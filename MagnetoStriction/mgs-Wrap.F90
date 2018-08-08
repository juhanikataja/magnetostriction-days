!/*****************************************************************************/
! *
! *  Elmer, A Finite Element Software for Multiphysical Problems
! *
! *  Copyright 1st April 1995 - , CSC - IT Center for Science Ltd., Finland
! *
! *  This program is free software; you can redistribute it and/or
! *  modify it under the terms of the GNU General Public License
! *  as published by the Free Software Foundation; either version 2
! *  of the License, or (at your option) any later version.
! *
! *  This program is distributed in the hope that it will be useful,
! *  but WITHOUT ANY WARRANTY; without even the implied warranty of
! *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! *  GNU General Public License for more details.
! *
! *  You should have received a copy of the GNU General Public License
! *  along with this program (in file fem/GPL-2); if not, write to the
! *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
! *  Boston, MA 02110-1301, USA.
! *
! *****************************************************************************/
!
!/******************************************************************************
! *
! *  Authors: Juhani Kataja
! *  Email:   juhani.kataja@csc.fi
! *  Web:     http://www.csc.fi/elmer
! *  Address: CSC - IT Center for Science Ltd.
! *           Keilaranta 14
! *           02101 Espoo, Finland
! *
! *  Original Date: 08 Jun 1997
! *
! *****************************************************************************/

!------------------------------------------------------------------------------
!> Magnetostriction module that is used to couple static magnetism with
!> elasticity
!> \ingroup Solvers
!-------------------------------------------------------------------------------
MODULE MagnetoStriction

  USE DefUtils
  USE LoadMod
  USE, INTRINSIC :: ISO_C_BINDING

  TYPE MSProcs_t
    TYPE(C_FUNPTR) :: H_cptr=C_NULL_FUNPTR, S_cptr=C_NULL_FUNPTR
    TYPE(C_FUNPTR) :: dHdB_cptr=C_NULL_FUNPTR, dSde_cptr=C_NULL_FUNPTR
  END TYPE

  TYPE MSModel_t
    LOGICAL :: UseMGS
    TYPE(Solver_t), POINTER :: MgDynSolver=>NULL(), ElasticSolver=>NULL()
    INTEGER :: s_n=0, av_nd(2)=0, av_np=0, av_n=0, av_edgebasisdegree=0, s_nd(2)=0
    LOGICAL :: av_piola
    REAL(KIND=dp), ALLOCATABLE :: rotwbasis(:,:), wbasis(:,:), aloc(:), sloc(:,:), basis(:), dBasisdx(:,:)
    TYPE(MSProcs_t) :: MSProcs
    LOGICAL :: Initialized=.FALSE.
  END TYPE

  INTERFACE
    SUBROUTINE mgs_H(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, &
        e33, out_7141795565043958993)
      USE DefUtils
      IMPLICIT NONE
      REAL(KIND=dp), INTENT(IN) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
      REAL(KIND=dp), INTENT(OUT), dimension(1:3, 1:1) :: out_7141795565043958993
    END SUBROUTINE

    SUBROUTINE mgs_dHdB(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, &
        e33, dhdb)
      USE DefUtils
      IMPLICIT NONE
      REAL(KIND=dp), INTENT(IN) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
      REAL(KIND=dp), INTENT(OUT), dimension(1:3, 1:3) :: dhdb
    END SUBROUTINE

    SUBROUTINE mgs_S(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, &
        e33, sigma)
      USE DefUtils
      IMPLICIT NONE
      REAL(KIND=dp), intent(in) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
      REAL(KIND=dp), intent(out), dimension(1:3, 1:3) :: sigma
    END SUBROUTINE

    SUBROUTINE mgs_dSde(B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, &
        e33, dsde)
      USE DefUtils
      IMPLICIT NONE
      REAL(KIND=dp), INTENT(IN) :: B1, B2, B3, e11, e12, e13, e21, e22, e23, e31, e32, e33
      REAL(KIND=dp), INTENT(OUT), DIMENSION(1:9, 1:9) :: dsde
    END SUBROUTINE

    FUNCTION loadfunction_c(quiet, abort_not_found, library, fname ) RESULT(cptr) &
        BIND(C,name='loadfunction_c')
      USE, INTRINSIC :: ISO_C_BINDING
      INTEGER(C_INT) :: quiet
      INTEGER(C_INT) :: abort_not_found
      CHARACTER(C_CHAR) :: library(*), fname(*)
      ! INTEGER(CAddrInt) :: fptr
      TYPE(C_FUNPTR) :: cptr
    END FUNCTION loadfunction_c
  END INTERFACE

