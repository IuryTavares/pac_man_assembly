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

#	(Detalhes importantes)
#
#	$s0 - posição do pac man	
#	$s1 - posição do fantasma vermelho
#	$s2 - posição do fantasma laranja
#	$s3 - posição do fantasma ciano
#	$s4 - posição do fantasma rosa
#	$s5 - armazena o stage atual (1 ou 2)
#	$s6 - armazena a quantidade de vidas (3 a 0)
#	$s7 - salva a pontuação atual do jogo

.macro sleep(%speed_in_miliseconds)
	li $a0, %speed_in_miliseconds
	li $v0, 32
	syscall
.end_macro 

.macro press_any_key()
	beqz $s6, end_loop_wait # checa se a qtd de vidas é zero
	li $t0, -1		# reseta o contador do reciever
	sw $t0, 0xffff0004 	# reseta o conteudo do reciever do keyboard
	loop_wait:
	bgez $t0, end_loop_wait
	lw $t0, 0xffff0004
	j loop_wait
	end_loop_wait:
.end_macro 

.data
display_address: 	.word 0x10010000
display_size:		.word 2048

color_blue:		.word 0x001818FF
color_yellow:		.word 0x00FFFE1D
color_red: 		.word 0x00DF0902
color_pink:		.word 0x00FA9893
color_ciano:		.word 0x0061FAFC
color_orange:		.word 0x00FC9711
color_black:		.word 0x00000000
color_white:		.word 0x00FFFFFF

indicador_white_red:	.word 0		## (1) indica que o movimento anterior do fantasma foi sobre uma pontuação	
indicador_white_orange:	.word 0		## (0) indica que o movimento anterior do fantasma não foi sobre uma pontuação
indicador_white_ciano:	.word 0		## 
indicador_white_pink:	.word 0		## se for 1, então pintamos a proxima posição da cor do fantasma e a atual de branco

ultima_direcao_red:	.word 2		## Indica a ultima direção que um fantasma se moveu.
ultima_direcao_orange:	.word 2		##	
ultima_direcao_ciano:	.word 5		##	(1) cima 	(2) esquerda
ultima_direcao_pink:	.word 5		## 	(3) baixo 	(5) direita

.text
.globl main
main:
	# configuações iniciais
	li $s5, 1            	# indicando que estamos no stage 1
	li $s6, 3		# indicando que temos 3 vidas iniciais
	li $s7, 0		# indicando que a pontuação inicial é zero

	jal paint_stage_text
	jal paint_pts
	jal contador_da_pontuacao
	jal paint_stage_1
	#j teste
	wait_1: # espera uma tecla ser pressionada para iniciar o movimento do pac man
	jal posicionar_personagens
	jal paint_lives
	press_any_key()
	
	game_loop_stage_1:
	beqz $s6, game_over # checa se a quantidade de vidas é diferente de zero
		# movimentação do pac man
		sleep(200) # velocidade do pac man (PIXEL / MILISEGUNDO)
		jal contador_da_pontuacao
		jal mover_pac_man
		
		# movimentação dos fantasmas
		jal movimentar_fantasma_vermelho
		beq $v0, 1, colisao_stage_1
		jal movimentar_fantasma_laranja
		beq $v0, 1, colisao_stage_1
		jal movimentar_fantasma_ciano
		beq $v0, 1, colisao_stage_1
		jal movimentar_fantasma_rosa
		beq $v0, 1, colisao_stage_1
		
		# configura as colisões
		j sem_colisao_stage_1
		colisao_stage_1:
		jal configurar_colisao
		beq $v0, 1, wait_1
		sem_colisao_stage_1:
		
		beq $s7, 144, end_game_loop_stage_1 # 144 pontos stage 1
	j game_loop_stage_1
	end_game_loop_stage_1:
	teste:
	jal resetar_labirinto
	li $s5, 2
	jal paint_stage_2
	jal paint_stage_text

	wait_2: # espera uma tecla ser pressionada para iniciar o movimento do pac man
	jal posicionar_personagens
	jal paint_lives
	press_any_key()

	game_loop_stage_2:
	beqz $s6, game_over 
		# movimentação do pac man
		sleep(200) # velocidade do pac man (PIXEL / MILISEGUNDO)
		jal contador_da_pontuacao
		jal mover_pac_man
		
		# movimentação dos fantasmas
		jal movimentar_fantasma_vermelho
		beq $v0, 1, colisao_stage_2
		jal movimentar_fantasma_laranja
		beq $v0, 1, colisao_stage_2
		jal movimentar_fantasma_ciano
		beq $v0, 1, colisao_stage_2
		jal movimentar_fantasma_rosa
		beq $v0, 1, colisao_stage_2
		
		# configura as colisões
		j sem_colisao_stage_2
		colisao_stage_2:
		jal configurar_colisao
		beq $v0, 1, wait_2
		sem_colisao_stage_2:
		
		beq $s7, 274, end_game_loop_stage_2 # 130 pontos stage 2, 274 no total.
	j game_loop_stage_2
	end_game_loop_stage_2:
	
	you_win:
	jal resetar_labirinto
	jal paint_you_win
	j end_of_program
	
	game_over:
	jal resetar_labirinto
	jal paint_game_over

end_of_program:
li $v0, 10 # fim do programa
syscall

# checa se o pac man tocou em algum fantasma
# se ocorreu uma colisao a função pinta a nova quantidade de vidas
# $v0 - retorna 1 se houver colisão, 0 se não houver
configurar_colisao:
	sub $s6, $s6, 1		# atualiza a quantidade total de vidas
	
	# repintando posição atual do pac man da devida cor
	lw $t0, color_black
	sw $t0, 0($s0)
	
	# repintando posição atual do fantasma red da devida cor
	lw $t0, indicador_white_red
	beqz $t0, black_reposicionar_red 
	lw $a3, color_white
	sw $a3, 0($s1)
	sw $zero, indicador_white_red
	j exit_reposicionar_red
	black_reposicionar_red:
	lw $a3, color_black
	sw $a3, 0($s1)
	exit_reposicionar_red:
	
	# repintando posição atual do fantasma orange da devida cor
	lw $t0, indicador_white_orange
	beqz $t0, black_reposicionar_orange 
	lw $a3, color_white
	sw $a3, 0($s2)
	sw $zero, indicador_white_orange
	j exit_reposicionar_orange
	black_reposicionar_orange:
	lw $a3, color_black
	sw $a3, 0($s2)
	exit_reposicionar_orange:
	
	# repintando posição atual do fantasma ciano da devida cor
	lw $t0, indicador_white_ciano
	beqz $t0, black_reposicionar_ciano
	lw $a3, color_white
	sw $a3, 0($s3)
	sw $zero, indicador_white_ciano
	j exit_reposicionar_ciano
	black_reposicionar_ciano:
	lw $a3, color_black
	sw $a3, 0($s3)
	exit_reposicionar_ciano:
	
	# repintando posição atual do fantasma pink da devida cor
	lw $t0, indicador_white_pink
	beqz $t0, black_reposicionar_pink
	lw $a3, color_white
	sw $a3, 0($s4)
	sw $zero, indicador_white_pink
	j exit_reposicionar_pink
	black_reposicionar_pink:
	lw $a3, color_black
	sw $a3, 0($s4)
	exit_reposicionar_pink:
jr $ra

# posiciona os personagens de acordo com o stage
# usado no inicio do jogo ou quando uma vida é perdida
# o stage é salvo em $s5
posicionar_personagens:
	la $a0, display_address
	beq $s5, 1, posicionar_stage_1
	j nao_posicionar_stage_1
	posicionar_stage_1:
		##### pintando personagens nas devidas posições #####
		lw $a3, color_yellow
		sw $a3, 1340($a0)
		lw $a3, color_red
		sw $a3, 4916($a0) 
		lw $a3, color_orange
		sw $a3, 4920($a0)
		lw $a3, color_ciano
		sw $a3, 4928($a0)
		lw $a3, color_pink
		sw $a3, 4932($a0)
	
		###### endereço dos personagens no bitmap ######
		addi $s0, $a0, 1340 # pac man
		addi $s1, $a0, 4916  # red ghost
		addi $s2, $a0, 4920  # orange ghost
		addi $s3, $a0, 4928 # ciano ghost
		addi $s4, $a0, 4932 # pink ghost
	j nao_posicionar_stage_2
	nao_posicionar_stage_1:
		
	beq $s5, 2, posicionar_stage_2
	j nao_posicionar_stage_2
	posicionar_stage_2:
		##### pintando personagens nas devidas posições #####
		lw $a3, color_yellow
		sw $a3, 3900($a0)
		lw $a3, color_red
		sw $a3, 5428($a0) 
		lw $a3, color_orange
		sw $a3, 5432($a0)
		lw $a3, color_ciano
		sw $a3, 5440($a0)
		lw $a3, color_pink
		sw $a3, 5444($a0)
	
		###### endereço dos personagens no bitmap ######
		addi $s0, $a0, 3900 # pac man
		addi $s1, $a0, 5428  # red ghost
		addi $s2, $a0, 5432  # orange ghost
		addi $s3, $a0, 5440 # ciano ghost
		addi $s4, $a0, 5444 # pink ghost
	nao_posicionar_stage_2:
jr $ra

# pinta no display a pontuação atual
# recebe a pontuação em $s7
contador_da_pontuacao:
	move $t8, $s7 # guarda num registrador auxiliar a pontuação total

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# armazenando o dígito da centena em $t1
	div $t1, $t8, 100	#
	mul $t4, $t1, 100	#	PINTANDO O DISPLAY DA CENTENA
	sub $t8, $t8, $t4	#
				#
	move $a1, $t1		# valor a ser pintado
	li $a2, 1		# display a ser pintado
	jal contador_display
	
	lw $t0, 4($sp)
	
	# armazenando o dígito da dezena em $t2
	div $t2, $t8, 10	#
	mul $t4, $t2, 10	#	PINTANDO O DISPLAY DA DEZENA
	sub $t8, $t8, $t4	#
				#
	move $a1, $t2		# valor a ser pintado
	li $a2, 2		# display a ser pintado
	jal contador_display
	
	# armazenando o dígito da unidade em $t3
	move $t3, $t8		#
				#
	move $a1, $t3		# valor a ser pintado
	li $a2, 3		# display a ser pintado
	jal contador_display
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra


