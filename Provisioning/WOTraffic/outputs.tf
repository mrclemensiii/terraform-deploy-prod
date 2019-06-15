output "prod_app_customer_access" {
  value = "${aws_route53_record.woexchangeapp.*.fqdn}"
}

output "prod_app_instance_ip" {
  value = "${aws_instance.Wideorbit-App.*.private_ip}"
}

output "prod_app_instance_name" {
  value = "${aws_instance.Wideorbit-App.*.tags.Name}"
}

output "prod_db_customer_access" {
  value = "${aws_route53_record.woexchangedb.*.fqdn}"
}

output "prod_db_instance_ip" {
  value = "${aws_instance.Wideorbit-DB.*.private_ip}"
}

output "prod_db_instance_name" {
  value = "${aws_instance.Wideorbit-DB.*.tags.Name}"
}

output "dr_app_customer_access" {
  value = "${aws_route53_record.woexchangeappdr.*.fqdn}"
}

output "dr_app_instance_ip" {
  value = "${aws_instance.Wideorbit-App-DR.*.private_ip}"
}

output "dr_app_instance_name" {
  value = "${aws_instance.Wideorbit-App-DR.*.tags.Name}"
}

output "dr_db_customer_access" {
  value = "${aws_route53_record.woexchangedbdr.*.fqdn}"
}

output "dr_db_instance_ip" {
  value = "${aws_instance.Wideorbit-DB-DR.*.private_ip}"
}

output "dr_db_instance_name" {
  value = "${aws_instance.Wideorbit-DB-DR.*.tags.Name}"
}








