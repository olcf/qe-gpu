!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------------
subroutine stop_pp  
  !--------------------------------------------------------------------
  !
  ! Synchronize processes before stopping.
  !
#ifdef PARA
  include 'mpif.h'  
  integer :: info  
  call mpi_barrier (MPI_COMM_WORLD, info)  

  call mpi_finalize (info)  
#endif
#ifdef T3D
  !
  ! set streambuffers off
  !

  call set_d_stream (0)  
#endif

  stop  
end subroutine stop_pp
