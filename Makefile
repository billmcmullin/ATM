CC=g++
INCLUDE_FLAGS=-Iinclude
DEBUG_FLAGS=
CFLAGS=-g
LDFLAGS=-pthread
GTEST_LIBS=-lgtest -lgtest_main $(LDFLAGS)
OBJ_DIR=obj

OBJ = $(OBJ_DIR)/ATM.o \
	  $(OBJ_DIR)/Bank.o \
	  $(OBJ_DIR)/BaseDisplay.o \
	  $(OBJ_DIR)/Account.o

GTEST_DIR = gtest
GTEST_BUILD_DIR = $(GTEST_DIR)/obj
GTEST_SRCS = $(wildcard $(GTEST_DIR)/*.cxx)
GTEST_OBJS = $(patsubst $(GTEST_DIR)/%.cxx,$(GTEST_BUILD_DIR)/%.o,$(GTEST_SRCS))
TEST_BIN = unit_tests

PROD_LIB = ATM.a

.PHONY: clean all build-tests test compile

all : $(OBJ_DIR) $(OBJ)

# New target: compile production code and create a static archive
# Usage: make compile
compile: $(PROD_LIB)

$(PROD_LIB): $(OBJ)
	ar rcs $@ $^

$(OBJ_DIR) :
	mkdir -p $(OBJ_DIR)

$(GTEST_BUILD_DIR) :
	mkdir -p $(GTEST_BUILD_DIR)

$(OBJ_DIR)/%.o : %.cxx | $(OBJ_DIR)
	$(CC) $(CFLAGS) $(INCLUDE_FLAGS) -o $@ -c $<

# compile test objects
$(GTEST_BUILD_DIR)/%.o: $(GTEST_DIR)/%.cxx | $(GTEST_BUILD_DIR)
	$(CC) $(CFLAGS) $(INCLUDE_FLAGS) -o $@ -c $<

# Build & link the test binary (links production objects + test objects)
$(TEST_BIN): $(OBJ) $(GTEST_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(GTEST_LIBS)

# Convenience target: build tests (compile + link) but do not run them
build-tests: $(TEST_BIN)

# Run the unit tests (builds first if needed)
test: build-tests
	./$(TEST_BIN)

clean:
	rm -rf $(OBJ_DIR) $(GTEST_BUILD_DIR) $(TEST_BIN) $(PROD_LIB)