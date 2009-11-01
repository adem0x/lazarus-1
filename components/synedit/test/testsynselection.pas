unit TestSynSelection;

{$mode objfpc}{$H+}

interface

(* TODO: Known Issues in SynEdit
      - smLine Blocks: Begin/End Points return X values inside the line
      - Go/select to matcing brace, have inconsistent rules which side of the ")" the caret must be
        They should follow the same as bracket highlight?

   TODO: Missing tests
      - Select persistent block, move caret away and back, continue selection
      - Select by Mouse (incl scrolling while selecting)
      - Drag Block (incl scrolling)
      - Replace text
      - persistent block moves on edit
*)
uses
  Classes, SysUtils, fpcunit, testutils, testregistry, TestBase,
  SynEdit, SynEditTypes, SynEditTextTrimmer, SynEditKeyCmds,
  LCLType, LCLProc;

type

  { TTestSynSelection }

  TTestSynSelection = class(TTestBase)
  protected
    (* Testing selection, with any X/Y pair having negative values, will check for No Selection *)
    procedure TestIsBlock(Name: String; X1, Y1, X2, Y2: Integer);
    procedure TestIsBlock(Name: String; X1, Y1, X2, Y2: Integer; Text: String);
    procedure TestIsBlock(Name: String; X1, Y1, X2, Y2: Integer; Text: Array of String);
    procedure TestIsNoBlock(Name: String);
  published
    procedure SelectByKey;

    (* Test for selection via the following Methods:
       SelectWord /.SelectLine / SelectParagraph / SelectAll / SelectToBrace
       [ BeginUpdate; BlockBegin := ; BlockEnd := ; EndUpdatel ]
    *)
    procedure SelectByMethod;

    procedure ReplaceSelText;

    //Temporarily here, till we have more units
    procedure TextDelCmd;
  end;

implementation

procedure TTestSynSelection.TestIsBlock(Name: String; X1, Y1, X2, Y2: Integer);
begin
  if (Y1<0) or (X1 < 0) or (Y2<0) or (X2 < 0) then begin
    TestIsNoBlock(Name);
    exit;
  end;
  if (not SynEdit.SelAvail)
  then
    TestFail(Name, 'IsBlock',
             Format('X/Y=(%d, %d) - (%d, %d)', [X1, Y1, X2, Y2]),
             Format('No Sel Avail (X/Y=(%d, %d) - (%d, %d))', [SynEdit.BlockBegin.X, SynEdit.BlockBegin.Y,
                                                               SynEdit.BlockEnd.X, SynEdit.BlockEnd.Y])
            );
  if (SynEdit.BlockBegin.X <> X1) or (SynEdit.BlockBegin.Y <> Y1) or
     (SynEdit.BlockEnd.X <> X2) or (SynEdit.BlockEnd.Y <> Y2)
  then
    TestFail(Name, 'IsBlock',
             Format('X/Y=(%d, %d) - (%d, %d)', [X1, Y1, X2, Y2]),
             Format('X/Y=(%d, %d) - (%d, %d)', [SynEdit.BlockBegin.X, SynEdit.BlockBegin.Y,
                                                SynEdit.BlockEnd.X, SynEdit.BlockEnd.Y])
            );
end;

procedure TTestSynSelection.TestIsBlock(Name: String; X1, Y1, X2, Y2: Integer; Text: String);
begin
  TestIsBlock(Name, X1, Y1, X2, Y2);
  if (SynEdit.SelText <> Text) then
    TestFail(Name, 'IsBlockText', '"'+DbgStr(Text)+'"', '"'+DbgStr(SynEdit.SelText)+'"');
end;

procedure TTestSynSelection.TestIsBlock(Name: String; X1, Y1, X2, Y2: Integer;
  Text: array of String);
begin
  TestIsBlock(Name, X1, Y1, X2, Y2, LinesToText(Text));
end;

procedure TTestSynSelection.TestIsNoBlock(Name: String);
begin
  if (SynEdit.SelAvail) then
    TestFail(Name, 'IsNoBlock', 'No Selection',
             Format('X/Y=(%d, %d) - (%d, %d) "%s"',
                    [SynEdit.BlockBegin.X, SynEdit.BlockBegin.Y,
                     SynEdit.BlockEnd.X, SynEdit.BlockEnd.Y,
                     '"'+DbgStr(SynEdit.SelText)+'"'])
            );
end;

procedure TTestSynSelection.SelectByKey;
var
  SkipBlockOtherEndBack: Boolean;

  procedure TestKey(Name: String;
                    StartX, StartY: Integer;  Key: Word; Shift: TShiftState;
                    EndX, EndY: Integer;      ExpText: String;
                    ExitKey: Word; ExitShift: TShiftState;
                    ExitX, ExitY, ExitSkippedX, ExitSkippedY: Integer;
                    Persist: Boolean = False );
  var
    IsBackward: Boolean;
    X1, Y1, X2, Y2: Integer;
    SkipKey, SkipBackKey: Word;

    procedure TestOnlyPersitBlock(XName: String = '');
    begin
      if Persist
      then TestIsBlock(XName, X1, Y1, X2, Y2, ExpText)
      else TestIsNoBlock(XName);
    end;
    procedure TestKeySelect(Catch: Boolean = False);      // Simulate Key - Select
    begin
      SetCaret(StartX, StartY);
      TestIsNoBlock('Sanity, after set caret');
      DoKeyPress(Key, Shift);
      if (ExpText = '') and Catch then ExpText := SynEdit.SelText;    // Capture the text, to cmpare with later selections
      TestIsCaret('After Select Key', EndX, EndY);
      TestIsBlock('After Select Key', X1, Y1, X2, Y2, ExpText);
    end;

  begin
    PushBaseName(Name);
    if Persist then
      PushBaseName('Persistent');

    IsBackward := (EndY < StartY) or ( (EndY = StartY) and (EndX < StartX) );
    if IsBackward then begin
      X1 := EndX;      Y1 := EndY;
      X2 := StartX;    Y2 := StartY;
      SkipKey     := VK_RIGHT;
      SkipBackKey := VK_LEFT;
    end else begin
      X1 := StartX;    Y1 := StartY;
      X2 := EndX;      Y2 := EndY;
      SkipKey     := VK_LEFT;
      SkipBackKey := VK_RIGHT;
    end;
    if (SynEdit.SelectionMode = smLine) then begin
      // Todo: Block x are incorect returned in smLine
      //X1 := 1;
      //X2 := length(Synedit.Lines[Y2]);
    end;

    if Persist
    then SynEdit.Options2 := SynEdit.Options2 + [eoPersistentBlock]
    else SynEdit.Options2 := SynEdit.Options2 - [eoPersistentBlock];

    SynEdit.Options  := SynEdit.Options  - [eoNoSelection];
    SynEdit.Options2 := SynEdit.Options2 - [eoCaretSkipsSelection];

    // Select, and Unselect
    PushBaseName       ('Plain Select');
    TestKeySelect      (True);
    DoKeyPress         (ExitKey, ExitShift);
    TestIsCaret        ('After Exit Key', ExitX, ExitY);
    TestOnlyPersitBlock('After Exit Key');

    // if eoCaretSkipsSelection= OFF, then block is unselected, not Skipped
    PopPushBaseName    ('Skip=Off (unselect)');
    TestKeySelect      ();
    DoKeyPress         (SkipKey, []);
    TestOnlyPersitBlock('After Skip Key');

    SynEdit.Options2 := SynEdit.Options2 + [eoCaretSkipsSelection];

    // Block is kept, if caret skips to other end (eoCaretSkipsSelection)
    // Next caret move unselects as normal
    if (ExitKey <> SkipBackKey) or (ExitShift <> []) then begin
      PopPushBaseName    ('Skip=On (keep select)');
      TestKeySelect      ();
      DoKeyPress         (SkipKey, []);
      TestIsBlock        ('After Skip Key', X1, Y1, X2, Y2, ExpText);
      DoKeyPress         (ExitKey, ExitShift);
      TestIsCaret        ('After Exit Key', ExitSkippedX, ExitSkippedY);
      TestOnlyPersitBlock('After Exit Key');
    end;

    // Block is kept, if caret skips to other end and back (eoCaretSkipsSelection)
    // Next caret move unselects as normal
    if ((ExitKey <> SkipKey) or (ExitShift <> [])) and (not SkipBlockOtherEndBack) then begin
      PopPushBaseName    ('Skip=On (keep select, 2nd)');
      TestKeySelect      ();
      DoKeyPress         (SkipKey, []);
      TestIsBlock        ('After Skip Key', X1, Y1, X2, Y2, ExpText);
      DoKeyPress         (SkipBackKey, []);
      TestIsBlock        ('After SkipBack Key', X1, Y1, X2, Y2, ExpText);
      DoKeyPress         (ExitKey, ExitShift);
      TestIsCaret        ('After Exit Key', ExitX, ExitY);
      TestOnlyPersitBlock('After Exit Key');
    end;

    // Switching eoCaretSkipsSelection= OFF while selected is taken ito account on next move
    PopPushBaseName    ('Skip=On/Off');
    TestKeySelect      ();
    DoKeyPress         (SkipKey, []);
    TestIsBlock        ('After Skip Key', X1, Y1, X2, Y2, ExpText);
    SynEdit.Options2 := SynEdit.Options2 - [eoCaretSkipsSelection];
    DoKeyPress         (SkipBackKey, []);
    TestOnlyPersitBlock('After SkipBack Key (Skip=Off)');

    // Switching eoNoSelection=On while selected, clears the block
    PopPushBaseName    ('change eoNoSelection');
    TestKeySelect      ();
    SynEdit.Options  := SynEdit.Options  + [eoNoSelection];
    TestIsNoBlock      ('After setting eoNoSelection');

    // No selection, if eoNoSelection=On
    PopPushBaseName    ('eoNoSelection');
    SetCaret(StartX, StartY);
    TestIsNoBlock('Sanity, after set caret');
    DoKeyPress(Key, Shift);
    TestIsNoBlock('After Select Key');

    SynEdit.Options  := SynEdit.Options  - [eoNoSelection];

    PopBaseName;
    if Persist then
      PopBaseName;
    PopBaseName;

    // Repeat for persistent block
    if not Persist then
      TestKey(Name, StartX, StartY, Key, Shift, EndX, EndY, ExpText,
              ExitKey, ExitShift, ExitX, ExitY, ExitSkippedX, ExitSkippedY,
              True
             );
  end;

  procedure TestKey(Name: String;
                    StartX, StartY: Integer;  Key: Word; Shift: TShiftState;
                    EndX, EndY: Integer;      ExpText: Array of String;
                    ExitKey: Word; ExitShift: TShiftState;
                    ExitX, ExitY, ExitSkippedX, ExitSkippedY: Integer
                   );
  begin
    TestKey(Name, StartX, StartY, Key, Shift, EndX, EndY, LinesToText(ExpText),
            ExitKey, ExitShift, ExitX, ExitY, ExitSkippedX, ExitSkippedY
           );
  end;

