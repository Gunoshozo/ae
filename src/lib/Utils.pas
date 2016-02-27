unit Utils;


interface

// todo: make Lower/UpperCase wrapper for Wide*Case.
// todo: reconvertion table for Lower/UpperCase?
// todo: use StringTypeW in RemoveNonWordChars?

uses
  StringsW, Windows, SysUtils, Classes, Graphics; 

type
  TStringArray = array of String;
  TWideStringArray = array of WideString;
  TObjectProcedure = procedure (Parameter: Pointer) of object;

  TCallOnEachLineInCallback = procedure (Line: WideString; Data: Pointer);
  TCallOnEachLineInCallback_OO = procedure (Line: WideString; Data: DWord) of object;

  TMaskMatchInfo = record
    Matched: Boolean;
    StrPos: Word;
    MatchLength: Word;
  end;

function Explode(Delimiter, Str: WideString; Count: Integer = 0; SkipEmpty: Boolean = False): TWideStringArray;
// Split is like Explode with Count = 2. It's faster and more convenient because it doesn't return an array.
// If there was no Splitter then First will be '' and Second will be the while Str.
procedure Split(Str: WideString; Splitter: WideString; out First, Second: WideString);
function CharsOfString(const Str: WideString): TWideStringArray;
function Join(WSArray: array of WideString; Glue: WideString = ', '): WideString;

function IsDelimiter(const Delimiters, S: WideString; Index: Integer): Boolean;
// only European languages (no Japanese and such). Space is considered a word character.
function RemoveNonWordChars(const Str: WideString; DoNotRemove: WideString = ''): WideString;

// note: unlike the standard WrapText, it will remove spaces if they occur at the end of a line.
function WrapText(const Str: WideString; const Delimiter: WideString; const MaxWidth: Word): WideString;
function PadText(const Str: WideString; const NewLine, PadStr: WideString; const MaxWidth: Word): WideString;
function StrRepeat(const Str: WideString; Times: DWord): WideString;

procedure CopyToClipboard(Str: WideString);
function StrToIntW(Str: WideString): Integer;

function CallOnEachLineIn(Str: WideString; const Callback: TCallOnEachLineInCallback;
  const UserData: Pointer = NIL): DWord; overload;
function CallOnEachLineIn(Str: WideString; const Callback: TCallOnEachLineInCallback_OO;
  const UserData: DWord = 0): DWord; overload;

function TrimStringArray(WSArray: TWideStringArray): TWideStringArray;
function Trim(Str: WideString): WideString;
function TrimLeft(Str: WideString): WideString;
function TrimRight(Str: WideString): WideString;

function LaunchInNewThread(Proc: Pointer; Parameter: Pointer): DWord; overload;
function LaunchInNewThread(ObjectProc: TObjectProcedure; Parameter: Pointer): DWord; overload;
// True if thread has finished before timeout, False otherwise.
function WaitForThreadToFinish(TimeOutInSeconds: DWord = INFINITE; Thread: THandle = 0): Boolean;
function KillThread(Thread: THandle = 0; ExitCode: DWord = 1): Boolean;
                                    
function AreBytesEqual(const First, Second: array of Byte): Boolean; overload;
function AreBytesEqual(const First, Second; Length: DWord): Boolean; overload;

function CurrentWinUser: WideString;
function SysErrorMessage(ErrorCode: Integer): WideString;
function IsWritable(const FileName: WideString): Boolean;
function FormatVersion(const Version: Word): String;

function IsInvalidPathChar(const Char: WideChar): Boolean;
function MakeValidFileName(const Str: WideString; const SubstitutionChar: WideChar): WideString;

// note: using TForm's BorderIcons, etc. is slow (form blinks) and not reliable (for some
//       reson it causes TListView.Items to lose all associated objects and other things happen).
procedure ChangeWindowStyle(const Form: HWND; Style: DWord; AddIt: Boolean);

// From http://delphi.about.com
function IntToBin(Int: Byte): String; overload
function IntToBin(Int: Word): String; overload
function IntToBin(Int: DWord; Digits: Byte = 32; SpaceEach: Byte = 8): String; overload;

{ Stream functions }
procedure WriteWS(const Stream: TStream; const Str: WideString);
procedure WriteArray(const Stream: TStream; const WSArray: array of WideString); overload;
procedure WriteArray(const Stream: TStream; const DWArray: array of DWord); overload;

function ReadWS(const Stream: TStream): WideString;
procedure ReadArray(const Stream: TStream; var WSArray: array of WideString); overload;
procedure ReadArray(const Stream: TStream; var DWArray: array of DWord); overload;      

function ParamStrW(Index: Integer): WideString;
function PosW(const Substr, Str: WideString; Start: Word = 1): Integer;
function CompareStr(const S1, S2: WideString): Integer;

