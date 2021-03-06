!******************************************************************************
!*           Material model plugin for Elmer's MagnetoStriction.f90           *
!*                                                                            *
!*                 This file is part of 'elmer-mgs-galfenol'                  *
!******************************************************************************

!***************************************************
! This file is manually implemented, do not delete!
!***************************************************

! Adaptor for Elmer. This is the interface expected by MagnetoStriction.f90.
! 
! Here e actually denotes the Cauchy strain ε.
! 
! This version uses the global polynomial model, mgs_poly.f90.

! Elmer uses engineering shear strains γij = 2 εij in part of the solution process
! in the linear elastic solver, but this part is not one of them. The mgs_* routines
! get the actual strain εij.

subroutine mgs_H(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, h_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:3, 1:1) :: h_out
  REAL(KIND=dp) :: eps12, eps23, eps13
  call H_public(B1, B2, B3, e11, e12, e22, e23, e13, e33, h_out)
end subroutine

subroutine mgs_dHdB(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, dhdb_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:3, 1:3) :: dhdb_out
  REAL(KIND=dp) :: eps12, eps23, eps13
  call dH_dB_public(B1, B2, B3, e11, e12, e22, e23, e13, e33, dhdb_out)
end subroutine

subroutine mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:3, 1:3) :: sigma_out
  REAL(KIND=dp) :: eps12, eps23, eps13
  integer :: i, j
  call S_public(B1, B2, B3, e11, e12, e22, e23, e13, e33, sigma_out)
  ! This scaling comes from the energy-based model. We have:
  !   psi = epsxy sigxy + epsyx sigyx + (terms that don't depend on xy strain)
  ! 
  ! The above is correct, **for the energy**. Because depsyx/depsxy = 0, this yields
  !   dpsi/depsxy = sigxy
  ! 
  ! which is what we want. But OTOH, by symmetry,
  !   psi = 2 epsxy sigxy + (other terms)
  ! 
  ! This is actually what we have in the model. Now we will have
  !   dpsi/depsxy = 2 sigxy
  ! 
  ! so we have to halve the stress output from the model.
  ! FIXME: fix this in the model instead: don't assume epsilon is symmetric until everything is done.
  do i = 1, 3
    do j = 1, 3
      if (j .ne. i) then
        sigma_out(i, j) = sigma_out(i, j) / 2d0
      end if
    end do
  end do
end subroutine

subroutine mgs_dSde(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, dsde_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:9, 1:9) :: dsde_out
  REAL(KIND=dp) c1, c2
  INTEGER :: n, m
  ! These index packing constants come from mgs_physfields.f90.
  integer, parameter :: i11 = 1
  integer, parameter :: i21 = 2
  integer, parameter :: i31 = 3
  integer, parameter :: i12 = 4
  integer, parameter :: i22 = 5
  integer, parameter :: i32 = 6
  integer, parameter :: i13 = 7
  integer, parameter :: i23 = 8
  integer, parameter :: i33 = 9
  call dS_deps_public(B1, B2, B3, dsde_out)
  ! Convert the shear-related entries of ∂σij/∂εkl.
  do n = 1, 9    ! packed index of σij
    if (n == i11 .or. n == i22 .or. n == i33) then
      c1 = 1d0
    else
      c1 = 2d0
    end if
    do m = 1, 9  ! packed index of εkl
      if (m == i11 .or. m == i22 .or. m == i33) then
        c2 = 1d0
      else
        c2 = 2d0
      end if
      dsde_out(n, m) = dsde_out(n, m) / (c1 * c2)
    end do
  end do
end subroutine

