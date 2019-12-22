package main

import "fmt"
import "os"
import "io/ioutil"
import "rollsum"

func find_split(buf []byte) int {
    rs := rollsum.New()
    for i, b := range buf {
        rs.Roll(b)
        if !rs.OnSplit() {
            continue
        }
        return i+1
    }
    return 0
}

func main() {
    buf, err := ioutil.ReadFile(os.Args[1])
    if err != nil {
        panic("file bad")
    }

    var ofs int = 0
    for ofs < int(len(buf)) {
        count := find_split(buf[ofs:])
        if count == 0 {
            break
        }
        fmt.Printf("%d\n", count)
        ofs += count
    }
}
