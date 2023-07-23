unit PictureBrowseFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Layouts, FMX.ListBox, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.TreeView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.Menus, FMX.Objects, FMX.Media, FMX.Edit, FMX.ComboEdit,

  System.IOUtils,

  ZR.PascalStrings,
  ZR.ZDB.HashField_LIB, ZR.ZDB, ZR.UnicodeMixedLib, ZR.ZDB.ObjectData_LIB,
  ZR.Core, ZR.MemoryStream, ZR.ZDB.ItemStream_LIB, ZR.Status,
  ZR.MemoryRaster, ZR.DrawEngine.SlowFMX, ZR.DrawEngine;

type
  TPictureBrowseForm = class;

  TMaterialListBoxItem = class(TListBoxItem)
  public
    BrowseForm: TPictureBrowseForm;
    FileName: string;
    PlayButton: TButton;
    img: TImage;
    Lab: TLabel;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TPictureBrowseForm = class(TForm)
    topLayout: TLayout;
    ListBox: TListBox;
    FileListLayout: TLayout;
    PathEdit: TEdit;
    BrowseEditButton: TEditButton;
    StopButton: TButton;
    procedure BrowseEditButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PathEditChange(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    ListBoxItemWidth, ListBoxItemHeight: Integer;
    IsStop: TAtomBool;

    procedure DoLiClick(Sender: TObject);
    procedure RefreshFileList(Path, Filter: string);
  end;

var
  PictureBrowseForm: TPictureBrowseForm;

implementation

{$R *.fmx}


uses StyleModuleUnit, ShowImageFrm;

constructor TMaterialListBoxItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BrowseForm := nil;
  FileName := '';
  PlayButton := nil;
  img := nil;
  Lab := nil;
end;

destructor TMaterialListBoxItem.Destroy;
begin
  inherited Destroy;
end;

procedure TPictureBrowseForm.BrowseEditButtonClick(Sender: TObject);
var
  s: string;
begin
  s := PathEdit.Text;
  if SelectDirectory('Select root directory.', '', s) then
      PathEdit.Text := s;
end;

procedure TPictureBrowseForm.FormCreate(Sender: TObject);
begin
  ListBoxItemWidth := 128;
  ListBoxItemHeight := 128;
  IsStop := TAtomBool.Create(False);
  StopButton.Visible := False;
end;

procedure TPictureBrowseForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TPictureBrowseForm.PathEditChange(Sender: TObject);
begin
  RefreshFileList(PathEdit.Text, '*');
end;

procedure TPictureBrowseForm.DoLiClick(Sender: TObject);
var
  li: TMaterialListBoxItem;
begin
  li := TMaterialListBoxItem(Sender);
  ShowImage2(NewZRFromFile(li.FileName), li.FileName);
end;

procedure TPictureBrowseForm.RefreshFileList(Path, Filter: string);
begin
  if not PathEdit.Enabled then
      exit;
  ListBox.Clear;
  ListBox.ItemWidth := ListBoxItemWidth;
  ListBox.ItemHeight := ListBoxItemHeight;
  IsStop.V := False;
  StopButton.Visible := True;
  StopButton.BringToFront;

  TCompute.RunP_NP(procedure
    var
      dAry: U_StringArray;
      n, imgFil: string;
      imgFAry: TArrayPascalString;
      li: TMaterialListBoxItem;
      bmp: TMZR;
      FT: TDateTime;
    begin
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          PathEdit.Enabled := False;
        end);

      dAry := umlGetFileListWithFullPath(Path);
      imgFil := TBitmapCodecManager.GetFileTypes+';*.seq';
      umlGetSplitArray(imgFil, imgFAry, ';');

      for n in dAry do
        if umlMultipleMatch(Filter, umlGetFileName(n)) then
          begin
            try
              if umlMultipleMatch(imgFAry, umlGetFileName(n)) and CanLoadMemoryBitmap(n) then
                begin
                  if IsStop.V then
                      break;

                  bmp := NewZRFromFile(n);
                  bmp.FitScale(ListBoxItemWidth, ListBoxItemHeight);

                  TCompute.Sync(procedure
                    begin
                      li := TMaterialListBoxItem.Create(ListBox);
                      li.BrowseForm := Self;
                      li.Selectable := False;
                      li.OnClick := DoLiClick;

                      li.img := TImage.Create(li);
                      li.img.Parent := li;
                      li.img.Align := TAlignLayout.Client;
                      li.img.HitTest := False;
                      li.img.Opacity := 0.8;
                      MemoryBitmapToBitmap(bmp, li.img.Bitmap);

                      li.Lab := TLabel.Create(li.img);
                      li.Lab.Parent := li.img;
                      li.Lab.StyledSettings := li.Lab.StyledSettings - [TStyledSetting.Size];
                      li.Lab.WordWrap := True;
                      li.Lab.TextAlign := TTextAlign.Leading;
                      li.Lab.Opacity := 0.5;
                      li.Lab.HitTest := False;
                      li.Lab.Text := Format('%d x %d'#13#10'%s', [bmp.width, bmp.height, umlGetFileName(n).Text]);
                      li.Lab.AutoSize := True;
                      li.Lab.Align := TAlignLayout.Bottom;

                      DisposeObject(bmp);
                      li.FileName := n;
                      ListBox.AddObject(li);
                    end);
                end;
            except
            end;
          end;

      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          PathEdit.Enabled := True;
          StopButton.Visible := False;
        end);
    end);
end;

procedure TPictureBrowseForm.StopButtonClick(Sender: TObject);
begin
  IsStop.V := True;
end;

end.
