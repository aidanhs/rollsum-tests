import sys
from bup import _helpers
def main():
    buf = open(sys.argv[1]).read()
    ofs = 0
    while ofs < len(buf):
        count, bits = _helpers.splitbuf(buf[ofs:])
        print "%s %s" % (count, bits)
        if count == 0:
            break
        ofs += count
main()
