#! /bin/bash

echo "*****    Installing Utils    *****"
sudo apt update
sudo apt-get install -y \
    wget \
    sshpass \
    unzip \
    apt-transport-https \
    gnupg2\
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    ufw \
    jq \
    dnsmasq

sudo ufw allow 8300 # consule
sudo ufw allow 8301 # consule
sudo ufw allow 8302 # consule
sudo ufw allow 8500 # consule
sudo ufw allow 8502 # consule
sudo ufw allow 8600 # consule
sudo ufw allow 8080 # ingress-gateway
sudo ufw allow 8888 # mesh-gateway
sudo ufw allow 22
sudo ufw --force enable

echo "*****    gcloud login and get join addrs    *****"
sudo echo '${credentials}' > /var/gcp_key.json
gcloud auth activate-service-account --key-file=/var/gcp_key.json --project=${gcp_project}
sudo ssh-keygen -P '' -f '/root/.ssh/id_rsa' -t rsa -b 4096

echo "*****    Download and install Envoy    *****"
sudo curl -sL 'https://getenvoy.io/gpg' | sudo apt-key add -
sudo add-apt-repository \
"deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb \
$(lsb_release -cs) \
stable"
sudo apt-get update
sudo apt-get install -y getenvoy-envoy=1.14.2.p0.g1a0363c-1p66.gfbeeb15

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
-datacenter=${datacenter} \
-node=${consul_name} \
-client=0.0.0.0 \
-bind=PRIVATE_IP \
-encrypt=h65lqS3w4x42KP+n4Hn9RtK84Rx7zP3WSahZSyD5i1o= \
-data-dir=/var/lib/consul \
-config-dir=/etc/consul.d \
-config-format=hcl \
-retry-join=${serverip} \
-grpc-port=8502 \
-advertise=PRIVATE_IP \
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
sudo systemctl enable consul
sudo systemctl start consul
sleep 5

echo "*****    Run mesh gateway    *****"
# consul connect envoy -mesh-gateway -register -service 'gateway-primary' -address $PRIVATE_IP:8080 -wan-address ${public_ip}:8080 -admin-bind 127.0.0.1:19005 -token=$CONSUL_MESH_TOKEN &
consul connect envoy -expose-servers -mesh-gateway -register -service 'gateway-primary' -address $PRIVATE_IP:8080 -wan-address ${public_ip}:8080 -admin-bind 127.0.0.1:19005 &

echo "*****    Register proxy    *****"
sudo cat > /root/proxy-defaults.hcl << EOF
Kind = "proxy-defaults",
Name = "global",
MeshGateway {
  mode = "local"
}
EOF
consul config write /root/proxy-defaults.hcl

sudo cat > /root/service-defaults.hcl << EOF
Kind = "service-defaults",
Name = "web",
MeshGateway {
  mode = "local"
}
EOF
consul config write /root/service-defaults.hcl

echo "*****    Set & start dnsmasq    *****"
sudo sed -i -E "s/^nameserver.*/nameserver $PRIVATE_IP/" /etc/resolv.conf
sudo echo "nameserver 8.8.8.8" > /etc/resolv.dnsmasq
sudo echo "resolv-file=/etc/resolv.dnsmasq" >> /etc/dnsmasq.conf
sudo echo "server=/consul/${serverip}#8600" > /etc/dnsmasq.d/10-consul
systemctl enable dnsmasq
systemctl start dnsmasq
systemctl restart dnsmasq