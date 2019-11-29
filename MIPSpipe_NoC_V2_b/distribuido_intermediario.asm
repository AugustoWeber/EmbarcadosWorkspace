.eqv DMA_ADDR 0x0800
.eqv NOC_ADDR 0x0900
.eqv ROOT_NUM 5
.eqv ARRAY_ELEMENTS 360
.text


main:

	#carregar endereco da NOC
	lui $t0,NOC_ADDR
	
	

#Receber HEADER
RX_HEADER:
	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,32 
	and $t4,$t3,$t9
	beq $t4,$t3,RECEBER_HEADER  #verifica se o STALL é 1, se for 0 tenta ler
	j RX_HEADER
RECEBER_HEADER:
	lw $t6,4($t0) #le o dado vindo da noc
	
	la $t9,HEADER
	sw $t6,0($t9) #SALVA HEADER
	
#Receber SIZE
RX_SIZE:

	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,32 
	and $t4,$t3,$t9
	beq $t4,$t3,RECEBER_SIZE  #verifica se o STALL é 1, se for 0 tenta ler
	j RX_SIZE
RECEBER_SIZE:
	lw $t7,4($t0) #le o dado vindo da noc
	la $t9,SIZE
	sw $t7,0($t9) #SALVA SIZE
	
#Configurar DMA para receber o Array
	lui $t0,DMA_ADDR
	
	la $t9,ARRAY
	
#ROTINA PARA RECEBER VIA DMA
	
	sw $t9, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t7, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero,8
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA


#----------------FIM-RECEBER-ARRAY-------------------------------------------

#TODOS REGISTRADORES ESTAO DISPONIVEIS


#descobrir para quem enviar switch-case
	la  $t6,HEADER
	lw  $t6,0($t6) #Carregar o Header
	srl $t5,$t6,16 #t5 recebe a Origem do header
	addiu $t1,$zero,0xFFFF
	and $t6,$t1,$t6  #t6 recebe o destino do header
	
	la $t1,IP_ADDR #Guarda o ENDEREÇO da NOC para este processador
	sw $t6,0($t1)
	
	
	la $t9,DESTINO_1
	la $t8,DESTINO_2
	
	addiu $t0,$zero,ROOT_NUM  #descobrir se recebeu do root, caso sim, é o MIPS 6 ou 9
	beq $t0,$t5,ME_6_9
	
	addiu $t0,$zero,2
	beq $t0,$t6,ME_2
	
	addiu $t0,$zero,7
	beq $t0,$t6,ME_7
	
	addiu $t0,$zero,8
	beq $t0,$t6,ME_8
	
	addiu $t0,$zero,13
	beq $t0,$t6,ME_13	
	
	j END #DEU ERRO
	
ME_6_9:
	addiu $t0,$zero,6
	beq $t0,$t6,ME_6
	j ME_9
	
	
ME_6:
	addiu $t1,$zero,2
	sw $t1,0($t9) #SALVA DESTINO_1
	addiu $t1,$zero,7
	sw $t1,0($t8) #SALVA DESTINO_2
	
	j ME_CONTINUE
ME_9:
	addiu $t1,$zero,8
	sw $t1,0($t9) #SALVA DESTINO_1
	addiu $t1,$zero,13
	sw $t1,0($t8) #SALVA DESTINO_2
	
	j ME_CONTINUE
ME_2:
	addiu $t1,$zero,11
	sw $t1,0($t9) #SALVA DESTINO_1
	addiu $t1,$zero,10
	sw $t1,0($t8) #SALVA DESTINO_2
	
	j ME_CONTINUE
ME_7:
	addiu $t1,$zero,3
	sw $t1,0($t9) #SALVA DESTINO_1
	addiu $t1,$zero,1
	sw $t1,0($t8) #SALVA DESTINO_2
	
	j ME_CONTINUE
ME_8:
	addiu $t1,$zero,4
	sw $t1,0($t9) #SALVA DESTINO_1
	addiu $t1,$zero,12
	sw $t1,0($t8) #SALVA DESTINO_2
	
	j ME_CONTINUE
ME_13:
	addiu $t1,$zero,14
	sw $t1,0($t9) #SALVA DESTINO_1
	addiu $t1,$zero,15
	sw $t1,0($t8) #SALVA DESTINO_2
	
	j ME_CONTINUE

ME_CONTINUE:
#----------------DIVIDIR-ENVIAR-ARRAY---------------------------------------

#TODOS REGISTRADORES ESTAO DISPONIVEIS

#Carregar endereço do array
	la $t9, ARRAY
#Carregar SIZE
	la $t7,SIZE
	lw $t7,0($t7)
