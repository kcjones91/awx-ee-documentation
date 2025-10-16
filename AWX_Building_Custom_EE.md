# TL;DR

Need to build a custom EE for AWX? I needed to do it for managing Windows hosts, but if you need any extra Python modules or Ansible collections, check out the other file snippets.

# Build Steps

## Environment Setup

### [Install Python 3](https://cloudbytes.dev/snippets/upgrade-python-to-latest-version-on-ubuntu-linux) (3.12 is latest as of this writing)

```bash
sudo apt update && sudo apt upgrade -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3
```

### Create a new Python virtual environment for running Ansible, with the following Python packages installed
1. Create `~/venv/ansible/requirements.txt`
(these Python requirements are for the venv only - they aren't to be installed on your custom EE unless you need them for some reason)
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

2. Create Python venv and install Ansible tools
```bash
python3 -m venv ~/venv/ansible
source ~/venv/ansible/bin/activate
python3 -m pip install -r ~/venv/ansible/requirements.txt
```

### Create a working directory for your custom EE

- If it's a Git repo, add the `context` folder to your `.gitignore`
- Add the `execution-environment.yml`, `requirements.txt`, and `requirements.yml` files, which are included in this Gist, below this README file.

- Run the build command and push the image to your favorite cloud-based or self-hosted container registry. That's it!

## Build and Push Image to Container Registry

```bash
ansible-builder build --tag=your.docker.registry.url/custom-ee:1.0.0 --container-runtime=docker --verbosity=3
```

```bash
# Add extra tags like 'latest', if you want
docker image ls
docker image IMAGEHASH your.docker.registry.url/custom-ee:latest

# Push image to registry
docker push your.docker.registry.url/custom-ee:1.0.0
```

# The Story

I spent hours Googling how to create a custom EE for AWX that would allow me to run community Ansible collections (even just `community.general`!).

The standard base image when using version 1 (which every blog post you find says to do), for some reason, doesn't have anything newer than `2.13` of `ansible-core`, and any docs from Red Hat reference a base image that you need to be a RH customer in order to use. And I couldn't get the builder to pull `ansible-core >= 2.15` without using version 3 - you can see why I started to pull my hair out.

It was a constant struggle to figure out solutions to the seemingly random Python build errors I was getting, and I ended up FINALLY piecing together a working config from various blog posts, Reddit threads, etc.

Many thanks to [u/thenumberfourtytwo](https://www.reddit.com/user/thenumberfourtytwo/) on Reddit for the [custom EE image](https://www.reddit.com/r/awx/comments/10rifoa/comment/j6w1zsw/) that he built, but I wanted to build my own that I could push to my own container registry. And also many thanks to [u/MallocArray](https://www.reddit.com/user/MallocArray/)'s [comment which gave me a usable base image!](https://www.reddit.com/r/awx/comments/16zkg7t/comment/k3fvh84/) The rest of the various links I used for reference are below.

Anyway, I wanted to put this together to help anyone that may stumble across this.

Enjoy!

# Other Useful Links

- Error "too many open files" running jobs in AWX on custom EE's
  - https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
  - https://github.com/ansible/awx/issues/14693
- How to get Kerberos auth working between AWX and Windows hosts
  - https://github.com/kurokobo/awx-on-k3s/blob/af38ca8b357eb7dba6e647a6facba39ff2b84f3d/tips/use-kerberos.md#setting-up-kubernetes

# Credits

- https://openthreat.ro/awx-building-custom-execution-environment/
- https://medium.com/@frederic.egmorte/awx-create-a-new-execution-environment-with-ansible-builder-aee127d5bbdd
- https://developers.redhat.com/articles/2023/05/08/how-create-execution-environments-using-ansible-builder
- https://www.reddit.com/r/awx/comments/16zkg7t/awx_ee_builder_docker_image_alternative_for/
- https://www.reddit.com/r/awx/comments/10rifoa/msg_winrm_or_requests_is_not_installed_no_module/
- https://www.reddit.com/r/awx/comments/zy24n2/how_do_you_make_community_modules_available/
- https://www.reddit.com/r/awx/comments/1089o3i/upgrade_ansible_version_in_awxoperator_in/
- https://weiyentan.github.io/2021/creating-execution-environments/
- https://github.com/ansible/ansible-builder/issues/437
- https://github.com/ansible/ansible-builder/issues/496
- https://github.com/aimcod/ansible-awx-ee
- https://github.com/aimcod/k8awx
- https://cloudbytes.dev/snippets/upgrade-python-to-latest-version-on-ubuntu-linux