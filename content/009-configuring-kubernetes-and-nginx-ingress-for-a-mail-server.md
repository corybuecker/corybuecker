---
title: Configuring Kubernetes and NGINX Ingress for a mail server
published: 2021-01-03T17:25:39Z
revised: 2021-04-26T13:07:47Z
draft: false
preview: This is the first of a four-part series aimed at setting up a mail server in Kubernetes (K8s). Mail server software has always confused me. I am approaching this as a learning experience.
description: Configuring Kubernetes and NGINX Ingress for a mail server
slug: configuring-kubernetes-and-nginx-ingress-for-a-mail-server
---

This is the first of a four-part series aimed at setting up a mail server in Kubernetes (K8s). Mail server software has always confused me. I am approaching this as a learning experience. One word of warning; misconfigured mail servers are risky. They can be a mechanism for malicious actors to send spam and malware and make it seem as though you sent it. I recommend against using it as your primary email server until you understand each setting and the networking involved.

I'm using the [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/) with [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine). I'm configuring and deploying the [Ingress with Helm](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx).

## Forwarding source IP addresses

Kubernetes will normally replace the client (external) IP address of ingress connections. This enables a load balancer to forward traffic to any node. If the receiving node does not have a pod from the target service, that [node will forward the traffic to a node with a destination pod](https://kubernetes.io/docs/tutorials/services/source-ip/). In all cases, the final container will receive the traffic as though it originated from the node.

To apply basic Postfix spam filtering, I need to retain the client IP addresses through to the container. This requires two small changes to the Ingress resource.

### External traffic policy

Kubernetes load balancers support two traffic policies: Cluster and Local. The default, Cluster, obscures the client IP address but allows the routing mentioned above. The other, Local, will send the traffic to any healthy node. The key concept is that the health of the node is determined by whether or not it is running a pod served by the load balancer service.

In GKE and Amazon Kubernetes, this can be configured by setting the [external traffic policy of the load balancer to `Local`](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip).

This can [lead to imbalanced traffic](https://www.asykim.com/blog/deep-dive-into-kubernetes-external-traffic-policies) if a node is running more instances of the pod than another. In my case, this is easy to resolve by running the NGINX ingress controller as a `DaemonSet`. Otherwise, nodes without the controller will fail the health check.

```yaml
controller:
  kind: DaemonSet
  service:
    externalTrafficPolicy: Local
```

### Proxy protocol

The client IP is preserved through the load balancer and kube-proxy service. However, it will be still be obscured by NGINX itself. The [proxy protocol](https://www.haproxy.com/blog/haproxy/proxy-protocol/), supported by NGINX and Postfix, can be used to preserve the client IP address to the Postfix container.

This is also supported by the NGINX ingress without any extra work. The [PROXY setting](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/) causes NGINX to enable the proxy protocol for those ports. Configuring these ports is also required to automatically configure the load balancer and firewall settings.

```yaml
tcp:
  993: "default/dovecot:993"
  587: "default/postfix:587"
  25: "default/postfix:25::PROXY"
```

## Putting it together with Helm

I found it helpful to diagram the network architecture.

![PROXY architecture](/images/009-proxy-diagram.png)

Installing the Ingress with the configuration is simple.

```bash
helm upgrade -f ingress-configuration.yaml ingress-nginx ingress-nginx/ingress-nginx --install
```

In this case, `ingress-configuration.yaml` is this file:

```yaml
tcp:
  993: "default/dovecot:993"
  587: "default/postfix:587"
  25: "default/postfix:25::PROXY"
controller:
  kind: DaemonSet
  service:
    externalTrafficPolicy: Local
```
