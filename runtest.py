#!/usr/bin/env python3
import os
import statistics
from subprocess import call, check_output
import sys
import tempfile

def out(s, *args, **kwargs):
    print(s + ' ', *args, **kwargs, end='')
def outline():
    print()
def log(*args, **kwargs):
    print(*args, **kwargs, file=sys.stderr)

def main():
    test_files = sys.argv[1].split(' ')
    test_impls = [test_impl.split('=') for test_impl in sys.argv[2:]]

    out_tmpfile = tempfile.NamedTemporaryFile()

    out('FILE')
    out('SIZE')
    for impl_name, _ in test_impls:
        out(f'{impl_name}')
    outline()

    for test_file in test_files:
        test_sum_file = test_file + '.sum'
        if not (os.path.exists(test_file) and os.path.exists(test_sum_file)):
            log('INVALID FILE {test_file}')
            sys.exit(1)
        test_name = os.path.basename(test_file)
        out(test_name)
        out(check_output(f'du -h {test_file} | cut -f1', shell=True).decode('ascii').strip())
        expected_sha = open(test_sum_file, 'rb').read()
        first_nonerr = True
        for impl_name, impl_cmd in test_impls:
            log(f'Testing {test_file}=>{impl_name}')
            call(f'cat {test_file} > /dev/null', shell=True)
            time_out = check_output(f'/usr/bin/time -f "%U %M" {impl_cmd} {test_file} 2>&1 >{out_tmpfile.name}', shell=True).strip()

            user_time, max_mem = time_out.split(b' ')
            user_time = float(user_time)
            max_mem = round(int(max_mem) / 1024)
            actual_sha = check_output(f'sha1sum <{out_tmpfile.name}', shell=True)
            err = actual_sha != expected_sha
            sizes = [int(size) for size in open(out_tmpfile.name, 'rb').readlines()]
            count = len(sizes)
            if count > 500:
                pstdev = round(statistics.pstdev(sizes))
            else:
                pstdev = '-'

            if err or first_nonerr:
                res = f'{user_time}[{"X" if err else "/"},{count}c,{pstdev},{max_mem}M]'
                if not err:
                    first_nonerr = False
            else:
                res = f'{user_time}[",",",{max_mem}M]'
            out(res)
        outline()

    log()
    log('HOW TO READ THE RESULTS')
    log('- Each cell is `time[err,count,pstdev,mem]`. `time` is in seconds, `err` indicates whether the split result failed')
    log('  to match bup exactly, `count` indicates how many splits there were, `pstdev` indicates the standard devision of the')
    log('  split sizes and `mem` indicates max memory in MB.')
    log('- Standard deviation is only calculated for tests with >500 splits to try and give a rough judgement on the hash')
    log('  algorighm quality (intuitively I think random data should be a happy case for a hash).')
    log('- To save screen space, the common results from non-erroring lines are collapsed.')
    log()

if __name__ == '__main__':
    main()
