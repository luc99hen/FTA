! fortran program main
! 
! call cpp function resnet_call 
!

program  main
    use torch_wrapper

    implicit none

    print *, "Torch Start"

    r = model_predict(arr)
    print *, "return val", r

    print *, "Torch End"

end program  main
