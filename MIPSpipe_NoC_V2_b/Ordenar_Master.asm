.eqv ELEMENTOS_ARRAY 100 
.eqv ARRAY_NODE_SIZE 408
.eqv NUM_SLAVES 15
.eqv NUM_ARRAYS 15
.eqv ARRAY_1500_SIZE 6120
.eqv ENDERECO_DMA 0x0800
.eqv ENDERECO_NOC 0x0900
.text


main:

#ENVIAR a primeira leva de arrays para os  N_PROC SLAVES
	la $t9, ARRAY_1500 #carrega endereco do ARRAY
	
	la $t0, SLAVES #CARREGA NUM_PROC
	lw $t7, 0($t0)
	addiu $t7, $t7, 1 #NUM_PROC+1, quando for NUM_PROC+1 sai do loop enviar primeiros
	
	addiu $t6, $zero, 1 #NUMERO DO SLAVE QUE VAI RECEBER O ARRAY, COMEÇA EM 1 E VAI ATÉ 15
LOOP_PRIMEIRO_ENVIO:
	beq $t7,$t6,FIM_PRIMEIRO_ENVIO 
	sw $t6, 0($t9)			# Grava o num do IP para enviar o array
	
	lui $t0,ENDERECO_DMA
	addiu $t8,$zero,102   #SIZE
	
#ROTINA PARA ENVIAR VIA DMA
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria que contem as informações
	sw $t8, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA
	
	addiu $t9, $t9, ARRAY_NODE_SIZE  # Array[i++]
	addiu $t6, $t6, 1          	 #Slave_enviar -> t6++

	
	
	j LOOP_PRIMEIRO_ENVIO
	
FIM_PRIMEIRO_ENVIO:
		
	#salvar na memoria o numero de arrays enviados = NUM_SLAVES
	la $t0, NUM_ENVIADOS  #CARREGA endereco variavel NUM_ENVIADOS
	addiu $t1,$t6,-1
	sw $t1,0($t0)    #Grava na memoria numero de arrays enviados


#AGUARDAR RECEBER OS ARRAYS ORDENADOS      #aqui o registrador t6(SLAVE_ENVIAR) vai estar com valor de NUM_SLAVES+1

#POOLING RECEBER
#VERIFICAR SE JA RECEBEU TODOS OS ARRAYS

LOOP_RECEBER_HEADER: #FICA NO LOOP ATE RECEBER ALGUM DADO
	
	#carrega endereco do NoC
	lui $t0,ENDERECO_NOC	
	lw $t2,0($t0)  #ler o status
	addiu $t3,$zero,32
	and $t2,$t3,$t2
	beq $t2,$t3,LER_HEADER #verifica se o recived é 1, se for 1 tenta ler
	j LOOP_RECEBER_HEADER
LER_HEADER:
	lw $t5,4($t0) #le o dado vindo da noc
	#srl $t5,$t5,16 # faz um shift no header para saber qual slave vai enviar o array
	
LOOP_RECEBER_NUM_ARRAY:
	
	lui $t0,ENDERECO_NOC	
	lw $t2,0($t0)  #ler o status
	addiu $t3,$zero,32 
	and $t2,$t3,$t2
	beq $t2,$t3,LER_NUM_ARRAY #verifica se o STATUS(RECIVED) é 1, se for 0 tenta ler
	j LOOP_RECEBER_NUM_ARRAY
LER_NUM_ARRAY:
	lw $t4,4($t0) #le o dado vindo da noc
	
	
	
	#$t7 -> Endereço Array
	la $t7, ARRAY_1500
	addiu $t2, $t7, ARRAY_1500_SIZE 	# Caso percorreu todo o array, sai do loop
BUSCA_ARRAY: #percorrer o array para achar o endereço NUM_ARRAY para acionar o DMA
		
	beq $t7, $t2, END			# Caso chegar no fim, deu erro
	lw $t0, 4($t7)				# CARREGA NUM_ARRAY do array
	
	beq $t0, $t4, DMA_CONFIG		# Caso forem iguais vai para CONFIGURACAO DMA
	addiu $t7,$t7,  ARRAY_NODE_SIZE
	j BUSCA_ARRAY
	
DMA_CONFIG:
	
	#salvar header no array
	sw $t5,0($t7)
	
	#CONFIGURAR O DMA para o endereço 8($t7) e size 100
	addiu $t7,$t7,8
	addiu $t8,$zero, 100	 # Alteracao Augusto
#ROTINA PARA RECEBER VIA DMA
	lui $t0,0x0800
	sw $t7, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t8, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero, 8
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA
		
		
		
	#APOS RECEBIDO VERIFICA SE PRECISA ENVIAR DE VOLTA
	
	la $t0,ARRAYS_RECEBIDOS
	lw $t1,0($t0)
	addiu $t1,$t1,1 #ARRAYS_RECEBIDOS++     vai ate 15
	sw $t1,0($t0) 
	
#ENVIAR OUTRO ARRAY PARA ORDENAR
	
	#verifica se precisa enviar arrays para ordenar
	
	la $t0,NUM_ENVIADOS
	lw $t1,0($t0)
	addiu $t0,$zero,15
	beq $t1,$t0,LOOP_RECEBER_HEADER #caso tenha enviado todos os arrays, pula para o LOOP_RECEBER_HEADER
	
	
	#COMANDOS PARA ENVIAR ARRAY
	#enviar para IP NUM_ENVIADOS+1
	#sw $t6, 0($t9)			# Grava o num do IP para enviar o array

	#ENVIAR PARA O IP RECEBIDO NOVO ARRAY
	srl $t6,$t5,16	
	sw $t6,0($t9)
	
	lui $t0,ENDERECO_DMA
	addiu $t8,$zero,102   #SIZE
	
#ROTINA PARA ENVIAR VIA DMA
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria que contem as informações
	sw $t8, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA
	
	addiu $t9, $t9, ARRAY_NODE_SIZE  # Array[i++]
	addiu $t6, $t6, 1          	 #Slave_enviar -> t6++
	
	la $t0,NUM_ENVIADOS
	lw $t1,0($t0)
	addiu $t1,$t1,1 #ARRAYS_RECEBIDOS++     vai ate 15
	sw $t1,0($t0) 
	
	j LOOP_RECEBER_HEADER


END:
	j END

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
