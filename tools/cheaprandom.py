#!/usr/bin/python3
import random
import os

BLOCKSIZE = 4096
BLOCKBITS = BLOCKSIZE * 8

HELP_DESCRIPTION = """\
Create a file filled with cheap random numbers. The random numbers are
*not* sourced from /dev/urandom or getrandom in order to improve
performance. This tool is thus not suited for security critical
applications."""

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description=HELP_DESCRIPTION,
    )
    parser.add_argument(
        "megs",
        metavar="SIZE",
        help="Size of the file, in MiB",
        type=int,
    )
    parser.add_argument(
        "outfile",
        metavar="PATH",
        help="Path to output file",
    )

    args = parser.parse_args()

    megs = args.megs
    size = megs * (1024**2)
    outfile = args.outfile

    nblocks = (size + BLOCKSIZE - 1) // BLOCKSIZE
    size = nblocks*BLOCKSIZE

    with open(outfile, "wb") as f:
        os.posix_fallocate(f.fileno(), 0, size)
        for block in range(nblocks):
            data = random.getrandbits(BLOCKBITS).to_bytes(BLOCKSIZE, "little")
            assert f.write(data) == BLOCKSIZE
