.eqv ELEMENTOS_ARRAY 100 
.eqv ARRAY_SIZE 412
.eqv NUM_SLAVES 15
.eqv NUM_ARRAYS 15

.text
main:
	la $t9, ARRAY_1500
	#addiu $t9, $t9, 4	# ARRAY_1500 +1 word mem position 0x100101A8
	la $t0, NUM_PROC
	lw $t7, 0($t0)
	addiu $t7, $t7, 1
	
	
	
	#ENVIAR ARRAYS PARA OS N PROCESSADORES
	addiu $t6, $zero, 1
	
loop1:
	beq $t6, $t7, end_loop1	# Caso tenha enviado a todos os processadores disponiveis, sai do loop
	
	sw $t6, 4($t9)			# Grava o num do IP para enviar o array
#COMANDO PARA ENVIAR ARRAY

	lui $t0, 0x0800			# Endereco do TX
	
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria que contem as informações
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +


	addiu $t9, $t9, ARRAY_SIZE
	addiu $t6, $t6, 1		# t6++
	
	j loop1
end_loop1:
	
	addiu $t8, $t7, 0		# Recebe o send_INDEX
	addiu $t5, $zero, 0
	la $t4, RX_BUFF
	
LOOP2:						# Loop que recebe e envia arrays conforme os processadores retornam
							# Verificar se recebeu todos os arrays
	addiu $t0, $zero, 15
	beq $t0, $t5, END_LOOP2	# Se recebeu todos os arrays, pula para o fim
	
	
#CONFIGURAR, RECEBER E SALVAR NO BUFFER
	lui $t0, 0x0800			# Endereco do TX
	
	sw $t4, 8($t0)			# Grava no registrador RX o endereço da memoria que contem as informações
	addiu $t2, $zero, 8
	sw $t2, 0($t0)			# Grava 8 no registrador STATUS indicando para iniciar a transmissão... té +
	
	#GRAVAR DE VOLTA NO ARRAY_1500
#--------------------------ENVIAR ARRAY-------------------------------------------------------------------------------------------------
	
	addiu $t1, $zero, NUM_ARRAYS
	addiu $t1, $t1, 1
	beq $t8, $t1, loop2_continue	# Caso tenha enviado todos os arrays, pula para loop2_continue

		lw  $t6, 4($t4)		# Pega o ip recebido no buffer para enviar proximo array	
	
	lui $t0, 0x0000			# Pega os ultimos 2 bytes do header 
	ori $t0, 0x1111
	and $t6, $t6, $t0
	
	sw $t6, 4($t4)			# Grava de volta no header do buffer, sem o IP de destino
	sw $t6, 4($t9)			# Grava o num do IP para enviar o array
	
	

#COMANDO PARA ENVIAR ARRAY
	lui $t0, 0x0800			# Endereco do TX
	
	
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria que contem as informações
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +


	addiu $t9,$t9, ARRAY_SIZE
	addiu $t8,$t8,1			# SEND_INDEX++    t6++
	
	
#-------------------------------FIM ENVIAR ARRAY------------------------------------------------------------------------------------------

loop2_continue:
#----------------------------
	#LOCALIZAR O VETOR DO BUFFER NO VETOR ARRAY_1500
	
	la $t7, ARRAY_1500
        
	#la $t0, SEND_INDEX		# Guarda SEND_INDEX
	#sw $t8, 0($t0)
	addiu $t2, $t7, 6180	# Caso percorreu todo o array, sai do loop
	
	BUSCA:

	beq $t7, $t2, END		# Caso chegar no fim, deu erro
	lw $t0, 8($t7)			# CARREGA NUM_ARRAY do array
	lw $t1, 8($t4)			# CARREGA NUM_ARRAY do buffer
	
	beq $t0, $t1, TROCA		# Caso forem iguais vai pra troca
	j BUSCA
	TROCA:
		
	addiu $t2,$t7,ARRAY_SIZE
	addiu $t7,$t7,12 #endereco do primeiro elemento do array
	addiu $t3,$t4,12 #endereco do primeiro elemento do array no buffer
	TROCA_LOOP:
	
		beq $t2,$t7,TROCA_END
		lw $t1,0($t3)
		sw $t1,0($t7)
		addiu $t7,$t7,4 #array[i++]
		addiu $t3,$t3,4 #buffer[i++]
		
		
		j TROCA_LOOP
	
	
	
	TROCA_END:
	
	
	addiu $t5,$t5,1  #arrays recebidos $t5++
	#la $t0, SEND_INDEX
	#lw $t8,0($t0) #CARREGA SEND_INDEX


	j LOOP2

END_LOOP2:
	
	
	
END:
	j END
																	
					
.data 
	RX_BUFF:	.space ARRAY_SIZE
	SEND_INDEX:	.word 0
	NUM_PROC: 	.word 4
	ARRAY_1500:	.space 6000 #1500*4     1500 inteiros
	#SIZE		4
	#HEADER		4
	#NUM_ARRAY 	4
	#array_elements	400
	
