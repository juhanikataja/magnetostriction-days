SET(CMAKE_C_COMPILER "gcc" CACHE STRING "")
SET(CMAKE_CXX_COMPILER "g++" CACHE STRING "")
SET(CMAKE_Fortran_COMPILER "gfortran" CACHE STRING "")
#SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "")

SET(CMAKE_CXX_FLAGS "-std=c++11" CACHE STRING "")

SET(CMAKE_CXX_FLAGS_DEBUG "-g -fbacktrace -fsanitize=leak -fsanitize=address -fsanitize=bounds"
  CACHE STRING "")
SET(CMAKE_C_FLAGS_DEBUG "-g -fbacktrace -fsanitize=leak -fsanitize=address -fsanitize=bounds"
  CACHE STRING "")
SET(CMAKE_Fortran_FLAGS_DEBUG "-g -fbacktrace -fsanitize=leak -fsanitize=address -fsanitize=bounds -ffpe-trap=invalid,zero,overflow"
  CACHE STRING "")

SET(WITH_Hypre TRUE CACHE BOOL "")
#SET(Hypre_INCLUDE_DIR "$ENV{HOME}/opt/hypre/2.11.1/include" CACHE PATH "")
SET(WITH_Mumps TRUE CACHE BOOL "")
SET(RESET_ELMER_REVISION TRUE CACHE BOOL "") 
# SET(WITH_Trilinos FALSE CACHE BOOL "")
# SET(TRILINOS_PATH "$ENV{TRILINOS_PATH}" CACHE PATH "")
# SET(WITH_CONTRIB TRUE CACHE BOOL "")
SET(WITH_OpenMP TRUE CACHE BOOL "")

SET(WITH_ELMERPOST FALSE CACHE BOOl "")

# SuperLU
# SET(WITH_SuperLU TRUE CACHE BOOL "")
# SET(SuperLU_PATH "$ENV{HOME}/opt/superlu/5.2.1" CACHE PATH "")

# BLAS/lapack
SET(BLAS_LIBRARIES "/usr/lib/libblas.so" CACHE FILE "")
SET(LAPACK_LIBRARIES "/usr/lib/liblapack.so" CACHE FILE "")

# mpiexec becomes the one bundled with paraview for some reason
SET(MPIEXEC "/usr/bin/mpiexec" CACHE FILE "")
# set(WITH_Trilinos TRUE CACHE BOOL "")
# set(TRILINOS_PATH "/home/jkataja/opt/Trilinos/12.12.1" CACHE PATH "")
SET(WITH_LUA FALSE CACHE BOOL "")
