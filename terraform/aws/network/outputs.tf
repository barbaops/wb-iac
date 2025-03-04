output "vpc_id" {
  description = "SSM Parameter com o valor do vpc_id"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "SSM Parameters com os valores dos ID's das Subnets Públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "SSM Parameters com os valores dos ID's das Subnets Privadas"
  value       = aws_subnet.private[*].id
}

output "database_subnets" {
  description = "SSM Parameters com os valores dos ID's das Subnets de Databases"
  value       = aws_subnet.database[*].id
}
