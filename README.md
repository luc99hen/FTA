FTA is a Fortran-Torch-Adapter aimed for integrating deep learning model into Fortran environment. It has been used in replacing parameterization schemes in WRF with a [published paper](https://www.frontiersin.org/journals/earth-science/articles/10.3389/feart.2023.1149566/full)

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
    INTEGER(C_INT) :: use_gpu = 1                  ! should be compatible with your script module device


    model_loc = "/home/dl/luc/FTB/demo/lib/resnet.pt"//CHAR(0)  ! CHAR(0) is necessary for C string termination 

    print *, "Torch Start"

    model = resnet18_new(model_loc, use_gpu)        ! initialize the model
    res = resnet18_forward(model, input, output)    ! use the model to perform reasoning task
    call resnet18_delete(model)                     ! delete this model

    print *, output(1, 1)
    print *, "Torch End"

end program  main
```

# Dependencies

- CMake (>=3.0)
- gcc or icc compiler 
- [libtorch](https://pytorch.org/)
- Docker & nvidia-container-toolkit (OPTIONAL)

# How to Use

> Notice: we assume you already have a machine with Nvidia Driver installed properly.

## Manually setup

1. download libtorch 
    1. match your local CUDA version
    2. C++11 ABI ([choose this version if your compiler is `icc`](https://stackoverflow.com/questions/66192285/libtorch-works-with-g-but-fails-with-intel-compiler)) 
2. define your model in the [configuration file](./src/configure.conf)
    - data type supported: float, int, double
    - data size format: a, b, c
    - model name: will be used for interface name
3. run [`./build.sh`](./src/build.sh)
4. use the `torch_wrapper` library in your Fortran program

## Setup with Docker 

1. install [nvidia-container-toolkit & Docker](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#getting-started)
2. get image 
    1. build locally `docker build -t fortran-torch-adapter .`
    2. Or you can pull from dockerhub `docker pull 1813927768/fortran-torch-adapter:latest`
3. start the container `docker run -it  --rm --gpus all fortran-torch-adapter /bin/bash`
4. run `./build.sh` in the container
