package main

import "bytes"
import "fmt"
import "os"
import "io/ioutil"
import "./impl/go-ipfs-chunker"

func main() {
    algo := os.Args[1]
    buf, err := ioutil.ReadFile(os.Args[2])
    if err != nil {
        panic("file bad")
    }

    if algo == "split" {
        test_split(buf, 8192)
    } else if algo == "split256" {
        test_split(buf, 256*1024)
    } else if algo == "rabin" {
        test_rabin(buf, 8192)
    } else if algo == "rabin256" {
        test_rabin(buf, 256*1024)
    } else if algo == "buzhash" {
        test_buzhash(buf)
    } else {
        panic("unknown algo")
    }
}

func test_split(buf []byte, avgchunk int64) {
    find_split := func(r chunk.Splitter) (uint, int) {
        bs, err := r.NextBytes()
        if err != nil {
            panic(err)
        }
        return uint(len(bs)), 0
    }

    s := chunk.NewSizeSplitter(bytes.NewReader(buf), avgchunk)

    var ofs uint = 0
    for ofs < uint(len(buf)) {
        count, bits := find_split(s)
        fmt.Printf("%d %d\n", count, bits)
        if count == 0 {
            break
        }
        ofs += count
    }
}

func test_rabin(buf []byte, avgchunk uint64) {
    find_split := func(r *chunk.Rabin) (uint, int) {
        bs, err := r.NextBytes()
        if err != nil {
            panic(err)
        }
        return uint(len(bs)), 0
    }

    s := chunk.NewRabin(bytes.NewReader(buf), avgchunk)

    var ofs uint = 0
    for ofs < uint(len(buf)) {
        count, bits := find_split(s)
        fmt.Printf("%d %d\n", count, bits)
        if count == 0 {
            break
        }
        ofs += count
    }
}

func test_buzhash(buf []byte) {
    find_split := func(r *chunk.Buzhash) (uint, int) {
        bs, err := r.NextBytes()
        if err != nil {
            panic(err)
        }
        return uint(len(bs)), 0
    }

    s := chunk.NewBuzhash(bytes.NewReader(buf))

    var ofs uint = 0
    for ofs < uint(len(buf)) {
        count, bits := find_split(s)
        fmt.Printf("%d %d\n", count, bits)
        if count == 0 {
            break
        }
        ofs += count
    }
}
