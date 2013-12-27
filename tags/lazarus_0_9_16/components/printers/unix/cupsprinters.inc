{**************************************************************
Implementation for cupsprinter
***************************************************************}

uses udlgSelectPrinter,udlgpropertiesprinter, FileUtil;

//Return always 72 because, PostScript it's 72 only
function TCUPSPrinter.GetXDPI: Integer;
begin
  Result:=72;
end;

//Return always 72 because, PostScript it's 72 only
function TCUPSPrinter.GetYDPI: Integer;
begin
  Result:=72;
end;

constructor TCUPSPrinter.Create;
begin
  inherited Create;

  fcupsPrinters:=nil;
  fcupsPrinter :=nil;
  fcupsHttp    :=nil;
  fcupsPPD     :=nil;
  fcupsOptions :=nil;
  fcupsNumOpts :=0;
end;

destructor TCUPSPrinter.destroy;
begin
  FreeOptions;

  if Assigned(fcupsHttp) then
    httpClose(fcupsHttp);

  inherited destroy;
end;

procedure TCUPSPrinter.FreeOptions;
begin
  if Assigned(fcupsOptions) then
    cupsFreeOptions(fcupsNumOpts,fcupsOptions);

  fcupsNumOpts:=0;
  fcupsOptions:=nil;
  FStates:=FStates-[cpsDefaultPaperNameValid,cpsOrientationValid,
                    cpsPaperNameValid,cpsCopiesValid];
end;

procedure TCUPSPrinter.cupsAddOption(aName,aValue: string);
begin
  if not CUPSLibInstalled then Exit;
  fcupsNumOpts:=cupsdyn.cupsAddOption(PChar(aName),PChar(aValue),fcupsNumOpts,@fcupsOptions);
end;

//Return the value of option set for the selected printer
function TCUPSPrinter.cupsGetOption(aKeyWord: string): String;
begin
  Result:='';
  if not CUPSLibInstalled then Exit;
  if (Printers.Count>0) then
  begin
    if not Assigned(fcupsOptions) then
         SetOptionsOfPrinter;

    Result:=cupsdyn.cupsGetOption(PChar(aKeyWord),fcupsNumOpts,fcupsOptions);
  end;
end;

procedure TCUPSPrinter.GetDebugOptions(Lst : TStrings);
Var Opts : Pcups_option_t;
    Opt  : Pcups_option_t;
    i    : Integer;
begin
  if Assigned(Lst) and (Printers.Count>0) then
  begin
    Lst.Clear;
    if not CUPSLibInstalled then Exit;
    Lst.Add('**************************************************');
    if Assigned(fcupsPrinter) then
    begin
      Opts:=fcupsOptions; // fcupsPrinter^.options;
      Lst.Add(Format('Printer "%s" Number of Options %d',[fcupsPrinter^.Name,fcupsNumOpts{fcupsPrinter^.num_options}]));
      for i:=0 to {fcupsPrinter^.num_options}fcupsNumOpts-1 do
      begin
        Opt:=@Opts[i];
        Lst.Add(Opt^.name+'="'+Opt^.value+'"');
      end;
    end
    else Lst.Add('fcupsPrinter is not assigned');
    Lst.Add('**************************************************');
  end;
end;

procedure TCUPSPrinter.DoCupsConnect;
begin
  if not assigned(fcupsHttp) then
  begin
    if not CUPSLibInstalled then Exit;
    fcupsHttp:=httpConnect(cupsServer(),ippPort());
    if not Assigned(fcupsHttp) then
       raise Exception.Create('Unable to contact server!');
  end;
end;

//Print the file aFileName with a selected printer an options
function TCUPSPrinter.PrintFile(aFileName: String): longint;
var PrinterName : string;
begin
  Result:=-1;
  if not CUPSLibInstalled then Exit;
  aFileName:=ExpandFileName(aFileName);

  if (Printers.Count>0) then
  begin
    if not Assigned(fcupsOptions) then
        SetOptionsOfPrinter;

    if Assigned(fcupsPrinter) then
       PrinterName:=fcupsPrinter^.Name
    else
       PrinterName:='';

    Result:=cupsdyn.cupsPrintFile(PChar(PrinterName),PChar(aFileName),
                                  PChar(Self.Title),
                                  fcupsNumOpts,fcupsOptions);

  end;
end;


