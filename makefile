CC := g++
ARCH :=$(shell getconf LONG_BIT)
BUILD := debug
SRC_DIR := ./src
OBJ_DIR := ./obj/$(ARCH)/$(BUILD)
INC_DIR := ./include
BIN_DIR := ./bin/$(ARCH)/$(BUILD)
LIB_DIR := ./lib/$(ARCH)/$(BUILD)
DEP_DIR := ./dep
COV_REPORTS_DIR := ./cov
DOCS_DIR := ./docs
TEST_SRC_DIR := ./test
TEST_BIN_DIR := ./bin/test/$(ARCH)
PROJECT_NAME := $(shell basename $(CURDIR))
MAJOR_VERSION := 0
MINOR_VERSION := 1.9

SRC_FILES := $(shell find $(SRC_DIR) -regex '.*\.\(c\|cc\|cpp\|cxx\)')
OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/$(SRC_DIR)/%.o,$(SRC_FILES))
TEST_SRC_FILES := $(shell find $(TEST_SRC_DIR) -regex '.*\.\(c\|cc\|cpp\|cxx\)')
TEST_OBJ_FILES := $(patsubst $(TEST_SRC_DIR)/%.cpp,$(OBJ_DIR)/$(TEST_SRC_DIR)/%.o,$(TEST_SRC_FILES))

SO_FILE := $(PROJECT_NAME).so.$(MAJOR_VERSION).$(MINOR_VERSION)
SO_LN_FILE := $(PROJECT_NAME).so.$(MAJOR_VERSION)
A_FILE := $(PROJECT_NAME).a.$(MAJOR_VERSION).$(MINOR_VERSION)
A_LN_FILE := $(PROJECT_NAME).a.$(MAJOR_VERSION)
EXEC_FILE := $(PROJECT_NAME)
TEST_FILE := main_test

CFLAGS := -m$(ARCH) -Wall -Wconversion -Werror -g -std=c++11 -I$(INC_DIR)
CFLAGS_DEBUG := -DDEBUG
CFLAGS_RELEASE := -O3
LIBS := #ex: -lthirdpary
LIB_LDFLAGS :=  -m$(ARCH) -shared -Wl,-zdefs,-soname,$(SO_LN_FILE),-rpath,'$$ORIGIN'
EXEC_LD_FLAGS := -m$(ARCH) -Wl,-rpath,'$$ORIGIN/lib:$$ORIGIN/dep:$$ORIGIN/../../../$(LIB_DIR)'

ifeq ($(BUILD),debug)
	CFLAGS += $(CFLAGS_DEBUG)
else ifeq ($(BUILD),release)
	CFLAGS += $(CFLAGS_RELEASE)
	SO_DBG_FILE := $(SO_FILE).dbg
	A_DBG_FILE := $(A_FILE).dbg
	EXEC_DBG_FILE := $(EXEC_FILE).dbg
endif

all: shared test

coverage: CVRG := --coverage
coverage: all run
	lcov --quiet -c --directory . --output-file $(OBJ_DIR)/.info --no-external
	genhtml --quiet $(OBJ_DIR)/.info --output-directory $(COV_REPORTS_DIR)
	xdg-open $(COV_REPORTS_DIR)/index.html

shared: $(LIB_DIR)/$(SO_FILE) $(LIB_DIR)/$(SO_DBG_FILE)
static: $(LIB_DIR)/$(A_FILE) $(LIB_DIR)/$(A_DBG_FILE)
exec: $(BIN_DIR)/$(EXEC_FILE) $(BIN_DIR)/$(EXEC_DBG_FILE)
test: $(TEST_BIN_DIR)/$(TEST_FILE)
run: test
	$(TEST_BIN_DIR)/$(TEST_FILE)

$(OBJ_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(@D) $(DEP_DIR)/$(<D)
	$(CC) $(CFLAGS) $(CVRG) -fPIC -c -o $@ $< -MMD -MF $(DEP_DIR)/$<.dep

$(OBJ_DIR)/$(TEST_SRC_DIR)/%.o: $(TEST_SRC_DIR)/%.cpp
	@mkdir -p $(@D) $(DEP_DIR)/$(<D)
	$(CC) $(CFLAGS) $(CVRG) -c -o $@ $< -MMD -MF $(DEP_DIR)/$<.dep

$(LIB_DIR)/$(SO_FILE): $(OBJ_FILES)
	@mkdir -p $(@D)
	$(CC) $(CVRG) -g -o $@ $^ $(LIB_LDFLAGS) $(LIBS)
	ln -sf ./$(SO_FILE) $(LIB_DIR)/$(SO_LN_FILE)

$(LIB_DIR)/$(A_FILE): $(OBJ_FILES)
	@mkdir -p $(@D)
	ar rcs $@ $^
	ln -sf ./$(A_FILE) $(LIB_DIR)/$(A_LN_FILE)

$(BIN_DIR)/$(EXEC_FILE): $(OBJ_FILES)
	@mkdir -p $(@D)
	$(CC) $(CVRG) -g $? -o $@ $(LIBS)

%.dbg: %
	objcopy --only-keep-debug $< $@
	objcopy --strip-unneeded $< $<

$(TEST_BIN_DIR)/$(TEST_FILE): $(TEST_OBJ_FILES)
	@mkdir -p $(@D)
	$(eval EXEC_LIBS := $(shell find \( -name "$(SO_LN_FILE)" -o -name "$(A_LN_FILE)" \)))
	$(CC) $(CVRG) -g $^ -o $@ $(EXEC_LD_FLAGS) $(LIBS) -L$(LIB_DIR) -l:$(EXEC_LIBS) 

.PHONY: init all coverage shared static exec run clean

init:
	$(shell mkdir -p $(SRC_DIR) $(INC_DIR) $(OBJ_DIR) $(BIN_DIR) $(LIB_DIR) $(DEP_DIR) $(TEST_SRC_DIR) $(TEST_BIN_DIR) $(DOCS_DIR))

clean:
	rm -f $(OBJ_FILES) $(TEST_OBJ_FILES) $(LIB_DIR)/$(SO_FILE) $(LIB_DIR)/$(SO_FILE).dbg $(LIB_DIR)/$(SO_LN_FILE) $(LIB_DIR)/$(A_FILE) $(LIB_DIR)/$(A_FILE).dbg $(LIB_DIR)/$(A_LN_FILE) $(BIN_DIR)/$(EXEC_FILE) $(BIN_DIR)/$(EXEC_FILE).dbg $(TEST_BIN_DIR)/$(TEST_FILE)

-include  $(shell find $(DEP_DIR) -name '*.dep')/

#todo: make tests depend on shared/static lib
#todo: add section for other makefile deps
#todo: support pkg-config
#todo: replace blind test linking
#todo: support excluding source files from build
#todo: support making a test for an executable project 
