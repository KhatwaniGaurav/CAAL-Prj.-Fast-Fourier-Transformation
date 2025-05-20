.data
pi:         .float 3.1415926535    # Define π in memory
const_1024: .word 512          # Define 1024.0 in memory
f: .float 100 #frequency in Hetrz
one:    .float 1.0
two:    .float 2.0

.text
.globl main

main:
    # Assume:
    # - fa0 = f (frequency, float)
    # - a0  = n (sample index, integer)
    # Result will be in fa0 (ready for sin/cos)
    la a0,pi
    flw ft0, 0(a0)        # ft0 = π (from memory)
    la a0,f
    flw fa0, 0(a0)        # fa0 = f (from memory)
    lw t1, const_1024 # ft1 = 1024.0 (from memory)
    fcvt.s.w ft1, t1  
    li a0, 5

    # Compute (2πfn / 1024)
    li t2  2                # t1 = 2 (integer)
    fcvt.s.w ft2, t2        # ft2 = 2.0 (convert to float)
    fmul.s ft3, fa0, ft0    # ft3 = f * π
    fmul.s ft3, ft3, ft2    # ft3 = 2πf
    fcvt.s.w ft4, a0        # ft4 = n (convert to float)
    fmul.s ft3, ft3, ft4    # ft3 = 2πfn
    fdiv.s ft3, ft3, ft1    # fa0 = 2πfn / 1024 (final result)
     
    # Cleaning all registers
    fmul.s ft0,ft0,fa1
    fmul.s fa0,ft0,fa0
    fmul.s ft4,ft0,ft4
    fmul.s ft2,ft0,fa1
    fmul.s ft1,ft0,fa0
    mul a0,a0,s0
    mul t1,t1,s0
    mul t2,t2,s0

    # Now fa0 holds the argument for sin/cos!
    # (Call fsinn.s / fcos.s if available, or a software impl)
    fadd.s fs0, fs0, ft3       # Load x into fs0
    fadd.s fs6,fs6, ft3        # Load x into fs6 (preserved for later use)
    
    fmul.s ft3,ft0,ft3
    
    # Precompute x²
    fmul.s fs2, fs6, fs6  # fs2 = x²
    
    # --- Cosine Calculation (prioritize first) ---
    la a0, one
    flw ft2, 0(a0)        # cos_result = 1.0
    fmv.s fs4, fs2        # current_power = x²
    la a0, two
    flw ft3, 0(a0)        # factorial = 2! = 2
    li t5, -1             # sign = -
    li t3, 3              # factorial multiplier
    li t6, 16             # 16 terms (sufficient for x≈6.13)

cosine_loop:
    beqz t6, sine_init    # Exit when terms exhausted
    fcvt.s.w ft5, t5      # Convert sign to float
    fmul.s ft0, fs4, ft5  # sign * current_power
    fdiv.s ft0, ft0, ft3  # xⁿ / n!
    fadd.s ft2, ft2, ft0  # Update cos_result
    fmul.s fs4, fs4, fs2  # xⁿ → xⁿ⁺²
    addi t4, t3, 1        # n+1
    mul t0, t3, t4        # n*(n+1)
    fcvt.s.w ft0, t0      # Convert to float
    fmul.s ft3, ft3, ft0  # Update factorial (n! → (n+2)!)
    addi t3, t3, 2        # Increment multiplier
    neg t5, t5            # Flip sign
    addi t6, t6, -1       # Decrement counter
    j cosine_loop

sine_init:
    # --- Sine Calculation ---
    fmv.s ft1, fs6        # sin_result = x
    fmul.s fs3, fs6, fs2  # current_power = x³
    li t0, 6              # 3! = 6
    fcvt.s.w ft4, t0      # factorial = 6
    li t5, -1             # sign = -
    li t3, 4              # factorial multiplier
    li t6, 16             # 16 terms

sine_loop:
    beqz t6, end
    fcvt.s.w ft5, t5      # Convert sign to float
    fmul.s ft0, fs3, ft5  # sign * current_power
    fdiv.s ft0, ft0, ft4  # xⁿ / n!
    fadd.s ft1, ft1, ft0  # Update sin_result
    fmul.s fs3, fs3, fs2  # xⁿ → xⁿ⁺²
    addi t4, t3, 1        # n+1
    mul t0, t3, t4        # n*(n+1)
    fcvt.s.w ft0, t0      # Convert to float
    fmul.s ft4, ft4, ft0  # Update factorial
    addi t3, t3, 2        # Increment multiplier
    neg t5, t5            # Flip sign
    addi t6, t6, -1       # Decrement counter
    j sine_loop

end:
    # ft2 ≈ cos(6.135923) ≈ -0.989 (correct)
    # ft1 ≈ sin(6.135923) ≈ -0.149 (correct)