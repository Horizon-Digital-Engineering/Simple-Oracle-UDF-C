#include <oci.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_INPUT_LENGTH 4000
#define ERR_NULL_INPUT 20000
#define ERR_TOO_LONG 20001

static void raise_error(OCIExtProcContext *ctx, char **output, short *out_ind, sb4 errcode, const char *msg) {
    *output = NULL;
    *out_ind = -1;
    OCIExtProcRaiseExcpWithMsg(ctx, errcode, (OraText *)msg, (ub4)strlen(msg));
}

void string_udf(OCIExtProcContext *ctx, char *input, short *out_ind, char **output) {
    OCIEnv *env = NULL;
    OCIError *err = NULL;
    OCISvcCtx *svc = NULL;

    *out_ind = 0;

    if (OCIExtProcGetEnv(ctx, &env, &svc, &err) != OCI_SUCCESS) {
        raise_error(ctx, output, out_ind, 20002, "Failed to initialize OCI environment");
        return;
    }

    if (input == NULL) {
        raise_error(ctx, output, out_ind, ERR_NULL_INPUT, "Input string is NULL");
        return;
    }

    size_t len = strlen(input);
    if (len > MAX_INPUT_LENGTH) {
        raise_error(ctx, output, out_ind, ERR_TOO_LONG, "Input string exceeds maximum length");
        return;
    }

    *output = (char *)OCIExtProcAllocCallMemory(ctx, (len + 1) * sizeof(char));
    if (*output == NULL) {
        raise_error(ctx, output, out_ind, 20003, "Failed to allocate memory for output");
        return;
    }

    memcpy(*output, input, len + 1);
}
