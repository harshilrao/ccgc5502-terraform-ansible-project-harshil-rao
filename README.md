## Prerequisites
- Azure CLI configured & logged in
- Terraform v1.3.0+ installed
- Ansible v2.15+ installed
- Active Azure subscription
- SSH key permissions set:
  ```bash
  chmod 600 ansible/downloaded_keys/id_rsa
  ```

---

## Terraform Workflow
```bash
# 1. Clone the repository
git clone https://github.com/harshilrao/ccgc5502-terraform-ansible-project-harshil-rao
cd ccgc5502-terraform-ansible-project-harshil-rao

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Validate configuration
terraform validate

# 4. Review execution plan
terraform plan

# 5. Apply configuration (non-interactive)
terraform apply --auto-approve

# 6. To destroy the infrastructure
terraform destroy --auto-approve
```

---

## Ansible Workflow
Ansible is triggered **automatically** after `terraform apply` via `null_resource` in Terraform.  
You can also run it manually:
```bash
cd ansible
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/hosts ansible/n01717500-playbook.yml  --private-key ansible/downloaded_keys/id_rsa
```

---

## Ansible Playbook Roles

### profile-n01717500
- Appends to `/etc/profile`:
  ```bash
  #Test block added by Ansible……harshil
  export TMOUT=1500
  ```

### user-n01717500
- Creates group `cloudadmins`
- Creates `user100`, `user200`, `user300`
- Adds users to `cloudadmins` and `wheel` groups
- Generates SSH keys without passphrase
- Fetches `user100`’s private key from VM1 to control node (`ansible/downloaded_keys/id_rsa`)

### datadisk-n01717500
- Partitions data disk:
  - **4 GB XFS** → `/part1`
  - **5 GB EXT4** → `/part2`
- Creates mount points, mounts persistently

### webserver-n01717500
- Installs Apache HTTP Server
- Creates `vm1.html`, `vm2.html`, `vm3.html` with node FQDN
- Copies to `/var/www/html/index.html` on each node
- Sets permissions to `0444`
- Starts via handlers, enables on boot

---

## Outputs After Deployment
- Hostnames & FQDNs for Linux & Windows VMs
- Private & Public IPs
- Virtual Network, Subnets, Load Balancer name
