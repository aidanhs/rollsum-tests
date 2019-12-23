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
$ make container # create an image for the container
```

# Running Tests

Jump into the container to and set up the test environment.

NOTE: all the implementations load the test file for a run fully into RAM before starting work. The test files are all
below 1.5GB.

```
$ podman run -it -v $(pwd):/work --tmpfs /tmp --rm rollsum-tests bash
# make testfiles # generate deterministic test files
[...]
# make rebuilddep # wipe and build all the dependencies
# make preptest # build the assorted test programs
[...]
```

Finally:

```
# make test # actually run tests
[...]
HOW TO READ THE RESULTS
- Each cell is `time[err,count,pstdev,mem]`. `time` is in seconds, `err` indicates whether the split result failed
  to match bup exactly, `count` indicates how many splits there were, `pstdev` indicates the standard devision of the
  split sizes and `mem` indicates max memory in MB.
- Standard deviation is only calculated for tests with >1000 splits to try and give a rough judgement on the hash
  algorighm quality (intuitively I think random data should be a happy case for a hash).
- To save screen space, the common results from non-erroring lines are collapsed.

FILE     SIZE  BUP                         RSROBU             PERKEEP           RSROGE                      IPFSRA                      IPFSSPL                   RSROBU256                   RSROGE256                   IPFSRA256                   IPFSSPL256                IPFSBZ
01.test  4.0K  0.0[/,0c,-,6M]              0.0[",",",2M]      0.0[",",",2M]     0.0[",",",2M]               0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[",",",2M]               0.0[",",",2M]               0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
02.test  4.0K  0.0[/,0c,-,7M]              0.0[",",",2M]      0.0[",",",2M]     0.0[",",",2M]               0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[",",",2M]               0.0[",",",2M]               0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
03.test  8.0K  0.0[/,1c,-,6M]              0.0[",",",2M]      0.0[",",",2M]     0.0[X,0c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,0c,-,2M]              0.0[X,0c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
04.test  64K   0.0[/,11c,-,7M]             0.0[",",",2M]      0.0[",",",2M]     0.0[X,6c,-,2M]              0.0[X,10c,-,6M]             0.0[X,8c,-,6M]            0.0[X,0c,-,2M]              0.0[X,0c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
05.test  384K  0.01[/,45c,-,7M]            0.0[",",",2M]      0.0[",",",2M]     0.0[X,52c,-,2M]             0.0[X,48c,-,7M]             0.0[X,48c,-,7M]           0.0[X,1c,-,2M]              0.0[X,1c,-,2M]              0.0[X,1c,-,7M]              0.0[X,2c,-,7M]            0.0[X,2c,-,7M]
06.test  1.7M  0.01[/,188c,-,8M]           0.0[",",",4M]      0.0[",",",3M]     0.0[X,211c,-,4M]            0.0[X,203c,-,11M]           0.0[X,206c,-,9M]          0.0[X,8c,-,4M]              0.0[X,7c,-,4M]              0.0[X,6c,-,12M]             0.0[X,7c,-,9M]            0.0[X,7c,-,10M]
07.test  5.5M  0.01[/,711c,-,12M]          0.01[",",",7M]     0.02[",",",8M]    0.0[X,729c,-,7M]            0.04[X,680c,-,18M]          0.0[X,704c,-,18M]         0.01[X,27c,-,7M]            0.0[X,32c,-,7M]             0.03[X,21c,-,18M]           0.0[X,22c,-,18M]          0.01[X,26c,-,18M]
08.test  16M   0.03[/,2010c,8554,22M]      0.03[",",",18M]    0.06[",",",19M]   0.02[X,2178c,8358,18M]      0.11[X,2019c,3438,39M]      0.0[X,2048c,0,39M]        0.02[X,85c,-,18M]           0.01[X,57c,-,18M]           0.08[X,64c,-,39M]           0.0[X,64c,-,39M]          0.01[X,65c,-,39M]
09.test  42M   0.06[/,5094c,8506,47M]      0.07[",",",43M]    0.17[",",",44M]   0.05[X,5549c,8232,43M]      0.26[X,5154c,3467,90M]      0.0[X,5255c,31,90M]       0.06[X,213c,-,43M]          0.02[X,160c,-,43M]          0.23[X,155c,-,90M]          0.0[X,165c,-,90M]         0.04[X,172c,-,90M]
10.test  96M   0.2[/,12260c,8176,102M]     0.16[",",",97M]    0.4[",",",100M]   0.12[X,12566c,8644,97M]     0.68[X,11970c,3435,199M]    0.03[X,12208c,72,201M]    0.18[X,471c,-,97M]          0.06[X,410c,-,97M]          0.51[X,370c,-,199M]         0.0[X,382c,-,199M]        0.08[X,400c,-,199M]
11.test  205M  0.34[/,26205c,8239,211M]    0.36[",",",206M]   0.84[",",",213M]  0.26[X,27406c,8446,206M]    1.29[X,25630c,3425,420M]    0.06[X,26167c,7,422M]     0.34[X,1011c,223003,206M]   0.11[X,803c,-,206M]         1.09[X,799c,-,418M]         0.05[X,818c,-,419M]       0.2[X,818c,-,417M]
12.test  411M  0.69[/,52107c,8292,416M]    0.7[",",",412M]    1.64[",",",426M]  0.49[X,54428c,8554,412M]    2.58[X,51216c,3439,835M]    0.11[X,52488c,0,840M]     0.69[X,1981c,212794,412M]   0.24[X,1787c,242932,412M]   2.2[X,1611c,110133,831M]    0.06[X,1641c,4852,833M]   0.41[X,1672c,110754,831M]
13.test  778M  1.33[/,99447c,8185,784M]    1.39[",",",780M]   3.22[",",",806M]  0.93[X,103607c,8485,780M]   4.88[X,97600c,3443,1578M]   0.24[X,99577c,13,1587M]   1.32[X,3680c,228807,780M]   0.45[X,3166c,264622,780M]   4.2[X,3017c,110748,1570M]   0.12[X,3112c,1101,1574M]  0.68[X,3254c,107475,1568M]
14.test  1.4G  2.35[/,179861c,8153,1414M]  2.48[",",",1409M]  5.6[",",",1456M]  1.67[X,188641c,8448,1409M]  8.83[X,176327c,3444,2850M]  0.39[X,180151c,19,2865M]  2.39[X,6726c,216579,1409M]  0.83[X,5821c,265289,1409M]  7.59[X,5506c,111157,2835M]  0.21[X,5630c,1088,2841M]  1.29[X,5768c,110212,2832M]
```

You can limit the test files with e.g. `make TEST_FILES="test/01.test test/02.test" test`.

# Results Commentary

 - Of the three identical implementations ('bupsplit'):
   - rsroll edges out bup by small but consistent amounts, potentially due to python overhead
   - perkeep is slow by comparison
 - All of the IPFS implementations seem to be leaking memory pretty badly (~1x the amount being split)
 - IPFS split is a nice baseline to consider other implementations in the context of
 - Based on IPFS split, if buzhash is working it's pretty impressive!

# Misc

To regenerate sums:
```
for f in test/*.test; do ./test_rust rsroll-bup $f | sha1sum > $f.sum; done
```

Bugs found by this repo:
 - https://github.com/perkeep/perkeep/issues/611
 - https://gitlab.com/asuran-rs/libasuran/merge_requests/2
