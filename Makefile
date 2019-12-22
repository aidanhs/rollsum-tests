.PHONY: default dep testfiles preptest test

default: testfiles

mtgen: mtgen.c mt19937ar.c
	gcc -o mtgen -static -O3 mtgen.c

dep:
	podman build -t rollsum-tests .

TEST_FILES ?= $(addsuffix .test,$(addprefix test/,01 02 03 04 05 06 07 08 09 10 11 12 13 14))
testfiles: mtgen $(TEST_FILES)

%.test:
	N=$$(basename $@ .test) && \
	  SEED=$$(echo "$$N*1000" | bc) && \
	  SIZE=$$(echo "$$N^8" | bc) && \
	  ./mtgen $$SEED $$SIZE > $@

export PYTHONPATH = ./impl/bup/lib
BUP_CMD = python2 -u test_bup.py
RSROLL_CMD = ./test_rsroll
PERKEEP_CMD = ./test_perkeep

preptest:
	cd impl/bup && make
	cd impl/rsroll && cargo build --release
	rustc -C opt-level=3 -C lto -L ./rsroll/target/release -L ./impl/rsroll/target/release/deps test_rsroll.rs
	# golang "internal modules" and "import path checking" biting us here
	export GOPATH=$$(mktemp -d) && mkdir -p $$GOPATH/src/rollsum && cp impl/perkeep/internal/rollsum/rollsum.go $$GOPATH/src/rollsum/ && sed -i 's#// import.*##g' $$GOPATH/src/rollsum/rollsum.go && go build test_perkeep.go

test:
	( \
	    echo "FILE SIZE BUP_FAIL RSROLL_FAIL PERKEEP_FAIL BUP_TIME RSROLL_TIME PERKEEP_TIME"; \
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
	        PERKEEP_OUT="$$(/usr/bin/time -f %U $(PERKEEP_CMD) $$f 2>$$TMPFILE | sha1sum)"; \
	        PERKEEP_TIME="$$(cat $$TMPFILE)"; \
	        [ "$$BUP_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        [ "$$RSROLL_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        [ "$$PERKEEP_OUT" = "$$EXPECT" ]; echo -n "$$? "; \
	        echo -n "$$BUP_TIME "; \
	        echo -n "$$RSROLL_TIME "; \
	        echo -n "$$PERKEEP_TIME "; \
	        echo; \
	    done \
	) | column -t
