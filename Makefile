.PHONY: default dep testfiles preptest test

default: testfiles

mtgen: mtgen.c mt19937ar.c
	gcc -o mtgen -static -O3 mtgen.c

dep:
	[ -d bup ] || (git clone https://github.com/bup/bup.git && cd bup && git checkout 0.27)
	[ -d rsroll ] || (git clone https://github.com/aidanhs/rsroll.git && cd rsroll && git checkout 0.1.0)
	[ -d camlistore ] || (git clone https://github.com/camlistore/camlistore.git && cd camlistore && git checkout 0.8)
	docker build -t rollsum-tests .

TEST_FILES ?= $(addsuffix .test,$(addprefix test/,01 02 03 04 05 06 07 08 09 10 11 12))
testfiles: mtgen $(TEST_FILES)

%.test:
	N=$$(basename $@ .test) && \
	  SEED=$$(echo "$$N*1000" | bc) && \
	  SIZE=$$(echo "$$N^8" | bc) && \
	  ./mtgen $$SEED $$SIZE > $@

export PYTHONPATH = ./bup/lib
BUP_CMD = python2 -u test_bup.py
RSROLL_CMD = ./test_rsroll
CAMROLL_CMD = ./test_camroll

preptest:
	cd bup && make
	cd rsroll && cargo build --release
	rustc -O -L ./rsroll/target/release -L ./rsroll/target/release/deps test_rsroll.rs
	go build test_camroll.go

test:
	( \
	    echo "FILE SIZE BUP_FAIL RSROLL_FAIL CAMROLL_FAIL BUP_TIME RSROLL_TIME CAMROLL_TIME"; \
	    export TMPFILE=$$(mktemp); \
	    for f in $(TEST_FILES); do \
	        if [ ! -f $$f -o ! -f $$f.sum ]; then echo "INVALID FILE $$f" >&2; exit 1; fi; \
	        echo -n "$$(basename $$f) $$(du -h $$f | cut -f1) "; \
	        EXPECT=$$(cat $$f.sum); \
	        cat $$f > /dev/null; \
	        BUP_OUT="$$(/usr/bin/time -f %U $(BUP_CMD) $$f 2>$$TMPFILE | sha1sum)"; \
	        BUP_TIME="$$(cat $$TMPFILE)"; \
	        RSROLL_OUT="$$(/usr/bin/time -f %U $(RSROLL_CMD) $$f 2>$$TMPFILE | sha1sum)"; \
	        RSROLL_TIME="$$(cat $$TMPFILE)"; \
	        CAMROLL_OUT="$$(/usr/bin/time -f %U $(CAMROLL_CMD) $$f 2>$$TMPFILE | sha1sum)"; \
	        CAMROLL_TIME="$$(cat $$TMPFILE)"; \
	        [ "$$BUP_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        [ "$$RSROLL_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        [ "$$CAMROLL_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        echo -n "$$BUP_TIME "; \
	        echo -n "$$RSROLL_TIME "; \
	        echo -n "$$CAMROLL_TIME "; \
	        echo; \
	    done \
	) | column -t
