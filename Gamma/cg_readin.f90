!
!-----------------------------------------------------------------------
subroutine cg_readin
  !-----------------------------------------------------------------------
  !
  use pwcom
  use cgcom
  use io
  implicit none
  integer :: iunit
  namelist /inputph/ prefix, fildyn, trans, epsil, raman, nmodes,     &
            tr2_ph, niter_ph, amass, tmp_dir, asr, deltatau, nderiv, &
            first, last
  !
  call start_clock('cg_readin')
  !
  prefix = 'pwscf'
  fildyn = 'matdyn'
  epsil  = .true.
  trans  = .true.
  raman  = .true.
  asr    = .false.
  tr2_ph = 1.0e-12
  niter_ph= 50
  nmodes =  0
  deltatau= 0.0
  nderiv = 2
  first  = 1
  last   = 0
#if defined(T3E) || defined(ORIGIN)
  iunit=9
#else
  iunit=5
#endif
  read(iunit,'(a)') title_ph
  read(iunit,inputph)
#ifdef PARA
  call init_pool
#endif
  !
  !  read the input file produced by 'punch' subroutine in pwscf program
  !  allocate memory and recalculate what is needed
  !
  call read_file
  !
  !  various checks
  !
  if (.not.trans .and. .not.epsil)                                  &
       &     call error('data','nothing to do',1)
  if (nks.ne.1) call error('data','too many k-points',1)
  !      if (xk(1,1).ne.0.0 .or. xk(2,1).ne.0.0 .or. xk(3,1).ne.0.0)
  !     &    call error('data','only k=0 allowed',1)
  if (nmodes.gt.3*nat .or. nmodes.lt.0)                             &
       &     call error('data','wrong number of normal modes',1)
  if (epsil .and. nmodes.ne.0) call error('data','not allowed',1)
  if (raman .and. deltatau.le.0.d0)                                 &
       &     call error('data','deltatau > 0 needed for raman CS',1)
  if (nderiv.ne.2 .and. nderiv.ne.4) &
       call error('data','nderiv not allowed',1)
  !
  if (last.eq.0) last=3*nat
  !
  call cg_readmodes(iunit)
  !
  call stop_clock('cg_readin')
  !
  return
end subroutine cg_readin
!
!-----------------------------------------------------------------------
subroutine cg_readmodes(iunit)
  !-----------------------------------------------------------------------
#include "machine.h"
  use parameters, only: DP
  use allocate
  use pwcom
  use cgcom
  !
  implicit none
  integer :: iunit
  !
  integer :: na, nu, mu
  real(kind=DP) utest, unorm, DDOT
  !
  ! allocate space for modes, dynamical matrix, auxiliary stuff
  !
  call mallocate (u,  3*nat, 3*nat)
  call mallocate (dyn,3*nat, 3*nat)
  call mallocate (equiv_atoms, nat, nat)
  call mallocate (n_equiv_atoms, nat)
  call mallocate (has_equivalent,nat)
  !
  ! nmodes not given: use defaults (all modes) as normal modes ...
  !
  if (nmodes.eq.0) then
     call find_equiv_sites (nat,nat,nsym,irt,has_equivalent,        &
          &      n_diff_sites,n_equiv_atoms,equiv_atoms)
     if (n_diff_sites .le. 0 .or. n_diff_sites .gt. nat)            &
          &      call error('equiv.sites','boh!',1)
     !
     ! these are all modes, but only independent modes are calculated
     !
     nmodes = 3*nat
     call setv(3*nat*nmodes,0.d0,u,1)
     do nu = 1,nmodes
        u(nu,nu) = 1.0
     end do
     ! look if ASR can be exploited to reduce the number of calculations
     ! we need to locate an independent atom with no equivalent atoms
     nasr=0
     if (asr.and.n_diff_sites.gt.1) then
        do na = 1, n_diff_sites
           if (n_equiv_atoms(na).eq.1 ) then
              nasr = equiv_atoms(na, 1)
              go to 1
           end if
        end do
 1      continue
     end if
  else
     if (asr) call error('readin','warning: asr disabled',-1)
     nasr=0
     !
     ! ... otherwise read normal modes from input
     !
     do na = 1,nat
        has_equivalent(na) = 0
     end do
     do nu = 1,nmodes
        read (iunit,*,end=10,err=10) (u(mu,nu), mu=1,3*nat)
        do mu = 1, nu-1
           utest = DDOT(3*nat,u(1,nu),1,u(1,mu),1)
           if (abs(utest).gt.1.0e-10) then
              print *, ' warning: input modes are not orthogonal'
              call DAXPY(3*nat,-utest,u(1,mu),1,u(1,nu),1)
           end if
        end do
        unorm = sqrt(DDOT(3*nat,u(1,nu),1,u(1,nu),1))
        if (abs(unorm).lt.1.0e-10) go to 10
        call DSCAL(3*nat,1.0/unorm,u(1,nu),1)
     end do
     go to 20
10   call error('phonon','wrong data read',1)
  endif
20 continue
  !
  return
end subroutine cg_readmodes
