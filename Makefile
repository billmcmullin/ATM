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

.PHONY: clean all build-tests test compile coverage

# If COVERAGE=1 is set (by command line or recursive make), add instrumentation flags
ifeq ($(COVERAGE),1)
	CFLAGS += --coverage -O0
	LDFLAGS += --coverage
	GTEST_LIBS = -lgtest -lgtest_main $(LDFLAGS)
endif

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

# Coverage target: builds instrumented binaries, runs tests, captures and reports coverage.
# Usage: make coverage
# This target will:
#  - clean
#  - rebuild with coverage instrumentation
#  - run unit tests and generate Google Test XML under coverage/gtest-results.xml
#  - collect coverage via lcov and generate HTML under coverage/html
coverage:
	@echo "=== Building instrumented binaries for coverage ==="
	$(MAKE) clean
	$(MAKE) build-tests COVERAGE=1
	@echo "=== Running tests (generating gtest XML) ==="
	mkdir -p coverage
	# run tests and produce google-test XML; don't fail the make if tests fail
	./$(TEST_BIN) --gtest_output=xml:coverage/gtest-results.xml || true
	@echo "=== Capturing coverage with lcov ==="
	# capture coverage data (searches . and subdirs for .gcda/.gcno)
	lcov --capture --directory . --output-file coverage/coverage.info
	# remove system files and third-party paths (adjust patterns as needed)
	lcov --remove coverage/coverage.info '/usr/*' '*/gtest/*' --output-file coverage/coverage.info
	@echo "=== Generating HTML report ==="
	genhtml coverage/coverage.info --output-directory coverage/html
	@echo "Coverage report generated at coverage/html/index.html"

clean:
	rm -rf $(OBJ_DIR) $(GTEST_BUILD_DIR) $(TEST_BIN) $(PROD_LIB) coverage *.info

