cmake_minimum_required(VERSION 3.0 FATAL_ERROR)

# project name and enabled languages
project(fortran_calls_ts CXX Fortran)

# find libtorch
find_package(Torch REQUIRED)

# if CMAKE_BUILD_TYPE undefined, set it to Release
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

# compiler flags for release mode
set(CMAKE_CXX_FLAGS_RELEASE "-O3")
set(CMAKE_Fortran_FLAGS_RELEASE "-O3")

# set default build paths
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib)

# generated export header will be placed here
include_directories(${PROJECT_BINARY_DIR})

# c library
add_library(call_ts_cpp SHARED call_ts.cpp)

# fortran wrapper library
add_library(torch_wrapper_F SHARED wrapper.f90)

# fortran executable
add_executable(torch_caller main.f90)

# linked against c library
target_link_libraries(torch_caller torch_wrapper_F)
target_link_libraries(torch_wrapper_F call_ts_cpp)
target_link_libraries(call_ts_cpp "${TORCH_LIBRARIES}")

# let cmake generate the export header
include(GenerateExportHeader)
generate_export_header(call_ts_cpp BASE_NAME call_ts)

install(TARGETS call_ts_cpp LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(FILES call_ts.h ${PROJECT_BINARY_DIR}/call_ts_export.h DESTINATION include)

set_property(TARGET torch_caller PROPERTY CXX_STANDARD 14)
