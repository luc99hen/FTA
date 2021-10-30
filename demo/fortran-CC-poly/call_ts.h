#pragma once

#ifndef CALL_TS_API
#include "call_ts_export.h"
#define CALL_TS_API CALL_TS_EXPORT
#endif

// __cplusplus is only defined in cpp environment
// it is used for `.h` file generaization in `.c` file and `.cpp` file
// https://www.cnblogs.com/Braveliu/p/12219521.html
#ifdef __cplusplus
extern "C"
{
#endif

    CALL_TS_API
    int resnet_call(float input[2][2]);

#ifdef __cplusplus
}
#endif