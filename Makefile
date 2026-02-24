CC=g++
INCLUDE_FLAGS=-Iinclude
DEBUG_FLAGS=
CFLAGS=-g
OBJ_DIR=obj

OBJ = $(OBJ_DIR)/ATM.o \
	  $(OBJ_DIR)/Bank.o \
	  $(OBJ_DIR)/BaseDisplay.o \
	  $(OBJ_DIR)/Account.o

.PHONY = clean all
	
all : $(OBJ_DIR) $(OBJ)

$(OBJ_DIR) :
	mkdir $(OBJ_DIR)

$(OBJ_DIR)/%.o : %.cxx
	$(CC) $(CFLAGS) $(INCLUDE_FLAGS) -o $@ -c $^ 

clean:
	rm -rf $(OBJ_DIR)
