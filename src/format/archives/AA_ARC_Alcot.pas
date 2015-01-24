{
  AE - VN Tools
  © 2007-2015 WKStudio & The Contributors.
  This software is free. Please see License for details.

  Alcot games ARC archive format & functions

  Written by Nik & dsp2003.
}

unit AA_ARC_Alcot;

interface

uses AA_RFA,

     AnimED_Console,
     AnimED_Math,
     AnimED_Misc,
     AnimED_Directories,
     AnimED_Progress,
     AnimED_Translation,
     Generic_Hashes,
     SysUtils, Classes, Windows, Forms;

type
  TAlcotHdr = packed record
   Magic     : array[1..4] of char; // 'ARC'#26
   ExtCount  : longword; // file extension count
   FileCount : longword; // filecount (64 bytes per record)
   CTableSize : longword; // encrypted table size (header included)
  end;

  TAlcotTableHdr = packed record
   Hash          : longword; // Calculated via Gainax_Hash function, header is NOT included
   Size1         : longword; // Size of the first part
   Size2         : longword; // Size of the second part
   Size3         : longword; // Size of the third part
   DecryptedSize : longword; // Filecount * SizeOf(TAlcotTable48) (64 bytes) | SizeOf(TAlcotTable32) (48 bytes)
  end;

  TAlcotTable48 = packed record
   Offset   : longword; // Относительно конца таблицы
   Size     : longword; // Filesize
   Hash     : longword; // ... or is it?
   Dummy    : longword; // = 0
   FileName : array[1..48] of char; // filename
  end;

  TAlcotTable32 = packed record
   Offset   : longword; // Относительно конца таблицы
   Size     : longword; // Filesize
   Dummy    : int64; // = 0
   FileName : array[1..32] of char; // filename
  end;

 { Supported archives implementation }
 procedure IA_ARC_Alcot_48(var ArcFormat : TArcFormats; index : integer);
 function OA_ARC_Alcot_48 : boolean;
 function SA_ARC_Alcot_48(Mode : integer) : boolean;

 procedure IA_ARC_Alcot_32(var ArcFormat : TArcFormats; index : integer);
 function OA_ARC_Alcot_32 : boolean;
// function SA_ARC_Alcot_32(Mode : integer) : boolean;

 function Alcot_DecodeTable(InputStream : TStream; Info : TAlcotTableHdr) : TStream;

implementation

uses AnimED_Archives;

procedure IA_ARC_Alcot_48;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Alcot 48';
  Ext  := '.arc';
  Stat := $0;
  Open := OA_ARC_Alcot_48;
  Save := SA_ARC_Alcot_48;
  Extr := EA_RAW;
  FLen := 48;
  SArg := 0;
  Ver  := $20150124;
 end;
end;

procedure IA_ARC_Alcot_32;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Alcot 32';
  Ext  := '.arc';
  Stat := $F;
  Open := OA_ARC_Alcot_32;
//  Save := SA_ARC_Alcot_32;
  Extr := EA_RAW;
  FLen := 32;
  SArg := 0;
  Ver  := $20150124;
 end;
end;

function OA_ARC_Alcot_48;
var Hdr  : TAlcotHdr;
    THdr : TAlcotTableHdr;
    Dir  : TAlcotTable48;
  { dsp2003 to Nik:
    There's a potential problem with this logic. Basically, with 48 bytes for
    the header and file extension table, you can only have 8 slots for file
    extensions. Maybe the table is padded to 48 and not really equals to? }
    FileExtensions : array[1..$20] of char;
    tmpstream, tablestream : TStream;
    i : longword;
begin
 Result := false;
 with ArchiveStream do begin
  Position := 0;
  Read(Hdr,sizeof(Hdr));
  with Hdr do begin
   if Magic <> 'ARC'#26 then Exit;
   RecordsCount := FileCount;
   Read(FileExtensions[1],SizeOf(FileExtensions));
   Read(THdr,sizeof(THdr));

   if ArchiveStream.Size < CTableSize then Exit; // sanity check

   tmpstream := TMemoryStream.Create;
   tmpstream.CopyFrom(ArchiveStream,CTableSize - SizeOf(THdr));
   tablestream := Alcot_DecodeTable(tmpstream,THdr);
   FreeAndNil(tmpstream);

   if tableStream = nil then Exit; // sanity check

   ReOffset := SizeOf(Hdr) + SizeOf(FileExtensions) + CTableSize;
  end;

  tableStream.Position := 0;

