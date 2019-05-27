#!/usr/bin/python

from bcc import BPF
from time import sleep

bpf="""
#include <uapi/linux/ptrace.h>
#include <linux/blkdev.h>

BPF_HISTOGRAM(dist);
BPF_HISTOGRAM(dist_linear);

int trace(struct pt_regs *ctx) {
  if (!PT_REGS_PARM1(ctx) ) {
    bpf_trace_printk("arg error\\n");
    return 0;
  }

  dist.increment(bpf_log2l(ctx->si));
  dist_linear.increment(ctx->si);

  return 0;
}
"""

b = BPF(text=bpf)
b.attach_uprobe(name="/app-profile/sample-netcore-app.ni.exe", addr=0x1920, fn_name="trace")

print("Tracing .. Hit Ctrl-C to end.")

# trace until Ctrl-C
try:
        sleep(99999999)
except KeyboardInterrupt:
        print()

# output
print("log2 histogram")
print("~~~~~~~~~~~~~~")
b["dist"].print_log2_hist("pos")

print("\nlinear histogram")
print("~~~~~~~~~~~~~~~~")
b["dist_linear"].print_linear_hist("pos")