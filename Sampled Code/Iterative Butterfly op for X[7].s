#Assumption twiddle factor is 1 for all calculations.
.data
Data:       .float 1,5,3,7,2,6,4,8    # Bit-reversed input
Result:     .space 32                  # 8 floats for final output
One:        .float 1.0                # Twiddle factor = 1.0

.text
main:
    la a0, Data        # Load input address
    la a1, Result      # Load output address
    la a2, One         # Load address of 1.0
    flw fa1, 0(a2)     # fa1 = 1.0 (Wn^k = 1)

    # Load input (bit-reversed)
    flw fs0, 0(a0)     # fs0 = 1
    flw fs1, 4(a0)     # fs1 = 5
    flw fs2, 8(a0)     # fs2 = 3
    flw fs3, 12(a0)    # fs3 = 7
    flw fs4, 16(a0)    # fs4 = 2
    flw fs5, 20(a0)    # fs5 = 6
    flw fs6, 24(a0)    # fs6 = 4
    flw fs7, 28(a0)    # fs7 = 8

Two_Point_DFT:
    # X3 = [1,3], X4 = [5,7], X5 = [2,4], X6 = [6,8]
    fmadd.s ft0, fs0, fa1, fs2   # X3[0] = 1 + 3 = 4
    fmsub.s ft1, fs0, fa1, fs2   # X3[1] = 1 - 3 = -2
    fmadd.s ft2, fs1, fa1, fs3   # X4[0] = 5 + 7 = 12
    fmsub.s ft3, fs1, fa1, fs3   # X4[1] = 5 - 7 = -2
    fmadd.s ft4, fs4, fa1, fs6   # X5[0] = 2 + 4 = 6
    fmsub.s ft5, fs4, fa1, fs6   # X5[1] = 2 - 4 = -2
    fmadd.s ft6, fs5, fa1, fs7   # X6[0] = 6 + 8 = 14
    fmsub.s ft7, fs5, fa1, fs7   # X6[1] = 6 - 8 = -2

    # Store Stage 1 results
    fsw ft0, 0(a1)     # X3[0] = 4
    fsw ft1, 4(a1)     # X3[1] = -2
    fsw ft2, 8(a1)     # X4[0] = 12
    fsw ft3, 12(a1)    # X4[1] = -2
    fsw ft4, 16(a1)    # X5[0] = 6
    fsw ft5, 20(a1)    # X5[1] = -2
    fsw ft6, 24(a1)    # X6[0] = 14
    fsw ft7, 28(a1)    # X6[1] = -2

Four_Point_DFT:

    # Load X3 and X4 for X1
    flw ft0, 0(a1)     # X3[0] = 4
    flw ft1, 8(a1)     # X4[0] = 12
    flw ft2, 4(a1)     # X3[1] = -2
    flw ft3, 12(a1)    # X4[1] = -2

    # Compute X1
    fmadd.s ft4, ft0, fa1, ft1   # X1[0] = 4 + 12 = 16
    fmsub.s ft5, ft0, fa1, ft1   # X1[2] = 4 - 12 = -8
    fmadd.s ft6, ft2, fa1, ft3   # X1[1] = -2 + (-2) = -4
    fmsub.s ft7, ft2, fa1, ft3   # X1[3] = -2 - (-2) = 0

    # Store X1
    fsw ft4, 0(a1)     # X1[0] = 16
    fsw ft6, 4(a1)     # X1[1] = -4
    fsw ft5, 8(a1)     # X1[2] = -8
    fsw ft7, 12(a1)    # X1[3] = 0

    # Load X5 and X6 for X2
    flw ft0, 16(a1)    # X5[0] = 6
    flw ft1, 24(a1)    # X6[0] = 14
    flw ft2, 20(a1)    # X5[1] = -2
    flw ft3, 28(a1)    # X6[1] = -2

    # Compute X2
    fmadd.s ft4, ft0, fa1, ft1   # X2[0] = 6 + 14 = 20
    fmsub.s ft5, ft0, fa1, ft1   # X2[2] = 6 - 14 = -8
    fmadd.s ft6, ft2, fa1, ft3   # X2[1] = -2 + (-2) = -4
    fmsub.s ft7, ft2, fa1, ft3   # X2[3] = -2 - (-2) = 0

    # Store X2
    fsw ft4, 16(a1)    # X2[0] = 20
    fsw ft6, 20(a1)    # X2[1] = -4
    fsw ft5, 24(a1)    # X2[2] = -8
    fsw ft7, 28(a1)    # X2[3] = 0

Eight_Point_DFT:

    # Load X1 and X2
    flw ft0, 0(a1)     # X1[0] = 16
    flw ft1, 16(a1)    # X2[0] = 20
    flw ft2, 4(a1)     # X1[1] = -4
    flw ft3, 20(a1)    # X2[1] = -4
    flw ft4, 8(a1)     # X1[2] = -8
    flw ft5, 24(a1)    # X2[2] = -8
    flw ft6, 12(a1)    # X1[3] = 0
    flw ft7, 28(a1)    # X2[3] = 0
    
    flw fs0, 0(a1)     # X1[0] = 16
    flw fs2, 4(a1)     # X1[1] = -4
    flw fs4, 8(a1)     # X1[2] = -8
    flw fs6, 12(a1)    # X1[3] = 0


    # Compute final X[k]
    fadd.s ft0, ft0, ft1        # X[0] = 16 + 20 = 36
    fsub.s ft1, fs0, ft1        # X[4] = 16 - 20 = -4
    fadd.s ft2, ft2, ft3        # X[1] = -4 + (-4) = -8
    fsub.s ft3, fs2, ft3        # X[5] = -4 - (-4) = 0
    fadd.s ft4, ft4, ft5        # X[2] = -8 + (-8) = -16
    fsub.s ft5, fs4, ft5        # X[6] = -8 - (-8) = 0
    fadd.s ft6, ft6, ft7        # X[3] = 0 + 0 = 0
    fsub.s ft7, fs6, ft7        # X[7] = 0 - 0 = 0

    # Store final results
    fsw ft0, 0(a1)     # X[0] = 36
    fsw ft2, 4(a1)     # X[1] = -8
    fsw ft4, 8(a1)     # X[2] = -16
    fsw ft6, 12(a1)    # X[3] = 0
    fsw ft1, 16(a1)    # X[4] = -4
    fsw ft3, 20(a1)    # X[5] = 0
    fsw ft5, 24(a1)    # X[6] = 0
    fsw ft7, 28(a1)    # X[7] = 0

exit:
  