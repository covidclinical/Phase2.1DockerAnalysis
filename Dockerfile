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

## TODO:
## install RStudio Server / notebooks