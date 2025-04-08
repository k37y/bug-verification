#!/bin/bash

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
NC="\033[0m" # No Color

echo -e "${YELLOW}Note the number of Pod restarts ...${NC}"
oc -n openshift-ovn-kubernetes get pod

echo -e "${BLUE}Note current OVN cert dates ...${NC}"
CERT=$(oc -n openshift-ovn-kubernetes rsh -c ovnkube-master ds/ovnkube-master \
  /usr/bin/openssl s_client -connect 10.128.0.2:9107 </dev/null 2>/dev/null | \
  /usr/bin/openssl x509 -noout -dates | tee /dev/tty)

echo -e "${RED}Deleting the current OVN cert secret ...${NC}"
oc -n openshift-ovn-kubernetes delete secret ovn-cert

echo -e "${BLUE}Wait till the new OVN cert secret appears ...${NC}"
while ! oc -n openshift-ovn-kubernetes get secret ovn-cert &>/dev/null; do sleep 1; done
oc -n openshift-ovn-kubernetes get secret ovn-cert

echo -e "${BLUE}Note current OVN cert dates ...${NC}"
openssl x509 -noout -dates <<< "$(oc -n openshift-ovn-kubernetes get secret ovn-cert -o jsonpath='{.data.tls\.crt}' | base64 -d)"

echo -e "${BLUE}Wait till the new cert reflects on the :9107 endpoint ...${NC}"
while diff <(echo "$CERT") <(echo "$(oc -n openshift-ovn-kubernetes rsh -c ovnkube-master ds/ovnkube-master \
  /usr/bin/openssl s_client -connect 10.128.0.2:9107 </dev/null 2>/dev/null | \
  /usr/bin/openssl x509 -noout -dates)"); do sleep 3; done

echo -e "${YELLOW}Note the number of Pod restarts ...${NC}"
oc -n openshift-ovn-kubernetes get pod
