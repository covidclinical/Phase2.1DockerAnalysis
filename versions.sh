#!/bin/bash

R CMD BATCH r_versions.R R_VERSIONS
lsb_release -a > UBUNTU_VERSION
