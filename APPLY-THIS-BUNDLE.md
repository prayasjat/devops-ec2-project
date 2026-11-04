# Apply this bundle to your existing project

This is a replacement overlay, not a remote deployment. Extract/copy the included files over your existing project directory, preserving `.git/` and your existing commits. Review any local changes before overwriting.

Files included are intended to replace the corresponding project files and add the `infra/`, `scripts/`, `.github/workflows/`, and `docs/` directories.

After copying, check the diff in Git before staging. Do not add `infra/terraform.tfvars`, `.terraform/`, state files, AWS credentials, `.env`, or private keys to Git.
