unit FpDbgDarwinClasses;

{$mode objfpc}{$H+}
{$linkframework security}

interface

uses
  Classes,
  SysUtils,
  BaseUnix,
  process,
  FpDbgClasses,
  FpDbgLoader,
  DbgIntfBaseTypes,
  FpDbgLinuxExtra,
  FpDbgInfo,
  MacOSAll,
  FpDbgUtil,
  LazLoggerBase;

type
  x86_thread_state32_t = record
    __eax: cuint;
    __ebx: cuint;
    __ecx: cuint;
    __edx: cuint;
    __edi: cuint;
    __esi: cuint;
    __ebp: cuint;
    __esp: cuint;
    __ss: cuint;
    __eflags: cuint;
    __eip: cuint;
    __cs: cuint;
    __ds: cuint;
    __es: cuint;
    __fs: cuint;
    __gs: cuint;
  end;

  x86_thread_state64_t = record
    __rax: cuint64;
    __rbx: cuint64;
    __rcx: cuint64;
    __rdx: cuint64;
    __rdi: cuint64;
    __rsi: cuint64;
    __rbp: cuint64;
    __rsp: cuint64;
    __r8: cuint64;
    __r9: cuint64;
    __r10: cuint64;
    __r11: cuint64;
    __r12: cuint64;
    __r13: cuint64;
    __r14: cuint64;
    __r15: cuint64;
    __rip: cuint64;
    __rflags: cuint64;
    __cs: cuint64;
    __fs: cuint64;
    __gs: cuint64;
  end;

type

  { TDbgDarwinThread }

  TDbgDarwinThread = class(TDbgThread)
  private
    FThreadState32: x86_thread_state32_t;
    FThreadState64: x86_thread_state64_t;
    FNeedIPDecrement: boolean;
  protected
    function ReadThreadState: boolean;
  public
    function ResetInstructionPointerAfterBreakpoint: boolean; override;
    procedure LoadRegisterValues; override;
  end;

  { TDbgDarwinProcess }

  TDbgDarwinProcess = class(TDbgProcess)
  private
    FStatus: cint;
    FProcessStarted: boolean;
    FTaskPort: mach_port_name_t;
    FProcProcess: TProcess;
    FIsTerminating: boolean;
    FExceptionSignal: PtrUInt;
    function GetDebugAccessRights: boolean;
    procedure OnForkEvent(Sender : TObject);
  protected
    function InitializeLoader: TDbgImageLoader; override;
    function CreateThread(AthreadIdentifier: THandle; out IsMainThread: boolean): TDbgThread; override;
  public
    class function StartInstance(AFileName: string; AParams, AnEnvironment: TStrings; AWorkingDirectory: string; AOnLog: TOnLog): TDbgProcess; override;
    constructor Create(const AName: string; const AProcessID, AThreadID: Integer; AOnLog: TOnLog); override;
    destructor Destroy; override;

    function ReadData(const AAdress: TDbgPtr; const ASize: Cardinal; out AData): Boolean; override;
    function WriteData(const AAdress: TDbgPtr; const ASize: Cardinal; const AData): Boolean; override;

    function GetInstructionPointerRegisterValue: TDbgPtr; override;
    function GetStackPointerRegisterValue: TDbgPtr; override;
    function GetStackBasePointerRegisterValue: TDbgPtr; override;
    procedure TerminateProcess; override;

    function Continue(AProcess: TDbgProcess; AThread: TDbgThread): boolean; override;
    function WaitForDebugEvent(out ProcessIdentifier, ThreadIdentifier: THandle): boolean; override;
    function ResolveDebugEvent(AThread: TDbgThread): TFPDEvent; override;
  end;

procedure RegisterDbgClasses;

implementation

type
  vm_map_t = mach_port_t;
  vm_offset_t = UIntPtr;
  vm_address_t = vm_offset_t;
  vm_size_t = UIntPtr;
  vm_prot_t = cint;
  mach_vm_address_t = uint64;
  mach_msg_Type_number_t = natural_t;
  mach_vm_size_t = uint64;
  task_t = mach_port_t;
  thread_act_t = mach_port_t;
  thread_act_array = array[0..255] of thread_act_t;
  thread_act_array_t = ^thread_act_array;
  thread_state_flavor_t = cint;
  thread_state_t = ^natural_t;

