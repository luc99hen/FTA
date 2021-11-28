####################
# This script is used in docker image build stage to install FTA dependencies
####################

#!/bin/bash

apt-get update
apt-get install -y unzip wget cmake gfortran vim

wget -O libtorch11.zip https://download.pytorch.org/libtorch/cu112/libtorch-cxx11-abi-shared-with-deps-1.8.0%2Bcu112.zip
unzip libtorch11.zip -d /lib
