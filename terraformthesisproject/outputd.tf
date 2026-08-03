# outputs.tf

output "load_balancer_url" {
  description = "The DNS name of the load balancer"
  value       = "http://${aws_lb.main_lb.dns_name}"
}


output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.default.address
}