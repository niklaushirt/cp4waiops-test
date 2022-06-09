oc delete secret ibm-entitlement-key -n cp4waiops
oc delete secret ibm-aiops-pull-secret -n cp4waiops
oc delete secret ibm-entitlement-key -n cp4waiops-evtmgr
oc delete secret ibm-aiops-pull-secret -n cp4waiops-evtmgr
oc delete secret ibm-entitlement-key -n openshift-marketplace
oc delete secret ibm-aiops-pull-secret -n openshift-marketplace
oc delete secret ibm-entitlement-key -n openshift-operators
oc delete secret ibm-aiops-pull-secret -n openshift-operators




oc create ns cp4waiops
oc create ns cp4waiops-evtmgr

export DOCKER_USER=your_docker_username
export DOCKER_PWD=your_docker_password

export ICR_TOKEN=your_IBM_PULL_TOKEN

export ARTIFACTORY_USER=yourIBMeMail
export ARTIFACTORY_TOKEN=changeme

oc get secret/pull-secret -n openshift-config -oyaml > pull-secret-backup.yaml
oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > temp-pull-secret.yaml
oc registry login --registry="docker.io" --auth-basic="$DOCKER_USER:$DOCKER_PWD" --to=temp-pull-secret.yaml
oc registry login --registry="hyc-katamari-cicd-team-docker-local.artifactory.swg-devops.com" --auth-basic="$ARTIFACTORY_USER:$ARTIFACTORY_TOKEN" --to=temp-pull-secret.yaml
oc registry login --registry="cp.icr.io" --auth-basic="cp:$ICR_TOKEN" --to=temp-pull-secret.yaml
oc registry login --registry="cp.stg.icr.io" --auth-basic="cp:$ICR_TOKEN" --to=temp-pull-secret.yaml
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=temp-pull-secret.yaml

oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > temp-ibm-entitlement-key.yaml


oc create secret generic ibm-entitlement-key -n cp4waiops --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml
oc create secret generic ibm-entitlement-key -n cp4waiops-evtmgr --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml
oc create secret generic ibm-entitlement-key -n openshift-marketplace --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml
oc create secret generic ibm-entitlement-key -n openshift-operators --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml

oc create secret generic ibm-aiops-pull-secret -n cp4waiops --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml
oc create secret generic ibm-aiops-pull-secret -n cp4waiops-evtmgr --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml
oc create secret generic ibm-aiops-pull-secret -n openshift-marketplace --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml
oc create secret generic ibm-aiops-pull-secret -n openshift-operators --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=temp-ibm-entitlement-key.yaml



exit 1


# Then run
ansible-playbook ./ansible/99_test.yaml  -e ENTITLED_REGISTRY_KEY=$ICR_TOKEN


# If you get pull errors execute this
kubectl patch -n openshift-marketplace serviceaccount default -p '{"imagePullSecrets": [{"name": "ibm-entitlement-key"}]}'
kubectl patch -n openshift-marketplace serviceaccount ibm-operator-catalog -p '{"imagePullSecrets": [{"name": "ibm-entitlement-key"}]}'
oc delete pod $(oc get po -n openshift-marketplace|grep ImagePull|awk '{print$1}') -n openshift-marketplace

