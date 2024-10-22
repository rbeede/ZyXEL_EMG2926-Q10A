/* LzmaUtil.c -- Test application for LZMA compression
2008-08-05
Igor Pavlov
public domain */

/*modify by penny for CCC RDM compress*/
#define _CRT_SECURE_NO_WARNINGS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "LzmaDec.h"
#include "LzmaEnc.h"
#include "Alloc.h"

const char *kCantReadMessage = "Can not read input file";
const char *kCantWriteMessage = "Can not write output file";
const char *kCantAllocateMessage = "Can not allocate memory";
const char *kDataErrorMessage = "Data error";

static void *SzAlloc(void *p, size_t size) { p = p; return MyAlloc(size); }
static void SzFree(void *p, void *address) {  p = p; MyFree(address); }
static ISzAlloc g_Alloc = { SzAlloc, SzFree };
static int memOffset = 0;
static int fileSize = 0;

#define kInBufferSize (1 << 15)
#define kOutBufferSize (1 << 15)

unsigned char g_InBuffer[kInBufferSize];
unsigned char g_OutBuffer[kOutBufferSize];

size_t MyReadPtr(void *file, void *data, size_t size)
  {
	int s = 0;
	if (fileSize > size){
		s = size;
		fileSize -= size;
	}
	else{
		s = fileSize;
		fileSize = 0;
	}
	
	memcpy(data, file + memOffset, s);
	memOffset += s;
		
	
  	return s; }
size_t MyReadFile(FILE *file, void *data, size_t size)
  {
  return fread(data, 1, size, file); }

int MyReadFileAndCheck(FILE *file, void *data, size_t size)
  { return (MyReadFile(file, data, size) == size); }

size_t MyWriteFile(FILE *file, const void *data, size_t size)
{
  if (size == 0)
    return 0;
  return fwrite(data, 1, size, file);
}

size_t MyWriteToPtr(void *file, const void *data, size_t size)
{
  if (size == 0)
    return 0;
  memcpy(file + memOffset, data, size);
  memOffset += size;
  
  return size;
}

int MyWriteFileAndCheck(FILE *file, const void *data, size_t size)
  { return (MyWriteFile(file, data, size) == size); }

long MyGetFileLength(FILE *file)
{
  long length;
  fseek(file, 0, SEEK_END);
  length = ftell(file);
  fseek(file, 0, SEEK_SET);
  return length;
}

long MyGetPtrFileLength(void *file)
{
  long length;
//  fseek(file, 0, SEEK_END);
//  length = ftell(file);
//  fseek(file, 0, SEEK_SET);
	length = fileSize;
  return length;
}

int MySetFileLength(int length)
{
	/*set Share memory size*/
	fileSize = length;

  return 0;
}

int PrintError(const char *message)
{
	printf( "%s(): %s\n", __FUNCTION__, message);
	return 1;
}

#define IN_BUF_SIZE (1 << 16)
#define OUT_BUF_SIZE (1 << 16)

UInt64 GetUnpackSize(FILE *inFile)
{
  UInt64 unpackSize;
  /*any possibility that thereIsSize == 0??*/
  int thereIsSize; /* = 1, if there is uncompressed size in headers */
  int i;
 
  /* header: 5 bytes of LZMA properties and 8 bytes of uncompressed size */
  unsigned char header[LZMA_PROPS_SIZE + 8];

  /* Read and parse header */

  if (!MyReadFileAndCheck(inFile, header, sizeof(header)))
    return PrintError(kCantReadMessage);

  unpackSize = 0;
  thereIsSize = 0;
  for (i = 0; i < 8; i++)
  {
    unsigned char b = header[LZMA_PROPS_SIZE + i];
    if (b != 0xFF)
      thereIsSize = 1;

	printf("%s(): GetUnpackSize b:%x\n", __FUNCTION__, b);
    unpackSize += (UInt64)b << (i * 8);
  }

  return unpackSize;
}

