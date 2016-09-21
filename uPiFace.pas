unit uPiFace;

{$mode objfpc}
{$H+}

// Ultibo unit to control PiFace
// tested on earlier model (26 pin header) with PIB
// pjde 2016
// LGPL v2 license

interface

uses
  Classes, SysUtils, SPI;

const
  oo : array [boolean] of string = ('OFF', 'ON');

  SPI_WRITE_CMD     = $40;
  SPI_READ_CMD      = $41;

  // MCP23S17 Port configuration     // bank = 0
  IODIRA            = $00;           // I/O direction A
  IODIRB            = $01;           // I/O direction B
  IOCON             = $0A;           // I/O config
  GPIOA             = $12;           // port A
  GPIOB             = $13;           // port B
  GPPUA             = $0C;           // port A pullups
  GPPUB             = $0D;           // port B pullups
  OUTPUT_PORT       = GPIOA;
  INPUT_PORT        = GPIOB;

type

  { TPiFace }

  TPiFace = class
  private
    FBoardNo : byte;
    FInputs, FOutputs : byte;
    procedure Init;
    procedure Close;
  public
    function SPIAvailable : boolean;
    procedure SetOutput (no : integer; state : boolean);
    function GetOutput (no : integer) : boolean;
    function GetInput (no : integer) : boolean;
    function GetInputs : byte;
    function GetOutputs : byte;
    procedure SetOutputs (val : byte);
    procedure ToggleOutput (no : integer);
    constructor Create (BoardNo : byte);
    destructor Destroy; override;
  end;


implementation

{ TPiFace }

uses uLog, GlobalConst;

procedure spi_write (no, port, value : byte);
var
  res : LongWord;
  Count : Longword;
  TxBuff, RxBuff : array of byte;
begin
  Count := 0;
  SetLength (TxBuff, 3);
  TxBuff[0] := SPI_WRITE_CMD;
  TxBuff[1] := port;
  TxBuff[2] := value;
  SetLength (RxBuff, length (TxBuff));
  res := SYSSPIWriteRead (no, @TxBuff[0], @RxBuff[0], 3, Count);
  if res <> ERROR_SUCCESS then
    Log ('SPI Write Failed. Error Code ' + res.ToString);
end;

function spi_read (no, port : byte) : byte;
var
  res : LongWord;
  Count : Longword;
  TxBuff, RxBuff : array of byte;
begin
  Count := 0;
  SetLength (TxBuff, 3);
  TxBuff[0] := SPI_READ_CMD;
  TxBuff[1] := port;
  TxBuff[2] := $ff;
  SetLength (RxBuff, length (TxBuff));
  res := SYSSPIWriteRead (no, @TxBuff[0], @RxBuff[0], 3, Count);
  if res <> ERROR_SUCCESS then
    Log ('SPI Read Failed. Error Code ' + res.ToString);
  Result := RxBuff[2];
end;

procedure TPiFace.Init;
var
  res : LongWord;
begin
  res := SYSSPIStart (SPI_MODE_4WIRE, 100000, SPI_CLOCK_PHASE_LOW, SPI_CLOCK_POLARITY_LOW);
  if res = ERROR_SUCCESS then
    Log ('SPI Driver started ok.')
  else
    Log ('SPI Driver failed to start. Error Code ' + res.ToString);
  spi_write (FBoardNo, IOCON,  $08);              // enable hardware addressing
  spi_write (FBoardNo, GPIOA,  $00);              // turn on port A
  spi_write (FBoardNo, IODIRA, $00);              // set port A as an output
  spi_write (FBoardNo, IODIRB, $ff);              // set port B as an input
  spi_write (FBoardNo, GPPUB,  $ff);              // turn on port B pullups
end;

procedure TPiFace.Close;
begin
  Log ('Stopping SPI.');
  SysSPIStop;
end;

function TPiFace.SPIAvailable: boolean;
begin
  Result := SYSSPIAvailable;
end;

procedure TPiFace.SetOutput (no: integer; state: boolean);
var
  mask : byte;
begin
   Log ('Set Output ' + no.ToString + ' ' + oo[state] + '.');
  if not (no in [1..8]) then exit;
  mask := 1 shl (no - 1);
  if state then
    FOutputs := FOutputs or mask
  else
    FOutputs := FOutputs and (mask xor $ff);
  SetOutputs (FOutputs);
end;

function TPiFace.GetOutput (no: integer): boolean;
begin
  Result := false;
end;

function TPiFace.GetInput (no: integer): boolean;
var
  mask : byte;
begin
  Result := false;
  if not (no in [1..8]) then exit;
  GetInputs;
  mask := 1 shl (no - 1);
  Result := (FInputs or mask) > 0;
 end;

function TPiFace.GetInputs: byte;
begin
   FInputs := spi_read (FBoardNo, INPUT_PORT) xor $ff;
   Result := FInputs;
end;

function TPiFace.GetOutputs : byte;
begin
  Result := FOutputs;
end;

procedure TPiFace.SetOutputs (val: byte);
begin
  FOutputs := val;
  spi_write (FBoardNo, OUTPUT_PORT, val);
end;

procedure TPiFace.ToggleOutput (no: integer);
var
  mask : byte;
begin
  if not (no in [1..8]) then exit;
  mask := 1 shl (no - 1);
  SetOutput (no, (FOutputs and mask) = 0);
end;

constructor TPiFace.Create (BoardNo : byte);
begin
  Log ('Creating PIFace.');
  FBoardNo := BoardNo;
  FOutputs := 0;
  FInputs := 0;
  Init;
end;

destructor TPiFace.Destroy;
begin
  Close;
  inherited Destroy;
end;

end.

