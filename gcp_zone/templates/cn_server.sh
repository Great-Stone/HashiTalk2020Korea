#! /bin/bash

echo "*****    Installing Utils    *****"
sudo apt update
sudo apt-get install -y \
    dnsutils \
    wget \
    software-properties-common \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg2\
    unzip \
    ufw \
    jq \
    dnsmasq

sudo ufw allow 8300 # consule
sudo ufw allow 8301 # consule
sudo ufw allow 8302 # consule
sudo ufw allow 8500 # consule
sudo ufw allow 8600 # consule
sudo ufw allow 4646 # nomad
sudo ufw allow 4647 # nomad
sudo ufw allow 4648 # nomad
sudo ufw allow 22
sudo ufw --force enable

echo "*****    Download and install Consul on Debian    *****"
if [ ! -f /usr/local/bin/consul ]; then
    cd /tmp
    wget https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip
    unzip consul_${consul_version}_linux_amd64.zip
    sudo mv consul /usr/local/bin/
    consul -v
fi

echo "*****    Install Consul on ARM    *****"
sudo groupadd --system consul
sudo useradd -s /sbin/nologin --system -g consul consul

sudo mkdir -p /var/lib/consul
sudo chown -R consul:consul /var/lib/consul
sudo chmod -R 775 /var/lib/consul

sudo mkdir /etc/consul.d
sudo chown -R consul:consul /etc/consul.d

echo "*****    Create Consul config   *****"
sudo bash -c 'cat <<EOF > /etc/consul.d/consul.hcl
primary_datacenter = "${datacenter}"
enable_central_service_config = true
translate_wan_addrs = true
connect {
  enabled = true
  # enable_mesh_gateway_wan_federation = true
}
acl {
  enabled = false
  default_policy = "allow"
  down_policy = "extend-cache"
  enable_token_persistence = true
}
EOF'

echo "*****    Create and run consul service   *****"
#kill -9 `ps -ef | grep 'consul' | awk '{print $2}'`
export PRIVATE_IP=$(hostname  -I | cut -f1 -d' ')
sudo systemctl stop consul
sudo bash -c 'rm -rf /etc/systemd/system/consul.service'
sudo bash -c 'cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul Service Discovery Agent
Documentation=https://www.consul.io/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent \
-server -ui -bootstrap-expect=1 \
-datacenter=${datacenter} \
-node=${consul_name} \
-client=0.0.0.0 \
-bind=PRIVATE_IP \
-encrypt=h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o= \
-data-dir=/var/lib/consul \
-config-dir=/etc/consul.d \
-config-format=hcl \
-advertise=PRIVATE_IP \
-grpc-port=8502 \
-advertise-wan=${public_ip}

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target
EOF'

sudo sed -i 's|PRIVATE_IP|'$PRIVATE_IP'|g' /etc/systemd/system/consul.service

sudo systemctl daemon-reload
sudo systemctl enable consul
sudo systemctl start consul
sleep 10

echo "*****    Nomad Install    *****"
sudo curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install nomad -y

echo "*****    Bootstrap Nomad    *****"
sudo cat > /etc/nomad.d/server.hcl << EOF
name = "gcp_server"
data_dir  = "/var/lib/nomad"
datacenter = "${datacenter}"
bind_addr = "0.0.0.0"
server {
  enabled = true
  bootstrap_expect = 1
}
consul {
  address = "127.0.0.1:8500"
#  token = "CONSUL_HTTP_TOKEN"
}
advertise {
  http = "${public_ip}:4646"
  rpc  = "PRIVATE_IP:4647"
  serf = "${public_ip}:4648"
}
EOF

# sudo sed -i 's|CONSUL_HTTP_TOKEN|'$CONSUL_HTTP_TOKEN'|g' /etc/nomad.d/server.hcl
sudo sed -i 's|PRIVATE_IP|'$PRIVATE_IP'|g' /etc/nomad.d/server.hcl

sudo systemctl unmask nomad
sudo systemctl enable nomad
sudo systemctl start nomad

echo "*****    Set & start dnsmasq    *****"
sudo sed -i -E "s/^nameserver.*/nameserver $PRIVATE_IP/" /etc/resolv.conf
sudo echo "nameserver 8.8.8.8" > /etc/resolv.dnsmasq
sudo echo "resolv-file=/etc/resolv.dnsmasq" >> /etc/dnsmasq.conf
sudo echo "server=/consul/127.0.0.1#8600" > /etc/dnsmasq.d/10-consul
systemctl enable dnsmasq
systemctl start dnsmasq
systemctl restart dnsmasq