begin
  ReCreateEdit;
  BaseTestName := 'SelectByKey';

  (* tests include:
       eoPersistentBlock
       eoCaretSkipsSelection
       eoNoSelection
       eoScrollPastEol
  *)
  // CaretPos are Logical, to save params

  SynEdit.TabWidth := 4;
  SkipBlockOtherEndBack := False;

  SetLines(['begin',
            '  Foo(bar);',
            '  // äüöäabc', // Utf8 2 bytes per char
            #9#9+'test',    // Tab  1 byte / several display cells
            'end;'
           ]);


  PushBaseName('Default:smNormal');
    SynEdit.DefaultSelectionMode := smNormal;
    //      Name                                   Start  Select-Key          Block-End    UnSel-Key     End-Caret/Skipped
    TestKey('S-VK_RIGHT, Exit=VK_RIGHT',            3,2, VK_RIGHT,[ssShift],  4,2, 'F',    VK_RIGHT,[],  5,2, 4,2);
    TestKey('S-VK_RIGHT, Exit=VK_LEFT',             3,2, VK_RIGHT,[ssShift],  4,2, 'F',    VK_LEFT,[],   3,2, 2,2); // VK_LEFT goes back to block begin;
    TestKey('S-VK_RIGHT, Exit=VK_UP',               3,2, VK_RIGHT,[ssShift],  4,2, 'F',    VK_UP,[],     4,1, 3,1);
    TestKey('S-VK_RIGHT, Exit=VK_UP(no move)',      3,1, VK_RIGHT,[ssShift],  4,1, 'g',    VK_UP,[],     4,1, 3,1);

    TestKey('S-VK_RIGHT, Exit=VK_RIGHT utf8',       8,3, VK_RIGHT,[ssShift], 10,3, 'ü',    VK_RIGHT,[], 12,3,10,2);
    TestKey('S-VK_RIGHT, Exit=VK_LEFT utf8',        8,3, VK_RIGHT,[ssShift], 10,3, 'ü',    VK_LEFT,[],   8,3, 6,3);
    // Todo: tab (currently shift-left, from behind a tab, will create blockbegin <> caret

    TestKey('S-VK_LEFT,  Exit=VK_LEFT',             3,2, VK_LEFT,[ssShift],   2,2, ' ',    VK_LEFT,[],   1,2, 2,2);
    TestKey('S-VK_LEFT,  Exit=VK_RIGHT',            3,2, VK_LEFT,[ssShift],   2,2, ' ',    VK_RIGHT,[],  3,2, 4,2);
    SynEdit.Options  := SynEdit.Options  + [eoScrollPastEol];
    TestKey('S-VK_LEFT,  Exit=VK_LEFT(no move)',    2,2, VK_LEFT,[ssShift],   1,2, ' ',    VK_LEFT,[],   1,2, 1,2);
    SynEdit.Options  := SynEdit.Options  - [eoScrollPastEol];

    TestKey('S-VK_UP, Exit=VK_DOWN',                3,2, VK_UP,[ssShift],     3,1, ['gin','  '],  VK_DOWN,[],   3,2, 3,3);

    TestKey('S-VK_END, Exit=VK_END',                7,2, VK_END,[ssShift],   12,2, 'bar);',       VK_END,[],   12,2, 12,2);
    TestKey('S-VK_HOME, Exit=VK_HOME',              3,1, VK_HOME,[ssShift],   1,1, 'be',          VK_HOME,[],   1,1, 1,1);

    TestKey('SC-VK_RIGHT, Exit=C-VK_LEFT (word)',      3,2, VK_RIGHT,[ssShift,ssCtrl], 7,2, 'Foo(',  VK_LEFT,[ssCtrl],   3,2, 6,1);
    TestKey('SC-VK_RIGHT, Exit=C-VK_LEFT (half word)', 4,2, VK_RIGHT,[ssShift,ssCtrl], 7,2, 'oo(',   VK_LEFT,[ssCtrl],   3,2, 3,2);

    SynEdit.Options := SynEdit.Options  + [eoScrollPastEol];
    TestKey('S-VK_LEFT,  Exit=VK_LEFT',             8,1, VK_LEFT,[ssShift],   7,1, '',    VK_LEFT,[],   6,1, 7,1);
    TestKey('S-VK_LEFT,  Exit=VK_RIGHT',            8,1, VK_LEFT,[ssShift],   7,1, '',    VK_RIGHT,[],  8,1, 9,1);

    // Column selection (force horiz move, by going to end of shorter line)
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol, eoKeepCaretX];
    TestKey('SA-VK_UP (Col), Exit=VK_DOWN (PastEOL=Off KeepX=Off)', 10,2, VK_UP,[ssShift, ssAlt],   6,1, ['    ','(bar'],  VK_DOWN,[],   6,2, 14,3); // caret-after-skip + 4 utf8 2 byte
    SkipBlockOtherEndBack := True; // KeepCaretX wouldn't work
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol] + [eoKeepCaretX];
    TestKey('SA-VK_UP (Col), Exit=VK_DOWN (PastEOL=Off KeepX=On)',  10,2, VK_UP,[ssShift, ssAlt],   6,1, ['    ','(bar'],  VK_DOWN,[],  10,2, 14,3); // caret-after-skip + 4 utf8 2 byte
    SkipBlockOtherEndBack := False;


  PopPushBaseName('Default:smColumn');
    SynEdit.DefaultSelectionMode := smColumn;
    //      Name                                      Start  Select-Key          Block-End    UnSel-Key     End-Caret/Skipped
    TestKey('S-VK_RIGHT, Exit=VK_RIGHT',               3,2, VK_RIGHT,[ssShift],  4,2, 'F',    VK_RIGHT,[],  5,2, 4,2);
    TestKey('S-VK_RIGHT, Exit=VK_LEFT',                3,2, VK_RIGHT,[ssShift],  4,2, 'F',    VK_LEFT,[],   3,2, 2,2); // VK_LEFT goes back to block begin;
    SynEdit.Options  := SynEdit.Options  + [eoScrollPastEol];
    TestKey('S-VK_LEFT,  Exit=VK_LEFT(no move)',       2,2, VK_LEFT,[ssShift],   1,2, ' ',    VK_LEFT,[],   1,2, 1,2);
    SynEdit.Options  := SynEdit.Options  - [eoScrollPastEol];

    TestKey('S-VK_END, Exit=VK_END',                   7,2, VK_END,[ssShift],   12,2, 'bar);',       VK_END,[],   12,2, 12,2);
    TestKey('S-VK_HOME, Exit=VK_HOME',                 3,1, VK_HOME,[ssShift],   1,1, 'be',          VK_HOME,[],   1,1, 1,1);
    TestKey('SC-VK_RIGHT, Exit=C-VK_LEFT (word)',      3,2, VK_RIGHT,[ssShift,ssCtrl], 7,2, 'Foo(',  VK_LEFT,[ssCtrl],   3,2, 6,1);
    TestKey('SC-VK_RIGHT, Exit=C-VK_LEFT (half word)', 4,2, VK_RIGHT,[ssShift,ssCtrl], 7,2, 'oo(',   VK_LEFT,[ssCtrl],   3,2, 3,2);

    SynEdit.Options := SynEdit.Options  + [eoScrollPastEol];
    TestKey('S-VK_LEFT,  Exit=VK_LEFT',             8,1, VK_LEFT,[ssShift],   7,1, ' ',    VK_LEFT,[],   6,1, 7,1);
    TestKey('S-VK_LEFT,  Exit=VK_RIGHT',            8,1, VK_LEFT,[ssShift],   7,1, ' ',    VK_RIGHT,[],  8,1, 9,1);

    // Column selection (force horiz move, by going to end of shorter line)
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol, eoKeepCaretX];
    TestKey('SA-VK_UP (Col), Exit=VK_DOWN (PastEOL=Off KeepX=Off)', 10,2, VK_UP,[ssShift, ssAlt],   6,1, ['    ','(bar'],  VK_DOWN,[],   6,2, 14,3); // caret-after-skip + 4 utf8 2 byte
    SkipBlockOtherEndBack := True; // KeepCaretX wouldn't work
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol] + [eoKeepCaretX];
    TestKey('SA-VK_UP (Col), Exit=VK_DOWN (PastEOL=Off KeepX=On)',  10,2, VK_UP,[ssShift, ssAlt],   6,1, ['    ','(bar'],  VK_DOWN,[],  10,2, 14,3); // caret-after-skip + 4 utf8 2 byte
    SkipBlockOtherEndBack := False;


  PopPushBaseName('Default:smLine');
    SynEdit.DefaultSelectionMode := smLine;
    //      Name                                   Start  Select-Key          Block-End              UnSel-Key     End-Caret/Skipped
    TestKey('S-VK_RIGHT, Exit=VK_RIGHT',            3,2, VK_RIGHT,[ssShift],  4,2, ['  Foo(bar);', ''],    VK_RIGHT,[],  5,2, 4,2);
    TestKey('S-VK_RIGHT, Exit=VK_LEFT',             3,2, VK_RIGHT,[ssShift],  4,2, ['  Foo(bar);', ''],    VK_LEFT,[],   3,2, 2,2); // VK_LEFT goes back to block begin;
    TestKey('S-VK_RIGHT, Exit=VK_UP',               3,2, VK_RIGHT,[ssShift],  4,2, ['  Foo(bar);', ''],    VK_UP,[],     4,1, 3,1);
    TestKey('S-VK_RIGHT, Exit=VK_UP(no move)',      3,1, VK_RIGHT,[ssShift],  4,1, ['begin', ''],          VK_UP,[],     4,1, 3,1);

    SynEdit.Options  := SynEdit.Options  + [eoScrollPastEol];
    TestKey('S-VK_LEFT,  Exit=VK_LEFT(no move)',    2,2, VK_LEFT,[ssShift],   1,2, ['  Foo(bar);', ''],    VK_LEFT,[],   1,2, 1,2);
    SynEdit.Options  := SynEdit.Options  - [eoScrollPastEol];

    TestKey('S-VK_UP, Exit=VK_DOWN',                3,2, VK_UP,[ssShift],     3,1, ['begin','  Foo(bar);', ''],  VK_DOWN,[],   3,2, 3,3);
    TestKey('S-VK_END, Exit=VK_END',                7,2, VK_END,[ssShift],   12,2, ['  Foo(bar);', ''],          VK_END,[],   12,2, 12,2);
    TestKey('S-VK_HOME, Exit=VK_HOME',              3,1, VK_HOME,[ssShift],   1,1, ['begin', ''],                VK_HOME,[],   1,1, 1,1);

    TestKey('SC-VK_RIGHT, Exit=C-VK_LEFT (word)',      3,2, VK_RIGHT,[ssShift,ssCtrl], 7,2, ['  Foo(bar);', ''],  VK_LEFT,[ssCtrl],   3,2, 6,1);
    TestKey('SC-VK_RIGHT, Exit=C-VK_LEFT (half word)', 4,2, VK_RIGHT,[ssShift,ssCtrl], 7,2, ['  Foo(bar);', ''],  VK_LEFT,[ssCtrl],   3,2, 3,2);

    SynEdit.Options := SynEdit.Options  + [eoScrollPastEol];
    TestKey('S-VK_LEFT,  Exit=VK_LEFT',             8,1, VK_LEFT,[ssShift],   7,1, ['begin', ''],    VK_LEFT,[],   6,1, 7,1);
    TestKey('S-VK_LEFT,  Exit=VK_RIGHT',            8,1, VK_LEFT,[ssShift],   7,1, ['begin', ''],    VK_RIGHT,[],  8,1, 9,1);

    // Column selection (force horiz move, by going to end of shorter line)
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol, eoKeepCaretX];
    TestKey('SA-VK_UP (Col), Exit=VK_DOWN (PastEOL=Off KeepX=Off)', 10,2, VK_UP,[ssShift, ssAlt],   6,1, ['    ','(bar'],  VK_DOWN,[],   6,2, 14,3); // caret-after-skip + 4 utf8 2 byte
    SkipBlockOtherEndBack := True; // KeepCaretX wouldn't work
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol] + [eoKeepCaretX];
    TestKey('SA-VK_UP (Col), Exit=VK_DOWN (PastEOL=Off KeepX=On)',  10,2, VK_UP,[ssShift, ssAlt],   6,1, ['    ','(bar'],  VK_DOWN,[],  10,2, 14,3); // caret-after-skip + 4 utf8 2 byte
    SkipBlockOtherEndBack := False;


  PopBaseName; // Default:smLine

  // ColumnSelection, Continue after zero width
  SynEdit.DefaultSelectionMode := smNormal;

  PushBaseName('BlockSel through zero width');
  SynEdit.Options2 := SynEdit.Options2 - [eoPersistentBlock];
  SetCaret(3, 1);
  DoKeyPress(VK_RIGHT, [ssShift, ssAlt]);
  TestIsBlock('after VK_RIGHT', 3, 1, 4, 1, 'g');
  DoKeyPress(VK_DOWN, [ssShift, ssAlt]);
  TestIsBlock('after VK_DOWN', 3, 1, 4, 2, ['g', 'F']);
  DoKeyPress(VK_LEFT, [ssShift, ssAlt]);
  TestIsNoBlock('after VK_LEFT (empty)');
  DoKeyPress(VK_LEFT, [ssShift, ssAlt]);
  TestIsBlock('after VK_LEFT (continue)', 3, 1, 2, 2, ['e', ' ']);

  DoKeyPress(VK_RIGHT, [ssShift, ssAlt]);
  TestIsNoBlock('after VK_Right (empty)');
  DoKeyPress(VK_RIGHT, []);
  TestIsNoBlock('after VK_Right (move away)');
  DoKeyPress(VK_LEFT, []);
  TestIsNoBlock('after VK_LEFT (move back)');
  DoKeyPress(VK_LEFT, [ssShift, ssAlt]);
  TestIsBlock('after VK_LEFT (NO continue after away/back)', 2, 2, 3, 2, [' ']);


  PopPushBaseName('BlockSel through zero width (persistent)');
  SynEdit.Options2 := SynEdit.Options2 + [eoPersistentBlock];
  SetCaret(3, 1);
  DoKeyPress(VK_RIGHT, [ssShift, ssAlt]);
  TestIsBlock('after VK_RIGHT', 3, 1, 4, 1, 'g');
  DoKeyPress(VK_DOWN, [ssShift, ssAlt]);
  TestIsBlock('after VK_DOWN', 3, 1, 4, 2, ['g', 'F']);
  DoKeyPress(VK_LEFT, [ssShift, ssAlt]);
  TestIsNoBlock('after VK_LEFT (empty)');
  DoKeyPress(VK_LEFT, [ssShift, ssAlt]);
  TestIsBlock('after VK_LEFT (continue)', 3, 1, 2, 2, ['e', ' ']);

  PopBaseName;
