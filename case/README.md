# Magnetostriction test case

## Contents

* Magnetostrictive material model (Reijo Kouhia, Anouar Belahcen, Katarzyna Fonteyn, Paavo Rasilo)
  * See also [https://github.com/TUTElectromechanics/mm-codegen](mm-codegen) which generates the Fortran code from symbolic definitions given in Python (Juha Jeronen)
* Test mesh `MStest` (Ugur Aydin, Sabin Sathyan)
* Parametric test geometry `geom/galfenol_test.geo`, can be used with Gmsh to make a mesh (Juha Jeronen, Juhani Kataja, Paavo Rasilo)
* Magnetostrictive coupling solvers (Juhani Kataja, Sabin Sathyan)
    * Based on Elmer's MagnetoDynamics and StressSolve solvers

# Usage:

* Download this package somewhere.
* If you didn't yet follow the instructions in the main README, do so now:
  * In `elmerfem/fem/src/modules` in Elmer's source tree, create a symlink `MagnetoStriction` pointing to the `../MagnetoStriction` directory of this package.
  * Compile Elmer, obtaining (among other files) `MagnetoStriction.so`.
* In this directory (`case`) of this package, create a symlink `MagnetoStriction.so` pointing to your `elmer-install/share/elmersolver/lib/MagnetoStriction.so`.
* Compile the material model plugin, in `galfenol/`, with `make`.
  * Optionally can compile small test programs by `make hb`, `make se`.
* run `ElmerSolver galfenol.sif`.

# Hacking:

* If you want to change the material parameters or the model, look at mm-codegen.
* If you change something in `../MagnetoStriction`, recompile Elmer. 

# Disclaimer:

Results might not be physical
