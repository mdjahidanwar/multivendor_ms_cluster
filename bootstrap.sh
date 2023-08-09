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

#!/bin/bash

# nodes=( a0420smmcmsdamonitor01 a0420snemcmsdalb01 a0420snemcmsdalb02 a0420ssecdapmcmscas01 a0420ssecdapmcmscas02 a0420ssecdapmcmscas03 a0420ssecmcmsdaes01 a0420ssecmcmsdaes02 a0420ssecmcmsdaes03  a0420ssecmcmsdarmq01 a0420ssecmcmsdarmq02 )
# for i in "${nodes[@]}"
# do
# echo "creating container $i --->>"
# lxc-create -n  $i -t download --  --dist centos --release 7 --arch amd64 
# lxc-create -n  $i -t download --  --dist centos --release 7 --arch amd64 
# done

lxc-create -n  a0420smmcmsdamonitor01 -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420snemcmsdalb01     -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420snemcmsdalb02  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecdapmcmscas01  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecdapmcmscas02  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecdapmcmscas03  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecmcmsdaes01  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecmcmsdaes02  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecmcmsdaes03  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecmcmsdarmq01  -t download --  --dist centos --release 7 --arch amd64 
lxc-create -n a0420ssecmcmsdarmq02    -t download --  --dist centos --release 7 --arch amd64 

echo "taking 5mins rest--->"
sleep 5

echo -e "container created\nstarting the containers---->"
# for i in "${nodes[@]}"
# do
# echo "creating container $i --->>"
# lxc-start -n  $i 
# done


lxc-start -n  a0420smmcmsdamonitor01 
lxc-start -n a0420snemcmsdalb01   
lxc-start -n a0420snemcmsdalb02   
lxc-start -n a0420ssecdapmcmscas01   
lxc-start -n a0420ssecdapmcmscas02   
lxc-start -n a0420ssecdapmcmscas03   
lxc-start -n a0420ssecmcmsdaes01   
lxc-start -n a0420ssecmcmsdaes02   
lxc-start -n a0420ssecmcmsdaes03   
lxc-start -n a0420ssecmcmsdarmq01  
lxc-start -n a0420ssecmcmsdarmq02  

lxc-ls -f 

EOF

chmod +x /home/admin/create-containers.sh
/home/admin/create-containers.sh 

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

sleep 10
echo "inserting values on hosts files"
lxc-ls -f | awk 'NR>1{print $5,$1}' >> /etc/hosts
lxc-ls -f | awk 'NR>1{print $1}' > /etc/ansible/hosts

sed -i '/^a0420smmcmsdamonitor01.*/i [monitor]' /etc/ansible/hosts
sed -i '/^a0420snemcmsdalb01.*/i [lb]' /etc/ansible/hosts
sed -i '/^a0420ssecdapmcmscas01.*/i [cas]' /etc/ansible/hosts
sed -i '/^a0420ssecmcmsdaes01.*/i [es]' /etc/ansible/hosts
sed -i '/^a0420ssecmcmsdarmq01.*/i [mq]' /etc/ansible/hosts

echo "generating ssh key pair"
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y





#start=0
#while [[ $start -le $3 ]]
#do 
#echo "$1$3 ansible_host=$2$3" >> /etc/ansible/hosts
#echo "$1$3 $2$3" >> /etc/hosts
#(( start = start + 1))
#done
