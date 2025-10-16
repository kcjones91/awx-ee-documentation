# Process Documentation for Creating a Custom Execution Environment (EE)

This repository provides a complete, GitHub‑ready guide for building a **custom Ansible Execution Environment (EE)** with **ansible-builder**. It includes example config files and explains exactly what to edit for your use case.

---

## Overview

You will use three files to define your EE:

- **`execution-environment.yml`** – the main build definition for `ansible-builder` (base image, build steps, and where to find dependency lists).
- **`requirements.txt`** – Python packages to install into the EE image.
- **`requirements.yml`** – Ansible Galaxy collections to pre-install into the EE image.

Once built and tested locally, tag and push the image to your container registry and reference it in **AWX / Automation Controller** under **Execution Environments**.

---

## Prerequisites

- **This repo**
  - Make sure to clone this repo.
- **System**
  - RHEL 9 / CentOS Stream 9 host (or compatible) with a container runtime: **Podman** (recommended) or Docker.
  - Python 3.
- **Tools**
  - `ansible-builder` (installed in a virtualenv or system-wide).
- **Access**
  - A container registry where you can push images (e.g., Quay, GHCR, ECR).
  - Network access to pull base images and collections.
    

### Create a virtual enviornment

```bash
python3.11 -m venv ~/venv/ansible
source ~/venv/ansible/bin/activate
python3 -m pip install --upgrade pip
pip install ansible-builder ansible-navigator ansible-lint
```

---

## Understanding the Files

### 🧩 `execution-environment.yml` (main build file)

This file instructs `ansible-builder` how to assemble the image. Below is the example you provided (trimmed for focus) with notes:

```yaml
---
version: 3

images:
  base_image:
    name: quay.io/centos/centos:stream9   # Base OS image (change if you need RHEL UBI, etc. Recommend to keep the same or use redhat official images)

dependencies:
  ansible_core:
    package_pip: ansible-core>=2.15.8     # Pin for reproducibility -- Ansible version here
  ansible_runner:
    package_pip: ansible-runner
  galaxy: requirements.yml                 # Where Ansible collections are listed
  python: requirements.txt                 # Where Python packages are listed

additional_build_steps:
  append_base:
    - RUN yum upgrade -y
    - RUN yum install -y python3 python3-pip python3-devel gcc epel-release
    - RUN yum install -y krb5-devel krb5-libs krb5-workstation
    - RUN python3 -m pip install --upgrade --force pip
    - RUN pip3 install pypsrp[kerberos]
    - RUN pip3 install pyVim PyVmomi
    - COPY --from=quay.io/project-receptor/receptor:latest /usr/bin/receptor /usr/bin/receptor
    - RUN mkdir -p /var/run/receptor
```

**What to customize:**
- **Base image**: keep `centos:stream9` or switch to an approved enterprise base (e.g., UBI 9).
- **Pinned versions**: consider pinning `ansible-core` to an exact version for reproducible builds.
- **System packages**: add/remove `yum` packages your playbooks need (e.g., `git`, `jq`, `openssl`).
- **Receptor**: the `COPY --from=... receptor` step brings the receptor binary into the EE (useful for AAP/mesh). Keep or remove based on your needs.

> Tip: Avoid putting secrets here—this file is committed to your repo.

---

### 🐍 `requirements.txt` (Python dependencies)

Your example:
```text
dnspython
pykerberos
pywinrm
awxkit==21.6.0
urllib3
python-tss-sdk
```

**Customize tips:**
- Add any **Python modules** your roles/playbooks or custom scripts import.
- Prefer **pinned versions** in production, e.g., `urllib3==1.26.18`.
- Do **not** add `ansible`/`ansible-core` here (handled by `execution-environment.yml`).

---

### 🌌 `requirements.yml` (Ansible Galaxy collections)

Your example:
```yaml
collections:
  - name: ansible.netcommon
  - name: ansible.utils
  - name: ansible.windows
  - name: community.crypto
  - name: community.dns
  - name: community.docker
  - name: community.general
  - name: community.grafana
  - name: community.network
  - name: community.windows
  - name: microsoft.ad
```

