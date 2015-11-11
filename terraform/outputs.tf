output "elb_url" {
  value = "${aws_elb.demo_service.dns_name}"
}
