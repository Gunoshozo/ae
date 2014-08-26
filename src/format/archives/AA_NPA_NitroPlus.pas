{
  AE - VN Tools
  (c) 2007-2014 WinKiller Studio & The Contributors.
  This software is free. Please see License for details.

  Nitro+ and Nitro+ ChiRAL 'npa' game archive format & functions
  
  Written by dsp2003 & Nik.
  Based on source code of tool 'nipa' written by Wilhansen.
  https://github.com/Wilhansen/nipa
}

unit AA_NPA_NitroPlus;

interface

uses AA_RFA,
     AnimED_Console,
     AnimED_Math,
     AnimED_Misc,
     AnimED_Translation,
     AnimED_Progress,
     AnimED_Directories,
     ZLibEx,
     Classes, Windows, Forms, Sysutils,
     FileStreamJ, JUtils, JReconvertor;

 { Supported archives implementation }
 procedure IA_NPA_NitroPlus(var ArcFormat : TArcFormats; index : integer);

  function OA_NPA_NitroPlus : boolean;
  function SA_NPA_NitroPlus(Mode : integer) : boolean;

  function EA_NPA_NitroPlus(FileRecord : TRFA) : boolean;


  function FileNameCryptFunc(CharIndex, FileIndex, HeadKey1, HeadKey2 : longword) : byte;
  function GetFileCryptKey(FileIndex, HeadKey1, HeadKey2, FileSize : longword; FileName : String) : byte;
  procedure DecryptNPA(DecryptInputStream, DecryptOutputStream : TStream; Key : byte; FileName : String; KeyIndex : longword);

type
 TNPAHdr = packed record
  Magic        : array[1..5] of char; // 'NPA'+$1+$0
  MagicDummy   : array[1..2] of char; // usually $0 but unused
  Key1         : longword;
  Key2         : longword;
  Compressed   : byte; // 1 if compressed
  Encrypted    : byte; // 1 if encrypted
  TotalCount   : longword; // FileCount + FolderCount
  FolderCount  : longword;
  FileCount    : longword;
  Dummy        : int64;
  StartOffset  : longword; // Starting offset for data. Filetable - 0x29 (header) usually.
 end;

 TNPADir = packed record
  // Every entry has
  // NameLength : longword; // Name Length
  // Name : array[1..NameLength] of char; // Name
  FileType  : byte; // 1 = folder, 2 = file
  FileId    : longword; // Just id.
  Offset    : longword; // Offset of file.
  CompSize  : longword; // Compressed file size.
  OrigSize  : longword; // Original file size.
 end;

 TNPADirFN = array[1..1024] of char; // Filename. Zero-terminated. Size varies

 TKeyArray = array[0..255] of byte;
 TKeysArray = array[1..3] of TKeyArray;

