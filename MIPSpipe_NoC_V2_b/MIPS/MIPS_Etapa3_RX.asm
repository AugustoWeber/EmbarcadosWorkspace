.text
main:


#RECEBER
RECEBER:
	lui $t0, 0x0800

	lui $t1,0x1001

	
	sw $t1,8($t0)     # grava no registrador RX o endereço da memoria que contem as informações
	addiu $t2,$zero,8
	sw $t2,0($t0)       # grava 8 no registrador STATUS indicando para iniciar a transmissão... té +

#ORDENAR

    addiu   $t5, $zero, 1           # t5 = constant 1
    addiu   $t8, $zero, 1           # t8 = 1: swap performed
    
while:
    beq     $t8, $zero, end_ordenar         # Verifies if a swap has ocurred
    la      $t0, array              # t0 points the first array element
    #la      $t6, size               # 
   addiu    $t0,$t0,12
    
    #lw      $t6, 0($t6)             # t6 <- size    
    addiu   $t6,$zero,100	    #t6 <- size
    
    
    addiu   $t8, $zero, 0           # swap <- 0
    
loop:    
    lw      $t1, 0($t0)             # t1 <- array[i]
    lw      $t2, 4($t0)             # t2 <- array[i+1]
    slt     $t7, $t2, $t1           # array[i+1] < array[i] ?
    beq     $t7, $t5, swap          # Branch if array[i+1] < array[i]

continue:
    addiu   $t0, $t0, 4             # t0 points the next element
    addiu   $t6, $t6, -1            # size--
    beq     $t6, $t5, while         # Verifies if all elements were compared
    j       loop    

# Swaps array[i] and array[i+1]
swap:    
    sw      $t1, 4($t0)
    sw      $t2, 0($t0)
    addiu   $t8, $zero, 1           # Indicates a swap
    j       continue
    
end_ordenar: 
   #ENVIAR ORDENADO
    lui $t0, 0x0800

    lui $t1,0x1001
    
    #lw $t9,4($t1)
    #sll $t9,$t9,4
    sw $zero, 4($t1)
    #ori $t9,$t9,1
    #sw $t9,4($t1)
    
    sw $t1,4($t0)     # grava no registrador TX o endereço da memoria que contem as informações
    addiu $t2,$zero,2
    sw $t2,0($t0)       # grava 2 no registrador STATUS indicando para iniciar a transmissão... té +

    
    
    
    
     j RECEBER
end:
     j       end 

.data 
    array:      .word 0


 
