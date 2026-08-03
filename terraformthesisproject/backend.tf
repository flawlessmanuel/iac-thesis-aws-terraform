# backend.tf
#
# Remote state backend: stores terraform.tfstate in S3 (versioned, encrypted)
# instead of on local disk, and uses S3-native state locking (use_lockfile,
# GA since Terraform 1.11) so two applies can never run concurrently and
# corrupt the state. This is the current HashiCorp-recommended approach;
# the older pattern of a separate DynamoDB lock table is now deprecated.
#
# BOOTSTRAP STEPS (one-time, done manually BEFORE this backend block is
# enabled, since Terraform cannot create the backend it is about to use):
#
#   aws s3api create-bucket --bucket chimd-thesis-terraform-state-2026 --region eu-north-1 --create-bucket-configuration LocationConstraint=eu-north-1

#   aws s3api put-bucket-versioning --bucket chimd-thesis-terraform-state-2026 \
#       --versioning-configuration Status=Enabled
#   aws s3api put-bucket-encryption --bucket chimd-thesis-terraform-state-2026 \
#       --server-side-encryption-configuration \
#       '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# Then fill in the bucket name below and run: terraform init -migrate-state
#
# Requires Terraform CLI >= 1.11 for use_lockfile support.

terraform {
  backend "s3" {
    bucket       = "chimd-thesis-terraform-state-2026"
    key          = "thesis-project/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true # S3-native state locking (no DynamoDB table required)
  }
}
