# CCGC 5502 – Terraform + Ansible Automation Project

Provision Azure infrastructure with **Terraform** and configure the VMs with **Ansible**.  
Deploys a VNet, subnets, NSGs, **3 Ubuntu Linux VMs**, a **Load Balancer** (HTTP probe + NAT rules for SSH), and configures:

- `/etc/profile` (session timeout)
- Users & groups (`user100`, `user200`, `user300`, `cloudadmins`, `wheel`) with SSH keys
- Data disk partitioning and mounts (`/part1` XFS ~4GB, `/part2` EXT4 ~5GB)
- Apache (`apache2`) serving node-specific `index.html` behind the LB

---

## 1) Prerequisites

- Azure subscription + permissions
- **Azure CLI** (logged in): `az login`
- **Terraform** ≥ 1.6
- **Ansible** ≥ 2.14
- SSH key present (public key): `~/.ssh/id_rsa.pub` (or use your own path)

> Tip: Set the subscription you want to use:
> ```bash
> az account set --subscription "<YOUR_SUBSCRIPTION_NAME_OR_ID>"
> ```

---

## 2) Clone

```bash
git clone <your-repo-url>
cd ccgc5502-terraform-ansible-project-harshil-rao
```

---

## 3) Configure variables (no secrets in Git)

Create `terraform/terraform.tfvars` on **your machine** (don’t commit it):

```hcl
# ID suffix used in names and null_resource triggers (use your Humber ID)
humber_id = "n01717500"

# Resource group and region
rg_name  = "7175-ccgc5502-project-rg"
location = "Canada Central"

# Networking
address_space = ["10.10.0.0/16"]
subnet_map = {
  vm    = "10.10.1.0/24"
  mgmt  = "10.10.2.0/24"
  db    = "10.10.3.0/24"
  # Optional (if you add Bastion): bastion = "10.10.10.0/27"
}

# VM config
vm_count       = 3
vm_size        = "Standard_B1ms"
admin_username = "azureuser"
ssh_public_key = file("~/.ssh/id_rsa.pub")

# Ubuntu (Jammy 22.04 LTS) image
linux_image = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}

# Tags
common_tags = {
  Project        = "CCGC 5502 Automation Project"
  Name           = "harshil.rao"
  ExpirationDate = "2024-12-31"
  Environment    = "Project"
}
```

> If your SSH public key is at a different path, change `ssh_public_key` accordingly.

---

## 4) Initialize + Validate + Plan

```bash
cd terraform
terraform init
terraform validate
terraform plan -out=tfplan
```

---

## 5) Apply (provision Azure)

```bash
terraform apply --auto-approve
```

When it finishes, capture outputs:

```bash
terraform output
# Expect at least:
# - lb_public_ip
# - lb_fqdn
# - vm_private_ips
```

---

## 6) Generate a fresh Ansible inventory (portable)

Do **not** rely on the committed `terraform/hosts` (it has a hardcoded IP).  
Regenerate it from the **actual** LB public IP created in *your* subscription:

```bash
# still in the terraform folder
LB_IP=$(terraform output -raw lb_public_ip)

cat > hosts <<EOF
[linux]
vm1 ansible_host=${LB_IP} ansible_port=50000
vm2 ansible_host=${LB_IP} ansible_port=50001
vm3 ansible_host=${LB_IP} ansible_port=50002
EOF

echo "Wrote inventory with LB ${LB_IP} -> terraform/hosts"
```

> The load balancer module creates **NAT rules** that map:
> - `50000 → 22` (VM1)
> - `50001 → 22` (VM2)
> - `50002 → 22` (VM3)

---

## 7) Optional quick SSH sanity check

```bash
# Replace azureuser if you changed admin_username
ssh -p 50000 azureuser@$(terraform output -raw lb_public_ip) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
exit
```

---

## 8) Run Ansible configuration

From repo root:

```bash
cd ..
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i terraform/hosts ansible/n01717500-playbook.yml
```

What this playbook does:
- **profile-n01717500**: appends a block to `/etc/profile`, sets `TMOUT=1500`
- **user-n01717500**: creates `cloudadmins`, ensures `wheel`, creates users `user100/200/300`, generates SSH keys; downloads `user100` private key from **VM1** to `ansible/downloads/user100_id_rsa`
- **datadisk-n01717500**: finds the 10GB data disk, partitions (≈4G XFS + ≈5G EXT4), mounts `/part1` and `/part2` persistently
- **webserver-n01717500**: installs **apache2** (Ubuntu), enables & starts it, creates per-node `index.html` with the VM’s FQDN

---

## 9) Validation (matches the rubric)

**Terraform state lines (aim ~48):**
```bash
cd terraform
terraform state list | nl
```

**Outputs:**
```bash
terraform output
```

**Login as `user100` with the downloaded private key (no password/passphrase):**
```bash
LB_IP=$(terraform output -raw lb_public_ip)
chmod 600 ../ansible/downloads/user100_id_rsa

ssh -i ../ansible/downloads/user100_id_rsa     -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null     -p 50000 user100@${LB_IP}

# On VM1:
tail -4 /etc/profile
tail -4 /etc/passwd
grep -E 'cloudadmins|wheel' /etc/group
df -Th
exit
```

**Web via Load Balancer (round-robin pages):**
- Open: `http://$(terraform output -raw lb_fqdn)` **or** `http://$(terraform output -raw lb_public_ip)`
- Refresh every ~7 seconds; each refresh should show the **FQDN** of a different node.

---

## 10) Destroy (to save cost)

```bash
cd terraform
terraform destroy --auto-approve
```

---

## Notes & Tips

- This project assumes **Ubuntu** for the web role (uses `apache2`). If you change to CentOS/RHEL, update the role to install `httpd` instead of `apache2`.
- Keep `terraform.tfvars` **out of Git**. Share a `terraform.tfvars.example` if needed.
- If you want a **remote backend** (Azure Storage) for shared state, add `backend.tf` and grant `Storage Blob Data Contributor` to your user; otherwise this README uses the default **local** backend to avoid cross-PC failures.
- If SSH to `user100` fails: ensure Ansible finished without errors and that you used the downloaded key from `ansible/downloads/user100_id_rsa`.

---

## One-liner Quick Start (advanced)

```bash
cd terraform && terraform init && terraform apply -auto-approve && LB_IP=$(terraform output -raw lb_public_ip) && printf "[linux]
vm1 ansible_host=%s ansible_port=50000
vm2 ansible_host=%s ansible_port=50001
vm3 ansible_host=%s ansible_port=50002
" "$LB_IP" "$LB_IP" "$LB_IP" > hosts && cd .. && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i terraform/hosts ansible/n01717500-playbook.yml
```
