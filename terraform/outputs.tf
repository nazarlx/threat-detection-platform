output "honeypot_public_ip" {
  value = aws_instance.honeypot.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/honeypot-key.pem ubuntu@${aws_instance.honeypot.public_ip}"
}
