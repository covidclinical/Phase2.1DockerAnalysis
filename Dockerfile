## based on Ubuntu LTS
FROM ubuntu:20.04

## make a more comfortable user environment
RUN yes | unminimize

## we're going to create a non-root user and give the user sudo
RUN apt-get update && \
	apt-get -y install sudo \
	&& echo "Set disable_coredump false" >> /etc/sudo.conf
	
## set locale info
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& apt-get update && apt-get install -y locales \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ=America/New_York

## MRO dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		less \
		libgomp1 \
		libpango-1.0-0 \
		libxt6 \
		libsm6 \
		make \
		texinfo \
		libtiff-dev \
		libpng-dev \
        libicu-dev \
        libpcre3 \
        libpcre3-dev \
        libbz2-dev \
        liblzma-dev \
		gcc \
		g++ \
		openjdk-8-jre \
		openjdk-8-jdk \
		gfortran \
		libreadline-dev \
		libx11-dev \
		libcurl4-openssl-dev \ 
		libssl-dev \
		libxml2-dev \
        wget \
        libtinfo5 \
	&& rm -rf /var/lib/apt/lists/*

## R version
ENV MRO_VERSION_MAJOR 4
ENV MRO_VERSION_MINOR 0
ENV MRO_VERSION_BUGFIX 2
ENV MRO_VERSION $MRO_VERSION_MAJOR.$MRO_VERSION_MINOR.$MRO_VERSION_BUGFIX
ENV R_HOME=/opt/microsoft/ropen/$MRO_VERSION/lib64/R

WORKDIR /tmp

## Donwload and install MRO & MKL
RUN curl -LO -# https://mran.blob.core.windows.net/install/mro/$MRO_VERSION/Ubuntu/microsoft-r-open-$MRO_VERSION.tar.gz \
	&& tar -xzf microsoft-r-open-$MRO_VERSION.tar.gz
RUN tar -xzf microsoft-r-open-$MRO_VERSION.tar.gz
WORKDIR /tmp/microsoft-r-open
RUN  ./install.sh -a -u

# Clean up downloaded files
WORKDIR /tmp
RUN rm microsoft-r-open-*.tar.gz \
	&& rm -r microsoft-r-open

# Use libcurl for download, otherwise problems with tar files
RUN echo 'options("download.file.method" = "libcurl")' >> /opt/microsoft/ropen/$MRO_VERSION/lib64/R/etc/Rprofile.site

RUN chmod 777 /tmp

# ## install unixodbc
RUN apt-get update && apt-get install -y \
	unixodbc \
	unixodbc-dev

## install MS SQL Server ODBC driver
RUN apt-get update \
	&& apt-get install -y gnupg

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
	&& echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod bionic main" | tee /etc/apt/sources.list.d/mssql-release.list \
	&& apt-get update \
	&& ACCEPT_EULA=Y apt-get install msodbcsql17
	
## install kerberos client tools for Windows authentication to SQL
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y krb5-user

## install FreeTDS driver, since there is some legacy Python code around that needs it
RUN wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.1.40.tar.gz
RUN tar zxvf freetds-1.1.40.tar.gz
RUN cd freetds-1.1.40 && ./configure && make && make install

## tell unixodbc where to find the FreeTDS driver shared object
RUN echo '\n\
[FreeTDS]\n\
Driver = /usr/local/lib/libtdsodbc.so \n\
' >> /etc/odbcinst.ini

# install Oracle Instant Client dependencies
RUN apt-get update \
	&& apt-get install -y alien \
	&& apt-get install -y libaio1

## install Oracle Instant Client and Oracle ODBC driver 
ARG release=18
ARG update=5
ARG reserved=3

# wget https://download.oracle.com/otn_software/linux/instantclient/185000/oracle-instantclient18.5-basic-18.5.0.0.0-3.x86_64.rpm
RUN wget https://download.oracle.com/otn_software/linux/instantclient/${release}${update}000/oracle-instantclient${release}.${update}-basic-${release}.${update}.0.0.0-${reserved}.x86_64.rpm \
    && wget https://download.oracle.com/otn_software/linux/instantclient/${release}${update}000/oracle-instantclient${release}.${update}-devel-${release}.${update}.0.0.0-${reserved}.x86_64.rpm \
    && wget https://download.oracle.com/otn_software/linux/instantclient/${release}${update}000/oracle-instantclient${release}.${update}-sqlplus-${release}.${update}.0.0.0-${reserved}.x86_64.rpm \
    && wget https://download.oracle.com/otn_software/linux/instantclient/${release}${update}000/oracle-instantclient${release}.${update}-odbc-${release}.${update}.0.0.0-${reserved}.x86_64.rpm

RUN alien -i oracle-instantclient${release}.${update}-basic-${release}.${update}.0.0.0-${reserved}.x86_64.rpm \
   && alien -i oracle-instantclient${release}.${update}-devel-${release}.${update}.0.0.0-${reserved}.x86_64.rpm \
   && alien -i oracle-instantclient${release}.${update}-sqlplus-${release}.${update}.0.0.0-${reserved}.x86_64.rpm \
   && alien -i oracle-instantclient${release}.${update}-odbc-${release}.${update}.0.0.0-${reserved}.x86_64.rpm

RUN rm oracle-instantclient*.rpm 

# define the environment variables
ENV LD_LIBRARY_PATH=/usr/lib/oracle/${release}.${update}/client64/lib/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} \
    ORACLE_HOME=/usr/lib/oracle/${release}.${update}/client64 \
    PATH=$PATH:$ORACLE_HOME/bin

RUN echo "/usr/lib/oracle/${release}.${update}/client64/lib" | sudo tee /etc/ld.so.conf.d/oracle.conf

## tell unixodbc where to find the Oracle driver shared object
RUN echo '\n\
[Oracle]\n\
Driver = /usr/lib/oracle/18.5/client64/lib/libsqora.so.18.1 \n\
' >> /etc/odbcinst.ini

# the following steps are needed for Roracle package
RUN mkdir $ORACLE_HOME/rdbms \
    && mkdir $ORACLE_HOME/rdbms/public 

RUN cp /usr/include/oracle/${release}.${update}/client64/* $ORACLE_HOME/rdbms/public \
    && chmod -R 777  $ORACLE_HOME/rdbms/public

# install ROracle
 RUN R -e "install.packages('ROracle')"

## configure and install rJava
RUN R CMD javareconf
RUN R -e "install.packages('rJava', type='source')"

# ## install devtools
RUN R -e "install.packages('devtools')"

# install additional R packages
RUN Rscript -e 'install.packages("Rcpp")'
RUN Rscript -e 'install.packages("roxygen2")'
RUN Rscript -e 'install.packages("tidyverse")'
RUN Rscript -e 'if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")'
RUN Rscript -e 'BiocManager::install(version = "3.12", update=FALSE, ask=FALSE)'
RUN R -e "install.packages('getPass')"
RUN R -e "install.packages('xlsx')"

## install python and pip
RUN apt-get update && apt-get -y install \
    python3-pip

## install odbc connector for R
## these versions aren't currently available in the MS repo, but required for "immediate" code execution 
## instead of prepared statement execution
RUN Rscript -e 'devtools::install_version("DBI", version = "1.1.0", repos = "http://cran.us.r-project.org")'
RUN Rscript -e 'devtools::install_version("odbc", version = "1.2.3", repos = "http://cran.us.r-project.org")'

## install pyodbc
RUN pip3 install pyodbc

## install and configure ssh and sshd
RUN apt-get update && apt-get install -y \
	openssh-server \
	ssh
RUN mkdir /var/run/sshd

## install X11 tools
RUN apt-get update && apt-get install -y \
	xterm \
	xauth

## install terminal multiplexers
RUN apt-get update && apt-get install -y \
	screen \
	tmux

## install git
RUN apt-get update && apt-get install -y \
	git

## install editors
RUN apt-get update && apt-get install -y \
	nano \
	vim

## configure X11 so we can e.g. create plots in R over SSH
RUN sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config \
    && sed -i "s/^.*X11UseLocalhost.*$/X11UseLocalhost no/" /etc/ssh/sshd_config \
    && grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config

RUN apt-get update && apt-get install -y \
	man-db 

RUN apt-get update && apt-get install -y \
	zsh

## there is an issue where the R package thinks that the certificate is in the .../ropen/4.0.0/... directory
ENV CURL_CA_BUNDLE=/opt/microsoft/ropen/4.0.2/lib64/R/lib/microsoft-r-cacert.pem
RUN Rscript -e "remove.packages(c('curl','httr'))"
RUN Rscript -e "install.packages(c('curl', 'httr'))"

# ## clone our git repo that has the SQL Server connection helper code for R and install the package
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/FactToCube.git')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/MsSqlTools.git')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/SqlTools.git')"

RUN chmod 777 /opt/microsoft/ropen/$MRO_VERSION/lib64/R/library

## change these to suit 
ARG user_name=dockeruser
ARG user_password=dockerpassword

## create the new user, set zsh as their shell, and install zsh configuration
RUN useradd $user_name \
	&& mkdir /home/${user_name} \
	&& chown ${user_name}:${user_name} /home/${user_name} \
	&& addgroup ${user_name} staff \
	&& echo "$user_name:$user_password" | chpasswd \
	&& adduser ${user_name} sudo \
	&& chsh -s /bin/zsh ${user_name} \
	&& sudo -u ${user_name} sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" \
	&& sed -i 's/robbyrussell/bureau/' /home/${user_name}/.zshrc

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

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.5_amd64.deb
RUN dpkg -i ./libssl1.0.0_1.0.2n-1ubuntu5.5_amd64.deb

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
RUN R -e "devtools::install_github('https://github.com/covidclinical/Phase2.1UtilitiesRPackage', subdir='FourCePhase2.1Utilities', upgrade=FALSE)"
RUN R -e "devtools::install_github('https://github.com/covidclinical/Phase2.1DataRPackage', subdir='FourCePhase2.1Data', upgrade=FALSE)"

## tell git to use the cache credential helper and set a 1 day-expiration
RUN git config --system credential.helper 'cache --timeout 86400'

## need newer version of dplyr
RUN R -e "options(repos = c(CRAN = 'https://cran.microsoft.com/snapshot/2021-01-29')); install.packages('dplyr')"

## additional dependencies 2021-02-01
RUN R -e "install.packages('np')"
RUN R -e "install.packages('codetools')"
RUN R -e "install.packages('glmnet')"
RUN R -e "install.packages('glmpath')"
RUN R -e "install.packages('lars')"
RUN R -e "install.packages('zoo')"
RUN R --vanilla -e "options(repos = c(CRAN = 'https://cran.microsoft.com/snapshot/2021-01-29')); install.packages('lme4')"
RUN R -e "install.packages('icd')"

## allow anyone to write system R libraries
RUN chmod -R 777 /opt/microsoft/ropen/$MRO_VERSION/lib64/R/library
RUN chmod -R 777 /opt/microsoft/ropen/$MRO_VERSION/lib64/R/doc/html/packages.html

CMD ["/startup/startup.sh"]
