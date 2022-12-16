# -- compute/main.tf --

data "aws_ami" "web_ami" {
    most_recent = true
    owners = ["137112412989"]
    
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-2.0*"]
    }
}

resource "random_id" "node_id" {
    byte_length = 2
    count = var.instance_count
}

resource "aws_instance" "web-instance" {
    count = var.instance_count
    instance_type = var.instance_type
    ami = data.aws_ami.web_ami.id
    tags = {
        Name = "web-instance-${random_id.node_id[count.index].dec}"
    }
    #key_name = ""
    vpc_security_group_ids = [var.public_security_group]
    subnet_id = var.public_subnets[count.index]
    #user_data = ""
    root_block_device {
        volume_size = var.volume_size
    }
}