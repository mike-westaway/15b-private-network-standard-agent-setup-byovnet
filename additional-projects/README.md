# Additional Projects

This directory contains Terraform code for creating additional AI Foundry projects on-demand.

## Usage

1. **Configure variables**: Edit `terraform.tfvars` with your values (you can copy from `../code/terraform.tfvars`)

2. **Initialize Terraform**:
   ```powershell
   terraform init
   ```

3. **Plan the deployment**:
   ```powershell
   terraform plan
   ```

4. **Apply the deployment**:
   ```powershell
   terraform apply
   ```

5. **Destroy when done** (optional):
   ```powershell
   terraform destroy
   ```

## Notes

- This directory has its own Terraform state, separate from the main deployment in `../code/`
- Resources created here won't affect the main deployment
- You can run this deployment multiple times with different configurations
