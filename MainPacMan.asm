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
display_size:		.word 2048
keyboard_address:	.word 0xFFFF0004
color_blue:		.word 0x001818FF
color_yellow:		.word 0x00FFFE1D
color_red: 		.word 0x00DF0902
color_pink:		.word 0x00FA9893
color_ciano:		.word 0x0061FAFC
color_orange:		.word 0x00FC9711
color_black:		.word 0x00000000
color_white:		.word 0x00FFFFFF

#		(Detalhes importantes)
# 	endereço topo dir:  0
#	endereço topo esq:  252
#	endereço baixo dir  7936
#	endereço baixo esq: 8188
#	mover p/ esquerda: address-4
#	mover p/ direita:  address+4
#	mover p/ cima:     address-256
#	mover p/ baixo:	   address+256
#	$s0 - posição do pac man	
#	$s1 - posição do fantasma azul
#	$s2 - posição do fantasma laranja
#	$s3 - posição do fantasma vermelho
#	$s4 - posição do fantasma rosa

.text
.globl main
main:
	jal paint_stage_1
	jal salvar_posicao_inicial_personagens
	
	# enquanto $s7 diferente de 0
	li $s7, 1
	loop_stage_1:
	beq $zero, $s7, end_loop_stage_1
		
		li $a0, 60
		jal sleep
		
		jal mover_teste		
		
		#jal capturar_tecla
		#jal mover_pac_man
	j loop_stage_1
	end_loop_stage_1:
	
li $v0, 10
syscall

mover_teste:
	lw $a0, display_address
	addi $t0, $a0, 1608 # endereço que o pac man está
	lw $t1, color_black
	lw $t2, color_yellow
	
	li $v0, 12
	syscall
	beq $v0, 119, w
	j nao_w
	w:
		sw $t1, 0($t0)
		sub $t0, $t0, 256
		sw $t2, 0($t0)
	j leu
	nao_w:
	beq $v0, 119, a
	j nao_a
	a:
		sw $t1, 0($t0)
		sub $t0, $t0, 4
		sw $t2, 0($t0)
	j leu
	nao_a:
	beq $v0, 119, s
	j nao_s
	s:
		sw $t1, 0($t0)
		add $t0, $t0, 256
		sw $t2, 0($t0)
	j leu
	nao_s:
	beq $v0, 119, d
	j nao_d
	d:
		sw $t1, 0($t0)
		add $t0, $t0, 4
		sw $t2, 0($t0)
	j leu
	nao_d:
	leu:
jr $ra

# mover o pac man na direção indicada
# $a0 - posição atual do pac man
# $a1 - nova posição do pac man (retorno da função "capturar tecla" $v0)
mover_pac_man:
	lw $t0, color_black
	lw $t1, color_blue
	
	sw $t0, ($a0)
	sw $t1, ($a1)
	
	end_mover_pac_man:
jr $ra

# recebe do teclado a direção que o pac man irá se mover
# $a0 - keyboard_address
# $v0 - retorna a próxima posição que o pac man tentará se mover
capturar_tecla:
	lw $a0, keyboard_address
	move $t0, $s0 # move para t0 a posição atual do pac man 
	# case w
	beq $a0, 119, teclou_w
	j nao_teclou_w
	teclou_w:
		sub $v0, $t0, 256
	j capturou_tecla
	nao_teclou_w:
	# case a
	beq $a0, 97, teclou_a
	j nao_teclou_a
	teclou_a:
		sub $v0, $t0, 4
	j capturou_tecla
	nao_teclou_a:
	# case s
	beq $a0, 115, teclou_s
	j nao_teclou_s
	teclou_s:
		add $v0, $t0, 256
	j capturou_tecla
	nao_teclou_s:
	# case d
	beq $a0, 100, teclou_d
	j nao_teclou_d
	teclou_d:
		add $v0, $t0, 4
	j capturou_tecla
	nao_teclou_d:
	# se nenhuma tecla acima for pressionada o pac man continua o movimento anterior
	capturou_tecla:
jr $ra

# recebe em $a0 o tempo (em mili segundos) que o programa dará o sleep
sleep:
	li $v0, 32
	syscall
jr $ra

