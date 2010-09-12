unit fpWebNewHTMLFileUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  StdCtrls, ComCtrls;

type

  { TfpWebNewHTMLFileForm }

  TfpWebNewHTMLFileForm = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbCharset: TComboBox;
    cbShema: TComboBox;
    edtAutor: TEdit;
    edtCopyr: TEdit;
    edtCSS: TComboBox;
    edtJS: TComboBox;
    edtTitle: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    procedure FillLinks;
    procedure SaveHtmlProps;
    procedure LoadHtmlProps;
  public
    function HtmlText:string;
  end; 

var
  fpWebNewHTMLFileForm: TfpWebNewHTMLFileForm;

const
  HTML_Autor     = 'HTML_Autor';
  HTML_Copyright = 'HTML_Copyright';

implementation

uses fpWebStrConsts, SrcEditorIntf, ProjectIntf, LazIDEIntf;

{$R *.lfm}
const
  HTMLHeaders : array [0..7] of string =
    ('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'+LineEnding +
     '<HTML>',

     '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'+LineEnding +
     '<HTML>',

     '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">'+LineEnding +
     '<HTML>',

     '<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
     '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'+LineEnding+
     '<html xmlns="http://www.w3.org/1999/xhtml">',

     '<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
     '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'+LineEnding+
     '<html xmlns="http://www.w3.org/1999/xhtml">',

     '<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
     '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'+LineEnding+
     '<html xmlns="http://www.w3.org/1999/xhtml">',

     '<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
     '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.0//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd">'+LineEnding+
     '<html xmlns="http://www.w3.org/1999/xhtml">',

     '<?xml version="1.0" encoding="utf-8"?>'+LineEnding+
     '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'+LineEnding+
     '<html xmlns="http://www.w3.org/1999/xhtml">'
    );

{ TfpWebNewHTMLFileForm }

procedure TfpWebNewHTMLFileForm.FormCreate(Sender: TObject);
begin
  Caption:=SNewHtmlFileProps;
  Label3.Caption:=SHTMLTitle;//
  Label1.Caption:=SHTMLAutor;
  Label2.Caption:=SHTMLCopyright;
  Label4.Caption:=SHTMLCharset;
  Label5.Caption:=SHTMLCssFile;
  Label6.Caption:=SHTMLJSFile;
  //

  LoadHtmlProps;
  edtCSS.Items.Clear;
  edtJS.Items.Clear;
  FillLinks;
end;

procedure TfpWebNewHTMLFileForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  if ModalResult = mrOk then
    SaveHtmlProps;
end;

procedure TfpWebNewHTMLFileForm.FillLinks;
var
  i:integer;
  S, Ext:string;
begin
  if Assigned(LazarusIDE) and Assigned(LazarusIDE.ActiveProject) then
  begin
    for i:=0 to LazarusIDE.ActiveProject.FileCount - 1 do
    begin
      S:=LazarusIDE.ActiveProject.Files[i].Filename;
      Ext:=UpperCase(ExtractFileExt(S));
      if Ext = '.JS' then
        edtJS.Items.Add(S)
      else
      if Ext = '.CSS' then
        edtCSS.Items.Add(S);
    end;
  end;
end;

procedure TfpWebNewHTMLFileForm.SaveHtmlProps;
begin
  if Assigned(LazarusIDE) and Assigned(LazarusIDE.ActiveProject) then
  begin
    LazarusIDE.ActiveProject.CustomSessionData.Values[HTML_Autor] := edtAutor.Text;
    LazarusIDE.ActiveProject.CustomSessionData.Values[HTML_Copyright] := edtCopyr.Text;
    LazarusIDE.ActiveProject.Modified:=True;
  end;
end;

procedure TfpWebNewHTMLFileForm.LoadHtmlProps;
begin
  if Assigned(LazarusIDE) and Assigned(LazarusIDE.ActiveProject) then
  begin
    edtAutor.Text := LazarusIDE.ActiveProject.CustomSessionData.Values[HTML_Autor];
    edtCopyr.Text := LazarusIDE.ActiveProject.CustomSessionData.Values[HTML_Copyright];
  end;
end;

function TfpWebNewHTMLFileForm.HtmlText: string;
begin
  Result:= HTMLHeaders[cbShema.ItemIndex] + LineEnding+'  <head>'+LineEnding;
  Result:=Result + '    <title>'+fpWebNewHTMLFileForm.edtTitle.Text+'</title>'+LineEnding;
  if fpWebNewHTMLFileForm.edtAutor.Text <> '' then
    Result:=Result + '    <meta name="author" content="'+fpWebNewHTMLFileForm.edtAutor.Text+'" >'+LineEnding;
  if fpWebNewHTMLFileForm.edtCopyr.Text <> '' then
    Result:=Result + '    <meta name="copyright" content="'+fpWebNewHTMLFileForm.edtCopyr.Text+'">'+LineEnding;
  if fpWebNewHTMLFileForm.cbCharset.Text <> '' then
    Result:=Result + '    <meta http-equiv="content-type" content="text/html; charset='+fpWebNewHTMLFileForm.cbCharset.Text+'">'+LineEnding;
  if fpWebNewHTMLFileForm.edtCSS.Text <> '' then
    Result:=Result + '    <link rel="stylesheet" type="text/css" href="'+fpWebNewHTMLFileForm.edtCSS.Text+'" />'+LineEnding;
  Result:=Result + '  </head>'+LineEnding;
  Result:=Result + '  <body>'+LineEnding;
  Result:=Result + '    <h1> '+fpWebNewHTMLFileForm.edtTitle.Text+' </h1>'+LineEnding;
  Result:=Result + '    <!-- '+SEnterYouText+' -->'+LineEnding;
  Result:=Result + '  </body>'+LineEnding+'</html>'+LineEnding;
end;

end.

