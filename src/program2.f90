!! para llamar a los generadores de R
!subroutine test_random(y) 
!double precision normrnd, unifrnd, x, y
!call rndstart() 
!!x = normrnd()
!y = unifrnd() 
!call rndend() 
!return
!end




subroutine allotest_(X,Y,W,n,kbin,nboot,T,pvalor,umatrix)
implicit none

!!DEC$ ATTRIBUTES DLLEXPORT::test_allo
!!DEC$ ATTRIBUTES C, REFERENCE, ALIAS:'test_allo_' :: test_allo

integer n,kbin,p,iboot,nboot,i,j
double precision X(n),X2(n),Y(n),Y2(n),W(n),&
errg(n),muhatg(n),Yboot(n),h,T,Tboot,pvalor,&
umatrix(n,nboot), aux, beta(10)
!real u, rand
double precision u
real,external::rnnof
integer,external::which_min,which_max2



w=1


h=-1.0
aux = 0.001
do i=1,n
 X2(i)=max(X(i),aux)
 Y2(i)=max(Y(i),aux)
end do


X=log(X2)
Y=log(Y2)

! Estimación Piloto 

!p=1
!call Reglineal_pred(X,Y,W,n,p,muhatg)


p=1
call Reglineal (X,Y,W,n,p,Beta)
do i=1,n
muhatg(i)=beta(1)
do j=1,p
muhatg(i)=muhatg(i)+beta(j+1)*X(i)**j
end do
end do


 errg=Y-muhatg


!print *, errg(1:n)

call RfastC3(X,Y,W,n,p,kbin,h,T)
!print *, T 

pvalor=0
do iboot=1,nboot
 do i=1,n
  !u=RAND()
  !call test_random(u)
  u = umatrix(i,iboot)
  if (u.le.(5.0+sqrt(5.0))/10) then
   Yboot(i)=muhatg(i)+errg(i)*(1-sqrt(5.0))/2
  else
   Yboot(i)=muhatg(i)+errg(i)*(1+sqrt(5.0))/2
  end if
 end do
 h=-1.0
call RfastC3(X,Yboot,W,n,p,kbin,h,Tboot)
if(Tboot.gt.T) pvalor=pvalor+1
end do

pvalor=pvalor/nboot

end subroutine





subroutine allotest_sestelo_(X,Y,W,n,kbin,nboot,T,pvalor,umatrix)
implicit none

!!DEC$ ATTRIBUTES DLLEXPORT::test_allo
!!DEC$ ATTRIBUTES C, REFERENCE, ALIAS:'test_allo_' :: test_allo

integer n,kbin,p,iboot,nboot,i,j
double precision X(n),X2(n),Y(n),Y2(n),W(n),&
errg(n),muhatg(n),Yboot(n),h,T,Tboot,pvalor,&
umatrix(n,nboot), aux, beta(10)
!real u, rand
double precision u
real,external::rnnof
integer,external::which_min,which_max2


h=-1.0
aux = 0.001
do i=1,n
 X2(i)=max(X(i),aux)
 Y2(i)=max(Y(i),aux)
end do

X2=log(X2)
Y2=log(Y2)

! Estimación Piloto escala normal
p=1
call Reglineal (X2,Y2,W,n,p,Beta)

do i=1,n
muhatg(i)=exp(beta(1))
do j=1,p
muhatg(i)=muhatg(i)*X(i)**beta(j+1)
end do
end do
errg=Y-muhatg ! residuos modelo alometrico


!print *, errg(1:n)

call RfastC3_sestelo(X,Y,W,n,p,kbin,h,T)
!print *, T 

pvalor=0
do iboot=1,nboot
 do i=1,n
  !u=RAND()
  !call test_random(u)
  u = umatrix(i,iboot)
  if (u.le.(5.0+sqrt(5.0))/10) then
   Yboot(i)=muhatg(i)+errg(i)*(1-sqrt(5.0))/2
  else
   Yboot(i)=muhatg(i)+errg(i)*(1+sqrt(5.0))/2
  end if
 end do
 h=-1.0
call RfastC3_sestelo(X,Yboot,W,n,p,kbin,h,Tboot)
if(Tboot.gt.T) pvalor=pvalor+1
end do

pvalor=pvalor/nboot

end subroutine


subroutine RfastC3_sestelo(X,Y,W,n,p,kbin,h,T)
implicit none

integer,parameter::kernel=1,nh=20
integer n,kbin,p,i,j
double precision X(n),Y(n),W(n),Xb(kbin),pred1(n),h,X2(n),Y2(n),&
Pb(kbin,3),residuo(n),predg(n),T,sumw,sum2,xmin,xmax,rango,beta(10),aux
integer,external::which_min



aux = 0.001
do i=1,n
 X2(i)=max(X(i),aux)
 Y2(i)=max(Y(i),aux)
end do
! Ajustamos el modelo lineal primero
X2=log(X2)
Y2=log(Y2)

p=1
call Reglineal (X2,Y2,W,n,p,Beta)
do i=1,n
predg(i)=exp(beta(1))
do j=1,p
predg(i)=predg(i)*X(i)**beta(j+1)
end do
end do

Residuo=Y-predg

! -----------------------------------------

!print *, predg

!do i=1,n
 ! print (*,*) predg(i)
!end do

p=3
!call rfast_h_alo(X,Residuo,W,n,h,p,Xb,Pb,kbin,kernel,nh)
call Grid1d(X,W,n,Xb,kbin)



call rfast_h(X,Residuo,W,n,h,p,Xb,Pb(1,1),kbin,kernel,nh)


!stop

!call Interpola_alo(Xb,Pb,kbin,X,pred1,pred2,n)
call Interpola(Xb,Pb(1,1),kbin,X,pred1,n)

!do i=1,n
!print *, residuo(1:n)
! print *, pred1(i)
!end do


 !print *, pred1(1:n)

!Centro las pred1
sumw=0
sum2=0
do i=1,n
sumw=sumw+W(i)
sum2=sum2+pred1(i)
end do



do i=1,n
Pred1(i)=pred1(i)-(sum2/sumw)
end do




xmin=9999
xmax=-xmin
do i=1,n
if(x(i).le.xmin) xmin=x(i)
if(x(i).ge.xmax) xmax=x(i)
end do

rango=xmax-xmin

T=0
do i=1,n
!if (abs(X(i)).le.xmax-(0.10*rango)) 
T=T+abs(pred1(i))
end do



end subroutine



subroutine RfastC3(X,Y,W,n,p,kbin,h,T)
implicit none

integer,parameter::kernel=1,nh=20
integer n,kbin,p,i,j
double precision X(n),Y(n),W(n),Xb(kbin),pred1(n),h,&
Pb(kbin,3),residuo(n),predg(n),T,sumw,sum2,xmin,xmax,rango,beta(10)
integer,external::which_min




! Ajustamos el modelo lineal primero

p=1
!call Reglineal_pred(X,Y,W,n,p,predg)

call Reglineal (X,Y,W,n,p,Beta)
do i=1,n
predg(i)=beta(1)
do j=1,p
predg(i)=predg(i)+beta(j+1)*X(i)**j
end do
end do

Residuo=Y-predg

! -----------------------------------------

!print *, predg

!do i=1,n
 ! print (*,*) predg(i)
!end do

p=2



!call rfast_h_alo(X,Residuo,W,n,h,p,Xb,Pb,kbin,kernel,nh)

call Grid1d(X,W,n,Xb,kbin)



call rfast_h(X,Residuo,W,n,h,p,Xb,Pb(1,1),kbin,kernel,nh)


!stop

!call Interpola_alo(Xb,Pb,kbin,X,pred1,pred2,n)
call Interpola(Xb,Pb(1,1),kbin,X,pred1,n)

do i=1,n
!print *, residuo(1:n)
 !print *, pred1(i)
end do


 !print *, pred1(1:n)

!Centro las pred1
sumw=0
sum2=0
do i=1,n
sumw=sumw+W(i)
sum2=sum2+pred1(i)
end do



do i=1,n
Pred1(i)=pred1(i)-(sum2/sumw)
end do




xmin=9999
xmax=-xmin
do i=1,n
if(x(i).le.xmin) xmin=x(i)
if(x(i).ge.xmax) xmax=x(i)
end do

rango=xmax-xmin

T=0
do i=1,n
if (abs(X(i)).le.xmax-(0.10*rango)) T=T+abs(pred1(i))
end do



end subroutine



subroutine Reglineal_pred(X,Y,W,n,p,Pred)
implicit none
integer i,n,j,p,iopt
double precision X(n),Y(n),W(n),Pred(n),beta(p+1),&
sterr(p+1),se,r2,X2(n,p+1)
do i=1,n
do j=1,p
X2(i,j)=X(i)**j
end do
end do
iopt=0
call WRegresion(X2,Y,W,n,p,beta,sterr,se,r2,iopt)
!do i=1,n
!	Pred(i)= Beta(1)+Beta(2)*X(i)
!end do 


pred=Beta(1)
do i=1,n
do j=1,p
pred(i)=pred(i)+Beta(j+1)*X2(i,j)
end do
end do

end







!*********************************************************
!		
!Subroutine RFAST_H_alo MODIFICADA PARA EL CONTRASTE ALOMETRICO
! PB AHORA ES UN VECTOR!
!
!* h: ventana, seleccivÄ±n por cv (h=-1). Valores de 0 a 1.
!* kernel: tipo de nucleo (1=epanech, 2=triang, 3=gaussian)
!* nh: grid de busqueda de ventanas, de 0 a 1.
!* p: grado del polinomio
!
!*********************************************************
subroutine rfast_h_alo(X,Y,W,n,h,p,Xb,Pb,kbin,kernel,nh)

!!DEC$ ATTRIBUTES DLLEXPORT::rfast
!!DEC$ ATTRIBUTES C, REFERENCE, ALIAS:'rfast_' :: RFAST 

implicit none
integer n,i,j,kbin,p,ifcv,nh,kernel

double precision x(n),Y(n),W(n),Xb(kbin),Yb(kbin),Wb(kbin),&
Pb(kbin),h,&
rango,hmin,hmax,beta(p+1),xbb(kbin),pred(8)


call GRID1D(X,W,n,Xb,kbin)

xbb(1:kbin)=xb(1:kbin)




call Binning(X,Y,n,W,Xb,Yb,Wb,kbin)
rango=Xb(kbin)-Xb(1)
hmin=0
hmax=1



if (h.eq.-1)  then ! ventana por cv
call Ventana1D(Xb,Yb,Wb,kbin,h,p,hmin,hmax,nh,rango,kernel)

elseif(h.eq.0) then ! lineal
call Reglineal (Xb,Yb,Wb,kbin,p,Beta)

pb=0
do i=1,kbin
Pb(i)=beta(1)
!	Pb(i,2)=0
do j=1,p
pb(i)=pb(i)+beta(j+1)*Xbb(i)**j
!	pb(i,2)=pb(i,2)+p*beta(j+1)*Xbb(i)**(j-1)
end do
end do

goto 1



elseif (h.eq.-2) then
Pb=0
goto 1
end if





ifcv=0
do i=1,kbin
call Reg1D(Xb,Yb,Wb,kbin,h,p,xbb(i),pred,rango,kernel,ifcv)
pb(i)=pred(1)
!pb(i,2)=pred(2)
!pb(i,3)=pred(3)

end do

1 continue



xb(1:kbin)=xbb(1:kbin)
end subroutine












!********************************************
!********************************************




subroutine localtest_(F,X,Y,W,n,h0,h,nh,p,kbin,fact,nf,kernel,nboot,&
pcmax,pcmin,r,D,Ci,Cs,umatrix,level,nalfas)


!!DEC$ ATTRIBUTES DLLEXPORT::localtest
!!DEC$ ATTRIBUTES C, REFERENCE, ALIAS:'localtest_' :: localtest

implicit none
integer,parameter::kfino=1000
integer i,n,j,kbin,p,nf,F(n),fact(nf),iboot,ir,l,k,&
nh,nboot,kernel,r,index,posmin,posmax,nalfas
double precision X(n),Y(n),W(n),Waux(n),xb(kbin),pb(kbin,3,nf),&
u,h(nf),Pb_0(kbin,3),res(n),Pb_0boot(kbin,3,nboot),meanerr,P_0(n),Err(n),&
C(3,nf),xmin(nf),xmax(nf),pcmax(nf),pcmin(nf),Ci(nalfas),Cs(nalfas),&
Dboot(nboot),D,pmax,pasox,pasoxfino,icont(kbin,3,nf),xminc,xmaxc,h0,&
umatrix(n,nboot),level(nalfas)
!REAL(4) rand 
double precision, allocatable:: Yboot(:),muhatg(:),errg(:),errgboot(:),&
muhatgboot(:),Xfino(:),Pfino(:),p0(:,:),pred(:),pboot(:,:,:,:),cboot(:,:,:),&
media(:,:,:),sesgo(:,:,:)



allocate (errg(n),muhatg(n),Yboot(n),errgboot(n),muhatgboot(n),&
Xfino(kfino),Pfino(kfino),pred(n),pboot(kbin,3,nf,nboot),Cboot(3,nf,nboot),&
sesgo(kbin,3,nf),media(kbin,3,nf))



Xb=-1
Pb=-1

pasox=0


call GRID(X,W,n,Xb,kbin)
call GRID(X,W,n,Xfino,kfino)

pasox=Xb(2)-Xb(1)
pasoxfino=Xfino(2)-Xfino(1)



xmin=999999
xmax=-xmin
do i=1,n
 do j=1,nf
  if (W(i).gt.0) then
   if (X(i).le.xmin(j).and.F(i).eq.fact(j)) xmin(j)=X(i)
   if (X(i).ge.xmax(j).and.F(i).eq.fact(j)) xmax(j)=X(i)
  end if
 end do
end do



! estimacion curvas y derivadas
! *****************************


 if(nf.eq.1) then
  call rfast_h (X,Y,W,n,h0,p,Xb,Pb(1,1,1),kbin,kernel,nh)
  !evitamos predicciones fuera del rango de los datos
  do i=1,kbin
   if (Xb(i).lt.xmin(1).or.Xb(i).gt.xmax(1)+(xb(2)-xb(1))) Pb(i,1:3,1)=-1
  end do
 else




  call rfast_h (X,Y,W,n,h0,p,Xb,Pb_0(1,1),kbin,kernel,nh)  !efecto global

  call Interpola (Xb,Pb_0(1,1),kbin,X,P_0,n)
  res(1:n)=Y(1:n)-P_0(1:n)

  do j=1,nf !efectos parciales
   Waux=0
   do i=1,n
    if (F(i).eq.fact(j)) Waux(i)=W(i)
   end do
   call rfast_h (X,res,Waux,n,h(j),p,Xb,Pb(1,1,j),kbin,kernel,nh)
  
   do l=1,3
    do i=1,kbin
     Pb(i,l,j)=Pb_0(i,l)+Pb(i,l,j) !sumo efecto global y parcial
    end do
   end do

  !evitamos predicciones fuera del rango de los datos
   do i=1,kbin
    if (Xb(i).lt.xmin(j).or.Xb(i).gt.xmax(j)+(xb(2)-xb(1))) Pb(i,1:3,j)=-1
   end do
  end do
 end if












! Max de estimación, max de primera derivada
!********************************************

index=-1
C=-1

do j=1,nf

 do k=1,2
  pmax=-999
  call Interpola (Xb,Pb(1,k,j),kbin,Xfino,Pfino,kfino)
  do i=1,kfino
   if(xmin(j).le.xfino(i).and.xfino(i).le.xmax(j).and.Xfino(i).le.pcmax(j).and.Xfino(i).ge.pcmin(j)) then
    if (pfino(i).ne.-1.0.and.pfino(i).ge.pmax) then
     pmax=pfino(i)
     C(k,j)=Xfino(i)
     index=i
    end if
   end if
  end do

  if (C(k,j).ge.xmax(j)) then ! si se sale el máximo, escribe valor  muy grande
   C(k,j)=9999 
  end if

  if(index.ne.kfino) then
   if (index+1.le.kfino.and.xfino(index+1).ge.xmax(j)) then
    C(k,j)=9999
   end if
  end if
 
 end do



 !revisar

 do k=3,3
  C(k,j)=9999
  call Interpola (Xb,Pb(1,k,j),kbin,Xfino,Pfino,kfino)
  do i=2,kfino
   if (Xfino(i).gt.pcmin(j).and.Pfino(i).ne.-1.0.and.Pfino(i-1).ne.-1.0) then
    if (Pfino(i)*Pfino(i-1).lt.0) then
     C(k,j)=0.5*(Xfino(i)+Xfino(i-1))
     goto 1
    end if
   end if
 end do
  1      continue
 end do


