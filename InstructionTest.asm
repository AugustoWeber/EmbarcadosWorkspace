 Address    Code        Basic                     Source

0x00400000  0x3c011001  lui $1,0x00001001     1    lui $1, 0x1001
0x00400004  0x00000000  nop                   2    nop
0x00400008  0x00000000  nop                   3    nop
0x0040000c  0x00000000  nop                   4    nop
0x00400010  0x3428001c  ori $8,$1,0x0000001c  5    ori $t0,$1,0x001c
0x00400014  0x00000000  nop                   6    nop 
0x00400018  0x00000000  nop                   7    nop 
0x0040001c  0x00000000  nop                   8    nop 
0x00400020  0x00000000  nop                   9    nop
0x00400024  0x8d090000  lw $9,0x00000000($8)  10   lw $t1,0($t0)
0x00400028  0x8d0a0001  lw $10,0x00000001($8) 11   lw $t2,1($t0)
0x0040002c  0x8d0b0002  lw $11,0x00000002($8) 12   lw $t3,2($t0)
0x00400030  0x8d0c0003  lw $12,0x00000003($8) 13   lw $t4,3($t0)
0x00400034  0x8d0d0004  lw $13,0x00000004($8) 14   lw $t5,4($t0)
0x00400038  0x8d0e0005  lw $14,0x00000005($8) 15   lw $t6,5($t0)
0x0040003c  0x8d0f0006  lw $15,0x00000006($8) 16   lw $t7,6($t0)
0x00400040  0x00000000  nop                   17   nop
0x00400044  0x00000000  nop                   18   nop
0x00400048  0x00000000  nop                   19   nop
0x0040004c  0x00000000  nop                   20   nop
0x00400050  0x08100014  j 0x00400050          21   fim:j fim
