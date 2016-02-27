{
  AE - VN Tools
  © 2007-2016 WKStudio & The Contributors.
  This software is free. Please see License for details.

  Studio Miris archive format & functions
  
  Written by dsp2003.
}

unit AA_ARC_Miris;

interface

uses AA_RFA,
     AnimED_Console,
     AnimED_Math,
     AnimED_Misc,
     AnimED_Translation,
     AnimED_Progress,
     AE_StringUtils,
     AnimED_Directories,
     Classes, Windows, Forms, Sysutils,
     JUtils, JReconvertor, FileStreamJ, StringsW;

 { Supported archives implementation }
 procedure IA_ARC_Miris(var ArcFormat : TArcFormats; index : integer);

  function OA_ARC_Miris : boolean;
  function SA_ARC_Miris(Mode : integer) : boolean;


type
 TARCHdr = packed record
  Magic     : array[1..4] of char; // 'ARC'#$1A
  ExtCount  : longword;
  FileCount : longword;
  FileExt   : array[1..32] of char;
 end;

 TARCDir = packed record
  Offset   : longword;
  FileSize : longword;
  FileName : array[1..24] of char;
 end;

implementation

uses AnimED_Archives;

procedure IA_ARC_Miris;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Studio Miris ARC v1a';
  Ext  := '.arc';
  Stat := $0;
  Open := OA_ARC_Miris;
  Save := SA_ARC_Miris;
  Extr := EA_RAW;
  FLen := 24;
  SArg := 0;
  Ver  := $20150119;
 end;
end;

function OA_ARC_Miris;
var i,j : longword;
    Hdr : TARCHdr;
    Dir : TARCDir;
begin
 Result := False;

 with ArchiveStream do begin
  Seek(0,soBeginning);
  Read(Hdr,SizeOf(Hdr));
  with Hdr do begin
   if Magic <> 'ARC'#$1A then Exit;   
   RecordsCount := FileCount;
  end;

{*}Progress_Max(RecordsCount);

// Reading file table...
  for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);    

   with Dir,RFA[i] do begin
    Read(Dir,SizeOf(Dir));
    RFA_1 := Offset;
    RFA_2 := FileSize;
    RFA_C := FileSize;
    for j := 1 to length(FileName) do if FileName[j] <> #0 then RFA_3 := RFA_3 + FileName[j] else break;
   end;

  end;

  Result := True;
 end;

end;

function SA_ARC_Miris;
var i,j,k : longword;
    Hdr : TARCHdr;
    Dir : TARCDir;
    ExtList : TStringsW;
    ExtString : string;
begin
 Result := False;

 // список для расширений файлов
 ExtList := TStringsW.Create;
 // логика обработки строк и сортировки перенесена в отдельную функцию
 AE_SortStringsWExt(AddedFilesW,ExtList);

 with ArchiveStream do begin

  RecordsCount := AddedFilesW.Count;

  with Hdr do begin
   Magic := 'ARC'#$1A;
   FileCount := RecordsCount;
   ExtCount := ExtList.Count;
   i := 1;
   // Заполняем поле с расширениями. Если там нет выравнивания, то влезет не более 8 штук
   for k := 0 to ExtCount-1 do begin
    ExtString := lowercase(ExtList.Strings[k]);
    FillChar(FileExt,SizeOf(FileExt),0);
    if i = SizeOf(FileExt) then break;
    for j := 1 to length(ExtString) do begin
     FileExt[i] := ExtString[j];
     inc(i);
     if i = SizeOf(Hdr.FileExt) then break;
    end;
   end;
   UpOffset := SizeOf(Hdr)+SizeOf(Dir)*RecordsCount;
  end;

  Write(Hdr,SizeOf(Hdr));

{*}Progress_Max(RecordsCount);

  for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);

   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

   with Dir,RFA[i] do begin
    RFA_3 := ExtractFileName(AddedFiles.Strings[i-1]);

    RFA_1 := UpOffset;
    RFA_2 := FileDataStream.Size;

    FreeAndNil(FileDataStream);

    UpOffset := UpOffset + RFA_2;

    Offset   := RFA_1;
    FileSize := RFA_2;
    FillChar(FileName,SizeOf(FileName),0);
    for j := 1 to Length(FileName) do if j <= length(RFA_3) then FileName[j] := RFA_3[j] else break;
   end;

   // пишем кусок таблицы
   Write(Dir,SizeOf(Dir));
   
  end;

  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);
   // пишем файл в архив
   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);
   CopyFrom(FileDataStream,FileDataStream.Size);
   // высвобождаем поток файла
   FreeAndNil(FileDataStream);
  end;
  
 end; // with ArchiveStream

 Result := True;

end;

end.