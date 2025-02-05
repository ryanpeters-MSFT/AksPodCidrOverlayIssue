# AKS CNI Overlay Pod CIDR Limitation

This repository summarizes a constraint between the pod CIDR range and the number of nodes available to use. 

The issue is that **if the pod CIDR is too small, then AKS will limit the number of nodes that can be created**. This behavior is because [AKS will pre-allocate 256 (`/24`) pod IPs](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay?tabs=kubectl#overview-of-overlay-networking) from a virtual IP range. As a result, AKS will only create as many nodes as it needs based on the pod CIDR range. 

For example, if a pod CIDR range is small, such as `/19` (8,192 IPs) and each node can support a max (theoretical) of 256 IPs, then this means AKS **only needs** to create 32 nodes (8,192 / 256 = 32). 

```powershell
az aks create -n mycluster -g rg-aks-group `
    --network-plugin azure `
    --network-plugin-mode overlay `
    --pod-cidr 192.168.0.0/19 `
    -c 33
```

If, given the command above, a cluster is created with a node count > 32, it will result in the error below:

```powershell
Code: InsufficientSubnetSize
Message: Pre-allocated IPs 8448 exceeds IPs available 8192 in Subnet Cidr 192.168.0.0/19, Subnet Name networkProfile.podCIDR. If Autoscaler is enabled, the max-count from each nodepool is counted towards this total (which means that pre-allocated IPs count represents a theoretical max value, not the actual number of IPs requested). http://aka.ms/aks/insufficientsubnetsize
Target: networkProfile.podCIDR
```

The error notes the 8,448 pre-allocated IPs exceeds the 8,192 IPs specified in the pod CIDR range. This is because the cluster has specified 33 nodes, which attempts to create 8,448 IPs (256 x 33), when we only need 8,192.

Similarly, a pod CIDR of `/23` (512 IPs) will fail if the cluster node size is 3 or more (3 x 256 = 768 IPs attempted to pre-allocate).

## Notes/Observations
- Even if a smaller number of pods are (i.e., pod limit) is less than 256 (which, almost always, will be), this creates some "waste". 