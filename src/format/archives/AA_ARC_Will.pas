{
  AE - VN Tools
  © 2007-2016 WKStudio & The Contributors.
  This software is free. Please see License for details.

  Will Co. Engine ARC game archive format & functions
  
  Written by dsp2003, with help of w8m. ^_~
}

unit AA_ARC_Will;

interface

uses AA_RFA,
     AnimED_Console,
     AnimED_Math,
     AnimED_Misc,
     AnimED_Directories,
     AnimED_Progress,
     AE_StringUtils,
     AnimED_Translation,
     SysUtils, Classes, Windows, Forms,
     JUtils, JReconvertor, FileStreamJ, StringsW;

 { Supported archives implementation }
 procedure IA_ARC_Will_1_8(var ArcFormat : TArcFormats; index : integer);
 procedure IA_ARC_Will_1_12(var ArcFormat : TArcFormats; index : integer);
 procedure IA_ARC_Will_2(var ArcFormat : TArcFormats; index : integer);

  function OA_ARC_Will_1_8 : boolean;
  function SA_ARC_Will_1_8(Mode : integer) : boolean;
  function OA_ARC_Will_1_12 : boolean;
  function SA_ARC_Will_1_12(Mode : integer) : boolean;
  function OA_ARC_Will_2 : boolean;
  function SA_ARC_Will_2(Mode : integer) : boolean;


{ procedure ARC_Will_SortFiles(var Input,Ext : TStringsW);}

type
{ Will Co. Engine ARC v1 format structural description }
 TARCHeader = packed record
  ExtRec     : longword;             // Количество расширений имеющихся файлов.
 end;
 TARCExtDir = packed record
  Ext        : array[1..4] of char;  // Расширение (максимум 4 символа).
  FileCount  : longword;             // Число типа LONGWORD. Кол-во файлов.
  ExtFOffset : longword;             // Оффсет, указывающий в начало списка
                                     // файлов, которым следует присвоить расширение.
 end;
 TARC8Dir = packed record
  FileName   : array[1..9] of char;  // Имя файла БЕЗ расширения.
  Filesize   : longword;             // Число типа LONGWORD. Размер файла.
  Offset     : longword;             // Число типа LONGWORD. Оффсет файла.
 end;
 TARC12Dir = packed record           // для более новых версий архива
  FileName   : array[1..13] of char; // Имя файла БЕЗ расширения.
  Filesize   : longword;             // Число типа LONGWORD. Размер файла.
  Offset     : longword;             // Число типа LONGWORD. Оффсет файла.
 end;

 { Will Co. Engine ARC v2 format structural description }
 TARC2Hdr = packed record
  FileCount : longword;               // number of files in archive
  TableSize : longword;               // filetable size (header is not included)
 end;
 TARC2Dir = packed record
  Filesize  : longword;               // size of file
  Offset    : longword;               // Relative offset. ReOffset = Hdr+TableSize
//Filename : widestring;              // filename in unicode format
 end;
 TARC2DirFN = array[1..4096] of widechar; // Filename. Zero-terminated. Size varies.

implementation

uses AnimED_Archives;

procedure IA_ARC_Will_1_8;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Will Co. ARC v1-8';
  Ext  := '.arc';
  Stat := $0;
  Open := OA_ARC_Will_1_8;
  Save := SA_ARC_Will_1_8;
  Extr := EA_RAW;
  FLen := 12;
  SArg := 0;
  Ver  := $20110403;
 end;
end;

procedure IA_ARC_Will_1_12;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Will Co. ARC v1-12';
  Ext  := '.arc';
  Stat := $0;
  Open := OA_ARC_Will_1_12;
  Save := SA_ARC_Will_1_12;
  Extr := EA_RAW;
  FLen := 16;
  SArg := 0;
  Ver  := $20110403;
 end;
end;

procedure IA_ARC_Will_2;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Will Co. ARC v2';
  Ext  := '.arc';
  Stat := $0;
  Open := OA_ARC_Will_2;
  Save := SA_ARC_Will_2;
  Extr := EA_RAW;
  FLen := $FFF;
  SArg := 0;
  Ver  := $20140708;
 end;
end;

function OA_ARC_Will_1_8;
{ Will Co. ARC archive opening function }
var i,k : integer; ExtAppend : string[4];
    Hdr    : TArcHeader;
    ExtDir : array of TARCExtDir;
    Dir    : TARC8Dir;
