program se
use types
use mgscontainer
implicit none
real(kind=dp) :: S_se(3,3), dSde_se(9,9), C(6,6)
real(kind=dp) :: lam_, mu_, E_, nu_, coeff, d1, d2, coeff1, coeff2, coeff3, ss

integer :: n
character(len=80) :: myformat 

myformat = "(ES13.3,ES13.3,ES13.3)"

! e = [((1.0d0*n/1000d0), n=1,1000)]

! Bx By Bz exx exy eyy exz eyz ezz output   DANGER: mathematician's shear strain
!call S_public(0d0, 0d0, 0d0, 1d0, 0d0, 0d0, 0d0, 0d0, 0d0, S_se)

! mgs_S from mgs_plugin does the shear strain scalings for Elmer compatibility.

!       mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
call mgs_S(0d0, 0d0, 0d0, 1d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, S_se)
print *, "stress at unit xx axial strain"
do n = 1, 3
  print myformat, S_se(:, n)
end do

!       mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
call mgs_S(0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 1d0, 0d0, 0d0, 0d0, 0d0, S_se)
print *, "stress at unit yy axial strain"
do n = 1, 3
  print myformat, S_se(:, n)
end do

!       mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
call mgs_S(0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 1d0, S_se)
print *, "stress at unit zz axial strain"
do n = 1, 3
  print myformat, S_se(:, n)
end do

!       mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
call mgs_S(0d0, 0d0, 0d0, 0d0, 1d0, 0d0, 1d0, 0d0, 0d0, 0d0, 0d0, 0d0, S_se)
print *, "stress at unit xy shear strain"
do n = 1, 3
  print myformat, S_se(:, n)
end do

!       mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
call mgs_S(0d0, 0d0, 0d0, 0d0, 0d0, 1d0, 0d0, 0d0, 0d0, 1d0, 0d0, 0d0, S_se)
print *, "stress at unit xz shear strain"
do n = 1, 3
  print myformat, S_se(:, n)
end do

!       mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
call mgs_S(0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 1d0, 0d0, 1d0, 0d0, S_se)
print *, "stress at unit yz shear strain"
do n = 1, 3
  print myformat, S_se(:, n)
end do

! Lamé parameters, hardcoded into the material model
lam_ = lam_public()
mu_ = mu_public()

! https://en.wikipedia.org/wiki/Lam%C3%A9_parameters
E_  = mu_ * (3d0 * lam_ + 2d0 * mu_) / (lam_ + mu_)
nu_ = lam_ / (2d0 * (lam_ + mu_))
print *, "E, nu from model", E_, nu_
print *, "reference values", 75d9, 0.4

! http://www.efunda.com/formulae/solid_mechanics/mat_mechanics/hooke_isotropic.cfm
coeff = E_ / ((1d0 + nu_) * (1d0 - 2d0*nu_))
d1 = coeff * (1d0 - nu_)
d2 = coeff * nu_

print *, "coeffs from model", d1, d2

coeff1 = S_se(1,1)
coeff2 = S_se(1,2)
coeff3 = S_se(3,3)  ! σzz
print *, "coeffs in array", coeff1, coeff2, coeff3

! see elmerfem/src/Stress.F90, subroutine StressCompose
C = 0
C(1,1) = coeff * (1d0-nu_)
C(1,2) = coeff * nu_
C(1,3) = coeff * nu_
C(2,1) = coeff * nu_
C(2,2) = coeff * (1d0-nu_)
C(2,3) = coeff * nu_
C(3,1) = coeff * nu_
C(3,2) = coeff * nu_
C(3,3) = coeff * (1d0-nu_)
do n = 4,6
!  C(n,n) = coeff * (1d0-2*nu_)
  C(n,n) = coeff * 0.5*(1d0-2*nu_)  ! to match Stress.F90
end do

!call dS_deps_public(0d0, 0d0, 0d0, dSde_se)
call mgs_dSde(0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, dSde_se)

!   integer, parameter :: i11 = 1
!   integer, parameter :: i21 = 2
!   integer, parameter :: i31 = 3
!   integer, parameter :: i12 = 4
!   integer, parameter :: i22 = 5
!   integer, parameter :: i32 = 6
!   integer, parameter :: i13 = 7
!   integer, parameter :: i23 = 8
!   integer, parameter :: i33 = 9

!                     1    2    3    4    5    6    7    8    9
! dsde(1,:) = dsxx./[ dexx deyx dezx dexy deyy dezy dexz deyz dezz]
print *, "testing dSde c(1,1,1,1)", dSde_se(1,1)
print *, "C(1,1)", C(1,1)
print *, "testing dSde c(1,1,2,2)", dSde_se(1,5)
print *, "C(1,2)", C(1,2)
print *, "testing dSde c(1,1,3,3)", dSde_se(1,9)
print *, "C(1,3)", C(1,3)
print *, "testing dSxy/dexy, dSyx/deyx", dSde_se(4,4), dSde_se(2,2)
print *, "C(6,6)", C(6,6)

! shear stiffness in the xy plane
ss = coeff * (1d0 - 2d0*nu_)
print *, "theoretical", ss
print *, "from array ", dSde_se(2, 2), dSde_se(2, 4), dSde_se(4, 2), dSde_se(4, 4)  ! should be same, by symmetries

print *, "theoretical"
myformat = "(ES13.3,ES13.3,ES13.3,ES13.3,ES13.3,ES13.3)"
do n = 1, 6
  print myformat, C(n,:)
end do

print *, "from array, in Voigt format"
myformat = "(ES13.3,ES13.3,ES13.3,ES13.3,ES13.3,ES13.3)"  ! 11 22 33 12 13 23
print myformat, dSde_se(1,1), dSde_se(1,5), dSde_se(1,9), dSde_se(1,4), dSde_se(1,8), dSde_se(1,7)
print myformat, dSde_se(5,1), dSde_se(5,5), dSde_se(5,9), dSde_se(5,4), dSde_se(5,8), dSde_se(5,7)
print myformat, dSde_se(9,1), dSde_se(9,5), dSde_se(9,9), dSde_se(9,4), dSde_se(9,8), dSde_se(9,7)
print myformat, dSde_se(4,1), dSde_se(4,5), dSde_se(4,9), dSde_se(4,4), dSde_se(4,8), dSde_se(4,7)
print myformat, dSde_se(8,1), dSde_se(8,5), dSde_se(8,9), dSde_se(8,4), dSde_se(8,8), dSde_se(8,7)
print myformat, dSde_se(7,1), dSde_se(7,5), dSde_se(7,9), dSde_se(7,4), dSde_se(7,8), dSde_se(7,7)

print *, "from array, raw packed"
myformat = "(ES13.3,ES13.3,ES13.3,ES13.3,ES13.3,ES13.3,ES13.3,ES13.3,ES13.3)"
do n = 1, 9
  print myformat, dSde_se(n,:)
end do

end program

