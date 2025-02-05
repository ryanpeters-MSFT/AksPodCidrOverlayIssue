$GROUP = "rg-aks-podcidr"
$CLUSTER = "podcidrcluster"

# create the resource group
az group create -n $GROUP --location eastus2

# create a cluster with CNI overlay
az aks create -n $CLUSTER -g $GROUP `
    --network-plugin azure `
    --network-plugin-mode overlay `
    --pod-cidr 192.168.0.0/23 `
    -c 3

# get credentials
az aks get-credentials -n $CLUSTER -g $GROUP --overwrite-existing