FTB is a Fortran-Torch-Bridge aimed for integrating deep learning model into Forrtan environment.

# prerequisite

- [Docker && nvidia-container-runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#getting-started)
- CMake

# How to Use
1. prepare libtorch 
    1. match CUDA version
    2. C++11 ABI (compiler) https://zhuanlan.zhihu.com/p/125197727
2. define your model in configuration file
    - data type supported: float, int, double
    - data size format: (a b c)
    - model name: will be used for interface name
3. ./build.sh configure.conf
4. link it into your Fortran program


# test

Phased testing
- libtorch basic operation 
- cpu/gpu
- different input
    - shape
    - allocatable  