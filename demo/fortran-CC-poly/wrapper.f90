module torch_wrapper
    use, intrinsic :: iso_c_binding, only: C_int, C_float
    implicit none

    INTEGER(C_int) :: r
    REAL(C_float) :: arr(2, 2) = 1.0

    ! interface for external C function
    interface resnet_call  
        function resnet_call (input) result(r) bind(c, name="resnet_call")
            import
            REAL(C_float) :: input(2, 2)
            INTEGER(C_int) :: r
        end function
    end interface

    contains
        function model_predict (input) result(r)
            REAL(C_float) :: input(2, 2)
            INTEGER(C_int) :: r
            print *, "model call start"
            r = resnet_call(input)
            print *, "model call end"
        end function model_predict
    
end module torch_wrapper