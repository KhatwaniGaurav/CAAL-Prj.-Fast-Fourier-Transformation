
.data
Value_x: .float 2.16

.text
.globl main

main:
 la a0,Value_x
 flw fs0, 0(a0)
 flw fs6, 0(a0)

 #Starting from second term since first term will either be x or 1
Second_term:  #For Cosine Taylor Series
 fmul.s fs0,fs0,fs6  #x^2 
 addi t0,t0,2
 fcvt.s.w ft0,t0
 fdiv.s fs1,fs0,ft0  #x^2/2
 sub t0,t0,t0 
 
Third_term:  #For Sine Taylor Series
 fmul.s fs0,fs0,fs6  #x^3
 addi t0,t0,6
 fcvt.s.w ft0,t0
 fdiv.s fs2,fs0,ft0  #x^3/6
 sub t0,t0,t0 
 
Fourth_term:  #For Cosine Taylor Series
 fmul.s fs0,fs0,fs6  #x^4
 addi t0,t0,24
 fcvt.s.w ft0,t0
 fdiv.s fs3,fs0,ft0  #x^4/24
 sub t0,t0,t0 

Fifth_term:  #For Sine Taylor Series
 fmul.s fs0,fs0,fs6  #x^5 
 addi t0,t0,120
 fcvt.s.w ft0,t0
 fdiv.s fs4,fs0,ft0  #x^5/120
 sub t0,t0,t0 
    
Sixth_term:  #For Cosine Taylor Series
 fmul.s fs0,fs0,fs6  #x^6
 addi t0,t0,720
 fcvt.s.w ft0,t0
 fdiv.s fs5,fs0,ft0    #x^6/720
 sub t0,t0,t0  
 
 #Cant go any further in Iterative approach because  addi t0,t0,5040 or higher values than 6! aren't able to be stored, due to 12 bit immediate limitation 
Sine_Calculation: 
flw fs0, 0(a0)
fsub.s ft1,fs0,fs2 # sin = x - x^3/6
fadd.s ft1,ft1,fs4 # sin += x^5/120
 
Cosine_Calculation:
addi s0,s0,1
fcvt.s.w fs0,s0
fsub.s ft2,fs0,fs1  #cos -= x^2/2
fadd.s ft2,ft2,fs3   #cos += x^4/24
fsub.s ft2,ft2,fs5  #cos -= x^2/2
