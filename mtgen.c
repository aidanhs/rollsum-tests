#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

#include "mt19937ar.c"

int main(int argc, char** argv) {
    if (argc != 3) {
        printf("mtgen <seed> <bytes>\n");
        return 1;
    }
    char *tail;
    long i = strtol(argv[1], &tail, 10);
    // C is stupid, complete validation is too hard
    if (errno == ERANGE || *tail != '\0'){
        printf("seed: invalid number or range error\n");
        errno = 0;
        return 1;
    }
    long num = strtol(argv[2], &tail, 10);
    // C is stupid, complete validation is too hard
    if (errno == ERANGE || *tail != '\0'){
        printf("bytes: invalid number or range error\n");
        errno = 0;
        return 1;
    }
    init_genrand(i);
    long val;
    unsigned char* cval;
    while (num >= 4) {
        val = genrand_int32();
        cval = (unsigned char*)&val;
        printf("%c%c%c%c", cval[0], cval[1], cval[2], cval[3]);
        num -= 4;
    }
    val = genrand_int32();
    cval = (unsigned char*)&val;
    while (num > 0) {
        printf("%c", cval[num]);
        num--;
    }
    return 0;
}
