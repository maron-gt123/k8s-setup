#!/usr/bin/env bash

# region : set variables
TARGET_BRANCH=$1
TEMPLATE_VMID=9999
VMID_1=201
VMID_2=202
TARGETIP_1=192.168.1.141
TARGETIP_2=192.168.1.142
# endregion


# stop vm
ssh "${TARGETIP_2}" qm stop "${VMID_1}"
ssh "${TARGETIP_3}" qm stop "${VMID_2}"

# delete vm
## on onp-proxmox01-SV
ssh "${TARGETIP_1}" qm destroy "${VMID_1}" --destroy-unreferenced-disks true --purge true
ssh "${TARGETIP_1}" qm destroy "${TEMPLATE_VMID}" --destroy-unreferenced-disks true --purge true
## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s

## on onp-proxmox02-SV
ssh "${TARGETIP_2}" qm destroy "${VMID_2}" --destroy-unreferenced-disks true --purge true
## wait due to prevent to cluster-data mismatch on proxmox
sleep 20s
