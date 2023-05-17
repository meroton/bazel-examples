#include <stdio.h>
#include "Library/Library.h"

int
main(int count, char* arguments[]) {
    hello_library();

    for (int i = 1; i < count; i++ ) {
        printf("%d: %s\n", i, arguments[i]);
    }
}
