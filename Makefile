CXX ?= g++
CPPFLAGS += -I.
CXXFLAGS += -std=c++14 -Wall -O3

# Implicit linking is done with cc
LDLIBS += -lstdc++

BISON ?= bison
BISONFLAGS += -Wall,error

FLEX ?= flex
FLEXFLAGS +=

VPATH = src

####################

EXE = whenever-cpp

# Generated files
GEN_SRC = parse.cc scan.cc
GEN_HDR = parse.hh stack.hh
GEN = $(GEN_SRC) $(GEN_HDR)

SOURCES = $(GEN_SRC) $(EXE).cc
OBJECTS = $(SOURCES:.cc=.o)
HEADERS = $(GEN_HDR)

####################

all: $(EXE)

%.cc %.hh: %.yy
	$(BISON) $(BISONFLAGS) -o $*.cc $^ --defines=$*.hh

%.cc: %.ll
	$(FLEX) $(FLEXFLAGS) -o $@ $^

$(EXE).o: parse.hh

$(EXE): $(OBJECTS)

neat:
	$(RM) $(GEN)
	$(RM) $(OBJECTS)

clean: neat
	$(RM) $(EXE)

.PHONY: all clean neat
