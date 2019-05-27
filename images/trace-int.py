#!/usr/bin/python
from bcc import BPF

bpf="""
#include <uapi/linux/ptrace.h>

int trace(struct pt_regs *ctx) {
  if (!PT_REGS_PARM1(ctx) ) {
    bpf_trace_printk("arg error\\n");
    return 0;
  }

  bpf_trace_printk("trace %d\\n", ctx->si);
  return 0;
}
"""

b = BPF(text=bpf)

b.attach_uprobe(name="/app-profile/sample-netcore-app.ni.exe", addr=0x1920, fn_name="trace").trace_print()