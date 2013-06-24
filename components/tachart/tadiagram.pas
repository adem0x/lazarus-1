{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Authors: Alexander Klenin

}
unit TADiagram;

{$H+}

interface

uses
  Types,
  TAChartUtils, TATypes;

type
  TDiaObject = class(TObject)
  public
    procedure Notify(ASender: TDiaObject); virtual; abstract;
    procedure Changed(ASender: TDiaObject); virtual; abstract;
  end;

  TDiaCoordConverter = class
    function AxisToGraph(AP: TDoublePoint): TDoublePoint; virtual;
    function GraphToAxis(AP: TDoublePoint): TDoublePoint; virtual;
    function GraphToImage(AP: TDoublePoint): TPoint; virtual;
    function ImageToGraph(AP: TPoint): TDoublePoint; virtual;
    function ImageToDevice(AP: TPoint): TDoublePoint; virtual;
    function DeviceToImage(AP: TDoublePoint): TPoint; virtual;
  end;

  TDiaContext = class(TDiaObject)
  private
    FConverter: TDiaCoordConverter;
  public
    property Converter: TDiaCoordConverter read FConverter write FConverter;
  end;

  TDiaUnits = (duNone, duAxis, duGraph, duPixels, duCentimeters);
  TDiaBoxSide = (dbsTop, dbsLeft, dbsRight, dbsBottom);
  TDiaCoordinate = array [duAxis .. High(TDiaUnits)] of Double;
  TDiaPoint = record X, Y: TDiaCoordinate; end;

  TDiaElement = class;

  TDiaDecoratorList = class;

  TDiaDecorator = class(TDiaObject)
  private
    FOwner: TDiaObject;
  public
    constructor Create(AOwner: TDiaDecoratorList);
    property Owner: TDiaObject read FOwner;
  end;

  TDiaDecoratorEnumerator = class;

  TDiaDecoratorList = class(TDiaObject)
  private
    FDecorators: array of TDiaDecorator;
    FOwner: TDiaObject;
    procedure Add(ADecorator: TDiaDecorator);
  public
    constructor Create(AOwner: TDiaObject);
    destructor Destroy; override;
    property Owner: TDiaObject read FOwner;
    function GetEnumerator: TDiaDecoratorEnumerator;
  end;

  TDiaDecoratorEnumerator = class
    FList: TDiaDecoratorList;
    FPosition: Integer;
  public
    constructor Create(AList: TDiaDecoratorList);
    function GetCurrent: TDiaDecorator;
    function MoveNext: Boolean;
    property Current: TDiaDecorator read GetCurrent;
  end;

  TDiagram = class(TDiaObject)
  strict private
    FBounds: array [TDiaBoxSide] of TDiaCoordinate;
    FContext: TDiaContext;
    FElements: array of TDiaElement;
    function GetBounds(AIndex: TDiaBoxSide): TDiaCoordinate;
    procedure SetBounds(AIndex: TDiaBoxSide; AValue: TDiaCoordinate);
    procedure SetContext(AValue: TDiaContext);
  public
    destructor Destroy; override;
    procedure Draw;
    procedure Add(AElement: TDiaElement);
    procedure SetPixelBounds(const ARect: TRect);
    procedure Changed(ASender: TDiaObject); override;
    procedure Notify(ASender: TDiaObject); override;
    property Context: TDiaContext read FContext write SetContext;
    property Bounds[AIndex: TDiaBoxSide]: TDiaCoordinate
      read GetBounds write SetBounds; default;
  end;

  TDiaConnector = class;

  TDiaElement = class(TDiaObject)
  strict private
    FConnectors: array of TDiaConnector;
    FOwner: TDiagram;
  private
    FDecorators: TDiaDecoratorList;
  protected
    procedure SetOwner(AValue: TDiagram); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AConnector: TDiaConnector);
    procedure Changed(ASender: TDiaObject); override;
    procedure Draw; virtual;
    procedure Notify(ASender: TDiaObject); override;
    property Owner: TDiagram read FOwner;
    property Decorators: TDiaDecoratorList read FDecorators;
  end;

  TDiaPosition = class(TDiaObject)
  private
    FOwner: TDiaElement;
    FPercentage: Boolean;
    FReverse: Boolean;
    FUnits: TDiaUnits;
    FValue: Double;
    procedure SetPercentage(AValue: Boolean);
    procedure SetReverse(AValue: Boolean);
    procedure SetUnits(AValue: TDiaUnits);
    procedure SetValue(AValue: Double);
  public
    constructor Create(AOwner: TDiaElement);
    procedure Changed(ASender: TDiaObject); override;
    procedure Notify(ASender: TDiaObject); override;
    function Calc(const A, B: TDiaPoint): TDiaPoint;

    property Owner: TDiaElement read FOwner;
  published
    property Percentage: Boolean read FPercentage write SetPercentage;
    property Reverse: Boolean read FReverse write SetReverse;
    property Units: TDiaUnits read FUnits write SetUnits;
    property Value: Double read FValue write SetValue;
  end;

  TDiaBox = class(TDiaElement)
  strict private
    FBottom: TDiaPosition;
    FCaption: String;
    FHeight: TDiaPosition;
    FLeft: TDiaPosition;
    FRight: TDiaPosition;
    FTop: TDiaPosition;
    FWidth: TDiaPosition;
    procedure SetBottom(AValue: TDiaPosition);
    procedure SetCaption(AValue: String);
    procedure SetHeight(AValue: TDiaPosition);
    procedure SetLeft(AValue: TDiaPosition);
    procedure SetRight(AValue: TDiaPosition);
    procedure SetTop(AValue: TDiaPosition);
    procedure SetWidth(AValue: TDiaPosition);
  public
    FBottomLeft: TDiaPoint;
    FBottomRight: TDiaPoint;
    FTopLeft: TDiaPoint;
    FTopRight: TDiaPoint;
  class var
    FInternalDraw: procedure (ASelf: TDiaBox);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Draw; override;
    procedure Changed(ASender: TDiaObject); override;
  published
    property Left: TDiaPosition read FLeft write SetLeft;
    property Top: TDiaPosition read FTop write SetTop;
    property Right: TDiaPosition read FRight write SetRight;
    property Bottom: TDiaPosition read FBottom write SetBottom;
    property Caption: String read FCaption write SetCaption;
    //property Height: TDiaPosition read FHeight write SetHeight;
    //property Width: TDiaPosition read FWidth write SetWidth;
  end;

  TDiaConnector = class(TDiaObject)
  strict private
    FElement: TDiaElement;
    FPosition: TDiaPosition;
    procedure SetPosition(AValue: TDiaPosition);
  private
    FActualPos: TDiaPoint;
    procedure SetElement(AValue: TDiaElement);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Changed(ASender: TDiaObject); override;
    procedure Notify(ASender: TDiaObject); override;
    property ActualPos: TDiaPoint read FActualPos;
    property Element: TDiaElement read FElement;
  published
    property Position: TDiaPosition read FPosition write SetPosition;
  end;

  TDiaBoxConnector = class(TDiaConnector)
  private
    FSide: TDiaBoxSide;
    procedure SetSide(AValue: TDiaBoxSide);
  public
    procedure Changed(ASender: TDiaObject); override;
  published
    property Side: TDiaBoxSide read FSide write SetSide;
  end;

  TDiaEndPointShape = (depsNone, depsOpenArrow, depsClosedArrow);

  TDiaEndPoint = class(TDiaElement)
  private
    FConnector: TDiaConnector;
    FLength: TDiaPosition;
    FShape: TDiaEndPointShape;
    FWidth: TDiaPosition;
    procedure SetConnector(AValue: TDiaConnector);
    procedure SetLength(AValue: TDiaPosition);
    procedure SetShape(AValue: TDiaEndPointShape);
    procedure SetWidth(AValue: TDiaPosition);
  public
    constructor Create;
    destructor Destroy; override;
    property Connector: TDiaConnector read FConnector write SetConnector;
    property Length: TDiaPosition read FLength write SetLength;
    property Shape: TDiaEndPointShape read FShape write SetShape;
    property Width: TDiaPosition read FWidth write SetWidth;
  end;

  TDiaLink = class(TDiaElement)
  private
    FFinish: TDiaEndPoint;
    FStart: TDiaEndPoint;
    procedure SetFinish(AValue: TDiaEndPoint);
    procedure SetStart(AValue: TDiaEndPoint);
  protected
    procedure SetOwner(AValue: TDiagram); override;
  public
    class var
      FInternalDraw: procedure (ASelf: TDiaLink);
    constructor Create;
    destructor Destroy; override;
    procedure Draw; override;
  published
    property Start: TDiaEndPoint read FStart write SetStart;
    property Finish: TDiaEndPoint read FFinish write SetFinish;
  end;

