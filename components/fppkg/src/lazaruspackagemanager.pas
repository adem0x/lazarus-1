{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazarusPackageManager; 

interface

uses
  LazPackageManagerIntf, LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit('LazPackageManagerIntf', @LazPackageManagerIntf.Register); 
end; 

initialization
  RegisterPackage('LazarusPackageManager', @Register); 
end.