const

 npa_ChaosHeadRetail = 1;
 npa_ChaosHeadTrial1 = 2;
 npa_ChaosHeadTrial2 = 3;

 ChaosHeadRetail : TKeyArray = (
	$F1, $71, $80, $19, $17, $01, $74, $7D, $90, $47, $F9, $68, $DE, $B4, $24, $40,
	$73, $9E, $5B, $38, $4C, $3A, $2A, $0D, $2E, $B9, $5C, $E9, $CE, $E8, $3E, $39,
	$A2, $F8, $A8, $5E, $1D, $1B, $D3, $23, $CB, $9B, $B0, $D5, $59, $F0, $3B, $09,
	$4D, $E4, $4A, $30, $7F, $89, $44, $A0, $7A, $3C, $EE, $0E, $66, $BF, $C9, $46,
	$77, $21, $86, $78, $6E, $8E, $E6, $99, $33, $2B, $0C, $EA, $42, $85, $D2, $8F,
	$5F, $94, $DA, $AC, $76, $B7, $51, $BA, $0B, $D4, $91, $28, $72, $AE, $E7, $D6,
	$BD, $53, $A3, $4F, $9D, $C5, $CC, $5D, $18, $96, $02, $A5, $C2, $63, $F4, $00,
	$6B, $EB, $79, $95, $83, $A7, $8C, $9A, $AB, $8A, $4E, $D7, $DB, $CA, $62, $27,
	$0A, $D1, $DD, $48, $C6, $88, $B6, $A9, $41, $10, $FE, $55, $E0, $D9, $06, $29,
	$65, $6A, $ED, $E5, $98, $52, $FF, $8D, $43, $F6, $A4, $CF, $A6, $F2, $97, $13,
	$12, $04, $FD, $25, $81, $87, $EF, $2F, $6C, $84, $2C, $AA, $A1, $AF, $36, $CD,
	$92, $0F, $2D, $67, $45, $E2, $64, $B3, $20, $50, $4B, $F3, $7B, $1F, $1C, $03,
	$C4, $C1, $16, $61, $6F, $C7, $BE, $05, $AD, $22, $34, $B2, $54, $37, $F7, $D0,
	$FA, $60, $8B, $14, $08, $BC, $EC, $BB, $26, $9C, $57, $32, $5A, $3F, $35, $6D,
	$C8, $C3, $69, $7C, $31, $58, $E3, $75, $D8, $E1, $C0, $9F, $11, $B5, $93, $56,
	$F5, $1E, $B1, $1A, $70, $3D, $FB, $82, $DC, $DF, $7E, $07, $15, $49, $FC, $B8
);

 ChaosHeadTrial1 : TKeyArray = (
	$E0, $60, $7F, $08, $06, $F0, $63, $6C, $8F, $36, $E8, $57, $CD, $A3, $13, $3F,
	$62, $8D, $4A, $27, $3B, $29, $19, $FC, $1D, $A8, $4B, $D8, $BD, $D7, $C1, $28,
	$91, $E7, $97, $4D, $0C, $0A, $C2, $12, $BA, $8A, $AF, $C4, $48, $EF, $2A, $F8,
	$3C, $D3, $39, $2F, $6E, $78, $33, $9F, $69, $2B, $DD, $FD, $55, $AE, $B8, $35,
	$66, $10, $75, $67, $5D, $7D, $D5, $88, $22, $1A, $FB, $D9, $31, $74, $2D, $7E,
	$4E, $83, $C9, $9B, $65, $A6, $40, $A9, $FA, $C3, $80, $17, $61, $9D, $D6, $C5,
	$AC, $42, $92, $3E, $8C, $B4, $53, $4C, $07, $85, $F1, $94, $B1, $52, $E3, $FF,
	$5A, $DA, $68, $84, $72, $96, $7B, $89, $9A, $79, $3D, $C6, $CA, $B9, $51, $16,
	$F9, $C0, $CC, $37, $B5, $77, $A5, $98, $30, $0F, $ED, $44, $DF, $C8, $F5, $18,
	$54, $59, $DC, $D4, $87, $41, $EE, $7C, $32, $E5, $93, $BE, $95, $E1, $86, $02,
	$01, $F3, $EC, $14, $70, $76, $DE, $1E, $5B, $73, $1B, $99, $90, $9E, $25, $BC,
	$81, $FE, $1C, $56, $34, $D1, $BB, $A2, $1F, $4F, $3A, $E2, $6A, $0E, $0B, $F2,
	$B3, $B0, $05, $50, $5E, $B6, $AD, $F4, $9C, $11, $23, $A1, $43, $26, $E6, $CF,
	$E9, $5F, $7A, $03, $F7, $AB, $DB, $AA, $15, $8B, $46, $21, $49, $2E, $24, $5C,
	$B7, $B2, $58, $6B, $20, $47, $D2, $64, $C7, $D0, $BF, $8E, $00, $A4, $82, $45,
	$E4, $0D, $A0, $09, $6F, $2C, $EA, $71, $CB, $CE, $6D, $F6, $04, $38, $EB, $A7
);

 ChaosHeadTrial2 : TKeyArray = (
	$F1, $21, $30, $69, $67, $51, $24, $2D, $40, $97, $F9, $18, $DE, $B4, $74, $90,
	$23, $4E, $0B, $88, $9C, $8A, $7A, $5D, $7E, $B9, $0C, $E9, $CE, $E8, $8E, $89,
	$A2, $F8, $A8, $0E, $6D, $6B, $D3, $73, $CB, $4B, $B0, $D5, $09, $F0, $8B, $59,
	$9D, $E4, $9A, $80, $2F, $39, $94, $A0, $2A, $8C, $EE, $5E, $16, $BF, $C9, $96,
	$27, $71, $36, $28, $1E, $3E, $E6, $49, $83, $7B, $5C, $EA, $92, $35, $D2, $3F,
	$0F, $44, $DA, $AC, $26, $B7, $01, $BA, $5B, $D4, $41, $78, $22, $AE, $E7, $D6,
	$BD, $03, $A3, $9F, $4D, $C5, $CC, $0D, $68, $46, $52, $A5, $C2, $13, $F4, $50,
	$1B, $EB, $29, $45, $33, $A7, $3C, $4A, $AB, $3A, $9E, $D7, $DB, $CA, $12, $77,
	$5A, $D1, $DD, $98, $C6, $38, $B6, $A9, $91, $60, $FE, $05, $E0, $D9, $56, $79,
	$15, $1A, $ED, $E5, $48, $02, $FF, $3D, $93, $F6, $A4, $CF, $A6, $F2, $47, $63,
	$62, $54, $FD, $75, $31, $37, $EF, $7F, $1C, $34, $7C, $AA, $A1, $AF, $86, $CD,
	$42, $5F, $7D, $17, $95, $E2, $14, $B3, $70, $00, $9B, $F3, $2B, $6F, $6C, $53,
	$C4, $C1, $66, $11, $1F, $C7, $BE, $55, $AD, $72, $84, $B2, $04, $87, $F7, $D0,
	$FA, $10, $3B, $64, $58, $BC, $EC, $BB, $76, $4C, $07, $82, $0A, $8F, $85, $1D,
	$C8, $C3, $19, $2C, $81, $08, $E3, $25, $D8, $E1, $C0, $4F, $61, $B5, $43, $06,
	$F5, $6E, $B1, $6A, $20, $8D, $FB, $32, $DC, $DF, $2E, $57, $65, $99, $FC, $B8
);

