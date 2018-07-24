   	# float i, n;
   	# scanf("%f",&n);
   	# for(i=0.01 ; i*i<n ; i=i+0.01 );
   	# printf("%f  %i", i, a);
    	
    	#X = enderço atual
    	
    	# transformando um endereço numa posição matricial
    	#
	#divido X por 256, o quociente será a linha.
	#subtraio X pelo (quociente*256). terá Y como resultado
	#divido Y por 4, o quociente será o valor da coluna

	#distance = sqrt((x1-x2)^2+(y1-y2)^2)
    
.data
	float_aux: .float 0.01  
.text
	li $a0, 25
	jal sqrt
	li $v0, 2
	mov.s $f12, $f2
	syscall
li $v0, 10
syscall

# $a0, entrada
# $f3, saida
sqrt:
	lwc1 $f1, float_aux # $f1 sempre vale 0.01
	beqin_sqrt:
	mul.s $f4, $f2, $f2
	bge $f4, $a0, end_sqrt
	add.s $f2, $f2, $f1
	j begin_sqrt
	end_sqrt:
jr $ra
