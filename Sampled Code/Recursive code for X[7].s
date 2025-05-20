#Assumption twiddle factor is 1 for all calculations.
.data
Data:       .float 1,5,3,7,2,6,4,8    # Bit-reversed input
Result:     .space 32                  # 8 floats for final output
One:        .float 1.0                # Twiddle factor = 1.0

.text
main:
    # Copy Data to Result
    la a0, Data
    la a1, Result
    li a2, 8                   # Number of elements
    jal copy_array

    # Load twiddle factor into fa1
    la a0, One
    flw fa1, 0(a0)

    # Call recursive FFT on Result
    la a0, Result
    li a1, 0                   # Start index
    li a2, 8                   # Size
    jal fft_recursive

    j exit

# Function to copy array
copy_array:
    # a0: source, a1: destination, a2: count
    mv t0, a0
    mv t1, a1
    li t2, 0                   # Loop counter
copy_loop:
    bgeu t2, a2, copy_done
    lw t3, 0(t0)              # Load word from Data
    sw t3, 0(t1)              # Store word to Result
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, 1
    j copy_loop
copy_done:
    ret

# Recursive FFT function
fft_recursive:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw a0, 8(sp)              # Save Result address
    sw a1, 4(sp)              # Save start index
    sw a2, 0(sp)              # Save size

    li t0, 1
    beq a2, t0, end_fft       # Base case: size 1

    srli t1, a2, 1            # half = size / 2

    # Recursively process first half
    lw a0, 8(sp)
    lw a1, 4(sp)
    mv a2, t1
    jal ra, fft_recursive

    # Recursively process second half
    lw a0, 8(sp)
    lw a1, 4(sp)
    lw a2, 0(sp)
    srli t1, a2, 1
    add a1, a1, t1            # start + half
    mv a2, t1
    jal ra, fft_recursive

    # Combine the two halves
    lw a0, 8(sp)
    lw a1, 4(sp)
    lw a2, 0(sp)
    srli t1, a2, 1            # half

    li t2, 0                  # k = 0
combine_loop:
    bgeu t2, t1, end_combine

    # Calculate even element address
    add t3, a1, t2
    slli t3, t3, 2
    add t3, a0, t3
    flw ft0, 0(t3)            # even = Result[start + k]

    # Calculate odd element address
    add t4, a1, t1
    add t4, t4, t2
    slli t4, t4, 2
    add t4, a0, t4
    flw ft1, 0(t4)            # odd = Result[start + half + k]

    # Butterfly operation
    fadd.s ft2, ft0, ft1      # even + odd
    fsub.s ft3, ft0, ft1      # even - odd

    fsw ft2, 0(t3)
    fsw ft3, 0(t4)

    addi t2, t2, 1
    j combine_loop

end_combine:
end_fft:
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

exit:
    # Exit program
    nop