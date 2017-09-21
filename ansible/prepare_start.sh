#! /usr/bin/env bash 

SSHKEYDIR=~/.ssh/id_rsa
WORKDIR=/admin/ansible

mkdir -p $WORKDIR/modules $WORKDIR/logs

if [ -f "$SSHKEYDIR" ]; then
	echo -e "SSH key genered!"
else 
	ssh-keygen -t rsa -b 2048 -N '' -C "ansible manager" -f $SSHKEYDIR
	chmod 600 $SSHKEYDIR && chmod 644 $SSHKEYDIR.pub
fi

j=1

if [ "$#" -gt 0 ]; then 
	for i in $@; do
		ssh-copy-id root@$i
		arg[$j]=$i
		let j++
		PY=$(ssh root@$i 'dpkg -l | grep python-minimal')
		if [ -z $PY ]; then
			ssh root@$i 'apt-get update && 	apt-get install python-minimal -y' 
		fi
	done
else
	echo -e "Not entered parametrs!!!"
fi

cat <<EOF > $WORKDIR/hosts
# hosts list
[cluster]
EOF

for c in ${arg[@]}; do
	echo $c >> $WORKDIR/hosts
done 

cat <<EOF > $WORKDIR/ansible.cfg
[defaults]
inventory = $WORKDIR/hosts
log_path = $WORKDIR/logs/ansible.log
EOF

ansible cluster -m ping  	
