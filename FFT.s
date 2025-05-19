#define STDOUT 0xd0580000

.section .text
.global _start
_start:
## START YOUR CODE HERE

.data
real-x:      .space 4096          # 1024 floats
imag-x:      .space 4096          # 1024 floats
tw_real:     .space 4096          # 1024 twiddle real parts
tw_imag:     .space 4096          # 1024 twiddle imag parts
pi:          .float 3.1415926535
two:         .float 2.0
one:         .float 1.0
N:           .word 1024

.text
.globl _start
_start:
    # Bit Reversal on real and imaginary parts
    la s0, real-x
    jal BitRevFunc
    la s0, imag-x
    jal BitRevFunc

    # Generate twiddle factors
    jal GenTwdl

    # Run the FFT
    jal FFTMain

    # Exit
    li a7, 93
    li a0, 0
    ecall

BitRevFunc:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t0, 0              # i=0
    li s1, 1024           # N
    li t2, 4              # element size (*4)

BRLoop:
    bge t0, s1, BRend
    mul t3, t0, t2
    add t3, s0, t3

    mv a0, t0
    jal BitRev
    mv t6, a1

    bge t0, t6, NoSwap

    mul s2, t6, t2
    add s2, s0, s2

    lw t4, 0(t3)
    lw t5, 0(s2)
    sw t5, 0(t3)
    sw t4, 0(s2)

NoSwap:
    addi t0, t0, 1
    j BRLoop

BRend:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

BitRev:
    li t1, 0
    li s4, 10
BitRevCalc:
    slli t1, t1, 1
    andi t5, a0, 1
    or t1, t1, t5
    srli a0, a0, 1
    addi s4, s4, -1
    bnez s4, BitRevCalc

    li a1, 0x3FF
    and a1, t1, a1
    ret

GenTwdl:
    li t0, 0              # i
    li t1, 1024

TwdlLoop:
    bge t0, t1, TwdlDone

    # Calc angle = 2πi / 1024
    la a0, pi
    flw ft0, 0(a0)
    li t2, 2
    fcvt.s.w ft2, t2
    fmul.s ft0, ft0, ft2         

    fcvt.s.w ft3, t0
    fmul.s ft4, ft0, ft3         

    la a0, N
    lw t3, 0(a0)
    fcvt.s.w ft5, t3
    fdiv.s ft6, ft4, ft5         

    fmv.s fs0, ft6
    fmv.s fs6, ft6
    fmul.s fs2, fs6, fs6         

    # cosine computation
    la a0, one
    flw ft2, 0(a0)
    fmv.s fs4, fs2
    la a0, two
    flw ft3, 0(a0)
    li t5, -1
    li t3, 3
    li t6, 16

cosLoop:
    beqz t6, cosDone
    fcvt.s.w ft5, t5
    fmul.s ft0, fs4, ft5
    fdiv.s ft0, ft0, ft3
    fadd.s ft2, ft2, ft0
    fmul.s fs4, fs4, fs2
    addi t4, t3, 1
    mul t0, t3, t4
    fcvt.s.w ft0, t0
    fmul.s ft3, ft3, ft0
    addi t3, t3, 2
    neg t5, t5
    addi t6, t6, -1
    j cosLoop

cosDone:
    # Store cos to tw_real[i]
    la a0, tw_real
    li t4, 4
    mul t5, t0, t4
    add a0, a0, t5
    fsw ft2, 0(a0)

    # sine computation
    fmv.s ft1, fs6
    fmul.s fs3, fs6, fs2
    li t0, 6
    fcvt.s.w ft4, t0
    li t5, -1
    li t3, 4
    li t6, 16

sineLoop:
    beqz t6, sineDone
    fcvt.s.w ft5, t5
    fmul.s ft0, fs3, ft5
    fdiv.s ft0, ft0, ft4
    fadd.s ft1, ft1, ft0
    fmul.s fs3, fs3, fs2
    addi t4, t3, 1
    mul t0, t3, t4
    fcvt.s.w ft0, t0
    fmul.s ft4, ft4, ft0
    addi t3, t3, 2
    neg t5, t5
    addi t6, t6, -1
    j sineLoop

