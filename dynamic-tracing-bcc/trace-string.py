#!/usr/bin/python

from bcc import BPF

maxLength = 50;

bpf="""
#include <uapi/linux/ptrace.h>

int trace(struct pt_regs *ctx) {
  if (!PT_REGS_PARM1(ctx) ) {
    bpf_trace_printk("arg error\\n");
    return 0;
  }

  if( !ctx->si ) {
    bpf_trace_printk("null pointer\\n");
    return 0;
  }

  int len;
  bpf_probe_read(&len, sizeof(len), (void *)(ctx->si + 8));

"""

bpf += """
  char buf[%d];
  bpf_probe_read(buf, %d * sizeof(char), (void *)(ctx->si + 11));

""" % (maxLength * 2, maxLength * 2)

bpf += """
  char buf[%d];
  bpf_probe_read(buf, %d * sizeof(char), (void *)(ctx->si + 11));

""" % (maxLength * 2, maxLength * 2)

pos = 0
while pos < maxLength:
    bpf += """
  buf[%d] = buf[%d];
    """ % (pos, pos * 2 + 1)
    pos += 1

bpf += """

  bpf_trace_printk("len %d : %s \\n", len, buf);
  return 0;
}
"""

b = BPF(text=bpf)

b.attach_uprobe(name="/app-profile/sample-netcore-app.ni.exe", addr=0x1900, fn_name="trace").trace_print()