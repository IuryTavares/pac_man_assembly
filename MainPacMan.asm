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
#	$s5 - armazena o stage atual (1 ou 2)
#	$s6 - armazena a quantidade de vidas (3 no máximo)

.text
.globl main
main:
	jal paint_stage_1
	jal paint_pts
	li $s5, 1            # indicando que estamos no stage 1
	jal paint_stage_text
	li $s6, 3
	jal paint_lives
	
	li $a1, 0
	li $a2, 1
	jal contador_display
	
	li $a1, 0
	li $a2, 2
	jal contador_display
	
	li $a1, 0
	li $a2, 3
	jal contador_display
	
	li $t9, 1   # while $t9 diferente de 0 o jogo continua
	game_loop:
	beq $zero, $t9, end_game_loop 
		jal movimentar_syscall
	#j game_loop
	end_game_loop:
li $v0, 10
syscall

movimentar_syscall:
	la $a0, display_address  # se nao pegar, testar com load word
	li $v0, 12
	syscall
	beq $v0, 119, mover_w
	j nao_mover_w
	mover_w:
		# a antiga posicao está em $s0
		# armazeno a nova posiçao em $t0
		sub $t0, $s0, 256  	# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, color_yellow
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, color_black #  pinta posição antiga de preto
		sw $t1, 0($s0)
		# atualiza posição de memoria do $v0
		sub $s0, $s0, 256
	j fim_movimentar_syscall
	nao_mover_w:
	beq $v0, 97, mover_a
	j nao_mover_a
	mover_a:
		sub $t0, $s0, 4  	# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, color_yellow
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, color_black  # pinta posição antida de preto
		sw $t1, 0($s0) # posição antiga do personagem
		# atualiza posição de memoria do $v0
		sub $s0, $s0, 4
	j fim_movimentar_syscall
	nao_mover_a:
	beq $v0, 115, mover_s
	j nao_mover_s
	mover_s:
		add $t0, $s0, 256  	# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, color_yellow
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, color_black  # pinta posição antida de preto
		sw $t1, 0($s0) # posição antiga do personagem
		# atualiza posição de memoria do $v0
		add $s0, $s0, 256
	j fim_movimentar_syscall
	nao_mover_s:
	beq $v0, 100, mover_d
	j nao_mover_d
	mover_d:
		add $t0, $s0, 4  	# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, color_yellow
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, color_black  # pinta posição antida de preto
		sw $t1, 0($s0) # posição antiga do personagem
		# atualiza posição de memoria do $v0
		add $s0, $s0, 4
	j fim_movimentar_syscall
	nao_mover_d:
	
	fim_movimentar_syscall:
jr $ra

# recebe em $a0 o tempo (em mili segundos) que o programa dará o sleep
sleep:
	li $v0, 32
	syscall
jr $ra