implementation

uses
  SysUtils,
  TAGeometry;

const
  DEFAULT_DPI = 72;
  CM_PER_INCH = 2.54;

function PointDist(const A, B: TDoublePoint): Double; overload;
begin
  Result := Sqrt(Sqr(A.X - B.X) + Sqr(A.Y - B.Y));
end;

function WeightedAverage(
  const AP1, AP2: TDoublePoint; ACoeff: Double): TDoublePoint; overload; inline;
begin
  Result.X := WeightedAverage(AP1.X, AP2.X, ACoeff);
  Result.Y := WeightedAverage(AP1.Y, AP2.Y, ACoeff);
end;

{ TDiaEndPoint }

constructor TDiaEndPoint.Create;
begin
  inherited;
  FLength := TDiaPosition.Create(Self);
  FWidth := TDiaPosition.Create(Self);
end;

destructor TDiaEndPoint.Destroy;
begin
  FreeAndNil(FLength);
  FreeAndNil(FWidth);
  inherited;
end;

procedure TDiaEndPoint.SetConnector(AValue: TDiaConnector);
begin
  if FConnector = AValue then exit;
  FConnector := AValue;
  Notify(Self);
end;

procedure TDiaEndPoint.SetLength(AValue: TDiaPosition);
begin
  if FLength = AValue then exit;
  FLength := AValue;
  Notify(Self);