end do











! vuelvo a eliminar los 9999 para que en el intervalo de confianza
! para la dif de maximos no aparezca el valor de -9982... 
! pongo el máx de la localidad en cada caso
!*****************************************************************


do k=1,3
 do j=1,nf
  if(C(k,j).eq.9999) C(k,j)=xmax(j)
 end do
end do

! ********************************************************





posmin=-1
posmax=-1

xminc=99999.999
xmaxc=-xminc
do j=1,nf
if (C(r+1,j).le.xminc) then
xminc=C(r+1,j)
posmin=j
end if

if (C(r+1,j).ge.xmaxc) then
xmaxc=C(r+1,j)
posmax=j
end if
end do

if(posmin.lt.posmax) then
D=(C(r+1,posmin)-C(r+1,posmax))
else
D=(C(r+1,posmax)-C(r+1,posmin))
end if










!Estimaciones piloto para bootstrap

allocate(p0(n,nf))

do j=1,nf
call Interpola (Xb,Pb(1,1,j),kbin,X,P0(1,j),n)
do i=1,n
if (X(i).lt.xmin(j).or.X(i).gt.xmax(j)) P0(i,j)=-1
end do
end do


do i=1,n
do j=1,nf
if (F(i).eq.fact(j)) pred(i)=p0(i,j)
end do
Err(i)=Y(i)-pred(i)
end do


!centro errores
meanerr=sum(Err(1:n))/n
do i=1,n
 Err(i)=Err(i)-meanerr
end do

deallocate (p0)

cboot=-1





do iboot=1,nboot
do i=1,n
  !u=RAND()    !wild bootstrap
  !call test_random(u)
  u=umatrix(i,iboot)
  ir=0
  IF (u.le.(5+sqrt(5.0))/10) ir=1
  if (ir.eq.1) then
   Yboot(i)=Pred(i)+err(i)*(1-sqrt(5.0))/2
  else
   Yboot(i)=pred(i)+err(i)*(1+sqrt(5.0))/2
  end if
end do


  call rfast_h(X,Yboot,W,n,h0,p,Xb,Pb_0boot(1,1,iboot),kbin,kernel,nh)
  call Interpola (Xb,Pb_0boot(1,1,iboot),kbin,X,P_0,n)
  res(1:n)=Yboot(1:n)-P_0(1:n)

  do j=1,nf !efectos parciales
   Waux=0
   do i=1,n
    if (F(i).eq.fact(j)) Waux(i)=W(i)
   end do
   call rfast_h (X,res,Waux,n,h(j),p,Xb,Pboot(1,1,j,iboot),kbin,kernel,nh)
   
   do l=1,3
    do i=1,kbin
     Pboot(i,l,j,iboot)=Pb_0boot(i,l,iboot)+Pboot(i,l,j,iboot) !sumo efecto global y parcial
    end do
   end do
  
   !evitamos predicciones fuera del rango de los datos
   do i=1,kbin
    if (Xb(i).lt.xmin(j).or.Xb(i).gt.xmax(j)+(xb(2)-xb(1))) Pboot(i,1:3,j,iboot)=-1
   end do
  end do
end do ! cierra iboot





! *************************************
! Recentro Bootstraps

! ************************************

  
media=0
icont=0
sesgo=0
do i=1,kbin
 do k=1,3
  do j=1,nf
   do l=1,nboot
    if(pboot(i,k,j,l).ne.-1) then 
     media(i,k,j)=media(i,k,j)+pboot(i,k,j,l) 
    else 
     media(i,k,j)=media(i,k,j)
     icont(i,k,j)=icont(i,k,j)+1
    end if
   end do
   media(i,k,j)=media(i,k,j)/nboot-icont(i,k,j)
   if(pb(i,k,j).ne.-1) sesgo(i,k,j)=pb(i,k,j)-media(i,k,j)
  end do
 end do
end do

do i=1,kbin
 do k=1,3
  do j=1,nf
   do l=1,nboot
    if(pboot(i,k,j,l).ne.-1) pboot(i,k,j,l)=pboot(i,k,j,l)+sesgo(i,k,j)
   end do
  end do
 end do
end do


!************************************





!!! calculo cboot 

cboot=-1

 ! punto de corte
 do iboot=1,nboot
  do j=1,nf
   do k=1,2
    pmax=-999
    call Interpola (Xb,Pboot(1,k,j,iboot),kbin,Xfino,Pfino,kfino)
    do i=1,kfino
     if(xmin(j).le.xfino(i).and.xfino(i).le.xmax(j).and.Xfino(i).le.pcmax(j).and.Xfino(i).ge.pcmin(j)) then
      if (pfino(i).ne.-1.0.and.pfino(i).ge.pmax) then
       pmax=pfino(i)
       Cboot(k,j,iboot)=Xfino(i)
       index=i !lo meto yo para saber en que punto se queda
      end if
     end if
    end do
   end do
  end do
 end do





! codigo para el 9999
! ********************

do k=1,2
 do j=1,nf
  do iboot=1,nboot
   if (Cboot(k,j,iboot).ge.xmax(j)) then ! esto lo meti yo, si se sale el máximo, fuera valor  muy grande
    Cboot(k,j,iboot)=9999 
   end if
   if (Cboot(k,j,iboot)+(Xfino(2)-Xfino(1)).ge.xmax(j)) then
    Cboot(k,j,iboot)=9999
   end if
  end do
 end do
end do

! *********************





! *************************************

! elimino de nuevo los 9999 de las bootstrap para poder hacer las diferencias con los intervalos bien
! para la estimacion y primera derivada,le pongo el m‡ximo de la localidad




do k=1,2
do j=1,nf
do iboot=1,nboot
if (Cboot(k,j,iboot).eq.9999) then ! esto lo meti yo, si se sale el máximo, fuera valor  muy grande
Cboot(k,j,iboot)=xmax(j) 
end if
end do
end do
end do






do iboot=1,nboot
xminc=99999.999
xmaxc=-xminc
do j=1,nf
if (Cboot(r+1,j,iboot).le.xminc) then
xminc=Cboot(r+1,j,iboot)
posmin=j
end if

if (Cboot(r+1,j,iboot).ge.xmaxc) then
xmaxc=Cboot(r+1,j,iboot)
posmax=j
end if
end do

if(posmin.lt.posmax) then
Dboot(iboot)=(Cboot(r+1,posmin,iboot)-Cboot(r+1,posmax,iboot))
else
Dboot(iboot)=(Cboot(r+1,posmax,iboot)-Cboot(r+1,posmin,iboot))
end if
end do


Ci=-1
Cs=-1

do i=1,nalfas
  call ICbootstrap_beta_per(Dboot,nboot,1-level(i),Ci(i),Cs(i)) 
end do

end subroutine





subroutine ICbootstrap_beta_per(X,nboot,beta,li,ls)
implicit none
integer nboot,nalfa
double precision X(nboot),li,ls,alfa(3),Q(3),beta

alfa(1)=beta/2
alfa(2)=0.5
alfa(3)=1-beta/2
nalfa=3
call quantile (X,nboot,alfa,nalfa,Q)

li=Q(1)!-Q(2)
ls=Q(3)!-Q(2)

end subroutine








subroutine globaltest_(F,X,Y,W,n,h0,h,nh,p,kbin,fact,nf,kernel,nboot,r,T,&
pvalor,umatrix)

!!DEC$ ATTRIBUTES DLLEXPORT::globaltest
!!DEC$ ATTRIBUTES C, REFERENCE, ALIAS:'globaltest_' :: globaltest

implicit none
integer i,z,n,j,kbin,p,nf,F(n),fact(nf),iboot,k,&
nh,nboot,kernel,r,pp
double precision X(n),Y(n),W(n),Waux(n),xb(kbin),pb(kbin,3,nf),&
h(nf),h0,hp(nf),pred1(kbin,nf),pred0(kbin),pol(n,nf),&
u,Tboot,T,pvalor,umatrix(n,nboot)
!REAL(4) rand 
double precision, allocatable:: Yboot(:),muhatg(:),errg(:),errgboot(:),&
muhatgboot(:),muhatg2(:)


allocate (errg(n),muhatg(n),Yboot(n),errgboot(n),muhatgboot(n),muhatg2(n))



Xb=-1
Pb=-1
call GRID(X,W,n,Xb,kbin)


!estimo efecto global
call rfast_h(X,Y,W,n,h0,p,Xb,Pb,kbin,kernel,nh)
call Interpola (Xb,Pb(1,1,1),kbin,X,muhatg,n)




do i=1,n
 errg(i)=Y(i)-muhatg(i)
end do

do i=1,kbin
 pred0(i)=Pb(i,r+1,1)
end do



! estimo efectos parciales
do j=1,nf
 Waux=0
 do i=1,n
  if (F(i).eq.fact(j)) Waux(i)=W(i)
 end do
 call rfast_h(X,errg,Waux,n,h(j),p,Xb,Pb,kbin,kernel,nh)
 do i=1,kbin
  pred1(i,j)=Pb(i,r+1,1)
 end do
end do





! estimo polinomios
hp=0 !ventana para pol


if(r.eq.1) pp=0 !grado pol, solo calcula medias
if(r.eq.2) pp=1


do j=1,nf
 Waux=0
 do i=1,n
  if (F(i).eq.fact(j)) Waux(i)=W(i)
 end do
 call rfast_h(X,errg,Waux,n,hp(j),pp,Xb,Pb,kbin,kernel,nh)
 call Interpola (Xb,Pb(1,1,1),kbin,X,pol(1,j),n)
end do

if(r.eq.0) pol=0

!para las bootstraps
!**********************************
do i=1,n
 do j=1,nf
  if(F(i).eq.fact(j)) muhatg2(i)=muhatg(i)+pol(i,j)
 end do
end do

errg(1:n)=Y(1:n)-muhatg2(1:n)
!**********************************




!Estadistico

T=0
do j=1,nf
do i=1,kbin
! T=T+abs(pred0(i)-pred1(i,j))
T=T+abs(pred1(i,j))
end do
end do






! Bootstrap


pvalor=0
do iboot=1,nboot
 do z=1,n
  !u=RAND()
  !call test_random(u)
  u=umatrix(z,iboot)
  if (u.le.(5.0+sqrt(5.0))/10) then
   Yboot(z)=muhatg2(z)+errg(z)*(1-sqrt(5.0))/2
  else
   Yboot(z)=muhatg2(z)+errg(z)*(1+sqrt(5.0))/2
  end if
end do


call rfast_h(X,Yboot,W,n,h0,p,Xb,Pb,kbin,kernel,nh)
call Interpola (Xb,Pb(1,1,1),kbin,X,muhatgboot,n)


do i=1,n
errgboot(i)=Yboot(i)-muhatgboot(i)
end do


do i=1,kbin
pred0(i)=Pb(i,r+1,1)
end do



do j=1,nf
Waux=0
do i=1,n
if (F(i).eq.fact(j)) Waux(i)=W(i)
end do
call rfast_h(X,errgboot,Waux,n,h(j),p,Xb,Pb,kbin,kernel,nh)

do i=1,kbin
pred1(i,j)=Pb(i,r+1,1)
end do
end do



Tboot=0
do k=1,nf
 do z=1,kbin
 ! Tboot=Tboot+abs(pred0(z)-pred1(z,k))
  Tboot=Tboot+abs(pred1(z,k))
 end do
end do

if(Tboot.gt.T) pvalor=pvalor+1

end do

pvalor=pvalor/nboot


!print *,pvalor



end subroutine










! !*************************************************
! !************************************************* propuesta para 4 estadisticos (no funciona)



! subroutine globaltest_(F,X,Y,W,n,h0,h,nh,p,kbin,fact,nf,kernel,nboot,r,T,&
! pvalor,umatrix)

! !!DEC$ ATTRIBUTES DLLEXPORT::globaltest
! !!DEC$ ATTRIBUTES C, REFERENCE, ALIAS:'globaltest_' :: globaltest

! implicit none
! integer i,z,n,j,kbin,p,nf,F(n),fact(nf),iboot,k,&
! nh,nboot,kernel,r,pp,icont,ii
! double precision X(n),Y(n),W(n),Waux(n),xb(kbin),pb(kbin,3,nf),&
! h(nf),h0,hp(nf),pred1(kbin,nf),pred0(kbin),pol(n,nf),&
! u,Tboot(4),pvalor(4),umatrix(n,nboot),h0i,hi(nf),hgi(nf),meanerr,T(4),&
! RSS0,RSS1,hg(nf)
! !REAL(4) rand 
! double precision, allocatable:: Yboot(:),muhatg(:),errg(:),errgboot(:),&
! muhatgboot(:),muhatg2(:),fpar(:,:),fpar_est(:),Xaux(:)


! allocate (errg(n),muhatg(n),Yboot(n),errgboot(n),muhatgboot(n),muhatg2(n),&
!   fpar_est(n),fpar(n,nf),Xaux(n))

! h0i = h0
! hi = h
! hgi = h0

! Xb=-1
! Pb=-1
! call GRID(X,W,n,Xb,kbin)


! !estimo efecto global
! call rfast_h(X,Y,W,n,h0,p,Xb,Pb,kbin,kernel,nh)
! call Interpola (Xb,Pb(1,1,1),kbin,X,muhatg,n)

! !print *, h0

! !print *, muhatg



! do i=1,n
!  errg(i)=Y(i)-muhatg(i)
! end do

! !do i=1,kbin
! ! pred0(i)=Pb(i,r+1,1)
! !end do



! ! estimo efectos parciales
! do j=1,nf
!  Waux=0
!  do i=1,n
!   if (F(i).eq.fact(j)) Waux(i)=W(i)
!  end do
!  call rfast_h(X,errg,Waux,n,h(j),p,Xb,Pb,kbin,kernel,nh)
!  do i=1,kbin
!   pred1(i,j)=Pb(i,r+1,1)
!  end do
!  call Interpola (Xb,Pb(1,1,1),kbin,X,fpar(1,j),n)
! end do


! do i=1,n
!  do j=1,nf
!   if(F(i).eq.fact(j)) fpar_est(i)=fpar(i,j)
!  end do
! end do

! ! !interpolamos efectos parciales para RSS
! ! icont=0
! !   do i=1,n
! !    if (F(i).eq.fact(j)) then
! !     icont=icont+1
! !     Xaux(icont)=X(i)
! !    end if
! !   end do
! !   call Interpola (Xb,Pb(1,1,1),kbin,Xaux,fpar,icont)
  
! !   ii=0
! !   do i=1,n
! !   if (F(i).eq.fact(j)) then
! !    ii=ii+1
! !    fpar_est(i)=fpar(ii)
! !   end if
! !   end do

! ! end do




! !print *, h(1), h(2)


! ! estimo polinomios
! hp=0 !ventana para pol


! if(r.eq.1) pp=0 !grado pol, solo calcula medias
! if(r.eq.2) pp=1


! do j=1,nf
!  Waux=0
!  do i=1,n
!   if (F(i).eq.fact(j)) Waux(i)=W(i)
!  end do
!  call rfast_h(X,errg,Waux,n,hp(j),pp,Xb,Pb,kbin,kernel,nh)
!  call Interpola (Xb,Pb(1,1,1),kbin,X,pol(1,j),n)
! end do

! if(r.eq.0) pol=0

! !para las bootstraps
! !**********************************
! do i=1,n
!  do j=1,nf
!   if(F(i).eq.fact(j)) muhatg2(i)=muhatg(i)+pol(i,j)
!  end do
! end do

