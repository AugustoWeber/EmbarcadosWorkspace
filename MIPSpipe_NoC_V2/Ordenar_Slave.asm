
.text
main:

#RECEBER DADOS VIA DMA

#CONFIGURAR O DMA para o endereço 0($t0) e size 102
	lui $t0,0x0800
	la $t2,array
	
	addiu $t1,$zero,102	
#ROTINA PARA RECEBER VIA DMA
	
	sw $t2, 20($t0)			# Grava no registrador RX o endereço da memoria que ira receber o array
	sw $t1, 24($t0)			# Grava no registrador RX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +
#FIM ROTINA


#FIM RECEBER





#------INSERTION SORT-----------------------------------------------------------
	addiu      $t9, $zero,100              # t9 = size
	        	
   	la $t8,array			#t8 = endereco array
   	addiu $t8,$t8,8
   	
   	
   	
   	addiu $t7,$t8,4			#t7 = eleito array[1]
   	
for_loop:				#for size--
	beq $t9,$zero,end	
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

	la $t1,array
	lw $t2,0($t1)
	sll $t2,$t2,16
	sw $t2,0($t1)
	
	lui $t0,0x0800
	addiu $t3,$zero,102	
	
	sw $t1, 4($t0)			# Grava no registrador TX o endereço da memoria que deseja enviar
	sw $t3, 8($t0)			# Grava no registrador TX o size
	addiu $t2, $zero, 2
	sw $t2, 0($t0)			# Grava 2 no registrador STATUS indicando para iniciar a transmissão... té +

	j main

end: 
	j end 

.data 
    	array:      .space 408 
