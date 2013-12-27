{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

-------------------------------------------------------------------------------}

(*
  This is a wrapper around Synedits internal Storage. It allows TString based
  access to the Text.
  It relieves SynEditTextBase from having to support the full TStrings interface.
  It also hides all of the other methods that SynEditTextBase provides
*)

unit SynEditLines;

{$I synedit.inc}

interface

uses
  Classes, SysUtils, FileUtil, FPCAdds, SynEditTextBase;

type

  TSavedNotification = Procedure of Object;

  { TSynEditLines }

  TSynEditLines = class(TStrings)
  private
    fDosFileFormat: boolean;
    FTextBuffer: TSynEditStrings;
    FOnSaved: TSavedNotification;
  protected
    function Get(Index: integer): string; override;
    function GetCapacity: integer;
      {$IFDEF SYN_COMPILER_3_UP} override; {$ENDIF}                             //mh 2000-10-18
    function GetCount: integer; override;
    function GetObject(Index: integer): TObject; override;
    procedure Put(Index: integer; const S: string); override;
    procedure PutObject(Index: integer; AObject: TObject); override;
    procedure SetCapacity(NewCapacity: integer);
                                   {$IFDEF SYN_COMPILER_3_UP} override; {$ENDIF}
    procedure SetUpdateState(Updating: Boolean); override;
  public
    constructor Create(ATextBuffer: TSynEditStrings; OnSaved: TSavedNotification);
    function Add(const S: string): integer; override;
    procedure AddStrings(AStrings: TStrings); override;
    procedure Clear; override;
    procedure Delete(Index: integer); override;
    procedure Insert(Index: integer; const S: string); override;
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromFile(const FileName: string); override;
    procedure SaveToFile(const FileName: string); override;
    property DosFileFormat: boolean read fDosFileFormat write fDosFileFormat;
  end;

implementation

type

