#!/usr/bin/env python3

"""A runner that executes a compiled `cc_binary`."""

import subprocess
import sys
from typing import List

from rules_python.python.runfiles import \
    runfiles  # Bazel's runfiles library, to find runtime dependencies.


def main(args: List[str]):
    r = runfiles.Create()
    # Workspace-relative path.
    program = r.Rlocation("example/Program")
    subprocess.run([program, "from", "python"]),


if __name__ == '__main__':
    main(sys.argv[1:])