! errg(1:n)=Y(1:n)-muhatg2(1:n)
! !**********************************

! !centro errores
! meanerr=sum(errg(1:n))/n
! do i=1,n
!  errg(i)=errg(i)-meanerr
! end do



! !Estadistico

! T(1)=0
! do j=1,nf
! do i=1,kbin
! !do i=1,n
! ! T=T+abs(pred0(i)-pred1(i,j))
! if(Xb(i).ge.-1.and.Xb(i).le.1) T(1)=T(1)+abs(pred1(i,j))
! !if(X(i).ge.-1.5.and.X(i).le.1.5) T(1)=T(1)+abs(fpar(i,j))
! end do
! end do



! ! para la g
! T(2)=0
! do j=1,nf
!  Waux=0
!  do i=1,n
!   if (F(i).eq.fact(j)) Waux(i)=W(i)
!  end do
!  call rfast_h(X,errg,Waux,n,hg(j),p,Xb,Pb,kbin,kernel,nh)
!  do i=1,kbin
!    if(Xb(i).ge.-2.and.Xb(i).le.2) T(2)=T(2)+abs(Pb(i,1,1))
! end do
! end do



! RSS0=0
! RSS1=0
! do i=1,n
!  RSS0=RSS0+(Y(i)-muhatg2(i))**2
!  RSS1=RSS1+(Y(i)- muhatg(i) - fpar_est(i) )**2
! end do
! T(3)=RSS0-RSS1
! T(4)=T(3)/RSS1








! ! Bootstrap


! pvalor=0
! do iboot=1,nboot
!  do z=1,n
!   !u=RAND()
!   !call test_random(u)
!   u=umatrix(z,iboot)
!   if (u.le.(5.0+sqrt(5.0))/10) then
!    Yboot(z)=muhatg2(z)+errg(z)*(1-sqrt(5.0))/2
!   else
!    Yboot(z)=muhatg2(z)+errg(z)*(1+sqrt(5.0))/2
!   end if
! end do

! !h0 = h0i
! !h = hi
! !hg = h0i

! call rfast_h(X,Yboot,W,n,h0,p,Xb,Pb,kbin,kernel,nh)
! call Interpola (Xb,Pb(1,1,1),kbin,X,muhatgboot,n)


! do i=1,n
! errgboot(i)=Yboot(i)-muhatgboot(i)
! end do


! do i=1,kbin
! pred0(i)=Pb(i,r+1,1)
! end do


! !efectos parciales
! do j=1,nf
! Waux=0
! do i=1,n
! if (F(i).eq.fact(j)) Waux(i)=W(i)
! end do
! call rfast_h(X,errgboot,Waux,n,h(j),p,Xb,Pb,kbin,kernel,nh)
! do i=1,kbin
! pred1(i,j)=Pb(i,r+1,1)
! end do
! call Interpola (Xb,Pb(1,1,1),kbin,X,fpar(1,j),n) !interpolamos efectos parciales para RSS
! end do

! do i=1,n
!  do j=1,nf
!   if(F(i).eq.fact(j)) fpar_est(i)=fpar(i,j)
!  end do
! end do






! !polinomios


! ! estimo polinomios
! hp=0 !ventana para pol


! if(r.eq.1) pp=0 !grado pol, solo calcula medias
! if(r.eq.2) pp=1


! do j=1,nf
!  Waux=0
!  do i=1,n
!   if (F(i).eq.fact(j)) Waux(i)=W(i)
!  end do
!  call rfast_h(X,errgboot,Waux,n,hp(j),pp,Xb,Pb,kbin,kernel,nh)
!  call Interpola (Xb,Pb(1,1,1),kbin,X,pol(1,j),n)
! end do

! if(r.eq.0) pol=0


! !**********************************
! do i=1,n
!  do j=1,nf
!   if(F(i).eq.fact(j)) muhatg2(i)=muhatgboot(i)+pol(i,j)
!  end do
! end do

! errgboot(1:n)=Yboot(1:n)-muhatg2(1:n)
! !**********************************







! Tboot(1)=0
! do k=1,nf
!  do z=1,kbin
! !  do z=1,n
!  ! Tboot=Tboot+abs(pred0(z)-pred1(z,k))
!   if(Xb(z).ge.-1.and.Xb(z).le.1) Tboot(1)=Tboot(1)+abs(pred1(z,k))
! !   if(X(z).ge.-1.and.X(z).le.1) Tboot(1)=Tboot(1)+abs(fpar(z,k))
!  end do
! end do





! ! para la g
! Tboot(2)=0
! do j=1,nf
!  Waux=0
!  do i=1,n
!   if (F(i).eq.fact(j)) Waux(i)=W(i)
!  end do
!  call rfast_h(X,errgboot,Waux,n,hg(j),p,Xb,Pb,kbin,kernel,nh)
!  do i=1,kbin
!    if(Xb(i).ge.-2.and.Xb(i).le.2) Tboot(2)=Tboot(2)+abs(Pb(i,1,1))
!      ! if(Xb(i).ge.-2.and.Xb(i).le.2) T(2)=T(2)+abs(Pb(i,1,1))
! end do
! end do

! RSS0=0
! RSS1=0
! do i=1,n
!  RSS0=RSS0+(Yboot(i)-muhatg2(i))**2
!  RSS1=RSS1+(Yboot(i)- muhatgboot(i)-fpar_est(i) )**2
! end do
! Tboot(3)=RSS0-RSS1
! Tboot(4)=Tboot(3)/RSS1



! do j=1,4
! if(Tboot(j).gt.T(j)) pvalor(j)=pvalor(j)+1
! end do


! end do

! pvalor=pvalor/nboot


! !print *,pvalor



! end subroutine













!**********************************************
!**********************************************





subroutine frfast_(F,X,Y,W,n,h0,h,p,kbin,fact,&
nf,nboot,xb,pb,li,ls,dif,difi,difs,model,&
 c,cs,ci,difc,difcs,difci,pboot,pcmin,pcmax,cboot,&
kernel,nh,a,ainf,asup,b,binf,bsup,ipredict,&
predict,predictl,predictu,umatrix)


!!DEC$ ATTRIBUTES DLLEXPORT::frfast
!!DEC$ ATTRIBUTES C, REFERENCE, ALIAS:'frfast_' :: frfast

implicit none
integer,parameter::kfino=1000
integer n,i,j,kbin,p,nf,F(n),fact(nf),iboot,ir,l,k,m,kernel,&
nboot,index,pasox,pasoxfino,model,&
icont(kbin,3,nf),nh,ipredict,II(n)
double precision x(n),y(n),W(n),Waux(n),xfino(kfino),Li(kbin,3,nf),ls(kbin,3,nf),P_0(n),&
Pb(kbin,3,nf),h(nf),Xb(kbin),xmin(nf),Pb_0(kbin,3),&
xmax(nf),Err(n),Dif(kbin,3,nf,nf),Difi(kbin,3,nf,nf),Difs(kbin,3,nf,nf),&
C(3,nf),Pfino(kfino),Ci(3,nf),Cs(3,nf),pboot(kbin,3,nf,nboot),&
DifC(3,nf,nf),DifCI(3,nf,nf),DifCs(3,nf,nf),pmax,&
u,pcmax(nf),pcmin(nf),Cboot(3,nf,nboot),a(nf),b(nf),aboot(nf,nboot),bboot(nf,nboot),&
asup(nf),ainf(nf),bsup(nf),binf(nf),predict(n,3,nf),predictu(n,3,nf),predictl(n,3,nf),&
res(n),Pb_0boot(kbin,3,nboot),h0,meanerr,umatrix(n,nboot)
double precision,allocatable::Pred(:),P0(:,:),Yboot(:),&
bi(:,:,:),bs(:,:,:),Vb(:,:),&
Difbi(:,:,:,:),Difbs(:,:,:,:),V(:),pboota(:,:,:,:),&
sesgo(:,:,:),media(:,:,:),Xboot(:)

!REAL(4) rand 



!***************************
!kernel: nucleo
!si kernel=1  epanechikow
!si kernel=2  trianglar
!si kernel=3  gaussiano
!*********************************


allocate (Pred(n),Yboot(n),pboota(kbin,3,nf,nboot),Xboot(n))

allocate (bi(kbin,3,nf),bs(kbin,3,nf),Vb(kbin,nboot),&
Difbi(kbin,3,nf,nf),Difbs(kbin,3,nf,nf),sesgo(kbin,3,nf),&
media(kbin,3,nf))


if (kbin.le.nboot) then
 allocate (V(nboot))
else
 allocate(V(kbin))
end if



Xb=-1
Pb=-1

pasox=0


call GRID(X,W,n,Xb,kbin)
call GRID(X,W,n,Xfino,kfino)

pasox=floor(Xb(2)-Xb(1))
pasoxfino=floor(Xfino(2)-Xfino(1))



xmin=999999
xmax=-xmin
do i=1,n
 do j=1,nf
  if (W(i).gt.0) then
   if (X(i).le.xmin(j).and.F(i).eq.fact(j)) xmin(j)=X(i)
   if (X(i).ge.xmax(j).and.F(i).eq.fact(j)) xmax(j)=X(i)
  end if
 end do
end do



! estimacion curvas y derivadas
! *****************************

if (model.eq.1.) then
 if(nf.eq.1) then
  call rfast_h (X,Y,W,n,h0,p,Xb,Pb(1,1,1),kbin,kernel,nh)
  !evitamos predicciones fuera del rango de los datos
  do i=1,kbin
   if (Xb(i).lt.xmin(1).or.Xb(i).gt.xmax(1)+(xb(2)-xb(1))) Pb(i,1:3,1)=-1
  end do
 else
  call rfast_h (X,Y,W,n,h0,p,Xb,Pb_0(1,1),kbin,kernel,nh)  !efecto global
  call Interpola (Xb,Pb_0(1,1),kbin,X,P_0,n)
  res(1:n)=Y(1:n)-P_0(1:n)




Pb=0
do j=1,nf !efectos parciales
   Waux=0
   do i=1,n
    if (F(i).eq.fact(j)) Waux(i)=W(i)
   end do
   call rfast_h (X,res,Waux,n,h(j),p,Xb,Pb(1,1,j),kbin,kernel,nh)
   do l=1,3
    do i=1,kbin
     Pb(i,l,j)=Pb_0(i,l)+Pb(i,l,j) !sumo efecto global y parcial
    end do
   end do

  !evitamos predicciones fuera del rango de los datos
   do i=1,kbin
    if (Xb(i).lt.xmin(j).or.Xb(i).gt.xmax(j)+(xb(2)-xb(1))) Pb(i,1:3,j)=-1
   end do
  end do
 end if
end if






if (model.eq.2) then
 do j=1,nf
  Waux=0
  do i=1,n
   if (F(i).eq.fact(j)) Waux(i)=W(i)
  end do
  call Rfast0_sinbinning(X,Y,n,Waux,Xb,Pb(1,1,j),kbin,a(j),b(j))
  !evitamos predicciones fuera del rango de los datos
  do i=1,kbin
   if (Xb(i).lt.xmin(j).or.Xb(i).gt.xmax(j)+(xb(2)-xb(1))) Pb(i,1:3,j)=-1
  end do
 end do
end if






! Max de estimación, max de primera derivada
!********************************************

index=-1
C=-1

do j=1,nf

 do k=1,2
  pmax=-999
  call Interpola (Xb,Pb(1,k,j),kbin,Xfino,Pfino,kfino)
  do i=1,kfino
   if(xmin(j).le.xfino(i).and.xfino(i).le.xmax(j).and.Xfino(i).le.pcmax(j).and.Xfino(i).ge.pcmin(j)) then
    if (pfino(i).ne.-1.0.and.pfino(i).ge.pmax) then
     pmax=pfino(i)
     C(k,j)=Xfino(i)
     index=i
    end if
   end if
  end do

  if (C(k,j).ge.xmax(j)) then ! si se sale el máximo, escribe valor  muy grande
   C(k,j)=9999 
  end if



  if(index.ne.kfino) then
   if (index+1.le.kfino.and.xfino(index+1).ge.xmax(j)) then
    C(k,j)=9999
   end if
  end if
 
 end do



 !revisar

 do k=3,3
  C(k,j)=9999
  call Interpola (Xb,Pb(1,k,j),kbin,Xfino,Pfino,kfino)
  do i=2,kfino
   if (Xfino(i).gt.pcmin(j).and.Pfino(i).ne.-1.0.and.Pfino(i-1).ne.-1.0) then
    if (Pfino(i)*Pfino(i-1).lt.0) then
     C(k,j)=0.5*(Xfino(i)+Xfino(i-1))
     goto 1
    end if
   end if
 end do
  1      continue
 end do


end do





!diferencias estimaciones
!************************


Dif=-1
do i=1,kbin
 do j=1,3
  do k=1,nf
   do l=k+1,nf               
    if (pb(i,j,k).ne.-1.and.pb(i,j,l).ne.-1.0) &
    Dif(i,j,k,l)=pb(i,j,k)-pb(i,j,l)
   end do
  end do 
 end do
end do










! vuelvo a eliminar los 9999 para que en el intervalo de confianza
! para la dif de maximos no aparezca el valor de -9982... 
! pongo el máx de la localidad en cada caso
!*****************************************************************


do k=1,3
 do j=1,nf
  if(C(k,j).eq.9999) C(k,j)=xmax(j)
 end do
end do

! ********************************************************









! diferencias entre c
! ******************* 

DifC=-1
do j=1,3
 do k=1,nf
  do l=k+1,nf               
   if (C(j,k).ne.-1.and.C(j,l).ne.-1.0) &
   DifC(j,k,l)=C(j,l)-C(j,k)
  end do
 end do 
end do










!  BOOTSTRAP
! *************



! estimaciones piloto

allocate(p0(n,nf))

do j=1,nf
 call Interpola (Xb,Pb(1,1,j),kbin,X,P0(1,j),n)
 do i=1,n
  if (X(i).lt.xmin(j).or.X(i).gt.xmax(j)) P0(i,j)=-1
 end do
end do

do i=1,n
 do j=1,nf
  if (F(i).eq.fact(j)) pred(i)=p0(i,j)
 end do
 Err(i)=Y(i)-pred(i)
end do

!centro errores
meanerr=sum(Err(1:n))/n
do i=1,n
 Err(i)=Err(i)-meanerr
end do

deallocate (p0)



Cboot=-1.0

! replicas bootstrap

if (nboot.gt.0) then

!if(seed.ne.-1) call srand(seed) va desde fuera

do iboot=1,nboot

 if (model.eq.2) call Sample_Int(n,n,II,umatrix(1,iboot))

do i=1,n
 if(model.eq.1) then
  !u=RAND()    !wild bootstrap
  !call test_random(u)
  u=umatrix(i,iboot)
  ir=0
  IF (u.le.(5+sqrt(5.0))/10) ir=1
  if (ir.eq.1) then
   Yboot(i)=Pred(i)+err(i)*(1-sqrt(5.0))/2
  else
   Yboot(i)=pred(i)+err(i)*(1+sqrt(5.0))/2
  end if
 else
  Yboot(i)=Y(II(i)) !bootstrap simple
  Xboot(i)=X(II(i))
 end if
end do




if (model.eq.1) then
 if(nf.eq.1) then
  call rfast_h (X,Yboot,W,n,h0,p,Xb,Pboot(1,1,1,iboot),kbin,kernel,nh) 
  !evitamos predicciones fuera del rango de los datos
  do i=1,kbin
   if (Xb(i).lt.xmin(1).or.Xb(i).gt.xmax(1)+(xb(2)-xb(1))) Pboot(i,1:3,1,iboot)=-1
  end do
 else
  call rfast_h(X,Yboot,W,n,h0,p,Xb,Pb_0boot(1,1,iboot),kbin,kernel,nh)
  call Interpola (Xb,Pb_0boot(1,1,iboot),kbin,X,P_0,n)
  res(1:n)=Yboot(1:n)-P_0(1:n)

  do j=1,nf !efectos parciales
   Waux=0
   do i=1,n
    if (F(i).eq.fact(j)) Waux(i)=W(i)
   end do
   call rfast_h (X,res,Waux,n,h(j),p,Xb,Pboot(1,1,j,iboot),kbin,kernel,nh)
   
   do l=1,3
    do i=1,kbin
     Pboot(i,l,j,iboot)=Pb_0boot(i,l,iboot)+Pboot(i,l,j,iboot) !sumo efecto global y parcial
    end do
   end do
  
   !evitamos predicciones fuera del rango de los datos
   do i=1,kbin
    if (Xb(i).lt.xmin(j).or.Xb(i).gt.xmax(j)+(xb(2)-xb(1))) Pboot(i,1:3,j,iboot)=-1
   end do
  end do
 end if
