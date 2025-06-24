#!/usr/bin/env python3

"""A runner that executes a compiled `cc_binary`."""

import subprocess
import sys
from typing import List

from rules_python.python.runfiles import \
    runfiles  # Bazel's runfiles library, to find runtime dependencies.


def main(runfile: str, args: List[str]):
    breakpoint()  # You can set breakpoints for `pdb` in the source file.
    #
    # `bazel run --run_under pdb //config:Runner` opens the launcher script in pdb,
    # but that calls `subprocess.Call` on the real program,
    # which disconnects the debugger.
    print("> run.main", runfile, args)

    # Workspace-relative path.
    lookup = "example/" + runfile

    r = runfiles.Create()
    print("lookup:", lookup)  # DEBUG
    found = r.Rlocation(lookup)
    print("found:", found)  # DEBUG

    if found:
        print("Found the json file, we can now proceed to do something!")
    else:
        print("Cannot find the file. Exiting")
        sys.exit(1)


if __name__ == '__main__':
    if len(sys.argv) < 1:
        print(sys.stderr, "Requires an argument for the payload, to find it in runfiles.")
        exit(1)

    runfile = sys.argv[1]
    # Need some mangling to help with the example.
    # As we only get the textual label,
    # this converts it to a file path, we can look for that (in vain).
    if runfile.startswith(":"):
        runfile = runfile.replace(":", "config/")

    main(runfile, sys.argv[2:])
