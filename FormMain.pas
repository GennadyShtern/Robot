unit FormMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, System.ImageList,
  FMX.ImgList
  //,FormImageDataModule
  ,FMX.Menus, FMX.Layouts, FMX.ListBox, FMX.TabControl, System.Actions,
  FMX.ActnList, FMX.Ani, System.Bluetooth
  ;

type

  TfmMain = class(TForm)
    btnStart: TButton;
    t2sb1: TSpeedButton;
    t2sb1im: TImage;
    imTablo2: TImage;
    t2sb2: TSpeedButton;
    t2sb2im: TImage;
    t2sb3: TSpeedButton;
    t2sb3im: TImage;
    t2sb4: TSpeedButton;
    t2sb4im: TImage;
    imTablo1: TImage;
    t1sb1: TSpeedButton;
    t1sb1im: TImage;
    t1sb2: TSpeedButton;
    t1sb2im: TImage;
    t1sb3: TSpeedButton;
    t1sb3im: TImage;
    t1sb4: TSpeedButton;
    t1sb4im: TImage;
    Popup: TPopup;
    ListBox: TListBox;
    lbiV: TListBoxItem;
    lbiL: TListBoxItem;
    lbiP: TListBoxItem;
    lbiN: TListBoxItem;
    TabControl: TTabControl;
    tiTabloids: TTabItem;
    tiSettings: TTabItem;
    plTabloidsTop: TPanel;
    plTabloidsClient: TPanel;
    ActionList: TActionList;
    ChangeTabAction: TChangeTabAction;
    plSettingsTop: TPanel;
    lbxSettings: TListBox;
    plSettingsClient: TPanel;
    LoadingImage: TImage;
    SpinAnimation: TFloatAnimation;
    lbghDevices: TListBoxGroupHeader;
    lbiDevices: TListBoxItem;
    cbDevices: TComboBox;
    lbghTabloCount: TListBoxGroupHeader;
    lbiTableCount: TListBoxItem;
    cbTabloCount: TComboBox;
    lbghTimes: TListBoxGroupHeader;
    ListBoxItem1: TListBoxItem;
    cbTimes: TComboBox;
    Label1: TLabel;
    Timer: TTimer;
    imSelection: TImage;
    Label2: TLabel;
    sbNext: TSpeedButton;
    sbPrior: TSpeedButton;
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure t2sb1Click(Sender: TObject);
    procedure lbiLClick(Sender: TObject);
    procedure ListBoxClick(Sender: TObject);
    procedure t2sb1Tap(Sender: TObject; const Point: TPointF);
    procedure sbNextClick(Sender: TObject);
    procedure sbPriorClick(Sender: TObject);
    procedure cbTabloCountChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
    FButtons: TArray<TSpeedButton>;
    FPath: TArray<string>;
    FPathIndex: integer;
    FManager: TBluetoothManager;
    FDevice: TBluetoothDevice;
    FBlueToothDeviceName: string;
    FTabloCount: integer;

    procedure ActiveAnimation(aActive: Boolean);
    function VerifyInput: Boolean;
    procedure RobotGo;
    function VerifyTablo(ATablo: TImage): Boolean;
    procedure GetPath(ATablo: TImage; var APath: TArray<string>);
    procedure StartGo;
  public
    { Public declarations }
    function Readsettings: Boolean;
    procedure WriteSettings;
  end;

var
  fmMain: TfmMain;

implementation
uses DateUtils, UnitBluetoothUtils, IniFiles, System.IOUtils;

{$R *.fmx}

var
  sys_IniFileName: string;


procedure TfmMain.ActiveAnimation(aActive: Boolean);
begin
  if aActive then
  begin
    LoadingImage.Visible := True;
    SpinAnimation.Enabled := True;
  end
  else
  begin
    SpinAnimation.Enabled := False;
    LoadingImage.Visible := False;
  end;
end;

procedure TfmMain.btnStartClick(Sender: TObject);
begin
  if VerifyInput then
  begin
    try
      WriteSettings;
      RobotGo;
    finally
    end;
  end;
