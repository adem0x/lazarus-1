{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynEditTypes.pas, released 2000-04-07.
The Original Code is based on parts of mwCustomEdit.pas by Martin Waldenburg,
part of the mwEdit component suite.
Portions created by Martin Waldenburg are Copyright (C) 1998 Martin Waldenburg.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id$

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}

unit SynEditTypes;

{$I synedit.inc}

interface

const
  TSynSpecialChars = ['�'..'�', '�'..'�', '�'..'�'];
  TSynValidStringChars = ['_', '0'..'9', 'A'..'Z', 'a'..'z'] + TSynSpecialChars;
  TSynWhiteChars = [' ', #9];
  TSynWordBreakChars = ['.', ',', ';', ':', '"', '''', '!', '?', '[', ']', '(',
            ')', '{', '}', '@', '^', '-', '=', '+', '*', '/', '\', '|','<','>'];

type
  TSynIdentChars = set of char;

  {$IFDEF SYN_LAZARUS}
  // NOTE: the note below is not valid for the LCL which uses UTF-8
  {$ELSE}
  //NOTE: This will need to be localized and currently will not work with
  //      MBCS languages like Japanese or Korean.
  {$ENDIF}

  PSynSelectionMode = ^TSynSelectionMode;
  // to be binary (clipboard) compatible with other (Delphi compiled) synedits
  // use {$PACKENUM 1}
{$IFDEF SYN_LAZARUS}{$PACKENUM 1}{$ENDIF SYN_LAZARUS}
  TSynSelectionMode = (smNormal, smLine, smColumn);
{$IFDEF SYN_LAZARUS}{$PACKENUM 4}{$ENDIF SYN_LAZARUS}

  TSynSearchOption = (ssoMatchCase, ssoWholeWord, ssoBackwards,
    ssoEntireScope, ssoSelectedOnly, ssoReplace, ssoReplaceAll, ssoPrompt
    {$IFDEF SYN_LAZARUS},
    ssoSearchInReplacement,// continue search in replacement
    ssoRegExpr, ssoRegExprMultiLine{$ENDIF});
  TSynSearchOptions = set of TSynSearchOption;

implementation

end.


