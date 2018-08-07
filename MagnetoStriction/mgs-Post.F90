MODULE MgsPostUtils
  USE Types, only: Element_t

  INTERFACE
    SUBROUTINE write_element(Element)
        USE TYPES, only: element_t
        TYPE(Element_t), POINTER :: Element
    END SUBROUTINE
  END INTERFACE

END MODULE MgsPostUtils

!-------------------------------------------------------------------------------
SUBROUTINE MgsPost_init0( Model,Solver,dt,TransientSimulation )
!-------------------------------------------------------------------------------
  USE DefUtils

  IMPLICIT NONE
!------------------------------------------------------------------------------
  TYPE(Solver_t) :: Solver
  TYPE(Model_t) :: Model

  REAL(KIND=dp) :: dt
  LOGICAL :: TransientSimulation
!------------------------------------------------------------------------------
! Local variables
!------------------------------------------------------------------------------
  TYPE(ValueList_t), POINTER :: SolverParams
  SolverParams => GetSolverParams()
  CALL ListAddLogical(SolverParams, "Discontinuous Galerkin", .TRUE.)
  CALL ListAddString(SolverParams, "Variable", &
    "mgs_stress[mgs_stress_xx:1 mgs_stress_yy:1 mgs_stress_zz:1 mgs_stress_xy:1 mgs_stress_yz:1 mgs_stress_xz:1]")
  CALL ListAddString(SolverParams, "Element","n:1")
  ! CALL ListAddString(SolverParams, "Exported Variable 1", "mgs field strength[mgs field strength:3]") ! This is probably not
  ! needed


!-------------------------------------------------------------------------------
END SUBROUTINE MgsPost_init0
!-------------------------------------------------------------------------------

SUBROUTINE write_element(Element)
    USE types, only: element_t
    IMPLICIT NONE
    TYPE(Element_t), POINTER:: Element
    write (*,"(A, I5)", advance="NO"), 'Type:', Element % TYPE % ElementCode
    write (*, *), 'DGIndexes', Element % DGIndexes(:)
    write (*, *), 'Bodyid', Element % BodyID
    write (*, *), 'NDOFs, bdofs, dgdofs', Element % ndofs, &
        Element % bdofs, Element % dgdofs

END SUBROUTINE write_element

!-------------------------------------------------------------------------------
SUBROUTINE MgsPost_bulk( Model,Solver,dt,TransientSimulation )
!-------------------------------------------------------------------------------
  USE DefUtils
  USE MgsPostUtils
  USE MagnetoStriction

  IMPLICIT NONE
!------------------------------------------------------------------------------
  TYPE(Solver_t) :: Solver
  TYPE(Model_t) :: Model

  REAL(KIND=dp) :: dt
  LOGICAL :: TransientSimulation
!------------------------------------------------------------------------------
! Local variables
!------------------------------------------------------------------------------
  TYPE(Element_t), POINTER :: Element
  TYPE(ValueHandle_t) :: ExternalHB_h, Young_h, Poisson_h
  TYPE(MSModel_t) :: MSModel
  TYPE(GaussIntegrationPoints_t) :: IP

  INTEGER :: m, n, i, j, t, p, q, n_local_dofs, TotNDofs, nd
  INTEGER, parameter :: stressdofs = 6
  INTEGER, parameter :: Voigtmap(3,3) = reshape([1,4,6,4,2,5,6,5,3],[3,3])
  INTEGER, parameter :: inverseVoigtmap(2,6) = reshape([1,1,2,2,3,3,1,2,2,3,1,3],[2,6])

  LOGICAL :: ExternalHB, Found, elem_status, use_flux, use_strain
  REAL(KIND=dp) :: B(1:3,1), stress(3,3), Hfield(1:3,1), &
    DetJ, strain(3,3), sol_norm,stressvoigt(6), Poisson, Young

  REAL(KIND=dp), ALLOCATABLE :: STIFF(:,:), LOAD(:), basis(:)
  TYPE(Nodes_t) :: Nodes
  type(Variable_t), POINTER :: varptr

  REAL(KIND=dp) :: lame_mu, lame_lambda
