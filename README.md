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
$ podman run -it -v $(pwd):/work --rm rollsum-tests bash
# make testfiles # generate deterministic test files
[...]
# make preptest # build the assorted test programs
[...]
# make test # actually run tests
[...]
FILE     SIZE  BUP_FAIL  RSROLL_FAIL  PERKEEP_FAIL  BUP_TIME  RSROLL_TIME  PERKEEP_TIME
01.test  4.0K  0         0            0             0.01      0.00         0.00
02.test  4.0K  0         0            0             0.00      0.00         0.00
03.test  8.0K  0         0            0             0.00      0.00         0.00
04.test  64K   0         0            0             0.00      0.00         0.00
05.test  384K  0         0            0             0.00      0.00         0.00
06.test  1.7M  0         0            0             0.00      0.00         0.00
07.test  5.5M  0         0            0             0.01      0.02         0.02
08.test  16M   0         0            0             0.04      0.07         0.06
09.test  42M   0         0            0             0.09      0.18         0.19
10.test  96M   0         0            0             0.18      0.41         0.42
11.test  205M  0         0            0             0.38      0.90         0.93
12.test  411M  0         0            0             0.81      1.84         1.84
13.test  778M  0         0            0             1.57      3.40         3.49
14.test  1.4G  0         0            0             2.74      6.23         6.36
```
You can also limit the tests with `make TEST_FILES="test/01.test test/02.test" test`.
