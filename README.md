FTA is a Fortran-Torch-Adapter aimed for integrating deep learning model into Forrtan environment.

```Fortran
! fortran program main
! 
! use PyTorch modle resnet.pt in a Fortran program with FTA library torch_wrapper
!

program  main
    use torch_wrapper
    implicit none

    CHARACTER(100), TARGET :: model_loc;
    TYPE(ftorchmodel) :: model;
    INTEGER :: res
    REAL(C_float) :: input(1, 3, 224, 224) = 1.0
    REAL :: output(1, 1000)
    INTEGER(C_INT) :: use_gpu = 1


    model_loc = "/home/dl/luc/FTB/demo/lib/resnet.pt"//CHAR(0)  ! CHAR(0) is necessary for C string termination 

    print *, "Torch Start"

    model = resnet18_new(model_loc, use_gpu)
    res = resnet18_forward(model, input, output)
    call resnet18_delete(model)

    print *, output(1, 1)
    print *, "Torch End"

end program  main
```

# prerequisite

- CMake (>=3.0)
- gcc or icc compiler
- libtorch
- [Docker && nvidia-container-runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#getting-started) (OPTIONAL)

# How to Use
1. download libtorch 
    1. match CUDA version
    2. C++11 ABI ([compiler compatibility](https://zhuanlan.zhihu.com/p/125197727)) 
2. define your model in configuration file
    - data type supported: float, int, double
    - data size format: (a b c)
    - model name: will be used for interface name
3. ./build.sh configure.conf
4. use the torch_wrapper library in your Fortran program


# test

Phased testing
- libtorch basic operation 
- cpu/gpu
- different input
    - shape
    - allocatable  