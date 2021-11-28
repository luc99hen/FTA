FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu18.04

WORKDIR /FTA

COPY install.sh /FTA/

# install libtorch
RUN ./install.sh  

COPY . /FTA/

CMD ["/bin/bash"]