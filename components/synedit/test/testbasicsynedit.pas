unit TestBasicSynEdit;

(* TODO:
   - TestEditEmpty:
     Test with different sets of VirtualViews (with/without trimming (enabled/module present at all)
*)

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, testregistry, LCLProc, LCLType, Forms, TestBase,
  SynEdit, SynEditTextTrimmer, SynEditKeyCmds;

type

  { TTestBasicSynEdit }

  TTestBasicSynEdit = class(TTestBase)
  private
    InsertFlag: Boolean;
    TrimType: TSynEditStringTrimmingType;
    TrimEnabled: Boolean;
  protected
    procedure ReCreateEdit; reintroduce;
  published
    procedure TestEditEmpty;
    procedure TestEditTabs;
    procedure TestEditPhysicalLogical;
    procedure TestCaretAutoMove;
    procedure TestEditHomeEnd;
  end;

implementation

procedure TTestBasicSynEdit.ReCreateEdit;
begin
  inherited ReCreateEdit;
  SynEdit.InsertMode := InsertFlag;
  SynEdit.TrimSpaceType := TrimType;
  if TrimEnabled then
    SynEdit.Options := SynEdit.Options + [eoTrimTrailingSpaces]
  else
    SynEdit.Options := SynEdit.Options - [eoTrimTrailingSpaces];

end;

procedure TTestBasicSynEdit.TestEditEmpty;
  procedure CheckText(aName: String; ExpText: String; ExpLines: Integer);
  var
    s: String;
  begin
    AssertEquals(BaseTestName + aName+' Count', ExpLines, SynEdit.Lines.Count);
    // TestIsText (without Views => just real text)
    // TestIsFullText (with Views => eg trimmed spaces)
    s:='';
    if ExpLines > 0 then
      s := LineEnding;
    TestIsText(aName+' Text', ExpText+s);
  end;
  procedure DoChecks;
  begin
    ReCreateEdit;
    CheckText('Empty', '', 0);
    SynEdit.CommandProcessor(ecChar, 'x', nil);
    CheckText('After Insert "x"', 'x', 1);

    ReCreateEdit;
    SynEdit.CommandProcessor(ecChar, ' ', nil);
    if TrimEnabled then begin
      CheckText('After Insert <space>', '', 1);
      if TrimType = settIgnoreAll then begin
        TestIsFullText('After Insert <space> (FullText)', ''+LineEnding);
        TestIsCaret('After Insert <space>', 2,1);
      end else begin
        TestIsFullText('After Insert <space> (FullText)', ' '+LineEnding);
        TestIsCaret('After Insert <space>', 2,1);
      end;
    end else begin
      CheckText('After Insert <space>', ' ', 1);
      TestIsFullText('After Insert <space> (FullText)', ' '+LineEnding);
      TestIsCaret('After Insert <space>', 2,1);
    end;

    ReCreateEdit;
    CheckText('Empty', '', 0);
    SynEdit.CommandProcessor(ecDeleteChar, '', nil);
    CheckText('After ecDeleteChar', '', 0);

    ReCreateEdit;
    SynEdit.CommandProcessor(ecDeleteLastChar, '', nil);
    CheckText('After ecDeleteLastChar', '', 0);

    ReCreateEdit;
    SynEdit.CommandProcessor(ecDeleteWord, '', nil);
    CheckText('After ecDeleteWord', '', 0);

    ReCreateEdit;
    SynEdit.CommandProcessor(ecDeleteLastWord, '', nil);
    CheckText('After ecDeleteLastWord', '', 0);

    ReCreateEdit;
    SynEdit.CommandProcessor(ecInsertLine, '', nil);
    CheckText('After ecInsertLine', LineEnding, 2);

    ReCreateEdit;
    SynEdit.CommandProcessor(ecLineBreak, '', nil);
    CheckText('After ecLineBreak', LineEnding, 2);

  end;
begin
  TrimEnabled := True;
  TrimType := settEditLine;
  PushBaseName('Trim=EditLine');
    PushBaseName('InsertMode');
      InsertFlag := True;
      DoChecks;
    PopPushBaseName('OverwriteMode');
      InsertFlag := False;
      DoChecks;
    PopBaseName;

  TrimType := settIgnoreAll;
  PopPushBaseName('Trim=IgnoreAll');
    PushBaseName('InsertMode');
      InsertFlag := True;
      DoChecks;
    PopPushBaseName('OverwriteMode');
      InsertFlag := False;
      DoChecks;
    PopBaseName;

  TrimEnabled := False;
  PopPushBaseName('Trim=Disabled');
    PushBaseName('InsertMode');
      InsertFlag := True;
      DoChecks;
    PopPushBaseName('OverwriteMode');
      InsertFlag := False;
      DoChecks;
    PopBaseName;

end;

procedure TTestBasicSynEdit.TestEditTabs;
begin
  ReCreateEdit;
  // witout eoAutoIndent
  SynEdit.Options  := SynEdit.Options
                    - [eoTabIndent, eoTabsToSpaces, eoSpacesToTabs, eoAutoIndent, eoSmartTabs, eoSmartTabDelete];
  SynEdit.TabWidth := 4;
  SetLines(['  abc', #9'abcde', '']);
  SetCaret(2, 2); // after tab
  TestIsCaretPhys('Before delete tab', 5, 2);
  SynEdit.CommandProcessor(ecDeleteLastChar, '', nil);

  TestIsCaret('After delete tab', 1, 2);
  TestIsCaretPhys('After delete tab', 1, 2);
  TestIsText('After delete tab', ['  abc', 'abcde', '']);

  ReCreateEdit;
  // with eoAutoIndent
  SynEdit.Options  := SynEdit.Options + [eoSmartTabs, eoSmartTabDelete, eoAutoIndent]
                    - [eoTabIndent, eoTabsToSpaces, eoSpacesToTabs];
  SynEdit.TabWidth := 4;
  SetLines(['  abc', #9'abcde', '']);
  SetCaret(2, 2); // after tab
  TestIsCaretPhys('Before delete tab', 5, 2);
  SynEdit.CommandProcessor(ecDeleteLastChar, '', nil);

  // reuqired indent is filled up with spaces
  TestIsCaret('After delete tab (smart)', 3, 2);
  TestIsCaretPhys('After delete tab (smart)', 3, 2);
  TestIsText('After delete tab (smart)', ['  abc', '  abcde', '']);

end;

procedure TTestBasicSynEdit.TestEditPhysicalLogical;

  procedure TestPhysLog(name: string; y, x, expX: integer);
  var gotX: Integer;
  begin
    name := name + ' y='+inttostr(y)+' x='+inttostr(x);
    gotX := SynEdit.PhysicalToLogicalPos(Point(x, y)).x;
    AssertEquals(name+'  PhysicalToLogicalPos', expX, gotX);
    gotX := SynEdit.PhysicalToLogicalCol(SynEdit.Lines[y-1], y-1, x);
    AssertEquals(name+'  PhysicalToLogicalCol', expX, gotX);
  end;

  procedure TestLogPhys(name: string; y, x, expX: integer);
  var gotX: Integer;
  begin
    name := name + ' y='+inttostr(y)+' x='+inttostr(x);
    gotX := SynEdit.LogicalToPhysicalPos(Point(x, y)).x;
    AssertEquals(name+'  LogicalToPhysicalPos', expX, gotX);
    gotX := SynEdit.LogicalToPhysicalCol(SynEdit.Lines[y-1], y-1, x);
    AssertEquals(name+'  LogicalToPhysicalCol', expX, gotX);
  end;

begin
  ReCreateEdit;
  SynEdit.TabWidth := 6;

  SetLines(['abc', ' ääX', #9'mn', 'abc'#9'de', #9'Xää.']);

  TestLogPhys('simple line (abc)', 1, 1, 1);
  TestLogPhys('simple line (abc)', 1, 2, 2);
  TestLogPhys('simple line (abc)', 1, 4, 4);
  TestLogPhys('simple line (abc)', 1, 5, 5);
  TestLogPhys('simple line (abc)', 1, 6, 6);
  TestLogPhys('line with 2byte-char', 2, 1, 1);
  TestLogPhys('line with 2byte-char', 2, 2, 2);
  TestLogPhys('line with 2byte-char', 2, 4, 3); // after ae
  TestLogPhys('line with 2byte-char', 2, 6, 4);
  TestLogPhys('line with 2byte-char', 2, 7, 5);
  TestLogPhys('line with 2byte-char', 2, 8, 6);
  TestLogPhys('line with 2byte-char', 2, 11, 9);
  TestLogPhys('line with tab (start)', 3, 1, 1);
  TestLogPhys('line with tab (start)', 3, 2, 7);
  TestLogPhys('line with tab (middle)', 4, 3, 3);
  TestLogPhys('line with tab (middle)', 4, 4, 4); // before tab
  TestLogPhys('line with tab (middle)', 4, 5, 7); // after tab
  TestLogPhys('line with tab (middle)', 4, 6, 8);
  TestLogPhys('line with tab (middle)', 4, 9, 11);
  TestLogPhys('line with tab (start) + 2bc', 5, 1, 1);
  TestLogPhys('line with tab (start) + 2bc', 5, 2, 7);
  TestLogPhys('line with tab (start) + 2bc', 5, 3, 8);
  TestLogPhys('line with tab (start) + 2bc', 5, 5, 9);

  TestPhysLog('simple line (abc)', 1, 1, 1);
  TestPhysLog('simple line (abc)', 1, 2, 2);
  TestPhysLog('simple line (abc)', 1, 4, 4);
  TestPhysLog('simple line (abc)', 1, 5, 5);
  TestPhysLog('simple line (abc)', 1, 6, 6);
  TestPhysLog('line with 2byte-char', 2, 1, 1);
  TestPhysLog('line with 2byte-char', 2, 2, 2);
  TestPhysLog('line with 2byte-char', 2, 3, 4);
  TestPhysLog('line with 2byte-char', 2, 4, 6);
  TestPhysLog('line with 2byte-char', 2, 5, 7);
  TestPhysLog('line with 2byte-char', 2, 6, 8);
  TestPhysLog('line with 2byte-char', 2, 7, 9);
  TestPhysLog('line with tab (start)', 3, 1, 1);
  TestPhysLog('line with tab (start)', 3, 2, 1);
  TestPhysLog('line with tab (start)', 3, 5, 1);
  TestPhysLog('line with tab (start)', 3, 6, 1);
  TestPhysLog('line with tab (start)', 3, 7, 2);
  TestPhysLog('line with tab (start)', 3, 8, 3);
  TestPhysLog('line with tab (start)', 3, 9, 4);
  TestPhysLog('line with tab (start)', 3, 11, 6);

end;

procedure TTestBasicSynEdit.TestCaretAutoMove;

  procedure DoTest(name: string; y, x, insertY, insertX, InsertY2, InsertX2: integer;
                   txt: string; expY, expX: Integer);
  begin
    name := name + ' y='+inttostr(y)+' x='+inttostr(x);
    if y > 0 then begin
      ReCreateEdit;
      SynEdit.TabWidth := 6;
      SetLines(['x', 'abc', ' ääX', #9'mn', 'abc'#9'de', #9'Xää.']);
      SynEdit.CaretXY := Point(x, y);
    end;

    SynEdit.TextBetweenPointsEx[Point(insertX, insertY), point(insertX2, InsertY2), scamAdjust]
      := txt;
debugln(dbgstr(SynEdit.Text));
    TestIsCaretPhys(name, expX, expY);
  end;

const
  cr = LineEnding;
begin


  DoTest('simple insert',              2,2,   2,1,  2,1, 'X',      2,3);
  DoTest('simple insert CR',           2,2,   2,1,  2,1, 'X'+cr,   3,2);
  DoTest('simple insert CR+',          2,2,   2,1,  2,1, cr+'X',   3,3);
  DoTest('simple delete',              2,2,   2,1,  2,2, '',       2,1);
  DoTest('simple delete CR',           2,2,   1,2,  2,1, '',       1,3);
  DoTest('+simple delete CR',          2,2,   1,1,  2,1, '',       1,2);

  DoTest('simple insert (eol)',        2,4,   2,1,  2,1, 'X',   2,5);
  DoTest('simple insert (past eol)',   2,7,   2,1,  2,1, 'X',   2,8);

  DoTest('insert with tab',            4,8,   4,1,  4,1, 'X',      4,8);
  DoTest('insert with tab (cont)',    -4,8,   4,2,  4,2, 'Y',      4,8);
  DoTest('insert with tab (cont)',    -4,8,   4,3,  4,3, 'abc',    4,8);
  DoTest('insert with tab (cont)',    -4,8,   4,6,  4,6, 'Z',      4,14);
  DoTest('insert with tab (cont)',    -4,8,   4,7,  4,7, '.',      4,14);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,14);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,8);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,8);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,8);


  SynEdit.CaretObj.IncAutoMoveOnEdit;
  DoTest('insert with tab (am-block)',            4,8,   4,1,  4,1, 'X',      4,8);
  DoTest('insert with tab (am-block) (cont)',    -4,8,   4,2,  4,2, 'Y',      4,8);
  DoTest('insert with tab (am-block) (cont)',    -4,8,   4,3,  4,3, 'abc',    4,8);
  DoTest('insert with tab (am-block) (cont)',    -4,8,   4,6,  4,6, 'Z',      4,14);
  DoTest('insert with tab (am-block) (cont)',    -4,8,   4,7,  4,7, '.',      4,14);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,14);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,8);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,8);
  DoTest('delete with tab (cont)',    -4,8,   4,1,  4,2, '',       4,8);
  SynEdit.CaretObj.DecAutoMoveOnEdit;

end;

procedure TTestBasicSynEdit.TestEditHomeEnd;
  procedure DoInit1;
  begin
    InsertFlag := False;
    TrimType := settIgnoreAll;
    ReCreateEdit;
    SynEdit.TabWidth := 6;
    SyneDit.Options := [];
    SyneDit.Options2 := [];
    SetLines(['',           //1
              '',

              'test',       // 3
              '',
              '',
              '                                                      ',
              'test',       // 3
              #9#9#9#9#9,

              '   spaced',  // 9
              '',
              '',
              '                                                      ',
              '   spaced',
              #9#9#9#9#9,

              #9'tabbed',    // 15
              '',
              '',
              '                                                      ',
              #9'tabbed',
              #9#9#9#9#9,

              #9'   tabbed spaced', // 21
              '',
              '',
              '                                                      ',
              #9'   tabbed spaced',
              #9#9#9#9#9,

              '   ', // 27  (space only)
              '',
              '',
              '                                                      ',
              #9'   ',
              #9#9#9#9#9,

              '        spaced 9 for tab',  // 33
              #9#9#9#9#9,

              ' X   ', // 35
              ' X'#9, // 36

              ''
              ]);

  end;

  procedure TestHome(Name:String; X, Y, ExpX1, ExpX2, ExpX3: Integer; ExpLTxTStartX: Integer = -1);
  begin
    SetCaretPhys(X, Y);
    synedit.CommandProcessor(ecLineStart, '', nil);
    TestIsCaretPhys(Name + '(1st home)', ExpX1,Y);
    synedit.CommandProcessor(ecLineStart, '', nil);
    TestIsCaretPhys(Name + '(2nd home)', ExpX2,Y);
    synedit.CommandProcessor(ecLineStart, '', nil);
    TestIsCaretPhys(Name + '(3rd home)', ExpX3,Y);
    if ExpLTxTStartX > 0 then begin
      SetCaretPhys(X, Y);
      synedit.CommandProcessor(ecLineTextStart, '', nil);
      TestIsCaretPhys(Name + '(1st line-text-start)', ExpLTxTStartX,Y);
      synedit.CommandProcessor(ecLineTextStart, '', nil);
      TestIsCaretPhys(Name + '(2nd line-text-start)', ExpLTxTStartX,Y);
      synedit.CommandProcessor(ecLineTextStart, '', nil);
      TestIsCaretPhys(Name + '(3rd line-text-start)', ExpLTxTStartX,Y);
    end;
  end;

  procedure TestEnd(Name:String; X, Y, ExpX1, ExpX2, ExpX3: Integer);
  begin
    SetCaretPhys(X, Y);
    synedit.CommandProcessor(ecLineEnd, '', nil);
    TestIsCaretPhys(Name + '(1st end)', ExpX1,Y);
    synedit.CommandProcessor(ecLineEnd, '', nil);
    TestIsCaretPhys(Name + '(2nd end)', ExpX2,Y);
    synedit.CommandProcessor(ecLineEnd, '', nil);
    TestIsCaretPhys(Name + '(3rd end)', ExpX3,Y);
  end;

begin
  // None Smart-Home:
  //   Caret goes x=1, then x=indend
  // Smart-Home:
  //   Caret goes x=indent, then 1,    IF AFTER indent, or at x=1
  //   Caret goes x=1, then x=indend,  IF at x=indent, or inside indent
  // Both
  //   Caret does not go past eol, unless explicitly enabled
  //   if spaces/tab exist at start of otherwise empty line, caret will go to prev-line indent

  {%region}
  DoInit1;
  PushBaseName('no smart / no past-eol');

  TestHome('empty 1st line',                      1, 1,  1,1,1,   1);
  TestHome('empty 2nd line',                      1, 2,  1,1,1,   1);

  TestHome('unindented line',                     1, 3,  1,1,1,   1);
  TestHome('unindented line x-in-line',           4, 3,  1,1,1,   1);
  TestHome('1st line after unindendet',           1, 4,  1,1,1,   1);
  TestHome('2nd line after unindendet',           1, 5,  1,1,1,   1);
  TestHome('3rd #32 line after unindendet',       2, 6,  1,1,1,   1);
  TestHome('4th #9  line after unindendet',       2, 8,  1,1,1,   1);

  TestHome('space indented line',                 1, 9,  4,1,4,   4);
  TestHome('space indented line x-after-indent',  4, 9,  1,4,1,   4); // go to indent, after absolute home
  TestHome('space indented line x-in-indent',     3, 9,  1,4,1,   4);
  TestHome('space indented line x-in-line',       6, 9,  1,4,1,   4);
  TestHome('1st after space indented line',       1,10,  1,1,1,   1);
  TestHome('2nd after space indented line',       1,11,  1,1,1,   1);
  TestHome('3rd #32 after space indented line',   2,12,  1,4,1,   1);
  TestHome('4th #9  after space indented line',   2,14,  1,4,1,   1);
  TestHome('#9  after long space indented line',  2,34,  1,9,1,   1);
  SyneDit.Options2 := SyneDit.Options2 + [eoCaretSkipTab];
  TestHome('4th #9  after space indented line  [skipT]',   7,14,  1,1,1,   1);
  TestHome('#9  after long space indented line [skipT]',   1,34,  7,1,7,   1);
  TestHome('#9  after long space indented line [skipT]',   7,34,  1,7,1,   1);
  TestHome('#9  after long space indented line [skipT]',  13,34,  1,7,1,   1);
  SyneDit.Options2 := SyneDit.Options2 - [eoCaretSkipTab];

  TestHome('tab indented line',                   1,15,  7,1,7,   7);
  TestHome('tab indented line x-after-indent',    7,15,  1,7,1,   7);
  TestHome('tab indented line x-in-indent',       5,15,  1,7,1,   7);
  TestHome('tab indented line x-in-line',         9,15,  1,7,1,   7);
  TestHome('1st after tab indented line',         1,16,  1,1,1,   1);
  TestHome('2nd after tab indented line',         1,17,  1,1,1,   1);
  TestHome('3rd #32 after tab indented line',     2,18,  1,7,1,   1);
  TestHome('4th #9  after tab indented line',     2,20,  1,7,1,   1);
  {%endregion}

  {%region}
  DoInit1;
  SyneDit.Options := [eoScrollPastEol];
  PopPushBaseName('no smart / past-eol');

  TestHome('empty 1st line',                      1, 1,  1,1,1,   1);
  TestHome('empty 2nd line',                      1, 2,  1,1,1,   1);

  TestHome('unindented line',                     1, 3,  1,1,1,   1);
  TestHome('unindented line x-in-line',           4, 3,  1,1,1,   1);
  TestHome('1st line after unindendet',           1, 4,  1,1,1,   1);
  TestHome('2nd line after unindendet',           1, 5,  1,1,1,   1);
  TestHome('3rd #32 line after unindendet',       2, 6,  1,1,1,   1);
  TestHome('4th #9  line after unindendet',       2, 8,  1,1,1,   1);

  TestHome('space indented line',                 1, 9,  4,1,4,   4);
  TestHome('space indented line x-after-indent',  4, 9,  1,4,1,   4); // go to indent, after absolute home
  TestHome('space indented line x-in-indent',     3, 9,  1,4,1,   4);
  TestHome('space indented line x-in-line',       6, 9,  1,4,1,   4);
  TestHome('1st after space indented line',       1,10,  4,1,4,   1);
  TestHome('1st after space indented line (x)',   2,10,  1,4,1,   1);
  TestHome('2nd after space indented line',       1,11,  4,1,4,   1);
  TestHome('3rd #32 after space indented line',   2,12,  1,4,1,   1);
  TestHome('4th #9  after space indented line',   2,14,  1,4,1,   1);
  TestHome('#9  after long space indented line',  2,34,  1,9,1,   1);
  SyneDit.Options2 := SyneDit.Options2 + [eoCaretSkipTab];
  TestHome('4th #9  after space indented line  [skipT]',   7,14,  1,1,1,   1);
  TestHome('#9  after long space indented line [skipT]',   1,34,  7,1,7,   1);
  TestHome('#9  after long space indented line [skipT]',   7,34,  1,7,1,   1);
  TestHome('#9  after long space indented line [skipT]',  13,34,  1,7,1,   1);
  SyneDit.Options2 := SyneDit.Options2 - [eoCaretSkipTab];

  TestHome('tab indented line',                   1,15,  7,1,7,   7);
  TestHome('tab indented line x-after-indent',    7,15,  1,7,1,   7);
  TestHome('tab indented line x-in-indent',       5,15,  1,7,1,   7);
  TestHome('tab indented line x-in-line',         9,15,  1,7,1,   7);
  TestHome('1st after tab indented line',         1,16,  7,1,7,   1);
  TestHome('1st after tab indented line(x)',      2,16,  1,7,1,   1);
  TestHome('2nd after tab indented line',         1,17,  7,1,7,   1);
  TestHome('3rd #32 after tab indented line',     2,18,  1,7,1,   1);
  TestHome('4th #9  after tab indented line',     2,20,  1,7,1,   1);
  {%endregion}


  {%region}
  DoInit1;
  SyneDit.Options := [eoEnhanceHomeKey];

  PopPushBaseName('smart home / no past-eol');

  TestHome('empty 1st line',                      1, 1,  1,1,1,   1);
  TestHome('empty 2nd line',                      1, 2,  1,1,1,   1);

  TestHome('unindented line',                     1, 3,  1,1,1,   1);
  TestHome('unindented line x-in-line',           4, 3,  1,1,1,   1);
  TestHome('1st line after unindendet',           1, 4,  1,1,1,   1);
  TestHome('2nd line after unindendet',           1, 5,  1,1,1,   1);
  TestHome('3rd #32 line after unindendet',       2, 6,  1,1,1,   1);
  TestHome('4th #9  line after unindendet',       2, 8,  1,1,1,   1);

  TestHome('space indented line',                 1, 9,  4,1,4,   4); // go to absolut home (x-=1), after indent
  TestHome('space indented line x-after-indent',  4, 9,  1,4,1,   4);
  TestHome('space indented line x-in-indent',     3, 9,  1,4,1,   4);
  TestHome('space indented line x-in-line',       6, 9,  4,1,4,   4);
  TestHome('1st after space indented line',       1,10,  1,1,1,   1);
  TestHome('2nd after space indented line',       1,11,  1,1,1,   1);
  TestHome('3rd #32 after space indented line',   2,12,  1,4,1,   1);
  TestHome('4th #9  after space indented line',   2,14,  1,4,1,   1);
  TestHome('#9  after long space indented line',  2,34,  1,9,1,   1);
  SyneDit.Options2 := SyneDit.Options2 + [eoCaretSkipTab];
  TestHome('4th #9  after space indented line  [skipT]',   7,14,  1,1,1,   1);
  TestHome('#9  after long space indented line [skipT]',   1,34,  7,1,7,   1);
  TestHome('#9  after long space indented line [skipT]',   7,34,  1,7,1,   1);
  TestHome('#9  after long space indented line [skipT]',  13,34,  7,1,7,   1);
  SyneDit.Options2 := SyneDit.Options2 - [eoCaretSkipTab];

  TestHome('tab indented line',                   1,15,  7,1,7,   7);
  TestHome('tab indented line x-after-indent',    7,15,  1,7,1,   7);
  TestHome('tab indented line x-in-indent',       5,15,  1,7,1,   7);
  TestHome('tab indented line x-in-line',         9,15,  7,1,7,   7);
  TestHome('1st after tab indented line',         1,16,  1,1,1,   1);
  TestHome('2nd after tab indented line',         1,17,  1,1,1,   1);
  TestHome('3rd #32 after tab indented line',     2,18,  1,7,1,   1);
  TestHome('3rd #32 after tab indented line',    11,18,  7,1,7,   1);
  TestHome('4th #9  after tab indented line',     2,20,  1,7,1,   1);
  {%endregion}


  {%region}
  DoInit1;
  SyneDit.Options := [eoEnhanceHomeKey, eoScrollPastEol];

  PopPushBaseName('smart home / past-eol');

  TestHome('empty 1st line',                      1, 1,  1,1,1,   1);
  TestHome('empty 2nd line',                      1, 2,  1,1,1,   1);

  TestHome('unindented line',                     1, 3,  1,1,1,   1);
  TestHome('unindented line x-in-line',           4, 3,  1,1,1,   1);
  TestHome('1st line after unindendet',           1, 4,  1,1,1,   1);
  TestHome('2nd line after unindendet',           1, 5,  1,1,1,   1);
  TestHome('3rd #32 line after unindendet',       2, 6,  1,1,1,   1);
  TestHome('4th #9  line after unindendet',       2, 8,  1,1,1,   1);

  TestHome('space indented line',                 1, 9,  4,1,4,   4); // go to absolut home (x-=1), after indent
  TestHome('space indented line x-after-indent',  4, 9,  1,4,1,   4);
  TestHome('space indented line x-in-indent',     3, 9,  1,4,1,   4);
  TestHome('space indented line x-in-line',       6, 9,  4,1,4,   4);
  TestHome('1st after space indented line',       1,10,  4,1,4,   1);
  TestHome('2nd after space indented line',       1,11,  4,1,4,   1);
  TestHome('3rd #32 after space indented line',   2,12,  1,4,1,   1);
  TestHome('4th #9  after space indented line',   2,14,  1,4,1,   1);
  TestHome('#9  after long space indented line',  2,34,  1,9,1,   1);
  SyneDit.Options2 := SyneDit.Options2 + [eoCaretSkipTab];
  TestHome('4th #9  after space indented line [skipT]',   7,14,  1,1,1,   1);
  TestHome('#9  after long space indented line [skipT]',  7,34,  1,7,1,   1);
  SyneDit.Options2 := SyneDit.Options2 - [eoCaretSkipTab];

  TestHome('tab indented line',                   1,15,  7,1,7,   7);
  TestHome('tab indented line x-after-indent',    7,15,  1,7,1,   7);
  TestHome('tab indented line x-in-indent',       5,15,  1,7,1,   7);
  TestHome('tab indented line x-in-line',         9,15,  7,1,7,   7);
  TestHome('1st after tab indented line',         1,16,  7,1,7,   1);
  TestHome('1st after tab indented line (x)',     2,16,  1,7,1,   1);
  TestHome('2nd after tab indented line',         1,17,  7,1,7,   1);
  TestHome('3rd #32 after tab indented line',     2,18,  1,7,1,   1);
  TestHome('3rd #32 after tab indented line',    11,18,  7,1,7,   1);
  TestHome('4th #9  after tab indented line',     2,20,  1,7,1,   1);
  {%endregion}

  PopPushBaseName('NO smart end/ NO past-eol');
  DoInit1;
  TestEnd ('empty 1st line',  1,1,  1,1,1);
  TestEnd ('end',       1,35,  6,3,6);
  TestEnd ('end tab',   1,36,  7,3,7);

  PopPushBaseName('smart end/ NO past-eol');
  DoInit1;
  SyneDit.Options2 := [eoEnhanceEndKey];
  TestEnd ('end',       1,35,  3,6,3);
  TestEnd ('end tab',   1,36,  3,7,3);

  //SyneDit.Options := [eoScrollPastEol, eoEnhanceHomeKey];
  //SyneDit.Options2 := [eoEnhanceEndKey];

end;



initialization

  RegisterTest(TTestBasicSynEdit); 
end.

