	.data
T0: .space 4 # the pointers to your lookup tables
T1: .space 4
T2: .space 4
T3: .space 4
	
input: .space 512
prompt: .asciiz "Enter a string: "
inputprompt: .asciiz "Input: "
outputprompt: .asciiz "Output: "
result: .word 0:512
	
s: .word 0xd82c07cd, 0xc2094cbd, 0x6baa9441, 0x42485e3f
message: .word 0x00000000, 0x00000000, 0x00000000, 0x00000000
	
ciphertext: .word 0x00000000, 0x00000000, 0x00000000, 0x00000000
	
key: .word 0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c #0x6920e299, 0xa5202a6d, 0x656e6368, 0x69746f2a 0x6920e299, 0xa5202a6d, 0x656e6368, 0x69746f2a
rkey: .word 0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c
rcon: .word 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
t: .word 0, 0, 0, 0
fin: .asciiz "C:\\Users\\egeaktemur\\Desktop\\tables.dat"
buffer: .space 12288
	
	.text
	.globl main
main:
	# open a file for writing
	li $v0, 13
	la $a0, fin
	li $a1, 0
	li $a2, 0
	syscall
	move $s6, $v0
	# read from file
	li $v0, 14
	move $a0, $s6
	la $a1, buffer
	li $a2, 12288
	syscall
	move $s0, $v0
	la $s1, buffer
	# Allocating 256 * 4 bytes for each table on the heap memory.
	li $v0, 9
	li $a0, 1024
	syscall
	sw $v0, T0
	li $v0, 9
	li $a0, 1024
	syscall
	sw $v0, T1
	li $v0, 9
	li $a0, 1024
	syscall
	sw $v0, T2
	li $v0, 9
	li $a0, 1024
	syscall
	sw $v0, T3
	la $s2, T0
	lw $s2, 0($s2)
	jal convert_strings
	la $s2, T1
	lw $s2, 0($s2)
	jal convert_strings
	la $s2, T2
	lw $s2, 0($s2)
	jal convert_strings
	la $s2, T3
	lw $s2, 0($s2)
	jal convert_strings
	
	li $v0, 4
	la $a0, prompt
	syscall
	li $v0, 8
	la $a0, input
	li $a1, 512
	syscall
	la $t0, input
	li $t1, 0
	li $t5, '\n'
	li $t6, 0
	la $s0, result
	jal convert_input
	
	j Exit
	
convert_input:
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
	j convert
	
convert:
	lb $t2, 0($t0)
	beq $t2, $t5, exit_converting
	beqz $t2, exit_converting
	li $t4, 4
	addi $t6, $t6, 1
	
convert_input_loop:
	li $t3, 0
	li $t8, 4
	beq $t4, 0, convert
	addi $t1, $t1, 1 # increment global counter
	addi $t4, $t4, -1
	
convert4:
	lb $t2, 0($t0)
	
	beq $t2, $t5, end_converting
	beqz $t2, end_converting
	
	addi $t8, $t8, -1 # increment local counter
	addi $t6, $t8, 0
	sll $t6, $t6, 3
	
	addi $t7, $t2, 0
	sllv $t7, $t7, $t6
	add $t3, $t7, $t3
	
	addi $t0, $t0, 1 # Increment input buffer address
	bne $t8, 0, convert4
	
end_converting:
	la $s0, result
	addi $t2, $t1, -1
	sll $t2, $t2, 2
	add $t2, $s0, $t2
	sw $t3, 0($t2)
	j convert_input_loop
	
exit_converting2:
	li $v0, 11
	li $a0, '\n'
	syscall
	la $a2, key
	lw $s1, 0($a2)
	la $a3, rkey
	sw $s1, 0($a3)
	lw $s1, 4($a2)
	sw $s1, 4($a3)
	lw $s1, 8($a2)
	sw $s1, 8($a3)
	lw $s1, 12($a2)
	sw $s1, 12($a3)
	
	sub $sp, $sp, 8
	sw $t6, 0($sp)
	sw $s0, 4($sp)

	jal key_schedule
	
	lw $s0, 4($sp)
	lw $t6, 0($sp)
	add $sp, $sp, 8
	
	li $v0, 4
	la $a0, outputprompt
	syscall
	
	la $a1, ciphertext
	lw $a0, ($a1)     
	li $v0, 34 
	syscall
	li $v0, 11
	li $a0, ','
	syscall
	lw $a0, 4($a1)   
	li $v0, 34
	syscall
	li $v0, 11
	li $a0, ','
	syscall
	lw $a0, 8($a1) 
	li $v0, 34  
	syscall
	li $v0, 11
	li $a0, ','
	syscall
	lw $a0, 12($a1) 
	li $v0, 34 
	syscall
        li $v0, 11
        la $a0, '\n'
        syscall
	
