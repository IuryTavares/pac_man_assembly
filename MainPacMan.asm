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
	addi $a1, $zero, 328
	addi $a2, $zero, 1352
	jal paint_column
	addi $a1, $zero, 6728
	addi $a2, $zero, 7752
	jal paint_column
	addi $a1, $zero, 5156
	addi $a2, $zero, 5694
	jal paint_column
	addi $a1, $zero, 5164
	addi $a2, $zero, 5932
	jal paint_column
	addi $a1, $zero, 5184
	addi $a2, $zero, 5952
	jal paint_column
	addi $a1, $zero, 5200
	addi $a2, $zero, 5968
	jal paint_column
	addi $a1, $zero, 5220
	addi $a2, $zero, 5988
	jal paint_column
	addi $a1, $zero, 5228
	addi $a2, $zero, 5996
	jal paint_column
	addi $a1, $zero, 4936
	addi $a2, $zero, 6216
	jal paint_column
	addi $a1, $zero, 1836
	addi $a2, $zero, 2604
	jal paint_column
	addi $a1, $zero, 1892
	addi $a2, $zero, 2660
	jal paint_column
	addi $a1, $zero, 1844
	addi $a2, $zero, 3124
	jal paint_column
	addi $a1, $zero, 1884
	addi $a2, $zero, 3164
	jal paint_column
	addi $a1, $zero, 2372
	addi $a2, $zero, 3140
	jal paint_column
	addi $a1, $zero, 2380
	addi $a2, $zero, 3148
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
	addi $a1, $zero, 6672
	addi $a2, $zero, 6692
	jal paint_line
	addi $a1, $zero, 6700
	addi $a2, $zero, 6720
	jal paint_line
	addi $a1, $zero, 6736
	addi $a2, $zero, 6756
	jal paint_line
	addi $a1, $zero, 6764
	addi $a2, $zero, 6784
	jal paint_line
	addi $a1, $zero, 7440
	addi $a2, $zero, 7460
	jal paint_line
	addi $a1, $zero, 7468
	addi $a2, $zero, 7488
	jal paint_line
	addi $a1, $zero, 7504
	addi $a2, $zero, 7524
	jal paint_line
	addi $a1, $zero, 7532
	addi $a2, $zero, 7552
	jal paint_line
	addi $a1, $zero, 4880
	addi $a2, $zero, 4900
	jal paint_line
	addi $a1, $zero, 4908
	addi $a2, $zero, 4928
	jal paint_line
	addi $a1, $zero, 4944
	addi $a2, $zero, 4964
	jal paint_line
	addi $a1, $zero, 4972
	addi $a2, $zero, 4992
	jal paint_line
	addi $a1, $zero, 6172
	addi $a2, $zero, 6180
	jal paint_line
	addi $a1, $zero, 6188
	addi $a2, $zero, 6208
	jal paint_line
	addi $a1, $zero, 6224
	addi $a2, $zero, 6244
	jal paint_line
	addi $a1, $zero, 6252
	addi $a2, $zero, 6260
	jal paint_line
	addi $a1, $zero, 5900
	addi $a2, $zero, 5908
	jal paint_line
	addi $a1, $zero, 6156
	addi $a2, $zero, 6164
	jal paint_line
	addi $a1, $zero, 6012
	addi $a2, $zero, 6020
	jal paint_line
	addi $a1, $zero, 6268
	addi $a2, $zero, 6276
	jal paint_line
	addi $a1, $zero, 5392
	addi $a2, $zero, 5404
	jal paint_line
	addi $a1, $zero, 5492
	addi $a2, $zero, 5504
	jal paint_line
	addi $a1, $zero, 1808
	addi $a2, $zero, 1828
	jal paint_line
	addi $a1, $zero, 1852
	addi $a2, $zero, 1876
	jal paint_line
	addi $a1, $zero, 1900
	addi $a2, $zero, 1920
	jal paint_line
	addi $a1, $zero, 2320
	addi $a2, $zero, 2340
	jal paint_line
	addi $a1, $zero, 2412
	addi $a2, $zero, 2432
	jal paint_line
	addi $a1, $zero, 2844
	addi $a2, $zero, 2860
	jal paint_line
	addi $a1, $zero, 3356
	addi $a2, $zero, 3380
	jal paint_line
	addi $a1, $zero, 3420
	addi $a2, $zero, 3444
	jal paint_line
	addi $a1, $zero, 2916
	addi $a2, $zero, 2932
	jal paint_line
	addi $a1, $zero, 3336
	addi $a2, $zero, 3348
	jal paint_line
	addi $a1, $zero, 4360
	addi $a2, $zero, 4372
	jal paint_line
	addi $a1, $zero, 3964
	addi $a2, $zero, 3976
	jal paint_line
	addi $a1, $zero, 4476
	addi $a2, $zero, 4488
	jal paint_line
	addi $a1, $zero, 2824
	addi $a2, $zero, 2836
	jal paint_line
	addi $a1, $zero, 3848
	addi $a2, $zero, 3860
	jal paint_line
	#addi $a1, $zero, 
	#addi $a2, $zero, 
	#jal paint_line
	
	
	lw $a3, color_black
	sw $a3, 3080($a0)
	sw $a3, 4104($a0)
	sw $a3, 3208($a0)
	sw $a3, 4232($a0)
	
	lw $a3, color_blue
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
	sw $a3, 6928($a0)
	sw $a3, 7184($a0)
	sw $a3, 6948($a0)
	sw $a3, 7204($a0)
	sw $a3, 6976($a0)
	sw $a3, 7232($a0)
	sw $a3, 6992($a0)
	sw $a3, 7248($a0)
	sw $a3, 7012($a0)
	sw $a3, 7268($a0)
	sw $a3, 7020($a0)
	sw $a3, 7276($a0)
	sw $a3, 7040($a0)
	sw $a3, 7296($a0)
	sw $a3, 6956($a0)
	sw $a3, 7212($a0)
	sw $a3, 5136($a0)
	sw $a3, 5660($a0)
	sw $a3, 5916($a0)
	sw $a3, 6004($a0)
	sw $a3, 5748($a0)
	sw $a3, 5248($a0)
	sw $a3, 5924($a0)
	sw $a3, 2064($a0)
	sw $a3, 2084($a0)
	sw $a3, 2108($a0)
	sw $a3, 2132($a0)
	sw $a3, 2156($a0)
	sw $a3, 2176($a0)
	sw $a3, 1840($a0)
	sw $a3, 1888($a0)
	sw $a3, 2872($a0)
	sw $a3, 2876($a0)
	sw $a3, 3128($a0)
	sw $a3, 3132($a0)
	sw $a3, 2900($a0)
	sw $a3, 2904($a0)
	sw $a3, 3156($a0)
	sw $a3, 3160($a0)
	sw $a3, 3100($a0)
	sw $a3, 3188($a0)
	sw $a3, 2364($a0)
	sw $a3, 2368($a0)
	sw $a3, 2384($a0)
	sw $a3, 2388($a0)
	sw $a3, 3144($a0)
	sw $a3, 3092($a0)
	sw $a3, 4116($a0)
	sw $a3, 3196($a0)
	sw $a3, 4220($a0)
	
	
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
