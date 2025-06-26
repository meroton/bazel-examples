#!/usr/bin/env python3

"""A runner that executes a compiled `cc_binary`."""

import subprocess
import sys
from typing import List

# Bazel's runfiles library, to find runtime dependencies.
from python.runfiles import Runfiles


def main(args: List[str]):
    r = Runfiles.Create()
    # Workspace-relative path.
    program = r.Rlocation("example/Program")
    subprocess.run([program, "from", "python"]),


if __name__ == '__main__':
    main(sys.argv[1:])