mover_pac_man:
	la $a0, display_address # se nao pegar, testar com load word
	lw $v0, 0xffff0004	# movimento com keyboard
	#li $v0, 12
	#syscall
	
	beq $v0, 119, mover_w
	j nao_mover_w
	mover_w:
		sub $t0, $s0, 256  			# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posição
		beq $t2, $t1, fim_mover_pac_man 	# PAREDE, NÃO MOVER
		lw $t1, color_white			# salva a nova posição do pac man
		
		beq $t2, $t1, incrementar_pontuacao_w 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_w
		incrementar_pontuacao_w:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_w:
		
		lw $t1, color_yellow
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, color_black #  pinta posição antiga de preto
		sw $t1, 0($s0)
		sub $s0, $s0, 256
		j fim_mover_pac_man
	nao_mover_w:
	beq $v0, 97, mover_a
	j nao_mover_a
	mover_a:
		sub $t0, $s0, 4  			# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posição
		beq $t2, $t1, fim_mover_pac_man 	# se o conteudo for a cor azul, nao mover
		lw $t1, color_white			# salva a nova posição do pac man
		
		beq $t2, $t1, incrementar_pontuacao_a 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_a
		incrementar_pontuacao_a:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_a:
		
		addi $t1, $a0, 3844 # endereço do portal da esquerda
		beq $t0, $t1, mover_pelo_portal_w  # se der falso, entao é um movimento comum
		
		# MOVIMENTO COMUM
		lw $t1, color_yellow
		sw $t1, 0($t0) 				# nova posição de vermelho
		lw $t1, color_black  			# pinta posição antida de preto
		sw $t1, 0($s0) 				# posição antiga do personagem
		sub $s0, $s0, 4				# salva a nova posição do pac man
		j fim_mover_pac_man
		
		# MOVIMENTO PELO PORTAL ESQUERDO - muda a posição para 3952
		mover_pelo_portal_w:
		addi $t0, $a0, 3952   	# endereço do portal direito
		lw $t1, color_yellow	# carregando a cor amarela
		sw $t1, 0($t0)		# pintando o pac man no outro portal
		lw $t1, color_black	# carregando a cor preto
		sw $t1, 0($s0)		# pintando de preto onde o pac man estava
		addi $s0, $a0, 3952	# salva a nova posição do pac man
		
		j fim_mover_pac_man
	nao_mover_a:
	beq $v0, 115, mover_s
	j nao_mover_s
	mover_s:
		add $t0, $s0, 256  			# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posição
		beq $t2, $t1, fim_mover_pac_man 	# se o conteudo for a cor azul, nao mover
		lw $t1, color_white
		
		beq $t2, $t1, incrementar_pontuacao_s 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_s
		incrementar_pontuacao_s:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_s:
		
		lw $t1, color_yellow
		sw $t1, 0($t0) 				# nova posição de vermelho
		lw $t1, color_black  			# pinta posição antida de preto
		sw $t1, 0($s0) 				# posição antiga do personagem
		add $s0, $s0, 256
		j fim_mover_pac_man
	nao_mover_s:
	beq $v0, 100, mover_d
	j nao_mover_d
	mover_d:
		add $t0, $s0, 4  			# calculo a nova posição e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posição
		beq $t2, $t1, fim_mover_pac_man 	# se o conteudo for a cor azul, nao mover
		lw $t1, color_white
		
		beq $t2, $t1, incrementar_pontuacao_d 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_d
		incrementar_pontuacao_d:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_d:
		
		addi $t1, $a0, 3956 # endereço do portal da direita
		beq $t0, $t1, mover_pelo_portal_d  # se der falso, entao é um movimento comum
		
		# MOVIMENTO COMUM
		lw $t1, color_yellow
		sw $t1, 0($t0) 				# nova posição de vermelho
		lw $t1, color_black 			# pinta posição antida de preto
		sw $t1, 0($s0) 				# posição antiga do personagem
		add $s0, $s0, 4				# salva a nova posição do pac man
		j fim_mover_pac_man
		
		# MOVIMENTO PELO PORTAL DIREITO - muda a posição para 3848
		mover_pelo_portal_d:
		addi $t0, $a0, 3848   	# endereço do portal direito
		lw $t1, color_yellow	# carregando a cor amarela
		sw $t1, 0($t0)		# pintando o pac man no outro portal
		lw $t1, color_black	# carregando a cor preto
		sw $t1, 0($s0)		# pintando de preto onde o pac man estava
		addi $s0, $a0, 3848	# salva a nova posição do pac man
		
		j fim_mover_pac_man
	nao_mover_d:
	
	fim_mover_pac_man:
jr $ra

# pinta no display o labirinto e  a pontuação
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
	
	li $a1, 520
	li $a2, 568
	jal paint_line
	
	li $a1, 576
	li $a2, 624
	jal paint_line

	li $a1, 2828
	li $a2, 2924
	jal paint_line
	
	li $a1, 1292
	li $a2, 1332
	jal paint_line
	
	li $a1, 1348
	li $a2, 1388
	jal paint_line
	
	li $a1, 4876
	li $a2, 4908
	jal paint_line
	
	li $a1, 4940
	li $a2, 4972
	jal paint_line
	
	li $a1, 6412
	li $a2, 6508
	jal paint_line
	
	li $a1, 7176
	li $a2, 7224
	jal paint_line
	
	li $a1, 7232
	li $a2, 7280
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
jr $ra

# pinta no display o labirinto e a pontuação
paint_stage_2:
	la $a0, display_address
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# pintando labirinto
	li $t1, 4
	lw $a3, color_blue
	
	li $a1, 260
	li $a2, 372
	jal paint_line
	
	li $a1, 800
	li $a2, 824
	jal paint_line
	
	li $a1, 832
	li $a2, 856
	jal paint_line
	
	li $a1, 1056
	li $a2, 1080
	jal paint_line
	
	li $a1, 1088
	li $a2, 1112
	jal paint_line
	
	li $a1, 1312
	li $a2, 1336
	jal paint_line
	
	li $a1, 1344
	li $a2, 1368
	jal paint_line
	
	li $a1, 1568
	li $a2, 1592
	jal paint_line
	
	li $a1, 1600
	li $a2, 1624
	jal paint_line
	
	li $a1, 1824
	li $a2, 1848
	jal paint_line
	
	li $a1, 1856
	li $a2, 1880
	jal paint_line
	
	li $a1, 2348
	li $a2, 2380
	jal paint_line
	
	li $a1, 2604
	li $a2, 2636
	jal paint_line
	
	li $a1, 2316
	li $a2, 2328
	jal paint_line
	
	li $a1, 2572
	li $a2, 2584
	jal paint_line
	
	li $a1, 2828
	li $a2, 2840
	jal paint_line
	
	li $a1, 3084
	li $a2, 3096
	jal paint_line
	
	li $a1, 3104
	li $a2, 3120
	jal paint_line
	
	li $a1, 3360
	li $a2, 3376
	jal paint_line
	
	li $a1, 3616
	li $a2, 3632
	jal paint_line
	
	li $a1, 2400
	li $a2, 2412
	jal paint_line
	
	li $a1, 2656
	li $a2, 2668
	jal paint_line
	
	li $a1, 2912
	li $a2, 2924
	jal paint_line
	
	li $a1, 3168
	li $a2, 3180
	jal paint_line
	
	li $a1, 3144
	li $a2, 3160
	jal paint_line
	
	li $a1, 3400
	li $a2, 3416
	jal paint_line
	
	li $a1, 3656
	li $a2, 3672
	jal paint_line
	
	li $a1, 3588
	li $a2, 3608
	jal paint_line
	
	li $a1, 4100
	li $a2, 4120
	jal paint_line
	
	li $a1, 3680
	li $a2, 3700
	jal paint_line
	
	li $a1, 4192
	li $a2, 4212
	jal paint_line
	
	li $a1, 4128
	li $a2, 4136
	jal paint_line
	
	li $a1, 4384
	li $a2, 4392
	jal paint_line
	
	li $a1, 4620
	li $a2, 4648
	jal paint_line
	
	li $a1, 4876
	li $a2, 4904
	jal paint_line
	
	li $a1, 5132
	li $a2, 5160
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
	
	li $a1, 4912
	li $a2, 4936
	jal paint_line
	
	li $a1, 5168
	li $a2, 5192
	jal paint_line
	
	li $a1, 4176
	li $a2, 4184
	jal paint_line
	
	li $a1, 4432
	li $a2, 4440
	jal paint_line
	
	li $a1, 4688
	li $a2, 4716
	jal paint_line
	
	li $a1, 4944
	li $a2, 4972
	jal paint_line
	
	li $a1, 5200
	li $a2, 5228
	jal paint_line
	
	li $a1, 7172
	li $a2, 7284
	jal paint_line
	
	li $t1, 20
	
	li $a1, 5656
	li $a2, 5716
	jal paint_line
	
	li $a1, 5660
	li $a2, 5720
	jal paint_line
	
	li $a1, 5664
	li $a2, 5724
	jal paint_line
	
	li $a1, 5668
	li $a2, 5728
	jal paint_line
	
	li $a1, 5912
	li $a2, 5972
	jal paint_line
	
	li $a1, 5916
	li $a2, 5976
	jal paint_line
	
	li $a1, 5920
	li $a2, 5980
	jal paint_line
	
	li $a1, 5924
	li $a2, 5984
	jal paint_line
	
	li $a1, 6424
	li $a2, 6484
	jal paint_line
	
	li $a1, 6428
	li $a2, 6488
	jal paint_line
	
	li $a1, 6432
	li $a2, 6492
	jal paint_line
	
	li $a1, 6436
	li $a2, 6496
	jal paint_line
	
	li $a1, 6680
	li $a2, 6740
	jal paint_line
	
	li $a1, 6684
	li $a2, 6744
	jal paint_line
	
	li $a1, 6688
	li $a2, 6748
	jal paint_line
	
	li $a1, 6692
	li $a2, 6752
	jal paint_line
	
	li $t1, 256
	
	li $a1, 516
	li $a2, 3332
	jal paint_line
	
	li $a1, 4356
	li $a2, 6916
	jal paint_line
	
	li $a1, 628
	li $a2, 3444
	jal paint_line
	
	li $a1, 4468
	li $a2, 7028
	jal paint_line
	
	li $a1, 5644
	li $a2, 6668
	jal paint_line
	
	li $a1, 5648
	li $a2, 6672
	jal paint_line
	
	li $a1, 5736
	li $a2, 6760
	jal paint_line
	
	li $a1, 5740
	li $a2, 6764
	jal paint_line
	
	li $a1, 780
	li $a2, 1804
	jal paint_line
	
	li $a1, 784
	li $a2, 1808
	jal paint_line
	
	li $a1, 788
	li $a2, 1812
	jal paint_line
	
	li $a1, 792
	li $a2, 1816
	jal paint_line
	
	li $a1, 2336
	li $a2, 2848
	jal paint_line
	
	li $a1, 2340
	li $a2, 2852
	jal paint_line
	
	li $a1, 864
	li $a2, 1888
	jal paint_line
	
	li $a1, 868
	li $a2, 1892
	jal paint_line
	
	li $a1, 872
	li $a2, 1896
	jal paint_line
	
	li $a1, 876
	li $a2, 1900
	jal paint_line
	
	li $a1, 2388
	li $a2, 2900
	jal paint_line
	
	li $a1, 2392
	li $a2, 2904
	jal paint_line
	
	li $a1, 2872
	li $a2, 3640
	jal paint_line
	
	li $a1, 2876
	li $a2, 3644
	jal paint_line
	
	li $a1, 2880
	li $a2, 3648
	jal paint_line
	
	# pintando pontuação
	lw $a3, color_white
	li $t1, 8
		
	li $a1, 520
	li $a2, 624
	jal paint_line
	
	li $a1, 6920
	li $a2, 7024
	jal paint_line
	
	li $a1, 4364
	li $a2, 4380
	jal paint_line
	
	li $a1, 5384
	li $a2, 5416
	jal paint_line
	
	li $a1, 6164
	li $a2, 6244
	jal paint_line
	
	li $a1, 5456
	li $a2, 5488
	jal paint_line
	
	li $a1, 3868
	li $a2, 3932
	jal paint_line
	
	li $a1, 3340
	li $a2, 3356
	jal paint_line
	
	li $a1, 3420
	li $a2, 3436
	jal paint_line
	
	li $a1, 2056
	li $a2, 2160
	jal paint_line
	
	li $a1, 4444
	li $a2, 4460
	jal paint_line
	
	li $a1, 2860
	li $a2, 2868
	jal paint_line
	
	li $a1, 2884
	li $a2, 2892
	jal paint_line
	
	li $t1, 512
	
	li $a1, 1032
	li $a2, 3080
	jal paint_line
	
	li $a1, 796
	li $a2, 4380
	jal paint_line
	
	li $a1, 2868
	li $a2, 3892
	jal paint_line
	
	li $a1, 2884
	li $a2, 3908
	jal paint_line
	
	li $a1, 828
	li $a2, 1852
	jal paint_line
	
	li $a1, 860
	li $a2, 4444
	jal paint_line
	
	li $a1, 1136
	li $a2, 3184
	jal paint_line
	
	li $a1, 4872
	li $a2, 6920
	jal paint_line
	
	li $a1, 5652
	li $a2, 6676
	jal paint_line
	
	li $a1, 5928
	li $a2, 6440
	jal paint_line
	
	li $a1, 5692
	li $a2, 6716
	jal paint_line
	
	li $a1, 5968
	li $a2, 6480
	jal paint_line
	
	li $a1, 5732
	li $a2, 6756
	jal paint_line
	
	li $a1, 4976
	li $a2, 7024
	jal paint_line
	
	li $a1, 4428
	li $a2, 4940
	jal paint_line
	
	li $a1, 4396
	li $a2, 4908
	jal paint_line
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
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
	
	# contador auxiliar da pintura de vidas
	li $t4, 0 # conta a partir de qual vida as demais seão pintadas de preto
	
	paint_lives_loop:
	beq $t0, 3, end_paint_lives_loop
		
		beq $t4, $s6, pintar_vidas_de_preto
		j nao_pintar_vidas_de_preto
		pintar_vidas_de_preto:
			lw $a3, color_black
		nao_pintar_vidas_de_preto:
		
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
	addi $t1, $t1, 32 # contador do enrereço
	addi $t0, $t0, 1 # contador do laço 
	addi $t4, $t4, 1 # contador da pintura
	j paint_lives_loop
	end_paint_lives_loop:
		
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

