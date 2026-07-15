output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "ec2_id" {
  value = { for key, value in aws_instance.dev_ec2 : key => value.id }

}

output "ec2_public_ip" {
  value = { for key, value in aws_instance.dev_ec2 : key => value.public_ip }
  # output from for_each can be a list or a map
  # value = [for v in aws_instance.dev_ec2 : v.private_ip]

}

output "private_ip" {
  value = [for value in aws_instance.dev_ec2 : value.private_ip]

}