[app_servers]
${app_server_ip}

[jmeter_clients]
${jmeter_client_ip}

[all:vars]
ansible_user = "ubuntu"
ansible_ssh_private_key_file = "~/.ssh/tu-llave-ssh-en-aws.pem" # <-- CAMBIA ESTA RUTA
ansible_ssh_common_args = "-o StrictHostKeyChecking=no"