paint_game_over:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, color_red
	
	## G ##
	li $t1, 256
	
	li $a1, 2068
	li $a2, 3860
	jal paint_line
	
	li $a1, 2320
	li $a2, 3600
	jal paint_line
	
	li $a1, 2852
	li $a2, 3876
	jal paint_line
	
	li $a1, 2856
	li $a2, 3624
	jal paint_line
	
	li $t1, 4
	
	li $a1, 2072
	li $a2, 2084
	jal paint_line
	
	li $a1, 2328
	li $a2, 2340
	jal paint_line
	
	li $a1, 3608
	li $a2, 3616
	jal paint_line
	
	li $a1, 3864
	li $a2, 3872
	jal paint_line
	
	sw $a3, 2848($a0)
	sw $a3, 3104($a0)
	
	## A ##
	
	li $t1, 256
	
	li $a1, 2352
	li $a2, 3888
	jal paint_line
	
	li $a1, 2100
	li $a2, 3892
	jal paint_line
	
	li $a1, 2108
	li $a2, 3900
	jal paint_line
	
	li $a1, 2368
	li $a2, 3904
	jal paint_line
	
	sw $a3, 2104($a0)
	sw $a3, 2360($a0)
	sw $a3, 3128($a0)
	sw $a3, 3384($a0)
	
	## M ##
	
	li $a1, 2120
	li $a2, 3912
	jal paint_line
	
	li $a1, 2124
	li $a2, 3916
	jal paint_line
	
	li $a1, 2384
	li $a2, 2896
	jal paint_line
	
	li $a1, 2644
	li $a2, 3156
	jal paint_line
	
	li $a1, 2904
	li $a2, 3416
	jal paint_line
	
	li $a1, 2652
	li $a2, 3164
	jal paint_line
	
	li $a1, 2400
	li $a2, 2912
	jal paint_line
	
	li $a1, 2148
	li $a2, 3940
	jal paint_line
	
	li $a1, 2152
	li $a2, 3944
	jal paint_line
	
	## E ##
	li $a1, 2160
	li $a2, 3952
	jal paint_line
	
	li $a1, 2164
	li $a2, 3956
	jal paint_line
	
	li $t1, 4
	
	li $a1, 2168
	li $a2, 2176
	jal paint_line
	
	li $a1, 2424
	li $a2, 2432
	jal paint_line
	
	li $a1, 2936
	li $a2, 2944
	jal paint_line
	
	li $a1, 3192
	li $a2, 3200
	jal paint_line
	
	li $a1, 3704
	li $a2, 3712
	jal paint_line
	
	li $a1, 3960
	li $a2, 3968
	jal paint_line
	
	## O ##
	li $t1, 256
	
	li $a1, 4628
	li $a2, 5908
	jal paint_line
	
	li $a1, 4376
	li $a2, 6168
	jal paint_line
	
	li $a1, 4388
	li $a2, 6180
	jal paint_line
	
	li $a1, 4648
	li $a2, 5928
	jal paint_line
	
	sw $a3, 4380($a0)
	sw $a3, 4384($a0)
	sw $a3, 4636($a0)
	sw $a3, 4640($a0)
	sw $a3, 5916($a0)
	sw $a3, 5920($a0)
	sw $a3, 6172($a0)
	sw $a3, 6176($a0)
	
	## V ##
	li $a1, 4400
	li $a2, 5680
	jal paint_line
	
	li $a1, 4404
	li $a2, 5940
	jal paint_line
	
	li $a1, 4420
	li $a2, 5956
	jal paint_line
	
	li $a1, 4424
	li $a2, 5704
	jal paint_line
	
	li $a1, 5688
	li $a2, 6200
	jal paint_line
	
	li $a1, 5696
	li $a2, 6208
	jal paint_line
	
	sw $a3, 5948($a0)
	sw $a3, 6204($a0)
	
	## E ##
	
	li $a1, 4432
	li $a2, 6224
	jal paint_line
	
	li $a1, 4436
	li $a2, 6228
	jal paint_line
	
	li $t1, 4
	
	li $a1, 4440
	li $a2, 4448
	jal paint_line
	
	li $a1, 5208
	li $a2, 5216
	jal paint_line
	
	li $a1, 4696
	li $a2, 4704
	jal paint_line
	
	li $a1, 5464
	li $a2, 5472
	jal paint_line
	
	li $a1, 5976
	li $a2, 5984
	jal paint_line
	
	li $a1, 6232
	li $a2, 6240
	jal paint_line
	
	## R ##
	
	li $t1, 256
	
	li $a1, 4456
	li $a2, 6248
	jal paint_line
	
	li $a1, 4460
	li $a2, 6252
	jal paint_line
	
	li $a1, 4472
	li $a2, 6264
	jal paint_line
	
	li $a1, 4732
	li $a2, 5244
	jal paint_line
	
	li $a1, 5756
	li $a2, 6268
	jal paint_line
	
	sw $a3, 4464($a0)
	sw $a3, 4468($a0)
	sw $a3, 4720($a0)
	sw $a3, 4724($a0)
	sw $a3, 5488($a0)
	sw $a3, 5492($a0)
	sw $a3, 5744($a0)
	sw $a3, 5748($a0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	

jr $ra

paint_you_win:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, color_red
	li $t1, 256
	
	### Y #####
	li $a1, 2076
	li $a2, 2332
	jal paint_line
	
	li $a1, 2080
	li $a2, 2592
	jal paint_line
	
	li $a1, 2340
	li $a2, 2852
	jal paint_line
	
	li $a1, 2600
	li $a2, 3880
	jal paint_line
	
	li $a1, 2604
	li $a2, 3884
	jal paint_line
	
	li $a1, 2352
	li $a2, 2864
	jal paint_line
	
	li $a1, 2100
	li $a2, 2612
	jal paint_line
	
	li $a1, 2104
	li $a2, 2360
	jal paint_line
	
	#### O ###
	
	li $a1, 2368
	li $a2, 3648
	jal paint_line
	
	li $a1, 2116
	li $a2, 3908
	jal paint_line
	
	li $a1, 2128
	li $a2, 3920
	jal paint_line
	
	li $a1, 2388
	li $a2, 3668
	jal paint_line
	
	sw $a3, 2120($a0)
	sw $a3, 2124($a0)
	sw $a3, 2376($a0)
	sw $a3, 2380($a0)
	sw $a3, 3656($a0)
	sw $a3, 3660($a0)
	sw $a3, 3912($a0)
	sw $a3, 3916($a0)
	
	## U ##
	li $a1, 2140
	li $a2, 3676
	jal paint_line
	
	li $a1, 2144
	li $a2, 3936
	jal paint_line
	
	li $a1, 2160
	li $a2, 3952
	jal paint_line
	
	li $a1, 2164
	li $a2, 3700
	jal paint_line
	
	li $a1, 3684
	li $a2, 3940
	jal paint_line
	
	li $a1, 3688
	li $a2, 3944
	jal paint_line
	
	li $a1, 3692
	li $a2, 3948
	jal paint_line
	
	## W ##
	li $a1, 4376
	li $a2, 5656
	jal paint_line
	
	li $a1, 4380
	li $a2, 5916
	jal paint_line
	
	li $a1, 5664
	li $a2, 6176
	jal paint_line
	
	li $a1, 5672
	li $a2, 6184
	jal paint_line
	
	li $a1, 4396
	li $a2, 5932
	jal paint_line
	
	li $a1, 4400
	li $a2, 5936
	jal paint_line
	
	li $a1, 4416
	li $a2, 5952
	jal paint_line
	
	li $a1, 4420
	li $a2, 5700
	jal paint_line
	
	li $a1, 5684
	li $a2, 6196
	jal paint_line
	
	li $a1, 5692
	li $a2, 6204
	jal paint_line
	
	sw $a3, 5924($a0)
	sw $a3, 6180($a0)
	sw $a3, 5944($a0)
	sw $a3, 6200($a0)	
	
	## I ##
	li $a1, 5200
	li $a2, 6224
	jal paint_line
	
	li $a1, 5196
	li $a2, 6220
	jal paint_line
	
	sw $a3, 4428($a0)
	sw $a3, 4432($a0)
	sw $a3, 4684($a0)
	sw $a3, 4688($a0)
	
	## N ##
	
	li $a1, 4440
	li $a2, 6232
	jal paint_line
	
	li $a1, 4444
	li $a2, 6236
	jal paint_line
	
	li $a1, 4468
	li $a2, 6260
	jal paint_line
	
	li $a1, 4472
	li $a2, 6264
	jal paint_line
	
	li $a1, 4704
	li $a2, 4960
	jal paint_line
	
	li $a1, 4964
	li $a2, 5220
	jal paint_line
	
	li $a1, 5224
	li $a2, 5480
	jal paint_line
	
	li $a1, 5484
	li $a2, 5740
	jal paint_line
		
	li $a1, 5744
	li $a2, 6000
	jal paint_line
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra

# pinta o labirinto de preto
resetar_labirinto:
	la $a0, display_address
	li $t4, 260
	lw $a3, color_black
	li $t1, 4
	
	addi $sp, $sp, -4
	sw $ra 0($sp)

	loop_reset:
	bgt $t4, 7428, end_loop_reset
		move $a1, $t4
		addi $a2, $t4, 112
		jal paint_line
	addi $t4, $t4, 256
	j loop_reset
	end_loop_reset:
	
	lw $ra 0($sp)
	addi $sp, $sp, 4
jr $ra
		
movimentar_fantasma_vermelho:
	li $t9, 0
	li $t0, 0 # conta a quantidade de movimentos válidos
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s1, 256	# endereço fantasma vermelho acima
	sub $t2, $s1, 4		# endereço fantasma vermelho esquerda
	addi $t3, $s1, 256	# endereço fantasma vermelho abaixo
	addi $t4, $s1, 4	# endereço fantasma vermelho direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_red # parede acima
	lw $a3, color_orange
	beq $a3, $a2, invalido_cima_red # fantasma laranja acima
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_cima_red # fantasma azul acima
	lw $a3, color_pink	
	beq $a3, $a2, invalido_cima_red # fantasma rosa acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1
	invalido_cima_red:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_red # parede a esquerda
	lw $a3, color_orange
	beq $a3, $a2, invalido_esquerda_red # fantasma laranja a esquerda
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_esquerda_red # fantasma azul a esquerda
	lw $a3, color_pink	
	beq $a3, $a2, invalido_esquerda_red # fantasma rosa a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_red:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_red # parede abaixo
	lw $a3, color_orange
	beq $a3, $a2, invalido_baixo_red # fantasma laranja abaixo
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_baixo_red # fantasma azul abaixo
	lw $a3, color_pink	
	beq $a3, $a2, invalido_baixo_red # fantasma rosa abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_red:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_red # parede a direita
	lw $a3, color_orange
	beq $a3, $a2, invalido_direita_red # fantasma laranja a direita
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_direita_red # fantasma azul a direita
	lw $a3, color_pink	
	beq $a3, $a2, invalido_direita_red # fantasma rosa a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_red:
	
	### 2º parte, segue para os calculos de movimentação ###
	beq $t0, 0, nenhum_movimento_possivel_red
	beq $t0, 1, um_movimento_possivel_red
	beq $t0, 2, dois_movimentos_possiveis_red
	beq $t0, 3, tres_movimentos_possiveis_red
	beq $t0, 4, quatro_movimentos_possiveis_red
	
	# permanece na mesma posição
	nenhum_movimento_possivel_red: 
	j end_fantasma_red
	
	# calcula qual a direção e se movimento nela
	um_movimento_possivel_red:
		beq $t9, 1, mover_cima_red
		beq $t9, 2, mover_esquerda_red
		beq $t9, 3, mover_baixo_red
		beq $t9, 5, mover_direita_red
	
	dois_movimentos_possiveis_red:
	
		lw $t0, ultima_direcao_red
		beq $t9, 7, dois_direita_esquerda_red
		beq $t9, 4, dois_cima_baixo_red
		beq $t9, 3, dois_cima_esquerda_red
		beq $t9, 6, dois_cima_direita_red
		beq $t9, 5, dois_baixo_esquerda_red
		beq $t9, 8, dois_baixo_direita_red
		
		dois_direita_esquerda_red: # 7
			beq $t0, 2, mover_esquerda_red
			beq $t0, 5, mover_direita_red
			
		dois_cima_baixo_red: # 4
			beq $t0, 1, mover_cima_red
			beq $t0, 3, mover_baixo_red
			
		dois_cima_esquerda_red: # 3
			beq $t0, 5, mover_cima_red
			beq $t0, 3, mover_esquerda_red
			
		dois_cima_direita_red: # 6
			beq $t0, 2, mover_cima_red
			beq $t0, 3, mover_direita_red
			
		dois_baixo_esquerda_red: # 5
			beq $t0, 5, mover_baixo_red
			beq $t0, 1, mover_esquerda_red
			
		dois_baixo_direita_red: # 8
			beq $t0, 2, mover_baixo_red
			beq $t0, 1, mover_direita_red
			
	tres_movimentos_possiveis_red:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do red ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do red ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do red ghost
		move $t4, $v1 # coluna do red ghost
		
		beq $t1, $t3, tres_mesma_linha_red
		beq $t2, $t4, tres_mesma_coluna_red
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		j tres_sem_perseguicao_red
		
		tres_mesma_linha_red:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_red
			lw $t0, 0xffff0004
			beq $t0, 97, mover_esquerda_red # a
			beq $t0, 100, mover_direita_red # d
		
		tres_mesma_coluna_red:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_red
			lw $t0, 0xffff0004
			beq $t0, 119, mover_cima_red # w
			beq $t0, 115, mover_baixo_red # s
		
		tres_sem_perseguicao_red:
		
		# gerando o numero aleatorio em $a0
		li $v0, 42
		li $a1, 3
		syscall
	 	
	 	lw $t0, ultima_direcao_red
	 	beq $t9, 8,  direita_cima_esquerda_red
	 	beq $t9, 6,  cima_esquerda_baixo_red
	 	beq $t9, 10, esquerda_baixo_direita_red
	 	beq $t9, 9,  baixo_direita_cima_red
	 	
	 	direita_cima_esquerda_red:# 8
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, cima_esquerda_red
	 		beq $t9, 5, esquerda_direita_red
	 		beq $t9, 2, cima_direita_red
	 		
	 	cima_esquerda_baixo_red: # 6
	 		sub $t9, $t9, $t0
	 		beq $t9, 3, baixo_esquerda_red
	 		beq $t9, 1, cima_baixo_red
	 		beq $t9, 5, cima_esquerda_red
	 		
	 	esquerda_baixo_direita_red: # 10
	 		sub $t9, $t9, $t0
	 		beq $t9, 8, baixo_esquerda_red
	 		beq $t9, 9, esquerda_direita_red
	 		beq $t9, 5, baixo_direita_red
	 		
	 	baixo_direita_cima_red: # 9
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, baixo_direita_red
	 		beq $t9, 7, cima_baixo_red
	 		beq $t9, 8, cima_direita_red
	 		
	 	esquerda_direita_red:
	 		beq $a0, 0, mover_esquerda_red
	 		beq $a0, 1, mover_direita_red
	 	
	 	cima_baixo_red:
			beq $a0, 0, mover_cima_red
	 		beq $a0, 1, mover_baixo_red
	 		
		cima_esquerda_red:
			beq $a0, 0, mover_esquerda_red
	 		beq $a0, 1, mover_cima_red
	 		
		cima_direita_red:
			beq $a0, 0, mover_cima_red
	 		beq $a0, 1, mover_direita_red
	 		
	 	baixo_esquerda_red:
	 		beq $a0, 0, mover_esquerda_red
	 		beq $a0, 1, mover_baixo_red
	 	
	 	baixo_direita_red:
			beq $a0, 0, mover_direita_red
	 		beq $a0, 1, mover_baixo_red
		
	quatro_movimentos_possiveis_red:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do red ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do red ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do red ghost
		move $t4, $v1 # coluna do red ghost
		
		# pac man - ($t1,$t2), red ghost - ($t3,$t4)
		move $a0, $t3	# x do fantasma
		move $a1, $t4	# y do fantasma
		
		# se eles estiverem na mesma linha ou coluna
		beq $t1, $t3, mesma_linha_red
		beq $t2, $t4, mesma_coluna_red

		#determinar o quadrante que o pac man está em relação ao red ghost
		bgt $t3, $t1, quadrante_esquerda_red 
		j quadrante_direita_red
		
		quadrante_esquerda_red:
			blt $t4, $t1, quadrante_cima_esquerda_red
			j quadrante_baixo_esquerda_red
			
		quadrante_direita_red:
			blt $t4, $t1, quadrante_cima_direita_red
			j quadrante_baixo_direita_red
		
		# efetua a lógica dos movimentos
		quadrante_cima_esquerda_red:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_esquerda_red
			# ir para cima
			bgt $v1, $v0, mover_cima_red 
			# ir para esquerda
			j mover_esquerda_red
			
		quadrante_baixo_esquerda_red:
			move $a2, $t1
			move $a3, $t4 
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_esquerda_red
			# ir para cima
			bgt $v1, $v0, mover_baixo_red 
			# ir para esquerda
			j mover_esquerda_red
			
		quadrante_cima_direita_red:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_direita_red
			# ir para cima
			bgt $v1, $v0, mover_cima_red 
			# ir para esquerda
			j mover_direita_red
			
		quadrante_baixo_direita_red:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_direita_red
			# ir para cima
			bgt $v1, $v0, mover_baixo_red 
			# ir para esquerda
			j mover_direita_red
			
		randomico_cima_esquerda_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_red
			j  mover_esquerda_red
			
		randomico_baixo_esquerda_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_red
			j  mover_esquerda_red
			
		randomico_cima_direita_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_red
			j  mover_direita_red
			
		randomico_baixo_direita_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_red
			j  mover_direita_red
			
		mesma_linha_red:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			blt $t3, $t1, mover_direita_red # pac man a direita - vá para direita
			j mover_esquerda_red # senão vá para esquerda
			
		mesma_coluna_red:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			blt $t4, $t2, mover_cima_red
			j mover_baixo_red 
		
	mover_cima_red:
		sub $t1, $s1, 256	# endereço fantasma vermelho acima
	
		lw $t0, indicador_white_red
		beq $t0, 1, mover_cima_red_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, red_valido_mover_cima_black_black
		j red_nao_valido_mover_cima_black_black	
		red_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t1)
		sub $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 1
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, red_valido_mover_cima_black_white
		j red_nao_valido_mover_cima_black_white	
		red_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t1)
		sub $s1, $s1, 256
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 1
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, red_valido_mover_cima_white_black
		j red_nao_valido_mover_cima_white_black	
		red_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t1)
		sub $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 1
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_cima_white_black:
		
	mover_esquerda_red:
		sub $t2, $s1, 4		# endereço fantasma vermelho esquerda
		
		# portal esquerdo
		bne $s5, 2, nao_portal_esquerdo_red
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_red
		lw $a3, color_black
		sw $a3, 0($s1)
		addi $s1, $a0, 3952
		lw $a3, color_red
		sw $a3, 0($s1)
		sw $zero, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		nao_portal_esquerdo_red:
	
		lw $t0, indicador_white_red
		beq $t0, 1, mover_esquerda_red_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, red_valido_mover_esquerda_black_black
		j red_nao_valido_mover_esquerda_black_black	
		red_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t2)
		sub $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, red_valido_mover_esquerda_black_white
		j red_nao_valido_mover_esquerda_black_white	
		red_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t2)
		sub $s1, $s1, 4
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, red_valido_mover_esquerda_white_black
		j red_nao_valido_mover_esquerda_white_black	
		red_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t2)
		sub $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_red:
		addi $t3, $s1, 256	# endereço fantasma vermelho abaixo

		lw $t0, indicador_white_red
		beq $t0, 1, mover_baixo_red_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, red_valido_mover_baixo_black_black
		j red_nao_valido_mover_baixo_black_black	
		red_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t3)
		addi $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 3
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, red_valido_mover_baixo_black_white
		j red_nao_valido_mover_baixo_black_white	
		red_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t3)
		addi $s1, $s1, 256
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 3
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, red_valido_mover_baixo_white_black
		j red_nao_valido_mover_baixo_white_black	
		red_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t3)
		addi $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 3
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_baixo_white_black:
		
	mover_direita_red:
		addi $t4, $s1, 4	# endereço fantasma vermelho direita
		
		# portal direito
		bne $s5, 2, nao_portal_direito_red
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_red
		lw $a3, color_black
		sw $a3, 0($s1)
		addi $s1, $a0, 3848
		lw $a3, color_red
		sw $a3, 0($s1)
		sw $zero, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		nao_portal_direito_red:
	
		lw $t0, indicador_white_red
		beq $t0, 1, mover_direita_red_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, red_valido_mover_direita_black_black
		j red_nao_valido_mover_direita_black_black	
		red_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t4)
		addi $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, red_valido_mover_direita_black_white
		j red_nao_valido_mover_direita_black_white	
		red_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t4)
		addi $s1, $s1, 4
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, red_valido_mover_direita_white_black
		j red_nao_valido_mover_direita_white_black	
		red_valido_mover_direita_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t4)
		addi $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_direita_white_black:

	end_fantasma_red:
	
	sub $t1, $s1, 256
	sub $t2, $s1, 4
	addi $t3, $s1, 256
	addi $t4, $s1, 4
	
	beq $t1, $s0, colisao_red
	beq $t2, $s0, colisao_red
	beq $t3, $s0, colisao_red
	beq $t4, $s0, colisao_red
	li $v0, 0
	j end_colisao_red
	colisao_red:
	li $v0, 1
	end_colisao_red:
