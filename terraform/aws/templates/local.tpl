---
ansible_connection: local
kraken_services_namespaces: "${kraken_services_namespaces}"
kraken_services: ${kraken_services}
kraken_services_repos: ${kraken_services_repos}
thirdparty_scheduler: ${thirdparty_scheduler}
service_tokens:
  dockercfg_base64: ${dockercfg_base64}
  command_passwd: ${command_passwd}
  master_private_ip: ${master_private_ip}
  etcd_private_ip: ${etcd_private_ip}
  dns_domain: ${dns_domain}