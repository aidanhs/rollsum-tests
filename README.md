Tests for assorted rollsum implementations

The following rollsum implementations are tested, all theoretically using the same algorithm:
 - bup
 - rsroll
 - perkeep rollsum

The following compilers are used for the implementations, all within a Docker container:
 - clang
 - rustc (+ cargo)
 - go

Clone this repo, get the rollsum implementations and build a Docker image with the compilers (you can use Docker rather than podman by editing the Makefile):

```
$ git clone https://github.com/aidanhs/rollsum-tests.git && cd rollsum-tests && git submodule update --init --recursive
$ make dep
```
If you already have the implementations hanging around, feel free to symlink them.

Running tests:
```
$ podman run -it -v $(pwd):/work --tmpfs /tmp --rm rollsum-tests bash
# make testfiles # generate deterministic test files
[...]
# make preptest # build the assorted test programs
[...]
# make test # actually run tests
[...]
FILE     SIZE  BUP(err,cnt)    RSROLL(err,cnt)  PERKEEP(err,cnt)  IPFSRA(err,cnt)  IPFSBU(err,cnt)  IPFSSPL(err,cnt)
01.test  4.0K  0.02[0,1]       0.00[0,1]        0.00[0,1]         0.00[1,1]        0.00[1,1]        0.00[1,1]
02.test  4.0K  0.00[0,1]       0.00[0,1]        0.00[0,1]         0.00[1,1]        0.00[1,1]        0.00[1,1]
03.test  8.0K  0.00[0,2]       0.00[0,2]        0.00[0,2]         0.00[1,1]        0.00[1,1]        0.00[1,1]
04.test  64K   0.00[0,12]      0.00[0,12]       0.00[0,12]        0.00[1,1]        0.00[1,1]        0.00[1,8]
05.test  384K  0.00[0,46]      0.00[0,46]       0.00[0,46]        0.00[1,1]        0.00[1,2]        0.00[1,48]
06.test  1.7M  0.00[0,189]     0.00[0,189]      0.00[0,189]       0.01[1,6]        0.00[1,7]        0.00[1,206]
07.test  5.5M  0.02[0,712]     0.00[0,712]      0.02[0,712]       0.02[1,21]       0.00[1,26]       0.00[1,704]
08.test  16M   0.03[0,2011]    0.02[0,2011]     0.07[0,2011]      0.09[1,64]       0.02[1,65]       0.00[1,2048]
09.test  42M   0.08[0,5095]    0.06[0,5095]     0.16[0,5095]      0.25[1,155]      0.03[1,172]      0.01[1,5255]
10.test  96M   0.18[0,12261]   0.16[0,12261]    0.41[0,12261]     0.56[1,370]      0.07[1,400]      0.03[1,12208]
11.test  205M  0.36[0,26206]   0.35[0,26206]    0.88[0,26206]     1.18[1,799]      0.16[1,818]      0.07[1,26167]
12.test  411M  0.76[0,52108]   0.69[0,52108]    1.67[0,52108]     2.34[1,1611]     0.34[1,1672]     0.14[1,52488]
13.test  778M  1.43[0,99448]   1.31[0,99448]    3.34[0,99448]     4.74[1,3017]     0.67[1,3254]     0.31[1,99577]
14.test  1.4G  3.01[0,179862]  2.69[0,179862]   6.53[0,179862]    8.28[1,5506]     1.11[1,5768]     0.41[1,180151]
```

Each result like `time[err,cnt]`, shows `time` in ms, with `err` indicating whether the split result
matches bup exactly and `cnt` indicates how many splits there were.

You can also limit the tests with `make TEST_FILES="test/01.test test/02.test" test`.