jr $ra
	
movimentar_fantasma_laranja:
	li $t9, 0
	li $t0, 0 # conta a quantidade de movimentos válidos
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s2, 256	# endereço fantasma orange acima
	sub $t2, $s2, 4		# endereço fantasma orange esquerda
	addi $t3, $s2, 256	# endereço fantasma orange abaixo
	addi $t4, $s2, 4	# endereço fantasma orange direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_orange # parede acima
	lw $a3, color_red
	beq $a3, $a2, invalido_cima_orange # fantasma vermelho acima
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_cima_orange # fantasma azul acima
	lw $a3, color_pink	
	beq $a3, $a2, invalido_cima_orange # fantasma rosa acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1
	invalido_cima_orange:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_orange # parede a esquerda
	lw $a3, color_red
	beq $a3, $a2, invalido_esquerda_orange # fantasma vermelho a esquerda
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_esquerda_orange # fantasma azul a esquerda
	lw $a3, color_pink	
	beq $a3, $a2, invalido_esquerda_orange # fantasma rosa a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_orange:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_orange # parede abaixo
	lw $a3, color_red
	beq $a3, $a2, invalido_baixo_orange # fantasma vermelho abaixo
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_baixo_orange # fantasma azul abaixo
	lw $a3, color_pink	
	beq $a3, $a2, invalido_baixo_orange # fantasma rosa abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_orange:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_orange # parede a direita
	lw $a3, color_red
	beq $a3, $a2, invalido_direita_orange # fantasma vermelho a direita
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_direita_orange # fantasma azul a direita
	lw $a3, color_pink	
	beq $a3, $a2, invalido_direita_orange # fantasma rosa a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_orange:
	
	### 2º parte, segue para os calculos de movimentação ###
	beq $t0, 0, nenhum_movimento_possivel_orange
	beq $t0, 1, um_movimento_possivel_orange
	beq $t0, 2, dois_movimentos_possiveis_orange
	beq $t0, 3, tres_movimentos_possiveis_orange
	beq $t0, 4, quatro_movimentos_possiveis_orange
	
	# permanece na mesma posição
	nenhum_movimento_possivel_orange: 
	j end_fantasma_orange
	
	# calcula qual a direção e se movimento nela
	um_movimento_possivel_orange:
		beq $t9, 1, mover_cima_orange
		beq $t9, 2, mover_esquerda_orange
		beq $t9, 3, mover_baixo_orange
		beq $t9, 5, mover_direita_orange
	
	dois_movimentos_possiveis_orange:
		lw $t0, ultima_direcao_orange
		beq $t9, 7, dois_direita_esquerda_orange
		beq $t9, 4, dois_cima_baixo_orange
		beq $t9, 3, dois_cima_esquerda_orange
		beq $t9, 6, dois_cima_direita_orange
		beq $t9, 5, dois_baixo_esquerda_orange
		beq $t9, 8, dois_baixo_direita_orange
		
		dois_direita_esquerda_orange: # 7
			beq $t0, 2, mover_esquerda_orange
			beq $t0, 5, mover_direita_orange
			
		dois_cima_baixo_orange: # 4
			beq $t0, 1, mover_cima_orange
			beq $t0, 3, mover_baixo_orange
			
		dois_cima_esquerda_orange: # 3
			beq $t0, 5, mover_cima_orange
			beq $t0, 3, mover_esquerda_orange
			
		dois_cima_direita_orange: # 6
			beq $t0, 2, mover_cima_orange
			beq $t0, 3, mover_direita_orange
			
		dois_baixo_esquerda_orange: # 5
			beq $t0, 5, mover_baixo_orange
			beq $t0, 1, mover_esquerda_orange
			
		dois_baixo_direita_orange: # 8
			beq $t0, 2, mover_baixo_orange
			beq $t0, 1, mover_direita_orange
			
	tres_movimentos_possiveis_orange:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do orange ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do orange ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do orange ghost
		move $t4, $v1 # coluna do orange ghost
		
		beq $t1, $t3, tres_mesma_linha_orange
		beq $t2, $t4, tres_mesma_coluna_orange
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		j tres_sem_perseguicao_orange
		
		tres_mesma_linha_orange:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_orange
			lw $t0, 0xffff0004
			beq $t0, 97, mover_esquerda_orange # a
			beq $t0, 100, mover_direita_orange # d
		
		tres_mesma_coluna_orange:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_orange
			lw $t0, 0xffff0004
			beq $t0, 119, mover_cima_orange # w
			beq $t0, 115, mover_baixo_orange # s
		
		tres_sem_perseguicao_orange:
		
	
		lw $t0, 0xffff0004 	# ultimo movimento do pac man 
		li $v0, 42
		li $a1, 2
		syscall			# valor randomico
		lw $t5, ultima_direcao_orange
		beq $t9, 8,  direita_cima_esquerda_orange
	 	beq $t9, 6,  cima_esquerda_baixo_orange
	 	beq $t9, 10, esquerda_baixo_direita_orange
	 	beq $t9, 9,  baixo_direita_cima_orange
	 	
	 	direita_cima_esquerda_orange: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 116, decisao_direita_cima_esquerda_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 6, cima_esquerda_orange
	 		beq $t9, 5, direita_esquerda_orange
	 		beq $t9, 3, cima_direita_orange
	 		decisao_direita_cima_esquerda_orange:
	 		beq $t0, 119, mover_cima_orange
	 		beq $t0, 97, mover_esquerda_orange
	 		beq $t0, 100, mover_direita_orange
	 		
	 	cima_esquerda_baixo_orange: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 100, decisao_cima_esquerda_baixo_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 5, cima_esquerda_orange
	 		beq $t9, 1, cima_baixo_orange
	 		beq $t9, 3, baixo_esquerda_orange
	 		decisao_cima_esquerda_baixo_orange:
	 		beq $t0, 119, mover_cima_orange
	 		beq $t0, 97, mover_esquerda_orange
	 		beq $t0, 116, mover_baixo_orange
	 		
	 	esquerda_baixo_direita_orange:
	 		bne $t0, 119, decisao_esquerda_baixo_direita_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, baixo_esquerda_orange
	 		beq $t9, 9, direita_esquerda_orange
	 		beq $t9, 5, baixo_direita_orange
	 		decisao_esquerda_baixo_direita_orange:
	 		beq $t0, 97, mover_esquerda_orange
	 		beq $t0, 116, mover_baixo_orange
	 		beq $t0, 100, mover_direita_orange
	 		
	 	baixo_direita_cima_orange:
	 		bne $t0, 97, decisao_baixo_direita_cima_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, cima_direita_orange
	 		beq $t9, 7, cima_baixo_orange
	 		beq $t9, 6, baixo_direita_orange
	 		decisao_baixo_direita_cima_orange:
	 		beq $t0, 116, mover_baixo_orange
	 		beq $t0, 100, mover_direita_orange
	 		beq $t0, 119, mover_cima_orange
	 	
	 	cima_baixo_orange:
	 		beq $a0, 0, mover_cima_orange
	 		beq $a0, 1, mover_baixo_orange
	 	
	 	direita_esquerda_orange:
	 		beq $a0, 0, mover_direita_orange
	 		beq $a0, 1, mover_esquerda_orange
	 	
	 	cima_esquerda_orange:
	 		beq $a0, 0, mover_cima_orange
	 		beq $a0, 1, mover_esquerda_orange
	 	
	 	cima_direita_orange:
	 		beq $a0, 0, mover_cima_orange
	 		beq $a0, 1, mover_direita_orange
	 	
	 	baixo_esquerda_orange:
	 		beq $a0, 0, mover_baixo_orange
	 		beq $a0, 1, mover_esquerda_orange
	 	
	 	baixo_direita_orange:
	 		beq $a0, 0, mover_baixo_orange
	 		beq $a0, 1, mover_direita_orange

	quatro_movimentos_possiveis_orange:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do orange ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do orange ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do orange ghost
		move $t4, $v1 # coluna do orange ghost
		
		beq $t1, $t3, quatro_mesma_linha_orange
		beq $t2, $t4, quatro_mesma_coluna_orange
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		j quatro_sem_perseguicao_orange
		
		quatro_mesma_linha_orange:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, quatro_sem_perseguicao_orange
			lw $t0, 0xffff0004
			beq $t0, 97, mover_esquerda_orange # a
			beq $t0, 100, mover_direita_orange # d
		
		quatro_mesma_coluna_orange:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, quatro_sem_perseguicao_orange
			lw $t0, 0xffff0004
			beq $t0, 119, mover_cima_orange # w
			beq $t0, 115, mover_baixo_orange # s
		
		quatro_sem_perseguicao_orange:
		
		lw $t0, 0xffff0004
		beq $t0, 119, mover_cima_orange # w
		beq $t0, 97, mover_esquerda_orange # a
		beq $t0, 116 mover_baixo_orange # s
		beq $t0, 100 mover_direita_orange # d
		
	mover_cima_orange:
		sub $t1, $s2, 256	# endereço fantasma orange acima
	
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_cima_orange_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, orange_valido_mover_cima_black_black
		j orange_nao_valido_mover_cima_black_black	
		orange_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t1)
		sub $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 1
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, orange_valido_mover_cima_black_white
		j orange_nao_valido_mover_cima_black_white	
		orange_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t1)
		sub $s2, $s2, 256
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 1
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, orange_valido_mover_cima_white_black
		j orange_nao_valido_mover_cima_white_black	
		orange_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t1)
		sub $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 1
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_cima_white_black:
		
	mover_esquerda_orange:
		sub $t2, $s2, 4		# endereço fantasma orange esquerd
	
		# portal esquerdo
		bne $s5, 2, nao_portal_esquerdo_orange
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_orange
		lw $a3, color_black
		sw $a3, 0($s2)
		addi $s2, $a0, 3952
		lw $a3, color_orange
		sw $a3, 0($s2)
		sw $zero, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		nao_portal_esquerdo_orange:
	
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_esquerda_orange_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, orange_valido_mover_esquerda_black_black
		j orange_nao_valido_mover_esquerda_black_black	
		orange_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t2)
		sub $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, orange_valido_mover_esquerda_black_white
		j orange_nao_valido_mover_esquerda_black_white	
		orange_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t2)
		sub $s2, $s2, 4
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, orange_valido_mover_esquerda_white_black
		j orange_nao_valido_mover_esquerda_white_black	
		orange_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t2)
		sub $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_orange:
		addi $t3, $s2, 256	# endereço fantasma orange abaixo
		
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_baixo_orange_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, orange_valido_mover_baixo_black_black
		j orange_nao_valido_mover_baixo_black_black	
		orange_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t3)
		addi $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 3
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, orange_valido_mover_baixo_black_white
		j orange_nao_valido_mover_baixo_black_white	
		orange_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t3)
		addi $s2, $s2, 256
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 3
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, orange_valido_mover_baixo_white_black
		j orange_nao_valido_mover_baixo_white_black	
		orange_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t3)
		addi $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 3
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_baixo_white_black:
		
	mover_direita_orange:
		addi $t4, $s2, 4	# endereço fantasma orange direita
	
		# portal direito
		bne $s5, 2, nao_portal_direito_orange
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_orange
		lw $a3, color_black
		sw $a3, 0($s2)
		addi $s2, $a0, 3848
		lw $a3, color_orange
		sw $a3, 0($s2)
		sw $zero, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		nao_portal_direito_orange:
	
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_direita_orange_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, orange_valido_mover_direita_black_black
		j orange_nao_valido_mover_direita_black_black	
		orange_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t4)
		addi $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, orange_valido_mover_direita_black_white
		j orange_nao_valido_mover_direita_black_white	
		orange_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t4)
		addi $s2, $s2, 4
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, orange_valido_mover_direita_white_black
		j orange_nao_valido_mover_direita_white_black	
		orange_valido_mover_direita_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t4)
		addi $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_direita_white_black:

	end_fantasma_orange:
	
	sub $t1, $s2, 256
	sub $t2, $s2, 4
	addi $t3, $s2, 256
	addi $t4, $s2, 4
	
	beq $t1, $s0, colisao_orange
	beq $t2, $s0, colisao_orange
	beq $t3, $s0, colisao_orange
	beq $t4, $s0, colisao_orange
	li $v0, 0
	j end_colisao_orange
	colisao_orange:
	li $v0, 1
	end_colisao_orange:
