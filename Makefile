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

preptest:
	cd impl/bup && make
	cd impl/rsroll && cargo build --release --lib
	cd impl/bita && cargo build --release --lib
	cd impl/libasuran && cargo build --release --lib
	rustc --edition 2018 -C opt-level=3 -C lto \
	  -L ./impl/rsroll/target/release/deps \
	  -L ./impl/bita/target/release/deps \
	  -L ./impl/libasuran/target/release/deps \
	  test_rust.rs
	# golang "internal modules" and "import path checking" biting us here
	export GOPATH=$$(mktemp -d) && \
	  mkdir -p $$GOPATH/src/rollsum && \
	  cp impl/perkeep/internal/rollsum/rollsum.go $$GOPATH/src/rollsum/ && \
	  sed -i 's#// import.*##g' $$GOPATH/src/rollsum/rollsum.go && \
	  go build test_perkeep.go
	export GOPATH=$$(mktemp -d) && \
	  go get github.com/ipfs/go-ipfs-chunker && \
	  go build test_ipfs.go

# First group is bupsplit, second group is other 8k targeting sums, third is 256k targeting sums
test:
	./runtest.py "$(TEST_FILES)" \
	  "BUP=python2 -u test_bup.py" \
	  "RSROBU=./test_rust rsroll-bup" \
	  "BITABU=./test_rust bita-bup" \
	  "PERKEEP=./test_perkeep" \
	  \
	  "RSROGE=./test_rust rsroll-gear" \
	  "IPFSRA=./test_ipfs rabin" \
	  "IPFSSPL=./test_ipfs split" \
	  \
	  "RSROBU256=./test_rust rsroll-bup256" \
	  "RSROGE256=./test_rust rsroll-gear256" \
	  "BITABZ=./test_rust bita-buzhash" \
	  "ASURANBZ=./test_rust asuran-buzhash" \
	  "IPFSRA256=./test_ipfs rabin256" \
	  "IPFSSPL256=./test_ipfs split256" \
	  "IPFSBZ=./test_ipfs buzhash" \
	| column -t
