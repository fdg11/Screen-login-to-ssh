# Admin-tools
Screen login script to ssh (bash)
# Install openvpn server
This script deploys an openvpn server on the Ubuntu OS 16.04. (With the client-to-client directive)'
Builds the script "make_config.sh", in the directory: "~/client-config", to create a config file for clients, in the directory: "~/client-config/files"'
If you need a more fine-tuned configuration for both the server and the client, you can fix them in the following directories:'
- server: /etc/openvpn/"config server file name".conf'
- client: ~/client-configs/files/"client file config file name".conf || ovpn'
