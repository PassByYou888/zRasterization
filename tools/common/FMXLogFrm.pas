unit FMXLogFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.Memo.Types,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.Status,
  ZR.MemoryRaster, ZR.DrawEngine, ZR.DrawEngine.SlowFMX;

type
  TLogForm = class(TForm)
    Memo: TMemo;
    ProgressBar: TProgressBar;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure MemoPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    bk: TZR;
    FVisibleLog: Boolean;
    procedure DoStatus_BackCall(AText: SystemString; const ID: Integer);
    procedure SetVisibleLog(const Value: Boolean);
  public
    property VisibleLog: Boolean read FVisibleLog write SetVisibleLog;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  LogForm: TLogForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure TLogForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caHide;
end;

procedure TLogForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatus_BackCall);
  FVisibleLog := True;
end;

procedure TLogForm.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = VKESCAPE then
      close;
end;

procedure TLogForm.MemoPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  TDrawEngineInterface_FMX.DrawEngine_Interface.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, TDrawEngineInterface_FMX.DrawEngine_Interface);
  d.ViewOptions := [voEdge];
  d.DrawTile(bk);
  d.Flush;
end;

procedure TLogForm.DoStatus_BackCall(AText: SystemString; const ID: Integer);
begin
  if Memo.Lines.Count > 10000 then
      Memo.Lines.Clear;

  Memo.Lines.Add(AText);
  Memo.GoToTextEnd;
  if FVisibleLog then
    begin
      if not Visible then
          Show
      else
          BringToFront;
    end;
end;

procedure TLogForm.SetVisibleLog(const Value: Boolean);
begin
  FVisibleLog := Value;
  Visible := FVisibleLog;
end;

constructor TLogForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  bk := NewZR();
  bk.SetSize(128, 128, RColor(0, 0, 0));
  FillBlackGrayBackgroundTexture(bk, 8);
end;

destructor TLogForm.Destroy;
begin
  RemoveDoStatusHook(Self);
  DisposeObject(bk);
  inherited Destroy;
end;

end.
