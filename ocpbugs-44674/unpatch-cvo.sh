#!/bin/bash

update_cno ()
{
    oc patch clusterversion version --type json -p '[{"op":"remove","path":"/spec/overrides/0"}]'
}

custom_sdn ()
{
    oc -n openshift-network-operator scale --replicas=1 deployment/network-operator
}

update_cno
custom_sdn