end if




if (model.eq.2) then
 do j=1,nf
  Waux=0
  do i=1,n
   if (F(i).eq.fact(j)) Waux(i)=W(i)
  end do
  call Rfast0_sinbinning(Xboot,Yboot,n,Waux,Xb,Pboot(1,1,j,iboot),kbin,aboot(j,iboot),bboot(j,iboot))
  !evitamos predicciones fuera del rango de los datos
  do i=1,kbin
   if (Xb(i).lt.xmin(j).or.Xb(i).gt.xmax(j)+(xb(2)-xb(1))) Pboot(i,1:3,j,iboot)=-1
  end do
 end do
end if


end do  ! cierra iboot








! *************************************
! Recentro Bootstraps

! ************************************

  
media=0
icont=0
sesgo=0
do i=1,kbin
 do k=1,3
  do j=1,nf
   do l=1,nboot
    if(pboot(i,k,j,l).ne.-1) then 
     media(i,k,j)=media(i,k,j)+pboot(i,k,j,l) 
    else 
     media(i,k,j)=media(i,k,j)
     icont(i,k,j)=icont(i,k,j)+1
    end if
   end do
   media(i,k,j)=media(i,k,j)/nboot-icont(i,k,j)
   if(pb(i,k,j).ne.-1) sesgo(i,k,j)=pb(i,k,j)-media(i,k,j)
  end do
 end do
end do

do i=1,kbin
 do k=1,3
  do j=1,nf
   do l=1,nboot
    if(pboot(i,k,j,l).ne.-1) pboot(i,k,j,l)=pboot(i,k,j,l)+sesgo(i,k,j)
   end do
  end do
 end do
end do


!************************************





! Intervalos de confianza 
! parametros modelo alometrico
!********************************

if (model.eq.2) then

 do k=1,nf
  do l=1,nboot
   V(l)=aboot(k,l)
   if (V(l).eq.-1) goto 100
  end do
  call ICbootstrap(a(k),V,nboot,ainf(k),asup(k))
  100 continue
 end do 


 do k=1,nf
  do l=1,nboot
   V(l)=bboot(k,l)
   if (V(l).eq.-1) goto 13
  end do
  call ICbootstrap(b(k),V,nboot,binf(k),bsup(k))
  13 continue
 end do 
end if

!************************************












!***********************************


! estimo Cboot 


if (model.eq.1) then
 cboot=-1

 ! punto de corte
 do iboot=1,nboot
  do j=1,nf
   do k=1,2
    pmax=-999
    call Interpola (Xb,Pboot(1,k,j,iboot),kbin,Xfino,Pfino,kfino)
    do i=1,kfino
     if(xmin(j).le.xfino(i).and.xfino(i).le.xmax(j).and.Xfino(i).le.pcmax(j).and.Xfino(i).ge.pcmin(j)) then
      if (pfino(i).ne.-1.0.and.pfino(i).ge.pmax) then
       pmax=pfino(i)
       Cboot(k,j,iboot)=Xfino(i)
       index=i !lo meto yo para saber en que punto se queda
      end if
     end if
    end do
   end do
  end do
 end do

end if





! codigo para el 9999
! ********************

do k=1,2
 do j=1,nf
  do iboot=1,nboot
   if (Cboot(k,j,iboot).ge.xmax(j)) then ! esto lo meti yo, si se sale el máximo, fuera valor  muy grande
    Cboot(k,j,iboot)=9999 
   end if
   if (Cboot(k,j,iboot)+(Xfino(2)-Xfino(1)).ge.xmax(j)) then
    Cboot(k,j,iboot)=9999
   end if
  end do
 end do
end do

! *********************









else

li=-1
ls=-1


bi=-1
bs=-1
ci=-1
cs=-1
difi=-1
difs=-1

difci=-1
difcs=-1
end if






! intervalos de confianza
! ***********************

li=-1
ls=-1
do i=1,kbin
 do j=1,3
  do k=1,nf
   do l=1,nboot
    V(l)=pboot(i,j,k,l)
    if (V(l).eq.-1) goto 11
   end do
   call ICbootstrap(pb(i,j,k),V,nboot,li(i,j,k),ls(i,j,k))
   11 continue
  end do 
 end do
end do



! bandas de confianza
! ********************

bi=-1
bs=-1
do j=1,3
 do k=1,nf
  do i=1,kbin
   V(i)=pb(i,j,k)
   do l=1,nboot
    Vb(i,l)=pboot(i,j,k,l)
   end do
  end do
  call Banda(V,Vb,kbin,nboot,bi(1,j,k),bs(1,j,k))
 end do
end do







! prediccion
! **********

if(ipredict.eq.1) then
 do j=1,3
  do k=1,nf
   call Interpola (Xb,Pb(1,j,k),kbin,X,Predict(1,j,k),n)
   call Interpola (Xb,li(1,j,k),kbin,X,Predictl(1,j,k),n)
   call Interpola (Xb,ls(1,j,k),kbin,X,Predictu(1,j,k),n)
  end do
 end do
end if


!***********













! AHORA LAS DIFERENCIAS
Difi=-1
Difs=-1
do i=1,kbin
do j=1,3
do k=1,nf
do l=k+1,nf               
do m=1,nboot
V(m)=pboot(i,j,k,m)-pboot(i,j,l,m)
if (pboot(i,j,k,m).eq.-1.0.or.&
pboot(i,j,l,m).eq.-1.0) goto 12
end do
if (Dif(i,j,k,l).ne.-1.0) then
call ICbootstrap(Dif(i,j,k,l),V,nboot,&
Difi(i,j,k,l),Difs(i,j,k,l))
end if
12              continue
end do
end do 
end do
end do








!! BANDA DE CONFIANZA



Difbi=-1
Difbs=-1

do j=1,3
do k=1,nf
do l=k+1,nf               
do i=1,kbin
V(i)=Dif(i,j,k,l)
do m=1,nboot
Vb(i,m)=pboot(i,j,k,m)-pboot(i,j,l,m)
if (pboot(i,j,k,m).eq.-1.0.or.&
pboot(i,j,l,m).eq.1-0) Vb(i,m)=-1.0
end do
end do
call Banda(V,Vb,kbin,nboot,Difbi(1,j,k,l),Difbs(1,j,k,l))
end do
end do 
end do





Ci=-1
Cs=-1

do i=1,3
do j=1,nf
if (C(i,j).ne.-1.0) then
do k=1,nboot
V(k)=Cboot(i,j,k)
if (V(k).eq.-1.0) goto 1222
end do

call ICbootstrap(C(i,j),V,nboot,Ci(i,j),Cs(i,j)) 
1222          continue
end if
end do
end do








! *************************************

! elimino de nuevo los 9999 de las bootstrap para poder hacer las diferencias con los intervalos bien
! para la estimacion y primera derivada,le pongo el m‡ximo de la localidad




do k=1,2
do j=1,nf
do iboot=1,nboot
if (Cboot(k,j,iboot).eq.9999) then ! esto lo meti yo, si se sale el máximo, fuera valor  muy grande
Cboot(k,j,iboot)=xmax(j) 
end if
end do
end do
end do






!*************************************

DifCi=-1
DifCs=-1

do i=1,3
do j=1,nf
do k=j+1,nf
V=0
if (C(i,j).ne.-1.0.and.C(i,k).ne.-1.0) then

do l=1,nboot
V(l)=Cboot(i,k,l)-Cboot(i,j,l)
if (Cboot(i,j,l).eq.-1.0.or.&
Cboot(i,k,l).eq.-1.0) goto 23
end do

call ICbootstrap(DifC(i,j,k),V,nboot,&
DifCi(i,j,k),DifCs(i,j,k)) 
23 continue
end if
end do
end do
end do









end    subroutine









subroutine Sample_Int(n,size,II,uvector)
implicit none
integer n,size,II(n),i
double precision u, uvector(n)
!real rand
do i=1,size
!II(i)=1+rand()*n
!call test_random(u)
u=uvector(i)
II(i)=floor(1+u*n)
if (ii(i).le.1) ii(i)=1
if (ii(i).ge.n) ii(i)=n
end do
end





!*********************************************************
!		
!Subroutine RFAST_H
!
!* h: ventana, selección por cv (h=-1). Valores de 0 a 1.
!* kernel: tipo de nucleo (1=epanech, 2=triang, 3=gaussian)
!* nh: grid de busqueda de ventanas, de 0 a 1.
!* p: grado del polinomio
!
!*********************************************************


subroutine rfast_h(X,Y,W,n,h,p,Xb,Pb,kbin,kernel,nh)
implicit none
integer n,i,j,kbin,p,nh,kernel
double precision x(n),y(n),W(n),Xb(kbin),Yb(kbin),Wb(kbin),&
Pb(kbin,3),h,&
rango,hmin,hmax,beta(10),xbb(kbin),pred(8)


double precision, allocatable::ls(:,:),li(:,:)

allocate(Li(kbin,3),Ls(kbin,3))


!if (Xb(1).eq.-1) 
!call GRID(X,W,n,Xb,kbin) !lo comento porque sino no estima en los mismos
!nodos para cada nivel


!call Grid1d(X,W,n,Xb,kbin)
call Binning(X,Y,n,W,Xb,Yb,Wb,kbin)




rango=Xb(kbin)-Xb(1)
hmin=0
hmax=1
!nh=15 !100

! Selección de las ventanas por CV

if (h.eq.-1)  then
call Ventana1D(Xb,Yb,Wb,kbin,h,p,hmin,hmax,nh,rango,kernel)
elseif(h.eq.0) then
call Reglineal (Xb,Yb,Wb,kbin,p,Beta)
do i=1,kbin
Pb(i,1)=beta(1)
Pb(i,2)=0
Pb(i,3)=0 !si h=0 la segunda derivada es 0
do j=1,p
pb(i,1)=pb(i,1)+beta(j+1)*Xb(i)**j
pb(i,2)=pb(i,2)+p*beta(j+1)*Xb(i)**(j-1)
end do
end do
goto 1
elseif (h.eq.-2) then
Pb=0
goto 1
end if

xbb=xb

do i=1,kbin
call Reg1D(Xb,Yb,Wb,kbin,h,p,xbb(i),pred,rango,kernel,0)
pb(i,1)=pred(1)
pb(i,2)=pred(2)
pb(i,3)=pred(3)
end do

1 continue
end subroutine















!***************************************************
!		
!		VENTANA1D
!
!* h: ventana, selección por cv (h=-1). Valores de 0 a 1.
!* kernel: tipo de nucleo (1=epanech, 2=triang, 3=gaussian)
!* nh: grid de busqueda de ventanas, de 0 a 1.
!***************************************************



subroutine Ventana1D(X,Y,W,n,h,p,hmin,hmax,nh,rango,kernel)
implicit none
integer i,icont,p,n,ih,nh,ih2,Err(nh),kernel
double precision x(n),Y(n),h,hmin,hmax,&
pred(8),W(n),Wnodo(n),hgrid(nh),ErrH(5000),sumW,rango,&
VT,sumy,sumy2,maxr2,minr2
double precision,allocatable::ErrCV(:,:),Predh(:,:)
integer,external::which_min
allocate(ErrCV(n,nh),Predh(n,nh))

! Establécense o grid de ventanas de búsqueda
do ih=1,nh
hgrid(ih)=hmin+(ih-1)*(hmax-hmin)/(nh-1)
end do


! Para cada punto fanse as estimacións por CV para cada unha das ventanas
icont=1000

Err=0
do ih=nh,1,-1 !bucle al reves
do i=1,n
wnodo=w
if(i.ne.1) Wnodo(i-1)=0
Wnodo(i)=0
if(i.ne.n) Wnodo(i+1)=0
call Reg1D(X,Y,Wnodo,n,hgrid(ih),p,X(i),pred,rango,kernel,1)
PredH(i,ih)=pred(1)
if (pred(1).eq.-1.0) then
do ih2=ih,1,-1  !bucle al reves
Err(ih2)=1
end do
goto 3333
end if
end do
end do

3333 continue

! Calcúlanse os erros (globais) obtidos para cada ventana. Para elo calcúlase
! o erro cadrático medio ponderado polos pesos W iniciais

ErrH=9e9


do ih=1,nh
if (Err(ih).eq.0) then
sumw=0
ErrH(ih)=0
do i=1,n
sumw=sumw+W(i)
ErrH(ih)=ErrH(ih)+W(i)*(Y(i)-PredH(i,ih))**2
end do
ErrH(ih)=ErrH(ih)/sumw
end if
end do

! Xa calculados os erros para cada ventana selecciónase a ventana óptima
ih=which_min(ErrH,nh)
h= hgrid(ih)

!lo comente para el paquete
!open (1,file='errores.dat')
!do i=1,nh
!	write (1,'(100(f20.7,1x))')hgrid(i),ErrH(i),Errh(ih)-Errh(i)
!end do
!
!close(1)

! A continuación escríbese un resume dos erros obtidos. O ficheiro ten 3 columnas:
! Ventana; error absoluto: % de incremento de erro en relación á ventana óptima
! (lóxicamente, na última columna a ventana óptima terá un valor de 0) 


sumy=0
sumy2=0
sumw=0
do i=1,n
sumw=sumw+W(i)
sumy=sumy+W(i)*Y(i)
sumy2=sumy2+W(i)*Y(i)**2
end do

vt=(sumy2/sumw)-(sumy/sumw)**2


do i=1,nh
if (errh(i).ne.9e9) then
Errh(i)=(vT-ErrH(i))/Vt   ! calcula el r2
else
Errh(i)=0
end if
end do


minr2=9e9
maxr2=-minr2
do i=1,nh
if (Errh(i).gt.0) then
minr2=min(Errh(i),minr2)
maxr2=max(Errh(i),maxr2)
end if
end do



!goto 11
!lo comente para el paquete
!open (1,file='ventanas2.dat')
!do i=1,nh
!	write (1,'(100(f20.7,1x))') hgrid(i),ErrH(i),Errh(ih)-Errh(i)
!end do
!close(1)
!11 continue




!do i=nh,1,-1
!if (Errh(i)+((maxr2-minr2)*0.05).ge.Errh(ih)) then  ! hacemos rango y luego el 10% de ese valor
!	h=hgrid(i)
!	goto 33
!end if
!end do


!33 continue


deallocate(ErrCV,Predh)
end 






!***************************************************
!  Subroutine  REG1D  (estimación en un unico punto)
!
! kernel: nucleo (1=epa, 2=triang, 3=gaussian)
!
!****************************************************


subroutine Reg1D(X,Y,W,n,h,p,x0,pred,rango,kernel,ifcv)
implicit none 
integer i,j,icont,p,iopt,ier,n,kernel,ifcv
double precision x(n),Y(n),h,waux,Beta(10),Sterr(20),se,r2,&
pred(8),W(n),x0,rango,h2,u,pred2
double precision,allocatable::Vx(:),Vy(:),WW(:),XX(:,:)
allocate(Vx(n),Vy(n),WW(n))

pred=-1

h2=h
!345 continue

if (0.le.h2) then
!3 continue
!tanh=sind(-h2*.9)/cosd(-h2*0.9)
!tanh=sin(-h2*.9*(pi/180)) / cos(-h2*0.9*(pi/180))

icont=0
do i=1,n
u=((X(i)-x0)/rango) /h2 
if (W(i).gt.0) then
 
