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
    find_split := func(r chunk.Splitter) int {
        bs, err := r.NextBytes()
        if err != nil {
            panic(err)
        }
        return len(bs)
    }

    s := chunk.NewSizeSplitter(bytes.NewReader(buf), avgchunk)

    var ofs int = 0
    for ofs < len(buf) {
        count := find_split(s)
        if count == 0 {
            break
        }
        fmt.Printf("%d\n", count)
        ofs += count
    }
}

func test_rabin(buf []byte, avgchunk uint64) {
    find_split := func(r *chunk.Rabin) int {
        bs, err := r.NextBytes()
        if err != nil {
            panic(err)
        }
        return len(bs)
    }

    s := chunk.NewRabin(bytes.NewReader(buf), avgchunk)

    var ofs int = 0
    for ofs < len(buf) {
        count := find_split(s)
        if count == 0 {
            break
        }
        fmt.Printf("%d\n", count)
        ofs += count
    }
}

func test_buzhash(buf []byte) {
    find_split := func(r *chunk.Buzhash) int {
        bs, err := r.NextBytes()
        if err != nil {
            panic(err)
        }
        return len(bs)
    }

    s := chunk.NewBuzhash(bytes.NewReader(buf))

    var ofs int = 0
    for ofs < len(buf) {
        count := find_split(s)
        if count == 0 {
            break
        }
        fmt.Printf("%d\n", count)
        ofs += count
    }
}
