# %% check the environment
import torch
print(torch.__version__)

# %% a basic PyTorch Module
class MyCell(torch.nn.Module):
    def __init__(self):
        super(MyCell, self).__init__()
        self.linear = torch.nn.Linear(4, 4)
    
    def forward(self, x, h):
        new_h = torch.tanh(self.linear(x) + h)
        return new_h, new_h

my_cell = MyCell()
x = torch.rand(3, 4)
h = torch.rand(3, 4)

traced_cell = torch.jit.trace(my_cell, (x, h))
print(traced_cell)
traced_cell(x, h)

# %%  convert a pytorch model to torch script and serialize it to a file
import torch
import torchvision

# resnet model instance
model = torchvision.models.resnet18()
# an example input 
example = torch.rand(1, 3, 224, 224)
# use torch.jit.trace to generate a script module 
trace_script_module = torch.jit.trace(model, example)
trace_script_module.save("traced_resnet_modle.pt")
