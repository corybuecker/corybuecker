---
title: Running a mail server in Kubernetes (K8s), tying it all together
published: 2021-07-13T13:00:53Z
draft: false
preview: It has been some time since I started this project, but in this post I tie up all the parts of running a mail server in Kubernetes (K8s).
description: It has been some time since I started this project, but in this post I tie up all the parts of running a mail server in Kubernetes (K8s).
slug: running-a-mail-server-in-kubernetes-k8s-tying-it-all-together
---

It has been some time since I started this project, but in this post I tie up all the parts of running a mail server in Kubernetes (K8s). I highly recommend reading the first three posts, if you have not already.

1. [Configuring Kubernetes and NGINX Ingress for a mail server](/post/configuring-kubernetes-and-nginx-ingress-for-a-mail-server)
1. [Setting up Network File System (NFS) on Kubernetes](/post/setting-up-network-file-system-nfs-on-kubernetes)
1. [Setting up Dovecot for IMAP and email submission on Kubernetes (K8s)](/post/setting-up-dovecot-for-imap-and-email-submission-on-kubernetes)

In this post, I will walk through the configuratin of Postfix and share the complete configuration in the form of Kubernetes configuration files.

Compared to Dovecot, setting up Postfix is relatively simple. Part of this simplicity is due to using Dovecot as the submission server, along with Sendgrid. Additionally, Dovecot is an LMTP service for Postfix, so the entire Postfix configuration in `/etc/postfix/main.cf` becomes:

```nginx
# Log everything to standard out
maillog_file = /dev/stdout

# Set this to your mail server's public IP address (loadbalancer). This is part of the client IP presevation I mention in the first post.
proxy_interfaces = 1.2.3.4

# this setting has several side-effects, e.g. the domain of this mail
# server is now example.com, http://www.postfix.org/postconf.5.html#mydomain
myhostname = mail.example.com

# disable all compatibility levels
compatibility_level = 9999

virtual_mailbox_domains = example.com
virtual_mailbox_maps = lmdb:/etc/postfix/virtual
virtual_alias_maps = lmdb:/etc/postfix/virtual
virtual_transport = lmtp:dovecot.default.svc.cluster.local:24

```

In the `/etc/postfix/virtual` file, I map the entire domains to a single address.

```bash
@example.com me@example.com
```

At this point, all the pieces of running a mail server in Kubernetes are complete. I frequently prefer looking at code, so all four of these posts have been codifed into [corybuecker/k8s-mail](https://github.com/corybuecker/k8s-mail). Please take the time to understand each setting; do not copy settings verbatim from anywhere, including my scripts above.