end;

procedure TfmMain.cbTabloCountChange(Sender: TObject);
begin
  FTabloCount := cbTabloCount.ItemIndex + 1;
  if FTabloCount > 1 then
    imTablo2.Visible := True
  else
    imTablo2.Visible := False;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  LIndex: integer;
begin
  try
    ActiveAnimation(False);
    Popup.Position.X := -100;
    Popup.Position.Y := -100;
    Popup.IsOpen := False;
    imSelection.Visible := False;
    FButtons := [];
    FPathIndex := -1;

    Readsettings;
    RequestBluetoothPermissions;
    FManager := GetDeviceNamesList(cbDevices.Items);

    cbTabloCount.ItemIndex := FTabloCount - 1;

    if Not FBlueToothDeviceName.IsEmpty then
    begin
      LIndex := cbDevices.Items.IndexOf(FBlueToothDeviceName);
      if LIndex >= 0 then
        cbDevices.ItemIndex := LIndex;
    end
    else
      sbNextClick(Sender);
  finally
  end;
end;

procedure TfmMain.GetPath(ATablo: TImage; var APath: TArray<string>);
const
  cnstDir: array[1..4] of string = ('F','L','R','S'); //{Вперед,Влево,Вправо,Назад(Стоп)}
var
  I: integer;
begin
  for I := 0 to ATablo.ChildrenCount - 1 do
  begin
    if ATablo.Children.Items[I] is TSpeedButton then
    begin
      if (ATablo.Children.Items[I] as TSpeedButton).Tag > 0 then
      begin
        APath := APath + [cnstDir[(ATablo.Children.Items[I] as TSpeedButton).Tag]];
        FButtons := FButtons + [(ATablo.Children.Items[I] as TSpeedButton)];
      end;
    end;
  end;
end;

procedure TfmMain.lbiLClick(Sender: TObject);
var
  sb: TSpeedButton;
  LStream: TMemoryStream;
begin
  if Sender is TListBoxItem then
  begin
    sb := (Sender as TListBoxItem).TagObject as TSpeedButton;
    sb.Tag := -1;
    LStream := TMemoryStream.Create;
    try
      LStream.Clear;
      (Sender as TListBoxItem).ItemData.Bitmap.SaveToStream(LStream);
      LStream.Position := 0;

      if sb.Children[1] is TImage then
      begin
        (sb.Children[1] as TImage).Bitmap.LoadFromStream(LStream);
        sb.Tag := (Sender as TListBoxItem).Index + 1;
      end;
    finally
      LStream.Free;

      Popup.Position.X := -100;
      Popup.Position.Y := -100;
      Popup.IsOpen := False;
    end;
  end;
end;

procedure TfmMain.ListBoxClick(Sender: TObject);
begin
  lbiLClick(Sender);
end;

procedure TfmMain.sbNextClick(Sender: TObject);
begin
  ChangeTabAction.Tab := tiSettings;
  ChangeTabAction.Execute;
end;

procedure TfmMain.sbPriorClick(Sender: TObject);
begin
  ChangeTabAction.Tab := tiTabloids;
  ChangeTabAction.Execute;
end;

procedure TfmMain.t2sb1Click(Sender: TObject);
var
  sb: TSpeedButton;
  LPoint: TPointF;
  I: integer;
begin
  if (FPathIndex < 0) and (Sender is TSpeedButton) then
  begin
    sb := Sender as TSpeedButton;
    LPoint := sb.LocalToScreen(sb.ClipRect.CenterPoint);
    for I := 0 to ListBox.Count - 1 do
       ListBox.ItemByIndex(I).TagObject := sb;

    Popup.Position.X := LPoint.X;
    Popup.Position.Y := LPoint.Y;
    Popup.Popup(False);
  end;
end;

procedure TfmMain.t2sb1Tap(Sender: TObject; const Point: TPointF);
begin
  t2sb1Click(Sender);
end;

