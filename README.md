Tests for assorted rollsum implementations

The following rollsum implementations are tested, all theoretically using the same algorithm:
 - bup
 - rsroll
 - camlistore rollsum

The following compilers are necessary:
 - gcc
 - rustc (+ cargo)
 - go

Clone this repo, get the rollsum implementations and build a Docker image with the compilers:
```
$ git clone https://github.com/aidanhs/rollsum-tests.git && cd rollsum-tests
$ make dep
```
If you already have the implementations hanging around, feel free to symlink them.

Running tests:
```
$ docker run -it -v $(pwd):/work --rm rollsum-tests bash
# make testfiles # generate deterministic test files
[...]
# make preptest # build the assorted test programs
[...]
# make test # actually run tests
[...]
FILE     SIZE  BUP_FAIL  RSROLL_FAIL  CAMROLL_FAIL  BUP_TIME  RSROLL_TIME  CAMROLL_TIME
01.test  4.0K  0         0            0             0.00      0.00         0.00
02.test  4.0K  0         0            0             0.00      0.00         0.00
03.test  8.0K  0         0            1             0.01      0.00         0.00
04.test  64K   0         0            1             0.01      0.00         0.00
05.test  384K  0         0            1             0.01      0.00         0.00
06.test  1.7M  0         0            1             0.01      0.01         0.01
07.test  5.5M  0         0            1             0.01      0.02         0.04
08.test  16M   0         0            1             0.06      0.07         0.13
09.test  42M   0         0            1             0.14      0.16         0.32
10.test  96M   0         0            1             0.35      0.38         0.75
11.test  205M  0         0            1             0.74      0.79         1.59
12.test  411M  0         0            1             1.49      1.71         3.23
```
You can also limit the tests with `make TEST_FILES="test/01.test test/02.test" test`.

(yes, camlistore is failing the tests - https://github.com/camlistore/camlistore/issues/611)
