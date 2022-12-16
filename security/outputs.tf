#-- security/outputs.tf --

output "public_security_group"{
    value = aws_security_group.security_group["public"].id
}

output "web_security_group"{
    value = aws_security_group.security_group["web"].id
}