if(ifcv.eq.1.and.u.eq.0) then

waux=0

else 
if(kernel.eq.1.and.abs(u).le.1) then
waux=W(i) * ( (0.75* (1-(u**2))))
elseif(kernel.eq.2.and.abs(u).le.1) then
waux= W(i) * (1-(abs(u)))
elseif(kernel.eq.3) then
waux=W(i)*( (1/sqrt(2*3.1415927)) * dexp( -0.5*(u**2) ) ) 
else 
waux=W(i)*0.0
end if
end if

if (waux.gt.0) then
icont=icont+1
Vx(icont)=X(i)-x0
Vy(icont)=Y(i)
WW(icont)=waux
end if
end if
end do

if (icont.gt.6) then
allocate (XX(icont,4))
do i=1,icont
do j=1,p
XX(i,j)=Vx(i)**j
end do
end do
iopt=1
call WRegresion_Javier(XX,Vy,WW,icont,p,beta,sterr,se,r2,iopt,ier)
pred(1)=beta(1)
pred(2)=beta(2)
pred(3)=beta(3)
pred(4)=sterr(1)
pred(5)=sterr(2)
pred(6)=sterr(3)
pred(7)=r2
pred(8)=ier
deallocate(XX)
if (ier.ne.0)  then
pred=-1
goto 445
end if
else
pred=-1
goto 445
end if
else
continue

end if


445 continue
deallocate(Vx,Vy,WW)
pred2=pred(2)
end






integer function which_min(X,n)
implicit none
integer n,i
double precision X(n),aux

aux=X(1)
which_min=1
do i=2,n
if (X(i).le.aux) then
aux=X(i)
which_min=i
end if
end do
end







MODULE lsq

!  Module for unconstrained linear least-squares calculations.
!  The algorithm is suitable for updating LS calculations as more
!  data are added.   This is sometimes called recursive estimation.
!  Only one dependent variable is allowed.
!  Based upon Applied Statistics algorithm AS 274.
!  Translation from Fortran 77 to Fortran 90 by Alan Miller.
!  A function, VARPRD, has been added for calculating the variances
!  of predicted values, and this uses a subroutine BKSUB2.

!  Version 1.14, 19 August 2002 - ELF90 compatible version
!  Author: Alan Miller
!  e-mail : amiller @ bigpond.net.au
!  WWW-pages: http://www.ozemail.com.au/~milleraj
!             http://users.bigpond.net.au/amiller/

!  Bug fixes:
!  1. In REGCF a call to TOLSET has been added in case the user had
!     not set tolerances.
!  2. In SING, each time a singularity is detected, unless it is in the
!     variables in the last position, INCLUD is called.   INCLUD assumes
!     that a new observation is being added and increments the number of
!     cases, NOBS.   The line:  nobs = nobs - 1 has been added.
!  3. row_ptr was left out of the DEALLOCATE statement in routine startup
!     in version 1.07.
!  4. In COV, now calls SS if rss_set = .FALSE.  29 August 1997
!  5. In TOLSET, correction to accomodate negative values of D.  19 August 2002

!  Other changes:
!  1. Array row_ptr added 18 July 1997.   This points to the first element
!     stored in each row thus saving a small amount of time needed to
!     calculate its position.
!  2. Optional parameter, EPS, added to routine TOLSET, so that the user
!     can specify the accuracy of the input data.
!  3. Cosmetic change of lsq_kind to dp (`Double precision')
!  4. Change to routine SING to use row_ptr rather than calculate the position
!     of first elements in each row.

!  The PUBLIC variables are:
!  dp       = a KIND parameter for the floating-point quantities calculated
!             in this module.   See the more detailed explanation below.
!             This KIND parameter should be used for all floating-point
!             arguments passed to routines in this module.

!  nobs    = the number of observations processed to date.
!  ncol    = the total number of variables, including one for the constant,
!            if a constant is being fitted.
!  r_dim   = the dimension of array r = ncol*(ncol-1)/2
!  vorder  = an integer vector storing the current order of the variables
!            in the QR-factorization.   The initial order is 0, 1, 2, ...
!            if a constant is being fitted, or 1, 2, ... otherwise.
!  initialized = a logical variable which indicates whether space has
!                been allocated for various arrays.
!  tol_set = a logical variable which is set when subroutine TOLSET has
!            been called to calculate tolerances for use in testing for
!            singularities.
!  rss_set = a logical variable indicating whether residual sums of squares
!            are available and usable.
!  d()     = array of row multipliers for the Cholesky factorization.
!            The factorization is X = Q.sqrt(D).R where Q is an ortho-
!            normal matrix which is NOT stored, D is a diagonal matrix
!            whose diagonal elements are stored in array d, and R is an
!            upper-triangular matrix with 1's as its diagonal elements.
!  rhs()   = vector of RHS projections (after scaling by sqrt(D)).
!            Thus Q'y = sqrt(D).rhs
!  r()     = the upper-triangular matrix R.   The upper triangle only,
!            excluding the implicit 1's on the diagonal, are stored by
!            rows.
!  tol()   = array of tolerances used in testing for singularities.
!  rss()   = array of residual sums of squares.   rss(i) is the residual
!            sum of squares with the first i variables in the model.
!            By changing the order of variables, the residual sums of
!            squares can be found for all possible subsets of the variables.
!            The residual sum of squares with NO variables in the model,
!            that is the total sum of squares of the y-values, can be
!            calculated as rss(1) + d(1)*rhs(1)^2.   If the first variable
!            is a constant, then rss(1) is the sum of squares of
!            (y - ybar) where ybar is the average value of y.
!  sserr   = residual sum of squares with all of the variables included.
!  row_ptr() = array of indices of first elements in each row of R.
!
!--------------------------------------------------------------------------

!     General declarations

IMPLICIT NONE

INTEGER, SAVE                :: nobs, ncol, r_dim
INTEGER, ALLOCATABLE, SAVE   :: vorder(:), row_ptr(:)
LOGICAL, SAVE                :: initialized = .false.,                  &
tol_set = .false., rss_set = .false.

! Note. dp is being set to give at least 12 decimal digit
!       representation of floating point numbers.   This should be adequate
!       for most problems except the fitting of polynomials.   dp is
!       being set so that the same code can be run on PCs and Unix systems,
!       which will usually represent floating-point numbers in `double
!       precision', and other systems with larger word lengths which will
!       give similar accuracy in `single precision'.

INTEGER, PARAMETER           :: dp = SELECTED_REAL_KIND(12,60)
double precision, ALLOCATABLE, SAVE :: d(:), rhs(:), r(:), tol(:), rss(:)
double precision, SAVE              :: zero = 0.0_dp, one = 1.0_dp, vsmall
double precision, SAVE              :: sserr, toly

PUBLIC                       :: dp, nobs, ncol, r_dim, vorder, row_ptr, &
initialized, tol_set, rss_set,          &
d, rhs, r, tol, rss, sserr
PRIVATE                      :: zero, one, vsmall


CONTAINS

SUBROUTINE startup(nvar, fit_const)

!     Allocates dimensions for arrays and initializes to zero
!     The calling program must set nvar = the number of variables, and
!     fit_const = .true. if a constant is to be included in the model,
!     otherwise fit_const = .false.
!
!--------------------------------------------------------------------------

IMPLICIT NONE
INTEGER, INTENT(IN)  :: nvar
LOGICAL, INTENT(IN)  :: fit_const

!     Local variable
INTEGER   :: i

vsmall = 10. * TINY(zero)

nobs = 0
IF (fit_const) THEN
ncol = nvar + 1
ELSE
ncol = nvar
END IF

IF (initialized) DEALLOCATE(d, rhs, r, tol, rss, vorder, row_ptr)
r_dim = ncol * (ncol - 1)/2
ALLOCATE( d(ncol), rhs(ncol), r(r_dim), tol(ncol), rss(ncol), vorder(ncol),  &
row_ptr(ncol) )

d = zero
rhs = zero
r = zero
sserr = zero

IF (fit_const) THEN
DO i = 1, ncol
vorder(i) = i-1
END DO
ELSE
DO i = 1, ncol
vorder(i) = i
END DO
END IF ! (fit_const)

! row_ptr(i) is the position of element R(i,i+1) in array r().

row_ptr(1) = 1
DO i = 2, ncol-1
row_ptr(i) = row_ptr(i-1) + ncol - i + 1
END DO
row_ptr(ncol) = 0

initialized = .true.
tol_set = .false.
rss_set = .false.

RETURN
END SUBROUTINE startup




SUBROUTINE includ(weight, xrow, yelem)

!     ALGORITHM AS75.1  APPL. STATIST. (1974) VOL.23, NO. 3

!     Calling this routine updates D, R, RHS and SSERR by the
!     inclusion of xrow, yelem with the specified weight.

!     *** WARNING  Array XROW is overwritten.

!     N.B. As this routine will be called many times in most applications,
!          checks have been eliminated.
!
!--------------------------------------------------------------------------


IMPLICIT NONE
double precision,INTENT(IN)                    :: weight, yelem
double precision, DIMENSION(:), INTENT(IN OUT) :: xrow

!     Local variables

INTEGER     :: i, k, nextr
double precision   :: w, y, xi, di, wxi, dpi, cbar, sbar, xk

nobs = nobs + 1
w = weight
y = yelem
rss_set = .false.
nextr = 1
DO i = 1, ncol

!     Skip unnecessary transformations.   Test on exact zeroes must be
!     used or stability can be destroyed.

IF (ABS(w) < vsmall) RETURN
xi = xrow(i)
IF (ABS(xi) < vsmall) THEN
nextr = nextr + ncol - i
ELSE
di = d(i)
wxi = w * xi
dpi = di + wxi*xi
cbar = di / dpi
sbar = wxi / dpi
w = cbar * w
d(i) = dpi
DO k = i+1, ncol
xk = xrow(k)
xrow(k) = xk - xi * r(nextr)
r(nextr) = cbar * r(nextr) + sbar * xk
nextr = nextr + 1
END DO
xk = y
y = xk - xi * rhs(i)
rhs(i) = cbar * rhs(i) + sbar * xk
END IF
END DO ! i = 1, ncol

!     Y * SQRT(W) is now equal to the Brown, Durbin & Evans recursive
!     residual.

sserr = sserr + w * y * y

RETURN
END SUBROUTINE includ



SUBROUTINE regcf(beta, nreq, ifault)

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Modified version of AS75.4 to calculate regression coefficients
!     for the first NREQ variables, given an orthogonal reduction from
!     AS75.1.
!
!--------------------------------------------------------------------------

IMPLICIT NONE
INTEGER, INTENT(IN)                  :: nreq
INTEGER, INTENT(OUT)                 :: ifault
double precision, DIMENSION(:), INTENT(OUT) :: beta

!     Local variables

INTEGER   :: i, j, nextr

!     Some checks.

ifault = 0
IF (nreq < 1 .OR. nreq > ncol) ifault = ifault + 4
IF (ifault /= 0) RETURN

IF (.NOT. tol_set) CALL tolset()

DO i = nreq, 1, -1
IF (SQRT(d(i)) < tol(i)) THEN
beta(i) = zero
d(i) = zero
ifault = -i
ELSE
beta(i) = rhs(i)
nextr = row_ptr(i)
DO j = i+1, nreq
beta(i) = beta(i) - r(nextr) * beta(j)
nextr = nextr + 1
END DO ! j = i+1, nreq
END IF
END DO ! i = nreq, 1, -1

RETURN
END SUBROUTINE regcf



SUBROUTINE tolset(eps)

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Sets up array TOL for testing for zeroes in an orthogonal
!     reduction formed using AS75.1.

double precision, INTENT(IN), OPTIONAL :: eps

!     Unless the argument eps is set, it is assumed that the input data are
!     recorded to full machine accuracy.   This is often not the case.
!     If, for instance, the data are recorded to `single precision' of about
!     6-7 significant decimal digits, then singularities will not be detected.
!     It is suggested that in this case eps should be set equal to
!     10.0 * EPSILON(1.0)
!     If the data are recorded to say 4 significant decimals, then eps should
!     be set to 1.0E-03
!     The above comments apply to the predictor variables, not to the
!     dependent variable.

!     Correction - 19 August 2002
!     When negative weights are used, it is possible for an alement of D
!     to be negative.

!     Local variables.
!
!--------------------------------------------------------------------------

!     Local variables

INTEGER    :: col, row, pos
double precision  :: eps1, ten = 10.0, total, work(ncol)

!     EPS is a machine-dependent constant.

IF (PRESENT(eps)) THEN
eps1 = MAX(ABS(eps), ten * EPSILON(ten))
ELSE
eps1 = ten * EPSILON(ten)
END IF

!     Set tol(i) = sum of absolute values in column I of R after
!     scaling each element by the square root of its row multiplier,
!     multiplied by EPS1.

work = SQRT(ABS(d))
DO col = 1, ncol
pos = col - 1
total = work(col)
DO row = 1, col-1
total = total + ABS(r(pos)) * work(row)
pos = pos + ncol - row - 1
END DO
tol(col) = eps1 * total
END DO

tol_set = .TRUE.
RETURN
END SUBROUTINE tolset




SUBROUTINE sing(lindep, ifault)

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Checks for singularities, reports, and adjusts orthogonal
!     reductions produced by AS75.1.

!     Correction - 19 August 2002
!     When negative weights are used, it is possible for an alement of D
!     to be negative.

!     Auxiliary routines called: INCLUD, TOLSET
!
!--------------------------------------------------------------------------

INTEGER, INTENT(OUT)                :: ifault
LOGICAL, DIMENSION(:), INTENT(OUT)  :: lindep

!     Local variables

double precision  :: temp, x(ncol), work(ncol), y, weight
INTEGER    :: pos, row, pos2

ifault = 0

work = SQRT(ABS(d))
IF (.NOT. tol_set) CALL tolset()

DO row = 1, ncol
temp = tol(row)
pos = row_ptr(row)         ! pos = location of first element in row

!     If diagonal element is near zero, set it to zero, set appropriate
!     element of LINDEP, and use INCLUD to augment the projections in
!     the lower rows of the orthogonalization.

lindep(row) = .FALSE.
IF (work(row) <= temp) THEN
lindep(row) = .TRUE.
ifault = ifault - 1
IF (row < ncol) THEN
pos2 = pos + ncol - row - 1
x = zero
x(row+1:ncol) = r(pos:pos2)
y = rhs(row)
weight = d(row)
r(pos:pos2) = zero
d(row) = zero
rhs(row) = zero
CALL includ(weight, x, y)
! INCLUD automatically increases the number
! of cases each time it is called.
nobs = nobs - 1
ELSE
sserr = sserr + d(row) * rhs(row)**2
END IF ! (row < ncol)
END IF ! (work(row) <= temp)
END DO ! row = 1, ncol

RETURN
END SUBROUTINE sing



SUBROUTINE ss()

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Calculates partial residual sums of squares from an orthogonal
!     reduction from AS75.1.
!
!--------------------------------------------------------------------------

!     Local variables

INTEGER    :: i
double precision  :: total

total = sserr
rss(ncol) = sserr
DO i = ncol, 2, -1
total = total + d(i) * rhs(i)**2
rss(i-1) = total
END DO

rss_set = .TRUE.
RETURN
END SUBROUTINE ss



SUBROUTINE cov(nreq, var, covmat, dimcov, sterr, ifault)

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Calculate covariance matrix for regression coefficients for the
!     first nreq variables, from an orthogonal reduction produced from
!     AS75.1.

!     Auxiliary routine called: INV
!
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)                   :: nreq, dimcov
INTEGER, INTENT(OUT)                  :: ifault
double precision, INTENT(OUT)                :: var
double precision, DIMENSION(:), INTENT(OUT)  :: covmat, sterr

!     Local variables.

INTEGER                :: dim_rinv, pos, row, start, pos2, col, pos1, k
double precision              :: total
double precision, ALLOCATABLE :: rinv(:)

!     Check that dimension of array covmat is adequate.

IF (dimcov < nreq*(nreq+1)/2) THEN
ifault = 1
RETURN
END IF