end;

procedure TTestSynSelection.SelectByMethod;
var
  NoSelection : Boolean;
  UseBeginUpdate: Boolean;

  procedure DoTestIsBlock(Name: String; X1, Y1, X2, Y2: Integer; ExpText: Array of String);
  begin
    if NoSelection
    then TestIsNoBlock(Name)
    else begin
      TestIsBlock(Name, X1, Y1, X2, Y2, ExpText);
      TestIsCaret(Name, X2, Y2);
    end;
  end;
  procedure DoTestIsBlockBackward(Name: String; X1, Y1, X2, Y2: Integer; ExpText: Array of String);
  begin
    if NoSelection
    then TestIsNoBlock(Name)
    else begin
      TestIsBlock(Name, X1, Y1, X2, Y2, ExpText);
      TestIsCaret(Name, X1, Y1); // caret at start
    end;
  end;
  procedure DoLock;
  begin
    if UseBeginUpdate then SynEdit.BeginUpdate;
  end;
  procedure DoUnLock;
  begin
    if UseBeginUpdate then SynEdit.EndUpdate;
  end;

  procedure DoSelectByMethod;
  var
    i: Integer;
  Begin
    (* *** smNormal *** *)
    PushBaseName('Default:smNormal');
    SynEdit.DefaultSelectionMode := smNormal;

    // word
    for i := 7 to 11 do begin // includes 11: select previous word, if no current
      SetCaret(i, 3);
      DoLock;
      SynEdit.SelectWord;
      DoUnLock;
      DoTestIsBlock('Select Word x='+IntToStr(i), 7,3, 10,3, ['bar']);
    end;
    SetCaret(1, 3);          // Select next word, if neitheer current nor previous
    DoLock;
    SynEdit.SelectWord;
    DoUnLock;
    DoTestIsBlock('Select Word x=1', 3,3, 6,3, ['Foo']);

    if UseBeginUpdate then begin
      SetCaret(8, 3);
      DoLock;
      SynEdit.SelectWord;
      SynEdit.LogicalCaretXY := Point(7, 3);
      DoUnLock;
      DoTestIsBlockBackward('Select Word, caret to start', 7,3, 10,3, ['bar']);
    end;

    // Line
    SetCaret(4, 3);
    DoLock;
    SynEdit.SelectLine(True);
    DoUnLock;
    DoTestIsBlock('Select Line (inc space)', 1,3, 12,3, ['  Foo(bar);']);

    SetCaret(4, 3);
    DoLock;
    SynEdit.SelectLine(False);
    DoUnLock;
    DoTestIsBlock('Select Line (excl space)', 3,3, 12,3, ['Foo(bar);']);

    // paragraph (includes 1 line before)
    SetCaret(1, 3);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=3', 1,2, 1,7, ['', '  Foo(bar);',
                                   '  abc;', '  // äüöäabc', #9#9+'test', '']);

    SetCaret(1, 2);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=2', 1,2, 1,7, ['', '  Foo(bar);',
                                   '  abc;', '  // äüöäabc', #9#9+'test', '']);

    SetCaret(1, 1);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=2 (begin of file)', 1,1, 1,2, ['begin', '']);

    SetCaret(1, 9);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=9 (end of file)', 1,8, 4,10, ['', 'end;(', '//)']);

    SetCaret(1, 7);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=7 (empty para)', 1,7, 1,8, ['', '']);

    // select all
    SetCaret(3, 3);
    DoLock;
    SynEdit.SelectAll;
    DoUnLock;
    DoTestIsBlock('Select All', 1,1, 4,10, ['begin', '', '  Foo(bar);', '  abc;',
                        '  // äüöäabc', #9#9+'test', '', '', 'end;(', '//)']);

    // select to brace
    SetCaret(8, 3);
    DoLock;
    SynEdit.SelectToBrace;
    DoUnLock;
    TestIsNoBlock('SelectToBrace (not at brace)');

    SetCaret(6, 3);
    DoLock;
    SynEdit.SelectToBrace;
    DoUnLock;
    DoTestIsBlockBackward('SelectToBrace X=6', 6,3, 11,3, ['(bar)']);

    SetCaret(11, 3);
    DoLock;
    SynEdit.SelectToBrace;
    DoUnLock;
    DoTestIsBlock('SelectToBrace X=11', 6,3, 11,3, ['(bar)']);

    SetCaret(5, 9);
    DoLock;
    SynEdit.SelectToBrace;
    DoUnLock;
    DoTestIsBlockBackward('SelectToBrace multi line', 5,9, 4,10, ['(', '//)']);

    // BlockBegin/end
    SetCaret(1, 1);
    SetCaretAndSel(2,3, 4,3, UseBeginUpdate);
    DoTestIsBlock('Select Begin/End', 2,3, 4,3, [' F']);

    SetCaret(1, 1);
    SetCaretAndSel(12,3, 1,4, UseBeginUpdate);
    DoTestIsBlock('Select Begin/End CrLf', 12,3, 1,4, ['', '']);

    SetCaret(1, 1);
    SetCaretAndSelBackward(11,3, 13,3, UseBeginUpdate);
    DoTestIsBlockBackward('Select Begin/End Eol', 11,3, 13,3, ['; ']);


    (* *** smColumn *** *)
    PopPushBaseName('Default:smColumn');
    SynEdit.DefaultSelectionMode := smColumn;

    // word
    for i := 7 to 11 do begin // includes 11: select previous word, if no current
      SetCaret(i, 3);
      DoLock;
      SynEdit.SelectWord;
      DoUnLock;
      DoTestIsBlock('Select Word x='+IntToStr(i), 7,3, 10,3, ['bar']);
    end;
    SetCaret(1, 3);          // Select next word, if neitheer current nor previous
    DoLock;
    SynEdit.SelectWord;
    DoUnLock;
    DoTestIsBlock('Select Word x=1', 3,3, 6,3, ['Foo']);

    if UseBeginUpdate then begin
      SetCaret(8, 3);
      DoLock;
      SynEdit.SelectWord;
      SynEdit.LogicalCaretXY := Point(7, 3);
      DoUnLock;
      DoTestIsBlockBackward('Select Word, caret to start', 7,3, 10,3, ['bar']);
    end;

    // Line
    SetCaret(4, 3);
    DoLock;
    SynEdit.SelectLine(True);
    DoUnLock;
    DoTestIsBlock('Select Line (inc space)', 1,3, 12,3, ['  Foo(bar);']);

    SetCaret(4, 3);
    DoLock;
    SynEdit.SelectLine(False);
    DoUnLock;
    DoTestIsBlock('Select Line (excl space)', 3,3, 12,3, ['Foo(bar);']);

    // paragraph (includes 1 line before)
    SetCaret(1, 3);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=3', 1,2, 1,7, ['', '  Foo(bar);',
                                   '  abc;', '  // äüöäabc', #9#9+'test', '']);

    SetCaret(1, 9);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=9 (end of file)', 1,8, 4,10, ['', 'end;(', '//)']);

    SetCaret(1, 7);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=7 (empty para)', 1,7, 1,8, ['', '']);

    // select all
    SetCaret(3, 3);
    DoLock;
    SynEdit.SelectAll;
    DoUnLock;
    DoTestIsBlock('Select All', 1,1, 4,10, ['begin', '', '  Foo(bar);', '  abc;',
                        '  // äüöäabc', #9#9+'test', '', '', 'end;(', '//)']);

    // select to brace
    SetCaret(6, 3);
    DoLock;
    SynEdit.SelectToBrace;
    DoUnLock;
    DoTestIsBlockBackward('SelectToBrace X=6', 6,3, 11,3, ['(bar)']);

    SetCaret(5, 9);
    DoLock;
    SynEdit.SelectToBrace;
    DoUnLock;
    DoTestIsBlockBackward('SelectToBrace multi line', 5,9, 4,10, [';', ' ']);

    // BlockBegin/end
    SetCaret(1, 1);
    DoLock;
    SetCaret(4, 3);
    SynEdit.BlockBegin := Point(2,3);
    SynEdit.BlockEnd   := Point(4,3);
    DoUnLock;
    DoTestIsBlock('Select Begin/End 1 line', 2,3, 4,3, [' F']);

    SetCaret(1, 1);
    DoLock;
    SetCaret(13, 3);
    SynEdit.BlockBegin := Point(11,3);
    SynEdit.BlockEnd   := Point(13,3);
    DoUnLock;
    DoTestIsBlock('Select Begin/End 1 line Eol', 11,3, 13,3, ['; ']);

    SetCaret(1, 1);
    DoLock;
    SetCaret(6, 5);
    SynEdit.BlockBegin := Point(10,3);
    SynEdit.BlockEnd   := Point(6,5);
    DoUnLock;
    DoTestIsBlock('Select Begin/End utf8 4 column', 10,3, 6,5, ['(bar', ';   ', 'äüöä']); // 3 utf8

    SetCaret(1, 1);
    DoLock;
    SetCaret(10, 3);
    SynEdit.BlockBegin := Point(10,3);
    SynEdit.BlockEnd   := Point(9+3,5);
    DoUnLock;
    DoTestIsBlockBackward('Select Begin/End utf8  1 column', 10,3, 9+3,5, ['r', ' ', 'ä']); // 3 utf8

    SetCaret(1, 1);
    DoLock;
    SetCaret(5, 9);
    SynEdit.BlockBegin := Point(1, 5);
    SynEdit.BlockEnd   := Point(5, 9);
    DoUnLock;
    DoTestIsBlock('Select Begin/End tabs', 1,5, 5,9, ['  //', #9, '    ', '    ', 'end;']); // 3 utf8



    (* *** smLine *** *)
    PopPushBaseName('Default:smLine');
    SynEdit.DefaultSelectionMode := smLine;

    // word
    for i := 7 to 11 do begin // includes 11: select previous word, if no current
      SetCaret(i, 3);
      DoLock;
      SynEdit.SelectWord;
      DoUnLock;
      DoTestIsBlock('Select Word x='+IntToStr(i), 7,3, 10,3, ['bar']);
    end;
    SetCaret(1, 3);          // Select next word, if neitheer current nor previous
    DoLock;
    SynEdit.SelectWord;
    DoUnLock;
    DoTestIsBlock('Select Word x=1', 3,3, 6,3, ['Foo']);

    if UseBeginUpdate then begin
      SetCaret(8, 3);
      DoLock;
      SynEdit.SelectWord;
      SynEdit.LogicalCaretXY := Point(7, 3);
      DoUnLock;
      DoTestIsBlockBackward('Select Word, caret to start', 7,3, 10,3, ['bar']);
    end;

    // Line
    SetCaret(4, 3);
    DoLock;
    SynEdit.SelectLine(True);
    DoUnLock;
    DoTestIsBlock('Select Line (inc space)', 1,3, 12,3, ['  Foo(bar);']);

    SetCaret(4, 3);
    DoLock;
    SynEdit.SelectLine(False);
    DoUnLock;
    DoTestIsBlock('Select Line (excl space)', 3,3, 12,3, ['Foo(bar);']); // TODO wrong X pos

    // paragraph (includes 1 line before)
    SetCaret(1, 3);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=3', 1,2, 1,7, ['', '  Foo(bar);',
                                   '  abc;', '  // äüöäabc', #9#9+'test', '']);

    SetCaret(1, 2);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=2', 1,2, 1,7, ['', '  Foo(bar);',
                                   '  abc;', '  // äüöäabc', #9#9+'test', '']);

    SetCaret(1, 1);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=2 (begin of file)', 1,1, 1,2, ['begin', '']);

    SetCaret(1, 9);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=9 (end of file)', 1,8, 4,10, ['', 'end;(', '//)']);

    SetCaret(1, 7);
    DoLock;
    SynEdit.SelectParagraph;
    DoUnLock;
    DoTestIsBlock('Select ParagraphLine Y=7 (empty para)', 1,7, 1,8, ['', '']);

    // select all
    SetCaret(3, 3);
    DoLock;
    SynEdit.SelectAll;
    DoUnLock;
    DoTestIsBlock('Select All', 1,1, 4,10, ['begin', '', '  Foo(bar);', '  abc;',
                        '  // äüöäabc', #9#9+'test', '', '', 'end;(', '//)']);

    // select to brace
    // TODO

    // BlockBegin/end
    SetCaret(1, 1);
    DoLock;
    SetCaret(4, 3);
    SynEdit.BlockBegin := Point(2,3);
    SynEdit.BlockEnd   := Point(4,3);
    DoUnLock;
    DoTestIsBlock('Select Begin/End', 2,3, 4,3, ['  Foo(bar);', '']); // TODO wrong X


    PopBaseName;
  End;

begin
  ReCreateEdit;
  BaseTestName := 'SelectByMethod';

  (* tests include:
       eoPersistentBlock
       eoNoSelection
       Embed into BeginUpdate for locks
  *)
  // CaretPos are Logical, to save params

  SynEdit.TabWidth := 4;
  SynEdit.Options := SynEdit.Options  + [eoScrollPastEol];

  SetLines(['begin',
            '',
            '  Foo(bar);',
            '  abc;',
            '  // äüöäabc', // Utf8 2 bytes per char
            #9#9+'test',    // Tab  1 byte / several display cells
            '',
            '',
            'end;(',
            '//)'
           ]);

  NoSelection := False;
  SynEdit.Options  := SynEdit.Options  - [eoNoSelection];
  SynEdit.Options2 := SynEdit.Options2 + [eoPersistentBlock];

  PushBaseName('NonePersist');
  UseBeginUpdate := False;
  DoSelectByMethod;

  PopPushBaseName('NonePersist Locked');
  UseBeginUpdate := True;
  DoSelectByMethod;

  NoSelection := True;
  SynEdit.Options  := SynEdit.Options  + [eoNoSelection];

  PopPushBaseName('NonePersist eoNoSelection');
  UseBeginUpdate := False;
  DoSelectByMethod;


  NoSelection := False;
  SynEdit.Options  := SynEdit.Options  - [eoNoSelection];
  SynEdit.Options2 := SynEdit.Options2 - [eoPersistentBlock];

  PopPushBaseName('Persisent');
  UseBeginUpdate := False;
  DoSelectByMethod;

  PopPushBaseName('Persisent Locked');
  UseBeginUpdate := True;
  DoSelectByMethod;

  NoSelection := True;
  SynEdit.Options  := SynEdit.Options  + [eoNoSelection];
  PopPushBaseName('Persisent eoNoSelection Locked');
  DoSelectByMethod;
end;

procedure TTestSynSelection.ReplaceSelText;
  var
    SelInsertMode: TSynSelectionMode;

  function TheText: TStringArray;
  begin
    SetLength(Result, 8);
    Result[0] := 'begin';
    Result[1] := '';
    Result[2] := '  Foo(bar);';
    Result[3] := '  abc;';
    Result[4] := '  // äüöäabc'; // Utf8 2 bytes per char
    Result[5] := #9#9+'test';    // Tab  1 byte / several display cells
    Result[6] := '';
    Result[7] := ''; // this line is not added, it just provides the last CrLf
  end;

  procedure TestReplace(Name: String; X1,Y1, X2,Y2: Integer; Before: Array of String;
                        Replace: Array of String; ExpCaretX, ExpCaretY: Integer;
                        ExpLineRepl: Array of Const; SkipUndo: Boolean = False);
  var
    SkipUndo2: Boolean;
  begin
    PushBaseName(Name);
    SetLines(TheText);
    SetCaretAndSel(X1,Y1, X2,Y2);
    TestIsBlock    ('Sanity, selection at begin of test', X1,Y1, X2,Y2, Before);
    SynEdit.TestSetSelText(LinesToText(Replace), SelInsertMode);
    TestIsCaretPhys('After Replace', ExpCaretX, ExpCaretY);
    TestIsNoBlock  ('After Replace');
    TestIsFullText ('After Replace', TheText, ExpLineRepl);

    if not SkipUndo then begin
      SynEdit.Undo;
      TestIsBlock    ('After Undo', X1,Y1, X2,Y2, Before);
      TestIsFullText ('After Undo', TheText);

      SynEdit.Redo;
      TestIsCaretPhys('After Redo', ExpCaretX, ExpCaretY);
      TestIsNoBlock  ('After Redo');
      TestIsFullText ('After Redo', TheText, ExpLineRepl);

      SynEdit.Undo;
      TestIsBlock    ('After Undo 2', X1,Y1, X2,Y2, Before);
      TestIsFullText ('After Undo 2', TheText);

      SynEdit.Redo;
      TestIsCaretPhys('After Redo 2', ExpCaretX, ExpCaretY);
      TestIsNoBlock  ('After Redo 2');
      TestIsFullText ('After Redo 2', TheText, ExpLineRepl);

      SynEdit.Undo;
      SynEdit.TestSetSelText(LinesToText(Replace), SelInsertMode);
      TestIsCaretPhys('After Undo,Replace', ExpCaretX, ExpCaretY);
      TestIsNoBlock  ('After Undo,Replace');
      TestIsFullText ('After Undo,Replace', TheText, ExpLineRepl);
    end;

    // *** do in 2 steps, explicit set to empty
    SetLines(TheText);
    SetCaretAndSel(X1,Y1, X2,Y2);
    TestIsBlock    ('Sanity, selection at begin of test (2)', X1,Y1, X2,Y2, Before);
    SynEdit.SelText := '';
    if SynEdit.TestFullText = LinesToText(TheText) then SkipUndo2 := True;       // Nothing changed, can not restore bloc in undo
    SynEdit.TestSetSelText(LinesToText(Replace), SelInsertMode);
    TestIsCaretPhys('After Replace (2 step)', ExpCaretX, ExpCaretY);
    TestIsNoBlock  ('After Replace (2 step)');
    TestIsFullText ('After Replace (2 step)', TheText, ExpLineRepl);

    if (not SkipUndo) and (not SkipUndo2) then begin
      SynEdit.Undo;      // there may only be one undo, then the other is ignored
      SynEdit.Undo;
      TestIsBlock    ('After Undo (2 step)', X1,Y1, X2,Y2, Before);
      TestIsFullText ('After Undo (2 step)', TheText);

      SynEdit.Redo;
      SynEdit.Redo;
      TestIsCaretPhys('After Redo (2 step)', ExpCaretX, ExpCaretY);
      TestIsNoBlock  ('After Redo (2 step)');
      TestIsFullText ('After Redo (2 step)', TheText, ExpLineRepl);
    end;

    // *** do in 2 steps, explicit set to empty // inside Lock and UndoBlock
    SetLines(TheText);
    SetCaretAndSel(X1,Y1, X2,Y2);
    TestIsBlock    ('Sanity, selection at begin of test (3)', X1,Y1, X2,Y2, Before);
    SynEdit.BeginUndoBlock;
    SynEdit.BeginUpdate;
    SynEdit.SelText := '';
    SynEdit.TestSetSelText(LinesToText(Replace), SelInsertMode);
    SynEdit.EndUndoBlock;
    SynEdit.EndUpdate;
    TestIsCaretPhys('After Replace (2 step, locked)', ExpCaretX, ExpCaretY);
    TestIsNoBlock  ('After Replace (2 step, locked)');
    TestIsFullText ('After Replace (2 step, locked)', TheText, ExpLineRepl);

    if (not SkipUndo) and (not SkipUndo2) then begin
      SynEdit.Undo;
      TestIsBlock    ('After Undo (2 step, locked)', X1,Y1, X2,Y2, Before);
      TestIsFullText ('After Undo (2 step, locked)', TheText);

      SynEdit.Redo;
      TestIsCaretPhys('After Redo (2 step, locked)', ExpCaretX, ExpCaretY);
      TestIsNoBlock  ('After Redo (2 step, locked)');
      TestIsFullText ('After Redo (2 step, locked)', TheText, ExpLineRepl);
    end;

    // *** Do Action and Undo in the same lock (not undo block)
    if not SkipUndo then begin
      SetLines(TheText);
      SetCaretAndSel(X1,Y1, X2,Y2);
      TestIsBlock    ('Sanity, selection at begin of test (4)', X1,Y1, X2,Y2, Before);
      SynEdit.BeginUpdate;
      SynEdit.TestSetSelText(LinesToText(Replace), SelInsertMode);

      SynEdit.Undo;
      TestIsBlock    ('After Undo (locked together)', X1,Y1, X2,Y2, Before);
      TestIsFullText ('After Undo (locked together)', TheText);
      SynEdit.EndUpdate;

      SynEdit.Redo;
      TestIsCaretPhys('After Redo (locked together)', ExpCaretX, ExpCaretY);
      TestIsNoBlock  ('After Redo (locked together)');
      TestIsFullText ('After Redo (locked)', TheText, ExpLineRepl);
    end;

    // *** Apply selection backward
    SetLines(TheText);
    SetCaretAndSel(X2,Y2, X1,Y1);
    TestIsBlock    ('Sanity, selection at begin of test (backward)', X1,Y1, X2,Y2, Before);
    SynEdit.TestSetSelText(LinesToText(Replace), SelInsertMode);
    TestIsCaretPhys('After Replace (backward)', ExpCaretX, ExpCaretY);
    TestIsNoBlock  ('After Replace (backward)');
    TestIsFullText ('After Replace (backward)', TheText, ExpLineRepl);

    if not SkipUndo then begin
      SynEdit.Undo;
      TestIsBlock    ('After Undo (backward)', X1,Y1, X2,Y2, Before);
      TestIsFullText ('After Undo (backward)', TheText);

      SynEdit.Redo;
      TestIsCaretPhys('After Redo (backward)', ExpCaretX, ExpCaretY);
      TestIsNoBlock  ('After Redo (backward)');
      TestIsFullText ('After Redo (backward)', TheText, ExpLineRepl);

      SynEdit.Undo;
      TestIsBlock    ('After Undo 2 (backward)', X1,Y1, X2,Y2, Before);
      TestIsFullText ('After Undo 2 (backward)', TheText);
    end;

    PopBaseName;
  end;

  procedure DoTests;
  var
    t: TStringArray;
  begin
    SynEdit.Options2 := SynEdit.Options2 - [eoPersistentBlock];
    t := TheText;;

    PushBaseName('Default:smNormal');
    {%region 'Default:smNormal'}
    SynEdit.DefaultSelectionMode := smNormal;
    SelInsertMode := smNormal;
    SynEdit.Options := SynEdit.Options  + [eoScrollPastEol];

    //          Name                          Block      Before          Repl         ExpCaret  ExpText-Repl
    //                                        Logical                                 Physical
    TestReplace('No Sel Middle = empty',    -1,-1,  2,3, [''],           [''],        2,3,  [3, '  Foo(bar);']);
    TestReplace('No Sel Middle = X',        -1,-1,  2,3, [''],           ['X'],       3,3,  [3, ' X Foo(bar);']);
    TestReplace('No Sel Middle = utf8',     -1,-1,  2,3, [''],           ['Ä'],       3,3,  [3, ' Ä Foo(bar);']);
    TestReplace('No Sel Middle = tab ',     -1,-1,  2,3, [''],           [#9],        5,3,  [3, ' '+#9+' Foo(bar);']);
    if not (eoTrimTrailingSpaces in SynEdit.Options) then
    TestReplace('No Sel Middle = CrLf',     -1,-1,  2,3, [''],           ['',''],     1,4,  [3, ' ', ' Foo(bar);']);
    if not (eoTrimTrailingSpaces in SynEdit.Options) then
    TestReplace('No Sel Middle = X CrLf Y', -1,-1,  2,3, [''],           ['X','Y'],   2,4,  [3, ' X', 'Y Foo(bar);']);

    TestReplace('One Line Middle = empty',    2,3,  4,3, [' F'],         [''],        2,3,  [3, ' oo(bar);']);
    TestReplace('One Line Middle = X',        2,3,  4,3, [' F'],         ['X'],       3,3,  [3, ' Xoo(bar);']);
    TestReplace('One Line Middle = utf8',     2,3,  4,3, [' F'],         ['Ä'],       3,3,  [3, ' Äoo(bar);']);
    TestReplace('One Line Middle = tab ',     2,3,  4,3, [' F'],         [#9],        5,3,  [3, ' '+#9+'oo(bar);']);
    if not (eoTrimTrailingSpaces in SynEdit.Options) then
    TestReplace('One Line Middle = CrLf',     2,3,  4,3, [' F'],         ['',''],     1,4,  [3, ' ', 'oo(bar);']);
    if not (eoTrimTrailingSpaces in SynEdit.Options) then
    TestReplace('One Line Middle = X CrLf Y', 2,3,  4,3, [' F'],         ['X','Y'],   2,4,  [3, ' X', 'Yoo(bar);']);

    TestReplace('One Line AtStart = empty',   1,3,  2,3, [' '],          [''],        1,3,  [3, ' Foo(bar);']);
    TestReplace('One Line AtStart = X',       1,3,  2,3, [' '],          ['X'],       2,3,  [3, 'X Foo(bar);']);
    TestReplace('One Line AtStart = utf8',    1,3,  2,3, [' '],          ['Ä'],       2,3,  [3, 'Ä Foo(bar);']);
    TestReplace('One Line AtStart = tab ',    1,3,  2,3, [' '],          [#9],        5,3,  [3, ''+#9+' Foo(bar);']);
    TestReplace('One Line AtStart = CrLf',    1,3,  2,3, [' '],          ['',''],     1,4,  [3, '',' Foo(bar);']);
    TestReplace('One Line AtStart = CrLf,Y',  1,3,  2,3, [' '],          ['','Y'],    2,4,  [3, '','Y Foo(bar);']);

    TestReplace('One Line AtEnd = empty',    11,3, 12,3, [';'],          [''],       11,3,  [3, '  Foo(bar)']);
    TestReplace('One Line AtEnd = X',        11,3, 12,3, [';'],          ['X'],      12,3,  [3, '  Foo(bar)X']);
    TestReplace('One Line AtEnd = utf8',     11,3, 12,3, [';'],          ['Ä'],      12,3,  [3, '  Foo(bar)Ä']);
    TestReplace('One Line AtEnd = tab ',     11,3, 12,3, [';'],          [#9],       13,3,  [3, '  Foo(bar)'+#9+'']);

    TestReplace('One Line End+Past = empty', 11,3, 13,3, ['; '],         [''],       11,3,  [3, '  Foo(bar)']);
    TestReplace('One Line End+Past = X',     11,3, 13,3, ['; '],         ['X'],      12,3,  [3, '  Foo(bar)X']);
    TestReplace('One Line End+Past = utf8',  11,3, 13,3, ['; '],         ['Ä'],      12,3,  [3, '  Foo(bar)Ä']);
    TestReplace('One Line End+Past = tab ',  11,3, 13,3, ['; '],         [#9],       13,3,  [3, '  Foo(bar)'+#9+'']);

    TestReplace('One Line Past = empty',     13,3, 15,3, ['  '],         [''],       13,3,  [3, '  Foo(bar);'], True); // skip undo
    TestReplace('One Line Past = X',         13,3, 15,3, ['  '],         ['X'],      14,3,  [3, '  Foo(bar); X']);
    TestReplace('One Line Past = utf8',      13,3, 15,3, ['  '],         ['Ä'],      14,3,  [3, '  Foo(bar); Ä']);
    TestReplace('One Line Past = tab ',      13,3, 15,3, ['  '],         [#9],       17,3,  [3, '  Foo(bar); '+#9+'']);
    if not (eoTrimTrailingSpaces in SynEdit.Options) then
    TestReplace('One Line Past = CrLf ',     13,3, 15,3, ['  '],         ['', ''],    1,4,  [3, '  Foo(bar); ', '']);
    TestReplace('One Line Past = X,CrLf ',   13,3, 15,3, ['  '],         ['X', ''],   1,4,  [3, '  Foo(bar); X', '']);

    TestReplace('One Line utf8 = empty',      6,5,  8,5, ['ä'],          [''],        6,5,  [5, '  // üöäabc']);
    TestReplace('One Line utf8 = X',          6,5,  8,5, ['ä'],          ['X'],       7,5,  [5, '  // Xüöäabc']);
    TestReplace('One Line utf8 = utf8',       6,5,  8,5, ['ä'],          ['Ä'],       7,5,  [5, '  // Äüöäabc']);
    TestReplace('One Line utf8 = tab ',       6,5,  8,5, ['ä'],          [#9],        9,5,  [5, '  // '+#9+'üöäabc']);

    // Caret starts at Logical.X = 8 (which is Phys=7) => End add Phys = 8 (if X inserted)
    TestReplace('One Line 2 utf8 = empty',    8,5, 12,5, ['üö'],         [''],        7,5,  [5, '  // ääabc']);
    TestReplace('One Line 2 utf8 = X',        8,5, 12,5, ['üö'],         ['X'],       8,5,  [5, '  // äXäabc']);
    TestReplace('One Line 2 utf8 = utf8',     8,5, 12,5, ['üö'],         ['Ä'],       8,5,  [5, '  // äÄäabc']);
    TestReplace('One Line 2 utf8 = tab ',     8,5, 12,5, ['üö'],         [#9],        9,5,  [5, '  // ä'+#9+'äabc']);

    TestReplace('One Line tab = empty',       2,6,  3,6, [#9],           [''],        5,6,  [6, #9+'test']);
    TestReplace('One Line tab = X',           2,6,  3,6, [#9],           ['X'],       6,6,  [6, #9+'Xtest']);
    TestReplace('One Line tab = utf8',        2,6,  3,6, [#9],           ['Ä'],       6,6,  [6, #9+'Ätest']);
    TestReplace('One Line tab = tab ',        2,6,  3,6, [#9],           [#9],        9,6,  [6, #9#9+'test']);

    TestReplace('Full Line = empty',          1,3, 12,3, [t[2] ],        [''],        1,3,  [3, '']);
    TestReplace('Full Line = X',              1,3, 12,3, [t[2] ],        ['X'],       2,3,  [3, 'X']);
    TestReplace('Full Line = utf8',           1,3, 12,3, [t[2] ],        ['Ä'],       2,3,  [3, 'Ä']);
    TestReplace('Full Line = tab',            1,3, 12,3, [t[2] ],        [#9],        5,3,  [3, #9]);

    TestReplace('Full Line + CrLf = empty',   1,3,  1,4, [t[2], ''],     [''],        1,3,  [3]);
    TestReplace('Full Line + CrLf = X',       1,3,  1,4, [t[2], ''],     ['X'],       2,3,  [3, 3, 'X' + t[3]]);
    TestReplace('Full Line + CrLf = utf8',    1,3,  1,4, [t[2], ''],     ['Ä'],       2,3,  [3, 3, 'Ä' + t[3]]);
    TestReplace('Full Line + CrLf = tab',     1,3,  1,4, [t[2], ''],     [#9],        5,3,  [3, 3, #9 + t[3]]);
    TestReplace('Full Line + CrLf = CrLf',    1,3,  1,4, [t[2], ''],     ['', ''],    1,4,  [3, '']);

    TestReplace('Full Line, CrLf, Chr= empty',1,3,  2,4, [t[2], ' '],    [''],        1,3,  [3, 3, ' abc;']);
    TestReplace('Full Line, CrLf, Chr= X',    1,3,  2,4, [t[2], ' '],    ['X'],       2,3,  [3, 3, 'X abc;']);
    TestReplace('Full Line, CrLf, Chr= utf8', 1,3,  2,4, [t[2], ' '],    ['Ä'],       2,3,  [3, 3, 'Ä abc;']);
    TestReplace('Full Line, CrLf, Chr= tab',  1,3,  2,4, [t[2], ' '],    [#9],        5,3,  [3, 3, #9 + ' abc;']);

    TestReplace('Part Line, CrLf = empty',    4,3,  1,4, ['oo(bar);',''], [''],       4,3,  [3, 3, '  F  abc;']);
    TestReplace('Part Line, CrLf = X',        4,3,  1,4, ['oo(bar);',''], ['X'],      5,3,  [3, 3, '  FX  abc;']);
    TestReplace('Part Line, CrLf = utf8',     4,3,  1,4, ['oo(bar);',''], ['Ä'],      5,3,  [3, 3, '  FÄ  abc;']);
    TestReplace('Part Line, CrLf = tab',      4,3,  1,4, ['oo(bar);',''], [#9],       5,3,  [3, 3, '  F'+#9 + '  abc;']);

    TestReplace('Part Line, CrLf, Chr= empty',4,3,  2,4, ['oo(bar);',' '], [''],      4,3,  [3, 3, '  F abc;']);
    TestReplace('Part Line, CrLf, Chr= X',    4,3,  2,4, ['oo(bar);',' '], ['X'],     5,3,  [3, 3, '  FX abc;']);
    TestReplace('Part Line, CrLf, Chr= utf8', 4,3,  2,4, ['oo(bar);',' '], ['Ä'],     5,3,  [3, 3, '  FÄ abc;']);
    TestReplace('Part Line, CrLf, Chr= tab',  4,3,  2,4, ['oo(bar);',' '], [#9],      5,3,  [3, 3, '  F'+#9 + ' abc;']);

    TestReplace('Only CrLf = empty',         12,3,  1,4, ['', ''],       [''],       12,3,  [3, '  Foo(bar);  abc;', 4]);
    TestReplace('Only CrLf = X',             12,3,  1,4, ['', ''],       ['X'],      13,3,  [3, '  Foo(bar);X  abc;', 4]);
    TestReplace('Only CrLf = utf8',          12,3,  1,4, ['', ''],       ['Ä'],      13,3,  [3, '  Foo(bar);Ä  abc;', 4]);
    TestReplace('Only CrLf = tab',           12,3,  1,4, ['', ''],       [#9],       13,3,  [3, '  Foo(bar);'+#9+'  abc;', 4]);

    TestReplace('CrLf past Eol = empty',     14,3,  1,4, ['', ''],       [''],       14,3,  [3, '  Foo(bar);    abc;', 4]);
    TestReplace('CrLf past Eol = X',         14,3,  1,4, ['', ''],       ['X'],      15,3,  [3, '  Foo(bar);  X  abc;', 4]);
    TestReplace('CrLf past Eol = utf8',      14,3,  1,4, ['', ''],       ['Ä'],      15,3,  [3, '  Foo(bar);  Ä  abc;', 4]);
    TestReplace('CrLf past Eol = tab',       14,3,  1,4, ['', ''],       [#9],       17,3,  [3, '  Foo(bar);  '+#9+'  abc;', 4]);

    TestReplace('CrLf past Eol, Chr = empty',14,3,  3,4, ['', '  '],     [''],       14,3,  [3, '  Foo(bar);  abc;', 4]);
    TestReplace('CrLf past Eol, Chr = X',    14,3,  3,4, ['', '  '],     ['X'],      15,3,  [3, '  Foo(bar);  Xabc;', 4]);
    TestReplace('CrLf past Eol, Chr = utf8', 14,3,  3,4, ['', '  '],     ['Ä'],      15,3,  [3, '  Foo(bar);  Äabc;', 4]);
    TestReplace('CrLf past Eol, Chr = tab',  14,3,  3,4, ['', '  '],     [#9],       17,3,  [3, '  Foo(bar);  '+#9+'abc;', 4]);

    TestReplace('2 Lines = X',                1,3,  7,4, [t[2], t[3] ],      ['X'],   2,3,  [3, 3, 'X']);
    TestReplace('2 Lines CrLf = X',           1,3,  1,5, [t[2], t[3], ''],   ['X'],   2,3,  [3, 3, 3, 'X  // äüöäabc']);
    TestReplace('2 Lines CrLf, Chr = X',      1,3,  2,5, [t[2], t[3], ' '],  ['X'],   2,3,  [3, 3, 3, 'X // äüöäabc']);
    TestReplace('2 (part)Lines CrLf, Chr = X',6,3,  2,5, ['(bar);', t[3], ' '], ['X'],7,3,  [3, 3, 3, '  FooX // äüöäabc']);
    TestReplace('1 empty Lines = X',          1,2,  1,3, ['', ''],           ['X'],   2,2,  [2, 2, 'X  Foo(bar);']);


    PopPushBaseName('Default:smNormal eoScrollPastEol=off');
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol];

    SynEdit.Text := LinesToText(TheText);
    SetCaret(10,3);
    SynEdit.Options := SynEdit.Options  - [eoScrollPastEol];
    SynEdit.BlockBegin := Point(10,3);
    SynEdit.BlockEnd   := Point(12,3);
    TestIsBlock('eoScrollPastEol=off  just to past eol', 10,3, 12,3, [');']);
    SynEdit.BlockBegin := Point(10,3);
    SynEdit.BlockEnd   := Point(14,3);
    TestIsBlock('eoScrollPastEol=off  prevent past eol', 10,3, 12,3, [');']);
    SynEdit.BlockBegin := Point(14,3);
    SynEdit.BlockEnd   := Point(10,3);
    TestIsBlock('eoScrollPastEol=off  prevent past eol backward', 10,3, 12,3, [');']);

    TestReplace('One Line AtEnd = X',        11,3, 12,3, [';'],          ['X'],      12,3,  [3, '  Foo(bar)X']);
    if not (eoTrimTrailingSpaces in SynEdit.Options) then
    TestReplace('One Line Middle = CrLf',     2,3,  4,3, [' F'],         ['',''],     1,4,  [3, ' ', 'oo(bar);']);
    if not (eoTrimTrailingSpaces in SynEdit.Options) then
    TestReplace('One Line Middle = X CrLf Y', 2,3,  4,3, [' F'],         ['X','Y'],   2,4,  [3, ' X', 'Yoo(bar);']);
    TestReplace('Full Line = empty',          1,3, 12,3, [t[2] ],        [''],        1,3,  [3, '']);
    TestReplace('Full Line = X',              1,3, 12,3, [t[2] ],        ['X'],       2,3,  [3, 'X']);
    TestReplace('Full Line + CrLf = empty',   1,3,  1,4, [t[2], ''],     [''],        1,3,  [3]);
    TestReplace('Full Line + CrLf = X',       1,3,  1,4, [t[2], ''],     ['X'],       2,3,  [3, 3, 'X' + t[3]]);
    TestReplace('Part Line, CrLf = X',        4,3,  1,4, ['oo(bar);',''], ['X'],      5,3,  [3, 3, '  FX  abc;']);
    TestReplace('Part Line, CrLf, Chr= X',    4,3,  2,4, ['oo(bar);',' '], ['X'],     5,3,  [3, 3, '  FX abc;']);
    TestReplace('Only CrLf = X',             12,3,  1,4, ['', ''],       ['X'],      13,3,  [3, '  Foo(bar);X  abc;', 4]);
    TestReplace('2 Lines = X',                1,3,  7,4, [t[2], t[3] ],  ['X'],       2,3,  [3, 3, 'X']);
    TestReplace('2 Lines CrLf = X',           1,3,  1,5, [t[2], t[3], ''], ['X'],     2,3,  [3, 3, 3, 'X  // äüöäabc']);
    TestReplace('2 Lines CrLf, Chr = X',      1,3,  2,5, [t[2], t[3], ' '], ['X'],    2,3,  [3, 3, 3, 'X // äüöäabc']);
    TestReplace('2 (part)Lines CrLf, Chr = X',6,3,  2,5, ['(bar);', t[3], ' '], ['X'],7,3,  [3, 3, 3, '  FooX // äüöäabc']);
    TestReplace('1 empty Lines = X',          1,2,  1,3, ['', ''],       ['X'],       2,2,  [2, 2, 'X  Foo(bar);']);
    {%endregion}



    {%region 'Default:smColumn'}
    PopPushBaseName('Default:smColumn');
    SynEdit.DefaultSelectionMode := smColumn;
    SelInsertMode := smColumn;
    SynEdit.Options := SynEdit.Options  + [eoScrollPastEol];

    TestReplace('One Line Middle = empty',    2,3,  4,3, [' F'],         [''],        2,3,  [3, ' oo(bar);']);
    TestReplace('One Line Middle = X',        2,3,  4,3, [' F'],         ['X'],       3,3,  [3, ' Xoo(bar);']);
    TestReplace('One Line Middle = utf8',     2,3,  4,3, [' F'],         ['Ä'],       3,3,  [3, ' Äoo(bar);']);
    TestReplace('One Line Middle = tab ',     2,3,  4,3, [' F'],         [#9],        5,3,  [3, ' '+#9+'oo(bar);']);
    TestReplace('One Line Middle = CrLf ',    2,3,  4,3, [' F'],         ['', ''],    2,4,  [3, ' oo(bar);']);
    TestReplace('One Line Middle = X CrLf Y', 2,3,  4,3, [' F'],         ['X', 'Y'],  3,4,  [3, ' Xoo(bar);',  4, ' Y abc;']);

    TestReplace('One Line AtStart = empty',   1,3,  2,3, [' '],          [''],        1,3,  [3, ' Foo(bar);']);
    TestReplace('One Line AtStart = X',       1,3,  2,3, [' '],          ['X'],       2,3,  [3, 'X Foo(bar);']);
    TestReplace('One Line AtStart = utf8',    1,3,  2,3, [' '],          ['Ä'],       2,3,  [3, 'Ä Foo(bar);']);
    TestReplace('One Line AtStart = tab ',    1,3,  2,3, [' '],          [#9],        5,3,  [3, ''+#9+' Foo(bar);']);

    TestReplace('One Line AtEnd = empty',    11,3, 12,3, [';'],          [''],       11,3,  [3, '  Foo(bar)']);
    TestReplace('One Line AtEnd = X',        11,3, 12,3, [';'],          ['X'],      12,3,  [3, '  Foo(bar)X']);
    TestReplace('One Line AtEnd = utf8',     11,3, 12,3, [';'],          ['Ä'],      12,3,  [3, '  Foo(bar)Ä']);
    TestReplace('One Line Past = tab ',      13,3, 15,3, ['  '],         [#9],       17,3,  [3, '  Foo(bar); '+#9+'']);

    TestReplace('One Line End+Past = empty', 11,3, 13,3, ['; '],         [''],       11,3,  [3, '  Foo(bar)']);
    TestReplace('One Line End+Past = X',     11,3, 13,3, ['; '],         ['X'],      12,3,  [3, '  Foo(bar)X']);
    TestReplace('One Line End+Past = utf8',  11,3, 13,3, ['; '],         ['Ä'],      12,3,  [3, '  Foo(bar)Ä']);
    TestReplace('One Line End+Past = tab ',  11,3, 13,3, ['; '],         [#9],       13,3,  [3, '  Foo(bar)'+#9+'']);

    TestReplace('One Line Past = empty',     13,3, 15,3, ['  '],         [''],       13,3,  [3, '  Foo(bar);'], True); // skip undo
    TestReplace('One Line Past = X',         13,3, 15,3, ['  '],         ['X'],      14,3,  [3, '  Foo(bar); X']);
    TestReplace('One Line Past = utf8',      13,3, 15,3, ['  '],         ['Ä'],      14,3,  [3, '  Foo(bar); Ä']);
    TestReplace('One Line AtEnd = tab ',     11,3, 12,3, [';'],          [#9],       13,3,  [3, '  Foo(bar)'+#9+'']);

    TestReplace('One Line utf8 = empty',      6,5,  8,5, ['ä'],          [''],        6,5,  [5, '  // üöäabc']);
    TestReplace('One Line utf8 = X',          6,5,  8,5, ['ä'],          ['X'],       7,5,  [5, '  // Xüöäabc']);
    TestReplace('One Line utf8 = utf8',       6,5,  8,5, ['ä'],          ['Ä'],       7,5,  [5, '  // Äüöäabc']);
    TestReplace('One Line utf8 = tab ',       6,5,  8,5, ['ä'],          [#9],        9,5,  [5, '  // '+#9+'üöäabc']);

    // Caret starts at Logical.X = 8 (which is Phys=7) => End add Phys = 8 (if X inserted)
    TestReplace('One Line 2 utf8 = empty',    8,5, 12,5, ['üö'],         [''],        7,5,  [5, '  // ääabc']);
    TestReplace('One Line 2 utf8 = X',        8,5, 12,5, ['üö'],         ['X'],       8,5,  [5, '  // äXäabc']);
    TestReplace('One Line 2 utf8 = utf8',     8,5, 12,5, ['üö'],         ['Ä'],       8,5,  [5, '  // äÄäabc']);
    TestReplace('One Line 2 utf8 = tab ',     8,5, 12,5, ['üö'],         [#9],        9,5,  [5, '  // ä'+#9+'äabc']);

    TestReplace('One Line tab = empty',       2,6,  3,6, [#9],           [''],        5,6,  [6, #9+'test']);
    TestReplace('One Line tab = X',           2,6,  3,6, [#9],           ['X'],       6,6,  [6, #9+'Xtest']);
    TestReplace('One Line tab = utf8',        2,6,  3,6, [#9],           ['Ä'],       6,6,  [6, #9+'Ätest']);
    TestReplace('One Line tab = tab ',        2,6,  3,6, [#9],           [#9],        9,6,  [6, #9#9+'test']);

    TestReplace('Two Line Middle = empty',    2,3,  4,4, [' F', ' a'],   [''],        2,3,  [3, ' oo(bar);',       4, ' bc;']);
    TestReplace('Two Line Middle = X',        2,3,  4,4, [' F', ' a'],   ['X'],       3,3,  [3, ' Xoo(bar);',      4, ' bc;']);
    TestReplace('Two Line Middle = utf8',     2,3,  4,4, [' F', ' a'],   ['Ä'],       3,3,  [3, ' Äoo(bar);',      4, ' bc;']);
    TestReplace('Two Line Middle = tab ',     2,3,  4,4, [' F', ' a'],   [#9],        5,3,  [3, ' '+#9+'oo(bar);', 4, ' bc;']);

    TestReplace('Two Line Middle (Back) =empty',       4,3,  2,4, [' F', ' a'],      [''],        2,3,  [3, ' oo(bar);',   4, ' bc;']);
    TestReplace('Two Line Middle (Back) =X',           4,3,  2,4, [' F', ' a'],      ['X'],       3,3,  [3, ' Xoo(bar);',  4, ' bc;']);

    TestReplace('2 Line Middle/Part-Past =empty',      9,3,  6,4, ['(ba', ';  '],   [''],        6,3,  [3, '  Foor);',  4, '  abc']);
    TestReplace('2 Line Middle/Part-Past =X',          9,3,  6,4, ['(ba', ';  '],   ['X'],       7,3,  [3, '  FooXr);',  4, '  abc']);
    TestReplace('2 Line Middle/Part-Past =X Cr Y',     9,3,  6,4, ['(ba', ';  '],   ['X', 'Y'],  7,4,  [3, '  FooXr);',  4, '  abcY']);

    // Logocal X1 = Logical.X2
    TestReplace('3 Line Middle, y2 utf8 = X/Y',        8,3, 8,5, ['b',' ','ü'],    ['X','Y','Z'], 8,5,  [3,'  Foo(Xar);', 4,'  abc;Y', 5,'  // äZöäabc']);
    TestReplace('3 Line Middle, y2 utf8 (BK)= X/Y',    7,3,10,5, ['b',' ','ü'],    ['X','Y','Z'], 8,5,  [3,'  Foo(Xar);', 4,'  abc;Y', 5,'  // äZöäabc']);

    TestReplace('3 Line Middle, y2 past eol = X/Y/Z',        8,3, 12,5, ['a',' ','ö'],    ['X','Y','Z'], 9,5,  [3,'  Foo(bXr);', 4,'  abc; Y', 5,'  // äüZäabc']);
    TestReplace('3 Line Middle (bck), y2 past eol = X/Y/Z',  9,3, 10,5, ['a',' ','ö'],    ['X','Y','Z'], 9,5,  [3,'  Foo(bXr);', 4,'  abc; Y', 5,'  // äüZäabc']);

    // multiline insert at last line of text
    TestReplace('Below Last Line = X/Y',                      1,7,-1,-1, [''],            ['X','Y','Z'], 2,9,  [7, 'X', 'Y', 'Z']);

    {%endregion}


(*
    Result[2] := '  Foo(bar);';
    Result[3] := '  abc;';
    Result[4] := '  // äüöäabc'; // Utf8 2 bytes per char

    Result[0] := 'begin';
    Result[1] := '';
    Result[2] := '  Foo(bar);';
    Result[3] := '  abc;';
    Result[4] := '  // äüöäabc'; // Utf8 2 bytes per char
    Result[5] := #9#9+'test';    // Tab  1 byte / several display cells
    Result[6] := '';
*)
    // Todo: more smColumn and smLine tests;

    PopBaseName;
  end;

begin
  ReCreateEdit;
  BaseTestName := 'ReplaceSelText';

  (* tests include:
       eoOverwriteBlock = on/off
       TrimSpace = on/off
       undo / redo
       Tests Begin/EndUpdate combinations

       eoPersistentBlock
  *)
  // CaretPos are Logical, to save params

  SynEdit.TabWidth := 4;
  SynEdit.Options  := SynEdit.Options  + [eoScrollPastEol]
                    - [eoTabIndent, eoTabsToSpaces, eoSpacesToTabs, eoSmartTabs, eoSmartTabDelete];


  (* eoOverwriteBlock: Should only affect editing, but not SetSelectionText *)

  PushBaseName('TrimSpace=On OverwriteBlock=On');
  SynEdit.Options  := SynEdit.Options  + [eoTrimTrailingSpaces];
  SynEdit.Options2 := SynEdit.Options2 + [eoOverwriteBlock];
  SynEdit.TrimSpaceType := settLeaveLine;
  DoTests;

  PushBaseName('TrimSpace=Off OverwriteBlock=On');
  SynEdit.Options  := SynEdit.Options  - [eoTrimTrailingSpaces];
  DoTests;

  PushBaseName('TrimSpace=On OverwriteBlock=Off');
  SynEdit.Options  := SynEdit.Options  + [eoTrimTrailingSpaces];
  SynEdit.Options2 := SynEdit.Options2 - [eoOverwriteBlock];
  DoTests;

  PushBaseName('TrimSpace=Off OverwriteBlock=Off');
  SynEdit.Options  := SynEdit.Options  - [eoTrimTrailingSpaces];
  DoTests;


end;

procedure TTestSynSelection.TextDelCmd;
  Procedure test1(Name, Txt: String;
                  x, y: Integer; Cmd: TSynEditorCommand;
                  ExpText: String; ExpX, ExpY: Integer);
  var i : integer;
  begin
    Name := Name + ' ('
          + ' Start('+IntToStr(x)+', '+IntToStr(y)+')'
          + ' Exp('+IntToStr(Expx)+', '+IntToStr(Expy)+') )'
          + ' Cmd: ' + inttostr(Cmd) + ' )';
    SynEdit.Text := Txt;
    //SynEdit.SelectionMode := Mode;

    SynEdit.CaretXY := Point(x, y);
    SynEdit.CommandProcessor(Cmd, ' ', nil);
    AssertEquals(Name, ExpText, SynEdit.ViewedTextBuffer.Text);
    AssertEquals(Name+' ExpX', ExpX, SynEdit.CaretX);
    AssertEquals(Name+' ExpY', ExpY, SynEdit.CaretY);

    for i := 1 to 2 do begin
      Name := Name + inttostr(i);
      SynEdit.Undo;
      AssertEquals(Name + ' undo Text',    Txt,     SynEdit.ViewedTextBuffer.Text);
      AssertEquals(Name+' X', X, SynEdit.CaretX);
      AssertEquals(Name+' Y', Y, SynEdit.CaretY);

      SynEdit.Redo;
      AssertEquals(Name + ' redo', ExpText, SynEdit.ViewedTextBuffer.Text);
      AssertEquals(Name+' ExpX', ExpX, SynEdit.CaretX);
      AssertEquals(Name+' ExpY', ExpY, SynEdit.CaretY);
    end;
  end;

const
    cr: String = LineEnding;
    t1: String = 'abcdef'  + LineEnding;
    t2: String = '  mn'    + LineEnding;
    t3: String = '123 456 7' + LineEnding;
begin
  test1('ecDeleteChar',     t1,      2,1, ecDeleteChar, 'acdef' + cr,   2,1);
  test1('ecDeleteChar EOL', t1 + t2, 7,1, ecDeleteChar, 'abcdef' + t2,  7,1);

  test1('ecDeleteWord',     t3,      5,1, ecDeleteWord, '123 7' + cr,   5,1);

  test1('ecDeleteLastChar',     t1,      3,1, ecDeleteLastChar, 'acdef' + cr,   2,1);
  test1('ecDeleteLastChar EOL', t1 + t2, 1,2, ecDeleteLastChar, 'abcdef' + t2,  7,1);

  test1('ecDeleteLastWord',     t3,      8,1, ecDeleteLastWord, '123  7' + cr,       5,1);
end;



initialization

  RegisterTest(TTestSynSelection); 
end.

