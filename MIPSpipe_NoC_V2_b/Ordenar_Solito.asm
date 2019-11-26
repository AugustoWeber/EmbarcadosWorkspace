.text
main:


	la $t8, ARRAY_1500 #endereco do array
	addiu $t8,$t8,8
	
#------INSERTION SORT-----------------------------------------------------------
INSERTION_BEGIN:
	addiu      $t9, $zero,99              # t9 = size
	        	
   	# addiu $t8,$t8,8
   	
   	
   	
   	addiu $t7,$t8,4			#t7 = eleito array[1]
   	
for_loop:				#for size--
	beq $t9,$zero,END_INSERTION	
	subiu $t9,$t9,1
	
	subiu $t6,$t7,4
	lw $t5,0($t7) #eleito
while_loop:
	slt $t0,$t6,$t8
	addiu $t1,$zero,1
	beq $t0,$t1,end_while
	
	lw $t1,0($t6) #array[j]
	slt $t0,$t5,$t1
	beq $t0,$zero,end_while
	
	sw $t1,4($t6)
	subiu $t6,$t6,4
	j while_loop
		
	
	
end_while:	
	sw $t5,4($t6)
	addiu $t7,$t7,4
	j for_loop
	

#---------------------------FIM INSERTION SORT--------------------------------
END_INSERTION:

	
	addiu $t8,$t8,408

	j INSERTION_BEGIN

end: 
	j end 
	
	
	
.data 
	NUM_ENVIADOS:		.word 0
	ARRAYS_RECEBIDOS:	.word 0
	SEND_INDEX:		.word 0
	SLAVES: 		.word 15
	ARRAY_1500:		.word 0
				
	#HEADER		4
	#NUM_ARRAY 	4
	#array_elements	400

#RECEBER ARRAYS ORDENADOS:
#Pooling, Receber Header e NUM_ARRAY
#Configurar DMA
#Ativar DMA