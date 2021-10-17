---
title: Setting up Network File System (NFS) on Kubernetes
published: 2021-01-30 10:21:26
revised: 2021-02-28T20:21:26Z
draft: false
preview: Before getting to Postfix and Dovecot, I need a large storage space for email. Kubernetes' persistent volumes work very well, but they have a specific limitation for this use case.
description: Before getting to Postfix and Dovecot, I need a large storage space for email. Kubernetes' persistent volumes work very well, but they have a specific limitation for this use case.
slug: setting-up-network-file-system-nfs-on-kubernetes
---

This is the second part in a series aimed at setting up a mail server in Kubernetes (K8s). I recommend reading the first part for [setting up networking in Kubernetes](/post/configuring-kubernetes-and-nginx-ingress-for-a-mail-server).

## Why Kubernetes?

Postfix and Dovecot have been around for quite a while. Their documentation, for the most part, assumes deployment on standalone servers. Kubernetes has the benefit of standardized configuration via Docker and Helm charts. I have a hobby Kubernetes cluster configured for automatic TLS certificate generation.

My particular Kubernetes cluster is hosted by [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine), so some of the configuration settings may be specific to that product.

## NFS

Before getting to Postfix and Dovecot, I need a large storage space for email. Kubernetes' persistent volumes work very well, but they have a specific limitation for this use case. The [access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for most volumes is `ReadWriteOnce`. This means the volume is attached to a single node at a time. For a mail server, I want multiple pods, across multiple nodes, of Dovecot to be able to read and write to the same volume. Otherwise, some email would be written to volume A and some to volume B.

There are only a few volume types that support `ReadWriteMany`, but the easiest to configure is NFS.

### Dedicated instance

This is the rare case where I setup a instance outside of the K8s cluster to dedicate it as a NFS server. In the future, I may explore moving this instance into K8s. It's a bit hypocritical because Postfix and Dovecot are also largely setup on dedicated servers. That said, I am more interested in getting a mail server setup than setting up NFS in K8s.

I'm using an Ubuntu 20.04.1 LTS image for the standalone VM. I'm using a externally mounted volume (/dev/sdb) to actually serve as the NFS drive. Installing NFS itself is as simple as:

```bash
sudo apt install nfs-kernel-server
```

Setting up the external mount is also straightforward:

```bash
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/network_storage_disk
sudo mount -o discard,defaults /dev/sdb /mnt/disks/network_storage_disk
```

Once the volume is mounted, edit `/etc/fstab` to ensure that it's mounted on reboot. First, find the UUID of the device.

```bash
root@network-storage:~$ blkid /dev/sdb
/dev/sdb: UUID="433da51c-bc78-4a9f-b962-2ef0b55b8f0f" TYPE="ext4"
```

The UUID of the drive can then be used in `/etc/fstab`.

```bash
UUID=433da51c-bc78-4a9f-b962-2ef0b55b8f0f /mnt/disks/network_storage_disk ext4 discard,defaults,nofail 0 2
```

Next, create a new directory on the network drive to use for Postfix and Dovecot. I'm giving ownership of the directory to `nobody`, which is a special Linux user without any permissions. Because I'm not running a multi-user system, I'm using the [`all_squash` NFS option](https://linux.die.net/man/5/exports).

```bash
sudo mkdir -p /mnt/disks/network_storage_disk/mailserver
sudo chown nobody:nogroup /mnt/disks/network_storage_disk/mailserver
```

The last step is setting up the NFS export. In `/etc/exports`, add the directory and then restart NFS.

```bash
root@network-storage:~$ cat /etc/exports 
# /etc/exports: the access control list for filesystems which may be exported
#		to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#

/mnt/disks/network_storage_disk/mailserver *(rw,all_squash,sync,no_subtree_check)

root@network-storage:~$ systemctl restart nfs-kernel-server
```

### Networking

I'm using private networking for my GKE cluster, so allowing networking on the VM is as simple as adding the correct networking tag to the VM. GKE's firewall is setup to allow all internal network traffic by default. Take care not to expose any ports on this VM to the Internet if you are assigning it a public IP address. Take a look at a tool called `socat` for a convenient way to SSH tunnel through K8s into this VM.

I'll write a future post about GCE and GKE networking.

## Kubernetes

Setting up NFS is the hardest part of this setup. Configuring K8s very easy and only requires `PersistentVolume` and `PersistentVolumeClaim` objects. Replace `{internal_vm_ip_address}` with the correct IP address.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: network-storage-mailserver
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: /mnt/disks/network_storage_disk/mailserver
    server: {internal_vm_ip_address}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: network-storage-mailserver-claim
spec:
  storageClassName: nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
```