!------------------------------------------------------------------------------

  use_flux = ListGetLogical(GetSolverParams(), "use flux", Found)
  if(.not. Found) use_flux = .true.

  use_strain = ListGetLogical(GetSolverParams(), "use strain", Found)
  if(.not. Found) use_strain = .true.

  Solver % variable % TYPE = Variable_on_nodes_on_elements
  varptr => solver % Variable
  DO while (associated(varptr))
    if(varptr % name(1:11) == 'mgs_stress_') &
      varptr % TYPE = Variable_on_nodes_on_elements
    varptr => varptr % next
  END DO

  nd = MAX(Solver % Mesh % MaxElementDOFs, Solver % Mesh % MaxElementNodes)

  ALLOCATE(basis(nd))
  ALLOCATE(STIFF(stressdofs*nd,stressdofs*nd))
  ALLOCATE(LOAD(stressdofs*nd))

  n = Solver % Mesh % MaxElementNodes
  ALLOCATE(Nodes % x(n), Nodes % y(n), Nodes % z(n), Nodes % xyz(n,3))

  CALL ListInitElementKeyword(ExternalHB_h, 'Material', 'External HB model')
  CALL ListInitElementKeyword(Young_h, 'Material', 'Youngs modulus')
  CALL ListInitElementKeyword(Poisson_h, 'Material', 'Poisson ratio')
  !  Poisson Ratio = Real 0.34
  !  Youngs Modulus = Real 183e9

  CALL DefaultInitialize()

  DO m = 1,GetNOFActive()
    Element => GetActiveElement(m)
    ExternalHB = ListGetElementLogical( ExternalHB_h, Element, Found )
    IF (.NOT. ExternalHB) CYCLE
    STIFF = 0.0_dp
    LOAD = 0.0_dp

    CALL GetElementNodes(Nodes, Element)
    CALL CollectMSModel(GetMaterial(Element), Element, MSModel, Model)


    IP = GaussPoints(Element)
    n_local_dofs = GetElementNOFDOFs(Element)
    TotNDofs = n_local_dofs*stressdofs
    !print *, "young, poisson: ", MSModel %YoungModulus, MSModel %PoissonRatio
    !lame_mu = MSModel %YoungModulus/(2*(1+msmodel %PoissonRatio))
    !lame_lambda = msmodel %YoungModulus*msmodel%PoissonRatio / &
    !  ((1+MSModel%PoissonRatio)*(1-2*MSModel%PoissonRatio))

    DO t = 1, IP % N
      IF (MSModel % av_piola) THEN
        elem_status = EdgeElementInfo( Element, Nodes, IP % U(t), IP % V(t), &
          IP % W(t), DetF = DetJ, Basis = Basis, EdgeBasis = msmodel % WBasis, &
          RotBasis = msmodel % rotwbasis, dBasisdx = msmodel % dBasisdx, &
          BasisDegree = msmodel % av_EdgeBasisDegree, ApplyPiolaTransform = .TRUE.)
      ELSE
        elem_status = ElementInfo( Element, Nodes, IP % U(t), IP % V(t), &
          IP % W(t), detJ, Basis, MSModel % dBasisdx )
        CALL GetEdgeBasis(Element, msmodel % WBasis, msmodel % RotWBasis, msmodel % Basis, msmodel % dBasisdx)
      END IF

      if(use_strain) then
        CALL EvalStrainAtIp(MSModel, Strain, msmodel % dBasisdx)
      ELSE
        Strain = 0.0_dp
      END IF

      IF(use_flux) then
        CALL EvalFluxAtIp(MSModel, B, msmodel % rotwbasis)
      ELSE
        B = 0.0_dp
      END IF

    Poisson = ListGetElementReal(Poisson_h, Basis, Element)
    Young= ListGetElementReal(Young_h, Basis, Element)

    CALL CalcHB(MSModel, B_in=B, H=Hfield, e_in=strain, sigma=stress, &
      Young=Young, poisson=poisson)

    ! calculate stress the old fashioned way:
    !  stress = 2*lame_mu*strain
    !  do p=1,3
    !    stress(p,p) = stress(p,p) + (strain(1,1)+strain(2,2)+strain(3,3))*lame_lambda
    !  end do



      do p = 1, stressdofs
        stressvoigt(p) = stress(inverseVoigtmap(1,p), inverseVoigtmap(2,p))
      end do

      DO i = 1,n_local_dofs
        DO j = 1,n_local_dofs
          DO p = 1,stressdofs ! six dofs in stress tensor
              STIFF(stressdofs*(i-1)+p,stressdofs*(j-1)+p) = &
                STIFF(stressdofs*(i-1)+p,stressdofs*(j-1)+p) + &
                basis(i)*basis(j) * IP % s(t) * detJ
          END DO
        END DO
        DO p = 1,6
          LOAD(stressdofs*(i-1)+p) = &
            LOAD(stressdofs*(i-1)+p) + &
            basis(i)*stressvoigt(p) * &
            IP % s(t) * DetJ
        END DO
      END DO

    END DO ! IP loop
    CALL DefaultUpdateEquations(STIFF,LOAD)
  END DO ! Element loop

!-------------------------------------------------------------------------------
END SUBROUTINE MgsPost_bulk
!-------------------------------------------------------------------------------

