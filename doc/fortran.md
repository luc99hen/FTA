## `use`

```fortran
USE namespace
USE namespace, ONLY: paras
USE namespace, name => rename
```

### [module](https://docs.oracle.com/cd/E19205-01/819-5263/aevog/index.html)
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


### [derived type](https://fortran-lang.org/learn/quickstart/derived_types)

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

### [interface](https://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap06/interface.html)

Any *external function* to be used should be listed in an *interface block* along with declaration of its arguments and their types and the type of the function value.

An *external function* is a function not contained in any program, function or module.


---

## reference
1. [Fortran语法简述](https://zhuanlan.zhihu.com/p/367443139)
2. [Fortran-C互操作接口](https://docs.oracle.com/cd/E19957-01/805-4940/6j4m1u7qn/index.html)