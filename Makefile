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

# Parasoft tooling placeholders (override on command line or edit here)
# Example:
#   make coverage CPPT_COMPILER_WRAPPER=/opt/parasoft/cpptest/bin/cpptest_wrapper \
#                CPPT_REPORT_TOOL=/opt/parasoft/cpptest/bin/cpptest_report
CPPT_COMPILER_WRAPPER ?= /opt/parasoft/cpptest/bin/cpptest_wrapper
CPPT_REPORT_TOOL ?= /opt/parasoft/cpptest/bin/cpptest_report
# If your Parasoft tool requires additional args (project location, credentials etc.)
CPPT_REPORT_ARGS ?=

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

# Coverage target:
# - If the Parasoft compiler wrapper & report tool exist and are executable, use Parasoft flow.
# - Otherwise, fall back to lcov/genhtml coverage collection.
coverage:
	@echo "=== Coverage: checking for Parasoft tooling at $(CPPT_COMPILER_WRAPPER) and $(CPPT_REPORT_TOOL) ==="
	@if [ -x "$(CPPT_COMPILER_WRAPPER)" ] && [ -x "$(CPPT_REPORT_TOOL)" ]; then \
		echo "Parasoft compiler wrapper and report tool found."; \
		echo "=== Rebuilding with Parasoft instrumentation ==="; \
		$(MAKE) clean; \
		# Rebuild using Parasoft compiler wrapper (override CC/CXX for the recursive make)
		CC="$(CPPT_COMPILER_WRAPPER)" CXX="$(CPPT_COMPILER_WRAPPER)" $(MAKE) build-tests; \
		echo "=== Running unit tests ==="; \
		mkdir -p coverage; \
		./$(TEST_BIN) --gtest_output=xml:coverage/gtest-results-parasoft.xml || true; \
		echo "=== Invoking Parasoft report/collector tool ==="; \
		$(CPPT_REPORT_TOOL) $(CPPT_REPORT_ARGS) --input coverage/gtest-results-parasoft.xml --output coverage/parasoft || true; \
		echo "Parasoft coverage collection complete (see coverage/parasoft or Parasoft reports)"; \
	else \
		echo "Parasoft tooling not found or not executable at $(CPPT_COMPILER_WRAPPER) / $(CPPT_REPORT_TOOL). Falling back to lcov."; \
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
	rm -rf $(OBJ_DIR) $(GTEST_BUILD_DIR) $(TEST_BIN) $(PROD_LIB) coverage *.info
