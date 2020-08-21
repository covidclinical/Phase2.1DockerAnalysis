# 4CE Project

This docker is built to run a canned set of analyses for the 4CE Project.

# Prerequisites

## Docker

In order to run this container you need to have Docker installed.

See - https://docs.docker.com/get-docker/

## SSH Client

If you are using SSH to connect to a Docker or to enable port forwarding you'll need an SSH client. 

For MacOS and Linux you can use the SSH client already installed.

For Windows systems you will need to download an SSH client likey PuTTY (https://www.putty.org/).

# IMPORTANT!

As is the spirit of Docker nothing will be saved on the container itself! If you need to save intermediary files you need to write them to the folder you mount to the container. The -v parameter used in the docker command will share a folder from your local environment to the running container. Anything in that folder will be preserved on subsequent runnings of the container.

# Starting Container

To run this docker container issue the following command in your terminal. 

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

/SOME_LOCAL_PATH should be replaced by the local path you wish to save any R Scripts or generated data. When on the running container this folder will be located at /4ceData.

### CONTAINER_USER_USERNAME and CONTAINER_USER_PASSWORD

This is a username and password combo that will get created on the machine and can be used to log into the R Studio Server Web UI.

## Stopping and checking container status

If you need to stop the container you can issue the following docker command.

```bash
docker kill 4ce
```

If you want to check the status of the container use the following command.

```bash
docker ps
```

# Connecting

Running this container with the default command starts an SSH Server as well as an R Studio Server instance.

## Connecting to RStudio Server via localhost

If you are running this on your own machine you can use http://localhost:8787 to access R Studio Server. You will use the username and password you used in the above 'docker run' command.

## Connecting to RStudio Server hosted on a remote server

IMPORTANT! Additional security measures need to be in place if you are deploying this to a widely accessible server. See the R Studio Server pages for ideas on increasing security. Do not run this container somewhere that is accesible from the outside world without first locking down access. You may want to consider

* Restricting which users can SSH via Ubuntu
* Restricting network access
* Ensuring encrypted R Studio Server traffic

https://docs.rstudio.com/ide/server-pro/access-and-security.html

The Docker host’s firewall, and any relevant network firewalls, need to be configured to allow inbound TCP access to port 22 and 8787 on the Docker host. Access can be limited to only TCP port 22 if ssh port mapping is used on the client side (see documentation on DockerHub).

### Remote server with only port 22 access

Access to the remote server from clients may also be restricted to port 22 only. The client will need to forward a local port to port 8787 on the remote in order to connect to the RStudio Server. An example using the native MacOS SSH client

```bash
ssh -L 8787:SOME.REMOTE.HOST:8787 USERNAME@SOME.REMOTE.HOST
```

If succesful, the client should be able to visit http://localhost:8787 to see RStudio Server.


## Connecting to the container via SSH (localhost)

To connect to server via ssh you'll use the follow command which assumes the default user/password.

```bash
ssh dockeruser@localhost -p 2200 
```

From here you can run an R command line session.

## Running container as an interactive R session

One final option for the container is if you want to simply run it like an interactive R session. The container will exit after you close your R session. Note, this command starts the container so you can't already have one running when issuing it. The --rm flag will ensure that when this container exits the container is stopped and cleaned up.

```bash
docker run --name 4ce -v /SOME_LOCAL_PATH:/4ceData --rm -it dbmi/4ce-analysis:latest R
```

# Other Information

R Studio Utility is installed in - /usr/sbin

If you ever need to restart rstudio server inside the container

```bash
/usr/sbin/rstudio-server restart
```

# Developer Information

If you want to build your own copy of this container you can use

```bash
docker build .
```

You can optionally specify a tag when building to reference later.

```bash
docker build --tag dbmi/4ce-analysis:development .
```
