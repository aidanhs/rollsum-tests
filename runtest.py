#!/usr/bin/env python3
import os
from subprocess import call, check_output
import sys
import tempfile

def out(s, *args, **kwargs):
    print(s + ' ', *args, **kwargs)
def outline():
    print()
def log(*args, **kwargs):
    print(*args, **kwargs, file=sys.stderr)

def main():
    test_files = sys.argv[1].split(' ')
    test_impls = [test_impl.split('=') for test_impl in sys.argv[2:]]

    out_tmpfile = tempfile.NamedTemporaryFile()
    for impl_name, _ in test_impls:
        out(f'{impl_name}', end='')
    outline()

    for test_file in test_files:
        test_sum_file = test_file + '.sum'
        if not (os.path.exists(test_file) and os.path.exists(test_sum_file)):
            log('INVALID FILE {test_file}')
            sys.exit(1)
        test_name = os.path.basename(test_file)
        expected_sha = open(test_sum_file, 'rb').read()
        for impl_name, impl_cmd in test_impls:
            log(f'Testing {test_file}=>{impl_name}')
            call(f'cat {test_file} > /dev/null', shell=True)
            time = float(check_output(f'/usr/bin/time -f %U {impl_cmd} {test_file} 2>&1 >{out_tmpfile.name}', shell=True).strip())
            actual_sha = check_output(f'sha1sum <{out_tmpfile.name}', shell=True)
            err = actual_sha != expected_sha
            count = len(open(out_tmpfile.name, 'rb').readlines())
            res = f'{time}[{int(err)},{count}]'
            out(res, end='')
        outline()

    log()
    log('KEY')
    log('Each cell is `time[err,count]`. `time` is in ms, `err` indicates whether the split result failed to')
    log('match bup exactly and `count` indicates how many splits there were.')
    log()

if __name__ == '__main__':
    main()
