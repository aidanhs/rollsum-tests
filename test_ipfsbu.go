package main

import "bytes"
import "fmt"
import "os"
import "io/ioutil"
import "github.com/ipfs/go-ipfs-chunker"

func find_split(r chunk.Splitter) (uint, int) {
    bs, err := r.NextBytes()
    if err != nil {
        panic(err)
    }
    return uint(len(bs)), 0
}

func main() {
    buf, err := ioutil.ReadFile(os.Args[1])
    if err != nil {
        panic("file bad")
    }

    s := chunk.NewBuzhash(bytes.NewReader(buf)) // according to bup design

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