begin
 Result := False;
 with ArchiveStream do begin
  RecordsCount := 0;
  Seek(0,soBeginning);

  Read(Hdr,SizeOf(Hdr));

  with Hdr do begin
   if ExtRec = 0 then Exit;
   if ExtRec > $FF then Exit;

   SetLength(ExtDir,ExtRec); // устанавливаем количество слотов под расширения
   for i := 0 to ExtRec-1 do begin
    Read(ExtDir[i],SizeOf(TARCExtDir));
    with ExtDir[i] do begin
     if (FileCount = 0) or (FileCount > $FFFF) then Exit;
     RecordsCount := RecordsCount+Filecount;
    end;
   end;

   ReOffset := SizeOf(Hdr)+ExtRec*SizeOf(TARCExtDir)+SizeOf(Dir)*RecordsCount;

   if ReOffset > Size then Exit;

{*}Progress_Max(RecordsCount);
// Reading filetable...

   ReOffset := 0;

   for i := 1 to RecordsCount do begin
{*} Progress_Pos(i);
    Read(Dir,SizeOf(Dir));

    with Dir, RFA[i] do begin
     if Offset = 0 then Exit;
     for k := 0 to ExtRec-1 do if Position > ExtDir[k].ExtFOffset then ExtAppend := ExtDir[k].Ext; // Working with extensions table...
     for k := 1 to SizeOf(Filename) do if FileName[k] <> #0 then RFA_3 := RFA_3 + FileName[k] else break;

     RFA_3 := RFA_3 +'.'+ExtAppend; // Working with extensions table...
     RFA_1 := Offset;
     RFA_2 := FileSize;
     RFA_C := RFA_2; // replicates filesize
    end; //with

   end; //for

  end; //with Hdr

 end; //with ArchiveStream

 Result := True;

end;

{ Will Co. Engine ARC archive creating function }
function SA_ARC_Will_1_8;
var i,j : integer;
    ExtList : TStringsW;
    Hdr    : TArcHeader;
    ExtDir : array of TARCExtDir;
    Dir    : TARC8Dir;
begin
 // список для расширений файлов
 ExtList := TStringsW.Create;
 // логика обработки строк и сортировки перенесена в отдельную функцию
 AE_SortStringsWExt(AddedFilesW,ExtList);

 with Hdr, ArchiveStream do begin
  ExtRec := ExtList.Count;

  // Writing...
  Write(Hdr,SizeOf(Hdr));

  SetLength(ExtDir,ExtList.Count); // слоты под расширения

// Using the Reoffset variable for calculating the archive table sections ... OMG WTF!?
// Will Co. coders are truly lunatics! >_<
  ReOffset := SizeOf(Hdr)+ExtRec*SizeOf(TARCExtDir);

  for i := 0 to ExtRec-1 do begin
   with ExtDir[i] do begin
    for j := 1 to 4 do begin
     if j <= length(ExtList.Strings[i])-1 then Ext[j] := char(ExtList.Strings[i][j+1]) else Ext[j] := #0;
    end;
    // берём количество файлов из тега
    FileCount := ExtList.Tags[i];

    ExtFOffset := ReOffset;
    ReOffset := ReOffset + SizeOf(Dir)*FileCount; // Adding size of the future linked-to-extension filetable section. The LAST calculated value is used for the first file offset.
   end;
   // Writing...
   Write(ExtDir[i],SizeOf(ExtDir[i]));
  end;

// Creating file table...
  RFA[1].RFA_1 := ReOffset;
  UpOffset     := ReOffset;
  RecordsCount := AddedFilesW.Count;

  for i := 1 to RecordsCount do begin // unlike other archives, RecordsCount is not quite situable here
{*}Progress_Pos(i);
   with Dir do begin
    FillChar(Dir,SizeOf(Dir),0);
    OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

    UpOffset := UpOffset + FileDataStream.Size;
    RFA[i+1].RFA_1 := UpOffset;
    RFA[i].RFA_2 := FileDataStream.Size;
    RFA[i].RFA_3 := ExtractFileName(AddedFilesW.Strings[i-1]);
    for j := 1 to SizeOf(Filename) do begin
     if j <= length(RFA[i].RFA_3)-length(ExtractFileExt(RFA[i].RFA_3)) then FileName[j] := RFA[i].RFA_3[j] else break;
    end;
    Offset := RFA[i].RFA_1;
    FileSize := RFA[i].RFA_2;
    FreeAndNil(FileDataStream);
   end;
   // Writing part of the filetable...
   Write(Dir,SizeOf(Dir));
  end;

  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);

   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

   CopyFrom(FileDataStream,FileDataStream.Size);
   FreeAndNil(FileDataStream);
  end;

 end; // with hdr, ArchiveStream

 Result := True;

