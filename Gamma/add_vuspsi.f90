!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine add_vuspsi (lda, n, m, psi, hpsi )  
  !-----------------------------------------------------------------------
  !
  !    This routine applies the Ultra-Soft Hamiltonian to a
  !    vector psi and puts the result in hpsi.
  !    Requires the products of psi with all beta functions
  !    in array becp(nkb,m) (calculated by ccalbec)
  ! input:
  !     lda   leading dimension of arrays psi, spsi
  !     n     true dimension of psi, spsi
  !     m     number of states psi
  !     psi   
  ! output:
  !     hpsi  V_US*psi is added to hpsi
  !
#include "machine.h"
  use pwcom  
  use rbecmod
  use allocate
  implicit none
  !
  !     First the dummy variables
  !
  integer :: lda, n, m
  complex(kind=DP) :: psi (lda, m), hpsi (lda, m)  
  !
  !    here the local variables
  !
  integer :: jkb, ikb, ih, jh, na, nt, ijkb0, ibnd  
  ! counters
  real(kind=DP), allocatable :: ps (:,:)  
  ! the product vkb and psi
  !
  if (nkb.eq.0) return  
  allocate(ps(nkb,m))  
  ps(:,:) = 0.d0
  call start_clock ('add_vuspsi')  
  ijkb0 = 0  
  do nt = 1, ntyp  
     do na = 1, nat  
        if (ityp (na) .eq.nt) then  
           do ibnd = 1, m
              do jh = 1, nh (nt)  
                 jkb = ijkb0 + jh  
                 do ih = 1, nh (nt)  
                    ikb = ijkb0 + ih  
                    ps (ikb, ibnd) = ps (ikb, ibnd) + &
                         deeq(ih,jh,na,current_spin) * becp(jkb,ibnd)
                 enddo
              enddo
           enddo
           ijkb0 = ijkb0 + nh (nt)  
        endif
     enddo
  enddo

  call DGEMM ('N', 'N', 2*n, m, nkb, 1.d0, vkb, &
       2*lda, ps, nkb, 1.d0, hpsi, 2*lda)
  deallocate (ps)  

  call stop_clock ('add_vuspsi')  
  return  
end subroutine add_vuspsi

