{
  AE - VN Tools
  © 2007-2016 WKStudio & The Contributors.
  This software is free. Please see License for details.

  Petka & Vasilij Ivanovich 1: Saving the Galaxy,
  Petka & Vasilij Ivanovich 2: Judgement Day game archive format & functions
  
  Written by dsp2003 & Nik.
}

unit AA_STR_Petka;

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
 procedure IA_STR_Petka(var ArcFormat : TArcFormats; index : integer);

  function OA_STR_Petka : boolean;
  function SA_STR_Petka(Mode : integer) : boolean;

type
 TSTRHdr = packed record
  Magic       : array[1..4] of char; // 'StOR'
  TableOffset : longword; // offset of file table
 end;

 //Filecount : longword;

 TSTRDir = packed record
  Dummy       : longword; // Unknown. Not used in the game
  Offset      : longword; // Absolute offset of file
  FileSize    : longword; // Size of file
 end;

 TSTRDirFN = array[1..256] of char; // Filename. Zero-terminated. Size varies

implementation

uses AnimED_Archives;

procedure IA_STR_Petka;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Petka and Vasilij Ivanovich (1/2)';
  Ext  := '.str';
  Stat := $0;
  Open := OA_STR_Petka;
  Save := SA_STR_Petka;
  Extr := EA_RAW;
  FLen := $ff;
  SArg := 0;
  Ver  := $20140722;
 end;
end;

function OA_STR_Petka;
var i,j : longword;
    Hdr : TSTRHdr;
    Dir : TSTRDir;
    FileName : TSTRDirFN;
begin
 Result := False;

 with ArchiveStream do begin
  Seek(0,soBeginning);
  Read(Hdr,SizeOf(Hdr));
  with Hdr do begin
   if Magic <> 'StOR' then Exit; // sanity check
   if TableOffset > Size then Exit; // more sanity checks
   Seek(TableOffset,soBeginning);
   // reading number of files
   Read(i,SizeOf(i));
   RecordsCount := i;
  end;

{*}Progress_Max(RecordsCount);

// Reading file table...
  for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);    

   with Dir,RFA[i] do begin
    Read(Dir,SizeOf(Dir));
    RFA_1 := Offset;
//    if Offset > Size then Exit; // sanity check
    RFA_2 := FileSize;
//    if FileSize > Size then Exit; // sanity check
    RFA_C := FileSize;
   end;

  end;

  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);
   RFA[i].RFA_3 := ''; // fix for filename fill bug
   FillChar(FileName,SizeOf(FileName),0);  // clean array
   for j := 1 to length(FileName) do begin
    Read(FileName[j],1);
    if FileName[j] = #0 then break;
   end;
   for j := 1 to length(FileName) do begin
    if FileName[j] <> #0 then RFA[i].RFA_3 := RFA[i].RFA_3 + FileName[j];
   end;
  end;

  Result := True;
 end;

end;

function SA_STR_Petka;
var i,j : longword;
    Hdr : TSTRHdr;
    Dir : TSTRDir;
begin
 Result := False;

 with ArchiveStream do begin

  RecordsCount := AddedFilesW.Count;
  ReOffset := SizeOf(Hdr);

  // Getting sizes of files for filetable offsets, etc
  for i := 1 to RecordsCount do begin
   with RFA[i] do begin
    OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);
    RFA_1 := ReOffset;
    RFA_2 := FileDataStream.Size;
    RFA_3 := AddedFilesW.Strings[i-1]; // format supports paths
    ReOffset := ReOffset + RFA_2; // we don't need to call the object function again. speeds things up
    FreeAndNil(FileDataStream);
   end;
  end;

  with Hdr do begin
   Magic       := 'StOR';
   TableOffset := ReOffset;
  end;

  Write(Hdr,SizeOf(Hdr));

{*}Progress_Max(RecordsCount);

  // writing files
  for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);
   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);
   CopyFrom(FileDataStream,FileDataStream.Size);
   FreeAndNil(FileDataStream);
  end;

  // writing number of files
  i := RecordsCount;
  Write(i,SizeOf(i));

  // writing file table
  for i := 1 to RecordsCount do begin

{*}Progress_Pos(i);

   with Dir,RFA[i] do begin
    Dummy    := $AE887001; // AE VN TOOL
    Offset   := RFA_1;
    FileSize := RFA_2;
   end;

   Write(Dir,SizeOf(Dir));
   
  end;

  j := 0;

  // writing filenames
  for i := 1 to RecordsCount do begin
   with RFA[i] do begin
 {*}Progress_Pos(i);
    Write(RFA_3[1],Length(RFA_3));
    Write(j,1); // trailing zero
   end;
  end;
  
 end; // with ArchiveStream

 Result := True;

end;

end.