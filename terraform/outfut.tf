output "public_ip" {
    value =  "Your EC2 IP is : ${aws_instance.Monitoring_Server.public_ip}"
}
