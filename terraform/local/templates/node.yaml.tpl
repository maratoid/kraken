#cloud-config

---
write_files:
  - path: /etc/ansible/hosts
    content: |
      [node]
      $NODE_SHORT_NAME ansible_ssh_host=$private_ipv4
  - path: /etc/ansible/group_vars/node
    content: |
      ---
        ansible_connection: ssh
        ansible_python_interpreter: "PATH=/home/core/bin:$PATH python"
        ansible_ssh_private_key_file: /opt/ansible/private_key
        ansible_ssh_user: core
        master_record: ${access_scheme}://$MASTER_PRIVATE_IP:${access_port}
        cluster_name: ${cluster_name}
        proxy_record: $NODE_001_IP
        kubernetes_basic_auth_user:
            name: ${cluster_user}
            password: ${cluster_passwd}
        dns_domain: ${dns_domain}
        dns_ip: ${dns_ip}
        dockercfg_base64: ${dockercfg_base64}
        etcd_private_ip: $ETCD_PRIVATE_IP
        deployment_mode: ${deployment_mode}
        hyperkube_image: ${hyperkube_image}
        interface_name: ${interface_name}
        kraken_local_dir: ${kraken_local_dir}
        kubernetes_api_version: ${kubernetes_api_version}
        kubernetes_binaries_uri: ${kubernetes_binaries_uri}
        kubernetes_cert_dir: ${kubernetes_cert_dir}
        logentries_token: ${logentries_token}
        logentries_url: ${logentries_url}
        access_port: "${access_port}"
        master_private_ip: $MASTER_PRIVATE_IP
        access_scheme: ${access_scheme}
        sysdigcloud_access_key: ${sysdigcloud_access_key}
coreos:
  etcd2:
    proxy: on
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    advertise-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    initial-cluster: etcd=http://$ETCD_PRIVATE_IP:2380
  fleet:
    etcd-servers: http://$private_ipv4:4001
    public-ip: $private_ipv4
    metadata: "role=node"
  flannel:
    etcd-endpoints: http://$ETCD_PRIVATE_IP:4001
    interface: $private_ipv4
  units:
    - name: docker.service
      drop-ins:
        - name: 50-docker-opts.conf
          content: |
            [Service]
            Environment="DOCKER_OPTS=--log-level=warn"
    - name: setup-network-environment.service
      command: start
      content: |
        [Unit]
        Description=Setup Network Environment
        Documentation=https://github.com/kelseyhightower/setup-network-environment
        Requires=network-online.target
        After=network-online.target
        Before=flanneld.service

        [Service]
        ExecStartPre=-/usr/bin/mkdir -p /opt/bin
        ExecStartPre=/usr/bin/wget -N -P /opt/bin https://github.com/kelseyhightower/setup-network-environment/releases/download/v1.0.0/setup-network-environment
        ExecStartPre=/usr/bin/chmod +x /opt/bin/setup-network-environment
        ExecStart=/opt/bin/setup-network-environment
        RemainAfterExit=yes
        Type=oneshot
    - name: fleet.service
      command: start
    - name: systemd-journal-gatewayd.socket
      command: start
      enable: yes
      content: |
        [Unit]
        Description=Journal Gateway Service Socket
        [Socket]
        ListenStream=/var/run/journald.sock
        Service=systemd-journal-gatewayd.service
        [Install]
        WantedBy=sockets.target
    - name: generate-ansible-keys.service
      command: start
      content: |
        [Unit]
        Description=Generates SSH keys for ansible container
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStartPre=-/usr/bin/rm /home/core/.ssh/ansible_rsa*
        ExecStartPre=/usr/bin/bash -c "ssh-keygen -f /home/core/.ssh/ansible_rsa -N ''"
        ExecStart=/usr/bin/bash -c "cat /home/core/.ssh/ansible_rsa.pub >> /home/core/.ssh/authorized_keys"
    - name: kraken-git-pull.service
      command: start
      content: |
        [Unit]
        Requires=generate-ansible-keys.service
        After=generate-ansible-keys.service
        Description=Fetches kraken repo
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStartPre=/usr/bin/rm -rf /opt/kraken
        ExecStart=/usr/bin/git clone -b ${kraken_branch} ${kraken_repo} /opt/kraken
    - name: write-sha-file.service
      command: start
      content: |
        [Unit]
        Requires=kraken-git-pull.service
        After=kraken-git-pull.service
        Description=writes optional sha to a file
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/bash -c '/usr/bin/echo "${kraken_commit}" > /opt/kraken/commit.sha'
    - name: fetch-kraken-commit.service
      command: start
      content: |
        [Unit]
        Requires=write-sha-file.service
        After=write-sha-file.service
        Description=fetches an optional commit
        ConditionFileNotEmpty=/opt/kraken/commit.sha
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        WorkingDirectory=/opt/kraken
        ExecStartPre=/usr/bin/git fetch ${kraken_repo} +refs/pull/*:refs/remotes/origin/pr/*
        ExecStart=/usr/bin/git checkout -f ${kraken_commit}
    - name: ansible-in-docker.service
      command: start
      content: |
        [Unit]
        Requires=write-sha-file.service
        After=fetch-kraken-commit.service
        Description=Runs a prebaked ansible container
        [Service]
        Type=simple
        Restart=on-failure
        RestartSec=3
        ExecStartPre=-/usr/bin/docker rm -f ansible-docker
        ExecStart=/usr/bin/docker run --name ansible-docker -v /etc/ansible:/etc/ansible -v ${kraken_local_dir}:${kraken_local_dir} -v /home/core/.ssh/ansible_rsa:/opt/ansible/private_key -v /var/run:/ansible -e ANSIBLE_HOST_KEY_CHECKING=False ${ansible_docker_image} /sbin/my_init --skip-startup-files --skip-runit -- ${ansible_playbook_command} ${ansible_playbook_file}
  update:
    group: ${coreos_update_channel}
    reboot-strategy: ${coreos_reboot_strategy}
