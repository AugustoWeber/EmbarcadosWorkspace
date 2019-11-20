.text
	addiu $t0, $zero,16
	addiu $t1, $t0, 16
	sll $t1, $t1, 4
	srl $t0, $t0, 2
end:
	j end	 