exit_converting:
	beq $t6, 0, Exit
	addi $t6, $t6, -1
	lw $t2, ($s0)
	beq $t2, $t5, Exit1
	beqz $t2, Exit1
	li $t0, 0
	li $v0, 4
	la $a0, inputprompt
	syscall
	
print_loop:
	
	
	lw $t1, ($s0)
	la $s1, message
	sll $t9, $t0, 2
	add $s1, $s1, $t9
	sw $t1, 0($s1)
	lw $a0, ($s0)
	li $v0, 34
	syscall
	addi $s0, $s0, 4
	addi $t0, $t0, 1
	beq $t0, 4, exit_converting2
	li $v0, 11
	li $a0, ','
	syscall
	j print_loop
	
convert_strings:
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
	li $t0, 256
	j convert_loop
	
convert_loop:
	#covert each digit to integers and sum them to convert it to decimal / binary
	beq $t0, 0, Exit1
	li $t1, 0
	
	lbu $a0, 2($s1)
	jal convert_hex_to_bin
	addiu $t1, $v0, 0
	sll $t1, $t1, 28
	
	lbu $a0, 3($s1)
	jal convert_hex_to_bin
	addiu $t2, $v0, 0
	sll $t2, $t2, 24
	add $t1, $t1, $t2
	
	lbu $a0, 4($s1)
	jal convert_hex_to_bin
	addiu $t2, $v0, 0
	sll $t2, $t2, 20
	add $t1, $t1, $t2
	
	lbu $a0, 5($s1)
	jal convert_hex_to_bin
	addiu $t2, $v0, 0
	sll $t2, $t2, 16
	add $t1, $t1, $t2
	
	lbu $a0, 6($s1)
	jal convert_hex_to_bin
	addiu $t2, $v0, 0
	sll $t2, $t2, 12
	add $t1, $t1, $t2
	
	lbu $a0, 7($s1)
	jal convert_hex_to_bin
	addiu $t2, $v0, 0
	sll $t2, $t2, 8
	add $t1, $t1, $t2
	
	lbu $a0, 8($s1)
	jal convert_hex_to_bin
	addiu $t2, $v0, 0
	sll $t2, $t2, 4
	add $t1, $t1, $t2
	
	lbu $a0, 9($s1)
	jal convert_hex_to_bin
	addiu $t2, $v0, 0
	add $t1, $t1, $t2
	
	addiu $s1, $s1, 12
	addi $t0, $t0, -1
	sw $t1, 0($s2)
	addiu $s2, $s2, 4
	j convert_loop
	
convert_hex_to_bin:
	subu $a0, $a0, 48 # subtract ASCII '0'
	blt $a0, 10, convert_done # if less than 10, it's a digit 0 -9
	subu $a0, $a0, 7 # subtract 7 to get from 'A' to 10
	blt $a0, 16, convert_done # if less than 16, it's a letter A -F
	subu $a0, $a0, 32 # subtract 32 to get from 'a' to 10
	
convert_done:
	move $v0, $a0
	jr $ra
	
