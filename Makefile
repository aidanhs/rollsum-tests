.PHONY: default testfiles

default: testfiles

mtgen: mtgen.c mt19937ar.c
	gcc -o mtgen -static -O3 mtgen.c

testfiles: mtgen 1.test 2.test 3.test 4.test 5.test 6.test 7.test 8.test 9.test 10.test

%.test:
	N=$$(basename $@ .test) && \
	  SEED=$$(echo "$$N*1000" | bc) && \
	  SIZE=$$(echo "$$N^8" | bc) && \
	  ./mtgen $$SEED $$SIZE > $@

BUP_LIB_DIR ?= ./bup/lib

test:
	PYTHONPATH=$(BUP_LIB_DIR) python2 test_bup.py 4.test
