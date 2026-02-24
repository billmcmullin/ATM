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

# Parasoft coverage integration variables (adjust as needed)
# cpptestcc must be on PATH or provide full path:
CPPT_COMPILER ?= cpptestcc
# Example flags: -compiler <compiler-id> -line-coverage -workspace <path-to-workspace> --
# Note: ensure CPPT_WORKSPACE is writable by the build user
CPPT_WORKSPACE ?= $(shell pwd)/parasoft_workspace
CPPT_COMPILER_FLAGS ?= -compiler gcc_9-64 -line-coverage -workspace $(CPPT_WORKSPACE) --
# Path to Parasoft runtime library to append to link (override if installed elsewhere)
CPPT_COV_LIB ?= /opt/parasoft/cpptest/runtime/lib/cpptest.a

.PHONY: clean all build-tests test compile coverage

all : $(OBJ_DIR) $(OBJ)

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

# Coverage target using Parasoft cpptestcc integration (per Parasoft docs)
# If cpptestcc is available, this will:
#  - clean
#  - rebuild using cpptestcc as the CXX wrapper (instrumentation)
#  - ensure the Parasoft runtime library is linked by appending CPPT_COV_LIB to LDFLAGS
#  - run unit tests (test results are produced; coverage data is written into the Parasoft workspace)
# If cpptestcc is not available, fallback to lcov-based coverage (requires lcov & genhtml).
coverage:
	@echo "=== Coverage: checking for Parasoft cpptestcc ($(CPPT_COMPILER)) ==="
	@if command -v $(CPPT_COMPILER) >/dev/null 2>&1 ; then \
		echo "Parasoft cpptestcc found."; \
		echo "=== Preparing Parasoft workspace: $(CPPT_WORKSPACE) ==="; \
		mkdir -p $(CPPT_WORKSPACE); \
		echo "=== Rebuilding with Parasoft instrumentation (CXX overridden) ==="; \
		$(MAKE) clean; \
		# Use cpptestcc as the compiler wrapper. The CXX variable is overridden for the recursive make.
		CXX="$(CPPT_COMPILER) $(CPPT_COMPILER_FLAGS) g++" LDFLAGS="$(LDFLAGS) $(CPPT_COV_LIB)" $(MAKE) build-tests; \
		echo "=== Running instrumented unit tests (coverage data will be stored in Parasoft workspace) ==="; \
		mkdir -p coverage; \
		./$(TEST_BIN) --gtest_output=xml:coverage/gtest-results-parasoft.xml || true; \
		echo "Parasoft coverage instrumentation complete. Coverage data and workspace files are in $(CPPT_WORKSPACE)."; \
	else \
		echo "Parasoft cpptestcc not found. Falling back to lcov."; \
		$(MAKE) clean; \
		echo "=== Building instrumented binaries for lcov ==="; \
		$(MAKE) build-tests COVERAGE=1 CFLAGS="--coverage -O0 -g" LDFLAGS="--coverage"; \
		echo "=== Running tests (generating gtest XML) ==="; \
		mkdir -p coverage; \
		./$(TEST_BIN) --gtest_output=xml:coverage/gtest-results.xml || true; \
		echo "=== Capturing coverage with lcov ==="; \
		lcov --quiet --capture --directory . --output-file coverage/coverage.info; \
		lcov --quiet --remove coverage/coverage.info '/usr/*' '*/gtest/*' --output-file coverage/coverage.info; \
		echo "=== Generating HTML report ==="; \
		genhtml coverage/coverage.info --output-directory coverage/html || true; \
		echo "LCOV coverage report generated at coverage/html/index.html"; \
	fi

clean:
	rm -rf $(OBJ_DIR) $(GTEST_BUILD_DIR) $(TEST_BIN) $(PROD_LIB) coverage $(CPPT_WORKSPACE) *.info