{ TSynEditFiler }

  TSynEditFiler = class(TObject)
  protected
    fBuffer: PChar;
    fBufPtr: Cardinal;
    fBufSize: Cardinal;
    fDosFile: boolean;
    fFiler: TFileStream;
    procedure Flush; virtual;
    procedure SetBufferSize(NewSize: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;
  public
    property DosFile: boolean read fDosFile write fDosFile;
  end;

constructor TSynEditFiler.Create;
const
  kByte = 1024;
begin
  inherited Create;
  fDosFile := FALSE;
  SetBufferSize(16 * kByte);
  fBuffer[0] := #0;
end;

destructor TSynEditFiler.Destroy;
begin
  Flush;
  fFiler.Free;
  SetBufferSize(0);
  inherited Destroy;
end;

procedure TSynEditFiler.Flush;
begin
end;

procedure TSynEditFiler.SetBufferSize(NewSize: Cardinal);
begin
  if NewSize <> fBufSize then begin
    ReallocMem(fBuffer, NewSize);
    fBufSize := NewSize;
  end;
end;

{ TSynEditFileReader }

type
  TSynEditFileReader = class(TSynEditFiler)
  protected
    fFilePos: TStreamSeekType;
    fFileSize: TStreamSeekType;
    procedure FillBuffer;
  public
    constructor Create(const FileName: string);
    function EOF: boolean;
    function ReadLine: string;
  end;

constructor TSynEditFileReader.Create(const FileName: string);
begin
  inherited Create;
  fFiler := TFileStream.Create(UTF8ToSys(FileName), fmOpenRead{ ToDo: or fmShareDenyWrite});
  fFileSize := fFiler.Size;
  fFiler.Seek(0, soFromBeginning);
end;

function TSynEditFileReader.EOF: boolean;
begin
  Result := (fBuffer[fBufPtr] = #0) and (fFilePos >= fFileSize);
end;

procedure TSynEditFileReader.FillBuffer;
var
  Count: Cardinal;
begin
  if fBufPtr >= fBufSize - 1 then
    fBufPtr := 0;
  Count := fFileSize - fFilePos;
  if Count >= fBufSize - fBufPtr then
    Count := fBufSize - fBufPtr - 1;
  fFiler.ReadBuffer(fBuffer[fBufPtr], Count);
  fBuffer[fBufPtr + Count] := #0;
  fFilePos := fFilePos + Count;
  fBufPtr := 0;
end;

function TSynEditFileReader.ReadLine: string;
var
  E, P, S: PChar;
begin
  Result := '';
  repeat
    S := PChar(@fBuffer[fBufPtr]);
    if S[0] = #0 then begin
      FillBuffer;
      S := PChar(@fBuffer[0]);
    end;
    E := PChar(@fBuffer[fBufSize]);
    P := S;
    while P + 2 < E do begin
      case P[0] of
        #10, #13:
          begin
            SetString(Result, S, P - S);
            {$IFDEF SYN_LAZARUS}
            // a single #13 is used in Mac OS files
            if (P[0] = #13) and (P[1] = #10) then begin
            {$ELSE}
            if P[0] = #13 then begin
            {$ENDIF}
              fDosFile := TRUE;
              Inc(P);
            end;
            Inc(P);
            fBufPtr := P - fBuffer;
            exit;
          end;
        #0:
          if fFilePos >= fFileSize then begin
            fBufPtr := P - fBuffer;
            SetString(Result, S, P - S);
            exit;
          end;
      end;
      Inc(P);
    end;
    // put the partial string to the start of the buffer, and refill the buffer
    Inc(P);
    if S > fBuffer then
      StrLCopy(fBuffer, S, P - S);
    fBufPtr := P - S;
    fBuffer[fBufPtr] := #0;
    // if line is longer than half the buffer then grow it first
    if 2 * Cardinal(P - S) > fBufSize then
      SetBufferSize(fBufSize + fBufSize);
  until FALSE;
end;

{ TSynEditFileWriter }

type
  TSynEditFileWriter = class(TSynEditFiler)
  protected
    procedure Flush; override;
  public
    constructor Create(const FileName: string);
    procedure WriteLine(const S: string);
  end;

constructor TSynEditFileWriter.Create(const FileName: string);
begin
  inherited Create;
  fFiler := TFileStream.Create(UTF8ToSys(FileName), fmCreate);
  fFiler.Seek(0, soFromBeginning);
end;

procedure TSynEditFileWriter.Flush;
begin
  if fBufPtr > 0 then begin
    fFiler.WriteBuffer(fBuffer[0], fBufPtr);
    fBufPtr := 0;
  end;
end;

procedure TSynEditFileWriter.WriteLine(const S: string);
var
  L, NL: Cardinal;
begin
  L := Length(S);
  NL := 1 + Ord(fDosFile);
  repeat
    if fBufPtr + L + NL <= fBufSize then begin
      if L > 0 then begin
        Move(S[1], fBuffer[fBufPtr], L);
        fBufPtr := fBufPtr + L;
      end;
      if fDosFile then begin
        fBuffer[fBufPtr] := #13;
        Inc(fBufPtr);
      end;
      fBuffer[fBufPtr] := #10;
      Inc(fBufPtr);
      exit;
    end;
    Flush;
    if L + NL > fBufSize then
      SetBufferSize(L + NL);
  until FALSE;
end;

{ TSynEditLines }

constructor TSynEditLines.Create(ATextBuffer: TSynEditStrings; OnSaved: TSavedNotification);
begin
  inherited Create;
  FTextBuffer := ATextBuffer;
  FOnSaved := OnSaved;
end;

function TSynEditLines.Get(Index: integer): string;
begin
  Result := FTextBuffer[Index];
end;

function TSynEditLines.GetCapacity: integer;
begin
  Result := FTextBuffer.Capacity;
end;

function TSynEditLines.GetCount: integer;
begin
  Result := FTextBuffer.Count;
end;

function TSynEditLines.GetObject(Index: integer): TObject;
begin
  Result := FTextBuffer.Objects[Index];
end;

procedure TSynEditLines.Put(Index: integer; const S: string);
begin
  FTextBuffer[Index] := S;
end;

procedure TSynEditLines.PutObject(Index: integer; AObject: TObject);
begin
  FTextBuffer.Objects[Index] := AObject;
end;

procedure TSynEditLines.SetCapacity(NewCapacity: integer);
begin
  FTextBuffer.Capacity := NewCapacity;
end;

procedure TSynEditLines.SetUpdateState(Updating: Boolean);
begin
  if Updating then
    FTextBuffer.BeginUpdate
  else
    FTextBuffer.EndUpdate;
end;

function TSynEditLines.Add(const S: string): integer;
begin
  Result := FTextBuffer.Add(S);
end;

procedure TSynEditLines.AddStrings(AStrings: TStrings);
begin
  FTextBuffer.AddStrings(AStrings);
end;

procedure TSynEditLines.Clear;
begin
  FTextBuffer.Clear;
end;

procedure TSynEditLines.Delete(Index: integer);
begin
  FTextBuffer.Delete(Index);
end;

procedure TSynEditLines.Insert(Index: integer; const S: string);
begin
  FTextBuffer.Insert(Index, S);
end;

procedure TSynEditLines.Assign(Source: TPersistent);
begin
  FTextBuffer.Assign(Source);
end;

procedure TSynEditLines.LoadFromFile(const FileName: string);
var
  Reader: TSynEditFileReader;
begin
  Reader := TSynEditFileReader.Create(FileName);
  try
    BeginUpdate;
    try
      Clear;
      while not Reader.EOF do
        Add(Reader.ReadLine);
      fDosFileFormat := Reader.DosFile;
    finally
      EndUpdate;
    end;
  finally
    Reader.Free;
  end;
end;

procedure TSynEditLines.SaveToFile(const FileName: string);
var
  Writer: TSynEditFileWriter;
  i: integer;
begin
  Writer := TSynEditFileWriter.Create(FileName);
  try
    Writer.DosFile := fDosFileFormat;
    for i := 0 to Count - 1 do
      Writer.WriteLine(Get(i));
  finally
    Writer.Free;
  end;
  If Assigned(FOnSaved) then FOnSaved();
end;

end.
