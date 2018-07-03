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
color_blue_sky:		.word 0x0061fafc
color_orange:		.word 0x00fc9711

#		(Detalhes importantes)
# 	endereço topo dir:  0
#	endereço topo esq:  252
#	endereço baixo dir  7936
#	endereço baixo esq: 8188
#	mover p/ esquerda: address-4
#	mover p/ direita:  address+4
#	mover p/ cima:     address-256
#	mover p/ baixo:	   address-256

.text
.globl main
main:
	la $a0, display_address
	lw $a1, color_red
	sw $a1, 0($a0)
	sw $a1, 252($a0)
	sw $a1, 7936($a0)
	sw $a1, 8188($a0)
li $v0, 10
syscall