end;

procedure TDiaEndPoint.SetShape(AValue: TDiaEndPointShape);
begin
  if FShape = AValue then exit;
  FShape := AValue;
  Notify(Self);
end;

procedure TDiaEndPoint.SetWidth(AValue: TDiaPosition);
begin
  if FWidth = AValue then exit;
  FWidth := AValue;
  Notify(Self);
end;

{ TDiaDecoratorEnumerator }

constructor TDiaDecoratorEnumerator.Create(AList: TDiaDecoratorList);
begin
  FList := AList;
  FPosition := -1;
end;

function TDiaDecoratorEnumerator.GetCurrent: TDiaDecorator;
begin
  Result := FList.FDecorators[FPosition];
end;

function TDiaDecoratorEnumerator.MoveNext: Boolean;
begin
  FPosition += 1;
  Result := FPosition < Length(FList.FDecorators);
end;

{ TDiaDecoratorList }

procedure TDiaDecoratorList.Add(ADecorator: TDiaDecorator);
begin
  SetLength(FDecorators, Length(FDecorators) + 1);
  FDecorators[High(FDecorators)] := ADecorator;
  //Notify(ADecorator);
end;

constructor TDiaDecoratorList.Create(AOwner: TDiaObject);
begin
  FOwner := AOwner;
end;

destructor TDiaDecoratorList.Destroy;
var
  d: TDiaDecorator;
begin
  for d in FDecorators do
    d.Free;
  inherited;
end;

function TDiaDecoratorList.GetEnumerator: TDiaDecoratorEnumerator;
begin
  Result := TDiaDecoratorEnumerator.Create(Self);
end;

{ TDiaDecorator }

constructor TDiaDecorator.Create(AOwner: TDiaDecoratorList);
begin
  if AOwner <> nil then
    AOwner.Add(Self);
end;

{ TDiaLink }

constructor TDiaLink.Create;
begin
  inherited;
  FStart := TDiaEndPoint.Create;
  FFinish := TDiaEndPoint.Create;
end;

destructor TDiaLink.Destroy;
begin
  FreeAndNil(FStart);
  FreeAndNil(FFinish);
  inherited;
end;

procedure TDiaLink.Draw;
begin
  inherited;
  if FInternalDraw <> nil then
    FInternalDraw(Self);
end;

