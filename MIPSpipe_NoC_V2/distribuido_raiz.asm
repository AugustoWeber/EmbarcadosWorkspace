.eqv DMA_ADDR 0x0800
.eqv NOC_ADDR 0x0900
.eqv ROOT_NUM 5
.text


main:

#Carregar endereço do array
	la $t9, ARRAY
#Carregar SIZE
	la $t7,SIZE
	lw $t7,0($t7)
#Calcular o endereço da metade do array
	srl $t7,$t7,1      #/2
	sll $t8,$t7,2      #x4
	addiu $t8,$t8,$t9
	#t8 aponta para a metade do array

#-----------------------ENVIAR ARRAY------------------------------------------------------------------

#Enviar primeira metade do array para o processador 6
	lui $t0,NOC_ADDR
	
#enviar o Header  |ORIGEM|DESTINO| 32 bits
LOOP_HEADER:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,0x40 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_HEADER
	J LOOP_HEADER    #caso não consiga enviar retorna para LOOP_HEADER
ENVIAR_HEADER:
	addiu $t5,$zero,ROOT_NUM
	sll   $t5,$t5,16
	addiu $t5,$t5,6            #WORD CARREGADA COM a origem ROOT_NUM e o destino 6
	sw	$t5,4($t0) 	#Enviar HEADER PELA NOC
#Enviar o tamanho
LOOP_SIZE:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,0x40 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_SIZE
	J LOOP_SIZE   #caso não consiga enviar retorna para LOOP_HEADER
	
ENVIAR_SIZE:
	sw	$t7,4($t0) 	#Enviar SIZE pela NOC, SIZE = SIZE/2

#Configurar DMA para enviar o Array
	
	addiu $t0,$zero,DMA_ADDR    #carrega endereco do DMA
	
#ROTINA PARA ENVIAR VIA DMA
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria onde começa o ARRAY
	sw $t7, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA
	
#Enviar segunda metade do array para o processador 9

	lui $t0,NOC_ADDR
	
#enviar o Header  |ORIGEM|DESTINO| 32 bits
LOOP_HEADER_2:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,0x40 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_HEADER_2
	J LOOP_HEADER_2    #caso não consiga enviar retorna para LOOP_HEADER
ENVIAR_HEADER_2:
	addiu $t5,$zero,ROOT_NUM
	sll   $t5,$t5,16
	addiu $t5,$t5,9           #WORD CARREGADA COM a origem ROOT_NUM e o destino 9
	sw	$t5,4($t0) 	#Enviar HEADER PELA NOC
#Enviar o tamanho
LOOP_SIZE_2:
	lw $t6,0($t0) # carrega o status
	addiu $t7,$zero,0x40 #ve se pode transmitir	
	and $t6,$t6,$t7
	
	beq $t6,$t7, ENVIAR_SIZE_2
	J LOOP_SIZE_2   #caso não consiga enviar retorna para LOOP_HEADER
	
ENVIAR_SIZE_2:
	sw	$t7,4($t0) 	#Enviar SIZE pela NOC, SIZE = SIZE/2

#Configurar DMA para enviar o Array
	
	addiu $t0,$zero,DMA_ADDR    #carrega endereco do DMA
	
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
RX_HEADER:
	lui $t0,NOC_ADDR	
	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,0x20 
	and $t4,$t3,$t9
	beq $t4,$t3,RX_HEADER  #verifica se o STALL é 1, se for 0 tenta ler
	
	lw $t6,0($t0) #le o dado vindo da noc
	
#Configurar DMA para receber o Array
	lui $t0,DMA_ADDR
	
	la $t9,ARRAY
	
	la $t1,SIZE
	lw $t1,0($t1)
	srl $t7,$t1,1    #SIZE/2
	
#ROTINA PARA RECEBER VIA DMA
	
	sw $t9, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t7, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA

#RECEBER SEGUNDO ARRAY

RX_2_HEADER:
	lui $t0,NOC_ADDR
	lw $t9,0($t0)  #ler o status
	addiu $t3,$zero,0x20 
	and $t4,$t3,$t9
	beq $t4,$t3,RX_2_HEADER  #verifica se o STALL é 1, se for 0 tenta ler
	
	lw $t6,0($t0) #le o dado vindo da noc
	
#Configurar DMA para receber o Array
	lui $t0,DMA_ADDR
		
		
#Carregar endereço do array
	la $t9, ARRAY

#Calcular o endereço da metade do array
	sll $t8,$t7,2      #x4
	addiu $t8,$t8,$t9
	#t8 aponta para a metade do array
	
	
#ROTINA PARA RECEBER VIA DMA
	
	sw $t8, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t7, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero, 2
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
	
	add $t6,$t8,$t7 #ARRAY_2
	add $t7,$t7,$t9 #Array_1
	
	
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
		beq $t8,$t6,END  #VErifica se o Array2 ja terminou
		lw $t0,0($t8)
		sw $t0,0($t3)        #GRAVA ARRAY2 no ARRAY DESTINO
		addiu $t8,$t8,4      #i++
		addiu $t3,$t3,4      
		j LOOP_MERGE
FIM_ARRAY_2:
		beq $t9,$t7,END #VErifica se o Array1 ja terminou
		lw $t0,0($t9)
		sw $t0,0($t3)        #GRAVA ARRAY2 no ARRAY DESTINO
		addiu $t9,$t9,4      #i++
		addiu $t3,$t3,4      
		j LOOP_MERGE

#-------------------------FIM-JUNTAR-ARRAY--------------------------------------------------------------


END:
	j END



.data
	SIZE: .word 20
	 ARRAY:		.word 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1
	ARRAY_FINAL: .space 80