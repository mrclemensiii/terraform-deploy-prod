output "app_instance_name" {
  value = "${aws_instance.Wideorbit-App.*.tags.Name}"
}

output "db_instance_name" {
  value = "${aws_instance.Wideorbit-DB.*.tags.Name}"
}

output "app_instance_ip" {
  value = "${aws_instance.Wideorbit-App.*.private_ip}"
}

output "db_instance_ip" {
  value = "${aws_instance.Wideorbit-DB.*.private_ip}"
}

output "db_customer_access" {
  value = "${aws_route53_record.woexchangedb.*.fqdn}"
}

output "app_customer_access" {
  value = "${aws_route53_record.woexchangeapp.*.fqdn}"
}
