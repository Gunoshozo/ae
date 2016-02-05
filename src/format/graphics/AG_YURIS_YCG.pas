{
  AE - VN Tools
  © 2007-2016 WKStudio and The Contributors.
  This software is free. Please see License for details.
  
  YU-RIS YCG image format library

  Written by dsp2003.
}

unit AG_YURIS_YCG;

interface

uses Classes, SysUtils,
     ZLibEx,
     AnimEd_Console,
     AG_Portable_Network_Graphics,
     AG_Fundamental,
     AG_StdFmt,
     AG_RFI;

function Import_YURIS_YCG(InputStream, OutputStream : TStream; OutputStreamA : TStream = nil) : TRFI;
procedure IG_YURIS_YCG(var ImFormat : TImageFormats);

type
 TYURISYCGHdr = packed record
  Magic       : array[1..4] of char; // 'YCG'#0
  Width       : longword; // image width
  Height      : longword; // image height
  BitDepth    : longword; // bit depth (seems to always be 32 bit)
  IsChunked   : longword; // Always 1 ? = True
  NumOfChunks : longword; // Always 2 ?
 end;
 // Looks like the images are split in half. What a weirdos >_<
 TYURISYCGChunk = packed record // repeat reading this for NumOfChunks
  ScanLineB   : longword; // scanline range begin (first chunk starts with 0)
  ScanLineE   : longword; // scanline range end
  DataSize    : longword; // uncompressed chunk size
  CompSize    : longword; // compressed chunk size
 end;
 // The data is compressed with usual zlib

implementation

uses AnimED_Graphics;

                           
procedure IG_YURIS_YCG;
begin
 with ImFormat do begin
  Name := '[PNG] YU-RIS YCG';
  Ext  := '.png';
  Stat := $F;
  Open := Import_YURIS_YCG;
  Save := nil;
  Ver  := $20140826;
 end;
end;

function Import_YURIS_YCG(InputStream, OutputStream : TStream; OutputStreamA : TStream = nil) : TRFI;
var RFI   : TRFI;
    Hdr   : TYURISYCGHdr;
    i,j   : longword;
    Chunk : array of TYURISYCGChunk;
    tmpStream, tmpStream2 : TStream;
begin
 RFI.Valid := False;

 with InputStream do begin
  Seek(0,soBeginning);

  Read(Hdr,SizeOf(Hdr));

  j := SizeOf(Hdr)+SizeOf(TYURISYCGChunk)*Hdr.NumOfChunks; // offset for data

  with Hdr do begin

   if Magic <> 'YCG'#0 then Exit; // sanity check

   RFI.RealWidth    := Width;
   RFI.RealHeight   := Height;
   RFI.BitDepth     := BitDepth;
   RFI.ExtAlpha     := True;
   RFI.X            := 0;
   RFI.Y            := 0;
   RFI.RenderWidth  := 0;
   RFI.RenderHeight := 0;
   RFI.Palette      := NullPalette; // if BitDepth > 8 then ignored

   if IsChunked = 1 then begin // check if the image contain chunks

    SetLength(Chunk,NumOfChunks);

    for i := 0 to NumOfChunks-1 do begin

     Read(Chunk[i],SizeOf(TYURISYCGChunk));

    end;

    tmpStream2 := TMemoryStream.Create;

    for i := 1 to NumOfChunks do begin

     Seek(j,soBeginning);
     tmpStream := TMemoryStream.Create;
     tmpStream.CopyFrom(InputStream,Chunk[i-1].CompSize);
     tmpStream.Seek(0,soBeginning);

     ZDecompressStream(tmpStream,tmpStream2);

     j := j + Chunk[i-1].CompSize; // adding to start offset for the next chunk

     FreeAndNil(tmpStream);

    end;

    tmpStream2.Seek(0,soBeginning);
    VerticalFlip(tmpStream2,GetScanlineLen2(Width,BitDepth),Height);
    tmpStream2.Seek(0,soBeginning);
    { Copies alpha channel into separate non-interleaved stream and strips it from base stream }
    if ((BitDepth > 24) and (OutputStreamA <> nil)) then begin
     { Cleanup of the stream - fixes 32-bit image loading }
     OutputStream.Size := 0;
     { ---end }
     ExtractAlpha(tmpStream2,OutputStreamA,Width,Height);
     StripAlpha(tmpStream2,OutputStream,Width,Height);
     RFI.BitDepth := 24;

     RFI.Valid        := True;
    end else OutputStream.CopyFrom(tmpStream,tmpStream.Size);

   end else LogE('Non-chunked YU-RIS images are not implemented. Please supply AE VN Tools maintainer with your copy of this image so it could be implemented!');
   
  end;

 end;

 Result := RFI;
end;

end.