{*}Progress_Max(RecordsCount);
  for i := 1 to RecordsCount do begin
   with RFA[i] do begin

 {*}Progress_Pos(i);

    TableStream.Read(Dir,SizeOf(Dir));

    RFA_1 := ReOffset + Dir.Offset;
    RFA_2 := Dir.Size;
    if (RFA_1 > Size) or (RFA_1 = 0) then begin
     FreeAndNil(tableStream);
     Exit; // sanity check
    end;
    if RFA_2 > Size then begin
     FreeAndNil(tableStream);
     Exit; // always make sanity check!
    end;
    RFA_3 := String(PChar(@Dir.FileName));
    RFA_C := RFA_2;
   end;
  end;

  FreeAndNil(tableStream);

 end;

 Result := True;
end;

function OA_ARC_Alcot_32;
var Hdr  : TAlcotHdr;
    THdr : TAlcotTableHdr;
    Dir  : TAlcotTable32;
    FileExtensions : array[1..$20] of char;
    tmpstream, tablestream : TStream;
//    copystream : TFileStream; // DEBUG!!!
    i : longword;
begin
 Result := false;
 with ArchiveStream do begin
  Position := 0;
  Read(Hdr,sizeof(Hdr));
  with Hdr do begin
   if Magic <> 'ARC'#26 then Exit;
   RecordsCount := FileCount;
   Read(FileExtensions[1],SizeOf(FileExtensions));
   Read(THdr,sizeof(THdr));

   if ArchiveStream.Size < CTableSize then Exit; // sanity check

   tmpstream := TMemoryStream.Create;
   tmpstream.CopyFrom(ArchiveStream,CTableSize - SizeOf(THdr));
   tablestream := Alcot_DecodeTable(tmpstream,THdr);
   FreeAndNil(tmpstream);

   if tableStream = nil then Exit; // sanity check

 //debug
 //copystream := TFileStream.Create('C:\TEMP\alcotable.bin',fmCreate);
 //dstream.Position := 0;
 //copystream.CopyFrom(dstream,dstream.Size);
 //FreeAndNil(copystream);
 //debug-eof

   ReOffset := SizeOf(Hdr) + SizeOf(FileExtensions) + CTableSize;
  end;

  tableStream.Position := 0;

{*}Progress_Max(RecordsCount);
  for i := 1 to RecordsCount do begin
   with RFA[i] do begin

 {*}Progress_Pos(i);

    TableStream.Read(Dir,SizeOf(Dir));

    RFA_1 := ReOffset + Dir.Offset;
    RFA_2 := Dir.Size;
    if (RFA_1 > Size) or (RFA_1 = 0) then begin
     FreeAndNil(tableStream);
     Exit; // sanity check
    end;
    if RFA_2 > Size then begin
     FreeAndNil(tableStream);
     Exit; // always make sanity check!
    end;
    RFA_3 := String(PChar(@Dir.FileName));
    RFA_C := RFA_2;
   end;
  end;

  FreeAndNil(tableStream);

 end;

 Result := True;
end;

function SA_ARC_Alcot_48;
var Hdr : TAlcotHdr;
    THdr : TAlcotTableHdr;
    FileExtensions : array[1..$20] of char;
    cFileExtensions : array of string;
    curext : string;
    stream, dstream, namesstr : TStream;
    i, j, elen, celen, ind, work : longword;
    extadd : boolean;
    TableArray : array of TAlcotTable48;
begin
 RecordsCount := AddedFilesW.Count;
 Hdr.Magic := 'ARC'#26;
 Hdr.FileCount := RecordsCount;