# pinta no display o labirinto e os contadores do jogo
# salva nos registradores $s0 a $s4 o address dos personagens
paint_stage_1:
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	###### labirinto ######
	li $t1, 4
	lw $a3, color_blue
	
	li $a1, 260 
	li $a2, 372
	jal paint_line
	
	li $a1, 7428
	li $a2, 7540
	jal paint_line
	
	li $a1, 780
	li $a2, 792
	jal paint_line
	
	li $a1, 1036
	li $a2, 1048
	jal paint_line
	
	li $a1, 1548
	li $a2, 1560
	jal paint_line
	
	li $a1, 1804
	li $a2, 1816
	jal paint_line
	
	li $a1, 2316
	li $a2, 2328
	jal paint_line
	
	li $a1, 2572
	li $a2, 2584
	jal paint_line
	
	li $a1, 864
	li $a2, 876
	jal paint_line
	
	li $a1, 1120
	li $a2, 1132
	jal paint_line
	
	li $a1, 1632
	li $a2, 1644
	jal paint_line
	
	li $a1, 1888
	li $a2, 1900
	jal paint_line
	
	li $a1, 2400
	li $a2, 2412
	jal paint_line
	
	li $a1, 2656
	li $a2, 2668
	jal paint_line
	
	li $a1, 800
	li $a2, 820
	jal paint_line
	
	li $a1, 1056
	li $a2, 1076
	jal paint_line
	
	li $a1, 836
	li $a2, 856
	jal paint_line
	
	li $a1, 1092
	li $a2, 1112
	jal paint_line
	
	li $a1, 1580
	li $a2, 1612
	jal paint_line
	
	li $a1, 1836
	li $a2, 1868
	jal paint_line
	
	li $a1, 2336
	li $a2, 2352
	jal paint_line
	
	li $a1, 2592
	li $a2, 2608
	jal paint_line
	
	li $a1, 2376
	li $a2, 2392
	jal paint_line
	
	li $a1, 2632
	li $a2, 2648
	jal paint_line
	
	li $a1, 3076
	li $a2, 3096
	jal paint_line
	
	li $a1, 3168
	li $a2, 3188
	jal paint_line
	
	li $a1, 4612
	li $a2, 4632
	jal paint_line
	
	li $a1, 4704
	li $a2, 4724
	jal paint_line
	
	li $a1, 3120
	li $a2, 3144
	jal paint_line
	
	li $a1, 3376
	li $a2, 3400
	jal paint_line
	
	li $a1, 3632
	li $a2, 3656
	jal paint_line
	
	li $a1, 3888
	li $a2, 3912
	jal paint_line
	
	li $a1, 4144
	li $a2, 4168
	jal paint_line
	
	li $a1, 4400
	li $a2, 4424
	jal paint_line
	
	li $a1, 4656
	li $a2, 4680
	jal paint_line
	
	li $a1, 5132
	li $a2, 5144
	jal paint_line
	
	li $a1, 5388
	li $a2, 5400
	jal paint_line
	
	li $a1, 5900
	li $a2, 5912
	jal paint_line
	
	li $a1, 6156
	li $a2, 6168
	jal paint_line
	
	li $a1, 6668
	li $a2, 6680
	jal paint_line
	
	li $a1, 6924
	li $a2, 6936
	jal paint_line
	
	li $a1, 5216
	li $a2, 5228
	jal paint_line
	
	li $a1, 5472
	li $a2, 5484
	jal paint_line
	
	li $a1, 5984
	li $a2, 5996
	jal paint_line
	
	li $a1, 6240
	li $a2, 6252
	jal paint_line
	
	li $a1, 6752
	li $a2, 6764
	jal paint_line
	
	li $a1, 7008
	li $a2, 7020
	jal paint_line
	
	li $a1, 5152
	li $a2, 5168
	jal paint_line
	
	li $a1, 5408
	li $a2, 5424
	jal paint_line
	
	li $a1, 5192
	li $a2, 5208
	jal paint_line
	
	li $a1, 5448
	li $a2, 5464
	jal paint_line
	
	li $a1, 5932
	li $a2, 5964
	jal paint_line
	
	li $a1, 6188
	li $a2, 6220
	jal paint_line
	
	li $a1, 6688
	li $a2, 6708
	jal paint_line
	
	li $a1, 6944
	li $a2, 6964
	jal paint_line
	
	li $a1, 6724
	li $a2, 6744
	jal paint_line
	
	li $a1, 6980
	li $a2, 7000
	jal paint_line
	
	li $t1, 256
	
	li $a1, 516
	li $a2, 2820
	jal paint_line
	
	li $a1, 1568
	li $a2, 2080
	jal paint_line
	
	li $a1, 1572
	li $a2, 2084
	jal paint_line
	
	li $a1, 1620
	li $a2, 2132
	jal paint_line
	
	li $a1, 1624
	li $a2, 2136
	jal paint_line
	
	li $a1, 572
	li $a2, 1084
	jal paint_line
	
	li $a1, 2104
	li $a2, 2616
	jal paint_line
	
	li $a1, 2112
	li $a2, 2624
	jal paint_line
	
	li $a1, 2108
	li $a2, 2620
	jal paint_line
	
	li $a1, 628
	li $a2, 2932
	jal paint_line
	
	li $a1, 3352
	li $a2, 4376
	jal paint_line
	
	li $a1, 3424
	li $a2, 4448
	jal paint_line
	
	li $a1, 3104
	li $a2, 4640
	jal paint_line
	
	li $a1, 3108
	li $a2, 4644
	jal paint_line
	
	li $a1, 3112
	li $a2, 4668
	jal paint_line
	
	li $a1, 3152
	li $a2, 4688
	jal paint_line
	
	li $a1, 3156
	li $a2, 4692
	jal paint_line
	
	li $a1, 3160
	li $a2, 4696
	jal paint_line
	
	li $a1, 4868
	li $a2, 7172
	jal paint_line
	
	li $a1, 4980
	li $a2, 7284
	jal paint_line
	
	li $a1, 5664
	li $a2, 6176
	jal paint_line
	
	li $a1, 5668
	li $a2, 6180
	jal paint_line
	
	li $a1, 5716
	li $a2, 6228
	jal paint_line
	
	li $a1, 5720
	li $a2, 6232
	jal paint_line
	
	li $a1, 6716
	li $a2, 7228
	jal paint_line

	li $a1, 5176
	li $a2, 5688
	jal paint_line
		
	li $a1, 5184
	li $a2, 5696
	jal paint_line
	
	li $a1, 5180
	li $a2, 5692
	jal paint_line
	
	####### pontos ########
	li $t1, 8
	lw $a3, color_white
	
	li $a1, 528
	li $a2, 568
	jal paint_line
	
	li $a1, 576
	li $a2, 616
	jal paint_line

	li $a1, 2828
	li $a2, 2924
	jal paint_line
	
	li $a1, 1292
	li $a2, 1388
	jal paint_line
	
	
	li $a1, 4876
	li $a2, 4972
	jal paint_line
	
	li $a1, 6412
	li $a2, 6508
	jal paint_line
	
	li $a1, 7184
	li $a2, 7224
	jal paint_line
	
	li $a1, 7232
	li $a2, 7272
	jal paint_line
	
	li $a1, 2064
	li $a2, 2072
	jal paint_line
	
	li $a1, 2088
	li $a2, 2096
	jal paint_line
	
	li $a1, 2120
	li $a2, 2128
	jal paint_line
	
	li $a1, 2144
	li $a2, 2152
	jal paint_line
	
	li $a1, 5648
	li $a2, 5656
	jal paint_line
	
	li $a1, 5672
	li $a2, 5680
	jal paint_line
	
	li $a1, 5704
	li $a2, 5712
	jal paint_line
	
	li $a1, 5728
	li $a2, 5736
	jal paint_line
	
	li $t1, 512
	
	li $a1, 1032
	li $a2, 2568
	jal paint_line
	
	li $a1, 1136
	li $a2, 2672
	jal paint_line
	
	li $a1, 796
	li $a2, 6940
	jal paint_line
	
	li $a1, 860
	li $a2, 7004
	jal paint_line
	
	li $a1, 5128
	li $a2, 6664
	jal paint_line
	
	li $a1, 5232
	li $a2, 6768
	jal paint_line
	
	li $a1, 3372
	li $a2, 4396
	jal paint_line
	
	li $a1, 3404
	li $a2, 4428
	jal paint_line
	
	sw $a3, 1080($a0)
	sw $a3, 1088($a0)
	sw $a3, 1576($a0)
	sw $a3, 1616($a0)
	sw $a3, 2356($a0)
	sw $a3, 2372($a0)
	sw $a3, 5428($a0)
	sw $a3, 5444($a0)
	sw $a3, 6184($a0)
	sw $a3, 6224($a0)
	sw $a3, 6712($a0)
	sw $a3, 6720($a0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	##### personagens #####
	lw $a3, color_yellow
	sw $a3, 2876($a0)
	lw $a3, color_red
	sw $a3, 520($a0) 
	lw $a3, color_orange
	sw $a3, 624($a0)
	lw $a3, color_ciano
	sw $a3, 7176($a0)
	lw $a3, color_pink
	sw $a3, 7280($a0)
	
	###### endereço dos personagens no bitmap ######
	addi $s0, $a0, 2876 # pac man
	addi $s1, $a0, 520  # red ghost
	addi $s2, $a0, 624  # orange ghost
	addi $s3, $a0, 7176 # ciano ghost
	addi $s4, $a0, 7280 # pink ghost
jr $ra

paint_pts:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, color_white
	li $t1, 4
	
	li $a1, 3480
	li $a2, 3484
	jal paint_line
	
	li $a1, 3992
	li $a2, 3996
	jal paint_line
	
	li $a1, 3492
	li $a2, 3500
	jal paint_line
	
	li $a1, 3508
	li $a2, 3516
	jal paint_line
	
	li $a1, 4020
	li $a2, 4028
	jal paint_line
	
	li $a1, 4532
	li $a2, 4540
	jal paint_line
	
	li $t1, 256
	
	li $a1, 3476
	li $a2, 4500
	jal paint_line
	
	li $a1, 3752
	li $a2, 4520
	jal paint_line
	
	sw $a3, 3740($a0)
	sw $a3, 3764($a0)
	sw $a3, 4284($a0)
	sw $a3, 3780($a0)
	sw $a3, 4548($a0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra

# pinta o TEXTO stage e o valor do stage atual
# $s5 - armazena o valor do stage atual
paint_stage_text:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, color_white
	li $t1, 4
	
	li $a1, 660
	li $a2, 668
	jal paint_line
	
	li $a1, 1172
	li $a2, 1180
	jal paint_line
	
	li $a1, 1684
	li $a2, 1692
	jal paint_line
	
	li $a1, 676
	li $a2, 684
	jal paint_line
	
	li $a1, 692
	li $a2, 700
	jal paint_line
	
	li $a1, 708
	li $a2, 720
	jal paint_line
	
	li $a1, 1732
	li $a2, 1744
	jal paint_line
	
	li $t1, 256
	
	li $a1, 936
	li $a2, 1704
	jal paint_line
	
	li $a1, 948
	li $a2, 1716
	jal paint_line
	
	li $a1, 956
	li $a2, 1724
	jal paint_line
	
	li $a1, 964
	li $a2, 1476
	jal paint_line
	
	li $a1, 728
	li $a2, 1752
	jal paint_line
		
	sw $a3, 916($a0)
	sw $a3, 1436($a0)
	sw $a3, 1464($a0)
	sw $a3, 1228($a0)
	sw $a3, 1232($a0)
	sw $a3, 1488($a0)
	sw $a3, 732($a0)
	sw $a3, 736($a0)
	sw $a3, 1244($a0)
	sw $a3, 1248($a0)
	sw $a3, 1756($a0)
	sw $a3, 1760($a0)

	beq $s5, 1, stage_1_texto
	j nao_stage_1_texto
	stage_1_texto:
		lw $a3, color_white
		li $t1, 4
		
		li $a1, 1772
		li $a2, 1780
		jal paint_line
		
		li $t1, 256
		
		li $a1, 752
		li $a2, 1520
		jal paint_line
		
		sw $a3, 1004($a0)
		
		lw $a3, color_black
		
		sw $a3, 748($a0)
		sw $a3, 756($a0)
		sw $a3, 1260($a0)
		sw $a3, 1516($a0)
		sw $a3, 1012($a0)
		sw $a3, 1268($a0)
		sw $a3, 1524($a0)
	j nao_stage_2_texto
	nao_stage_1_texto:
	
	beq $s5, 2, stage_2_texto
	j nao_stage_2_texto
	stage_2_texto:
		lw $a3, color_white
		li $t1, 4
		
		li $a1, 748
		li $a2, 756
		jal paint_line
		
		li $a1, 1260
		li $a2, 1268
		jal paint_line
		
		li $a1, 1772
		li $a2, 1780
		jal paint_line

		sw $a3, 1012($a0)
		sw $a3, 1516($a0)
		
		lw $a3, color_black
		
		sw $a3, 1004($a0)
		sw $a3, 1008($a0)
		sw $a3, 1520($a0)
		sw $a3, 1524($a0)
	nao_stage_2_texto:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra

# pinta os "pac man's" grandes que representam as vidas
# pinta de acordo com a quantidade de vidas armazenados em $s6
# $s6 - quantidade de vidas
paint_lives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, display_address
	lw $a3, color_yellow
	
	li $t0, 0 # contador do laço
	li $t1, 0 # contador do endereço do pac man (conta de 32 a 32)
	paint_lives_loop:
	beq $t0, $s6, end_paint_lives_loop
		addi $t2, $a0, 6048
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6052
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6056
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6300
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6304
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6308
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6312
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6316
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6552
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6556
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6560
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6564
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6808
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6812
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7064
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7068
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7072
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7076
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7324
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7328
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7332
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7336
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7340
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7584
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7588
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7592
		add $t2, $t2, $t1
		sw $a3, 0($t2)
	addi $t1, $t1, 32
	addi $t0, $t0, 1
	j paint_lives_loop
	end_paint_lives_loop:
	
	li $t0, 3 # valor auxiliar para subtracao
	li $t1, 0 # contador do address
	li $t4, 0 # contador do laço
	sub $t3, $t0, $s6  
	lw $a3, color_black
	
	# pinta de preto as vidas perdidas
	paint_black_lives_loop:
	beq $t4, $t3, end_paint_black_lives_loop
		addi $t2, $a0, 6048
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6052
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6056
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6300
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6304
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6308
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6312
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6316
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6552
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6556
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6560
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6564
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6808
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 6812
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7064
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7068
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7072
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7076
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7324
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7328
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7332
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7336
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7340
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7584
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7588
		add $t2, $t2, $t1
		sw $a3, 0($t2)
		
		addi $t2, $a0, 7592
		add $t2, $t2, $t1
		sw $a3, 0($t2)
	addi $t1, $t1, 32	
	addi $t4, $t4, 1
	j paint_black_lives_loop
	end_paint_black_lives_loop:
		
	lw $ra, 0($sp)
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

# considero o terceiro contador como padrão
# se for o contador 3 nçao incremento o reg contador
# se for o contador 2 incrementar o counter em 16
# se for o contador 2 incrementar o counter em 32
# $a1 - valor a ser pintado
# $a2 - (1 = msb, 3 = lsb)
contador_display:
	la $a0, display_address
	
	# contador 3
	beq $a2, 3, contador_3
	j nao_contador_3
	contador_3:
		li $t0, 32
	j nao_contador_1
	nao_contador_3:
	# contador 2
	beq $a2, 2, contador_2
	j nao_contador_2
	contador_2:
		li $t0, 16
	j nao_contador_1
	nao_contador_2:
	# contador 1
	beq $a2, 1, contador_1
	j nao_contador_1
	contador_1:
		li $t0, 0
	nao_contador_1:
	
	# case 0
	beq $a1, 0, pintar_0
	j nao_pintar_0
	pintar_0:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
	j fim_contador_display
	nao_pintar_0:
	# case 1
	beq $a1, 1, pintar_1
	j nao_pintar_1
	pintar_1:
		lw $t2, color_white
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_1:
	# case 2
	beq $a1, 2, pintar_2
	j nao_pintar_2
	pintar_2:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_2:
	# case 3
	beq $a1, 3, pintar_3
	j nao_pintar_3
	pintar_3:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_3:
	# case 4
	beq $a1, 4, pintar_4
	j nao_pintar_4
	pintar_4:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_4:
	# case 5
	beq $a1, 5, pintar_5
	j nao_pintar_5
	pintar_5:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_5:
	# case 6
	beq $a1, 6, pintar_6
	j nao_pintar_6
	pintar_6:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_6:
	# case 7
	beq $a1, 7, pintar_7
	j nao_pintar_7
	pintar_7:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_7:
	# case 8
	beq $a1, 8, pintar_8
	j nao_pintar_8
	pintar_8:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_8:
	# case 9
	beq $a1, 9, pintar_9
	j nao_pintar_9
	pintar_9:
		lw $t2, color_white
	
		addi $t1, $a0, 3532
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3536
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3540
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4044
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4048
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4052
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4556
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4560
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4564
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3788
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 3796
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4308
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		lw $t2, color_black
		
		addi $t1, $a0, 3792
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4300
		add $t1, $t1, $t0
		sw $t2, 0($t1)
		
		addi $t1, $a0, 4304
		add $t1, $t1, $t0
		sw $t2, 0($t1)
	j fim_contador_display
	nao_pintar_9:
	
	fim_contador_display:
jr $ra
