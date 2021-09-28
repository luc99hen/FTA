#include "call_ts.h"

#include <torch/script.h>
#include <iostream>
#include <memory>

int resnet_call(float input[1][3][224][224])
{
    torch::jit::script::Module module;
    try
    {
        module = torch::jit::load("./resnet.pt");
    }
    catch (const c10::Error &e)
    {
        std::cerr << "error loading the model\n";
        return -1;
    }

    // Create a vector of inputs.
    std::vector<torch::jit::IValue> inputs;
    inputs.push_back(torch::from_blob(input, {1, 3, 224, 224}).to(at::kCUDA));

    // use GPU
    module.to(at::kCUDA);

    // Execute the model and turn its output into a tensor.
    at::Tensor output = module.forward(inputs).toTensor();
    std::cout << output.slice(/*dim=*/1, /*start=*/0, /*end=*/5) << '\n';

    std::cout << "ok\n";

    return 1;
}