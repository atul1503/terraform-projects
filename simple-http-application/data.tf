data "aws_security_group" "to_ssh" {
    id="sg-0e0a343d686d04bb2"

}

data "aws_vpc" "name" {

    id = "vpc-0a09f20db19cbd756"
  
}