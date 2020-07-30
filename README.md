# 4CE Project

This docker is built to run a canned set of analyses for the 4CE Project.

# Prerequisites

# IMPORTANT!

As is the spirit of Docker nothing will be saved on the container itself! If you need to save intermediary files you need to write them to the folder you mount to the container. The -v parameter used in the docker command will share a folder from your local environment to the running container. Anything in that folder will be preserved on subsequent runnings of the container.

# Connecting and Running
## Connecting via R Studio

## Connecting via R Command Line

```bash
docker run --name 4ce -v /SOME_LOCAL_PATH:/c19i2b2 -it dbmi/4ce-analysis:0.1 R
```