#Calcular o endereço da metade do array
	srl $t7,$t7,1      #/2
	sll $t8,$t7,2      #x4
	addu $t8,$t8,$t9
	#t8 aponta para a metade do array

#-----------------------ENVIAR ARRAY------------------------------------------------------------------

#Enviar primeira metade do array para o processador DESTINO_1
	
	
	lui $t0,NOC_ADDR
	
#enviar o Header  |ORIGEM|DESTINO| 32 bits
	la $t1,IP_ADDR
	lw $t5,0($t1) #CArrega o NUM_IP
	sll   $t5,$t5,16
	
	la $t1, DESTINO_1
	lw $t1,0($t1)
	addu $t5,$t5,$t1            #WORD CARREGADA COM a origem e o destino 
LOOP_HEADER:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,16 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_HEADER
	J LOOP_HEADER    #caso não consiga enviar retorna para LOOP_HEADER
ENVIAR_HEADER:
	sw $t5,4($t0) 	#Enviar HEADER PELA NOC
#Enviar o tamanho
LOOP_SIZE:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,16 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_SIZE
	J LOOP_SIZE   #caso não consiga enviar retorna para LOOP_HEADER
	
ENVIAR_SIZE:
	la $t1,SIZE
	lw $t7,0($t1)
	srl $t7,$t7,1
	sw	$t7,4($t0) 	#Enviar SIZE pela NOC, SIZE = SIZE/2

#Configurar DMA para enviar o Array
	
	lui $t0,DMA_ADDR    #carrega endereco do DMA
	#addiu $t7,$t7,1
#ROTINA PARA ENVIAR VIA DMA
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria onde começa o ARRAY
	sw $t7, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA
	
	
	
#Enviar segunda metade do array para o processador DESTINO_2

	lui $t0,NOC_ADDR
#enviar o Header  |ORIGEM|DESTINO| 32 bits
	la $t1,IP_ADDR
	lw $t5,0($t1) #Carrega o NUM_IP
	sll   $t5,$t5,16
	
	la $t1, DESTINO_2
	lw $t1,0($t1)
	addu $t5,$t5,$t1            #WORD CARREGADA COM a origem e o destino 

LOOP_HEADER_2:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,16 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_HEADER_2
	J LOOP_HEADER_2    #caso não consiga enviar retorna para LOOP_HEADER
ENVIAR_HEADER_2:
	#addiu $t5,$zero,ROOT_NUM
	#sll   $t5,$t5,16
	#addiu $t5,$t5,9           #WORD CARREGADA COM a origem e o destino 
	sw	$t5,4($t0) 	#Enviar HEADER PELA NOC
#Enviar o tamanho
LOOP_SIZE_2:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,16 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_SIZE_2
	J LOOP_SIZE_2   #caso não consiga enviar retorna para LOOP_HEADER
	
ENVIAR_SIZE_2:
	la $t1,SIZE
	lw $t7,0($t1)
	srl $t7,$t7,1
	sw	$t7,4($t0) 	#Enviar SIZE pela NOC, SIZE = SIZE/2

#Configurar DMA para enviar o Array
	
	lui $t0,DMA_ADDR    #carrega endereco do DMA
	#addiu $t7,$t7,1
#ROTINA PARA ENVIAR VIA DMA
	sw $t8, 4($t0)			# Grava no registrador TX o endereço da memoria onde começa a metade do array ARRAY
	sw $t7, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA

#----------------------FIM-ENVIAR-ARRAY-----------------------------------------------------------


#----------------------------RECEBER-ARRAY----------------------------------------------------------
#TODOS REGISTRADORES DISPONIVEIS

#Receber HEADER
RX_SLAVE_HEADER:
	lui $t0,NOC_ADDR	
	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,32 
	and $t4,$t3,$t9
	beq $t4,$t3,RECEBER_HEADER_2  #verifica se o STALL é 1, se for 0 tenta ler
	
	j RX_SLAVE_HEADER
RECEBER_HEADER_2:
	lw $t6,4($t0) #le o dado vindo da noc
	
#Configurar DMA para receber o Array
	lui $t0,DMA_ADDR
	
	la $t9,ARRAY
	
	la $t1,SIZE
	lw $t1,0($t1)
	srl $t7,$t1,1    #SIZE/2
	
#ROTINA PARA RECEBER VIA DMA
	
	sw $t9, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t7, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero, 8
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA

#RECEBER SEGUNDO ARRAY

RX_SLAVE_2_HEADER:
	lui $t0,NOC_ADDR
	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,32 
	and $t4,$t3,$t9
	beq $t4,$t3,RECEBER_HEADER_3  #verifica se o STALL é 1, se for 0 tenta ler
	j RX_SLAVE_2_HEADER
