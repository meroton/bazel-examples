#!/usr/bin/env python3

import sys
from typing import List


def main(args: List[str]):
    prog = sys.argv[0]
    print(prog, args)


if __name__ == '__main__':
    main(sys.argv[1:])