//Set State of Job
procedure TCUPSPrinter.SetJobState(aJobId : LongInt; aOp : ipp_op_t);
var Request,R : Pipp_t;                         //IPP Request
    Language  : Pcups_lang_t;                   //Default Language
    URI       : Array[0..HTTP_MAX_URI] of Char; //Printer URI
begin
  if not CUPSLibInstalled then Exit;
  if (Printers.Count>0) then
  begin
    if Assigned(fcupsPrinter) then
    begin
      R:=nil;
      DoCupsConnect;
      Request:=ippNew();
      Language:=cupsLangDefault();

      ippAddString(Request, IPP_TAG_OPERATION, IPP_TAG_CHARSET,
               'attributes-charset', '', cupsLangEncoding(language));

      ippAddString(Request, IPP_TAG_OPERATION, IPP_TAG_LANGUAGE,
               'attributes-natural-language', '', Language^.language);

      URI:=Format('http://%s:%d/jobs/%d',[cupsServer,ippPort,aJobId]);

      ippAddString(Request,IPP_TAG_OPERATION,IPP_TAG_URI,'job-uri','',URI);
      ippAddString(Request,IPP_TAG_OPERATION,IPP_TAG_NAME,'requesting-user-name','',cupsUser());

      Request^.request.op.operation_id := aOp;
      Request^.request.op.request_id   := 1;

      //Do the request and get back a response...
      R:=cupsDoRequest(fcupsHttp, Request, '/jobs/');
      if Assigned(R) then
      begin
        if (R^.request.status.status_code>IPP_OK_CONFLICT) then
          ippDelete(R);
      end;
    end;
  end;
end;

function TCUPSPrinter.GetCupsRequest : Pipp_t;
var Request   : Pipp_t; //IPP Request
    Language  : Pcups_lang_t;     //Default Language
    URI       : Array[0..HTTP_MAX_URI] of Char; //Printer URI
begin
  Result:=Nil;
  if not CUPSLibInstalled then Exit;
  if (Printers.Count>0) then
  begin
    if Assigned(fcupsPrinter) then
    begin
      DoCupsConnect;
      Request:=ippNew();
      {Build an IPP_GET_PRINTER_ATTRIBUTES request,
      which requires the following attributes:
        attributes-charset
        attributes-natural-language
        printer-uri}
      Request^.request.op.operation_id := IPP_GET_PRINTER_ATTRIBUTES;
      Request^.request.op.request_id   := 1;
      Language:=cupsLangDefault;

      ippAddString(Request, IPP_TAG_OPERATION, IPP_TAG_CHARSET,
               'attributes-charset', '', cupsLangEncoding(language));

      ippAddString(Request, IPP_TAG_OPERATION, IPP_TAG_LANGUAGE,
               'attributes-natural-language', '', Language^.language);

      // or this syntax >>
      //URI:=Format('http://%s:%d/printers/%s',[cupsServer,ippPort,fcupsPrinter^.name]);
      URI:=Format('ipp://localhost/printers/%s',[fcupsPrinter^.name]);
      ippAddString(Request,IPP_TAG_OPERATION,IPP_TAG_URI,'printer-uri','',URI);

      //Do the request and get back a response...
      Result:=cupsDoRequest(fcupsHttp, Request, '/');
      if Assigned(Result) then
      begin
        if (Result^.request.status.status_code>IPP_OK_CONFLICT) then
        begin
          ippDelete(Result);
          Result:=nil;
        end;
      end;
    end;
  end;
end;

//Initialize the options with the default options of selected
//printer
procedure TCUPSPrinter.SetOptionsOfPrinter;
Var Opts : Pcups_option_t;
    Opt  : Pcups_option_t;
    i    : Integer;
begin
  if not CUPSLibInstalled then Exit;
  if (Printers.Count>0) then
  begin
    if Assigned(fcupsPrinter) then
    begin
      Opts := fcupsPrinter^.Options;
      for i:=0 to fcupsPrinter^.num_options-1 do
      begin
        Opt:=@Opts[i];
        self.cupsAddOption(Opt^.Name,Opt^.Value);
      end;
    end;
  end;
end;

//Enum all options associed with aKeyWord
function TCUPSPrinter.EnumPPDChoice(Lst : TStrings;
  const aKeyWord : string; OptNames: TStrings = nil) : Integer;
var i         : integer;
    Option    : Pppd_option_t;
    Choice    : Pppd_choice_t;
