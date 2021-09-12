module pointrectangle_module

use, intrinsic :: ISO_C_Binding, only: C_int, C_double
use, intrinsic :: ISO_C_Binding, only: C_ptr, C_NULL_ptr

implicit none

private ! all paras are private without a explicit public

! https://gcc.gnu.org/onlinedocs/gfortran/Derived-Types-and-struct.html
! match Point in class.cc
TYPE, BIND(C) :: fPoint 
    REAL(C_double) :: x
    REAL(C_double) :: y
END TYPE fPoint

TYPE, BIND(C) :: fRectangle
    TYPE(fPoint) :: corner
    REAL(C_double) :: width
    REAL(C_double) :: height
END TYPE fRectangle

TYPE pointrectangle_type
private
    TYPE(C_ptr) :: object = C_NULL_ptr
END TYPE pointrectangle_type

! ---
! C function declarations
! ---

INTERFACE

! this is the result variable  https://stackoverflow.com/a/31061870
FUNCTION C_pointrectangle_new (a) result(this) bind(C, name="pointrectangle__new")
    import 
    TYPE(C_ptr) :: this
    TYPE(fRectangle), value :: a
END FUNCTION C_pointrectangle_new

SUBROUTINE C_pointrectangle_delete (this) bind(C, name="pointrectangle__delete")
    import
    TYPE(C_ptr), value :: this
END SUBROUTINE C_pointrectangle_delete

FUNCTION C_pointrectangle__findCenter (this) result(center) bind(C,name="pointrectangle__findCenter")
    import
    TYPE(fPoint) :: center
    TYPE(C_ptr), value :: this
END FUNCTION C_pointrectangle__findCenter

FUNCTION C_pointrectangle__findArea (this) result(area) bind(C,name="pointrectangle__findArea")
    import
    REAL(C_double) :: area
    TYPE(C_ptr), value :: this
END FUNCTION C_pointrectangle__findArea

SUBROUTINE C_pointrectangle__printInfo (this) bind(C,name="pointrectangle__printInfo")
    import 
    TYPE(C_ptr), value :: this
END SUBROUTINE C_pointrectangle__printInfo

END INTERFACE

! generic interface block http://www.mrao.cam.ac.uk/~pa/f90Notes/HTMLNotesnode211.html
INTERFACE new  
    MODULE PROCEDURE pointrectangle_new
END INTERFACE new

INTERFACE delete
    MODULE PROCEDURE pointrectangle__delete
END INTERFACE delete

INTERFACE findArea
    MODULE PROCEDURE pointrectangle__findArea
END INTERFACE findArea

INTERFACE printInfo
    MODULE PROCEDURE pointrectangle__printInfo
END INTERFACE printInfo

INTERFACE findCenter
    MODULE PROCEDURE pointrectangle__findCenter
END INTERFACE findCenter

public :: new, delete, findCenter, findArea, printInfo
public :: pointrectangle_type, fPoint, fRectangle


! ---
CONTAINS

!---
! Fortran wrapper routines to interface C wrappers
!---

subroutine pointrectangle_new(this, a)
    type(pointrectangle_type), intent(out) :: this
    type(fRectangle) :: a
    this%object = C_pointrectangle_new(a)
end subroutine pointrectangle_new

subroutine pointrectangle__delete(this)
    type(pointrectangle_type), intent(inout) :: this
    call C_pointrectangle_delete(this%object)
    this%object = C_NULL_ptr
end subroutine pointrectangle__delete

subroutine pointrectangle__printInfo(this)
    type(pointrectangle_type), intent(in) :: this
    call C_pointrectangle__printInfo(this%object)
end subroutine pointrectangle__printInfo

function pointrectangle__findCenter(this) result(center)
    type(pointrectangle_type), intent(in) :: this
    TYPE(fPoint) :: center
    center = C_pointrectangle__findCenter(this%object)
end function pointrectangle__findCenter

function pointrectangle__findArea(this) result(area)
    type(pointrectangle_type), intent(in) :: this
    REAL(C_double) :: area
    area = C_pointrectangle__findArea(this%object)
end function pointrectangle__findArea

end module pointrectangle_module