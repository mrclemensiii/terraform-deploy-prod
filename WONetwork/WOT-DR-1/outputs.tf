output "instance_name" {
  value = "${aws_instance.Wideorbit-App.*.tags.Name}"
}

output "instance_ip" {
  value = "${aws_instance.Wideorbit-App.*.private_ip}"
}

output "customer_access" {
  value = "${aws_route53_record.woexchange.fqdn}"
}