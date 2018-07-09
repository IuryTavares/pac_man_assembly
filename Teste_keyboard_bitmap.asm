.data
bitmap:   .word 0x10010000
red:   .word 0x00ff0000
blue:  .word 0x0000ff00
green: .word 0x000000ff
black: .word 0x00000000
white: .word 0x00ffffff
keyboard: .word 0xffff0004


.text
.globl main
main:
	li $t1, 4
	lw $a3, white
	
	li $a1, 132
	li $a2, 184
	jal paint_line
	li $a1, 1796
	li $a2, 1848
	jal paint_line
	
	li $t1, 128
	li $a1, 260
	li $a2, 1668
	jal paint_line
	li $a1, 312
	li $a2, 1720
	jal paint_line
	
	la $a0, bitmap
	lw $a3, red
	sw $a3, 396($a0)
	
	# teste de calculo de posição por endereço (FUNCIONA)
	addi $t0, $zero, 400 
	add $a0, $a0, $t0
	sw $a3, 0($a0)
	lw $t1, 0($t0) # erro nesta linha, descobrir o erro depois
			
	add $s0, $zero, 396 # endereço inicial do personagem
	
	#jal movimentar_syscall
li $v0, 10
syscall

#simulando movimento
# $a0 - keyboard
# $
#
movimentar_mmio:
	
jr $ra

# sempre que se mover, atualiar o novo endereço em $s0
# $a0 - bitmap
# $v0 - syscall de input
movimentar_syscall:
	la $a0, bitmap
	
	li $v0, 12
	syscall
	
	beq $v0, 119, mover_w
	j nao_mover_w
	mover_w:
		# calculo a nova posição e armazeno em $t0
		add $t0, $s0, -128
		# checo se a posição nova é uma parede
		lw $t1, white
		add $t0, $t0, $a0 # calculando novo endereço
		lw $t2, 0($t0)
		beq $t2, $t1, fim_movimentar_syscall # se for uma parede, nao pode se mover
		# pode mover
		lw $t1, red
		sw $t1, ($t0) # nova posição de vermelho
		
		lw $t1, black #  pinta posição antida de preto
		add $t0, $zero, $v0
		sw $t1, 0($t0)
		
		# atualiza posição de memoria do $v0
		add $v0, $s0, -128
		
	j fim_movimentar_syscall
	nao_mover_w:
	beq $v0, 97, mover_a
	j nao_mover_a
	mover_a:
	
	j fim_movimentar_syscall
	nao_mover_a:
	beq $v0, 115, mover_s
	j nao_mover_s
	mover_s:
	
	j fim_movimentar_syscall
	nao_mover_s:
	beq $v0, 100, mover_d
	j nao_mover_d
	mover_d:
	
	j fim_movimentar_syscall
	nao_mover_d:
	
	fim_movimentar_syscall:
jr $ra

# pinta uma linha dentro de um intervalo determinado
# $a0 - display_address
# $a1 - endereço inicial
# $a2 - endereço final
# $a3 - cor a ser pintada
# $t1 - intervalo entre os pixels
paint_line:
	la $a0, bitmap
	paint_line_loop:
	bgt $a1, $a2, end_paint_line_loop
	add $t0, $a1, $a0
	sw $a3, 0($t0)
	add $a1, $a1, $t1
	j paint_line_loop
	end_paint_line_loop:
jr $ra

