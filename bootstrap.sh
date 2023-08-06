useradd -mG sudo admin -s /usr/bin/bash -d /home/admin
echo "admin:admin" | chpasswd

wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R vagrant:vagrant ~/.ssh

cp -pr /home/vagrant/.ssh /home/admin
chown -R admin:admin /home/admin/.ssh
sudo apt-get update
curl -OL https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
sha256sum go1.16.7.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.16.7.linux-amd64.tar.gz
sudo echo "export PATH=$PATH:/usr/local/go/bin" >> /home/admin/.profile
source /home/admin/.profile
go version


echo "####\nConfiguring docker and LXC------->"
sudo apt-get -y  install lxc docker.io telnet wget vim 
sudo echo "$(id admin -un) veth lxcbr0 10" | sudo tee -a /etc/lxc/lxc-usernet
mkdir -p /home/admin/.config/lxc
cp /etc/lxc/default.conf /home/admin/.config/lxc/default.conf
MS_UID="$(grep "$(id admin -un)" /etc/subuid  | cut -d : -f 2)"
ME_UID="$(grep "$(id admin -un)" /etc/subuid  | cut -d : -f 3)"
MS_GID="$(grep "$(id admin -un)" /etc/subgid  | cut -d : -f 2)"
ME_GID="$(grep "$(id admin -un)" /etc/subgid  | cut -d : -f 3)"
echo "lxc.idmap = u 0 $MS_UID $ME_UID" >> /home/admin/.config/lxc/default.conf
echo "lxc.idmap = g 0 $MS_GID $ME_GID" >> /home/admin/.config/lxc/default.conf

echo "docker compose --->"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo usermod -aG docker admin

echo "installing kind------>"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /bin/kind
git clone https://github.com/mdjahidanwar/kind-cluster.git

echo "ansible -->"
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible -y 

echo "[nodes]" > /etc/ansible/hosts


#start=0
#while [[ $start -le $3 ]]
#do 
#echo "$1$3 ansible_host=$2$3" >> /etc/ansible/hosts
#echo "$1$3 $2$3" >> /etc/hosts
#(( start = start + 1))
#done
