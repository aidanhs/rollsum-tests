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
# These aim for ~8k chunksize
BUP_CMD = python2 -u test_bup.py
RSROLL_CMD = ./test_rsroll
PERKEEP_CMD = ./test_perkeep
IPFSRA_CMD = ./test_ipfsra 8192
IPFSSPL_CMD = ./test_ipfsspl 8192
# These aim for ~256k chunksize
RSROLL256_CMD = ./test_rsroll256
IPFSRA256_CMD = ./test_ipfsra $$((256*1024))
IPFSSPL256_CMD = ./test_ipfsspl $$((256*1024))
IPFSBU_CMD = ./test_ipfsbu

preptest:
	cd impl/bup && make
	cd impl/rsroll && cargo build --release
	rustc -C opt-level=3 -C lto -L ./rsroll/target/release -L ./impl/rsroll/target/release/deps test_rsroll.rs
	rustc -C opt-level=3 -C lto -L ./rsroll/target/release -L ./impl/rsroll/target/release/deps test_rsroll256.rs
	# golang "internal modules" and "import path checking" biting us here
	export GOPATH=$$(mktemp -d) && \
	  mkdir -p $$GOPATH/src/rollsum && \
	  cp impl/perkeep/internal/rollsum/rollsum.go $$GOPATH/src/rollsum/ && \
	  sed -i 's#// import.*##g' $$GOPATH/src/rollsum/rollsum.go && \
	  go build test_perkeep.go
	export GOPATH=$$(mktemp -d) && \
	  go get github.com/ipfs/go-ipfs-chunker && \
	  go build test_ipfsra.go
	export GOPATH=$$(mktemp -d) && \
	  go get github.com/ipfs/go-ipfs-chunker && \
	  go build test_ipfsspl.go
	export GOPATH=$$(mktemp -d) && \
	  go get github.com/ipfs/go-ipfs-chunker && \
	  go build test_ipfsbu.go

test:
	( \
	    echo "FILE SIZE BUP(err,cnt) RSROLL(err,cnt) PERKEEP(err,cnt) IPFSRA(err,cnt) IPFSSPL(err,cnt) RSROLL256(err,cnt) IPFSRA256(err,cnt) IPFSSPL256(err,cnt) IPFSBU(err,cnt)"; \
	    export OUT_TMPFILE=$$(mktemp); \
	    for f in $(TEST_FILES); do \
	        if [ ! -f $$f -o ! -f $$f.sum ]; then echo "INVALID FILE $$f" >&2; exit 1; fi; \
	        echo -n "$$(basename $$f) $$(du -h $$f | cut -f1) "; \
	        EXPECT=$$(cat $$f.sum); \
	        for CMD in "$(BUP_CMD)" "$(RSROLL_CMD)" "$(PERKEEP_CMD)" "$(IPFSRA_CMD)" "$(IPFSSPL_CMD)" "$(RSROLL256_CMD)" "$(IPFSRA256_CMD)" "$(IPFSSPL256_CMD)" "$(IPFSBU_CMD)"; do \
	            cat $$f > /dev/null; \
	            TIME=$$(/usr/bin/time -f %U $$CMD $$f 2>&1 >$$OUT_TMPFILE); \
	            VALID="$$([ "$$(sha1sum <$$OUT_TMPFILE)" = "$$EXPECT" ]; echo -n "$$?")"; \
	            COUNT="$$(wc -l <$$OUT_TMPFILE)"; \
	            echo -n "$$TIME[$$VALID,$$COUNT] "; \
	        done; \
	        echo; \
	    done \
	) | column -t
