Introduction
============

Tarook is a holistic life-cycle management tool based on Ansible, Nix, and Terraform,
designed to deploy a flexible, customizable, highly available, and scalable kubeadm-based Kubernetes
distribution — on OpenStack, Proxmox and bare-metal infrastructures.

Key Features
------------

**Easy deployment and flexible management:**

* Enables simple Kubernetes deployment on OpenStack, Proxmox or bare-metal infrastructures.
* Parameters can be defined via a central configuration.
* Reduces operational overhead and supports the long-term management of Kubernetes environments.

**Scalability and flexibility:**

* Easily adapt your infrastructure to growing demands with centralized configuration based on Nix,
  as well as flexible storage and custom load-balancing solutions.

**High Availability and reliability:**

* Simplifies the setup of highly available Kubernetes clusters.
* Keepalived and HAProxy ensure high availability by safeguarding the Kubernetes API endpoint
  against failures and service disruptions.

**Secrets and identity management:**

* Automated certificate management and fine-grained access control based on HashiCorp Vault ensure high data security.

**NVIDIA GPU and vGPU support:**

* Optimize Kubernetes performance with NVIDIA GPU and vGPU support for accelerated computing.

**Modular architecture:**

* Tarook combines two building blocks:

  * The k8s-core which deploying and managing a kubeadm-based Kubernetes cluster
  * k8s-supplements enhance the core with essential tools and services needed for reliable operations.

**Integrated tools & services:**

Includes integrated tools and services to enable efficient, secure, and scalable Kubernetes operations.

* Cert-Manager: Automates the SSL/TLS certificates management to ensure secure communication inside and outside the cluster.
* Flux: Enabling declarative management of Kubernetes deployments and continuous delivery.
* Ingress NGINX Controller: A powerful ingress controller for routing external traffic to Kubernetes services.
* Kubernetes Monitoring Stack: Monitoring and alerting system integrated into Kubernetes for detailed insights into cluster and application metrics.
* Rook Ceph: Scalable and highly available storage solution for persistent data, integrated directly into Kubernetes with Ceph as the backend.
