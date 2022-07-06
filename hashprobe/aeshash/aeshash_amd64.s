//go:build !purego

#include "textflag.h"

// func Hash32(value uint32, seed uintptr) uintptr
TEXT ·Hash32(SB), NOSPLIT, $0-24
    MOVL value+0(FP), AX
    MOVQ seed+8(FP), BX

    MOVOU runtime·aeskeysched+0(SB), X1
    MOVOU runtime·aeskeysched+16(SB), X2
    MOVOU runtime·aeskeysched+32(SB), X3

    MOVQ BX, X0
    PINSRD $2, AX, X0

	AESENC X1, X0
	AESENC X2, X0
	AESENC X3, X0

    MOVQ X0, ret+16(FP)
    RET

// func Hash64(value uint64, seed uintptr) uintptr
TEXT ·Hash64(SB), NOSPLIT, $0-24
    MOVL value+0(FP), AX
    MOVQ seed+8(FP), BX

    MOVOU runtime·aeskeysched+0(SB), X1
    MOVOU runtime·aeskeysched+16(SB), X2
    MOVOU runtime·aeskeysched+32(SB), X3

    MOVQ BX, X0
    PINSRQ $1, AX, X0

	AESENC X1, X0
	AESENC X2, X0
	AESENC X3, X0

    MOVQ X0, ret+16(FP)
    RET

// func Hash128(value [16]byte, seed uintptr) uintptr
TEXT ·Hash128(SB), NOSPLIT, $0-32
    LEAQ value+0(FP), AX
    MOVQ seed+16(FP), BX
    MOVQ $16, CX

    MOVQ BX, X0                      // 64 bits of per-table hash seed
    PINSRW $4, CX, X0                // 16 bits of length
    PSHUFHW $0, X0, X0               // repeat length 4 times total
    PXOR runtime·aeskeysched(SB), X0 // xor in per-process seed
    AESENC X0, X0                    // scramble seed

    MOVOU (AX), X1
    PXOR X0, X1
	AESENC X1, X1
	AESENC X1, X1
	AESENC X1, X1

    MOVQ X1, ret+24(FP)
    RET

// func MultiHash32(hashes []uintptr, values []uint32, seed uintptr)
TEXT ·MultiHash32(SB), NOSPLIT, $0-56
    MOVQ hashes_base+0(FP), AX
    MOVQ values_base+24(FP), BX
    MOVQ values_len+32(FP), CX
    MOVQ seed+48(FP), DX

    MOVOU runtime·aeskeysched+0(SB), X1
    MOVOU runtime·aeskeysched+16(SB), X2
    MOVOU runtime·aeskeysched+32(SB), X3

    XORQ SI, SI
    JMP test
loop:
    MOVQ DX, X0
    PINSRD $2, (BX)(SI*4), X0

	AESENC X1, X0
	AESENC X2, X0
	AESENC X3, X0

    MOVQ X0, (AX)(SI*8)
    INCQ SI
test:
    CMPQ SI, CX
    JNE loop
    RET

// func MultiHash64(hashes []uintptr, values []uint64, seed uintptr)
TEXT ·MultiHash64(SB), NOSPLIT, $0-56
    MOVQ hashes_base+0(FP), AX
    MOVQ values_base+24(FP), BX
    MOVQ values_len+32(FP), CX
    MOVQ seed+48(FP), DX

    MOVOU runtime·aeskeysched+0(SB), X1
    MOVOU runtime·aeskeysched+16(SB), X2
    MOVOU runtime·aeskeysched+32(SB), X3

    XORQ SI, SI
    JMP test
loop:
    MOVQ DX, X0
    PINSRQ $1, (BX)(SI*8), X0

	AESENC X1, X0
	AESENC X2, X0
	AESENC X3, X0

    MOVQ X0, (AX)(SI*8)
    INCQ SI
test:
    CMPQ SI, CX
    JNE loop
    RET

// func MultiHash128(hashes []uintptr, values [][16]byte, seed uintptr)
TEXT ·MultiHash128(SB), NOSPLIT, $0-56
    MOVQ hashes_base+0(FP), AX
    MOVQ values_base+24(FP), BX
    MOVQ values_len+32(FP), CX
    MOVQ seed+48(FP), DX
    MOVQ $16, DI

    MOVQ DX, X0
    PINSRW $4, DI, X0
    PSHUFHW $0, X0, X0
    PXOR runtime·aeskeysched(SB), X0
    AESENC X0, X0

    XORQ SI, SI
    JMP test
loop:
    MOVOU (BX), X1

    PXOR X0, X1
	AESENC X1, X1
	AESENC X1, X1
	AESENC X1, X1

    MOVQ X1, (AX)(SI*8)
    ADDQ $16, BX
    INCQ SI
test:
    CMPQ SI, CX
    JNE loop
    RET
