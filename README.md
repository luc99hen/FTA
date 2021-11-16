FTB is a Fortran-Torch-Bridge aimed for integrating deep learning model into Forrtan environment.

# prerequisite

- [Docker && nvidia-container-runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#getting-started)
- 

# settings 
- data type supported: float, int, double
- data size format: (a b c)
- model name: will be used for interface name

# test

Phased testing
- libtorch basic operation 
- cpu/gpu
- different input
    - shape
    - allocatable  