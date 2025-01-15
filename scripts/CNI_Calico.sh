#!/bin/bash

#Calico over Flannel as the CNI (Container Network Interface)

# remove flannel if installed!
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# open firewall ports
sudo ufw allow proto tcp from any to any port 443
# BGP
sudo ufw allow proto tcp from any to any port 179
sudo ufw allow proto udp from any to any port 9099

# install calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "You need to open firewall ports to worker noders too !"