function MaskMatch(const Str, Mask: WideString): Boolean;
{ Info can have special values in some cases:
  * Matched = True but MatchLength = 0 (and StrPos having random value) - this means that Mask consisted of only "*" and
    thus no particular substring could be specified (since it could match any part of the string). }
function MaskMatchInfo(const Str, Mask: WideString; StartingPos: Word = 1): TMaskMatchInfo;

procedure FindMask(Mask: WideString; Result: TStringsW); overload;
procedure FindMask(Mask: WideString; Result: TStrings); overload;

procedure StringsW2J(const Src: TStringsW; const Dest: TStrings);
procedure FindAll(BasePath, Mask: WideString; Result: TStringsW); overload;
procedure FindAll(BasePath, Mask: WideString; Result: TStrings); overload;

procedure FindAllRelative(BasePath, Mask: WideString; Result: TStringsW); overload;
procedure FindAllRelative(BasePath, Mask: WideString; Result: TStrings); overload;

// including trailing backslash
function ExtractFilePath(FileName: WideString): WideString;
function ExtractFileName(Path: WideString): WideString;

function ExpandFileName(FileName: WideString): WideString;

function ExtractFileExt(FileName: WideString): WideString;
function ChangeFileExt(FileName, Extension: WideString): WideString;

function IncludeTrailingBackslash(Path: WideString): WideString;
function ExcludeTrailingBackslash(Path: WideString): WideString;

// if file didn't exist, sets Result.ftLastWriteTime.dwLowDateTime to 0
function FileInfo(Path: WideString): TWin32FindDataW;
function IsDirectory(Path: WideString): Boolean;
function FileExists(Path: WideString): Boolean;

{ recursive functions }
function CopyDirectory(Source, Destination: WideString): Boolean;
function RemoveDirectory(Path: WideString): Boolean;

function ForceDirectories(Path: WideString): Boolean;
function MkDir(Path: WideString): Boolean;

function UpperCase(const Str: WideString): WideString;
function LowerCase(const Str: WideString): WideString;

function StripAccelChars(const Str: WideString): WideString;

function InputQueryW(const ACaption, APrompt: WideString; var Value: WideString): Boolean;

type
  TInputBoxesLanguage = record
    OK:         WideString;
    Cancel:     WideString;
  end;

var
  InputBoxesLanguage: TInputBoxesLanguage;

implementation

uses MMSystem, Math,
     Menus, // Menus is used for StripAccelChar (cHotkeyPrefix const).
     JReconvertor, UnicodeComponents, Dialogs, StdCtrls, Controls, // InputQueryW uses.
     Forms;   // Forms is used for Application.ProcessMessages.

type
  TObjectCall = record
    Proc: TObjectProcedure;
    Param: Pointer;
  end;

const
  // for WrapText and PadText.
  LineBreakers: WideString = ' .,!?"'';:'#10#13#9;

var
  LastCreatedThread: DWord = 0;

function Explode(Delimiter, Str: WideString; Count: Integer = 0; SkipEmpty: Boolean = False): TWideStringArray;
var
  Current, P: Integer;
begin
  Current := 0;
  SetLength(Result, $FFFF);

  while Length(Str) <> 0 do
  begin
    Inc(Current);
    P := Pos(Delimiter, Str);

    if (P > 0) and ((Current < Count) or (Count = 0)) then
    begin
      if not SkipEmpty or (P > 1) then
        Result[Current - 1] := Copy(Str, 1, P - 1)
        else
          Dec(Current);
      Str := Copy(Str, P + Length(Delimiter), $FFFF);
    end
      else
      begin
        Result[Current - 1] := Str;
        Break;
      end;
  end;

  SetLength(Result, Current);
end;      

procedure Split(Str: WideString; Splitter: WideString; out First, Second: WideString);
begin
  First := Copy(Str, 1, PosW(Splitter, Str) - 1);
  if First = '' then
    Splitter := '';
  Second := Copy(Str, Length(First) + Length(Splitter) + 1, $FFFF)
end;

function CharsOfString(const Str: WideString): TWideStringArray;
var
  I: Word;
begin
  SetLength(Result, Length(Str));
  for I := 1 to Length(Str) do
    Result[I - 1] := Str[I]
end;
          
function Join(WSArray: array of WideString; Glue: WideString = ', '): WideString;
var
	I: Word;
begin
	Result := '';
	if Length(WSArray) <> 0 then
		for I := 0 to Length(WSArray) - 1 do
			Result := Result + Glue + WSArray[I];

	Result := Copy(Result, Length(Glue) + 1, $FFFF)
end;

function TrimStringArray(WSArray: TWideStringArray): TWideStringArray;
var
  I: Word;
