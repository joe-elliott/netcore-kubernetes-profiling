#!/usr/bin/env python
#
# USAGE:    dotnet-mapgen [-h] {generate,merge} PID
#

import argparse
import glob
import os
import shutil
import subprocess
import tempfile

def bail(error):
    print("ERROR: " + error)
    exit(1)

def get_assembly_list(pid):
    assemblies = [] 
    try:
        with open("/tmp/perfinfo-%d.map" % pid) as f:
            for line in f:
                parts = line.split(';')
                if len(parts) < 2 or parts[0] != "ImageLoad":
                    continue
                assemblies.append(parts[1])
    except IOError:
        bail("error opening /tmp/perfinfo-%d.map file" % pid)
    return assemblies

def get_base_address(pid, assembly):
    hexaddr = subprocess.check_output(
        "cat /proc/%d/maps | grep %s | head -1 | cut -d '-' -f 1" %
        (pid, assembly), shell=True)
    if hexaddr == '':
        return -1
    return int(hexaddr, 16)

def append_perf_map(assembly, asm_map, pid):
    base_address = get_base_address(pid, assembly)
    lines_to_add = ""
    with open(asm_map) as f:
        for line in f:
            parts = line.split()
            offset, size, symbol = parts[0], parts[1], str.join(" ", parts[2:])
            offset = int(offset, 16) + base_address
            lines_to_add += "%016x %s %s\n" % (offset, size, symbol)
    with open("/tmp/perf-%d.map" % pid, "a") as perfmap:
        perfmap.write(lines_to_add)

def merge(pid):
    assemblies = get_assembly_list(pid)
    succeeded, failed = (0, 0)
    for assembly in assemblies:
        # TODO The generated map files have a GUID embedded in them, which
        #      allows multiple versions to coexist (probably). How do we get
        #      this GUID? E.g.:
        #         System.Runtime.ni.{819d412e-d773-4dbb-8d01-20d412b6cf09}.map
        # jpe - removed ni?: /tmp/%s.ni.{*}.map
        matches = glob.glob("/tmp/%s.{*}.map" %
                            os.path.splitext(os.path.basename(assembly))[0])
        if len(matches) == 0:
            failed += 1
        else:
            append_perf_map(assembly, matches[0], pid)
            succeeded += 1
    print("perfmap merging: %d succeeded, %d failed" % (succeeded, failed))

parser = argparse.ArgumentParser(description=
    "Generates map files for crossgen-compiled assemblies, and merges them " +
    "into the main perf map file. Built for use with .NET Core on Linux.")
parser.add_argument("pid", type=int, help="the dotnet process id")
args = parser.parse_args()

merge(args.pid)