**Customize tips:**
- Remove collections you don’t use to **reduce image size**.
- Add private/enterprise sources by specifying `source:` (e.g., private Automation Hub).
- Ensure version compatibility with your `ansible-core` pin.

Example with versions and a private source:
```yaml
collections:
  - name: ansible.utils
    version: 4.1.0
  - name: community.general
    version: 8.6.2
  - name: myco.platform
    source: https://automation-hub.myco.local/api/galaxy/content/published/
    version: '>=1.2.0,<2.0.0'
```

---

## Build the Execution Environment

From the repository root (where `execution-environment.yml` lives):

```bash
# This step could take about 15 minutes try verbose mode to be safe!
ansible-builder build -f execution-environment.yml -t custom-ee:latest
# For Podman users, this builds a local image "localhost/custom-ee:latest"
```

```bash
# For verbosity
ansible-builder build -f -vvv execution-environment.yml -t custom-ee:latest
# For Podman users, this builds a local image "localhost/custom-ee:latest"
```

List images:
```bash
podman images   # or: docker images
```

Run a test shell (this will be inside the container we created:
```bash
podman run -it --rm custom-ee:latest bash
ansible --version
ansible-galaxy collection list
python3 -c "import pywinrm, dnspython, urllib3; print('ok')"
```

---

## Push to a Container Registry

Log in and push (Podman example):

```bash
podman login <REGISTRY>                 # e.g., quay.io or ghcr.io
podman tag custom-ee:latest <REGISTRY>/<NAMESPACE>/custom-ee:latest
podman push <REGISTRY>/<NAMESPACE>/custom-ee:latest
```

> For GHCR: `REGISTRY=ghcr.io` and `NAMESPACE=<your_github_username_or_org>`.

---

## Use in AWX / Automation Controller

1. Go to **Administration → Execution Environments**.
2. Click **Add**.
3. Set **Image** to the pushed URL, e.g.:  
   `quay.io/myco/custom-ee:latest` or `ghcr.io/myuser/custom-ee:latest`.
4. (Optional) Set **Pull** to “Always” during testing.
5. Save and run a quick job template to validate it.

---

## Security & Reproducibility

- **Pin versions** (collections and Python modules) to prevent surprise upgrades.
- Avoid committing secrets; prefer **private hubs/registries** and CI secrets.
- Consider **multi-stage** builds or private bases if you need internal CA certs or tools.
- Scan images (e.g., Trivy, Grype) and keep a changelog of base and dependency updates.

---

## Troubleshooting

- **SSL or Kerberos errors**: ensure `krb5-*` libs exist and `/etc/krb5.conf` is correct at runtime (mount if needed).
- **Missing modules**: rebuild after adding to `requirements.txt` or `requirements.yml`.
- **Large images**: remove unused collections; consolidate `yum install` lines; pin versions.
- **Private Hub auth**: configure `ansible-galaxy.yml` or use `ansible-navigator` config to point to your Automation Hub with credentials.

---

## Quick Commands (copy/paste)

```bash
# Build
ansible-builder build -f execution-environment.yml -t custom-ee:latest

# Test
podman run -it --rm custom-ee:latest bash

# Tag & Push
podman tag custom-ee:latest <REGISTRY>/<NAMESPACE>/custom-ee:latest
podman push <REGISTRY>/<NAMESPACE>/custom-ee:latest
```

---

## Suggested .gitignore

```gitignore
# ansible-builder build context
context/
# Python venvs
.venv/
venv/
# editor/OS files
.DS_Store
*.swp
```

---

### Credits

This documentation is tailored to the example configs you provided for:
- Kerberos/WinRM (pywinrm, pypsrp[kerberos], krb5 libs)
- VMware SDKs (PyVmomi / pyVim)
- AAP receptor binary inclusion

Tweak to fit your organization’s standards and security requirements.

