resource "aws_instance" "dev_ec2" {
  for_each = var.server_name

  ami           = "ami-0adf1d1f171c8c66b"
  instance_type = "t4g.micro"
  key_name      = data.aws_key_pair.aws_pub_key.key_name

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.admin_sg.id]

  monitoring                  = var.enable_monitoring
  associate_public_ip_address = var.enable_public_ip

  user_data = data.local_file.user_data.content

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-each.key" })
}


# ----------s3 bucket -------------------
resource "aws_s3_bucket" "main_bucket" {
  bucket = local.bucket_name
  tags = merge(local.common_tags, {Name = local.bucket_name})
}