procedure TDiaLink.SetFinish(AValue: TDiaEndPoint);
begin
  if FFinish = AValue then exit;
  FFinish := AValue;
  Notify(Self);
end;

procedure TDiaLink.SetOwner(AValue: TDiagram);
begin
  inherited SetOwner(AValue);
  FStart.SetOwner(AValue);
  FFinish.SetOwner(AValue);
end;

procedure TDiaLink.SetStart(AValue: TDiaEndPoint);
begin
  if FStart = AValue then exit;
  FStart := AValue;
  Notify(Self);
end;

{ TDiaBoxConnector }

procedure TDiaBoxConnector.Changed(ASender: TDiaObject);
var
  b: TDiaBox;
begin
  inherited;
  if not (Element is TDiaBox) then exit;
  b := Element as TDiaBox;
  case Side of
    dbsTop: FActualPos := Position.Calc(b.FTopLeft, b.FTopRight);
    dbsBottom: FActualPos := Position.Calc(b.FBottomLeft, b.FBottomRight);
    dbsLeft: FActualPos := Position.Calc(b.FTopLeft, b.FBottomLeft);
    dbsRight: FActualPos := Position.Calc(b.FTopRight, b.FBottomRight);
  end;
end;

procedure TDiaBoxConnector.SetSide(AValue: TDiaBoxSide);
begin
  if FSide = AValue then Exit;
  FSide := AValue;
  Notify(Self);
end;

{ TDiaConnector }

procedure TDiaConnector.Changed(ASender: TDiaObject);
begin
  FPosition.Changed(ASender);
end;

constructor TDiaConnector.Create;
begin
  FPosition := TDiaPosition.Create(Element);
end;

destructor TDiaConnector.Destroy;
begin
  FreeAndNil(FElement);
  inherited;
end;

procedure TDiaConnector.Notify(ASender: TDiaObject);
begin
  if Element <> nil then
    Element.Notify(Self);
end;

procedure TDiaConnector.SetElement(AValue: TDiaElement);
begin
  if FElement = AValue then Exit;
  Notify(Self);
  FElement := AValue;
  FPosition.FOwner := FElement;
  Notify(Self);
end;

procedure TDiaConnector.SetPosition(AValue: TDiaPosition);
begin
  if FPosition = AValue then Exit;
  FPosition := AValue;
  Notify(Self);
end;

{ TDiaCoordConverter }

function TDiaCoordConverter.AxisToGraph(AP: TDoublePoint): TDoublePoint;
begin
  Result := AP;
end;

function TDiaCoordConverter.DeviceToImage(AP: TDoublePoint): TPoint;
begin
  Result := RoundPoint(AP * (DEFAULT_DPI / CM_PER_INCH));
end;

function TDiaCoordConverter.GraphToAxis(AP: TDoublePoint): TDoublePoint;
begin
  Result := AP;
end;

function TDiaCoordConverter.GraphToImage(AP: TDoublePoint): TPoint;
begin
  Result := RoundPoint(AP);
end;

function TDiaCoordConverter.ImageToDevice(AP: TPoint): TDoublePoint;
begin
  Result := DoublePoint(AP) * (CM_PER_INCH / DEFAULT_DPI);
end;

function TDiaCoordConverter.ImageToGraph(AP: TPoint): TDoublePoint;
begin
  Result := DoublePoint(AP);
end;

{ TDiaBox }

procedure TDiaBox.Changed(ASender: TDiaObject);

  function DiaPoint(AX, AY: TDiaBoxSide): TDiaPoint;
  begin
    Result.X := Owner[AX];
    Result.Y := Owner[AY];
  end;

  function XY(const AX, AY: TDiaPoint): TDiaPoint;
  var
    u: TDiaUnits;
  begin
    for u in TDiaUnits do begin
      Result.X[u] := AX.X[u];
      Result.Y[u] := AY.Y[u];
    end;
  end;

var
  tl, tr, bl, br: TDiaPoint;
