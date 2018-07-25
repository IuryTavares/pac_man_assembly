li $a0, 1
li $a1, 1
li $a2, 10
li $a3, 10
jal distancia_euclidiana
move $a0, $v0
li $v0, 1
syscall

li $v0, 10
syscall



# $a0 valor de entrada
# $v0 resultado
integerSqrt:
  	move $v0, $zero        # initalize return
  	move $t1, $a0          # move a0 to t1
  	addi $t0, $zero, 1
	sll $t0, $t0, 30      # shift to second-to-top bit

	integerSqrt_bit:
 	slt $t2, $t1, $t0     # num < bit
 	beq $t2, $zero, integerSqrt_loop
	srl $t0, $t0, 2       # bit >> 2
 	j integerSqrt_bit

	integerSqrt_loop:
	beq $t0, $zero, integerSqrt_return
  	add $t3, $v0, $t0     # t3 = return + bit
 	slt $t2, $t1, $t3
 	beq $t2, $zero, integerSqrt_else
 	srl $v0, $v0, 1       # return >> 1
 	j integerSqrt_loop_end
	
	integerSqrt_else:
 	sub $t1, $t1, $t3     # num -= return + bit
 	srl $v0, $v0, 1       # return >> 1
 	add $v0, $v0, $t0     # return + bit

	integerSqrt_loop_end:
 	srl $t0, $t0, 2       # bit >> 2
 	j integerSqrt_loop

	integerSqrt_return:
jr $ra


# $a0 - x1
# $a1 - y1
# $a2 - x2
# $a3 - y2
# $v0 - distancia
# distance = sqrt((x1-x2)^2+(y1-y2)^2)
# devido a limitação da raiz quadrada em assembly alguns resultados não serão bem definidos
distancia_euclidiana:
	# parte de dentro da raiz
	sub $a0, $a0, $a2 # (x1-x2)
	sub $a1, $a1, $a3 # (y1-y2)
	mul $a0, $a0, $a0 # (x1-x2)^2
	mul $a1, $a1, $a1 # (y1-y2)^2
	add $a0, $a0, $a1
	# raiz
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal integerSqrt
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	# o retorno de integerSqrt já está em $v0
jr $ra
