!
! Copyright (C) 2001-2010 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
SUBROUTINE allocate_fft
  !-----------------------------------------------------------------------
  !
  !     This routine allocates memory for FFT-related arrays - IMPORTANT:
  !     routine "data_structure" must be called before it in order to
  !     set the proper dimensions and grid distribution across processors
  !     these dimensions
  !
  USE io_global, ONLY : stdout
  USE gvect,     ONLY : ngm, g, gg, nl, nlm, mill, igtongl
  USE gvecs,   ONLY : ngms, nls, nlsm
  USE fft_base,   ONLY : dfftp, dffts
  USE ions_base, ONLY : nat
  USE lsda_mod,  ONLY : nspin
  USE spin_orb,  ONLY : domag
  USE scf,       ONLY : rho, v, vnew, vltot, vrs, rho_core, rhog_core, &
                        kedtau, create_scf_type
  USE control_flags, ONLY : gamma_only
  USE noncollin_module, ONLY : pointlist, factlist, r_loc, &
      report, i_cons, noncolin, npol
  USE wavefunctions_module, ONLY : psic, psic_nc, psic_batch
  USE funct,     ONLY: dft_is_meta
#ifdef USE_CUDA                                               
  USE fft_parallel, ONLY : f_h, aux_h, aux_d, aux2_h, aux2_d
  USE wavefunctions_module, ONLY : psic_d, psic_batch_d                     
  USE scf,        ONLY : vltot_d, vrs_d, rho_core_d, rhog_core_d
  USE mpiDeviceUtil, ONLY : dev_id, node_id
  USE mp_bands, ONLY: nproc_bgrp
#endif     
  IMPLICIT NONE
 integer :: i
  !
  ! First a bunch of checks
  !
  IF (dfftp%nnr.lt.ngm) THEN
     WRITE( stdout, '(/,4x," nr1=",i4," nr2= ", i4, " nr3=",i4, &
          &" nrxx = ",i8," ngm=",i8)') dfftp%nr1, dfftp%nr2, dfftp%nr3, dfftp%nnr, ngm
     CALL errore ('allocate_fft', 'the nr"s are too small!', 1)

  ENDIF
  IF (dffts%nnr.lt.ngms) THEN
     WRITE( stdout, '(/,4x," nr1s=",i4," nr2s= ", i4, " nr3s=",i4, &
          &" nrxxs = ",i8," ngms=",i8)') dffts%nr1, dffts%nr2, dffts%nr3, dffts%nnr, ngms
     CALL errore ('allocate_fft', 'the nrs"s are too small!', 1)

  ENDIF
  IF (ngm  <= 0) CALL errore ('allocate_fft', 'wrong ngm', 1)
  IF (ngms <= 0) CALL errore ('allocate_fft', 'wrong ngms', 1)
  IF (dfftp%nnr <= 0) CALL errore ('allocate_fft', 'wrong nnr', 1)
  IF (dffts%nnr<= 0) CALL errore ('allocate_fft', 'wrong smooth nnr', 1)
  IF (nspin<= 0) CALL errore ('allocate_fft', 'wrong nspin', 1)

#ifdef USE_CUDA
  IF (nproc_bgrp == 1) then
    WRITE( stdout, '(5x,"Only 1 process per pool detected. Reducing FFT batch sizes...")')
    dfftp%batchsize = 4
    dfftp%subbatchsize = 4
    dffts%batchsize = 4
    dffts%subbatchsize = 4
  ENDIF
#endif
  !
  !     Allocate memory for all kind of stuff.
  !
  CALL create_scf_type(rho)
  CALL create_scf_type(v,    do_not_allocate_becsum = .true.)
  CALL create_scf_type(vnew, do_not_allocate_becsum = .true.)
  ALLOCATE (vltot( dfftp%nnr))
  ALLOCATE (rho_core( dfftp%nnr))
  IF (dft_is_meta() ) THEN
     ALLOCATE ( kedtau(dffts%nnr,nspin) )
  ELSE
     ALLOCATE ( kedtau(1,nspin) )
  ENDIF
  ALLOCATE( rhog_core( ngm ) )
  ALLOCATE (psic( dfftp%nnr))
  ALLOCATE (psic_batch(dfftp%batchsize*dfftp%nnr))
  ALLOCATE (vrs( dfftp%nnr, nspin))

#ifdef USE_CUDA                                               
  ALLOCATE (psic_d( dfftp%nnr))                              
  ALLOCATE (psic_batch_d(dfftp%batchsize*dfftp%nnr))
  ALLOCATE (f_h(dfftp%batchsize*dfftp%nnr))
  ALLOCATE (aux_h(dfftp%batchsize*dfftp%nnr))
  ALLOCATE (aux_d(dfftp%batchsize*dfftp%nnr))
  ALLOCATE (aux2_h(dfftp%batchsize*dfftp%nnr))
  ALLOCATE (aux2_d(dfftp%batchsize*dfftp%nnr))
  ALLOCATE (vltot_d( dfftp%nnr))                              
  ALLOCATE (rho_core_d( dfftp%nnr))                           
  ALLOCATE (rhog_core_d( ngm ) )                              
  ALLOCATE (vrs_d( dfftp%nnr, nspin))                         
#ifdef USE_IPC
  call init_ipc( psic_batch_d, 0, dfftp%comm, dfftp%IPC_PEER, dev_id, node_id )
  call init_ipc(       aux2_d, 1, dfftp%comm, dffts%IPC_PEER, dev_id, node_id )
#ifdef __CUDA_DEBUG
DO i = 1,dfftp%nproc
  print *,"IPC_PEER[ ",i," ]:",dfftp%IPC_PEER(i)
ENDDO
#endif
#endif
#endif  

  IF (noncolin) ALLOCATE (psic_nc( dfftp%nnr, npol))

  IF ( ( (report.ne.0).or.(i_cons.ne.0) ) .and. (noncolin.and.domag) &
                      .or. (i_cons.eq.1) .or. nspin==2 ) THEN
!
! In order to print out local quantities, integrated around the atoms,
! we need the following variables
!
     ALLOCATE(pointlist(dfftp%nnr))
     ALLOCATE(factlist(dfftp%nnr))
     ALLOCATE(r_loc(nat))
     CALL make_pointlists ( )
  ENDIF

  RETURN
END SUBROUTINE allocate_fft
