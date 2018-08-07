OBJ_SUFFIX=so
SRCS:=$(wildcard *.f90)
OBJS:=$(subst .f90,.$(OBJ_SUFFIX),$(SRCS))
INSTALL_OBJS:=$(patsubst %,../%,$(OBJS))

%.$(OBJ_SUFFIX): %.f90
	elmerf90 $< -o $@

../%.$(OBJ_SUFFIX): %.$(OBJ_SUFFIX)
	cp $< $@

all: $(OBJS)

install: $(INSTALL_OBJS)

clean: 
	rm *.$(OBJ_SUFFIX)
