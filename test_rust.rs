extern crate rollsum;

use std::env;
use std::fs;
use std::path::Path;
use std::io::prelude::*;

pub fn main () {
    let args: Vec<_> = env::args().collect();
    let algo = &args[1];
    let mut file = fs::File::open(&Path::new(&args[2])).unwrap();
    let mut buf = vec![];
    file.read_to_end(&mut buf).unwrap();

    if algo == "rsroll-bup" {
        test_bup(buf);
    } else if algo == "rsroll-bup256" {
        test_bup256(buf);
    } else if algo == "rsroll-gear" {
        test_gear(buf);
    } else if algo == "rsroll-gear256" {
        test_gear256(buf);
    } else {
        panic!("unknown algo {}", algo)
    }
}

fn test_bup(buf: Vec<u8>) {
    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let mut b = rollsum::Bup::new();
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

fn test_bup256(buf: Vec<u8>) {
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

fn test_gear(buf: Vec<u8>) {
    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let mut b = rollsum::Gear::new();
        if let Some((count, _digest)) = b.find_chunk_edge(&buf[ofs..]) {
            let bits = 0;
            println!("{} {}", count, bits);
            ofs += count;
        } else {
            println!("0 -1");
            break
        }
    }
}

fn test_gear256(buf: Vec<u8>) {
    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let mut b = rollsum::Gear::new_with_chunk_bits(18);
        if let Some((count, _digest)) = b.find_chunk_edge(&buf[ofs..]) {
            let bits = 0;
            println!("{} {}", count, bits);
            ofs += count;
        } else {
            println!("0 -1");
            break
        }
    }
}
