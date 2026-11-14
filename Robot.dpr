program Robot;

uses
  System.StartUpCopy,
  FMX.Forms,
  FormMain in 'FormMain.pas' {fmMain},
  UnitBluetoothUtils in 'UnitBluetoothUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
