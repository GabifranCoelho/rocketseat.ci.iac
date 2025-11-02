terraform {
  backend "s3" {
    bucket         = "pr-656003592068-tfstate-us-east-2"
    key            = "iac/terraform.tfstate" # caminho dentro do bucket (pode trocar)
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}