#!/bin/bash

update_cno ()
{
    oc patch clusterversion version --type json -p '[{"op":"add","path":"/spec/overrides","value":[{"kind":"Deployment","group":"apps","name":"network-operator","namespace":"openshift-network-operator","unmanaged":true}]}]'
    # oc patch clusterversion version --type json -p '[{"op":"remove","path":"/spec/overrides/0"}]'
}

custom_sdn ()
{
    oc -n openshift-network-operator scale --replicas=0 deployment/network-operator
    oc -n openshift-sdn set image ds/sdn sdn=quay.io/kevy/sdn@sha256:364c44ffd363a86ec511e637326753ccdc6a9035cb5b2448e712ff8ca20331e9
}

update_cno
custom_sdn
