! fortran program main
! 
! call cpp function resnet_call 
!

program  main
    use torch_wrapper
    implicit none

    CHARACTER(100), TARGET :: model_loc;
    TYPE(ftorchmodel) :: model;
    INTEGER :: res
    REAL(C_float) :: input(1, 3, 224, 224) = 1.0
    REAL :: output(1, 1000)


    model_loc = "/home/dl/luc/FTB/demo/lib/resnet.pt"//CHAR(0)  ! CHAR(0) is necessary for C string termination 

    print *, "Torch Start"

    model = torchmodel_new(model_loc, 0)
    res = torchmodel_forward(model, input, output)
    call torchmodel_delete(model)

    print *, output(1, 1)
    print *, "Torch End"

end program  main