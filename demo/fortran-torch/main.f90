! fortran program main
! 
! call cpp function resnet_call 
!

program  main
    use, intrinsic :: iso_c_binding, only: C_int, C_float
    implicit none

    INTEGER(C_int) :: r
    REAL(C_float) :: arr(1, 3, 224, 224) = 1.0

    ! interface for external C function
    interface resnet_call  
        function resnet_call (input) result(r) bind(c, name="resnet_call")
            import
            REAL(C_float) :: input(1, 3, 224, 224)
            INTEGER(C_int) :: r
        end function
    end interface
    
    print *, "Main Start"

    r = resnet_call(arr)
    print *, "return val", r

    print *, "Main End"

end program  main
