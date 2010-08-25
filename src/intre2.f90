      subroutine intre2(najh,natms,ixx,iyy,izz,xxx,yyy,zzz)

! version 2 allows for a maximum of 500AA in either direction along each
! axis. enlarged from the original allowance of 100AA to unbind 5-HT from
! its receptor.
!
! P.-L. Chau  2004/11/05

      implicit none

      double precision xxx(*),yyy(*),zzz(*)
      integer natms,najh
      integer ixx(*),iyy(*),izz(*)

      integer j

! read in all records and convert from Hardwick format to real numbers
      do 180 j = 1,natms
         read(najh,*) ixx(j),iyy(j),izz(j)
         xxx(j) = dble(ixx(j))*5.0d2/dble(2**30)
         yyy(j) = dble(iyy(j))*5.0d2/dble(2**30)
         zzz(j) = dble(izz(j))*5.0d2/dble(2**30)
 180  continue

      return
      end
