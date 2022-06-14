#!/usr/bin/env bash
# ./build.sh [configuration_file_path] [output_file_path]

#set -ex
set -e

###################
## global settings
###################

cpp_file="model.cpp"
fortran_file="wrapper.f90"
output_folder=${2:-$(cd .. && pwd -P)/install}

###################
## utils function
###################

function print_log() {
    echo "[ LOG ] " "$@"
}

# log error
function print_error() {
    format=$1
    shift

    # shellcheck disable=SC2059
    printf "[ ERROR ] ${format}" "$@"
    exit
}

# Standarlize the string to make it conform to the variable name standards
function standardlize_string() {
    local string=$1

    string="${string##*([[:space:]])}"                              # remove leading spaces
    string="${string%%*([[:space:]])}"                              # remove trailling spaces
    string=$(echo -e "${string}" | tr -s '[:punct:] [:blank:]' '_') # transform punctations & spaces into `_`
    string=$(echo -e "${string}" | sed 's/[^a-zA-Z0-9_]//g')        # remove non-alphanumberics

    # string=$(echo -e "${string}" | tr '[:upper:]' '[:lower:]')      # transform to lower case
    echo "${string}"
}

# Standarlize the key OR value to make it easy to parse
function standardlize_value() {
    local value=$1

    value="${value%%\;*}"  # Remove in line right comments
    value="${value%%\#*}"  # Remove in line right comments
    value="${value##*( )}" # Remove leading spaces
    value="${value%%*( )}" # Remove trailing spaces
    value="${value#\"*}"   # Remove leading string quotes
    value="${value%\"*}"   # Remove trailing string quotes

    value=$(echo -e "${value}" | sed -e 's/[[:space:]]*//g') # Remove spaces in value

    echo "${value}"
}

# Usage: string_to_arr ',' string
# Output: string_arr (global)
function string_to_arr() {
    local str=$2
    local seperator=$1

    IFS="$seperator" read -r -a string_arr <<<"$str"
    # # print arr contents
    # for index in "${!arr[@]}"; do
    #     echo "$index ${arr[index]}"
    # done
}

# Usage: arr_to_string ',' arr
function arr_to_string() {
    local separator="$1"
    local args=("${@:2}")
    local result
    printf -v result '%s' "${args[@]/#/$separator}"
    printf '%s' "${result:${#separator}}"
}

# Usage: reverse_arr input_arr reverse_arr
function reverse_arr() {
    declare -n arr="$1" rev="$2"
    for i in "${arr[@]}"; do
        rev=("$i" "${rev[@]}")
    done
}

# Usage: range start end step
# [start, end]
function range() {
    local start=$1
    local end=$2
    local step=$3

    echo $(seq -s ", " $start $step $end)
}

# Usage: read_templ temp_file
# ! Notice: temp_file should have escaped quotes
function read_templ() {
    eval "echo \"$(cat $1)\""
}

###################
## process function
###################

# generating based on the settings
function generate_wrapper_file() {
    local model_name=$1
    local c_input_dim_str

    c_input_dim_str=$(printf '%s\n' "${input_dim[@]}" | tac | tr '\n' ', '; echo)
    #reverse_arr input_dim c_input_dim

    print_log "model_name:" ${model_name}
    print_log "input_dim: " $(arr_to_string ', ' "${input_dim[@]}")
    print_log "output_dim: " $(arr_to_string ', ' "${output_dim[@]}")
    print_log "input_type: " ${input_type}
    print_log "output_type: " ${output_type}

    # assure that all settings in this section are valid
    if [[ -z ${input_type} || -z ${input_dim} || -z ${output_type} || -z ${output_dim} ]]; then
        print_error "section %s format error:\n" "${model_name}"
    fi

    # generate C++ model class
    read_templ ./template/cpp_body >>${cpp_file}

    # generate Fortran file

    ## generate extern interfaces (from C++ source)
    read_templ ./template/fortran_extern_interface | sed -i "/INTERFACE/ r /dev/stdin" ${fortran_file}
    ## generate interfaces (used by user)
    read_templ ./template/fortran_interface | sed -i "/CONTAINS/ r /dev/stdin" ${fortran_file}

    echo "generate ${section} successfully!"
}

