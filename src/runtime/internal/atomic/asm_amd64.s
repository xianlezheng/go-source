// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Note: some of these functions are semantically inlined
// by the compiler (in src/cmd/compile/internal/gc/ssa.go).

#include "textflag.h"

// bool Cas(int32 *val, int32 old, int32 new)
// Atomically:
//	if(*val == old){
//		*val = new;
//		return 1;
//	} else
//		return 0;
TEXT runtime∕internal∕atomic·Cas(SB),NOSPLIT,$0-17 // 17 = sizeof(*uint32「8」 + sizeof(uint32)「4」 + sizeof(uint32)「4」 + sizeof(uint8/bool)「1」)
	MOVQ	ptr+0(FP), BX   // 入参：1，8字节的uint32指针
	MOVL	old+8(FP), AX   // 入参：2，4字节的 uint32
	MOVL	new+12(FP), CX  // 入参：2，4字节的 uint32
	LOCK
	// lock 前缀指令
	// 在CPU的LOCK信号被声明之后，在此期随同执行的指令会转换成原子指令。
	// 在多处理器环境中，LOCK信号确保，在此信号被声明之后，处理器独占使用任何共享内存
	// LOCK前缀只能预加在以下指令前面，并且只能加在这些形式的指令前面,其中目标操作数是内存操作数：
	// add、adc、and、btc、btr、bts、cmpxchg、cmpxch8b，cmpxchg16b，dec，inc，neg，not，or，sbb，sub，xor，xadd和xchg。

    // ZF: 标志寄存器的一种，零标志：用于判断结果是否为0。运算结果0，ZF置1，否则置0。
    /*
     * CMPXCHGL r, [m]
     * if AX == [m] {
     *   ZF = 1;
     *   [m] = r;
     * } else {
     *   ZF = 0;
     *   AX = [m];
     * }
     */
	CMPXCHGL	CX, 0(BX)   // 比较并交换指令, ZF set to 1 if success(可参考：https://blog.csdn.net/lotluck/article/details/78793468)
	SETEQ	ret+16(FP)      // 1 if ZF set to 1
	RET

// bool	runtime∕internal∕atomic·Cas64(uint64 *val, uint64 old, uint64 new)
// Atomically:
//	if(*val == *old){
//		*val = new;
//		return 1;
//	} else {
//		return 0;
//	}
TEXT runtime∕internal∕atomic·Cas64(SB), NOSPLIT, $0-25
	MOVQ	ptr+0(FP), BX
	MOVQ	old+8(FP), AX
	MOVQ	new+16(FP), CX
	LOCK
	CMPXCHGQ	CX, 0(BX)
	SETEQ	ret+24(FP)
	RET

TEXT runtime∕internal∕atomic·Casuintptr(SB), NOSPLIT, $0-25
	JMP	runtime∕internal∕atomic·Cas64(SB)

TEXT runtime∕internal∕atomic·CasRel(SB), NOSPLIT, $0-17
	JMP	runtime∕internal∕atomic·Cas(SB)

TEXT runtime∕internal∕atomic·Loaduintptr(SB), NOSPLIT, $0-16
	JMP	runtime∕internal∕atomic·Load64(SB)

TEXT runtime∕internal∕atomic·Loaduint(SB), NOSPLIT, $0-16
	JMP	runtime∕internal∕atomic·Load64(SB)

TEXT runtime∕internal∕atomic·Storeuintptr(SB), NOSPLIT, $0-16
	JMP	runtime∕internal∕atomic·Store64(SB)

TEXT runtime∕internal∕atomic·Loadint64(SB), NOSPLIT, $0-16
	JMP	runtime∕internal∕atomic·Load64(SB)

TEXT runtime∕internal∕atomic·Xaddint64(SB), NOSPLIT, $0-24
	JMP	runtime∕internal∕atomic·Xadd64(SB)

// bool Casp1(void **val, void *old, void *new)
// Atomically:
//	if(*val == old){
//		*val = new;
//		return 1;
//	} else
//		return 0;
TEXT runtime∕internal∕atomic·Casp1(SB), NOSPLIT, $0-25
	MOVQ	ptr+0(FP), BX
	MOVQ	old+8(FP), AX
	MOVQ	new+16(FP), CX
	LOCK
	CMPXCHGQ	CX, 0(BX)
	SETEQ	ret+24(FP)
	RET

