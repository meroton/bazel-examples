#include <stdio.h>

#include "Library/Library.h"
#include "Parameters/Parameters.h"

void
hello_library() {
    printf("Hello: Meroton %s%%\n", STRING(MER_PERCENT));
}
