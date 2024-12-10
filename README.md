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

## Step 1: Clone the Repository

Clone the GitHub Gist to your local system:

```bash
git clone https://gist.github.com/CaptainStealthy/6c54a5ed3ba66e9d7ee87481e4e178c2
cd 6c54a5ed3ba66e9d7ee87481e4e178c2
```

This repository contains all necessary configuration files.

---

## Step 2: Review Configuration Files

Examine the following files in the repository:

1. **`execution-environment.yml`**: Specifies the base image and required dependencies for the EE.
2. **`requirements.yml`**: Lists Ansible collections to be included.
3. **`bindep.txt`**: Defines system-level dependencies.
4. **`Dockerfile`** (optional): Provides advanced configurations for the image.

Modify these files as needed to suit your environment's requirements.

---

## Step 3: Build the Execution Environment

Use the `ansible-builder` tool to build the EE image:

```bash
ansible-builder build -f execution-environment.yml -t custom-ee:latest
```

**Arguments**:
- `-f`: Path to the `execution-environment.yml` file.
- `-t`: Tag for the resulting image.

Verify the build by listing container images:

```bash
podman images  # or docker images
```

---

## Step 4: Test the Execution Environment

Launch a container from the custom EE image to test its configuration:

```bash
podman run -it custom-ee:latest bash  # or docker run -it custom-ee:latest bash
```

Inside the container, confirm the presence of installed Ansible collections:

```bash
ansible-galaxy collection list
```

---

## Step 5: Use the Custom EE in AWX or Automation Controller

To make the custom EE accessible in AWX or Automation Controller, push it to your local environment:

### Log in to the Container Registry

Log in to your local container registry:

```bash
podman login <registry>
```

Enter your credentials when prompted.

### Tag and Push the Image

Tag the custom EE image with the local registry URL and push it:

```bash
podman tag custom-ee:<registry>/custom-ee:latest
podman push <registry>/custom-ee:latest
```

### Configure in AWX/Automation Controller

1. Navigate to the **Execution Environments** section.
2. Create a new EE and specify the image URL: `<registry>/custom-ee:latest`.
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