!     Check for small or zero multipliers on the diagonal.

ifault = 0
DO row = 1, nreq
IF (ABS(d(row)) < vsmall) ifault = -row
END DO
IF (ifault /= 0) RETURN

!     Calculate estimate of the residual variance.

IF (nobs > nreq) THEN
IF (.NOT. rss_set) CALL ss()
var = rss(nreq) / (nobs - nreq)
ELSE
ifault = 2
RETURN
END IF

dim_rinv = nreq*(nreq-1)/2
ALLOCATE ( rinv(dim_rinv) )

CALL INV(nreq, rinv)
pos = 1
start = 1
DO row = 1, nreq
pos2 = start
DO col = row, nreq
pos1 = start + col - row
IF (row == col) THEN
total = one / d(col)
ELSE
total = rinv(pos1-1) / d(col)
END IF
DO K = col+1, nreq
total = total + rinv(pos1) * rinv(pos2) / d(k)
pos1 = pos1 + 1
pos2 = pos2 + 1
END DO ! K = col+1, nreq
covmat(pos) = total * var
IF (row == col) sterr(row) = SQRT(covmat(pos))
pos = pos + 1
END DO ! col = row, nreq
start = start + nreq - row
END DO ! row = 1, nreq

DEALLOCATE(rinv)
RETURN
END SUBROUTINE cov



SUBROUTINE inv(nreq, rinv)

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Invert first nreq rows and columns of Cholesky factorization
!     produced by AS 75.1.
!
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)                  :: nreq
double precision, DIMENSION(:), INTENT(OUT) :: rinv

!     Local variables.

INTEGER    :: pos, row, col, start, k, pos1, pos2
double precision  :: total

!     Invert R ignoring row multipliers, from the bottom up.

pos = nreq * (nreq-1)/2
DO row = nreq-1, 1, -1
start = row_ptr(row)
DO col = nreq, row+1, -1
pos1 = start
pos2 = pos
total = zero
DO k = row+1, col-1
pos2 = pos2 + nreq - k
total = total - r(pos1) * rinv(pos2)
pos1 = pos1 + 1
END DO ! k = row+1, col-1
rinv(pos) = total - r(pos1)
pos = pos - 1
END DO ! col = nreq, row+1, -1
END DO ! row = nreq-1, 1, -1

RETURN
END SUBROUTINE inv



SUBROUTINE partial_corr(in, cormat, dimc, ycorr, ifault)

!     Replaces subroutines PCORR and COR of:
!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Calculate partial correlations after the variables in rows
!     1, 2, ..., IN have been forced into the regression.
!     If IN = 1, and the first row of R represents a constant in the
!     model, then the usual simple correlations are returned.

!     If IN = 0, the value returned in array CORMAT for the correlation
!     of variables Xi & Xj is:
!       sum ( Xi.Xj ) / Sqrt ( sum (Xi^2) . sum (Xj^2) )

!     On return, array CORMAT contains the upper triangle of the matrix of
!     partial correlations stored by rows, excluding the 1's on the diagonal.
!     e.g. if IN = 2, the consecutive elements returned are:
!     (3,4) (3,5) ... (3,ncol), (4,5) (4,6) ... (4,ncol), etc.
!     Array YCORR stores the partial correlations with the Y-variable
!     starting with YCORR(IN+1) = partial correlation with the variable in
!     position (IN+1).
!
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)                  :: in, dimc
INTEGER, INTENT(OUT)                 :: ifault
double precision, DIMENSION(:), INTENT(OUT) :: cormat, ycorr

!     Local variables.

INTEGER    :: base_pos, pos, row, col, col1, col2, pos1, pos2
double precision  :: rms(in+1:ncol), sumxx, sumxy, sumyy, work(in+1:ncol)

!     Some checks.

ifault = 0
IF (in < 0 .OR. in > ncol-1) ifault = ifault + 4
IF (dimc < (ncol-in)*(ncol-in-1)/2) ifault = ifault + 8
IF (ifault /= 0) RETURN

!     Base position for calculating positions of elements in row (IN+1) of R.

base_pos = in*ncol - (in+1)*(in+2)/2

!     Calculate 1/RMS of elements in columns from IN to (ncol-1).

IF (d(in+1) > zero) rms(in+1) = one / SQRT(d(in+1))
DO col = in+2, ncol
pos = base_pos + col
sumxx = d(col)
DO row = in+1, col-1
sumxx = sumxx + d(row) * r(pos)**2
pos = pos + ncol - row - 1
END DO ! row = in+1, col-1
IF (sumxx > zero) THEN
rms(col) = one / SQRT(sumxx)
ELSE
rms(col) = zero
ifault = -col
END IF ! (sumxx > zero)
END DO ! col = in+1, ncol-1

!     Calculate 1/RMS for the Y-variable

sumyy = sserr
DO row = in+1, ncol
sumyy = sumyy + d(row) * rhs(row)**2
END DO ! row = in+1, ncol
IF (sumyy > zero) sumyy = one / SQRT(sumyy)

!     Calculate sums of cross-products.
!     These are obtained by taking dot products of pairs of columns of R,
!     but with the product for each row multiplied by the row multiplier
!     in array D.

pos = 1
DO col1 = in+1, ncol
sumxy = zero
work(col1+1:ncol) = zero
pos1 = base_pos + col1
DO row = in+1, col1-1
pos2 = pos1 + 1
DO col2 = col1+1, ncol
work(col2) = work(col2) + d(row) * r(pos1) * r(pos2)
pos2 = pos2 + 1
END DO ! col2 = col1+1, ncol
sumxy = sumxy + d(row) * r(pos1) * rhs(row)
pos1 = pos1 + ncol - row - 1
END DO ! row = in+1, col1-1

!     Row COL1 has an implicit 1 as its first element (in column COL1)

pos2 = pos1 + 1
DO col2 = col1+1, ncol
work(col2) = work(col2) + d(col1) * r(pos2)
pos2 = pos2 + 1
cormat(pos) = work(col2) * rms(col1) * rms(col2)
pos = pos + 1
END DO ! col2 = col1+1, ncol
sumxy = sumxy + d(col1) * rhs(col1)
ycorr(col1) = sumxy * rms(col1) * sumyy
END DO ! col1 = in+1, ncol-1

ycorr(1:in) = zero

RETURN
END SUBROUTINE partial_corr




SUBROUTINE vmove(from, to, ifault)

!     ALGORITHM AS274 APPL. STATIST. (1992) VOL.41, NO. 2

!     Move variable from position FROM to position TO in an
!     orthogonal reduction produced by AS75.1.
!
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)    :: from, to
INTEGER, INTENT(OUT)   :: ifault

!     Local variables

double precision  :: d1, d2, x, d1new, d2new, cbar, sbar, y
INTEGER    :: m, first, last, inc, m1, m2, mp1, col, pos, row

!     Check input parameters

ifault = 0
IF (from < 1 .OR. from > ncol) ifault = ifault + 4
IF (to < 1 .OR. to > ncol) ifault = ifault + 8
IF (ifault /= 0) RETURN

IF (from == to) RETURN

IF (.NOT. rss_set) CALL ss()

IF (from < to) THEN
first = from
last = to - 1
inc = 1
ELSE
first = from - 1
last = to
inc = -1
END IF

DO m = first, last, inc

!     Find addresses of first elements of R in rows M and (M+1).

m1 = row_ptr(m)
m2 = row_ptr(m+1)
mp1 = m + 1
d1 = d(m)
d2 = d(mp1)

!     Special cases.

IF (d1 < vsmall .AND. d2 < vsmall) GO TO 40
x = r(m1)
IF (ABS(x) * SQRT(d1) < tol(mp1)) THEN
x = zero
END IF
IF (d1 < vsmall .OR. ABS(x) < vsmall) THEN
d(m) = d2
d(mp1) = d1
r(m1) = zero
DO col = m+2, ncol
m1 = m1 + 1
x = r(m1)
r(m1) = r(m2)
r(m2) = x
m2 = m2 + 1
END DO ! col = m+2, ncol
x = rhs(m)
rhs(m) = rhs(mp1)
rhs(mp1) = x
GO TO 40
ELSE IF (d2 < vsmall) THEN
d(m) = d1 * x**2
r(m1) = one / x
r(m1+1:m1+ncol-m-1) = r(m1+1:m1+ncol-m-1) / x
rhs(m) = rhs(m) / x
GO TO 40
END IF

!     Planar rotation in regular case.

d1new = d2 + d1*x**2
cbar = d2 / d1new
sbar = x * d1 / d1new
d2new = d1 * cbar
d(m) = d1new
d(mp1) = d2new
r(m1) = sbar
DO col = m+2, ncol
m1 = m1 + 1
y = r(m1)
r(m1) = cbar*r(m2) + sbar*y
r(m2) = y - x*r(m2)
m2 = m2 + 1
END DO ! col = m+2, ncol
y = rhs(m)
rhs(m) = cbar*rhs(mp1) + sbar*y
rhs(mp1) = y - x*rhs(mp1)

!     Swap columns M and (M+1) down to row (M-1).

40 pos = m
DO row = 1, m-1
x = r(pos)
r(pos) = r(pos-1)
r(pos-1) = x
pos = pos + ncol - row - 1
END DO ! row = 1, m-1

!     Adjust variable order (VORDER), the tolerances (TOL) and
!     the vector of residual sums of squares (RSS).

m1 = vorder(m)
vorder(m) = vorder(mp1)
vorder(mp1) = m1
x = tol(m)
tol(m) = tol(mp1)
tol(mp1) = x
rss(m) = rss(mp1) + d(mp1) * rhs(mp1)**2
END DO

RETURN
END SUBROUTINE vmove



SUBROUTINE reordr(list, n, pos1, ifault)

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2

!     Re-order the variables in an orthogonal reduction produced by
!     AS75.1 so that the N variables in LIST start at position POS1,
!     though will not necessarily be in the same order as in LIST.
!     Any variables in VORDER before position POS1 are not moved.

!     Auxiliary routine called: VMOVE
!
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)               :: n, pos1
INTEGER, DIMENSION(:), INTENT(IN) :: list
INTEGER, INTENT(OUT)              :: ifault

!     Local variables.

INTEGER    :: next, i, l, j

!     Check N.

ifault = 0
IF (n < 1 .OR. n > ncol+1-pos1) ifault = ifault + 4
IF (ifault /= 0) RETURN

!     Work through VORDER finding variables which are in LIST.

next = pos1
i = pos1
10 l = vorder(i)
DO j = 1, n
IF (l == list(j)) GO TO 40
END DO
30 i = i + 1
IF (i <= ncol) GO TO 10

!     If this point is reached, one or more variables in LIST has not
!     been found.

ifault = 8
RETURN

!     Variable L is in LIST; move it up to position NEXT if it is not
!     already there.

40 IF (i > next) CALL vmove(i, next, ifault)
next = next + 1
IF (next < n+pos1) GO TO 30

RETURN
END SUBROUTINE reordr



SUBROUTINE hdiag(xrow, nreq, hii, ifault)

!     ALGORITHM AS274  APPL. STATIST. (1992) VOL.41, NO. 2
!
!                         -1           -1
! The hat matrix H = x(X'X) x' = x(R'DR) x' = z'Dz

!              -1
! where z = x'R

! Here we only calculate the diagonal element hii corresponding to one
! row (xrow).   The variance of the i-th least-squares residual is (1 - hii).
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)                  :: nreq
INTEGER, INTENT(OUT)                 :: ifault
double precision, DIMENSION(:), INTENT(IN)  :: xrow
double precision, INTENT(OUT)               :: hii

!     Local variables

INTEGER    :: col, row, pos
double precision  :: total, wk(ncol)

!     Some checks

ifault = 0
IF (nreq > ncol) ifault = ifault + 4
IF (ifault /= 0) RETURN

!     The elements of xrow.inv(R).sqrt(D) are calculated and stored in WK.

hii = zero
DO col = 1, nreq
IF (SQRT(d(col)) <= tol(col)) THEN
wk(col) = zero
ELSE
pos = col - 1
total = xrow(col)
DO row = 1, col-1
total = total - wk(row)*r(pos)
pos = pos + ncol - row - 1
END DO ! row = 1, col-1
wk(col) = total
hii = hii + total**2 / d(col)
END IF
END DO ! col = 1, nreq

RETURN
END SUBROUTINE hdiag



FUNCTION varprd(x, nreq) RESULT(fn_val)

!     Calculate the variance of x'b where b consists of the first nreq
!     least-squares regression coefficients.
!
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)                  :: nreq
double precision, DIMENSION(:), INTENT(IN)  :: x
double precision                            :: fn_val

!     Local variables

INTEGER    :: ifault, row
double precision  :: var, wk(nreq)

!     Check input parameter values

fn_val = zero
ifault = 0
IF (nreq < 1 .OR. nreq > ncol) ifault = ifault + 4
IF (nobs <= nreq) ifault = ifault + 8
IF (ifault /= 0) THEN
!WRITE(*, '(1x, a, i4)') 'Error in function VARPRD: ifault =', ifault
RETURN
END IF

!     Calculate the residual variance estimate.

var = sserr / (nobs - nreq)

