{
  AE - VN Tools
  © 2007-2016 WKStudio & The Contributors.
  This software is free. Please see License for details.

  RockStar GTA III\VC\SA game archive format & functions
  
  Written by dsp2003.
}

unit _AA_GhostTrick_iOS;

interface

uses AA_RFA,
     AnimED_Console,
     AnimED_Math,
     AnimED_Misc,
     AnimED_Translation,
     AnimED_Progress,
     AnimED_Directories,
     Classes, Windows, Forms, Sysutils,
     FileStreamJ, JUtils, JReconvertor;

 { Supported archives implementation }
 procedure IA_PAC_GT_iOS(var ArcFormat : TArcFormats; index : integer);

  function OA_PAC_GT_iOS : boolean;
//  function SA_IMG_GTA3v1(Mode : integer) : boolean;


type
 TPACHdr = packed record
  FileCount : longword;
  TableSize : longword;
 end;

implementation

uses AnimED_Archives;

procedure IA_PAC_GT_iOS;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Capcom Ghost Trick iOS PAC';
  Ext  := '.pac';
  Stat := $F;
  Open := OA_IMG_GTA3v1;
//  Save := ;
  Extr := EA_RAW;
  FLen := 0;
  SArg := 0;
  Ver  := $20130911;
 end;
end;

function OA_IMG_GTA3v1;
{ GTA III/VC IMG archive opening function }
var i,j : integer;
    Dir : TIMGDir;
    DIRStream, tmpStream : TStream;
const IMG_Ext : array [1..2] of string = ('.img','.dir');
begin
 Result := False;

 for i := 1 to Length(IMG_Ext) do if not FileExists(ChangeFileExt(ArchiveFileName,IMG_Ext[i])) then Exit;

 // финт ушами. закрываем неправильный файл и открываем .img вне зависимости от того, какой был открыт в данный момент
 if lowercase(ExtractFileExt(ArchiveFileName)) <> IMG_Ext[1] then begin
  FreeAndNil(ArchiveStream);
  ArchiveFileName := ChangeFileExt(ArchiveFileName,IMG_Ext[1]);
  OpenFileStream(ArchiveStream,ArchiveFileName,fmOpenRead);
 end;

 OpenFileStream(tmpStream,ChangeFileExt(ArchiveFileName,IMG_Ext[2]),fmOpenRead);
 DIRStream := TMemoryStream.Create;
 DIRStream.CopyFrom(tmpStream,tmpStream.Size);
 DIRStream.Seek(0,soBeginning);
 FreeAndNil(tmpStream);

 with DIRStream do begin
  if (Size mod SizeOf(Dir)) <> 0 then Exit;
// Reading file table...
  i := 0; // filecount to 0
  while Position < Size do begin
   inc(i); // filecount increasing
   with Dir,RFA[i] do begin
    Read(Dir,SizeOf(Dir));
    RFA_1 := Offset   * 2048;
    RFA_2 := FileSize * 2048;
    RFA_C := FileSize * 2048;
    for j := 1 to length(FileName) do if FileName[j] <> #0 then RFA_3 := RFA_3 + FileName[j] else break;
   end;
  end;
  RecordsCount := i; // filecount

  FreeAndNil(DIRStream);
 end;

 Result := True;

end;

function OA_IMG_GTA3v2;
var i,j : integer;
    Hdr : TIMGHdr;
    Dir : TIMGDir;
begin
 Result := False;

 with ArchiveStream do begin
  Seek(0,soBeginning);
  Read(Hdr,SizeOf(Hdr));
  with Hdr do begin
   if Magic <> 'VER2' then Exit;
   RecordsCount := FileCount;
  end;

{*}Progress_Max(RecordsCount);

// Reading file table...
  for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);    

   with Dir,RFA[i] do begin
    Read(Dir,SizeOf(Dir));
    RFA_1 := Offset   * 2048;
    RFA_2 := FileSize * 2048;
    RFA_C := FileSize * 2048;
    for j := 1 to length(FileName) do if FileName[j] <> #0 then RFA_3 := RFA_3 + FileName[j] else break;
   end;

  end;

  Result := True;
 end;

end;

function SA_IMG_GTA3v1;
var i,j : integer;
    Dummy : array of byte;
    Dir : TIMGDir;
    dirStream : TStream;
begin
 Result := False;

 dirStream := TFileStreamJ.Create(ChangeFileExt(ArchiveFileName,'.dir'),fmCreate);

 RecordsCount := AddedFiles.Count;
 UpOffset := 0;

{*}Progress_Max(RecordsCount);

 for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);

  OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

  with Dir,RFA[i] do begin
   RFA_3    := ExtractFileName(AddedFiles.Strings[i-1]);

   RFA_1    := UpOffset;
   RFA_2    := SizeDiv(FileDataStream.Size,2048);

   UpOffset := UpOffset + RFA_2;

   Offset   := RFA_1 div 2048;
   FileSize := RFA_2 div 2048;
   FillChar(FileName,SizeOf(FileName),0);
   for j := 1 to Length(FileName) do if j <= length(RFA_3) then FileName[j] := RFA_3[j] else break;
  end;

  // пишем кусок таблицы
  dirStream.Write(Dir,SizeOf(Dir));
  with ArchiveStream do begin
  // пишем файл в архив
   CopyFrom(FileDataStream,FileDataStream.Size);
  // пишем массив-пустышку
   SetLength(Dummy,SizeMod(FileDataStream.Size,2048));
   Write(Dummy[0],Length(Dummy));
  end;
  // высвобождаем поток файла
  FreeAndNil(FileDataStream);
 end;
 // высвобождаем поток файла заголовка
 FreeAndNil(dirStream);

 Result := True;

end;

function SA_IMG_GTA3v2;
var i,j : integer;
    Dummy : array of byte;
    Hdr : TIMGHdr;
    Dir : TIMGDir;
begin
 Result := False;

 with ArchiveStream do begin

  RecordsCount := AddedFiles.Count;

  with Hdr do begin
   Magic     := 'VER2';
   FileCount := RecordsCount;
   UpOffset  := SizeDiv(SizeOf(Hdr)+SizeOf(Dir)*RecordsCount,2048);
  end;

  Write(Hdr,SizeOf(Hdr));

{*}Progress_Max(RecordsCount);

  for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);

   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);

   with Dir,RFA[i] do begin
    RFA_3 := ExtractFileName(AddedFiles.Strings[i-1]);

    RFA_1 := UpOffset;
    RFA_2 := SizeDiv(FileDataStream.Size,2048);

    FreeAndNil(FileDataStream);

    UpOffset := UpOffset + RFA_2;

    Offset   := RFA_1 div 2048;
    FileSize := RFA_2 div 2048;
    FillChar(FileName,SizeOf(FileName),0);
    for j := 1 to Length(FileName) do if j <= length(RFA_3) then FileName[j] := RFA_3[j] else break;
   end;

   // пишем кусок таблицы
   Write(Dir,SizeOf(Dir));
   
  end;

  // дописываем выравнивание
  SetLength(Dummy,SizeMod(SizeOf(Hdr)+SizeOf(Dir)*RecordsCount,2048));
  Write(Dummy[0],Length(Dummy));

  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);
   // пишем файл в архив
   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);
   CopyFrom(FileDataStream,FileDataStream.Size);
   // пишем массив-пустышку
   SetLength(Dummy,SizeMod(FileDataStream.Size,2048));
   Write(Dummy[0],Length(Dummy));
   // высвобождаем поток файла
   FreeAndNil(FileDataStream);
  end;
  
 end; // with ArchiveStream

 Result := True;

end;

end.