implementation

uses AnimED_Archives;

var NPAKeys : TKeysArray;

procedure IA_NPA_NitroPlus;
begin
 with ArcFormat do begin
  ID   := index;
  IDS  := 'Nitro+';
  Ext  := '.npa';
  Stat := $f;
  Open := OA_NPA_NitroPlus;
  Save := SA_NPA_NitroPlus;
  Extr := EA_NPA_NitroPlus;
  FLen := $ff;
  SArg := 0;
  Ver  := $20140807;
 end;
end;

function OA_NPA_NitroPlus;
var Hdr : TNPAHdr;
    Dir : TNPADir;
    FileName : TNPADirFN;
    FileNameSize : longword;
    TmpByte : byte;
    FileIndex : longword;
    i,j : longword;
begin
 Result := False;

 with ArchiveStream do begin
  Seek(0,soBeginning);
  Read(Hdr,SizeOf(Hdr));
  with Hdr do begin
   if Magic <> 'NPA'#1#0 then Exit; // sanity check
   RecordsCount := FileCount;
  end;

{*}Progress_Max(Hdr.TotalCount);

// Reading file table...
  FileIndex := 1;
  for i := 1 to Hdr.TotalCount do begin

{*}Progress_Pos(i);

   with Dir,RFA[FileIndex] do begin
    Read(FileNameSize,SizeOf(FileNameSize));
//    if FileNameSize > 1024 then Exit; // assumption assert
    Read(FileName[1],FileNameSize);
    Read(Dir,SizeOf(Dir));

    case FileType of
     1 : ; // do nothing if directory
     2 : begin
          RFA_3 := ''; // fix for filename fill bug
          for j := 1 to FileNameSize do begin
           TmpByte := Ord(FileName[j]);
           TmpByte := TmpByte + FileNameCryptFunc(j - 1, i - 1, Hdr.Key1, Hdr.Key2);
           RFA_3 := RFA_3 + Chr(TmpByte);
          end;

          RFA_1 := Offset + Hdr.StartOffset + $29;
          RFA_2 := OrigSize;
          RFA_C := CompSize;
          RFA_E := boolean(Hdr.Encrypted);
          RFA_Z := boolean(Hdr.Compressed);
          RFA_X := acUnknown;
          SetLength(RFA_N,1);
          SetLength(RFA_N[0],1);
          RFA_N[0][0] := i - 1;
          FileIndex := FileIndex + 1;
