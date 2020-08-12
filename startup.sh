#!/bin/bash

if [[ -z $CONTAINER_USER_USERNAME ]] || [[ -z $CONTAINER_USER_PASSWORD ]];
then
      exit 1
else
    groupadd rstudio-users

    useradd $CONTAINER_USER_USERNAME \
	&& mkdir /home/${CONTAINER_USER_USERNAME} \
	&& chown ${CONTAINER_USER_USERNAME}:${CONTAINER_USER_USERNAME} /home/${CONTAINER_USER_USERNAME} \
	&& chown ${CONTAINER_USER_USERNAME}:${CONTAINER_USER_USERNAME} /4ceData \
	&& addgroup ${CONTAINER_USER_USERNAME} staff \
	&& echo "$CONTAINER_USER_USERNAME:$CONTAINER_USER_PASSWORD" | chpasswd \
	&& adduser ${CONTAINER_USER_USERNAME} sudo \
	&& chsh -s /bin/zsh ${CONTAINER_USER_USERNAME} \
	&& sudo -u ${CONTAINER_USER_USERNAME} sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" \
	&& sed -i 's/robbyrussell/bureau/' /home/${CONTAINER_USER_USERNAME}/.zshrc

    usermod -a -G rstudio-users $CONTAINER_USER_USERNAME
fi

/usr/sbin/rstudio-server restart
/usr/sbin/sshd -D