Exit1:
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	
round_operation:
	
	# Calculate t[0]
	lw $t1, 0($a1)
	lw $t2, 4($a1)
	lw $t3, 8($a1)
	lw $t4, 12($a1)
	la $s0, T3
	la $s1, T2
	la $s2, T1
	la $s3, T0
	lw $s0, 0($s0)
	lw $s1, 0($s1)
	lw $s2, 0($s2)
	lw $s3, 0($s3)
	
	srl $t5, $t1, 24
	srl $t6, $t2, 16
	and $t6, $t6, 0xFF
	srl $t7, $t3, 8
	and $t7, $t7, 0xFF
	and $t8, $t4, 0xFF
	sll $t5, $t5, 2
	sll $t6, $t6, 2
	sll $t7, $t7, 2
	sll $t8, $t8, 2
	add $s0, $s0, $t5
	add $s2, $s2, $t6
	add $s1, $s1, $t7
	add $s3, $s3, $t8
	lw $s4, 0($s0)
	lw $s5, 0($s1)
	lw $s6, 0($s2)
	lw $s7, 0($s3)
	xor $t9, $s4, $s5
	xor $t9, $t9, $s6
	xor $t9, $t9, $s7
	la $t1, rkey
	lw $t1, 0($t1)
	xor $t9, $t9, $t1
	la $t1, t
	sw $t9, 0($t1)
	
	la $t2, ciphertext
	sw $t9, ($t2)
	
	# Calculate t[1]
	lw $t4, 0($a1)
	lw $t1, 4($a1)
	lw $t2, 8($a1)
	lw $t3, 12($a1)
	la $s0, T3
	la $s1, T2
	la $s2, T1
	la $s3, T0
	lw $s0, 0($s0)
	lw $s1, 0($s1)
	lw $s2, 0($s2)
	lw $s3, 0($s3)
	
	srl $t5, $t1, 24
	srl $t6, $t2, 16
	and $t6, $t6, 0xFF
	srl $t7, $t3, 8
	and $t7, $t7, 0xFF
	and $t8, $t4, 0xFF
	sll $t5, $t5, 2
	sll $t6, $t6, 2
	sll $t7, $t7, 2
	sll $t8, $t8, 2
	add $s0, $s0, $t5
	add $s2, $s2, $t6
	add $s1, $s1, $t7
	add $s3, $s3, $t8
	lw $s4, 0($s0)
	lw $s5, 0($s1)
	lw $s6, 0($s2)
	lw $s7, 0($s3)
	xor $t9, $s4, $s5
	xor $t9, $t9, $s6
	xor $t9, $t9, $s7
	la $t1, rkey
	lw $t1, 4($t1)
	xor $t9, $t9, $t1
	la $t1, t
	sw $t9, 4($t1)
	
	la $t2, ciphertext
	addi $t2, $t2, 4
	sw $t9, ($t2)
	
	# Calculate t[2]
	lw $t3, 0($a1)
	lw $t4, 4($a1)
	lw $t1, 8($a1)
	lw $t2, 12($a1)
	la $s0, T3
	la $s1, T2
	la $s2, T1
	la $s3, T0
	lw $s0, 0($s0)
	lw $s1, 0($s1)
	lw $s2, 0($s2)
	lw $s3, 0($s3)
	
	srl $t5, $t1, 24
	srl $t6, $t2, 16
	and $t6, $t6, 0xFF
	srl $t7, $t3, 8
	and $t7, $t7, 0xFF
	and $t8, $t4, 0xFF
	sll $t5, $t5, 2
	sll $t6, $t6, 2
	sll $t7, $t7, 2
	sll $t8, $t8, 2
	add $s0, $s0, $t5
	add $s2, $s2, $t6
	add $s1, $s1, $t7
	add $s3, $s3, $t8
	lw $s4, 0($s0)
	lw $s5, 0($s1)
	lw $s6, 0($s2)
	lw $s7, 0($s3)
	xor $t9, $s4, $s5
	xor $t9, $t9, $s6
	xor $t9, $t9, $s7
	la $t1, rkey
	lw $t1, 8($t1)
	xor $t9, $t9, $t1
	la $t1, t
	sw $t9, 8($t1)
	
	la $t2, ciphertext
	addi $t2, $t2, 8
	sw $t9, ($t2)
	
	# Calculate t[3]
	lw $t2, 0($a1)
	lw $t3, 4($a1)
	lw $t4, 8($a1)
	lw $t1, 12($a1)
	la $s0, T3
	la $s1, T2
	la $s2, T1
	la $s3, T0
	lw $s0, 0($s0)
	lw $s1, 0($s1)
	lw $s2, 0($s2)
	lw $s3, 0($s3)
	
	srl $t5, $t1, 24
	srl $t6, $t2, 16
	and $t6, $t6, 0xFF
	srl $t7, $t3, 8
	and $t7, $t7, 0xFF
	and $t8, $t4, 0xFF
	sll $t5, $t5, 2
	sll $t6, $t6, 2
	sll $t7, $t7, 2
	sll $t8, $t8, 2
	add $s0, $s0, $t5
	add $s2, $s2, $t6
	add $s1, $s1, $t7
	add $s3, $s3, $t8
	lw $s4, 0($s0)
	lw $s5, 0($s1)
	lw $s6, 0($s2)
	lw $s7, 0($s3)
	xor $t9, $s4, $s5
	xor $t9, $t9, $s6
	xor $t9, $t9, $s7
	la $t1, rkey
	lw $t1, 12($t1)
	xor $t9, $t9, $t1
	la $t1, t
	sw $t9, 12($t1)
	
	la $t2, s
	lw $t3, 0($t1)
	sw $t3, 0($t2)
	lw $t3, 4($t1)
	sw $t3, 4($t2)
	lw $t3, 8($t1)
	sw $t3, 8($t2)
	lw $t3, 12($t1)
	sw $t3, 12($t2)
	
	la $t2, ciphertext
	addi $t2, $t2, 12
	sw $t9, ($t2)
	
	jr $ra
	
