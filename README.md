## Prerequisites
- Azure CLI installed, logged in (`az login`)
- Terraform v1.3.0+ installed
- Ansible v2.15+ installed
- Active Azure subscription
- An SSH public key available on your machine  
  (create one if needed: `ssh-keygen -t rsa -b 2048`)

---

## Clone & Project Layout
```bash
git clone https://github.com/harshilrao/ccgc5502-terraform-ansible-project-harshil-rao
cd ccgc5502-terraform-ansible-project-harshil-rao
tree
```

Key paths used below:
- Terraform: `terraform/`
- Ansible: `ansible/`
  - Playbook: `ansible/n01717500-playbook.yml`
  - Roles: `ansible/roles/{profile-,user-,datadisk-,webserver-}n01717500/`

---

## Set Variables (non-interactive apply)
Create `terraform/terraform.tfvars` so Terraform won’t prompt:

```hcl
# terraform/terraform.tfvars
admin_username = "harshilrao"
humber_id      = "n01717500"
rg_name        = "7500-rg"

# paste the full contents of your ~/.ssh/id_rsa.pub here (single line)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... yourkey ... user@host"
```

Where to get your public key:
```bash
cat ~/.ssh/id_rsa.pub
```

> **Note:** All resources should use the `7500-` prefix and global tags via `locals`. VM size = `B1ms`, storage = `LRS`, DB = cheapest tier.

---

## Terraform Workflow
```bash
cd terraform

# 1) Initialize
terraform init

# 2) Validate
terraform validate

# 3) Review plan
terraform plan

# 4) Apply (non-interactive)
terraform apply --auto-approve
```

This will:
- Create Azure resources (RG, VNet/Subnets, VMs, LB, disks, etc.)
- Generate or render an Ansible inventory (`terraform/hosts` in this repo)
- **Trigger Ansible automatically** via a `null_resource` (if configured in your root module)

---

## Ansible (Manual Run, if needed)
If you want to re-run Ansible manually after `apply`:

```bash
cd ansible

# First run will create and fetch user100's private key to:
# ansible/downloaded_keys/id_rsa  (this file won't exist before the role runs!)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../terraform/hosts n01717500-playbook.yml   --private-key downloaded_keys/id_rsa
```

> **Why `chmod 600 ansible/downloaded_keys/id_rsa` might fail before apply:**  
> The file is created **by the Ansible role** (`user-n01717500`). It does not exist until the playbook runs successfully the first time. After the playbook runs, set permissions:
>
> ```bash
> chmod 600 ansible/downloaded_keys/id_rsa
> ```

---

## What the Roles Do
- **profile-n01717500**  
  Appends to `/etc/profile`:
  ```bash
  #Test block added by Ansible……harshil
  export TMOUT=1500
  ```
- **user-n01717500**  
  Creates `cloudadmins`, users `user100/200/300`, adds to `cloudadmins` & `wheel`, generates SSH keys (no passphrase), fetches **user100** private key from **VM1** to `ansible/downloaded_keys/id_rsa`.
- **datadisk-n01717500**  
  Partitions & mounts data disk: **4GB XFS → /part1**, **5GB EXT4 → /part2** (persistent).
- **webserver-n01717500**  
  Installs Apache, deploys `vm1.html`, `vm2.html`, `vm3.html` (each shows node FQDN) as `/var/www/html/index.html`, sets mode `0444`, enables & starts service, uses handlers.

---

## Post-Provision Validation
From the `terraform/` folder:
```bash
# Must show exactly 48 lines for this project (rubric)
terraform state list | nl

# Show all outputs (RG, VNet, Subnets, IPs, FQDNs, LB, etc.)
terraform output
```

**SSH test (after Ansible ran and key is downloaded):**
```bash
cd ansible
chmod 600 downloaded_keys/id_rsa
ssh -i downloaded_keys/id_rsa user100@<VM1-FQDN-OR-IP>
# then run:
tail -4 /etc/profile
tail -4 /etc/passwd
grep -E 'cloudadmins|wheel' /etc/group
df -Th
```

**LB round-robin test:**  
Open the **LB FQDN** in a browser over **HTTP** and refresh every ~7 seconds; page should show different VM FQDNs.

---

## Destroy (Cleanup)
```bash
cd terraform
terraform destroy --auto-approve
```

---

## Troubleshooting
- **Terraform prompting for vars** → Add/complete `terraform/terraform.tfvars`.
- **`chmod 600 ansible/downloaded_keys/id_rsa` fails** → Run Ansible first; the file is created by the `user-n01717500` role.
- **CentOS repo / `httpd` not found** → Ensure the `webserver` role installs the correct package for your OS and repos are enabled (EL8 `httpd` on AppStream; use `dnf config-manager --set-enabled ...` if mirrors are disabled).
