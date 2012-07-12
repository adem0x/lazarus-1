unit StringsConverter;

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is StringsConverter, released May 2003.
The Initial Developer of the Original Code is Anthony Steele. 
Portions created by Anthony Steele are Copyright (C) 1999-2000 Anthony Steele.
All Rights Reserved. 
Contributor(s): Anthony Steele. 

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations 
under the License.

Alternatively, the contents of this file may be used under the terms of
the GNU General Public License Version 2 or later (the "GPL") 
See http://www.gnu.org/licenses/gpl.html
------------------------------------------------------------------------------*)
{*)}

{$I JcfGlobal.inc}

interface

uses
  { delphi }
  Classes,
  { local }
  Converter;

type
  TStringsConverter = class(TObject)
  private
    fcMessageStrings: TStrings;

    procedure SetMessageStrings(const pcStrings: TStrings);
    function GetMessageStrings: TStrings;

  protected
    function OriginalFileName: string;

    procedure SendStatusMessage(const psFile, psMessage: string;
      const piY, piX: integer);

  public
    constructor Create;

    procedure Convert;

    property MessageStrings: TStrings Read GetMessageStrings Write SetMessageStrings;
  end;


implementation

uses SysUtils;

constructor TStringsConverter.Create;
begin
  inherited;
  fcMessageStrings := nil;
end;


procedure TStringsConverter.Convert;
begin
  // show message on popup if there is no message output
  //GuiMessages := (fcMessageStrings = nil);

  //DoConvertUnit;
end;

function TStringsConverter.GetMessageStrings: TStrings;
begin
  Result := fcMessageStrings;
end;


function TStringsConverter.OriginalFileName: string;
begin
  Result := 'text';
end;

procedure TStringsConverter.SetMessageStrings(const pcStrings: TStrings);
begin
  fcMessageStrings := pcStrings;
end;

procedure TStringsConverter.SendStatusMessage(const psFile, psMessage: string;
  const piY, piX: integer);
var
  lsWholeMessage: string;
begin
  if fcMessageStrings <> nil then
  begin
    lsWholeMessage := psMessage;
    if (piY >= 0) and (piX >= 0) then
      lsWholeMessage := lsWholeMessage + ' at line ' + IntToStr(piY) +
        ' col ' + IntToStr(piX);


    fcMessageStrings.Add(lsWholeMessage);
  end;

end;

end.
