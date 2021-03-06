#include <iostream>
#include <memory>

#include <torch/script.h>

class TorchModel
{
    // torch model
    torch::jit::script::Module module;

    // whether to use gpu
    int use_gpu;

public:
    TorchModel(const char *model_loc, // torchscript model store location (absolute path)
               int use_gpu);

    int forward(void *input_data, void *output_data);
};

// constructor
TorchModel::TorchModel(const char *model_loc, int gpu)
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
int TorchModel::forward(void *input_data, void *output_data)
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

    TorchModel *torchmodel_new(const char *model_loc, int gpu)
    {
        return new TorchModel(model_loc, gpu);
    }

    int torchmodel_forward(TorchModel *This, void *input, void *output)
    {
        return This->forward(input, output);
    }

    void torchmodel_delete(TorchModel *This)
    {
        delete This;
    }
}

// test usage
int test(int argc, const char *argv[])
{
    TorchModel *model = new TorchModel("/home/dl/luc/FTB/demo/lib/resnet.pt", 0);

    float input_data[1][3][244][244] = {1};
    float output_data[1000][1];
    model->forward(input_data, output_data);
}