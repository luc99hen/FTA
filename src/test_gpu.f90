! fortran program test_gpu
! 
! test if torch_script modle can be used in GPU environment 
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

    model_loc = "../../lib/resnet.pt"//CHAR(0)  ! CHAR(0) is necessary for C string termination 

    print *, "Test GPU Start"

    model = resnet18_new(model_loc, use_gpu)
    res = resnet18_forward(model, input, output)
    call resnet18_delete(model)

    print *, output(1, 1)
    print *, "Test GPU End"

end program  main