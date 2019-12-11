.data
	a	.word	0
	result0	.word	0
	result1	.word	0
	result2	.word	0
.text
#Operation mul for arguments: 7 9
li $t0, 7
li $t0, 9
mul $t0, $t0, %t1
sw $t0, result0
#Operation add for arguments: 3 result0
li $t0, 3
lw $t0, result0
add $t0, $t0, %t1
sw $t0, result1
#Operation assign for arguments: a result1
lw $t0, result1
sw $t0, a
