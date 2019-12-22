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
        let mut b = rollsum::Bup::new_with_chunk_bits(18);
        if let Some((count, _digest)) = b.find_chunk_edge(&buf[ofs..]) {
            let bits = b.count_bits();
            println!("{} {}", count, bits);
            ofs += count;
        } else {
            println!("0 -1");
            break
        }
    }
}