RECEBER_HEADER_3:
	lw $t6,4($t0) #le o dado vindo da noc
	
#Configurar DMA para receber o Array
	lui $t0,DMA_ADDR
		
		
#Carregar endereço do array
	la $t9, ARRAY

#Calcular o endereço da metade do array
	sll $t8,$t7,2      #x4
	addu $t8,$t8,$t9
	#t8 aponta para a metade do array
	
	
#ROTINA PARA RECEBER VIA DMA
	
	sw $t8, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t7, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero, 8
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA

#---------------------------FIM-RECEBER-ARRAY-----------------------------------------------------

#-------------------------------JUNTAR-ARRAY--------------------------------------------------------------

#TODOS REGISTRADORES DISPONIVEIS

	la $t9,ARRAY
	#la $t8,ARRAY_2
	#t8 = Array_2
	
	la $t3,ARRAY_FINAL
	
	#la $t7,SIZE
	#lw $t7,0($t7)
	#T7 = SIZE/2
	
	sll $t7,$t7,2  #SIZE*4
	
	addu $t6,$t8,$t7 #fim ARRAY_2
	addu $t7,$t7,$t9 #fim Array_1
	
	
	LOOP_MERGE:
		
		beq $t9,$t7,FIM_ARRAY_1
		beq $t8,$t6,FIM_ARRAY_2
		
		lw $t0,0($t9)
		lw $t1,0($t8)

		slt $t0,$t0,$t1                  # T0 <= 1 se ARRAY_1[n] < ARRAY_2[m]
		addiu $t1,$zero,1
		beq $t1,$t0,ARRAY_1_MENOR
		#SE ARRAY2 > ARRAY1...
		
		lw $t0,0($t8)
		sw $t0,0($t3)        #GRAVA ARRAY2 no ARRAY DESTINO
		addiu $t8,$t8,4      #i++
		addiu $t3,$t3,4      
		
		j LOOP_MERGE
ARRAY_1_MENOR:		
		lw $t0,0($t9)
		sw $t0,0($t3)        #GRAVA ARRAY2 no ARRAY DESTINO
		addiu $t9,$t9,4      #i++
		addiu $t3,$t3,4      
		
		j LOOP_MERGE
		
FIM_ARRAY_1: #grava o que sobrou no array 2, no destino
		beq $t8,$t6,FIM_MERGE  #VErifica se o Array2 ja terminou
		lw $t0,0($t8)
		sw $t0,0($t3)        #GRAVA ARRAY2 no ARRAY DESTINO
		addiu $t8,$t8,4      #i++
		addiu $t3,$t3,4      
		j LOOP_MERGE
FIM_ARRAY_2:
		beq $t9,$t7,FIM_MERGE #VErifica se o Array1 ja terminou
		lw $t0,0($t9)
		sw $t0,0($t3)        #GRAVA ARRAY2 no ARRAY DESTINO
		addiu $t9,$t9,4      #i++
		addiu $t3,$t3,4      
		j LOOP_MERGE

#-------------------------FIM-JUNTAR-ARRAY--------------------------------------------------------------


FIM_MERGE:


#Enviar para o MASTER
	lui $t0,NOC_ADDR
	
	la $t1,HEADER #CARREGAR O HEADER RECEBIDO
	lw $t1,0($t1)
	
	#INVERTER A ORIGEM E DESTINO DO HEADER, 
	sll $t2,$t1,16
	srl $t5,$t1,16
	or $t5,$t2,$t5 
		
#enviar o Header  |ORIGEM|DESTINO| 32 bits
LOOP_HEADER_3:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,16 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_HEADER_3
	J LOOP_HEADER_3    #caso não consiga enviar retorna para LOOP_HEADER
ENVIAR_HEADER_3:
	sw	$t5,4($t0) 	#Enviar HEADER PELA NOC
	

#Configurar DMA para enviar o Array
	#Carregar endereço do array
	la $t9,ARRAY_FINAL
	#Carregar SIZE
	la $t7,SIZE
	lw $t7,0($t7)
	lui $t0,DMA_ADDR    #carrega endereco do DMA
	
#ROTINA PARA ENVIAR VIA DMA
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria onde começa o ARRAY
	sw $t7, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA

END:
	j END
		

.data
	IP_ADDR:   .word 0
	DESTINO_1: .word 0
	DESTINO_2: .word 0
	SIZE: 		.word 0
	HEADER:		 .word 0
	ARRAY: 		.space 1600
	ARRAY_FINAL:  .space 1600
