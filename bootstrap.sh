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

cat > /home/admin/create-containers.sh << EOF

lxc-create -n  a0420psmygpdaredis07 -t download --  --dist centos --release 8 --arch amd64 
lxc-create -n a0420psmygpdaredis08     -t download --  --dist centos --release 8 --arch amd64 
lxc-create -n a0420psmygpdaredis09  -t download --  --dist centos --release 8 --arch amd64 



echo "taking 5mins rest--->"
sleep 5

echo -e "container created\nstarting the containers---->"


lxc-start -n  a0420psmygpdaredis07 
lxc-start -n a0420psmygpdaredis08   
lxc-start -n a0420psmygpdaredis09

lxc-ls -f 

EOF

chmod +x /home/admin/create-containers.sh
/home/admin/create-containers.sh 

sleep 10
echo "inserting values on hosts files"
lxc-ls -f | awk 'NR>1{print $5,$1}' >> /etc/hosts
lxc-ls -f | awk 'NR>1{print $1}' > /etc/ansible/hosts

echo "generating ssh key pair"
sudo -u admin ssh-keygen -t rsa -N '' -f /home/admin/.ssh/id_rsa <<< y
