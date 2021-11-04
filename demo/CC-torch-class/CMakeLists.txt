cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(custom_ops)

find_package(Torch REQUIRED)

add_executable(model model.cpp)

target_link_libraries(model "${TORCH_LIBRARIES}")
set_property(TARGET model PROPERTY CXX_STANDARD 14)