// uint32 Xadd(uint32 volatile *val, int32 delta)
// Atomically:
//	*val += delta;
//	return *val;
TEXT runtime∕internal∕atomic·Xadd(SB), NOSPLIT, $0-20
	MOVQ	ptr+0(FP), BX
	MOVL	delta+8(FP), AX
	MOVL	AX, CX
	LOCK
	/*  XADDL r,[m]
        temp = [m];
        [m] += r;
        r = temp;
	*/
	XADDL	AX, 0(BX)       // 执行加法运算
	ADDL	CX, AX          // AX += CX
	MOVL	AX, ret+16(FP)
	RET

TEXT runtime∕internal∕atomic·Xadd64(SB), NOSPLIT, $0-24
	MOVQ	ptr+0(FP), BX
	MOVQ	delta+8(FP), AX
	MOVQ	AX, CX
	LOCK
	XADDQ	AX, 0(BX)
	ADDQ	CX, AX
	MOVQ	AX, ret+16(FP)
	RET

TEXT runtime∕internal∕atomic·Xadduintptr(SB), NOSPLIT, $0-24
	JMP	runtime∕internal∕atomic·Xadd64(SB)

// alias("sync/atomic", "SwapInt32", "runtime/internal/atomic", "Xchg", all...)
TEXT runtime∕internal∕atomic·Xchg(SB), NOSPLIT, $0-20
	MOVQ	ptr+0(FP), BX
	MOVL	new+8(FP), AX
	XCHGL	AX, 0(BX)       // 交换指令
	MOVL	AX, ret+16(FP)  // 交换后的 AX(old value) 写入 FP 返回值位
	RET

TEXT runtime∕internal∕atomic·Xchg64(SB), NOSPLIT, $0-24
	MOVQ	ptr+0(FP), BX
	MOVQ	new+8(FP), AX
	XCHGQ	AX, 0(BX)
	MOVQ	AX, ret+16(FP)
	RET

TEXT runtime∕internal∕atomic·Xchguintptr(SB), NOSPLIT, $0-24
	JMP	runtime∕internal∕atomic·Xchg64(SB)

TEXT runtime∕internal∕atomic·StorepNoWB(SB), NOSPLIT, $0-16
	MOVQ	ptr+0(FP), BX
	MOVQ	val+8(FP), AX
	XCHGQ	AX, 0(BX)
	RET

TEXT runtime∕internal∕atomic·Store(SB), NOSPLIT, $0-12
	MOVQ	ptr+0(FP), BX
	MOVL	val+8(FP), AX
	XCHGL	AX, 0(BX)   // 交换指令
	RET

TEXT runtime∕internal∕atomic·StoreRel(SB), NOSPLIT, $0-12
	JMP	runtime∕internal∕atomic·Store(SB)

TEXT runtime∕internal∕atomic·Store8(SB), NOSPLIT, $0-9
	MOVQ	ptr+0(FP), BX
	MOVB	val+8(FP), AX
	XCHGB	AX, 0(BX)
	RET

TEXT runtime∕internal∕atomic·Store64(SB), NOSPLIT, $0-16
	MOVQ	ptr+0(FP), BX
	MOVQ	val+8(FP), AX
	XCHGQ	AX, 0(BX)
	RET

// void	runtime∕internal∕atomic·Or8(byte volatile*, byte);
TEXT runtime∕internal∕atomic·Or8(SB), NOSPLIT, $0-9
	MOVQ	ptr+0(FP), AX
	MOVB	val+8(FP), BX
	LOCK
	ORB	BX, (AX)
	RET

// void	runtime∕internal∕atomic·And8(byte volatile*, byte);
TEXT runtime∕internal∕atomic·And8(SB), NOSPLIT, $0-9
	MOVQ	ptr+0(FP), AX
	MOVB	val+8(FP), BX
	LOCK
	ANDB	BX, (AX)
	RET
