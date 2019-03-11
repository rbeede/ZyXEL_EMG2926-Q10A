/*add for lzma function prototype and definitions*/

#include "Types.h"

SRes Encode(void *inFile, FILE *outFile);
int Decode(FILE *inFile, void *outFile);
int MySetFileLength(int length);
UInt64 GetUnpackSize(FILE *inFile);
SRes FileEncode(FILE *inFile, FILE *outFile);
int FileDecode(FILE *inFile, FILE *outFile);