int Decode(FILE *inFile, void *outFile)
{
  UInt64 unpackSize;
  int thereIsSize; /* = 1, if there is uncompressed size in headers */
  int i;
  int res = 0;
  
  CLzmaDec state;

  /* header: 5 bytes of LZMA properties and 8 bytes of uncompressed size */
  unsigned char header[LZMA_PROPS_SIZE + 8];
  memOffset = 0;

  /* Read and parse header */

  if (!MyReadFileAndCheck(inFile, header, sizeof(header)))
    return PrintError(kCantReadMessage);

  unpackSize = 0;
  thereIsSize = 0;
  for (i = 0; i < 8; i++)
  {
    unsigned char b = header[LZMA_PROPS_SIZE + i];
    if (b != 0xFF)
      thereIsSize = 1;
    unpackSize += (UInt64)b << (i * 8);
  }

  LzmaDec_Construct(&state);
  res = LzmaDec_Allocate(&state, header, LZMA_PROPS_SIZE, &g_Alloc);
  if (res != SZ_OK)
    return res;
  {
    Byte inBuf[IN_BUF_SIZE];
    Byte outBuf[OUT_BUF_SIZE];
    size_t inPos = 0, inSize = 0, outPos = 0;
    LzmaDec_Init(&state);
    for (;;)
    {
      if (inPos == inSize)
      {
        inSize = MyReadFile(inFile, inBuf, IN_BUF_SIZE);
        inPos = 0;
      }
      {
        SizeT inProcessed = inSize - inPos;
        SizeT outProcessed = OUT_BUF_SIZE - outPos;
        ELzmaFinishMode finishMode = LZMA_FINISH_ANY;
        ELzmaStatus status;
        if (thereIsSize && outProcessed > unpackSize)
        {
          outProcessed = (SizeT)unpackSize;
          finishMode = LZMA_FINISH_END;
        }
        res = LzmaDec_DecodeToBuf(&state, outBuf + outPos, &outProcessed,
            inBuf + inPos, &inProcessed, finishMode, &status);
        inPos += (UInt32)inProcessed;
        outPos += outProcessed;
        unpackSize -= outProcessed;

        if (outFile != 0)
          MyWriteToPtr(outFile, outBuf, outPos);
        outPos = 0;

        if ((res != SZ_OK) || (thereIsSize && unpackSize == 0))
          break;

        if (inProcessed == 0 && outProcessed == 0)
        {
          if (thereIsSize || status != LZMA_STATUS_FINISHED_WITH_MARK)
            res = SZ_ERROR_DATA;
          break;
        }
      }
    }
  }

  LzmaDec_Free(&state, &g_Alloc);
  return res;
}

int FileDecode(FILE *inFile, FILE *outFile)
{
  UInt64 unpackSize;
  int thereIsSize; /* = 1, if there is uncompressed size in headers */
  int i;
  int res = 0;
  
  CLzmaDec state;

  /* header: 5 bytes of LZMA properties and 8 bytes of uncompressed size */
  unsigned char header[LZMA_PROPS_SIZE + 8];
  memOffset = 0;

  /* Read and parse header */

  if (!MyReadFileAndCheck(inFile, header, sizeof(header)))
    return PrintError(kCantReadMessage);

  unpackSize = 0;
  thereIsSize = 0;
  for (i = 0; i < 8; i++)
  {
    unsigned char b = header[LZMA_PROPS_SIZE + i];
    if (b != 0xFF)
      thereIsSize = 1;
    unpackSize += (UInt64)b << (i * 8);
  }

  LzmaDec_Construct(&state);
  res = LzmaDec_Allocate(&state, header, LZMA_PROPS_SIZE, &g_Alloc);
  if (res != SZ_OK)
    return res;
  {
    Byte inBuf[IN_BUF_SIZE];
    Byte outBuf[OUT_BUF_SIZE];
    size_t inPos = 0, inSize = 0, outPos = 0;
    LzmaDec_Init(&state);
    for (;;)
    {
      if (inPos == inSize)
      {
        inSize = MyReadFile(inFile, inBuf, IN_BUF_SIZE);
        inPos = 0;
      }
      {
        SizeT inProcessed = inSize - inPos;
        SizeT outProcessed = OUT_BUF_SIZE - outPos;
        ELzmaFinishMode finishMode = LZMA_FINISH_ANY;
        ELzmaStatus status;
        if (thereIsSize && outProcessed > unpackSize)
        {
          outProcessed = (SizeT)unpackSize;
          finishMode = LZMA_FINISH_END;
        }
        res = LzmaDec_DecodeToBuf(&state, outBuf + outPos, &outProcessed,
            inBuf + inPos, &inProcessed, finishMode, &status);
        inPos += (UInt32)inProcessed;
        outPos += outProcessed;
        unpackSize -= outProcessed;

        if (outFile != 0)
          MyWriteFile(outFile, outBuf, outPos);
        outPos = 0;

        if ((res != SZ_OK) || (thereIsSize && unpackSize == 0))
          break;

        if (inProcessed == 0 && outProcessed == 0)
        {
          if (thereIsSize || status != LZMA_STATUS_FINISHED_WITH_MARK)
            res = SZ_ERROR_DATA;
          break;
        }
      }
    }
  }

  LzmaDec_Free(&state, &g_Alloc);
  return res;
}