end;

function OA_ARC_Will_1_12;
{ Will Co. ARC archive opening function }
var i,k : integer; ExtAppend : string[4];
    Hdr    : TArcHeader;
    ExtDir : array of TARCExtDir;
    Dir    : TARC12Dir;
begin
 Result := False;
 with ArchiveStream do begin
  RecordsCount := 0;
  Seek(0,soBeginning);

  Read(Hdr,SizeOf(Hdr));

  with Hdr do begin
   if ExtRec = 0 then Exit;
   if ExtRec > $FF then Exit;

   SetLength(ExtDir,ExtRec+1); // устанавливаем количество слотов под расширения
   for i := 1 to ExtRec do begin
    Read(ExtDir[i],SizeOf(TARCExtDir));
    with ExtDir[i] do begin
     if (FileCount = 0) or (FileCount > $FFFF) then Exit;
     RecordsCount := RecordsCount+Filecount;
    end;
   end;

   ReOffset := SizeOf(Hdr)+ExtRec*SizeOf(TARCExtDir)+SizeOf(Dir)*RecordsCount;

   if ReOffset > ArchiveStream.Size then Exit;

{*}Progress_Max(RecordsCount);
// Reading filetable...
   for i := 1 to RecordsCount do begin
{*} Progress_Pos(i);
    Read(Dir,SizeOf(Dir));

    with Dir, RFA[i] do begin
     if Offset = 0 then Exit;
     for k := 1 to ExtRec do if Position > ExtDir[k].ExtFOffset then ExtAppend := ExtDir[k].Ext; // Working with extensions table...
     for k := 1 to SizeOf(Filename) do if FileName[k] <> #0 then RFA_3 := RFA_3 + FileName[k] else break;

     RFA_3 := RFA_3 +'.'+ExtAppend; // Working with extensions table...
     RFA_1 := Offset;
     RFA_2 := FileSize;
     RFA_C := RFA_2; // replicates filesize
    end; //with

   end; //for

  end; //with Hdr

 end; //with ArchiveStream

 Result := True;

end;

{ Will Co. Engine ARC archive creating function }
function SA_ARC_Will_1_12;
var i,j : integer;
    ExtList : TStringsW;
    Hdr    : TArcHeader;
    ExtDir : array of TARCExtDir;
    Dir    : TARC12Dir;
begin
 // список для расширений файлов
 ExtList := TStringsW.Create;
 // логика обработки строк и сортировки перенесена в отдельную функцию
 AE_SortStringsWExt(AddedFilesW,ExtList);

 with Hdr, ArchiveStream do begin
  ExtRec := ExtList.Count;

  // Writing...
  Write(Hdr,SizeOf(Hdr));

  SetLength(ExtDir,ExtList.Count); // слоты под расширения

// Using the Reoffset variable for calculating the archive table sections ... OMG WTF!?
// Will Co. coders are truly lunatics! >_<
  ReOffset := SizeOf(Hdr)+ExtRec*SizeOf(TARCExtDir);

  for i := 0 to ExtRec-1 do begin
   with ExtDir[i] do begin
    for j := 1 to 4 do begin
     if j <= length(ExtList.Strings[i])-1 then Ext[j] := char(ExtList.Strings[i][j+1]) else Ext[j] := #0;
    end;
    // берём количество файлов из тега
    FileCount := ExtList.Tags[i];

    ExtFOffset := ReOffset;
    ReOffset := ReOffset + SizeOf(Dir)*FileCount; // Adding size of the future linked-to-extension filetable section. The LAST calculated value is used for the first file offset.
   end;
   // Writing...
   Write(ExtDir[i],SizeOf(ExtDir[i]));
  end;

