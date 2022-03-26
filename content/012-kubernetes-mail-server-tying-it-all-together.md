---
title: Running a mail server in Kubernetes (K8s), tying it all together
published: "2021-07-13T13:03:27Z"
revised: "2021-07-18T03:03:13Z"
preview: In this post I tie up all the parts of running a mail server in Kubernetes (K8s)
description: In this post I tie up all the parts of running a mail server in Kubernetes (K8s)
slug: kubernetes-mail-server-tying-it-all-together
---

It has been some time since I started this project, but in this post I tie up all the parts of running a mail server in Kubernetes (K8s). I highly recommend reading the first three posts, if you have not already.

1. [Configuring Kubernetes and NGINX Ingress for a mail server](/post/configuring-kubernetes-and-nginx-ingress-for-a-mail-server)
1. [Setting up Network File System (NFS) on Kubernetes](/post/setting-up-network-file-system-nfs-on-kubernetes)
1. [Setting up Dovecot for IMAP and email submission on Kubernetes (K8s)](/post/setting-up-dovecot-for-imap-and-email-submission-on-kubernetes)

In this post, I will walk through the configuratin of Postfix and share the complete configuration in the form of Kubernetes configuration files.

## Docker image

The entire Dockerfile for Postfix is:

```docker
FROM alpine:3

RUN apk --no-cache add postfix openssl bash
COPY main.cf virtual /etc/postfix/
COPY startup.sh /usr/bin/

CMD ["startup.sh"]
```

Compared to Dovecot, setting up Postfix is relatively simple. Part of this simplicity is due to using Dovecot as the submission server, along with Sendgrid. Additionally, Dovecot is an LMTP service for Postfix, so the entire Postfix configuration in `/etc/postfix/main.cf` becomes:

```plaintext
# Log everything to standard out
maillog_file = /dev/stdout

# this setting has several side-effects, e.g. the domain of this mail
# server is now example.com, http://www.postfix.org/postconf.5.html#mydomain
myhostname = mail.example.com

# disable all compatibility levels
compatibility_level = 9999

# Configure Postfix to expect the proxy protocol, since
# traffic on port 25 proxied through the NGINX ingress.
smtpd_upstream_proxy_protocol = haproxy

virtual_mailbox_domains = example.com
virtual_mailbox_maps = lmdb:/etc/postfix/virtual
virtual_alias_maps = lmdb:/etc/postfix/virtual
virtual_transport = lmtp:dovecot.default.svc.cluster.local:24
```

In the `/etc/postfix/virtual` file, I map the entire domain to a single address.

```plaintext
@example.com me@example.com
```

The startup script is needed to compile the virtual database and then replace the running process with `postfix`.

```bash
#!/bin/bash

set -ex

newaliases
postmap /etc/postfix/virtual

exec postfix start-fg
```

At this point, all the pieces of running a mail server in Kubernetes are complete. I frequently prefer looking at code, so all four of these posts have been codifed into [corybuecker/k8s-mail](https://github.com/corybuecker/k8s-mail). Please take the time to understand each setting; do not copy settings verbatim from anywhere, including my scripts above.
