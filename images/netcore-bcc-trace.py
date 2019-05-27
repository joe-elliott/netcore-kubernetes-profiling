
    #!/usr/bin/python
    from bcc import BPF
    import argparse

    parser = argparse.ArgumentParser('netcore-bcc-trace')
    parser.add_argument('nativeImagePath', help='Full path to the native netcore image to trace.', type=str)
    parser.add_argument('methodOffset', help='The offset of the method to trace.', type=lambda x: int(x,0))
    parser.add_argument('type', help='The type of parameter or return value.', choices=['int', 'str'], type=str)
    parser.add_argument('--length', help='The max length to print for string types.')
    parser.add_argument('--return', help='Pass this flag if you want to trace a return value instead of a parameter.', default=False, action='store_true')  
    args = parser.parse_args()

    def generateBPF(type, length, isReturn):
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

      return bpf

    bpf = generateBPF(args.type, args.length, args.return)
    b = BPF(text=bpf)

    b.attach_uprobe(name=args.nativeImagePath, addr=args.methodOffset, fn_name="trace").trace_print()