// Creating file table...
  RFA[1].RFA_1 := ReOffset;
  UpOffset     := ReOffset;
  RecordsCount := AddedFilesW.Count;

  for i := 1 to RecordsCount do begin // unlike other archives, RecordsCount is not quite situable here
{*}Progress_Pos(i);
   with Dir do begin
    FillChar(Dir,SizeOf(Dir),0);
    OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

    UpOffset := UpOffset + FileDataStream.Size;
    RFA[i+1].RFA_1 := UpOffset;
    RFA[i].RFA_2 := FileDataStream.Size;
    RFA[i].RFA_3 := ExtractFileName(AddedFilesW.Strings[i-1]);
    for j := 1 to SizeOf(Filename) do begin
     if j <= length(RFA[i].RFA_3)-length(ExtractFileExt(RFA[i].RFA_3)) then FileName[j] := RFA[i].RFA_3[j] else break;
    end;
    Offset := RFA[i].RFA_1;
    FileSize := RFA[i].RFA_2;
    FreeAndNil(FileDataStream);
   end;
   // Writing part of the filetable...
   Write(Dir,SizeOf(Dir));
  end;

  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);

   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

   CopyFrom(FileDataStream,FileDataStream.Size);
   FreeAndNil(FileDataStream);
  end;

 end; // with hdr, ArchiveStream

 Result := True;

end;

function OA_ARC_Will_2;
var i,j : longword;
    Hdr : TARC2Hdr;
    Dir : TARC2Dir;
    tmpFNWide : widestring;
    Filename : TARC2DirFN;
begin
 Result := False;

 with ArchiveStream do begin
  Seek(0,soBeginning);
  Read(Hdr,SizeOf(Hdr));
  with Hdr do begin

   if TableSize > ArchiveStream.Size then Exit; // sanity check

   ReOffset := SizeOf(Hdr) + TableSize;

   RecordsCount := FileCount;

   if FileCount = 0 then Exit;      // always do...
   if FileCount > $FFFFF then Exit; // ...sanity checks

{*}Progress_Max(RecordsCount);
// Reading file table...
   for i := 1 to RecordsCount do begin
 {*}Progress_Pos(i);
    with Dir,RFA[i] do begin
     Read(Dir,SizeOf(Dir));
     RFA_1 := Offset + ReOffset;
     RFA_2 := FileSize;
     RFA_C := FileSize;

     if RFA_1 = 0 then Exit;
     if RFA_1 > Size then Exit;
     if RFA_2 > Size then Exit;

     FillChar(FileName,SizeOf(FileName),0);  //cleaning the array in order to avoid garbage
     tmpFNWide := '';                        //same here
     for j := 1 to length(FileName) do begin
      Read(FileName[j],2); {Header size is not fixed... damn!}
      if FileName[j] = #0 then break;
     end;
     for j := 1 to length(FileName) do begin
      if FileName[j] <> #0 then tmpFNWide := tmpFNWide + FileName[j];
     end;

     RFA_3 := Wide2JIS(tmpFNWide);

    end;
   end;
  end;

  Result := True;

 end;
end;

function SA_ARC_Will_2;
var i : longword;
    Hdr       : TARC2Hdr;
    Dir       : TARC2Dir;
    tmpFNWide : widestring;
begin
 with ArchiveStream do begin
  with Hdr do begin
 //Generating header (4 bytes)...
   RecordsCount := AddedFiles.Count;
   ReOffset := SizeOf(Hdr)+SizeOf(Dir)*RecordsCount;
   FileCount := RecordsCount;
{ We have to calculate the header by checking the length of every filename, because the header size is not fixed }
   for i := 1 to RecordsCount do ReOffset := ReOffset+(length(ExtractFileName(AddedFilesW.Strings[i-1]))*2)+2; //+2 means zero word

   TableSize := ReOffSet - SizeOf(Hdr);

  end;
// Writing header...
  Write(Hdr,SizeOf(Hdr));

//Creating file table...
  UpOffset := 0;

  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);
   with Dir do begin
//   FileDataStream := TFileStream.Create(GetFolder+AddedFiles.Strings[i-1],fmOpenRead);
    OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

    RFA[i].RFA_1 := UpOffset; // the RecordsCount+1 value will not be used, so it's not important
    RFA[i].RFA_2 := FileDataStream.Size;

    UpOffset := UpOffset + FileDataStream.Size;

    tmpFNWide := '';
    tmpFNWide := ExtractFileName(AddedFilesW.Strings[i-1])+#0; // +#0 means pcharz symbol

    Offset := RFA[i].RFA_1;
    FileSize := RFA[i].RFA_2;
    FreeAndNil(FileDataStream);
    Write(Dir,SizeOf(Dir));

    Write(tmpFNWide[1],length(tmpFNWide)*2); // writing filename in unicode

   end;
  end;
//Writing files...
  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);

   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

   CopyFrom(FileDataStream,FileDataStream.Size);
   FreeAndNil(FileDataStream);
  end;
 end;

 Result := True;

end;

end.