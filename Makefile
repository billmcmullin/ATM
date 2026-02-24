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
# Set CPPT_COMPILER to the full path of cpptestcc on your Jenkins agent if not on PATH.
CPPT_COMPILER ?= cpptestcc
CPPT_WORKSPACE ?= $(shell pwd)/parasoft_workspace
CPPT_COMPILER_FLAGS ?= -compiler gcc_9-64 -line-coverage -workspace $(CPPT_WORKSPACE) --
# If your Parasoft installation requires linking an additional runtime library, set CPPT_COV_LIB.
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

# Coverage target using Parasoft C/C++test instrumentation only (no lcov fallback).
# This target fails if cpptestcc is not found.
coverage:
	@echo "=== Coverage: checking for Parasoft cpptestcc ($(CPPT_COMPILER)) ==="; \
	if command -v "$(CPPT_COMPILER)" >/dev/null 2>&1; then \
		echo "Parasoft cpptestcc found."; \
		echo "Preparing Parasoft workspace: $(CPPT_WORKSPACE)"; \
		mkdir -p "$(CPPT_WORKSPACE)"; \
		echo "Cleaning previous build artifacts"; \
		$(MAKE) clean; \
		echo "Rebuilding with Parasoft instrumentation (overriding CC/CXX)"; \
		CC="$(CPPT_COMPILER) $(CPPT_COMPILER_FLAGS) g++" CXX="$(CPPT_COMPILER) $(CPPT_COMPILER_FLAGS) g++" LDFLAGS="$(LDFLAGS) $(CPPT_COV_LIB)" $(MAKE) build-tests; \
		echo "Running instrumented unit tests (coverage data will be written into Parasoft workspace)"; \
		mkdir -p coverage; \
		./$(TEST_BIN) --gtest_output=xml:coverage/gtest-results-parasoft.xml || true; \
		echo "Parasoft coverage instrumentation complete. Inspect workspace at: $(CPPT_WORKSPACE)"; \
	else \
		echo "ERROR: Parasoft cpptestcc not found at '$(CPPT_COMPILER)'. Please install Parasoft C/C++test or set CPPT_COMPILER to the cpptestcc path."; \
		exit 1; \
	fi

clean:
	rm -rf $(OBJ_DIR) $(GTEST_BUILD_DIR) $(TEST_BIN) $(PROD_LIB) coverage $(CPPT_WORKSPACE) *.info