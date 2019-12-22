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
	./runtest.py "$(TEST_FILES)" "BUP=$(BUP_CMD)" "RSROLL=$(RSROLL_CMD)" "PERKEEP=$(PERKEEP_CMD)" "IPFSRA=$(IPFSRA_CMD)" "IPFSSPL=$(IPFSSPL_CMD)" "RSROLL256=$(RSROLL256_CMD)" "IPFSRA256=$(IPFSRA256_CMD)" "IPFSSPL256=$(IPFSSPL256_CMD)" "IPFSBU=$(IPFSBU_CMD)" | column -t