//        if RFA_1 > Size then Exit; // sanity check
//        if CompSize > Size then Exit; // sanity check
         end;
     else Exit; // sanity check
    end;

   end; // with Dir,RFA[FileIndex]
  end; // for i to Hdr.TotalCount

  SetLength(RFA[0].RFA_N,1);
  SetLength(RFA[0].RFA_N[0],2);
  RFA[0].RFA_N[0][0] := Hdr.Key1;
  RFA[0].RFA_N[0][1] := Hdr.Key2;

  Result := True;
 end; // with ArchiveStream

end;

function SA_NPA_NitroPlus;
var i,j : longword;
    Hdr : TNPAHdr;
    Dir : TNPADir;
begin
 Result := False;
end;

function EA_NPA_NitroPlus;
var TempoStream, TempoStream2 : TStream;
    DecryptKey : byte;
begin
 NPAKeys[1] := ChaosHeadRetail;
 NPAKeys[2] := ChaosHeadTrial1;
 NPAKeys[3] := ChaosHeadTrial2;

 Result := False;
 if ((ArchiveStream <> nil) and (FileDataStream <> nil)) = True then try
  if (FileRecord.RFA_C > 0) and (FileRecord.RFA_1 <= ArchiveStream.Size) then begin
   ArchiveStream.Position := FileRecord.RFA_1;
   if (FileRecord.RFA_E = False) and (FileRecord.RFA_Z = False) then begin
    FileDataStream.CopyFrom(ArchiveStream,FileRecord.RFA_C)
   end else begin
    TempoStream := TMemoryStream.Create;
    TempoStream.CopyFrom(ArchiveStream,FileRecord.RFA_C);
    if FileRecord.RFA_E <> False then begin
     DecryptKey := GetFileCryptKey(FileRecord.RFA_N[0][0], RFA[0].RFA_N[0][0], RFA[0].RFA_N[0][1], FileRecord.RFA_2, FileRecord.RFA_3);
     TempoStream.Position := 0;
     TempoStream2 := TMemoryStream.Create;
     DecryptNPA(TempoStream, TempoStream2, DecryptKey, FileRecord.RFA_3, npa_ChaosHeadRetail);
     FreeAndNil(TempoStream);
     TempoStream := TempoStream2;
     TempoStream2 := nil;
    end;
    if FileRecord.RFA_Z = True then begin
     TempoStream.Position := 0;
     TempoStream2 := TMemoryStream.Create;
     ZDecompressStream(TempoStream, TempoStream2);
     FreeAndNil(TempoStream);
     TempoStream := TempoStream2;
     TempoStream2 := nil;
    end;
    TempoStream.Position := 0;
    FileDataStream.CopyFrom(TempoStream,TempoStream.Size);
    FreeAndNil(TempoStream);
   end;
  end;
 except
 end;
 Result := True;

end;

function FileNameCryptFunc;
var key, temp : longword;
begin
  key := $FC * CharIndex;
  temp := HeadKey1 * HeadKey2;

  key := key - (temp shr $18);
  key := key - (temp shr $10);
  key := key - (temp shr $08);
  key := key - (temp and $ff);

  key := key - (FileIndex shr $18);
  key := key - (FileIndex shr $10);
  key := key - (FileIndex shr $08);
  key := key - FileIndex;

  Result := key and $ff;
end;

function GetFileCryptKey;
var key1, key2, i : longword;
begin
  key1 := $87654321; // FIXME: Not for all games.
  key2 := HeadKey1 * HeadKey2;

  for i := 1 to Length(FileName) do begin
   key1 := key1 - Ord(FileName[i]);
  end;

  key1 := key1 * Length(FileName);
  key1 := key1 + key2;
  key1 := key1 * FileSize;

  Result := key1 and $ff;
end;

procedure DecryptNPA;
var i, limit : longword;
    arr : TKeyArray;
    bt : byte;
begin
  limit := $1000 + Length(FileName);
  if DecryptInputStream.Size < limit then limit := DecryptInputStream.Size;
  limit := limit - 1;
  arr := NPAKeys[KeyIndex];
  for i := 0 to limit do begin
   DecryptInputStream.Read(bt, 1);
   bt := arr[bt];
   bt := ((bt - Key) - i);
   DecryptOutputStream.Write(bt, 1);
  end;
  if DecryptInputStream.Size > limit then begin
  i := DecryptInputStream.Position;
   DecryptOutputStream.CopyFrom(DecryptInputStream,DecryptInputStream.Size - limit - 1);
  end;
end;


end.