begin
  Result := WSArray;
  if Length(Result) <> 0 then
    for I := 0 to Length(Result) - 1 do
      Result[I] := sysutils.Trim(Result[I])
end;

function Trim(Str: WideString): WideString;
var
  Start, Finish: Word;
begin
  Start := 1;
  while (Start < Length(Str)) and (Str[Start] <= ' ') do
    Inc(Start);
  Finish := Length(Str);
  while (Finish >= Start) and (Str[Finish] <= ' ') do
    Dec(Finish);
  Result := Copy(Str, Start, Finish - Start + 1)
end;

function TrimLeft(Str: WideString): WideString;
var
  Start: Word;
begin
  Start := 1;
  while (Start < Length(Str)) and (Str[Start] <= ' ') do
    Inc(Start);
  Result := Copy(Str, Start, $FFFF)
end;

function TrimRight(Str: WideString): WideString;
var
  Finish: Word;
begin
  Finish := Length(Str);
  while (Finish >= 1) and (Str[Finish] <= ' ') do
    Dec(Finish);
  Result := Copy(Str, 1, Finish)
end;

function IsDelimiter(const Delimiters, S: WideString; Index: Integer): Boolean;
begin
  Result := (Index > 0) and (Index <= Length(S)) and (PosW(S[Index], Delimiters) <> 0)
end;

function RemoveNonWordChars(const Str: WideString; DoNotRemove: WideString = ''): WideString;
var
  I: Word;
begin
  Result := Str;
  if Length(Result) <> 0 then
    for I := Length(Result) downto 1 do
      if not IsDelimiter(DoNotRemove, Result, I) and
         (((Word(Result[I]) <> Word(' ')) and (Word(Result[I]) <= Word('/'))) or
          ((Word(Result[I]) >= Word(':')) and (Word(Result[I]) <= Word('?'))) or
          ((Word(Result[I]) >= Word('[')) and (Word(Result[I]) <= Word('`'))) or
          ((Word(Result[I]) >= Word('{')) and (Word(Result[I]) <= Word('}')))) then
        Delete(Result, I, 1)
end;

function GenericPadText(const Str: WideString; const NewLine, PadStr: WideString; const MaxWidth: Word): WideString;
var
  I, LastDelim, LastBreak, PadCount: Integer;
  Delimiter: WideString;
begin
  Result := Str;

  I := 1;
  LastDelim := 0;
  LastBreak := 1;

  while I <= Length(Result) do
  begin
    if IsDelimiter(LineBreakers, Result, I) then
      LastDelim := I + 1;

    if I - LastBreak < MaxWidth then
      Inc(I)
      else
      begin
        if LastDelim = 0 then
          LastDelim := I
          else if Result[LastDelim - 1] = ' ' then
          begin
            Delete(Result, LastDelim - 1, 1);
            Dec(LastDelim);
          end;

        if PadStr = '' then
          Delimiter := ''
          else
          begin
            PadCount := MaxWidth - (LastDelim - LastBreak);
            Delimiter := StrRepeat(PadStr, PadCount div Length(PadStr));
            Delimiter := Delimiter + Copy(PadStr, 1, PadCount mod Length(PadStr));
          end;
        Delimiter := Delimiter + NewLine;

        Insert(Delimiter, Result, LastDelim);
        I := LastDelim + Length(Delimiter);
        LastDelim := 0;
        LastBreak := I
      end
  end
end;

function WrapText(const Str: WideString; const Delimiter: WideString; const MaxWidth: Word): WideString;
begin
  Result := GenericPadText(Str, Delimiter, '', MaxWidth);
end;

function PadText(const Str: WideString; const NewLine, PadStr: WideString; const MaxWidth: Word): WideString;
begin
  Result := GenericPadText(Str, NewLine, PadStr, MaxWidth);
end;

function StrRepeat(const Str: WideString; Times: DWord): WideString;
begin
  Result := '';
  if Str <> '' then
    for Times := Times downto 1 do
      Result := Result + Str;
end;

procedure CopyToClipboard(Str: WideString);
var
  Data: THandle;
  DataPtr: Pointer;
begin
  Str := Str + #0;
  Data := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, Length(Str) * 2);
  DataPtr := GlobalLock(Data);
  try
    Move(Str[1], DataPtr^, Length(Str) * 2);

    OpenClipboard(0);
    try
      EmptyClipboard;
      SetClipboardData(CF_UNICODETEXT, Data)
    finally
      CloseClipboard
    end
  finally
    GlobalUnlock(Data);
    GlobalFree(Data)
  end
end;

function LaunchInNewThread(Proc: Pointer; Parameter: Pointer): DWord;
begin
  LastCreatedThread := CreateThread(NIL, 0, Proc, Parameter, 0, Result);
  Result := LastCreatedThread
