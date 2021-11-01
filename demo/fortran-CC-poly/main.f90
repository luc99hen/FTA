! fortran program main
! 
! call cpp function resnet_call 
!

program  main
    use torch_wrapper
    implicit none

    INTEGER(C_int) :: r
    REAL(C_float) :: arr(1, 3, 224, 224) = 1.0

    print *, "Torch Start"

    r = call_model(arr)
    print *, "return val", r

    print *, "Torch End"

end program  main