# Tests for assorted rollsum implementations

## Competitors

The following rollsum implementations are tested, all theoretically using the same algorithm:
 - bup (C + Python)
 - rsroll (Rust)
 - perkeep rollsum (Go)

These others are tested for the sake of curiosity after reading https://github.com/ipfs/go-ipfs-chunker/issues/18 (which is in Go):
 - go-ipfs-chunker rabin implementation (two variants, ~8k chunks and ~256k chunks)
 - go-ipfs-chunker split implementation (fixed size 8k chunks)
 - go-ipfs-chunker buzhash implementation (~256k chunks)
 - rsroll for 256k chunks

Comments:
 - using a single chunk size in a rsroll seemed to help a little, so I didn't parameterise it. I didn't test if would help for Go
 - I partitioned out the 8k and 256k competitors in case this number of results would make a difference - in practice it does make
   some, but not enough the change rankings (as you can see from the results)
 - currently these implementation benchmarking times *include* the initial load of the file - this is bad and they shouldn't

# Prerequisites

You need Podman or Docker (if the latter, just change the command in the Makefile and it should work).

Clone this repo, get the rollsum implementations and build a Docker image with the compilers:

```
$ git clone https://github.com/aidanhs/rollsum-tests.git && cd rollsum-tests && git submodule update --init --recursive
$ make dep # create an image for the container
```

# Running Tests

Jump into the container to and set up the test environment.

NOTE: all the implementations load the test file for a run fully into RAM before starting work. The test files are all
below 1.5GB.

```
$ podman run -it -v $(pwd):/work --tmpfs /tmp --rm rollsum-tests bash
# make testfiles # generate deterministic test files
[...]
# make preptest # build the assorted test programs
[...]
```

Finally:

```
# make test # actually run tests
[...]
KEY
Each cell is `time[err,count]`. `time` is in ms, `err` indicates whether the split result failed to
match bup exactly and `count` indicates how many splits there were.

BUP             RSROLL          PERKEEP        IPFSRA         IPFSSPL         RSROLL256     IPFSRA256     IPFSSPL256    IPFSBU
0.0[0,1]        0.0[0,1]        0.0[0,1]       0.0[1,1]       0.0[1,1]        0.0[0,1]      0.0[1,1]      0.0[1,1]      0.0[1,1]
0.0[0,1]        0.0[0,1]        0.0[0,1]       0.0[1,1]       0.0[1,1]        0.0[0,1]      0.0[1,1]      0.0[1,1]      0.0[1,1]
0.0[0,2]        0.0[0,2]        0.0[0,2]       0.0[1,1]       0.0[1,1]        0.0[1,1]      0.0[1,1]      0.0[1,1]      0.0[1,1]
0.0[0,12]       0.0[0,12]       0.0[0,12]      0.0[1,10]      0.0[1,8]        0.0[1,1]      0.0[1,1]      0.0[1,1]      0.0[1,1]
0.01[0,46]      0.0[0,46]       0.0[0,46]      0.0[1,48]      0.0[1,48]       0.0[1,2]      0.0[1,1]      0.0[1,2]      0.0[1,2]
0.0[0,189]      0.0[0,189]      0.0[0,189]     0.01[1,203]    0.0[1,206]      0.0[1,9]      0.01[1,6]     0.0[1,7]      0.0[1,7]
0.01[0,712]     0.0[0,712]      0.02[0,712]    0.04[1,680]    0.0[1,704]      0.01[1,28]    0.03[1,21]    0.0[1,22]     0.0[1,26]
0.03[0,2011]    0.02[0,2011]    0.06[0,2011]   0.1[1,2019]    0.01[1,2048]    0.03[1,86]    0.08[1,64]    0.0[1,64]     0.0[1,65]
0.07[0,5095]    0.06[0,5095]    0.17[0,5095]   0.26[1,5154]   0.02[1,5255]    0.07[1,214]   0.23[1,155]   0.0[1,165]    0.03[1,172]
0.16[0,12261]   0.14[0,12261]   0.37[0,12261]  0.61[1,11970]  0.03[1,12208]   0.17[1,472]   0.51[1,370]   0.01[1,382]   0.07[1,400]
0.34[0,26206]   0.32[0,26206]   0.81[0,26206]  1.31[1,25630]  0.06[1,26167]   0.37[1,1012]  1.12[1,799]   0.03[1,818]   0.16[1,818]
0.73[0,52108]   0.64[0,52108]   1.64[0,52108]  2.62[1,51216]  0.14[1,52488]   0.73[1,1982]  2.19[1,1611]  0.03[1,1641]  0.29[1,1672]
1.31[0,99448]   1.21[0,99448]   3.11[0,99448]  4.82[1,97600]  0.21[1,99577]   1.37[1,3681]  4.16[1,3017]  0.1[1,3112]   0.57[1,3254]
2.36[0,179862]  2.23[0,179862]  5.6[0,179862]  8.9[1,176327]  0.38[1,180151]  2.49[1,6727]  7.82[1,5506]  0.23[1,5630]  1.01[1,5768]
```

You can limit the test files with e.g. `make TEST_FILES="test/01.test test/02.test" test`.
