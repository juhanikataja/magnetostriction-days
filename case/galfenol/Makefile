FC?=/usr/bin/gfortran 

FFLAGS=-fopenmp -DCONTIG=,CONTIGUOUS -DHAVE_EXECUTECOMMANDLINE -DUSE_ISO_C_BINDINGS -DUSE_ARPACK -O2 -g -DNDEBUG -fPIC -I$(ELMER_HOME)/share/elmersolver/include -L$(ELMER_HOME)/lib/elmersolver -lelmersolver 
# the above are from running `elmerf90`

all: galfenol.so hb

mgs-container.o: mgs-container.F90 ./generated/mgs_poly.f90 ./generated/mgs_poly_impl.f90
	$(FC) $(FFLAGS) mgs-container.F90 -c -o mgs-container.o

mgs_plugin.o: mgs_plugin.f90
	$(FC) $(FFLAGS) $^ -c -o $@

galfenol.so: mgs-container.o mgs_plugin.o 
	$(FC) $^ -shared -o $@

hb: mgs-container.o hb.F90
	$(FC) $(FFLAGS) $^ -o hb

se: mgs-container.o se.F90
	$(FC) $(FFLAGS) $^ -o se

