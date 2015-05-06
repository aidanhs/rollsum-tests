.PHONY: default testfiles preptest test

default: testfiles

mtgen: mtgen.c mt19937ar.c
	gcc -o mtgen -static -O3 mtgen.c

TEST_FILES = $(addsuffix .test,$(addprefix test/,01 02 03 04 05 06 07 08 09 10 11 12))
testfiles: mtgen $(TEST_FILES)

%.test:
	N=$$(basename $@ .test) && \
	  SEED=$$(echo "$$N*1000" | bc) && \
	  SIZE=$$(echo "$$N^8" | bc) && \
	  ./mtgen $$SEED $$SIZE > $@

BUP_LIB_DIR ?= ./bup/lib
RSROLL_DIR ?= ./rust-rollsum
export PYTHONPATH = $(BUP_LIB_DIR)
BUP_CMD = python2 -u test_bup.py
RSROLL_CMD = ./test_rollsum

preptest:
	rustc -O -L $(RSROLL_DIR)/target/release -L $(RSROLL_DIR)/target/release/deps test_rollsum.rs

test:
	( \
	    echo "FILE BUP_FAIL RUST-ROLLSUM_FAIL BUP_TIME RUST-ROLLSUM_TIME"; \
	    export TMPFILE=$$(mktemp); \
	    for f in $(TEST_FILES); do \
	        echo -n "$$f "; \
	        EXPECT=$$(cat $$f.sum); \
	        BUP_OUT="$$(time -f %U $(BUP_CMD) $$f 2>$$TMPFILE | sha1sum)"; \
	        BUP_TIME="$$(cat $$TMPFILE)"; \
	        RSROLL_OUT="$$(time -f %U $(RSROLL_CMD) $$f 2>$$TMPFILE | sha1sum)"; \
	        RSROLL_TIME="$$(cat $$TMPFILE)"; \
	        [ "$$BUP_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        [ "$$RSROLL_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        echo -n "$$BUP_TIME "; \
	        echo -n "$$RSROLL_TIME "; \
	        echo; \
	    done \
	) | column -t