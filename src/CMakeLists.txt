cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(custom_ops CXX Fortran)

find_package(Torch REQUIRED)

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

target_link_libraries(torch_wrapper_F call_ts_cpp)
target_link_libraries(call_ts_cpp "${TORCH_LIBRARIES}")

set_property(TARGET test_cpu PROPERTY CXX_STANDARD 14)
set_property(TARGET test_gpu PROPERTY CXX_STANDARD 14)