end;

function RunObjectProc(Parameter: Pointer): DWord; stdcall;
begin
  with TObjectCall(Parameter^) do
    Proc(Param);
  FreeMem(Parameter, SizeOf(TObjectCall));
  Result := 1
end;

function LaunchInNewThread(ObjectProc: TObjectProcedure; Parameter: Pointer): DWord;
var
  Call: Pointer;
begin
  GetMem(Call, SizeOf(TObjectCall));
  with TObjectCall(Call^) do
  begin
    Proc := ObjectProc;
    Param := Parameter
  end;

  Result := LaunchInNewThread(@RunObjectProc, Call)
end;

function WaitForThreadToFinish;
var
  TimeOut, ExitCode: DWord;
begin
  if Thread = 0 then
    Thread := LastCreatedThread;

  if TimeOutInSeconds = INFINITE then
    TimeOut := INFINITE
    else
      TimeOut := timeGetTime + TimeOutInSeconds * 1000;

  repeat
    if not GetExitCodeThread(Thread, ExitCode) or (timeGetTime > TimeOut) then
    begin
      KillThread(Thread);
      Result := False;
      Exit
    end;

    Application.ProcessMessages
  until ExitCode <> STILL_ACTIVE;

  Result := True
end;

function KillThread;
begin
  if Thread = 0 then
    Thread := LastCreatedThread;
  Result := TerminateThread(Thread, ExitCode)
end;

function AreBytesEqual(const First, Second: array of Byte): Boolean;
begin
  Result := (Length(First) = Length(Second)) and
            AreBytesEqual(First[0], Second[0], Length(First))
end;

function AreBytesEqual(const First, Second; Length: DWord): Boolean;
var
  I: DWord;
begin
  if Length <> 0 then
    for I := 0 to Length - 1 do
      if Byte( Ptr(DWord(@First) + I)^ ) <> Byte( Ptr(DWord(@Second) + I)^ ) then
      begin
        Result := False;
        Exit
      end;

  Result := True
end;

function CurrentWinUser: WideString;
var
  Length: DWord;
begin
  Length := 300;

  SetLength(Result, Length);
  GetUserNameW(PWideChar(Result), Length);
  SetLength(Result, Length - 1) { one for null char }
end;

function SysErrorMessage(ErrorCode: Integer): WideString;
var
  Buffer: array[0..255] of WideChar;
var
  Len: Integer;
