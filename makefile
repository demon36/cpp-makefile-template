CC := g++
SRC_DIR := ./src
OBJ_DIR := ./build
INC_DIR := ./include
BIN_DIR := ./bin
LIB_DIR := ./lib
DEP_DIR := ./dep
TESTS_DIR := ./test
MAIN_TEST := $(BIN_DIR)/main_test
CVRG_INFO := $(OBJ_DIR)/coverage.info
LIB_NAME := $(shell basename $(CURDIR))

SRC_FILES := $(shell find $(SRC_DIR) -name '*.cpp')
OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/$(SRC_DIR)/%.o,$(SRC_FILES))
TEST_SRC_FILES := $(shell find $(TESTS_DIR) -name '*.cpp')
TEST_OBJ_FILES := $(patsubst $(TESTS_DIR)/%.cpp,$(OBJ_DIR)/$(TESTS_DIR)/%.o,$(TEST_SRC_FILES))
LIB_FILE := $(LIB_DIR)/lib$(LIB_NAME).so

CFLAGS := -w -Wall -g -std=c++11 -I$(INC_DIR)
LIBS := #ex: -lthirdpary
EXEC_LIBS := -L$(LIB_DIR) -l$(LIB_NAME)
VERSION := 0.1
LIB_LDFLAGS := -shared -Wl,-zdefs,-soname,lib$(LIB_NAME).so.$(VERSION)
BIN_LDFLAGS := -Wl,-rpath='$$ORIGIN/../lib'

all: $(LIB_FILE) $(MAIN_TEST)

coverage: CVRG := --coverage
coverage: clean all test
	# gcov $(MAIN_TEST) --object-directory $(OBJ_DIR) --relative-only
	lcov --quiet -c --directory . --output-file $(CVRG_INFO) --no-external
	genhtml --quiet $(CVRG_INFO) --output-directory html
	xdg-open ./html/index.html

test: $(MAIN_TEST)
	$(MAIN_TEST)

$(OBJ_DIR)/$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(@D) $(DEP_DIR)/$(<D)
	$(CC) $(CFLAGS) $(CVRG) -fPIC -c -o $@ $< -MMD -MF $(DEP_DIR)/$<.dep

$(OBJ_DIR)/$(TESTS_DIR)/%.o: $(TESTS_DIR)/%.cpp
	@mkdir -p $(@D) $(DEP_DIR)/$(<D)
	$(CC) $(CFLAGS) $(CVRG) -c -o $@ $< -MMD -MF $(DEP_DIR)/$<.dep

#TODO: handle static lib generation
#TODO: handle if project is binary type not lib
$(MAIN_TEST): $(TEST_OBJ_FILES)
	@mkdir -p $(@D)
	$(CC) $(CVRG) -g $? -o $@ $(BIN_LDFLAGS) $(EXEC_LIBS) $(LIBS)

$(LIB_FILE): $(OBJ_FILES)
	@mkdir -p $(@D)
	$(CC) $(CVRG) -g -o $(LIB_FILE).$(VERSION) $^ $(LIB_LDFLAGS) $(LIBS)
	ln -sf $(CURDIR)/$(LIB_FILE).$(VERSION) $(LIB_FILE)

.PHONY: init all clean coverage test

init:
	$(shell mkdir -p $(SRC_DIR) $(INC_DIR) $(OBJ_DIR) $(BIN_DIR) $(LIB_DIR) $(DEP_DIR) $(TESTS_DIR))

clean:
	rm -rf $(OBJ_DIR)/* $(LIB_DIR)/* $(BIN_DIR)/* $(DEP_DIR)/*

-include  $(shell find $(SRC_DIR) -name '*.dep')
