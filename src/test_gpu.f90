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
    REAL :: input(1, 3, 224, 224) = 1.0
    REAL :: output(1, 1000)
    INTEGER(C_INT) :: use_gpu = 1

    model_loc = "../../lib/resnet.pt"//CHAR(0)  ! CHAR(0) is necessary for C string termination 

    print *, "Test GPU Start"

    model = test_model_new(model_loc, use_gpu)
    res = test_model_forward(model, input, output)
    call test_model_delete(model)

    print *, output(1, 1)
    print *, "Test GPU End"

end program  main