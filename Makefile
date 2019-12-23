.PHONY: container default dep testfiles preptest test

BUILDDIR = ./build
export GOPATH = $(shell pwd)/build/gopath
export PYTHONPATH = ./impl/bup/lib

MTGEN = $(BUILDDIR)/mtgen

default:
	echo "please read the readme"

$(MTGEN): mtgen.c mt19937ar.c
	gcc -o $@ -static -O3 mtgen.c

container:
	podman build -t rollsum-tests .

TEST_FILES ?= $(addsuffix .test,$(addprefix test/,01 02 03 04 05 06 07 08 09 10 11 12 13 14))
testfiles: $(MTGEN) $(TEST_FILES)

%.test:
	N=$$(basename $@ .test) && \
	  SEED=$$(echo "$$N*1000" | bc) && \
	  SIZE=$$(echo "$$N^8" | bc) && \
	  $(MTGEN) $$SEED $$SIZE > $@

# This is basically a question of "how much do you trust your dep tracking".
# Me? I trust Cargo and go, but not custom Makefiles
rebuilddep:
	cd impl/bup && git clean -fxd && make
	cd impl/bita && : && cargo build --release --lib
	cd impl/go-ipfs-chunker && : && (cd .. && go get ./go-ipfs-chunker) # idk why doing the install from the dir uses pkg (rather than src) or why building then can't find pkg
	cd impl/libasuran && : && cargo build --release --lib
	# golang "internal modules" and "import path checking" biting us with perkeep
	cd impl/perkeep && : && (mkdir -p $$GOPATH/src/rollsum && cp internal/rollsum/rollsum.go $$GOPATH/src/rollsum/ && sed -i 's#// import.*##g' $$GOPATH/src/rollsum/rollsum.go)
	cd impl/rsroll && : && cargo build --release --lib

preptest:
	rustc --edition 2018 -C opt-level=3 -C lto \
	  -L ./impl/rsroll/target/release/deps \
	  -L ./impl/bita/target/release/deps \
	  -L ./impl/libasuran/target/release/deps \
	  -o $(BUILDDIR)/test_rust \
	  test_rust.rs
	go build -o $(BUILDDIR)/test_perkeep test_perkeep.go
	go build -o $(BUILDDIR)/test_ipfs test_ipfs.go

# First group is bupsplit, second group is other sums targeting 8k, third is 256k targeting sums
test:
	./runtest.py "$(TEST_FILES)" \
	  "BUP=python2 -u test_bup.py" \
	  "RSROBU=$(BUILDDIR)/test_rust rsroll-bup" \
	  "BITABU=$(BUILDDIR)/test_rust bita-bup" \
	  "PERKEEP=$(BUILDDIR)/test_perkeep" \
	  \
	  "RSROGE=$(BUILDDIR)/test_rust rsroll-gear" \
	  "IPFSRA=$(BUILDDIR)/test_ipfs rabin" \
	  "IPFSSPL=$(BUILDDIR)/test_ipfs split" \
	  \
	  "RSROBU256=$(BUILDDIR)/test_rust rsroll-bup256" \
	  "RSROGE256=$(BUILDDIR)/test_rust rsroll-gear256" \
	  "BITABZ=$(BUILDDIR)/test_rust bita-buzhash" \
	  "ASURANBZ=$(BUILDDIR)/test_rust asuran-buzhash" \
	  "IPFSRA256=$(BUILDDIR)/test_ipfs rabin256" \
	  "IPFSSPL256=$(BUILDDIR)/test_ipfs split256" \
	  "IPFSBZ=$(BUILDDIR)/test_ipfs buzhash" \
	| column -t
