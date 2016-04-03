{
  AE - VN Tools
  © 2007-2016 WKStudio & The Contributors.
  This software is free. Please see License for details.

  Visual Novel Adventure Platform UGU v1.10 archive format & functions
  
  Written by dsp2003.
}

unit AA_UGU_VNAP;

interface

uses AA_RFA,
     AnimED_Console,
     AnimED_Math,
     AnimED_Misc,
     AnimED_Translation,
     AnimED_Progress,
     AnimED_Directories,
     Classes, Windows, Forms, Sysutils, ZlibEx,
     FileStreamJ, JUtils, JReconvertor;

 { Supported archives implementation }
 procedure IA_UGU_VNAP(var ArcFormat : TArcFormats; index : integer);

  function OA_UGU_VNAP : boolean;
  function SA_UGU_VNAP(Mode : integer) : boolean;

type

 TUGUHdr = packed record
  Magic     : array[1..3] of char; // 'UGU' Uguu~ >w<
  Version   : array[1..3] of char; // '110'
  FileCount : longword;
 end;

 TUGUDir = packed record
//FNLength  : longword;
//Filename  : string;
  Offset    : longword;
  Filesize  : longword;
  CFilesize : longword; // Files are compressed via zlib
  Unknown   : byte; // 0x03 - txt, 0x02 - png? Something to do with encryption?
 end;

implementation

uses AnimED_Archives;

procedure IA_UGU_VNAP;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'VNAP UGU v1.10';
  Ext  := '.ugu';
  Stat := $0;
  Open := OA_UGU_VNAP;
  Save := SA_UGU_VNAP;
  Extr := EA_zlib;
  FLen := $ff;
  SArg := 0;
  Ver  := $20131214;
 end;
end;

function OA_UGU_VNAP;
var i : integer;
    Hdr : TUGUHdr;
    Dir : TUGUDir;
    FNLength : longword;
    Filename : string;
begin
 Result := False;

 with ArchiveStream do begin
  Seek(0,soBeginning);
  Read(Hdr,SizeOf(Hdr));
  with Hdr do begin
   if Magic <> 'UGU' then Exit;
   if Version <> '110' then LogW('[DEBUG] AA_UGU_110.pas: Expected version: 110. Found: '+Version);
   RecordsCount := FileCount;
  end;

{*}Progress_Max(RecordsCount);

// Reading file table...
  for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);    

   Read(FNLength,SizeOf(FNLength));
   if FNLength = 0 then Exit;
   SetLength(Filename,FNLength);
   Read(Filename[1],FNLength);

   with Dir,RFA[i] do begin
    Read(Dir,SizeOf(Dir));
    RFA_1 := Offset;
    RFA_2 := FileSize;
    RFA_C := CFileSize;
    RFA_Z := True;
    RFA_X := acZlib;
    RFA_3 := FileName;
   end;

  end;

  ReOffset := Position;

  for i := 1 to RecordsCount do begin
   RFA[i].RFA_1 := RFA[i].RFA_1 + ReOffset;
  end;

  Result := True;
 end;

end;

function SA_UGU_VNAP;
var i,j : integer;
    Hdr : TUGUHdr;
    Dir : TUGUDir;
    FNLength : longword;
    Filename : string;
begin
 Result := False;

 with ArchiveStream do begin

  RecordsCount := AddedFiles.Count;

  with Hdr do begin
   Magic     := 'UGU';
   Version   := '110';
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