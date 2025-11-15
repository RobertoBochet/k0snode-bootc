# k0s bootc

This repo contains the recipes to build a **bootable container image** based on **bootc** for **k0s**.

## What is...

### ...k0s?

> k0s is an open source, all-inclusive Kubernetes distribution, which is configured with all of the features needed to build a Kubernetes cluster and packaged as a single binary for ease of use.

You can find more information about k0s [here](https://docs.k0sproject.io/).

### ...bootc?

Do you know what a container is? Well, a container image doesn't contain a kernel; so `container image` + `kernel` = `bootable container image`.
The obtained bootable container image can be run on a VM or a bare-metal machine, with the advantage of a highly customizable immutable OS built exploiting traditional OCI tools(e.g. podman) and skills.

To make this magic happen, we use [bootc](https://github.com/containers/bootc).

> Transactional, in-place operating system updates using OCI/Docker container images. bootc is the key component in a broader mission of bootable containers.

## Image tags semantics

In the registry, different tags for each image are available.

- `latest` is the latest compiled version of the image (it may not be a good idea to use it in production).
- `dev` is the latest compiled development version of the image. It would be unstable.
- `X.Y.Z-k0s.N-SHORT_SHA` is the image compiled from the git commit corresponding to the `SHORT_SHA` (e.g `1.32.1-k0s.0-7b3b3d1`). It may be associated with a development commit.
- `X.Y.Z-k0s.N` is the latest compiled image with the specified k0s version (e.g `1.32.1-k0s.0`).
- `X.Y.Z` is the latest compiled image with the specified k8s compatible version of k0s (e.g `1.32.1`).
- `X.Y` is the latest compiled image with the equivalent major and minor k8s compatible version of k0s (e.g `1.32`).

If you want to understand better the k0s versioning, you can find more information [here](https://docs.k0sproject.io/stable/releases/).

## Build

To build a bootable container image no special requirements are needed, just build it as an ordinary container image with `podman` or `buildah`.

```bash
podman build -t k0s-bootc:${IMAGE_TAG} .
```

For the use in production, you should use the image built by the CI/CD pipeline.
It will publish the image to the [github registry](https://github.com/RobertoBochet/k0snode-bootc/pkgs/container/k0snode-bootc).

## Installation

There are several ways to deploy a new instance of this machine. You can refer to the [fedora bootc docs](https://docs.fedoraproject.org/en-US/bootc/bare-metal/) to find the most suitable way to deploy your machine.
