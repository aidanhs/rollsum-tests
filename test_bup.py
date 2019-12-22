import sys
from bup import _helpers
def main():
    buf = open(sys.argv[1]).read()
    ofs = 0
    while ofs < len(buf):
        count, _ = _helpers.splitbuf(buffer(buf, ofs))
        if count == 0:
            break
        print count
        ofs += count
main()
