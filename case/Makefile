OBJ_SUFFIX=so
SOBJS=MagnetoStriction.$(OBJ_SUFFIX)
SIF_FILES=ms2.sif ms2-ref.sif casedefs.sif outputvars.sif ms2names.sif
DATA_FILES=MStest/mesh.* BH mgs-codegen/HB_8_4_3
SOURCE_FILES=$(wildcard *.F90) Makefile
FILELIST=$(DATA_FILES) $(SIF_FILES) $(SOURCE_FILES)
MGS_SOURCES=$(wildcard ./mgs-codegen/*.f90) mgs-codegen/Makefile
FC=elmerf90
DATE=$(shell date +%Y-%m-%d)
#######################

all: $(SOBJS)
	make -C mgs-codegen install

MagnetoStriction.$(OBJ_SUFFIX): MagnetoStriction.o mgdyn.o mgs-StressSolve.o mgs-Stress.o 
	$(FC) $^ -o $@

%.o: %.F90
	$(FC) -c $< -o $@

mgs-StressSolve.o: mgs-Stress.o

clean:
	rm -f *.o $(SOBJS) *.mod *.$(OBJ_SUFFIX)
	make -C mgs-codegen clean
