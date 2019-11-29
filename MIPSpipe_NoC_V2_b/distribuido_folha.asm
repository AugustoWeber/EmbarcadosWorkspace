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
	addiu $t2, $zero, 8
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA


#----------------FIM-RECEBER-ARRAY-------------------------------------------





#------INSERTION SORT-----------------------------------------------------------
	#addiu      $t9, $zero,100              # t9 = size
	la $t0,SIZE
	lw $t9,0($t0)   	#CARREGAR SIZE
	addiu $t9,$t9,-1
	
   	la $t8,ARRAY			#t8 = endereco array
 
   	
   	
   	
   	addiu $t7,$t8,4			#t7 = eleito array[1]
   	
for_loop:				#for size--
	beq $t9,$zero,FIM_INSERTION	
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

#ENVIAR DE VOLTA VIA DMA MASTER
	
FIM_INSERTION:

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
	addiu $t7,$zero,16 #ve se pode transmitir	
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
	lui $t0,DMA_ADDR    #carrega endereco do DMA
	
#ROTINA PARA ENVIAR VIA DMA
	sw $t9, 4($t0)			# Grava no registrador TX o endereço da memoria onde começa o ARRAY
	sw $t7, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA


end: 
	j end 

.data 
    	HEADER:  .word 0
    	SIZE:	.word 0
    	ARRAY:      .space 40 

