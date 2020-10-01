

# 4CE Project

Use this container to run Phase 2 analyses for the 4CE Project.

# Table of Contents

1. [Prerequisites](#Prerequisites)
2. [Preserving State!](#Preserving-State)
3. [Starting Container](#Starting-Container)
4. [Connecting](#Connecting)
5. [Other Information](#Other-Information)
6. [Developer Information](#Developer-Information)
7. [Offline Usage](#Offline-Usage)

# Prerequisites

## Docker

In order to run this container you need to have the Docker runtime installed.

See - https://docs.docker.com/get-docker/

## SSH Client

If you are connecting to the container via ssh, or to enable port forwarding, you'll need an SSH client. 

macOS and Linux typically have a command line ssh client installed out of the box.

For Windows systems you will need to download an SSH client such as PuTTY (https://www.putty.org/).

# Preserving State

In general, no state (file system, running processes, etc.) will be preserved when the Docker container is terminated and re-run. If you need to persist files, you should write them to the directory mounted to the container using the `-v` argument in the `docker` invocation. This option will share a directory from the host environment, making it available in the running container. Anything in that directory will therefore be preserved when the container is stopped.  For sites that need to run the container on a host that is isolated from the internet, there may be a need to persist the intermediate analysis results while the container is moved to a network location where it can push the files to GitHub. See [Offline Usage](#Offline-Usage) below for details.  Documentation in the [Phase2.1UtilitiesRPackage](https://github.com/covidclinical/Phase2.1UtilitiesRPackage) contains information on default container-local file system locations that are recommended for use as intermediate scratch space for use by analytic packages.

# Starting Container

To remove old versions of the container image, and ensure you are running the latest image that we have built and pushed to Docker Hub, issue this before running the container:

```bash
docker image rm dbmi/4ce-analysis:latest
```

Then to run the container:

```bash
docker run --rm --name 4ce -d -v /SOME_LOCAL_PATH:/4ceData \
                            -p 8787:8787 \
                            -p 2200:22 \
                            -e CONTAINER_USER_USERNAME=REPLACE_ME_USERNAME \
                            -e CONTAINER_USER_PASSWORD=REPLACE_ME_PASSWORD \
                            dbmi/4ce-analysis:latest
```

## Parameters

### /SOME_LOCAL_PATH

/SOME_LOCAL_PATH should be replaced by the path on the host to the directory to which you wish to save any R Scripts or generated data. On the running container, this directory will be located at /4ceData. The permissions on the host data directory pointed to by /SOME_LOCAL_PATH needs to be effective read + write + execute for the user who is running the container from the command line.

### CONTAINER_USER_USERNAME and CONTAINER_USER_PASSWORD

This is the username and password that will get created on the container, and can be used to connect to it via ssh, or to log into the R Studio Server Web UI.

## Stopping and checking container status

If you need to stop the container you can issue the following docker command:

```bash
docker kill 4ce
```

If you want to check the status of the container use the following command:

```bash
docker ps
```

# Connecting

Running this container with the default command starts an SSH Server as well as an R Studio Server instance.

## Connecting to RStudio Server via localhost

If you are running this on your own machine you can use http://localhost:8787 to access R Studio Server. You will use the username and password you used in the above 'docker run' command.

## Connecting to RStudio Server hosted on a remote server

IMPORTANT! Additional security measures need to be in place if you are deploying this to a widely accessible server. See the R Studio Server pages for ideas on increasing security. Do not run this container somewhere that is accesible from the outside world without first locking down access. You may want to consider:

* Restricting which users can SSH via Ubuntu
* Restricting network access
* Ensuring encrypted R Studio Server traffic

https://docs.rstudio.com/ide/server-pro/access-and-security.html

The Docker host’s firewall, as well as any relevant network firewalls, need to be configured to allow inbound TCP access to port 22 and 8787 on the Docker host. Access can be limited to only TCP port 22 if ssh port mapping is used on the client side (see documentation on DockerHub).

### Remote server with only port 22 access

Access to the remote server from clients may also be restricted to port 22 only. The client will need to forward a local port to port 8787 on the remote in order to connect to the RStudio Server. An example using the native macOS SSH client:

```bash
ssh -L 8787:SOME.REMOTE.HOST:8787 USERNAME@SOME.REMOTE.HOST
```

If succesful, the client should be able to visit http://localhost:8787 to see RStudio Server.


## Connecting to the container via SSH (localhost)

To connect via ssh you'll use the follow command, which assumes the default user/password.

```bash
ssh dockeruser@localhost -p 2200 
```

From here you can run an R command-line session.

## Running the container as an interactive R session

One final option is to run the container in a way that directly presents the user with an interactive R session. The container will stop after you quit this R session. Note, this command runs the container so you can't already have one running when issuing it. The --rm flag will ensure that when the R session is quit, the container is stopped and cleaned up.

```bash
docker run --name 4ce -v /SOME_LOCAL_PATH:/4ceData --rm -it dbmi/4ce-analysis:latest R
```

# Other Information

R Studio Utility is installed in - /usr/sbin

If you need to restart rstudio server inside the container

```bash
/usr/sbin/rstudio-server restart
```

# Developer Information

If you want to build your own copy of this container you can clone this repository and run this in the directory containing the Dockerfile:

```bash
docker build .
```

You can optionally specify a tag when building, to help keep track of your experimental builds:

```bash
docker build --tag dbmi/4ce-analysis:development .
```


# Offline Usage

Many sites will have security controls in place that prevent a host that has access to the patient-level data required to run the analyses from connecting to external networks.  In these circumstances, you will need to employ a second "bastion" host that will serve as the transfer mechanism to move the container image onto the isolated host, and then to transfer the summary result files generated by the analyses to the respective GitHub repositories.

Under this arrangement, the container image will be pulled from the Docker Hub registry onto the bastion host (which itself needs to have the Docker runtime installed).  The container can then be run on the bastion host if any additional configuration requires internet access (e.g., installation of additional packages), and saved as a new Docker image.  The image (whether the original one from the registry or an updated one) will then be saved to a `.tar` file, which can be transferred (e.g. via scp) to the isolated host.  The image is then run on the isolated host as usual, with access to the required input data. The analysis packages are designed by default to save their results to a scratch file system location that is local to the contianer. Thus, the analyses can be run on the isolated host, the modified container (including the result files) can be saved as a new image, the image transferred back to the bastion host, and the result files uploaded.  

In more detail, the steps are are follows:

## 1. *On the bastion host:* Pull the container image from the registry

## 2. *On the bastion host:* Optionally run the container, perform any desired customization, and save to a new image

## 3. *On the bastion host:* Transfer the image to the isolated host as a `.tar` file

## 4. *On the isolated host:* Load the `.tar` file as an image in Docker

## 5. *On the isolated host:* Run the container

## 6. *On the isolated host:* Execute the desired analyses, saving results to the container's local file system

## 7. *On the isolated host:* Save the running container (with result files) as a new image

## 8. *On the isolated host:* Transfer that new image as a `.tar` file back to the bastion host

## 9. *On the bastion host:* Load the `.tar` file as an image in Docker

## 10. *On the bastion host:* Run the container

## 11. *On the bastion host:* Upload the result files to GitHub
