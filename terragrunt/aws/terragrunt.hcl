locals {    
    company                 = read_terragrunt_config(find_in_parent_folders("company.hcl", "${get_terragrunt_dir()}/company.hcl"))
    environment             = read_terragrunt_config(find_in_parent_folders("environment.hcl", "${get_terragrunt_dir()}/environment.hcl"))
    region_vars             = read_terragrunt_config(find_in_parent_folders("region.hcl", "${get_terragrunt_dir()}/region.hcl"))

    company_name            = local.company.locals.name
    iam_role                = local.environment.locals.iam_role_tf
    aws_region              = local.region_vars.locals.aws_region
    env                     = local.environment.locals.environment

    default_tags = jsonencode({
        env                 = "${local.env}"
        provider            = "AWS"
        latest_update       = formatdate("DD/MM/YYYY", timestamp())
    })
}

generate "provider" {
  path                      = "provider.tf"
  if_exists                 = "overwrite_terragrunt"
  contents                  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  assume_role {
    role_arn = "${local.iam_role}"
  }
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path        = "backend.tf"
    if_exists   = "overwrite_terragrunt"
  }
  config = {
    encrypt     = true
    bucket      = "${local.company_name}-terraform"
    region      = "us-east-1"
    key         = "${path_relative_to_include()}/terraform.tfstate"
    role_arn    = "arn:aws:iam::891377134563:role/terragrunt_runner"
  }
}