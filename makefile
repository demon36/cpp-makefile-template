CC := g++
SRC_DIR := ./src
OBJ_DIR := ./obj
INC_DIR := ./include
BIN_DIR := ./bin
LIB_DIR := ./lib
DEP_DIR := ./dep
TESTS_DIR := ./test
PROJECT_NAME := $(shell basename $(CURDIR))
MAJOR_VERSION := 0
MINOR_VERSION := 1.9

SRC_FILES := $(shell find $(SRC_DIR) -name '*.cpp')
OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/$(SRC_DIR)/%.o,$(SRC_FILES))
TEST_SRC_FILES := $(shell find $(TESTS_DIR) -name '*.cpp')
TEST_OBJ_FILES := $(patsubst $(TESTS_DIR)/%.cpp,$(OBJ_DIR)/$(TESTS_DIR)/%.o,$(TEST_SRC_FILES))

#rename to SO_PATH
SO_FILE := $(LIB_DIR)/$(PROJECT_NAME).so.$(MAJOR_VERSION).$(MINOR_VERSION)
A_FILE := $(LIB_DIR)/$(PROJECT_NAME).a.$(MAJOR_VERSION).$(MINOR_VERSION)
EXEC_FILE := $(BIN_DIR)/$(PROJECT_NAME)
TEST_FILE := $(BIN_DIR)/main_test

CFLAGS := -Wall -Wconversion -Werror -g -std=c++11 -I$(INC_DIR)
LIBS := #ex: -lthirdpary
LIB_LDFLAGS := -shared -Wl,-zdefs,-soname,$(PROJECT_NAME).so.$(MAJOR_VERSION),-rpath,'$$ORIGIN'
EXEC_LD_FLAGS := -Wl,-rpath,'$$ORIGIN/lib:$$ORIGIN/dep:$$ORIGIN/../$(LIB_DIR)'
all: shared test

coverage: CVRG := --coverage
coverage: all run
	lcov --quiet -c --directory . --output-file $(OBJ_DIR)/.info --no-external
	genhtml --quiet $(OBJ_DIR)/.info --output-directory html
	xdg-open ./html/index.html

shared: $(SO_FILE)
static: $(A_FILE)
exec: $(EXEC_FILE)
test: $(TEST_FILE)
run: test
	$(TEST_FILE)

$(OBJ_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(@D) $(DEP_DIR)/$(<D)
	$(CC) $(CFLAGS) $(CVRG) -fPIC -c -o $@ $< -MMD -MF $(DEP_DIR)/$<.dep

$(OBJ_DIR)/$(TESTS_DIR)/%.o: $(TESTS_DIR)/%.cpp
	@mkdir -p $(@D) $(DEP_DIR)/$(<D)
	$(CC) $(CFLAGS) $(CVRG) -c -o $@ $< -MMD -MF $(DEP_DIR)/$<.dep

$(SO_FILE): $(OBJ_FILES)
	@mkdir -p $(@D)
	$(CC) $(CVRG) -g -o $(SO_FILE) $^ $(LIB_LDFLAGS) $(LIBS)
	ln -sf ./$(PROJECT_NAME).so.$(MAJOR_VERSION) $(SO_FILE)

$(A_FILE): $(OBJ_FILES)
	@mkdir -p $(@D)
	ar rcs $@ $^
	ln -sf ./$(PROJECT_NAME).a.$(MAJOR_VERSION) $(A_FILE)

$(EXEC_FILE): $(OBJ_FILES)
	@mkdir -p $(@D)
	$(CC) $(CVRG) -g $? -o $@ $(LIBS)

$(TEST_FILE): $(TEST_OBJ_FILES)
	@mkdir -p $(@D)
	$(eval EXEC_LIBS := $(shell find \( -name "$(PROJECT_NAME).a.$(MAJOR_VERSION)" -o -name "$(PROJECT_NAME).so.$(MAJOR_VERSION)" \)))
	$(CC) $(CVRG) -g $^ -o $@ $(EXEC_LD_FLAGS) $(LIBS) -L$(LIB_DIR) $(EXEC_LIBS) 

.PHONY: init all coverage shared static exec run clean

init:
	$(shell mkdir -p $(SRC_DIR) $(INC_DIR) $(OBJ_DIR) $(BIN_DIR) $(LIB_DIR) $(DEP_DIR) $(TESTS_DIR))

clean:
	#todo: delete only relevant files
	rm -rf $(OBJ_DIR)/* $(LIB_DIR)/* $(BIN_DIR)/* $(DEP_DIR)/*

-include  $(shell find $(DEP_DIR) -name '*.dep')

#todo: make tests depend on shared/static lib
#todo: handle version in the linux conventional way
#todo: add section for other makefile deps
#todo: support pkg-config
#todo: support ARCH=all BUILD=all
#todo: delete binaries + symlinks at clean up
#todo: should exec and test be merged ?