sineDone:
    la a0, tw_imag
    li t4, 4
    mul t5, t0, t4
    add a0, a0, t5
    fsw ft1, 0(a0)

    addi t0, t0, 1
    j TwdlLoop
TwdlDone:
    ret


FFTMain:
    li t7, 0                
FFTCalc:
    li t0, 1
    sll t2, t0, t7          # m=2^stage
    srl t1, t2, 1           # mhalf=m/2

    li t5, 0                # j=0
BlockLoop:
    li t9, 1024
    bge t5, t9, NextStage

    mv t6, t1
    vsetvli t6, t6, e32, m1

    la a0, real-x
    la a1, imag-x
    add t8, a0, t5
    vle32.v v0, (t8)
    add t8, a1, t5
    vle32.v v1, (t8)

    add t9, t5, t1
    add t8, a0, t9
    vle32.v v2, (t8)
    add t8, a1, t9
    vle32.v v3, (t8)

    la a2, tw_real
    la a3, tw_imag
    add t8, a2, t5
    vle32.v v4, (t8)
    add t8, a3, t5
    vle32.v v5, (t8)

    vmul.vv v6, v2, v4
    vmul.vv v7, v3, v5
    vsub.vv v8, v6, v7

    vmul.vv v6, v2, v5
    vmul.vv v7, v3, v4
    vadd.vv v9, v6, v7

    vadd.vv v10, v0, v8
    vsub.vv v11, v0, v8

    vadd.vv v12, v1, v9
    vsub.vv v13, v1, v9

    add t8, a0, t5
    vse32.v v10, (t8)
    add t9, t5, t1
    add t8, a0, t9
    vse32.v v11, (t8)

    add t8, a1, t5
    vse32.v v12, (t8)
    add t9, t5, t1
    add t8, a1, t9
    vse32.v v13, (t8)

    add t5, t5, t2
    j BlockLoop

NextStage:
    addi t7, t7, 1
    li t3, 10
    blt t7, t3, FFTCalc
    ret

## END YOU CODE HERE

# Function to print a matrix for debugging purposes
# This function iterates over all elements of a matrix stored in memory.
# Instead of calculating the end address in each iteration, it precomputes 
# the end address (baseAddress + size^2 * 4) to optimize the loop.
# Input:
#   a0: Base address of the matrix
#   a1: Size of matrix
# Clobbers:
#   t0, t1, ft0
printToLog:
    li t0, 0x123                #  Identifiers used for python script to read logs
    li t0, 0x456
    mv a1, a1                   # moving size to get it from log 
    mv t0, a0                   # Copy the base address of the matrix to t0 to avoid modifying a0
    mul t1, a1, a1              # size^2 
    slli  t1, t1, 2             # size^2 * 4 (total size of the matrix in bytes)
    add t1, a0, t1              # Calculate the end address (base address + total size)

    printMatrixLoop:
        bge t0, t1, printMatrixLoopEnd 
        flw ft0, 0(t0)          # Load from array
        addi t0, t0, 4          # increment address by elem size
        j printMatrixLoop
    printMatrixLoopEnd:

    li t0, 0x123                #  Identifiers used for python script to read logs
    li t0, 0x456

    jr ra


# Function: _finish
# VeeR Related function which writes to to_host which stops the simulator
_finish:
    li x3, 0xd0580000
    addi x5, x0, 0xff
    sb x5, 0(x3)
    beq x0, x0, _finish

    .rept 100
        nop
    .endr


.data
## ALL DATA IS DEFINED HERE LIKE MATRIX, CONSTANTS ETC

## DATA DEFINE START
.equ MatrixSize, 5
matrix:
    .float -10.0, 13.0, 10.0, -3.0, 2.0
    .float 6.0, 15.0, 4.0, 13.0, 4.0
    .float 18.0, 2.0, 9.0, 8.0, -4.0
    .float 5.0, 4.0, 12.0, 17.0, 6.0
    .float -10.0, 7.0, 13.0, -3.0, 16.0
## DATA DEFINE END
size: .word MatrixSize