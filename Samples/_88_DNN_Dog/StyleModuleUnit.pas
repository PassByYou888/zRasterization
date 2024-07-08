unit StyleModuleUnit;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls;

type
  TStyleDataModule = class(TDataModule)
    GlobalStyleBook: TStyleBook;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  StyleDataModule: TStyleDataModule;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

end.
