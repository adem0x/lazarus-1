{%MainUnit ../dbctrls.pas}
{
 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

{ TDBMemo }

function TDBMemo.GetDataField: string;
begin
  Result:=FDataLink.FieldName;
end;

function TDBMemo.GetDataSource: TDataSource;
begin
  Result:=FDataLink.DataSource;
end;

function TDBMemo.GetField: TField;
begin
  Result:=FDataLink.Field;
end;

function TDBMemo.GetReadOnly: Boolean;
begin
  Result:=FDataLink.ReadOnly;
end;

procedure TDBMemo.SetAutoDisplay(const AValue: Boolean);
begin
  if FAutoDisplay=AValue then exit;
  FAutoDisplay:=AValue;
  if FAutoDisplay then LoadMemo;
end;

procedure TDBMemo.SetDataField(const AValue: string);
begin
  FDataLink.FieldName:=AValue;
end;

procedure TDBMemo.SetDataSource(const AValue: TDataSource);
begin
  if not (FDataLink.DataSourceFixed and (csLoading in ComponentState)) then
    FDataLink.DataSource:=AValue;
  if AValue<>nil then
    AValue.FreeNotification(Self);
end;

procedure TDBMemo.SetReadOnly(const AValue: Boolean);
begin
  FDataLink.ReadOnly:=AValue;
end;

function TDBMemo.WordWrapIsStored: boolean;
begin
  Result:=not WordWrap;
end;

procedure TDBMemo.DataChange(Sender: TObject);
begin
  if FDataLink.Field<>nil then begin
    if FDataLink.Field.IsBlob then begin
      if FAutoDisplay or (FDataLink.Editing and FDBMemoLoaded) then begin
        FDBMemoLoaded:=False;
        LoadMemo;
      end else begin
        Text:=Format('(%s)', [FDataLink.Field.DisplayLabel]);
        FDBMemoLoaded:=False;
      end;
    end else begin
      if FDBMemoFocused and FDataLink.CanModify then
        Text:=FDataLink.Field.Text
      else
        Text:=FDataLink.Field.DisplayText;
      FDBMemoLoaded:=True;
    end
  end else begin
    if csDesigning in ComponentState then
      Text:=Name
    else
      Text:='';
    FDBMemoLoaded:=False;
  end;
end;

procedure TDBMemo.EditingChange(Sender: TObject);
begin
  inherited ReadOnly:=not (FDataLink.Editing and FDBMemoLoaded);
end;

procedure TDBMemo.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation=opRemove) then begin
    if (FDataLink<>nil) and (AComponent=DataSource) then
      DataSource:=nil;
  end;
end;

procedure TDBMemo.UpdateData(Sender: TObject);
begin
  FDataLink.Field.AsString:=Text;
end;

constructor TDBMemo.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  ControlStyle:=ControlStyle+[csReplicatable];
  FAutoDisplay:=True;
  FDataLink:=TFieldDataLink.Create;
  FDataLink.Control:=Self;
  FDataLink.OnDataChange:=@DataChange;
  FDataLink.OnEditingChange:=@EditingChange;
  FDataLink.OnUpdateData:=@UpdateData;
  inherited ReadOnly:=True;
end;

procedure TDBMemo.FocusRequest(Sender: TObject);
begin
  //the FieldLink has requested the control
  //recieve focus for some reason..
  //perhaps an error occured?
  SetFocus;
end;

procedure TDBMemo.Loaded;
begin
  inherited Loaded;
  if (csDesigning in ComponentState) then
    DataChange(Self);
end;

procedure TDBMemo.EditingDone;
begin
  FDataLink.UpdateRecord;
  inherited EditingDone;
end;

procedure TDBMemo.Change;
begin
  FDatalink.Modified;
  inherited Change;
end;

procedure TDBMemo.KeyPress(var Key: Char);
  function CheckValidChar: boolean;
  begin
    result := FDBMemoLoaded and (FDatalink.Field<>nil) and
      FDatalink.Field.IsValidChar(Key);
    if Result then
      FDatalink.Edit
    else
      Key := #0;
  end;
  function CheckEditingKey: boolean;
  begin
    result := FDbMemoLoaded;
    if Result then
      FDatalink.Edit
    else
      Key := #0;
  end;
begin
  inherited KeyPress(Key);
  case key of
    #32..#255: // alphabetic characters
      CheckValidChar;
    ^M: // enter key
      if not CheckEditingKey then
        LoadMemo;
    #27: // escape
      if FDbMemoLoaded then
        FDatalink.Reset
      else
        Key:=#0;
    ^X,^V, #8: // special keys
      CheckEditingKey;
    else
      Key := #0;
  end;
end;

procedure TDBMemo.WndProc(var AMessage: TLMessage);
begin
  case AMessage.Msg of
    LM_CLEARSEL,
    LM_CUTTOCLIP,
    LM_PASTEFROMCLIP:
      FDatalink.Edit;
  end;
  inherited WndProc(AMessage);
end;

destructor TDBMemo.Destroy;
begin
  FDataLink.Free;
  FDataLink:=nil;
  inherited Destroy;
end;

procedure TDBMemo.LoadMemo;
begin
  if not FDBMemoLoaded and (FDataLink.Field<>nil)
  and FDataLink.Field.IsBlob then begin
    try
      Lines.Text:=FDataLink.Field.AsString;
      FDBMemoLoaded:=True;
    except
      on E:EInvalidOperation do
        Lines.Text:='('+E.Message+')';
    end;
    EditingChange(Self);
  end;
end;

// included by dbctrls.pas
