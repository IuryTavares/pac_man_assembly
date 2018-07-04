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
color_blue:		.word 0x001818ff
color_yellow:		.word 0x00fffe1d
color_red: 		.word 0x00df0902
color_pink:		.word 0x00fa9893
color_ciano:		.word 0x0061fafc
color_orange:		.word 0x00fc9711
color_black:		.word 0x00000000
color_white:		.word 0x00ffffff

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
