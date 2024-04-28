#!/bin/bash

# Set NameCheap DNS environment variables
set_namecheap_dns_env_vars() {
  export NameCheapHost=$1
  export NameCheapDomain=$2
  export NameCheapPassword=$3
  echo "Environment variables set for NameCheap DNS."
}

# Get NameCheap DNS credentials
get_namecheap_dns_credential() {
  CurrentIP=$(curl -s https://dynamicdns.park-your-domain.com/getip)
  NameCheapDNSCredential="host=$NameCheapHost&domain=$NameCheapDomain&password=$NameCheapPassword&ip=$CurrentIP"
  echo $NameCheapDNSCredential
}

# Update NameCheap DNS
update_namecheap_dns() {
  NameCheapParams=$(get_namecheap_dns_credential)
  NameCheapUpdateUrl="https://dynamicdns.park-your-domain.com/update?$NameCheapParams"
  Result=$(curl -s $NameCheapUpdateUrl | grep -i ErrCount | cut -d">" -f2 | cut -d"<" -f1)
  if [[ $Result == 0 ]]; then
    echo "Update Successful"
  else
    echo "Failed to update"
  fi
}

# Example usage:
# set_namecheap_dns_env_vars "host" "example.com" "password"
# update_namecheap_dns