begin
  Result:=-1;
  if not CUPSLibInstalled then Exit;
  if not Assigned(Lst) then Exit;
  Lst.Clear;

  if (Printers.Count>0) then
  begin
    if Assigned(fcupsPrinter) then
    begin
      if Assigned(fcupsPPD) then
      begin
        Option:=nil;
        Option:=ppdFindOption(fcupsPPD,PChar(aKeyWord));

        If Assigned(Option) then
        begin
          for i:=0 to Option^.num_choices-1 do
          begin
            Choice:=@Option^.choices[i];
            if Choice^.marked=#1 then
              Result:=i;

            Lst.Add(Choice^.text);
            if Assigned(OptNames) then
              OptNames.Add(Choice^.choice);
          end;

          //Not marked choise then the choice is default
          if (Result<0) and (Lst.Count>0) then begin
            Result:=Lst.IndexOf(OPtion^.defchoice);
            if (Result<0)and Assigned(OptNames) then
              Result := OptNames.IndexOf(Option^.DefChoice);
          end;
        end;
      end;
    end;
  end;
end;

procedure TCUPSPrinter.GetEnumAttributeString(aName: PChar; Lst: TStrings);
var
  Reponse   : Pipp_t; //IPP Reponse
  Attribute : Pipp_attribute_t; //Current attribute
  i         : Integer;
begin
  if not assigned(Lst) then
    raise Exception.Create('Lst must be assigned');
  if not CUPSLibInstalled then Exit;
  
  Reponse:=GetCupsRequest;
  if Assigned(Reponse) then
  begin
    try
      Attribute:=ippFindAttribute(Reponse,aName, IPP_TAG_ZERO);
      if Assigned(Attribute) then
      begin
        for i:=0 to Attribute^.num_values-1 do
        begin
          if Attribute^.value_tag=IPP_TAG_INTEGER then
             Lst.add(IntToStr(Pipp_value_t(@Attribute^.values)[i].aInteger))
          else
             Lst.add(Pipp_value_t(@Attribute^.values)[i]._string.text);
        end;
      end;
    finally
      ippDelete(Reponse);
    end;
  end;
end;

function TCUPSPrinter.GetAttributeInteger(aName: PChar; DefaultValue : Integer): Integer;
var
  Reponse   : Pipp_t; //IPP Reponse
  Attribute : Pipp_attribute_t; //Current attribute
begin
  Result:=DefaultValue;
  if not CUPSLibInstalled then Exit;

  Reponse:=GetCupsRequest;
  if Assigned(Reponse) then
  begin
    try
      Attribute:=ippFindAttribute(Reponse,aName, IPP_TAG_ZERO);
      if Assigned(Attribute) then
        Result:=Attribute^.values[0].aInteger;
    finally
      ippDelete(Reponse);
    end;
  end;
end;

function TCUPSPrinter.GetAttributeString(aName: PChar;
  const DefaultValue : string): string;
var
  Reponse   : Pipp_t; //IPP Reponse
  Attribute : Pipp_attribute_t; //Current attribute
begin
  Result:=DefaultValue;
  if not CUPSLibInstalled then Exit;
  Reponse:=GetCupsRequest;
  if Assigned(Reponse) then
  begin
    try
      Attribute:=ippFindAttribute(Reponse,aName, IPP_TAG_ZERO);
      if Assigned(Attribute) then
        Result:=Attribute^.values[0]._string.text;
    finally
      ippDelete(Reponse);
    end;
  end;
end;

function TCUPSPrinter.GetAttributeBoolean(aName: PChar;
  DefaultValue : Boolean): Boolean;
var
  Reponse   : Pipp_t; //IPP Reponse
  Attribute : Pipp_attribute_t; //Current attribute
