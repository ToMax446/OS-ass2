
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	0c013103          	ld	sp,192(sp) # 800090c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	fee70713          	addi	a4,a4,-18 # 8000a040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	7cc78793          	addi	a5,a5,1996 # 80006830 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffde7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e0478793          	addi	a5,a5,-508 # 80000eb2 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	fe6080e7          	jalr	-26(ra) # 80003112 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	0000b517          	auipc	a0,0xb
    80000190:	ee450513          	addi	a0,a0,-284 # 8000b070 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000b497          	auipc	s1,0xb
    800001a0:	ed448493          	addi	s1,s1,-300 # 8000b070 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000b917          	auipc	s2,0xb
    800001aa:	f6290913          	addi	s2,s2,-158 # 8000b108 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	d00080e7          	jalr	-768(ra) # 80001ec4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	8bc080e7          	jalr	-1860(ra) # 80002a90 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	eac080e7          	jalr	-340(ra) # 800030bc <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	0000b517          	auipc	a0,0xb
    80000228:	e4c50513          	addi	a0,a0,-436 # 8000b070 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a7e080e7          	jalr	-1410(ra) # 80000caa <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000b517          	auipc	a0,0xb
    8000023e:	e3650513          	addi	a0,a0,-458 # 8000b070 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a68080e7          	jalr	-1432(ra) # 80000caa <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	0000b717          	auipc	a4,0xb
    80000276:	e8f72b23          	sw	a5,-362(a4) # 8000b108 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	0000b517          	auipc	a0,0xb
    800002d0:	da450513          	addi	a0,a0,-604 # 8000b070 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	e76080e7          	jalr	-394(ra) # 80003168 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000b517          	auipc	a0,0xb
    800002fe:	d7650513          	addi	a0,a0,-650 # 8000b070 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9a8080e7          	jalr	-1624(ra) # 80000caa <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	0000b717          	auipc	a4,0xb
    80000322:	d5270713          	addi	a4,a4,-686 # 8000b070 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	0000b797          	auipc	a5,0xb
    8000034c:	d2878793          	addi	a5,a5,-728 # 8000b070 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	0000b797          	auipc	a5,0xb
    8000037a:	d927a783          	lw	a5,-622(a5) # 8000b108 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000b717          	auipc	a4,0xb
    8000038e:	ce670713          	addi	a4,a4,-794 # 8000b070 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000b497          	auipc	s1,0xb
    8000039e:	cd648493          	addi	s1,s1,-810 # 8000b070 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	0000b717          	auipc	a4,0xb
    800003da:	c9a70713          	addi	a4,a4,-870 # 8000b070 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000b717          	auipc	a4,0xb
    800003f0:	d2f72223          	sw	a5,-732(a4) # 8000b110 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	0000b797          	auipc	a5,0xb
    80000416:	c5e78793          	addi	a5,a5,-930 # 8000b070 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	0000b797          	auipc	a5,0xb
    8000043a:	ccc7ab23          	sw	a2,-810(a5) # 8000b10c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000b517          	auipc	a0,0xb
    80000442:	cca50513          	addi	a0,a0,-822 # 8000b108 <cons+0x98>
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	87e080e7          	jalr	-1922(ra) # 80002cc4 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	0000b517          	auipc	a0,0xb
    80000464:	c1050513          	addi	a0,a0,-1008 # 8000b070 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001b797          	auipc	a5,0x1b
    8000047c:	27078793          	addi	a5,a5,624 # 8001b6e8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	0000b797          	auipc	a5,0xb
    8000054e:	be07a323          	sw	zero,-1050(a5) # 8000b130 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	e9c50513          	addi	a0,a0,-356 # 80008408 <digits+0x3c8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	0000a717          	auipc	a4,0xa
    80000582:	a8f72123          	sw	a5,-1406(a4) # 8000a000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	0000bd97          	auipc	s11,0xb
    800005be:	b76dad83          	lw	s11,-1162(s11) # 8000b130 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	0000b517          	auipc	a0,0xb
    800005fc:	b2050513          	addi	a0,a0,-1248 # 8000b118 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	0000b517          	auipc	a0,0xb
    80000760:	9bc50513          	addi	a0,a0,-1604 # 8000b118 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	546080e7          	jalr	1350(ra) # 80000caa <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	0000b497          	auipc	s1,0xb
    8000077c:	9a048493          	addi	s1,s1,-1632 # 8000b118 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	0000b517          	auipc	a0,0xb
    800007dc:	96050513          	addi	a0,a0,-1696 # 8000b138 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00009797          	auipc	a5,0x9
    80000808:	7fc7a783          	lw	a5,2044(a5) # 8000a000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	41c080e7          	jalr	1052(ra) # 80000c4a <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00009717          	auipc	a4,0x9
    80000844:	7c873703          	ld	a4,1992(a4) # 8000a008 <uart_tx_r>
    80000848:	00009797          	auipc	a5,0x9
    8000084c:	7c87b783          	ld	a5,1992(a5) # 8000a010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	0000ba17          	auipc	s4,0xb
    8000086e:	8cea0a13          	addi	s4,s4,-1842 # 8000b138 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00009497          	auipc	s1,0x9
    80000876:	79648493          	addi	s1,s1,1942 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00009997          	auipc	s3,0x9
    8000087e:	79698993          	addi	s3,s3,1942 # 8000a010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	424080e7          	jalr	1060(ra) # 80002cc4 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	0000b517          	auipc	a0,0xb
    800008e0:	85c50513          	addi	a0,a0,-1956 # 8000b138 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00009797          	auipc	a5,0x9
    800008f0:	7147a783          	lw	a5,1812(a5) # 8000a000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00009797          	auipc	a5,0x9
    800008fc:	7187b783          	ld	a5,1816(a5) # 8000a010 <uart_tx_w>
    80000900:	00009717          	auipc	a4,0x9
    80000904:	70873703          	ld	a4,1800(a4) # 8000a008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	0000ba17          	auipc	s4,0xb
    80000914:	828a0a13          	addi	s4,s4,-2008 # 8000b138 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	6f048493          	addi	s1,s1,1776 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	6f090913          	addi	s2,s2,1776 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	164080e7          	jalr	356(ra) # 80002a90 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	0000a497          	auipc	s1,0xa
    80000946:	7f648493          	addi	s1,s1,2038 # 8000b138 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00009717          	auipc	a4,0x9
    8000095a:	6af73d23          	sd	a5,1722(a4) # 8000a010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	342080e7          	jalr	834(ra) # 80000caa <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	0000a497          	auipc	s1,0xa
    800009ce:	76e48493          	addi	s1,s1,1902 # 8000b138 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2c4080e7          	jalr	708(ra) # 80000caa <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	0001f797          	auipc	a5,0x1f
    80000a10:	5f478793          	addi	a5,a5,1524 # 80020000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2e0080e7          	jalr	736(ra) # 80000d04 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	0000a917          	auipc	s2,0xa
    80000a30:	74490913          	addi	s2,s2,1860 # 8000b170 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	260080e7          	jalr	608(ra) # 80000caa <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	0000a517          	auipc	a0,0xa
    80000acc:	6a850513          	addi	a0,a0,1704 # 8000b170 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	0001f517          	auipc	a0,0x1f
    80000ae0:	52450513          	addi	a0,a0,1316 # 80020000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	0000a497          	auipc	s1,0xa
    80000b02:	67248493          	addi	s1,s1,1650 # 8000b170 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	0000a517          	auipc	a0,0xa
    80000b1a:	65a50513          	addi	a0,a0,1626 # 8000b170 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	18a080e7          	jalr	394(ra) # 80000caa <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1d6080e7          	jalr	470(ra) # 80000d04 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	0000a517          	auipc	a0,0xa
    80000b46:	62e50513          	addi	a0,a0,1582 # 8000b170 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	160080e7          	jalr	352(ra) # 80000caa <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	32a080e7          	jalr	810(ra) # 80001ea8 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	2f8080e7          	jalr	760(ra) # 80001ea8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	2ec080e7          	jalr	748(ra) # 80001ea8 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	2d4080e7          	jalr	724(ra) # 80001ea8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk)){
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk)){
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	294080e7          	jalr	660(ra) # 80001ea8 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    printf("lk is %s\n", lk->name);
    80000c28:	648c                	ld	a1,8(s1)
    80000c2a:	00007517          	auipc	a0,0x7
    80000c2e:	44650513          	addi	a0,a0,1094 # 80008070 <digits+0x30>
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	956080e7          	jalr	-1706(ra) # 80000588 <printf>
    panic("acquire");
    80000c3a:	00007517          	auipc	a0,0x7
    80000c3e:	44650513          	addi	a0,a0,1094 # 80008080 <digits+0x40>
    80000c42:	00000097          	auipc	ra,0x0
    80000c46:	8fc080e7          	jalr	-1796(ra) # 8000053e <panic>

0000000080000c4a <pop_off>:

void
pop_off(void)
{
    80000c4a:	1141                	addi	sp,sp,-16
    80000c4c:	e406                	sd	ra,8(sp)
    80000c4e:	e022                	sd	s0,0(sp)
    80000c50:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	256080e7          	jalr	598(ra) # 80001ea8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c5e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c60:	e78d                	bnez	a5,80000c8a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c62:	5d3c                	lw	a5,120(a0)
    80000c64:	02f05b63          	blez	a5,80000c9a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c68:	37fd                	addiw	a5,a5,-1
    80000c6a:	0007871b          	sext.w	a4,a5
    80000c6e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c70:	eb09                	bnez	a4,80000c82 <pop_off+0x38>
    80000c72:	5d7c                	lw	a5,124(a0)
    80000c74:	c799                	beqz	a5,80000c82 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c7e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c82:	60a2                	ld	ra,8(sp)
    80000c84:	6402                	ld	s0,0(sp)
    80000c86:	0141                	addi	sp,sp,16
    80000c88:	8082                	ret
    panic("pop_off - interruptible");
    80000c8a:	00007517          	auipc	a0,0x7
    80000c8e:	3fe50513          	addi	a0,a0,1022 # 80008088 <digits+0x48>
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	8ac080e7          	jalr	-1876(ra) # 8000053e <panic>
    panic("pop_off");
    80000c9a:	00007517          	auipc	a0,0x7
    80000c9e:	40650513          	addi	a0,a0,1030 # 800080a0 <digits+0x60>
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>

0000000080000caa <release>:
{
    80000caa:	1101                	addi	sp,sp,-32
    80000cac:	ec06                	sd	ra,24(sp)
    80000cae:	e822                	sd	s0,16(sp)
    80000cb0:	e426                	sd	s1,8(sp)
    80000cb2:	1000                	addi	s0,sp,32
    80000cb4:	84aa                	mv	s1,a0
  if(!holding(lk)){
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	eb4080e7          	jalr	-332(ra) # 80000b6a <holding>
    80000cbe:	c115                	beqz	a0,80000ce2 <release+0x38>
  lk->cpu = 0;
    80000cc0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cc4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cc8:	0f50000f          	fence	iorw,ow
    80000ccc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	f7a080e7          	jalr	-134(ra) # 80000c4a <pop_off>
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    printf("the paniced lock is %s\n", lk->name);
    80000ce2:	648c                	ld	a1,8(s1)
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	3c450513          	addi	a0,a0,964 # 800080a8 <digits+0x68>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	89c080e7          	jalr	-1892(ra) # 80000588 <printf>
    panic("release");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	3cc50513          	addi	a0,a0,972 # 800080c0 <digits+0x80>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>

0000000080000d04 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d04:	1141                	addi	sp,sp,-16
    80000d06:	e422                	sd	s0,8(sp)
    80000d08:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d0a:	ce09                	beqz	a2,80000d24 <memset+0x20>
    80000d0c:	87aa                	mv	a5,a0
    80000d0e:	fff6071b          	addiw	a4,a2,-1
    80000d12:	1702                	slli	a4,a4,0x20
    80000d14:	9301                	srli	a4,a4,0x20
    80000d16:	0705                	addi	a4,a4,1
    80000d18:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d1a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d1e:	0785                	addi	a5,a5,1
    80000d20:	fee79de3          	bne	a5,a4,80000d1a <memset+0x16>
  }
  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret

0000000080000d2a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d30:	ca05                	beqz	a2,80000d60 <memcmp+0x36>
    80000d32:	fff6069b          	addiw	a3,a2,-1
    80000d36:	1682                	slli	a3,a3,0x20
    80000d38:	9281                	srli	a3,a3,0x20
    80000d3a:	0685                	addi	a3,a3,1
    80000d3c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d3e:	00054783          	lbu	a5,0(a0)
    80000d42:	0005c703          	lbu	a4,0(a1)
    80000d46:	00e79863          	bne	a5,a4,80000d56 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d4a:	0505                	addi	a0,a0,1
    80000d4c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d4e:	fed518e3          	bne	a0,a3,80000d3e <memcmp+0x14>
  }

  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	a019                	j	80000d5a <memcmp+0x30>
      return *s1 - *s2;
    80000d56:	40e7853b          	subw	a0,a5,a4
}
    80000d5a:	6422                	ld	s0,8(sp)
    80000d5c:	0141                	addi	sp,sp,16
    80000d5e:	8082                	ret
  return 0;
    80000d60:	4501                	li	a0,0
    80000d62:	bfe5                	j	80000d5a <memcmp+0x30>

0000000080000d64 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d64:	1141                	addi	sp,sp,-16
    80000d66:	e422                	sd	s0,8(sp)
    80000d68:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d6a:	ca0d                	beqz	a2,80000d9c <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d6c:	00a5f963          	bgeu	a1,a0,80000d7e <memmove+0x1a>
    80000d70:	02061693          	slli	a3,a2,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	00d58733          	add	a4,a1,a3
    80000d7a:	02e56463          	bltu	a0,a4,80000da2 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d7e:	fff6079b          	addiw	a5,a2,-1
    80000d82:	1782                	slli	a5,a5,0x20
    80000d84:	9381                	srli	a5,a5,0x20
    80000d86:	0785                	addi	a5,a5,1
    80000d88:	97ae                	add	a5,a5,a1
    80000d8a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d8c:	0585                	addi	a1,a1,1
    80000d8e:	0705                	addi	a4,a4,1
    80000d90:	fff5c683          	lbu	a3,-1(a1)
    80000d94:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d98:	fef59ae3          	bne	a1,a5,80000d8c <memmove+0x28>

  return dst;
}
    80000d9c:	6422                	ld	s0,8(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    d += n;
    80000da2:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000da4:	fff6079b          	addiw	a5,a2,-1
    80000da8:	1782                	slli	a5,a5,0x20
    80000daa:	9381                	srli	a5,a5,0x20
    80000dac:	fff7c793          	not	a5,a5
    80000db0:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000db2:	177d                	addi	a4,a4,-1
    80000db4:	16fd                	addi	a3,a3,-1
    80000db6:	00074603          	lbu	a2,0(a4)
    80000dba:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dbe:	fef71ae3          	bne	a4,a5,80000db2 <memmove+0x4e>
    80000dc2:	bfe9                	j	80000d9c <memmove+0x38>

0000000080000dc4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dc4:	1141                	addi	sp,sp,-16
    80000dc6:	e406                	sd	ra,8(sp)
    80000dc8:	e022                	sd	s0,0(sp)
    80000dca:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dcc:	00000097          	auipc	ra,0x0
    80000dd0:	f98080e7          	jalr	-104(ra) # 80000d64 <memmove>
}
    80000dd4:	60a2                	ld	ra,8(sp)
    80000dd6:	6402                	ld	s0,0(sp)
    80000dd8:	0141                	addi	sp,sp,16
    80000dda:	8082                	ret

0000000080000ddc <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ddc:	1141                	addi	sp,sp,-16
    80000dde:	e422                	sd	s0,8(sp)
    80000de0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000de2:	ce11                	beqz	a2,80000dfe <strncmp+0x22>
    80000de4:	00054783          	lbu	a5,0(a0)
    80000de8:	cf89                	beqz	a5,80000e02 <strncmp+0x26>
    80000dea:	0005c703          	lbu	a4,0(a1)
    80000dee:	00f71a63          	bne	a4,a5,80000e02 <strncmp+0x26>
    n--, p++, q++;
    80000df2:	367d                	addiw	a2,a2,-1
    80000df4:	0505                	addi	a0,a0,1
    80000df6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000df8:	f675                	bnez	a2,80000de4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dfa:	4501                	li	a0,0
    80000dfc:	a809                	j	80000e0e <strncmp+0x32>
    80000dfe:	4501                	li	a0,0
    80000e00:	a039                	j	80000e0e <strncmp+0x32>
  if(n == 0)
    80000e02:	ca09                	beqz	a2,80000e14 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e04:	00054503          	lbu	a0,0(a0)
    80000e08:	0005c783          	lbu	a5,0(a1)
    80000e0c:	9d1d                	subw	a0,a0,a5
}
    80000e0e:	6422                	ld	s0,8(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret
    return 0;
    80000e14:	4501                	li	a0,0
    80000e16:	bfe5                	j	80000e0e <strncmp+0x32>

0000000080000e18 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e18:	1141                	addi	sp,sp,-16
    80000e1a:	e422                	sd	s0,8(sp)
    80000e1c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e1e:	872a                	mv	a4,a0
    80000e20:	8832                	mv	a6,a2
    80000e22:	367d                	addiw	a2,a2,-1
    80000e24:	01005963          	blez	a6,80000e36 <strncpy+0x1e>
    80000e28:	0705                	addi	a4,a4,1
    80000e2a:	0005c783          	lbu	a5,0(a1)
    80000e2e:	fef70fa3          	sb	a5,-1(a4)
    80000e32:	0585                	addi	a1,a1,1
    80000e34:	f7f5                	bnez	a5,80000e20 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e36:	00c05d63          	blez	a2,80000e50 <strncpy+0x38>
    80000e3a:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e3c:	0685                	addi	a3,a3,1
    80000e3e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e42:	fff6c793          	not	a5,a3
    80000e46:	9fb9                	addw	a5,a5,a4
    80000e48:	010787bb          	addw	a5,a5,a6
    80000e4c:	fef048e3          	bgtz	a5,80000e3c <strncpy+0x24>
  return os;
}
    80000e50:	6422                	ld	s0,8(sp)
    80000e52:	0141                	addi	sp,sp,16
    80000e54:	8082                	ret

0000000080000e56 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e56:	1141                	addi	sp,sp,-16
    80000e58:	e422                	sd	s0,8(sp)
    80000e5a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e5c:	02c05363          	blez	a2,80000e82 <safestrcpy+0x2c>
    80000e60:	fff6069b          	addiw	a3,a2,-1
    80000e64:	1682                	slli	a3,a3,0x20
    80000e66:	9281                	srli	a3,a3,0x20
    80000e68:	96ae                	add	a3,a3,a1
    80000e6a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e6c:	00d58963          	beq	a1,a3,80000e7e <safestrcpy+0x28>
    80000e70:	0585                	addi	a1,a1,1
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff5c703          	lbu	a4,-1(a1)
    80000e78:	fee78fa3          	sb	a4,-1(a5)
    80000e7c:	fb65                	bnez	a4,80000e6c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e7e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e82:	6422                	ld	s0,8(sp)
    80000e84:	0141                	addi	sp,sp,16
    80000e86:	8082                	ret

0000000080000e88 <strlen>:

int
strlen(const char *s)
{
    80000e88:	1141                	addi	sp,sp,-16
    80000e8a:	e422                	sd	s0,8(sp)
    80000e8c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e8e:	00054783          	lbu	a5,0(a0)
    80000e92:	cf91                	beqz	a5,80000eae <strlen+0x26>
    80000e94:	0505                	addi	a0,a0,1
    80000e96:	87aa                	mv	a5,a0
    80000e98:	4685                	li	a3,1
    80000e9a:	9e89                	subw	a3,a3,a0
    80000e9c:	00f6853b          	addw	a0,a3,a5
    80000ea0:	0785                	addi	a5,a5,1
    80000ea2:	fff7c703          	lbu	a4,-1(a5)
    80000ea6:	fb7d                	bnez	a4,80000e9c <strlen+0x14>
    ;
  return n;
}
    80000ea8:	6422                	ld	s0,8(sp)
    80000eaa:	0141                	addi	sp,sp,16
    80000eac:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eae:	4501                	li	a0,0
    80000eb0:	bfe5                	j	80000ea8 <strlen+0x20>

0000000080000eb2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eb2:	1141                	addi	sp,sp,-16
    80000eb4:	e406                	sd	ra,8(sp)
    80000eb6:	e022                	sd	s0,0(sp)
    80000eb8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eba:	00001097          	auipc	ra,0x1
    80000ebe:	fde080e7          	jalr	-34(ra) # 80001e98 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ec2:	00009717          	auipc	a4,0x9
    80000ec6:	15670713          	addi	a4,a4,342 # 8000a018 <started>
  if(cpuid() == 0){
    80000eca:	c139                	beqz	a0,80000f10 <main+0x5e>
    while(started == 0)
    80000ecc:	431c                	lw	a5,0(a4)
    80000ece:	2781                	sext.w	a5,a5
    80000ed0:	dff5                	beqz	a5,80000ecc <main+0x1a>
      ;
    __sync_synchronize();
    80000ed2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed6:	00001097          	auipc	ra,0x1
    80000eda:	fc2080e7          	jalr	-62(ra) # 80001e98 <cpuid>
    80000ede:	85aa                	mv	a1,a0
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	20050513          	addi	a0,a0,512 # 800080e0 <digits+0xa0>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	6a0080e7          	jalr	1696(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ef0:	00000097          	auipc	ra,0x0
    80000ef4:	0d8080e7          	jalr	216(ra) # 80000fc8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef8:	00002097          	auipc	ra,0x2
    80000efc:	41e080e7          	jalr	1054(ra) # 80003316 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00006097          	auipc	ra,0x6
    80000f04:	970080e7          	jalr	-1680(ra) # 80006870 <plicinithart>
  }

  scheduler();        
    80000f08:	00002097          	auipc	ra,0x2
    80000f0c:	840080e7          	jalr	-1984(ra) # 80002748 <scheduler>
    consoleinit();
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	540080e7          	jalr	1344(ra) # 80000450 <consoleinit>
    printfinit();
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	856080e7          	jalr	-1962(ra) # 8000076e <printfinit>
    printf("\n");
    80000f20:	00007517          	auipc	a0,0x7
    80000f24:	4e850513          	addi	a0,a0,1256 # 80008408 <digits+0x3c8>
    80000f28:	fffff097          	auipc	ra,0xfffff
    80000f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	19850513          	addi	a0,a0,408 # 800080c8 <digits+0x88>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	4c850513          	addi	a0,a0,1224 # 80008408 <digits+0x3c8>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	640080e7          	jalr	1600(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f50:	00000097          	auipc	ra,0x0
    80000f54:	b68080e7          	jalr	-1176(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	322080e7          	jalr	802(ra) # 8000127a <kvminit>
    kvminithart();   // turn on paging
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	068080e7          	jalr	104(ra) # 80000fc8 <kvminithart>
    procinit();      // process table
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	d5c080e7          	jalr	-676(ra) # 80001cc4 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	37e080e7          	jalr	894(ra) # 800032ee <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	39e080e7          	jalr	926(ra) # 80003316 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00006097          	auipc	ra,0x6
    80000f84:	8da080e7          	jalr	-1830(ra) # 8000685a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00006097          	auipc	ra,0x6
    80000f8c:	8e8080e7          	jalr	-1816(ra) # 80006870 <plicinithart>
    binit();         // buffer cache
    80000f90:	00003097          	auipc	ra,0x3
    80000f94:	ac8080e7          	jalr	-1336(ra) # 80003a58 <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	158080e7          	jalr	344(ra) # 800040f0 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	102080e7          	jalr	258(ra) # 800050a2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00006097          	auipc	ra,0x6
    80000fac:	9ea080e7          	jalr	-1558(ra) # 80006992 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	3b0080e7          	jalr	944(ra) # 80002360 <userinit>
    __sync_synchronize();
    80000fb8:	0ff0000f          	fence
    started = 1;
    80000fbc:	4785                	li	a5,1
    80000fbe:	00009717          	auipc	a4,0x9
    80000fc2:	04f72d23          	sw	a5,90(a4) # 8000a018 <started>
    80000fc6:	b789                	j	80000f08 <main+0x56>

0000000080000fc8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc8:	1141                	addi	sp,sp,-16
    80000fca:	e422                	sd	s0,8(sp)
    80000fcc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fce:	00009797          	auipc	a5,0x9
    80000fd2:	0527b783          	ld	a5,82(a5) # 8000a020 <kernel_pagetable>
    80000fd6:	83b1                	srli	a5,a5,0xc
    80000fd8:	577d                	li	a4,-1
    80000fda:	177e                	slli	a4,a4,0x3f
    80000fdc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fde:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fe2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe6:	6422                	ld	s0,8(sp)
    80000fe8:	0141                	addi	sp,sp,16
    80000fea:	8082                	ret

0000000080000fec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fec:	7139                	addi	sp,sp,-64
    80000fee:	fc06                	sd	ra,56(sp)
    80000ff0:	f822                	sd	s0,48(sp)
    80000ff2:	f426                	sd	s1,40(sp)
    80000ff4:	f04a                	sd	s2,32(sp)
    80000ff6:	ec4e                	sd	s3,24(sp)
    80000ff8:	e852                	sd	s4,16(sp)
    80000ffa:	e456                	sd	s5,8(sp)
    80000ffc:	e05a                	sd	s6,0(sp)
    80000ffe:	0080                	addi	s0,sp,64
    80001000:	84aa                	mv	s1,a0
    80001002:	89ae                	mv	s3,a1
    80001004:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001006:	57fd                	li	a5,-1
    80001008:	83e9                	srli	a5,a5,0x1a
    8000100a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000100c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100e:	04b7f263          	bgeu	a5,a1,80001052 <walk+0x66>
    panic("walk");
    80001012:	00007517          	auipc	a0,0x7
    80001016:	0e650513          	addi	a0,a0,230 # 800080f8 <digits+0xb8>
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	524080e7          	jalr	1316(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001022:	060a8663          	beqz	s5,8000108e <walk+0xa2>
    80001026:	00000097          	auipc	ra,0x0
    8000102a:	ace080e7          	jalr	-1330(ra) # 80000af4 <kalloc>
    8000102e:	84aa                	mv	s1,a0
    80001030:	c529                	beqz	a0,8000107a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001032:	6605                	lui	a2,0x1
    80001034:	4581                	li	a1,0
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	cce080e7          	jalr	-818(ra) # 80000d04 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103e:	00c4d793          	srli	a5,s1,0xc
    80001042:	07aa                	slli	a5,a5,0xa
    80001044:	0017e793          	ori	a5,a5,1
    80001048:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000104c:	3a5d                	addiw	s4,s4,-9
    8000104e:	036a0063          	beq	s4,s6,8000106e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001052:	0149d933          	srl	s2,s3,s4
    80001056:	1ff97913          	andi	s2,s2,511
    8000105a:	090e                	slli	s2,s2,0x3
    8000105c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105e:	00093483          	ld	s1,0(s2)
    80001062:	0014f793          	andi	a5,s1,1
    80001066:	dfd5                	beqz	a5,80001022 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001068:	80a9                	srli	s1,s1,0xa
    8000106a:	04b2                	slli	s1,s1,0xc
    8000106c:	b7c5                	j	8000104c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106e:	00c9d513          	srli	a0,s3,0xc
    80001072:	1ff57513          	andi	a0,a0,511
    80001076:	050e                	slli	a0,a0,0x3
    80001078:	9526                	add	a0,a0,s1
}
    8000107a:	70e2                	ld	ra,56(sp)
    8000107c:	7442                	ld	s0,48(sp)
    8000107e:	74a2                	ld	s1,40(sp)
    80001080:	7902                	ld	s2,32(sp)
    80001082:	69e2                	ld	s3,24(sp)
    80001084:	6a42                	ld	s4,16(sp)
    80001086:	6aa2                	ld	s5,8(sp)
    80001088:	6b02                	ld	s6,0(sp)
    8000108a:	6121                	addi	sp,sp,64
    8000108c:	8082                	ret
        return 0;
    8000108e:	4501                	li	a0,0
    80001090:	b7ed                	j	8000107a <walk+0x8e>

0000000080001092 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001092:	57fd                	li	a5,-1
    80001094:	83e9                	srli	a5,a5,0x1a
    80001096:	00b7f463          	bgeu	a5,a1,8000109e <walkaddr+0xc>
    return 0;
    8000109a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000109c:	8082                	ret
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a6:	4601                	li	a2,0
    800010a8:	00000097          	auipc	ra,0x0
    800010ac:	f44080e7          	jalr	-188(ra) # 80000fec <walk>
  if(pte == 0)
    800010b0:	c105                	beqz	a0,800010d0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010b2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b4:	0117f693          	andi	a3,a5,17
    800010b8:	4745                	li	a4,17
    return 0;
    800010ba:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010bc:	00e68663          	beq	a3,a4,800010c8 <walkaddr+0x36>
}
    800010c0:	60a2                	ld	ra,8(sp)
    800010c2:	6402                	ld	s0,0(sp)
    800010c4:	0141                	addi	sp,sp,16
    800010c6:	8082                	ret
  pa = PTE2PA(*pte);
    800010c8:	00a7d513          	srli	a0,a5,0xa
    800010cc:	0532                	slli	a0,a0,0xc
  return pa;
    800010ce:	bfcd                	j	800010c0 <walkaddr+0x2e>
    return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7fd                	j	800010c0 <walkaddr+0x2e>

00000000800010d4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d4:	715d                	addi	sp,sp,-80
    800010d6:	e486                	sd	ra,72(sp)
    800010d8:	e0a2                	sd	s0,64(sp)
    800010da:	fc26                	sd	s1,56(sp)
    800010dc:	f84a                	sd	s2,48(sp)
    800010de:	f44e                	sd	s3,40(sp)
    800010e0:	f052                	sd	s4,32(sp)
    800010e2:	ec56                	sd	s5,24(sp)
    800010e4:	e85a                	sd	s6,16(sp)
    800010e6:	e45e                	sd	s7,8(sp)
    800010e8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ea:	c205                	beqz	a2,8000110a <mappages+0x36>
    800010ec:	8aaa                	mv	s5,a0
    800010ee:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010f0:	77fd                	lui	a5,0xfffff
    800010f2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010f6:	15fd                	addi	a1,a1,-1
    800010f8:	00c589b3          	add	s3,a1,a2
    800010fc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001100:	8952                	mv	s2,s4
    80001102:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001106:	6b85                	lui	s7,0x1
    80001108:	a015                	j	8000112c <mappages+0x58>
    panic("mappages: size");
    8000110a:	00007517          	auipc	a0,0x7
    8000110e:	ff650513          	addi	a0,a0,-10 # 80008100 <digits+0xc0>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000111a:	00007517          	auipc	a0,0x7
    8000111e:	ff650513          	addi	a0,a0,-10 # 80008110 <digits+0xd0>
    80001122:	fffff097          	auipc	ra,0xfffff
    80001126:	41c080e7          	jalr	1052(ra) # 8000053e <panic>
    a += PGSIZE;
    8000112a:	995e                	add	s2,s2,s7
  for(;;){
    8000112c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	4605                	li	a2,1
    80001132:	85ca                	mv	a1,s2
    80001134:	8556                	mv	a0,s5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	eb6080e7          	jalr	-330(ra) # 80000fec <walk>
    8000113e:	cd19                	beqz	a0,8000115c <mappages+0x88>
    if(*pte & PTE_V)
    80001140:	611c                	ld	a5,0(a0)
    80001142:	8b85                	andi	a5,a5,1
    80001144:	fbf9                	bnez	a5,8000111a <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001146:	80b1                	srli	s1,s1,0xc
    80001148:	04aa                	slli	s1,s1,0xa
    8000114a:	0164e4b3          	or	s1,s1,s6
    8000114e:	0014e493          	ori	s1,s1,1
    80001152:	e104                	sd	s1,0(a0)
    if(a == last)
    80001154:	fd391be3          	bne	s2,s3,8000112a <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001158:	4501                	li	a0,0
    8000115a:	a011                	j	8000115e <mappages+0x8a>
      return -1;
    8000115c:	557d                	li	a0,-1
}
    8000115e:	60a6                	ld	ra,72(sp)
    80001160:	6406                	ld	s0,64(sp)
    80001162:	74e2                	ld	s1,56(sp)
    80001164:	7942                	ld	s2,48(sp)
    80001166:	79a2                	ld	s3,40(sp)
    80001168:	7a02                	ld	s4,32(sp)
    8000116a:	6ae2                	ld	s5,24(sp)
    8000116c:	6b42                	ld	s6,16(sp)
    8000116e:	6ba2                	ld	s7,8(sp)
    80001170:	6161                	addi	sp,sp,80
    80001172:	8082                	ret

0000000080001174 <kvmmap>:
{
    80001174:	1141                	addi	sp,sp,-16
    80001176:	e406                	sd	ra,8(sp)
    80001178:	e022                	sd	s0,0(sp)
    8000117a:	0800                	addi	s0,sp,16
    8000117c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000117e:	86b2                	mv	a3,a2
    80001180:	863e                	mv	a2,a5
    80001182:	00000097          	auipc	ra,0x0
    80001186:	f52080e7          	jalr	-174(ra) # 800010d4 <mappages>
    8000118a:	e509                	bnez	a0,80001194 <kvmmap+0x20>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret
    panic("kvmmap");
    80001194:	00007517          	auipc	a0,0x7
    80001198:	f8c50513          	addi	a0,a0,-116 # 80008120 <digits+0xe0>
    8000119c:	fffff097          	auipc	ra,0xfffff
    800011a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>

00000000800011a4 <kvmmake>:
{
    800011a4:	1101                	addi	sp,sp,-32
    800011a6:	ec06                	sd	ra,24(sp)
    800011a8:	e822                	sd	s0,16(sp)
    800011aa:	e426                	sd	s1,8(sp)
    800011ac:	e04a                	sd	s2,0(sp)
    800011ae:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	944080e7          	jalr	-1724(ra) # 80000af4 <kalloc>
    800011b8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ba:	6605                	lui	a2,0x1
    800011bc:	4581                	li	a1,0
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	b46080e7          	jalr	-1210(ra) # 80000d04 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10000637          	lui	a2,0x10000
    800011ce:	100005b7          	lui	a1,0x10000
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	fa0080e7          	jalr	-96(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10001637          	lui	a2,0x10001
    800011e4:	100015b7          	lui	a1,0x10001
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f8a080e7          	jalr	-118(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	004006b7          	lui	a3,0x400
    800011f8:	0c000637          	lui	a2,0xc000
    800011fc:	0c0005b7          	lui	a1,0xc000
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f72080e7          	jalr	-142(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000120a:	00007917          	auipc	s2,0x7
    8000120e:	df690913          	addi	s2,s2,-522 # 80008000 <etext>
    80001212:	4729                	li	a4,10
    80001214:	80007697          	auipc	a3,0x80007
    80001218:	dec68693          	addi	a3,a3,-532 # 8000 <_entry-0x7fff8000>
    8000121c:	4605                	li	a2,1
    8000121e:	067e                	slli	a2,a2,0x1f
    80001220:	85b2                	mv	a1,a2
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f50080e7          	jalr	-176(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000122c:	4719                	li	a4,6
    8000122e:	46c5                	li	a3,17
    80001230:	06ee                	slli	a3,a3,0x1b
    80001232:	412686b3          	sub	a3,a3,s2
    80001236:	864a                	mv	a2,s2
    80001238:	85ca                	mv	a1,s2
    8000123a:	8526                	mv	a0,s1
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	f38080e7          	jalr	-200(ra) # 80001174 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001244:	4729                	li	a4,10
    80001246:	6685                	lui	a3,0x1
    80001248:	00006617          	auipc	a2,0x6
    8000124c:	db860613          	addi	a2,a2,-584 # 80007000 <_trampoline>
    80001250:	040005b7          	lui	a1,0x4000
    80001254:	15fd                	addi	a1,a1,-1
    80001256:	05b2                	slli	a1,a1,0xc
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f1a080e7          	jalr	-230(ra) # 80001174 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001262:	8526                	mv	a0,s1
    80001264:	00001097          	auipc	ra,0x1
    80001268:	9ca080e7          	jalr	-1590(ra) # 80001c2e <proc_mapstacks>
}
    8000126c:	8526                	mv	a0,s1
    8000126e:	60e2                	ld	ra,24(sp)
    80001270:	6442                	ld	s0,16(sp)
    80001272:	64a2                	ld	s1,8(sp)
    80001274:	6902                	ld	s2,0(sp)
    80001276:	6105                	addi	sp,sp,32
    80001278:	8082                	ret

000000008000127a <kvminit>:
{
    8000127a:	1141                	addi	sp,sp,-16
    8000127c:	e406                	sd	ra,8(sp)
    8000127e:	e022                	sd	s0,0(sp)
    80001280:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f22080e7          	jalr	-222(ra) # 800011a4 <kvmmake>
    8000128a:	00009797          	auipc	a5,0x9
    8000128e:	d8a7bb23          	sd	a0,-618(a5) # 8000a020 <kernel_pagetable>
}
    80001292:	60a2                	ld	ra,8(sp)
    80001294:	6402                	ld	s0,0(sp)
    80001296:	0141                	addi	sp,sp,16
    80001298:	8082                	ret

000000008000129a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000129a:	715d                	addi	sp,sp,-80
    8000129c:	e486                	sd	ra,72(sp)
    8000129e:	e0a2                	sd	s0,64(sp)
    800012a0:	fc26                	sd	s1,56(sp)
    800012a2:	f84a                	sd	s2,48(sp)
    800012a4:	f44e                	sd	s3,40(sp)
    800012a6:	f052                	sd	s4,32(sp)
    800012a8:	ec56                	sd	s5,24(sp)
    800012aa:	e85a                	sd	s6,16(sp)
    800012ac:	e45e                	sd	s7,8(sp)
    800012ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b0:	03459793          	slli	a5,a1,0x34
    800012b4:	e795                	bnez	a5,800012e0 <uvmunmap+0x46>
    800012b6:	8a2a                	mv	s4,a0
    800012b8:	892e                	mv	s2,a1
    800012ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012bc:	0632                	slli	a2,a2,0xc
    800012be:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c4:	6b05                	lui	s6,0x1
    800012c6:	0735e863          	bltu	a1,s3,80001336 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ca:	60a6                	ld	ra,72(sp)
    800012cc:	6406                	ld	s0,64(sp)
    800012ce:	74e2                	ld	s1,56(sp)
    800012d0:	7942                	ld	s2,48(sp)
    800012d2:	79a2                	ld	s3,40(sp)
    800012d4:	7a02                	ld	s4,32(sp)
    800012d6:	6ae2                	ld	s5,24(sp)
    800012d8:	6b42                	ld	s6,16(sp)
    800012da:	6ba2                	ld	s7,8(sp)
    800012dc:	6161                	addi	sp,sp,80
    800012de:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e0:	00007517          	auipc	a0,0x7
    800012e4:	e4850513          	addi	a0,a0,-440 # 80008128 <digits+0xe8>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e5050513          	addi	a0,a0,-432 # 80008140 <digits+0x100>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e5050513          	addi	a0,a0,-432 # 80008150 <digits+0x110>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	236080e7          	jalr	566(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e5850513          	addi	a0,a0,-424 # 80008168 <digits+0x128>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	226080e7          	jalr	550(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001320:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001322:	0532                	slli	a0,a0,0xc
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	6d4080e7          	jalr	1748(ra) # 800009f8 <kfree>
    *pte = 0;
    8000132c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001330:	995a                	add	s2,s2,s6
    80001332:	f9397ce3          	bgeu	s2,s3,800012ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001336:	4601                	li	a2,0
    80001338:	85ca                	mv	a1,s2
    8000133a:	8552                	mv	a0,s4
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	cb0080e7          	jalr	-848(ra) # 80000fec <walk>
    80001344:	84aa                	mv	s1,a0
    80001346:	d54d                	beqz	a0,800012f0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001348:	6108                	ld	a0,0(a0)
    8000134a:	00157793          	andi	a5,a0,1
    8000134e:	dbcd                	beqz	a5,80001300 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001350:	3ff57793          	andi	a5,a0,1023
    80001354:	fb778ee3          	beq	a5,s7,80001310 <uvmunmap+0x76>
    if(do_free){
    80001358:	fc0a8ae3          	beqz	s5,8000132c <uvmunmap+0x92>
    8000135c:	b7d1                	j	80001320 <uvmunmap+0x86>

000000008000135e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135e:	1101                	addi	sp,sp,-32
    80001360:	ec06                	sd	ra,24(sp)
    80001362:	e822                	sd	s0,16(sp)
    80001364:	e426                	sd	s1,8(sp)
    80001366:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	78c080e7          	jalr	1932(ra) # 80000af4 <kalloc>
    80001370:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001372:	c519                	beqz	a0,80001380 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	98c080e7          	jalr	-1652(ra) # 80000d04 <memset>
  return pagetable;
}
    80001380:	8526                	mv	a0,s1
    80001382:	60e2                	ld	ra,24(sp)
    80001384:	6442                	ld	s0,16(sp)
    80001386:	64a2                	ld	s1,8(sp)
    80001388:	6105                	addi	sp,sp,32
    8000138a:	8082                	ret

000000008000138c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138c:	7179                	addi	sp,sp,-48
    8000138e:	f406                	sd	ra,40(sp)
    80001390:	f022                	sd	s0,32(sp)
    80001392:	ec26                	sd	s1,24(sp)
    80001394:	e84a                	sd	s2,16(sp)
    80001396:	e44e                	sd	s3,8(sp)
    80001398:	e052                	sd	s4,0(sp)
    8000139a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139c:	6785                	lui	a5,0x1
    8000139e:	04f67863          	bgeu	a2,a5,800013ee <uvminit+0x62>
    800013a2:	8a2a                	mv	s4,a0
    800013a4:	89ae                	mv	s3,a1
    800013a6:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	74c080e7          	jalr	1868(ra) # 80000af4 <kalloc>
    800013b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b2:	6605                	lui	a2,0x1
    800013b4:	4581                	li	a1,0
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	94e080e7          	jalr	-1714(ra) # 80000d04 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013be:	4779                	li	a4,30
    800013c0:	86ca                	mv	a3,s2
    800013c2:	6605                	lui	a2,0x1
    800013c4:	4581                	li	a1,0
    800013c6:	8552                	mv	a0,s4
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	d0c080e7          	jalr	-756(ra) # 800010d4 <mappages>
  memmove(mem, src, sz);
    800013d0:	8626                	mv	a2,s1
    800013d2:	85ce                	mv	a1,s3
    800013d4:	854a                	mv	a0,s2
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	98e080e7          	jalr	-1650(ra) # 80000d64 <memmove>
}
    800013de:	70a2                	ld	ra,40(sp)
    800013e0:	7402                	ld	s0,32(sp)
    800013e2:	64e2                	ld	s1,24(sp)
    800013e4:	6942                	ld	s2,16(sp)
    800013e6:	69a2                	ld	s3,8(sp)
    800013e8:	6a02                	ld	s4,0(sp)
    800013ea:	6145                	addi	sp,sp,48
    800013ec:	8082                	ret
    panic("inituvm: more than a page");
    800013ee:	00007517          	auipc	a0,0x7
    800013f2:	d9250513          	addi	a0,a0,-622 # 80008180 <digits+0x140>
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	148080e7          	jalr	328(ra) # 8000053e <panic>

00000000800013fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001408:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000140a:	00b67d63          	bgeu	a2,a1,80001424 <uvmdealloc+0x26>
    8000140e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001410:	6785                	lui	a5,0x1
    80001412:	17fd                	addi	a5,a5,-1
    80001414:	00f60733          	add	a4,a2,a5
    80001418:	767d                	lui	a2,0xfffff
    8000141a:	8f71                	and	a4,a4,a2
    8000141c:	97ae                	add	a5,a5,a1
    8000141e:	8ff1                	and	a5,a5,a2
    80001420:	00f76863          	bltu	a4,a5,80001430 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001424:	8526                	mv	a0,s1
    80001426:	60e2                	ld	ra,24(sp)
    80001428:	6442                	ld	s0,16(sp)
    8000142a:	64a2                	ld	s1,8(sp)
    8000142c:	6105                	addi	sp,sp,32
    8000142e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001430:	8f99                	sub	a5,a5,a4
    80001432:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001434:	4685                	li	a3,1
    80001436:	0007861b          	sext.w	a2,a5
    8000143a:	85ba                	mv	a1,a4
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	e5e080e7          	jalr	-418(ra) # 8000129a <uvmunmap>
    80001444:	b7c5                	j	80001424 <uvmdealloc+0x26>

0000000080001446 <uvmalloc>:
  if(newsz < oldsz)
    80001446:	0ab66163          	bltu	a2,a1,800014e8 <uvmalloc+0xa2>
{
    8000144a:	7139                	addi	sp,sp,-64
    8000144c:	fc06                	sd	ra,56(sp)
    8000144e:	f822                	sd	s0,48(sp)
    80001450:	f426                	sd	s1,40(sp)
    80001452:	f04a                	sd	s2,32(sp)
    80001454:	ec4e                	sd	s3,24(sp)
    80001456:	e852                	sd	s4,16(sp)
    80001458:	e456                	sd	s5,8(sp)
    8000145a:	0080                	addi	s0,sp,64
    8000145c:	8aaa                	mv	s5,a0
    8000145e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001460:	6985                	lui	s3,0x1
    80001462:	19fd                	addi	s3,s3,-1
    80001464:	95ce                	add	a1,a1,s3
    80001466:	79fd                	lui	s3,0xfffff
    80001468:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146c:	08c9f063          	bgeu	s3,a2,800014ec <uvmalloc+0xa6>
    80001470:	894e                	mv	s2,s3
    mem = kalloc();
    80001472:	fffff097          	auipc	ra,0xfffff
    80001476:	682080e7          	jalr	1666(ra) # 80000af4 <kalloc>
    8000147a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000147c:	c51d                	beqz	a0,800014aa <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000147e:	6605                	lui	a2,0x1
    80001480:	4581                	li	a1,0
    80001482:	00000097          	auipc	ra,0x0
    80001486:	882080e7          	jalr	-1918(ra) # 80000d04 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000148a:	4779                	li	a4,30
    8000148c:	86a6                	mv	a3,s1
    8000148e:	6605                	lui	a2,0x1
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	c40080e7          	jalr	-960(ra) # 800010d4 <mappages>
    8000149c:	e905                	bnez	a0,800014cc <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149e:	6785                	lui	a5,0x1
    800014a0:	993e                	add	s2,s2,a5
    800014a2:	fd4968e3          	bltu	s2,s4,80001472 <uvmalloc+0x2c>
  return newsz;
    800014a6:	8552                	mv	a0,s4
    800014a8:	a809                	j	800014ba <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014aa:	864e                	mv	a2,s3
    800014ac:	85ca                	mv	a1,s2
    800014ae:	8556                	mv	a0,s5
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	f4e080e7          	jalr	-178(ra) # 800013fe <uvmdealloc>
      return 0;
    800014b8:	4501                	li	a0,0
}
    800014ba:	70e2                	ld	ra,56(sp)
    800014bc:	7442                	ld	s0,48(sp)
    800014be:	74a2                	ld	s1,40(sp)
    800014c0:	7902                	ld	s2,32(sp)
    800014c2:	69e2                	ld	s3,24(sp)
    800014c4:	6a42                	ld	s4,16(sp)
    800014c6:	6aa2                	ld	s5,8(sp)
    800014c8:	6121                	addi	sp,sp,64
    800014ca:	8082                	ret
      kfree(mem);
    800014cc:	8526                	mv	a0,s1
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	52a080e7          	jalr	1322(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014d6:	864e                	mv	a2,s3
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	f22080e7          	jalr	-222(ra) # 800013fe <uvmdealloc>
      return 0;
    800014e4:	4501                	li	a0,0
    800014e6:	bfd1                	j	800014ba <uvmalloc+0x74>
    return oldsz;
    800014e8:	852e                	mv	a0,a1
}
    800014ea:	8082                	ret
  return newsz;
    800014ec:	8532                	mv	a0,a2
    800014ee:	b7f1                	j	800014ba <uvmalloc+0x74>

00000000800014f0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014f0:	7179                	addi	sp,sp,-48
    800014f2:	f406                	sd	ra,40(sp)
    800014f4:	f022                	sd	s0,32(sp)
    800014f6:	ec26                	sd	s1,24(sp)
    800014f8:	e84a                	sd	s2,16(sp)
    800014fa:	e44e                	sd	s3,8(sp)
    800014fc:	e052                	sd	s4,0(sp)
    800014fe:	1800                	addi	s0,sp,48
    80001500:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001502:	84aa                	mv	s1,a0
    80001504:	6905                	lui	s2,0x1
    80001506:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	4985                	li	s3,1
    8000150a:	a821                	j	80001522 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000150c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000150e:	0532                	slli	a0,a0,0xc
    80001510:	00000097          	auipc	ra,0x0
    80001514:	fe0080e7          	jalr	-32(ra) # 800014f0 <freewalk>
      pagetable[i] = 0;
    80001518:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000151c:	04a1                	addi	s1,s1,8
    8000151e:	03248163          	beq	s1,s2,80001540 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001522:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001524:	00f57793          	andi	a5,a0,15
    80001528:	ff3782e3          	beq	a5,s3,8000150c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000152c:	8905                	andi	a0,a0,1
    8000152e:	d57d                	beqz	a0,8000151c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001530:	00007517          	auipc	a0,0x7
    80001534:	c7050513          	addi	a0,a0,-912 # 800081a0 <digits+0x160>
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	006080e7          	jalr	6(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001540:	8552                	mv	a0,s4
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	4b6080e7          	jalr	1206(ra) # 800009f8 <kfree>
}
    8000154a:	70a2                	ld	ra,40(sp)
    8000154c:	7402                	ld	s0,32(sp)
    8000154e:	64e2                	ld	s1,24(sp)
    80001550:	6942                	ld	s2,16(sp)
    80001552:	69a2                	ld	s3,8(sp)
    80001554:	6a02                	ld	s4,0(sp)
    80001556:	6145                	addi	sp,sp,48
    80001558:	8082                	ret

000000008000155a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000155a:	1101                	addi	sp,sp,-32
    8000155c:	ec06                	sd	ra,24(sp)
    8000155e:	e822                	sd	s0,16(sp)
    80001560:	e426                	sd	s1,8(sp)
    80001562:	1000                	addi	s0,sp,32
    80001564:	84aa                	mv	s1,a0
  if(sz > 0)
    80001566:	e999                	bnez	a1,8000157c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001568:	8526                	mv	a0,s1
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	f86080e7          	jalr	-122(ra) # 800014f0 <freewalk>
}
    80001572:	60e2                	ld	ra,24(sp)
    80001574:	6442                	ld	s0,16(sp)
    80001576:	64a2                	ld	s1,8(sp)
    80001578:	6105                	addi	sp,sp,32
    8000157a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000157c:	6605                	lui	a2,0x1
    8000157e:	167d                	addi	a2,a2,-1
    80001580:	962e                	add	a2,a2,a1
    80001582:	4685                	li	a3,1
    80001584:	8231                	srli	a2,a2,0xc
    80001586:	4581                	li	a1,0
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	d12080e7          	jalr	-750(ra) # 8000129a <uvmunmap>
    80001590:	bfe1                	j	80001568 <uvmfree+0xe>

0000000080001592 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001592:	c679                	beqz	a2,80001660 <uvmcopy+0xce>
{
    80001594:	715d                	addi	sp,sp,-80
    80001596:	e486                	sd	ra,72(sp)
    80001598:	e0a2                	sd	s0,64(sp)
    8000159a:	fc26                	sd	s1,56(sp)
    8000159c:	f84a                	sd	s2,48(sp)
    8000159e:	f44e                	sd	s3,40(sp)
    800015a0:	f052                	sd	s4,32(sp)
    800015a2:	ec56                	sd	s5,24(sp)
    800015a4:	e85a                	sd	s6,16(sp)
    800015a6:	e45e                	sd	s7,8(sp)
    800015a8:	0880                	addi	s0,sp,80
    800015aa:	8b2a                	mv	s6,a0
    800015ac:	8aae                	mv	s5,a1
    800015ae:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015b2:	4601                	li	a2,0
    800015b4:	85ce                	mv	a1,s3
    800015b6:	855a                	mv	a0,s6
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	a34080e7          	jalr	-1484(ra) # 80000fec <walk>
    800015c0:	c531                	beqz	a0,8000160c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015c2:	6118                	ld	a4,0(a0)
    800015c4:	00177793          	andi	a5,a4,1
    800015c8:	cbb1                	beqz	a5,8000161c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ca:	00a75593          	srli	a1,a4,0xa
    800015ce:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015d2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	51e080e7          	jalr	1310(ra) # 80000af4 <kalloc>
    800015de:	892a                	mv	s2,a0
    800015e0:	c939                	beqz	a0,80001636 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015e2:	6605                	lui	a2,0x1
    800015e4:	85de                	mv	a1,s7
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	77e080e7          	jalr	1918(ra) # 80000d64 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ee:	8726                	mv	a4,s1
    800015f0:	86ca                	mv	a3,s2
    800015f2:	6605                	lui	a2,0x1
    800015f4:	85ce                	mv	a1,s3
    800015f6:	8556                	mv	a0,s5
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	adc080e7          	jalr	-1316(ra) # 800010d4 <mappages>
    80001600:	e515                	bnez	a0,8000162c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001602:	6785                	lui	a5,0x1
    80001604:	99be                	add	s3,s3,a5
    80001606:	fb49e6e3          	bltu	s3,s4,800015b2 <uvmcopy+0x20>
    8000160a:	a081                	j	8000164a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000160c:	00007517          	auipc	a0,0x7
    80001610:	ba450513          	addi	a0,a0,-1116 # 800081b0 <digits+0x170>
    80001614:	fffff097          	auipc	ra,0xfffff
    80001618:	f2a080e7          	jalr	-214(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000161c:	00007517          	auipc	a0,0x7
    80001620:	bb450513          	addi	a0,a0,-1100 # 800081d0 <digits+0x190>
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	f1a080e7          	jalr	-230(ra) # 8000053e <panic>
      kfree(mem);
    8000162c:	854a                	mv	a0,s2
    8000162e:	fffff097          	auipc	ra,0xfffff
    80001632:	3ca080e7          	jalr	970(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001636:	4685                	li	a3,1
    80001638:	00c9d613          	srli	a2,s3,0xc
    8000163c:	4581                	li	a1,0
    8000163e:	8556                	mv	a0,s5
    80001640:	00000097          	auipc	ra,0x0
    80001644:	c5a080e7          	jalr	-934(ra) # 8000129a <uvmunmap>
  return -1;
    80001648:	557d                	li	a0,-1
}
    8000164a:	60a6                	ld	ra,72(sp)
    8000164c:	6406                	ld	s0,64(sp)
    8000164e:	74e2                	ld	s1,56(sp)
    80001650:	7942                	ld	s2,48(sp)
    80001652:	79a2                	ld	s3,40(sp)
    80001654:	7a02                	ld	s4,32(sp)
    80001656:	6ae2                	ld	s5,24(sp)
    80001658:	6b42                	ld	s6,16(sp)
    8000165a:	6ba2                	ld	s7,8(sp)
    8000165c:	6161                	addi	sp,sp,80
    8000165e:	8082                	ret
  return 0;
    80001660:	4501                	li	a0,0
}
    80001662:	8082                	ret

0000000080001664 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001664:	1141                	addi	sp,sp,-16
    80001666:	e406                	sd	ra,8(sp)
    80001668:	e022                	sd	s0,0(sp)
    8000166a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000166c:	4601                	li	a2,0
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	97e080e7          	jalr	-1666(ra) # 80000fec <walk>
  if(pte == 0)
    80001676:	c901                	beqz	a0,80001686 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001678:	611c                	ld	a5,0(a0)
    8000167a:	9bbd                	andi	a5,a5,-17
    8000167c:	e11c                	sd	a5,0(a0)
}
    8000167e:	60a2                	ld	ra,8(sp)
    80001680:	6402                	ld	s0,0(sp)
    80001682:	0141                	addi	sp,sp,16
    80001684:	8082                	ret
    panic("uvmclear");
    80001686:	00007517          	auipc	a0,0x7
    8000168a:	b6a50513          	addi	a0,a0,-1174 # 800081f0 <digits+0x1b0>
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>

0000000080001696 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001696:	c6bd                	beqz	a3,80001704 <copyout+0x6e>
{
    80001698:	715d                	addi	sp,sp,-80
    8000169a:	e486                	sd	ra,72(sp)
    8000169c:	e0a2                	sd	s0,64(sp)
    8000169e:	fc26                	sd	s1,56(sp)
    800016a0:	f84a                	sd	s2,48(sp)
    800016a2:	f44e                	sd	s3,40(sp)
    800016a4:	f052                	sd	s4,32(sp)
    800016a6:	ec56                	sd	s5,24(sp)
    800016a8:	e85a                	sd	s6,16(sp)
    800016aa:	e45e                	sd	s7,8(sp)
    800016ac:	e062                	sd	s8,0(sp)
    800016ae:	0880                	addi	s0,sp,80
    800016b0:	8b2a                	mv	s6,a0
    800016b2:	8c2e                	mv	s8,a1
    800016b4:	8a32                	mv	s4,a2
    800016b6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ba:	6a85                	lui	s5,0x1
    800016bc:	a015                	j	800016e0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016be:	9562                	add	a0,a0,s8
    800016c0:	0004861b          	sext.w	a2,s1
    800016c4:	85d2                	mv	a1,s4
    800016c6:	41250533          	sub	a0,a0,s2
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	69a080e7          	jalr	1690(ra) # 80000d64 <memmove>

    len -= n;
    800016d2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016dc:	02098263          	beqz	s3,80001700 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016e0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e4:	85ca                	mv	a1,s2
    800016e6:	855a                	mv	a0,s6
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	9aa080e7          	jalr	-1622(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    800016f0:	cd01                	beqz	a0,80001708 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016f2:	418904b3          	sub	s1,s2,s8
    800016f6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016f8:	fc99f3e3          	bgeu	s3,s1,800016be <copyout+0x28>
    800016fc:	84ce                	mv	s1,s3
    800016fe:	b7c1                	j	800016be <copyout+0x28>
  }
  return 0;
    80001700:	4501                	li	a0,0
    80001702:	a021                	j	8000170a <copyout+0x74>
    80001704:	4501                	li	a0,0
}
    80001706:	8082                	ret
      return -1;
    80001708:	557d                	li	a0,-1
}
    8000170a:	60a6                	ld	ra,72(sp)
    8000170c:	6406                	ld	s0,64(sp)
    8000170e:	74e2                	ld	s1,56(sp)
    80001710:	7942                	ld	s2,48(sp)
    80001712:	79a2                	ld	s3,40(sp)
    80001714:	7a02                	ld	s4,32(sp)
    80001716:	6ae2                	ld	s5,24(sp)
    80001718:	6b42                	ld	s6,16(sp)
    8000171a:	6ba2                	ld	s7,8(sp)
    8000171c:	6c02                	ld	s8,0(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret

0000000080001722 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001722:	c6bd                	beqz	a3,80001790 <copyin+0x6e>
{
    80001724:	715d                	addi	sp,sp,-80
    80001726:	e486                	sd	ra,72(sp)
    80001728:	e0a2                	sd	s0,64(sp)
    8000172a:	fc26                	sd	s1,56(sp)
    8000172c:	f84a                	sd	s2,48(sp)
    8000172e:	f44e                	sd	s3,40(sp)
    80001730:	f052                	sd	s4,32(sp)
    80001732:	ec56                	sd	s5,24(sp)
    80001734:	e85a                	sd	s6,16(sp)
    80001736:	e45e                	sd	s7,8(sp)
    80001738:	e062                	sd	s8,0(sp)
    8000173a:	0880                	addi	s0,sp,80
    8000173c:	8b2a                	mv	s6,a0
    8000173e:	8a2e                	mv	s4,a1
    80001740:	8c32                	mv	s8,a2
    80001742:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001744:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001746:	6a85                	lui	s5,0x1
    80001748:	a015                	j	8000176c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000174a:	9562                	add	a0,a0,s8
    8000174c:	0004861b          	sext.w	a2,s1
    80001750:	412505b3          	sub	a1,a0,s2
    80001754:	8552                	mv	a0,s4
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	60e080e7          	jalr	1550(ra) # 80000d64 <memmove>

    len -= n;
    8000175e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001762:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001764:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001768:	02098263          	beqz	s3,8000178c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000176c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001770:	85ca                	mv	a1,s2
    80001772:	855a                	mv	a0,s6
    80001774:	00000097          	auipc	ra,0x0
    80001778:	91e080e7          	jalr	-1762(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000177c:	cd01                	beqz	a0,80001794 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000177e:	418904b3          	sub	s1,s2,s8
    80001782:	94d6                	add	s1,s1,s5
    if(n > len)
    80001784:	fc99f3e3          	bgeu	s3,s1,8000174a <copyin+0x28>
    80001788:	84ce                	mv	s1,s3
    8000178a:	b7c1                	j	8000174a <copyin+0x28>
  }
  return 0;
    8000178c:	4501                	li	a0,0
    8000178e:	a021                	j	80001796 <copyin+0x74>
    80001790:	4501                	li	a0,0
}
    80001792:	8082                	ret
      return -1;
    80001794:	557d                	li	a0,-1
}
    80001796:	60a6                	ld	ra,72(sp)
    80001798:	6406                	ld	s0,64(sp)
    8000179a:	74e2                	ld	s1,56(sp)
    8000179c:	7942                	ld	s2,48(sp)
    8000179e:	79a2                	ld	s3,40(sp)
    800017a0:	7a02                	ld	s4,32(sp)
    800017a2:	6ae2                	ld	s5,24(sp)
    800017a4:	6b42                	ld	s6,16(sp)
    800017a6:	6ba2                	ld	s7,8(sp)
    800017a8:	6c02                	ld	s8,0(sp)
    800017aa:	6161                	addi	sp,sp,80
    800017ac:	8082                	ret

00000000800017ae <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ae:	c6c5                	beqz	a3,80001856 <copyinstr+0xa8>
{
    800017b0:	715d                	addi	sp,sp,-80
    800017b2:	e486                	sd	ra,72(sp)
    800017b4:	e0a2                	sd	s0,64(sp)
    800017b6:	fc26                	sd	s1,56(sp)
    800017b8:	f84a                	sd	s2,48(sp)
    800017ba:	f44e                	sd	s3,40(sp)
    800017bc:	f052                	sd	s4,32(sp)
    800017be:	ec56                	sd	s5,24(sp)
    800017c0:	e85a                	sd	s6,16(sp)
    800017c2:	e45e                	sd	s7,8(sp)
    800017c4:	0880                	addi	s0,sp,80
    800017c6:	8a2a                	mv	s4,a0
    800017c8:	8b2e                	mv	s6,a1
    800017ca:	8bb2                	mv	s7,a2
    800017cc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ce:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d0:	6985                	lui	s3,0x1
    800017d2:	a035                	j	800017fe <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017da:	0017b793          	seqz	a5,a5
    800017de:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6161                	addi	sp,sp,80
    800017f6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017fc:	c8a9                	beqz	s1,8000184e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017fe:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001802:	85ca                	mv	a1,s2
    80001804:	8552                	mv	a0,s4
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	88c080e7          	jalr	-1908(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000180e:	c131                	beqz	a0,80001852 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001810:	41790833          	sub	a6,s2,s7
    80001814:	984e                	add	a6,a6,s3
    if(n > max)
    80001816:	0104f363          	bgeu	s1,a6,8000181c <copyinstr+0x6e>
    8000181a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000181c:	955e                	add	a0,a0,s7
    8000181e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001822:	fc080be3          	beqz	a6,800017f8 <copyinstr+0x4a>
    80001826:	985a                	add	a6,a6,s6
    80001828:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000182a:	41650633          	sub	a2,a0,s6
    8000182e:	14fd                	addi	s1,s1,-1
    80001830:	9b26                	add	s6,s6,s1
    80001832:	00f60733          	add	a4,a2,a5
    80001836:	00074703          	lbu	a4,0(a4)
    8000183a:	df49                	beqz	a4,800017d4 <copyinstr+0x26>
        *dst = *p;
    8000183c:	00e78023          	sb	a4,0(a5)
      --max;
    80001840:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001844:	0785                	addi	a5,a5,1
    while(n > 0){
    80001846:	ff0796e3          	bne	a5,a6,80001832 <copyinstr+0x84>
      dst++;
    8000184a:	8b42                	mv	s6,a6
    8000184c:	b775                	j	800017f8 <copyinstr+0x4a>
    8000184e:	4781                	li	a5,0
    80001850:	b769                	j	800017da <copyinstr+0x2c>
      return -1;
    80001852:	557d                	li	a0,-1
    80001854:	b779                	j	800017e2 <copyinstr+0x34>
  int got_null = 0;
    80001856:	4781                	li	a5,0
  if(got_null){
    80001858:	0017b793          	seqz	a5,a5
    8000185c:	40f00533          	neg	a0,a5
}
    80001860:	8082                	ret

0000000080001862 <remove_cs>:
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

int
remove_cs(struct proc *pred, struct proc *curr, struct proc *p){ //created
    80001862:	7139                	addi	sp,sp,-64
    80001864:	fc06                	sd	ra,56(sp)
    80001866:	f822                	sd	s0,48(sp)
    80001868:	f426                	sd	s1,40(sp)
    8000186a:	f04a                	sd	s2,32(sp)
    8000186c:	ec4e                	sd	s3,24(sp)
    8000186e:	e852                	sd	s4,16(sp)
    80001870:	e456                	sd	s5,8(sp)
    80001872:	e05a                	sd	s6,0(sp)
    80001874:	0080                	addi	s0,sp,64
    80001876:	8b2a                	mv	s6,a0
    80001878:	84ae                	mv	s1,a1
    8000187a:	8a32                	mv	s4,a2
int ret=-1;
printf("p->index=%d\n", p->index);
    8000187c:	5e0c                	lw	a1,56(a2)
    8000187e:	00007517          	auipc	a0,0x7
    80001882:	98250513          	addi	a0,a0,-1662 # 80008200 <digits+0x1c0>
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	d02080e7          	jalr	-766(ra) # 80000588 <printf>
printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
    8000188e:	5c90                	lw	a2,56(s1)
    80001890:	038b2583          	lw	a1,56(s6) # 1038 <_entry-0x7fffefc8>
    80001894:	00007517          	auipc	a0,0x7
    80001898:	97c50513          	addi	a0,a0,-1668 # 80008210 <digits+0x1d0>
    8000189c:	fffff097          	auipc	ra,0xfffff
    800018a0:	cec080e7          	jalr	-788(ra) # 80000588 <printf>
while (curr->index <= p->index) {
    800018a4:	5c9c                	lw	a5,56(s1)
    800018a6:	038a2703          	lw	a4,56(s4) # fffffffffffff038 <end+0xffffffff7ffdf038>
    800018aa:	04f74663          	blt	a4,a5,800018f6 <remove_cs+0x94>
    800018ae:	18800a93          	li	s5,392
    }
    release(&pred->linked_list_lock);
    //printf("%d\n",132);
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    pred = curr;
    curr = &proc[curr->next];
    800018b2:	0000a997          	auipc	s3,0xa
    800018b6:	9ee98993          	addi	s3,s3,-1554 # 8000b2a0 <proc>
    800018ba:	a011                	j	800018be <remove_cs+0x5c>
    800018bc:	84ca                	mv	s1,s2
  if ( p->index == curr->index) {
    800018be:	04e78463          	beq	a5,a4,80001906 <remove_cs+0xa4>
    release(&pred->linked_list_lock);
    800018c2:	040b0513          	addi	a0,s6,64
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	3e4080e7          	jalr	996(ra) # 80000caa <release>
    curr = &proc[curr->next];
    800018ce:	5cc8                	lw	a0,60(s1)
    800018d0:	2501                	sext.w	a0,a0
    800018d2:	03550533          	mul	a0,a0,s5
    800018d6:	01350933          	add	s2,a0,s3
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    acquire(&curr->linked_list_lock);
    800018da:	04050513          	addi	a0,a0,64
    800018de:	954e                	add	a0,a0,s3
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	304080e7          	jalr	772(ra) # 80000be4 <acquire>
while (curr->index <= p->index) {
    800018e8:	03892783          	lw	a5,56(s2) # 1038 <_entry-0x7fffefc8>
    800018ec:	038a2703          	lw	a4,56(s4)
    800018f0:	8b26                	mv	s6,s1
    800018f2:	fcf755e3          	bge	a4,a5,800018bc <remove_cs+0x5a>
    //printf("after lock\n");
  }
  panic("item not found");
    800018f6:	00007517          	auipc	a0,0x7
    800018fa:	93250513          	addi	a0,a0,-1742 # 80008228 <digits+0x1e8>
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	c40080e7          	jalr	-960(ra) # 8000053e <panic>
      pred->next = curr->next;
    80001906:	5cdc                	lw	a5,60(s1)
    80001908:	2781                	sext.w	a5,a5
    8000190a:	02fb2e23          	sw	a5,60(s6)
      ret = curr->index;
    8000190e:	5c84                	lw	s1,56(s1)
      release(&pred->linked_list_lock);
    80001910:	040b0513          	addi	a0,s6,64
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	396080e7          	jalr	918(ra) # 80000caa <release>
}
    8000191c:	8526                	mv	a0,s1
    8000191e:	70e2                	ld	ra,56(sp)
    80001920:	7442                	ld	s0,48(sp)
    80001922:	74a2                	ld	s1,40(sp)
    80001924:	7902                	ld	s2,32(sp)
    80001926:	69e2                	ld	s3,24(sp)
    80001928:	6a42                	ld	s4,16(sp)
    8000192a:	6aa2                	ld	s5,8(sp)
    8000192c:	6b02                	ld	s6,0(sp)
    8000192e:	6121                	addi	sp,sp,64
    80001930:	8082                	ret

0000000080001932 <remove_from_list>:

int remove_from_list(int p_index, int *list,struct spinlock lock_list){
    80001932:	7159                	addi	sp,sp,-112
    80001934:	f486                	sd	ra,104(sp)
    80001936:	f0a2                	sd	s0,96(sp)
    80001938:	eca6                	sd	s1,88(sp)
    8000193a:	e8ca                	sd	s2,80(sp)
    8000193c:	e4ce                	sd	s3,72(sp)
    8000193e:	e0d2                	sd	s4,64(sp)
    80001940:	fc56                	sd	s5,56(sp)
    80001942:	f85a                	sd	s6,48(sp)
    80001944:	f45e                	sd	s7,40(sp)
    80001946:	f062                	sd	s8,32(sp)
    80001948:	ec66                	sd	s9,24(sp)
    8000194a:	e86a                	sd	s10,16(sp)
    8000194c:	e46e                	sd	s11,8(sp)
    8000194e:	1880                	addi	s0,sp,112
    80001950:	892a                	mv	s2,a0
    80001952:	8aae                	mv	s5,a1
    80001954:	89b2                	mv	s3,a2
  printf("entered remove from list\n");
    80001956:	00007517          	auipc	a0,0x7
    8000195a:	8e250513          	addi	a0,a0,-1822 # 80008238 <digits+0x1f8>
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	c2a080e7          	jalr	-982(ra) # 80000588 <printf>
  printf("trying to remove %d\n", p_index);
    80001966:	85ca                	mv	a1,s2
    80001968:	00007517          	auipc	a0,0x7
    8000196c:	8f050513          	addi	a0,a0,-1808 # 80008258 <digits+0x218>
    80001970:	fffff097          	auipc	ra,0xfffff
    80001974:	c18080e7          	jalr	-1000(ra) # 80000588 <printf>
  int ret=-1;
  acquire(&lock_list);
    80001978:	854e                	mv	a0,s3
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	26a080e7          	jalr	618(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001982:	000aaa03          	lw	s4,0(s5) # fffffffffffff000 <end+0xffffffff7ffdf000>
    80001986:	57fd                	li	a5,-1
    80001988:	02fa0b63          	beq	s4,a5,800019be <remove_from_list+0x8c>
    panic("the remove from list faild.\n");
  }
  else{
    
    if(proc[*list].next==-1){ // only one is on the list
    8000198c:	18800793          	li	a5,392
    80001990:	02fa0733          	mul	a4,s4,a5
    80001994:	0000a797          	auipc	a5,0xa
    80001998:	90c78793          	addi	a5,a5,-1780 # 8000b2a0 <proc>
    8000199c:	97ba                	add	a5,a5,a4
    8000199e:	5fc4                	lw	s1,60(a5)
    800019a0:	2481                	sext.w	s1,s1
    800019a2:	57fd                	li	a5,-1
    800019a4:	02f49563          	bne	s1,a5,800019ce <remove_from_list+0x9c>
        if(p_index==*list){
    800019a8:	0b2a1363          	bne	s4,s2,80001a4e <remove_from_list+0x11c>
          //acquire(proc[p_index].linked_list_lock);
          *list = -1;
    800019ac:	00faa023          	sw	a5,0(s5)
          release(&lock_list);
    800019b0:	854e                	mv	a0,s3
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	2f8080e7          	jalr	760(ra) # 80000caa <release>
          ret=p_index;
          return ret;
    800019ba:	84ca                	mv	s1,s2
    800019bc:	a075                	j	80001a68 <remove_from_list+0x136>
    panic("the remove from list faild.\n");
    800019be:	00007517          	auipc	a0,0x7
    800019c2:	8b250513          	addi	a0,a0,-1870 # 80008270 <digits+0x230>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	b78080e7          	jalr	-1160(ra) # 8000053e <panic>
    }
    else{
      struct proc *pred;
      struct proc *curr;
      pred=&proc[*list];
      curr=&proc[pred->next];
    800019ce:	0000a497          	auipc	s1,0xa
    800019d2:	8d248493          	addi	s1,s1,-1838 # 8000b2a0 <proc>
    800019d6:	18800c93          	li	s9,392
    800019da:	039a0d33          	mul	s10,s4,s9
    800019de:	01a48db3          	add	s11,s1,s10
    800019e2:	03cdac03          	lw	s8,60(s11)
    800019e6:	2c01                	sext.w	s8,s8
      acquire(&pred->linked_list_lock);
    800019e8:	040d0b13          	addi	s6,s10,64
    800019ec:	9b26                	add	s6,s6,s1
    800019ee:	855a                	mv	a0,s6
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	1f4080e7          	jalr	500(ra) # 80000be4 <acquire>
      acquire(&curr->linked_list_lock);
    800019f8:	039c0cb3          	mul	s9,s8,s9
    800019fc:	040c8b93          	addi	s7,s9,64
    80001a00:	9ba6                	add	s7,s7,s1
    80001a02:	855e                	mv	a0,s7
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	1e0080e7          	jalr	480(ra) # 80000be4 <acquire>
      printf("pred is:%d the curr is:%d\n", pred->index,curr->index);
    80001a0c:	94e6                	add	s1,s1,s9
    80001a0e:	5c90                	lw	a2,56(s1)
    80001a10:	038da583          	lw	a1,56(s11)
    80001a14:	00007517          	auipc	a0,0x7
    80001a18:	87c50513          	addi	a0,a0,-1924 # 80008290 <digits+0x250>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	b6c080e7          	jalr	-1172(ra) # 80000588 <printf>
      if (pred->index == p_index){
    80001a24:	038da783          	lw	a5,56(s11)
    80001a28:	07279063          	bne	a5,s2,80001a88 <remove_from_list+0x156>
        *list = curr->index;
    80001a2c:	5c94                	lw	a3,56(s1)
    80001a2e:	00daa023          	sw	a3,0(s5)
        pred->next = -1;  //the caller will insert to the new list
    80001a32:	577d                	li	a4,-1
    80001a34:	02edae23          	sw	a4,60(s11)
  int ret=-1;
    80001a38:	54fd                	li	s1,-1
      }
      else {
      ret=remove_cs(pred, curr, &proc[p_index]);
      printf("changed.\nthe link of %d removed from the list of %s\n",ret ,lock_list.name);
      }
      release(&curr->linked_list_lock);
    80001a3a:	855e                	mv	a0,s7
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	26e080e7          	jalr	622(ra) # 80000caa <release>
      release(&pred->linked_list_lock);
    80001a44:	855a                	mv	a0,s6
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	264080e7          	jalr	612(ra) # 80000caa <release>
    }
  }
  printf("here4\n");
    80001a4e:	00007517          	auipc	a0,0x7
    80001a52:	89a50513          	addi	a0,a0,-1894 # 800082e8 <digits+0x2a8>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	b32080e7          	jalr	-1230(ra) # 80000588 <printf>
  release(&lock_list);
    80001a5e:	854e                	mv	a0,s3
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	24a080e7          	jalr	586(ra) # 80000caa <release>
  return ret;
}
    80001a68:	8526                	mv	a0,s1
    80001a6a:	70a6                	ld	ra,104(sp)
    80001a6c:	7406                	ld	s0,96(sp)
    80001a6e:	64e6                	ld	s1,88(sp)
    80001a70:	6946                	ld	s2,80(sp)
    80001a72:	69a6                	ld	s3,72(sp)
    80001a74:	6a06                	ld	s4,64(sp)
    80001a76:	7ae2                	ld	s5,56(sp)
    80001a78:	7b42                	ld	s6,48(sp)
    80001a7a:	7ba2                	ld	s7,40(sp)
    80001a7c:	7c02                	ld	s8,32(sp)
    80001a7e:	6ce2                	ld	s9,24(sp)
    80001a80:	6d42                	ld	s10,16(sp)
    80001a82:	6da2                	ld	s11,8(sp)
    80001a84:	6165                	addi	sp,sp,112
    80001a86:	8082                	ret
      ret=remove_cs(pred, curr, &proc[p_index]);
    80001a88:	18800613          	li	a2,392
    80001a8c:	02c90633          	mul	a2,s2,a2
    80001a90:	0000a517          	auipc	a0,0xa
    80001a94:	81050513          	addi	a0,a0,-2032 # 8000b2a0 <proc>
    80001a98:	962a                	add	a2,a2,a0
    80001a9a:	019505b3          	add	a1,a0,s9
    80001a9e:	956a                	add	a0,a0,s10
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	dc2080e7          	jalr	-574(ra) # 80001862 <remove_cs>
    80001aa8:	84aa                	mv	s1,a0
      printf("changed.\nthe link of %d removed from the list of %s\n",ret ,lock_list.name);
    80001aaa:	0089b603          	ld	a2,8(s3)
    80001aae:	85aa                	mv	a1,a0
    80001ab0:	00007517          	auipc	a0,0x7
    80001ab4:	80050513          	addi	a0,a0,-2048 # 800082b0 <digits+0x270>
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	ad0080e7          	jalr	-1328(ra) # 80000588 <printf>
    80001ac0:	bfad                	j	80001a3a <remove_from_list+0x108>

0000000080001ac2 <insert_cs>:

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001ac2:	7139                	addi	sp,sp,-64
    80001ac4:	fc06                	sd	ra,56(sp)
    80001ac6:	f822                	sd	s0,48(sp)
    80001ac8:	f426                	sd	s1,40(sp)
    80001aca:	f04a                	sd	s2,32(sp)
    80001acc:	ec4e                	sd	s3,24(sp)
    80001ace:	e852                	sd	s4,16(sp)
    80001ad0:	e456                	sd	s5,8(sp)
    80001ad2:	0080                	addi	s0,sp,64
    80001ad4:	84aa                	mv	s1,a0
    80001ad6:	8aae                	mv	s5,a1
  //struct proc *curr=pred; 
  while (pred->next != -1) {
    80001ad8:	5d5c                	lw	a5,60(a0)
    80001ada:	2781                	sext.w	a5,a5
    80001adc:	577d                	li	a4,-1
    80001ade:	04e78063          	beq	a5,a4,80001b1e <insert_cs+0x5c>
    80001ae2:	18800a13          	li	s4,392
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    release(&pred->linked_list_lock); // caller acquired
    pred = &proc[pred->next];
    80001ae6:	00009917          	auipc	s2,0x9
    80001aea:	7ba90913          	addi	s2,s2,1978 # 8000b2a0 <proc>
  while (pred->next != -1) {
    80001aee:	59fd                	li	s3,-1
    release(&pred->linked_list_lock); // caller acquired
    80001af0:	04048513          	addi	a0,s1,64
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	1b6080e7          	jalr	438(ra) # 80000caa <release>
    pred = &proc[pred->next];
    80001afc:	5cc8                	lw	a0,60(s1)
    80001afe:	2501                	sext.w	a0,a0
    80001b00:	03450533          	mul	a0,a0,s4
    80001b04:	012504b3          	add	s1,a0,s2
    acquire(&pred->linked_list_lock);
    80001b08:	04050513          	addi	a0,a0,64
    80001b0c:	954a                	add	a0,a0,s2
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	0d6080e7          	jalr	214(ra) # 80000be4 <acquire>
  while (pred->next != -1) {
    80001b16:	5cdc                	lw	a5,60(s1)
    80001b18:	2781                	sext.w	a5,a5
    80001b1a:	fd379be3          	bne	a5,s3,80001af0 <insert_cs+0x2e>
    }
    //printf("exitloop\n");
    pred->next = p->index;
    80001b1e:	038aa783          	lw	a5,56(s5)
    80001b22:	dcdc                	sw	a5,60(s1)
    //printf("the pred is:%d pred->next:%d p->index=%d\n",pred->index,pred->next,p->index);
    //printf("the p->index is:%d\n",p->index);
    p->next=-1;
    80001b24:	57fd                	li	a5,-1
    80001b26:	02faae23          	sw	a5,60(s5)
    release(&pred->linked_list_lock);
    80001b2a:	04048513          	addi	a0,s1,64
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	17c080e7          	jalr	380(ra) # 80000caa <release>
    return p->index;
}
    80001b36:	038aa503          	lw	a0,56(s5)
    80001b3a:	70e2                	ld	ra,56(sp)
    80001b3c:	7442                	ld	s0,48(sp)
    80001b3e:	74a2                	ld	s1,40(sp)
    80001b40:	7902                	ld	s2,32(sp)
    80001b42:	69e2                	ld	s3,24(sp)
    80001b44:	6a42                	ld	s4,16(sp)
    80001b46:	6aa2                	ld	s5,8(sp)
    80001b48:	6121                	addi	sp,sp,64
    80001b4a:	8082                	ret

0000000080001b4c <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock lock_list){
    80001b4c:	7139                	addi	sp,sp,-64
    80001b4e:	fc06                	sd	ra,56(sp)
    80001b50:	f822                	sd	s0,48(sp)
    80001b52:	f426                	sd	s1,40(sp)
    80001b54:	f04a                	sd	s2,32(sp)
    80001b56:	ec4e                	sd	s3,24(sp)
    80001b58:	e852                	sd	s4,16(sp)
    80001b5a:	e456                	sd	s5,8(sp)
    80001b5c:	0080                	addi	s0,sp,64
    80001b5e:	84aa                	mv	s1,a0
    80001b60:	892e                	mv	s2,a1
    80001b62:	8a32                	mv	s4,a2
  //printf("entered insert_to_list.\n");
  int ret=-1;
  if(*list==-1){
    80001b64:	4198                	lw	a4,0(a1)
    80001b66:	57fd                	li	a5,-1
    80001b68:	06f70563          	beq	a4,a5,80001bd2 <insert_to_list+0x86>
    ret=p_index;
    //printf("here\nlist pointer: %d, list next %d\n",*list, proc[*list].next);
    release(&lock_list);
  }
  else{
    acquire(&lock_list);
    80001b6c:	8532                	mv	a0,a2
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	076080e7          	jalr	118(ra) # 80000be4 <acquire>
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    80001b76:	00092903          	lw	s2,0(s2)
    80001b7a:	18800a93          	li	s5,392
    80001b7e:	03590933          	mul	s2,s2,s5
    //printf("the index of the first prosses in the list is:%d %d\n",*list,pred->next);
    acquire(&pred->linked_list_lock);
    80001b82:	04090513          	addi	a0,s2,64
    80001b86:	00009997          	auipc	s3,0x9
    80001b8a:	71a98993          	addi	s3,s3,1818 # 8000b2a0 <proc>
    80001b8e:	954e                	add	a0,a0,s3
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	054080e7          	jalr	84(ra) # 80000be4 <acquire>
    //curr=&proc[pred->next];
    //acquire(&curr->lock);
    ret=insert_cs(pred, &proc[p_index]);
    80001b98:	035484b3          	mul	s1,s1,s5
    80001b9c:	009985b3          	add	a1,s3,s1
    80001ba0:	01298533          	add	a0,s3,s2
    80001ba4:	00000097          	auipc	ra,0x0
    80001ba8:	f1e080e7          	jalr	-226(ra) # 80001ac2 <insert_cs>
    80001bac:	84aa                	mv	s1,a0
    //release(&curr->lock);
    // release(&pred->linked_list_lock);
    //printf("ret is:%d \n",ret);  
    release(&lock_list);
    80001bae:	8552                	mv	a0,s4
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	0fa080e7          	jalr	250(ra) # 80000caa <release>
}
if(ret==-1){
    80001bb8:	57fd                	li	a5,-1
    80001bba:	06f48263          	beq	s1,a5,80001c1e <insert_to_list+0xd2>
  panic("insert is failed");
}
return ret;
}
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	70e2                	ld	ra,56(sp)
    80001bc2:	7442                	ld	s0,48(sp)
    80001bc4:	74a2                	ld	s1,40(sp)
    80001bc6:	7902                	ld	s2,32(sp)
    80001bc8:	69e2                	ld	s3,24(sp)
    80001bca:	6a42                	ld	s4,16(sp)
    80001bcc:	6aa2                	ld	s5,8(sp)
    80001bce:	6121                	addi	sp,sp,64
    80001bd0:	8082                	ret
    acquire(&lock_list);
    80001bd2:	8532                	mv	a0,a2
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	010080e7          	jalr	16(ra) # 80000be4 <acquire>
    *list=p_index;
    80001bdc:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001be0:	18800993          	li	s3,392
    80001be4:	03348ab3          	mul	s5,s1,s3
    80001be8:	040a8913          	addi	s2,s5,64
    80001bec:	00009997          	auipc	s3,0x9
    80001bf0:	6b498993          	addi	s3,s3,1716 # 8000b2a0 <proc>
    80001bf4:	994e                	add	s2,s2,s3
    80001bf6:	854a                	mv	a0,s2
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	fec080e7          	jalr	-20(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001c00:	99d6                	add	s3,s3,s5
    80001c02:	57fd                	li	a5,-1
    80001c04:	02f9ae23          	sw	a5,60(s3)
    release(&proc[p_index].linked_list_lock);
    80001c08:	854a                	mv	a0,s2
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	0a0080e7          	jalr	160(ra) # 80000caa <release>
    release(&lock_list);
    80001c12:	8552                	mv	a0,s4
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	096080e7          	jalr	150(ra) # 80000caa <release>
    80001c1c:	bf71                	j	80001bb8 <insert_to_list+0x6c>
  panic("insert is failed");
    80001c1e:	00006517          	auipc	a0,0x6
    80001c22:	6d250513          	addi	a0,a0,1746 # 800082f0 <digits+0x2b0>
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	918080e7          	jalr	-1768(ra) # 8000053e <panic>

0000000080001c2e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001c2e:	7139                	addi	sp,sp,-64
    80001c30:	fc06                	sd	ra,56(sp)
    80001c32:	f822                	sd	s0,48(sp)
    80001c34:	f426                	sd	s1,40(sp)
    80001c36:	f04a                	sd	s2,32(sp)
    80001c38:	ec4e                	sd	s3,24(sp)
    80001c3a:	e852                	sd	s4,16(sp)
    80001c3c:	e456                	sd	s5,8(sp)
    80001c3e:	e05a                	sd	s6,0(sp)
    80001c40:	0080                	addi	s0,sp,64
    80001c42:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c44:	00009497          	auipc	s1,0x9
    80001c48:	65c48493          	addi	s1,s1,1628 # 8000b2a0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c4c:	8b26                	mv	s6,s1
    80001c4e:	00006a97          	auipc	s5,0x6
    80001c52:	3b2a8a93          	addi	s5,s5,946 # 80008000 <etext>
    80001c56:	04000937          	lui	s2,0x4000
    80001c5a:	197d                	addi	s2,s2,-1
    80001c5c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5e:	00010a17          	auipc	s4,0x10
    80001c62:	842a0a13          	addi	s4,s4,-1982 # 800114a0 <tickslock>
    char *pa = kalloc();
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	e8e080e7          	jalr	-370(ra) # 80000af4 <kalloc>
    80001c6e:	862a                	mv	a2,a0
    if(pa == 0)
    80001c70:	c131                	beqz	a0,80001cb4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c72:	416485b3          	sub	a1,s1,s6
    80001c76:	858d                	srai	a1,a1,0x3
    80001c78:	000ab783          	ld	a5,0(s5)
    80001c7c:	02f585b3          	mul	a1,a1,a5
    80001c80:	2585                	addiw	a1,a1,1
    80001c82:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c86:	4719                	li	a4,6
    80001c88:	6685                	lui	a3,0x1
    80001c8a:	40b905b3          	sub	a1,s2,a1
    80001c8e:	854e                	mv	a0,s3
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	4e4080e7          	jalr	1252(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c98:	18848493          	addi	s1,s1,392
    80001c9c:	fd4495e3          	bne	s1,s4,80001c66 <proc_mapstacks+0x38>
  }
}
    80001ca0:	70e2                	ld	ra,56(sp)
    80001ca2:	7442                	ld	s0,48(sp)
    80001ca4:	74a2                	ld	s1,40(sp)
    80001ca6:	7902                	ld	s2,32(sp)
    80001ca8:	69e2                	ld	s3,24(sp)
    80001caa:	6a42                	ld	s4,16(sp)
    80001cac:	6aa2                	ld	s5,8(sp)
    80001cae:	6b02                	ld	s6,0(sp)
    80001cb0:	6121                	addi	sp,sp,64
    80001cb2:	8082                	ret
      panic("kalloc");
    80001cb4:	00006517          	auipc	a0,0x6
    80001cb8:	65450513          	addi	a0,a0,1620 # 80008308 <digits+0x2c8>
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	882080e7          	jalr	-1918(ra) # 8000053e <panic>

0000000080001cc4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80001cc4:	7119                	addi	sp,sp,-128
    80001cc6:	fc86                	sd	ra,120(sp)
    80001cc8:	f8a2                	sd	s0,112(sp)
    80001cca:	f4a6                	sd	s1,104(sp)
    80001ccc:	f0ca                	sd	s2,96(sp)
    80001cce:	ecce                	sd	s3,88(sp)
    80001cd0:	e8d2                	sd	s4,80(sp)
    80001cd2:	e4d6                	sd	s5,72(sp)
    80001cd4:	e0da                	sd	s6,64(sp)
    80001cd6:	fc5e                	sd	s7,56(sp)
    80001cd8:	f862                	sd	s8,48(sp)
    80001cda:	f466                	sd	s9,40(sp)
    80001cdc:	0100                	addi	s0,sp,128
  printf("entered procinit\n");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	63250513          	addi	a0,a0,1586 # 80008310 <digits+0x2d0>
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	8a2080e7          	jalr	-1886(ra) # 80000588 <printf>
  struct proc *p;

  for (int i = 0; i<NCPU; i++){
    cas(&cpus_ll[i],0,-1); 
    80001cee:	567d                	li	a2,-1
    80001cf0:	4581                	li	a1,0
    80001cf2:	00008517          	auipc	a0,0x8
    80001cf6:	33650513          	addi	a0,a0,822 # 8000a028 <cpus_ll>
    80001cfa:	00005097          	auipc	ra,0x5
    80001cfe:	17c080e7          	jalr	380(ra) # 80006e76 <cas>
    printf("done cpus_ll[%d]=%d\n",i ,cpus_ll[i]);
    80001d02:	00008617          	auipc	a2,0x8
    80001d06:	32662603          	lw	a2,806(a2) # 8000a028 <cpus_ll>
    80001d0a:	4581                	li	a1,0
    80001d0c:	00006517          	auipc	a0,0x6
    80001d10:	61c50513          	addi	a0,a0,1564 # 80008328 <digits+0x2e8>
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	874080e7          	jalr	-1932(ra) # 80000588 <printf>
}
  
  initlock(&pid_lock, "nextpid");
    80001d1c:	00006597          	auipc	a1,0x6
    80001d20:	62458593          	addi	a1,a1,1572 # 80008340 <digits+0x300>
    80001d24:	00009517          	auipc	a0,0x9
    80001d28:	46c50513          	addi	a0,a0,1132 # 8000b190 <pid_lock>
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	e28080e7          	jalr	-472(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d34:	00006597          	auipc	a1,0x6
    80001d38:	61458593          	addi	a1,a1,1556 # 80008348 <digits+0x308>
    80001d3c:	00009517          	auipc	a0,0x9
    80001d40:	46c50513          	addi	a0,a0,1132 # 8000b1a8 <wait_lock>
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	e10080e7          	jalr	-496(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001d4c:	00006597          	auipc	a1,0x6
    80001d50:	60c58593          	addi	a1,a1,1548 # 80008358 <digits+0x318>
    80001d54:	00009517          	auipc	a0,0x9
    80001d58:	46c50513          	addi	a0,a0,1132 # 8000b1c0 <sleeping_head>
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	df8080e7          	jalr	-520(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001d64:	00006597          	auipc	a1,0x6
    80001d68:	60458593          	addi	a1,a1,1540 # 80008368 <digits+0x328>
    80001d6c:	00009517          	auipc	a0,0x9
    80001d70:	46c50513          	addi	a0,a0,1132 # 8000b1d8 <zombie_head>
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	de0080e7          	jalr	-544(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001d7c:	00006597          	auipc	a1,0x6
    80001d80:	5fc58593          	addi	a1,a1,1532 # 80008378 <digits+0x338>
    80001d84:	00009517          	auipc	a0,0x9
    80001d88:	46c50513          	addi	a0,a0,1132 # 8000b1f0 <unused_head>
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	dc8080e7          	jalr	-568(ra) # 80000b54 <initlock>
  
  int i=0; //added
    80001d94:	4981                	li	s3,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d96:	00009497          	auipc	s1,0x9
    80001d9a:	50a48493          	addi	s1,s1,1290 # 8000b2a0 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001d9e:	8ca6                	mv	s9,s1
    80001da0:	00006c17          	auipc	s8,0x6
    80001da4:	260c3c03          	ld	s8,608(s8) # 80008000 <etext>
    80001da8:	04000a37          	lui	s4,0x4000
    80001dac:	1a7d                	addi	s4,s4,-1
    80001dae:	0a32                	slli	s4,s4,0xc
      //added:
      p->state= UNUSED; 
      p->index=i; 
      initlock(&p->lock, "proc");
    80001db0:	00006b97          	auipc	s7,0x6
    80001db4:	5d8b8b93          	addi	s7,s7,1496 # 80008388 <digits+0x348>
      initlock(&p->linked_list_lock, "inbar");
    80001db8:	00006b17          	auipc	s6,0x6
    80001dbc:	5d8b0b13          	addi	s6,s6,1496 # 80008390 <digits+0x350>
      i++;
      insert_to_list(p->index, &unused,unused_head);
    80001dc0:	00009917          	auipc	s2,0x9
    80001dc4:	3d090913          	addi	s2,s2,976 # 8000b190 <pid_lock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dc8:	0000fa97          	auipc	s5,0xf
    80001dcc:	6d8a8a93          	addi	s5,s5,1752 # 800114a0 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001dd0:	419487b3          	sub	a5,s1,s9
    80001dd4:	878d                	srai	a5,a5,0x3
    80001dd6:	038787b3          	mul	a5,a5,s8
    80001dda:	2785                	addiw	a5,a5,1
    80001ddc:	00d7979b          	slliw	a5,a5,0xd
    80001de0:	40fa07b3          	sub	a5,s4,a5
    80001de4:	f0bc                	sd	a5,96(s1)
      p->state= UNUSED; 
    80001de6:	0004ac23          	sw	zero,24(s1)
      p->index=i; 
    80001dea:	0334ac23          	sw	s3,56(s1)
      initlock(&p->lock, "proc");
    80001dee:	85de                	mv	a1,s7
    80001df0:	8526                	mv	a0,s1
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	d62080e7          	jalr	-670(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, "inbar");
    80001dfa:	85da                	mv	a1,s6
    80001dfc:	04048513          	addi	a0,s1,64
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	d54080e7          	jalr	-684(ra) # 80000b54 <initlock>
      i++;
    80001e08:	2985                	addiw	s3,s3,1
      insert_to_list(p->index, &unused,unused_head);
    80001e0a:	06093783          	ld	a5,96(s2)
    80001e0e:	f8f43023          	sd	a5,-128(s0)
    80001e12:	06893783          	ld	a5,104(s2)
    80001e16:	f8f43423          	sd	a5,-120(s0)
    80001e1a:	07093783          	ld	a5,112(s2)
    80001e1e:	f8f43823          	sd	a5,-112(s0)
    80001e22:	f8040613          	addi	a2,s0,-128
    80001e26:	00007597          	auipc	a1,0x7
    80001e2a:	23e58593          	addi	a1,a1,574 # 80009064 <unused>
    80001e2e:	5c88                	lw	a0,56(s1)
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d1c080e7          	jalr	-740(ra) # 80001b4c <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e38:	18848493          	addi	s1,s1,392
    80001e3c:	f9549ae3          	bne	s1,s5,80001dd0 <procinit+0x10c>
      //printf("the value of the index is:%d\n",i);
  }

  
  
  printf("the head of the unused list is %d, and the value of next is:%d\n ",unused,proc[unused].next);
    80001e40:	00007597          	auipc	a1,0x7
    80001e44:	2245a583          	lw	a1,548(a1) # 80009064 <unused>
    80001e48:	18800793          	li	a5,392
    80001e4c:	02f58733          	mul	a4,a1,a5
    80001e50:	00009797          	auipc	a5,0x9
    80001e54:	45078793          	addi	a5,a5,1104 # 8000b2a0 <proc>
    80001e58:	97ba                	add	a5,a5,a4
    80001e5a:	5fd0                	lw	a2,60(a5)
    80001e5c:	2601                	sext.w	a2,a2
    80001e5e:	00006517          	auipc	a0,0x6
    80001e62:	53a50513          	addi	a0,a0,1338 # 80008398 <digits+0x358>
    80001e66:	ffffe097          	auipc	ra,0xffffe
    80001e6a:	722080e7          	jalr	1826(ra) # 80000588 <printf>
      
  printf("finished procinit\n");
    80001e6e:	00006517          	auipc	a0,0x6
    80001e72:	57250513          	addi	a0,a0,1394 # 800083e0 <digits+0x3a0>
    80001e76:	ffffe097          	auipc	ra,0xffffe
    80001e7a:	712080e7          	jalr	1810(ra) # 80000588 <printf>
}
    80001e7e:	70e6                	ld	ra,120(sp)
    80001e80:	7446                	ld	s0,112(sp)
    80001e82:	74a6                	ld	s1,104(sp)
    80001e84:	7906                	ld	s2,96(sp)
    80001e86:	69e6                	ld	s3,88(sp)
    80001e88:	6a46                	ld	s4,80(sp)
    80001e8a:	6aa6                	ld	s5,72(sp)
    80001e8c:	6b06                	ld	s6,64(sp)
    80001e8e:	7be2                	ld	s7,56(sp)
    80001e90:	7c42                	ld	s8,48(sp)
    80001e92:	7ca2                	ld	s9,40(sp)
    80001e94:	6109                	addi	sp,sp,128
    80001e96:	8082                	ret

0000000080001e98 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001e98:	1141                	addi	sp,sp,-16
    80001e9a:	e422                	sd	s0,8(sp)
    80001e9c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e9e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ea0:	2501                	sext.w	a0,a0
    80001ea2:	6422                	ld	s0,8(sp)
    80001ea4:	0141                	addi	sp,sp,16
    80001ea6:	8082                	ret

0000000080001ea8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001ea8:	1141                	addi	sp,sp,-16
    80001eaa:	e422                	sd	s0,8(sp)
    80001eac:	0800                	addi	s0,sp,16
    80001eae:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001eb0:	2781                	sext.w	a5,a5
    80001eb2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001eb4:	00009517          	auipc	a0,0x9
    80001eb8:	35450513          	addi	a0,a0,852 # 8000b208 <cpus>
    80001ebc:	953e                	add	a0,a0,a5
    80001ebe:	6422                	ld	s0,8(sp)
    80001ec0:	0141                	addi	sp,sp,16
    80001ec2:	8082                	ret

0000000080001ec4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ec4:	1101                	addi	sp,sp,-32
    80001ec6:	ec06                	sd	ra,24(sp)
    80001ec8:	e822                	sd	s0,16(sp)
    80001eca:	e426                	sd	s1,8(sp)
    80001ecc:	1000                	addi	s0,sp,32
  push_off();
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	cca080e7          	jalr	-822(ra) # 80000b98 <push_off>
    80001ed6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ed8:	2781                	sext.w	a5,a5
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	00009717          	auipc	a4,0x9
    80001ee0:	2b470713          	addi	a4,a4,692 # 8000b190 <pid_lock>
    80001ee4:	97ba                	add	a5,a5,a4
    80001ee6:	7fa4                	ld	s1,120(a5)
  pop_off();
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	d62080e7          	jalr	-670(ra) # 80000c4a <pop_off>
  return p;
}
    80001ef0:	8526                	mv	a0,s1
    80001ef2:	60e2                	ld	ra,24(sp)
    80001ef4:	6442                	ld	s0,16(sp)
    80001ef6:	64a2                	ld	s1,8(sp)
    80001ef8:	6105                	addi	sp,sp,32
    80001efa:	8082                	ret

0000000080001efc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001efc:	1141                	addi	sp,sp,-16
    80001efe:	e406                	sd	ra,8(sp)
    80001f00:	e022                	sd	s0,0(sp)
    80001f02:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f04:	00000097          	auipc	ra,0x0
    80001f08:	fc0080e7          	jalr	-64(ra) # 80001ec4 <myproc>
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d9e080e7          	jalr	-610(ra) # 80000caa <release>

  if (first) {
    80001f14:	00007797          	auipc	a5,0x7
    80001f18:	14c7a783          	lw	a5,332(a5) # 80009060 <first.1725>
    80001f1c:	eb89                	bnez	a5,80001f2e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001f1e:	00001097          	auipc	ra,0x1
    80001f22:	410080e7          	jalr	1040(ra) # 8000332e <usertrapret>
}
    80001f26:	60a2                	ld	ra,8(sp)
    80001f28:	6402                	ld	s0,0(sp)
    80001f2a:	0141                	addi	sp,sp,16
    80001f2c:	8082                	ret
    first = 0;
    80001f2e:	00007797          	auipc	a5,0x7
    80001f32:	1207a923          	sw	zero,306(a5) # 80009060 <first.1725>
    fsinit(ROOTDEV);
    80001f36:	4505                	li	a0,1
    80001f38:	00002097          	auipc	ra,0x2
    80001f3c:	138080e7          	jalr	312(ra) # 80004070 <fsinit>
    80001f40:	bff9                	j	80001f1e <forkret+0x22>

0000000080001f42 <allocpid>:
allocpid() { //changed as ordered in task 2
    80001f42:	1101                	addi	sp,sp,-32
    80001f44:	ec06                	sd	ra,24(sp)
    80001f46:	e822                	sd	s0,16(sp)
    80001f48:	e426                	sd	s1,8(sp)
    80001f4a:	e04a                	sd	s2,0(sp)
    80001f4c:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001f4e:	00007917          	auipc	s2,0x7
    80001f52:	12290913          	addi	s2,s2,290 # 80009070 <nextpid>
    80001f56:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001f5a:	0014861b          	addiw	a2,s1,1
    80001f5e:	85a6                	mv	a1,s1
    80001f60:	854a                	mv	a0,s2
    80001f62:	00005097          	auipc	ra,0x5
    80001f66:	f14080e7          	jalr	-236(ra) # 80006e76 <cas>
    80001f6a:	f575                	bnez	a0,80001f56 <allocpid+0x14>
}
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	60e2                	ld	ra,24(sp)
    80001f70:	6442                	ld	s0,16(sp)
    80001f72:	64a2                	ld	s1,8(sp)
    80001f74:	6902                	ld	s2,0(sp)
    80001f76:	6105                	addi	sp,sp,32
    80001f78:	8082                	ret

0000000080001f7a <proc_pagetable>:
{
    80001f7a:	1101                	addi	sp,sp,-32
    80001f7c:	ec06                	sd	ra,24(sp)
    80001f7e:	e822                	sd	s0,16(sp)
    80001f80:	e426                	sd	s1,8(sp)
    80001f82:	e04a                	sd	s2,0(sp)
    80001f84:	1000                	addi	s0,sp,32
    80001f86:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	3d6080e7          	jalr	982(ra) # 8000135e <uvmcreate>
    80001f90:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f92:	c121                	beqz	a0,80001fd2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f94:	4729                	li	a4,10
    80001f96:	00005697          	auipc	a3,0x5
    80001f9a:	06a68693          	addi	a3,a3,106 # 80007000 <_trampoline>
    80001f9e:	6605                	lui	a2,0x1
    80001fa0:	040005b7          	lui	a1,0x4000
    80001fa4:	15fd                	addi	a1,a1,-1
    80001fa6:	05b2                	slli	a1,a1,0xc
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	12c080e7          	jalr	300(ra) # 800010d4 <mappages>
    80001fb0:	02054863          	bltz	a0,80001fe0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001fb4:	4719                	li	a4,6
    80001fb6:	07893683          	ld	a3,120(s2)
    80001fba:	6605                	lui	a2,0x1
    80001fbc:	020005b7          	lui	a1,0x2000
    80001fc0:	15fd                	addi	a1,a1,-1
    80001fc2:	05b6                	slli	a1,a1,0xd
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	10e080e7          	jalr	270(ra) # 800010d4 <mappages>
    80001fce:	02054163          	bltz	a0,80001ff0 <proc_pagetable+0x76>
}
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	60e2                	ld	ra,24(sp)
    80001fd6:	6442                	ld	s0,16(sp)
    80001fd8:	64a2                	ld	s1,8(sp)
    80001fda:	6902                	ld	s2,0(sp)
    80001fdc:	6105                	addi	sp,sp,32
    80001fde:	8082                	ret
    uvmfree(pagetable, 0);
    80001fe0:	4581                	li	a1,0
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	576080e7          	jalr	1398(ra) # 8000155a <uvmfree>
    return 0;
    80001fec:	4481                	li	s1,0
    80001fee:	b7d5                	j	80001fd2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ff0:	4681                	li	a3,0
    80001ff2:	4605                	li	a2,1
    80001ff4:	040005b7          	lui	a1,0x4000
    80001ff8:	15fd                	addi	a1,a1,-1
    80001ffa:	05b2                	slli	a1,a1,0xc
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	29c080e7          	jalr	668(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80002006:	4581                	li	a1,0
    80002008:	8526                	mv	a0,s1
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	550080e7          	jalr	1360(ra) # 8000155a <uvmfree>
    return 0;
    80002012:	4481                	li	s1,0
    80002014:	bf7d                	j	80001fd2 <proc_pagetable+0x58>

0000000080002016 <proc_freepagetable>:
{
    80002016:	1101                	addi	sp,sp,-32
    80002018:	ec06                	sd	ra,24(sp)
    8000201a:	e822                	sd	s0,16(sp)
    8000201c:	e426                	sd	s1,8(sp)
    8000201e:	e04a                	sd	s2,0(sp)
    80002020:	1000                	addi	s0,sp,32
    80002022:	84aa                	mv	s1,a0
    80002024:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002026:	4681                	li	a3,0
    80002028:	4605                	li	a2,1
    8000202a:	040005b7          	lui	a1,0x4000
    8000202e:	15fd                	addi	a1,a1,-1
    80002030:	05b2                	slli	a1,a1,0xc
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	268080e7          	jalr	616(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000203a:	4681                	li	a3,0
    8000203c:	4605                	li	a2,1
    8000203e:	020005b7          	lui	a1,0x2000
    80002042:	15fd                	addi	a1,a1,-1
    80002044:	05b6                	slli	a1,a1,0xd
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	252080e7          	jalr	594(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80002050:	85ca                	mv	a1,s2
    80002052:	8526                	mv	a0,s1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	506080e7          	jalr	1286(ra) # 8000155a <uvmfree>
}
    8000205c:	60e2                	ld	ra,24(sp)
    8000205e:	6442                	ld	s0,16(sp)
    80002060:	64a2                	ld	s1,8(sp)
    80002062:	6902                	ld	s2,0(sp)
    80002064:	6105                	addi	sp,sp,32
    80002066:	8082                	ret

0000000080002068 <freeproc>:
{
    80002068:	7139                	addi	sp,sp,-64
    8000206a:	fc06                	sd	ra,56(sp)
    8000206c:	f822                	sd	s0,48(sp)
    8000206e:	f426                	sd	s1,40(sp)
    80002070:	f04a                	sd	s2,32(sp)
    80002072:	0080                	addi	s0,sp,64
    80002074:	84aa                	mv	s1,a0
  printf("entered freeproc\n");
    80002076:	00006517          	auipc	a0,0x6
    8000207a:	38250513          	addi	a0,a0,898 # 800083f8 <digits+0x3b8>
    8000207e:	ffffe097          	auipc	ra,0xffffe
    80002082:	50a080e7          	jalr	1290(ra) # 80000588 <printf>
  if(p->trapframe)
    80002086:	7ca8                	ld	a0,120(s1)
    80002088:	c509                	beqz	a0,80002092 <freeproc+0x2a>
    kfree((void*)p->trapframe);
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	96e080e7          	jalr	-1682(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002092:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80002096:	78a8                	ld	a0,112(s1)
    80002098:	c511                	beqz	a0,800020a4 <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    8000209a:	74ac                	ld	a1,104(s1)
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	f7a080e7          	jalr	-134(ra) # 80002016 <proc_freepagetable>
  p->pagetable = 0;
    800020a4:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    800020a8:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    800020ac:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800020b0:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    800020b4:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    800020b8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800020bc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800020c0:	0204a623          	sw	zero,44(s1)
  printf("calling remove from freeproc to remove it from the zombie list p->index=%d p->state=\n",p->index,p->state);
    800020c4:	4c90                	lw	a2,24(s1)
    800020c6:	5c8c                	lw	a1,56(s1)
    800020c8:	00006517          	auipc	a0,0x6
    800020cc:	34850513          	addi	a0,a0,840 # 80008410 <digits+0x3d0>
    800020d0:	ffffe097          	auipc	ra,0xffffe
    800020d4:	4b8080e7          	jalr	1208(ra) # 80000588 <printf>
 remove_from_list(p->index,&zombie,zombie_head);
    800020d8:	00009917          	auipc	s2,0x9
    800020dc:	0b890913          	addi	s2,s2,184 # 8000b190 <pid_lock>
    800020e0:	04893783          	ld	a5,72(s2)
    800020e4:	fcf43023          	sd	a5,-64(s0)
    800020e8:	05093783          	ld	a5,80(s2)
    800020ec:	fcf43423          	sd	a5,-56(s0)
    800020f0:	05893783          	ld	a5,88(s2)
    800020f4:	fcf43823          	sd	a5,-48(s0)
    800020f8:	fc040613          	addi	a2,s0,-64
    800020fc:	00007597          	auipc	a1,0x7
    80002100:	f6c58593          	addi	a1,a1,-148 # 80009068 <zombie>
    80002104:	5c88                	lw	a0,56(s1)
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	82c080e7          	jalr	-2004(ra) # 80001932 <remove_from_list>
  printf("doen remove from freeproc to remove it from the zombie list p->index=%d p->state=\n",p->index,p->state);
    8000210e:	4c90                	lw	a2,24(s1)
    80002110:	5c8c                	lw	a1,56(s1)
    80002112:	00006517          	auipc	a0,0x6
    80002116:	35650513          	addi	a0,a0,854 # 80008468 <digits+0x428>
    8000211a:	ffffe097          	auipc	ra,0xffffe
    8000211e:	46e080e7          	jalr	1134(ra) # 80000588 <printf>
  p->state = UNUSED;
    80002122:	0004ac23          	sw	zero,24(s1)
  printf("calling insert from freeproc\n");
    80002126:	00006517          	auipc	a0,0x6
    8000212a:	39a50513          	addi	a0,a0,922 # 800084c0 <digits+0x480>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	45a080e7          	jalr	1114(ra) # 80000588 <printf>
  insert_to_list(p->index,&unused,unused_head);
    80002136:	06093783          	ld	a5,96(s2)
    8000213a:	fcf43023          	sd	a5,-64(s0)
    8000213e:	06893783          	ld	a5,104(s2)
    80002142:	fcf43423          	sd	a5,-56(s0)
    80002146:	07093783          	ld	a5,112(s2)
    8000214a:	fcf43823          	sd	a5,-48(s0)
    8000214e:	fc040613          	addi	a2,s0,-64
    80002152:	00007597          	auipc	a1,0x7
    80002156:	f1258593          	addi	a1,a1,-238 # 80009064 <unused>
    8000215a:	5c88                	lw	a0,56(s1)
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	9f0080e7          	jalr	-1552(ra) # 80001b4c <insert_to_list>
  printf("the head of the unused list is %d ",unused);
    80002164:	00007597          	auipc	a1,0x7
    80002168:	f005a583          	lw	a1,-256(a1) # 80009064 <unused>
    8000216c:	00006517          	auipc	a0,0x6
    80002170:	37450513          	addi	a0,a0,884 # 800084e0 <digits+0x4a0>
    80002174:	ffffe097          	auipc	ra,0xffffe
    80002178:	414080e7          	jalr	1044(ra) # 80000588 <printf>
  printf("exiting insert from freeproc\n");
    8000217c:	00006517          	auipc	a0,0x6
    80002180:	38c50513          	addi	a0,a0,908 # 80008508 <digits+0x4c8>
    80002184:	ffffe097          	auipc	ra,0xffffe
    80002188:	404080e7          	jalr	1028(ra) # 80000588 <printf>
  printf("exiting from freeproc\n");
    8000218c:	00006517          	auipc	a0,0x6
    80002190:	39c50513          	addi	a0,a0,924 # 80008528 <digits+0x4e8>
    80002194:	ffffe097          	auipc	ra,0xffffe
    80002198:	3f4080e7          	jalr	1012(ra) # 80000588 <printf>
}
    8000219c:	70e2                	ld	ra,56(sp)
    8000219e:	7442                	ld	s0,48(sp)
    800021a0:	74a2                	ld	s1,40(sp)
    800021a2:	7902                	ld	s2,32(sp)
    800021a4:	6121                	addi	sp,sp,64
    800021a6:	8082                	ret

00000000800021a8 <allocproc>:
{
    800021a8:	715d                	addi	sp,sp,-80
    800021aa:	e486                	sd	ra,72(sp)
    800021ac:	e0a2                	sd	s0,64(sp)
    800021ae:	fc26                	sd	s1,56(sp)
    800021b0:	f84a                	sd	s2,48(sp)
    800021b2:	f44e                	sd	s3,40(sp)
    800021b4:	f052                	sd	s4,32(sp)
    800021b6:	0880                	addi	s0,sp,80
  printf("entered allocproc\n");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	38850513          	addi	a0,a0,904 # 80008540 <digits+0x500>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	3c8080e7          	jalr	968(ra) # 80000588 <printf>
  if(unused != -1){
    800021c8:	00007917          	auipc	s2,0x7
    800021cc:	e9c92903          	lw	s2,-356(s2) # 80009064 <unused>
    800021d0:	57fd                	li	a5,-1
  return 0;
    800021d2:	4481                	li	s1,0
  if(unused != -1){
    800021d4:	12f90563          	beq	s2,a5,800022fe <allocproc+0x156>
    p = &proc[unused];
    800021d8:	18800993          	li	s3,392
    800021dc:	033909b3          	mul	s3,s2,s3
    800021e0:	00009497          	auipc	s1,0x9
    800021e4:	0c048493          	addi	s1,s1,192 # 8000b2a0 <proc>
    800021e8:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    800021ea:	8526                	mv	a0,s1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	9f8080e7          	jalr	-1544(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	d4e080e7          	jalr	-690(ra) # 80001f42 <allocpid>
    800021fc:	d888                	sw	a0,48(s1)
  printf("removed from the unused list is %d\n ",unused);
    800021fe:	00007a17          	auipc	s4,0x7
    80002202:	e66a0a13          	addi	s4,s4,-410 # 80009064 <unused>
    80002206:	000a2583          	lw	a1,0(s4)
    8000220a:	00006517          	auipc	a0,0x6
    8000220e:	34e50513          	addi	a0,a0,846 # 80008558 <digits+0x518>
    80002212:	ffffe097          	auipc	ra,0xffffe
    80002216:	376080e7          	jalr	886(ra) # 80000588 <printf>
  remove_from_list(p->index,&unused,unused_head);
    8000221a:	00009797          	auipc	a5,0x9
    8000221e:	f7678793          	addi	a5,a5,-138 # 8000b190 <pid_lock>
    80002222:	73b8                	ld	a4,96(a5)
    80002224:	fae43823          	sd	a4,-80(s0)
    80002228:	77b8                	ld	a4,104(a5)
    8000222a:	fae43c23          	sd	a4,-72(s0)
    8000222e:	7bbc                	ld	a5,112(a5)
    80002230:	fcf43023          	sd	a5,-64(s0)
    80002234:	fb040613          	addi	a2,s0,-80
    80002238:	85d2                	mv	a1,s4
    8000223a:	5c88                	lw	a0,56(s1)
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	6f6080e7          	jalr	1782(ra) # 80001932 <remove_from_list>
  printf("the head of the unused list is %d \n",unused);
    80002244:	000a2583          	lw	a1,0(s4)
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	33850513          	addi	a0,a0,824 # 80008580 <digits+0x540>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	338080e7          	jalr	824(ra) # 80000588 <printf>
  printf("allocproc, p->state= %d\n", p->state);
    80002258:	4c8c                	lw	a1,24(s1)
    8000225a:	00006517          	auipc	a0,0x6
    8000225e:	34e50513          	addi	a0,a0,846 # 800085a8 <digits+0x568>
    80002262:	ffffe097          	auipc	ra,0xffffe
    80002266:	326080e7          	jalr	806(ra) # 80000588 <printf>
  p->state = USED;
    8000226a:	4785                	li	a5,1
    8000226c:	cc9c                	sw	a5,24(s1)
  printf("allocproc, p->state= %d\n", p->state);
    8000226e:	4585                	li	a1,1
    80002270:	00006517          	auipc	a0,0x6
    80002274:	33850513          	addi	a0,a0,824 # 800085a8 <digits+0x568>
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	310080e7          	jalr	784(ra) # 80000588 <printf>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	874080e7          	jalr	-1932(ra) # 80000af4 <kalloc>
    80002288:	8a2a                	mv	s4,a0
    8000228a:	fca8                	sd	a0,120(s1)
    8000228c:	c151                	beqz	a0,80002310 <allocproc+0x168>
  p->pagetable = proc_pagetable(p);
    8000228e:	8526                	mv	a0,s1
    80002290:	00000097          	auipc	ra,0x0
    80002294:	cea080e7          	jalr	-790(ra) # 80001f7a <proc_pagetable>
    80002298:	8a2a                	mv	s4,a0
    8000229a:	18800793          	li	a5,392
    8000229e:	02f90733          	mul	a4,s2,a5
    800022a2:	00009797          	auipc	a5,0x9
    800022a6:	ffe78793          	addi	a5,a5,-2 # 8000b2a0 <proc>
    800022aa:	97ba                	add	a5,a5,a4
    800022ac:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800022ae:	c549                	beqz	a0,80002338 <allocproc+0x190>
  memset(&p->context, 0, sizeof(p->context));
    800022b0:	08098513          	addi	a0,s3,128
    800022b4:	00009a17          	auipc	s4,0x9
    800022b8:	feca0a13          	addi	s4,s4,-20 # 8000b2a0 <proc>
    800022bc:	07000613          	li	a2,112
    800022c0:	4581                	li	a1,0
    800022c2:	9552                	add	a0,a0,s4
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	a40080e7          	jalr	-1472(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    800022cc:	18800793          	li	a5,392
    800022d0:	02f90933          	mul	s2,s2,a5
    800022d4:	9952                	add	s2,s2,s4
    800022d6:	00000797          	auipc	a5,0x0
    800022da:	c2678793          	addi	a5,a5,-986 # 80001efc <forkret>
    800022de:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    800022e2:	06093783          	ld	a5,96(s2)
    800022e6:	6705                	lui	a4,0x1
    800022e8:	97ba                	add	a5,a5,a4
    800022ea:	08f93423          	sd	a5,136(s2)
  printf("exit allocproc in 3.\n");
    800022ee:	00006517          	auipc	a0,0x6
    800022f2:	30a50513          	addi	a0,a0,778 # 800085f8 <digits+0x5b8>
    800022f6:	ffffe097          	auipc	ra,0xffffe
    800022fa:	292080e7          	jalr	658(ra) # 80000588 <printf>
}
    800022fe:	8526                	mv	a0,s1
    80002300:	60a6                	ld	ra,72(sp)
    80002302:	6406                	ld	s0,64(sp)
    80002304:	74e2                	ld	s1,56(sp)
    80002306:	7942                	ld	s2,48(sp)
    80002308:	79a2                	ld	s3,40(sp)
    8000230a:	7a02                	ld	s4,32(sp)
    8000230c:	6161                	addi	sp,sp,80
    8000230e:	8082                	ret
    freeproc(p);
    80002310:	8526                	mv	a0,s1
    80002312:	00000097          	auipc	ra,0x0
    80002316:	d56080e7          	jalr	-682(ra) # 80002068 <freeproc>
    release(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	98e080e7          	jalr	-1650(ra) # 80000caa <release>
    printf("exit allocproc in 1.\n");
    80002324:	00006517          	auipc	a0,0x6
    80002328:	2a450513          	addi	a0,a0,676 # 800085c8 <digits+0x588>
    8000232c:	ffffe097          	auipc	ra,0xffffe
    80002330:	25c080e7          	jalr	604(ra) # 80000588 <printf>
    return 0;
    80002334:	84d2                	mv	s1,s4
    80002336:	b7e1                	j	800022fe <allocproc+0x156>
    freeproc(p);
    80002338:	8526                	mv	a0,s1
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	d2e080e7          	jalr	-722(ra) # 80002068 <freeproc>
    release(&p->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	966080e7          	jalr	-1690(ra) # 80000caa <release>
    printf("exit allocproc in 2.\n");
    8000234c:	00006517          	auipc	a0,0x6
    80002350:	29450513          	addi	a0,a0,660 # 800085e0 <digits+0x5a0>
    80002354:	ffffe097          	auipc	ra,0xffffe
    80002358:	234080e7          	jalr	564(ra) # 80000588 <printf>
    return 0;
    8000235c:	84d2                	mv	s1,s4
    8000235e:	b745                	j	800022fe <allocproc+0x156>

0000000080002360 <userinit>:
{
    80002360:	7139                	addi	sp,sp,-64
    80002362:	fc06                	sd	ra,56(sp)
    80002364:	f822                	sd	s0,48(sp)
    80002366:	f426                	sd	s1,40(sp)
    80002368:	0080                	addi	s0,sp,64
  printf("entered userinit\n");
    8000236a:	00006517          	auipc	a0,0x6
    8000236e:	2a650513          	addi	a0,a0,678 # 80008610 <digits+0x5d0>
    80002372:	ffffe097          	auipc	ra,0xffffe
    80002376:	216080e7          	jalr	534(ra) # 80000588 <printf>
  p = allocproc();
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	e2e080e7          	jalr	-466(ra) # 800021a8 <allocproc>
    80002382:	84aa                	mv	s1,a0
  printf("come back to userinit from allocproc with state of:%d\n",p->state);
    80002384:	4d0c                	lw	a1,24(a0)
    80002386:	00006517          	auipc	a0,0x6
    8000238a:	2a250513          	addi	a0,a0,674 # 80008628 <digits+0x5e8>
    8000238e:	ffffe097          	auipc	ra,0xffffe
    80002392:	1fa080e7          	jalr	506(ra) # 80000588 <printf>
  initproc = p;
    80002396:	00008797          	auipc	a5,0x8
    8000239a:	c897bd23          	sd	s1,-870(a5) # 8000a030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000239e:	03400613          	li	a2,52
    800023a2:	00007597          	auipc	a1,0x7
    800023a6:	cde58593          	addi	a1,a1,-802 # 80009080 <initcode>
    800023aa:	78a8                	ld	a0,112(s1)
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	fe0080e7          	jalr	-32(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    800023b4:	6785                	lui	a5,0x1
    800023b6:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800023b8:	7cb8                	ld	a4,120(s1)
    800023ba:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800023be:	7cb8                	ld	a4,120(s1)
    800023c0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800023c2:	4641                	li	a2,16
    800023c4:	00006597          	auipc	a1,0x6
    800023c8:	29c58593          	addi	a1,a1,668 # 80008660 <digits+0x620>
    800023cc:	17848513          	addi	a0,s1,376
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	a86080e7          	jalr	-1402(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800023d8:	00006517          	auipc	a0,0x6
    800023dc:	29850513          	addi	a0,a0,664 # 80008670 <digits+0x630>
    800023e0:	00002097          	auipc	ra,0x2
    800023e4:	6be080e7          	jalr	1726(ra) # 80004a9e <namei>
    800023e8:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    800023ec:	478d                	li	a5,3
    800023ee:	cc9c                	sw	a5,24(s1)
  printf("before inserting from the %d list in userinit\n",p->state);
    800023f0:	458d                	li	a1,3
    800023f2:	00006517          	auipc	a0,0x6
    800023f6:	28650513          	addi	a0,a0,646 # 80008678 <digits+0x638>
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	18e080e7          	jalr	398(ra) # 80000588 <printf>
  insert_to_list(p->index,&cpus_ll[0],cpus_head[0]);
    80002402:	00009797          	auipc	a5,0x9
    80002406:	d8e78793          	addi	a5,a5,-626 # 8000b190 <pid_lock>
    8000240a:	7ff8                	ld	a4,248(a5)
    8000240c:	fce43023          	sd	a4,-64(s0)
    80002410:	1007b703          	ld	a4,256(a5)
    80002414:	fce43423          	sd	a4,-56(s0)
    80002418:	1087b783          	ld	a5,264(a5)
    8000241c:	fcf43823          	sd	a5,-48(s0)
    80002420:	fc040613          	addi	a2,s0,-64
    80002424:	00008597          	auipc	a1,0x8
    80002428:	c0458593          	addi	a1,a1,-1020 # 8000a028 <cpus_ll>
    8000242c:	5c88                	lw	a0,56(s1)
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	71e080e7          	jalr	1822(ra) # 80001b4c <insert_to_list>
  printf("after inserting from the %d list in userinit\n",p->state);
    80002436:	4c8c                	lw	a1,24(s1)
    80002438:	00006517          	auipc	a0,0x6
    8000243c:	27050513          	addi	a0,a0,624 # 800086a8 <digits+0x668>
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	148080e7          	jalr	328(ra) # 80000588 <printf>
  release(&p->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	860080e7          	jalr	-1952(ra) # 80000caa <release>
  printf("exiting from userinit\n");
    80002452:	00006517          	auipc	a0,0x6
    80002456:	28650513          	addi	a0,a0,646 # 800086d8 <digits+0x698>
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	12e080e7          	jalr	302(ra) # 80000588 <printf>
}
    80002462:	70e2                	ld	ra,56(sp)
    80002464:	7442                	ld	s0,48(sp)
    80002466:	74a2                	ld	s1,40(sp)
    80002468:	6121                	addi	sp,sp,64
    8000246a:	8082                	ret

000000008000246c <growproc>:
{
    8000246c:	1101                	addi	sp,sp,-32
    8000246e:	ec06                	sd	ra,24(sp)
    80002470:	e822                	sd	s0,16(sp)
    80002472:	e426                	sd	s1,8(sp)
    80002474:	e04a                	sd	s2,0(sp)
    80002476:	1000                	addi	s0,sp,32
    80002478:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	a4a080e7          	jalr	-1462(ra) # 80001ec4 <myproc>
    80002482:	892a                	mv	s2,a0
  sz = p->sz;
    80002484:	752c                	ld	a1,104(a0)
    80002486:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000248a:	00904f63          	bgtz	s1,800024a8 <growproc+0x3c>
  } else if(n < 0){
    8000248e:	0204cc63          	bltz	s1,800024c6 <growproc+0x5a>
  p->sz = sz;
    80002492:	1602                	slli	a2,a2,0x20
    80002494:	9201                	srli	a2,a2,0x20
    80002496:	06c93423          	sd	a2,104(s2)
  return 0;
    8000249a:	4501                	li	a0,0
}
    8000249c:	60e2                	ld	ra,24(sp)
    8000249e:	6442                	ld	s0,16(sp)
    800024a0:	64a2                	ld	s1,8(sp)
    800024a2:	6902                	ld	s2,0(sp)
    800024a4:	6105                	addi	sp,sp,32
    800024a6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800024a8:	9e25                	addw	a2,a2,s1
    800024aa:	1602                	slli	a2,a2,0x20
    800024ac:	9201                	srli	a2,a2,0x20
    800024ae:	1582                	slli	a1,a1,0x20
    800024b0:	9181                	srli	a1,a1,0x20
    800024b2:	7928                	ld	a0,112(a0)
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	f92080e7          	jalr	-110(ra) # 80001446 <uvmalloc>
    800024bc:	0005061b          	sext.w	a2,a0
    800024c0:	fa69                	bnez	a2,80002492 <growproc+0x26>
      return -1;
    800024c2:	557d                	li	a0,-1
    800024c4:	bfe1                	j	8000249c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800024c6:	9e25                	addw	a2,a2,s1
    800024c8:	1602                	slli	a2,a2,0x20
    800024ca:	9201                	srli	a2,a2,0x20
    800024cc:	1582                	slli	a1,a1,0x20
    800024ce:	9181                	srli	a1,a1,0x20
    800024d0:	7928                	ld	a0,112(a0)
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	f2c080e7          	jalr	-212(ra) # 800013fe <uvmdealloc>
    800024da:	0005061b          	sext.w	a2,a0
    800024de:	bf55                	j	80002492 <growproc+0x26>

00000000800024e0 <fork>:
{
    800024e0:	715d                	addi	sp,sp,-80
    800024e2:	e486                	sd	ra,72(sp)
    800024e4:	e0a2                	sd	s0,64(sp)
    800024e6:	fc26                	sd	s1,56(sp)
    800024e8:	f84a                	sd	s2,48(sp)
    800024ea:	f44e                	sd	s3,40(sp)
    800024ec:	f052                	sd	s4,32(sp)
    800024ee:	0880                	addi	s0,sp,80
  printf("entered fork\n");
    800024f0:	00006517          	auipc	a0,0x6
    800024f4:	20050513          	addi	a0,a0,512 # 800086f0 <digits+0x6b0>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	090080e7          	jalr	144(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002500:	00000097          	auipc	ra,0x0
    80002504:	9c4080e7          	jalr	-1596(ra) # 80001ec4 <myproc>
    80002508:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	c9e080e7          	jalr	-866(ra) # 800021a8 <allocproc>
    80002512:	22050963          	beqz	a0,80002744 <fork+0x264>
    80002516:	89aa                	mv	s3,a0
  printf("pstate: %d pindex: %d\nnpstate: %d npindex: %d\n", a, p->index, np->state, np->index);
    80002518:	5d18                	lw	a4,56(a0)
    8000251a:	4d14                	lw	a3,24(a0)
    8000251c:	03892603          	lw	a2,56(s2)
    80002520:	01892583          	lw	a1,24(s2)
    80002524:	00006517          	auipc	a0,0x6
    80002528:	1dc50513          	addi	a0,a0,476 # 80008700 <digits+0x6c0>
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	05c080e7          	jalr	92(ra) # 80000588 <printf>
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002534:	06893603          	ld	a2,104(s2)
    80002538:	0709b583          	ld	a1,112(s3)
    8000253c:	07093503          	ld	a0,112(s2)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	052080e7          	jalr	82(ra) # 80001592 <uvmcopy>
    80002548:	04054663          	bltz	a0,80002594 <fork+0xb4>
  np->sz = p->sz;
    8000254c:	06893783          	ld	a5,104(s2)
    80002550:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80002554:	07893683          	ld	a3,120(s2)
    80002558:	87b6                	mv	a5,a3
    8000255a:	0789b703          	ld	a4,120(s3)
    8000255e:	12068693          	addi	a3,a3,288
    80002562:	0007b803          	ld	a6,0(a5)
    80002566:	6788                	ld	a0,8(a5)
    80002568:	6b8c                	ld	a1,16(a5)
    8000256a:	6f90                	ld	a2,24(a5)
    8000256c:	01073023          	sd	a6,0(a4)
    80002570:	e708                	sd	a0,8(a4)
    80002572:	eb0c                	sd	a1,16(a4)
    80002574:	ef10                	sd	a2,24(a4)
    80002576:	02078793          	addi	a5,a5,32
    8000257a:	02070713          	addi	a4,a4,32
    8000257e:	fed792e3          	bne	a5,a3,80002562 <fork+0x82>
  np->trapframe->a0 = 0;
    80002582:	0789b783          	ld	a5,120(s3)
    80002586:	0607b823          	sd	zero,112(a5)
    8000258a:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000258e:	17000a13          	li	s4,368
    80002592:	a83d                	j	800025d0 <fork+0xf0>
    printf("here\n");
    80002594:	00006517          	auipc	a0,0x6
    80002598:	19c50513          	addi	a0,a0,412 # 80008730 <digits+0x6f0>
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fec080e7          	jalr	-20(ra) # 80000588 <printf>
    freeproc(np);
    800025a4:	854e                	mv	a0,s3
    800025a6:	00000097          	auipc	ra,0x0
    800025aa:	ac2080e7          	jalr	-1342(ra) # 80002068 <freeproc>
    release(&np->lock);
    800025ae:	854e                	mv	a0,s3
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	6fa080e7          	jalr	1786(ra) # 80000caa <release>
    return -1;
    800025b8:	5a7d                	li	s4,-1
    800025ba:	aaa5                	j	80002732 <fork+0x252>
      np->ofile[i] = filedup(p->ofile[i]);
    800025bc:	00003097          	auipc	ra,0x3
    800025c0:	b78080e7          	jalr	-1160(ra) # 80005134 <filedup>
    800025c4:	009987b3          	add	a5,s3,s1
    800025c8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800025ca:	04a1                	addi	s1,s1,8
    800025cc:	01448763          	beq	s1,s4,800025da <fork+0xfa>
    if(p->ofile[i])
    800025d0:	009907b3          	add	a5,s2,s1
    800025d4:	6388                	ld	a0,0(a5)
    800025d6:	f17d                	bnez	a0,800025bc <fork+0xdc>
    800025d8:	bfcd                	j	800025ca <fork+0xea>
  np->cwd = idup(p->cwd);
    800025da:	17093503          	ld	a0,368(s2)
    800025de:	00002097          	auipc	ra,0x2
    800025e2:	ccc080e7          	jalr	-820(ra) # 800042aa <idup>
    800025e6:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800025ea:	17898493          	addi	s1,s3,376
    800025ee:	4641                	li	a2,16
    800025f0:	17890593          	addi	a1,s2,376
    800025f4:	8526                	mv	a0,s1
    800025f6:	fffff097          	auipc	ra,0xfffff
    800025fa:	860080e7          	jalr	-1952(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    800025fe:	0309aa03          	lw	s4,48(s3)
  np->cpu_num=p->cpu_num; //giving the child it's parent's cpu_num (the only change)
    80002602:	03492783          	lw	a5,52(s2)
    80002606:	02f9aa23          	sw	a5,52(s3)
  initlock(&p->linked_list_lock,"inbar");
    8000260a:	00006597          	auipc	a1,0x6
    8000260e:	d8658593          	addi	a1,a1,-634 # 80008390 <digits+0x350>
    80002612:	04090513          	addi	a0,s2,64
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	53e080e7          	jalr	1342(ra) # 80000b54 <initlock>
  printf("the linked list lock of the np %s is now initiallized.\n",np->name);
    8000261e:	85a6                	mv	a1,s1
    80002620:	00006517          	auipc	a0,0x6
    80002624:	11850513          	addi	a0,a0,280 # 80008738 <digits+0x6f8>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	f60080e7          	jalr	-160(ra) # 80000588 <printf>
  printf("559 release\n");
    80002630:	00006517          	auipc	a0,0x6
    80002634:	14050513          	addi	a0,a0,320 # 80008770 <digits+0x730>
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	f50080e7          	jalr	-176(ra) # 80000588 <printf>
  release(&np->lock);
    80002640:	854e                	mv	a0,s3
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	668080e7          	jalr	1640(ra) # 80000caa <release>
  acquire(&wait_lock);
    8000264a:	00009497          	auipc	s1,0x9
    8000264e:	b5e48493          	addi	s1,s1,-1186 # 8000b1a8 <wait_lock>
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	590080e7          	jalr	1424(ra) # 80000be4 <acquire>
  np->parent = p;
    8000265c:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	648080e7          	jalr	1608(ra) # 80000caa <release>
  acquire(&np->lock);
    8000266a:	854e                	mv	a0,s3
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	578080e7          	jalr	1400(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002674:	478d                	li	a5,3
    80002676:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(np->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    8000267a:	03492583          	lw	a1,52(s2)
    8000267e:	00159793          	slli	a5,a1,0x1
    80002682:	97ae                	add	a5,a5,a1
    80002684:	00379713          	slli	a4,a5,0x3
    80002688:	00009797          	auipc	a5,0x9
    8000268c:	b0878793          	addi	a5,a5,-1272 # 8000b190 <pid_lock>
    80002690:	97ba                	add	a5,a5,a4
    80002692:	7ff8                	ld	a4,248(a5)
    80002694:	fae43823          	sd	a4,-80(s0)
    80002698:	1007b703          	ld	a4,256(a5)
    8000269c:	fae43c23          	sd	a4,-72(s0)
    800026a0:	1087b783          	ld	a5,264(a5)
    800026a4:	fcf43023          	sd	a5,-64(s0)
    800026a8:	058a                	slli	a1,a1,0x2
    800026aa:	fb040613          	addi	a2,s0,-80
    800026ae:	00008797          	auipc	a5,0x8
    800026b2:	97a78793          	addi	a5,a5,-1670 # 8000a028 <cpus_ll>
    800026b6:	95be                	add	a1,a1,a5
    800026b8:	0389a503          	lw	a0,56(s3)
    800026bc:	fffff097          	auipc	ra,0xfffff
    800026c0:	490080e7          	jalr	1168(ra) # 80001b4c <insert_to_list>
  release(&np->lock);
    800026c4:	854e                	mv	a0,s3
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	5e4080e7          	jalr	1508(ra) # 80000caa <release>
  printf("the np->next=%d\n",np->next);
    800026ce:	03c9a583          	lw	a1,60(s3)
    800026d2:	2581                	sext.w	a1,a1
    800026d4:	00006517          	auipc	a0,0x6
    800026d8:	0ac50513          	addi	a0,a0,172 # 80008780 <digits+0x740>
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	eac080e7          	jalr	-340(ra) # 80000588 <printf>
  printf("the np->state=%d\n",np->state);
    800026e4:	0189a583          	lw	a1,24(s3)
    800026e8:	00006517          	auipc	a0,0x6
    800026ec:	0b050513          	addi	a0,a0,176 # 80008798 <digits+0x758>
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	e98080e7          	jalr	-360(ra) # 80000588 <printf>
  printf("the p->next=%d\n",p->next);
    800026f8:	03c92583          	lw	a1,60(s2)
    800026fc:	2581                	sext.w	a1,a1
    800026fe:	00006517          	auipc	a0,0x6
    80002702:	0b250513          	addi	a0,a0,178 # 800087b0 <digits+0x770>
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	e82080e7          	jalr	-382(ra) # 80000588 <printf>
  printf("the p->state=%d\n",p->state);
    8000270e:	01892583          	lw	a1,24(s2)
    80002712:	00006517          	auipc	a0,0x6
    80002716:	0ae50513          	addi	a0,a0,174 # 800087c0 <digits+0x780>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	e6e080e7          	jalr	-402(ra) # 80000588 <printf>
  printf("finished fork\n");
    80002722:	00006517          	auipc	a0,0x6
    80002726:	0b650513          	addi	a0,a0,182 # 800087d8 <digits+0x798>
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	e5e080e7          	jalr	-418(ra) # 80000588 <printf>
}
    80002732:	8552                	mv	a0,s4
    80002734:	60a6                	ld	ra,72(sp)
    80002736:	6406                	ld	s0,64(sp)
    80002738:	74e2                	ld	s1,56(sp)
    8000273a:	7942                	ld	s2,48(sp)
    8000273c:	79a2                	ld	s3,40(sp)
    8000273e:	7a02                	ld	s4,32(sp)
    80002740:	6161                	addi	sp,sp,80
    80002742:	8082                	ret
    return -1;
    80002744:	5a7d                	li	s4,-1
    80002746:	b7f5                	j	80002732 <fork+0x252>

0000000080002748 <scheduler>:
{
    80002748:	7119                	addi	sp,sp,-128
    8000274a:	fc86                	sd	ra,120(sp)
    8000274c:	f8a2                	sd	s0,112(sp)
    8000274e:	f4a6                	sd	s1,104(sp)
    80002750:	f0ca                	sd	s2,96(sp)
    80002752:	ecce                	sd	s3,88(sp)
    80002754:	e8d2                	sd	s4,80(sp)
    80002756:	e4d6                	sd	s5,72(sp)
    80002758:	e0da                	sd	s6,64(sp)
    8000275a:	fc5e                	sd	s7,56(sp)
    8000275c:	f862                	sd	s8,48(sp)
    8000275e:	f466                	sd	s9,40(sp)
    80002760:	f06a                	sd	s10,32(sp)
    80002762:	0100                	addi	s0,sp,128
  printf("entered scheduler\n");
    80002764:	00006517          	auipc	a0,0x6
    80002768:	08450513          	addi	a0,a0,132 # 800087e8 <digits+0x7a8>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	e1c080e7          	jalr	-484(ra) # 80000588 <printf>
  struct proc *p=myproc();
    80002774:	fffff097          	auipc	ra,0xfffff
    80002778:	750080e7          	jalr	1872(ra) # 80001ec4 <myproc>
    8000277c:	8492                	mv	s1,tp
  int id = r_tp();
    8000277e:	2481                	sext.w	s1,s1
    80002780:	8592                	mv	a1,tp
  printf("the cpuid=%d\n",cpuid());
    80002782:	2581                	sext.w	a1,a1
    80002784:	00006517          	auipc	a0,0x6
    80002788:	07c50513          	addi	a0,a0,124 # 80008800 <digits+0x7c0>
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	dfc080e7          	jalr	-516(ra) # 80000588 <printf>
  c->proc = 0;
    80002794:	00749c93          	slli	s9,s1,0x7
    80002798:	00009797          	auipc	a5,0x9
    8000279c:	9f878793          	addi	a5,a5,-1544 # 8000b190 <pid_lock>
    800027a0:	97e6                	add	a5,a5,s9
    800027a2:	0607bc23          	sd	zero,120(a5)
        swtch(&c->context, &p->context);
    800027a6:	00009797          	auipc	a5,0x9
    800027aa:	a6a78793          	addi	a5,a5,-1430 # 8000b210 <cpus+0x8>
    800027ae:	9cbe                	add	s9,s9,a5
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800027b0:	00008997          	auipc	s3,0x8
    800027b4:	87898993          	addi	s3,s3,-1928 # 8000a028 <cpus_ll>
    800027b8:	5a7d                	li	s4,-1
      acquire(&cpus_head[cpuid()]);
    800027ba:	00009d17          	auipc	s10,0x9
    800027be:	9d6d0d13          	addi	s10,s10,-1578 # 8000b190 <pid_lock>
    800027c2:	00009b97          	auipc	s7,0x9
    800027c6:	ac6b8b93          	addi	s7,s7,-1338 # 8000b288 <cpus_head>
      p = &proc[cpus_ll[cpuid()]];
    800027ca:	00009b17          	auipc	s6,0x9
    800027ce:	ad6b0b13          	addi	s6,s6,-1322 # 8000b2a0 <proc>
        c->proc = p;
    800027d2:	049e                	slli	s1,s1,0x7
    800027d4:	009d0ab3          	add	s5,s10,s1
    800027d8:	a8e5                	j	800028d0 <scheduler+0x188>
    800027da:	8512                	mv	a0,tp
      acquire(&cpus_head[cpuid()]);
    800027dc:	0005079b          	sext.w	a5,a0
    800027e0:	00179513          	slli	a0,a5,0x1
    800027e4:	953e                	add	a0,a0,a5
    800027e6:	050e                	slli	a0,a0,0x3
    800027e8:	955e                	add	a0,a0,s7
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	3fa080e7          	jalr	1018(ra) # 80000be4 <acquire>
    800027f2:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    800027f4:	2781                	sext.w	a5,a5
    800027f6:	078a                	slli	a5,a5,0x2
    800027f8:	97ce                	add	a5,a5,s3
    800027fa:	0007a903          	lw	s2,0(a5)
    800027fe:	03890933          	mul	s2,s2,s8
    80002802:	016904b3          	add	s1,s2,s6
      printf("the pid of p after choosing:%d\n",p->pid);
    80002806:	588c                	lw	a1,48(s1)
    80002808:	00006517          	auipc	a0,0x6
    8000280c:	00850513          	addi	a0,a0,8 # 80008810 <digits+0x7d0>
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	d78080e7          	jalr	-648(ra) # 80000588 <printf>
    80002818:	8512                	mv	a0,tp
      release(&cpus_head[cpuid()]);
    8000281a:	0005079b          	sext.w	a5,a0
    8000281e:	00179513          	slli	a0,a5,0x1
    80002822:	953e                	add	a0,a0,a5
    80002824:	050e                	slli	a0,a0,0x3
    80002826:	955e                	add	a0,a0,s7
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	482080e7          	jalr	1154(ra) # 80000caa <release>
    80002830:	8592                	mv	a1,tp
    80002832:	8792                	mv	a5,tp
      remove_from_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
    80002834:	0007871b          	sext.w	a4,a5
    80002838:	00171793          	slli	a5,a4,0x1
    8000283c:	97ba                	add	a5,a5,a4
    8000283e:	078e                	slli	a5,a5,0x3
    80002840:	97ea                	add	a5,a5,s10
    80002842:	7ff8                	ld	a4,248(a5)
    80002844:	f8e43023          	sd	a4,-128(s0)
    80002848:	1007b703          	ld	a4,256(a5)
    8000284c:	f8e43423          	sd	a4,-120(s0)
    80002850:	1087b783          	ld	a5,264(a5)
    80002854:	f8f43823          	sd	a5,-112(s0)
    80002858:	2581                	sext.w	a1,a1
    8000285a:	058a                	slli	a1,a1,0x2
    8000285c:	f8040613          	addi	a2,s0,-128
    80002860:	95ce                	add	a1,a1,s3
    80002862:	5c88                	lw	a0,56(s1)
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	0ce080e7          	jalr	206(ra) # 80001932 <remove_from_list>
      acquire(&p->lock);
    8000286c:	8526                	mv	a0,s1
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	376080e7          	jalr	886(ra) # 80000be4 <acquire>
        printf("after rmoving from the %d list in scheduler\n",p->state);
    80002876:	4c8c                	lw	a1,24(s1)
    80002878:	00006517          	auipc	a0,0x6
    8000287c:	fb850513          	addi	a0,a0,-72 # 80008830 <digits+0x7f0>
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	d08080e7          	jalr	-760(ra) # 80000588 <printf>
        p->state = RUNNING;
    80002888:	4791                	li	a5,4
    8000288a:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    8000288c:	069abc23          	sd	s1,120(s5)
        swtch(&c->context, &p->context);
    80002890:	08090593          	addi	a1,s2,128
    80002894:	95da                	add	a1,a1,s6
    80002896:	8566                	mv	a0,s9
    80002898:	00001097          	auipc	ra,0x1
    8000289c:	9ec080e7          	jalr	-1556(ra) # 80003284 <swtch>
        printf("exit swtc with prosses index:%d and state of:%d\n",p->index,p->state);
    800028a0:	4c90                	lw	a2,24(s1)
    800028a2:	5c8c                	lw	a1,56(s1)
    800028a4:	00006517          	auipc	a0,0x6
    800028a8:	fbc50513          	addi	a0,a0,-68 # 80008860 <digits+0x820>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	cdc080e7          	jalr	-804(ra) # 80000588 <printf>
        c->proc = 0;
    800028b4:	060abc23          	sd	zero,120(s5)
        release(&p->lock);
    800028b8:	8526                	mv	a0,s1
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	3f0080e7          	jalr	1008(ra) # 80000caa <release>
    800028c2:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800028c4:	2781                	sext.w	a5,a5
    800028c6:	078a                	slli	a5,a5,0x2
    800028c8:	97ce                	add	a5,a5,s3
    800028ca:	439c                	lw	a5,0(a5)
    800028cc:	f14797e3          	bne	a5,s4,800027da <scheduler+0x92>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028d4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d8:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    800028dc:	8792                	mv	a5,tp
    800028de:	2781                	sext.w	a5,a5
    800028e0:	078a                	slli	a5,a5,0x2
    800028e2:	97ce                	add	a5,a5,s3
    800028e4:	439c                	lw	a5,0(a5)
    800028e6:	ff4785e3          	beq	a5,s4,800028d0 <scheduler+0x188>
    800028ea:	18800c13          	li	s8,392
    800028ee:	b5f5                	j	800027da <scheduler+0x92>

00000000800028f0 <sched>:
{
    800028f0:	7179                	addi	sp,sp,-48
    800028f2:	f406                	sd	ra,40(sp)
    800028f4:	f022                	sd	s0,32(sp)
    800028f6:	ec26                	sd	s1,24(sp)
    800028f8:	e84a                	sd	s2,16(sp)
    800028fa:	e44e                	sd	s3,8(sp)
    800028fc:	1800                	addi	s0,sp,48
  printf("entered sched\n");
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	f9a50513          	addi	a0,a0,-102 # 80008898 <digits+0x858>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c82080e7          	jalr	-894(ra) # 80000588 <printf>
  struct proc *p = myproc();
    8000290e:	fffff097          	auipc	ra,0xfffff
    80002912:	5b6080e7          	jalr	1462(ra) # 80001ec4 <myproc>
    80002916:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	252080e7          	jalr	594(ra) # 80000b6a <holding>
    80002920:	c93d                	beqz	a0,80002996 <sched+0xa6>
    80002922:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    80002924:	2781                	sext.w	a5,a5
    80002926:	079e                	slli	a5,a5,0x7
    80002928:	00009717          	auipc	a4,0x9
    8000292c:	86870713          	addi	a4,a4,-1944 # 8000b190 <pid_lock>
    80002930:	97ba                	add	a5,a5,a4
    80002932:	0f07a703          	lw	a4,240(a5)
    80002936:	4785                	li	a5,1
    80002938:	06f71763          	bne	a4,a5,800029a6 <sched+0xb6>
  if(p->state == RUNNING)
    8000293c:	4c98                	lw	a4,24(s1)
    8000293e:	4791                	li	a5,4
    80002940:	06f70b63          	beq	a4,a5,800029b6 <sched+0xc6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002944:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002948:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000294a:	efb5                	bnez	a5,800029c6 <sched+0xd6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000294c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000294e:	00009917          	auipc	s2,0x9
    80002952:	84290913          	addi	s2,s2,-1982 # 8000b190 <pid_lock>
    80002956:	2781                	sext.w	a5,a5
    80002958:	079e                	slli	a5,a5,0x7
    8000295a:	97ca                	add	a5,a5,s2
    8000295c:	0f47a983          	lw	s3,244(a5)
    80002960:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002962:	2781                	sext.w	a5,a5
    80002964:	079e                	slli	a5,a5,0x7
    80002966:	00009597          	auipc	a1,0x9
    8000296a:	8aa58593          	addi	a1,a1,-1878 # 8000b210 <cpus+0x8>
    8000296e:	95be                	add	a1,a1,a5
    80002970:	08048513          	addi	a0,s1,128
    80002974:	00001097          	auipc	ra,0x1
    80002978:	910080e7          	jalr	-1776(ra) # 80003284 <swtch>
    8000297c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000297e:	2781                	sext.w	a5,a5
    80002980:	079e                	slli	a5,a5,0x7
    80002982:	97ca                	add	a5,a5,s2
    80002984:	0f37aa23          	sw	s3,244(a5)
}
    80002988:	70a2                	ld	ra,40(sp)
    8000298a:	7402                	ld	s0,32(sp)
    8000298c:	64e2                	ld	s1,24(sp)
    8000298e:	6942                	ld	s2,16(sp)
    80002990:	69a2                	ld	s3,8(sp)
    80002992:	6145                	addi	sp,sp,48
    80002994:	8082                	ret
    panic("sched p->lock");
    80002996:	00006517          	auipc	a0,0x6
    8000299a:	f1250513          	addi	a0,a0,-238 # 800088a8 <digits+0x868>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	ba0080e7          	jalr	-1120(ra) # 8000053e <panic>
    panic("sched locks");
    800029a6:	00006517          	auipc	a0,0x6
    800029aa:	f1250513          	addi	a0,a0,-238 # 800088b8 <digits+0x878>
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	b90080e7          	jalr	-1136(ra) # 8000053e <panic>
    panic("sched running");
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	f1250513          	addi	a0,a0,-238 # 800088c8 <digits+0x888>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>
    panic("sched interruptible");
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	f1250513          	addi	a0,a0,-238 # 800088d8 <digits+0x898>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	b70080e7          	jalr	-1168(ra) # 8000053e <panic>

00000000800029d6 <yield>:
{
    800029d6:	7139                	addi	sp,sp,-64
    800029d8:	fc06                	sd	ra,56(sp)
    800029da:	f822                	sd	s0,48(sp)
    800029dc:	f426                	sd	s1,40(sp)
    800029de:	0080                	addi	s0,sp,64
  printf("entered yield\n");
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	f1050513          	addi	a0,a0,-240 # 800088f0 <digits+0x8b0>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	ba0080e7          	jalr	-1120(ra) # 80000588 <printf>
  struct proc *p = myproc();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	4d4080e7          	jalr	1236(ra) # 80001ec4 <myproc>
    800029f8:	84aa                	mv	s1,a0
  printf("the index of p is:%d ,the cpu_num of p is:%d, the state is:%d \n", p->index, p->cpu_num,p->state);
    800029fa:	4d14                	lw	a3,24(a0)
    800029fc:	5950                	lw	a2,52(a0)
    800029fe:	5d0c                	lw	a1,56(a0)
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	f0050513          	addi	a0,a0,-256 # 80008900 <digits+0x8c0>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b80080e7          	jalr	-1152(ra) # 80000588 <printf>
  insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002a10:	58cc                	lw	a1,52(s1)
    80002a12:	00159793          	slli	a5,a1,0x1
    80002a16:	97ae                	add	a5,a5,a1
    80002a18:	00379713          	slli	a4,a5,0x3
    80002a1c:	00008797          	auipc	a5,0x8
    80002a20:	77478793          	addi	a5,a5,1908 # 8000b190 <pid_lock>
    80002a24:	97ba                	add	a5,a5,a4
    80002a26:	7ff8                	ld	a4,248(a5)
    80002a28:	fce43023          	sd	a4,-64(s0)
    80002a2c:	1007b703          	ld	a4,256(a5)
    80002a30:	fce43423          	sd	a4,-56(s0)
    80002a34:	1087b783          	ld	a5,264(a5)
    80002a38:	fcf43823          	sd	a5,-48(s0)
    80002a3c:	058a                	slli	a1,a1,0x2
    80002a3e:	fc040613          	addi	a2,s0,-64
    80002a42:	00007797          	auipc	a5,0x7
    80002a46:	5e678793          	addi	a5,a5,1510 # 8000a028 <cpus_ll>
    80002a4a:	95be                	add	a1,a1,a5
    80002a4c:	5c88                	lw	a0,56(s1)
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	0fe080e7          	jalr	254(ra) # 80001b4c <insert_to_list>
  acquire(&p->lock);
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	18c080e7          	jalr	396(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002a60:	478d                	li	a5,3
    80002a62:	cc9c                	sw	a5,24(s1)
  sched();
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	e8c080e7          	jalr	-372(ra) # 800028f0 <sched>
  release(&p->lock);
    80002a6c:	8526                	mv	a0,s1
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	23c080e7          	jalr	572(ra) # 80000caa <release>
  printf("exit yield\n");
    80002a76:	00006517          	auipc	a0,0x6
    80002a7a:	eca50513          	addi	a0,a0,-310 # 80008940 <digits+0x900>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	b0a080e7          	jalr	-1270(ra) # 80000588 <printf>
}
    80002a86:	70e2                	ld	ra,56(sp)
    80002a88:	7442                	ld	s0,48(sp)
    80002a8a:	74a2                	ld	s1,40(sp)
    80002a8c:	6121                	addi	sp,sp,64
    80002a8e:	8082                	ret

0000000080002a90 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002a90:	715d                	addi	sp,sp,-80
    80002a92:	e486                	sd	ra,72(sp)
    80002a94:	e0a2                	sd	s0,64(sp)
    80002a96:	fc26                	sd	s1,56(sp)
    80002a98:	f84a                	sd	s2,48(sp)
    80002a9a:	f44e                	sd	s3,40(sp)
    80002a9c:	0880                	addi	s0,sp,80
    80002a9e:	89aa                	mv	s3,a0
    80002aa0:	892e                	mv	s2,a1
  //printf("entered sleep\n");
  struct proc *p = myproc();
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	422080e7          	jalr	1058(ra) # 80001ec4 <myproc>
    80002aaa:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  printf("the proccec index is:%d and the process state is:%d\n",p->index,p->state);
    80002aac:	4d10                	lw	a2,24(a0)
    80002aae:	5d0c                	lw	a1,56(a0)
    80002ab0:	00006517          	auipc	a0,0x6
    80002ab4:	ea050513          	addi	a0,a0,-352 # 80008950 <digits+0x910>
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	ad0080e7          	jalr	-1328(ra) # 80000588 <printf>
  int ret=insert_to_list(p->index,&sleeping,sleeping_head);
    80002ac0:	00008797          	auipc	a5,0x8
    80002ac4:	6d078793          	addi	a5,a5,1744 # 8000b190 <pid_lock>
    80002ac8:	7b98                	ld	a4,48(a5)
    80002aca:	fae43823          	sd	a4,-80(s0)
    80002ace:	7f98                	ld	a4,56(a5)
    80002ad0:	fae43c23          	sd	a4,-72(s0)
    80002ad4:	63bc                	ld	a5,64(a5)
    80002ad6:	fcf43023          	sd	a5,-64(s0)
    80002ada:	fb040613          	addi	a2,s0,-80
    80002ade:	00006597          	auipc	a1,0x6
    80002ae2:	58e58593          	addi	a1,a1,1422 # 8000906c <sleeping>
    80002ae6:	5c88                	lw	a0,56(s1)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	064080e7          	jalr	100(ra) # 80001b4c <insert_to_list>
    80002af0:	85aa                	mv	a1,a0
  printf("exit from the insertion of %d to the sleeping list.\n",ret);
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	e9650513          	addi	a0,a0,-362 # 80008988 <digits+0x948>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a8e080e7          	jalr	-1394(ra) # 80000588 <printf>
  acquire(&p->lock);  //DOC: sleeplock1
    80002b02:	8526                	mv	a0,s1
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	0e0080e7          	jalr	224(ra) # 80000be4 <acquire>
  release(lk);
    80002b0c:	854a                	mv	a0,s2
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	19c080e7          	jalr	412(ra) # 80000caa <release>

  // Go to sleep.
  p->chan = chan;
    80002b16:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002b1a:	4789                	li	a5,2
    80002b1c:	cc9c                	sw	a5,24(s1)
  //printf("the number of locks is:%d\n",mycpu()->noff);
  sched();
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	dd2080e7          	jalr	-558(ra) # 800028f0 <sched>

  // Tidy up.
  p->chan = 0;
    80002b26:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002b2a:	8526                	mv	a0,s1
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	17e080e7          	jalr	382(ra) # 80000caa <release>
  acquire(lk);
    80002b34:	854a                	mv	a0,s2
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	0ae080e7          	jalr	174(ra) # 80000be4 <acquire>
    printf("exit sleep\n");
    80002b3e:	00006517          	auipc	a0,0x6
    80002b42:	e8250513          	addi	a0,a0,-382 # 800089c0 <digits+0x980>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	a42080e7          	jalr	-1470(ra) # 80000588 <printf>

}
    80002b4e:	60a6                	ld	ra,72(sp)
    80002b50:	6406                	ld	s0,64(sp)
    80002b52:	74e2                	ld	s1,56(sp)
    80002b54:	7942                	ld	s2,48(sp)
    80002b56:	79a2                	ld	s3,40(sp)
    80002b58:	6161                	addi	sp,sp,80
    80002b5a:	8082                	ret

0000000080002b5c <wait>:
{
    80002b5c:	715d                	addi	sp,sp,-80
    80002b5e:	e486                	sd	ra,72(sp)
    80002b60:	e0a2                	sd	s0,64(sp)
    80002b62:	fc26                	sd	s1,56(sp)
    80002b64:	f84a                	sd	s2,48(sp)
    80002b66:	f44e                	sd	s3,40(sp)
    80002b68:	f052                	sd	s4,32(sp)
    80002b6a:	ec56                	sd	s5,24(sp)
    80002b6c:	e85a                	sd	s6,16(sp)
    80002b6e:	e45e                	sd	s7,8(sp)
    80002b70:	e062                	sd	s8,0(sp)
    80002b72:	0880                	addi	s0,sp,80
    80002b74:	8b2a                	mv	s6,a0
  printf("entered wait\n");
    80002b76:	00006517          	auipc	a0,0x6
    80002b7a:	e5a50513          	addi	a0,a0,-422 # 800089d0 <digits+0x990>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	a0a080e7          	jalr	-1526(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	33e080e7          	jalr	830(ra) # 80001ec4 <myproc>
    80002b8e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002b90:	00008517          	auipc	a0,0x8
    80002b94:	61850513          	addi	a0,a0,1560 # 8000b1a8 <wait_lock>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	04c080e7          	jalr	76(ra) # 80000be4 <acquire>
    havekids = 0;
    80002ba0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002ba2:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002ba4:	0000f997          	auipc	s3,0xf
    80002ba8:	8fc98993          	addi	s3,s3,-1796 # 800114a0 <tickslock>
        havekids = 1;
    80002bac:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002bae:	00008c17          	auipc	s8,0x8
    80002bb2:	5fac0c13          	addi	s8,s8,1530 # 8000b1a8 <wait_lock>
    havekids = 0;
    80002bb6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002bb8:	00008497          	auipc	s1,0x8
    80002bbc:	6e848493          	addi	s1,s1,1768 # 8000b2a0 <proc>
    80002bc0:	a079                	j	80002c4e <wait+0xf2>
          pid = np->pid;
    80002bc2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002bc6:	000b0e63          	beqz	s6,80002be2 <wait+0x86>
    80002bca:	4691                	li	a3,4
    80002bcc:	02c48613          	addi	a2,s1,44
    80002bd0:	85da                	mv	a1,s6
    80002bd2:	07093503          	ld	a0,112(s2)
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	ac0080e7          	jalr	-1344(ra) # 80001696 <copyout>
    80002bde:	02054d63          	bltz	a0,80002c18 <wait+0xbc>
          freeproc(np);
    80002be2:	8526                	mv	a0,s1
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	484080e7          	jalr	1156(ra) # 80002068 <freeproc>
          release(&np->lock);
    80002bec:	8526                	mv	a0,s1
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	0bc080e7          	jalr	188(ra) # 80000caa <release>
          release(&wait_lock);
    80002bf6:	00008517          	auipc	a0,0x8
    80002bfa:	5b250513          	addi	a0,a0,1458 # 8000b1a8 <wait_lock>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	0ac080e7          	jalr	172(ra) # 80000caa <release>
          printf("exited wait2\n");
    80002c06:	00006517          	auipc	a0,0x6
    80002c0a:	dea50513          	addi	a0,a0,-534 # 800089f0 <digits+0x9b0>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	97a080e7          	jalr	-1670(ra) # 80000588 <printf>
          return pid;
    80002c16:	a059                	j	80002c9c <wait+0x140>
            release(&np->lock);
    80002c18:	8526                	mv	a0,s1
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	090080e7          	jalr	144(ra) # 80000caa <release>
            release(&wait_lock);
    80002c22:	00008517          	auipc	a0,0x8
    80002c26:	58650513          	addi	a0,a0,1414 # 8000b1a8 <wait_lock>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	080080e7          	jalr	128(ra) # 80000caa <release>
            printf("exited wait1\n");
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	dae50513          	addi	a0,a0,-594 # 800089e0 <digits+0x9a0>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	94e080e7          	jalr	-1714(ra) # 80000588 <printf>
            return -1;
    80002c42:	59fd                	li	s3,-1
    80002c44:	a8a1                	j	80002c9c <wait+0x140>
    for(np = proc; np < &proc[NPROC]; np++){
    80002c46:	18848493          	addi	s1,s1,392
    80002c4a:	03348463          	beq	s1,s3,80002c72 <wait+0x116>
      if(np->parent == p){
    80002c4e:	6cbc                	ld	a5,88(s1)
    80002c50:	ff279be3          	bne	a5,s2,80002c46 <wait+0xea>
        acquire(&np->lock);
    80002c54:	8526                	mv	a0,s1
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	f8e080e7          	jalr	-114(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002c5e:	4c9c                	lw	a5,24(s1)
    80002c60:	f74781e3          	beq	a5,s4,80002bc2 <wait+0x66>
        release(&np->lock);
    80002c64:	8526                	mv	a0,s1
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	044080e7          	jalr	68(ra) # 80000caa <release>
        havekids = 1;
    80002c6e:	8756                	mv	a4,s5
    80002c70:	bfd9                	j	80002c46 <wait+0xea>
    if(!havekids || p->killed){
    80002c72:	c701                	beqz	a4,80002c7a <wait+0x11e>
    80002c74:	02892783          	lw	a5,40(s2)
    80002c78:	cf9d                	beqz	a5,80002cb6 <wait+0x15a>
      release(&wait_lock);
    80002c7a:	00008517          	auipc	a0,0x8
    80002c7e:	52e50513          	addi	a0,a0,1326 # 8000b1a8 <wait_lock>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	028080e7          	jalr	40(ra) # 80000caa <release>
      printf("exited wait3\n");
    80002c8a:	00006517          	auipc	a0,0x6
    80002c8e:	d7650513          	addi	a0,a0,-650 # 80008a00 <digits+0x9c0>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8f6080e7          	jalr	-1802(ra) # 80000588 <printf>
      return -1;
    80002c9a:	59fd                	li	s3,-1
}
    80002c9c:	854e                	mv	a0,s3
    80002c9e:	60a6                	ld	ra,72(sp)
    80002ca0:	6406                	ld	s0,64(sp)
    80002ca2:	74e2                	ld	s1,56(sp)
    80002ca4:	7942                	ld	s2,48(sp)
    80002ca6:	79a2                	ld	s3,40(sp)
    80002ca8:	7a02                	ld	s4,32(sp)
    80002caa:	6ae2                	ld	s5,24(sp)
    80002cac:	6b42                	ld	s6,16(sp)
    80002cae:	6ba2                	ld	s7,8(sp)
    80002cb0:	6c02                	ld	s8,0(sp)
    80002cb2:	6161                	addi	sp,sp,80
    80002cb4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002cb6:	85e2                	mv	a1,s8
    80002cb8:	854a                	mv	a0,s2
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	dd6080e7          	jalr	-554(ra) # 80002a90 <sleep>
    havekids = 0;
    80002cc2:	bdd5                	j	80002bb6 <wait+0x5a>

0000000080002cc4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002cc4:	7159                	addi	sp,sp,-112
    80002cc6:	f486                	sd	ra,104(sp)
    80002cc8:	f0a2                	sd	s0,96(sp)
    80002cca:	eca6                	sd	s1,88(sp)
    80002ccc:	e8ca                	sd	s2,80(sp)
    80002cce:	e4ce                	sd	s3,72(sp)
    80002cd0:	e0d2                	sd	s4,64(sp)
    80002cd2:	fc56                	sd	s5,56(sp)
    80002cd4:	f85a                	sd	s6,48(sp)
    80002cd6:	f45e                	sd	s7,40(sp)
    80002cd8:	f062                	sd	s8,32(sp)
    80002cda:	1880                	addi	s0,sp,112
  struct proc *p;
  if (sleeping == -1){
    80002cdc:	00006917          	auipc	s2,0x6
    80002ce0:	39092903          	lw	s2,912(s2) # 8000906c <sleeping>
    80002ce4:	57fd                	li	a5,-1
    80002ce6:	06f90063          	beq	s2,a5,80002d46 <wakeup+0x82>
    80002cea:	89aa                	mv	s3,a0
      //printf("process p->pid = %d\n", p->pid);
    //printf("no one is sleeping so exit\n");
    return;
  } // if no one is sleeping - do nothing
  //acquire(&sleeping_head);
  p = &proc[sleeping];
    80002cec:	18800493          	li	s1,392
    80002cf0:	029904b3          	mul	s1,s2,s1
    80002cf4:	00008797          	auipc	a5,0x8
    80002cf8:	5ac78793          	addi	a5,a5,1452 # 8000b2a0 <proc>
    80002cfc:	94be                	add	s1,s1,a5
  if (p->next == -1){ // there is only one sleeper
    80002cfe:	5cdc                	lw	a5,60(s1)
    80002d00:	2781                	sext.w	a5,a5
    80002d02:	577d                	li	a4,-1
    80002d04:	06e78563          	beq	a5,a4,80002d6e <wakeup+0xaa>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
      }
      release(&p->lock);
    }  
  }
  while(p->next != -1 ) { // loop through all sleepers
    80002d08:	18800793          	li	a5,392
    80002d0c:	02f90933          	mul	s2,s2,a5
    80002d10:	00008797          	auipc	a5,0x8
    80002d14:	59078793          	addi	a5,a5,1424 # 8000b2a0 <proc>
    80002d18:	993e                	add	s2,s2,a5
    80002d1a:	03c92783          	lw	a5,60(s2)
    80002d1e:	2781                	sext.w	a5,a5
    80002d20:	577d                	li	a4,-1
    80002d22:	02e78a63          	beq	a5,a4,80002d56 <wakeup+0x92>
    if(p != myproc()){
      //printf("process p->pid = %d\n", p->pid);
      acquire(&p->lock);
      if(p->chan == chan && p->state==SLEEPING) {
    80002d26:	4a09                	li	s4,2
        remove_from_list(p->index,&sleeping,sleeping_head);
    80002d28:	00008a97          	auipc	s5,0x8
    80002d2c:	468a8a93          	addi	s5,s5,1128 # 8000b190 <pid_lock>
    80002d30:	00006c17          	auipc	s8,0x6
    80002d34:	33cc0c13          	addi	s8,s8,828 # 8000906c <sleeping>
        p->state = RUNNABLE;
    80002d38:	4b8d                	li	s7,3
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002d3a:	00007b17          	auipc	s6,0x7
    80002d3e:	2eeb0b13          	addi	s6,s6,750 # 8000a028 <cpus_ll>
  while(p->next != -1 ) { // loop through all sleepers
    80002d42:	597d                	li	s2,-1
    80002d44:	a0ed                	j	80002e2e <wakeup+0x16a>
    printf("no one is sleeping\n");
    80002d46:	00006517          	auipc	a0,0x6
    80002d4a:	cca50513          	addi	a0,a0,-822 # 80008a10 <digits+0x9d0>
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	83a080e7          	jalr	-1990(ra) # 80000588 <printf>
      }
      release(&p->lock);
    }
    p++;
  }
}
    80002d56:	70a6                	ld	ra,104(sp)
    80002d58:	7406                	ld	s0,96(sp)
    80002d5a:	64e6                	ld	s1,88(sp)
    80002d5c:	6946                	ld	s2,80(sp)
    80002d5e:	69a6                	ld	s3,72(sp)
    80002d60:	6a06                	ld	s4,64(sp)
    80002d62:	7ae2                	ld	s5,56(sp)
    80002d64:	7b42                	ld	s6,48(sp)
    80002d66:	7ba2                	ld	s7,40(sp)
    80002d68:	7c02                	ld	s8,32(sp)
    80002d6a:	6165                	addi	sp,sp,112
    80002d6c:	8082                	ret
    if(p != myproc()){ 
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	156080e7          	jalr	342(ra) # 80001ec4 <myproc>
    80002d76:	f8a489e3          	beq	s1,a0,80002d08 <wakeup+0x44>
      acquire(&p->lock);
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	e68080e7          	jalr	-408(ra) # 80000be4 <acquire>
      if(p->chan == chan&& p->state==SLEEPING) {
    80002d84:	709c                	ld	a5,32(s1)
    80002d86:	01378863          	beq	a5,s3,80002d96 <wakeup+0xd2>
      release(&p->lock);
    80002d8a:	8526                	mv	a0,s1
    80002d8c:	ffffe097          	auipc	ra,0xffffe
    80002d90:	f1e080e7          	jalr	-226(ra) # 80000caa <release>
    80002d94:	bf95                	j	80002d08 <wakeup+0x44>
      if(p->chan == chan&& p->state==SLEEPING) {
    80002d96:	4c98                	lw	a4,24(s1)
    80002d98:	4789                	li	a5,2
    80002d9a:	fef718e3          	bne	a4,a5,80002d8a <wakeup+0xc6>
        remove_from_list(p->index,&sleeping,sleeping_head);
    80002d9e:	00008a17          	auipc	s4,0x8
    80002da2:	3f2a0a13          	addi	s4,s4,1010 # 8000b190 <pid_lock>
    80002da6:	030a3783          	ld	a5,48(s4)
    80002daa:	f8f43823          	sd	a5,-112(s0)
    80002dae:	038a3783          	ld	a5,56(s4)
    80002db2:	f8f43c23          	sd	a5,-104(s0)
    80002db6:	040a3783          	ld	a5,64(s4)
    80002dba:	faf43023          	sd	a5,-96(s0)
    80002dbe:	f9040613          	addi	a2,s0,-112
    80002dc2:	00006597          	auipc	a1,0x6
    80002dc6:	2aa58593          	addi	a1,a1,682 # 8000906c <sleeping>
    80002dca:	5c88                	lw	a0,56(s1)
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	b66080e7          	jalr	-1178(ra) # 80001932 <remove_from_list>
        p->state = RUNNABLE;
    80002dd4:	478d                	li	a5,3
    80002dd6:	cc9c                	sw	a5,24(s1)
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002dd8:	58dc                	lw	a5,52(s1)
    80002dda:	00179713          	slli	a4,a5,0x1
    80002dde:	973e                	add	a4,a4,a5
    80002de0:	070e                	slli	a4,a4,0x3
    80002de2:	9a3a                	add	s4,s4,a4
    80002de4:	0f8a3703          	ld	a4,248(s4)
    80002de8:	f8e43823          	sd	a4,-112(s0)
    80002dec:	100a3703          	ld	a4,256(s4)
    80002df0:	f8e43c23          	sd	a4,-104(s0)
    80002df4:	108a3703          	ld	a4,264(s4)
    80002df8:	fae43023          	sd	a4,-96(s0)
    80002dfc:	078a                	slli	a5,a5,0x2
    80002dfe:	f9040613          	addi	a2,s0,-112
    80002e02:	00007597          	auipc	a1,0x7
    80002e06:	22658593          	addi	a1,a1,550 # 8000a028 <cpus_ll>
    80002e0a:	95be                	add	a1,a1,a5
    80002e0c:	5c88                	lw	a0,56(s1)
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	d3e080e7          	jalr	-706(ra) # 80001b4c <insert_to_list>
    80002e16:	bf95                	j	80002d8a <wakeup+0xc6>
      release(&p->lock);
    80002e18:	8526                	mv	a0,s1
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	e90080e7          	jalr	-368(ra) # 80000caa <release>
    p++;
    80002e22:	18848493          	addi	s1,s1,392
  while(p->next != -1 ) { // loop through all sleepers
    80002e26:	5cdc                	lw	a5,60(s1)
    80002e28:	2781                	sext.w	a5,a5
    80002e2a:	f32786e3          	beq	a5,s2,80002d56 <wakeup+0x92>
    if(p != myproc()){
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	096080e7          	jalr	150(ra) # 80001ec4 <myproc>
    80002e36:	fea486e3          	beq	s1,a0,80002e22 <wakeup+0x15e>
      acquire(&p->lock);
    80002e3a:	8526                	mv	a0,s1
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	da8080e7          	jalr	-600(ra) # 80000be4 <acquire>
      if(p->chan == chan && p->state==SLEEPING) {
    80002e44:	709c                	ld	a5,32(s1)
    80002e46:	fd3799e3          	bne	a5,s3,80002e18 <wakeup+0x154>
    80002e4a:	4c9c                	lw	a5,24(s1)
    80002e4c:	fd4796e3          	bne	a5,s4,80002e18 <wakeup+0x154>
        remove_from_list(p->index,&sleeping,sleeping_head);
    80002e50:	030ab783          	ld	a5,48(s5)
    80002e54:	f8f43823          	sd	a5,-112(s0)
    80002e58:	038ab783          	ld	a5,56(s5)
    80002e5c:	f8f43c23          	sd	a5,-104(s0)
    80002e60:	040ab783          	ld	a5,64(s5)
    80002e64:	faf43023          	sd	a5,-96(s0)
    80002e68:	f9040613          	addi	a2,s0,-112
    80002e6c:	85e2                	mv	a1,s8
    80002e6e:	5c88                	lw	a0,56(s1)
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	ac2080e7          	jalr	-1342(ra) # 80001932 <remove_from_list>
        p->state = RUNNABLE;
    80002e78:	0174ac23          	sw	s7,24(s1)
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002e7c:	58cc                	lw	a1,52(s1)
    80002e7e:	00159793          	slli	a5,a1,0x1
    80002e82:	97ae                	add	a5,a5,a1
    80002e84:	078e                	slli	a5,a5,0x3
    80002e86:	97d6                	add	a5,a5,s5
    80002e88:	7ff8                	ld	a4,248(a5)
    80002e8a:	f8e43823          	sd	a4,-112(s0)
    80002e8e:	1007b703          	ld	a4,256(a5)
    80002e92:	f8e43c23          	sd	a4,-104(s0)
    80002e96:	1087b783          	ld	a5,264(a5)
    80002e9a:	faf43023          	sd	a5,-96(s0)
    80002e9e:	058a                	slli	a1,a1,0x2
    80002ea0:	f9040613          	addi	a2,s0,-112
    80002ea4:	95da                	add	a1,a1,s6
    80002ea6:	5c88                	lw	a0,56(s1)
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	ca4080e7          	jalr	-860(ra) # 80001b4c <insert_to_list>
    80002eb0:	b7a5                	j	80002e18 <wakeup+0x154>

0000000080002eb2 <reparent>:
{
    80002eb2:	7179                	addi	sp,sp,-48
    80002eb4:	f406                	sd	ra,40(sp)
    80002eb6:	f022                	sd	s0,32(sp)
    80002eb8:	ec26                	sd	s1,24(sp)
    80002eba:	e84a                	sd	s2,16(sp)
    80002ebc:	e44e                	sd	s3,8(sp)
    80002ebe:	e052                	sd	s4,0(sp)
    80002ec0:	1800                	addi	s0,sp,48
    80002ec2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ec4:	00008497          	auipc	s1,0x8
    80002ec8:	3dc48493          	addi	s1,s1,988 # 8000b2a0 <proc>
      pp->parent = initproc;
    80002ecc:	00007a17          	auipc	s4,0x7
    80002ed0:	164a0a13          	addi	s4,s4,356 # 8000a030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ed4:	0000e997          	auipc	s3,0xe
    80002ed8:	5cc98993          	addi	s3,s3,1484 # 800114a0 <tickslock>
    80002edc:	a029                	j	80002ee6 <reparent+0x34>
    80002ede:	18848493          	addi	s1,s1,392
    80002ee2:	01348d63          	beq	s1,s3,80002efc <reparent+0x4a>
    if(pp->parent == p){
    80002ee6:	6cbc                	ld	a5,88(s1)
    80002ee8:	ff279be3          	bne	a5,s2,80002ede <reparent+0x2c>
      pp->parent = initproc;
    80002eec:	000a3503          	ld	a0,0(s4)
    80002ef0:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	dd2080e7          	jalr	-558(ra) # 80002cc4 <wakeup>
    80002efa:	b7d5                	j	80002ede <reparent+0x2c>
}
    80002efc:	70a2                	ld	ra,40(sp)
    80002efe:	7402                	ld	s0,32(sp)
    80002f00:	64e2                	ld	s1,24(sp)
    80002f02:	6942                	ld	s2,16(sp)
    80002f04:	69a2                	ld	s3,8(sp)
    80002f06:	6a02                	ld	s4,0(sp)
    80002f08:	6145                	addi	sp,sp,48
    80002f0a:	8082                	ret

0000000080002f0c <exit>:
{
    80002f0c:	715d                	addi	sp,sp,-80
    80002f0e:	e486                	sd	ra,72(sp)
    80002f10:	e0a2                	sd	s0,64(sp)
    80002f12:	fc26                	sd	s1,56(sp)
    80002f14:	f84a                	sd	s2,48(sp)
    80002f16:	f44e                	sd	s3,40(sp)
    80002f18:	f052                	sd	s4,32(sp)
    80002f1a:	0880                	addi	s0,sp,80
    80002f1c:	8a2a                	mv	s4,a0
  printf("entered exit\n");
    80002f1e:	00006517          	auipc	a0,0x6
    80002f22:	b0a50513          	addi	a0,a0,-1270 # 80008a28 <digits+0x9e8>
    80002f26:	ffffd097          	auipc	ra,0xffffd
    80002f2a:	662080e7          	jalr	1634(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	f96080e7          	jalr	-106(ra) # 80001ec4 <myproc>
    80002f36:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f38:	00007797          	auipc	a5,0x7
    80002f3c:	0f87b783          	ld	a5,248(a5) # 8000a030 <initproc>
    80002f40:	0f050493          	addi	s1,a0,240
    80002f44:	17050913          	addi	s2,a0,368
    80002f48:	02a79363          	bne	a5,a0,80002f6e <exit+0x62>
    panic("init exiting");
    80002f4c:	00006517          	auipc	a0,0x6
    80002f50:	aec50513          	addi	a0,a0,-1300 # 80008a38 <digits+0x9f8>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>
      fileclose(f);
    80002f5c:	00002097          	auipc	ra,0x2
    80002f60:	22a080e7          	jalr	554(ra) # 80005186 <fileclose>
      p->ofile[fd] = 0;
    80002f64:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f68:	04a1                	addi	s1,s1,8
    80002f6a:	01248563          	beq	s1,s2,80002f74 <exit+0x68>
    if(p->ofile[fd]){
    80002f6e:	6088                	ld	a0,0(s1)
    80002f70:	f575                	bnez	a0,80002f5c <exit+0x50>
    80002f72:	bfdd                	j	80002f68 <exit+0x5c>
  begin_op();
    80002f74:	00002097          	auipc	ra,0x2
    80002f78:	d46080e7          	jalr	-698(ra) # 80004cba <begin_op>
  iput(p->cwd);
    80002f7c:	1709b503          	ld	a0,368(s3)
    80002f80:	00001097          	auipc	ra,0x1
    80002f84:	522080e7          	jalr	1314(ra) # 800044a2 <iput>
  end_op();
    80002f88:	00002097          	auipc	ra,0x2
    80002f8c:	db2080e7          	jalr	-590(ra) # 80004d3a <end_op>
  p->cwd = 0;
    80002f90:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002f94:	00008497          	auipc	s1,0x8
    80002f98:	1fc48493          	addi	s1,s1,508 # 8000b190 <pid_lock>
    80002f9c:	00008917          	auipc	s2,0x8
    80002fa0:	20c90913          	addi	s2,s2,524 # 8000b1a8 <wait_lock>
    80002fa4:	854a                	mv	a0,s2
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
  reparent(p);
    80002fae:	854e                	mv	a0,s3
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	f02080e7          	jalr	-254(ra) # 80002eb2 <reparent>
  wakeup(p->parent);
    80002fb8:	0589b503          	ld	a0,88(s3)
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	d08080e7          	jalr	-760(ra) # 80002cc4 <wakeup>
  acquire(&p->lock);
    80002fc4:	854e                	mv	a0,s3
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002fce:	0349a623          	sw	s4,44(s3)
  printf("before insertind %d to the zombie list. its state is:%d",p->index);
    80002fd2:	0389a583          	lw	a1,56(s3)
    80002fd6:	00006517          	auipc	a0,0x6
    80002fda:	a7250513          	addi	a0,a0,-1422 # 80008a48 <digits+0xa08>
    80002fde:	ffffd097          	auipc	ra,0xffffd
    80002fe2:	5aa080e7          	jalr	1450(ra) # 80000588 <printf>
  p->state = ZOMBIE;
    80002fe6:	4795                	li	a5,5
    80002fe8:	00f9ac23          	sw	a5,24(s3)
  int ret=insert_to_list(p->index,&zombie,zombie_head);
    80002fec:	64bc                	ld	a5,72(s1)
    80002fee:	faf43823          	sd	a5,-80(s0)
    80002ff2:	68bc                	ld	a5,80(s1)
    80002ff4:	faf43c23          	sd	a5,-72(s0)
    80002ff8:	6cbc                	ld	a5,88(s1)
    80002ffa:	fcf43023          	sd	a5,-64(s0)
    80002ffe:	fb040613          	addi	a2,s0,-80
    80003002:	00006597          	auipc	a1,0x6
    80003006:	06658593          	addi	a1,a1,102 # 80009068 <zombie>
    8000300a:	0389a503          	lw	a0,56(s3)
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	b3e080e7          	jalr	-1218(ra) # 80001b4c <insert_to_list>
    80003016:	85aa                	mv	a1,a0
  printf("doen with inserting the prosses index %d to the zombie list.\n",ret);
    80003018:	00006517          	auipc	a0,0x6
    8000301c:	a6850513          	addi	a0,a0,-1432 # 80008a80 <digits+0xa40>
    80003020:	ffffd097          	auipc	ra,0xffffd
    80003024:	568080e7          	jalr	1384(ra) # 80000588 <printf>
  release(&wait_lock);
    80003028:	854a                	mv	a0,s2
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	c80080e7          	jalr	-896(ra) # 80000caa <release>
  sched();
    80003032:	00000097          	auipc	ra,0x0
    80003036:	8be080e7          	jalr	-1858(ra) # 800028f0 <sched>
  panic("zombie exit");
    8000303a:	00006517          	auipc	a0,0x6
    8000303e:	a8650513          	addi	a0,a0,-1402 # 80008ac0 <digits+0xa80>
    80003042:	ffffd097          	auipc	ra,0xffffd
    80003046:	4fc080e7          	jalr	1276(ra) # 8000053e <panic>

000000008000304a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000304a:	7179                	addi	sp,sp,-48
    8000304c:	f406                	sd	ra,40(sp)
    8000304e:	f022                	sd	s0,32(sp)
    80003050:	ec26                	sd	s1,24(sp)
    80003052:	e84a                	sd	s2,16(sp)
    80003054:	e44e                	sd	s3,8(sp)
    80003056:	1800                	addi	s0,sp,48
    80003058:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000305a:	00008497          	auipc	s1,0x8
    8000305e:	24648493          	addi	s1,s1,582 # 8000b2a0 <proc>
    80003062:	0000e997          	auipc	s3,0xe
    80003066:	43e98993          	addi	s3,s3,1086 # 800114a0 <tickslock>
    acquire(&p->lock);
    8000306a:	8526                	mv	a0,s1
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	b78080e7          	jalr	-1160(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80003074:	589c                	lw	a5,48(s1)
    80003076:	01278d63          	beq	a5,s2,80003090 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000307a:	8526                	mv	a0,s1
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	c2e080e7          	jalr	-978(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003084:	18848493          	addi	s1,s1,392
    80003088:	ff3491e3          	bne	s1,s3,8000306a <kill+0x20>
  }
  return -1;
    8000308c:	557d                	li	a0,-1
    8000308e:	a829                	j	800030a8 <kill+0x5e>
      p->killed = 1;
    80003090:	4785                	li	a5,1
    80003092:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80003094:	4c98                	lw	a4,24(s1)
    80003096:	4789                	li	a5,2
    80003098:	00f70f63          	beq	a4,a5,800030b6 <kill+0x6c>
      release(&p->lock);
    8000309c:	8526                	mv	a0,s1
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	c0c080e7          	jalr	-1012(ra) # 80000caa <release>
      return 0;
    800030a6:	4501                	li	a0,0
}
    800030a8:	70a2                	ld	ra,40(sp)
    800030aa:	7402                	ld	s0,32(sp)
    800030ac:	64e2                	ld	s1,24(sp)
    800030ae:	6942                	ld	s2,16(sp)
    800030b0:	69a2                	ld	s3,8(sp)
    800030b2:	6145                	addi	sp,sp,48
    800030b4:	8082                	ret
        p->state = RUNNABLE;
    800030b6:	478d                	li	a5,3
    800030b8:	cc9c                	sw	a5,24(s1)
    800030ba:	b7cd                	j	8000309c <kill+0x52>

00000000800030bc <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800030bc:	7179                	addi	sp,sp,-48
    800030be:	f406                	sd	ra,40(sp)
    800030c0:	f022                	sd	s0,32(sp)
    800030c2:	ec26                	sd	s1,24(sp)
    800030c4:	e84a                	sd	s2,16(sp)
    800030c6:	e44e                	sd	s3,8(sp)
    800030c8:	e052                	sd	s4,0(sp)
    800030ca:	1800                	addi	s0,sp,48
    800030cc:	84aa                	mv	s1,a0
    800030ce:	892e                	mv	s2,a1
    800030d0:	89b2                	mv	s3,a2
    800030d2:	8a36                	mv	s4,a3
  //printf("entered either_copyout\n");
  struct proc *p = myproc();
    800030d4:	fffff097          	auipc	ra,0xfffff
    800030d8:	df0080e7          	jalr	-528(ra) # 80001ec4 <myproc>
  if(user_dst){
    800030dc:	c08d                	beqz	s1,800030fe <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800030de:	86d2                	mv	a3,s4
    800030e0:	864e                	mv	a2,s3
    800030e2:	85ca                	mv	a1,s2
    800030e4:	7928                	ld	a0,112(a0)
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	5b0080e7          	jalr	1456(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800030ee:	70a2                	ld	ra,40(sp)
    800030f0:	7402                	ld	s0,32(sp)
    800030f2:	64e2                	ld	s1,24(sp)
    800030f4:	6942                	ld	s2,16(sp)
    800030f6:	69a2                	ld	s3,8(sp)
    800030f8:	6a02                	ld	s4,0(sp)
    800030fa:	6145                	addi	sp,sp,48
    800030fc:	8082                	ret
    memmove((char *)dst, src, len);
    800030fe:	000a061b          	sext.w	a2,s4
    80003102:	85ce                	mv	a1,s3
    80003104:	854a                	mv	a0,s2
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	c5e080e7          	jalr	-930(ra) # 80000d64 <memmove>
    return 0;
    8000310e:	8526                	mv	a0,s1
    80003110:	bff9                	j	800030ee <either_copyout+0x32>

0000000080003112 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003112:	7179                	addi	sp,sp,-48
    80003114:	f406                	sd	ra,40(sp)
    80003116:	f022                	sd	s0,32(sp)
    80003118:	ec26                	sd	s1,24(sp)
    8000311a:	e84a                	sd	s2,16(sp)
    8000311c:	e44e                	sd	s3,8(sp)
    8000311e:	e052                	sd	s4,0(sp)
    80003120:	1800                	addi	s0,sp,48
    80003122:	892a                	mv	s2,a0
    80003124:	84ae                	mv	s1,a1
    80003126:	89b2                	mv	s3,a2
    80003128:	8a36                	mv	s4,a3
  //printf("entered either_copyin\n");
  struct proc *p = myproc();
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	d9a080e7          	jalr	-614(ra) # 80001ec4 <myproc>
  if(user_src){
    80003132:	c08d                	beqz	s1,80003154 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80003134:	86d2                	mv	a3,s4
    80003136:	864e                	mv	a2,s3
    80003138:	85ca                	mv	a1,s2
    8000313a:	7928                	ld	a0,112(a0)
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	5e6080e7          	jalr	1510(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80003144:	70a2                	ld	ra,40(sp)
    80003146:	7402                	ld	s0,32(sp)
    80003148:	64e2                	ld	s1,24(sp)
    8000314a:	6942                	ld	s2,16(sp)
    8000314c:	69a2                	ld	s3,8(sp)
    8000314e:	6a02                	ld	s4,0(sp)
    80003150:	6145                	addi	sp,sp,48
    80003152:	8082                	ret
    memmove(dst, (char*)src, len);
    80003154:	000a061b          	sext.w	a2,s4
    80003158:	85ce                	mv	a1,s3
    8000315a:	854a                	mv	a0,s2
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	c08080e7          	jalr	-1016(ra) # 80000d64 <memmove>
    return 0;
    80003164:	8526                	mv	a0,s1
    80003166:	bff9                	j	80003144 <either_copyin+0x32>

0000000080003168 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003168:	715d                	addi	sp,sp,-80
    8000316a:	e486                	sd	ra,72(sp)
    8000316c:	e0a2                	sd	s0,64(sp)
    8000316e:	fc26                	sd	s1,56(sp)
    80003170:	f84a                	sd	s2,48(sp)
    80003172:	f44e                	sd	s3,40(sp)
    80003174:	f052                	sd	s4,32(sp)
    80003176:	ec56                	sd	s5,24(sp)
    80003178:	e85a                	sd	s6,16(sp)
    8000317a:	e45e                	sd	s7,8(sp)
    8000317c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000317e:	00005517          	auipc	a0,0x5
    80003182:	28a50513          	addi	a0,a0,650 # 80008408 <digits+0x3c8>
    80003186:	ffffd097          	auipc	ra,0xffffd
    8000318a:	402080e7          	jalr	1026(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000318e:	00008497          	auipc	s1,0x8
    80003192:	28a48493          	addi	s1,s1,650 # 8000b418 <proc+0x178>
    80003196:	0000e917          	auipc	s2,0xe
    8000319a:	48290913          	addi	s2,s2,1154 # 80011618 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000319e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800031a0:	00006997          	auipc	s3,0x6
    800031a4:	93098993          	addi	s3,s3,-1744 # 80008ad0 <digits+0xa90>
    printf("%d %s %s", p->pid, state, p->name);
    800031a8:	00006a97          	auipc	s5,0x6
    800031ac:	930a8a93          	addi	s5,s5,-1744 # 80008ad8 <digits+0xa98>
    printf("\n");
    800031b0:	00005a17          	auipc	s4,0x5
    800031b4:	258a0a13          	addi	s4,s4,600 # 80008408 <digits+0x3c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031b8:	00006b97          	auipc	s7,0x6
    800031bc:	958b8b93          	addi	s7,s7,-1704 # 80008b10 <states.1763>
    800031c0:	a00d                	j	800031e2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800031c2:	eb86a583          	lw	a1,-328(a3)
    800031c6:	8556                	mv	a0,s5
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	3c0080e7          	jalr	960(ra) # 80000588 <printf>
    printf("\n");
    800031d0:	8552                	mv	a0,s4
    800031d2:	ffffd097          	auipc	ra,0xffffd
    800031d6:	3b6080e7          	jalr	950(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800031da:	18848493          	addi	s1,s1,392
    800031de:	03248163          	beq	s1,s2,80003200 <procdump+0x98>
    if(p->state == UNUSED)
    800031e2:	86a6                	mv	a3,s1
    800031e4:	ea04a783          	lw	a5,-352(s1)
    800031e8:	dbed                	beqz	a5,800031da <procdump+0x72>
      state = "???";
    800031ea:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031ec:	fcfb6be3          	bltu	s6,a5,800031c2 <procdump+0x5a>
    800031f0:	1782                	slli	a5,a5,0x20
    800031f2:	9381                	srli	a5,a5,0x20
    800031f4:	078e                	slli	a5,a5,0x3
    800031f6:	97de                	add	a5,a5,s7
    800031f8:	6390                	ld	a2,0(a5)
    800031fa:	f661                	bnez	a2,800031c2 <procdump+0x5a>
      state = "???";
    800031fc:	864e                	mv	a2,s3
    800031fe:	b7d1                	j	800031c2 <procdump+0x5a>
  }
}
    80003200:	60a6                	ld	ra,72(sp)
    80003202:	6406                	ld	s0,64(sp)
    80003204:	74e2                	ld	s1,56(sp)
    80003206:	7942                	ld	s2,48(sp)
    80003208:	79a2                	ld	s3,40(sp)
    8000320a:	7a02                	ld	s4,32(sp)
    8000320c:	6ae2                	ld	s5,24(sp)
    8000320e:	6b42                	ld	s6,16(sp)
    80003210:	6ba2                	ld	s7,8(sp)
    80003212:	6161                	addi	sp,sp,80
    80003214:	8082                	ret

0000000080003216 <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	1000                	addi	s0,sp,32
    80003220:	84aa                	mv	s1,a0
  struct proc *p= myproc();  
    80003222:	fffff097          	auipc	ra,0xfffff
    80003226:	ca2080e7          	jalr	-862(ra) # 80001ec4 <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    8000322a:	8626                	mv	a2,s1
    8000322c:	594c                	lw	a1,52(a0)
    8000322e:	03450513          	addi	a0,a0,52
    80003232:	00004097          	auipc	ra,0x4
    80003236:	c44080e7          	jalr	-956(ra) # 80006e76 <cas>
    8000323a:	e519                	bnez	a0,80003248 <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    8000323c:	4501                	li	a0,0
}
    8000323e:	60e2                	ld	ra,24(sp)
    80003240:	6442                	ld	s0,16(sp)
    80003242:	64a2                	ld	s1,8(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret
    yield();
    80003248:	fffff097          	auipc	ra,0xfffff
    8000324c:	78e080e7          	jalr	1934(ra) # 800029d6 <yield>
    return cpu_num;
    80003250:	8526                	mv	a0,s1
    80003252:	b7f5                	j	8000323e <set_cpu+0x28>

0000000080003254 <get_cpu>:

int get_cpu(){ //added as orderd
    80003254:	1101                	addi	sp,sp,-32
    80003256:	ec06                	sd	ra,24(sp)
    80003258:	e822                	sd	s0,16(sp)
    8000325a:	1000                	addi	s0,sp,32
  struct proc *p=myproc();
    8000325c:	fffff097          	auipc	ra,0xfffff
    80003260:	c68080e7          	jalr	-920(ra) # 80001ec4 <myproc>
  int ans=0;
    80003264:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80003268:	5950                	lw	a2,52(a0)
    8000326a:	4581                	li	a1,0
    8000326c:	fec40513          	addi	a0,s0,-20
    80003270:	00004097          	auipc	ra,0x4
    80003274:	c06080e7          	jalr	-1018(ra) # 80006e76 <cas>
    return ans;
}
    80003278:	fec42503          	lw	a0,-20(s0)
    8000327c:	60e2                	ld	ra,24(sp)
    8000327e:	6442                	ld	s0,16(sp)
    80003280:	6105                	addi	sp,sp,32
    80003282:	8082                	ret

0000000080003284 <swtch>:
    80003284:	00153023          	sd	ra,0(a0)
    80003288:	00253423          	sd	sp,8(a0)
    8000328c:	e900                	sd	s0,16(a0)
    8000328e:	ed04                	sd	s1,24(a0)
    80003290:	03253023          	sd	s2,32(a0)
    80003294:	03353423          	sd	s3,40(a0)
    80003298:	03453823          	sd	s4,48(a0)
    8000329c:	03553c23          	sd	s5,56(a0)
    800032a0:	05653023          	sd	s6,64(a0)
    800032a4:	05753423          	sd	s7,72(a0)
    800032a8:	05853823          	sd	s8,80(a0)
    800032ac:	05953c23          	sd	s9,88(a0)
    800032b0:	07a53023          	sd	s10,96(a0)
    800032b4:	07b53423          	sd	s11,104(a0)
    800032b8:	0005b083          	ld	ra,0(a1)
    800032bc:	0085b103          	ld	sp,8(a1)
    800032c0:	6980                	ld	s0,16(a1)
    800032c2:	6d84                	ld	s1,24(a1)
    800032c4:	0205b903          	ld	s2,32(a1)
    800032c8:	0285b983          	ld	s3,40(a1)
    800032cc:	0305ba03          	ld	s4,48(a1)
    800032d0:	0385ba83          	ld	s5,56(a1)
    800032d4:	0405bb03          	ld	s6,64(a1)
    800032d8:	0485bb83          	ld	s7,72(a1)
    800032dc:	0505bc03          	ld	s8,80(a1)
    800032e0:	0585bc83          	ld	s9,88(a1)
    800032e4:	0605bd03          	ld	s10,96(a1)
    800032e8:	0685bd83          	ld	s11,104(a1)
    800032ec:	8082                	ret

00000000800032ee <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800032ee:	1141                	addi	sp,sp,-16
    800032f0:	e406                	sd	ra,8(sp)
    800032f2:	e022                	sd	s0,0(sp)
    800032f4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800032f6:	00006597          	auipc	a1,0x6
    800032fa:	84a58593          	addi	a1,a1,-1974 # 80008b40 <states.1763+0x30>
    800032fe:	0000e517          	auipc	a0,0xe
    80003302:	1a250513          	addi	a0,a0,418 # 800114a0 <tickslock>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	84e080e7          	jalr	-1970(ra) # 80000b54 <initlock>
}
    8000330e:	60a2                	ld	ra,8(sp)
    80003310:	6402                	ld	s0,0(sp)
    80003312:	0141                	addi	sp,sp,16
    80003314:	8082                	ret

0000000080003316 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003316:	1141                	addi	sp,sp,-16
    80003318:	e422                	sd	s0,8(sp)
    8000331a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000331c:	00003797          	auipc	a5,0x3
    80003320:	48478793          	addi	a5,a5,1156 # 800067a0 <kernelvec>
    80003324:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003328:	6422                	ld	s0,8(sp)
    8000332a:	0141                	addi	sp,sp,16
    8000332c:	8082                	ret

000000008000332e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000332e:	1141                	addi	sp,sp,-16
    80003330:	e406                	sd	ra,8(sp)
    80003332:	e022                	sd	s0,0(sp)
    80003334:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	b8e080e7          	jalr	-1138(ra) # 80001ec4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000333e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003342:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003344:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003348:	00004617          	auipc	a2,0x4
    8000334c:	cb860613          	addi	a2,a2,-840 # 80007000 <_trampoline>
    80003350:	00004697          	auipc	a3,0x4
    80003354:	cb068693          	addi	a3,a3,-848 # 80007000 <_trampoline>
    80003358:	8e91                	sub	a3,a3,a2
    8000335a:	040007b7          	lui	a5,0x4000
    8000335e:	17fd                	addi	a5,a5,-1
    80003360:	07b2                	slli	a5,a5,0xc
    80003362:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003364:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003368:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000336a:	180026f3          	csrr	a3,satp
    8000336e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003370:	7d38                	ld	a4,120(a0)
    80003372:	7134                	ld	a3,96(a0)
    80003374:	6585                	lui	a1,0x1
    80003376:	96ae                	add	a3,a3,a1
    80003378:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000337a:	7d38                	ld	a4,120(a0)
    8000337c:	00000697          	auipc	a3,0x0
    80003380:	13868693          	addi	a3,a3,312 # 800034b4 <usertrap>
    80003384:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003386:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003388:	8692                	mv	a3,tp
    8000338a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000338c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003390:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003394:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003398:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000339c:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000339e:	6f18                	ld	a4,24(a4)
    800033a0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800033a4:	792c                	ld	a1,112(a0)
    800033a6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800033a8:	00004717          	auipc	a4,0x4
    800033ac:	ce870713          	addi	a4,a4,-792 # 80007090 <userret>
    800033b0:	8f11                	sub	a4,a4,a2
    800033b2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800033b4:	577d                	li	a4,-1
    800033b6:	177e                	slli	a4,a4,0x3f
    800033b8:	8dd9                	or	a1,a1,a4
    800033ba:	02000537          	lui	a0,0x2000
    800033be:	157d                	addi	a0,a0,-1
    800033c0:	0536                	slli	a0,a0,0xd
    800033c2:	9782                	jalr	a5
}
    800033c4:	60a2                	ld	ra,8(sp)
    800033c6:	6402                	ld	s0,0(sp)
    800033c8:	0141                	addi	sp,sp,16
    800033ca:	8082                	ret

00000000800033cc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800033cc:	1101                	addi	sp,sp,-32
    800033ce:	ec06                	sd	ra,24(sp)
    800033d0:	e822                	sd	s0,16(sp)
    800033d2:	e426                	sd	s1,8(sp)
    800033d4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800033d6:	0000e497          	auipc	s1,0xe
    800033da:	0ca48493          	addi	s1,s1,202 # 800114a0 <tickslock>
    800033de:	8526                	mv	a0,s1
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	804080e7          	jalr	-2044(ra) # 80000be4 <acquire>
  ticks++;
    800033e8:	00007517          	auipc	a0,0x7
    800033ec:	c5050513          	addi	a0,a0,-944 # 8000a038 <ticks>
    800033f0:	411c                	lw	a5,0(a0)
    800033f2:	2785                	addiw	a5,a5,1
    800033f4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	8ce080e7          	jalr	-1842(ra) # 80002cc4 <wakeup>
  release(&tickslock);
    800033fe:	8526                	mv	a0,s1
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	8aa080e7          	jalr	-1878(ra) # 80000caa <release>
}
    80003408:	60e2                	ld	ra,24(sp)
    8000340a:	6442                	ld	s0,16(sp)
    8000340c:	64a2                	ld	s1,8(sp)
    8000340e:	6105                	addi	sp,sp,32
    80003410:	8082                	ret

0000000080003412 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003412:	1101                	addi	sp,sp,-32
    80003414:	ec06                	sd	ra,24(sp)
    80003416:	e822                	sd	s0,16(sp)
    80003418:	e426                	sd	s1,8(sp)
    8000341a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000341c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003420:	00074d63          	bltz	a4,8000343a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003424:	57fd                	li	a5,-1
    80003426:	17fe                	slli	a5,a5,0x3f
    80003428:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000342a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000342c:	06f70363          	beq	a4,a5,80003492 <devintr+0x80>
  }
}
    80003430:	60e2                	ld	ra,24(sp)
    80003432:	6442                	ld	s0,16(sp)
    80003434:	64a2                	ld	s1,8(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret
     (scause & 0xff) == 9){
    8000343a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000343e:	46a5                	li	a3,9
    80003440:	fed792e3          	bne	a5,a3,80003424 <devintr+0x12>
    int irq = plic_claim();
    80003444:	00003097          	auipc	ra,0x3
    80003448:	464080e7          	jalr	1124(ra) # 800068a8 <plic_claim>
    8000344c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000344e:	47a9                	li	a5,10
    80003450:	02f50763          	beq	a0,a5,8000347e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003454:	4785                	li	a5,1
    80003456:	02f50963          	beq	a0,a5,80003488 <devintr+0x76>
    return 1;
    8000345a:	4505                	li	a0,1
    } else if(irq){
    8000345c:	d8f1                	beqz	s1,80003430 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000345e:	85a6                	mv	a1,s1
    80003460:	00005517          	auipc	a0,0x5
    80003464:	6e850513          	addi	a0,a0,1768 # 80008b48 <states.1763+0x38>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	120080e7          	jalr	288(ra) # 80000588 <printf>
      plic_complete(irq);
    80003470:	8526                	mv	a0,s1
    80003472:	00003097          	auipc	ra,0x3
    80003476:	45a080e7          	jalr	1114(ra) # 800068cc <plic_complete>
    return 1;
    8000347a:	4505                	li	a0,1
    8000347c:	bf55                	j	80003430 <devintr+0x1e>
      uartintr();
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	52a080e7          	jalr	1322(ra) # 800009a8 <uartintr>
    80003486:	b7ed                	j	80003470 <devintr+0x5e>
      virtio_disk_intr();
    80003488:	00004097          	auipc	ra,0x4
    8000348c:	924080e7          	jalr	-1756(ra) # 80006dac <virtio_disk_intr>
    80003490:	b7c5                	j	80003470 <devintr+0x5e>
    if(cpuid() == 0){
    80003492:	fffff097          	auipc	ra,0xfffff
    80003496:	a06080e7          	jalr	-1530(ra) # 80001e98 <cpuid>
    8000349a:	c901                	beqz	a0,800034aa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000349c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800034a0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800034a2:	14479073          	csrw	sip,a5
    return 2;
    800034a6:	4509                	li	a0,2
    800034a8:	b761                	j	80003430 <devintr+0x1e>
      clockintr();
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	f22080e7          	jalr	-222(ra) # 800033cc <clockintr>
    800034b2:	b7ed                	j	8000349c <devintr+0x8a>

00000000800034b4 <usertrap>:
{
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	e04a                	sd	s2,0(sp)
    800034be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034c0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800034c4:	1007f793          	andi	a5,a5,256
    800034c8:	e3ad                	bnez	a5,8000352a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800034ca:	00003797          	auipc	a5,0x3
    800034ce:	2d678793          	addi	a5,a5,726 # 800067a0 <kernelvec>
    800034d2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800034d6:	fffff097          	auipc	ra,0xfffff
    800034da:	9ee080e7          	jalr	-1554(ra) # 80001ec4 <myproc>
    800034de:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800034e0:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034e2:	14102773          	csrr	a4,sepc
    800034e6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034e8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800034ec:	47a1                	li	a5,8
    800034ee:	04f71c63          	bne	a4,a5,80003546 <usertrap+0x92>
    if(p->killed)
    800034f2:	551c                	lw	a5,40(a0)
    800034f4:	e3b9                	bnez	a5,8000353a <usertrap+0x86>
    p->trapframe->epc += 4;
    800034f6:	7cb8                	ld	a4,120(s1)
    800034f8:	6f1c                	ld	a5,24(a4)
    800034fa:	0791                	addi	a5,a5,4
    800034fc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003502:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003506:	10079073          	csrw	sstatus,a5
    syscall();
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	2e0080e7          	jalr	736(ra) # 800037ea <syscall>
  if(p->killed)
    80003512:	549c                	lw	a5,40(s1)
    80003514:	ebc1                	bnez	a5,800035a4 <usertrap+0xf0>
  usertrapret();
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	e18080e7          	jalr	-488(ra) # 8000332e <usertrapret>
}
    8000351e:	60e2                	ld	ra,24(sp)
    80003520:	6442                	ld	s0,16(sp)
    80003522:	64a2                	ld	s1,8(sp)
    80003524:	6902                	ld	s2,0(sp)
    80003526:	6105                	addi	sp,sp,32
    80003528:	8082                	ret
    panic("usertrap: not from user mode");
    8000352a:	00005517          	auipc	a0,0x5
    8000352e:	63e50513          	addi	a0,a0,1598 # 80008b68 <states.1763+0x58>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	00c080e7          	jalr	12(ra) # 8000053e <panic>
      exit(-1);
    8000353a:	557d                	li	a0,-1
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	9d0080e7          	jalr	-1584(ra) # 80002f0c <exit>
    80003544:	bf4d                	j	800034f6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	ecc080e7          	jalr	-308(ra) # 80003412 <devintr>
    8000354e:	892a                	mv	s2,a0
    80003550:	c501                	beqz	a0,80003558 <usertrap+0xa4>
  if(p->killed)
    80003552:	549c                	lw	a5,40(s1)
    80003554:	c3a1                	beqz	a5,80003594 <usertrap+0xe0>
    80003556:	a815                	j	8000358a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003558:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000355c:	5890                	lw	a2,48(s1)
    8000355e:	00005517          	auipc	a0,0x5
    80003562:	62a50513          	addi	a0,a0,1578 # 80008b88 <states.1763+0x78>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	022080e7          	jalr	34(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000356e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003572:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003576:	00005517          	auipc	a0,0x5
    8000357a:	64250513          	addi	a0,a0,1602 # 80008bb8 <states.1763+0xa8>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	00a080e7          	jalr	10(ra) # 80000588 <printf>
    p->killed = 1;
    80003586:	4785                	li	a5,1
    80003588:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000358a:	557d                	li	a0,-1
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	980080e7          	jalr	-1664(ra) # 80002f0c <exit>
  if(which_dev == 2)
    80003594:	4789                	li	a5,2
    80003596:	f8f910e3          	bne	s2,a5,80003516 <usertrap+0x62>
    yield();
    8000359a:	fffff097          	auipc	ra,0xfffff
    8000359e:	43c080e7          	jalr	1084(ra) # 800029d6 <yield>
    800035a2:	bf95                	j	80003516 <usertrap+0x62>
  int which_dev = 0;
    800035a4:	4901                	li	s2,0
    800035a6:	b7d5                	j	8000358a <usertrap+0xd6>

00000000800035a8 <kerneltrap>:
{
    800035a8:	7179                	addi	sp,sp,-48
    800035aa:	f406                	sd	ra,40(sp)
    800035ac:	f022                	sd	s0,32(sp)
    800035ae:	ec26                	sd	s1,24(sp)
    800035b0:	e84a                	sd	s2,16(sp)
    800035b2:	e44e                	sd	s3,8(sp)
    800035b4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035b6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035ba:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035be:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800035c2:	1004f793          	andi	a5,s1,256
    800035c6:	cb85                	beqz	a5,800035f6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035c8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800035cc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800035ce:	ef85                	bnez	a5,80003606 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	e42080e7          	jalr	-446(ra) # 80003412 <devintr>
    800035d8:	cd1d                	beqz	a0,80003616 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800035da:	4789                	li	a5,2
    800035dc:	06f50a63          	beq	a0,a5,80003650 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800035e0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800035e4:	10049073          	csrw	sstatus,s1
}
    800035e8:	70a2                	ld	ra,40(sp)
    800035ea:	7402                	ld	s0,32(sp)
    800035ec:	64e2                	ld	s1,24(sp)
    800035ee:	6942                	ld	s2,16(sp)
    800035f0:	69a2                	ld	s3,8(sp)
    800035f2:	6145                	addi	sp,sp,48
    800035f4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800035f6:	00005517          	auipc	a0,0x5
    800035fa:	5e250513          	addi	a0,a0,1506 # 80008bd8 <states.1763+0xc8>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003606:	00005517          	auipc	a0,0x5
    8000360a:	5fa50513          	addi	a0,a0,1530 # 80008c00 <states.1763+0xf0>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003616:	85ce                	mv	a1,s3
    80003618:	00005517          	auipc	a0,0x5
    8000361c:	60850513          	addi	a0,a0,1544 # 80008c20 <states.1763+0x110>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f68080e7          	jalr	-152(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003628:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000362c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003630:	00005517          	auipc	a0,0x5
    80003634:	60050513          	addi	a0,a0,1536 # 80008c30 <states.1763+0x120>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f50080e7          	jalr	-176(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003640:	00005517          	auipc	a0,0x5
    80003644:	60850513          	addi	a0,a0,1544 # 80008c48 <states.1763+0x138>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	ef6080e7          	jalr	-266(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003650:	fffff097          	auipc	ra,0xfffff
    80003654:	874080e7          	jalr	-1932(ra) # 80001ec4 <myproc>
    80003658:	d541                	beqz	a0,800035e0 <kerneltrap+0x38>
    8000365a:	fffff097          	auipc	ra,0xfffff
    8000365e:	86a080e7          	jalr	-1942(ra) # 80001ec4 <myproc>
    80003662:	4d18                	lw	a4,24(a0)
    80003664:	4791                	li	a5,4
    80003666:	f6f71de3          	bne	a4,a5,800035e0 <kerneltrap+0x38>
    yield();
    8000366a:	fffff097          	auipc	ra,0xfffff
    8000366e:	36c080e7          	jalr	876(ra) # 800029d6 <yield>
    80003672:	b7bd                	j	800035e0 <kerneltrap+0x38>

0000000080003674 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003674:	1101                	addi	sp,sp,-32
    80003676:	ec06                	sd	ra,24(sp)
    80003678:	e822                	sd	s0,16(sp)
    8000367a:	e426                	sd	s1,8(sp)
    8000367c:	1000                	addi	s0,sp,32
    8000367e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003680:	fffff097          	auipc	ra,0xfffff
    80003684:	844080e7          	jalr	-1980(ra) # 80001ec4 <myproc>
  switch (n) {
    80003688:	4795                	li	a5,5
    8000368a:	0497e163          	bltu	a5,s1,800036cc <argraw+0x58>
    8000368e:	048a                	slli	s1,s1,0x2
    80003690:	00005717          	auipc	a4,0x5
    80003694:	5f070713          	addi	a4,a4,1520 # 80008c80 <states.1763+0x170>
    80003698:	94ba                	add	s1,s1,a4
    8000369a:	409c                	lw	a5,0(s1)
    8000369c:	97ba                	add	a5,a5,a4
    8000369e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800036a0:	7d3c                	ld	a5,120(a0)
    800036a2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800036a4:	60e2                	ld	ra,24(sp)
    800036a6:	6442                	ld	s0,16(sp)
    800036a8:	64a2                	ld	s1,8(sp)
    800036aa:	6105                	addi	sp,sp,32
    800036ac:	8082                	ret
    return p->trapframe->a1;
    800036ae:	7d3c                	ld	a5,120(a0)
    800036b0:	7fa8                	ld	a0,120(a5)
    800036b2:	bfcd                	j	800036a4 <argraw+0x30>
    return p->trapframe->a2;
    800036b4:	7d3c                	ld	a5,120(a0)
    800036b6:	63c8                	ld	a0,128(a5)
    800036b8:	b7f5                	j	800036a4 <argraw+0x30>
    return p->trapframe->a3;
    800036ba:	7d3c                	ld	a5,120(a0)
    800036bc:	67c8                	ld	a0,136(a5)
    800036be:	b7dd                	j	800036a4 <argraw+0x30>
    return p->trapframe->a4;
    800036c0:	7d3c                	ld	a5,120(a0)
    800036c2:	6bc8                	ld	a0,144(a5)
    800036c4:	b7c5                	j	800036a4 <argraw+0x30>
    return p->trapframe->a5;
    800036c6:	7d3c                	ld	a5,120(a0)
    800036c8:	6fc8                	ld	a0,152(a5)
    800036ca:	bfe9                	j	800036a4 <argraw+0x30>
  panic("argraw");
    800036cc:	00005517          	auipc	a0,0x5
    800036d0:	58c50513          	addi	a0,a0,1420 # 80008c58 <states.1763+0x148>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>

00000000800036dc <fetchaddr>:
{
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	e04a                	sd	s2,0(sp)
    800036e6:	1000                	addi	s0,sp,32
    800036e8:	84aa                	mv	s1,a0
    800036ea:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800036ec:	ffffe097          	auipc	ra,0xffffe
    800036f0:	7d8080e7          	jalr	2008(ra) # 80001ec4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800036f4:	753c                	ld	a5,104(a0)
    800036f6:	02f4f863          	bgeu	s1,a5,80003726 <fetchaddr+0x4a>
    800036fa:	00848713          	addi	a4,s1,8
    800036fe:	02e7e663          	bltu	a5,a4,8000372a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003702:	46a1                	li	a3,8
    80003704:	8626                	mv	a2,s1
    80003706:	85ca                	mv	a1,s2
    80003708:	7928                	ld	a0,112(a0)
    8000370a:	ffffe097          	auipc	ra,0xffffe
    8000370e:	018080e7          	jalr	24(ra) # 80001722 <copyin>
    80003712:	00a03533          	snez	a0,a0
    80003716:	40a00533          	neg	a0,a0
}
    8000371a:	60e2                	ld	ra,24(sp)
    8000371c:	6442                	ld	s0,16(sp)
    8000371e:	64a2                	ld	s1,8(sp)
    80003720:	6902                	ld	s2,0(sp)
    80003722:	6105                	addi	sp,sp,32
    80003724:	8082                	ret
    return -1;
    80003726:	557d                	li	a0,-1
    80003728:	bfcd                	j	8000371a <fetchaddr+0x3e>
    8000372a:	557d                	li	a0,-1
    8000372c:	b7fd                	j	8000371a <fetchaddr+0x3e>

000000008000372e <fetchstr>:
{
    8000372e:	7179                	addi	sp,sp,-48
    80003730:	f406                	sd	ra,40(sp)
    80003732:	f022                	sd	s0,32(sp)
    80003734:	ec26                	sd	s1,24(sp)
    80003736:	e84a                	sd	s2,16(sp)
    80003738:	e44e                	sd	s3,8(sp)
    8000373a:	1800                	addi	s0,sp,48
    8000373c:	892a                	mv	s2,a0
    8000373e:	84ae                	mv	s1,a1
    80003740:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003742:	ffffe097          	auipc	ra,0xffffe
    80003746:	782080e7          	jalr	1922(ra) # 80001ec4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000374a:	86ce                	mv	a3,s3
    8000374c:	864a                	mv	a2,s2
    8000374e:	85a6                	mv	a1,s1
    80003750:	7928                	ld	a0,112(a0)
    80003752:	ffffe097          	auipc	ra,0xffffe
    80003756:	05c080e7          	jalr	92(ra) # 800017ae <copyinstr>
  if(err < 0)
    8000375a:	00054763          	bltz	a0,80003768 <fetchstr+0x3a>
  return strlen(buf);
    8000375e:	8526                	mv	a0,s1
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	728080e7          	jalr	1832(ra) # 80000e88 <strlen>
}
    80003768:	70a2                	ld	ra,40(sp)
    8000376a:	7402                	ld	s0,32(sp)
    8000376c:	64e2                	ld	s1,24(sp)
    8000376e:	6942                	ld	s2,16(sp)
    80003770:	69a2                	ld	s3,8(sp)
    80003772:	6145                	addi	sp,sp,48
    80003774:	8082                	ret

0000000080003776 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003776:	1101                	addi	sp,sp,-32
    80003778:	ec06                	sd	ra,24(sp)
    8000377a:	e822                	sd	s0,16(sp)
    8000377c:	e426                	sd	s1,8(sp)
    8000377e:	1000                	addi	s0,sp,32
    80003780:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003782:	00000097          	auipc	ra,0x0
    80003786:	ef2080e7          	jalr	-270(ra) # 80003674 <argraw>
    8000378a:	c088                	sw	a0,0(s1)
  return 0;
}
    8000378c:	4501                	li	a0,0
    8000378e:	60e2                	ld	ra,24(sp)
    80003790:	6442                	ld	s0,16(sp)
    80003792:	64a2                	ld	s1,8(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret

0000000080003798 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003798:	1101                	addi	sp,sp,-32
    8000379a:	ec06                	sd	ra,24(sp)
    8000379c:	e822                	sd	s0,16(sp)
    8000379e:	e426                	sd	s1,8(sp)
    800037a0:	1000                	addi	s0,sp,32
    800037a2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	ed0080e7          	jalr	-304(ra) # 80003674 <argraw>
    800037ac:	e088                	sd	a0,0(s1)
  return 0;
}
    800037ae:	4501                	li	a0,0
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6105                	addi	sp,sp,32
    800037b8:	8082                	ret

00000000800037ba <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800037ba:	1101                	addi	sp,sp,-32
    800037bc:	ec06                	sd	ra,24(sp)
    800037be:	e822                	sd	s0,16(sp)
    800037c0:	e426                	sd	s1,8(sp)
    800037c2:	e04a                	sd	s2,0(sp)
    800037c4:	1000                	addi	s0,sp,32
    800037c6:	84ae                	mv	s1,a1
    800037c8:	8932                	mv	s2,a2
  *ip = argraw(n);
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	eaa080e7          	jalr	-342(ra) # 80003674 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800037d2:	864a                	mv	a2,s2
    800037d4:	85a6                	mv	a1,s1
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	f58080e7          	jalr	-168(ra) # 8000372e <fetchstr>
}
    800037de:	60e2                	ld	ra,24(sp)
    800037e0:	6442                	ld	s0,16(sp)
    800037e2:	64a2                	ld	s1,8(sp)
    800037e4:	6902                	ld	s2,0(sp)
    800037e6:	6105                	addi	sp,sp,32
    800037e8:	8082                	ret

00000000800037ea <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800037ea:	1101                	addi	sp,sp,-32
    800037ec:	ec06                	sd	ra,24(sp)
    800037ee:	e822                	sd	s0,16(sp)
    800037f0:	e426                	sd	s1,8(sp)
    800037f2:	e04a                	sd	s2,0(sp)
    800037f4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800037f6:	ffffe097          	auipc	ra,0xffffe
    800037fa:	6ce080e7          	jalr	1742(ra) # 80001ec4 <myproc>
    800037fe:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003800:	07853903          	ld	s2,120(a0)
    80003804:	0a893783          	ld	a5,168(s2)
    80003808:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000380c:	37fd                	addiw	a5,a5,-1
    8000380e:	4751                	li	a4,20
    80003810:	00f76f63          	bltu	a4,a5,8000382e <syscall+0x44>
    80003814:	00369713          	slli	a4,a3,0x3
    80003818:	00005797          	auipc	a5,0x5
    8000381c:	48078793          	addi	a5,a5,1152 # 80008c98 <syscalls>
    80003820:	97ba                	add	a5,a5,a4
    80003822:	639c                	ld	a5,0(a5)
    80003824:	c789                	beqz	a5,8000382e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003826:	9782                	jalr	a5
    80003828:	06a93823          	sd	a0,112(s2)
    8000382c:	a839                	j	8000384a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000382e:	17848613          	addi	a2,s1,376
    80003832:	588c                	lw	a1,48(s1)
    80003834:	00005517          	auipc	a0,0x5
    80003838:	42c50513          	addi	a0,a0,1068 # 80008c60 <states.1763+0x150>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	d4c080e7          	jalr	-692(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003844:	7cbc                	ld	a5,120(s1)
    80003846:	577d                	li	a4,-1
    80003848:	fbb8                	sd	a4,112(a5)
  }
}
    8000384a:	60e2                	ld	ra,24(sp)
    8000384c:	6442                	ld	s0,16(sp)
    8000384e:	64a2                	ld	s1,8(sp)
    80003850:	6902                	ld	s2,0(sp)
    80003852:	6105                	addi	sp,sp,32
    80003854:	8082                	ret

0000000080003856 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003856:	1101                	addi	sp,sp,-32
    80003858:	ec06                	sd	ra,24(sp)
    8000385a:	e822                	sd	s0,16(sp)
    8000385c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000385e:	fec40593          	addi	a1,s0,-20
    80003862:	4501                	li	a0,0
    80003864:	00000097          	auipc	ra,0x0
    80003868:	f12080e7          	jalr	-238(ra) # 80003776 <argint>
    return -1;
    8000386c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000386e:	00054963          	bltz	a0,80003880 <sys_exit+0x2a>
  exit(n);
    80003872:	fec42503          	lw	a0,-20(s0)
    80003876:	fffff097          	auipc	ra,0xfffff
    8000387a:	696080e7          	jalr	1686(ra) # 80002f0c <exit>
  return 0;  // not reached
    8000387e:	4781                	li	a5,0
}
    80003880:	853e                	mv	a0,a5
    80003882:	60e2                	ld	ra,24(sp)
    80003884:	6442                	ld	s0,16(sp)
    80003886:	6105                	addi	sp,sp,32
    80003888:	8082                	ret

000000008000388a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000388a:	1141                	addi	sp,sp,-16
    8000388c:	e406                	sd	ra,8(sp)
    8000388e:	e022                	sd	s0,0(sp)
    80003890:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003892:	ffffe097          	auipc	ra,0xffffe
    80003896:	632080e7          	jalr	1586(ra) # 80001ec4 <myproc>
}
    8000389a:	5908                	lw	a0,48(a0)
    8000389c:	60a2                	ld	ra,8(sp)
    8000389e:	6402                	ld	s0,0(sp)
    800038a0:	0141                	addi	sp,sp,16
    800038a2:	8082                	ret

00000000800038a4 <sys_fork>:

uint64
sys_fork(void)
{
    800038a4:	1141                	addi	sp,sp,-16
    800038a6:	e406                	sd	ra,8(sp)
    800038a8:	e022                	sd	s0,0(sp)
    800038aa:	0800                	addi	s0,sp,16
  return fork();
    800038ac:	fffff097          	auipc	ra,0xfffff
    800038b0:	c34080e7          	jalr	-972(ra) # 800024e0 <fork>
}
    800038b4:	60a2                	ld	ra,8(sp)
    800038b6:	6402                	ld	s0,0(sp)
    800038b8:	0141                	addi	sp,sp,16
    800038ba:	8082                	ret

00000000800038bc <sys_wait>:

uint64
sys_wait(void)
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800038c4:	fe840593          	addi	a1,s0,-24
    800038c8:	4501                	li	a0,0
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	ece080e7          	jalr	-306(ra) # 80003798 <argaddr>
    800038d2:	87aa                	mv	a5,a0
    return -1;
    800038d4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800038d6:	0007c863          	bltz	a5,800038e6 <sys_wait+0x2a>
  return wait(p);
    800038da:	fe843503          	ld	a0,-24(s0)
    800038de:	fffff097          	auipc	ra,0xfffff
    800038e2:	27e080e7          	jalr	638(ra) # 80002b5c <wait>
}
    800038e6:	60e2                	ld	ra,24(sp)
    800038e8:	6442                	ld	s0,16(sp)
    800038ea:	6105                	addi	sp,sp,32
    800038ec:	8082                	ret

00000000800038ee <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800038ee:	7179                	addi	sp,sp,-48
    800038f0:	f406                	sd	ra,40(sp)
    800038f2:	f022                	sd	s0,32(sp)
    800038f4:	ec26                	sd	s1,24(sp)
    800038f6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800038f8:	fdc40593          	addi	a1,s0,-36
    800038fc:	4501                	li	a0,0
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	e78080e7          	jalr	-392(ra) # 80003776 <argint>
    80003906:	87aa                	mv	a5,a0
    return -1;
    80003908:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000390a:	0207c063          	bltz	a5,8000392a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000390e:	ffffe097          	auipc	ra,0xffffe
    80003912:	5b6080e7          	jalr	1462(ra) # 80001ec4 <myproc>
    80003916:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003918:	fdc42503          	lw	a0,-36(s0)
    8000391c:	fffff097          	auipc	ra,0xfffff
    80003920:	b50080e7          	jalr	-1200(ra) # 8000246c <growproc>
    80003924:	00054863          	bltz	a0,80003934 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003928:	8526                	mv	a0,s1
}
    8000392a:	70a2                	ld	ra,40(sp)
    8000392c:	7402                	ld	s0,32(sp)
    8000392e:	64e2                	ld	s1,24(sp)
    80003930:	6145                	addi	sp,sp,48
    80003932:	8082                	ret
    return -1;
    80003934:	557d                	li	a0,-1
    80003936:	bfd5                	j	8000392a <sys_sbrk+0x3c>

0000000080003938 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003938:	7139                	addi	sp,sp,-64
    8000393a:	fc06                	sd	ra,56(sp)
    8000393c:	f822                	sd	s0,48(sp)
    8000393e:	f426                	sd	s1,40(sp)
    80003940:	f04a                	sd	s2,32(sp)
    80003942:	ec4e                	sd	s3,24(sp)
    80003944:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003946:	fcc40593          	addi	a1,s0,-52
    8000394a:	4501                	li	a0,0
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	e2a080e7          	jalr	-470(ra) # 80003776 <argint>
    return -1;
    80003954:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003956:	06054563          	bltz	a0,800039c0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000395a:	0000e517          	auipc	a0,0xe
    8000395e:	b4650513          	addi	a0,a0,-1210 # 800114a0 <tickslock>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	282080e7          	jalr	642(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000396a:	00006917          	auipc	s2,0x6
    8000396e:	6ce92903          	lw	s2,1742(s2) # 8000a038 <ticks>
  while(ticks - ticks0 < n){
    80003972:	fcc42783          	lw	a5,-52(s0)
    80003976:	cf85                	beqz	a5,800039ae <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003978:	0000e997          	auipc	s3,0xe
    8000397c:	b2898993          	addi	s3,s3,-1240 # 800114a0 <tickslock>
    80003980:	00006497          	auipc	s1,0x6
    80003984:	6b848493          	addi	s1,s1,1720 # 8000a038 <ticks>
    if(myproc()->killed){
    80003988:	ffffe097          	auipc	ra,0xffffe
    8000398c:	53c080e7          	jalr	1340(ra) # 80001ec4 <myproc>
    80003990:	551c                	lw	a5,40(a0)
    80003992:	ef9d                	bnez	a5,800039d0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003994:	85ce                	mv	a1,s3
    80003996:	8526                	mv	a0,s1
    80003998:	fffff097          	auipc	ra,0xfffff
    8000399c:	0f8080e7          	jalr	248(ra) # 80002a90 <sleep>
  while(ticks - ticks0 < n){
    800039a0:	409c                	lw	a5,0(s1)
    800039a2:	412787bb          	subw	a5,a5,s2
    800039a6:	fcc42703          	lw	a4,-52(s0)
    800039aa:	fce7efe3          	bltu	a5,a4,80003988 <sys_sleep+0x50>
  }
  release(&tickslock);
    800039ae:	0000e517          	auipc	a0,0xe
    800039b2:	af250513          	addi	a0,a0,-1294 # 800114a0 <tickslock>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	2f4080e7          	jalr	756(ra) # 80000caa <release>
  return 0;
    800039be:	4781                	li	a5,0
}
    800039c0:	853e                	mv	a0,a5
    800039c2:	70e2                	ld	ra,56(sp)
    800039c4:	7442                	ld	s0,48(sp)
    800039c6:	74a2                	ld	s1,40(sp)
    800039c8:	7902                	ld	s2,32(sp)
    800039ca:	69e2                	ld	s3,24(sp)
    800039cc:	6121                	addi	sp,sp,64
    800039ce:	8082                	ret
      release(&tickslock);
    800039d0:	0000e517          	auipc	a0,0xe
    800039d4:	ad050513          	addi	a0,a0,-1328 # 800114a0 <tickslock>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	2d2080e7          	jalr	722(ra) # 80000caa <release>
      return -1;
    800039e0:	57fd                	li	a5,-1
    800039e2:	bff9                	j	800039c0 <sys_sleep+0x88>

00000000800039e4 <sys_kill>:

uint64
sys_kill(void)
{
    800039e4:	1101                	addi	sp,sp,-32
    800039e6:	ec06                	sd	ra,24(sp)
    800039e8:	e822                	sd	s0,16(sp)
    800039ea:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800039ec:	fec40593          	addi	a1,s0,-20
    800039f0:	4501                	li	a0,0
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	d84080e7          	jalr	-636(ra) # 80003776 <argint>
    800039fa:	87aa                	mv	a5,a0
    return -1;
    800039fc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800039fe:	0007c863          	bltz	a5,80003a0e <sys_kill+0x2a>
  return kill(pid);
    80003a02:	fec42503          	lw	a0,-20(s0)
    80003a06:	fffff097          	auipc	ra,0xfffff
    80003a0a:	644080e7          	jalr	1604(ra) # 8000304a <kill>
}
    80003a0e:	60e2                	ld	ra,24(sp)
    80003a10:	6442                	ld	s0,16(sp)
    80003a12:	6105                	addi	sp,sp,32
    80003a14:	8082                	ret

0000000080003a16 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003a16:	1101                	addi	sp,sp,-32
    80003a18:	ec06                	sd	ra,24(sp)
    80003a1a:	e822                	sd	s0,16(sp)
    80003a1c:	e426                	sd	s1,8(sp)
    80003a1e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003a20:	0000e517          	auipc	a0,0xe
    80003a24:	a8050513          	addi	a0,a0,-1408 # 800114a0 <tickslock>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	1bc080e7          	jalr	444(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003a30:	00006497          	auipc	s1,0x6
    80003a34:	6084a483          	lw	s1,1544(s1) # 8000a038 <ticks>
  release(&tickslock);
    80003a38:	0000e517          	auipc	a0,0xe
    80003a3c:	a6850513          	addi	a0,a0,-1432 # 800114a0 <tickslock>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	26a080e7          	jalr	618(ra) # 80000caa <release>
  return xticks;
}
    80003a48:	02049513          	slli	a0,s1,0x20
    80003a4c:	9101                	srli	a0,a0,0x20
    80003a4e:	60e2                	ld	ra,24(sp)
    80003a50:	6442                	ld	s0,16(sp)
    80003a52:	64a2                	ld	s1,8(sp)
    80003a54:	6105                	addi	sp,sp,32
    80003a56:	8082                	ret

0000000080003a58 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a58:	7179                	addi	sp,sp,-48
    80003a5a:	f406                	sd	ra,40(sp)
    80003a5c:	f022                	sd	s0,32(sp)
    80003a5e:	ec26                	sd	s1,24(sp)
    80003a60:	e84a                	sd	s2,16(sp)
    80003a62:	e44e                	sd	s3,8(sp)
    80003a64:	e052                	sd	s4,0(sp)
    80003a66:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a68:	00005597          	auipc	a1,0x5
    80003a6c:	2e058593          	addi	a1,a1,736 # 80008d48 <syscalls+0xb0>
    80003a70:	0000e517          	auipc	a0,0xe
    80003a74:	a4850513          	addi	a0,a0,-1464 # 800114b8 <bcache>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	0dc080e7          	jalr	220(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a80:	00016797          	auipc	a5,0x16
    80003a84:	a3878793          	addi	a5,a5,-1480 # 800194b8 <bcache+0x8000>
    80003a88:	00016717          	auipc	a4,0x16
    80003a8c:	c9870713          	addi	a4,a4,-872 # 80019720 <bcache+0x8268>
    80003a90:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a94:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a98:	0000e497          	auipc	s1,0xe
    80003a9c:	a3848493          	addi	s1,s1,-1480 # 800114d0 <bcache+0x18>
    b->next = bcache.head.next;
    80003aa0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003aa2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003aa4:	00005a17          	auipc	s4,0x5
    80003aa8:	2aca0a13          	addi	s4,s4,684 # 80008d50 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003aac:	2b893783          	ld	a5,696(s2)
    80003ab0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003ab2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003ab6:	85d2                	mv	a1,s4
    80003ab8:	01048513          	addi	a0,s1,16
    80003abc:	00001097          	auipc	ra,0x1
    80003ac0:	4bc080e7          	jalr	1212(ra) # 80004f78 <initsleeplock>
    bcache.head.next->prev = b;
    80003ac4:	2b893783          	ld	a5,696(s2)
    80003ac8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003aca:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ace:	45848493          	addi	s1,s1,1112
    80003ad2:	fd349de3          	bne	s1,s3,80003aac <binit+0x54>
  }
}
    80003ad6:	70a2                	ld	ra,40(sp)
    80003ad8:	7402                	ld	s0,32(sp)
    80003ada:	64e2                	ld	s1,24(sp)
    80003adc:	6942                	ld	s2,16(sp)
    80003ade:	69a2                	ld	s3,8(sp)
    80003ae0:	6a02                	ld	s4,0(sp)
    80003ae2:	6145                	addi	sp,sp,48
    80003ae4:	8082                	ret

0000000080003ae6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003ae6:	7179                	addi	sp,sp,-48
    80003ae8:	f406                	sd	ra,40(sp)
    80003aea:	f022                	sd	s0,32(sp)
    80003aec:	ec26                	sd	s1,24(sp)
    80003aee:	e84a                	sd	s2,16(sp)
    80003af0:	e44e                	sd	s3,8(sp)
    80003af2:	1800                	addi	s0,sp,48
    80003af4:	89aa                	mv	s3,a0
    80003af6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003af8:	0000e517          	auipc	a0,0xe
    80003afc:	9c050513          	addi	a0,a0,-1600 # 800114b8 <bcache>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	0e4080e7          	jalr	228(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b08:	00016497          	auipc	s1,0x16
    80003b0c:	c684b483          	ld	s1,-920(s1) # 80019770 <bcache+0x82b8>
    80003b10:	00016797          	auipc	a5,0x16
    80003b14:	c1078793          	addi	a5,a5,-1008 # 80019720 <bcache+0x8268>
    80003b18:	02f48f63          	beq	s1,a5,80003b56 <bread+0x70>
    80003b1c:	873e                	mv	a4,a5
    80003b1e:	a021                	j	80003b26 <bread+0x40>
    80003b20:	68a4                	ld	s1,80(s1)
    80003b22:	02e48a63          	beq	s1,a4,80003b56 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b26:	449c                	lw	a5,8(s1)
    80003b28:	ff379ce3          	bne	a5,s3,80003b20 <bread+0x3a>
    80003b2c:	44dc                	lw	a5,12(s1)
    80003b2e:	ff2799e3          	bne	a5,s2,80003b20 <bread+0x3a>
      b->refcnt++;
    80003b32:	40bc                	lw	a5,64(s1)
    80003b34:	2785                	addiw	a5,a5,1
    80003b36:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b38:	0000e517          	auipc	a0,0xe
    80003b3c:	98050513          	addi	a0,a0,-1664 # 800114b8 <bcache>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	16a080e7          	jalr	362(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    80003b48:	01048513          	addi	a0,s1,16
    80003b4c:	00001097          	auipc	ra,0x1
    80003b50:	466080e7          	jalr	1126(ra) # 80004fb2 <acquiresleep>
      return b;
    80003b54:	a8b9                	j	80003bb2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b56:	00016497          	auipc	s1,0x16
    80003b5a:	c124b483          	ld	s1,-1006(s1) # 80019768 <bcache+0x82b0>
    80003b5e:	00016797          	auipc	a5,0x16
    80003b62:	bc278793          	addi	a5,a5,-1086 # 80019720 <bcache+0x8268>
    80003b66:	00f48863          	beq	s1,a5,80003b76 <bread+0x90>
    80003b6a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b6c:	40bc                	lw	a5,64(s1)
    80003b6e:	cf81                	beqz	a5,80003b86 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b70:	64a4                	ld	s1,72(s1)
    80003b72:	fee49de3          	bne	s1,a4,80003b6c <bread+0x86>
  panic("bget: no buffers");
    80003b76:	00005517          	auipc	a0,0x5
    80003b7a:	1e250513          	addi	a0,a0,482 # 80008d58 <syscalls+0xc0>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	9c0080e7          	jalr	-1600(ra) # 8000053e <panic>
      b->dev = dev;
    80003b86:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003b8a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003b8e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b92:	4785                	li	a5,1
    80003b94:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b96:	0000e517          	auipc	a0,0xe
    80003b9a:	92250513          	addi	a0,a0,-1758 # 800114b8 <bcache>
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	10c080e7          	jalr	268(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    80003ba6:	01048513          	addi	a0,s1,16
    80003baa:	00001097          	auipc	ra,0x1
    80003bae:	408080e7          	jalr	1032(ra) # 80004fb2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003bb2:	409c                	lw	a5,0(s1)
    80003bb4:	cb89                	beqz	a5,80003bc6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	70a2                	ld	ra,40(sp)
    80003bba:	7402                	ld	s0,32(sp)
    80003bbc:	64e2                	ld	s1,24(sp)
    80003bbe:	6942                	ld	s2,16(sp)
    80003bc0:	69a2                	ld	s3,8(sp)
    80003bc2:	6145                	addi	sp,sp,48
    80003bc4:	8082                	ret
    virtio_disk_rw(b, 0);
    80003bc6:	4581                	li	a1,0
    80003bc8:	8526                	mv	a0,s1
    80003bca:	00003097          	auipc	ra,0x3
    80003bce:	f0c080e7          	jalr	-244(ra) # 80006ad6 <virtio_disk_rw>
    b->valid = 1;
    80003bd2:	4785                	li	a5,1
    80003bd4:	c09c                	sw	a5,0(s1)
  return b;
    80003bd6:	b7c5                	j	80003bb6 <bread+0xd0>

0000000080003bd8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003bd8:	1101                	addi	sp,sp,-32
    80003bda:	ec06                	sd	ra,24(sp)
    80003bdc:	e822                	sd	s0,16(sp)
    80003bde:	e426                	sd	s1,8(sp)
    80003be0:	1000                	addi	s0,sp,32
    80003be2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003be4:	0541                	addi	a0,a0,16
    80003be6:	00001097          	auipc	ra,0x1
    80003bea:	466080e7          	jalr	1126(ra) # 8000504c <holdingsleep>
    80003bee:	cd01                	beqz	a0,80003c06 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003bf0:	4585                	li	a1,1
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	00003097          	auipc	ra,0x3
    80003bf8:	ee2080e7          	jalr	-286(ra) # 80006ad6 <virtio_disk_rw>
}
    80003bfc:	60e2                	ld	ra,24(sp)
    80003bfe:	6442                	ld	s0,16(sp)
    80003c00:	64a2                	ld	s1,8(sp)
    80003c02:	6105                	addi	sp,sp,32
    80003c04:	8082                	ret
    panic("bwrite");
    80003c06:	00005517          	auipc	a0,0x5
    80003c0a:	16a50513          	addi	a0,a0,362 # 80008d70 <syscalls+0xd8>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	930080e7          	jalr	-1744(ra) # 8000053e <panic>

0000000080003c16 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c16:	1101                	addi	sp,sp,-32
    80003c18:	ec06                	sd	ra,24(sp)
    80003c1a:	e822                	sd	s0,16(sp)
    80003c1c:	e426                	sd	s1,8(sp)
    80003c1e:	e04a                	sd	s2,0(sp)
    80003c20:	1000                	addi	s0,sp,32
    80003c22:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c24:	01050913          	addi	s2,a0,16
    80003c28:	854a                	mv	a0,s2
    80003c2a:	00001097          	auipc	ra,0x1
    80003c2e:	422080e7          	jalr	1058(ra) # 8000504c <holdingsleep>
    80003c32:	c92d                	beqz	a0,80003ca4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c34:	854a                	mv	a0,s2
    80003c36:	00001097          	auipc	ra,0x1
    80003c3a:	3d2080e7          	jalr	978(ra) # 80005008 <releasesleep>

  acquire(&bcache.lock);
    80003c3e:	0000e517          	auipc	a0,0xe
    80003c42:	87a50513          	addi	a0,a0,-1926 # 800114b8 <bcache>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	f9e080e7          	jalr	-98(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003c4e:	40bc                	lw	a5,64(s1)
    80003c50:	37fd                	addiw	a5,a5,-1
    80003c52:	0007871b          	sext.w	a4,a5
    80003c56:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c58:	eb05                	bnez	a4,80003c88 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c5a:	68bc                	ld	a5,80(s1)
    80003c5c:	64b8                	ld	a4,72(s1)
    80003c5e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c60:	64bc                	ld	a5,72(s1)
    80003c62:	68b8                	ld	a4,80(s1)
    80003c64:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c66:	00016797          	auipc	a5,0x16
    80003c6a:	85278793          	addi	a5,a5,-1966 # 800194b8 <bcache+0x8000>
    80003c6e:	2b87b703          	ld	a4,696(a5)
    80003c72:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c74:	00016717          	auipc	a4,0x16
    80003c78:	aac70713          	addi	a4,a4,-1364 # 80019720 <bcache+0x8268>
    80003c7c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c7e:	2b87b703          	ld	a4,696(a5)
    80003c82:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c84:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c88:	0000e517          	auipc	a0,0xe
    80003c8c:	83050513          	addi	a0,a0,-2000 # 800114b8 <bcache>
    80003c90:	ffffd097          	auipc	ra,0xffffd
    80003c94:	01a080e7          	jalr	26(ra) # 80000caa <release>
}
    80003c98:	60e2                	ld	ra,24(sp)
    80003c9a:	6442                	ld	s0,16(sp)
    80003c9c:	64a2                	ld	s1,8(sp)
    80003c9e:	6902                	ld	s2,0(sp)
    80003ca0:	6105                	addi	sp,sp,32
    80003ca2:	8082                	ret
    panic("brelse");
    80003ca4:	00005517          	auipc	a0,0x5
    80003ca8:	0d450513          	addi	a0,a0,212 # 80008d78 <syscalls+0xe0>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	892080e7          	jalr	-1902(ra) # 8000053e <panic>

0000000080003cb4 <bpin>:

void
bpin(struct buf *b) {
    80003cb4:	1101                	addi	sp,sp,-32
    80003cb6:	ec06                	sd	ra,24(sp)
    80003cb8:	e822                	sd	s0,16(sp)
    80003cba:	e426                	sd	s1,8(sp)
    80003cbc:	1000                	addi	s0,sp,32
    80003cbe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cc0:	0000d517          	auipc	a0,0xd
    80003cc4:	7f850513          	addi	a0,a0,2040 # 800114b8 <bcache>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	f1c080e7          	jalr	-228(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003cd0:	40bc                	lw	a5,64(s1)
    80003cd2:	2785                	addiw	a5,a5,1
    80003cd4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003cd6:	0000d517          	auipc	a0,0xd
    80003cda:	7e250513          	addi	a0,a0,2018 # 800114b8 <bcache>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	fcc080e7          	jalr	-52(ra) # 80000caa <release>
}
    80003ce6:	60e2                	ld	ra,24(sp)
    80003ce8:	6442                	ld	s0,16(sp)
    80003cea:	64a2                	ld	s1,8(sp)
    80003cec:	6105                	addi	sp,sp,32
    80003cee:	8082                	ret

0000000080003cf0 <bunpin>:

void
bunpin(struct buf *b) {
    80003cf0:	1101                	addi	sp,sp,-32
    80003cf2:	ec06                	sd	ra,24(sp)
    80003cf4:	e822                	sd	s0,16(sp)
    80003cf6:	e426                	sd	s1,8(sp)
    80003cf8:	1000                	addi	s0,sp,32
    80003cfa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cfc:	0000d517          	auipc	a0,0xd
    80003d00:	7bc50513          	addi	a0,a0,1980 # 800114b8 <bcache>
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	ee0080e7          	jalr	-288(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003d0c:	40bc                	lw	a5,64(s1)
    80003d0e:	37fd                	addiw	a5,a5,-1
    80003d10:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d12:	0000d517          	auipc	a0,0xd
    80003d16:	7a650513          	addi	a0,a0,1958 # 800114b8 <bcache>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	f90080e7          	jalr	-112(ra) # 80000caa <release>
}
    80003d22:	60e2                	ld	ra,24(sp)
    80003d24:	6442                	ld	s0,16(sp)
    80003d26:	64a2                	ld	s1,8(sp)
    80003d28:	6105                	addi	sp,sp,32
    80003d2a:	8082                	ret

0000000080003d2c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d2c:	1101                	addi	sp,sp,-32
    80003d2e:	ec06                	sd	ra,24(sp)
    80003d30:	e822                	sd	s0,16(sp)
    80003d32:	e426                	sd	s1,8(sp)
    80003d34:	e04a                	sd	s2,0(sp)
    80003d36:	1000                	addi	s0,sp,32
    80003d38:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d3a:	00d5d59b          	srliw	a1,a1,0xd
    80003d3e:	00016797          	auipc	a5,0x16
    80003d42:	e567a783          	lw	a5,-426(a5) # 80019b94 <sb+0x1c>
    80003d46:	9dbd                	addw	a1,a1,a5
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	d9e080e7          	jalr	-610(ra) # 80003ae6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d50:	0074f713          	andi	a4,s1,7
    80003d54:	4785                	li	a5,1
    80003d56:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d5a:	14ce                	slli	s1,s1,0x33
    80003d5c:	90d9                	srli	s1,s1,0x36
    80003d5e:	00950733          	add	a4,a0,s1
    80003d62:	05874703          	lbu	a4,88(a4)
    80003d66:	00e7f6b3          	and	a3,a5,a4
    80003d6a:	c69d                	beqz	a3,80003d98 <bfree+0x6c>
    80003d6c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d6e:	94aa                	add	s1,s1,a0
    80003d70:	fff7c793          	not	a5,a5
    80003d74:	8ff9                	and	a5,a5,a4
    80003d76:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d7a:	00001097          	auipc	ra,0x1
    80003d7e:	118080e7          	jalr	280(ra) # 80004e92 <log_write>
  brelse(bp);
    80003d82:	854a                	mv	a0,s2
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	e92080e7          	jalr	-366(ra) # 80003c16 <brelse>
}
    80003d8c:	60e2                	ld	ra,24(sp)
    80003d8e:	6442                	ld	s0,16(sp)
    80003d90:	64a2                	ld	s1,8(sp)
    80003d92:	6902                	ld	s2,0(sp)
    80003d94:	6105                	addi	sp,sp,32
    80003d96:	8082                	ret
    panic("freeing free block");
    80003d98:	00005517          	auipc	a0,0x5
    80003d9c:	fe850513          	addi	a0,a0,-24 # 80008d80 <syscalls+0xe8>
    80003da0:	ffffc097          	auipc	ra,0xffffc
    80003da4:	79e080e7          	jalr	1950(ra) # 8000053e <panic>

0000000080003da8 <balloc>:
{
    80003da8:	711d                	addi	sp,sp,-96
    80003daa:	ec86                	sd	ra,88(sp)
    80003dac:	e8a2                	sd	s0,80(sp)
    80003dae:	e4a6                	sd	s1,72(sp)
    80003db0:	e0ca                	sd	s2,64(sp)
    80003db2:	fc4e                	sd	s3,56(sp)
    80003db4:	f852                	sd	s4,48(sp)
    80003db6:	f456                	sd	s5,40(sp)
    80003db8:	f05a                	sd	s6,32(sp)
    80003dba:	ec5e                	sd	s7,24(sp)
    80003dbc:	e862                	sd	s8,16(sp)
    80003dbe:	e466                	sd	s9,8(sp)
    80003dc0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003dc2:	00016797          	auipc	a5,0x16
    80003dc6:	dba7a783          	lw	a5,-582(a5) # 80019b7c <sb+0x4>
    80003dca:	cbd1                	beqz	a5,80003e5e <balloc+0xb6>
    80003dcc:	8baa                	mv	s7,a0
    80003dce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003dd0:	00016b17          	auipc	s6,0x16
    80003dd4:	da8b0b13          	addi	s6,s6,-600 # 80019b78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dd8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003dda:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ddc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003dde:	6c89                	lui	s9,0x2
    80003de0:	a831                	j	80003dfc <balloc+0x54>
    brelse(bp);
    80003de2:	854a                	mv	a0,s2
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	e32080e7          	jalr	-462(ra) # 80003c16 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003dec:	015c87bb          	addw	a5,s9,s5
    80003df0:	00078a9b          	sext.w	s5,a5
    80003df4:	004b2703          	lw	a4,4(s6)
    80003df8:	06eaf363          	bgeu	s5,a4,80003e5e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003dfc:	41fad79b          	sraiw	a5,s5,0x1f
    80003e00:	0137d79b          	srliw	a5,a5,0x13
    80003e04:	015787bb          	addw	a5,a5,s5
    80003e08:	40d7d79b          	sraiw	a5,a5,0xd
    80003e0c:	01cb2583          	lw	a1,28(s6)
    80003e10:	9dbd                	addw	a1,a1,a5
    80003e12:	855e                	mv	a0,s7
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	cd2080e7          	jalr	-814(ra) # 80003ae6 <bread>
    80003e1c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e1e:	004b2503          	lw	a0,4(s6)
    80003e22:	000a849b          	sext.w	s1,s5
    80003e26:	8662                	mv	a2,s8
    80003e28:	faa4fde3          	bgeu	s1,a0,80003de2 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003e2c:	41f6579b          	sraiw	a5,a2,0x1f
    80003e30:	01d7d69b          	srliw	a3,a5,0x1d
    80003e34:	00c6873b          	addw	a4,a3,a2
    80003e38:	00777793          	andi	a5,a4,7
    80003e3c:	9f95                	subw	a5,a5,a3
    80003e3e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e42:	4037571b          	sraiw	a4,a4,0x3
    80003e46:	00e906b3          	add	a3,s2,a4
    80003e4a:	0586c683          	lbu	a3,88(a3)
    80003e4e:	00d7f5b3          	and	a1,a5,a3
    80003e52:	cd91                	beqz	a1,80003e6e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e54:	2605                	addiw	a2,a2,1
    80003e56:	2485                	addiw	s1,s1,1
    80003e58:	fd4618e3          	bne	a2,s4,80003e28 <balloc+0x80>
    80003e5c:	b759                	j	80003de2 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e5e:	00005517          	auipc	a0,0x5
    80003e62:	f3a50513          	addi	a0,a0,-198 # 80008d98 <syscalls+0x100>
    80003e66:	ffffc097          	auipc	ra,0xffffc
    80003e6a:	6d8080e7          	jalr	1752(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e6e:	974a                	add	a4,a4,s2
    80003e70:	8fd5                	or	a5,a5,a3
    80003e72:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e76:	854a                	mv	a0,s2
    80003e78:	00001097          	auipc	ra,0x1
    80003e7c:	01a080e7          	jalr	26(ra) # 80004e92 <log_write>
        brelse(bp);
    80003e80:	854a                	mv	a0,s2
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	d94080e7          	jalr	-620(ra) # 80003c16 <brelse>
  bp = bread(dev, bno);
    80003e8a:	85a6                	mv	a1,s1
    80003e8c:	855e                	mv	a0,s7
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	c58080e7          	jalr	-936(ra) # 80003ae6 <bread>
    80003e96:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e98:	40000613          	li	a2,1024
    80003e9c:	4581                	li	a1,0
    80003e9e:	05850513          	addi	a0,a0,88
    80003ea2:	ffffd097          	auipc	ra,0xffffd
    80003ea6:	e62080e7          	jalr	-414(ra) # 80000d04 <memset>
  log_write(bp);
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00001097          	auipc	ra,0x1
    80003eb0:	fe6080e7          	jalr	-26(ra) # 80004e92 <log_write>
  brelse(bp);
    80003eb4:	854a                	mv	a0,s2
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	d60080e7          	jalr	-672(ra) # 80003c16 <brelse>
}
    80003ebe:	8526                	mv	a0,s1
    80003ec0:	60e6                	ld	ra,88(sp)
    80003ec2:	6446                	ld	s0,80(sp)
    80003ec4:	64a6                	ld	s1,72(sp)
    80003ec6:	6906                	ld	s2,64(sp)
    80003ec8:	79e2                	ld	s3,56(sp)
    80003eca:	7a42                	ld	s4,48(sp)
    80003ecc:	7aa2                	ld	s5,40(sp)
    80003ece:	7b02                	ld	s6,32(sp)
    80003ed0:	6be2                	ld	s7,24(sp)
    80003ed2:	6c42                	ld	s8,16(sp)
    80003ed4:	6ca2                	ld	s9,8(sp)
    80003ed6:	6125                	addi	sp,sp,96
    80003ed8:	8082                	ret

0000000080003eda <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003eda:	7179                	addi	sp,sp,-48
    80003edc:	f406                	sd	ra,40(sp)
    80003ede:	f022                	sd	s0,32(sp)
    80003ee0:	ec26                	sd	s1,24(sp)
    80003ee2:	e84a                	sd	s2,16(sp)
    80003ee4:	e44e                	sd	s3,8(sp)
    80003ee6:	e052                	sd	s4,0(sp)
    80003ee8:	1800                	addi	s0,sp,48
    80003eea:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003eec:	47ad                	li	a5,11
    80003eee:	04b7fe63          	bgeu	a5,a1,80003f4a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ef2:	ff45849b          	addiw	s1,a1,-12
    80003ef6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003efa:	0ff00793          	li	a5,255
    80003efe:	0ae7e363          	bltu	a5,a4,80003fa4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003f02:	08052583          	lw	a1,128(a0)
    80003f06:	c5ad                	beqz	a1,80003f70 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003f08:	00092503          	lw	a0,0(s2)
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	bda080e7          	jalr	-1062(ra) # 80003ae6 <bread>
    80003f14:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003f16:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003f1a:	02049593          	slli	a1,s1,0x20
    80003f1e:	9181                	srli	a1,a1,0x20
    80003f20:	058a                	slli	a1,a1,0x2
    80003f22:	00b784b3          	add	s1,a5,a1
    80003f26:	0004a983          	lw	s3,0(s1)
    80003f2a:	04098d63          	beqz	s3,80003f84 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003f2e:	8552                	mv	a0,s4
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	ce6080e7          	jalr	-794(ra) # 80003c16 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f38:	854e                	mv	a0,s3
    80003f3a:	70a2                	ld	ra,40(sp)
    80003f3c:	7402                	ld	s0,32(sp)
    80003f3e:	64e2                	ld	s1,24(sp)
    80003f40:	6942                	ld	s2,16(sp)
    80003f42:	69a2                	ld	s3,8(sp)
    80003f44:	6a02                	ld	s4,0(sp)
    80003f46:	6145                	addi	sp,sp,48
    80003f48:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f4a:	02059493          	slli	s1,a1,0x20
    80003f4e:	9081                	srli	s1,s1,0x20
    80003f50:	048a                	slli	s1,s1,0x2
    80003f52:	94aa                	add	s1,s1,a0
    80003f54:	0504a983          	lw	s3,80(s1)
    80003f58:	fe0990e3          	bnez	s3,80003f38 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f5c:	4108                	lw	a0,0(a0)
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	e4a080e7          	jalr	-438(ra) # 80003da8 <balloc>
    80003f66:	0005099b          	sext.w	s3,a0
    80003f6a:	0534a823          	sw	s3,80(s1)
    80003f6e:	b7e9                	j	80003f38 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003f70:	4108                	lw	a0,0(a0)
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	e36080e7          	jalr	-458(ra) # 80003da8 <balloc>
    80003f7a:	0005059b          	sext.w	a1,a0
    80003f7e:	08b92023          	sw	a1,128(s2)
    80003f82:	b759                	j	80003f08 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003f84:	00092503          	lw	a0,0(s2)
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	e20080e7          	jalr	-480(ra) # 80003da8 <balloc>
    80003f90:	0005099b          	sext.w	s3,a0
    80003f94:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003f98:	8552                	mv	a0,s4
    80003f9a:	00001097          	auipc	ra,0x1
    80003f9e:	ef8080e7          	jalr	-264(ra) # 80004e92 <log_write>
    80003fa2:	b771                	j	80003f2e <bmap+0x54>
  panic("bmap: out of range");
    80003fa4:	00005517          	auipc	a0,0x5
    80003fa8:	e0c50513          	addi	a0,a0,-500 # 80008db0 <syscalls+0x118>
    80003fac:	ffffc097          	auipc	ra,0xffffc
    80003fb0:	592080e7          	jalr	1426(ra) # 8000053e <panic>

0000000080003fb4 <iget>:
{
    80003fb4:	7179                	addi	sp,sp,-48
    80003fb6:	f406                	sd	ra,40(sp)
    80003fb8:	f022                	sd	s0,32(sp)
    80003fba:	ec26                	sd	s1,24(sp)
    80003fbc:	e84a                	sd	s2,16(sp)
    80003fbe:	e44e                	sd	s3,8(sp)
    80003fc0:	e052                	sd	s4,0(sp)
    80003fc2:	1800                	addi	s0,sp,48
    80003fc4:	89aa                	mv	s3,a0
    80003fc6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003fc8:	00016517          	auipc	a0,0x16
    80003fcc:	bd050513          	addi	a0,a0,-1072 # 80019b98 <itable>
    80003fd0:	ffffd097          	auipc	ra,0xffffd
    80003fd4:	c14080e7          	jalr	-1004(ra) # 80000be4 <acquire>
  empty = 0;
    80003fd8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fda:	00016497          	auipc	s1,0x16
    80003fde:	bd648493          	addi	s1,s1,-1066 # 80019bb0 <itable+0x18>
    80003fe2:	00017697          	auipc	a3,0x17
    80003fe6:	65e68693          	addi	a3,a3,1630 # 8001b640 <log>
    80003fea:	a039                	j	80003ff8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fec:	02090b63          	beqz	s2,80004022 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ff0:	08848493          	addi	s1,s1,136
    80003ff4:	02d48a63          	beq	s1,a3,80004028 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ff8:	449c                	lw	a5,8(s1)
    80003ffa:	fef059e3          	blez	a5,80003fec <iget+0x38>
    80003ffe:	4098                	lw	a4,0(s1)
    80004000:	ff3716e3          	bne	a4,s3,80003fec <iget+0x38>
    80004004:	40d8                	lw	a4,4(s1)
    80004006:	ff4713e3          	bne	a4,s4,80003fec <iget+0x38>
      ip->ref++;
    8000400a:	2785                	addiw	a5,a5,1
    8000400c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000400e:	00016517          	auipc	a0,0x16
    80004012:	b8a50513          	addi	a0,a0,-1142 # 80019b98 <itable>
    80004016:	ffffd097          	auipc	ra,0xffffd
    8000401a:	c94080e7          	jalr	-876(ra) # 80000caa <release>
      return ip;
    8000401e:	8926                	mv	s2,s1
    80004020:	a03d                	j	8000404e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004022:	f7f9                	bnez	a5,80003ff0 <iget+0x3c>
    80004024:	8926                	mv	s2,s1
    80004026:	b7e9                	j	80003ff0 <iget+0x3c>
  if(empty == 0)
    80004028:	02090c63          	beqz	s2,80004060 <iget+0xac>
  ip->dev = dev;
    8000402c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004030:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004034:	4785                	li	a5,1
    80004036:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000403a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000403e:	00016517          	auipc	a0,0x16
    80004042:	b5a50513          	addi	a0,a0,-1190 # 80019b98 <itable>
    80004046:	ffffd097          	auipc	ra,0xffffd
    8000404a:	c64080e7          	jalr	-924(ra) # 80000caa <release>
}
    8000404e:	854a                	mv	a0,s2
    80004050:	70a2                	ld	ra,40(sp)
    80004052:	7402                	ld	s0,32(sp)
    80004054:	64e2                	ld	s1,24(sp)
    80004056:	6942                	ld	s2,16(sp)
    80004058:	69a2                	ld	s3,8(sp)
    8000405a:	6a02                	ld	s4,0(sp)
    8000405c:	6145                	addi	sp,sp,48
    8000405e:	8082                	ret
    panic("iget: no inodes");
    80004060:	00005517          	auipc	a0,0x5
    80004064:	d6850513          	addi	a0,a0,-664 # 80008dc8 <syscalls+0x130>
    80004068:	ffffc097          	auipc	ra,0xffffc
    8000406c:	4d6080e7          	jalr	1238(ra) # 8000053e <panic>

0000000080004070 <fsinit>:
fsinit(int dev) {
    80004070:	7179                	addi	sp,sp,-48
    80004072:	f406                	sd	ra,40(sp)
    80004074:	f022                	sd	s0,32(sp)
    80004076:	ec26                	sd	s1,24(sp)
    80004078:	e84a                	sd	s2,16(sp)
    8000407a:	e44e                	sd	s3,8(sp)
    8000407c:	1800                	addi	s0,sp,48
    8000407e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004080:	4585                	li	a1,1
    80004082:	00000097          	auipc	ra,0x0
    80004086:	a64080e7          	jalr	-1436(ra) # 80003ae6 <bread>
    8000408a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000408c:	00016997          	auipc	s3,0x16
    80004090:	aec98993          	addi	s3,s3,-1300 # 80019b78 <sb>
    80004094:	02000613          	li	a2,32
    80004098:	05850593          	addi	a1,a0,88
    8000409c:	854e                	mv	a0,s3
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	cc6080e7          	jalr	-826(ra) # 80000d64 <memmove>
  brelse(bp);
    800040a6:	8526                	mv	a0,s1
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	b6e080e7          	jalr	-1170(ra) # 80003c16 <brelse>
  if(sb.magic != FSMAGIC)
    800040b0:	0009a703          	lw	a4,0(s3)
    800040b4:	102037b7          	lui	a5,0x10203
    800040b8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800040bc:	02f71263          	bne	a4,a5,800040e0 <fsinit+0x70>
  initlog(dev, &sb);
    800040c0:	00016597          	auipc	a1,0x16
    800040c4:	ab858593          	addi	a1,a1,-1352 # 80019b78 <sb>
    800040c8:	854a                	mv	a0,s2
    800040ca:	00001097          	auipc	ra,0x1
    800040ce:	b4c080e7          	jalr	-1204(ra) # 80004c16 <initlog>
}
    800040d2:	70a2                	ld	ra,40(sp)
    800040d4:	7402                	ld	s0,32(sp)
    800040d6:	64e2                	ld	s1,24(sp)
    800040d8:	6942                	ld	s2,16(sp)
    800040da:	69a2                	ld	s3,8(sp)
    800040dc:	6145                	addi	sp,sp,48
    800040de:	8082                	ret
    panic("invalid file system");
    800040e0:	00005517          	auipc	a0,0x5
    800040e4:	cf850513          	addi	a0,a0,-776 # 80008dd8 <syscalls+0x140>
    800040e8:	ffffc097          	auipc	ra,0xffffc
    800040ec:	456080e7          	jalr	1110(ra) # 8000053e <panic>

00000000800040f0 <iinit>:
{
    800040f0:	7179                	addi	sp,sp,-48
    800040f2:	f406                	sd	ra,40(sp)
    800040f4:	f022                	sd	s0,32(sp)
    800040f6:	ec26                	sd	s1,24(sp)
    800040f8:	e84a                	sd	s2,16(sp)
    800040fa:	e44e                	sd	s3,8(sp)
    800040fc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800040fe:	00005597          	auipc	a1,0x5
    80004102:	cf258593          	addi	a1,a1,-782 # 80008df0 <syscalls+0x158>
    80004106:	00016517          	auipc	a0,0x16
    8000410a:	a9250513          	addi	a0,a0,-1390 # 80019b98 <itable>
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	a46080e7          	jalr	-1466(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004116:	00016497          	auipc	s1,0x16
    8000411a:	aaa48493          	addi	s1,s1,-1366 # 80019bc0 <itable+0x28>
    8000411e:	00017997          	auipc	s3,0x17
    80004122:	53298993          	addi	s3,s3,1330 # 8001b650 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004126:	00005917          	auipc	s2,0x5
    8000412a:	cd290913          	addi	s2,s2,-814 # 80008df8 <syscalls+0x160>
    8000412e:	85ca                	mv	a1,s2
    80004130:	8526                	mv	a0,s1
    80004132:	00001097          	auipc	ra,0x1
    80004136:	e46080e7          	jalr	-442(ra) # 80004f78 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000413a:	08848493          	addi	s1,s1,136
    8000413e:	ff3498e3          	bne	s1,s3,8000412e <iinit+0x3e>
}
    80004142:	70a2                	ld	ra,40(sp)
    80004144:	7402                	ld	s0,32(sp)
    80004146:	64e2                	ld	s1,24(sp)
    80004148:	6942                	ld	s2,16(sp)
    8000414a:	69a2                	ld	s3,8(sp)
    8000414c:	6145                	addi	sp,sp,48
    8000414e:	8082                	ret

0000000080004150 <ialloc>:
{
    80004150:	715d                	addi	sp,sp,-80
    80004152:	e486                	sd	ra,72(sp)
    80004154:	e0a2                	sd	s0,64(sp)
    80004156:	fc26                	sd	s1,56(sp)
    80004158:	f84a                	sd	s2,48(sp)
    8000415a:	f44e                	sd	s3,40(sp)
    8000415c:	f052                	sd	s4,32(sp)
    8000415e:	ec56                	sd	s5,24(sp)
    80004160:	e85a                	sd	s6,16(sp)
    80004162:	e45e                	sd	s7,8(sp)
    80004164:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004166:	00016717          	auipc	a4,0x16
    8000416a:	a1e72703          	lw	a4,-1506(a4) # 80019b84 <sb+0xc>
    8000416e:	4785                	li	a5,1
    80004170:	04e7fa63          	bgeu	a5,a4,800041c4 <ialloc+0x74>
    80004174:	8aaa                	mv	s5,a0
    80004176:	8bae                	mv	s7,a1
    80004178:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000417a:	00016a17          	auipc	s4,0x16
    8000417e:	9fea0a13          	addi	s4,s4,-1538 # 80019b78 <sb>
    80004182:	00048b1b          	sext.w	s6,s1
    80004186:	0044d593          	srli	a1,s1,0x4
    8000418a:	018a2783          	lw	a5,24(s4)
    8000418e:	9dbd                	addw	a1,a1,a5
    80004190:	8556                	mv	a0,s5
    80004192:	00000097          	auipc	ra,0x0
    80004196:	954080e7          	jalr	-1708(ra) # 80003ae6 <bread>
    8000419a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000419c:	05850993          	addi	s3,a0,88
    800041a0:	00f4f793          	andi	a5,s1,15
    800041a4:	079a                	slli	a5,a5,0x6
    800041a6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800041a8:	00099783          	lh	a5,0(s3)
    800041ac:	c785                	beqz	a5,800041d4 <ialloc+0x84>
    brelse(bp);
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	a68080e7          	jalr	-1432(ra) # 80003c16 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800041b6:	0485                	addi	s1,s1,1
    800041b8:	00ca2703          	lw	a4,12(s4)
    800041bc:	0004879b          	sext.w	a5,s1
    800041c0:	fce7e1e3          	bltu	a5,a4,80004182 <ialloc+0x32>
  panic("ialloc: no inodes");
    800041c4:	00005517          	auipc	a0,0x5
    800041c8:	c3c50513          	addi	a0,a0,-964 # 80008e00 <syscalls+0x168>
    800041cc:	ffffc097          	auipc	ra,0xffffc
    800041d0:	372080e7          	jalr	882(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800041d4:	04000613          	li	a2,64
    800041d8:	4581                	li	a1,0
    800041da:	854e                	mv	a0,s3
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	b28080e7          	jalr	-1240(ra) # 80000d04 <memset>
      dip->type = type;
    800041e4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800041e8:	854a                	mv	a0,s2
    800041ea:	00001097          	auipc	ra,0x1
    800041ee:	ca8080e7          	jalr	-856(ra) # 80004e92 <log_write>
      brelse(bp);
    800041f2:	854a                	mv	a0,s2
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	a22080e7          	jalr	-1502(ra) # 80003c16 <brelse>
      return iget(dev, inum);
    800041fc:	85da                	mv	a1,s6
    800041fe:	8556                	mv	a0,s5
    80004200:	00000097          	auipc	ra,0x0
    80004204:	db4080e7          	jalr	-588(ra) # 80003fb4 <iget>
}
    80004208:	60a6                	ld	ra,72(sp)
    8000420a:	6406                	ld	s0,64(sp)
    8000420c:	74e2                	ld	s1,56(sp)
    8000420e:	7942                	ld	s2,48(sp)
    80004210:	79a2                	ld	s3,40(sp)
    80004212:	7a02                	ld	s4,32(sp)
    80004214:	6ae2                	ld	s5,24(sp)
    80004216:	6b42                	ld	s6,16(sp)
    80004218:	6ba2                	ld	s7,8(sp)
    8000421a:	6161                	addi	sp,sp,80
    8000421c:	8082                	ret

000000008000421e <iupdate>:
{
    8000421e:	1101                	addi	sp,sp,-32
    80004220:	ec06                	sd	ra,24(sp)
    80004222:	e822                	sd	s0,16(sp)
    80004224:	e426                	sd	s1,8(sp)
    80004226:	e04a                	sd	s2,0(sp)
    80004228:	1000                	addi	s0,sp,32
    8000422a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000422c:	415c                	lw	a5,4(a0)
    8000422e:	0047d79b          	srliw	a5,a5,0x4
    80004232:	00016597          	auipc	a1,0x16
    80004236:	95e5a583          	lw	a1,-1698(a1) # 80019b90 <sb+0x18>
    8000423a:	9dbd                	addw	a1,a1,a5
    8000423c:	4108                	lw	a0,0(a0)
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	8a8080e7          	jalr	-1880(ra) # 80003ae6 <bread>
    80004246:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004248:	05850793          	addi	a5,a0,88
    8000424c:	40c8                	lw	a0,4(s1)
    8000424e:	893d                	andi	a0,a0,15
    80004250:	051a                	slli	a0,a0,0x6
    80004252:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004254:	04449703          	lh	a4,68(s1)
    80004258:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000425c:	04649703          	lh	a4,70(s1)
    80004260:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004264:	04849703          	lh	a4,72(s1)
    80004268:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000426c:	04a49703          	lh	a4,74(s1)
    80004270:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004274:	44f8                	lw	a4,76(s1)
    80004276:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004278:	03400613          	li	a2,52
    8000427c:	05048593          	addi	a1,s1,80
    80004280:	0531                	addi	a0,a0,12
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	ae2080e7          	jalr	-1310(ra) # 80000d64 <memmove>
  log_write(bp);
    8000428a:	854a                	mv	a0,s2
    8000428c:	00001097          	auipc	ra,0x1
    80004290:	c06080e7          	jalr	-1018(ra) # 80004e92 <log_write>
  brelse(bp);
    80004294:	854a                	mv	a0,s2
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	980080e7          	jalr	-1664(ra) # 80003c16 <brelse>
}
    8000429e:	60e2                	ld	ra,24(sp)
    800042a0:	6442                	ld	s0,16(sp)
    800042a2:	64a2                	ld	s1,8(sp)
    800042a4:	6902                	ld	s2,0(sp)
    800042a6:	6105                	addi	sp,sp,32
    800042a8:	8082                	ret

00000000800042aa <idup>:
{
    800042aa:	1101                	addi	sp,sp,-32
    800042ac:	ec06                	sd	ra,24(sp)
    800042ae:	e822                	sd	s0,16(sp)
    800042b0:	e426                	sd	s1,8(sp)
    800042b2:	1000                	addi	s0,sp,32
    800042b4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042b6:	00016517          	auipc	a0,0x16
    800042ba:	8e250513          	addi	a0,a0,-1822 # 80019b98 <itable>
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  ip->ref++;
    800042c6:	449c                	lw	a5,8(s1)
    800042c8:	2785                	addiw	a5,a5,1
    800042ca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042cc:	00016517          	auipc	a0,0x16
    800042d0:	8cc50513          	addi	a0,a0,-1844 # 80019b98 <itable>
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	9d6080e7          	jalr	-1578(ra) # 80000caa <release>
}
    800042dc:	8526                	mv	a0,s1
    800042de:	60e2                	ld	ra,24(sp)
    800042e0:	6442                	ld	s0,16(sp)
    800042e2:	64a2                	ld	s1,8(sp)
    800042e4:	6105                	addi	sp,sp,32
    800042e6:	8082                	ret

00000000800042e8 <ilock>:
{
    800042e8:	1101                	addi	sp,sp,-32
    800042ea:	ec06                	sd	ra,24(sp)
    800042ec:	e822                	sd	s0,16(sp)
    800042ee:	e426                	sd	s1,8(sp)
    800042f0:	e04a                	sd	s2,0(sp)
    800042f2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800042f4:	c115                	beqz	a0,80004318 <ilock+0x30>
    800042f6:	84aa                	mv	s1,a0
    800042f8:	451c                	lw	a5,8(a0)
    800042fa:	00f05f63          	blez	a5,80004318 <ilock+0x30>
  acquiresleep(&ip->lock);
    800042fe:	0541                	addi	a0,a0,16
    80004300:	00001097          	auipc	ra,0x1
    80004304:	cb2080e7          	jalr	-846(ra) # 80004fb2 <acquiresleep>
  if(ip->valid == 0){
    80004308:	40bc                	lw	a5,64(s1)
    8000430a:	cf99                	beqz	a5,80004328 <ilock+0x40>
}
    8000430c:	60e2                	ld	ra,24(sp)
    8000430e:	6442                	ld	s0,16(sp)
    80004310:	64a2                	ld	s1,8(sp)
    80004312:	6902                	ld	s2,0(sp)
    80004314:	6105                	addi	sp,sp,32
    80004316:	8082                	ret
    panic("ilock");
    80004318:	00005517          	auipc	a0,0x5
    8000431c:	b0050513          	addi	a0,a0,-1280 # 80008e18 <syscalls+0x180>
    80004320:	ffffc097          	auipc	ra,0xffffc
    80004324:	21e080e7          	jalr	542(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004328:	40dc                	lw	a5,4(s1)
    8000432a:	0047d79b          	srliw	a5,a5,0x4
    8000432e:	00016597          	auipc	a1,0x16
    80004332:	8625a583          	lw	a1,-1950(a1) # 80019b90 <sb+0x18>
    80004336:	9dbd                	addw	a1,a1,a5
    80004338:	4088                	lw	a0,0(s1)
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	7ac080e7          	jalr	1964(ra) # 80003ae6 <bread>
    80004342:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004344:	05850593          	addi	a1,a0,88
    80004348:	40dc                	lw	a5,4(s1)
    8000434a:	8bbd                	andi	a5,a5,15
    8000434c:	079a                	slli	a5,a5,0x6
    8000434e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004350:	00059783          	lh	a5,0(a1)
    80004354:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004358:	00259783          	lh	a5,2(a1)
    8000435c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004360:	00459783          	lh	a5,4(a1)
    80004364:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004368:	00659783          	lh	a5,6(a1)
    8000436c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004370:	459c                	lw	a5,8(a1)
    80004372:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004374:	03400613          	li	a2,52
    80004378:	05b1                	addi	a1,a1,12
    8000437a:	05048513          	addi	a0,s1,80
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	9e6080e7          	jalr	-1562(ra) # 80000d64 <memmove>
    brelse(bp);
    80004386:	854a                	mv	a0,s2
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	88e080e7          	jalr	-1906(ra) # 80003c16 <brelse>
    ip->valid = 1;
    80004390:	4785                	li	a5,1
    80004392:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004394:	04449783          	lh	a5,68(s1)
    80004398:	fbb5                	bnez	a5,8000430c <ilock+0x24>
      panic("ilock: no type");
    8000439a:	00005517          	auipc	a0,0x5
    8000439e:	a8650513          	addi	a0,a0,-1402 # 80008e20 <syscalls+0x188>
    800043a2:	ffffc097          	auipc	ra,0xffffc
    800043a6:	19c080e7          	jalr	412(ra) # 8000053e <panic>

00000000800043aa <iunlock>:
{
    800043aa:	1101                	addi	sp,sp,-32
    800043ac:	ec06                	sd	ra,24(sp)
    800043ae:	e822                	sd	s0,16(sp)
    800043b0:	e426                	sd	s1,8(sp)
    800043b2:	e04a                	sd	s2,0(sp)
    800043b4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800043b6:	c905                	beqz	a0,800043e6 <iunlock+0x3c>
    800043b8:	84aa                	mv	s1,a0
    800043ba:	01050913          	addi	s2,a0,16
    800043be:	854a                	mv	a0,s2
    800043c0:	00001097          	auipc	ra,0x1
    800043c4:	c8c080e7          	jalr	-884(ra) # 8000504c <holdingsleep>
    800043c8:	cd19                	beqz	a0,800043e6 <iunlock+0x3c>
    800043ca:	449c                	lw	a5,8(s1)
    800043cc:	00f05d63          	blez	a5,800043e6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800043d0:	854a                	mv	a0,s2
    800043d2:	00001097          	auipc	ra,0x1
    800043d6:	c36080e7          	jalr	-970(ra) # 80005008 <releasesleep>
}
    800043da:	60e2                	ld	ra,24(sp)
    800043dc:	6442                	ld	s0,16(sp)
    800043de:	64a2                	ld	s1,8(sp)
    800043e0:	6902                	ld	s2,0(sp)
    800043e2:	6105                	addi	sp,sp,32
    800043e4:	8082                	ret
    panic("iunlock");
    800043e6:	00005517          	auipc	a0,0x5
    800043ea:	a4a50513          	addi	a0,a0,-1462 # 80008e30 <syscalls+0x198>
    800043ee:	ffffc097          	auipc	ra,0xffffc
    800043f2:	150080e7          	jalr	336(ra) # 8000053e <panic>

00000000800043f6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800043f6:	7179                	addi	sp,sp,-48
    800043f8:	f406                	sd	ra,40(sp)
    800043fa:	f022                	sd	s0,32(sp)
    800043fc:	ec26                	sd	s1,24(sp)
    800043fe:	e84a                	sd	s2,16(sp)
    80004400:	e44e                	sd	s3,8(sp)
    80004402:	e052                	sd	s4,0(sp)
    80004404:	1800                	addi	s0,sp,48
    80004406:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004408:	05050493          	addi	s1,a0,80
    8000440c:	08050913          	addi	s2,a0,128
    80004410:	a021                	j	80004418 <itrunc+0x22>
    80004412:	0491                	addi	s1,s1,4
    80004414:	01248d63          	beq	s1,s2,8000442e <itrunc+0x38>
    if(ip->addrs[i]){
    80004418:	408c                	lw	a1,0(s1)
    8000441a:	dde5                	beqz	a1,80004412 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000441c:	0009a503          	lw	a0,0(s3)
    80004420:	00000097          	auipc	ra,0x0
    80004424:	90c080e7          	jalr	-1780(ra) # 80003d2c <bfree>
      ip->addrs[i] = 0;
    80004428:	0004a023          	sw	zero,0(s1)
    8000442c:	b7dd                	j	80004412 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000442e:	0809a583          	lw	a1,128(s3)
    80004432:	e185                	bnez	a1,80004452 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004434:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004438:	854e                	mv	a0,s3
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	de4080e7          	jalr	-540(ra) # 8000421e <iupdate>
}
    80004442:	70a2                	ld	ra,40(sp)
    80004444:	7402                	ld	s0,32(sp)
    80004446:	64e2                	ld	s1,24(sp)
    80004448:	6942                	ld	s2,16(sp)
    8000444a:	69a2                	ld	s3,8(sp)
    8000444c:	6a02                	ld	s4,0(sp)
    8000444e:	6145                	addi	sp,sp,48
    80004450:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004452:	0009a503          	lw	a0,0(s3)
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	690080e7          	jalr	1680(ra) # 80003ae6 <bread>
    8000445e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004460:	05850493          	addi	s1,a0,88
    80004464:	45850913          	addi	s2,a0,1112
    80004468:	a811                	j	8000447c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000446a:	0009a503          	lw	a0,0(s3)
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	8be080e7          	jalr	-1858(ra) # 80003d2c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004476:	0491                	addi	s1,s1,4
    80004478:	01248563          	beq	s1,s2,80004482 <itrunc+0x8c>
      if(a[j])
    8000447c:	408c                	lw	a1,0(s1)
    8000447e:	dde5                	beqz	a1,80004476 <itrunc+0x80>
    80004480:	b7ed                	j	8000446a <itrunc+0x74>
    brelse(bp);
    80004482:	8552                	mv	a0,s4
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	792080e7          	jalr	1938(ra) # 80003c16 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000448c:	0809a583          	lw	a1,128(s3)
    80004490:	0009a503          	lw	a0,0(s3)
    80004494:	00000097          	auipc	ra,0x0
    80004498:	898080e7          	jalr	-1896(ra) # 80003d2c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000449c:	0809a023          	sw	zero,128(s3)
    800044a0:	bf51                	j	80004434 <itrunc+0x3e>

00000000800044a2 <iput>:
{
    800044a2:	1101                	addi	sp,sp,-32
    800044a4:	ec06                	sd	ra,24(sp)
    800044a6:	e822                	sd	s0,16(sp)
    800044a8:	e426                	sd	s1,8(sp)
    800044aa:	e04a                	sd	s2,0(sp)
    800044ac:	1000                	addi	s0,sp,32
    800044ae:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800044b0:	00015517          	auipc	a0,0x15
    800044b4:	6e850513          	addi	a0,a0,1768 # 80019b98 <itable>
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	72c080e7          	jalr	1836(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044c0:	4498                	lw	a4,8(s1)
    800044c2:	4785                	li	a5,1
    800044c4:	02f70363          	beq	a4,a5,800044ea <iput+0x48>
  ip->ref--;
    800044c8:	449c                	lw	a5,8(s1)
    800044ca:	37fd                	addiw	a5,a5,-1
    800044cc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044ce:	00015517          	auipc	a0,0x15
    800044d2:	6ca50513          	addi	a0,a0,1738 # 80019b98 <itable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7d4080e7          	jalr	2004(ra) # 80000caa <release>
}
    800044de:	60e2                	ld	ra,24(sp)
    800044e0:	6442                	ld	s0,16(sp)
    800044e2:	64a2                	ld	s1,8(sp)
    800044e4:	6902                	ld	s2,0(sp)
    800044e6:	6105                	addi	sp,sp,32
    800044e8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044ea:	40bc                	lw	a5,64(s1)
    800044ec:	dff1                	beqz	a5,800044c8 <iput+0x26>
    800044ee:	04a49783          	lh	a5,74(s1)
    800044f2:	fbf9                	bnez	a5,800044c8 <iput+0x26>
    acquiresleep(&ip->lock);
    800044f4:	01048913          	addi	s2,s1,16
    800044f8:	854a                	mv	a0,s2
    800044fa:	00001097          	auipc	ra,0x1
    800044fe:	ab8080e7          	jalr	-1352(ra) # 80004fb2 <acquiresleep>
    release(&itable.lock);
    80004502:	00015517          	auipc	a0,0x15
    80004506:	69650513          	addi	a0,a0,1686 # 80019b98 <itable>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	7a0080e7          	jalr	1952(ra) # 80000caa <release>
    itrunc(ip);
    80004512:	8526                	mv	a0,s1
    80004514:	00000097          	auipc	ra,0x0
    80004518:	ee2080e7          	jalr	-286(ra) # 800043f6 <itrunc>
    ip->type = 0;
    8000451c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004520:	8526                	mv	a0,s1
    80004522:	00000097          	auipc	ra,0x0
    80004526:	cfc080e7          	jalr	-772(ra) # 8000421e <iupdate>
    ip->valid = 0;
    8000452a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000452e:	854a                	mv	a0,s2
    80004530:	00001097          	auipc	ra,0x1
    80004534:	ad8080e7          	jalr	-1320(ra) # 80005008 <releasesleep>
    acquire(&itable.lock);
    80004538:	00015517          	auipc	a0,0x15
    8000453c:	66050513          	addi	a0,a0,1632 # 80019b98 <itable>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	6a4080e7          	jalr	1700(ra) # 80000be4 <acquire>
    80004548:	b741                	j	800044c8 <iput+0x26>

000000008000454a <iunlockput>:
{
    8000454a:	1101                	addi	sp,sp,-32
    8000454c:	ec06                	sd	ra,24(sp)
    8000454e:	e822                	sd	s0,16(sp)
    80004550:	e426                	sd	s1,8(sp)
    80004552:	1000                	addi	s0,sp,32
    80004554:	84aa                	mv	s1,a0
  iunlock(ip);
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	e54080e7          	jalr	-428(ra) # 800043aa <iunlock>
  iput(ip);
    8000455e:	8526                	mv	a0,s1
    80004560:	00000097          	auipc	ra,0x0
    80004564:	f42080e7          	jalr	-190(ra) # 800044a2 <iput>
}
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004572:	1141                	addi	sp,sp,-16
    80004574:	e422                	sd	s0,8(sp)
    80004576:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004578:	411c                	lw	a5,0(a0)
    8000457a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000457c:	415c                	lw	a5,4(a0)
    8000457e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004580:	04451783          	lh	a5,68(a0)
    80004584:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004588:	04a51783          	lh	a5,74(a0)
    8000458c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004590:	04c56783          	lwu	a5,76(a0)
    80004594:	e99c                	sd	a5,16(a1)
}
    80004596:	6422                	ld	s0,8(sp)
    80004598:	0141                	addi	sp,sp,16
    8000459a:	8082                	ret

000000008000459c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000459c:	457c                	lw	a5,76(a0)
    8000459e:	0ed7e963          	bltu	a5,a3,80004690 <readi+0xf4>
{
    800045a2:	7159                	addi	sp,sp,-112
    800045a4:	f486                	sd	ra,104(sp)
    800045a6:	f0a2                	sd	s0,96(sp)
    800045a8:	eca6                	sd	s1,88(sp)
    800045aa:	e8ca                	sd	s2,80(sp)
    800045ac:	e4ce                	sd	s3,72(sp)
    800045ae:	e0d2                	sd	s4,64(sp)
    800045b0:	fc56                	sd	s5,56(sp)
    800045b2:	f85a                	sd	s6,48(sp)
    800045b4:	f45e                	sd	s7,40(sp)
    800045b6:	f062                	sd	s8,32(sp)
    800045b8:	ec66                	sd	s9,24(sp)
    800045ba:	e86a                	sd	s10,16(sp)
    800045bc:	e46e                	sd	s11,8(sp)
    800045be:	1880                	addi	s0,sp,112
    800045c0:	8baa                	mv	s7,a0
    800045c2:	8c2e                	mv	s8,a1
    800045c4:	8ab2                	mv	s5,a2
    800045c6:	84b6                	mv	s1,a3
    800045c8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800045ca:	9f35                	addw	a4,a4,a3
    return 0;
    800045cc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800045ce:	0ad76063          	bltu	a4,a3,8000466e <readi+0xd2>
  if(off + n > ip->size)
    800045d2:	00e7f463          	bgeu	a5,a4,800045da <readi+0x3e>
    n = ip->size - off;
    800045d6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045da:	0a0b0963          	beqz	s6,8000468c <readi+0xf0>
    800045de:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800045e0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800045e4:	5cfd                	li	s9,-1
    800045e6:	a82d                	j	80004620 <readi+0x84>
    800045e8:	020a1d93          	slli	s11,s4,0x20
    800045ec:	020ddd93          	srli	s11,s11,0x20
    800045f0:	05890613          	addi	a2,s2,88
    800045f4:	86ee                	mv	a3,s11
    800045f6:	963a                	add	a2,a2,a4
    800045f8:	85d6                	mv	a1,s5
    800045fa:	8562                	mv	a0,s8
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	ac0080e7          	jalr	-1344(ra) # 800030bc <either_copyout>
    80004604:	05950d63          	beq	a0,s9,8000465e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004608:	854a                	mv	a0,s2
    8000460a:	fffff097          	auipc	ra,0xfffff
    8000460e:	60c080e7          	jalr	1548(ra) # 80003c16 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004612:	013a09bb          	addw	s3,s4,s3
    80004616:	009a04bb          	addw	s1,s4,s1
    8000461a:	9aee                	add	s5,s5,s11
    8000461c:	0569f763          	bgeu	s3,s6,8000466a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004620:	000ba903          	lw	s2,0(s7)
    80004624:	00a4d59b          	srliw	a1,s1,0xa
    80004628:	855e                	mv	a0,s7
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	8b0080e7          	jalr	-1872(ra) # 80003eda <bmap>
    80004632:	0005059b          	sext.w	a1,a0
    80004636:	854a                	mv	a0,s2
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	4ae080e7          	jalr	1198(ra) # 80003ae6 <bread>
    80004640:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004642:	3ff4f713          	andi	a4,s1,1023
    80004646:	40ed07bb          	subw	a5,s10,a4
    8000464a:	413b06bb          	subw	a3,s6,s3
    8000464e:	8a3e                	mv	s4,a5
    80004650:	2781                	sext.w	a5,a5
    80004652:	0006861b          	sext.w	a2,a3
    80004656:	f8f679e3          	bgeu	a2,a5,800045e8 <readi+0x4c>
    8000465a:	8a36                	mv	s4,a3
    8000465c:	b771                	j	800045e8 <readi+0x4c>
      brelse(bp);
    8000465e:	854a                	mv	a0,s2
    80004660:	fffff097          	auipc	ra,0xfffff
    80004664:	5b6080e7          	jalr	1462(ra) # 80003c16 <brelse>
      tot = -1;
    80004668:	59fd                	li	s3,-1
  }
  return tot;
    8000466a:	0009851b          	sext.w	a0,s3
}
    8000466e:	70a6                	ld	ra,104(sp)
    80004670:	7406                	ld	s0,96(sp)
    80004672:	64e6                	ld	s1,88(sp)
    80004674:	6946                	ld	s2,80(sp)
    80004676:	69a6                	ld	s3,72(sp)
    80004678:	6a06                	ld	s4,64(sp)
    8000467a:	7ae2                	ld	s5,56(sp)
    8000467c:	7b42                	ld	s6,48(sp)
    8000467e:	7ba2                	ld	s7,40(sp)
    80004680:	7c02                	ld	s8,32(sp)
    80004682:	6ce2                	ld	s9,24(sp)
    80004684:	6d42                	ld	s10,16(sp)
    80004686:	6da2                	ld	s11,8(sp)
    80004688:	6165                	addi	sp,sp,112
    8000468a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000468c:	89da                	mv	s3,s6
    8000468e:	bff1                	j	8000466a <readi+0xce>
    return 0;
    80004690:	4501                	li	a0,0
}
    80004692:	8082                	ret

0000000080004694 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004694:	457c                	lw	a5,76(a0)
    80004696:	10d7e863          	bltu	a5,a3,800047a6 <writei+0x112>
{
    8000469a:	7159                	addi	sp,sp,-112
    8000469c:	f486                	sd	ra,104(sp)
    8000469e:	f0a2                	sd	s0,96(sp)
    800046a0:	eca6                	sd	s1,88(sp)
    800046a2:	e8ca                	sd	s2,80(sp)
    800046a4:	e4ce                	sd	s3,72(sp)
    800046a6:	e0d2                	sd	s4,64(sp)
    800046a8:	fc56                	sd	s5,56(sp)
    800046aa:	f85a                	sd	s6,48(sp)
    800046ac:	f45e                	sd	s7,40(sp)
    800046ae:	f062                	sd	s8,32(sp)
    800046b0:	ec66                	sd	s9,24(sp)
    800046b2:	e86a                	sd	s10,16(sp)
    800046b4:	e46e                	sd	s11,8(sp)
    800046b6:	1880                	addi	s0,sp,112
    800046b8:	8b2a                	mv	s6,a0
    800046ba:	8c2e                	mv	s8,a1
    800046bc:	8ab2                	mv	s5,a2
    800046be:	8936                	mv	s2,a3
    800046c0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800046c2:	00e687bb          	addw	a5,a3,a4
    800046c6:	0ed7e263          	bltu	a5,a3,800047aa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800046ca:	00043737          	lui	a4,0x43
    800046ce:	0ef76063          	bltu	a4,a5,800047ae <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046d2:	0c0b8863          	beqz	s7,800047a2 <writei+0x10e>
    800046d6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800046d8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800046dc:	5cfd                	li	s9,-1
    800046de:	a091                	j	80004722 <writei+0x8e>
    800046e0:	02099d93          	slli	s11,s3,0x20
    800046e4:	020ddd93          	srli	s11,s11,0x20
    800046e8:	05848513          	addi	a0,s1,88
    800046ec:	86ee                	mv	a3,s11
    800046ee:	8656                	mv	a2,s5
    800046f0:	85e2                	mv	a1,s8
    800046f2:	953a                	add	a0,a0,a4
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	a1e080e7          	jalr	-1506(ra) # 80003112 <either_copyin>
    800046fc:	07950263          	beq	a0,s9,80004760 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004700:	8526                	mv	a0,s1
    80004702:	00000097          	auipc	ra,0x0
    80004706:	790080e7          	jalr	1936(ra) # 80004e92 <log_write>
    brelse(bp);
    8000470a:	8526                	mv	a0,s1
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	50a080e7          	jalr	1290(ra) # 80003c16 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004714:	01498a3b          	addw	s4,s3,s4
    80004718:	0129893b          	addw	s2,s3,s2
    8000471c:	9aee                	add	s5,s5,s11
    8000471e:	057a7663          	bgeu	s4,s7,8000476a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004722:	000b2483          	lw	s1,0(s6)
    80004726:	00a9559b          	srliw	a1,s2,0xa
    8000472a:	855a                	mv	a0,s6
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	7ae080e7          	jalr	1966(ra) # 80003eda <bmap>
    80004734:	0005059b          	sext.w	a1,a0
    80004738:	8526                	mv	a0,s1
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	3ac080e7          	jalr	940(ra) # 80003ae6 <bread>
    80004742:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004744:	3ff97713          	andi	a4,s2,1023
    80004748:	40ed07bb          	subw	a5,s10,a4
    8000474c:	414b86bb          	subw	a3,s7,s4
    80004750:	89be                	mv	s3,a5
    80004752:	2781                	sext.w	a5,a5
    80004754:	0006861b          	sext.w	a2,a3
    80004758:	f8f674e3          	bgeu	a2,a5,800046e0 <writei+0x4c>
    8000475c:	89b6                	mv	s3,a3
    8000475e:	b749                	j	800046e0 <writei+0x4c>
      brelse(bp);
    80004760:	8526                	mv	a0,s1
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	4b4080e7          	jalr	1204(ra) # 80003c16 <brelse>
  }

  if(off > ip->size)
    8000476a:	04cb2783          	lw	a5,76(s6)
    8000476e:	0127f463          	bgeu	a5,s2,80004776 <writei+0xe2>
    ip->size = off;
    80004772:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004776:	855a                	mv	a0,s6
    80004778:	00000097          	auipc	ra,0x0
    8000477c:	aa6080e7          	jalr	-1370(ra) # 8000421e <iupdate>

  return tot;
    80004780:	000a051b          	sext.w	a0,s4
}
    80004784:	70a6                	ld	ra,104(sp)
    80004786:	7406                	ld	s0,96(sp)
    80004788:	64e6                	ld	s1,88(sp)
    8000478a:	6946                	ld	s2,80(sp)
    8000478c:	69a6                	ld	s3,72(sp)
    8000478e:	6a06                	ld	s4,64(sp)
    80004790:	7ae2                	ld	s5,56(sp)
    80004792:	7b42                	ld	s6,48(sp)
    80004794:	7ba2                	ld	s7,40(sp)
    80004796:	7c02                	ld	s8,32(sp)
    80004798:	6ce2                	ld	s9,24(sp)
    8000479a:	6d42                	ld	s10,16(sp)
    8000479c:	6da2                	ld	s11,8(sp)
    8000479e:	6165                	addi	sp,sp,112
    800047a0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047a2:	8a5e                	mv	s4,s7
    800047a4:	bfc9                	j	80004776 <writei+0xe2>
    return -1;
    800047a6:	557d                	li	a0,-1
}
    800047a8:	8082                	ret
    return -1;
    800047aa:	557d                	li	a0,-1
    800047ac:	bfe1                	j	80004784 <writei+0xf0>
    return -1;
    800047ae:	557d                	li	a0,-1
    800047b0:	bfd1                	j	80004784 <writei+0xf0>

00000000800047b2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800047b2:	1141                	addi	sp,sp,-16
    800047b4:	e406                	sd	ra,8(sp)
    800047b6:	e022                	sd	s0,0(sp)
    800047b8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800047ba:	4639                	li	a2,14
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	620080e7          	jalr	1568(ra) # 80000ddc <strncmp>
}
    800047c4:	60a2                	ld	ra,8(sp)
    800047c6:	6402                	ld	s0,0(sp)
    800047c8:	0141                	addi	sp,sp,16
    800047ca:	8082                	ret

00000000800047cc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800047cc:	7139                	addi	sp,sp,-64
    800047ce:	fc06                	sd	ra,56(sp)
    800047d0:	f822                	sd	s0,48(sp)
    800047d2:	f426                	sd	s1,40(sp)
    800047d4:	f04a                	sd	s2,32(sp)
    800047d6:	ec4e                	sd	s3,24(sp)
    800047d8:	e852                	sd	s4,16(sp)
    800047da:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800047dc:	04451703          	lh	a4,68(a0)
    800047e0:	4785                	li	a5,1
    800047e2:	00f71a63          	bne	a4,a5,800047f6 <dirlookup+0x2a>
    800047e6:	892a                	mv	s2,a0
    800047e8:	89ae                	mv	s3,a1
    800047ea:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800047ec:	457c                	lw	a5,76(a0)
    800047ee:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800047f0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047f2:	e79d                	bnez	a5,80004820 <dirlookup+0x54>
    800047f4:	a8a5                	j	8000486c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800047f6:	00004517          	auipc	a0,0x4
    800047fa:	64250513          	addi	a0,a0,1602 # 80008e38 <syscalls+0x1a0>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	d40080e7          	jalr	-704(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004806:	00004517          	auipc	a0,0x4
    8000480a:	64a50513          	addi	a0,a0,1610 # 80008e50 <syscalls+0x1b8>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004816:	24c1                	addiw	s1,s1,16
    80004818:	04c92783          	lw	a5,76(s2)
    8000481c:	04f4f763          	bgeu	s1,a5,8000486a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004820:	4741                	li	a4,16
    80004822:	86a6                	mv	a3,s1
    80004824:	fc040613          	addi	a2,s0,-64
    80004828:	4581                	li	a1,0
    8000482a:	854a                	mv	a0,s2
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	d70080e7          	jalr	-656(ra) # 8000459c <readi>
    80004834:	47c1                	li	a5,16
    80004836:	fcf518e3          	bne	a0,a5,80004806 <dirlookup+0x3a>
    if(de.inum == 0)
    8000483a:	fc045783          	lhu	a5,-64(s0)
    8000483e:	dfe1                	beqz	a5,80004816 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004840:	fc240593          	addi	a1,s0,-62
    80004844:	854e                	mv	a0,s3
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	f6c080e7          	jalr	-148(ra) # 800047b2 <namecmp>
    8000484e:	f561                	bnez	a0,80004816 <dirlookup+0x4a>
      if(poff)
    80004850:	000a0463          	beqz	s4,80004858 <dirlookup+0x8c>
        *poff = off;
    80004854:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004858:	fc045583          	lhu	a1,-64(s0)
    8000485c:	00092503          	lw	a0,0(s2)
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	754080e7          	jalr	1876(ra) # 80003fb4 <iget>
    80004868:	a011                	j	8000486c <dirlookup+0xa0>
  return 0;
    8000486a:	4501                	li	a0,0
}
    8000486c:	70e2                	ld	ra,56(sp)
    8000486e:	7442                	ld	s0,48(sp)
    80004870:	74a2                	ld	s1,40(sp)
    80004872:	7902                	ld	s2,32(sp)
    80004874:	69e2                	ld	s3,24(sp)
    80004876:	6a42                	ld	s4,16(sp)
    80004878:	6121                	addi	sp,sp,64
    8000487a:	8082                	ret

000000008000487c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000487c:	711d                	addi	sp,sp,-96
    8000487e:	ec86                	sd	ra,88(sp)
    80004880:	e8a2                	sd	s0,80(sp)
    80004882:	e4a6                	sd	s1,72(sp)
    80004884:	e0ca                	sd	s2,64(sp)
    80004886:	fc4e                	sd	s3,56(sp)
    80004888:	f852                	sd	s4,48(sp)
    8000488a:	f456                	sd	s5,40(sp)
    8000488c:	f05a                	sd	s6,32(sp)
    8000488e:	ec5e                	sd	s7,24(sp)
    80004890:	e862                	sd	s8,16(sp)
    80004892:	e466                	sd	s9,8(sp)
    80004894:	1080                	addi	s0,sp,96
    80004896:	84aa                	mv	s1,a0
    80004898:	8b2e                	mv	s6,a1
    8000489a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000489c:	00054703          	lbu	a4,0(a0)
    800048a0:	02f00793          	li	a5,47
    800048a4:	02f70363          	beq	a4,a5,800048ca <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800048a8:	ffffd097          	auipc	ra,0xffffd
    800048ac:	61c080e7          	jalr	1564(ra) # 80001ec4 <myproc>
    800048b0:	17053503          	ld	a0,368(a0)
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	9f6080e7          	jalr	-1546(ra) # 800042aa <idup>
    800048bc:	89aa                	mv	s3,a0
  while(*path == '/')
    800048be:	02f00913          	li	s2,47
  len = path - s;
    800048c2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800048c4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800048c6:	4c05                	li	s8,1
    800048c8:	a865                	j	80004980 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800048ca:	4585                	li	a1,1
    800048cc:	4505                	li	a0,1
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	6e6080e7          	jalr	1766(ra) # 80003fb4 <iget>
    800048d6:	89aa                	mv	s3,a0
    800048d8:	b7dd                	j	800048be <namex+0x42>
      iunlockput(ip);
    800048da:	854e                	mv	a0,s3
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	c6e080e7          	jalr	-914(ra) # 8000454a <iunlockput>
      return 0;
    800048e4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800048e6:	854e                	mv	a0,s3
    800048e8:	60e6                	ld	ra,88(sp)
    800048ea:	6446                	ld	s0,80(sp)
    800048ec:	64a6                	ld	s1,72(sp)
    800048ee:	6906                	ld	s2,64(sp)
    800048f0:	79e2                	ld	s3,56(sp)
    800048f2:	7a42                	ld	s4,48(sp)
    800048f4:	7aa2                	ld	s5,40(sp)
    800048f6:	7b02                	ld	s6,32(sp)
    800048f8:	6be2                	ld	s7,24(sp)
    800048fa:	6c42                	ld	s8,16(sp)
    800048fc:	6ca2                	ld	s9,8(sp)
    800048fe:	6125                	addi	sp,sp,96
    80004900:	8082                	ret
      iunlock(ip);
    80004902:	854e                	mv	a0,s3
    80004904:	00000097          	auipc	ra,0x0
    80004908:	aa6080e7          	jalr	-1370(ra) # 800043aa <iunlock>
      return ip;
    8000490c:	bfe9                	j	800048e6 <namex+0x6a>
      iunlockput(ip);
    8000490e:	854e                	mv	a0,s3
    80004910:	00000097          	auipc	ra,0x0
    80004914:	c3a080e7          	jalr	-966(ra) # 8000454a <iunlockput>
      return 0;
    80004918:	89d2                	mv	s3,s4
    8000491a:	b7f1                	j	800048e6 <namex+0x6a>
  len = path - s;
    8000491c:	40b48633          	sub	a2,s1,a1
    80004920:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004924:	094cd463          	bge	s9,s4,800049ac <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004928:	4639                	li	a2,14
    8000492a:	8556                	mv	a0,s5
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	438080e7          	jalr	1080(ra) # 80000d64 <memmove>
  while(*path == '/')
    80004934:	0004c783          	lbu	a5,0(s1)
    80004938:	01279763          	bne	a5,s2,80004946 <namex+0xca>
    path++;
    8000493c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000493e:	0004c783          	lbu	a5,0(s1)
    80004942:	ff278de3          	beq	a5,s2,8000493c <namex+0xc0>
    ilock(ip);
    80004946:	854e                	mv	a0,s3
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	9a0080e7          	jalr	-1632(ra) # 800042e8 <ilock>
    if(ip->type != T_DIR){
    80004950:	04499783          	lh	a5,68(s3)
    80004954:	f98793e3          	bne	a5,s8,800048da <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004958:	000b0563          	beqz	s6,80004962 <namex+0xe6>
    8000495c:	0004c783          	lbu	a5,0(s1)
    80004960:	d3cd                	beqz	a5,80004902 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004962:	865e                	mv	a2,s7
    80004964:	85d6                	mv	a1,s5
    80004966:	854e                	mv	a0,s3
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	e64080e7          	jalr	-412(ra) # 800047cc <dirlookup>
    80004970:	8a2a                	mv	s4,a0
    80004972:	dd51                	beqz	a0,8000490e <namex+0x92>
    iunlockput(ip);
    80004974:	854e                	mv	a0,s3
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	bd4080e7          	jalr	-1068(ra) # 8000454a <iunlockput>
    ip = next;
    8000497e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004980:	0004c783          	lbu	a5,0(s1)
    80004984:	05279763          	bne	a5,s2,800049d2 <namex+0x156>
    path++;
    80004988:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000498a:	0004c783          	lbu	a5,0(s1)
    8000498e:	ff278de3          	beq	a5,s2,80004988 <namex+0x10c>
  if(*path == 0)
    80004992:	c79d                	beqz	a5,800049c0 <namex+0x144>
    path++;
    80004994:	85a6                	mv	a1,s1
  len = path - s;
    80004996:	8a5e                	mv	s4,s7
    80004998:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000499a:	01278963          	beq	a5,s2,800049ac <namex+0x130>
    8000499e:	dfbd                	beqz	a5,8000491c <namex+0xa0>
    path++;
    800049a0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800049a2:	0004c783          	lbu	a5,0(s1)
    800049a6:	ff279ce3          	bne	a5,s2,8000499e <namex+0x122>
    800049aa:	bf8d                	j	8000491c <namex+0xa0>
    memmove(name, s, len);
    800049ac:	2601                	sext.w	a2,a2
    800049ae:	8556                	mv	a0,s5
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	3b4080e7          	jalr	948(ra) # 80000d64 <memmove>
    name[len] = 0;
    800049b8:	9a56                	add	s4,s4,s5
    800049ba:	000a0023          	sb	zero,0(s4)
    800049be:	bf9d                	j	80004934 <namex+0xb8>
  if(nameiparent){
    800049c0:	f20b03e3          	beqz	s6,800048e6 <namex+0x6a>
    iput(ip);
    800049c4:	854e                	mv	a0,s3
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	adc080e7          	jalr	-1316(ra) # 800044a2 <iput>
    return 0;
    800049ce:	4981                	li	s3,0
    800049d0:	bf19                	j	800048e6 <namex+0x6a>
  if(*path == 0)
    800049d2:	d7fd                	beqz	a5,800049c0 <namex+0x144>
  while(*path != '/' && *path != 0)
    800049d4:	0004c783          	lbu	a5,0(s1)
    800049d8:	85a6                	mv	a1,s1
    800049da:	b7d1                	j	8000499e <namex+0x122>

00000000800049dc <dirlink>:
{
    800049dc:	7139                	addi	sp,sp,-64
    800049de:	fc06                	sd	ra,56(sp)
    800049e0:	f822                	sd	s0,48(sp)
    800049e2:	f426                	sd	s1,40(sp)
    800049e4:	f04a                	sd	s2,32(sp)
    800049e6:	ec4e                	sd	s3,24(sp)
    800049e8:	e852                	sd	s4,16(sp)
    800049ea:	0080                	addi	s0,sp,64
    800049ec:	892a                	mv	s2,a0
    800049ee:	8a2e                	mv	s4,a1
    800049f0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800049f2:	4601                	li	a2,0
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	dd8080e7          	jalr	-552(ra) # 800047cc <dirlookup>
    800049fc:	e93d                	bnez	a0,80004a72 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049fe:	04c92483          	lw	s1,76(s2)
    80004a02:	c49d                	beqz	s1,80004a30 <dirlink+0x54>
    80004a04:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a06:	4741                	li	a4,16
    80004a08:	86a6                	mv	a3,s1
    80004a0a:	fc040613          	addi	a2,s0,-64
    80004a0e:	4581                	li	a1,0
    80004a10:	854a                	mv	a0,s2
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	b8a080e7          	jalr	-1142(ra) # 8000459c <readi>
    80004a1a:	47c1                	li	a5,16
    80004a1c:	06f51163          	bne	a0,a5,80004a7e <dirlink+0xa2>
    if(de.inum == 0)
    80004a20:	fc045783          	lhu	a5,-64(s0)
    80004a24:	c791                	beqz	a5,80004a30 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a26:	24c1                	addiw	s1,s1,16
    80004a28:	04c92783          	lw	a5,76(s2)
    80004a2c:	fcf4ede3          	bltu	s1,a5,80004a06 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a30:	4639                	li	a2,14
    80004a32:	85d2                	mv	a1,s4
    80004a34:	fc240513          	addi	a0,s0,-62
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	3e0080e7          	jalr	992(ra) # 80000e18 <strncpy>
  de.inum = inum;
    80004a40:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a44:	4741                	li	a4,16
    80004a46:	86a6                	mv	a3,s1
    80004a48:	fc040613          	addi	a2,s0,-64
    80004a4c:	4581                	li	a1,0
    80004a4e:	854a                	mv	a0,s2
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	c44080e7          	jalr	-956(ra) # 80004694 <writei>
    80004a58:	872a                	mv	a4,a0
    80004a5a:	47c1                	li	a5,16
  return 0;
    80004a5c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a5e:	02f71863          	bne	a4,a5,80004a8e <dirlink+0xb2>
}
    80004a62:	70e2                	ld	ra,56(sp)
    80004a64:	7442                	ld	s0,48(sp)
    80004a66:	74a2                	ld	s1,40(sp)
    80004a68:	7902                	ld	s2,32(sp)
    80004a6a:	69e2                	ld	s3,24(sp)
    80004a6c:	6a42                	ld	s4,16(sp)
    80004a6e:	6121                	addi	sp,sp,64
    80004a70:	8082                	ret
    iput(ip);
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	a30080e7          	jalr	-1488(ra) # 800044a2 <iput>
    return -1;
    80004a7a:	557d                	li	a0,-1
    80004a7c:	b7dd                	j	80004a62 <dirlink+0x86>
      panic("dirlink read");
    80004a7e:	00004517          	auipc	a0,0x4
    80004a82:	3e250513          	addi	a0,a0,994 # 80008e60 <syscalls+0x1c8>
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	ab8080e7          	jalr	-1352(ra) # 8000053e <panic>
    panic("dirlink");
    80004a8e:	00004517          	auipc	a0,0x4
    80004a92:	4e250513          	addi	a0,a0,1250 # 80008f70 <syscalls+0x2d8>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	aa8080e7          	jalr	-1368(ra) # 8000053e <panic>

0000000080004a9e <namei>:

struct inode*
namei(char *path)
{
    80004a9e:	1101                	addi	sp,sp,-32
    80004aa0:	ec06                	sd	ra,24(sp)
    80004aa2:	e822                	sd	s0,16(sp)
    80004aa4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004aa6:	fe040613          	addi	a2,s0,-32
    80004aaa:	4581                	li	a1,0
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	dd0080e7          	jalr	-560(ra) # 8000487c <namex>
}
    80004ab4:	60e2                	ld	ra,24(sp)
    80004ab6:	6442                	ld	s0,16(sp)
    80004ab8:	6105                	addi	sp,sp,32
    80004aba:	8082                	ret

0000000080004abc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004abc:	1141                	addi	sp,sp,-16
    80004abe:	e406                	sd	ra,8(sp)
    80004ac0:	e022                	sd	s0,0(sp)
    80004ac2:	0800                	addi	s0,sp,16
    80004ac4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004ac6:	4585                	li	a1,1
    80004ac8:	00000097          	auipc	ra,0x0
    80004acc:	db4080e7          	jalr	-588(ra) # 8000487c <namex>
}
    80004ad0:	60a2                	ld	ra,8(sp)
    80004ad2:	6402                	ld	s0,0(sp)
    80004ad4:	0141                	addi	sp,sp,16
    80004ad6:	8082                	ret

0000000080004ad8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004ad8:	1101                	addi	sp,sp,-32
    80004ada:	ec06                	sd	ra,24(sp)
    80004adc:	e822                	sd	s0,16(sp)
    80004ade:	e426                	sd	s1,8(sp)
    80004ae0:	e04a                	sd	s2,0(sp)
    80004ae2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004ae4:	00017917          	auipc	s2,0x17
    80004ae8:	b5c90913          	addi	s2,s2,-1188 # 8001b640 <log>
    80004aec:	01892583          	lw	a1,24(s2)
    80004af0:	02892503          	lw	a0,40(s2)
    80004af4:	fffff097          	auipc	ra,0xfffff
    80004af8:	ff2080e7          	jalr	-14(ra) # 80003ae6 <bread>
    80004afc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004afe:	02c92683          	lw	a3,44(s2)
    80004b02:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b04:	02d05763          	blez	a3,80004b32 <write_head+0x5a>
    80004b08:	00017797          	auipc	a5,0x17
    80004b0c:	b6878793          	addi	a5,a5,-1176 # 8001b670 <log+0x30>
    80004b10:	05c50713          	addi	a4,a0,92
    80004b14:	36fd                	addiw	a3,a3,-1
    80004b16:	1682                	slli	a3,a3,0x20
    80004b18:	9281                	srli	a3,a3,0x20
    80004b1a:	068a                	slli	a3,a3,0x2
    80004b1c:	00017617          	auipc	a2,0x17
    80004b20:	b5860613          	addi	a2,a2,-1192 # 8001b674 <log+0x34>
    80004b24:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b26:	4390                	lw	a2,0(a5)
    80004b28:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b2a:	0791                	addi	a5,a5,4
    80004b2c:	0711                	addi	a4,a4,4
    80004b2e:	fed79ce3          	bne	a5,a3,80004b26 <write_head+0x4e>
  }
  bwrite(buf);
    80004b32:	8526                	mv	a0,s1
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	0a4080e7          	jalr	164(ra) # 80003bd8 <bwrite>
  brelse(buf);
    80004b3c:	8526                	mv	a0,s1
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	0d8080e7          	jalr	216(ra) # 80003c16 <brelse>
}
    80004b46:	60e2                	ld	ra,24(sp)
    80004b48:	6442                	ld	s0,16(sp)
    80004b4a:	64a2                	ld	s1,8(sp)
    80004b4c:	6902                	ld	s2,0(sp)
    80004b4e:	6105                	addi	sp,sp,32
    80004b50:	8082                	ret

0000000080004b52 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b52:	00017797          	auipc	a5,0x17
    80004b56:	b1a7a783          	lw	a5,-1254(a5) # 8001b66c <log+0x2c>
    80004b5a:	0af05d63          	blez	a5,80004c14 <install_trans+0xc2>
{
    80004b5e:	7139                	addi	sp,sp,-64
    80004b60:	fc06                	sd	ra,56(sp)
    80004b62:	f822                	sd	s0,48(sp)
    80004b64:	f426                	sd	s1,40(sp)
    80004b66:	f04a                	sd	s2,32(sp)
    80004b68:	ec4e                	sd	s3,24(sp)
    80004b6a:	e852                	sd	s4,16(sp)
    80004b6c:	e456                	sd	s5,8(sp)
    80004b6e:	e05a                	sd	s6,0(sp)
    80004b70:	0080                	addi	s0,sp,64
    80004b72:	8b2a                	mv	s6,a0
    80004b74:	00017a97          	auipc	s5,0x17
    80004b78:	afca8a93          	addi	s5,s5,-1284 # 8001b670 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b7c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b7e:	00017997          	auipc	s3,0x17
    80004b82:	ac298993          	addi	s3,s3,-1342 # 8001b640 <log>
    80004b86:	a035                	j	80004bb2 <install_trans+0x60>
      bunpin(dbuf);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	166080e7          	jalr	358(ra) # 80003cf0 <bunpin>
    brelse(lbuf);
    80004b92:	854a                	mv	a0,s2
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	082080e7          	jalr	130(ra) # 80003c16 <brelse>
    brelse(dbuf);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	078080e7          	jalr	120(ra) # 80003c16 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ba6:	2a05                	addiw	s4,s4,1
    80004ba8:	0a91                	addi	s5,s5,4
    80004baa:	02c9a783          	lw	a5,44(s3)
    80004bae:	04fa5963          	bge	s4,a5,80004c00 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bb2:	0189a583          	lw	a1,24(s3)
    80004bb6:	014585bb          	addw	a1,a1,s4
    80004bba:	2585                	addiw	a1,a1,1
    80004bbc:	0289a503          	lw	a0,40(s3)
    80004bc0:	fffff097          	auipc	ra,0xfffff
    80004bc4:	f26080e7          	jalr	-218(ra) # 80003ae6 <bread>
    80004bc8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004bca:	000aa583          	lw	a1,0(s5)
    80004bce:	0289a503          	lw	a0,40(s3)
    80004bd2:	fffff097          	auipc	ra,0xfffff
    80004bd6:	f14080e7          	jalr	-236(ra) # 80003ae6 <bread>
    80004bda:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004bdc:	40000613          	li	a2,1024
    80004be0:	05890593          	addi	a1,s2,88
    80004be4:	05850513          	addi	a0,a0,88
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	17c080e7          	jalr	380(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	fe6080e7          	jalr	-26(ra) # 80003bd8 <bwrite>
    if(recovering == 0)
    80004bfa:	f80b1ce3          	bnez	s6,80004b92 <install_trans+0x40>
    80004bfe:	b769                	j	80004b88 <install_trans+0x36>
}
    80004c00:	70e2                	ld	ra,56(sp)
    80004c02:	7442                	ld	s0,48(sp)
    80004c04:	74a2                	ld	s1,40(sp)
    80004c06:	7902                	ld	s2,32(sp)
    80004c08:	69e2                	ld	s3,24(sp)
    80004c0a:	6a42                	ld	s4,16(sp)
    80004c0c:	6aa2                	ld	s5,8(sp)
    80004c0e:	6b02                	ld	s6,0(sp)
    80004c10:	6121                	addi	sp,sp,64
    80004c12:	8082                	ret
    80004c14:	8082                	ret

0000000080004c16 <initlog>:
{
    80004c16:	7179                	addi	sp,sp,-48
    80004c18:	f406                	sd	ra,40(sp)
    80004c1a:	f022                	sd	s0,32(sp)
    80004c1c:	ec26                	sd	s1,24(sp)
    80004c1e:	e84a                	sd	s2,16(sp)
    80004c20:	e44e                	sd	s3,8(sp)
    80004c22:	1800                	addi	s0,sp,48
    80004c24:	892a                	mv	s2,a0
    80004c26:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c28:	00017497          	auipc	s1,0x17
    80004c2c:	a1848493          	addi	s1,s1,-1512 # 8001b640 <log>
    80004c30:	00004597          	auipc	a1,0x4
    80004c34:	24058593          	addi	a1,a1,576 # 80008e70 <syscalls+0x1d8>
    80004c38:	8526                	mv	a0,s1
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	f1a080e7          	jalr	-230(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004c42:	0149a583          	lw	a1,20(s3)
    80004c46:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c48:	0109a783          	lw	a5,16(s3)
    80004c4c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c4e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c52:	854a                	mv	a0,s2
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	e92080e7          	jalr	-366(ra) # 80003ae6 <bread>
  log.lh.n = lh->n;
    80004c5c:	4d3c                	lw	a5,88(a0)
    80004c5e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c60:	02f05563          	blez	a5,80004c8a <initlog+0x74>
    80004c64:	05c50713          	addi	a4,a0,92
    80004c68:	00017697          	auipc	a3,0x17
    80004c6c:	a0868693          	addi	a3,a3,-1528 # 8001b670 <log+0x30>
    80004c70:	37fd                	addiw	a5,a5,-1
    80004c72:	1782                	slli	a5,a5,0x20
    80004c74:	9381                	srli	a5,a5,0x20
    80004c76:	078a                	slli	a5,a5,0x2
    80004c78:	06050613          	addi	a2,a0,96
    80004c7c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c7e:	4310                	lw	a2,0(a4)
    80004c80:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004c82:	0711                	addi	a4,a4,4
    80004c84:	0691                	addi	a3,a3,4
    80004c86:	fef71ce3          	bne	a4,a5,80004c7e <initlog+0x68>
  brelse(buf);
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	f8c080e7          	jalr	-116(ra) # 80003c16 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c92:	4505                	li	a0,1
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	ebe080e7          	jalr	-322(ra) # 80004b52 <install_trans>
  log.lh.n = 0;
    80004c9c:	00017797          	auipc	a5,0x17
    80004ca0:	9c07a823          	sw	zero,-1584(a5) # 8001b66c <log+0x2c>
  write_head(); // clear the log
    80004ca4:	00000097          	auipc	ra,0x0
    80004ca8:	e34080e7          	jalr	-460(ra) # 80004ad8 <write_head>
}
    80004cac:	70a2                	ld	ra,40(sp)
    80004cae:	7402                	ld	s0,32(sp)
    80004cb0:	64e2                	ld	s1,24(sp)
    80004cb2:	6942                	ld	s2,16(sp)
    80004cb4:	69a2                	ld	s3,8(sp)
    80004cb6:	6145                	addi	sp,sp,48
    80004cb8:	8082                	ret

0000000080004cba <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004cba:	1101                	addi	sp,sp,-32
    80004cbc:	ec06                	sd	ra,24(sp)
    80004cbe:	e822                	sd	s0,16(sp)
    80004cc0:	e426                	sd	s1,8(sp)
    80004cc2:	e04a                	sd	s2,0(sp)
    80004cc4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004cc6:	00017517          	auipc	a0,0x17
    80004cca:	97a50513          	addi	a0,a0,-1670 # 8001b640 <log>
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	f16080e7          	jalr	-234(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004cd6:	00017497          	auipc	s1,0x17
    80004cda:	96a48493          	addi	s1,s1,-1686 # 8001b640 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cde:	4979                	li	s2,30
    80004ce0:	a039                	j	80004cee <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ce2:	85a6                	mv	a1,s1
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	ffffe097          	auipc	ra,0xffffe
    80004cea:	daa080e7          	jalr	-598(ra) # 80002a90 <sleep>
    if(log.committing){
    80004cee:	50dc                	lw	a5,36(s1)
    80004cf0:	fbed                	bnez	a5,80004ce2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cf2:	509c                	lw	a5,32(s1)
    80004cf4:	0017871b          	addiw	a4,a5,1
    80004cf8:	0007069b          	sext.w	a3,a4
    80004cfc:	0027179b          	slliw	a5,a4,0x2
    80004d00:	9fb9                	addw	a5,a5,a4
    80004d02:	0017979b          	slliw	a5,a5,0x1
    80004d06:	54d8                	lw	a4,44(s1)
    80004d08:	9fb9                	addw	a5,a5,a4
    80004d0a:	00f95963          	bge	s2,a5,80004d1c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d0e:	85a6                	mv	a1,s1
    80004d10:	8526                	mv	a0,s1
    80004d12:	ffffe097          	auipc	ra,0xffffe
    80004d16:	d7e080e7          	jalr	-642(ra) # 80002a90 <sleep>
    80004d1a:	bfd1                	j	80004cee <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d1c:	00017517          	auipc	a0,0x17
    80004d20:	92450513          	addi	a0,a0,-1756 # 8001b640 <log>
    80004d24:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	f84080e7          	jalr	-124(ra) # 80000caa <release>
      break;
    }
  }
}
    80004d2e:	60e2                	ld	ra,24(sp)
    80004d30:	6442                	ld	s0,16(sp)
    80004d32:	64a2                	ld	s1,8(sp)
    80004d34:	6902                	ld	s2,0(sp)
    80004d36:	6105                	addi	sp,sp,32
    80004d38:	8082                	ret

0000000080004d3a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d3a:	7139                	addi	sp,sp,-64
    80004d3c:	fc06                	sd	ra,56(sp)
    80004d3e:	f822                	sd	s0,48(sp)
    80004d40:	f426                	sd	s1,40(sp)
    80004d42:	f04a                	sd	s2,32(sp)
    80004d44:	ec4e                	sd	s3,24(sp)
    80004d46:	e852                	sd	s4,16(sp)
    80004d48:	e456                	sd	s5,8(sp)
    80004d4a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d4c:	00017497          	auipc	s1,0x17
    80004d50:	8f448493          	addi	s1,s1,-1804 # 8001b640 <log>
    80004d54:	8526                	mv	a0,s1
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	e8e080e7          	jalr	-370(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004d5e:	509c                	lw	a5,32(s1)
    80004d60:	37fd                	addiw	a5,a5,-1
    80004d62:	0007891b          	sext.w	s2,a5
    80004d66:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d68:	50dc                	lw	a5,36(s1)
    80004d6a:	efb9                	bnez	a5,80004dc8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d6c:	06091663          	bnez	s2,80004dd8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004d70:	00017497          	auipc	s1,0x17
    80004d74:	8d048493          	addi	s1,s1,-1840 # 8001b640 <log>
    80004d78:	4785                	li	a5,1
    80004d7a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d7c:	8526                	mv	a0,s1
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	f2c080e7          	jalr	-212(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d86:	54dc                	lw	a5,44(s1)
    80004d88:	06f04763          	bgtz	a5,80004df6 <end_op+0xbc>
    acquire(&log.lock);
    80004d8c:	00017497          	auipc	s1,0x17
    80004d90:	8b448493          	addi	s1,s1,-1868 # 8001b640 <log>
    80004d94:	8526                	mv	a0,s1
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	e4e080e7          	jalr	-434(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004d9e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffe097          	auipc	ra,0xffffe
    80004da8:	f20080e7          	jalr	-224(ra) # 80002cc4 <wakeup>
    release(&log.lock);
    80004dac:	8526                	mv	a0,s1
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	efc080e7          	jalr	-260(ra) # 80000caa <release>
}
    80004db6:	70e2                	ld	ra,56(sp)
    80004db8:	7442                	ld	s0,48(sp)
    80004dba:	74a2                	ld	s1,40(sp)
    80004dbc:	7902                	ld	s2,32(sp)
    80004dbe:	69e2                	ld	s3,24(sp)
    80004dc0:	6a42                	ld	s4,16(sp)
    80004dc2:	6aa2                	ld	s5,8(sp)
    80004dc4:	6121                	addi	sp,sp,64
    80004dc6:	8082                	ret
    panic("log.committing");
    80004dc8:	00004517          	auipc	a0,0x4
    80004dcc:	0b050513          	addi	a0,a0,176 # 80008e78 <syscalls+0x1e0>
    80004dd0:	ffffb097          	auipc	ra,0xffffb
    80004dd4:	76e080e7          	jalr	1902(ra) # 8000053e <panic>
    wakeup(&log);
    80004dd8:	00017497          	auipc	s1,0x17
    80004ddc:	86848493          	addi	s1,s1,-1944 # 8001b640 <log>
    80004de0:	8526                	mv	a0,s1
    80004de2:	ffffe097          	auipc	ra,0xffffe
    80004de6:	ee2080e7          	jalr	-286(ra) # 80002cc4 <wakeup>
  release(&log.lock);
    80004dea:	8526                	mv	a0,s1
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	ebe080e7          	jalr	-322(ra) # 80000caa <release>
  if(do_commit){
    80004df4:	b7c9                	j	80004db6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004df6:	00017a97          	auipc	s5,0x17
    80004dfa:	87aa8a93          	addi	s5,s5,-1926 # 8001b670 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dfe:	00017a17          	auipc	s4,0x17
    80004e02:	842a0a13          	addi	s4,s4,-1982 # 8001b640 <log>
    80004e06:	018a2583          	lw	a1,24(s4)
    80004e0a:	012585bb          	addw	a1,a1,s2
    80004e0e:	2585                	addiw	a1,a1,1
    80004e10:	028a2503          	lw	a0,40(s4)
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	cd2080e7          	jalr	-814(ra) # 80003ae6 <bread>
    80004e1c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e1e:	000aa583          	lw	a1,0(s5)
    80004e22:	028a2503          	lw	a0,40(s4)
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	cc0080e7          	jalr	-832(ra) # 80003ae6 <bread>
    80004e2e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e30:	40000613          	li	a2,1024
    80004e34:	05850593          	addi	a1,a0,88
    80004e38:	05848513          	addi	a0,s1,88
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	f28080e7          	jalr	-216(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    80004e44:	8526                	mv	a0,s1
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	d92080e7          	jalr	-622(ra) # 80003bd8 <bwrite>
    brelse(from);
    80004e4e:	854e                	mv	a0,s3
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	dc6080e7          	jalr	-570(ra) # 80003c16 <brelse>
    brelse(to);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	dbc080e7          	jalr	-580(ra) # 80003c16 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e62:	2905                	addiw	s2,s2,1
    80004e64:	0a91                	addi	s5,s5,4
    80004e66:	02ca2783          	lw	a5,44(s4)
    80004e6a:	f8f94ee3          	blt	s2,a5,80004e06 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e6e:	00000097          	auipc	ra,0x0
    80004e72:	c6a080e7          	jalr	-918(ra) # 80004ad8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e76:	4501                	li	a0,0
    80004e78:	00000097          	auipc	ra,0x0
    80004e7c:	cda080e7          	jalr	-806(ra) # 80004b52 <install_trans>
    log.lh.n = 0;
    80004e80:	00016797          	auipc	a5,0x16
    80004e84:	7e07a623          	sw	zero,2028(a5) # 8001b66c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e88:	00000097          	auipc	ra,0x0
    80004e8c:	c50080e7          	jalr	-944(ra) # 80004ad8 <write_head>
    80004e90:	bdf5                	j	80004d8c <end_op+0x52>

0000000080004e92 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e92:	1101                	addi	sp,sp,-32
    80004e94:	ec06                	sd	ra,24(sp)
    80004e96:	e822                	sd	s0,16(sp)
    80004e98:	e426                	sd	s1,8(sp)
    80004e9a:	e04a                	sd	s2,0(sp)
    80004e9c:	1000                	addi	s0,sp,32
    80004e9e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ea0:	00016917          	auipc	s2,0x16
    80004ea4:	7a090913          	addi	s2,s2,1952 # 8001b640 <log>
    80004ea8:	854a                	mv	a0,s2
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	d3a080e7          	jalr	-710(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004eb2:	02c92603          	lw	a2,44(s2)
    80004eb6:	47f5                	li	a5,29
    80004eb8:	06c7c563          	blt	a5,a2,80004f22 <log_write+0x90>
    80004ebc:	00016797          	auipc	a5,0x16
    80004ec0:	7a07a783          	lw	a5,1952(a5) # 8001b65c <log+0x1c>
    80004ec4:	37fd                	addiw	a5,a5,-1
    80004ec6:	04f65e63          	bge	a2,a5,80004f22 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004eca:	00016797          	auipc	a5,0x16
    80004ece:	7967a783          	lw	a5,1942(a5) # 8001b660 <log+0x20>
    80004ed2:	06f05063          	blez	a5,80004f32 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ed6:	4781                	li	a5,0
    80004ed8:	06c05563          	blez	a2,80004f42 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004edc:	44cc                	lw	a1,12(s1)
    80004ede:	00016717          	auipc	a4,0x16
    80004ee2:	79270713          	addi	a4,a4,1938 # 8001b670 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ee6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ee8:	4314                	lw	a3,0(a4)
    80004eea:	04b68c63          	beq	a3,a1,80004f42 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004eee:	2785                	addiw	a5,a5,1
    80004ef0:	0711                	addi	a4,a4,4
    80004ef2:	fef61be3          	bne	a2,a5,80004ee8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ef6:	0621                	addi	a2,a2,8
    80004ef8:	060a                	slli	a2,a2,0x2
    80004efa:	00016797          	auipc	a5,0x16
    80004efe:	74678793          	addi	a5,a5,1862 # 8001b640 <log>
    80004f02:	963e                	add	a2,a2,a5
    80004f04:	44dc                	lw	a5,12(s1)
    80004f06:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f08:	8526                	mv	a0,s1
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	daa080e7          	jalr	-598(ra) # 80003cb4 <bpin>
    log.lh.n++;
    80004f12:	00016717          	auipc	a4,0x16
    80004f16:	72e70713          	addi	a4,a4,1838 # 8001b640 <log>
    80004f1a:	575c                	lw	a5,44(a4)
    80004f1c:	2785                	addiw	a5,a5,1
    80004f1e:	d75c                	sw	a5,44(a4)
    80004f20:	a835                	j	80004f5c <log_write+0xca>
    panic("too big a transaction");
    80004f22:	00004517          	auipc	a0,0x4
    80004f26:	f6650513          	addi	a0,a0,-154 # 80008e88 <syscalls+0x1f0>
    80004f2a:	ffffb097          	auipc	ra,0xffffb
    80004f2e:	614080e7          	jalr	1556(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004f32:	00004517          	auipc	a0,0x4
    80004f36:	f6e50513          	addi	a0,a0,-146 # 80008ea0 <syscalls+0x208>
    80004f3a:	ffffb097          	auipc	ra,0xffffb
    80004f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004f42:	00878713          	addi	a4,a5,8
    80004f46:	00271693          	slli	a3,a4,0x2
    80004f4a:	00016717          	auipc	a4,0x16
    80004f4e:	6f670713          	addi	a4,a4,1782 # 8001b640 <log>
    80004f52:	9736                	add	a4,a4,a3
    80004f54:	44d4                	lw	a3,12(s1)
    80004f56:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f58:	faf608e3          	beq	a2,a5,80004f08 <log_write+0x76>
  }
  release(&log.lock);
    80004f5c:	00016517          	auipc	a0,0x16
    80004f60:	6e450513          	addi	a0,a0,1764 # 8001b640 <log>
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	d46080e7          	jalr	-698(ra) # 80000caa <release>
}
    80004f6c:	60e2                	ld	ra,24(sp)
    80004f6e:	6442                	ld	s0,16(sp)
    80004f70:	64a2                	ld	s1,8(sp)
    80004f72:	6902                	ld	s2,0(sp)
    80004f74:	6105                	addi	sp,sp,32
    80004f76:	8082                	ret

0000000080004f78 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f78:	1101                	addi	sp,sp,-32
    80004f7a:	ec06                	sd	ra,24(sp)
    80004f7c:	e822                	sd	s0,16(sp)
    80004f7e:	e426                	sd	s1,8(sp)
    80004f80:	e04a                	sd	s2,0(sp)
    80004f82:	1000                	addi	s0,sp,32
    80004f84:	84aa                	mv	s1,a0
    80004f86:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f88:	00004597          	auipc	a1,0x4
    80004f8c:	f3858593          	addi	a1,a1,-200 # 80008ec0 <syscalls+0x228>
    80004f90:	0521                	addi	a0,a0,8
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	bc2080e7          	jalr	-1086(ra) # 80000b54 <initlock>
  lk->name = name;
    80004f9a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f9e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fa2:	0204a423          	sw	zero,40(s1)
}
    80004fa6:	60e2                	ld	ra,24(sp)
    80004fa8:	6442                	ld	s0,16(sp)
    80004faa:	64a2                	ld	s1,8(sp)
    80004fac:	6902                	ld	s2,0(sp)
    80004fae:	6105                	addi	sp,sp,32
    80004fb0:	8082                	ret

0000000080004fb2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004fb2:	1101                	addi	sp,sp,-32
    80004fb4:	ec06                	sd	ra,24(sp)
    80004fb6:	e822                	sd	s0,16(sp)
    80004fb8:	e426                	sd	s1,8(sp)
    80004fba:	e04a                	sd	s2,0(sp)
    80004fbc:	1000                	addi	s0,sp,32
    80004fbe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fc0:	00850913          	addi	s2,a0,8
    80004fc4:	854a                	mv	a0,s2
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004fce:	409c                	lw	a5,0(s1)
    80004fd0:	cb89                	beqz	a5,80004fe2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004fd2:	85ca                	mv	a1,s2
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	ffffe097          	auipc	ra,0xffffe
    80004fda:	aba080e7          	jalr	-1350(ra) # 80002a90 <sleep>
  while (lk->locked) {
    80004fde:	409c                	lw	a5,0(s1)
    80004fe0:	fbed                	bnez	a5,80004fd2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fe2:	4785                	li	a5,1
    80004fe4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	ede080e7          	jalr	-290(ra) # 80001ec4 <myproc>
    80004fee:	591c                	lw	a5,48(a0)
    80004ff0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ff2:	854a                	mv	a0,s2
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	cb6080e7          	jalr	-842(ra) # 80000caa <release>
}
    80004ffc:	60e2                	ld	ra,24(sp)
    80004ffe:	6442                	ld	s0,16(sp)
    80005000:	64a2                	ld	s1,8(sp)
    80005002:	6902                	ld	s2,0(sp)
    80005004:	6105                	addi	sp,sp,32
    80005006:	8082                	ret

0000000080005008 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005008:	1101                	addi	sp,sp,-32
    8000500a:	ec06                	sd	ra,24(sp)
    8000500c:	e822                	sd	s0,16(sp)
    8000500e:	e426                	sd	s1,8(sp)
    80005010:	e04a                	sd	s2,0(sp)
    80005012:	1000                	addi	s0,sp,32
    80005014:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005016:	00850913          	addi	s2,a0,8
    8000501a:	854a                	mv	a0,s2
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	bc8080e7          	jalr	-1080(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80005024:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005028:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000502c:	8526                	mv	a0,s1
    8000502e:	ffffe097          	auipc	ra,0xffffe
    80005032:	c96080e7          	jalr	-874(ra) # 80002cc4 <wakeup>
  release(&lk->lk);
    80005036:	854a                	mv	a0,s2
    80005038:	ffffc097          	auipc	ra,0xffffc
    8000503c:	c72080e7          	jalr	-910(ra) # 80000caa <release>
}
    80005040:	60e2                	ld	ra,24(sp)
    80005042:	6442                	ld	s0,16(sp)
    80005044:	64a2                	ld	s1,8(sp)
    80005046:	6902                	ld	s2,0(sp)
    80005048:	6105                	addi	sp,sp,32
    8000504a:	8082                	ret

000000008000504c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000504c:	7179                	addi	sp,sp,-48
    8000504e:	f406                	sd	ra,40(sp)
    80005050:	f022                	sd	s0,32(sp)
    80005052:	ec26                	sd	s1,24(sp)
    80005054:	e84a                	sd	s2,16(sp)
    80005056:	e44e                	sd	s3,8(sp)
    80005058:	1800                	addi	s0,sp,48
    8000505a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000505c:	00850913          	addi	s2,a0,8
    80005060:	854a                	mv	a0,s2
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	b82080e7          	jalr	-1150(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000506a:	409c                	lw	a5,0(s1)
    8000506c:	ef99                	bnez	a5,8000508a <holdingsleep+0x3e>
    8000506e:	4481                	li	s1,0
  release(&lk->lk);
    80005070:	854a                	mv	a0,s2
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	c38080e7          	jalr	-968(ra) # 80000caa <release>
  return r;
}
    8000507a:	8526                	mv	a0,s1
    8000507c:	70a2                	ld	ra,40(sp)
    8000507e:	7402                	ld	s0,32(sp)
    80005080:	64e2                	ld	s1,24(sp)
    80005082:	6942                	ld	s2,16(sp)
    80005084:	69a2                	ld	s3,8(sp)
    80005086:	6145                	addi	sp,sp,48
    80005088:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000508a:	0284a983          	lw	s3,40(s1)
    8000508e:	ffffd097          	auipc	ra,0xffffd
    80005092:	e36080e7          	jalr	-458(ra) # 80001ec4 <myproc>
    80005096:	5904                	lw	s1,48(a0)
    80005098:	413484b3          	sub	s1,s1,s3
    8000509c:	0014b493          	seqz	s1,s1
    800050a0:	bfc1                	j	80005070 <holdingsleep+0x24>

00000000800050a2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800050a2:	1141                	addi	sp,sp,-16
    800050a4:	e406                	sd	ra,8(sp)
    800050a6:	e022                	sd	s0,0(sp)
    800050a8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800050aa:	00004597          	auipc	a1,0x4
    800050ae:	e2658593          	addi	a1,a1,-474 # 80008ed0 <syscalls+0x238>
    800050b2:	00016517          	auipc	a0,0x16
    800050b6:	6d650513          	addi	a0,a0,1750 # 8001b788 <ftable>
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	a9a080e7          	jalr	-1382(ra) # 80000b54 <initlock>
}
    800050c2:	60a2                	ld	ra,8(sp)
    800050c4:	6402                	ld	s0,0(sp)
    800050c6:	0141                	addi	sp,sp,16
    800050c8:	8082                	ret

00000000800050ca <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800050ca:	1101                	addi	sp,sp,-32
    800050cc:	ec06                	sd	ra,24(sp)
    800050ce:	e822                	sd	s0,16(sp)
    800050d0:	e426                	sd	s1,8(sp)
    800050d2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050d4:	00016517          	auipc	a0,0x16
    800050d8:	6b450513          	addi	a0,a0,1716 # 8001b788 <ftable>
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	b08080e7          	jalr	-1272(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050e4:	00016497          	auipc	s1,0x16
    800050e8:	6bc48493          	addi	s1,s1,1724 # 8001b7a0 <ftable+0x18>
    800050ec:	00017717          	auipc	a4,0x17
    800050f0:	65470713          	addi	a4,a4,1620 # 8001c740 <ftable+0xfb8>
    if(f->ref == 0){
    800050f4:	40dc                	lw	a5,4(s1)
    800050f6:	cf99                	beqz	a5,80005114 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050f8:	02848493          	addi	s1,s1,40
    800050fc:	fee49ce3          	bne	s1,a4,800050f4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005100:	00016517          	auipc	a0,0x16
    80005104:	68850513          	addi	a0,a0,1672 # 8001b788 <ftable>
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	ba2080e7          	jalr	-1118(ra) # 80000caa <release>
  return 0;
    80005110:	4481                	li	s1,0
    80005112:	a819                	j	80005128 <filealloc+0x5e>
      f->ref = 1;
    80005114:	4785                	li	a5,1
    80005116:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005118:	00016517          	auipc	a0,0x16
    8000511c:	67050513          	addi	a0,a0,1648 # 8001b788 <ftable>
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	b8a080e7          	jalr	-1142(ra) # 80000caa <release>
}
    80005128:	8526                	mv	a0,s1
    8000512a:	60e2                	ld	ra,24(sp)
    8000512c:	6442                	ld	s0,16(sp)
    8000512e:	64a2                	ld	s1,8(sp)
    80005130:	6105                	addi	sp,sp,32
    80005132:	8082                	ret

0000000080005134 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005134:	1101                	addi	sp,sp,-32
    80005136:	ec06                	sd	ra,24(sp)
    80005138:	e822                	sd	s0,16(sp)
    8000513a:	e426                	sd	s1,8(sp)
    8000513c:	1000                	addi	s0,sp,32
    8000513e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005140:	00016517          	auipc	a0,0x16
    80005144:	64850513          	addi	a0,a0,1608 # 8001b788 <ftable>
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	a9c080e7          	jalr	-1380(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005150:	40dc                	lw	a5,4(s1)
    80005152:	02f05263          	blez	a5,80005176 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005156:	2785                	addiw	a5,a5,1
    80005158:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000515a:	00016517          	auipc	a0,0x16
    8000515e:	62e50513          	addi	a0,a0,1582 # 8001b788 <ftable>
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	b48080e7          	jalr	-1208(ra) # 80000caa <release>
  return f;
}
    8000516a:	8526                	mv	a0,s1
    8000516c:	60e2                	ld	ra,24(sp)
    8000516e:	6442                	ld	s0,16(sp)
    80005170:	64a2                	ld	s1,8(sp)
    80005172:	6105                	addi	sp,sp,32
    80005174:	8082                	ret
    panic("filedup");
    80005176:	00004517          	auipc	a0,0x4
    8000517a:	d6250513          	addi	a0,a0,-670 # 80008ed8 <syscalls+0x240>
    8000517e:	ffffb097          	auipc	ra,0xffffb
    80005182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>

0000000080005186 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005186:	7139                	addi	sp,sp,-64
    80005188:	fc06                	sd	ra,56(sp)
    8000518a:	f822                	sd	s0,48(sp)
    8000518c:	f426                	sd	s1,40(sp)
    8000518e:	f04a                	sd	s2,32(sp)
    80005190:	ec4e                	sd	s3,24(sp)
    80005192:	e852                	sd	s4,16(sp)
    80005194:	e456                	sd	s5,8(sp)
    80005196:	0080                	addi	s0,sp,64
    80005198:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000519a:	00016517          	auipc	a0,0x16
    8000519e:	5ee50513          	addi	a0,a0,1518 # 8001b788 <ftable>
    800051a2:	ffffc097          	auipc	ra,0xffffc
    800051a6:	a42080e7          	jalr	-1470(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800051aa:	40dc                	lw	a5,4(s1)
    800051ac:	06f05163          	blez	a5,8000520e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800051b0:	37fd                	addiw	a5,a5,-1
    800051b2:	0007871b          	sext.w	a4,a5
    800051b6:	c0dc                	sw	a5,4(s1)
    800051b8:	06e04363          	bgtz	a4,8000521e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800051bc:	0004a903          	lw	s2,0(s1)
    800051c0:	0094ca83          	lbu	s5,9(s1)
    800051c4:	0104ba03          	ld	s4,16(s1)
    800051c8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800051cc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800051d0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051d4:	00016517          	auipc	a0,0x16
    800051d8:	5b450513          	addi	a0,a0,1460 # 8001b788 <ftable>
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	ace080e7          	jalr	-1330(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    800051e4:	4785                	li	a5,1
    800051e6:	04f90d63          	beq	s2,a5,80005240 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051ea:	3979                	addiw	s2,s2,-2
    800051ec:	4785                	li	a5,1
    800051ee:	0527e063          	bltu	a5,s2,8000522e <fileclose+0xa8>
    begin_op();
    800051f2:	00000097          	auipc	ra,0x0
    800051f6:	ac8080e7          	jalr	-1336(ra) # 80004cba <begin_op>
    iput(ff.ip);
    800051fa:	854e                	mv	a0,s3
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	2a6080e7          	jalr	678(ra) # 800044a2 <iput>
    end_op();
    80005204:	00000097          	auipc	ra,0x0
    80005208:	b36080e7          	jalr	-1226(ra) # 80004d3a <end_op>
    8000520c:	a00d                	j	8000522e <fileclose+0xa8>
    panic("fileclose");
    8000520e:	00004517          	auipc	a0,0x4
    80005212:	cd250513          	addi	a0,a0,-814 # 80008ee0 <syscalls+0x248>
    80005216:	ffffb097          	auipc	ra,0xffffb
    8000521a:	328080e7          	jalr	808(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000521e:	00016517          	auipc	a0,0x16
    80005222:	56a50513          	addi	a0,a0,1386 # 8001b788 <ftable>
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	a84080e7          	jalr	-1404(ra) # 80000caa <release>
  }
}
    8000522e:	70e2                	ld	ra,56(sp)
    80005230:	7442                	ld	s0,48(sp)
    80005232:	74a2                	ld	s1,40(sp)
    80005234:	7902                	ld	s2,32(sp)
    80005236:	69e2                	ld	s3,24(sp)
    80005238:	6a42                	ld	s4,16(sp)
    8000523a:	6aa2                	ld	s5,8(sp)
    8000523c:	6121                	addi	sp,sp,64
    8000523e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005240:	85d6                	mv	a1,s5
    80005242:	8552                	mv	a0,s4
    80005244:	00000097          	auipc	ra,0x0
    80005248:	34c080e7          	jalr	844(ra) # 80005590 <pipeclose>
    8000524c:	b7cd                	j	8000522e <fileclose+0xa8>

000000008000524e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000524e:	715d                	addi	sp,sp,-80
    80005250:	e486                	sd	ra,72(sp)
    80005252:	e0a2                	sd	s0,64(sp)
    80005254:	fc26                	sd	s1,56(sp)
    80005256:	f84a                	sd	s2,48(sp)
    80005258:	f44e                	sd	s3,40(sp)
    8000525a:	0880                	addi	s0,sp,80
    8000525c:	84aa                	mv	s1,a0
    8000525e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005260:	ffffd097          	auipc	ra,0xffffd
    80005264:	c64080e7          	jalr	-924(ra) # 80001ec4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005268:	409c                	lw	a5,0(s1)
    8000526a:	37f9                	addiw	a5,a5,-2
    8000526c:	4705                	li	a4,1
    8000526e:	04f76763          	bltu	a4,a5,800052bc <filestat+0x6e>
    80005272:	892a                	mv	s2,a0
    ilock(f->ip);
    80005274:	6c88                	ld	a0,24(s1)
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	072080e7          	jalr	114(ra) # 800042e8 <ilock>
    stati(f->ip, &st);
    8000527e:	fb840593          	addi	a1,s0,-72
    80005282:	6c88                	ld	a0,24(s1)
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	2ee080e7          	jalr	750(ra) # 80004572 <stati>
    iunlock(f->ip);
    8000528c:	6c88                	ld	a0,24(s1)
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	11c080e7          	jalr	284(ra) # 800043aa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005296:	46e1                	li	a3,24
    80005298:	fb840613          	addi	a2,s0,-72
    8000529c:	85ce                	mv	a1,s3
    8000529e:	07093503          	ld	a0,112(s2)
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	3f4080e7          	jalr	1012(ra) # 80001696 <copyout>
    800052aa:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800052ae:	60a6                	ld	ra,72(sp)
    800052b0:	6406                	ld	s0,64(sp)
    800052b2:	74e2                	ld	s1,56(sp)
    800052b4:	7942                	ld	s2,48(sp)
    800052b6:	79a2                	ld	s3,40(sp)
    800052b8:	6161                	addi	sp,sp,80
    800052ba:	8082                	ret
  return -1;
    800052bc:	557d                	li	a0,-1
    800052be:	bfc5                	j	800052ae <filestat+0x60>

00000000800052c0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800052c0:	7179                	addi	sp,sp,-48
    800052c2:	f406                	sd	ra,40(sp)
    800052c4:	f022                	sd	s0,32(sp)
    800052c6:	ec26                	sd	s1,24(sp)
    800052c8:	e84a                	sd	s2,16(sp)
    800052ca:	e44e                	sd	s3,8(sp)
    800052cc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800052ce:	00854783          	lbu	a5,8(a0)
    800052d2:	c3d5                	beqz	a5,80005376 <fileread+0xb6>
    800052d4:	84aa                	mv	s1,a0
    800052d6:	89ae                	mv	s3,a1
    800052d8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052da:	411c                	lw	a5,0(a0)
    800052dc:	4705                	li	a4,1
    800052de:	04e78963          	beq	a5,a4,80005330 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052e2:	470d                	li	a4,3
    800052e4:	04e78d63          	beq	a5,a4,8000533e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052e8:	4709                	li	a4,2
    800052ea:	06e79e63          	bne	a5,a4,80005366 <fileread+0xa6>
    ilock(f->ip);
    800052ee:	6d08                	ld	a0,24(a0)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	ff8080e7          	jalr	-8(ra) # 800042e8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052f8:	874a                	mv	a4,s2
    800052fa:	5094                	lw	a3,32(s1)
    800052fc:	864e                	mv	a2,s3
    800052fe:	4585                	li	a1,1
    80005300:	6c88                	ld	a0,24(s1)
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	29a080e7          	jalr	666(ra) # 8000459c <readi>
    8000530a:	892a                	mv	s2,a0
    8000530c:	00a05563          	blez	a0,80005316 <fileread+0x56>
      f->off += r;
    80005310:	509c                	lw	a5,32(s1)
    80005312:	9fa9                	addw	a5,a5,a0
    80005314:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005316:	6c88                	ld	a0,24(s1)
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	092080e7          	jalr	146(ra) # 800043aa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005320:	854a                	mv	a0,s2
    80005322:	70a2                	ld	ra,40(sp)
    80005324:	7402                	ld	s0,32(sp)
    80005326:	64e2                	ld	s1,24(sp)
    80005328:	6942                	ld	s2,16(sp)
    8000532a:	69a2                	ld	s3,8(sp)
    8000532c:	6145                	addi	sp,sp,48
    8000532e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005330:	6908                	ld	a0,16(a0)
    80005332:	00000097          	auipc	ra,0x0
    80005336:	3c8080e7          	jalr	968(ra) # 800056fa <piperead>
    8000533a:	892a                	mv	s2,a0
    8000533c:	b7d5                	j	80005320 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000533e:	02451783          	lh	a5,36(a0)
    80005342:	03079693          	slli	a3,a5,0x30
    80005346:	92c1                	srli	a3,a3,0x30
    80005348:	4725                	li	a4,9
    8000534a:	02d76863          	bltu	a4,a3,8000537a <fileread+0xba>
    8000534e:	0792                	slli	a5,a5,0x4
    80005350:	00016717          	auipc	a4,0x16
    80005354:	39870713          	addi	a4,a4,920 # 8001b6e8 <devsw>
    80005358:	97ba                	add	a5,a5,a4
    8000535a:	639c                	ld	a5,0(a5)
    8000535c:	c38d                	beqz	a5,8000537e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000535e:	4505                	li	a0,1
    80005360:	9782                	jalr	a5
    80005362:	892a                	mv	s2,a0
    80005364:	bf75                	j	80005320 <fileread+0x60>
    panic("fileread");
    80005366:	00004517          	auipc	a0,0x4
    8000536a:	b8a50513          	addi	a0,a0,-1142 # 80008ef0 <syscalls+0x258>
    8000536e:	ffffb097          	auipc	ra,0xffffb
    80005372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>
    return -1;
    80005376:	597d                	li	s2,-1
    80005378:	b765                	j	80005320 <fileread+0x60>
      return -1;
    8000537a:	597d                	li	s2,-1
    8000537c:	b755                	j	80005320 <fileread+0x60>
    8000537e:	597d                	li	s2,-1
    80005380:	b745                	j	80005320 <fileread+0x60>

0000000080005382 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005382:	715d                	addi	sp,sp,-80
    80005384:	e486                	sd	ra,72(sp)
    80005386:	e0a2                	sd	s0,64(sp)
    80005388:	fc26                	sd	s1,56(sp)
    8000538a:	f84a                	sd	s2,48(sp)
    8000538c:	f44e                	sd	s3,40(sp)
    8000538e:	f052                	sd	s4,32(sp)
    80005390:	ec56                	sd	s5,24(sp)
    80005392:	e85a                	sd	s6,16(sp)
    80005394:	e45e                	sd	s7,8(sp)
    80005396:	e062                	sd	s8,0(sp)
    80005398:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000539a:	00954783          	lbu	a5,9(a0)
    8000539e:	10078663          	beqz	a5,800054aa <filewrite+0x128>
    800053a2:	892a                	mv	s2,a0
    800053a4:	8aae                	mv	s5,a1
    800053a6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800053a8:	411c                	lw	a5,0(a0)
    800053aa:	4705                	li	a4,1
    800053ac:	02e78263          	beq	a5,a4,800053d0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053b0:	470d                	li	a4,3
    800053b2:	02e78663          	beq	a5,a4,800053de <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800053b6:	4709                	li	a4,2
    800053b8:	0ee79163          	bne	a5,a4,8000549a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800053bc:	0ac05d63          	blez	a2,80005476 <filewrite+0xf4>
    int i = 0;
    800053c0:	4981                	li	s3,0
    800053c2:	6b05                	lui	s6,0x1
    800053c4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053c8:	6b85                	lui	s7,0x1
    800053ca:	c00b8b9b          	addiw	s7,s7,-1024
    800053ce:	a861                	j	80005466 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800053d0:	6908                	ld	a0,16(a0)
    800053d2:	00000097          	auipc	ra,0x0
    800053d6:	22e080e7          	jalr	558(ra) # 80005600 <pipewrite>
    800053da:	8a2a                	mv	s4,a0
    800053dc:	a045                	j	8000547c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053de:	02451783          	lh	a5,36(a0)
    800053e2:	03079693          	slli	a3,a5,0x30
    800053e6:	92c1                	srli	a3,a3,0x30
    800053e8:	4725                	li	a4,9
    800053ea:	0cd76263          	bltu	a4,a3,800054ae <filewrite+0x12c>
    800053ee:	0792                	slli	a5,a5,0x4
    800053f0:	00016717          	auipc	a4,0x16
    800053f4:	2f870713          	addi	a4,a4,760 # 8001b6e8 <devsw>
    800053f8:	97ba                	add	a5,a5,a4
    800053fa:	679c                	ld	a5,8(a5)
    800053fc:	cbdd                	beqz	a5,800054b2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053fe:	4505                	li	a0,1
    80005400:	9782                	jalr	a5
    80005402:	8a2a                	mv	s4,a0
    80005404:	a8a5                	j	8000547c <filewrite+0xfa>
    80005406:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000540a:	00000097          	auipc	ra,0x0
    8000540e:	8b0080e7          	jalr	-1872(ra) # 80004cba <begin_op>
      ilock(f->ip);
    80005412:	01893503          	ld	a0,24(s2)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	ed2080e7          	jalr	-302(ra) # 800042e8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000541e:	8762                	mv	a4,s8
    80005420:	02092683          	lw	a3,32(s2)
    80005424:	01598633          	add	a2,s3,s5
    80005428:	4585                	li	a1,1
    8000542a:	01893503          	ld	a0,24(s2)
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	266080e7          	jalr	614(ra) # 80004694 <writei>
    80005436:	84aa                	mv	s1,a0
    80005438:	00a05763          	blez	a0,80005446 <filewrite+0xc4>
        f->off += r;
    8000543c:	02092783          	lw	a5,32(s2)
    80005440:	9fa9                	addw	a5,a5,a0
    80005442:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005446:	01893503          	ld	a0,24(s2)
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	f60080e7          	jalr	-160(ra) # 800043aa <iunlock>
      end_op();
    80005452:	00000097          	auipc	ra,0x0
    80005456:	8e8080e7          	jalr	-1816(ra) # 80004d3a <end_op>

      if(r != n1){
    8000545a:	009c1f63          	bne	s8,s1,80005478 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000545e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005462:	0149db63          	bge	s3,s4,80005478 <filewrite+0xf6>
      int n1 = n - i;
    80005466:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000546a:	84be                	mv	s1,a5
    8000546c:	2781                	sext.w	a5,a5
    8000546e:	f8fb5ce3          	bge	s6,a5,80005406 <filewrite+0x84>
    80005472:	84de                	mv	s1,s7
    80005474:	bf49                	j	80005406 <filewrite+0x84>
    int i = 0;
    80005476:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005478:	013a1f63          	bne	s4,s3,80005496 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000547c:	8552                	mv	a0,s4
    8000547e:	60a6                	ld	ra,72(sp)
    80005480:	6406                	ld	s0,64(sp)
    80005482:	74e2                	ld	s1,56(sp)
    80005484:	7942                	ld	s2,48(sp)
    80005486:	79a2                	ld	s3,40(sp)
    80005488:	7a02                	ld	s4,32(sp)
    8000548a:	6ae2                	ld	s5,24(sp)
    8000548c:	6b42                	ld	s6,16(sp)
    8000548e:	6ba2                	ld	s7,8(sp)
    80005490:	6c02                	ld	s8,0(sp)
    80005492:	6161                	addi	sp,sp,80
    80005494:	8082                	ret
    ret = (i == n ? n : -1);
    80005496:	5a7d                	li	s4,-1
    80005498:	b7d5                	j	8000547c <filewrite+0xfa>
    panic("filewrite");
    8000549a:	00004517          	auipc	a0,0x4
    8000549e:	a6650513          	addi	a0,a0,-1434 # 80008f00 <syscalls+0x268>
    800054a2:	ffffb097          	auipc	ra,0xffffb
    800054a6:	09c080e7          	jalr	156(ra) # 8000053e <panic>
    return -1;
    800054aa:	5a7d                	li	s4,-1
    800054ac:	bfc1                	j	8000547c <filewrite+0xfa>
      return -1;
    800054ae:	5a7d                	li	s4,-1
    800054b0:	b7f1                	j	8000547c <filewrite+0xfa>
    800054b2:	5a7d                	li	s4,-1
    800054b4:	b7e1                	j	8000547c <filewrite+0xfa>

00000000800054b6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800054b6:	7179                	addi	sp,sp,-48
    800054b8:	f406                	sd	ra,40(sp)
    800054ba:	f022                	sd	s0,32(sp)
    800054bc:	ec26                	sd	s1,24(sp)
    800054be:	e84a                	sd	s2,16(sp)
    800054c0:	e44e                	sd	s3,8(sp)
    800054c2:	e052                	sd	s4,0(sp)
    800054c4:	1800                	addi	s0,sp,48
    800054c6:	84aa                	mv	s1,a0
    800054c8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800054ca:	0005b023          	sd	zero,0(a1)
    800054ce:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800054d2:	00000097          	auipc	ra,0x0
    800054d6:	bf8080e7          	jalr	-1032(ra) # 800050ca <filealloc>
    800054da:	e088                	sd	a0,0(s1)
    800054dc:	c551                	beqz	a0,80005568 <pipealloc+0xb2>
    800054de:	00000097          	auipc	ra,0x0
    800054e2:	bec080e7          	jalr	-1044(ra) # 800050ca <filealloc>
    800054e6:	00aa3023          	sd	a0,0(s4)
    800054ea:	c92d                	beqz	a0,8000555c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054ec:	ffffb097          	auipc	ra,0xffffb
    800054f0:	608080e7          	jalr	1544(ra) # 80000af4 <kalloc>
    800054f4:	892a                	mv	s2,a0
    800054f6:	c125                	beqz	a0,80005556 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054f8:	4985                	li	s3,1
    800054fa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054fe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005502:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005506:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000550a:	00004597          	auipc	a1,0x4
    8000550e:	a0658593          	addi	a1,a1,-1530 # 80008f10 <syscalls+0x278>
    80005512:	ffffb097          	auipc	ra,0xffffb
    80005516:	642080e7          	jalr	1602(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000551a:	609c                	ld	a5,0(s1)
    8000551c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005520:	609c                	ld	a5,0(s1)
    80005522:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005526:	609c                	ld	a5,0(s1)
    80005528:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000552c:	609c                	ld	a5,0(s1)
    8000552e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005532:	000a3783          	ld	a5,0(s4)
    80005536:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000553a:	000a3783          	ld	a5,0(s4)
    8000553e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005542:	000a3783          	ld	a5,0(s4)
    80005546:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000554a:	000a3783          	ld	a5,0(s4)
    8000554e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005552:	4501                	li	a0,0
    80005554:	a025                	j	8000557c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005556:	6088                	ld	a0,0(s1)
    80005558:	e501                	bnez	a0,80005560 <pipealloc+0xaa>
    8000555a:	a039                	j	80005568 <pipealloc+0xb2>
    8000555c:	6088                	ld	a0,0(s1)
    8000555e:	c51d                	beqz	a0,8000558c <pipealloc+0xd6>
    fileclose(*f0);
    80005560:	00000097          	auipc	ra,0x0
    80005564:	c26080e7          	jalr	-986(ra) # 80005186 <fileclose>
  if(*f1)
    80005568:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000556c:	557d                	li	a0,-1
  if(*f1)
    8000556e:	c799                	beqz	a5,8000557c <pipealloc+0xc6>
    fileclose(*f1);
    80005570:	853e                	mv	a0,a5
    80005572:	00000097          	auipc	ra,0x0
    80005576:	c14080e7          	jalr	-1004(ra) # 80005186 <fileclose>
  return -1;
    8000557a:	557d                	li	a0,-1
}
    8000557c:	70a2                	ld	ra,40(sp)
    8000557e:	7402                	ld	s0,32(sp)
    80005580:	64e2                	ld	s1,24(sp)
    80005582:	6942                	ld	s2,16(sp)
    80005584:	69a2                	ld	s3,8(sp)
    80005586:	6a02                	ld	s4,0(sp)
    80005588:	6145                	addi	sp,sp,48
    8000558a:	8082                	ret
  return -1;
    8000558c:	557d                	li	a0,-1
    8000558e:	b7fd                	j	8000557c <pipealloc+0xc6>

0000000080005590 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005590:	1101                	addi	sp,sp,-32
    80005592:	ec06                	sd	ra,24(sp)
    80005594:	e822                	sd	s0,16(sp)
    80005596:	e426                	sd	s1,8(sp)
    80005598:	e04a                	sd	s2,0(sp)
    8000559a:	1000                	addi	s0,sp,32
    8000559c:	84aa                	mv	s1,a0
    8000559e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
  if(writable){
    800055a8:	02090d63          	beqz	s2,800055e2 <pipeclose+0x52>
    pi->writeopen = 0;
    800055ac:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800055b0:	21848513          	addi	a0,s1,536
    800055b4:	ffffd097          	auipc	ra,0xffffd
    800055b8:	710080e7          	jalr	1808(ra) # 80002cc4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800055bc:	2204b783          	ld	a5,544(s1)
    800055c0:	eb95                	bnez	a5,800055f4 <pipeclose+0x64>
    release(&pi->lock);
    800055c2:	8526                	mv	a0,s1
    800055c4:	ffffb097          	auipc	ra,0xffffb
    800055c8:	6e6080e7          	jalr	1766(ra) # 80000caa <release>
    kfree((char*)pi);
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffb097          	auipc	ra,0xffffb
    800055d2:	42a080e7          	jalr	1066(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800055d6:	60e2                	ld	ra,24(sp)
    800055d8:	6442                	ld	s0,16(sp)
    800055da:	64a2                	ld	s1,8(sp)
    800055dc:	6902                	ld	s2,0(sp)
    800055de:	6105                	addi	sp,sp,32
    800055e0:	8082                	ret
    pi->readopen = 0;
    800055e2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055e6:	21c48513          	addi	a0,s1,540
    800055ea:	ffffd097          	auipc	ra,0xffffd
    800055ee:	6da080e7          	jalr	1754(ra) # 80002cc4 <wakeup>
    800055f2:	b7e9                	j	800055bc <pipeclose+0x2c>
    release(&pi->lock);
    800055f4:	8526                	mv	a0,s1
    800055f6:	ffffb097          	auipc	ra,0xffffb
    800055fa:	6b4080e7          	jalr	1716(ra) # 80000caa <release>
}
    800055fe:	bfe1                	j	800055d6 <pipeclose+0x46>

0000000080005600 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005600:	7159                	addi	sp,sp,-112
    80005602:	f486                	sd	ra,104(sp)
    80005604:	f0a2                	sd	s0,96(sp)
    80005606:	eca6                	sd	s1,88(sp)
    80005608:	e8ca                	sd	s2,80(sp)
    8000560a:	e4ce                	sd	s3,72(sp)
    8000560c:	e0d2                	sd	s4,64(sp)
    8000560e:	fc56                	sd	s5,56(sp)
    80005610:	f85a                	sd	s6,48(sp)
    80005612:	f45e                	sd	s7,40(sp)
    80005614:	f062                	sd	s8,32(sp)
    80005616:	ec66                	sd	s9,24(sp)
    80005618:	1880                	addi	s0,sp,112
    8000561a:	84aa                	mv	s1,a0
    8000561c:	8aae                	mv	s5,a1
    8000561e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005620:	ffffd097          	auipc	ra,0xffffd
    80005624:	8a4080e7          	jalr	-1884(ra) # 80001ec4 <myproc>
    80005628:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffb097          	auipc	ra,0xffffb
    80005630:	5b8080e7          	jalr	1464(ra) # 80000be4 <acquire>
  while(i < n){
    80005634:	0d405163          	blez	s4,800056f6 <pipewrite+0xf6>
    80005638:	8ba6                	mv	s7,s1
  int i = 0;
    8000563a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000563c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000563e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005642:	21c48c13          	addi	s8,s1,540
    80005646:	a08d                	j	800056a8 <pipewrite+0xa8>
      release(&pi->lock);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	660080e7          	jalr	1632(ra) # 80000caa <release>
      return -1;
    80005652:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005654:	854a                	mv	a0,s2
    80005656:	70a6                	ld	ra,104(sp)
    80005658:	7406                	ld	s0,96(sp)
    8000565a:	64e6                	ld	s1,88(sp)
    8000565c:	6946                	ld	s2,80(sp)
    8000565e:	69a6                	ld	s3,72(sp)
    80005660:	6a06                	ld	s4,64(sp)
    80005662:	7ae2                	ld	s5,56(sp)
    80005664:	7b42                	ld	s6,48(sp)
    80005666:	7ba2                	ld	s7,40(sp)
    80005668:	7c02                	ld	s8,32(sp)
    8000566a:	6ce2                	ld	s9,24(sp)
    8000566c:	6165                	addi	sp,sp,112
    8000566e:	8082                	ret
      wakeup(&pi->nread);
    80005670:	8566                	mv	a0,s9
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	652080e7          	jalr	1618(ra) # 80002cc4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000567a:	85de                	mv	a1,s7
    8000567c:	8562                	mv	a0,s8
    8000567e:	ffffd097          	auipc	ra,0xffffd
    80005682:	412080e7          	jalr	1042(ra) # 80002a90 <sleep>
    80005686:	a839                	j	800056a4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005688:	21c4a783          	lw	a5,540(s1)
    8000568c:	0017871b          	addiw	a4,a5,1
    80005690:	20e4ae23          	sw	a4,540(s1)
    80005694:	1ff7f793          	andi	a5,a5,511
    80005698:	97a6                	add	a5,a5,s1
    8000569a:	f9f44703          	lbu	a4,-97(s0)
    8000569e:	00e78c23          	sb	a4,24(a5)
      i++;
    800056a2:	2905                	addiw	s2,s2,1
  while(i < n){
    800056a4:	03495d63          	bge	s2,s4,800056de <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800056a8:	2204a783          	lw	a5,544(s1)
    800056ac:	dfd1                	beqz	a5,80005648 <pipewrite+0x48>
    800056ae:	0289a783          	lw	a5,40(s3)
    800056b2:	fbd9                	bnez	a5,80005648 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800056b4:	2184a783          	lw	a5,536(s1)
    800056b8:	21c4a703          	lw	a4,540(s1)
    800056bc:	2007879b          	addiw	a5,a5,512
    800056c0:	faf708e3          	beq	a4,a5,80005670 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056c4:	4685                	li	a3,1
    800056c6:	01590633          	add	a2,s2,s5
    800056ca:	f9f40593          	addi	a1,s0,-97
    800056ce:	0709b503          	ld	a0,112(s3)
    800056d2:	ffffc097          	auipc	ra,0xffffc
    800056d6:	050080e7          	jalr	80(ra) # 80001722 <copyin>
    800056da:	fb6517e3          	bne	a0,s6,80005688 <pipewrite+0x88>
  wakeup(&pi->nread);
    800056de:	21848513          	addi	a0,s1,536
    800056e2:	ffffd097          	auipc	ra,0xffffd
    800056e6:	5e2080e7          	jalr	1506(ra) # 80002cc4 <wakeup>
  release(&pi->lock);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffb097          	auipc	ra,0xffffb
    800056f0:	5be080e7          	jalr	1470(ra) # 80000caa <release>
  return i;
    800056f4:	b785                	j	80005654 <pipewrite+0x54>
  int i = 0;
    800056f6:	4901                	li	s2,0
    800056f8:	b7dd                	j	800056de <pipewrite+0xde>

00000000800056fa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056fa:	715d                	addi	sp,sp,-80
    800056fc:	e486                	sd	ra,72(sp)
    800056fe:	e0a2                	sd	s0,64(sp)
    80005700:	fc26                	sd	s1,56(sp)
    80005702:	f84a                	sd	s2,48(sp)
    80005704:	f44e                	sd	s3,40(sp)
    80005706:	f052                	sd	s4,32(sp)
    80005708:	ec56                	sd	s5,24(sp)
    8000570a:	e85a                	sd	s6,16(sp)
    8000570c:	0880                	addi	s0,sp,80
    8000570e:	84aa                	mv	s1,a0
    80005710:	892e                	mv	s2,a1
    80005712:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005714:	ffffc097          	auipc	ra,0xffffc
    80005718:	7b0080e7          	jalr	1968(ra) # 80001ec4 <myproc>
    8000571c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000571e:	8b26                	mv	s6,s1
    80005720:	8526                	mv	a0,s1
    80005722:	ffffb097          	auipc	ra,0xffffb
    80005726:	4c2080e7          	jalr	1218(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000572a:	2184a703          	lw	a4,536(s1)
    8000572e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005732:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005736:	02f71463          	bne	a4,a5,8000575e <piperead+0x64>
    8000573a:	2244a783          	lw	a5,548(s1)
    8000573e:	c385                	beqz	a5,8000575e <piperead+0x64>
    if(pr->killed){
    80005740:	028a2783          	lw	a5,40(s4)
    80005744:	ebc1                	bnez	a5,800057d4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005746:	85da                	mv	a1,s6
    80005748:	854e                	mv	a0,s3
    8000574a:	ffffd097          	auipc	ra,0xffffd
    8000574e:	346080e7          	jalr	838(ra) # 80002a90 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005752:	2184a703          	lw	a4,536(s1)
    80005756:	21c4a783          	lw	a5,540(s1)
    8000575a:	fef700e3          	beq	a4,a5,8000573a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000575e:	09505263          	blez	s5,800057e2 <piperead+0xe8>
    80005762:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005764:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005766:	2184a783          	lw	a5,536(s1)
    8000576a:	21c4a703          	lw	a4,540(s1)
    8000576e:	02f70d63          	beq	a4,a5,800057a8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005772:	0017871b          	addiw	a4,a5,1
    80005776:	20e4ac23          	sw	a4,536(s1)
    8000577a:	1ff7f793          	andi	a5,a5,511
    8000577e:	97a6                	add	a5,a5,s1
    80005780:	0187c783          	lbu	a5,24(a5)
    80005784:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005788:	4685                	li	a3,1
    8000578a:	fbf40613          	addi	a2,s0,-65
    8000578e:	85ca                	mv	a1,s2
    80005790:	070a3503          	ld	a0,112(s4)
    80005794:	ffffc097          	auipc	ra,0xffffc
    80005798:	f02080e7          	jalr	-254(ra) # 80001696 <copyout>
    8000579c:	01650663          	beq	a0,s6,800057a8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057a0:	2985                	addiw	s3,s3,1
    800057a2:	0905                	addi	s2,s2,1
    800057a4:	fd3a91e3          	bne	s5,s3,80005766 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800057a8:	21c48513          	addi	a0,s1,540
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	518080e7          	jalr	1304(ra) # 80002cc4 <wakeup>
  release(&pi->lock);
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffb097          	auipc	ra,0xffffb
    800057ba:	4f4080e7          	jalr	1268(ra) # 80000caa <release>
  return i;
}
    800057be:	854e                	mv	a0,s3
    800057c0:	60a6                	ld	ra,72(sp)
    800057c2:	6406                	ld	s0,64(sp)
    800057c4:	74e2                	ld	s1,56(sp)
    800057c6:	7942                	ld	s2,48(sp)
    800057c8:	79a2                	ld	s3,40(sp)
    800057ca:	7a02                	ld	s4,32(sp)
    800057cc:	6ae2                	ld	s5,24(sp)
    800057ce:	6b42                	ld	s6,16(sp)
    800057d0:	6161                	addi	sp,sp,80
    800057d2:	8082                	ret
      release(&pi->lock);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffb097          	auipc	ra,0xffffb
    800057da:	4d4080e7          	jalr	1236(ra) # 80000caa <release>
      return -1;
    800057de:	59fd                	li	s3,-1
    800057e0:	bff9                	j	800057be <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057e2:	4981                	li	s3,0
    800057e4:	b7d1                	j	800057a8 <piperead+0xae>

00000000800057e6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800057e6:	df010113          	addi	sp,sp,-528
    800057ea:	20113423          	sd	ra,520(sp)
    800057ee:	20813023          	sd	s0,512(sp)
    800057f2:	ffa6                	sd	s1,504(sp)
    800057f4:	fbca                	sd	s2,496(sp)
    800057f6:	f7ce                	sd	s3,488(sp)
    800057f8:	f3d2                	sd	s4,480(sp)
    800057fa:	efd6                	sd	s5,472(sp)
    800057fc:	ebda                	sd	s6,464(sp)
    800057fe:	e7de                	sd	s7,456(sp)
    80005800:	e3e2                	sd	s8,448(sp)
    80005802:	ff66                	sd	s9,440(sp)
    80005804:	fb6a                	sd	s10,432(sp)
    80005806:	f76e                	sd	s11,424(sp)
    80005808:	0c00                	addi	s0,sp,528
    8000580a:	84aa                	mv	s1,a0
    8000580c:	dea43c23          	sd	a0,-520(s0)
    80005810:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005814:	ffffc097          	auipc	ra,0xffffc
    80005818:	6b0080e7          	jalr	1712(ra) # 80001ec4 <myproc>
    8000581c:	892a                	mv	s2,a0

  begin_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	49c080e7          	jalr	1180(ra) # 80004cba <begin_op>

  if((ip = namei(path)) == 0){
    80005826:	8526                	mv	a0,s1
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	276080e7          	jalr	630(ra) # 80004a9e <namei>
    80005830:	c92d                	beqz	a0,800058a2 <exec+0xbc>
    80005832:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	ab4080e7          	jalr	-1356(ra) # 800042e8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000583c:	04000713          	li	a4,64
    80005840:	4681                	li	a3,0
    80005842:	e5040613          	addi	a2,s0,-432
    80005846:	4581                	li	a1,0
    80005848:	8526                	mv	a0,s1
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	d52080e7          	jalr	-686(ra) # 8000459c <readi>
    80005852:	04000793          	li	a5,64
    80005856:	00f51a63          	bne	a0,a5,8000586a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000585a:	e5042703          	lw	a4,-432(s0)
    8000585e:	464c47b7          	lui	a5,0x464c4
    80005862:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005866:	04f70463          	beq	a4,a5,800058ae <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000586a:	8526                	mv	a0,s1
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	cde080e7          	jalr	-802(ra) # 8000454a <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	4c6080e7          	jalr	1222(ra) # 80004d3a <end_op>
  }
  return -1;
    8000587c:	557d                	li	a0,-1
}
    8000587e:	20813083          	ld	ra,520(sp)
    80005882:	20013403          	ld	s0,512(sp)
    80005886:	74fe                	ld	s1,504(sp)
    80005888:	795e                	ld	s2,496(sp)
    8000588a:	79be                	ld	s3,488(sp)
    8000588c:	7a1e                	ld	s4,480(sp)
    8000588e:	6afe                	ld	s5,472(sp)
    80005890:	6b5e                	ld	s6,464(sp)
    80005892:	6bbe                	ld	s7,456(sp)
    80005894:	6c1e                	ld	s8,448(sp)
    80005896:	7cfa                	ld	s9,440(sp)
    80005898:	7d5a                	ld	s10,432(sp)
    8000589a:	7dba                	ld	s11,424(sp)
    8000589c:	21010113          	addi	sp,sp,528
    800058a0:	8082                	ret
    end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	498080e7          	jalr	1176(ra) # 80004d3a <end_op>
    return -1;
    800058aa:	557d                	li	a0,-1
    800058ac:	bfc9                	j	8000587e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800058ae:	854a                	mv	a0,s2
    800058b0:	ffffc097          	auipc	ra,0xffffc
    800058b4:	6ca080e7          	jalr	1738(ra) # 80001f7a <proc_pagetable>
    800058b8:	8baa                	mv	s7,a0
    800058ba:	d945                	beqz	a0,8000586a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058bc:	e7042983          	lw	s3,-400(s0)
    800058c0:	e8845783          	lhu	a5,-376(s0)
    800058c4:	c7ad                	beqz	a5,8000592e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058c6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058c8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800058ca:	6c85                	lui	s9,0x1
    800058cc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800058d0:	def43823          	sd	a5,-528(s0)
    800058d4:	a42d                	j	80005afe <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800058d6:	00003517          	auipc	a0,0x3
    800058da:	64250513          	addi	a0,a0,1602 # 80008f18 <syscalls+0x280>
    800058de:	ffffb097          	auipc	ra,0xffffb
    800058e2:	c60080e7          	jalr	-928(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800058e6:	8756                	mv	a4,s5
    800058e8:	012d86bb          	addw	a3,s11,s2
    800058ec:	4581                	li	a1,0
    800058ee:	8526                	mv	a0,s1
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	cac080e7          	jalr	-852(ra) # 8000459c <readi>
    800058f8:	2501                	sext.w	a0,a0
    800058fa:	1aaa9963          	bne	s5,a0,80005aac <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800058fe:	6785                	lui	a5,0x1
    80005900:	0127893b          	addw	s2,a5,s2
    80005904:	77fd                	lui	a5,0xfffff
    80005906:	01478a3b          	addw	s4,a5,s4
    8000590a:	1f897163          	bgeu	s2,s8,80005aec <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000590e:	02091593          	slli	a1,s2,0x20
    80005912:	9181                	srli	a1,a1,0x20
    80005914:	95ea                	add	a1,a1,s10
    80005916:	855e                	mv	a0,s7
    80005918:	ffffb097          	auipc	ra,0xffffb
    8000591c:	77a080e7          	jalr	1914(ra) # 80001092 <walkaddr>
    80005920:	862a                	mv	a2,a0
    if(pa == 0)
    80005922:	d955                	beqz	a0,800058d6 <exec+0xf0>
      n = PGSIZE;
    80005924:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005926:	fd9a70e3          	bgeu	s4,s9,800058e6 <exec+0x100>
      n = sz - i;
    8000592a:	8ad2                	mv	s5,s4
    8000592c:	bf6d                	j	800058e6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000592e:	4901                	li	s2,0
  iunlockput(ip);
    80005930:	8526                	mv	a0,s1
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	c18080e7          	jalr	-1000(ra) # 8000454a <iunlockput>
  end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	400080e7          	jalr	1024(ra) # 80004d3a <end_op>
  p = myproc();
    80005942:	ffffc097          	auipc	ra,0xffffc
    80005946:	582080e7          	jalr	1410(ra) # 80001ec4 <myproc>
    8000594a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000594c:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005950:	6785                	lui	a5,0x1
    80005952:	17fd                	addi	a5,a5,-1
    80005954:	993e                	add	s2,s2,a5
    80005956:	757d                	lui	a0,0xfffff
    80005958:	00a977b3          	and	a5,s2,a0
    8000595c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005960:	6609                	lui	a2,0x2
    80005962:	963e                	add	a2,a2,a5
    80005964:	85be                	mv	a1,a5
    80005966:	855e                	mv	a0,s7
    80005968:	ffffc097          	auipc	ra,0xffffc
    8000596c:	ade080e7          	jalr	-1314(ra) # 80001446 <uvmalloc>
    80005970:	8b2a                	mv	s6,a0
  ip = 0;
    80005972:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005974:	12050c63          	beqz	a0,80005aac <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005978:	75f9                	lui	a1,0xffffe
    8000597a:	95aa                	add	a1,a1,a0
    8000597c:	855e                	mv	a0,s7
    8000597e:	ffffc097          	auipc	ra,0xffffc
    80005982:	ce6080e7          	jalr	-794(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    80005986:	7c7d                	lui	s8,0xfffff
    80005988:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000598a:	e0043783          	ld	a5,-512(s0)
    8000598e:	6388                	ld	a0,0(a5)
    80005990:	c535                	beqz	a0,800059fc <exec+0x216>
    80005992:	e9040993          	addi	s3,s0,-368
    80005996:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000599a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	4ec080e7          	jalr	1260(ra) # 80000e88 <strlen>
    800059a4:	2505                	addiw	a0,a0,1
    800059a6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800059aa:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800059ae:	13896363          	bltu	s2,s8,80005ad4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800059b2:	e0043d83          	ld	s11,-512(s0)
    800059b6:	000dba03          	ld	s4,0(s11)
    800059ba:	8552                	mv	a0,s4
    800059bc:	ffffb097          	auipc	ra,0xffffb
    800059c0:	4cc080e7          	jalr	1228(ra) # 80000e88 <strlen>
    800059c4:	0015069b          	addiw	a3,a0,1
    800059c8:	8652                	mv	a2,s4
    800059ca:	85ca                	mv	a1,s2
    800059cc:	855e                	mv	a0,s7
    800059ce:	ffffc097          	auipc	ra,0xffffc
    800059d2:	cc8080e7          	jalr	-824(ra) # 80001696 <copyout>
    800059d6:	10054363          	bltz	a0,80005adc <exec+0x2f6>
    ustack[argc] = sp;
    800059da:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800059de:	0485                	addi	s1,s1,1
    800059e0:	008d8793          	addi	a5,s11,8
    800059e4:	e0f43023          	sd	a5,-512(s0)
    800059e8:	008db503          	ld	a0,8(s11)
    800059ec:	c911                	beqz	a0,80005a00 <exec+0x21a>
    if(argc >= MAXARG)
    800059ee:	09a1                	addi	s3,s3,8
    800059f0:	fb3c96e3          	bne	s9,s3,8000599c <exec+0x1b6>
  sz = sz1;
    800059f4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059f8:	4481                	li	s1,0
    800059fa:	a84d                	j	80005aac <exec+0x2c6>
  sp = sz;
    800059fc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800059fe:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a00:	00349793          	slli	a5,s1,0x3
    80005a04:	f9040713          	addi	a4,s0,-112
    80005a08:	97ba                	add	a5,a5,a4
    80005a0a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005a0e:	00148693          	addi	a3,s1,1
    80005a12:	068e                	slli	a3,a3,0x3
    80005a14:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a18:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a1c:	01897663          	bgeu	s2,s8,80005a28 <exec+0x242>
  sz = sz1;
    80005a20:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a24:	4481                	li	s1,0
    80005a26:	a059                	j	80005aac <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a28:	e9040613          	addi	a2,s0,-368
    80005a2c:	85ca                	mv	a1,s2
    80005a2e:	855e                	mv	a0,s7
    80005a30:	ffffc097          	auipc	ra,0xffffc
    80005a34:	c66080e7          	jalr	-922(ra) # 80001696 <copyout>
    80005a38:	0a054663          	bltz	a0,80005ae4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005a3c:	078ab783          	ld	a5,120(s5)
    80005a40:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a44:	df843783          	ld	a5,-520(s0)
    80005a48:	0007c703          	lbu	a4,0(a5)
    80005a4c:	cf11                	beqz	a4,80005a68 <exec+0x282>
    80005a4e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a50:	02f00693          	li	a3,47
    80005a54:	a039                	j	80005a62 <exec+0x27c>
      last = s+1;
    80005a56:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a5a:	0785                	addi	a5,a5,1
    80005a5c:	fff7c703          	lbu	a4,-1(a5)
    80005a60:	c701                	beqz	a4,80005a68 <exec+0x282>
    if(*s == '/')
    80005a62:	fed71ce3          	bne	a4,a3,80005a5a <exec+0x274>
    80005a66:	bfc5                	j	80005a56 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a68:	4641                	li	a2,16
    80005a6a:	df843583          	ld	a1,-520(s0)
    80005a6e:	178a8513          	addi	a0,s5,376
    80005a72:	ffffb097          	auipc	ra,0xffffb
    80005a76:	3e4080e7          	jalr	996(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a7a:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005a7e:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005a82:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a86:	078ab783          	ld	a5,120(s5)
    80005a8a:	e6843703          	ld	a4,-408(s0)
    80005a8e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a90:	078ab783          	ld	a5,120(s5)
    80005a94:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a98:	85ea                	mv	a1,s10
    80005a9a:	ffffc097          	auipc	ra,0xffffc
    80005a9e:	57c080e7          	jalr	1404(ra) # 80002016 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005aa2:	0004851b          	sext.w	a0,s1
    80005aa6:	bbe1                	j	8000587e <exec+0x98>
    80005aa8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005aac:	e0843583          	ld	a1,-504(s0)
    80005ab0:	855e                	mv	a0,s7
    80005ab2:	ffffc097          	auipc	ra,0xffffc
    80005ab6:	564080e7          	jalr	1380(ra) # 80002016 <proc_freepagetable>
  if(ip){
    80005aba:	da0498e3          	bnez	s1,8000586a <exec+0x84>
  return -1;
    80005abe:	557d                	li	a0,-1
    80005ac0:	bb7d                	j	8000587e <exec+0x98>
    80005ac2:	e1243423          	sd	s2,-504(s0)
    80005ac6:	b7dd                	j	80005aac <exec+0x2c6>
    80005ac8:	e1243423          	sd	s2,-504(s0)
    80005acc:	b7c5                	j	80005aac <exec+0x2c6>
    80005ace:	e1243423          	sd	s2,-504(s0)
    80005ad2:	bfe9                	j	80005aac <exec+0x2c6>
  sz = sz1;
    80005ad4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ad8:	4481                	li	s1,0
    80005ada:	bfc9                	j	80005aac <exec+0x2c6>
  sz = sz1;
    80005adc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ae0:	4481                	li	s1,0
    80005ae2:	b7e9                	j	80005aac <exec+0x2c6>
  sz = sz1;
    80005ae4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ae8:	4481                	li	s1,0
    80005aea:	b7c9                	j	80005aac <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005aec:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005af0:	2b05                	addiw	s6,s6,1
    80005af2:	0389899b          	addiw	s3,s3,56
    80005af6:	e8845783          	lhu	a5,-376(s0)
    80005afa:	e2fb5be3          	bge	s6,a5,80005930 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005afe:	2981                	sext.w	s3,s3
    80005b00:	03800713          	li	a4,56
    80005b04:	86ce                	mv	a3,s3
    80005b06:	e1840613          	addi	a2,s0,-488
    80005b0a:	4581                	li	a1,0
    80005b0c:	8526                	mv	a0,s1
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	a8e080e7          	jalr	-1394(ra) # 8000459c <readi>
    80005b16:	03800793          	li	a5,56
    80005b1a:	f8f517e3          	bne	a0,a5,80005aa8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005b1e:	e1842783          	lw	a5,-488(s0)
    80005b22:	4705                	li	a4,1
    80005b24:	fce796e3          	bne	a5,a4,80005af0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005b28:	e4043603          	ld	a2,-448(s0)
    80005b2c:	e3843783          	ld	a5,-456(s0)
    80005b30:	f8f669e3          	bltu	a2,a5,80005ac2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005b34:	e2843783          	ld	a5,-472(s0)
    80005b38:	963e                	add	a2,a2,a5
    80005b3a:	f8f667e3          	bltu	a2,a5,80005ac8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b3e:	85ca                	mv	a1,s2
    80005b40:	855e                	mv	a0,s7
    80005b42:	ffffc097          	auipc	ra,0xffffc
    80005b46:	904080e7          	jalr	-1788(ra) # 80001446 <uvmalloc>
    80005b4a:	e0a43423          	sd	a0,-504(s0)
    80005b4e:	d141                	beqz	a0,80005ace <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005b50:	e2843d03          	ld	s10,-472(s0)
    80005b54:	df043783          	ld	a5,-528(s0)
    80005b58:	00fd77b3          	and	a5,s10,a5
    80005b5c:	fba1                	bnez	a5,80005aac <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b5e:	e2042d83          	lw	s11,-480(s0)
    80005b62:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b66:	f80c03e3          	beqz	s8,80005aec <exec+0x306>
    80005b6a:	8a62                	mv	s4,s8
    80005b6c:	4901                	li	s2,0
    80005b6e:	b345                	j	8000590e <exec+0x128>

0000000080005b70 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b70:	7179                	addi	sp,sp,-48
    80005b72:	f406                	sd	ra,40(sp)
    80005b74:	f022                	sd	s0,32(sp)
    80005b76:	ec26                	sd	s1,24(sp)
    80005b78:	e84a                	sd	s2,16(sp)
    80005b7a:	1800                	addi	s0,sp,48
    80005b7c:	892e                	mv	s2,a1
    80005b7e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005b80:	fdc40593          	addi	a1,s0,-36
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	bf2080e7          	jalr	-1038(ra) # 80003776 <argint>
    80005b8c:	04054063          	bltz	a0,80005bcc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b90:	fdc42703          	lw	a4,-36(s0)
    80005b94:	47bd                	li	a5,15
    80005b96:	02e7ed63          	bltu	a5,a4,80005bd0 <argfd+0x60>
    80005b9a:	ffffc097          	auipc	ra,0xffffc
    80005b9e:	32a080e7          	jalr	810(ra) # 80001ec4 <myproc>
    80005ba2:	fdc42703          	lw	a4,-36(s0)
    80005ba6:	01e70793          	addi	a5,a4,30
    80005baa:	078e                	slli	a5,a5,0x3
    80005bac:	953e                	add	a0,a0,a5
    80005bae:	611c                	ld	a5,0(a0)
    80005bb0:	c395                	beqz	a5,80005bd4 <argfd+0x64>
    return -1;
  if(pfd)
    80005bb2:	00090463          	beqz	s2,80005bba <argfd+0x4a>
    *pfd = fd;
    80005bb6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005bba:	4501                	li	a0,0
  if(pf)
    80005bbc:	c091                	beqz	s1,80005bc0 <argfd+0x50>
    *pf = f;
    80005bbe:	e09c                	sd	a5,0(s1)
}
    80005bc0:	70a2                	ld	ra,40(sp)
    80005bc2:	7402                	ld	s0,32(sp)
    80005bc4:	64e2                	ld	s1,24(sp)
    80005bc6:	6942                	ld	s2,16(sp)
    80005bc8:	6145                	addi	sp,sp,48
    80005bca:	8082                	ret
    return -1;
    80005bcc:	557d                	li	a0,-1
    80005bce:	bfcd                	j	80005bc0 <argfd+0x50>
    return -1;
    80005bd0:	557d                	li	a0,-1
    80005bd2:	b7fd                	j	80005bc0 <argfd+0x50>
    80005bd4:	557d                	li	a0,-1
    80005bd6:	b7ed                	j	80005bc0 <argfd+0x50>

0000000080005bd8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005bd8:	1101                	addi	sp,sp,-32
    80005bda:	ec06                	sd	ra,24(sp)
    80005bdc:	e822                	sd	s0,16(sp)
    80005bde:	e426                	sd	s1,8(sp)
    80005be0:	1000                	addi	s0,sp,32
    80005be2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005be4:	ffffc097          	auipc	ra,0xffffc
    80005be8:	2e0080e7          	jalr	736(ra) # 80001ec4 <myproc>
    80005bec:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005bee:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffdf0f0>
    80005bf2:	4501                	li	a0,0
    80005bf4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005bf6:	6398                	ld	a4,0(a5)
    80005bf8:	cb19                	beqz	a4,80005c0e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005bfa:	2505                	addiw	a0,a0,1
    80005bfc:	07a1                	addi	a5,a5,8
    80005bfe:	fed51ce3          	bne	a0,a3,80005bf6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c02:	557d                	li	a0,-1
}
    80005c04:	60e2                	ld	ra,24(sp)
    80005c06:	6442                	ld	s0,16(sp)
    80005c08:	64a2                	ld	s1,8(sp)
    80005c0a:	6105                	addi	sp,sp,32
    80005c0c:	8082                	ret
      p->ofile[fd] = f;
    80005c0e:	01e50793          	addi	a5,a0,30
    80005c12:	078e                	slli	a5,a5,0x3
    80005c14:	963e                	add	a2,a2,a5
    80005c16:	e204                	sd	s1,0(a2)
      return fd;
    80005c18:	b7f5                	j	80005c04 <fdalloc+0x2c>

0000000080005c1a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c1a:	715d                	addi	sp,sp,-80
    80005c1c:	e486                	sd	ra,72(sp)
    80005c1e:	e0a2                	sd	s0,64(sp)
    80005c20:	fc26                	sd	s1,56(sp)
    80005c22:	f84a                	sd	s2,48(sp)
    80005c24:	f44e                	sd	s3,40(sp)
    80005c26:	f052                	sd	s4,32(sp)
    80005c28:	ec56                	sd	s5,24(sp)
    80005c2a:	0880                	addi	s0,sp,80
    80005c2c:	89ae                	mv	s3,a1
    80005c2e:	8ab2                	mv	s5,a2
    80005c30:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005c32:	fb040593          	addi	a1,s0,-80
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	e86080e7          	jalr	-378(ra) # 80004abc <nameiparent>
    80005c3e:	892a                	mv	s2,a0
    80005c40:	12050f63          	beqz	a0,80005d7e <create+0x164>
    return 0;

  ilock(dp);
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	6a4080e7          	jalr	1700(ra) # 800042e8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c4c:	4601                	li	a2,0
    80005c4e:	fb040593          	addi	a1,s0,-80
    80005c52:	854a                	mv	a0,s2
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	b78080e7          	jalr	-1160(ra) # 800047cc <dirlookup>
    80005c5c:	84aa                	mv	s1,a0
    80005c5e:	c921                	beqz	a0,80005cae <create+0x94>
    iunlockput(dp);
    80005c60:	854a                	mv	a0,s2
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	8e8080e7          	jalr	-1816(ra) # 8000454a <iunlockput>
    ilock(ip);
    80005c6a:	8526                	mv	a0,s1
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	67c080e7          	jalr	1660(ra) # 800042e8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c74:	2981                	sext.w	s3,s3
    80005c76:	4789                	li	a5,2
    80005c78:	02f99463          	bne	s3,a5,80005ca0 <create+0x86>
    80005c7c:	0444d783          	lhu	a5,68(s1)
    80005c80:	37f9                	addiw	a5,a5,-2
    80005c82:	17c2                	slli	a5,a5,0x30
    80005c84:	93c1                	srli	a5,a5,0x30
    80005c86:	4705                	li	a4,1
    80005c88:	00f76c63          	bltu	a4,a5,80005ca0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005c8c:	8526                	mv	a0,s1
    80005c8e:	60a6                	ld	ra,72(sp)
    80005c90:	6406                	ld	s0,64(sp)
    80005c92:	74e2                	ld	s1,56(sp)
    80005c94:	7942                	ld	s2,48(sp)
    80005c96:	79a2                	ld	s3,40(sp)
    80005c98:	7a02                	ld	s4,32(sp)
    80005c9a:	6ae2                	ld	s5,24(sp)
    80005c9c:	6161                	addi	sp,sp,80
    80005c9e:	8082                	ret
    iunlockput(ip);
    80005ca0:	8526                	mv	a0,s1
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	8a8080e7          	jalr	-1880(ra) # 8000454a <iunlockput>
    return 0;
    80005caa:	4481                	li	s1,0
    80005cac:	b7c5                	j	80005c8c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005cae:	85ce                	mv	a1,s3
    80005cb0:	00092503          	lw	a0,0(s2)
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	49c080e7          	jalr	1180(ra) # 80004150 <ialloc>
    80005cbc:	84aa                	mv	s1,a0
    80005cbe:	c529                	beqz	a0,80005d08 <create+0xee>
  ilock(ip);
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	628080e7          	jalr	1576(ra) # 800042e8 <ilock>
  ip->major = major;
    80005cc8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005ccc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005cd0:	4785                	li	a5,1
    80005cd2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	546080e7          	jalr	1350(ra) # 8000421e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005ce0:	2981                	sext.w	s3,s3
    80005ce2:	4785                	li	a5,1
    80005ce4:	02f98a63          	beq	s3,a5,80005d18 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ce8:	40d0                	lw	a2,4(s1)
    80005cea:	fb040593          	addi	a1,s0,-80
    80005cee:	854a                	mv	a0,s2
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	cec080e7          	jalr	-788(ra) # 800049dc <dirlink>
    80005cf8:	06054b63          	bltz	a0,80005d6e <create+0x154>
  iunlockput(dp);
    80005cfc:	854a                	mv	a0,s2
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	84c080e7          	jalr	-1972(ra) # 8000454a <iunlockput>
  return ip;
    80005d06:	b759                	j	80005c8c <create+0x72>
    panic("create: ialloc");
    80005d08:	00003517          	auipc	a0,0x3
    80005d0c:	23050513          	addi	a0,a0,560 # 80008f38 <syscalls+0x2a0>
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	82e080e7          	jalr	-2002(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005d18:	04a95783          	lhu	a5,74(s2)
    80005d1c:	2785                	addiw	a5,a5,1
    80005d1e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005d22:	854a                	mv	a0,s2
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	4fa080e7          	jalr	1274(ra) # 8000421e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d2c:	40d0                	lw	a2,4(s1)
    80005d2e:	00003597          	auipc	a1,0x3
    80005d32:	21a58593          	addi	a1,a1,538 # 80008f48 <syscalls+0x2b0>
    80005d36:	8526                	mv	a0,s1
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	ca4080e7          	jalr	-860(ra) # 800049dc <dirlink>
    80005d40:	00054f63          	bltz	a0,80005d5e <create+0x144>
    80005d44:	00492603          	lw	a2,4(s2)
    80005d48:	00003597          	auipc	a1,0x3
    80005d4c:	20858593          	addi	a1,a1,520 # 80008f50 <syscalls+0x2b8>
    80005d50:	8526                	mv	a0,s1
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	c8a080e7          	jalr	-886(ra) # 800049dc <dirlink>
    80005d5a:	f80557e3          	bgez	a0,80005ce8 <create+0xce>
      panic("create dots");
    80005d5e:	00003517          	auipc	a0,0x3
    80005d62:	1fa50513          	addi	a0,a0,506 # 80008f58 <syscalls+0x2c0>
    80005d66:	ffffa097          	auipc	ra,0xffffa
    80005d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005d6e:	00003517          	auipc	a0,0x3
    80005d72:	1fa50513          	addi	a0,a0,506 # 80008f68 <syscalls+0x2d0>
    80005d76:	ffffa097          	auipc	ra,0xffffa
    80005d7a:	7c8080e7          	jalr	1992(ra) # 8000053e <panic>
    return 0;
    80005d7e:	84aa                	mv	s1,a0
    80005d80:	b731                	j	80005c8c <create+0x72>

0000000080005d82 <sys_dup>:
{
    80005d82:	7179                	addi	sp,sp,-48
    80005d84:	f406                	sd	ra,40(sp)
    80005d86:	f022                	sd	s0,32(sp)
    80005d88:	ec26                	sd	s1,24(sp)
    80005d8a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d8c:	fd840613          	addi	a2,s0,-40
    80005d90:	4581                	li	a1,0
    80005d92:	4501                	li	a0,0
    80005d94:	00000097          	auipc	ra,0x0
    80005d98:	ddc080e7          	jalr	-548(ra) # 80005b70 <argfd>
    return -1;
    80005d9c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d9e:	02054363          	bltz	a0,80005dc4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005da2:	fd843503          	ld	a0,-40(s0)
    80005da6:	00000097          	auipc	ra,0x0
    80005daa:	e32080e7          	jalr	-462(ra) # 80005bd8 <fdalloc>
    80005dae:	84aa                	mv	s1,a0
    return -1;
    80005db0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005db2:	00054963          	bltz	a0,80005dc4 <sys_dup+0x42>
  filedup(f);
    80005db6:	fd843503          	ld	a0,-40(s0)
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	37a080e7          	jalr	890(ra) # 80005134 <filedup>
  return fd;
    80005dc2:	87a6                	mv	a5,s1
}
    80005dc4:	853e                	mv	a0,a5
    80005dc6:	70a2                	ld	ra,40(sp)
    80005dc8:	7402                	ld	s0,32(sp)
    80005dca:	64e2                	ld	s1,24(sp)
    80005dcc:	6145                	addi	sp,sp,48
    80005dce:	8082                	ret

0000000080005dd0 <sys_read>:
{
    80005dd0:	7179                	addi	sp,sp,-48
    80005dd2:	f406                	sd	ra,40(sp)
    80005dd4:	f022                	sd	s0,32(sp)
    80005dd6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dd8:	fe840613          	addi	a2,s0,-24
    80005ddc:	4581                	li	a1,0
    80005dde:	4501                	li	a0,0
    80005de0:	00000097          	auipc	ra,0x0
    80005de4:	d90080e7          	jalr	-624(ra) # 80005b70 <argfd>
    return -1;
    80005de8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dea:	04054163          	bltz	a0,80005e2c <sys_read+0x5c>
    80005dee:	fe440593          	addi	a1,s0,-28
    80005df2:	4509                	li	a0,2
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	982080e7          	jalr	-1662(ra) # 80003776 <argint>
    return -1;
    80005dfc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dfe:	02054763          	bltz	a0,80005e2c <sys_read+0x5c>
    80005e02:	fd840593          	addi	a1,s0,-40
    80005e06:	4505                	li	a0,1
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	990080e7          	jalr	-1648(ra) # 80003798 <argaddr>
    return -1;
    80005e10:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e12:	00054d63          	bltz	a0,80005e2c <sys_read+0x5c>
  return fileread(f, p, n);
    80005e16:	fe442603          	lw	a2,-28(s0)
    80005e1a:	fd843583          	ld	a1,-40(s0)
    80005e1e:	fe843503          	ld	a0,-24(s0)
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	49e080e7          	jalr	1182(ra) # 800052c0 <fileread>
    80005e2a:	87aa                	mv	a5,a0
}
    80005e2c:	853e                	mv	a0,a5
    80005e2e:	70a2                	ld	ra,40(sp)
    80005e30:	7402                	ld	s0,32(sp)
    80005e32:	6145                	addi	sp,sp,48
    80005e34:	8082                	ret

0000000080005e36 <sys_write>:
{
    80005e36:	7179                	addi	sp,sp,-48
    80005e38:	f406                	sd	ra,40(sp)
    80005e3a:	f022                	sd	s0,32(sp)
    80005e3c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e3e:	fe840613          	addi	a2,s0,-24
    80005e42:	4581                	li	a1,0
    80005e44:	4501                	li	a0,0
    80005e46:	00000097          	auipc	ra,0x0
    80005e4a:	d2a080e7          	jalr	-726(ra) # 80005b70 <argfd>
    return -1;
    80005e4e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e50:	04054163          	bltz	a0,80005e92 <sys_write+0x5c>
    80005e54:	fe440593          	addi	a1,s0,-28
    80005e58:	4509                	li	a0,2
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	91c080e7          	jalr	-1764(ra) # 80003776 <argint>
    return -1;
    80005e62:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e64:	02054763          	bltz	a0,80005e92 <sys_write+0x5c>
    80005e68:	fd840593          	addi	a1,s0,-40
    80005e6c:	4505                	li	a0,1
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	92a080e7          	jalr	-1750(ra) # 80003798 <argaddr>
    return -1;
    80005e76:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e78:	00054d63          	bltz	a0,80005e92 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005e7c:	fe442603          	lw	a2,-28(s0)
    80005e80:	fd843583          	ld	a1,-40(s0)
    80005e84:	fe843503          	ld	a0,-24(s0)
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	4fa080e7          	jalr	1274(ra) # 80005382 <filewrite>
    80005e90:	87aa                	mv	a5,a0
}
    80005e92:	853e                	mv	a0,a5
    80005e94:	70a2                	ld	ra,40(sp)
    80005e96:	7402                	ld	s0,32(sp)
    80005e98:	6145                	addi	sp,sp,48
    80005e9a:	8082                	ret

0000000080005e9c <sys_close>:
{
    80005e9c:	1101                	addi	sp,sp,-32
    80005e9e:	ec06                	sd	ra,24(sp)
    80005ea0:	e822                	sd	s0,16(sp)
    80005ea2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ea4:	fe040613          	addi	a2,s0,-32
    80005ea8:	fec40593          	addi	a1,s0,-20
    80005eac:	4501                	li	a0,0
    80005eae:	00000097          	auipc	ra,0x0
    80005eb2:	cc2080e7          	jalr	-830(ra) # 80005b70 <argfd>
    return -1;
    80005eb6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005eb8:	02054463          	bltz	a0,80005ee0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ebc:	ffffc097          	auipc	ra,0xffffc
    80005ec0:	008080e7          	jalr	8(ra) # 80001ec4 <myproc>
    80005ec4:	fec42783          	lw	a5,-20(s0)
    80005ec8:	07f9                	addi	a5,a5,30
    80005eca:	078e                	slli	a5,a5,0x3
    80005ecc:	97aa                	add	a5,a5,a0
    80005ece:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005ed2:	fe043503          	ld	a0,-32(s0)
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	2b0080e7          	jalr	688(ra) # 80005186 <fileclose>
  return 0;
    80005ede:	4781                	li	a5,0
}
    80005ee0:	853e                	mv	a0,a5
    80005ee2:	60e2                	ld	ra,24(sp)
    80005ee4:	6442                	ld	s0,16(sp)
    80005ee6:	6105                	addi	sp,sp,32
    80005ee8:	8082                	ret

0000000080005eea <sys_fstat>:
{
    80005eea:	1101                	addi	sp,sp,-32
    80005eec:	ec06                	sd	ra,24(sp)
    80005eee:	e822                	sd	s0,16(sp)
    80005ef0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ef2:	fe840613          	addi	a2,s0,-24
    80005ef6:	4581                	li	a1,0
    80005ef8:	4501                	li	a0,0
    80005efa:	00000097          	auipc	ra,0x0
    80005efe:	c76080e7          	jalr	-906(ra) # 80005b70 <argfd>
    return -1;
    80005f02:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f04:	02054563          	bltz	a0,80005f2e <sys_fstat+0x44>
    80005f08:	fe040593          	addi	a1,s0,-32
    80005f0c:	4505                	li	a0,1
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	88a080e7          	jalr	-1910(ra) # 80003798 <argaddr>
    return -1;
    80005f16:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f18:	00054b63          	bltz	a0,80005f2e <sys_fstat+0x44>
  return filestat(f, st);
    80005f1c:	fe043583          	ld	a1,-32(s0)
    80005f20:	fe843503          	ld	a0,-24(s0)
    80005f24:	fffff097          	auipc	ra,0xfffff
    80005f28:	32a080e7          	jalr	810(ra) # 8000524e <filestat>
    80005f2c:	87aa                	mv	a5,a0
}
    80005f2e:	853e                	mv	a0,a5
    80005f30:	60e2                	ld	ra,24(sp)
    80005f32:	6442                	ld	s0,16(sp)
    80005f34:	6105                	addi	sp,sp,32
    80005f36:	8082                	ret

0000000080005f38 <sys_link>:
{
    80005f38:	7169                	addi	sp,sp,-304
    80005f3a:	f606                	sd	ra,296(sp)
    80005f3c:	f222                	sd	s0,288(sp)
    80005f3e:	ee26                	sd	s1,280(sp)
    80005f40:	ea4a                	sd	s2,272(sp)
    80005f42:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f44:	08000613          	li	a2,128
    80005f48:	ed040593          	addi	a1,s0,-304
    80005f4c:	4501                	li	a0,0
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	86c080e7          	jalr	-1940(ra) # 800037ba <argstr>
    return -1;
    80005f56:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f58:	10054e63          	bltz	a0,80006074 <sys_link+0x13c>
    80005f5c:	08000613          	li	a2,128
    80005f60:	f5040593          	addi	a1,s0,-176
    80005f64:	4505                	li	a0,1
    80005f66:	ffffe097          	auipc	ra,0xffffe
    80005f6a:	854080e7          	jalr	-1964(ra) # 800037ba <argstr>
    return -1;
    80005f6e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f70:	10054263          	bltz	a0,80006074 <sys_link+0x13c>
  begin_op();
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	d46080e7          	jalr	-698(ra) # 80004cba <begin_op>
  if((ip = namei(old)) == 0){
    80005f7c:	ed040513          	addi	a0,s0,-304
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	b1e080e7          	jalr	-1250(ra) # 80004a9e <namei>
    80005f88:	84aa                	mv	s1,a0
    80005f8a:	c551                	beqz	a0,80006016 <sys_link+0xde>
  ilock(ip);
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	35c080e7          	jalr	860(ra) # 800042e8 <ilock>
  if(ip->type == T_DIR){
    80005f94:	04449703          	lh	a4,68(s1)
    80005f98:	4785                	li	a5,1
    80005f9a:	08f70463          	beq	a4,a5,80006022 <sys_link+0xea>
  ip->nlink++;
    80005f9e:	04a4d783          	lhu	a5,74(s1)
    80005fa2:	2785                	addiw	a5,a5,1
    80005fa4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fa8:	8526                	mv	a0,s1
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	274080e7          	jalr	628(ra) # 8000421e <iupdate>
  iunlock(ip);
    80005fb2:	8526                	mv	a0,s1
    80005fb4:	ffffe097          	auipc	ra,0xffffe
    80005fb8:	3f6080e7          	jalr	1014(ra) # 800043aa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005fbc:	fd040593          	addi	a1,s0,-48
    80005fc0:	f5040513          	addi	a0,s0,-176
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	af8080e7          	jalr	-1288(ra) # 80004abc <nameiparent>
    80005fcc:	892a                	mv	s2,a0
    80005fce:	c935                	beqz	a0,80006042 <sys_link+0x10a>
  ilock(dp);
    80005fd0:	ffffe097          	auipc	ra,0xffffe
    80005fd4:	318080e7          	jalr	792(ra) # 800042e8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005fd8:	00092703          	lw	a4,0(s2)
    80005fdc:	409c                	lw	a5,0(s1)
    80005fde:	04f71d63          	bne	a4,a5,80006038 <sys_link+0x100>
    80005fe2:	40d0                	lw	a2,4(s1)
    80005fe4:	fd040593          	addi	a1,s0,-48
    80005fe8:	854a                	mv	a0,s2
    80005fea:	fffff097          	auipc	ra,0xfffff
    80005fee:	9f2080e7          	jalr	-1550(ra) # 800049dc <dirlink>
    80005ff2:	04054363          	bltz	a0,80006038 <sys_link+0x100>
  iunlockput(dp);
    80005ff6:	854a                	mv	a0,s2
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	552080e7          	jalr	1362(ra) # 8000454a <iunlockput>
  iput(ip);
    80006000:	8526                	mv	a0,s1
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	4a0080e7          	jalr	1184(ra) # 800044a2 <iput>
  end_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	d30080e7          	jalr	-720(ra) # 80004d3a <end_op>
  return 0;
    80006012:	4781                	li	a5,0
    80006014:	a085                	j	80006074 <sys_link+0x13c>
    end_op();
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	d24080e7          	jalr	-732(ra) # 80004d3a <end_op>
    return -1;
    8000601e:	57fd                	li	a5,-1
    80006020:	a891                	j	80006074 <sys_link+0x13c>
    iunlockput(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	526080e7          	jalr	1318(ra) # 8000454a <iunlockput>
    end_op();
    8000602c:	fffff097          	auipc	ra,0xfffff
    80006030:	d0e080e7          	jalr	-754(ra) # 80004d3a <end_op>
    return -1;
    80006034:	57fd                	li	a5,-1
    80006036:	a83d                	j	80006074 <sys_link+0x13c>
    iunlockput(dp);
    80006038:	854a                	mv	a0,s2
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	510080e7          	jalr	1296(ra) # 8000454a <iunlockput>
  ilock(ip);
    80006042:	8526                	mv	a0,s1
    80006044:	ffffe097          	auipc	ra,0xffffe
    80006048:	2a4080e7          	jalr	676(ra) # 800042e8 <ilock>
  ip->nlink--;
    8000604c:	04a4d783          	lhu	a5,74(s1)
    80006050:	37fd                	addiw	a5,a5,-1
    80006052:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006056:	8526                	mv	a0,s1
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	1c6080e7          	jalr	454(ra) # 8000421e <iupdate>
  iunlockput(ip);
    80006060:	8526                	mv	a0,s1
    80006062:	ffffe097          	auipc	ra,0xffffe
    80006066:	4e8080e7          	jalr	1256(ra) # 8000454a <iunlockput>
  end_op();
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	cd0080e7          	jalr	-816(ra) # 80004d3a <end_op>
  return -1;
    80006072:	57fd                	li	a5,-1
}
    80006074:	853e                	mv	a0,a5
    80006076:	70b2                	ld	ra,296(sp)
    80006078:	7412                	ld	s0,288(sp)
    8000607a:	64f2                	ld	s1,280(sp)
    8000607c:	6952                	ld	s2,272(sp)
    8000607e:	6155                	addi	sp,sp,304
    80006080:	8082                	ret

0000000080006082 <sys_unlink>:
{
    80006082:	7151                	addi	sp,sp,-240
    80006084:	f586                	sd	ra,232(sp)
    80006086:	f1a2                	sd	s0,224(sp)
    80006088:	eda6                	sd	s1,216(sp)
    8000608a:	e9ca                	sd	s2,208(sp)
    8000608c:	e5ce                	sd	s3,200(sp)
    8000608e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006090:	08000613          	li	a2,128
    80006094:	f3040593          	addi	a1,s0,-208
    80006098:	4501                	li	a0,0
    8000609a:	ffffd097          	auipc	ra,0xffffd
    8000609e:	720080e7          	jalr	1824(ra) # 800037ba <argstr>
    800060a2:	18054163          	bltz	a0,80006224 <sys_unlink+0x1a2>
  begin_op();
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	c14080e7          	jalr	-1004(ra) # 80004cba <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800060ae:	fb040593          	addi	a1,s0,-80
    800060b2:	f3040513          	addi	a0,s0,-208
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	a06080e7          	jalr	-1530(ra) # 80004abc <nameiparent>
    800060be:	84aa                	mv	s1,a0
    800060c0:	c979                	beqz	a0,80006196 <sys_unlink+0x114>
  ilock(dp);
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	226080e7          	jalr	550(ra) # 800042e8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800060ca:	00003597          	auipc	a1,0x3
    800060ce:	e7e58593          	addi	a1,a1,-386 # 80008f48 <syscalls+0x2b0>
    800060d2:	fb040513          	addi	a0,s0,-80
    800060d6:	ffffe097          	auipc	ra,0xffffe
    800060da:	6dc080e7          	jalr	1756(ra) # 800047b2 <namecmp>
    800060de:	14050a63          	beqz	a0,80006232 <sys_unlink+0x1b0>
    800060e2:	00003597          	auipc	a1,0x3
    800060e6:	e6e58593          	addi	a1,a1,-402 # 80008f50 <syscalls+0x2b8>
    800060ea:	fb040513          	addi	a0,s0,-80
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	6c4080e7          	jalr	1732(ra) # 800047b2 <namecmp>
    800060f6:	12050e63          	beqz	a0,80006232 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800060fa:	f2c40613          	addi	a2,s0,-212
    800060fe:	fb040593          	addi	a1,s0,-80
    80006102:	8526                	mv	a0,s1
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	6c8080e7          	jalr	1736(ra) # 800047cc <dirlookup>
    8000610c:	892a                	mv	s2,a0
    8000610e:	12050263          	beqz	a0,80006232 <sys_unlink+0x1b0>
  ilock(ip);
    80006112:	ffffe097          	auipc	ra,0xffffe
    80006116:	1d6080e7          	jalr	470(ra) # 800042e8 <ilock>
  if(ip->nlink < 1)
    8000611a:	04a91783          	lh	a5,74(s2)
    8000611e:	08f05263          	blez	a5,800061a2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006122:	04491703          	lh	a4,68(s2)
    80006126:	4785                	li	a5,1
    80006128:	08f70563          	beq	a4,a5,800061b2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000612c:	4641                	li	a2,16
    8000612e:	4581                	li	a1,0
    80006130:	fc040513          	addi	a0,s0,-64
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	bd0080e7          	jalr	-1072(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000613c:	4741                	li	a4,16
    8000613e:	f2c42683          	lw	a3,-212(s0)
    80006142:	fc040613          	addi	a2,s0,-64
    80006146:	4581                	li	a1,0
    80006148:	8526                	mv	a0,s1
    8000614a:	ffffe097          	auipc	ra,0xffffe
    8000614e:	54a080e7          	jalr	1354(ra) # 80004694 <writei>
    80006152:	47c1                	li	a5,16
    80006154:	0af51563          	bne	a0,a5,800061fe <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006158:	04491703          	lh	a4,68(s2)
    8000615c:	4785                	li	a5,1
    8000615e:	0af70863          	beq	a4,a5,8000620e <sys_unlink+0x18c>
  iunlockput(dp);
    80006162:	8526                	mv	a0,s1
    80006164:	ffffe097          	auipc	ra,0xffffe
    80006168:	3e6080e7          	jalr	998(ra) # 8000454a <iunlockput>
  ip->nlink--;
    8000616c:	04a95783          	lhu	a5,74(s2)
    80006170:	37fd                	addiw	a5,a5,-1
    80006172:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006176:	854a                	mv	a0,s2
    80006178:	ffffe097          	auipc	ra,0xffffe
    8000617c:	0a6080e7          	jalr	166(ra) # 8000421e <iupdate>
  iunlockput(ip);
    80006180:	854a                	mv	a0,s2
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	3c8080e7          	jalr	968(ra) # 8000454a <iunlockput>
  end_op();
    8000618a:	fffff097          	auipc	ra,0xfffff
    8000618e:	bb0080e7          	jalr	-1104(ra) # 80004d3a <end_op>
  return 0;
    80006192:	4501                	li	a0,0
    80006194:	a84d                	j	80006246 <sys_unlink+0x1c4>
    end_op();
    80006196:	fffff097          	auipc	ra,0xfffff
    8000619a:	ba4080e7          	jalr	-1116(ra) # 80004d3a <end_op>
    return -1;
    8000619e:	557d                	li	a0,-1
    800061a0:	a05d                	j	80006246 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800061a2:	00003517          	auipc	a0,0x3
    800061a6:	dd650513          	addi	a0,a0,-554 # 80008f78 <syscalls+0x2e0>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	394080e7          	jalr	916(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061b2:	04c92703          	lw	a4,76(s2)
    800061b6:	02000793          	li	a5,32
    800061ba:	f6e7f9e3          	bgeu	a5,a4,8000612c <sys_unlink+0xaa>
    800061be:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061c2:	4741                	li	a4,16
    800061c4:	86ce                	mv	a3,s3
    800061c6:	f1840613          	addi	a2,s0,-232
    800061ca:	4581                	li	a1,0
    800061cc:	854a                	mv	a0,s2
    800061ce:	ffffe097          	auipc	ra,0xffffe
    800061d2:	3ce080e7          	jalr	974(ra) # 8000459c <readi>
    800061d6:	47c1                	li	a5,16
    800061d8:	00f51b63          	bne	a0,a5,800061ee <sys_unlink+0x16c>
    if(de.inum != 0)
    800061dc:	f1845783          	lhu	a5,-232(s0)
    800061e0:	e7a1                	bnez	a5,80006228 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061e2:	29c1                	addiw	s3,s3,16
    800061e4:	04c92783          	lw	a5,76(s2)
    800061e8:	fcf9ede3          	bltu	s3,a5,800061c2 <sys_unlink+0x140>
    800061ec:	b781                	j	8000612c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800061ee:	00003517          	auipc	a0,0x3
    800061f2:	da250513          	addi	a0,a0,-606 # 80008f90 <syscalls+0x2f8>
    800061f6:	ffffa097          	auipc	ra,0xffffa
    800061fa:	348080e7          	jalr	840(ra) # 8000053e <panic>
    panic("unlink: writei");
    800061fe:	00003517          	auipc	a0,0x3
    80006202:	daa50513          	addi	a0,a0,-598 # 80008fa8 <syscalls+0x310>
    80006206:	ffffa097          	auipc	ra,0xffffa
    8000620a:	338080e7          	jalr	824(ra) # 8000053e <panic>
    dp->nlink--;
    8000620e:	04a4d783          	lhu	a5,74(s1)
    80006212:	37fd                	addiw	a5,a5,-1
    80006214:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006218:	8526                	mv	a0,s1
    8000621a:	ffffe097          	auipc	ra,0xffffe
    8000621e:	004080e7          	jalr	4(ra) # 8000421e <iupdate>
    80006222:	b781                	j	80006162 <sys_unlink+0xe0>
    return -1;
    80006224:	557d                	li	a0,-1
    80006226:	a005                	j	80006246 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006228:	854a                	mv	a0,s2
    8000622a:	ffffe097          	auipc	ra,0xffffe
    8000622e:	320080e7          	jalr	800(ra) # 8000454a <iunlockput>
  iunlockput(dp);
    80006232:	8526                	mv	a0,s1
    80006234:	ffffe097          	auipc	ra,0xffffe
    80006238:	316080e7          	jalr	790(ra) # 8000454a <iunlockput>
  end_op();
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	afe080e7          	jalr	-1282(ra) # 80004d3a <end_op>
  return -1;
    80006244:	557d                	li	a0,-1
}
    80006246:	70ae                	ld	ra,232(sp)
    80006248:	740e                	ld	s0,224(sp)
    8000624a:	64ee                	ld	s1,216(sp)
    8000624c:	694e                	ld	s2,208(sp)
    8000624e:	69ae                	ld	s3,200(sp)
    80006250:	616d                	addi	sp,sp,240
    80006252:	8082                	ret

0000000080006254 <sys_open>:

uint64
sys_open(void)
{
    80006254:	7131                	addi	sp,sp,-192
    80006256:	fd06                	sd	ra,184(sp)
    80006258:	f922                	sd	s0,176(sp)
    8000625a:	f526                	sd	s1,168(sp)
    8000625c:	f14a                	sd	s2,160(sp)
    8000625e:	ed4e                	sd	s3,152(sp)
    80006260:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006262:	08000613          	li	a2,128
    80006266:	f5040593          	addi	a1,s0,-176
    8000626a:	4501                	li	a0,0
    8000626c:	ffffd097          	auipc	ra,0xffffd
    80006270:	54e080e7          	jalr	1358(ra) # 800037ba <argstr>
    return -1;
    80006274:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006276:	0c054163          	bltz	a0,80006338 <sys_open+0xe4>
    8000627a:	f4c40593          	addi	a1,s0,-180
    8000627e:	4505                	li	a0,1
    80006280:	ffffd097          	auipc	ra,0xffffd
    80006284:	4f6080e7          	jalr	1270(ra) # 80003776 <argint>
    80006288:	0a054863          	bltz	a0,80006338 <sys_open+0xe4>

  begin_op();
    8000628c:	fffff097          	auipc	ra,0xfffff
    80006290:	a2e080e7          	jalr	-1490(ra) # 80004cba <begin_op>

  if(omode & O_CREATE){
    80006294:	f4c42783          	lw	a5,-180(s0)
    80006298:	2007f793          	andi	a5,a5,512
    8000629c:	cbdd                	beqz	a5,80006352 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000629e:	4681                	li	a3,0
    800062a0:	4601                	li	a2,0
    800062a2:	4589                	li	a1,2
    800062a4:	f5040513          	addi	a0,s0,-176
    800062a8:	00000097          	auipc	ra,0x0
    800062ac:	972080e7          	jalr	-1678(ra) # 80005c1a <create>
    800062b0:	892a                	mv	s2,a0
    if(ip == 0){
    800062b2:	c959                	beqz	a0,80006348 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800062b4:	04491703          	lh	a4,68(s2)
    800062b8:	478d                	li	a5,3
    800062ba:	00f71763          	bne	a4,a5,800062c8 <sys_open+0x74>
    800062be:	04695703          	lhu	a4,70(s2)
    800062c2:	47a5                	li	a5,9
    800062c4:	0ce7ec63          	bltu	a5,a4,8000639c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800062c8:	fffff097          	auipc	ra,0xfffff
    800062cc:	e02080e7          	jalr	-510(ra) # 800050ca <filealloc>
    800062d0:	89aa                	mv	s3,a0
    800062d2:	10050263          	beqz	a0,800063d6 <sys_open+0x182>
    800062d6:	00000097          	auipc	ra,0x0
    800062da:	902080e7          	jalr	-1790(ra) # 80005bd8 <fdalloc>
    800062de:	84aa                	mv	s1,a0
    800062e0:	0e054663          	bltz	a0,800063cc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800062e4:	04491703          	lh	a4,68(s2)
    800062e8:	478d                	li	a5,3
    800062ea:	0cf70463          	beq	a4,a5,800063b2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062ee:	4789                	li	a5,2
    800062f0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800062f4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800062f8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800062fc:	f4c42783          	lw	a5,-180(s0)
    80006300:	0017c713          	xori	a4,a5,1
    80006304:	8b05                	andi	a4,a4,1
    80006306:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000630a:	0037f713          	andi	a4,a5,3
    8000630e:	00e03733          	snez	a4,a4
    80006312:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006316:	4007f793          	andi	a5,a5,1024
    8000631a:	c791                	beqz	a5,80006326 <sys_open+0xd2>
    8000631c:	04491703          	lh	a4,68(s2)
    80006320:	4789                	li	a5,2
    80006322:	08f70f63          	beq	a4,a5,800063c0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006326:	854a                	mv	a0,s2
    80006328:	ffffe097          	auipc	ra,0xffffe
    8000632c:	082080e7          	jalr	130(ra) # 800043aa <iunlock>
  end_op();
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	a0a080e7          	jalr	-1526(ra) # 80004d3a <end_op>

  return fd;
}
    80006338:	8526                	mv	a0,s1
    8000633a:	70ea                	ld	ra,184(sp)
    8000633c:	744a                	ld	s0,176(sp)
    8000633e:	74aa                	ld	s1,168(sp)
    80006340:	790a                	ld	s2,160(sp)
    80006342:	69ea                	ld	s3,152(sp)
    80006344:	6129                	addi	sp,sp,192
    80006346:	8082                	ret
      end_op();
    80006348:	fffff097          	auipc	ra,0xfffff
    8000634c:	9f2080e7          	jalr	-1550(ra) # 80004d3a <end_op>
      return -1;
    80006350:	b7e5                	j	80006338 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006352:	f5040513          	addi	a0,s0,-176
    80006356:	ffffe097          	auipc	ra,0xffffe
    8000635a:	748080e7          	jalr	1864(ra) # 80004a9e <namei>
    8000635e:	892a                	mv	s2,a0
    80006360:	c905                	beqz	a0,80006390 <sys_open+0x13c>
    ilock(ip);
    80006362:	ffffe097          	auipc	ra,0xffffe
    80006366:	f86080e7          	jalr	-122(ra) # 800042e8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000636a:	04491703          	lh	a4,68(s2)
    8000636e:	4785                	li	a5,1
    80006370:	f4f712e3          	bne	a4,a5,800062b4 <sys_open+0x60>
    80006374:	f4c42783          	lw	a5,-180(s0)
    80006378:	dba1                	beqz	a5,800062c8 <sys_open+0x74>
      iunlockput(ip);
    8000637a:	854a                	mv	a0,s2
    8000637c:	ffffe097          	auipc	ra,0xffffe
    80006380:	1ce080e7          	jalr	462(ra) # 8000454a <iunlockput>
      end_op();
    80006384:	fffff097          	auipc	ra,0xfffff
    80006388:	9b6080e7          	jalr	-1610(ra) # 80004d3a <end_op>
      return -1;
    8000638c:	54fd                	li	s1,-1
    8000638e:	b76d                	j	80006338 <sys_open+0xe4>
      end_op();
    80006390:	fffff097          	auipc	ra,0xfffff
    80006394:	9aa080e7          	jalr	-1622(ra) # 80004d3a <end_op>
      return -1;
    80006398:	54fd                	li	s1,-1
    8000639a:	bf79                	j	80006338 <sys_open+0xe4>
    iunlockput(ip);
    8000639c:	854a                	mv	a0,s2
    8000639e:	ffffe097          	auipc	ra,0xffffe
    800063a2:	1ac080e7          	jalr	428(ra) # 8000454a <iunlockput>
    end_op();
    800063a6:	fffff097          	auipc	ra,0xfffff
    800063aa:	994080e7          	jalr	-1644(ra) # 80004d3a <end_op>
    return -1;
    800063ae:	54fd                	li	s1,-1
    800063b0:	b761                	j	80006338 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800063b2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800063b6:	04691783          	lh	a5,70(s2)
    800063ba:	02f99223          	sh	a5,36(s3)
    800063be:	bf2d                	j	800062f8 <sys_open+0xa4>
    itrunc(ip);
    800063c0:	854a                	mv	a0,s2
    800063c2:	ffffe097          	auipc	ra,0xffffe
    800063c6:	034080e7          	jalr	52(ra) # 800043f6 <itrunc>
    800063ca:	bfb1                	j	80006326 <sys_open+0xd2>
      fileclose(f);
    800063cc:	854e                	mv	a0,s3
    800063ce:	fffff097          	auipc	ra,0xfffff
    800063d2:	db8080e7          	jalr	-584(ra) # 80005186 <fileclose>
    iunlockput(ip);
    800063d6:	854a                	mv	a0,s2
    800063d8:	ffffe097          	auipc	ra,0xffffe
    800063dc:	172080e7          	jalr	370(ra) # 8000454a <iunlockput>
    end_op();
    800063e0:	fffff097          	auipc	ra,0xfffff
    800063e4:	95a080e7          	jalr	-1702(ra) # 80004d3a <end_op>
    return -1;
    800063e8:	54fd                	li	s1,-1
    800063ea:	b7b9                	j	80006338 <sys_open+0xe4>

00000000800063ec <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063ec:	7175                	addi	sp,sp,-144
    800063ee:	e506                	sd	ra,136(sp)
    800063f0:	e122                	sd	s0,128(sp)
    800063f2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800063f4:	fffff097          	auipc	ra,0xfffff
    800063f8:	8c6080e7          	jalr	-1850(ra) # 80004cba <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800063fc:	08000613          	li	a2,128
    80006400:	f7040593          	addi	a1,s0,-144
    80006404:	4501                	li	a0,0
    80006406:	ffffd097          	auipc	ra,0xffffd
    8000640a:	3b4080e7          	jalr	948(ra) # 800037ba <argstr>
    8000640e:	02054963          	bltz	a0,80006440 <sys_mkdir+0x54>
    80006412:	4681                	li	a3,0
    80006414:	4601                	li	a2,0
    80006416:	4585                	li	a1,1
    80006418:	f7040513          	addi	a0,s0,-144
    8000641c:	fffff097          	auipc	ra,0xfffff
    80006420:	7fe080e7          	jalr	2046(ra) # 80005c1a <create>
    80006424:	cd11                	beqz	a0,80006440 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006426:	ffffe097          	auipc	ra,0xffffe
    8000642a:	124080e7          	jalr	292(ra) # 8000454a <iunlockput>
  end_op();
    8000642e:	fffff097          	auipc	ra,0xfffff
    80006432:	90c080e7          	jalr	-1780(ra) # 80004d3a <end_op>
  return 0;
    80006436:	4501                	li	a0,0
}
    80006438:	60aa                	ld	ra,136(sp)
    8000643a:	640a                	ld	s0,128(sp)
    8000643c:	6149                	addi	sp,sp,144
    8000643e:	8082                	ret
    end_op();
    80006440:	fffff097          	auipc	ra,0xfffff
    80006444:	8fa080e7          	jalr	-1798(ra) # 80004d3a <end_op>
    return -1;
    80006448:	557d                	li	a0,-1
    8000644a:	b7fd                	j	80006438 <sys_mkdir+0x4c>

000000008000644c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000644c:	7135                	addi	sp,sp,-160
    8000644e:	ed06                	sd	ra,152(sp)
    80006450:	e922                	sd	s0,144(sp)
    80006452:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006454:	fffff097          	auipc	ra,0xfffff
    80006458:	866080e7          	jalr	-1946(ra) # 80004cba <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000645c:	08000613          	li	a2,128
    80006460:	f7040593          	addi	a1,s0,-144
    80006464:	4501                	li	a0,0
    80006466:	ffffd097          	auipc	ra,0xffffd
    8000646a:	354080e7          	jalr	852(ra) # 800037ba <argstr>
    8000646e:	04054a63          	bltz	a0,800064c2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006472:	f6c40593          	addi	a1,s0,-148
    80006476:	4505                	li	a0,1
    80006478:	ffffd097          	auipc	ra,0xffffd
    8000647c:	2fe080e7          	jalr	766(ra) # 80003776 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006480:	04054163          	bltz	a0,800064c2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006484:	f6840593          	addi	a1,s0,-152
    80006488:	4509                	li	a0,2
    8000648a:	ffffd097          	auipc	ra,0xffffd
    8000648e:	2ec080e7          	jalr	748(ra) # 80003776 <argint>
     argint(1, &major) < 0 ||
    80006492:	02054863          	bltz	a0,800064c2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006496:	f6841683          	lh	a3,-152(s0)
    8000649a:	f6c41603          	lh	a2,-148(s0)
    8000649e:	458d                	li	a1,3
    800064a0:	f7040513          	addi	a0,s0,-144
    800064a4:	fffff097          	auipc	ra,0xfffff
    800064a8:	776080e7          	jalr	1910(ra) # 80005c1a <create>
     argint(2, &minor) < 0 ||
    800064ac:	c919                	beqz	a0,800064c2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064ae:	ffffe097          	auipc	ra,0xffffe
    800064b2:	09c080e7          	jalr	156(ra) # 8000454a <iunlockput>
  end_op();
    800064b6:	fffff097          	auipc	ra,0xfffff
    800064ba:	884080e7          	jalr	-1916(ra) # 80004d3a <end_op>
  return 0;
    800064be:	4501                	li	a0,0
    800064c0:	a031                	j	800064cc <sys_mknod+0x80>
    end_op();
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	878080e7          	jalr	-1928(ra) # 80004d3a <end_op>
    return -1;
    800064ca:	557d                	li	a0,-1
}
    800064cc:	60ea                	ld	ra,152(sp)
    800064ce:	644a                	ld	s0,144(sp)
    800064d0:	610d                	addi	sp,sp,160
    800064d2:	8082                	ret

00000000800064d4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800064d4:	7135                	addi	sp,sp,-160
    800064d6:	ed06                	sd	ra,152(sp)
    800064d8:	e922                	sd	s0,144(sp)
    800064da:	e526                	sd	s1,136(sp)
    800064dc:	e14a                	sd	s2,128(sp)
    800064de:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800064e0:	ffffc097          	auipc	ra,0xffffc
    800064e4:	9e4080e7          	jalr	-1564(ra) # 80001ec4 <myproc>
    800064e8:	892a                	mv	s2,a0
  
  begin_op();
    800064ea:	ffffe097          	auipc	ra,0xffffe
    800064ee:	7d0080e7          	jalr	2000(ra) # 80004cba <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064f2:	08000613          	li	a2,128
    800064f6:	f6040593          	addi	a1,s0,-160
    800064fa:	4501                	li	a0,0
    800064fc:	ffffd097          	auipc	ra,0xffffd
    80006500:	2be080e7          	jalr	702(ra) # 800037ba <argstr>
    80006504:	04054b63          	bltz	a0,8000655a <sys_chdir+0x86>
    80006508:	f6040513          	addi	a0,s0,-160
    8000650c:	ffffe097          	auipc	ra,0xffffe
    80006510:	592080e7          	jalr	1426(ra) # 80004a9e <namei>
    80006514:	84aa                	mv	s1,a0
    80006516:	c131                	beqz	a0,8000655a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006518:	ffffe097          	auipc	ra,0xffffe
    8000651c:	dd0080e7          	jalr	-560(ra) # 800042e8 <ilock>
  if(ip->type != T_DIR){
    80006520:	04449703          	lh	a4,68(s1)
    80006524:	4785                	li	a5,1
    80006526:	04f71063          	bne	a4,a5,80006566 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000652a:	8526                	mv	a0,s1
    8000652c:	ffffe097          	auipc	ra,0xffffe
    80006530:	e7e080e7          	jalr	-386(ra) # 800043aa <iunlock>
  iput(p->cwd);
    80006534:	17093503          	ld	a0,368(s2)
    80006538:	ffffe097          	auipc	ra,0xffffe
    8000653c:	f6a080e7          	jalr	-150(ra) # 800044a2 <iput>
  end_op();
    80006540:	ffffe097          	auipc	ra,0xffffe
    80006544:	7fa080e7          	jalr	2042(ra) # 80004d3a <end_op>
  p->cwd = ip;
    80006548:	16993823          	sd	s1,368(s2)
  return 0;
    8000654c:	4501                	li	a0,0
}
    8000654e:	60ea                	ld	ra,152(sp)
    80006550:	644a                	ld	s0,144(sp)
    80006552:	64aa                	ld	s1,136(sp)
    80006554:	690a                	ld	s2,128(sp)
    80006556:	610d                	addi	sp,sp,160
    80006558:	8082                	ret
    end_op();
    8000655a:	ffffe097          	auipc	ra,0xffffe
    8000655e:	7e0080e7          	jalr	2016(ra) # 80004d3a <end_op>
    return -1;
    80006562:	557d                	li	a0,-1
    80006564:	b7ed                	j	8000654e <sys_chdir+0x7a>
    iunlockput(ip);
    80006566:	8526                	mv	a0,s1
    80006568:	ffffe097          	auipc	ra,0xffffe
    8000656c:	fe2080e7          	jalr	-30(ra) # 8000454a <iunlockput>
    end_op();
    80006570:	ffffe097          	auipc	ra,0xffffe
    80006574:	7ca080e7          	jalr	1994(ra) # 80004d3a <end_op>
    return -1;
    80006578:	557d                	li	a0,-1
    8000657a:	bfd1                	j	8000654e <sys_chdir+0x7a>

000000008000657c <sys_exec>:

uint64
sys_exec(void)
{
    8000657c:	7145                	addi	sp,sp,-464
    8000657e:	e786                	sd	ra,456(sp)
    80006580:	e3a2                	sd	s0,448(sp)
    80006582:	ff26                	sd	s1,440(sp)
    80006584:	fb4a                	sd	s2,432(sp)
    80006586:	f74e                	sd	s3,424(sp)
    80006588:	f352                	sd	s4,416(sp)
    8000658a:	ef56                	sd	s5,408(sp)
    8000658c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000658e:	08000613          	li	a2,128
    80006592:	f4040593          	addi	a1,s0,-192
    80006596:	4501                	li	a0,0
    80006598:	ffffd097          	auipc	ra,0xffffd
    8000659c:	222080e7          	jalr	546(ra) # 800037ba <argstr>
    return -1;
    800065a0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800065a2:	0c054a63          	bltz	a0,80006676 <sys_exec+0xfa>
    800065a6:	e3840593          	addi	a1,s0,-456
    800065aa:	4505                	li	a0,1
    800065ac:	ffffd097          	auipc	ra,0xffffd
    800065b0:	1ec080e7          	jalr	492(ra) # 80003798 <argaddr>
    800065b4:	0c054163          	bltz	a0,80006676 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800065b8:	10000613          	li	a2,256
    800065bc:	4581                	li	a1,0
    800065be:	e4040513          	addi	a0,s0,-448
    800065c2:	ffffa097          	auipc	ra,0xffffa
    800065c6:	742080e7          	jalr	1858(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800065ca:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800065ce:	89a6                	mv	s3,s1
    800065d0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800065d2:	02000a13          	li	s4,32
    800065d6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800065da:	00391513          	slli	a0,s2,0x3
    800065de:	e3040593          	addi	a1,s0,-464
    800065e2:	e3843783          	ld	a5,-456(s0)
    800065e6:	953e                	add	a0,a0,a5
    800065e8:	ffffd097          	auipc	ra,0xffffd
    800065ec:	0f4080e7          	jalr	244(ra) # 800036dc <fetchaddr>
    800065f0:	02054a63          	bltz	a0,80006624 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800065f4:	e3043783          	ld	a5,-464(s0)
    800065f8:	c3b9                	beqz	a5,8000663e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	4fa080e7          	jalr	1274(ra) # 80000af4 <kalloc>
    80006602:	85aa                	mv	a1,a0
    80006604:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006608:	cd11                	beqz	a0,80006624 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000660a:	6605                	lui	a2,0x1
    8000660c:	e3043503          	ld	a0,-464(s0)
    80006610:	ffffd097          	auipc	ra,0xffffd
    80006614:	11e080e7          	jalr	286(ra) # 8000372e <fetchstr>
    80006618:	00054663          	bltz	a0,80006624 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000661c:	0905                	addi	s2,s2,1
    8000661e:	09a1                	addi	s3,s3,8
    80006620:	fb491be3          	bne	s2,s4,800065d6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006624:	10048913          	addi	s2,s1,256
    80006628:	6088                	ld	a0,0(s1)
    8000662a:	c529                	beqz	a0,80006674 <sys_exec+0xf8>
    kfree(argv[i]);
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	3cc080e7          	jalr	972(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006634:	04a1                	addi	s1,s1,8
    80006636:	ff2499e3          	bne	s1,s2,80006628 <sys_exec+0xac>
  return -1;
    8000663a:	597d                	li	s2,-1
    8000663c:	a82d                	j	80006676 <sys_exec+0xfa>
      argv[i] = 0;
    8000663e:	0a8e                	slli	s5,s5,0x3
    80006640:	fc040793          	addi	a5,s0,-64
    80006644:	9abe                	add	s5,s5,a5
    80006646:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000664a:	e4040593          	addi	a1,s0,-448
    8000664e:	f4040513          	addi	a0,s0,-192
    80006652:	fffff097          	auipc	ra,0xfffff
    80006656:	194080e7          	jalr	404(ra) # 800057e6 <exec>
    8000665a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000665c:	10048993          	addi	s3,s1,256
    80006660:	6088                	ld	a0,0(s1)
    80006662:	c911                	beqz	a0,80006676 <sys_exec+0xfa>
    kfree(argv[i]);
    80006664:	ffffa097          	auipc	ra,0xffffa
    80006668:	394080e7          	jalr	916(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000666c:	04a1                	addi	s1,s1,8
    8000666e:	ff3499e3          	bne	s1,s3,80006660 <sys_exec+0xe4>
    80006672:	a011                	j	80006676 <sys_exec+0xfa>
  return -1;
    80006674:	597d                	li	s2,-1
}
    80006676:	854a                	mv	a0,s2
    80006678:	60be                	ld	ra,456(sp)
    8000667a:	641e                	ld	s0,448(sp)
    8000667c:	74fa                	ld	s1,440(sp)
    8000667e:	795a                	ld	s2,432(sp)
    80006680:	79ba                	ld	s3,424(sp)
    80006682:	7a1a                	ld	s4,416(sp)
    80006684:	6afa                	ld	s5,408(sp)
    80006686:	6179                	addi	sp,sp,464
    80006688:	8082                	ret

000000008000668a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000668a:	7139                	addi	sp,sp,-64
    8000668c:	fc06                	sd	ra,56(sp)
    8000668e:	f822                	sd	s0,48(sp)
    80006690:	f426                	sd	s1,40(sp)
    80006692:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006694:	ffffc097          	auipc	ra,0xffffc
    80006698:	830080e7          	jalr	-2000(ra) # 80001ec4 <myproc>
    8000669c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000669e:	fd840593          	addi	a1,s0,-40
    800066a2:	4501                	li	a0,0
    800066a4:	ffffd097          	auipc	ra,0xffffd
    800066a8:	0f4080e7          	jalr	244(ra) # 80003798 <argaddr>
    return -1;
    800066ac:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800066ae:	0e054063          	bltz	a0,8000678e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800066b2:	fc840593          	addi	a1,s0,-56
    800066b6:	fd040513          	addi	a0,s0,-48
    800066ba:	fffff097          	auipc	ra,0xfffff
    800066be:	dfc080e7          	jalr	-516(ra) # 800054b6 <pipealloc>
    return -1;
    800066c2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800066c4:	0c054563          	bltz	a0,8000678e <sys_pipe+0x104>
  fd0 = -1;
    800066c8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800066cc:	fd043503          	ld	a0,-48(s0)
    800066d0:	fffff097          	auipc	ra,0xfffff
    800066d4:	508080e7          	jalr	1288(ra) # 80005bd8 <fdalloc>
    800066d8:	fca42223          	sw	a0,-60(s0)
    800066dc:	08054c63          	bltz	a0,80006774 <sys_pipe+0xea>
    800066e0:	fc843503          	ld	a0,-56(s0)
    800066e4:	fffff097          	auipc	ra,0xfffff
    800066e8:	4f4080e7          	jalr	1268(ra) # 80005bd8 <fdalloc>
    800066ec:	fca42023          	sw	a0,-64(s0)
    800066f0:	06054863          	bltz	a0,80006760 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066f4:	4691                	li	a3,4
    800066f6:	fc440613          	addi	a2,s0,-60
    800066fa:	fd843583          	ld	a1,-40(s0)
    800066fe:	78a8                	ld	a0,112(s1)
    80006700:	ffffb097          	auipc	ra,0xffffb
    80006704:	f96080e7          	jalr	-106(ra) # 80001696 <copyout>
    80006708:	02054063          	bltz	a0,80006728 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000670c:	4691                	li	a3,4
    8000670e:	fc040613          	addi	a2,s0,-64
    80006712:	fd843583          	ld	a1,-40(s0)
    80006716:	0591                	addi	a1,a1,4
    80006718:	78a8                	ld	a0,112(s1)
    8000671a:	ffffb097          	auipc	ra,0xffffb
    8000671e:	f7c080e7          	jalr	-132(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006722:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006724:	06055563          	bgez	a0,8000678e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006728:	fc442783          	lw	a5,-60(s0)
    8000672c:	07f9                	addi	a5,a5,30
    8000672e:	078e                	slli	a5,a5,0x3
    80006730:	97a6                	add	a5,a5,s1
    80006732:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006736:	fc042503          	lw	a0,-64(s0)
    8000673a:	0579                	addi	a0,a0,30
    8000673c:	050e                	slli	a0,a0,0x3
    8000673e:	9526                	add	a0,a0,s1
    80006740:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006744:	fd043503          	ld	a0,-48(s0)
    80006748:	fffff097          	auipc	ra,0xfffff
    8000674c:	a3e080e7          	jalr	-1474(ra) # 80005186 <fileclose>
    fileclose(wf);
    80006750:	fc843503          	ld	a0,-56(s0)
    80006754:	fffff097          	auipc	ra,0xfffff
    80006758:	a32080e7          	jalr	-1486(ra) # 80005186 <fileclose>
    return -1;
    8000675c:	57fd                	li	a5,-1
    8000675e:	a805                	j	8000678e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006760:	fc442783          	lw	a5,-60(s0)
    80006764:	0007c863          	bltz	a5,80006774 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006768:	01e78513          	addi	a0,a5,30
    8000676c:	050e                	slli	a0,a0,0x3
    8000676e:	9526                	add	a0,a0,s1
    80006770:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006774:	fd043503          	ld	a0,-48(s0)
    80006778:	fffff097          	auipc	ra,0xfffff
    8000677c:	a0e080e7          	jalr	-1522(ra) # 80005186 <fileclose>
    fileclose(wf);
    80006780:	fc843503          	ld	a0,-56(s0)
    80006784:	fffff097          	auipc	ra,0xfffff
    80006788:	a02080e7          	jalr	-1534(ra) # 80005186 <fileclose>
    return -1;
    8000678c:	57fd                	li	a5,-1
}
    8000678e:	853e                	mv	a0,a5
    80006790:	70e2                	ld	ra,56(sp)
    80006792:	7442                	ld	s0,48(sp)
    80006794:	74a2                	ld	s1,40(sp)
    80006796:	6121                	addi	sp,sp,64
    80006798:	8082                	ret
    8000679a:	0000                	unimp
    8000679c:	0000                	unimp
	...

00000000800067a0 <kernelvec>:
    800067a0:	7111                	addi	sp,sp,-256
    800067a2:	e006                	sd	ra,0(sp)
    800067a4:	e40a                	sd	sp,8(sp)
    800067a6:	e80e                	sd	gp,16(sp)
    800067a8:	ec12                	sd	tp,24(sp)
    800067aa:	f016                	sd	t0,32(sp)
    800067ac:	f41a                	sd	t1,40(sp)
    800067ae:	f81e                	sd	t2,48(sp)
    800067b0:	fc22                	sd	s0,56(sp)
    800067b2:	e0a6                	sd	s1,64(sp)
    800067b4:	e4aa                	sd	a0,72(sp)
    800067b6:	e8ae                	sd	a1,80(sp)
    800067b8:	ecb2                	sd	a2,88(sp)
    800067ba:	f0b6                	sd	a3,96(sp)
    800067bc:	f4ba                	sd	a4,104(sp)
    800067be:	f8be                	sd	a5,112(sp)
    800067c0:	fcc2                	sd	a6,120(sp)
    800067c2:	e146                	sd	a7,128(sp)
    800067c4:	e54a                	sd	s2,136(sp)
    800067c6:	e94e                	sd	s3,144(sp)
    800067c8:	ed52                	sd	s4,152(sp)
    800067ca:	f156                	sd	s5,160(sp)
    800067cc:	f55a                	sd	s6,168(sp)
    800067ce:	f95e                	sd	s7,176(sp)
    800067d0:	fd62                	sd	s8,184(sp)
    800067d2:	e1e6                	sd	s9,192(sp)
    800067d4:	e5ea                	sd	s10,200(sp)
    800067d6:	e9ee                	sd	s11,208(sp)
    800067d8:	edf2                	sd	t3,216(sp)
    800067da:	f1f6                	sd	t4,224(sp)
    800067dc:	f5fa                	sd	t5,232(sp)
    800067de:	f9fe                	sd	t6,240(sp)
    800067e0:	dc9fc0ef          	jal	ra,800035a8 <kerneltrap>
    800067e4:	6082                	ld	ra,0(sp)
    800067e6:	6122                	ld	sp,8(sp)
    800067e8:	61c2                	ld	gp,16(sp)
    800067ea:	7282                	ld	t0,32(sp)
    800067ec:	7322                	ld	t1,40(sp)
    800067ee:	73c2                	ld	t2,48(sp)
    800067f0:	7462                	ld	s0,56(sp)
    800067f2:	6486                	ld	s1,64(sp)
    800067f4:	6526                	ld	a0,72(sp)
    800067f6:	65c6                	ld	a1,80(sp)
    800067f8:	6666                	ld	a2,88(sp)
    800067fa:	7686                	ld	a3,96(sp)
    800067fc:	7726                	ld	a4,104(sp)
    800067fe:	77c6                	ld	a5,112(sp)
    80006800:	7866                	ld	a6,120(sp)
    80006802:	688a                	ld	a7,128(sp)
    80006804:	692a                	ld	s2,136(sp)
    80006806:	69ca                	ld	s3,144(sp)
    80006808:	6a6a                	ld	s4,152(sp)
    8000680a:	7a8a                	ld	s5,160(sp)
    8000680c:	7b2a                	ld	s6,168(sp)
    8000680e:	7bca                	ld	s7,176(sp)
    80006810:	7c6a                	ld	s8,184(sp)
    80006812:	6c8e                	ld	s9,192(sp)
    80006814:	6d2e                	ld	s10,200(sp)
    80006816:	6dce                	ld	s11,208(sp)
    80006818:	6e6e                	ld	t3,216(sp)
    8000681a:	7e8e                	ld	t4,224(sp)
    8000681c:	7f2e                	ld	t5,232(sp)
    8000681e:	7fce                	ld	t6,240(sp)
    80006820:	6111                	addi	sp,sp,256
    80006822:	10200073          	sret
    80006826:	00000013          	nop
    8000682a:	00000013          	nop
    8000682e:	0001                	nop

0000000080006830 <timervec>:
    80006830:	34051573          	csrrw	a0,mscratch,a0
    80006834:	e10c                	sd	a1,0(a0)
    80006836:	e510                	sd	a2,8(a0)
    80006838:	e914                	sd	a3,16(a0)
    8000683a:	6d0c                	ld	a1,24(a0)
    8000683c:	7110                	ld	a2,32(a0)
    8000683e:	6194                	ld	a3,0(a1)
    80006840:	96b2                	add	a3,a3,a2
    80006842:	e194                	sd	a3,0(a1)
    80006844:	4589                	li	a1,2
    80006846:	14459073          	csrw	sip,a1
    8000684a:	6914                	ld	a3,16(a0)
    8000684c:	6510                	ld	a2,8(a0)
    8000684e:	610c                	ld	a1,0(a0)
    80006850:	34051573          	csrrw	a0,mscratch,a0
    80006854:	30200073          	mret
	...

000000008000685a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000685a:	1141                	addi	sp,sp,-16
    8000685c:	e422                	sd	s0,8(sp)
    8000685e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006860:	0c0007b7          	lui	a5,0xc000
    80006864:	4705                	li	a4,1
    80006866:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006868:	c3d8                	sw	a4,4(a5)
}
    8000686a:	6422                	ld	s0,8(sp)
    8000686c:	0141                	addi	sp,sp,16
    8000686e:	8082                	ret

0000000080006870 <plicinithart>:

void
plicinithart(void)
{
    80006870:	1141                	addi	sp,sp,-16
    80006872:	e406                	sd	ra,8(sp)
    80006874:	e022                	sd	s0,0(sp)
    80006876:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006878:	ffffb097          	auipc	ra,0xffffb
    8000687c:	620080e7          	jalr	1568(ra) # 80001e98 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006880:	0085171b          	slliw	a4,a0,0x8
    80006884:	0c0027b7          	lui	a5,0xc002
    80006888:	97ba                	add	a5,a5,a4
    8000688a:	40200713          	li	a4,1026
    8000688e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006892:	00d5151b          	slliw	a0,a0,0xd
    80006896:	0c2017b7          	lui	a5,0xc201
    8000689a:	953e                	add	a0,a0,a5
    8000689c:	00052023          	sw	zero,0(a0)
}
    800068a0:	60a2                	ld	ra,8(sp)
    800068a2:	6402                	ld	s0,0(sp)
    800068a4:	0141                	addi	sp,sp,16
    800068a6:	8082                	ret

00000000800068a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800068a8:	1141                	addi	sp,sp,-16
    800068aa:	e406                	sd	ra,8(sp)
    800068ac:	e022                	sd	s0,0(sp)
    800068ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068b0:	ffffb097          	auipc	ra,0xffffb
    800068b4:	5e8080e7          	jalr	1512(ra) # 80001e98 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800068b8:	00d5179b          	slliw	a5,a0,0xd
    800068bc:	0c201537          	lui	a0,0xc201
    800068c0:	953e                	add	a0,a0,a5
  return irq;
}
    800068c2:	4148                	lw	a0,4(a0)
    800068c4:	60a2                	ld	ra,8(sp)
    800068c6:	6402                	ld	s0,0(sp)
    800068c8:	0141                	addi	sp,sp,16
    800068ca:	8082                	ret

00000000800068cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800068cc:	1101                	addi	sp,sp,-32
    800068ce:	ec06                	sd	ra,24(sp)
    800068d0:	e822                	sd	s0,16(sp)
    800068d2:	e426                	sd	s1,8(sp)
    800068d4:	1000                	addi	s0,sp,32
    800068d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800068d8:	ffffb097          	auipc	ra,0xffffb
    800068dc:	5c0080e7          	jalr	1472(ra) # 80001e98 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800068e0:	00d5151b          	slliw	a0,a0,0xd
    800068e4:	0c2017b7          	lui	a5,0xc201
    800068e8:	97aa                	add	a5,a5,a0
    800068ea:	c3c4                	sw	s1,4(a5)
}
    800068ec:	60e2                	ld	ra,24(sp)
    800068ee:	6442                	ld	s0,16(sp)
    800068f0:	64a2                	ld	s1,8(sp)
    800068f2:	6105                	addi	sp,sp,32
    800068f4:	8082                	ret

00000000800068f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068f6:	1141                	addi	sp,sp,-16
    800068f8:	e406                	sd	ra,8(sp)
    800068fa:	e022                	sd	s0,0(sp)
    800068fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068fe:	479d                	li	a5,7
    80006900:	06a7c963          	blt	a5,a0,80006972 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006904:	00016797          	auipc	a5,0x16
    80006908:	6fc78793          	addi	a5,a5,1788 # 8001d000 <disk>
    8000690c:	00a78733          	add	a4,a5,a0
    80006910:	6789                	lui	a5,0x2
    80006912:	97ba                	add	a5,a5,a4
    80006914:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006918:	e7ad                	bnez	a5,80006982 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000691a:	00451793          	slli	a5,a0,0x4
    8000691e:	00018717          	auipc	a4,0x18
    80006922:	6e270713          	addi	a4,a4,1762 # 8001f000 <disk+0x2000>
    80006926:	6314                	ld	a3,0(a4)
    80006928:	96be                	add	a3,a3,a5
    8000692a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000692e:	6314                	ld	a3,0(a4)
    80006930:	96be                	add	a3,a3,a5
    80006932:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006936:	6314                	ld	a3,0(a4)
    80006938:	96be                	add	a3,a3,a5
    8000693a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000693e:	6318                	ld	a4,0(a4)
    80006940:	97ba                	add	a5,a5,a4
    80006942:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006946:	00016797          	auipc	a5,0x16
    8000694a:	6ba78793          	addi	a5,a5,1722 # 8001d000 <disk>
    8000694e:	97aa                	add	a5,a5,a0
    80006950:	6509                	lui	a0,0x2
    80006952:	953e                	add	a0,a0,a5
    80006954:	4785                	li	a5,1
    80006956:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000695a:	00018517          	auipc	a0,0x18
    8000695e:	6be50513          	addi	a0,a0,1726 # 8001f018 <disk+0x2018>
    80006962:	ffffc097          	auipc	ra,0xffffc
    80006966:	362080e7          	jalr	866(ra) # 80002cc4 <wakeup>
}
    8000696a:	60a2                	ld	ra,8(sp)
    8000696c:	6402                	ld	s0,0(sp)
    8000696e:	0141                	addi	sp,sp,16
    80006970:	8082                	ret
    panic("free_desc 1");
    80006972:	00002517          	auipc	a0,0x2
    80006976:	64650513          	addi	a0,a0,1606 # 80008fb8 <syscalls+0x320>
    8000697a:	ffffa097          	auipc	ra,0xffffa
    8000697e:	bc4080e7          	jalr	-1084(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006982:	00002517          	auipc	a0,0x2
    80006986:	64650513          	addi	a0,a0,1606 # 80008fc8 <syscalls+0x330>
    8000698a:	ffffa097          	auipc	ra,0xffffa
    8000698e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>

0000000080006992 <virtio_disk_init>:
{
    80006992:	1101                	addi	sp,sp,-32
    80006994:	ec06                	sd	ra,24(sp)
    80006996:	e822                	sd	s0,16(sp)
    80006998:	e426                	sd	s1,8(sp)
    8000699a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000699c:	00002597          	auipc	a1,0x2
    800069a0:	63c58593          	addi	a1,a1,1596 # 80008fd8 <syscalls+0x340>
    800069a4:	00018517          	auipc	a0,0x18
    800069a8:	78450513          	addi	a0,a0,1924 # 8001f128 <disk+0x2128>
    800069ac:	ffffa097          	auipc	ra,0xffffa
    800069b0:	1a8080e7          	jalr	424(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069b4:	100017b7          	lui	a5,0x10001
    800069b8:	4398                	lw	a4,0(a5)
    800069ba:	2701                	sext.w	a4,a4
    800069bc:	747277b7          	lui	a5,0x74727
    800069c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800069c4:	0ef71163          	bne	a4,a5,80006aa6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800069c8:	100017b7          	lui	a5,0x10001
    800069cc:	43dc                	lw	a5,4(a5)
    800069ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069d0:	4705                	li	a4,1
    800069d2:	0ce79a63          	bne	a5,a4,80006aa6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069d6:	100017b7          	lui	a5,0x10001
    800069da:	479c                	lw	a5,8(a5)
    800069dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800069de:	4709                	li	a4,2
    800069e0:	0ce79363          	bne	a5,a4,80006aa6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800069e4:	100017b7          	lui	a5,0x10001
    800069e8:	47d8                	lw	a4,12(a5)
    800069ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069ec:	554d47b7          	lui	a5,0x554d4
    800069f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800069f4:	0af71963          	bne	a4,a5,80006aa6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800069f8:	100017b7          	lui	a5,0x10001
    800069fc:	4705                	li	a4,1
    800069fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a00:	470d                	li	a4,3
    80006a02:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a04:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a06:	c7ffe737          	lui	a4,0xc7ffe
    80006a0a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fde75f>
    80006a0e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a10:	2701                	sext.w	a4,a4
    80006a12:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a14:	472d                	li	a4,11
    80006a16:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a18:	473d                	li	a4,15
    80006a1a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006a1c:	6705                	lui	a4,0x1
    80006a1e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006a24:	5bdc                	lw	a5,52(a5)
    80006a26:	2781                	sext.w	a5,a5
  if(max == 0)
    80006a28:	c7d9                	beqz	a5,80006ab6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006a2a:	471d                	li	a4,7
    80006a2c:	08f77d63          	bgeu	a4,a5,80006ac6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a30:	100014b7          	lui	s1,0x10001
    80006a34:	47a1                	li	a5,8
    80006a36:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006a38:	6609                	lui	a2,0x2
    80006a3a:	4581                	li	a1,0
    80006a3c:	00016517          	auipc	a0,0x16
    80006a40:	5c450513          	addi	a0,a0,1476 # 8001d000 <disk>
    80006a44:	ffffa097          	auipc	ra,0xffffa
    80006a48:	2c0080e7          	jalr	704(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006a4c:	00016717          	auipc	a4,0x16
    80006a50:	5b470713          	addi	a4,a4,1460 # 8001d000 <disk>
    80006a54:	00c75793          	srli	a5,a4,0xc
    80006a58:	2781                	sext.w	a5,a5
    80006a5a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006a5c:	00018797          	auipc	a5,0x18
    80006a60:	5a478793          	addi	a5,a5,1444 # 8001f000 <disk+0x2000>
    80006a64:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006a66:	00016717          	auipc	a4,0x16
    80006a6a:	61a70713          	addi	a4,a4,1562 # 8001d080 <disk+0x80>
    80006a6e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006a70:	00017717          	auipc	a4,0x17
    80006a74:	59070713          	addi	a4,a4,1424 # 8001e000 <disk+0x1000>
    80006a78:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006a7a:	4705                	li	a4,1
    80006a7c:	00e78c23          	sb	a4,24(a5)
    80006a80:	00e78ca3          	sb	a4,25(a5)
    80006a84:	00e78d23          	sb	a4,26(a5)
    80006a88:	00e78da3          	sb	a4,27(a5)
    80006a8c:	00e78e23          	sb	a4,28(a5)
    80006a90:	00e78ea3          	sb	a4,29(a5)
    80006a94:	00e78f23          	sb	a4,30(a5)
    80006a98:	00e78fa3          	sb	a4,31(a5)
}
    80006a9c:	60e2                	ld	ra,24(sp)
    80006a9e:	6442                	ld	s0,16(sp)
    80006aa0:	64a2                	ld	s1,8(sp)
    80006aa2:	6105                	addi	sp,sp,32
    80006aa4:	8082                	ret
    panic("could not find virtio disk");
    80006aa6:	00002517          	auipc	a0,0x2
    80006aaa:	54250513          	addi	a0,a0,1346 # 80008fe8 <syscalls+0x350>
    80006aae:	ffffa097          	auipc	ra,0xffffa
    80006ab2:	a90080e7          	jalr	-1392(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006ab6:	00002517          	auipc	a0,0x2
    80006aba:	55250513          	addi	a0,a0,1362 # 80009008 <syscalls+0x370>
    80006abe:	ffffa097          	auipc	ra,0xffffa
    80006ac2:	a80080e7          	jalr	-1408(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006ac6:	00002517          	auipc	a0,0x2
    80006aca:	56250513          	addi	a0,a0,1378 # 80009028 <syscalls+0x390>
    80006ace:	ffffa097          	auipc	ra,0xffffa
    80006ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>

0000000080006ad6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006ad6:	7159                	addi	sp,sp,-112
    80006ad8:	f486                	sd	ra,104(sp)
    80006ada:	f0a2                	sd	s0,96(sp)
    80006adc:	eca6                	sd	s1,88(sp)
    80006ade:	e8ca                	sd	s2,80(sp)
    80006ae0:	e4ce                	sd	s3,72(sp)
    80006ae2:	e0d2                	sd	s4,64(sp)
    80006ae4:	fc56                	sd	s5,56(sp)
    80006ae6:	f85a                	sd	s6,48(sp)
    80006ae8:	f45e                	sd	s7,40(sp)
    80006aea:	f062                	sd	s8,32(sp)
    80006aec:	ec66                	sd	s9,24(sp)
    80006aee:	e86a                	sd	s10,16(sp)
    80006af0:	1880                	addi	s0,sp,112
    80006af2:	892a                	mv	s2,a0
    80006af4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006af6:	00c52c83          	lw	s9,12(a0)
    80006afa:	001c9c9b          	slliw	s9,s9,0x1
    80006afe:	1c82                	slli	s9,s9,0x20
    80006b00:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b04:	00018517          	auipc	a0,0x18
    80006b08:	62450513          	addi	a0,a0,1572 # 8001f128 <disk+0x2128>
    80006b0c:	ffffa097          	auipc	ra,0xffffa
    80006b10:	0d8080e7          	jalr	216(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006b14:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b16:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006b18:	00016b97          	auipc	s7,0x16
    80006b1c:	4e8b8b93          	addi	s7,s7,1256 # 8001d000 <disk>
    80006b20:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006b22:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006b24:	8a4e                	mv	s4,s3
    80006b26:	a051                	j	80006baa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006b28:	00fb86b3          	add	a3,s7,a5
    80006b2c:	96da                	add	a3,a3,s6
    80006b2e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006b32:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006b34:	0207c563          	bltz	a5,80006b5e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006b38:	2485                	addiw	s1,s1,1
    80006b3a:	0711                	addi	a4,a4,4
    80006b3c:	25548063          	beq	s1,s5,80006d7c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006b40:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006b42:	00018697          	auipc	a3,0x18
    80006b46:	4d668693          	addi	a3,a3,1238 # 8001f018 <disk+0x2018>
    80006b4a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006b4c:	0006c583          	lbu	a1,0(a3)
    80006b50:	fde1                	bnez	a1,80006b28 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006b52:	2785                	addiw	a5,a5,1
    80006b54:	0685                	addi	a3,a3,1
    80006b56:	ff879be3          	bne	a5,s8,80006b4c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006b5a:	57fd                	li	a5,-1
    80006b5c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006b5e:	02905a63          	blez	s1,80006b92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b62:	f9042503          	lw	a0,-112(s0)
    80006b66:	00000097          	auipc	ra,0x0
    80006b6a:	d90080e7          	jalr	-624(ra) # 800068f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b6e:	4785                	li	a5,1
    80006b70:	0297d163          	bge	a5,s1,80006b92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b74:	f9442503          	lw	a0,-108(s0)
    80006b78:	00000097          	auipc	ra,0x0
    80006b7c:	d7e080e7          	jalr	-642(ra) # 800068f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b80:	4789                	li	a5,2
    80006b82:	0097d863          	bge	a5,s1,80006b92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b86:	f9842503          	lw	a0,-104(s0)
    80006b8a:	00000097          	auipc	ra,0x0
    80006b8e:	d6c080e7          	jalr	-660(ra) # 800068f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b92:	00018597          	auipc	a1,0x18
    80006b96:	59658593          	addi	a1,a1,1430 # 8001f128 <disk+0x2128>
    80006b9a:	00018517          	auipc	a0,0x18
    80006b9e:	47e50513          	addi	a0,a0,1150 # 8001f018 <disk+0x2018>
    80006ba2:	ffffc097          	auipc	ra,0xffffc
    80006ba6:	eee080e7          	jalr	-274(ra) # 80002a90 <sleep>
  for(int i = 0; i < 3; i++){
    80006baa:	f9040713          	addi	a4,s0,-112
    80006bae:	84ce                	mv	s1,s3
    80006bb0:	bf41                	j	80006b40 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006bb2:	20058713          	addi	a4,a1,512
    80006bb6:	00471693          	slli	a3,a4,0x4
    80006bba:	00016717          	auipc	a4,0x16
    80006bbe:	44670713          	addi	a4,a4,1094 # 8001d000 <disk>
    80006bc2:	9736                	add	a4,a4,a3
    80006bc4:	4685                	li	a3,1
    80006bc6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006bca:	20058713          	addi	a4,a1,512
    80006bce:	00471693          	slli	a3,a4,0x4
    80006bd2:	00016717          	auipc	a4,0x16
    80006bd6:	42e70713          	addi	a4,a4,1070 # 8001d000 <disk>
    80006bda:	9736                	add	a4,a4,a3
    80006bdc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006be0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006be4:	7679                	lui	a2,0xffffe
    80006be6:	963e                	add	a2,a2,a5
    80006be8:	00018697          	auipc	a3,0x18
    80006bec:	41868693          	addi	a3,a3,1048 # 8001f000 <disk+0x2000>
    80006bf0:	6298                	ld	a4,0(a3)
    80006bf2:	9732                	add	a4,a4,a2
    80006bf4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006bf6:	6298                	ld	a4,0(a3)
    80006bf8:	9732                	add	a4,a4,a2
    80006bfa:	4541                	li	a0,16
    80006bfc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006bfe:	6298                	ld	a4,0(a3)
    80006c00:	9732                	add	a4,a4,a2
    80006c02:	4505                	li	a0,1
    80006c04:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006c08:	f9442703          	lw	a4,-108(s0)
    80006c0c:	6288                	ld	a0,0(a3)
    80006c0e:	962a                	add	a2,a2,a0
    80006c10:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffde00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c14:	0712                	slli	a4,a4,0x4
    80006c16:	6290                	ld	a2,0(a3)
    80006c18:	963a                	add	a2,a2,a4
    80006c1a:	05890513          	addi	a0,s2,88
    80006c1e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006c20:	6294                	ld	a3,0(a3)
    80006c22:	96ba                	add	a3,a3,a4
    80006c24:	40000613          	li	a2,1024
    80006c28:	c690                	sw	a2,8(a3)
  if(write)
    80006c2a:	140d0063          	beqz	s10,80006d6a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c2e:	00018697          	auipc	a3,0x18
    80006c32:	3d26b683          	ld	a3,978(a3) # 8001f000 <disk+0x2000>
    80006c36:	96ba                	add	a3,a3,a4
    80006c38:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c3c:	00016817          	auipc	a6,0x16
    80006c40:	3c480813          	addi	a6,a6,964 # 8001d000 <disk>
    80006c44:	00018517          	auipc	a0,0x18
    80006c48:	3bc50513          	addi	a0,a0,956 # 8001f000 <disk+0x2000>
    80006c4c:	6114                	ld	a3,0(a0)
    80006c4e:	96ba                	add	a3,a3,a4
    80006c50:	00c6d603          	lhu	a2,12(a3)
    80006c54:	00166613          	ori	a2,a2,1
    80006c58:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c5c:	f9842683          	lw	a3,-104(s0)
    80006c60:	6110                	ld	a2,0(a0)
    80006c62:	9732                	add	a4,a4,a2
    80006c64:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c68:	20058613          	addi	a2,a1,512
    80006c6c:	0612                	slli	a2,a2,0x4
    80006c6e:	9642                	add	a2,a2,a6
    80006c70:	577d                	li	a4,-1
    80006c72:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c76:	00469713          	slli	a4,a3,0x4
    80006c7a:	6114                	ld	a3,0(a0)
    80006c7c:	96ba                	add	a3,a3,a4
    80006c7e:	03078793          	addi	a5,a5,48
    80006c82:	97c2                	add	a5,a5,a6
    80006c84:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006c86:	611c                	ld	a5,0(a0)
    80006c88:	97ba                	add	a5,a5,a4
    80006c8a:	4685                	li	a3,1
    80006c8c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c8e:	611c                	ld	a5,0(a0)
    80006c90:	97ba                	add	a5,a5,a4
    80006c92:	4809                	li	a6,2
    80006c94:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006c98:	611c                	ld	a5,0(a0)
    80006c9a:	973e                	add	a4,a4,a5
    80006c9c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ca0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006ca4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ca8:	6518                	ld	a4,8(a0)
    80006caa:	00275783          	lhu	a5,2(a4)
    80006cae:	8b9d                	andi	a5,a5,7
    80006cb0:	0786                	slli	a5,a5,0x1
    80006cb2:	97ba                	add	a5,a5,a4
    80006cb4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006cb8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006cbc:	6518                	ld	a4,8(a0)
    80006cbe:	00275783          	lhu	a5,2(a4)
    80006cc2:	2785                	addiw	a5,a5,1
    80006cc4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006cc8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ccc:	100017b7          	lui	a5,0x10001
    80006cd0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cd4:	00492703          	lw	a4,4(s2)
    80006cd8:	4785                	li	a5,1
    80006cda:	02f71163          	bne	a4,a5,80006cfc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006cde:	00018997          	auipc	s3,0x18
    80006ce2:	44a98993          	addi	s3,s3,1098 # 8001f128 <disk+0x2128>
  while(b->disk == 1) {
    80006ce6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006ce8:	85ce                	mv	a1,s3
    80006cea:	854a                	mv	a0,s2
    80006cec:	ffffc097          	auipc	ra,0xffffc
    80006cf0:	da4080e7          	jalr	-604(ra) # 80002a90 <sleep>
  while(b->disk == 1) {
    80006cf4:	00492783          	lw	a5,4(s2)
    80006cf8:	fe9788e3          	beq	a5,s1,80006ce8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006cfc:	f9042903          	lw	s2,-112(s0)
    80006d00:	20090793          	addi	a5,s2,512
    80006d04:	00479713          	slli	a4,a5,0x4
    80006d08:	00016797          	auipc	a5,0x16
    80006d0c:	2f878793          	addi	a5,a5,760 # 8001d000 <disk>
    80006d10:	97ba                	add	a5,a5,a4
    80006d12:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d16:	00018997          	auipc	s3,0x18
    80006d1a:	2ea98993          	addi	s3,s3,746 # 8001f000 <disk+0x2000>
    80006d1e:	00491713          	slli	a4,s2,0x4
    80006d22:	0009b783          	ld	a5,0(s3)
    80006d26:	97ba                	add	a5,a5,a4
    80006d28:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d2c:	854a                	mv	a0,s2
    80006d2e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d32:	00000097          	auipc	ra,0x0
    80006d36:	bc4080e7          	jalr	-1084(ra) # 800068f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d3a:	8885                	andi	s1,s1,1
    80006d3c:	f0ed                	bnez	s1,80006d1e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d3e:	00018517          	auipc	a0,0x18
    80006d42:	3ea50513          	addi	a0,a0,1002 # 8001f128 <disk+0x2128>
    80006d46:	ffffa097          	auipc	ra,0xffffa
    80006d4a:	f64080e7          	jalr	-156(ra) # 80000caa <release>
}
    80006d4e:	70a6                	ld	ra,104(sp)
    80006d50:	7406                	ld	s0,96(sp)
    80006d52:	64e6                	ld	s1,88(sp)
    80006d54:	6946                	ld	s2,80(sp)
    80006d56:	69a6                	ld	s3,72(sp)
    80006d58:	6a06                	ld	s4,64(sp)
    80006d5a:	7ae2                	ld	s5,56(sp)
    80006d5c:	7b42                	ld	s6,48(sp)
    80006d5e:	7ba2                	ld	s7,40(sp)
    80006d60:	7c02                	ld	s8,32(sp)
    80006d62:	6ce2                	ld	s9,24(sp)
    80006d64:	6d42                	ld	s10,16(sp)
    80006d66:	6165                	addi	sp,sp,112
    80006d68:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006d6a:	00018697          	auipc	a3,0x18
    80006d6e:	2966b683          	ld	a3,662(a3) # 8001f000 <disk+0x2000>
    80006d72:	96ba                	add	a3,a3,a4
    80006d74:	4609                	li	a2,2
    80006d76:	00c69623          	sh	a2,12(a3)
    80006d7a:	b5c9                	j	80006c3c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d7c:	f9042583          	lw	a1,-112(s0)
    80006d80:	20058793          	addi	a5,a1,512
    80006d84:	0792                	slli	a5,a5,0x4
    80006d86:	00016517          	auipc	a0,0x16
    80006d8a:	32250513          	addi	a0,a0,802 # 8001d0a8 <disk+0xa8>
    80006d8e:	953e                	add	a0,a0,a5
  if(write)
    80006d90:	e20d11e3          	bnez	s10,80006bb2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006d94:	20058713          	addi	a4,a1,512
    80006d98:	00471693          	slli	a3,a4,0x4
    80006d9c:	00016717          	auipc	a4,0x16
    80006da0:	26470713          	addi	a4,a4,612 # 8001d000 <disk>
    80006da4:	9736                	add	a4,a4,a3
    80006da6:	0a072423          	sw	zero,168(a4)
    80006daa:	b505                	j	80006bca <virtio_disk_rw+0xf4>

0000000080006dac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006dac:	1101                	addi	sp,sp,-32
    80006dae:	ec06                	sd	ra,24(sp)
    80006db0:	e822                	sd	s0,16(sp)
    80006db2:	e426                	sd	s1,8(sp)
    80006db4:	e04a                	sd	s2,0(sp)
    80006db6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006db8:	00018517          	auipc	a0,0x18
    80006dbc:	37050513          	addi	a0,a0,880 # 8001f128 <disk+0x2128>
    80006dc0:	ffffa097          	auipc	ra,0xffffa
    80006dc4:	e24080e7          	jalr	-476(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006dc8:	10001737          	lui	a4,0x10001
    80006dcc:	533c                	lw	a5,96(a4)
    80006dce:	8b8d                	andi	a5,a5,3
    80006dd0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006dd2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006dd6:	00018797          	auipc	a5,0x18
    80006dda:	22a78793          	addi	a5,a5,554 # 8001f000 <disk+0x2000>
    80006dde:	6b94                	ld	a3,16(a5)
    80006de0:	0207d703          	lhu	a4,32(a5)
    80006de4:	0026d783          	lhu	a5,2(a3)
    80006de8:	06f70163          	beq	a4,a5,80006e4a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006dec:	00016917          	auipc	s2,0x16
    80006df0:	21490913          	addi	s2,s2,532 # 8001d000 <disk>
    80006df4:	00018497          	auipc	s1,0x18
    80006df8:	20c48493          	addi	s1,s1,524 # 8001f000 <disk+0x2000>
    __sync_synchronize();
    80006dfc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e00:	6898                	ld	a4,16(s1)
    80006e02:	0204d783          	lhu	a5,32(s1)
    80006e06:	8b9d                	andi	a5,a5,7
    80006e08:	078e                	slli	a5,a5,0x3
    80006e0a:	97ba                	add	a5,a5,a4
    80006e0c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e0e:	20078713          	addi	a4,a5,512
    80006e12:	0712                	slli	a4,a4,0x4
    80006e14:	974a                	add	a4,a4,s2
    80006e16:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006e1a:	e731                	bnez	a4,80006e66 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e1c:	20078793          	addi	a5,a5,512
    80006e20:	0792                	slli	a5,a5,0x4
    80006e22:	97ca                	add	a5,a5,s2
    80006e24:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006e26:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e2a:	ffffc097          	auipc	ra,0xffffc
    80006e2e:	e9a080e7          	jalr	-358(ra) # 80002cc4 <wakeup>

    disk.used_idx += 1;
    80006e32:	0204d783          	lhu	a5,32(s1)
    80006e36:	2785                	addiw	a5,a5,1
    80006e38:	17c2                	slli	a5,a5,0x30
    80006e3a:	93c1                	srli	a5,a5,0x30
    80006e3c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e40:	6898                	ld	a4,16(s1)
    80006e42:	00275703          	lhu	a4,2(a4)
    80006e46:	faf71be3          	bne	a4,a5,80006dfc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e4a:	00018517          	auipc	a0,0x18
    80006e4e:	2de50513          	addi	a0,a0,734 # 8001f128 <disk+0x2128>
    80006e52:	ffffa097          	auipc	ra,0xffffa
    80006e56:	e58080e7          	jalr	-424(ra) # 80000caa <release>
}
    80006e5a:	60e2                	ld	ra,24(sp)
    80006e5c:	6442                	ld	s0,16(sp)
    80006e5e:	64a2                	ld	s1,8(sp)
    80006e60:	6902                	ld	s2,0(sp)
    80006e62:	6105                	addi	sp,sp,32
    80006e64:	8082                	ret
      panic("virtio_disk_intr status");
    80006e66:	00002517          	auipc	a0,0x2
    80006e6a:	1e250513          	addi	a0,a0,482 # 80009048 <syscalls+0x3b0>
    80006e6e:	ffff9097          	auipc	ra,0xffff9
    80006e72:	6d0080e7          	jalr	1744(ra) # 8000053e <panic>

0000000080006e76 <cas>:
    80006e76:	100522af          	lr.w	t0,(a0)
    80006e7a:	00b29563          	bne	t0,a1,80006e84 <fail>
    80006e7e:	18c5252f          	sc.w	a0,a2,(a0)
    80006e82:	8082                	ret

0000000080006e84 <fail>:
    80006e84:	4505                	li	a0,1
    80006e86:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
