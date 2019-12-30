# data "ovh_iploadbalancing" "lb" {
#   service_name = "loadbalancer-720a56ca2fa693ea1e5018e0c2b1b4d1"
#   state       = "ok"
# }

# resource "openstack_lb_loadbalancer_v2" "lb" {
#    name = "loadbalancer-720a56ca2fa693ea1e5018e0c2b1b4d1"
# }

resource "openstack_compute_keypair_v2" "wizaops" {
  provider       = "openstack.gra7"
  name           = "Wizaops"
  public_key     = "${file("~/.ssh/wizaops.pub")}"
}

resource "ovh_cloud_network_private" "front" {
  name           = "front" # Nom du réseau
  provider       = "ovh.ovh" # Nom du fournisseur
  vlan_id        = 2000 # Identifiant du vlan pour le vRrack
  regions        = ["GRA7"]
}

resource "ovh_cloud_network_private" "back" {
  name           = "back" # Nom du réseau
  provider       = "ovh.ovh" # Nom du fournisseur
  vlan_id        = 2001 # Identifiant du vlan pour le vRrack
  regions        = ["GRA7"]
}

resource "ovh_cloud_network_private_subnet" "subnet_back" {
  network_id = "${ovh_cloud_network_private.back.id}"
  start      = "10.0.50.200"
  end        = "10.0.50.250"
  network    = "10.0.50.0/24"
  dhcp       = true
  no_gateway = true
  provider   = "ovh.ovh"
  region     = "GRA7"
}

resource "ovh_cloud_network_private_subnet" "subnet_front" {
  network_id = "${ovh_cloud_network_private.front.id}"
  start      = "10.0.51.200"
  end        = "10.0.51.250"
  network    = "10.0.51.0/24"
  dhcp       = true
  no_gateway = true
  provider   = "ovh.ovh"
  region     = "GRA7"
}

resource "openstack_compute_secgroup_v2" "egress" {
  name        = "egress"
  description = "egress for all instance"
  provider    = "openstack.gra7"
  rule        = []
}

resource "openstack_compute_secgroup_v2" "httpprivate" {
  name        = "http-private"
  description = "Rules http and https for instances in private subnet"
  provider    = "openstack.gra7"
  rule {
    cidr = "10.0.0.0/8"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
  }

  rule {
    cidr = "10.0.0.0/8"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
  }

  rule {
    cidr = "82.127.221.196/32"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
  }

  rule {
    cidr = "82.127.221.196/32"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
  }

  rule {
    cidr = "92.154.82.114/32"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
  }

  rule {
    cidr = "92.154.82.114/32"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
  }
}

resource "openstack_compute_secgroup_v2" "httppublic" {
  name        = "http-public"
  description = "Rules http and https for loadblancers"
  provider    = "openstack.gra7"

  rule {
    cidr = "0.0.0.0/0"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
  }

  rule {
    cidr = "0.0.0.0/0"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
  }
}

resource "openstack_compute_secgroup_v2" "rabbitmqprivate" {
  name        = "rabbitmq-private"
  description = "Rule for default port 5672"
  provider    = "openstack.gra7"

  rule {
    cidr = "10.0.0.0/8"
    from_port = 5672
    ip_protocol = "tcp"
    to_port = 5672
  }
}

resource "openstack_compute_secgroup_v2" "rabbitmqpublic" {
  name        = "rabbitmq-public"
  description = "Rule for the dashboard"
  provider    = "openstack.gra7"

  rule {
    cidr = "82.127.221.196/32"
    from_port = 15672
    ip_protocol = "tcp"
    to_port = 15672
  }

  rule {
    cidr = "92.154.82.114/32"
    from_port = 15672
    ip_protocol = "tcp"
    to_port = 15672
  }
}

resource "openstack_compute_secgroup_v2" "sshpublic" {
  name        = "ssh-public"
  description = "Rule for ssh connexion"
  provider    = "openstack.gra7"

  rule {
    cidr = "82.127.221.196/32"
    from_port = 22
    ip_protocol = "tcp"
    to_port = 22
  }

  rule {
    cidr = "92.154.82.114/32"
    from_port = 22
    ip_protocol = "tcp"
    to_port = 22
  }
}

resource "openstack_compute_secgroup_v2" "zabbixpublic" {
  name        = "zabbix-public"
  description = "Rule for zabbix agent"
  provider    = "openstack.gra7"

  rule {
    cidr = "82.127.221.196/32"
    from_port = 10050
    ip_protocol = "tcp"
    to_port = 10050
  }

  rule {
    cidr = "92.154.82.114/32"
    from_port = 10050
    ip_protocol = "tcp"
    to_port = 10050
  }
}

resource "openstack_compute_instance_v2" "back_instances" {
  for_each        = toset(var.instances_names_back)
  name            = each.value
  key_pair        = "${openstack_compute_keypair_v2.wizaops.name}"
  security_groups = ["zabbix-public","ssh-public","http-private","egress"]
  provider        = "openstack.gra7"
  flavor_name     = "c2-7"
  image_name      = "Debian 10"
  network {
    name = "Ext-Net"
  }

  network {
    name = "back"
  }
}

resource "openstack_compute_instance_v2" "front_instances" {
  for_each        = toset(var.instances_names_front)
  name            = each.value
  key_pair        = "${openstack_compute_keypair_v2.wizaops.name}"
  security_groups = ["zabbix-public","ssh-public","http-private","egress"]
  provider        = "openstack.gra7"
  flavor_name     = "c2-7"
  image_name      = "Debian 10"
  network {
    name = "Ext-Net"
  }

  network {
    name = "front"
  }
}

resource "openstack_compute_instance_v2" "lb_back" {
  name            = "LbBack"
  key_pair        = "${openstack_compute_keypair_v2.wizaops.name}"
  security_groups = ["zabbix-public","ssh-public","http-public","egress"]
  provider        = "openstack.gra7"
  flavor_name     = "c2-7"
  image_name      = "Debian 10"
  network {
    name = "Ext-Net"
  }

  network {
    name = "back"
  }
}

resource "openstack_compute_instance_v2" "lb_front" {
  name            = "LbFront"
  key_pair        = "${openstack_compute_keypair_v2.wizaops.name}"
  security_groups = ["zabbix-public","ssh-public","http-public","egress"]
  provider        = "openstack.gra7"
  flavor_name     = "b2-7"
  image_name      = "Debian 10"
  network {
    name = "Ext-Net"
  }

  network {
    name = "front"
  }
}


resource "openstack_compute_instance_v2" "rabbitmq" {
  name            = "RabbitMQ"
  key_pair        = "${openstack_compute_keypair_v2.wizaops.name}"
  security_groups = ["zabbix-public","ssh-public","rabbitmq-public","rabbitmq-private","egress"]
  provider        = "openstack.gra7"
  flavor_name     = "b2-7"
  image_name      = "Debian 10"
  network {
    name = "Ext-Net"
  }

  network {
    name = "back"
  }
}