// THdr.DecryptedSize := RecordsCount*$40;
 with THdr do begin
  DecryptedSize := RecordsCount*sizeof(TAlcotTable48);
  Size2 := 0;
  Size1 := (((DecryptedSize div $100) + 1) div 8) + 1;
  if (DecryptedSize mod $100) = 0 then begin
   Size3 := (DecryptedSize div $100) + DecryptedSize;
  end else begin
   Size3 := (DecryptedSize div $100) + DecryptedSize + 1;
  end;
  Hdr.CTableSize := Size1 + Size3 + sizeof(THdr);
 end;

 UpOffset := 0;

 SetLength(cFileExtensions,0);
 SetLength(TableArray,RecordsCount);
 FillChar(TableArray[0],sizeof(TAlcotTable48)*RecordsCount,0);
 FillChar(FileExtensions[1],SizeOf(FileExtensions),0);
 dstream := TMemoryStream.Create;
 dstream.Write(TableArray[0],THdr.Size1);
 elen := 0;
 for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);
   RFA[i].RFA_3 := AddedFilesW.Strings[i-1];
   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);
   namesstr := TMemoryStream.Create;
   work := Length(RFA[i].RFA_3);
   namesstr.Write(RFA[i].RFA_3[1],work);
   namesstr.Position := 0;
   TableArray[i-1].Hash := Gainax_Hash(namesstr,0);
   FreeAndNil(namesstr);
   TableArray[i-1].Offset := UpOffset;
   TableArray[i-1].Size := FileDataStream.Size;
   UpOffset := UpOffset + FileDataStream.Size;
   FreeAndNil(FileDataStream);
   CopyMemory(@TableArray[i-1].FileName, @RFA[i].RFA_3[1], work);
   curext := ExtractFileExt(RFA[i].RFA_3);
   // extension accumulator
   extadd := true;
   celen := elen;
   // if the extension already found - won't add it
   for j := 1 to celen do if curext = cFileExtensions[j-1] then extadd := false;
   if extadd then begin
    SetLength(cFileExtensions,elen+1);
    cFileExtensions[elen] := curext;
    Inc(elen);
   end;
 end;
 ind := 1;
 Hdr.ExtCount := elen;
 for i := 0 to elen-1 do
 begin
   celen := Length(cFileExtensions[i]);
   if(ind + celen > SizeOf(FileExtensions)) then break;
   CopyMemory(@FileExtensions[ind],@cFileExtensions[i][1],celen);
   ind := ind + celen;
 end;

 stream := TMemoryStream.Create;
 stream.Write(TableArray[0],sizeof(TAlcotTable48)*RecordsCount);
 stream.Position := 0;
 work := $FFFFFFFF;
 while (stream.Position + $100) < stream.Size do
 begin
   dstream.Write(work,1);
   dstream.CopyFrom(stream,$100);
//   stream.Position := stream.Position + $100;
 end;
 work := stream.Size - stream.Position - 1;
 dstream.Write(work,1);
 dstream.CopyFrom(stream,work+1);
 FreeAndNil(stream);
 dstream.Position := 0;
 THdr.Hash := Gainax_Hash(dstream,0);
 dstream.Position := 0;
 ArchiveStream.Write(Hdr,sizeof(Hdr));
 ArchiveStream.Write(FileExtensions[1],SizeOf(FileExtensions));
 ArchiveStream.Write(THdr,sizeof(THdr));
 ArchiveStream.CopyFrom(dstream,dstream.Size);
 FreeAndNil(dstream);

 for i := 1 to RecordsCount do begin
{*}Progress_Pos(i);
   OpenFileStream(FileDataStream,RootDir+AddedFilesW.Strings[i-1],fmOpenRead);
   ArchiveStream.CopyFrom(FileDataStream,FileDataStream.Size);
   FreeAndNil(FileDataStream);
 end;

 SetLength(TableArray,0);
 SetLength(cFileExtensions,0);
 Result := True;
end;

function Alcot_DecodeTable;
var bt, wb : byte;
    ww, ww2 : word;
    PosBlock1, PosBlock2, PosBlock3, CPos : longword;
    arr : array of byte;
begin
  Result := nil;
  if (Info.Size1 + Info.Size2 + Info.Size3) <> InputStream.Size then Exit;
  PosBlock1 := 0;
  PosBlock2 := Info.Size1;
  PosBlock3 := Info.Size2 + PosBlock2;
  Result := TMemoryStream.Create;
  SetLength(arr,InputStream.Size);
  InputStream.Position := 0;
  InputStream.Read(arr[0],InputStream.Size);
  bt := $80;
  while Result.Size < Info.DecryptedSize do
  begin
    if (arr[PosBlock1] and bt) = 0 then
    begin
      ww := arr[PosBlock3] + 1;
      Inc(PosBlock3);
      Result.Write(arr[PosBlock3],ww);
      Inc(PosBlock3,ww);
    end
    else
    begin
      CopyMemory(@ww,@arr[PosBlock2],2);
      ww2 := (ww shr $D) + 3;
      Inc(PosBlock2,2);
      CPos := Result.Position - (ww and $1FFF) - 1;
      while ww2 > 0 do
      begin
        Result.Position := CPos;
        Result.Read(wb,1);
        Result.Position := Result.Size;
        Result.Write(wb,1);
        Inc(CPos);
        Dec(ww2);
      end;
    end;
    bt := bt shr 1;
    if bt = 0 then
    begin
      bt := $80;
      Inc(PosBlock1);
    end;
  end;
  SetLength(arr,0);
end;


end.