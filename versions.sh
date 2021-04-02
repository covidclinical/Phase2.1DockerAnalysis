#!/bin/bash

R CMD BATCH --slave --no-timing r_versions.R R_VERSIONS
lsb_release -a > UBUNTU_VERSION
