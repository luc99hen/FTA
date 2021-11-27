#!/usr/bin/env bash

###################
## global settings
###################

cpp_file="model.cpp"
fortran_file="wrapper.f90"

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

###################
## process function
###################

# generating based on the settings
function generate_wrapper_file() {
    local model_name=$1
    local c_input_dim

    reverse_arr input_dim c_input_dim

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
    cat >>${cpp_file} <<-EOF

class ${model_name}
{
    // torch model
    torch::jit::script::Module module;

    // whether to use gpu
    int use_gpu;

public:
    ${model_name}(const char *model_loc, // torchscript model store location (absolute path)
               int use_gpu);

    int forward(void *input_data, void *output_data);
};

// constructor
${model_name}::${model_name}(const char *model_loc, int gpu)
{
    try
    {
        module = torch::jit::load(model_loc);
    }
    catch (const c10::Error &e)
    {
        std::cerr << "error loading the model\n";
        return;
    }

    use_gpu = gpu;
}

// call model
int ${model_name}::forward(void *input_data, void *output_data)
{
    // create a vector of inputs
    std::vector<torch::jit::IValue> inputs;
    // parse the array in Fortran mem layout (reverse the dimension order)
    //  according to its type
    at::Tensor input_tensor;
    input_tensor = torch::from_blob((${input_type} *)input_data, {$(arr_to_string ', ' "${c_input_dim[@]}")}); // generate

    // permute the array mem layout from Fortran to C
    // reverse all dimensions order
    input_tensor = input_tensor.permute({$(range $((${#input_dim[@]} - 1)) 0 -1)}); // generate

    // use GPU
    if (use_gpu)
    {
        input_tensor = input_tensor.to(at::kCUDA);
        module.to(at::kCUDA);
    }

    inputs.push_back(input_tensor);

    // Execute the model and turn its output into a tensor.
    at::Tensor output_tensor = module.forward(inputs).toTensor();

    // permute the array mem layout from C to Fortran
    output_tensor = output_tensor.permute({$(range $((${#output_dim[@]} - 1)) 0 -1)}); // generate
    // convert the discontinuous tensor into a continuous tensor & port it to cpu if possible
    output_tensor = output_tensor.contiguous().cpu();
    std::memcpy(output_data, output_tensor.data_ptr(), output_tensor.numel() * sizeof(${output_type})); // generate

    return 1;
}

// C wrapper interfaces to C++ routines
extern "C"
{

    ${model_name} *${model_name}_new(const char *model_loc, int gpu)
    {
        return new ${model_name}(model_loc, gpu);
    }

    int ${model_name}_forward(${model_name} *This, void *input, void *output)
    {
        return This->forward(input, output);
    }

    void ${model_name}_delete(${model_name} *This)
    {
        delete This;
    }
}
EOF

    # generate Fortran file
    cat <<-EOF | sed -i "/INTERFACE/ r /dev/stdin" ${fortran_file}

    FUNCTION C_${model_name}_new (model_loc, gpu) result(this) bind(C, name="${model_name}_new")
        import 
        TYPE(C_ptr) :: this
        CHARACTER(C_CHAR) :: model_loc(100)
        INTEGER(C_INT), value :: gpu
    END FUNCTION C_${model_name}_new

    SUBROUTINE C_${model_name}_delete (this) bind(C, name="${model_name}_delete")
        import 
        TYPE(C_ptr), value :: this
    END SUBROUTINE

    FUNCTION C_${model_name}_forward (this, input, output) result(flag) bind(C, name="${model_name}_forward")
        import 
        TYPE(C_ptr), value :: this
        INTEGER(C_int) :: flag
        REAL(C_${input_type}) :: input($(arr_to_string ', ' "${input_dim[@]}"))           ! generate
        REAL(C_${output_type}) :: output($(arr_to_string ', ' "${output_dim[@]}"))        ! generate
    END FUNCTION C_${model_name}_forward
EOF

    cat <<-EOF | sed -i "/CONTAINS/ r /dev/stdin" ${fortran_file}

    function ${model_name}_new(model_loc, gpu) result(this)
        character(100), target, intent(in) :: model_loc
        INTEGER(C_INT), intent(in) :: gpu
        type(fTorchModel) :: this

        this%object = C_${model_name}_new(model_loc, gpu)
    end function ${model_name}_new

    subroutine ${model_name}_delete(this)
        type(fTorchModel), intent(inout) :: this
        call C_${model_name}_delete(this%object)
        this%object = C_NULL_ptr    
    end subroutine ${model_name}_delete

    function ${model_name}_forward(this, input, output) result(flag) 
        type(fTorchModel), intent(inout) :: this
        REAL(C_${input_type}) :: input($(arr_to_string ', ' "${input_dim[@]}"))              ! generate
        REAL(C_${output_type}) :: output($(arr_to_string ', ' "${output_dim[@]}"))            ! generate
        INTEGER(C_INT) :: flag
        flag = C_${model_name}_forward(this%object, input, output)
    end function ${model_name}_forward
EOF

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
        if [[ $line =~ ^"["(.+)"]"$ ]]; then
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
    cat >${cpp_file} <<EOF
#include <iostream>
#include <memory>

#include <torch/script.h>
EOF
    # Fortran file
    cat >${fortran_file} <<EOF
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

    END INTERFACE
    
    ! ---
    ! Fortran wrapper routines to interface C wrappers
    ! ---
    CONTAINS

end module torch_wrapper
EOF
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
    local libtorch_path
    local compiler_option
    local cxx_compiler
    local fortran_compiler

    # set libtorch path
    echo "Please set the libtorch library path in your computer"
    read libtorch_path
    while [[ -z ${libtorch_path} ]]; do
        print_log "libtorch path shouldn't be empty"
        echo "Please set the libtorch library path in your computer"
        read libtorch_path
    done

    # set compiler option
    echo "Please choose your compiler(1/2): 1. gcc  2. icc"
    read compiler_option
    while [[ $compiler_option != 1 && $compiler_option != 2 ]]; do
        print_log "compiler option should be either 1 or 2"
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
    cmake -DCMAKE_PREFIX_PATH=$libtorch_path -DCMAKE_MODULE_PATH=$libtorch_path/share/cmake/Torch -DCMAKE_CXX_COMPILER=$cxx_compiler -DCMAKE_Fortran_COMPILER=$fortran_compiler ..
    if [ $? -ne 0 ]; then
        print_error "cmake generate fail; build abort :<\n"
    fi

    # cmake build
    cmake --build . --config Release
    if [ $? -ne 0 ]; then
        print_error "cmake build fail; build abort :<\n"
    fi
}

function compile_end() {
    echo "------------------------"
    echo "COMPILE Stage Finish!"
    echo "------------------------"
}

function test() {
    echo "------------------------"
    echo "TEST Stage Start!"
    echo "------------------------"

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
