#!/usr/bin/env python3

"""Parse multiple `.json` files and generate a header file with defines for each attribute."""

import sys
import argparse
import json

from typing import Dict, List


def main(program, args: List[str]):
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', help="Output file", required=True)
    parser.add_argument('--base', help="Base config file", required=True)
    parser.add_argument('--literal', help="Literal text to add.")
    parser.add_argument('inputs', help="input files", nargs='+')

    ns = parser.parse_args(args)
    base = ns.base
    inputs = ns.inputs
    output = ns.output
    literal = ns.literal

    inputs.append(base)

    contents: List[Dict] = [{}] * len(inputs)
    for i, input in enumerate(inputs):
        with open(input, 'r') as f:
            content = json.load(f)
            contents[i] = content

    defines = {
        k: v
        for d in contents
        for k, v in d.items()
    }
    buffer = [""] * sum([len(d) for d in contents])
    for i, (k, v) in enumerate(defines.items()):
        # NB: This example has no quoting or value handling.
        buffer[i] = f"#define {k} {v}\n"

    with open(output, 'w') as f:
        f.write(f"/* Generated by {program} {literal} */\n")
        f.writelines(buffer)


if __name__ == '__main__':
    main(sys.argv[0], sys.argv[1:])
