
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	07010113          	addi	sp,sp,112 # 80009070 <stack0>
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
    80000068:	4bc78793          	addi	a5,a5,1212 # 80006520 <timervec>
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
    80000130:	cda080e7          	jalr	-806(ra) # 80002e06 <either_copyin>
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
    800001c8:	c7e080e7          	jalr	-898(ra) # 80001e42 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	61c080e7          	jalr	1564(ra) # 800027f0 <sleep>
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
    80000214:	ba0080e7          	jalr	-1120(ra) # 80002db0 <either_copyout>
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
    800002f6:	b6a080e7          	jalr	-1174(ra) # 80002e5c <procdump>
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
    8000044a:	5a8080e7          	jalr	1448(ra) # 800029ee <wakeup>
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
    80000570:	d7c50513          	addi	a0,a0,-644 # 800082e8 <digits+0x2a8>
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
    800008a4:	14e080e7          	jalr	334(ra) # 800029ee <wakeup>
    
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
    80000930:	ec4080e7          	jalr	-316(ra) # 800027f0 <sleep>
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
    80000b82:	2a8080e7          	jalr	680(ra) # 80001e26 <mycpu>
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
    80000bb4:	276080e7          	jalr	630(ra) # 80001e26 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	26a080e7          	jalr	618(ra) # 80001e26 <mycpu>
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
    80000bd8:	252080e7          	jalr	594(ra) # 80001e26 <mycpu>
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
    80000c18:	212080e7          	jalr	530(ra) # 80001e26 <mycpu>
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
    80000c56:	1d4080e7          	jalr	468(ra) # 80001e26 <mycpu>
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
    80000ebe:	f5c080e7          	jalr	-164(ra) # 80001e16 <cpuid>
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
    80000eda:	f40080e7          	jalr	-192(ra) # 80001e16 <cpuid>
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
    80000efc:	112080e7          	jalr	274(ra) # 8000300a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	660080e7          	jalr	1632(ra) # 80006560 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	634080e7          	jalr	1588(ra) # 8000253c <scheduler>
    consoleinit();
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	540080e7          	jalr	1344(ra) # 80000450 <consoleinit>
    printfinit();
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	856080e7          	jalr	-1962(ra) # 8000076e <printfinit>
    printf("\n");
    80000f20:	00007517          	auipc	a0,0x7
    80000f24:	3c850513          	addi	a0,a0,968 # 800082e8 <digits+0x2a8>
    80000f28:	fffff097          	auipc	ra,0xfffff
    80000f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	19850513          	addi	a0,a0,408 # 800080c8 <digits+0x88>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	3a850513          	addi	a0,a0,936 # 800082e8 <digits+0x2a8>
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
    80000f6c:	d22080e7          	jalr	-734(ra) # 80001c8a <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	072080e7          	jalr	114(ra) # 80002fe2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	092080e7          	jalr	146(ra) # 8000300a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	5ca080e7          	jalr	1482(ra) # 8000654a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	5d8080e7          	jalr	1496(ra) # 80006560 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	7bc080e7          	jalr	1980(ra) # 8000374c <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	e4c080e7          	jalr	-436(ra) # 80003de4 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	df6080e7          	jalr	-522(ra) # 80004d96 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	6da080e7          	jalr	1754(ra) # 80006682 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	280080e7          	jalr	640(ra) # 80002230 <userinit>
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
    80001268:	990080e7          	jalr	-1648(ra) # 80001bf4 <proc_mapstacks>
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
int ret=-1;
// while (curr->index <= p->index) {
while (curr->next != -1) {
    80001876:	5ddc                	lw	a5,60(a1)
    80001878:	2781                	sext.w	a5,a5
    8000187a:	577d                	li	a4,-1
    8000187c:	04e78b63          	beq	a5,a4,800018d2 <remove_cs+0x70>
    80001880:	84ae                	mv	s1,a1
    80001882:	89b2                	mv	s3,a2
    80001884:	18800a93          	li	s5,392
    }
    release(&pred->linked_list_lock);
    //printf("%d\n",132);
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    pred = curr;
    curr = &proc[curr->next];
    80001888:	00009917          	auipc	s2,0x9
    8000188c:	a1890913          	addi	s2,s2,-1512 # 8000a2a0 <proc>
while (curr->next != -1) {
    80001890:	5a7d                	li	s4,-1
    80001892:	a011                	j	80001896 <remove_cs+0x34>
    curr = &proc[curr->next];
    80001894:	84da                	mv	s1,s6
  if ( p->index == curr->index) {
    80001896:	0389a703          	lw	a4,56(s3) # 1038 <_entry-0x7fffefc8>
    8000189a:	5c9c                	lw	a5,56(s1)
    8000189c:	04f70363          	beq	a4,a5,800018e2 <remove_cs+0x80>
    release(&pred->linked_list_lock);
    800018a0:	04050513          	addi	a0,a0,64
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	406080e7          	jalr	1030(ra) # 80000caa <release>
    curr = &proc[curr->next];
    800018ac:	5cc8                	lw	a0,60(s1)
    800018ae:	2501                	sext.w	a0,a0
    800018b0:	03550533          	mul	a0,a0,s5
    800018b4:	01250b33          	add	s6,a0,s2
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    acquire(&curr->linked_list_lock);
    800018b8:	04050513          	addi	a0,a0,64
    800018bc:	954a                	add	a0,a0,s2
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	326080e7          	jalr	806(ra) # 80000be4 <acquire>
while (curr->next != -1) {
    800018c6:	03cb2783          	lw	a5,60(s6) # 103c <_entry-0x7fffefc4>
    800018ca:	2781                	sext.w	a5,a5
    800018cc:	8526                	mv	a0,s1
    800018ce:	fd4793e3          	bne	a5,s4,80001894 <remove_cs+0x32>
    //printf("after lock\n");
  }
  panic("item not found");
    800018d2:	00007517          	auipc	a0,0x7
    800018d6:	92e50513          	addi	a0,a0,-1746 # 80008200 <digits+0x1c0>
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	c64080e7          	jalr	-924(ra) # 8000053e <panic>
      pred->next = curr->next;
    800018e2:	5cdc                	lw	a5,60(s1)
    800018e4:	2781                	sext.w	a5,a5
    800018e6:	dd5c                	sw	a5,60(a0)
      ret = curr->index;
    800018e8:	5c84                	lw	s1,56(s1)
      release(&pred->linked_list_lock);
    800018ea:	04050513          	addi	a0,a0,64
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	3bc080e7          	jalr	956(ra) # 80000caa <release>
}
    800018f6:	8526                	mv	a0,s1
    800018f8:	70e2                	ld	ra,56(sp)
    800018fa:	7442                	ld	s0,48(sp)
    800018fc:	74a2                	ld	s1,40(sp)
    800018fe:	7902                	ld	s2,32(sp)
    80001900:	69e2                	ld	s3,24(sp)
    80001902:	6a42                	ld	s4,16(sp)
    80001904:	6aa2                	ld	s5,8(sp)
    80001906:	6b02                	ld	s6,0(sp)
    80001908:	6121                	addi	sp,sp,64
    8000190a:	8082                	ret

000000008000190c <remove_from_list>:

int remove_from_list(int p_index, int *list,struct spinlock lock_list){
    8000190c:	7159                	addi	sp,sp,-112
    8000190e:	f486                	sd	ra,104(sp)
    80001910:	f0a2                	sd	s0,96(sp)
    80001912:	eca6                	sd	s1,88(sp)
    80001914:	e8ca                	sd	s2,80(sp)
    80001916:	e4ce                	sd	s3,72(sp)
    80001918:	e0d2                	sd	s4,64(sp)
    8000191a:	fc56                	sd	s5,56(sp)
    8000191c:	f85a                	sd	s6,48(sp)
    8000191e:	f45e                	sd	s7,40(sp)
    80001920:	f062                	sd	s8,32(sp)
    80001922:	ec66                	sd	s9,24(sp)
    80001924:	e86a                	sd	s10,16(sp)
    80001926:	e46e                	sd	s11,8(sp)
    80001928:	1880                	addi	s0,sp,112
    8000192a:	8a2a                	mv	s4,a0
    8000192c:	8aae                	mv	s5,a1
    8000192e:	89b2                	mv	s3,a2
  int ret=-1;
  acquire(&lock_list);
    80001930:	8532                	mv	a0,a2
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	2b2080e7          	jalr	690(ra) # 80000be4 <acquire>
  if(*list==-1){
    8000193a:	000aa903          	lw	s2,0(s5) # fffffffffffff000 <end+0xffffffff7ffe0000>
    8000193e:	57fd                	li	a5,-1
    80001940:	04f90763          	beq	s2,a5,8000198e <remove_from_list+0x82>
    panic("the remove from list faild.\n");
  }
  else{
    
    if(proc[*list].next==-1){ // only one is on the list
    80001944:	18800793          	li	a5,392
    80001948:	02f90733          	mul	a4,s2,a5
    8000194c:	00009797          	auipc	a5,0x9
    80001950:	95478793          	addi	a5,a5,-1708 # 8000a2a0 <proc>
    80001954:	97ba                	add	a5,a5,a4
    80001956:	5fc4                	lw	s1,60(a5)
    80001958:	2481                	sext.w	s1,s1
    8000195a:	57fd                	li	a5,-1
    8000195c:	04f49a63          	bne	s1,a5,800019b0 <remove_from_list+0xa4>
        if(p_index==*list){
    80001960:	03490f63          	beq	s2,s4,8000199e <remove_from_list+0x92>
      }
      release(&curr->linked_list_lock);
      release(&pred->linked_list_lock);
    }
  }
  release(&lock_list);
    80001964:	854e                	mv	a0,s3
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	344080e7          	jalr	836(ra) # 80000caa <release>
  return ret;
}
    8000196e:	8526                	mv	a0,s1
    80001970:	70a6                	ld	ra,104(sp)
    80001972:	7406                	ld	s0,96(sp)
    80001974:	64e6                	ld	s1,88(sp)
    80001976:	6946                	ld	s2,80(sp)
    80001978:	69a6                	ld	s3,72(sp)
    8000197a:	6a06                	ld	s4,64(sp)
    8000197c:	7ae2                	ld	s5,56(sp)
    8000197e:	7b42                	ld	s6,48(sp)
    80001980:	7ba2                	ld	s7,40(sp)
    80001982:	7c02                	ld	s8,32(sp)
    80001984:	6ce2                	ld	s9,24(sp)
    80001986:	6d42                	ld	s10,16(sp)
    80001988:	6da2                	ld	s11,8(sp)
    8000198a:	6165                	addi	sp,sp,112
    8000198c:	8082                	ret
    panic("the remove from list faild.\n");
    8000198e:	00007517          	auipc	a0,0x7
    80001992:	88250513          	addi	a0,a0,-1918 # 80008210 <digits+0x1d0>
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>
          *list = -1;
    8000199e:	00faa023          	sw	a5,0(s5)
          release(&lock_list);
    800019a2:	854e                	mv	a0,s3
    800019a4:	fffff097          	auipc	ra,0xfffff
    800019a8:	306080e7          	jalr	774(ra) # 80000caa <release>
          return ret;
    800019ac:	84d2                	mv	s1,s4
    800019ae:	b7c1                	j	8000196e <remove_from_list+0x62>
      curr=&proc[pred->next];
    800019b0:	00009b17          	auipc	s6,0x9
    800019b4:	8f0b0b13          	addi	s6,s6,-1808 # 8000a2a0 <proc>
    800019b8:	18800c93          	li	s9,392
    800019bc:	03990c33          	mul	s8,s2,s9
    800019c0:	018b07b3          	add	a5,s6,s8
    800019c4:	5fc4                	lw	s1,60(a5)
    800019c6:	2481                	sext.w	s1,s1
      acquire(&pred->linked_list_lock);
    800019c8:	040c0b93          	addi	s7,s8,64
    800019cc:	9bda                	add	s7,s7,s6
    800019ce:	855e                	mv	a0,s7
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	214080e7          	jalr	532(ra) # 80000be4 <acquire>
      if (curr->next == -1 && curr->index == p_index){
    800019d8:	03948cb3          	mul	s9,s1,s9
    800019dc:	9b66                	add	s6,s6,s9
    800019de:	03cb2783          	lw	a5,60(s6)
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	577d                	li	a4,-1
    800019e6:	00e79663          	bne	a5,a4,800019f2 <remove_from_list+0xe6>
    800019ea:	038b2783          	lw	a5,56(s6)
    800019ee:	07478163          	beq	a5,s4,80001a50 <remove_from_list+0x144>
      acquire(&curr->linked_list_lock);
    800019f2:	18800d93          	li	s11,392
    800019f6:	03b48d33          	mul	s10,s1,s11
    800019fa:	040d0b13          	addi	s6,s10,64
    800019fe:	00009c97          	auipc	s9,0x9
    80001a02:	8a2c8c93          	addi	s9,s9,-1886 # 8000a2a0 <proc>
    80001a06:	9b66                	add	s6,s6,s9
    80001a08:	855a                	mv	a0,s6
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	1da080e7          	jalr	474(ra) # 80000be4 <acquire>
      if (pred->index == p_index){
    80001a12:	03b90db3          	mul	s11,s2,s11
    80001a16:	9cee                	add	s9,s9,s11
    80001a18:	038ca783          	lw	a5,56(s9)
    80001a1c:	05479463          	bne	a5,s4,80001a64 <remove_from_list+0x158>
        *list = curr->index;
    80001a20:	00009797          	auipc	a5,0x9
    80001a24:	88078793          	addi	a5,a5,-1920 # 8000a2a0 <proc>
    80001a28:	01a784b3          	add	s1,a5,s10
    80001a2c:	5c94                	lw	a3,56(s1)
    80001a2e:	00daa023          	sw	a3,0(s5)
        pred->next = -1;  //the caller will insert to the new list
    80001a32:	57fd                	li	a5,-1
    80001a34:	02fcae23          	sw	a5,60(s9)
  int ret=-1;
    80001a38:	54fd                	li	s1,-1
      release(&curr->linked_list_lock);
    80001a3a:	855a                	mv	a0,s6
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	26e080e7          	jalr	622(ra) # 80000caa <release>
      release(&pred->linked_list_lock);
    80001a44:	855e                	mv	a0,s7
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	264080e7          	jalr	612(ra) # 80000caa <release>
    80001a4e:	bf19                	j	80001964 <remove_from_list+0x58>
        pred->next = -1;
    80001a50:	00009917          	auipc	s2,0x9
    80001a54:	85090913          	addi	s2,s2,-1968 # 8000a2a0 <proc>
    80001a58:	9962                	add	s2,s2,s8
    80001a5a:	57fd                	li	a5,-1
    80001a5c:	02f92e23          	sw	a5,60(s2)
        return ret;
    80001a60:	84d2                	mv	s1,s4
    80001a62:	b731                	j	8000196e <remove_from_list+0x62>
      ret=remove_cs(pred, curr, &proc[p_index]);
    80001a64:	18800613          	li	a2,392
    80001a68:	02ca0633          	mul	a2,s4,a2
    80001a6c:	00009517          	auipc	a0,0x9
    80001a70:	83450513          	addi	a0,a0,-1996 # 8000a2a0 <proc>
    80001a74:	962a                	add	a2,a2,a0
    80001a76:	01a505b3          	add	a1,a0,s10
    80001a7a:	9562                	add	a0,a0,s8
    80001a7c:	00000097          	auipc	ra,0x0
    80001a80:	de6080e7          	jalr	-538(ra) # 80001862 <remove_cs>
    80001a84:	84aa                	mv	s1,a0
    80001a86:	bf55                	j	80001a3a <remove_from_list+0x12e>

0000000080001a88 <insert_cs>:

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001a88:	7139                	addi	sp,sp,-64
    80001a8a:	fc06                	sd	ra,56(sp)
    80001a8c:	f822                	sd	s0,48(sp)
    80001a8e:	f426                	sd	s1,40(sp)
    80001a90:	f04a                	sd	s2,32(sp)
    80001a92:	ec4e                	sd	s3,24(sp)
    80001a94:	e852                	sd	s4,16(sp)
    80001a96:	e456                	sd	s5,8(sp)
    80001a98:	0080                	addi	s0,sp,64
    80001a9a:	84aa                	mv	s1,a0
    80001a9c:	8aae                	mv	s5,a1
  //struct proc *curr=pred; 
  while (pred->next != -1) {
    80001a9e:	5d5c                	lw	a5,60(a0)
    80001aa0:	2781                	sext.w	a5,a5
    80001aa2:	577d                	li	a4,-1
    80001aa4:	04e78063          	beq	a5,a4,80001ae4 <insert_cs+0x5c>
    80001aa8:	18800a13          	li	s4,392
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    release(&pred->linked_list_lock); // caller acquired
    pred = &proc[pred->next];
    80001aac:	00008917          	auipc	s2,0x8
    80001ab0:	7f490913          	addi	s2,s2,2036 # 8000a2a0 <proc>
  while (pred->next != -1) {
    80001ab4:	59fd                	li	s3,-1
    release(&pred->linked_list_lock); // caller acquired
    80001ab6:	04048513          	addi	a0,s1,64
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	1f0080e7          	jalr	496(ra) # 80000caa <release>
    pred = &proc[pred->next];
    80001ac2:	5cc8                	lw	a0,60(s1)
    80001ac4:	2501                	sext.w	a0,a0
    80001ac6:	03450533          	mul	a0,a0,s4
    80001aca:	012504b3          	add	s1,a0,s2
    acquire(&pred->linked_list_lock);
    80001ace:	04050513          	addi	a0,a0,64
    80001ad2:	954a                	add	a0,a0,s2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	110080e7          	jalr	272(ra) # 80000be4 <acquire>
  while (pred->next != -1) {
    80001adc:	5cdc                	lw	a5,60(s1)
    80001ade:	2781                	sext.w	a5,a5
    80001ae0:	fd379be3          	bne	a5,s3,80001ab6 <insert_cs+0x2e>
    }
    //printf("exitloop\n");
    pred->next = p->index;
    80001ae4:	038aa783          	lw	a5,56(s5)
    80001ae8:	dcdc                	sw	a5,60(s1)
    //printf("the pred is:%d pred->next:%d p->index=%d\n",pred->index,pred->next,p->index);
    //printf("the p->index is:%d\n",p->index);
    p->next=-1;
    80001aea:	57fd                	li	a5,-1
    80001aec:	02faae23          	sw	a5,60(s5)
    release(&pred->linked_list_lock);
    80001af0:	04048513          	addi	a0,s1,64
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	1b6080e7          	jalr	438(ra) # 80000caa <release>
    return p->index;
}
    80001afc:	038aa503          	lw	a0,56(s5)
    80001b00:	70e2                	ld	ra,56(sp)
    80001b02:	7442                	ld	s0,48(sp)
    80001b04:	74a2                	ld	s1,40(sp)
    80001b06:	7902                	ld	s2,32(sp)
    80001b08:	69e2                	ld	s3,24(sp)
    80001b0a:	6a42                	ld	s4,16(sp)
    80001b0c:	6aa2                	ld	s5,8(sp)
    80001b0e:	6121                	addi	sp,sp,64
    80001b10:	8082                	ret

0000000080001b12 <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock lock_list){
    80001b12:	7139                	addi	sp,sp,-64
    80001b14:	fc06                	sd	ra,56(sp)
    80001b16:	f822                	sd	s0,48(sp)
    80001b18:	f426                	sd	s1,40(sp)
    80001b1a:	f04a                	sd	s2,32(sp)
    80001b1c:	ec4e                	sd	s3,24(sp)
    80001b1e:	e852                	sd	s4,16(sp)
    80001b20:	e456                	sd	s5,8(sp)
    80001b22:	0080                	addi	s0,sp,64
    80001b24:	84aa                	mv	s1,a0
    80001b26:	892e                	mv	s2,a1
    80001b28:	8a32                	mv	s4,a2
  //printf("entered insert_to_list.\n");
  int ret=-1;
  if(*list==-1){
    80001b2a:	4198                	lw	a4,0(a1)
    80001b2c:	57fd                	li	a5,-1
    80001b2e:	06f70563          	beq	a4,a5,80001b98 <insert_to_list+0x86>
    ret=p_index;
    //printf("here\nlist pointer: %d, list next %d\n",*list, proc[*list].next);
    release(&lock_list);
  }
  else{
    acquire(&lock_list);
    80001b32:	8532                	mv	a0,a2
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	0b0080e7          	jalr	176(ra) # 80000be4 <acquire>
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    80001b3c:	00092903          	lw	s2,0(s2)
    80001b40:	18800a93          	li	s5,392
    80001b44:	03590933          	mul	s2,s2,s5
    //printf("the index of the first prosses in the list is:%d %d\n",*list,pred->next);
    acquire(&pred->linked_list_lock);
    80001b48:	04090513          	addi	a0,s2,64
    80001b4c:	00008997          	auipc	s3,0x8
    80001b50:	75498993          	addi	s3,s3,1876 # 8000a2a0 <proc>
    80001b54:	954e                	add	a0,a0,s3
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	08e080e7          	jalr	142(ra) # 80000be4 <acquire>
    //curr=&proc[pred->next];
    //acquire(&curr->lock);
    ret=insert_cs(pred, &proc[p_index]);
    80001b5e:	035484b3          	mul	s1,s1,s5
    80001b62:	009985b3          	add	a1,s3,s1
    80001b66:	01298533          	add	a0,s3,s2
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f1e080e7          	jalr	-226(ra) # 80001a88 <insert_cs>
    80001b72:	84aa                	mv	s1,a0
    //release(&curr->lock);
    // release(&pred->linked_list_lock);
    //printf("ret is:%d \n",ret);  
    release(&lock_list);
    80001b74:	8552                	mv	a0,s4
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	134080e7          	jalr	308(ra) # 80000caa <release>
}
if(ret==-1){
    80001b7e:	57fd                	li	a5,-1
    80001b80:	06f48263          	beq	s1,a5,80001be4 <insert_to_list+0xd2>
  panic("insert is failed");
}
return ret;
}
    80001b84:	8526                	mv	a0,s1
    80001b86:	70e2                	ld	ra,56(sp)
    80001b88:	7442                	ld	s0,48(sp)
    80001b8a:	74a2                	ld	s1,40(sp)
    80001b8c:	7902                	ld	s2,32(sp)
    80001b8e:	69e2                	ld	s3,24(sp)
    80001b90:	6a42                	ld	s4,16(sp)
    80001b92:	6aa2                	ld	s5,8(sp)
    80001b94:	6121                	addi	sp,sp,64
    80001b96:	8082                	ret
    acquire(&lock_list);
    80001b98:	8532                	mv	a0,a2
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	04a080e7          	jalr	74(ra) # 80000be4 <acquire>
    *list=p_index;
    80001ba2:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001ba6:	18800993          	li	s3,392
    80001baa:	03348ab3          	mul	s5,s1,s3
    80001bae:	040a8913          	addi	s2,s5,64
    80001bb2:	00008997          	auipc	s3,0x8
    80001bb6:	6ee98993          	addi	s3,s3,1774 # 8000a2a0 <proc>
    80001bba:	994e                	add	s2,s2,s3
    80001bbc:	854a                	mv	a0,s2
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	026080e7          	jalr	38(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001bc6:	99d6                	add	s3,s3,s5
    80001bc8:	57fd                	li	a5,-1
    80001bca:	02f9ae23          	sw	a5,60(s3)
    release(&proc[p_index].linked_list_lock);
    80001bce:	854a                	mv	a0,s2
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	0da080e7          	jalr	218(ra) # 80000caa <release>
    release(&lock_list);
    80001bd8:	8552                	mv	a0,s4
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	0d0080e7          	jalr	208(ra) # 80000caa <release>
    80001be2:	bf71                	j	80001b7e <insert_to_list+0x6c>
  panic("insert is failed");
    80001be4:	00006517          	auipc	a0,0x6
    80001be8:	64c50513          	addi	a0,a0,1612 # 80008230 <digits+0x1f0>
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	952080e7          	jalr	-1710(ra) # 8000053e <panic>

0000000080001bf4 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001bf4:	7139                	addi	sp,sp,-64
    80001bf6:	fc06                	sd	ra,56(sp)
    80001bf8:	f822                	sd	s0,48(sp)
    80001bfa:	f426                	sd	s1,40(sp)
    80001bfc:	f04a                	sd	s2,32(sp)
    80001bfe:	ec4e                	sd	s3,24(sp)
    80001c00:	e852                	sd	s4,16(sp)
    80001c02:	e456                	sd	s5,8(sp)
    80001c04:	e05a                	sd	s6,0(sp)
    80001c06:	0080                	addi	s0,sp,64
    80001c08:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	00008497          	auipc	s1,0x8
    80001c0e:	69648493          	addi	s1,s1,1686 # 8000a2a0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c12:	8b26                	mv	s6,s1
    80001c14:	00006a97          	auipc	s5,0x6
    80001c18:	3eca8a93          	addi	s5,s5,1004 # 80008000 <etext>
    80001c1c:	04000937          	lui	s2,0x4000
    80001c20:	197d                	addi	s2,s2,-1
    80001c22:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c24:	0000fa17          	auipc	s4,0xf
    80001c28:	87ca0a13          	addi	s4,s4,-1924 # 800104a0 <tickslock>
    char *pa = kalloc();
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	ec8080e7          	jalr	-312(ra) # 80000af4 <kalloc>
    80001c34:	862a                	mv	a2,a0
    if(pa == 0)
    80001c36:	c131                	beqz	a0,80001c7a <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c38:	416485b3          	sub	a1,s1,s6
    80001c3c:	858d                	srai	a1,a1,0x3
    80001c3e:	000ab783          	ld	a5,0(s5)
    80001c42:	02f585b3          	mul	a1,a1,a5
    80001c46:	2585                	addiw	a1,a1,1
    80001c48:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c4c:	4719                	li	a4,6
    80001c4e:	6685                	lui	a3,0x1
    80001c50:	40b905b3          	sub	a1,s2,a1
    80001c54:	854e                	mv	a0,s3
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	51e080e7          	jalr	1310(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5e:	18848493          	addi	s1,s1,392
    80001c62:	fd4495e3          	bne	s1,s4,80001c2c <proc_mapstacks+0x38>
  }
}
    80001c66:	70e2                	ld	ra,56(sp)
    80001c68:	7442                	ld	s0,48(sp)
    80001c6a:	74a2                	ld	s1,40(sp)
    80001c6c:	7902                	ld	s2,32(sp)
    80001c6e:	69e2                	ld	s3,24(sp)
    80001c70:	6a42                	ld	s4,16(sp)
    80001c72:	6aa2                	ld	s5,8(sp)
    80001c74:	6b02                	ld	s6,0(sp)
    80001c76:	6121                	addi	sp,sp,64
    80001c78:	8082                	ret
      panic("kalloc");
    80001c7a:	00006517          	auipc	a0,0x6
    80001c7e:	5ce50513          	addi	a0,a0,1486 # 80008248 <digits+0x208>
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080001c8a <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80001c8a:	7119                	addi	sp,sp,-128
    80001c8c:	fc86                	sd	ra,120(sp)
    80001c8e:	f8a2                	sd	s0,112(sp)
    80001c90:	f4a6                	sd	s1,104(sp)
    80001c92:	f0ca                	sd	s2,96(sp)
    80001c94:	ecce                	sd	s3,88(sp)
    80001c96:	e8d2                	sd	s4,80(sp)
    80001c98:	e4d6                	sd	s5,72(sp)
    80001c9a:	e0da                	sd	s6,64(sp)
    80001c9c:	fc5e                	sd	s7,56(sp)
    80001c9e:	f862                	sd	s8,48(sp)
    80001ca0:	f466                	sd	s9,40(sp)
    80001ca2:	0100                	addi	s0,sp,128
  printf("entered procinit\n");
    80001ca4:	00006517          	auipc	a0,0x6
    80001ca8:	5ac50513          	addi	a0,a0,1452 # 80008250 <digits+0x210>
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	8dc080e7          	jalr	-1828(ra) # 80000588 <printf>
  struct proc *p;

  for (int i = 0; i<NCPU; i++){
    cas(&cpus_ll[i],0,-1); 
    80001cb4:	567d                	li	a2,-1
    80001cb6:	4581                	li	a1,0
    80001cb8:	00007517          	auipc	a0,0x7
    80001cbc:	37050513          	addi	a0,a0,880 # 80009028 <cpus_ll>
    80001cc0:	00005097          	auipc	ra,0x5
    80001cc4:	ea6080e7          	jalr	-346(ra) # 80006b66 <cas>
}
  
  initlock(&pid_lock, "nextpid");
    80001cc8:	00006597          	auipc	a1,0x6
    80001ccc:	5a058593          	addi	a1,a1,1440 # 80008268 <digits+0x228>
    80001cd0:	00008517          	auipc	a0,0x8
    80001cd4:	4c050513          	addi	a0,a0,1216 # 8000a190 <pid_lock>
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	e7c080e7          	jalr	-388(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ce0:	00006597          	auipc	a1,0x6
    80001ce4:	59058593          	addi	a1,a1,1424 # 80008270 <digits+0x230>
    80001ce8:	00008517          	auipc	a0,0x8
    80001cec:	4c050513          	addi	a0,a0,1216 # 8000a1a8 <wait_lock>
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	e64080e7          	jalr	-412(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001cf8:	00006597          	auipc	a1,0x6
    80001cfc:	58858593          	addi	a1,a1,1416 # 80008280 <digits+0x240>
    80001d00:	00008517          	auipc	a0,0x8
    80001d04:	4c050513          	addi	a0,a0,1216 # 8000a1c0 <sleeping_head>
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	e4c080e7          	jalr	-436(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001d10:	00006597          	auipc	a1,0x6
    80001d14:	58058593          	addi	a1,a1,1408 # 80008290 <digits+0x250>
    80001d18:	00008517          	auipc	a0,0x8
    80001d1c:	4c050513          	addi	a0,a0,1216 # 8000a1d8 <zombie_head>
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	e34080e7          	jalr	-460(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001d28:	00006597          	auipc	a1,0x6
    80001d2c:	57858593          	addi	a1,a1,1400 # 800082a0 <digits+0x260>
    80001d30:	00008517          	auipc	a0,0x8
    80001d34:	4c050513          	addi	a0,a0,1216 # 8000a1f0 <unused_head>
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	e1c080e7          	jalr	-484(ra) # 80000b54 <initlock>
  
  int i=0; //added
    80001d40:	4981                	li	s3,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d42:	00008497          	auipc	s1,0x8
    80001d46:	55e48493          	addi	s1,s1,1374 # 8000a2a0 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001d4a:	8ca6                	mv	s9,s1
    80001d4c:	00006c17          	auipc	s8,0x6
    80001d50:	2b4c3c03          	ld	s8,692(s8) # 80008000 <etext>
    80001d54:	04000a37          	lui	s4,0x4000
    80001d58:	1a7d                	addi	s4,s4,-1
    80001d5a:	0a32                	slli	s4,s4,0xc
      //added:
      p->state= UNUSED; 
      p->index=i; 
      initlock(&p->lock, "proc");
    80001d5c:	00006b97          	auipc	s7,0x6
    80001d60:	554b8b93          	addi	s7,s7,1364 # 800082b0 <digits+0x270>
      initlock(&p->linked_list_lock, "inbar");
    80001d64:	00006b17          	auipc	s6,0x6
    80001d68:	554b0b13          	addi	s6,s6,1364 # 800082b8 <digits+0x278>
      i++;
      insert_to_list(p->index, &unused,unused_head);
    80001d6c:	00008917          	auipc	s2,0x8
    80001d70:	42490913          	addi	s2,s2,1060 # 8000a190 <pid_lock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d74:	0000ea97          	auipc	s5,0xe
    80001d78:	72ca8a93          	addi	s5,s5,1836 # 800104a0 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001d7c:	419487b3          	sub	a5,s1,s9
    80001d80:	878d                	srai	a5,a5,0x3
    80001d82:	038787b3          	mul	a5,a5,s8
    80001d86:	2785                	addiw	a5,a5,1
    80001d88:	00d7979b          	slliw	a5,a5,0xd
    80001d8c:	40fa07b3          	sub	a5,s4,a5
    80001d90:	f0bc                	sd	a5,96(s1)
      p->state= UNUSED; 
    80001d92:	0004ac23          	sw	zero,24(s1)
      p->index=i; 
    80001d96:	0334ac23          	sw	s3,56(s1)
      initlock(&p->lock, "proc");
    80001d9a:	85de                	mv	a1,s7
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	db6080e7          	jalr	-586(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, "inbar");
    80001da6:	85da                	mv	a1,s6
    80001da8:	04048513          	addi	a0,s1,64
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	da8080e7          	jalr	-600(ra) # 80000b54 <initlock>
      i++;
    80001db4:	2985                	addiw	s3,s3,1
      insert_to_list(p->index, &unused,unused_head);
    80001db6:	06093783          	ld	a5,96(s2)
    80001dba:	f8f43023          	sd	a5,-128(s0)
    80001dbe:	06893783          	ld	a5,104(s2)
    80001dc2:	f8f43423          	sd	a5,-120(s0)
    80001dc6:	07093783          	ld	a5,112(s2)
    80001dca:	f8f43823          	sd	a5,-112(s0)
    80001dce:	f8040613          	addi	a2,s0,-128
    80001dd2:	00007597          	auipc	a1,0x7
    80001dd6:	c9258593          	addi	a1,a1,-878 # 80008a64 <unused>
    80001dda:	5c88                	lw	a0,56(s1)
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	d36080e7          	jalr	-714(ra) # 80001b12 <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de4:	18848493          	addi	s1,s1,392
    80001de8:	f9549ae3          	bne	s1,s5,80001d7c <procinit+0xf2>
      //printf("the value of the index is:%d\n",i);
  }
  printf("finished procinit\n");
    80001dec:	00006517          	auipc	a0,0x6
    80001df0:	4d450513          	addi	a0,a0,1236 # 800082c0 <digits+0x280>
    80001df4:	ffffe097          	auipc	ra,0xffffe
    80001df8:	794080e7          	jalr	1940(ra) # 80000588 <printf>
}
    80001dfc:	70e6                	ld	ra,120(sp)
    80001dfe:	7446                	ld	s0,112(sp)
    80001e00:	74a6                	ld	s1,104(sp)
    80001e02:	7906                	ld	s2,96(sp)
    80001e04:	69e6                	ld	s3,88(sp)
    80001e06:	6a46                	ld	s4,80(sp)
    80001e08:	6aa6                	ld	s5,72(sp)
    80001e0a:	6b06                	ld	s6,64(sp)
    80001e0c:	7be2                	ld	s7,56(sp)
    80001e0e:	7c42                	ld	s8,48(sp)
    80001e10:	7ca2                	ld	s9,40(sp)
    80001e12:	6109                	addi	sp,sp,128
    80001e14:	8082                	ret

0000000080001e16 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001e16:	1141                	addi	sp,sp,-16
    80001e18:	e422                	sd	s0,8(sp)
    80001e1a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e1c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001e1e:	2501                	sext.w	a0,a0
    80001e20:	6422                	ld	s0,8(sp)
    80001e22:	0141                	addi	sp,sp,16
    80001e24:	8082                	ret

0000000080001e26 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001e26:	1141                	addi	sp,sp,-16
    80001e28:	e422                	sd	s0,8(sp)
    80001e2a:	0800                	addi	s0,sp,16
    80001e2c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001e2e:	2781                	sext.w	a5,a5
    80001e30:	079e                	slli	a5,a5,0x7
  return c;
}
    80001e32:	00008517          	auipc	a0,0x8
    80001e36:	3d650513          	addi	a0,a0,982 # 8000a208 <cpus>
    80001e3a:	953e                	add	a0,a0,a5
    80001e3c:	6422                	ld	s0,8(sp)
    80001e3e:	0141                	addi	sp,sp,16
    80001e40:	8082                	ret

0000000080001e42 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e42:	1101                	addi	sp,sp,-32
    80001e44:	ec06                	sd	ra,24(sp)
    80001e46:	e822                	sd	s0,16(sp)
    80001e48:	e426                	sd	s1,8(sp)
    80001e4a:	1000                	addi	s0,sp,32
  push_off();
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	d4c080e7          	jalr	-692(ra) # 80000b98 <push_off>
    80001e54:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e56:	2781                	sext.w	a5,a5
    80001e58:	079e                	slli	a5,a5,0x7
    80001e5a:	00008717          	auipc	a4,0x8
    80001e5e:	33670713          	addi	a4,a4,822 # 8000a190 <pid_lock>
    80001e62:	97ba                	add	a5,a5,a4
    80001e64:	7fa4                	ld	s1,120(a5)
  pop_off();
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	de4080e7          	jalr	-540(ra) # 80000c4a <pop_off>
  return p;
}
    80001e6e:	8526                	mv	a0,s1
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret

0000000080001e7a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e7a:	1141                	addi	sp,sp,-16
    80001e7c:	e406                	sd	ra,8(sp)
    80001e7e:	e022                	sd	s0,0(sp)
    80001e80:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	fc0080e7          	jalr	-64(ra) # 80001e42 <myproc>
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e20080e7          	jalr	-480(ra) # 80000caa <release>

  if (first) {
    80001e92:	00007797          	auipc	a5,0x7
    80001e96:	bce7a783          	lw	a5,-1074(a5) # 80008a60 <first.1723>
    80001e9a:	eb89                	bnez	a5,80001eac <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e9c:	00001097          	auipc	ra,0x1
    80001ea0:	186080e7          	jalr	390(ra) # 80003022 <usertrapret>
}
    80001ea4:	60a2                	ld	ra,8(sp)
    80001ea6:	6402                	ld	s0,0(sp)
    80001ea8:	0141                	addi	sp,sp,16
    80001eaa:	8082                	ret
    first = 0;
    80001eac:	00007797          	auipc	a5,0x7
    80001eb0:	ba07aa23          	sw	zero,-1100(a5) # 80008a60 <first.1723>
    fsinit(ROOTDEV);
    80001eb4:	4505                	li	a0,1
    80001eb6:	00002097          	auipc	ra,0x2
    80001eba:	eae080e7          	jalr	-338(ra) # 80003d64 <fsinit>
    80001ebe:	bff9                	j	80001e9c <forkret+0x22>

0000000080001ec0 <allocpid>:
allocpid() { //changed as ordered in task 2
    80001ec0:	1101                	addi	sp,sp,-32
    80001ec2:	ec06                	sd	ra,24(sp)
    80001ec4:	e822                	sd	s0,16(sp)
    80001ec6:	e426                	sd	s1,8(sp)
    80001ec8:	e04a                	sd	s2,0(sp)
    80001eca:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001ecc:	00007917          	auipc	s2,0x7
    80001ed0:	ba490913          	addi	s2,s2,-1116 # 80008a70 <nextpid>
    80001ed4:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001ed8:	0014861b          	addiw	a2,s1,1
    80001edc:	85a6                	mv	a1,s1
    80001ede:	854a                	mv	a0,s2
    80001ee0:	00005097          	auipc	ra,0x5
    80001ee4:	c86080e7          	jalr	-890(ra) # 80006b66 <cas>
    80001ee8:	f575                	bnez	a0,80001ed4 <allocpid+0x14>
}
    80001eea:	8526                	mv	a0,s1
    80001eec:	60e2                	ld	ra,24(sp)
    80001eee:	6442                	ld	s0,16(sp)
    80001ef0:	64a2                	ld	s1,8(sp)
    80001ef2:	6902                	ld	s2,0(sp)
    80001ef4:	6105                	addi	sp,sp,32
    80001ef6:	8082                	ret

0000000080001ef8 <proc_pagetable>:
{
    80001ef8:	1101                	addi	sp,sp,-32
    80001efa:	ec06                	sd	ra,24(sp)
    80001efc:	e822                	sd	s0,16(sp)
    80001efe:	e426                	sd	s1,8(sp)
    80001f00:	e04a                	sd	s2,0(sp)
    80001f02:	1000                	addi	s0,sp,32
    80001f04:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	458080e7          	jalr	1112(ra) # 8000135e <uvmcreate>
    80001f0e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f10:	c121                	beqz	a0,80001f50 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f12:	4729                	li	a4,10
    80001f14:	00005697          	auipc	a3,0x5
    80001f18:	0ec68693          	addi	a3,a3,236 # 80007000 <_trampoline>
    80001f1c:	6605                	lui	a2,0x1
    80001f1e:	040005b7          	lui	a1,0x4000
    80001f22:	15fd                	addi	a1,a1,-1
    80001f24:	05b2                	slli	a1,a1,0xc
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	1ae080e7          	jalr	430(ra) # 800010d4 <mappages>
    80001f2e:	02054863          	bltz	a0,80001f5e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f32:	4719                	li	a4,6
    80001f34:	07893683          	ld	a3,120(s2)
    80001f38:	6605                	lui	a2,0x1
    80001f3a:	020005b7          	lui	a1,0x2000
    80001f3e:	15fd                	addi	a1,a1,-1
    80001f40:	05b6                	slli	a1,a1,0xd
    80001f42:	8526                	mv	a0,s1
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	190080e7          	jalr	400(ra) # 800010d4 <mappages>
    80001f4c:	02054163          	bltz	a0,80001f6e <proc_pagetable+0x76>
}
    80001f50:	8526                	mv	a0,s1
    80001f52:	60e2                	ld	ra,24(sp)
    80001f54:	6442                	ld	s0,16(sp)
    80001f56:	64a2                	ld	s1,8(sp)
    80001f58:	6902                	ld	s2,0(sp)
    80001f5a:	6105                	addi	sp,sp,32
    80001f5c:	8082                	ret
    uvmfree(pagetable, 0);
    80001f5e:	4581                	li	a1,0
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	5f8080e7          	jalr	1528(ra) # 8000155a <uvmfree>
    return 0;
    80001f6a:	4481                	li	s1,0
    80001f6c:	b7d5                	j	80001f50 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f6e:	4681                	li	a3,0
    80001f70:	4605                	li	a2,1
    80001f72:	040005b7          	lui	a1,0x4000
    80001f76:	15fd                	addi	a1,a1,-1
    80001f78:	05b2                	slli	a1,a1,0xc
    80001f7a:	8526                	mv	a0,s1
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	31e080e7          	jalr	798(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001f84:	4581                	li	a1,0
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	5d2080e7          	jalr	1490(ra) # 8000155a <uvmfree>
    return 0;
    80001f90:	4481                	li	s1,0
    80001f92:	bf7d                	j	80001f50 <proc_pagetable+0x58>

0000000080001f94 <proc_freepagetable>:
{
    80001f94:	1101                	addi	sp,sp,-32
    80001f96:	ec06                	sd	ra,24(sp)
    80001f98:	e822                	sd	s0,16(sp)
    80001f9a:	e426                	sd	s1,8(sp)
    80001f9c:	e04a                	sd	s2,0(sp)
    80001f9e:	1000                	addi	s0,sp,32
    80001fa0:	84aa                	mv	s1,a0
    80001fa2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fa4:	4681                	li	a3,0
    80001fa6:	4605                	li	a2,1
    80001fa8:	040005b7          	lui	a1,0x4000
    80001fac:	15fd                	addi	a1,a1,-1
    80001fae:	05b2                	slli	a1,a1,0xc
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	2ea080e7          	jalr	746(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fb8:	4681                	li	a3,0
    80001fba:	4605                	li	a2,1
    80001fbc:	020005b7          	lui	a1,0x2000
    80001fc0:	15fd                	addi	a1,a1,-1
    80001fc2:	05b6                	slli	a1,a1,0xd
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	2d4080e7          	jalr	724(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001fce:	85ca                	mv	a1,s2
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	588080e7          	jalr	1416(ra) # 8000155a <uvmfree>
}
    80001fda:	60e2                	ld	ra,24(sp)
    80001fdc:	6442                	ld	s0,16(sp)
    80001fde:	64a2                	ld	s1,8(sp)
    80001fe0:	6902                	ld	s2,0(sp)
    80001fe2:	6105                	addi	sp,sp,32
    80001fe4:	8082                	ret

0000000080001fe6 <freeproc>:
{
    80001fe6:	7139                	addi	sp,sp,-64
    80001fe8:	fc06                	sd	ra,56(sp)
    80001fea:	f822                	sd	s0,48(sp)
    80001fec:	f426                	sd	s1,40(sp)
    80001fee:	f04a                	sd	s2,32(sp)
    80001ff0:	0080                	addi	s0,sp,64
    80001ff2:	84aa                	mv	s1,a0
  printf("entered freeproc\n");
    80001ff4:	00006517          	auipc	a0,0x6
    80001ff8:	2e450513          	addi	a0,a0,740 # 800082d8 <digits+0x298>
    80001ffc:	ffffe097          	auipc	ra,0xffffe
    80002000:	58c080e7          	jalr	1420(ra) # 80000588 <printf>
  if(p->trapframe)
    80002004:	7ca8                	ld	a0,120(s1)
    80002006:	c509                	beqz	a0,80002010 <freeproc+0x2a>
    kfree((void*)p->trapframe);
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	9f0080e7          	jalr	-1552(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002010:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80002014:	78a8                	ld	a0,112(s1)
    80002016:	c511                	beqz	a0,80002022 <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    80002018:	74ac                	ld	a1,104(s1)
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	f7a080e7          	jalr	-134(ra) # 80001f94 <proc_freepagetable>
  p->pagetable = 0;
    80002022:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002026:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    8000202a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000202e:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002032:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002036:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000203a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000203e:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index,&zombie,zombie_head);
    80002042:	00008917          	auipc	s2,0x8
    80002046:	14e90913          	addi	s2,s2,334 # 8000a190 <pid_lock>
    8000204a:	04893783          	ld	a5,72(s2)
    8000204e:	fcf43023          	sd	a5,-64(s0)
    80002052:	05093783          	ld	a5,80(s2)
    80002056:	fcf43423          	sd	a5,-56(s0)
    8000205a:	05893783          	ld	a5,88(s2)
    8000205e:	fcf43823          	sd	a5,-48(s0)
    80002062:	fc040613          	addi	a2,s0,-64
    80002066:	00007597          	auipc	a1,0x7
    8000206a:	a0258593          	addi	a1,a1,-1534 # 80008a68 <zombie>
    8000206e:	5c88                	lw	a0,56(s1)
    80002070:	00000097          	auipc	ra,0x0
    80002074:	89c080e7          	jalr	-1892(ra) # 8000190c <remove_from_list>
  p->state = UNUSED;
    80002078:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index,&unused,unused_head);
    8000207c:	06093783          	ld	a5,96(s2)
    80002080:	fcf43023          	sd	a5,-64(s0)
    80002084:	06893783          	ld	a5,104(s2)
    80002088:	fcf43423          	sd	a5,-56(s0)
    8000208c:	07093783          	ld	a5,112(s2)
    80002090:	fcf43823          	sd	a5,-48(s0)
    80002094:	fc040613          	addi	a2,s0,-64
    80002098:	00007597          	auipc	a1,0x7
    8000209c:	9cc58593          	addi	a1,a1,-1588 # 80008a64 <unused>
    800020a0:	5c88                	lw	a0,56(s1)
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	a70080e7          	jalr	-1424(ra) # 80001b12 <insert_to_list>
  printf("exiting from freeproc\n");
    800020aa:	00006517          	auipc	a0,0x6
    800020ae:	24650513          	addi	a0,a0,582 # 800082f0 <digits+0x2b0>
    800020b2:	ffffe097          	auipc	ra,0xffffe
    800020b6:	4d6080e7          	jalr	1238(ra) # 80000588 <printf>
}
    800020ba:	70e2                	ld	ra,56(sp)
    800020bc:	7442                	ld	s0,48(sp)
    800020be:	74a2                	ld	s1,40(sp)
    800020c0:	7902                	ld	s2,32(sp)
    800020c2:	6121                	addi	sp,sp,64
    800020c4:	8082                	ret

00000000800020c6 <allocproc>:
{
    800020c6:	715d                	addi	sp,sp,-80
    800020c8:	e486                	sd	ra,72(sp)
    800020ca:	e0a2                	sd	s0,64(sp)
    800020cc:	fc26                	sd	s1,56(sp)
    800020ce:	f84a                	sd	s2,48(sp)
    800020d0:	f44e                	sd	s3,40(sp)
    800020d2:	f052                	sd	s4,32(sp)
    800020d4:	0880                	addi	s0,sp,80
  printf("entered allocproc\n");
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	23250513          	addi	a0,a0,562 # 80008308 <digits+0x2c8>
    800020de:	ffffe097          	auipc	ra,0xffffe
    800020e2:	4aa080e7          	jalr	1194(ra) # 80000588 <printf>
  if(unused != -1){
    800020e6:	00007917          	auipc	s2,0x7
    800020ea:	97e92903          	lw	s2,-1666(s2) # 80008a64 <unused>
    800020ee:	57fd                	li	a5,-1
  return 0;
    800020f0:	4481                	li	s1,0
  if(unused != -1){
    800020f2:	0cf90e63          	beq	s2,a5,800021ce <allocproc+0x108>
    p = &proc[unused];
    800020f6:	18800993          	li	s3,392
    800020fa:	033909b3          	mul	s3,s2,s3
    800020fe:	00008497          	auipc	s1,0x8
    80002102:	1a248493          	addi	s1,s1,418 # 8000a2a0 <proc>
    80002106:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	ada080e7          	jalr	-1318(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80002112:	00000097          	auipc	ra,0x0
    80002116:	dae080e7          	jalr	-594(ra) # 80001ec0 <allocpid>
    8000211a:	d888                	sw	a0,48(s1)
  remove_from_list(p->index,&unused,unused_head);
    8000211c:	00008797          	auipc	a5,0x8
    80002120:	07478793          	addi	a5,a5,116 # 8000a190 <pid_lock>
    80002124:	73b8                	ld	a4,96(a5)
    80002126:	fae43823          	sd	a4,-80(s0)
    8000212a:	77b8                	ld	a4,104(a5)
    8000212c:	fae43c23          	sd	a4,-72(s0)
    80002130:	7bbc                	ld	a5,112(a5)
    80002132:	fcf43023          	sd	a5,-64(s0)
    80002136:	fb040613          	addi	a2,s0,-80
    8000213a:	00007597          	auipc	a1,0x7
    8000213e:	92a58593          	addi	a1,a1,-1750 # 80008a64 <unused>
    80002142:	5c88                	lw	a0,56(s1)
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	7c8080e7          	jalr	1992(ra) # 8000190c <remove_from_list>
  p->state = USED;
    8000214c:	4785                	li	a5,1
    8000214e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	9a4080e7          	jalr	-1628(ra) # 80000af4 <kalloc>
    80002158:	8a2a                	mv	s4,a0
    8000215a:	fca8                	sd	a0,120(s1)
    8000215c:	c151                	beqz	a0,800021e0 <allocproc+0x11a>
  p->pagetable = proc_pagetable(p);
    8000215e:	8526                	mv	a0,s1
    80002160:	00000097          	auipc	ra,0x0
    80002164:	d98080e7          	jalr	-616(ra) # 80001ef8 <proc_pagetable>
    80002168:	8a2a                	mv	s4,a0
    8000216a:	18800793          	li	a5,392
    8000216e:	02f90733          	mul	a4,s2,a5
    80002172:	00008797          	auipc	a5,0x8
    80002176:	12e78793          	addi	a5,a5,302 # 8000a2a0 <proc>
    8000217a:	97ba                	add	a5,a5,a4
    8000217c:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    8000217e:	c549                	beqz	a0,80002208 <allocproc+0x142>
  memset(&p->context, 0, sizeof(p->context));
    80002180:	08098513          	addi	a0,s3,128
    80002184:	00008a17          	auipc	s4,0x8
    80002188:	11ca0a13          	addi	s4,s4,284 # 8000a2a0 <proc>
    8000218c:	07000613          	li	a2,112
    80002190:	4581                	li	a1,0
    80002192:	9552                	add	a0,a0,s4
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b70080e7          	jalr	-1168(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    8000219c:	18800793          	li	a5,392
    800021a0:	02f90933          	mul	s2,s2,a5
    800021a4:	9952                	add	s2,s2,s4
    800021a6:	00000797          	auipc	a5,0x0
    800021aa:	cd478793          	addi	a5,a5,-812 # 80001e7a <forkret>
    800021ae:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    800021b2:	06093783          	ld	a5,96(s2)
    800021b6:	6705                	lui	a4,0x1
    800021b8:	97ba                	add	a5,a5,a4
    800021ba:	08f93423          	sd	a5,136(s2)
  printf("exit allocproc in 3.\n");
    800021be:	00006517          	auipc	a0,0x6
    800021c2:	19250513          	addi	a0,a0,402 # 80008350 <digits+0x310>
    800021c6:	ffffe097          	auipc	ra,0xffffe
    800021ca:	3c2080e7          	jalr	962(ra) # 80000588 <printf>
}
    800021ce:	8526                	mv	a0,s1
    800021d0:	60a6                	ld	ra,72(sp)
    800021d2:	6406                	ld	s0,64(sp)
    800021d4:	74e2                	ld	s1,56(sp)
    800021d6:	7942                	ld	s2,48(sp)
    800021d8:	79a2                	ld	s3,40(sp)
    800021da:	7a02                	ld	s4,32(sp)
    800021dc:	6161                	addi	sp,sp,80
    800021de:	8082                	ret
    freeproc(p);
    800021e0:	8526                	mv	a0,s1
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	e04080e7          	jalr	-508(ra) # 80001fe6 <freeproc>
    release(&p->lock);
    800021ea:	8526                	mv	a0,s1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	abe080e7          	jalr	-1346(ra) # 80000caa <release>
    printf("exit allocproc in 1.\n");
    800021f4:	00006517          	auipc	a0,0x6
    800021f8:	12c50513          	addi	a0,a0,300 # 80008320 <digits+0x2e0>
    800021fc:	ffffe097          	auipc	ra,0xffffe
    80002200:	38c080e7          	jalr	908(ra) # 80000588 <printf>
    return 0;
    80002204:	84d2                	mv	s1,s4
    80002206:	b7e1                	j	800021ce <allocproc+0x108>
    freeproc(p);
    80002208:	8526                	mv	a0,s1
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	ddc080e7          	jalr	-548(ra) # 80001fe6 <freeproc>
    release(&p->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a96080e7          	jalr	-1386(ra) # 80000caa <release>
    printf("exit allocproc in 2.\n");
    8000221c:	00006517          	auipc	a0,0x6
    80002220:	11c50513          	addi	a0,a0,284 # 80008338 <digits+0x2f8>
    80002224:	ffffe097          	auipc	ra,0xffffe
    80002228:	364080e7          	jalr	868(ra) # 80000588 <printf>
    return 0;
    8000222c:	84d2                	mv	s1,s4
    8000222e:	b745                	j	800021ce <allocproc+0x108>

0000000080002230 <userinit>:
{
    80002230:	7139                	addi	sp,sp,-64
    80002232:	fc06                	sd	ra,56(sp)
    80002234:	f822                	sd	s0,48(sp)
    80002236:	f426                	sd	s1,40(sp)
    80002238:	0080                	addi	s0,sp,64
  printf("entered userinit\n");
    8000223a:	00006517          	auipc	a0,0x6
    8000223e:	12e50513          	addi	a0,a0,302 # 80008368 <digits+0x328>
    80002242:	ffffe097          	auipc	ra,0xffffe
    80002246:	346080e7          	jalr	838(ra) # 80000588 <printf>
  p = allocproc();
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	e7c080e7          	jalr	-388(ra) # 800020c6 <allocproc>
    80002252:	84aa                	mv	s1,a0
  initproc = p;
    80002254:	00007797          	auipc	a5,0x7
    80002258:	dca7be23          	sd	a0,-548(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000225c:	03400613          	li	a2,52
    80002260:	00007597          	auipc	a1,0x7
    80002264:	82058593          	addi	a1,a1,-2016 # 80008a80 <initcode>
    80002268:	7928                	ld	a0,112(a0)
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	122080e7          	jalr	290(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    80002272:	6785                	lui	a5,0x1
    80002274:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80002276:	7cb8                	ld	a4,120(s1)
    80002278:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000227c:	7cb8                	ld	a4,120(s1)
    8000227e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002280:	4641                	li	a2,16
    80002282:	00006597          	auipc	a1,0x6
    80002286:	0fe58593          	addi	a1,a1,254 # 80008380 <digits+0x340>
    8000228a:	17848513          	addi	a0,s1,376
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	bc8080e7          	jalr	-1080(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    80002296:	00006517          	auipc	a0,0x6
    8000229a:	0fa50513          	addi	a0,a0,250 # 80008390 <digits+0x350>
    8000229e:	00002097          	auipc	ra,0x2
    800022a2:	4f4080e7          	jalr	1268(ra) # 80004792 <namei>
    800022a6:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    800022aa:	478d                	li	a5,3
    800022ac:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index,&cpus_ll[0],cpus_head[0]);
    800022ae:	00008797          	auipc	a5,0x8
    800022b2:	ee278793          	addi	a5,a5,-286 # 8000a190 <pid_lock>
    800022b6:	7ff8                	ld	a4,248(a5)
    800022b8:	fce43023          	sd	a4,-64(s0)
    800022bc:	1007b703          	ld	a4,256(a5)
    800022c0:	fce43423          	sd	a4,-56(s0)
    800022c4:	1087b783          	ld	a5,264(a5)
    800022c8:	fcf43823          	sd	a5,-48(s0)
    800022cc:	fc040613          	addi	a2,s0,-64
    800022d0:	00007597          	auipc	a1,0x7
    800022d4:	d5858593          	addi	a1,a1,-680 # 80009028 <cpus_ll>
    800022d8:	5c88                	lw	a0,56(s1)
    800022da:	00000097          	auipc	ra,0x0
    800022de:	838080e7          	jalr	-1992(ra) # 80001b12 <insert_to_list>
  release(&p->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9c6080e7          	jalr	-1594(ra) # 80000caa <release>
  printf("exiting from userinit\n");
    800022ec:	00006517          	auipc	a0,0x6
    800022f0:	0ac50513          	addi	a0,a0,172 # 80008398 <digits+0x358>
    800022f4:	ffffe097          	auipc	ra,0xffffe
    800022f8:	294080e7          	jalr	660(ra) # 80000588 <printf>
}
    800022fc:	70e2                	ld	ra,56(sp)
    800022fe:	7442                	ld	s0,48(sp)
    80002300:	74a2                	ld	s1,40(sp)
    80002302:	6121                	addi	sp,sp,64
    80002304:	8082                	ret

0000000080002306 <growproc>:
{
    80002306:	1101                	addi	sp,sp,-32
    80002308:	ec06                	sd	ra,24(sp)
    8000230a:	e822                	sd	s0,16(sp)
    8000230c:	e426                	sd	s1,8(sp)
    8000230e:	e04a                	sd	s2,0(sp)
    80002310:	1000                	addi	s0,sp,32
    80002312:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002314:	00000097          	auipc	ra,0x0
    80002318:	b2e080e7          	jalr	-1234(ra) # 80001e42 <myproc>
    8000231c:	892a                	mv	s2,a0
  sz = p->sz;
    8000231e:	752c                	ld	a1,104(a0)
    80002320:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002324:	00904f63          	bgtz	s1,80002342 <growproc+0x3c>
  } else if(n < 0){
    80002328:	0204cc63          	bltz	s1,80002360 <growproc+0x5a>
  p->sz = sz;
    8000232c:	1602                	slli	a2,a2,0x20
    8000232e:	9201                	srli	a2,a2,0x20
    80002330:	06c93423          	sd	a2,104(s2)
  return 0;
    80002334:	4501                	li	a0,0
}
    80002336:	60e2                	ld	ra,24(sp)
    80002338:	6442                	ld	s0,16(sp)
    8000233a:	64a2                	ld	s1,8(sp)
    8000233c:	6902                	ld	s2,0(sp)
    8000233e:	6105                	addi	sp,sp,32
    80002340:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002342:	9e25                	addw	a2,a2,s1
    80002344:	1602                	slli	a2,a2,0x20
    80002346:	9201                	srli	a2,a2,0x20
    80002348:	1582                	slli	a1,a1,0x20
    8000234a:	9181                	srli	a1,a1,0x20
    8000234c:	7928                	ld	a0,112(a0)
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	0f8080e7          	jalr	248(ra) # 80001446 <uvmalloc>
    80002356:	0005061b          	sext.w	a2,a0
    8000235a:	fa69                	bnez	a2,8000232c <growproc+0x26>
      return -1;
    8000235c:	557d                	li	a0,-1
    8000235e:	bfe1                	j	80002336 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002360:	9e25                	addw	a2,a2,s1
    80002362:	1602                	slli	a2,a2,0x20
    80002364:	9201                	srli	a2,a2,0x20
    80002366:	1582                	slli	a1,a1,0x20
    80002368:	9181                	srli	a1,a1,0x20
    8000236a:	7928                	ld	a0,112(a0)
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	092080e7          	jalr	146(ra) # 800013fe <uvmdealloc>
    80002374:	0005061b          	sext.w	a2,a0
    80002378:	bf55                	j	8000232c <growproc+0x26>

000000008000237a <fork>:
{
    8000237a:	715d                	addi	sp,sp,-80
    8000237c:	e486                	sd	ra,72(sp)
    8000237e:	e0a2                	sd	s0,64(sp)
    80002380:	fc26                	sd	s1,56(sp)
    80002382:	f84a                	sd	s2,48(sp)
    80002384:	f44e                	sd	s3,40(sp)
    80002386:	f052                	sd	s4,32(sp)
    80002388:	0880                	addi	s0,sp,80
  printf("entered fork\n");
    8000238a:	00006517          	auipc	a0,0x6
    8000238e:	02650513          	addi	a0,a0,38 # 800083b0 <digits+0x370>
    80002392:	ffffe097          	auipc	ra,0xffffe
    80002396:	1f6080e7          	jalr	502(ra) # 80000588 <printf>
  struct proc *p = myproc();
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	aa8080e7          	jalr	-1368(ra) # 80001e42 <myproc>
    800023a2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	d22080e7          	jalr	-734(ra) # 800020c6 <allocproc>
    800023ac:	18050663          	beqz	a0,80002538 <fork+0x1be>
    800023b0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800023b2:	06893603          	ld	a2,104(s2)
    800023b6:	792c                	ld	a1,112(a0)
    800023b8:	07093503          	ld	a0,112(s2)
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	1d6080e7          	jalr	470(ra) # 80001592 <uvmcopy>
    800023c4:	04054663          	bltz	a0,80002410 <fork+0x96>
  np->sz = p->sz;
    800023c8:	06893783          	ld	a5,104(s2)
    800023cc:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    800023d0:	07893683          	ld	a3,120(s2)
    800023d4:	87b6                	mv	a5,a3
    800023d6:	0789b703          	ld	a4,120(s3)
    800023da:	12068693          	addi	a3,a3,288
    800023de:	0007b803          	ld	a6,0(a5)
    800023e2:	6788                	ld	a0,8(a5)
    800023e4:	6b8c                	ld	a1,16(a5)
    800023e6:	6f90                	ld	a2,24(a5)
    800023e8:	01073023          	sd	a6,0(a4)
    800023ec:	e708                	sd	a0,8(a4)
    800023ee:	eb0c                	sd	a1,16(a4)
    800023f0:	ef10                	sd	a2,24(a4)
    800023f2:	02078793          	addi	a5,a5,32
    800023f6:	02070713          	addi	a4,a4,32
    800023fa:	fed792e3          	bne	a5,a3,800023de <fork+0x64>
  np->trapframe->a0 = 0;
    800023fe:	0789b783          	ld	a5,120(s3)
    80002402:	0607b823          	sd	zero,112(a5)
    80002406:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000240a:	17000a13          	li	s4,368
    8000240e:	a03d                	j	8000243c <fork+0xc2>
    freeproc(np);
    80002410:	854e                	mv	a0,s3
    80002412:	00000097          	auipc	ra,0x0
    80002416:	bd4080e7          	jalr	-1068(ra) # 80001fe6 <freeproc>
    release(&np->lock);
    8000241a:	854e                	mv	a0,s3
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	88e080e7          	jalr	-1906(ra) # 80000caa <release>
    return -1;
    80002424:	5a7d                	li	s4,-1
    80002426:	a201                	j	80002526 <fork+0x1ac>
      np->ofile[i] = filedup(p->ofile[i]);
    80002428:	00003097          	auipc	ra,0x3
    8000242c:	a00080e7          	jalr	-1536(ra) # 80004e28 <filedup>
    80002430:	009987b3          	add	a5,s3,s1
    80002434:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002436:	04a1                	addi	s1,s1,8
    80002438:	01448763          	beq	s1,s4,80002446 <fork+0xcc>
    if(p->ofile[i])
    8000243c:	009907b3          	add	a5,s2,s1
    80002440:	6388                	ld	a0,0(a5)
    80002442:	f17d                	bnez	a0,80002428 <fork+0xae>
    80002444:	bfcd                	j	80002436 <fork+0xbc>
  np->cwd = idup(p->cwd);
    80002446:	17093503          	ld	a0,368(s2)
    8000244a:	00002097          	auipc	ra,0x2
    8000244e:	b54080e7          	jalr	-1196(ra) # 80003f9e <idup>
    80002452:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002456:	4641                	li	a2,16
    80002458:	17890593          	addi	a1,s2,376
    8000245c:	17898513          	addi	a0,s3,376
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	9f6080e7          	jalr	-1546(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    80002468:	0309aa03          	lw	s4,48(s3)
  np->cpu_num=p->cpu_num; //giving the child it's parent's cpu_num (the only change)
    8000246c:	03492783          	lw	a5,52(s2)
    80002470:	02f9aa23          	sw	a5,52(s3)
  initlock(&p->linked_list_lock,"inbar");
    80002474:	00006597          	auipc	a1,0x6
    80002478:	e4458593          	addi	a1,a1,-444 # 800082b8 <digits+0x278>
    8000247c:	04090513          	addi	a0,s2,64
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	6d4080e7          	jalr	1748(ra) # 80000b54 <initlock>
  release(&np->lock);
    80002488:	854e                	mv	a0,s3
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	820080e7          	jalr	-2016(ra) # 80000caa <release>
  acquire(&wait_lock);
    80002492:	00008497          	auipc	s1,0x8
    80002496:	d1648493          	addi	s1,s1,-746 # 8000a1a8 <wait_lock>
    8000249a:	8526                	mv	a0,s1
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	748080e7          	jalr	1864(ra) # 80000be4 <acquire>
  np->parent = p;
    800024a4:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    800024a8:	8526                	mv	a0,s1
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	800080e7          	jalr	-2048(ra) # 80000caa <release>
  acquire(&np->lock);
    800024b2:	854e                	mv	a0,s3
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	730080e7          	jalr	1840(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800024bc:	478d                	li	a5,3
    800024be:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(np->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    800024c2:	03492583          	lw	a1,52(s2)
    800024c6:	00159793          	slli	a5,a1,0x1
    800024ca:	97ae                	add	a5,a5,a1
    800024cc:	00379713          	slli	a4,a5,0x3
    800024d0:	00008797          	auipc	a5,0x8
    800024d4:	cc078793          	addi	a5,a5,-832 # 8000a190 <pid_lock>
    800024d8:	97ba                	add	a5,a5,a4
    800024da:	7ff8                	ld	a4,248(a5)
    800024dc:	fae43823          	sd	a4,-80(s0)
    800024e0:	1007b703          	ld	a4,256(a5)
    800024e4:	fae43c23          	sd	a4,-72(s0)
    800024e8:	1087b783          	ld	a5,264(a5)
    800024ec:	fcf43023          	sd	a5,-64(s0)
    800024f0:	058a                	slli	a1,a1,0x2
    800024f2:	fb040613          	addi	a2,s0,-80
    800024f6:	00007797          	auipc	a5,0x7
    800024fa:	b3278793          	addi	a5,a5,-1230 # 80009028 <cpus_ll>
    800024fe:	95be                	add	a1,a1,a5
    80002500:	0389a503          	lw	a0,56(s3)
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	60e080e7          	jalr	1550(ra) # 80001b12 <insert_to_list>
  release(&np->lock);
    8000250c:	854e                	mv	a0,s3
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	79c080e7          	jalr	1948(ra) # 80000caa <release>
  printf("finished fork\n");
    80002516:	00006517          	auipc	a0,0x6
    8000251a:	eaa50513          	addi	a0,a0,-342 # 800083c0 <digits+0x380>
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	06a080e7          	jalr	106(ra) # 80000588 <printf>
}
    80002526:	8552                	mv	a0,s4
    80002528:	60a6                	ld	ra,72(sp)
    8000252a:	6406                	ld	s0,64(sp)
    8000252c:	74e2                	ld	s1,56(sp)
    8000252e:	7942                	ld	s2,48(sp)
    80002530:	79a2                	ld	s3,40(sp)
    80002532:	7a02                	ld	s4,32(sp)
    80002534:	6161                	addi	sp,sp,80
    80002536:	8082                	ret
    return -1;
    80002538:	5a7d                	li	s4,-1
    8000253a:	b7f5                	j	80002526 <fork+0x1ac>

000000008000253c <scheduler>:
{
    8000253c:	7119                	addi	sp,sp,-128
    8000253e:	fc86                	sd	ra,120(sp)
    80002540:	f8a2                	sd	s0,112(sp)
    80002542:	f4a6                	sd	s1,104(sp)
    80002544:	f0ca                	sd	s2,96(sp)
    80002546:	ecce                	sd	s3,88(sp)
    80002548:	e8d2                	sd	s4,80(sp)
    8000254a:	e4d6                	sd	s5,72(sp)
    8000254c:	e0da                	sd	s6,64(sp)
    8000254e:	fc5e                	sd	s7,56(sp)
    80002550:	f862                	sd	s8,48(sp)
    80002552:	f466                	sd	s9,40(sp)
    80002554:	f06a                	sd	s10,32(sp)
    80002556:	0100                	addi	s0,sp,128
  printf("entered scheduler\n");
    80002558:	00006517          	auipc	a0,0x6
    8000255c:	e7850513          	addi	a0,a0,-392 # 800083d0 <digits+0x390>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	028080e7          	jalr	40(ra) # 80000588 <printf>
  struct proc *p=myproc();
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	8da080e7          	jalr	-1830(ra) # 80001e42 <myproc>
    80002570:	8492                	mv	s1,tp
  int id = r_tp();
    80002572:	2481                	sext.w	s1,s1
    80002574:	8592                	mv	a1,tp
  printf("the cpuid=%d\n",cpuid());
    80002576:	2581                	sext.w	a1,a1
    80002578:	00006517          	auipc	a0,0x6
    8000257c:	e7050513          	addi	a0,a0,-400 # 800083e8 <digits+0x3a8>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	008080e7          	jalr	8(ra) # 80000588 <printf>
  c->proc = 0;
    80002588:	00749c13          	slli	s8,s1,0x7
    8000258c:	00008797          	auipc	a5,0x8
    80002590:	c0478793          	addi	a5,a5,-1020 # 8000a190 <pid_lock>
    80002594:	97e2                	add	a5,a5,s8
    80002596:	0607bc23          	sd	zero,120(a5)
        swtch(&c->context, &p->context);
    8000259a:	00008797          	auipc	a5,0x8
    8000259e:	c7678793          	addi	a5,a5,-906 # 8000a210 <cpus+0x8>
    800025a2:	9c3e                	add	s8,s8,a5
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800025a4:	00007997          	auipc	s3,0x7
    800025a8:	a8498993          	addi	s3,s3,-1404 # 80009028 <cpus_ll>
    800025ac:	5a7d                	li	s4,-1
    800025ae:	18800d13          	li	s10,392
      p = &proc[cpus_ll[cpuid()]];
    800025b2:	00008b17          	auipc	s6,0x8
    800025b6:	ceeb0b13          	addi	s6,s6,-786 # 8000a2a0 <proc>
      remove_from_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
    800025ba:	00008c97          	auipc	s9,0x8
    800025be:	bd6c8c93          	addi	s9,s9,-1066 # 8000a190 <pid_lock>
        c->proc = p;
    800025c2:	049e                	slli	s1,s1,0x7
    800025c4:	009c8ab3          	add	s5,s9,s1
    800025c8:	a841                	j	80002658 <scheduler+0x11c>
    800025ca:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    800025cc:	2781                	sext.w	a5,a5
    800025ce:	078a                	slli	a5,a5,0x2
    800025d0:	97ce                	add	a5,a5,s3
    800025d2:	4384                	lw	s1,0(a5)
    800025d4:	03a484b3          	mul	s1,s1,s10
    800025d8:	01648933          	add	s2,s1,s6
    800025dc:	8592                	mv	a1,tp
    800025de:	8792                	mv	a5,tp
      remove_from_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
    800025e0:	0007871b          	sext.w	a4,a5
    800025e4:	00171793          	slli	a5,a4,0x1
    800025e8:	97ba                	add	a5,a5,a4
    800025ea:	078e                	slli	a5,a5,0x3
    800025ec:	97e6                	add	a5,a5,s9
    800025ee:	7ff8                	ld	a4,248(a5)
    800025f0:	f8e43023          	sd	a4,-128(s0)
    800025f4:	1007b703          	ld	a4,256(a5)
    800025f8:	f8e43423          	sd	a4,-120(s0)
    800025fc:	1087b783          	ld	a5,264(a5)
    80002600:	f8f43823          	sd	a5,-112(s0)
    80002604:	2581                	sext.w	a1,a1
    80002606:	058a                	slli	a1,a1,0x2
    80002608:	f8040613          	addi	a2,s0,-128
    8000260c:	95ce                	add	a1,a1,s3
    8000260e:	03892503          	lw	a0,56(s2)
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	2fa080e7          	jalr	762(ra) # 8000190c <remove_from_list>
      acquire(&p->lock);
    8000261a:	854a                	mv	a0,s2
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	5c8080e7          	jalr	1480(ra) # 80000be4 <acquire>
        p->state = RUNNING;
    80002624:	01792c23          	sw	s7,24(s2)
        c->proc = p;
    80002628:	072abc23          	sd	s2,120(s5)
        swtch(&c->context, &p->context);
    8000262c:	08048593          	addi	a1,s1,128
    80002630:	95da                	add	a1,a1,s6
    80002632:	8562                	mv	a0,s8
    80002634:	00001097          	auipc	ra,0x1
    80002638:	944080e7          	jalr	-1724(ra) # 80002f78 <swtch>
        c->proc = 0;
    8000263c:	060abc23          	sd	zero,120(s5)
        release(&p->lock);
    80002640:	854a                	mv	a0,s2
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	668080e7          	jalr	1640(ra) # 80000caa <release>
    8000264a:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    8000264c:	2781                	sext.w	a5,a5
    8000264e:	078a                	slli	a5,a5,0x2
    80002650:	97ce                	add	a5,a5,s3
    80002652:	439c                	lw	a5,0(a5)
    80002654:	f7479be3          	bne	a5,s4,800025ca <scheduler+0x8e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002658:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000265c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002660:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002664:	8792                	mv	a5,tp
    80002666:	2781                	sext.w	a5,a5
    80002668:	078a                	slli	a5,a5,0x2
    8000266a:	97ce                	add	a5,a5,s3
    8000266c:	439c                	lw	a5,0(a5)
    8000266e:	ff4785e3          	beq	a5,s4,80002658 <scheduler+0x11c>
        p->state = RUNNING;
    80002672:	4b91                	li	s7,4
    80002674:	bf99                	j	800025ca <scheduler+0x8e>

0000000080002676 <sched>:
{
    80002676:	7179                	addi	sp,sp,-48
    80002678:	f406                	sd	ra,40(sp)
    8000267a:	f022                	sd	s0,32(sp)
    8000267c:	ec26                	sd	s1,24(sp)
    8000267e:	e84a                	sd	s2,16(sp)
    80002680:	e44e                	sd	s3,8(sp)
    80002682:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	7be080e7          	jalr	1982(ra) # 80001e42 <myproc>
    8000268c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	4dc080e7          	jalr	1244(ra) # 80000b6a <holding>
    80002696:	c93d                	beqz	a0,8000270c <sched+0x96>
    80002698:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    8000269a:	2781                	sext.w	a5,a5
    8000269c:	079e                	slli	a5,a5,0x7
    8000269e:	00008717          	auipc	a4,0x8
    800026a2:	af270713          	addi	a4,a4,-1294 # 8000a190 <pid_lock>
    800026a6:	97ba                	add	a5,a5,a4
    800026a8:	0f07a703          	lw	a4,240(a5)
    800026ac:	4785                	li	a5,1
    800026ae:	06f71763          	bne	a4,a5,8000271c <sched+0xa6>
  if(p->state == RUNNING)
    800026b2:	4c98                	lw	a4,24(s1)
    800026b4:	4791                	li	a5,4
    800026b6:	06f70b63          	beq	a4,a5,8000272c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026be:	8b89                	andi	a5,a5,2
  if(intr_get())
    800026c0:	efb5                	bnez	a5,8000273c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800026c2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800026c4:	00008917          	auipc	s2,0x8
    800026c8:	acc90913          	addi	s2,s2,-1332 # 8000a190 <pid_lock>
    800026cc:	2781                	sext.w	a5,a5
    800026ce:	079e                	slli	a5,a5,0x7
    800026d0:	97ca                	add	a5,a5,s2
    800026d2:	0f47a983          	lw	s3,244(a5)
    800026d6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800026d8:	2781                	sext.w	a5,a5
    800026da:	079e                	slli	a5,a5,0x7
    800026dc:	00008597          	auipc	a1,0x8
    800026e0:	b3458593          	addi	a1,a1,-1228 # 8000a210 <cpus+0x8>
    800026e4:	95be                	add	a1,a1,a5
    800026e6:	08048513          	addi	a0,s1,128
    800026ea:	00001097          	auipc	ra,0x1
    800026ee:	88e080e7          	jalr	-1906(ra) # 80002f78 <swtch>
    800026f2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800026f4:	2781                	sext.w	a5,a5
    800026f6:	079e                	slli	a5,a5,0x7
    800026f8:	97ca                	add	a5,a5,s2
    800026fa:	0f37aa23          	sw	s3,244(a5)
}
    800026fe:	70a2                	ld	ra,40(sp)
    80002700:	7402                	ld	s0,32(sp)
    80002702:	64e2                	ld	s1,24(sp)
    80002704:	6942                	ld	s2,16(sp)
    80002706:	69a2                	ld	s3,8(sp)
    80002708:	6145                	addi	sp,sp,48
    8000270a:	8082                	ret
    panic("sched p->lock");
    8000270c:	00006517          	auipc	a0,0x6
    80002710:	cec50513          	addi	a0,a0,-788 # 800083f8 <digits+0x3b8>
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	e2a080e7          	jalr	-470(ra) # 8000053e <panic>
    panic("sched locks");
    8000271c:	00006517          	auipc	a0,0x6
    80002720:	cec50513          	addi	a0,a0,-788 # 80008408 <digits+0x3c8>
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	e1a080e7          	jalr	-486(ra) # 8000053e <panic>
    panic("sched running");
    8000272c:	00006517          	auipc	a0,0x6
    80002730:	cec50513          	addi	a0,a0,-788 # 80008418 <digits+0x3d8>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	e0a080e7          	jalr	-502(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000273c:	00006517          	auipc	a0,0x6
    80002740:	cec50513          	addi	a0,a0,-788 # 80008428 <digits+0x3e8>
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	dfa080e7          	jalr	-518(ra) # 8000053e <panic>

000000008000274c <yield>:
{
    8000274c:	7139                	addi	sp,sp,-64
    8000274e:	fc06                	sd	ra,56(sp)
    80002750:	f822                	sd	s0,48(sp)
    80002752:	f426                	sd	s1,40(sp)
    80002754:	0080                	addi	s0,sp,64
  printf("entered yield\n");
    80002756:	00006517          	auipc	a0,0x6
    8000275a:	cea50513          	addi	a0,a0,-790 # 80008440 <digits+0x400>
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	e2a080e7          	jalr	-470(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	6dc080e7          	jalr	1756(ra) # 80001e42 <myproc>
    8000276e:	84aa                	mv	s1,a0
  insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002770:	594c                	lw	a1,52(a0)
    80002772:	00159793          	slli	a5,a1,0x1
    80002776:	97ae                	add	a5,a5,a1
    80002778:	00379713          	slli	a4,a5,0x3
    8000277c:	00008797          	auipc	a5,0x8
    80002780:	a1478793          	addi	a5,a5,-1516 # 8000a190 <pid_lock>
    80002784:	97ba                	add	a5,a5,a4
    80002786:	7ff8                	ld	a4,248(a5)
    80002788:	fce43023          	sd	a4,-64(s0)
    8000278c:	1007b703          	ld	a4,256(a5)
    80002790:	fce43423          	sd	a4,-56(s0)
    80002794:	1087b783          	ld	a5,264(a5)
    80002798:	fcf43823          	sd	a5,-48(s0)
    8000279c:	058a                	slli	a1,a1,0x2
    8000279e:	fc040613          	addi	a2,s0,-64
    800027a2:	00007797          	auipc	a5,0x7
    800027a6:	88678793          	addi	a5,a5,-1914 # 80009028 <cpus_ll>
    800027aa:	95be                	add	a1,a1,a5
    800027ac:	5d08                	lw	a0,56(a0)
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	364080e7          	jalr	868(ra) # 80001b12 <insert_to_list>
  acquire(&p->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	42c080e7          	jalr	1068(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800027c0:	478d                	li	a5,3
    800027c2:	cc9c                	sw	a5,24(s1)
  sched();
    800027c4:	00000097          	auipc	ra,0x0
    800027c8:	eb2080e7          	jalr	-334(ra) # 80002676 <sched>
  release(&p->lock);
    800027cc:	8526                	mv	a0,s1
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4dc080e7          	jalr	1244(ra) # 80000caa <release>
  printf("exit yield\n");
    800027d6:	00006517          	auipc	a0,0x6
    800027da:	c7a50513          	addi	a0,a0,-902 # 80008450 <digits+0x410>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	daa080e7          	jalr	-598(ra) # 80000588 <printf>
}
    800027e6:	70e2                	ld	ra,56(sp)
    800027e8:	7442                	ld	s0,48(sp)
    800027ea:	74a2                	ld	s1,40(sp)
    800027ec:	6121                	addi	sp,sp,64
    800027ee:	8082                	ret

00000000800027f0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800027f0:	715d                	addi	sp,sp,-80
    800027f2:	e486                	sd	ra,72(sp)
    800027f4:	e0a2                	sd	s0,64(sp)
    800027f6:	fc26                	sd	s1,56(sp)
    800027f8:	f84a                	sd	s2,48(sp)
    800027fa:	f44e                	sd	s3,40(sp)
    800027fc:	0880                	addi	s0,sp,80
    800027fe:	89aa                	mv	s3,a0
    80002800:	892e                	mv	s2,a1
  //printf("entered sleep\n");
  struct proc *p = myproc();
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	640080e7          	jalr	1600(ra) # 80001e42 <myproc>
    8000280a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  insert_to_list(p->index,&sleeping,sleeping_head);
    8000280c:	00008797          	auipc	a5,0x8
    80002810:	98478793          	addi	a5,a5,-1660 # 8000a190 <pid_lock>
    80002814:	7b98                	ld	a4,48(a5)
    80002816:	fae43823          	sd	a4,-80(s0)
    8000281a:	7f98                	ld	a4,56(a5)
    8000281c:	fae43c23          	sd	a4,-72(s0)
    80002820:	63bc                	ld	a5,64(a5)
    80002822:	fcf43023          	sd	a5,-64(s0)
    80002826:	fb040613          	addi	a2,s0,-80
    8000282a:	00006597          	auipc	a1,0x6
    8000282e:	24258593          	addi	a1,a1,578 # 80008a6c <sleeping>
    80002832:	5d08                	lw	a0,56(a0)
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	2de080e7          	jalr	734(ra) # 80001b12 <insert_to_list>
  acquire(&p->lock);  //DOC: sleeplock1
    8000283c:	8526                	mv	a0,s1
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	3a6080e7          	jalr	934(ra) # 80000be4 <acquire>
  release(lk);
    80002846:	854a                	mv	a0,s2
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	462080e7          	jalr	1122(ra) # 80000caa <release>

  // Go to sleep.
  p->chan = chan;
    80002850:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002854:	4789                	li	a5,2
    80002856:	cc9c                	sw	a5,24(s1)
  //printf("the number of locks is:%d\n",mycpu()->noff);
  sched();
    80002858:	00000097          	auipc	ra,0x0
    8000285c:	e1e080e7          	jalr	-482(ra) # 80002676 <sched>

  // Tidy up.
  p->chan = 0;
    80002860:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	444080e7          	jalr	1092(ra) # 80000caa <release>
  acquire(lk);
    8000286e:	854a                	mv	a0,s2
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	374080e7          	jalr	884(ra) # 80000be4 <acquire>

}
    80002878:	60a6                	ld	ra,72(sp)
    8000287a:	6406                	ld	s0,64(sp)
    8000287c:	74e2                	ld	s1,56(sp)
    8000287e:	7942                	ld	s2,48(sp)
    80002880:	79a2                	ld	s3,40(sp)
    80002882:	6161                	addi	sp,sp,80
    80002884:	8082                	ret

0000000080002886 <wait>:
{
    80002886:	715d                	addi	sp,sp,-80
    80002888:	e486                	sd	ra,72(sp)
    8000288a:	e0a2                	sd	s0,64(sp)
    8000288c:	fc26                	sd	s1,56(sp)
    8000288e:	f84a                	sd	s2,48(sp)
    80002890:	f44e                	sd	s3,40(sp)
    80002892:	f052                	sd	s4,32(sp)
    80002894:	ec56                	sd	s5,24(sp)
    80002896:	e85a                	sd	s6,16(sp)
    80002898:	e45e                	sd	s7,8(sp)
    8000289a:	e062                	sd	s8,0(sp)
    8000289c:	0880                	addi	s0,sp,80
    8000289e:	8b2a                	mv	s6,a0
  printf("entered wait\n");
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	bc050513          	addi	a0,a0,-1088 # 80008460 <digits+0x420>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	ce0080e7          	jalr	-800(ra) # 80000588 <printf>
  struct proc *p = myproc();
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	592080e7          	jalr	1426(ra) # 80001e42 <myproc>
    800028b8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028ba:	00008517          	auipc	a0,0x8
    800028be:	8ee50513          	addi	a0,a0,-1810 # 8000a1a8 <wait_lock>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	322080e7          	jalr	802(ra) # 80000be4 <acquire>
    havekids = 0;
    800028ca:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800028cc:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800028ce:	0000e997          	auipc	s3,0xe
    800028d2:	bd298993          	addi	s3,s3,-1070 # 800104a0 <tickslock>
        havekids = 1;
    800028d6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028d8:	00008c17          	auipc	s8,0x8
    800028dc:	8d0c0c13          	addi	s8,s8,-1840 # 8000a1a8 <wait_lock>
    havekids = 0;
    800028e0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800028e2:	00008497          	auipc	s1,0x8
    800028e6:	9be48493          	addi	s1,s1,-1602 # 8000a2a0 <proc>
    800028ea:	a079                	j	80002978 <wait+0xf2>
          pid = np->pid;
    800028ec:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028f0:	000b0e63          	beqz	s6,8000290c <wait+0x86>
    800028f4:	4691                	li	a3,4
    800028f6:	02c48613          	addi	a2,s1,44
    800028fa:	85da                	mv	a1,s6
    800028fc:	07093503          	ld	a0,112(s2)
    80002900:	fffff097          	auipc	ra,0xfffff
    80002904:	d96080e7          	jalr	-618(ra) # 80001696 <copyout>
    80002908:	02054d63          	bltz	a0,80002942 <wait+0xbc>
          freeproc(np);
    8000290c:	8526                	mv	a0,s1
    8000290e:	fffff097          	auipc	ra,0xfffff
    80002912:	6d8080e7          	jalr	1752(ra) # 80001fe6 <freeproc>
          release(&np->lock);
    80002916:	8526                	mv	a0,s1
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	392080e7          	jalr	914(ra) # 80000caa <release>
          release(&wait_lock);
    80002920:	00008517          	auipc	a0,0x8
    80002924:	88850513          	addi	a0,a0,-1912 # 8000a1a8 <wait_lock>
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	382080e7          	jalr	898(ra) # 80000caa <release>
          printf("exited wait2\n");
    80002930:	00006517          	auipc	a0,0x6
    80002934:	b5050513          	addi	a0,a0,-1200 # 80008480 <digits+0x440>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c50080e7          	jalr	-944(ra) # 80000588 <printf>
          return pid;
    80002940:	a059                	j	800029c6 <wait+0x140>
            release(&np->lock);
    80002942:	8526                	mv	a0,s1
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	366080e7          	jalr	870(ra) # 80000caa <release>
            release(&wait_lock);
    8000294c:	00008517          	auipc	a0,0x8
    80002950:	85c50513          	addi	a0,a0,-1956 # 8000a1a8 <wait_lock>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	356080e7          	jalr	854(ra) # 80000caa <release>
            printf("exited wait1\n");
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	b1450513          	addi	a0,a0,-1260 # 80008470 <digits+0x430>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c24080e7          	jalr	-988(ra) # 80000588 <printf>
            return -1;
    8000296c:	59fd                	li	s3,-1
    8000296e:	a8a1                	j	800029c6 <wait+0x140>
    for(np = proc; np < &proc[NPROC]; np++){
    80002970:	18848493          	addi	s1,s1,392
    80002974:	03348463          	beq	s1,s3,8000299c <wait+0x116>
      if(np->parent == p){
    80002978:	6cbc                	ld	a5,88(s1)
    8000297a:	ff279be3          	bne	a5,s2,80002970 <wait+0xea>
        acquire(&np->lock);
    8000297e:	8526                	mv	a0,s1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	264080e7          	jalr	612(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002988:	4c9c                	lw	a5,24(s1)
    8000298a:	f74781e3          	beq	a5,s4,800028ec <wait+0x66>
        release(&np->lock);
    8000298e:	8526                	mv	a0,s1
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	31a080e7          	jalr	794(ra) # 80000caa <release>
        havekids = 1;
    80002998:	8756                	mv	a4,s5
    8000299a:	bfd9                	j	80002970 <wait+0xea>
    if(!havekids || p->killed){
    8000299c:	c701                	beqz	a4,800029a4 <wait+0x11e>
    8000299e:	02892783          	lw	a5,40(s2)
    800029a2:	cf9d                	beqz	a5,800029e0 <wait+0x15a>
      release(&wait_lock);
    800029a4:	00008517          	auipc	a0,0x8
    800029a8:	80450513          	addi	a0,a0,-2044 # 8000a1a8 <wait_lock>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	2fe080e7          	jalr	766(ra) # 80000caa <release>
      printf("exited wait3\n");
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	adc50513          	addi	a0,a0,-1316 # 80008490 <digits+0x450>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bcc080e7          	jalr	-1076(ra) # 80000588 <printf>
      return -1;
    800029c4:	59fd                	li	s3,-1
}
    800029c6:	854e                	mv	a0,s3
    800029c8:	60a6                	ld	ra,72(sp)
    800029ca:	6406                	ld	s0,64(sp)
    800029cc:	74e2                	ld	s1,56(sp)
    800029ce:	7942                	ld	s2,48(sp)
    800029d0:	79a2                	ld	s3,40(sp)
    800029d2:	7a02                	ld	s4,32(sp)
    800029d4:	6ae2                	ld	s5,24(sp)
    800029d6:	6b42                	ld	s6,16(sp)
    800029d8:	6ba2                	ld	s7,8(sp)
    800029da:	6c02                	ld	s8,0(sp)
    800029dc:	6161                	addi	sp,sp,80
    800029de:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800029e0:	85e2                	mv	a1,s8
    800029e2:	854a                	mv	a0,s2
    800029e4:	00000097          	auipc	ra,0x0
    800029e8:	e0c080e7          	jalr	-500(ra) # 800027f0 <sleep>
    havekids = 0;
    800029ec:	bdd5                	j	800028e0 <wait+0x5a>

00000000800029ee <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800029ee:	7159                	addi	sp,sp,-112
    800029f0:	f486                	sd	ra,104(sp)
    800029f2:	f0a2                	sd	s0,96(sp)
    800029f4:	eca6                	sd	s1,88(sp)
    800029f6:	e8ca                	sd	s2,80(sp)
    800029f8:	e4ce                	sd	s3,72(sp)
    800029fa:	e0d2                	sd	s4,64(sp)
    800029fc:	fc56                	sd	s5,56(sp)
    800029fe:	f85a                	sd	s6,48(sp)
    80002a00:	f45e                	sd	s7,40(sp)
    80002a02:	f062                	sd	s8,32(sp)
    80002a04:	1880                	addi	s0,sp,112
  struct proc *p;
  if (sleeping == -1){
    80002a06:	00006917          	auipc	s2,0x6
    80002a0a:	06692903          	lw	s2,102(s2) # 80008a6c <sleeping>
    80002a0e:	57fd                	li	a5,-1
    80002a10:	1af90263          	beq	s2,a5,80002bb4 <wakeup+0x1c6>
    80002a14:	89aa                	mv	s3,a0
    return;
  } // if no one is sleeping - do nothing
  //acquire(&sleeping_head);
  p = &proc[sleeping];
    80002a16:	18800493          	li	s1,392
    80002a1a:	029904b3          	mul	s1,s2,s1
    80002a1e:	00008797          	auipc	a5,0x8
    80002a22:	88278793          	addi	a5,a5,-1918 # 8000a2a0 <proc>
    80002a26:	94be                	add	s1,s1,a5
  if (p->next == -1){ // there is only one sleeper
    80002a28:	5cdc                	lw	a5,60(s1)
    80002a2a:	2781                	sext.w	a5,a5
    80002a2c:	577d                	li	a4,-1
    80002a2e:	04e78163          	beq	a5,a4,80002a70 <wakeup+0x82>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
      }
      release(&p->lock);
    }  
  }
  while(p->next != -1 ) { // loop through all sleepers
    80002a32:	18800793          	li	a5,392
    80002a36:	02f90933          	mul	s2,s2,a5
    80002a3a:	00008797          	auipc	a5,0x8
    80002a3e:	86678793          	addi	a5,a5,-1946 # 8000a2a0 <proc>
    80002a42:	993e                	add	s2,s2,a5
    80002a44:	03c92783          	lw	a5,60(s2)
    80002a48:	2781                	sext.w	a5,a5
    80002a4a:	577d                	li	a4,-1
    80002a4c:	16e78463          	beq	a5,a4,80002bb4 <wakeup+0x1c6>
    if(p != myproc()){
      //printf("process p->pid = %d\n", p->pid);
      acquire(&p->lock);
      if(p->chan == chan && p->state==SLEEPING) {
    80002a50:	4a09                	li	s4,2
        remove_from_list(p->index,&sleeping,sleeping_head);
    80002a52:	00007a97          	auipc	s5,0x7
    80002a56:	73ea8a93          	addi	s5,s5,1854 # 8000a190 <pid_lock>
    80002a5a:	00006c17          	auipc	s8,0x6
    80002a5e:	012c0c13          	addi	s8,s8,18 # 80008a6c <sleeping>
        p->state = RUNNABLE;
    80002a62:	4b8d                	li	s7,3
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002a64:	00006b17          	auipc	s6,0x6
    80002a68:	5c4b0b13          	addi	s6,s6,1476 # 80009028 <cpus_ll>
  while(p->next != -1 ) { // loop through all sleepers
    80002a6c:	597d                	li	s2,-1
    80002a6e:	a0c9                	j	80002b30 <wakeup+0x142>
    if(p != myproc()){ 
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	3d2080e7          	jalr	978(ra) # 80001e42 <myproc>
    80002a78:	faa48de3          	beq	s1,a0,80002a32 <wakeup+0x44>
      acquire(&p->lock);
    80002a7c:	8526                	mv	a0,s1
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	166080e7          	jalr	358(ra) # 80000be4 <acquire>
      if(p->chan == chan && p->state == SLEEPING) {
    80002a86:	709c                	ld	a5,32(s1)
    80002a88:	01378863          	beq	a5,s3,80002a98 <wakeup+0xaa>
      release(&p->lock);
    80002a8c:	8526                	mv	a0,s1
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	21c080e7          	jalr	540(ra) # 80000caa <release>
    80002a96:	bf71                	j	80002a32 <wakeup+0x44>
      if(p->chan == chan && p->state == SLEEPING) {
    80002a98:	4c98                	lw	a4,24(s1)
    80002a9a:	4789                	li	a5,2
    80002a9c:	fef718e3          	bne	a4,a5,80002a8c <wakeup+0x9e>
        remove_from_list(p->index, &sleeping, sleeping_head);
    80002aa0:	00007a17          	auipc	s4,0x7
    80002aa4:	6f0a0a13          	addi	s4,s4,1776 # 8000a190 <pid_lock>
    80002aa8:	030a3783          	ld	a5,48(s4)
    80002aac:	f8f43823          	sd	a5,-112(s0)
    80002ab0:	038a3783          	ld	a5,56(s4)
    80002ab4:	f8f43c23          	sd	a5,-104(s0)
    80002ab8:	040a3783          	ld	a5,64(s4)
    80002abc:	faf43023          	sd	a5,-96(s0)
    80002ac0:	f9040613          	addi	a2,s0,-112
    80002ac4:	00006597          	auipc	a1,0x6
    80002ac8:	fa858593          	addi	a1,a1,-88 # 80008a6c <sleeping>
    80002acc:	5c88                	lw	a0,56(s1)
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	e3e080e7          	jalr	-450(ra) # 8000190c <remove_from_list>
        p->state = RUNNABLE;
    80002ad6:	478d                	li	a5,3
    80002ad8:	cc9c                	sw	a5,24(s1)
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002ada:	58dc                	lw	a5,52(s1)
    80002adc:	00179713          	slli	a4,a5,0x1
    80002ae0:	973e                	add	a4,a4,a5
    80002ae2:	070e                	slli	a4,a4,0x3
    80002ae4:	9a3a                	add	s4,s4,a4
    80002ae6:	0f8a3703          	ld	a4,248(s4)
    80002aea:	f8e43823          	sd	a4,-112(s0)
    80002aee:	100a3703          	ld	a4,256(s4)
    80002af2:	f8e43c23          	sd	a4,-104(s0)
    80002af6:	108a3703          	ld	a4,264(s4)
    80002afa:	fae43023          	sd	a4,-96(s0)
    80002afe:	078a                	slli	a5,a5,0x2
    80002b00:	f9040613          	addi	a2,s0,-112
    80002b04:	00006597          	auipc	a1,0x6
    80002b08:	52458593          	addi	a1,a1,1316 # 80009028 <cpus_ll>
    80002b0c:	95be                	add	a1,a1,a5
    80002b0e:	5c88                	lw	a0,56(s1)
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	002080e7          	jalr	2(ra) # 80001b12 <insert_to_list>
    80002b18:	bf95                	j	80002a8c <wakeup+0x9e>
      }
      release(&p->lock);
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	18e080e7          	jalr	398(ra) # 80000caa <release>
    }
    p++;
    80002b24:	18848493          	addi	s1,s1,392
  while(p->next != -1 ) { // loop through all sleepers
    80002b28:	5cdc                	lw	a5,60(s1)
    80002b2a:	2781                	sext.w	a5,a5
    80002b2c:	09278463          	beq	a5,s2,80002bb4 <wakeup+0x1c6>
    if(p != myproc()){
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	312080e7          	jalr	786(ra) # 80001e42 <myproc>
    80002b38:	fea486e3          	beq	s1,a0,80002b24 <wakeup+0x136>
      acquire(&p->lock);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	0a6080e7          	jalr	166(ra) # 80000be4 <acquire>
      if(p->chan == chan && p->state==SLEEPING) {
    80002b46:	709c                	ld	a5,32(s1)
    80002b48:	fd3799e3          	bne	a5,s3,80002b1a <wakeup+0x12c>
    80002b4c:	4c9c                	lw	a5,24(s1)
    80002b4e:	fd4796e3          	bne	a5,s4,80002b1a <wakeup+0x12c>
        remove_from_list(p->index,&sleeping,sleeping_head);
    80002b52:	030ab783          	ld	a5,48(s5)
    80002b56:	f8f43823          	sd	a5,-112(s0)
    80002b5a:	038ab783          	ld	a5,56(s5)
    80002b5e:	f8f43c23          	sd	a5,-104(s0)
    80002b62:	040ab783          	ld	a5,64(s5)
    80002b66:	faf43023          	sd	a5,-96(s0)
    80002b6a:	f9040613          	addi	a2,s0,-112
    80002b6e:	85e2                	mv	a1,s8
    80002b70:	5c88                	lw	a0,56(s1)
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	d9a080e7          	jalr	-614(ra) # 8000190c <remove_from_list>
        p->state = RUNNABLE;
    80002b7a:	0174ac23          	sw	s7,24(s1)
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002b7e:	58cc                	lw	a1,52(s1)
    80002b80:	00159793          	slli	a5,a1,0x1
    80002b84:	97ae                	add	a5,a5,a1
    80002b86:	078e                	slli	a5,a5,0x3
    80002b88:	97d6                	add	a5,a5,s5
    80002b8a:	7ff8                	ld	a4,248(a5)
    80002b8c:	f8e43823          	sd	a4,-112(s0)
    80002b90:	1007b703          	ld	a4,256(a5)
    80002b94:	f8e43c23          	sd	a4,-104(s0)
    80002b98:	1087b783          	ld	a5,264(a5)
    80002b9c:	faf43023          	sd	a5,-96(s0)
    80002ba0:	058a                	slli	a1,a1,0x2
    80002ba2:	f9040613          	addi	a2,s0,-112
    80002ba6:	95da                	add	a1,a1,s6
    80002ba8:	5c88                	lw	a0,56(s1)
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	f68080e7          	jalr	-152(ra) # 80001b12 <insert_to_list>
    80002bb2:	b7a5                	j	80002b1a <wakeup+0x12c>
  }
}
    80002bb4:	70a6                	ld	ra,104(sp)
    80002bb6:	7406                	ld	s0,96(sp)
    80002bb8:	64e6                	ld	s1,88(sp)
    80002bba:	6946                	ld	s2,80(sp)
    80002bbc:	69a6                	ld	s3,72(sp)
    80002bbe:	6a06                	ld	s4,64(sp)
    80002bc0:	7ae2                	ld	s5,56(sp)
    80002bc2:	7b42                	ld	s6,48(sp)
    80002bc4:	7ba2                	ld	s7,40(sp)
    80002bc6:	7c02                	ld	s8,32(sp)
    80002bc8:	6165                	addi	sp,sp,112
    80002bca:	8082                	ret

0000000080002bcc <reparent>:
{
    80002bcc:	7179                	addi	sp,sp,-48
    80002bce:	f406                	sd	ra,40(sp)
    80002bd0:	f022                	sd	s0,32(sp)
    80002bd2:	ec26                	sd	s1,24(sp)
    80002bd4:	e84a                	sd	s2,16(sp)
    80002bd6:	e44e                	sd	s3,8(sp)
    80002bd8:	e052                	sd	s4,0(sp)
    80002bda:	1800                	addi	s0,sp,48
    80002bdc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bde:	00007497          	auipc	s1,0x7
    80002be2:	6c248493          	addi	s1,s1,1730 # 8000a2a0 <proc>
      pp->parent = initproc;
    80002be6:	00006a17          	auipc	s4,0x6
    80002bea:	44aa0a13          	addi	s4,s4,1098 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bee:	0000e997          	auipc	s3,0xe
    80002bf2:	8b298993          	addi	s3,s3,-1870 # 800104a0 <tickslock>
    80002bf6:	a029                	j	80002c00 <reparent+0x34>
    80002bf8:	18848493          	addi	s1,s1,392
    80002bfc:	01348d63          	beq	s1,s3,80002c16 <reparent+0x4a>
    if(pp->parent == p){
    80002c00:	6cbc                	ld	a5,88(s1)
    80002c02:	ff279be3          	bne	a5,s2,80002bf8 <reparent+0x2c>
      pp->parent = initproc;
    80002c06:	000a3503          	ld	a0,0(s4)
    80002c0a:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	de2080e7          	jalr	-542(ra) # 800029ee <wakeup>
    80002c14:	b7d5                	j	80002bf8 <reparent+0x2c>
}
    80002c16:	70a2                	ld	ra,40(sp)
    80002c18:	7402                	ld	s0,32(sp)
    80002c1a:	64e2                	ld	s1,24(sp)
    80002c1c:	6942                	ld	s2,16(sp)
    80002c1e:	69a2                	ld	s3,8(sp)
    80002c20:	6a02                	ld	s4,0(sp)
    80002c22:	6145                	addi	sp,sp,48
    80002c24:	8082                	ret

0000000080002c26 <exit>:
{
    80002c26:	715d                	addi	sp,sp,-80
    80002c28:	e486                	sd	ra,72(sp)
    80002c2a:	e0a2                	sd	s0,64(sp)
    80002c2c:	fc26                	sd	s1,56(sp)
    80002c2e:	f84a                	sd	s2,48(sp)
    80002c30:	f44e                	sd	s3,40(sp)
    80002c32:	f052                	sd	s4,32(sp)
    80002c34:	0880                	addi	s0,sp,80
    80002c36:	8a2a                	mv	s4,a0
  printf("entered exit\n");
    80002c38:	00006517          	auipc	a0,0x6
    80002c3c:	86850513          	addi	a0,a0,-1944 # 800084a0 <digits+0x460>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	948080e7          	jalr	-1720(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	1fa080e7          	jalr	506(ra) # 80001e42 <myproc>
    80002c50:	89aa                	mv	s3,a0
  if(p == initproc)
    80002c52:	00006797          	auipc	a5,0x6
    80002c56:	3de7b783          	ld	a5,990(a5) # 80009030 <initproc>
    80002c5a:	0f050493          	addi	s1,a0,240
    80002c5e:	17050913          	addi	s2,a0,368
    80002c62:	02a79363          	bne	a5,a0,80002c88 <exit+0x62>
    panic("init exiting");
    80002c66:	00006517          	auipc	a0,0x6
    80002c6a:	84a50513          	addi	a0,a0,-1974 # 800084b0 <digits+0x470>
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	8d0080e7          	jalr	-1840(ra) # 8000053e <panic>
      fileclose(f);
    80002c76:	00002097          	auipc	ra,0x2
    80002c7a:	204080e7          	jalr	516(ra) # 80004e7a <fileclose>
      p->ofile[fd] = 0;
    80002c7e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002c82:	04a1                	addi	s1,s1,8
    80002c84:	01248563          	beq	s1,s2,80002c8e <exit+0x68>
    if(p->ofile[fd]){
    80002c88:	6088                	ld	a0,0(s1)
    80002c8a:	f575                	bnez	a0,80002c76 <exit+0x50>
    80002c8c:	bfdd                	j	80002c82 <exit+0x5c>
  begin_op();
    80002c8e:	00002097          	auipc	ra,0x2
    80002c92:	d20080e7          	jalr	-736(ra) # 800049ae <begin_op>
  iput(p->cwd);
    80002c96:	1709b503          	ld	a0,368(s3)
    80002c9a:	00001097          	auipc	ra,0x1
    80002c9e:	4fc080e7          	jalr	1276(ra) # 80004196 <iput>
  end_op();
    80002ca2:	00002097          	auipc	ra,0x2
    80002ca6:	d8c080e7          	jalr	-628(ra) # 80004a2e <end_op>
  p->cwd = 0;
    80002caa:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002cae:	00007497          	auipc	s1,0x7
    80002cb2:	4e248493          	addi	s1,s1,1250 # 8000a190 <pid_lock>
    80002cb6:	00007917          	auipc	s2,0x7
    80002cba:	4f290913          	addi	s2,s2,1266 # 8000a1a8 <wait_lock>
    80002cbe:	854a                	mv	a0,s2
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	f24080e7          	jalr	-220(ra) # 80000be4 <acquire>
  reparent(p);
    80002cc8:	854e                	mv	a0,s3
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	f02080e7          	jalr	-254(ra) # 80002bcc <reparent>
  wakeup(p->parent);
    80002cd2:	0589b503          	ld	a0,88(s3)
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	d18080e7          	jalr	-744(ra) # 800029ee <wakeup>
  acquire(&p->lock);
    80002cde:	854e                	mv	a0,s3
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	f04080e7          	jalr	-252(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002ce8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002cec:	4795                	li	a5,5
    80002cee:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index,&zombie,zombie_head);
    80002cf2:	64bc                	ld	a5,72(s1)
    80002cf4:	faf43823          	sd	a5,-80(s0)
    80002cf8:	68bc                	ld	a5,80(s1)
    80002cfa:	faf43c23          	sd	a5,-72(s0)
    80002cfe:	6cbc                	ld	a5,88(s1)
    80002d00:	fcf43023          	sd	a5,-64(s0)
    80002d04:	fb040613          	addi	a2,s0,-80
    80002d08:	00006597          	auipc	a1,0x6
    80002d0c:	d6058593          	addi	a1,a1,-672 # 80008a68 <zombie>
    80002d10:	0389a503          	lw	a0,56(s3)
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	dfe080e7          	jalr	-514(ra) # 80001b12 <insert_to_list>
  release(&wait_lock);
    80002d1c:	854a                	mv	a0,s2
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	f8c080e7          	jalr	-116(ra) # 80000caa <release>
  sched();
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	950080e7          	jalr	-1712(ra) # 80002676 <sched>
  panic("zombie exit");
    80002d2e:	00005517          	auipc	a0,0x5
    80002d32:	79250513          	addi	a0,a0,1938 # 800084c0 <digits+0x480>
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	808080e7          	jalr	-2040(ra) # 8000053e <panic>

0000000080002d3e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002d3e:	7179                	addi	sp,sp,-48
    80002d40:	f406                	sd	ra,40(sp)
    80002d42:	f022                	sd	s0,32(sp)
    80002d44:	ec26                	sd	s1,24(sp)
    80002d46:	e84a                	sd	s2,16(sp)
    80002d48:	e44e                	sd	s3,8(sp)
    80002d4a:	1800                	addi	s0,sp,48
    80002d4c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002d4e:	00007497          	auipc	s1,0x7
    80002d52:	55248493          	addi	s1,s1,1362 # 8000a2a0 <proc>
    80002d56:	0000d997          	auipc	s3,0xd
    80002d5a:	74a98993          	addi	s3,s3,1866 # 800104a0 <tickslock>
    acquire(&p->lock);
    80002d5e:	8526                	mv	a0,s1
    80002d60:	ffffe097          	auipc	ra,0xffffe
    80002d64:	e84080e7          	jalr	-380(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002d68:	589c                	lw	a5,48(s1)
    80002d6a:	01278d63          	beq	a5,s2,80002d84 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002d6e:	8526                	mv	a0,s1
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	f3a080e7          	jalr	-198(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d78:	18848493          	addi	s1,s1,392
    80002d7c:	ff3491e3          	bne	s1,s3,80002d5e <kill+0x20>
  }
  return -1;
    80002d80:	557d                	li	a0,-1
    80002d82:	a829                	j	80002d9c <kill+0x5e>
      p->killed = 1;
    80002d84:	4785                	li	a5,1
    80002d86:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002d88:	4c98                	lw	a4,24(s1)
    80002d8a:	4789                	li	a5,2
    80002d8c:	00f70f63          	beq	a4,a5,80002daa <kill+0x6c>
      release(&p->lock);
    80002d90:	8526                	mv	a0,s1
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	f18080e7          	jalr	-232(ra) # 80000caa <release>
      return 0;
    80002d9a:	4501                	li	a0,0
}
    80002d9c:	70a2                	ld	ra,40(sp)
    80002d9e:	7402                	ld	s0,32(sp)
    80002da0:	64e2                	ld	s1,24(sp)
    80002da2:	6942                	ld	s2,16(sp)
    80002da4:	69a2                	ld	s3,8(sp)
    80002da6:	6145                	addi	sp,sp,48
    80002da8:	8082                	ret
        p->state = RUNNABLE;
    80002daa:	478d                	li	a5,3
    80002dac:	cc9c                	sw	a5,24(s1)
    80002dae:	b7cd                	j	80002d90 <kill+0x52>

0000000080002db0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002db0:	7179                	addi	sp,sp,-48
    80002db2:	f406                	sd	ra,40(sp)
    80002db4:	f022                	sd	s0,32(sp)
    80002db6:	ec26                	sd	s1,24(sp)
    80002db8:	e84a                	sd	s2,16(sp)
    80002dba:	e44e                	sd	s3,8(sp)
    80002dbc:	e052                	sd	s4,0(sp)
    80002dbe:	1800                	addi	s0,sp,48
    80002dc0:	84aa                	mv	s1,a0
    80002dc2:	892e                	mv	s2,a1
    80002dc4:	89b2                	mv	s3,a2
    80002dc6:	8a36                	mv	s4,a3
  //printf("entered either_copyout\n");
  struct proc *p = myproc();
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	07a080e7          	jalr	122(ra) # 80001e42 <myproc>
  if(user_dst){
    80002dd0:	c08d                	beqz	s1,80002df2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002dd2:	86d2                	mv	a3,s4
    80002dd4:	864e                	mv	a2,s3
    80002dd6:	85ca                	mv	a1,s2
    80002dd8:	7928                	ld	a0,112(a0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	8bc080e7          	jalr	-1860(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002de2:	70a2                	ld	ra,40(sp)
    80002de4:	7402                	ld	s0,32(sp)
    80002de6:	64e2                	ld	s1,24(sp)
    80002de8:	6942                	ld	s2,16(sp)
    80002dea:	69a2                	ld	s3,8(sp)
    80002dec:	6a02                	ld	s4,0(sp)
    80002dee:	6145                	addi	sp,sp,48
    80002df0:	8082                	ret
    memmove((char *)dst, src, len);
    80002df2:	000a061b          	sext.w	a2,s4
    80002df6:	85ce                	mv	a1,s3
    80002df8:	854a                	mv	a0,s2
    80002dfa:	ffffe097          	auipc	ra,0xffffe
    80002dfe:	f6a080e7          	jalr	-150(ra) # 80000d64 <memmove>
    return 0;
    80002e02:	8526                	mv	a0,s1
    80002e04:	bff9                	j	80002de2 <either_copyout+0x32>

0000000080002e06 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002e06:	7179                	addi	sp,sp,-48
    80002e08:	f406                	sd	ra,40(sp)
    80002e0a:	f022                	sd	s0,32(sp)
    80002e0c:	ec26                	sd	s1,24(sp)
    80002e0e:	e84a                	sd	s2,16(sp)
    80002e10:	e44e                	sd	s3,8(sp)
    80002e12:	e052                	sd	s4,0(sp)
    80002e14:	1800                	addi	s0,sp,48
    80002e16:	892a                	mv	s2,a0
    80002e18:	84ae                	mv	s1,a1
    80002e1a:	89b2                	mv	s3,a2
    80002e1c:	8a36                	mv	s4,a3
  //printf("entered either_copyin\n");
  struct proc *p = myproc();
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	024080e7          	jalr	36(ra) # 80001e42 <myproc>
  if(user_src){
    80002e26:	c08d                	beqz	s1,80002e48 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002e28:	86d2                	mv	a3,s4
    80002e2a:	864e                	mv	a2,s3
    80002e2c:	85ca                	mv	a1,s2
    80002e2e:	7928                	ld	a0,112(a0)
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	8f2080e7          	jalr	-1806(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002e38:	70a2                	ld	ra,40(sp)
    80002e3a:	7402                	ld	s0,32(sp)
    80002e3c:	64e2                	ld	s1,24(sp)
    80002e3e:	6942                	ld	s2,16(sp)
    80002e40:	69a2                	ld	s3,8(sp)
    80002e42:	6a02                	ld	s4,0(sp)
    80002e44:	6145                	addi	sp,sp,48
    80002e46:	8082                	ret
    memmove(dst, (char*)src, len);
    80002e48:	000a061b          	sext.w	a2,s4
    80002e4c:	85ce                	mv	a1,s3
    80002e4e:	854a                	mv	a0,s2
    80002e50:	ffffe097          	auipc	ra,0xffffe
    80002e54:	f14080e7          	jalr	-236(ra) # 80000d64 <memmove>
    return 0;
    80002e58:	8526                	mv	a0,s1
    80002e5a:	bff9                	j	80002e38 <either_copyin+0x32>

0000000080002e5c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002e5c:	715d                	addi	sp,sp,-80
    80002e5e:	e486                	sd	ra,72(sp)
    80002e60:	e0a2                	sd	s0,64(sp)
    80002e62:	fc26                	sd	s1,56(sp)
    80002e64:	f84a                	sd	s2,48(sp)
    80002e66:	f44e                	sd	s3,40(sp)
    80002e68:	f052                	sd	s4,32(sp)
    80002e6a:	ec56                	sd	s5,24(sp)
    80002e6c:	e85a                	sd	s6,16(sp)
    80002e6e:	e45e                	sd	s7,8(sp)
    80002e70:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	47650513          	addi	a0,a0,1142 # 800082e8 <digits+0x2a8>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	70e080e7          	jalr	1806(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002e82:	00007497          	auipc	s1,0x7
    80002e86:	59648493          	addi	s1,s1,1430 # 8000a418 <proc+0x178>
    80002e8a:	0000d917          	auipc	s2,0xd
    80002e8e:	78e90913          	addi	s2,s2,1934 # 80010618 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e92:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002e94:	00005997          	auipc	s3,0x5
    80002e98:	63c98993          	addi	s3,s3,1596 # 800084d0 <digits+0x490>
    printf("%d %s %s", p->pid, state, p->name);
    80002e9c:	00005a97          	auipc	s5,0x5
    80002ea0:	63ca8a93          	addi	s5,s5,1596 # 800084d8 <digits+0x498>
    printf("\n");
    80002ea4:	00005a17          	auipc	s4,0x5
    80002ea8:	444a0a13          	addi	s4,s4,1092 # 800082e8 <digits+0x2a8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002eac:	00005b97          	auipc	s7,0x5
    80002eb0:	664b8b93          	addi	s7,s7,1636 # 80008510 <states.1760>
    80002eb4:	a00d                	j	80002ed6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002eb6:	eb86a583          	lw	a1,-328(a3)
    80002eba:	8556                	mv	a0,s5
    80002ebc:	ffffd097          	auipc	ra,0xffffd
    80002ec0:	6cc080e7          	jalr	1740(ra) # 80000588 <printf>
    printf("\n");
    80002ec4:	8552                	mv	a0,s4
    80002ec6:	ffffd097          	auipc	ra,0xffffd
    80002eca:	6c2080e7          	jalr	1730(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ece:	18848493          	addi	s1,s1,392
    80002ed2:	03248163          	beq	s1,s2,80002ef4 <procdump+0x98>
    if(p->state == UNUSED)
    80002ed6:	86a6                	mv	a3,s1
    80002ed8:	ea04a783          	lw	a5,-352(s1)
    80002edc:	dbed                	beqz	a5,80002ece <procdump+0x72>
      state = "???";
    80002ede:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ee0:	fcfb6be3          	bltu	s6,a5,80002eb6 <procdump+0x5a>
    80002ee4:	1782                	slli	a5,a5,0x20
    80002ee6:	9381                	srli	a5,a5,0x20
    80002ee8:	078e                	slli	a5,a5,0x3
    80002eea:	97de                	add	a5,a5,s7
    80002eec:	6390                	ld	a2,0(a5)
    80002eee:	f661                	bnez	a2,80002eb6 <procdump+0x5a>
      state = "???";
    80002ef0:	864e                	mv	a2,s3
    80002ef2:	b7d1                	j	80002eb6 <procdump+0x5a>
  }
}
    80002ef4:	60a6                	ld	ra,72(sp)
    80002ef6:	6406                	ld	s0,64(sp)
    80002ef8:	74e2                	ld	s1,56(sp)
    80002efa:	7942                	ld	s2,48(sp)
    80002efc:	79a2                	ld	s3,40(sp)
    80002efe:	7a02                	ld	s4,32(sp)
    80002f00:	6ae2                	ld	s5,24(sp)
    80002f02:	6b42                	ld	s6,16(sp)
    80002f04:	6ba2                	ld	s7,8(sp)
    80002f06:	6161                	addi	sp,sp,80
    80002f08:	8082                	ret

0000000080002f0a <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002f0a:	1101                	addi	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	e426                	sd	s1,8(sp)
    80002f12:	1000                	addi	s0,sp,32
    80002f14:	84aa                	mv	s1,a0
  struct proc *p= myproc();  
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	f2c080e7          	jalr	-212(ra) # 80001e42 <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002f1e:	8626                	mv	a2,s1
    80002f20:	594c                	lw	a1,52(a0)
    80002f22:	03450513          	addi	a0,a0,52
    80002f26:	00004097          	auipc	ra,0x4
    80002f2a:	c40080e7          	jalr	-960(ra) # 80006b66 <cas>
    80002f2e:	e519                	bnez	a0,80002f3c <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002f30:	4501                	li	a0,0
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret
    yield();
    80002f3c:	00000097          	auipc	ra,0x0
    80002f40:	810080e7          	jalr	-2032(ra) # 8000274c <yield>
    return cpu_num;
    80002f44:	8526                	mv	a0,s1
    80002f46:	b7f5                	j	80002f32 <set_cpu+0x28>

0000000080002f48 <get_cpu>:

int get_cpu(){ //added as orderd
    80002f48:	1101                	addi	sp,sp,-32
    80002f4a:	ec06                	sd	ra,24(sp)
    80002f4c:	e822                	sd	s0,16(sp)
    80002f4e:	1000                	addi	s0,sp,32
  struct proc *p=myproc();
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	ef2080e7          	jalr	-270(ra) # 80001e42 <myproc>
  int ans=0;
    80002f58:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002f5c:	5950                	lw	a2,52(a0)
    80002f5e:	4581                	li	a1,0
    80002f60:	fec40513          	addi	a0,s0,-20
    80002f64:	00004097          	auipc	ra,0x4
    80002f68:	c02080e7          	jalr	-1022(ra) # 80006b66 <cas>
    return ans;
}
    80002f6c:	fec42503          	lw	a0,-20(s0)
    80002f70:	60e2                	ld	ra,24(sp)
    80002f72:	6442                	ld	s0,16(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret

0000000080002f78 <swtch>:
    80002f78:	00153023          	sd	ra,0(a0)
    80002f7c:	00253423          	sd	sp,8(a0)
    80002f80:	e900                	sd	s0,16(a0)
    80002f82:	ed04                	sd	s1,24(a0)
    80002f84:	03253023          	sd	s2,32(a0)
    80002f88:	03353423          	sd	s3,40(a0)
    80002f8c:	03453823          	sd	s4,48(a0)
    80002f90:	03553c23          	sd	s5,56(a0)
    80002f94:	05653023          	sd	s6,64(a0)
    80002f98:	05753423          	sd	s7,72(a0)
    80002f9c:	05853823          	sd	s8,80(a0)
    80002fa0:	05953c23          	sd	s9,88(a0)
    80002fa4:	07a53023          	sd	s10,96(a0)
    80002fa8:	07b53423          	sd	s11,104(a0)
    80002fac:	0005b083          	ld	ra,0(a1)
    80002fb0:	0085b103          	ld	sp,8(a1)
    80002fb4:	6980                	ld	s0,16(a1)
    80002fb6:	6d84                	ld	s1,24(a1)
    80002fb8:	0205b903          	ld	s2,32(a1)
    80002fbc:	0285b983          	ld	s3,40(a1)
    80002fc0:	0305ba03          	ld	s4,48(a1)
    80002fc4:	0385ba83          	ld	s5,56(a1)
    80002fc8:	0405bb03          	ld	s6,64(a1)
    80002fcc:	0485bb83          	ld	s7,72(a1)
    80002fd0:	0505bc03          	ld	s8,80(a1)
    80002fd4:	0585bc83          	ld	s9,88(a1)
    80002fd8:	0605bd03          	ld	s10,96(a1)
    80002fdc:	0685bd83          	ld	s11,104(a1)
    80002fe0:	8082                	ret

0000000080002fe2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002fe2:	1141                	addi	sp,sp,-16
    80002fe4:	e406                	sd	ra,8(sp)
    80002fe6:	e022                	sd	s0,0(sp)
    80002fe8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002fea:	00005597          	auipc	a1,0x5
    80002fee:	55658593          	addi	a1,a1,1366 # 80008540 <states.1760+0x30>
    80002ff2:	0000d517          	auipc	a0,0xd
    80002ff6:	4ae50513          	addi	a0,a0,1198 # 800104a0 <tickslock>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	b5a080e7          	jalr	-1190(ra) # 80000b54 <initlock>
}
    80003002:	60a2                	ld	ra,8(sp)
    80003004:	6402                	ld	s0,0(sp)
    80003006:	0141                	addi	sp,sp,16
    80003008:	8082                	ret

000000008000300a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000300a:	1141                	addi	sp,sp,-16
    8000300c:	e422                	sd	s0,8(sp)
    8000300e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003010:	00003797          	auipc	a5,0x3
    80003014:	48078793          	addi	a5,a5,1152 # 80006490 <kernelvec>
    80003018:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000301c:	6422                	ld	s0,8(sp)
    8000301e:	0141                	addi	sp,sp,16
    80003020:	8082                	ret

0000000080003022 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003022:	1141                	addi	sp,sp,-16
    80003024:	e406                	sd	ra,8(sp)
    80003026:	e022                	sd	s0,0(sp)
    80003028:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	e18080e7          	jalr	-488(ra) # 80001e42 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003032:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003036:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003038:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000303c:	00004617          	auipc	a2,0x4
    80003040:	fc460613          	addi	a2,a2,-60 # 80007000 <_trampoline>
    80003044:	00004697          	auipc	a3,0x4
    80003048:	fbc68693          	addi	a3,a3,-68 # 80007000 <_trampoline>
    8000304c:	8e91                	sub	a3,a3,a2
    8000304e:	040007b7          	lui	a5,0x4000
    80003052:	17fd                	addi	a5,a5,-1
    80003054:	07b2                	slli	a5,a5,0xc
    80003056:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003058:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000305c:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000305e:	180026f3          	csrr	a3,satp
    80003062:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003064:	7d38                	ld	a4,120(a0)
    80003066:	7134                	ld	a3,96(a0)
    80003068:	6585                	lui	a1,0x1
    8000306a:	96ae                	add	a3,a3,a1
    8000306c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000306e:	7d38                	ld	a4,120(a0)
    80003070:	00000697          	auipc	a3,0x0
    80003074:	13868693          	addi	a3,a3,312 # 800031a8 <usertrap>
    80003078:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000307a:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000307c:	8692                	mv	a3,tp
    8000307e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003080:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003084:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003088:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000308c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003090:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003092:	6f18                	ld	a4,24(a4)
    80003094:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003098:	792c                	ld	a1,112(a0)
    8000309a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000309c:	00004717          	auipc	a4,0x4
    800030a0:	ff470713          	addi	a4,a4,-12 # 80007090 <userret>
    800030a4:	8f11                	sub	a4,a4,a2
    800030a6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800030a8:	577d                	li	a4,-1
    800030aa:	177e                	slli	a4,a4,0x3f
    800030ac:	8dd9                	or	a1,a1,a4
    800030ae:	02000537          	lui	a0,0x2000
    800030b2:	157d                	addi	a0,a0,-1
    800030b4:	0536                	slli	a0,a0,0xd
    800030b6:	9782                	jalr	a5
}
    800030b8:	60a2                	ld	ra,8(sp)
    800030ba:	6402                	ld	s0,0(sp)
    800030bc:	0141                	addi	sp,sp,16
    800030be:	8082                	ret

00000000800030c0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800030c0:	1101                	addi	sp,sp,-32
    800030c2:	ec06                	sd	ra,24(sp)
    800030c4:	e822                	sd	s0,16(sp)
    800030c6:	e426                	sd	s1,8(sp)
    800030c8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800030ca:	0000d497          	auipc	s1,0xd
    800030ce:	3d648493          	addi	s1,s1,982 # 800104a0 <tickslock>
    800030d2:	8526                	mv	a0,s1
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	b10080e7          	jalr	-1264(ra) # 80000be4 <acquire>
  ticks++;
    800030dc:	00006517          	auipc	a0,0x6
    800030e0:	f5c50513          	addi	a0,a0,-164 # 80009038 <ticks>
    800030e4:	411c                	lw	a5,0(a0)
    800030e6:	2785                	addiw	a5,a5,1
    800030e8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	904080e7          	jalr	-1788(ra) # 800029ee <wakeup>
  release(&tickslock);
    800030f2:	8526                	mv	a0,s1
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	bb6080e7          	jalr	-1098(ra) # 80000caa <release>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003110:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003114:	00074d63          	bltz	a4,8000312e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003118:	57fd                	li	a5,-1
    8000311a:	17fe                	slli	a5,a5,0x3f
    8000311c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000311e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003120:	06f70363          	beq	a4,a5,80003186 <devintr+0x80>
  }
}
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	64a2                	ld	s1,8(sp)
    8000312a:	6105                	addi	sp,sp,32
    8000312c:	8082                	ret
     (scause & 0xff) == 9){
    8000312e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003132:	46a5                	li	a3,9
    80003134:	fed792e3          	bne	a5,a3,80003118 <devintr+0x12>
    int irq = plic_claim();
    80003138:	00003097          	auipc	ra,0x3
    8000313c:	460080e7          	jalr	1120(ra) # 80006598 <plic_claim>
    80003140:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003142:	47a9                	li	a5,10
    80003144:	02f50763          	beq	a0,a5,80003172 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003148:	4785                	li	a5,1
    8000314a:	02f50963          	beq	a0,a5,8000317c <devintr+0x76>
    return 1;
    8000314e:	4505                	li	a0,1
    } else if(irq){
    80003150:	d8f1                	beqz	s1,80003124 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003152:	85a6                	mv	a1,s1
    80003154:	00005517          	auipc	a0,0x5
    80003158:	3f450513          	addi	a0,a0,1012 # 80008548 <states.1760+0x38>
    8000315c:	ffffd097          	auipc	ra,0xffffd
    80003160:	42c080e7          	jalr	1068(ra) # 80000588 <printf>
      plic_complete(irq);
    80003164:	8526                	mv	a0,s1
    80003166:	00003097          	auipc	ra,0x3
    8000316a:	456080e7          	jalr	1110(ra) # 800065bc <plic_complete>
    return 1;
    8000316e:	4505                	li	a0,1
    80003170:	bf55                	j	80003124 <devintr+0x1e>
      uartintr();
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	836080e7          	jalr	-1994(ra) # 800009a8 <uartintr>
    8000317a:	b7ed                	j	80003164 <devintr+0x5e>
      virtio_disk_intr();
    8000317c:	00004097          	auipc	ra,0x4
    80003180:	920080e7          	jalr	-1760(ra) # 80006a9c <virtio_disk_intr>
    80003184:	b7c5                	j	80003164 <devintr+0x5e>
    if(cpuid() == 0){
    80003186:	fffff097          	auipc	ra,0xfffff
    8000318a:	c90080e7          	jalr	-880(ra) # 80001e16 <cpuid>
    8000318e:	c901                	beqz	a0,8000319e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003190:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003194:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003196:	14479073          	csrw	sip,a5
    return 2;
    8000319a:	4509                	li	a0,2
    8000319c:	b761                	j	80003124 <devintr+0x1e>
      clockintr();
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	f22080e7          	jalr	-222(ra) # 800030c0 <clockintr>
    800031a6:	b7ed                	j	80003190 <devintr+0x8a>

00000000800031a8 <usertrap>:
{
    800031a8:	1101                	addi	sp,sp,-32
    800031aa:	ec06                	sd	ra,24(sp)
    800031ac:	e822                	sd	s0,16(sp)
    800031ae:	e426                	sd	s1,8(sp)
    800031b0:	e04a                	sd	s2,0(sp)
    800031b2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031b4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800031b8:	1007f793          	andi	a5,a5,256
    800031bc:	e3ad                	bnez	a5,8000321e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800031be:	00003797          	auipc	a5,0x3
    800031c2:	2d278793          	addi	a5,a5,722 # 80006490 <kernelvec>
    800031c6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800031ca:	fffff097          	auipc	ra,0xfffff
    800031ce:	c78080e7          	jalr	-904(ra) # 80001e42 <myproc>
    800031d2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800031d4:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031d6:	14102773          	csrr	a4,sepc
    800031da:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031dc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800031e0:	47a1                	li	a5,8
    800031e2:	04f71c63          	bne	a4,a5,8000323a <usertrap+0x92>
    if(p->killed)
    800031e6:	551c                	lw	a5,40(a0)
    800031e8:	e3b9                	bnez	a5,8000322e <usertrap+0x86>
    p->trapframe->epc += 4;
    800031ea:	7cb8                	ld	a4,120(s1)
    800031ec:	6f1c                	ld	a5,24(a4)
    800031ee:	0791                	addi	a5,a5,4
    800031f0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800031f6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031fa:	10079073          	csrw	sstatus,a5
    syscall();
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	2e0080e7          	jalr	736(ra) # 800034de <syscall>
  if(p->killed)
    80003206:	549c                	lw	a5,40(s1)
    80003208:	ebc1                	bnez	a5,80003298 <usertrap+0xf0>
  usertrapret();
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	e18080e7          	jalr	-488(ra) # 80003022 <usertrapret>
}
    80003212:	60e2                	ld	ra,24(sp)
    80003214:	6442                	ld	s0,16(sp)
    80003216:	64a2                	ld	s1,8(sp)
    80003218:	6902                	ld	s2,0(sp)
    8000321a:	6105                	addi	sp,sp,32
    8000321c:	8082                	ret
    panic("usertrap: not from user mode");
    8000321e:	00005517          	auipc	a0,0x5
    80003222:	34a50513          	addi	a0,a0,842 # 80008568 <states.1760+0x58>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	318080e7          	jalr	792(ra) # 8000053e <panic>
      exit(-1);
    8000322e:	557d                	li	a0,-1
    80003230:	00000097          	auipc	ra,0x0
    80003234:	9f6080e7          	jalr	-1546(ra) # 80002c26 <exit>
    80003238:	bf4d                	j	800031ea <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	ecc080e7          	jalr	-308(ra) # 80003106 <devintr>
    80003242:	892a                	mv	s2,a0
    80003244:	c501                	beqz	a0,8000324c <usertrap+0xa4>
  if(p->killed)
    80003246:	549c                	lw	a5,40(s1)
    80003248:	c3a1                	beqz	a5,80003288 <usertrap+0xe0>
    8000324a:	a815                	j	8000327e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000324c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003250:	5890                	lw	a2,48(s1)
    80003252:	00005517          	auipc	a0,0x5
    80003256:	33650513          	addi	a0,a0,822 # 80008588 <states.1760+0x78>
    8000325a:	ffffd097          	auipc	ra,0xffffd
    8000325e:	32e080e7          	jalr	814(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003262:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003266:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000326a:	00005517          	auipc	a0,0x5
    8000326e:	34e50513          	addi	a0,a0,846 # 800085b8 <states.1760+0xa8>
    80003272:	ffffd097          	auipc	ra,0xffffd
    80003276:	316080e7          	jalr	790(ra) # 80000588 <printf>
    p->killed = 1;
    8000327a:	4785                	li	a5,1
    8000327c:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000327e:	557d                	li	a0,-1
    80003280:	00000097          	auipc	ra,0x0
    80003284:	9a6080e7          	jalr	-1626(ra) # 80002c26 <exit>
  if(which_dev == 2)
    80003288:	4789                	li	a5,2
    8000328a:	f8f910e3          	bne	s2,a5,8000320a <usertrap+0x62>
    yield();
    8000328e:	fffff097          	auipc	ra,0xfffff
    80003292:	4be080e7          	jalr	1214(ra) # 8000274c <yield>
    80003296:	bf95                	j	8000320a <usertrap+0x62>
  int which_dev = 0;
    80003298:	4901                	li	s2,0
    8000329a:	b7d5                	j	8000327e <usertrap+0xd6>

000000008000329c <kerneltrap>:
{
    8000329c:	7179                	addi	sp,sp,-48
    8000329e:	f406                	sd	ra,40(sp)
    800032a0:	f022                	sd	s0,32(sp)
    800032a2:	ec26                	sd	s1,24(sp)
    800032a4:	e84a                	sd	s2,16(sp)
    800032a6:	e44e                	sd	s3,8(sp)
    800032a8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032aa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032ae:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032b2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800032b6:	1004f793          	andi	a5,s1,256
    800032ba:	cb85                	beqz	a5,800032ea <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032bc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800032c0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800032c2:	ef85                	bnez	a5,800032fa <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	e42080e7          	jalr	-446(ra) # 80003106 <devintr>
    800032cc:	cd1d                	beqz	a0,8000330a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032ce:	4789                	li	a5,2
    800032d0:	06f50a63          	beq	a0,a5,80003344 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032d4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032d8:	10049073          	csrw	sstatus,s1
}
    800032dc:	70a2                	ld	ra,40(sp)
    800032de:	7402                	ld	s0,32(sp)
    800032e0:	64e2                	ld	s1,24(sp)
    800032e2:	6942                	ld	s2,16(sp)
    800032e4:	69a2                	ld	s3,8(sp)
    800032e6:	6145                	addi	sp,sp,48
    800032e8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032ea:	00005517          	auipc	a0,0x5
    800032ee:	2ee50513          	addi	a0,a0,750 # 800085d8 <states.1760+0xc8>
    800032f2:	ffffd097          	auipc	ra,0xffffd
    800032f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800032fa:	00005517          	auipc	a0,0x5
    800032fe:	30650513          	addi	a0,a0,774 # 80008600 <states.1760+0xf0>
    80003302:	ffffd097          	auipc	ra,0xffffd
    80003306:	23c080e7          	jalr	572(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000330a:	85ce                	mv	a1,s3
    8000330c:	00005517          	auipc	a0,0x5
    80003310:	31450513          	addi	a0,a0,788 # 80008620 <states.1760+0x110>
    80003314:	ffffd097          	auipc	ra,0xffffd
    80003318:	274080e7          	jalr	628(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000331c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003320:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003324:	00005517          	auipc	a0,0x5
    80003328:	30c50513          	addi	a0,a0,780 # 80008630 <states.1760+0x120>
    8000332c:	ffffd097          	auipc	ra,0xffffd
    80003330:	25c080e7          	jalr	604(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003334:	00005517          	auipc	a0,0x5
    80003338:	31450513          	addi	a0,a0,788 # 80008648 <states.1760+0x138>
    8000333c:	ffffd097          	auipc	ra,0xffffd
    80003340:	202080e7          	jalr	514(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003344:	fffff097          	auipc	ra,0xfffff
    80003348:	afe080e7          	jalr	-1282(ra) # 80001e42 <myproc>
    8000334c:	d541                	beqz	a0,800032d4 <kerneltrap+0x38>
    8000334e:	fffff097          	auipc	ra,0xfffff
    80003352:	af4080e7          	jalr	-1292(ra) # 80001e42 <myproc>
    80003356:	4d18                	lw	a4,24(a0)
    80003358:	4791                	li	a5,4
    8000335a:	f6f71de3          	bne	a4,a5,800032d4 <kerneltrap+0x38>
    yield();
    8000335e:	fffff097          	auipc	ra,0xfffff
    80003362:	3ee080e7          	jalr	1006(ra) # 8000274c <yield>
    80003366:	b7bd                	j	800032d4 <kerneltrap+0x38>

0000000080003368 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003368:	1101                	addi	sp,sp,-32
    8000336a:	ec06                	sd	ra,24(sp)
    8000336c:	e822                	sd	s0,16(sp)
    8000336e:	e426                	sd	s1,8(sp)
    80003370:	1000                	addi	s0,sp,32
    80003372:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	ace080e7          	jalr	-1330(ra) # 80001e42 <myproc>
  switch (n) {
    8000337c:	4795                	li	a5,5
    8000337e:	0497e163          	bltu	a5,s1,800033c0 <argraw+0x58>
    80003382:	048a                	slli	s1,s1,0x2
    80003384:	00005717          	auipc	a4,0x5
    80003388:	2fc70713          	addi	a4,a4,764 # 80008680 <states.1760+0x170>
    8000338c:	94ba                	add	s1,s1,a4
    8000338e:	409c                	lw	a5,0(s1)
    80003390:	97ba                	add	a5,a5,a4
    80003392:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003394:	7d3c                	ld	a5,120(a0)
    80003396:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003398:	60e2                	ld	ra,24(sp)
    8000339a:	6442                	ld	s0,16(sp)
    8000339c:	64a2                	ld	s1,8(sp)
    8000339e:	6105                	addi	sp,sp,32
    800033a0:	8082                	ret
    return p->trapframe->a1;
    800033a2:	7d3c                	ld	a5,120(a0)
    800033a4:	7fa8                	ld	a0,120(a5)
    800033a6:	bfcd                	j	80003398 <argraw+0x30>
    return p->trapframe->a2;
    800033a8:	7d3c                	ld	a5,120(a0)
    800033aa:	63c8                	ld	a0,128(a5)
    800033ac:	b7f5                	j	80003398 <argraw+0x30>
    return p->trapframe->a3;
    800033ae:	7d3c                	ld	a5,120(a0)
    800033b0:	67c8                	ld	a0,136(a5)
    800033b2:	b7dd                	j	80003398 <argraw+0x30>
    return p->trapframe->a4;
    800033b4:	7d3c                	ld	a5,120(a0)
    800033b6:	6bc8                	ld	a0,144(a5)
    800033b8:	b7c5                	j	80003398 <argraw+0x30>
    return p->trapframe->a5;
    800033ba:	7d3c                	ld	a5,120(a0)
    800033bc:	6fc8                	ld	a0,152(a5)
    800033be:	bfe9                	j	80003398 <argraw+0x30>
  panic("argraw");
    800033c0:	00005517          	auipc	a0,0x5
    800033c4:	29850513          	addi	a0,a0,664 # 80008658 <states.1760+0x148>
    800033c8:	ffffd097          	auipc	ra,0xffffd
    800033cc:	176080e7          	jalr	374(ra) # 8000053e <panic>

00000000800033d0 <fetchaddr>:
{
    800033d0:	1101                	addi	sp,sp,-32
    800033d2:	ec06                	sd	ra,24(sp)
    800033d4:	e822                	sd	s0,16(sp)
    800033d6:	e426                	sd	s1,8(sp)
    800033d8:	e04a                	sd	s2,0(sp)
    800033da:	1000                	addi	s0,sp,32
    800033dc:	84aa                	mv	s1,a0
    800033de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033e0:	fffff097          	auipc	ra,0xfffff
    800033e4:	a62080e7          	jalr	-1438(ra) # 80001e42 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033e8:	753c                	ld	a5,104(a0)
    800033ea:	02f4f863          	bgeu	s1,a5,8000341a <fetchaddr+0x4a>
    800033ee:	00848713          	addi	a4,s1,8
    800033f2:	02e7e663          	bltu	a5,a4,8000341e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033f6:	46a1                	li	a3,8
    800033f8:	8626                	mv	a2,s1
    800033fa:	85ca                	mv	a1,s2
    800033fc:	7928                	ld	a0,112(a0)
    800033fe:	ffffe097          	auipc	ra,0xffffe
    80003402:	324080e7          	jalr	804(ra) # 80001722 <copyin>
    80003406:	00a03533          	snez	a0,a0
    8000340a:	40a00533          	neg	a0,a0
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6902                	ld	s2,0(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret
    return -1;
    8000341a:	557d                	li	a0,-1
    8000341c:	bfcd                	j	8000340e <fetchaddr+0x3e>
    8000341e:	557d                	li	a0,-1
    80003420:	b7fd                	j	8000340e <fetchaddr+0x3e>

0000000080003422 <fetchstr>:
{
    80003422:	7179                	addi	sp,sp,-48
    80003424:	f406                	sd	ra,40(sp)
    80003426:	f022                	sd	s0,32(sp)
    80003428:	ec26                	sd	s1,24(sp)
    8000342a:	e84a                	sd	s2,16(sp)
    8000342c:	e44e                	sd	s3,8(sp)
    8000342e:	1800                	addi	s0,sp,48
    80003430:	892a                	mv	s2,a0
    80003432:	84ae                	mv	s1,a1
    80003434:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003436:	fffff097          	auipc	ra,0xfffff
    8000343a:	a0c080e7          	jalr	-1524(ra) # 80001e42 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000343e:	86ce                	mv	a3,s3
    80003440:	864a                	mv	a2,s2
    80003442:	85a6                	mv	a1,s1
    80003444:	7928                	ld	a0,112(a0)
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	368080e7          	jalr	872(ra) # 800017ae <copyinstr>
  if(err < 0)
    8000344e:	00054763          	bltz	a0,8000345c <fetchstr+0x3a>
  return strlen(buf);
    80003452:	8526                	mv	a0,s1
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	a34080e7          	jalr	-1484(ra) # 80000e88 <strlen>
}
    8000345c:	70a2                	ld	ra,40(sp)
    8000345e:	7402                	ld	s0,32(sp)
    80003460:	64e2                	ld	s1,24(sp)
    80003462:	6942                	ld	s2,16(sp)
    80003464:	69a2                	ld	s3,8(sp)
    80003466:	6145                	addi	sp,sp,48
    80003468:	8082                	ret

000000008000346a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000346a:	1101                	addi	sp,sp,-32
    8000346c:	ec06                	sd	ra,24(sp)
    8000346e:	e822                	sd	s0,16(sp)
    80003470:	e426                	sd	s1,8(sp)
    80003472:	1000                	addi	s0,sp,32
    80003474:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	ef2080e7          	jalr	-270(ra) # 80003368 <argraw>
    8000347e:	c088                	sw	a0,0(s1)
  return 0;
}
    80003480:	4501                	li	a0,0
    80003482:	60e2                	ld	ra,24(sp)
    80003484:	6442                	ld	s0,16(sp)
    80003486:	64a2                	ld	s1,8(sp)
    80003488:	6105                	addi	sp,sp,32
    8000348a:	8082                	ret

000000008000348c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000348c:	1101                	addi	sp,sp,-32
    8000348e:	ec06                	sd	ra,24(sp)
    80003490:	e822                	sd	s0,16(sp)
    80003492:	e426                	sd	s1,8(sp)
    80003494:	1000                	addi	s0,sp,32
    80003496:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	ed0080e7          	jalr	-304(ra) # 80003368 <argraw>
    800034a0:	e088                	sd	a0,0(s1)
  return 0;
}
    800034a2:	4501                	li	a0,0
    800034a4:	60e2                	ld	ra,24(sp)
    800034a6:	6442                	ld	s0,16(sp)
    800034a8:	64a2                	ld	s1,8(sp)
    800034aa:	6105                	addi	sp,sp,32
    800034ac:	8082                	ret

00000000800034ae <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800034ae:	1101                	addi	sp,sp,-32
    800034b0:	ec06                	sd	ra,24(sp)
    800034b2:	e822                	sd	s0,16(sp)
    800034b4:	e426                	sd	s1,8(sp)
    800034b6:	e04a                	sd	s2,0(sp)
    800034b8:	1000                	addi	s0,sp,32
    800034ba:	84ae                	mv	s1,a1
    800034bc:	8932                	mv	s2,a2
  *ip = argraw(n);
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	eaa080e7          	jalr	-342(ra) # 80003368 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800034c6:	864a                	mv	a2,s2
    800034c8:	85a6                	mv	a1,s1
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	f58080e7          	jalr	-168(ra) # 80003422 <fetchstr>
}
    800034d2:	60e2                	ld	ra,24(sp)
    800034d4:	6442                	ld	s0,16(sp)
    800034d6:	64a2                	ld	s1,8(sp)
    800034d8:	6902                	ld	s2,0(sp)
    800034da:	6105                	addi	sp,sp,32
    800034dc:	8082                	ret

00000000800034de <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800034de:	1101                	addi	sp,sp,-32
    800034e0:	ec06                	sd	ra,24(sp)
    800034e2:	e822                	sd	s0,16(sp)
    800034e4:	e426                	sd	s1,8(sp)
    800034e6:	e04a                	sd	s2,0(sp)
    800034e8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034ea:	fffff097          	auipc	ra,0xfffff
    800034ee:	958080e7          	jalr	-1704(ra) # 80001e42 <myproc>
    800034f2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034f4:	07853903          	ld	s2,120(a0)
    800034f8:	0a893783          	ld	a5,168(s2)
    800034fc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003500:	37fd                	addiw	a5,a5,-1
    80003502:	4751                	li	a4,20
    80003504:	00f76f63          	bltu	a4,a5,80003522 <syscall+0x44>
    80003508:	00369713          	slli	a4,a3,0x3
    8000350c:	00005797          	auipc	a5,0x5
    80003510:	18c78793          	addi	a5,a5,396 # 80008698 <syscalls>
    80003514:	97ba                	add	a5,a5,a4
    80003516:	639c                	ld	a5,0(a5)
    80003518:	c789                	beqz	a5,80003522 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000351a:	9782                	jalr	a5
    8000351c:	06a93823          	sd	a0,112(s2)
    80003520:	a839                	j	8000353e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003522:	17848613          	addi	a2,s1,376
    80003526:	588c                	lw	a1,48(s1)
    80003528:	00005517          	auipc	a0,0x5
    8000352c:	13850513          	addi	a0,a0,312 # 80008660 <states.1760+0x150>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	058080e7          	jalr	88(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003538:	7cbc                	ld	a5,120(s1)
    8000353a:	577d                	li	a4,-1
    8000353c:	fbb8                	sd	a4,112(a5)
  }
}
    8000353e:	60e2                	ld	ra,24(sp)
    80003540:	6442                	ld	s0,16(sp)
    80003542:	64a2                	ld	s1,8(sp)
    80003544:	6902                	ld	s2,0(sp)
    80003546:	6105                	addi	sp,sp,32
    80003548:	8082                	ret

000000008000354a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000354a:	1101                	addi	sp,sp,-32
    8000354c:	ec06                	sd	ra,24(sp)
    8000354e:	e822                	sd	s0,16(sp)
    80003550:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003552:	fec40593          	addi	a1,s0,-20
    80003556:	4501                	li	a0,0
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	f12080e7          	jalr	-238(ra) # 8000346a <argint>
    return -1;
    80003560:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003562:	00054963          	bltz	a0,80003574 <sys_exit+0x2a>
  exit(n);
    80003566:	fec42503          	lw	a0,-20(s0)
    8000356a:	fffff097          	auipc	ra,0xfffff
    8000356e:	6bc080e7          	jalr	1724(ra) # 80002c26 <exit>
  return 0;  // not reached
    80003572:	4781                	li	a5,0
}
    80003574:	853e                	mv	a0,a5
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	6105                	addi	sp,sp,32
    8000357c:	8082                	ret

000000008000357e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000357e:	1141                	addi	sp,sp,-16
    80003580:	e406                	sd	ra,8(sp)
    80003582:	e022                	sd	s0,0(sp)
    80003584:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003586:	fffff097          	auipc	ra,0xfffff
    8000358a:	8bc080e7          	jalr	-1860(ra) # 80001e42 <myproc>
}
    8000358e:	5908                	lw	a0,48(a0)
    80003590:	60a2                	ld	ra,8(sp)
    80003592:	6402                	ld	s0,0(sp)
    80003594:	0141                	addi	sp,sp,16
    80003596:	8082                	ret

0000000080003598 <sys_fork>:

uint64
sys_fork(void)
{
    80003598:	1141                	addi	sp,sp,-16
    8000359a:	e406                	sd	ra,8(sp)
    8000359c:	e022                	sd	s0,0(sp)
    8000359e:	0800                	addi	s0,sp,16
  return fork();
    800035a0:	fffff097          	auipc	ra,0xfffff
    800035a4:	dda080e7          	jalr	-550(ra) # 8000237a <fork>
}
    800035a8:	60a2                	ld	ra,8(sp)
    800035aa:	6402                	ld	s0,0(sp)
    800035ac:	0141                	addi	sp,sp,16
    800035ae:	8082                	ret

00000000800035b0 <sys_wait>:

uint64
sys_wait(void)
{
    800035b0:	1101                	addi	sp,sp,-32
    800035b2:	ec06                	sd	ra,24(sp)
    800035b4:	e822                	sd	s0,16(sp)
    800035b6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800035b8:	fe840593          	addi	a1,s0,-24
    800035bc:	4501                	li	a0,0
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	ece080e7          	jalr	-306(ra) # 8000348c <argaddr>
    800035c6:	87aa                	mv	a5,a0
    return -1;
    800035c8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800035ca:	0007c863          	bltz	a5,800035da <sys_wait+0x2a>
  return wait(p);
    800035ce:	fe843503          	ld	a0,-24(s0)
    800035d2:	fffff097          	auipc	ra,0xfffff
    800035d6:	2b4080e7          	jalr	692(ra) # 80002886 <wait>
}
    800035da:	60e2                	ld	ra,24(sp)
    800035dc:	6442                	ld	s0,16(sp)
    800035de:	6105                	addi	sp,sp,32
    800035e0:	8082                	ret

00000000800035e2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035e2:	7179                	addi	sp,sp,-48
    800035e4:	f406                	sd	ra,40(sp)
    800035e6:	f022                	sd	s0,32(sp)
    800035e8:	ec26                	sd	s1,24(sp)
    800035ea:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035ec:	fdc40593          	addi	a1,s0,-36
    800035f0:	4501                	li	a0,0
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	e78080e7          	jalr	-392(ra) # 8000346a <argint>
    800035fa:	87aa                	mv	a5,a0
    return -1;
    800035fc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800035fe:	0207c063          	bltz	a5,8000361e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003602:	fffff097          	auipc	ra,0xfffff
    80003606:	840080e7          	jalr	-1984(ra) # 80001e42 <myproc>
    8000360a:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    8000360c:	fdc42503          	lw	a0,-36(s0)
    80003610:	fffff097          	auipc	ra,0xfffff
    80003614:	cf6080e7          	jalr	-778(ra) # 80002306 <growproc>
    80003618:	00054863          	bltz	a0,80003628 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000361c:	8526                	mv	a0,s1
}
    8000361e:	70a2                	ld	ra,40(sp)
    80003620:	7402                	ld	s0,32(sp)
    80003622:	64e2                	ld	s1,24(sp)
    80003624:	6145                	addi	sp,sp,48
    80003626:	8082                	ret
    return -1;
    80003628:	557d                	li	a0,-1
    8000362a:	bfd5                	j	8000361e <sys_sbrk+0x3c>

000000008000362c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000362c:	7139                	addi	sp,sp,-64
    8000362e:	fc06                	sd	ra,56(sp)
    80003630:	f822                	sd	s0,48(sp)
    80003632:	f426                	sd	s1,40(sp)
    80003634:	f04a                	sd	s2,32(sp)
    80003636:	ec4e                	sd	s3,24(sp)
    80003638:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000363a:	fcc40593          	addi	a1,s0,-52
    8000363e:	4501                	li	a0,0
    80003640:	00000097          	auipc	ra,0x0
    80003644:	e2a080e7          	jalr	-470(ra) # 8000346a <argint>
    return -1;
    80003648:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000364a:	06054563          	bltz	a0,800036b4 <sys_sleep+0x88>
  acquire(&tickslock);
    8000364e:	0000d517          	auipc	a0,0xd
    80003652:	e5250513          	addi	a0,a0,-430 # 800104a0 <tickslock>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	58e080e7          	jalr	1422(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000365e:	00006917          	auipc	s2,0x6
    80003662:	9da92903          	lw	s2,-1574(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80003666:	fcc42783          	lw	a5,-52(s0)
    8000366a:	cf85                	beqz	a5,800036a2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000366c:	0000d997          	auipc	s3,0xd
    80003670:	e3498993          	addi	s3,s3,-460 # 800104a0 <tickslock>
    80003674:	00006497          	auipc	s1,0x6
    80003678:	9c448493          	addi	s1,s1,-1596 # 80009038 <ticks>
    if(myproc()->killed){
    8000367c:	ffffe097          	auipc	ra,0xffffe
    80003680:	7c6080e7          	jalr	1990(ra) # 80001e42 <myproc>
    80003684:	551c                	lw	a5,40(a0)
    80003686:	ef9d                	bnez	a5,800036c4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003688:	85ce                	mv	a1,s3
    8000368a:	8526                	mv	a0,s1
    8000368c:	fffff097          	auipc	ra,0xfffff
    80003690:	164080e7          	jalr	356(ra) # 800027f0 <sleep>
  while(ticks - ticks0 < n){
    80003694:	409c                	lw	a5,0(s1)
    80003696:	412787bb          	subw	a5,a5,s2
    8000369a:	fcc42703          	lw	a4,-52(s0)
    8000369e:	fce7efe3          	bltu	a5,a4,8000367c <sys_sleep+0x50>
  }
  release(&tickslock);
    800036a2:	0000d517          	auipc	a0,0xd
    800036a6:	dfe50513          	addi	a0,a0,-514 # 800104a0 <tickslock>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	600080e7          	jalr	1536(ra) # 80000caa <release>
  return 0;
    800036b2:	4781                	li	a5,0
}
    800036b4:	853e                	mv	a0,a5
    800036b6:	70e2                	ld	ra,56(sp)
    800036b8:	7442                	ld	s0,48(sp)
    800036ba:	74a2                	ld	s1,40(sp)
    800036bc:	7902                	ld	s2,32(sp)
    800036be:	69e2                	ld	s3,24(sp)
    800036c0:	6121                	addi	sp,sp,64
    800036c2:	8082                	ret
      release(&tickslock);
    800036c4:	0000d517          	auipc	a0,0xd
    800036c8:	ddc50513          	addi	a0,a0,-548 # 800104a0 <tickslock>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	5de080e7          	jalr	1502(ra) # 80000caa <release>
      return -1;
    800036d4:	57fd                	li	a5,-1
    800036d6:	bff9                	j	800036b4 <sys_sleep+0x88>

00000000800036d8 <sys_kill>:

uint64
sys_kill(void)
{
    800036d8:	1101                	addi	sp,sp,-32
    800036da:	ec06                	sd	ra,24(sp)
    800036dc:	e822                	sd	s0,16(sp)
    800036de:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036e0:	fec40593          	addi	a1,s0,-20
    800036e4:	4501                	li	a0,0
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	d84080e7          	jalr	-636(ra) # 8000346a <argint>
    800036ee:	87aa                	mv	a5,a0
    return -1;
    800036f0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036f2:	0007c863          	bltz	a5,80003702 <sys_kill+0x2a>
  return kill(pid);
    800036f6:	fec42503          	lw	a0,-20(s0)
    800036fa:	fffff097          	auipc	ra,0xfffff
    800036fe:	644080e7          	jalr	1604(ra) # 80002d3e <kill>
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret

000000008000370a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003714:	0000d517          	auipc	a0,0xd
    80003718:	d8c50513          	addi	a0,a0,-628 # 800104a0 <tickslock>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	4c8080e7          	jalr	1224(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003724:	00006497          	auipc	s1,0x6
    80003728:	9144a483          	lw	s1,-1772(s1) # 80009038 <ticks>
  release(&tickslock);
    8000372c:	0000d517          	auipc	a0,0xd
    80003730:	d7450513          	addi	a0,a0,-652 # 800104a0 <tickslock>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	576080e7          	jalr	1398(ra) # 80000caa <release>
  return xticks;
}
    8000373c:	02049513          	slli	a0,s1,0x20
    80003740:	9101                	srli	a0,a0,0x20
    80003742:	60e2                	ld	ra,24(sp)
    80003744:	6442                	ld	s0,16(sp)
    80003746:	64a2                	ld	s1,8(sp)
    80003748:	6105                	addi	sp,sp,32
    8000374a:	8082                	ret

000000008000374c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000374c:	7179                	addi	sp,sp,-48
    8000374e:	f406                	sd	ra,40(sp)
    80003750:	f022                	sd	s0,32(sp)
    80003752:	ec26                	sd	s1,24(sp)
    80003754:	e84a                	sd	s2,16(sp)
    80003756:	e44e                	sd	s3,8(sp)
    80003758:	e052                	sd	s4,0(sp)
    8000375a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000375c:	00005597          	auipc	a1,0x5
    80003760:	fec58593          	addi	a1,a1,-20 # 80008748 <syscalls+0xb0>
    80003764:	0000d517          	auipc	a0,0xd
    80003768:	d5450513          	addi	a0,a0,-684 # 800104b8 <bcache>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	3e8080e7          	jalr	1000(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003774:	00015797          	auipc	a5,0x15
    80003778:	d4478793          	addi	a5,a5,-700 # 800184b8 <bcache+0x8000>
    8000377c:	00015717          	auipc	a4,0x15
    80003780:	fa470713          	addi	a4,a4,-92 # 80018720 <bcache+0x8268>
    80003784:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003788:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000378c:	0000d497          	auipc	s1,0xd
    80003790:	d4448493          	addi	s1,s1,-700 # 800104d0 <bcache+0x18>
    b->next = bcache.head.next;
    80003794:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003796:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003798:	00005a17          	auipc	s4,0x5
    8000379c:	fb8a0a13          	addi	s4,s4,-72 # 80008750 <syscalls+0xb8>
    b->next = bcache.head.next;
    800037a0:	2b893783          	ld	a5,696(s2)
    800037a4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800037a6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800037aa:	85d2                	mv	a1,s4
    800037ac:	01048513          	addi	a0,s1,16
    800037b0:	00001097          	auipc	ra,0x1
    800037b4:	4bc080e7          	jalr	1212(ra) # 80004c6c <initsleeplock>
    bcache.head.next->prev = b;
    800037b8:	2b893783          	ld	a5,696(s2)
    800037bc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800037be:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037c2:	45848493          	addi	s1,s1,1112
    800037c6:	fd349de3          	bne	s1,s3,800037a0 <binit+0x54>
  }
}
    800037ca:	70a2                	ld	ra,40(sp)
    800037cc:	7402                	ld	s0,32(sp)
    800037ce:	64e2                	ld	s1,24(sp)
    800037d0:	6942                	ld	s2,16(sp)
    800037d2:	69a2                	ld	s3,8(sp)
    800037d4:	6a02                	ld	s4,0(sp)
    800037d6:	6145                	addi	sp,sp,48
    800037d8:	8082                	ret

00000000800037da <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037da:	7179                	addi	sp,sp,-48
    800037dc:	f406                	sd	ra,40(sp)
    800037de:	f022                	sd	s0,32(sp)
    800037e0:	ec26                	sd	s1,24(sp)
    800037e2:	e84a                	sd	s2,16(sp)
    800037e4:	e44e                	sd	s3,8(sp)
    800037e6:	1800                	addi	s0,sp,48
    800037e8:	89aa                	mv	s3,a0
    800037ea:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800037ec:	0000d517          	auipc	a0,0xd
    800037f0:	ccc50513          	addi	a0,a0,-820 # 800104b8 <bcache>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	3f0080e7          	jalr	1008(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037fc:	00015497          	auipc	s1,0x15
    80003800:	f744b483          	ld	s1,-140(s1) # 80018770 <bcache+0x82b8>
    80003804:	00015797          	auipc	a5,0x15
    80003808:	f1c78793          	addi	a5,a5,-228 # 80018720 <bcache+0x8268>
    8000380c:	02f48f63          	beq	s1,a5,8000384a <bread+0x70>
    80003810:	873e                	mv	a4,a5
    80003812:	a021                	j	8000381a <bread+0x40>
    80003814:	68a4                	ld	s1,80(s1)
    80003816:	02e48a63          	beq	s1,a4,8000384a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000381a:	449c                	lw	a5,8(s1)
    8000381c:	ff379ce3          	bne	a5,s3,80003814 <bread+0x3a>
    80003820:	44dc                	lw	a5,12(s1)
    80003822:	ff2799e3          	bne	a5,s2,80003814 <bread+0x3a>
      b->refcnt++;
    80003826:	40bc                	lw	a5,64(s1)
    80003828:	2785                	addiw	a5,a5,1
    8000382a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000382c:	0000d517          	auipc	a0,0xd
    80003830:	c8c50513          	addi	a0,a0,-884 # 800104b8 <bcache>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	476080e7          	jalr	1142(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000383c:	01048513          	addi	a0,s1,16
    80003840:	00001097          	auipc	ra,0x1
    80003844:	466080e7          	jalr	1126(ra) # 80004ca6 <acquiresleep>
      return b;
    80003848:	a8b9                	j	800038a6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000384a:	00015497          	auipc	s1,0x15
    8000384e:	f1e4b483          	ld	s1,-226(s1) # 80018768 <bcache+0x82b0>
    80003852:	00015797          	auipc	a5,0x15
    80003856:	ece78793          	addi	a5,a5,-306 # 80018720 <bcache+0x8268>
    8000385a:	00f48863          	beq	s1,a5,8000386a <bread+0x90>
    8000385e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003860:	40bc                	lw	a5,64(s1)
    80003862:	cf81                	beqz	a5,8000387a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003864:	64a4                	ld	s1,72(s1)
    80003866:	fee49de3          	bne	s1,a4,80003860 <bread+0x86>
  panic("bget: no buffers");
    8000386a:	00005517          	auipc	a0,0x5
    8000386e:	eee50513          	addi	a0,a0,-274 # 80008758 <syscalls+0xc0>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	ccc080e7          	jalr	-820(ra) # 8000053e <panic>
      b->dev = dev;
    8000387a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000387e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003882:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003886:	4785                	li	a5,1
    80003888:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000388a:	0000d517          	auipc	a0,0xd
    8000388e:	c2e50513          	addi	a0,a0,-978 # 800104b8 <bcache>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	418080e7          	jalr	1048(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000389a:	01048513          	addi	a0,s1,16
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	408080e7          	jalr	1032(ra) # 80004ca6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800038a6:	409c                	lw	a5,0(s1)
    800038a8:	cb89                	beqz	a5,800038ba <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800038aa:	8526                	mv	a0,s1
    800038ac:	70a2                	ld	ra,40(sp)
    800038ae:	7402                	ld	s0,32(sp)
    800038b0:	64e2                	ld	s1,24(sp)
    800038b2:	6942                	ld	s2,16(sp)
    800038b4:	69a2                	ld	s3,8(sp)
    800038b6:	6145                	addi	sp,sp,48
    800038b8:	8082                	ret
    virtio_disk_rw(b, 0);
    800038ba:	4581                	li	a1,0
    800038bc:	8526                	mv	a0,s1
    800038be:	00003097          	auipc	ra,0x3
    800038c2:	f08080e7          	jalr	-248(ra) # 800067c6 <virtio_disk_rw>
    b->valid = 1;
    800038c6:	4785                	li	a5,1
    800038c8:	c09c                	sw	a5,0(s1)
  return b;
    800038ca:	b7c5                	j	800038aa <bread+0xd0>

00000000800038cc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800038cc:	1101                	addi	sp,sp,-32
    800038ce:	ec06                	sd	ra,24(sp)
    800038d0:	e822                	sd	s0,16(sp)
    800038d2:	e426                	sd	s1,8(sp)
    800038d4:	1000                	addi	s0,sp,32
    800038d6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038d8:	0541                	addi	a0,a0,16
    800038da:	00001097          	auipc	ra,0x1
    800038de:	466080e7          	jalr	1126(ra) # 80004d40 <holdingsleep>
    800038e2:	cd01                	beqz	a0,800038fa <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038e4:	4585                	li	a1,1
    800038e6:	8526                	mv	a0,s1
    800038e8:	00003097          	auipc	ra,0x3
    800038ec:	ede080e7          	jalr	-290(ra) # 800067c6 <virtio_disk_rw>
}
    800038f0:	60e2                	ld	ra,24(sp)
    800038f2:	6442                	ld	s0,16(sp)
    800038f4:	64a2                	ld	s1,8(sp)
    800038f6:	6105                	addi	sp,sp,32
    800038f8:	8082                	ret
    panic("bwrite");
    800038fa:	00005517          	auipc	a0,0x5
    800038fe:	e7650513          	addi	a0,a0,-394 # 80008770 <syscalls+0xd8>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	c3c080e7          	jalr	-964(ra) # 8000053e <panic>

000000008000390a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000390a:	1101                	addi	sp,sp,-32
    8000390c:	ec06                	sd	ra,24(sp)
    8000390e:	e822                	sd	s0,16(sp)
    80003910:	e426                	sd	s1,8(sp)
    80003912:	e04a                	sd	s2,0(sp)
    80003914:	1000                	addi	s0,sp,32
    80003916:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003918:	01050913          	addi	s2,a0,16
    8000391c:	854a                	mv	a0,s2
    8000391e:	00001097          	auipc	ra,0x1
    80003922:	422080e7          	jalr	1058(ra) # 80004d40 <holdingsleep>
    80003926:	c92d                	beqz	a0,80003998 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003928:	854a                	mv	a0,s2
    8000392a:	00001097          	auipc	ra,0x1
    8000392e:	3d2080e7          	jalr	978(ra) # 80004cfc <releasesleep>

  acquire(&bcache.lock);
    80003932:	0000d517          	auipc	a0,0xd
    80003936:	b8650513          	addi	a0,a0,-1146 # 800104b8 <bcache>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	2aa080e7          	jalr	682(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003942:	40bc                	lw	a5,64(s1)
    80003944:	37fd                	addiw	a5,a5,-1
    80003946:	0007871b          	sext.w	a4,a5
    8000394a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000394c:	eb05                	bnez	a4,8000397c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000394e:	68bc                	ld	a5,80(s1)
    80003950:	64b8                	ld	a4,72(s1)
    80003952:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003954:	64bc                	ld	a5,72(s1)
    80003956:	68b8                	ld	a4,80(s1)
    80003958:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000395a:	00015797          	auipc	a5,0x15
    8000395e:	b5e78793          	addi	a5,a5,-1186 # 800184b8 <bcache+0x8000>
    80003962:	2b87b703          	ld	a4,696(a5)
    80003966:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003968:	00015717          	auipc	a4,0x15
    8000396c:	db870713          	addi	a4,a4,-584 # 80018720 <bcache+0x8268>
    80003970:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003972:	2b87b703          	ld	a4,696(a5)
    80003976:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003978:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000397c:	0000d517          	auipc	a0,0xd
    80003980:	b3c50513          	addi	a0,a0,-1220 # 800104b8 <bcache>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	326080e7          	jalr	806(ra) # 80000caa <release>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	64a2                	ld	s1,8(sp)
    80003992:	6902                	ld	s2,0(sp)
    80003994:	6105                	addi	sp,sp,32
    80003996:	8082                	ret
    panic("brelse");
    80003998:	00005517          	auipc	a0,0x5
    8000399c:	de050513          	addi	a0,a0,-544 # 80008778 <syscalls+0xe0>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	b9e080e7          	jalr	-1122(ra) # 8000053e <panic>

00000000800039a8 <bpin>:

void
bpin(struct buf *b) {
    800039a8:	1101                	addi	sp,sp,-32
    800039aa:	ec06                	sd	ra,24(sp)
    800039ac:	e822                	sd	s0,16(sp)
    800039ae:	e426                	sd	s1,8(sp)
    800039b0:	1000                	addi	s0,sp,32
    800039b2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039b4:	0000d517          	auipc	a0,0xd
    800039b8:	b0450513          	addi	a0,a0,-1276 # 800104b8 <bcache>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	228080e7          	jalr	552(ra) # 80000be4 <acquire>
  b->refcnt++;
    800039c4:	40bc                	lw	a5,64(s1)
    800039c6:	2785                	addiw	a5,a5,1
    800039c8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039ca:	0000d517          	auipc	a0,0xd
    800039ce:	aee50513          	addi	a0,a0,-1298 # 800104b8 <bcache>
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	2d8080e7          	jalr	728(ra) # 80000caa <release>
}
    800039da:	60e2                	ld	ra,24(sp)
    800039dc:	6442                	ld	s0,16(sp)
    800039de:	64a2                	ld	s1,8(sp)
    800039e0:	6105                	addi	sp,sp,32
    800039e2:	8082                	ret

00000000800039e4 <bunpin>:

void
bunpin(struct buf *b) {
    800039e4:	1101                	addi	sp,sp,-32
    800039e6:	ec06                	sd	ra,24(sp)
    800039e8:	e822                	sd	s0,16(sp)
    800039ea:	e426                	sd	s1,8(sp)
    800039ec:	1000                	addi	s0,sp,32
    800039ee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039f0:	0000d517          	auipc	a0,0xd
    800039f4:	ac850513          	addi	a0,a0,-1336 # 800104b8 <bcache>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	1ec080e7          	jalr	492(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003a00:	40bc                	lw	a5,64(s1)
    80003a02:	37fd                	addiw	a5,a5,-1
    80003a04:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a06:	0000d517          	auipc	a0,0xd
    80003a0a:	ab250513          	addi	a0,a0,-1358 # 800104b8 <bcache>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	29c080e7          	jalr	668(ra) # 80000caa <release>
}
    80003a16:	60e2                	ld	ra,24(sp)
    80003a18:	6442                	ld	s0,16(sp)
    80003a1a:	64a2                	ld	s1,8(sp)
    80003a1c:	6105                	addi	sp,sp,32
    80003a1e:	8082                	ret

0000000080003a20 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a20:	1101                	addi	sp,sp,-32
    80003a22:	ec06                	sd	ra,24(sp)
    80003a24:	e822                	sd	s0,16(sp)
    80003a26:	e426                	sd	s1,8(sp)
    80003a28:	e04a                	sd	s2,0(sp)
    80003a2a:	1000                	addi	s0,sp,32
    80003a2c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a2e:	00d5d59b          	srliw	a1,a1,0xd
    80003a32:	00015797          	auipc	a5,0x15
    80003a36:	1627a783          	lw	a5,354(a5) # 80018b94 <sb+0x1c>
    80003a3a:	9dbd                	addw	a1,a1,a5
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	d9e080e7          	jalr	-610(ra) # 800037da <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a44:	0074f713          	andi	a4,s1,7
    80003a48:	4785                	li	a5,1
    80003a4a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a4e:	14ce                	slli	s1,s1,0x33
    80003a50:	90d9                	srli	s1,s1,0x36
    80003a52:	00950733          	add	a4,a0,s1
    80003a56:	05874703          	lbu	a4,88(a4)
    80003a5a:	00e7f6b3          	and	a3,a5,a4
    80003a5e:	c69d                	beqz	a3,80003a8c <bfree+0x6c>
    80003a60:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a62:	94aa                	add	s1,s1,a0
    80003a64:	fff7c793          	not	a5,a5
    80003a68:	8ff9                	and	a5,a5,a4
    80003a6a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a6e:	00001097          	auipc	ra,0x1
    80003a72:	118080e7          	jalr	280(ra) # 80004b86 <log_write>
  brelse(bp);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	e92080e7          	jalr	-366(ra) # 8000390a <brelse>
}
    80003a80:	60e2                	ld	ra,24(sp)
    80003a82:	6442                	ld	s0,16(sp)
    80003a84:	64a2                	ld	s1,8(sp)
    80003a86:	6902                	ld	s2,0(sp)
    80003a88:	6105                	addi	sp,sp,32
    80003a8a:	8082                	ret
    panic("freeing free block");
    80003a8c:	00005517          	auipc	a0,0x5
    80003a90:	cf450513          	addi	a0,a0,-780 # 80008780 <syscalls+0xe8>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	aaa080e7          	jalr	-1366(ra) # 8000053e <panic>

0000000080003a9c <balloc>:
{
    80003a9c:	711d                	addi	sp,sp,-96
    80003a9e:	ec86                	sd	ra,88(sp)
    80003aa0:	e8a2                	sd	s0,80(sp)
    80003aa2:	e4a6                	sd	s1,72(sp)
    80003aa4:	e0ca                	sd	s2,64(sp)
    80003aa6:	fc4e                	sd	s3,56(sp)
    80003aa8:	f852                	sd	s4,48(sp)
    80003aaa:	f456                	sd	s5,40(sp)
    80003aac:	f05a                	sd	s6,32(sp)
    80003aae:	ec5e                	sd	s7,24(sp)
    80003ab0:	e862                	sd	s8,16(sp)
    80003ab2:	e466                	sd	s9,8(sp)
    80003ab4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003ab6:	00015797          	auipc	a5,0x15
    80003aba:	0c67a783          	lw	a5,198(a5) # 80018b7c <sb+0x4>
    80003abe:	cbd1                	beqz	a5,80003b52 <balloc+0xb6>
    80003ac0:	8baa                	mv	s7,a0
    80003ac2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003ac4:	00015b17          	auipc	s6,0x15
    80003ac8:	0b4b0b13          	addi	s6,s6,180 # 80018b78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003acc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003ace:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ad0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003ad2:	6c89                	lui	s9,0x2
    80003ad4:	a831                	j	80003af0 <balloc+0x54>
    brelse(bp);
    80003ad6:	854a                	mv	a0,s2
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	e32080e7          	jalr	-462(ra) # 8000390a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ae0:	015c87bb          	addw	a5,s9,s5
    80003ae4:	00078a9b          	sext.w	s5,a5
    80003ae8:	004b2703          	lw	a4,4(s6)
    80003aec:	06eaf363          	bgeu	s5,a4,80003b52 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003af0:	41fad79b          	sraiw	a5,s5,0x1f
    80003af4:	0137d79b          	srliw	a5,a5,0x13
    80003af8:	015787bb          	addw	a5,a5,s5
    80003afc:	40d7d79b          	sraiw	a5,a5,0xd
    80003b00:	01cb2583          	lw	a1,28(s6)
    80003b04:	9dbd                	addw	a1,a1,a5
    80003b06:	855e                	mv	a0,s7
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	cd2080e7          	jalr	-814(ra) # 800037da <bread>
    80003b10:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b12:	004b2503          	lw	a0,4(s6)
    80003b16:	000a849b          	sext.w	s1,s5
    80003b1a:	8662                	mv	a2,s8
    80003b1c:	faa4fde3          	bgeu	s1,a0,80003ad6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003b20:	41f6579b          	sraiw	a5,a2,0x1f
    80003b24:	01d7d69b          	srliw	a3,a5,0x1d
    80003b28:	00c6873b          	addw	a4,a3,a2
    80003b2c:	00777793          	andi	a5,a4,7
    80003b30:	9f95                	subw	a5,a5,a3
    80003b32:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b36:	4037571b          	sraiw	a4,a4,0x3
    80003b3a:	00e906b3          	add	a3,s2,a4
    80003b3e:	0586c683          	lbu	a3,88(a3)
    80003b42:	00d7f5b3          	and	a1,a5,a3
    80003b46:	cd91                	beqz	a1,80003b62 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b48:	2605                	addiw	a2,a2,1
    80003b4a:	2485                	addiw	s1,s1,1
    80003b4c:	fd4618e3          	bne	a2,s4,80003b1c <balloc+0x80>
    80003b50:	b759                	j	80003ad6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b52:	00005517          	auipc	a0,0x5
    80003b56:	c4650513          	addi	a0,a0,-954 # 80008798 <syscalls+0x100>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	9e4080e7          	jalr	-1564(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b62:	974a                	add	a4,a4,s2
    80003b64:	8fd5                	or	a5,a5,a3
    80003b66:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	00001097          	auipc	ra,0x1
    80003b70:	01a080e7          	jalr	26(ra) # 80004b86 <log_write>
        brelse(bp);
    80003b74:	854a                	mv	a0,s2
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	d94080e7          	jalr	-620(ra) # 8000390a <brelse>
  bp = bread(dev, bno);
    80003b7e:	85a6                	mv	a1,s1
    80003b80:	855e                	mv	a0,s7
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	c58080e7          	jalr	-936(ra) # 800037da <bread>
    80003b8a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b8c:	40000613          	li	a2,1024
    80003b90:	4581                	li	a1,0
    80003b92:	05850513          	addi	a0,a0,88
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	16e080e7          	jalr	366(ra) # 80000d04 <memset>
  log_write(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00001097          	auipc	ra,0x1
    80003ba4:	fe6080e7          	jalr	-26(ra) # 80004b86 <log_write>
  brelse(bp);
    80003ba8:	854a                	mv	a0,s2
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	d60080e7          	jalr	-672(ra) # 8000390a <brelse>
}
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	60e6                	ld	ra,88(sp)
    80003bb6:	6446                	ld	s0,80(sp)
    80003bb8:	64a6                	ld	s1,72(sp)
    80003bba:	6906                	ld	s2,64(sp)
    80003bbc:	79e2                	ld	s3,56(sp)
    80003bbe:	7a42                	ld	s4,48(sp)
    80003bc0:	7aa2                	ld	s5,40(sp)
    80003bc2:	7b02                	ld	s6,32(sp)
    80003bc4:	6be2                	ld	s7,24(sp)
    80003bc6:	6c42                	ld	s8,16(sp)
    80003bc8:	6ca2                	ld	s9,8(sp)
    80003bca:	6125                	addi	sp,sp,96
    80003bcc:	8082                	ret

0000000080003bce <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003bce:	7179                	addi	sp,sp,-48
    80003bd0:	f406                	sd	ra,40(sp)
    80003bd2:	f022                	sd	s0,32(sp)
    80003bd4:	ec26                	sd	s1,24(sp)
    80003bd6:	e84a                	sd	s2,16(sp)
    80003bd8:	e44e                	sd	s3,8(sp)
    80003bda:	e052                	sd	s4,0(sp)
    80003bdc:	1800                	addi	s0,sp,48
    80003bde:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003be0:	47ad                	li	a5,11
    80003be2:	04b7fe63          	bgeu	a5,a1,80003c3e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003be6:	ff45849b          	addiw	s1,a1,-12
    80003bea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bee:	0ff00793          	li	a5,255
    80003bf2:	0ae7e363          	bltu	a5,a4,80003c98 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003bf6:	08052583          	lw	a1,128(a0)
    80003bfa:	c5ad                	beqz	a1,80003c64 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003bfc:	00092503          	lw	a0,0(s2)
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	bda080e7          	jalr	-1062(ra) # 800037da <bread>
    80003c08:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c0a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c0e:	02049593          	slli	a1,s1,0x20
    80003c12:	9181                	srli	a1,a1,0x20
    80003c14:	058a                	slli	a1,a1,0x2
    80003c16:	00b784b3          	add	s1,a5,a1
    80003c1a:	0004a983          	lw	s3,0(s1)
    80003c1e:	04098d63          	beqz	s3,80003c78 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003c22:	8552                	mv	a0,s4
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	ce6080e7          	jalr	-794(ra) # 8000390a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c2c:	854e                	mv	a0,s3
    80003c2e:	70a2                	ld	ra,40(sp)
    80003c30:	7402                	ld	s0,32(sp)
    80003c32:	64e2                	ld	s1,24(sp)
    80003c34:	6942                	ld	s2,16(sp)
    80003c36:	69a2                	ld	s3,8(sp)
    80003c38:	6a02                	ld	s4,0(sp)
    80003c3a:	6145                	addi	sp,sp,48
    80003c3c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c3e:	02059493          	slli	s1,a1,0x20
    80003c42:	9081                	srli	s1,s1,0x20
    80003c44:	048a                	slli	s1,s1,0x2
    80003c46:	94aa                	add	s1,s1,a0
    80003c48:	0504a983          	lw	s3,80(s1)
    80003c4c:	fe0990e3          	bnez	s3,80003c2c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c50:	4108                	lw	a0,0(a0)
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	e4a080e7          	jalr	-438(ra) # 80003a9c <balloc>
    80003c5a:	0005099b          	sext.w	s3,a0
    80003c5e:	0534a823          	sw	s3,80(s1)
    80003c62:	b7e9                	j	80003c2c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c64:	4108                	lw	a0,0(a0)
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	e36080e7          	jalr	-458(ra) # 80003a9c <balloc>
    80003c6e:	0005059b          	sext.w	a1,a0
    80003c72:	08b92023          	sw	a1,128(s2)
    80003c76:	b759                	j	80003bfc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c78:	00092503          	lw	a0,0(s2)
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	e20080e7          	jalr	-480(ra) # 80003a9c <balloc>
    80003c84:	0005099b          	sext.w	s3,a0
    80003c88:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c8c:	8552                	mv	a0,s4
    80003c8e:	00001097          	auipc	ra,0x1
    80003c92:	ef8080e7          	jalr	-264(ra) # 80004b86 <log_write>
    80003c96:	b771                	j	80003c22 <bmap+0x54>
  panic("bmap: out of range");
    80003c98:	00005517          	auipc	a0,0x5
    80003c9c:	b1850513          	addi	a0,a0,-1256 # 800087b0 <syscalls+0x118>
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	89e080e7          	jalr	-1890(ra) # 8000053e <panic>

0000000080003ca8 <iget>:
{
    80003ca8:	7179                	addi	sp,sp,-48
    80003caa:	f406                	sd	ra,40(sp)
    80003cac:	f022                	sd	s0,32(sp)
    80003cae:	ec26                	sd	s1,24(sp)
    80003cb0:	e84a                	sd	s2,16(sp)
    80003cb2:	e44e                	sd	s3,8(sp)
    80003cb4:	e052                	sd	s4,0(sp)
    80003cb6:	1800                	addi	s0,sp,48
    80003cb8:	89aa                	mv	s3,a0
    80003cba:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003cbc:	00015517          	auipc	a0,0x15
    80003cc0:	edc50513          	addi	a0,a0,-292 # 80018b98 <itable>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	f20080e7          	jalr	-224(ra) # 80000be4 <acquire>
  empty = 0;
    80003ccc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003cce:	00015497          	auipc	s1,0x15
    80003cd2:	ee248493          	addi	s1,s1,-286 # 80018bb0 <itable+0x18>
    80003cd6:	00017697          	auipc	a3,0x17
    80003cda:	96a68693          	addi	a3,a3,-1686 # 8001a640 <log>
    80003cde:	a039                	j	80003cec <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ce0:	02090b63          	beqz	s2,80003d16 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ce4:	08848493          	addi	s1,s1,136
    80003ce8:	02d48a63          	beq	s1,a3,80003d1c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cec:	449c                	lw	a5,8(s1)
    80003cee:	fef059e3          	blez	a5,80003ce0 <iget+0x38>
    80003cf2:	4098                	lw	a4,0(s1)
    80003cf4:	ff3716e3          	bne	a4,s3,80003ce0 <iget+0x38>
    80003cf8:	40d8                	lw	a4,4(s1)
    80003cfa:	ff4713e3          	bne	a4,s4,80003ce0 <iget+0x38>
      ip->ref++;
    80003cfe:	2785                	addiw	a5,a5,1
    80003d00:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d02:	00015517          	auipc	a0,0x15
    80003d06:	e9650513          	addi	a0,a0,-362 # 80018b98 <itable>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	fa0080e7          	jalr	-96(ra) # 80000caa <release>
      return ip;
    80003d12:	8926                	mv	s2,s1
    80003d14:	a03d                	j	80003d42 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d16:	f7f9                	bnez	a5,80003ce4 <iget+0x3c>
    80003d18:	8926                	mv	s2,s1
    80003d1a:	b7e9                	j	80003ce4 <iget+0x3c>
  if(empty == 0)
    80003d1c:	02090c63          	beqz	s2,80003d54 <iget+0xac>
  ip->dev = dev;
    80003d20:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d24:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d28:	4785                	li	a5,1
    80003d2a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d2e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d32:	00015517          	auipc	a0,0x15
    80003d36:	e6650513          	addi	a0,a0,-410 # 80018b98 <itable>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	f70080e7          	jalr	-144(ra) # 80000caa <release>
}
    80003d42:	854a                	mv	a0,s2
    80003d44:	70a2                	ld	ra,40(sp)
    80003d46:	7402                	ld	s0,32(sp)
    80003d48:	64e2                	ld	s1,24(sp)
    80003d4a:	6942                	ld	s2,16(sp)
    80003d4c:	69a2                	ld	s3,8(sp)
    80003d4e:	6a02                	ld	s4,0(sp)
    80003d50:	6145                	addi	sp,sp,48
    80003d52:	8082                	ret
    panic("iget: no inodes");
    80003d54:	00005517          	auipc	a0,0x5
    80003d58:	a7450513          	addi	a0,a0,-1420 # 800087c8 <syscalls+0x130>
    80003d5c:	ffffc097          	auipc	ra,0xffffc
    80003d60:	7e2080e7          	jalr	2018(ra) # 8000053e <panic>

0000000080003d64 <fsinit>:
fsinit(int dev) {
    80003d64:	7179                	addi	sp,sp,-48
    80003d66:	f406                	sd	ra,40(sp)
    80003d68:	f022                	sd	s0,32(sp)
    80003d6a:	ec26                	sd	s1,24(sp)
    80003d6c:	e84a                	sd	s2,16(sp)
    80003d6e:	e44e                	sd	s3,8(sp)
    80003d70:	1800                	addi	s0,sp,48
    80003d72:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d74:	4585                	li	a1,1
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	a64080e7          	jalr	-1436(ra) # 800037da <bread>
    80003d7e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d80:	00015997          	auipc	s3,0x15
    80003d84:	df898993          	addi	s3,s3,-520 # 80018b78 <sb>
    80003d88:	02000613          	li	a2,32
    80003d8c:	05850593          	addi	a1,a0,88
    80003d90:	854e                	mv	a0,s3
    80003d92:	ffffd097          	auipc	ra,0xffffd
    80003d96:	fd2080e7          	jalr	-46(ra) # 80000d64 <memmove>
  brelse(bp);
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	b6e080e7          	jalr	-1170(ra) # 8000390a <brelse>
  if(sb.magic != FSMAGIC)
    80003da4:	0009a703          	lw	a4,0(s3)
    80003da8:	102037b7          	lui	a5,0x10203
    80003dac:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003db0:	02f71263          	bne	a4,a5,80003dd4 <fsinit+0x70>
  initlog(dev, &sb);
    80003db4:	00015597          	auipc	a1,0x15
    80003db8:	dc458593          	addi	a1,a1,-572 # 80018b78 <sb>
    80003dbc:	854a                	mv	a0,s2
    80003dbe:	00001097          	auipc	ra,0x1
    80003dc2:	b4c080e7          	jalr	-1204(ra) # 8000490a <initlog>
}
    80003dc6:	70a2                	ld	ra,40(sp)
    80003dc8:	7402                	ld	s0,32(sp)
    80003dca:	64e2                	ld	s1,24(sp)
    80003dcc:	6942                	ld	s2,16(sp)
    80003dce:	69a2                	ld	s3,8(sp)
    80003dd0:	6145                	addi	sp,sp,48
    80003dd2:	8082                	ret
    panic("invalid file system");
    80003dd4:	00005517          	auipc	a0,0x5
    80003dd8:	a0450513          	addi	a0,a0,-1532 # 800087d8 <syscalls+0x140>
    80003ddc:	ffffc097          	auipc	ra,0xffffc
    80003de0:	762080e7          	jalr	1890(ra) # 8000053e <panic>

0000000080003de4 <iinit>:
{
    80003de4:	7179                	addi	sp,sp,-48
    80003de6:	f406                	sd	ra,40(sp)
    80003de8:	f022                	sd	s0,32(sp)
    80003dea:	ec26                	sd	s1,24(sp)
    80003dec:	e84a                	sd	s2,16(sp)
    80003dee:	e44e                	sd	s3,8(sp)
    80003df0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003df2:	00005597          	auipc	a1,0x5
    80003df6:	9fe58593          	addi	a1,a1,-1538 # 800087f0 <syscalls+0x158>
    80003dfa:	00015517          	auipc	a0,0x15
    80003dfe:	d9e50513          	addi	a0,a0,-610 # 80018b98 <itable>
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	d52080e7          	jalr	-686(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e0a:	00015497          	auipc	s1,0x15
    80003e0e:	db648493          	addi	s1,s1,-586 # 80018bc0 <itable+0x28>
    80003e12:	00017997          	auipc	s3,0x17
    80003e16:	83e98993          	addi	s3,s3,-1986 # 8001a650 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e1a:	00005917          	auipc	s2,0x5
    80003e1e:	9de90913          	addi	s2,s2,-1570 # 800087f8 <syscalls+0x160>
    80003e22:	85ca                	mv	a1,s2
    80003e24:	8526                	mv	a0,s1
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	e46080e7          	jalr	-442(ra) # 80004c6c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e2e:	08848493          	addi	s1,s1,136
    80003e32:	ff3498e3          	bne	s1,s3,80003e22 <iinit+0x3e>
}
    80003e36:	70a2                	ld	ra,40(sp)
    80003e38:	7402                	ld	s0,32(sp)
    80003e3a:	64e2                	ld	s1,24(sp)
    80003e3c:	6942                	ld	s2,16(sp)
    80003e3e:	69a2                	ld	s3,8(sp)
    80003e40:	6145                	addi	sp,sp,48
    80003e42:	8082                	ret

0000000080003e44 <ialloc>:
{
    80003e44:	715d                	addi	sp,sp,-80
    80003e46:	e486                	sd	ra,72(sp)
    80003e48:	e0a2                	sd	s0,64(sp)
    80003e4a:	fc26                	sd	s1,56(sp)
    80003e4c:	f84a                	sd	s2,48(sp)
    80003e4e:	f44e                	sd	s3,40(sp)
    80003e50:	f052                	sd	s4,32(sp)
    80003e52:	ec56                	sd	s5,24(sp)
    80003e54:	e85a                	sd	s6,16(sp)
    80003e56:	e45e                	sd	s7,8(sp)
    80003e58:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e5a:	00015717          	auipc	a4,0x15
    80003e5e:	d2a72703          	lw	a4,-726(a4) # 80018b84 <sb+0xc>
    80003e62:	4785                	li	a5,1
    80003e64:	04e7fa63          	bgeu	a5,a4,80003eb8 <ialloc+0x74>
    80003e68:	8aaa                	mv	s5,a0
    80003e6a:	8bae                	mv	s7,a1
    80003e6c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e6e:	00015a17          	auipc	s4,0x15
    80003e72:	d0aa0a13          	addi	s4,s4,-758 # 80018b78 <sb>
    80003e76:	00048b1b          	sext.w	s6,s1
    80003e7a:	0044d593          	srli	a1,s1,0x4
    80003e7e:	018a2783          	lw	a5,24(s4)
    80003e82:	9dbd                	addw	a1,a1,a5
    80003e84:	8556                	mv	a0,s5
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	954080e7          	jalr	-1708(ra) # 800037da <bread>
    80003e8e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e90:	05850993          	addi	s3,a0,88
    80003e94:	00f4f793          	andi	a5,s1,15
    80003e98:	079a                	slli	a5,a5,0x6
    80003e9a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e9c:	00099783          	lh	a5,0(s3)
    80003ea0:	c785                	beqz	a5,80003ec8 <ialloc+0x84>
    brelse(bp);
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	a68080e7          	jalr	-1432(ra) # 8000390a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003eaa:	0485                	addi	s1,s1,1
    80003eac:	00ca2703          	lw	a4,12(s4)
    80003eb0:	0004879b          	sext.w	a5,s1
    80003eb4:	fce7e1e3          	bltu	a5,a4,80003e76 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003eb8:	00005517          	auipc	a0,0x5
    80003ebc:	94850513          	addi	a0,a0,-1720 # 80008800 <syscalls+0x168>
    80003ec0:	ffffc097          	auipc	ra,0xffffc
    80003ec4:	67e080e7          	jalr	1662(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003ec8:	04000613          	li	a2,64
    80003ecc:	4581                	li	a1,0
    80003ece:	854e                	mv	a0,s3
    80003ed0:	ffffd097          	auipc	ra,0xffffd
    80003ed4:	e34080e7          	jalr	-460(ra) # 80000d04 <memset>
      dip->type = type;
    80003ed8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003edc:	854a                	mv	a0,s2
    80003ede:	00001097          	auipc	ra,0x1
    80003ee2:	ca8080e7          	jalr	-856(ra) # 80004b86 <log_write>
      brelse(bp);
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	a22080e7          	jalr	-1502(ra) # 8000390a <brelse>
      return iget(dev, inum);
    80003ef0:	85da                	mv	a1,s6
    80003ef2:	8556                	mv	a0,s5
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	db4080e7          	jalr	-588(ra) # 80003ca8 <iget>
}
    80003efc:	60a6                	ld	ra,72(sp)
    80003efe:	6406                	ld	s0,64(sp)
    80003f00:	74e2                	ld	s1,56(sp)
    80003f02:	7942                	ld	s2,48(sp)
    80003f04:	79a2                	ld	s3,40(sp)
    80003f06:	7a02                	ld	s4,32(sp)
    80003f08:	6ae2                	ld	s5,24(sp)
    80003f0a:	6b42                	ld	s6,16(sp)
    80003f0c:	6ba2                	ld	s7,8(sp)
    80003f0e:	6161                	addi	sp,sp,80
    80003f10:	8082                	ret

0000000080003f12 <iupdate>:
{
    80003f12:	1101                	addi	sp,sp,-32
    80003f14:	ec06                	sd	ra,24(sp)
    80003f16:	e822                	sd	s0,16(sp)
    80003f18:	e426                	sd	s1,8(sp)
    80003f1a:	e04a                	sd	s2,0(sp)
    80003f1c:	1000                	addi	s0,sp,32
    80003f1e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f20:	415c                	lw	a5,4(a0)
    80003f22:	0047d79b          	srliw	a5,a5,0x4
    80003f26:	00015597          	auipc	a1,0x15
    80003f2a:	c6a5a583          	lw	a1,-918(a1) # 80018b90 <sb+0x18>
    80003f2e:	9dbd                	addw	a1,a1,a5
    80003f30:	4108                	lw	a0,0(a0)
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	8a8080e7          	jalr	-1880(ra) # 800037da <bread>
    80003f3a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f3c:	05850793          	addi	a5,a0,88
    80003f40:	40c8                	lw	a0,4(s1)
    80003f42:	893d                	andi	a0,a0,15
    80003f44:	051a                	slli	a0,a0,0x6
    80003f46:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f48:	04449703          	lh	a4,68(s1)
    80003f4c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f50:	04649703          	lh	a4,70(s1)
    80003f54:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f58:	04849703          	lh	a4,72(s1)
    80003f5c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f60:	04a49703          	lh	a4,74(s1)
    80003f64:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f68:	44f8                	lw	a4,76(s1)
    80003f6a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f6c:	03400613          	li	a2,52
    80003f70:	05048593          	addi	a1,s1,80
    80003f74:	0531                	addi	a0,a0,12
    80003f76:	ffffd097          	auipc	ra,0xffffd
    80003f7a:	dee080e7          	jalr	-530(ra) # 80000d64 <memmove>
  log_write(bp);
    80003f7e:	854a                	mv	a0,s2
    80003f80:	00001097          	auipc	ra,0x1
    80003f84:	c06080e7          	jalr	-1018(ra) # 80004b86 <log_write>
  brelse(bp);
    80003f88:	854a                	mv	a0,s2
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	980080e7          	jalr	-1664(ra) # 8000390a <brelse>
}
    80003f92:	60e2                	ld	ra,24(sp)
    80003f94:	6442                	ld	s0,16(sp)
    80003f96:	64a2                	ld	s1,8(sp)
    80003f98:	6902                	ld	s2,0(sp)
    80003f9a:	6105                	addi	sp,sp,32
    80003f9c:	8082                	ret

0000000080003f9e <idup>:
{
    80003f9e:	1101                	addi	sp,sp,-32
    80003fa0:	ec06                	sd	ra,24(sp)
    80003fa2:	e822                	sd	s0,16(sp)
    80003fa4:	e426                	sd	s1,8(sp)
    80003fa6:	1000                	addi	s0,sp,32
    80003fa8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003faa:	00015517          	auipc	a0,0x15
    80003fae:	bee50513          	addi	a0,a0,-1042 # 80018b98 <itable>
    80003fb2:	ffffd097          	auipc	ra,0xffffd
    80003fb6:	c32080e7          	jalr	-974(ra) # 80000be4 <acquire>
  ip->ref++;
    80003fba:	449c                	lw	a5,8(s1)
    80003fbc:	2785                	addiw	a5,a5,1
    80003fbe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fc0:	00015517          	auipc	a0,0x15
    80003fc4:	bd850513          	addi	a0,a0,-1064 # 80018b98 <itable>
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	ce2080e7          	jalr	-798(ra) # 80000caa <release>
}
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	60e2                	ld	ra,24(sp)
    80003fd4:	6442                	ld	s0,16(sp)
    80003fd6:	64a2                	ld	s1,8(sp)
    80003fd8:	6105                	addi	sp,sp,32
    80003fda:	8082                	ret

0000000080003fdc <ilock>:
{
    80003fdc:	1101                	addi	sp,sp,-32
    80003fde:	ec06                	sd	ra,24(sp)
    80003fe0:	e822                	sd	s0,16(sp)
    80003fe2:	e426                	sd	s1,8(sp)
    80003fe4:	e04a                	sd	s2,0(sp)
    80003fe6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003fe8:	c115                	beqz	a0,8000400c <ilock+0x30>
    80003fea:	84aa                	mv	s1,a0
    80003fec:	451c                	lw	a5,8(a0)
    80003fee:	00f05f63          	blez	a5,8000400c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ff2:	0541                	addi	a0,a0,16
    80003ff4:	00001097          	auipc	ra,0x1
    80003ff8:	cb2080e7          	jalr	-846(ra) # 80004ca6 <acquiresleep>
  if(ip->valid == 0){
    80003ffc:	40bc                	lw	a5,64(s1)
    80003ffe:	cf99                	beqz	a5,8000401c <ilock+0x40>
}
    80004000:	60e2                	ld	ra,24(sp)
    80004002:	6442                	ld	s0,16(sp)
    80004004:	64a2                	ld	s1,8(sp)
    80004006:	6902                	ld	s2,0(sp)
    80004008:	6105                	addi	sp,sp,32
    8000400a:	8082                	ret
    panic("ilock");
    8000400c:	00005517          	auipc	a0,0x5
    80004010:	80c50513          	addi	a0,a0,-2036 # 80008818 <syscalls+0x180>
    80004014:	ffffc097          	auipc	ra,0xffffc
    80004018:	52a080e7          	jalr	1322(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000401c:	40dc                	lw	a5,4(s1)
    8000401e:	0047d79b          	srliw	a5,a5,0x4
    80004022:	00015597          	auipc	a1,0x15
    80004026:	b6e5a583          	lw	a1,-1170(a1) # 80018b90 <sb+0x18>
    8000402a:	9dbd                	addw	a1,a1,a5
    8000402c:	4088                	lw	a0,0(s1)
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	7ac080e7          	jalr	1964(ra) # 800037da <bread>
    80004036:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004038:	05850593          	addi	a1,a0,88
    8000403c:	40dc                	lw	a5,4(s1)
    8000403e:	8bbd                	andi	a5,a5,15
    80004040:	079a                	slli	a5,a5,0x6
    80004042:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004044:	00059783          	lh	a5,0(a1)
    80004048:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000404c:	00259783          	lh	a5,2(a1)
    80004050:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004054:	00459783          	lh	a5,4(a1)
    80004058:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000405c:	00659783          	lh	a5,6(a1)
    80004060:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004064:	459c                	lw	a5,8(a1)
    80004066:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004068:	03400613          	li	a2,52
    8000406c:	05b1                	addi	a1,a1,12
    8000406e:	05048513          	addi	a0,s1,80
    80004072:	ffffd097          	auipc	ra,0xffffd
    80004076:	cf2080e7          	jalr	-782(ra) # 80000d64 <memmove>
    brelse(bp);
    8000407a:	854a                	mv	a0,s2
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	88e080e7          	jalr	-1906(ra) # 8000390a <brelse>
    ip->valid = 1;
    80004084:	4785                	li	a5,1
    80004086:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004088:	04449783          	lh	a5,68(s1)
    8000408c:	fbb5                	bnez	a5,80004000 <ilock+0x24>
      panic("ilock: no type");
    8000408e:	00004517          	auipc	a0,0x4
    80004092:	79250513          	addi	a0,a0,1938 # 80008820 <syscalls+0x188>
    80004096:	ffffc097          	auipc	ra,0xffffc
    8000409a:	4a8080e7          	jalr	1192(ra) # 8000053e <panic>

000000008000409e <iunlock>:
{
    8000409e:	1101                	addi	sp,sp,-32
    800040a0:	ec06                	sd	ra,24(sp)
    800040a2:	e822                	sd	s0,16(sp)
    800040a4:	e426                	sd	s1,8(sp)
    800040a6:	e04a                	sd	s2,0(sp)
    800040a8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800040aa:	c905                	beqz	a0,800040da <iunlock+0x3c>
    800040ac:	84aa                	mv	s1,a0
    800040ae:	01050913          	addi	s2,a0,16
    800040b2:	854a                	mv	a0,s2
    800040b4:	00001097          	auipc	ra,0x1
    800040b8:	c8c080e7          	jalr	-884(ra) # 80004d40 <holdingsleep>
    800040bc:	cd19                	beqz	a0,800040da <iunlock+0x3c>
    800040be:	449c                	lw	a5,8(s1)
    800040c0:	00f05d63          	blez	a5,800040da <iunlock+0x3c>
  releasesleep(&ip->lock);
    800040c4:	854a                	mv	a0,s2
    800040c6:	00001097          	auipc	ra,0x1
    800040ca:	c36080e7          	jalr	-970(ra) # 80004cfc <releasesleep>
}
    800040ce:	60e2                	ld	ra,24(sp)
    800040d0:	6442                	ld	s0,16(sp)
    800040d2:	64a2                	ld	s1,8(sp)
    800040d4:	6902                	ld	s2,0(sp)
    800040d6:	6105                	addi	sp,sp,32
    800040d8:	8082                	ret
    panic("iunlock");
    800040da:	00004517          	auipc	a0,0x4
    800040de:	75650513          	addi	a0,a0,1878 # 80008830 <syscalls+0x198>
    800040e2:	ffffc097          	auipc	ra,0xffffc
    800040e6:	45c080e7          	jalr	1116(ra) # 8000053e <panic>

00000000800040ea <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040ea:	7179                	addi	sp,sp,-48
    800040ec:	f406                	sd	ra,40(sp)
    800040ee:	f022                	sd	s0,32(sp)
    800040f0:	ec26                	sd	s1,24(sp)
    800040f2:	e84a                	sd	s2,16(sp)
    800040f4:	e44e                	sd	s3,8(sp)
    800040f6:	e052                	sd	s4,0(sp)
    800040f8:	1800                	addi	s0,sp,48
    800040fa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040fc:	05050493          	addi	s1,a0,80
    80004100:	08050913          	addi	s2,a0,128
    80004104:	a021                	j	8000410c <itrunc+0x22>
    80004106:	0491                	addi	s1,s1,4
    80004108:	01248d63          	beq	s1,s2,80004122 <itrunc+0x38>
    if(ip->addrs[i]){
    8000410c:	408c                	lw	a1,0(s1)
    8000410e:	dde5                	beqz	a1,80004106 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004110:	0009a503          	lw	a0,0(s3)
    80004114:	00000097          	auipc	ra,0x0
    80004118:	90c080e7          	jalr	-1780(ra) # 80003a20 <bfree>
      ip->addrs[i] = 0;
    8000411c:	0004a023          	sw	zero,0(s1)
    80004120:	b7dd                	j	80004106 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004122:	0809a583          	lw	a1,128(s3)
    80004126:	e185                	bnez	a1,80004146 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004128:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000412c:	854e                	mv	a0,s3
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	de4080e7          	jalr	-540(ra) # 80003f12 <iupdate>
}
    80004136:	70a2                	ld	ra,40(sp)
    80004138:	7402                	ld	s0,32(sp)
    8000413a:	64e2                	ld	s1,24(sp)
    8000413c:	6942                	ld	s2,16(sp)
    8000413e:	69a2                	ld	s3,8(sp)
    80004140:	6a02                	ld	s4,0(sp)
    80004142:	6145                	addi	sp,sp,48
    80004144:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004146:	0009a503          	lw	a0,0(s3)
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	690080e7          	jalr	1680(ra) # 800037da <bread>
    80004152:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004154:	05850493          	addi	s1,a0,88
    80004158:	45850913          	addi	s2,a0,1112
    8000415c:	a811                	j	80004170 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000415e:	0009a503          	lw	a0,0(s3)
    80004162:	00000097          	auipc	ra,0x0
    80004166:	8be080e7          	jalr	-1858(ra) # 80003a20 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000416a:	0491                	addi	s1,s1,4
    8000416c:	01248563          	beq	s1,s2,80004176 <itrunc+0x8c>
      if(a[j])
    80004170:	408c                	lw	a1,0(s1)
    80004172:	dde5                	beqz	a1,8000416a <itrunc+0x80>
    80004174:	b7ed                	j	8000415e <itrunc+0x74>
    brelse(bp);
    80004176:	8552                	mv	a0,s4
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	792080e7          	jalr	1938(ra) # 8000390a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004180:	0809a583          	lw	a1,128(s3)
    80004184:	0009a503          	lw	a0,0(s3)
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	898080e7          	jalr	-1896(ra) # 80003a20 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004190:	0809a023          	sw	zero,128(s3)
    80004194:	bf51                	j	80004128 <itrunc+0x3e>

0000000080004196 <iput>:
{
    80004196:	1101                	addi	sp,sp,-32
    80004198:	ec06                	sd	ra,24(sp)
    8000419a:	e822                	sd	s0,16(sp)
    8000419c:	e426                	sd	s1,8(sp)
    8000419e:	e04a                	sd	s2,0(sp)
    800041a0:	1000                	addi	s0,sp,32
    800041a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800041a4:	00015517          	auipc	a0,0x15
    800041a8:	9f450513          	addi	a0,a0,-1548 # 80018b98 <itable>
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	a38080e7          	jalr	-1480(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041b4:	4498                	lw	a4,8(s1)
    800041b6:	4785                	li	a5,1
    800041b8:	02f70363          	beq	a4,a5,800041de <iput+0x48>
  ip->ref--;
    800041bc:	449c                	lw	a5,8(s1)
    800041be:	37fd                	addiw	a5,a5,-1
    800041c0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041c2:	00015517          	auipc	a0,0x15
    800041c6:	9d650513          	addi	a0,a0,-1578 # 80018b98 <itable>
    800041ca:	ffffd097          	auipc	ra,0xffffd
    800041ce:	ae0080e7          	jalr	-1312(ra) # 80000caa <release>
}
    800041d2:	60e2                	ld	ra,24(sp)
    800041d4:	6442                	ld	s0,16(sp)
    800041d6:	64a2                	ld	s1,8(sp)
    800041d8:	6902                	ld	s2,0(sp)
    800041da:	6105                	addi	sp,sp,32
    800041dc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041de:	40bc                	lw	a5,64(s1)
    800041e0:	dff1                	beqz	a5,800041bc <iput+0x26>
    800041e2:	04a49783          	lh	a5,74(s1)
    800041e6:	fbf9                	bnez	a5,800041bc <iput+0x26>
    acquiresleep(&ip->lock);
    800041e8:	01048913          	addi	s2,s1,16
    800041ec:	854a                	mv	a0,s2
    800041ee:	00001097          	auipc	ra,0x1
    800041f2:	ab8080e7          	jalr	-1352(ra) # 80004ca6 <acquiresleep>
    release(&itable.lock);
    800041f6:	00015517          	auipc	a0,0x15
    800041fa:	9a250513          	addi	a0,a0,-1630 # 80018b98 <itable>
    800041fe:	ffffd097          	auipc	ra,0xffffd
    80004202:	aac080e7          	jalr	-1364(ra) # 80000caa <release>
    itrunc(ip);
    80004206:	8526                	mv	a0,s1
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	ee2080e7          	jalr	-286(ra) # 800040ea <itrunc>
    ip->type = 0;
    80004210:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004214:	8526                	mv	a0,s1
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	cfc080e7          	jalr	-772(ra) # 80003f12 <iupdate>
    ip->valid = 0;
    8000421e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004222:	854a                	mv	a0,s2
    80004224:	00001097          	auipc	ra,0x1
    80004228:	ad8080e7          	jalr	-1320(ra) # 80004cfc <releasesleep>
    acquire(&itable.lock);
    8000422c:	00015517          	auipc	a0,0x15
    80004230:	96c50513          	addi	a0,a0,-1684 # 80018b98 <itable>
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	9b0080e7          	jalr	-1616(ra) # 80000be4 <acquire>
    8000423c:	b741                	j	800041bc <iput+0x26>

000000008000423e <iunlockput>:
{
    8000423e:	1101                	addi	sp,sp,-32
    80004240:	ec06                	sd	ra,24(sp)
    80004242:	e822                	sd	s0,16(sp)
    80004244:	e426                	sd	s1,8(sp)
    80004246:	1000                	addi	s0,sp,32
    80004248:	84aa                	mv	s1,a0
  iunlock(ip);
    8000424a:	00000097          	auipc	ra,0x0
    8000424e:	e54080e7          	jalr	-428(ra) # 8000409e <iunlock>
  iput(ip);
    80004252:	8526                	mv	a0,s1
    80004254:	00000097          	auipc	ra,0x0
    80004258:	f42080e7          	jalr	-190(ra) # 80004196 <iput>
}
    8000425c:	60e2                	ld	ra,24(sp)
    8000425e:	6442                	ld	s0,16(sp)
    80004260:	64a2                	ld	s1,8(sp)
    80004262:	6105                	addi	sp,sp,32
    80004264:	8082                	ret

0000000080004266 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004266:	1141                	addi	sp,sp,-16
    80004268:	e422                	sd	s0,8(sp)
    8000426a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000426c:	411c                	lw	a5,0(a0)
    8000426e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004270:	415c                	lw	a5,4(a0)
    80004272:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004274:	04451783          	lh	a5,68(a0)
    80004278:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000427c:	04a51783          	lh	a5,74(a0)
    80004280:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004284:	04c56783          	lwu	a5,76(a0)
    80004288:	e99c                	sd	a5,16(a1)
}
    8000428a:	6422                	ld	s0,8(sp)
    8000428c:	0141                	addi	sp,sp,16
    8000428e:	8082                	ret

0000000080004290 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004290:	457c                	lw	a5,76(a0)
    80004292:	0ed7e963          	bltu	a5,a3,80004384 <readi+0xf4>
{
    80004296:	7159                	addi	sp,sp,-112
    80004298:	f486                	sd	ra,104(sp)
    8000429a:	f0a2                	sd	s0,96(sp)
    8000429c:	eca6                	sd	s1,88(sp)
    8000429e:	e8ca                	sd	s2,80(sp)
    800042a0:	e4ce                	sd	s3,72(sp)
    800042a2:	e0d2                	sd	s4,64(sp)
    800042a4:	fc56                	sd	s5,56(sp)
    800042a6:	f85a                	sd	s6,48(sp)
    800042a8:	f45e                	sd	s7,40(sp)
    800042aa:	f062                	sd	s8,32(sp)
    800042ac:	ec66                	sd	s9,24(sp)
    800042ae:	e86a                	sd	s10,16(sp)
    800042b0:	e46e                	sd	s11,8(sp)
    800042b2:	1880                	addi	s0,sp,112
    800042b4:	8baa                	mv	s7,a0
    800042b6:	8c2e                	mv	s8,a1
    800042b8:	8ab2                	mv	s5,a2
    800042ba:	84b6                	mv	s1,a3
    800042bc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042be:	9f35                	addw	a4,a4,a3
    return 0;
    800042c0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800042c2:	0ad76063          	bltu	a4,a3,80004362 <readi+0xd2>
  if(off + n > ip->size)
    800042c6:	00e7f463          	bgeu	a5,a4,800042ce <readi+0x3e>
    n = ip->size - off;
    800042ca:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042ce:	0a0b0963          	beqz	s6,80004380 <readi+0xf0>
    800042d2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042d4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800042d8:	5cfd                	li	s9,-1
    800042da:	a82d                	j	80004314 <readi+0x84>
    800042dc:	020a1d93          	slli	s11,s4,0x20
    800042e0:	020ddd93          	srli	s11,s11,0x20
    800042e4:	05890613          	addi	a2,s2,88
    800042e8:	86ee                	mv	a3,s11
    800042ea:	963a                	add	a2,a2,a4
    800042ec:	85d6                	mv	a1,s5
    800042ee:	8562                	mv	a0,s8
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	ac0080e7          	jalr	-1344(ra) # 80002db0 <either_copyout>
    800042f8:	05950d63          	beq	a0,s9,80004352 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042fc:	854a                	mv	a0,s2
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	60c080e7          	jalr	1548(ra) # 8000390a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004306:	013a09bb          	addw	s3,s4,s3
    8000430a:	009a04bb          	addw	s1,s4,s1
    8000430e:	9aee                	add	s5,s5,s11
    80004310:	0569f763          	bgeu	s3,s6,8000435e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004314:	000ba903          	lw	s2,0(s7)
    80004318:	00a4d59b          	srliw	a1,s1,0xa
    8000431c:	855e                	mv	a0,s7
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	8b0080e7          	jalr	-1872(ra) # 80003bce <bmap>
    80004326:	0005059b          	sext.w	a1,a0
    8000432a:	854a                	mv	a0,s2
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	4ae080e7          	jalr	1198(ra) # 800037da <bread>
    80004334:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004336:	3ff4f713          	andi	a4,s1,1023
    8000433a:	40ed07bb          	subw	a5,s10,a4
    8000433e:	413b06bb          	subw	a3,s6,s3
    80004342:	8a3e                	mv	s4,a5
    80004344:	2781                	sext.w	a5,a5
    80004346:	0006861b          	sext.w	a2,a3
    8000434a:	f8f679e3          	bgeu	a2,a5,800042dc <readi+0x4c>
    8000434e:	8a36                	mv	s4,a3
    80004350:	b771                	j	800042dc <readi+0x4c>
      brelse(bp);
    80004352:	854a                	mv	a0,s2
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	5b6080e7          	jalr	1462(ra) # 8000390a <brelse>
      tot = -1;
    8000435c:	59fd                	li	s3,-1
  }
  return tot;
    8000435e:	0009851b          	sext.w	a0,s3
}
    80004362:	70a6                	ld	ra,104(sp)
    80004364:	7406                	ld	s0,96(sp)
    80004366:	64e6                	ld	s1,88(sp)
    80004368:	6946                	ld	s2,80(sp)
    8000436a:	69a6                	ld	s3,72(sp)
    8000436c:	6a06                	ld	s4,64(sp)
    8000436e:	7ae2                	ld	s5,56(sp)
    80004370:	7b42                	ld	s6,48(sp)
    80004372:	7ba2                	ld	s7,40(sp)
    80004374:	7c02                	ld	s8,32(sp)
    80004376:	6ce2                	ld	s9,24(sp)
    80004378:	6d42                	ld	s10,16(sp)
    8000437a:	6da2                	ld	s11,8(sp)
    8000437c:	6165                	addi	sp,sp,112
    8000437e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004380:	89da                	mv	s3,s6
    80004382:	bff1                	j	8000435e <readi+0xce>
    return 0;
    80004384:	4501                	li	a0,0
}
    80004386:	8082                	ret

0000000080004388 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004388:	457c                	lw	a5,76(a0)
    8000438a:	10d7e863          	bltu	a5,a3,8000449a <writei+0x112>
{
    8000438e:	7159                	addi	sp,sp,-112
    80004390:	f486                	sd	ra,104(sp)
    80004392:	f0a2                	sd	s0,96(sp)
    80004394:	eca6                	sd	s1,88(sp)
    80004396:	e8ca                	sd	s2,80(sp)
    80004398:	e4ce                	sd	s3,72(sp)
    8000439a:	e0d2                	sd	s4,64(sp)
    8000439c:	fc56                	sd	s5,56(sp)
    8000439e:	f85a                	sd	s6,48(sp)
    800043a0:	f45e                	sd	s7,40(sp)
    800043a2:	f062                	sd	s8,32(sp)
    800043a4:	ec66                	sd	s9,24(sp)
    800043a6:	e86a                	sd	s10,16(sp)
    800043a8:	e46e                	sd	s11,8(sp)
    800043aa:	1880                	addi	s0,sp,112
    800043ac:	8b2a                	mv	s6,a0
    800043ae:	8c2e                	mv	s8,a1
    800043b0:	8ab2                	mv	s5,a2
    800043b2:	8936                	mv	s2,a3
    800043b4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800043b6:	00e687bb          	addw	a5,a3,a4
    800043ba:	0ed7e263          	bltu	a5,a3,8000449e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800043be:	00043737          	lui	a4,0x43
    800043c2:	0ef76063          	bltu	a4,a5,800044a2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043c6:	0c0b8863          	beqz	s7,80004496 <writei+0x10e>
    800043ca:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800043cc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800043d0:	5cfd                	li	s9,-1
    800043d2:	a091                	j	80004416 <writei+0x8e>
    800043d4:	02099d93          	slli	s11,s3,0x20
    800043d8:	020ddd93          	srli	s11,s11,0x20
    800043dc:	05848513          	addi	a0,s1,88
    800043e0:	86ee                	mv	a3,s11
    800043e2:	8656                	mv	a2,s5
    800043e4:	85e2                	mv	a1,s8
    800043e6:	953a                	add	a0,a0,a4
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	a1e080e7          	jalr	-1506(ra) # 80002e06 <either_copyin>
    800043f0:	07950263          	beq	a0,s9,80004454 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043f4:	8526                	mv	a0,s1
    800043f6:	00000097          	auipc	ra,0x0
    800043fa:	790080e7          	jalr	1936(ra) # 80004b86 <log_write>
    brelse(bp);
    800043fe:	8526                	mv	a0,s1
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	50a080e7          	jalr	1290(ra) # 8000390a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004408:	01498a3b          	addw	s4,s3,s4
    8000440c:	0129893b          	addw	s2,s3,s2
    80004410:	9aee                	add	s5,s5,s11
    80004412:	057a7663          	bgeu	s4,s7,8000445e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004416:	000b2483          	lw	s1,0(s6)
    8000441a:	00a9559b          	srliw	a1,s2,0xa
    8000441e:	855a                	mv	a0,s6
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	7ae080e7          	jalr	1966(ra) # 80003bce <bmap>
    80004428:	0005059b          	sext.w	a1,a0
    8000442c:	8526                	mv	a0,s1
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	3ac080e7          	jalr	940(ra) # 800037da <bread>
    80004436:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004438:	3ff97713          	andi	a4,s2,1023
    8000443c:	40ed07bb          	subw	a5,s10,a4
    80004440:	414b86bb          	subw	a3,s7,s4
    80004444:	89be                	mv	s3,a5
    80004446:	2781                	sext.w	a5,a5
    80004448:	0006861b          	sext.w	a2,a3
    8000444c:	f8f674e3          	bgeu	a2,a5,800043d4 <writei+0x4c>
    80004450:	89b6                	mv	s3,a3
    80004452:	b749                	j	800043d4 <writei+0x4c>
      brelse(bp);
    80004454:	8526                	mv	a0,s1
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	4b4080e7          	jalr	1204(ra) # 8000390a <brelse>
  }

  if(off > ip->size)
    8000445e:	04cb2783          	lw	a5,76(s6)
    80004462:	0127f463          	bgeu	a5,s2,8000446a <writei+0xe2>
    ip->size = off;
    80004466:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000446a:	855a                	mv	a0,s6
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	aa6080e7          	jalr	-1370(ra) # 80003f12 <iupdate>

  return tot;
    80004474:	000a051b          	sext.w	a0,s4
}
    80004478:	70a6                	ld	ra,104(sp)
    8000447a:	7406                	ld	s0,96(sp)
    8000447c:	64e6                	ld	s1,88(sp)
    8000447e:	6946                	ld	s2,80(sp)
    80004480:	69a6                	ld	s3,72(sp)
    80004482:	6a06                	ld	s4,64(sp)
    80004484:	7ae2                	ld	s5,56(sp)
    80004486:	7b42                	ld	s6,48(sp)
    80004488:	7ba2                	ld	s7,40(sp)
    8000448a:	7c02                	ld	s8,32(sp)
    8000448c:	6ce2                	ld	s9,24(sp)
    8000448e:	6d42                	ld	s10,16(sp)
    80004490:	6da2                	ld	s11,8(sp)
    80004492:	6165                	addi	sp,sp,112
    80004494:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004496:	8a5e                	mv	s4,s7
    80004498:	bfc9                	j	8000446a <writei+0xe2>
    return -1;
    8000449a:	557d                	li	a0,-1
}
    8000449c:	8082                	ret
    return -1;
    8000449e:	557d                	li	a0,-1
    800044a0:	bfe1                	j	80004478 <writei+0xf0>
    return -1;
    800044a2:	557d                	li	a0,-1
    800044a4:	bfd1                	j	80004478 <writei+0xf0>

00000000800044a6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800044a6:	1141                	addi	sp,sp,-16
    800044a8:	e406                	sd	ra,8(sp)
    800044aa:	e022                	sd	s0,0(sp)
    800044ac:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800044ae:	4639                	li	a2,14
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	92c080e7          	jalr	-1748(ra) # 80000ddc <strncmp>
}
    800044b8:	60a2                	ld	ra,8(sp)
    800044ba:	6402                	ld	s0,0(sp)
    800044bc:	0141                	addi	sp,sp,16
    800044be:	8082                	ret

00000000800044c0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800044c0:	7139                	addi	sp,sp,-64
    800044c2:	fc06                	sd	ra,56(sp)
    800044c4:	f822                	sd	s0,48(sp)
    800044c6:	f426                	sd	s1,40(sp)
    800044c8:	f04a                	sd	s2,32(sp)
    800044ca:	ec4e                	sd	s3,24(sp)
    800044cc:	e852                	sd	s4,16(sp)
    800044ce:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800044d0:	04451703          	lh	a4,68(a0)
    800044d4:	4785                	li	a5,1
    800044d6:	00f71a63          	bne	a4,a5,800044ea <dirlookup+0x2a>
    800044da:	892a                	mv	s2,a0
    800044dc:	89ae                	mv	s3,a1
    800044de:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044e0:	457c                	lw	a5,76(a0)
    800044e2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044e4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044e6:	e79d                	bnez	a5,80004514 <dirlookup+0x54>
    800044e8:	a8a5                	j	80004560 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044ea:	00004517          	auipc	a0,0x4
    800044ee:	34e50513          	addi	a0,a0,846 # 80008838 <syscalls+0x1a0>
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	04c080e7          	jalr	76(ra) # 8000053e <panic>
      panic("dirlookup read");
    800044fa:	00004517          	auipc	a0,0x4
    800044fe:	35650513          	addi	a0,a0,854 # 80008850 <syscalls+0x1b8>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	03c080e7          	jalr	60(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000450a:	24c1                	addiw	s1,s1,16
    8000450c:	04c92783          	lw	a5,76(s2)
    80004510:	04f4f763          	bgeu	s1,a5,8000455e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004514:	4741                	li	a4,16
    80004516:	86a6                	mv	a3,s1
    80004518:	fc040613          	addi	a2,s0,-64
    8000451c:	4581                	li	a1,0
    8000451e:	854a                	mv	a0,s2
    80004520:	00000097          	auipc	ra,0x0
    80004524:	d70080e7          	jalr	-656(ra) # 80004290 <readi>
    80004528:	47c1                	li	a5,16
    8000452a:	fcf518e3          	bne	a0,a5,800044fa <dirlookup+0x3a>
    if(de.inum == 0)
    8000452e:	fc045783          	lhu	a5,-64(s0)
    80004532:	dfe1                	beqz	a5,8000450a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004534:	fc240593          	addi	a1,s0,-62
    80004538:	854e                	mv	a0,s3
    8000453a:	00000097          	auipc	ra,0x0
    8000453e:	f6c080e7          	jalr	-148(ra) # 800044a6 <namecmp>
    80004542:	f561                	bnez	a0,8000450a <dirlookup+0x4a>
      if(poff)
    80004544:	000a0463          	beqz	s4,8000454c <dirlookup+0x8c>
        *poff = off;
    80004548:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000454c:	fc045583          	lhu	a1,-64(s0)
    80004550:	00092503          	lw	a0,0(s2)
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	754080e7          	jalr	1876(ra) # 80003ca8 <iget>
    8000455c:	a011                	j	80004560 <dirlookup+0xa0>
  return 0;
    8000455e:	4501                	li	a0,0
}
    80004560:	70e2                	ld	ra,56(sp)
    80004562:	7442                	ld	s0,48(sp)
    80004564:	74a2                	ld	s1,40(sp)
    80004566:	7902                	ld	s2,32(sp)
    80004568:	69e2                	ld	s3,24(sp)
    8000456a:	6a42                	ld	s4,16(sp)
    8000456c:	6121                	addi	sp,sp,64
    8000456e:	8082                	ret

0000000080004570 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004570:	711d                	addi	sp,sp,-96
    80004572:	ec86                	sd	ra,88(sp)
    80004574:	e8a2                	sd	s0,80(sp)
    80004576:	e4a6                	sd	s1,72(sp)
    80004578:	e0ca                	sd	s2,64(sp)
    8000457a:	fc4e                	sd	s3,56(sp)
    8000457c:	f852                	sd	s4,48(sp)
    8000457e:	f456                	sd	s5,40(sp)
    80004580:	f05a                	sd	s6,32(sp)
    80004582:	ec5e                	sd	s7,24(sp)
    80004584:	e862                	sd	s8,16(sp)
    80004586:	e466                	sd	s9,8(sp)
    80004588:	1080                	addi	s0,sp,96
    8000458a:	84aa                	mv	s1,a0
    8000458c:	8b2e                	mv	s6,a1
    8000458e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004590:	00054703          	lbu	a4,0(a0)
    80004594:	02f00793          	li	a5,47
    80004598:	02f70363          	beq	a4,a5,800045be <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000459c:	ffffe097          	auipc	ra,0xffffe
    800045a0:	8a6080e7          	jalr	-1882(ra) # 80001e42 <myproc>
    800045a4:	17053503          	ld	a0,368(a0)
    800045a8:	00000097          	auipc	ra,0x0
    800045ac:	9f6080e7          	jalr	-1546(ra) # 80003f9e <idup>
    800045b0:	89aa                	mv	s3,a0
  while(*path == '/')
    800045b2:	02f00913          	li	s2,47
  len = path - s;
    800045b6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800045b8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800045ba:	4c05                	li	s8,1
    800045bc:	a865                	j	80004674 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800045be:	4585                	li	a1,1
    800045c0:	4505                	li	a0,1
    800045c2:	fffff097          	auipc	ra,0xfffff
    800045c6:	6e6080e7          	jalr	1766(ra) # 80003ca8 <iget>
    800045ca:	89aa                	mv	s3,a0
    800045cc:	b7dd                	j	800045b2 <namex+0x42>
      iunlockput(ip);
    800045ce:	854e                	mv	a0,s3
    800045d0:	00000097          	auipc	ra,0x0
    800045d4:	c6e080e7          	jalr	-914(ra) # 8000423e <iunlockput>
      return 0;
    800045d8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800045da:	854e                	mv	a0,s3
    800045dc:	60e6                	ld	ra,88(sp)
    800045de:	6446                	ld	s0,80(sp)
    800045e0:	64a6                	ld	s1,72(sp)
    800045e2:	6906                	ld	s2,64(sp)
    800045e4:	79e2                	ld	s3,56(sp)
    800045e6:	7a42                	ld	s4,48(sp)
    800045e8:	7aa2                	ld	s5,40(sp)
    800045ea:	7b02                	ld	s6,32(sp)
    800045ec:	6be2                	ld	s7,24(sp)
    800045ee:	6c42                	ld	s8,16(sp)
    800045f0:	6ca2                	ld	s9,8(sp)
    800045f2:	6125                	addi	sp,sp,96
    800045f4:	8082                	ret
      iunlock(ip);
    800045f6:	854e                	mv	a0,s3
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	aa6080e7          	jalr	-1370(ra) # 8000409e <iunlock>
      return ip;
    80004600:	bfe9                	j	800045da <namex+0x6a>
      iunlockput(ip);
    80004602:	854e                	mv	a0,s3
    80004604:	00000097          	auipc	ra,0x0
    80004608:	c3a080e7          	jalr	-966(ra) # 8000423e <iunlockput>
      return 0;
    8000460c:	89d2                	mv	s3,s4
    8000460e:	b7f1                	j	800045da <namex+0x6a>
  len = path - s;
    80004610:	40b48633          	sub	a2,s1,a1
    80004614:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004618:	094cd463          	bge	s9,s4,800046a0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000461c:	4639                	li	a2,14
    8000461e:	8556                	mv	a0,s5
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	744080e7          	jalr	1860(ra) # 80000d64 <memmove>
  while(*path == '/')
    80004628:	0004c783          	lbu	a5,0(s1)
    8000462c:	01279763          	bne	a5,s2,8000463a <namex+0xca>
    path++;
    80004630:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004632:	0004c783          	lbu	a5,0(s1)
    80004636:	ff278de3          	beq	a5,s2,80004630 <namex+0xc0>
    ilock(ip);
    8000463a:	854e                	mv	a0,s3
    8000463c:	00000097          	auipc	ra,0x0
    80004640:	9a0080e7          	jalr	-1632(ra) # 80003fdc <ilock>
    if(ip->type != T_DIR){
    80004644:	04499783          	lh	a5,68(s3)
    80004648:	f98793e3          	bne	a5,s8,800045ce <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000464c:	000b0563          	beqz	s6,80004656 <namex+0xe6>
    80004650:	0004c783          	lbu	a5,0(s1)
    80004654:	d3cd                	beqz	a5,800045f6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004656:	865e                	mv	a2,s7
    80004658:	85d6                	mv	a1,s5
    8000465a:	854e                	mv	a0,s3
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	e64080e7          	jalr	-412(ra) # 800044c0 <dirlookup>
    80004664:	8a2a                	mv	s4,a0
    80004666:	dd51                	beqz	a0,80004602 <namex+0x92>
    iunlockput(ip);
    80004668:	854e                	mv	a0,s3
    8000466a:	00000097          	auipc	ra,0x0
    8000466e:	bd4080e7          	jalr	-1068(ra) # 8000423e <iunlockput>
    ip = next;
    80004672:	89d2                	mv	s3,s4
  while(*path == '/')
    80004674:	0004c783          	lbu	a5,0(s1)
    80004678:	05279763          	bne	a5,s2,800046c6 <namex+0x156>
    path++;
    8000467c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000467e:	0004c783          	lbu	a5,0(s1)
    80004682:	ff278de3          	beq	a5,s2,8000467c <namex+0x10c>
  if(*path == 0)
    80004686:	c79d                	beqz	a5,800046b4 <namex+0x144>
    path++;
    80004688:	85a6                	mv	a1,s1
  len = path - s;
    8000468a:	8a5e                	mv	s4,s7
    8000468c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000468e:	01278963          	beq	a5,s2,800046a0 <namex+0x130>
    80004692:	dfbd                	beqz	a5,80004610 <namex+0xa0>
    path++;
    80004694:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004696:	0004c783          	lbu	a5,0(s1)
    8000469a:	ff279ce3          	bne	a5,s2,80004692 <namex+0x122>
    8000469e:	bf8d                	j	80004610 <namex+0xa0>
    memmove(name, s, len);
    800046a0:	2601                	sext.w	a2,a2
    800046a2:	8556                	mv	a0,s5
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	6c0080e7          	jalr	1728(ra) # 80000d64 <memmove>
    name[len] = 0;
    800046ac:	9a56                	add	s4,s4,s5
    800046ae:	000a0023          	sb	zero,0(s4)
    800046b2:	bf9d                	j	80004628 <namex+0xb8>
  if(nameiparent){
    800046b4:	f20b03e3          	beqz	s6,800045da <namex+0x6a>
    iput(ip);
    800046b8:	854e                	mv	a0,s3
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	adc080e7          	jalr	-1316(ra) # 80004196 <iput>
    return 0;
    800046c2:	4981                	li	s3,0
    800046c4:	bf19                	j	800045da <namex+0x6a>
  if(*path == 0)
    800046c6:	d7fd                	beqz	a5,800046b4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800046c8:	0004c783          	lbu	a5,0(s1)
    800046cc:	85a6                	mv	a1,s1
    800046ce:	b7d1                	j	80004692 <namex+0x122>

00000000800046d0 <dirlink>:
{
    800046d0:	7139                	addi	sp,sp,-64
    800046d2:	fc06                	sd	ra,56(sp)
    800046d4:	f822                	sd	s0,48(sp)
    800046d6:	f426                	sd	s1,40(sp)
    800046d8:	f04a                	sd	s2,32(sp)
    800046da:	ec4e                	sd	s3,24(sp)
    800046dc:	e852                	sd	s4,16(sp)
    800046de:	0080                	addi	s0,sp,64
    800046e0:	892a                	mv	s2,a0
    800046e2:	8a2e                	mv	s4,a1
    800046e4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046e6:	4601                	li	a2,0
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	dd8080e7          	jalr	-552(ra) # 800044c0 <dirlookup>
    800046f0:	e93d                	bnez	a0,80004766 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046f2:	04c92483          	lw	s1,76(s2)
    800046f6:	c49d                	beqz	s1,80004724 <dirlink+0x54>
    800046f8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046fa:	4741                	li	a4,16
    800046fc:	86a6                	mv	a3,s1
    800046fe:	fc040613          	addi	a2,s0,-64
    80004702:	4581                	li	a1,0
    80004704:	854a                	mv	a0,s2
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	b8a080e7          	jalr	-1142(ra) # 80004290 <readi>
    8000470e:	47c1                	li	a5,16
    80004710:	06f51163          	bne	a0,a5,80004772 <dirlink+0xa2>
    if(de.inum == 0)
    80004714:	fc045783          	lhu	a5,-64(s0)
    80004718:	c791                	beqz	a5,80004724 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000471a:	24c1                	addiw	s1,s1,16
    8000471c:	04c92783          	lw	a5,76(s2)
    80004720:	fcf4ede3          	bltu	s1,a5,800046fa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004724:	4639                	li	a2,14
    80004726:	85d2                	mv	a1,s4
    80004728:	fc240513          	addi	a0,s0,-62
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	6ec080e7          	jalr	1772(ra) # 80000e18 <strncpy>
  de.inum = inum;
    80004734:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004738:	4741                	li	a4,16
    8000473a:	86a6                	mv	a3,s1
    8000473c:	fc040613          	addi	a2,s0,-64
    80004740:	4581                	li	a1,0
    80004742:	854a                	mv	a0,s2
    80004744:	00000097          	auipc	ra,0x0
    80004748:	c44080e7          	jalr	-956(ra) # 80004388 <writei>
    8000474c:	872a                	mv	a4,a0
    8000474e:	47c1                	li	a5,16
  return 0;
    80004750:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004752:	02f71863          	bne	a4,a5,80004782 <dirlink+0xb2>
}
    80004756:	70e2                	ld	ra,56(sp)
    80004758:	7442                	ld	s0,48(sp)
    8000475a:	74a2                	ld	s1,40(sp)
    8000475c:	7902                	ld	s2,32(sp)
    8000475e:	69e2                	ld	s3,24(sp)
    80004760:	6a42                	ld	s4,16(sp)
    80004762:	6121                	addi	sp,sp,64
    80004764:	8082                	ret
    iput(ip);
    80004766:	00000097          	auipc	ra,0x0
    8000476a:	a30080e7          	jalr	-1488(ra) # 80004196 <iput>
    return -1;
    8000476e:	557d                	li	a0,-1
    80004770:	b7dd                	j	80004756 <dirlink+0x86>
      panic("dirlink read");
    80004772:	00004517          	auipc	a0,0x4
    80004776:	0ee50513          	addi	a0,a0,238 # 80008860 <syscalls+0x1c8>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	dc4080e7          	jalr	-572(ra) # 8000053e <panic>
    panic("dirlink");
    80004782:	00004517          	auipc	a0,0x4
    80004786:	1ee50513          	addi	a0,a0,494 # 80008970 <syscalls+0x2d8>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	db4080e7          	jalr	-588(ra) # 8000053e <panic>

0000000080004792 <namei>:

struct inode*
namei(char *path)
{
    80004792:	1101                	addi	sp,sp,-32
    80004794:	ec06                	sd	ra,24(sp)
    80004796:	e822                	sd	s0,16(sp)
    80004798:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000479a:	fe040613          	addi	a2,s0,-32
    8000479e:	4581                	li	a1,0
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	dd0080e7          	jalr	-560(ra) # 80004570 <namex>
}
    800047a8:	60e2                	ld	ra,24(sp)
    800047aa:	6442                	ld	s0,16(sp)
    800047ac:	6105                	addi	sp,sp,32
    800047ae:	8082                	ret

00000000800047b0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800047b0:	1141                	addi	sp,sp,-16
    800047b2:	e406                	sd	ra,8(sp)
    800047b4:	e022                	sd	s0,0(sp)
    800047b6:	0800                	addi	s0,sp,16
    800047b8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800047ba:	4585                	li	a1,1
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	db4080e7          	jalr	-588(ra) # 80004570 <namex>
}
    800047c4:	60a2                	ld	ra,8(sp)
    800047c6:	6402                	ld	s0,0(sp)
    800047c8:	0141                	addi	sp,sp,16
    800047ca:	8082                	ret

00000000800047cc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047cc:	1101                	addi	sp,sp,-32
    800047ce:	ec06                	sd	ra,24(sp)
    800047d0:	e822                	sd	s0,16(sp)
    800047d2:	e426                	sd	s1,8(sp)
    800047d4:	e04a                	sd	s2,0(sp)
    800047d6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047d8:	00016917          	auipc	s2,0x16
    800047dc:	e6890913          	addi	s2,s2,-408 # 8001a640 <log>
    800047e0:	01892583          	lw	a1,24(s2)
    800047e4:	02892503          	lw	a0,40(s2)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	ff2080e7          	jalr	-14(ra) # 800037da <bread>
    800047f0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047f2:	02c92683          	lw	a3,44(s2)
    800047f6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047f8:	02d05763          	blez	a3,80004826 <write_head+0x5a>
    800047fc:	00016797          	auipc	a5,0x16
    80004800:	e7478793          	addi	a5,a5,-396 # 8001a670 <log+0x30>
    80004804:	05c50713          	addi	a4,a0,92
    80004808:	36fd                	addiw	a3,a3,-1
    8000480a:	1682                	slli	a3,a3,0x20
    8000480c:	9281                	srli	a3,a3,0x20
    8000480e:	068a                	slli	a3,a3,0x2
    80004810:	00016617          	auipc	a2,0x16
    80004814:	e6460613          	addi	a2,a2,-412 # 8001a674 <log+0x34>
    80004818:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000481a:	4390                	lw	a2,0(a5)
    8000481c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000481e:	0791                	addi	a5,a5,4
    80004820:	0711                	addi	a4,a4,4
    80004822:	fed79ce3          	bne	a5,a3,8000481a <write_head+0x4e>
  }
  bwrite(buf);
    80004826:	8526                	mv	a0,s1
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	0a4080e7          	jalr	164(ra) # 800038cc <bwrite>
  brelse(buf);
    80004830:	8526                	mv	a0,s1
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	0d8080e7          	jalr	216(ra) # 8000390a <brelse>
}
    8000483a:	60e2                	ld	ra,24(sp)
    8000483c:	6442                	ld	s0,16(sp)
    8000483e:	64a2                	ld	s1,8(sp)
    80004840:	6902                	ld	s2,0(sp)
    80004842:	6105                	addi	sp,sp,32
    80004844:	8082                	ret

0000000080004846 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004846:	00016797          	auipc	a5,0x16
    8000484a:	e267a783          	lw	a5,-474(a5) # 8001a66c <log+0x2c>
    8000484e:	0af05d63          	blez	a5,80004908 <install_trans+0xc2>
{
    80004852:	7139                	addi	sp,sp,-64
    80004854:	fc06                	sd	ra,56(sp)
    80004856:	f822                	sd	s0,48(sp)
    80004858:	f426                	sd	s1,40(sp)
    8000485a:	f04a                	sd	s2,32(sp)
    8000485c:	ec4e                	sd	s3,24(sp)
    8000485e:	e852                	sd	s4,16(sp)
    80004860:	e456                	sd	s5,8(sp)
    80004862:	e05a                	sd	s6,0(sp)
    80004864:	0080                	addi	s0,sp,64
    80004866:	8b2a                	mv	s6,a0
    80004868:	00016a97          	auipc	s5,0x16
    8000486c:	e08a8a93          	addi	s5,s5,-504 # 8001a670 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004870:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004872:	00016997          	auipc	s3,0x16
    80004876:	dce98993          	addi	s3,s3,-562 # 8001a640 <log>
    8000487a:	a035                	j	800048a6 <install_trans+0x60>
      bunpin(dbuf);
    8000487c:	8526                	mv	a0,s1
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	166080e7          	jalr	358(ra) # 800039e4 <bunpin>
    brelse(lbuf);
    80004886:	854a                	mv	a0,s2
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	082080e7          	jalr	130(ra) # 8000390a <brelse>
    brelse(dbuf);
    80004890:	8526                	mv	a0,s1
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	078080e7          	jalr	120(ra) # 8000390a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000489a:	2a05                	addiw	s4,s4,1
    8000489c:	0a91                	addi	s5,s5,4
    8000489e:	02c9a783          	lw	a5,44(s3)
    800048a2:	04fa5963          	bge	s4,a5,800048f4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048a6:	0189a583          	lw	a1,24(s3)
    800048aa:	014585bb          	addw	a1,a1,s4
    800048ae:	2585                	addiw	a1,a1,1
    800048b0:	0289a503          	lw	a0,40(s3)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	f26080e7          	jalr	-218(ra) # 800037da <bread>
    800048bc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800048be:	000aa583          	lw	a1,0(s5)
    800048c2:	0289a503          	lw	a0,40(s3)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	f14080e7          	jalr	-236(ra) # 800037da <bread>
    800048ce:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800048d0:	40000613          	li	a2,1024
    800048d4:	05890593          	addi	a1,s2,88
    800048d8:	05850513          	addi	a0,a0,88
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	488080e7          	jalr	1160(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    800048e4:	8526                	mv	a0,s1
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	fe6080e7          	jalr	-26(ra) # 800038cc <bwrite>
    if(recovering == 0)
    800048ee:	f80b1ce3          	bnez	s6,80004886 <install_trans+0x40>
    800048f2:	b769                	j	8000487c <install_trans+0x36>
}
    800048f4:	70e2                	ld	ra,56(sp)
    800048f6:	7442                	ld	s0,48(sp)
    800048f8:	74a2                	ld	s1,40(sp)
    800048fa:	7902                	ld	s2,32(sp)
    800048fc:	69e2                	ld	s3,24(sp)
    800048fe:	6a42                	ld	s4,16(sp)
    80004900:	6aa2                	ld	s5,8(sp)
    80004902:	6b02                	ld	s6,0(sp)
    80004904:	6121                	addi	sp,sp,64
    80004906:	8082                	ret
    80004908:	8082                	ret

000000008000490a <initlog>:
{
    8000490a:	7179                	addi	sp,sp,-48
    8000490c:	f406                	sd	ra,40(sp)
    8000490e:	f022                	sd	s0,32(sp)
    80004910:	ec26                	sd	s1,24(sp)
    80004912:	e84a                	sd	s2,16(sp)
    80004914:	e44e                	sd	s3,8(sp)
    80004916:	1800                	addi	s0,sp,48
    80004918:	892a                	mv	s2,a0
    8000491a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000491c:	00016497          	auipc	s1,0x16
    80004920:	d2448493          	addi	s1,s1,-732 # 8001a640 <log>
    80004924:	00004597          	auipc	a1,0x4
    80004928:	f4c58593          	addi	a1,a1,-180 # 80008870 <syscalls+0x1d8>
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	226080e7          	jalr	550(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004936:	0149a583          	lw	a1,20(s3)
    8000493a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000493c:	0109a783          	lw	a5,16(s3)
    80004940:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004942:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004946:	854a                	mv	a0,s2
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	e92080e7          	jalr	-366(ra) # 800037da <bread>
  log.lh.n = lh->n;
    80004950:	4d3c                	lw	a5,88(a0)
    80004952:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004954:	02f05563          	blez	a5,8000497e <initlog+0x74>
    80004958:	05c50713          	addi	a4,a0,92
    8000495c:	00016697          	auipc	a3,0x16
    80004960:	d1468693          	addi	a3,a3,-748 # 8001a670 <log+0x30>
    80004964:	37fd                	addiw	a5,a5,-1
    80004966:	1782                	slli	a5,a5,0x20
    80004968:	9381                	srli	a5,a5,0x20
    8000496a:	078a                	slli	a5,a5,0x2
    8000496c:	06050613          	addi	a2,a0,96
    80004970:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004972:	4310                	lw	a2,0(a4)
    80004974:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004976:	0711                	addi	a4,a4,4
    80004978:	0691                	addi	a3,a3,4
    8000497a:	fef71ce3          	bne	a4,a5,80004972 <initlog+0x68>
  brelse(buf);
    8000497e:	fffff097          	auipc	ra,0xfffff
    80004982:	f8c080e7          	jalr	-116(ra) # 8000390a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004986:	4505                	li	a0,1
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	ebe080e7          	jalr	-322(ra) # 80004846 <install_trans>
  log.lh.n = 0;
    80004990:	00016797          	auipc	a5,0x16
    80004994:	cc07ae23          	sw	zero,-804(a5) # 8001a66c <log+0x2c>
  write_head(); // clear the log
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	e34080e7          	jalr	-460(ra) # 800047cc <write_head>
}
    800049a0:	70a2                	ld	ra,40(sp)
    800049a2:	7402                	ld	s0,32(sp)
    800049a4:	64e2                	ld	s1,24(sp)
    800049a6:	6942                	ld	s2,16(sp)
    800049a8:	69a2                	ld	s3,8(sp)
    800049aa:	6145                	addi	sp,sp,48
    800049ac:	8082                	ret

00000000800049ae <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800049ae:	1101                	addi	sp,sp,-32
    800049b0:	ec06                	sd	ra,24(sp)
    800049b2:	e822                	sd	s0,16(sp)
    800049b4:	e426                	sd	s1,8(sp)
    800049b6:	e04a                	sd	s2,0(sp)
    800049b8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800049ba:	00016517          	auipc	a0,0x16
    800049be:	c8650513          	addi	a0,a0,-890 # 8001a640 <log>
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	222080e7          	jalr	546(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800049ca:	00016497          	auipc	s1,0x16
    800049ce:	c7648493          	addi	s1,s1,-906 # 8001a640 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049d2:	4979                	li	s2,30
    800049d4:	a039                	j	800049e2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800049d6:	85a6                	mv	a1,s1
    800049d8:	8526                	mv	a0,s1
    800049da:	ffffe097          	auipc	ra,0xffffe
    800049de:	e16080e7          	jalr	-490(ra) # 800027f0 <sleep>
    if(log.committing){
    800049e2:	50dc                	lw	a5,36(s1)
    800049e4:	fbed                	bnez	a5,800049d6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049e6:	509c                	lw	a5,32(s1)
    800049e8:	0017871b          	addiw	a4,a5,1
    800049ec:	0007069b          	sext.w	a3,a4
    800049f0:	0027179b          	slliw	a5,a4,0x2
    800049f4:	9fb9                	addw	a5,a5,a4
    800049f6:	0017979b          	slliw	a5,a5,0x1
    800049fa:	54d8                	lw	a4,44(s1)
    800049fc:	9fb9                	addw	a5,a5,a4
    800049fe:	00f95963          	bge	s2,a5,80004a10 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a02:	85a6                	mv	a1,s1
    80004a04:	8526                	mv	a0,s1
    80004a06:	ffffe097          	auipc	ra,0xffffe
    80004a0a:	dea080e7          	jalr	-534(ra) # 800027f0 <sleep>
    80004a0e:	bfd1                	j	800049e2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a10:	00016517          	auipc	a0,0x16
    80004a14:	c3050513          	addi	a0,a0,-976 # 8001a640 <log>
    80004a18:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	290080e7          	jalr	656(ra) # 80000caa <release>
      break;
    }
  }
}
    80004a22:	60e2                	ld	ra,24(sp)
    80004a24:	6442                	ld	s0,16(sp)
    80004a26:	64a2                	ld	s1,8(sp)
    80004a28:	6902                	ld	s2,0(sp)
    80004a2a:	6105                	addi	sp,sp,32
    80004a2c:	8082                	ret

0000000080004a2e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a2e:	7139                	addi	sp,sp,-64
    80004a30:	fc06                	sd	ra,56(sp)
    80004a32:	f822                	sd	s0,48(sp)
    80004a34:	f426                	sd	s1,40(sp)
    80004a36:	f04a                	sd	s2,32(sp)
    80004a38:	ec4e                	sd	s3,24(sp)
    80004a3a:	e852                	sd	s4,16(sp)
    80004a3c:	e456                	sd	s5,8(sp)
    80004a3e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a40:	00016497          	auipc	s1,0x16
    80004a44:	c0048493          	addi	s1,s1,-1024 # 8001a640 <log>
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	19a080e7          	jalr	410(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004a52:	509c                	lw	a5,32(s1)
    80004a54:	37fd                	addiw	a5,a5,-1
    80004a56:	0007891b          	sext.w	s2,a5
    80004a5a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a5c:	50dc                	lw	a5,36(s1)
    80004a5e:	efb9                	bnez	a5,80004abc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a60:	06091663          	bnez	s2,80004acc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004a64:	00016497          	auipc	s1,0x16
    80004a68:	bdc48493          	addi	s1,s1,-1060 # 8001a640 <log>
    80004a6c:	4785                	li	a5,1
    80004a6e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	238080e7          	jalr	568(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a7a:	54dc                	lw	a5,44(s1)
    80004a7c:	06f04763          	bgtz	a5,80004aea <end_op+0xbc>
    acquire(&log.lock);
    80004a80:	00016497          	auipc	s1,0x16
    80004a84:	bc048493          	addi	s1,s1,-1088 # 8001a640 <log>
    80004a88:	8526                	mv	a0,s1
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	15a080e7          	jalr	346(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004a92:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffe097          	auipc	ra,0xffffe
    80004a9c:	f56080e7          	jalr	-170(ra) # 800029ee <wakeup>
    release(&log.lock);
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	208080e7          	jalr	520(ra) # 80000caa <release>
}
    80004aaa:	70e2                	ld	ra,56(sp)
    80004aac:	7442                	ld	s0,48(sp)
    80004aae:	74a2                	ld	s1,40(sp)
    80004ab0:	7902                	ld	s2,32(sp)
    80004ab2:	69e2                	ld	s3,24(sp)
    80004ab4:	6a42                	ld	s4,16(sp)
    80004ab6:	6aa2                	ld	s5,8(sp)
    80004ab8:	6121                	addi	sp,sp,64
    80004aba:	8082                	ret
    panic("log.committing");
    80004abc:	00004517          	auipc	a0,0x4
    80004ac0:	dbc50513          	addi	a0,a0,-580 # 80008878 <syscalls+0x1e0>
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	a7a080e7          	jalr	-1414(ra) # 8000053e <panic>
    wakeup(&log);
    80004acc:	00016497          	auipc	s1,0x16
    80004ad0:	b7448493          	addi	s1,s1,-1164 # 8001a640 <log>
    80004ad4:	8526                	mv	a0,s1
    80004ad6:	ffffe097          	auipc	ra,0xffffe
    80004ada:	f18080e7          	jalr	-232(ra) # 800029ee <wakeup>
  release(&log.lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	1ca080e7          	jalr	458(ra) # 80000caa <release>
  if(do_commit){
    80004ae8:	b7c9                	j	80004aaa <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004aea:	00016a97          	auipc	s5,0x16
    80004aee:	b86a8a93          	addi	s5,s5,-1146 # 8001a670 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004af2:	00016a17          	auipc	s4,0x16
    80004af6:	b4ea0a13          	addi	s4,s4,-1202 # 8001a640 <log>
    80004afa:	018a2583          	lw	a1,24(s4)
    80004afe:	012585bb          	addw	a1,a1,s2
    80004b02:	2585                	addiw	a1,a1,1
    80004b04:	028a2503          	lw	a0,40(s4)
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	cd2080e7          	jalr	-814(ra) # 800037da <bread>
    80004b10:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b12:	000aa583          	lw	a1,0(s5)
    80004b16:	028a2503          	lw	a0,40(s4)
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	cc0080e7          	jalr	-832(ra) # 800037da <bread>
    80004b22:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b24:	40000613          	li	a2,1024
    80004b28:	05850593          	addi	a1,a0,88
    80004b2c:	05848513          	addi	a0,s1,88
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	234080e7          	jalr	564(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    80004b38:	8526                	mv	a0,s1
    80004b3a:	fffff097          	auipc	ra,0xfffff
    80004b3e:	d92080e7          	jalr	-622(ra) # 800038cc <bwrite>
    brelse(from);
    80004b42:	854e                	mv	a0,s3
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	dc6080e7          	jalr	-570(ra) # 8000390a <brelse>
    brelse(to);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	dbc080e7          	jalr	-580(ra) # 8000390a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b56:	2905                	addiw	s2,s2,1
    80004b58:	0a91                	addi	s5,s5,4
    80004b5a:	02ca2783          	lw	a5,44(s4)
    80004b5e:	f8f94ee3          	blt	s2,a5,80004afa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	c6a080e7          	jalr	-918(ra) # 800047cc <write_head>
    install_trans(0); // Now install writes to home locations
    80004b6a:	4501                	li	a0,0
    80004b6c:	00000097          	auipc	ra,0x0
    80004b70:	cda080e7          	jalr	-806(ra) # 80004846 <install_trans>
    log.lh.n = 0;
    80004b74:	00016797          	auipc	a5,0x16
    80004b78:	ae07ac23          	sw	zero,-1288(a5) # 8001a66c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b7c:	00000097          	auipc	ra,0x0
    80004b80:	c50080e7          	jalr	-944(ra) # 800047cc <write_head>
    80004b84:	bdf5                	j	80004a80 <end_op+0x52>

0000000080004b86 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b86:	1101                	addi	sp,sp,-32
    80004b88:	ec06                	sd	ra,24(sp)
    80004b8a:	e822                	sd	s0,16(sp)
    80004b8c:	e426                	sd	s1,8(sp)
    80004b8e:	e04a                	sd	s2,0(sp)
    80004b90:	1000                	addi	s0,sp,32
    80004b92:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b94:	00016917          	auipc	s2,0x16
    80004b98:	aac90913          	addi	s2,s2,-1364 # 8001a640 <log>
    80004b9c:	854a                	mv	a0,s2
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	046080e7          	jalr	70(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ba6:	02c92603          	lw	a2,44(s2)
    80004baa:	47f5                	li	a5,29
    80004bac:	06c7c563          	blt	a5,a2,80004c16 <log_write+0x90>
    80004bb0:	00016797          	auipc	a5,0x16
    80004bb4:	aac7a783          	lw	a5,-1364(a5) # 8001a65c <log+0x1c>
    80004bb8:	37fd                	addiw	a5,a5,-1
    80004bba:	04f65e63          	bge	a2,a5,80004c16 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004bbe:	00016797          	auipc	a5,0x16
    80004bc2:	aa27a783          	lw	a5,-1374(a5) # 8001a660 <log+0x20>
    80004bc6:	06f05063          	blez	a5,80004c26 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004bca:	4781                	li	a5,0
    80004bcc:	06c05563          	blez	a2,80004c36 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bd0:	44cc                	lw	a1,12(s1)
    80004bd2:	00016717          	auipc	a4,0x16
    80004bd6:	a9e70713          	addi	a4,a4,-1378 # 8001a670 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004bda:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bdc:	4314                	lw	a3,0(a4)
    80004bde:	04b68c63          	beq	a3,a1,80004c36 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004be2:	2785                	addiw	a5,a5,1
    80004be4:	0711                	addi	a4,a4,4
    80004be6:	fef61be3          	bne	a2,a5,80004bdc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004bea:	0621                	addi	a2,a2,8
    80004bec:	060a                	slli	a2,a2,0x2
    80004bee:	00016797          	auipc	a5,0x16
    80004bf2:	a5278793          	addi	a5,a5,-1454 # 8001a640 <log>
    80004bf6:	963e                	add	a2,a2,a5
    80004bf8:	44dc                	lw	a5,12(s1)
    80004bfa:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	fffff097          	auipc	ra,0xfffff
    80004c02:	daa080e7          	jalr	-598(ra) # 800039a8 <bpin>
    log.lh.n++;
    80004c06:	00016717          	auipc	a4,0x16
    80004c0a:	a3a70713          	addi	a4,a4,-1478 # 8001a640 <log>
    80004c0e:	575c                	lw	a5,44(a4)
    80004c10:	2785                	addiw	a5,a5,1
    80004c12:	d75c                	sw	a5,44(a4)
    80004c14:	a835                	j	80004c50 <log_write+0xca>
    panic("too big a transaction");
    80004c16:	00004517          	auipc	a0,0x4
    80004c1a:	c7250513          	addi	a0,a0,-910 # 80008888 <syscalls+0x1f0>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c26:	00004517          	auipc	a0,0x4
    80004c2a:	c7a50513          	addi	a0,a0,-902 # 800088a0 <syscalls+0x208>
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	910080e7          	jalr	-1776(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004c36:	00878713          	addi	a4,a5,8
    80004c3a:	00271693          	slli	a3,a4,0x2
    80004c3e:	00016717          	auipc	a4,0x16
    80004c42:	a0270713          	addi	a4,a4,-1534 # 8001a640 <log>
    80004c46:	9736                	add	a4,a4,a3
    80004c48:	44d4                	lw	a3,12(s1)
    80004c4a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c4c:	faf608e3          	beq	a2,a5,80004bfc <log_write+0x76>
  }
  release(&log.lock);
    80004c50:	00016517          	auipc	a0,0x16
    80004c54:	9f050513          	addi	a0,a0,-1552 # 8001a640 <log>
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	052080e7          	jalr	82(ra) # 80000caa <release>
}
    80004c60:	60e2                	ld	ra,24(sp)
    80004c62:	6442                	ld	s0,16(sp)
    80004c64:	64a2                	ld	s1,8(sp)
    80004c66:	6902                	ld	s2,0(sp)
    80004c68:	6105                	addi	sp,sp,32
    80004c6a:	8082                	ret

0000000080004c6c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c6c:	1101                	addi	sp,sp,-32
    80004c6e:	ec06                	sd	ra,24(sp)
    80004c70:	e822                	sd	s0,16(sp)
    80004c72:	e426                	sd	s1,8(sp)
    80004c74:	e04a                	sd	s2,0(sp)
    80004c76:	1000                	addi	s0,sp,32
    80004c78:	84aa                	mv	s1,a0
    80004c7a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c7c:	00004597          	auipc	a1,0x4
    80004c80:	c4458593          	addi	a1,a1,-956 # 800088c0 <syscalls+0x228>
    80004c84:	0521                	addi	a0,a0,8
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	ece080e7          	jalr	-306(ra) # 80000b54 <initlock>
  lk->name = name;
    80004c8e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c92:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c96:	0204a423          	sw	zero,40(s1)
}
    80004c9a:	60e2                	ld	ra,24(sp)
    80004c9c:	6442                	ld	s0,16(sp)
    80004c9e:	64a2                	ld	s1,8(sp)
    80004ca0:	6902                	ld	s2,0(sp)
    80004ca2:	6105                	addi	sp,sp,32
    80004ca4:	8082                	ret

0000000080004ca6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ca6:	1101                	addi	sp,sp,-32
    80004ca8:	ec06                	sd	ra,24(sp)
    80004caa:	e822                	sd	s0,16(sp)
    80004cac:	e426                	sd	s1,8(sp)
    80004cae:	e04a                	sd	s2,0(sp)
    80004cb0:	1000                	addi	s0,sp,32
    80004cb2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cb4:	00850913          	addi	s2,a0,8
    80004cb8:	854a                	mv	a0,s2
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	f2a080e7          	jalr	-214(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004cc2:	409c                	lw	a5,0(s1)
    80004cc4:	cb89                	beqz	a5,80004cd6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004cc6:	85ca                	mv	a1,s2
    80004cc8:	8526                	mv	a0,s1
    80004cca:	ffffe097          	auipc	ra,0xffffe
    80004cce:	b26080e7          	jalr	-1242(ra) # 800027f0 <sleep>
  while (lk->locked) {
    80004cd2:	409c                	lw	a5,0(s1)
    80004cd4:	fbed                	bnez	a5,80004cc6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004cd6:	4785                	li	a5,1
    80004cd8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	168080e7          	jalr	360(ra) # 80001e42 <myproc>
    80004ce2:	591c                	lw	a5,48(a0)
    80004ce4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ce6:	854a                	mv	a0,s2
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	fc2080e7          	jalr	-62(ra) # 80000caa <release>
}
    80004cf0:	60e2                	ld	ra,24(sp)
    80004cf2:	6442                	ld	s0,16(sp)
    80004cf4:	64a2                	ld	s1,8(sp)
    80004cf6:	6902                	ld	s2,0(sp)
    80004cf8:	6105                	addi	sp,sp,32
    80004cfa:	8082                	ret

0000000080004cfc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004cfc:	1101                	addi	sp,sp,-32
    80004cfe:	ec06                	sd	ra,24(sp)
    80004d00:	e822                	sd	s0,16(sp)
    80004d02:	e426                	sd	s1,8(sp)
    80004d04:	e04a                	sd	s2,0(sp)
    80004d06:	1000                	addi	s0,sp,32
    80004d08:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d0a:	00850913          	addi	s2,a0,8
    80004d0e:	854a                	mv	a0,s2
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	ed4080e7          	jalr	-300(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004d18:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d1c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d20:	8526                	mv	a0,s1
    80004d22:	ffffe097          	auipc	ra,0xffffe
    80004d26:	ccc080e7          	jalr	-820(ra) # 800029ee <wakeup>
  release(&lk->lk);
    80004d2a:	854a                	mv	a0,s2
    80004d2c:	ffffc097          	auipc	ra,0xffffc
    80004d30:	f7e080e7          	jalr	-130(ra) # 80000caa <release>
}
    80004d34:	60e2                	ld	ra,24(sp)
    80004d36:	6442                	ld	s0,16(sp)
    80004d38:	64a2                	ld	s1,8(sp)
    80004d3a:	6902                	ld	s2,0(sp)
    80004d3c:	6105                	addi	sp,sp,32
    80004d3e:	8082                	ret

0000000080004d40 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d40:	7179                	addi	sp,sp,-48
    80004d42:	f406                	sd	ra,40(sp)
    80004d44:	f022                	sd	s0,32(sp)
    80004d46:	ec26                	sd	s1,24(sp)
    80004d48:	e84a                	sd	s2,16(sp)
    80004d4a:	e44e                	sd	s3,8(sp)
    80004d4c:	1800                	addi	s0,sp,48
    80004d4e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d50:	00850913          	addi	s2,a0,8
    80004d54:	854a                	mv	a0,s2
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	e8e080e7          	jalr	-370(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d5e:	409c                	lw	a5,0(s1)
    80004d60:	ef99                	bnez	a5,80004d7e <holdingsleep+0x3e>
    80004d62:	4481                	li	s1,0
  release(&lk->lk);
    80004d64:	854a                	mv	a0,s2
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	f44080e7          	jalr	-188(ra) # 80000caa <release>
  return r;
}
    80004d6e:	8526                	mv	a0,s1
    80004d70:	70a2                	ld	ra,40(sp)
    80004d72:	7402                	ld	s0,32(sp)
    80004d74:	64e2                	ld	s1,24(sp)
    80004d76:	6942                	ld	s2,16(sp)
    80004d78:	69a2                	ld	s3,8(sp)
    80004d7a:	6145                	addi	sp,sp,48
    80004d7c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d7e:	0284a983          	lw	s3,40(s1)
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	0c0080e7          	jalr	192(ra) # 80001e42 <myproc>
    80004d8a:	5904                	lw	s1,48(a0)
    80004d8c:	413484b3          	sub	s1,s1,s3
    80004d90:	0014b493          	seqz	s1,s1
    80004d94:	bfc1                	j	80004d64 <holdingsleep+0x24>

0000000080004d96 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d96:	1141                	addi	sp,sp,-16
    80004d98:	e406                	sd	ra,8(sp)
    80004d9a:	e022                	sd	s0,0(sp)
    80004d9c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d9e:	00004597          	auipc	a1,0x4
    80004da2:	b3258593          	addi	a1,a1,-1230 # 800088d0 <syscalls+0x238>
    80004da6:	00016517          	auipc	a0,0x16
    80004daa:	9e250513          	addi	a0,a0,-1566 # 8001a788 <ftable>
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	da6080e7          	jalr	-602(ra) # 80000b54 <initlock>
}
    80004db6:	60a2                	ld	ra,8(sp)
    80004db8:	6402                	ld	s0,0(sp)
    80004dba:	0141                	addi	sp,sp,16
    80004dbc:	8082                	ret

0000000080004dbe <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004dbe:	1101                	addi	sp,sp,-32
    80004dc0:	ec06                	sd	ra,24(sp)
    80004dc2:	e822                	sd	s0,16(sp)
    80004dc4:	e426                	sd	s1,8(sp)
    80004dc6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004dc8:	00016517          	auipc	a0,0x16
    80004dcc:	9c050513          	addi	a0,a0,-1600 # 8001a788 <ftable>
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	e14080e7          	jalr	-492(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dd8:	00016497          	auipc	s1,0x16
    80004ddc:	9c848493          	addi	s1,s1,-1592 # 8001a7a0 <ftable+0x18>
    80004de0:	00017717          	auipc	a4,0x17
    80004de4:	96070713          	addi	a4,a4,-1696 # 8001b740 <ftable+0xfb8>
    if(f->ref == 0){
    80004de8:	40dc                	lw	a5,4(s1)
    80004dea:	cf99                	beqz	a5,80004e08 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dec:	02848493          	addi	s1,s1,40
    80004df0:	fee49ce3          	bne	s1,a4,80004de8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004df4:	00016517          	auipc	a0,0x16
    80004df8:	99450513          	addi	a0,a0,-1644 # 8001a788 <ftable>
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	eae080e7          	jalr	-338(ra) # 80000caa <release>
  return 0;
    80004e04:	4481                	li	s1,0
    80004e06:	a819                	j	80004e1c <filealloc+0x5e>
      f->ref = 1;
    80004e08:	4785                	li	a5,1
    80004e0a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e0c:	00016517          	auipc	a0,0x16
    80004e10:	97c50513          	addi	a0,a0,-1668 # 8001a788 <ftable>
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	e96080e7          	jalr	-362(ra) # 80000caa <release>
}
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	60e2                	ld	ra,24(sp)
    80004e20:	6442                	ld	s0,16(sp)
    80004e22:	64a2                	ld	s1,8(sp)
    80004e24:	6105                	addi	sp,sp,32
    80004e26:	8082                	ret

0000000080004e28 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e28:	1101                	addi	sp,sp,-32
    80004e2a:	ec06                	sd	ra,24(sp)
    80004e2c:	e822                	sd	s0,16(sp)
    80004e2e:	e426                	sd	s1,8(sp)
    80004e30:	1000                	addi	s0,sp,32
    80004e32:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e34:	00016517          	auipc	a0,0x16
    80004e38:	95450513          	addi	a0,a0,-1708 # 8001a788 <ftable>
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	da8080e7          	jalr	-600(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e44:	40dc                	lw	a5,4(s1)
    80004e46:	02f05263          	blez	a5,80004e6a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e4a:	2785                	addiw	a5,a5,1
    80004e4c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e4e:	00016517          	auipc	a0,0x16
    80004e52:	93a50513          	addi	a0,a0,-1734 # 8001a788 <ftable>
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	e54080e7          	jalr	-428(ra) # 80000caa <release>
  return f;
}
    80004e5e:	8526                	mv	a0,s1
    80004e60:	60e2                	ld	ra,24(sp)
    80004e62:	6442                	ld	s0,16(sp)
    80004e64:	64a2                	ld	s1,8(sp)
    80004e66:	6105                	addi	sp,sp,32
    80004e68:	8082                	ret
    panic("filedup");
    80004e6a:	00004517          	auipc	a0,0x4
    80004e6e:	a6e50513          	addi	a0,a0,-1426 # 800088d8 <syscalls+0x240>
    80004e72:	ffffb097          	auipc	ra,0xffffb
    80004e76:	6cc080e7          	jalr	1740(ra) # 8000053e <panic>

0000000080004e7a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e7a:	7139                	addi	sp,sp,-64
    80004e7c:	fc06                	sd	ra,56(sp)
    80004e7e:	f822                	sd	s0,48(sp)
    80004e80:	f426                	sd	s1,40(sp)
    80004e82:	f04a                	sd	s2,32(sp)
    80004e84:	ec4e                	sd	s3,24(sp)
    80004e86:	e852                	sd	s4,16(sp)
    80004e88:	e456                	sd	s5,8(sp)
    80004e8a:	0080                	addi	s0,sp,64
    80004e8c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e8e:	00016517          	auipc	a0,0x16
    80004e92:	8fa50513          	addi	a0,a0,-1798 # 8001a788 <ftable>
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	d4e080e7          	jalr	-690(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e9e:	40dc                	lw	a5,4(s1)
    80004ea0:	06f05163          	blez	a5,80004f02 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ea4:	37fd                	addiw	a5,a5,-1
    80004ea6:	0007871b          	sext.w	a4,a5
    80004eaa:	c0dc                	sw	a5,4(s1)
    80004eac:	06e04363          	bgtz	a4,80004f12 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004eb0:	0004a903          	lw	s2,0(s1)
    80004eb4:	0094ca83          	lbu	s5,9(s1)
    80004eb8:	0104ba03          	ld	s4,16(s1)
    80004ebc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ec0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ec4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ec8:	00016517          	auipc	a0,0x16
    80004ecc:	8c050513          	addi	a0,a0,-1856 # 8001a788 <ftable>
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	dda080e7          	jalr	-550(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004ed8:	4785                	li	a5,1
    80004eda:	04f90d63          	beq	s2,a5,80004f34 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ede:	3979                	addiw	s2,s2,-2
    80004ee0:	4785                	li	a5,1
    80004ee2:	0527e063          	bltu	a5,s2,80004f22 <fileclose+0xa8>
    begin_op();
    80004ee6:	00000097          	auipc	ra,0x0
    80004eea:	ac8080e7          	jalr	-1336(ra) # 800049ae <begin_op>
    iput(ff.ip);
    80004eee:	854e                	mv	a0,s3
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	2a6080e7          	jalr	678(ra) # 80004196 <iput>
    end_op();
    80004ef8:	00000097          	auipc	ra,0x0
    80004efc:	b36080e7          	jalr	-1226(ra) # 80004a2e <end_op>
    80004f00:	a00d                	j	80004f22 <fileclose+0xa8>
    panic("fileclose");
    80004f02:	00004517          	auipc	a0,0x4
    80004f06:	9de50513          	addi	a0,a0,-1570 # 800088e0 <syscalls+0x248>
    80004f0a:	ffffb097          	auipc	ra,0xffffb
    80004f0e:	634080e7          	jalr	1588(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004f12:	00016517          	auipc	a0,0x16
    80004f16:	87650513          	addi	a0,a0,-1930 # 8001a788 <ftable>
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	d90080e7          	jalr	-624(ra) # 80000caa <release>
  }
}
    80004f22:	70e2                	ld	ra,56(sp)
    80004f24:	7442                	ld	s0,48(sp)
    80004f26:	74a2                	ld	s1,40(sp)
    80004f28:	7902                	ld	s2,32(sp)
    80004f2a:	69e2                	ld	s3,24(sp)
    80004f2c:	6a42                	ld	s4,16(sp)
    80004f2e:	6aa2                	ld	s5,8(sp)
    80004f30:	6121                	addi	sp,sp,64
    80004f32:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f34:	85d6                	mv	a1,s5
    80004f36:	8552                	mv	a0,s4
    80004f38:	00000097          	auipc	ra,0x0
    80004f3c:	34c080e7          	jalr	844(ra) # 80005284 <pipeclose>
    80004f40:	b7cd                	j	80004f22 <fileclose+0xa8>

0000000080004f42 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f42:	715d                	addi	sp,sp,-80
    80004f44:	e486                	sd	ra,72(sp)
    80004f46:	e0a2                	sd	s0,64(sp)
    80004f48:	fc26                	sd	s1,56(sp)
    80004f4a:	f84a                	sd	s2,48(sp)
    80004f4c:	f44e                	sd	s3,40(sp)
    80004f4e:	0880                	addi	s0,sp,80
    80004f50:	84aa                	mv	s1,a0
    80004f52:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f54:	ffffd097          	auipc	ra,0xffffd
    80004f58:	eee080e7          	jalr	-274(ra) # 80001e42 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f5c:	409c                	lw	a5,0(s1)
    80004f5e:	37f9                	addiw	a5,a5,-2
    80004f60:	4705                	li	a4,1
    80004f62:	04f76763          	bltu	a4,a5,80004fb0 <filestat+0x6e>
    80004f66:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f68:	6c88                	ld	a0,24(s1)
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	072080e7          	jalr	114(ra) # 80003fdc <ilock>
    stati(f->ip, &st);
    80004f72:	fb840593          	addi	a1,s0,-72
    80004f76:	6c88                	ld	a0,24(s1)
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	2ee080e7          	jalr	750(ra) # 80004266 <stati>
    iunlock(f->ip);
    80004f80:	6c88                	ld	a0,24(s1)
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	11c080e7          	jalr	284(ra) # 8000409e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f8a:	46e1                	li	a3,24
    80004f8c:	fb840613          	addi	a2,s0,-72
    80004f90:	85ce                	mv	a1,s3
    80004f92:	07093503          	ld	a0,112(s2)
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	700080e7          	jalr	1792(ra) # 80001696 <copyout>
    80004f9e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004fa2:	60a6                	ld	ra,72(sp)
    80004fa4:	6406                	ld	s0,64(sp)
    80004fa6:	74e2                	ld	s1,56(sp)
    80004fa8:	7942                	ld	s2,48(sp)
    80004faa:	79a2                	ld	s3,40(sp)
    80004fac:	6161                	addi	sp,sp,80
    80004fae:	8082                	ret
  return -1;
    80004fb0:	557d                	li	a0,-1
    80004fb2:	bfc5                	j	80004fa2 <filestat+0x60>

0000000080004fb4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004fb4:	7179                	addi	sp,sp,-48
    80004fb6:	f406                	sd	ra,40(sp)
    80004fb8:	f022                	sd	s0,32(sp)
    80004fba:	ec26                	sd	s1,24(sp)
    80004fbc:	e84a                	sd	s2,16(sp)
    80004fbe:	e44e                	sd	s3,8(sp)
    80004fc0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004fc2:	00854783          	lbu	a5,8(a0)
    80004fc6:	c3d5                	beqz	a5,8000506a <fileread+0xb6>
    80004fc8:	84aa                	mv	s1,a0
    80004fca:	89ae                	mv	s3,a1
    80004fcc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fce:	411c                	lw	a5,0(a0)
    80004fd0:	4705                	li	a4,1
    80004fd2:	04e78963          	beq	a5,a4,80005024 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fd6:	470d                	li	a4,3
    80004fd8:	04e78d63          	beq	a5,a4,80005032 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fdc:	4709                	li	a4,2
    80004fde:	06e79e63          	bne	a5,a4,8000505a <fileread+0xa6>
    ilock(f->ip);
    80004fe2:	6d08                	ld	a0,24(a0)
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	ff8080e7          	jalr	-8(ra) # 80003fdc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004fec:	874a                	mv	a4,s2
    80004fee:	5094                	lw	a3,32(s1)
    80004ff0:	864e                	mv	a2,s3
    80004ff2:	4585                	li	a1,1
    80004ff4:	6c88                	ld	a0,24(s1)
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	29a080e7          	jalr	666(ra) # 80004290 <readi>
    80004ffe:	892a                	mv	s2,a0
    80005000:	00a05563          	blez	a0,8000500a <fileread+0x56>
      f->off += r;
    80005004:	509c                	lw	a5,32(s1)
    80005006:	9fa9                	addw	a5,a5,a0
    80005008:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000500a:	6c88                	ld	a0,24(s1)
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	092080e7          	jalr	146(ra) # 8000409e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005014:	854a                	mv	a0,s2
    80005016:	70a2                	ld	ra,40(sp)
    80005018:	7402                	ld	s0,32(sp)
    8000501a:	64e2                	ld	s1,24(sp)
    8000501c:	6942                	ld	s2,16(sp)
    8000501e:	69a2                	ld	s3,8(sp)
    80005020:	6145                	addi	sp,sp,48
    80005022:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005024:	6908                	ld	a0,16(a0)
    80005026:	00000097          	auipc	ra,0x0
    8000502a:	3c8080e7          	jalr	968(ra) # 800053ee <piperead>
    8000502e:	892a                	mv	s2,a0
    80005030:	b7d5                	j	80005014 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005032:	02451783          	lh	a5,36(a0)
    80005036:	03079693          	slli	a3,a5,0x30
    8000503a:	92c1                	srli	a3,a3,0x30
    8000503c:	4725                	li	a4,9
    8000503e:	02d76863          	bltu	a4,a3,8000506e <fileread+0xba>
    80005042:	0792                	slli	a5,a5,0x4
    80005044:	00015717          	auipc	a4,0x15
    80005048:	6a470713          	addi	a4,a4,1700 # 8001a6e8 <devsw>
    8000504c:	97ba                	add	a5,a5,a4
    8000504e:	639c                	ld	a5,0(a5)
    80005050:	c38d                	beqz	a5,80005072 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005052:	4505                	li	a0,1
    80005054:	9782                	jalr	a5
    80005056:	892a                	mv	s2,a0
    80005058:	bf75                	j	80005014 <fileread+0x60>
    panic("fileread");
    8000505a:	00004517          	auipc	a0,0x4
    8000505e:	89650513          	addi	a0,a0,-1898 # 800088f0 <syscalls+0x258>
    80005062:	ffffb097          	auipc	ra,0xffffb
    80005066:	4dc080e7          	jalr	1244(ra) # 8000053e <panic>
    return -1;
    8000506a:	597d                	li	s2,-1
    8000506c:	b765                	j	80005014 <fileread+0x60>
      return -1;
    8000506e:	597d                	li	s2,-1
    80005070:	b755                	j	80005014 <fileread+0x60>
    80005072:	597d                	li	s2,-1
    80005074:	b745                	j	80005014 <fileread+0x60>

0000000080005076 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005076:	715d                	addi	sp,sp,-80
    80005078:	e486                	sd	ra,72(sp)
    8000507a:	e0a2                	sd	s0,64(sp)
    8000507c:	fc26                	sd	s1,56(sp)
    8000507e:	f84a                	sd	s2,48(sp)
    80005080:	f44e                	sd	s3,40(sp)
    80005082:	f052                	sd	s4,32(sp)
    80005084:	ec56                	sd	s5,24(sp)
    80005086:	e85a                	sd	s6,16(sp)
    80005088:	e45e                	sd	s7,8(sp)
    8000508a:	e062                	sd	s8,0(sp)
    8000508c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000508e:	00954783          	lbu	a5,9(a0)
    80005092:	10078663          	beqz	a5,8000519e <filewrite+0x128>
    80005096:	892a                	mv	s2,a0
    80005098:	8aae                	mv	s5,a1
    8000509a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000509c:	411c                	lw	a5,0(a0)
    8000509e:	4705                	li	a4,1
    800050a0:	02e78263          	beq	a5,a4,800050c4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050a4:	470d                	li	a4,3
    800050a6:	02e78663          	beq	a5,a4,800050d2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800050aa:	4709                	li	a4,2
    800050ac:	0ee79163          	bne	a5,a4,8000518e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800050b0:	0ac05d63          	blez	a2,8000516a <filewrite+0xf4>
    int i = 0;
    800050b4:	4981                	li	s3,0
    800050b6:	6b05                	lui	s6,0x1
    800050b8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800050bc:	6b85                	lui	s7,0x1
    800050be:	c00b8b9b          	addiw	s7,s7,-1024
    800050c2:	a861                	j	8000515a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800050c4:	6908                	ld	a0,16(a0)
    800050c6:	00000097          	auipc	ra,0x0
    800050ca:	22e080e7          	jalr	558(ra) # 800052f4 <pipewrite>
    800050ce:	8a2a                	mv	s4,a0
    800050d0:	a045                	j	80005170 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050d2:	02451783          	lh	a5,36(a0)
    800050d6:	03079693          	slli	a3,a5,0x30
    800050da:	92c1                	srli	a3,a3,0x30
    800050dc:	4725                	li	a4,9
    800050de:	0cd76263          	bltu	a4,a3,800051a2 <filewrite+0x12c>
    800050e2:	0792                	slli	a5,a5,0x4
    800050e4:	00015717          	auipc	a4,0x15
    800050e8:	60470713          	addi	a4,a4,1540 # 8001a6e8 <devsw>
    800050ec:	97ba                	add	a5,a5,a4
    800050ee:	679c                	ld	a5,8(a5)
    800050f0:	cbdd                	beqz	a5,800051a6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050f2:	4505                	li	a0,1
    800050f4:	9782                	jalr	a5
    800050f6:	8a2a                	mv	s4,a0
    800050f8:	a8a5                	j	80005170 <filewrite+0xfa>
    800050fa:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050fe:	00000097          	auipc	ra,0x0
    80005102:	8b0080e7          	jalr	-1872(ra) # 800049ae <begin_op>
      ilock(f->ip);
    80005106:	01893503          	ld	a0,24(s2)
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	ed2080e7          	jalr	-302(ra) # 80003fdc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005112:	8762                	mv	a4,s8
    80005114:	02092683          	lw	a3,32(s2)
    80005118:	01598633          	add	a2,s3,s5
    8000511c:	4585                	li	a1,1
    8000511e:	01893503          	ld	a0,24(s2)
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	266080e7          	jalr	614(ra) # 80004388 <writei>
    8000512a:	84aa                	mv	s1,a0
    8000512c:	00a05763          	blez	a0,8000513a <filewrite+0xc4>
        f->off += r;
    80005130:	02092783          	lw	a5,32(s2)
    80005134:	9fa9                	addw	a5,a5,a0
    80005136:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000513a:	01893503          	ld	a0,24(s2)
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	f60080e7          	jalr	-160(ra) # 8000409e <iunlock>
      end_op();
    80005146:	00000097          	auipc	ra,0x0
    8000514a:	8e8080e7          	jalr	-1816(ra) # 80004a2e <end_op>

      if(r != n1){
    8000514e:	009c1f63          	bne	s8,s1,8000516c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005152:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005156:	0149db63          	bge	s3,s4,8000516c <filewrite+0xf6>
      int n1 = n - i;
    8000515a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000515e:	84be                	mv	s1,a5
    80005160:	2781                	sext.w	a5,a5
    80005162:	f8fb5ce3          	bge	s6,a5,800050fa <filewrite+0x84>
    80005166:	84de                	mv	s1,s7
    80005168:	bf49                	j	800050fa <filewrite+0x84>
    int i = 0;
    8000516a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000516c:	013a1f63          	bne	s4,s3,8000518a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005170:	8552                	mv	a0,s4
    80005172:	60a6                	ld	ra,72(sp)
    80005174:	6406                	ld	s0,64(sp)
    80005176:	74e2                	ld	s1,56(sp)
    80005178:	7942                	ld	s2,48(sp)
    8000517a:	79a2                	ld	s3,40(sp)
    8000517c:	7a02                	ld	s4,32(sp)
    8000517e:	6ae2                	ld	s5,24(sp)
    80005180:	6b42                	ld	s6,16(sp)
    80005182:	6ba2                	ld	s7,8(sp)
    80005184:	6c02                	ld	s8,0(sp)
    80005186:	6161                	addi	sp,sp,80
    80005188:	8082                	ret
    ret = (i == n ? n : -1);
    8000518a:	5a7d                	li	s4,-1
    8000518c:	b7d5                	j	80005170 <filewrite+0xfa>
    panic("filewrite");
    8000518e:	00003517          	auipc	a0,0x3
    80005192:	77250513          	addi	a0,a0,1906 # 80008900 <syscalls+0x268>
    80005196:	ffffb097          	auipc	ra,0xffffb
    8000519a:	3a8080e7          	jalr	936(ra) # 8000053e <panic>
    return -1;
    8000519e:	5a7d                	li	s4,-1
    800051a0:	bfc1                	j	80005170 <filewrite+0xfa>
      return -1;
    800051a2:	5a7d                	li	s4,-1
    800051a4:	b7f1                	j	80005170 <filewrite+0xfa>
    800051a6:	5a7d                	li	s4,-1
    800051a8:	b7e1                	j	80005170 <filewrite+0xfa>

00000000800051aa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800051aa:	7179                	addi	sp,sp,-48
    800051ac:	f406                	sd	ra,40(sp)
    800051ae:	f022                	sd	s0,32(sp)
    800051b0:	ec26                	sd	s1,24(sp)
    800051b2:	e84a                	sd	s2,16(sp)
    800051b4:	e44e                	sd	s3,8(sp)
    800051b6:	e052                	sd	s4,0(sp)
    800051b8:	1800                	addi	s0,sp,48
    800051ba:	84aa                	mv	s1,a0
    800051bc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800051be:	0005b023          	sd	zero,0(a1)
    800051c2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800051c6:	00000097          	auipc	ra,0x0
    800051ca:	bf8080e7          	jalr	-1032(ra) # 80004dbe <filealloc>
    800051ce:	e088                	sd	a0,0(s1)
    800051d0:	c551                	beqz	a0,8000525c <pipealloc+0xb2>
    800051d2:	00000097          	auipc	ra,0x0
    800051d6:	bec080e7          	jalr	-1044(ra) # 80004dbe <filealloc>
    800051da:	00aa3023          	sd	a0,0(s4)
    800051de:	c92d                	beqz	a0,80005250 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800051e0:	ffffc097          	auipc	ra,0xffffc
    800051e4:	914080e7          	jalr	-1772(ra) # 80000af4 <kalloc>
    800051e8:	892a                	mv	s2,a0
    800051ea:	c125                	beqz	a0,8000524a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800051ec:	4985                	li	s3,1
    800051ee:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800051f2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800051f6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800051fa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800051fe:	00003597          	auipc	a1,0x3
    80005202:	71258593          	addi	a1,a1,1810 # 80008910 <syscalls+0x278>
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	94e080e7          	jalr	-1714(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000520e:	609c                	ld	a5,0(s1)
    80005210:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005214:	609c                	ld	a5,0(s1)
    80005216:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000521a:	609c                	ld	a5,0(s1)
    8000521c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005220:	609c                	ld	a5,0(s1)
    80005222:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005226:	000a3783          	ld	a5,0(s4)
    8000522a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000522e:	000a3783          	ld	a5,0(s4)
    80005232:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005236:	000a3783          	ld	a5,0(s4)
    8000523a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000523e:	000a3783          	ld	a5,0(s4)
    80005242:	0127b823          	sd	s2,16(a5)
  return 0;
    80005246:	4501                	li	a0,0
    80005248:	a025                	j	80005270 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000524a:	6088                	ld	a0,0(s1)
    8000524c:	e501                	bnez	a0,80005254 <pipealloc+0xaa>
    8000524e:	a039                	j	8000525c <pipealloc+0xb2>
    80005250:	6088                	ld	a0,0(s1)
    80005252:	c51d                	beqz	a0,80005280 <pipealloc+0xd6>
    fileclose(*f0);
    80005254:	00000097          	auipc	ra,0x0
    80005258:	c26080e7          	jalr	-986(ra) # 80004e7a <fileclose>
  if(*f1)
    8000525c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005260:	557d                	li	a0,-1
  if(*f1)
    80005262:	c799                	beqz	a5,80005270 <pipealloc+0xc6>
    fileclose(*f1);
    80005264:	853e                	mv	a0,a5
    80005266:	00000097          	auipc	ra,0x0
    8000526a:	c14080e7          	jalr	-1004(ra) # 80004e7a <fileclose>
  return -1;
    8000526e:	557d                	li	a0,-1
}
    80005270:	70a2                	ld	ra,40(sp)
    80005272:	7402                	ld	s0,32(sp)
    80005274:	64e2                	ld	s1,24(sp)
    80005276:	6942                	ld	s2,16(sp)
    80005278:	69a2                	ld	s3,8(sp)
    8000527a:	6a02                	ld	s4,0(sp)
    8000527c:	6145                	addi	sp,sp,48
    8000527e:	8082                	ret
  return -1;
    80005280:	557d                	li	a0,-1
    80005282:	b7fd                	j	80005270 <pipealloc+0xc6>

0000000080005284 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005284:	1101                	addi	sp,sp,-32
    80005286:	ec06                	sd	ra,24(sp)
    80005288:	e822                	sd	s0,16(sp)
    8000528a:	e426                	sd	s1,8(sp)
    8000528c:	e04a                	sd	s2,0(sp)
    8000528e:	1000                	addi	s0,sp,32
    80005290:	84aa                	mv	s1,a0
    80005292:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
  if(writable){
    8000529c:	02090d63          	beqz	s2,800052d6 <pipeclose+0x52>
    pi->writeopen = 0;
    800052a0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800052a4:	21848513          	addi	a0,s1,536
    800052a8:	ffffd097          	auipc	ra,0xffffd
    800052ac:	746080e7          	jalr	1862(ra) # 800029ee <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800052b0:	2204b783          	ld	a5,544(s1)
    800052b4:	eb95                	bnez	a5,800052e8 <pipeclose+0x64>
    release(&pi->lock);
    800052b6:	8526                	mv	a0,s1
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	9f2080e7          	jalr	-1550(ra) # 80000caa <release>
    kfree((char*)pi);
    800052c0:	8526                	mv	a0,s1
    800052c2:	ffffb097          	auipc	ra,0xffffb
    800052c6:	736080e7          	jalr	1846(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800052ca:	60e2                	ld	ra,24(sp)
    800052cc:	6442                	ld	s0,16(sp)
    800052ce:	64a2                	ld	s1,8(sp)
    800052d0:	6902                	ld	s2,0(sp)
    800052d2:	6105                	addi	sp,sp,32
    800052d4:	8082                	ret
    pi->readopen = 0;
    800052d6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800052da:	21c48513          	addi	a0,s1,540
    800052de:	ffffd097          	auipc	ra,0xffffd
    800052e2:	710080e7          	jalr	1808(ra) # 800029ee <wakeup>
    800052e6:	b7e9                	j	800052b0 <pipeclose+0x2c>
    release(&pi->lock);
    800052e8:	8526                	mv	a0,s1
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	9c0080e7          	jalr	-1600(ra) # 80000caa <release>
}
    800052f2:	bfe1                	j	800052ca <pipeclose+0x46>

00000000800052f4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800052f4:	7159                	addi	sp,sp,-112
    800052f6:	f486                	sd	ra,104(sp)
    800052f8:	f0a2                	sd	s0,96(sp)
    800052fa:	eca6                	sd	s1,88(sp)
    800052fc:	e8ca                	sd	s2,80(sp)
    800052fe:	e4ce                	sd	s3,72(sp)
    80005300:	e0d2                	sd	s4,64(sp)
    80005302:	fc56                	sd	s5,56(sp)
    80005304:	f85a                	sd	s6,48(sp)
    80005306:	f45e                	sd	s7,40(sp)
    80005308:	f062                	sd	s8,32(sp)
    8000530a:	ec66                	sd	s9,24(sp)
    8000530c:	1880                	addi	s0,sp,112
    8000530e:	84aa                	mv	s1,a0
    80005310:	8aae                	mv	s5,a1
    80005312:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	b2e080e7          	jalr	-1234(ra) # 80001e42 <myproc>
    8000531c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000531e:	8526                	mv	a0,s1
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	8c4080e7          	jalr	-1852(ra) # 80000be4 <acquire>
  while(i < n){
    80005328:	0d405163          	blez	s4,800053ea <pipewrite+0xf6>
    8000532c:	8ba6                	mv	s7,s1
  int i = 0;
    8000532e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005330:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005332:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005336:	21c48c13          	addi	s8,s1,540
    8000533a:	a08d                	j	8000539c <pipewrite+0xa8>
      release(&pi->lock);
    8000533c:	8526                	mv	a0,s1
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	96c080e7          	jalr	-1684(ra) # 80000caa <release>
      return -1;
    80005346:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005348:	854a                	mv	a0,s2
    8000534a:	70a6                	ld	ra,104(sp)
    8000534c:	7406                	ld	s0,96(sp)
    8000534e:	64e6                	ld	s1,88(sp)
    80005350:	6946                	ld	s2,80(sp)
    80005352:	69a6                	ld	s3,72(sp)
    80005354:	6a06                	ld	s4,64(sp)
    80005356:	7ae2                	ld	s5,56(sp)
    80005358:	7b42                	ld	s6,48(sp)
    8000535a:	7ba2                	ld	s7,40(sp)
    8000535c:	7c02                	ld	s8,32(sp)
    8000535e:	6ce2                	ld	s9,24(sp)
    80005360:	6165                	addi	sp,sp,112
    80005362:	8082                	ret
      wakeup(&pi->nread);
    80005364:	8566                	mv	a0,s9
    80005366:	ffffd097          	auipc	ra,0xffffd
    8000536a:	688080e7          	jalr	1672(ra) # 800029ee <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000536e:	85de                	mv	a1,s7
    80005370:	8562                	mv	a0,s8
    80005372:	ffffd097          	auipc	ra,0xffffd
    80005376:	47e080e7          	jalr	1150(ra) # 800027f0 <sleep>
    8000537a:	a839                	j	80005398 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000537c:	21c4a783          	lw	a5,540(s1)
    80005380:	0017871b          	addiw	a4,a5,1
    80005384:	20e4ae23          	sw	a4,540(s1)
    80005388:	1ff7f793          	andi	a5,a5,511
    8000538c:	97a6                	add	a5,a5,s1
    8000538e:	f9f44703          	lbu	a4,-97(s0)
    80005392:	00e78c23          	sb	a4,24(a5)
      i++;
    80005396:	2905                	addiw	s2,s2,1
  while(i < n){
    80005398:	03495d63          	bge	s2,s4,800053d2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000539c:	2204a783          	lw	a5,544(s1)
    800053a0:	dfd1                	beqz	a5,8000533c <pipewrite+0x48>
    800053a2:	0289a783          	lw	a5,40(s3)
    800053a6:	fbd9                	bnez	a5,8000533c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800053a8:	2184a783          	lw	a5,536(s1)
    800053ac:	21c4a703          	lw	a4,540(s1)
    800053b0:	2007879b          	addiw	a5,a5,512
    800053b4:	faf708e3          	beq	a4,a5,80005364 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800053b8:	4685                	li	a3,1
    800053ba:	01590633          	add	a2,s2,s5
    800053be:	f9f40593          	addi	a1,s0,-97
    800053c2:	0709b503          	ld	a0,112(s3)
    800053c6:	ffffc097          	auipc	ra,0xffffc
    800053ca:	35c080e7          	jalr	860(ra) # 80001722 <copyin>
    800053ce:	fb6517e3          	bne	a0,s6,8000537c <pipewrite+0x88>
  wakeup(&pi->nread);
    800053d2:	21848513          	addi	a0,s1,536
    800053d6:	ffffd097          	auipc	ra,0xffffd
    800053da:	618080e7          	jalr	1560(ra) # 800029ee <wakeup>
  release(&pi->lock);
    800053de:	8526                	mv	a0,s1
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	8ca080e7          	jalr	-1846(ra) # 80000caa <release>
  return i;
    800053e8:	b785                	j	80005348 <pipewrite+0x54>
  int i = 0;
    800053ea:	4901                	li	s2,0
    800053ec:	b7dd                	j	800053d2 <pipewrite+0xde>

00000000800053ee <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800053ee:	715d                	addi	sp,sp,-80
    800053f0:	e486                	sd	ra,72(sp)
    800053f2:	e0a2                	sd	s0,64(sp)
    800053f4:	fc26                	sd	s1,56(sp)
    800053f6:	f84a                	sd	s2,48(sp)
    800053f8:	f44e                	sd	s3,40(sp)
    800053fa:	f052                	sd	s4,32(sp)
    800053fc:	ec56                	sd	s5,24(sp)
    800053fe:	e85a                	sd	s6,16(sp)
    80005400:	0880                	addi	s0,sp,80
    80005402:	84aa                	mv	s1,a0
    80005404:	892e                	mv	s2,a1
    80005406:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005408:	ffffd097          	auipc	ra,0xffffd
    8000540c:	a3a080e7          	jalr	-1478(ra) # 80001e42 <myproc>
    80005410:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005412:	8b26                	mv	s6,s1
    80005414:	8526                	mv	a0,s1
    80005416:	ffffb097          	auipc	ra,0xffffb
    8000541a:	7ce080e7          	jalr	1998(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000541e:	2184a703          	lw	a4,536(s1)
    80005422:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005426:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000542a:	02f71463          	bne	a4,a5,80005452 <piperead+0x64>
    8000542e:	2244a783          	lw	a5,548(s1)
    80005432:	c385                	beqz	a5,80005452 <piperead+0x64>
    if(pr->killed){
    80005434:	028a2783          	lw	a5,40(s4)
    80005438:	ebc1                	bnez	a5,800054c8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000543a:	85da                	mv	a1,s6
    8000543c:	854e                	mv	a0,s3
    8000543e:	ffffd097          	auipc	ra,0xffffd
    80005442:	3b2080e7          	jalr	946(ra) # 800027f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005446:	2184a703          	lw	a4,536(s1)
    8000544a:	21c4a783          	lw	a5,540(s1)
    8000544e:	fef700e3          	beq	a4,a5,8000542e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005452:	09505263          	blez	s5,800054d6 <piperead+0xe8>
    80005456:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005458:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000545a:	2184a783          	lw	a5,536(s1)
    8000545e:	21c4a703          	lw	a4,540(s1)
    80005462:	02f70d63          	beq	a4,a5,8000549c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005466:	0017871b          	addiw	a4,a5,1
    8000546a:	20e4ac23          	sw	a4,536(s1)
    8000546e:	1ff7f793          	andi	a5,a5,511
    80005472:	97a6                	add	a5,a5,s1
    80005474:	0187c783          	lbu	a5,24(a5)
    80005478:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000547c:	4685                	li	a3,1
    8000547e:	fbf40613          	addi	a2,s0,-65
    80005482:	85ca                	mv	a1,s2
    80005484:	070a3503          	ld	a0,112(s4)
    80005488:	ffffc097          	auipc	ra,0xffffc
    8000548c:	20e080e7          	jalr	526(ra) # 80001696 <copyout>
    80005490:	01650663          	beq	a0,s6,8000549c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005494:	2985                	addiw	s3,s3,1
    80005496:	0905                	addi	s2,s2,1
    80005498:	fd3a91e3          	bne	s5,s3,8000545a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000549c:	21c48513          	addi	a0,s1,540
    800054a0:	ffffd097          	auipc	ra,0xffffd
    800054a4:	54e080e7          	jalr	1358(ra) # 800029ee <wakeup>
  release(&pi->lock);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffc097          	auipc	ra,0xffffc
    800054ae:	800080e7          	jalr	-2048(ra) # 80000caa <release>
  return i;
}
    800054b2:	854e                	mv	a0,s3
    800054b4:	60a6                	ld	ra,72(sp)
    800054b6:	6406                	ld	s0,64(sp)
    800054b8:	74e2                	ld	s1,56(sp)
    800054ba:	7942                	ld	s2,48(sp)
    800054bc:	79a2                	ld	s3,40(sp)
    800054be:	7a02                	ld	s4,32(sp)
    800054c0:	6ae2                	ld	s5,24(sp)
    800054c2:	6b42                	ld	s6,16(sp)
    800054c4:	6161                	addi	sp,sp,80
    800054c6:	8082                	ret
      release(&pi->lock);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffb097          	auipc	ra,0xffffb
    800054ce:	7e0080e7          	jalr	2016(ra) # 80000caa <release>
      return -1;
    800054d2:	59fd                	li	s3,-1
    800054d4:	bff9                	j	800054b2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054d6:	4981                	li	s3,0
    800054d8:	b7d1                	j	8000549c <piperead+0xae>

00000000800054da <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800054da:	df010113          	addi	sp,sp,-528
    800054de:	20113423          	sd	ra,520(sp)
    800054e2:	20813023          	sd	s0,512(sp)
    800054e6:	ffa6                	sd	s1,504(sp)
    800054e8:	fbca                	sd	s2,496(sp)
    800054ea:	f7ce                	sd	s3,488(sp)
    800054ec:	f3d2                	sd	s4,480(sp)
    800054ee:	efd6                	sd	s5,472(sp)
    800054f0:	ebda                	sd	s6,464(sp)
    800054f2:	e7de                	sd	s7,456(sp)
    800054f4:	e3e2                	sd	s8,448(sp)
    800054f6:	ff66                	sd	s9,440(sp)
    800054f8:	fb6a                	sd	s10,432(sp)
    800054fa:	f76e                	sd	s11,424(sp)
    800054fc:	0c00                	addi	s0,sp,528
    800054fe:	84aa                	mv	s1,a0
    80005500:	dea43c23          	sd	a0,-520(s0)
    80005504:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005508:	ffffd097          	auipc	ra,0xffffd
    8000550c:	93a080e7          	jalr	-1734(ra) # 80001e42 <myproc>
    80005510:	892a                	mv	s2,a0

  begin_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	49c080e7          	jalr	1180(ra) # 800049ae <begin_op>

  if((ip = namei(path)) == 0){
    8000551a:	8526                	mv	a0,s1
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	276080e7          	jalr	630(ra) # 80004792 <namei>
    80005524:	c92d                	beqz	a0,80005596 <exec+0xbc>
    80005526:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	ab4080e7          	jalr	-1356(ra) # 80003fdc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005530:	04000713          	li	a4,64
    80005534:	4681                	li	a3,0
    80005536:	e5040613          	addi	a2,s0,-432
    8000553a:	4581                	li	a1,0
    8000553c:	8526                	mv	a0,s1
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	d52080e7          	jalr	-686(ra) # 80004290 <readi>
    80005546:	04000793          	li	a5,64
    8000554a:	00f51a63          	bne	a0,a5,8000555e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000554e:	e5042703          	lw	a4,-432(s0)
    80005552:	464c47b7          	lui	a5,0x464c4
    80005556:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000555a:	04f70463          	beq	a4,a5,800055a2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	cde080e7          	jalr	-802(ra) # 8000423e <iunlockput>
    end_op();
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	4c6080e7          	jalr	1222(ra) # 80004a2e <end_op>
  }
  return -1;
    80005570:	557d                	li	a0,-1
}
    80005572:	20813083          	ld	ra,520(sp)
    80005576:	20013403          	ld	s0,512(sp)
    8000557a:	74fe                	ld	s1,504(sp)
    8000557c:	795e                	ld	s2,496(sp)
    8000557e:	79be                	ld	s3,488(sp)
    80005580:	7a1e                	ld	s4,480(sp)
    80005582:	6afe                	ld	s5,472(sp)
    80005584:	6b5e                	ld	s6,464(sp)
    80005586:	6bbe                	ld	s7,456(sp)
    80005588:	6c1e                	ld	s8,448(sp)
    8000558a:	7cfa                	ld	s9,440(sp)
    8000558c:	7d5a                	ld	s10,432(sp)
    8000558e:	7dba                	ld	s11,424(sp)
    80005590:	21010113          	addi	sp,sp,528
    80005594:	8082                	ret
    end_op();
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	498080e7          	jalr	1176(ra) # 80004a2e <end_op>
    return -1;
    8000559e:	557d                	li	a0,-1
    800055a0:	bfc9                	j	80005572 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800055a2:	854a                	mv	a0,s2
    800055a4:	ffffd097          	auipc	ra,0xffffd
    800055a8:	954080e7          	jalr	-1708(ra) # 80001ef8 <proc_pagetable>
    800055ac:	8baa                	mv	s7,a0
    800055ae:	d945                	beqz	a0,8000555e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055b0:	e7042983          	lw	s3,-400(s0)
    800055b4:	e8845783          	lhu	a5,-376(s0)
    800055b8:	c7ad                	beqz	a5,80005622 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055ba:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055bc:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800055be:	6c85                	lui	s9,0x1
    800055c0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800055c4:	def43823          	sd	a5,-528(s0)
    800055c8:	a42d                	j	800057f2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800055ca:	00003517          	auipc	a0,0x3
    800055ce:	34e50513          	addi	a0,a0,846 # 80008918 <syscalls+0x280>
    800055d2:	ffffb097          	auipc	ra,0xffffb
    800055d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800055da:	8756                	mv	a4,s5
    800055dc:	012d86bb          	addw	a3,s11,s2
    800055e0:	4581                	li	a1,0
    800055e2:	8526                	mv	a0,s1
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	cac080e7          	jalr	-852(ra) # 80004290 <readi>
    800055ec:	2501                	sext.w	a0,a0
    800055ee:	1aaa9963          	bne	s5,a0,800057a0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800055f2:	6785                	lui	a5,0x1
    800055f4:	0127893b          	addw	s2,a5,s2
    800055f8:	77fd                	lui	a5,0xfffff
    800055fa:	01478a3b          	addw	s4,a5,s4
    800055fe:	1f897163          	bgeu	s2,s8,800057e0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005602:	02091593          	slli	a1,s2,0x20
    80005606:	9181                	srli	a1,a1,0x20
    80005608:	95ea                	add	a1,a1,s10
    8000560a:	855e                	mv	a0,s7
    8000560c:	ffffc097          	auipc	ra,0xffffc
    80005610:	a86080e7          	jalr	-1402(ra) # 80001092 <walkaddr>
    80005614:	862a                	mv	a2,a0
    if(pa == 0)
    80005616:	d955                	beqz	a0,800055ca <exec+0xf0>
      n = PGSIZE;
    80005618:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000561a:	fd9a70e3          	bgeu	s4,s9,800055da <exec+0x100>
      n = sz - i;
    8000561e:	8ad2                	mv	s5,s4
    80005620:	bf6d                	j	800055da <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005622:	4901                	li	s2,0
  iunlockput(ip);
    80005624:	8526                	mv	a0,s1
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	c18080e7          	jalr	-1000(ra) # 8000423e <iunlockput>
  end_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	400080e7          	jalr	1024(ra) # 80004a2e <end_op>
  p = myproc();
    80005636:	ffffd097          	auipc	ra,0xffffd
    8000563a:	80c080e7          	jalr	-2036(ra) # 80001e42 <myproc>
    8000563e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005640:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005644:	6785                	lui	a5,0x1
    80005646:	17fd                	addi	a5,a5,-1
    80005648:	993e                	add	s2,s2,a5
    8000564a:	757d                	lui	a0,0xfffff
    8000564c:	00a977b3          	and	a5,s2,a0
    80005650:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005654:	6609                	lui	a2,0x2
    80005656:	963e                	add	a2,a2,a5
    80005658:	85be                	mv	a1,a5
    8000565a:	855e                	mv	a0,s7
    8000565c:	ffffc097          	auipc	ra,0xffffc
    80005660:	dea080e7          	jalr	-534(ra) # 80001446 <uvmalloc>
    80005664:	8b2a                	mv	s6,a0
  ip = 0;
    80005666:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005668:	12050c63          	beqz	a0,800057a0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000566c:	75f9                	lui	a1,0xffffe
    8000566e:	95aa                	add	a1,a1,a0
    80005670:	855e                	mv	a0,s7
    80005672:	ffffc097          	auipc	ra,0xffffc
    80005676:	ff2080e7          	jalr	-14(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    8000567a:	7c7d                	lui	s8,0xfffff
    8000567c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000567e:	e0043783          	ld	a5,-512(s0)
    80005682:	6388                	ld	a0,0(a5)
    80005684:	c535                	beqz	a0,800056f0 <exec+0x216>
    80005686:	e9040993          	addi	s3,s0,-368
    8000568a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000568e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005690:	ffffb097          	auipc	ra,0xffffb
    80005694:	7f8080e7          	jalr	2040(ra) # 80000e88 <strlen>
    80005698:	2505                	addiw	a0,a0,1
    8000569a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000569e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800056a2:	13896363          	bltu	s2,s8,800057c8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056a6:	e0043d83          	ld	s11,-512(s0)
    800056aa:	000dba03          	ld	s4,0(s11)
    800056ae:	8552                	mv	a0,s4
    800056b0:	ffffb097          	auipc	ra,0xffffb
    800056b4:	7d8080e7          	jalr	2008(ra) # 80000e88 <strlen>
    800056b8:	0015069b          	addiw	a3,a0,1
    800056bc:	8652                	mv	a2,s4
    800056be:	85ca                	mv	a1,s2
    800056c0:	855e                	mv	a0,s7
    800056c2:	ffffc097          	auipc	ra,0xffffc
    800056c6:	fd4080e7          	jalr	-44(ra) # 80001696 <copyout>
    800056ca:	10054363          	bltz	a0,800057d0 <exec+0x2f6>
    ustack[argc] = sp;
    800056ce:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056d2:	0485                	addi	s1,s1,1
    800056d4:	008d8793          	addi	a5,s11,8
    800056d8:	e0f43023          	sd	a5,-512(s0)
    800056dc:	008db503          	ld	a0,8(s11)
    800056e0:	c911                	beqz	a0,800056f4 <exec+0x21a>
    if(argc >= MAXARG)
    800056e2:	09a1                	addi	s3,s3,8
    800056e4:	fb3c96e3          	bne	s9,s3,80005690 <exec+0x1b6>
  sz = sz1;
    800056e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056ec:	4481                	li	s1,0
    800056ee:	a84d                	j	800057a0 <exec+0x2c6>
  sp = sz;
    800056f0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800056f2:	4481                	li	s1,0
  ustack[argc] = 0;
    800056f4:	00349793          	slli	a5,s1,0x3
    800056f8:	f9040713          	addi	a4,s0,-112
    800056fc:	97ba                	add	a5,a5,a4
    800056fe:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005702:	00148693          	addi	a3,s1,1
    80005706:	068e                	slli	a3,a3,0x3
    80005708:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000570c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005710:	01897663          	bgeu	s2,s8,8000571c <exec+0x242>
  sz = sz1;
    80005714:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005718:	4481                	li	s1,0
    8000571a:	a059                	j	800057a0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000571c:	e9040613          	addi	a2,s0,-368
    80005720:	85ca                	mv	a1,s2
    80005722:	855e                	mv	a0,s7
    80005724:	ffffc097          	auipc	ra,0xffffc
    80005728:	f72080e7          	jalr	-142(ra) # 80001696 <copyout>
    8000572c:	0a054663          	bltz	a0,800057d8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005730:	078ab783          	ld	a5,120(s5)
    80005734:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005738:	df843783          	ld	a5,-520(s0)
    8000573c:	0007c703          	lbu	a4,0(a5)
    80005740:	cf11                	beqz	a4,8000575c <exec+0x282>
    80005742:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005744:	02f00693          	li	a3,47
    80005748:	a039                	j	80005756 <exec+0x27c>
      last = s+1;
    8000574a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000574e:	0785                	addi	a5,a5,1
    80005750:	fff7c703          	lbu	a4,-1(a5)
    80005754:	c701                	beqz	a4,8000575c <exec+0x282>
    if(*s == '/')
    80005756:	fed71ce3          	bne	a4,a3,8000574e <exec+0x274>
    8000575a:	bfc5                	j	8000574a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000575c:	4641                	li	a2,16
    8000575e:	df843583          	ld	a1,-520(s0)
    80005762:	178a8513          	addi	a0,s5,376
    80005766:	ffffb097          	auipc	ra,0xffffb
    8000576a:	6f0080e7          	jalr	1776(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    8000576e:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005772:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005776:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000577a:	078ab783          	ld	a5,120(s5)
    8000577e:	e6843703          	ld	a4,-408(s0)
    80005782:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005784:	078ab783          	ld	a5,120(s5)
    80005788:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000578c:	85ea                	mv	a1,s10
    8000578e:	ffffd097          	auipc	ra,0xffffd
    80005792:	806080e7          	jalr	-2042(ra) # 80001f94 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005796:	0004851b          	sext.w	a0,s1
    8000579a:	bbe1                	j	80005572 <exec+0x98>
    8000579c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800057a0:	e0843583          	ld	a1,-504(s0)
    800057a4:	855e                	mv	a0,s7
    800057a6:	ffffc097          	auipc	ra,0xffffc
    800057aa:	7ee080e7          	jalr	2030(ra) # 80001f94 <proc_freepagetable>
  if(ip){
    800057ae:	da0498e3          	bnez	s1,8000555e <exec+0x84>
  return -1;
    800057b2:	557d                	li	a0,-1
    800057b4:	bb7d                	j	80005572 <exec+0x98>
    800057b6:	e1243423          	sd	s2,-504(s0)
    800057ba:	b7dd                	j	800057a0 <exec+0x2c6>
    800057bc:	e1243423          	sd	s2,-504(s0)
    800057c0:	b7c5                	j	800057a0 <exec+0x2c6>
    800057c2:	e1243423          	sd	s2,-504(s0)
    800057c6:	bfe9                	j	800057a0 <exec+0x2c6>
  sz = sz1;
    800057c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057cc:	4481                	li	s1,0
    800057ce:	bfc9                	j	800057a0 <exec+0x2c6>
  sz = sz1;
    800057d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057d4:	4481                	li	s1,0
    800057d6:	b7e9                	j	800057a0 <exec+0x2c6>
  sz = sz1;
    800057d8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057dc:	4481                	li	s1,0
    800057de:	b7c9                	j	800057a0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800057e0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057e4:	2b05                	addiw	s6,s6,1
    800057e6:	0389899b          	addiw	s3,s3,56
    800057ea:	e8845783          	lhu	a5,-376(s0)
    800057ee:	e2fb5be3          	bge	s6,a5,80005624 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057f2:	2981                	sext.w	s3,s3
    800057f4:	03800713          	li	a4,56
    800057f8:	86ce                	mv	a3,s3
    800057fa:	e1840613          	addi	a2,s0,-488
    800057fe:	4581                	li	a1,0
    80005800:	8526                	mv	a0,s1
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	a8e080e7          	jalr	-1394(ra) # 80004290 <readi>
    8000580a:	03800793          	li	a5,56
    8000580e:	f8f517e3          	bne	a0,a5,8000579c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005812:	e1842783          	lw	a5,-488(s0)
    80005816:	4705                	li	a4,1
    80005818:	fce796e3          	bne	a5,a4,800057e4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000581c:	e4043603          	ld	a2,-448(s0)
    80005820:	e3843783          	ld	a5,-456(s0)
    80005824:	f8f669e3          	bltu	a2,a5,800057b6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005828:	e2843783          	ld	a5,-472(s0)
    8000582c:	963e                	add	a2,a2,a5
    8000582e:	f8f667e3          	bltu	a2,a5,800057bc <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005832:	85ca                	mv	a1,s2
    80005834:	855e                	mv	a0,s7
    80005836:	ffffc097          	auipc	ra,0xffffc
    8000583a:	c10080e7          	jalr	-1008(ra) # 80001446 <uvmalloc>
    8000583e:	e0a43423          	sd	a0,-504(s0)
    80005842:	d141                	beqz	a0,800057c2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005844:	e2843d03          	ld	s10,-472(s0)
    80005848:	df043783          	ld	a5,-528(s0)
    8000584c:	00fd77b3          	and	a5,s10,a5
    80005850:	fba1                	bnez	a5,800057a0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005852:	e2042d83          	lw	s11,-480(s0)
    80005856:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000585a:	f80c03e3          	beqz	s8,800057e0 <exec+0x306>
    8000585e:	8a62                	mv	s4,s8
    80005860:	4901                	li	s2,0
    80005862:	b345                	j	80005602 <exec+0x128>

0000000080005864 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005864:	7179                	addi	sp,sp,-48
    80005866:	f406                	sd	ra,40(sp)
    80005868:	f022                	sd	s0,32(sp)
    8000586a:	ec26                	sd	s1,24(sp)
    8000586c:	e84a                	sd	s2,16(sp)
    8000586e:	1800                	addi	s0,sp,48
    80005870:	892e                	mv	s2,a1
    80005872:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005874:	fdc40593          	addi	a1,s0,-36
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	bf2080e7          	jalr	-1038(ra) # 8000346a <argint>
    80005880:	04054063          	bltz	a0,800058c0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005884:	fdc42703          	lw	a4,-36(s0)
    80005888:	47bd                	li	a5,15
    8000588a:	02e7ed63          	bltu	a5,a4,800058c4 <argfd+0x60>
    8000588e:	ffffc097          	auipc	ra,0xffffc
    80005892:	5b4080e7          	jalr	1460(ra) # 80001e42 <myproc>
    80005896:	fdc42703          	lw	a4,-36(s0)
    8000589a:	01e70793          	addi	a5,a4,30
    8000589e:	078e                	slli	a5,a5,0x3
    800058a0:	953e                	add	a0,a0,a5
    800058a2:	611c                	ld	a5,0(a0)
    800058a4:	c395                	beqz	a5,800058c8 <argfd+0x64>
    return -1;
  if(pfd)
    800058a6:	00090463          	beqz	s2,800058ae <argfd+0x4a>
    *pfd = fd;
    800058aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800058ae:	4501                	li	a0,0
  if(pf)
    800058b0:	c091                	beqz	s1,800058b4 <argfd+0x50>
    *pf = f;
    800058b2:	e09c                	sd	a5,0(s1)
}
    800058b4:	70a2                	ld	ra,40(sp)
    800058b6:	7402                	ld	s0,32(sp)
    800058b8:	64e2                	ld	s1,24(sp)
    800058ba:	6942                	ld	s2,16(sp)
    800058bc:	6145                	addi	sp,sp,48
    800058be:	8082                	ret
    return -1;
    800058c0:	557d                	li	a0,-1
    800058c2:	bfcd                	j	800058b4 <argfd+0x50>
    return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	b7fd                	j	800058b4 <argfd+0x50>
    800058c8:	557d                	li	a0,-1
    800058ca:	b7ed                	j	800058b4 <argfd+0x50>

00000000800058cc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058cc:	1101                	addi	sp,sp,-32
    800058ce:	ec06                	sd	ra,24(sp)
    800058d0:	e822                	sd	s0,16(sp)
    800058d2:	e426                	sd	s1,8(sp)
    800058d4:	1000                	addi	s0,sp,32
    800058d6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058d8:	ffffc097          	auipc	ra,0xffffc
    800058dc:	56a080e7          	jalr	1386(ra) # 80001e42 <myproc>
    800058e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058e2:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffe00f0>
    800058e6:	4501                	li	a0,0
    800058e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800058ea:	6398                	ld	a4,0(a5)
    800058ec:	cb19                	beqz	a4,80005902 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800058ee:	2505                	addiw	a0,a0,1
    800058f0:	07a1                	addi	a5,a5,8
    800058f2:	fed51ce3          	bne	a0,a3,800058ea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800058f6:	557d                	li	a0,-1
}
    800058f8:	60e2                	ld	ra,24(sp)
    800058fa:	6442                	ld	s0,16(sp)
    800058fc:	64a2                	ld	s1,8(sp)
    800058fe:	6105                	addi	sp,sp,32
    80005900:	8082                	ret
      p->ofile[fd] = f;
    80005902:	01e50793          	addi	a5,a0,30
    80005906:	078e                	slli	a5,a5,0x3
    80005908:	963e                	add	a2,a2,a5
    8000590a:	e204                	sd	s1,0(a2)
      return fd;
    8000590c:	b7f5                	j	800058f8 <fdalloc+0x2c>

000000008000590e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000590e:	715d                	addi	sp,sp,-80
    80005910:	e486                	sd	ra,72(sp)
    80005912:	e0a2                	sd	s0,64(sp)
    80005914:	fc26                	sd	s1,56(sp)
    80005916:	f84a                	sd	s2,48(sp)
    80005918:	f44e                	sd	s3,40(sp)
    8000591a:	f052                	sd	s4,32(sp)
    8000591c:	ec56                	sd	s5,24(sp)
    8000591e:	0880                	addi	s0,sp,80
    80005920:	89ae                	mv	s3,a1
    80005922:	8ab2                	mv	s5,a2
    80005924:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005926:	fb040593          	addi	a1,s0,-80
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	e86080e7          	jalr	-378(ra) # 800047b0 <nameiparent>
    80005932:	892a                	mv	s2,a0
    80005934:	12050f63          	beqz	a0,80005a72 <create+0x164>
    return 0;

  ilock(dp);
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	6a4080e7          	jalr	1700(ra) # 80003fdc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005940:	4601                	li	a2,0
    80005942:	fb040593          	addi	a1,s0,-80
    80005946:	854a                	mv	a0,s2
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	b78080e7          	jalr	-1160(ra) # 800044c0 <dirlookup>
    80005950:	84aa                	mv	s1,a0
    80005952:	c921                	beqz	a0,800059a2 <create+0x94>
    iunlockput(dp);
    80005954:	854a                	mv	a0,s2
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	8e8080e7          	jalr	-1816(ra) # 8000423e <iunlockput>
    ilock(ip);
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	67c080e7          	jalr	1660(ra) # 80003fdc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005968:	2981                	sext.w	s3,s3
    8000596a:	4789                	li	a5,2
    8000596c:	02f99463          	bne	s3,a5,80005994 <create+0x86>
    80005970:	0444d783          	lhu	a5,68(s1)
    80005974:	37f9                	addiw	a5,a5,-2
    80005976:	17c2                	slli	a5,a5,0x30
    80005978:	93c1                	srli	a5,a5,0x30
    8000597a:	4705                	li	a4,1
    8000597c:	00f76c63          	bltu	a4,a5,80005994 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005980:	8526                	mv	a0,s1
    80005982:	60a6                	ld	ra,72(sp)
    80005984:	6406                	ld	s0,64(sp)
    80005986:	74e2                	ld	s1,56(sp)
    80005988:	7942                	ld	s2,48(sp)
    8000598a:	79a2                	ld	s3,40(sp)
    8000598c:	7a02                	ld	s4,32(sp)
    8000598e:	6ae2                	ld	s5,24(sp)
    80005990:	6161                	addi	sp,sp,80
    80005992:	8082                	ret
    iunlockput(ip);
    80005994:	8526                	mv	a0,s1
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	8a8080e7          	jalr	-1880(ra) # 8000423e <iunlockput>
    return 0;
    8000599e:	4481                	li	s1,0
    800059a0:	b7c5                	j	80005980 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800059a2:	85ce                	mv	a1,s3
    800059a4:	00092503          	lw	a0,0(s2)
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	49c080e7          	jalr	1180(ra) # 80003e44 <ialloc>
    800059b0:	84aa                	mv	s1,a0
    800059b2:	c529                	beqz	a0,800059fc <create+0xee>
  ilock(ip);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	628080e7          	jalr	1576(ra) # 80003fdc <ilock>
  ip->major = major;
    800059bc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800059c0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800059c4:	4785                	li	a5,1
    800059c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	546080e7          	jalr	1350(ra) # 80003f12 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059d4:	2981                	sext.w	s3,s3
    800059d6:	4785                	li	a5,1
    800059d8:	02f98a63          	beq	s3,a5,80005a0c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800059dc:	40d0                	lw	a2,4(s1)
    800059de:	fb040593          	addi	a1,s0,-80
    800059e2:	854a                	mv	a0,s2
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	cec080e7          	jalr	-788(ra) # 800046d0 <dirlink>
    800059ec:	06054b63          	bltz	a0,80005a62 <create+0x154>
  iunlockput(dp);
    800059f0:	854a                	mv	a0,s2
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	84c080e7          	jalr	-1972(ra) # 8000423e <iunlockput>
  return ip;
    800059fa:	b759                	j	80005980 <create+0x72>
    panic("create: ialloc");
    800059fc:	00003517          	auipc	a0,0x3
    80005a00:	f3c50513          	addi	a0,a0,-196 # 80008938 <syscalls+0x2a0>
    80005a04:	ffffb097          	auipc	ra,0xffffb
    80005a08:	b3a080e7          	jalr	-1222(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005a0c:	04a95783          	lhu	a5,74(s2)
    80005a10:	2785                	addiw	a5,a5,1
    80005a12:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005a16:	854a                	mv	a0,s2
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	4fa080e7          	jalr	1274(ra) # 80003f12 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a20:	40d0                	lw	a2,4(s1)
    80005a22:	00003597          	auipc	a1,0x3
    80005a26:	f2658593          	addi	a1,a1,-218 # 80008948 <syscalls+0x2b0>
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	ca4080e7          	jalr	-860(ra) # 800046d0 <dirlink>
    80005a34:	00054f63          	bltz	a0,80005a52 <create+0x144>
    80005a38:	00492603          	lw	a2,4(s2)
    80005a3c:	00003597          	auipc	a1,0x3
    80005a40:	f1458593          	addi	a1,a1,-236 # 80008950 <syscalls+0x2b8>
    80005a44:	8526                	mv	a0,s1
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	c8a080e7          	jalr	-886(ra) # 800046d0 <dirlink>
    80005a4e:	f80557e3          	bgez	a0,800059dc <create+0xce>
      panic("create dots");
    80005a52:	00003517          	auipc	a0,0x3
    80005a56:	f0650513          	addi	a0,a0,-250 # 80008958 <syscalls+0x2c0>
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005a62:	00003517          	auipc	a0,0x3
    80005a66:	f0650513          	addi	a0,a0,-250 # 80008968 <syscalls+0x2d0>
    80005a6a:	ffffb097          	auipc	ra,0xffffb
    80005a6e:	ad4080e7          	jalr	-1324(ra) # 8000053e <panic>
    return 0;
    80005a72:	84aa                	mv	s1,a0
    80005a74:	b731                	j	80005980 <create+0x72>

0000000080005a76 <sys_dup>:
{
    80005a76:	7179                	addi	sp,sp,-48
    80005a78:	f406                	sd	ra,40(sp)
    80005a7a:	f022                	sd	s0,32(sp)
    80005a7c:	ec26                	sd	s1,24(sp)
    80005a7e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a80:	fd840613          	addi	a2,s0,-40
    80005a84:	4581                	li	a1,0
    80005a86:	4501                	li	a0,0
    80005a88:	00000097          	auipc	ra,0x0
    80005a8c:	ddc080e7          	jalr	-548(ra) # 80005864 <argfd>
    return -1;
    80005a90:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a92:	02054363          	bltz	a0,80005ab8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a96:	fd843503          	ld	a0,-40(s0)
    80005a9a:	00000097          	auipc	ra,0x0
    80005a9e:	e32080e7          	jalr	-462(ra) # 800058cc <fdalloc>
    80005aa2:	84aa                	mv	s1,a0
    return -1;
    80005aa4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005aa6:	00054963          	bltz	a0,80005ab8 <sys_dup+0x42>
  filedup(f);
    80005aaa:	fd843503          	ld	a0,-40(s0)
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	37a080e7          	jalr	890(ra) # 80004e28 <filedup>
  return fd;
    80005ab6:	87a6                	mv	a5,s1
}
    80005ab8:	853e                	mv	a0,a5
    80005aba:	70a2                	ld	ra,40(sp)
    80005abc:	7402                	ld	s0,32(sp)
    80005abe:	64e2                	ld	s1,24(sp)
    80005ac0:	6145                	addi	sp,sp,48
    80005ac2:	8082                	ret

0000000080005ac4 <sys_read>:
{
    80005ac4:	7179                	addi	sp,sp,-48
    80005ac6:	f406                	sd	ra,40(sp)
    80005ac8:	f022                	sd	s0,32(sp)
    80005aca:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005acc:	fe840613          	addi	a2,s0,-24
    80005ad0:	4581                	li	a1,0
    80005ad2:	4501                	li	a0,0
    80005ad4:	00000097          	auipc	ra,0x0
    80005ad8:	d90080e7          	jalr	-624(ra) # 80005864 <argfd>
    return -1;
    80005adc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ade:	04054163          	bltz	a0,80005b20 <sys_read+0x5c>
    80005ae2:	fe440593          	addi	a1,s0,-28
    80005ae6:	4509                	li	a0,2
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	982080e7          	jalr	-1662(ra) # 8000346a <argint>
    return -1;
    80005af0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005af2:	02054763          	bltz	a0,80005b20 <sys_read+0x5c>
    80005af6:	fd840593          	addi	a1,s0,-40
    80005afa:	4505                	li	a0,1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	990080e7          	jalr	-1648(ra) # 8000348c <argaddr>
    return -1;
    80005b04:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b06:	00054d63          	bltz	a0,80005b20 <sys_read+0x5c>
  return fileread(f, p, n);
    80005b0a:	fe442603          	lw	a2,-28(s0)
    80005b0e:	fd843583          	ld	a1,-40(s0)
    80005b12:	fe843503          	ld	a0,-24(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	49e080e7          	jalr	1182(ra) # 80004fb4 <fileread>
    80005b1e:	87aa                	mv	a5,a0
}
    80005b20:	853e                	mv	a0,a5
    80005b22:	70a2                	ld	ra,40(sp)
    80005b24:	7402                	ld	s0,32(sp)
    80005b26:	6145                	addi	sp,sp,48
    80005b28:	8082                	ret

0000000080005b2a <sys_write>:
{
    80005b2a:	7179                	addi	sp,sp,-48
    80005b2c:	f406                	sd	ra,40(sp)
    80005b2e:	f022                	sd	s0,32(sp)
    80005b30:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b32:	fe840613          	addi	a2,s0,-24
    80005b36:	4581                	li	a1,0
    80005b38:	4501                	li	a0,0
    80005b3a:	00000097          	auipc	ra,0x0
    80005b3e:	d2a080e7          	jalr	-726(ra) # 80005864 <argfd>
    return -1;
    80005b42:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b44:	04054163          	bltz	a0,80005b86 <sys_write+0x5c>
    80005b48:	fe440593          	addi	a1,s0,-28
    80005b4c:	4509                	li	a0,2
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	91c080e7          	jalr	-1764(ra) # 8000346a <argint>
    return -1;
    80005b56:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b58:	02054763          	bltz	a0,80005b86 <sys_write+0x5c>
    80005b5c:	fd840593          	addi	a1,s0,-40
    80005b60:	4505                	li	a0,1
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	92a080e7          	jalr	-1750(ra) # 8000348c <argaddr>
    return -1;
    80005b6a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b6c:	00054d63          	bltz	a0,80005b86 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005b70:	fe442603          	lw	a2,-28(s0)
    80005b74:	fd843583          	ld	a1,-40(s0)
    80005b78:	fe843503          	ld	a0,-24(s0)
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	4fa080e7          	jalr	1274(ra) # 80005076 <filewrite>
    80005b84:	87aa                	mv	a5,a0
}
    80005b86:	853e                	mv	a0,a5
    80005b88:	70a2                	ld	ra,40(sp)
    80005b8a:	7402                	ld	s0,32(sp)
    80005b8c:	6145                	addi	sp,sp,48
    80005b8e:	8082                	ret

0000000080005b90 <sys_close>:
{
    80005b90:	1101                	addi	sp,sp,-32
    80005b92:	ec06                	sd	ra,24(sp)
    80005b94:	e822                	sd	s0,16(sp)
    80005b96:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b98:	fe040613          	addi	a2,s0,-32
    80005b9c:	fec40593          	addi	a1,s0,-20
    80005ba0:	4501                	li	a0,0
    80005ba2:	00000097          	auipc	ra,0x0
    80005ba6:	cc2080e7          	jalr	-830(ra) # 80005864 <argfd>
    return -1;
    80005baa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005bac:	02054463          	bltz	a0,80005bd4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	292080e7          	jalr	658(ra) # 80001e42 <myproc>
    80005bb8:	fec42783          	lw	a5,-20(s0)
    80005bbc:	07f9                	addi	a5,a5,30
    80005bbe:	078e                	slli	a5,a5,0x3
    80005bc0:	97aa                	add	a5,a5,a0
    80005bc2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005bc6:	fe043503          	ld	a0,-32(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	2b0080e7          	jalr	688(ra) # 80004e7a <fileclose>
  return 0;
    80005bd2:	4781                	li	a5,0
}
    80005bd4:	853e                	mv	a0,a5
    80005bd6:	60e2                	ld	ra,24(sp)
    80005bd8:	6442                	ld	s0,16(sp)
    80005bda:	6105                	addi	sp,sp,32
    80005bdc:	8082                	ret

0000000080005bde <sys_fstat>:
{
    80005bde:	1101                	addi	sp,sp,-32
    80005be0:	ec06                	sd	ra,24(sp)
    80005be2:	e822                	sd	s0,16(sp)
    80005be4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005be6:	fe840613          	addi	a2,s0,-24
    80005bea:	4581                	li	a1,0
    80005bec:	4501                	li	a0,0
    80005bee:	00000097          	auipc	ra,0x0
    80005bf2:	c76080e7          	jalr	-906(ra) # 80005864 <argfd>
    return -1;
    80005bf6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005bf8:	02054563          	bltz	a0,80005c22 <sys_fstat+0x44>
    80005bfc:	fe040593          	addi	a1,s0,-32
    80005c00:	4505                	li	a0,1
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	88a080e7          	jalr	-1910(ra) # 8000348c <argaddr>
    return -1;
    80005c0a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c0c:	00054b63          	bltz	a0,80005c22 <sys_fstat+0x44>
  return filestat(f, st);
    80005c10:	fe043583          	ld	a1,-32(s0)
    80005c14:	fe843503          	ld	a0,-24(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	32a080e7          	jalr	810(ra) # 80004f42 <filestat>
    80005c20:	87aa                	mv	a5,a0
}
    80005c22:	853e                	mv	a0,a5
    80005c24:	60e2                	ld	ra,24(sp)
    80005c26:	6442                	ld	s0,16(sp)
    80005c28:	6105                	addi	sp,sp,32
    80005c2a:	8082                	ret

0000000080005c2c <sys_link>:
{
    80005c2c:	7169                	addi	sp,sp,-304
    80005c2e:	f606                	sd	ra,296(sp)
    80005c30:	f222                	sd	s0,288(sp)
    80005c32:	ee26                	sd	s1,280(sp)
    80005c34:	ea4a                	sd	s2,272(sp)
    80005c36:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c38:	08000613          	li	a2,128
    80005c3c:	ed040593          	addi	a1,s0,-304
    80005c40:	4501                	li	a0,0
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	86c080e7          	jalr	-1940(ra) # 800034ae <argstr>
    return -1;
    80005c4a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c4c:	10054e63          	bltz	a0,80005d68 <sys_link+0x13c>
    80005c50:	08000613          	li	a2,128
    80005c54:	f5040593          	addi	a1,s0,-176
    80005c58:	4505                	li	a0,1
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	854080e7          	jalr	-1964(ra) # 800034ae <argstr>
    return -1;
    80005c62:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c64:	10054263          	bltz	a0,80005d68 <sys_link+0x13c>
  begin_op();
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	d46080e7          	jalr	-698(ra) # 800049ae <begin_op>
  if((ip = namei(old)) == 0){
    80005c70:	ed040513          	addi	a0,s0,-304
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	b1e080e7          	jalr	-1250(ra) # 80004792 <namei>
    80005c7c:	84aa                	mv	s1,a0
    80005c7e:	c551                	beqz	a0,80005d0a <sys_link+0xde>
  ilock(ip);
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	35c080e7          	jalr	860(ra) # 80003fdc <ilock>
  if(ip->type == T_DIR){
    80005c88:	04449703          	lh	a4,68(s1)
    80005c8c:	4785                	li	a5,1
    80005c8e:	08f70463          	beq	a4,a5,80005d16 <sys_link+0xea>
  ip->nlink++;
    80005c92:	04a4d783          	lhu	a5,74(s1)
    80005c96:	2785                	addiw	a5,a5,1
    80005c98:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c9c:	8526                	mv	a0,s1
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	274080e7          	jalr	628(ra) # 80003f12 <iupdate>
  iunlock(ip);
    80005ca6:	8526                	mv	a0,s1
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	3f6080e7          	jalr	1014(ra) # 8000409e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005cb0:	fd040593          	addi	a1,s0,-48
    80005cb4:	f5040513          	addi	a0,s0,-176
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	af8080e7          	jalr	-1288(ra) # 800047b0 <nameiparent>
    80005cc0:	892a                	mv	s2,a0
    80005cc2:	c935                	beqz	a0,80005d36 <sys_link+0x10a>
  ilock(dp);
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	318080e7          	jalr	792(ra) # 80003fdc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ccc:	00092703          	lw	a4,0(s2)
    80005cd0:	409c                	lw	a5,0(s1)
    80005cd2:	04f71d63          	bne	a4,a5,80005d2c <sys_link+0x100>
    80005cd6:	40d0                	lw	a2,4(s1)
    80005cd8:	fd040593          	addi	a1,s0,-48
    80005cdc:	854a                	mv	a0,s2
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	9f2080e7          	jalr	-1550(ra) # 800046d0 <dirlink>
    80005ce6:	04054363          	bltz	a0,80005d2c <sys_link+0x100>
  iunlockput(dp);
    80005cea:	854a                	mv	a0,s2
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	552080e7          	jalr	1362(ra) # 8000423e <iunlockput>
  iput(ip);
    80005cf4:	8526                	mv	a0,s1
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	4a0080e7          	jalr	1184(ra) # 80004196 <iput>
  end_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	d30080e7          	jalr	-720(ra) # 80004a2e <end_op>
  return 0;
    80005d06:	4781                	li	a5,0
    80005d08:	a085                	j	80005d68 <sys_link+0x13c>
    end_op();
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	d24080e7          	jalr	-732(ra) # 80004a2e <end_op>
    return -1;
    80005d12:	57fd                	li	a5,-1
    80005d14:	a891                	j	80005d68 <sys_link+0x13c>
    iunlockput(ip);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	526080e7          	jalr	1318(ra) # 8000423e <iunlockput>
    end_op();
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	d0e080e7          	jalr	-754(ra) # 80004a2e <end_op>
    return -1;
    80005d28:	57fd                	li	a5,-1
    80005d2a:	a83d                	j	80005d68 <sys_link+0x13c>
    iunlockput(dp);
    80005d2c:	854a                	mv	a0,s2
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	510080e7          	jalr	1296(ra) # 8000423e <iunlockput>
  ilock(ip);
    80005d36:	8526                	mv	a0,s1
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	2a4080e7          	jalr	676(ra) # 80003fdc <ilock>
  ip->nlink--;
    80005d40:	04a4d783          	lhu	a5,74(s1)
    80005d44:	37fd                	addiw	a5,a5,-1
    80005d46:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d4a:	8526                	mv	a0,s1
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	1c6080e7          	jalr	454(ra) # 80003f12 <iupdate>
  iunlockput(ip);
    80005d54:	8526                	mv	a0,s1
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	4e8080e7          	jalr	1256(ra) # 8000423e <iunlockput>
  end_op();
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	cd0080e7          	jalr	-816(ra) # 80004a2e <end_op>
  return -1;
    80005d66:	57fd                	li	a5,-1
}
    80005d68:	853e                	mv	a0,a5
    80005d6a:	70b2                	ld	ra,296(sp)
    80005d6c:	7412                	ld	s0,288(sp)
    80005d6e:	64f2                	ld	s1,280(sp)
    80005d70:	6952                	ld	s2,272(sp)
    80005d72:	6155                	addi	sp,sp,304
    80005d74:	8082                	ret

0000000080005d76 <sys_unlink>:
{
    80005d76:	7151                	addi	sp,sp,-240
    80005d78:	f586                	sd	ra,232(sp)
    80005d7a:	f1a2                	sd	s0,224(sp)
    80005d7c:	eda6                	sd	s1,216(sp)
    80005d7e:	e9ca                	sd	s2,208(sp)
    80005d80:	e5ce                	sd	s3,200(sp)
    80005d82:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d84:	08000613          	li	a2,128
    80005d88:	f3040593          	addi	a1,s0,-208
    80005d8c:	4501                	li	a0,0
    80005d8e:	ffffd097          	auipc	ra,0xffffd
    80005d92:	720080e7          	jalr	1824(ra) # 800034ae <argstr>
    80005d96:	18054163          	bltz	a0,80005f18 <sys_unlink+0x1a2>
  begin_op();
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	c14080e7          	jalr	-1004(ra) # 800049ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005da2:	fb040593          	addi	a1,s0,-80
    80005da6:	f3040513          	addi	a0,s0,-208
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	a06080e7          	jalr	-1530(ra) # 800047b0 <nameiparent>
    80005db2:	84aa                	mv	s1,a0
    80005db4:	c979                	beqz	a0,80005e8a <sys_unlink+0x114>
  ilock(dp);
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	226080e7          	jalr	550(ra) # 80003fdc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005dbe:	00003597          	auipc	a1,0x3
    80005dc2:	b8a58593          	addi	a1,a1,-1142 # 80008948 <syscalls+0x2b0>
    80005dc6:	fb040513          	addi	a0,s0,-80
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	6dc080e7          	jalr	1756(ra) # 800044a6 <namecmp>
    80005dd2:	14050a63          	beqz	a0,80005f26 <sys_unlink+0x1b0>
    80005dd6:	00003597          	auipc	a1,0x3
    80005dda:	b7a58593          	addi	a1,a1,-1158 # 80008950 <syscalls+0x2b8>
    80005dde:	fb040513          	addi	a0,s0,-80
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	6c4080e7          	jalr	1732(ra) # 800044a6 <namecmp>
    80005dea:	12050e63          	beqz	a0,80005f26 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005dee:	f2c40613          	addi	a2,s0,-212
    80005df2:	fb040593          	addi	a1,s0,-80
    80005df6:	8526                	mv	a0,s1
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	6c8080e7          	jalr	1736(ra) # 800044c0 <dirlookup>
    80005e00:	892a                	mv	s2,a0
    80005e02:	12050263          	beqz	a0,80005f26 <sys_unlink+0x1b0>
  ilock(ip);
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	1d6080e7          	jalr	470(ra) # 80003fdc <ilock>
  if(ip->nlink < 1)
    80005e0e:	04a91783          	lh	a5,74(s2)
    80005e12:	08f05263          	blez	a5,80005e96 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e16:	04491703          	lh	a4,68(s2)
    80005e1a:	4785                	li	a5,1
    80005e1c:	08f70563          	beq	a4,a5,80005ea6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e20:	4641                	li	a2,16
    80005e22:	4581                	li	a1,0
    80005e24:	fc040513          	addi	a0,s0,-64
    80005e28:	ffffb097          	auipc	ra,0xffffb
    80005e2c:	edc080e7          	jalr	-292(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e30:	4741                	li	a4,16
    80005e32:	f2c42683          	lw	a3,-212(s0)
    80005e36:	fc040613          	addi	a2,s0,-64
    80005e3a:	4581                	li	a1,0
    80005e3c:	8526                	mv	a0,s1
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	54a080e7          	jalr	1354(ra) # 80004388 <writei>
    80005e46:	47c1                	li	a5,16
    80005e48:	0af51563          	bne	a0,a5,80005ef2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005e4c:	04491703          	lh	a4,68(s2)
    80005e50:	4785                	li	a5,1
    80005e52:	0af70863          	beq	a4,a5,80005f02 <sys_unlink+0x18c>
  iunlockput(dp);
    80005e56:	8526                	mv	a0,s1
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	3e6080e7          	jalr	998(ra) # 8000423e <iunlockput>
  ip->nlink--;
    80005e60:	04a95783          	lhu	a5,74(s2)
    80005e64:	37fd                	addiw	a5,a5,-1
    80005e66:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e6a:	854a                	mv	a0,s2
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	0a6080e7          	jalr	166(ra) # 80003f12 <iupdate>
  iunlockput(ip);
    80005e74:	854a                	mv	a0,s2
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	3c8080e7          	jalr	968(ra) # 8000423e <iunlockput>
  end_op();
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	bb0080e7          	jalr	-1104(ra) # 80004a2e <end_op>
  return 0;
    80005e86:	4501                	li	a0,0
    80005e88:	a84d                	j	80005f3a <sys_unlink+0x1c4>
    end_op();
    80005e8a:	fffff097          	auipc	ra,0xfffff
    80005e8e:	ba4080e7          	jalr	-1116(ra) # 80004a2e <end_op>
    return -1;
    80005e92:	557d                	li	a0,-1
    80005e94:	a05d                	j	80005f3a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e96:	00003517          	auipc	a0,0x3
    80005e9a:	ae250513          	addi	a0,a0,-1310 # 80008978 <syscalls+0x2e0>
    80005e9e:	ffffa097          	auipc	ra,0xffffa
    80005ea2:	6a0080e7          	jalr	1696(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ea6:	04c92703          	lw	a4,76(s2)
    80005eaa:	02000793          	li	a5,32
    80005eae:	f6e7f9e3          	bgeu	a5,a4,80005e20 <sys_unlink+0xaa>
    80005eb2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005eb6:	4741                	li	a4,16
    80005eb8:	86ce                	mv	a3,s3
    80005eba:	f1840613          	addi	a2,s0,-232
    80005ebe:	4581                	li	a1,0
    80005ec0:	854a                	mv	a0,s2
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	3ce080e7          	jalr	974(ra) # 80004290 <readi>
    80005eca:	47c1                	li	a5,16
    80005ecc:	00f51b63          	bne	a0,a5,80005ee2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ed0:	f1845783          	lhu	a5,-232(s0)
    80005ed4:	e7a1                	bnez	a5,80005f1c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ed6:	29c1                	addiw	s3,s3,16
    80005ed8:	04c92783          	lw	a5,76(s2)
    80005edc:	fcf9ede3          	bltu	s3,a5,80005eb6 <sys_unlink+0x140>
    80005ee0:	b781                	j	80005e20 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	aae50513          	addi	a0,a0,-1362 # 80008990 <syscalls+0x2f8>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	ab650513          	addi	a0,a0,-1354 # 800089a8 <syscalls+0x310>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	644080e7          	jalr	1604(ra) # 8000053e <panic>
    dp->nlink--;
    80005f02:	04a4d783          	lhu	a5,74(s1)
    80005f06:	37fd                	addiw	a5,a5,-1
    80005f08:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f0c:	8526                	mv	a0,s1
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	004080e7          	jalr	4(ra) # 80003f12 <iupdate>
    80005f16:	b781                	j	80005e56 <sys_unlink+0xe0>
    return -1;
    80005f18:	557d                	li	a0,-1
    80005f1a:	a005                	j	80005f3a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f1c:	854a                	mv	a0,s2
    80005f1e:	ffffe097          	auipc	ra,0xffffe
    80005f22:	320080e7          	jalr	800(ra) # 8000423e <iunlockput>
  iunlockput(dp);
    80005f26:	8526                	mv	a0,s1
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	316080e7          	jalr	790(ra) # 8000423e <iunlockput>
  end_op();
    80005f30:	fffff097          	auipc	ra,0xfffff
    80005f34:	afe080e7          	jalr	-1282(ra) # 80004a2e <end_op>
  return -1;
    80005f38:	557d                	li	a0,-1
}
    80005f3a:	70ae                	ld	ra,232(sp)
    80005f3c:	740e                	ld	s0,224(sp)
    80005f3e:	64ee                	ld	s1,216(sp)
    80005f40:	694e                	ld	s2,208(sp)
    80005f42:	69ae                	ld	s3,200(sp)
    80005f44:	616d                	addi	sp,sp,240
    80005f46:	8082                	ret

0000000080005f48 <sys_open>:

uint64
sys_open(void)
{
    80005f48:	7131                	addi	sp,sp,-192
    80005f4a:	fd06                	sd	ra,184(sp)
    80005f4c:	f922                	sd	s0,176(sp)
    80005f4e:	f526                	sd	s1,168(sp)
    80005f50:	f14a                	sd	s2,160(sp)
    80005f52:	ed4e                	sd	s3,152(sp)
    80005f54:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f56:	08000613          	li	a2,128
    80005f5a:	f5040593          	addi	a1,s0,-176
    80005f5e:	4501                	li	a0,0
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	54e080e7          	jalr	1358(ra) # 800034ae <argstr>
    return -1;
    80005f68:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f6a:	0c054163          	bltz	a0,8000602c <sys_open+0xe4>
    80005f6e:	f4c40593          	addi	a1,s0,-180
    80005f72:	4505                	li	a0,1
    80005f74:	ffffd097          	auipc	ra,0xffffd
    80005f78:	4f6080e7          	jalr	1270(ra) # 8000346a <argint>
    80005f7c:	0a054863          	bltz	a0,8000602c <sys_open+0xe4>

  begin_op();
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	a2e080e7          	jalr	-1490(ra) # 800049ae <begin_op>

  if(omode & O_CREATE){
    80005f88:	f4c42783          	lw	a5,-180(s0)
    80005f8c:	2007f793          	andi	a5,a5,512
    80005f90:	cbdd                	beqz	a5,80006046 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f92:	4681                	li	a3,0
    80005f94:	4601                	li	a2,0
    80005f96:	4589                	li	a1,2
    80005f98:	f5040513          	addi	a0,s0,-176
    80005f9c:	00000097          	auipc	ra,0x0
    80005fa0:	972080e7          	jalr	-1678(ra) # 8000590e <create>
    80005fa4:	892a                	mv	s2,a0
    if(ip == 0){
    80005fa6:	c959                	beqz	a0,8000603c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005fa8:	04491703          	lh	a4,68(s2)
    80005fac:	478d                	li	a5,3
    80005fae:	00f71763          	bne	a4,a5,80005fbc <sys_open+0x74>
    80005fb2:	04695703          	lhu	a4,70(s2)
    80005fb6:	47a5                	li	a5,9
    80005fb8:	0ce7ec63          	bltu	a5,a4,80006090 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	e02080e7          	jalr	-510(ra) # 80004dbe <filealloc>
    80005fc4:	89aa                	mv	s3,a0
    80005fc6:	10050263          	beqz	a0,800060ca <sys_open+0x182>
    80005fca:	00000097          	auipc	ra,0x0
    80005fce:	902080e7          	jalr	-1790(ra) # 800058cc <fdalloc>
    80005fd2:	84aa                	mv	s1,a0
    80005fd4:	0e054663          	bltz	a0,800060c0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005fd8:	04491703          	lh	a4,68(s2)
    80005fdc:	478d                	li	a5,3
    80005fde:	0cf70463          	beq	a4,a5,800060a6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005fe2:	4789                	li	a5,2
    80005fe4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005fe8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005fec:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ff0:	f4c42783          	lw	a5,-180(s0)
    80005ff4:	0017c713          	xori	a4,a5,1
    80005ff8:	8b05                	andi	a4,a4,1
    80005ffa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ffe:	0037f713          	andi	a4,a5,3
    80006002:	00e03733          	snez	a4,a4
    80006006:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000600a:	4007f793          	andi	a5,a5,1024
    8000600e:	c791                	beqz	a5,8000601a <sys_open+0xd2>
    80006010:	04491703          	lh	a4,68(s2)
    80006014:	4789                	li	a5,2
    80006016:	08f70f63          	beq	a4,a5,800060b4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000601a:	854a                	mv	a0,s2
    8000601c:	ffffe097          	auipc	ra,0xffffe
    80006020:	082080e7          	jalr	130(ra) # 8000409e <iunlock>
  end_op();
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	a0a080e7          	jalr	-1526(ra) # 80004a2e <end_op>

  return fd;
}
    8000602c:	8526                	mv	a0,s1
    8000602e:	70ea                	ld	ra,184(sp)
    80006030:	744a                	ld	s0,176(sp)
    80006032:	74aa                	ld	s1,168(sp)
    80006034:	790a                	ld	s2,160(sp)
    80006036:	69ea                	ld	s3,152(sp)
    80006038:	6129                	addi	sp,sp,192
    8000603a:	8082                	ret
      end_op();
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	9f2080e7          	jalr	-1550(ra) # 80004a2e <end_op>
      return -1;
    80006044:	b7e5                	j	8000602c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006046:	f5040513          	addi	a0,s0,-176
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	748080e7          	jalr	1864(ra) # 80004792 <namei>
    80006052:	892a                	mv	s2,a0
    80006054:	c905                	beqz	a0,80006084 <sys_open+0x13c>
    ilock(ip);
    80006056:	ffffe097          	auipc	ra,0xffffe
    8000605a:	f86080e7          	jalr	-122(ra) # 80003fdc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000605e:	04491703          	lh	a4,68(s2)
    80006062:	4785                	li	a5,1
    80006064:	f4f712e3          	bne	a4,a5,80005fa8 <sys_open+0x60>
    80006068:	f4c42783          	lw	a5,-180(s0)
    8000606c:	dba1                	beqz	a5,80005fbc <sys_open+0x74>
      iunlockput(ip);
    8000606e:	854a                	mv	a0,s2
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	1ce080e7          	jalr	462(ra) # 8000423e <iunlockput>
      end_op();
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	9b6080e7          	jalr	-1610(ra) # 80004a2e <end_op>
      return -1;
    80006080:	54fd                	li	s1,-1
    80006082:	b76d                	j	8000602c <sys_open+0xe4>
      end_op();
    80006084:	fffff097          	auipc	ra,0xfffff
    80006088:	9aa080e7          	jalr	-1622(ra) # 80004a2e <end_op>
      return -1;
    8000608c:	54fd                	li	s1,-1
    8000608e:	bf79                	j	8000602c <sys_open+0xe4>
    iunlockput(ip);
    80006090:	854a                	mv	a0,s2
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	1ac080e7          	jalr	428(ra) # 8000423e <iunlockput>
    end_op();
    8000609a:	fffff097          	auipc	ra,0xfffff
    8000609e:	994080e7          	jalr	-1644(ra) # 80004a2e <end_op>
    return -1;
    800060a2:	54fd                	li	s1,-1
    800060a4:	b761                	j	8000602c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800060a6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800060aa:	04691783          	lh	a5,70(s2)
    800060ae:	02f99223          	sh	a5,36(s3)
    800060b2:	bf2d                	j	80005fec <sys_open+0xa4>
    itrunc(ip);
    800060b4:	854a                	mv	a0,s2
    800060b6:	ffffe097          	auipc	ra,0xffffe
    800060ba:	034080e7          	jalr	52(ra) # 800040ea <itrunc>
    800060be:	bfb1                	j	8000601a <sys_open+0xd2>
      fileclose(f);
    800060c0:	854e                	mv	a0,s3
    800060c2:	fffff097          	auipc	ra,0xfffff
    800060c6:	db8080e7          	jalr	-584(ra) # 80004e7a <fileclose>
    iunlockput(ip);
    800060ca:	854a                	mv	a0,s2
    800060cc:	ffffe097          	auipc	ra,0xffffe
    800060d0:	172080e7          	jalr	370(ra) # 8000423e <iunlockput>
    end_op();
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	95a080e7          	jalr	-1702(ra) # 80004a2e <end_op>
    return -1;
    800060dc:	54fd                	li	s1,-1
    800060de:	b7b9                	j	8000602c <sys_open+0xe4>

00000000800060e0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060e0:	7175                	addi	sp,sp,-144
    800060e2:	e506                	sd	ra,136(sp)
    800060e4:	e122                	sd	s0,128(sp)
    800060e6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800060e8:	fffff097          	auipc	ra,0xfffff
    800060ec:	8c6080e7          	jalr	-1850(ra) # 800049ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800060f0:	08000613          	li	a2,128
    800060f4:	f7040593          	addi	a1,s0,-144
    800060f8:	4501                	li	a0,0
    800060fa:	ffffd097          	auipc	ra,0xffffd
    800060fe:	3b4080e7          	jalr	948(ra) # 800034ae <argstr>
    80006102:	02054963          	bltz	a0,80006134 <sys_mkdir+0x54>
    80006106:	4681                	li	a3,0
    80006108:	4601                	li	a2,0
    8000610a:	4585                	li	a1,1
    8000610c:	f7040513          	addi	a0,s0,-144
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	7fe080e7          	jalr	2046(ra) # 8000590e <create>
    80006118:	cd11                	beqz	a0,80006134 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	124080e7          	jalr	292(ra) # 8000423e <iunlockput>
  end_op();
    80006122:	fffff097          	auipc	ra,0xfffff
    80006126:	90c080e7          	jalr	-1780(ra) # 80004a2e <end_op>
  return 0;
    8000612a:	4501                	li	a0,0
}
    8000612c:	60aa                	ld	ra,136(sp)
    8000612e:	640a                	ld	s0,128(sp)
    80006130:	6149                	addi	sp,sp,144
    80006132:	8082                	ret
    end_op();
    80006134:	fffff097          	auipc	ra,0xfffff
    80006138:	8fa080e7          	jalr	-1798(ra) # 80004a2e <end_op>
    return -1;
    8000613c:	557d                	li	a0,-1
    8000613e:	b7fd                	j	8000612c <sys_mkdir+0x4c>

0000000080006140 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006140:	7135                	addi	sp,sp,-160
    80006142:	ed06                	sd	ra,152(sp)
    80006144:	e922                	sd	s0,144(sp)
    80006146:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006148:	fffff097          	auipc	ra,0xfffff
    8000614c:	866080e7          	jalr	-1946(ra) # 800049ae <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006150:	08000613          	li	a2,128
    80006154:	f7040593          	addi	a1,s0,-144
    80006158:	4501                	li	a0,0
    8000615a:	ffffd097          	auipc	ra,0xffffd
    8000615e:	354080e7          	jalr	852(ra) # 800034ae <argstr>
    80006162:	04054a63          	bltz	a0,800061b6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006166:	f6c40593          	addi	a1,s0,-148
    8000616a:	4505                	li	a0,1
    8000616c:	ffffd097          	auipc	ra,0xffffd
    80006170:	2fe080e7          	jalr	766(ra) # 8000346a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006174:	04054163          	bltz	a0,800061b6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006178:	f6840593          	addi	a1,s0,-152
    8000617c:	4509                	li	a0,2
    8000617e:	ffffd097          	auipc	ra,0xffffd
    80006182:	2ec080e7          	jalr	748(ra) # 8000346a <argint>
     argint(1, &major) < 0 ||
    80006186:	02054863          	bltz	a0,800061b6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000618a:	f6841683          	lh	a3,-152(s0)
    8000618e:	f6c41603          	lh	a2,-148(s0)
    80006192:	458d                	li	a1,3
    80006194:	f7040513          	addi	a0,s0,-144
    80006198:	fffff097          	auipc	ra,0xfffff
    8000619c:	776080e7          	jalr	1910(ra) # 8000590e <create>
     argint(2, &minor) < 0 ||
    800061a0:	c919                	beqz	a0,800061b6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061a2:	ffffe097          	auipc	ra,0xffffe
    800061a6:	09c080e7          	jalr	156(ra) # 8000423e <iunlockput>
  end_op();
    800061aa:	fffff097          	auipc	ra,0xfffff
    800061ae:	884080e7          	jalr	-1916(ra) # 80004a2e <end_op>
  return 0;
    800061b2:	4501                	li	a0,0
    800061b4:	a031                	j	800061c0 <sys_mknod+0x80>
    end_op();
    800061b6:	fffff097          	auipc	ra,0xfffff
    800061ba:	878080e7          	jalr	-1928(ra) # 80004a2e <end_op>
    return -1;
    800061be:	557d                	li	a0,-1
}
    800061c0:	60ea                	ld	ra,152(sp)
    800061c2:	644a                	ld	s0,144(sp)
    800061c4:	610d                	addi	sp,sp,160
    800061c6:	8082                	ret

00000000800061c8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800061c8:	7135                	addi	sp,sp,-160
    800061ca:	ed06                	sd	ra,152(sp)
    800061cc:	e922                	sd	s0,144(sp)
    800061ce:	e526                	sd	s1,136(sp)
    800061d0:	e14a                	sd	s2,128(sp)
    800061d2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061d4:	ffffc097          	auipc	ra,0xffffc
    800061d8:	c6e080e7          	jalr	-914(ra) # 80001e42 <myproc>
    800061dc:	892a                	mv	s2,a0
  
  begin_op();
    800061de:	ffffe097          	auipc	ra,0xffffe
    800061e2:	7d0080e7          	jalr	2000(ra) # 800049ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061e6:	08000613          	li	a2,128
    800061ea:	f6040593          	addi	a1,s0,-160
    800061ee:	4501                	li	a0,0
    800061f0:	ffffd097          	auipc	ra,0xffffd
    800061f4:	2be080e7          	jalr	702(ra) # 800034ae <argstr>
    800061f8:	04054b63          	bltz	a0,8000624e <sys_chdir+0x86>
    800061fc:	f6040513          	addi	a0,s0,-160
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	592080e7          	jalr	1426(ra) # 80004792 <namei>
    80006208:	84aa                	mv	s1,a0
    8000620a:	c131                	beqz	a0,8000624e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000620c:	ffffe097          	auipc	ra,0xffffe
    80006210:	dd0080e7          	jalr	-560(ra) # 80003fdc <ilock>
  if(ip->type != T_DIR){
    80006214:	04449703          	lh	a4,68(s1)
    80006218:	4785                	li	a5,1
    8000621a:	04f71063          	bne	a4,a5,8000625a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000621e:	8526                	mv	a0,s1
    80006220:	ffffe097          	auipc	ra,0xffffe
    80006224:	e7e080e7          	jalr	-386(ra) # 8000409e <iunlock>
  iput(p->cwd);
    80006228:	17093503          	ld	a0,368(s2)
    8000622c:	ffffe097          	auipc	ra,0xffffe
    80006230:	f6a080e7          	jalr	-150(ra) # 80004196 <iput>
  end_op();
    80006234:	ffffe097          	auipc	ra,0xffffe
    80006238:	7fa080e7          	jalr	2042(ra) # 80004a2e <end_op>
  p->cwd = ip;
    8000623c:	16993823          	sd	s1,368(s2)
  return 0;
    80006240:	4501                	li	a0,0
}
    80006242:	60ea                	ld	ra,152(sp)
    80006244:	644a                	ld	s0,144(sp)
    80006246:	64aa                	ld	s1,136(sp)
    80006248:	690a                	ld	s2,128(sp)
    8000624a:	610d                	addi	sp,sp,160
    8000624c:	8082                	ret
    end_op();
    8000624e:	ffffe097          	auipc	ra,0xffffe
    80006252:	7e0080e7          	jalr	2016(ra) # 80004a2e <end_op>
    return -1;
    80006256:	557d                	li	a0,-1
    80006258:	b7ed                	j	80006242 <sys_chdir+0x7a>
    iunlockput(ip);
    8000625a:	8526                	mv	a0,s1
    8000625c:	ffffe097          	auipc	ra,0xffffe
    80006260:	fe2080e7          	jalr	-30(ra) # 8000423e <iunlockput>
    end_op();
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	7ca080e7          	jalr	1994(ra) # 80004a2e <end_op>
    return -1;
    8000626c:	557d                	li	a0,-1
    8000626e:	bfd1                	j	80006242 <sys_chdir+0x7a>

0000000080006270 <sys_exec>:

uint64
sys_exec(void)
{
    80006270:	7145                	addi	sp,sp,-464
    80006272:	e786                	sd	ra,456(sp)
    80006274:	e3a2                	sd	s0,448(sp)
    80006276:	ff26                	sd	s1,440(sp)
    80006278:	fb4a                	sd	s2,432(sp)
    8000627a:	f74e                	sd	s3,424(sp)
    8000627c:	f352                	sd	s4,416(sp)
    8000627e:	ef56                	sd	s5,408(sp)
    80006280:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006282:	08000613          	li	a2,128
    80006286:	f4040593          	addi	a1,s0,-192
    8000628a:	4501                	li	a0,0
    8000628c:	ffffd097          	auipc	ra,0xffffd
    80006290:	222080e7          	jalr	546(ra) # 800034ae <argstr>
    return -1;
    80006294:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006296:	0c054a63          	bltz	a0,8000636a <sys_exec+0xfa>
    8000629a:	e3840593          	addi	a1,s0,-456
    8000629e:	4505                	li	a0,1
    800062a0:	ffffd097          	auipc	ra,0xffffd
    800062a4:	1ec080e7          	jalr	492(ra) # 8000348c <argaddr>
    800062a8:	0c054163          	bltz	a0,8000636a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800062ac:	10000613          	li	a2,256
    800062b0:	4581                	li	a1,0
    800062b2:	e4040513          	addi	a0,s0,-448
    800062b6:	ffffb097          	auipc	ra,0xffffb
    800062ba:	a4e080e7          	jalr	-1458(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062be:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800062c2:	89a6                	mv	s3,s1
    800062c4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062c6:	02000a13          	li	s4,32
    800062ca:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062ce:	00391513          	slli	a0,s2,0x3
    800062d2:	e3040593          	addi	a1,s0,-464
    800062d6:	e3843783          	ld	a5,-456(s0)
    800062da:	953e                	add	a0,a0,a5
    800062dc:	ffffd097          	auipc	ra,0xffffd
    800062e0:	0f4080e7          	jalr	244(ra) # 800033d0 <fetchaddr>
    800062e4:	02054a63          	bltz	a0,80006318 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800062e8:	e3043783          	ld	a5,-464(s0)
    800062ec:	c3b9                	beqz	a5,80006332 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800062ee:	ffffb097          	auipc	ra,0xffffb
    800062f2:	806080e7          	jalr	-2042(ra) # 80000af4 <kalloc>
    800062f6:	85aa                	mv	a1,a0
    800062f8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800062fc:	cd11                	beqz	a0,80006318 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800062fe:	6605                	lui	a2,0x1
    80006300:	e3043503          	ld	a0,-464(s0)
    80006304:	ffffd097          	auipc	ra,0xffffd
    80006308:	11e080e7          	jalr	286(ra) # 80003422 <fetchstr>
    8000630c:	00054663          	bltz	a0,80006318 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006310:	0905                	addi	s2,s2,1
    80006312:	09a1                	addi	s3,s3,8
    80006314:	fb491be3          	bne	s2,s4,800062ca <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006318:	10048913          	addi	s2,s1,256
    8000631c:	6088                	ld	a0,0(s1)
    8000631e:	c529                	beqz	a0,80006368 <sys_exec+0xf8>
    kfree(argv[i]);
    80006320:	ffffa097          	auipc	ra,0xffffa
    80006324:	6d8080e7          	jalr	1752(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006328:	04a1                	addi	s1,s1,8
    8000632a:	ff2499e3          	bne	s1,s2,8000631c <sys_exec+0xac>
  return -1;
    8000632e:	597d                	li	s2,-1
    80006330:	a82d                	j	8000636a <sys_exec+0xfa>
      argv[i] = 0;
    80006332:	0a8e                	slli	s5,s5,0x3
    80006334:	fc040793          	addi	a5,s0,-64
    80006338:	9abe                	add	s5,s5,a5
    8000633a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000633e:	e4040593          	addi	a1,s0,-448
    80006342:	f4040513          	addi	a0,s0,-192
    80006346:	fffff097          	auipc	ra,0xfffff
    8000634a:	194080e7          	jalr	404(ra) # 800054da <exec>
    8000634e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006350:	10048993          	addi	s3,s1,256
    80006354:	6088                	ld	a0,0(s1)
    80006356:	c911                	beqz	a0,8000636a <sys_exec+0xfa>
    kfree(argv[i]);
    80006358:	ffffa097          	auipc	ra,0xffffa
    8000635c:	6a0080e7          	jalr	1696(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006360:	04a1                	addi	s1,s1,8
    80006362:	ff3499e3          	bne	s1,s3,80006354 <sys_exec+0xe4>
    80006366:	a011                	j	8000636a <sys_exec+0xfa>
  return -1;
    80006368:	597d                	li	s2,-1
}
    8000636a:	854a                	mv	a0,s2
    8000636c:	60be                	ld	ra,456(sp)
    8000636e:	641e                	ld	s0,448(sp)
    80006370:	74fa                	ld	s1,440(sp)
    80006372:	795a                	ld	s2,432(sp)
    80006374:	79ba                	ld	s3,424(sp)
    80006376:	7a1a                	ld	s4,416(sp)
    80006378:	6afa                	ld	s5,408(sp)
    8000637a:	6179                	addi	sp,sp,464
    8000637c:	8082                	ret

000000008000637e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000637e:	7139                	addi	sp,sp,-64
    80006380:	fc06                	sd	ra,56(sp)
    80006382:	f822                	sd	s0,48(sp)
    80006384:	f426                	sd	s1,40(sp)
    80006386:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006388:	ffffc097          	auipc	ra,0xffffc
    8000638c:	aba080e7          	jalr	-1350(ra) # 80001e42 <myproc>
    80006390:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006392:	fd840593          	addi	a1,s0,-40
    80006396:	4501                	li	a0,0
    80006398:	ffffd097          	auipc	ra,0xffffd
    8000639c:	0f4080e7          	jalr	244(ra) # 8000348c <argaddr>
    return -1;
    800063a0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800063a2:	0e054063          	bltz	a0,80006482 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800063a6:	fc840593          	addi	a1,s0,-56
    800063aa:	fd040513          	addi	a0,s0,-48
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	dfc080e7          	jalr	-516(ra) # 800051aa <pipealloc>
    return -1;
    800063b6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063b8:	0c054563          	bltz	a0,80006482 <sys_pipe+0x104>
  fd0 = -1;
    800063bc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063c0:	fd043503          	ld	a0,-48(s0)
    800063c4:	fffff097          	auipc	ra,0xfffff
    800063c8:	508080e7          	jalr	1288(ra) # 800058cc <fdalloc>
    800063cc:	fca42223          	sw	a0,-60(s0)
    800063d0:	08054c63          	bltz	a0,80006468 <sys_pipe+0xea>
    800063d4:	fc843503          	ld	a0,-56(s0)
    800063d8:	fffff097          	auipc	ra,0xfffff
    800063dc:	4f4080e7          	jalr	1268(ra) # 800058cc <fdalloc>
    800063e0:	fca42023          	sw	a0,-64(s0)
    800063e4:	06054863          	bltz	a0,80006454 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063e8:	4691                	li	a3,4
    800063ea:	fc440613          	addi	a2,s0,-60
    800063ee:	fd843583          	ld	a1,-40(s0)
    800063f2:	78a8                	ld	a0,112(s1)
    800063f4:	ffffb097          	auipc	ra,0xffffb
    800063f8:	2a2080e7          	jalr	674(ra) # 80001696 <copyout>
    800063fc:	02054063          	bltz	a0,8000641c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006400:	4691                	li	a3,4
    80006402:	fc040613          	addi	a2,s0,-64
    80006406:	fd843583          	ld	a1,-40(s0)
    8000640a:	0591                	addi	a1,a1,4
    8000640c:	78a8                	ld	a0,112(s1)
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	288080e7          	jalr	648(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006416:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006418:	06055563          	bgez	a0,80006482 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000641c:	fc442783          	lw	a5,-60(s0)
    80006420:	07f9                	addi	a5,a5,30
    80006422:	078e                	slli	a5,a5,0x3
    80006424:	97a6                	add	a5,a5,s1
    80006426:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000642a:	fc042503          	lw	a0,-64(s0)
    8000642e:	0579                	addi	a0,a0,30
    80006430:	050e                	slli	a0,a0,0x3
    80006432:	9526                	add	a0,a0,s1
    80006434:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006438:	fd043503          	ld	a0,-48(s0)
    8000643c:	fffff097          	auipc	ra,0xfffff
    80006440:	a3e080e7          	jalr	-1474(ra) # 80004e7a <fileclose>
    fileclose(wf);
    80006444:	fc843503          	ld	a0,-56(s0)
    80006448:	fffff097          	auipc	ra,0xfffff
    8000644c:	a32080e7          	jalr	-1486(ra) # 80004e7a <fileclose>
    return -1;
    80006450:	57fd                	li	a5,-1
    80006452:	a805                	j	80006482 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006454:	fc442783          	lw	a5,-60(s0)
    80006458:	0007c863          	bltz	a5,80006468 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000645c:	01e78513          	addi	a0,a5,30
    80006460:	050e                	slli	a0,a0,0x3
    80006462:	9526                	add	a0,a0,s1
    80006464:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006468:	fd043503          	ld	a0,-48(s0)
    8000646c:	fffff097          	auipc	ra,0xfffff
    80006470:	a0e080e7          	jalr	-1522(ra) # 80004e7a <fileclose>
    fileclose(wf);
    80006474:	fc843503          	ld	a0,-56(s0)
    80006478:	fffff097          	auipc	ra,0xfffff
    8000647c:	a02080e7          	jalr	-1534(ra) # 80004e7a <fileclose>
    return -1;
    80006480:	57fd                	li	a5,-1
}
    80006482:	853e                	mv	a0,a5
    80006484:	70e2                	ld	ra,56(sp)
    80006486:	7442                	ld	s0,48(sp)
    80006488:	74a2                	ld	s1,40(sp)
    8000648a:	6121                	addi	sp,sp,64
    8000648c:	8082                	ret
	...

0000000080006490 <kernelvec>:
    80006490:	7111                	addi	sp,sp,-256
    80006492:	e006                	sd	ra,0(sp)
    80006494:	e40a                	sd	sp,8(sp)
    80006496:	e80e                	sd	gp,16(sp)
    80006498:	ec12                	sd	tp,24(sp)
    8000649a:	f016                	sd	t0,32(sp)
    8000649c:	f41a                	sd	t1,40(sp)
    8000649e:	f81e                	sd	t2,48(sp)
    800064a0:	fc22                	sd	s0,56(sp)
    800064a2:	e0a6                	sd	s1,64(sp)
    800064a4:	e4aa                	sd	a0,72(sp)
    800064a6:	e8ae                	sd	a1,80(sp)
    800064a8:	ecb2                	sd	a2,88(sp)
    800064aa:	f0b6                	sd	a3,96(sp)
    800064ac:	f4ba                	sd	a4,104(sp)
    800064ae:	f8be                	sd	a5,112(sp)
    800064b0:	fcc2                	sd	a6,120(sp)
    800064b2:	e146                	sd	a7,128(sp)
    800064b4:	e54a                	sd	s2,136(sp)
    800064b6:	e94e                	sd	s3,144(sp)
    800064b8:	ed52                	sd	s4,152(sp)
    800064ba:	f156                	sd	s5,160(sp)
    800064bc:	f55a                	sd	s6,168(sp)
    800064be:	f95e                	sd	s7,176(sp)
    800064c0:	fd62                	sd	s8,184(sp)
    800064c2:	e1e6                	sd	s9,192(sp)
    800064c4:	e5ea                	sd	s10,200(sp)
    800064c6:	e9ee                	sd	s11,208(sp)
    800064c8:	edf2                	sd	t3,216(sp)
    800064ca:	f1f6                	sd	t4,224(sp)
    800064cc:	f5fa                	sd	t5,232(sp)
    800064ce:	f9fe                	sd	t6,240(sp)
    800064d0:	dcdfc0ef          	jal	ra,8000329c <kerneltrap>
    800064d4:	6082                	ld	ra,0(sp)
    800064d6:	6122                	ld	sp,8(sp)
    800064d8:	61c2                	ld	gp,16(sp)
    800064da:	7282                	ld	t0,32(sp)
    800064dc:	7322                	ld	t1,40(sp)
    800064de:	73c2                	ld	t2,48(sp)
    800064e0:	7462                	ld	s0,56(sp)
    800064e2:	6486                	ld	s1,64(sp)
    800064e4:	6526                	ld	a0,72(sp)
    800064e6:	65c6                	ld	a1,80(sp)
    800064e8:	6666                	ld	a2,88(sp)
    800064ea:	7686                	ld	a3,96(sp)
    800064ec:	7726                	ld	a4,104(sp)
    800064ee:	77c6                	ld	a5,112(sp)
    800064f0:	7866                	ld	a6,120(sp)
    800064f2:	688a                	ld	a7,128(sp)
    800064f4:	692a                	ld	s2,136(sp)
    800064f6:	69ca                	ld	s3,144(sp)
    800064f8:	6a6a                	ld	s4,152(sp)
    800064fa:	7a8a                	ld	s5,160(sp)
    800064fc:	7b2a                	ld	s6,168(sp)
    800064fe:	7bca                	ld	s7,176(sp)
    80006500:	7c6a                	ld	s8,184(sp)
    80006502:	6c8e                	ld	s9,192(sp)
    80006504:	6d2e                	ld	s10,200(sp)
    80006506:	6dce                	ld	s11,208(sp)
    80006508:	6e6e                	ld	t3,216(sp)
    8000650a:	7e8e                	ld	t4,224(sp)
    8000650c:	7f2e                	ld	t5,232(sp)
    8000650e:	7fce                	ld	t6,240(sp)
    80006510:	6111                	addi	sp,sp,256
    80006512:	10200073          	sret
    80006516:	00000013          	nop
    8000651a:	00000013          	nop
    8000651e:	0001                	nop

0000000080006520 <timervec>:
    80006520:	34051573          	csrrw	a0,mscratch,a0
    80006524:	e10c                	sd	a1,0(a0)
    80006526:	e510                	sd	a2,8(a0)
    80006528:	e914                	sd	a3,16(a0)
    8000652a:	6d0c                	ld	a1,24(a0)
    8000652c:	7110                	ld	a2,32(a0)
    8000652e:	6194                	ld	a3,0(a1)
    80006530:	96b2                	add	a3,a3,a2
    80006532:	e194                	sd	a3,0(a1)
    80006534:	4589                	li	a1,2
    80006536:	14459073          	csrw	sip,a1
    8000653a:	6914                	ld	a3,16(a0)
    8000653c:	6510                	ld	a2,8(a0)
    8000653e:	610c                	ld	a1,0(a0)
    80006540:	34051573          	csrrw	a0,mscratch,a0
    80006544:	30200073          	mret
	...

000000008000654a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000654a:	1141                	addi	sp,sp,-16
    8000654c:	e422                	sd	s0,8(sp)
    8000654e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006550:	0c0007b7          	lui	a5,0xc000
    80006554:	4705                	li	a4,1
    80006556:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006558:	c3d8                	sw	a4,4(a5)
}
    8000655a:	6422                	ld	s0,8(sp)
    8000655c:	0141                	addi	sp,sp,16
    8000655e:	8082                	ret

0000000080006560 <plicinithart>:

void
plicinithart(void)
{
    80006560:	1141                	addi	sp,sp,-16
    80006562:	e406                	sd	ra,8(sp)
    80006564:	e022                	sd	s0,0(sp)
    80006566:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006568:	ffffc097          	auipc	ra,0xffffc
    8000656c:	8ae080e7          	jalr	-1874(ra) # 80001e16 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006570:	0085171b          	slliw	a4,a0,0x8
    80006574:	0c0027b7          	lui	a5,0xc002
    80006578:	97ba                	add	a5,a5,a4
    8000657a:	40200713          	li	a4,1026
    8000657e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006582:	00d5151b          	slliw	a0,a0,0xd
    80006586:	0c2017b7          	lui	a5,0xc201
    8000658a:	953e                	add	a0,a0,a5
    8000658c:	00052023          	sw	zero,0(a0)
}
    80006590:	60a2                	ld	ra,8(sp)
    80006592:	6402                	ld	s0,0(sp)
    80006594:	0141                	addi	sp,sp,16
    80006596:	8082                	ret

0000000080006598 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006598:	1141                	addi	sp,sp,-16
    8000659a:	e406                	sd	ra,8(sp)
    8000659c:	e022                	sd	s0,0(sp)
    8000659e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065a0:	ffffc097          	auipc	ra,0xffffc
    800065a4:	876080e7          	jalr	-1930(ra) # 80001e16 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800065a8:	00d5179b          	slliw	a5,a0,0xd
    800065ac:	0c201537          	lui	a0,0xc201
    800065b0:	953e                	add	a0,a0,a5
  return irq;
}
    800065b2:	4148                	lw	a0,4(a0)
    800065b4:	60a2                	ld	ra,8(sp)
    800065b6:	6402                	ld	s0,0(sp)
    800065b8:	0141                	addi	sp,sp,16
    800065ba:	8082                	ret

00000000800065bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800065bc:	1101                	addi	sp,sp,-32
    800065be:	ec06                	sd	ra,24(sp)
    800065c0:	e822                	sd	s0,16(sp)
    800065c2:	e426                	sd	s1,8(sp)
    800065c4:	1000                	addi	s0,sp,32
    800065c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800065c8:	ffffc097          	auipc	ra,0xffffc
    800065cc:	84e080e7          	jalr	-1970(ra) # 80001e16 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800065d0:	00d5151b          	slliw	a0,a0,0xd
    800065d4:	0c2017b7          	lui	a5,0xc201
    800065d8:	97aa                	add	a5,a5,a0
    800065da:	c3c4                	sw	s1,4(a5)
}
    800065dc:	60e2                	ld	ra,24(sp)
    800065de:	6442                	ld	s0,16(sp)
    800065e0:	64a2                	ld	s1,8(sp)
    800065e2:	6105                	addi	sp,sp,32
    800065e4:	8082                	ret

00000000800065e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065e6:	1141                	addi	sp,sp,-16
    800065e8:	e406                	sd	ra,8(sp)
    800065ea:	e022                	sd	s0,0(sp)
    800065ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800065ee:	479d                	li	a5,7
    800065f0:	06a7c963          	blt	a5,a0,80006662 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800065f4:	00016797          	auipc	a5,0x16
    800065f8:	a0c78793          	addi	a5,a5,-1524 # 8001c000 <disk>
    800065fc:	00a78733          	add	a4,a5,a0
    80006600:	6789                	lui	a5,0x2
    80006602:	97ba                	add	a5,a5,a4
    80006604:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006608:	e7ad                	bnez	a5,80006672 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000660a:	00451793          	slli	a5,a0,0x4
    8000660e:	00018717          	auipc	a4,0x18
    80006612:	9f270713          	addi	a4,a4,-1550 # 8001e000 <disk+0x2000>
    80006616:	6314                	ld	a3,0(a4)
    80006618:	96be                	add	a3,a3,a5
    8000661a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000661e:	6314                	ld	a3,0(a4)
    80006620:	96be                	add	a3,a3,a5
    80006622:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006626:	6314                	ld	a3,0(a4)
    80006628:	96be                	add	a3,a3,a5
    8000662a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000662e:	6318                	ld	a4,0(a4)
    80006630:	97ba                	add	a5,a5,a4
    80006632:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006636:	00016797          	auipc	a5,0x16
    8000663a:	9ca78793          	addi	a5,a5,-1590 # 8001c000 <disk>
    8000663e:	97aa                	add	a5,a5,a0
    80006640:	6509                	lui	a0,0x2
    80006642:	953e                	add	a0,a0,a5
    80006644:	4785                	li	a5,1
    80006646:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000664a:	00018517          	auipc	a0,0x18
    8000664e:	9ce50513          	addi	a0,a0,-1586 # 8001e018 <disk+0x2018>
    80006652:	ffffc097          	auipc	ra,0xffffc
    80006656:	39c080e7          	jalr	924(ra) # 800029ee <wakeup>
}
    8000665a:	60a2                	ld	ra,8(sp)
    8000665c:	6402                	ld	s0,0(sp)
    8000665e:	0141                	addi	sp,sp,16
    80006660:	8082                	ret
    panic("free_desc 1");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	35650513          	addi	a0,a0,854 # 800089b8 <syscalls+0x320>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006672:	00002517          	auipc	a0,0x2
    80006676:	35650513          	addi	a0,a0,854 # 800089c8 <syscalls+0x330>
    8000667a:	ffffa097          	auipc	ra,0xffffa
    8000667e:	ec4080e7          	jalr	-316(ra) # 8000053e <panic>

0000000080006682 <virtio_disk_init>:
{
    80006682:	1101                	addi	sp,sp,-32
    80006684:	ec06                	sd	ra,24(sp)
    80006686:	e822                	sd	s0,16(sp)
    80006688:	e426                	sd	s1,8(sp)
    8000668a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000668c:	00002597          	auipc	a1,0x2
    80006690:	34c58593          	addi	a1,a1,844 # 800089d8 <syscalls+0x340>
    80006694:	00018517          	auipc	a0,0x18
    80006698:	a9450513          	addi	a0,a0,-1388 # 8001e128 <disk+0x2128>
    8000669c:	ffffa097          	auipc	ra,0xffffa
    800066a0:	4b8080e7          	jalr	1208(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066a4:	100017b7          	lui	a5,0x10001
    800066a8:	4398                	lw	a4,0(a5)
    800066aa:	2701                	sext.w	a4,a4
    800066ac:	747277b7          	lui	a5,0x74727
    800066b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066b4:	0ef71163          	bne	a4,a5,80006796 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066b8:	100017b7          	lui	a5,0x10001
    800066bc:	43dc                	lw	a5,4(a5)
    800066be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066c0:	4705                	li	a4,1
    800066c2:	0ce79a63          	bne	a5,a4,80006796 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066c6:	100017b7          	lui	a5,0x10001
    800066ca:	479c                	lw	a5,8(a5)
    800066cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066ce:	4709                	li	a4,2
    800066d0:	0ce79363          	bne	a5,a4,80006796 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800066d4:	100017b7          	lui	a5,0x10001
    800066d8:	47d8                	lw	a4,12(a5)
    800066da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066dc:	554d47b7          	lui	a5,0x554d4
    800066e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066e4:	0af71963          	bne	a4,a5,80006796 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066e8:	100017b7          	lui	a5,0x10001
    800066ec:	4705                	li	a4,1
    800066ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f0:	470d                	li	a4,3
    800066f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800066f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800066f6:	c7ffe737          	lui	a4,0xc7ffe
    800066fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    800066fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006700:	2701                	sext.w	a4,a4
    80006702:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006704:	472d                	li	a4,11
    80006706:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006708:	473d                	li	a4,15
    8000670a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000670c:	6705                	lui	a4,0x1
    8000670e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006710:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006714:	5bdc                	lw	a5,52(a5)
    80006716:	2781                	sext.w	a5,a5
  if(max == 0)
    80006718:	c7d9                	beqz	a5,800067a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000671a:	471d                	li	a4,7
    8000671c:	08f77d63          	bgeu	a4,a5,800067b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006720:	100014b7          	lui	s1,0x10001
    80006724:	47a1                	li	a5,8
    80006726:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006728:	6609                	lui	a2,0x2
    8000672a:	4581                	li	a1,0
    8000672c:	00016517          	auipc	a0,0x16
    80006730:	8d450513          	addi	a0,a0,-1836 # 8001c000 <disk>
    80006734:	ffffa097          	auipc	ra,0xffffa
    80006738:	5d0080e7          	jalr	1488(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000673c:	00016717          	auipc	a4,0x16
    80006740:	8c470713          	addi	a4,a4,-1852 # 8001c000 <disk>
    80006744:	00c75793          	srli	a5,a4,0xc
    80006748:	2781                	sext.w	a5,a5
    8000674a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000674c:	00018797          	auipc	a5,0x18
    80006750:	8b478793          	addi	a5,a5,-1868 # 8001e000 <disk+0x2000>
    80006754:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006756:	00016717          	auipc	a4,0x16
    8000675a:	92a70713          	addi	a4,a4,-1750 # 8001c080 <disk+0x80>
    8000675e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006760:	00017717          	auipc	a4,0x17
    80006764:	8a070713          	addi	a4,a4,-1888 # 8001d000 <disk+0x1000>
    80006768:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000676a:	4705                	li	a4,1
    8000676c:	00e78c23          	sb	a4,24(a5)
    80006770:	00e78ca3          	sb	a4,25(a5)
    80006774:	00e78d23          	sb	a4,26(a5)
    80006778:	00e78da3          	sb	a4,27(a5)
    8000677c:	00e78e23          	sb	a4,28(a5)
    80006780:	00e78ea3          	sb	a4,29(a5)
    80006784:	00e78f23          	sb	a4,30(a5)
    80006788:	00e78fa3          	sb	a4,31(a5)
}
    8000678c:	60e2                	ld	ra,24(sp)
    8000678e:	6442                	ld	s0,16(sp)
    80006790:	64a2                	ld	s1,8(sp)
    80006792:	6105                	addi	sp,sp,32
    80006794:	8082                	ret
    panic("could not find virtio disk");
    80006796:	00002517          	auipc	a0,0x2
    8000679a:	25250513          	addi	a0,a0,594 # 800089e8 <syscalls+0x350>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800067a6:	00002517          	auipc	a0,0x2
    800067aa:	26250513          	addi	a0,a0,610 # 80008a08 <syscalls+0x370>
    800067ae:	ffffa097          	auipc	ra,0xffffa
    800067b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800067b6:	00002517          	auipc	a0,0x2
    800067ba:	27250513          	addi	a0,a0,626 # 80008a28 <syscalls+0x390>
    800067be:	ffffa097          	auipc	ra,0xffffa
    800067c2:	d80080e7          	jalr	-640(ra) # 8000053e <panic>

00000000800067c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067c6:	7159                	addi	sp,sp,-112
    800067c8:	f486                	sd	ra,104(sp)
    800067ca:	f0a2                	sd	s0,96(sp)
    800067cc:	eca6                	sd	s1,88(sp)
    800067ce:	e8ca                	sd	s2,80(sp)
    800067d0:	e4ce                	sd	s3,72(sp)
    800067d2:	e0d2                	sd	s4,64(sp)
    800067d4:	fc56                	sd	s5,56(sp)
    800067d6:	f85a                	sd	s6,48(sp)
    800067d8:	f45e                	sd	s7,40(sp)
    800067da:	f062                	sd	s8,32(sp)
    800067dc:	ec66                	sd	s9,24(sp)
    800067de:	e86a                	sd	s10,16(sp)
    800067e0:	1880                	addi	s0,sp,112
    800067e2:	892a                	mv	s2,a0
    800067e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067e6:	00c52c83          	lw	s9,12(a0)
    800067ea:	001c9c9b          	slliw	s9,s9,0x1
    800067ee:	1c82                	slli	s9,s9,0x20
    800067f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800067f4:	00018517          	auipc	a0,0x18
    800067f8:	93450513          	addi	a0,a0,-1740 # 8001e128 <disk+0x2128>
    800067fc:	ffffa097          	auipc	ra,0xffffa
    80006800:	3e8080e7          	jalr	1000(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006804:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006806:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006808:	00015b97          	auipc	s7,0x15
    8000680c:	7f8b8b93          	addi	s7,s7,2040 # 8001c000 <disk>
    80006810:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006812:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006814:	8a4e                	mv	s4,s3
    80006816:	a051                	j	8000689a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006818:	00fb86b3          	add	a3,s7,a5
    8000681c:	96da                	add	a3,a3,s6
    8000681e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006822:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006824:	0207c563          	bltz	a5,8000684e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006828:	2485                	addiw	s1,s1,1
    8000682a:	0711                	addi	a4,a4,4
    8000682c:	25548063          	beq	s1,s5,80006a6c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006830:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006832:	00017697          	auipc	a3,0x17
    80006836:	7e668693          	addi	a3,a3,2022 # 8001e018 <disk+0x2018>
    8000683a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000683c:	0006c583          	lbu	a1,0(a3)
    80006840:	fde1                	bnez	a1,80006818 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006842:	2785                	addiw	a5,a5,1
    80006844:	0685                	addi	a3,a3,1
    80006846:	ff879be3          	bne	a5,s8,8000683c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000684a:	57fd                	li	a5,-1
    8000684c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000684e:	02905a63          	blez	s1,80006882 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006852:	f9042503          	lw	a0,-112(s0)
    80006856:	00000097          	auipc	ra,0x0
    8000685a:	d90080e7          	jalr	-624(ra) # 800065e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000685e:	4785                	li	a5,1
    80006860:	0297d163          	bge	a5,s1,80006882 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006864:	f9442503          	lw	a0,-108(s0)
    80006868:	00000097          	auipc	ra,0x0
    8000686c:	d7e080e7          	jalr	-642(ra) # 800065e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006870:	4789                	li	a5,2
    80006872:	0097d863          	bge	a5,s1,80006882 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006876:	f9842503          	lw	a0,-104(s0)
    8000687a:	00000097          	auipc	ra,0x0
    8000687e:	d6c080e7          	jalr	-660(ra) # 800065e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006882:	00018597          	auipc	a1,0x18
    80006886:	8a658593          	addi	a1,a1,-1882 # 8001e128 <disk+0x2128>
    8000688a:	00017517          	auipc	a0,0x17
    8000688e:	78e50513          	addi	a0,a0,1934 # 8001e018 <disk+0x2018>
    80006892:	ffffc097          	auipc	ra,0xffffc
    80006896:	f5e080e7          	jalr	-162(ra) # 800027f0 <sleep>
  for(int i = 0; i < 3; i++){
    8000689a:	f9040713          	addi	a4,s0,-112
    8000689e:	84ce                	mv	s1,s3
    800068a0:	bf41                	j	80006830 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800068a2:	20058713          	addi	a4,a1,512
    800068a6:	00471693          	slli	a3,a4,0x4
    800068aa:	00015717          	auipc	a4,0x15
    800068ae:	75670713          	addi	a4,a4,1878 # 8001c000 <disk>
    800068b2:	9736                	add	a4,a4,a3
    800068b4:	4685                	li	a3,1
    800068b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068ba:	20058713          	addi	a4,a1,512
    800068be:	00471693          	slli	a3,a4,0x4
    800068c2:	00015717          	auipc	a4,0x15
    800068c6:	73e70713          	addi	a4,a4,1854 # 8001c000 <disk>
    800068ca:	9736                	add	a4,a4,a3
    800068cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800068d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068d4:	7679                	lui	a2,0xffffe
    800068d6:	963e                	add	a2,a2,a5
    800068d8:	00017697          	auipc	a3,0x17
    800068dc:	72868693          	addi	a3,a3,1832 # 8001e000 <disk+0x2000>
    800068e0:	6298                	ld	a4,0(a3)
    800068e2:	9732                	add	a4,a4,a2
    800068e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068e6:	6298                	ld	a4,0(a3)
    800068e8:	9732                	add	a4,a4,a2
    800068ea:	4541                	li	a0,16
    800068ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068ee:	6298                	ld	a4,0(a3)
    800068f0:	9732                	add	a4,a4,a2
    800068f2:	4505                	li	a0,1
    800068f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800068f8:	f9442703          	lw	a4,-108(s0)
    800068fc:	6288                	ld	a0,0(a3)
    800068fe:	962a                	add	a2,a2,a0
    80006900:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006904:	0712                	slli	a4,a4,0x4
    80006906:	6290                	ld	a2,0(a3)
    80006908:	963a                	add	a2,a2,a4
    8000690a:	05890513          	addi	a0,s2,88
    8000690e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006910:	6294                	ld	a3,0(a3)
    80006912:	96ba                	add	a3,a3,a4
    80006914:	40000613          	li	a2,1024
    80006918:	c690                	sw	a2,8(a3)
  if(write)
    8000691a:	140d0063          	beqz	s10,80006a5a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000691e:	00017697          	auipc	a3,0x17
    80006922:	6e26b683          	ld	a3,1762(a3) # 8001e000 <disk+0x2000>
    80006926:	96ba                	add	a3,a3,a4
    80006928:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000692c:	00015817          	auipc	a6,0x15
    80006930:	6d480813          	addi	a6,a6,1748 # 8001c000 <disk>
    80006934:	00017517          	auipc	a0,0x17
    80006938:	6cc50513          	addi	a0,a0,1740 # 8001e000 <disk+0x2000>
    8000693c:	6114                	ld	a3,0(a0)
    8000693e:	96ba                	add	a3,a3,a4
    80006940:	00c6d603          	lhu	a2,12(a3)
    80006944:	00166613          	ori	a2,a2,1
    80006948:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000694c:	f9842683          	lw	a3,-104(s0)
    80006950:	6110                	ld	a2,0(a0)
    80006952:	9732                	add	a4,a4,a2
    80006954:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006958:	20058613          	addi	a2,a1,512
    8000695c:	0612                	slli	a2,a2,0x4
    8000695e:	9642                	add	a2,a2,a6
    80006960:	577d                	li	a4,-1
    80006962:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006966:	00469713          	slli	a4,a3,0x4
    8000696a:	6114                	ld	a3,0(a0)
    8000696c:	96ba                	add	a3,a3,a4
    8000696e:	03078793          	addi	a5,a5,48
    80006972:	97c2                	add	a5,a5,a6
    80006974:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006976:	611c                	ld	a5,0(a0)
    80006978:	97ba                	add	a5,a5,a4
    8000697a:	4685                	li	a3,1
    8000697c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000697e:	611c                	ld	a5,0(a0)
    80006980:	97ba                	add	a5,a5,a4
    80006982:	4809                	li	a6,2
    80006984:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006988:	611c                	ld	a5,0(a0)
    8000698a:	973e                	add	a4,a4,a5
    8000698c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006990:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006994:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006998:	6518                	ld	a4,8(a0)
    8000699a:	00275783          	lhu	a5,2(a4)
    8000699e:	8b9d                	andi	a5,a5,7
    800069a0:	0786                	slli	a5,a5,0x1
    800069a2:	97ba                	add	a5,a5,a4
    800069a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800069a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800069ac:	6518                	ld	a4,8(a0)
    800069ae:	00275783          	lhu	a5,2(a4)
    800069b2:	2785                	addiw	a5,a5,1
    800069b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800069b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800069bc:	100017b7          	lui	a5,0x10001
    800069c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800069c4:	00492703          	lw	a4,4(s2)
    800069c8:	4785                	li	a5,1
    800069ca:	02f71163          	bne	a4,a5,800069ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800069ce:	00017997          	auipc	s3,0x17
    800069d2:	75a98993          	addi	s3,s3,1882 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    800069d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800069d8:	85ce                	mv	a1,s3
    800069da:	854a                	mv	a0,s2
    800069dc:	ffffc097          	auipc	ra,0xffffc
    800069e0:	e14080e7          	jalr	-492(ra) # 800027f0 <sleep>
  while(b->disk == 1) {
    800069e4:	00492783          	lw	a5,4(s2)
    800069e8:	fe9788e3          	beq	a5,s1,800069d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800069ec:	f9042903          	lw	s2,-112(s0)
    800069f0:	20090793          	addi	a5,s2,512
    800069f4:	00479713          	slli	a4,a5,0x4
    800069f8:	00015797          	auipc	a5,0x15
    800069fc:	60878793          	addi	a5,a5,1544 # 8001c000 <disk>
    80006a00:	97ba                	add	a5,a5,a4
    80006a02:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006a06:	00017997          	auipc	s3,0x17
    80006a0a:	5fa98993          	addi	s3,s3,1530 # 8001e000 <disk+0x2000>
    80006a0e:	00491713          	slli	a4,s2,0x4
    80006a12:	0009b783          	ld	a5,0(s3)
    80006a16:	97ba                	add	a5,a5,a4
    80006a18:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a1c:	854a                	mv	a0,s2
    80006a1e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a22:	00000097          	auipc	ra,0x0
    80006a26:	bc4080e7          	jalr	-1084(ra) # 800065e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a2a:	8885                	andi	s1,s1,1
    80006a2c:	f0ed                	bnez	s1,80006a0e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a2e:	00017517          	auipc	a0,0x17
    80006a32:	6fa50513          	addi	a0,a0,1786 # 8001e128 <disk+0x2128>
    80006a36:	ffffa097          	auipc	ra,0xffffa
    80006a3a:	274080e7          	jalr	628(ra) # 80000caa <release>
}
    80006a3e:	70a6                	ld	ra,104(sp)
    80006a40:	7406                	ld	s0,96(sp)
    80006a42:	64e6                	ld	s1,88(sp)
    80006a44:	6946                	ld	s2,80(sp)
    80006a46:	69a6                	ld	s3,72(sp)
    80006a48:	6a06                	ld	s4,64(sp)
    80006a4a:	7ae2                	ld	s5,56(sp)
    80006a4c:	7b42                	ld	s6,48(sp)
    80006a4e:	7ba2                	ld	s7,40(sp)
    80006a50:	7c02                	ld	s8,32(sp)
    80006a52:	6ce2                	ld	s9,24(sp)
    80006a54:	6d42                	ld	s10,16(sp)
    80006a56:	6165                	addi	sp,sp,112
    80006a58:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006a5a:	00017697          	auipc	a3,0x17
    80006a5e:	5a66b683          	ld	a3,1446(a3) # 8001e000 <disk+0x2000>
    80006a62:	96ba                	add	a3,a3,a4
    80006a64:	4609                	li	a2,2
    80006a66:	00c69623          	sh	a2,12(a3)
    80006a6a:	b5c9                	j	8000692c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a6c:	f9042583          	lw	a1,-112(s0)
    80006a70:	20058793          	addi	a5,a1,512
    80006a74:	0792                	slli	a5,a5,0x4
    80006a76:	00015517          	auipc	a0,0x15
    80006a7a:	63250513          	addi	a0,a0,1586 # 8001c0a8 <disk+0xa8>
    80006a7e:	953e                	add	a0,a0,a5
  if(write)
    80006a80:	e20d11e3          	bnez	s10,800068a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006a84:	20058713          	addi	a4,a1,512
    80006a88:	00471693          	slli	a3,a4,0x4
    80006a8c:	00015717          	auipc	a4,0x15
    80006a90:	57470713          	addi	a4,a4,1396 # 8001c000 <disk>
    80006a94:	9736                	add	a4,a4,a3
    80006a96:	0a072423          	sw	zero,168(a4)
    80006a9a:	b505                	j	800068ba <virtio_disk_rw+0xf4>

0000000080006a9c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a9c:	1101                	addi	sp,sp,-32
    80006a9e:	ec06                	sd	ra,24(sp)
    80006aa0:	e822                	sd	s0,16(sp)
    80006aa2:	e426                	sd	s1,8(sp)
    80006aa4:	e04a                	sd	s2,0(sp)
    80006aa6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006aa8:	00017517          	auipc	a0,0x17
    80006aac:	68050513          	addi	a0,a0,1664 # 8001e128 <disk+0x2128>
    80006ab0:	ffffa097          	auipc	ra,0xffffa
    80006ab4:	134080e7          	jalr	308(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006ab8:	10001737          	lui	a4,0x10001
    80006abc:	533c                	lw	a5,96(a4)
    80006abe:	8b8d                	andi	a5,a5,3
    80006ac0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ac2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ac6:	00017797          	auipc	a5,0x17
    80006aca:	53a78793          	addi	a5,a5,1338 # 8001e000 <disk+0x2000>
    80006ace:	6b94                	ld	a3,16(a5)
    80006ad0:	0207d703          	lhu	a4,32(a5)
    80006ad4:	0026d783          	lhu	a5,2(a3)
    80006ad8:	06f70163          	beq	a4,a5,80006b3a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006adc:	00015917          	auipc	s2,0x15
    80006ae0:	52490913          	addi	s2,s2,1316 # 8001c000 <disk>
    80006ae4:	00017497          	auipc	s1,0x17
    80006ae8:	51c48493          	addi	s1,s1,1308 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    80006aec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006af0:	6898                	ld	a4,16(s1)
    80006af2:	0204d783          	lhu	a5,32(s1)
    80006af6:	8b9d                	andi	a5,a5,7
    80006af8:	078e                	slli	a5,a5,0x3
    80006afa:	97ba                	add	a5,a5,a4
    80006afc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006afe:	20078713          	addi	a4,a5,512
    80006b02:	0712                	slli	a4,a4,0x4
    80006b04:	974a                	add	a4,a4,s2
    80006b06:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006b0a:	e731                	bnez	a4,80006b56 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b0c:	20078793          	addi	a5,a5,512
    80006b10:	0792                	slli	a5,a5,0x4
    80006b12:	97ca                	add	a5,a5,s2
    80006b14:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006b16:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b1a:	ffffc097          	auipc	ra,0xffffc
    80006b1e:	ed4080e7          	jalr	-300(ra) # 800029ee <wakeup>

    disk.used_idx += 1;
    80006b22:	0204d783          	lhu	a5,32(s1)
    80006b26:	2785                	addiw	a5,a5,1
    80006b28:	17c2                	slli	a5,a5,0x30
    80006b2a:	93c1                	srli	a5,a5,0x30
    80006b2c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b30:	6898                	ld	a4,16(s1)
    80006b32:	00275703          	lhu	a4,2(a4)
    80006b36:	faf71be3          	bne	a4,a5,80006aec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006b3a:	00017517          	auipc	a0,0x17
    80006b3e:	5ee50513          	addi	a0,a0,1518 # 8001e128 <disk+0x2128>
    80006b42:	ffffa097          	auipc	ra,0xffffa
    80006b46:	168080e7          	jalr	360(ra) # 80000caa <release>
}
    80006b4a:	60e2                	ld	ra,24(sp)
    80006b4c:	6442                	ld	s0,16(sp)
    80006b4e:	64a2                	ld	s1,8(sp)
    80006b50:	6902                	ld	s2,0(sp)
    80006b52:	6105                	addi	sp,sp,32
    80006b54:	8082                	ret
      panic("virtio_disk_intr status");
    80006b56:	00002517          	auipc	a0,0x2
    80006b5a:	ef250513          	addi	a0,a0,-270 # 80008a48 <syscalls+0x3b0>
    80006b5e:	ffffa097          	auipc	ra,0xffffa
    80006b62:	9e0080e7          	jalr	-1568(ra) # 8000053e <panic>

0000000080006b66 <cas>:
    80006b66:	100522af          	lr.w	t0,(a0)
    80006b6a:	00b29563          	bne	t0,a1,80006b74 <fail>
    80006b6e:	18c5252f          	sc.w	a0,a2,(a0)
    80006b72:	8082                	ret

0000000080006b74 <fail>:
    80006b74:	4505                	li	a0,1
    80006b76:	8082                	ret
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
