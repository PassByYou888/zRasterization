unit RasterFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  FMX.Surfaces, FMX.ListBox, FMX.ScrollBox, FMX.Memo, FMX.TabControl,

  ZR.Core, ZR.MemoryRaster, ZR.PascalStrings, ZR.DrawEngine.SlowFMX;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ComboBox1: TComboBox;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    mr1, mr2: TMZR;
  end;

var
  Form1: TForm1;

  { ���к����Ǵ� zDrawEngine->FMX �ӿڰγ��� }
  { ��ΪzDrawEngine����ϵ�е�޴������������㿪Դ }

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  mr2.Assign(mr1);
  MemoryBitmapToBitmap(mr2, Image2.Bitmap);
  Label2.Text := Format('%s ��� %d * %d', [ComboBox1.Items[ComboBox1.ItemIndex], mr2.Width, mr2.Height]);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  mr2.Reset;
  case ComboBox1.ItemIndex of
    0: mr2.ZoomFrom(mr1, mr1.Width div 20, mr1.Height div 20);
    1: mr2.FastBlurZoomFrom(mr1, mr1.Width div 20, mr1.Height div 20);
    2: mr2.GaussianBlurZoomFrom(mr1, mr1.Width div 20, mr1.Height div 20);
    3: mr2.GrayscaleBlurZoomFrom(mr1, mr1.Width div 20, mr1.Height div 20);
  end;
  MemoryBitmapToBitmap(mr2, Image2.Bitmap);
  Label2.Text := Format('%s ��� %d * %d', [ComboBox1.Items[ComboBox1.ItemIndex], mr2.Width, mr2.Height]);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  mr2.Reset;
  case ComboBox1.ItemIndex of
    0: mr2.ZoomFrom(mr1, mr1.Width * 5, mr1.Height * 5);
    1: mr2.FastBlurZoomFrom(mr1, mr1.Width * 5, mr1.Height * 5);
    2: mr2.GaussianBlurZoomFrom(mr1, mr1.Width * 5, mr1.Height * 5);
    3: mr2.GrayscaleBlurZoomFrom(mr1, mr1.Width * 5, mr1.Height * 5);
  end;
  MemoryBitmapToBitmap(mr2, Image2.Bitmap);
  Label2.Text := Format('%s ��� %d * %d', [ComboBox1.Items[ComboBox1.ItemIndex], mr2.Width, mr2.Height]);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  rs:TResourceStream;
begin
  rs:=TResourceStream.Create(hInstance, 'demo', RT_RCDATA);
  image1.Bitmap.LoadFromStream(rs);
  disposeObject(rs);

  mr1 := TMZR.Create;
  mr2 := TMZR.Create;

  BitmapToMemoryBitmap(Image1.Bitmap, mr1);
  Label1.Text := Format('ԭͼ %d * %d', [mr1.Width, mr1.Height]);

  Button1Click(Button1);
end;

end.
