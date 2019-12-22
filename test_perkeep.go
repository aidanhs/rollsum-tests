package main

import "fmt"
import "os"
import "io/ioutil"
import "rollsum"

func find_split(buf []byte) (uint, int) {
    bits := -1
    rs := rollsum.New()
    for i, b := range buf {
        rs.Roll(b)
        if !rs.OnSplit() {
            continue
        }
        bits = rs.Bits()
        return uint(i)+1, bits
    }
    return 0, bits
}

func main() {
    buf, err := ioutil.ReadFile(os.Args[1])
    if err != nil {
        panic("file bad")
    }

    var ofs uint = 0
    for ofs < uint(len(buf)) {
        count, bits := find_split(buf[ofs:])
        fmt.Printf("%d %d\n", count, bits)
        if count == 0 {
            break
        }
        ofs += count
    }
}