begin
  tl := DiaPoint(dbsLeft, dbsTop);
  tr := DiaPoint(dbsRight, dbsTop);
  bl := DiaPoint(dbsLeft, dbsBottom);
  br := DiaPoint(dbsRight, dbsBottom);
  if (Left.Units <> duNone) and (Top.Units <> duNone) then
    FTopLeft := XY(Left.Calc(tl, tr), Top.Calc(tl, bl));
  if (Right.Units <> duNone) and (Top.Units <> duNone) then
    FTopRight := XY(Right.Calc(tr, tl), Top.Calc(tr, br));
  if (Left.Units <> duNone) and (Bottom.Units <> duNone) then
    FBottomLeft := XY(Left.Calc(tl, tr), Bottom.Calc(bl, tl));
  if (Right.Units <> duNone) and (Bottom.Units <> duNone) then
    FBottomRight := XY(Right.Calc(br, bl), Bottom.Calc(br, tr));
  inherited;
end;

constructor TDiaBox.Create;
begin
  FLeft := TDiaPosition.Create(Self);
  FRight := TDiaPosition.Create(Self);
  FTop := TDiaPosition.Create(Self);
  FBottom := TDiaPosition.Create(Self);
end;

destructor TDiaBox.Destroy;
begin
  FreeAndNil(FLeft);
  FreeAndNil(FRight);
  FreeAndNil(FTop);
  FreeAndNil(FBottom);
  inherited;
end;

procedure TDiaBox.Draw;
begin
  if FInternalDraw <> nil then
    FInternalDraw(Self);
end;

procedure TDiaBox.SetBottom(AValue: TDiaPosition);
begin
  if FBottom = AValue then Exit;
  FBottom := AValue;
end;

procedure TDiaBox.SetCaption(AValue: String);
begin
  if FCaption = AValue then exit;
  FCaption := AValue;
  Notify(Self);
end;

procedure TDiaBox.SetHeight(AValue: TDiaPosition);
begin
  if FHeight = AValue then Exit;
  FHeight := AValue;
end;

procedure TDiaBox.SetLeft(AValue: TDiaPosition);
begin
  if FLeft = AValue then Exit;
  FLeft := AValue;
end;

procedure TDiaBox.SetRight(AValue: TDiaPosition);
begin
  if FRight = AValue then Exit;
  FRight := AValue;
end;

procedure TDiaBox.SetTop(AValue: TDiaPosition);
begin
  if FTop = AValue then Exit;
  FTop := AValue;
end;

procedure TDiaBox.SetWidth(AValue: TDiaPosition);
begin
  if FWidth = AValue then Exit;
  FWidth := AValue;
end;

{ TDiagram }

procedure TDiagram.Add(AElement: TDiaElement);
begin
  if AElement.Owner = Self then exit;
  SetLength(FElements, Length(FElements) + 1);
  FElements[High(FElements)] := AElement;
  AElement.SetOwner(Self);
end;

procedure TDiagram.Changed(ASender: TDiaObject);
var
  e: TDiaElement;
begin
  for e in FElements do
    e.Changed(ASender);
end;

destructor TDiagram.Destroy;
var
  e: TDiaElement;
begin
  for e in FElements do
    e.Free;
  inherited;
end;

procedure TDiagram.Draw;
var
  e: TDiaElement;
begin
  for e in FElements do
    e.Draw;
end;

function TDiagram.GetBounds(AIndex: TDiaBoxSide): TDiaCoordinate;
begin
  Result := FBounds[AIndex];
end;

procedure TDiagram.Notify(ASender: TDiaObject);
begin
  Changed(ASender);
end;

procedure TDiagram.SetBounds(AIndex: TDiaBoxSide; AValue: TDiaCoordinate);
begin
  FBounds[AIndex] := AValue;
  Notify(Self);
end;

procedure TDiagram.SetContext(AValue: TDiaContext);
begin
  if FContext = AValue then exit;
  FContext := AValue;
  Notify(AValue);
end;

procedure TDiagram.SetPixelBounds(const ARect: TRect);
begin
  FBounds[dbsTop][duPixels] := ARect.Top;
  FBounds[dbsBottom][duPixels] := ARect.Bottom;
  FBounds[dbsLeft][duPixels] := ARect.Left;
  FBounds[dbsRight][duPixels] := ARect.Right;
  Notify(Self);
end;

{ TDiaElement }

