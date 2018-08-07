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

subroutine mgs_H(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, h_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:3, 1:1) :: h_out
  call H_public(B1, B2, B3, e11, e12, e22, e23, e13, e33, h_out)
end subroutine

subroutine mgs_dHdB(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, dhdb_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:3, 1:3) :: dhdb_out
  call dH_dB_public(B1, B2, B3, e11, e12, e22, e23, e13, e33, dhdb_out)
end subroutine

subroutine mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, sigma_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:3, 1:3) :: sigma_out
  call S_public(B1, B2, B3, e11, e12, e22, e23, e13, e33, sigma_out)
end subroutine

subroutine mgs_dSde(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33, dsde_out)
  use types
  use MgsContainer
  implicit none
  REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
  REAL(KIND=dp), intent(out), dimension(1:9, 1:9) :: dsde_out
  call dS_deps_public(B1, B2, B3, dsde_out)
end subroutine

