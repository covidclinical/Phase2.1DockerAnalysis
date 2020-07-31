# 4CE Project

This docker is built to run a canned set of analyses for the 4CE Project.

# Prerequisites

In order to run this container you need to have Docker installed.

See - https://docs.docker.com/get-docker/

# IMPORTANT!

As is the spirit of Docker nothing will be saved on the container itself! If you need to save intermediary files you need to write them to the folder you mount to the container. The -v parameter used in the docker command will share a folder from your local environment to the running container. Anything in that folder will be preserved on subsequent runnings of the container.

# Starting Container

To run this docker container issue the following command in your terminal. /SOME_LOCAL_PATH should be replaced by the path you wish to save any R Scripts or generated data.

```bash
docker run --rm --name 4ce -v /SOME_LOCAL_PATH:/c19i2b2 \
                            -p 8787:8787 \
                            -p 2200:22 \
                            -e CONTAINER_USER_USERNAME=REPLACE_ME_USERNAME \
                            -e CONTAINER_USER_PASSWORD=REPLACE_ME_PASSWORD \
                            dbmi/4ce-analysis:development
```

This will run the container in the background. If you need to stop the container you can issue the following docker command.

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

If you are running this on your own machine you can use http://localhost:8787 to access R Studio Server. The default username and password you can use is dockeruser/dockerpassword. 

## Connecting to RStudio Server via IP Address of container

IMPORTANT! Additional security measures need to be in place if you are deploying this to a widely accessible server.

https://docs.rstudio.com/ide/server-pro/access-and-security.html

If you have deployed this container to another server then you'll use the IP address of that server. This requires that the ports to the remote server are open and that the running container can receive traffic on those ports.

## Connecting to the container via SSH (localhost)

To connect to server via ssh you'll use the follow command which assumes the default user/password.

```bash
ssh dockeruser@localhost -p 2200 
```

From here you can run an R command line session.

## Running container as an interactive R session

One final option for the container is if you want to simply run it like an interactive R session. The container will exit after you close your R session. Note, this command starts the container so you can't already have one running when issuing it. The --rm flag will ensure that when this container exits the container is stopped and cleaned up.

```bash
docker run --name 4ce -v /SOME_LOCAL_PATH:/c19i2b2 --rm -it dbmi/4ce-analysis:latest R
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
docker build --tag dbmi/4ce-analysis:release-0.2 .
```