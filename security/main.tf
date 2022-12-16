#-- security/main.tf --
resource "aws_security_group" "security_group" {
    for_each = local.security_groups
    name = each.value.name
    description = each.value.description
    vpc_id = var.vpc_id
    dynamic "ingress"{
        for_each = each.value.ingress
        content{
            from_port = ingress.value.from
            to_port = ingress.value.to
            protocol = ingress.value.protocol
            cidr_blocks = ingress.value.cidr_blocks
        }
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# #Allow the Bastion host from the web tier to access the private tier
# resource "aws_security_group_rule" "private-from-bastion-ssh-ingress" {
#     type = "ingress"
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     security_group_id = "${aws_security_group.security_group["web"].id}"
#     source_security_group_id = "${aws_security_group.security_group["public"].id}"
# }