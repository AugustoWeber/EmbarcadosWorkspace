
.text
main:
	#carrega endereco do NoC
	lui $t0,0x0800
	lui $t1,0x1001 #endereco de onde vai guardar o array, primeiro elemento é o tamanho   	
	
	addiu $t2,$t1,4 #adiciona 4 para começar a salvar o array a partir daqui
	addiu $t5,$zero,0 #size = 0
RECEBER_LOOP:
	
	lw $t9,8($t0)  #ler o status
	addiu $t3,$zero,0x20 
	and $t4,$t3,$t9
	beq $t4,$t3,RECEBER_LOOP #verifica se o STALL é 1, se for 0 tenta ler

	
	lw $t8,0($t0) #le o dado vindo da noc
	
	sw $t8,0($t2)
	addiu $t2,$t2,4   #endereco++4
	addiu $t5,$t5,1  #SIZE++
	
	addiu $t3,$zero,1 #verifica no status se é o ultimo flit
	and $t4,$t3,$t9
	
	beq $t4,$t3,SALVA_SIZE #verifica se o é o ultimo dado
	j RECEBER_LOOP
	
SALVA_SIZE:
	sw $t5,0($t1)

END:
	j END
	