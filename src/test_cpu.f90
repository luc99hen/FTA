! fortran program test_cpu
! 
! test if torch_script modle can be used in CPU environment 
!

program  main
    use torch_wrapper
    implicit none

    CHARACTER(100), TARGET :: model_loc;
    TYPE(ftorchmodel) :: model;
    INTEGER :: res
    REAL(C_float), dimension(:, :, :, :), allocatable :: input
    REAL :: output(1, 1000)
    INTEGER(C_INT) :: use_gpu = 0


    model_loc = "../../lib/resnet.pt"//CHAR(0)  ! CHAR(0) is necessary for C string termination 

    allocate (input(1, 3, 224, 224))
    input = 1.0

    print *, "Test CPU Start"

    model = test_model_new(model_loc, use_gpu)
    res = test_model_forward(model, input, output)
    call test_model_delete(model)

    deallocate (input)
    print *, output(1, 1)
    print *, "Test CPU End"

end program  main