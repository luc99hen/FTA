This [demo](https://stackoverflow.com/questions/66192285/libtorch-works-with-g-but-fails-with-intel-compiler) is calling torch script model from fortran program.

## build steps
```bash
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=/path/to/libtorch ..  # downloaded from https://pytorch.org/
cmake --build . --config Release

cd bin/
./fortran_calls_ts.x
```