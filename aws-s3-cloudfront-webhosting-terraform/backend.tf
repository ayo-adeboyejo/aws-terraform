terraform {
  backend "s3" {
    bucket       = "ayo-day-03-bucket-terraform-12345"
    key          = "cfwebsite/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # enables state locking to prevent concurrent modifications to state
  }
}