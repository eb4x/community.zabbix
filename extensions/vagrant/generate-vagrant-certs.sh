#!/usr/bin/env bash

if [ ! -e files/ca/Vagrant_Root_CA.key ] && [ ! -e files/ca/Vagrant_Root_CA.crt ]; then
    # Create root CA
    openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
      -subj '/CN=Vagrant Root CA' -days 7300 \
      -x509 -extensions v3_ca \
        -addext 'keyUsage = critical, digitalSignature, cRLSign, keyCertSign' \
      -keyout files/ca/Vagrant_Root_CA.key \
      -out files/ca/Vagrant_Root_CA.crt
fi

if [ ! -e files/ca/Vagrant_Intermediate_CA.key ] && [ ! -e files/ca/Vagrant_Intermediate_CA.crt ]; then
    # Create intermediate CA
    openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
        -subj '/CN=Vagrant Intermediate CA' -days 3650 \
        -extensions v3_ca \
          -addext 'keyUsage = critical, digitalSignature, cRLSign, keyCertSign' \
          -addext 'basicConstraints = critical, CA:true, pathlen:0' \
        -set_serial 4096 \
        -CA files/ca/Vagrant_Root_CA.crt -CAkey files/ca/Vagrant_Root_CA.key \
        -keyout files/ca/Vagrant_Intermediate_CA.key \
        -out files/ca/Vagrant_Intermediate_CA.crt
fi

declare -A certificate_days=(
  [zabbix-server-db]=365
#  [zabbix-server]=365
#  [zabbix-proxy]=365
#  [zabbix-web]=365
)

for hostname in ${!certificate_days[*]}; do

  # Don't renew certificates with more than 15 days before expiry.
  if [ -e files/certs/${hostname}.vagrant.local.crt ] && \
     openssl x509 -checkend $((3600*24*15)) -in files/certs/${hostname}.vagrant.local.crt &> /dev/null; then
    continue
  fi

  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -subj "/CN=${hostname}.vagrant.local" -days ${certificate_days[$hostname]} \
    -CA files/ca/Vagrant_Intermediate_CA.crt -CAkey files/ca/Vagrant_Intermediate_CA.key \
    -extensions usr_cert \
      -addext 'keyUsage = critical, digitalSignature, keyEncipherment' \
      -addext 'basicConstraints = critical, CA:FALSE' \
      -addext 'extendedKeyUsage = serverAuth, clientAuth' \
      -addext "subjectAltName=DNS:${hostname}.vagrant.local" \
    -keyout files/certs/${hostname}.vagrant.local.key \
    -out files/certs/${hostname}.vagrant.local.crt

done
