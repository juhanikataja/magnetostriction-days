!******************************************************************************
!*           Material model plugin for Elmer's MagnetoStriction.f90           *
!*                                                                            *
!*                 This file is part of 'elmer-mgs-galfenol'                  *
!******************************************************************************

!***************************************************
! This file is manually implemented, do not delete!
!***************************************************

! Do not compact the format of the intent declarations. The rudimentary parser
! in the stage2 code generator only understands this one-item-per-line format.
! (This format is also produced by SymPy.)
!
! This file contains essentially additional, user-defined stage1 functions
! and subroutines.
!
! These routines implement H, ∂H/∂B, σ, and ∂σ/∂ε in terms of partial derivatives
! of the potential ϕ. These are needed in the material model for Elmer's
! MagnetoStriction.f90. An adaptor is needed to fit the interface, because
! we cannot here control the ordering of the formal parameter list produced
! by stage2 for the public API.
!
! For more information, see the implementation file.

! H = -∂ϕ/∂B
interface
subroutine H(dphi_dBx, dphi_dBy, dphi_dBz,
             H_out)
use types
implicit none
REAL(KIND=dp), intent(in) :: dphi_dBx
REAL(KIND=dp), intent(in) :: dphi_dBy
REAL(KIND=dp), intent(in) :: dphi_dBz
REAL(KIND=dp), intent(out), dimension(1:3, 1:1) :: H_out
end subroutine
end interface

interface
subroutine dH_dB(d2phi_dBx2, d2phi_dBy2, d2phi_dBz2,
                 d2phi_dBxdBy, d2phi_dBxdBz, d2phi_dBydBz,
                 dH_dB_out)
use types
implicit none
REAL(KIND=dp), intent(in) :: d2phi_dBx2
REAL(KIND=dp), intent(in) :: d2phi_dBy2
REAL(KIND=dp), intent(in) :: d2phi_dBz2
REAL(KIND=dp), intent(in) :: d2phi_dBxdBy
REAL(KIND=dp), intent(in) :: d2phi_dBxdBz
REAL(KIND=dp), intent(in) :: d2phi_dBydBz
REAL(KIND=dp), intent(out), dimension(1:3, 1:3) :: dH_dB_out
end subroutine
end interface

! σ = +∂ϕ/∂ε
interface
subroutine S(dphi_depsxx, dphi_depsyy, dphi_depszz,
             dphi_depsyz, dphi_depszx, dphi_depsxy,
             S_out)
use types
implicit none
REAL(KIND=dp), intent(in) :: dphi_depsxx
REAL(KIND=dp), intent(in) :: dphi_depsyy
REAL(KIND=dp), intent(in) :: dphi_depszz
REAL(KIND=dp), intent(in) :: dphi_depsyz
REAL(KIND=dp), intent(in) :: dphi_depszx
REAL(KIND=dp), intent(in) :: dphi_depsxy
REAL(KIND=dp), intent(out), dimension(1:3, 1:3) :: S_out
end subroutine
end interface

interface
subroutine dS_deps(d2phi_depsxx2, d2phi_depsyy2, d2phi_depszz2,
                   d2phi_depsyz2, d2phi_depszx2, d2phi_depsxy2,
                   d2phi_depsxxdepsxy, d2phi_depsxxdepsyy,
                   d2phi_depsxxdepsyz, d2phi_depsxxdepszx,
                   d2phi_depsxxdepszz,
                   d2phi_depsxydepsyy, d2phi_depsxydepsyz,
                   d2phi_depsxydepszx, d2phi_depsxydepszz,
                   d2phi_depsyydepsyz, d2phi_depsyydepszx,
                   d2phi_depsyydepszz,
                   d2phi_depsyzdepszx, d2phi_depsyzdepszz,
                   d2phi_depszxdepszz,
                   dS_deps_out)
use types
implicit none
REAL(KIND=dp), intent(in) :: d2phi_depsxx2
REAL(KIND=dp), intent(in) :: d2phi_depsyy2
REAL(KIND=dp), intent(in) :: d2phi_depszz2
REAL(KIND=dp), intent(in) :: d2phi_depsyz2
REAL(KIND=dp), intent(in) :: d2phi_depszx2
REAL(KIND=dp), intent(in) :: d2phi_depsxy2
REAL(KIND=dp), intent(in) :: d2phi_depsxxdepsxy
REAL(KIND=dp), intent(in) :: d2phi_depsxxdepsyy
REAL(KIND=dp), intent(in) :: d2phi_depsxxdepsyz
REAL(KIND=dp), intent(in) :: d2phi_depsxxdepszx
REAL(KIND=dp), intent(in) :: d2phi_depsxxdepszz
REAL(KIND=dp), intent(in) :: d2phi_depsxydepsyy
REAL(KIND=dp), intent(in) :: d2phi_depsxydepsyz
REAL(KIND=dp), intent(in) :: d2phi_depsxydepszx
REAL(KIND=dp), intent(in) :: d2phi_depsxydepszz
REAL(KIND=dp), intent(in) :: d2phi_depsyydepsyz
REAL(KIND=dp), intent(in) :: d2phi_depsyydepszx
REAL(KIND=dp), intent(in) :: d2phi_depsyydepszz
REAL(KIND=dp), intent(in) :: d2phi_depsyzdepszx
REAL(KIND=dp), intent(in) :: d2phi_depsyzdepszz
REAL(KIND=dp), intent(in) :: d2phi_depszxdepszz
REAL(KIND=dp), intent(out), dimension(1:9, 1:9) :: dS_deps_out
end subroutine
end interface

