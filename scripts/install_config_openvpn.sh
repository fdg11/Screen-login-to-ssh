#!/usr/bin/env bash
#Version 1.0.0
#First argument: Client identifier

#Global Variables:
SERV_DIR=~/openvpn-ca
CLIENT_DIR=~/client-configs

#Checking for arguments:
if [ $# != 1 ] || [ "$1" = "--help" ]; then
	echo -e "Using: install_config_openvpn.sh [parameter...] or --help"
	echo -e "Parameters are not entered: the name of the config file for the server"
	echo -e "Example: install_config_openvpn.sh server"
	exit 1
fi

#Checking for iptables & gzip:
ipt=$(dpkg -s iptables 2> /dev/null | grep Status | awk '{print $3}')
gzi=$(dpkg -s gzip 2> /dev/null | grep Status | awk '{print $3}')
if [ "$ipt" != "ok" ]; then
	echo -e "The iptables package is not installed"
	exit 1
elif [ "$gzi" != "ok" ]; then
	echo -e "The gzip package is not installed"
	exit 1
fi

#Checking for openvpn:
ovpn=$(dpkg -s openvpn 2> /dev/null | grep Status | awk '{print $3}')
if [ "$ovpn" = "ok" ]; then
    echo -e "The openvpn package is installed"
    exit 1
fi

#Update & upgrade & install openvpn server:
apt-get update && apt upgrade -y
apt-get install openvpn easy-rsa curl -y
apt-get autoremove -y && apt-get autoclean && apt-get clean

#Creating a directory easy-rsa:
make-cadir $SERV_DIR

#Preparing server certificates:
cd $SERV_DIR
source vars 
./clean-all 
./build-ca 
./build-key-server ${1}
./build-dh 
openvpn --genkey --secret keys/ta.key 
cd $SERV_DIR/keys/
cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn

#Preparing the server configuration:
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | tee /etc/openvpn/base.conf
sed '/proto udp/s/^/;/;/proto tcp/s/;//;/client-to-client/s/;//;/tls-auth/s/;//;/cipher AES-128-CBC/s/;//;/max-clients/s/;//;/user/s/;//;/group/s/;//;/log/s/;//;/^log-append/s/^/;/;/mute/s/;//;/^topology subnet/s/^/;/;/cipher DES-EDE3-CBC/a\auth SHA256' /etc/openvpn/base.conf > /etc/openvpn/${1}.conf
echo -e "key-direction 0" >> /etc/openvpn/${1}.conf

#Allow forwarding of packets and iptables nat tun:
sysctl -w net.ipv4.ip_forward=1
sysctl -p
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o tun+ -j MASQUERADE
iptables-save > /etc/iptables
echo "        #iptables nat tun" >> /etc/network/interfaces
echo "	      pre-up iptables-restore < /etc/iptables" >> /etc/network/interfaces 

#We learn our ip:
MYIP=$(curl -s ifconfig.me/ip)

#Preparing the client configuration:
mkdir -p $CLIENT_DIR/files
chmod 700 $CLIENT_DIR/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf $CLIENT_DIR/base.conf
sed -i '/proto udp/s/^/;/;/proto tcp/s/;//;/remote/s/my-server-1/'$MYIP'/;/ca/s/^/#/;/cert/s/^/#/;/key/s/^/#/;/remote-cert-tls/s/#//;s/;cipher x/cipher AES-128-CBC/' \
$CLIENT_DIR/base.conf 
sed -i '/cipher AES-128-CBC/a \auth SHA256' $CLIENT_DIR/base.conf
echo "key-direction 1" >> $CLIENT_DIR/base.conf
echo "#script-security 2" >> $CLIENT_DIR/base.conf
echo "#up /etc/openvpn/update-resolv-conf" >> $CLIENT_DIR/base.conf
echo "#down /etc/openvpn/update-resolv-conf" >> $CLIENT_DIR/base.conf

#Create make_config.sh script:
cat <<EOF > ~/client-configs/make_config.sh
#!/usr/bin/env bash
# First argument: Key OS  
# Second argument: Client identifier

#Local Variables:
KEY_DIR=$CLIENT_DIR/keys
OUTPUT_DIR=$CLIENT_DIR/files
BASE_CONFIG=$CLIENT_DIR/base.conf

#Checking for arguments:
if [ \$# != 2 ] || [ "\${1}" = "--help" ]; then
        echo -e "Using: make_config.sh [key-client OS]: -w - Windows, -o - Mac OSX, -l - GNU/Linux or --help and [parameter1...]"
        echo -e "Use the -r key to lock the client certificate and delete the config file"
	echo -e "Example: make_config.sh -w client1 - (create client)"
        echo -e "Example: make_config.sh -r client1 - (delete client)"
	exit 1
fi

#Preparing server certificates:
if [ "\${1}" != "-r" ]; then
	cd $SERV_DIR
	source vars
	./build-key \${2}

#Description of the key logic:
	if [ "\${1}" = "-w" ] || [ "\${1}" = "-o" ]; then
		cat \${BASE_CONFIG} \
    		<(echo -e '<ca>') \
    		\${KEY_DIR}/ca.crt \
    		<(echo -e '</ca>\n<cert>') \
    		\${KEY_DIR}/\${2}.crt \
    		<(echo -e '</cert>\n<key>') \
    		\${KEY_DIR}/\${2}.key \
    		<(echo -e '</key>\n<tls-auth>') \
    		\${KEY_DIR}/ta.key \
    		<(echo -e '</tls-auth>') \
    		> \${OUTPUT_DIR}/\${2}.ovpn
	elif [ "\${1}" = "-l" ]; then

		sed -i '/^#script-security/s/#//g' \${BASE_CONFIG}
		sed -i '/^#up/s/#//g' \${BASE_CONFIG}
		sed -i '/^#down/s/#//g' \${BASE_CONFIG}

		cat \${BASE_CONFIG} \
    		<(echo -e '<ca>') \
    		\${KEY_DIR}/ca.crt \
    		<(echo -e '</ca>\n<cert>') \
    		\${KEY_DIR}/\${2}.crt \
    		<(echo -e '</cert>\n<key>') \
    		\${KEY_DIR}/\${2}.key \
    		<(echo -e '</key>\n<tls-auth>') \
    		\${KEY_DIR}/ta.key \
    		<(echo -e '</tls-auth>') \
    		> \${OUTPUT_DIR}/\${2}.conf
	else	
		echo -e "Keys are not entered: the key may be: -w, -o, -l"
		exit 1		
	fi

elif [ "\${1}" = "-r" ]; then
    cd $SERV_DIR
    source vars &> /dev/null
    ./revoke-full \${2} &> /dev/null
    cp $SERV_DIR/keys/crl.pem /etc/openvpn
    rm -f \${OUTPUT_DIR}/\${2}.conf || \${OUTPUT_DIR}/\${2}.ovpn &> /dev/null
	cat /etc/openvpn/${1}.conf | grep crl-verify -q
	
	if [ "\$?" != 0 ]; then 
		echo -e "crl-verify crl.pem" >> /etc/openvpn/${1}.conf 
	fi
	
	systemctl restart openvpn@${1}
    echo -e "Client: \${2} Was deactivated!"
else
	echo -e "Keys are not entered: the key may be: -w, -o, -l, -r"
    exit 1          
fi
EOF

#Startup rights:
chmod 700 $CLIENT_DIR/make_config.sh

#Adding to autostart and server restart:
systemctl enable openvpn@${1}
systemctl start openvpn@${1}

#Description:
echo -e '\n## - Description:'
echo -e '## This script deploys an openvpn server on the Ubuntu OS 16.04. (With the client-to-client directive)'
echo -e '## Builds the script "make_config.sh", in the directory: "~/client-config", to create a config file for clients, in the directory: "~/client-config/files"'
echo -e '## If you need a more fine-tuned configuration for both the server and the client, you can fix them in the following directories:'
echo -e '## - server: /etc/openvpn/"config server file name".conf'
echo -e '## - client: ~/client-configs/files/"client file config file name".conf || ovpn'