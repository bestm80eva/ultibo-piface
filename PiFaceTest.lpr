program PiFaceTest;

{$mode objfpc}{$H+}

{ Raspberry Pi Application                                                     }
{  Test program for Pi Face HAT }

uses
  RaspberryPi,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes, Console,
  SPI,
  uLog,
  Ultibo, uPiFace
  { Add additional units here };

var
  Console1, Console2, Console3 : TWindowHandle;
  ch : char;
  aPIFace : TPIFace;
  b, ip : byte;
  s : string;
  i : integer;


procedure Log1 (s : string);
begin
  ConsoleWindowWriteLn (Console1, s);
end;

procedure Log2 (s : string);
begin
  ConsoleWindowWriteLn (Console2, s);
end;

procedure Log3 (s : string);
begin
  ConsoleWindowWriteLn (Console3, s);
end;

procedure Msg2 (Sender : TObject; s : string);
begin
  Log2 (s);
end;

begin
  Console1 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_LEFT, true);
  Console2 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_TOPRIGHT, false);
  Console3 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_BOTTOMRIGHT, false);
  SetLogProc (@Log1);
  Log1 ('PiFace Test.');
  Log2 ('Keyboard Commands :-');
  Log2 (' 1 to 8 - Toggle outputs 1 to 8.');
  Log2 (' I      - Read and display inputs.');
  if SYSSPIAvailable then
    Log1 ('SYS SPI Device available.')
  else
    Log1 ('SYS SPI Device not available');
  aPiFace := TPiFace.Create (0);
  while true do
    begin
      if ConsoleReadChar (ch, nil) then
        case (ch) of
          '1'..'8' :
            begin
              b := ord (ch) - ord ('0');
              aPiFace.ToggleOutput (b);
            end;
          'I', 'i' :
            begin
              ip := aPiFace.GetInputs;
              s := 'IN: ';
              b := 1;
              for i := 1 to 8 do
                begin
                  if (ip and b) > 0 then
                    s := s + 'X'
                  else
                    s := s + '_';
                  b := b shl 1;
                end;
              ConsoleWindowWriteLnEx (Console3, '    12345678', 1, 1, COLOR_BLACK, COLOR_WHITE);
              ConsoleWindowWriteLnEx (Console3, s, 1, 2, COLOR_BLACK, COLOR_WHITE);
            end;
        end;
    end;
  ThreadHalt (0);
end.