# salva a posição inicial dos personagens de acordo com o stage atual
# $a0 - display_address
# $a1 - stage atual (1 - stage 1) (2 - stage 2)
# $s0 $s1 $s2 $s3 $s4
salvar_posicao_inicial_personagens:
	la $a0, display_address
	# case 1
	beq $a1, 1, stage_1
	j stage_2
	stage_1:
		addi $s0, $a0, 1608 # pac man      
		addi $s1, $a0, 4160 # blue ghost   
		addi $s2, $a0, 4164 # orange ghost 
		addi $s3, $a0, 4172 # red ghost    
		addi $s4, $a0, 4176 # pink ghost   
	j fim_set_posicao
	not_stage_1:
	# case 2
	beq $a1, 2, stage_2
	j not_stage_2
	stage_2:   # falta implementar MUDAR APENAS OS IMEDIATOS
	#	addi $s0, $a0, 1608 # pac man      
	#	addi $s1, $a0, 4160 # blue ghost   
	#	addi $s2, $a0, 4164 # orange ghost 
	#	addi $s3, $a0, 4172 # red ghost    
	#	addi $s4, $a0, 4176 # pink ghost   
	not_stage_2:
	fim_set_posicao:
jr $ra

# pinta no display o labirinto e os contadores do jogo
# $a0 - display_address
paint_stage_1:
	la $a0, display_address
	
	# pintando pac man
	lw $a3, color_yellow
	sw $a3, 1608($a0)
	
	# pintando fantasmas
	lw $a3, color_ciano
	sw $a3, 4160($a0)
	lw $a3, color_orange
	sw $a3, 4164($a0)
	lw $a3, color_red
	sw $a3, 4172($a0)
	lw $a3, color_pink
	sw $a3, 4176($a0)
	
	addi $sp, $sp, -4
	sw $ra 0($sp)
	
	# inicio pintando pontos
	lw $a3, color_white # cor dos pontos
	
	addi $t1, $zero, 512
	addi $a1, $zero, 524
	addi $a2, $zero, 2572
	jal paint_column
	addi $a1, $zero, 296
	addi $a2, $zero, 2344
	jal paint_column
	addi $a1, $zero, 580
	addi $a2, $zero, 1092
	jal paint_column
	addi $a1, $zero, 588
	addi $a2, $zero, 1100
	jal paint_column
	addi $a1, $zero, 360
	addi $a2, $zero, 2408
	jal paint_column
	addi $a1, $zero, 644
	addi $a2, $zero, 2692
	jal paint_column
	addi $a1, $zero, 1848
	addi $a2, $zero, 2360
	jal paint_column
	addi $a1, $zero, 1880
	addi $a2, $zero, 2392
	jal paint_column
	addi $a1, $zero, 2880
	addi $a2, $zero, 3392
	jal paint_column
	addi $a1, $zero, 2896
	addi $a2, $zero, 3408
	jal paint_column
	addi $a1, $zero, 2840
	addi $a2, $zero, 4376
	jal paint_column
	addi $a1, $zero, 3896
	addi $a2, $zero, 4408
	jal paint_column
	addi $a1, $zero, 3928
	addi $a2, $zero, 4440
	jal paint_column
	addi $a1, $zero, 2936
	addi $a2, $zero, 4472
	jal paint_column
	addi $a1, $zero, 4620
	addi $a2, $zero, 5644
	jal paint_column
	addi $a1, $zero, 4904
	addi $a2, $zero, 7464
	jal paint_column
	addi $a1, $zero, 5188
	addi $a2, $zero, 7748
	jal paint_column
	addi $a1, $zero, 5196
	addi $a2, $zero, 7756
	jal paint_column
	addi $a1, $zero, 4968
	addi $a2, $zero, 7528
	jal paint_column
	addi $a1, $zero, 4740
	addi $a2, $zero, 5764
	jal paint_column
	addi $a1, $zero, 6788
	addi $a2, $zero, 7812
	jal paint_column
	addi $a1, $zero, 6668
	addi $a2, $zero, 7692
	jal paint_column
	
	addi $t1, $zero, 8
	addi $a1, $zero, 272
	addi $a2, $zero, 320
	jal paint_line
	addi $a1, $zero, 336
	addi $a2, $zero, 384
	jal paint_line
	addi $a1, $zero, 1548
	addi $a2, $zero, 1596
	jal paint_line
	addi $a1, $zero, 1620
	addi $a2, $zero, 1668
	jal paint_line
	addi $a1, $zero, 2572
	addi $a2, $zero, 2596
	jal paint_line
	addi $a1, $zero, 2668
	addi $a2, $zero, 2692
	jal paint_line
	addi $a1, $zero, 3612
	addi $a2, $zero, 3700
	jal paint_line
	addi $a1, $zero, 4620
	addi $a2, $zero, 4740
	jal paint_line
	addi $a1, $zero, 6416
	addi $a2, $zero, 6528
	jal paint_line
	addi $a1, $zero, 7692
	addi $a2, $zero, 7812
	jal paint_line
	
	sw $a3, 5652($a0)
	sw $a3, 5912($a0)
	sw $a3, 5756($a0)
	sw $a3, 6008($a0)
	sw $a3, 2620($a0)
	sw $a3, 2644($a0)
	
	# fim pintando pontos
	
	# inicio pintando o STAGE e o PTS
	lw $a3, color_white
	addi $t1, $zero, 256
	
	addi $a1, $zero, 936
	addi $a2, $zero, 1960
	jal paint_column
	addi $a1, $zero, 948
	addi $a2, $zero, 1972
	jal paint_column
	addi $a1, $zero, 956
	addi $a2, $zero, 1980
	jal paint_column
	addi $a1, $zero, 964
	addi $a2, $zero, 1988
	jal paint_column
	addi $a1, $zero, 1488
	addi $a2, $zero, 2000
	jal paint_column
	addi $a1, $zero, 984
	addi $a2, $zero, 2008
	jal paint_column
	addi $a1, $zero, 1008
	addi $a2, $zero, 2032
	jal paint_column
	addi $a1, $zero, 3732
	addi $a2, $zero, 4756
	jal paint_column
	addi $a1, $zero, 3752
	addi $a2, $zero, 4776
	jal paint_column
	addi $a1, $zero, 3788
	addi $a2, $zero, 4812
	jal paint_column
	addi $a1, $zero, 3796
	addi $a2, $zero, 4820
	jal paint_column
	addi $a1, $zero, 3804
	addi $a2, $zero, 4828
	jal paint_column
	addi $a1, $zero, 3812
	addi $a2, $zero, 4836
	jal paint_column
	addi $a1, $zero, 3820
	addi $a2, $zero, 4844
	jal paint_column
	addi $a1, $zero, 3828
	addi $a2, $zero, 4852
	jal paint_column
	
	addi $t1, $zero, 4
	
	addi $a1, $zero, 916
	addi $a2, $zero, 924
	jal paint_line
	addi $a1, $zero, 1428
	addi $a2, $zero, 1436
	jal paint_line
	addi $a1, $zero, 1940
	addi $a2, $zero, 1948
	jal paint_line
	addi $a1, $zero, 932
	addi $a2, $zero, 940
	jal paint_line
	addi $a1, $zero, 948
	addi $a2, $zero, 956
	jal paint_line
	addi $a1, $zero, 1716
	addi $a2, $zero, 1724
	jal paint_line
	addi $a1, $zero, 964
	addi $a2, $zero, 976
	jal paint_line
	addi $a1, $zero, 1988
	addi $a2, $zero, 2000
	jal paint_line
	addi $a1, $zero, 984
	addi $a2, $zero, 992
	jal paint_line
	addi $a1, $zero, 1496
	addi $a2, $zero, 1504
	jal paint_line
	addi $a1, $zero, 2008
	addi $a2, $zero, 2016
	jal paint_line
	addi $a1, $zero, 2028
	addi $a2, $zero, 2036
	jal paint_line
	addi $a1, $zero, 3764
	addi $a2, $zero, 3772
	jal paint_line
	addi $a1, $zero, 4276
	addi $a2, $zero, 4284
	jal paint_line
	addi $a1, $zero, 4788
	addi $a2, $zero, 4796
	jal paint_line
	
	sw $a3, 1484($a0)
	sw $a3, 1260($a0)
	sw $a3, 1172($a0)
	sw $a3, 1692($a0)
	sw $a3, 3736($a0)
	sw $a3, 3740($a0)
	sw $a3, 4248($a0)
	sw $a3, 4252($a0)
	sw $a3, 3996($a0)
	sw $a3, 3748($a0)
	sw $a3, 3756($a0)
	sw $a3, 4020($a0)
	sw $a3, 4540($a0)
	sw $a3, 4036($a0)
	sw $a3, 4804($a0)
	sw $a3, 3792($a0)
	sw $a3, 3808($a0)
	sw $a3, 3824($a0)
	sw $a3, 4816($a0)
	sw $a3, 4832($a0)
	sw $a3, 4848($a0)
	# fim pintando o STAGE e o PTS
	
	# inicio pintanto as três vidas do pac man
	lw $a3, color_yellow
	
	addi $t1, $zero, 4
	
	addi $a1, $zero, 6304
	addi $a2, $zero, 6312
	jal paint_line
	addi $a1, $zero, 6556
	addi $a2, $zero, 6572
	jal paint_line
	addi $a1, $zero, 6808
	addi $a2, $zero, 6820
	jal paint_line
	addi $a1, $zero, 7320
	addi $a2, $zero, 7332
	jal paint_line
	addi $a1, $zero, 7580
	addi $a2, $zero, 7596
	jal paint_line
	addi $a1, $zero, 7840
	addi $a2, $zero, 7848
	jal paint_line
	addi $a1, $zero, 6336
	addi $a2, $zero, 6344
	jal paint_line
	addi $a1, $zero, 6588
	addi $a2, $zero, 6604
	jal paint_line
	addi $a1, $zero, 6840
	addi $a2, $zero, 6852
	jal paint_line
	addi $a1, $zero, 7352
	addi $a2, $zero, 7364
	jal paint_line
	addi $a1, $zero, 7612
	addi $a2, $zero, 7628
	jal paint_line
	addi $a1, $zero, 7872
	addi $a2, $zero, 7880
	jal paint_line
	addi $a1, $zero, 6368
	addi $a2, $zero, 6376
	jal paint_line
	addi $a1, $zero, 6620
	addi $a2, $zero, 6636
	jal paint_line
	addi $a1, $zero, 6872
	addi $a2, $zero, 6884
	jal paint_line
	addi $a1, $zero, 7384
	addi $a2, $zero, 7396
	jal paint_line
	addi $a1, $zero, 7644
	addi $a2, $zero, 7660
	jal paint_line
	addi $a1, $zero, 7904
	addi $a2, $zero, 7912
	jal paint_line
	
	sw $a3, 7064($a0)
	sw $a3, 7068($a0)
	sw $a3, 7096($a0)
	sw $a3, 7100($a0)
	sw $a3, 7128($a0)
	sw $a3, 7132($a0)
	# fim pintanto as três vidas do pac man
	
	# inicio pintando labirinto
	lw $a3, color_blue # cor das paredes
	addi $t1, $zero, 256
	
	addi $a1, $zero, 8
	addi $a2, $zero, 2824
	jal paint_column
	addi $a1, $zero, 4360
	addi $a2, $zero, 7944
	jal paint_column
	addi $a1, $zero, 136
	addi $a2, $zero, 2952
	jal paint_column
	addi $a1, $zero, 4488
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
	addi $a2, $zero, 2868
	jal paint_column
	addi $a1, $zero, 1884
	addi $a2, $zero, 2908
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
	addi $a2, $zero, 3388
	jal paint_line
	addi $a1, $zero, 3412
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
	addi $a1, $zero, 2940
	addi $a2, $zero, 2952
	jal paint_line
	addi $a1, $zero, 3452
	addi $a2, $zero, 3464
	jal paint_line
	addi $a1, $zero, 3868
	addi $a2, $zero, 3892
	jal paint_line
	addi $a1, $zero, 4380
	addi $a2, $zero, 4404
	jal paint_line
	addi $a1, $zero, 4444
	addi $a2, $zero, 4468
	jal paint_line
	addi $a1, $zero, 3932
	addi $a2, $zero, 3956
	jal paint_line
	addi $a1, $zero, 4412
	addi $a2, $zero, 4436
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
	sw $a3, 3132($a0)
	sw $a3, 2900($a0)
	sw $a3, 2904($a0)
	sw $a3, 3156($a0)
	sw $a3, 3100($a0)
	sw $a3, 3188($a0)
	sw $a3, 2364($a0)
	sw $a3, 2368($a0)
	sw $a3, 2384($a0)
	sw $a3, 2388($a0)
	sw $a3, 3400($a0)
	sw $a3, 3092($a0)
	sw $a3, 4116($a0)
	sw $a3, 3196($a0)
	sw $a3, 4220($a0)
	sw $a3, 3396($a0)
	sw $a3, 3404($a0)
	sw $a3, 4124($a0)
	sw $a3, 4148($a0)
	sw $a3, 4156($a0)
	sw $a3, 3900($a0)
	sw $a3, 3904($a0)
	sw $a3, 3908($a0)
	sw $a3, 3916($a0)
	sw $a3, 3920($a0)
	sw $a3, 3924($a0)
	sw $a3, 4188($a0)
	sw $a3, 4212($a0)
	sw $a3, 4180($a0)
	# fim pintando labirinto
	
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
