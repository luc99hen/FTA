This [demo](https://pytorch.org/tutorials/advanced/cpp_export.html) loads a TorchScript Model in C++ and runs it in CUDA environment.

## build steps
```bash
# prequisit: a torch script module has been created

mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=/path/to/libtorch ..  # downloaded from https://pytorch.org/
cmake --build . --config Release
```