begin
  Len := FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS or
    FORMAT_MESSAGE_ARGUMENT_ARRAY, nil, ErrorCode, 0, Buffer,
    SizeOf(Buffer), nil);
  while (Len > 0) and ((((Buffer[Len - 1] >= #0) and (Buffer[Len - 1] <= #32))) or
        (Buffer[Len - 1] = '.')) do Dec(Len);
  Result := Buffer;
end;

function IsWritable(const FileName: WideString): Boolean;
var
  Handle: DWord;
begin
  Handle := CreateFileW(PWideChar(FileName), GENERIC_READ or GENERIC_WRITE,
                        FILE_SHARE_READ, NIL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  Result := (Integer(Handle) >= 0) and (GetLastError = 0);

  if Handle <> INVALID_HANDLE_VALUE then
    CloseHandle(Handle)
end;

function FormatVersion(const Version: Word): String;
begin
  Result := Format('v%d.%d', [Hi(Version), Lo(Version)])
end;

function IsInvalidPathChar(const Char: WideChar): Boolean;
begin
  Result := (Char = '\') or (Char = '/') or (Char = '*') or (Char = '?') or (Char = '<') or (Char = '>')
end;

function MakeValidFileName(const Str: WideString; const SubstitutionChar: WideChar): WideString;
var
  I: Integer;
begin
  if (Str = '') or (Str = '.') or (Str = '..') then
    Result := StringOfChar(SubstitutionChar, Length(Str) + 1)
    else
    begin
      Result := Str;
      for I := 1 to Length(Result) - 1 do
        if IsInvalidPathChar(Result[I]) then
          Result[I] := SubstitutionChar
    end
end;

procedure ChangeWindowStyle(const Form: HWND; Style: DWord; AddIt: Boolean);
var
  Styles: DWord;
begin
  Styles := DWord(GetWindowLong(Form, GWL_STYLE));

  if AddIt then
    Styles := Styles or Style
    else
      Styles := Styles and not Style;

  SetWindowLong(Form, GWL_STYLE, Styles)
end;

function IntToBin(Int: Byte): String;
begin
  Result := IntToBin(Word(Int), 8)
end;

function IntToBin(Int: Word): String;
begin
  Result := IntToBin(Word(Int), 16)
end;

// From http://delphi.about.com
function IntToBin(Int: DWord; Digits: Byte = 32; SpaceEach: Byte = 8): String;
var
  Current: Byte;
begin
  Result := StringOfChar('0', Digits);

  Current := Digits;
  while Int > 0 do
  begin
    if Int and 1 = 1 then
      Result[Current] := '1';
    Dec(Current);
    Int := Int shr 1
  end;

  for Int := 1 to (Digits - 1) div SpaceEach do
    Insert(' ', Result, Digits - Int * SpaceEach + 1)
end;

{ Stream functions }        

procedure WriteWS(const Stream: TStream; const Str: WideString);
var
  Len: Word;
begin
  Len := Length(Str);
  Stream.Write(Len, SizeOf(Len));
  Stream.Write(Str[1], Len * 2)
end;

procedure WriteArray(const Stream: TStream; const WSArray: array of WideString);
var
  I: Word;
begin
  if Length(WSArray) <> 0 then
    for I := 0 to Length(WSArray) -  1 do
      WriteWS(Stream, WSArray[I])
end;

procedure WriteArray(const Stream: TStream; const DWArray: array of DWord);
begin
  if Length(DWArray) <> 0 then
    Stream.Write(DWArray[0], SizeOf(DWArray[0]) * Length(DWArray))
end;

function ReadWS(const Stream: TStream): WideString;
var
  Len: Word;
begin
  Stream.Read(Len, 2);
  SetLength(Result, Len);
  Stream.Read(Result[1], Len * 2)
end;

procedure ReadArray(const Stream: TStream; var WSArray: array of WideString);
var
  I: Word;
begin
  if Length(WSArray) <> 0 then
    for I := 0 to Length(WSArray) - 1 do
      WSArray[I] := ReadWS(Stream)
end;

procedure ReadArray(const Stream: TStream; var DWArray: array of DWord);
begin
  if Length(DWArray) <> 0 then
    Stream.Read(DWArray[0], SizeOf(DWArray[0]) * Length(DWArray))
end;

function ParamStrW;
var
  I, CurrentIndex: Word;
  CmdLine: WideString;
  Join: Boolean;
begin
  if Index = 0 then
  begin
    SetLength(Result, 500);
    SetLength(Result, GetModuleFileNameW(0, @Result[1], 500));
    Exit
  end;

  CmdLine := GetCommandLineW;

  Result := '';
  Join := False;
  CurrentIndex := 0;

  for I := 1 to Length(CmdLine) do
    if CmdLine[I] = '"' then
      Join := not Join
      else if (CmdLine[I] = ' ') and not Join then
        Inc(CurrentIndex)
        else if CurrentIndex = Index then
          Result := Result + CmdLine[I]
          else if CurrentIndex > Index then
            Exit
end;

function PosW(const Substr, Str: WideString; Start: Word = 1): Integer;
var
  I, Current: Integer;
begin
  Current := 1;

  if Substr <> '' then
		for I := Start to Length(Str) do
      if Substr[Current] <> Str[I] then
			  Current := 1
				else
    			if Current >= Length(Substr) then
		    	begin
				    Result := I - Current + 1;
    				Exit
		    	end
          else
						Inc(Current);

  Result := 0
end;

function MaskMatch(const Str, Mask: WideString): Boolean;
begin
  Result := MaskMatchInfo(Str, Mask).Matched
end;

function MaskMatchInfo;
var
  BeginningAnyMatch, EndingAnyMatch: Word;
  Info: TMaskMatchInfo;

  function Match(const StrI, MaskI: Word): Boolean;
	begin
    if MaskI > Length(Mask) then
      Result := StrI = Length(Str) + 1
      else if StrI > Length(Str) then
        Result := MaskI > EndingAnyMatch
        else if (Mask[MaskI] = '*') or (Mask[MaskI] = '+') then
          Result := Match(Succ(StrI), Succ(MaskI)) or Match(Succ(StrI), MaskI) or
                    ((Mask[MaskI] = '*') and (Match(StrI, Succ(MaskI)))) or (MaskI = Length(Mask))
          else
	 	        Result := ((Mask[MaskI] = Str[StrI]) or (Mask[MaskI] = '?')) and
                      Match(Succ(StrI), Succ(MaskI));

    if Result and ((MaskI <= Length(Mask)) and (Mask[MaskI] <> '*')) then
    begin
      Info.StrPos := Min(Info.StrPos, StrI);
      Info.MatchLength := Max(Info.MatchLength, StrI)
    end
	end;

begin
  Info.StrPos := $FFFF;
  Info.MatchLength := 0;

  BeginningAnyMatch := 1;
  while (BeginningAnyMatch < Length(Mask)) and (Mask[BeginningAnyMatch] = '*') do
    Inc(BeginningAnyMatch);

  EndingAnyMatch := Length(Mask);
  while (EndingAnyMatch > 0) and (Mask[EndingAnyMatch] = '*') do
    Dec(EndingAnyMatch);

  Info.Matched := Match(StartingPos, 1);

  if Info.StrPos = $FFFF then
    Info.MatchLength := 0
    else
      Dec(Info.MatchLength, Info.StrPos - 1);
  Result := Info
end;

function CompareStr(const S1, S2: WideString): Integer;
begin
  Result := CompareStringW(LOCALE_USER_DEFAULT, 0, PWideChar(S1), Length(S1), PWideChar(S2), Length(S2)) - 2
end;

function StrToIntW(Str: WideString): Integer;
const
  { 0..9 }
  ASCII_Zero  = $30;
  JASCII_Zero = $FF10;
  JASCII_Nine = JASCII_Zero + 9;
  { A..F }
  ASCII_A     = $41;
  JASCII_A    = $FF21;
  JASCII_F    = $FF26;
  { a..f }
  ASCII_A_sm  = $61;
  JASCII_a_sm = $FF41;
  JASCII_f_sm = $FF46;
var
  I: Word;
begin
  for I := 1 to Length(Str) do
    if (Ord(Str[I]) >= JASCII_Zero) and (Ord(Str[I]) <= JASCII_Nine) then
      Dec(Word(Str[I]), JASCII_Zero - ASCII_Zero)
      else if (Ord(Str[I]) >= JASCII_A) and (Ord(Str[I]) <= JASCII_F) then
        Dec(Word(Str[I]), JASCII_A - ASCII_A)
        else if (Ord(Str[I]) >= JASCII_a_sm) and (Ord(Str[I]) <= JASCII_f_sm) then
          Dec(Word(Str[I]), JASCII_a_sm - ASCII_a_sm);

  Result := SysUtils.StrToInt(Str)
end;

function CallOnEachLineIn(Str: WideString; const Callback: TCallOnEachLineInCallback;
  const UserData: Pointer = NIL): DWord;
var
  I, PrevNewLine: DWord;
begin
  Result := 0;
  PrevNewLine := 1;

  if (Str <> '') and (Str[Length(Str)] <> #10) and (Str[Length(Str)] <> #13) then
    Str := Str + #10;

  for I := 1 to Length(Str) do
    if (Str[I] = #10) or (Str[I] = #13) then
    begin
      if I > PrevNewLine then
        Callback(Copy(Str, PrevNewLine, I - PrevNewLine), UserData);
      PrevNewLine := I + 1;
      Inc(Result);
    end;
end;

function CallOnEachLineIn(Str: WideString; const Callback: TCallOnEachLineInCallback_OO;
  const UserData: DWord = 0): DWord;
var
  I, PrevNewLine: DWord;
begin
  Result := 0;
  PrevNewLine := 1;

  if (Str <> '') and (Str[Length(Str)] <> #10) and (Str[Length(Str)] <> #13) then
    Str := Str + #10;

  for I := 1 to Length(Str) do
    if (Str[I] = #10) or (Str[I] = #13) then
    begin
      if I > PrevNewLine then
        Callback(Copy(Str, PrevNewLine, I - PrevNewLine), UserData);
      PrevNewLine := I + 1;
      Inc(Result);
    end;
end;

// override SysUtils.FindClose
function FindClose(Handle: DWord): Boolean;
begin
  Result := Windows.FindClose(Handle)
end;

procedure FindMask(Mask: WideString; Result: TStringsW);
var
  SR: TWin32FindDataW;
  Handle: DWord;
begin
  Handle := FindFirstFileW(PWideChar(Mask), SR);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (WideString(SR.cFileName) <> '.') and (WideString(SR.cFileName) <> '..') then
        Result.Add(SR.cFileName, SR.dwFileAttributes)
    until not FindNextFileW(Handle, SR);
    FindClose(Handle)
  end
end;

procedure FindAll(BasePath, Mask: WideString; Result: TStringsW);
var
  I: DWord;
  S: TStringsW;
begin
  BasePath := IncludeTrailingBackslash(BasePath);

  S := TStringsW.Create;
  FindMask(BasePath + Mask, S);

  if S.Count <> 0 then
    for I := 0 to S.Count - 1 do
      if S.Tags[I] and FILE_ATTRIBUTE_DIRECTORY = 0 then
        Result.Add(BasePath + S[I])
        else
          FindAll(BasePath + S[I], Mask, Result);

  S.Free
end;

procedure FindAllRelative(BasePath, Mask: WideString; Result: TStringsW);
var
  I: DWord;
begin
  BasePath := IncludeTrailingBackslash(BasePath);
  FindAll(BasePath, Mask, Result);

  if Result.Count <> 0 then
    for I := 0 to Result.Count - 1 do
      Result[I] := Copy(Result[I], Length(BasePath) + 1, Length(Result[I]))
end;


procedure StringsW2J;
var
  I: Word;
begin
  if Src.Count <> 0 then
    for I := 0 to Src.Count - 1 do
      Dest.Add( Wide2JIS(Src[I]) )
end;

procedure FindMask(Mask: WideString; Result: TStrings);
var
  S: TStringsW;
begin
  S := TStringsW.Create;
  try
    FindMask(Mask, S);
    StringsW2J(S, Result)
  finally
    S.Free
  end
end;

procedure FindAll(BasePath, Mask: WideString; Result: TStrings);
var
  S: TStringsW;
begin
  S := TStringsW.Create;
  try
    FindAll(BasePath, Mask, S);
    StringsW2J(S, Result)
  finally
    S.Free
  end
end;

procedure FindAllRelative(BasePath, Mask: WideString; Result: TStrings);
var
  S: TStringsW;
begin
  S := TStringsW.Create;
  try
    FindAllRelative(BasePath, Mask, S);
    StringsW2J(S, Result)
  finally
    S.Free
  end
end;


function ExtractFilePath(FileName: WideString): WideString;
var
  I: Word;
begin
  Result := '';
  I := Length(FileName);
  while (I >= 1) and (FileName[I] <> '\') and (FileName[I] <> ':') do
    Dec(I);
  Result := Copy(FileName, 1, I);
end;

function IncludeTrailingBackslash(Path: WideString): WideString;
begin
  Result := Path;
  if (Result = '') or (Result[Length(Result)] <> '\') then
    Result := Result + '\'
end;

function ExcludeTrailingBackslash(Path: WideString): WideString;
begin
  Result := Path;
  if (Result <> '') and (Result[Length(Result)] = '\') then
    Result := Copy(Result, 1, Length(Result) - 1)
end;

function ExtractFileName(Path: WideString): WideString;
var
  I: Word;
begin
  for I := Length(Path) downto 1 do
    if (Path[I] = '\') or (Path[I] = ':') then
    begin
      Result := Copy(Path, I + 1, Length(Path));
      Exit
    end;

  Result := Path
end;

function ExtractFileExt(FileName: WideString): WideString;
var
  I: Word;
begin
  for I := Length(FileName) downto 1 do
    if FileName[I] = '\' then
      Break
      else if FileName[I] = '.' then
      begin
        Result := Copy(FileName, I, Length(FileName));
        Exit
      end;

  Result := ''
end;

function ExpandFileName;
var
  Name: PWideChar;
begin
  SetLength(Result, 2000);
  SetLength(Result, GetFullPathNameW(PWideChar(FileName), 1000, PWideChar(Result), Name))
end;

function ChangeFileExt(FileName, Extension: WideString): WideString;
var
  I: Word;
begin
  for I := Length(FileName) downto 1 do
    if FileName[I] = '\' then
      Break
      else if FileName[I] = '.' then
      begin
        Result := Copy(FileName, 1, I - 1) + Extension;
        Exit
      end;

  Result := FileName + Extension;
end;


function FileInfo;
var
  Handle: DWord;
begin
  Handle := FindFirstFileW(PWideChar( ExcludeTrailingBackslash(Path) ), Result);
  if Handle <> INVALID_HANDLE_VALUE then
    FindClose(Handle)
    else
      Result.ftLastWriteTime.dwLowDateTime := 0
end;

function IsDirectory;
begin
  with FileInfo(Path) do
    Result := (ftLastWriteTime.dwLowDateTime <> 0) and (dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0)
end;

function FileExists;
begin
  with FileInfo(Path) do
    Result := (ftLastWriteTime.dwLowDateTime <> 0) and (dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0)
end;

function CopyDirectory;
var
  SR: TWin32FindDataW;
  Handle: DWord;
begin
  Result := True;

  Source := IncludeTrailingBackslash(Source);
  Destination := IncludeTrailingBackslash(Destination);
  ForceDirectories(Destination);

  Handle := FindFirstFileW(PWideChar(Source + '*.*'), SR);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (WideString(SR.cFileName) <> '.') and (WideString(SR.cFileName) <> '..') then
        if (SR.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) then
          Result := CopyDirectory(Source + SR.cFileName, Destination + SR.cFileName) and Result
          else
            Result := CopyFileW( PWideChar(Source + SR.cFileName), PWideChar(Destination + SR.cFileName), False ) and Result
    until not FindNextFileW(Handle, SR);
    FindClose(Handle)
  end
end;

function RemoveDirectory;
var
  SR: TWin32FindDataW;
  Handle: DWord;
begin
  Result := True;
  Path := IncludeTrailingBackslash(Path);

  Handle := FindFirstFileW(PWideChar(Path + '*.*'), SR);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (WideString(SR.cFileName) <> '.') and (WideString(SR.cFileName) <> '..') then
        if (SR.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) then
          Result := RemoveDirectory(Path + SR.cFileName) and Result
          else
            Result := DeleteFileW(PWideChar(Path + SR.cFileName)) and Result
    until not FindNextFileW(Handle, SR);
    FindClose(Handle)
  end;

  Result := RemoveDirectoryW(PWideChar(Path)) and Result
end;

function ForceDirectories(Path: WideString): Boolean;
var
  I: Word;
begin
  Result := True;
  Path := IncludeTrailingBackslash(Path);

  for I := 1 to Length(Path) do
    if Path[I] = '\' then
      try
        CreateDirectoryW(PWideChar(Copy(Path, 1, I)), NIL)
      except
        Result := False;
        Break
      end
end;

function MkDir(Path: WideString): Boolean;
begin
  Result := CreateDirectoryW(PWideChar(Path), NIL)
end;

function UpperCase(const Str: WideString): WideString;
var
  I: Word;
begin
  Result := Str;

  for I := 1 to Length(Result) do
    if (Result[I] >= WideChar('a')) and (Result[I] <= WideChar('z')) then
      Dec(Result[I], 32)
end;

function LowerCase(const Str: WideString): WideString;
var
  I: Word;
begin
  Result := Str;

  for I := 1 to Length(Result) do
    if (Result[I] >= WideChar('A')) and (Result[I] <= WideChar('Z')) then
      Inc(Result[I], 32)
end;        

function StripAccelChars(const Str: WideString): WideString;
var
  I: Word;
begin
  Result := Str;
  for I := 1 to Length(Str) do
    if Str[I] = cHotkeyPrefix then
      Delete(Result, I, 1)
end;

// Dialogs.pas: 2139.
function InputQueryW(const ACaption, APrompt: WideString; var Value: WideString): Boolean;
var
  Form: TForm;
  Prompt: TLabelW;
  Edit: TEdit;
  DialogUnits: TPoint;
  ButtonTop, ButtonWidth, ButtonHeight: Integer;

	function GetAveCharSize(Canvas: TCanvas): TPoint;
	var
		I: Integer;
		Buffer: array[0..51] of Char;
	begin
		for I := 0 to 25 do Buffer[I] := Chr(I + Ord('A'));
		for I := 0 to 25 do Buffer[I + 26] := Chr(I + Ord('a'));
		GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
		Result.X := Result.X div 52;
	end;

begin
  Result := False;
  Form := TForm.Create(Application);
  with Form do
    try
      Canvas.Font := Font;
      DialogUnits := GetAveCharSize(Canvas);
      BorderStyle := bsDialog;
      Caption := ACaption;
      ClientWidth := MulDiv(180, DialogUnits.X, 4);
      Position := poScreenCenter;
      Prompt := TLabelW.Create(Form);
      with Prompt do
      begin
        Parent := Form;
        Caption := APrompt;
        Left := MulDiv(8, DialogUnits.X, 4);
        Top := MulDiv(8, DialogUnits.Y, 8);
        Constraints.MaxWidth := MulDiv(164, DialogUnits.X, 4);
        WordWrap := True;
      end;
      Edit := TEdit.Create(Form);
      with Edit do
      begin
        Parent := Form;
        Font.Charset := SHIFTJIS_CHARSET;
        Left := Prompt.Left;
        Top := Prompt.Top + Prompt.Height + 5;
        Width := MulDiv(164, DialogUnits.X, 4);
        MaxLength := 255;
        Text := Wide2JIS(Value);
        SelectAll;
      end;
      ButtonTop := Edit.Top + Edit.Height + 15;
      ButtonWidth := MulDiv(50, DialogUnits.X, 4);
      ButtonHeight := MulDiv(14, DialogUnits.Y, 8);
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := InputBoxesLanguage.OK;
        ModalResult := mrOk;
        Default := True;
        SetBounds(MulDiv(38, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := InputBoxesLanguage.Cancel;
        ModalResult := mrCancel;
        Cancel := True;
        SetBounds(MulDiv(92, DialogUnits.X, 4), Edit.Top + Edit.Height + 15,
          ButtonWidth, ButtonHeight);
        Form.ClientHeight := Top + Height + 13;          
      end;
      if ShowModal = mrOk then
      begin
        Value := JIS2Wide(Edit.Text);
        Result := True;
      end;
    finally
      Form.Free;
    end;
end;


initialization
  with InputBoxesLanguage do
  begin
    OK        := 'OK';
    Cancel    := 'Cencel';
  end;

end.
