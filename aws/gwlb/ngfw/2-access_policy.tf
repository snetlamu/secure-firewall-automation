##################
# Access Policy
##################

# Data Sources
data "fmc_port_objects" "http" {
    name = "HTTP"
}
data "fmc_port_objects" "https" {
    name = "HTTPS"
}
data "fmc_port_objects" "ssh" {
    name = "SSH"
}
data "fmc_ips_policies" "ips_policy" {
    name = "Security Over Connectivity"
}

# Network Objects
resource "fmc_network_objects" "app_subnet" {
  name        = "app_subnet"
  value       = var.app_subnet
  description = "App Network"
}

# Host Objects
resource "fmc_host_objects" "app_server" {
    name        = "app_server"
    value       = var.app_server
    description = "App Server"
}

# IPS Policy
resource "fmc_ips_policies" "ips_policy" {
    name            = "ftdv_ips_policy"
    inspection_mode = "DETECTION"
    basepolicy_id   = data.fmc_ips_policies.ips_policy.id
}

# Access Control Policy Rules
#########################################################

resource "fmc_access_rules" "access_rule_1" {
    depends_on = [fmc_devices.ftd]
    acp                = fmc_access_policies.access_policy.id
    section            = "mandatory"
    name               = "Permit Outbound"
    action             = "allow"
    enabled            = true
    send_events_to_fmc = true
    log_files          = false
    log_begin          = true
    log_end            = true
    source_networks {
        source_network {
            id   = fmc_network_objects.app_subnet.id
            type = "Network"
        }
    }
    destination_ports {
        destination_port {
            id = data.fmc_port_objects.http.id
            type = "TCPPortObject"
        }
        destination_port {
            id = data.fmc_port_objects.https.id
            type = "TCPPortObject"
        }
    }
    ips_policy   = fmc_ips_policies.ips_policy.id
    new_comments = ["outbound web traffic"]
}

resource "fmc_access_rules" "access_rule_2" {
    depends_on = [fmc_devices.ftd]
    acp                = fmc_access_policies.access_policy.id
    section            = "mandatory"
    name               = "Access to App Server"
    action             = "allow"
    enabled            = true
    send_events_to_fmc = true
    log_files          = false
    log_begin          = true
    log_end            = true
    destination_networks {
        destination_network {
            id = fmc_host_objects.app_server.id
            type =  "Host"
        }
    }
    destination_ports {
        destination_port {
            id = data.fmc_port_objects.ssh.id
            type = "TCPPortObject"
        }
    }
    ips_policy   = fmc_ips_policies.ips_policy.id
    new_comments = ["SSH to App Server"]
}

# Deploy policy if any changes exist
resource "fmc_ftd_deploy" "ftd" {
    depends_on = [
        fmc_access_rules.access_rule_1,
        fmc_access_rules.access_rule_2
    ]
    device = fmc_devices.ftd.id
    ignore_warning = false
    force_deploy = false
}