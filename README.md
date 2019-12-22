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
Each cell is `time[err,count,mem]`. `time` is in seconds, `err` indicates whether the split result failed to
match bup exactly, `count` indicates how many splits there were, mem indicates max memory in MB.

BUP                    RSROLL                PERKEEP                IPFSRA                 IPFSSPL                RSROLL256           IPFSRA256            IPFSSPL256           IPFSBU
0.0[-,1l,7M]           0.0[-,1l,2M]          0.0[-,1l,2M]           0.0[X,1l,6M]           0.0[X,1l,6M]           0.0[-,1l,2M]        0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
0.0[-,1l,7M]           0.0[-,1l,2M]          0.0[-,1l,2M]           0.0[X,1l,6M]           0.0[X,1l,6M]           0.0[-,1l,2M]        0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
0.0[-,2l,7M]           0.0[-,2l,2M]          0.0[-,2l,2M]           0.0[X,1l,6M]           0.0[X,1l,6M]           0.0[X,1l,2M]        0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
0.0[-,12l,6M]          0.0[-,12l,2M]         0.0[-,12l,2M]          0.0[X,10l,6M]          0.0[X,8l,6M]           0.0[X,1l,2M]        0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
0.01[-,46l,7M]         0.0[-,46l,2M]         0.0[-,46l,2M]          0.0[X,48l,7M]          0.0[X,48l,7M]          0.0[X,2l,2M]        0.0[X,1l,7M]         0.0[X,2l,7M]         0.0[X,2l,7M]
0.0[-,189l,8M]         0.0[-,189l,4M]        0.0[-,189l,4M]         0.01[X,203l,11M]       0.0[X,206l,9M]         0.0[X,9l,3M]        0.01[X,6l,12M]       0.0[X,7l,9M]         0.0[X,7l,10M]
0.01[-,712l,12M]       0.0[-,712l,7M]        0.02[-,712l,8M]        0.03[X,680l,18M]       0.0[X,704l,18M]        0.01[X,28l,7M]      0.03[X,21l,18M]      0.0[X,22l,18M]       0.0[X,26l,18M]
0.03[-,2011l,22M]      0.02[-,2011l,18M]     0.06[-,2011l,19M]      0.1[X,2019l,39M]       0.0[X,2048l,39M]       0.03[X,86l,18M]     0.09[X,64l,39M]      0.0[X,64l,39M]       0.01[X,65l,39M]
0.07[-,5095l,47M]      0.07[-,5095l,43M]     0.18[-,5095l,44M]      0.26[X,5154l,90M]      0.01[X,5255l,90M]      0.07[X,214l,43M]    0.23[X,155l,90M]     0.01[X,165l,90M]     0.04[X,172l,90M]
0.17[-,12261l,102M]    0.16[-,12261l,97M]    0.41[-,12261l,101M]    0.61[X,11970l,199M]    0.02[X,12208l,201M]    0.17[X,472l,97M]    0.51[X,370l,199M]    0.01[X,382l,199M]    0.06[X,400l,199M]
0.34[-,26206l,211M]    0.31[-,26206l,206M]   0.8[-,26206l,213M]     1.29[X,25630l,420M]    0.04[X,26167l,422M]    0.36[X,1012l,206M]  1.11[X,799l,418M]    0.03[X,818l,419M]    0.14[X,818l,417M]
0.69[-,52108l,416M]    0.64[-,52108l,412M]   1.64[-,52108l,426M]    2.56[X,51216l,836M]    0.11[X,52488l,840M]    0.72[X,1982l,412M]  2.21[X,1611l,831M]   0.06[X,1641l,833M]   0.32[X,1672l,831M]
1.31[-,99448l,784M]    1.26[-,99448l,780M]   3.13[-,99448l,807M]    4.91[X,97600l,1578M]   0.25[X,99577l,1587M]   1.37[X,3681l,780M]  4.34[X,3017l,1570M]  0.11[X,3112l,1574M]  0.6[X,3254l,1568M]
2.59[-,179862l,1414M]  2.2[-,179862l,1409M]  5.62[-,179862l,1458M]  9.37[X,176327l,2850M]  0.45[X,180151l,2866M]  2.5[X,6727l,1409M]  7.73[X,5506l,2835M]  0.21[X,5630l,2841M]  1.03[X,5768l,2831M]
```

You can limit the test files with e.g. `make TEST_FILES="test/01.test test/02.test" test`.
