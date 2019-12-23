extern crate bita;
extern crate futures_util;
extern crate libasuran;
extern crate rollsum;

use std::env;
use std::fs;
use std::future::Future;
use std::io::prelude::*;
use std::path::Path;

pub fn main () {
    let args: Vec<_> = env::args().collect();
    let algo = &args[1];
    let mut file = fs::File::open(&Path::new(&args[2])).unwrap();
    let mut buf = vec![];
    file.read_to_end(&mut buf).unwrap();

    if algo == "rsroll-bup" {
        test_rsroll_bup(buf);
    } else if algo == "rsroll-bup256" {
        test_rsroll_bup256(buf);
    } else if algo == "rsroll-gear" {
        test_rsroll_gear(buf);
    } else if algo == "rsroll-gear256" {
        test_rsroll_gear256(buf);
    } else if algo == "bita-bup" {
        test_bita_bup(buf);
    } else if algo == "bita-buzhash" {
        test_bita_buzhash(buf);
    } else if algo == "asuran-buzhash" {
        test_asuran_buzhash(buf);
    } else {
        panic!("unknown algo {}", algo)
    }
}

fn test_rsroll_bup(buf: Vec<u8>) {
    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let mut b = rollsum::Bup::new();
        if let Some((count, _digest)) = b.find_chunk_edge(&buf[ofs..]) {
            println!("{}", count);
            ofs += count;
        } else {
            break
        }
    }
}

fn test_rsroll_bup256(buf: Vec<u8>) {
    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let mut b = rollsum::Bup::new_with_chunk_bits(18);
        if let Some((count, _digest)) = b.find_chunk_edge(&buf[ofs..]) {
            println!("{}", count);
            ofs += count;
        } else {
            break
        }
    }
}

fn test_rsroll_gear(buf: Vec<u8>) {
    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let mut b = rollsum::Gear::new();
        if let Some((count, _digest)) = b.find_chunk_edge(&buf[ofs..]) {
            println!("{}", count);
            ofs += count;
        } else {
            break
        }
    }
}

fn test_rsroll_gear256(buf: Vec<u8>) {
    let mut ofs: usize = 0;
    while ofs < buf.len() {
        let mut b = rollsum::Gear::new_with_chunk_bits(18);
        if let Some((count, _digest)) = b.find_chunk_edge(&buf[ofs..]) {
            println!("{}", count);
            ofs += count;
        } else {
            break
        }
    }
}

fn runfut<T>(mut fut: impl Future<Output=T> + Unpin) -> T {
    use std::task::{Context, Poll, RawWaker, RawWakerVTable, Waker};
    use std::pin::Pin;
    use std::ptr;

    fn rawwaker_clone(_: *const ()) -> RawWaker { panic!() }
    fn rawwaker_wake(_: *const ()) {}
    fn rawwaker_wake_by_ref(_: *const ()) {}
    fn rawwaker_drop(_: *const ()) {}
    static RAWWAKER_VTABLE: RawWakerVTable =
        RawWakerVTable::new(rawwaker_clone, rawwaker_wake, rawwaker_wake_by_ref, rawwaker_drop);

    let pinfut = Pin::new(&mut fut);
    let rawwaker = RawWaker::new(ptr::null(), &RAWWAKER_VTABLE);
    let waker = unsafe { Waker::from_raw(rawwaker) };
    let res = match pinfut.poll(&mut Context::from_waker(&waker)) {
        Poll::Ready(res) => res,
        Poll::Pending => panic!("not ready"),
    };
    res
}

fn test_bita_bup(buf: Vec<u8>) {
    use futures_util::stream::StreamExt;
    use std::usize;

    let config = bita::chunker::ChunkerConfig::RollSum(bita::chunker::HashConfig {
        filter_bits: bita::chunker::HashFilterBits(13),
        min_chunk_size: 0,
        max_chunk_size: usize::MAX,
        window_size: 1 << 6,
    });
    let mut buf = buf.as_slice();
    let fut = bita::chunker::Chunker::new(config, &mut buf)
        .map(|result| {
            let (offset, _chunk) = result.unwrap();
            offset
        })
        .collect::<Vec<u64>>();
    let res = runfut(fut);
    let mut ofs_iter = res.into_iter();
    let mut last_ofs = ofs_iter.next().unwrap();
    assert!(last_ofs == 0);
    for ofs in ofs_iter {
        println!("{}", ofs - last_ofs);
        last_ofs = ofs
    }
}

fn test_bita_buzhash(buf: Vec<u8>) {
    use futures_util::stream::StreamExt;
    use std::usize;

    let config = bita::chunker::ChunkerConfig::BuzHash(bita::chunker::HashConfig {
        filter_bits: bita::chunker::HashFilterBits(18),
        min_chunk_size: 0,
        max_chunk_size: usize::MAX,
        window_size: 1 << 5,
    });
    let mut buf = buf.as_slice();
    let fut = bita::chunker::Chunker::new(config, &mut buf)
        .map(|result| {
            let (offset, _chunk) = result.unwrap();
            offset
        })
        .collect::<Vec<u64>>();
    let res = runfut(fut);
    let mut ofs_iter = res.into_iter();
    let mut last_ofs = ofs_iter.next().unwrap();
    assert!(last_ofs == 0);
    for ofs in ofs_iter {
        println!("{}", ofs - last_ofs);
        last_ofs = ofs
    }
}

fn test_asuran_buzhash(buf: Vec<u8>) {
    use libasuran::chunker::Slicer;

    let mut chunker = libasuran::chunker::slicer::buzhash::BuzHash::new(0, 1 << 5, 18);
    chunker.add_reader(buf.as_slice());
    while let Some(chunk) = chunker.take_slice() {
        println!("{}", chunk.len())
    }
}
