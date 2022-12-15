output "vpc_id" {
    value = aws_vpc.my_vpc.id
}

output "public_subnets"{
    value = aws_subnet.public_subnet.*.id
}

output "web_subnets"{
    value = aws_subnet.web_subnet.*.id
}

output "rds_subnets"{
    value = aws_subnet.rds_subnet.*.id
}