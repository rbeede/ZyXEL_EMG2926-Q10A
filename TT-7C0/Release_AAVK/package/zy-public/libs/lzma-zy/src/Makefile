
LZMALIBOBJ = LzmaEnc.o LzmaDec.o LzFind.o LzmaUtil.o
LZMAOBJ = LzmaMain.o
TARGET = targetlzma
TARGET_LIB = libtargetlzma.so
### Implicit rules ###
.c.o:
	$(CC) -c -fPIC $(CFLAGS) $(INC_PATH) $< -o $@

all: $(TARGET) $(TARGET_LIB)
	@echo "###################################"
	@echo "#             LZMA"
	@echo "#        Build up successfully"
	@echo "###################################"
	
$(TARGET): $(LZMALIBOBJ) $(LZMAOBJ)
	$(CC) -Wall $(LZMALIBOBJ) $(LZMAOBJ) -L./ $(LIB_PATH) -o $@

$(TARGET_LIB): $(LZMALIBOBJ)
	$(CC) -shared -o $@ $(LZMALIBOBJ)

clean:
	rm -rf $(LZMALIBOBJ) $(LZMAOBJ)
	rm -rf $(TARGET) $(TARGET_LIB)
	
