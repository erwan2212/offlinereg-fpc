program Offlinereg_Gui;

uses
  Forms,
  uFrmMain in 'uFrmMain.pas' {Form1},
  uofflinereg in '..\clone_disk\uofflinereg.pas',
  ubcd in 'ubcd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
