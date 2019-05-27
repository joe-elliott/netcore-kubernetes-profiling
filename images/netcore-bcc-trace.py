#!/usr/bin/python
from bcc import BPF
import argparse

parser = argparse.ArgumentParser('netcore-bcc-trace')
parser.add_argument('nativeImagePath', help='Full path to the native netcore image to trace.', type=str)
parser.add_argument('methodOffset', help='The offset of the method to trace.', type=lambda x: int(x,0))
parser.add_argument('type', help='The type of parameter or return value.', choices=['int', 'str'], type=str)
parser.add_argument('--len', help='The max length to print for string types.', default=50)
parser.add_argument('--ret', help='Pass this flag if you want to trace a return value instead of a parameter.', default=False, action='store_true')  
args = parser.parse_args()

def generateBPF(type, maxLength, isReturn):
    bpf="""
    #include <uapi/linux/ptrace.h>

    int trace(struct pt_regs *ctx) {
    if (!PT_REGS_PARM1(ctx) ) {
        bpf_trace_printk("arg error\\n");
        return 0;
    }
    """

    if type == 'int':
        if isReturn: 
            bpf += 'bpf_trace_printk("trace %d\\n", PT_REGS_RC(ctx));'
        else:
            bpf += 'bpf_trace_printk("trace %d\\n", PT_REGS_PARM2(ctx));'
    elif type == 'str':
        # print a string up to maxLength characters
        bpf += """
            if( !ctx->si ) {
            bpf_trace_printk("null pointer\\n");
            return 0;
            }

            int len;
            bpf_probe_read(&len, sizeof(len), (void *)(ctx->si + 8));
        """

        # create a large enough char buff
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
        """

    bpf += """
       return 0;
    }
    """

    return bpf

bpf = generateBPF(args.type, args.len, args.ret)
b = BPF(text=bpf)

if args.ret:
    b.attach_uretprobe(name=args.nativeImagePath, addr=args.methodOffset, fn_name="trace").trace_print()
else:
    b.attach_uprobe(name=args.nativeImagePath, addr=args.methodOffset, fn_name="trace").trace_print()