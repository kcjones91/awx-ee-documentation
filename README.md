# Process Documentation for Creating a Custom Execution Environment (EE)

## Overview

This document provides a comprehensive guide for creating a custom Execution Environment (EE) using `ansible-builder`. Follow these steps to streamline your workflow and ensure a successful build.

---

## Prerequisites

- **System Requirements**:
  - Python installed.
  - `ansible-builder` installed.
  - A container runtime such as Docker or Podman.
- **Resources**:
  - Access to YAML files from the Gist repository.

Ensure all dependencies are installed and configured prior to proceeding.

---

## Step 1: Install Python 3 (May not be needed)

```bash
sudo dnf update -y
sudo dnf install python3
```

---

## Step 2: Create a Python Virtual Environment

Set up a Python virtual environment for running Ansible:

### Create `requirements.txt`

Create `~/venv/ansible/requirements.txt` with the following content:

```
autopep8
ansible-core
ansible-builder
ansible-lint
ansible-navigator
flake8
yamllint
pytest
pytest-xdist
```

### Create and Activate the Virtual Environment

Run the following commands:

```bash
python3 -m venv ~/venv/ansible
source ~/venv/ansible/bin/activate
python3 -m pip install -r ~/venv/ansible/requirements.txt
```

---

## Step 3: Clone the Repository

Clone the GitHub Gist to your local system:

```bash
git clone https://gist.github.com/CaptainStealthy/6c54a5ed3ba66e9d7ee87481e4e178c2
cd 6c54a5ed3ba66e9d7ee87481e4e178c2
```

This repository contains all necessary configuration files.

---

## Step 4: Create a Working Directory

Create a working directory for your custom EE. If using a Git repository, add the `context` folder to your `.gitignore` file.

Add the following files, included in the Gist, to the working directory:

- `execution-environment.yml`
- `requirements.txt`
- `requirements.yml`

---

## Step 5: Build the Execution Environment

Use the `ansible-builder` tool to build the EE image:

### With Podman

```bash
ansible-builder build -f execution-environment.yml -t custom-ee:latest
podman images
```

---

## Step 6: Test the Execution Environment

Launch a container from the custom EE image to test its configuration:

```bash
podman run -it custom-ee:latest bash
```

Inside the container, confirm the presence of installed Ansible collections:

```bash
ansible-galaxy collection list
```

---

## Step 7: Push the Image to a Container Registry

### Log in to the Container Registry

Log in to your container registry:

```bash
podman login https://<container registry>/  # For Podman
```

### Push the Image

#### With Podman

```bash
podman tag custom-ee:latest <container registry>/custom-ee:latest
podman push <container registry>/custom-ee:latest
```

---

## Step 8: Configure in AWX or Automation Controller

1. Navigate to the **Execution Environments** section.
2. Create a new EE and specify the image URL: `<container registry>/custom-ee:latest` (or your Docker registry URL).
3. Test the EE by running a job template.

---

## Cleanup

Remove the local image to free up space:

```bash
podman rmi custom-ee:latest  # or docker rmi custom-ee:latest
```

Delete any temporary build artifacts:

```bash
rm -rf context/  # or specific build directories
```

---

## Final Notes

This documentation ensures a smooth process for creating, testing, and deploying a custom Execution Environment. Tailor the steps and files to meet your specific needs and environment.