typedef struct _CPtrSeqInStream
{
  ISeqInStream funcTable;
  void *file;
} CPtrSeqInStream;

typedef struct _CFileSeqInStream
{
  ISeqInStream funcTable;
  FILE *file;
} CFileSeqInStream;

static SRes MyReadFromPtr(void *p, void *buf, size_t *size)
{
  if (*size == 0)
    return SZ_OK;
  *size = MyReadPtr(((CPtrSeqInStream*)p)->file, buf, *size);
  /*
  if (*size == 0)
    return SZE_FAIL;
  */
  return SZ_OK;
}

static SRes MyRead(void *p, void *buf, size_t *size)
{
  if (*size == 0)
    return SZ_OK;
  *size = MyReadFile(((CFileSeqInStream*)p)->file, buf, *size);
  /*
  if (*size == 0)
    return SZE_FAIL;
  */
  return SZ_OK;
}

typedef struct _CFileSeqOutStream
{
  ISeqOutStream funcTable;
  FILE *file;
} CFileSeqOutStream;

static size_t MyWrite(void *pp, const void *buf, size_t size)
{
  return MyWriteFile(((CFileSeqOutStream *)pp)->file, buf, size);
}

SRes Encode(void *inFile, FILE *outFile)
{
  CLzmaEncHandle enc;
  SRes res;
  CPtrSeqInStream inStream;
  CFileSeqOutStream outStream;
  CLzmaEncProps props;

  memOffset = 0;
  enc = LzmaEnc_Create(&g_Alloc);
  if (enc == 0)
    return SZ_ERROR_MEM;

  inStream.funcTable.Read = MyReadFromPtr;
  inStream.file = inFile;
  outStream.funcTable.Write = MyWrite;
  outStream.file = outFile;

  LzmaEncProps_Init(&props);
  res = LzmaEnc_SetProps(enc, &props);
  if (res == SZ_OK)
  {
    Byte header[LZMA_PROPS_SIZE + 8];
    size_t headerSize = LZMA_PROPS_SIZE;
    UInt64 fileSize;
    int i;
//	char tmp;

    res = LzmaEnc_WriteProperties(enc, header, &headerSize);
    fileSize = MyGetPtrFileLength(inFile);

	printf("%s(): Encode fileSize:%llu\n", __FUNCTION__, fileSize);
    for (i = 0; i < 8; i++){
//	  tmp = (Byte)(fileSize >> (8 * i));
      header[headerSize++] = (Byte)(fileSize >> (8 * i));
	}
	
    if (!MyWriteFileAndCheck(outFile, header, headerSize))
      return PrintError("writing error");

    if (res == SZ_OK)
      res = LzmaEnc_Encode(enc, &outStream.funcTable, &inStream.funcTable,
        NULL, &g_Alloc, &g_Alloc);
  }
  LzmaEnc_Destroy(enc, &g_Alloc, &g_Alloc);
  return res;
}

