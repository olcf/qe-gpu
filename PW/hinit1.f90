!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine hinit1  
  !-----------------------------------------------------------------------
  !  Atomic configuration dependent hamiltonian initialization
  !
  use pwcom  
  !
  implicit none
  !  update the potential
  !
  call update_pot  
  !
  !  initialize structure factor array if it has not already been calculat
  !  update_pot ( this is done if order > 0 )
  !
  if (order.eq.0) then  
     if (lmovecell) call scale_h  
     call struc_fact (nat, tau, ntyp, ityp, ngm, g, bg, nr1, nr2, &
          nr3, strf, eigts1, eigts2, eigts3)
     !
     !  calculate the core charge (if any) for the nonlinear core correction
     !
     call set_rhoc  
  endif
  !
  ! calculate the total local potential
  !
  call setlocal  
  !
  ! define the total local potential (external+scf)
  !
  call set_vrs (vrs, vltot, vr, nrxx, nspin, doublegrid)  
  !
  ! orthogonalize the wavefunctions with the new S if Davidson without
  ! overlap is used
  !
  if (.not.loverlap.and.isolve.eq.0) call ortho  
  !
  ! and update the D matrix
  !
  call newd  
  !
  ! and recalculate the products of the S with the atomic wfcs used in LDA+U
  ! calculations
  !
  if (lda_plus_u) call orthoatwfc

  return  
end subroutine hinit1

