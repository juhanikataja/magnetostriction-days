program se
use types
use mgscontainer
implicit none
real(kind=dp) :: e(1000), S_se(3,3)

integer :: n

e = [((1.0d-1*n/1000d0), n=1,1000)]

do n = 1,1000
  call S_public(0d0, 0d0, 0d0, e(n), 0d0, 0d0, 0d0, 0d0, 0d0, S_se)
  print *, e(n), S_se(1,1)
end do

end program