jr $ra
	
	
movimentar_fantasma_ciano:
	li $t9, 0
	li $t0, 0 # conta a quantidade de movimentos válidos
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s3, 256	# endereço fantasma ciano acima
	sub $t2, $s3, 4		# endereço fantasma ciano esquerda
	addi $t3, $s3, 256	# endereço fantasma ciano abaixo
	addi $t4, $s3, 4	# endereço fantasma ciano direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_blue # parede acima
	lw $a3, color_red
	beq $a3, $a2, invalido_cima_blue # fantasma vermelho acima
	lw $a3, color_orange
	beq $a3, $a2, invalido_cima_blue # fantasma laranja acima
	lw $a3, color_pink	
	beq $a3, $a2, invalido_cima_blue # fantasma rosa acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1
	invalido_cima_blue:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_blue # parede a esquerda
	lw $a3, color_red
	beq $a3, $a2, invalido_esquerda_blue # fantasma vermelho a esquerda
	lw $a3, color_orange	
	beq $a3, $a2, invalido_esquerda_blue # fantasma laranja a esquerda
	lw $a3, color_pink	
	beq $a3, $a2, invalido_esquerda_blue # fantasma rosa a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_blue:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_blue # parede abaixo
	lw $a3, color_red
	beq $a3, $a2, invalido_baixo_blue # fantasma vermelho abaixo
	lw $a3, color_orange	
	beq $a3, $a2, invalido_baixo_blue # fantasma laranja abaixo
	lw $a3, color_pink	
	beq $a3, $a2, invalido_baixo_blue # fantasma rosa abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_blue:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_blue # parede a direita
	lw $a3, color_red
	beq $a3, $a2, invalido_direita_blue # fantasma vermelho a direita
	lw $a3, color_orange	
	beq $a3, $a2, invalido_direita_blue # fantasma laranja a direita
	lw $a3, color_pink	
	beq $a3, $a2, invalido_direita_blue # fantasma rosa a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_blue:
	
	### 2º parte, segue para os calculos de movimentação ###
	beq $t0, 0, nenhum_movimento_possivel_ciano
	beq $t0, 1, um_movimento_possivel_ciano
	beq $t0, 2, dois_movimentos_possiveis_ciano
	beq $t0, 3, tres_movimentos_possiveis_ciano
	beq $t0, 4, quatro_movimentos_possiveis_ciano
	
	# permanece na mesma posição
	nenhum_movimento_possivel_ciano: 
	j end_fantasma_ciano
	
	# calcula qual a direção e se movimento nela
	um_movimento_possivel_ciano:
		beq $t9, 1, mover_cima_ciano
		beq $t9, 2, mover_esquerda_ciano
		beq $t9, 3, mover_baixo_ciano
		beq $t9, 5, mover_direita_ciano
	
	dois_movimentos_possiveis_ciano:
		lw $t0, ultima_direcao_ciano
		beq $t9, 7, dois_direita_esquerda_ciano
		beq $t9, 4, dois_cima_baixo_ciano
		beq $t9, 3, dois_cima_esquerda_ciano
		beq $t9, 6, dois_cima_direita_ciano
		beq $t9, 5, dois_baixo_esquerda_ciano
		beq $t9, 8, dois_baixo_direita_ciano
		
		dois_direita_esquerda_ciano: # 7
			beq $t0, 2, mover_esquerda_ciano
			beq $t0, 5, mover_direita_ciano
			
		dois_cima_baixo_ciano: # 4
			beq $t0, 1, mover_cima_ciano
			beq $t0, 3, mover_baixo_ciano
			
		dois_cima_esquerda_ciano: # 3
			beq $t0, 5, mover_cima_ciano
			beq $t0, 3, mover_esquerda_ciano
			
		dois_cima_direita_ciano: # 6
			beq $t0, 2, mover_cima_ciano
			beq $t0, 3, mover_direita_ciano
			
		dois_baixo_esquerda_ciano: # 5
			beq $t0, 5, mover_baixo_ciano
			beq $t0, 1, mover_esquerda_ciano
			
		dois_baixo_direita_ciano: # 8
			beq $t0, 2, mover_baixo_ciano
			beq $t0, 1, mover_direita_ciano
			
	tres_movimentos_possiveis_ciano:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do ciano ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do ciano ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do ciano ghost
		move $t4, $v1 # coluna do ciano ghost
		
		beq $t1, $t3, tres_mesma_linha_ciano
		beq $t2, $t4, tres_mesma_coluna_ciano
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		j tres_sem_perseguicao_ciano
		
		tres_mesma_linha_ciano:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_ciano
			lw $t0, 0xffff0004
			beq $t0, 97, mover_esquerda_ciano # a
			beq $t0, 100, mover_direita_ciano # d
		
		tres_mesma_coluna_ciano:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_ciano
			lw $t0, 0xffff0004
			beq $t0, 119, mover_cima_ciano # w
			beq $t0, 115, mover_baixo_ciano # s
		
		tres_sem_perseguicao_ciano:
		
		li $v0, 42 # 1 - fica corajoso e persegue o pac man
		li $a1, 2  # 0 - fica assustado e foge do pac man
		syscall
		move $t9, $a0
	
		lw $t0, 0xffff0004 	# ultimo movimento do pac man 
		li $v0, 42
		li $a1, 2
		syscall			# valor randomico
		lw $t5, ultima_direcao_ciano
		beq $t9, 8,  direita_cima_esquerda_ciano
	 	beq $t9, 6,  cima_esquerda_baixo_ciano
	 	beq $t9, 10, esquerda_baixo_direita_ciano
	 	beq $t9, 9,  baixo_direita_cima_ciano
	 	
	 	direita_cima_esquerda_ciano: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 116, decisao_direita_cima_esquerda_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 6, cima_esquerda_ciano
	 		beq $t9, 5, direita_esquerda_ciano
	 		beq $t9, 3, cima_direita_ciano
	 		decisao_direita_cima_esquerda_ciano:
	 		beq $t0, 119, mover_cima_ciano
	 		beq $t0, 97, mover_esquerda_ciano
	 		beq $t0, 100, mover_direita_ciano
	 		
	 	cima_esquerda_baixo_ciano: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 100, decisao_cima_esquerda_baixo_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 5, cima_esquerda_ciano
	 		beq $t9, 1, cima_baixo_ciano
	 		beq $t9, 3, baixo_esquerda_ciano
	 		decisao_cima_esquerda_baixo_ciano:
	 		beq $t0, 119, mover_cima_ciano
	 		beq $t0, 97, mover_esquerda_ciano
	 		beq $t0, 116, mover_baixo_ciano
	 		
	 	esquerda_baixo_direita_ciano:
	 		bne $t0, 119, decisao_esquerda_baixo_direita_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, baixo_esquerda_ciano
	 		beq $t9, 9, direita_esquerda_ciano
	 		beq $t9, 5, baixo_direita_ciano
	 		decisao_esquerda_baixo_direita_ciano:
	 		beq $t0, 97, mover_esquerda_ciano
	 		beq $t0, 116, mover_baixo_ciano
	 		beq $t0, 100, mover_direita_ciano
	 		
	 	baixo_direita_cima_ciano:
	 		bne $t0, 97, decisao_baixo_direita_cima_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, cima_direita_ciano
	 		beq $t9, 7, cima_baixo_ciano
	 		beq $t9, 6, baixo_direita_ciano
	 		decisao_baixo_direita_cima_ciano:
	 		beq $t0, 116, mover_baixo_ciano
	 		beq $t0, 100, mover_direita_ciano
	 		beq $t0, 119, mover_cima_ciano
	 	
	 	cima_baixo_ciano:
	 		beq $a0, 0, mover_cima_ciano
	 		beq $a0, 1, mover_baixo_ciano
	 	
	 	direita_esquerda_ciano:
	 		beq $a0, 0, mover_direita_ciano
	 		beq $a0, 1, mover_esquerda_ciano
	 	
	 	cima_esquerda_ciano:
	 		beq $a0, 0, mover_cima_ciano
	 		beq $a0, 1, mover_esquerda_ciano
	 	
	 	cima_direita_ciano:
	 		beq $a0, 0, mover_cima_ciano
	 		beq $a0, 1, mover_direita_ciano
	 	
	 	baixo_esquerda_ciano:
	 		beq $a0, 0, mover_baixo_ciano
	 		beq $a0, 1, mover_esquerda_ciano
	 	
	 	baixo_direita_ciano:
	 		beq $a0, 0, mover_baixo_ciano
	 		beq $a0, 1, mover_direita_ciano
	 		
	quatro_movimentos_possiveis_ciano:
	li $v0, 42 # 1 - fica corajoso e persegue o pac man
	li $a1, 2  # 0 - fica assustado e foge do pac man
	syscall
	move $t9, $a0
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do ciano ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do ciano ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do ciano ghost
		move $t4, $v1 # coluna do ciano ghost
		
		# pac man - ($t1,$t2), ciano ghost - ($t3,$t4)
		move $a0, $t3	# x do fantasma
		move $a1, $t4	# y do fantasma
		
		# se eles estiverem na mesma linha ou coluna
		beq $t1, $t3, mesma_linha_ciano
		beq $t2, $t4, mesma_coluna_ciano

		#determinar o quadrante que o pac man está em relação ao ciano ghost
		bgt $t3, $t1, quadrante_esquerda_ciano 
		j quadrante_direita_ciano
		
		quadrante_esquerda_ciano:
			blt $t4, $t1, quadrante_cima_esquerda_ciano
			j quadrante_baixo_esquerda_ciano
			
		quadrante_direita_ciano:
			blt $t4, $t1, quadrante_cima_direita_ciano
			j quadrante_baixo_direita_ciano
		
		# efetua a lógica dos movimentos
		quadrante_cima_esquerda_ciano:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_esquerda_ciano # ir para cima
			
			# indica se o fantasma está corajoso ou assustado
			beq $t9, 1, corajoso_cima_esquerda_ciano
			j assustado_cima_esquerda_ciano
			
			corajoso_cima_esquerda_ciano:
			bgt $v1, $v0, mover_cima_ciano
			j mover_esquerda_ciano
			
			assustado_cima_esquerda_ciano:
			bgt $v1, $v0, mover_esquerda_ciano
			j mover_cima_ciano
			
		quadrante_baixo_esquerda_ciano:
			move $a2, $t1
			move $a3, $t4 
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_esquerda_ciano
			
			# indica se o fantasma está corajoso ou assustado
			beq $t9, 1, corajoso_baixo_esquerda_ciano
			j assustado_baixo_esquerda_ciano
			
			corajoso_baixo_esquerda_ciano:
			bgt $v1, $v0, mover_baixo_ciano
			j mover_esquerda_ciano
			
			assustado_baixo_esquerda_ciano:
			bgt $v1, $v0, mover_esquerda_ciano
			j mover_baixo_ciano
			
		quadrante_cima_direita_ciano:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_direita_ciano
			
			# indica se o fantasma está corajoso ou assustado
			beq $t9, 1, corajoso_cima_direita_ciano
			j assustado_cima_direita_ciano
			
			corajoso_cima_direita_ciano:
			bgt $v1, $v0, mover_cima_ciano
			j mover_direita_ciano
			
			assustado_cima_direita_ciano:
			bgt $v1, $v0, mover_direita_ciano
			j mover_cima_ciano
			
		quadrante_baixo_direita_ciano:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_direita_ciano
			
			# indica se o fantasma está corajoso ou assustado
			beq $t9, 1, corajoso_baixo_direita_ciano
			j assustado_baixo_direita_ciano
			
			corajoso_baixo_direita_ciano:
			bgt $v1, $v0, mover_baixo_ciano
			j mover_direita_ciano
			
			assustado_baixo_direita_ciano:
			bgt $v1, $v0, mover_direita_ciano
			j mover_baixo_ciano
			
		randomico_cima_esquerda_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_ciano
			j  mover_esquerda_ciano
			
		randomico_baixo_esquerda_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_ciano
			j  mover_esquerda_ciano
			
		randomico_cima_direita_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_ciano
			j  mover_direita_ciano
			
		randomico_baixo_direita_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_ciano
			j  mover_direita_ciano
			
		mesma_linha_ciano:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			
			beq $t9, 1, corajoso_mesma_linha_ciano
			j assustado_mesma_linha_ciano
			
			corajoso_mesma_linha_ciano:
			blt $t3, $t1, mover_direita_ciano # pac man a direita - vá para direita
			j mover_esquerda_ciano # senão vá para esquerda
			
			assustado_mesma_linha_ciano:
			blt $t3, $t1, mover_esquerda_ciano # pac man a direita - vá para direita
			j mover_direita_ciano # senão vá para esquerda
			
		mesma_coluna_ciano:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			
			beq $t9, 1, corajoso_mesma_coluna_ciano
			j assustado_mesma_coluna_ciano
			
			corajoso_mesma_coluna_ciano:
			blt $t4, $t2, mover_cima_ciano
			j mover_baixo_ciano
			
			assustado_mesma_coluna_ciano:
			blt $t4, $t2, mover_baixo_ciano
			j mover_cima_ciano
			
	mover_cima_ciano:
		sub $t1, $s3, 256	# endereço fantasma ciano acima
		
		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_cima_ciano_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, ciano_valido_mover_cima_black_black
		j ciano_nao_valido_mover_cima_black_black	
		ciano_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t1)
		sub $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 1
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, ciano_valido_mover_cima_black_white
		j ciano_nao_valido_mover_cima_black_white	
		ciano_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t1)
		sub $s3, $s3, 256
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 1
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, ciano_valido_mover_cima_white_black
		j ciano_nao_valido_mover_cima_white_black	
		ciano_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t1)
		sub $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 1
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_cima_white_black:
		
	mover_esquerda_ciano:
		sub $t2, $s3, 4		# endereço fantasma ciano esquerda

		# portal esquerdo
		bne $s5, 2, nao_portal_esquerdo_ciano
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_ciano
		lw $a3, color_black
		sw $a3, 0($s3)
		addi $s3, $a0, 3952
		lw $a3, color_ciano
		sw $a3, 0($s3)
		sw $zero, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		nao_portal_esquerdo_ciano:
	
		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_esquerda_ciano_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, ciano_valido_mover_esquerda_black_black
		j ciano_nao_valido_mover_esquerda_black_black	
		ciano_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t2)
		sub $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, ciano_valido_mover_esquerda_black_white
		j ciano_nao_valido_mover_esquerda_black_white	
		ciano_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t2)
		sub $s3, $s3, 4
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, ciano_valido_mover_esquerda_white_black
		j ciano_nao_valido_mover_esquerda_white_black	
		ciano_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t2)
		sub $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_ciano:
		addi $t3, $s3, 256	# endereço fantasma ciano abaixo

		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_baixo_ciano_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, ciano_valido_mover_baixo_black_black
		j ciano_nao_valido_mover_baixo_black_black	
		ciano_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t3)
		addi $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 3
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, ciano_valido_mover_baixo_black_white
		j ciano_nao_valido_mover_baixo_black_white	
		ciano_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t3)
		addi $s3, $s3, 256
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 3
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, ciano_valido_mover_baixo_white_black
		j ciano_nao_valido_mover_baixo_white_black	
		ciano_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t3)
		addi $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 3
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_baixo_white_black:
		
	mover_direita_ciano:
		addi $t4, $s3, 4	# endereço fantasma ciano direita
		
		# portal direito
		bne $s5, 2, nao_portal_direito_ciano
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_ciano
		lw $a3, color_black
		sw $a3, 0($s3)
		addi $s3, $a0, 3848
		lw $a3, color_ciano
		sw $a3, 0($s3)
		sw $zero, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		nao_portal_direito_ciano:
	
		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_direita_ciano_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, ciano_valido_mover_direita_black_black
		j ciano_nao_valido_mover_direita_black_black	
		ciano_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t4)
		addi $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, ciano_valido_mover_direita_black_white
		j ciano_nao_valido_mover_direita_black_white	
		ciano_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t4)
		addi $s3, $s3, 4
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, ciano_valido_mover_direita_white_black
		j ciano_nao_valido_mover_direita_white_black	
		ciano_valido_mover_direita_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t4)
		addi $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_direita_white_black:

	end_fantasma_ciano:
	sub $t1, $s3, 256
	sub $t2, $s3, 4
	addi $t3, $s3, 256
	addi $t4, $s3, 4
	
	beq $t1, $s0, colisao_ciano
	beq $t2, $s0, colisao_ciano
	beq $t3, $s0, colisao_ciano
	beq $t4, $s0, colisao_ciano
	li $v0, 0
	j end_colisao_ciano
	colisao_ciano:
	li $v0, 1
	end_colisao_ciano:
