{ This file was automatically created by Lazarus. Do not edit!
This source is only used to compile and install the package.
 }

unit RunTimeTypeInfoControls; 

interface

uses
  rttictrls, rttigrids, LazarusPackageIntf; 

implementation

procedure Register; 
begin
  RegisterUnit('rttictrls', @rttictrls.Register); 
  RegisterUnit('rttigrids', @rttigrids.Register); 
end; 

initialization
  RegisterPackage('RunTimeTypeInfoControls', @Register); 
end.
