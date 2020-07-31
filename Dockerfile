FROM dbmi/hds-analysis-docker:0.2

## customization for 4CE Phase 2.0
RUN R -e "install.packages('data.table')"
RUN R -e "install.packages('dplyr')"
RUN R -e "install.packages('exactmeta')"
RUN R -e "install.packages('fmsb')"
RUN R -e "install.packages('forestplot')"
RUN R -e "install.packages('httr')"
RUN R -e "install.packages('lme4')"
RUN R -e "install.packages('metafor')"
RUN R -e "install.packages('rtf')"
RUN R -e "install.packages('splines')"

## install RStudio Server / notebooks
RUN mkdir /opt/rstudioserver
WORKDIR /opt/rstudioserver

RUN apt-get update && apt-get install -y gdebi-core
RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.3.1056-amd64.deb
RUN gdebi -n rstudio-server-1.3.1056-amd64.deb

## Copy startup script.
RUN mkdir /startup
COPY startup.sh /startup/startup.sh
RUN chmod 700 /startup/startup.sh

RUN mkdir /c19i2b2
WORKDIR /c19i2b2

## Lock the default user from analysis docker
RUN usermod -L dockeruser
RUN chage -E0 dockeruser
RUN usermod -s /sbin/nologin dockeruser

CMD ["/startup/startup.sh"]