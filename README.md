# Tests for assorted rollsum implementations

## Competitors

The following rollsum implementations are tested, all theoretically using the same algorithm:
 - bup (C + Python)
 - rsroll (Rust)
 - perkeep rollsum (Go)

These others are tested for the sake of curiosity after reading https://github.com/ipfs/go-ipfs-chunker/issues/18 (in Go):
 - go-ipfs-chunker rabin implementation (two variants, ~8k chunks and ~256k chunks)
 - go-ipfs-chunker split implementation (fixed size 8k chunks)
 - go-ipfs-chunker buzhash implementation (~256k chunks)
 - rsroll for 256k chunks

Comments:
 - using a constant chunk size in a rsroll seemed to help a little, so I didn't parameterise by argument (instead creating two
   programs). I didn't test the same would help for Go
 - I partitioned out the 8k and 256k competitors in case the number of splits would make a material difference to perf - in
   practice it does make some, but not enough the change rankings (as you can see from the results)
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

FILE     SIZE  BUP                    RSROLL                 PERKEEP               IPFSRA                 IPFSSPL                RSROLL256            IPFSRA256            IPFSSPL256           IPFSBU
01.test  4.0K  0.0[-,1l,7M]           0.0[-,1l,2M]           0.0[-,1l,2M]          0.0[X,1l,6M]           0.0[X,1l,6M]           0.0[-,1l,2M]         0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
02.test  4.0K  0.0[-,1l,6M]           0.0[-,1l,2M]           0.0[-,1l,2M]          0.0[X,1l,6M]           0.0[X,1l,6M]           0.0[-,1l,2M]         0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
03.test  8.0K  0.0[-,2l,7M]           0.0[-,2l,2M]           0.0[-,2l,2M]          0.0[X,1l,6M]           0.0[X,1l,6M]           0.0[X,1l,2M]         0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
04.test  64K   0.0[-,12l,7M]          0.0[-,12l,2M]          0.0[-,12l,2M]         0.0[X,10l,6M]          0.0[X,8l,6M]           0.0[X,1l,2M]         0.0[X,1l,6M]         0.0[X,1l,6M]         0.0[X,1l,6M]
05.test  384K  0.01[-,46l,7M]         0.0[-,46l,2M]          0.0[-,46l,2M]         0.0[X,48l,8M]          0.0[X,48l,7M]          0.0[X,2l,2M]         0.0[X,1l,8M]         0.0[X,2l,7M]         0.0[X,2l,7M]
06.test  1.7M  0.01[-,189l,8M]        0.0[-,189l,4M]         0.0[-,189l,4M]        0.01[X,203l,11M]       0.0[X,206l,9M]         0.0[X,9l,4M]         0.01[X,6l,12M]       0.0[X,7l,10M]        0.0[X,7l,10M]
07.test  5.5M  0.01[-,712l,12M]       0.0[-,712l,7M]         0.02[-,712l,8M]       0.04[X,680l,18M]       0.0[X,704l,18M]        0.01[X,28l,7M]       0.03[X,21l,18M]      0.0[X,22l,18M]       0.01[X,26l,18M]
08.test  16M   0.03[-,2011l,22M]      0.02[-,2011l,18M]      0.06[-,2011l,19M]     0.1[X,2019l,39M]       0.01[X,2048l,39M]      0.02[X,86l,18M]      0.08[X,64l,39M]      0.0[X,64l,39M]       0.0[X,65l,39M]
09.test  42M   0.07[-,5095l,47M]      0.06[-,5095l,43M]      0.14[-,5095l,44M]     0.25[X,5154l,90M]      0.01[X,5255l,90M]      0.07[X,214l,43M]     0.22[X,155l,90M]     0.0[X,165l,90M]      0.03[X,172l,90M]
10.test  96M   0.17[-,12261l,102M]    0.15[-,12261l,97M]     0.37[-,12261l,101M]   0.59[X,11970l,199M]    0.03[X,12208l,201M]    0.17[X,472l,97M]     0.53[X,370l,199M]    0.02[X,382l,199M]    0.06[X,400l,199M]
11.test  205M  0.34[-,26206l,211M]    0.31[-,26206l,206M]    0.82[-,26206l,213M]   1.29[X,25630l,420M]    0.05[X,26167l,422M]    0.36[X,1012l,206M]   1.11[X,799l,418M]    0.03[X,818l,419M]    0.16[X,818l,417M]
12.test  411M  0.69[-,52108l,416M]    0.63[-,52108l,412M]    1.62[-,52108l,426M]   2.55[X,51216l,835M]    0.11[X,52488l,840M]    0.72[X,1982l,412M]   2.2[X,1611l,831M]    0.05[X,1641l,833M]   0.33[X,1672l,831M]
13.test  778M  1.29[-,99448l,784M]    1.22[-,99448l,780M]    3.1[-,99448l,806M]    4.82[X,97600l,1578M]   0.21[X,99577l,1587M]   1.37[X,3681l,780M]   4.19[X,3017l,1570M]  0.15[X,3112l,1574M]  0.52[X,3254l,1568M]
14.test  1.4G  2.35[-,179862l,1414M]  2.21[-,179862l,1409M]  5.6[-,179862l,1458M]  8.79[X,176327l,2850M]  0.34[X,180151l,2865M]  2.49[X,6727l,1409M]  7.54[X,5506l,2835M]  0.21[X,5630l,2841M]  1.0[X,5768l,2832M]
```

You can limit the test files with e.g. `make TEST_FILES="test/01.test test/02.test" test`.

# Results Commentary

 - Of the three identical implementations ('bupsplit'):
   - rsroll edges out bup by small but consistent amounts
   - perkeep is slow by comparison
 - All of the IPFS implementations seem to be leaking memory pretty badly (~1x the amount being split)
 - IPFS split is a nice baseline to consider other implementations in the context of
 - Based on IPFS split, if buzhash is working it's pretty impressive!
