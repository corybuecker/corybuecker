---
title: Setting up Dovecot for IMAP and email submission on Kubernetes (K8s)
published: "2021-04-05T13:03:27Z"
revised: "2021-04-26T03:03:13Z"
preview: Since Dovecot is my IMAP, LMTP, and submission (authorized relay for outgoing email) service, I started there.
description: Since Dovecot is my IMAP, LMTP, and submission (authorized relay for outgoing email) service, I started there.
slug: setting-up-dovecot-for-imap-and-email-submission-on-kubernetes
---

This is the third part of a series aimed at setting up a mail server in Kubernetes (K8s). I recommend reading the first part for [setting up networking in Kubernetes](/post/configuring-kubernetes-and-nginx-ingress-for-a-mail-server) and the second part for [setting up a Network File System (NFS) on Kubernetes](/post/setting-up-network-file-system-nfs-on-kubernetes).

I [published the scripts](https://github.com/corybuecker/k8s-mail) I started with to build and test the configuration as you go, all in the safety of your local development environment.

## A word of warning

Dovecot and Postfix can be _dangerous_ if misconfigured. The risks run from open relaying, where a malicious party forwards spam through your mail server, to unauthorized access of your email.

A core reason for setting these tools up in Kubernetes is that I wanted to study each setting and its impact on deliverability and security. Please take the time to do the same; do not copy settings verbatim from anywhere, including my scripts above.

## Use case

Postfix and Dovecot are extremely flexible, supporting a variety of email server configurations. Rather than try for a more complex setup, my use case is very simple. I have a single domain, and I want to route all email on that domain to a single address. For example, email@example.com and newsletters@example.com both deliver to me@example.com.

This permitted me to explore the most basic settings around virtual domains, authentication, etc.

It also meant that I could have a single permission for my entire mail directory. Dovecot can map user permissions to a single permission, and I can take advantage of this.

## Why Kubernetes?

Postfix and Dovecot have been around for quite a while. Their documentation, for the most part, assumes deployment on standalone servers. Kubernetes has the benefit of standardized configuration via Docker and Helm charts. I have a hobby Kubernetes cluster configured for automatic TLS certificate generation.

My particular Kubernetes cluster is hosted by [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine), so some of the configuration settings may be specific to that product.

### Note on deliverability

The majority of cloud providers, including Google, [block outgoing communication on port 25](https://cloud.google.com/vpc/docs/firewalls#blockedtraffic). This is specifically meant to prevent someone from intentionally or accidentally setting up an open relay.

I decided to use SendGrid to send outgoing emails. This is very easy to configure as part of Dovecot while retaining my ability to submit an authorized email through Dovecot on a submission port.

## Dovecot

Since Dovecot is my IMAP, LMTP, and submission (authorized relay for outgoing email) service, I started there.

### dovecot.conf walkthrough

First, set up some logging to `stdout`. This works well with K8s and Docker as most logging is passed from a container's `stdout` to a central log service.

```bash
# log everything to stdout
auth_debug = yes
auth_verbose_passwords = sha1
auth_verbose = yes
log_path = /dev/stdout
mail_debug = yes
verbose_ssl = yes
```

Next, enable all three protocols. LMTP is perhaps the most unusual setting. The Local Mail Transfer Protocol (LMTP) allows Postfix to pass email to Dovecot and require an immediate success or failure message. In my case, it means that Postfix can pass mail to Dovecot without writing it to disk. Dovecot becomes the single gatekeeper of incoming email. This allows advanced plugins like Sieve to be used for incoming emails.

The non-SSL IMAP service on port 143 is explicitly disabled.

```bash
# IMAP for accessing email
# LTMP so that Postfix can forward SMTP mail to Dovecot
# Submission so that an authenticated user can forward to Sendgrid
protocols = imap lmtp submission

service lmtp {
   inet_listener lmtp {
      address = 0.0.0.0
      port = 24
   }
}

service imap-login {
  inet_listener imap {
    port = 0
  }
}
```

Next up is the [SSL configuration](https://doc.dovecot.org/configuration_manual/dovecot_ssl_configuration/#dovecot-ssl-configuration). For local testing, I've included a self-signed certificate generator that works well for most cases. For a real mail server, a service like Let's Encrypt works extremely well. Just remember to always change the key permissions to `400`.

```bash
# this configuration REQUIRES SSL, which isn't usable if a client only supports STARTTLS
ssl = required

# this syntax allows Dovecot to read a file for a configuration value
ssl_cert = </etc/ssl/dovecot/server.pem
ssl_key = </etc/ssl/dovecot/server.key
```

Because of my simple use case, I only need a single user for authentication! That makes [the `passwd-file` database](https://doc.dovecot.org/configuration_manual/authentication/passwd_file/#authentication-passwd-file) ideal and very simple to implement. Dovecot even supports [multiple encryption schemes](https://doc.dovecot.org/configuration_manual/authentication/password_schemes/#authentication-password-schemes), including Argon2.

An [example of a password file](https://github.com/corybuecker/k8s-mail/blob/main/volumes/dovecot_password_file) is in the GitHub repository for this project.

```bash
passdb {
  driver = passwd-file
  args = /etc/dovecot/private/dovecot_password.file
}

userdb {
  driver = passwd-file
  args = /etc/dovecot/private/dovecot_password.file
  default_fields = home=/home/%u
}
```

The next configuration block is so that Dovecot will relay mail on the [submission service](https://doc.dovecot.org/admin_manual/submission_server) to Sendgrid.

One undocumented detail that I ran into is the SSL requirements of the submission service. According to the `ssl = required` configuration above, I would have expected the submission service to disable STARTTLS in favor of an SSL-only initiated session. However, STARTTLS is the only mode it allows. I'm not sure if this is intentional, but I wrote an [explicit test to ensure that authentication cannot happen without TLS](https://github.com/corybuecker/k8s-mail/blob/f7de84e86aaf527c8a1eae58cae306a82b5d14c8/tests/submission_test.py#L12).

Please see [Integrating with the SMTP API](https://sendgrid.com/docs/for-developers/sending-email/integrating-with-the-smtp-api/) for more information about configuring Sendgrid.

```bash
hostname = mail.example.com
submission_relay_host = # see https://sendgrid.com/docs/for-developers/sending-email/integrating-with-the-smtp-api/
submission_relay_port = # see https://sendgrid.com/docs/for-developers/sending-email/integrating-with-the-smtp-api/
submission_relay_user = # see https://sendgrid.com/docs/for-developers/sending-email/integrating-with-the-smtp-api/
submission_relay_password = </etc/dovecot/private/dovecot_submission_password.file
submission_relay_ssl = smtps
```

The last setting for Dovecot is a [directive to put all mail in a `mail` subdirectory](https://doc.dovecot.org/configuration_manual/mail_location/#mail-location-settings) of the user's home folder. Remember that this is not the dovecot user, but the default home setting in the `userdb`, i.e. `/home/me@example.com/mail`.

```bash
mail_location = maildir:~/mail
```

As I mentioned earlier, all of this is [published on GitHub](https://github.com/corybuecker/k8s-mail). The Docker Compose file also simulates the K8s environment. The tests can be run with Python out of the box.