CONTAINS

!------------------------------------------------------------------------------
  SUBROUTINE SetMSFunctions(Material, MSModel)
!------------------------------------------------------------------------------
    IMPLICIT NONE
    TYPE(ValueList_t), INTENT(IN), POINTER :: Material
    TYPE(MSModel_t), INTENT(INOUT) :: MSModel
!------------------------------------------------------------------------------
    TYPE(ValueListEntry_t), POINTER :: ptr
    CHARACTER(120) :: msg
    LOGICAL :: Found
!-------------------------------------------------------------------------------

    MSModel % MSProcs % H_cptr = name_to_c_ptr('mgs H fun')
    MSModel % MSProcs % S_cptr = name_to_c_ptr('mgs S fun')
    MSModel % MSProcs % dHdB_cptr = name_to_c_ptr('mgs dHdB fun')
    MSModel % MSProcs % dSde_cptr = name_to_c_ptr('mgs dSde fun')

    CONTAINS
      FUNCTION name_to_c_ptr(procname) result(cptr)
        IMPLICIT NONE
        TYPE(ValueListEntry_t), POINTER :: ptr
        TYPE(C_FUNPTR) :: cptr
        CHARACTER(*) :: procname

        ptr => ListFind( Material, trim(procname), found)
        IF (.not. FOUND) CALL Fatal('SetMSFunctions', trim(procname)//' was not given.')
        IF(ptr % PROCEDURE /= 0) THEN
          cptr = transfer(ptr % PROCEDURE, cptr)
        ELSE
          CALL Fatal('SetMSFunctions', 'ptr % procedure is null')
        END IF
      END FUNCTION name_to_c_ptr
!-------------------------------------------------------------------------------
  END SUBROUTINE SetMSFunctions
!-------------------------------------------------------------------------------

!-------------------------------------------------------------------------------
  SUBROUTINE EvalStrainAtIp(MSModel, Strain, dBasisdx)
!-------------------------------------------------------------------------------
    IMPLICIT NONE
    TYPE(MSModel_t), INTENT(IN) :: MSModel
    REAL(KIND=dp), INTENT(IN) :: dBasisdx(:,:)
    REAL(KIND=dp), INTENT(OUT) :: strain(3,3)
!-------------------------------------------------------------------------------

    Strain = MATMUL( msmodel % sloc(:,1:msmodel % s_nd(1)), dBasisdx(1:msmodel % s_nd(1),:) )
    Strain = (Strain + TRANSPOSE(Strain)) / 2
!-------------------------------------------------------------------------------
  END SUBROUTINE
!-------------------------------------------------------------------------------

!-------------------------------------------------------------------------------
  SUBROUTINE EvalFluxAtIp(MSModel, B, RotWBasis)
!-------------------------------------------------------------------------------
    IMPLICIT NONE
    TYPE(MSModel_t), INTENT(IN) :: MSModel
    REAL(KIND=dp), INTENT(IN) :: RotWBasis(:,:)
    REAL(KIND=dp), INTENT(OUT) :: B(3)
!-------------------------------------------------------------------------------
    INTEGER :: np, nd

    np = MSModel % av_np
    nd = MSModel % av_nd(1)

    B = MATMUL( msmodel % Aloc(np+1:nd), RotWBasis(1:nd-np,:) )
!-------------------------------------------------------------------------------
  END SUBROUTINE
!-------------------------------------------------------------------------------

!-------------------------------------------------------------------------------
  SUBROUTINE CollectMSModel(Material, uelement, MSModel, Model, IP)
!-------------------------------------------------------------------------------
    IMPLICIT NONE
    TYPE(ValueList_t), INTENT(IN), POINTER :: Material
    TYPE(Element_t), INTENT(IN), POINTER :: uelement
    TYPE(MSModel_t), INTENT(INOUT) :: MSModel
    TYPE(Model_t), INTENT(IN) :: Model
    TYPE(GaussIntegrationPoints_t), INTENT(IN), OPTIONAL :: IP
!-------------------------------------------------------------------------------
    INTEGER :: siz, stress_solver_id, av_solver_id
    LOGICAL :: HBCurve, Cubic, Found, secondorder
    INTEGER :: av_nd, s_nd
    INTEGER :: av_nd_node, av_nd_bub
!-------------------------------------------------------------------------------
    IF(.not. MSModel % Initialized) THEN
      IF(.not. associated(MSModel % MgDynSolver)) THEN
        av_solver_id = GetInteger( Material, 'AV Solver id', Found)
        IF(.NOT. Found) CALL Fatal('CollectMSModel','AV solver id not given')
        MSModel % MgDynSolver   => Model % Solvers(av_solver_id)
      END IF

      IF(.not. associated(MSModel % ElasticSolver)) THEN
        stress_solver_id = GetInteger( Material, 'Stress Solver id', Found)
        IF(.NOT. Found) CALL Fatal('CollectMSModel','Stress Solver id not given')
        MSModel % ElasticSolver => Model % Solvers(stress_solver_id)
      END IF

      MSModel % av_piola = GetLogical( GetSolverParams(MSModel % MgDynSolver), &
        'use Piola Transform', Found )
      IF(.NOT. Found) MSModel % av_piola = .FALSE.

      SecondOrder = GetLogical( GetSolverParams(MSModel % MgDynSolver), &
        'Quadratic Approximation', Found )
      IF(.NOT. Found) SecondOrder = .FALSE.

      IF(SecondOrder) THEN
        MSModel % av_edgebasisdegree = 2
      ELSE
        MSModel % av_edgebasisdegree = 1
      END IF
      MSModel % Initialized = .TRUE.
    END IF

    CALL AllocateLocalSolutionArrays()

    CALL GetVectorLocalSolution(msmodel % sloc, usolver=msmodel % ElasticSolver)
    CALL GetScalarLocalSolution(msmodel % aloc, usolver=msmodel % MgDynSolver)

    CALL SetMSFunctions(Material, MSModel)
    MSModel % UseMGS = .TRUE.

    ! Evaluate right basis functions for av solver and elasticity solver based on their
    ! solver-wise "element = ..." keyword

    CONTAINS

      SUBROUTINE AllocateLocalSolutionArrays()
        IMPLICIT NONE

        av_nd = GetElementNOFDOFs(UElement = uElement, USolver = MSModel % MgDynSolver) + &
          GetElementNOFBDOFs(Element = uElement, USolver = MSModel % MgDynSolver)
        MSModel % av_n  = GetElementNOFNodes()
        MSModel % av_np = MSModel % av_n * MSModel % MgDynSolver % &
          Def_Dofs(GetElementFamily(uelement), uelement % BodyId,1)

        s_nd = GetElementNOFDOFS(USolver = MSModel % ElasticSolver)  + &
          GetElementNOFBDOFs(usolver = msmodel % ElasticSolver)

        IF (av_nd > MSModel % av_nd(2)) THEN
          IF(ALLOCATED(MSModel % RotWBasis)) deallocate(MSModel % RotWBasis)
          IF(ALLOCATED(MSModel % WBasis)) deallocate(MSModel % WBasis)
          IF(ALLOCATED(MSModel % aloc)) deallocate(MSModel % aloc)

          ALLOCATE(&
            MSModel % RotWBasis(av_nd,3),&
            MSModel % WBasis(av_nd,3), &
            MSModel % aloc(av_nd))
          MSmodel % av_nd(2) = av_nd
        END IF

        IF (s_nd > MSModel % s_nd(2)) THEN
          IF(ALLOCATED(MSModel % sloc)) deallocate(MSModel % sloc)
          IF(ALLOCATED(MSModel % basis)) deallocate(MSModel % basis)
          IF(ALLOCATED(MSModel % dBasisdx)) deallocate(MSModel % dBasisdx)
          ALLOCATE(&
            MSModel % sloc(3,s_nd),&
            MSModel % basis(s_nd), &
            MSModel % dBasisdx(s_nd,3))
          msmodel % s_nd(2) = s_nd
        END IF

        MSModel % av_nd(1) = av_nd
        MSModel % s_nd(1) = s_nd
      END SUBROUTINE AllocateLocalSolutionArrays

  END SUBROUTINE CollectMSModel

  SUBROUTINE CalcHB(MSModel, B_in, H, dHdB, e_in, sigma, dHde, dSde, dSdB)

    IMPLICIT NONE

    TYPE(MSModel_t), INTENT(IN) :: MSModel
    REAL(KIND=dp), OPTIONAL :: e_in(3,3)
    REAL(KIND=dp), OPTIONAL :: B_in(3)
    REAL(KIND=dp), INTENT(OUT), OPTIONAL :: dHdB(1:3,1:3), sigma(1:3,1:3), &
      dHde(1:3,1:9), dSde(9,9), dSdB(1:9,1:3)
    REAL(KIND=dp), INTENT(OUT), OPTIONAL :: H(1:3,1)
    REAL(KIND=dp) :: e(3,3), B(3)

    PROCEDURE(mgs_H), POINTER :: H_proc
    PROCEDURE(mgs_S), POINTER :: S_proc
    PROCEDURE(mgs_dHdB), POINTER :: dHdB_proc
    PROCEDURE(mgs_dSde), POINTER :: dSde_proc


    INTEGER :: m, n
    REAL(KIND=dp) :: mudiag, Babs, dHdBdiag

    IF(.NOT. PRESENT(B_in)) THEN
      B = 0.0_dp
    ELSE
      DO m=1,3
        B(m) = B_in(m)
      END DO
    END IF

    IF(.NOT. PRESENT(e_in)) THEN
      e = 0.0_dp
    ELSE
      DO m=1,3
        DO n=1,3
          e(m,n) = e_in(m,n)
        END DO
      END DO
    END IF


    IF(PRESENT(H)) THEN
      CALL C_F_PROCPOINTER(MSModel % MSProcs % H_cptr, H_proc)
      CALL H_proc(&
        B(1), B(2), B(3), &
        e(1,1), e(1,2), e(1,3), &
        e(2,1), e(2,2), e(2,3), &
        e(3,1), e(3,2), e(3,3), &
        H)
    END IF


    IF(PRESENT(dhdb)) THEN
      CALL C_F_PROCPOINTER(MSModel % MSProcs % dHdB_cptr, dHdB_proc)
      CALL dHdB_proc( &
        B(1), B(2), B(3), &
        e(1,1), e(1,2), e(1,3), &
        e(2,1), e(2,2), e(2,3), &
        e(3,1), e(3,2), e(3,3), &
        dHdB)
    END IF

    IF(PRESENT(sigma)) THEN
      CALL C_F_PROCPOINTER(MSModel % MSProcs % S_cptr, S_proc)
      CALL S_proc(&
        B(1), B(2), B(3), &
        e(1,1), e(1,2), e(1,3), &
        e(2,1), e(2,2), e(2,3), &
        e(3,1), e(3,2), e(3,3), &
        sigma)
    END IF

    IF(present(dsde)) THEN
      CALL C_F_PROCPOINTER(MSModel % MSProcs % dSde_cptr, dSde_proc)
      CALL dSde_proc(&
        B(1), B(2), B(3), &
        e(1,1), e(1,2), e(1,3), &
        e(2,1), e(2,2), e(2,3), &
        e(3,1), e(3,2), e(3,3), &
        dSde)
    END IF

!-------------------------------------------------------------------------------
  END SUBROUTINE CalcHB
!-------------------------------------------------------------------------------

END MODULE MagnetoStriction
