# import public key for EC2 from aws
data "aws_key_pair" "aws_pub_key" {
  key_name           = "ayodadeb_adm_key"
  include_public_key = true

}

# import user_data using local_file provider 
data "local_file" "user_data" {
  filename = "${path.module}/scripts/init.sh"
}