const
  x86_THREAD_STATE32    = 1;
  x86_FLOAT_STATE32     = 2;
  x86_EXCEPTION_STATE32 = 3;
  x86_THREAD_STATE64    = 4;
  x86_FLOAT_STATE64     = 5;
  x86_EXCEPTION_STATE64 = 6;
  x86_THREAD_STATE      = 7;
  x86_FLOAT_STATE       = 8;
  x86_EXCEPTION_STATE   = 9;
  x86_DEBUG_STATE32     = 10;
  x86_DEBUG_STATE64     = 11;
  x86_DEBUG_STATE       = 12;
  THREAD_STATE_NONE     = 13;
  x86_AVX_STATE32       = 16;
  x86_AVX_STATE64       = 17;
  x86_AVX_STATE         = 18;

  x86_THREAD_STATE32_COUNT: mach_msg_Type_number_t = sizeof(x86_thread_state32_t) div sizeof(cint);
  x86_THREAD_STATE64_COUNT: mach_msg_Type_number_t = sizeof(x86_thread_state64_t) div sizeof(cint);

function task_for_pid(target_tport: mach_port_name_t; pid: integer; var t: mach_port_name_t): kern_return_t; cdecl external name 'task_for_pid';
function mach_task_self: mach_port_name_t; cdecl external name 'mach_task_self';
function mach_error_string(error_value: mach_error_t): pchar; cdecl; external name 'mach_error_string';
function mach_vm_protect(target_task: vm_map_t; adress: mach_vm_address_t; size: mach_vm_size_t; set_maximum: boolean_t; new_protection: vm_prot_t): kern_return_t; cdecl external name 'mach_vm_protect';
function mach_vm_write(target_task: vm_map_t; address: mach_vm_address_t; data: vm_offset_t; dataCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'mach_vm_write';
function mach_vm_read(target_task: vm_map_t; address: mach_vm_address_t; size: mach_vm_size_t; var data: vm_offset_t; var dataCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'mach_vm_read';

function task_threads(target_task: task_t; var act_list: thread_act_array_t; var act_listCnt: mach_msg_type_number_t): kern_return_t; cdecl external name 'task_threads';
function thread_get_state(target_act: thread_act_t; flavor: thread_state_flavor_t; old_state: thread_state_t; var old_stateCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'thread_get_state';
function thread_set_state(target_act: thread_act_t; flavor: thread_state_flavor_t; new_state: thread_state_t; old_stateCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'thread_set_state';

procedure RegisterDbgClasses;
begin
  OSDbgClasses.DbgProcessClass:=TDbgDarwinProcess;
end;

Function WIFSTOPPED(Status: Integer): Boolean;
begin
  WIFSTOPPED:=((Status and $FF)=$7F);
end;

{ TDbgDarwinThread }

procedure TDbgDarwinProcess.OnForkEvent(Sender: TObject);
begin
  fpPTrace(PTRACE_TRACEME, 0, nil, nil);
end;

function TDbgDarwinThread.ReadThreadState: boolean;
var
  aKernResult: kern_return_t;
  old_StateCnt: mach_msg_Type_number_t;
begin
  if Process.Mode=dm32 then
    begin
    old_StateCnt:=x86_THREAD_STATE32_COUNT;
    aKernResult:=thread_get_state(Id,x86_THREAD_STATE32, @FThreadState32,old_StateCnt);
    end
  else
    begin
    old_StateCnt:=x86_THREAD_STATE64_COUNT;
    aKernResult:=thread_get_state(Id,x86_THREAD_STATE64, @FThreadState64,old_StateCnt);
    end;
  if aKernResult <> KERN_SUCCESS then
    begin
    Log('Failed to call thread_get_state for thread %d. Mach error: '+mach_error_string(aKernResult),[Id]);
    end;
  FRegisterValueListValid:=false;
end;

function TDbgDarwinThread.ResetInstructionPointerAfterBreakpoint: boolean;
var
  aKernResult: kern_return_t;
  new_StateCnt: mach_msg_Type_number_t;
begin
  result := true;
  // If the breakpoint is reached by single-stepping, decrementing the
  // instruction pointer is not necessary.
  if not FNeedIPDecrement then
    Exit;

  if Process.Mode=dm32 then
    begin
    Dec(FThreadState32.__eip);
    new_StateCnt := x86_THREAD_STATE32_COUNT;
    aKernResult:=thread_set_state(ID,x86_THREAD_STATE32, @FThreadState32, new_StateCnt);
    end
  else
    begin
    Dec(FThreadState64.__rip);
    new_StateCnt := x86_THREAD_STATE64_COUNT;
    aKernResult:=thread_set_state(ID,x86_THREAD_STATE64, @FThreadState64, new_StateCnt);
    end;

  if aKernResult <> KERN_SUCCESS then
    begin
    Log('Failed to call thread_set_state for thread %d. Mach error: '+mach_error_string(aKernResult),[Id]);
    end;
end;

procedure TDbgDarwinThread.LoadRegisterValues;
begin
  if Process.Mode=dm32 then with FThreadState32 do
  begin
    FRegisterValueList.DbgRegisterAutoCreate['eax'].SetValue(__eax, IntToStr(__eax),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['ecx'].SetValue(__ecx, IntToStr(__ecx),4,1);
    FRegisterValueList.DbgRegisterAutoCreate['edx'].SetValue(__edx, IntToStr(__edx),4,2);
    FRegisterValueList.DbgRegisterAutoCreate['ebx'].SetValue(__ebx, IntToStr(__ebx),4,3);
    FRegisterValueList.DbgRegisterAutoCreate['esp'].SetValue(__esp, IntToStr(__esp),4,4);
    FRegisterValueList.DbgRegisterAutoCreate['ebp'].SetValue(__ebp, IntToStr(__ebp),4,5);
    FRegisterValueList.DbgRegisterAutoCreate['esi'].SetValue(__esi, IntToStr(__esi),4,6);
    FRegisterValueList.DbgRegisterAutoCreate['edi'].SetValue(__edi, IntToStr(__edi),4,7);
    FRegisterValueList.DbgRegisterAutoCreate['eip'].SetValue(__eip, IntToStr(__eip),4,8);

    FRegisterValueList.DbgRegisterAutoCreate['eflags'].Setx86EFlagsValue(__eflags);

    FRegisterValueList.DbgRegisterAutoCreate['cs'].SetValue(__cs, IntToStr(__cs),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['ss'].SetValue(__ss, IntToStr(__ss),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['ds'].SetValue(__ds, IntToStr(__ds),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['es'].SetValue(__es, IntToStr(__es),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['fs'].SetValue(__fs, IntToStr(__fs),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['gs'].SetValue(__gs, IntToStr(__gs),4,0);
  end else with FThreadState64 do
    begin
    FRegisterValueList.DbgRegisterAutoCreate['rax'].SetValue(__rax, IntToStr(__rax),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['rcx'].SetValue(__rcx, IntToStr(__rcx),4,1);
    FRegisterValueList.DbgRegisterAutoCreate['rdx'].SetValue(__rdx, IntToStr(__rdx),4,2);
    FRegisterValueList.DbgRegisterAutoCreate['rbx'].SetValue(__rbx, IntToStr(__rbx),4,3);
    FRegisterValueList.DbgRegisterAutoCreate['rsp'].SetValue(__rsp, IntToStr(__rsp),4,4);
    FRegisterValueList.DbgRegisterAutoCreate['rbp'].SetValue(__rbp, IntToStr(__rbp),4,5);
    FRegisterValueList.DbgRegisterAutoCreate['rsi'].SetValue(__rsi, IntToStr(__rsi),4,6);
    FRegisterValueList.DbgRegisterAutoCreate['rdi'].SetValue(__rdi, IntToStr(__rdi),4,7);
    FRegisterValueList.DbgRegisterAutoCreate['rip'].SetValue(__rip, IntToStr(__rip),4,8);

    FRegisterValueList.DbgRegisterAutoCreate['eflags'].Setx86EFlagsValue(__rflags);

    FRegisterValueList.DbgRegisterAutoCreate['cs'].SetValue(__cs, IntToStr(__cs),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r8'].SetValue(__r8, IntToStr(__r8),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r9'].SetValue(__r9, IntToStr(__r9),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r10'].SetValue(__r10, IntToStr(__r10),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r11'].SetValue(__r11, IntToStr(__r11),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r12'].SetValue(__r12, IntToStr(__r12),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r13'].SetValue(__r13, IntToStr(__r13),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r14'].SetValue(__r14, IntToStr(__r14),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['r15'].SetValue(__r15, IntToStr(__r15),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['fs'].SetValue(__fs, IntToStr(__fs),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['gs'].SetValue(__gs, IntToStr(__gs),4,0);
  end;
  FRegisterValueListValid:=true;
end;

{ TDbgDarwinProcess }

function TDbgDarwinProcess.GetDebugAccessRights: boolean;
var
  authFlags: AuthorizationFlags;
  stat: OSStatus;
  author: AuthorizationRef;
  authItem: AuthorizationItem;
  authRights: AuthorizationRights;
begin
  result := false;
  authFlags := kAuthorizationFlagExtendRights or kAuthorizationFlagPreAuthorize or kAuthorizationFlagInteractionAllowed or ( 1 << 5);

  stat := AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, author);
  if stat <> errAuthorizationSuccess then
    begin
    debugln('Failed to create authorization. Authorization error: ' + inttostr(stat));
    exit;
    end;

  authItem.name:='system.privilege.taskport';
  authItem.flags:=0;
  authItem.value:=nil;
  authItem.valueLength:=0;

  authRights.count:=1;
  authRights.items:=@authItem;

  stat := AuthorizationCopyRights(author, authRights, kAuthorizationEmptyEnvironment, authFlags, nil);
  if stat <> errAuthorizationSuccess then
    begin
    debugln('Failed to get debug-(taskport)-privilege. Authorization error: ' + inttostr(stat));
    exit;
    end;
  result := true;
end;

function TDbgDarwinProcess.InitializeLoader: TDbgImageLoader;
var
  FObjFileName: string;
  dSYMFilename: string;
begin
  // JvdS: Mach-O binaries do not contain DWARF-debug info. Instead this info
  // is stored inside the .o files, and the executable contains a map (in stabs-
  // format) of all these .o files. An alternative to parsing this map and reading
  // those .o files a dSYM-bundle could be used, which could be generated
  // with dsymutil.
  dSYMFilename:=ChangeFileExt(Name, '.dSYM');
  dSYMFilename:=dSYMFilename+'/Contents/Resources/DWARF/'+ExtractFileName(Name);

  if ExtractFileExt(dSYMFilename)='.app' then
    dSYMFilename := ChangeFileExt(dSYMFilename,'');

  if FileExists(dSYMFilename) then
    result := TDbgImageLoader.Create(dSYMFilename)
  else
    begin
    log('No dSYM bundle ('+dSYMFilename+') found.', dllInfo);
    result := TDbgImageLoader.Create(Name);
    end;
end;

function TDbgDarwinProcess.CreateThread(AthreadIdentifier: THandle; out IsMainThread: boolean): TDbgThread;
begin
  IsMainThread:=true;
  if AthreadIdentifier>-1 then
    result := TDbgDarwinThread.Create(Self, AthreadIdentifier, AthreadIdentifier)
  else
    result := nil;
end;

constructor TDbgDarwinProcess.Create(const AName: string; const AProcessID,
  AThreadID: Integer; AOnLog: TOnLog);
var
  aKernResult: kern_return_t;
begin
  inherited Create(AName, AProcessID, AThreadID, AOnLog);

  LoadInfo;

  if DbgInfo.HasInfo
  then FSymInstances.Add(Self);

  GetDebugAccessRights;
  aKernResult:=task_for_pid(mach_task_self, AProcessID, FTaskPort);
  if aKernResult <> KERN_SUCCESS then
    begin
    log('Failed to get task for process '+IntToStr(AProcessID)+'. Probably insufficient rights to debug applications. Mach error: '+mach_error_string(aKernResult), dllInfo);
    end;
end;

destructor TDbgDarwinProcess.Destroy;
begin
  FProcProcess.Free;
  inherited Destroy;
end;

class function TDbgDarwinProcess.StartInstance(AFileName: string; AParams, AnEnvironment: TStrings; AWorkingDirectory: string; AOnLog: TOnLog): TDbgProcess;
var
  PID: TPid;
  stat: longint;
  AProcess: TProcess;
  AnExecutabeFilename: string;
begin
  result := nil;

  AnExecutabeFilename:=ExcludeTrailingPathDelimiter(AFileName);
  if DirectoryExists(AnExecutabeFilename) then
    begin
    if not (ExtractFileExt(AnExecutabeFilename)='.app') then
      begin
      DebugLn(format('Can not debug %s, because it''s a directory',[AnExecutabeFilename]));
      Exit;
      end;

    AnExecutabeFilename := AnExecutabeFilename + '/Contents/MacOS/' + ChangeFileExt(ExtractFileName(AnExecutabeFilename),'');
    if not FileExists(AFileName) then
      begin
      DebugLn(format('Can not find  %s.',[AnExecutabeFilename]));
      Exit;
      end;
    end;

  AProcess := TProcess.Create(nil);
  try
    AProcess.OnForkEvent:=@OnForkEvent;
    AProcess.Executable:=AnExecutabeFilename;
    AProcess.Parameters:=AParams;
    AProcess.Environment:=AnEnvironment;
    AProcess.CurrentDirectory:=AWorkingDirectory;
    AProcess.Execute;
    PID:=AProcess.ProcessID;

    sleep(100);
    result := TDbgDarwinProcess.Create(AFileName, Pid, -1, AOnLog);
  except
    AProcess.Free;
    raise;
  end;

  TDbgDarwinProcess(result).FProcProcess := AProcess;
end;

function TDbgDarwinProcess.ReadData(const AAdress: TDbgPtr;
  const ASize: Cardinal; out AData): Boolean;
var
  aKernResult: kern_return_t;
  cnt: mach_msg_Type_number_t;
  b: pointer;
begin
  result := false;

  aKernResult := mach_vm_read(FTaskPort, AAdress, ASize, PtrUInt(b), cnt);
  if aKernResult <> KERN_SUCCESS then
    begin
    DebugLn('Failed to read data at address '+FormatAddress(AAdress)+'. Mach error: '+mach_error_string(aKernResult));
    Exit;
    end;
  System.Move(b^, AData, Cnt);
  MaskBreakpointsInReadData(AAdress, ASize, AData);
  result := true;
end;

function TDbgDarwinProcess.WriteData(const AAdress: TDbgPtr;
  const ASize: Cardinal; const AData): Boolean;
var
  aKernResult: kern_return_t;
begin
  result := false;
  aKernResult:=mach_vm_protect(FTaskPort, AAdress, ASize, boolean_t(false), 7 {VM_PROT_READ + VM_PROT_WRITE + VM_PROT_COPY});
  if aKernResult <> KERN_SUCCESS then
    begin
    DebugLn('Failed to call vm_protect for address '+FormatAddress(AAdress)+'. Mach error: '+mach_error_string(aKernResult));
    Exit;
    end;

  aKernResult := mach_vm_write(FTaskPort, AAdress, vm_offset_t(@AData), ASize);
  if aKernResult <> KERN_SUCCESS then
    begin
    DebugLn('Failed to write data at address '+FormatAddress(AAdress)+'. Mach error: '+mach_error_string(aKernResult));
    Exit;
    end;

  result := true;
end;

function TDbgDarwinProcess.GetInstructionPointerRegisterValue: TDbgPtr;
begin
  if Mode=dm32 then
    result := TDbgDarwinThread(FMainThread).FThreadState32.__eip
  else
    result := TDbgDarwinThread(FMainThread).FThreadState64.__rip;
end;

function TDbgDarwinProcess.GetStackPointerRegisterValue: TDbgPtr;
begin
  if Mode=dm32 then
    result := TDbgDarwinThread(FMainThread).FThreadState32.__esp
  else
    result := TDbgDarwinThread(FMainThread).FThreadState64.__rsp;
end;

function TDbgDarwinProcess.GetStackBasePointerRegisterValue: TDbgPtr;
begin
  if Mode=dm32 then
    result := TDbgDarwinThread(FMainThread).FThreadState32.__ebp
  else
    result := TDbgDarwinThread(FMainThread).FThreadState64.__rbp;
end;

procedure TDbgDarwinProcess.TerminateProcess;
begin
  FIsTerminating:=true;
  if fpkill(ProcessID,SIGKILL)<>0 then
    begin
    log('Failed to send SIGKILL to process %d. Errno: %d',[ProcessID, errno]);
    FIsTerminating:=false;
    end;
end;

function TDbgDarwinProcess.Continue(AProcess: TDbgProcess; AThread: TDbgThread): boolean;
var
  e: integer;
begin
  fpseterrno(0);
{$ifdef linux}
  fpPTrace(PTRACE_CONT, ProcessID, nil, nil);
{$endif linux}
{$ifdef darwin}
  if (AThread.SingleStepping) or assigned(FCurrentBreakpoint) then
    fpPTrace(PTRACE_SINGLESTEP, ProcessID, pointer(1), pointer(FExceptionSignal))
  else if FIsTerminating then
    fpPTrace(PTRACE_KILL, ProcessID, pointer(1), nil)
  else
    fpPTrace(PTRACE_CONT, ProcessID, pointer(1), pointer(FExceptionSignal));
{$endif darwin}
  e := fpgeterrno;
  if e <> 0 then
    begin
    writeln('Failed to continue process. Errcode: ',e);
    result := false;
    end
  else
    result := true;
end;

function TDbgDarwinProcess.WaitForDebugEvent(out ProcessIdentifier, ThreadIdentifier: THandle): boolean;
var
  aKernResult: kern_return_t;
  act_list: thread_act_array_t;
  act_listCtn: mach_msg_type_number_t;
begin
  ThreadIdentifier:=-1;

  ProcessIdentifier:=FpWaitPid(-1, FStatus, 0);

  result := ProcessIdentifier<>-1;
  if not result then
    Log('Failed to wait for debug event. Errcode: %d', [fpgeterrno])
  else if (WIFSTOPPED(FStatus)) then
    begin
    aKernResult := task_threads(FTaskPort, act_list, act_listCtn);
    if aKernResult <> KERN_SUCCESS then
      begin
      Log('Failed to call task_threads. Mach error: '+mach_error_string(aKernResult));
      end;

    if act_listCtn>0 then
      ThreadIdentifier := act_list^[0];
    end
end;

function TDbgDarwinProcess.ResolveDebugEvent(AThread: TDbgThread): TFPDEvent;

var
  ExceptionAddr: TDBGPtr;

begin
  FExceptionSignal:=0;
  if wifexited(FStatus) or wifsignaled(FStatus) then
    begin
    SetExitCode(wexitStatus(FStatus));
    writeln('Exit');
    // Clear all pending signals
    repeat
    until FpWaitPid(-1, FStatus, WNOHANG)<1;

    result := deExitProcess
    end
  else if WIFSTOPPED(FStatus) then
    begin
    writeln('Stopped ',FStatus, ' signal: ',wstopsig(FStatus));
    TDbgDarwinThread(AThread).ReadThreadState;
    case wstopsig(FStatus) of
      SIGTRAP:
        begin
        if not FProcessStarted then
          begin
          result := deCreateProcess;
          FProcessStarted:=true;
          end
        else if assigned(FCurrentBreakpoint) then
          begin
          FCurrentBreakpoint.SetBreak;
          FCurrentBreakpoint:=nil;
          if FMainThread.SingleStepping then
            result := deBreakpoint
          else
            result := deInternalContinue;
          end
        else
          result := deBreakpoint;

        // Handle the breakpoint also if it is reached by single-stepping.
        ExceptionAddr:=GetInstructionPointerRegisterValue;
        if not (FMainThread.SingleStepping or assigned(FCurrentBreakpoint)) then
          begin
          TDbgDarwinThread(FMainThread).FNeedIPDecrement:=true;
          dec(ExceptionAddr);
          end
        else
          TDbgDarwinThread(FMainThread).FNeedIPDecrement:=false;
        if DoBreak(ExceptionAddr, FMainThread.ID) then
          result := deBreakpoint;
        end;
      SIGBUS:
        begin
        ExceptionClass:='SIGBUS';
        FExceptionSignal:=SIGBUS;
        result := deException;
        end;
      SIGINT:
        begin
        ExceptionClass:='SIGINT';
        FExceptionSignal:=SIGINT;
        result := deException;
        end;
      SIGSEGV:
        begin
        ExceptionClass:='SIGSEGV';
        FExceptionSignal:=SIGSEGV;
        result := deException;
        end;
      SIGKILL:
        begin
        if FIsTerminating then
          result := deInternalContinue
        else
          begin
          ExceptionClass:='SIGKILL';
          FExceptionSignal:=SIGKILL;
          result := deException;
          end;
        end;
      else
        begin
        ExceptionClass:='Unknown exception code '+inttostr(wstopsig(FStatus));
        FExceptionSignal:=wstopsig(FStatus);
        result := deException;
        end;
    end; {case}
    if result=deException then
      ExceptionClass:='External: '+ExceptionClass;
    end
  else
    raise exception.CreateFmt('Received unknown status %d from process with pid=%d',[FStatus, ProcessID]);
end;

end.
