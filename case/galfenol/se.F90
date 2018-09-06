program se
use types
use mgscontainer
implicit none
real(kind=dp) :: e(1000), S_se(3,3), dSde_se(9,9)
real(kind=dp) :: lam_, mu_, E_, nu_, coeff, d1, d2, coeff1, coeff2

integer :: n

e = [((1.0d0*n/1000d0), n=1,1000)]

do n = 1,1000
  ! Bx By Bz exx exy eyy exz eyz ezz output
  call S_public(0d0, 0d0, 0d0, e(n), 0d0, 0d0, 0d0, 0d0, 0d0, S_se)
  print *, e(n), S_se(1,1)
end do

! Lamé parameters, hardcoded into the material model
lam_ = lam_public()
mu_ = mu_public()

! https://en.wikipedia.org/wiki/Lam%C3%A9_parameters
E_  = mu_ * (3d0 * lam_ + 2d0 * mu_) / (lam_ + mu_)
nu_ = lam_ / (2d0 * (lam_ + mu_))
print *, "E, nu from model", E_, nu_

! http://www.efunda.com/formulae/solid_mechanics/mat_mechanics/hooke_isotropic.cfm
coeff = E_ / ((1d0 + nu_) * (1d0 - 2d0*nu_))
d1 = coeff * (1d0 - nu_)
d2 = coeff * nu_
print *, "coeffs from model", d1, d2

coeff1 = S_se(1,1)
coeff2 = S_se(1,2)
print *, "coeffs in array", coeff1, coeff2

call dS_deps_public(0d0, 0d0, 0d0, dSde_se)
print *, "testing dSde", dSde_se(1,1)

end program
