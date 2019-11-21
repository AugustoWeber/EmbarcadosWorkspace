.eqv DMA_ADDR 0x0800
.eqv NOC_ADDR 0x0900
.eqv ROOT_NUM 5
.text

main:


	#carregar endereco da NOC
	lui $t0,NOC_ADDR
#Receber HEADER
RX_HEADER:
	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,32
	and $t4,$t3,$t9
	beq $t4,$t3,LER_HEADER  #verifica se o status(5) é 1, se for 1 tenta ler
	j RX_HEADER
LER_HEADER:
	lw $t6,4($t0) #le o dado vindo da noc
	
	la $t9,HEADER
	sw $t6,0($t9) #SALVA HEADER
	
#Receber SIZE
RX_SIZE:

	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,32 
	and $t4,$t3,$t9
	beq $t4,$t3,LER_SIZE  #verifica se o STALL é 1, se for 0 tenta ler
	j RX_SIZE
LER_SIZE:
	lw $t7,4($t0) #le o dado vindo da noc
	la $t9,SIZE
	sw $t7,0($t9) #SALVA SIZE
	
#Configurar DMA para receber o Array
	lui $t0,DMA_ADDR
	
	la $t9,ARRAY
	
#ROTINA PARA RECEBER VIA DMA
	
	sw $t9, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t7, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA




#Enviar Array de volta



#ENVIAR DE VOLTA VIA DMA MASTER
	

#Enviar para o MASTER
	lui $t0,NOC_ADDR
	
	la $t1,HEADER #CARREGAR O HEADER RECEBIDO
	lw $t1,0($t1)
	
	#INVERTER A ORIGEM E DESTINO DO HEADER, 
	sll $t2,$t1,16
	srl $t5,$t1,16
	or $t5,$t2,$t5 
		
#enviar o Header  |ORIGEM|DESTINO| 32 bits
LOOP_HEADER:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,32 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_HEADER
	J LOOP_HEADER    #caso não consiga enviar retorna para LOOP_HEADER
ENVIAR_HEADER:
	sw	$t5,4($t0) 	#Enviar HEADER PELA NOC
	

#Configurar DMA para enviar o Array
	#Carregar endereço do array
	la $t9, ARRAY
	#Carregar SIZE
	la $t7,SIZE
	lw $t7,0($t7)
	addiu $t0,$zero,DMA_ADDR    #carrega endereco do DMA
	
#ROTINA PARA ENVIAR VIA DMA
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria onde começa o ARRAY
	sw $t7, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA





END:

	j END

.data 	
	HEADER: 	.word 0
    	SIZE: 		.word 0
    	ARRAY:		.word 0
