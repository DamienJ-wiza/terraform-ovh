provider "ovh" {
  endpoint    = "ovh-eu"
  version     = "~> 0.5"
  alias       = "ovh"
}

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3"
  domain_name = "default"
  version     = "~> 1.24"
  region      = "GRA7"
  alias       = "gra7"
}
