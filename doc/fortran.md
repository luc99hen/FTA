## Module
[Module](https://www.tutorialspoint.com/fortran/fortran_modules.htm) provides you a way of splitting your programs between multiple files. It is used for:
- Packaging subprograms, data and interface blocks.
- Defining global data that can be used by more than one routine.
- Declaring variables that can be made available within any routines you choose.
- Importing a module entirely, for use, into another program or subroutine.

### Module Syntax
A module consists of two parts:
- a specification part for statements declaration
- a `contains` part for subroutine and function definitions

```Fortran
module name     
   [statement declarations]  
   [contains [subroutine and function definitions] ] 
end module [name]
```


#### `use`

```fortran
USE namespace
USE namespace, ONLY: paras
USE namespace, name => rename
```

> Use `ONLY` as much as possible is a [good practice](https://stackoverflow.com/questions/3874585/emulating-namespaces-in-fortran-90)

### [Module Usage](https://docs.oracle.com/cd/E19205-01/819-5263/aevog/index.html)
Compiling a file containing a F95 module generates both an interface file (`.mod` file) and an (`.o`) object file. The compiler looks for the interface file in the current working directory when compiling `USE` modulename statements.



### instrinct modules 
Fortran 2003 introduced [intrinsic modules](https://riptutorial.com/fortran/example/5650/intrinsic-modules) which provide access to special named constants, derived types and module procedures.

```fortran
USE, INTRINSIC :: ISO_C_Binding 
```

## `implicit none`
`implicit none` statement is used to inhibit a very old feature of Fortran that by default treats all variables that starts with the letters i,j,k,l,m and n as integers and all other variables as real arguments.

It should always be used after `program` or `use`, following the implicit none statement will be your variable declarations.


## `private`

All entities listed in PRIVATE will not be accessible from outside of the module and all entities listed in PUBLIC can be accessed from outside of the module. All the others entities, by default, can be accessed from outside of the module.


## type && derived type

### type


### [Derived type](https://fortran-lang.org/learn/quickstart/derived_types)

It is a special form of data type that can encapsulate other built-in types as well as other derived type.  It's equivalent to `struct` in C.

```fortran
TYPE :: t_pair
    INTEGER :: i
    REAL :: x
END TYPE

! Declare
TYPE(t_pair) :: pair
! initialize
pair%i = 1   ! `%` is used to access members of derived type 
pair%x = 0.5
```

### [Interface block](https://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap06/interface.html)

All functions should be one of:
- external function, a function not contained in any program or module.
- internal function, function declared in this file
- function in modules, `use module`


*Interface* is introduced to let the program to know the external function interface.

Any *external function* to be used should be listed in an *interface block* along with declaration of its arguments and their types and the type of the function value.

#### [Generic interface](http://www.personal.psu.edu/jhm/f90/statements/interfac.html)

Fortran's generic programming ability at compile stage.

```fortran
Interface vector_add
    Function ivector_add(a,b,n)
        Implicit none
        integer, intent(in) :: a(:),b(:),n
        integer ivector_add(size(a))
    end function ivector_add
    function rvector_add(a,b,n)
        implicit none
        real, intent(in) :: a(:),b(:),n
        real rvector_add(size(a))
    end function rvector_add
end interface vector_add
```

---

## reference
1. [Fortran语法简述](https://zhuanlan.zhihu.com/p/367443139)
2. [Fortran-C互操作接口](https://docs.oracle.com/cd/E19957-01/805-4940/6j4m1u7qn/index.html)