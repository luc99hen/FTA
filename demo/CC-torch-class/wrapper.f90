module torch_wrapper

    use, intrinsic :: ISO_C_Binding
    implicit none

    ! ---
    ! C struct declaration
    ! ---

    ! match TorchModel in model.cpp
    TYPE fTorchModel
    PRIVATE
        TYPE(C_ptr) :: object = C_NULL_ptr
    END TYPE fTorchModel

    
    ! ---
    ! C function declarations
    ! ---
    INTERFACE

    FUNCTION C_torchmodel_new (model_loc, gpu) result(this) bind(C, name="torchmodel_new")
        import 
        TYPE(C_ptr) :: this
        CHARACTER(C_CHAR) :: model_loc(100)
        INTEGER(C_INT) :: gpu
    END FUNCTION C_torchmodel_new

    SUBROUTINE C_torchmodel_delete (this) bind(C, name="torchmodel_delete")
        import 
        TYPE(C_ptr), value :: this
    END SUBROUTINE

    FUNCTION C_torchmodel_forward (this, input, output) result(flag) bind(C, name="torchmodel_forward")
        import 
        TYPE(C_ptr), value :: this
        INTEGER(C_int) :: flag
        REAL(C_float) :: input(1, 3, 224, 224)  ! generate
        REAL(C_float) :: output(1, 1000)        ! generate
    END FUNCTION C_torchmodel_forward

    END INTERFACE
    
    ! ---
    ! Fortran wrapper routines to interface C wrappers
    ! ---
    CONTAINS
    function torchmodel_new(model_loc, gpu) result(this)
        character(100), target, intent(in) :: model_loc
        INTEGER(C_INT), intent(in) :: gpu
        type(fTorchModel) :: this

        this%object = C_torchmodel_new(model_loc, gpu)
    end function torchmodel_new

    subroutine torchmodel_delete(this)
        type(fTorchModel), intent(inout) :: this
        call C_torchmodel_delete(this%object)
        this%object = C_NULL_ptr    
    end subroutine torchmodel_delete

    function torchmodel_forward(this, input, output) result(flag) 
        type(fTorchModel), intent(inout) :: this
        REAL(C_float) :: input(1, 3, 224, 224)      ! generate
        REAL(C_float) :: output(1, 1000)            ! generate
        INTEGER(C_INT) :: flag
        flag = C_torchmodel_forward(this%object, input, output)
    end function torchmodel_forward

end module torch_wrapper