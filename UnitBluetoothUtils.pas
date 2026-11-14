unit UnitBluetoothUtils;
(*****************************************************
Библиотека содержит следующие ключевые классы для Classic Bluetooth:


Класс	Назначение
TBluetoothManager	Главный менеджер: управление адаптером, поиск устройств, состояние соединения.
TBluetoothAdapter	Локальный адаптер: включение/выключение, сопряжение.
TBluetoothDevice	Удалённое устройство: информация, список сервисов, создание сокета.
TBluetoothDeviceList	Список найденных или сопряжённых устройств.
TBluetoothSocket	Сокет для обмена данными (чтение/запись).
TBluetoothService	Описание сервиса удалённого устройства (имя, UUID).
****************************************)


interface
uses System.SysUtils, System.Bluetooth, System.Classes,
     System.Permissions; // Модуль для работы с разрешениями


procedure RequestBluetoothPermissions;
function EnableBluetooth: TBluetoothManager;
function GetDeviceByName(AManager: TBluetoothManager; ADaviceName: String): TBluetoothDevice;
function SendBluetoothData(ADevice: TBluetoothDevice; AText: String): Boolean;
function ReadBluetoothData(ADevice: TBluetoothDevice): String;

//Уже спаренные устройство (например, модуль HC-05/06) можно получить через существующий список список напрямую:
function GetDeviceNamesList(ADaviceNamesList: TStrings): TBluetoothManager;


implementation
uses FMX.Dialogs, System.Types;

const
  SPP_UUID = '{00001101-0000-1000-8000-00805F9B34FB}';
  BLUETOOTH_SCAN_PERMISSION = 'android.permission.BLUETOOTH_SCAN';
  BLUETOOTH_CONNECT_PERMISSION = 'android.permission.BLUETOOTH_CONNECT';


procedure RequestBluetoothPermissions;
var
  Permissions: TArray<string>;
begin
  // Для Android 12 и выше запрашиваем новые разрешения
  if TOSVersion.Check(12) then
    Permissions := [BLUETOOTH_SCAN_PERMISSION, BLUETOOTH_CONNECT_PERMISSION]
  else
    // Для более старых версий может потребоваться ACCESS_FINE_LOCATION
    Permissions := ['android.permission.ACCESS_FINE_LOCATION'];

  PermissionsService.RequestPermissions(
    Permissions,
    procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) = 2) and
         (AGrantResults[0] = TPermissionStatus.Granted) and
         (AGrantResults[1] = TPermissionStatus.Granted) then
      begin
        // ✅ Разрешения получены! Теперь можно вызывать методы Bluetooth.
        // Например: BluetoothAdapter.StartDiscovery;
        //ShowMessage('Для работы Bluetooth есть разрешения.');
        ;
      end
      else
      begin
        // ❌ Пользователь отклонил разрешения. Обработайте этот сценарий.
        ShowMessage('Для работы Bluetooth необходимо предоставить разрешения.');
      end;
    end
  );
end;

function EnableBluetooth: TBluetoothManager;
var
  Manager: TBluetoothManager;
begin
  Manager := TBluetoothManager.Current;
  if Manager = nil then
    ShowMessage('Bluetooth не поддерживается на этом устройстве.')
  else
{$IFDEF ANDROID}
    // Включение Bluetooth (только на Android, вызывает системный диалог)
    ; //Manager.EnableBluetooth;
{$ELSE}
    ;
{$ENDIF}
  Result := Manager;
end;

//Этот метод возвращает устройства, которые уже были сопряжены с телефоном ранее.
//Уже спаренное устройство (например, модуль HC-05/06) можно получить через существующий список список напрямую:
function GetDeviceByName(AManager: TBluetoothManager; ADaviceName: String): TBluetoothDevice;
var
  PairedDevices: TBluetoothDeviceList;
  I: Integer;
begin
  Result := nil;
  PairedDevices := AManager.GetPairedDevices(AManager.CurrentAdapter);
  for I := 0 to PairedDevices.Count - 1 do
  begin
    //Memo1.Lines.Add(PairedDevices[I].DeviceName);
    if SameText(PairedDevices[I].DeviceName, ADaviceName) then
    begin
      Result := PairedDevices[I];
      break;
    end;
  end;
end;

//Уже спаренные устройство (например, модуль HC-05/06) можно получить через существующий список список напрямую:
function GetDeviceNamesList(ADaviceNamesList: TStrings): TBluetoothManager;
var
  Manager: TBluetoothManager;
  PairedDevices: TBluetoothDeviceList;
  I: Integer;
begin
  ADaviceNamesList.Clear;

  Manager := EnableBluetooth;
  if Manager <> nil then
  begin
    try
      PairedDevices := Manager.GetPairedDevices(Manager.CurrentAdapter);

      for I := 0 to PairedDevices.Count - 1 do
        ADaviceNamesList.Add(PairedDevices[I].DeviceName);
    except on E:Exception do
      ShowMessage(E.Message);
    end;

  end;

  Result := Manager;
end;

//Если устройство ещё не сопряжено, запустите поиск. По завершении будет вызвано событие OnDiscoveryEnd:
(******
function FindNewDeviceByName(AManager: TBluetoothManager; ADaviceName: string): TBluetoothDevice;
  // Обработчик события
  procedure BluetoothManagerDiscoveryEnd(const Sender: TObject;
    const ADeviceList: TBluetoothDeviceList);
  begin
    // ADeviceList содержит найденные устройства
  end;
begin
  AManager.StartDiscovery(5000); // таймаут 5 сек.
  AManager.OnDiscoveryEnd := BluetoothManagerDiscoveryEnd;
end;
*******)

function SendBluetoothData(ADevice: TBluetoothDevice; AText: String): Boolean;
var
  Data: TBytes;
  Socket: TBluetoothSocket;
begin
  Result := False;

  // Предположим, Device уже выбран из списка
  Socket := ADevice.CreateClientSocket(StringToGUID(SPP_UUID), True);
  if Socket <> nil then
    Socket.Connect; // Установка соединения


  Data := TEncoding.UTF8.GetBytes(AText);
  Socket.SendData(Data);

end;

// Приём данных (в отдельном потоке или по таймеру)
function ReadBluetoothData(ADevice: TBluetoothDevice): String;
begin
  Result := '';
end;

end.
