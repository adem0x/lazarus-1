{%MainUnit ../comctrls.pp}
{ $Id$

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

{------------------------------------------------------------------------------}
{   TListItems Constructor                                                     }
{------------------------------------------------------------------------------}
constructor TListItems.Create(AOwner : TCustomListView);
begin
  Inherited Create;
  FItems := TList.Create;
  FOwner := AOwner;
  FCacheIndex := -1;
end;

{------------------------------------------------------------------------------}
{   TListItems GetCount                                                        }
{------------------------------------------------------------------------------}
function TListItems.GetCount : Integer;
begin
  Result:=FItems.Count;
end;

{------------------------------------------------------------------------------}
{   TListItems GetItem                                                         }
{------------------------------------------------------------------------------}
function TListItems.GetItem(const AIndex: Integer): TListItem;
begin
  if (FCacheIndex <> -1) and (FCacheIndex = AIndex)
  then begin
    Result := FCacheItem;
    Exit;
  end;
  
  if FItems.Count - 1 < AIndex
  then Result := nil
  else begin
    Result := TListItem(FItems.Items[AIndex]);
    FCacheItem := Result;
    FCacheIndex := AIndex;
  end;
end;

{------------------------------------------------------------------------------}
{   TListItems SetItem                                                         }
{------------------------------------------------------------------------------}
procedure TListItems.SetItem(const AIndex: Integer; const AValue: TListItem);
var
  OldItem: TListItem;
begin
  if FItems.Count - 1 < AIndex then Exit;
  
  OldItem := GetItem(AIndex);
  if OldItem = AValue then Exit;
  
  FItems.Items[AIndex] := AValue;
  FCacheIndex := AIndex;
  FCacheItem := AValue;
  
  if AValue.IntfUpdateAllowed
  then begin
    AValue.IntfUpdateText;
    AValue.IntfUpdateImages;
  end;
end;

{------------------------------------------------------------------------------}
{   TListItems Add                                                             }
{------------------------------------------------------------------------------}
function TListItems.Add: TListItem;
begin
  Result := TListItem.Create(self);
  AddItem(Result);
end;

{------------------------------------------------------------------------------}
{   TListItems AddItem                                                         }
{------------------------------------------------------------------------------}
procedure TListItems.AddItem(AItem: TListItem);
begin
  FCacheIndex := FItems.Add(AItem);
  FCacheItem := AItem;

  //Notify parent TListView that something was added.
  if FOwner <> nil
  then FOwner.ItemInserted(AItem, FCacheIndex);
end;

{------------------------------------------------------------------------------
   TListItems Clear
------------------------------------------------------------------------------}
procedure TListItems.Clear;
begin
  while Count > 0 do Delete(Count-1);
end;

{------------------------------------------------------------------------------}
{   TListItems Delete                                                          }
{------------------------------------------------------------------------------}
procedure TListItems.Delete(const AIndex: Integer);
begin
  Item[AIndex].Delete;
end;

{------------------------------------------------------------------------------}
{   TListItems ItemDeleted                                                     }
{------------------------------------------------------------------------------}
procedure TListItems.ItemDeleted(const AItem: TListItem);
var
  idx: Integer;
begin
  idx := FItems.IndexOf(AItem);
  if FOwner <> nil
  then FOwner.ItemDeleted(idx);
  if FCacheIndex = idx 
  then FCacheIndex := -1;
  FItems.Remove(AItem);
end;

{------------------------------------------------------------------------------}
{   TListItems IndexOf                                                         }
{------------------------------------------------------------------------------}
function TListItems.IndexOf(const AItem: TListItem): Integer;
begin
  if  (FCacheIndex <> -1) 
  and (FCacheItem = AItem)
  then begin
    Result := FCacheIndex;
    Exit;
  end;
  
  Result := FItems.IndexOf(AItem);
  if Result = -1 then Exit;
  
  FCacheIndex := Result;
  FCacheItem := AItem;
end;

{------------------------------------------------------------------------------}
{   TListItems Insert                                                          }
{------------------------------------------------------------------------------}
function TListItems.Insert(const AIndex: Integer): TListItem;
begin
  Result := TListItem.Create(self);
  InsertItem(Result, AIndex);
end;

{------------------------------------------------------------------------------}
{   TListItems InsertItem                                                      }
{------------------------------------------------------------------------------}
procedure TListItems.InsertItem(AItem: TListItem; const AIndex: Integer);
begin
  FItems.Insert(AIndex, AItem);
  FCacheIndex := AIndex;
  FCacheItem := AItem;

  //Notify parent TListView that something was added.
  if FOwner <> nil
  then FOwner.ItemInserted(AItem, AIndex);
end;

{------------------------------------------------------------------------------}
{   TListItems Destructor                                                      }
{------------------------------------------------------------------------------}
destructor TListItems.Destroy;
begin
  FCacheIndex := 0;
  while FItems.Count > 0 do
  begin
    FCacheItem := TListItem(FItems[0]);
    FCacheItem.Free;
  end;
  FCacheIndex := -1;
  FreeAndNil(FItems);
  inherited Destroy;
end;

{------------------------------------------------------------------------------}
{   TListItems FindData                                                        }
{------------------------------------------------------------------------------}
function TListItems.FindData(const AData: Pointer): TListItem;
var
  n: Integer;
begin
  if  (FCacheIndex <> -1) 
  and (FCacheItem <> nil) 
  and (FCacheItem.Data = AData)
  then begin
    Result := FCacheItem;
    Exit;
  end;
  
  for n := 0 to FItems.Count - 1 do
  begin
    Result := TListItem(FItems[n]);
    if Result.Data = AData 
    then begin
      FCacheIndex := n;
      FCacheItem := Result;
      Exit;
    end;
  end;          
  
  Result := nil;
end;

{------------------------------------------------------------------------------}
{   TListItems DefineProperties                                                }
{------------------------------------------------------------------------------}
procedure TListItems.DefineProperties(Filer: TFiler);

  function WriteItems: Boolean;
  var
    I: Integer;
    Items: TListItems;
  begin
    Items := TListItems(Filer.Ancestor);
    if not Assigned(Items) then
      Result := Count > 0
    else if (Items.Count <> Count) then
             Result := True
    else
    begin
      Result := False;
      for I := 0 to Count - 1 do
      begin
        Result := not Item[I].IsEqual(Items[I]);
        if Result then Break;
      end
    end;
  end;

begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Data', @ReadData, @WriteData, WriteItems);
end;

type
  PItemHeader = ^TItemHeader;
  TItemHeader = packed record
    Size, Count: Integer;
    Items: record end;
  end;
  PItemInfo = ^TItemInfo;
  TItemInfo = packed record
    ImageIndex: Integer;
    StateIndex: Integer;
    OverlayIndex: Integer;
    SubItemCount: Integer;
    Data: Pointer;
    Caption: string[255];
  end;
  ShortStr = string[255];
  PShortStr = ^ShortStr;
  PInteger  = ^Integer;
  
procedure TListItems.ReadData(Stream: TStream);
var
  I, J, Size, L, Len: Integer;
  ItemHeader: PItemHeader;
  ItemInfo: PItemInfo;
  PStr: PShortStr;
  PInt: PInteger;
  ListItem: TListItem;
  SubCount: Integer;
begin
  Clear;
  //Flag:=False;
  Size:=ReadLRSInteger(Stream);
  ItemHeader := AllocMem(Size);
  Owner.BeginUpdate;
  try
    ItemHeader^.Count:=ReadLRSInteger(Stream);
    Stream.ReadBuffer(ItemHeader^.Items, Size - 8);
    ItemInfo := @ItemHeader^.Items;
    PStr := nil;
    for I := 0 to ItemHeader^.Count - 1 do
    begin
      ListItem := Add;
      ListItem.Caption := ItemInfo^.Caption;
      ListItem.ImageIndex := LEtoN(ItemInfo^.ImageIndex);
      // ListItem.StateIndex := LEtoN(ItemInfo^.StateIndex);
      // ListItem.OverlayIndex := LEtoN(ItemInfo^.OverlayIndex);

      //TODO: check if we need to stream a data pointer
      ListItem.Data := Pointer(LEtoN(PtrInt(ItemInfo^.Data)));
      
      PStr := @ItemInfo^.Caption;
      Inc(Integer(PStr), Length(PStr^) + 1);
      Len := 0;
      SubCount := LEtoN(ItemInfo^.SubItemCount);
      for J := 0 to SubCount - 1 do
      begin
        ListItem.SubItems.Add(PStr^);
        L := Length(PStr^);
        Inc(Len, L + 1);
        Inc(Integer(PStr), L + 1);
      end;

      Inc(Integer(ItemInfo), SizeOf(TItemInfo)-255+Length(ItemInfo^.Caption)+Len);
    end;
    
    //read subitem images
    if PChar(PStr) - PChar(ItemHeader) < Size then
    begin
      PInt := Pointer(PStr);
      for I := 0 to Count - 1 do
      begin
        if Item[I].FSubItems <> nil
        then begin
          for J := 0 to Item[I].SubItems.Count - 1 do
          begin
            Item[I].SubItemImages[J] := LEtoN(PInt^);
            Inc(PInt);
          end;
        end;
      end;
    end;
  finally
    FreeMem(ItemHeader, Size);
    Owner.EndUpdate;
  end;
end;

procedure TListItems.WriteData(Stream: TStream);
var
  I, J, Size, L, Len : Integer;
  ItemHeader         : PItemHeader;
  ItemInfo           : PItemInfo;
  PStr               : PShortStr;
  PInt               : PInteger;
  
  function GetLength(const S: string): Integer;
  begin
    Result := Length(S);
    if Result > 255 then Result := 255;
  end;

begin
  Size := SizeOf(TItemHeader);
  for I := 0 to Count - 1 do
  begin
    L := GetLength(Item[I].Caption) + 1;
    for J := 0 to Item[I].SubItems.Count - 1 do
    begin
      Inc(L, GetLength(Item[I].SubItems[J]) + 1);
      Inc(L, SizeOf(Integer));
    end;
    Inc(Size, SizeOf(TItemInfo) - 255 + L);
  end;
  ItemHeader := AllocMem(Size);
  try
    ItemHeader^.Size := NtoLE(Size);
    ItemHeader^.Count := NtoLE(Count);
    ItemInfo := @ItemHeader^.Items;
    PStr := nil;
    for I := 0 to Count - 1 do
    begin
      with Item[I] do
      begin
        ItemInfo^.Caption := Caption;
        ItemInfo^.ImageIndex := NtoLE(ImageIndex);
        ItemInfo^.StateIndex := NtoLE(Integer(-1)) {StateIndex};
        ItemInfo^.OverlayIndex := NtoLE(Integer(-1)) {OverlayIndex};
        ItemInfo^.SubItemCount := NtoLE(SubItems.Count);
        // TODO: check this
        // Stream pointers ???
        ItemInfo^.Data := Pointer(NtoLE(PtrInt(Data)));
        PStr := @ItemInfo^.Caption;
        Inc(Pointer(PStr), Length(ItemInfo^.Caption) + 1);
        Len := 0;
        for J := 0 to SubItems.Count - 1 do
        begin
          PStr^ := SubItems[J];
          L := Length(PStr^);
          Inc(Len, L + 1);
          Inc(Pointer(PStr), L + 1);
        end;
      end;
      Inc(Integer(ItemInfo), SizeOf(TItemInfo) - 255 +
        Length(ItemInfo^.Caption) + Len);
    end;
    
    //write SubItem images.
    PInt := Pointer(PStr);
    for I := 0 to Count - 1 do
    begin
      for J := 0 to  Item[I].SubItems.Count - 1 do
      begin
        PInt^ := NtoLE(Item[I].SubItemImages[J]);
        Inc(PInt);
      end;
    end;

    Stream.WriteBuffer(ItemHeader^, Size);
  finally
    FreeMem(ItemHeader, Size);
  end;
end;

{ =============================================================================

  $Log$
  Revision 1.26  2004/11/13 17:22:15  marc
  + Added generic endian functions

  Revision 1.25  2004/11/13 15:53:14  marc
  * Fixed endianess

  Revision 1.24  2004/08/15 17:00:58  mattias
  improved DefineProperties to read/write endian independent

  Revision 1.23  2004/07/11 17:20:47  marc
  * Implemented most of TListColoum/Item in the Ws for gtk and win32

  Revision 1.22  2004/06/28 23:16:24  mattias
  added TListView.AddItems  from Andrew Haines

  Revision 1.21  2004/05/21 18:12:17  mattias
  quick fixed crashing property overloading BorderStyle

  Revision 1.20  2004/05/18 23:10:41  marc
  * Started to move TListview to the WS interface

  Revision 1.19  2004/04/10 17:58:57  mattias
  implemented mainunit hints for include files

  Revision 1.18  2004/03/18 22:35:52  mattias
  improved TCustomListView.ItemAdded with an Index param  from Andrew

  Revision 1.17  2003/02/24 19:00:42  mattias
  added TlistView.SubItem improvements from Olivier Guilbaud

  Revision 1.16  2003/02/18 23:22:56  mattias
  added listview items property editor

  Revision 1.15  2002/11/18 13:38:44  mattias
  fixed buffer overrun and added several checks

  Revision 1.14  2002/11/13 18:21:04  lazarus
  MG: added TListItems.Clear

  Revision 1.13  2002/09/14 14:47:41  lazarus
  MG: fixed icons

  Revision 1.12  2002/09/14 08:38:06  lazarus
  MG: added TListView notification from Vincent

  Revision 1.11  2002/05/10 06:05:53  lazarus
  MG: changed license to LGPL

  Revision 1.10  2002/03/24 16:38:01  lazarus
  MWE:
    * Fixed bug on ListItems.Delete

  Revision 1.9  2002/03/23 15:49:22  lazarus
  MWE: Fixed more compatebility issues (Sort, SelectedItem)

}