SRes FileEncode(FILE *inFile, FILE *outFile)
{
  CLzmaEncHandle enc;
  SRes res;
  CFileSeqInStream inStream;
  CFileSeqOutStream outStream;
  CLzmaEncProps props;

  memOffset = 0;
  enc = LzmaEnc_Create(&g_Alloc);
  if (enc == 0)
    return SZ_ERROR_MEM;

  inStream.funcTable.Read = MyRead;
  inStream.file = inFile;
  outStream.funcTable.Write = MyWrite;
  outStream.file = outFile;

  LzmaEncProps_Init(&props);
  res = LzmaEnc_SetProps(enc, &props);
  if (res == SZ_OK)
  {
    Byte header[LZMA_PROPS_SIZE + 8];
    size_t headerSize = LZMA_PROPS_SIZE;
    UInt64 fileSize;
    int i;
//	char tmp;

    res = LzmaEnc_WriteProperties(enc, header, &headerSize);
    fileSize = MyGetFileLength(inFile);

	printf("%s(): Encode fileSize:%llu\n", __FUNCTION__, fileSize);
    for (i = 0; i < 8; i++){
//	  tmp = (Byte)(fileSize >> (8 * i));
      header[headerSize++] = (Byte)(fileSize >> (8 * i));
	}
	
    if (!MyWriteFileAndCheck(outFile, header, headerSize))
      return PrintError("writing error");

    if (res == SZ_OK)
      res = LzmaEnc_Encode(enc, &outStream.funcTable, &inStream.funcTable,
        NULL, &g_Alloc, &g_Alloc);
  }
  LzmaEnc_Destroy(enc, &g_Alloc, &g_Alloc);
  return res;
}
#if 0
int main2(int numArgs, const char *args[], char *rs)
{
  FILE *inFile = 0;
  FILE *outFile = 0;
  char c;
  int res;
  int encodeMode;
  struct stat buf1;
  int file_size = 0;
  char *ptr;

  if (numArgs == 1)
  {
    PrintHelp(rs);
    return 0;
  }

  if (numArgs < 3 || numArgs > 4 || strlen(args[1]) != 1)
    return PrintUserError(rs);

  c = args[1][0];
  encodeMode = (c == 'e' || c == 'E');
  if (!encodeMode && c != 'd' && c != 'D')
    return PrintUserError(rs);

  {
    size_t t4 = sizeof(UInt32);
    size_t t8 = sizeof(UInt64);
    if (t4 != 4 || t8 != 8)
      return PrintError(rs, "LZMA UTil needs correct UInt32 and UInt64");
  }

  inFile = fopen(args[2], "rb");
  if (inFile == 0)
    return PrintError(rs, "Can not open input file");
  

  if (numArgs > 3)
  {
    outFile = fopen(args[3], "wb+");
    if (outFile == 0)
      return PrintError(rs, "Can not open output file");
  }
  else if (encodeMode)
    PrintUserError(rs);

  if (encodeMode)
  {
  	stat(args[2], &buf1);
  	fileSize = file_size = buf1.st_size;
  	printf("fileSize:%d\r\n", fileSize);
  	ptr = malloc(file_size);
  	fread(ptr, 1, file_size, inFile);
  	fclose(inFile);

  	inFile = fopen(args[2], "rb");
  	if (inFile == 0)
    	return PrintError(rs, "11Can not open input file");  
  
    res = Encode(ptr, outFile, rs);
	free(ptr);
  }
  else
  {
  	fileSize = GetUnpackSize(inFile, rs);
	printf("Decode fileSize :%d\r\n", fileSize);
	fclose(inFile);
	
  	inFile = fopen(args[2], "rb");
  	if (inFile == 0)
    	return PrintError(rs, "Can not open input file");

	ptr = malloc(fileSize);
	
    res = Decode(inFile, ptr, rs);
	printf("Decode res :%d\r\n", res);
	fwrite(ptr, 1 , fileSize, outFile);
	free(ptr);

  }
  

  if (outFile != 0)
    fclose(outFile);
  fclose(inFile);

  if (res != SZ_OK)
  {
    if (res == SZ_ERROR_MEM)
      return PrintError(rs, kCantAllocateMessage);
    else if (res == SZ_ERROR_DATA)
      return PrintError(rs, kDataErrorMessage);
    else
      return PrintErrorNumber(rs, res);
  }
  return 0;
}

int MY_CDECL main(int numArgs, const char *args[])
{
FILE *File = 0;
char test[256];
  char rs[800] = { 0 };
  int res = main2(numArgs, args, rs);
  printf(rs);

  File = fopen("/home/penny/tmp/ccc/core/librdm/test", "rb");
  
  fread(&test, 1, 2, File);
  printf("test0:%x\r\n", test[0]);
  printf("test1:%x\r\n", test[1]);

  fread(&test, 1, 2, File);
  printf("test2:%x\r\n", test[0]);
  printf("test3:%x\r\n", test[1]);

  fclose(File);
  
  return res;
}

#endif
