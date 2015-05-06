extern crate rollsum;

use std::env;
use std::fs;
use std::path::Path;
use std::io::prelude::*;

pub fn main () {
    let args: Vec<_> = env::args().collect();
    let mut file = fs::File::open(&Path::new(&args[1])).unwrap();
    let mut buf = vec![];
    file.read_to_end(&mut buf).unwrap();

    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let (count, bits) = rollsum::split_find_ofs(&buf[ofs..]);
        println!("{} {}", count, bits);
        if count == 0 {
            break;
        }
        ofs += count;
    }
}
