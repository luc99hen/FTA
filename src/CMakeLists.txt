cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(custom_ops CXX Fortran)

find_package(Torch REQUIRED)

# general settings

## fortran compiler settings
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
    set(dialect "-ffree-form -std=f2008 -fimplicit-none -g -cpp")
    set(bounds "-fcheck=bounds")
endif()
if(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
    set(dialect "-stand f08 -free -implicitnone -g")
    set(bounds "-check bounds")
endif()

set(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} ${dialect} ${bounds}")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${dialect}")

## c++ compiler settings
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -Wall")      # -g enables debug, -Wall enables questionable warnings 

## target file locations
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# c library
add_library(call_ts_cpp SHARED model.cpp)

# fortran wrapper library
add_library(torch_wrapper_F SHARED wrapper.f90)

# fortran executable
add_executable(test_cpu test_cpu.f90)
add_executable(test_gpu test_gpu.f90)

# linked against c library
target_link_libraries(test_cpu torch_wrapper_F)
target_link_libraries(test_gpu torch_wrapper_F)

target_link_libraries(torch_wrapper_F PRIVATE call_ts_cpp)
target_link_libraries(call_ts_cpp PRIVATE "${TORCH_LIBRARIES}")

set_property(TARGET test_cpu PROPERTY CXX_STANDARD 14)
set_property(TARGET test_gpu PROPERTY CXX_STANDARD 14)