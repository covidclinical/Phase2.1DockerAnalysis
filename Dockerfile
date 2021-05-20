#
# 4CE Distributed Computing Container
#

FROM ubuntu:20.04

#------------------------------------------------------------------------------
# Basic initial system configuration
#------------------------------------------------------------------------------

# install standard Ubuntu Server packages
RUN yes | unminimize

# we're going to create a non-root user at runtime and give the user sudo
RUN apt-get update && \
	apt-get -y install sudo \
	&& echo "Set disable_coredump false" >> /etc/sudo.conf
	
# set locale info
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& apt-get update && apt-get install -y locales \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ=America/New_York

WORKDIR /tmp

#------------------------------------------------------------------------------
# Install system tools and libraries via apt
#------------------------------------------------------------------------------

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install \
		-y \
		#--no-install-recommends \
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
		openssh-server \
		ssh \
		xterm \
		xauth \
		screen \
		tmux \
		git \
		libgit2-dev \
		nano \
		emacs \
		vim \
		man-db \
		zsh \
		unixodbc \
		unixodbc-dev \
		gnupg \
		krb5-user \
		python3-dev \
		python3 \ 
		python3-pip \
		alien \
		libaio1 \
		libgmp-dev \
		libmpfr-dev \
	&& rm -rf /var/lib/apt/lists/*


#------------------------------------------------------------------------------
# Configure system tools
#------------------------------------------------------------------------------

# required for ssh and sshd	
RUN mkdir /var/run/sshd	

# configure X11
RUN sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config \
    && sed -i "s/^.*X11UseLocalhost.*$/X11UseLocalhost no/" /etc/ssh/sshd_config \
    && grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config	

# tell git to use the cache credential helper and set a 1 day-expiration
RUN git config --system credential.helper 'cache --timeout 86400'


#------------------------------------------------------------------------------
# Install and configure database connectivity components
#------------------------------------------------------------------------------

# install MS SQL Server ODBC driver
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
	&& echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod bionic main" | tee /etc/apt/sources.list.d/mssql-release.list \
	&& apt-get update \
	&& ACCEPT_EULA=Y apt-get install msodbcsql17

# install FreeTDS driver
WORKDIR /tmp
RUN wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.1.40.tar.gz
RUN tar zxvf freetds-1.1.40.tar.gz
RUN cd freetds-1.1.40 && ./configure && make && make install
RUN rm -r /tmp/freetds*

# tell unixodbc where to find the FreeTDS driver shared object
RUN echo '\n\
[FreeTDS]\n\
Driver = /usr/local/lib/libtdsodbc.so \n\
' >> /etc/odbcinst.ini

# install Oracle Instant Client and Oracle ODBC driver 
ARG ORACLE_RELEASE=18
ARG ORACLE_UPDATE=5
ARG ORACLE_RESERVED=3

RUN wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-basic-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
    && wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-devel-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
    && wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-sqlplus-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
    && wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-odbc-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm

RUN alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-basic-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
   && alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-devel-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
   && alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-sqlplus-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
   && alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-odbc-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm

RUN rm oracle-instantclient*.rpm 

# define the environment variables for oracle
ENV LD_LIBRARY_PATH=/usr/lib/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64/lib/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} \
    ORACLE_HOME=/usr/lib/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64 \
    PATH=$PATH:$ORACLE_HOME/bin

RUN echo "/usr/lib/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64/lib" | sudo tee /etc/ld.so.conf.d/oracle.conf

# tell unixodbc where to find the Oracle driver shared object
RUN echo '\n\
[Oracle]\n\
Driver = /usr/lib/oracle/'${ORACLE_RELEASE}'.'${ORACLE_UPDATE}'/client64/lib/libsqora.so.18.1 \n\
' >> /etc/odbcinst.ini

# install pyodbc
RUN pip3 install pyodbc


#------------------------------------------------------------------------------
# Install and configure R
#------------------------------------------------------------------------------

# declare R version to be installed, make it available at build and run time
ENV MRO_VERSION_MAJOR 4
ENV MRO_VERSION_MINOR 0
ENV MRO_VERSION_BUGFIX 2
ENV MRO_VERSION $MRO_VERSION_MAJOR.$MRO_VERSION_MINOR.$MRO_VERSION_BUGFIX
ENV R_HOME=/opt/microsoft/ropen/$MRO_VERSION/lib64/R

# Download and install MRO
RUN mkdir /tmp/mro
WORKDIR /tmp/mro
RUN curl -LO -# https://mran.blob.core.windows.net/install/mro/$MRO_VERSION/Ubuntu/microsoft-r-open-$MRO_VERSION.tar.gz \
	&& tar -xzf microsoft-r-open-$MRO_VERSION.tar.gz --no-same-owner --no-same-permissions
WORKDIR /tmp/mro/microsoft-r-open
RUN  ./install.sh -a -u

# Clean up downloaded files
WORKDIR /tmp
RUN rm -r /tmp/mro

# set CRAN repository snapshot for standard package installs
RUN echo 'options(repos = c(CRAN = "https://cran.microsoft.com/snapshot/2021-01-29"))' >> /opt/microsoft/ropen/$MRO_VERSION/lib64/R/etc/Rprofile.site

# tell R to use wget (devtools::install_github aimed at HTTPS connections had problems with libcurl)
RUN echo 'options("download.file.method" = "wget")' >> /opt/microsoft/ropen/$MRO_VERSION/lib64/R/etc/Rprofile.site

# for some reason R thinks that the certificate is in the .../ropen/4.0.0/... directory, instead of 4.0.2
# this needs to be available at both build and run time (https://github.com/microsoft/microsoft-r-open/issues/63)
ENV CURL_CA_BUNDLE=/opt/microsoft/ropen/4.0.2/lib64/R/lib/microsoft-r-cacert.pem
RUN Rscript -e "remove.packages(c('curl','httr'))"
RUN Rscript -e "install.packages(c('curl', 'httr'))"

#------------------------------------------------------------------------------
# Install R packages
#------------------------------------------------------------------------------

# configure and install rJava
RUN R CMD javareconf
RUN Rscript -e "install.packages('rJava', type='source')"

# install devtools, which for some reason depends on shiny
RUN Rscript -e "install.packages('shiny')"
RUN Rscript -e "install.packages('devtools')"

# install BioConductor
RUN Rscript -e 'if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")'
RUN Rscript -e 'BiocManager::install(version = "3.12", update=FALSE, ask=FALSE)'

# install standard data science and bioinformatics packages
RUN Rscript -e 'install.packages("Rcpp")'
RUN Rscript -e 'install.packages("roxygen2")'
RUN Rscript -e 'install.packages("tidyverse")'
RUN Rscript -e 'install.packages("git2r")'
RUN Rscript -e "install.packages('getPass')"
RUN Rscript -e "install.packages('xlsx')"
RUN Rscript -e "install.packages('data.table')"
RUN Rscript -e "install.packages('dplyr')"
RUN Rscript -e "install.packages('exactmeta')"
RUN Rscript -e "install.packages('fmsb')"
RUN Rscript -e "install.packages('forestplot')"
RUN Rscript -e "install.packages('metafor')"
RUN Rscript -e "install.packages('rtf')"
RUN Rscript -e "install.packages('splines')"
RUN Rscript -e "install.packages('tidyr')"
RUN Rscript -e "install.packages('stringr')"
RUN Rscript -e "install.packages('survival')"
RUN Rscript -e "install.packages('np')"
RUN Rscript -e "install.packages('codetools')"
RUN Rscript -e "install.packages('glmnet')"
RUN Rscript -e "install.packages('glmpath')"
RUN Rscript -e "install.packages('lars')"
RUN Rscript -e "install.packages('zoo')"
RUN Rscript -e "install.packages('testthat')"
RUN Rscript -e "install.packages('DBI')"
RUN Rscript -e "install.packages('odbc')"
RUN Rscript -e "install.packages('caret')"
RUN Rscript -e "install.packages('icd.data')"

# need a newer version
RUN Rscript -e "install.packages('broom', repos='https://cran.microsoft.com/snapshot/2021-03-01/')"

# this one is missing from the 2021-01-29 snapshot, so rever to default for this MRO 4.0.2
RUN Rscript -e "install.packages('icd', repos='https://cran.microsoft.com/snapshot/2020-07-16')"

# -- vanilla because there is a bug that causes the R intro / preamble text to get pushed into the compiler
RUN Rscript --vanilla -e "install.packages('lme4', repos='https://cran.microsoft.com/snapshot/2021-01-29')"
RUN Rscript --vanilla -e "install.packages('survminer', repos='https://cran.microsoft.com/snapshot/2021-01-29')"
RUN Rscript --vanilla -e "install.packages('CVXR', repos='https://cran.microsoft.com/snapshot/2021-05-20')"

# install R packages for connecting to SQL Server and working with resulting data sets
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/FactToCube.git')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/MsSqlTools.git')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/SqlTools.git')"

# the following steps are needed for Roracle package
RUN mkdir $ORACLE_HOME/rdbms \
    && mkdir $ORACLE_HOME/rdbms/public 
RUN cp /usr/include/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64/* $ORACLE_HOME/rdbms/public \
    && chmod -R 777  $ORACLE_HOME/rdbms/public

# install ROracle
RUN Rscript -e "install.packages('ROracle')" 

 # allow modification of these locations so users can install R packages without warnings
RUN chmod -R 777 /opt/microsoft/ropen/$MRO_VERSION/lib64/R/library
RUN chmod -R 777 /opt/microsoft/ropen/$MRO_VERSION/lib64/R/doc/html/packages.html


#------------------------------------------------------------------------------
# Install and configure RStudio Server
#------------------------------------------------------------------------------

RUN mkdir /opt/rstudioserver
WORKDIR /opt/rstudioserver

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb
RUN dpkg -i ./libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb

RUN apt-get update && apt-get install -y gdebi-core

# older RStudio version (try to deal with name / pwd prompt from git credential manager):
# 1.2 works, later versions require modifying the GIT_ASKPASS environment variable
# to suppress a prompt in R
# RUN wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5042-amd64.deb
# RUN gdebi -n rstudio-server-1.2.5042-amd64.deb

RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1106-amd64.deb
RUN gdebi --non-interactive rstudio-server-1.4.1106-amd64.deb

# Copy RStudio Config
COPY rserver.conf /etc/rstudio/rserver.conf


#------------------------------------------------------------------------------
# Install 4CE software packages
#------------------------------------------------------------------------------
RUN R -e "devtools::install_github('https://github.com/covidclinical/Phase2.1UtilitiesRPackage', subdir='FourCePhase2.1Utilities', upgrade=FALSE, ref='v1.1.0')"
RUN R -e "devtools::install_github('https://github.com/covidclinical/Phase2.1DataRPackage', subdir='FourCePhase2.1Data', upgrade=FALSE, ref='v1.2.0')"

# allow modification of these locations so users can install and update R packages
RUN chmod -R 777 /opt/microsoft/ropen/$MRO_VERSION/lib64/R/library
RUN chmod -R 777 /opt/microsoft/ropen/$MRO_VERSION/lib64/R/doc/html/packages.html

#------------------------------------------------------------------------------
# Final odds and ends
#------------------------------------------------------------------------------

# Copy startup script
RUN mkdir /startup
COPY startup.sh /startup/startup.sh
RUN chmod 700 /startup/startup.sh

# Create a mount point for host filesystem data
RUN mkdir /4ceData

CMD ["/startup/startup.sh"]
