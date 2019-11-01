
.text
main:
	nop
	nop 
	nop 
	#la $t0,size
	lui $at, 0x00001001

	ori $t0, $at,0x0000000
	lw $t9,0($t0)
	
	addiu $t1,$zero,0
	addu $t0,$t9,$zero
multi:
	beq   $t0,$zero, multi_end 
	addiu $t1,$t1,4
	addiu $t0,$t0,-1
	#subiu $t0,$t0,1
	j multi
multi_end:
	
	addu $t9,$t1,$zero   #size
	addiu $t5,$zero,0 #i=0
for_loop1:
	#subiu $t0,$t9,4    #size-1
	addiu $t0,$t9,-4    #size-1
	beq $t5,$t0,for_end
	addu $t8,$t5,$zero     # min = i
	addiu $t4,$t5,4    #j = i+1
	for_loopj:
		beq $t4,$t9,forj_end
		#la $t1,array
		lui $at, 0x00001001
		ori $t1,$at,0x00000004
		addu $t0,$t1,$t4 
		lw $t3,0($t0)  #array[j]

		addu $t0,$t1,$t8
		lw  $t6,0($t0) #array[min]
		slt $t0,$t3,$t6		#se array[j] < array[min] t0 <= 1
		beq $t0,$zero,end_if1
		addu $t8,$t4,$zero

				
	end_if1:
		addiu $t4,$t4,4    #j++
		
		j for_loopj
		forj_end:
		beq $t5,$t8, end_if
		addu $t0,$t1,$t5

		lw $t7,0($t0) #aux
		
		
		addu $t2,$t1,$t8 

		lw  $t6,0($t2) #array[min]
		nop
		nop
		nop
		sw $t7,0($t2)
		sw $t6,0($t0)			
	end_if:
		addiu $t5,$t5,4	
																
	j for_loop1

for_end:		
end: 
	j end 
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