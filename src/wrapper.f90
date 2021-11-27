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

    FUNCTION C_resnet32_new (model_loc, gpu) result(this) bind(C, name="resnet32_new")
        import 
        TYPE(C_ptr) :: this
        CHARACTER(C_CHAR) :: model_loc(100)
        INTEGER(C_INT), value :: gpu
    END FUNCTION C_resnet32_new

    SUBROUTINE C_resnet32_delete (this) bind(C, name="resnet32_delete")
        import 
        TYPE(C_ptr), value :: this
    END SUBROUTINE

    FUNCTION C_resnet32_forward (this, input, output) result(flag) bind(C, name="resnet32_forward")
        import 
        TYPE(C_ptr), value :: this
        INTEGER(C_int) :: flag
        REAL(C_double) :: input(1, 3, 224, 448)           ! generate
        REAL(C_float) :: output(1, 100, 80)        ! generate
    END FUNCTION C_resnet32_forward

    FUNCTION C_test_model_new (model_loc, gpu) result(this) bind(C, name="test_model_new")
        import 
        TYPE(C_ptr) :: this
        CHARACTER(C_CHAR) :: model_loc(100)
        INTEGER(C_INT), value :: gpu
    END FUNCTION C_test_model_new

    SUBROUTINE C_test_model_delete (this) bind(C, name="test_model_delete")
        import 
        TYPE(C_ptr), value :: this
    END SUBROUTINE

    FUNCTION C_test_model_forward (this, input, output) result(flag) bind(C, name="test_model_forward")
        import 
        TYPE(C_ptr), value :: this
        INTEGER(C_int) :: flag
        REAL(C_float) :: input(1, 3, 224, 224)           ! generate
        REAL(C_float) :: output(1, 100)        ! generate
    END FUNCTION C_test_model_forward

    END INTERFACE
    
    ! ---
    ! Fortran wrapper routines to interface C wrappers
    ! ---
    CONTAINS

    function resnet32_new(model_loc, gpu) result(this)
        character(100), target, intent(in) :: model_loc
        INTEGER(C_INT), intent(in) :: gpu
        type(fTorchModel) :: this

        this%object = C_resnet32_new(model_loc, gpu)
    end function resnet32_new

    subroutine resnet32_delete(this)
        type(fTorchModel), intent(inout) :: this
        call C_resnet32_delete(this%object)
        this%object = C_NULL_ptr    
    end subroutine resnet32_delete

    function resnet32_forward(this, input, output) result(flag) 
        type(fTorchModel), intent(inout) :: this
        REAL(C_double) :: input(1, 3, 224, 448)              ! generate
        REAL(C_float) :: output(1, 100, 80)            ! generate
        INTEGER(C_INT) :: flag
        flag = C_resnet32_forward(this%object, input, output)
    end function resnet32_forward

    function test_model_new(model_loc, gpu) result(this)
        character(100), target, intent(in) :: model_loc
        INTEGER(C_INT), intent(in) :: gpu
        type(fTorchModel) :: this

        this%object = C_test_model_new(model_loc, gpu)
    end function test_model_new

    subroutine test_model_delete(this)
        type(fTorchModel), intent(inout) :: this
        call C_test_model_delete(this%object)
        this%object = C_NULL_ptr    
    end subroutine test_model_delete

    function test_model_forward(this, input, output) result(flag) 
        type(fTorchModel), intent(inout) :: this
        REAL(C_float) :: input(1, 3, 224, 224)              ! generate
        REAL(C_float) :: output(1, 100)            ! generate
        INTEGER(C_INT) :: flag
        flag = C_test_model_forward(this%object, input, output)
    end function test_model_forward

end module torch_wrapper
