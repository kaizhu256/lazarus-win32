{
   This file is part of the Free Pascal run time library.
   (c) 2000-2003 by Marco van de Voort
   member of the Free Pascal development team.

   See the file COPYING.FPC, included in this distribution,
   for details about the copyright.

   Signalhandler for FreeBSD/i386

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY;without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}

procedure SignalToRunerror(Sig: cint; info : psiginfo; SigContext:PSigContext); public name '_FPC_DEFAULTSIGHANDLER'; cdecl;

var
  p: pbyte;
  res : word;

begin
  res:=0;
  case sig of
    SIGFPE :
      begin
        Case Info^.si_code Of
          FPE_INTDIV,             { integer divide by zero -NOTIMP on Mac OS X 10.4.7 }
          FPE_FLTDIV : Res:=200;  { floating point divide by zero }
          FPE_FLTOVF : Res:=205;  { floating point overflow }
          FPE_FLTUND : Res:=206;  { floating point underflow }
          FPE_FLTRES,             { floating point inexact result }
          FPE_FLTINV : Res:=207;  { invalid floating point operation }
          Else
            begin
              { Assume that if an integer divide was executed, the }
              { error was a divide-by-zero (FPE_INTDIV is not      }
              { implemented as of 10.5.0)                          }
{$ifdef cpu64}
              p:=pbyte(sigcontext^.uc_mcontext^.ts.rip);
{$else cpu64}
              p:=pbyte(sigcontext^.uc_mcontext^.ts.eip);
{$endif cpu64}
              { skip some prefix bytes }
              while (p^ in [{$ifdef cpu64}$40..$4f,{$endif}$66,$67]) do
                inc(p);
              if (p^ in [$f6,$f7]) and
                 (((p+1)^ and (%110 shl 3)) = (%110 shl 3)) then
                Res:=200
              else
                Res:=207; { coprocessor error }
            end;
        end;
        { make sure any fpu operations won't trigger new exceptions in handler }
        sysResetFPU;
        { Now clear exception flags in the context }
        { perform an fnclex: clear exception and busy flags }
        sigcontext^.uc_mcontext^.fs.fpu_fsw.flag0:=
          sigcontext^.uc_mcontext^.fs.fpu_fsw.flag0 and (not(%11111111) and not(1 shl 15));
        { also clear sse exception flags }
        sigcontext^.uc_mcontext^.fs.fpu_mxcsr:=
          sigcontext^.uc_mcontext^.fs.fpu_mxcsr and not(%111111)
      end;
    SIGILL,
    SIGBUS,
    SIGSEGV :
        res:=216;
    SIGINT:
        res:=217;
    SIGQUIT:
        res:=233;
  end;
  {$ifdef FPC_USE_SIGPROCMASK}
   reenable_signal(sig);
  {$endif }

  if (res <> 0) then
    begin
{$ifdef cpu64}
      sigcontext^.uc_mcontext^.ts.rdi:=res;
      sigcontext^.uc_mcontext^.ts.rsi:=sigcontext^.uc_mcontext^.ts.rip;
      sigcontext^.uc_mcontext^.ts.rdx:=sigcontext^.uc_mcontext^.ts.rbp;
      { the ABI expects the stack pointer to be 8 bytes off alignment
        due to the return address which has been pushed -- but take into account
        that rsp may already unaligned in case of a leaf routine }
      if (sigcontext^.uc_mcontext^.ts.rsp and 15)=0 then
        dec(sigcontext^.uc_mcontext^.ts.rsp,sizeof(pointer));
      { return to run time error handler }
      sigcontext^.uc_mcontext^.ts.rip:=ptruint(@HandleErrorAddrFrame);
{$else cpu64}
      { assume regcall calling convention is the default }
      sigcontext^.uc_mcontext^.ts.eax:=res;
      sigcontext^.uc_mcontext^.ts.edx:=sigcontext^.uc_mcontext^.ts.eip;
      sigcontext^.uc_mcontext^.ts.ecx:=sigcontext^.uc_mcontext^.ts.ebp;
      { the ABI expects the stack pointer to be 4 bytes off alignment }
      { due to the return address which has been pushed -- but take into account
        that esp may already unaligned in case of a leaf routine }
      if (sigcontext^.uc_mcontext^.ts.esp and 15)=0 then
        dec(sigcontext^.uc_mcontext^.ts.esp,sizeof(pointer));
      { return to run time error handler }
      sigcontext^.uc_mcontext^.ts.eip:=ptruint(@HandleErrorAddrFrame);
{$endif cpu64}
    end;
end;