procedure TDiaElement.Add(AConnector: TDiaConnector);
begin
  if AConnector.Element = Self then exit;
  SetLength(FConnectors, Length(FConnectors) + 1);
  FConnectors[High(FConnectors)] := AConnector;
  AConnector.SetElement(Self);
end;

procedure TDiaElement.Changed(ASender: TDiaObject);
var
  c: TDiaConnector;
begin
  for c in FConnectors do
    c.Changed(ASender);
end;

constructor TDiaElement.Create;
begin
  FDecorators := TDiaDecoratorList.Create(Self);
end;

destructor TDiaElement.Destroy;
begin
  FreeAndNil(FDecorators);
  inherited;
end;

procedure TDiaElement.Draw;
begin
  //
end;

procedure TDiaElement.Notify(ASender: TDiaObject);
begin
  if Owner <> nil then
    Owner.Notify(ASender);
end;

procedure TDiaElement.SetOwner(AValue: TDiagram);
begin
  if FOwner = AValue then Exit;
  Notify(Self);
  FOwner := AValue;
  Notify(Self);
end;

{ TDiaPosition }

function TDiaPosition.Calc(const A, B: TDiaPoint): TDiaPoint;
var
  d: TDiagram;
  conv: TDiaCoordConverter;
  w: Double;
  pa, pb: TDoublePoint;
  ap, gp, dp: TDoublePoint;
  ip: TPoint;
begin
  if Owner = nil then exit;
  d := Owner.Owner;
  conv := d.Context.Converter;
  pa := DoublePoint(A.X[Units], A.Y[Units]);
  pb := DoublePoint(B.X[Units], B.Y[Units]);
  if Percentage then
    w := Value * PERCENT
  else begin
    w := PointDist(pa, pb);
    if w > 0 then
      w := Value / w;
  end;
  if Reverse then
    w := 1.0 - w;
  case Units of
    duNone: ;
    duAxis: begin
      ap := WeightedAverage(pa, pb, w);
      gp := conv.AxisToGraph(ap);
      ip := conv.GraphToImage(gp);
      dp := conv.ImageToDevice(ip);
    end;
    duGraph: begin
      gp := WeightedAverage(pa, pb, w);
      ap := conv.GraphToAxis(gp);
      ip := conv.GraphToImage(gp);
      dp := conv.ImageToDevice(ip);
    end;
    duPixels: begin
      ip := RoundPoint(WeightedAverage(pa, pb, w));
      gp := conv.ImageToGraph(ip);
      ap := conv.GraphToAxis(gp);
      dp := conv.ImageToDevice(ip);
    end;
    duCentimeters: begin
      dp := WeightedAverage(pa, pb, w);
      ip := conv.DeviceToImage(dp);
      gp := conv.ImageToGraph(ip);
      ap := conv.GraphToAxis(gp);
    end;
  end;
  Result.X[duAxis] := ap.X;
  Result.Y[duAxis] := ap.Y;
  Result.X[duGraph] := gp.X;
  Result.Y[duGraph] := gp.Y;
  Result.X[duPixels] := ip.X;
  Result.Y[duPixels] := ip.Y;
  Result.X[duCentimeters] := dp.X;
  Result.Y[duCentimeters] := dp.Y;
end;

procedure TDiaPosition.Changed(ASender: TDiaObject);
begin
  if ASender = Self then exit;
  //
end;

constructor TDiaPosition.Create(AOwner: TDiaElement);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TDiaPosition.Notify(ASender: TDiaObject);
begin
  if Owner <> nil then
    Owner.Notify(ASender);
end;

procedure TDiaPosition.SetPercentage(AValue: Boolean);
begin
  if FPercentage = AValue then Exit;
  FPercentage := AValue;
  Notify(Self);
end;

procedure TDiaPosition.SetReverse(AValue: Boolean);
begin
  if FReverse = AValue then exit;
  FReverse := AValue;
  Notify(Self);
end;

procedure TDiaPosition.SetUnits(AValue: TDiaUnits);
begin
  if FUnits = AValue then exit;
  FUnits := AValue;
  Notify(Self);
end;

procedure TDiaPosition.SetValue(AValue: Double);
begin
  if FValue = AValue then exit;
  FValue := AValue;
  Notify(Self);
end;

end.

