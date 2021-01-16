#!/bin/sh

ETC=inventory/.etc/ipsec/
sudo cp $ETC/swanctl.conf /etc/swanctl/
sudo cp $ETC/server-cert.pem /etc/swanctl/x509/
sudo cp $ETC/ca-cert.pem /etc/swanctl/x509ca/
sudo cp $ETC/charon-systemd.conf /etc/strongswan.d/
sudo systemctl restart strongswan
