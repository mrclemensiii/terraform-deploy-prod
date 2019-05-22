output "app_instance_name" {
  value = "${aws_instance.Wideorbit-App.*.tags.Name}"
}

output "app_instance_ip" {
  value = "${aws_instance.Wideorbit-App.*.private_ip}"
}

output "db_instance_name" {
  value = "${aws_instance.Wideorbit-DB.*.tags.Name}"
}

output "db_instance_ip" {
  value = "${aws_instance.Wideorbit-DB.*.private_ip}"
}

output "customer_access" {
  value = "${aws_route53_record.woexchange.fqdn}"
}