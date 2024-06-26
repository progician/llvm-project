; RUN: opt %loadNPMPolly '-passes=print<polly-function-scops>' -polly-invariant-load-hoisting=true -disable-output < %s 2>&1 | FileCheck %s
; RUN: opt %loadNPMPolly -passes=polly-codegen -polly-invariant-load-hoisting=true -S < %s 2>&1 | FileCheck %s --check-prefix=CODEGEN
;
;    void f(int *I0, int *I1, int *V) {
;      for (int i = 0; i < 1000; i++) {
;        if ((long)(*I0) == 0)
;          V[i] += *I1;
;      }
;    }
;
; CHECK:         Assumed Context:
; CHECK-NEXT:      [loadI0] -> {  :  }
; CHECK-NEXT:    Invalid Context:
; CHECK-NEXT:      [loadI0] -> {  : loadI0 < 0 }
;
; CHECK:   p0: %loadI0
;
; CHECK:       Stmt_if_then
; CHECK-NEXT:    Domain :=
; CHECK-NEXT:      [loadI0] -> { Stmt_if_then[i0] : loadI0 = 0 and 0 <= i0 <= 999 };
;
; CODEGEN:      polly.preload.begin:
; CODEGEN-NEXT:   %polly.access.I0 = getelementptr i32, ptr %I0, i64 0
; CODEGEN-NEXT:   %polly.access.I0.load = load i32, ptr %polly.access.I0
; CODEGEN-NEXT:   store i32 %polly.access.I0.load, ptr %loadI1a.preload.s2a
; CODEGEN-NEXT:   %0 = sext i32 %polly.access.I0.load to i64
; CODEGEN-NEXT:   %1 = icmp eq i64 %0, 0
; CODEGEN-NEXT:   %polly.preload.cond.result = and i1 %1, true
; CODEGEN-NEXT:   br label %polly.preload.cond
;
; CODEGEN:      polly.preload.cond:
; CODEGEN-NEXT:   br i1 %polly.preload.cond.result, label %polly.preload.exec, label %polly.preload.merge
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define void @f(ptr %I0, ptr %I1, ptr %V) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %loadI1a = load i32, ptr %I0, align 4
  %arrayidx = getelementptr inbounds i32, ptr %V, i64 %indvars.iv
  %loadI1a1 = load i32, ptr %arrayidx, align 4
  %add = add nsw i32 %loadI1a1, %loadI1a
  store i32 %add, ptr %arrayidx, align 4
  %loadI0 = load i32, ptr %I0, align 4
  %loadI0ext = zext i32 %loadI0 to i64
  %cmp1 = icmp eq i64 %loadI0ext, 0
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  %loadI1b = load i32, ptr %I1, align 4
  %arrayidx4 = getelementptr inbounds i32, ptr %V, i64 %indvars.iv
  %loadI1a4 = load i32, ptr %arrayidx4, align 4
  %add5 = add nsw i32 %loadI1a4, %loadI1b
  store i32 %add5, ptr %arrayidx4, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}
