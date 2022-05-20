
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	98013103          	ld	sp,-1664(sp) # 80008980 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	2cc78793          	addi	a5,a5,716 # 80006330 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdf7ff>
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
    80000130:	af4080e7          	jalr	-1292(ra) # 80002c20 <either_copyin>
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
    8000018c:	0000a517          	auipc	a0,0xa
    80000190:	ee450513          	addi	a0,a0,-284 # 8000a070 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ed448493          	addi	s1,s1,-300 # 8000a070 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f6290913          	addi	s2,s2,-158 # 8000a108 <cons+0x98>
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
    800001c8:	c4a080e7          	jalr	-950(ra) # 80001e0e <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	52a080e7          	jalr	1322(ra) # 800026fe <sleep>
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
    80000214:	9ba080e7          	jalr	-1606(ra) # 80002bca <either_copyout>
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
    80000224:	0000a517          	auipc	a0,0xa
    80000228:	e4c50513          	addi	a0,a0,-436 # 8000a070 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a7e080e7          	jalr	-1410(ra) # 80000caa <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e3650513          	addi	a0,a0,-458 # 8000a070 <cons>
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
    80000272:	0000a717          	auipc	a4,0xa
    80000276:	e8f72b23          	sw	a5,-362(a4) # 8000a108 <cons+0x98>
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
    800002cc:	0000a517          	auipc	a0,0xa
    800002d0:	da450513          	addi	a0,a0,-604 # 8000a070 <cons>
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
    800002f6:	984080e7          	jalr	-1660(ra) # 80002c76 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d7650513          	addi	a0,a0,-650 # 8000a070 <cons>
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
    8000031e:	0000a717          	auipc	a4,0xa
    80000322:	d5270713          	addi	a4,a4,-686 # 8000a070 <cons>
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
    80000348:	0000a797          	auipc	a5,0xa
    8000034c:	d2878793          	addi	a5,a5,-728 # 8000a070 <cons>
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
    80000376:	0000a797          	auipc	a5,0xa
    8000037a:	d927a783          	lw	a5,-622(a5) # 8000a108 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	ce670713          	addi	a4,a4,-794 # 8000a070 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	cd648493          	addi	s1,s1,-810 # 8000a070 <cons>
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
    800003d6:	0000a717          	auipc	a4,0xa
    800003da:	c9a70713          	addi	a4,a4,-870 # 8000a070 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d2f72223          	sw	a5,-732(a4) # 8000a110 <cons+0xa0>
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
    80000412:	0000a797          	auipc	a5,0xa
    80000416:	c5e78793          	addi	a5,a5,-930 # 8000a070 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	0000a797          	auipc	a5,0xa
    8000043a:	ccc7ab23          	sw	a2,-810(a5) # 8000a10c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cca50513          	addi	a0,a0,-822 # 8000a108 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	474080e7          	jalr	1140(ra) # 800028ba <wakeup>
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
    80000460:	0000a517          	auipc	a0,0xa
    80000464:	c1050513          	addi	a0,a0,-1008 # 8000a070 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	27078793          	addi	a5,a5,624 # 8001a6e8 <devsw>
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
    8000054a:	0000a797          	auipc	a5,0xa
    8000054e:	be07a323          	sw	zero,-1050(a5) # 8000a130 <pr+0x18>
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
    80000570:	b8c50513          	addi	a0,a0,-1140 # 800080f8 <digits+0xb8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
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
    800005ba:	0000ad97          	auipc	s11,0xa
    800005be:	b76dad83          	lw	s11,-1162(s11) # 8000a130 <pr+0x18>
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
    800005f8:	0000a517          	auipc	a0,0xa
    800005fc:	b2050513          	addi	a0,a0,-1248 # 8000a118 <pr>
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
    8000075c:	0000a517          	auipc	a0,0xa
    80000760:	9bc50513          	addi	a0,a0,-1604 # 8000a118 <pr>
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
    80000778:	0000a497          	auipc	s1,0xa
    8000077c:	9a048493          	addi	s1,s1,-1632 # 8000a118 <pr>
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
    800007d8:	0000a517          	auipc	a0,0xa
    800007dc:	96050513          	addi	a0,a0,-1696 # 8000a138 <uart_tx_lock>
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
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
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
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
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
    8000086a:	0000aa17          	auipc	s4,0xa
    8000086e:	8cea0a13          	addi	s4,s4,-1842 # 8000a138 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
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
    800008a4:	01a080e7          	jalr	26(ra) # 800028ba <wakeup>
    
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
    800008dc:	0000a517          	auipc	a0,0xa
    800008e0:	85c50513          	addi	a0,a0,-1956 # 8000a138 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	0000aa17          	auipc	s4,0xa
    80000914:	828a0a13          	addi	s4,s4,-2008 # 8000a138 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	dd2080e7          	jalr	-558(ra) # 800026fe <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00009497          	auipc	s1,0x9
    80000946:	7f648493          	addi	s1,s1,2038 # 8000a138 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
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
    800009ca:	00009497          	auipc	s1,0x9
    800009ce:	76e48493          	addi	s1,s1,1902 # 8000a138 <uart_tx_lock>
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
    80000a0c:	0001e797          	auipc	a5,0x1e
    80000a10:	5f478793          	addi	a5,a5,1524 # 8001f000 <end>
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
    80000a2c:	00009917          	auipc	s2,0x9
    80000a30:	74490913          	addi	s2,s2,1860 # 8000a170 <kmem>
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
    80000ac8:	00009517          	auipc	a0,0x9
    80000acc:	6a850513          	addi	a0,a0,1704 # 8000a170 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	0001e517          	auipc	a0,0x1e
    80000ae0:	52450513          	addi	a0,a0,1316 # 8001f000 <end>
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
    80000afe:	00009497          	auipc	s1,0x9
    80000b02:	67248493          	addi	s1,s1,1650 # 8000a170 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00009517          	auipc	a0,0x9
    80000b1a:	65a50513          	addi	a0,a0,1626 # 8000a170 <kmem>
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
    80000b42:	00009517          	auipc	a0,0x9
    80000b46:	62e50513          	addi	a0,a0,1582 # 8000a170 <kmem>
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
    80000b82:	274080e7          	jalr	628(ra) # 80001df2 <mycpu>
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

static inline uint64
r_sstatus()
{
  uint64 x;
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus

// disable device interrupts
static inline void
intr_off()
{
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	242080e7          	jalr	578(ra) # 80001df2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	236080e7          	jalr	566(ra) # 80001df2 <mycpu>
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
    80000bd8:	21e080e7          	jalr	542(ra) # 80001df2 <mycpu>
// are device interrupts enabled?
static inline int
intr_get()
{
  uint64 x = r_sstatus();
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
    80000c18:	1de080e7          	jalr	478(ra) # 80001df2 <mycpu>
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
    80000c56:	1a0080e7          	jalr	416(ra) # 80001df2 <mycpu>
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
    printf("the paniced lock is r %s\n", lk->name);
    80000ce2:	648c                	ld	a1,8(s1)
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	3c450513          	addi	a0,a0,964 # 800080a8 <digits+0x68>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	89c080e7          	jalr	-1892(ra) # 80000588 <printf>
    panic("release");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	3d450513          	addi	a0,a0,980 # 800080c8 <digits+0x88>
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
    80000ebe:	f28080e7          	jalr	-216(ra) # 80001de2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ec2:	00008717          	auipc	a4,0x8
    80000ec6:	15670713          	addi	a4,a4,342 # 80009018 <started>
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
    80000eda:	f0c080e7          	jalr	-244(ra) # 80001de2 <cpuid>
    80000ede:	85aa                	mv	a1,a0
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	20850513          	addi	a0,a0,520 # 800080e8 <digits+0xa8>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	6a0080e7          	jalr	1696(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ef0:	00000097          	auipc	ra,0x0
    80000ef4:	0d8080e7          	jalr	216(ra) # 80000fc8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef8:	00002097          	auipc	ra,0x2
    80000efc:	f1c080e7          	jalr	-228(ra) # 80002e14 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	470080e7          	jalr	1136(ra) # 80006370 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	55c080e7          	jalr	1372(ra) # 80002464 <scheduler>
    consoleinit();
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	540080e7          	jalr	1344(ra) # 80000450 <consoleinit>
    printfinit();
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	856080e7          	jalr	-1962(ra) # 8000076e <printfinit>
    printf("\n");
    80000f20:	00007517          	auipc	a0,0x7
    80000f24:	1d850513          	addi	a0,a0,472 # 800080f8 <digits+0xb8>
    80000f28:	fffff097          	auipc	ra,0xfffff
    80000f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	1a050513          	addi	a0,a0,416 # 800080d0 <digits+0x90>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	1b850513          	addi	a0,a0,440 # 800080f8 <digits+0xb8>
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
    80000f6c:	cec080e7          	jalr	-788(ra) # 80001c54 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	e7c080e7          	jalr	-388(ra) # 80002dec <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	e9c080e7          	jalr	-356(ra) # 80002e14 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	3da080e7          	jalr	986(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	3e8080e7          	jalr	1000(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	5c6080e7          	jalr	1478(ra) # 80003556 <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	c56080e7          	jalr	-938(ra) # 80003bee <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	c00080e7          	jalr	-1024(ra) # 80004ba0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	4ea080e7          	jalr	1258(ra) # 80006492 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	1ec080e7          	jalr	492(ra) # 8000219c <userinit>
    __sync_synchronize();
    80000fb8:	0ff0000f          	fence
    started = 1;
    80000fbc:	4785                	li	a5,1
    80000fbe:	00008717          	auipc	a4,0x8
    80000fc2:	04f72d23          	sw	a5,90(a4) # 80009018 <started>
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
    80000fce:	00008797          	auipc	a5,0x8
    80000fd2:	0527b783          	ld	a5,82(a5) # 80009020 <kernel_pagetable>
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
    80001016:	0ee50513          	addi	a0,a0,238 # 80008100 <digits+0xc0>
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
    8000110e:	ffe50513          	addi	a0,a0,-2 # 80008108 <digits+0xc8>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000111a:	00007517          	auipc	a0,0x7
    8000111e:	ffe50513          	addi	a0,a0,-2 # 80008118 <digits+0xd8>
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
    80001198:	f9450513          	addi	a0,a0,-108 # 80008128 <digits+0xe8>
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
    80001268:	95a080e7          	jalr	-1702(ra) # 80001bbe <proc_mapstacks>
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
    8000128a:	00008797          	auipc	a5,0x8
    8000128e:	d8a7bb23          	sd	a0,-618(a5) # 80009020 <kernel_pagetable>
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
    800012e4:	e5050513          	addi	a0,a0,-432 # 80008130 <digits+0xf0>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e5850513          	addi	a0,a0,-424 # 80008148 <digits+0x108>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e5850513          	addi	a0,a0,-424 # 80008158 <digits+0x118>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	236080e7          	jalr	566(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e6050513          	addi	a0,a0,-416 # 80008170 <digits+0x130>
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
    800013f2:	d9a50513          	addi	a0,a0,-614 # 80008188 <digits+0x148>
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
    80001534:	c7850513          	addi	a0,a0,-904 # 800081a8 <digits+0x168>
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
    80001610:	bac50513          	addi	a0,a0,-1108 # 800081b8 <digits+0x178>
    80001614:	fffff097          	auipc	ra,0xfffff
    80001618:	f2a080e7          	jalr	-214(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000161c:	00007517          	auipc	a0,0x7
    80001620:	bbc50513          	addi	a0,a0,-1092 # 800081d8 <digits+0x198>
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
    8000168a:	b7250513          	addi	a0,a0,-1166 # 800081f8 <digits+0x1b8>
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
    80001862:	715d                	addi	sp,sp,-80
    80001864:	e486                	sd	ra,72(sp)
    80001866:	e0a2                	sd	s0,64(sp)
    80001868:	fc26                	sd	s1,56(sp)
    8000186a:	f84a                	sd	s2,48(sp)
    8000186c:	f44e                	sd	s3,40(sp)
    8000186e:	f052                	sd	s4,32(sp)
    80001870:	ec56                	sd	s5,24(sp)
    80001872:	e85a                	sd	s6,16(sp)
    80001874:	e45e                	sd	s7,8(sp)
    80001876:	0880                	addi	s0,sp,80
int ret=-1;
//printf("remove cs p->index=%d\n", p->index);
//printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
int curr_inx=curr->index;
while (curr_inx != -1) {
    80001878:	5d98                	lw	a4,56(a1)
    8000187a:	57fd                	li	a5,-1
    8000187c:	06f70163          	beq	a4,a5,800018de <remove_cs+0x7c>
    80001880:	8b2a                	mv	s6,a0
    80001882:	84ae                	mv	s1,a1
    80001884:	89b2                	mv	s3,a2
    release(&pred->linked_list_lock);
    //printf("%d\n",132);
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    pred = curr;
    curr_inx =curr->next;
    if(curr_inx!=-1){
    80001886:	5a7d                	li	s4,-1
    80001888:	18800a93          	li	s5,392
      curr = &proc[curr->next];
    8000188c:	00009917          	auipc	s2,0x9
    80001890:	a1490913          	addi	s2,s2,-1516 # 8000a2a0 <proc>
    80001894:	a005                	j	800018b4 <remove_cs+0x52>
    80001896:	5cc8                	lw	a0,60(s1)
    80001898:	2501                	sext.w	a0,a0
    8000189a:	03550533          	mul	a0,a0,s5
    8000189e:	01250bb3          	add	s7,a0,s2
      acquire(&curr->linked_list_lock);
    800018a2:	04050513          	addi	a0,a0,64
    800018a6:	954a                	add	a0,a0,s2
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	33c080e7          	jalr	828(ra) # 80000be4 <acquire>
    800018b0:	8b26                	mv	s6,s1
      curr = &proc[curr->next];
    800018b2:	84de                	mv	s1,s7
  if ( p->index == curr->index) {
    800018b4:	0389a703          	lw	a4,56(s3) # 1038 <_entry-0x7fffefc8>
    800018b8:	5c9c                	lw	a5,56(s1)
    800018ba:	02f70a63          	beq	a4,a5,800018ee <remove_cs+0x8c>
    release(&pred->linked_list_lock);
    800018be:	040b0513          	addi	a0,s6,64 # 1040 <_entry-0x7fffefc0>
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	3e8080e7          	jalr	1000(ra) # 80000caa <release>
    curr_inx =curr->next;
    800018ca:	5cdc                	lw	a5,60(s1)
    800018cc:	2781                	sext.w	a5,a5
    if(curr_inx!=-1){
    800018ce:	fd4794e3          	bne	a5,s4,80001896 <remove_cs+0x34>
    }
    else{
      release(&curr->linked_list_lock);
    800018d2:	04048513          	addi	a0,s1,64
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	3d4080e7          	jalr	980(ra) # 80000caa <release>
    }
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    //printf("after lock\n");
  }
  panic("item not found");
    800018de:	00007517          	auipc	a0,0x7
    800018e2:	92a50513          	addi	a0,a0,-1750 # 80008208 <digits+0x1c8>
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	c58080e7          	jalr	-936(ra) # 8000053e <panic>
      pred->next = curr->next;
    800018ee:	5cdc                	lw	a5,60(s1)
    800018f0:	2781                	sext.w	a5,a5
    800018f2:	02fb2e23          	sw	a5,60(s6)
      ret = curr->index;
    800018f6:	0384a903          	lw	s2,56(s1)
      release(&curr->linked_list_lock);
    800018fa:	04048513          	addi	a0,s1,64
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	3ac080e7          	jalr	940(ra) # 80000caa <release>
      release(&pred->linked_list_lock);
    80001906:	040b0513          	addi	a0,s6,64
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	3a0080e7          	jalr	928(ra) # 80000caa <release>
}
    80001912:	854a                	mv	a0,s2
    80001914:	60a6                	ld	ra,72(sp)
    80001916:	6406                	ld	s0,64(sp)
    80001918:	74e2                	ld	s1,56(sp)
    8000191a:	7942                	ld	s2,48(sp)
    8000191c:	79a2                	ld	s3,40(sp)
    8000191e:	7a02                	ld	s4,32(sp)
    80001920:	6ae2                	ld	s5,24(sp)
    80001922:	6b42                	ld	s6,16(sp)
    80001924:	6ba2                	ld	s7,8(sp)
    80001926:	6161                	addi	sp,sp,80
    80001928:	8082                	ret

000000008000192a <remove_from_list>:

int remove_from_list(int p_index, int *list,struct spinlock lock_list){
    8000192a:	7139                	addi	sp,sp,-64
    8000192c:	fc06                	sd	ra,56(sp)
    8000192e:	f822                	sd	s0,48(sp)
    80001930:	f426                	sd	s1,40(sp)
    80001932:	f04a                	sd	s2,32(sp)
    80001934:	ec4e                	sd	s3,24(sp)
    80001936:	e852                	sd	s4,16(sp)
    80001938:	e456                	sd	s5,8(sp)
    8000193a:	e05a                	sd	s6,0(sp)
    8000193c:	0080                	addi	s0,sp,64
    8000193e:	84aa                	mv	s1,a0
    80001940:	89ae                	mv	s3,a1
    80001942:	8932                	mv	s2,a2
  //printf("entered remove from list\n");
  //printf("trying to remove %d\n", p_index);
  int ret=-1;
  acquire(&lock_list);
    80001944:	8532                	mv	a0,a2
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	29e080e7          	jalr	670(ra) # 80000be4 <acquire>
  if(*list==-1){
    8000194e:	0009a783          	lw	a5,0(s3)
    80001952:	577d                	li	a4,-1
    80001954:	08e78c63          	beq	a5,a4,800019ec <remove_from_list+0xc2>
    release(&lock_list);
    panic("the remove from list faild.\n");
  }
  else{
    //if(proc[*list].next==-1){ // only one is on the list
        if(p_index == *list){
    80001958:	0a978763          	beq	a5,s1,80001a06 <remove_from_list+0xdc>
          ret=p_index;
          return ret;
        }
    //}
    else{
      release(&lock_list);
    8000195c:	854a                	mv	a0,s2
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	34c080e7          	jalr	844(ra) # 80000caa <release>
      struct proc *pred;
      struct proc *curr;
      pred=&proc[*list];
    80001966:	0009a983          	lw	s3,0(s3)
    8000196a:	18800793          	li	a5,392
    8000196e:	02f987b3          	mul	a5,s3,a5
    80001972:	00009917          	auipc	s2,0x9
    80001976:	92e90913          	addi	s2,s2,-1746 # 8000a2a0 <proc>
    8000197a:	01278a33          	add	s4,a5,s2
      acquire(&pred->linked_list_lock);
    8000197e:	04078793          	addi	a5,a5,64
    80001982:	993e                	add	s2,s2,a5
    80001984:	854a                	mv	a0,s2
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	25e080e7          	jalr	606(ra) # 80000be4 <acquire>
      if(pred->next==-1)
    8000198e:	03ca2783          	lw	a5,60(s4) # fffffffffffff03c <end+0xffffffff7ffe003c>
    80001992:	2781                	sext.w	a5,a5
    80001994:	577d                	li	a4,-1
    80001996:	08e78b63          	beq	a5,a4,80001a2c <remove_from_list+0x102>
      {
        release(&pred->linked_list_lock);
        panic("the item is not in the list\n");
      }
      curr=&proc[pred->next];
    8000199a:	00009a97          	auipc	s5,0x9
    8000199e:	906a8a93          	addi	s5,s5,-1786 # 8000a2a0 <proc>
    800019a2:	18800b13          	li	s6,392
    800019a6:	036989b3          	mul	s3,s3,s6
    800019aa:	99d6                	add	s3,s3,s5
    800019ac:	03c9a903          	lw	s2,60(s3)
    800019b0:	2901                	sext.w	s2,s2
    800019b2:	03690933          	mul	s2,s2,s6
      acquire(&curr->linked_list_lock);
    800019b6:	04090513          	addi	a0,s2,64
    800019ba:	9556                	add	a0,a0,s5
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	228080e7          	jalr	552(ra) # 80000be4 <acquire>
      //printf("pred is:%d the curr is:%d\n", pred->index,curr->index);
     
      ret=remove_cs(pred, curr, &proc[p_index]);
    800019c4:	03648633          	mul	a2,s1,s6
    800019c8:	9656                	add	a2,a2,s5
    800019ca:	012a85b3          	add	a1,s5,s2
    800019ce:	8552                	mv	a0,s4
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	e92080e7          	jalr	-366(ra) # 80001862 <remove_cs>
    }
  }
  //printf("here4\n");
  //release(&lock_list);
  return ret;
}
    800019d8:	70e2                	ld	ra,56(sp)
    800019da:	7442                	ld	s0,48(sp)
    800019dc:	74a2                	ld	s1,40(sp)
    800019de:	7902                	ld	s2,32(sp)
    800019e0:	69e2                	ld	s3,24(sp)
    800019e2:	6a42                	ld	s4,16(sp)
    800019e4:	6aa2                	ld	s5,8(sp)
    800019e6:	6b02                	ld	s6,0(sp)
    800019e8:	6121                	addi	sp,sp,64
    800019ea:	8082                	ret
    release(&lock_list);
    800019ec:	854a                	mv	a0,s2
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	2bc080e7          	jalr	700(ra) # 80000caa <release>
    panic("the remove from list faild.\n");
    800019f6:	00007517          	auipc	a0,0x7
    800019fa:	82250513          	addi	a0,a0,-2014 # 80008218 <digits+0x1d8>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>
          *list = proc[p_index].next;
    80001a06:	18800793          	li	a5,392
    80001a0a:	02f48733          	mul	a4,s1,a5
    80001a0e:	00009797          	auipc	a5,0x9
    80001a12:	89278793          	addi	a5,a5,-1902 # 8000a2a0 <proc>
    80001a16:	97ba                	add	a5,a5,a4
    80001a18:	5fdc                	lw	a5,60(a5)
    80001a1a:	00f9a023          	sw	a5,0(s3)
          release(&lock_list);
    80001a1e:	854a                	mv	a0,s2
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	28a080e7          	jalr	650(ra) # 80000caa <release>
          return ret;
    80001a28:	8526                	mv	a0,s1
    80001a2a:	b77d                	j	800019d8 <remove_from_list+0xae>
        release(&pred->linked_list_lock);
    80001a2c:	854a                	mv	a0,s2
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	27c080e7          	jalr	636(ra) # 80000caa <release>
        panic("the item is not in the list\n");
    80001a36:	00007517          	auipc	a0,0x7
    80001a3a:	80250513          	addi	a0,a0,-2046 # 80008238 <digits+0x1f8>
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>

0000000080001a46 <insert_cs>:

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001a46:	7139                	addi	sp,sp,-64
    80001a48:	fc06                	sd	ra,56(sp)
    80001a4a:	f822                	sd	s0,48(sp)
    80001a4c:	f426                	sd	s1,40(sp)
    80001a4e:	f04a                	sd	s2,32(sp)
    80001a50:	ec4e                	sd	s3,24(sp)
    80001a52:	e852                	sd	s4,16(sp)
    80001a54:	e456                	sd	s5,8(sp)
    80001a56:	e05a                	sd	s6,0(sp)
    80001a58:	0080                	addi	s0,sp,64
    80001a5a:	892a                	mv	s2,a0
    80001a5c:	8aae                	mv	s5,a1
  //struct proc *curr=pred;
  //printf("insert cs");
  int curr = pred->index; 
  struct spinlock *pred_lock;
  while (curr != -1) {
    80001a5e:	5d18                	lw	a4,56(a0)
    80001a60:	57fd                	li	a5,-1
    80001a62:	04f70a63          	beq	a4,a5,80001ab6 <insert_cs+0x70>
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    if(pred->next!=-1){
    80001a66:	59fd                	li	s3,-1
    80001a68:	18800b13          	li	s6,392
      pred_lock=&pred->linked_list_lock; // caller acquired
      pred = &proc[pred->next];
    80001a6c:	00009a17          	auipc	s4,0x9
    80001a70:	834a0a13          	addi	s4,s4,-1996 # 8000a2a0 <proc>
    80001a74:	a81d                	j	80001aaa <insert_cs+0x64>
      pred_lock=&pred->linked_list_lock; // caller acquired
    80001a76:	04090513          	addi	a0,s2,64
      pred = &proc[pred->next];
    80001a7a:	03c92483          	lw	s1,60(s2)
    80001a7e:	2481                	sext.w	s1,s1
    80001a80:	036484b3          	mul	s1,s1,s6
    80001a84:	01448933          	add	s2,s1,s4
      release(pred_lock);
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	222080e7          	jalr	546(ra) # 80000caa <release>
      acquire(&pred->linked_list_lock);
    80001a90:	04048493          	addi	s1,s1,64
    80001a94:	009a0533          	add	a0,s4,s1
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	14c080e7          	jalr	332(ra) # 80000be4 <acquire>
    }
    curr = pred->next;
    80001aa0:	03c92783          	lw	a5,60(s2)
    80001aa4:	2781                	sext.w	a5,a5
  while (curr != -1) {
    80001aa6:	01378863          	beq	a5,s3,80001ab6 <insert_cs+0x70>
    if(pred->next!=-1){
    80001aaa:	03c92783          	lw	a5,60(s2)
    80001aae:	2781                	sext.w	a5,a5
    80001ab0:	ff3788e3          	beq	a5,s3,80001aa0 <insert_cs+0x5a>
    80001ab4:	b7c9                	j	80001a76 <insert_cs+0x30>
    }
    //printf("exitloop\n");
    pred->next = p->index;
    80001ab6:	038aa783          	lw	a5,56(s5)
    80001aba:	02f92e23          	sw	a5,60(s2)
    release(&pred->linked_list_lock);
    80001abe:	04090513          	addi	a0,s2,64
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	1e8080e7          	jalr	488(ra) # 80000caa <release>
    //printf("the pred is:%d pred->next:%d p->index=%d\n",pred->index,pred->next,p->index);
    //printf("the p->index is:%d\n",p->index);
    p->next=-1;
    80001aca:	57fd                	li	a5,-1
    80001acc:	02faae23          	sw	a5,60(s5)
    return p->index;
}
    80001ad0:	038aa503          	lw	a0,56(s5)
    80001ad4:	70e2                	ld	ra,56(sp)
    80001ad6:	7442                	ld	s0,48(sp)
    80001ad8:	74a2                	ld	s1,40(sp)
    80001ada:	7902                	ld	s2,32(sp)
    80001adc:	69e2                	ld	s3,24(sp)
    80001ade:	6a42                	ld	s4,16(sp)
    80001ae0:	6aa2                	ld	s5,8(sp)
    80001ae2:	6b02                	ld	s6,0(sp)
    80001ae4:	6121                	addi	sp,sp,64
    80001ae6:	8082                	ret

0000000080001ae8 <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock lock_list){
    80001ae8:	7139                	addi	sp,sp,-64
    80001aea:	fc06                	sd	ra,56(sp)
    80001aec:	f822                	sd	s0,48(sp)
    80001aee:	f426                	sd	s1,40(sp)
    80001af0:	f04a                	sd	s2,32(sp)
    80001af2:	ec4e                	sd	s3,24(sp)
    80001af4:	e852                	sd	s4,16(sp)
    80001af6:	e456                	sd	s5,8(sp)
    80001af8:	0080                	addi	s0,sp,64
    80001afa:	84aa                	mv	s1,a0
    80001afc:	892e                	mv	s2,a1
    80001afe:	89b2                	mv	s3,a2
  //printf("entered insert_to_list.\n");
  int ret=-1;
  acquire(&lock_list);
    80001b00:	8532                	mv	a0,a2
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	0e2080e7          	jalr	226(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001b0a:	00092703          	lw	a4,0(s2)
    80001b0e:	57fd                	li	a5,-1
    80001b10:	04f70d63          	beq	a4,a5,80001b6a <insert_to_list+0x82>
    ret=p_index;
    //printf("here\nlist pointer: %d, list next %d\n",*list, proc[*list].next);
    release(&lock_list);
  }
  else{
    release(&lock_list);
    80001b14:	854e                	mv	a0,s3
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	194080e7          	jalr	404(ra) # 80000caa <release>
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    80001b1e:	00092903          	lw	s2,0(s2)
    80001b22:	18800a13          	li	s4,392
    80001b26:	03490933          	mul	s2,s2,s4
    //printf("the index of the first prosses in the list is:%d %d\n",*list,pred->next);
    acquire(&pred->linked_list_lock);
    80001b2a:	04090513          	addi	a0,s2,64
    80001b2e:	00008997          	auipc	s3,0x8
    80001b32:	77298993          	addi	s3,s3,1906 # 8000a2a0 <proc>
    80001b36:	954e                	add	a0,a0,s3
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	0ac080e7          	jalr	172(ra) # 80000be4 <acquire>
    //curr=&proc[pred->next];
    //acquire(&curr->lock);
    ret=insert_cs(pred, &proc[p_index]);
    80001b40:	034485b3          	mul	a1,s1,s4
    80001b44:	95ce                	add	a1,a1,s3
    80001b46:	01298533          	add	a0,s3,s2
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	efc080e7          	jalr	-260(ra) # 80001a46 <insert_cs>
    //release(&curr->lock);
    // release(&pred->linked_list_lock);
    //printf("ret is:%d \n",ret);  
  }
if(ret==-1){
    80001b52:	57fd                	li	a5,-1
    80001b54:	04f50d63          	beq	a0,a5,80001bae <insert_to_list+0xc6>
  panic("insert is failed");
}
return ret;
}
    80001b58:	70e2                	ld	ra,56(sp)
    80001b5a:	7442                	ld	s0,48(sp)
    80001b5c:	74a2                	ld	s1,40(sp)
    80001b5e:	7902                	ld	s2,32(sp)
    80001b60:	69e2                	ld	s3,24(sp)
    80001b62:	6a42                	ld	s4,16(sp)
    80001b64:	6aa2                	ld	s5,8(sp)
    80001b66:	6121                	addi	sp,sp,64
    80001b68:	8082                	ret
    *list=p_index;
    80001b6a:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001b6e:	18800a13          	li	s4,392
    80001b72:	03448ab3          	mul	s5,s1,s4
    80001b76:	040a8913          	addi	s2,s5,64
    80001b7a:	00008a17          	auipc	s4,0x8
    80001b7e:	726a0a13          	addi	s4,s4,1830 # 8000a2a0 <proc>
    80001b82:	9952                	add	s2,s2,s4
    80001b84:	854a                	mv	a0,s2
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	05e080e7          	jalr	94(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001b8e:	9a56                	add	s4,s4,s5
    80001b90:	57fd                	li	a5,-1
    80001b92:	02fa2e23          	sw	a5,60(s4)
    release(&proc[p_index].linked_list_lock);
    80001b96:	854a                	mv	a0,s2
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	112080e7          	jalr	274(ra) # 80000caa <release>
    release(&lock_list);
    80001ba0:	854e                	mv	a0,s3
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	108080e7          	jalr	264(ra) # 80000caa <release>
    ret=p_index;
    80001baa:	8526                	mv	a0,s1
    80001bac:	b75d                	j	80001b52 <insert_to_list+0x6a>
  panic("insert is failed");
    80001bae:	00006517          	auipc	a0,0x6
    80001bb2:	6aa50513          	addi	a0,a0,1706 # 80008258 <digits+0x218>
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	988080e7          	jalr	-1656(ra) # 8000053e <panic>

0000000080001bbe <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001bbe:	7139                	addi	sp,sp,-64
    80001bc0:	fc06                	sd	ra,56(sp)
    80001bc2:	f822                	sd	s0,48(sp)
    80001bc4:	f426                	sd	s1,40(sp)
    80001bc6:	f04a                	sd	s2,32(sp)
    80001bc8:	ec4e                	sd	s3,24(sp)
    80001bca:	e852                	sd	s4,16(sp)
    80001bcc:	e456                	sd	s5,8(sp)
    80001bce:	e05a                	sd	s6,0(sp)
    80001bd0:	0080                	addi	s0,sp,64
    80001bd2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	00008497          	auipc	s1,0x8
    80001bd8:	6cc48493          	addi	s1,s1,1740 # 8000a2a0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001bdc:	8b26                	mv	s6,s1
    80001bde:	00006a97          	auipc	s5,0x6
    80001be2:	422a8a93          	addi	s5,s5,1058 # 80008000 <etext>
    80001be6:	04000937          	lui	s2,0x4000
    80001bea:	197d                	addi	s2,s2,-1
    80001bec:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	0000fa17          	auipc	s4,0xf
    80001bf2:	8b2a0a13          	addi	s4,s4,-1870 # 800104a0 <tickslock>
    char *pa = kalloc();
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	efe080e7          	jalr	-258(ra) # 80000af4 <kalloc>
    80001bfe:	862a                	mv	a2,a0
    if(pa == 0)
    80001c00:	c131                	beqz	a0,80001c44 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c02:	416485b3          	sub	a1,s1,s6
    80001c06:	858d                	srai	a1,a1,0x3
    80001c08:	000ab783          	ld	a5,0(s5)
    80001c0c:	02f585b3          	mul	a1,a1,a5
    80001c10:	2585                	addiw	a1,a1,1
    80001c12:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c16:	4719                	li	a4,6
    80001c18:	6685                	lui	a3,0x1
    80001c1a:	40b905b3          	sub	a1,s2,a1
    80001c1e:	854e                	mv	a0,s3
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	554080e7          	jalr	1364(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c28:	18848493          	addi	s1,s1,392
    80001c2c:	fd4495e3          	bne	s1,s4,80001bf6 <proc_mapstacks+0x38>
  }
}
    80001c30:	70e2                	ld	ra,56(sp)
    80001c32:	7442                	ld	s0,48(sp)
    80001c34:	74a2                	ld	s1,40(sp)
    80001c36:	7902                	ld	s2,32(sp)
    80001c38:	69e2                	ld	s3,24(sp)
    80001c3a:	6a42                	ld	s4,16(sp)
    80001c3c:	6aa2                	ld	s5,8(sp)
    80001c3e:	6b02                	ld	s6,0(sp)
    80001c40:	6121                	addi	sp,sp,64
    80001c42:	8082                	ret
      panic("kalloc");
    80001c44:	00006517          	auipc	a0,0x6
    80001c48:	62c50513          	addi	a0,a0,1580 # 80008270 <digits+0x230>
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	8f2080e7          	jalr	-1806(ra) # 8000053e <panic>

0000000080001c54 <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80001c54:	7119                	addi	sp,sp,-128
    80001c56:	fc86                	sd	ra,120(sp)
    80001c58:	f8a2                	sd	s0,112(sp)
    80001c5a:	f4a6                	sd	s1,104(sp)
    80001c5c:	f0ca                	sd	s2,96(sp)
    80001c5e:	ecce                	sd	s3,88(sp)
    80001c60:	e8d2                	sd	s4,80(sp)
    80001c62:	e4d6                	sd	s5,72(sp)
    80001c64:	e0da                	sd	s6,64(sp)
    80001c66:	fc5e                	sd	s7,56(sp)
    80001c68:	f862                	sd	s8,48(sp)
    80001c6a:	f466                	sd	s9,40(sp)
    80001c6c:	0100                	addi	s0,sp,128
  //printf("entered procinit\n");
  struct proc *p;

  for (int i = 0; i<NCPU; i++){
    cas(&cpus_ll[i],0,-1); 
    80001c6e:	567d                	li	a2,-1
    80001c70:	4581                	li	a1,0
    80001c72:	00007517          	auipc	a0,0x7
    80001c76:	3b650513          	addi	a0,a0,950 # 80009028 <cpus_ll>
    80001c7a:	00005097          	auipc	ra,0x5
    80001c7e:	cfc080e7          	jalr	-772(ra) # 80006976 <cas>
    //printf("done cpus_ll[%d]=%d\n",i ,cpus_ll[i]);
}
  
  initlock(&pid_lock, "nextpid");
    80001c82:	00006597          	auipc	a1,0x6
    80001c86:	5f658593          	addi	a1,a1,1526 # 80008278 <digits+0x238>
    80001c8a:	00008517          	auipc	a0,0x8
    80001c8e:	50650513          	addi	a0,a0,1286 # 8000a190 <pid_lock>
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	ec2080e7          	jalr	-318(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c9a:	00006597          	auipc	a1,0x6
    80001c9e:	5e658593          	addi	a1,a1,1510 # 80008280 <digits+0x240>
    80001ca2:	00008517          	auipc	a0,0x8
    80001ca6:	50650513          	addi	a0,a0,1286 # 8000a1a8 <wait_lock>
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	eaa080e7          	jalr	-342(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001cb2:	00006597          	auipc	a1,0x6
    80001cb6:	5de58593          	addi	a1,a1,1502 # 80008290 <digits+0x250>
    80001cba:	00008517          	auipc	a0,0x8
    80001cbe:	50650513          	addi	a0,a0,1286 # 8000a1c0 <sleeping_head>
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	e92080e7          	jalr	-366(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	5d658593          	addi	a1,a1,1494 # 800082a0 <digits+0x260>
    80001cd2:	00008517          	auipc	a0,0x8
    80001cd6:	50650513          	addi	a0,a0,1286 # 8000a1d8 <zombie_head>
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	e7a080e7          	jalr	-390(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001ce2:	00006597          	auipc	a1,0x6
    80001ce6:	5ce58593          	addi	a1,a1,1486 # 800082b0 <digits+0x270>
    80001cea:	00008517          	auipc	a0,0x8
    80001cee:	50650513          	addi	a0,a0,1286 # 8000a1f0 <unused_head>
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	e62080e7          	jalr	-414(ra) # 80000b54 <initlock>
  
  int i=0; //added
    80001cfa:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cfc:	00008497          	auipc	s1,0x8
    80001d00:	5a448493          	addi	s1,s1,1444 # 8000a2a0 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001d04:	8ca6                	mv	s9,s1
    80001d06:	00006c17          	auipc	s8,0x6
    80001d0a:	2fac3c03          	ld	s8,762(s8) # 80008000 <etext>
    80001d0e:	04000a37          	lui	s4,0x4000
    80001d12:	1a7d                	addi	s4,s4,-1
    80001d14:	0a32                	slli	s4,s4,0xc
      //added:
      p->state= UNUSED; 
      p->index=i; 
      initlock(&p->lock, "proc");
    80001d16:	00006b97          	auipc	s7,0x6
    80001d1a:	5aab8b93          	addi	s7,s7,1450 # 800082c0 <digits+0x280>
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
    80001d1e:	00006b17          	auipc	s6,0x6
    80001d22:	5aab0b13          	addi	s6,s6,1450 # 800082c8 <digits+0x288>
      i++;
      insert_to_list(p->index, &unused,unused_head);
    80001d26:	00008997          	auipc	s3,0x8
    80001d2a:	46a98993          	addi	s3,s3,1130 # 8000a190 <pid_lock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d2e:	0000ea97          	auipc	s5,0xe
    80001d32:	772a8a93          	addi	s5,s5,1906 # 800104a0 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001d36:	419487b3          	sub	a5,s1,s9
    80001d3a:	878d                	srai	a5,a5,0x3
    80001d3c:	038787b3          	mul	a5,a5,s8
    80001d40:	2785                	addiw	a5,a5,1
    80001d42:	00d7979b          	slliw	a5,a5,0xd
    80001d46:	40fa07b3          	sub	a5,s4,a5
    80001d4a:	f0bc                	sd	a5,96(s1)
      p->state= UNUSED; 
    80001d4c:	0004ac23          	sw	zero,24(s1)
      p->index=i; 
    80001d50:	0324ac23          	sw	s2,56(s1)
      initlock(&p->lock, "proc");
    80001d54:	85de                	mv	a1,s7
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	dfc080e7          	jalr	-516(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, name);
    80001d60:	85da                	mv	a1,s6
    80001d62:	04048513          	addi	a0,s1,64
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	dee080e7          	jalr	-530(ra) # 80000b54 <initlock>
      i++;
    80001d6e:	2905                	addiw	s2,s2,1
      insert_to_list(p->index, &unused,unused_head);
    80001d70:	0609b783          	ld	a5,96(s3)
    80001d74:	f8f43023          	sd	a5,-128(s0)
    80001d78:	0689b783          	ld	a5,104(s3)
    80001d7c:	f8f43423          	sd	a5,-120(s0)
    80001d80:	0709b783          	ld	a5,112(s3)
    80001d84:	f8f43823          	sd	a5,-112(s0)
    80001d88:	f8040613          	addi	a2,s0,-128
    80001d8c:	00007597          	auipc	a1,0x7
    80001d90:	b9858593          	addi	a1,a1,-1128 # 80008924 <unused>
    80001d94:	5c88                	lw	a0,56(s1)
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	d52080e7          	jalr	-686(ra) # 80001ae8 <insert_to_list>
      printf("the value of the index is:%d\n",i);
    80001d9e:	85ca                	mv	a1,s2
    80001da0:	00006517          	auipc	a0,0x6
    80001da4:	53050513          	addi	a0,a0,1328 # 800082d0 <digits+0x290>
    80001da8:	ffffe097          	auipc	ra,0xffffe
    80001dac:	7e0080e7          	jalr	2016(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db0:	18848493          	addi	s1,s1,392
    80001db4:	f95491e3          	bne	s1,s5,80001d36 <procinit+0xe2>

  
  
  //printf("the head of the unused list is %d, and the value of next is:%d\n ",unused,proc[unused].next);
      
  printf("finished procinit\n");
    80001db8:	00006517          	auipc	a0,0x6
    80001dbc:	53850513          	addi	a0,a0,1336 # 800082f0 <digits+0x2b0>
    80001dc0:	ffffe097          	auipc	ra,0xffffe
    80001dc4:	7c8080e7          	jalr	1992(ra) # 80000588 <printf>
}
    80001dc8:	70e6                	ld	ra,120(sp)
    80001dca:	7446                	ld	s0,112(sp)
    80001dcc:	74a6                	ld	s1,104(sp)
    80001dce:	7906                	ld	s2,96(sp)
    80001dd0:	69e6                	ld	s3,88(sp)
    80001dd2:	6a46                	ld	s4,80(sp)
    80001dd4:	6aa6                	ld	s5,72(sp)
    80001dd6:	6b06                	ld	s6,64(sp)
    80001dd8:	7be2                	ld	s7,56(sp)
    80001dda:	7c42                	ld	s8,48(sp)
    80001ddc:	7ca2                	ld	s9,40(sp)
    80001dde:	6109                	addi	sp,sp,128
    80001de0:	8082                	ret

0000000080001de2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001de2:	1141                	addi	sp,sp,-16
    80001de4:	e422                	sd	s0,8(sp)
    80001de6:	0800                	addi	s0,sp,16
// this core's hartid (core number), the index into cpus[].
static inline uint64
r_tp()
{
  uint64 x;
  asm volatile("mv %0, tp" : "=r" (x) );
    80001de8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001dea:	2501                	sext.w	a0,a0
    80001dec:	6422                	ld	s0,8(sp)
    80001dee:	0141                	addi	sp,sp,16
    80001df0:	8082                	ret

0000000080001df2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001df2:	1141                	addi	sp,sp,-16
    80001df4:	e422                	sd	s0,8(sp)
    80001df6:	0800                	addi	s0,sp,16
    80001df8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001dfa:	2781                	sext.w	a5,a5
    80001dfc:	079e                	slli	a5,a5,0x7
  return c;
}
    80001dfe:	00008517          	auipc	a0,0x8
    80001e02:	40a50513          	addi	a0,a0,1034 # 8000a208 <cpus>
    80001e06:	953e                	add	a0,a0,a5
    80001e08:	6422                	ld	s0,8(sp)
    80001e0a:	0141                	addi	sp,sp,16
    80001e0c:	8082                	ret

0000000080001e0e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e0e:	1101                	addi	sp,sp,-32
    80001e10:	ec06                	sd	ra,24(sp)
    80001e12:	e822                	sd	s0,16(sp)
    80001e14:	e426                	sd	s1,8(sp)
    80001e16:	1000                	addi	s0,sp,32
  push_off();
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	d80080e7          	jalr	-640(ra) # 80000b98 <push_off>
    80001e20:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e22:	2781                	sext.w	a5,a5
    80001e24:	079e                	slli	a5,a5,0x7
    80001e26:	00008717          	auipc	a4,0x8
    80001e2a:	36a70713          	addi	a4,a4,874 # 8000a190 <pid_lock>
    80001e2e:	97ba                	add	a5,a5,a4
    80001e30:	7fa4                	ld	s1,120(a5)
  pop_off();
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e18080e7          	jalr	-488(ra) # 80000c4a <pop_off>
  return p;
}
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	60e2                	ld	ra,24(sp)
    80001e3e:	6442                	ld	s0,16(sp)
    80001e40:	64a2                	ld	s1,8(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret

0000000080001e46 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e46:	1141                	addi	sp,sp,-16
    80001e48:	e406                	sd	ra,8(sp)
    80001e4a:	e022                	sd	s0,0(sp)
    80001e4c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	fc0080e7          	jalr	-64(ra) # 80001e0e <myproc>
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e54080e7          	jalr	-428(ra) # 80000caa <release>

  if (first) {
    80001e5e:	00007797          	auipc	a5,0x7
    80001e62:	ac27a783          	lw	a5,-1342(a5) # 80008920 <first.1724>
    80001e66:	eb89                	bnez	a5,80001e78 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e68:	00001097          	auipc	ra,0x1
    80001e6c:	fc4080e7          	jalr	-60(ra) # 80002e2c <usertrapret>
}
    80001e70:	60a2                	ld	ra,8(sp)
    80001e72:	6402                	ld	s0,0(sp)
    80001e74:	0141                	addi	sp,sp,16
    80001e76:	8082                	ret
    first = 0;
    80001e78:	00007797          	auipc	a5,0x7
    80001e7c:	aa07a423          	sw	zero,-1368(a5) # 80008920 <first.1724>
    fsinit(ROOTDEV);
    80001e80:	4505                	li	a0,1
    80001e82:	00002097          	auipc	ra,0x2
    80001e86:	cec080e7          	jalr	-788(ra) # 80003b6e <fsinit>
    80001e8a:	bff9                	j	80001e68 <forkret+0x22>

0000000080001e8c <allocpid>:
allocpid() { //changed as ordered in task 2
    80001e8c:	1101                	addi	sp,sp,-32
    80001e8e:	ec06                	sd	ra,24(sp)
    80001e90:	e822                	sd	s0,16(sp)
    80001e92:	e426                	sd	s1,8(sp)
    80001e94:	e04a                	sd	s2,0(sp)
    80001e96:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001e98:	00007917          	auipc	s2,0x7
    80001e9c:	a9890913          	addi	s2,s2,-1384 # 80008930 <nextpid>
    80001ea0:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001ea4:	0014861b          	addiw	a2,s1,1
    80001ea8:	85a6                	mv	a1,s1
    80001eaa:	854a                	mv	a0,s2
    80001eac:	00005097          	auipc	ra,0x5
    80001eb0:	aca080e7          	jalr	-1334(ra) # 80006976 <cas>
    80001eb4:	f575                	bnez	a0,80001ea0 <allocpid+0x14>
}
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	60e2                	ld	ra,24(sp)
    80001eba:	6442                	ld	s0,16(sp)
    80001ebc:	64a2                	ld	s1,8(sp)
    80001ebe:	6902                	ld	s2,0(sp)
    80001ec0:	6105                	addi	sp,sp,32
    80001ec2:	8082                	ret

0000000080001ec4 <proc_pagetable>:
{
    80001ec4:	1101                	addi	sp,sp,-32
    80001ec6:	ec06                	sd	ra,24(sp)
    80001ec8:	e822                	sd	s0,16(sp)
    80001eca:	e426                	sd	s1,8(sp)
    80001ecc:	e04a                	sd	s2,0(sp)
    80001ece:	1000                	addi	s0,sp,32
    80001ed0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	48c080e7          	jalr	1164(ra) # 8000135e <uvmcreate>
    80001eda:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001edc:	c121                	beqz	a0,80001f1c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ede:	4729                	li	a4,10
    80001ee0:	00005697          	auipc	a3,0x5
    80001ee4:	12068693          	addi	a3,a3,288 # 80007000 <_trampoline>
    80001ee8:	6605                	lui	a2,0x1
    80001eea:	040005b7          	lui	a1,0x4000
    80001eee:	15fd                	addi	a1,a1,-1
    80001ef0:	05b2                	slli	a1,a1,0xc
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	1e2080e7          	jalr	482(ra) # 800010d4 <mappages>
    80001efa:	02054863          	bltz	a0,80001f2a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001efe:	4719                	li	a4,6
    80001f00:	07893683          	ld	a3,120(s2)
    80001f04:	6605                	lui	a2,0x1
    80001f06:	020005b7          	lui	a1,0x2000
    80001f0a:	15fd                	addi	a1,a1,-1
    80001f0c:	05b6                	slli	a1,a1,0xd
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	1c4080e7          	jalr	452(ra) # 800010d4 <mappages>
    80001f18:	02054163          	bltz	a0,80001f3a <proc_pagetable+0x76>
}
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	60e2                	ld	ra,24(sp)
    80001f20:	6442                	ld	s0,16(sp)
    80001f22:	64a2                	ld	s1,8(sp)
    80001f24:	6902                	ld	s2,0(sp)
    80001f26:	6105                	addi	sp,sp,32
    80001f28:	8082                	ret
    uvmfree(pagetable, 0);
    80001f2a:	4581                	li	a1,0
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	62c080e7          	jalr	1580(ra) # 8000155a <uvmfree>
    return 0;
    80001f36:	4481                	li	s1,0
    80001f38:	b7d5                	j	80001f1c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f3a:	4681                	li	a3,0
    80001f3c:	4605                	li	a2,1
    80001f3e:	040005b7          	lui	a1,0x4000
    80001f42:	15fd                	addi	a1,a1,-1
    80001f44:	05b2                	slli	a1,a1,0xc
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	352080e7          	jalr	850(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001f50:	4581                	li	a1,0
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	606080e7          	jalr	1542(ra) # 8000155a <uvmfree>
    return 0;
    80001f5c:	4481                	li	s1,0
    80001f5e:	bf7d                	j	80001f1c <proc_pagetable+0x58>

0000000080001f60 <proc_freepagetable>:
{
    80001f60:	1101                	addi	sp,sp,-32
    80001f62:	ec06                	sd	ra,24(sp)
    80001f64:	e822                	sd	s0,16(sp)
    80001f66:	e426                	sd	s1,8(sp)
    80001f68:	e04a                	sd	s2,0(sp)
    80001f6a:	1000                	addi	s0,sp,32
    80001f6c:	84aa                	mv	s1,a0
    80001f6e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f70:	4681                	li	a3,0
    80001f72:	4605                	li	a2,1
    80001f74:	040005b7          	lui	a1,0x4000
    80001f78:	15fd                	addi	a1,a1,-1
    80001f7a:	05b2                	slli	a1,a1,0xc
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	31e080e7          	jalr	798(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f84:	4681                	li	a3,0
    80001f86:	4605                	li	a2,1
    80001f88:	020005b7          	lui	a1,0x2000
    80001f8c:	15fd                	addi	a1,a1,-1
    80001f8e:	05b6                	slli	a1,a1,0xd
    80001f90:	8526                	mv	a0,s1
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	308080e7          	jalr	776(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001f9a:	85ca                	mv	a1,s2
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	5bc080e7          	jalr	1468(ra) # 8000155a <uvmfree>
}
    80001fa6:	60e2                	ld	ra,24(sp)
    80001fa8:	6442                	ld	s0,16(sp)
    80001faa:	64a2                	ld	s1,8(sp)
    80001fac:	6902                	ld	s2,0(sp)
    80001fae:	6105                	addi	sp,sp,32
    80001fb0:	8082                	ret

0000000080001fb2 <freeproc>:
{
    80001fb2:	7139                	addi	sp,sp,-64
    80001fb4:	fc06                	sd	ra,56(sp)
    80001fb6:	f822                	sd	s0,48(sp)
    80001fb8:	f426                	sd	s1,40(sp)
    80001fba:	f04a                	sd	s2,32(sp)
    80001fbc:	0080                	addi	s0,sp,64
    80001fbe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fc0:	7d28                	ld	a0,120(a0)
    80001fc2:	c509                	beqz	a0,80001fcc <freeproc+0x1a>
    kfree((void*)p->trapframe);
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	a34080e7          	jalr	-1484(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001fcc:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001fd0:	78a8                	ld	a0,112(s1)
    80001fd2:	c511                	beqz	a0,80001fde <freeproc+0x2c>
    proc_freepagetable(p->pagetable, p->sz);
    80001fd4:	74ac                	ld	a1,104(s1)
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	f8a080e7          	jalr	-118(ra) # 80001f60 <proc_freepagetable>
  p->pagetable = 0;
    80001fde:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001fe2:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001fe6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001fea:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001fee:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001ff2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ff6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ffa:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index,&zombie,zombie_head);
    80001ffe:	00008917          	auipc	s2,0x8
    80002002:	19290913          	addi	s2,s2,402 # 8000a190 <pid_lock>
    80002006:	04893783          	ld	a5,72(s2)
    8000200a:	fcf43023          	sd	a5,-64(s0)
    8000200e:	05093783          	ld	a5,80(s2)
    80002012:	fcf43423          	sd	a5,-56(s0)
    80002016:	05893783          	ld	a5,88(s2)
    8000201a:	fcf43823          	sd	a5,-48(s0)
    8000201e:	fc040613          	addi	a2,s0,-64
    80002022:	00007597          	auipc	a1,0x7
    80002026:	90658593          	addi	a1,a1,-1786 # 80008928 <zombie>
    8000202a:	5c88                	lw	a0,56(s1)
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	8fe080e7          	jalr	-1794(ra) # 8000192a <remove_from_list>
  p->state = UNUSED;
    80002034:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index,&unused,unused_head);
    80002038:	06093783          	ld	a5,96(s2)
    8000203c:	fcf43023          	sd	a5,-64(s0)
    80002040:	06893783          	ld	a5,104(s2)
    80002044:	fcf43423          	sd	a5,-56(s0)
    80002048:	07093783          	ld	a5,112(s2)
    8000204c:	fcf43823          	sd	a5,-48(s0)
    80002050:	fc040613          	addi	a2,s0,-64
    80002054:	00007597          	auipc	a1,0x7
    80002058:	8d058593          	addi	a1,a1,-1840 # 80008924 <unused>
    8000205c:	5c88                	lw	a0,56(s1)
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	a8a080e7          	jalr	-1398(ra) # 80001ae8 <insert_to_list>
}
    80002066:	70e2                	ld	ra,56(sp)
    80002068:	7442                	ld	s0,48(sp)
    8000206a:	74a2                	ld	s1,40(sp)
    8000206c:	7902                	ld	s2,32(sp)
    8000206e:	6121                	addi	sp,sp,64
    80002070:	8082                	ret

0000000080002072 <allocproc>:
{
    80002072:	715d                	addi	sp,sp,-80
    80002074:	e486                	sd	ra,72(sp)
    80002076:	e0a2                	sd	s0,64(sp)
    80002078:	fc26                	sd	s1,56(sp)
    8000207a:	f84a                	sd	s2,48(sp)
    8000207c:	f44e                	sd	s3,40(sp)
    8000207e:	f052                	sd	s4,32(sp)
    80002080:	0880                	addi	s0,sp,80
  if(unused != -1){
    80002082:	00007917          	auipc	s2,0x7
    80002086:	8a292903          	lw	s2,-1886(s2) # 80008924 <unused>
    8000208a:	57fd                	li	a5,-1
  return 0;
    8000208c:	4481                	li	s1,0
  if(unused != -1){
    8000208e:	0cf90663          	beq	s2,a5,8000215a <allocproc+0xe8>
    p = &proc[unused];
    80002092:	18800993          	li	s3,392
    80002096:	033909b3          	mul	s3,s2,s3
    8000209a:	00008497          	auipc	s1,0x8
    8000209e:	20648493          	addi	s1,s1,518 # 8000a2a0 <proc>
    800020a2:	94ce                	add	s1,s1,s3
    remove_from_list(p->index,&unused,unused_head);
    800020a4:	00008797          	auipc	a5,0x8
    800020a8:	0ec78793          	addi	a5,a5,236 # 8000a190 <pid_lock>
    800020ac:	73b8                	ld	a4,96(a5)
    800020ae:	fae43823          	sd	a4,-80(s0)
    800020b2:	77b8                	ld	a4,104(a5)
    800020b4:	fae43c23          	sd	a4,-72(s0)
    800020b8:	7bbc                	ld	a5,112(a5)
    800020ba:	fcf43023          	sd	a5,-64(s0)
    800020be:	fb040613          	addi	a2,s0,-80
    800020c2:	00007597          	auipc	a1,0x7
    800020c6:	86258593          	addi	a1,a1,-1950 # 80008924 <unused>
    800020ca:	5c88                	lw	a0,56(s1)
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	85e080e7          	jalr	-1954(ra) # 8000192a <remove_from_list>
    acquire(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	b0e080e7          	jalr	-1266(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	dae080e7          	jalr	-594(ra) # 80001e8c <allocpid>
    800020e6:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020e8:	4785                	li	a5,1
    800020ea:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	a08080e7          	jalr	-1528(ra) # 80000af4 <kalloc>
    800020f4:	8a2a                	mv	s4,a0
    800020f6:	fca8                	sd	a0,120(s1)
    800020f8:	c935                	beqz	a0,8000216c <allocproc+0xfa>
  p->pagetable = proc_pagetable(p);
    800020fa:	8526                	mv	a0,s1
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	dc8080e7          	jalr	-568(ra) # 80001ec4 <proc_pagetable>
    80002104:	8a2a                	mv	s4,a0
    80002106:	18800793          	li	a5,392
    8000210a:	02f90733          	mul	a4,s2,a5
    8000210e:	00008797          	auipc	a5,0x8
    80002112:	19278793          	addi	a5,a5,402 # 8000a2a0 <proc>
    80002116:	97ba                	add	a5,a5,a4
    80002118:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    8000211a:	c52d                	beqz	a0,80002184 <allocproc+0x112>
  memset(&p->context, 0, sizeof(p->context));
    8000211c:	08098513          	addi	a0,s3,128
    80002120:	00008a17          	auipc	s4,0x8
    80002124:	180a0a13          	addi	s4,s4,384 # 8000a2a0 <proc>
    80002128:	07000613          	li	a2,112
    8000212c:	4581                	li	a1,0
    8000212e:	9552                	add	a0,a0,s4
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	bd4080e7          	jalr	-1068(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    80002138:	18800793          	li	a5,392
    8000213c:	02f90933          	mul	s2,s2,a5
    80002140:	9952                	add	s2,s2,s4
    80002142:	00000797          	auipc	a5,0x0
    80002146:	d0478793          	addi	a5,a5,-764 # 80001e46 <forkret>
    8000214a:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000214e:	06093783          	ld	a5,96(s2)
    80002152:	6705                	lui	a4,0x1
    80002154:	97ba                	add	a5,a5,a4
    80002156:	08f93423          	sd	a5,136(s2)
}
    8000215a:	8526                	mv	a0,s1
    8000215c:	60a6                	ld	ra,72(sp)
    8000215e:	6406                	ld	s0,64(sp)
    80002160:	74e2                	ld	s1,56(sp)
    80002162:	7942                	ld	s2,48(sp)
    80002164:	79a2                	ld	s3,40(sp)
    80002166:	7a02                	ld	s4,32(sp)
    80002168:	6161                	addi	sp,sp,80
    8000216a:	8082                	ret
    freeproc(p);
    8000216c:	8526                	mv	a0,s1
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	e44080e7          	jalr	-444(ra) # 80001fb2 <freeproc>
    release(&p->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b32080e7          	jalr	-1230(ra) # 80000caa <release>
    return 0;
    80002180:	84d2                	mv	s1,s4
    80002182:	bfe1                	j	8000215a <allocproc+0xe8>
    freeproc(p);
    80002184:	8526                	mv	a0,s1
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	e2c080e7          	jalr	-468(ra) # 80001fb2 <freeproc>
    release(&p->lock);
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b1a080e7          	jalr	-1254(ra) # 80000caa <release>
    return 0;
    80002198:	84d2                	mv	s1,s4
    8000219a:	b7c1                	j	8000215a <allocproc+0xe8>

000000008000219c <userinit>:
{
    8000219c:	7139                	addi	sp,sp,-64
    8000219e:	fc06                	sd	ra,56(sp)
    800021a0:	f822                	sd	s0,48(sp)
    800021a2:	f426                	sd	s1,40(sp)
    800021a4:	0080                	addi	s0,sp,64
  p = allocproc();
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	ecc080e7          	jalr	-308(ra) # 80002072 <allocproc>
    800021ae:	84aa                	mv	s1,a0
  initproc = p;
    800021b0:	00007797          	auipc	a5,0x7
    800021b4:	e8a7b023          	sd	a0,-384(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021b8:	03400613          	li	a2,52
    800021bc:	00006597          	auipc	a1,0x6
    800021c0:	78458593          	addi	a1,a1,1924 # 80008940 <initcode>
    800021c4:	7928                	ld	a0,112(a0)
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	1c6080e7          	jalr	454(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    800021ce:	6785                	lui	a5,0x1
    800021d0:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800021d2:	7cb8                	ld	a4,120(s1)
    800021d4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021d8:	7cb8                	ld	a4,120(s1)
    800021da:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021dc:	4641                	li	a2,16
    800021de:	00006597          	auipc	a1,0x6
    800021e2:	12a58593          	addi	a1,a1,298 # 80008308 <digits+0x2c8>
    800021e6:	17848513          	addi	a0,s1,376
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	c6c080e7          	jalr	-916(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800021f2:	00006517          	auipc	a0,0x6
    800021f6:	12650513          	addi	a0,a0,294 # 80008318 <digits+0x2d8>
    800021fa:	00002097          	auipc	ra,0x2
    800021fe:	3a2080e7          	jalr	930(ra) # 8000459c <namei>
    80002202:	16a4b823          	sd	a0,368(s1)
  insert_to_list(p->index,&cpus_ll[0],cpus_head[0]);
    80002206:	00008797          	auipc	a5,0x8
    8000220a:	f8a78793          	addi	a5,a5,-118 # 8000a190 <pid_lock>
    8000220e:	7ff8                	ld	a4,248(a5)
    80002210:	fce43023          	sd	a4,-64(s0)
    80002214:	1007b703          	ld	a4,256(a5)
    80002218:	fce43423          	sd	a4,-56(s0)
    8000221c:	1087b783          	ld	a5,264(a5)
    80002220:	fcf43823          	sd	a5,-48(s0)
    80002224:	fc040613          	addi	a2,s0,-64
    80002228:	00007597          	auipc	a1,0x7
    8000222c:	e0058593          	addi	a1,a1,-512 # 80009028 <cpus_ll>
    80002230:	5c88                	lw	a0,56(s1)
    80002232:	00000097          	auipc	ra,0x0
    80002236:	8b6080e7          	jalr	-1866(ra) # 80001ae8 <insert_to_list>
  p->state = RUNNABLE;
    8000223a:	478d                	li	a5,3
    8000223c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a6a080e7          	jalr	-1430(ra) # 80000caa <release>
}
    80002248:	70e2                	ld	ra,56(sp)
    8000224a:	7442                	ld	s0,48(sp)
    8000224c:	74a2                	ld	s1,40(sp)
    8000224e:	6121                	addi	sp,sp,64
    80002250:	8082                	ret

0000000080002252 <growproc>:
{
    80002252:	1101                	addi	sp,sp,-32
    80002254:	ec06                	sd	ra,24(sp)
    80002256:	e822                	sd	s0,16(sp)
    80002258:	e426                	sd	s1,8(sp)
    8000225a:	e04a                	sd	s2,0(sp)
    8000225c:	1000                	addi	s0,sp,32
    8000225e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	bae080e7          	jalr	-1106(ra) # 80001e0e <myproc>
    80002268:	892a                	mv	s2,a0
  sz = p->sz;
    8000226a:	752c                	ld	a1,104(a0)
    8000226c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002270:	00904f63          	bgtz	s1,8000228e <growproc+0x3c>
  } else if(n < 0){
    80002274:	0204cc63          	bltz	s1,800022ac <growproc+0x5a>
  p->sz = sz;
    80002278:	1602                	slli	a2,a2,0x20
    8000227a:	9201                	srli	a2,a2,0x20
    8000227c:	06c93423          	sd	a2,104(s2)
  return 0;
    80002280:	4501                	li	a0,0
}
    80002282:	60e2                	ld	ra,24(sp)
    80002284:	6442                	ld	s0,16(sp)
    80002286:	64a2                	ld	s1,8(sp)
    80002288:	6902                	ld	s2,0(sp)
    8000228a:	6105                	addi	sp,sp,32
    8000228c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000228e:	9e25                	addw	a2,a2,s1
    80002290:	1602                	slli	a2,a2,0x20
    80002292:	9201                	srli	a2,a2,0x20
    80002294:	1582                	slli	a1,a1,0x20
    80002296:	9181                	srli	a1,a1,0x20
    80002298:	7928                	ld	a0,112(a0)
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	1ac080e7          	jalr	428(ra) # 80001446 <uvmalloc>
    800022a2:	0005061b          	sext.w	a2,a0
    800022a6:	fa69                	bnez	a2,80002278 <growproc+0x26>
      return -1;
    800022a8:	557d                	li	a0,-1
    800022aa:	bfe1                	j	80002282 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022ac:	9e25                	addw	a2,a2,s1
    800022ae:	1602                	slli	a2,a2,0x20
    800022b0:	9201                	srli	a2,a2,0x20
    800022b2:	1582                	slli	a1,a1,0x20
    800022b4:	9181                	srli	a1,a1,0x20
    800022b6:	7928                	ld	a0,112(a0)
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	146080e7          	jalr	326(ra) # 800013fe <uvmdealloc>
    800022c0:	0005061b          	sext.w	a2,a0
    800022c4:	bf55                	j	80002278 <growproc+0x26>

00000000800022c6 <fork>:
{
    800022c6:	715d                	addi	sp,sp,-80
    800022c8:	e486                	sd	ra,72(sp)
    800022ca:	e0a2                	sd	s0,64(sp)
    800022cc:	fc26                	sd	s1,56(sp)
    800022ce:	f84a                	sd	s2,48(sp)
    800022d0:	f44e                	sd	s3,40(sp)
    800022d2:	f052                	sd	s4,32(sp)
    800022d4:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	b38080e7          	jalr	-1224(ra) # 80001e0e <myproc>
    800022de:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	d92080e7          	jalr	-622(ra) # 80002072 <allocproc>
    800022e8:	16050c63          	beqz	a0,80002460 <fork+0x19a>
    800022ec:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022ee:	06893603          	ld	a2,104(s2)
    800022f2:	792c                	ld	a1,112(a0)
    800022f4:	07093503          	ld	a0,112(s2)
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	29a080e7          	jalr	666(ra) # 80001592 <uvmcopy>
    80002300:	04054663          	bltz	a0,8000234c <fork+0x86>
  np->sz = p->sz;
    80002304:	06893783          	ld	a5,104(s2)
    80002308:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    8000230c:	07893683          	ld	a3,120(s2)
    80002310:	87b6                	mv	a5,a3
    80002312:	0789b703          	ld	a4,120(s3)
    80002316:	12068693          	addi	a3,a3,288
    8000231a:	0007b803          	ld	a6,0(a5)
    8000231e:	6788                	ld	a0,8(a5)
    80002320:	6b8c                	ld	a1,16(a5)
    80002322:	6f90                	ld	a2,24(a5)
    80002324:	01073023          	sd	a6,0(a4)
    80002328:	e708                	sd	a0,8(a4)
    8000232a:	eb0c                	sd	a1,16(a4)
    8000232c:	ef10                	sd	a2,24(a4)
    8000232e:	02078793          	addi	a5,a5,32
    80002332:	02070713          	addi	a4,a4,32
    80002336:	fed792e3          	bne	a5,a3,8000231a <fork+0x54>
  np->trapframe->a0 = 0;
    8000233a:	0789b783          	ld	a5,120(s3)
    8000233e:	0607b823          	sd	zero,112(a5)
    80002342:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80002346:	17000a13          	li	s4,368
    8000234a:	a03d                	j	80002378 <fork+0xb2>
    freeproc(np);
    8000234c:	854e                	mv	a0,s3
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	c64080e7          	jalr	-924(ra) # 80001fb2 <freeproc>
    release(&np->lock);
    80002356:	854e                	mv	a0,s3
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	952080e7          	jalr	-1710(ra) # 80000caa <release>
    return -1;
    80002360:	5a7d                	li	s4,-1
    80002362:	a0f5                	j	8000244e <fork+0x188>
      np->ofile[i] = filedup(p->ofile[i]);
    80002364:	00003097          	auipc	ra,0x3
    80002368:	8ce080e7          	jalr	-1842(ra) # 80004c32 <filedup>
    8000236c:	009987b3          	add	a5,s3,s1
    80002370:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002372:	04a1                	addi	s1,s1,8
    80002374:	01448763          	beq	s1,s4,80002382 <fork+0xbc>
    if(p->ofile[i])
    80002378:	009907b3          	add	a5,s2,s1
    8000237c:	6388                	ld	a0,0(a5)
    8000237e:	f17d                	bnez	a0,80002364 <fork+0x9e>
    80002380:	bfcd                	j	80002372 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002382:	17093503          	ld	a0,368(s2)
    80002386:	00002097          	auipc	ra,0x2
    8000238a:	a22080e7          	jalr	-1502(ra) # 80003da8 <idup>
    8000238e:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002392:	17898493          	addi	s1,s3,376
    80002396:	4641                	li	a2,16
    80002398:	17890593          	addi	a1,s2,376
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	ab8080e7          	jalr	-1352(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    800023a6:	0309aa03          	lw	s4,48(s3)
  np->cpu_num=p->cpu_num; //giving the child it's parent's cpu_num (the only change)
    800023aa:	03492783          	lw	a5,52(s2)
    800023ae:	02f9aa23          	sw	a5,52(s3)
  initlock(&np->linked_list_lock, np->name);
    800023b2:	85a6                	mv	a1,s1
    800023b4:	04098513          	addi	a0,s3,64
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	79c080e7          	jalr	1948(ra) # 80000b54 <initlock>
  release(&np->lock);
    800023c0:	854e                	mv	a0,s3
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8e8080e7          	jalr	-1816(ra) # 80000caa <release>
  acquire(&wait_lock);
    800023ca:	00008497          	auipc	s1,0x8
    800023ce:	dde48493          	addi	s1,s1,-546 # 8000a1a8 <wait_lock>
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	810080e7          	jalr	-2032(ra) # 80000be4 <acquire>
  np->parent = p;
    800023dc:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8c8080e7          	jalr	-1848(ra) # 80000caa <release>
  acquire(&np->lock);
    800023ea:	854e                	mv	a0,s3
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	7f8080e7          	jalr	2040(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023f4:	478d                	li	a5,3
    800023f6:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(np->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    800023fa:	03492583          	lw	a1,52(s2)
    800023fe:	00159793          	slli	a5,a1,0x1
    80002402:	97ae                	add	a5,a5,a1
    80002404:	00379713          	slli	a4,a5,0x3
    80002408:	00008797          	auipc	a5,0x8
    8000240c:	d8878793          	addi	a5,a5,-632 # 8000a190 <pid_lock>
    80002410:	97ba                	add	a5,a5,a4
    80002412:	7ff8                	ld	a4,248(a5)
    80002414:	fae43823          	sd	a4,-80(s0)
    80002418:	1007b703          	ld	a4,256(a5)
    8000241c:	fae43c23          	sd	a4,-72(s0)
    80002420:	1087b783          	ld	a5,264(a5)
    80002424:	fcf43023          	sd	a5,-64(s0)
    80002428:	058a                	slli	a1,a1,0x2
    8000242a:	fb040613          	addi	a2,s0,-80
    8000242e:	00007797          	auipc	a5,0x7
    80002432:	bfa78793          	addi	a5,a5,-1030 # 80009028 <cpus_ll>
    80002436:	95be                	add	a1,a1,a5
    80002438:	0389a503          	lw	a0,56(s3)
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	6ac080e7          	jalr	1708(ra) # 80001ae8 <insert_to_list>
  release(&np->lock);
    80002444:	854e                	mv	a0,s3
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	864080e7          	jalr	-1948(ra) # 80000caa <release>
}
    8000244e:	8552                	mv	a0,s4
    80002450:	60a6                	ld	ra,72(sp)
    80002452:	6406                	ld	s0,64(sp)
    80002454:	74e2                	ld	s1,56(sp)
    80002456:	7942                	ld	s2,48(sp)
    80002458:	79a2                	ld	s3,40(sp)
    8000245a:	7a02                	ld	s4,32(sp)
    8000245c:	6161                	addi	sp,sp,80
    8000245e:	8082                	ret
    return -1;
    80002460:	5a7d                	li	s4,-1
    80002462:	b7f5                	j	8000244e <fork+0x188>

0000000080002464 <scheduler>:
{
    80002464:	7119                	addi	sp,sp,-128
    80002466:	fc86                	sd	ra,120(sp)
    80002468:	f8a2                	sd	s0,112(sp)
    8000246a:	f4a6                	sd	s1,104(sp)
    8000246c:	f0ca                	sd	s2,96(sp)
    8000246e:	ecce                	sd	s3,88(sp)
    80002470:	e8d2                	sd	s4,80(sp)
    80002472:	e4d6                	sd	s5,72(sp)
    80002474:	e0da                	sd	s6,64(sp)
    80002476:	fc5e                	sd	s7,56(sp)
    80002478:	f862                	sd	s8,48(sp)
    8000247a:	f466                	sd	s9,40(sp)
    8000247c:	f06a                	sd	s10,32(sp)
    8000247e:	0100                	addi	s0,sp,128
    80002480:	8792                	mv	a5,tp
  int id = r_tp();
    80002482:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002484:	00779b93          	slli	s7,a5,0x7
    80002488:	00008717          	auipc	a4,0x8
    8000248c:	d0870713          	addi	a4,a4,-760 # 8000a190 <pid_lock>
    80002490:	975e                	add	a4,a4,s7
    80002492:	06073c23          	sd	zero,120(a4)
      swtch(&c->context, &p->context);
    80002496:	00008717          	auipc	a4,0x8
    8000249a:	d7a70713          	addi	a4,a4,-646 # 8000a210 <cpus+0x8>
    8000249e:	9bba                	add	s7,s7,a4
    if (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800024a0:	00007497          	auipc	s1,0x7
    800024a4:	b8848493          	addi	s1,s1,-1144 # 80009028 <cpus_ll>
    800024a8:	597d                	li	s2,-1
    800024aa:	18800b13          	li	s6,392
      p = &proc[cpus_ll[cpuid()]];
    800024ae:	00008997          	auipc	s3,0x8
    800024b2:	df298993          	addi	s3,s3,-526 # 8000a2a0 <proc>
      remove_from_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
    800024b6:	00008a97          	auipc	s5,0x8
    800024ba:	cdaa8a93          	addi	s5,s5,-806 # 8000a190 <pid_lock>
      c->proc = p;
    800024be:	079e                	slli	a5,a5,0x7
    800024c0:	00fa8a33          	add	s4,s5,a5
    800024c4:	a801                	j	800024d4 <scheduler+0x70>
        c->proc = 0;
    800024c6:	060a3c23          	sd	zero,120(s4)
        release(&p->lock);
    800024ca:	8566                	mv	a0,s9
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7de080e7          	jalr	2014(ra) # 80000caa <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800024d8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024dc:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    800024e0:	8792                	mv	a5,tp
    if (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800024e2:	2781                	sext.w	a5,a5
    800024e4:	078a                	slli	a5,a5,0x2
    800024e6:	97a6                	add	a5,a5,s1
    800024e8:	0007ac03          	lw	s8,0(a5)
    800024ec:	ff2c04e3          	beq	s8,s2,800024d4 <scheduler+0x70>
    800024f0:	8792                	mv	a5,tp
  return id;
    800024f2:	036c0d33          	mul	s10,s8,s6
      p = &proc[cpus_ll[cpuid()]];
    800024f6:	013d0cb3          	add	s9,s10,s3
      acquire(&p->lock);
    800024fa:	8566                	mv	a0,s9
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	6e8080e7          	jalr	1768(ra) # 80000be4 <acquire>
    80002504:	8592                	mv	a1,tp
    80002506:	8792                	mv	a5,tp
      remove_from_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
    80002508:	0007871b          	sext.w	a4,a5
    8000250c:	00171793          	slli	a5,a4,0x1
    80002510:	97ba                	add	a5,a5,a4
    80002512:	078e                	slli	a5,a5,0x3
    80002514:	97d6                	add	a5,a5,s5
    80002516:	7ff8                	ld	a4,248(a5)
    80002518:	f8e43023          	sd	a4,-128(s0)
    8000251c:	1007b703          	ld	a4,256(a5)
    80002520:	f8e43423          	sd	a4,-120(s0)
    80002524:	1087b783          	ld	a5,264(a5)
    80002528:	f8f43823          	sd	a5,-112(s0)
    8000252c:	2581                	sext.w	a1,a1
    8000252e:	058a                	slli	a1,a1,0x2
    80002530:	f8040613          	addi	a2,s0,-128
    80002534:	95a6                	add	a1,a1,s1
    80002536:	038ca503          	lw	a0,56(s9)
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	3f0080e7          	jalr	1008(ra) # 8000192a <remove_from_list>
      p->state = RUNNING;
    80002542:	4791                	li	a5,4
    80002544:	00fcac23          	sw	a5,24(s9)
      c->proc = p;
    80002548:	079a3c23          	sd	s9,120(s4)
      swtch(&c->context, &p->context);
    8000254c:	080d0593          	addi	a1,s10,128
    80002550:	95ce                	add	a1,a1,s3
    80002552:	855e                	mv	a0,s7
    80002554:	00001097          	auipc	ra,0x1
    80002558:	82e080e7          	jalr	-2002(ra) # 80002d82 <swtch>
      if(p->state!=ZOMBIE){
    8000255c:	018ca703          	lw	a4,24(s9)
    80002560:	4795                	li	a5,5
    80002562:	f6f702e3          	beq	a4,a5,800024c6 <scheduler+0x62>
    80002566:	8592                	mv	a1,tp
    80002568:	8792                	mv	a5,tp
        insert_to_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
    8000256a:	0007871b          	sext.w	a4,a5
    8000256e:	00171793          	slli	a5,a4,0x1
    80002572:	97ba                	add	a5,a5,a4
    80002574:	078e                	slli	a5,a5,0x3
    80002576:	97d6                	add	a5,a5,s5
    80002578:	7ff8                	ld	a4,248(a5)
    8000257a:	f8e43023          	sd	a4,-128(s0)
    8000257e:	1007b703          	ld	a4,256(a5)
    80002582:	f8e43423          	sd	a4,-120(s0)
    80002586:	1087b783          	ld	a5,264(a5)
    8000258a:	f8f43823          	sd	a5,-112(s0)
    8000258e:	2581                	sext.w	a1,a1
    80002590:	058a                	slli	a1,a1,0x2
    80002592:	f8040613          	addi	a2,s0,-128
    80002596:	95a6                	add	a1,a1,s1
    80002598:	038ca503          	lw	a0,56(s9)
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	54c080e7          	jalr	1356(ra) # 80001ae8 <insert_to_list>
    800025a4:	b70d                	j	800024c6 <scheduler+0x62>

00000000800025a6 <sched>:
{
    800025a6:	7179                	addi	sp,sp,-48
    800025a8:	f406                	sd	ra,40(sp)
    800025aa:	f022                	sd	s0,32(sp)
    800025ac:	ec26                	sd	s1,24(sp)
    800025ae:	e84a                	sd	s2,16(sp)
    800025b0:	e44e                	sd	s3,8(sp)
    800025b2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025b4:	00000097          	auipc	ra,0x0
    800025b8:	85a080e7          	jalr	-1958(ra) # 80001e0e <myproc>
    800025bc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	5ac080e7          	jalr	1452(ra) # 80000b6a <holding>
    800025c6:	c93d                	beqz	a0,8000263c <sched+0x96>
    800025c8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    800025ca:	2781                	sext.w	a5,a5
    800025cc:	079e                	slli	a5,a5,0x7
    800025ce:	00008717          	auipc	a4,0x8
    800025d2:	bc270713          	addi	a4,a4,-1086 # 8000a190 <pid_lock>
    800025d6:	97ba                	add	a5,a5,a4
    800025d8:	0f07a703          	lw	a4,240(a5)
    800025dc:	4785                	li	a5,1
    800025de:	06f71763          	bne	a4,a5,8000264c <sched+0xa6>
  if(p->state == RUNNING)
    800025e2:	4c98                	lw	a4,24(s1)
    800025e4:	4791                	li	a5,4
    800025e6:	06f70b63          	beq	a4,a5,8000265c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025ee:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025f0:	efb5                	bnez	a5,8000266c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025f2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025f4:	00008917          	auipc	s2,0x8
    800025f8:	b9c90913          	addi	s2,s2,-1124 # 8000a190 <pid_lock>
    800025fc:	2781                	sext.w	a5,a5
    800025fe:	079e                	slli	a5,a5,0x7
    80002600:	97ca                	add	a5,a5,s2
    80002602:	0f47a983          	lw	s3,244(a5)
    80002606:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002608:	2781                	sext.w	a5,a5
    8000260a:	079e                	slli	a5,a5,0x7
    8000260c:	00008597          	auipc	a1,0x8
    80002610:	c0458593          	addi	a1,a1,-1020 # 8000a210 <cpus+0x8>
    80002614:	95be                	add	a1,a1,a5
    80002616:	08048513          	addi	a0,s1,128
    8000261a:	00000097          	auipc	ra,0x0
    8000261e:	768080e7          	jalr	1896(ra) # 80002d82 <swtch>
    80002622:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002624:	2781                	sext.w	a5,a5
    80002626:	079e                	slli	a5,a5,0x7
    80002628:	97ca                	add	a5,a5,s2
    8000262a:	0f37aa23          	sw	s3,244(a5)
}
    8000262e:	70a2                	ld	ra,40(sp)
    80002630:	7402                	ld	s0,32(sp)
    80002632:	64e2                	ld	s1,24(sp)
    80002634:	6942                	ld	s2,16(sp)
    80002636:	69a2                	ld	s3,8(sp)
    80002638:	6145                	addi	sp,sp,48
    8000263a:	8082                	ret
    panic("sched p->lock");
    8000263c:	00006517          	auipc	a0,0x6
    80002640:	ce450513          	addi	a0,a0,-796 # 80008320 <digits+0x2e0>
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	efa080e7          	jalr	-262(ra) # 8000053e <panic>
    panic("sched locks");
    8000264c:	00006517          	auipc	a0,0x6
    80002650:	ce450513          	addi	a0,a0,-796 # 80008330 <digits+0x2f0>
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	eea080e7          	jalr	-278(ra) # 8000053e <panic>
    panic("sched running");
    8000265c:	00006517          	auipc	a0,0x6
    80002660:	ce450513          	addi	a0,a0,-796 # 80008340 <digits+0x300>
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	eda080e7          	jalr	-294(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000266c:	00006517          	auipc	a0,0x6
    80002670:	ce450513          	addi	a0,a0,-796 # 80008350 <digits+0x310>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>

000000008000267c <yield>:
{
    8000267c:	7139                	addi	sp,sp,-64
    8000267e:	fc06                	sd	ra,56(sp)
    80002680:	f822                	sd	s0,48(sp)
    80002682:	f426                	sd	s1,40(sp)
    80002684:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	788080e7          	jalr	1928(ra) # 80001e0e <myproc>
    8000268e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	554080e7          	jalr	1364(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002698:	478d                	li	a5,3
    8000269a:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    8000269c:	58cc                	lw	a1,52(s1)
    8000269e:	00159793          	slli	a5,a1,0x1
    800026a2:	97ae                	add	a5,a5,a1
    800026a4:	00379713          	slli	a4,a5,0x3
    800026a8:	00008797          	auipc	a5,0x8
    800026ac:	ae878793          	addi	a5,a5,-1304 # 8000a190 <pid_lock>
    800026b0:	97ba                	add	a5,a5,a4
    800026b2:	7ff8                	ld	a4,248(a5)
    800026b4:	fce43023          	sd	a4,-64(s0)
    800026b8:	1007b703          	ld	a4,256(a5)
    800026bc:	fce43423          	sd	a4,-56(s0)
    800026c0:	1087b783          	ld	a5,264(a5)
    800026c4:	fcf43823          	sd	a5,-48(s0)
    800026c8:	058a                	slli	a1,a1,0x2
    800026ca:	fc040613          	addi	a2,s0,-64
    800026ce:	00007797          	auipc	a5,0x7
    800026d2:	95a78793          	addi	a5,a5,-1702 # 80009028 <cpus_ll>
    800026d6:	95be                	add	a1,a1,a5
    800026d8:	5c88                	lw	a0,56(s1)
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	40e080e7          	jalr	1038(ra) # 80001ae8 <insert_to_list>
  sched();
    800026e2:	00000097          	auipc	ra,0x0
    800026e6:	ec4080e7          	jalr	-316(ra) # 800025a6 <sched>
  release(&p->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	5be080e7          	jalr	1470(ra) # 80000caa <release>
}
    800026f4:	70e2                	ld	ra,56(sp)
    800026f6:	7442                	ld	s0,48(sp)
    800026f8:	74a2                	ld	s1,40(sp)
    800026fa:	6121                	addi	sp,sp,64
    800026fc:	8082                	ret

00000000800026fe <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800026fe:	715d                	addi	sp,sp,-80
    80002700:	e486                	sd	ra,72(sp)
    80002702:	e0a2                	sd	s0,64(sp)
    80002704:	fc26                	sd	s1,56(sp)
    80002706:	f84a                	sd	s2,48(sp)
    80002708:	f44e                	sd	s3,40(sp)
    8000270a:	0880                	addi	s0,sp,80
    8000270c:	89aa                	mv	s3,a0
    8000270e:	892e                	mv	s2,a1
  //printf("entered sleep\n");
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	6fe080e7          	jalr	1790(ra) # 80001e0e <myproc>
    80002718:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.

 // printf("the proccec index is:%d and the process state is:%d\n",p->index,p->state);
 // printf("exit from the insertion of %d to the sleeping list.\n",ret);
  acquire(&p->lock);  //DOC: sleeplock1
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	4ca080e7          	jalr	1226(ra) # 80000be4 <acquire>
  release(lk);
    80002722:	854a                	mv	a0,s2
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	586080e7          	jalr	1414(ra) # 80000caa <release>

  // Go to sleep.
  p->chan = chan;
    8000272c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002730:	4789                	li	a5,2
    80002732:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index,&sleeping,sleeping_head);
    80002734:	00008797          	auipc	a5,0x8
    80002738:	a5c78793          	addi	a5,a5,-1444 # 8000a190 <pid_lock>
    8000273c:	7b98                	ld	a4,48(a5)
    8000273e:	fae43823          	sd	a4,-80(s0)
    80002742:	7f98                	ld	a4,56(a5)
    80002744:	fae43c23          	sd	a4,-72(s0)
    80002748:	63bc                	ld	a5,64(a5)
    8000274a:	fcf43023          	sd	a5,-64(s0)
    8000274e:	fb040613          	addi	a2,s0,-80
    80002752:	00006597          	auipc	a1,0x6
    80002756:	1da58593          	addi	a1,a1,474 # 8000892c <sleeping>
    8000275a:	5c88                	lw	a0,56(s1)
    8000275c:	fffff097          	auipc	ra,0xfffff
    80002760:	38c080e7          	jalr	908(ra) # 80001ae8 <insert_to_list>
  //printf("the number of locks is:%d\n",mycpu()->noff);
  sched();
    80002764:	00000097          	auipc	ra,0x0
    80002768:	e42080e7          	jalr	-446(ra) # 800025a6 <sched>

  // Tidy up.
  p->chan = 0;
    8000276c:	0204b023          	sd	zero,32(s1)
  // Reacquire original lock.
  release(&p->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	538080e7          	jalr	1336(ra) # 80000caa <release>
  acquire(lk);
    8000277a:	854a                	mv	a0,s2
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	468080e7          	jalr	1128(ra) # 80000be4 <acquire>
    //printf("exit sleep\n");

}
    80002784:	60a6                	ld	ra,72(sp)
    80002786:	6406                	ld	s0,64(sp)
    80002788:	74e2                	ld	s1,56(sp)
    8000278a:	7942                	ld	s2,48(sp)
    8000278c:	79a2                	ld	s3,40(sp)
    8000278e:	6161                	addi	sp,sp,80
    80002790:	8082                	ret

0000000080002792 <wait>:
{
    80002792:	715d                	addi	sp,sp,-80
    80002794:	e486                	sd	ra,72(sp)
    80002796:	e0a2                	sd	s0,64(sp)
    80002798:	fc26                	sd	s1,56(sp)
    8000279a:	f84a                	sd	s2,48(sp)
    8000279c:	f44e                	sd	s3,40(sp)
    8000279e:	f052                	sd	s4,32(sp)
    800027a0:	ec56                	sd	s5,24(sp)
    800027a2:	e85a                	sd	s6,16(sp)
    800027a4:	e45e                	sd	s7,8(sp)
    800027a6:	e062                	sd	s8,0(sp)
    800027a8:	0880                	addi	s0,sp,80
    800027aa:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	662080e7          	jalr	1634(ra) # 80001e0e <myproc>
    800027b4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027b6:	00008517          	auipc	a0,0x8
    800027ba:	9f250513          	addi	a0,a0,-1550 # 8000a1a8 <wait_lock>
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	426080e7          	jalr	1062(ra) # 80000be4 <acquire>
    havekids = 0;
    800027c6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027c8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800027ca:	0000e997          	auipc	s3,0xe
    800027ce:	cd698993          	addi	s3,s3,-810 # 800104a0 <tickslock>
        havekids = 1;
    800027d2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027d4:	00008c17          	auipc	s8,0x8
    800027d8:	9d4c0c13          	addi	s8,s8,-1580 # 8000a1a8 <wait_lock>
    havekids = 0;
    800027dc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027de:	00008497          	auipc	s1,0x8
    800027e2:	ac248493          	addi	s1,s1,-1342 # 8000a2a0 <proc>
    800027e6:	a0bd                	j	80002854 <wait+0xc2>
          pid = np->pid;
    800027e8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027ec:	000b0e63          	beqz	s6,80002808 <wait+0x76>
    800027f0:	4691                	li	a3,4
    800027f2:	02c48613          	addi	a2,s1,44
    800027f6:	85da                	mv	a1,s6
    800027f8:	07093503          	ld	a0,112(s2)
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	e9a080e7          	jalr	-358(ra) # 80001696 <copyout>
    80002804:	02054563          	bltz	a0,8000282e <wait+0x9c>
          freeproc(np);
    80002808:	8526                	mv	a0,s1
    8000280a:	fffff097          	auipc	ra,0xfffff
    8000280e:	7a8080e7          	jalr	1960(ra) # 80001fb2 <freeproc>
          release(&np->lock);
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	496080e7          	jalr	1174(ra) # 80000caa <release>
          release(&wait_lock);
    8000281c:	00008517          	auipc	a0,0x8
    80002820:	98c50513          	addi	a0,a0,-1652 # 8000a1a8 <wait_lock>
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	486080e7          	jalr	1158(ra) # 80000caa <release>
          return pid;
    8000282c:	a09d                	j	80002892 <wait+0x100>
            release(&np->lock);
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	47a080e7          	jalr	1146(ra) # 80000caa <release>
            release(&wait_lock);
    80002838:	00008517          	auipc	a0,0x8
    8000283c:	97050513          	addi	a0,a0,-1680 # 8000a1a8 <wait_lock>
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	46a080e7          	jalr	1130(ra) # 80000caa <release>
            return -1;
    80002848:	59fd                	li	s3,-1
    8000284a:	a0a1                	j	80002892 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000284c:	18848493          	addi	s1,s1,392
    80002850:	03348463          	beq	s1,s3,80002878 <wait+0xe6>
      if(np->parent == p){
    80002854:	6cbc                	ld	a5,88(s1)
    80002856:	ff279be3          	bne	a5,s2,8000284c <wait+0xba>
        acquire(&np->lock);
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	388080e7          	jalr	904(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002864:	4c9c                	lw	a5,24(s1)
    80002866:	f94781e3          	beq	a5,s4,800027e8 <wait+0x56>
        release(&np->lock);
    8000286a:	8526                	mv	a0,s1
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	43e080e7          	jalr	1086(ra) # 80000caa <release>
        havekids = 1;
    80002874:	8756                	mv	a4,s5
    80002876:	bfd9                	j	8000284c <wait+0xba>
    if(!havekids || p->killed){
    80002878:	c701                	beqz	a4,80002880 <wait+0xee>
    8000287a:	02892783          	lw	a5,40(s2)
    8000287e:	c79d                	beqz	a5,800028ac <wait+0x11a>
      release(&wait_lock);
    80002880:	00008517          	auipc	a0,0x8
    80002884:	92850513          	addi	a0,a0,-1752 # 8000a1a8 <wait_lock>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	422080e7          	jalr	1058(ra) # 80000caa <release>
      return -1;
    80002890:	59fd                	li	s3,-1
}
    80002892:	854e                	mv	a0,s3
    80002894:	60a6                	ld	ra,72(sp)
    80002896:	6406                	ld	s0,64(sp)
    80002898:	74e2                	ld	s1,56(sp)
    8000289a:	7942                	ld	s2,48(sp)
    8000289c:	79a2                	ld	s3,40(sp)
    8000289e:	7a02                	ld	s4,32(sp)
    800028a0:	6ae2                	ld	s5,24(sp)
    800028a2:	6b42                	ld	s6,16(sp)
    800028a4:	6ba2                	ld	s7,8(sp)
    800028a6:	6c02                	ld	s8,0(sp)
    800028a8:	6161                	addi	sp,sp,80
    800028aa:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028ac:	85e2                	mv	a1,s8
    800028ae:	854a                	mv	a0,s2
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	e4e080e7          	jalr	-434(ra) # 800026fe <sleep>
    havekids = 0;
    800028b8:	b715                	j	800027dc <wait+0x4a>

00000000800028ba <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028ba:	7119                	addi	sp,sp,-128
    800028bc:	fc86                	sd	ra,120(sp)
    800028be:	f8a2                	sd	s0,112(sp)
    800028c0:	f4a6                	sd	s1,104(sp)
    800028c2:	f0ca                	sd	s2,96(sp)
    800028c4:	ecce                	sd	s3,88(sp)
    800028c6:	e8d2                	sd	s4,80(sp)
    800028c8:	e4d6                	sd	s5,72(sp)
    800028ca:	e0da                	sd	s6,64(sp)
    800028cc:	fc5e                	sd	s7,56(sp)
    800028ce:	f862                	sd	s8,48(sp)
    800028d0:	f466                	sd	s9,40(sp)
    800028d2:	f06a                	sd	s10,32(sp)
    800028d4:	0100                	addi	s0,sp,128
  struct proc *p;
  if (sleeping == -1){
    800028d6:	00006497          	auipc	s1,0x6
    800028da:	0564a483          	lw	s1,86(s1) # 8000892c <sleeping>
    800028de:	57fd                	li	a5,-1
    800028e0:	0ef48d63          	beq	s1,a5,800029da <wakeup+0x120>
    800028e4:	89aa                	mv	s3,a0
      //printf("process p->pid = %d\n", p->pid);
    //printf("no one is sleeping so exit\n");
    return;
  } // if no one is sleeping - do nothing
  //acquire(&sleeping_head);
  p = &proc[sleeping];
    800028e6:	18800793          	li	a5,392
    800028ea:	02f484b3          	mul	s1,s1,a5
    800028ee:	00008797          	auipc	a5,0x8
    800028f2:	9b278793          	addi	a5,a5,-1614 # 8000a2a0 <proc>
    800028f6:	94be                	add	s1,s1,a5
  int curr= proc[sleeping].index;
  while(curr!=-1) { // loop through all sleepers
    800028f8:	5c98                	lw	a4,56(s1)
    800028fa:	57fd                	li	a5,-1
    800028fc:	0cf70f63          	beq	a4,a5,800029da <wakeup+0x120>
    if(p != myproc()){
      //printf("process p->pid = %d\n", p->pid);
      acquire(&p->lock);
      if(p->chan == chan && p->state==SLEEPING) {
    80002900:	4a89                	li	s5,2
        remove_from_list(p->index,&sleeping,sleeping_head);
    80002902:	00008b17          	auipc	s6,0x8
    80002906:	88eb0b13          	addi	s6,s6,-1906 # 8000a190 <pid_lock>
    8000290a:	00006c97          	auipc	s9,0x6
    8000290e:	022c8c93          	addi	s9,s9,34 # 8000892c <sleeping>
        p->chan=0;
        p->state = RUNNABLE;
    80002912:	4c0d                	li	s8,3
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002914:	00006b97          	auipc	s7,0x6
    80002918:	714b8b93          	addi	s7,s7,1812 # 80009028 <cpus_ll>
      }
      release(&p->lock);
    }
    if(p->next!=-1)
    8000291c:	597d                	li	s2,-1
      p = &proc[p->next];
    8000291e:	00008a17          	auipc	s4,0x8
    80002922:	982a0a13          	addi	s4,s4,-1662 # 8000a2a0 <proc>
    80002926:	a02d                	j	80002950 <wakeup+0x96>
      release(&p->lock);
    80002928:	856a                	mv	a0,s10
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	380080e7          	jalr	896(ra) # 80000caa <release>
    if(p->next!=-1)
    80002932:	5cdc                	lw	a5,60(s1)
    80002934:	2781                	sext.w	a5,a5
    80002936:	01278963          	beq	a5,s2,80002948 <wakeup+0x8e>
      p = &proc[p->next];
    8000293a:	5cc4                	lw	s1,60(s1)
    8000293c:	2481                	sext.w	s1,s1
    8000293e:	18800793          	li	a5,392
    80002942:	02f484b3          	mul	s1,s1,a5
    80002946:	94d2                	add	s1,s1,s4
    curr=p->next;
    80002948:	5cdc                	lw	a5,60(s1)
    8000294a:	2781                	sext.w	a5,a5
  while(curr!=-1) { // loop through all sleepers
    8000294c:	09278763          	beq	a5,s2,800029da <wakeup+0x120>
    if(p != myproc()){
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	4be080e7          	jalr	1214(ra) # 80001e0e <myproc>
    80002958:	fca48de3          	beq	s1,a0,80002932 <wakeup+0x78>
      acquire(&p->lock);
    8000295c:	8d26                	mv	s10,s1
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	284080e7          	jalr	644(ra) # 80000be4 <acquire>
      if(p->chan == chan && p->state==SLEEPING) {
    80002968:	709c                	ld	a5,32(s1)
    8000296a:	fb379fe3          	bne	a5,s3,80002928 <wakeup+0x6e>
    8000296e:	4c9c                	lw	a5,24(s1)
    80002970:	fb579ce3          	bne	a5,s5,80002928 <wakeup+0x6e>
        remove_from_list(p->index,&sleeping,sleeping_head);
    80002974:	030b3783          	ld	a5,48(s6)
    80002978:	f8f43023          	sd	a5,-128(s0)
    8000297c:	038b3783          	ld	a5,56(s6)
    80002980:	f8f43423          	sd	a5,-120(s0)
    80002984:	040b3783          	ld	a5,64(s6)
    80002988:	f8f43823          	sd	a5,-112(s0)
    8000298c:	f8040613          	addi	a2,s0,-128
    80002990:	85e6                	mv	a1,s9
    80002992:	5c88                	lw	a0,56(s1)
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	f96080e7          	jalr	-106(ra) # 8000192a <remove_from_list>
        p->chan=0;
    8000299c:	0204b023          	sd	zero,32(s1)
        p->state = RUNNABLE;
    800029a0:	0184ac23          	sw	s8,24(s1)
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    800029a4:	58cc                	lw	a1,52(s1)
    800029a6:	00159793          	slli	a5,a1,0x1
    800029aa:	97ae                	add	a5,a5,a1
    800029ac:	078e                	slli	a5,a5,0x3
    800029ae:	97da                	add	a5,a5,s6
    800029b0:	7ff8                	ld	a4,248(a5)
    800029b2:	f8e43023          	sd	a4,-128(s0)
    800029b6:	1007b703          	ld	a4,256(a5)
    800029ba:	f8e43423          	sd	a4,-120(s0)
    800029be:	1087b783          	ld	a5,264(a5)
    800029c2:	f8f43823          	sd	a5,-112(s0)
    800029c6:	058a                	slli	a1,a1,0x2
    800029c8:	f8040613          	addi	a2,s0,-128
    800029cc:	95de                	add	a1,a1,s7
    800029ce:	5c88                	lw	a0,56(s1)
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	118080e7          	jalr	280(ra) # 80001ae8 <insert_to_list>
    800029d8:	bf81                	j	80002928 <wakeup+0x6e>
  }
}
    800029da:	70e6                	ld	ra,120(sp)
    800029dc:	7446                	ld	s0,112(sp)
    800029de:	74a6                	ld	s1,104(sp)
    800029e0:	7906                	ld	s2,96(sp)
    800029e2:	69e6                	ld	s3,88(sp)
    800029e4:	6a46                	ld	s4,80(sp)
    800029e6:	6aa6                	ld	s5,72(sp)
    800029e8:	6b06                	ld	s6,64(sp)
    800029ea:	7be2                	ld	s7,56(sp)
    800029ec:	7c42                	ld	s8,48(sp)
    800029ee:	7ca2                	ld	s9,40(sp)
    800029f0:	7d02                	ld	s10,32(sp)
    800029f2:	6109                	addi	sp,sp,128
    800029f4:	8082                	ret

00000000800029f6 <reparent>:
{
    800029f6:	7179                	addi	sp,sp,-48
    800029f8:	f406                	sd	ra,40(sp)
    800029fa:	f022                	sd	s0,32(sp)
    800029fc:	ec26                	sd	s1,24(sp)
    800029fe:	e84a                	sd	s2,16(sp)
    80002a00:	e44e                	sd	s3,8(sp)
    80002a02:	e052                	sd	s4,0(sp)
    80002a04:	1800                	addi	s0,sp,48
    80002a06:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002a08:	00008497          	auipc	s1,0x8
    80002a0c:	89848493          	addi	s1,s1,-1896 # 8000a2a0 <proc>
      pp->parent = initproc;
    80002a10:	00006a17          	auipc	s4,0x6
    80002a14:	620a0a13          	addi	s4,s4,1568 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002a18:	0000e997          	auipc	s3,0xe
    80002a1c:	a8898993          	addi	s3,s3,-1400 # 800104a0 <tickslock>
    80002a20:	a029                	j	80002a2a <reparent+0x34>
    80002a22:	18848493          	addi	s1,s1,392
    80002a26:	01348d63          	beq	s1,s3,80002a40 <reparent+0x4a>
    if(pp->parent == p){
    80002a2a:	6cbc                	ld	a5,88(s1)
    80002a2c:	ff279be3          	bne	a5,s2,80002a22 <reparent+0x2c>
      pp->parent = initproc;
    80002a30:	000a3503          	ld	a0,0(s4)
    80002a34:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	e84080e7          	jalr	-380(ra) # 800028ba <wakeup>
    80002a3e:	b7d5                	j	80002a22 <reparent+0x2c>
}
    80002a40:	70a2                	ld	ra,40(sp)
    80002a42:	7402                	ld	s0,32(sp)
    80002a44:	64e2                	ld	s1,24(sp)
    80002a46:	6942                	ld	s2,16(sp)
    80002a48:	69a2                	ld	s3,8(sp)
    80002a4a:	6a02                	ld	s4,0(sp)
    80002a4c:	6145                	addi	sp,sp,48
    80002a4e:	8082                	ret

0000000080002a50 <exit>:
{
    80002a50:	715d                	addi	sp,sp,-80
    80002a52:	e486                	sd	ra,72(sp)
    80002a54:	e0a2                	sd	s0,64(sp)
    80002a56:	fc26                	sd	s1,56(sp)
    80002a58:	f84a                	sd	s2,48(sp)
    80002a5a:	f44e                	sd	s3,40(sp)
    80002a5c:	f052                	sd	s4,32(sp)
    80002a5e:	0880                	addi	s0,sp,80
    80002a60:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	3ac080e7          	jalr	940(ra) # 80001e0e <myproc>
    80002a6a:	89aa                	mv	s3,a0
  if(p == initproc)
    80002a6c:	00006797          	auipc	a5,0x6
    80002a70:	5c47b783          	ld	a5,1476(a5) # 80009030 <initproc>
    80002a74:	0f050493          	addi	s1,a0,240
    80002a78:	17050913          	addi	s2,a0,368
    80002a7c:	02a79363          	bne	a5,a0,80002aa2 <exit+0x52>
    panic("init exiting");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	8e850513          	addi	a0,a0,-1816 # 80008368 <digits+0x328>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	ab6080e7          	jalr	-1354(ra) # 8000053e <panic>
      fileclose(f);
    80002a90:	00002097          	auipc	ra,0x2
    80002a94:	1f4080e7          	jalr	500(ra) # 80004c84 <fileclose>
      p->ofile[fd] = 0;
    80002a98:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a9c:	04a1                	addi	s1,s1,8
    80002a9e:	01248563          	beq	s1,s2,80002aa8 <exit+0x58>
    if(p->ofile[fd]){
    80002aa2:	6088                	ld	a0,0(s1)
    80002aa4:	f575                	bnez	a0,80002a90 <exit+0x40>
    80002aa6:	bfdd                	j	80002a9c <exit+0x4c>
  begin_op();
    80002aa8:	00002097          	auipc	ra,0x2
    80002aac:	d10080e7          	jalr	-752(ra) # 800047b8 <begin_op>
  iput(p->cwd);
    80002ab0:	1709b503          	ld	a0,368(s3)
    80002ab4:	00001097          	auipc	ra,0x1
    80002ab8:	4ec080e7          	jalr	1260(ra) # 80003fa0 <iput>
  end_op();
    80002abc:	00002097          	auipc	ra,0x2
    80002ac0:	d7c080e7          	jalr	-644(ra) # 80004838 <end_op>
  p->cwd = 0;
    80002ac4:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002ac8:	00007497          	auipc	s1,0x7
    80002acc:	6c848493          	addi	s1,s1,1736 # 8000a190 <pid_lock>
    80002ad0:	00007917          	auipc	s2,0x7
    80002ad4:	6d890913          	addi	s2,s2,1752 # 8000a1a8 <wait_lock>
    80002ad8:	854a                	mv	a0,s2
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	10a080e7          	jalr	266(ra) # 80000be4 <acquire>
  reparent(p);
    80002ae2:	854e                	mv	a0,s3
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	f12080e7          	jalr	-238(ra) # 800029f6 <reparent>
  wakeup(p->parent);
    80002aec:	0589b503          	ld	a0,88(s3)
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	dca080e7          	jalr	-566(ra) # 800028ba <wakeup>
  acquire(&p->lock);
    80002af8:	854e                	mv	a0,s3
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	0ea080e7          	jalr	234(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002b02:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002b06:	4795                	li	a5,5
    80002b08:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index,&zombie,zombie_head);
    80002b0c:	64bc                	ld	a5,72(s1)
    80002b0e:	faf43823          	sd	a5,-80(s0)
    80002b12:	68bc                	ld	a5,80(s1)
    80002b14:	faf43c23          	sd	a5,-72(s0)
    80002b18:	6cbc                	ld	a5,88(s1)
    80002b1a:	fcf43023          	sd	a5,-64(s0)
    80002b1e:	fb040613          	addi	a2,s0,-80
    80002b22:	00006597          	auipc	a1,0x6
    80002b26:	e0658593          	addi	a1,a1,-506 # 80008928 <zombie>
    80002b2a:	0389a503          	lw	a0,56(s3)
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	fba080e7          	jalr	-70(ra) # 80001ae8 <insert_to_list>
  release(&wait_lock);
    80002b36:	854a                	mv	a0,s2
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	172080e7          	jalr	370(ra) # 80000caa <release>
  sched();
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	a66080e7          	jalr	-1434(ra) # 800025a6 <sched>
  panic("zombie exit");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	83050513          	addi	a0,a0,-2000 # 80008378 <digits+0x338>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>

0000000080002b58 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002b58:	7179                	addi	sp,sp,-48
    80002b5a:	f406                	sd	ra,40(sp)
    80002b5c:	f022                	sd	s0,32(sp)
    80002b5e:	ec26                	sd	s1,24(sp)
    80002b60:	e84a                	sd	s2,16(sp)
    80002b62:	e44e                	sd	s3,8(sp)
    80002b64:	1800                	addi	s0,sp,48
    80002b66:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002b68:	00007497          	auipc	s1,0x7
    80002b6c:	73848493          	addi	s1,s1,1848 # 8000a2a0 <proc>
    80002b70:	0000e997          	auipc	s3,0xe
    80002b74:	93098993          	addi	s3,s3,-1744 # 800104a0 <tickslock>
    acquire(&p->lock);
    80002b78:	8526                	mv	a0,s1
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	06a080e7          	jalr	106(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002b82:	589c                	lw	a5,48(s1)
    80002b84:	01278d63          	beq	a5,s2,80002b9e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002b88:	8526                	mv	a0,s1
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	120080e7          	jalr	288(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b92:	18848493          	addi	s1,s1,392
    80002b96:	ff3491e3          	bne	s1,s3,80002b78 <kill+0x20>
  }
  return -1;
    80002b9a:	557d                	li	a0,-1
    80002b9c:	a829                	j	80002bb6 <kill+0x5e>
      p->killed = 1;
    80002b9e:	4785                	li	a5,1
    80002ba0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002ba2:	4c98                	lw	a4,24(s1)
    80002ba4:	4789                	li	a5,2
    80002ba6:	00f70f63          	beq	a4,a5,80002bc4 <kill+0x6c>
      release(&p->lock);
    80002baa:	8526                	mv	a0,s1
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	0fe080e7          	jalr	254(ra) # 80000caa <release>
      return 0;
    80002bb4:	4501                	li	a0,0
}
    80002bb6:	70a2                	ld	ra,40(sp)
    80002bb8:	7402                	ld	s0,32(sp)
    80002bba:	64e2                	ld	s1,24(sp)
    80002bbc:	6942                	ld	s2,16(sp)
    80002bbe:	69a2                	ld	s3,8(sp)
    80002bc0:	6145                	addi	sp,sp,48
    80002bc2:	8082                	ret
        p->state = RUNNABLE;
    80002bc4:	478d                	li	a5,3
    80002bc6:	cc9c                	sw	a5,24(s1)
    80002bc8:	b7cd                	j	80002baa <kill+0x52>

0000000080002bca <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002bca:	7179                	addi	sp,sp,-48
    80002bcc:	f406                	sd	ra,40(sp)
    80002bce:	f022                	sd	s0,32(sp)
    80002bd0:	ec26                	sd	s1,24(sp)
    80002bd2:	e84a                	sd	s2,16(sp)
    80002bd4:	e44e                	sd	s3,8(sp)
    80002bd6:	e052                	sd	s4,0(sp)
    80002bd8:	1800                	addi	s0,sp,48
    80002bda:	84aa                	mv	s1,a0
    80002bdc:	892e                	mv	s2,a1
    80002bde:	89b2                	mv	s3,a2
    80002be0:	8a36                	mv	s4,a3
  //printf("entered either_copyout\n");
  struct proc *p = myproc();
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	22c080e7          	jalr	556(ra) # 80001e0e <myproc>
  if(user_dst){
    80002bea:	c08d                	beqz	s1,80002c0c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002bec:	86d2                	mv	a3,s4
    80002bee:	864e                	mv	a2,s3
    80002bf0:	85ca                	mv	a1,s2
    80002bf2:	7928                	ld	a0,112(a0)
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	aa2080e7          	jalr	-1374(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002bfc:	70a2                	ld	ra,40(sp)
    80002bfe:	7402                	ld	s0,32(sp)
    80002c00:	64e2                	ld	s1,24(sp)
    80002c02:	6942                	ld	s2,16(sp)
    80002c04:	69a2                	ld	s3,8(sp)
    80002c06:	6a02                	ld	s4,0(sp)
    80002c08:	6145                	addi	sp,sp,48
    80002c0a:	8082                	ret
    memmove((char *)dst, src, len);
    80002c0c:	000a061b          	sext.w	a2,s4
    80002c10:	85ce                	mv	a1,s3
    80002c12:	854a                	mv	a0,s2
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	150080e7          	jalr	336(ra) # 80000d64 <memmove>
    return 0;
    80002c1c:	8526                	mv	a0,s1
    80002c1e:	bff9                	j	80002bfc <either_copyout+0x32>

0000000080002c20 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c20:	7179                	addi	sp,sp,-48
    80002c22:	f406                	sd	ra,40(sp)
    80002c24:	f022                	sd	s0,32(sp)
    80002c26:	ec26                	sd	s1,24(sp)
    80002c28:	e84a                	sd	s2,16(sp)
    80002c2a:	e44e                	sd	s3,8(sp)
    80002c2c:	e052                	sd	s4,0(sp)
    80002c2e:	1800                	addi	s0,sp,48
    80002c30:	892a                	mv	s2,a0
    80002c32:	84ae                	mv	s1,a1
    80002c34:	89b2                	mv	s3,a2
    80002c36:	8a36                	mv	s4,a3
  //printf("entered either_copyin\n");
  struct proc *p = myproc();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	1d6080e7          	jalr	470(ra) # 80001e0e <myproc>
  if(user_src){
    80002c40:	c08d                	beqz	s1,80002c62 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002c42:	86d2                	mv	a3,s4
    80002c44:	864e                	mv	a2,s3
    80002c46:	85ca                	mv	a1,s2
    80002c48:	7928                	ld	a0,112(a0)
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	ad8080e7          	jalr	-1320(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002c52:	70a2                	ld	ra,40(sp)
    80002c54:	7402                	ld	s0,32(sp)
    80002c56:	64e2                	ld	s1,24(sp)
    80002c58:	6942                	ld	s2,16(sp)
    80002c5a:	69a2                	ld	s3,8(sp)
    80002c5c:	6a02                	ld	s4,0(sp)
    80002c5e:	6145                	addi	sp,sp,48
    80002c60:	8082                	ret
    memmove(dst, (char*)src, len);
    80002c62:	000a061b          	sext.w	a2,s4
    80002c66:	85ce                	mv	a1,s3
    80002c68:	854a                	mv	a0,s2
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	0fa080e7          	jalr	250(ra) # 80000d64 <memmove>
    return 0;
    80002c72:	8526                	mv	a0,s1
    80002c74:	bff9                	j	80002c52 <either_copyin+0x32>

0000000080002c76 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002c76:	715d                	addi	sp,sp,-80
    80002c78:	e486                	sd	ra,72(sp)
    80002c7a:	e0a2                	sd	s0,64(sp)
    80002c7c:	fc26                	sd	s1,56(sp)
    80002c7e:	f84a                	sd	s2,48(sp)
    80002c80:	f44e                	sd	s3,40(sp)
    80002c82:	f052                	sd	s4,32(sp)
    80002c84:	ec56                	sd	s5,24(sp)
    80002c86:	e85a                	sd	s6,16(sp)
    80002c88:	e45e                	sd	s7,8(sp)
    80002c8a:	0880                	addi	s0,sp,80
  };
  struct proc *p;
  char *state;

  //printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    80002c8c:	00007497          	auipc	s1,0x7
    80002c90:	78c48493          	addi	s1,s1,1932 # 8000a418 <proc+0x178>
    80002c94:	0000e917          	auipc	s2,0xe
    80002c98:	98490913          	addi	s2,s2,-1660 # 80010618 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c9c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002c9e:	00005997          	auipc	s3,0x5
    80002ca2:	6ea98993          	addi	s3,s3,1770 # 80008388 <digits+0x348>
    printf("%d %s %s", p->pid, state, p->name);
    80002ca6:	00005a97          	auipc	s5,0x5
    80002caa:	6eaa8a93          	addi	s5,s5,1770 # 80008390 <digits+0x350>
    printf("\n");
    80002cae:	00005a17          	auipc	s4,0x5
    80002cb2:	44aa0a13          	addi	s4,s4,1098 # 800080f8 <digits+0xb8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cb6:	00005b97          	auipc	s7,0x5
    80002cba:	712b8b93          	addi	s7,s7,1810 # 800083c8 <states.1762>
    80002cbe:	a00d                	j	80002ce0 <procdump+0x6a>
    printf("%d %s %s", p->pid, state, p->name);
    80002cc0:	eb86a583          	lw	a1,-328(a3)
    80002cc4:	8556                	mv	a0,s5
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8c2080e7          	jalr	-1854(ra) # 80000588 <printf>
    printf("\n");
    80002cce:	8552                	mv	a0,s4
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	8b8080e7          	jalr	-1864(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002cd8:	18848493          	addi	s1,s1,392
    80002cdc:	03248163          	beq	s1,s2,80002cfe <procdump+0x88>
    if(p->state == UNUSED)
    80002ce0:	86a6                	mv	a3,s1
    80002ce2:	ea04a783          	lw	a5,-352(s1)
    80002ce6:	dbed                	beqz	a5,80002cd8 <procdump+0x62>
      state = "???";
    80002ce8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cea:	fcfb6be3          	bltu	s6,a5,80002cc0 <procdump+0x4a>
    80002cee:	1782                	slli	a5,a5,0x20
    80002cf0:	9381                	srli	a5,a5,0x20
    80002cf2:	078e                	slli	a5,a5,0x3
    80002cf4:	97de                	add	a5,a5,s7
    80002cf6:	6390                	ld	a2,0(a5)
    80002cf8:	f661                	bnez	a2,80002cc0 <procdump+0x4a>
      state = "???";
    80002cfa:	864e                	mv	a2,s3
    80002cfc:	b7d1                	j	80002cc0 <procdump+0x4a>
  }
}
    80002cfe:	60a6                	ld	ra,72(sp)
    80002d00:	6406                	ld	s0,64(sp)
    80002d02:	74e2                	ld	s1,56(sp)
    80002d04:	7942                	ld	s2,48(sp)
    80002d06:	79a2                	ld	s3,40(sp)
    80002d08:	7a02                	ld	s4,32(sp)
    80002d0a:	6ae2                	ld	s5,24(sp)
    80002d0c:	6b42                	ld	s6,16(sp)
    80002d0e:	6ba2                	ld	s7,8(sp)
    80002d10:	6161                	addi	sp,sp,80
    80002d12:	8082                	ret

0000000080002d14 <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	1000                	addi	s0,sp,32
    80002d1e:	84aa                	mv	s1,a0
  struct proc *p= myproc();  
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	0ee080e7          	jalr	238(ra) # 80001e0e <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002d28:	8626                	mv	a2,s1
    80002d2a:	594c                	lw	a1,52(a0)
    80002d2c:	03450513          	addi	a0,a0,52
    80002d30:	00004097          	auipc	ra,0x4
    80002d34:	c46080e7          	jalr	-954(ra) # 80006976 <cas>
    80002d38:	e519                	bnez	a0,80002d46 <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002d3a:	4501                	li	a0,0
}
    80002d3c:	60e2                	ld	ra,24(sp)
    80002d3e:	6442                	ld	s0,16(sp)
    80002d40:	64a2                	ld	s1,8(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret
    yield();
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	936080e7          	jalr	-1738(ra) # 8000267c <yield>
    return cpu_num;
    80002d4e:	8526                	mv	a0,s1
    80002d50:	b7f5                	j	80002d3c <set_cpu+0x28>

0000000080002d52 <get_cpu>:

int get_cpu(){ //added as orderd
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	1000                	addi	s0,sp,32
  struct proc *p=myproc();
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	0b4080e7          	jalr	180(ra) # 80001e0e <myproc>
  int ans=0;
    80002d62:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002d66:	5950                	lw	a2,52(a0)
    80002d68:	4581                	li	a1,0
    80002d6a:	fec40513          	addi	a0,s0,-20
    80002d6e:	00004097          	auipc	ra,0x4
    80002d72:	c08080e7          	jalr	-1016(ra) # 80006976 <cas>
    return ans;
}
    80002d76:	fec42503          	lw	a0,-20(s0)
    80002d7a:	60e2                	ld	ra,24(sp)
    80002d7c:	6442                	ld	s0,16(sp)
    80002d7e:	6105                	addi	sp,sp,32
    80002d80:	8082                	ret

0000000080002d82 <swtch>:
    80002d82:	00153023          	sd	ra,0(a0)
    80002d86:	00253423          	sd	sp,8(a0)
    80002d8a:	e900                	sd	s0,16(a0)
    80002d8c:	ed04                	sd	s1,24(a0)
    80002d8e:	03253023          	sd	s2,32(a0)
    80002d92:	03353423          	sd	s3,40(a0)
    80002d96:	03453823          	sd	s4,48(a0)
    80002d9a:	03553c23          	sd	s5,56(a0)
    80002d9e:	05653023          	sd	s6,64(a0)
    80002da2:	05753423          	sd	s7,72(a0)
    80002da6:	05853823          	sd	s8,80(a0)
    80002daa:	05953c23          	sd	s9,88(a0)
    80002dae:	07a53023          	sd	s10,96(a0)
    80002db2:	07b53423          	sd	s11,104(a0)
    80002db6:	0005b083          	ld	ra,0(a1)
    80002dba:	0085b103          	ld	sp,8(a1)
    80002dbe:	6980                	ld	s0,16(a1)
    80002dc0:	6d84                	ld	s1,24(a1)
    80002dc2:	0205b903          	ld	s2,32(a1)
    80002dc6:	0285b983          	ld	s3,40(a1)
    80002dca:	0305ba03          	ld	s4,48(a1)
    80002dce:	0385ba83          	ld	s5,56(a1)
    80002dd2:	0405bb03          	ld	s6,64(a1)
    80002dd6:	0485bb83          	ld	s7,72(a1)
    80002dda:	0505bc03          	ld	s8,80(a1)
    80002dde:	0585bc83          	ld	s9,88(a1)
    80002de2:	0605bd03          	ld	s10,96(a1)
    80002de6:	0685bd83          	ld	s11,104(a1)
    80002dea:	8082                	ret

0000000080002dec <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002dec:	1141                	addi	sp,sp,-16
    80002dee:	e406                	sd	ra,8(sp)
    80002df0:	e022                	sd	s0,0(sp)
    80002df2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002df4:	00005597          	auipc	a1,0x5
    80002df8:	60458593          	addi	a1,a1,1540 # 800083f8 <states.1762+0x30>
    80002dfc:	0000d517          	auipc	a0,0xd
    80002e00:	6a450513          	addi	a0,a0,1700 # 800104a0 <tickslock>
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	d50080e7          	jalr	-688(ra) # 80000b54 <initlock>
}
    80002e0c:	60a2                	ld	ra,8(sp)
    80002e0e:	6402                	ld	s0,0(sp)
    80002e10:	0141                	addi	sp,sp,16
    80002e12:	8082                	ret

0000000080002e14 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e14:	1141                	addi	sp,sp,-16
    80002e16:	e422                	sd	s0,8(sp)
    80002e18:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e1a:	00003797          	auipc	a5,0x3
    80002e1e:	48678793          	addi	a5,a5,1158 # 800062a0 <kernelvec>
    80002e22:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e26:	6422                	ld	s0,8(sp)
    80002e28:	0141                	addi	sp,sp,16
    80002e2a:	8082                	ret

0000000080002e2c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e2c:	1141                	addi	sp,sp,-16
    80002e2e:	e406                	sd	ra,8(sp)
    80002e30:	e022                	sd	s0,0(sp)
    80002e32:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	fda080e7          	jalr	-38(ra) # 80001e0e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e40:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e42:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e46:	00004617          	auipc	a2,0x4
    80002e4a:	1ba60613          	addi	a2,a2,442 # 80007000 <_trampoline>
    80002e4e:	00004697          	auipc	a3,0x4
    80002e52:	1b268693          	addi	a3,a3,434 # 80007000 <_trampoline>
    80002e56:	8e91                	sub	a3,a3,a2
    80002e58:	040007b7          	lui	a5,0x4000
    80002e5c:	17fd                	addi	a5,a5,-1
    80002e5e:	07b2                	slli	a5,a5,0xc
    80002e60:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e62:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e66:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e68:	180026f3          	csrr	a3,satp
    80002e6c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e6e:	7d38                	ld	a4,120(a0)
    80002e70:	7134                	ld	a3,96(a0)
    80002e72:	6585                	lui	a1,0x1
    80002e74:	96ae                	add	a3,a3,a1
    80002e76:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e78:	7d38                	ld	a4,120(a0)
    80002e7a:	00000697          	auipc	a3,0x0
    80002e7e:	13868693          	addi	a3,a3,312 # 80002fb2 <usertrap>
    80002e82:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e84:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e86:	8692                	mv	a3,tp
    80002e88:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e8a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e8e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e92:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e96:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e9a:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e9c:	6f18                	ld	a4,24(a4)
    80002e9e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ea2:	792c                	ld	a1,112(a0)
    80002ea4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ea6:	00004717          	auipc	a4,0x4
    80002eaa:	1ea70713          	addi	a4,a4,490 # 80007090 <userret>
    80002eae:	8f11                	sub	a4,a4,a2
    80002eb0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002eb2:	577d                	li	a4,-1
    80002eb4:	177e                	slli	a4,a4,0x3f
    80002eb6:	8dd9                	or	a1,a1,a4
    80002eb8:	02000537          	lui	a0,0x2000
    80002ebc:	157d                	addi	a0,a0,-1
    80002ebe:	0536                	slli	a0,a0,0xd
    80002ec0:	9782                	jalr	a5
}
    80002ec2:	60a2                	ld	ra,8(sp)
    80002ec4:	6402                	ld	s0,0(sp)
    80002ec6:	0141                	addi	sp,sp,16
    80002ec8:	8082                	ret

0000000080002eca <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	e426                	sd	s1,8(sp)
    80002ed2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ed4:	0000d497          	auipc	s1,0xd
    80002ed8:	5cc48493          	addi	s1,s1,1484 # 800104a0 <tickslock>
    80002edc:	8526                	mv	a0,s1
    80002ede:	ffffe097          	auipc	ra,0xffffe
    80002ee2:	d06080e7          	jalr	-762(ra) # 80000be4 <acquire>
  ticks++;
    80002ee6:	00006517          	auipc	a0,0x6
    80002eea:	15250513          	addi	a0,a0,338 # 80009038 <ticks>
    80002eee:	411c                	lw	a5,0(a0)
    80002ef0:	2785                	addiw	a5,a5,1
    80002ef2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ef4:	00000097          	auipc	ra,0x0
    80002ef8:	9c6080e7          	jalr	-1594(ra) # 800028ba <wakeup>
  release(&tickslock);
    80002efc:	8526                	mv	a0,s1
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	dac080e7          	jalr	-596(ra) # 80000caa <release>
}
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	64a2                	ld	s1,8(sp)
    80002f0c:	6105                	addi	sp,sp,32
    80002f0e:	8082                	ret

0000000080002f10 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	e426                	sd	s1,8(sp)
    80002f18:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f1a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f1e:	00074d63          	bltz	a4,80002f38 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f22:	57fd                	li	a5,-1
    80002f24:	17fe                	slli	a5,a5,0x3f
    80002f26:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f28:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f2a:	06f70363          	beq	a4,a5,80002f90 <devintr+0x80>
  }
}
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	64a2                	ld	s1,8(sp)
    80002f34:	6105                	addi	sp,sp,32
    80002f36:	8082                	ret
     (scause & 0xff) == 9){
    80002f38:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f3c:	46a5                	li	a3,9
    80002f3e:	fed792e3          	bne	a5,a3,80002f22 <devintr+0x12>
    int irq = plic_claim();
    80002f42:	00003097          	auipc	ra,0x3
    80002f46:	466080e7          	jalr	1126(ra) # 800063a8 <plic_claim>
    80002f4a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f4c:	47a9                	li	a5,10
    80002f4e:	02f50763          	beq	a0,a5,80002f7c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f52:	4785                	li	a5,1
    80002f54:	02f50963          	beq	a0,a5,80002f86 <devintr+0x76>
    return 1;
    80002f58:	4505                	li	a0,1
    } else if(irq){
    80002f5a:	d8f1                	beqz	s1,80002f2e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f5c:	85a6                	mv	a1,s1
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	4a250513          	addi	a0,a0,1186 # 80008400 <states.1762+0x38>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	622080e7          	jalr	1570(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f6e:	8526                	mv	a0,s1
    80002f70:	00003097          	auipc	ra,0x3
    80002f74:	45c080e7          	jalr	1116(ra) # 800063cc <plic_complete>
    return 1;
    80002f78:	4505                	li	a0,1
    80002f7a:	bf55                	j	80002f2e <devintr+0x1e>
      uartintr();
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	a2c080e7          	jalr	-1492(ra) # 800009a8 <uartintr>
    80002f84:	b7ed                	j	80002f6e <devintr+0x5e>
      virtio_disk_intr();
    80002f86:	00004097          	auipc	ra,0x4
    80002f8a:	926080e7          	jalr	-1754(ra) # 800068ac <virtio_disk_intr>
    80002f8e:	b7c5                	j	80002f6e <devintr+0x5e>
    if(cpuid() == 0){
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	e52080e7          	jalr	-430(ra) # 80001de2 <cpuid>
    80002f98:	c901                	beqz	a0,80002fa8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f9a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f9e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002fa0:	14479073          	csrw	sip,a5
    return 2;
    80002fa4:	4509                	li	a0,2
    80002fa6:	b761                	j	80002f2e <devintr+0x1e>
      clockintr();
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	f22080e7          	jalr	-222(ra) # 80002eca <clockintr>
    80002fb0:	b7ed                	j	80002f9a <devintr+0x8a>

0000000080002fb2 <usertrap>:
{
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	e04a                	sd	s2,0(sp)
    80002fbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fbe:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002fc2:	1007f793          	andi	a5,a5,256
    80002fc6:	e3ad                	bnez	a5,80003028 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fc8:	00003797          	auipc	a5,0x3
    80002fcc:	2d878793          	addi	a5,a5,728 # 800062a0 <kernelvec>
    80002fd0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	e3a080e7          	jalr	-454(ra) # 80001e0e <myproc>
    80002fdc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002fde:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fe0:	14102773          	csrr	a4,sepc
    80002fe4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fe6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002fea:	47a1                	li	a5,8
    80002fec:	04f71c63          	bne	a4,a5,80003044 <usertrap+0x92>
    if(p->killed)
    80002ff0:	551c                	lw	a5,40(a0)
    80002ff2:	e3b9                	bnez	a5,80003038 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ff4:	7cb8                	ld	a4,120(s1)
    80002ff6:	6f1c                	ld	a5,24(a4)
    80002ff8:	0791                	addi	a5,a5,4
    80002ffa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ffc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003000:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003004:	10079073          	csrw	sstatus,a5
    syscall();
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	2e0080e7          	jalr	736(ra) # 800032e8 <syscall>
  if(p->killed)
    80003010:	549c                	lw	a5,40(s1)
    80003012:	ebc1                	bnez	a5,800030a2 <usertrap+0xf0>
  usertrapret();
    80003014:	00000097          	auipc	ra,0x0
    80003018:	e18080e7          	jalr	-488(ra) # 80002e2c <usertrapret>
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	64a2                	ld	s1,8(sp)
    80003022:	6902                	ld	s2,0(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret
    panic("usertrap: not from user mode");
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	3f850513          	addi	a0,a0,1016 # 80008420 <states.1762+0x58>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>
      exit(-1);
    80003038:	557d                	li	a0,-1
    8000303a:	00000097          	auipc	ra,0x0
    8000303e:	a16080e7          	jalr	-1514(ra) # 80002a50 <exit>
    80003042:	bf4d                	j	80002ff4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003044:	00000097          	auipc	ra,0x0
    80003048:	ecc080e7          	jalr	-308(ra) # 80002f10 <devintr>
    8000304c:	892a                	mv	s2,a0
    8000304e:	c501                	beqz	a0,80003056 <usertrap+0xa4>
  if(p->killed)
    80003050:	549c                	lw	a5,40(s1)
    80003052:	c3a1                	beqz	a5,80003092 <usertrap+0xe0>
    80003054:	a815                	j	80003088 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003056:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000305a:	5890                	lw	a2,48(s1)
    8000305c:	00005517          	auipc	a0,0x5
    80003060:	3e450513          	addi	a0,a0,996 # 80008440 <states.1762+0x78>
    80003064:	ffffd097          	auipc	ra,0xffffd
    80003068:	524080e7          	jalr	1316(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000306c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003070:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003074:	00005517          	auipc	a0,0x5
    80003078:	3fc50513          	addi	a0,a0,1020 # 80008470 <states.1762+0xa8>
    8000307c:	ffffd097          	auipc	ra,0xffffd
    80003080:	50c080e7          	jalr	1292(ra) # 80000588 <printf>
    p->killed = 1;
    80003084:	4785                	li	a5,1
    80003086:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003088:	557d                	li	a0,-1
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	9c6080e7          	jalr	-1594(ra) # 80002a50 <exit>
  if(which_dev == 2)
    80003092:	4789                	li	a5,2
    80003094:	f8f910e3          	bne	s2,a5,80003014 <usertrap+0x62>
    yield();
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	5e4080e7          	jalr	1508(ra) # 8000267c <yield>
    800030a0:	bf95                	j	80003014 <usertrap+0x62>
  int which_dev = 0;
    800030a2:	4901                	li	s2,0
    800030a4:	b7d5                	j	80003088 <usertrap+0xd6>

00000000800030a6 <kerneltrap>:
{
    800030a6:	7179                	addi	sp,sp,-48
    800030a8:	f406                	sd	ra,40(sp)
    800030aa:	f022                	sd	s0,32(sp)
    800030ac:	ec26                	sd	s1,24(sp)
    800030ae:	e84a                	sd	s2,16(sp)
    800030b0:	e44e                	sd	s3,8(sp)
    800030b2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030b4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030b8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030bc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800030c0:	1004f793          	andi	a5,s1,256
    800030c4:	cb85                	beqz	a5,800030f4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030ca:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800030cc:	ef85                	bnez	a5,80003104 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	e42080e7          	jalr	-446(ra) # 80002f10 <devintr>
    800030d6:	cd1d                	beqz	a0,80003114 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030d8:	4789                	li	a5,2
    800030da:	06f50a63          	beq	a0,a5,8000314e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030de:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030e2:	10049073          	csrw	sstatus,s1
}
    800030e6:	70a2                	ld	ra,40(sp)
    800030e8:	7402                	ld	s0,32(sp)
    800030ea:	64e2                	ld	s1,24(sp)
    800030ec:	6942                	ld	s2,16(sp)
    800030ee:	69a2                	ld	s3,8(sp)
    800030f0:	6145                	addi	sp,sp,48
    800030f2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030f4:	00005517          	auipc	a0,0x5
    800030f8:	39c50513          	addi	a0,a0,924 # 80008490 <states.1762+0xc8>
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003104:	00005517          	auipc	a0,0x5
    80003108:	3b450513          	addi	a0,a0,948 # 800084b8 <states.1762+0xf0>
    8000310c:	ffffd097          	auipc	ra,0xffffd
    80003110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003114:	85ce                	mv	a1,s3
    80003116:	00005517          	auipc	a0,0x5
    8000311a:	3c250513          	addi	a0,a0,962 # 800084d8 <states.1762+0x110>
    8000311e:	ffffd097          	auipc	ra,0xffffd
    80003122:	46a080e7          	jalr	1130(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003126:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000312a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000312e:	00005517          	auipc	a0,0x5
    80003132:	3ba50513          	addi	a0,a0,954 # 800084e8 <states.1762+0x120>
    80003136:	ffffd097          	auipc	ra,0xffffd
    8000313a:	452080e7          	jalr	1106(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000313e:	00005517          	auipc	a0,0x5
    80003142:	3c250513          	addi	a0,a0,962 # 80008500 <states.1762+0x138>
    80003146:	ffffd097          	auipc	ra,0xffffd
    8000314a:	3f8080e7          	jalr	1016(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	cc0080e7          	jalr	-832(ra) # 80001e0e <myproc>
    80003156:	d541                	beqz	a0,800030de <kerneltrap+0x38>
    80003158:	fffff097          	auipc	ra,0xfffff
    8000315c:	cb6080e7          	jalr	-842(ra) # 80001e0e <myproc>
    80003160:	4d18                	lw	a4,24(a0)
    80003162:	4791                	li	a5,4
    80003164:	f6f71de3          	bne	a4,a5,800030de <kerneltrap+0x38>
    yield();
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	514080e7          	jalr	1300(ra) # 8000267c <yield>
    80003170:	b7bd                	j	800030de <kerneltrap+0x38>

0000000080003172 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003172:	1101                	addi	sp,sp,-32
    80003174:	ec06                	sd	ra,24(sp)
    80003176:	e822                	sd	s0,16(sp)
    80003178:	e426                	sd	s1,8(sp)
    8000317a:	1000                	addi	s0,sp,32
    8000317c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	c90080e7          	jalr	-880(ra) # 80001e0e <myproc>
  switch (n) {
    80003186:	4795                	li	a5,5
    80003188:	0497e163          	bltu	a5,s1,800031ca <argraw+0x58>
    8000318c:	048a                	slli	s1,s1,0x2
    8000318e:	00005717          	auipc	a4,0x5
    80003192:	3aa70713          	addi	a4,a4,938 # 80008538 <states.1762+0x170>
    80003196:	94ba                	add	s1,s1,a4
    80003198:	409c                	lw	a5,0(s1)
    8000319a:	97ba                	add	a5,a5,a4
    8000319c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000319e:	7d3c                	ld	a5,120(a0)
    800031a0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret
    return p->trapframe->a1;
    800031ac:	7d3c                	ld	a5,120(a0)
    800031ae:	7fa8                	ld	a0,120(a5)
    800031b0:	bfcd                	j	800031a2 <argraw+0x30>
    return p->trapframe->a2;
    800031b2:	7d3c                	ld	a5,120(a0)
    800031b4:	63c8                	ld	a0,128(a5)
    800031b6:	b7f5                	j	800031a2 <argraw+0x30>
    return p->trapframe->a3;
    800031b8:	7d3c                	ld	a5,120(a0)
    800031ba:	67c8                	ld	a0,136(a5)
    800031bc:	b7dd                	j	800031a2 <argraw+0x30>
    return p->trapframe->a4;
    800031be:	7d3c                	ld	a5,120(a0)
    800031c0:	6bc8                	ld	a0,144(a5)
    800031c2:	b7c5                	j	800031a2 <argraw+0x30>
    return p->trapframe->a5;
    800031c4:	7d3c                	ld	a5,120(a0)
    800031c6:	6fc8                	ld	a0,152(a5)
    800031c8:	bfe9                	j	800031a2 <argraw+0x30>
  panic("argraw");
    800031ca:	00005517          	auipc	a0,0x5
    800031ce:	34650513          	addi	a0,a0,838 # 80008510 <states.1762+0x148>
    800031d2:	ffffd097          	auipc	ra,0xffffd
    800031d6:	36c080e7          	jalr	876(ra) # 8000053e <panic>

00000000800031da <fetchaddr>:
{
    800031da:	1101                	addi	sp,sp,-32
    800031dc:	ec06                	sd	ra,24(sp)
    800031de:	e822                	sd	s0,16(sp)
    800031e0:	e426                	sd	s1,8(sp)
    800031e2:	e04a                	sd	s2,0(sp)
    800031e4:	1000                	addi	s0,sp,32
    800031e6:	84aa                	mv	s1,a0
    800031e8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031ea:	fffff097          	auipc	ra,0xfffff
    800031ee:	c24080e7          	jalr	-988(ra) # 80001e0e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031f2:	753c                	ld	a5,104(a0)
    800031f4:	02f4f863          	bgeu	s1,a5,80003224 <fetchaddr+0x4a>
    800031f8:	00848713          	addi	a4,s1,8
    800031fc:	02e7e663          	bltu	a5,a4,80003228 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003200:	46a1                	li	a3,8
    80003202:	8626                	mv	a2,s1
    80003204:	85ca                	mv	a1,s2
    80003206:	7928                	ld	a0,112(a0)
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	51a080e7          	jalr	1306(ra) # 80001722 <copyin>
    80003210:	00a03533          	snez	a0,a0
    80003214:	40a00533          	neg	a0,a0
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6902                	ld	s2,0(sp)
    80003220:	6105                	addi	sp,sp,32
    80003222:	8082                	ret
    return -1;
    80003224:	557d                	li	a0,-1
    80003226:	bfcd                	j	80003218 <fetchaddr+0x3e>
    80003228:	557d                	li	a0,-1
    8000322a:	b7fd                	j	80003218 <fetchaddr+0x3e>

000000008000322c <fetchstr>:
{
    8000322c:	7179                	addi	sp,sp,-48
    8000322e:	f406                	sd	ra,40(sp)
    80003230:	f022                	sd	s0,32(sp)
    80003232:	ec26                	sd	s1,24(sp)
    80003234:	e84a                	sd	s2,16(sp)
    80003236:	e44e                	sd	s3,8(sp)
    80003238:	1800                	addi	s0,sp,48
    8000323a:	892a                	mv	s2,a0
    8000323c:	84ae                	mv	s1,a1
    8000323e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003240:	fffff097          	auipc	ra,0xfffff
    80003244:	bce080e7          	jalr	-1074(ra) # 80001e0e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003248:	86ce                	mv	a3,s3
    8000324a:	864a                	mv	a2,s2
    8000324c:	85a6                	mv	a1,s1
    8000324e:	7928                	ld	a0,112(a0)
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	55e080e7          	jalr	1374(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003258:	00054763          	bltz	a0,80003266 <fetchstr+0x3a>
  return strlen(buf);
    8000325c:	8526                	mv	a0,s1
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	c2a080e7          	jalr	-982(ra) # 80000e88 <strlen>
}
    80003266:	70a2                	ld	ra,40(sp)
    80003268:	7402                	ld	s0,32(sp)
    8000326a:	64e2                	ld	s1,24(sp)
    8000326c:	6942                	ld	s2,16(sp)
    8000326e:	69a2                	ld	s3,8(sp)
    80003270:	6145                	addi	sp,sp,48
    80003272:	8082                	ret

0000000080003274 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003274:	1101                	addi	sp,sp,-32
    80003276:	ec06                	sd	ra,24(sp)
    80003278:	e822                	sd	s0,16(sp)
    8000327a:	e426                	sd	s1,8(sp)
    8000327c:	1000                	addi	s0,sp,32
    8000327e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003280:	00000097          	auipc	ra,0x0
    80003284:	ef2080e7          	jalr	-270(ra) # 80003172 <argraw>
    80003288:	c088                	sw	a0,0(s1)
  return 0;
}
    8000328a:	4501                	li	a0,0
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret

0000000080003296 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003296:	1101                	addi	sp,sp,-32
    80003298:	ec06                	sd	ra,24(sp)
    8000329a:	e822                	sd	s0,16(sp)
    8000329c:	e426                	sd	s1,8(sp)
    8000329e:	1000                	addi	s0,sp,32
    800032a0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	ed0080e7          	jalr	-304(ra) # 80003172 <argraw>
    800032aa:	e088                	sd	a0,0(s1)
  return 0;
}
    800032ac:	4501                	li	a0,0
    800032ae:	60e2                	ld	ra,24(sp)
    800032b0:	6442                	ld	s0,16(sp)
    800032b2:	64a2                	ld	s1,8(sp)
    800032b4:	6105                	addi	sp,sp,32
    800032b6:	8082                	ret

00000000800032b8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	e04a                	sd	s2,0(sp)
    800032c2:	1000                	addi	s0,sp,32
    800032c4:	84ae                	mv	s1,a1
    800032c6:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032c8:	00000097          	auipc	ra,0x0
    800032cc:	eaa080e7          	jalr	-342(ra) # 80003172 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032d0:	864a                	mv	a2,s2
    800032d2:	85a6                	mv	a1,s1
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	f58080e7          	jalr	-168(ra) # 8000322c <fetchstr>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6902                	ld	s2,0(sp)
    800032e4:	6105                	addi	sp,sp,32
    800032e6:	8082                	ret

00000000800032e8 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800032e8:	1101                	addi	sp,sp,-32
    800032ea:	ec06                	sd	ra,24(sp)
    800032ec:	e822                	sd	s0,16(sp)
    800032ee:	e426                	sd	s1,8(sp)
    800032f0:	e04a                	sd	s2,0(sp)
    800032f2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032f4:	fffff097          	auipc	ra,0xfffff
    800032f8:	b1a080e7          	jalr	-1254(ra) # 80001e0e <myproc>
    800032fc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032fe:	07853903          	ld	s2,120(a0)
    80003302:	0a893783          	ld	a5,168(s2)
    80003306:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000330a:	37fd                	addiw	a5,a5,-1
    8000330c:	4751                	li	a4,20
    8000330e:	00f76f63          	bltu	a4,a5,8000332c <syscall+0x44>
    80003312:	00369713          	slli	a4,a3,0x3
    80003316:	00005797          	auipc	a5,0x5
    8000331a:	23a78793          	addi	a5,a5,570 # 80008550 <syscalls>
    8000331e:	97ba                	add	a5,a5,a4
    80003320:	639c                	ld	a5,0(a5)
    80003322:	c789                	beqz	a5,8000332c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003324:	9782                	jalr	a5
    80003326:	06a93823          	sd	a0,112(s2)
    8000332a:	a839                	j	80003348 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000332c:	17848613          	addi	a2,s1,376
    80003330:	588c                	lw	a1,48(s1)
    80003332:	00005517          	auipc	a0,0x5
    80003336:	1e650513          	addi	a0,a0,486 # 80008518 <states.1762+0x150>
    8000333a:	ffffd097          	auipc	ra,0xffffd
    8000333e:	24e080e7          	jalr	590(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003342:	7cbc                	ld	a5,120(s1)
    80003344:	577d                	li	a4,-1
    80003346:	fbb8                	sd	a4,112(a5)
  }
}
    80003348:	60e2                	ld	ra,24(sp)
    8000334a:	6442                	ld	s0,16(sp)
    8000334c:	64a2                	ld	s1,8(sp)
    8000334e:	6902                	ld	s2,0(sp)
    80003350:	6105                	addi	sp,sp,32
    80003352:	8082                	ret

0000000080003354 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003354:	1101                	addi	sp,sp,-32
    80003356:	ec06                	sd	ra,24(sp)
    80003358:	e822                	sd	s0,16(sp)
    8000335a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000335c:	fec40593          	addi	a1,s0,-20
    80003360:	4501                	li	a0,0
    80003362:	00000097          	auipc	ra,0x0
    80003366:	f12080e7          	jalr	-238(ra) # 80003274 <argint>
    return -1;
    8000336a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000336c:	00054963          	bltz	a0,8000337e <sys_exit+0x2a>
  exit(n);
    80003370:	fec42503          	lw	a0,-20(s0)
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	6dc080e7          	jalr	1756(ra) # 80002a50 <exit>
  return 0;  // not reached
    8000337c:	4781                	li	a5,0
}
    8000337e:	853e                	mv	a0,a5
    80003380:	60e2                	ld	ra,24(sp)
    80003382:	6442                	ld	s0,16(sp)
    80003384:	6105                	addi	sp,sp,32
    80003386:	8082                	ret

0000000080003388 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003388:	1141                	addi	sp,sp,-16
    8000338a:	e406                	sd	ra,8(sp)
    8000338c:	e022                	sd	s0,0(sp)
    8000338e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003390:	fffff097          	auipc	ra,0xfffff
    80003394:	a7e080e7          	jalr	-1410(ra) # 80001e0e <myproc>
}
    80003398:	5908                	lw	a0,48(a0)
    8000339a:	60a2                	ld	ra,8(sp)
    8000339c:	6402                	ld	s0,0(sp)
    8000339e:	0141                	addi	sp,sp,16
    800033a0:	8082                	ret

00000000800033a2 <sys_fork>:

uint64
sys_fork(void)
{
    800033a2:	1141                	addi	sp,sp,-16
    800033a4:	e406                	sd	ra,8(sp)
    800033a6:	e022                	sd	s0,0(sp)
    800033a8:	0800                	addi	s0,sp,16
  return fork();
    800033aa:	fffff097          	auipc	ra,0xfffff
    800033ae:	f1c080e7          	jalr	-228(ra) # 800022c6 <fork>
}
    800033b2:	60a2                	ld	ra,8(sp)
    800033b4:	6402                	ld	s0,0(sp)
    800033b6:	0141                	addi	sp,sp,16
    800033b8:	8082                	ret

00000000800033ba <sys_wait>:

uint64
sys_wait(void)
{
    800033ba:	1101                	addi	sp,sp,-32
    800033bc:	ec06                	sd	ra,24(sp)
    800033be:	e822                	sd	s0,16(sp)
    800033c0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033c2:	fe840593          	addi	a1,s0,-24
    800033c6:	4501                	li	a0,0
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	ece080e7          	jalr	-306(ra) # 80003296 <argaddr>
    800033d0:	87aa                	mv	a5,a0
    return -1;
    800033d2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033d4:	0007c863          	bltz	a5,800033e4 <sys_wait+0x2a>
  return wait(p);
    800033d8:	fe843503          	ld	a0,-24(s0)
    800033dc:	fffff097          	auipc	ra,0xfffff
    800033e0:	3b6080e7          	jalr	950(ra) # 80002792 <wait>
}
    800033e4:	60e2                	ld	ra,24(sp)
    800033e6:	6442                	ld	s0,16(sp)
    800033e8:	6105                	addi	sp,sp,32
    800033ea:	8082                	ret

00000000800033ec <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033ec:	7179                	addi	sp,sp,-48
    800033ee:	f406                	sd	ra,40(sp)
    800033f0:	f022                	sd	s0,32(sp)
    800033f2:	ec26                	sd	s1,24(sp)
    800033f4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800033f6:	fdc40593          	addi	a1,s0,-36
    800033fa:	4501                	li	a0,0
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	e78080e7          	jalr	-392(ra) # 80003274 <argint>
    80003404:	87aa                	mv	a5,a0
    return -1;
    80003406:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003408:	0207c063          	bltz	a5,80003428 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000340c:	fffff097          	auipc	ra,0xfffff
    80003410:	a02080e7          	jalr	-1534(ra) # 80001e0e <myproc>
    80003414:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003416:	fdc42503          	lw	a0,-36(s0)
    8000341a:	fffff097          	auipc	ra,0xfffff
    8000341e:	e38080e7          	jalr	-456(ra) # 80002252 <growproc>
    80003422:	00054863          	bltz	a0,80003432 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003426:	8526                	mv	a0,s1
}
    80003428:	70a2                	ld	ra,40(sp)
    8000342a:	7402                	ld	s0,32(sp)
    8000342c:	64e2                	ld	s1,24(sp)
    8000342e:	6145                	addi	sp,sp,48
    80003430:	8082                	ret
    return -1;
    80003432:	557d                	li	a0,-1
    80003434:	bfd5                	j	80003428 <sys_sbrk+0x3c>

0000000080003436 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003436:	7139                	addi	sp,sp,-64
    80003438:	fc06                	sd	ra,56(sp)
    8000343a:	f822                	sd	s0,48(sp)
    8000343c:	f426                	sd	s1,40(sp)
    8000343e:	f04a                	sd	s2,32(sp)
    80003440:	ec4e                	sd	s3,24(sp)
    80003442:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003444:	fcc40593          	addi	a1,s0,-52
    80003448:	4501                	li	a0,0
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	e2a080e7          	jalr	-470(ra) # 80003274 <argint>
    return -1;
    80003452:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003454:	06054563          	bltz	a0,800034be <sys_sleep+0x88>
  acquire(&tickslock);
    80003458:	0000d517          	auipc	a0,0xd
    8000345c:	04850513          	addi	a0,a0,72 # 800104a0 <tickslock>
    80003460:	ffffd097          	auipc	ra,0xffffd
    80003464:	784080e7          	jalr	1924(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003468:	00006917          	auipc	s2,0x6
    8000346c:	bd092903          	lw	s2,-1072(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80003470:	fcc42783          	lw	a5,-52(s0)
    80003474:	cf85                	beqz	a5,800034ac <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003476:	0000d997          	auipc	s3,0xd
    8000347a:	02a98993          	addi	s3,s3,42 # 800104a0 <tickslock>
    8000347e:	00006497          	auipc	s1,0x6
    80003482:	bba48493          	addi	s1,s1,-1094 # 80009038 <ticks>
    if(myproc()->killed){
    80003486:	fffff097          	auipc	ra,0xfffff
    8000348a:	988080e7          	jalr	-1656(ra) # 80001e0e <myproc>
    8000348e:	551c                	lw	a5,40(a0)
    80003490:	ef9d                	bnez	a5,800034ce <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003492:	85ce                	mv	a1,s3
    80003494:	8526                	mv	a0,s1
    80003496:	fffff097          	auipc	ra,0xfffff
    8000349a:	268080e7          	jalr	616(ra) # 800026fe <sleep>
  while(ticks - ticks0 < n){
    8000349e:	409c                	lw	a5,0(s1)
    800034a0:	412787bb          	subw	a5,a5,s2
    800034a4:	fcc42703          	lw	a4,-52(s0)
    800034a8:	fce7efe3          	bltu	a5,a4,80003486 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034ac:	0000d517          	auipc	a0,0xd
    800034b0:	ff450513          	addi	a0,a0,-12 # 800104a0 <tickslock>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	7f6080e7          	jalr	2038(ra) # 80000caa <release>
  return 0;
    800034bc:	4781                	li	a5,0
}
    800034be:	853e                	mv	a0,a5
    800034c0:	70e2                	ld	ra,56(sp)
    800034c2:	7442                	ld	s0,48(sp)
    800034c4:	74a2                	ld	s1,40(sp)
    800034c6:	7902                	ld	s2,32(sp)
    800034c8:	69e2                	ld	s3,24(sp)
    800034ca:	6121                	addi	sp,sp,64
    800034cc:	8082                	ret
      release(&tickslock);
    800034ce:	0000d517          	auipc	a0,0xd
    800034d2:	fd250513          	addi	a0,a0,-46 # 800104a0 <tickslock>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7d4080e7          	jalr	2004(ra) # 80000caa <release>
      return -1;
    800034de:	57fd                	li	a5,-1
    800034e0:	bff9                	j	800034be <sys_sleep+0x88>

00000000800034e2 <sys_kill>:

uint64
sys_kill(void)
{
    800034e2:	1101                	addi	sp,sp,-32
    800034e4:	ec06                	sd	ra,24(sp)
    800034e6:	e822                	sd	s0,16(sp)
    800034e8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800034ea:	fec40593          	addi	a1,s0,-20
    800034ee:	4501                	li	a0,0
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	d84080e7          	jalr	-636(ra) # 80003274 <argint>
    800034f8:	87aa                	mv	a5,a0
    return -1;
    800034fa:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800034fc:	0007c863          	bltz	a5,8000350c <sys_kill+0x2a>
  return kill(pid);
    80003500:	fec42503          	lw	a0,-20(s0)
    80003504:	fffff097          	auipc	ra,0xfffff
    80003508:	654080e7          	jalr	1620(ra) # 80002b58 <kill>
}
    8000350c:	60e2                	ld	ra,24(sp)
    8000350e:	6442                	ld	s0,16(sp)
    80003510:	6105                	addi	sp,sp,32
    80003512:	8082                	ret

0000000080003514 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003514:	1101                	addi	sp,sp,-32
    80003516:	ec06                	sd	ra,24(sp)
    80003518:	e822                	sd	s0,16(sp)
    8000351a:	e426                	sd	s1,8(sp)
    8000351c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000351e:	0000d517          	auipc	a0,0xd
    80003522:	f8250513          	addi	a0,a0,-126 # 800104a0 <tickslock>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	6be080e7          	jalr	1726(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000352e:	00006497          	auipc	s1,0x6
    80003532:	b0a4a483          	lw	s1,-1270(s1) # 80009038 <ticks>
  release(&tickslock);
    80003536:	0000d517          	auipc	a0,0xd
    8000353a:	f6a50513          	addi	a0,a0,-150 # 800104a0 <tickslock>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	76c080e7          	jalr	1900(ra) # 80000caa <release>
  return xticks;
}
    80003546:	02049513          	slli	a0,s1,0x20
    8000354a:	9101                	srli	a0,a0,0x20
    8000354c:	60e2                	ld	ra,24(sp)
    8000354e:	6442                	ld	s0,16(sp)
    80003550:	64a2                	ld	s1,8(sp)
    80003552:	6105                	addi	sp,sp,32
    80003554:	8082                	ret

0000000080003556 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003556:	7179                	addi	sp,sp,-48
    80003558:	f406                	sd	ra,40(sp)
    8000355a:	f022                	sd	s0,32(sp)
    8000355c:	ec26                	sd	s1,24(sp)
    8000355e:	e84a                	sd	s2,16(sp)
    80003560:	e44e                	sd	s3,8(sp)
    80003562:	e052                	sd	s4,0(sp)
    80003564:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003566:	00005597          	auipc	a1,0x5
    8000356a:	09a58593          	addi	a1,a1,154 # 80008600 <syscalls+0xb0>
    8000356e:	0000d517          	auipc	a0,0xd
    80003572:	f4a50513          	addi	a0,a0,-182 # 800104b8 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	5de080e7          	jalr	1502(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000357e:	00015797          	auipc	a5,0x15
    80003582:	f3a78793          	addi	a5,a5,-198 # 800184b8 <bcache+0x8000>
    80003586:	00015717          	auipc	a4,0x15
    8000358a:	19a70713          	addi	a4,a4,410 # 80018720 <bcache+0x8268>
    8000358e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003592:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003596:	0000d497          	auipc	s1,0xd
    8000359a:	f3a48493          	addi	s1,s1,-198 # 800104d0 <bcache+0x18>
    b->next = bcache.head.next;
    8000359e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035a0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035a2:	00005a17          	auipc	s4,0x5
    800035a6:	066a0a13          	addi	s4,s4,102 # 80008608 <syscalls+0xb8>
    b->next = bcache.head.next;
    800035aa:	2b893783          	ld	a5,696(s2)
    800035ae:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035b0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035b4:	85d2                	mv	a1,s4
    800035b6:	01048513          	addi	a0,s1,16
    800035ba:	00001097          	auipc	ra,0x1
    800035be:	4bc080e7          	jalr	1212(ra) # 80004a76 <initsleeplock>
    bcache.head.next->prev = b;
    800035c2:	2b893783          	ld	a5,696(s2)
    800035c6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035c8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035cc:	45848493          	addi	s1,s1,1112
    800035d0:	fd349de3          	bne	s1,s3,800035aa <binit+0x54>
  }
}
    800035d4:	70a2                	ld	ra,40(sp)
    800035d6:	7402                	ld	s0,32(sp)
    800035d8:	64e2                	ld	s1,24(sp)
    800035da:	6942                	ld	s2,16(sp)
    800035dc:	69a2                	ld	s3,8(sp)
    800035de:	6a02                	ld	s4,0(sp)
    800035e0:	6145                	addi	sp,sp,48
    800035e2:	8082                	ret

00000000800035e4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035e4:	7179                	addi	sp,sp,-48
    800035e6:	f406                	sd	ra,40(sp)
    800035e8:	f022                	sd	s0,32(sp)
    800035ea:	ec26                	sd	s1,24(sp)
    800035ec:	e84a                	sd	s2,16(sp)
    800035ee:	e44e                	sd	s3,8(sp)
    800035f0:	1800                	addi	s0,sp,48
    800035f2:	89aa                	mv	s3,a0
    800035f4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035f6:	0000d517          	auipc	a0,0xd
    800035fa:	ec250513          	addi	a0,a0,-318 # 800104b8 <bcache>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	5e6080e7          	jalr	1510(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003606:	00015497          	auipc	s1,0x15
    8000360a:	16a4b483          	ld	s1,362(s1) # 80018770 <bcache+0x82b8>
    8000360e:	00015797          	auipc	a5,0x15
    80003612:	11278793          	addi	a5,a5,274 # 80018720 <bcache+0x8268>
    80003616:	02f48f63          	beq	s1,a5,80003654 <bread+0x70>
    8000361a:	873e                	mv	a4,a5
    8000361c:	a021                	j	80003624 <bread+0x40>
    8000361e:	68a4                	ld	s1,80(s1)
    80003620:	02e48a63          	beq	s1,a4,80003654 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003624:	449c                	lw	a5,8(s1)
    80003626:	ff379ce3          	bne	a5,s3,8000361e <bread+0x3a>
    8000362a:	44dc                	lw	a5,12(s1)
    8000362c:	ff2799e3          	bne	a5,s2,8000361e <bread+0x3a>
      b->refcnt++;
    80003630:	40bc                	lw	a5,64(s1)
    80003632:	2785                	addiw	a5,a5,1
    80003634:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003636:	0000d517          	auipc	a0,0xd
    8000363a:	e8250513          	addi	a0,a0,-382 # 800104b8 <bcache>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	66c080e7          	jalr	1644(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    80003646:	01048513          	addi	a0,s1,16
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	466080e7          	jalr	1126(ra) # 80004ab0 <acquiresleep>
      return b;
    80003652:	a8b9                	j	800036b0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003654:	00015497          	auipc	s1,0x15
    80003658:	1144b483          	ld	s1,276(s1) # 80018768 <bcache+0x82b0>
    8000365c:	00015797          	auipc	a5,0x15
    80003660:	0c478793          	addi	a5,a5,196 # 80018720 <bcache+0x8268>
    80003664:	00f48863          	beq	s1,a5,80003674 <bread+0x90>
    80003668:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000366a:	40bc                	lw	a5,64(s1)
    8000366c:	cf81                	beqz	a5,80003684 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000366e:	64a4                	ld	s1,72(s1)
    80003670:	fee49de3          	bne	s1,a4,8000366a <bread+0x86>
  panic("bget: no buffers");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	f9c50513          	addi	a0,a0,-100 # 80008610 <syscalls+0xc0>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>
      b->dev = dev;
    80003684:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003688:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000368c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003690:	4785                	li	a5,1
    80003692:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003694:	0000d517          	auipc	a0,0xd
    80003698:	e2450513          	addi	a0,a0,-476 # 800104b8 <bcache>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	60e080e7          	jalr	1550(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    800036a4:	01048513          	addi	a0,s1,16
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	408080e7          	jalr	1032(ra) # 80004ab0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036b0:	409c                	lw	a5,0(s1)
    800036b2:	cb89                	beqz	a5,800036c4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036b4:	8526                	mv	a0,s1
    800036b6:	70a2                	ld	ra,40(sp)
    800036b8:	7402                	ld	s0,32(sp)
    800036ba:	64e2                	ld	s1,24(sp)
    800036bc:	6942                	ld	s2,16(sp)
    800036be:	69a2                	ld	s3,8(sp)
    800036c0:	6145                	addi	sp,sp,48
    800036c2:	8082                	ret
    virtio_disk_rw(b, 0);
    800036c4:	4581                	li	a1,0
    800036c6:	8526                	mv	a0,s1
    800036c8:	00003097          	auipc	ra,0x3
    800036cc:	f0e080e7          	jalr	-242(ra) # 800065d6 <virtio_disk_rw>
    b->valid = 1;
    800036d0:	4785                	li	a5,1
    800036d2:	c09c                	sw	a5,0(s1)
  return b;
    800036d4:	b7c5                	j	800036b4 <bread+0xd0>

00000000800036d6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036d6:	1101                	addi	sp,sp,-32
    800036d8:	ec06                	sd	ra,24(sp)
    800036da:	e822                	sd	s0,16(sp)
    800036dc:	e426                	sd	s1,8(sp)
    800036de:	1000                	addi	s0,sp,32
    800036e0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036e2:	0541                	addi	a0,a0,16
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	466080e7          	jalr	1126(ra) # 80004b4a <holdingsleep>
    800036ec:	cd01                	beqz	a0,80003704 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036ee:	4585                	li	a1,1
    800036f0:	8526                	mv	a0,s1
    800036f2:	00003097          	auipc	ra,0x3
    800036f6:	ee4080e7          	jalr	-284(ra) # 800065d6 <virtio_disk_rw>
}
    800036fa:	60e2                	ld	ra,24(sp)
    800036fc:	6442                	ld	s0,16(sp)
    800036fe:	64a2                	ld	s1,8(sp)
    80003700:	6105                	addi	sp,sp,32
    80003702:	8082                	ret
    panic("bwrite");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	f2450513          	addi	a0,a0,-220 # 80008628 <syscalls+0xd8>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e32080e7          	jalr	-462(ra) # 8000053e <panic>

0000000080003714 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	e426                	sd	s1,8(sp)
    8000371c:	e04a                	sd	s2,0(sp)
    8000371e:	1000                	addi	s0,sp,32
    80003720:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003722:	01050913          	addi	s2,a0,16
    80003726:	854a                	mv	a0,s2
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	422080e7          	jalr	1058(ra) # 80004b4a <holdingsleep>
    80003730:	c92d                	beqz	a0,800037a2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003732:	854a                	mv	a0,s2
    80003734:	00001097          	auipc	ra,0x1
    80003738:	3d2080e7          	jalr	978(ra) # 80004b06 <releasesleep>

  acquire(&bcache.lock);
    8000373c:	0000d517          	auipc	a0,0xd
    80003740:	d7c50513          	addi	a0,a0,-644 # 800104b8 <bcache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	4a0080e7          	jalr	1184(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000374c:	40bc                	lw	a5,64(s1)
    8000374e:	37fd                	addiw	a5,a5,-1
    80003750:	0007871b          	sext.w	a4,a5
    80003754:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003756:	eb05                	bnez	a4,80003786 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003758:	68bc                	ld	a5,80(s1)
    8000375a:	64b8                	ld	a4,72(s1)
    8000375c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000375e:	64bc                	ld	a5,72(s1)
    80003760:	68b8                	ld	a4,80(s1)
    80003762:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003764:	00015797          	auipc	a5,0x15
    80003768:	d5478793          	addi	a5,a5,-684 # 800184b8 <bcache+0x8000>
    8000376c:	2b87b703          	ld	a4,696(a5)
    80003770:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003772:	00015717          	auipc	a4,0x15
    80003776:	fae70713          	addi	a4,a4,-82 # 80018720 <bcache+0x8268>
    8000377a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000377c:	2b87b703          	ld	a4,696(a5)
    80003780:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003782:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003786:	0000d517          	auipc	a0,0xd
    8000378a:	d3250513          	addi	a0,a0,-718 # 800104b8 <bcache>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	51c080e7          	jalr	1308(ra) # 80000caa <release>
}
    80003796:	60e2                	ld	ra,24(sp)
    80003798:	6442                	ld	s0,16(sp)
    8000379a:	64a2                	ld	s1,8(sp)
    8000379c:	6902                	ld	s2,0(sp)
    8000379e:	6105                	addi	sp,sp,32
    800037a0:	8082                	ret
    panic("brelse");
    800037a2:	00005517          	auipc	a0,0x5
    800037a6:	e8e50513          	addi	a0,a0,-370 # 80008630 <syscalls+0xe0>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	d94080e7          	jalr	-620(ra) # 8000053e <panic>

00000000800037b2 <bpin>:

void
bpin(struct buf *b) {
    800037b2:	1101                	addi	sp,sp,-32
    800037b4:	ec06                	sd	ra,24(sp)
    800037b6:	e822                	sd	s0,16(sp)
    800037b8:	e426                	sd	s1,8(sp)
    800037ba:	1000                	addi	s0,sp,32
    800037bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037be:	0000d517          	auipc	a0,0xd
    800037c2:	cfa50513          	addi	a0,a0,-774 # 800104b8 <bcache>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	41e080e7          	jalr	1054(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037ce:	40bc                	lw	a5,64(s1)
    800037d0:	2785                	addiw	a5,a5,1
    800037d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037d4:	0000d517          	auipc	a0,0xd
    800037d8:	ce450513          	addi	a0,a0,-796 # 800104b8 <bcache>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	4ce080e7          	jalr	1230(ra) # 80000caa <release>
}
    800037e4:	60e2                	ld	ra,24(sp)
    800037e6:	6442                	ld	s0,16(sp)
    800037e8:	64a2                	ld	s1,8(sp)
    800037ea:	6105                	addi	sp,sp,32
    800037ec:	8082                	ret

00000000800037ee <bunpin>:

void
bunpin(struct buf *b) {
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	1000                	addi	s0,sp,32
    800037f8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037fa:	0000d517          	auipc	a0,0xd
    800037fe:	cbe50513          	addi	a0,a0,-834 # 800104b8 <bcache>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	3e2080e7          	jalr	994(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000380a:	40bc                	lw	a5,64(s1)
    8000380c:	37fd                	addiw	a5,a5,-1
    8000380e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003810:	0000d517          	auipc	a0,0xd
    80003814:	ca850513          	addi	a0,a0,-856 # 800104b8 <bcache>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	492080e7          	jalr	1170(ra) # 80000caa <release>
}
    80003820:	60e2                	ld	ra,24(sp)
    80003822:	6442                	ld	s0,16(sp)
    80003824:	64a2                	ld	s1,8(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret

000000008000382a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	e426                	sd	s1,8(sp)
    80003832:	e04a                	sd	s2,0(sp)
    80003834:	1000                	addi	s0,sp,32
    80003836:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003838:	00d5d59b          	srliw	a1,a1,0xd
    8000383c:	00015797          	auipc	a5,0x15
    80003840:	3587a783          	lw	a5,856(a5) # 80018b94 <sb+0x1c>
    80003844:	9dbd                	addw	a1,a1,a5
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	d9e080e7          	jalr	-610(ra) # 800035e4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000384e:	0074f713          	andi	a4,s1,7
    80003852:	4785                	li	a5,1
    80003854:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003858:	14ce                	slli	s1,s1,0x33
    8000385a:	90d9                	srli	s1,s1,0x36
    8000385c:	00950733          	add	a4,a0,s1
    80003860:	05874703          	lbu	a4,88(a4)
    80003864:	00e7f6b3          	and	a3,a5,a4
    80003868:	c69d                	beqz	a3,80003896 <bfree+0x6c>
    8000386a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000386c:	94aa                	add	s1,s1,a0
    8000386e:	fff7c793          	not	a5,a5
    80003872:	8ff9                	and	a5,a5,a4
    80003874:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003878:	00001097          	auipc	ra,0x1
    8000387c:	118080e7          	jalr	280(ra) # 80004990 <log_write>
  brelse(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00000097          	auipc	ra,0x0
    80003886:	e92080e7          	jalr	-366(ra) # 80003714 <brelse>
}
    8000388a:	60e2                	ld	ra,24(sp)
    8000388c:	6442                	ld	s0,16(sp)
    8000388e:	64a2                	ld	s1,8(sp)
    80003890:	6902                	ld	s2,0(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret
    panic("freeing free block");
    80003896:	00005517          	auipc	a0,0x5
    8000389a:	da250513          	addi	a0,a0,-606 # 80008638 <syscalls+0xe8>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	ca0080e7          	jalr	-864(ra) # 8000053e <panic>

00000000800038a6 <balloc>:
{
    800038a6:	711d                	addi	sp,sp,-96
    800038a8:	ec86                	sd	ra,88(sp)
    800038aa:	e8a2                	sd	s0,80(sp)
    800038ac:	e4a6                	sd	s1,72(sp)
    800038ae:	e0ca                	sd	s2,64(sp)
    800038b0:	fc4e                	sd	s3,56(sp)
    800038b2:	f852                	sd	s4,48(sp)
    800038b4:	f456                	sd	s5,40(sp)
    800038b6:	f05a                	sd	s6,32(sp)
    800038b8:	ec5e                	sd	s7,24(sp)
    800038ba:	e862                	sd	s8,16(sp)
    800038bc:	e466                	sd	s9,8(sp)
    800038be:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038c0:	00015797          	auipc	a5,0x15
    800038c4:	2bc7a783          	lw	a5,700(a5) # 80018b7c <sb+0x4>
    800038c8:	cbd1                	beqz	a5,8000395c <balloc+0xb6>
    800038ca:	8baa                	mv	s7,a0
    800038cc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038ce:	00015b17          	auipc	s6,0x15
    800038d2:	2aab0b13          	addi	s6,s6,682 # 80018b78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038d8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038da:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038dc:	6c89                	lui	s9,0x2
    800038de:	a831                	j	800038fa <balloc+0x54>
    brelse(bp);
    800038e0:	854a                	mv	a0,s2
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	e32080e7          	jalr	-462(ra) # 80003714 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038ea:	015c87bb          	addw	a5,s9,s5
    800038ee:	00078a9b          	sext.w	s5,a5
    800038f2:	004b2703          	lw	a4,4(s6)
    800038f6:	06eaf363          	bgeu	s5,a4,8000395c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038fa:	41fad79b          	sraiw	a5,s5,0x1f
    800038fe:	0137d79b          	srliw	a5,a5,0x13
    80003902:	015787bb          	addw	a5,a5,s5
    80003906:	40d7d79b          	sraiw	a5,a5,0xd
    8000390a:	01cb2583          	lw	a1,28(s6)
    8000390e:	9dbd                	addw	a1,a1,a5
    80003910:	855e                	mv	a0,s7
    80003912:	00000097          	auipc	ra,0x0
    80003916:	cd2080e7          	jalr	-814(ra) # 800035e4 <bread>
    8000391a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000391c:	004b2503          	lw	a0,4(s6)
    80003920:	000a849b          	sext.w	s1,s5
    80003924:	8662                	mv	a2,s8
    80003926:	faa4fde3          	bgeu	s1,a0,800038e0 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000392a:	41f6579b          	sraiw	a5,a2,0x1f
    8000392e:	01d7d69b          	srliw	a3,a5,0x1d
    80003932:	00c6873b          	addw	a4,a3,a2
    80003936:	00777793          	andi	a5,a4,7
    8000393a:	9f95                	subw	a5,a5,a3
    8000393c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003940:	4037571b          	sraiw	a4,a4,0x3
    80003944:	00e906b3          	add	a3,s2,a4
    80003948:	0586c683          	lbu	a3,88(a3)
    8000394c:	00d7f5b3          	and	a1,a5,a3
    80003950:	cd91                	beqz	a1,8000396c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003952:	2605                	addiw	a2,a2,1
    80003954:	2485                	addiw	s1,s1,1
    80003956:	fd4618e3          	bne	a2,s4,80003926 <balloc+0x80>
    8000395a:	b759                	j	800038e0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000395c:	00005517          	auipc	a0,0x5
    80003960:	cf450513          	addi	a0,a0,-780 # 80008650 <syscalls+0x100>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	bda080e7          	jalr	-1062(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000396c:	974a                	add	a4,a4,s2
    8000396e:	8fd5                	or	a5,a5,a3
    80003970:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003974:	854a                	mv	a0,s2
    80003976:	00001097          	auipc	ra,0x1
    8000397a:	01a080e7          	jalr	26(ra) # 80004990 <log_write>
        brelse(bp);
    8000397e:	854a                	mv	a0,s2
    80003980:	00000097          	auipc	ra,0x0
    80003984:	d94080e7          	jalr	-620(ra) # 80003714 <brelse>
  bp = bread(dev, bno);
    80003988:	85a6                	mv	a1,s1
    8000398a:	855e                	mv	a0,s7
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	c58080e7          	jalr	-936(ra) # 800035e4 <bread>
    80003994:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003996:	40000613          	li	a2,1024
    8000399a:	4581                	li	a1,0
    8000399c:	05850513          	addi	a0,a0,88
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	364080e7          	jalr	868(ra) # 80000d04 <memset>
  log_write(bp);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00001097          	auipc	ra,0x1
    800039ae:	fe6080e7          	jalr	-26(ra) # 80004990 <log_write>
  brelse(bp);
    800039b2:	854a                	mv	a0,s2
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	d60080e7          	jalr	-672(ra) # 80003714 <brelse>
}
    800039bc:	8526                	mv	a0,s1
    800039be:	60e6                	ld	ra,88(sp)
    800039c0:	6446                	ld	s0,80(sp)
    800039c2:	64a6                	ld	s1,72(sp)
    800039c4:	6906                	ld	s2,64(sp)
    800039c6:	79e2                	ld	s3,56(sp)
    800039c8:	7a42                	ld	s4,48(sp)
    800039ca:	7aa2                	ld	s5,40(sp)
    800039cc:	7b02                	ld	s6,32(sp)
    800039ce:	6be2                	ld	s7,24(sp)
    800039d0:	6c42                	ld	s8,16(sp)
    800039d2:	6ca2                	ld	s9,8(sp)
    800039d4:	6125                	addi	sp,sp,96
    800039d6:	8082                	ret

00000000800039d8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039d8:	7179                	addi	sp,sp,-48
    800039da:	f406                	sd	ra,40(sp)
    800039dc:	f022                	sd	s0,32(sp)
    800039de:	ec26                	sd	s1,24(sp)
    800039e0:	e84a                	sd	s2,16(sp)
    800039e2:	e44e                	sd	s3,8(sp)
    800039e4:	e052                	sd	s4,0(sp)
    800039e6:	1800                	addi	s0,sp,48
    800039e8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039ea:	47ad                	li	a5,11
    800039ec:	04b7fe63          	bgeu	a5,a1,80003a48 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039f0:	ff45849b          	addiw	s1,a1,-12
    800039f4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039f8:	0ff00793          	li	a5,255
    800039fc:	0ae7e363          	bltu	a5,a4,80003aa2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a00:	08052583          	lw	a1,128(a0)
    80003a04:	c5ad                	beqz	a1,80003a6e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a06:	00092503          	lw	a0,0(s2)
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	bda080e7          	jalr	-1062(ra) # 800035e4 <bread>
    80003a12:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a14:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a18:	02049593          	slli	a1,s1,0x20
    80003a1c:	9181                	srli	a1,a1,0x20
    80003a1e:	058a                	slli	a1,a1,0x2
    80003a20:	00b784b3          	add	s1,a5,a1
    80003a24:	0004a983          	lw	s3,0(s1)
    80003a28:	04098d63          	beqz	s3,80003a82 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a2c:	8552                	mv	a0,s4
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	ce6080e7          	jalr	-794(ra) # 80003714 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a36:	854e                	mv	a0,s3
    80003a38:	70a2                	ld	ra,40(sp)
    80003a3a:	7402                	ld	s0,32(sp)
    80003a3c:	64e2                	ld	s1,24(sp)
    80003a3e:	6942                	ld	s2,16(sp)
    80003a40:	69a2                	ld	s3,8(sp)
    80003a42:	6a02                	ld	s4,0(sp)
    80003a44:	6145                	addi	sp,sp,48
    80003a46:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a48:	02059493          	slli	s1,a1,0x20
    80003a4c:	9081                	srli	s1,s1,0x20
    80003a4e:	048a                	slli	s1,s1,0x2
    80003a50:	94aa                	add	s1,s1,a0
    80003a52:	0504a983          	lw	s3,80(s1)
    80003a56:	fe0990e3          	bnez	s3,80003a36 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a5a:	4108                	lw	a0,0(a0)
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	e4a080e7          	jalr	-438(ra) # 800038a6 <balloc>
    80003a64:	0005099b          	sext.w	s3,a0
    80003a68:	0534a823          	sw	s3,80(s1)
    80003a6c:	b7e9                	j	80003a36 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a6e:	4108                	lw	a0,0(a0)
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	e36080e7          	jalr	-458(ra) # 800038a6 <balloc>
    80003a78:	0005059b          	sext.w	a1,a0
    80003a7c:	08b92023          	sw	a1,128(s2)
    80003a80:	b759                	j	80003a06 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a82:	00092503          	lw	a0,0(s2)
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	e20080e7          	jalr	-480(ra) # 800038a6 <balloc>
    80003a8e:	0005099b          	sext.w	s3,a0
    80003a92:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a96:	8552                	mv	a0,s4
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	ef8080e7          	jalr	-264(ra) # 80004990 <log_write>
    80003aa0:	b771                	j	80003a2c <bmap+0x54>
  panic("bmap: out of range");
    80003aa2:	00005517          	auipc	a0,0x5
    80003aa6:	bc650513          	addi	a0,a0,-1082 # 80008668 <syscalls+0x118>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>

0000000080003ab2 <iget>:
{
    80003ab2:	7179                	addi	sp,sp,-48
    80003ab4:	f406                	sd	ra,40(sp)
    80003ab6:	f022                	sd	s0,32(sp)
    80003ab8:	ec26                	sd	s1,24(sp)
    80003aba:	e84a                	sd	s2,16(sp)
    80003abc:	e44e                	sd	s3,8(sp)
    80003abe:	e052                	sd	s4,0(sp)
    80003ac0:	1800                	addi	s0,sp,48
    80003ac2:	89aa                	mv	s3,a0
    80003ac4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ac6:	00015517          	auipc	a0,0x15
    80003aca:	0d250513          	addi	a0,a0,210 # 80018b98 <itable>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	116080e7          	jalr	278(ra) # 80000be4 <acquire>
  empty = 0;
    80003ad6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ad8:	00015497          	auipc	s1,0x15
    80003adc:	0d848493          	addi	s1,s1,216 # 80018bb0 <itable+0x18>
    80003ae0:	00017697          	auipc	a3,0x17
    80003ae4:	b6068693          	addi	a3,a3,-1184 # 8001a640 <log>
    80003ae8:	a039                	j	80003af6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aea:	02090b63          	beqz	s2,80003b20 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aee:	08848493          	addi	s1,s1,136
    80003af2:	02d48a63          	beq	s1,a3,80003b26 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003af6:	449c                	lw	a5,8(s1)
    80003af8:	fef059e3          	blez	a5,80003aea <iget+0x38>
    80003afc:	4098                	lw	a4,0(s1)
    80003afe:	ff3716e3          	bne	a4,s3,80003aea <iget+0x38>
    80003b02:	40d8                	lw	a4,4(s1)
    80003b04:	ff4713e3          	bne	a4,s4,80003aea <iget+0x38>
      ip->ref++;
    80003b08:	2785                	addiw	a5,a5,1
    80003b0a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b0c:	00015517          	auipc	a0,0x15
    80003b10:	08c50513          	addi	a0,a0,140 # 80018b98 <itable>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	196080e7          	jalr	406(ra) # 80000caa <release>
      return ip;
    80003b1c:	8926                	mv	s2,s1
    80003b1e:	a03d                	j	80003b4c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b20:	f7f9                	bnez	a5,80003aee <iget+0x3c>
    80003b22:	8926                	mv	s2,s1
    80003b24:	b7e9                	j	80003aee <iget+0x3c>
  if(empty == 0)
    80003b26:	02090c63          	beqz	s2,80003b5e <iget+0xac>
  ip->dev = dev;
    80003b2a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b2e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b32:	4785                	li	a5,1
    80003b34:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b38:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b3c:	00015517          	auipc	a0,0x15
    80003b40:	05c50513          	addi	a0,a0,92 # 80018b98 <itable>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	166080e7          	jalr	358(ra) # 80000caa <release>
}
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	70a2                	ld	ra,40(sp)
    80003b50:	7402                	ld	s0,32(sp)
    80003b52:	64e2                	ld	s1,24(sp)
    80003b54:	6942                	ld	s2,16(sp)
    80003b56:	69a2                	ld	s3,8(sp)
    80003b58:	6a02                	ld	s4,0(sp)
    80003b5a:	6145                	addi	sp,sp,48
    80003b5c:	8082                	ret
    panic("iget: no inodes");
    80003b5e:	00005517          	auipc	a0,0x5
    80003b62:	b2250513          	addi	a0,a0,-1246 # 80008680 <syscalls+0x130>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	9d8080e7          	jalr	-1576(ra) # 8000053e <panic>

0000000080003b6e <fsinit>:
fsinit(int dev) {
    80003b6e:	7179                	addi	sp,sp,-48
    80003b70:	f406                	sd	ra,40(sp)
    80003b72:	f022                	sd	s0,32(sp)
    80003b74:	ec26                	sd	s1,24(sp)
    80003b76:	e84a                	sd	s2,16(sp)
    80003b78:	e44e                	sd	s3,8(sp)
    80003b7a:	1800                	addi	s0,sp,48
    80003b7c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b7e:	4585                	li	a1,1
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	a64080e7          	jalr	-1436(ra) # 800035e4 <bread>
    80003b88:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b8a:	00015997          	auipc	s3,0x15
    80003b8e:	fee98993          	addi	s3,s3,-18 # 80018b78 <sb>
    80003b92:	02000613          	li	a2,32
    80003b96:	05850593          	addi	a1,a0,88
    80003b9a:	854e                	mv	a0,s3
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	1c8080e7          	jalr	456(ra) # 80000d64 <memmove>
  brelse(bp);
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	b6e080e7          	jalr	-1170(ra) # 80003714 <brelse>
  if(sb.magic != FSMAGIC)
    80003bae:	0009a703          	lw	a4,0(s3)
    80003bb2:	102037b7          	lui	a5,0x10203
    80003bb6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bba:	02f71263          	bne	a4,a5,80003bde <fsinit+0x70>
  initlog(dev, &sb);
    80003bbe:	00015597          	auipc	a1,0x15
    80003bc2:	fba58593          	addi	a1,a1,-70 # 80018b78 <sb>
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	00001097          	auipc	ra,0x1
    80003bcc:	b4c080e7          	jalr	-1204(ra) # 80004714 <initlog>
}
    80003bd0:	70a2                	ld	ra,40(sp)
    80003bd2:	7402                	ld	s0,32(sp)
    80003bd4:	64e2                	ld	s1,24(sp)
    80003bd6:	6942                	ld	s2,16(sp)
    80003bd8:	69a2                	ld	s3,8(sp)
    80003bda:	6145                	addi	sp,sp,48
    80003bdc:	8082                	ret
    panic("invalid file system");
    80003bde:	00005517          	auipc	a0,0x5
    80003be2:	ab250513          	addi	a0,a0,-1358 # 80008690 <syscalls+0x140>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	958080e7          	jalr	-1704(ra) # 8000053e <panic>

0000000080003bee <iinit>:
{
    80003bee:	7179                	addi	sp,sp,-48
    80003bf0:	f406                	sd	ra,40(sp)
    80003bf2:	f022                	sd	s0,32(sp)
    80003bf4:	ec26                	sd	s1,24(sp)
    80003bf6:	e84a                	sd	s2,16(sp)
    80003bf8:	e44e                	sd	s3,8(sp)
    80003bfa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bfc:	00005597          	auipc	a1,0x5
    80003c00:	aac58593          	addi	a1,a1,-1364 # 800086a8 <syscalls+0x158>
    80003c04:	00015517          	auipc	a0,0x15
    80003c08:	f9450513          	addi	a0,a0,-108 # 80018b98 <itable>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	f48080e7          	jalr	-184(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c14:	00015497          	auipc	s1,0x15
    80003c18:	fac48493          	addi	s1,s1,-84 # 80018bc0 <itable+0x28>
    80003c1c:	00017997          	auipc	s3,0x17
    80003c20:	a3498993          	addi	s3,s3,-1484 # 8001a650 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c24:	00005917          	auipc	s2,0x5
    80003c28:	a8c90913          	addi	s2,s2,-1396 # 800086b0 <syscalls+0x160>
    80003c2c:	85ca                	mv	a1,s2
    80003c2e:	8526                	mv	a0,s1
    80003c30:	00001097          	auipc	ra,0x1
    80003c34:	e46080e7          	jalr	-442(ra) # 80004a76 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c38:	08848493          	addi	s1,s1,136
    80003c3c:	ff3498e3          	bne	s1,s3,80003c2c <iinit+0x3e>
}
    80003c40:	70a2                	ld	ra,40(sp)
    80003c42:	7402                	ld	s0,32(sp)
    80003c44:	64e2                	ld	s1,24(sp)
    80003c46:	6942                	ld	s2,16(sp)
    80003c48:	69a2                	ld	s3,8(sp)
    80003c4a:	6145                	addi	sp,sp,48
    80003c4c:	8082                	ret

0000000080003c4e <ialloc>:
{
    80003c4e:	715d                	addi	sp,sp,-80
    80003c50:	e486                	sd	ra,72(sp)
    80003c52:	e0a2                	sd	s0,64(sp)
    80003c54:	fc26                	sd	s1,56(sp)
    80003c56:	f84a                	sd	s2,48(sp)
    80003c58:	f44e                	sd	s3,40(sp)
    80003c5a:	f052                	sd	s4,32(sp)
    80003c5c:	ec56                	sd	s5,24(sp)
    80003c5e:	e85a                	sd	s6,16(sp)
    80003c60:	e45e                	sd	s7,8(sp)
    80003c62:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c64:	00015717          	auipc	a4,0x15
    80003c68:	f2072703          	lw	a4,-224(a4) # 80018b84 <sb+0xc>
    80003c6c:	4785                	li	a5,1
    80003c6e:	04e7fa63          	bgeu	a5,a4,80003cc2 <ialloc+0x74>
    80003c72:	8aaa                	mv	s5,a0
    80003c74:	8bae                	mv	s7,a1
    80003c76:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c78:	00015a17          	auipc	s4,0x15
    80003c7c:	f00a0a13          	addi	s4,s4,-256 # 80018b78 <sb>
    80003c80:	00048b1b          	sext.w	s6,s1
    80003c84:	0044d593          	srli	a1,s1,0x4
    80003c88:	018a2783          	lw	a5,24(s4)
    80003c8c:	9dbd                	addw	a1,a1,a5
    80003c8e:	8556                	mv	a0,s5
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	954080e7          	jalr	-1708(ra) # 800035e4 <bread>
    80003c98:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c9a:	05850993          	addi	s3,a0,88
    80003c9e:	00f4f793          	andi	a5,s1,15
    80003ca2:	079a                	slli	a5,a5,0x6
    80003ca4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ca6:	00099783          	lh	a5,0(s3)
    80003caa:	c785                	beqz	a5,80003cd2 <ialloc+0x84>
    brelse(bp);
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	a68080e7          	jalr	-1432(ra) # 80003714 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb4:	0485                	addi	s1,s1,1
    80003cb6:	00ca2703          	lw	a4,12(s4)
    80003cba:	0004879b          	sext.w	a5,s1
    80003cbe:	fce7e1e3          	bltu	a5,a4,80003c80 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cc2:	00005517          	auipc	a0,0x5
    80003cc6:	9f650513          	addi	a0,a0,-1546 # 800086b8 <syscalls+0x168>
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cd2:	04000613          	li	a2,64
    80003cd6:	4581                	li	a1,0
    80003cd8:	854e                	mv	a0,s3
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	02a080e7          	jalr	42(ra) # 80000d04 <memset>
      dip->type = type;
    80003ce2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	ca8080e7          	jalr	-856(ra) # 80004990 <log_write>
      brelse(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	a22080e7          	jalr	-1502(ra) # 80003714 <brelse>
      return iget(dev, inum);
    80003cfa:	85da                	mv	a1,s6
    80003cfc:	8556                	mv	a0,s5
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	db4080e7          	jalr	-588(ra) # 80003ab2 <iget>
}
    80003d06:	60a6                	ld	ra,72(sp)
    80003d08:	6406                	ld	s0,64(sp)
    80003d0a:	74e2                	ld	s1,56(sp)
    80003d0c:	7942                	ld	s2,48(sp)
    80003d0e:	79a2                	ld	s3,40(sp)
    80003d10:	7a02                	ld	s4,32(sp)
    80003d12:	6ae2                	ld	s5,24(sp)
    80003d14:	6b42                	ld	s6,16(sp)
    80003d16:	6ba2                	ld	s7,8(sp)
    80003d18:	6161                	addi	sp,sp,80
    80003d1a:	8082                	ret

0000000080003d1c <iupdate>:
{
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	e04a                	sd	s2,0(sp)
    80003d26:	1000                	addi	s0,sp,32
    80003d28:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2a:	415c                	lw	a5,4(a0)
    80003d2c:	0047d79b          	srliw	a5,a5,0x4
    80003d30:	00015597          	auipc	a1,0x15
    80003d34:	e605a583          	lw	a1,-416(a1) # 80018b90 <sb+0x18>
    80003d38:	9dbd                	addw	a1,a1,a5
    80003d3a:	4108                	lw	a0,0(a0)
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	8a8080e7          	jalr	-1880(ra) # 800035e4 <bread>
    80003d44:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d46:	05850793          	addi	a5,a0,88
    80003d4a:	40c8                	lw	a0,4(s1)
    80003d4c:	893d                	andi	a0,a0,15
    80003d4e:	051a                	slli	a0,a0,0x6
    80003d50:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d52:	04449703          	lh	a4,68(s1)
    80003d56:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d5a:	04649703          	lh	a4,70(s1)
    80003d5e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d62:	04849703          	lh	a4,72(s1)
    80003d66:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d6a:	04a49703          	lh	a4,74(s1)
    80003d6e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d72:	44f8                	lw	a4,76(s1)
    80003d74:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d76:	03400613          	li	a2,52
    80003d7a:	05048593          	addi	a1,s1,80
    80003d7e:	0531                	addi	a0,a0,12
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	fe4080e7          	jalr	-28(ra) # 80000d64 <memmove>
  log_write(bp);
    80003d88:	854a                	mv	a0,s2
    80003d8a:	00001097          	auipc	ra,0x1
    80003d8e:	c06080e7          	jalr	-1018(ra) # 80004990 <log_write>
  brelse(bp);
    80003d92:	854a                	mv	a0,s2
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	980080e7          	jalr	-1664(ra) # 80003714 <brelse>
}
    80003d9c:	60e2                	ld	ra,24(sp)
    80003d9e:	6442                	ld	s0,16(sp)
    80003da0:	64a2                	ld	s1,8(sp)
    80003da2:	6902                	ld	s2,0(sp)
    80003da4:	6105                	addi	sp,sp,32
    80003da6:	8082                	ret

0000000080003da8 <idup>:
{
    80003da8:	1101                	addi	sp,sp,-32
    80003daa:	ec06                	sd	ra,24(sp)
    80003dac:	e822                	sd	s0,16(sp)
    80003dae:	e426                	sd	s1,8(sp)
    80003db0:	1000                	addi	s0,sp,32
    80003db2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db4:	00015517          	auipc	a0,0x15
    80003db8:	de450513          	addi	a0,a0,-540 # 80018b98 <itable>
    80003dbc:	ffffd097          	auipc	ra,0xffffd
    80003dc0:	e28080e7          	jalr	-472(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dc4:	449c                	lw	a5,8(s1)
    80003dc6:	2785                	addiw	a5,a5,1
    80003dc8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dca:	00015517          	auipc	a0,0x15
    80003dce:	dce50513          	addi	a0,a0,-562 # 80018b98 <itable>
    80003dd2:	ffffd097          	auipc	ra,0xffffd
    80003dd6:	ed8080e7          	jalr	-296(ra) # 80000caa <release>
}
    80003dda:	8526                	mv	a0,s1
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	64a2                	ld	s1,8(sp)
    80003de2:	6105                	addi	sp,sp,32
    80003de4:	8082                	ret

0000000080003de6 <ilock>:
{
    80003de6:	1101                	addi	sp,sp,-32
    80003de8:	ec06                	sd	ra,24(sp)
    80003dea:	e822                	sd	s0,16(sp)
    80003dec:	e426                	sd	s1,8(sp)
    80003dee:	e04a                	sd	s2,0(sp)
    80003df0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003df2:	c115                	beqz	a0,80003e16 <ilock+0x30>
    80003df4:	84aa                	mv	s1,a0
    80003df6:	451c                	lw	a5,8(a0)
    80003df8:	00f05f63          	blez	a5,80003e16 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dfc:	0541                	addi	a0,a0,16
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	cb2080e7          	jalr	-846(ra) # 80004ab0 <acquiresleep>
  if(ip->valid == 0){
    80003e06:	40bc                	lw	a5,64(s1)
    80003e08:	cf99                	beqz	a5,80003e26 <ilock+0x40>
}
    80003e0a:	60e2                	ld	ra,24(sp)
    80003e0c:	6442                	ld	s0,16(sp)
    80003e0e:	64a2                	ld	s1,8(sp)
    80003e10:	6902                	ld	s2,0(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret
    panic("ilock");
    80003e16:	00005517          	auipc	a0,0x5
    80003e1a:	8ba50513          	addi	a0,a0,-1862 # 800086d0 <syscalls+0x180>
    80003e1e:	ffffc097          	auipc	ra,0xffffc
    80003e22:	720080e7          	jalr	1824(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e26:	40dc                	lw	a5,4(s1)
    80003e28:	0047d79b          	srliw	a5,a5,0x4
    80003e2c:	00015597          	auipc	a1,0x15
    80003e30:	d645a583          	lw	a1,-668(a1) # 80018b90 <sb+0x18>
    80003e34:	9dbd                	addw	a1,a1,a5
    80003e36:	4088                	lw	a0,0(s1)
    80003e38:	fffff097          	auipc	ra,0xfffff
    80003e3c:	7ac080e7          	jalr	1964(ra) # 800035e4 <bread>
    80003e40:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e42:	05850593          	addi	a1,a0,88
    80003e46:	40dc                	lw	a5,4(s1)
    80003e48:	8bbd                	andi	a5,a5,15
    80003e4a:	079a                	slli	a5,a5,0x6
    80003e4c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e4e:	00059783          	lh	a5,0(a1)
    80003e52:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e56:	00259783          	lh	a5,2(a1)
    80003e5a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e5e:	00459783          	lh	a5,4(a1)
    80003e62:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e66:	00659783          	lh	a5,6(a1)
    80003e6a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e6e:	459c                	lw	a5,8(a1)
    80003e70:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e72:	03400613          	li	a2,52
    80003e76:	05b1                	addi	a1,a1,12
    80003e78:	05048513          	addi	a0,s1,80
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	ee8080e7          	jalr	-280(ra) # 80000d64 <memmove>
    brelse(bp);
    80003e84:	854a                	mv	a0,s2
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	88e080e7          	jalr	-1906(ra) # 80003714 <brelse>
    ip->valid = 1;
    80003e8e:	4785                	li	a5,1
    80003e90:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e92:	04449783          	lh	a5,68(s1)
    80003e96:	fbb5                	bnez	a5,80003e0a <ilock+0x24>
      panic("ilock: no type");
    80003e98:	00005517          	auipc	a0,0x5
    80003e9c:	84050513          	addi	a0,a0,-1984 # 800086d8 <syscalls+0x188>
    80003ea0:	ffffc097          	auipc	ra,0xffffc
    80003ea4:	69e080e7          	jalr	1694(ra) # 8000053e <panic>

0000000080003ea8 <iunlock>:
{
    80003ea8:	1101                	addi	sp,sp,-32
    80003eaa:	ec06                	sd	ra,24(sp)
    80003eac:	e822                	sd	s0,16(sp)
    80003eae:	e426                	sd	s1,8(sp)
    80003eb0:	e04a                	sd	s2,0(sp)
    80003eb2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eb4:	c905                	beqz	a0,80003ee4 <iunlock+0x3c>
    80003eb6:	84aa                	mv	s1,a0
    80003eb8:	01050913          	addi	s2,a0,16
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00001097          	auipc	ra,0x1
    80003ec2:	c8c080e7          	jalr	-884(ra) # 80004b4a <holdingsleep>
    80003ec6:	cd19                	beqz	a0,80003ee4 <iunlock+0x3c>
    80003ec8:	449c                	lw	a5,8(s1)
    80003eca:	00f05d63          	blez	a5,80003ee4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ece:	854a                	mv	a0,s2
    80003ed0:	00001097          	auipc	ra,0x1
    80003ed4:	c36080e7          	jalr	-970(ra) # 80004b06 <releasesleep>
}
    80003ed8:	60e2                	ld	ra,24(sp)
    80003eda:	6442                	ld	s0,16(sp)
    80003edc:	64a2                	ld	s1,8(sp)
    80003ede:	6902                	ld	s2,0(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret
    panic("iunlock");
    80003ee4:	00005517          	auipc	a0,0x5
    80003ee8:	80450513          	addi	a0,a0,-2044 # 800086e8 <syscalls+0x198>
    80003eec:	ffffc097          	auipc	ra,0xffffc
    80003ef0:	652080e7          	jalr	1618(ra) # 8000053e <panic>

0000000080003ef4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ef4:	7179                	addi	sp,sp,-48
    80003ef6:	f406                	sd	ra,40(sp)
    80003ef8:	f022                	sd	s0,32(sp)
    80003efa:	ec26                	sd	s1,24(sp)
    80003efc:	e84a                	sd	s2,16(sp)
    80003efe:	e44e                	sd	s3,8(sp)
    80003f00:	e052                	sd	s4,0(sp)
    80003f02:	1800                	addi	s0,sp,48
    80003f04:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f06:	05050493          	addi	s1,a0,80
    80003f0a:	08050913          	addi	s2,a0,128
    80003f0e:	a021                	j	80003f16 <itrunc+0x22>
    80003f10:	0491                	addi	s1,s1,4
    80003f12:	01248d63          	beq	s1,s2,80003f2c <itrunc+0x38>
    if(ip->addrs[i]){
    80003f16:	408c                	lw	a1,0(s1)
    80003f18:	dde5                	beqz	a1,80003f10 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f1a:	0009a503          	lw	a0,0(s3)
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	90c080e7          	jalr	-1780(ra) # 8000382a <bfree>
      ip->addrs[i] = 0;
    80003f26:	0004a023          	sw	zero,0(s1)
    80003f2a:	b7dd                	j	80003f10 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f2c:	0809a583          	lw	a1,128(s3)
    80003f30:	e185                	bnez	a1,80003f50 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f32:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f36:	854e                	mv	a0,s3
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	de4080e7          	jalr	-540(ra) # 80003d1c <iupdate>
}
    80003f40:	70a2                	ld	ra,40(sp)
    80003f42:	7402                	ld	s0,32(sp)
    80003f44:	64e2                	ld	s1,24(sp)
    80003f46:	6942                	ld	s2,16(sp)
    80003f48:	69a2                	ld	s3,8(sp)
    80003f4a:	6a02                	ld	s4,0(sp)
    80003f4c:	6145                	addi	sp,sp,48
    80003f4e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f50:	0009a503          	lw	a0,0(s3)
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	690080e7          	jalr	1680(ra) # 800035e4 <bread>
    80003f5c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f5e:	05850493          	addi	s1,a0,88
    80003f62:	45850913          	addi	s2,a0,1112
    80003f66:	a811                	j	80003f7a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f68:	0009a503          	lw	a0,0(s3)
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	8be080e7          	jalr	-1858(ra) # 8000382a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f74:	0491                	addi	s1,s1,4
    80003f76:	01248563          	beq	s1,s2,80003f80 <itrunc+0x8c>
      if(a[j])
    80003f7a:	408c                	lw	a1,0(s1)
    80003f7c:	dde5                	beqz	a1,80003f74 <itrunc+0x80>
    80003f7e:	b7ed                	j	80003f68 <itrunc+0x74>
    brelse(bp);
    80003f80:	8552                	mv	a0,s4
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	792080e7          	jalr	1938(ra) # 80003714 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f8a:	0809a583          	lw	a1,128(s3)
    80003f8e:	0009a503          	lw	a0,0(s3)
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	898080e7          	jalr	-1896(ra) # 8000382a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f9a:	0809a023          	sw	zero,128(s3)
    80003f9e:	bf51                	j	80003f32 <itrunc+0x3e>

0000000080003fa0 <iput>:
{
    80003fa0:	1101                	addi	sp,sp,-32
    80003fa2:	ec06                	sd	ra,24(sp)
    80003fa4:	e822                	sd	s0,16(sp)
    80003fa6:	e426                	sd	s1,8(sp)
    80003fa8:	e04a                	sd	s2,0(sp)
    80003faa:	1000                	addi	s0,sp,32
    80003fac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fae:	00015517          	auipc	a0,0x15
    80003fb2:	bea50513          	addi	a0,a0,-1046 # 80018b98 <itable>
    80003fb6:	ffffd097          	auipc	ra,0xffffd
    80003fba:	c2e080e7          	jalr	-978(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fbe:	4498                	lw	a4,8(s1)
    80003fc0:	4785                	li	a5,1
    80003fc2:	02f70363          	beq	a4,a5,80003fe8 <iput+0x48>
  ip->ref--;
    80003fc6:	449c                	lw	a5,8(s1)
    80003fc8:	37fd                	addiw	a5,a5,-1
    80003fca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fcc:	00015517          	auipc	a0,0x15
    80003fd0:	bcc50513          	addi	a0,a0,-1076 # 80018b98 <itable>
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	cd6080e7          	jalr	-810(ra) # 80000caa <release>
}
    80003fdc:	60e2                	ld	ra,24(sp)
    80003fde:	6442                	ld	s0,16(sp)
    80003fe0:	64a2                	ld	s1,8(sp)
    80003fe2:	6902                	ld	s2,0(sp)
    80003fe4:	6105                	addi	sp,sp,32
    80003fe6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fe8:	40bc                	lw	a5,64(s1)
    80003fea:	dff1                	beqz	a5,80003fc6 <iput+0x26>
    80003fec:	04a49783          	lh	a5,74(s1)
    80003ff0:	fbf9                	bnez	a5,80003fc6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ff2:	01048913          	addi	s2,s1,16
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	00001097          	auipc	ra,0x1
    80003ffc:	ab8080e7          	jalr	-1352(ra) # 80004ab0 <acquiresleep>
    release(&itable.lock);
    80004000:	00015517          	auipc	a0,0x15
    80004004:	b9850513          	addi	a0,a0,-1128 # 80018b98 <itable>
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	ca2080e7          	jalr	-862(ra) # 80000caa <release>
    itrunc(ip);
    80004010:	8526                	mv	a0,s1
    80004012:	00000097          	auipc	ra,0x0
    80004016:	ee2080e7          	jalr	-286(ra) # 80003ef4 <itrunc>
    ip->type = 0;
    8000401a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000401e:	8526                	mv	a0,s1
    80004020:	00000097          	auipc	ra,0x0
    80004024:	cfc080e7          	jalr	-772(ra) # 80003d1c <iupdate>
    ip->valid = 0;
    80004028:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000402c:	854a                	mv	a0,s2
    8000402e:	00001097          	auipc	ra,0x1
    80004032:	ad8080e7          	jalr	-1320(ra) # 80004b06 <releasesleep>
    acquire(&itable.lock);
    80004036:	00015517          	auipc	a0,0x15
    8000403a:	b6250513          	addi	a0,a0,-1182 # 80018b98 <itable>
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	ba6080e7          	jalr	-1114(ra) # 80000be4 <acquire>
    80004046:	b741                	j	80003fc6 <iput+0x26>

0000000080004048 <iunlockput>:
{
    80004048:	1101                	addi	sp,sp,-32
    8000404a:	ec06                	sd	ra,24(sp)
    8000404c:	e822                	sd	s0,16(sp)
    8000404e:	e426                	sd	s1,8(sp)
    80004050:	1000                	addi	s0,sp,32
    80004052:	84aa                	mv	s1,a0
  iunlock(ip);
    80004054:	00000097          	auipc	ra,0x0
    80004058:	e54080e7          	jalr	-428(ra) # 80003ea8 <iunlock>
  iput(ip);
    8000405c:	8526                	mv	a0,s1
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	f42080e7          	jalr	-190(ra) # 80003fa0 <iput>
}
    80004066:	60e2                	ld	ra,24(sp)
    80004068:	6442                	ld	s0,16(sp)
    8000406a:	64a2                	ld	s1,8(sp)
    8000406c:	6105                	addi	sp,sp,32
    8000406e:	8082                	ret

0000000080004070 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004070:	1141                	addi	sp,sp,-16
    80004072:	e422                	sd	s0,8(sp)
    80004074:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004076:	411c                	lw	a5,0(a0)
    80004078:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000407a:	415c                	lw	a5,4(a0)
    8000407c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000407e:	04451783          	lh	a5,68(a0)
    80004082:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004086:	04a51783          	lh	a5,74(a0)
    8000408a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000408e:	04c56783          	lwu	a5,76(a0)
    80004092:	e99c                	sd	a5,16(a1)
}
    80004094:	6422                	ld	s0,8(sp)
    80004096:	0141                	addi	sp,sp,16
    80004098:	8082                	ret

000000008000409a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000409a:	457c                	lw	a5,76(a0)
    8000409c:	0ed7e963          	bltu	a5,a3,8000418e <readi+0xf4>
{
    800040a0:	7159                	addi	sp,sp,-112
    800040a2:	f486                	sd	ra,104(sp)
    800040a4:	f0a2                	sd	s0,96(sp)
    800040a6:	eca6                	sd	s1,88(sp)
    800040a8:	e8ca                	sd	s2,80(sp)
    800040aa:	e4ce                	sd	s3,72(sp)
    800040ac:	e0d2                	sd	s4,64(sp)
    800040ae:	fc56                	sd	s5,56(sp)
    800040b0:	f85a                	sd	s6,48(sp)
    800040b2:	f45e                	sd	s7,40(sp)
    800040b4:	f062                	sd	s8,32(sp)
    800040b6:	ec66                	sd	s9,24(sp)
    800040b8:	e86a                	sd	s10,16(sp)
    800040ba:	e46e                	sd	s11,8(sp)
    800040bc:	1880                	addi	s0,sp,112
    800040be:	8baa                	mv	s7,a0
    800040c0:	8c2e                	mv	s8,a1
    800040c2:	8ab2                	mv	s5,a2
    800040c4:	84b6                	mv	s1,a3
    800040c6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c8:	9f35                	addw	a4,a4,a3
    return 0;
    800040ca:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040cc:	0ad76063          	bltu	a4,a3,8000416c <readi+0xd2>
  if(off + n > ip->size)
    800040d0:	00e7f463          	bgeu	a5,a4,800040d8 <readi+0x3e>
    n = ip->size - off;
    800040d4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d8:	0a0b0963          	beqz	s6,8000418a <readi+0xf0>
    800040dc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040de:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040e2:	5cfd                	li	s9,-1
    800040e4:	a82d                	j	8000411e <readi+0x84>
    800040e6:	020a1d93          	slli	s11,s4,0x20
    800040ea:	020ddd93          	srli	s11,s11,0x20
    800040ee:	05890613          	addi	a2,s2,88
    800040f2:	86ee                	mv	a3,s11
    800040f4:	963a                	add	a2,a2,a4
    800040f6:	85d6                	mv	a1,s5
    800040f8:	8562                	mv	a0,s8
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	ad0080e7          	jalr	-1328(ra) # 80002bca <either_copyout>
    80004102:	05950d63          	beq	a0,s9,8000415c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004106:	854a                	mv	a0,s2
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	60c080e7          	jalr	1548(ra) # 80003714 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004110:	013a09bb          	addw	s3,s4,s3
    80004114:	009a04bb          	addw	s1,s4,s1
    80004118:	9aee                	add	s5,s5,s11
    8000411a:	0569f763          	bgeu	s3,s6,80004168 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000411e:	000ba903          	lw	s2,0(s7)
    80004122:	00a4d59b          	srliw	a1,s1,0xa
    80004126:	855e                	mv	a0,s7
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	8b0080e7          	jalr	-1872(ra) # 800039d8 <bmap>
    80004130:	0005059b          	sext.w	a1,a0
    80004134:	854a                	mv	a0,s2
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	4ae080e7          	jalr	1198(ra) # 800035e4 <bread>
    8000413e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004140:	3ff4f713          	andi	a4,s1,1023
    80004144:	40ed07bb          	subw	a5,s10,a4
    80004148:	413b06bb          	subw	a3,s6,s3
    8000414c:	8a3e                	mv	s4,a5
    8000414e:	2781                	sext.w	a5,a5
    80004150:	0006861b          	sext.w	a2,a3
    80004154:	f8f679e3          	bgeu	a2,a5,800040e6 <readi+0x4c>
    80004158:	8a36                	mv	s4,a3
    8000415a:	b771                	j	800040e6 <readi+0x4c>
      brelse(bp);
    8000415c:	854a                	mv	a0,s2
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	5b6080e7          	jalr	1462(ra) # 80003714 <brelse>
      tot = -1;
    80004166:	59fd                	li	s3,-1
  }
  return tot;
    80004168:	0009851b          	sext.w	a0,s3
}
    8000416c:	70a6                	ld	ra,104(sp)
    8000416e:	7406                	ld	s0,96(sp)
    80004170:	64e6                	ld	s1,88(sp)
    80004172:	6946                	ld	s2,80(sp)
    80004174:	69a6                	ld	s3,72(sp)
    80004176:	6a06                	ld	s4,64(sp)
    80004178:	7ae2                	ld	s5,56(sp)
    8000417a:	7b42                	ld	s6,48(sp)
    8000417c:	7ba2                	ld	s7,40(sp)
    8000417e:	7c02                	ld	s8,32(sp)
    80004180:	6ce2                	ld	s9,24(sp)
    80004182:	6d42                	ld	s10,16(sp)
    80004184:	6da2                	ld	s11,8(sp)
    80004186:	6165                	addi	sp,sp,112
    80004188:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000418a:	89da                	mv	s3,s6
    8000418c:	bff1                	j	80004168 <readi+0xce>
    return 0;
    8000418e:	4501                	li	a0,0
}
    80004190:	8082                	ret

0000000080004192 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004192:	457c                	lw	a5,76(a0)
    80004194:	10d7e863          	bltu	a5,a3,800042a4 <writei+0x112>
{
    80004198:	7159                	addi	sp,sp,-112
    8000419a:	f486                	sd	ra,104(sp)
    8000419c:	f0a2                	sd	s0,96(sp)
    8000419e:	eca6                	sd	s1,88(sp)
    800041a0:	e8ca                	sd	s2,80(sp)
    800041a2:	e4ce                	sd	s3,72(sp)
    800041a4:	e0d2                	sd	s4,64(sp)
    800041a6:	fc56                	sd	s5,56(sp)
    800041a8:	f85a                	sd	s6,48(sp)
    800041aa:	f45e                	sd	s7,40(sp)
    800041ac:	f062                	sd	s8,32(sp)
    800041ae:	ec66                	sd	s9,24(sp)
    800041b0:	e86a                	sd	s10,16(sp)
    800041b2:	e46e                	sd	s11,8(sp)
    800041b4:	1880                	addi	s0,sp,112
    800041b6:	8b2a                	mv	s6,a0
    800041b8:	8c2e                	mv	s8,a1
    800041ba:	8ab2                	mv	s5,a2
    800041bc:	8936                	mv	s2,a3
    800041be:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041c0:	00e687bb          	addw	a5,a3,a4
    800041c4:	0ed7e263          	bltu	a5,a3,800042a8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041c8:	00043737          	lui	a4,0x43
    800041cc:	0ef76063          	bltu	a4,a5,800042ac <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041d0:	0c0b8863          	beqz	s7,800042a0 <writei+0x10e>
    800041d4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041d6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041da:	5cfd                	li	s9,-1
    800041dc:	a091                	j	80004220 <writei+0x8e>
    800041de:	02099d93          	slli	s11,s3,0x20
    800041e2:	020ddd93          	srli	s11,s11,0x20
    800041e6:	05848513          	addi	a0,s1,88
    800041ea:	86ee                	mv	a3,s11
    800041ec:	8656                	mv	a2,s5
    800041ee:	85e2                	mv	a1,s8
    800041f0:	953a                	add	a0,a0,a4
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	a2e080e7          	jalr	-1490(ra) # 80002c20 <either_copyin>
    800041fa:	07950263          	beq	a0,s9,8000425e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041fe:	8526                	mv	a0,s1
    80004200:	00000097          	auipc	ra,0x0
    80004204:	790080e7          	jalr	1936(ra) # 80004990 <log_write>
    brelse(bp);
    80004208:	8526                	mv	a0,s1
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	50a080e7          	jalr	1290(ra) # 80003714 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004212:	01498a3b          	addw	s4,s3,s4
    80004216:	0129893b          	addw	s2,s3,s2
    8000421a:	9aee                	add	s5,s5,s11
    8000421c:	057a7663          	bgeu	s4,s7,80004268 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004220:	000b2483          	lw	s1,0(s6)
    80004224:	00a9559b          	srliw	a1,s2,0xa
    80004228:	855a                	mv	a0,s6
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	7ae080e7          	jalr	1966(ra) # 800039d8 <bmap>
    80004232:	0005059b          	sext.w	a1,a0
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	3ac080e7          	jalr	940(ra) # 800035e4 <bread>
    80004240:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004242:	3ff97713          	andi	a4,s2,1023
    80004246:	40ed07bb          	subw	a5,s10,a4
    8000424a:	414b86bb          	subw	a3,s7,s4
    8000424e:	89be                	mv	s3,a5
    80004250:	2781                	sext.w	a5,a5
    80004252:	0006861b          	sext.w	a2,a3
    80004256:	f8f674e3          	bgeu	a2,a5,800041de <writei+0x4c>
    8000425a:	89b6                	mv	s3,a3
    8000425c:	b749                	j	800041de <writei+0x4c>
      brelse(bp);
    8000425e:	8526                	mv	a0,s1
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	4b4080e7          	jalr	1204(ra) # 80003714 <brelse>
  }

  if(off > ip->size)
    80004268:	04cb2783          	lw	a5,76(s6)
    8000426c:	0127f463          	bgeu	a5,s2,80004274 <writei+0xe2>
    ip->size = off;
    80004270:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004274:	855a                	mv	a0,s6
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	aa6080e7          	jalr	-1370(ra) # 80003d1c <iupdate>

  return tot;
    8000427e:	000a051b          	sext.w	a0,s4
}
    80004282:	70a6                	ld	ra,104(sp)
    80004284:	7406                	ld	s0,96(sp)
    80004286:	64e6                	ld	s1,88(sp)
    80004288:	6946                	ld	s2,80(sp)
    8000428a:	69a6                	ld	s3,72(sp)
    8000428c:	6a06                	ld	s4,64(sp)
    8000428e:	7ae2                	ld	s5,56(sp)
    80004290:	7b42                	ld	s6,48(sp)
    80004292:	7ba2                	ld	s7,40(sp)
    80004294:	7c02                	ld	s8,32(sp)
    80004296:	6ce2                	ld	s9,24(sp)
    80004298:	6d42                	ld	s10,16(sp)
    8000429a:	6da2                	ld	s11,8(sp)
    8000429c:	6165                	addi	sp,sp,112
    8000429e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042a0:	8a5e                	mv	s4,s7
    800042a2:	bfc9                	j	80004274 <writei+0xe2>
    return -1;
    800042a4:	557d                	li	a0,-1
}
    800042a6:	8082                	ret
    return -1;
    800042a8:	557d                	li	a0,-1
    800042aa:	bfe1                	j	80004282 <writei+0xf0>
    return -1;
    800042ac:	557d                	li	a0,-1
    800042ae:	bfd1                	j	80004282 <writei+0xf0>

00000000800042b0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042b0:	1141                	addi	sp,sp,-16
    800042b2:	e406                	sd	ra,8(sp)
    800042b4:	e022                	sd	s0,0(sp)
    800042b6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042b8:	4639                	li	a2,14
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	b22080e7          	jalr	-1246(ra) # 80000ddc <strncmp>
}
    800042c2:	60a2                	ld	ra,8(sp)
    800042c4:	6402                	ld	s0,0(sp)
    800042c6:	0141                	addi	sp,sp,16
    800042c8:	8082                	ret

00000000800042ca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042ca:	7139                	addi	sp,sp,-64
    800042cc:	fc06                	sd	ra,56(sp)
    800042ce:	f822                	sd	s0,48(sp)
    800042d0:	f426                	sd	s1,40(sp)
    800042d2:	f04a                	sd	s2,32(sp)
    800042d4:	ec4e                	sd	s3,24(sp)
    800042d6:	e852                	sd	s4,16(sp)
    800042d8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042da:	04451703          	lh	a4,68(a0)
    800042de:	4785                	li	a5,1
    800042e0:	00f71a63          	bne	a4,a5,800042f4 <dirlookup+0x2a>
    800042e4:	892a                	mv	s2,a0
    800042e6:	89ae                	mv	s3,a1
    800042e8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ea:	457c                	lw	a5,76(a0)
    800042ec:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042ee:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f0:	e79d                	bnez	a5,8000431e <dirlookup+0x54>
    800042f2:	a8a5                	j	8000436a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042f4:	00004517          	auipc	a0,0x4
    800042f8:	3fc50513          	addi	a0,a0,1020 # 800086f0 <syscalls+0x1a0>
    800042fc:	ffffc097          	auipc	ra,0xffffc
    80004300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004304:	00004517          	auipc	a0,0x4
    80004308:	40450513          	addi	a0,a0,1028 # 80008708 <syscalls+0x1b8>
    8000430c:	ffffc097          	auipc	ra,0xffffc
    80004310:	232080e7          	jalr	562(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004314:	24c1                	addiw	s1,s1,16
    80004316:	04c92783          	lw	a5,76(s2)
    8000431a:	04f4f763          	bgeu	s1,a5,80004368 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000431e:	4741                	li	a4,16
    80004320:	86a6                	mv	a3,s1
    80004322:	fc040613          	addi	a2,s0,-64
    80004326:	4581                	li	a1,0
    80004328:	854a                	mv	a0,s2
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	d70080e7          	jalr	-656(ra) # 8000409a <readi>
    80004332:	47c1                	li	a5,16
    80004334:	fcf518e3          	bne	a0,a5,80004304 <dirlookup+0x3a>
    if(de.inum == 0)
    80004338:	fc045783          	lhu	a5,-64(s0)
    8000433c:	dfe1                	beqz	a5,80004314 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000433e:	fc240593          	addi	a1,s0,-62
    80004342:	854e                	mv	a0,s3
    80004344:	00000097          	auipc	ra,0x0
    80004348:	f6c080e7          	jalr	-148(ra) # 800042b0 <namecmp>
    8000434c:	f561                	bnez	a0,80004314 <dirlookup+0x4a>
      if(poff)
    8000434e:	000a0463          	beqz	s4,80004356 <dirlookup+0x8c>
        *poff = off;
    80004352:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004356:	fc045583          	lhu	a1,-64(s0)
    8000435a:	00092503          	lw	a0,0(s2)
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	754080e7          	jalr	1876(ra) # 80003ab2 <iget>
    80004366:	a011                	j	8000436a <dirlookup+0xa0>
  return 0;
    80004368:	4501                	li	a0,0
}
    8000436a:	70e2                	ld	ra,56(sp)
    8000436c:	7442                	ld	s0,48(sp)
    8000436e:	74a2                	ld	s1,40(sp)
    80004370:	7902                	ld	s2,32(sp)
    80004372:	69e2                	ld	s3,24(sp)
    80004374:	6a42                	ld	s4,16(sp)
    80004376:	6121                	addi	sp,sp,64
    80004378:	8082                	ret

000000008000437a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000437a:	711d                	addi	sp,sp,-96
    8000437c:	ec86                	sd	ra,88(sp)
    8000437e:	e8a2                	sd	s0,80(sp)
    80004380:	e4a6                	sd	s1,72(sp)
    80004382:	e0ca                	sd	s2,64(sp)
    80004384:	fc4e                	sd	s3,56(sp)
    80004386:	f852                	sd	s4,48(sp)
    80004388:	f456                	sd	s5,40(sp)
    8000438a:	f05a                	sd	s6,32(sp)
    8000438c:	ec5e                	sd	s7,24(sp)
    8000438e:	e862                	sd	s8,16(sp)
    80004390:	e466                	sd	s9,8(sp)
    80004392:	1080                	addi	s0,sp,96
    80004394:	84aa                	mv	s1,a0
    80004396:	8b2e                	mv	s6,a1
    80004398:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000439a:	00054703          	lbu	a4,0(a0)
    8000439e:	02f00793          	li	a5,47
    800043a2:	02f70363          	beq	a4,a5,800043c8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043a6:	ffffe097          	auipc	ra,0xffffe
    800043aa:	a68080e7          	jalr	-1432(ra) # 80001e0e <myproc>
    800043ae:	17053503          	ld	a0,368(a0)
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	9f6080e7          	jalr	-1546(ra) # 80003da8 <idup>
    800043ba:	89aa                	mv	s3,a0
  while(*path == '/')
    800043bc:	02f00913          	li	s2,47
  len = path - s;
    800043c0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043c2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043c4:	4c05                	li	s8,1
    800043c6:	a865                	j	8000447e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043c8:	4585                	li	a1,1
    800043ca:	4505                	li	a0,1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	6e6080e7          	jalr	1766(ra) # 80003ab2 <iget>
    800043d4:	89aa                	mv	s3,a0
    800043d6:	b7dd                	j	800043bc <namex+0x42>
      iunlockput(ip);
    800043d8:	854e                	mv	a0,s3
    800043da:	00000097          	auipc	ra,0x0
    800043de:	c6e080e7          	jalr	-914(ra) # 80004048 <iunlockput>
      return 0;
    800043e2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043e4:	854e                	mv	a0,s3
    800043e6:	60e6                	ld	ra,88(sp)
    800043e8:	6446                	ld	s0,80(sp)
    800043ea:	64a6                	ld	s1,72(sp)
    800043ec:	6906                	ld	s2,64(sp)
    800043ee:	79e2                	ld	s3,56(sp)
    800043f0:	7a42                	ld	s4,48(sp)
    800043f2:	7aa2                	ld	s5,40(sp)
    800043f4:	7b02                	ld	s6,32(sp)
    800043f6:	6be2                	ld	s7,24(sp)
    800043f8:	6c42                	ld	s8,16(sp)
    800043fa:	6ca2                	ld	s9,8(sp)
    800043fc:	6125                	addi	sp,sp,96
    800043fe:	8082                	ret
      iunlock(ip);
    80004400:	854e                	mv	a0,s3
    80004402:	00000097          	auipc	ra,0x0
    80004406:	aa6080e7          	jalr	-1370(ra) # 80003ea8 <iunlock>
      return ip;
    8000440a:	bfe9                	j	800043e4 <namex+0x6a>
      iunlockput(ip);
    8000440c:	854e                	mv	a0,s3
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	c3a080e7          	jalr	-966(ra) # 80004048 <iunlockput>
      return 0;
    80004416:	89d2                	mv	s3,s4
    80004418:	b7f1                	j	800043e4 <namex+0x6a>
  len = path - s;
    8000441a:	40b48633          	sub	a2,s1,a1
    8000441e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004422:	094cd463          	bge	s9,s4,800044aa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004426:	4639                	li	a2,14
    80004428:	8556                	mv	a0,s5
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	93a080e7          	jalr	-1734(ra) # 80000d64 <memmove>
  while(*path == '/')
    80004432:	0004c783          	lbu	a5,0(s1)
    80004436:	01279763          	bne	a5,s2,80004444 <namex+0xca>
    path++;
    8000443a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000443c:	0004c783          	lbu	a5,0(s1)
    80004440:	ff278de3          	beq	a5,s2,8000443a <namex+0xc0>
    ilock(ip);
    80004444:	854e                	mv	a0,s3
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	9a0080e7          	jalr	-1632(ra) # 80003de6 <ilock>
    if(ip->type != T_DIR){
    8000444e:	04499783          	lh	a5,68(s3)
    80004452:	f98793e3          	bne	a5,s8,800043d8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004456:	000b0563          	beqz	s6,80004460 <namex+0xe6>
    8000445a:	0004c783          	lbu	a5,0(s1)
    8000445e:	d3cd                	beqz	a5,80004400 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004460:	865e                	mv	a2,s7
    80004462:	85d6                	mv	a1,s5
    80004464:	854e                	mv	a0,s3
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	e64080e7          	jalr	-412(ra) # 800042ca <dirlookup>
    8000446e:	8a2a                	mv	s4,a0
    80004470:	dd51                	beqz	a0,8000440c <namex+0x92>
    iunlockput(ip);
    80004472:	854e                	mv	a0,s3
    80004474:	00000097          	auipc	ra,0x0
    80004478:	bd4080e7          	jalr	-1068(ra) # 80004048 <iunlockput>
    ip = next;
    8000447c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000447e:	0004c783          	lbu	a5,0(s1)
    80004482:	05279763          	bne	a5,s2,800044d0 <namex+0x156>
    path++;
    80004486:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004488:	0004c783          	lbu	a5,0(s1)
    8000448c:	ff278de3          	beq	a5,s2,80004486 <namex+0x10c>
  if(*path == 0)
    80004490:	c79d                	beqz	a5,800044be <namex+0x144>
    path++;
    80004492:	85a6                	mv	a1,s1
  len = path - s;
    80004494:	8a5e                	mv	s4,s7
    80004496:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004498:	01278963          	beq	a5,s2,800044aa <namex+0x130>
    8000449c:	dfbd                	beqz	a5,8000441a <namex+0xa0>
    path++;
    8000449e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044a0:	0004c783          	lbu	a5,0(s1)
    800044a4:	ff279ce3          	bne	a5,s2,8000449c <namex+0x122>
    800044a8:	bf8d                	j	8000441a <namex+0xa0>
    memmove(name, s, len);
    800044aa:	2601                	sext.w	a2,a2
    800044ac:	8556                	mv	a0,s5
    800044ae:	ffffd097          	auipc	ra,0xffffd
    800044b2:	8b6080e7          	jalr	-1866(ra) # 80000d64 <memmove>
    name[len] = 0;
    800044b6:	9a56                	add	s4,s4,s5
    800044b8:	000a0023          	sb	zero,0(s4)
    800044bc:	bf9d                	j	80004432 <namex+0xb8>
  if(nameiparent){
    800044be:	f20b03e3          	beqz	s6,800043e4 <namex+0x6a>
    iput(ip);
    800044c2:	854e                	mv	a0,s3
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	adc080e7          	jalr	-1316(ra) # 80003fa0 <iput>
    return 0;
    800044cc:	4981                	li	s3,0
    800044ce:	bf19                	j	800043e4 <namex+0x6a>
  if(*path == 0)
    800044d0:	d7fd                	beqz	a5,800044be <namex+0x144>
  while(*path != '/' && *path != 0)
    800044d2:	0004c783          	lbu	a5,0(s1)
    800044d6:	85a6                	mv	a1,s1
    800044d8:	b7d1                	j	8000449c <namex+0x122>

00000000800044da <dirlink>:
{
    800044da:	7139                	addi	sp,sp,-64
    800044dc:	fc06                	sd	ra,56(sp)
    800044de:	f822                	sd	s0,48(sp)
    800044e0:	f426                	sd	s1,40(sp)
    800044e2:	f04a                	sd	s2,32(sp)
    800044e4:	ec4e                	sd	s3,24(sp)
    800044e6:	e852                	sd	s4,16(sp)
    800044e8:	0080                	addi	s0,sp,64
    800044ea:	892a                	mv	s2,a0
    800044ec:	8a2e                	mv	s4,a1
    800044ee:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044f0:	4601                	li	a2,0
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	dd8080e7          	jalr	-552(ra) # 800042ca <dirlookup>
    800044fa:	e93d                	bnez	a0,80004570 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044fc:	04c92483          	lw	s1,76(s2)
    80004500:	c49d                	beqz	s1,8000452e <dirlink+0x54>
    80004502:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004504:	4741                	li	a4,16
    80004506:	86a6                	mv	a3,s1
    80004508:	fc040613          	addi	a2,s0,-64
    8000450c:	4581                	li	a1,0
    8000450e:	854a                	mv	a0,s2
    80004510:	00000097          	auipc	ra,0x0
    80004514:	b8a080e7          	jalr	-1142(ra) # 8000409a <readi>
    80004518:	47c1                	li	a5,16
    8000451a:	06f51163          	bne	a0,a5,8000457c <dirlink+0xa2>
    if(de.inum == 0)
    8000451e:	fc045783          	lhu	a5,-64(s0)
    80004522:	c791                	beqz	a5,8000452e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004524:	24c1                	addiw	s1,s1,16
    80004526:	04c92783          	lw	a5,76(s2)
    8000452a:	fcf4ede3          	bltu	s1,a5,80004504 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000452e:	4639                	li	a2,14
    80004530:	85d2                	mv	a1,s4
    80004532:	fc240513          	addi	a0,s0,-62
    80004536:	ffffd097          	auipc	ra,0xffffd
    8000453a:	8e2080e7          	jalr	-1822(ra) # 80000e18 <strncpy>
  de.inum = inum;
    8000453e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004542:	4741                	li	a4,16
    80004544:	86a6                	mv	a3,s1
    80004546:	fc040613          	addi	a2,s0,-64
    8000454a:	4581                	li	a1,0
    8000454c:	854a                	mv	a0,s2
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	c44080e7          	jalr	-956(ra) # 80004192 <writei>
    80004556:	872a                	mv	a4,a0
    80004558:	47c1                	li	a5,16
  return 0;
    8000455a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000455c:	02f71863          	bne	a4,a5,8000458c <dirlink+0xb2>
}
    80004560:	70e2                	ld	ra,56(sp)
    80004562:	7442                	ld	s0,48(sp)
    80004564:	74a2                	ld	s1,40(sp)
    80004566:	7902                	ld	s2,32(sp)
    80004568:	69e2                	ld	s3,24(sp)
    8000456a:	6a42                	ld	s4,16(sp)
    8000456c:	6121                	addi	sp,sp,64
    8000456e:	8082                	ret
    iput(ip);
    80004570:	00000097          	auipc	ra,0x0
    80004574:	a30080e7          	jalr	-1488(ra) # 80003fa0 <iput>
    return -1;
    80004578:	557d                	li	a0,-1
    8000457a:	b7dd                	j	80004560 <dirlink+0x86>
      panic("dirlink read");
    8000457c:	00004517          	auipc	a0,0x4
    80004580:	19c50513          	addi	a0,a0,412 # 80008718 <syscalls+0x1c8>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	fba080e7          	jalr	-70(ra) # 8000053e <panic>
    panic("dirlink");
    8000458c:	00004517          	auipc	a0,0x4
    80004590:	29c50513          	addi	a0,a0,668 # 80008828 <syscalls+0x2d8>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>

000000008000459c <namei>:

struct inode*
namei(char *path)
{
    8000459c:	1101                	addi	sp,sp,-32
    8000459e:	ec06                	sd	ra,24(sp)
    800045a0:	e822                	sd	s0,16(sp)
    800045a2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045a4:	fe040613          	addi	a2,s0,-32
    800045a8:	4581                	li	a1,0
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	dd0080e7          	jalr	-560(ra) # 8000437a <namex>
}
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045ba:	1141                	addi	sp,sp,-16
    800045bc:	e406                	sd	ra,8(sp)
    800045be:	e022                	sd	s0,0(sp)
    800045c0:	0800                	addi	s0,sp,16
    800045c2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045c4:	4585                	li	a1,1
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	db4080e7          	jalr	-588(ra) # 8000437a <namex>
}
    800045ce:	60a2                	ld	ra,8(sp)
    800045d0:	6402                	ld	s0,0(sp)
    800045d2:	0141                	addi	sp,sp,16
    800045d4:	8082                	ret

00000000800045d6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045d6:	1101                	addi	sp,sp,-32
    800045d8:	ec06                	sd	ra,24(sp)
    800045da:	e822                	sd	s0,16(sp)
    800045dc:	e426                	sd	s1,8(sp)
    800045de:	e04a                	sd	s2,0(sp)
    800045e0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045e2:	00016917          	auipc	s2,0x16
    800045e6:	05e90913          	addi	s2,s2,94 # 8001a640 <log>
    800045ea:	01892583          	lw	a1,24(s2)
    800045ee:	02892503          	lw	a0,40(s2)
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	ff2080e7          	jalr	-14(ra) # 800035e4 <bread>
    800045fa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045fc:	02c92683          	lw	a3,44(s2)
    80004600:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004602:	02d05763          	blez	a3,80004630 <write_head+0x5a>
    80004606:	00016797          	auipc	a5,0x16
    8000460a:	06a78793          	addi	a5,a5,106 # 8001a670 <log+0x30>
    8000460e:	05c50713          	addi	a4,a0,92
    80004612:	36fd                	addiw	a3,a3,-1
    80004614:	1682                	slli	a3,a3,0x20
    80004616:	9281                	srli	a3,a3,0x20
    80004618:	068a                	slli	a3,a3,0x2
    8000461a:	00016617          	auipc	a2,0x16
    8000461e:	05a60613          	addi	a2,a2,90 # 8001a674 <log+0x34>
    80004622:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004624:	4390                	lw	a2,0(a5)
    80004626:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004628:	0791                	addi	a5,a5,4
    8000462a:	0711                	addi	a4,a4,4
    8000462c:	fed79ce3          	bne	a5,a3,80004624 <write_head+0x4e>
  }
  bwrite(buf);
    80004630:	8526                	mv	a0,s1
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	0a4080e7          	jalr	164(ra) # 800036d6 <bwrite>
  brelse(buf);
    8000463a:	8526                	mv	a0,s1
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	0d8080e7          	jalr	216(ra) # 80003714 <brelse>
}
    80004644:	60e2                	ld	ra,24(sp)
    80004646:	6442                	ld	s0,16(sp)
    80004648:	64a2                	ld	s1,8(sp)
    8000464a:	6902                	ld	s2,0(sp)
    8000464c:	6105                	addi	sp,sp,32
    8000464e:	8082                	ret

0000000080004650 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004650:	00016797          	auipc	a5,0x16
    80004654:	01c7a783          	lw	a5,28(a5) # 8001a66c <log+0x2c>
    80004658:	0af05d63          	blez	a5,80004712 <install_trans+0xc2>
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	e456                	sd	s5,8(sp)
    8000466c:	e05a                	sd	s6,0(sp)
    8000466e:	0080                	addi	s0,sp,64
    80004670:	8b2a                	mv	s6,a0
    80004672:	00016a97          	auipc	s5,0x16
    80004676:	ffea8a93          	addi	s5,s5,-2 # 8001a670 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000467c:	00016997          	auipc	s3,0x16
    80004680:	fc498993          	addi	s3,s3,-60 # 8001a640 <log>
    80004684:	a035                	j	800046b0 <install_trans+0x60>
      bunpin(dbuf);
    80004686:	8526                	mv	a0,s1
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	166080e7          	jalr	358(ra) # 800037ee <bunpin>
    brelse(lbuf);
    80004690:	854a                	mv	a0,s2
    80004692:	fffff097          	auipc	ra,0xfffff
    80004696:	082080e7          	jalr	130(ra) # 80003714 <brelse>
    brelse(dbuf);
    8000469a:	8526                	mv	a0,s1
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	078080e7          	jalr	120(ra) # 80003714 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a4:	2a05                	addiw	s4,s4,1
    800046a6:	0a91                	addi	s5,s5,4
    800046a8:	02c9a783          	lw	a5,44(s3)
    800046ac:	04fa5963          	bge	s4,a5,800046fe <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046b0:	0189a583          	lw	a1,24(s3)
    800046b4:	014585bb          	addw	a1,a1,s4
    800046b8:	2585                	addiw	a1,a1,1
    800046ba:	0289a503          	lw	a0,40(s3)
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	f26080e7          	jalr	-218(ra) # 800035e4 <bread>
    800046c6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046c8:	000aa583          	lw	a1,0(s5)
    800046cc:	0289a503          	lw	a0,40(s3)
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	f14080e7          	jalr	-236(ra) # 800035e4 <bread>
    800046d8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046da:	40000613          	li	a2,1024
    800046de:	05890593          	addi	a1,s2,88
    800046e2:	05850513          	addi	a0,a0,88
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	67e080e7          	jalr	1662(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046ee:	8526                	mv	a0,s1
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	fe6080e7          	jalr	-26(ra) # 800036d6 <bwrite>
    if(recovering == 0)
    800046f8:	f80b1ce3          	bnez	s6,80004690 <install_trans+0x40>
    800046fc:	b769                	j	80004686 <install_trans+0x36>
}
    800046fe:	70e2                	ld	ra,56(sp)
    80004700:	7442                	ld	s0,48(sp)
    80004702:	74a2                	ld	s1,40(sp)
    80004704:	7902                	ld	s2,32(sp)
    80004706:	69e2                	ld	s3,24(sp)
    80004708:	6a42                	ld	s4,16(sp)
    8000470a:	6aa2                	ld	s5,8(sp)
    8000470c:	6b02                	ld	s6,0(sp)
    8000470e:	6121                	addi	sp,sp,64
    80004710:	8082                	ret
    80004712:	8082                	ret

0000000080004714 <initlog>:
{
    80004714:	7179                	addi	sp,sp,-48
    80004716:	f406                	sd	ra,40(sp)
    80004718:	f022                	sd	s0,32(sp)
    8000471a:	ec26                	sd	s1,24(sp)
    8000471c:	e84a                	sd	s2,16(sp)
    8000471e:	e44e                	sd	s3,8(sp)
    80004720:	1800                	addi	s0,sp,48
    80004722:	892a                	mv	s2,a0
    80004724:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004726:	00016497          	auipc	s1,0x16
    8000472a:	f1a48493          	addi	s1,s1,-230 # 8001a640 <log>
    8000472e:	00004597          	auipc	a1,0x4
    80004732:	ffa58593          	addi	a1,a1,-6 # 80008728 <syscalls+0x1d8>
    80004736:	8526                	mv	a0,s1
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	41c080e7          	jalr	1052(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004740:	0149a583          	lw	a1,20(s3)
    80004744:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004746:	0109a783          	lw	a5,16(s3)
    8000474a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000474c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004750:	854a                	mv	a0,s2
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	e92080e7          	jalr	-366(ra) # 800035e4 <bread>
  log.lh.n = lh->n;
    8000475a:	4d3c                	lw	a5,88(a0)
    8000475c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000475e:	02f05563          	blez	a5,80004788 <initlog+0x74>
    80004762:	05c50713          	addi	a4,a0,92
    80004766:	00016697          	auipc	a3,0x16
    8000476a:	f0a68693          	addi	a3,a3,-246 # 8001a670 <log+0x30>
    8000476e:	37fd                	addiw	a5,a5,-1
    80004770:	1782                	slli	a5,a5,0x20
    80004772:	9381                	srli	a5,a5,0x20
    80004774:	078a                	slli	a5,a5,0x2
    80004776:	06050613          	addi	a2,a0,96
    8000477a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000477c:	4310                	lw	a2,0(a4)
    8000477e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004780:	0711                	addi	a4,a4,4
    80004782:	0691                	addi	a3,a3,4
    80004784:	fef71ce3          	bne	a4,a5,8000477c <initlog+0x68>
  brelse(buf);
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	f8c080e7          	jalr	-116(ra) # 80003714 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004790:	4505                	li	a0,1
    80004792:	00000097          	auipc	ra,0x0
    80004796:	ebe080e7          	jalr	-322(ra) # 80004650 <install_trans>
  log.lh.n = 0;
    8000479a:	00016797          	auipc	a5,0x16
    8000479e:	ec07a923          	sw	zero,-302(a5) # 8001a66c <log+0x2c>
  write_head(); // clear the log
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	e34080e7          	jalr	-460(ra) # 800045d6 <write_head>
}
    800047aa:	70a2                	ld	ra,40(sp)
    800047ac:	7402                	ld	s0,32(sp)
    800047ae:	64e2                	ld	s1,24(sp)
    800047b0:	6942                	ld	s2,16(sp)
    800047b2:	69a2                	ld	s3,8(sp)
    800047b4:	6145                	addi	sp,sp,48
    800047b6:	8082                	ret

00000000800047b8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047b8:	1101                	addi	sp,sp,-32
    800047ba:	ec06                	sd	ra,24(sp)
    800047bc:	e822                	sd	s0,16(sp)
    800047be:	e426                	sd	s1,8(sp)
    800047c0:	e04a                	sd	s2,0(sp)
    800047c2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047c4:	00016517          	auipc	a0,0x16
    800047c8:	e7c50513          	addi	a0,a0,-388 # 8001a640 <log>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	418080e7          	jalr	1048(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047d4:	00016497          	auipc	s1,0x16
    800047d8:	e6c48493          	addi	s1,s1,-404 # 8001a640 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047dc:	4979                	li	s2,30
    800047de:	a039                	j	800047ec <begin_op+0x34>
      sleep(&log, &log.lock);
    800047e0:	85a6                	mv	a1,s1
    800047e2:	8526                	mv	a0,s1
    800047e4:	ffffe097          	auipc	ra,0xffffe
    800047e8:	f1a080e7          	jalr	-230(ra) # 800026fe <sleep>
    if(log.committing){
    800047ec:	50dc                	lw	a5,36(s1)
    800047ee:	fbed                	bnez	a5,800047e0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047f0:	509c                	lw	a5,32(s1)
    800047f2:	0017871b          	addiw	a4,a5,1
    800047f6:	0007069b          	sext.w	a3,a4
    800047fa:	0027179b          	slliw	a5,a4,0x2
    800047fe:	9fb9                	addw	a5,a5,a4
    80004800:	0017979b          	slliw	a5,a5,0x1
    80004804:	54d8                	lw	a4,44(s1)
    80004806:	9fb9                	addw	a5,a5,a4
    80004808:	00f95963          	bge	s2,a5,8000481a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000480c:	85a6                	mv	a1,s1
    8000480e:	8526                	mv	a0,s1
    80004810:	ffffe097          	auipc	ra,0xffffe
    80004814:	eee080e7          	jalr	-274(ra) # 800026fe <sleep>
    80004818:	bfd1                	j	800047ec <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000481a:	00016517          	auipc	a0,0x16
    8000481e:	e2650513          	addi	a0,a0,-474 # 8001a640 <log>
    80004822:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	486080e7          	jalr	1158(ra) # 80000caa <release>
      break;
    }
  }
}
    8000482c:	60e2                	ld	ra,24(sp)
    8000482e:	6442                	ld	s0,16(sp)
    80004830:	64a2                	ld	s1,8(sp)
    80004832:	6902                	ld	s2,0(sp)
    80004834:	6105                	addi	sp,sp,32
    80004836:	8082                	ret

0000000080004838 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004838:	7139                	addi	sp,sp,-64
    8000483a:	fc06                	sd	ra,56(sp)
    8000483c:	f822                	sd	s0,48(sp)
    8000483e:	f426                	sd	s1,40(sp)
    80004840:	f04a                	sd	s2,32(sp)
    80004842:	ec4e                	sd	s3,24(sp)
    80004844:	e852                	sd	s4,16(sp)
    80004846:	e456                	sd	s5,8(sp)
    80004848:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000484a:	00016497          	auipc	s1,0x16
    8000484e:	df648493          	addi	s1,s1,-522 # 8001a640 <log>
    80004852:	8526                	mv	a0,s1
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	390080e7          	jalr	912(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000485c:	509c                	lw	a5,32(s1)
    8000485e:	37fd                	addiw	a5,a5,-1
    80004860:	0007891b          	sext.w	s2,a5
    80004864:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004866:	50dc                	lw	a5,36(s1)
    80004868:	efb9                	bnez	a5,800048c6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000486a:	06091663          	bnez	s2,800048d6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000486e:	00016497          	auipc	s1,0x16
    80004872:	dd248493          	addi	s1,s1,-558 # 8001a640 <log>
    80004876:	4785                	li	a5,1
    80004878:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000487a:	8526                	mv	a0,s1
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	42e080e7          	jalr	1070(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004884:	54dc                	lw	a5,44(s1)
    80004886:	06f04763          	bgtz	a5,800048f4 <end_op+0xbc>
    acquire(&log.lock);
    8000488a:	00016497          	auipc	s1,0x16
    8000488e:	db648493          	addi	s1,s1,-586 # 8001a640 <log>
    80004892:	8526                	mv	a0,s1
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	350080e7          	jalr	848(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000489c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048a0:	8526                	mv	a0,s1
    800048a2:	ffffe097          	auipc	ra,0xffffe
    800048a6:	018080e7          	jalr	24(ra) # 800028ba <wakeup>
    release(&log.lock);
    800048aa:	8526                	mv	a0,s1
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	3fe080e7          	jalr	1022(ra) # 80000caa <release>
}
    800048b4:	70e2                	ld	ra,56(sp)
    800048b6:	7442                	ld	s0,48(sp)
    800048b8:	74a2                	ld	s1,40(sp)
    800048ba:	7902                	ld	s2,32(sp)
    800048bc:	69e2                	ld	s3,24(sp)
    800048be:	6a42                	ld	s4,16(sp)
    800048c0:	6aa2                	ld	s5,8(sp)
    800048c2:	6121                	addi	sp,sp,64
    800048c4:	8082                	ret
    panic("log.committing");
    800048c6:	00004517          	auipc	a0,0x4
    800048ca:	e6a50513          	addi	a0,a0,-406 # 80008730 <syscalls+0x1e0>
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	c70080e7          	jalr	-912(ra) # 8000053e <panic>
    wakeup(&log);
    800048d6:	00016497          	auipc	s1,0x16
    800048da:	d6a48493          	addi	s1,s1,-662 # 8001a640 <log>
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffe097          	auipc	ra,0xffffe
    800048e4:	fda080e7          	jalr	-38(ra) # 800028ba <wakeup>
  release(&log.lock);
    800048e8:	8526                	mv	a0,s1
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	3c0080e7          	jalr	960(ra) # 80000caa <release>
  if(do_commit){
    800048f2:	b7c9                	j	800048b4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f4:	00016a97          	auipc	s5,0x16
    800048f8:	d7ca8a93          	addi	s5,s5,-644 # 8001a670 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048fc:	00016a17          	auipc	s4,0x16
    80004900:	d44a0a13          	addi	s4,s4,-700 # 8001a640 <log>
    80004904:	018a2583          	lw	a1,24(s4)
    80004908:	012585bb          	addw	a1,a1,s2
    8000490c:	2585                	addiw	a1,a1,1
    8000490e:	028a2503          	lw	a0,40(s4)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	cd2080e7          	jalr	-814(ra) # 800035e4 <bread>
    8000491a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000491c:	000aa583          	lw	a1,0(s5)
    80004920:	028a2503          	lw	a0,40(s4)
    80004924:	fffff097          	auipc	ra,0xfffff
    80004928:	cc0080e7          	jalr	-832(ra) # 800035e4 <bread>
    8000492c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000492e:	40000613          	li	a2,1024
    80004932:	05850593          	addi	a1,a0,88
    80004936:	05848513          	addi	a0,s1,88
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	42a080e7          	jalr	1066(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    80004942:	8526                	mv	a0,s1
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	d92080e7          	jalr	-622(ra) # 800036d6 <bwrite>
    brelse(from);
    8000494c:	854e                	mv	a0,s3
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	dc6080e7          	jalr	-570(ra) # 80003714 <brelse>
    brelse(to);
    80004956:	8526                	mv	a0,s1
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	dbc080e7          	jalr	-580(ra) # 80003714 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004960:	2905                	addiw	s2,s2,1
    80004962:	0a91                	addi	s5,s5,4
    80004964:	02ca2783          	lw	a5,44(s4)
    80004968:	f8f94ee3          	blt	s2,a5,80004904 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	c6a080e7          	jalr	-918(ra) # 800045d6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004974:	4501                	li	a0,0
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	cda080e7          	jalr	-806(ra) # 80004650 <install_trans>
    log.lh.n = 0;
    8000497e:	00016797          	auipc	a5,0x16
    80004982:	ce07a723          	sw	zero,-786(a5) # 8001a66c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	c50080e7          	jalr	-944(ra) # 800045d6 <write_head>
    8000498e:	bdf5                	j	8000488a <end_op+0x52>

0000000080004990 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004990:	1101                	addi	sp,sp,-32
    80004992:	ec06                	sd	ra,24(sp)
    80004994:	e822                	sd	s0,16(sp)
    80004996:	e426                	sd	s1,8(sp)
    80004998:	e04a                	sd	s2,0(sp)
    8000499a:	1000                	addi	s0,sp,32
    8000499c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000499e:	00016917          	auipc	s2,0x16
    800049a2:	ca290913          	addi	s2,s2,-862 # 8001a640 <log>
    800049a6:	854a                	mv	a0,s2
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	23c080e7          	jalr	572(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049b0:	02c92603          	lw	a2,44(s2)
    800049b4:	47f5                	li	a5,29
    800049b6:	06c7c563          	blt	a5,a2,80004a20 <log_write+0x90>
    800049ba:	00016797          	auipc	a5,0x16
    800049be:	ca27a783          	lw	a5,-862(a5) # 8001a65c <log+0x1c>
    800049c2:	37fd                	addiw	a5,a5,-1
    800049c4:	04f65e63          	bge	a2,a5,80004a20 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049c8:	00016797          	auipc	a5,0x16
    800049cc:	c987a783          	lw	a5,-872(a5) # 8001a660 <log+0x20>
    800049d0:	06f05063          	blez	a5,80004a30 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049d4:	4781                	li	a5,0
    800049d6:	06c05563          	blez	a2,80004a40 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049da:	44cc                	lw	a1,12(s1)
    800049dc:	00016717          	auipc	a4,0x16
    800049e0:	c9470713          	addi	a4,a4,-876 # 8001a670 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049e4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049e6:	4314                	lw	a3,0(a4)
    800049e8:	04b68c63          	beq	a3,a1,80004a40 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049ec:	2785                	addiw	a5,a5,1
    800049ee:	0711                	addi	a4,a4,4
    800049f0:	fef61be3          	bne	a2,a5,800049e6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049f4:	0621                	addi	a2,a2,8
    800049f6:	060a                	slli	a2,a2,0x2
    800049f8:	00016797          	auipc	a5,0x16
    800049fc:	c4878793          	addi	a5,a5,-952 # 8001a640 <log>
    80004a00:	963e                	add	a2,a2,a5
    80004a02:	44dc                	lw	a5,12(s1)
    80004a04:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a06:	8526                	mv	a0,s1
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	daa080e7          	jalr	-598(ra) # 800037b2 <bpin>
    log.lh.n++;
    80004a10:	00016717          	auipc	a4,0x16
    80004a14:	c3070713          	addi	a4,a4,-976 # 8001a640 <log>
    80004a18:	575c                	lw	a5,44(a4)
    80004a1a:	2785                	addiw	a5,a5,1
    80004a1c:	d75c                	sw	a5,44(a4)
    80004a1e:	a835                	j	80004a5a <log_write+0xca>
    panic("too big a transaction");
    80004a20:	00004517          	auipc	a0,0x4
    80004a24:	d2050513          	addi	a0,a0,-736 # 80008740 <syscalls+0x1f0>
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	b16080e7          	jalr	-1258(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a30:	00004517          	auipc	a0,0x4
    80004a34:	d2850513          	addi	a0,a0,-728 # 80008758 <syscalls+0x208>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	b06080e7          	jalr	-1274(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a40:	00878713          	addi	a4,a5,8
    80004a44:	00271693          	slli	a3,a4,0x2
    80004a48:	00016717          	auipc	a4,0x16
    80004a4c:	bf870713          	addi	a4,a4,-1032 # 8001a640 <log>
    80004a50:	9736                	add	a4,a4,a3
    80004a52:	44d4                	lw	a3,12(s1)
    80004a54:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a56:	faf608e3          	beq	a2,a5,80004a06 <log_write+0x76>
  }
  release(&log.lock);
    80004a5a:	00016517          	auipc	a0,0x16
    80004a5e:	be650513          	addi	a0,a0,-1050 # 8001a640 <log>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	248080e7          	jalr	584(ra) # 80000caa <release>
}
    80004a6a:	60e2                	ld	ra,24(sp)
    80004a6c:	6442                	ld	s0,16(sp)
    80004a6e:	64a2                	ld	s1,8(sp)
    80004a70:	6902                	ld	s2,0(sp)
    80004a72:	6105                	addi	sp,sp,32
    80004a74:	8082                	ret

0000000080004a76 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a76:	1101                	addi	sp,sp,-32
    80004a78:	ec06                	sd	ra,24(sp)
    80004a7a:	e822                	sd	s0,16(sp)
    80004a7c:	e426                	sd	s1,8(sp)
    80004a7e:	e04a                	sd	s2,0(sp)
    80004a80:	1000                	addi	s0,sp,32
    80004a82:	84aa                	mv	s1,a0
    80004a84:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a86:	00004597          	auipc	a1,0x4
    80004a8a:	cf258593          	addi	a1,a1,-782 # 80008778 <syscalls+0x228>
    80004a8e:	0521                	addi	a0,a0,8
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	0c4080e7          	jalr	196(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a98:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a9c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aa0:	0204a423          	sw	zero,40(s1)
}
    80004aa4:	60e2                	ld	ra,24(sp)
    80004aa6:	6442                	ld	s0,16(sp)
    80004aa8:	64a2                	ld	s1,8(sp)
    80004aaa:	6902                	ld	s2,0(sp)
    80004aac:	6105                	addi	sp,sp,32
    80004aae:	8082                	ret

0000000080004ab0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ab0:	1101                	addi	sp,sp,-32
    80004ab2:	ec06                	sd	ra,24(sp)
    80004ab4:	e822                	sd	s0,16(sp)
    80004ab6:	e426                	sd	s1,8(sp)
    80004ab8:	e04a                	sd	s2,0(sp)
    80004aba:	1000                	addi	s0,sp,32
    80004abc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004abe:	00850913          	addi	s2,a0,8
    80004ac2:	854a                	mv	a0,s2
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	120080e7          	jalr	288(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004acc:	409c                	lw	a5,0(s1)
    80004ace:	cb89                	beqz	a5,80004ae0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ad0:	85ca                	mv	a1,s2
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffe097          	auipc	ra,0xffffe
    80004ad8:	c2a080e7          	jalr	-982(ra) # 800026fe <sleep>
  while (lk->locked) {
    80004adc:	409c                	lw	a5,0(s1)
    80004ade:	fbed                	bnez	a5,80004ad0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ae0:	4785                	li	a5,1
    80004ae2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ae4:	ffffd097          	auipc	ra,0xffffd
    80004ae8:	32a080e7          	jalr	810(ra) # 80001e0e <myproc>
    80004aec:	591c                	lw	a5,48(a0)
    80004aee:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004af0:	854a                	mv	a0,s2
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	1b8080e7          	jalr	440(ra) # 80000caa <release>
}
    80004afa:	60e2                	ld	ra,24(sp)
    80004afc:	6442                	ld	s0,16(sp)
    80004afe:	64a2                	ld	s1,8(sp)
    80004b00:	6902                	ld	s2,0(sp)
    80004b02:	6105                	addi	sp,sp,32
    80004b04:	8082                	ret

0000000080004b06 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b06:	1101                	addi	sp,sp,-32
    80004b08:	ec06                	sd	ra,24(sp)
    80004b0a:	e822                	sd	s0,16(sp)
    80004b0c:	e426                	sd	s1,8(sp)
    80004b0e:	e04a                	sd	s2,0(sp)
    80004b10:	1000                	addi	s0,sp,32
    80004b12:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b14:	00850913          	addi	s2,a0,8
    80004b18:	854a                	mv	a0,s2
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	0ca080e7          	jalr	202(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b22:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b26:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffe097          	auipc	ra,0xffffe
    80004b30:	d8e080e7          	jalr	-626(ra) # 800028ba <wakeup>
  release(&lk->lk);
    80004b34:	854a                	mv	a0,s2
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	174080e7          	jalr	372(ra) # 80000caa <release>
}
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6902                	ld	s2,0(sp)
    80004b46:	6105                	addi	sp,sp,32
    80004b48:	8082                	ret

0000000080004b4a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b4a:	7179                	addi	sp,sp,-48
    80004b4c:	f406                	sd	ra,40(sp)
    80004b4e:	f022                	sd	s0,32(sp)
    80004b50:	ec26                	sd	s1,24(sp)
    80004b52:	e84a                	sd	s2,16(sp)
    80004b54:	e44e                	sd	s3,8(sp)
    80004b56:	1800                	addi	s0,sp,48
    80004b58:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b5a:	00850913          	addi	s2,a0,8
    80004b5e:	854a                	mv	a0,s2
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	084080e7          	jalr	132(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b68:	409c                	lw	a5,0(s1)
    80004b6a:	ef99                	bnez	a5,80004b88 <holdingsleep+0x3e>
    80004b6c:	4481                	li	s1,0
  release(&lk->lk);
    80004b6e:	854a                	mv	a0,s2
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	13a080e7          	jalr	314(ra) # 80000caa <release>
  return r;
}
    80004b78:	8526                	mv	a0,s1
    80004b7a:	70a2                	ld	ra,40(sp)
    80004b7c:	7402                	ld	s0,32(sp)
    80004b7e:	64e2                	ld	s1,24(sp)
    80004b80:	6942                	ld	s2,16(sp)
    80004b82:	69a2                	ld	s3,8(sp)
    80004b84:	6145                	addi	sp,sp,48
    80004b86:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b88:	0284a983          	lw	s3,40(s1)
    80004b8c:	ffffd097          	auipc	ra,0xffffd
    80004b90:	282080e7          	jalr	642(ra) # 80001e0e <myproc>
    80004b94:	5904                	lw	s1,48(a0)
    80004b96:	413484b3          	sub	s1,s1,s3
    80004b9a:	0014b493          	seqz	s1,s1
    80004b9e:	bfc1                	j	80004b6e <holdingsleep+0x24>

0000000080004ba0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ba0:	1141                	addi	sp,sp,-16
    80004ba2:	e406                	sd	ra,8(sp)
    80004ba4:	e022                	sd	s0,0(sp)
    80004ba6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ba8:	00004597          	auipc	a1,0x4
    80004bac:	be058593          	addi	a1,a1,-1056 # 80008788 <syscalls+0x238>
    80004bb0:	00016517          	auipc	a0,0x16
    80004bb4:	bd850513          	addi	a0,a0,-1064 # 8001a788 <ftable>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	f9c080e7          	jalr	-100(ra) # 80000b54 <initlock>
}
    80004bc0:	60a2                	ld	ra,8(sp)
    80004bc2:	6402                	ld	s0,0(sp)
    80004bc4:	0141                	addi	sp,sp,16
    80004bc6:	8082                	ret

0000000080004bc8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bc8:	1101                	addi	sp,sp,-32
    80004bca:	ec06                	sd	ra,24(sp)
    80004bcc:	e822                	sd	s0,16(sp)
    80004bce:	e426                	sd	s1,8(sp)
    80004bd0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bd2:	00016517          	auipc	a0,0x16
    80004bd6:	bb650513          	addi	a0,a0,-1098 # 8001a788 <ftable>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	00a080e7          	jalr	10(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004be2:	00016497          	auipc	s1,0x16
    80004be6:	bbe48493          	addi	s1,s1,-1090 # 8001a7a0 <ftable+0x18>
    80004bea:	00017717          	auipc	a4,0x17
    80004bee:	b5670713          	addi	a4,a4,-1194 # 8001b740 <ftable+0xfb8>
    if(f->ref == 0){
    80004bf2:	40dc                	lw	a5,4(s1)
    80004bf4:	cf99                	beqz	a5,80004c12 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bf6:	02848493          	addi	s1,s1,40
    80004bfa:	fee49ce3          	bne	s1,a4,80004bf2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bfe:	00016517          	auipc	a0,0x16
    80004c02:	b8a50513          	addi	a0,a0,-1142 # 8001a788 <ftable>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	0a4080e7          	jalr	164(ra) # 80000caa <release>
  return 0;
    80004c0e:	4481                	li	s1,0
    80004c10:	a819                	j	80004c26 <filealloc+0x5e>
      f->ref = 1;
    80004c12:	4785                	li	a5,1
    80004c14:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c16:	00016517          	auipc	a0,0x16
    80004c1a:	b7250513          	addi	a0,a0,-1166 # 8001a788 <ftable>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	08c080e7          	jalr	140(ra) # 80000caa <release>
}
    80004c26:	8526                	mv	a0,s1
    80004c28:	60e2                	ld	ra,24(sp)
    80004c2a:	6442                	ld	s0,16(sp)
    80004c2c:	64a2                	ld	s1,8(sp)
    80004c2e:	6105                	addi	sp,sp,32
    80004c30:	8082                	ret

0000000080004c32 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c32:	1101                	addi	sp,sp,-32
    80004c34:	ec06                	sd	ra,24(sp)
    80004c36:	e822                	sd	s0,16(sp)
    80004c38:	e426                	sd	s1,8(sp)
    80004c3a:	1000                	addi	s0,sp,32
    80004c3c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c3e:	00016517          	auipc	a0,0x16
    80004c42:	b4a50513          	addi	a0,a0,-1206 # 8001a788 <ftable>
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	f9e080e7          	jalr	-98(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c4e:	40dc                	lw	a5,4(s1)
    80004c50:	02f05263          	blez	a5,80004c74 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c54:	2785                	addiw	a5,a5,1
    80004c56:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c58:	00016517          	auipc	a0,0x16
    80004c5c:	b3050513          	addi	a0,a0,-1232 # 8001a788 <ftable>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	04a080e7          	jalr	74(ra) # 80000caa <release>
  return f;
}
    80004c68:	8526                	mv	a0,s1
    80004c6a:	60e2                	ld	ra,24(sp)
    80004c6c:	6442                	ld	s0,16(sp)
    80004c6e:	64a2                	ld	s1,8(sp)
    80004c70:	6105                	addi	sp,sp,32
    80004c72:	8082                	ret
    panic("filedup");
    80004c74:	00004517          	auipc	a0,0x4
    80004c78:	b1c50513          	addi	a0,a0,-1252 # 80008790 <syscalls+0x240>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	8c2080e7          	jalr	-1854(ra) # 8000053e <panic>

0000000080004c84 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c84:	7139                	addi	sp,sp,-64
    80004c86:	fc06                	sd	ra,56(sp)
    80004c88:	f822                	sd	s0,48(sp)
    80004c8a:	f426                	sd	s1,40(sp)
    80004c8c:	f04a                	sd	s2,32(sp)
    80004c8e:	ec4e                	sd	s3,24(sp)
    80004c90:	e852                	sd	s4,16(sp)
    80004c92:	e456                	sd	s5,8(sp)
    80004c94:	0080                	addi	s0,sp,64
    80004c96:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c98:	00016517          	auipc	a0,0x16
    80004c9c:	af050513          	addi	a0,a0,-1296 # 8001a788 <ftable>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	f44080e7          	jalr	-188(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ca8:	40dc                	lw	a5,4(s1)
    80004caa:	06f05163          	blez	a5,80004d0c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cae:	37fd                	addiw	a5,a5,-1
    80004cb0:	0007871b          	sext.w	a4,a5
    80004cb4:	c0dc                	sw	a5,4(s1)
    80004cb6:	06e04363          	bgtz	a4,80004d1c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cba:	0004a903          	lw	s2,0(s1)
    80004cbe:	0094ca83          	lbu	s5,9(s1)
    80004cc2:	0104ba03          	ld	s4,16(s1)
    80004cc6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cca:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cce:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cd2:	00016517          	auipc	a0,0x16
    80004cd6:	ab650513          	addi	a0,a0,-1354 # 8001a788 <ftable>
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	fd0080e7          	jalr	-48(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004ce2:	4785                	li	a5,1
    80004ce4:	04f90d63          	beq	s2,a5,80004d3e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ce8:	3979                	addiw	s2,s2,-2
    80004cea:	4785                	li	a5,1
    80004cec:	0527e063          	bltu	a5,s2,80004d2c <fileclose+0xa8>
    begin_op();
    80004cf0:	00000097          	auipc	ra,0x0
    80004cf4:	ac8080e7          	jalr	-1336(ra) # 800047b8 <begin_op>
    iput(ff.ip);
    80004cf8:	854e                	mv	a0,s3
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	2a6080e7          	jalr	678(ra) # 80003fa0 <iput>
    end_op();
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	b36080e7          	jalr	-1226(ra) # 80004838 <end_op>
    80004d0a:	a00d                	j	80004d2c <fileclose+0xa8>
    panic("fileclose");
    80004d0c:	00004517          	auipc	a0,0x4
    80004d10:	a8c50513          	addi	a0,a0,-1396 # 80008798 <syscalls+0x248>
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	82a080e7          	jalr	-2006(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d1c:	00016517          	auipc	a0,0x16
    80004d20:	a6c50513          	addi	a0,a0,-1428 # 8001a788 <ftable>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f86080e7          	jalr	-122(ra) # 80000caa <release>
  }
}
    80004d2c:	70e2                	ld	ra,56(sp)
    80004d2e:	7442                	ld	s0,48(sp)
    80004d30:	74a2                	ld	s1,40(sp)
    80004d32:	7902                	ld	s2,32(sp)
    80004d34:	69e2                	ld	s3,24(sp)
    80004d36:	6a42                	ld	s4,16(sp)
    80004d38:	6aa2                	ld	s5,8(sp)
    80004d3a:	6121                	addi	sp,sp,64
    80004d3c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d3e:	85d6                	mv	a1,s5
    80004d40:	8552                	mv	a0,s4
    80004d42:	00000097          	auipc	ra,0x0
    80004d46:	34c080e7          	jalr	844(ra) # 8000508e <pipeclose>
    80004d4a:	b7cd                	j	80004d2c <fileclose+0xa8>

0000000080004d4c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d4c:	715d                	addi	sp,sp,-80
    80004d4e:	e486                	sd	ra,72(sp)
    80004d50:	e0a2                	sd	s0,64(sp)
    80004d52:	fc26                	sd	s1,56(sp)
    80004d54:	f84a                	sd	s2,48(sp)
    80004d56:	f44e                	sd	s3,40(sp)
    80004d58:	0880                	addi	s0,sp,80
    80004d5a:	84aa                	mv	s1,a0
    80004d5c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	0b0080e7          	jalr	176(ra) # 80001e0e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d66:	409c                	lw	a5,0(s1)
    80004d68:	37f9                	addiw	a5,a5,-2
    80004d6a:	4705                	li	a4,1
    80004d6c:	04f76763          	bltu	a4,a5,80004dba <filestat+0x6e>
    80004d70:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d72:	6c88                	ld	a0,24(s1)
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	072080e7          	jalr	114(ra) # 80003de6 <ilock>
    stati(f->ip, &st);
    80004d7c:	fb840593          	addi	a1,s0,-72
    80004d80:	6c88                	ld	a0,24(s1)
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	2ee080e7          	jalr	750(ra) # 80004070 <stati>
    iunlock(f->ip);
    80004d8a:	6c88                	ld	a0,24(s1)
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	11c080e7          	jalr	284(ra) # 80003ea8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d94:	46e1                	li	a3,24
    80004d96:	fb840613          	addi	a2,s0,-72
    80004d9a:	85ce                	mv	a1,s3
    80004d9c:	07093503          	ld	a0,112(s2)
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	8f6080e7          	jalr	-1802(ra) # 80001696 <copyout>
    80004da8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dac:	60a6                	ld	ra,72(sp)
    80004dae:	6406                	ld	s0,64(sp)
    80004db0:	74e2                	ld	s1,56(sp)
    80004db2:	7942                	ld	s2,48(sp)
    80004db4:	79a2                	ld	s3,40(sp)
    80004db6:	6161                	addi	sp,sp,80
    80004db8:	8082                	ret
  return -1;
    80004dba:	557d                	li	a0,-1
    80004dbc:	bfc5                	j	80004dac <filestat+0x60>

0000000080004dbe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dbe:	7179                	addi	sp,sp,-48
    80004dc0:	f406                	sd	ra,40(sp)
    80004dc2:	f022                	sd	s0,32(sp)
    80004dc4:	ec26                	sd	s1,24(sp)
    80004dc6:	e84a                	sd	s2,16(sp)
    80004dc8:	e44e                	sd	s3,8(sp)
    80004dca:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dcc:	00854783          	lbu	a5,8(a0)
    80004dd0:	c3d5                	beqz	a5,80004e74 <fileread+0xb6>
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	89ae                	mv	s3,a1
    80004dd6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dd8:	411c                	lw	a5,0(a0)
    80004dda:	4705                	li	a4,1
    80004ddc:	04e78963          	beq	a5,a4,80004e2e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004de0:	470d                	li	a4,3
    80004de2:	04e78d63          	beq	a5,a4,80004e3c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004de6:	4709                	li	a4,2
    80004de8:	06e79e63          	bne	a5,a4,80004e64 <fileread+0xa6>
    ilock(f->ip);
    80004dec:	6d08                	ld	a0,24(a0)
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	ff8080e7          	jalr	-8(ra) # 80003de6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004df6:	874a                	mv	a4,s2
    80004df8:	5094                	lw	a3,32(s1)
    80004dfa:	864e                	mv	a2,s3
    80004dfc:	4585                	li	a1,1
    80004dfe:	6c88                	ld	a0,24(s1)
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	29a080e7          	jalr	666(ra) # 8000409a <readi>
    80004e08:	892a                	mv	s2,a0
    80004e0a:	00a05563          	blez	a0,80004e14 <fileread+0x56>
      f->off += r;
    80004e0e:	509c                	lw	a5,32(s1)
    80004e10:	9fa9                	addw	a5,a5,a0
    80004e12:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e14:	6c88                	ld	a0,24(s1)
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	092080e7          	jalr	146(ra) # 80003ea8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e1e:	854a                	mv	a0,s2
    80004e20:	70a2                	ld	ra,40(sp)
    80004e22:	7402                	ld	s0,32(sp)
    80004e24:	64e2                	ld	s1,24(sp)
    80004e26:	6942                	ld	s2,16(sp)
    80004e28:	69a2                	ld	s3,8(sp)
    80004e2a:	6145                	addi	sp,sp,48
    80004e2c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e2e:	6908                	ld	a0,16(a0)
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	3c8080e7          	jalr	968(ra) # 800051f8 <piperead>
    80004e38:	892a                	mv	s2,a0
    80004e3a:	b7d5                	j	80004e1e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e3c:	02451783          	lh	a5,36(a0)
    80004e40:	03079693          	slli	a3,a5,0x30
    80004e44:	92c1                	srli	a3,a3,0x30
    80004e46:	4725                	li	a4,9
    80004e48:	02d76863          	bltu	a4,a3,80004e78 <fileread+0xba>
    80004e4c:	0792                	slli	a5,a5,0x4
    80004e4e:	00016717          	auipc	a4,0x16
    80004e52:	89a70713          	addi	a4,a4,-1894 # 8001a6e8 <devsw>
    80004e56:	97ba                	add	a5,a5,a4
    80004e58:	639c                	ld	a5,0(a5)
    80004e5a:	c38d                	beqz	a5,80004e7c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e5c:	4505                	li	a0,1
    80004e5e:	9782                	jalr	a5
    80004e60:	892a                	mv	s2,a0
    80004e62:	bf75                	j	80004e1e <fileread+0x60>
    panic("fileread");
    80004e64:	00004517          	auipc	a0,0x4
    80004e68:	94450513          	addi	a0,a0,-1724 # 800087a8 <syscalls+0x258>
    80004e6c:	ffffb097          	auipc	ra,0xffffb
    80004e70:	6d2080e7          	jalr	1746(ra) # 8000053e <panic>
    return -1;
    80004e74:	597d                	li	s2,-1
    80004e76:	b765                	j	80004e1e <fileread+0x60>
      return -1;
    80004e78:	597d                	li	s2,-1
    80004e7a:	b755                	j	80004e1e <fileread+0x60>
    80004e7c:	597d                	li	s2,-1
    80004e7e:	b745                	j	80004e1e <fileread+0x60>

0000000080004e80 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e80:	715d                	addi	sp,sp,-80
    80004e82:	e486                	sd	ra,72(sp)
    80004e84:	e0a2                	sd	s0,64(sp)
    80004e86:	fc26                	sd	s1,56(sp)
    80004e88:	f84a                	sd	s2,48(sp)
    80004e8a:	f44e                	sd	s3,40(sp)
    80004e8c:	f052                	sd	s4,32(sp)
    80004e8e:	ec56                	sd	s5,24(sp)
    80004e90:	e85a                	sd	s6,16(sp)
    80004e92:	e45e                	sd	s7,8(sp)
    80004e94:	e062                	sd	s8,0(sp)
    80004e96:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e98:	00954783          	lbu	a5,9(a0)
    80004e9c:	10078663          	beqz	a5,80004fa8 <filewrite+0x128>
    80004ea0:	892a                	mv	s2,a0
    80004ea2:	8aae                	mv	s5,a1
    80004ea4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ea6:	411c                	lw	a5,0(a0)
    80004ea8:	4705                	li	a4,1
    80004eaa:	02e78263          	beq	a5,a4,80004ece <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eae:	470d                	li	a4,3
    80004eb0:	02e78663          	beq	a5,a4,80004edc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eb4:	4709                	li	a4,2
    80004eb6:	0ee79163          	bne	a5,a4,80004f98 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004eba:	0ac05d63          	blez	a2,80004f74 <filewrite+0xf4>
    int i = 0;
    80004ebe:	4981                	li	s3,0
    80004ec0:	6b05                	lui	s6,0x1
    80004ec2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ec6:	6b85                	lui	s7,0x1
    80004ec8:	c00b8b9b          	addiw	s7,s7,-1024
    80004ecc:	a861                	j	80004f64 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ece:	6908                	ld	a0,16(a0)
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	22e080e7          	jalr	558(ra) # 800050fe <pipewrite>
    80004ed8:	8a2a                	mv	s4,a0
    80004eda:	a045                	j	80004f7a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004edc:	02451783          	lh	a5,36(a0)
    80004ee0:	03079693          	slli	a3,a5,0x30
    80004ee4:	92c1                	srli	a3,a3,0x30
    80004ee6:	4725                	li	a4,9
    80004ee8:	0cd76263          	bltu	a4,a3,80004fac <filewrite+0x12c>
    80004eec:	0792                	slli	a5,a5,0x4
    80004eee:	00015717          	auipc	a4,0x15
    80004ef2:	7fa70713          	addi	a4,a4,2042 # 8001a6e8 <devsw>
    80004ef6:	97ba                	add	a5,a5,a4
    80004ef8:	679c                	ld	a5,8(a5)
    80004efa:	cbdd                	beqz	a5,80004fb0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004efc:	4505                	li	a0,1
    80004efe:	9782                	jalr	a5
    80004f00:	8a2a                	mv	s4,a0
    80004f02:	a8a5                	j	80004f7a <filewrite+0xfa>
    80004f04:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f08:	00000097          	auipc	ra,0x0
    80004f0c:	8b0080e7          	jalr	-1872(ra) # 800047b8 <begin_op>
      ilock(f->ip);
    80004f10:	01893503          	ld	a0,24(s2)
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	ed2080e7          	jalr	-302(ra) # 80003de6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f1c:	8762                	mv	a4,s8
    80004f1e:	02092683          	lw	a3,32(s2)
    80004f22:	01598633          	add	a2,s3,s5
    80004f26:	4585                	li	a1,1
    80004f28:	01893503          	ld	a0,24(s2)
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	266080e7          	jalr	614(ra) # 80004192 <writei>
    80004f34:	84aa                	mv	s1,a0
    80004f36:	00a05763          	blez	a0,80004f44 <filewrite+0xc4>
        f->off += r;
    80004f3a:	02092783          	lw	a5,32(s2)
    80004f3e:	9fa9                	addw	a5,a5,a0
    80004f40:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f44:	01893503          	ld	a0,24(s2)
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	f60080e7          	jalr	-160(ra) # 80003ea8 <iunlock>
      end_op();
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	8e8080e7          	jalr	-1816(ra) # 80004838 <end_op>

      if(r != n1){
    80004f58:	009c1f63          	bne	s8,s1,80004f76 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f5c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f60:	0149db63          	bge	s3,s4,80004f76 <filewrite+0xf6>
      int n1 = n - i;
    80004f64:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f68:	84be                	mv	s1,a5
    80004f6a:	2781                	sext.w	a5,a5
    80004f6c:	f8fb5ce3          	bge	s6,a5,80004f04 <filewrite+0x84>
    80004f70:	84de                	mv	s1,s7
    80004f72:	bf49                	j	80004f04 <filewrite+0x84>
    int i = 0;
    80004f74:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f76:	013a1f63          	bne	s4,s3,80004f94 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f7a:	8552                	mv	a0,s4
    80004f7c:	60a6                	ld	ra,72(sp)
    80004f7e:	6406                	ld	s0,64(sp)
    80004f80:	74e2                	ld	s1,56(sp)
    80004f82:	7942                	ld	s2,48(sp)
    80004f84:	79a2                	ld	s3,40(sp)
    80004f86:	7a02                	ld	s4,32(sp)
    80004f88:	6ae2                	ld	s5,24(sp)
    80004f8a:	6b42                	ld	s6,16(sp)
    80004f8c:	6ba2                	ld	s7,8(sp)
    80004f8e:	6c02                	ld	s8,0(sp)
    80004f90:	6161                	addi	sp,sp,80
    80004f92:	8082                	ret
    ret = (i == n ? n : -1);
    80004f94:	5a7d                	li	s4,-1
    80004f96:	b7d5                	j	80004f7a <filewrite+0xfa>
    panic("filewrite");
    80004f98:	00004517          	auipc	a0,0x4
    80004f9c:	82050513          	addi	a0,a0,-2016 # 800087b8 <syscalls+0x268>
    80004fa0:	ffffb097          	auipc	ra,0xffffb
    80004fa4:	59e080e7          	jalr	1438(ra) # 8000053e <panic>
    return -1;
    80004fa8:	5a7d                	li	s4,-1
    80004faa:	bfc1                	j	80004f7a <filewrite+0xfa>
      return -1;
    80004fac:	5a7d                	li	s4,-1
    80004fae:	b7f1                	j	80004f7a <filewrite+0xfa>
    80004fb0:	5a7d                	li	s4,-1
    80004fb2:	b7e1                	j	80004f7a <filewrite+0xfa>

0000000080004fb4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fb4:	7179                	addi	sp,sp,-48
    80004fb6:	f406                	sd	ra,40(sp)
    80004fb8:	f022                	sd	s0,32(sp)
    80004fba:	ec26                	sd	s1,24(sp)
    80004fbc:	e84a                	sd	s2,16(sp)
    80004fbe:	e44e                	sd	s3,8(sp)
    80004fc0:	e052                	sd	s4,0(sp)
    80004fc2:	1800                	addi	s0,sp,48
    80004fc4:	84aa                	mv	s1,a0
    80004fc6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fc8:	0005b023          	sd	zero,0(a1)
    80004fcc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fd0:	00000097          	auipc	ra,0x0
    80004fd4:	bf8080e7          	jalr	-1032(ra) # 80004bc8 <filealloc>
    80004fd8:	e088                	sd	a0,0(s1)
    80004fda:	c551                	beqz	a0,80005066 <pipealloc+0xb2>
    80004fdc:	00000097          	auipc	ra,0x0
    80004fe0:	bec080e7          	jalr	-1044(ra) # 80004bc8 <filealloc>
    80004fe4:	00aa3023          	sd	a0,0(s4)
    80004fe8:	c92d                	beqz	a0,8000505a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	b0a080e7          	jalr	-1270(ra) # 80000af4 <kalloc>
    80004ff2:	892a                	mv	s2,a0
    80004ff4:	c125                	beqz	a0,80005054 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ff6:	4985                	li	s3,1
    80004ff8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ffc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005000:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005004:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005008:	00003597          	auipc	a1,0x3
    8000500c:	7c058593          	addi	a1,a1,1984 # 800087c8 <syscalls+0x278>
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	b44080e7          	jalr	-1212(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005018:	609c                	ld	a5,0(s1)
    8000501a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000501e:	609c                	ld	a5,0(s1)
    80005020:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005024:	609c                	ld	a5,0(s1)
    80005026:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000502a:	609c                	ld	a5,0(s1)
    8000502c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005030:	000a3783          	ld	a5,0(s4)
    80005034:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005038:	000a3783          	ld	a5,0(s4)
    8000503c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005040:	000a3783          	ld	a5,0(s4)
    80005044:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005048:	000a3783          	ld	a5,0(s4)
    8000504c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005050:	4501                	li	a0,0
    80005052:	a025                	j	8000507a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005054:	6088                	ld	a0,0(s1)
    80005056:	e501                	bnez	a0,8000505e <pipealloc+0xaa>
    80005058:	a039                	j	80005066 <pipealloc+0xb2>
    8000505a:	6088                	ld	a0,0(s1)
    8000505c:	c51d                	beqz	a0,8000508a <pipealloc+0xd6>
    fileclose(*f0);
    8000505e:	00000097          	auipc	ra,0x0
    80005062:	c26080e7          	jalr	-986(ra) # 80004c84 <fileclose>
  if(*f1)
    80005066:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000506a:	557d                	li	a0,-1
  if(*f1)
    8000506c:	c799                	beqz	a5,8000507a <pipealloc+0xc6>
    fileclose(*f1);
    8000506e:	853e                	mv	a0,a5
    80005070:	00000097          	auipc	ra,0x0
    80005074:	c14080e7          	jalr	-1004(ra) # 80004c84 <fileclose>
  return -1;
    80005078:	557d                	li	a0,-1
}
    8000507a:	70a2                	ld	ra,40(sp)
    8000507c:	7402                	ld	s0,32(sp)
    8000507e:	64e2                	ld	s1,24(sp)
    80005080:	6942                	ld	s2,16(sp)
    80005082:	69a2                	ld	s3,8(sp)
    80005084:	6a02                	ld	s4,0(sp)
    80005086:	6145                	addi	sp,sp,48
    80005088:	8082                	ret
  return -1;
    8000508a:	557d                	li	a0,-1
    8000508c:	b7fd                	j	8000507a <pipealloc+0xc6>

000000008000508e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000508e:	1101                	addi	sp,sp,-32
    80005090:	ec06                	sd	ra,24(sp)
    80005092:	e822                	sd	s0,16(sp)
    80005094:	e426                	sd	s1,8(sp)
    80005096:	e04a                	sd	s2,0(sp)
    80005098:	1000                	addi	s0,sp,32
    8000509a:	84aa                	mv	s1,a0
    8000509c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
  if(writable){
    800050a6:	02090d63          	beqz	s2,800050e0 <pipeclose+0x52>
    pi->writeopen = 0;
    800050aa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050ae:	21848513          	addi	a0,s1,536
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	808080e7          	jalr	-2040(ra) # 800028ba <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050ba:	2204b783          	ld	a5,544(s1)
    800050be:	eb95                	bnez	a5,800050f2 <pipeclose+0x64>
    release(&pi->lock);
    800050c0:	8526                	mv	a0,s1
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	be8080e7          	jalr	-1048(ra) # 80000caa <release>
    kfree((char*)pi);
    800050ca:	8526                	mv	a0,s1
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	92c080e7          	jalr	-1748(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050d4:	60e2                	ld	ra,24(sp)
    800050d6:	6442                	ld	s0,16(sp)
    800050d8:	64a2                	ld	s1,8(sp)
    800050da:	6902                	ld	s2,0(sp)
    800050dc:	6105                	addi	sp,sp,32
    800050de:	8082                	ret
    pi->readopen = 0;
    800050e0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050e4:	21c48513          	addi	a0,s1,540
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	7d2080e7          	jalr	2002(ra) # 800028ba <wakeup>
    800050f0:	b7e9                	j	800050ba <pipeclose+0x2c>
    release(&pi->lock);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	bb6080e7          	jalr	-1098(ra) # 80000caa <release>
}
    800050fc:	bfe1                	j	800050d4 <pipeclose+0x46>

00000000800050fe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050fe:	7159                	addi	sp,sp,-112
    80005100:	f486                	sd	ra,104(sp)
    80005102:	f0a2                	sd	s0,96(sp)
    80005104:	eca6                	sd	s1,88(sp)
    80005106:	e8ca                	sd	s2,80(sp)
    80005108:	e4ce                	sd	s3,72(sp)
    8000510a:	e0d2                	sd	s4,64(sp)
    8000510c:	fc56                	sd	s5,56(sp)
    8000510e:	f85a                	sd	s6,48(sp)
    80005110:	f45e                	sd	s7,40(sp)
    80005112:	f062                	sd	s8,32(sp)
    80005114:	ec66                	sd	s9,24(sp)
    80005116:	1880                	addi	s0,sp,112
    80005118:	84aa                	mv	s1,a0
    8000511a:	8aae                	mv	s5,a1
    8000511c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	cf0080e7          	jalr	-784(ra) # 80001e0e <myproc>
    80005126:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005128:	8526                	mv	a0,s1
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	aba080e7          	jalr	-1350(ra) # 80000be4 <acquire>
  while(i < n){
    80005132:	0d405163          	blez	s4,800051f4 <pipewrite+0xf6>
    80005136:	8ba6                	mv	s7,s1
  int i = 0;
    80005138:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000513a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000513c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005140:	21c48c13          	addi	s8,s1,540
    80005144:	a08d                	j	800051a6 <pipewrite+0xa8>
      release(&pi->lock);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	b62080e7          	jalr	-1182(ra) # 80000caa <release>
      return -1;
    80005150:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005152:	854a                	mv	a0,s2
    80005154:	70a6                	ld	ra,104(sp)
    80005156:	7406                	ld	s0,96(sp)
    80005158:	64e6                	ld	s1,88(sp)
    8000515a:	6946                	ld	s2,80(sp)
    8000515c:	69a6                	ld	s3,72(sp)
    8000515e:	6a06                	ld	s4,64(sp)
    80005160:	7ae2                	ld	s5,56(sp)
    80005162:	7b42                	ld	s6,48(sp)
    80005164:	7ba2                	ld	s7,40(sp)
    80005166:	7c02                	ld	s8,32(sp)
    80005168:	6ce2                	ld	s9,24(sp)
    8000516a:	6165                	addi	sp,sp,112
    8000516c:	8082                	ret
      wakeup(&pi->nread);
    8000516e:	8566                	mv	a0,s9
    80005170:	ffffd097          	auipc	ra,0xffffd
    80005174:	74a080e7          	jalr	1866(ra) # 800028ba <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005178:	85de                	mv	a1,s7
    8000517a:	8562                	mv	a0,s8
    8000517c:	ffffd097          	auipc	ra,0xffffd
    80005180:	582080e7          	jalr	1410(ra) # 800026fe <sleep>
    80005184:	a839                	j	800051a2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005186:	21c4a783          	lw	a5,540(s1)
    8000518a:	0017871b          	addiw	a4,a5,1
    8000518e:	20e4ae23          	sw	a4,540(s1)
    80005192:	1ff7f793          	andi	a5,a5,511
    80005196:	97a6                	add	a5,a5,s1
    80005198:	f9f44703          	lbu	a4,-97(s0)
    8000519c:	00e78c23          	sb	a4,24(a5)
      i++;
    800051a0:	2905                	addiw	s2,s2,1
  while(i < n){
    800051a2:	03495d63          	bge	s2,s4,800051dc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051a6:	2204a783          	lw	a5,544(s1)
    800051aa:	dfd1                	beqz	a5,80005146 <pipewrite+0x48>
    800051ac:	0289a783          	lw	a5,40(s3)
    800051b0:	fbd9                	bnez	a5,80005146 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051b2:	2184a783          	lw	a5,536(s1)
    800051b6:	21c4a703          	lw	a4,540(s1)
    800051ba:	2007879b          	addiw	a5,a5,512
    800051be:	faf708e3          	beq	a4,a5,8000516e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051c2:	4685                	li	a3,1
    800051c4:	01590633          	add	a2,s2,s5
    800051c8:	f9f40593          	addi	a1,s0,-97
    800051cc:	0709b503          	ld	a0,112(s3)
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	552080e7          	jalr	1362(ra) # 80001722 <copyin>
    800051d8:	fb6517e3          	bne	a0,s6,80005186 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051dc:	21848513          	addi	a0,s1,536
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	6da080e7          	jalr	1754(ra) # 800028ba <wakeup>
  release(&pi->lock);
    800051e8:	8526                	mv	a0,s1
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	ac0080e7          	jalr	-1344(ra) # 80000caa <release>
  return i;
    800051f2:	b785                	j	80005152 <pipewrite+0x54>
  int i = 0;
    800051f4:	4901                	li	s2,0
    800051f6:	b7dd                	j	800051dc <pipewrite+0xde>

00000000800051f8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051f8:	715d                	addi	sp,sp,-80
    800051fa:	e486                	sd	ra,72(sp)
    800051fc:	e0a2                	sd	s0,64(sp)
    800051fe:	fc26                	sd	s1,56(sp)
    80005200:	f84a                	sd	s2,48(sp)
    80005202:	f44e                	sd	s3,40(sp)
    80005204:	f052                	sd	s4,32(sp)
    80005206:	ec56                	sd	s5,24(sp)
    80005208:	e85a                	sd	s6,16(sp)
    8000520a:	0880                	addi	s0,sp,80
    8000520c:	84aa                	mv	s1,a0
    8000520e:	892e                	mv	s2,a1
    80005210:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	bfc080e7          	jalr	-1028(ra) # 80001e0e <myproc>
    8000521a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000521c:	8b26                	mv	s6,s1
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	9c4080e7          	jalr	-1596(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005228:	2184a703          	lw	a4,536(s1)
    8000522c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005230:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005234:	02f71463          	bne	a4,a5,8000525c <piperead+0x64>
    80005238:	2244a783          	lw	a5,548(s1)
    8000523c:	c385                	beqz	a5,8000525c <piperead+0x64>
    if(pr->killed){
    8000523e:	028a2783          	lw	a5,40(s4)
    80005242:	ebc1                	bnez	a5,800052d2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005244:	85da                	mv	a1,s6
    80005246:	854e                	mv	a0,s3
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	4b6080e7          	jalr	1206(ra) # 800026fe <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005250:	2184a703          	lw	a4,536(s1)
    80005254:	21c4a783          	lw	a5,540(s1)
    80005258:	fef700e3          	beq	a4,a5,80005238 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000525c:	09505263          	blez	s5,800052e0 <piperead+0xe8>
    80005260:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005262:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005264:	2184a783          	lw	a5,536(s1)
    80005268:	21c4a703          	lw	a4,540(s1)
    8000526c:	02f70d63          	beq	a4,a5,800052a6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005270:	0017871b          	addiw	a4,a5,1
    80005274:	20e4ac23          	sw	a4,536(s1)
    80005278:	1ff7f793          	andi	a5,a5,511
    8000527c:	97a6                	add	a5,a5,s1
    8000527e:	0187c783          	lbu	a5,24(a5)
    80005282:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005286:	4685                	li	a3,1
    80005288:	fbf40613          	addi	a2,s0,-65
    8000528c:	85ca                	mv	a1,s2
    8000528e:	070a3503          	ld	a0,112(s4)
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	404080e7          	jalr	1028(ra) # 80001696 <copyout>
    8000529a:	01650663          	beq	a0,s6,800052a6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000529e:	2985                	addiw	s3,s3,1
    800052a0:	0905                	addi	s2,s2,1
    800052a2:	fd3a91e3          	bne	s5,s3,80005264 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052a6:	21c48513          	addi	a0,s1,540
    800052aa:	ffffd097          	auipc	ra,0xffffd
    800052ae:	610080e7          	jalr	1552(ra) # 800028ba <wakeup>
  release(&pi->lock);
    800052b2:	8526                	mv	a0,s1
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	9f6080e7          	jalr	-1546(ra) # 80000caa <release>
  return i;
}
    800052bc:	854e                	mv	a0,s3
    800052be:	60a6                	ld	ra,72(sp)
    800052c0:	6406                	ld	s0,64(sp)
    800052c2:	74e2                	ld	s1,56(sp)
    800052c4:	7942                	ld	s2,48(sp)
    800052c6:	79a2                	ld	s3,40(sp)
    800052c8:	7a02                	ld	s4,32(sp)
    800052ca:	6ae2                	ld	s5,24(sp)
    800052cc:	6b42                	ld	s6,16(sp)
    800052ce:	6161                	addi	sp,sp,80
    800052d0:	8082                	ret
      release(&pi->lock);
    800052d2:	8526                	mv	a0,s1
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	9d6080e7          	jalr	-1578(ra) # 80000caa <release>
      return -1;
    800052dc:	59fd                	li	s3,-1
    800052de:	bff9                	j	800052bc <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052e0:	4981                	li	s3,0
    800052e2:	b7d1                	j	800052a6 <piperead+0xae>

00000000800052e4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052e4:	df010113          	addi	sp,sp,-528
    800052e8:	20113423          	sd	ra,520(sp)
    800052ec:	20813023          	sd	s0,512(sp)
    800052f0:	ffa6                	sd	s1,504(sp)
    800052f2:	fbca                	sd	s2,496(sp)
    800052f4:	f7ce                	sd	s3,488(sp)
    800052f6:	f3d2                	sd	s4,480(sp)
    800052f8:	efd6                	sd	s5,472(sp)
    800052fa:	ebda                	sd	s6,464(sp)
    800052fc:	e7de                	sd	s7,456(sp)
    800052fe:	e3e2                	sd	s8,448(sp)
    80005300:	ff66                	sd	s9,440(sp)
    80005302:	fb6a                	sd	s10,432(sp)
    80005304:	f76e                	sd	s11,424(sp)
    80005306:	0c00                	addi	s0,sp,528
    80005308:	84aa                	mv	s1,a0
    8000530a:	dea43c23          	sd	a0,-520(s0)
    8000530e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	afc080e7          	jalr	-1284(ra) # 80001e0e <myproc>
    8000531a:	892a                	mv	s2,a0

  begin_op();
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	49c080e7          	jalr	1180(ra) # 800047b8 <begin_op>

  if((ip = namei(path)) == 0){
    80005324:	8526                	mv	a0,s1
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	276080e7          	jalr	630(ra) # 8000459c <namei>
    8000532e:	c92d                	beqz	a0,800053a0 <exec+0xbc>
    80005330:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	ab4080e7          	jalr	-1356(ra) # 80003de6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000533a:	04000713          	li	a4,64
    8000533e:	4681                	li	a3,0
    80005340:	e5040613          	addi	a2,s0,-432
    80005344:	4581                	li	a1,0
    80005346:	8526                	mv	a0,s1
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	d52080e7          	jalr	-686(ra) # 8000409a <readi>
    80005350:	04000793          	li	a5,64
    80005354:	00f51a63          	bne	a0,a5,80005368 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005358:	e5042703          	lw	a4,-432(s0)
    8000535c:	464c47b7          	lui	a5,0x464c4
    80005360:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005364:	04f70463          	beq	a4,a5,800053ac <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005368:	8526                	mv	a0,s1
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	cde080e7          	jalr	-802(ra) # 80004048 <iunlockput>
    end_op();
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	4c6080e7          	jalr	1222(ra) # 80004838 <end_op>
  }
  return -1;
    8000537a:	557d                	li	a0,-1
}
    8000537c:	20813083          	ld	ra,520(sp)
    80005380:	20013403          	ld	s0,512(sp)
    80005384:	74fe                	ld	s1,504(sp)
    80005386:	795e                	ld	s2,496(sp)
    80005388:	79be                	ld	s3,488(sp)
    8000538a:	7a1e                	ld	s4,480(sp)
    8000538c:	6afe                	ld	s5,472(sp)
    8000538e:	6b5e                	ld	s6,464(sp)
    80005390:	6bbe                	ld	s7,456(sp)
    80005392:	6c1e                	ld	s8,448(sp)
    80005394:	7cfa                	ld	s9,440(sp)
    80005396:	7d5a                	ld	s10,432(sp)
    80005398:	7dba                	ld	s11,424(sp)
    8000539a:	21010113          	addi	sp,sp,528
    8000539e:	8082                	ret
    end_op();
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	498080e7          	jalr	1176(ra) # 80004838 <end_op>
    return -1;
    800053a8:	557d                	li	a0,-1
    800053aa:	bfc9                	j	8000537c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053ac:	854a                	mv	a0,s2
    800053ae:	ffffd097          	auipc	ra,0xffffd
    800053b2:	b16080e7          	jalr	-1258(ra) # 80001ec4 <proc_pagetable>
    800053b6:	8baa                	mv	s7,a0
    800053b8:	d945                	beqz	a0,80005368 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ba:	e7042983          	lw	s3,-400(s0)
    800053be:	e8845783          	lhu	a5,-376(s0)
    800053c2:	c7ad                	beqz	a5,8000542c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053c4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053c8:	6c85                	lui	s9,0x1
    800053ca:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053ce:	def43823          	sd	a5,-528(s0)
    800053d2:	a42d                	j	800055fc <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053d4:	00003517          	auipc	a0,0x3
    800053d8:	3fc50513          	addi	a0,a0,1020 # 800087d0 <syscalls+0x280>
    800053dc:	ffffb097          	auipc	ra,0xffffb
    800053e0:	162080e7          	jalr	354(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053e4:	8756                	mv	a4,s5
    800053e6:	012d86bb          	addw	a3,s11,s2
    800053ea:	4581                	li	a1,0
    800053ec:	8526                	mv	a0,s1
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	cac080e7          	jalr	-852(ra) # 8000409a <readi>
    800053f6:	2501                	sext.w	a0,a0
    800053f8:	1aaa9963          	bne	s5,a0,800055aa <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800053fc:	6785                	lui	a5,0x1
    800053fe:	0127893b          	addw	s2,a5,s2
    80005402:	77fd                	lui	a5,0xfffff
    80005404:	01478a3b          	addw	s4,a5,s4
    80005408:	1f897163          	bgeu	s2,s8,800055ea <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000540c:	02091593          	slli	a1,s2,0x20
    80005410:	9181                	srli	a1,a1,0x20
    80005412:	95ea                	add	a1,a1,s10
    80005414:	855e                	mv	a0,s7
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	c7c080e7          	jalr	-900(ra) # 80001092 <walkaddr>
    8000541e:	862a                	mv	a2,a0
    if(pa == 0)
    80005420:	d955                	beqz	a0,800053d4 <exec+0xf0>
      n = PGSIZE;
    80005422:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005424:	fd9a70e3          	bgeu	s4,s9,800053e4 <exec+0x100>
      n = sz - i;
    80005428:	8ad2                	mv	s5,s4
    8000542a:	bf6d                	j	800053e4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000542c:	4901                	li	s2,0
  iunlockput(ip);
    8000542e:	8526                	mv	a0,s1
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	c18080e7          	jalr	-1000(ra) # 80004048 <iunlockput>
  end_op();
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	400080e7          	jalr	1024(ra) # 80004838 <end_op>
  p = myproc();
    80005440:	ffffd097          	auipc	ra,0xffffd
    80005444:	9ce080e7          	jalr	-1586(ra) # 80001e0e <myproc>
    80005448:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000544a:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000544e:	6785                	lui	a5,0x1
    80005450:	17fd                	addi	a5,a5,-1
    80005452:	993e                	add	s2,s2,a5
    80005454:	757d                	lui	a0,0xfffff
    80005456:	00a977b3          	and	a5,s2,a0
    8000545a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000545e:	6609                	lui	a2,0x2
    80005460:	963e                	add	a2,a2,a5
    80005462:	85be                	mv	a1,a5
    80005464:	855e                	mv	a0,s7
    80005466:	ffffc097          	auipc	ra,0xffffc
    8000546a:	fe0080e7          	jalr	-32(ra) # 80001446 <uvmalloc>
    8000546e:	8b2a                	mv	s6,a0
  ip = 0;
    80005470:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005472:	12050c63          	beqz	a0,800055aa <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005476:	75f9                	lui	a1,0xffffe
    80005478:	95aa                	add	a1,a1,a0
    8000547a:	855e                	mv	a0,s7
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	1e8080e7          	jalr	488(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    80005484:	7c7d                	lui	s8,0xfffff
    80005486:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005488:	e0043783          	ld	a5,-512(s0)
    8000548c:	6388                	ld	a0,0(a5)
    8000548e:	c535                	beqz	a0,800054fa <exec+0x216>
    80005490:	e9040993          	addi	s3,s0,-368
    80005494:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005498:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	9ee080e7          	jalr	-1554(ra) # 80000e88 <strlen>
    800054a2:	2505                	addiw	a0,a0,1
    800054a4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054a8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054ac:	13896363          	bltu	s2,s8,800055d2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054b0:	e0043d83          	ld	s11,-512(s0)
    800054b4:	000dba03          	ld	s4,0(s11)
    800054b8:	8552                	mv	a0,s4
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	9ce080e7          	jalr	-1586(ra) # 80000e88 <strlen>
    800054c2:	0015069b          	addiw	a3,a0,1
    800054c6:	8652                	mv	a2,s4
    800054c8:	85ca                	mv	a1,s2
    800054ca:	855e                	mv	a0,s7
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	1ca080e7          	jalr	458(ra) # 80001696 <copyout>
    800054d4:	10054363          	bltz	a0,800055da <exec+0x2f6>
    ustack[argc] = sp;
    800054d8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054dc:	0485                	addi	s1,s1,1
    800054de:	008d8793          	addi	a5,s11,8
    800054e2:	e0f43023          	sd	a5,-512(s0)
    800054e6:	008db503          	ld	a0,8(s11)
    800054ea:	c911                	beqz	a0,800054fe <exec+0x21a>
    if(argc >= MAXARG)
    800054ec:	09a1                	addi	s3,s3,8
    800054ee:	fb3c96e3          	bne	s9,s3,8000549a <exec+0x1b6>
  sz = sz1;
    800054f2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054f6:	4481                	li	s1,0
    800054f8:	a84d                	j	800055aa <exec+0x2c6>
  sp = sz;
    800054fa:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054fc:	4481                	li	s1,0
  ustack[argc] = 0;
    800054fe:	00349793          	slli	a5,s1,0x3
    80005502:	f9040713          	addi	a4,s0,-112
    80005506:	97ba                	add	a5,a5,a4
    80005508:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000550c:	00148693          	addi	a3,s1,1
    80005510:	068e                	slli	a3,a3,0x3
    80005512:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005516:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000551a:	01897663          	bgeu	s2,s8,80005526 <exec+0x242>
  sz = sz1;
    8000551e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005522:	4481                	li	s1,0
    80005524:	a059                	j	800055aa <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005526:	e9040613          	addi	a2,s0,-368
    8000552a:	85ca                	mv	a1,s2
    8000552c:	855e                	mv	a0,s7
    8000552e:	ffffc097          	auipc	ra,0xffffc
    80005532:	168080e7          	jalr	360(ra) # 80001696 <copyout>
    80005536:	0a054663          	bltz	a0,800055e2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000553a:	078ab783          	ld	a5,120(s5)
    8000553e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005542:	df843783          	ld	a5,-520(s0)
    80005546:	0007c703          	lbu	a4,0(a5)
    8000554a:	cf11                	beqz	a4,80005566 <exec+0x282>
    8000554c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000554e:	02f00693          	li	a3,47
    80005552:	a039                	j	80005560 <exec+0x27c>
      last = s+1;
    80005554:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005558:	0785                	addi	a5,a5,1
    8000555a:	fff7c703          	lbu	a4,-1(a5)
    8000555e:	c701                	beqz	a4,80005566 <exec+0x282>
    if(*s == '/')
    80005560:	fed71ce3          	bne	a4,a3,80005558 <exec+0x274>
    80005564:	bfc5                	j	80005554 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005566:	4641                	li	a2,16
    80005568:	df843583          	ld	a1,-520(s0)
    8000556c:	178a8513          	addi	a0,s5,376
    80005570:	ffffc097          	auipc	ra,0xffffc
    80005574:	8e6080e7          	jalr	-1818(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    80005578:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    8000557c:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005580:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005584:	078ab783          	ld	a5,120(s5)
    80005588:	e6843703          	ld	a4,-408(s0)
    8000558c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000558e:	078ab783          	ld	a5,120(s5)
    80005592:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005596:	85ea                	mv	a1,s10
    80005598:	ffffd097          	auipc	ra,0xffffd
    8000559c:	9c8080e7          	jalr	-1592(ra) # 80001f60 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055a0:	0004851b          	sext.w	a0,s1
    800055a4:	bbe1                	j	8000537c <exec+0x98>
    800055a6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055aa:	e0843583          	ld	a1,-504(s0)
    800055ae:	855e                	mv	a0,s7
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	9b0080e7          	jalr	-1616(ra) # 80001f60 <proc_freepagetable>
  if(ip){
    800055b8:	da0498e3          	bnez	s1,80005368 <exec+0x84>
  return -1;
    800055bc:	557d                	li	a0,-1
    800055be:	bb7d                	j	8000537c <exec+0x98>
    800055c0:	e1243423          	sd	s2,-504(s0)
    800055c4:	b7dd                	j	800055aa <exec+0x2c6>
    800055c6:	e1243423          	sd	s2,-504(s0)
    800055ca:	b7c5                	j	800055aa <exec+0x2c6>
    800055cc:	e1243423          	sd	s2,-504(s0)
    800055d0:	bfe9                	j	800055aa <exec+0x2c6>
  sz = sz1;
    800055d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055d6:	4481                	li	s1,0
    800055d8:	bfc9                	j	800055aa <exec+0x2c6>
  sz = sz1;
    800055da:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055de:	4481                	li	s1,0
    800055e0:	b7e9                	j	800055aa <exec+0x2c6>
  sz = sz1;
    800055e2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e6:	4481                	li	s1,0
    800055e8:	b7c9                	j	800055aa <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055ea:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055ee:	2b05                	addiw	s6,s6,1
    800055f0:	0389899b          	addiw	s3,s3,56
    800055f4:	e8845783          	lhu	a5,-376(s0)
    800055f8:	e2fb5be3          	bge	s6,a5,8000542e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055fc:	2981                	sext.w	s3,s3
    800055fe:	03800713          	li	a4,56
    80005602:	86ce                	mv	a3,s3
    80005604:	e1840613          	addi	a2,s0,-488
    80005608:	4581                	li	a1,0
    8000560a:	8526                	mv	a0,s1
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	a8e080e7          	jalr	-1394(ra) # 8000409a <readi>
    80005614:	03800793          	li	a5,56
    80005618:	f8f517e3          	bne	a0,a5,800055a6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000561c:	e1842783          	lw	a5,-488(s0)
    80005620:	4705                	li	a4,1
    80005622:	fce796e3          	bne	a5,a4,800055ee <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005626:	e4043603          	ld	a2,-448(s0)
    8000562a:	e3843783          	ld	a5,-456(s0)
    8000562e:	f8f669e3          	bltu	a2,a5,800055c0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005632:	e2843783          	ld	a5,-472(s0)
    80005636:	963e                	add	a2,a2,a5
    80005638:	f8f667e3          	bltu	a2,a5,800055c6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000563c:	85ca                	mv	a1,s2
    8000563e:	855e                	mv	a0,s7
    80005640:	ffffc097          	auipc	ra,0xffffc
    80005644:	e06080e7          	jalr	-506(ra) # 80001446 <uvmalloc>
    80005648:	e0a43423          	sd	a0,-504(s0)
    8000564c:	d141                	beqz	a0,800055cc <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000564e:	e2843d03          	ld	s10,-472(s0)
    80005652:	df043783          	ld	a5,-528(s0)
    80005656:	00fd77b3          	and	a5,s10,a5
    8000565a:	fba1                	bnez	a5,800055aa <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000565c:	e2042d83          	lw	s11,-480(s0)
    80005660:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005664:	f80c03e3          	beqz	s8,800055ea <exec+0x306>
    80005668:	8a62                	mv	s4,s8
    8000566a:	4901                	li	s2,0
    8000566c:	b345                	j	8000540c <exec+0x128>

000000008000566e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000566e:	7179                	addi	sp,sp,-48
    80005670:	f406                	sd	ra,40(sp)
    80005672:	f022                	sd	s0,32(sp)
    80005674:	ec26                	sd	s1,24(sp)
    80005676:	e84a                	sd	s2,16(sp)
    80005678:	1800                	addi	s0,sp,48
    8000567a:	892e                	mv	s2,a1
    8000567c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000567e:	fdc40593          	addi	a1,s0,-36
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	bf2080e7          	jalr	-1038(ra) # 80003274 <argint>
    8000568a:	04054063          	bltz	a0,800056ca <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000568e:	fdc42703          	lw	a4,-36(s0)
    80005692:	47bd                	li	a5,15
    80005694:	02e7ed63          	bltu	a5,a4,800056ce <argfd+0x60>
    80005698:	ffffc097          	auipc	ra,0xffffc
    8000569c:	776080e7          	jalr	1910(ra) # 80001e0e <myproc>
    800056a0:	fdc42703          	lw	a4,-36(s0)
    800056a4:	01e70793          	addi	a5,a4,30
    800056a8:	078e                	slli	a5,a5,0x3
    800056aa:	953e                	add	a0,a0,a5
    800056ac:	611c                	ld	a5,0(a0)
    800056ae:	c395                	beqz	a5,800056d2 <argfd+0x64>
    return -1;
  if(pfd)
    800056b0:	00090463          	beqz	s2,800056b8 <argfd+0x4a>
    *pfd = fd;
    800056b4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056b8:	4501                	li	a0,0
  if(pf)
    800056ba:	c091                	beqz	s1,800056be <argfd+0x50>
    *pf = f;
    800056bc:	e09c                	sd	a5,0(s1)
}
    800056be:	70a2                	ld	ra,40(sp)
    800056c0:	7402                	ld	s0,32(sp)
    800056c2:	64e2                	ld	s1,24(sp)
    800056c4:	6942                	ld	s2,16(sp)
    800056c6:	6145                	addi	sp,sp,48
    800056c8:	8082                	ret
    return -1;
    800056ca:	557d                	li	a0,-1
    800056cc:	bfcd                	j	800056be <argfd+0x50>
    return -1;
    800056ce:	557d                	li	a0,-1
    800056d0:	b7fd                	j	800056be <argfd+0x50>
    800056d2:	557d                	li	a0,-1
    800056d4:	b7ed                	j	800056be <argfd+0x50>

00000000800056d6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056d6:	1101                	addi	sp,sp,-32
    800056d8:	ec06                	sd	ra,24(sp)
    800056da:	e822                	sd	s0,16(sp)
    800056dc:	e426                	sd	s1,8(sp)
    800056de:	1000                	addi	s0,sp,32
    800056e0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056e2:	ffffc097          	auipc	ra,0xffffc
    800056e6:	72c080e7          	jalr	1836(ra) # 80001e0e <myproc>
    800056ea:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056ec:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffe00f0>
    800056f0:	4501                	li	a0,0
    800056f2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056f4:	6398                	ld	a4,0(a5)
    800056f6:	cb19                	beqz	a4,8000570c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056f8:	2505                	addiw	a0,a0,1
    800056fa:	07a1                	addi	a5,a5,8
    800056fc:	fed51ce3          	bne	a0,a3,800056f4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005700:	557d                	li	a0,-1
}
    80005702:	60e2                	ld	ra,24(sp)
    80005704:	6442                	ld	s0,16(sp)
    80005706:	64a2                	ld	s1,8(sp)
    80005708:	6105                	addi	sp,sp,32
    8000570a:	8082                	ret
      p->ofile[fd] = f;
    8000570c:	01e50793          	addi	a5,a0,30
    80005710:	078e                	slli	a5,a5,0x3
    80005712:	963e                	add	a2,a2,a5
    80005714:	e204                	sd	s1,0(a2)
      return fd;
    80005716:	b7f5                	j	80005702 <fdalloc+0x2c>

0000000080005718 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005718:	715d                	addi	sp,sp,-80
    8000571a:	e486                	sd	ra,72(sp)
    8000571c:	e0a2                	sd	s0,64(sp)
    8000571e:	fc26                	sd	s1,56(sp)
    80005720:	f84a                	sd	s2,48(sp)
    80005722:	f44e                	sd	s3,40(sp)
    80005724:	f052                	sd	s4,32(sp)
    80005726:	ec56                	sd	s5,24(sp)
    80005728:	0880                	addi	s0,sp,80
    8000572a:	89ae                	mv	s3,a1
    8000572c:	8ab2                	mv	s5,a2
    8000572e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005730:	fb040593          	addi	a1,s0,-80
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	e86080e7          	jalr	-378(ra) # 800045ba <nameiparent>
    8000573c:	892a                	mv	s2,a0
    8000573e:	12050f63          	beqz	a0,8000587c <create+0x164>
    return 0;

  ilock(dp);
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	6a4080e7          	jalr	1700(ra) # 80003de6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000574a:	4601                	li	a2,0
    8000574c:	fb040593          	addi	a1,s0,-80
    80005750:	854a                	mv	a0,s2
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	b78080e7          	jalr	-1160(ra) # 800042ca <dirlookup>
    8000575a:	84aa                	mv	s1,a0
    8000575c:	c921                	beqz	a0,800057ac <create+0x94>
    iunlockput(dp);
    8000575e:	854a                	mv	a0,s2
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	8e8080e7          	jalr	-1816(ra) # 80004048 <iunlockput>
    ilock(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	67c080e7          	jalr	1660(ra) # 80003de6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005772:	2981                	sext.w	s3,s3
    80005774:	4789                	li	a5,2
    80005776:	02f99463          	bne	s3,a5,8000579e <create+0x86>
    8000577a:	0444d783          	lhu	a5,68(s1)
    8000577e:	37f9                	addiw	a5,a5,-2
    80005780:	17c2                	slli	a5,a5,0x30
    80005782:	93c1                	srli	a5,a5,0x30
    80005784:	4705                	li	a4,1
    80005786:	00f76c63          	bltu	a4,a5,8000579e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000578a:	8526                	mv	a0,s1
    8000578c:	60a6                	ld	ra,72(sp)
    8000578e:	6406                	ld	s0,64(sp)
    80005790:	74e2                	ld	s1,56(sp)
    80005792:	7942                	ld	s2,48(sp)
    80005794:	79a2                	ld	s3,40(sp)
    80005796:	7a02                	ld	s4,32(sp)
    80005798:	6ae2                	ld	s5,24(sp)
    8000579a:	6161                	addi	sp,sp,80
    8000579c:	8082                	ret
    iunlockput(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	8a8080e7          	jalr	-1880(ra) # 80004048 <iunlockput>
    return 0;
    800057a8:	4481                	li	s1,0
    800057aa:	b7c5                	j	8000578a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057ac:	85ce                	mv	a1,s3
    800057ae:	00092503          	lw	a0,0(s2)
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	49c080e7          	jalr	1180(ra) # 80003c4e <ialloc>
    800057ba:	84aa                	mv	s1,a0
    800057bc:	c529                	beqz	a0,80005806 <create+0xee>
  ilock(ip);
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	628080e7          	jalr	1576(ra) # 80003de6 <ilock>
  ip->major = major;
    800057c6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057ca:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057ce:	4785                	li	a5,1
    800057d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	546080e7          	jalr	1350(ra) # 80003d1c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057de:	2981                	sext.w	s3,s3
    800057e0:	4785                	li	a5,1
    800057e2:	02f98a63          	beq	s3,a5,80005816 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057e6:	40d0                	lw	a2,4(s1)
    800057e8:	fb040593          	addi	a1,s0,-80
    800057ec:	854a                	mv	a0,s2
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	cec080e7          	jalr	-788(ra) # 800044da <dirlink>
    800057f6:	06054b63          	bltz	a0,8000586c <create+0x154>
  iunlockput(dp);
    800057fa:	854a                	mv	a0,s2
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	84c080e7          	jalr	-1972(ra) # 80004048 <iunlockput>
  return ip;
    80005804:	b759                	j	8000578a <create+0x72>
    panic("create: ialloc");
    80005806:	00003517          	auipc	a0,0x3
    8000580a:	fea50513          	addi	a0,a0,-22 # 800087f0 <syscalls+0x2a0>
    8000580e:	ffffb097          	auipc	ra,0xffffb
    80005812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005816:	04a95783          	lhu	a5,74(s2)
    8000581a:	2785                	addiw	a5,a5,1
    8000581c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005820:	854a                	mv	a0,s2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	4fa080e7          	jalr	1274(ra) # 80003d1c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000582a:	40d0                	lw	a2,4(s1)
    8000582c:	00003597          	auipc	a1,0x3
    80005830:	fd458593          	addi	a1,a1,-44 # 80008800 <syscalls+0x2b0>
    80005834:	8526                	mv	a0,s1
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	ca4080e7          	jalr	-860(ra) # 800044da <dirlink>
    8000583e:	00054f63          	bltz	a0,8000585c <create+0x144>
    80005842:	00492603          	lw	a2,4(s2)
    80005846:	00003597          	auipc	a1,0x3
    8000584a:	fc258593          	addi	a1,a1,-62 # 80008808 <syscalls+0x2b8>
    8000584e:	8526                	mv	a0,s1
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	c8a080e7          	jalr	-886(ra) # 800044da <dirlink>
    80005858:	f80557e3          	bgez	a0,800057e6 <create+0xce>
      panic("create dots");
    8000585c:	00003517          	auipc	a0,0x3
    80005860:	fb450513          	addi	a0,a0,-76 # 80008810 <syscalls+0x2c0>
    80005864:	ffffb097          	auipc	ra,0xffffb
    80005868:	cda080e7          	jalr	-806(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000586c:	00003517          	auipc	a0,0x3
    80005870:	fb450513          	addi	a0,a0,-76 # 80008820 <syscalls+0x2d0>
    80005874:	ffffb097          	auipc	ra,0xffffb
    80005878:	cca080e7          	jalr	-822(ra) # 8000053e <panic>
    return 0;
    8000587c:	84aa                	mv	s1,a0
    8000587e:	b731                	j	8000578a <create+0x72>

0000000080005880 <sys_dup>:
{
    80005880:	7179                	addi	sp,sp,-48
    80005882:	f406                	sd	ra,40(sp)
    80005884:	f022                	sd	s0,32(sp)
    80005886:	ec26                	sd	s1,24(sp)
    80005888:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000588a:	fd840613          	addi	a2,s0,-40
    8000588e:	4581                	li	a1,0
    80005890:	4501                	li	a0,0
    80005892:	00000097          	auipc	ra,0x0
    80005896:	ddc080e7          	jalr	-548(ra) # 8000566e <argfd>
    return -1;
    8000589a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000589c:	02054363          	bltz	a0,800058c2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058a0:	fd843503          	ld	a0,-40(s0)
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	e32080e7          	jalr	-462(ra) # 800056d6 <fdalloc>
    800058ac:	84aa                	mv	s1,a0
    return -1;
    800058ae:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058b0:	00054963          	bltz	a0,800058c2 <sys_dup+0x42>
  filedup(f);
    800058b4:	fd843503          	ld	a0,-40(s0)
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	37a080e7          	jalr	890(ra) # 80004c32 <filedup>
  return fd;
    800058c0:	87a6                	mv	a5,s1
}
    800058c2:	853e                	mv	a0,a5
    800058c4:	70a2                	ld	ra,40(sp)
    800058c6:	7402                	ld	s0,32(sp)
    800058c8:	64e2                	ld	s1,24(sp)
    800058ca:	6145                	addi	sp,sp,48
    800058cc:	8082                	ret

00000000800058ce <sys_read>:
{
    800058ce:	7179                	addi	sp,sp,-48
    800058d0:	f406                	sd	ra,40(sp)
    800058d2:	f022                	sd	s0,32(sp)
    800058d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d6:	fe840613          	addi	a2,s0,-24
    800058da:	4581                	li	a1,0
    800058dc:	4501                	li	a0,0
    800058de:	00000097          	auipc	ra,0x0
    800058e2:	d90080e7          	jalr	-624(ra) # 8000566e <argfd>
    return -1;
    800058e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058e8:	04054163          	bltz	a0,8000592a <sys_read+0x5c>
    800058ec:	fe440593          	addi	a1,s0,-28
    800058f0:	4509                	li	a0,2
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	982080e7          	jalr	-1662(ra) # 80003274 <argint>
    return -1;
    800058fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058fc:	02054763          	bltz	a0,8000592a <sys_read+0x5c>
    80005900:	fd840593          	addi	a1,s0,-40
    80005904:	4505                	li	a0,1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	990080e7          	jalr	-1648(ra) # 80003296 <argaddr>
    return -1;
    8000590e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005910:	00054d63          	bltz	a0,8000592a <sys_read+0x5c>
  return fileread(f, p, n);
    80005914:	fe442603          	lw	a2,-28(s0)
    80005918:	fd843583          	ld	a1,-40(s0)
    8000591c:	fe843503          	ld	a0,-24(s0)
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	49e080e7          	jalr	1182(ra) # 80004dbe <fileread>
    80005928:	87aa                	mv	a5,a0
}
    8000592a:	853e                	mv	a0,a5
    8000592c:	70a2                	ld	ra,40(sp)
    8000592e:	7402                	ld	s0,32(sp)
    80005930:	6145                	addi	sp,sp,48
    80005932:	8082                	ret

0000000080005934 <sys_write>:
{
    80005934:	7179                	addi	sp,sp,-48
    80005936:	f406                	sd	ra,40(sp)
    80005938:	f022                	sd	s0,32(sp)
    8000593a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000593c:	fe840613          	addi	a2,s0,-24
    80005940:	4581                	li	a1,0
    80005942:	4501                	li	a0,0
    80005944:	00000097          	auipc	ra,0x0
    80005948:	d2a080e7          	jalr	-726(ra) # 8000566e <argfd>
    return -1;
    8000594c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000594e:	04054163          	bltz	a0,80005990 <sys_write+0x5c>
    80005952:	fe440593          	addi	a1,s0,-28
    80005956:	4509                	li	a0,2
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	91c080e7          	jalr	-1764(ra) # 80003274 <argint>
    return -1;
    80005960:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005962:	02054763          	bltz	a0,80005990 <sys_write+0x5c>
    80005966:	fd840593          	addi	a1,s0,-40
    8000596a:	4505                	li	a0,1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	92a080e7          	jalr	-1750(ra) # 80003296 <argaddr>
    return -1;
    80005974:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005976:	00054d63          	bltz	a0,80005990 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000597a:	fe442603          	lw	a2,-28(s0)
    8000597e:	fd843583          	ld	a1,-40(s0)
    80005982:	fe843503          	ld	a0,-24(s0)
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	4fa080e7          	jalr	1274(ra) # 80004e80 <filewrite>
    8000598e:	87aa                	mv	a5,a0
}
    80005990:	853e                	mv	a0,a5
    80005992:	70a2                	ld	ra,40(sp)
    80005994:	7402                	ld	s0,32(sp)
    80005996:	6145                	addi	sp,sp,48
    80005998:	8082                	ret

000000008000599a <sys_close>:
{
    8000599a:	1101                	addi	sp,sp,-32
    8000599c:	ec06                	sd	ra,24(sp)
    8000599e:	e822                	sd	s0,16(sp)
    800059a0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059a2:	fe040613          	addi	a2,s0,-32
    800059a6:	fec40593          	addi	a1,s0,-20
    800059aa:	4501                	li	a0,0
    800059ac:	00000097          	auipc	ra,0x0
    800059b0:	cc2080e7          	jalr	-830(ra) # 8000566e <argfd>
    return -1;
    800059b4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059b6:	02054463          	bltz	a0,800059de <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059ba:	ffffc097          	auipc	ra,0xffffc
    800059be:	454080e7          	jalr	1108(ra) # 80001e0e <myproc>
    800059c2:	fec42783          	lw	a5,-20(s0)
    800059c6:	07f9                	addi	a5,a5,30
    800059c8:	078e                	slli	a5,a5,0x3
    800059ca:	97aa                	add	a5,a5,a0
    800059cc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059d0:	fe043503          	ld	a0,-32(s0)
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	2b0080e7          	jalr	688(ra) # 80004c84 <fileclose>
  return 0;
    800059dc:	4781                	li	a5,0
}
    800059de:	853e                	mv	a0,a5
    800059e0:	60e2                	ld	ra,24(sp)
    800059e2:	6442                	ld	s0,16(sp)
    800059e4:	6105                	addi	sp,sp,32
    800059e6:	8082                	ret

00000000800059e8 <sys_fstat>:
{
    800059e8:	1101                	addi	sp,sp,-32
    800059ea:	ec06                	sd	ra,24(sp)
    800059ec:	e822                	sd	s0,16(sp)
    800059ee:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059f0:	fe840613          	addi	a2,s0,-24
    800059f4:	4581                	li	a1,0
    800059f6:	4501                	li	a0,0
    800059f8:	00000097          	auipc	ra,0x0
    800059fc:	c76080e7          	jalr	-906(ra) # 8000566e <argfd>
    return -1;
    80005a00:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a02:	02054563          	bltz	a0,80005a2c <sys_fstat+0x44>
    80005a06:	fe040593          	addi	a1,s0,-32
    80005a0a:	4505                	li	a0,1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	88a080e7          	jalr	-1910(ra) # 80003296 <argaddr>
    return -1;
    80005a14:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a16:	00054b63          	bltz	a0,80005a2c <sys_fstat+0x44>
  return filestat(f, st);
    80005a1a:	fe043583          	ld	a1,-32(s0)
    80005a1e:	fe843503          	ld	a0,-24(s0)
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	32a080e7          	jalr	810(ra) # 80004d4c <filestat>
    80005a2a:	87aa                	mv	a5,a0
}
    80005a2c:	853e                	mv	a0,a5
    80005a2e:	60e2                	ld	ra,24(sp)
    80005a30:	6442                	ld	s0,16(sp)
    80005a32:	6105                	addi	sp,sp,32
    80005a34:	8082                	ret

0000000080005a36 <sys_link>:
{
    80005a36:	7169                	addi	sp,sp,-304
    80005a38:	f606                	sd	ra,296(sp)
    80005a3a:	f222                	sd	s0,288(sp)
    80005a3c:	ee26                	sd	s1,280(sp)
    80005a3e:	ea4a                	sd	s2,272(sp)
    80005a40:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a42:	08000613          	li	a2,128
    80005a46:	ed040593          	addi	a1,s0,-304
    80005a4a:	4501                	li	a0,0
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	86c080e7          	jalr	-1940(ra) # 800032b8 <argstr>
    return -1;
    80005a54:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a56:	10054e63          	bltz	a0,80005b72 <sys_link+0x13c>
    80005a5a:	08000613          	li	a2,128
    80005a5e:	f5040593          	addi	a1,s0,-176
    80005a62:	4505                	li	a0,1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	854080e7          	jalr	-1964(ra) # 800032b8 <argstr>
    return -1;
    80005a6c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a6e:	10054263          	bltz	a0,80005b72 <sys_link+0x13c>
  begin_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	d46080e7          	jalr	-698(ra) # 800047b8 <begin_op>
  if((ip = namei(old)) == 0){
    80005a7a:	ed040513          	addi	a0,s0,-304
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	b1e080e7          	jalr	-1250(ra) # 8000459c <namei>
    80005a86:	84aa                	mv	s1,a0
    80005a88:	c551                	beqz	a0,80005b14 <sys_link+0xde>
  ilock(ip);
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	35c080e7          	jalr	860(ra) # 80003de6 <ilock>
  if(ip->type == T_DIR){
    80005a92:	04449703          	lh	a4,68(s1)
    80005a96:	4785                	li	a5,1
    80005a98:	08f70463          	beq	a4,a5,80005b20 <sys_link+0xea>
  ip->nlink++;
    80005a9c:	04a4d783          	lhu	a5,74(s1)
    80005aa0:	2785                	addiw	a5,a5,1
    80005aa2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	274080e7          	jalr	628(ra) # 80003d1c <iupdate>
  iunlock(ip);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	3f6080e7          	jalr	1014(ra) # 80003ea8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005aba:	fd040593          	addi	a1,s0,-48
    80005abe:	f5040513          	addi	a0,s0,-176
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	af8080e7          	jalr	-1288(ra) # 800045ba <nameiparent>
    80005aca:	892a                	mv	s2,a0
    80005acc:	c935                	beqz	a0,80005b40 <sys_link+0x10a>
  ilock(dp);
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	318080e7          	jalr	792(ra) # 80003de6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ad6:	00092703          	lw	a4,0(s2)
    80005ada:	409c                	lw	a5,0(s1)
    80005adc:	04f71d63          	bne	a4,a5,80005b36 <sys_link+0x100>
    80005ae0:	40d0                	lw	a2,4(s1)
    80005ae2:	fd040593          	addi	a1,s0,-48
    80005ae6:	854a                	mv	a0,s2
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	9f2080e7          	jalr	-1550(ra) # 800044da <dirlink>
    80005af0:	04054363          	bltz	a0,80005b36 <sys_link+0x100>
  iunlockput(dp);
    80005af4:	854a                	mv	a0,s2
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	552080e7          	jalr	1362(ra) # 80004048 <iunlockput>
  iput(ip);
    80005afe:	8526                	mv	a0,s1
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	4a0080e7          	jalr	1184(ra) # 80003fa0 <iput>
  end_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	d30080e7          	jalr	-720(ra) # 80004838 <end_op>
  return 0;
    80005b10:	4781                	li	a5,0
    80005b12:	a085                	j	80005b72 <sys_link+0x13c>
    end_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	d24080e7          	jalr	-732(ra) # 80004838 <end_op>
    return -1;
    80005b1c:	57fd                	li	a5,-1
    80005b1e:	a891                	j	80005b72 <sys_link+0x13c>
    iunlockput(ip);
    80005b20:	8526                	mv	a0,s1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	526080e7          	jalr	1318(ra) # 80004048 <iunlockput>
    end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	d0e080e7          	jalr	-754(ra) # 80004838 <end_op>
    return -1;
    80005b32:	57fd                	li	a5,-1
    80005b34:	a83d                	j	80005b72 <sys_link+0x13c>
    iunlockput(dp);
    80005b36:	854a                	mv	a0,s2
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	510080e7          	jalr	1296(ra) # 80004048 <iunlockput>
  ilock(ip);
    80005b40:	8526                	mv	a0,s1
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	2a4080e7          	jalr	676(ra) # 80003de6 <ilock>
  ip->nlink--;
    80005b4a:	04a4d783          	lhu	a5,74(s1)
    80005b4e:	37fd                	addiw	a5,a5,-1
    80005b50:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	1c6080e7          	jalr	454(ra) # 80003d1c <iupdate>
  iunlockput(ip);
    80005b5e:	8526                	mv	a0,s1
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	4e8080e7          	jalr	1256(ra) # 80004048 <iunlockput>
  end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	cd0080e7          	jalr	-816(ra) # 80004838 <end_op>
  return -1;
    80005b70:	57fd                	li	a5,-1
}
    80005b72:	853e                	mv	a0,a5
    80005b74:	70b2                	ld	ra,296(sp)
    80005b76:	7412                	ld	s0,288(sp)
    80005b78:	64f2                	ld	s1,280(sp)
    80005b7a:	6952                	ld	s2,272(sp)
    80005b7c:	6155                	addi	sp,sp,304
    80005b7e:	8082                	ret

0000000080005b80 <sys_unlink>:
{
    80005b80:	7151                	addi	sp,sp,-240
    80005b82:	f586                	sd	ra,232(sp)
    80005b84:	f1a2                	sd	s0,224(sp)
    80005b86:	eda6                	sd	s1,216(sp)
    80005b88:	e9ca                	sd	s2,208(sp)
    80005b8a:	e5ce                	sd	s3,200(sp)
    80005b8c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b8e:	08000613          	li	a2,128
    80005b92:	f3040593          	addi	a1,s0,-208
    80005b96:	4501                	li	a0,0
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	720080e7          	jalr	1824(ra) # 800032b8 <argstr>
    80005ba0:	18054163          	bltz	a0,80005d22 <sys_unlink+0x1a2>
  begin_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	c14080e7          	jalr	-1004(ra) # 800047b8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bac:	fb040593          	addi	a1,s0,-80
    80005bb0:	f3040513          	addi	a0,s0,-208
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	a06080e7          	jalr	-1530(ra) # 800045ba <nameiparent>
    80005bbc:	84aa                	mv	s1,a0
    80005bbe:	c979                	beqz	a0,80005c94 <sys_unlink+0x114>
  ilock(dp);
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	226080e7          	jalr	550(ra) # 80003de6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bc8:	00003597          	auipc	a1,0x3
    80005bcc:	c3858593          	addi	a1,a1,-968 # 80008800 <syscalls+0x2b0>
    80005bd0:	fb040513          	addi	a0,s0,-80
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	6dc080e7          	jalr	1756(ra) # 800042b0 <namecmp>
    80005bdc:	14050a63          	beqz	a0,80005d30 <sys_unlink+0x1b0>
    80005be0:	00003597          	auipc	a1,0x3
    80005be4:	c2858593          	addi	a1,a1,-984 # 80008808 <syscalls+0x2b8>
    80005be8:	fb040513          	addi	a0,s0,-80
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	6c4080e7          	jalr	1732(ra) # 800042b0 <namecmp>
    80005bf4:	12050e63          	beqz	a0,80005d30 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bf8:	f2c40613          	addi	a2,s0,-212
    80005bfc:	fb040593          	addi	a1,s0,-80
    80005c00:	8526                	mv	a0,s1
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	6c8080e7          	jalr	1736(ra) # 800042ca <dirlookup>
    80005c0a:	892a                	mv	s2,a0
    80005c0c:	12050263          	beqz	a0,80005d30 <sys_unlink+0x1b0>
  ilock(ip);
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	1d6080e7          	jalr	470(ra) # 80003de6 <ilock>
  if(ip->nlink < 1)
    80005c18:	04a91783          	lh	a5,74(s2)
    80005c1c:	08f05263          	blez	a5,80005ca0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c20:	04491703          	lh	a4,68(s2)
    80005c24:	4785                	li	a5,1
    80005c26:	08f70563          	beq	a4,a5,80005cb0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c2a:	4641                	li	a2,16
    80005c2c:	4581                	li	a1,0
    80005c2e:	fc040513          	addi	a0,s0,-64
    80005c32:	ffffb097          	auipc	ra,0xffffb
    80005c36:	0d2080e7          	jalr	210(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c3a:	4741                	li	a4,16
    80005c3c:	f2c42683          	lw	a3,-212(s0)
    80005c40:	fc040613          	addi	a2,s0,-64
    80005c44:	4581                	li	a1,0
    80005c46:	8526                	mv	a0,s1
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	54a080e7          	jalr	1354(ra) # 80004192 <writei>
    80005c50:	47c1                	li	a5,16
    80005c52:	0af51563          	bne	a0,a5,80005cfc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c56:	04491703          	lh	a4,68(s2)
    80005c5a:	4785                	li	a5,1
    80005c5c:	0af70863          	beq	a4,a5,80005d0c <sys_unlink+0x18c>
  iunlockput(dp);
    80005c60:	8526                	mv	a0,s1
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	3e6080e7          	jalr	998(ra) # 80004048 <iunlockput>
  ip->nlink--;
    80005c6a:	04a95783          	lhu	a5,74(s2)
    80005c6e:	37fd                	addiw	a5,a5,-1
    80005c70:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c74:	854a                	mv	a0,s2
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	0a6080e7          	jalr	166(ra) # 80003d1c <iupdate>
  iunlockput(ip);
    80005c7e:	854a                	mv	a0,s2
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	3c8080e7          	jalr	968(ra) # 80004048 <iunlockput>
  end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	bb0080e7          	jalr	-1104(ra) # 80004838 <end_op>
  return 0;
    80005c90:	4501                	li	a0,0
    80005c92:	a84d                	j	80005d44 <sys_unlink+0x1c4>
    end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	ba4080e7          	jalr	-1116(ra) # 80004838 <end_op>
    return -1;
    80005c9c:	557d                	li	a0,-1
    80005c9e:	a05d                	j	80005d44 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ca0:	00003517          	auipc	a0,0x3
    80005ca4:	b9050513          	addi	a0,a0,-1136 # 80008830 <syscalls+0x2e0>
    80005ca8:	ffffb097          	auipc	ra,0xffffb
    80005cac:	896080e7          	jalr	-1898(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cb0:	04c92703          	lw	a4,76(s2)
    80005cb4:	02000793          	li	a5,32
    80005cb8:	f6e7f9e3          	bgeu	a5,a4,80005c2a <sys_unlink+0xaa>
    80005cbc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cc0:	4741                	li	a4,16
    80005cc2:	86ce                	mv	a3,s3
    80005cc4:	f1840613          	addi	a2,s0,-232
    80005cc8:	4581                	li	a1,0
    80005cca:	854a                	mv	a0,s2
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	3ce080e7          	jalr	974(ra) # 8000409a <readi>
    80005cd4:	47c1                	li	a5,16
    80005cd6:	00f51b63          	bne	a0,a5,80005cec <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cda:	f1845783          	lhu	a5,-232(s0)
    80005cde:	e7a1                	bnez	a5,80005d26 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ce0:	29c1                	addiw	s3,s3,16
    80005ce2:	04c92783          	lw	a5,76(s2)
    80005ce6:	fcf9ede3          	bltu	s3,a5,80005cc0 <sys_unlink+0x140>
    80005cea:	b781                	j	80005c2a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cec:	00003517          	auipc	a0,0x3
    80005cf0:	b5c50513          	addi	a0,a0,-1188 # 80008848 <syscalls+0x2f8>
    80005cf4:	ffffb097          	auipc	ra,0xffffb
    80005cf8:	84a080e7          	jalr	-1974(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005cfc:	00003517          	auipc	a0,0x3
    80005d00:	b6450513          	addi	a0,a0,-1180 # 80008860 <syscalls+0x310>
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	83a080e7          	jalr	-1990(ra) # 8000053e <panic>
    dp->nlink--;
    80005d0c:	04a4d783          	lhu	a5,74(s1)
    80005d10:	37fd                	addiw	a5,a5,-1
    80005d12:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	004080e7          	jalr	4(ra) # 80003d1c <iupdate>
    80005d20:	b781                	j	80005c60 <sys_unlink+0xe0>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	a005                	j	80005d44 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d26:	854a                	mv	a0,s2
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	320080e7          	jalr	800(ra) # 80004048 <iunlockput>
  iunlockput(dp);
    80005d30:	8526                	mv	a0,s1
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	316080e7          	jalr	790(ra) # 80004048 <iunlockput>
  end_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	afe080e7          	jalr	-1282(ra) # 80004838 <end_op>
  return -1;
    80005d42:	557d                	li	a0,-1
}
    80005d44:	70ae                	ld	ra,232(sp)
    80005d46:	740e                	ld	s0,224(sp)
    80005d48:	64ee                	ld	s1,216(sp)
    80005d4a:	694e                	ld	s2,208(sp)
    80005d4c:	69ae                	ld	s3,200(sp)
    80005d4e:	616d                	addi	sp,sp,240
    80005d50:	8082                	ret

0000000080005d52 <sys_open>:

uint64
sys_open(void)
{
    80005d52:	7131                	addi	sp,sp,-192
    80005d54:	fd06                	sd	ra,184(sp)
    80005d56:	f922                	sd	s0,176(sp)
    80005d58:	f526                	sd	s1,168(sp)
    80005d5a:	f14a                	sd	s2,160(sp)
    80005d5c:	ed4e                	sd	s3,152(sp)
    80005d5e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d60:	08000613          	li	a2,128
    80005d64:	f5040593          	addi	a1,s0,-176
    80005d68:	4501                	li	a0,0
    80005d6a:	ffffd097          	auipc	ra,0xffffd
    80005d6e:	54e080e7          	jalr	1358(ra) # 800032b8 <argstr>
    return -1;
    80005d72:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d74:	0c054163          	bltz	a0,80005e36 <sys_open+0xe4>
    80005d78:	f4c40593          	addi	a1,s0,-180
    80005d7c:	4505                	li	a0,1
    80005d7e:	ffffd097          	auipc	ra,0xffffd
    80005d82:	4f6080e7          	jalr	1270(ra) # 80003274 <argint>
    80005d86:	0a054863          	bltz	a0,80005e36 <sys_open+0xe4>

  begin_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	a2e080e7          	jalr	-1490(ra) # 800047b8 <begin_op>

  if(omode & O_CREATE){
    80005d92:	f4c42783          	lw	a5,-180(s0)
    80005d96:	2007f793          	andi	a5,a5,512
    80005d9a:	cbdd                	beqz	a5,80005e50 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d9c:	4681                	li	a3,0
    80005d9e:	4601                	li	a2,0
    80005da0:	4589                	li	a1,2
    80005da2:	f5040513          	addi	a0,s0,-176
    80005da6:	00000097          	auipc	ra,0x0
    80005daa:	972080e7          	jalr	-1678(ra) # 80005718 <create>
    80005dae:	892a                	mv	s2,a0
    if(ip == 0){
    80005db0:	c959                	beqz	a0,80005e46 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005db2:	04491703          	lh	a4,68(s2)
    80005db6:	478d                	li	a5,3
    80005db8:	00f71763          	bne	a4,a5,80005dc6 <sys_open+0x74>
    80005dbc:	04695703          	lhu	a4,70(s2)
    80005dc0:	47a5                	li	a5,9
    80005dc2:	0ce7ec63          	bltu	a5,a4,80005e9a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	e02080e7          	jalr	-510(ra) # 80004bc8 <filealloc>
    80005dce:	89aa                	mv	s3,a0
    80005dd0:	10050263          	beqz	a0,80005ed4 <sys_open+0x182>
    80005dd4:	00000097          	auipc	ra,0x0
    80005dd8:	902080e7          	jalr	-1790(ra) # 800056d6 <fdalloc>
    80005ddc:	84aa                	mv	s1,a0
    80005dde:	0e054663          	bltz	a0,80005eca <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005de2:	04491703          	lh	a4,68(s2)
    80005de6:	478d                	li	a5,3
    80005de8:	0cf70463          	beq	a4,a5,80005eb0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dec:	4789                	li	a5,2
    80005dee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005df2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005df6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dfa:	f4c42783          	lw	a5,-180(s0)
    80005dfe:	0017c713          	xori	a4,a5,1
    80005e02:	8b05                	andi	a4,a4,1
    80005e04:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e08:	0037f713          	andi	a4,a5,3
    80005e0c:	00e03733          	snez	a4,a4
    80005e10:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e14:	4007f793          	andi	a5,a5,1024
    80005e18:	c791                	beqz	a5,80005e24 <sys_open+0xd2>
    80005e1a:	04491703          	lh	a4,68(s2)
    80005e1e:	4789                	li	a5,2
    80005e20:	08f70f63          	beq	a4,a5,80005ebe <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e24:	854a                	mv	a0,s2
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	082080e7          	jalr	130(ra) # 80003ea8 <iunlock>
  end_op();
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	a0a080e7          	jalr	-1526(ra) # 80004838 <end_op>

  return fd;
}
    80005e36:	8526                	mv	a0,s1
    80005e38:	70ea                	ld	ra,184(sp)
    80005e3a:	744a                	ld	s0,176(sp)
    80005e3c:	74aa                	ld	s1,168(sp)
    80005e3e:	790a                	ld	s2,160(sp)
    80005e40:	69ea                	ld	s3,152(sp)
    80005e42:	6129                	addi	sp,sp,192
    80005e44:	8082                	ret
      end_op();
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	9f2080e7          	jalr	-1550(ra) # 80004838 <end_op>
      return -1;
    80005e4e:	b7e5                	j	80005e36 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e50:	f5040513          	addi	a0,s0,-176
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	748080e7          	jalr	1864(ra) # 8000459c <namei>
    80005e5c:	892a                	mv	s2,a0
    80005e5e:	c905                	beqz	a0,80005e8e <sys_open+0x13c>
    ilock(ip);
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	f86080e7          	jalr	-122(ra) # 80003de6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e68:	04491703          	lh	a4,68(s2)
    80005e6c:	4785                	li	a5,1
    80005e6e:	f4f712e3          	bne	a4,a5,80005db2 <sys_open+0x60>
    80005e72:	f4c42783          	lw	a5,-180(s0)
    80005e76:	dba1                	beqz	a5,80005dc6 <sys_open+0x74>
      iunlockput(ip);
    80005e78:	854a                	mv	a0,s2
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	1ce080e7          	jalr	462(ra) # 80004048 <iunlockput>
      end_op();
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	9b6080e7          	jalr	-1610(ra) # 80004838 <end_op>
      return -1;
    80005e8a:	54fd                	li	s1,-1
    80005e8c:	b76d                	j	80005e36 <sys_open+0xe4>
      end_op();
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	9aa080e7          	jalr	-1622(ra) # 80004838 <end_op>
      return -1;
    80005e96:	54fd                	li	s1,-1
    80005e98:	bf79                	j	80005e36 <sys_open+0xe4>
    iunlockput(ip);
    80005e9a:	854a                	mv	a0,s2
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	1ac080e7          	jalr	428(ra) # 80004048 <iunlockput>
    end_op();
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	994080e7          	jalr	-1644(ra) # 80004838 <end_op>
    return -1;
    80005eac:	54fd                	li	s1,-1
    80005eae:	b761                	j	80005e36 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005eb0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005eb4:	04691783          	lh	a5,70(s2)
    80005eb8:	02f99223          	sh	a5,36(s3)
    80005ebc:	bf2d                	j	80005df6 <sys_open+0xa4>
    itrunc(ip);
    80005ebe:	854a                	mv	a0,s2
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	034080e7          	jalr	52(ra) # 80003ef4 <itrunc>
    80005ec8:	bfb1                	j	80005e24 <sys_open+0xd2>
      fileclose(f);
    80005eca:	854e                	mv	a0,s3
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	db8080e7          	jalr	-584(ra) # 80004c84 <fileclose>
    iunlockput(ip);
    80005ed4:	854a                	mv	a0,s2
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	172080e7          	jalr	370(ra) # 80004048 <iunlockput>
    end_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	95a080e7          	jalr	-1702(ra) # 80004838 <end_op>
    return -1;
    80005ee6:	54fd                	li	s1,-1
    80005ee8:	b7b9                	j	80005e36 <sys_open+0xe4>

0000000080005eea <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eea:	7175                	addi	sp,sp,-144
    80005eec:	e506                	sd	ra,136(sp)
    80005eee:	e122                	sd	s0,128(sp)
    80005ef0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	8c6080e7          	jalr	-1850(ra) # 800047b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005efa:	08000613          	li	a2,128
    80005efe:	f7040593          	addi	a1,s0,-144
    80005f02:	4501                	li	a0,0
    80005f04:	ffffd097          	auipc	ra,0xffffd
    80005f08:	3b4080e7          	jalr	948(ra) # 800032b8 <argstr>
    80005f0c:	02054963          	bltz	a0,80005f3e <sys_mkdir+0x54>
    80005f10:	4681                	li	a3,0
    80005f12:	4601                	li	a2,0
    80005f14:	4585                	li	a1,1
    80005f16:	f7040513          	addi	a0,s0,-144
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	7fe080e7          	jalr	2046(ra) # 80005718 <create>
    80005f22:	cd11                	beqz	a0,80005f3e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	124080e7          	jalr	292(ra) # 80004048 <iunlockput>
  end_op();
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	90c080e7          	jalr	-1780(ra) # 80004838 <end_op>
  return 0;
    80005f34:	4501                	li	a0,0
}
    80005f36:	60aa                	ld	ra,136(sp)
    80005f38:	640a                	ld	s0,128(sp)
    80005f3a:	6149                	addi	sp,sp,144
    80005f3c:	8082                	ret
    end_op();
    80005f3e:	fffff097          	auipc	ra,0xfffff
    80005f42:	8fa080e7          	jalr	-1798(ra) # 80004838 <end_op>
    return -1;
    80005f46:	557d                	li	a0,-1
    80005f48:	b7fd                	j	80005f36 <sys_mkdir+0x4c>

0000000080005f4a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f4a:	7135                	addi	sp,sp,-160
    80005f4c:	ed06                	sd	ra,152(sp)
    80005f4e:	e922                	sd	s0,144(sp)
    80005f50:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	866080e7          	jalr	-1946(ra) # 800047b8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f5a:	08000613          	li	a2,128
    80005f5e:	f7040593          	addi	a1,s0,-144
    80005f62:	4501                	li	a0,0
    80005f64:	ffffd097          	auipc	ra,0xffffd
    80005f68:	354080e7          	jalr	852(ra) # 800032b8 <argstr>
    80005f6c:	04054a63          	bltz	a0,80005fc0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f70:	f6c40593          	addi	a1,s0,-148
    80005f74:	4505                	li	a0,1
    80005f76:	ffffd097          	auipc	ra,0xffffd
    80005f7a:	2fe080e7          	jalr	766(ra) # 80003274 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f7e:	04054163          	bltz	a0,80005fc0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f82:	f6840593          	addi	a1,s0,-152
    80005f86:	4509                	li	a0,2
    80005f88:	ffffd097          	auipc	ra,0xffffd
    80005f8c:	2ec080e7          	jalr	748(ra) # 80003274 <argint>
     argint(1, &major) < 0 ||
    80005f90:	02054863          	bltz	a0,80005fc0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f94:	f6841683          	lh	a3,-152(s0)
    80005f98:	f6c41603          	lh	a2,-148(s0)
    80005f9c:	458d                	li	a1,3
    80005f9e:	f7040513          	addi	a0,s0,-144
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	776080e7          	jalr	1910(ra) # 80005718 <create>
     argint(2, &minor) < 0 ||
    80005faa:	c919                	beqz	a0,80005fc0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	09c080e7          	jalr	156(ra) # 80004048 <iunlockput>
  end_op();
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	884080e7          	jalr	-1916(ra) # 80004838 <end_op>
  return 0;
    80005fbc:	4501                	li	a0,0
    80005fbe:	a031                	j	80005fca <sys_mknod+0x80>
    end_op();
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	878080e7          	jalr	-1928(ra) # 80004838 <end_op>
    return -1;
    80005fc8:	557d                	li	a0,-1
}
    80005fca:	60ea                	ld	ra,152(sp)
    80005fcc:	644a                	ld	s0,144(sp)
    80005fce:	610d                	addi	sp,sp,160
    80005fd0:	8082                	ret

0000000080005fd2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fd2:	7135                	addi	sp,sp,-160
    80005fd4:	ed06                	sd	ra,152(sp)
    80005fd6:	e922                	sd	s0,144(sp)
    80005fd8:	e526                	sd	s1,136(sp)
    80005fda:	e14a                	sd	s2,128(sp)
    80005fdc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fde:	ffffc097          	auipc	ra,0xffffc
    80005fe2:	e30080e7          	jalr	-464(ra) # 80001e0e <myproc>
    80005fe6:	892a                	mv	s2,a0
  
  begin_op();
    80005fe8:	ffffe097          	auipc	ra,0xffffe
    80005fec:	7d0080e7          	jalr	2000(ra) # 800047b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ff0:	08000613          	li	a2,128
    80005ff4:	f6040593          	addi	a1,s0,-160
    80005ff8:	4501                	li	a0,0
    80005ffa:	ffffd097          	auipc	ra,0xffffd
    80005ffe:	2be080e7          	jalr	702(ra) # 800032b8 <argstr>
    80006002:	04054b63          	bltz	a0,80006058 <sys_chdir+0x86>
    80006006:	f6040513          	addi	a0,s0,-160
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	592080e7          	jalr	1426(ra) # 8000459c <namei>
    80006012:	84aa                	mv	s1,a0
    80006014:	c131                	beqz	a0,80006058 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	dd0080e7          	jalr	-560(ra) # 80003de6 <ilock>
  if(ip->type != T_DIR){
    8000601e:	04449703          	lh	a4,68(s1)
    80006022:	4785                	li	a5,1
    80006024:	04f71063          	bne	a4,a5,80006064 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006028:	8526                	mv	a0,s1
    8000602a:	ffffe097          	auipc	ra,0xffffe
    8000602e:	e7e080e7          	jalr	-386(ra) # 80003ea8 <iunlock>
  iput(p->cwd);
    80006032:	17093503          	ld	a0,368(s2)
    80006036:	ffffe097          	auipc	ra,0xffffe
    8000603a:	f6a080e7          	jalr	-150(ra) # 80003fa0 <iput>
  end_op();
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	7fa080e7          	jalr	2042(ra) # 80004838 <end_op>
  p->cwd = ip;
    80006046:	16993823          	sd	s1,368(s2)
  return 0;
    8000604a:	4501                	li	a0,0
}
    8000604c:	60ea                	ld	ra,152(sp)
    8000604e:	644a                	ld	s0,144(sp)
    80006050:	64aa                	ld	s1,136(sp)
    80006052:	690a                	ld	s2,128(sp)
    80006054:	610d                	addi	sp,sp,160
    80006056:	8082                	ret
    end_op();
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	7e0080e7          	jalr	2016(ra) # 80004838 <end_op>
    return -1;
    80006060:	557d                	li	a0,-1
    80006062:	b7ed                	j	8000604c <sys_chdir+0x7a>
    iunlockput(ip);
    80006064:	8526                	mv	a0,s1
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	fe2080e7          	jalr	-30(ra) # 80004048 <iunlockput>
    end_op();
    8000606e:	ffffe097          	auipc	ra,0xffffe
    80006072:	7ca080e7          	jalr	1994(ra) # 80004838 <end_op>
    return -1;
    80006076:	557d                	li	a0,-1
    80006078:	bfd1                	j	8000604c <sys_chdir+0x7a>

000000008000607a <sys_exec>:

uint64
sys_exec(void)
{
    8000607a:	7145                	addi	sp,sp,-464
    8000607c:	e786                	sd	ra,456(sp)
    8000607e:	e3a2                	sd	s0,448(sp)
    80006080:	ff26                	sd	s1,440(sp)
    80006082:	fb4a                	sd	s2,432(sp)
    80006084:	f74e                	sd	s3,424(sp)
    80006086:	f352                	sd	s4,416(sp)
    80006088:	ef56                	sd	s5,408(sp)
    8000608a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000608c:	08000613          	li	a2,128
    80006090:	f4040593          	addi	a1,s0,-192
    80006094:	4501                	li	a0,0
    80006096:	ffffd097          	auipc	ra,0xffffd
    8000609a:	222080e7          	jalr	546(ra) # 800032b8 <argstr>
    return -1;
    8000609e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060a0:	0c054a63          	bltz	a0,80006174 <sys_exec+0xfa>
    800060a4:	e3840593          	addi	a1,s0,-456
    800060a8:	4505                	li	a0,1
    800060aa:	ffffd097          	auipc	ra,0xffffd
    800060ae:	1ec080e7          	jalr	492(ra) # 80003296 <argaddr>
    800060b2:	0c054163          	bltz	a0,80006174 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060b6:	10000613          	li	a2,256
    800060ba:	4581                	li	a1,0
    800060bc:	e4040513          	addi	a0,s0,-448
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	c44080e7          	jalr	-956(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060c8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060cc:	89a6                	mv	s3,s1
    800060ce:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060d0:	02000a13          	li	s4,32
    800060d4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060d8:	00391513          	slli	a0,s2,0x3
    800060dc:	e3040593          	addi	a1,s0,-464
    800060e0:	e3843783          	ld	a5,-456(s0)
    800060e4:	953e                	add	a0,a0,a5
    800060e6:	ffffd097          	auipc	ra,0xffffd
    800060ea:	0f4080e7          	jalr	244(ra) # 800031da <fetchaddr>
    800060ee:	02054a63          	bltz	a0,80006122 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060f2:	e3043783          	ld	a5,-464(s0)
    800060f6:	c3b9                	beqz	a5,8000613c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060f8:	ffffb097          	auipc	ra,0xffffb
    800060fc:	9fc080e7          	jalr	-1540(ra) # 80000af4 <kalloc>
    80006100:	85aa                	mv	a1,a0
    80006102:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006106:	cd11                	beqz	a0,80006122 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006108:	6605                	lui	a2,0x1
    8000610a:	e3043503          	ld	a0,-464(s0)
    8000610e:	ffffd097          	auipc	ra,0xffffd
    80006112:	11e080e7          	jalr	286(ra) # 8000322c <fetchstr>
    80006116:	00054663          	bltz	a0,80006122 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000611a:	0905                	addi	s2,s2,1
    8000611c:	09a1                	addi	s3,s3,8
    8000611e:	fb491be3          	bne	s2,s4,800060d4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006122:	10048913          	addi	s2,s1,256
    80006126:	6088                	ld	a0,0(s1)
    80006128:	c529                	beqz	a0,80006172 <sys_exec+0xf8>
    kfree(argv[i]);
    8000612a:	ffffb097          	auipc	ra,0xffffb
    8000612e:	8ce080e7          	jalr	-1842(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006132:	04a1                	addi	s1,s1,8
    80006134:	ff2499e3          	bne	s1,s2,80006126 <sys_exec+0xac>
  return -1;
    80006138:	597d                	li	s2,-1
    8000613a:	a82d                	j	80006174 <sys_exec+0xfa>
      argv[i] = 0;
    8000613c:	0a8e                	slli	s5,s5,0x3
    8000613e:	fc040793          	addi	a5,s0,-64
    80006142:	9abe                	add	s5,s5,a5
    80006144:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006148:	e4040593          	addi	a1,s0,-448
    8000614c:	f4040513          	addi	a0,s0,-192
    80006150:	fffff097          	auipc	ra,0xfffff
    80006154:	194080e7          	jalr	404(ra) # 800052e4 <exec>
    80006158:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000615a:	10048993          	addi	s3,s1,256
    8000615e:	6088                	ld	a0,0(s1)
    80006160:	c911                	beqz	a0,80006174 <sys_exec+0xfa>
    kfree(argv[i]);
    80006162:	ffffb097          	auipc	ra,0xffffb
    80006166:	896080e7          	jalr	-1898(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000616a:	04a1                	addi	s1,s1,8
    8000616c:	ff3499e3          	bne	s1,s3,8000615e <sys_exec+0xe4>
    80006170:	a011                	j	80006174 <sys_exec+0xfa>
  return -1;
    80006172:	597d                	li	s2,-1
}
    80006174:	854a                	mv	a0,s2
    80006176:	60be                	ld	ra,456(sp)
    80006178:	641e                	ld	s0,448(sp)
    8000617a:	74fa                	ld	s1,440(sp)
    8000617c:	795a                	ld	s2,432(sp)
    8000617e:	79ba                	ld	s3,424(sp)
    80006180:	7a1a                	ld	s4,416(sp)
    80006182:	6afa                	ld	s5,408(sp)
    80006184:	6179                	addi	sp,sp,464
    80006186:	8082                	ret

0000000080006188 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006188:	7139                	addi	sp,sp,-64
    8000618a:	fc06                	sd	ra,56(sp)
    8000618c:	f822                	sd	s0,48(sp)
    8000618e:	f426                	sd	s1,40(sp)
    80006190:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	c7c080e7          	jalr	-900(ra) # 80001e0e <myproc>
    8000619a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000619c:	fd840593          	addi	a1,s0,-40
    800061a0:	4501                	li	a0,0
    800061a2:	ffffd097          	auipc	ra,0xffffd
    800061a6:	0f4080e7          	jalr	244(ra) # 80003296 <argaddr>
    return -1;
    800061aa:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061ac:	0e054063          	bltz	a0,8000628c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061b0:	fc840593          	addi	a1,s0,-56
    800061b4:	fd040513          	addi	a0,s0,-48
    800061b8:	fffff097          	auipc	ra,0xfffff
    800061bc:	dfc080e7          	jalr	-516(ra) # 80004fb4 <pipealloc>
    return -1;
    800061c0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061c2:	0c054563          	bltz	a0,8000628c <sys_pipe+0x104>
  fd0 = -1;
    800061c6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061ca:	fd043503          	ld	a0,-48(s0)
    800061ce:	fffff097          	auipc	ra,0xfffff
    800061d2:	508080e7          	jalr	1288(ra) # 800056d6 <fdalloc>
    800061d6:	fca42223          	sw	a0,-60(s0)
    800061da:	08054c63          	bltz	a0,80006272 <sys_pipe+0xea>
    800061de:	fc843503          	ld	a0,-56(s0)
    800061e2:	fffff097          	auipc	ra,0xfffff
    800061e6:	4f4080e7          	jalr	1268(ra) # 800056d6 <fdalloc>
    800061ea:	fca42023          	sw	a0,-64(s0)
    800061ee:	06054863          	bltz	a0,8000625e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061f2:	4691                	li	a3,4
    800061f4:	fc440613          	addi	a2,s0,-60
    800061f8:	fd843583          	ld	a1,-40(s0)
    800061fc:	78a8                	ld	a0,112(s1)
    800061fe:	ffffb097          	auipc	ra,0xffffb
    80006202:	498080e7          	jalr	1176(ra) # 80001696 <copyout>
    80006206:	02054063          	bltz	a0,80006226 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000620a:	4691                	li	a3,4
    8000620c:	fc040613          	addi	a2,s0,-64
    80006210:	fd843583          	ld	a1,-40(s0)
    80006214:	0591                	addi	a1,a1,4
    80006216:	78a8                	ld	a0,112(s1)
    80006218:	ffffb097          	auipc	ra,0xffffb
    8000621c:	47e080e7          	jalr	1150(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006220:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006222:	06055563          	bgez	a0,8000628c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006226:	fc442783          	lw	a5,-60(s0)
    8000622a:	07f9                	addi	a5,a5,30
    8000622c:	078e                	slli	a5,a5,0x3
    8000622e:	97a6                	add	a5,a5,s1
    80006230:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006234:	fc042503          	lw	a0,-64(s0)
    80006238:	0579                	addi	a0,a0,30
    8000623a:	050e                	slli	a0,a0,0x3
    8000623c:	9526                	add	a0,a0,s1
    8000623e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006242:	fd043503          	ld	a0,-48(s0)
    80006246:	fffff097          	auipc	ra,0xfffff
    8000624a:	a3e080e7          	jalr	-1474(ra) # 80004c84 <fileclose>
    fileclose(wf);
    8000624e:	fc843503          	ld	a0,-56(s0)
    80006252:	fffff097          	auipc	ra,0xfffff
    80006256:	a32080e7          	jalr	-1486(ra) # 80004c84 <fileclose>
    return -1;
    8000625a:	57fd                	li	a5,-1
    8000625c:	a805                	j	8000628c <sys_pipe+0x104>
    if(fd0 >= 0)
    8000625e:	fc442783          	lw	a5,-60(s0)
    80006262:	0007c863          	bltz	a5,80006272 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006266:	01e78513          	addi	a0,a5,30
    8000626a:	050e                	slli	a0,a0,0x3
    8000626c:	9526                	add	a0,a0,s1
    8000626e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006272:	fd043503          	ld	a0,-48(s0)
    80006276:	fffff097          	auipc	ra,0xfffff
    8000627a:	a0e080e7          	jalr	-1522(ra) # 80004c84 <fileclose>
    fileclose(wf);
    8000627e:	fc843503          	ld	a0,-56(s0)
    80006282:	fffff097          	auipc	ra,0xfffff
    80006286:	a02080e7          	jalr	-1534(ra) # 80004c84 <fileclose>
    return -1;
    8000628a:	57fd                	li	a5,-1
}
    8000628c:	853e                	mv	a0,a5
    8000628e:	70e2                	ld	ra,56(sp)
    80006290:	7442                	ld	s0,48(sp)
    80006292:	74a2                	ld	s1,40(sp)
    80006294:	6121                	addi	sp,sp,64
    80006296:	8082                	ret
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	dc7fc0ef          	jal	ra,800030a6 <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	a6a080e7          	jalr	-1430(ra) # 80001de2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	953e                	add	a0,a0,a5
    8000639c:	00052023          	sw	zero,0(a0)
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffc097          	auipc	ra,0xffffc
    800063b4:	a32080e7          	jalr	-1486(ra) # 80001de2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5179b          	slliw	a5,a0,0xd
    800063bc:	0c201537          	lui	a0,0xc201
    800063c0:	953e                	add	a0,a0,a5
  return irq;
}
    800063c2:	4148                	lw	a0,4(a0)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	a0a080e7          	jalr	-1526(ra) # 80001de2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	06a7c963          	blt	a5,a0,80006472 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	00016797          	auipc	a5,0x16
    80006408:	bfc78793          	addi	a5,a5,-1028 # 8001c000 <disk>
    8000640c:	00a78733          	add	a4,a5,a0
    80006410:	6789                	lui	a5,0x2
    80006412:	97ba                	add	a5,a5,a4
    80006414:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006418:	e7ad                	bnez	a5,80006482 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000641a:	00451793          	slli	a5,a0,0x4
    8000641e:	00018717          	auipc	a4,0x18
    80006422:	be270713          	addi	a4,a4,-1054 # 8001e000 <disk+0x2000>
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000642e:	6314                	ld	a3,0(a4)
    80006430:	96be                	add	a3,a3,a5
    80006432:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006436:	6314                	ld	a3,0(a4)
    80006438:	96be                	add	a3,a3,a5
    8000643a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000643e:	6318                	ld	a4,0(a4)
    80006440:	97ba                	add	a5,a5,a4
    80006442:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006446:	00016797          	auipc	a5,0x16
    8000644a:	bba78793          	addi	a5,a5,-1094 # 8001c000 <disk>
    8000644e:	97aa                	add	a5,a5,a0
    80006450:	6509                	lui	a0,0x2
    80006452:	953e                	add	a0,a0,a5
    80006454:	4785                	li	a5,1
    80006456:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000645a:	00018517          	auipc	a0,0x18
    8000645e:	bbe50513          	addi	a0,a0,-1090 # 8001e018 <disk+0x2018>
    80006462:	ffffc097          	auipc	ra,0xffffc
    80006466:	458080e7          	jalr	1112(ra) # 800028ba <wakeup>
}
    8000646a:	60a2                	ld	ra,8(sp)
    8000646c:	6402                	ld	s0,0(sp)
    8000646e:	0141                	addi	sp,sp,16
    80006470:	8082                	ret
    panic("free_desc 1");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	3fe50513          	addi	a0,a0,1022 # 80008870 <syscalls+0x320>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	3fe50513          	addi	a0,a0,1022 # 80008880 <syscalls+0x330>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>

0000000080006492 <virtio_disk_init>:
{
    80006492:	1101                	addi	sp,sp,-32
    80006494:	ec06                	sd	ra,24(sp)
    80006496:	e822                	sd	s0,16(sp)
    80006498:	e426                	sd	s1,8(sp)
    8000649a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000649c:	00002597          	auipc	a1,0x2
    800064a0:	3f458593          	addi	a1,a1,1012 # 80008890 <syscalls+0x340>
    800064a4:	00018517          	auipc	a0,0x18
    800064a8:	c8450513          	addi	a0,a0,-892 # 8001e128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	6a8080e7          	jalr	1704(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	4398                	lw	a4,0(a5)
    800064ba:	2701                	sext.w	a4,a4
    800064bc:	747277b7          	lui	a5,0x74727
    800064c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064c4:	0ef71163          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064c8:	100017b7          	lui	a5,0x10001
    800064cc:	43dc                	lw	a5,4(a5)
    800064ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d0:	4705                	li	a4,1
    800064d2:	0ce79a63          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d6:	100017b7          	lui	a5,0x10001
    800064da:	479c                	lw	a5,8(a5)
    800064dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064de:	4709                	li	a4,2
    800064e0:	0ce79363          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064e4:	100017b7          	lui	a5,0x10001
    800064e8:	47d8                	lw	a4,12(a5)
    800064ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ec:	554d47b7          	lui	a5,0x554d4
    800064f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064f4:	0af71963          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	4705                	li	a4,1
    800064fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006500:	470d                	li	a4,3
    80006502:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006504:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006506:	c7ffe737          	lui	a4,0xc7ffe
    8000650a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    8000650e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006510:	2701                	sext.w	a4,a4
    80006512:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006514:	472d                	li	a4,11
    80006516:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006518:	473d                	li	a4,15
    8000651a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000651c:	6705                	lui	a4,0x1
    8000651e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006520:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006524:	5bdc                	lw	a5,52(a5)
    80006526:	2781                	sext.w	a5,a5
  if(max == 0)
    80006528:	c7d9                	beqz	a5,800065b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000652a:	471d                	li	a4,7
    8000652c:	08f77d63          	bgeu	a4,a5,800065c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006530:	100014b7          	lui	s1,0x10001
    80006534:	47a1                	li	a5,8
    80006536:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006538:	6609                	lui	a2,0x2
    8000653a:	4581                	li	a1,0
    8000653c:	00016517          	auipc	a0,0x16
    80006540:	ac450513          	addi	a0,a0,-1340 # 8001c000 <disk>
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	7c0080e7          	jalr	1984(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000654c:	00016717          	auipc	a4,0x16
    80006550:	ab470713          	addi	a4,a4,-1356 # 8001c000 <disk>
    80006554:	00c75793          	srli	a5,a4,0xc
    80006558:	2781                	sext.w	a5,a5
    8000655a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000655c:	00018797          	auipc	a5,0x18
    80006560:	aa478793          	addi	a5,a5,-1372 # 8001e000 <disk+0x2000>
    80006564:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006566:	00016717          	auipc	a4,0x16
    8000656a:	b1a70713          	addi	a4,a4,-1254 # 8001c080 <disk+0x80>
    8000656e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006570:	00017717          	auipc	a4,0x17
    80006574:	a9070713          	addi	a4,a4,-1392 # 8001d000 <disk+0x1000>
    80006578:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000657a:	4705                	li	a4,1
    8000657c:	00e78c23          	sb	a4,24(a5)
    80006580:	00e78ca3          	sb	a4,25(a5)
    80006584:	00e78d23          	sb	a4,26(a5)
    80006588:	00e78da3          	sb	a4,27(a5)
    8000658c:	00e78e23          	sb	a4,28(a5)
    80006590:	00e78ea3          	sb	a4,29(a5)
    80006594:	00e78f23          	sb	a4,30(a5)
    80006598:	00e78fa3          	sb	a4,31(a5)
}
    8000659c:	60e2                	ld	ra,24(sp)
    8000659e:	6442                	ld	s0,16(sp)
    800065a0:	64a2                	ld	s1,8(sp)
    800065a2:	6105                	addi	sp,sp,32
    800065a4:	8082                	ret
    panic("could not find virtio disk");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	2fa50513          	addi	a0,a0,762 # 800088a0 <syscalls+0x350>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	30a50513          	addi	a0,a0,778 # 800088c0 <syscalls+0x370>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	31a50513          	addi	a0,a0,794 # 800088e0 <syscalls+0x390>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800065d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065d6:	7159                	addi	sp,sp,-112
    800065d8:	f486                	sd	ra,104(sp)
    800065da:	f0a2                	sd	s0,96(sp)
    800065dc:	eca6                	sd	s1,88(sp)
    800065de:	e8ca                	sd	s2,80(sp)
    800065e0:	e4ce                	sd	s3,72(sp)
    800065e2:	e0d2                	sd	s4,64(sp)
    800065e4:	fc56                	sd	s5,56(sp)
    800065e6:	f85a                	sd	s6,48(sp)
    800065e8:	f45e                	sd	s7,40(sp)
    800065ea:	f062                	sd	s8,32(sp)
    800065ec:	ec66                	sd	s9,24(sp)
    800065ee:	e86a                	sd	s10,16(sp)
    800065f0:	1880                	addi	s0,sp,112
    800065f2:	892a                	mv	s2,a0
    800065f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065f6:	00c52c83          	lw	s9,12(a0)
    800065fa:	001c9c9b          	slliw	s9,s9,0x1
    800065fe:	1c82                	slli	s9,s9,0x20
    80006600:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006604:	00018517          	auipc	a0,0x18
    80006608:	b2450513          	addi	a0,a0,-1244 # 8001e128 <disk+0x2128>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	5d8080e7          	jalr	1496(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006614:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006616:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006618:	00016b97          	auipc	s7,0x16
    8000661c:	9e8b8b93          	addi	s7,s7,-1560 # 8001c000 <disk>
    80006620:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006622:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006624:	8a4e                	mv	s4,s3
    80006626:	a051                	j	800066aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006628:	00fb86b3          	add	a3,s7,a5
    8000662c:	96da                	add	a3,a3,s6
    8000662e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006632:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006634:	0207c563          	bltz	a5,8000665e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006638:	2485                	addiw	s1,s1,1
    8000663a:	0711                	addi	a4,a4,4
    8000663c:	25548063          	beq	s1,s5,8000687c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006640:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006642:	00018697          	auipc	a3,0x18
    80006646:	9d668693          	addi	a3,a3,-1578 # 8001e018 <disk+0x2018>
    8000664a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000664c:	0006c583          	lbu	a1,0(a3)
    80006650:	fde1                	bnez	a1,80006628 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006652:	2785                	addiw	a5,a5,1
    80006654:	0685                	addi	a3,a3,1
    80006656:	ff879be3          	bne	a5,s8,8000664c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000665a:	57fd                	li	a5,-1
    8000665c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000665e:	02905a63          	blez	s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006662:	f9042503          	lw	a0,-112(s0)
    80006666:	00000097          	auipc	ra,0x0
    8000666a:	d90080e7          	jalr	-624(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000666e:	4785                	li	a5,1
    80006670:	0297d163          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006674:	f9442503          	lw	a0,-108(s0)
    80006678:	00000097          	auipc	ra,0x0
    8000667c:	d7e080e7          	jalr	-642(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006680:	4789                	li	a5,2
    80006682:	0097d863          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006686:	f9842503          	lw	a0,-104(s0)
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	d6c080e7          	jalr	-660(ra) # 800063f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006692:	00018597          	auipc	a1,0x18
    80006696:	a9658593          	addi	a1,a1,-1386 # 8001e128 <disk+0x2128>
    8000669a:	00018517          	auipc	a0,0x18
    8000669e:	97e50513          	addi	a0,a0,-1666 # 8001e018 <disk+0x2018>
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	05c080e7          	jalr	92(ra) # 800026fe <sleep>
  for(int i = 0; i < 3; i++){
    800066aa:	f9040713          	addi	a4,s0,-112
    800066ae:	84ce                	mv	s1,s3
    800066b0:	bf41                	j	80006640 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066b2:	20058713          	addi	a4,a1,512
    800066b6:	00471693          	slli	a3,a4,0x4
    800066ba:	00016717          	auipc	a4,0x16
    800066be:	94670713          	addi	a4,a4,-1722 # 8001c000 <disk>
    800066c2:	9736                	add	a4,a4,a3
    800066c4:	4685                	li	a3,1
    800066c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ca:	20058713          	addi	a4,a1,512
    800066ce:	00471693          	slli	a3,a4,0x4
    800066d2:	00016717          	auipc	a4,0x16
    800066d6:	92e70713          	addi	a4,a4,-1746 # 8001c000 <disk>
    800066da:	9736                	add	a4,a4,a3
    800066dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e4:	7679                	lui	a2,0xffffe
    800066e6:	963e                	add	a2,a2,a5
    800066e8:	00018697          	auipc	a3,0x18
    800066ec:	91868693          	addi	a3,a3,-1768 # 8001e000 <disk+0x2000>
    800066f0:	6298                	ld	a4,0(a3)
    800066f2:	9732                	add	a4,a4,a2
    800066f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f6:	6298                	ld	a4,0(a3)
    800066f8:	9732                	add	a4,a4,a2
    800066fa:	4541                	li	a0,16
    800066fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066fe:	6298                	ld	a4,0(a3)
    80006700:	9732                	add	a4,a4,a2
    80006702:	4505                	li	a0,1
    80006704:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f9442703          	lw	a4,-108(s0)
    8000670c:	6288                	ld	a0,0(a3)
    8000670e:	962a                	add	a2,a2,a0
    80006710:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006714:	0712                	slli	a4,a4,0x4
    80006716:	6290                	ld	a2,0(a3)
    80006718:	963a                	add	a2,a2,a4
    8000671a:	05890513          	addi	a0,s2,88
    8000671e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006720:	6294                	ld	a3,0(a3)
    80006722:	96ba                	add	a3,a3,a4
    80006724:	40000613          	li	a2,1024
    80006728:	c690                	sw	a2,8(a3)
  if(write)
    8000672a:	140d0063          	beqz	s10,8000686a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000672e:	00018697          	auipc	a3,0x18
    80006732:	8d26b683          	ld	a3,-1838(a3) # 8001e000 <disk+0x2000>
    80006736:	96ba                	add	a3,a3,a4
    80006738:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000673c:	00016817          	auipc	a6,0x16
    80006740:	8c480813          	addi	a6,a6,-1852 # 8001c000 <disk>
    80006744:	00018517          	auipc	a0,0x18
    80006748:	8bc50513          	addi	a0,a0,-1860 # 8001e000 <disk+0x2000>
    8000674c:	6114                	ld	a3,0(a0)
    8000674e:	96ba                	add	a3,a3,a4
    80006750:	00c6d603          	lhu	a2,12(a3)
    80006754:	00166613          	ori	a2,a2,1
    80006758:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000675c:	f9842683          	lw	a3,-104(s0)
    80006760:	6110                	ld	a2,0(a0)
    80006762:	9732                	add	a4,a4,a2
    80006764:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006768:	20058613          	addi	a2,a1,512
    8000676c:	0612                	slli	a2,a2,0x4
    8000676e:	9642                	add	a2,a2,a6
    80006770:	577d                	li	a4,-1
    80006772:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006776:	00469713          	slli	a4,a3,0x4
    8000677a:	6114                	ld	a3,0(a0)
    8000677c:	96ba                	add	a3,a3,a4
    8000677e:	03078793          	addi	a5,a5,48
    80006782:	97c2                	add	a5,a5,a6
    80006784:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006786:	611c                	ld	a5,0(a0)
    80006788:	97ba                	add	a5,a5,a4
    8000678a:	4685                	li	a3,1
    8000678c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000678e:	611c                	ld	a5,0(a0)
    80006790:	97ba                	add	a5,a5,a4
    80006792:	4809                	li	a6,2
    80006794:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006798:	611c                	ld	a5,0(a0)
    8000679a:	973e                	add	a4,a4,a5
    8000679c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067a8:	6518                	ld	a4,8(a0)
    800067aa:	00275783          	lhu	a5,2(a4)
    800067ae:	8b9d                	andi	a5,a5,7
    800067b0:	0786                	slli	a5,a5,0x1
    800067b2:	97ba                	add	a5,a5,a4
    800067b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067bc:	6518                	ld	a4,8(a0)
    800067be:	00275783          	lhu	a5,2(a4)
    800067c2:	2785                	addiw	a5,a5,1
    800067c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067cc:	100017b7          	lui	a5,0x10001
    800067d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067d4:	00492703          	lw	a4,4(s2)
    800067d8:	4785                	li	a5,1
    800067da:	02f71163          	bne	a4,a5,800067fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067de:	00018997          	auipc	s3,0x18
    800067e2:	94a98993          	addi	s3,s3,-1718 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    800067e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067e8:	85ce                	mv	a1,s3
    800067ea:	854a                	mv	a0,s2
    800067ec:	ffffc097          	auipc	ra,0xffffc
    800067f0:	f12080e7          	jalr	-238(ra) # 800026fe <sleep>
  while(b->disk == 1) {
    800067f4:	00492783          	lw	a5,4(s2)
    800067f8:	fe9788e3          	beq	a5,s1,800067e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067fc:	f9042903          	lw	s2,-112(s0)
    80006800:	20090793          	addi	a5,s2,512
    80006804:	00479713          	slli	a4,a5,0x4
    80006808:	00015797          	auipc	a5,0x15
    8000680c:	7f878793          	addi	a5,a5,2040 # 8001c000 <disk>
    80006810:	97ba                	add	a5,a5,a4
    80006812:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006816:	00017997          	auipc	s3,0x17
    8000681a:	7ea98993          	addi	s3,s3,2026 # 8001e000 <disk+0x2000>
    8000681e:	00491713          	slli	a4,s2,0x4
    80006822:	0009b783          	ld	a5,0(s3)
    80006826:	97ba                	add	a5,a5,a4
    80006828:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000682c:	854a                	mv	a0,s2
    8000682e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006832:	00000097          	auipc	ra,0x0
    80006836:	bc4080e7          	jalr	-1084(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000683a:	8885                	andi	s1,s1,1
    8000683c:	f0ed                	bnez	s1,8000681e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000683e:	00018517          	auipc	a0,0x18
    80006842:	8ea50513          	addi	a0,a0,-1814 # 8001e128 <disk+0x2128>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	464080e7          	jalr	1124(ra) # 80000caa <release>
}
    8000684e:	70a6                	ld	ra,104(sp)
    80006850:	7406                	ld	s0,96(sp)
    80006852:	64e6                	ld	s1,88(sp)
    80006854:	6946                	ld	s2,80(sp)
    80006856:	69a6                	ld	s3,72(sp)
    80006858:	6a06                	ld	s4,64(sp)
    8000685a:	7ae2                	ld	s5,56(sp)
    8000685c:	7b42                	ld	s6,48(sp)
    8000685e:	7ba2                	ld	s7,40(sp)
    80006860:	7c02                	ld	s8,32(sp)
    80006862:	6ce2                	ld	s9,24(sp)
    80006864:	6d42                	ld	s10,16(sp)
    80006866:	6165                	addi	sp,sp,112
    80006868:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000686a:	00017697          	auipc	a3,0x17
    8000686e:	7966b683          	ld	a3,1942(a3) # 8001e000 <disk+0x2000>
    80006872:	96ba                	add	a3,a3,a4
    80006874:	4609                	li	a2,2
    80006876:	00c69623          	sh	a2,12(a3)
    8000687a:	b5c9                	j	8000673c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000687c:	f9042583          	lw	a1,-112(s0)
    80006880:	20058793          	addi	a5,a1,512
    80006884:	0792                	slli	a5,a5,0x4
    80006886:	00016517          	auipc	a0,0x16
    8000688a:	82250513          	addi	a0,a0,-2014 # 8001c0a8 <disk+0xa8>
    8000688e:	953e                	add	a0,a0,a5
  if(write)
    80006890:	e20d11e3          	bnez	s10,800066b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006894:	20058713          	addi	a4,a1,512
    80006898:	00471693          	slli	a3,a4,0x4
    8000689c:	00015717          	auipc	a4,0x15
    800068a0:	76470713          	addi	a4,a4,1892 # 8001c000 <disk>
    800068a4:	9736                	add	a4,a4,a3
    800068a6:	0a072423          	sw	zero,168(a4)
    800068aa:	b505                	j	800066ca <virtio_disk_rw+0xf4>

00000000800068ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068ac:	1101                	addi	sp,sp,-32
    800068ae:	ec06                	sd	ra,24(sp)
    800068b0:	e822                	sd	s0,16(sp)
    800068b2:	e426                	sd	s1,8(sp)
    800068b4:	e04a                	sd	s2,0(sp)
    800068b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068b8:	00018517          	auipc	a0,0x18
    800068bc:	87050513          	addi	a0,a0,-1936 # 8001e128 <disk+0x2128>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068c8:	10001737          	lui	a4,0x10001
    800068cc:	533c                	lw	a5,96(a4)
    800068ce:	8b8d                	andi	a5,a5,3
    800068d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068d6:	00017797          	auipc	a5,0x17
    800068da:	72a78793          	addi	a5,a5,1834 # 8001e000 <disk+0x2000>
    800068de:	6b94                	ld	a3,16(a5)
    800068e0:	0207d703          	lhu	a4,32(a5)
    800068e4:	0026d783          	lhu	a5,2(a3)
    800068e8:	06f70163          	beq	a4,a5,8000694a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ec:	00015917          	auipc	s2,0x15
    800068f0:	71490913          	addi	s2,s2,1812 # 8001c000 <disk>
    800068f4:	00017497          	auipc	s1,0x17
    800068f8:	70c48493          	addi	s1,s1,1804 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    800068fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006900:	6898                	ld	a4,16(s1)
    80006902:	0204d783          	lhu	a5,32(s1)
    80006906:	8b9d                	andi	a5,a5,7
    80006908:	078e                	slli	a5,a5,0x3
    8000690a:	97ba                	add	a5,a5,a4
    8000690c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000690e:	20078713          	addi	a4,a5,512
    80006912:	0712                	slli	a4,a4,0x4
    80006914:	974a                	add	a4,a4,s2
    80006916:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000691a:	e731                	bnez	a4,80006966 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000691c:	20078793          	addi	a5,a5,512
    80006920:	0792                	slli	a5,a5,0x4
    80006922:	97ca                	add	a5,a5,s2
    80006924:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006926:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000692a:	ffffc097          	auipc	ra,0xffffc
    8000692e:	f90080e7          	jalr	-112(ra) # 800028ba <wakeup>

    disk.used_idx += 1;
    80006932:	0204d783          	lhu	a5,32(s1)
    80006936:	2785                	addiw	a5,a5,1
    80006938:	17c2                	slli	a5,a5,0x30
    8000693a:	93c1                	srli	a5,a5,0x30
    8000693c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006940:	6898                	ld	a4,16(s1)
    80006942:	00275703          	lhu	a4,2(a4)
    80006946:	faf71be3          	bne	a4,a5,800068fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000694a:	00017517          	auipc	a0,0x17
    8000694e:	7de50513          	addi	a0,a0,2014 # 8001e128 <disk+0x2128>
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	358080e7          	jalr	856(ra) # 80000caa <release>
}
    8000695a:	60e2                	ld	ra,24(sp)
    8000695c:	6442                	ld	s0,16(sp)
    8000695e:	64a2                	ld	s1,8(sp)
    80006960:	6902                	ld	s2,0(sp)
    80006962:	6105                	addi	sp,sp,32
    80006964:	8082                	ret
      panic("virtio_disk_intr status");
    80006966:	00002517          	auipc	a0,0x2
    8000696a:	f9a50513          	addi	a0,a0,-102 # 80008900 <syscalls+0x3b0>
    8000696e:	ffffa097          	auipc	ra,0xffffa
    80006972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>

0000000080006976 <cas>:
    80006976:	100522af          	lr.w	t0,(a0)
    8000697a:	00b29563          	bne	t0,a1,80006984 <fail>
    8000697e:	18c5252f          	sc.w	a0,a2,(a0)
    80006982:	8082                	ret

0000000080006984 <fail>:
    80006984:	4505                	li	a0,1
    80006986:	8082                	ret
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