jr $ra	
	
movimentar_fantasma_rosa:
	li $t0, 0 # conta a quantidade de movimentos válidos
	li $t9, 0 # lógica para determinar o sentido do movimento de várias direções
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s4, 256	# endereço fantasma rosa acima
	sub $t2, $s4, 4		# endereço fantasma rosa esquerda
	addi $t3, $s4, 256	# endereço fantasma rosa abaixo
	addi $t4, $s4, 4	# endereço fantasma rosa direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_pink # parede acima
	lw $a3, color_red
	beq $a3, $a2, invalido_cima_pink # fantasma vermelho acima
	lw $a3, color_orange
	beq $a3, $a2, invalido_cima_pink # fantasma laranja acima
	lw $a3, color_ciano
	beq $a3, $a2, invalido_cima_pink # fantasma ciano acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1 
	invalido_cima_pink:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_pink # parede a esquerda
	lw $a3, color_red
	beq $a3, $a2, invalido_esquerda_pink # fantasma vermelho a esquerda
	lw $a3, color_orange	
	beq $a3, $a2, invalido_esquerda_pink # fantasma laranja a esquerda
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_esquerda_pink # fantasma ciano a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_pink:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_pink # parede abaixo
	lw $a3, color_red
	beq $a3, $a2, invalido_baixo_pink # fantasma vermelho abaixo
	lw $a3, color_orange	
	beq $a3, $a2, invalido_baixo_pink # fantasma laranja abaixo
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_baixo_pink # fantasma ciano abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_pink:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_pink # parede a direita
	lw $a3, color_red
	beq $a3, $a2, invalido_direita_pink # fantasma vermelho a direita
	lw $a3, color_orange	
	beq $a3, $a2, invalido_direita_pink # fantasma laranja a direita
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_direita_pink # fantasma ciano a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_pink:
	
	### 2º parte, segue para os calculos de movimentação ###
	beq $t0, 0, nenhum_movimento_possivel_rosa
	beq $t0, 1, um_movimento_possivel_rosa
	beq $t0, 2, dois_movimentos_possiveis_rosa
	beq $t0, 3, tres_movimentos_possiveis_rosa
	beq $t0, 4, quatro_movimentos_possiveis_rosa
	
	# permanece na mesma posição
	nenhum_movimento_possivel_rosa: 
	j end_fantasma_rosa
	
	# calcula qual a direção e se movimento nela
	um_movimento_possivel_rosa:
		beq $t9, 1, mover_cima_rosa
		beq $t9, 2, mover_esquerda_rosa
		beq $t9, 3, mover_baixo_rosa
		beq $t9, 5, mover_direita_rosa
	
	dois_movimentos_possiveis_rosa:
		lw $t0, ultima_direcao_pink
		beq $t9, 7, dois_direita_esquerda_rosa
		beq $t9, 4, dois_cima_baixo_rosa
		beq $t9, 3, dois_cima_esquerda_rosa
		beq $t9, 6, dois_cima_direita_rosa
		beq $t9, 5, dois_baixo_esquerda_rosa
		beq $t9, 8, dois_baixo_direita_rosa
		
		dois_direita_esquerda_rosa: # 7
			beq $t0, 2, mover_esquerda_rosa
			beq $t0, 5, mover_direita_rosa
			
		dois_cima_baixo_rosa: # 4
			beq $t0, 1, mover_cima_rosa
			beq $t0, 3, mover_baixo_rosa
			
		dois_cima_esquerda_rosa: # 3
			beq $t0, 5, mover_cima_rosa
			beq $t0, 3, mover_esquerda_rosa
			
		dois_cima_direita_rosa: # 6
			beq $t0, 2, mover_cima_rosa
			beq $t0, 3, mover_direita_rosa
			
		dois_baixo_esquerda_rosa: # 5
			beq $t0, 5, mover_baixo_rosa
			beq $t0, 1, mover_esquerda_rosa
			
		dois_baixo_direita_rosa: # 8
			beq $t0, 2, mover_baixo_rosa
			beq $t0, 1, mover_direita_rosa
			
	tres_movimentos_possiveis_rosa:
		# gerando o numero aleatorio em $a0
		li $v0, 42
		li $a1, 3
		syscall
	 	
	 	lw $t0, ultima_direcao_pink
	 	beq $t9, 8,  direita_cima_esquerda_rosa
	 	beq $t9, 6,  cima_esquerda_baixo_rosa
	 	beq $t9, 10, esquerda_baixo_direita_rosa
	 	beq $t9, 9,  baixo_direita_cima_rosa
	 	
	 	direita_cima_esquerda_rosa:# 8
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, cima_esquerda_rosa
	 		beq $t9, 5, esquerda_direita_rosa
	 		beq $t9, 2, cima_direita_rosa
	 		
	 	cima_esquerda_baixo_rosa: # 6
	 		sub $t9, $t9, $t0
	 		beq $t9, 3, baixo_esquerda_rosa
	 		beq $t9, 1, cima_baixo_rosa
	 		beq $t9, 5, cima_esquerda_rosa
	 		
	 	esquerda_baixo_direita_rosa: # 10
	 		sub $t9, $t9, $t0
	 		beq $t9, 8, baixo_esquerda_rosa
	 		beq $t9, 9, esquerda_direita_rosa
	 		beq $t9, 5, baixo_direita_rosa
	 		
	 	baixo_direita_cima_rosa: # 9
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, baixo_direita_rosa
	 		beq $t9, 7, cima_baixo_rosa
	 		beq $t9, 8, cima_direita_rosa
	 		
	 	esquerda_direita_rosa:
	 		beq $a0, 0, mover_esquerda_rosa
	 		beq $a0, 1, mover_direita_rosa
	 	
	 	cima_baixo_rosa:
			beq $a0, 0, mover_cima_rosa
	 		beq $a0, 1, mover_baixo_rosa
	 		
		cima_esquerda_rosa:
			beq $a0, 0, mover_esquerda_rosa
	 		beq $a0, 1, mover_cima_rosa
	 		
		cima_direita_rosa:
			beq $a0, 0, mover_cima_rosa
	 		beq $a0, 1, mover_direita_rosa
	 		
	 	baixo_esquerda_rosa:
	 		beq $a0, 0, mover_esquerda_rosa
	 		beq $a0, 1, mover_baixo_rosa
	 	
	 	baixo_direita_rosa:
			beq $a0, 0, mover_direita_rosa
	 		beq $a0, 1, mover_baixo_rosa

	quatro_movimentos_possiveis_rosa:
		# gerando o número aleatorio em $a0
		li $v0, 42
		li $a1, 3
		syscall
		
		lw $t0, ultima_direcao_pink
		sub $t9, $t9, $t0
		beq $t9, 10, quatro_direita_cima_esquerda_rosa
		beq $t9, 9,  quatro_cima_esquerda_baixo_rosa
		beq $t9, 8,  quatro_esquerda_baixo_direita_rosa
		beq $t9, 6,  quatro_baixo_direita_cima_rosa
		
		quatro_direita_cima_esquerda_rosa: # 10
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
		quatro_cima_esquerda_baixo_rosa: # 9
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
		quatro_esquerda_baixo_direita_rosa: # 8
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
		quatro_baixo_direita_cima_rosa: # 6
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
	mover_cima_rosa:
		sub $t1, $s4, 256	# endereço fantasma rosa acima
		
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_cima_rosa_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, rosa_valido_mover_cima_black_black
		j rosa_nao_valido_mover_cima_black_black	
		rosa_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t1)
		sub $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 1
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, rosa_valido_mover_cima_black_white
		j rosa_nao_valido_mover_cima_black_white	
		rosa_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t1)
		sub $s4, $s4, 256
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 1
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_rosa_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, rosa_valido_mover_cima_white_black
		j rosa_nao_valido_mover_cima_white_black	
		rosa_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t1)
		sub $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 1
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_cima_white_black:
		
	mover_esquerda_rosa:
		sub $t2, $s4, 4		# endereço fantasma rosa esquerda
		
		# portal esquerdo
		beq $s5, 1, nao_portal_esquerdo_rosa
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_rosa
		lw $a3, color_black
		sw $a3, 0($s4)
		addi $s4, $a0, 3952
		lw $a3, color_pink
		sw $a3, 0($s4)
		sw $zero, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		
		nao_portal_esquerdo_rosa:
		
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_esquerda_rosa_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, rosa_valido_mover_esquerda_black_black
		j rosa_nao_valido_mover_esquerda_black_black	
		rosa_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t2)
		sub $s4, $s4, 4
		sw $zero, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, rosa_valido_mover_esquerda_black_white
		j rosa_nao_valido_mover_esquerda_black_white	
		rosa_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t2)
		sub $s4, $s4, 4
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_rosa_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, rosa_valido_mover_esquerda_white_black
		j rosa_nao_valido_mover_esquerda_white_black	
		rosa_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t2)
		sub $s4, $s4, 4
		sw $zero, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_rosa:
		addi $t3, $s4, 256	# endereço fantasma rosa abaixo
	
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_baixo_rosa_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, rosa_valido_mover_baixo_black_black
		j rosa_nao_valido_mover_baixo_black_black	
		rosa_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t3)
		addi $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 3
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, rosa_valido_mover_baixo_black_white
		j rosa_nao_valido_mover_baixo_black_white	
		rosa_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t3)
		addi $s4, $s4, 256
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 3
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_rosa_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, rosa_valido_mover_baixo_white_black
		j rosa_nao_valido_mover_baixo_white_black	
		rosa_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t3)
		addi $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 3
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_baixo_white_black:
		
	mover_direita_rosa:
		addi $t4, $s4, 4	# endereço fantasma rosa direita
	
		# portal direito
		beq $s5, 1, nao_portal_direito_rosa
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_rosa
		lw $a3, color_black
		sw $a3, 0($s4)
		addi $s4, $a0, 3848
		lw $a3, color_pink
		sw $a3, 0($s4)
		sw $zero, indicador_white_pink
		li $t0, 5
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		nao_portal_direito_rosa:
	
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_direita_rosa_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, rosa_valido_mover_direita_black_black
		j rosa_nao_valido_mover_direita_black_black	
		rosa_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t4)
		addi $s4, $s4, 4
		sw $zero, indicador_white_pink
		li $t0, 5
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, rosa_valido_mover_direita_black_white
		j rosa_nao_valido_mover_direita_black_white	
		rosa_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t4)
		addi $s4, $s4, 4
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 5
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_rosa_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, rosa_valido_mover_direita_white_black
		j rosa_nao_valido_mover_direita_white_black	
		rosa_valido_mover_direita_white_black:
		lw $a3, color_white
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t4)
		addi $s4, $s4, 4
		sw $zero, indicador_white_pink
		li $t0, 5
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_direita_white_black:

	end_fantasma_rosa:
	
	sub $t1, $s4, 256
	sub $t2, $s4, 4
	addi $t3, $s4, 256
	addi $t4, $s4, 4
	
	beq $t1, $s0, colisao_pink
	beq $t2, $s0, colisao_pink
	beq $t3, $s0, colisao_pink
	beq $t4, $s0, colisao_pink
	li $v0, 0
	j end_colisao_pink
	colisao_pink:
	li $v0, 1
	end_colisao_pink:
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
	sub $a0, $a0, $a2 # a =(x1-x2)
	sub $a1, $a1, $a3 # b = (y1-y2)
	mul $a0, $a0, $a0 # a^2
	mul $a1, $a1, $a1 # b^2
	add $a0, $a0, $a1 # c = a^2 + b^2
	# raiz
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal integerSqrt # sqrt(c)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	# o retorno de integerSqrt já está em $v0
jr $ra

# $a0 - endereço no bit map
# $v0 - valor da linha
# $v1 - valor da coluna
calcular_coordenadas:
	la $a3, display_address
	sub $a0, $a0, $a3
	div $a1, $a0, 256 	# t1 é o valor da linha
	mul $a2, $a1, 256	
	sub $a2, $a0, $a2 
	div $a2, $a2, 4		# t2 é o valor da coluna
	move $v0, $a1
	move $v1, $a2
jr $ra

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
