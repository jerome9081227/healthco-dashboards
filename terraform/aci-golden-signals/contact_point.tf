resource "grafana_contact_point" "default_email" {
  name = "grafana-default-email"

  email {
    addresses = ["jerome.wallace@grafana.com"]
  }
}