begin
  Result:=DefaultValue;
  if not CUPSLibInstalled then Exit;
  Reponse:=GetCupsRequest;
  if Assigned(Reponse) then
  begin
    try
      Attribute:=ippFindAttribute(Reponse,aName, IPP_TAG_ZERO);
      if Assigned(Attribute) then
        Result:=(Attribute^.values[0].aBoolean=#1);
    finally
      ippDelete(Reponse);
    end;
  end;
end;

function TCUPSPrinter.GetCanvasRef: TPrinterCanvasRef;
begin
  Result:=TPostscriptPrinterCanvas;
end;

//Override this methode for assign an
//file name at Canvas
procedure TCUPSPrinter.DoBeginDoc;
var
  NewPath: String;

  function TryTemporaryPath(const Path: string): Boolean;
  var
    CurPath: String;
  begin
    CurPath:=CleanAndExpandDirectory(Path);
    Result:=DirPathExists(NewPath);
    if Result then NewPath:=CurPath;
  end;

var
  NewOutputFileName: String;
begin
  if FBeginDocCount>0 then
    raise Exception.Create('TCUPSPrinter.DoBeginDoc already called. Maybe you forgot an EndDoc?');
  inherited DoBeginDoc;
  inc(FBeginDocCount);

  if (not TryTemporaryPath('~/tmp/'))
  and (not TryTemporaryPath('/tmp/'))
  and (not TryTemporaryPath('/var/tmp/')) then
    NewPath:='';

  NewOutputFileName:=AppendPathDelim(NewPath)
                   +'OutPrinter_'+FormatDateTime('yyyymmmddd-hhnnss',Now)+'.ps';
  
  TPostscriptPrinterCanvas(Canvas).OutputFileName:=NewOutputFileName;
end;

//If not aborted, send PostScript file to printer.
//After, delete this file.
procedure TCUPSPrinter.DoEndDoc(aAborded: Boolean);
begin
  inherited DoEndDoc(aAborded);
  dec(FBeginDocCount);
  Exclude(FStates,cpsPaperRectValid);

  //exit;
  
  if not aAborded then
    PrintFile(TPostscriptPrinterCanvas(Canvas).OutPutFileName);

  DeleteFile(TPostscriptPrinterCanvas(Canvas).OutPutFileName);
  TPostscriptPrinterCanvas(Canvas).OutPutFileName:='';
end;

procedure TCUPSPrinter.DoResetPrintersList;
begin
  if Assigned(fcupsPPD) then
  begin
    ppdClose(fcupsPPD);
    fcupsPPD:=nil;
  end;

  if fcupsPPDName<>'' then
  begin
    DeleteFile(fcupsPPDName);
    fcupsPPDName:='';
  end;

  FreeOptions;
  if Assigned(fcupsPrinters) and CUPSLibInstalled then begin
    cupsFreeDests(Printers.Count,fcupsPrinters);
    fCupsPrinter := nil;
  end;

  inherited DoResetPrintersList;
end;

procedure TCUPSPrinter.DoEnumPrinters(Lst: TStrings);
Var i,Num   : Integer;
    P       : Pcups_dest_t;
begin
  inherited DoEnumPrinters(Lst);
  if not CUPSLibInstalled then Exit;

  Num:=cupsGetDests(@fcupsPrinters);
  For i:=0 to Num-1 do
  begin
    P:=nil;
    P:=@fcupsPrinters[i];
    if Assigned(P) then
    begin
      if P^.is_default<>0 then
        Lst.Insert(0,P^.name)
      else
        Lst.Add(P^.name);
    end;
  end;
end;

procedure TCUPSPrinter.DoEnumPapers(Lst: TStrings);
begin
  inherited DoEnumPapers(Lst);
  
  GetEnumAttributeString('media-supported',Lst);
end;

procedure TCUPSPrinter.DoInitialization;
begin
  //printer list has been obtained
  if Printers.Count > 0 then
    SelectCurrentPrinterOrDefault;
end;

function TCUPSPrinter.DoSetPrinter(aName: string): Integer;
Var i  : Integer;
    P  : Pcups_dest_t;
    Fn : String;
begin
  //debugln('TCUPSPrinter.DoSetPrinter aName="',aName,'"');
  Result:=inherited DoSetPrinter(aName);
  if not CUPSLibInstalled then Exit;
  //debugln('TCUPSPrinter.DoSetPrinter B Printers.Count=',dbgs(Printers.Count));

  //Set the current printer. If aName='' then use a default Printer (index 0)
  If (Printers.Count>0) then
  begin
    if (aName<>'') and Assigned(fcupsPPD) then
    begin
      //Printer changed ?
      i:=Printers.IndexOf(aName);
      if i=PrinterIndex then
      begin
        Result:=PrinterIndex;
        //debugln('TCUPSPrinter.DoSetPrinter no change');
        Exit;
      end;
    end;

    //Clear all existing options
    FreeOptions;

    if Assigned(fcupsPPD) then
    begin
      ppdClose(fcupsPPD);
      fcupsPPD:=nil;

      if fcupsPPDName<>'' then
      begin
        DeleteFile(fcupsPPDName);
        fcupsPPDName:='';
      end;
    end;


    if aName='' then
      i:=0
    else
      i:=Printers.IndexOf(aName);

    if i>-1 then
    begin
      Result:=i;
      
      P:=nil;
      P:=cupsGetDest(PChar(aName),nil,Printers.Count,fcupsPrinters);
      if not Assigned(P) then
        raise Exception.Create(Format('"%s" is not a valid printer.',[aName]));
      fcupsPrinter:=P;

      //Open linked ppdfile
      Fn:=cupsGetPPD(PChar(aName));
      fcupsPPD:=ppdOpenFile(PChar(Fn));
      fcupsPPDName:=Fn;
    end;
  end
  else
  begin
    PrinterIndex:=-1;
    fcupsPPD:=nil;
  end;
end;

function TCUPSPrinter.DoGetCopies: Integer;
begin
  if not (cpsCopiesValid in FStates) then begin
    fCachedCopies:=inherited DoGetCopies;

    //Get default value if defined
    fCachedCopies:=GetAttributeInteger('copies-default',fCachedCopies);
    //Get Copies in options or return default value
    fCachedCopies:=StrToIntdef(cupsGetOption('copies'),fCachedCopies);
    {$IFDEF UseCache}
    Include(FStates,cpsCopiesValid);
    {$ENDIF}
  end;
  Result:=fCachedCopies;
end;

procedure TCUPSPrinter.DoSetCopies(aValue: Integer);
var i : Integer;
begin
  {$IFDEF UseCache}
  if aValue=DoGetCopies then exit;
  Exclude(FStates,cpsCopiesValid);
  {$ENDIF}
  inherited DoSetCopies(aValue);

  if Printers.Count>0 then
  begin
    if not Assigned(fcupsOptions) then
      SetOptionsOfPrinter;
    i:=aValue;
    if i<1 then i:=1;
    cupsAddOption('copies',IntToStr(i));
  end;
end;

function TCUPSPrinter.DoGetOrientation: TPrinterOrientation;
var i  : Integer;
begin
  if not (cpsOrientationValid in FStates) then begin
    fCachedOrientation:=inherited DoGetOrientation;

    if Printers.Count>0 then
    begin
      //Default orientation value
      i:=GetAttributeInteger('orientation-requested-default',3);
      //Get selected orientation or Default if not defined
      i:=StrToIntDef(cupsGetOption('orientation-requested'),i);
      //Calc result
      fCachedOrientation:=TPrinterOrientation(i-3);
    end;
    {$IFDEF UseCache}
    Include(FStates,cpsOrientationValid);
    {$ENDIF}
  end;
  Result:=fCachedOrientation;
end;

procedure TCUPSPrinter.DoSetOrientation(aValue: TPrinterOrientation);
var St : String;
begin
  {$IFDEF UseCache}
  if aValue=DoGetOrientation then exit;
  Exclude(FStates,cpsOrientationValid);
  {$ENDIF}
  inherited DoSetOrientation(aValue);

  if Printers.Count>0 then
  begin
    if not Assigned(fcupsOptions) then
         SetOptionsOfPrinter;

    St:=IntToStr(Ord(aValue)+3);
    cupsAddOption('orientation-requested',St);
  end;
end;

function TCUPSPrinter.DoGetDefaultPaperName: string;
begin
  if not (cpsDefaultPaperNameValid in FStates) then begin
    fCachedGetDefaultPaperName:=inherited DoGetDefaultPaperName;
    fCachedGetDefaultPaperName:=
                 GetAttributeString('media-default',fCachedGetDefaultPaperName);
    {$IFDEF UseCache}
    Include(FStates,cpsDefaultPaperNameValid);
    {$ENDIF}
  end;
  Result:=fCachedGetDefaultPaperName;
end;

function TCUPSPrinter.DoGetPaperName: string;
begin
  if not (cpsPaperNameValid in FStates) then begin
    fCachedPaperName:=cupsGetOption('PageSize');
    {$IFDEF UseCache}
    Include(FStates,cpsPaperNameValid);
    {$ENDIF}
  end;
  Result:=fCachedPaperName;
end;

procedure TCUPSPrinter.DoSetPaperName(aName: string);
begin
  {$IFDEF UseCache}
  if aName=DoGetPaperName then exit;
  Exclude(FStates,cpsPaperNameValid);
  {$ENDIF}
  inherited DoSetPaperName(aName);
  cupsAddOption('PageSize',aName)
end;

//Initialise aPaperRc with the aName paper rect
//Result : -1 no result
//          0 aPaperRc.WorkRect is a margins
//          1 aPaperRc.WorkRect is really the work rect
function TCUPSPrinter.DoGetPaperRect(aName: string;
  var aPaperRc: TPaperRect): Integer;
  
  procedure SortInts(var a, b: Integer);
  var
    h: LongInt;
  begin
    if b<a then begin
      h:=a;
      a:=b;
      b:=h;
    end;
  end;
  
var P : Pppd_size_t;
begin
  if (not (cpsPaperRectValid in FStates))
  or (fCachePaperRectName<>aName) then begin
    fCachePaperRectName:=aName;
    FillChar(fCachePaperRect,SizeOf(fCachePaperRect),0);
    fCachePaperRectResult:=inherited DoGetPaperRect(aName, aPaperRc);
    {$IFDEF UseCache}
    Include(FStates,cpsPaperRectValid);
    {$ENDIF}

    if CUPSLibInstalled and Assigned(fcupsPPD) then
    begin
      P:=nil;
      P:=ppdPageSize(fcupsPPD,PChar(aName));
      if Assigned(P) then
      begin
        fCachePaperRectResult:=1; //CUPS return margins

        fCachePaperRect.PhysicalRect.Right:=Trunc(P^.Width);
        fCachePaperRect.PhysicalRect.Bottom:=Trunc(P^.Length);

        //Margings
        fCachePaperRect.WorkRect.Left:=Trunc(P^.Left);
        fCachePaperRect.WorkRect.Right:=Trunc(P^.Right);
        fCachePaperRect.WorkRect.Top:=Trunc(P^.Top);
        fCachePaperRect.WorkRect.Bottom:=Trunc(P^.Bottom);
        SortInts(fCachePaperRect.WorkRect.Top,fCachePaperRect.WorkRect.Bottom);
        SortInts(fCachePaperRect.WorkRect.Left,fCachePaperRect.WorkRect.Right);
        //debugln('TCUPSPrinter.DoGetPaperRect PhysicalRect=',dbgs(fCachePaperRect.PhysicalRect),' WorkRect=',dbgs(fCachePaperRect.WorkRect));
      end;
    end;
  end;
  Result:=fCachePaperRectResult;
  aPaperRc:=fCachePaperRect;
end;


function TCUPSPrinter.DoGetPrinterState: TPrinterState;
var //Request   : Pipp_t; //IPP Request
    //Reponse   : Pipp_t; //IPP Reponse
    //Attribute : Pipp_attribute_t; //Current attribute
    //Language  : Pcups_lang_t;     //Default Language
    aState    : ipp_pstate_t;     //Printer state
    //URI       : Array[0..HTTP_MAX_URI] of Char; //Printer URI
begin
  Result:=inherited DoGetPrinterState;

  aState:=ipp_pstate_t(GetAttributeInteger('printer-state',0));
  Case aState of
    IPP_PRINTER_IDLE       : Result:=psReady;
    IPP_PRINTER_PROCESSING : Result:=psPrinting;
    IPP_PRINTER_STOPPED    : Result:=psStopped;
  end;
end;

function TCUPSPrinter.GetPrinterType: TPrinterType;
Var i : Integer;
begin
  Result:=inherited GetPrinterType;
  i:=GetAttributeInteger('printer-type',CUPS_PRINTER_LOCAL);
  If (i and CUPS_PRINTER_REMOTE)=CUPS_PRINTER_REMOTE then
    Result:=ptNetWork;
end;

function TCUPSPrinter.GetCanPrint: Boolean;
begin
  Result:=inherited GetCanPrint;
  Result:=GetAttributeBoolean('printer-is-accepting-jobs',Result)
end;

initialization
  if Assigned(Printer) then
    Printer.Free;

  Printer:=TCUPSPrinter.Create;

FINALIZATION
  // Free the printer before unloading library
  Printer.Free;
  Printer:=nil;
  //Unload CUPSLib if loaded
  FinalizeCups;

{END.}