procedure TfmMain.StartGo;
begin
  if FPathIndex < 0 then
  begin
    FPathIndex := 0;
    Timer.Interval := (2 + cbTimes.ItemIndex)*MSecsPerSec;

    TimerTimer(nil);
    Timer.Enabled := True;

    btnStart.Enabled := False;
    //imTablo1.Enabled := False;
    //imTablo2.Enabled := False;
  end;
end;

procedure TfmMain.TimerTimer(Sender: TObject);
begin
  if (FPathIndex >= 0) and (FPathIndex < length(FPath)) then
  begin
    imSelection.Visible := False;
    imSelection.Parent := FButtons[FPathIndex].Parent;
    imSelection.Position := FButtons[FPathIndex].Position;
    imSelection.Position.X := imSelection.Position.X - 2;
    imSelection.Position.Y := imSelection.Position.Y - 2;

    imSelection.Visible := True;
    //Посылка данных в BlueTooth
    SendBluetoothData(FDevice, FPath[FPathIndex]);
    Inc(FPathIndex);
  end
  else
  begin
    FPathIndex := -1;
    Timer.Enabled := False;
    ActiveAnimation(False);
    imSelection.Visible := False;

    btnStart.Enabled := True;
    imTablo1.Enabled := True;
    imTablo2.Enabled := True;

    ShowMessage('Путь пройден!');
  end;
end;

function TfmMain.VerifyInput: Boolean;
begin
  Result := True;
  FDevice := GetDeviceByName(FManager, FBlueToothDeviceName);
  if FDevice = nil then
  begin
    Result := false;
    ShowMessage('Не найдено BluTooth устройство!');
    Exit;
  end;
  Result := VerifyTablo(imTablo1);
  if Result and (FTabloCount > 1) then
    Result := VerifyTablo(imTablo2);
end;

function TfmMain.VerifyTablo(ATablo: TImage): Boolean;
var
  I, J: integer;
begin
  Result := True;
  J := 0;
  for I := 0 to ATablo.ChildrenCount - 1 do
  begin
    if ATablo.Children.Items[I] is TSpeedButton then
    begin
      Inc(J);
      if (ATablo.Children.Items[I] as TSpeedButton).Tag <= 0 then
      begin
        ShowMessage(Format('Не указано направление %d на табло №%d',[J, ATablo.Tag]));
        Result := False;
        break;
      end;
    end;
  end;
end;

function TfmMain.Readsettings: Boolean;
var
  LMemIniFile: TMemIniFile;
begin
  Result := False;

  LMemIniFile := TMemIniFile.Create(sys_IniFileName);
  try
    FBlueToothDeviceName := LMemIniFile.ReadString('BlueTooth', 'DeviceName', '');
    FTabloCount := LMemIniFile.ReadInteger('BlueTooth', 'TabloCount', 1);

    Result := Not FBlueToothDeviceName.IsEmpty;
  finally
    LMemIniFile.Free;
  end;
end;

procedure TfmMain.RobotGo;
begin
  FPath := [];
  FButtons := [];
  FPathIndex := -1;
  GetPath(imTablo1, FPath);
  if FTabloCount > 1 then
    GetPath(imTablo2, FPath);

  if length(FPath) > 0 then
  begin
    ActiveAnimation(True);
    StartGo;
  end;
end;

procedure TfmMain.WriteSettings;
var
  LMemIniFile: TMemIniFile;
begin
  LMemIniFile := TMemIniFile.Create(sys_IniFileName);
  try
    if cbDevices.ItemIndex >= 0 then
      FBlueToothDeviceName := cbDevices.Items[cbDevices.ItemIndex]
    else
      FBlueToothDeviceName := '';

    LMemIniFile.WriteString('BlueTooth', 'DeviceName', FBlueToothDeviceName);
    LMemIniFile.WriteInteger('BlueTooth', 'TabloCount', FTabloCount);
    LMemIniFile.UpdateFile;

  finally
    LMemIniFile.Free;
  end;
end;

initialization

 sys_IniFileName :=  System.IOUtils.TPath.Combine(TPath.GetPublicPath, 'Robot.ini');

end.
