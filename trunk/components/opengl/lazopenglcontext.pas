{ This file was automatically created by Lazarus. Do not edit!
This source is only used to compile and install the package.
 }

unit LazOpenGLContext; 

interface

uses
  openglcontext, LazarusPackageIntf; 

implementation

procedure Register; 
begin
  RegisterUnit('openglcontext', @openglcontext.Register); 
end; 

initialization
  RegisterPackage('LazOpenGLContext', @Register); 
end.
