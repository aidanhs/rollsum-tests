# Tests for assorted rollsum implementations

## Competitors

The following rollsum algorithms and implementations are tested:
 - 'bupsplit' - the rolling checksum implementation in bup, [apparently taken from rsync](https://github.com/bup/bup/blob/b49607d/DESIGN).
   Wikipedia has more historic information on rsync (apparently it's based on adler-32, itself modified from Fletcher's checksum -
   https://en.wikipedia.org/wiki/Rsync). This rollsum implementation targets average 8k chunk sizes (anything else is a deviation
   from 'true' bupsplit in my eyes, as opposed to other algorithms which are not prescriptive).
   - [bup](https://github.com/bup/bup) rollsum (C + Python)
   - [https://github.com/aidanhs/rsroll](https://github.com/aidanhs/rsroll) (Rust)
   - [perkeep](https://github.com/perkeep/perkeep) rollsum (Go)
   - [bita](https://github.com/oll3/bita) rollsum (Rust)
 - 'rabin' - the venerable 'Rabin Fingerprint', outlined on [Wikipedia](https://en.wikipedia.org/wiki/Rabin_fingerprint) and somewhat
   popular in filesystem chunking applications. It's not clear to me if [Rabin actually holds any advantage over rolling CRC](https://crypto.stackexchange.com/questions/2224/do-rabin-fingerprints-have-any-advantages-over-crc))
   - [IPFS chunking library](https://github.com/ipfs/go-ipfs-chunker/) (Go)
 - 'split' - not content-defined chunking at all! Fixed size blocks, interesting for comparison purposes
   - [IPFS chunking library](https://github.com/ipfs/go-ipfs-chunker/) (Go)
 - 'gear' - the predecessor to FastCDC (outlined in https://www.usenix.org/system/files/conference/atc16/atc16-paper-xia.pdf)
   - [https://github.com/aidanhs/rsroll](https://github.com/aidanhs/rsroll) (Rust)
 - 'buzhash' - outlined on [Wikipedia](https://en.wikipedia.org/wiki/Rolling_hash#Cyclic_polynomial), buzhash is a simple algorithm
   that uses a random number generator to generate a lookup table - you're probably unlikely to find implementations with matching
   results for that reason (Rabin just has a single polynomial)
   - [bita](https://github.com/oll3/bita) rollsum (Rust)
   - [IPFS chunking library](https://github.com/ipfs/go-ipfs-chunker/) (Go)
   - [libasuran](https://gitlab.com/asuran-rs/libasuran) rollsum (Rust)

Comments:
 - I partitioned out the 8k and 256k competitors in case the number of splits would make a material difference to perf - in
   practice it does make some, but not enough the change rankings (as you can see from the results)
 - currently these implementation benchmarking times *include* the initial load of the file - this is bad and they shouldn't,
   but is currently mitigated by doing `cat file > /dev/null` to get it into cache
 - the benchmark attempts to be semirealistic - given a file in cache, how long does it take to load it and determine the split
   points. In time I'll probably migrate this to exclude actually loading the file

# Prerequisites

You need Podman or Docker (if the latter, just change the command in the Makefile and it should work).

Clone this repo, get the rollsum implementations and build a Docker image with the dependencies:

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
- Standard deviation is only calculated for tests with >500 splits to try and give a rough judgement on the hash
  algorighm quality (intuitively I think random data should be a happy case for a hash).
- To save screen space, the common results from non-erroring lines are collapsed.

FILE     SIZE  BUP                         RSROBU             BITABU                      PERKEEP            RSROGE                      IPFSRA                      IPFSSPL                   RSROBU256                   RSROGE256                   BITABZ                      ASURANBZ                    IPFSRA256                   IPFSSPL256                IPFSBZ
01.test  4.0K  0.0[/,0c,-,6M]              0.0[",",",2M]      0.0[",",",2M]               0.0[",",",2M]      0.0[",",",3M]               0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[",",",2M]               0.0[",",",2M]               0.0[",",",2M]               0.0[X,1c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
02.test  4.0K  0.0[/,0c,-,7M]              0.0[",",",2M]      0.0[",",",2M]               0.0[",",",2M]      0.0[",",",2M]               0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[",",",2M]               0.0[",",",2M]               0.0[",",",2M]               0.0[X,1c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
03.test  8.0K  0.0[/,1c,-,7M]              0.0[",",",2M]      0.0[",",",2M]               0.0[",",",2M]      0.0[X,0c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,0c,-,2M]              0.0[X,0c,-,2M]              0.0[X,0c,-,2M]              0.0[X,1c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
04.test  64K   0.01[/,11c,-,7M]            0.0[",",",2M]      0.0[",",",2M]               0.0[",",",2M]      0.0[X,6c,-,2M]              0.0[X,10c,-,6M]             0.0[X,8c,-,6M]            0.0[X,0c,-,2M]              0.0[X,0c,-,2M]              0.0[X,0c,-,2M]              0.0[X,1c,-,2M]              0.0[X,1c,-,6M]              0.0[X,1c,-,6M]            0.0[X,1c,-,6M]
05.test  384K  0.0[/,45c,-,7M]             0.0[",",",3M]      0.0[",",",3M]               0.0[",",",2M]      0.0[X,52c,-,3M]             0.0[X,48c,-,8M]             0.0[X,48c,-,7M]           0.0[X,1c,-,3M]              0.0[X,1c,-,3M]              0.0[X,1c,-,3M]              0.0[X,1c,-,3M]              0.0[X,1c,-,8M]              0.0[X,2c,-,7M]            0.0[X,2c,-,7M]
06.test  1.7M  0.01[/,188c,-,8M]           0.0[",",",4M]      0.0[X,188c,-,5M]            0.0[",",",4M]      0.0[X,211c,-,4M]            0.01[X,203c,-,11M]          0.0[X,206c,-,9M]          0.0[X,8c,-,4M]              0.0[X,7c,-,4M]              0.01[X,7c,-,6M]             0.01[X,6c,-,5M]             0.0[X,6c,-,12M]             0.0[X,7c,-,9M]            0.0[X,7c,-,9M]
07.test  5.5M  0.01[/,711c,7478,12M]       0.0[",",",8M]      0.03[X,711c,7478,9M]        0.02[",",",8M]     0.0[X,729c,8435,8M]         0.04[X,680c,3405,19M]       0.0[X,704c,89,18M]        0.01[X,27c,-,8M]            0.0[X,32c,-,8M]             0.02[X,24c,-,10M]           0.03[X,21c,-,9M]            0.03[X,21c,-,18M]           0.0[X,22c,-,18M]          0.0[X,26c,-,18M]
08.test  16M   0.03[/,2010c,8554,22M]      0.02[",",",18M]    0.1[X,2012c,8554,19M]       0.06[",",",19M]    0.01[X,2178c,8358,19M]      0.11[X,2019c,3438,39M]      0.0[X,2048c,0,39M]        0.03[X,85c,-,19M]           0.02[X,57c,-,18M]           0.08[X,73c,-,21M]           0.09[X,49c,-,20M]           0.1[X,64c,-,39M]            0.0[X,64c,-,39M]          0.02[X,65c,-,39M]
09.test  42M   0.07[/,5094c,8506,47M]      0.07[",",",44M]    0.25[X,5104c,8506,45M]      0.17[",",",44M]    0.02[X,5549c,8232,43M]      0.26[X,5154c,3467,89M]      0.01[X,5255c,31,90M]      0.07[X,213c,-,43M]          0.04[X,160c,-,43M]          0.19[X,163c,-,48M]          0.24[X,135c,-,44M]          0.23[X,155c,-,90M]          0.0[X,165c,-,90M]         0.04[X,172c,-,90M]
10.test  96M   0.18[/,12260c,8176,102M]    0.16[",",",98M]    0.59[X,12265c,8176,99M]     0.39[",",",100M]   0.06[X,12566c,8644,98M]     0.6[X,11970c,3435,199M]     0.03[X,12208c,72,201M]    0.16[X,471c,-,98M]          0.11[X,410c,-,98M]          0.45[X,366c,-,103M]         0.57[X,297c,-,99M]          0.54[X,370c,-,199M]         0.02[X,382c,-,199M]       0.11[X,400c,-,199M]
11.test  205M  0.34[/,26205c,8239,211M]    0.32[",",",207M]   1.3[X,26211c,8239,208M]     0.82[",",",213M]   0.14[X,27406c,8446,207M]    1.3[X,25630c,3425,420M]     0.08[X,26167c,7,422M]     0.35[X,1011c,223003,207M]   0.23[X,803c,263320,207M]    0.96[X,836c,261952,211M]    1.19[X,639c,249044,208M]    1.15[X,799c,111378,418M]    0.03[X,818c,2618,419M]    0.19[X,818c,111677,417M]
12.test  411M  0.72[/,52107c,8292,416M]    0.67[",",",412M]   2.57[X,52088c,8292,414M]    1.69[",",",426M]   0.26[X,54428c,8554,412M]    2.57[X,51216c,3439,835M]    0.14[X,52488c,0,840M]     0.72[X,1981c,212794,412M]   0.47[X,1787c,242932,412M]   1.93[X,1637c,272110,418M]   2.38[X,1365c,231810,414M]   2.27[X,1611c,110133,831M]   0.07[X,1641c,4852,833M]   0.38[X,1672c,110754,831M]
13.test  778M  1.3[/,99447c,8185,784M]     1.26[",",",780M]   4.97[X,99454c,8185,782M]    3.21[",",",806M]   0.5[X,103607c,8485,780M]    5.15[X,97600c,3443,1578M]   0.2[X,99577c,13,1587M]    1.4[X,3680c,228807,780M]    0.92[X,3166c,264622,780M]   3.96[X,3111c,260256,786M]   4.94[X,2623c,233203,781M]   4.58[X,3017c,110748,1570M]  0.12[X,3112c,1101,1574M]  0.77[X,3254c,107475,1568M]
14.test  1.4G  2.42[/,179861c,8153,1414M]  2.26[",",",1410M]  9.28[X,179978c,8153,1412M]  5.87[",",",1456M]  1.01[X,188641c,8448,1410M]  9.66[X,176327c,3444,2850M]  0.46[X,180151c,19,2866M]  2.46[X,6726c,216579,1410M]  1.66[X,5821c,265289,1410M]  6.82[X,5679c,254793,1416M]  8.56[X,4498c,243249,1411M]  8.11[X,5506c,111157,2835M]  0.24[X,5630c,1088,2841M]  1.34[X,5768c,110212,2833M]
```

You can limit the test files with e.g. `make TEST_FILES="test/01.test test/02.test" test`.

# Results Commentary

 - Of the three identical implementations ('bupsplit'):
   - rsroll edges out bup by small but consistent amounts, potentially due to python overhead
   - perkeep and bita are slow by comparison
 - All of the IPFS implementations seem to be leaking memory pretty badly (~1x the amount being split)
 - IPFS split is a nice baseline to consider other implementations in the context of
 - Gear in rsroll and buzhash seem comparable and fluctuate which is the 'winner' based on time of day -
   I will be improving benchmarks in time to make them more consistent
   - given FastCDC is claimed to be significantly faster than gear, this is probably one to look at
 - some of the standard deviations are artificially reduced by having min and max chunk sizes - IPFS in
   particular is very aggressive with this (disabling those limits puts buzhash and rabin on a par with
   Bita buzhash) and it remains to be seen in future analyses how much this is crippling the chunking

# Misc

To regenerate sums:
```
for f in test/*.test; do ./test_rust rsroll-bup $f | sha1sum > $f.sum; done
```

Bugs found by this repo:
 - https://github.com/perkeep/perkeep/issues/611
 - https://gitlab.com/asuran-rs/libasuran/merge\_requests/2

TODO:
 - it's not useful to have splits before the window has been filled - fix it
 - partition out the set of tests into
   - 'correctness' (via patches to unify+compare implementations with each other)
   - 'quality' (via patches to remove chunk limits for standard deviation analysis, then using that to see how much the limits cause non-chunked splitting)
   - 'performance' (i.e. just running the implementations as-is)
 - have implementations load the data, mlock it and then do timing themselves
 - add the buzhash implementation from attic - https://github.com/jborg/attic/blob/master/attic/\_chunker.c
 - add https://github.com/nlfiedler/fastcdc-rs/blob/master/src/lib.rs
 - add librsync
 - have the benchmarks repeat the measurements 10 times (within the test programs themselves)
   - even better, actually do benchmarking properly - take inspiration from statistics, e.g. Go used by
     [go-ipfs-chunker](https://github.com/ipfs/go-ipfs-chunker/commit/79bdab24e1ecceaadf619ec33a56cadb9760e5c7),
     `cargo bench` or https://jsperf.com/
