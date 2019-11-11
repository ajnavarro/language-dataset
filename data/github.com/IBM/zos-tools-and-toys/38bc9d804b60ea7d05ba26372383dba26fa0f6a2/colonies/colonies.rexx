/* REXX */
/**********************************************************************/
/* List colony address spaces                                         */
/*                                                                    */
/* PROPERTY OF IBM                                                    */
/* COPYRIGHT IBM CORP. 1998                                           */
/*                                                                    */
/* Bill Schoen <wjs@us.bm.com> 4/9/98                                 */
/**********************************************************************/
numeric digits 12
pctcmd=-2147483647
pfs='KERNEL'
parse source . how . . . . . omvs .
if omvs<>"OMVS" then
   call syscalls 'ON'
address syscall
catd=-1

z4='00000000'x
cvtecvt=140
ecvtocvt=240
ocvtocve=8
ocvtfds='58'
ofsb='1000'
ofsbgfs='08'
ofsbcab='fc'
ofsblen='200'
cabname='08'
cabnext='14'

cvt=c2x(storage(10,4))
ecvt=c2x(storage(d2x(x2d(cvt)+cvtecvt),4))
ocvt=c2x(storage(d2x(x2d(ecvt)+ecvtocvt),4))

fds=storage(d2x(x2d(ocvt)+x2d(ocvtfds)),4)

if fetch(fds,'00001000'x,ofsblen) then
   do
   say 'Kernel is unavailable or at the wrong level',
                  'for this function or you are not a superuser'
   exit 1
   end
cab=ofs(ofsbcab,4)
cnt=0
if cab=z4 then
   say 'No colony address spaces'
 else
   say 'Colony address spaces:'
do while cab<>z4
   if fetch(fds,cab,'20')=0 then
      do
      cnt=cnt+1
      say ofs(cabname,8)
      cab=ofs(cabnext,4)
      end
end
return

/**********************************************************************/
ofs:
   arg ofsx,ln
   return substr(buf,x2d(ofsx)+1,ln)

/**********************************************************************/
fetch:
   parse arg alet,addr,len,eye  /* char: alet,addr  hex: len */
   len=x2c(right(len,8,0))
   dlen=c2d(len)
   buf=alet || addr || len
   'pfsctl' pfs pctcmd 'buf' max(dlen,12)
   if rc<>0 | retval=-1 then
      return 1
   if eye<>'' then
      if substr(buf,1,length(eye))<>eye then
         return 1
   if dlen<12 then
      buf=substr(buf,1,dlen)
   return 0
