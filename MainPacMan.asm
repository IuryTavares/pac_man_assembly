#   	Fábio Alves - Arquitetura e organização de computadores 2018.1
#								
#   	Tools -> KeyBoard and Display MMIO Simulator            
#		Keyboard reciever data address: 0xffff0004          	
#   	Tools -> Bitmap Display						
#		Unit Width in Pixels:  8				
#		Unit Height in Pixels: 8				
#		Display Width in Pixels:  512				
#		Display Height in Pixels: 256				
#		Base address for display: 0x10010000 (static data)	

.data
display_address: 	.word 0x10010000
dysplay_size:		.word 2048
keyboard_address:	.word 0xffff0004
color_black:		.word 0x00000000
color_white:		.word 0x00ffffff
color_blue:		.word 0x001818ff
color_yellow:		.word 0x00fffe1d
color_red: 		.word 0x00df0902
color_pink:		.word 0x00fa9893
color_ciano:		.word 0x0061fafc
color_orange:		.word 0x00fc9711

#		(Detalhes importantes)
# 	endereço topo dir:  0
#	endereço topo esq:  252
#	endereço baixo dir  7936
#	endereço baixo esq: 8188
#	mover p/ esquerda: address-4
#	mover p/ direita:  address+4
#	mover p/ cima:     address-256
#	mover p/ baixo:	   address+256

.text
.globl main
main:
	jal paint_stage_1
li $v0, 10
syscall

# pinta no display o labirinto e os contadores do jogo
# $a0 - display_address
# 
paint_stage_1:
	la $a0, display_address
	lw $a3, color_blue

	addi $sp, $sp, -4
	sw $ra 0($sp)
	
	addi $t1, $zero, 256
	addi $a1, $zero, 8
	addi $a2, $zero, 7944
	jal paint_column
	addi $a1, $zero, 136
	addi $a2, $zero, 8072
	jal paint_column
	
	addi $t1, $zero, 4
	addi $a1, $zero, 8
	addi $a2, $zero, 136
	jal paint_line
	addi $a1, $zero, 7944
	addi $a2, $zero, 8072
	jal paint_line
	addi $a1, $zero, 528
	addi $a2, $zero, 548
	jal paint_line
	addi $a1, $zero, 556
	addi $a2, $zero, 576
	jal paint_line
	addi $a1, $zero, 592
	addi $a2, $zero, 612
	jal paint_line
	addi $a1, $zero, 620
	addi $a2, $zero, 640
	jal paint_line
	addi $a1, $zero, 1296
	addi $a2, $zero, 1316
	jal paint_line
	addi $a1, $zero, 1324
	addi $a2, $zero, 1344
	jal paint_line
	addi $a1, $zero, 1360
	addi $a2, $zero, 1380
	jal paint_line
	addi $a1, $zero, 1388
	addi $a2, $zero, 1408
	jal paint_line

	sw $a3, 784($a0)
	sw $a3, 1040($a0)
	sw $a3, 804($a0)
	sw $a3, 1060($a0)
	sw $a3, 812($a0)
	sw $a3, 1068($a0)
	sw $a3, 832($a0)
	sw $a3, 1088($a0)
	sw $a3, 848($a0)
	sw $a3, 1104($a0)
	sw $a3, 868($a0)
	sw $a3, 1124($a0)
	sw $a3, 876($a0)
	sw $a3, 1132($a0)
	sw $a3, 896($a0)
	sw $a3, 1152($a0)
	
	addi $t1, $zero, 256
	addi $a1, $zero, 328
	addi $a2, $zero, 1352
	jal paint_column
	addi $a1, $zero, 6728
	addi $a2, $zero, 7752
	jal paint_column
	
	lw $ra 0($sp)
	addi $sp, $sp, 4
jr $ra

# pinta uma linha dentro de um intervalo determinado
# $a0 - display_address
# $a1 - endereço inicial
# $a2 - endereço final
# $a3 - cor a ser pintada
# $t1 - intervalo entre os pixels
paint_line:
	la $a0, display_address
	paint_line_loop:
	bgt $a1, $a2, end_paint_line_loop
	add $t0, $a1, $a0
	sw $a3, 0($t0)
	add $a1, $a1, $t1
	j paint_line_loop
	end_paint_line_loop:
jr $ra

# pinta uma coluna dentro de um intervalo determinado
# $a0 - display_address
# $a1 - endereço inicial
# $a2 - endereço final
# $a3 - cor a ser pintada
# $t1 - intervalo entre os pixels
paint_column:
	la $a0, display_address
	paint_column_loop:
	bgt $a1, $a2, end_paint_line_loop
	add $t0, $a1, $a0
	sw $a3, 0($t0)
	add $a1, $a1, $t1
	j paint_column_loop
	end_paint_column_loop:
jr $ra