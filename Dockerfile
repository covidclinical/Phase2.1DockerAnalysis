FROM dbmi/hds-analysis-docker:version-1.0.2

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
RUN R -e "install.packages('tidyr')"
RUN R -e "install.packages('stringr')"
RUN R -e "install.packages('survival')"

## install RStudio Server / notebooks
RUN mkdir /opt/rstudioserver
WORKDIR /opt/rstudioserver

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb
RUN dpkg -i ./libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb

RUN apt-get update && apt-get install -y gdebi-core
RUN wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5042-amd64.deb
RUN gdebi -n rstudio-server-1.2.5042-amd64.deb

## Copy startup script.
RUN mkdir /startup
COPY startup.sh /startup/startup.sh
RUN chmod 700 /startup/startup.sh

RUN mkdir /4ceData
WORKDIR /4ceData

## Lock the default user from analysis docker
RUN usermod -L dockeruser
RUN chage -E0 dockeruser
RUN usermod -s /sbin/nologin dockeruser

# Copy RStudio Config
COPY rserver.conf /etc/rstudio/rserver.conf

## install R package with utility functions for Phase 2 projects
RUN R -e "devtools::install_github('https://github.com/covidclinical/Phase2UtilitiesRPackage', subdir='FourCePhase2Utilities', upgrade=FALSE)"

## allow anyone to write system R libraries
RUN chmod -R 777 /opt/microsoft/ropen/3.5.3/lib64/R/library

CMD ["/startup/startup.sh"]
