CC=g++
SRC_DIR := ./src
OBJ_DIR := ./build
INC_DIR := ./include
BIN_DIR := ./bin
LIB_DIR := ./lib
DEP_DIR := ./dep
TESTS_DIR := ./test
MAIN_TEST := $(BIN_DIR)/main_test
CVRG_INFO := ./coverage.info
LIB_NAME := $(shell basename $(CURDIR))

SRC_FILES := $(shell find $(SRC_DIR) -name '*.cpp')
OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/$(SRC_DIR)/%.o,$(SRC_FILES))
TEST_SRC_FILES := $(shell find $(TESTS_DIR) -name '*.cpp')
TEST_OBJ_FILES := $(patsubst $(TESTS_DIR)/%.cpp,$(OBJ_DIR)/$(TESTS_DIR)/%.o,$(TEST_SRC_FILES))
LIB_FILE := lib$(LIB_NAME).so

CFLAGS := -w -Wall -g -std=c++11 -I$(INC_DIR)
LIBS := #ex: -lthirdpary
EXEC_LIBS := -L$(LIB_DIR) -l$(LIB_NAME)
VERSION := 0.1
LIB_LDFLAGS := -shared -Wl,-zdefs,-soname,lib$(LIB_NAME).so.$(VERSION)
BIN_LDFLAGS := -Wl,-rpath='$$ORIGIN/../lib'

init:
	$(shell mkdir -p $(SRC_DIR) $(INC_DIR) $(OBJ_DIR) $(BIN_DIR) $(LIB_DIR) $(DEP_DIR) $(TESTS_DIR))

all: $(LIB_NAME) $(MAIN_TEST)

allcvrg: CVRG := --coverage
allcvrg: clean all test
	# gcov $(MAIN_TEST) --object-directory $(OBJ_DIR) --relative-only
	# lcov -c --directory . --output-file $(CVRG_INFO) --no-external
	# genhtml --quiet $(CVRG_INFO) --output-directory html
	# xdg-open ./html/index.html

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
	$(CC) $(CVRG) -g $? -o $@ $(BIN_LDFLAGS) $(EXEC_LIBS) $(LIBS)

$(LIB_NAME): $(OBJ_FILES)
	$(CC) $(CVRG) -g -o $(LIB_DIR)/$(LIB_FILE).$(VERSION) $^ $(LIB_LDFLAGS) $(LIBS)
	ln -sf ./$(LIB_FILE).$(VERSION) $(LIB_DIR)/$(LIB_FILE)

.PHONY: all clean allcvrg test

clean:
	rm -rf $(OBJ_DIR)/* $(LIB_DIR)/* $(BIN_DIR)/* $(DEP_DIR)/* ./*.gcno ./*.gcda $(CVRG_INFO)

-include  $(shell find $(SRC_DIR) -name '*.dep')