key_update:
	la $t7, rkey
	lw $t1, 8($t7) #rkey[2]
	la $s1, T2
	lw $s1, 0($s1)
	la $s2, rcon
	
	srl $t2, $t1, 24
	and $t2, $t2, 0xFF #a
	srl $t3, $t1, 16
	and $t3, $t3, 0xFF #b
	srl $t4, $t1, 8
	and $t4, $t4, 0xFF #c
	and $t5, $t1, 0xFF #d
	
	sll $t3, $t3, 2
	sll $t2, $t2, 2
	sll $t4, $t4, 2
	sll $t5, $t5, 2
	
	add $t3, $t3, $s1
	add $t2, $t2, $s1
	add $t4, $t4, $s1
	add $t5, $t5, $s1
	
	lw $t3, 0($t3)
	lw $t2, 0($t2)
	lw $t4, 0($t4)
	lw $t5, 0($t5)
	
	and $t2, $t2, 0xFF #h
	and $t3, $t3, 0xFF
	and $t4, $t4, 0xFF #f
	and $t5, $t5, 0xFF #g
	sll $s0, $t0, 2
	add $s0, $s0, $s2
	lw $s2, 0($s0)
	xor $t3, $t3, $s2 #e
	
	sll $t3, $t3, 24
	sll $t4, $t4, 16
	sll $t5, $t5, 8
	
	xor $t6, $t3, $t4
	xor $t6, $t6, $t5
	xor $t6, $t6, $t2 #tmp
	
	lw $t1, 0($t7) #rkey[0]
	lw $t2, 4($t7) #rkey[1]
	lw $t3, 8($t7) #rkey[2]
	lw $t4, 12($t7) #rkey[3]
	
	xor $t1, $t6, $t1
	xor $t2, $t1, $t2
	xor $t3, $t2, $t3
	xor $t4, $t3, $t4
	
	sw $t1, 0($t7) #rkey[0] save
	sw $t2, 4($t7) #rkey[1] save
	sw $t3, 8($t7) #rkey[2] save
	sw $t4, 12($t7) #rkey[3] save
	
	addi $t9, $t0, 1
	jr $ra
	
key_schedule:
	la $a1, s
	la $a3, message
	la $a2, rkey
	li $t0, 0
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
	jal key_whitening
	j round_loop
	
round_loop:
	beq $t0, 8, Exit1
	
	jal key_update
	jal round_operation
	addi $t0, $t0, 1
	j round_loop
	
key_whitening:
	lw $t1, 0($a2)
	lw $t2, 4($a2)
	lw $t3, 8($a2)
	lw $t4, 12($a2)
	lw $t5, 0($a3)
	lw $t6, 4($a3)
	lw $t7, 8($a3)
	lw $t8, 12($a3)
	xor $t1, $t1, $t5
	xor $t2, $t2, $t6
	xor $t3, $t3, $t7
	xor $t4, $t4, $t8
	
	sw $t1, 0($a1) #rkey[0] save
	sw $t2, 4($a1) #rkey[1] save
	sw $t3, 8($a1) #rkey[2] save
	sw $t4, 12($a1) #rkey[3] save
	
	jr $ra
Exit:
	li $v0, 10
	syscall
