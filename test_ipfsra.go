package main

import "bytes"
import "fmt"
import "os"
import "strconv"
import "io/ioutil"
import "./impl/go-ipfs-chunker"

func find_split(r chunk.Splitter) (uint, int) {
    bs, err := r.NextBytes()
    if err != nil {
        panic(err)
    }
    return uint(len(bs)), 0
}

func main() {
    avgchunk_s := os.Args[1]
    avgchunk, err := strconv.Atoi(avgchunk_s)
    if err != nil {
        panic("bad avgchunk")
    }
    buf, err := ioutil.ReadFile(os.Args[2])
    if err != nil {
        panic("file bad")
    }

    s := chunk.NewRabin(bytes.NewReader(buf), uint64(avgchunk))

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
