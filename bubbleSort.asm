
# Programa: BubbleSort
# Descri��o: Ordena��o crescente

.text
main:
    nop
    nop
    nop
    lui $at, 0x00001001
    addiu   $t5, $zero, 1           # t5 = constant 1
    addiu   $t8, $zero, 1           # t8 = 1: swap performed
 
while:
    beq     $t8, $zero, end         # Verifies if a swap has ocurred
    #la      $t6, size               #  
    ori     $t6,$at,0
    #la      $t0, array              # t0 points the first array element
    addiu   $t0,$t6,4
    
    nop
    lw      $t6, 0($t6)             # t6 <- size    
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

    
end: 
   
    j       end
   nop
   nop
   nop

 
   
.data 
    size:       .word 100
    array:      .word 99 98 97 96 95 94 93 92 91 90 
    			89 88 87 86 85 84 83 82 81 80 
    			79 78 77 76 75 74 73 72 71 70 
    			69 68 67 66 65 64 63 62 61 60 
    			59 58 57 56 55 54 53 52 51 50 
    			49 48 47 46 45 44 43 42 41 40 
    			39 38 37 36 35 34 33 32 31 30 
    			29 28 27 26 25 24 23 22 21 20 
    			19 18 17 16 15 14 13 12 11 10 
    			9 8 7 6 5 4 3 2 1 0

