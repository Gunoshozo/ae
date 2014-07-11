{
  AE - VN Tools
  © 2007-2014 WinKiller Studio & The Contributors.
  This software is free. Please see License for details.

  Helper WideString Utils
  Written by dsp2003 & w8m.
}
unit AE_StringUtils;

interface

uses SysUtils, Math, StringsW, JUtils;

// функции дл€ сортировки строк
 function AE_CompareStringsW(First,Second : widestring) : integer;
procedure AE_SortStringsW(var InSort : TStringsW);
procedure AE_UpperCaseStringsW(var Input : TStringsW);
procedure AE_LowerCaseStringsW(var Input : TStringsW);
procedure AE_SortStringsWExt(var Input, Ext : TStringsW; MakeUpCase : boolean = true);

implementation

function AE_CompareStringsW;
var i : longword;
begin
 for i := 1 to min(Length(First),Length(Second)) do begin
  if word(First[i]) <> word(Second[i]) then begin
   Result := word(First[i]) - word(Second[i]); Exit;
  end;
 end;
 Result := Length(First) - Length(Second);
end;

// внутренн€€ функци€ сортировки
procedure AE_SortStringsW;
var k,l : longword;
    Tempo : widestring;
begin
 with InSort do begin
  for k := 0 to Count-1 do for l := 0 to Count-1 do begin
   if AE_CompareStringsW(Strings[k],Strings[l]) < 0 then begin // да, именно меньше (<)! иначе будет обратна€ сортировка
    Tempo := Strings[k];
    Strings[k] := Strings[l];
    Strings[l] := Tempo;
   end;
  end;
 end;
end;

procedure AE_UpperCaseStringsW;
var i : longword;
begin
 with Input do begin
  for i := 0 to Count-1 do Strings[i] := UpperCase(Strings[i]);
 end;
end;

procedure AE_LowerCaseStringsW;
var i : longword;
begin
 with Input do begin
  for i := 0 to Count-1 do Strings[i] := LowerCase(Strings[i]);
 end;
end;

// moved from AA_ARC_Will.pas
// previously ARC_Will_SortFiles
procedure AE_SortStringsWExt;
var Sorted : array of TStringsW;
    i,j : longword;
    ItemFound : boolean;
begin
 // переводим все строки в верхний регистр
 if MakeUpCase then AE_UpperCaseStringsW(Input);
{ with Input do begin
  for i := 0 to Count-1 do Strings[i] := UpperCase(Strings[i]);
 end;}

 // заполн€ем список расширений
 for i := 0 to Input.Count-1 do begin
  ItemFound := False;
  if Ext.Count > 0 then begin
   for j := 0 to Ext.Count-1 do begin
    if ExtractFileExt(Input.Strings[i]) = Ext.Strings[j] then begin
     ItemFound := True;
     break;
    end;
   end;
  end;
  if not ItemFound then Ext.Add(ExtractFileExt(Input.Strings[i]));
 end;
 AE_SortStringsW(Ext);

 // устанавливаем количество списков дл€ файлов по расширени€м
 SetLength(Sorted,Ext.Count);
 // создаЄм новые сортированные списки
 for j := 0 to Ext.Count-1 do begin
  Sorted[j] := TStringsW.Create;
  for i := 0 to Input.Count-1 do begin
   if ExtractFileExt(Input.Strings[i]) = Ext.Strings[j] then Sorted[j].Add(Input.Strings[i]);
  end;
  // записываем количество файлов в теги
  Ext.Tags[j] := Sorted[j].Count;
  AE_SortStringsW(Sorted[j]);
 end;
 // очищаем входной список файлов
 Input.Clear;
 // добавл€ем данные из сортированных списков
 for j := 0 to Ext.Count-1 do begin
  for i := 0 to Sorted[j].Count-1 do begin
   Input.Add(Sorted[j].Strings[i]);
  end;
  FreeAndNil(Sorted[j]);
 end;
 // высвобождаем пам€ть
 SetLength(Sorted,0);

end;

end.