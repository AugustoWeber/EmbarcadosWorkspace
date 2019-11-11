
.text
main:
	#carrega endereco do NoC
	lui $t0, 0x0800

	lui $t1, 0x1001
   	
   	
	lw $t9,0($t1)   #carrega SIZE
	
	#addiu $t9,$t9,1 #size vai ter 1 elemento a mais, pois o primeiro elemento é o endereço
	
	addiu $t1,$t1,4  #primeiro elemento do vetor SIZE
	
	
	addiu $t2,$zero,0 #t2 = i; i vai de 0 ate size
	
LOOP:
	beq $t2,$t9,ENVIAR_ULTIMO
	lw $t8,0($t1)   #carrega dado a ser enviado
	jal SEND_t8       #envia dado carregado
NEXT_NUM:
	addiu $t2,$t2,1   # i++
	addiu $t1,$t1,4   #endereco = endereco + 4
	j LOOP

SEND_t8:
	
	lw $t6,8($t0) # carrega o status
	addiu $t7,$zero,0x40 #ve se pode transmitir	
	and $t6,$t6,$t7
	beq $t6,$t7, ENVIAR_T8
	J SEND_t8    #caso não consiga enviar retorna para SEND_t8
	
ENVIAR_T8:
	sw $t8,0($t0)
   jr ra

ENVIAR_ULTIMO:
	sw $t8,4($t0)
	j END_LOOP
	
	
END_LOOP:
	j END_LOOP  #FIM PROGRAMA


.data 
	size:       .word 7
    	array:      .word 9 4 2 1 5 4 7 3
