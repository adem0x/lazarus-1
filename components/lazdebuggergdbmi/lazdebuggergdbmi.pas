{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazDebuggerGdbmi;

interface

uses
  CmdLineDebugger, DebugUtils, GDBTypeInfo, GDBMIMiscClasses, IDEMiniLibC, GDBMIDebugger, 
  GDBMIDebugInstructions, GDBMIServerDebugger, SSHGDBMIDebugger, GdbmiStringConstants, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('LazDebuggerGdbmi', @Register);
end.
