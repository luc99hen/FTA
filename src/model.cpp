#include <iostream>
#include <memory>

#include <torch/script.h>

class resnet18
{
    // torch model
    torch::jit::script::Module module;

    // whether to use gpu
    int use_gpu;

public:
    resnet18(const char *model_loc, // torchscript model store location (absolute path)
               int use_gpu);

    int forward(void *input_data, void *output_data);
};

// constructor
resnet18::resnet18(const char *model_loc, int gpu)
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
int resnet18::forward(void *input_data, void *output_data)
{
    // create a vector of inputs
    std::vector<torch::jit::IValue> inputs;
    // parse the array in Fortran mem layout (reverse the dimension order)
    //  according to its type
    at::Tensor input_tensor;
    input_tensor = torch::from_blob((float *)input_data, {224, 224, 3, 1}); // generate

    // permute the array mem layout from Fortran to C
    // reverse all dimensions order
    input_tensor = input_tensor.permute({3, 2, 1, 0}); // generate

    // use GPU
    if (use_gpu)
    {
        input_tensor = input_tensor.to(at::kCUDA);
        module.to(at::kCUDA);
    }

    inputs.push_back(input_tensor);

    // Execute the model and turn its output into a tensor.
    at::Tensor output_tensor = module.forward(inputs).toTensor();
    std::cout << output_tensor.slice(/*dim=*/1, /*start=*/0, /*end=*/5) << '\n';

    // permute the array mem layout from C to Fortran
    output_tensor = output_tensor.permute({1, 0}); // generate
    // convert the discontinuous tensor into a continuous tensor & port it to cpu if possible
    output_tensor = output_tensor.contiguous().cpu();
    std::memcpy(output_data, output_tensor.data_ptr(), output_tensor.numel() * sizeof(float)); // generate

    return 1;
}

// C wrapper interfaces to C++ routines
extern "C"
{

    resnet18 *resnet18_new(const char *model_loc, int gpu)
    {
        return new resnet18(model_loc, gpu);
    }

    int resnet18_forward(resnet18 *This, void *input, void *output)
    {
        return This->forward(input, output);
    }

    void resnet18_delete(resnet18 *This)
    {
        delete This;
    }
}

class resnet32
{
    // torch model
    torch::jit::script::Module module;

    // whether to use gpu
    int use_gpu;

public:
    resnet32(const char *model_loc, // torchscript model store location (absolute path)
               int use_gpu);

    int forward(void *input_data, void *output_data);
};

// constructor
resnet32::resnet32(const char *model_loc, int gpu)
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
int resnet32::forward(void *input_data, void *output_data)
{
    // create a vector of inputs
    std::vector<torch::jit::IValue> inputs;
    // parse the array in Fortran mem layout (reverse the dimension order)
    //  according to its type
    at::Tensor input_tensor;
    input_tensor = torch::from_blob((double *)input_data, {224, 3, 1}); // generate

    // permute the array mem layout from Fortran to C
    // reverse all dimensions order
    input_tensor = input_tensor.permute({2, 1, 0}); // generate

    // use GPU
    if (use_gpu)
    {
        input_tensor = input_tensor.to(at::kCUDA);
        module.to(at::kCUDA);
    }

    inputs.push_back(input_tensor);

    // Execute the model and turn its output into a tensor.
    at::Tensor output_tensor = module.forward(inputs).toTensor();
    std::cout << output_tensor.slice(/*dim=*/1, /*start=*/0, /*end=*/5) << '\n';

    // permute the array mem layout from C to Fortran
    output_tensor = output_tensor.permute({2, 1, 0}); // generate
    // convert the discontinuous tensor into a continuous tensor & port it to cpu if possible
    output_tensor = output_tensor.contiguous().cpu();
    std::memcpy(output_data, output_tensor.data_ptr(), output_tensor.numel() * sizeof(float)); // generate

    return 1;
}

// C wrapper interfaces to C++ routines
extern "C"
{

    resnet32 *resnet32_new(const char *model_loc, int gpu)
    {
        return new resnet32(model_loc, gpu);
    }

    int resnet32_forward(resnet32 *This, void *input, void *output)
    {
        return This->forward(input, output);
    }

    void resnet32_delete(resnet32 *This)
    {
        delete This;
    }
}