!     Variance of x'b = var.x'(inv R)(inv D)(inv R')x
!     First call BKSUB2 to calculate (inv R')x by back-substitution.

CALL BKSUB2(x, wk, nreq)
DO row = 1, nreq
IF(d(row) > tol(row)) fn_val = fn_val + wk(row)**2 / d(row)
END DO

fn_val = fn_val * var

RETURN
END FUNCTION varprd



SUBROUTINE bksub2(x, b, nreq)

!     Solve x = R'b for b given x, using only the first nreq rows and
!     columns of R, and only the first nreq elements of R.
!
!--------------------------------------------------------------------------

INTEGER, INTENT(IN)                  :: nreq
double precision, DIMENSION(:), INTENT(IN)  :: x
double precision, DIMENSION(:), INTENT(OUT) :: b

!     Local variables

INTEGER    :: pos, row, col
double precision  :: temp

!     Solve by back-substitution, starting from the top.

DO row = 1, nreq
pos = row - 1
temp = x(row)
DO col = 1, row-1
temp = temp - r(pos)*b(col)
pos = pos + ncol - col - 1
END DO
b(row) = temp
END DO

RETURN
END SUBROUTINE bksub2


END MODULE lsq











subroutine WRegresion_Javier(X,Y,W,n,nvar,beta,sterr,se,r2,iopt,ier)


USE lsq
IMPLICIT NONE
INTEGER             :: i, ier, j, m, n,nvar,iopt
double precision          :: x(n,nvar), y(n),W(n), xrow(0:nvar+1),&
beta(0:nvar+1),var, covmat(231), sterr(0:nvar+1), &
totalSS,se,r2
LOGICAL             :: fit_const = .TRUE., lindep(0:20)



! Least-squares calculations
m=nvar
CALL startup(m, fit_const)
DO i = 1, n
xrow(0) = 1.0_dp
DO j = 1, m
xrow(j) = x(i,j)
END DO
CALL includ(W(i), xrow, y(i))
END DO


if (iopt.gt.0) then
CALL sing(lindep, ier)
IF (ier /= 0) THEN
DO i = 0, m
!IF (lindep(i)) WRITE(*, '(a, i3)') ' Singularity detected for power: ', i 
!IF (lindep(i)) WRITE(9, '(a, i3)') ' Singularity detected for power: ', i
END DO
END IF
end if

! Calculate progressive residual sums of squares
CALL ss()
var = rss(m+1) / (n - m - 1)

! Calculate least-squares regn. coeffs.
CALL regcf(beta, m+1, ier)

if (iopt.gt.0) then
! Calculate covariance matrix, and hence std. errors of coeffs.
CALL cov(m+1, var, covmat, 231, sterr, ier)

!WRITE(*, *) 'Least-squares coefficients & std. errors'
!WRITE(9, *) 'Least-squares coefficients & std. errors'
!WRITE(*, *) 'Power  Coefficient          Std.error      Resid.sum of sq.'
!WRITE(9, *) 'Power  Coefficient          Std.error      Resid.sum of sq.'
DO i = 0, m
!  WRITE(*, '(i4, g20.12, "   ", g14.6, "   ", g14.6)')  &
!        i, beta(i), sterr(i), rss(i+1)
!  WRITE(9, '(i4, g20.12, "   ", g14.6, "   ", g14.6)')  &
!        i, beta(i), sterr(i), rss(i+1)
END DO

!WRITE(*, *)

!WRITE(*, '(a, g20.12)') ' Residual standard deviation = ', SQRT(var)

se=SQRT(var)
totalSS = rss(1)
!WRITE(*, '(a, g20.12)') ' R^2 = ', (totalSS - rss(m+1))/totalSS

r2=(totalSS - rss(m+1))/totalSS

end if
END 














subroutine Grid1D (X,W,n,Xgrid,kbin)
implicit none
integer kbin,i,n
double precision xmin,xmax,Xgrid(kbin),X(n),W(n)
xmin=9e9
xmax=-xmin
do i=1,n
if (W(i).gt.0) then
xmin=min(x(i),xmin)
xmax=max(x(i),xmax)
end if
end do

do i=1,kbin
Xgrid(i)=xmin+(i-1)*(xmax-xmin)/(kbin-1)
end do
end










subroutine Rfast0(X,Y,n,W,Xb,Pb,kbin,a,b)
implicit none
integer n,i,j,kbin,p
double precision x(n),y(n),W(n),Xb(kbin),Yb(kbin),Wb(kbin),&
Area(2),dis1,dis2,Beta(5),&
Pb(kbin,3),Xb2(kbin),Yb2(kbin),a,b,aux



!CONSTRUCCIÓN DE LA MUESTRA BINNING
Wb=0
Yb=0
do i=1,n
if (W(i).gt.0) then
if (X(i).lt.Xb(1)) then
Wb(1)=wb(1)+W(i)
yb(1)=yb(1)+W(i)*Y(i)
elseif (X(i).gt.Xb(kbin)) then
Wb(kbin)=wb(kbin)+W(i)
yb(kbin)=yb(kbin)+W(i)*Y(i)
else
do j=1,kbin-1
if (Xb(j).le.X(i).and.X(i).le.Xb(j+1)) then
dis1=X(i)-Xb(j)
dis2=Xb(j+1)-X(i)
Area(1)=dis2/(dis1+dis2)
Area(2)=dis1/(dis1+dis2)
Wb(j)=Wb(j)+W(i)*Area(1)
Yb(j)=Yb(j)+Y(i)*W(i)*Area(1)
Wb(j+1)=Wb(j+1)+W(i)*Area(2)
Yb(j+1)=Yb(j+1)+Y(i)*W(i)*Area(2)
end if
end do
end if
end if
end do
do i=1,kbin
if (Wb(i).gt.0) Yb(i)=Yb(i)/Wb(i)
end do




aux=0.001
Xb2=max(Xb,aux)
Yb2=max(Yb,aux)

Xb2=log(Xb2)
Yb2=log(Yb2)

p=1
call  Reglineal (Xb2,Yb2,Wb,kbin,p,Beta)


Beta(1)=exp(Beta(1))

a=Beta(1)
b=Beta(2)


do i=1,kbin
Pb(i,1)=Beta(1)*(Xb(i)**Beta(2))
Pb(i,2)=Beta(1)*Beta(2)*(Xb(i)**(Beta(2)-1))
Pb(i,3)=Beta(1)*Beta(2)*(Beta(2)-1)*(Xb(i)**(Beta(2)-2))
end do

end




subroutine Rfast0_sinbinning(X,Y,n,W,Xb,Pb,kbin,a,b)
implicit none
integer n,i,kbin,p
double precision x(n),y(n),W(n),Xb(kbin),&
Beta(5),&
Pb(kbin,3),X2(n),Y2(n),a,b,aux

aux=0.001
X2=max(X,aux)
Y2=max(Y,aux)

X2=log(X2)
Y2=log(Y2)

p=1
call  Reglineal (X2,Y2,W,n,p,Beta)


Beta(1)=exp(Beta(1))

a=Beta(1)
b=Beta(2)


do i=1,kbin
Pb(i,1)=Beta(1)*(Xb(i)**Beta(2))
Pb(i,2)=Beta(1)*Beta(2)*(Xb(i)**(Beta(2)-1))
Pb(i,3)=Beta(1)*Beta(2)*(Beta(2)-1)*(Xb(i)**(Beta(2)-2))
end do

end



!***************************************************
!		
!			WREGRESION
!
!***************************************************


subroutine WRegresion(X,Y,W,n,nvar,beta,sterr,se,r2,iopt)


USE lsq
IMPLICIT NONE
INTEGER             :: i, ier, j, m, n,nvar,iopt
double precision          :: x(n,nvar), y(n),W(n), xrow(0:nvar+1),&
beta(0:nvar+1),var, covmat(231), sterr(0:nvar+1), &
totalSS,se,r2
LOGICAL             :: fit_const = .TRUE., lindep(0:20)


! Least-squares calculations
m=nvar
CALL startup(m, fit_const)
DO i = 1, n
xrow(0) = 1.0_dp
DO j = 1, m
xrow(j) = x(i,j)
END DO
CALL includ(W(i), xrow, y(i))
END DO


if (iopt.gt.0) then
CALL sing(lindep, ier)
IF (ier /= 0) THEN
DO i = 0, m
!  IF (lindep(i)) WRITE(*, '(a, i3)') ' Singularity detected for power: ', i
! IF (lindep(i)) WRITE(9, '(a, i3)') ' Singularity detected for power: ', i
END DO
END IF
end if

! Calculate progressive residual sums of squares
CALL ss()
var = rss(m+1) / (n - m - 1)

! Calculate least-squares regn. coeffs.
CALL regcf(beta, m+1, ier)

if (iopt.gt.0) then
! Calculate covariance matrix, and hence std. errors of coeffs.
CALL cov(m+1, var, covmat, 231, sterr, ier)

!WRITE(*, *) 'Least-squares coefficients & std. errors'
!WRITE(9, *) 'Least-squares coefficients & std. errors'
!WRITE(*, *) 'Power  Coefficient          Std.error      Resid.sum of sq.'
!WRITE(9, *) 'Power  Coefficient          Std.error      Resid.sum of sq.'
DO i = 0, m
! WRITE(*, '(i4, g20.12, "   ", g14.6, "   ", g14.6)')  &
!      i, beta(i), sterr(i), rss(i+1)
! WRITE(9, '(i4, g20.12, "   ", g14.6, "   ", g14.6)')  &
!      i, beta(i), sterr(i), rss(i+1)
END DO

!WRITE(*, *)

!WRITE(*, '(a, g20.12)') ' Residual standard deviation = ', SQRT(var)

se=SQRT(var)
totalSS = rss(1)
!WRITE(*, '(a, g20.12)') ' R^2 = ', (totalSS - rss(m+1))/totalSS

r2=(totalSS - rss(m+1))/totalSS

end if
END 







subroutine RLineal (X,Y,W,n,p,Beta)
implicit none
integer n,p,iopt
double precision X(n,p),Y(n),W(n),beta(p+1),&
sterr(p+1),se,r2
iopt=0
call WRegresion(X,Y,W,n,p,beta,sterr,se,r2,iopt)
end


subroutine PredLineal (X,n,p,B,Pred)
implicit none
integer i,n,j,p
double precision X(n,p),B(p+1),Pred(n)

Pred=0
do i=1,n
Pred(i)=B(1)
do j=1,p
Pred(i)=Pred(i)+B(j+1)*X(i,j)
end do
end do
end



subroutine mean_var(X,W,n,mean,var)
implicit none
integer n ,i
double precision X(n),W(n),sumw,mean,var
Mean=0
var=0
SumW=0
do i=1,n
sumw=sumw+W(i)
Mean=Mean+W(i)*X(i)
var=var+W(i)*X(i)**2
end do

Mean=Mean/sumw
var=(var/sumw)-Mean**2

end








!******************************************
!
!	Subroutine	ICBOOTSTRAP
!
!*****************************************



subroutine ICbootstrap(X0,X,nboot,li,ls)
implicit none
integer nboot,nalfa
double precision X0,X(nboot),li,ls,alfa(3),Q(3),sesgo


alfa(1)=0.025
alfa(2)=0.5
alfa(3)=0.975
nalfa=3

call quantile (X,nboot,alfa,nalfa,Q)

if (Q(2).eq.9999) then
sesgo=0 
else
sesgo=Q(2)-X0
end if

li=Q(1)!-sesgo   !chapuzada
  

if (Q(3).eq.9999) then
ls=Q(3)
else
ls=Q(3)!-sesgo  !chapuzada
end if





end




!******************************************
!
!		Subroutine	quantile
!
!*****************************************


subroutine quantile (X,n,alfa,nalfa,Q)
implicit none
integer n,nalfa,ip,j,ind(n)
double precision X(n),alfa(nalfa),Q(nalfa),R,xest
call qsortd(x,ind,n)

do j=1,nalfa
IP=floor(alfa(j)*(n+1.))
XEST=alfa(j)*(n+1.)
IF(ip .lt. 1) then
Q(j)=X(ind(1))
elseif (ip.ge.n) then
Q(j)=X(ind(n))
else
R=alfa(j)*(n+1.)-IP
Q(j)=(1.-R)*X(ind(IP)) + R*X(ind(IP+1))
end if
end do
end









double precision function Cuant (X,n,alfa)
implicit none
integer n,ip,ind(n)
double precision X(n),alfa,Q,R,xest
call qsortd(x,ind,n)
IP=floor(alfa*(n+1.))
XEST=alfa*(n+1.)
IF(ip .lt. 1) then
Q=X(ind(1))
elseif (ip.ge.n) then
Q=X(ind(n))
else
R=alfa*(n+1.)-IP
Q=(1.-R)*X(ind(IP)) + R*X(ind(IP+1))
end if
Cuant=Q
end







!******************************************
!
!		Subroutine	BANDA
!
!*****************************************



subroutine Banda(f,fboot,n,nboot,bi,bs)
implicit none
integer nboot,nalfa,i,n,j,iboot
double precision F(n),Fboot(n,nboot),bi(n),bs(n),alfa(3),Q(3),&
W(nboot),V(nboot),mean(n),se(n),Sup(nboot),aux,W1(n)
W=1
W1=1
bi=-1
bs=-1



!  CENTRAMOS LAS ESTIMACIONES

do i=1,n
do j=1,nboot
V(j)=Fboot(i,j)-F(i)
end do
call mean_var(V,W,nboot,mean(i),se(i))
do j=1,nboot
Fboot(i,j)=Fboot(i,j)-mean(i)
end do
end do


! FIN DEL CENTRADO



do i=1,n
do j=1,nboot
V(j)=Fboot(i,j)
if (V(j).eq.-1.0) then
se(i)=0
goto 1
end if
end do
call mean_var(V,W,nboot,mean(i),se(i))
if (se(i).gt.0) se(i)=sqrt (se(i))


1   continue
end do


do iboot=1,nboot
Sup(iboot)=-9d-9
do i=1,n
if (se(i).gt.0) then
aux=abs(f(i)-fboot(i,iboot))/se(i)
if (aux.ge.sup(iboot)) sup(iboot)=aux
end if
end do
end do




alfa(1)=0.025
alfa(2)=0.5
alfa(3)=0.95
nalfa=3
call quantile (Sup,nboot,alfa,nalfa,Q)

do i=1,n
if (f(i).ne.-1.0) then
bi(i)=f(i)-Q(3)*Se(i)
bs(i)=f(i)+Q(3)*Se(i)
end if
end do
end













SUBROUTINE qsortd(x,ind,n)

! Code converted using TO_F90 by Alan Miller
! Date: 2002-12-18  Time: 11:55:47

IMPLICIT NONE
INTEGER, PARAMETER  :: dp = SELECTED_REAL_KIND(12, 60)
integer n,ind(n)
double precision x(n)



!***************************************************************************

!                                                         ROBERT RENKA
!                                                 OAK RIDGE NATL. LAB.

!   THIS SUBROUTINE USES AN ORDER N*LOG(N) QUICK SORT TO SORT A double precision
! ARRAY X INTO INCREASING ORDER.  THE ALGORITHM IS AS FOLLOWS.  IND IS
! INITIALIZED TO THE ORDERED SEQUENCE OF INDICES 1,...,N, AND ALL INTERCHANGES
! ARE APPLIED TO IND.  X IS DIVIDED INTO TWO PORTIONS BY PICKING A CENTRAL
! ELEMENT T.  THE FIRST AND LAST ELEMENTS ARE COMPARED WITH T, AND
! INTERCHANGES ARE APPLIED AS NECESSARY SO THAT THE THREE VALUES ARE IN
! ASCENDING ORDER.  INTERCHANGES ARE THEN APPLIED SO THAT ALL ELEMENTS
! GREATER THAN T ARE IN THE UPPER PORTION OF THE ARRAY AND ALL ELEMENTS
! LESS THAN T ARE IN THE LOWER PORTION.  THE UPPER AND LOWER INDICES OF ONE
! OF THE PORTIONS ARE SAVED IN LOCAL ARRAYS, AND THE PROCESS IS REPEATED
! ITERATIVELY ON THE OTHER PORTION.  WHEN A PORTION IS COMPLETELY SORTED,
! THE PROCESS BEGINS AGAIN BY RETRIEVING THE INDICES BOUNDING ANOTHER
! UNSORTED PORTION.

! INPUT PARAMETERS -   N - LENGTH OF THE ARRAY X.

!                      X - VECTOR OF LENGTH N TO BE SORTED.

!                    IND - VECTOR OF LENGTH >= N.

! N AND X ARE NOT ALTERED BY THIS ROUTINE.

! OUTPUT PARAMETER - IND - SEQUENCE OF INDICES 1,...,N PERMUTED IN THE SAME
!                          FASHION AS X WOULD BE.  THUS, THE ORDERING ON
!                          X IS DEFINED BY Y(I) = X(IND(I)).

!*********************************************************************

! NOTE -- IU AND IL MUST BE DIMENSIONED >= LOG(N) WHERE LOG HAS BASE 2.

!*********************************************************************

INTEGER   :: iu(21), il(21)
INTEGER   :: m, i, j, k, l, ij, it, itt, indx
double precision     :: r
double precision :: t

! LOCAL PARAMETERS -

! IU,IL =  TEMPORARY STORAGE FOR THE UPPER AND LOWER
!            INDICES OF PORTIONS OF THE ARRAY X
! M =      INDEX FOR IU AND IL
! I,J =    LOWER AND UPPER INDICES OF A PORTION OF X
! K,L =    INDICES IN THE RANGE I,...,J
! IJ =     RANDOMLY CHOSEN INDEX BETWEEN I AND J
! IT,ITT = TEMPORARY STORAGE FOR INTERCHANGES IN IND
! INDX =   TEMPORARY INDEX FOR X
! R =      PSEUDO RANDOM NUMBER FOR GENERATING IJ
! T =      CENTRAL ELEMENT OF X

IF (n <= 0) RETURN

! INITIALIZE IND, M, I, J, AND R

DO  i = 1, n
ind(i) = i
END DO
m = 1
i = 1
j = n
r = .375

! TOP OF LOOP

20 IF (i >= j) GO TO 70
IF (r <= .5898437) THEN
r = r + .0390625
ELSE
r = r - .21875
END IF

! INITIALIZE K

30 k = i

! SELECT A CENTRAL ELEMENT OF X AND SAVE IT IN T

ij = floor(i + r*(j-i))
it = ind(ij)
t = x(it)

! IF THE FIRST ELEMENT OF THE ARRAY IS GREATER THAN T,
!   INTERCHANGE IT WITH T

indx = ind(i)
IF (x(indx) > t) THEN
ind(ij) = indx
ind(i) = it
it = indx
t = x(it)
END IF

! INITIALIZE L

l = j

! IF THE LAST ELEMENT OF THE ARRAY IS LESS THAN T,
!   INTERCHANGE IT WITH T

indx = ind(j)
IF (x(indx) >= t) GO TO 50
ind(ij) = indx
ind(j) = it
it = indx
t = x(it)

! IF THE FIRST ELEMENT OF THE ARRAY IS GREATER THAN T,
!   INTERCHANGE IT WITH T

indx = ind(i)
IF (x(indx) <= t) GO TO 50
ind(ij) = indx
ind(i) = it
it = indx
t = x(it)
GO TO 50

! INTERCHANGE ELEMENTS K AND L

40 itt = ind(l)
ind(l) = ind(k)
ind(k) = itt

! FIND AN ELEMENT IN THE UPPER PART OF THE ARRAY WHICH IS
!   NOT LARGER THAN T

50 l = l - 1
indx = ind(l)
IF (x(indx) > t) GO TO 50

! FIND AN ELEMENT IN THE LOWER PART OF THE ARRAY WHCIH IS NOT SMALLER THAN T

60 k = k + 1
indx = ind(k)
IF (x(indx) < t) GO TO 60

! IF K <= L, INTERCHANGE ELEMENTS K AND L

IF (k <= l) GO TO 40

! SAVE THE UPPER AND LOWER SUBSCRIPTS OF THE PORTION OF THE
!   ARRAY YET TO BE SORTED

IF (l-i > j-k) THEN
il(m) = i
iu(m) = l
i = k
m = m + 1
GO TO 80
END IF

il(m) = k
iu(m) = j
j = l
m = m + 1
GO TO 80

! BEGIN AGAIN ON ANOTHER UNSORTED PORTION OF THE ARRAY

70 m = m - 1
IF (m == 0) RETURN
i = il(m)
j = iu(m)

80 IF (j-i >= 11) GO TO 30
IF (i == 1) GO TO 20
i = i - 1

! SORT ELEMENTS I+1,...,J.  NOTE THAT 1 <= I < J AND J-I < 11.

90 i = i + 1
IF (i == j) GO TO 70
indx = ind(i+1)
t = x(indx)
it = indx
indx = ind(i)
IF (x(indx) <= t) GO TO 90
k = i

100 ind(k+1) = ind(k)
k = k - 1
indx = ind(k)
IF (t < x(indx)) GO TO 100

ind(k+1) = it
GO TO 90
END SUBROUTINE qsortd





!******************************************
!
!		Subroutine	FACTORES
!
!*****************************************





subroutine Factores(X,n,fact,nf)
implicit none
integer n,nf,i,j,X(n),fact(100)
logical ifnew
nf=1
fact(1)=x(1)
do i=2,n
ifnew=.true.
do j=1,nf
If(X(i).eq.fact(j)) ifnew=.false. 
end do
if (ifnew) then
nf=nf+1
Fact(nf)=X(i)
end if
end do
end











subroutine Interpola_alo (Xgrid,Pgrid,kbin,X0,P0,P1,n)
! Fit a quintic spline with user control of knot positions.
! If the knots are at tk1, tk2,..., then the fitted spline is
! b0 + b1.t + b2.t^2 + b3.t^3 + b4.t^4 + b5.t^5    for t <= tk1
! b0 + ... + b5.t^5 + b6.(t-tk1)^5                 for tk1 < t <= tk2
! b0 + ... + b5.t^5 + b6.(t-tk1)^5 + b7.(t-tk2)^5  for tk2 < t <= tk3
! b0 + ... + b5.t^5 + b6.(t-tk1)^5 + b7.(t-tk2)^5 + b8.(t-tk3)^5
!                                                  for tk3 < t <= tk4, etc.

! In this version, the knots are evenly spaced.
! Also calculates first & 2nd derivatives of the spline.

! Uses the author's least-squares package in file lsq.f90
! Latest revision - 2 November 2003
! Alan Miller (amiller @ bigpond.net.au)

USE lsq
IMPLICIT NONE

INTEGER                 :: i, ier, j, n, nk,next_knot,kbin,icont
double precision               :: t, t1, y, dist,Xgrid(kbin),Pgrid(kbin),X0(n),P0(n),P1(n),P2(n)
double precision, PARAMETER    :: one = 1.0_dp,cero=0.0_dp
double precision, ALLOCATABLE  :: knot(:), xrow(:), b(:)



icont=0
do i=1,kbin
if (pgrid(i).ne.-1.0) icont=icont+1
end do

if (icont.gt.5) then
nk=icont/5


!numero de nodos
!if (nk>kbin/5) stop ! '** Too many knots requested - TRY AGAIN'

ALLOCATE ( knot(nk),xrow(0:5+nk), b(0:5+nk) )


! Calculate knot positions, evenly spaced.

dist = (Xgrid(kbin) - Xgrid(1)) / (nk + 1)
t1=Xgrid(1)
DO i = 1, nk
knot(i) = t1 + dist * i
END DO

! WRITE(9, '(a, i4)') 'Number of knots = ', nk


next_knot = 1

! Initialize the least-squares calculations
CALL startup(6+nk, .FALSE.)

DO i=1,kbin
t=Xgrid(i)
y=Pgrid(i)
xrow(0) = one
xrow(1) = (t - t1)
xrow(2) = (t - t1) * xrow(1)
xrow(3) = (t - t1) * xrow(2)
xrow(4) = (t - t1) * xrow(3)
xrow(5) = (t - t1) * xrow(4)
IF (t > knot(next_knot)) next_knot = MIN(nk, next_knot + 1)
DO j = 1, next_knot-1
xrow(5+j) = (t - knot(j))**5
END DO
xrow(5+next_knot:5+nk) = 0.0_dp
if (y.ne.-1.0_dp) CALL includ(one, xrow, y)

END DO

CALL regcf(b, 6+nk, ier)

!WRITE(*, *) ' Coefficient   Value'
!WRITE(*, '(a, g13.5)') ' Constant   ', b(0)
!WRITE(*, '(a, g13.5)') ' Linear     ', b(1)
!WRITE(*, '(a, g13.5)') ' Quadratic  ', b(2)
!WRITE(*, '(a, g13.5)') ' Cubic      ', b(3)
!WRITE(*, '(a, g13.5)') ' Quartic    ', b(4)
!WRITE(*, '(a, g13.5)') ' Quintic    ', b(5)
!WRITE(*, *) ' Knot position   Quintic Coefficient'
!DO j = 1, nk
!  WRITE(*, '(g13.5, t17, g13.5)') knot(j), b(5+j)
!END DO

! Calculate fitted values and derivatives


!call Ordena(X0,n,II)
next_knot = 1
DO i = 1, n
next_knot = 1
t=X0(i)
xrow(0) = one
xrow(1) = (t - t1)
xrow(2) = (t - t1) * xrow(1)
xrow(3) = (t - t1) * xrow(2)
xrow(4) = (t - t1) * xrow(3)
xrow(5) = (t - t1) * xrow(4)
if (i.eq.45) then
continue
end if
55 continue
IF (t > knot(next_knot)) THEN
next_knot = next_knot + 1
IF (next_knot <= nk) THEN
!      WRITE(9, '(a, g13.5)') 'New knot at t = ', knot(next_knot-1)
goto 55
ELSE
next_knot = nk + 1 
goto 56
END IF
END IF

56 continue
DO j = 1, next_knot-1
xrow(5+j) = (t - knot(j))**5
END DO
p0(i) = DOT_PRODUCT( b(0:5+next_knot-1), xrow(0:5+next_knot-1) )
p2(i) = ((20*b(5)*(t-t1) + 12*b(4))*(t-t1) + 6*b(3))*(t-t1) +2*b(2)
p1(i) = (((5*b(5)*(t-t1) + 4*b(4))*(t-t1) + 3*b(3))*(t-t1) +2*b(2))*(t-t1) + b(1)
DO j = 1, next_knot-1
p1(i) = p1(i) + 5*b(j+5)*(t - knot(j))**4
p2(i) = p2(i) + 20*b(j+5)*(t - knot(j))**3
END DO
!  WRITE(9, '(f8.3, 4g13.4)') t, d1, d2, fitted, y

!  write (*,*) i
END DO
deallocate ( knot,xrow, b )
else
p0=-1
p1=-1
p2=-1
end if


end subroutine





!******************************************
!
!		Subroutine	INTERPOLA
!
!*****************************************


subroutine Interpola (Xgrid,Pgrid,kbin,X0,P0,n)

! Fit a quintic spline with user control of knot positions.
! If the knots are at tk1, tk2, ..., then the fitted spline is
! b0 + b1.t + b2.t^2 + b3.t^3 + b4.t^4 + b5.t^5    for t <= tk1
! b0 + ... + b5.t^5 + b6.(t-tk1)^5                 for tk1 < t <= tk2
! b0 + ... + b5.t^5 + b6.(t-tk1)^5 + b7.(t-tk2)^5  for tk2 < t <= tk3
! b0 + ... + b5.t^5 + b6.(t-tk1)^5 + b7.(t-tk2)^5 + b8.(t-tk3)^5
!                                                  for tk3 < t <= tk4, etc.

! In this version, the knots are evenly spaced.
! Also calculates first & 2nd derivatives of the spline.

! Uses the author's least-squares package in file lsq.f90
! Latest revision - 2 November 2003
! Alan Miller (amiller @ bigpond.net.au)

USE lsq
IMPLICIT NONE

INTEGER                 :: i, ier, j, n, nk,next_knot,kbin,icont
double precision               :: t, t1, y, dist,&
Xgrid(kbin),Pgrid(kbin),X0(n),P0(n)


double precision,allocatable::P1(:),P2(:)





double precision, PARAMETER    :: one = 1.0_dp,cero=0.0_dp
double precision, ALLOCATABLE  :: knot(:), xrow(:), b(:)


allocate (P1(n),P2(n))
icont=0
do i=1,kbin
if (pgrid(i).ne.-1.0) icont=icont+1
end do

if (icont.gt.5) then
nk=icont/5


!numero de nodos
!if (nk>kbin/5) pause '** Too many knots requested - TRY AGAIN'

ALLOCATE ( knot(nk),xrow(0:5+nk), b(0:5+nk) )


! Calculate knot positions, evenly spaced.

dist = (Xgrid(kbin) - Xgrid(1)) / (nk + 1)
t1=Xgrid(1)
DO i = 1, nk
knot(i) = t1 + dist * i
END DO

! WRITE(9, '(a, i4)') 'Number of knots = ', nk


next_knot = 1

! Initialize the least-squares calculations
CALL startup(6+nk, .FALSE.)

DO i=1,kbin
t=Xgrid(i)
y=Pgrid(i)
xrow(0) = one
xrow(1) = (t - t1)
xrow(2) = (t - t1) * xrow(1)
xrow(3) = (t - t1) * xrow(2)
xrow(4) = (t - t1) * xrow(3)
xrow(5) = (t - t1) * xrow(4)
IF (t > knot(next_knot)) next_knot = MIN(nk, next_knot + 1)
DO j = 1, next_knot-1
xrow(5+j) = (t - knot(j))**5
END DO
xrow(5+next_knot:5+nk) = 0.0_dp
if (y.ne.-1.0_dp) CALL includ(one, xrow, y)

END DO

CALL regcf(b, 6+nk, ier)

!WRITE(*, *) ' Coefficient   Value'
!WRITE(*, '(a, g13.5)') ' Constant   ', b(0)
!WRITE(*, '(a, g13.5)') ' Linear     ', b(1)
!WRITE(*, '(a, g13.5)') ' Quadratic  ', b(2)
!WRITE(*, '(a, g13.5)') ' Cubic      ', b(3)
!WRITE(*, '(a, g13.5)') ' Quartic    ', b(4)
!WRITE(*, '(a, g13.5)') ' Quintic    ', b(5)
!WRITE(*, *) ' Knot position   Quintic Coefficient'
!DO j = 1, nk
!  WRITE(*, '(g13.5, t17, g13.5)') knot(j), b(5+j)
!END DO

! Calculate fitted values and derivatives


!call Ordena(X0,n,II)
next_knot = 1
DO i = 1, n
next_knot = 1
t=X0(i)
xrow(0) = one
xrow(1) = (t - t1)
xrow(2) = (t - t1) * xrow(1)
xrow(3) = (t - t1) * xrow(2)
xrow(4) = (t - t1) * xrow(3)
xrow(5) = (t - t1) * xrow(4)
if (i.eq.45) then
continue
end if
55 continue  
IF (t > knot(next_knot)) THEN
next_knot = next_knot + 1
IF (next_knot <= nk) THEN
!      WRITE(9, '(a, g13.5)') 'New knot at t = ', knot(next_knot-1)
goto 55
ELSE
next_knot = nk + 1 
goto 56
END IF
END IF

56 continue
DO j = 1, next_knot-1
xrow(5+j) = (t - knot(j))**5
END DO
p0(i) = DOT_PRODUCT( b(0:5+next_knot-1), xrow(0:5+next_knot-1) )
p2(i) = ((20*b(5)*(t-t1) + 12*b(4))*(t-t1) + 6*b(3))*(t-t1) + 2*b(2)
p1(i) = (((5*b(5)*(t-t1) + 4*b(4))*(t-t1) + 3*b(3))*(t-t1) + 2*b(2))*(t-t1) + b(1)
DO j = 1, next_knot-1
p1(i) = p1(i) + 5*b(j+5)*(t - knot(j))**4
p2(i) = p2(i) + 20*b(j+5)*(t - knot(j))**3
END DO
!  WRITE(9, '(f8.3, 4g13.4)') t, d1, d2, fitted, y

!  write (*,*) i
END DO
deallocate ( knot,xrow, b )
else
p0=-1
p1=-1
p2=-1
end if

deallocate (P1,P2)
end



!***************************************************
!		
!			REGRESION LINEAL
!
!***************************************************




subroutine Reglineal (X,Y,W,n,p,Beta)
implicit none
integer i,n,j,p,iopt
double precision X(n),Y(n),W(n),beta(p+1),&
sterr(p+1),se,r2,X2(n,p+1)
do i=1,n
do j=1,p
X2(i,j)=X(i)**j
end do
end do
iopt=0
call WRegresion(X2,Y,W,n,p,beta,sterr,se,r2,iopt)
end







!********************************
! GRID
!*********************************
subroutine GRID(X,W,n,Xb,nb)

implicit none
integer i,nb,n
double precision X(n),W(n),xmin,xmax,Xb(nb)
xmin=9e9
xmax=-xmin
do i=1,n
if (W(i).gt.0) then
xmin=min(X(i),xmin)
xmax=max(X(i),xmax)
end if
end do

do i=1,nb
Xb(i)=xmin+(i-1)*(xmax-xmin)/(nb-1)
end do
end






!***************************************************
!		
!			BINNING LINEAL
!
!***************************************************


subroutine Binning(X,Y,n,W,Xb,Yb,Wb,kbin)
implicit none
integer n,i,j,kbin
double precision x(n),y(n),W(n),Xb(kbin),Yb(kbin),Wb(kbin),&
Area(2),dis1,dis2


!CONSTRUCCIÓN DE LA MUESTRA BINNING
Wb=0
Yb=0
do i=1,n
if (W(i).gt.0) then
if (X(i).lt.Xb(1)) then
Wb(1)=wb(1)+W(i)
yb(1)=yb(1)+W(i)*Y(i)
elseif (X(i).gt.Xb(kbin)) then
Wb(kbin)=wb(kbin)+W(i)
yb(kbin)=yb(kbin)+W(i)*Y(i)
else
do j=1,kbin-1
if (Xb(j).le.X(i).and.X(i).le.Xb(j+1)) then
dis1=X(i)-Xb(j)
dis2=Xb(j+1)-X(i)
Area(1)=dis2/(dis1+dis2)
Area(2)=dis1/(dis1+dis2)
Wb(j)=Wb(j)+W(i)*Area(1)
Yb(j)=Yb(j)+Y(i)*W(i)*Area(1)
Wb(j+1)=Wb(j+1)+W(i)*Area(2)
Yb(j+1)=Yb(j+1)+Y(i)*W(i)*Area(2)
end if
end do
end if
end if
end do
do i=1,kbin
if (Wb(i).gt.0) Yb(i)=Yb(i)/Wb(i)
end do
end