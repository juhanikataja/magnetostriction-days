program hb
use types
use mgscontainer
use DefUtils
implicit none
real(kind=dp) :: B(1000), H_hb(3,1)

integer :: n

B = [((2.0d0*n/1000d0), n=1,1000)]

do n = 1,1000
  call H_public(B(n), 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, 0d0, H_hb)
  print *, B(n), H_hb(1,1)
end do

end program
