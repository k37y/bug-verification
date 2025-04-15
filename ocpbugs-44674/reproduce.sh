oc new-project foo
sleep 2s
oc create deployment onp --image=quay.io/onp/onp-tools -- python3 -m http.server 9900
sleep 2s
oc create service clusterip onp --tcp=9900
sleep 2s
oc expose service onp
sleep 2s
# paste <(oc get netnamespace -o json | jq -r '.items | .[] | .netid' | xargs printf '0x%x\n') <(oc get netnamespace -o json | jq -r '.items | .[] | .netname') | grep foo
sleep 2s
cat << EOF | oc -n foo create -f -
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-by-default
spec:
  podSelector: {}
  ingress: []
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-openshift-ingress
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          network.openshift.io/policy-group: ingress
  podSelector: {}
  policyTypes:
  - Ingress
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-same-namespace
spec:
  podSelector: {}
  ingress:
  - from:
    - podSelector: {}
EOF
paste <(oc get netnamespace -o json | jq -r '.items | .[] | .netid' | xargs printf '0x%x\n') <(oc get netnamespace -o json | jq -r '.items | .[] | .netname') | grep -E 'host-network|foo|openshift-ingress$'
sleep 5s
oc debug node/$(oc get pod -l app=onp -o json | jq -r '.items | .[] | .spec.nodeName') -- chroot /host ovs-ofctl -O OpenFlow13 dump-flows br0 table=80 | grep $(paste <(oc get netnamespace -o json | jq -r '.items | .[] | .netid' | xargs printf '0x%x\n') <(oc get netnamespace -o json | jq -r '.items | .[] | .netname') | grep foo | awk '{print $1}')
