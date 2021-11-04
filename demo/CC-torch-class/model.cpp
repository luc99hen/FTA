#include <iostream>
#include <memory>
#include "utils.h"

#include <torch/script.h>

// Array defines the input/output format
struct ArraySchema
{
    const long int *shape; // array dimension
    size_t shape_length;
    char type; // array type [d(ouble), f(loat), i(nt)]
};

class TorchModel
{
    // torch model
    torch::jit::script::Module module;

    // input/output schema
    char input_type;
    c10::IntArrayRef *input_shape;
    char output_type;
    c10::IntArrayRef *output_shape;

    // whether to use gpu
    int use_gpu;

public:
    TorchModel(const char *model_loc, // torchscript model store location (absolute path)
               ArraySchema &input, ArraySchema &output, int use_gpu);
    ~TorchModel();

    int forward(void *input_data, void *output_data);
};

// constructor
TorchModel::TorchModel(const char *model_loc, ArraySchema &inputSchema, ArraySchema &outputSchema, int gpu)
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
    input_type = inputSchema.type;
    output_type = outputSchema.type;
    input_shape = new c10::IntArrayRef(inputSchema.shape, inputSchema.shape_length);
    output_shape = new c10::IntArrayRef(outputSchema.shape, outputSchema.shape_length);
}

// destructor
TorchModel::~TorchModel()
{
    delete input_shape;
    delete output_shape;
}

// call model
int TorchModel::forward(void *input_data, void *output_data)
{
    // create a vector of inputs
    std::vector<torch::jit::IValue> inputs;
    // parse the array in Fortran mem layout (reverse the dimension order)
    //  according to its type
    at::Tensor input_tensor;
    switch (input_type)
    {
    case 'f':
        input_tensor = torch::from_blob((float *)input_data, *input_shape);
        break;
    case 'd':
        input_tensor = torch::from_blob((double *)input_data, *input_shape);
        break;
    case 'i':
        input_tensor = torch::from_blob((int *)input_data, *input_shape);
        break;
    default:
        std::cerr << "unsupported input type (should be [d(ouble), f(loat), i(nt)])\n";
        return -1;
    }

    // permute the array mem layout from Fortran to C
    // reverse all dimensions order
    input_tensor = input_tensor.permute(range((long)(input_shape->size() - 1), -1L, -1L));

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
    output_tensor = output_tensor.permute(range((long)(output_shape->size() - 1), -1L, -1L));
    // convert the discontinuous tensor into a continuous tensor & port it to cpu if possible
    output_tensor = output_tensor.contiguous().cpu();
    switch (output_type)
    {
    case 'f':
        std::memcpy(output_data, output_tensor.data_ptr(), output_tensor.numel() * sizeof(float));
        break;
    case 'd':
        std::memcpy(output_data, output_tensor.data_ptr(), output_tensor.numel() * sizeof(double));
        break;
    case 'i':
        std::memcpy(output_data, output_tensor.data_ptr(), output_tensor.numel() * sizeof(int));
        break;
    default:
        std::cerr << "unsupported output type (should be [d(ouble), f(loat), i(nt)])\n";
        return -1;
    }

    return 1;
}

// test usage
int main(int argc, const char *argv[])
{
    ArraySchema input = {(const long int[]){244, 244, 3, 1}, 4, 'f'};
    ArraySchema output = {(const long int[]){1, 1000}, 2, 'f'};

    TorchModel *model = new TorchModel("/home/dl/luc/FTB/demo/lib/resnet.pt", input, output, 0);

    float input_data[1][3][244][244] = {1};
    float output_data[1000][1];
    model->forward(input_data, output_data);
}