# Parse the conf file
function parse_conf() {
    local line_num=0
    local section=''
    local input_file="$1"

    if [[ -z $input_file ]]; then
        input_file="./configure.conf"
    fi

    shopt -s extglob # enable extended globbing

    while read -r line; do
        line_num=$((line_num + 1))

        # Ignore comments & empty lines
        if [[ $line =~ ^# || -z $line ]]; then
            continue
        fi

        # if match section title
        if [[ $line =~ ^"["(.+)"]".*$ ]]; then
            # if section is not null
            if [[ "${section}" ]]; then
                generate_wrapper_file "${section}"
            fi
            # start with a new section, and reset all settings
            section=$(standardlize_string "${BASH_REMATCH[1]}")
            input_type=''
            output_type=''
            input_dim=''
            output_dim=''

        # if match key-value pair
        elif [[ $line =~ ^(.*)"="(.*) ]]; then
            key=$(standardlize_value "${BASH_REMATCH[1]}")
            value=$(standardlize_value "${BASH_REMATCH[2]}")

            # check value format
            if [[ -z ${key} ]]; then
                print_error 'line %d: No key name\n' "${line_num}"
            elif [[ -z ${value} ]]; then
                print_error 'line %d: No key name\n' "${line_num}"
            fi

            # retrieve value into variable
            if [[ $key == "input_dim" ]]; then
                string_to_arr ',' $value
                input_dim=(${string_arr[@]})
            elif [[ $key == "input_format" ]]; then
                input_type=${value}
            elif [[ $key == "output_dim" ]]; then
                string_to_arr ',' $value
                output_dim=(${string_arr[@]})
            elif [[ $key == "output_format" ]]; then
                output_type=${value}
            elif [[ $key == "libtorch_path" ]]; then
                libtorch_path=${value}
            elif [[ $key == "compiler" ]]; then
                compiler_option=${value}
            fi

        fi

    done \
        <"$input_file"

    if [[ "${section}" ]]; then
        generate_wrapper_file "${section}"
    fi
}

function precompile_init() {
    echo
    echo "------------------------"
    echo "PRECOMPILE Stage Start!"
    echo "------------------------"

    # generate header file
    # cpp file
    cat <./template/cpp_header >${cpp_file}

    # Fortran file
    cat <./template/fortran_header >${fortran_file}
}

function precompile_finish() {
    echo "------------------------"
    echo "PRECOMPILE Stage Finish!"
    echo "------------------------"
}

function compile_start() {
    echo
    echo "------------------------"
    echo "COMPILE Stage Start!"
    echo "------------------------"
    if [ -d "build" ]; then
        print_log "build directory already exist, delete it"
        rm -rf ./build
    fi
    mkdir build && cd build
}

function do_compile() {
    local cxx_compiler
    local fortran_compiler

    # set libtorch path
    while [[ -z ${libtorch_path} ]]; do
        echo "Please set the libtorch library path in your computer"
        read libtorch_path
    done

    # set compiler option
    while [[ $compiler_option != 1 && $compiler_option != 2 ]]; do
        echo "Please choose your compiler(1 or 2): 1. gcc  2. icc"
        read compiler_option
    done
    if [[ $compiler_option == 1 ]]; then
        cxx_compiler="c++"
        fortran_compiler="gfortran"
    else
        cxx_compiler="icc"
        fortran_compiler="ifort"
    fi

    # cmake generate
    print_log "cmake -DCMAKE_PREFIX_PATH=${libtorch_path}  -DCMAKE_MODULE_PATH=${libtorch_path}/share/cmake/Torch -DCMAKE_CXX_COMPILER=${cxx_compiler} -DCMAKE_Fortran_COMPILER=${fortran_compiler} .."
    cmake -DCMAKE_PREFIX_PATH=$libtorch_path -DCMAKE_MODULE_PATH=$libtorch_path/share/cmake/Torch -DCMAKE_CXX_COMPILER=$cxx_compiler -DCMAKE_Fortran_COMPILER=$fortran_compiler ..
    if [ $? -ne 0 ]; then
        print_error "cmake generate fail; build abort :<\n"
    fi

    # cmake build
    print_log "cmake --build . --config Release"
    cmake --build . --config Release
    if [ $? -ne 0 ]; then
        print_error "cmake build fail; build abort :<\n"
    fi
}

function compile_end() {

    # move target files into output_folder
    cd .. # return to src directory

    if [ -d $output_folder ]; then
        print_log "build directory already exist, delete it"
        rm -rf $output_folder
    fi

    mkdir -p "${output_folder}/include"
    cp -r ./build/bin $output_folder
    cp -r ./build/lib $output_folder
    cp ./build/torch_wrapper.mod "${output_folder}/include/"

    echo "------------------------"
    echo "COMPILE Stage Finish!"
    echo "------------------------"
}

function test() {
    echo "------------------------"
    echo "TEST Stage Start!"
    echo "------------------------"

    cd "$output_folder/bin"

    if ./test_cpu; then
        print_log "FTA CPU test pass!"
    else
        print_error "FTA CPU test fail!\n"
    fi

    if ./test_gpu; then
        print_log "FTA GPU test pass!"
    else
        print_error "FTA GPU test fail!\n"
    fi

    echo "------------------------"
    echo "TEST Stage Finish!"
    echo "------------------------"
}

###################
## main process
###################

precompile_init
parse_conf "$1"
precompile_finish

compile_start
do_compile
compile_end

test
