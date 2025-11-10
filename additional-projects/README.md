# Additional Projects

This directory contains Terraform code for creating multiple AI Foundry projects that share the existing Storage Account, Cosmos DB, and AI Search resources from the main deployment.

## Prerequisites

You must first deploy the main infrastructure in `../code/` before creating additional projects.

## Usage

1. **Deploy the main infrastructure** (if not already done):
   ```powershell
   cd ../code
   terraform init
   terraform apply
   ```

2. **Get the resource IDs from the main deployment**:
   ```powershell
   cd ../code
   terraform output resource_ids_for_additional_projects
   ```
   Copy the output values.

3. **Configure variables**: Edit `terraform.tfvars` in the `additional-projects` directory:
   - Update the placeholder resource IDs with the actual values from step 2
   - **Add your project names to the `project_names` list**
   - The basic configuration values should already match the main deployment

4. **Initialize Terraform**:
   ```powershell
   cd ../additional-projects
   terraform init
   ```

5. **Plan the deployment**:
   ```powershell
   terraform plan
   ```

6. **Apply the deployment**:
   ```powershell
   terraform apply
   ```

## Adding More Projects

To add more projects, simply edit `terraform.tfvars` and add names to the `project_names` list:

```hcl
project_names = [
  "project-dev",
  "project-test",
  "project-prod",
  "project-new"  # <- Add new project here
]
```

Then run:
```powershell
terraform apply
```

## Removing Projects

To remove projects, delete the name from the `project_names` list and run:
```powershell
terraform apply
```

**Warning:** This will destroy the project and all associated data!

## What This Creates

For each project name in the list, Terraform creates:
- An AI Foundry project under the existing hub
- Project connections to the existing Storage Account, Cosmos DB, and AI Search
- Role assignments for the project's managed identity
- A capability host for AI agents
- Cosmos DB role assignments for the project-specific collections

## Notes

- This directory has its own Terraform state, separate from the main deployment in `../code/`
- All projects share the existing infrastructure resources (Storage, Cosmos DB, AI Search)
- Each project gets its own containers/collections within the shared resources
- Projects are isolated at the data plane level through role-based access controls
- Project names must be unique and follow Azure naming conventions
