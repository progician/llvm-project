# REQUIRES: x86
# RUN: llvm-mc -filetype=obj -triple=x86_64-apple-darwin %s -o %t.o
# RUN: lld -flavor darwinnew -o %t %t.o
# RUN: llvm-objdump --full-contents %t | FileCheck %s
# CHECK: Contents of section foo:
# CHECK:  2000 08200000 00000000
# CHECK: Contents of section bar:
# CHECK:  2008 11311111 01000000

.globl _main, _foo, _bar

.section __DATA,foo
_foo:
.quad _bar

.section __DATA,bar
_bar:
## The unsigned relocation should support 64-bit addends
.quad _foo + 0x111111111

.text
_main:
  mov $0, %rax
  ret
