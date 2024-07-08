{ ****************************************************************************** }
{ * draw fmx control                                                           * }
{ ****************************************************************************** }
unit ZR.DrawEngine.ControlBoxForFMX;

{$I ZR.Define.inc}

interface

uses System.Types, FMX.Controls, ZR.DrawEngine, ZR.Geometry2D, ZR.Geometry3D;

procedure DrawChildrenControl(WorkCtrl: TControl; DrawEng: TDrawEngine; ctrl: TControl; COLOR: TDEColor; LineWidth: TDEFloat);

implementation

procedure DrawChildrenControl(WorkCtrl: TControl; DrawEng: TDrawEngine; ctrl: TControl; COLOR: TDEColor; LineWidth: TDEFloat);
  procedure DrawControlRect(c: TControl);
  var
    r4: TRectf;
    r: TDERect;
  begin
    r4 := c.AbsoluteRect;
    r := MakeRectV2(Make2DPoint(WorkCtrl.AbsoluteToLocal(r4.TopLeft)), Make2DPoint(WorkCtrl.AbsoluteToLocal(r4.BottomRight)));
    DrawEng.DrawBoxInScene(r, COLOR, LineWidth);
  end;

var
  i: Integer;
begin
  for i := 0 to ctrl.ChildrenCount - 1 do
    begin
      if (ctrl.Children[i] is TControl) and (TControl(ctrl.Children[i]).Visible) then
        begin
          DrawChildrenControl(WorkCtrl, DrawEng, TControl(ctrl.Children[i]), COLOR, LineWidth);
          DrawControlRect(TControl(ctrl.Children[i]));
        end;
    end;
end;

end.
