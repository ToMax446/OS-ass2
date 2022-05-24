
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
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
    80000068:	36c78793          	addi	a5,a5,876 # 800063d0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    80000130:	adc080e7          	jalr	-1316(ra) # 80002c08 <either_copyin>
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
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
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
    800001c8:	c30080e7          	jalr	-976(ra) # 80001df4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	4fa080e7          	jalr	1274(ra) # 800026ce <sleep>
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
    80000214:	9a2080e7          	jalr	-1630(ra) # 80002bb2 <either_copyout>
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
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a7e080e7          	jalr	-1410(ra) # 80000caa <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
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
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
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
    800002f6:	96c080e7          	jalr	-1684(ra) # 80002c5e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	430080e7          	jalr	1072(ra) # 80002876 <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	84878793          	addi	a5,a5,-1976 # 80021cc0 <devsw>
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
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
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
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
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
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
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
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
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
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
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
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
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
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
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
    800008a4:	fd6080e7          	jalr	-42(ra) # 80002876 <wakeup>
    
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
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
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
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	da2080e7          	jalr	-606(ra) # 800026ce <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
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
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
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
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
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
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
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
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
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
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
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
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
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
    80000b82:	252080e7          	jalr	594(ra) # 80001dd0 <mycpu>
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
    80000bb4:	220080e7          	jalr	544(ra) # 80001dd0 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	214080e7          	jalr	532(ra) # 80001dd0 <mycpu>
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
    80000bd8:	1fc080e7          	jalr	508(ra) # 80001dd0 <mycpu>
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
    80000c18:	1bc080e7          	jalr	444(ra) # 80001dd0 <mycpu>
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
    80000c56:	17e080e7          	jalr	382(ra) # 80001dd0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c5e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c60:	e78d                	bnez	a5,80000c8a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1){
    80000c62:	5d3c                	lw	a5,120(a0)
    80000c64:	02f05b63          	blez	a5,80000c9a <pop_off+0x50>
    panic("pop_off");}
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
    panic("pop_off");}
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
    80000ebe:	f06080e7          	jalr	-250(ra) # 80001dc0 <cpuid>
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
    80000eda:	eea080e7          	jalr	-278(ra) # 80001dc0 <cpuid>
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
    80000efc:	f3a080e7          	jalr	-198(ra) # 80002e32 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	510080e7          	jalr	1296(ra) # 80006410 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	526080e7          	jalr	1318(ra) # 8000242e <scheduler>
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
    80000f6c:	ce8080e7          	jalr	-792(ra) # 80001c50 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	e9a080e7          	jalr	-358(ra) # 80002e0a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	eba080e7          	jalr	-326(ra) # 80002e32 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	47a080e7          	jalr	1146(ra) # 800063fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	488080e7          	jalr	1160(ra) # 80006410 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	660080e7          	jalr	1632(ra) # 800035f0 <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	cf0080e7          	jalr	-784(ra) # 80003c88 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	c9a080e7          	jalr	-870(ra) # 80004c3a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	58a080e7          	jalr	1418(ra) # 80006532 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	1e2080e7          	jalr	482(ra) # 80002192 <userinit>
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
    80001268:	956080e7          	jalr	-1706(ra) # 80001bba <proc_mapstacks>
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

0000000080001862 <leastUsedCPU>:
//     id++;
//   }
//   printf("chosen cpu %d\n", idMin);
//   return idMin;
// }
int leastUsedCPU(){ // get the CPU with least amount of processes
    80001862:	1141                	addi	sp,sp,-16
    80001864:	e422                	sd	s0,8(sp)
    80001866:	0800                	addi	s0,sp,16
  uint64 min = cpus[0].admittedProcs;
    80001868:	00010797          	auipc	a5,0x10
    8000186c:	a3878793          	addi	a5,a5,-1480 # 800112a0 <cpus>
    80001870:	63d4                	ld	a3,128(a5)
  // int id = 0;
  int idMin = 0;
    80001872:	4501                	li	a0,0
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    80001874:	00010617          	auipc	a2,0x10
    80001878:	e6c60613          	addi	a2,a2,-404 # 800116e0 <cpus_ll>
  // printf("%d\n", c-cpus);
    uint64 procsNum = c->admittedProcs;
    if (procsNum < min){
      min = procsNum;
      idMin = c-cpus;
    8000187c:	883e                	mv	a6,a5
    8000187e:	00006597          	auipc	a1,0x6
    80001882:	78258593          	addi	a1,a1,1922 # 80008000 <etext>
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    80001886:	08878793          	addi	a5,a5,136
    8000188a:	00c78d63          	beq	a5,a2,800018a4 <leastUsedCPU+0x42>
    uint64 procsNum = c->admittedProcs;
    8000188e:	63d8                	ld	a4,128(a5)
    if (procsNum < min){
    80001890:	fed77be3          	bgeu	a4,a3,80001886 <leastUsedCPU+0x24>
      idMin = c-cpus;
    80001894:	41078533          	sub	a0,a5,a6
    80001898:	850d                	srai	a0,a0,0x3
    8000189a:	6194                	ld	a3,0(a1)
    8000189c:	02d5053b          	mulw	a0,a0,a3
    uint64 procsNum = c->admittedProcs;
    800018a0:	86ba                	mv	a3,a4
    800018a2:	b7d5                	j	80001886 <leastUsedCPU+0x24>
    // id += procsNum;
    // id += idMin;
  }
  return idMin;
  ;
}
    800018a4:	6422                	ld	s0,8(sp)
    800018a6:	0141                	addi	sp,sp,16
    800018a8:	8082                	ret

00000000800018aa <remove_from_list>:


int
remove_from_list(int p_index, int *list, struct spinlock *lock_list){
    800018aa:	7159                	addi	sp,sp,-112
    800018ac:	f486                	sd	ra,104(sp)
    800018ae:	f0a2                	sd	s0,96(sp)
    800018b0:	eca6                	sd	s1,88(sp)
    800018b2:	e8ca                	sd	s2,80(sp)
    800018b4:	e4ce                	sd	s3,72(sp)
    800018b6:	e0d2                	sd	s4,64(sp)
    800018b8:	fc56                	sd	s5,56(sp)
    800018ba:	f85a                	sd	s6,48(sp)
    800018bc:	f45e                	sd	s7,40(sp)
    800018be:	f062                	sd	s8,32(sp)
    800018c0:	ec66                	sd	s9,24(sp)
    800018c2:	e86a                	sd	s10,16(sp)
    800018c4:	e46e                	sd	s11,8(sp)
    800018c6:	1880                	addi	s0,sp,112
    800018c8:	89aa                	mv	s3,a0
    800018ca:	8a2e                	mv	s4,a1
    800018cc:	84b2                	mv	s1,a2
  acquire(lock_list);
    800018ce:	8532                	mv	a0,a2
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	314080e7          	jalr	788(ra) # 80000be4 <acquire>
  if(*list == -1){
    800018d8:	000a2903          	lw	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018dc:	57fd                	li	a5,-1
    800018de:	08f90263          	beq	s2,a5,80001962 <remove_from_list+0xb8>
    release(lock_list);
    return -1;
  }
  release(lock_list);
    800018e2:	8526                	mv	a0,s1
    800018e4:	fffff097          	auipc	ra,0xfffff
    800018e8:	3c6080e7          	jalr	966(ra) # 80000caa <release>
  struct proc *p = 0;
  acquire(lock_list);
    800018ec:	8526                	mv	a0,s1
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	2f6080e7          	jalr	758(ra) # 80000be4 <acquire>
  if(*list == p_index){
    800018f6:	000a2783          	lw	a5,0(s4)
    800018fa:	07378b63          	beq	a5,s3,80001970 <remove_from_list+0xc6>
    *list = p->next;
    release(&p->linked_list_lock);
    release(lock_list);
    return 0;
  }
  release(lock_list);
    800018fe:	8526                	mv	a0,s1
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	3aa080e7          	jalr	938(ra) # 80000caa <release>
  int inList = 0;
  struct proc *pred_proc = &proc[*list];
    80001908:	000a2503          	lw	a0,0(s4)
    8000190c:	18800493          	li	s1,392
    80001910:	02950533          	mul	a0,a0,s1
    80001914:	00010917          	auipc	s2,0x10
    80001918:	f6490913          	addi	s2,s2,-156 # 80011878 <proc>
    8000191c:	01250db3          	add	s11,a0,s2
  acquire(&pred_proc->linked_list_lock);
    80001920:	04050513          	addi	a0,a0,64
    80001924:	954a                	add	a0,a0,s2
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	2be080e7          	jalr	702(ra) # 80000be4 <acquire>
  p = &proc[pred_proc->next];
    8000192e:	03cda503          	lw	a0,60(s11)
    80001932:	2501                	sext.w	a0,a0
    80001934:	02950533          	mul	a0,a0,s1
    80001938:	012504b3          	add	s1,a0,s2
  acquire(&p->linked_list_lock);
    8000193c:	04050513          	addi	a0,a0,64
    80001940:	954a                	add	a0,a0,s2
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	2a2080e7          	jalr	674(ra) # 80000be4 <acquire>
  int done = 0;
    8000194a:	4901                	li	s2,0
  int inList = 0;
    8000194c:	4d01                	li	s10,0
  while(!done){
    if (pred_proc->next == -1){
    8000194e:	5afd                	li	s5,-1
      done = 1;
    80001950:	4c85                	li	s9,1
    80001952:	8c66                	mv	s8,s9
    80001954:	18800b93          	li	s7,392
      pred_proc->next = p->next;
      continue;
    }
    release(&pred_proc->linked_list_lock);
    pred_proc = p;
    p = &proc[p->next];
    80001958:	00010a17          	auipc	s4,0x10
    8000195c:	f20a0a13          	addi	s4,s4,-224 # 80011878 <proc>
  while(!done){
    80001960:	a8b5                	j	800019dc <remove_from_list+0x132>
    release(lock_list);
    80001962:	8526                	mv	a0,s1
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	346080e7          	jalr	838(ra) # 80000caa <release>
    return -1;
    8000196c:	89ca                	mv	s3,s2
    8000196e:	a845                	j	80001a1e <remove_from_list+0x174>
    acquire(&p->linked_list_lock);
    80001970:	18800a93          	li	s5,392
    80001974:	035989b3          	mul	s3,s3,s5
    80001978:	04098913          	addi	s2,s3,64 # 1040 <_entry-0x7fffefc0>
    8000197c:	00010a97          	auipc	s5,0x10
    80001980:	efca8a93          	addi	s5,s5,-260 # 80011878 <proc>
    80001984:	9956                	add	s2,s2,s5
    80001986:	854a                	mv	a0,s2
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	25c080e7          	jalr	604(ra) # 80000be4 <acquire>
    *list = p->next;
    80001990:	9ace                	add	s5,s5,s3
    80001992:	03caa783          	lw	a5,60(s5)
    80001996:	00fa2023          	sw	a5,0(s4)
    release(&p->linked_list_lock);
    8000199a:	854a                	mv	a0,s2
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	30e080e7          	jalr	782(ra) # 80000caa <release>
    release(lock_list);
    800019a4:	8526                	mv	a0,s1
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	304080e7          	jalr	772(ra) # 80000caa <release>
    return 0;
    800019ae:	4981                	li	s3,0
    800019b0:	a0bd                	j	80001a1e <remove_from_list+0x174>
    release(&pred_proc->linked_list_lock);
    800019b2:	040d8513          	addi	a0,s11,64
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	2f4080e7          	jalr	756(ra) # 80000caa <release>
    p = &proc[p->next];
    800019be:	5cdc                	lw	a5,60(s1)
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	037787b3          	mul	a5,a5,s7
    800019c6:	01478b33          	add	s6,a5,s4
    acquire(&p->linked_list_lock);
    800019ca:	04078513          	addi	a0,a5,64
    800019ce:	9552                	add	a0,a0,s4
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	214080e7          	jalr	532(ra) # 80000be4 <acquire>
    800019d8:	8da6                	mv	s11,s1
    p = &proc[p->next];
    800019da:	84da                	mv	s1,s6
  while(!done){
    800019dc:	02091363          	bnez	s2,80001a02 <remove_from_list+0x158>
    if (pred_proc->next == -1){
    800019e0:	03cda783          	lw	a5,60(s11)
    800019e4:	2781                	sext.w	a5,a5
    800019e6:	01578b63          	beq	a5,s5,800019fc <remove_from_list+0x152>
    if(p->index == p_index){
    800019ea:	5c9c                	lw	a5,56(s1)
    800019ec:	fd3793e3          	bne	a5,s3,800019b2 <remove_from_list+0x108>
      pred_proc->next = p->next;
    800019f0:	5cdc                	lw	a5,60(s1)
    800019f2:	2781                	sext.w	a5,a5
    800019f4:	02fdae23          	sw	a5,60(s11)
      done = 1;
    800019f8:	8966                	mv	s2,s9
      continue;
    800019fa:	b7cd                	j	800019dc <remove_from_list+0x132>
      done = 1;
    800019fc:	8962                	mv	s2,s8
      inList = 1;
    800019fe:	8d62                	mv	s10,s8
    80001a00:	bff1                	j	800019dc <remove_from_list+0x132>
  }
  release(&p->linked_list_lock);
    80001a02:	04048513          	addi	a0,s1,64
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	2a4080e7          	jalr	676(ra) # 80000caa <release>
  release(&pred_proc->linked_list_lock); 
    80001a0e:	040d8513          	addi	a0,s11,64
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	298080e7          	jalr	664(ra) # 80000caa <release>
  if (inList)
    80001a1a:	020d1263          	bnez	s10,80001a3e <remove_from_list+0x194>
    return -1;
  return p_index;
}
    80001a1e:	854e                	mv	a0,s3
    80001a20:	70a6                	ld	ra,104(sp)
    80001a22:	7406                	ld	s0,96(sp)
    80001a24:	64e6                	ld	s1,88(sp)
    80001a26:	6946                	ld	s2,80(sp)
    80001a28:	69a6                	ld	s3,72(sp)
    80001a2a:	6a06                	ld	s4,64(sp)
    80001a2c:	7ae2                	ld	s5,56(sp)
    80001a2e:	7b42                	ld	s6,48(sp)
    80001a30:	7ba2                	ld	s7,40(sp)
    80001a32:	7c02                	ld	s8,32(sp)
    80001a34:	6ce2                	ld	s9,24(sp)
    80001a36:	6d42                	ld	s10,16(sp)
    80001a38:	6da2                	ld	s11,8(sp)
    80001a3a:	6165                	addi	sp,sp,112
    80001a3c:	8082                	ret
    return -1;
    80001a3e:	59fd                	li	s3,-1
    80001a40:	bff9                	j	80001a1e <remove_from_list+0x174>

0000000080001a42 <insert_cs>:
//   }
//   return ret;
// }

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001a42:	7139                	addi	sp,sp,-64
    80001a44:	fc06                	sd	ra,56(sp)
    80001a46:	f822                	sd	s0,48(sp)
    80001a48:	f426                	sd	s1,40(sp)
    80001a4a:	f04a                	sd	s2,32(sp)
    80001a4c:	ec4e                	sd	s3,24(sp)
    80001a4e:	e852                	sd	s4,16(sp)
    80001a50:	e456                	sd	s5,8(sp)
    80001a52:	e05a                	sd	s6,0(sp)
    80001a54:	0080                	addi	s0,sp,64
    80001a56:	892a                	mv	s2,a0
    80001a58:	8aae                	mv	s5,a1
  int curr = pred->index; 
  struct spinlock *pred_lock;
  while (curr != -1) {
    80001a5a:	5d18                	lw	a4,56(a0)
    80001a5c:	57fd                	li	a5,-1
    80001a5e:	04f70a63          	beq	a4,a5,80001ab2 <insert_cs+0x70>
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    if(pred->next!=-1){
    80001a62:	59fd                	li	s3,-1
    80001a64:	18800b13          	li	s6,392
      pred_lock=&pred->linked_list_lock; // caller acquired
      pred = &proc[pred->next];
    80001a68:	00010a17          	auipc	s4,0x10
    80001a6c:	e10a0a13          	addi	s4,s4,-496 # 80011878 <proc>
    80001a70:	a81d                	j	80001aa6 <insert_cs+0x64>
      pred_lock=&pred->linked_list_lock; // caller acquired
    80001a72:	04090513          	addi	a0,s2,64
      pred = &proc[pred->next];
    80001a76:	03c92483          	lw	s1,60(s2)
    80001a7a:	2481                	sext.w	s1,s1
    80001a7c:	036484b3          	mul	s1,s1,s6
    80001a80:	01448933          	add	s2,s1,s4
      release(pred_lock);
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	226080e7          	jalr	550(ra) # 80000caa <release>
      acquire(&pred->linked_list_lock);
    80001a8c:	04048493          	addi	s1,s1,64
    80001a90:	009a0533          	add	a0,s4,s1
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	150080e7          	jalr	336(ra) # 80000be4 <acquire>
    }
    curr = pred->next;
    80001a9c:	03c92783          	lw	a5,60(s2)
    80001aa0:	2781                	sext.w	a5,a5
  while (curr != -1) {
    80001aa2:	01378863          	beq	a5,s3,80001ab2 <insert_cs+0x70>
    if(pred->next!=-1){
    80001aa6:	03c92783          	lw	a5,60(s2)
    80001aaa:	2781                	sext.w	a5,a5
    80001aac:	ff3788e3          	beq	a5,s3,80001a9c <insert_cs+0x5a>
    80001ab0:	b7c9                	j	80001a72 <insert_cs+0x30>
    }
    pred->next = p->index;
    80001ab2:	038aa783          	lw	a5,56(s5)
    80001ab6:	02f92e23          	sw	a5,60(s2)
    release(&pred->linked_list_lock);      
    80001aba:	04090513          	addi	a0,s2,64
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	1ec080e7          	jalr	492(ra) # 80000caa <release>
    p->next=-1;
    80001ac6:	57fd                	li	a5,-1
    80001ac8:	02faae23          	sw	a5,60(s5)
    return p->index;
}
    80001acc:	038aa503          	lw	a0,56(s5)
    80001ad0:	70e2                	ld	ra,56(sp)
    80001ad2:	7442                	ld	s0,48(sp)
    80001ad4:	74a2                	ld	s1,40(sp)
    80001ad6:	7902                	ld	s2,32(sp)
    80001ad8:	69e2                	ld	s3,24(sp)
    80001ada:	6a42                	ld	s4,16(sp)
    80001adc:	6aa2                	ld	s5,8(sp)
    80001ade:	6b02                	ld	s6,0(sp)
    80001ae0:	6121                	addi	sp,sp,64
    80001ae2:	8082                	ret

0000000080001ae4 <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock *lock_list){;
    80001ae4:	7139                	addi	sp,sp,-64
    80001ae6:	fc06                	sd	ra,56(sp)
    80001ae8:	f822                	sd	s0,48(sp)
    80001aea:	f426                	sd	s1,40(sp)
    80001aec:	f04a                	sd	s2,32(sp)
    80001aee:	ec4e                	sd	s3,24(sp)
    80001af0:	e852                	sd	s4,16(sp)
    80001af2:	e456                	sd	s5,8(sp)
    80001af4:	0080                	addi	s0,sp,64
    80001af6:	84aa                	mv	s1,a0
    80001af8:	892e                	mv	s2,a1
    80001afa:	89b2                	mv	s3,a2
  int ret=-1;
  acquire(lock_list);
    80001afc:	8532                	mv	a0,a2
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	0e6080e7          	jalr	230(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001b06:	00092703          	lw	a4,0(s2)
    80001b0a:	57fd                	li	a5,-1
    80001b0c:	04f70d63          	beq	a4,a5,80001b66 <insert_to_list+0x82>
    release(&proc[p_index].linked_list_lock);
    ret = p_index;
    release(lock_list);
  }
  else{
    release(lock_list);
    80001b10:	854e                	mv	a0,s3
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	198080e7          	jalr	408(ra) # 80000caa <release>
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    80001b1a:	00092903          	lw	s2,0(s2)
    80001b1e:	18800a13          	li	s4,392
    80001b22:	03490933          	mul	s2,s2,s4
    acquire(&pred->linked_list_lock);
    80001b26:	04090513          	addi	a0,s2,64
    80001b2a:	00010997          	auipc	s3,0x10
    80001b2e:	d4e98993          	addi	s3,s3,-690 # 80011878 <proc>
    80001b32:	954e                	add	a0,a0,s3
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	0b0080e7          	jalr	176(ra) # 80000be4 <acquire>
    ret = insert_cs(pred, &proc[p_index]);
    80001b3c:	034485b3          	mul	a1,s1,s4
    80001b40:	95ce                	add	a1,a1,s3
    80001b42:	01298533          	add	a0,s3,s2
    80001b46:	00000097          	auipc	ra,0x0
    80001b4a:	efc080e7          	jalr	-260(ra) # 80001a42 <insert_cs>
  }
if(ret == -1){
    80001b4e:	57fd                	li	a5,-1
    80001b50:	04f50d63          	beq	a0,a5,80001baa <insert_to_list+0xc6>
  panic("insert is failed");
}
return ret;
}
    80001b54:	70e2                	ld	ra,56(sp)
    80001b56:	7442                	ld	s0,48(sp)
    80001b58:	74a2                	ld	s1,40(sp)
    80001b5a:	7902                	ld	s2,32(sp)
    80001b5c:	69e2                	ld	s3,24(sp)
    80001b5e:	6a42                	ld	s4,16(sp)
    80001b60:	6aa2                	ld	s5,8(sp)
    80001b62:	6121                	addi	sp,sp,64
    80001b64:	8082                	ret
    *list=p_index;
    80001b66:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001b6a:	18800a13          	li	s4,392
    80001b6e:	03448ab3          	mul	s5,s1,s4
    80001b72:	040a8913          	addi	s2,s5,64
    80001b76:	00010a17          	auipc	s4,0x10
    80001b7a:	d02a0a13          	addi	s4,s4,-766 # 80011878 <proc>
    80001b7e:	9952                	add	s2,s2,s4
    80001b80:	854a                	mv	a0,s2
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	062080e7          	jalr	98(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001b8a:	9a56                	add	s4,s4,s5
    80001b8c:	57fd                	li	a5,-1
    80001b8e:	02fa2e23          	sw	a5,60(s4)
    release(&proc[p_index].linked_list_lock);
    80001b92:	854a                	mv	a0,s2
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	116080e7          	jalr	278(ra) # 80000caa <release>
    release(lock_list);
    80001b9c:	854e                	mv	a0,s3
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	10c080e7          	jalr	268(ra) # 80000caa <release>
    ret = p_index;
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	b75d                	j	80001b4e <insert_to_list+0x6a>
  panic("insert is failed");
    80001baa:	00006517          	auipc	a0,0x6
    80001bae:	65e50513          	addi	a0,a0,1630 # 80008208 <digits+0x1c8>
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	98c080e7          	jalr	-1652(ra) # 8000053e <panic>

0000000080001bba <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001bba:	7139                	addi	sp,sp,-64
    80001bbc:	fc06                	sd	ra,56(sp)
    80001bbe:	f822                	sd	s0,48(sp)
    80001bc0:	f426                	sd	s1,40(sp)
    80001bc2:	f04a                	sd	s2,32(sp)
    80001bc4:	ec4e                	sd	s3,24(sp)
    80001bc6:	e852                	sd	s4,16(sp)
    80001bc8:	e456                	sd	s5,8(sp)
    80001bca:	e05a                	sd	s6,0(sp)
    80001bcc:	0080                	addi	s0,sp,64
    80001bce:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd0:	00010497          	auipc	s1,0x10
    80001bd4:	ca848493          	addi	s1,s1,-856 # 80011878 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001bd8:	8b26                	mv	s6,s1
    80001bda:	00006a97          	auipc	s5,0x6
    80001bde:	42ea8a93          	addi	s5,s5,1070 # 80008008 <etext+0x8>
    80001be2:	04000937          	lui	s2,0x4000
    80001be6:	197d                	addi	s2,s2,-1
    80001be8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	00016a17          	auipc	s4,0x16
    80001bee:	e8ea0a13          	addi	s4,s4,-370 # 80017a78 <tickslock>
    char *pa = kalloc();
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	f02080e7          	jalr	-254(ra) # 80000af4 <kalloc>
    80001bfa:	862a                	mv	a2,a0
    if(pa == 0)
    80001bfc:	c131                	beqz	a0,80001c40 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001bfe:	416485b3          	sub	a1,s1,s6
    80001c02:	858d                	srai	a1,a1,0x3
    80001c04:	000ab783          	ld	a5,0(s5)
    80001c08:	02f585b3          	mul	a1,a1,a5
    80001c0c:	2585                	addiw	a1,a1,1
    80001c0e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c12:	4719                	li	a4,6
    80001c14:	6685                	lui	a3,0x1
    80001c16:	40b905b3          	sub	a1,s2,a1
    80001c1a:	854e                	mv	a0,s3
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	558080e7          	jalr	1368(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c24:	18848493          	addi	s1,s1,392
    80001c28:	fd4495e3          	bne	s1,s4,80001bf2 <proc_mapstacks+0x38>
  }
}
    80001c2c:	70e2                	ld	ra,56(sp)
    80001c2e:	7442                	ld	s0,48(sp)
    80001c30:	74a2                	ld	s1,40(sp)
    80001c32:	7902                	ld	s2,32(sp)
    80001c34:	69e2                	ld	s3,24(sp)
    80001c36:	6a42                	ld	s4,16(sp)
    80001c38:	6aa2                	ld	s5,8(sp)
    80001c3a:	6b02                	ld	s6,0(sp)
    80001c3c:	6121                	addi	sp,sp,64
    80001c3e:	8082                	ret
      panic("kalloc");
    80001c40:	00006517          	auipc	a0,0x6
    80001c44:	5e050513          	addi	a0,a0,1504 # 80008220 <digits+0x1e0>
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	8f6080e7          	jalr	-1802(ra) # 8000053e <panic>

0000000080001c50 <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80001c50:	711d                	addi	sp,sp,-96
    80001c52:	ec86                	sd	ra,88(sp)
    80001c54:	e8a2                	sd	s0,80(sp)
    80001c56:	e4a6                	sd	s1,72(sp)
    80001c58:	e0ca                	sd	s2,64(sp)
    80001c5a:	fc4e                	sd	s3,56(sp)
    80001c5c:	f852                	sd	s4,48(sp)
    80001c5e:	f456                	sd	s5,40(sp)
    80001c60:	f05a                	sd	s6,32(sp)
    80001c62:	ec5e                	sd	s7,24(sp)
    80001c64:	e862                	sd	s8,16(sp)
    80001c66:	e466                	sd	s9,8(sp)
    80001c68:	e06a                	sd	s10,0(sp)
    80001c6a:	1080                	addi	s0,sp,96
  struct proc *p;

  for (int i = 0; i<CPUS; i++){
    80001c6c:	00010717          	auipc	a4,0x10
    80001c70:	a7470713          	addi	a4,a4,-1420 # 800116e0 <cpus_ll>
    80001c74:	0000f797          	auipc	a5,0xf
    80001c78:	62c78793          	addi	a5,a5,1580 # 800112a0 <cpus>
    80001c7c:	863a                	mv	a2,a4
    cpus_ll[i] = -1;
    80001c7e:	56fd                	li	a3,-1
    80001c80:	c314                	sw	a3,0(a4)
    // cpu_usage[i] = 0;    // set initial cpu's admitted to 0
    cpus[i].admittedProcs = 0;
    80001c82:	0807b023          	sd	zero,128(a5)
  for (int i = 0; i<CPUS; i++){
    80001c86:	0711                	addi	a4,a4,4
    80001c88:	08878793          	addi	a5,a5,136
    80001c8c:	fec79ae3          	bne	a5,a2,80001c80 <procinit+0x30>
}
  initlock(&pid_lock, "nextpid");
    80001c90:	00006597          	auipc	a1,0x6
    80001c94:	59858593          	addi	a1,a1,1432 # 80008228 <digits+0x1e8>
    80001c98:	00010517          	auipc	a0,0x10
    80001c9c:	a6850513          	addi	a0,a0,-1432 # 80011700 <pid_lock>
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	eb4080e7          	jalr	-332(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ca8:	00006597          	auipc	a1,0x6
    80001cac:	58858593          	addi	a1,a1,1416 # 80008230 <digits+0x1f0>
    80001cb0:	00010517          	auipc	a0,0x10
    80001cb4:	a6850513          	addi	a0,a0,-1432 # 80011718 <wait_lock>
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	e9c080e7          	jalr	-356(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001cc0:	00006597          	auipc	a1,0x6
    80001cc4:	58058593          	addi	a1,a1,1408 # 80008240 <digits+0x200>
    80001cc8:	00010517          	auipc	a0,0x10
    80001ccc:	a6850513          	addi	a0,a0,-1432 # 80011730 <sleeping_head>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	e84080e7          	jalr	-380(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001cd8:	00006597          	auipc	a1,0x6
    80001cdc:	57858593          	addi	a1,a1,1400 # 80008250 <digits+0x210>
    80001ce0:	00010517          	auipc	a0,0x10
    80001ce4:	a6850513          	addi	a0,a0,-1432 # 80011748 <zombie_head>
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	e6c080e7          	jalr	-404(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001cf0:	00006597          	auipc	a1,0x6
    80001cf4:	57058593          	addi	a1,a1,1392 # 80008260 <digits+0x220>
    80001cf8:	00010517          	auipc	a0,0x10
    80001cfc:	a6850513          	addi	a0,a0,-1432 # 80011760 <unused_head>
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	e54080e7          	jalr	-428(ra) # 80000b54 <initlock>
  
  int i=0; //added
    80001d08:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0a:	00010497          	auipc	s1,0x10
    80001d0e:	b6e48493          	addi	s1,s1,-1170 # 80011878 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001d12:	8d26                	mv	s10,s1
    80001d14:	00006c97          	auipc	s9,0x6
    80001d18:	2f4cbc83          	ld	s9,756(s9) # 80008008 <etext+0x8>
    80001d1c:	040009b7          	lui	s3,0x4000
    80001d20:	19fd                	addi	s3,s3,-1
    80001d22:	09b2                	slli	s3,s3,0xc
      //added:
      p->state = UNUSED; 
      p->index = i;
      p->next = -1;
    80001d24:	5c7d                	li	s8,-1
      p->cpu_num = 0;
      initlock(&p->lock, "proc");
    80001d26:	00006b97          	auipc	s7,0x6
    80001d2a:	54ab8b93          	addi	s7,s7,1354 # 80008270 <digits+0x230>
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
    80001d2e:	00006b17          	auipc	s6,0x6
    80001d32:	54ab0b13          	addi	s6,s6,1354 # 80008278 <digits+0x238>
      i++;
      insert_to_list(p->index, &unused, &unused_head);
    80001d36:	00010a97          	auipc	s5,0x10
    80001d3a:	a2aa8a93          	addi	s5,s5,-1494 # 80011760 <unused_head>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d3e:	00016a17          	auipc	s4,0x16
    80001d42:	d3aa0a13          	addi	s4,s4,-710 # 80017a78 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001d46:	41a487b3          	sub	a5,s1,s10
    80001d4a:	878d                	srai	a5,a5,0x3
    80001d4c:	039787b3          	mul	a5,a5,s9
    80001d50:	2785                	addiw	a5,a5,1
    80001d52:	00d7979b          	slliw	a5,a5,0xd
    80001d56:	40f987b3          	sub	a5,s3,a5
    80001d5a:	f0bc                	sd	a5,96(s1)
      p->state = UNUSED; 
    80001d5c:	0004ac23          	sw	zero,24(s1)
      p->index = i;
    80001d60:	0324ac23          	sw	s2,56(s1)
      p->next = -1;
    80001d64:	0384ae23          	sw	s8,60(s1)
      p->cpu_num = 0;
    80001d68:	0204aa23          	sw	zero,52(s1)
      initlock(&p->lock, "proc");
    80001d6c:	85de                	mv	a1,s7
    80001d6e:	8526                	mv	a0,s1
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	de4080e7          	jalr	-540(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, name);
    80001d78:	85da                	mv	a1,s6
    80001d7a:	04048513          	addi	a0,s1,64
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	dd6080e7          	jalr	-554(ra) # 80000b54 <initlock>
      i++;
    80001d86:	2905                	addiw	s2,s2,1
      insert_to_list(p->index, &unused, &unused_head);
    80001d88:	8656                	mv	a2,s5
    80001d8a:	00007597          	auipc	a1,0x7
    80001d8e:	b3a58593          	addi	a1,a1,-1222 # 800088c4 <unused>
    80001d92:	5c88                	lw	a0,56(s1)
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	d50080e7          	jalr	-688(ra) # 80001ae4 <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d9c:	18848493          	addi	s1,s1,392
    80001da0:	fb4493e3          	bne	s1,s4,80001d46 <procinit+0xf6>
  
  
  //printf("the head of the unused list is %d, and the value of next is:%d\n ",unused,proc[unused].next);
      
  //printf("finished procinit\n");
}
    80001da4:	60e6                	ld	ra,88(sp)
    80001da6:	6446                	ld	s0,80(sp)
    80001da8:	64a6                	ld	s1,72(sp)
    80001daa:	6906                	ld	s2,64(sp)
    80001dac:	79e2                	ld	s3,56(sp)
    80001dae:	7a42                	ld	s4,48(sp)
    80001db0:	7aa2                	ld	s5,40(sp)
    80001db2:	7b02                	ld	s6,32(sp)
    80001db4:	6be2                	ld	s7,24(sp)
    80001db6:	6c42                	ld	s8,16(sp)
    80001db8:	6ca2                	ld	s9,8(sp)
    80001dba:	6d02                	ld	s10,0(sp)
    80001dbc:	6125                	addi	sp,sp,96
    80001dbe:	8082                	ret

0000000080001dc0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001dc0:	1141                	addi	sp,sp,-16
    80001dc2:	e422                	sd	s0,8(sp)
    80001dc4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dc6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001dc8:	2501                	sext.w	a0,a0
    80001dca:	6422                	ld	s0,8(sp)
    80001dcc:	0141                	addi	sp,sp,16
    80001dce:	8082                	ret

0000000080001dd0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001dd0:	1141                	addi	sp,sp,-16
    80001dd2:	e422                	sd	s0,8(sp)
    80001dd4:	0800                	addi	s0,sp,16
    80001dd6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001dd8:	0007851b          	sext.w	a0,a5
    80001ddc:	00451793          	slli	a5,a0,0x4
    80001de0:	97aa                	add	a5,a5,a0
    80001de2:	078e                	slli	a5,a5,0x3
  return c;
}
    80001de4:	0000f517          	auipc	a0,0xf
    80001de8:	4bc50513          	addi	a0,a0,1212 # 800112a0 <cpus>
    80001dec:	953e                	add	a0,a0,a5
    80001dee:	6422                	ld	s0,8(sp)
    80001df0:	0141                	addi	sp,sp,16
    80001df2:	8082                	ret

0000000080001df4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001df4:	1101                	addi	sp,sp,-32
    80001df6:	ec06                	sd	ra,24(sp)
    80001df8:	e822                	sd	s0,16(sp)
    80001dfa:	e426                	sd	s1,8(sp)
    80001dfc:	1000                	addi	s0,sp,32
  push_off();
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	d9a080e7          	jalr	-614(ra) # 80000b98 <push_off>
    80001e06:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e08:	0007871b          	sext.w	a4,a5
    80001e0c:	00471793          	slli	a5,a4,0x4
    80001e10:	97ba                	add	a5,a5,a4
    80001e12:	078e                	slli	a5,a5,0x3
    80001e14:	0000f717          	auipc	a4,0xf
    80001e18:	48c70713          	addi	a4,a4,1164 # 800112a0 <cpus>
    80001e1c:	97ba                	add	a5,a5,a4
    80001e1e:	6384                	ld	s1,0(a5)
  pop_off();
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	e2a080e7          	jalr	-470(ra) # 80000c4a <pop_off>
  return p;
}
    80001e28:	8526                	mv	a0,s1
    80001e2a:	60e2                	ld	ra,24(sp)
    80001e2c:	6442                	ld	s0,16(sp)
    80001e2e:	64a2                	ld	s1,8(sp)
    80001e30:	6105                	addi	sp,sp,32
    80001e32:	8082                	ret

0000000080001e34 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e34:	1141                	addi	sp,sp,-16
    80001e36:	e406                	sd	ra,8(sp)
    80001e38:	e022                	sd	s0,0(sp)
    80001e3a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	fb8080e7          	jalr	-72(ra) # 80001df4 <myproc>
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	e66080e7          	jalr	-410(ra) # 80000caa <release>


  if (first) {
    80001e4c:	00007797          	auipc	a5,0x7
    80001e50:	a747a783          	lw	a5,-1420(a5) # 800088c0 <first.1747>
    80001e54:	eb89                	bnez	a5,80001e66 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e56:	00001097          	auipc	ra,0x1
    80001e5a:	ff4080e7          	jalr	-12(ra) # 80002e4a <usertrapret>
}
    80001e5e:	60a2                	ld	ra,8(sp)
    80001e60:	6402                	ld	s0,0(sp)
    80001e62:	0141                	addi	sp,sp,16
    80001e64:	8082                	ret
    first = 0;
    80001e66:	00007797          	auipc	a5,0x7
    80001e6a:	a407ad23          	sw	zero,-1446(a5) # 800088c0 <first.1747>
    fsinit(ROOTDEV);
    80001e6e:	4505                	li	a0,1
    80001e70:	00002097          	auipc	ra,0x2
    80001e74:	d98080e7          	jalr	-616(ra) # 80003c08 <fsinit>
    80001e78:	bff9                	j	80001e56 <forkret+0x22>

0000000080001e7a <inc_cpu_usage>:
inc_cpu_usage(int cpu_num){
    80001e7a:	1101                	addi	sp,sp,-32
    80001e7c:	ec06                	sd	ra,24(sp)
    80001e7e:	e822                	sd	s0,16(sp)
    80001e80:	e426                	sd	s1,8(sp)
    80001e82:	e04a                	sd	s2,0(sp)
    80001e84:	1000                	addi	s0,sp,32
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001e86:	00451493          	slli	s1,a0,0x4
    80001e8a:	94aa                	add	s1,s1,a0
    80001e8c:	048e                	slli	s1,s1,0x3
    80001e8e:	0000f797          	auipc	a5,0xf
    80001e92:	49278793          	addi	a5,a5,1170 # 80011320 <cpus+0x80>
    80001e96:	94be                	add	s1,s1,a5
    usage = c->admittedProcs;
    80001e98:	00451913          	slli	s2,a0,0x4
    80001e9c:	954a                	add	a0,a0,s2
    80001e9e:	050e                	slli	a0,a0,0x3
    80001ea0:	0000f917          	auipc	s2,0xf
    80001ea4:	40090913          	addi	s2,s2,1024 # 800112a0 <cpus>
    80001ea8:	992a                	add	s2,s2,a0
    80001eaa:	08093583          	ld	a1,128(s2)
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001eae:	0015861b          	addiw	a2,a1,1
    80001eb2:	2581                	sext.w	a1,a1
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	00005097          	auipc	ra,0x5
    80001eba:	b60080e7          	jalr	-1184(ra) # 80006a16 <cas>
    80001ebe:	f575                	bnez	a0,80001eaa <inc_cpu_usage+0x30>
}
    80001ec0:	60e2                	ld	ra,24(sp)
    80001ec2:	6442                	ld	s0,16(sp)
    80001ec4:	64a2                	ld	s1,8(sp)
    80001ec6:	6902                	ld	s2,0(sp)
    80001ec8:	6105                	addi	sp,sp,32
    80001eca:	8082                	ret

0000000080001ecc <allocpid>:
allocpid() { //changed as ordered in task 2
    80001ecc:	1101                	addi	sp,sp,-32
    80001ece:	ec06                	sd	ra,24(sp)
    80001ed0:	e822                	sd	s0,16(sp)
    80001ed2:	e426                	sd	s1,8(sp)
    80001ed4:	e04a                	sd	s2,0(sp)
    80001ed6:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001ed8:	00007917          	auipc	s2,0x7
    80001edc:	9f890913          	addi	s2,s2,-1544 # 800088d0 <nextpid>
    80001ee0:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001ee4:	0014861b          	addiw	a2,s1,1
    80001ee8:	85a6                	mv	a1,s1
    80001eea:	854a                	mv	a0,s2
    80001eec:	00005097          	auipc	ra,0x5
    80001ef0:	b2a080e7          	jalr	-1238(ra) # 80006a16 <cas>
    80001ef4:	f575                	bnez	a0,80001ee0 <allocpid+0x14>
}
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	60e2                	ld	ra,24(sp)
    80001efa:	6442                	ld	s0,16(sp)
    80001efc:	64a2                	ld	s1,8(sp)
    80001efe:	6902                	ld	s2,0(sp)
    80001f00:	6105                	addi	sp,sp,32
    80001f02:	8082                	ret

0000000080001f04 <proc_pagetable>:
{
    80001f04:	1101                	addi	sp,sp,-32
    80001f06:	ec06                	sd	ra,24(sp)
    80001f08:	e822                	sd	s0,16(sp)
    80001f0a:	e426                	sd	s1,8(sp)
    80001f0c:	e04a                	sd	s2,0(sp)
    80001f0e:	1000                	addi	s0,sp,32
    80001f10:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	44c080e7          	jalr	1100(ra) # 8000135e <uvmcreate>
    80001f1a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f1c:	c121                	beqz	a0,80001f5c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f1e:	4729                	li	a4,10
    80001f20:	00005697          	auipc	a3,0x5
    80001f24:	0e068693          	addi	a3,a3,224 # 80007000 <_trampoline>
    80001f28:	6605                	lui	a2,0x1
    80001f2a:	040005b7          	lui	a1,0x4000
    80001f2e:	15fd                	addi	a1,a1,-1
    80001f30:	05b2                	slli	a1,a1,0xc
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	1a2080e7          	jalr	418(ra) # 800010d4 <mappages>
    80001f3a:	02054863          	bltz	a0,80001f6a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f3e:	4719                	li	a4,6
    80001f40:	07893683          	ld	a3,120(s2)
    80001f44:	6605                	lui	a2,0x1
    80001f46:	020005b7          	lui	a1,0x2000
    80001f4a:	15fd                	addi	a1,a1,-1
    80001f4c:	05b6                	slli	a1,a1,0xd
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	184080e7          	jalr	388(ra) # 800010d4 <mappages>
    80001f58:	02054163          	bltz	a0,80001f7a <proc_pagetable+0x76>
}
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	60e2                	ld	ra,24(sp)
    80001f60:	6442                	ld	s0,16(sp)
    80001f62:	64a2                	ld	s1,8(sp)
    80001f64:	6902                	ld	s2,0(sp)
    80001f66:	6105                	addi	sp,sp,32
    80001f68:	8082                	ret
    uvmfree(pagetable, 0);
    80001f6a:	4581                	li	a1,0
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	5ec080e7          	jalr	1516(ra) # 8000155a <uvmfree>
    return 0;
    80001f76:	4481                	li	s1,0
    80001f78:	b7d5                	j	80001f5c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f7a:	4681                	li	a3,0
    80001f7c:	4605                	li	a2,1
    80001f7e:	040005b7          	lui	a1,0x4000
    80001f82:	15fd                	addi	a1,a1,-1
    80001f84:	05b2                	slli	a1,a1,0xc
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	312080e7          	jalr	786(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001f90:	4581                	li	a1,0
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	5c6080e7          	jalr	1478(ra) # 8000155a <uvmfree>
    return 0;
    80001f9c:	4481                	li	s1,0
    80001f9e:	bf7d                	j	80001f5c <proc_pagetable+0x58>

0000000080001fa0 <proc_freepagetable>:
{
    80001fa0:	1101                	addi	sp,sp,-32
    80001fa2:	ec06                	sd	ra,24(sp)
    80001fa4:	e822                	sd	s0,16(sp)
    80001fa6:	e426                	sd	s1,8(sp)
    80001fa8:	e04a                	sd	s2,0(sp)
    80001faa:	1000                	addi	s0,sp,32
    80001fac:	84aa                	mv	s1,a0
    80001fae:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fb0:	4681                	li	a3,0
    80001fb2:	4605                	li	a2,1
    80001fb4:	040005b7          	lui	a1,0x4000
    80001fb8:	15fd                	addi	a1,a1,-1
    80001fba:	05b2                	slli	a1,a1,0xc
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	2de080e7          	jalr	734(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fc4:	4681                	li	a3,0
    80001fc6:	4605                	li	a2,1
    80001fc8:	020005b7          	lui	a1,0x2000
    80001fcc:	15fd                	addi	a1,a1,-1
    80001fce:	05b6                	slli	a1,a1,0xd
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	2c8080e7          	jalr	712(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001fda:	85ca                	mv	a1,s2
    80001fdc:	8526                	mv	a0,s1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	57c080e7          	jalr	1404(ra) # 8000155a <uvmfree>
}
    80001fe6:	60e2                	ld	ra,24(sp)
    80001fe8:	6442                	ld	s0,16(sp)
    80001fea:	64a2                	ld	s1,8(sp)
    80001fec:	6902                	ld	s2,0(sp)
    80001fee:	6105                	addi	sp,sp,32
    80001ff0:	8082                	ret

0000000080001ff2 <freeproc>:
{
    80001ff2:	1101                	addi	sp,sp,-32
    80001ff4:	ec06                	sd	ra,24(sp)
    80001ff6:	e822                	sd	s0,16(sp)
    80001ff8:	e426                	sd	s1,8(sp)
    80001ffa:	1000                	addi	s0,sp,32
    80001ffc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ffe:	7d28                	ld	a0,120(a0)
    80002000:	c509                	beqz	a0,8000200a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	9f6080e7          	jalr	-1546(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000200a:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    8000200e:	78a8                	ld	a0,112(s1)
    80002010:	c511                	beqz	a0,8000201c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002012:	74ac                	ld	a1,104(s1)
    80002014:	00000097          	auipc	ra,0x0
    80002018:	f8c080e7          	jalr	-116(ra) # 80001fa0 <proc_freepagetable>
  p->pagetable = 0;
    8000201c:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002020:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80002024:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002028:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    8000202c:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002030:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002034:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002038:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index, &zombie, &zombie_head);
    8000203c:	0000f617          	auipc	a2,0xf
    80002040:	70c60613          	addi	a2,a2,1804 # 80011748 <zombie_head>
    80002044:	00007597          	auipc	a1,0x7
    80002048:	88458593          	addi	a1,a1,-1916 # 800088c8 <zombie>
    8000204c:	5c88                	lw	a0,56(s1)
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	85c080e7          	jalr	-1956(ra) # 800018aa <remove_from_list>
  p->state = UNUSED;
    80002056:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index, &unused, &unused_head);
    8000205a:	0000f617          	auipc	a2,0xf
    8000205e:	70660613          	addi	a2,a2,1798 # 80011760 <unused_head>
    80002062:	00007597          	auipc	a1,0x7
    80002066:	86258593          	addi	a1,a1,-1950 # 800088c4 <unused>
    8000206a:	5c88                	lw	a0,56(s1)
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	a78080e7          	jalr	-1416(ra) # 80001ae4 <insert_to_list>
}
    80002074:	60e2                	ld	ra,24(sp)
    80002076:	6442                	ld	s0,16(sp)
    80002078:	64a2                	ld	s1,8(sp)
    8000207a:	6105                	addi	sp,sp,32
    8000207c:	8082                	ret

000000008000207e <allocproc>:
{
    8000207e:	7179                	addi	sp,sp,-48
    80002080:	f406                	sd	ra,40(sp)
    80002082:	f022                	sd	s0,32(sp)
    80002084:	ec26                	sd	s1,24(sp)
    80002086:	e84a                	sd	s2,16(sp)
    80002088:	e44e                	sd	s3,8(sp)
    8000208a:	e052                	sd	s4,0(sp)
    8000208c:	1800                	addi	s0,sp,48
  if(unused != -1){
    8000208e:	00007917          	auipc	s2,0x7
    80002092:	83692903          	lw	s2,-1994(s2) # 800088c4 <unused>
    80002096:	57fd                	li	a5,-1
  return 0;
    80002098:	4481                	li	s1,0
  if(unused != -1){
    8000209a:	0af90b63          	beq	s2,a5,80002150 <allocproc+0xd2>
    p = &proc[unused];
    8000209e:	18800993          	li	s3,392
    800020a2:	033909b3          	mul	s3,s2,s3
    800020a6:	0000f497          	auipc	s1,0xf
    800020aa:	7d248493          	addi	s1,s1,2002 # 80011878 <proc>
    800020ae:	94ce                	add	s1,s1,s3
    remove_from_list(p->index,&unused, &unused_head);
    800020b0:	0000f617          	auipc	a2,0xf
    800020b4:	6b060613          	addi	a2,a2,1712 # 80011760 <unused_head>
    800020b8:	00007597          	auipc	a1,0x7
    800020bc:	80c58593          	addi	a1,a1,-2036 # 800088c4 <unused>
    800020c0:	5c88                	lw	a0,56(s1)
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	7e8080e7          	jalr	2024(ra) # 800018aa <remove_from_list>
    acquire(&p->lock);
    800020ca:	8526                	mv	a0,s1
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	b18080e7          	jalr	-1256(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	df8080e7          	jalr	-520(ra) # 80001ecc <allocpid>
    800020dc:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020de:	4785                	li	a5,1
    800020e0:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	a12080e7          	jalr	-1518(ra) # 80000af4 <kalloc>
    800020ea:	8a2a                	mv	s4,a0
    800020ec:	fca8                	sd	a0,120(s1)
    800020ee:	c935                	beqz	a0,80002162 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    800020f0:	8526                	mv	a0,s1
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	e12080e7          	jalr	-494(ra) # 80001f04 <proc_pagetable>
    800020fa:	8a2a                	mv	s4,a0
    800020fc:	18800793          	li	a5,392
    80002100:	02f90733          	mul	a4,s2,a5
    80002104:	0000f797          	auipc	a5,0xf
    80002108:	77478793          	addi	a5,a5,1908 # 80011878 <proc>
    8000210c:	97ba                	add	a5,a5,a4
    8000210e:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    80002110:	c52d                	beqz	a0,8000217a <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    80002112:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    80002116:	0000fa17          	auipc	s4,0xf
    8000211a:	762a0a13          	addi	s4,s4,1890 # 80011878 <proc>
    8000211e:	07000613          	li	a2,112
    80002122:	4581                	li	a1,0
    80002124:	9552                	add	a0,a0,s4
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	bde080e7          	jalr	-1058(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    8000212e:	18800793          	li	a5,392
    80002132:	02f90933          	mul	s2,s2,a5
    80002136:	9952                	add	s2,s2,s4
    80002138:	00000797          	auipc	a5,0x0
    8000213c:	cfc78793          	addi	a5,a5,-772 # 80001e34 <forkret>
    80002140:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002144:	06093783          	ld	a5,96(s2)
    80002148:	6705                	lui	a4,0x1
    8000214a:	97ba                	add	a5,a5,a4
    8000214c:	08f93423          	sd	a5,136(s2)
}
    80002150:	8526                	mv	a0,s1
    80002152:	70a2                	ld	ra,40(sp)
    80002154:	7402                	ld	s0,32(sp)
    80002156:	64e2                	ld	s1,24(sp)
    80002158:	6942                	ld	s2,16(sp)
    8000215a:	69a2                	ld	s3,8(sp)
    8000215c:	6a02                	ld	s4,0(sp)
    8000215e:	6145                	addi	sp,sp,48
    80002160:	8082                	ret
    freeproc(p);
    80002162:	8526                	mv	a0,s1
    80002164:	00000097          	auipc	ra,0x0
    80002168:	e8e080e7          	jalr	-370(ra) # 80001ff2 <freeproc>
    release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b3c080e7          	jalr	-1220(ra) # 80000caa <release>
    return 0;
    80002176:	84d2                	mv	s1,s4
    80002178:	bfe1                	j	80002150 <allocproc+0xd2>
    freeproc(p);
    8000217a:	8526                	mv	a0,s1
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	e76080e7          	jalr	-394(ra) # 80001ff2 <freeproc>
    release(&p->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	b24080e7          	jalr	-1244(ra) # 80000caa <release>
    return 0;
    8000218e:	84d2                	mv	s1,s4
    80002190:	b7c1                	j	80002150 <allocproc+0xd2>

0000000080002192 <userinit>:
{
    80002192:	1101                	addi	sp,sp,-32
    80002194:	ec06                	sd	ra,24(sp)
    80002196:	e822                	sd	s0,16(sp)
    80002198:	e426                	sd	s1,8(sp)
    8000219a:	1000                	addi	s0,sp,32
  p = allocproc();
    8000219c:	00000097          	auipc	ra,0x0
    800021a0:	ee2080e7          	jalr	-286(ra) # 8000207e <allocproc>
    800021a4:	84aa                	mv	s1,a0
  initproc = p;
    800021a6:	00007797          	auipc	a5,0x7
    800021aa:	e8a7b123          	sd	a0,-382(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021ae:	03400613          	li	a2,52
    800021b2:	00006597          	auipc	a1,0x6
    800021b6:	72e58593          	addi	a1,a1,1838 # 800088e0 <initcode>
    800021ba:	7928                	ld	a0,112(a0)
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	1d0080e7          	jalr	464(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    800021c4:	6785                	lui	a5,0x1
    800021c6:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800021c8:	7cb8                	ld	a4,120(s1)
    800021ca:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021ce:	7cb8                	ld	a4,120(s1)
    800021d0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021d2:	4641                	li	a2,16
    800021d4:	00006597          	auipc	a1,0x6
    800021d8:	0ac58593          	addi	a1,a1,172 # 80008280 <digits+0x240>
    800021dc:	17848513          	addi	a0,s1,376
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	c76080e7          	jalr	-906(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800021e8:	00006517          	auipc	a0,0x6
    800021ec:	0a850513          	addi	a0,a0,168 # 80008290 <digits+0x250>
    800021f0:	00002097          	auipc	ra,0x2
    800021f4:	446080e7          	jalr	1094(ra) # 80004636 <namei>
    800021f8:	16a4b823          	sd	a0,368(s1)
  insert_to_list(p->index, &cpus_ll[0], &cpus_head[0]);
    800021fc:	0000f617          	auipc	a2,0xf
    80002200:	57c60613          	addi	a2,a2,1404 # 80011778 <cpus_head>
    80002204:	0000f597          	auipc	a1,0xf
    80002208:	4dc58593          	addi	a1,a1,1244 # 800116e0 <cpus_ll>
    8000220c:	5c88                	lw	a0,56(s1)
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	8d6080e7          	jalr	-1834(ra) # 80001ae4 <insert_to_list>
  inc_cpu_usage(0);
    80002216:	4501                	li	a0,0
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	c62080e7          	jalr	-926(ra) # 80001e7a <inc_cpu_usage>
  p->state = RUNNABLE;
    80002220:	478d                	li	a5,3
    80002222:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a84080e7          	jalr	-1404(ra) # 80000caa <release>
}
    8000222e:	60e2                	ld	ra,24(sp)
    80002230:	6442                	ld	s0,16(sp)
    80002232:	64a2                	ld	s1,8(sp)
    80002234:	6105                	addi	sp,sp,32
    80002236:	8082                	ret

0000000080002238 <growproc>:
{
    80002238:	1101                	addi	sp,sp,-32
    8000223a:	ec06                	sd	ra,24(sp)
    8000223c:	e822                	sd	s0,16(sp)
    8000223e:	e426                	sd	s1,8(sp)
    80002240:	e04a                	sd	s2,0(sp)
    80002242:	1000                	addi	s0,sp,32
    80002244:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	bae080e7          	jalr	-1106(ra) # 80001df4 <myproc>
    8000224e:	892a                	mv	s2,a0
  sz = p->sz;
    80002250:	752c                	ld	a1,104(a0)
    80002252:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002256:	00904f63          	bgtz	s1,80002274 <growproc+0x3c>
  } else if(n < 0){
    8000225a:	0204cc63          	bltz	s1,80002292 <growproc+0x5a>
  p->sz = sz;
    8000225e:	1602                	slli	a2,a2,0x20
    80002260:	9201                	srli	a2,a2,0x20
    80002262:	06c93423          	sd	a2,104(s2)
  return 0;
    80002266:	4501                	li	a0,0
}
    80002268:	60e2                	ld	ra,24(sp)
    8000226a:	6442                	ld	s0,16(sp)
    8000226c:	64a2                	ld	s1,8(sp)
    8000226e:	6902                	ld	s2,0(sp)
    80002270:	6105                	addi	sp,sp,32
    80002272:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002274:	9e25                	addw	a2,a2,s1
    80002276:	1602                	slli	a2,a2,0x20
    80002278:	9201                	srli	a2,a2,0x20
    8000227a:	1582                	slli	a1,a1,0x20
    8000227c:	9181                	srli	a1,a1,0x20
    8000227e:	7928                	ld	a0,112(a0)
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	1c6080e7          	jalr	454(ra) # 80001446 <uvmalloc>
    80002288:	0005061b          	sext.w	a2,a0
    8000228c:	fa69                	bnez	a2,8000225e <growproc+0x26>
      return -1;
    8000228e:	557d                	li	a0,-1
    80002290:	bfe1                	j	80002268 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002292:	9e25                	addw	a2,a2,s1
    80002294:	1602                	slli	a2,a2,0x20
    80002296:	9201                	srli	a2,a2,0x20
    80002298:	1582                	slli	a1,a1,0x20
    8000229a:	9181                	srli	a1,a1,0x20
    8000229c:	7928                	ld	a0,112(a0)
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	160080e7          	jalr	352(ra) # 800013fe <uvmdealloc>
    800022a6:	0005061b          	sext.w	a2,a0
    800022aa:	bf55                	j	8000225e <growproc+0x26>

00000000800022ac <fork>:
{
    800022ac:	7179                	addi	sp,sp,-48
    800022ae:	f406                	sd	ra,40(sp)
    800022b0:	f022                	sd	s0,32(sp)
    800022b2:	ec26                	sd	s1,24(sp)
    800022b4:	e84a                	sd	s2,16(sp)
    800022b6:	e44e                	sd	s3,8(sp)
    800022b8:	e052                	sd	s4,0(sp)
    800022ba:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	b38080e7          	jalr	-1224(ra) # 80001df4 <myproc>
    800022c4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	db8080e7          	jalr	-584(ra) # 8000207e <allocproc>
    800022ce:	14050e63          	beqz	a0,8000242a <fork+0x17e>
    800022d2:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022d4:	0689b603          	ld	a2,104(s3)
    800022d8:	792c                	ld	a1,112(a0)
    800022da:	0709b503          	ld	a0,112(s3)
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	2b4080e7          	jalr	692(ra) # 80001592 <uvmcopy>
    800022e6:	04054663          	bltz	a0,80002332 <fork+0x86>
  np->sz = p->sz;
    800022ea:	0689b783          	ld	a5,104(s3)
    800022ee:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800022f2:	0789b683          	ld	a3,120(s3)
    800022f6:	87b6                	mv	a5,a3
    800022f8:	07893703          	ld	a4,120(s2)
    800022fc:	12068693          	addi	a3,a3,288
    80002300:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002304:	6788                	ld	a0,8(a5)
    80002306:	6b8c                	ld	a1,16(a5)
    80002308:	6f90                	ld	a2,24(a5)
    8000230a:	01073023          	sd	a6,0(a4)
    8000230e:	e708                	sd	a0,8(a4)
    80002310:	eb0c                	sd	a1,16(a4)
    80002312:	ef10                	sd	a2,24(a4)
    80002314:	02078793          	addi	a5,a5,32
    80002318:	02070713          	addi	a4,a4,32
    8000231c:	fed792e3          	bne	a5,a3,80002300 <fork+0x54>
  np->trapframe->a0 = 0;
    80002320:	07893783          	ld	a5,120(s2)
    80002324:	0607b823          	sd	zero,112(a5)
    80002328:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000232c:	17000a13          	li	s4,368
    80002330:	a03d                	j	8000235e <fork+0xb2>
    freeproc(np);
    80002332:	854a                	mv	a0,s2
    80002334:	00000097          	auipc	ra,0x0
    80002338:	cbe080e7          	jalr	-834(ra) # 80001ff2 <freeproc>
    release(&np->lock);
    8000233c:	854a                	mv	a0,s2
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	96c080e7          	jalr	-1684(ra) # 80000caa <release>
    return -1;
    80002346:	5a7d                	li	s4,-1
    80002348:	a8c1                	j	80002418 <fork+0x16c>
      np->ofile[i] = filedup(p->ofile[i]);
    8000234a:	00003097          	auipc	ra,0x3
    8000234e:	982080e7          	jalr	-1662(ra) # 80004ccc <filedup>
    80002352:	009907b3          	add	a5,s2,s1
    80002356:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002358:	04a1                	addi	s1,s1,8
    8000235a:	01448763          	beq	s1,s4,80002368 <fork+0xbc>
    if(p->ofile[i])
    8000235e:	009987b3          	add	a5,s3,s1
    80002362:	6388                	ld	a0,0(a5)
    80002364:	f17d                	bnez	a0,8000234a <fork+0x9e>
    80002366:	bfcd                	j	80002358 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002368:	1709b503          	ld	a0,368(s3)
    8000236c:	00002097          	auipc	ra,0x2
    80002370:	ad6080e7          	jalr	-1322(ra) # 80003e42 <idup>
    80002374:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002378:	17890493          	addi	s1,s2,376
    8000237c:	4641                	li	a2,16
    8000237e:	17898593          	addi	a1,s3,376
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	ad2080e7          	jalr	-1326(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    8000238c:	03092a03          	lw	s4,48(s2)
  np->cpu_num = p->cpu_num; //giving the child it's parent's cpu_num
    80002390:	0349a783          	lw	a5,52(s3)
    80002394:	02f92a23          	sw	a5,52(s2)
  initlock(&np->linked_list_lock, np->name);
    80002398:	85a6                	mv	a1,s1
    8000239a:	04090513          	addi	a0,s2,64
    8000239e:	ffffe097          	auipc	ra,0xffffe
    800023a2:	7b6080e7          	jalr	1974(ra) # 80000b54 <initlock>
  release(&np->lock);
    800023a6:	854a                	mv	a0,s2
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	902080e7          	jalr	-1790(ra) # 80000caa <release>
  acquire(&wait_lock);
    800023b0:	0000f497          	auipc	s1,0xf
    800023b4:	36848493          	addi	s1,s1,872 # 80011718 <wait_lock>
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	82a080e7          	jalr	-2006(ra) # 80000be4 <acquire>
  np->parent = p;
    800023c2:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8e2080e7          	jalr	-1822(ra) # 80000caa <release>
  acquire(&np->lock);
    800023d0:	854a                	mv	a0,s2
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	812080e7          	jalr	-2030(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023da:	478d                	li	a5,3
    800023dc:	00f92c23          	sw	a5,24(s2)
  insert_to_list(np->index, &cpus_ll[np->cpu_num], &cpus_head[np->cpu_num]);
    800023e0:	03492583          	lw	a1,52(s2)
    800023e4:	00159793          	slli	a5,a1,0x1
    800023e8:	97ae                	add	a5,a5,a1
    800023ea:	078e                	slli	a5,a5,0x3
    800023ec:	058a                	slli	a1,a1,0x2
    800023ee:	0000f617          	auipc	a2,0xf
    800023f2:	38a60613          	addi	a2,a2,906 # 80011778 <cpus_head>
    800023f6:	963e                	add	a2,a2,a5
    800023f8:	0000f797          	auipc	a5,0xf
    800023fc:	2e878793          	addi	a5,a5,744 # 800116e0 <cpus_ll>
    80002400:	95be                	add	a1,a1,a5
    80002402:	03892503          	lw	a0,56(s2)
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	6de080e7          	jalr	1758(ra) # 80001ae4 <insert_to_list>
  release(&np->lock);
    8000240e:	854a                	mv	a0,s2
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	89a080e7          	jalr	-1894(ra) # 80000caa <release>
}
    80002418:	8552                	mv	a0,s4
    8000241a:	70a2                	ld	ra,40(sp)
    8000241c:	7402                	ld	s0,32(sp)
    8000241e:	64e2                	ld	s1,24(sp)
    80002420:	6942                	ld	s2,16(sp)
    80002422:	69a2                	ld	s3,8(sp)
    80002424:	6a02                	ld	s4,0(sp)
    80002426:	6145                	addi	sp,sp,48
    80002428:	8082                	ret
    return -1;
    8000242a:	5a7d                	li	s4,-1
    8000242c:	b7f5                	j	80002418 <fork+0x16c>

000000008000242e <scheduler>:
{
    8000242e:	711d                	addi	sp,sp,-96
    80002430:	ec86                	sd	ra,88(sp)
    80002432:	e8a2                	sd	s0,80(sp)
    80002434:	e4a6                	sd	s1,72(sp)
    80002436:	e0ca                	sd	s2,64(sp)
    80002438:	fc4e                	sd	s3,56(sp)
    8000243a:	f852                	sd	s4,48(sp)
    8000243c:	f456                	sd	s5,40(sp)
    8000243e:	f05a                	sd	s6,32(sp)
    80002440:	ec5e                	sd	s7,24(sp)
    80002442:	e862                	sd	s8,16(sp)
    80002444:	e466                	sd	s9,8(sp)
    80002446:	e06a                	sd	s10,0(sp)
    80002448:	1080                	addi	s0,sp,96
    8000244a:	8712                	mv	a4,tp
  int id = r_tp();
    8000244c:	2701                	sext.w	a4,a4
  c->proc = 0;
    8000244e:	0000fb17          	auipc	s6,0xf
    80002452:	e52b0b13          	addi	s6,s6,-430 # 800112a0 <cpus>
    80002456:	00471793          	slli	a5,a4,0x4
    8000245a:	00e786b3          	add	a3,a5,a4
    8000245e:	068e                	slli	a3,a3,0x3
    80002460:	96da                	add	a3,a3,s6
    80002462:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    80002466:	97ba                	add	a5,a5,a4
    80002468:	078e                	slli	a5,a5,0x3
    8000246a:	07a1                	addi	a5,a5,8
    8000246c:	9b3e                	add	s6,s6,a5
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    8000246e:	0000f997          	auipc	s3,0xf
    80002472:	e3298993          	addi	s3,s3,-462 # 800112a0 <cpus>
      p = &proc[cpus_ll[cpuid()]];
    80002476:	0000f497          	auipc	s1,0xf
    8000247a:	40248493          	addi	s1,s1,1026 # 80011878 <proc>
      c->proc = p;
    8000247e:	8936                	mv	s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002480:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002484:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002488:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    8000248c:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    8000248e:	2781                	sext.w	a5,a5
    80002490:	078a                	slli	a5,a5,0x2
    80002492:	97ce                	add	a5,a5,s3
    80002494:	4407a703          	lw	a4,1088(a5)
    80002498:	57fd                	li	a5,-1
    8000249a:	fef703e3          	beq	a4,a5,80002480 <scheduler+0x52>
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    8000249e:	0000fa97          	auipc	s5,0xf
    800024a2:	2daa8a93          	addi	s5,s5,730 # 80011778 <cpus_head>
    800024a6:	0000fa17          	auipc	s4,0xf
    800024aa:	23aa0a13          	addi	s4,s4,570 # 800116e0 <cpus_ll>
    800024ae:	a881                	j	800024fe <scheduler+0xd0>
        panic("could not remove");
    800024b0:	00006517          	auipc	a0,0x6
    800024b4:	de850513          	addi	a0,a0,-536 # 80008298 <digits+0x258>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	086080e7          	jalr	134(ra) # 8000053e <panic>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    800024c0:	034c2583          	lw	a1,52(s8)
    800024c4:	00159613          	slli	a2,a1,0x1
    800024c8:	962e                	add	a2,a2,a1
    800024ca:	060e                	slli	a2,a2,0x3
    800024cc:	058a                	slli	a1,a1,0x2
    800024ce:	9656                	add	a2,a2,s5
    800024d0:	95d2                	add	a1,a1,s4
    800024d2:	038c2503          	lw	a0,56(s8)
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	60e080e7          	jalr	1550(ra) # 80001ae4 <insert_to_list>
      c->proc = 0;
    800024de:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    800024e2:	8566                	mv	a0,s9
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	7c6080e7          	jalr	1990(ra) # 80000caa <release>
    800024ec:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800024ee:	2781                	sext.w	a5,a5
    800024f0:	078a                	slli	a5,a5,0x2
    800024f2:	97ce                	add	a5,a5,s3
    800024f4:	4407a703          	lw	a4,1088(a5)
    800024f8:	57fd                	li	a5,-1
    800024fa:	f8f703e3          	beq	a4,a5,80002480 <scheduler+0x52>
    800024fe:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    80002500:	2781                	sext.w	a5,a5
    80002502:	078a                	slli	a5,a5,0x2
    80002504:	97ce                	add	a5,a5,s3
    80002506:	4407ad03          	lw	s10,1088(a5)
    8000250a:	18800b93          	li	s7,392
    8000250e:	037d0bb3          	mul	s7,s10,s7
    80002512:	009b8cb3          	add	s9,s7,s1
      acquire(&p->lock);
    80002516:	8566                	mv	a0,s9
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	6cc080e7          	jalr	1740(ra) # 80000be4 <acquire>
    80002520:	8592                	mv	a1,tp
    80002522:	8612                	mv	a2,tp
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    80002524:	0006079b          	sext.w	a5,a2
    80002528:	00179613          	slli	a2,a5,0x1
    8000252c:	963e                	add	a2,a2,a5
    8000252e:	060e                	slli	a2,a2,0x3
    80002530:	2581                	sext.w	a1,a1
    80002532:	058a                	slli	a1,a1,0x2
    80002534:	9656                	add	a2,a2,s5
    80002536:	95d2                	add	a1,a1,s4
    80002538:	038ca503          	lw	a0,56(s9)
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	36e080e7          	jalr	878(ra) # 800018aa <remove_from_list>
      if(removed == -1)
    80002544:	57fd                	li	a5,-1
    80002546:	f6f505e3          	beq	a0,a5,800024b0 <scheduler+0x82>
      p->state = RUNNING;
    8000254a:	18800c13          	li	s8,392
    8000254e:	038d0c33          	mul	s8,s10,s8
    80002552:	9c26                	add	s8,s8,s1
    80002554:	4791                	li	a5,4
    80002556:	00fc2c23          	sw	a5,24(s8)
      c->proc = p;
    8000255a:	01993023          	sd	s9,0(s2)
      swtch(&c->context, &p->context);
    8000255e:	080b8593          	addi	a1,s7,128
    80002562:	95a6                	add	a1,a1,s1
    80002564:	855a                	mv	a0,s6
    80002566:	00001097          	auipc	ra,0x1
    8000256a:	83a080e7          	jalr	-1990(ra) # 80002da0 <swtch>
      if(p->state != ZOMBIE){
    8000256e:	018c2703          	lw	a4,24(s8)
    80002572:	4795                	li	a5,5
    80002574:	f6f705e3          	beq	a4,a5,800024de <scheduler+0xb0>
    80002578:	b7a1                	j	800024c0 <scheduler+0x92>

000000008000257a <sched>:
{
    8000257a:	7179                	addi	sp,sp,-48
    8000257c:	f406                	sd	ra,40(sp)
    8000257e:	f022                	sd	s0,32(sp)
    80002580:	ec26                	sd	s1,24(sp)
    80002582:	e84a                	sd	s2,16(sp)
    80002584:	e44e                	sd	s3,8(sp)
    80002586:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002588:	00000097          	auipc	ra,0x0
    8000258c:	86c080e7          	jalr	-1940(ra) # 80001df4 <myproc>
    80002590:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	5d8080e7          	jalr	1496(ra) # 80000b6a <holding>
    8000259a:	c559                	beqz	a0,80002628 <sched+0xae>
    8000259c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    8000259e:	0007871b          	sext.w	a4,a5
    800025a2:	00471793          	slli	a5,a4,0x4
    800025a6:	97ba                	add	a5,a5,a4
    800025a8:	078e                	slli	a5,a5,0x3
    800025aa:	0000f717          	auipc	a4,0xf
    800025ae:	cf670713          	addi	a4,a4,-778 # 800112a0 <cpus>
    800025b2:	97ba                	add	a5,a5,a4
    800025b4:	5fb8                	lw	a4,120(a5)
    800025b6:	4785                	li	a5,1
    800025b8:	08f71063          	bne	a4,a5,80002638 <sched+0xbe>
  if(p->state == RUNNING)
    800025bc:	4c98                	lw	a4,24(s1)
    800025be:	4791                	li	a5,4
    800025c0:	08f70463          	beq	a4,a5,80002648 <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025c4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025c8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025ca:	e7d9                	bnez	a5,80002658 <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025cc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025ce:	0000f917          	auipc	s2,0xf
    800025d2:	cd290913          	addi	s2,s2,-814 # 800112a0 <cpus>
    800025d6:	0007871b          	sext.w	a4,a5
    800025da:	00471793          	slli	a5,a4,0x4
    800025de:	97ba                	add	a5,a5,a4
    800025e0:	078e                	slli	a5,a5,0x3
    800025e2:	97ca                	add	a5,a5,s2
    800025e4:	07c7a983          	lw	s3,124(a5)
    800025e8:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800025ea:	0005879b          	sext.w	a5,a1
    800025ee:	00479593          	slli	a1,a5,0x4
    800025f2:	95be                	add	a1,a1,a5
    800025f4:	058e                	slli	a1,a1,0x3
    800025f6:	05a1                	addi	a1,a1,8
    800025f8:	95ca                	add	a1,a1,s2
    800025fa:	08048513          	addi	a0,s1,128
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	7a2080e7          	jalr	1954(ra) # 80002da0 <swtch>
    80002606:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002608:	0007871b          	sext.w	a4,a5
    8000260c:	00471793          	slli	a5,a4,0x4
    80002610:	97ba                	add	a5,a5,a4
    80002612:	078e                	slli	a5,a5,0x3
    80002614:	993e                	add	s2,s2,a5
    80002616:	07392e23          	sw	s3,124(s2)
}
    8000261a:	70a2                	ld	ra,40(sp)
    8000261c:	7402                	ld	s0,32(sp)
    8000261e:	64e2                	ld	s1,24(sp)
    80002620:	6942                	ld	s2,16(sp)
    80002622:	69a2                	ld	s3,8(sp)
    80002624:	6145                	addi	sp,sp,48
    80002626:	8082                	ret
    panic("sched p->lock");
    80002628:	00006517          	auipc	a0,0x6
    8000262c:	c8850513          	addi	a0,a0,-888 # 800082b0 <digits+0x270>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>
    panic("sched locks");
    80002638:	00006517          	auipc	a0,0x6
    8000263c:	c8850513          	addi	a0,a0,-888 # 800082c0 <digits+0x280>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	efe080e7          	jalr	-258(ra) # 8000053e <panic>
    panic("sched running");
    80002648:	00006517          	auipc	a0,0x6
    8000264c:	c8850513          	addi	a0,a0,-888 # 800082d0 <digits+0x290>
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	eee080e7          	jalr	-274(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002658:	00006517          	auipc	a0,0x6
    8000265c:	c8850513          	addi	a0,a0,-888 # 800082e0 <digits+0x2a0>
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080002668 <yield>:
{
    80002668:	1101                	addi	sp,sp,-32
    8000266a:	ec06                	sd	ra,24(sp)
    8000266c:	e822                	sd	s0,16(sp)
    8000266e:	e426                	sd	s1,8(sp)
    80002670:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	782080e7          	jalr	1922(ra) # 80001df4 <myproc>
    8000267a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	568080e7          	jalr	1384(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002684:	478d                	li	a5,3
    80002686:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002688:	58cc                	lw	a1,52(s1)
    8000268a:	00159793          	slli	a5,a1,0x1
    8000268e:	97ae                	add	a5,a5,a1
    80002690:	078e                	slli	a5,a5,0x3
    80002692:	058a                	slli	a1,a1,0x2
    80002694:	0000f617          	auipc	a2,0xf
    80002698:	0e460613          	addi	a2,a2,228 # 80011778 <cpus_head>
    8000269c:	963e                	add	a2,a2,a5
    8000269e:	0000f797          	auipc	a5,0xf
    800026a2:	04278793          	addi	a5,a5,66 # 800116e0 <cpus_ll>
    800026a6:	95be                	add	a1,a1,a5
    800026a8:	5c88                	lw	a0,56(s1)
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	43a080e7          	jalr	1082(ra) # 80001ae4 <insert_to_list>
  sched();
    800026b2:	00000097          	auipc	ra,0x0
    800026b6:	ec8080e7          	jalr	-312(ra) # 8000257a <sched>
  release(&p->lock);
    800026ba:	8526                	mv	a0,s1
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	5ee080e7          	jalr	1518(ra) # 80000caa <release>
}
    800026c4:	60e2                	ld	ra,24(sp)
    800026c6:	6442                	ld	s0,16(sp)
    800026c8:	64a2                	ld	s1,8(sp)
    800026ca:	6105                	addi	sp,sp,32
    800026cc:	8082                	ret

00000000800026ce <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800026ce:	7179                	addi	sp,sp,-48
    800026d0:	f406                	sd	ra,40(sp)
    800026d2:	f022                	sd	s0,32(sp)
    800026d4:	ec26                	sd	s1,24(sp)
    800026d6:	e84a                	sd	s2,16(sp)
    800026d8:	e44e                	sd	s3,8(sp)
    800026da:	1800                	addi	s0,sp,48
    800026dc:	89aa                	mv	s3,a0
    800026de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	714080e7          	jalr	1812(ra) # 80001df4 <myproc>
    800026e8:	84aa                	mv	s1,a0
  // Must acquire p->lock in order to change p->state and then call sched.
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.
  // Go to sleep.
  // cas(&p->state, RUNNING, SLEEPING);
  insert_to_list(p->index, &sleeping, &sleeping_head);
    800026ea:	0000f617          	auipc	a2,0xf
    800026ee:	04660613          	addi	a2,a2,70 # 80011730 <sleeping_head>
    800026f2:	00006597          	auipc	a1,0x6
    800026f6:	1da58593          	addi	a1,a1,474 # 800088cc <sleeping>
    800026fa:	5d08                	lw	a0,56(a0)
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	3e8080e7          	jalr	1000(ra) # 80001ae4 <insert_to_list>
  p->chan = chan;
    80002704:	0334b023          	sd	s3,32(s1)
  // if (p->state == RUNNING){
  //   }
  // while(!cas(&p->state, RUNNING, SLEEPING));
  acquire(&p->lock);  //DOC: sleeplock1
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	4da080e7          	jalr	1242(ra) # 80000be4 <acquire>
  p->state = SLEEPING;
    80002712:	4789                	li	a5,2
    80002714:	cc9c                	sw	a5,24(s1)
  release(lk);
    80002716:	854a                	mv	a0,s2
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	592080e7          	jalr	1426(ra) # 80000caa <release>
  sched();
    80002720:	00000097          	auipc	ra,0x0
    80002724:	e5a080e7          	jalr	-422(ra) # 8000257a <sched>
  // Tidy up.
  p->chan = 0;
    80002728:	0204b023          	sd	zero,32(s1)
  // Reacquire original lock.
  release(&p->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	57c080e7          	jalr	1404(ra) # 80000caa <release>
  acquire(lk);
    80002736:	854a                	mv	a0,s2
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	4ac080e7          	jalr	1196(ra) # 80000be4 <acquire>

}
    80002740:	70a2                	ld	ra,40(sp)
    80002742:	7402                	ld	s0,32(sp)
    80002744:	64e2                	ld	s1,24(sp)
    80002746:	6942                	ld	s2,16(sp)
    80002748:	69a2                	ld	s3,8(sp)
    8000274a:	6145                	addi	sp,sp,48
    8000274c:	8082                	ret

000000008000274e <wait>:
{
    8000274e:	715d                	addi	sp,sp,-80
    80002750:	e486                	sd	ra,72(sp)
    80002752:	e0a2                	sd	s0,64(sp)
    80002754:	fc26                	sd	s1,56(sp)
    80002756:	f84a                	sd	s2,48(sp)
    80002758:	f44e                	sd	s3,40(sp)
    8000275a:	f052                	sd	s4,32(sp)
    8000275c:	ec56                	sd	s5,24(sp)
    8000275e:	e85a                	sd	s6,16(sp)
    80002760:	e45e                	sd	s7,8(sp)
    80002762:	e062                	sd	s8,0(sp)
    80002764:	0880                	addi	s0,sp,80
    80002766:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	68c080e7          	jalr	1676(ra) # 80001df4 <myproc>
    80002770:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002772:	0000f517          	auipc	a0,0xf
    80002776:	fa650513          	addi	a0,a0,-90 # 80011718 <wait_lock>
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	46a080e7          	jalr	1130(ra) # 80000be4 <acquire>
    havekids = 0;
    80002782:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002784:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002786:	00015997          	auipc	s3,0x15
    8000278a:	2f298993          	addi	s3,s3,754 # 80017a78 <tickslock>
        havekids = 1;
    8000278e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002790:	0000fc17          	auipc	s8,0xf
    80002794:	f88c0c13          	addi	s8,s8,-120 # 80011718 <wait_lock>
    havekids = 0;
    80002798:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000279a:	0000f497          	auipc	s1,0xf
    8000279e:	0de48493          	addi	s1,s1,222 # 80011878 <proc>
    800027a2:	a0bd                	j	80002810 <wait+0xc2>
          pid = np->pid;
    800027a4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027a8:	000b0e63          	beqz	s6,800027c4 <wait+0x76>
    800027ac:	4691                	li	a3,4
    800027ae:	02c48613          	addi	a2,s1,44
    800027b2:	85da                	mv	a1,s6
    800027b4:	07093503          	ld	a0,112(s2)
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	ede080e7          	jalr	-290(ra) # 80001696 <copyout>
    800027c0:	02054563          	bltz	a0,800027ea <wait+0x9c>
          freeproc(np);
    800027c4:	8526                	mv	a0,s1
    800027c6:	00000097          	auipc	ra,0x0
    800027ca:	82c080e7          	jalr	-2004(ra) # 80001ff2 <freeproc>
          release(&np->lock);
    800027ce:	8526                	mv	a0,s1
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	4da080e7          	jalr	1242(ra) # 80000caa <release>
          release(&wait_lock);
    800027d8:	0000f517          	auipc	a0,0xf
    800027dc:	f4050513          	addi	a0,a0,-192 # 80011718 <wait_lock>
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	4ca080e7          	jalr	1226(ra) # 80000caa <release>
          return pid;
    800027e8:	a09d                	j	8000284e <wait+0x100>
            release(&np->lock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	4be080e7          	jalr	1214(ra) # 80000caa <release>
            release(&wait_lock);
    800027f4:	0000f517          	auipc	a0,0xf
    800027f8:	f2450513          	addi	a0,a0,-220 # 80011718 <wait_lock>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	4ae080e7          	jalr	1198(ra) # 80000caa <release>
            return -1;
    80002804:	59fd                	li	s3,-1
    80002806:	a0a1                	j	8000284e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002808:	18848493          	addi	s1,s1,392
    8000280c:	03348463          	beq	s1,s3,80002834 <wait+0xe6>
      if(np->parent == p){
    80002810:	6cbc                	ld	a5,88(s1)
    80002812:	ff279be3          	bne	a5,s2,80002808 <wait+0xba>
        acquire(&np->lock);
    80002816:	8526                	mv	a0,s1
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	3cc080e7          	jalr	972(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002820:	4c9c                	lw	a5,24(s1)
    80002822:	f94781e3          	beq	a5,s4,800027a4 <wait+0x56>
        release(&np->lock);
    80002826:	8526                	mv	a0,s1
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	482080e7          	jalr	1154(ra) # 80000caa <release>
        havekids = 1;
    80002830:	8756                	mv	a4,s5
    80002832:	bfd9                	j	80002808 <wait+0xba>
    if(!havekids || p->killed){
    80002834:	c701                	beqz	a4,8000283c <wait+0xee>
    80002836:	02892783          	lw	a5,40(s2)
    8000283a:	c79d                	beqz	a5,80002868 <wait+0x11a>
      release(&wait_lock);
    8000283c:	0000f517          	auipc	a0,0xf
    80002840:	edc50513          	addi	a0,a0,-292 # 80011718 <wait_lock>
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	466080e7          	jalr	1126(ra) # 80000caa <release>
      return -1;
    8000284c:	59fd                	li	s3,-1
}
    8000284e:	854e                	mv	a0,s3
    80002850:	60a6                	ld	ra,72(sp)
    80002852:	6406                	ld	s0,64(sp)
    80002854:	74e2                	ld	s1,56(sp)
    80002856:	7942                	ld	s2,48(sp)
    80002858:	79a2                	ld	s3,40(sp)
    8000285a:	7a02                	ld	s4,32(sp)
    8000285c:	6ae2                	ld	s5,24(sp)
    8000285e:	6b42                	ld	s6,16(sp)
    80002860:	6ba2                	ld	s7,8(sp)
    80002862:	6c02                	ld	s8,0(sp)
    80002864:	6161                	addi	sp,sp,80
    80002866:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002868:	85e2                	mv	a1,s8
    8000286a:	854a                	mv	a0,s2
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	e62080e7          	jalr	-414(ra) # 800026ce <sleep>
    havekids = 0;
    80002874:	b715                	j	80002798 <wait+0x4a>

0000000080002876 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup (void* chan){
    80002876:	7119                	addi	sp,sp,-128
    80002878:	fc86                	sd	ra,120(sp)
    8000287a:	f8a2                	sd	s0,112(sp)
    8000287c:	f4a6                	sd	s1,104(sp)
    8000287e:	f0ca                	sd	s2,96(sp)
    80002880:	ecce                	sd	s3,88(sp)
    80002882:	e8d2                	sd	s4,80(sp)
    80002884:	e4d6                	sd	s5,72(sp)
    80002886:	e0da                	sd	s6,64(sp)
    80002888:	fc5e                	sd	s7,56(sp)
    8000288a:	f862                	sd	s8,48(sp)
    8000288c:	f466                	sd	s9,40(sp)
    8000288e:	f06a                	sd	s10,32(sp)
    80002890:	ec6e                	sd	s11,24(sp)
    80002892:	0100                	addi	s0,sp,128
    80002894:	8c2a                	mv	s8,a0
  struct proc * p;
  struct spinlock *l1 = &sleeping_head;
  struct spinlock *l2;

  acquire(l1);
    80002896:	0000f497          	auipc	s1,0xf
    8000289a:	e9a48493          	addi	s1,s1,-358 # 80011730 <sleeping_head>
    8000289e:	8526                	mv	a0,s1
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	344080e7          	jalr	836(ra) # 80000be4 <acquire>

  // int pred = sleeping;
  int volatile *link = &sleeping;
    800028a8:	00006997          	auipc	s3,0x6
    800028ac:	02498993          	addi	s3,s3,36 # 800088cc <sleeping>
  struct spinlock *l1 = &sleeping_head;
    800028b0:	f8943423          	sd	s1,-120(s0)
  while (*link != -1){
    800028b4:	5bfd                	li	s7,-1
    800028b6:	18800b13          	li	s6,392
    p = &proc[*link];
    800028ba:	0000fa17          	auipc	s4,0xf
    800028be:	fbea0a13          	addi	s4,s4,-66 # 80011878 <proc>
    l2 = &p->linked_list_lock;
    acquire(l2);
     if(p != myproc()){
        acquire(&p->lock);
       if(p->chan == chan && p->state == SLEEPING) {
    800028c2:	4c89                	li	s9,2
          release(p->lock);
          inc_cpu_usage(cpui);
          #endif
         // add to list
          release(l1);
          insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    800028c4:	0000fd97          	auipc	s11,0xf
    800028c8:	eb4d8d93          	addi	s11,s11,-332 # 80011778 <cpus_head>
    800028cc:	0000fd17          	auipc	s10,0xf
    800028d0:	e14d0d13          	addi	s10,s10,-492 # 800116e0 <cpus_ll>
  while (*link != -1){
    800028d4:	0009a783          	lw	a5,0(s3)
    800028d8:	2781                	sext.w	a5,a5
    800028da:	0b778563          	beq	a5,s7,80002984 <wakeup+0x10e>
    p = &proc[*link];
    800028de:	0009a903          	lw	s2,0(s3)
    800028e2:	2901                	sext.w	s2,s2
    800028e4:	036904b3          	mul	s1,s2,s6
    800028e8:	01448ab3          	add	s5,s1,s4
    l2 = &p->linked_list_lock;
    800028ec:	04048493          	addi	s1,s1,64
    800028f0:	94d2                	add	s1,s1,s4
    acquire(l2);
    800028f2:	8526                	mv	a0,s1
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	2f0080e7          	jalr	752(ra) # 80000be4 <acquire>
     if(p != myproc()){
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	4f8080e7          	jalr	1272(ra) # 80001df4 <myproc>
    80002904:	fcaa88e3          	beq	s5,a0,800028d4 <wakeup+0x5e>
        acquire(&p->lock);
    80002908:	8556                	mv	a0,s5
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	2da080e7          	jalr	730(ra) # 80000be4 <acquire>
       if(p->chan == chan && p->state == SLEEPING) {
    80002912:	020ab783          	ld	a5,32(s5)
    80002916:	fb879fe3          	bne	a5,s8,800028d4 <wakeup+0x5e>
    8000291a:	018aa783          	lw	a5,24(s5)
    8000291e:	fb979be3          	bne	a5,s9,800028d4 <wakeup+0x5e>
         p->state = RUNNABLE;
    80002922:	478d                	li	a5,3
    80002924:	00faac23          	sw	a5,24(s5)
         release(&p->lock);
    80002928:	8556                	mv	a0,s5
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	380080e7          	jalr	896(ra) # 80000caa <release>
         *link = p->next;
    80002932:	03caa783          	lw	a5,60(s5)
    80002936:	2781                	sext.w	a5,a5
    80002938:	00f9a023          	sw	a5,0(s3)
         p->next = -1;
    8000293c:	57fd                	li	a5,-1
    8000293e:	02faae23          	sw	a5,60(s5)
          release(l1);
    80002942:	f8843503          	ld	a0,-120(s0)
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	364080e7          	jalr	868(ra) # 80000caa <release>
          insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    8000294e:	034aa783          	lw	a5,52(s5)
    80002952:	00179613          	slli	a2,a5,0x1
    80002956:	963e                	add	a2,a2,a5
    80002958:	060e                	slli	a2,a2,0x3
    8000295a:	078a                	slli	a5,a5,0x2
    8000295c:	966e                	add	a2,a2,s11
    8000295e:	00fd05b3          	add	a1,s10,a5
    80002962:	038aa503          	lw	a0,56(s5)
    80002966:	fffff097          	auipc	ra,0xfffff
    8000296a:	17e080e7          	jalr	382(ra) # 80001ae4 <insert_to_list>
          l1 = l2;
          link = &proc[*link].next;
    8000296e:	0009a983          	lw	s3,0(s3)
    80002972:	2981                	sext.w	s3,s3
    80002974:	036989b3          	mul	s3,s3,s6
    80002978:	03c98993          	addi	s3,s3,60
    8000297c:	99d2                	add	s3,s3,s4
    l2 = &p->linked_list_lock;
    8000297e:	f8943423          	sd	s1,-120(s0)
    80002982:	bf89                	j	800028d4 <wakeup+0x5e>
          // remove_from_list(p->index, &sleeping, &sleeping_head);
      }
    }  
  }
}
    80002984:	70e6                	ld	ra,120(sp)
    80002986:	7446                	ld	s0,112(sp)
    80002988:	74a6                	ld	s1,104(sp)
    8000298a:	7906                	ld	s2,96(sp)
    8000298c:	69e6                	ld	s3,88(sp)
    8000298e:	6a46                	ld	s4,80(sp)
    80002990:	6aa6                	ld	s5,72(sp)
    80002992:	6b06                	ld	s6,64(sp)
    80002994:	7be2                	ld	s7,56(sp)
    80002996:	7c42                	ld	s8,48(sp)
    80002998:	7ca2                	ld	s9,40(sp)
    8000299a:	7d02                	ld	s10,32(sp)
    8000299c:	6de2                	ld	s11,24(sp)
    8000299e:	6109                	addi	sp,sp,128
    800029a0:	8082                	ret

00000000800029a2 <reparent>:
{
    800029a2:	7179                	addi	sp,sp,-48
    800029a4:	f406                	sd	ra,40(sp)
    800029a6:	f022                	sd	s0,32(sp)
    800029a8:	ec26                	sd	s1,24(sp)
    800029aa:	e84a                	sd	s2,16(sp)
    800029ac:	e44e                	sd	s3,8(sp)
    800029ae:	e052                	sd	s4,0(sp)
    800029b0:	1800                	addi	s0,sp,48
    800029b2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800029b4:	0000f497          	auipc	s1,0xf
    800029b8:	ec448493          	addi	s1,s1,-316 # 80011878 <proc>
      pp->parent = initproc;
    800029bc:	00006a17          	auipc	s4,0x6
    800029c0:	66ca0a13          	addi	s4,s4,1644 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800029c4:	00015997          	auipc	s3,0x15
    800029c8:	0b498993          	addi	s3,s3,180 # 80017a78 <tickslock>
    800029cc:	a029                	j	800029d6 <reparent+0x34>
    800029ce:	18848493          	addi	s1,s1,392
    800029d2:	01348d63          	beq	s1,s3,800029ec <reparent+0x4a>
    if(pp->parent == p){
    800029d6:	6cbc                	ld	a5,88(s1)
    800029d8:	ff279be3          	bne	a5,s2,800029ce <reparent+0x2c>
      pp->parent = initproc;
    800029dc:	000a3503          	ld	a0,0(s4)
    800029e0:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800029e2:	00000097          	auipc	ra,0x0
    800029e6:	e94080e7          	jalr	-364(ra) # 80002876 <wakeup>
    800029ea:	b7d5                	j	800029ce <reparent+0x2c>
}
    800029ec:	70a2                	ld	ra,40(sp)
    800029ee:	7402                	ld	s0,32(sp)
    800029f0:	64e2                	ld	s1,24(sp)
    800029f2:	6942                	ld	s2,16(sp)
    800029f4:	69a2                	ld	s3,8(sp)
    800029f6:	6a02                	ld	s4,0(sp)
    800029f8:	6145                	addi	sp,sp,48
    800029fa:	8082                	ret

00000000800029fc <exit>:
{
    800029fc:	7179                	addi	sp,sp,-48
    800029fe:	f406                	sd	ra,40(sp)
    80002a00:	f022                	sd	s0,32(sp)
    80002a02:	ec26                	sd	s1,24(sp)
    80002a04:	e84a                	sd	s2,16(sp)
    80002a06:	e44e                	sd	s3,8(sp)
    80002a08:	e052                	sd	s4,0(sp)
    80002a0a:	1800                	addi	s0,sp,48
    80002a0c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002a0e:	fffff097          	auipc	ra,0xfffff
    80002a12:	3e6080e7          	jalr	998(ra) # 80001df4 <myproc>
    80002a16:	89aa                	mv	s3,a0
  if(p == initproc)
    80002a18:	00006797          	auipc	a5,0x6
    80002a1c:	6107b783          	ld	a5,1552(a5) # 80009028 <initproc>
    80002a20:	0f050493          	addi	s1,a0,240
    80002a24:	17050913          	addi	s2,a0,368
    80002a28:	02a79363          	bne	a5,a0,80002a4e <exit+0x52>
    panic("init exiting");
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	8cc50513          	addi	a0,a0,-1844 # 800082f8 <digits+0x2b8>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>
      fileclose(f);
    80002a3c:	00002097          	auipc	ra,0x2
    80002a40:	2e2080e7          	jalr	738(ra) # 80004d1e <fileclose>
      p->ofile[fd] = 0;
    80002a44:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a48:	04a1                	addi	s1,s1,8
    80002a4a:	01248563          	beq	s1,s2,80002a54 <exit+0x58>
    if(p->ofile[fd]){
    80002a4e:	6088                	ld	a0,0(s1)
    80002a50:	f575                	bnez	a0,80002a3c <exit+0x40>
    80002a52:	bfdd                	j	80002a48 <exit+0x4c>
  begin_op();
    80002a54:	00002097          	auipc	ra,0x2
    80002a58:	dfe080e7          	jalr	-514(ra) # 80004852 <begin_op>
  iput(p->cwd);
    80002a5c:	1709b503          	ld	a0,368(s3)
    80002a60:	00001097          	auipc	ra,0x1
    80002a64:	5da080e7          	jalr	1498(ra) # 8000403a <iput>
  end_op();
    80002a68:	00002097          	auipc	ra,0x2
    80002a6c:	e6a080e7          	jalr	-406(ra) # 800048d2 <end_op>
  p->cwd = 0;
    80002a70:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002a74:	0000f497          	auipc	s1,0xf
    80002a78:	ca448493          	addi	s1,s1,-860 # 80011718 <wait_lock>
    80002a7c:	8526                	mv	a0,s1
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	166080e7          	jalr	358(ra) # 80000be4 <acquire>
  reparent(p);
    80002a86:	854e                	mv	a0,s3
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	f1a080e7          	jalr	-230(ra) # 800029a2 <reparent>
  wakeup(p->parent);
    80002a90:	0589b503          	ld	a0,88(s3)
    80002a94:	00000097          	auipc	ra,0x0
    80002a98:	de2080e7          	jalr	-542(ra) # 80002876 <wakeup>
  acquire(&p->lock);
    80002a9c:	854e                	mv	a0,s3
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	146080e7          	jalr	326(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002aa6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002aaa:	4795                	li	a5,5
    80002aac:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index, &zombie, &zombie_head);
    80002ab0:	0000f617          	auipc	a2,0xf
    80002ab4:	c9860613          	addi	a2,a2,-872 # 80011748 <zombie_head>
    80002ab8:	00006597          	auipc	a1,0x6
    80002abc:	e1058593          	addi	a1,a1,-496 # 800088c8 <zombie>
    80002ac0:	0389a503          	lw	a0,56(s3)
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	020080e7          	jalr	32(ra) # 80001ae4 <insert_to_list>
  release(&wait_lock);
    80002acc:	8526                	mv	a0,s1
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	1dc080e7          	jalr	476(ra) # 80000caa <release>
  sched();
    80002ad6:	00000097          	auipc	ra,0x0
    80002ada:	aa4080e7          	jalr	-1372(ra) # 8000257a <sched>
  panic("zombie exit");
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	82a50513          	addi	a0,a0,-2006 # 80008308 <digits+0x2c8>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	a58080e7          	jalr	-1448(ra) # 8000053e <panic>

0000000080002aee <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002aee:	7179                	addi	sp,sp,-48
    80002af0:	f406                	sd	ra,40(sp)
    80002af2:	f022                	sd	s0,32(sp)
    80002af4:	ec26                	sd	s1,24(sp)
    80002af6:	e84a                	sd	s2,16(sp)
    80002af8:	e44e                	sd	s3,8(sp)
    80002afa:	1800                	addi	s0,sp,48
    80002afc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002afe:	0000f497          	auipc	s1,0xf
    80002b02:	d7a48493          	addi	s1,s1,-646 # 80011878 <proc>
    80002b06:	00015997          	auipc	s3,0x15
    80002b0a:	f7298993          	addi	s3,s3,-142 # 80017a78 <tickslock>
    acquire(&p->lock);
    80002b0e:	8526                	mv	a0,s1
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	0d4080e7          	jalr	212(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002b18:	589c                	lw	a5,48(s1)
    80002b1a:	01278d63          	beq	a5,s2,80002b34 <kill+0x46>
      release(&p->lock);
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
      }
      return 0;
    }
    release(&p->lock);
    80002b1e:	8526                	mv	a0,s1
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	18a080e7          	jalr	394(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b28:	18848493          	addi	s1,s1,392
    80002b2c:	ff3491e3          	bne	s1,s3,80002b0e <kill+0x20>
  }
  return -1;
    80002b30:	557d                	li	a0,-1
    80002b32:	a831                	j	80002b4e <kill+0x60>
      p->killed = 1;
    80002b34:	4785                	li	a5,1
    80002b36:	d49c                	sw	a5,40(s1)
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002b38:	460d                	li	a2,3
    80002b3a:	4589                	li	a1,2
    80002b3c:	01848513          	addi	a0,s1,24
    80002b40:	00004097          	auipc	ra,0x4
    80002b44:	ed6080e7          	jalr	-298(ra) # 80006a16 <cas>
    80002b48:	87aa                	mv	a5,a0
      return 0;
    80002b4a:	4501                	li	a0,0
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002b4c:	cb81                	beqz	a5,80002b5c <kill+0x6e>
}
    80002b4e:	70a2                	ld	ra,40(sp)
    80002b50:	7402                	ld	s0,32(sp)
    80002b52:	64e2                	ld	s1,24(sp)
    80002b54:	6942                	ld	s2,16(sp)
    80002b56:	69a2                	ld	s3,8(sp)
    80002b58:	6145                	addi	sp,sp,48
    80002b5a:	8082                	ret
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002b5c:	0000f617          	auipc	a2,0xf
    80002b60:	bd460613          	addi	a2,a2,-1068 # 80011730 <sleeping_head>
    80002b64:	00006597          	auipc	a1,0x6
    80002b68:	d6858593          	addi	a1,a1,-664 # 800088cc <sleeping>
    80002b6c:	5c88                	lw	a0,56(s1)
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	d3c080e7          	jalr	-708(ra) # 800018aa <remove_from_list>
        p->state = RUNNABLE;
    80002b76:	478d                	li	a5,3
    80002b78:	cc9c                	sw	a5,24(s1)
      release(&p->lock);
    80002b7a:	8526                	mv	a0,s1
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	12e080e7          	jalr	302(ra) # 80000caa <release>
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002b84:	58cc                	lw	a1,52(s1)
    80002b86:	00159793          	slli	a5,a1,0x1
    80002b8a:	97ae                	add	a5,a5,a1
    80002b8c:	078e                	slli	a5,a5,0x3
    80002b8e:	058a                	slli	a1,a1,0x2
    80002b90:	0000f617          	auipc	a2,0xf
    80002b94:	be860613          	addi	a2,a2,-1048 # 80011778 <cpus_head>
    80002b98:	963e                	add	a2,a2,a5
    80002b9a:	0000f797          	auipc	a5,0xf
    80002b9e:	b4678793          	addi	a5,a5,-1210 # 800116e0 <cpus_ll>
    80002ba2:	95be                	add	a1,a1,a5
    80002ba4:	5c88                	lw	a0,56(s1)
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	f3e080e7          	jalr	-194(ra) # 80001ae4 <insert_to_list>
      return 0;
    80002bae:	4501                	li	a0,0
    80002bb0:	bf79                	j	80002b4e <kill+0x60>

0000000080002bb2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len){
    80002bb2:	7179                	addi	sp,sp,-48
    80002bb4:	f406                	sd	ra,40(sp)
    80002bb6:	f022                	sd	s0,32(sp)
    80002bb8:	ec26                	sd	s1,24(sp)
    80002bba:	e84a                	sd	s2,16(sp)
    80002bbc:	e44e                	sd	s3,8(sp)
    80002bbe:	e052                	sd	s4,0(sp)
    80002bc0:	1800                	addi	s0,sp,48
    80002bc2:	84aa                	mv	s1,a0
    80002bc4:	892e                	mv	s2,a1
    80002bc6:	89b2                	mv	s3,a2
    80002bc8:	8a36                	mv	s4,a3

  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	22a080e7          	jalr	554(ra) # 80001df4 <myproc>
  if(user_dst){
    80002bd2:	c08d                	beqz	s1,80002bf4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002bd4:	86d2                	mv	a3,s4
    80002bd6:	864e                	mv	a2,s3
    80002bd8:	85ca                	mv	a1,s2
    80002bda:	7928                	ld	a0,112(a0)
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	aba080e7          	jalr	-1350(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002be4:	70a2                	ld	ra,40(sp)
    80002be6:	7402                	ld	s0,32(sp)
    80002be8:	64e2                	ld	s1,24(sp)
    80002bea:	6942                	ld	s2,16(sp)
    80002bec:	69a2                	ld	s3,8(sp)
    80002bee:	6a02                	ld	s4,0(sp)
    80002bf0:	6145                	addi	sp,sp,48
    80002bf2:	8082                	ret
    memmove((char *)dst, src, len);
    80002bf4:	000a061b          	sext.w	a2,s4
    80002bf8:	85ce                	mv	a1,s3
    80002bfa:	854a                	mv	a0,s2
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	168080e7          	jalr	360(ra) # 80000d64 <memmove>
    return 0;
    80002c04:	8526                	mv	a0,s1
    80002c06:	bff9                	j	80002be4 <either_copyout+0x32>

0000000080002c08 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c08:	7179                	addi	sp,sp,-48
    80002c0a:	f406                	sd	ra,40(sp)
    80002c0c:	f022                	sd	s0,32(sp)
    80002c0e:	ec26                	sd	s1,24(sp)
    80002c10:	e84a                	sd	s2,16(sp)
    80002c12:	e44e                	sd	s3,8(sp)
    80002c14:	e052                	sd	s4,0(sp)
    80002c16:	1800                	addi	s0,sp,48
    80002c18:	892a                	mv	s2,a0
    80002c1a:	84ae                	mv	s1,a1
    80002c1c:	89b2                	mv	s3,a2
    80002c1e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	1d4080e7          	jalr	468(ra) # 80001df4 <myproc>
  if(user_src){
    80002c28:	c08d                	beqz	s1,80002c4a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002c2a:	86d2                	mv	a3,s4
    80002c2c:	864e                	mv	a2,s3
    80002c2e:	85ca                	mv	a1,s2
    80002c30:	7928                	ld	a0,112(a0)
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	af0080e7          	jalr	-1296(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002c3a:	70a2                	ld	ra,40(sp)
    80002c3c:	7402                	ld	s0,32(sp)
    80002c3e:	64e2                	ld	s1,24(sp)
    80002c40:	6942                	ld	s2,16(sp)
    80002c42:	69a2                	ld	s3,8(sp)
    80002c44:	6a02                	ld	s4,0(sp)
    80002c46:	6145                	addi	sp,sp,48
    80002c48:	8082                	ret
    memmove(dst, (char*)src, len);
    80002c4a:	000a061b          	sext.w	a2,s4
    80002c4e:	85ce                	mv	a1,s3
    80002c50:	854a                	mv	a0,s2
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	112080e7          	jalr	274(ra) # 80000d64 <memmove>
    return 0;
    80002c5a:	8526                	mv	a0,s1
    80002c5c:	bff9                	j	80002c3a <either_copyin+0x32>

0000000080002c5e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002c5e:	715d                	addi	sp,sp,-80
    80002c60:	e486                	sd	ra,72(sp)
    80002c62:	e0a2                	sd	s0,64(sp)
    80002c64:	fc26                	sd	s1,56(sp)
    80002c66:	f84a                	sd	s2,48(sp)
    80002c68:	f44e                	sd	s3,40(sp)
    80002c6a:	f052                	sd	s4,32(sp)
    80002c6c:	ec56                	sd	s5,24(sp)
    80002c6e:	e85a                	sd	s6,16(sp)
    80002c70:	e45e                	sd	s7,8(sp)
    80002c72:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	48450513          	addi	a0,a0,1156 # 800080f8 <digits+0xb8>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	90c080e7          	jalr	-1780(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c84:	0000f497          	auipc	s1,0xf
    80002c88:	d6c48493          	addi	s1,s1,-660 # 800119f0 <proc+0x178>
    80002c8c:	00015917          	auipc	s2,0x15
    80002c90:	f6490913          	addi	s2,s2,-156 # 80017bf0 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c94:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002c96:	00005997          	auipc	s3,0x5
    80002c9a:	68298993          	addi	s3,s3,1666 # 80008318 <digits+0x2d8>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002c9e:	00005a97          	auipc	s5,0x5
    80002ca2:	682a8a93          	addi	s5,s5,1666 # 80008320 <digits+0x2e0>
    printf("\n");
    80002ca6:	00005a17          	auipc	s4,0x5
    80002caa:	452a0a13          	addi	s4,s4,1106 # 800080f8 <digits+0xb8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cae:	00005b97          	auipc	s7,0x5
    80002cb2:	6aab8b93          	addi	s7,s7,1706 # 80008358 <states.1787>
    80002cb6:	a01d                	j	80002cdc <procdump+0x7e>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002cb8:	ebc6a703          	lw	a4,-324(a3)
    80002cbc:	eb86a583          	lw	a1,-328(a3)
    80002cc0:	8556                	mv	a0,s5
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c6080e7          	jalr	-1850(ra) # 80000588 <printf>
    printf("\n");
    80002cca:	8552                	mv	a0,s4
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	8bc080e7          	jalr	-1860(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002cd4:	18848493          	addi	s1,s1,392
    80002cd8:	03248163          	beq	s1,s2,80002cfa <procdump+0x9c>
    if(p->state == UNUSED)
    80002cdc:	86a6                	mv	a3,s1
    80002cde:	ea04a783          	lw	a5,-352(s1)
    80002ce2:	dbed                	beqz	a5,80002cd4 <procdump+0x76>
      state = "???";
    80002ce4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ce6:	fcfb69e3          	bltu	s6,a5,80002cb8 <procdump+0x5a>
    80002cea:	1782                	slli	a5,a5,0x20
    80002cec:	9381                	srli	a5,a5,0x20
    80002cee:	078e                	slli	a5,a5,0x3
    80002cf0:	97de                	add	a5,a5,s7
    80002cf2:	6390                	ld	a2,0(a5)
    80002cf4:	f271                	bnez	a2,80002cb8 <procdump+0x5a>
      state = "???";
    80002cf6:	864e                	mv	a2,s3
    80002cf8:	b7c1                	j	80002cb8 <procdump+0x5a>
  }
}
    80002cfa:	60a6                	ld	ra,72(sp)
    80002cfc:	6406                	ld	s0,64(sp)
    80002cfe:	74e2                	ld	s1,56(sp)
    80002d00:	7942                	ld	s2,48(sp)
    80002d02:	79a2                	ld	s3,40(sp)
    80002d04:	7a02                	ld	s4,32(sp)
    80002d06:	6ae2                	ld	s5,24(sp)
    80002d08:	6b42                	ld	s6,16(sp)
    80002d0a:	6ba2                	ld	s7,8(sp)
    80002d0c:	6161                	addi	sp,sp,80
    80002d0e:	8082                	ret

0000000080002d10 <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002d10:	1101                	addi	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	1000                	addi	s0,sp,32
    80002d1a:	84aa                	mv	s1,a0
// printf("%d\n", 12);
  struct proc *p= myproc();  
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	0d8080e7          	jalr	216(ra) # 80001df4 <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002d24:	8626                	mv	a2,s1
    80002d26:	594c                	lw	a1,52(a0)
    80002d28:	03450513          	addi	a0,a0,52
    80002d2c:	00004097          	auipc	ra,0x4
    80002d30:	cea080e7          	jalr	-790(ra) # 80006a16 <cas>
    80002d34:	e519                	bnez	a0,80002d42 <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002d36:	4501                	li	a0,0
}
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	64a2                	ld	s1,8(sp)
    80002d3e:	6105                	addi	sp,sp,32
    80002d40:	8082                	ret
    yield();
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	926080e7          	jalr	-1754(ra) # 80002668 <yield>
    return cpu_num;
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	b7f5                	j	80002d38 <set_cpu+0x28>

0000000080002d4e <get_cpu>:

int get_cpu(){ //added as orderd
    80002d4e:	1101                	addi	sp,sp,-32
    80002d50:	ec06                	sd	ra,24(sp)
    80002d52:	e822                	sd	s0,16(sp)
    80002d54:	1000                	addi	s0,sp,32
// printf("%d\n", 13);
  struct proc *p = myproc();
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	09e080e7          	jalr	158(ra) # 80001df4 <myproc>
  int ans=0;
    80002d5e:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002d62:	5950                	lw	a2,52(a0)
    80002d64:	4581                	li	a1,0
    80002d66:	fec40513          	addi	a0,s0,-20
    80002d6a:	00004097          	auipc	ra,0x4
    80002d6e:	cac080e7          	jalr	-852(ra) # 80006a16 <cas>
    return ans;
}
    80002d72:	fec42503          	lw	a0,-20(s0)
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <cpu_process_count>:

// int cpu_process_count (int cpu_num){
//   return cpu_usage[cpu_num];
// }
int cpu_process_count(int cpu_num){
    80002d7e:	1141                	addi	sp,sp,-16
    80002d80:	e422                	sd	s0,8(sp)
    80002d82:	0800                	addi	s0,sp,16
  struct cpu* c = &cpus[cpu_num];
  uint64 procsNum = c->admittedProcs;
    80002d84:	00451793          	slli	a5,a0,0x4
    80002d88:	97aa                	add	a5,a5,a0
    80002d8a:	078e                	slli	a5,a5,0x3
    80002d8c:	0000e517          	auipc	a0,0xe
    80002d90:	51450513          	addi	a0,a0,1300 # 800112a0 <cpus>
    80002d94:	97aa                	add	a5,a5,a0
  return procsNum;
}
    80002d96:	0807a503          	lw	a0,128(a5)
    80002d9a:	6422                	ld	s0,8(sp)
    80002d9c:	0141                	addi	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <swtch>:
    80002da0:	00153023          	sd	ra,0(a0)
    80002da4:	00253423          	sd	sp,8(a0)
    80002da8:	e900                	sd	s0,16(a0)
    80002daa:	ed04                	sd	s1,24(a0)
    80002dac:	03253023          	sd	s2,32(a0)
    80002db0:	03353423          	sd	s3,40(a0)
    80002db4:	03453823          	sd	s4,48(a0)
    80002db8:	03553c23          	sd	s5,56(a0)
    80002dbc:	05653023          	sd	s6,64(a0)
    80002dc0:	05753423          	sd	s7,72(a0)
    80002dc4:	05853823          	sd	s8,80(a0)
    80002dc8:	05953c23          	sd	s9,88(a0)
    80002dcc:	07a53023          	sd	s10,96(a0)
    80002dd0:	07b53423          	sd	s11,104(a0)
    80002dd4:	0005b083          	ld	ra,0(a1)
    80002dd8:	0085b103          	ld	sp,8(a1)
    80002ddc:	6980                	ld	s0,16(a1)
    80002dde:	6d84                	ld	s1,24(a1)
    80002de0:	0205b903          	ld	s2,32(a1)
    80002de4:	0285b983          	ld	s3,40(a1)
    80002de8:	0305ba03          	ld	s4,48(a1)
    80002dec:	0385ba83          	ld	s5,56(a1)
    80002df0:	0405bb03          	ld	s6,64(a1)
    80002df4:	0485bb83          	ld	s7,72(a1)
    80002df8:	0505bc03          	ld	s8,80(a1)
    80002dfc:	0585bc83          	ld	s9,88(a1)
    80002e00:	0605bd03          	ld	s10,96(a1)
    80002e04:	0685bd83          	ld	s11,104(a1)
    80002e08:	8082                	ret

0000000080002e0a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002e0a:	1141                	addi	sp,sp,-16
    80002e0c:	e406                	sd	ra,8(sp)
    80002e0e:	e022                	sd	s0,0(sp)
    80002e10:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e12:	00005597          	auipc	a1,0x5
    80002e16:	57658593          	addi	a1,a1,1398 # 80008388 <states.1787+0x30>
    80002e1a:	00015517          	auipc	a0,0x15
    80002e1e:	c5e50513          	addi	a0,a0,-930 # 80017a78 <tickslock>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	d32080e7          	jalr	-718(ra) # 80000b54 <initlock>
}
    80002e2a:	60a2                	ld	ra,8(sp)
    80002e2c:	6402                	ld	s0,0(sp)
    80002e2e:	0141                	addi	sp,sp,16
    80002e30:	8082                	ret

0000000080002e32 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e32:	1141                	addi	sp,sp,-16
    80002e34:	e422                	sd	s0,8(sp)
    80002e36:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e38:	00003797          	auipc	a5,0x3
    80002e3c:	50878793          	addi	a5,a5,1288 # 80006340 <kernelvec>
    80002e40:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e44:	6422                	ld	s0,8(sp)
    80002e46:	0141                	addi	sp,sp,16
    80002e48:	8082                	ret

0000000080002e4a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e4a:	1141                	addi	sp,sp,-16
    80002e4c:	e406                	sd	ra,8(sp)
    80002e4e:	e022                	sd	s0,0(sp)
    80002e50:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	fa2080e7          	jalr	-94(ra) # 80001df4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e5e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e60:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e64:	00004617          	auipc	a2,0x4
    80002e68:	19c60613          	addi	a2,a2,412 # 80007000 <_trampoline>
    80002e6c:	00004697          	auipc	a3,0x4
    80002e70:	19468693          	addi	a3,a3,404 # 80007000 <_trampoline>
    80002e74:	8e91                	sub	a3,a3,a2
    80002e76:	040007b7          	lui	a5,0x4000
    80002e7a:	17fd                	addi	a5,a5,-1
    80002e7c:	07b2                	slli	a5,a5,0xc
    80002e7e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e80:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e84:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e86:	180026f3          	csrr	a3,satp
    80002e8a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e8c:	7d38                	ld	a4,120(a0)
    80002e8e:	7134                	ld	a3,96(a0)
    80002e90:	6585                	lui	a1,0x1
    80002e92:	96ae                	add	a3,a3,a1
    80002e94:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e96:	7d38                	ld	a4,120(a0)
    80002e98:	00000697          	auipc	a3,0x0
    80002e9c:	13868693          	addi	a3,a3,312 # 80002fd0 <usertrap>
    80002ea0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ea2:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ea4:	8692                	mv	a3,tp
    80002ea6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002eac:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002eb0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eb4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002eb8:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eba:	6f18                	ld	a4,24(a4)
    80002ebc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ec0:	792c                	ld	a1,112(a0)
    80002ec2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ec4:	00004717          	auipc	a4,0x4
    80002ec8:	1cc70713          	addi	a4,a4,460 # 80007090 <userret>
    80002ecc:	8f11                	sub	a4,a4,a2
    80002ece:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ed0:	577d                	li	a4,-1
    80002ed2:	177e                	slli	a4,a4,0x3f
    80002ed4:	8dd9                	or	a1,a1,a4
    80002ed6:	02000537          	lui	a0,0x2000
    80002eda:	157d                	addi	a0,a0,-1
    80002edc:	0536                	slli	a0,a0,0xd
    80002ede:	9782                	jalr	a5
}
    80002ee0:	60a2                	ld	ra,8(sp)
    80002ee2:	6402                	ld	s0,0(sp)
    80002ee4:	0141                	addi	sp,sp,16
    80002ee6:	8082                	ret

0000000080002ee8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ee8:	1101                	addi	sp,sp,-32
    80002eea:	ec06                	sd	ra,24(sp)
    80002eec:	e822                	sd	s0,16(sp)
    80002eee:	e426                	sd	s1,8(sp)
    80002ef0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ef2:	00015497          	auipc	s1,0x15
    80002ef6:	b8648493          	addi	s1,s1,-1146 # 80017a78 <tickslock>
    80002efa:	8526                	mv	a0,s1
    80002efc:	ffffe097          	auipc	ra,0xffffe
    80002f00:	ce8080e7          	jalr	-792(ra) # 80000be4 <acquire>
  ticks++;
    80002f04:	00006517          	auipc	a0,0x6
    80002f08:	12c50513          	addi	a0,a0,300 # 80009030 <ticks>
    80002f0c:	411c                	lw	a5,0(a0)
    80002f0e:	2785                	addiw	a5,a5,1
    80002f10:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f12:	00000097          	auipc	ra,0x0
    80002f16:	964080e7          	jalr	-1692(ra) # 80002876 <wakeup>
  release(&tickslock);
    80002f1a:	8526                	mv	a0,s1
    80002f1c:	ffffe097          	auipc	ra,0xffffe
    80002f20:	d8e080e7          	jalr	-626(ra) # 80000caa <release>
}
    80002f24:	60e2                	ld	ra,24(sp)
    80002f26:	6442                	ld	s0,16(sp)
    80002f28:	64a2                	ld	s1,8(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret

0000000080002f2e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f2e:	1101                	addi	sp,sp,-32
    80002f30:	ec06                	sd	ra,24(sp)
    80002f32:	e822                	sd	s0,16(sp)
    80002f34:	e426                	sd	s1,8(sp)
    80002f36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f38:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f3c:	00074d63          	bltz	a4,80002f56 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f40:	57fd                	li	a5,-1
    80002f42:	17fe                	slli	a5,a5,0x3f
    80002f44:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f46:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f48:	06f70363          	beq	a4,a5,80002fae <devintr+0x80>
  }
}
    80002f4c:	60e2                	ld	ra,24(sp)
    80002f4e:	6442                	ld	s0,16(sp)
    80002f50:	64a2                	ld	s1,8(sp)
    80002f52:	6105                	addi	sp,sp,32
    80002f54:	8082                	ret
     (scause & 0xff) == 9){
    80002f56:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f5a:	46a5                	li	a3,9
    80002f5c:	fed792e3          	bne	a5,a3,80002f40 <devintr+0x12>
    int irq = plic_claim();
    80002f60:	00003097          	auipc	ra,0x3
    80002f64:	4e8080e7          	jalr	1256(ra) # 80006448 <plic_claim>
    80002f68:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f6a:	47a9                	li	a5,10
    80002f6c:	02f50763          	beq	a0,a5,80002f9a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f70:	4785                	li	a5,1
    80002f72:	02f50963          	beq	a0,a5,80002fa4 <devintr+0x76>
    return 1;
    80002f76:	4505                	li	a0,1
    } else if(irq){
    80002f78:	d8f1                	beqz	s1,80002f4c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f7a:	85a6                	mv	a1,s1
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	41450513          	addi	a0,a0,1044 # 80008390 <states.1787+0x38>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	604080e7          	jalr	1540(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f8c:	8526                	mv	a0,s1
    80002f8e:	00003097          	auipc	ra,0x3
    80002f92:	4de080e7          	jalr	1246(ra) # 8000646c <plic_complete>
    return 1;
    80002f96:	4505                	li	a0,1
    80002f98:	bf55                	j	80002f4c <devintr+0x1e>
      uartintr();
    80002f9a:	ffffe097          	auipc	ra,0xffffe
    80002f9e:	a0e080e7          	jalr	-1522(ra) # 800009a8 <uartintr>
    80002fa2:	b7ed                	j	80002f8c <devintr+0x5e>
      virtio_disk_intr();
    80002fa4:	00004097          	auipc	ra,0x4
    80002fa8:	9a8080e7          	jalr	-1624(ra) # 8000694c <virtio_disk_intr>
    80002fac:	b7c5                	j	80002f8c <devintr+0x5e>
    if(cpuid() == 0){
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	e12080e7          	jalr	-494(ra) # 80001dc0 <cpuid>
    80002fb6:	c901                	beqz	a0,80002fc6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002fb8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002fbc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002fbe:	14479073          	csrw	sip,a5
    return 2;
    80002fc2:	4509                	li	a0,2
    80002fc4:	b761                	j	80002f4c <devintr+0x1e>
      clockintr();
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	f22080e7          	jalr	-222(ra) # 80002ee8 <clockintr>
    80002fce:	b7ed                	j	80002fb8 <devintr+0x8a>

0000000080002fd0 <usertrap>:
{
    80002fd0:	1101                	addi	sp,sp,-32
    80002fd2:	ec06                	sd	ra,24(sp)
    80002fd4:	e822                	sd	s0,16(sp)
    80002fd6:	e426                	sd	s1,8(sp)
    80002fd8:	e04a                	sd	s2,0(sp)
    80002fda:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fdc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002fe0:	1007f793          	andi	a5,a5,256
    80002fe4:	e3ad                	bnez	a5,80003046 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fe6:	00003797          	auipc	a5,0x3
    80002fea:	35a78793          	addi	a5,a5,858 # 80006340 <kernelvec>
    80002fee:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	e02080e7          	jalr	-510(ra) # 80001df4 <myproc>
    80002ffa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ffc:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ffe:	14102773          	csrr	a4,sepc
    80003002:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003004:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003008:	47a1                	li	a5,8
    8000300a:	04f71c63          	bne	a4,a5,80003062 <usertrap+0x92>
    if(p->killed)
    8000300e:	551c                	lw	a5,40(a0)
    80003010:	e3b9                	bnez	a5,80003056 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003012:	7cb8                	ld	a4,120(s1)
    80003014:	6f1c                	ld	a5,24(a4)
    80003016:	0791                	addi	a5,a5,4
    80003018:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000301a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000301e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003022:	10079073          	csrw	sstatus,a5
    syscall();
    80003026:	00000097          	auipc	ra,0x0
    8000302a:	2e0080e7          	jalr	736(ra) # 80003306 <syscall>
  if(p->killed)
    8000302e:	549c                	lw	a5,40(s1)
    80003030:	ebc1                	bnez	a5,800030c0 <usertrap+0xf0>
  usertrapret();
    80003032:	00000097          	auipc	ra,0x0
    80003036:	e18080e7          	jalr	-488(ra) # 80002e4a <usertrapret>
}
    8000303a:	60e2                	ld	ra,24(sp)
    8000303c:	6442                	ld	s0,16(sp)
    8000303e:	64a2                	ld	s1,8(sp)
    80003040:	6902                	ld	s2,0(sp)
    80003042:	6105                	addi	sp,sp,32
    80003044:	8082                	ret
    panic("usertrap: not from user mode");
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	36a50513          	addi	a0,a0,874 # 800083b0 <states.1787+0x58>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	4f0080e7          	jalr	1264(ra) # 8000053e <panic>
      exit(-1);
    80003056:	557d                	li	a0,-1
    80003058:	00000097          	auipc	ra,0x0
    8000305c:	9a4080e7          	jalr	-1628(ra) # 800029fc <exit>
    80003060:	bf4d                	j	80003012 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003062:	00000097          	auipc	ra,0x0
    80003066:	ecc080e7          	jalr	-308(ra) # 80002f2e <devintr>
    8000306a:	892a                	mv	s2,a0
    8000306c:	c501                	beqz	a0,80003074 <usertrap+0xa4>
  if(p->killed)
    8000306e:	549c                	lw	a5,40(s1)
    80003070:	c3a1                	beqz	a5,800030b0 <usertrap+0xe0>
    80003072:	a815                	j	800030a6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003074:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003078:	5890                	lw	a2,48(s1)
    8000307a:	00005517          	auipc	a0,0x5
    8000307e:	35650513          	addi	a0,a0,854 # 800083d0 <states.1787+0x78>
    80003082:	ffffd097          	auipc	ra,0xffffd
    80003086:	506080e7          	jalr	1286(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000308a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000308e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003092:	00005517          	auipc	a0,0x5
    80003096:	36e50513          	addi	a0,a0,878 # 80008400 <states.1787+0xa8>
    8000309a:	ffffd097          	auipc	ra,0xffffd
    8000309e:	4ee080e7          	jalr	1262(ra) # 80000588 <printf>
    p->killed = 1;
    800030a2:	4785                	li	a5,1
    800030a4:	d49c                	sw	a5,40(s1)
    exit(-1);
    800030a6:	557d                	li	a0,-1
    800030a8:	00000097          	auipc	ra,0x0
    800030ac:	954080e7          	jalr	-1708(ra) # 800029fc <exit>
  if(which_dev == 2)
    800030b0:	4789                	li	a5,2
    800030b2:	f8f910e3          	bne	s2,a5,80003032 <usertrap+0x62>
    yield();
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	5b2080e7          	jalr	1458(ra) # 80002668 <yield>
    800030be:	bf95                	j	80003032 <usertrap+0x62>
  int which_dev = 0;
    800030c0:	4901                	li	s2,0
    800030c2:	b7d5                	j	800030a6 <usertrap+0xd6>

00000000800030c4 <kerneltrap>:
{
    800030c4:	7179                	addi	sp,sp,-48
    800030c6:	f406                	sd	ra,40(sp)
    800030c8:	f022                	sd	s0,32(sp)
    800030ca:	ec26                	sd	s1,24(sp)
    800030cc:	e84a                	sd	s2,16(sp)
    800030ce:	e44e                	sd	s3,8(sp)
    800030d0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030d2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030d6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030da:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800030de:	1004f793          	andi	a5,s1,256
    800030e2:	cb85                	beqz	a5,80003112 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030e4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030e8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800030ea:	ef85                	bnez	a5,80003122 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	e42080e7          	jalr	-446(ra) # 80002f2e <devintr>
    800030f4:	cd1d                	beqz	a0,80003132 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030f6:	4789                	li	a5,2
    800030f8:	06f50a63          	beq	a0,a5,8000316c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030fc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003100:	10049073          	csrw	sstatus,s1
}
    80003104:	70a2                	ld	ra,40(sp)
    80003106:	7402                	ld	s0,32(sp)
    80003108:	64e2                	ld	s1,24(sp)
    8000310a:	6942                	ld	s2,16(sp)
    8000310c:	69a2                	ld	s3,8(sp)
    8000310e:	6145                	addi	sp,sp,48
    80003110:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003112:	00005517          	auipc	a0,0x5
    80003116:	30e50513          	addi	a0,a0,782 # 80008420 <states.1787+0xc8>
    8000311a:	ffffd097          	auipc	ra,0xffffd
    8000311e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003122:	00005517          	auipc	a0,0x5
    80003126:	32650513          	addi	a0,a0,806 # 80008448 <states.1787+0xf0>
    8000312a:	ffffd097          	auipc	ra,0xffffd
    8000312e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003132:	85ce                	mv	a1,s3
    80003134:	00005517          	auipc	a0,0x5
    80003138:	33450513          	addi	a0,a0,820 # 80008468 <states.1787+0x110>
    8000313c:	ffffd097          	auipc	ra,0xffffd
    80003140:	44c080e7          	jalr	1100(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003144:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003148:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	32c50513          	addi	a0,a0,812 # 80008478 <states.1787+0x120>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	434080e7          	jalr	1076(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	33450513          	addi	a0,a0,820 # 80008490 <states.1787+0x138>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	c88080e7          	jalr	-888(ra) # 80001df4 <myproc>
    80003174:	d541                	beqz	a0,800030fc <kerneltrap+0x38>
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	c7e080e7          	jalr	-898(ra) # 80001df4 <myproc>
    8000317e:	4d18                	lw	a4,24(a0)
    80003180:	4791                	li	a5,4
    80003182:	f6f71de3          	bne	a4,a5,800030fc <kerneltrap+0x38>
    yield();
    80003186:	fffff097          	auipc	ra,0xfffff
    8000318a:	4e2080e7          	jalr	1250(ra) # 80002668 <yield>
    8000318e:	b7bd                	j	800030fc <kerneltrap+0x38>

0000000080003190 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	e426                	sd	s1,8(sp)
    80003198:	1000                	addi	s0,sp,32
    8000319a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	c58080e7          	jalr	-936(ra) # 80001df4 <myproc>
  switch (n) {
    800031a4:	4795                	li	a5,5
    800031a6:	0497e163          	bltu	a5,s1,800031e8 <argraw+0x58>
    800031aa:	048a                	slli	s1,s1,0x2
    800031ac:	00005717          	auipc	a4,0x5
    800031b0:	31c70713          	addi	a4,a4,796 # 800084c8 <states.1787+0x170>
    800031b4:	94ba                	add	s1,s1,a4
    800031b6:	409c                	lw	a5,0(s1)
    800031b8:	97ba                	add	a5,a5,a4
    800031ba:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031bc:	7d3c                	ld	a5,120(a0)
    800031be:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031c0:	60e2                	ld	ra,24(sp)
    800031c2:	6442                	ld	s0,16(sp)
    800031c4:	64a2                	ld	s1,8(sp)
    800031c6:	6105                	addi	sp,sp,32
    800031c8:	8082                	ret
    return p->trapframe->a1;
    800031ca:	7d3c                	ld	a5,120(a0)
    800031cc:	7fa8                	ld	a0,120(a5)
    800031ce:	bfcd                	j	800031c0 <argraw+0x30>
    return p->trapframe->a2;
    800031d0:	7d3c                	ld	a5,120(a0)
    800031d2:	63c8                	ld	a0,128(a5)
    800031d4:	b7f5                	j	800031c0 <argraw+0x30>
    return p->trapframe->a3;
    800031d6:	7d3c                	ld	a5,120(a0)
    800031d8:	67c8                	ld	a0,136(a5)
    800031da:	b7dd                	j	800031c0 <argraw+0x30>
    return p->trapframe->a4;
    800031dc:	7d3c                	ld	a5,120(a0)
    800031de:	6bc8                	ld	a0,144(a5)
    800031e0:	b7c5                	j	800031c0 <argraw+0x30>
    return p->trapframe->a5;
    800031e2:	7d3c                	ld	a5,120(a0)
    800031e4:	6fc8                	ld	a0,152(a5)
    800031e6:	bfe9                	j	800031c0 <argraw+0x30>
  panic("argraw");
    800031e8:	00005517          	auipc	a0,0x5
    800031ec:	2b850513          	addi	a0,a0,696 # 800084a0 <states.1787+0x148>
    800031f0:	ffffd097          	auipc	ra,0xffffd
    800031f4:	34e080e7          	jalr	846(ra) # 8000053e <panic>

00000000800031f8 <fetchaddr>:
{
    800031f8:	1101                	addi	sp,sp,-32
    800031fa:	ec06                	sd	ra,24(sp)
    800031fc:	e822                	sd	s0,16(sp)
    800031fe:	e426                	sd	s1,8(sp)
    80003200:	e04a                	sd	s2,0(sp)
    80003202:	1000                	addi	s0,sp,32
    80003204:	84aa                	mv	s1,a0
    80003206:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003208:	fffff097          	auipc	ra,0xfffff
    8000320c:	bec080e7          	jalr	-1044(ra) # 80001df4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003210:	753c                	ld	a5,104(a0)
    80003212:	02f4f863          	bgeu	s1,a5,80003242 <fetchaddr+0x4a>
    80003216:	00848713          	addi	a4,s1,8
    8000321a:	02e7e663          	bltu	a5,a4,80003246 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000321e:	46a1                	li	a3,8
    80003220:	8626                	mv	a2,s1
    80003222:	85ca                	mv	a1,s2
    80003224:	7928                	ld	a0,112(a0)
    80003226:	ffffe097          	auipc	ra,0xffffe
    8000322a:	4fc080e7          	jalr	1276(ra) # 80001722 <copyin>
    8000322e:	00a03533          	snez	a0,a0
    80003232:	40a00533          	neg	a0,a0
}
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	64a2                	ld	s1,8(sp)
    8000323c:	6902                	ld	s2,0(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret
    return -1;
    80003242:	557d                	li	a0,-1
    80003244:	bfcd                	j	80003236 <fetchaddr+0x3e>
    80003246:	557d                	li	a0,-1
    80003248:	b7fd                	j	80003236 <fetchaddr+0x3e>

000000008000324a <fetchstr>:
{
    8000324a:	7179                	addi	sp,sp,-48
    8000324c:	f406                	sd	ra,40(sp)
    8000324e:	f022                	sd	s0,32(sp)
    80003250:	ec26                	sd	s1,24(sp)
    80003252:	e84a                	sd	s2,16(sp)
    80003254:	e44e                	sd	s3,8(sp)
    80003256:	1800                	addi	s0,sp,48
    80003258:	892a                	mv	s2,a0
    8000325a:	84ae                	mv	s1,a1
    8000325c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000325e:	fffff097          	auipc	ra,0xfffff
    80003262:	b96080e7          	jalr	-1130(ra) # 80001df4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003266:	86ce                	mv	a3,s3
    80003268:	864a                	mv	a2,s2
    8000326a:	85a6                	mv	a1,s1
    8000326c:	7928                	ld	a0,112(a0)
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	540080e7          	jalr	1344(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003276:	00054763          	bltz	a0,80003284 <fetchstr+0x3a>
  return strlen(buf);
    8000327a:	8526                	mv	a0,s1
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	c0c080e7          	jalr	-1012(ra) # 80000e88 <strlen>
}
    80003284:	70a2                	ld	ra,40(sp)
    80003286:	7402                	ld	s0,32(sp)
    80003288:	64e2                	ld	s1,24(sp)
    8000328a:	6942                	ld	s2,16(sp)
    8000328c:	69a2                	ld	s3,8(sp)
    8000328e:	6145                	addi	sp,sp,48
    80003290:	8082                	ret

0000000080003292 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003292:	1101                	addi	sp,sp,-32
    80003294:	ec06                	sd	ra,24(sp)
    80003296:	e822                	sd	s0,16(sp)
    80003298:	e426                	sd	s1,8(sp)
    8000329a:	1000                	addi	s0,sp,32
    8000329c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	ef2080e7          	jalr	-270(ra) # 80003190 <argraw>
    800032a6:	c088                	sw	a0,0(s1)
  return 0;
}
    800032a8:	4501                	li	a0,0
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6105                	addi	sp,sp,32
    800032b2:	8082                	ret

00000000800032b4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	e426                	sd	s1,8(sp)
    800032bc:	1000                	addi	s0,sp,32
    800032be:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	ed0080e7          	jalr	-304(ra) # 80003190 <argraw>
    800032c8:	e088                	sd	a0,0(s1)
  return 0;
}
    800032ca:	4501                	li	a0,0
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	64a2                	ld	s1,8(sp)
    800032d2:	6105                	addi	sp,sp,32
    800032d4:	8082                	ret

00000000800032d6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800032d6:	1101                	addi	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	e426                	sd	s1,8(sp)
    800032de:	e04a                	sd	s2,0(sp)
    800032e0:	1000                	addi	s0,sp,32
    800032e2:	84ae                	mv	s1,a1
    800032e4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	eaa080e7          	jalr	-342(ra) # 80003190 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032ee:	864a                	mv	a2,s2
    800032f0:	85a6                	mv	a1,s1
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	f58080e7          	jalr	-168(ra) # 8000324a <fetchstr>
}
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	64a2                	ld	s1,8(sp)
    80003300:	6902                	ld	s2,0(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret

0000000080003306 <syscall>:
[SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    80003306:	1101                	addi	sp,sp,-32
    80003308:	ec06                	sd	ra,24(sp)
    8000330a:	e822                	sd	s0,16(sp)
    8000330c:	e426                	sd	s1,8(sp)
    8000330e:	e04a                	sd	s2,0(sp)
    80003310:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003312:	fffff097          	auipc	ra,0xfffff
    80003316:	ae2080e7          	jalr	-1310(ra) # 80001df4 <myproc>
    8000331a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000331c:	07853903          	ld	s2,120(a0)
    80003320:	0a893783          	ld	a5,168(s2)
    80003324:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003328:	37fd                	addiw	a5,a5,-1
    8000332a:	475d                	li	a4,23
    8000332c:	00f76f63          	bltu	a4,a5,8000334a <syscall+0x44>
    80003330:	00369713          	slli	a4,a3,0x3
    80003334:	00005797          	auipc	a5,0x5
    80003338:	1ac78793          	addi	a5,a5,428 # 800084e0 <syscalls>
    8000333c:	97ba                	add	a5,a5,a4
    8000333e:	639c                	ld	a5,0(a5)
    80003340:	c789                	beqz	a5,8000334a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003342:	9782                	jalr	a5
    80003344:	06a93823          	sd	a0,112(s2)
    80003348:	a839                	j	80003366 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000334a:	17848613          	addi	a2,s1,376
    8000334e:	588c                	lw	a1,48(s1)
    80003350:	00005517          	auipc	a0,0x5
    80003354:	15850513          	addi	a0,a0,344 # 800084a8 <states.1787+0x150>
    80003358:	ffffd097          	auipc	ra,0xffffd
    8000335c:	230080e7          	jalr	560(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003360:	7cbc                	ld	a5,120(s1)
    80003362:	577d                	li	a4,-1
    80003364:	fbb8                	sd	a4,112(a5)
  }
}
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6902                	ld	s2,0(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret

0000000080003372 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000337a:	fec40593          	addi	a1,s0,-20
    8000337e:	4501                	li	a0,0
    80003380:	00000097          	auipc	ra,0x0
    80003384:	f12080e7          	jalr	-238(ra) # 80003292 <argint>
    return -1;
    80003388:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000338a:	00054963          	bltz	a0,8000339c <sys_exit+0x2a>
  exit(n);
    8000338e:	fec42503          	lw	a0,-20(s0)
    80003392:	fffff097          	auipc	ra,0xfffff
    80003396:	66a080e7          	jalr	1642(ra) # 800029fc <exit>
  return 0;  // not reached
    8000339a:	4781                	li	a5,0
}
    8000339c:	853e                	mv	a0,a5
    8000339e:	60e2                	ld	ra,24(sp)
    800033a0:	6442                	ld	s0,16(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret

00000000800033a6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033a6:	1141                	addi	sp,sp,-16
    800033a8:	e406                	sd	ra,8(sp)
    800033aa:	e022                	sd	s0,0(sp)
    800033ac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033ae:	fffff097          	auipc	ra,0xfffff
    800033b2:	a46080e7          	jalr	-1466(ra) # 80001df4 <myproc>
}
    800033b6:	5908                	lw	a0,48(a0)
    800033b8:	60a2                	ld	ra,8(sp)
    800033ba:	6402                	ld	s0,0(sp)
    800033bc:	0141                	addi	sp,sp,16
    800033be:	8082                	ret

00000000800033c0 <sys_fork>:

uint64
sys_fork(void)
{
    800033c0:	1141                	addi	sp,sp,-16
    800033c2:	e406                	sd	ra,8(sp)
    800033c4:	e022                	sd	s0,0(sp)
    800033c6:	0800                	addi	s0,sp,16
  return fork();
    800033c8:	fffff097          	auipc	ra,0xfffff
    800033cc:	ee4080e7          	jalr	-284(ra) # 800022ac <fork>
}
    800033d0:	60a2                	ld	ra,8(sp)
    800033d2:	6402                	ld	s0,0(sp)
    800033d4:	0141                	addi	sp,sp,16
    800033d6:	8082                	ret

00000000800033d8 <sys_wait>:

uint64
sys_wait(void)
{
    800033d8:	1101                	addi	sp,sp,-32
    800033da:	ec06                	sd	ra,24(sp)
    800033dc:	e822                	sd	s0,16(sp)
    800033de:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033e0:	fe840593          	addi	a1,s0,-24
    800033e4:	4501                	li	a0,0
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	ece080e7          	jalr	-306(ra) # 800032b4 <argaddr>
    800033ee:	87aa                	mv	a5,a0
    return -1;
    800033f0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033f2:	0007c863          	bltz	a5,80003402 <sys_wait+0x2a>
  return wait(p);
    800033f6:	fe843503          	ld	a0,-24(s0)
    800033fa:	fffff097          	auipc	ra,0xfffff
    800033fe:	354080e7          	jalr	852(ra) # 8000274e <wait>
}
    80003402:	60e2                	ld	ra,24(sp)
    80003404:	6442                	ld	s0,16(sp)
    80003406:	6105                	addi	sp,sp,32
    80003408:	8082                	ret

000000008000340a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000340a:	7179                	addi	sp,sp,-48
    8000340c:	f406                	sd	ra,40(sp)
    8000340e:	f022                	sd	s0,32(sp)
    80003410:	ec26                	sd	s1,24(sp)
    80003412:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003414:	fdc40593          	addi	a1,s0,-36
    80003418:	4501                	li	a0,0
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e78080e7          	jalr	-392(ra) # 80003292 <argint>
    80003422:	87aa                	mv	a5,a0
    return -1;
    80003424:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003426:	0207c063          	bltz	a5,80003446 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000342a:	fffff097          	auipc	ra,0xfffff
    8000342e:	9ca080e7          	jalr	-1590(ra) # 80001df4 <myproc>
    80003432:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003434:	fdc42503          	lw	a0,-36(s0)
    80003438:	fffff097          	auipc	ra,0xfffff
    8000343c:	e00080e7          	jalr	-512(ra) # 80002238 <growproc>
    80003440:	00054863          	bltz	a0,80003450 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003444:	8526                	mv	a0,s1
}
    80003446:	70a2                	ld	ra,40(sp)
    80003448:	7402                	ld	s0,32(sp)
    8000344a:	64e2                	ld	s1,24(sp)
    8000344c:	6145                	addi	sp,sp,48
    8000344e:	8082                	ret
    return -1;
    80003450:	557d                	li	a0,-1
    80003452:	bfd5                	j	80003446 <sys_sbrk+0x3c>

0000000080003454 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003454:	7139                	addi	sp,sp,-64
    80003456:	fc06                	sd	ra,56(sp)
    80003458:	f822                	sd	s0,48(sp)
    8000345a:	f426                	sd	s1,40(sp)
    8000345c:	f04a                	sd	s2,32(sp)
    8000345e:	ec4e                	sd	s3,24(sp)
    80003460:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003462:	fcc40593          	addi	a1,s0,-52
    80003466:	4501                	li	a0,0
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	e2a080e7          	jalr	-470(ra) # 80003292 <argint>
    return -1;
    80003470:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003472:	06054563          	bltz	a0,800034dc <sys_sleep+0x88>
  acquire(&tickslock);
    80003476:	00014517          	auipc	a0,0x14
    8000347a:	60250513          	addi	a0,a0,1538 # 80017a78 <tickslock>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	766080e7          	jalr	1894(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003486:	00006917          	auipc	s2,0x6
    8000348a:	baa92903          	lw	s2,-1110(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000348e:	fcc42783          	lw	a5,-52(s0)
    80003492:	cf85                	beqz	a5,800034ca <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003494:	00014997          	auipc	s3,0x14
    80003498:	5e498993          	addi	s3,s3,1508 # 80017a78 <tickslock>
    8000349c:	00006497          	auipc	s1,0x6
    800034a0:	b9448493          	addi	s1,s1,-1132 # 80009030 <ticks>
    if(myproc()->killed){
    800034a4:	fffff097          	auipc	ra,0xfffff
    800034a8:	950080e7          	jalr	-1712(ra) # 80001df4 <myproc>
    800034ac:	551c                	lw	a5,40(a0)
    800034ae:	ef9d                	bnez	a5,800034ec <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034b0:	85ce                	mv	a1,s3
    800034b2:	8526                	mv	a0,s1
    800034b4:	fffff097          	auipc	ra,0xfffff
    800034b8:	21a080e7          	jalr	538(ra) # 800026ce <sleep>
  while(ticks - ticks0 < n){
    800034bc:	409c                	lw	a5,0(s1)
    800034be:	412787bb          	subw	a5,a5,s2
    800034c2:	fcc42703          	lw	a4,-52(s0)
    800034c6:	fce7efe3          	bltu	a5,a4,800034a4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034ca:	00014517          	auipc	a0,0x14
    800034ce:	5ae50513          	addi	a0,a0,1454 # 80017a78 <tickslock>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	7d8080e7          	jalr	2008(ra) # 80000caa <release>
  return 0;
    800034da:	4781                	li	a5,0
}
    800034dc:	853e                	mv	a0,a5
    800034de:	70e2                	ld	ra,56(sp)
    800034e0:	7442                	ld	s0,48(sp)
    800034e2:	74a2                	ld	s1,40(sp)
    800034e4:	7902                	ld	s2,32(sp)
    800034e6:	69e2                	ld	s3,24(sp)
    800034e8:	6121                	addi	sp,sp,64
    800034ea:	8082                	ret
      release(&tickslock);
    800034ec:	00014517          	auipc	a0,0x14
    800034f0:	58c50513          	addi	a0,a0,1420 # 80017a78 <tickslock>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	7b6080e7          	jalr	1974(ra) # 80000caa <release>
      return -1;
    800034fc:	57fd                	li	a5,-1
    800034fe:	bff9                	j	800034dc <sys_sleep+0x88>

0000000080003500 <sys_kill>:

uint64
sys_kill(void)
{
    80003500:	1101                	addi	sp,sp,-32
    80003502:	ec06                	sd	ra,24(sp)
    80003504:	e822                	sd	s0,16(sp)
    80003506:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003508:	fec40593          	addi	a1,s0,-20
    8000350c:	4501                	li	a0,0
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	d84080e7          	jalr	-636(ra) # 80003292 <argint>
    80003516:	87aa                	mv	a5,a0
    return -1;
    80003518:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000351a:	0007c863          	bltz	a5,8000352a <sys_kill+0x2a>
  return kill(pid);
    8000351e:	fec42503          	lw	a0,-20(s0)
    80003522:	fffff097          	auipc	ra,0xfffff
    80003526:	5cc080e7          	jalr	1484(ra) # 80002aee <kill>
}
    8000352a:	60e2                	ld	ra,24(sp)
    8000352c:	6442                	ld	s0,16(sp)
    8000352e:	6105                	addi	sp,sp,32
    80003530:	8082                	ret

0000000080003532 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000353c:	00014517          	auipc	a0,0x14
    80003540:	53c50513          	addi	a0,a0,1340 # 80017a78 <tickslock>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	6a0080e7          	jalr	1696(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000354c:	00006497          	auipc	s1,0x6
    80003550:	ae44a483          	lw	s1,-1308(s1) # 80009030 <ticks>
  release(&tickslock);
    80003554:	00014517          	auipc	a0,0x14
    80003558:	52450513          	addi	a0,a0,1316 # 80017a78 <tickslock>
    8000355c:	ffffd097          	auipc	ra,0xffffd
    80003560:	74e080e7          	jalr	1870(ra) # 80000caa <release>
  return xticks;
}
    80003564:	02049513          	slli	a0,s1,0x20
    80003568:	9101                	srli	a0,a0,0x20
    8000356a:	60e2                	ld	ra,24(sp)
    8000356c:	6442                	ld	s0,16(sp)
    8000356e:	64a2                	ld	s1,8(sp)
    80003570:	6105                	addi	sp,sp,32
    80003572:	8082                	ret

0000000080003574 <sys_get_cpu>:

uint64
sys_get_cpu(void){
    80003574:	1141                	addi	sp,sp,-16
    80003576:	e406                	sd	ra,8(sp)
    80003578:	e022                	sd	s0,0(sp)
    8000357a:	0800                	addi	s0,sp,16
  return get_cpu();
    8000357c:	fffff097          	auipc	ra,0xfffff
    80003580:	7d2080e7          	jalr	2002(ra) # 80002d4e <get_cpu>
}
    80003584:	60a2                	ld	ra,8(sp)
    80003586:	6402                	ld	s0,0(sp)
    80003588:	0141                	addi	sp,sp,16
    8000358a:	8082                	ret

000000008000358c <sys_set_cpu>:

uint64
sys_set_cpu(void){
    8000358c:	1101                	addi	sp,sp,-32
    8000358e:	ec06                	sd	ra,24(sp)
    80003590:	e822                	sd	s0,16(sp)
    80003592:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80003594:	fec40593          	addi	a1,s0,-20
    80003598:	4501                	li	a0,0
    8000359a:	00000097          	auipc	ra,0x0
    8000359e:	cf8080e7          	jalr	-776(ra) # 80003292 <argint>
    800035a2:	87aa                	mv	a5,a0
    return -1;
    800035a4:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800035a6:	0007c863          	bltz	a5,800035b6 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    800035aa:	fec42503          	lw	a0,-20(s0)
    800035ae:	fffff097          	auipc	ra,0xfffff
    800035b2:	762080e7          	jalr	1890(ra) # 80002d10 <set_cpu>
}
    800035b6:	60e2                	ld	ra,24(sp)
    800035b8:	6442                	ld	s0,16(sp)
    800035ba:	6105                	addi	sp,sp,32
    800035bc:	8082                	ret

00000000800035be <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    800035c6:	fec40593          	addi	a1,s0,-20
    800035ca:	4501                	li	a0,0
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	cc6080e7          	jalr	-826(ra) # 80003292 <argint>
    800035d4:	87aa                	mv	a5,a0
    return -1;
    800035d6:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800035d8:	0007c863          	bltz	a5,800035e8 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_num);
    800035dc:	fec42503          	lw	a0,-20(s0)
    800035e0:	fffff097          	auipc	ra,0xfffff
    800035e4:	79e080e7          	jalr	1950(ra) # 80002d7e <cpu_process_count>
}
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	6105                	addi	sp,sp,32
    800035ee:	8082                	ret

00000000800035f0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035f0:	7179                	addi	sp,sp,-48
    800035f2:	f406                	sd	ra,40(sp)
    800035f4:	f022                	sd	s0,32(sp)
    800035f6:	ec26                	sd	s1,24(sp)
    800035f8:	e84a                	sd	s2,16(sp)
    800035fa:	e44e                	sd	s3,8(sp)
    800035fc:	e052                	sd	s4,0(sp)
    800035fe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003600:	00005597          	auipc	a1,0x5
    80003604:	fa858593          	addi	a1,a1,-88 # 800085a8 <syscalls+0xc8>
    80003608:	00014517          	auipc	a0,0x14
    8000360c:	48850513          	addi	a0,a0,1160 # 80017a90 <bcache>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	544080e7          	jalr	1348(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003618:	0001c797          	auipc	a5,0x1c
    8000361c:	47878793          	addi	a5,a5,1144 # 8001fa90 <bcache+0x8000>
    80003620:	0001c717          	auipc	a4,0x1c
    80003624:	6d870713          	addi	a4,a4,1752 # 8001fcf8 <bcache+0x8268>
    80003628:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000362c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003630:	00014497          	auipc	s1,0x14
    80003634:	47848493          	addi	s1,s1,1144 # 80017aa8 <bcache+0x18>
    b->next = bcache.head.next;
    80003638:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000363a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000363c:	00005a17          	auipc	s4,0x5
    80003640:	f74a0a13          	addi	s4,s4,-140 # 800085b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003644:	2b893783          	ld	a5,696(s2)
    80003648:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000364a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000364e:	85d2                	mv	a1,s4
    80003650:	01048513          	addi	a0,s1,16
    80003654:	00001097          	auipc	ra,0x1
    80003658:	4bc080e7          	jalr	1212(ra) # 80004b10 <initsleeplock>
    bcache.head.next->prev = b;
    8000365c:	2b893783          	ld	a5,696(s2)
    80003660:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003662:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003666:	45848493          	addi	s1,s1,1112
    8000366a:	fd349de3          	bne	s1,s3,80003644 <binit+0x54>
  }
}
    8000366e:	70a2                	ld	ra,40(sp)
    80003670:	7402                	ld	s0,32(sp)
    80003672:	64e2                	ld	s1,24(sp)
    80003674:	6942                	ld	s2,16(sp)
    80003676:	69a2                	ld	s3,8(sp)
    80003678:	6a02                	ld	s4,0(sp)
    8000367a:	6145                	addi	sp,sp,48
    8000367c:	8082                	ret

000000008000367e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000367e:	7179                	addi	sp,sp,-48
    80003680:	f406                	sd	ra,40(sp)
    80003682:	f022                	sd	s0,32(sp)
    80003684:	ec26                	sd	s1,24(sp)
    80003686:	e84a                	sd	s2,16(sp)
    80003688:	e44e                	sd	s3,8(sp)
    8000368a:	1800                	addi	s0,sp,48
    8000368c:	89aa                	mv	s3,a0
    8000368e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003690:	00014517          	auipc	a0,0x14
    80003694:	40050513          	addi	a0,a0,1024 # 80017a90 <bcache>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	54c080e7          	jalr	1356(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036a0:	0001c497          	auipc	s1,0x1c
    800036a4:	6a84b483          	ld	s1,1704(s1) # 8001fd48 <bcache+0x82b8>
    800036a8:	0001c797          	auipc	a5,0x1c
    800036ac:	65078793          	addi	a5,a5,1616 # 8001fcf8 <bcache+0x8268>
    800036b0:	02f48f63          	beq	s1,a5,800036ee <bread+0x70>
    800036b4:	873e                	mv	a4,a5
    800036b6:	a021                	j	800036be <bread+0x40>
    800036b8:	68a4                	ld	s1,80(s1)
    800036ba:	02e48a63          	beq	s1,a4,800036ee <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036be:	449c                	lw	a5,8(s1)
    800036c0:	ff379ce3          	bne	a5,s3,800036b8 <bread+0x3a>
    800036c4:	44dc                	lw	a5,12(s1)
    800036c6:	ff2799e3          	bne	a5,s2,800036b8 <bread+0x3a>
      b->refcnt++;
    800036ca:	40bc                	lw	a5,64(s1)
    800036cc:	2785                	addiw	a5,a5,1
    800036ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036d0:	00014517          	auipc	a0,0x14
    800036d4:	3c050513          	addi	a0,a0,960 # 80017a90 <bcache>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	5d2080e7          	jalr	1490(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    800036e0:	01048513          	addi	a0,s1,16
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	466080e7          	jalr	1126(ra) # 80004b4a <acquiresleep>
      return b;
    800036ec:	a8b9                	j	8000374a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036ee:	0001c497          	auipc	s1,0x1c
    800036f2:	6524b483          	ld	s1,1618(s1) # 8001fd40 <bcache+0x82b0>
    800036f6:	0001c797          	auipc	a5,0x1c
    800036fa:	60278793          	addi	a5,a5,1538 # 8001fcf8 <bcache+0x8268>
    800036fe:	00f48863          	beq	s1,a5,8000370e <bread+0x90>
    80003702:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003704:	40bc                	lw	a5,64(s1)
    80003706:	cf81                	beqz	a5,8000371e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003708:	64a4                	ld	s1,72(s1)
    8000370a:	fee49de3          	bne	s1,a4,80003704 <bread+0x86>
  panic("bget: no buffers");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	eaa50513          	addi	a0,a0,-342 # 800085b8 <syscalls+0xd8>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>
      b->dev = dev;
    8000371e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003722:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003726:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000372a:	4785                	li	a5,1
    8000372c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000372e:	00014517          	auipc	a0,0x14
    80003732:	36250513          	addi	a0,a0,866 # 80017a90 <bcache>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	574080e7          	jalr	1396(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000373e:	01048513          	addi	a0,s1,16
    80003742:	00001097          	auipc	ra,0x1
    80003746:	408080e7          	jalr	1032(ra) # 80004b4a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000374a:	409c                	lw	a5,0(s1)
    8000374c:	cb89                	beqz	a5,8000375e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000374e:	8526                	mv	a0,s1
    80003750:	70a2                	ld	ra,40(sp)
    80003752:	7402                	ld	s0,32(sp)
    80003754:	64e2                	ld	s1,24(sp)
    80003756:	6942                	ld	s2,16(sp)
    80003758:	69a2                	ld	s3,8(sp)
    8000375a:	6145                	addi	sp,sp,48
    8000375c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000375e:	4581                	li	a1,0
    80003760:	8526                	mv	a0,s1
    80003762:	00003097          	auipc	ra,0x3
    80003766:	f14080e7          	jalr	-236(ra) # 80006676 <virtio_disk_rw>
    b->valid = 1;
    8000376a:	4785                	li	a5,1
    8000376c:	c09c                	sw	a5,0(s1)
  return b;
    8000376e:	b7c5                	j	8000374e <bread+0xd0>

0000000080003770 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003770:	1101                	addi	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	e426                	sd	s1,8(sp)
    80003778:	1000                	addi	s0,sp,32
    8000377a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000377c:	0541                	addi	a0,a0,16
    8000377e:	00001097          	auipc	ra,0x1
    80003782:	466080e7          	jalr	1126(ra) # 80004be4 <holdingsleep>
    80003786:	cd01                	beqz	a0,8000379e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003788:	4585                	li	a1,1
    8000378a:	8526                	mv	a0,s1
    8000378c:	00003097          	auipc	ra,0x3
    80003790:	eea080e7          	jalr	-278(ra) # 80006676 <virtio_disk_rw>
}
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	64a2                	ld	s1,8(sp)
    8000379a:	6105                	addi	sp,sp,32
    8000379c:	8082                	ret
    panic("bwrite");
    8000379e:	00005517          	auipc	a0,0x5
    800037a2:	e3250513          	addi	a0,a0,-462 # 800085d0 <syscalls+0xf0>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	d98080e7          	jalr	-616(ra) # 8000053e <panic>

00000000800037ae <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	e04a                	sd	s2,0(sp)
    800037b8:	1000                	addi	s0,sp,32
    800037ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037bc:	01050913          	addi	s2,a0,16
    800037c0:	854a                	mv	a0,s2
    800037c2:	00001097          	auipc	ra,0x1
    800037c6:	422080e7          	jalr	1058(ra) # 80004be4 <holdingsleep>
    800037ca:	c92d                	beqz	a0,8000383c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	3d2080e7          	jalr	978(ra) # 80004ba0 <releasesleep>

  acquire(&bcache.lock);
    800037d6:	00014517          	auipc	a0,0x14
    800037da:	2ba50513          	addi	a0,a0,698 # 80017a90 <bcache>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	406080e7          	jalr	1030(ra) # 80000be4 <acquire>
  b->refcnt--;
    800037e6:	40bc                	lw	a5,64(s1)
    800037e8:	37fd                	addiw	a5,a5,-1
    800037ea:	0007871b          	sext.w	a4,a5
    800037ee:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037f0:	eb05                	bnez	a4,80003820 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037f2:	68bc                	ld	a5,80(s1)
    800037f4:	64b8                	ld	a4,72(s1)
    800037f6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037f8:	64bc                	ld	a5,72(s1)
    800037fa:	68b8                	ld	a4,80(s1)
    800037fc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037fe:	0001c797          	auipc	a5,0x1c
    80003802:	29278793          	addi	a5,a5,658 # 8001fa90 <bcache+0x8000>
    80003806:	2b87b703          	ld	a4,696(a5)
    8000380a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000380c:	0001c717          	auipc	a4,0x1c
    80003810:	4ec70713          	addi	a4,a4,1260 # 8001fcf8 <bcache+0x8268>
    80003814:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003816:	2b87b703          	ld	a4,696(a5)
    8000381a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000381c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003820:	00014517          	auipc	a0,0x14
    80003824:	27050513          	addi	a0,a0,624 # 80017a90 <bcache>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	482080e7          	jalr	1154(ra) # 80000caa <release>
}
    80003830:	60e2                	ld	ra,24(sp)
    80003832:	6442                	ld	s0,16(sp)
    80003834:	64a2                	ld	s1,8(sp)
    80003836:	6902                	ld	s2,0(sp)
    80003838:	6105                	addi	sp,sp,32
    8000383a:	8082                	ret
    panic("brelse");
    8000383c:	00005517          	auipc	a0,0x5
    80003840:	d9c50513          	addi	a0,a0,-612 # 800085d8 <syscalls+0xf8>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	cfa080e7          	jalr	-774(ra) # 8000053e <panic>

000000008000384c <bpin>:

void
bpin(struct buf *b) {
    8000384c:	1101                	addi	sp,sp,-32
    8000384e:	ec06                	sd	ra,24(sp)
    80003850:	e822                	sd	s0,16(sp)
    80003852:	e426                	sd	s1,8(sp)
    80003854:	1000                	addi	s0,sp,32
    80003856:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003858:	00014517          	auipc	a0,0x14
    8000385c:	23850513          	addi	a0,a0,568 # 80017a90 <bcache>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	384080e7          	jalr	900(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003868:	40bc                	lw	a5,64(s1)
    8000386a:	2785                	addiw	a5,a5,1
    8000386c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000386e:	00014517          	auipc	a0,0x14
    80003872:	22250513          	addi	a0,a0,546 # 80017a90 <bcache>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	434080e7          	jalr	1076(ra) # 80000caa <release>
}
    8000387e:	60e2                	ld	ra,24(sp)
    80003880:	6442                	ld	s0,16(sp)
    80003882:	64a2                	ld	s1,8(sp)
    80003884:	6105                	addi	sp,sp,32
    80003886:	8082                	ret

0000000080003888 <bunpin>:

void
bunpin(struct buf *b) {
    80003888:	1101                	addi	sp,sp,-32
    8000388a:	ec06                	sd	ra,24(sp)
    8000388c:	e822                	sd	s0,16(sp)
    8000388e:	e426                	sd	s1,8(sp)
    80003890:	1000                	addi	s0,sp,32
    80003892:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003894:	00014517          	auipc	a0,0x14
    80003898:	1fc50513          	addi	a0,a0,508 # 80017a90 <bcache>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	348080e7          	jalr	840(ra) # 80000be4 <acquire>
  b->refcnt--;
    800038a4:	40bc                	lw	a5,64(s1)
    800038a6:	37fd                	addiw	a5,a5,-1
    800038a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038aa:	00014517          	auipc	a0,0x14
    800038ae:	1e650513          	addi	a0,a0,486 # 80017a90 <bcache>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	3f8080e7          	jalr	1016(ra) # 80000caa <release>
}
    800038ba:	60e2                	ld	ra,24(sp)
    800038bc:	6442                	ld	s0,16(sp)
    800038be:	64a2                	ld	s1,8(sp)
    800038c0:	6105                	addi	sp,sp,32
    800038c2:	8082                	ret

00000000800038c4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	e04a                	sd	s2,0(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800038d2:	00d5d59b          	srliw	a1,a1,0xd
    800038d6:	0001d797          	auipc	a5,0x1d
    800038da:	8967a783          	lw	a5,-1898(a5) # 8002016c <sb+0x1c>
    800038de:	9dbd                	addw	a1,a1,a5
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	d9e080e7          	jalr	-610(ra) # 8000367e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038e8:	0074f713          	andi	a4,s1,7
    800038ec:	4785                	li	a5,1
    800038ee:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038f2:	14ce                	slli	s1,s1,0x33
    800038f4:	90d9                	srli	s1,s1,0x36
    800038f6:	00950733          	add	a4,a0,s1
    800038fa:	05874703          	lbu	a4,88(a4)
    800038fe:	00e7f6b3          	and	a3,a5,a4
    80003902:	c69d                	beqz	a3,80003930 <bfree+0x6c>
    80003904:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003906:	94aa                	add	s1,s1,a0
    80003908:	fff7c793          	not	a5,a5
    8000390c:	8ff9                	and	a5,a5,a4
    8000390e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003912:	00001097          	auipc	ra,0x1
    80003916:	118080e7          	jalr	280(ra) # 80004a2a <log_write>
  brelse(bp);
    8000391a:	854a                	mv	a0,s2
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	e92080e7          	jalr	-366(ra) # 800037ae <brelse>
}
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	64a2                	ld	s1,8(sp)
    8000392a:	6902                	ld	s2,0(sp)
    8000392c:	6105                	addi	sp,sp,32
    8000392e:	8082                	ret
    panic("freeing free block");
    80003930:	00005517          	auipc	a0,0x5
    80003934:	cb050513          	addi	a0,a0,-848 # 800085e0 <syscalls+0x100>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	c06080e7          	jalr	-1018(ra) # 8000053e <panic>

0000000080003940 <balloc>:
{
    80003940:	711d                	addi	sp,sp,-96
    80003942:	ec86                	sd	ra,88(sp)
    80003944:	e8a2                	sd	s0,80(sp)
    80003946:	e4a6                	sd	s1,72(sp)
    80003948:	e0ca                	sd	s2,64(sp)
    8000394a:	fc4e                	sd	s3,56(sp)
    8000394c:	f852                	sd	s4,48(sp)
    8000394e:	f456                	sd	s5,40(sp)
    80003950:	f05a                	sd	s6,32(sp)
    80003952:	ec5e                	sd	s7,24(sp)
    80003954:	e862                	sd	s8,16(sp)
    80003956:	e466                	sd	s9,8(sp)
    80003958:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000395a:	0001c797          	auipc	a5,0x1c
    8000395e:	7fa7a783          	lw	a5,2042(a5) # 80020154 <sb+0x4>
    80003962:	cbd1                	beqz	a5,800039f6 <balloc+0xb6>
    80003964:	8baa                	mv	s7,a0
    80003966:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003968:	0001cb17          	auipc	s6,0x1c
    8000396c:	7e8b0b13          	addi	s6,s6,2024 # 80020150 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003970:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003972:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003974:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003976:	6c89                	lui	s9,0x2
    80003978:	a831                	j	80003994 <balloc+0x54>
    brelse(bp);
    8000397a:	854a                	mv	a0,s2
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	e32080e7          	jalr	-462(ra) # 800037ae <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003984:	015c87bb          	addw	a5,s9,s5
    80003988:	00078a9b          	sext.w	s5,a5
    8000398c:	004b2703          	lw	a4,4(s6)
    80003990:	06eaf363          	bgeu	s5,a4,800039f6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003994:	41fad79b          	sraiw	a5,s5,0x1f
    80003998:	0137d79b          	srliw	a5,a5,0x13
    8000399c:	015787bb          	addw	a5,a5,s5
    800039a0:	40d7d79b          	sraiw	a5,a5,0xd
    800039a4:	01cb2583          	lw	a1,28(s6)
    800039a8:	9dbd                	addw	a1,a1,a5
    800039aa:	855e                	mv	a0,s7
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	cd2080e7          	jalr	-814(ra) # 8000367e <bread>
    800039b4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b6:	004b2503          	lw	a0,4(s6)
    800039ba:	000a849b          	sext.w	s1,s5
    800039be:	8662                	mv	a2,s8
    800039c0:	faa4fde3          	bgeu	s1,a0,8000397a <balloc+0x3a>
      m = 1 << (bi % 8);
    800039c4:	41f6579b          	sraiw	a5,a2,0x1f
    800039c8:	01d7d69b          	srliw	a3,a5,0x1d
    800039cc:	00c6873b          	addw	a4,a3,a2
    800039d0:	00777793          	andi	a5,a4,7
    800039d4:	9f95                	subw	a5,a5,a3
    800039d6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039da:	4037571b          	sraiw	a4,a4,0x3
    800039de:	00e906b3          	add	a3,s2,a4
    800039e2:	0586c683          	lbu	a3,88(a3)
    800039e6:	00d7f5b3          	and	a1,a5,a3
    800039ea:	cd91                	beqz	a1,80003a06 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ec:	2605                	addiw	a2,a2,1
    800039ee:	2485                	addiw	s1,s1,1
    800039f0:	fd4618e3          	bne	a2,s4,800039c0 <balloc+0x80>
    800039f4:	b759                	j	8000397a <balloc+0x3a>
  panic("balloc: out of blocks");
    800039f6:	00005517          	auipc	a0,0x5
    800039fa:	c0250513          	addi	a0,a0,-1022 # 800085f8 <syscalls+0x118>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a06:	974a                	add	a4,a4,s2
    80003a08:	8fd5                	or	a5,a5,a3
    80003a0a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00001097          	auipc	ra,0x1
    80003a14:	01a080e7          	jalr	26(ra) # 80004a2a <log_write>
        brelse(bp);
    80003a18:	854a                	mv	a0,s2
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	d94080e7          	jalr	-620(ra) # 800037ae <brelse>
  bp = bread(dev, bno);
    80003a22:	85a6                	mv	a1,s1
    80003a24:	855e                	mv	a0,s7
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	c58080e7          	jalr	-936(ra) # 8000367e <bread>
    80003a2e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a30:	40000613          	li	a2,1024
    80003a34:	4581                	li	a1,0
    80003a36:	05850513          	addi	a0,a0,88
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	2ca080e7          	jalr	714(ra) # 80000d04 <memset>
  log_write(bp);
    80003a42:	854a                	mv	a0,s2
    80003a44:	00001097          	auipc	ra,0x1
    80003a48:	fe6080e7          	jalr	-26(ra) # 80004a2a <log_write>
  brelse(bp);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	d60080e7          	jalr	-672(ra) # 800037ae <brelse>
}
    80003a56:	8526                	mv	a0,s1
    80003a58:	60e6                	ld	ra,88(sp)
    80003a5a:	6446                	ld	s0,80(sp)
    80003a5c:	64a6                	ld	s1,72(sp)
    80003a5e:	6906                	ld	s2,64(sp)
    80003a60:	79e2                	ld	s3,56(sp)
    80003a62:	7a42                	ld	s4,48(sp)
    80003a64:	7aa2                	ld	s5,40(sp)
    80003a66:	7b02                	ld	s6,32(sp)
    80003a68:	6be2                	ld	s7,24(sp)
    80003a6a:	6c42                	ld	s8,16(sp)
    80003a6c:	6ca2                	ld	s9,8(sp)
    80003a6e:	6125                	addi	sp,sp,96
    80003a70:	8082                	ret

0000000080003a72 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a72:	7179                	addi	sp,sp,-48
    80003a74:	f406                	sd	ra,40(sp)
    80003a76:	f022                	sd	s0,32(sp)
    80003a78:	ec26                	sd	s1,24(sp)
    80003a7a:	e84a                	sd	s2,16(sp)
    80003a7c:	e44e                	sd	s3,8(sp)
    80003a7e:	e052                	sd	s4,0(sp)
    80003a80:	1800                	addi	s0,sp,48
    80003a82:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a84:	47ad                	li	a5,11
    80003a86:	04b7fe63          	bgeu	a5,a1,80003ae2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a8a:	ff45849b          	addiw	s1,a1,-12
    80003a8e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a92:	0ff00793          	li	a5,255
    80003a96:	0ae7e363          	bltu	a5,a4,80003b3c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a9a:	08052583          	lw	a1,128(a0)
    80003a9e:	c5ad                	beqz	a1,80003b08 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003aa0:	00092503          	lw	a0,0(s2)
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	bda080e7          	jalr	-1062(ra) # 8000367e <bread>
    80003aac:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003aae:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ab2:	02049593          	slli	a1,s1,0x20
    80003ab6:	9181                	srli	a1,a1,0x20
    80003ab8:	058a                	slli	a1,a1,0x2
    80003aba:	00b784b3          	add	s1,a5,a1
    80003abe:	0004a983          	lw	s3,0(s1)
    80003ac2:	04098d63          	beqz	s3,80003b1c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003ac6:	8552                	mv	a0,s4
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	ce6080e7          	jalr	-794(ra) # 800037ae <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ad0:	854e                	mv	a0,s3
    80003ad2:	70a2                	ld	ra,40(sp)
    80003ad4:	7402                	ld	s0,32(sp)
    80003ad6:	64e2                	ld	s1,24(sp)
    80003ad8:	6942                	ld	s2,16(sp)
    80003ada:	69a2                	ld	s3,8(sp)
    80003adc:	6a02                	ld	s4,0(sp)
    80003ade:	6145                	addi	sp,sp,48
    80003ae0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003ae2:	02059493          	slli	s1,a1,0x20
    80003ae6:	9081                	srli	s1,s1,0x20
    80003ae8:	048a                	slli	s1,s1,0x2
    80003aea:	94aa                	add	s1,s1,a0
    80003aec:	0504a983          	lw	s3,80(s1)
    80003af0:	fe0990e3          	bnez	s3,80003ad0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003af4:	4108                	lw	a0,0(a0)
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	e4a080e7          	jalr	-438(ra) # 80003940 <balloc>
    80003afe:	0005099b          	sext.w	s3,a0
    80003b02:	0534a823          	sw	s3,80(s1)
    80003b06:	b7e9                	j	80003ad0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b08:	4108                	lw	a0,0(a0)
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	e36080e7          	jalr	-458(ra) # 80003940 <balloc>
    80003b12:	0005059b          	sext.w	a1,a0
    80003b16:	08b92023          	sw	a1,128(s2)
    80003b1a:	b759                	j	80003aa0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b1c:	00092503          	lw	a0,0(s2)
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	e20080e7          	jalr	-480(ra) # 80003940 <balloc>
    80003b28:	0005099b          	sext.w	s3,a0
    80003b2c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b30:	8552                	mv	a0,s4
    80003b32:	00001097          	auipc	ra,0x1
    80003b36:	ef8080e7          	jalr	-264(ra) # 80004a2a <log_write>
    80003b3a:	b771                	j	80003ac6 <bmap+0x54>
  panic("bmap: out of range");
    80003b3c:	00005517          	auipc	a0,0x5
    80003b40:	ad450513          	addi	a0,a0,-1324 # 80008610 <syscalls+0x130>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>

0000000080003b4c <iget>:
{
    80003b4c:	7179                	addi	sp,sp,-48
    80003b4e:	f406                	sd	ra,40(sp)
    80003b50:	f022                	sd	s0,32(sp)
    80003b52:	ec26                	sd	s1,24(sp)
    80003b54:	e84a                	sd	s2,16(sp)
    80003b56:	e44e                	sd	s3,8(sp)
    80003b58:	e052                	sd	s4,0(sp)
    80003b5a:	1800                	addi	s0,sp,48
    80003b5c:	89aa                	mv	s3,a0
    80003b5e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b60:	0001c517          	auipc	a0,0x1c
    80003b64:	61050513          	addi	a0,a0,1552 # 80020170 <itable>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	07c080e7          	jalr	124(ra) # 80000be4 <acquire>
  empty = 0;
    80003b70:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b72:	0001c497          	auipc	s1,0x1c
    80003b76:	61648493          	addi	s1,s1,1558 # 80020188 <itable+0x18>
    80003b7a:	0001e697          	auipc	a3,0x1e
    80003b7e:	09e68693          	addi	a3,a3,158 # 80021c18 <log>
    80003b82:	a039                	j	80003b90 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b84:	02090b63          	beqz	s2,80003bba <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b88:	08848493          	addi	s1,s1,136
    80003b8c:	02d48a63          	beq	s1,a3,80003bc0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b90:	449c                	lw	a5,8(s1)
    80003b92:	fef059e3          	blez	a5,80003b84 <iget+0x38>
    80003b96:	4098                	lw	a4,0(s1)
    80003b98:	ff3716e3          	bne	a4,s3,80003b84 <iget+0x38>
    80003b9c:	40d8                	lw	a4,4(s1)
    80003b9e:	ff4713e3          	bne	a4,s4,80003b84 <iget+0x38>
      ip->ref++;
    80003ba2:	2785                	addiw	a5,a5,1
    80003ba4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ba6:	0001c517          	auipc	a0,0x1c
    80003baa:	5ca50513          	addi	a0,a0,1482 # 80020170 <itable>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	0fc080e7          	jalr	252(ra) # 80000caa <release>
      return ip;
    80003bb6:	8926                	mv	s2,s1
    80003bb8:	a03d                	j	80003be6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bba:	f7f9                	bnez	a5,80003b88 <iget+0x3c>
    80003bbc:	8926                	mv	s2,s1
    80003bbe:	b7e9                	j	80003b88 <iget+0x3c>
  if(empty == 0)
    80003bc0:	02090c63          	beqz	s2,80003bf8 <iget+0xac>
  ip->dev = dev;
    80003bc4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003bc8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003bcc:	4785                	li	a5,1
    80003bce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003bd2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003bd6:	0001c517          	auipc	a0,0x1c
    80003bda:	59a50513          	addi	a0,a0,1434 # 80020170 <itable>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	0cc080e7          	jalr	204(ra) # 80000caa <release>
}
    80003be6:	854a                	mv	a0,s2
    80003be8:	70a2                	ld	ra,40(sp)
    80003bea:	7402                	ld	s0,32(sp)
    80003bec:	64e2                	ld	s1,24(sp)
    80003bee:	6942                	ld	s2,16(sp)
    80003bf0:	69a2                	ld	s3,8(sp)
    80003bf2:	6a02                	ld	s4,0(sp)
    80003bf4:	6145                	addi	sp,sp,48
    80003bf6:	8082                	ret
    panic("iget: no inodes");
    80003bf8:	00005517          	auipc	a0,0x5
    80003bfc:	a3050513          	addi	a0,a0,-1488 # 80008628 <syscalls+0x148>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	93e080e7          	jalr	-1730(ra) # 8000053e <panic>

0000000080003c08 <fsinit>:
fsinit(int dev) {
    80003c08:	7179                	addi	sp,sp,-48
    80003c0a:	f406                	sd	ra,40(sp)
    80003c0c:	f022                	sd	s0,32(sp)
    80003c0e:	ec26                	sd	s1,24(sp)
    80003c10:	e84a                	sd	s2,16(sp)
    80003c12:	e44e                	sd	s3,8(sp)
    80003c14:	1800                	addi	s0,sp,48
    80003c16:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c18:	4585                	li	a1,1
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	a64080e7          	jalr	-1436(ra) # 8000367e <bread>
    80003c22:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c24:	0001c997          	auipc	s3,0x1c
    80003c28:	52c98993          	addi	s3,s3,1324 # 80020150 <sb>
    80003c2c:	02000613          	li	a2,32
    80003c30:	05850593          	addi	a1,a0,88
    80003c34:	854e                	mv	a0,s3
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	12e080e7          	jalr	302(ra) # 80000d64 <memmove>
  brelse(bp);
    80003c3e:	8526                	mv	a0,s1
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	b6e080e7          	jalr	-1170(ra) # 800037ae <brelse>
  if(sb.magic != FSMAGIC)
    80003c48:	0009a703          	lw	a4,0(s3)
    80003c4c:	102037b7          	lui	a5,0x10203
    80003c50:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c54:	02f71263          	bne	a4,a5,80003c78 <fsinit+0x70>
  initlog(dev, &sb);
    80003c58:	0001c597          	auipc	a1,0x1c
    80003c5c:	4f858593          	addi	a1,a1,1272 # 80020150 <sb>
    80003c60:	854a                	mv	a0,s2
    80003c62:	00001097          	auipc	ra,0x1
    80003c66:	b4c080e7          	jalr	-1204(ra) # 800047ae <initlog>
}
    80003c6a:	70a2                	ld	ra,40(sp)
    80003c6c:	7402                	ld	s0,32(sp)
    80003c6e:	64e2                	ld	s1,24(sp)
    80003c70:	6942                	ld	s2,16(sp)
    80003c72:	69a2                	ld	s3,8(sp)
    80003c74:	6145                	addi	sp,sp,48
    80003c76:	8082                	ret
    panic("invalid file system");
    80003c78:	00005517          	auipc	a0,0x5
    80003c7c:	9c050513          	addi	a0,a0,-1600 # 80008638 <syscalls+0x158>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>

0000000080003c88 <iinit>:
{
    80003c88:	7179                	addi	sp,sp,-48
    80003c8a:	f406                	sd	ra,40(sp)
    80003c8c:	f022                	sd	s0,32(sp)
    80003c8e:	ec26                	sd	s1,24(sp)
    80003c90:	e84a                	sd	s2,16(sp)
    80003c92:	e44e                	sd	s3,8(sp)
    80003c94:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c96:	00005597          	auipc	a1,0x5
    80003c9a:	9ba58593          	addi	a1,a1,-1606 # 80008650 <syscalls+0x170>
    80003c9e:	0001c517          	auipc	a0,0x1c
    80003ca2:	4d250513          	addi	a0,a0,1234 # 80020170 <itable>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	eae080e7          	jalr	-338(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003cae:	0001c497          	auipc	s1,0x1c
    80003cb2:	4ea48493          	addi	s1,s1,1258 # 80020198 <itable+0x28>
    80003cb6:	0001e997          	auipc	s3,0x1e
    80003cba:	f7298993          	addi	s3,s3,-142 # 80021c28 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003cbe:	00005917          	auipc	s2,0x5
    80003cc2:	99a90913          	addi	s2,s2,-1638 # 80008658 <syscalls+0x178>
    80003cc6:	85ca                	mv	a1,s2
    80003cc8:	8526                	mv	a0,s1
    80003cca:	00001097          	auipc	ra,0x1
    80003cce:	e46080e7          	jalr	-442(ra) # 80004b10 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003cd2:	08848493          	addi	s1,s1,136
    80003cd6:	ff3498e3          	bne	s1,s3,80003cc6 <iinit+0x3e>
}
    80003cda:	70a2                	ld	ra,40(sp)
    80003cdc:	7402                	ld	s0,32(sp)
    80003cde:	64e2                	ld	s1,24(sp)
    80003ce0:	6942                	ld	s2,16(sp)
    80003ce2:	69a2                	ld	s3,8(sp)
    80003ce4:	6145                	addi	sp,sp,48
    80003ce6:	8082                	ret

0000000080003ce8 <ialloc>:
{
    80003ce8:	715d                	addi	sp,sp,-80
    80003cea:	e486                	sd	ra,72(sp)
    80003cec:	e0a2                	sd	s0,64(sp)
    80003cee:	fc26                	sd	s1,56(sp)
    80003cf0:	f84a                	sd	s2,48(sp)
    80003cf2:	f44e                	sd	s3,40(sp)
    80003cf4:	f052                	sd	s4,32(sp)
    80003cf6:	ec56                	sd	s5,24(sp)
    80003cf8:	e85a                	sd	s6,16(sp)
    80003cfa:	e45e                	sd	s7,8(sp)
    80003cfc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cfe:	0001c717          	auipc	a4,0x1c
    80003d02:	45e72703          	lw	a4,1118(a4) # 8002015c <sb+0xc>
    80003d06:	4785                	li	a5,1
    80003d08:	04e7fa63          	bgeu	a5,a4,80003d5c <ialloc+0x74>
    80003d0c:	8aaa                	mv	s5,a0
    80003d0e:	8bae                	mv	s7,a1
    80003d10:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d12:	0001ca17          	auipc	s4,0x1c
    80003d16:	43ea0a13          	addi	s4,s4,1086 # 80020150 <sb>
    80003d1a:	00048b1b          	sext.w	s6,s1
    80003d1e:	0044d593          	srli	a1,s1,0x4
    80003d22:	018a2783          	lw	a5,24(s4)
    80003d26:	9dbd                	addw	a1,a1,a5
    80003d28:	8556                	mv	a0,s5
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	954080e7          	jalr	-1708(ra) # 8000367e <bread>
    80003d32:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d34:	05850993          	addi	s3,a0,88
    80003d38:	00f4f793          	andi	a5,s1,15
    80003d3c:	079a                	slli	a5,a5,0x6
    80003d3e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d40:	00099783          	lh	a5,0(s3)
    80003d44:	c785                	beqz	a5,80003d6c <ialloc+0x84>
    brelse(bp);
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	a68080e7          	jalr	-1432(ra) # 800037ae <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d4e:	0485                	addi	s1,s1,1
    80003d50:	00ca2703          	lw	a4,12(s4)
    80003d54:	0004879b          	sext.w	a5,s1
    80003d58:	fce7e1e3          	bltu	a5,a4,80003d1a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d5c:	00005517          	auipc	a0,0x5
    80003d60:	90450513          	addi	a0,a0,-1788 # 80008660 <syscalls+0x180>
    80003d64:	ffffc097          	auipc	ra,0xffffc
    80003d68:	7da080e7          	jalr	2010(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003d6c:	04000613          	li	a2,64
    80003d70:	4581                	li	a1,0
    80003d72:	854e                	mv	a0,s3
    80003d74:	ffffd097          	auipc	ra,0xffffd
    80003d78:	f90080e7          	jalr	-112(ra) # 80000d04 <memset>
      dip->type = type;
    80003d7c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d80:	854a                	mv	a0,s2
    80003d82:	00001097          	auipc	ra,0x1
    80003d86:	ca8080e7          	jalr	-856(ra) # 80004a2a <log_write>
      brelse(bp);
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	a22080e7          	jalr	-1502(ra) # 800037ae <brelse>
      return iget(dev, inum);
    80003d94:	85da                	mv	a1,s6
    80003d96:	8556                	mv	a0,s5
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	db4080e7          	jalr	-588(ra) # 80003b4c <iget>
}
    80003da0:	60a6                	ld	ra,72(sp)
    80003da2:	6406                	ld	s0,64(sp)
    80003da4:	74e2                	ld	s1,56(sp)
    80003da6:	7942                	ld	s2,48(sp)
    80003da8:	79a2                	ld	s3,40(sp)
    80003daa:	7a02                	ld	s4,32(sp)
    80003dac:	6ae2                	ld	s5,24(sp)
    80003dae:	6b42                	ld	s6,16(sp)
    80003db0:	6ba2                	ld	s7,8(sp)
    80003db2:	6161                	addi	sp,sp,80
    80003db4:	8082                	ret

0000000080003db6 <iupdate>:
{
    80003db6:	1101                	addi	sp,sp,-32
    80003db8:	ec06                	sd	ra,24(sp)
    80003dba:	e822                	sd	s0,16(sp)
    80003dbc:	e426                	sd	s1,8(sp)
    80003dbe:	e04a                	sd	s2,0(sp)
    80003dc0:	1000                	addi	s0,sp,32
    80003dc2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dc4:	415c                	lw	a5,4(a0)
    80003dc6:	0047d79b          	srliw	a5,a5,0x4
    80003dca:	0001c597          	auipc	a1,0x1c
    80003dce:	39e5a583          	lw	a1,926(a1) # 80020168 <sb+0x18>
    80003dd2:	9dbd                	addw	a1,a1,a5
    80003dd4:	4108                	lw	a0,0(a0)
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	8a8080e7          	jalr	-1880(ra) # 8000367e <bread>
    80003dde:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003de0:	05850793          	addi	a5,a0,88
    80003de4:	40c8                	lw	a0,4(s1)
    80003de6:	893d                	andi	a0,a0,15
    80003de8:	051a                	slli	a0,a0,0x6
    80003dea:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003dec:	04449703          	lh	a4,68(s1)
    80003df0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003df4:	04649703          	lh	a4,70(s1)
    80003df8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003dfc:	04849703          	lh	a4,72(s1)
    80003e00:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e04:	04a49703          	lh	a4,74(s1)
    80003e08:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e0c:	44f8                	lw	a4,76(s1)
    80003e0e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e10:	03400613          	li	a2,52
    80003e14:	05048593          	addi	a1,s1,80
    80003e18:	0531                	addi	a0,a0,12
    80003e1a:	ffffd097          	auipc	ra,0xffffd
    80003e1e:	f4a080e7          	jalr	-182(ra) # 80000d64 <memmove>
  log_write(bp);
    80003e22:	854a                	mv	a0,s2
    80003e24:	00001097          	auipc	ra,0x1
    80003e28:	c06080e7          	jalr	-1018(ra) # 80004a2a <log_write>
  brelse(bp);
    80003e2c:	854a                	mv	a0,s2
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	980080e7          	jalr	-1664(ra) # 800037ae <brelse>
}
    80003e36:	60e2                	ld	ra,24(sp)
    80003e38:	6442                	ld	s0,16(sp)
    80003e3a:	64a2                	ld	s1,8(sp)
    80003e3c:	6902                	ld	s2,0(sp)
    80003e3e:	6105                	addi	sp,sp,32
    80003e40:	8082                	ret

0000000080003e42 <idup>:
{
    80003e42:	1101                	addi	sp,sp,-32
    80003e44:	ec06                	sd	ra,24(sp)
    80003e46:	e822                	sd	s0,16(sp)
    80003e48:	e426                	sd	s1,8(sp)
    80003e4a:	1000                	addi	s0,sp,32
    80003e4c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e4e:	0001c517          	auipc	a0,0x1c
    80003e52:	32250513          	addi	a0,a0,802 # 80020170 <itable>
    80003e56:	ffffd097          	auipc	ra,0xffffd
    80003e5a:	d8e080e7          	jalr	-626(ra) # 80000be4 <acquire>
  ip->ref++;
    80003e5e:	449c                	lw	a5,8(s1)
    80003e60:	2785                	addiw	a5,a5,1
    80003e62:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e64:	0001c517          	auipc	a0,0x1c
    80003e68:	30c50513          	addi	a0,a0,780 # 80020170 <itable>
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	e3e080e7          	jalr	-450(ra) # 80000caa <release>
}
    80003e74:	8526                	mv	a0,s1
    80003e76:	60e2                	ld	ra,24(sp)
    80003e78:	6442                	ld	s0,16(sp)
    80003e7a:	64a2                	ld	s1,8(sp)
    80003e7c:	6105                	addi	sp,sp,32
    80003e7e:	8082                	ret

0000000080003e80 <ilock>:
{
    80003e80:	1101                	addi	sp,sp,-32
    80003e82:	ec06                	sd	ra,24(sp)
    80003e84:	e822                	sd	s0,16(sp)
    80003e86:	e426                	sd	s1,8(sp)
    80003e88:	e04a                	sd	s2,0(sp)
    80003e8a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e8c:	c115                	beqz	a0,80003eb0 <ilock+0x30>
    80003e8e:	84aa                	mv	s1,a0
    80003e90:	451c                	lw	a5,8(a0)
    80003e92:	00f05f63          	blez	a5,80003eb0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e96:	0541                	addi	a0,a0,16
    80003e98:	00001097          	auipc	ra,0x1
    80003e9c:	cb2080e7          	jalr	-846(ra) # 80004b4a <acquiresleep>
  if(ip->valid == 0){
    80003ea0:	40bc                	lw	a5,64(s1)
    80003ea2:	cf99                	beqz	a5,80003ec0 <ilock+0x40>
}
    80003ea4:	60e2                	ld	ra,24(sp)
    80003ea6:	6442                	ld	s0,16(sp)
    80003ea8:	64a2                	ld	s1,8(sp)
    80003eaa:	6902                	ld	s2,0(sp)
    80003eac:	6105                	addi	sp,sp,32
    80003eae:	8082                	ret
    panic("ilock");
    80003eb0:	00004517          	auipc	a0,0x4
    80003eb4:	7c850513          	addi	a0,a0,1992 # 80008678 <syscalls+0x198>
    80003eb8:	ffffc097          	auipc	ra,0xffffc
    80003ebc:	686080e7          	jalr	1670(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ec0:	40dc                	lw	a5,4(s1)
    80003ec2:	0047d79b          	srliw	a5,a5,0x4
    80003ec6:	0001c597          	auipc	a1,0x1c
    80003eca:	2a25a583          	lw	a1,674(a1) # 80020168 <sb+0x18>
    80003ece:	9dbd                	addw	a1,a1,a5
    80003ed0:	4088                	lw	a0,0(s1)
    80003ed2:	fffff097          	auipc	ra,0xfffff
    80003ed6:	7ac080e7          	jalr	1964(ra) # 8000367e <bread>
    80003eda:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003edc:	05850593          	addi	a1,a0,88
    80003ee0:	40dc                	lw	a5,4(s1)
    80003ee2:	8bbd                	andi	a5,a5,15
    80003ee4:	079a                	slli	a5,a5,0x6
    80003ee6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ee8:	00059783          	lh	a5,0(a1)
    80003eec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ef0:	00259783          	lh	a5,2(a1)
    80003ef4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ef8:	00459783          	lh	a5,4(a1)
    80003efc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f00:	00659783          	lh	a5,6(a1)
    80003f04:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f08:	459c                	lw	a5,8(a1)
    80003f0a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f0c:	03400613          	li	a2,52
    80003f10:	05b1                	addi	a1,a1,12
    80003f12:	05048513          	addi	a0,s1,80
    80003f16:	ffffd097          	auipc	ra,0xffffd
    80003f1a:	e4e080e7          	jalr	-434(ra) # 80000d64 <memmove>
    brelse(bp);
    80003f1e:	854a                	mv	a0,s2
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	88e080e7          	jalr	-1906(ra) # 800037ae <brelse>
    ip->valid = 1;
    80003f28:	4785                	li	a5,1
    80003f2a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f2c:	04449783          	lh	a5,68(s1)
    80003f30:	fbb5                	bnez	a5,80003ea4 <ilock+0x24>
      panic("ilock: no type");
    80003f32:	00004517          	auipc	a0,0x4
    80003f36:	74e50513          	addi	a0,a0,1870 # 80008680 <syscalls+0x1a0>
    80003f3a:	ffffc097          	auipc	ra,0xffffc
    80003f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>

0000000080003f42 <iunlock>:
{
    80003f42:	1101                	addi	sp,sp,-32
    80003f44:	ec06                	sd	ra,24(sp)
    80003f46:	e822                	sd	s0,16(sp)
    80003f48:	e426                	sd	s1,8(sp)
    80003f4a:	e04a                	sd	s2,0(sp)
    80003f4c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f4e:	c905                	beqz	a0,80003f7e <iunlock+0x3c>
    80003f50:	84aa                	mv	s1,a0
    80003f52:	01050913          	addi	s2,a0,16
    80003f56:	854a                	mv	a0,s2
    80003f58:	00001097          	auipc	ra,0x1
    80003f5c:	c8c080e7          	jalr	-884(ra) # 80004be4 <holdingsleep>
    80003f60:	cd19                	beqz	a0,80003f7e <iunlock+0x3c>
    80003f62:	449c                	lw	a5,8(s1)
    80003f64:	00f05d63          	blez	a5,80003f7e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f68:	854a                	mv	a0,s2
    80003f6a:	00001097          	auipc	ra,0x1
    80003f6e:	c36080e7          	jalr	-970(ra) # 80004ba0 <releasesleep>
}
    80003f72:	60e2                	ld	ra,24(sp)
    80003f74:	6442                	ld	s0,16(sp)
    80003f76:	64a2                	ld	s1,8(sp)
    80003f78:	6902                	ld	s2,0(sp)
    80003f7a:	6105                	addi	sp,sp,32
    80003f7c:	8082                	ret
    panic("iunlock");
    80003f7e:	00004517          	auipc	a0,0x4
    80003f82:	71250513          	addi	a0,a0,1810 # 80008690 <syscalls+0x1b0>
    80003f86:	ffffc097          	auipc	ra,0xffffc
    80003f8a:	5b8080e7          	jalr	1464(ra) # 8000053e <panic>

0000000080003f8e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f8e:	7179                	addi	sp,sp,-48
    80003f90:	f406                	sd	ra,40(sp)
    80003f92:	f022                	sd	s0,32(sp)
    80003f94:	ec26                	sd	s1,24(sp)
    80003f96:	e84a                	sd	s2,16(sp)
    80003f98:	e44e                	sd	s3,8(sp)
    80003f9a:	e052                	sd	s4,0(sp)
    80003f9c:	1800                	addi	s0,sp,48
    80003f9e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fa0:	05050493          	addi	s1,a0,80
    80003fa4:	08050913          	addi	s2,a0,128
    80003fa8:	a021                	j	80003fb0 <itrunc+0x22>
    80003faa:	0491                	addi	s1,s1,4
    80003fac:	01248d63          	beq	s1,s2,80003fc6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003fb0:	408c                	lw	a1,0(s1)
    80003fb2:	dde5                	beqz	a1,80003faa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003fb4:	0009a503          	lw	a0,0(s3)
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	90c080e7          	jalr	-1780(ra) # 800038c4 <bfree>
      ip->addrs[i] = 0;
    80003fc0:	0004a023          	sw	zero,0(s1)
    80003fc4:	b7dd                	j	80003faa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003fc6:	0809a583          	lw	a1,128(s3)
    80003fca:	e185                	bnez	a1,80003fea <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003fcc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003fd0:	854e                	mv	a0,s3
    80003fd2:	00000097          	auipc	ra,0x0
    80003fd6:	de4080e7          	jalr	-540(ra) # 80003db6 <iupdate>
}
    80003fda:	70a2                	ld	ra,40(sp)
    80003fdc:	7402                	ld	s0,32(sp)
    80003fde:	64e2                	ld	s1,24(sp)
    80003fe0:	6942                	ld	s2,16(sp)
    80003fe2:	69a2                	ld	s3,8(sp)
    80003fe4:	6a02                	ld	s4,0(sp)
    80003fe6:	6145                	addi	sp,sp,48
    80003fe8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fea:	0009a503          	lw	a0,0(s3)
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	690080e7          	jalr	1680(ra) # 8000367e <bread>
    80003ff6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ff8:	05850493          	addi	s1,a0,88
    80003ffc:	45850913          	addi	s2,a0,1112
    80004000:	a811                	j	80004014 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004002:	0009a503          	lw	a0,0(s3)
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	8be080e7          	jalr	-1858(ra) # 800038c4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000400e:	0491                	addi	s1,s1,4
    80004010:	01248563          	beq	s1,s2,8000401a <itrunc+0x8c>
      if(a[j])
    80004014:	408c                	lw	a1,0(s1)
    80004016:	dde5                	beqz	a1,8000400e <itrunc+0x80>
    80004018:	b7ed                	j	80004002 <itrunc+0x74>
    brelse(bp);
    8000401a:	8552                	mv	a0,s4
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	792080e7          	jalr	1938(ra) # 800037ae <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004024:	0809a583          	lw	a1,128(s3)
    80004028:	0009a503          	lw	a0,0(s3)
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	898080e7          	jalr	-1896(ra) # 800038c4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004034:	0809a023          	sw	zero,128(s3)
    80004038:	bf51                	j	80003fcc <itrunc+0x3e>

000000008000403a <iput>:
{
    8000403a:	1101                	addi	sp,sp,-32
    8000403c:	ec06                	sd	ra,24(sp)
    8000403e:	e822                	sd	s0,16(sp)
    80004040:	e426                	sd	s1,8(sp)
    80004042:	e04a                	sd	s2,0(sp)
    80004044:	1000                	addi	s0,sp,32
    80004046:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004048:	0001c517          	auipc	a0,0x1c
    8000404c:	12850513          	addi	a0,a0,296 # 80020170 <itable>
    80004050:	ffffd097          	auipc	ra,0xffffd
    80004054:	b94080e7          	jalr	-1132(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004058:	4498                	lw	a4,8(s1)
    8000405a:	4785                	li	a5,1
    8000405c:	02f70363          	beq	a4,a5,80004082 <iput+0x48>
  ip->ref--;
    80004060:	449c                	lw	a5,8(s1)
    80004062:	37fd                	addiw	a5,a5,-1
    80004064:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004066:	0001c517          	auipc	a0,0x1c
    8000406a:	10a50513          	addi	a0,a0,266 # 80020170 <itable>
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	c3c080e7          	jalr	-964(ra) # 80000caa <release>
}
    80004076:	60e2                	ld	ra,24(sp)
    80004078:	6442                	ld	s0,16(sp)
    8000407a:	64a2                	ld	s1,8(sp)
    8000407c:	6902                	ld	s2,0(sp)
    8000407e:	6105                	addi	sp,sp,32
    80004080:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004082:	40bc                	lw	a5,64(s1)
    80004084:	dff1                	beqz	a5,80004060 <iput+0x26>
    80004086:	04a49783          	lh	a5,74(s1)
    8000408a:	fbf9                	bnez	a5,80004060 <iput+0x26>
    acquiresleep(&ip->lock);
    8000408c:	01048913          	addi	s2,s1,16
    80004090:	854a                	mv	a0,s2
    80004092:	00001097          	auipc	ra,0x1
    80004096:	ab8080e7          	jalr	-1352(ra) # 80004b4a <acquiresleep>
    release(&itable.lock);
    8000409a:	0001c517          	auipc	a0,0x1c
    8000409e:	0d650513          	addi	a0,a0,214 # 80020170 <itable>
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	c08080e7          	jalr	-1016(ra) # 80000caa <release>
    itrunc(ip);
    800040aa:	8526                	mv	a0,s1
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	ee2080e7          	jalr	-286(ra) # 80003f8e <itrunc>
    ip->type = 0;
    800040b4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040b8:	8526                	mv	a0,s1
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	cfc080e7          	jalr	-772(ra) # 80003db6 <iupdate>
    ip->valid = 0;
    800040c2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040c6:	854a                	mv	a0,s2
    800040c8:	00001097          	auipc	ra,0x1
    800040cc:	ad8080e7          	jalr	-1320(ra) # 80004ba0 <releasesleep>
    acquire(&itable.lock);
    800040d0:	0001c517          	auipc	a0,0x1c
    800040d4:	0a050513          	addi	a0,a0,160 # 80020170 <itable>
    800040d8:	ffffd097          	auipc	ra,0xffffd
    800040dc:	b0c080e7          	jalr	-1268(ra) # 80000be4 <acquire>
    800040e0:	b741                	j	80004060 <iput+0x26>

00000000800040e2 <iunlockput>:
{
    800040e2:	1101                	addi	sp,sp,-32
    800040e4:	ec06                	sd	ra,24(sp)
    800040e6:	e822                	sd	s0,16(sp)
    800040e8:	e426                	sd	s1,8(sp)
    800040ea:	1000                	addi	s0,sp,32
    800040ec:	84aa                	mv	s1,a0
  iunlock(ip);
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	e54080e7          	jalr	-428(ra) # 80003f42 <iunlock>
  iput(ip);
    800040f6:	8526                	mv	a0,s1
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	f42080e7          	jalr	-190(ra) # 8000403a <iput>
}
    80004100:	60e2                	ld	ra,24(sp)
    80004102:	6442                	ld	s0,16(sp)
    80004104:	64a2                	ld	s1,8(sp)
    80004106:	6105                	addi	sp,sp,32
    80004108:	8082                	ret

000000008000410a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000410a:	1141                	addi	sp,sp,-16
    8000410c:	e422                	sd	s0,8(sp)
    8000410e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004110:	411c                	lw	a5,0(a0)
    80004112:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004114:	415c                	lw	a5,4(a0)
    80004116:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004118:	04451783          	lh	a5,68(a0)
    8000411c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004120:	04a51783          	lh	a5,74(a0)
    80004124:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004128:	04c56783          	lwu	a5,76(a0)
    8000412c:	e99c                	sd	a5,16(a1)
}
    8000412e:	6422                	ld	s0,8(sp)
    80004130:	0141                	addi	sp,sp,16
    80004132:	8082                	ret

0000000080004134 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004134:	457c                	lw	a5,76(a0)
    80004136:	0ed7e963          	bltu	a5,a3,80004228 <readi+0xf4>
{
    8000413a:	7159                	addi	sp,sp,-112
    8000413c:	f486                	sd	ra,104(sp)
    8000413e:	f0a2                	sd	s0,96(sp)
    80004140:	eca6                	sd	s1,88(sp)
    80004142:	e8ca                	sd	s2,80(sp)
    80004144:	e4ce                	sd	s3,72(sp)
    80004146:	e0d2                	sd	s4,64(sp)
    80004148:	fc56                	sd	s5,56(sp)
    8000414a:	f85a                	sd	s6,48(sp)
    8000414c:	f45e                	sd	s7,40(sp)
    8000414e:	f062                	sd	s8,32(sp)
    80004150:	ec66                	sd	s9,24(sp)
    80004152:	e86a                	sd	s10,16(sp)
    80004154:	e46e                	sd	s11,8(sp)
    80004156:	1880                	addi	s0,sp,112
    80004158:	8baa                	mv	s7,a0
    8000415a:	8c2e                	mv	s8,a1
    8000415c:	8ab2                	mv	s5,a2
    8000415e:	84b6                	mv	s1,a3
    80004160:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004162:	9f35                	addw	a4,a4,a3
    return 0;
    80004164:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004166:	0ad76063          	bltu	a4,a3,80004206 <readi+0xd2>
  if(off + n > ip->size)
    8000416a:	00e7f463          	bgeu	a5,a4,80004172 <readi+0x3e>
    n = ip->size - off;
    8000416e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004172:	0a0b0963          	beqz	s6,80004224 <readi+0xf0>
    80004176:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004178:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000417c:	5cfd                	li	s9,-1
    8000417e:	a82d                	j	800041b8 <readi+0x84>
    80004180:	020a1d93          	slli	s11,s4,0x20
    80004184:	020ddd93          	srli	s11,s11,0x20
    80004188:	05890613          	addi	a2,s2,88
    8000418c:	86ee                	mv	a3,s11
    8000418e:	963a                	add	a2,a2,a4
    80004190:	85d6                	mv	a1,s5
    80004192:	8562                	mv	a0,s8
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	a1e080e7          	jalr	-1506(ra) # 80002bb2 <either_copyout>
    8000419c:	05950d63          	beq	a0,s9,800041f6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041a0:	854a                	mv	a0,s2
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	60c080e7          	jalr	1548(ra) # 800037ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041aa:	013a09bb          	addw	s3,s4,s3
    800041ae:	009a04bb          	addw	s1,s4,s1
    800041b2:	9aee                	add	s5,s5,s11
    800041b4:	0569f763          	bgeu	s3,s6,80004202 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041b8:	000ba903          	lw	s2,0(s7)
    800041bc:	00a4d59b          	srliw	a1,s1,0xa
    800041c0:	855e                	mv	a0,s7
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	8b0080e7          	jalr	-1872(ra) # 80003a72 <bmap>
    800041ca:	0005059b          	sext.w	a1,a0
    800041ce:	854a                	mv	a0,s2
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	4ae080e7          	jalr	1198(ra) # 8000367e <bread>
    800041d8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041da:	3ff4f713          	andi	a4,s1,1023
    800041de:	40ed07bb          	subw	a5,s10,a4
    800041e2:	413b06bb          	subw	a3,s6,s3
    800041e6:	8a3e                	mv	s4,a5
    800041e8:	2781                	sext.w	a5,a5
    800041ea:	0006861b          	sext.w	a2,a3
    800041ee:	f8f679e3          	bgeu	a2,a5,80004180 <readi+0x4c>
    800041f2:	8a36                	mv	s4,a3
    800041f4:	b771                	j	80004180 <readi+0x4c>
      brelse(bp);
    800041f6:	854a                	mv	a0,s2
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	5b6080e7          	jalr	1462(ra) # 800037ae <brelse>
      tot = -1;
    80004200:	59fd                	li	s3,-1
  }
  return tot;
    80004202:	0009851b          	sext.w	a0,s3
}
    80004206:	70a6                	ld	ra,104(sp)
    80004208:	7406                	ld	s0,96(sp)
    8000420a:	64e6                	ld	s1,88(sp)
    8000420c:	6946                	ld	s2,80(sp)
    8000420e:	69a6                	ld	s3,72(sp)
    80004210:	6a06                	ld	s4,64(sp)
    80004212:	7ae2                	ld	s5,56(sp)
    80004214:	7b42                	ld	s6,48(sp)
    80004216:	7ba2                	ld	s7,40(sp)
    80004218:	7c02                	ld	s8,32(sp)
    8000421a:	6ce2                	ld	s9,24(sp)
    8000421c:	6d42                	ld	s10,16(sp)
    8000421e:	6da2                	ld	s11,8(sp)
    80004220:	6165                	addi	sp,sp,112
    80004222:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004224:	89da                	mv	s3,s6
    80004226:	bff1                	j	80004202 <readi+0xce>
    return 0;
    80004228:	4501                	li	a0,0
}
    8000422a:	8082                	ret

000000008000422c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000422c:	457c                	lw	a5,76(a0)
    8000422e:	10d7e863          	bltu	a5,a3,8000433e <writei+0x112>
{
    80004232:	7159                	addi	sp,sp,-112
    80004234:	f486                	sd	ra,104(sp)
    80004236:	f0a2                	sd	s0,96(sp)
    80004238:	eca6                	sd	s1,88(sp)
    8000423a:	e8ca                	sd	s2,80(sp)
    8000423c:	e4ce                	sd	s3,72(sp)
    8000423e:	e0d2                	sd	s4,64(sp)
    80004240:	fc56                	sd	s5,56(sp)
    80004242:	f85a                	sd	s6,48(sp)
    80004244:	f45e                	sd	s7,40(sp)
    80004246:	f062                	sd	s8,32(sp)
    80004248:	ec66                	sd	s9,24(sp)
    8000424a:	e86a                	sd	s10,16(sp)
    8000424c:	e46e                	sd	s11,8(sp)
    8000424e:	1880                	addi	s0,sp,112
    80004250:	8b2a                	mv	s6,a0
    80004252:	8c2e                	mv	s8,a1
    80004254:	8ab2                	mv	s5,a2
    80004256:	8936                	mv	s2,a3
    80004258:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000425a:	00e687bb          	addw	a5,a3,a4
    8000425e:	0ed7e263          	bltu	a5,a3,80004342 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004262:	00043737          	lui	a4,0x43
    80004266:	0ef76063          	bltu	a4,a5,80004346 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000426a:	0c0b8863          	beqz	s7,8000433a <writei+0x10e>
    8000426e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004270:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004274:	5cfd                	li	s9,-1
    80004276:	a091                	j	800042ba <writei+0x8e>
    80004278:	02099d93          	slli	s11,s3,0x20
    8000427c:	020ddd93          	srli	s11,s11,0x20
    80004280:	05848513          	addi	a0,s1,88
    80004284:	86ee                	mv	a3,s11
    80004286:	8656                	mv	a2,s5
    80004288:	85e2                	mv	a1,s8
    8000428a:	953a                	add	a0,a0,a4
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	97c080e7          	jalr	-1668(ra) # 80002c08 <either_copyin>
    80004294:	07950263          	beq	a0,s9,800042f8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004298:	8526                	mv	a0,s1
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	790080e7          	jalr	1936(ra) # 80004a2a <log_write>
    brelse(bp);
    800042a2:	8526                	mv	a0,s1
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	50a080e7          	jalr	1290(ra) # 800037ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042ac:	01498a3b          	addw	s4,s3,s4
    800042b0:	0129893b          	addw	s2,s3,s2
    800042b4:	9aee                	add	s5,s5,s11
    800042b6:	057a7663          	bgeu	s4,s7,80004302 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042ba:	000b2483          	lw	s1,0(s6)
    800042be:	00a9559b          	srliw	a1,s2,0xa
    800042c2:	855a                	mv	a0,s6
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	7ae080e7          	jalr	1966(ra) # 80003a72 <bmap>
    800042cc:	0005059b          	sext.w	a1,a0
    800042d0:	8526                	mv	a0,s1
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	3ac080e7          	jalr	940(ra) # 8000367e <bread>
    800042da:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042dc:	3ff97713          	andi	a4,s2,1023
    800042e0:	40ed07bb          	subw	a5,s10,a4
    800042e4:	414b86bb          	subw	a3,s7,s4
    800042e8:	89be                	mv	s3,a5
    800042ea:	2781                	sext.w	a5,a5
    800042ec:	0006861b          	sext.w	a2,a3
    800042f0:	f8f674e3          	bgeu	a2,a5,80004278 <writei+0x4c>
    800042f4:	89b6                	mv	s3,a3
    800042f6:	b749                	j	80004278 <writei+0x4c>
      brelse(bp);
    800042f8:	8526                	mv	a0,s1
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	4b4080e7          	jalr	1204(ra) # 800037ae <brelse>
  }

  if(off > ip->size)
    80004302:	04cb2783          	lw	a5,76(s6)
    80004306:	0127f463          	bgeu	a5,s2,8000430e <writei+0xe2>
    ip->size = off;
    8000430a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000430e:	855a                	mv	a0,s6
    80004310:	00000097          	auipc	ra,0x0
    80004314:	aa6080e7          	jalr	-1370(ra) # 80003db6 <iupdate>

  return tot;
    80004318:	000a051b          	sext.w	a0,s4
}
    8000431c:	70a6                	ld	ra,104(sp)
    8000431e:	7406                	ld	s0,96(sp)
    80004320:	64e6                	ld	s1,88(sp)
    80004322:	6946                	ld	s2,80(sp)
    80004324:	69a6                	ld	s3,72(sp)
    80004326:	6a06                	ld	s4,64(sp)
    80004328:	7ae2                	ld	s5,56(sp)
    8000432a:	7b42                	ld	s6,48(sp)
    8000432c:	7ba2                	ld	s7,40(sp)
    8000432e:	7c02                	ld	s8,32(sp)
    80004330:	6ce2                	ld	s9,24(sp)
    80004332:	6d42                	ld	s10,16(sp)
    80004334:	6da2                	ld	s11,8(sp)
    80004336:	6165                	addi	sp,sp,112
    80004338:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000433a:	8a5e                	mv	s4,s7
    8000433c:	bfc9                	j	8000430e <writei+0xe2>
    return -1;
    8000433e:	557d                	li	a0,-1
}
    80004340:	8082                	ret
    return -1;
    80004342:	557d                	li	a0,-1
    80004344:	bfe1                	j	8000431c <writei+0xf0>
    return -1;
    80004346:	557d                	li	a0,-1
    80004348:	bfd1                	j	8000431c <writei+0xf0>

000000008000434a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000434a:	1141                	addi	sp,sp,-16
    8000434c:	e406                	sd	ra,8(sp)
    8000434e:	e022                	sd	s0,0(sp)
    80004350:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004352:	4639                	li	a2,14
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	a88080e7          	jalr	-1400(ra) # 80000ddc <strncmp>
}
    8000435c:	60a2                	ld	ra,8(sp)
    8000435e:	6402                	ld	s0,0(sp)
    80004360:	0141                	addi	sp,sp,16
    80004362:	8082                	ret

0000000080004364 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004364:	7139                	addi	sp,sp,-64
    80004366:	fc06                	sd	ra,56(sp)
    80004368:	f822                	sd	s0,48(sp)
    8000436a:	f426                	sd	s1,40(sp)
    8000436c:	f04a                	sd	s2,32(sp)
    8000436e:	ec4e                	sd	s3,24(sp)
    80004370:	e852                	sd	s4,16(sp)
    80004372:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004374:	04451703          	lh	a4,68(a0)
    80004378:	4785                	li	a5,1
    8000437a:	00f71a63          	bne	a4,a5,8000438e <dirlookup+0x2a>
    8000437e:	892a                	mv	s2,a0
    80004380:	89ae                	mv	s3,a1
    80004382:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004384:	457c                	lw	a5,76(a0)
    80004386:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004388:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000438a:	e79d                	bnez	a5,800043b8 <dirlookup+0x54>
    8000438c:	a8a5                	j	80004404 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000438e:	00004517          	auipc	a0,0x4
    80004392:	30a50513          	addi	a0,a0,778 # 80008698 <syscalls+0x1b8>
    80004396:	ffffc097          	auipc	ra,0xffffc
    8000439a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000439e:	00004517          	auipc	a0,0x4
    800043a2:	31250513          	addi	a0,a0,786 # 800086b0 <syscalls+0x1d0>
    800043a6:	ffffc097          	auipc	ra,0xffffc
    800043aa:	198080e7          	jalr	408(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ae:	24c1                	addiw	s1,s1,16
    800043b0:	04c92783          	lw	a5,76(s2)
    800043b4:	04f4f763          	bgeu	s1,a5,80004402 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b8:	4741                	li	a4,16
    800043ba:	86a6                	mv	a3,s1
    800043bc:	fc040613          	addi	a2,s0,-64
    800043c0:	4581                	li	a1,0
    800043c2:	854a                	mv	a0,s2
    800043c4:	00000097          	auipc	ra,0x0
    800043c8:	d70080e7          	jalr	-656(ra) # 80004134 <readi>
    800043cc:	47c1                	li	a5,16
    800043ce:	fcf518e3          	bne	a0,a5,8000439e <dirlookup+0x3a>
    if(de.inum == 0)
    800043d2:	fc045783          	lhu	a5,-64(s0)
    800043d6:	dfe1                	beqz	a5,800043ae <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043d8:	fc240593          	addi	a1,s0,-62
    800043dc:	854e                	mv	a0,s3
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	f6c080e7          	jalr	-148(ra) # 8000434a <namecmp>
    800043e6:	f561                	bnez	a0,800043ae <dirlookup+0x4a>
      if(poff)
    800043e8:	000a0463          	beqz	s4,800043f0 <dirlookup+0x8c>
        *poff = off;
    800043ec:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043f0:	fc045583          	lhu	a1,-64(s0)
    800043f4:	00092503          	lw	a0,0(s2)
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	754080e7          	jalr	1876(ra) # 80003b4c <iget>
    80004400:	a011                	j	80004404 <dirlookup+0xa0>
  return 0;
    80004402:	4501                	li	a0,0
}
    80004404:	70e2                	ld	ra,56(sp)
    80004406:	7442                	ld	s0,48(sp)
    80004408:	74a2                	ld	s1,40(sp)
    8000440a:	7902                	ld	s2,32(sp)
    8000440c:	69e2                	ld	s3,24(sp)
    8000440e:	6a42                	ld	s4,16(sp)
    80004410:	6121                	addi	sp,sp,64
    80004412:	8082                	ret

0000000080004414 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004414:	711d                	addi	sp,sp,-96
    80004416:	ec86                	sd	ra,88(sp)
    80004418:	e8a2                	sd	s0,80(sp)
    8000441a:	e4a6                	sd	s1,72(sp)
    8000441c:	e0ca                	sd	s2,64(sp)
    8000441e:	fc4e                	sd	s3,56(sp)
    80004420:	f852                	sd	s4,48(sp)
    80004422:	f456                	sd	s5,40(sp)
    80004424:	f05a                	sd	s6,32(sp)
    80004426:	ec5e                	sd	s7,24(sp)
    80004428:	e862                	sd	s8,16(sp)
    8000442a:	e466                	sd	s9,8(sp)
    8000442c:	1080                	addi	s0,sp,96
    8000442e:	84aa                	mv	s1,a0
    80004430:	8b2e                	mv	s6,a1
    80004432:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004434:	00054703          	lbu	a4,0(a0)
    80004438:	02f00793          	li	a5,47
    8000443c:	02f70363          	beq	a4,a5,80004462 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004440:	ffffe097          	auipc	ra,0xffffe
    80004444:	9b4080e7          	jalr	-1612(ra) # 80001df4 <myproc>
    80004448:	17053503          	ld	a0,368(a0)
    8000444c:	00000097          	auipc	ra,0x0
    80004450:	9f6080e7          	jalr	-1546(ra) # 80003e42 <idup>
    80004454:	89aa                	mv	s3,a0
  while(*path == '/')
    80004456:	02f00913          	li	s2,47
  len = path - s;
    8000445a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000445c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000445e:	4c05                	li	s8,1
    80004460:	a865                	j	80004518 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004462:	4585                	li	a1,1
    80004464:	4505                	li	a0,1
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	6e6080e7          	jalr	1766(ra) # 80003b4c <iget>
    8000446e:	89aa                	mv	s3,a0
    80004470:	b7dd                	j	80004456 <namex+0x42>
      iunlockput(ip);
    80004472:	854e                	mv	a0,s3
    80004474:	00000097          	auipc	ra,0x0
    80004478:	c6e080e7          	jalr	-914(ra) # 800040e2 <iunlockput>
      return 0;
    8000447c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000447e:	854e                	mv	a0,s3
    80004480:	60e6                	ld	ra,88(sp)
    80004482:	6446                	ld	s0,80(sp)
    80004484:	64a6                	ld	s1,72(sp)
    80004486:	6906                	ld	s2,64(sp)
    80004488:	79e2                	ld	s3,56(sp)
    8000448a:	7a42                	ld	s4,48(sp)
    8000448c:	7aa2                	ld	s5,40(sp)
    8000448e:	7b02                	ld	s6,32(sp)
    80004490:	6be2                	ld	s7,24(sp)
    80004492:	6c42                	ld	s8,16(sp)
    80004494:	6ca2                	ld	s9,8(sp)
    80004496:	6125                	addi	sp,sp,96
    80004498:	8082                	ret
      iunlock(ip);
    8000449a:	854e                	mv	a0,s3
    8000449c:	00000097          	auipc	ra,0x0
    800044a0:	aa6080e7          	jalr	-1370(ra) # 80003f42 <iunlock>
      return ip;
    800044a4:	bfe9                	j	8000447e <namex+0x6a>
      iunlockput(ip);
    800044a6:	854e                	mv	a0,s3
    800044a8:	00000097          	auipc	ra,0x0
    800044ac:	c3a080e7          	jalr	-966(ra) # 800040e2 <iunlockput>
      return 0;
    800044b0:	89d2                	mv	s3,s4
    800044b2:	b7f1                	j	8000447e <namex+0x6a>
  len = path - s;
    800044b4:	40b48633          	sub	a2,s1,a1
    800044b8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800044bc:	094cd463          	bge	s9,s4,80004544 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800044c0:	4639                	li	a2,14
    800044c2:	8556                	mv	a0,s5
    800044c4:	ffffd097          	auipc	ra,0xffffd
    800044c8:	8a0080e7          	jalr	-1888(ra) # 80000d64 <memmove>
  while(*path == '/')
    800044cc:	0004c783          	lbu	a5,0(s1)
    800044d0:	01279763          	bne	a5,s2,800044de <namex+0xca>
    path++;
    800044d4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044d6:	0004c783          	lbu	a5,0(s1)
    800044da:	ff278de3          	beq	a5,s2,800044d4 <namex+0xc0>
    ilock(ip);
    800044de:	854e                	mv	a0,s3
    800044e0:	00000097          	auipc	ra,0x0
    800044e4:	9a0080e7          	jalr	-1632(ra) # 80003e80 <ilock>
    if(ip->type != T_DIR){
    800044e8:	04499783          	lh	a5,68(s3)
    800044ec:	f98793e3          	bne	a5,s8,80004472 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044f0:	000b0563          	beqz	s6,800044fa <namex+0xe6>
    800044f4:	0004c783          	lbu	a5,0(s1)
    800044f8:	d3cd                	beqz	a5,8000449a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044fa:	865e                	mv	a2,s7
    800044fc:	85d6                	mv	a1,s5
    800044fe:	854e                	mv	a0,s3
    80004500:	00000097          	auipc	ra,0x0
    80004504:	e64080e7          	jalr	-412(ra) # 80004364 <dirlookup>
    80004508:	8a2a                	mv	s4,a0
    8000450a:	dd51                	beqz	a0,800044a6 <namex+0x92>
    iunlockput(ip);
    8000450c:	854e                	mv	a0,s3
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	bd4080e7          	jalr	-1068(ra) # 800040e2 <iunlockput>
    ip = next;
    80004516:	89d2                	mv	s3,s4
  while(*path == '/')
    80004518:	0004c783          	lbu	a5,0(s1)
    8000451c:	05279763          	bne	a5,s2,8000456a <namex+0x156>
    path++;
    80004520:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004522:	0004c783          	lbu	a5,0(s1)
    80004526:	ff278de3          	beq	a5,s2,80004520 <namex+0x10c>
  if(*path == 0)
    8000452a:	c79d                	beqz	a5,80004558 <namex+0x144>
    path++;
    8000452c:	85a6                	mv	a1,s1
  len = path - s;
    8000452e:	8a5e                	mv	s4,s7
    80004530:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004532:	01278963          	beq	a5,s2,80004544 <namex+0x130>
    80004536:	dfbd                	beqz	a5,800044b4 <namex+0xa0>
    path++;
    80004538:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000453a:	0004c783          	lbu	a5,0(s1)
    8000453e:	ff279ce3          	bne	a5,s2,80004536 <namex+0x122>
    80004542:	bf8d                	j	800044b4 <namex+0xa0>
    memmove(name, s, len);
    80004544:	2601                	sext.w	a2,a2
    80004546:	8556                	mv	a0,s5
    80004548:	ffffd097          	auipc	ra,0xffffd
    8000454c:	81c080e7          	jalr	-2020(ra) # 80000d64 <memmove>
    name[len] = 0;
    80004550:	9a56                	add	s4,s4,s5
    80004552:	000a0023          	sb	zero,0(s4)
    80004556:	bf9d                	j	800044cc <namex+0xb8>
  if(nameiparent){
    80004558:	f20b03e3          	beqz	s6,8000447e <namex+0x6a>
    iput(ip);
    8000455c:	854e                	mv	a0,s3
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	adc080e7          	jalr	-1316(ra) # 8000403a <iput>
    return 0;
    80004566:	4981                	li	s3,0
    80004568:	bf19                	j	8000447e <namex+0x6a>
  if(*path == 0)
    8000456a:	d7fd                	beqz	a5,80004558 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000456c:	0004c783          	lbu	a5,0(s1)
    80004570:	85a6                	mv	a1,s1
    80004572:	b7d1                	j	80004536 <namex+0x122>

0000000080004574 <dirlink>:
{
    80004574:	7139                	addi	sp,sp,-64
    80004576:	fc06                	sd	ra,56(sp)
    80004578:	f822                	sd	s0,48(sp)
    8000457a:	f426                	sd	s1,40(sp)
    8000457c:	f04a                	sd	s2,32(sp)
    8000457e:	ec4e                	sd	s3,24(sp)
    80004580:	e852                	sd	s4,16(sp)
    80004582:	0080                	addi	s0,sp,64
    80004584:	892a                	mv	s2,a0
    80004586:	8a2e                	mv	s4,a1
    80004588:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000458a:	4601                	li	a2,0
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	dd8080e7          	jalr	-552(ra) # 80004364 <dirlookup>
    80004594:	e93d                	bnez	a0,8000460a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004596:	04c92483          	lw	s1,76(s2)
    8000459a:	c49d                	beqz	s1,800045c8 <dirlink+0x54>
    8000459c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000459e:	4741                	li	a4,16
    800045a0:	86a6                	mv	a3,s1
    800045a2:	fc040613          	addi	a2,s0,-64
    800045a6:	4581                	li	a1,0
    800045a8:	854a                	mv	a0,s2
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	b8a080e7          	jalr	-1142(ra) # 80004134 <readi>
    800045b2:	47c1                	li	a5,16
    800045b4:	06f51163          	bne	a0,a5,80004616 <dirlink+0xa2>
    if(de.inum == 0)
    800045b8:	fc045783          	lhu	a5,-64(s0)
    800045bc:	c791                	beqz	a5,800045c8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045be:	24c1                	addiw	s1,s1,16
    800045c0:	04c92783          	lw	a5,76(s2)
    800045c4:	fcf4ede3          	bltu	s1,a5,8000459e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800045c8:	4639                	li	a2,14
    800045ca:	85d2                	mv	a1,s4
    800045cc:	fc240513          	addi	a0,s0,-62
    800045d0:	ffffd097          	auipc	ra,0xffffd
    800045d4:	848080e7          	jalr	-1976(ra) # 80000e18 <strncpy>
  de.inum = inum;
    800045d8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045dc:	4741                	li	a4,16
    800045de:	86a6                	mv	a3,s1
    800045e0:	fc040613          	addi	a2,s0,-64
    800045e4:	4581                	li	a1,0
    800045e6:	854a                	mv	a0,s2
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	c44080e7          	jalr	-956(ra) # 8000422c <writei>
    800045f0:	872a                	mv	a4,a0
    800045f2:	47c1                	li	a5,16
  return 0;
    800045f4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045f6:	02f71863          	bne	a4,a5,80004626 <dirlink+0xb2>
}
    800045fa:	70e2                	ld	ra,56(sp)
    800045fc:	7442                	ld	s0,48(sp)
    800045fe:	74a2                	ld	s1,40(sp)
    80004600:	7902                	ld	s2,32(sp)
    80004602:	69e2                	ld	s3,24(sp)
    80004604:	6a42                	ld	s4,16(sp)
    80004606:	6121                	addi	sp,sp,64
    80004608:	8082                	ret
    iput(ip);
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	a30080e7          	jalr	-1488(ra) # 8000403a <iput>
    return -1;
    80004612:	557d                	li	a0,-1
    80004614:	b7dd                	j	800045fa <dirlink+0x86>
      panic("dirlink read");
    80004616:	00004517          	auipc	a0,0x4
    8000461a:	0aa50513          	addi	a0,a0,170 # 800086c0 <syscalls+0x1e0>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
    panic("dirlink");
    80004626:	00004517          	auipc	a0,0x4
    8000462a:	1aa50513          	addi	a0,a0,426 # 800087d0 <syscalls+0x2f0>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>

0000000080004636 <namei>:

struct inode*
namei(char *path)
{
    80004636:	1101                	addi	sp,sp,-32
    80004638:	ec06                	sd	ra,24(sp)
    8000463a:	e822                	sd	s0,16(sp)
    8000463c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000463e:	fe040613          	addi	a2,s0,-32
    80004642:	4581                	li	a1,0
    80004644:	00000097          	auipc	ra,0x0
    80004648:	dd0080e7          	jalr	-560(ra) # 80004414 <namex>
}
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004654:	1141                	addi	sp,sp,-16
    80004656:	e406                	sd	ra,8(sp)
    80004658:	e022                	sd	s0,0(sp)
    8000465a:	0800                	addi	s0,sp,16
    8000465c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000465e:	4585                	li	a1,1
    80004660:	00000097          	auipc	ra,0x0
    80004664:	db4080e7          	jalr	-588(ra) # 80004414 <namex>
}
    80004668:	60a2                	ld	ra,8(sp)
    8000466a:	6402                	ld	s0,0(sp)
    8000466c:	0141                	addi	sp,sp,16
    8000466e:	8082                	ret

0000000080004670 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004670:	1101                	addi	sp,sp,-32
    80004672:	ec06                	sd	ra,24(sp)
    80004674:	e822                	sd	s0,16(sp)
    80004676:	e426                	sd	s1,8(sp)
    80004678:	e04a                	sd	s2,0(sp)
    8000467a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000467c:	0001d917          	auipc	s2,0x1d
    80004680:	59c90913          	addi	s2,s2,1436 # 80021c18 <log>
    80004684:	01892583          	lw	a1,24(s2)
    80004688:	02892503          	lw	a0,40(s2)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	ff2080e7          	jalr	-14(ra) # 8000367e <bread>
    80004694:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004696:	02c92683          	lw	a3,44(s2)
    8000469a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000469c:	02d05763          	blez	a3,800046ca <write_head+0x5a>
    800046a0:	0001d797          	auipc	a5,0x1d
    800046a4:	5a878793          	addi	a5,a5,1448 # 80021c48 <log+0x30>
    800046a8:	05c50713          	addi	a4,a0,92
    800046ac:	36fd                	addiw	a3,a3,-1
    800046ae:	1682                	slli	a3,a3,0x20
    800046b0:	9281                	srli	a3,a3,0x20
    800046b2:	068a                	slli	a3,a3,0x2
    800046b4:	0001d617          	auipc	a2,0x1d
    800046b8:	59860613          	addi	a2,a2,1432 # 80021c4c <log+0x34>
    800046bc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800046be:	4390                	lw	a2,0(a5)
    800046c0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046c2:	0791                	addi	a5,a5,4
    800046c4:	0711                	addi	a4,a4,4
    800046c6:	fed79ce3          	bne	a5,a3,800046be <write_head+0x4e>
  }
  bwrite(buf);
    800046ca:	8526                	mv	a0,s1
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	0a4080e7          	jalr	164(ra) # 80003770 <bwrite>
  brelse(buf);
    800046d4:	8526                	mv	a0,s1
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	0d8080e7          	jalr	216(ra) # 800037ae <brelse>
}
    800046de:	60e2                	ld	ra,24(sp)
    800046e0:	6442                	ld	s0,16(sp)
    800046e2:	64a2                	ld	s1,8(sp)
    800046e4:	6902                	ld	s2,0(sp)
    800046e6:	6105                	addi	sp,sp,32
    800046e8:	8082                	ret

00000000800046ea <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ea:	0001d797          	auipc	a5,0x1d
    800046ee:	55a7a783          	lw	a5,1370(a5) # 80021c44 <log+0x2c>
    800046f2:	0af05d63          	blez	a5,800047ac <install_trans+0xc2>
{
    800046f6:	7139                	addi	sp,sp,-64
    800046f8:	fc06                	sd	ra,56(sp)
    800046fa:	f822                	sd	s0,48(sp)
    800046fc:	f426                	sd	s1,40(sp)
    800046fe:	f04a                	sd	s2,32(sp)
    80004700:	ec4e                	sd	s3,24(sp)
    80004702:	e852                	sd	s4,16(sp)
    80004704:	e456                	sd	s5,8(sp)
    80004706:	e05a                	sd	s6,0(sp)
    80004708:	0080                	addi	s0,sp,64
    8000470a:	8b2a                	mv	s6,a0
    8000470c:	0001da97          	auipc	s5,0x1d
    80004710:	53ca8a93          	addi	s5,s5,1340 # 80021c48 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004714:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004716:	0001d997          	auipc	s3,0x1d
    8000471a:	50298993          	addi	s3,s3,1282 # 80021c18 <log>
    8000471e:	a035                	j	8000474a <install_trans+0x60>
      bunpin(dbuf);
    80004720:	8526                	mv	a0,s1
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	166080e7          	jalr	358(ra) # 80003888 <bunpin>
    brelse(lbuf);
    8000472a:	854a                	mv	a0,s2
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	082080e7          	jalr	130(ra) # 800037ae <brelse>
    brelse(dbuf);
    80004734:	8526                	mv	a0,s1
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	078080e7          	jalr	120(ra) # 800037ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000473e:	2a05                	addiw	s4,s4,1
    80004740:	0a91                	addi	s5,s5,4
    80004742:	02c9a783          	lw	a5,44(s3)
    80004746:	04fa5963          	bge	s4,a5,80004798 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000474a:	0189a583          	lw	a1,24(s3)
    8000474e:	014585bb          	addw	a1,a1,s4
    80004752:	2585                	addiw	a1,a1,1
    80004754:	0289a503          	lw	a0,40(s3)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	f26080e7          	jalr	-218(ra) # 8000367e <bread>
    80004760:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004762:	000aa583          	lw	a1,0(s5)
    80004766:	0289a503          	lw	a0,40(s3)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	f14080e7          	jalr	-236(ra) # 8000367e <bread>
    80004772:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004774:	40000613          	li	a2,1024
    80004778:	05890593          	addi	a1,s2,88
    8000477c:	05850513          	addi	a0,a0,88
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	5e4080e7          	jalr	1508(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004788:	8526                	mv	a0,s1
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	fe6080e7          	jalr	-26(ra) # 80003770 <bwrite>
    if(recovering == 0)
    80004792:	f80b1ce3          	bnez	s6,8000472a <install_trans+0x40>
    80004796:	b769                	j	80004720 <install_trans+0x36>
}
    80004798:	70e2                	ld	ra,56(sp)
    8000479a:	7442                	ld	s0,48(sp)
    8000479c:	74a2                	ld	s1,40(sp)
    8000479e:	7902                	ld	s2,32(sp)
    800047a0:	69e2                	ld	s3,24(sp)
    800047a2:	6a42                	ld	s4,16(sp)
    800047a4:	6aa2                	ld	s5,8(sp)
    800047a6:	6b02                	ld	s6,0(sp)
    800047a8:	6121                	addi	sp,sp,64
    800047aa:	8082                	ret
    800047ac:	8082                	ret

00000000800047ae <initlog>:
{
    800047ae:	7179                	addi	sp,sp,-48
    800047b0:	f406                	sd	ra,40(sp)
    800047b2:	f022                	sd	s0,32(sp)
    800047b4:	ec26                	sd	s1,24(sp)
    800047b6:	e84a                	sd	s2,16(sp)
    800047b8:	e44e                	sd	s3,8(sp)
    800047ba:	1800                	addi	s0,sp,48
    800047bc:	892a                	mv	s2,a0
    800047be:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047c0:	0001d497          	auipc	s1,0x1d
    800047c4:	45848493          	addi	s1,s1,1112 # 80021c18 <log>
    800047c8:	00004597          	auipc	a1,0x4
    800047cc:	f0858593          	addi	a1,a1,-248 # 800086d0 <syscalls+0x1f0>
    800047d0:	8526                	mv	a0,s1
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	382080e7          	jalr	898(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800047da:	0149a583          	lw	a1,20(s3)
    800047de:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047e0:	0109a783          	lw	a5,16(s3)
    800047e4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047e6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047ea:	854a                	mv	a0,s2
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	e92080e7          	jalr	-366(ra) # 8000367e <bread>
  log.lh.n = lh->n;
    800047f4:	4d3c                	lw	a5,88(a0)
    800047f6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047f8:	02f05563          	blez	a5,80004822 <initlog+0x74>
    800047fc:	05c50713          	addi	a4,a0,92
    80004800:	0001d697          	auipc	a3,0x1d
    80004804:	44868693          	addi	a3,a3,1096 # 80021c48 <log+0x30>
    80004808:	37fd                	addiw	a5,a5,-1
    8000480a:	1782                	slli	a5,a5,0x20
    8000480c:	9381                	srli	a5,a5,0x20
    8000480e:	078a                	slli	a5,a5,0x2
    80004810:	06050613          	addi	a2,a0,96
    80004814:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004816:	4310                	lw	a2,0(a4)
    80004818:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000481a:	0711                	addi	a4,a4,4
    8000481c:	0691                	addi	a3,a3,4
    8000481e:	fef71ce3          	bne	a4,a5,80004816 <initlog+0x68>
  brelse(buf);
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	f8c080e7          	jalr	-116(ra) # 800037ae <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000482a:	4505                	li	a0,1
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	ebe080e7          	jalr	-322(ra) # 800046ea <install_trans>
  log.lh.n = 0;
    80004834:	0001d797          	auipc	a5,0x1d
    80004838:	4007a823          	sw	zero,1040(a5) # 80021c44 <log+0x2c>
  write_head(); // clear the log
    8000483c:	00000097          	auipc	ra,0x0
    80004840:	e34080e7          	jalr	-460(ra) # 80004670 <write_head>
}
    80004844:	70a2                	ld	ra,40(sp)
    80004846:	7402                	ld	s0,32(sp)
    80004848:	64e2                	ld	s1,24(sp)
    8000484a:	6942                	ld	s2,16(sp)
    8000484c:	69a2                	ld	s3,8(sp)
    8000484e:	6145                	addi	sp,sp,48
    80004850:	8082                	ret

0000000080004852 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004852:	1101                	addi	sp,sp,-32
    80004854:	ec06                	sd	ra,24(sp)
    80004856:	e822                	sd	s0,16(sp)
    80004858:	e426                	sd	s1,8(sp)
    8000485a:	e04a                	sd	s2,0(sp)
    8000485c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000485e:	0001d517          	auipc	a0,0x1d
    80004862:	3ba50513          	addi	a0,a0,954 # 80021c18 <log>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	37e080e7          	jalr	894(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000486e:	0001d497          	auipc	s1,0x1d
    80004872:	3aa48493          	addi	s1,s1,938 # 80021c18 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004876:	4979                	li	s2,30
    80004878:	a039                	j	80004886 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000487a:	85a6                	mv	a1,s1
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffe097          	auipc	ra,0xffffe
    80004882:	e50080e7          	jalr	-432(ra) # 800026ce <sleep>
    if(log.committing){
    80004886:	50dc                	lw	a5,36(s1)
    80004888:	fbed                	bnez	a5,8000487a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000488a:	509c                	lw	a5,32(s1)
    8000488c:	0017871b          	addiw	a4,a5,1
    80004890:	0007069b          	sext.w	a3,a4
    80004894:	0027179b          	slliw	a5,a4,0x2
    80004898:	9fb9                	addw	a5,a5,a4
    8000489a:	0017979b          	slliw	a5,a5,0x1
    8000489e:	54d8                	lw	a4,44(s1)
    800048a0:	9fb9                	addw	a5,a5,a4
    800048a2:	00f95963          	bge	s2,a5,800048b4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048a6:	85a6                	mv	a1,s1
    800048a8:	8526                	mv	a0,s1
    800048aa:	ffffe097          	auipc	ra,0xffffe
    800048ae:	e24080e7          	jalr	-476(ra) # 800026ce <sleep>
    800048b2:	bfd1                	j	80004886 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048b4:	0001d517          	auipc	a0,0x1d
    800048b8:	36450513          	addi	a0,a0,868 # 80021c18 <log>
    800048bc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	3ec080e7          	jalr	1004(ra) # 80000caa <release>
      break;
    }
  }
}
    800048c6:	60e2                	ld	ra,24(sp)
    800048c8:	6442                	ld	s0,16(sp)
    800048ca:	64a2                	ld	s1,8(sp)
    800048cc:	6902                	ld	s2,0(sp)
    800048ce:	6105                	addi	sp,sp,32
    800048d0:	8082                	ret

00000000800048d2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048d2:	7139                	addi	sp,sp,-64
    800048d4:	fc06                	sd	ra,56(sp)
    800048d6:	f822                	sd	s0,48(sp)
    800048d8:	f426                	sd	s1,40(sp)
    800048da:	f04a                	sd	s2,32(sp)
    800048dc:	ec4e                	sd	s3,24(sp)
    800048de:	e852                	sd	s4,16(sp)
    800048e0:	e456                	sd	s5,8(sp)
    800048e2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048e4:	0001d497          	auipc	s1,0x1d
    800048e8:	33448493          	addi	s1,s1,820 # 80021c18 <log>
    800048ec:	8526                	mv	a0,s1
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	2f6080e7          	jalr	758(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800048f6:	509c                	lw	a5,32(s1)
    800048f8:	37fd                	addiw	a5,a5,-1
    800048fa:	0007891b          	sext.w	s2,a5
    800048fe:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004900:	50dc                	lw	a5,36(s1)
    80004902:	efb9                	bnez	a5,80004960 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004904:	06091663          	bnez	s2,80004970 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004908:	0001d497          	auipc	s1,0x1d
    8000490c:	31048493          	addi	s1,s1,784 # 80021c18 <log>
    80004910:	4785                	li	a5,1
    80004912:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004914:	8526                	mv	a0,s1
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	394080e7          	jalr	916(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000491e:	54dc                	lw	a5,44(s1)
    80004920:	06f04763          	bgtz	a5,8000498e <end_op+0xbc>
    acquire(&log.lock);
    80004924:	0001d497          	auipc	s1,0x1d
    80004928:	2f448493          	addi	s1,s1,756 # 80021c18 <log>
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	2b6080e7          	jalr	694(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004936:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000493a:	8526                	mv	a0,s1
    8000493c:	ffffe097          	auipc	ra,0xffffe
    80004940:	f3a080e7          	jalr	-198(ra) # 80002876 <wakeup>
    release(&log.lock);
    80004944:	8526                	mv	a0,s1
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	364080e7          	jalr	868(ra) # 80000caa <release>
}
    8000494e:	70e2                	ld	ra,56(sp)
    80004950:	7442                	ld	s0,48(sp)
    80004952:	74a2                	ld	s1,40(sp)
    80004954:	7902                	ld	s2,32(sp)
    80004956:	69e2                	ld	s3,24(sp)
    80004958:	6a42                	ld	s4,16(sp)
    8000495a:	6aa2                	ld	s5,8(sp)
    8000495c:	6121                	addi	sp,sp,64
    8000495e:	8082                	ret
    panic("log.committing");
    80004960:	00004517          	auipc	a0,0x4
    80004964:	d7850513          	addi	a0,a0,-648 # 800086d8 <syscalls+0x1f8>
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	bd6080e7          	jalr	-1066(ra) # 8000053e <panic>
    wakeup(&log);
    80004970:	0001d497          	auipc	s1,0x1d
    80004974:	2a848493          	addi	s1,s1,680 # 80021c18 <log>
    80004978:	8526                	mv	a0,s1
    8000497a:	ffffe097          	auipc	ra,0xffffe
    8000497e:	efc080e7          	jalr	-260(ra) # 80002876 <wakeup>
  release(&log.lock);
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	326080e7          	jalr	806(ra) # 80000caa <release>
  if(do_commit){
    8000498c:	b7c9                	j	8000494e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000498e:	0001da97          	auipc	s5,0x1d
    80004992:	2baa8a93          	addi	s5,s5,698 # 80021c48 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004996:	0001da17          	auipc	s4,0x1d
    8000499a:	282a0a13          	addi	s4,s4,642 # 80021c18 <log>
    8000499e:	018a2583          	lw	a1,24(s4)
    800049a2:	012585bb          	addw	a1,a1,s2
    800049a6:	2585                	addiw	a1,a1,1
    800049a8:	028a2503          	lw	a0,40(s4)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	cd2080e7          	jalr	-814(ra) # 8000367e <bread>
    800049b4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049b6:	000aa583          	lw	a1,0(s5)
    800049ba:	028a2503          	lw	a0,40(s4)
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	cc0080e7          	jalr	-832(ra) # 8000367e <bread>
    800049c6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800049c8:	40000613          	li	a2,1024
    800049cc:	05850593          	addi	a1,a0,88
    800049d0:	05848513          	addi	a0,s1,88
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	390080e7          	jalr	912(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    800049dc:	8526                	mv	a0,s1
    800049de:	fffff097          	auipc	ra,0xfffff
    800049e2:	d92080e7          	jalr	-622(ra) # 80003770 <bwrite>
    brelse(from);
    800049e6:	854e                	mv	a0,s3
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	dc6080e7          	jalr	-570(ra) # 800037ae <brelse>
    brelse(to);
    800049f0:	8526                	mv	a0,s1
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	dbc080e7          	jalr	-580(ra) # 800037ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049fa:	2905                	addiw	s2,s2,1
    800049fc:	0a91                	addi	s5,s5,4
    800049fe:	02ca2783          	lw	a5,44(s4)
    80004a02:	f8f94ee3          	blt	s2,a5,8000499e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	c6a080e7          	jalr	-918(ra) # 80004670 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a0e:	4501                	li	a0,0
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	cda080e7          	jalr	-806(ra) # 800046ea <install_trans>
    log.lh.n = 0;
    80004a18:	0001d797          	auipc	a5,0x1d
    80004a1c:	2207a623          	sw	zero,556(a5) # 80021c44 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a20:	00000097          	auipc	ra,0x0
    80004a24:	c50080e7          	jalr	-944(ra) # 80004670 <write_head>
    80004a28:	bdf5                	j	80004924 <end_op+0x52>

0000000080004a2a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a2a:	1101                	addi	sp,sp,-32
    80004a2c:	ec06                	sd	ra,24(sp)
    80004a2e:	e822                	sd	s0,16(sp)
    80004a30:	e426                	sd	s1,8(sp)
    80004a32:	e04a                	sd	s2,0(sp)
    80004a34:	1000                	addi	s0,sp,32
    80004a36:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a38:	0001d917          	auipc	s2,0x1d
    80004a3c:	1e090913          	addi	s2,s2,480 # 80021c18 <log>
    80004a40:	854a                	mv	a0,s2
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	1a2080e7          	jalr	418(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a4a:	02c92603          	lw	a2,44(s2)
    80004a4e:	47f5                	li	a5,29
    80004a50:	06c7c563          	blt	a5,a2,80004aba <log_write+0x90>
    80004a54:	0001d797          	auipc	a5,0x1d
    80004a58:	1e07a783          	lw	a5,480(a5) # 80021c34 <log+0x1c>
    80004a5c:	37fd                	addiw	a5,a5,-1
    80004a5e:	04f65e63          	bge	a2,a5,80004aba <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a62:	0001d797          	auipc	a5,0x1d
    80004a66:	1d67a783          	lw	a5,470(a5) # 80021c38 <log+0x20>
    80004a6a:	06f05063          	blez	a5,80004aca <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a6e:	4781                	li	a5,0
    80004a70:	06c05563          	blez	a2,80004ada <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a74:	44cc                	lw	a1,12(s1)
    80004a76:	0001d717          	auipc	a4,0x1d
    80004a7a:	1d270713          	addi	a4,a4,466 # 80021c48 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a7e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a80:	4314                	lw	a3,0(a4)
    80004a82:	04b68c63          	beq	a3,a1,80004ada <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a86:	2785                	addiw	a5,a5,1
    80004a88:	0711                	addi	a4,a4,4
    80004a8a:	fef61be3          	bne	a2,a5,80004a80 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a8e:	0621                	addi	a2,a2,8
    80004a90:	060a                	slli	a2,a2,0x2
    80004a92:	0001d797          	auipc	a5,0x1d
    80004a96:	18678793          	addi	a5,a5,390 # 80021c18 <log>
    80004a9a:	963e                	add	a2,a2,a5
    80004a9c:	44dc                	lw	a5,12(s1)
    80004a9e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	fffff097          	auipc	ra,0xfffff
    80004aa6:	daa080e7          	jalr	-598(ra) # 8000384c <bpin>
    log.lh.n++;
    80004aaa:	0001d717          	auipc	a4,0x1d
    80004aae:	16e70713          	addi	a4,a4,366 # 80021c18 <log>
    80004ab2:	575c                	lw	a5,44(a4)
    80004ab4:	2785                	addiw	a5,a5,1
    80004ab6:	d75c                	sw	a5,44(a4)
    80004ab8:	a835                	j	80004af4 <log_write+0xca>
    panic("too big a transaction");
    80004aba:	00004517          	auipc	a0,0x4
    80004abe:	c2e50513          	addi	a0,a0,-978 # 800086e8 <syscalls+0x208>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	a7c080e7          	jalr	-1412(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004aca:	00004517          	auipc	a0,0x4
    80004ace:	c3650513          	addi	a0,a0,-970 # 80008700 <syscalls+0x220>
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	a6c080e7          	jalr	-1428(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004ada:	00878713          	addi	a4,a5,8
    80004ade:	00271693          	slli	a3,a4,0x2
    80004ae2:	0001d717          	auipc	a4,0x1d
    80004ae6:	13670713          	addi	a4,a4,310 # 80021c18 <log>
    80004aea:	9736                	add	a4,a4,a3
    80004aec:	44d4                	lw	a3,12(s1)
    80004aee:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004af0:	faf608e3          	beq	a2,a5,80004aa0 <log_write+0x76>
  }
  release(&log.lock);
    80004af4:	0001d517          	auipc	a0,0x1d
    80004af8:	12450513          	addi	a0,a0,292 # 80021c18 <log>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	1ae080e7          	jalr	430(ra) # 80000caa <release>
}
    80004b04:	60e2                	ld	ra,24(sp)
    80004b06:	6442                	ld	s0,16(sp)
    80004b08:	64a2                	ld	s1,8(sp)
    80004b0a:	6902                	ld	s2,0(sp)
    80004b0c:	6105                	addi	sp,sp,32
    80004b0e:	8082                	ret

0000000080004b10 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b10:	1101                	addi	sp,sp,-32
    80004b12:	ec06                	sd	ra,24(sp)
    80004b14:	e822                	sd	s0,16(sp)
    80004b16:	e426                	sd	s1,8(sp)
    80004b18:	e04a                	sd	s2,0(sp)
    80004b1a:	1000                	addi	s0,sp,32
    80004b1c:	84aa                	mv	s1,a0
    80004b1e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b20:	00004597          	auipc	a1,0x4
    80004b24:	c0058593          	addi	a1,a1,-1024 # 80008720 <syscalls+0x240>
    80004b28:	0521                	addi	a0,a0,8
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	02a080e7          	jalr	42(ra) # 80000b54 <initlock>
  lk->name = name;
    80004b32:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b36:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b3a:	0204a423          	sw	zero,40(s1)
}
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6902                	ld	s2,0(sp)
    80004b46:	6105                	addi	sp,sp,32
    80004b48:	8082                	ret

0000000080004b4a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b4a:	1101                	addi	sp,sp,-32
    80004b4c:	ec06                	sd	ra,24(sp)
    80004b4e:	e822                	sd	s0,16(sp)
    80004b50:	e426                	sd	s1,8(sp)
    80004b52:	e04a                	sd	s2,0(sp)
    80004b54:	1000                	addi	s0,sp,32
    80004b56:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b58:	00850913          	addi	s2,a0,8
    80004b5c:	854a                	mv	a0,s2
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	086080e7          	jalr	134(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004b66:	409c                	lw	a5,0(s1)
    80004b68:	cb89                	beqz	a5,80004b7a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b6a:	85ca                	mv	a1,s2
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	ffffe097          	auipc	ra,0xffffe
    80004b72:	b60080e7          	jalr	-1184(ra) # 800026ce <sleep>
  while (lk->locked) {
    80004b76:	409c                	lw	a5,0(s1)
    80004b78:	fbed                	bnez	a5,80004b6a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b7a:	4785                	li	a5,1
    80004b7c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	276080e7          	jalr	630(ra) # 80001df4 <myproc>
    80004b86:	591c                	lw	a5,48(a0)
    80004b88:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b8a:	854a                	mv	a0,s2
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	11e080e7          	jalr	286(ra) # 80000caa <release>
}
    80004b94:	60e2                	ld	ra,24(sp)
    80004b96:	6442                	ld	s0,16(sp)
    80004b98:	64a2                	ld	s1,8(sp)
    80004b9a:	6902                	ld	s2,0(sp)
    80004b9c:	6105                	addi	sp,sp,32
    80004b9e:	8082                	ret

0000000080004ba0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ba0:	1101                	addi	sp,sp,-32
    80004ba2:	ec06                	sd	ra,24(sp)
    80004ba4:	e822                	sd	s0,16(sp)
    80004ba6:	e426                	sd	s1,8(sp)
    80004ba8:	e04a                	sd	s2,0(sp)
    80004baa:	1000                	addi	s0,sp,32
    80004bac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bae:	00850913          	addi	s2,a0,8
    80004bb2:	854a                	mv	a0,s2
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	030080e7          	jalr	48(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004bbc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bc0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffe097          	auipc	ra,0xffffe
    80004bca:	cb0080e7          	jalr	-848(ra) # 80002876 <wakeup>
  release(&lk->lk);
    80004bce:	854a                	mv	a0,s2
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0da080e7          	jalr	218(ra) # 80000caa <release>
}
    80004bd8:	60e2                	ld	ra,24(sp)
    80004bda:	6442                	ld	s0,16(sp)
    80004bdc:	64a2                	ld	s1,8(sp)
    80004bde:	6902                	ld	s2,0(sp)
    80004be0:	6105                	addi	sp,sp,32
    80004be2:	8082                	ret

0000000080004be4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004be4:	7179                	addi	sp,sp,-48
    80004be6:	f406                	sd	ra,40(sp)
    80004be8:	f022                	sd	s0,32(sp)
    80004bea:	ec26                	sd	s1,24(sp)
    80004bec:	e84a                	sd	s2,16(sp)
    80004bee:	e44e                	sd	s3,8(sp)
    80004bf0:	1800                	addi	s0,sp,48
    80004bf2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bf4:	00850913          	addi	s2,a0,8
    80004bf8:	854a                	mv	a0,s2
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	fea080e7          	jalr	-22(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c02:	409c                	lw	a5,0(s1)
    80004c04:	ef99                	bnez	a5,80004c22 <holdingsleep+0x3e>
    80004c06:	4481                	li	s1,0
  release(&lk->lk);
    80004c08:	854a                	mv	a0,s2
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	0a0080e7          	jalr	160(ra) # 80000caa <release>
  return r;
}
    80004c12:	8526                	mv	a0,s1
    80004c14:	70a2                	ld	ra,40(sp)
    80004c16:	7402                	ld	s0,32(sp)
    80004c18:	64e2                	ld	s1,24(sp)
    80004c1a:	6942                	ld	s2,16(sp)
    80004c1c:	69a2                	ld	s3,8(sp)
    80004c1e:	6145                	addi	sp,sp,48
    80004c20:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c22:	0284a983          	lw	s3,40(s1)
    80004c26:	ffffd097          	auipc	ra,0xffffd
    80004c2a:	1ce080e7          	jalr	462(ra) # 80001df4 <myproc>
    80004c2e:	5904                	lw	s1,48(a0)
    80004c30:	413484b3          	sub	s1,s1,s3
    80004c34:	0014b493          	seqz	s1,s1
    80004c38:	bfc1                	j	80004c08 <holdingsleep+0x24>

0000000080004c3a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c3a:	1141                	addi	sp,sp,-16
    80004c3c:	e406                	sd	ra,8(sp)
    80004c3e:	e022                	sd	s0,0(sp)
    80004c40:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c42:	00004597          	auipc	a1,0x4
    80004c46:	aee58593          	addi	a1,a1,-1298 # 80008730 <syscalls+0x250>
    80004c4a:	0001d517          	auipc	a0,0x1d
    80004c4e:	11650513          	addi	a0,a0,278 # 80021d60 <ftable>
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	f02080e7          	jalr	-254(ra) # 80000b54 <initlock>
}
    80004c5a:	60a2                	ld	ra,8(sp)
    80004c5c:	6402                	ld	s0,0(sp)
    80004c5e:	0141                	addi	sp,sp,16
    80004c60:	8082                	ret

0000000080004c62 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c62:	1101                	addi	sp,sp,-32
    80004c64:	ec06                	sd	ra,24(sp)
    80004c66:	e822                	sd	s0,16(sp)
    80004c68:	e426                	sd	s1,8(sp)
    80004c6a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c6c:	0001d517          	auipc	a0,0x1d
    80004c70:	0f450513          	addi	a0,a0,244 # 80021d60 <ftable>
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	f70080e7          	jalr	-144(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c7c:	0001d497          	auipc	s1,0x1d
    80004c80:	0fc48493          	addi	s1,s1,252 # 80021d78 <ftable+0x18>
    80004c84:	0001e717          	auipc	a4,0x1e
    80004c88:	09470713          	addi	a4,a4,148 # 80022d18 <ftable+0xfb8>
    if(f->ref == 0){
    80004c8c:	40dc                	lw	a5,4(s1)
    80004c8e:	cf99                	beqz	a5,80004cac <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c90:	02848493          	addi	s1,s1,40
    80004c94:	fee49ce3          	bne	s1,a4,80004c8c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c98:	0001d517          	auipc	a0,0x1d
    80004c9c:	0c850513          	addi	a0,a0,200 # 80021d60 <ftable>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	00a080e7          	jalr	10(ra) # 80000caa <release>
  return 0;
    80004ca8:	4481                	li	s1,0
    80004caa:	a819                	j	80004cc0 <filealloc+0x5e>
      f->ref = 1;
    80004cac:	4785                	li	a5,1
    80004cae:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004cb0:	0001d517          	auipc	a0,0x1d
    80004cb4:	0b050513          	addi	a0,a0,176 # 80021d60 <ftable>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	ff2080e7          	jalr	-14(ra) # 80000caa <release>
}
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	60e2                	ld	ra,24(sp)
    80004cc4:	6442                	ld	s0,16(sp)
    80004cc6:	64a2                	ld	s1,8(sp)
    80004cc8:	6105                	addi	sp,sp,32
    80004cca:	8082                	ret

0000000080004ccc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ccc:	1101                	addi	sp,sp,-32
    80004cce:	ec06                	sd	ra,24(sp)
    80004cd0:	e822                	sd	s0,16(sp)
    80004cd2:	e426                	sd	s1,8(sp)
    80004cd4:	1000                	addi	s0,sp,32
    80004cd6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004cd8:	0001d517          	auipc	a0,0x1d
    80004cdc:	08850513          	addi	a0,a0,136 # 80021d60 <ftable>
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	f04080e7          	jalr	-252(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ce8:	40dc                	lw	a5,4(s1)
    80004cea:	02f05263          	blez	a5,80004d0e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cee:	2785                	addiw	a5,a5,1
    80004cf0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cf2:	0001d517          	auipc	a0,0x1d
    80004cf6:	06e50513          	addi	a0,a0,110 # 80021d60 <ftable>
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	fb0080e7          	jalr	-80(ra) # 80000caa <release>
  return f;
}
    80004d02:	8526                	mv	a0,s1
    80004d04:	60e2                	ld	ra,24(sp)
    80004d06:	6442                	ld	s0,16(sp)
    80004d08:	64a2                	ld	s1,8(sp)
    80004d0a:	6105                	addi	sp,sp,32
    80004d0c:	8082                	ret
    panic("filedup");
    80004d0e:	00004517          	auipc	a0,0x4
    80004d12:	a2a50513          	addi	a0,a0,-1494 # 80008738 <syscalls+0x258>
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	828080e7          	jalr	-2008(ra) # 8000053e <panic>

0000000080004d1e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d1e:	7139                	addi	sp,sp,-64
    80004d20:	fc06                	sd	ra,56(sp)
    80004d22:	f822                	sd	s0,48(sp)
    80004d24:	f426                	sd	s1,40(sp)
    80004d26:	f04a                	sd	s2,32(sp)
    80004d28:	ec4e                	sd	s3,24(sp)
    80004d2a:	e852                	sd	s4,16(sp)
    80004d2c:	e456                	sd	s5,8(sp)
    80004d2e:	0080                	addi	s0,sp,64
    80004d30:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d32:	0001d517          	auipc	a0,0x1d
    80004d36:	02e50513          	addi	a0,a0,46 # 80021d60 <ftable>
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	eaa080e7          	jalr	-342(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d42:	40dc                	lw	a5,4(s1)
    80004d44:	06f05163          	blez	a5,80004da6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d48:	37fd                	addiw	a5,a5,-1
    80004d4a:	0007871b          	sext.w	a4,a5
    80004d4e:	c0dc                	sw	a5,4(s1)
    80004d50:	06e04363          	bgtz	a4,80004db6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d54:	0004a903          	lw	s2,0(s1)
    80004d58:	0094ca83          	lbu	s5,9(s1)
    80004d5c:	0104ba03          	ld	s4,16(s1)
    80004d60:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d64:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d68:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d6c:	0001d517          	auipc	a0,0x1d
    80004d70:	ff450513          	addi	a0,a0,-12 # 80021d60 <ftable>
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f36080e7          	jalr	-202(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004d7c:	4785                	li	a5,1
    80004d7e:	04f90d63          	beq	s2,a5,80004dd8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d82:	3979                	addiw	s2,s2,-2
    80004d84:	4785                	li	a5,1
    80004d86:	0527e063          	bltu	a5,s2,80004dc6 <fileclose+0xa8>
    begin_op();
    80004d8a:	00000097          	auipc	ra,0x0
    80004d8e:	ac8080e7          	jalr	-1336(ra) # 80004852 <begin_op>
    iput(ff.ip);
    80004d92:	854e                	mv	a0,s3
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	2a6080e7          	jalr	678(ra) # 8000403a <iput>
    end_op();
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	b36080e7          	jalr	-1226(ra) # 800048d2 <end_op>
    80004da4:	a00d                	j	80004dc6 <fileclose+0xa8>
    panic("fileclose");
    80004da6:	00004517          	auipc	a0,0x4
    80004daa:	99a50513          	addi	a0,a0,-1638 # 80008740 <syscalls+0x260>
    80004dae:	ffffb097          	auipc	ra,0xffffb
    80004db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004db6:	0001d517          	auipc	a0,0x1d
    80004dba:	faa50513          	addi	a0,a0,-86 # 80021d60 <ftable>
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	eec080e7          	jalr	-276(ra) # 80000caa <release>
  }
}
    80004dc6:	70e2                	ld	ra,56(sp)
    80004dc8:	7442                	ld	s0,48(sp)
    80004dca:	74a2                	ld	s1,40(sp)
    80004dcc:	7902                	ld	s2,32(sp)
    80004dce:	69e2                	ld	s3,24(sp)
    80004dd0:	6a42                	ld	s4,16(sp)
    80004dd2:	6aa2                	ld	s5,8(sp)
    80004dd4:	6121                	addi	sp,sp,64
    80004dd6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004dd8:	85d6                	mv	a1,s5
    80004dda:	8552                	mv	a0,s4
    80004ddc:	00000097          	auipc	ra,0x0
    80004de0:	34c080e7          	jalr	844(ra) # 80005128 <pipeclose>
    80004de4:	b7cd                	j	80004dc6 <fileclose+0xa8>

0000000080004de6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004de6:	715d                	addi	sp,sp,-80
    80004de8:	e486                	sd	ra,72(sp)
    80004dea:	e0a2                	sd	s0,64(sp)
    80004dec:	fc26                	sd	s1,56(sp)
    80004dee:	f84a                	sd	s2,48(sp)
    80004df0:	f44e                	sd	s3,40(sp)
    80004df2:	0880                	addi	s0,sp,80
    80004df4:	84aa                	mv	s1,a0
    80004df6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	ffc080e7          	jalr	-4(ra) # 80001df4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e00:	409c                	lw	a5,0(s1)
    80004e02:	37f9                	addiw	a5,a5,-2
    80004e04:	4705                	li	a4,1
    80004e06:	04f76763          	bltu	a4,a5,80004e54 <filestat+0x6e>
    80004e0a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e0c:	6c88                	ld	a0,24(s1)
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	072080e7          	jalr	114(ra) # 80003e80 <ilock>
    stati(f->ip, &st);
    80004e16:	fb840593          	addi	a1,s0,-72
    80004e1a:	6c88                	ld	a0,24(s1)
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	2ee080e7          	jalr	750(ra) # 8000410a <stati>
    iunlock(f->ip);
    80004e24:	6c88                	ld	a0,24(s1)
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	11c080e7          	jalr	284(ra) # 80003f42 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e2e:	46e1                	li	a3,24
    80004e30:	fb840613          	addi	a2,s0,-72
    80004e34:	85ce                	mv	a1,s3
    80004e36:	07093503          	ld	a0,112(s2)
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	85c080e7          	jalr	-1956(ra) # 80001696 <copyout>
    80004e42:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e46:	60a6                	ld	ra,72(sp)
    80004e48:	6406                	ld	s0,64(sp)
    80004e4a:	74e2                	ld	s1,56(sp)
    80004e4c:	7942                	ld	s2,48(sp)
    80004e4e:	79a2                	ld	s3,40(sp)
    80004e50:	6161                	addi	sp,sp,80
    80004e52:	8082                	ret
  return -1;
    80004e54:	557d                	li	a0,-1
    80004e56:	bfc5                	j	80004e46 <filestat+0x60>

0000000080004e58 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e58:	7179                	addi	sp,sp,-48
    80004e5a:	f406                	sd	ra,40(sp)
    80004e5c:	f022                	sd	s0,32(sp)
    80004e5e:	ec26                	sd	s1,24(sp)
    80004e60:	e84a                	sd	s2,16(sp)
    80004e62:	e44e                	sd	s3,8(sp)
    80004e64:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e66:	00854783          	lbu	a5,8(a0)
    80004e6a:	c3d5                	beqz	a5,80004f0e <fileread+0xb6>
    80004e6c:	84aa                	mv	s1,a0
    80004e6e:	89ae                	mv	s3,a1
    80004e70:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e72:	411c                	lw	a5,0(a0)
    80004e74:	4705                	li	a4,1
    80004e76:	04e78963          	beq	a5,a4,80004ec8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e7a:	470d                	li	a4,3
    80004e7c:	04e78d63          	beq	a5,a4,80004ed6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e80:	4709                	li	a4,2
    80004e82:	06e79e63          	bne	a5,a4,80004efe <fileread+0xa6>
    ilock(f->ip);
    80004e86:	6d08                	ld	a0,24(a0)
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	ff8080e7          	jalr	-8(ra) # 80003e80 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e90:	874a                	mv	a4,s2
    80004e92:	5094                	lw	a3,32(s1)
    80004e94:	864e                	mv	a2,s3
    80004e96:	4585                	li	a1,1
    80004e98:	6c88                	ld	a0,24(s1)
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	29a080e7          	jalr	666(ra) # 80004134 <readi>
    80004ea2:	892a                	mv	s2,a0
    80004ea4:	00a05563          	blez	a0,80004eae <fileread+0x56>
      f->off += r;
    80004ea8:	509c                	lw	a5,32(s1)
    80004eaa:	9fa9                	addw	a5,a5,a0
    80004eac:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004eae:	6c88                	ld	a0,24(s1)
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	092080e7          	jalr	146(ra) # 80003f42 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004eb8:	854a                	mv	a0,s2
    80004eba:	70a2                	ld	ra,40(sp)
    80004ebc:	7402                	ld	s0,32(sp)
    80004ebe:	64e2                	ld	s1,24(sp)
    80004ec0:	6942                	ld	s2,16(sp)
    80004ec2:	69a2                	ld	s3,8(sp)
    80004ec4:	6145                	addi	sp,sp,48
    80004ec6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ec8:	6908                	ld	a0,16(a0)
    80004eca:	00000097          	auipc	ra,0x0
    80004ece:	3c8080e7          	jalr	968(ra) # 80005292 <piperead>
    80004ed2:	892a                	mv	s2,a0
    80004ed4:	b7d5                	j	80004eb8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ed6:	02451783          	lh	a5,36(a0)
    80004eda:	03079693          	slli	a3,a5,0x30
    80004ede:	92c1                	srli	a3,a3,0x30
    80004ee0:	4725                	li	a4,9
    80004ee2:	02d76863          	bltu	a4,a3,80004f12 <fileread+0xba>
    80004ee6:	0792                	slli	a5,a5,0x4
    80004ee8:	0001d717          	auipc	a4,0x1d
    80004eec:	dd870713          	addi	a4,a4,-552 # 80021cc0 <devsw>
    80004ef0:	97ba                	add	a5,a5,a4
    80004ef2:	639c                	ld	a5,0(a5)
    80004ef4:	c38d                	beqz	a5,80004f16 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ef6:	4505                	li	a0,1
    80004ef8:	9782                	jalr	a5
    80004efa:	892a                	mv	s2,a0
    80004efc:	bf75                	j	80004eb8 <fileread+0x60>
    panic("fileread");
    80004efe:	00004517          	auipc	a0,0x4
    80004f02:	85250513          	addi	a0,a0,-1966 # 80008750 <syscalls+0x270>
    80004f06:	ffffb097          	auipc	ra,0xffffb
    80004f0a:	638080e7          	jalr	1592(ra) # 8000053e <panic>
    return -1;
    80004f0e:	597d                	li	s2,-1
    80004f10:	b765                	j	80004eb8 <fileread+0x60>
      return -1;
    80004f12:	597d                	li	s2,-1
    80004f14:	b755                	j	80004eb8 <fileread+0x60>
    80004f16:	597d                	li	s2,-1
    80004f18:	b745                	j	80004eb8 <fileread+0x60>

0000000080004f1a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f1a:	715d                	addi	sp,sp,-80
    80004f1c:	e486                	sd	ra,72(sp)
    80004f1e:	e0a2                	sd	s0,64(sp)
    80004f20:	fc26                	sd	s1,56(sp)
    80004f22:	f84a                	sd	s2,48(sp)
    80004f24:	f44e                	sd	s3,40(sp)
    80004f26:	f052                	sd	s4,32(sp)
    80004f28:	ec56                	sd	s5,24(sp)
    80004f2a:	e85a                	sd	s6,16(sp)
    80004f2c:	e45e                	sd	s7,8(sp)
    80004f2e:	e062                	sd	s8,0(sp)
    80004f30:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f32:	00954783          	lbu	a5,9(a0)
    80004f36:	10078663          	beqz	a5,80005042 <filewrite+0x128>
    80004f3a:	892a                	mv	s2,a0
    80004f3c:	8aae                	mv	s5,a1
    80004f3e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f40:	411c                	lw	a5,0(a0)
    80004f42:	4705                	li	a4,1
    80004f44:	02e78263          	beq	a5,a4,80004f68 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f48:	470d                	li	a4,3
    80004f4a:	02e78663          	beq	a5,a4,80004f76 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f4e:	4709                	li	a4,2
    80004f50:	0ee79163          	bne	a5,a4,80005032 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f54:	0ac05d63          	blez	a2,8000500e <filewrite+0xf4>
    int i = 0;
    80004f58:	4981                	li	s3,0
    80004f5a:	6b05                	lui	s6,0x1
    80004f5c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f60:	6b85                	lui	s7,0x1
    80004f62:	c00b8b9b          	addiw	s7,s7,-1024
    80004f66:	a861                	j	80004ffe <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f68:	6908                	ld	a0,16(a0)
    80004f6a:	00000097          	auipc	ra,0x0
    80004f6e:	22e080e7          	jalr	558(ra) # 80005198 <pipewrite>
    80004f72:	8a2a                	mv	s4,a0
    80004f74:	a045                	j	80005014 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f76:	02451783          	lh	a5,36(a0)
    80004f7a:	03079693          	slli	a3,a5,0x30
    80004f7e:	92c1                	srli	a3,a3,0x30
    80004f80:	4725                	li	a4,9
    80004f82:	0cd76263          	bltu	a4,a3,80005046 <filewrite+0x12c>
    80004f86:	0792                	slli	a5,a5,0x4
    80004f88:	0001d717          	auipc	a4,0x1d
    80004f8c:	d3870713          	addi	a4,a4,-712 # 80021cc0 <devsw>
    80004f90:	97ba                	add	a5,a5,a4
    80004f92:	679c                	ld	a5,8(a5)
    80004f94:	cbdd                	beqz	a5,8000504a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f96:	4505                	li	a0,1
    80004f98:	9782                	jalr	a5
    80004f9a:	8a2a                	mv	s4,a0
    80004f9c:	a8a5                	j	80005014 <filewrite+0xfa>
    80004f9e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fa2:	00000097          	auipc	ra,0x0
    80004fa6:	8b0080e7          	jalr	-1872(ra) # 80004852 <begin_op>
      ilock(f->ip);
    80004faa:	01893503          	ld	a0,24(s2)
    80004fae:	fffff097          	auipc	ra,0xfffff
    80004fb2:	ed2080e7          	jalr	-302(ra) # 80003e80 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004fb6:	8762                	mv	a4,s8
    80004fb8:	02092683          	lw	a3,32(s2)
    80004fbc:	01598633          	add	a2,s3,s5
    80004fc0:	4585                	li	a1,1
    80004fc2:	01893503          	ld	a0,24(s2)
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	266080e7          	jalr	614(ra) # 8000422c <writei>
    80004fce:	84aa                	mv	s1,a0
    80004fd0:	00a05763          	blez	a0,80004fde <filewrite+0xc4>
        f->off += r;
    80004fd4:	02092783          	lw	a5,32(s2)
    80004fd8:	9fa9                	addw	a5,a5,a0
    80004fda:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004fde:	01893503          	ld	a0,24(s2)
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	f60080e7          	jalr	-160(ra) # 80003f42 <iunlock>
      end_op();
    80004fea:	00000097          	auipc	ra,0x0
    80004fee:	8e8080e7          	jalr	-1816(ra) # 800048d2 <end_op>

      if(r != n1){
    80004ff2:	009c1f63          	bne	s8,s1,80005010 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ff6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ffa:	0149db63          	bge	s3,s4,80005010 <filewrite+0xf6>
      int n1 = n - i;
    80004ffe:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005002:	84be                	mv	s1,a5
    80005004:	2781                	sext.w	a5,a5
    80005006:	f8fb5ce3          	bge	s6,a5,80004f9e <filewrite+0x84>
    8000500a:	84de                	mv	s1,s7
    8000500c:	bf49                	j	80004f9e <filewrite+0x84>
    int i = 0;
    8000500e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005010:	013a1f63          	bne	s4,s3,8000502e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005014:	8552                	mv	a0,s4
    80005016:	60a6                	ld	ra,72(sp)
    80005018:	6406                	ld	s0,64(sp)
    8000501a:	74e2                	ld	s1,56(sp)
    8000501c:	7942                	ld	s2,48(sp)
    8000501e:	79a2                	ld	s3,40(sp)
    80005020:	7a02                	ld	s4,32(sp)
    80005022:	6ae2                	ld	s5,24(sp)
    80005024:	6b42                	ld	s6,16(sp)
    80005026:	6ba2                	ld	s7,8(sp)
    80005028:	6c02                	ld	s8,0(sp)
    8000502a:	6161                	addi	sp,sp,80
    8000502c:	8082                	ret
    ret = (i == n ? n : -1);
    8000502e:	5a7d                	li	s4,-1
    80005030:	b7d5                	j	80005014 <filewrite+0xfa>
    panic("filewrite");
    80005032:	00003517          	auipc	a0,0x3
    80005036:	72e50513          	addi	a0,a0,1838 # 80008760 <syscalls+0x280>
    8000503a:	ffffb097          	auipc	ra,0xffffb
    8000503e:	504080e7          	jalr	1284(ra) # 8000053e <panic>
    return -1;
    80005042:	5a7d                	li	s4,-1
    80005044:	bfc1                	j	80005014 <filewrite+0xfa>
      return -1;
    80005046:	5a7d                	li	s4,-1
    80005048:	b7f1                	j	80005014 <filewrite+0xfa>
    8000504a:	5a7d                	li	s4,-1
    8000504c:	b7e1                	j	80005014 <filewrite+0xfa>

000000008000504e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000504e:	7179                	addi	sp,sp,-48
    80005050:	f406                	sd	ra,40(sp)
    80005052:	f022                	sd	s0,32(sp)
    80005054:	ec26                	sd	s1,24(sp)
    80005056:	e84a                	sd	s2,16(sp)
    80005058:	e44e                	sd	s3,8(sp)
    8000505a:	e052                	sd	s4,0(sp)
    8000505c:	1800                	addi	s0,sp,48
    8000505e:	84aa                	mv	s1,a0
    80005060:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005062:	0005b023          	sd	zero,0(a1)
    80005066:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000506a:	00000097          	auipc	ra,0x0
    8000506e:	bf8080e7          	jalr	-1032(ra) # 80004c62 <filealloc>
    80005072:	e088                	sd	a0,0(s1)
    80005074:	c551                	beqz	a0,80005100 <pipealloc+0xb2>
    80005076:	00000097          	auipc	ra,0x0
    8000507a:	bec080e7          	jalr	-1044(ra) # 80004c62 <filealloc>
    8000507e:	00aa3023          	sd	a0,0(s4)
    80005082:	c92d                	beqz	a0,800050f4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	a70080e7          	jalr	-1424(ra) # 80000af4 <kalloc>
    8000508c:	892a                	mv	s2,a0
    8000508e:	c125                	beqz	a0,800050ee <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005090:	4985                	li	s3,1
    80005092:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005096:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000509a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000509e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050a2:	00003597          	auipc	a1,0x3
    800050a6:	6ce58593          	addi	a1,a1,1742 # 80008770 <syscalls+0x290>
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	aaa080e7          	jalr	-1366(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800050b2:	609c                	ld	a5,0(s1)
    800050b4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050b8:	609c                	ld	a5,0(s1)
    800050ba:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050be:	609c                	ld	a5,0(s1)
    800050c0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800050c4:	609c                	ld	a5,0(s1)
    800050c6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800050ca:	000a3783          	ld	a5,0(s4)
    800050ce:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050d2:	000a3783          	ld	a5,0(s4)
    800050d6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050da:	000a3783          	ld	a5,0(s4)
    800050de:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050e2:	000a3783          	ld	a5,0(s4)
    800050e6:	0127b823          	sd	s2,16(a5)
  return 0;
    800050ea:	4501                	li	a0,0
    800050ec:	a025                	j	80005114 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050ee:	6088                	ld	a0,0(s1)
    800050f0:	e501                	bnez	a0,800050f8 <pipealloc+0xaa>
    800050f2:	a039                	j	80005100 <pipealloc+0xb2>
    800050f4:	6088                	ld	a0,0(s1)
    800050f6:	c51d                	beqz	a0,80005124 <pipealloc+0xd6>
    fileclose(*f0);
    800050f8:	00000097          	auipc	ra,0x0
    800050fc:	c26080e7          	jalr	-986(ra) # 80004d1e <fileclose>
  if(*f1)
    80005100:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005104:	557d                	li	a0,-1
  if(*f1)
    80005106:	c799                	beqz	a5,80005114 <pipealloc+0xc6>
    fileclose(*f1);
    80005108:	853e                	mv	a0,a5
    8000510a:	00000097          	auipc	ra,0x0
    8000510e:	c14080e7          	jalr	-1004(ra) # 80004d1e <fileclose>
  return -1;
    80005112:	557d                	li	a0,-1
}
    80005114:	70a2                	ld	ra,40(sp)
    80005116:	7402                	ld	s0,32(sp)
    80005118:	64e2                	ld	s1,24(sp)
    8000511a:	6942                	ld	s2,16(sp)
    8000511c:	69a2                	ld	s3,8(sp)
    8000511e:	6a02                	ld	s4,0(sp)
    80005120:	6145                	addi	sp,sp,48
    80005122:	8082                	ret
  return -1;
    80005124:	557d                	li	a0,-1
    80005126:	b7fd                	j	80005114 <pipealloc+0xc6>

0000000080005128 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005128:	1101                	addi	sp,sp,-32
    8000512a:	ec06                	sd	ra,24(sp)
    8000512c:	e822                	sd	s0,16(sp)
    8000512e:	e426                	sd	s1,8(sp)
    80005130:	e04a                	sd	s2,0(sp)
    80005132:	1000                	addi	s0,sp,32
    80005134:	84aa                	mv	s1,a0
    80005136:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	aac080e7          	jalr	-1364(ra) # 80000be4 <acquire>
  if(writable){
    80005140:	02090d63          	beqz	s2,8000517a <pipeclose+0x52>
    pi->writeopen = 0;
    80005144:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005148:	21848513          	addi	a0,s1,536
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	72a080e7          	jalr	1834(ra) # 80002876 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005154:	2204b783          	ld	a5,544(s1)
    80005158:	eb95                	bnez	a5,8000518c <pipeclose+0x64>
    release(&pi->lock);
    8000515a:	8526                	mv	a0,s1
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	b4e080e7          	jalr	-1202(ra) # 80000caa <release>
    kfree((char*)pi);
    80005164:	8526                	mv	a0,s1
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	892080e7          	jalr	-1902(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000516e:	60e2                	ld	ra,24(sp)
    80005170:	6442                	ld	s0,16(sp)
    80005172:	64a2                	ld	s1,8(sp)
    80005174:	6902                	ld	s2,0(sp)
    80005176:	6105                	addi	sp,sp,32
    80005178:	8082                	ret
    pi->readopen = 0;
    8000517a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000517e:	21c48513          	addi	a0,s1,540
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	6f4080e7          	jalr	1780(ra) # 80002876 <wakeup>
    8000518a:	b7e9                	j	80005154 <pipeclose+0x2c>
    release(&pi->lock);
    8000518c:	8526                	mv	a0,s1
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	b1c080e7          	jalr	-1252(ra) # 80000caa <release>
}
    80005196:	bfe1                	j	8000516e <pipeclose+0x46>

0000000080005198 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005198:	7159                	addi	sp,sp,-112
    8000519a:	f486                	sd	ra,104(sp)
    8000519c:	f0a2                	sd	s0,96(sp)
    8000519e:	eca6                	sd	s1,88(sp)
    800051a0:	e8ca                	sd	s2,80(sp)
    800051a2:	e4ce                	sd	s3,72(sp)
    800051a4:	e0d2                	sd	s4,64(sp)
    800051a6:	fc56                	sd	s5,56(sp)
    800051a8:	f85a                	sd	s6,48(sp)
    800051aa:	f45e                	sd	s7,40(sp)
    800051ac:	f062                	sd	s8,32(sp)
    800051ae:	ec66                	sd	s9,24(sp)
    800051b0:	1880                	addi	s0,sp,112
    800051b2:	84aa                	mv	s1,a0
    800051b4:	8aae                	mv	s5,a1
    800051b6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051b8:	ffffd097          	auipc	ra,0xffffd
    800051bc:	c3c080e7          	jalr	-964(ra) # 80001df4 <myproc>
    800051c0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800051c2:	8526                	mv	a0,s1
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	a20080e7          	jalr	-1504(ra) # 80000be4 <acquire>
  while(i < n){
    800051cc:	0d405163          	blez	s4,8000528e <pipewrite+0xf6>
    800051d0:	8ba6                	mv	s7,s1
  int i = 0;
    800051d2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051d4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051d6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800051da:	21c48c13          	addi	s8,s1,540
    800051de:	a08d                	j	80005240 <pipewrite+0xa8>
      release(&pi->lock);
    800051e0:	8526                	mv	a0,s1
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	ac8080e7          	jalr	-1336(ra) # 80000caa <release>
      return -1;
    800051ea:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051ec:	854a                	mv	a0,s2
    800051ee:	70a6                	ld	ra,104(sp)
    800051f0:	7406                	ld	s0,96(sp)
    800051f2:	64e6                	ld	s1,88(sp)
    800051f4:	6946                	ld	s2,80(sp)
    800051f6:	69a6                	ld	s3,72(sp)
    800051f8:	6a06                	ld	s4,64(sp)
    800051fa:	7ae2                	ld	s5,56(sp)
    800051fc:	7b42                	ld	s6,48(sp)
    800051fe:	7ba2                	ld	s7,40(sp)
    80005200:	7c02                	ld	s8,32(sp)
    80005202:	6ce2                	ld	s9,24(sp)
    80005204:	6165                	addi	sp,sp,112
    80005206:	8082                	ret
      wakeup(&pi->nread);
    80005208:	8566                	mv	a0,s9
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	66c080e7          	jalr	1644(ra) # 80002876 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005212:	85de                	mv	a1,s7
    80005214:	8562                	mv	a0,s8
    80005216:	ffffd097          	auipc	ra,0xffffd
    8000521a:	4b8080e7          	jalr	1208(ra) # 800026ce <sleep>
    8000521e:	a839                	j	8000523c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005220:	21c4a783          	lw	a5,540(s1)
    80005224:	0017871b          	addiw	a4,a5,1
    80005228:	20e4ae23          	sw	a4,540(s1)
    8000522c:	1ff7f793          	andi	a5,a5,511
    80005230:	97a6                	add	a5,a5,s1
    80005232:	f9f44703          	lbu	a4,-97(s0)
    80005236:	00e78c23          	sb	a4,24(a5)
      i++;
    8000523a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000523c:	03495d63          	bge	s2,s4,80005276 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005240:	2204a783          	lw	a5,544(s1)
    80005244:	dfd1                	beqz	a5,800051e0 <pipewrite+0x48>
    80005246:	0289a783          	lw	a5,40(s3)
    8000524a:	fbd9                	bnez	a5,800051e0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000524c:	2184a783          	lw	a5,536(s1)
    80005250:	21c4a703          	lw	a4,540(s1)
    80005254:	2007879b          	addiw	a5,a5,512
    80005258:	faf708e3          	beq	a4,a5,80005208 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000525c:	4685                	li	a3,1
    8000525e:	01590633          	add	a2,s2,s5
    80005262:	f9f40593          	addi	a1,s0,-97
    80005266:	0709b503          	ld	a0,112(s3)
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	4b8080e7          	jalr	1208(ra) # 80001722 <copyin>
    80005272:	fb6517e3          	bne	a0,s6,80005220 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005276:	21848513          	addi	a0,s1,536
    8000527a:	ffffd097          	auipc	ra,0xffffd
    8000527e:	5fc080e7          	jalr	1532(ra) # 80002876 <wakeup>
  release(&pi->lock);
    80005282:	8526                	mv	a0,s1
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	a26080e7          	jalr	-1498(ra) # 80000caa <release>
  return i;
    8000528c:	b785                	j	800051ec <pipewrite+0x54>
  int i = 0;
    8000528e:	4901                	li	s2,0
    80005290:	b7dd                	j	80005276 <pipewrite+0xde>

0000000080005292 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005292:	715d                	addi	sp,sp,-80
    80005294:	e486                	sd	ra,72(sp)
    80005296:	e0a2                	sd	s0,64(sp)
    80005298:	fc26                	sd	s1,56(sp)
    8000529a:	f84a                	sd	s2,48(sp)
    8000529c:	f44e                	sd	s3,40(sp)
    8000529e:	f052                	sd	s4,32(sp)
    800052a0:	ec56                	sd	s5,24(sp)
    800052a2:	e85a                	sd	s6,16(sp)
    800052a4:	0880                	addi	s0,sp,80
    800052a6:	84aa                	mv	s1,a0
    800052a8:	892e                	mv	s2,a1
    800052aa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052ac:	ffffd097          	auipc	ra,0xffffd
    800052b0:	b48080e7          	jalr	-1208(ra) # 80001df4 <myproc>
    800052b4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052b6:	8b26                	mv	s6,s1
    800052b8:	8526                	mv	a0,s1
    800052ba:	ffffc097          	auipc	ra,0xffffc
    800052be:	92a080e7          	jalr	-1750(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052c2:	2184a703          	lw	a4,536(s1)
    800052c6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052ca:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052ce:	02f71463          	bne	a4,a5,800052f6 <piperead+0x64>
    800052d2:	2244a783          	lw	a5,548(s1)
    800052d6:	c385                	beqz	a5,800052f6 <piperead+0x64>
    if(pr->killed){
    800052d8:	028a2783          	lw	a5,40(s4)
    800052dc:	ebc1                	bnez	a5,8000536c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052de:	85da                	mv	a1,s6
    800052e0:	854e                	mv	a0,s3
    800052e2:	ffffd097          	auipc	ra,0xffffd
    800052e6:	3ec080e7          	jalr	1004(ra) # 800026ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052ea:	2184a703          	lw	a4,536(s1)
    800052ee:	21c4a783          	lw	a5,540(s1)
    800052f2:	fef700e3          	beq	a4,a5,800052d2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052f6:	09505263          	blez	s5,8000537a <piperead+0xe8>
    800052fa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052fc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052fe:	2184a783          	lw	a5,536(s1)
    80005302:	21c4a703          	lw	a4,540(s1)
    80005306:	02f70d63          	beq	a4,a5,80005340 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000530a:	0017871b          	addiw	a4,a5,1
    8000530e:	20e4ac23          	sw	a4,536(s1)
    80005312:	1ff7f793          	andi	a5,a5,511
    80005316:	97a6                	add	a5,a5,s1
    80005318:	0187c783          	lbu	a5,24(a5)
    8000531c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005320:	4685                	li	a3,1
    80005322:	fbf40613          	addi	a2,s0,-65
    80005326:	85ca                	mv	a1,s2
    80005328:	070a3503          	ld	a0,112(s4)
    8000532c:	ffffc097          	auipc	ra,0xffffc
    80005330:	36a080e7          	jalr	874(ra) # 80001696 <copyout>
    80005334:	01650663          	beq	a0,s6,80005340 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005338:	2985                	addiw	s3,s3,1
    8000533a:	0905                	addi	s2,s2,1
    8000533c:	fd3a91e3          	bne	s5,s3,800052fe <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005340:	21c48513          	addi	a0,s1,540
    80005344:	ffffd097          	auipc	ra,0xffffd
    80005348:	532080e7          	jalr	1330(ra) # 80002876 <wakeup>
  release(&pi->lock);
    8000534c:	8526                	mv	a0,s1
    8000534e:	ffffc097          	auipc	ra,0xffffc
    80005352:	95c080e7          	jalr	-1700(ra) # 80000caa <release>
  return i;
}
    80005356:	854e                	mv	a0,s3
    80005358:	60a6                	ld	ra,72(sp)
    8000535a:	6406                	ld	s0,64(sp)
    8000535c:	74e2                	ld	s1,56(sp)
    8000535e:	7942                	ld	s2,48(sp)
    80005360:	79a2                	ld	s3,40(sp)
    80005362:	7a02                	ld	s4,32(sp)
    80005364:	6ae2                	ld	s5,24(sp)
    80005366:	6b42                	ld	s6,16(sp)
    80005368:	6161                	addi	sp,sp,80
    8000536a:	8082                	ret
      release(&pi->lock);
    8000536c:	8526                	mv	a0,s1
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	93c080e7          	jalr	-1732(ra) # 80000caa <release>
      return -1;
    80005376:	59fd                	li	s3,-1
    80005378:	bff9                	j	80005356 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000537a:	4981                	li	s3,0
    8000537c:	b7d1                	j	80005340 <piperead+0xae>

000000008000537e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000537e:	df010113          	addi	sp,sp,-528
    80005382:	20113423          	sd	ra,520(sp)
    80005386:	20813023          	sd	s0,512(sp)
    8000538a:	ffa6                	sd	s1,504(sp)
    8000538c:	fbca                	sd	s2,496(sp)
    8000538e:	f7ce                	sd	s3,488(sp)
    80005390:	f3d2                	sd	s4,480(sp)
    80005392:	efd6                	sd	s5,472(sp)
    80005394:	ebda                	sd	s6,464(sp)
    80005396:	e7de                	sd	s7,456(sp)
    80005398:	e3e2                	sd	s8,448(sp)
    8000539a:	ff66                	sd	s9,440(sp)
    8000539c:	fb6a                	sd	s10,432(sp)
    8000539e:	f76e                	sd	s11,424(sp)
    800053a0:	0c00                	addi	s0,sp,528
    800053a2:	84aa                	mv	s1,a0
    800053a4:	dea43c23          	sd	a0,-520(s0)
    800053a8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053ac:	ffffd097          	auipc	ra,0xffffd
    800053b0:	a48080e7          	jalr	-1464(ra) # 80001df4 <myproc>
    800053b4:	892a                	mv	s2,a0

  begin_op();
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	49c080e7          	jalr	1180(ra) # 80004852 <begin_op>

  if((ip = namei(path)) == 0){
    800053be:	8526                	mv	a0,s1
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	276080e7          	jalr	630(ra) # 80004636 <namei>
    800053c8:	c92d                	beqz	a0,8000543a <exec+0xbc>
    800053ca:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	ab4080e7          	jalr	-1356(ra) # 80003e80 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800053d4:	04000713          	li	a4,64
    800053d8:	4681                	li	a3,0
    800053da:	e5040613          	addi	a2,s0,-432
    800053de:	4581                	li	a1,0
    800053e0:	8526                	mv	a0,s1
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	d52080e7          	jalr	-686(ra) # 80004134 <readi>
    800053ea:	04000793          	li	a5,64
    800053ee:	00f51a63          	bne	a0,a5,80005402 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800053f2:	e5042703          	lw	a4,-432(s0)
    800053f6:	464c47b7          	lui	a5,0x464c4
    800053fa:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053fe:	04f70463          	beq	a4,a5,80005446 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005402:	8526                	mv	a0,s1
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	cde080e7          	jalr	-802(ra) # 800040e2 <iunlockput>
    end_op();
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	4c6080e7          	jalr	1222(ra) # 800048d2 <end_op>
  }
  return -1;
    80005414:	557d                	li	a0,-1
}
    80005416:	20813083          	ld	ra,520(sp)
    8000541a:	20013403          	ld	s0,512(sp)
    8000541e:	74fe                	ld	s1,504(sp)
    80005420:	795e                	ld	s2,496(sp)
    80005422:	79be                	ld	s3,488(sp)
    80005424:	7a1e                	ld	s4,480(sp)
    80005426:	6afe                	ld	s5,472(sp)
    80005428:	6b5e                	ld	s6,464(sp)
    8000542a:	6bbe                	ld	s7,456(sp)
    8000542c:	6c1e                	ld	s8,448(sp)
    8000542e:	7cfa                	ld	s9,440(sp)
    80005430:	7d5a                	ld	s10,432(sp)
    80005432:	7dba                	ld	s11,424(sp)
    80005434:	21010113          	addi	sp,sp,528
    80005438:	8082                	ret
    end_op();
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	498080e7          	jalr	1176(ra) # 800048d2 <end_op>
    return -1;
    80005442:	557d                	li	a0,-1
    80005444:	bfc9                	j	80005416 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005446:	854a                	mv	a0,s2
    80005448:	ffffd097          	auipc	ra,0xffffd
    8000544c:	abc080e7          	jalr	-1348(ra) # 80001f04 <proc_pagetable>
    80005450:	8baa                	mv	s7,a0
    80005452:	d945                	beqz	a0,80005402 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005454:	e7042983          	lw	s3,-400(s0)
    80005458:	e8845783          	lhu	a5,-376(s0)
    8000545c:	c7ad                	beqz	a5,800054c6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000545e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005460:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005462:	6c85                	lui	s9,0x1
    80005464:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005468:	def43823          	sd	a5,-528(s0)
    8000546c:	a42d                	j	80005696 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000546e:	00003517          	auipc	a0,0x3
    80005472:	30a50513          	addi	a0,a0,778 # 80008778 <syscalls+0x298>
    80005476:	ffffb097          	auipc	ra,0xffffb
    8000547a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000547e:	8756                	mv	a4,s5
    80005480:	012d86bb          	addw	a3,s11,s2
    80005484:	4581                	li	a1,0
    80005486:	8526                	mv	a0,s1
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	cac080e7          	jalr	-852(ra) # 80004134 <readi>
    80005490:	2501                	sext.w	a0,a0
    80005492:	1aaa9963          	bne	s5,a0,80005644 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005496:	6785                	lui	a5,0x1
    80005498:	0127893b          	addw	s2,a5,s2
    8000549c:	77fd                	lui	a5,0xfffff
    8000549e:	01478a3b          	addw	s4,a5,s4
    800054a2:	1f897163          	bgeu	s2,s8,80005684 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800054a6:	02091593          	slli	a1,s2,0x20
    800054aa:	9181                	srli	a1,a1,0x20
    800054ac:	95ea                	add	a1,a1,s10
    800054ae:	855e                	mv	a0,s7
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	be2080e7          	jalr	-1054(ra) # 80001092 <walkaddr>
    800054b8:	862a                	mv	a2,a0
    if(pa == 0)
    800054ba:	d955                	beqz	a0,8000546e <exec+0xf0>
      n = PGSIZE;
    800054bc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800054be:	fd9a70e3          	bgeu	s4,s9,8000547e <exec+0x100>
      n = sz - i;
    800054c2:	8ad2                	mv	s5,s4
    800054c4:	bf6d                	j	8000547e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054c6:	4901                	li	s2,0
  iunlockput(ip);
    800054c8:	8526                	mv	a0,s1
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	c18080e7          	jalr	-1000(ra) # 800040e2 <iunlockput>
  end_op();
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	400080e7          	jalr	1024(ra) # 800048d2 <end_op>
  p = myproc();
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	91a080e7          	jalr	-1766(ra) # 80001df4 <myproc>
    800054e2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054e4:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800054e8:	6785                	lui	a5,0x1
    800054ea:	17fd                	addi	a5,a5,-1
    800054ec:	993e                	add	s2,s2,a5
    800054ee:	757d                	lui	a0,0xfffff
    800054f0:	00a977b3          	and	a5,s2,a0
    800054f4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054f8:	6609                	lui	a2,0x2
    800054fa:	963e                	add	a2,a2,a5
    800054fc:	85be                	mv	a1,a5
    800054fe:	855e                	mv	a0,s7
    80005500:	ffffc097          	auipc	ra,0xffffc
    80005504:	f46080e7          	jalr	-186(ra) # 80001446 <uvmalloc>
    80005508:	8b2a                	mv	s6,a0
  ip = 0;
    8000550a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000550c:	12050c63          	beqz	a0,80005644 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005510:	75f9                	lui	a1,0xffffe
    80005512:	95aa                	add	a1,a1,a0
    80005514:	855e                	mv	a0,s7
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	14e080e7          	jalr	334(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    8000551e:	7c7d                	lui	s8,0xfffff
    80005520:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005522:	e0043783          	ld	a5,-512(s0)
    80005526:	6388                	ld	a0,0(a5)
    80005528:	c535                	beqz	a0,80005594 <exec+0x216>
    8000552a:	e9040993          	addi	s3,s0,-368
    8000552e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005532:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	954080e7          	jalr	-1708(ra) # 80000e88 <strlen>
    8000553c:	2505                	addiw	a0,a0,1
    8000553e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005542:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005546:	13896363          	bltu	s2,s8,8000566c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000554a:	e0043d83          	ld	s11,-512(s0)
    8000554e:	000dba03          	ld	s4,0(s11)
    80005552:	8552                	mv	a0,s4
    80005554:	ffffc097          	auipc	ra,0xffffc
    80005558:	934080e7          	jalr	-1740(ra) # 80000e88 <strlen>
    8000555c:	0015069b          	addiw	a3,a0,1
    80005560:	8652                	mv	a2,s4
    80005562:	85ca                	mv	a1,s2
    80005564:	855e                	mv	a0,s7
    80005566:	ffffc097          	auipc	ra,0xffffc
    8000556a:	130080e7          	jalr	304(ra) # 80001696 <copyout>
    8000556e:	10054363          	bltz	a0,80005674 <exec+0x2f6>
    ustack[argc] = sp;
    80005572:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005576:	0485                	addi	s1,s1,1
    80005578:	008d8793          	addi	a5,s11,8
    8000557c:	e0f43023          	sd	a5,-512(s0)
    80005580:	008db503          	ld	a0,8(s11)
    80005584:	c911                	beqz	a0,80005598 <exec+0x21a>
    if(argc >= MAXARG)
    80005586:	09a1                	addi	s3,s3,8
    80005588:	fb3c96e3          	bne	s9,s3,80005534 <exec+0x1b6>
  sz = sz1;
    8000558c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005590:	4481                	li	s1,0
    80005592:	a84d                	j	80005644 <exec+0x2c6>
  sp = sz;
    80005594:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005596:	4481                	li	s1,0
  ustack[argc] = 0;
    80005598:	00349793          	slli	a5,s1,0x3
    8000559c:	f9040713          	addi	a4,s0,-112
    800055a0:	97ba                	add	a5,a5,a4
    800055a2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800055a6:	00148693          	addi	a3,s1,1
    800055aa:	068e                	slli	a3,a3,0x3
    800055ac:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055b0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800055b4:	01897663          	bgeu	s2,s8,800055c0 <exec+0x242>
  sz = sz1;
    800055b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055bc:	4481                	li	s1,0
    800055be:	a059                	j	80005644 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055c0:	e9040613          	addi	a2,s0,-368
    800055c4:	85ca                	mv	a1,s2
    800055c6:	855e                	mv	a0,s7
    800055c8:	ffffc097          	auipc	ra,0xffffc
    800055cc:	0ce080e7          	jalr	206(ra) # 80001696 <copyout>
    800055d0:	0a054663          	bltz	a0,8000567c <exec+0x2fe>
  p->trapframe->a1 = sp;
    800055d4:	078ab783          	ld	a5,120(s5)
    800055d8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055dc:	df843783          	ld	a5,-520(s0)
    800055e0:	0007c703          	lbu	a4,0(a5)
    800055e4:	cf11                	beqz	a4,80005600 <exec+0x282>
    800055e6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055e8:	02f00693          	li	a3,47
    800055ec:	a039                	j	800055fa <exec+0x27c>
      last = s+1;
    800055ee:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055f2:	0785                	addi	a5,a5,1
    800055f4:	fff7c703          	lbu	a4,-1(a5)
    800055f8:	c701                	beqz	a4,80005600 <exec+0x282>
    if(*s == '/')
    800055fa:	fed71ce3          	bne	a4,a3,800055f2 <exec+0x274>
    800055fe:	bfc5                	j	800055ee <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005600:	4641                	li	a2,16
    80005602:	df843583          	ld	a1,-520(s0)
    80005606:	178a8513          	addi	a0,s5,376
    8000560a:	ffffc097          	auipc	ra,0xffffc
    8000560e:	84c080e7          	jalr	-1972(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    80005612:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005616:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    8000561a:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000561e:	078ab783          	ld	a5,120(s5)
    80005622:	e6843703          	ld	a4,-408(s0)
    80005626:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005628:	078ab783          	ld	a5,120(s5)
    8000562c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005630:	85ea                	mv	a1,s10
    80005632:	ffffd097          	auipc	ra,0xffffd
    80005636:	96e080e7          	jalr	-1682(ra) # 80001fa0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000563a:	0004851b          	sext.w	a0,s1
    8000563e:	bbe1                	j	80005416 <exec+0x98>
    80005640:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005644:	e0843583          	ld	a1,-504(s0)
    80005648:	855e                	mv	a0,s7
    8000564a:	ffffd097          	auipc	ra,0xffffd
    8000564e:	956080e7          	jalr	-1706(ra) # 80001fa0 <proc_freepagetable>
  if(ip){
    80005652:	da0498e3          	bnez	s1,80005402 <exec+0x84>
  return -1;
    80005656:	557d                	li	a0,-1
    80005658:	bb7d                	j	80005416 <exec+0x98>
    8000565a:	e1243423          	sd	s2,-504(s0)
    8000565e:	b7dd                	j	80005644 <exec+0x2c6>
    80005660:	e1243423          	sd	s2,-504(s0)
    80005664:	b7c5                	j	80005644 <exec+0x2c6>
    80005666:	e1243423          	sd	s2,-504(s0)
    8000566a:	bfe9                	j	80005644 <exec+0x2c6>
  sz = sz1;
    8000566c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005670:	4481                	li	s1,0
    80005672:	bfc9                	j	80005644 <exec+0x2c6>
  sz = sz1;
    80005674:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005678:	4481                	li	s1,0
    8000567a:	b7e9                	j	80005644 <exec+0x2c6>
  sz = sz1;
    8000567c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005680:	4481                	li	s1,0
    80005682:	b7c9                	j	80005644 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005684:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005688:	2b05                	addiw	s6,s6,1
    8000568a:	0389899b          	addiw	s3,s3,56
    8000568e:	e8845783          	lhu	a5,-376(s0)
    80005692:	e2fb5be3          	bge	s6,a5,800054c8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005696:	2981                	sext.w	s3,s3
    80005698:	03800713          	li	a4,56
    8000569c:	86ce                	mv	a3,s3
    8000569e:	e1840613          	addi	a2,s0,-488
    800056a2:	4581                	li	a1,0
    800056a4:	8526                	mv	a0,s1
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	a8e080e7          	jalr	-1394(ra) # 80004134 <readi>
    800056ae:	03800793          	li	a5,56
    800056b2:	f8f517e3          	bne	a0,a5,80005640 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800056b6:	e1842783          	lw	a5,-488(s0)
    800056ba:	4705                	li	a4,1
    800056bc:	fce796e3          	bne	a5,a4,80005688 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800056c0:	e4043603          	ld	a2,-448(s0)
    800056c4:	e3843783          	ld	a5,-456(s0)
    800056c8:	f8f669e3          	bltu	a2,a5,8000565a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056cc:	e2843783          	ld	a5,-472(s0)
    800056d0:	963e                	add	a2,a2,a5
    800056d2:	f8f667e3          	bltu	a2,a5,80005660 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056d6:	85ca                	mv	a1,s2
    800056d8:	855e                	mv	a0,s7
    800056da:	ffffc097          	auipc	ra,0xffffc
    800056de:	d6c080e7          	jalr	-660(ra) # 80001446 <uvmalloc>
    800056e2:	e0a43423          	sd	a0,-504(s0)
    800056e6:	d141                	beqz	a0,80005666 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800056e8:	e2843d03          	ld	s10,-472(s0)
    800056ec:	df043783          	ld	a5,-528(s0)
    800056f0:	00fd77b3          	and	a5,s10,a5
    800056f4:	fba1                	bnez	a5,80005644 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056f6:	e2042d83          	lw	s11,-480(s0)
    800056fa:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056fe:	f80c03e3          	beqz	s8,80005684 <exec+0x306>
    80005702:	8a62                	mv	s4,s8
    80005704:	4901                	li	s2,0
    80005706:	b345                	j	800054a6 <exec+0x128>

0000000080005708 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005708:	7179                	addi	sp,sp,-48
    8000570a:	f406                	sd	ra,40(sp)
    8000570c:	f022                	sd	s0,32(sp)
    8000570e:	ec26                	sd	s1,24(sp)
    80005710:	e84a                	sd	s2,16(sp)
    80005712:	1800                	addi	s0,sp,48
    80005714:	892e                	mv	s2,a1
    80005716:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005718:	fdc40593          	addi	a1,s0,-36
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	b76080e7          	jalr	-1162(ra) # 80003292 <argint>
    80005724:	04054063          	bltz	a0,80005764 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005728:	fdc42703          	lw	a4,-36(s0)
    8000572c:	47bd                	li	a5,15
    8000572e:	02e7ed63          	bltu	a5,a4,80005768 <argfd+0x60>
    80005732:	ffffc097          	auipc	ra,0xffffc
    80005736:	6c2080e7          	jalr	1730(ra) # 80001df4 <myproc>
    8000573a:	fdc42703          	lw	a4,-36(s0)
    8000573e:	01e70793          	addi	a5,a4,30
    80005742:	078e                	slli	a5,a5,0x3
    80005744:	953e                	add	a0,a0,a5
    80005746:	611c                	ld	a5,0(a0)
    80005748:	c395                	beqz	a5,8000576c <argfd+0x64>
    return -1;
  if(pfd)
    8000574a:	00090463          	beqz	s2,80005752 <argfd+0x4a>
    *pfd = fd;
    8000574e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005752:	4501                	li	a0,0
  if(pf)
    80005754:	c091                	beqz	s1,80005758 <argfd+0x50>
    *pf = f;
    80005756:	e09c                	sd	a5,0(s1)
}
    80005758:	70a2                	ld	ra,40(sp)
    8000575a:	7402                	ld	s0,32(sp)
    8000575c:	64e2                	ld	s1,24(sp)
    8000575e:	6942                	ld	s2,16(sp)
    80005760:	6145                	addi	sp,sp,48
    80005762:	8082                	ret
    return -1;
    80005764:	557d                	li	a0,-1
    80005766:	bfcd                	j	80005758 <argfd+0x50>
    return -1;
    80005768:	557d                	li	a0,-1
    8000576a:	b7fd                	j	80005758 <argfd+0x50>
    8000576c:	557d                	li	a0,-1
    8000576e:	b7ed                	j	80005758 <argfd+0x50>

0000000080005770 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005770:	1101                	addi	sp,sp,-32
    80005772:	ec06                	sd	ra,24(sp)
    80005774:	e822                	sd	s0,16(sp)
    80005776:	e426                	sd	s1,8(sp)
    80005778:	1000                	addi	s0,sp,32
    8000577a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000577c:	ffffc097          	auipc	ra,0xffffc
    80005780:	678080e7          	jalr	1656(ra) # 80001df4 <myproc>
    80005784:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005786:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000578a:	4501                	li	a0,0
    8000578c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000578e:	6398                	ld	a4,0(a5)
    80005790:	cb19                	beqz	a4,800057a6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005792:	2505                	addiw	a0,a0,1
    80005794:	07a1                	addi	a5,a5,8
    80005796:	fed51ce3          	bne	a0,a3,8000578e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000579a:	557d                	li	a0,-1
}
    8000579c:	60e2                	ld	ra,24(sp)
    8000579e:	6442                	ld	s0,16(sp)
    800057a0:	64a2                	ld	s1,8(sp)
    800057a2:	6105                	addi	sp,sp,32
    800057a4:	8082                	ret
      p->ofile[fd] = f;
    800057a6:	01e50793          	addi	a5,a0,30
    800057aa:	078e                	slli	a5,a5,0x3
    800057ac:	963e                	add	a2,a2,a5
    800057ae:	e204                	sd	s1,0(a2)
      return fd;
    800057b0:	b7f5                	j	8000579c <fdalloc+0x2c>

00000000800057b2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057b2:	715d                	addi	sp,sp,-80
    800057b4:	e486                	sd	ra,72(sp)
    800057b6:	e0a2                	sd	s0,64(sp)
    800057b8:	fc26                	sd	s1,56(sp)
    800057ba:	f84a                	sd	s2,48(sp)
    800057bc:	f44e                	sd	s3,40(sp)
    800057be:	f052                	sd	s4,32(sp)
    800057c0:	ec56                	sd	s5,24(sp)
    800057c2:	0880                	addi	s0,sp,80
    800057c4:	89ae                	mv	s3,a1
    800057c6:	8ab2                	mv	s5,a2
    800057c8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057ca:	fb040593          	addi	a1,s0,-80
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	e86080e7          	jalr	-378(ra) # 80004654 <nameiparent>
    800057d6:	892a                	mv	s2,a0
    800057d8:	12050f63          	beqz	a0,80005916 <create+0x164>
    return 0;

  ilock(dp);
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	6a4080e7          	jalr	1700(ra) # 80003e80 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057e4:	4601                	li	a2,0
    800057e6:	fb040593          	addi	a1,s0,-80
    800057ea:	854a                	mv	a0,s2
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	b78080e7          	jalr	-1160(ra) # 80004364 <dirlookup>
    800057f4:	84aa                	mv	s1,a0
    800057f6:	c921                	beqz	a0,80005846 <create+0x94>
    iunlockput(dp);
    800057f8:	854a                	mv	a0,s2
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	8e8080e7          	jalr	-1816(ra) # 800040e2 <iunlockput>
    ilock(ip);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	67c080e7          	jalr	1660(ra) # 80003e80 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000580c:	2981                	sext.w	s3,s3
    8000580e:	4789                	li	a5,2
    80005810:	02f99463          	bne	s3,a5,80005838 <create+0x86>
    80005814:	0444d783          	lhu	a5,68(s1)
    80005818:	37f9                	addiw	a5,a5,-2
    8000581a:	17c2                	slli	a5,a5,0x30
    8000581c:	93c1                	srli	a5,a5,0x30
    8000581e:	4705                	li	a4,1
    80005820:	00f76c63          	bltu	a4,a5,80005838 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005824:	8526                	mv	a0,s1
    80005826:	60a6                	ld	ra,72(sp)
    80005828:	6406                	ld	s0,64(sp)
    8000582a:	74e2                	ld	s1,56(sp)
    8000582c:	7942                	ld	s2,48(sp)
    8000582e:	79a2                	ld	s3,40(sp)
    80005830:	7a02                	ld	s4,32(sp)
    80005832:	6ae2                	ld	s5,24(sp)
    80005834:	6161                	addi	sp,sp,80
    80005836:	8082                	ret
    iunlockput(ip);
    80005838:	8526                	mv	a0,s1
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	8a8080e7          	jalr	-1880(ra) # 800040e2 <iunlockput>
    return 0;
    80005842:	4481                	li	s1,0
    80005844:	b7c5                	j	80005824 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005846:	85ce                	mv	a1,s3
    80005848:	00092503          	lw	a0,0(s2)
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	49c080e7          	jalr	1180(ra) # 80003ce8 <ialloc>
    80005854:	84aa                	mv	s1,a0
    80005856:	c529                	beqz	a0,800058a0 <create+0xee>
  ilock(ip);
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	628080e7          	jalr	1576(ra) # 80003e80 <ilock>
  ip->major = major;
    80005860:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005864:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005868:	4785                	li	a5,1
    8000586a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	546080e7          	jalr	1350(ra) # 80003db6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005878:	2981                	sext.w	s3,s3
    8000587a:	4785                	li	a5,1
    8000587c:	02f98a63          	beq	s3,a5,800058b0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005880:	40d0                	lw	a2,4(s1)
    80005882:	fb040593          	addi	a1,s0,-80
    80005886:	854a                	mv	a0,s2
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	cec080e7          	jalr	-788(ra) # 80004574 <dirlink>
    80005890:	06054b63          	bltz	a0,80005906 <create+0x154>
  iunlockput(dp);
    80005894:	854a                	mv	a0,s2
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	84c080e7          	jalr	-1972(ra) # 800040e2 <iunlockput>
  return ip;
    8000589e:	b759                	j	80005824 <create+0x72>
    panic("create: ialloc");
    800058a0:	00003517          	auipc	a0,0x3
    800058a4:	ef850513          	addi	a0,a0,-264 # 80008798 <syscalls+0x2b8>
    800058a8:	ffffb097          	auipc	ra,0xffffb
    800058ac:	c96080e7          	jalr	-874(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800058b0:	04a95783          	lhu	a5,74(s2)
    800058b4:	2785                	addiw	a5,a5,1
    800058b6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800058ba:	854a                	mv	a0,s2
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	4fa080e7          	jalr	1274(ra) # 80003db6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058c4:	40d0                	lw	a2,4(s1)
    800058c6:	00003597          	auipc	a1,0x3
    800058ca:	ee258593          	addi	a1,a1,-286 # 800087a8 <syscalls+0x2c8>
    800058ce:	8526                	mv	a0,s1
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	ca4080e7          	jalr	-860(ra) # 80004574 <dirlink>
    800058d8:	00054f63          	bltz	a0,800058f6 <create+0x144>
    800058dc:	00492603          	lw	a2,4(s2)
    800058e0:	00003597          	auipc	a1,0x3
    800058e4:	ed058593          	addi	a1,a1,-304 # 800087b0 <syscalls+0x2d0>
    800058e8:	8526                	mv	a0,s1
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	c8a080e7          	jalr	-886(ra) # 80004574 <dirlink>
    800058f2:	f80557e3          	bgez	a0,80005880 <create+0xce>
      panic("create dots");
    800058f6:	00003517          	auipc	a0,0x3
    800058fa:	ec250513          	addi	a0,a0,-318 # 800087b8 <syscalls+0x2d8>
    800058fe:	ffffb097          	auipc	ra,0xffffb
    80005902:	c40080e7          	jalr	-960(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005906:	00003517          	auipc	a0,0x3
    8000590a:	ec250513          	addi	a0,a0,-318 # 800087c8 <syscalls+0x2e8>
    8000590e:	ffffb097          	auipc	ra,0xffffb
    80005912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>
    return 0;
    80005916:	84aa                	mv	s1,a0
    80005918:	b731                	j	80005824 <create+0x72>

000000008000591a <sys_dup>:
{
    8000591a:	7179                	addi	sp,sp,-48
    8000591c:	f406                	sd	ra,40(sp)
    8000591e:	f022                	sd	s0,32(sp)
    80005920:	ec26                	sd	s1,24(sp)
    80005922:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005924:	fd840613          	addi	a2,s0,-40
    80005928:	4581                	li	a1,0
    8000592a:	4501                	li	a0,0
    8000592c:	00000097          	auipc	ra,0x0
    80005930:	ddc080e7          	jalr	-548(ra) # 80005708 <argfd>
    return -1;
    80005934:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005936:	02054363          	bltz	a0,8000595c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000593a:	fd843503          	ld	a0,-40(s0)
    8000593e:	00000097          	auipc	ra,0x0
    80005942:	e32080e7          	jalr	-462(ra) # 80005770 <fdalloc>
    80005946:	84aa                	mv	s1,a0
    return -1;
    80005948:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000594a:	00054963          	bltz	a0,8000595c <sys_dup+0x42>
  filedup(f);
    8000594e:	fd843503          	ld	a0,-40(s0)
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	37a080e7          	jalr	890(ra) # 80004ccc <filedup>
  return fd;
    8000595a:	87a6                	mv	a5,s1
}
    8000595c:	853e                	mv	a0,a5
    8000595e:	70a2                	ld	ra,40(sp)
    80005960:	7402                	ld	s0,32(sp)
    80005962:	64e2                	ld	s1,24(sp)
    80005964:	6145                	addi	sp,sp,48
    80005966:	8082                	ret

0000000080005968 <sys_read>:
{
    80005968:	7179                	addi	sp,sp,-48
    8000596a:	f406                	sd	ra,40(sp)
    8000596c:	f022                	sd	s0,32(sp)
    8000596e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005970:	fe840613          	addi	a2,s0,-24
    80005974:	4581                	li	a1,0
    80005976:	4501                	li	a0,0
    80005978:	00000097          	auipc	ra,0x0
    8000597c:	d90080e7          	jalr	-624(ra) # 80005708 <argfd>
    return -1;
    80005980:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005982:	04054163          	bltz	a0,800059c4 <sys_read+0x5c>
    80005986:	fe440593          	addi	a1,s0,-28
    8000598a:	4509                	li	a0,2
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	906080e7          	jalr	-1786(ra) # 80003292 <argint>
    return -1;
    80005994:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005996:	02054763          	bltz	a0,800059c4 <sys_read+0x5c>
    8000599a:	fd840593          	addi	a1,s0,-40
    8000599e:	4505                	li	a0,1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	914080e7          	jalr	-1772(ra) # 800032b4 <argaddr>
    return -1;
    800059a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059aa:	00054d63          	bltz	a0,800059c4 <sys_read+0x5c>
  return fileread(f, p, n);
    800059ae:	fe442603          	lw	a2,-28(s0)
    800059b2:	fd843583          	ld	a1,-40(s0)
    800059b6:	fe843503          	ld	a0,-24(s0)
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	49e080e7          	jalr	1182(ra) # 80004e58 <fileread>
    800059c2:	87aa                	mv	a5,a0
}
    800059c4:	853e                	mv	a0,a5
    800059c6:	70a2                	ld	ra,40(sp)
    800059c8:	7402                	ld	s0,32(sp)
    800059ca:	6145                	addi	sp,sp,48
    800059cc:	8082                	ret

00000000800059ce <sys_write>:
{
    800059ce:	7179                	addi	sp,sp,-48
    800059d0:	f406                	sd	ra,40(sp)
    800059d2:	f022                	sd	s0,32(sp)
    800059d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059d6:	fe840613          	addi	a2,s0,-24
    800059da:	4581                	li	a1,0
    800059dc:	4501                	li	a0,0
    800059de:	00000097          	auipc	ra,0x0
    800059e2:	d2a080e7          	jalr	-726(ra) # 80005708 <argfd>
    return -1;
    800059e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059e8:	04054163          	bltz	a0,80005a2a <sys_write+0x5c>
    800059ec:	fe440593          	addi	a1,s0,-28
    800059f0:	4509                	li	a0,2
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	8a0080e7          	jalr	-1888(ra) # 80003292 <argint>
    return -1;
    800059fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059fc:	02054763          	bltz	a0,80005a2a <sys_write+0x5c>
    80005a00:	fd840593          	addi	a1,s0,-40
    80005a04:	4505                	li	a0,1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	8ae080e7          	jalr	-1874(ra) # 800032b4 <argaddr>
    return -1;
    80005a0e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a10:	00054d63          	bltz	a0,80005a2a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005a14:	fe442603          	lw	a2,-28(s0)
    80005a18:	fd843583          	ld	a1,-40(s0)
    80005a1c:	fe843503          	ld	a0,-24(s0)
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	4fa080e7          	jalr	1274(ra) # 80004f1a <filewrite>
    80005a28:	87aa                	mv	a5,a0
}
    80005a2a:	853e                	mv	a0,a5
    80005a2c:	70a2                	ld	ra,40(sp)
    80005a2e:	7402                	ld	s0,32(sp)
    80005a30:	6145                	addi	sp,sp,48
    80005a32:	8082                	ret

0000000080005a34 <sys_close>:
{
    80005a34:	1101                	addi	sp,sp,-32
    80005a36:	ec06                	sd	ra,24(sp)
    80005a38:	e822                	sd	s0,16(sp)
    80005a3a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a3c:	fe040613          	addi	a2,s0,-32
    80005a40:	fec40593          	addi	a1,s0,-20
    80005a44:	4501                	li	a0,0
    80005a46:	00000097          	auipc	ra,0x0
    80005a4a:	cc2080e7          	jalr	-830(ra) # 80005708 <argfd>
    return -1;
    80005a4e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a50:	02054463          	bltz	a0,80005a78 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a54:	ffffc097          	auipc	ra,0xffffc
    80005a58:	3a0080e7          	jalr	928(ra) # 80001df4 <myproc>
    80005a5c:	fec42783          	lw	a5,-20(s0)
    80005a60:	07f9                	addi	a5,a5,30
    80005a62:	078e                	slli	a5,a5,0x3
    80005a64:	97aa                	add	a5,a5,a0
    80005a66:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a6a:	fe043503          	ld	a0,-32(s0)
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	2b0080e7          	jalr	688(ra) # 80004d1e <fileclose>
  return 0;
    80005a76:	4781                	li	a5,0
}
    80005a78:	853e                	mv	a0,a5
    80005a7a:	60e2                	ld	ra,24(sp)
    80005a7c:	6442                	ld	s0,16(sp)
    80005a7e:	6105                	addi	sp,sp,32
    80005a80:	8082                	ret

0000000080005a82 <sys_fstat>:
{
    80005a82:	1101                	addi	sp,sp,-32
    80005a84:	ec06                	sd	ra,24(sp)
    80005a86:	e822                	sd	s0,16(sp)
    80005a88:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a8a:	fe840613          	addi	a2,s0,-24
    80005a8e:	4581                	li	a1,0
    80005a90:	4501                	li	a0,0
    80005a92:	00000097          	auipc	ra,0x0
    80005a96:	c76080e7          	jalr	-906(ra) # 80005708 <argfd>
    return -1;
    80005a9a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a9c:	02054563          	bltz	a0,80005ac6 <sys_fstat+0x44>
    80005aa0:	fe040593          	addi	a1,s0,-32
    80005aa4:	4505                	li	a0,1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	80e080e7          	jalr	-2034(ra) # 800032b4 <argaddr>
    return -1;
    80005aae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ab0:	00054b63          	bltz	a0,80005ac6 <sys_fstat+0x44>
  return filestat(f, st);
    80005ab4:	fe043583          	ld	a1,-32(s0)
    80005ab8:	fe843503          	ld	a0,-24(s0)
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	32a080e7          	jalr	810(ra) # 80004de6 <filestat>
    80005ac4:	87aa                	mv	a5,a0
}
    80005ac6:	853e                	mv	a0,a5
    80005ac8:	60e2                	ld	ra,24(sp)
    80005aca:	6442                	ld	s0,16(sp)
    80005acc:	6105                	addi	sp,sp,32
    80005ace:	8082                	ret

0000000080005ad0 <sys_link>:
{
    80005ad0:	7169                	addi	sp,sp,-304
    80005ad2:	f606                	sd	ra,296(sp)
    80005ad4:	f222                	sd	s0,288(sp)
    80005ad6:	ee26                	sd	s1,280(sp)
    80005ad8:	ea4a                	sd	s2,272(sp)
    80005ada:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005adc:	08000613          	li	a2,128
    80005ae0:	ed040593          	addi	a1,s0,-304
    80005ae4:	4501                	li	a0,0
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	7f0080e7          	jalr	2032(ra) # 800032d6 <argstr>
    return -1;
    80005aee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005af0:	10054e63          	bltz	a0,80005c0c <sys_link+0x13c>
    80005af4:	08000613          	li	a2,128
    80005af8:	f5040593          	addi	a1,s0,-176
    80005afc:	4505                	li	a0,1
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	7d8080e7          	jalr	2008(ra) # 800032d6 <argstr>
    return -1;
    80005b06:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b08:	10054263          	bltz	a0,80005c0c <sys_link+0x13c>
  begin_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	d46080e7          	jalr	-698(ra) # 80004852 <begin_op>
  if((ip = namei(old)) == 0){
    80005b14:	ed040513          	addi	a0,s0,-304
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	b1e080e7          	jalr	-1250(ra) # 80004636 <namei>
    80005b20:	84aa                	mv	s1,a0
    80005b22:	c551                	beqz	a0,80005bae <sys_link+0xde>
  ilock(ip);
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	35c080e7          	jalr	860(ra) # 80003e80 <ilock>
  if(ip->type == T_DIR){
    80005b2c:	04449703          	lh	a4,68(s1)
    80005b30:	4785                	li	a5,1
    80005b32:	08f70463          	beq	a4,a5,80005bba <sys_link+0xea>
  ip->nlink++;
    80005b36:	04a4d783          	lhu	a5,74(s1)
    80005b3a:	2785                	addiw	a5,a5,1
    80005b3c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b40:	8526                	mv	a0,s1
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	274080e7          	jalr	628(ra) # 80003db6 <iupdate>
  iunlock(ip);
    80005b4a:	8526                	mv	a0,s1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	3f6080e7          	jalr	1014(ra) # 80003f42 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b54:	fd040593          	addi	a1,s0,-48
    80005b58:	f5040513          	addi	a0,s0,-176
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	af8080e7          	jalr	-1288(ra) # 80004654 <nameiparent>
    80005b64:	892a                	mv	s2,a0
    80005b66:	c935                	beqz	a0,80005bda <sys_link+0x10a>
  ilock(dp);
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	318080e7          	jalr	792(ra) # 80003e80 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b70:	00092703          	lw	a4,0(s2)
    80005b74:	409c                	lw	a5,0(s1)
    80005b76:	04f71d63          	bne	a4,a5,80005bd0 <sys_link+0x100>
    80005b7a:	40d0                	lw	a2,4(s1)
    80005b7c:	fd040593          	addi	a1,s0,-48
    80005b80:	854a                	mv	a0,s2
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	9f2080e7          	jalr	-1550(ra) # 80004574 <dirlink>
    80005b8a:	04054363          	bltz	a0,80005bd0 <sys_link+0x100>
  iunlockput(dp);
    80005b8e:	854a                	mv	a0,s2
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	552080e7          	jalr	1362(ra) # 800040e2 <iunlockput>
  iput(ip);
    80005b98:	8526                	mv	a0,s1
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	4a0080e7          	jalr	1184(ra) # 8000403a <iput>
  end_op();
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	d30080e7          	jalr	-720(ra) # 800048d2 <end_op>
  return 0;
    80005baa:	4781                	li	a5,0
    80005bac:	a085                	j	80005c0c <sys_link+0x13c>
    end_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	d24080e7          	jalr	-732(ra) # 800048d2 <end_op>
    return -1;
    80005bb6:	57fd                	li	a5,-1
    80005bb8:	a891                	j	80005c0c <sys_link+0x13c>
    iunlockput(ip);
    80005bba:	8526                	mv	a0,s1
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	526080e7          	jalr	1318(ra) # 800040e2 <iunlockput>
    end_op();
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	d0e080e7          	jalr	-754(ra) # 800048d2 <end_op>
    return -1;
    80005bcc:	57fd                	li	a5,-1
    80005bce:	a83d                	j	80005c0c <sys_link+0x13c>
    iunlockput(dp);
    80005bd0:	854a                	mv	a0,s2
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	510080e7          	jalr	1296(ra) # 800040e2 <iunlockput>
  ilock(ip);
    80005bda:	8526                	mv	a0,s1
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	2a4080e7          	jalr	676(ra) # 80003e80 <ilock>
  ip->nlink--;
    80005be4:	04a4d783          	lhu	a5,74(s1)
    80005be8:	37fd                	addiw	a5,a5,-1
    80005bea:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bee:	8526                	mv	a0,s1
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	1c6080e7          	jalr	454(ra) # 80003db6 <iupdate>
  iunlockput(ip);
    80005bf8:	8526                	mv	a0,s1
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	4e8080e7          	jalr	1256(ra) # 800040e2 <iunlockput>
  end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	cd0080e7          	jalr	-816(ra) # 800048d2 <end_op>
  return -1;
    80005c0a:	57fd                	li	a5,-1
}
    80005c0c:	853e                	mv	a0,a5
    80005c0e:	70b2                	ld	ra,296(sp)
    80005c10:	7412                	ld	s0,288(sp)
    80005c12:	64f2                	ld	s1,280(sp)
    80005c14:	6952                	ld	s2,272(sp)
    80005c16:	6155                	addi	sp,sp,304
    80005c18:	8082                	ret

0000000080005c1a <sys_unlink>:
{
    80005c1a:	7151                	addi	sp,sp,-240
    80005c1c:	f586                	sd	ra,232(sp)
    80005c1e:	f1a2                	sd	s0,224(sp)
    80005c20:	eda6                	sd	s1,216(sp)
    80005c22:	e9ca                	sd	s2,208(sp)
    80005c24:	e5ce                	sd	s3,200(sp)
    80005c26:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c28:	08000613          	li	a2,128
    80005c2c:	f3040593          	addi	a1,s0,-208
    80005c30:	4501                	li	a0,0
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	6a4080e7          	jalr	1700(ra) # 800032d6 <argstr>
    80005c3a:	18054163          	bltz	a0,80005dbc <sys_unlink+0x1a2>
  begin_op();
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	c14080e7          	jalr	-1004(ra) # 80004852 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c46:	fb040593          	addi	a1,s0,-80
    80005c4a:	f3040513          	addi	a0,s0,-208
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	a06080e7          	jalr	-1530(ra) # 80004654 <nameiparent>
    80005c56:	84aa                	mv	s1,a0
    80005c58:	c979                	beqz	a0,80005d2e <sys_unlink+0x114>
  ilock(dp);
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	226080e7          	jalr	550(ra) # 80003e80 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c62:	00003597          	auipc	a1,0x3
    80005c66:	b4658593          	addi	a1,a1,-1210 # 800087a8 <syscalls+0x2c8>
    80005c6a:	fb040513          	addi	a0,s0,-80
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	6dc080e7          	jalr	1756(ra) # 8000434a <namecmp>
    80005c76:	14050a63          	beqz	a0,80005dca <sys_unlink+0x1b0>
    80005c7a:	00003597          	auipc	a1,0x3
    80005c7e:	b3658593          	addi	a1,a1,-1226 # 800087b0 <syscalls+0x2d0>
    80005c82:	fb040513          	addi	a0,s0,-80
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	6c4080e7          	jalr	1732(ra) # 8000434a <namecmp>
    80005c8e:	12050e63          	beqz	a0,80005dca <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c92:	f2c40613          	addi	a2,s0,-212
    80005c96:	fb040593          	addi	a1,s0,-80
    80005c9a:	8526                	mv	a0,s1
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	6c8080e7          	jalr	1736(ra) # 80004364 <dirlookup>
    80005ca4:	892a                	mv	s2,a0
    80005ca6:	12050263          	beqz	a0,80005dca <sys_unlink+0x1b0>
  ilock(ip);
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	1d6080e7          	jalr	470(ra) # 80003e80 <ilock>
  if(ip->nlink < 1)
    80005cb2:	04a91783          	lh	a5,74(s2)
    80005cb6:	08f05263          	blez	a5,80005d3a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005cba:	04491703          	lh	a4,68(s2)
    80005cbe:	4785                	li	a5,1
    80005cc0:	08f70563          	beq	a4,a5,80005d4a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005cc4:	4641                	li	a2,16
    80005cc6:	4581                	li	a1,0
    80005cc8:	fc040513          	addi	a0,s0,-64
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	038080e7          	jalr	56(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cd4:	4741                	li	a4,16
    80005cd6:	f2c42683          	lw	a3,-212(s0)
    80005cda:	fc040613          	addi	a2,s0,-64
    80005cde:	4581                	li	a1,0
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	54a080e7          	jalr	1354(ra) # 8000422c <writei>
    80005cea:	47c1                	li	a5,16
    80005cec:	0af51563          	bne	a0,a5,80005d96 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cf0:	04491703          	lh	a4,68(s2)
    80005cf4:	4785                	li	a5,1
    80005cf6:	0af70863          	beq	a4,a5,80005da6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cfa:	8526                	mv	a0,s1
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	3e6080e7          	jalr	998(ra) # 800040e2 <iunlockput>
  ip->nlink--;
    80005d04:	04a95783          	lhu	a5,74(s2)
    80005d08:	37fd                	addiw	a5,a5,-1
    80005d0a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d0e:	854a                	mv	a0,s2
    80005d10:	ffffe097          	auipc	ra,0xffffe
    80005d14:	0a6080e7          	jalr	166(ra) # 80003db6 <iupdate>
  iunlockput(ip);
    80005d18:	854a                	mv	a0,s2
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	3c8080e7          	jalr	968(ra) # 800040e2 <iunlockput>
  end_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	bb0080e7          	jalr	-1104(ra) # 800048d2 <end_op>
  return 0;
    80005d2a:	4501                	li	a0,0
    80005d2c:	a84d                	j	80005dde <sys_unlink+0x1c4>
    end_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	ba4080e7          	jalr	-1116(ra) # 800048d2 <end_op>
    return -1;
    80005d36:	557d                	li	a0,-1
    80005d38:	a05d                	j	80005dde <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d3a:	00003517          	auipc	a0,0x3
    80005d3e:	a9e50513          	addi	a0,a0,-1378 # 800087d8 <syscalls+0x2f8>
    80005d42:	ffffa097          	auipc	ra,0xffffa
    80005d46:	7fc080e7          	jalr	2044(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d4a:	04c92703          	lw	a4,76(s2)
    80005d4e:	02000793          	li	a5,32
    80005d52:	f6e7f9e3          	bgeu	a5,a4,80005cc4 <sys_unlink+0xaa>
    80005d56:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d5a:	4741                	li	a4,16
    80005d5c:	86ce                	mv	a3,s3
    80005d5e:	f1840613          	addi	a2,s0,-232
    80005d62:	4581                	li	a1,0
    80005d64:	854a                	mv	a0,s2
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	3ce080e7          	jalr	974(ra) # 80004134 <readi>
    80005d6e:	47c1                	li	a5,16
    80005d70:	00f51b63          	bne	a0,a5,80005d86 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d74:	f1845783          	lhu	a5,-232(s0)
    80005d78:	e7a1                	bnez	a5,80005dc0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d7a:	29c1                	addiw	s3,s3,16
    80005d7c:	04c92783          	lw	a5,76(s2)
    80005d80:	fcf9ede3          	bltu	s3,a5,80005d5a <sys_unlink+0x140>
    80005d84:	b781                	j	80005cc4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d86:	00003517          	auipc	a0,0x3
    80005d8a:	a6a50513          	addi	a0,a0,-1430 # 800087f0 <syscalls+0x310>
    80005d8e:	ffffa097          	auipc	ra,0xffffa
    80005d92:	7b0080e7          	jalr	1968(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d96:	00003517          	auipc	a0,0x3
    80005d9a:	a7250513          	addi	a0,a0,-1422 # 80008808 <syscalls+0x328>
    80005d9e:	ffffa097          	auipc	ra,0xffffa
    80005da2:	7a0080e7          	jalr	1952(ra) # 8000053e <panic>
    dp->nlink--;
    80005da6:	04a4d783          	lhu	a5,74(s1)
    80005daa:	37fd                	addiw	a5,a5,-1
    80005dac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005db0:	8526                	mv	a0,s1
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	004080e7          	jalr	4(ra) # 80003db6 <iupdate>
    80005dba:	b781                	j	80005cfa <sys_unlink+0xe0>
    return -1;
    80005dbc:	557d                	li	a0,-1
    80005dbe:	a005                	j	80005dde <sys_unlink+0x1c4>
    iunlockput(ip);
    80005dc0:	854a                	mv	a0,s2
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	320080e7          	jalr	800(ra) # 800040e2 <iunlockput>
  iunlockput(dp);
    80005dca:	8526                	mv	a0,s1
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	316080e7          	jalr	790(ra) # 800040e2 <iunlockput>
  end_op();
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	afe080e7          	jalr	-1282(ra) # 800048d2 <end_op>
  return -1;
    80005ddc:	557d                	li	a0,-1
}
    80005dde:	70ae                	ld	ra,232(sp)
    80005de0:	740e                	ld	s0,224(sp)
    80005de2:	64ee                	ld	s1,216(sp)
    80005de4:	694e                	ld	s2,208(sp)
    80005de6:	69ae                	ld	s3,200(sp)
    80005de8:	616d                	addi	sp,sp,240
    80005dea:	8082                	ret

0000000080005dec <sys_open>:

uint64
sys_open(void)
{
    80005dec:	7131                	addi	sp,sp,-192
    80005dee:	fd06                	sd	ra,184(sp)
    80005df0:	f922                	sd	s0,176(sp)
    80005df2:	f526                	sd	s1,168(sp)
    80005df4:	f14a                	sd	s2,160(sp)
    80005df6:	ed4e                	sd	s3,152(sp)
    80005df8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dfa:	08000613          	li	a2,128
    80005dfe:	f5040593          	addi	a1,s0,-176
    80005e02:	4501                	li	a0,0
    80005e04:	ffffd097          	auipc	ra,0xffffd
    80005e08:	4d2080e7          	jalr	1234(ra) # 800032d6 <argstr>
    return -1;
    80005e0c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e0e:	0c054163          	bltz	a0,80005ed0 <sys_open+0xe4>
    80005e12:	f4c40593          	addi	a1,s0,-180
    80005e16:	4505                	li	a0,1
    80005e18:	ffffd097          	auipc	ra,0xffffd
    80005e1c:	47a080e7          	jalr	1146(ra) # 80003292 <argint>
    80005e20:	0a054863          	bltz	a0,80005ed0 <sys_open+0xe4>

  begin_op();
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	a2e080e7          	jalr	-1490(ra) # 80004852 <begin_op>

  if(omode & O_CREATE){
    80005e2c:	f4c42783          	lw	a5,-180(s0)
    80005e30:	2007f793          	andi	a5,a5,512
    80005e34:	cbdd                	beqz	a5,80005eea <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e36:	4681                	li	a3,0
    80005e38:	4601                	li	a2,0
    80005e3a:	4589                	li	a1,2
    80005e3c:	f5040513          	addi	a0,s0,-176
    80005e40:	00000097          	auipc	ra,0x0
    80005e44:	972080e7          	jalr	-1678(ra) # 800057b2 <create>
    80005e48:	892a                	mv	s2,a0
    if(ip == 0){
    80005e4a:	c959                	beqz	a0,80005ee0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e4c:	04491703          	lh	a4,68(s2)
    80005e50:	478d                	li	a5,3
    80005e52:	00f71763          	bne	a4,a5,80005e60 <sys_open+0x74>
    80005e56:	04695703          	lhu	a4,70(s2)
    80005e5a:	47a5                	li	a5,9
    80005e5c:	0ce7ec63          	bltu	a5,a4,80005f34 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	e02080e7          	jalr	-510(ra) # 80004c62 <filealloc>
    80005e68:	89aa                	mv	s3,a0
    80005e6a:	10050263          	beqz	a0,80005f6e <sys_open+0x182>
    80005e6e:	00000097          	auipc	ra,0x0
    80005e72:	902080e7          	jalr	-1790(ra) # 80005770 <fdalloc>
    80005e76:	84aa                	mv	s1,a0
    80005e78:	0e054663          	bltz	a0,80005f64 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e7c:	04491703          	lh	a4,68(s2)
    80005e80:	478d                	li	a5,3
    80005e82:	0cf70463          	beq	a4,a5,80005f4a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e86:	4789                	li	a5,2
    80005e88:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e8c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e90:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e94:	f4c42783          	lw	a5,-180(s0)
    80005e98:	0017c713          	xori	a4,a5,1
    80005e9c:	8b05                	andi	a4,a4,1
    80005e9e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ea2:	0037f713          	andi	a4,a5,3
    80005ea6:	00e03733          	snez	a4,a4
    80005eaa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005eae:	4007f793          	andi	a5,a5,1024
    80005eb2:	c791                	beqz	a5,80005ebe <sys_open+0xd2>
    80005eb4:	04491703          	lh	a4,68(s2)
    80005eb8:	4789                	li	a5,2
    80005eba:	08f70f63          	beq	a4,a5,80005f58 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ebe:	854a                	mv	a0,s2
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	082080e7          	jalr	130(ra) # 80003f42 <iunlock>
  end_op();
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	a0a080e7          	jalr	-1526(ra) # 800048d2 <end_op>

  return fd;
}
    80005ed0:	8526                	mv	a0,s1
    80005ed2:	70ea                	ld	ra,184(sp)
    80005ed4:	744a                	ld	s0,176(sp)
    80005ed6:	74aa                	ld	s1,168(sp)
    80005ed8:	790a                	ld	s2,160(sp)
    80005eda:	69ea                	ld	s3,152(sp)
    80005edc:	6129                	addi	sp,sp,192
    80005ede:	8082                	ret
      end_op();
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	9f2080e7          	jalr	-1550(ra) # 800048d2 <end_op>
      return -1;
    80005ee8:	b7e5                	j	80005ed0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005eea:	f5040513          	addi	a0,s0,-176
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	748080e7          	jalr	1864(ra) # 80004636 <namei>
    80005ef6:	892a                	mv	s2,a0
    80005ef8:	c905                	beqz	a0,80005f28 <sys_open+0x13c>
    ilock(ip);
    80005efa:	ffffe097          	auipc	ra,0xffffe
    80005efe:	f86080e7          	jalr	-122(ra) # 80003e80 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f02:	04491703          	lh	a4,68(s2)
    80005f06:	4785                	li	a5,1
    80005f08:	f4f712e3          	bne	a4,a5,80005e4c <sys_open+0x60>
    80005f0c:	f4c42783          	lw	a5,-180(s0)
    80005f10:	dba1                	beqz	a5,80005e60 <sys_open+0x74>
      iunlockput(ip);
    80005f12:	854a                	mv	a0,s2
    80005f14:	ffffe097          	auipc	ra,0xffffe
    80005f18:	1ce080e7          	jalr	462(ra) # 800040e2 <iunlockput>
      end_op();
    80005f1c:	fffff097          	auipc	ra,0xfffff
    80005f20:	9b6080e7          	jalr	-1610(ra) # 800048d2 <end_op>
      return -1;
    80005f24:	54fd                	li	s1,-1
    80005f26:	b76d                	j	80005ed0 <sys_open+0xe4>
      end_op();
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	9aa080e7          	jalr	-1622(ra) # 800048d2 <end_op>
      return -1;
    80005f30:	54fd                	li	s1,-1
    80005f32:	bf79                	j	80005ed0 <sys_open+0xe4>
    iunlockput(ip);
    80005f34:	854a                	mv	a0,s2
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	1ac080e7          	jalr	428(ra) # 800040e2 <iunlockput>
    end_op();
    80005f3e:	fffff097          	auipc	ra,0xfffff
    80005f42:	994080e7          	jalr	-1644(ra) # 800048d2 <end_op>
    return -1;
    80005f46:	54fd                	li	s1,-1
    80005f48:	b761                	j	80005ed0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f4a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f4e:	04691783          	lh	a5,70(s2)
    80005f52:	02f99223          	sh	a5,36(s3)
    80005f56:	bf2d                	j	80005e90 <sys_open+0xa4>
    itrunc(ip);
    80005f58:	854a                	mv	a0,s2
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	034080e7          	jalr	52(ra) # 80003f8e <itrunc>
    80005f62:	bfb1                	j	80005ebe <sys_open+0xd2>
      fileclose(f);
    80005f64:	854e                	mv	a0,s3
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	db8080e7          	jalr	-584(ra) # 80004d1e <fileclose>
    iunlockput(ip);
    80005f6e:	854a                	mv	a0,s2
    80005f70:	ffffe097          	auipc	ra,0xffffe
    80005f74:	172080e7          	jalr	370(ra) # 800040e2 <iunlockput>
    end_op();
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	95a080e7          	jalr	-1702(ra) # 800048d2 <end_op>
    return -1;
    80005f80:	54fd                	li	s1,-1
    80005f82:	b7b9                	j	80005ed0 <sys_open+0xe4>

0000000080005f84 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f84:	7175                	addi	sp,sp,-144
    80005f86:	e506                	sd	ra,136(sp)
    80005f88:	e122                	sd	s0,128(sp)
    80005f8a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	8c6080e7          	jalr	-1850(ra) # 80004852 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f94:	08000613          	li	a2,128
    80005f98:	f7040593          	addi	a1,s0,-144
    80005f9c:	4501                	li	a0,0
    80005f9e:	ffffd097          	auipc	ra,0xffffd
    80005fa2:	338080e7          	jalr	824(ra) # 800032d6 <argstr>
    80005fa6:	02054963          	bltz	a0,80005fd8 <sys_mkdir+0x54>
    80005faa:	4681                	li	a3,0
    80005fac:	4601                	li	a2,0
    80005fae:	4585                	li	a1,1
    80005fb0:	f7040513          	addi	a0,s0,-144
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	7fe080e7          	jalr	2046(ra) # 800057b2 <create>
    80005fbc:	cd11                	beqz	a0,80005fd8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fbe:	ffffe097          	auipc	ra,0xffffe
    80005fc2:	124080e7          	jalr	292(ra) # 800040e2 <iunlockput>
  end_op();
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	90c080e7          	jalr	-1780(ra) # 800048d2 <end_op>
  return 0;
    80005fce:	4501                	li	a0,0
}
    80005fd0:	60aa                	ld	ra,136(sp)
    80005fd2:	640a                	ld	s0,128(sp)
    80005fd4:	6149                	addi	sp,sp,144
    80005fd6:	8082                	ret
    end_op();
    80005fd8:	fffff097          	auipc	ra,0xfffff
    80005fdc:	8fa080e7          	jalr	-1798(ra) # 800048d2 <end_op>
    return -1;
    80005fe0:	557d                	li	a0,-1
    80005fe2:	b7fd                	j	80005fd0 <sys_mkdir+0x4c>

0000000080005fe4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fe4:	7135                	addi	sp,sp,-160
    80005fe6:	ed06                	sd	ra,152(sp)
    80005fe8:	e922                	sd	s0,144(sp)
    80005fea:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	866080e7          	jalr	-1946(ra) # 80004852 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ff4:	08000613          	li	a2,128
    80005ff8:	f7040593          	addi	a1,s0,-144
    80005ffc:	4501                	li	a0,0
    80005ffe:	ffffd097          	auipc	ra,0xffffd
    80006002:	2d8080e7          	jalr	728(ra) # 800032d6 <argstr>
    80006006:	04054a63          	bltz	a0,8000605a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000600a:	f6c40593          	addi	a1,s0,-148
    8000600e:	4505                	li	a0,1
    80006010:	ffffd097          	auipc	ra,0xffffd
    80006014:	282080e7          	jalr	642(ra) # 80003292 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006018:	04054163          	bltz	a0,8000605a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000601c:	f6840593          	addi	a1,s0,-152
    80006020:	4509                	li	a0,2
    80006022:	ffffd097          	auipc	ra,0xffffd
    80006026:	270080e7          	jalr	624(ra) # 80003292 <argint>
     argint(1, &major) < 0 ||
    8000602a:	02054863          	bltz	a0,8000605a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000602e:	f6841683          	lh	a3,-152(s0)
    80006032:	f6c41603          	lh	a2,-148(s0)
    80006036:	458d                	li	a1,3
    80006038:	f7040513          	addi	a0,s0,-144
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	776080e7          	jalr	1910(ra) # 800057b2 <create>
     argint(2, &minor) < 0 ||
    80006044:	c919                	beqz	a0,8000605a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006046:	ffffe097          	auipc	ra,0xffffe
    8000604a:	09c080e7          	jalr	156(ra) # 800040e2 <iunlockput>
  end_op();
    8000604e:	fffff097          	auipc	ra,0xfffff
    80006052:	884080e7          	jalr	-1916(ra) # 800048d2 <end_op>
  return 0;
    80006056:	4501                	li	a0,0
    80006058:	a031                	j	80006064 <sys_mknod+0x80>
    end_op();
    8000605a:	fffff097          	auipc	ra,0xfffff
    8000605e:	878080e7          	jalr	-1928(ra) # 800048d2 <end_op>
    return -1;
    80006062:	557d                	li	a0,-1
}
    80006064:	60ea                	ld	ra,152(sp)
    80006066:	644a                	ld	s0,144(sp)
    80006068:	610d                	addi	sp,sp,160
    8000606a:	8082                	ret

000000008000606c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000606c:	7135                	addi	sp,sp,-160
    8000606e:	ed06                	sd	ra,152(sp)
    80006070:	e922                	sd	s0,144(sp)
    80006072:	e526                	sd	s1,136(sp)
    80006074:	e14a                	sd	s2,128(sp)
    80006076:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	d7c080e7          	jalr	-644(ra) # 80001df4 <myproc>
    80006080:	892a                	mv	s2,a0
  
  begin_op();
    80006082:	ffffe097          	auipc	ra,0xffffe
    80006086:	7d0080e7          	jalr	2000(ra) # 80004852 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000608a:	08000613          	li	a2,128
    8000608e:	f6040593          	addi	a1,s0,-160
    80006092:	4501                	li	a0,0
    80006094:	ffffd097          	auipc	ra,0xffffd
    80006098:	242080e7          	jalr	578(ra) # 800032d6 <argstr>
    8000609c:	04054b63          	bltz	a0,800060f2 <sys_chdir+0x86>
    800060a0:	f6040513          	addi	a0,s0,-160
    800060a4:	ffffe097          	auipc	ra,0xffffe
    800060a8:	592080e7          	jalr	1426(ra) # 80004636 <namei>
    800060ac:	84aa                	mv	s1,a0
    800060ae:	c131                	beqz	a0,800060f2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800060b0:	ffffe097          	auipc	ra,0xffffe
    800060b4:	dd0080e7          	jalr	-560(ra) # 80003e80 <ilock>
  if(ip->type != T_DIR){
    800060b8:	04449703          	lh	a4,68(s1)
    800060bc:	4785                	li	a5,1
    800060be:	04f71063          	bne	a4,a5,800060fe <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800060c2:	8526                	mv	a0,s1
    800060c4:	ffffe097          	auipc	ra,0xffffe
    800060c8:	e7e080e7          	jalr	-386(ra) # 80003f42 <iunlock>
  iput(p->cwd);
    800060cc:	17093503          	ld	a0,368(s2)
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	f6a080e7          	jalr	-150(ra) # 8000403a <iput>
  end_op();
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	7fa080e7          	jalr	2042(ra) # 800048d2 <end_op>
  p->cwd = ip;
    800060e0:	16993823          	sd	s1,368(s2)
  return 0;
    800060e4:	4501                	li	a0,0
}
    800060e6:	60ea                	ld	ra,152(sp)
    800060e8:	644a                	ld	s0,144(sp)
    800060ea:	64aa                	ld	s1,136(sp)
    800060ec:	690a                	ld	s2,128(sp)
    800060ee:	610d                	addi	sp,sp,160
    800060f0:	8082                	ret
    end_op();
    800060f2:	ffffe097          	auipc	ra,0xffffe
    800060f6:	7e0080e7          	jalr	2016(ra) # 800048d2 <end_op>
    return -1;
    800060fa:	557d                	li	a0,-1
    800060fc:	b7ed                	j	800060e6 <sys_chdir+0x7a>
    iunlockput(ip);
    800060fe:	8526                	mv	a0,s1
    80006100:	ffffe097          	auipc	ra,0xffffe
    80006104:	fe2080e7          	jalr	-30(ra) # 800040e2 <iunlockput>
    end_op();
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	7ca080e7          	jalr	1994(ra) # 800048d2 <end_op>
    return -1;
    80006110:	557d                	li	a0,-1
    80006112:	bfd1                	j	800060e6 <sys_chdir+0x7a>

0000000080006114 <sys_exec>:

uint64
sys_exec(void)
{
    80006114:	7145                	addi	sp,sp,-464
    80006116:	e786                	sd	ra,456(sp)
    80006118:	e3a2                	sd	s0,448(sp)
    8000611a:	ff26                	sd	s1,440(sp)
    8000611c:	fb4a                	sd	s2,432(sp)
    8000611e:	f74e                	sd	s3,424(sp)
    80006120:	f352                	sd	s4,416(sp)
    80006122:	ef56                	sd	s5,408(sp)
    80006124:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006126:	08000613          	li	a2,128
    8000612a:	f4040593          	addi	a1,s0,-192
    8000612e:	4501                	li	a0,0
    80006130:	ffffd097          	auipc	ra,0xffffd
    80006134:	1a6080e7          	jalr	422(ra) # 800032d6 <argstr>
    return -1;
    80006138:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000613a:	0c054a63          	bltz	a0,8000620e <sys_exec+0xfa>
    8000613e:	e3840593          	addi	a1,s0,-456
    80006142:	4505                	li	a0,1
    80006144:	ffffd097          	auipc	ra,0xffffd
    80006148:	170080e7          	jalr	368(ra) # 800032b4 <argaddr>
    8000614c:	0c054163          	bltz	a0,8000620e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006150:	10000613          	li	a2,256
    80006154:	4581                	li	a1,0
    80006156:	e4040513          	addi	a0,s0,-448
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	baa080e7          	jalr	-1110(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006162:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006166:	89a6                	mv	s3,s1
    80006168:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000616a:	02000a13          	li	s4,32
    8000616e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006172:	00391513          	slli	a0,s2,0x3
    80006176:	e3040593          	addi	a1,s0,-464
    8000617a:	e3843783          	ld	a5,-456(s0)
    8000617e:	953e                	add	a0,a0,a5
    80006180:	ffffd097          	auipc	ra,0xffffd
    80006184:	078080e7          	jalr	120(ra) # 800031f8 <fetchaddr>
    80006188:	02054a63          	bltz	a0,800061bc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000618c:	e3043783          	ld	a5,-464(s0)
    80006190:	c3b9                	beqz	a5,800061d6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	962080e7          	jalr	-1694(ra) # 80000af4 <kalloc>
    8000619a:	85aa                	mv	a1,a0
    8000619c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800061a0:	cd11                	beqz	a0,800061bc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061a2:	6605                	lui	a2,0x1
    800061a4:	e3043503          	ld	a0,-464(s0)
    800061a8:	ffffd097          	auipc	ra,0xffffd
    800061ac:	0a2080e7          	jalr	162(ra) # 8000324a <fetchstr>
    800061b0:	00054663          	bltz	a0,800061bc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800061b4:	0905                	addi	s2,s2,1
    800061b6:	09a1                	addi	s3,s3,8
    800061b8:	fb491be3          	bne	s2,s4,8000616e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061bc:	10048913          	addi	s2,s1,256
    800061c0:	6088                	ld	a0,0(s1)
    800061c2:	c529                	beqz	a0,8000620c <sys_exec+0xf8>
    kfree(argv[i]);
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	834080e7          	jalr	-1996(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061cc:	04a1                	addi	s1,s1,8
    800061ce:	ff2499e3          	bne	s1,s2,800061c0 <sys_exec+0xac>
  return -1;
    800061d2:	597d                	li	s2,-1
    800061d4:	a82d                	j	8000620e <sys_exec+0xfa>
      argv[i] = 0;
    800061d6:	0a8e                	slli	s5,s5,0x3
    800061d8:	fc040793          	addi	a5,s0,-64
    800061dc:	9abe                	add	s5,s5,a5
    800061de:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061e2:	e4040593          	addi	a1,s0,-448
    800061e6:	f4040513          	addi	a0,s0,-192
    800061ea:	fffff097          	auipc	ra,0xfffff
    800061ee:	194080e7          	jalr	404(ra) # 8000537e <exec>
    800061f2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061f4:	10048993          	addi	s3,s1,256
    800061f8:	6088                	ld	a0,0(s1)
    800061fa:	c911                	beqz	a0,8000620e <sys_exec+0xfa>
    kfree(argv[i]);
    800061fc:	ffffa097          	auipc	ra,0xffffa
    80006200:	7fc080e7          	jalr	2044(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006204:	04a1                	addi	s1,s1,8
    80006206:	ff3499e3          	bne	s1,s3,800061f8 <sys_exec+0xe4>
    8000620a:	a011                	j	8000620e <sys_exec+0xfa>
  return -1;
    8000620c:	597d                	li	s2,-1
}
    8000620e:	854a                	mv	a0,s2
    80006210:	60be                	ld	ra,456(sp)
    80006212:	641e                	ld	s0,448(sp)
    80006214:	74fa                	ld	s1,440(sp)
    80006216:	795a                	ld	s2,432(sp)
    80006218:	79ba                	ld	s3,424(sp)
    8000621a:	7a1a                	ld	s4,416(sp)
    8000621c:	6afa                	ld	s5,408(sp)
    8000621e:	6179                	addi	sp,sp,464
    80006220:	8082                	ret

0000000080006222 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006222:	7139                	addi	sp,sp,-64
    80006224:	fc06                	sd	ra,56(sp)
    80006226:	f822                	sd	s0,48(sp)
    80006228:	f426                	sd	s1,40(sp)
    8000622a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000622c:	ffffc097          	auipc	ra,0xffffc
    80006230:	bc8080e7          	jalr	-1080(ra) # 80001df4 <myproc>
    80006234:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006236:	fd840593          	addi	a1,s0,-40
    8000623a:	4501                	li	a0,0
    8000623c:	ffffd097          	auipc	ra,0xffffd
    80006240:	078080e7          	jalr	120(ra) # 800032b4 <argaddr>
    return -1;
    80006244:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006246:	0e054063          	bltz	a0,80006326 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000624a:	fc840593          	addi	a1,s0,-56
    8000624e:	fd040513          	addi	a0,s0,-48
    80006252:	fffff097          	auipc	ra,0xfffff
    80006256:	dfc080e7          	jalr	-516(ra) # 8000504e <pipealloc>
    return -1;
    8000625a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000625c:	0c054563          	bltz	a0,80006326 <sys_pipe+0x104>
  fd0 = -1;
    80006260:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006264:	fd043503          	ld	a0,-48(s0)
    80006268:	fffff097          	auipc	ra,0xfffff
    8000626c:	508080e7          	jalr	1288(ra) # 80005770 <fdalloc>
    80006270:	fca42223          	sw	a0,-60(s0)
    80006274:	08054c63          	bltz	a0,8000630c <sys_pipe+0xea>
    80006278:	fc843503          	ld	a0,-56(s0)
    8000627c:	fffff097          	auipc	ra,0xfffff
    80006280:	4f4080e7          	jalr	1268(ra) # 80005770 <fdalloc>
    80006284:	fca42023          	sw	a0,-64(s0)
    80006288:	06054863          	bltz	a0,800062f8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000628c:	4691                	li	a3,4
    8000628e:	fc440613          	addi	a2,s0,-60
    80006292:	fd843583          	ld	a1,-40(s0)
    80006296:	78a8                	ld	a0,112(s1)
    80006298:	ffffb097          	auipc	ra,0xffffb
    8000629c:	3fe080e7          	jalr	1022(ra) # 80001696 <copyout>
    800062a0:	02054063          	bltz	a0,800062c0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800062a4:	4691                	li	a3,4
    800062a6:	fc040613          	addi	a2,s0,-64
    800062aa:	fd843583          	ld	a1,-40(s0)
    800062ae:	0591                	addi	a1,a1,4
    800062b0:	78a8                	ld	a0,112(s1)
    800062b2:	ffffb097          	auipc	ra,0xffffb
    800062b6:	3e4080e7          	jalr	996(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800062ba:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062bc:	06055563          	bgez	a0,80006326 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800062c0:	fc442783          	lw	a5,-60(s0)
    800062c4:	07f9                	addi	a5,a5,30
    800062c6:	078e                	slli	a5,a5,0x3
    800062c8:	97a6                	add	a5,a5,s1
    800062ca:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062ce:	fc042503          	lw	a0,-64(s0)
    800062d2:	0579                	addi	a0,a0,30
    800062d4:	050e                	slli	a0,a0,0x3
    800062d6:	9526                	add	a0,a0,s1
    800062d8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062dc:	fd043503          	ld	a0,-48(s0)
    800062e0:	fffff097          	auipc	ra,0xfffff
    800062e4:	a3e080e7          	jalr	-1474(ra) # 80004d1e <fileclose>
    fileclose(wf);
    800062e8:	fc843503          	ld	a0,-56(s0)
    800062ec:	fffff097          	auipc	ra,0xfffff
    800062f0:	a32080e7          	jalr	-1486(ra) # 80004d1e <fileclose>
    return -1;
    800062f4:	57fd                	li	a5,-1
    800062f6:	a805                	j	80006326 <sys_pipe+0x104>
    if(fd0 >= 0)
    800062f8:	fc442783          	lw	a5,-60(s0)
    800062fc:	0007c863          	bltz	a5,8000630c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006300:	01e78513          	addi	a0,a5,30
    80006304:	050e                	slli	a0,a0,0x3
    80006306:	9526                	add	a0,a0,s1
    80006308:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000630c:	fd043503          	ld	a0,-48(s0)
    80006310:	fffff097          	auipc	ra,0xfffff
    80006314:	a0e080e7          	jalr	-1522(ra) # 80004d1e <fileclose>
    fileclose(wf);
    80006318:	fc843503          	ld	a0,-56(s0)
    8000631c:	fffff097          	auipc	ra,0xfffff
    80006320:	a02080e7          	jalr	-1534(ra) # 80004d1e <fileclose>
    return -1;
    80006324:	57fd                	li	a5,-1
}
    80006326:	853e                	mv	a0,a5
    80006328:	70e2                	ld	ra,56(sp)
    8000632a:	7442                	ld	s0,48(sp)
    8000632c:	74a2                	ld	s1,40(sp)
    8000632e:	6121                	addi	sp,sp,64
    80006330:	8082                	ret
	...

0000000080006340 <kernelvec>:
    80006340:	7111                	addi	sp,sp,-256
    80006342:	e006                	sd	ra,0(sp)
    80006344:	e40a                	sd	sp,8(sp)
    80006346:	e80e                	sd	gp,16(sp)
    80006348:	ec12                	sd	tp,24(sp)
    8000634a:	f016                	sd	t0,32(sp)
    8000634c:	f41a                	sd	t1,40(sp)
    8000634e:	f81e                	sd	t2,48(sp)
    80006350:	fc22                	sd	s0,56(sp)
    80006352:	e0a6                	sd	s1,64(sp)
    80006354:	e4aa                	sd	a0,72(sp)
    80006356:	e8ae                	sd	a1,80(sp)
    80006358:	ecb2                	sd	a2,88(sp)
    8000635a:	f0b6                	sd	a3,96(sp)
    8000635c:	f4ba                	sd	a4,104(sp)
    8000635e:	f8be                	sd	a5,112(sp)
    80006360:	fcc2                	sd	a6,120(sp)
    80006362:	e146                	sd	a7,128(sp)
    80006364:	e54a                	sd	s2,136(sp)
    80006366:	e94e                	sd	s3,144(sp)
    80006368:	ed52                	sd	s4,152(sp)
    8000636a:	f156                	sd	s5,160(sp)
    8000636c:	f55a                	sd	s6,168(sp)
    8000636e:	f95e                	sd	s7,176(sp)
    80006370:	fd62                	sd	s8,184(sp)
    80006372:	e1e6                	sd	s9,192(sp)
    80006374:	e5ea                	sd	s10,200(sp)
    80006376:	e9ee                	sd	s11,208(sp)
    80006378:	edf2                	sd	t3,216(sp)
    8000637a:	f1f6                	sd	t4,224(sp)
    8000637c:	f5fa                	sd	t5,232(sp)
    8000637e:	f9fe                	sd	t6,240(sp)
    80006380:	d45fc0ef          	jal	ra,800030c4 <kerneltrap>
    80006384:	6082                	ld	ra,0(sp)
    80006386:	6122                	ld	sp,8(sp)
    80006388:	61c2                	ld	gp,16(sp)
    8000638a:	7282                	ld	t0,32(sp)
    8000638c:	7322                	ld	t1,40(sp)
    8000638e:	73c2                	ld	t2,48(sp)
    80006390:	7462                	ld	s0,56(sp)
    80006392:	6486                	ld	s1,64(sp)
    80006394:	6526                	ld	a0,72(sp)
    80006396:	65c6                	ld	a1,80(sp)
    80006398:	6666                	ld	a2,88(sp)
    8000639a:	7686                	ld	a3,96(sp)
    8000639c:	7726                	ld	a4,104(sp)
    8000639e:	77c6                	ld	a5,112(sp)
    800063a0:	7866                	ld	a6,120(sp)
    800063a2:	688a                	ld	a7,128(sp)
    800063a4:	692a                	ld	s2,136(sp)
    800063a6:	69ca                	ld	s3,144(sp)
    800063a8:	6a6a                	ld	s4,152(sp)
    800063aa:	7a8a                	ld	s5,160(sp)
    800063ac:	7b2a                	ld	s6,168(sp)
    800063ae:	7bca                	ld	s7,176(sp)
    800063b0:	7c6a                	ld	s8,184(sp)
    800063b2:	6c8e                	ld	s9,192(sp)
    800063b4:	6d2e                	ld	s10,200(sp)
    800063b6:	6dce                	ld	s11,208(sp)
    800063b8:	6e6e                	ld	t3,216(sp)
    800063ba:	7e8e                	ld	t4,224(sp)
    800063bc:	7f2e                	ld	t5,232(sp)
    800063be:	7fce                	ld	t6,240(sp)
    800063c0:	6111                	addi	sp,sp,256
    800063c2:	10200073          	sret
    800063c6:	00000013          	nop
    800063ca:	00000013          	nop
    800063ce:	0001                	nop

00000000800063d0 <timervec>:
    800063d0:	34051573          	csrrw	a0,mscratch,a0
    800063d4:	e10c                	sd	a1,0(a0)
    800063d6:	e510                	sd	a2,8(a0)
    800063d8:	e914                	sd	a3,16(a0)
    800063da:	6d0c                	ld	a1,24(a0)
    800063dc:	7110                	ld	a2,32(a0)
    800063de:	6194                	ld	a3,0(a1)
    800063e0:	96b2                	add	a3,a3,a2
    800063e2:	e194                	sd	a3,0(a1)
    800063e4:	4589                	li	a1,2
    800063e6:	14459073          	csrw	sip,a1
    800063ea:	6914                	ld	a3,16(a0)
    800063ec:	6510                	ld	a2,8(a0)
    800063ee:	610c                	ld	a1,0(a0)
    800063f0:	34051573          	csrrw	a0,mscratch,a0
    800063f4:	30200073          	mret
	...

00000000800063fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063fa:	1141                	addi	sp,sp,-16
    800063fc:	e422                	sd	s0,8(sp)
    800063fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006400:	0c0007b7          	lui	a5,0xc000
    80006404:	4705                	li	a4,1
    80006406:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006408:	c3d8                	sw	a4,4(a5)
}
    8000640a:	6422                	ld	s0,8(sp)
    8000640c:	0141                	addi	sp,sp,16
    8000640e:	8082                	ret

0000000080006410 <plicinithart>:

void
plicinithart(void)
{
    80006410:	1141                	addi	sp,sp,-16
    80006412:	e406                	sd	ra,8(sp)
    80006414:	e022                	sd	s0,0(sp)
    80006416:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006418:	ffffc097          	auipc	ra,0xffffc
    8000641c:	9a8080e7          	jalr	-1624(ra) # 80001dc0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006420:	0085171b          	slliw	a4,a0,0x8
    80006424:	0c0027b7          	lui	a5,0xc002
    80006428:	97ba                	add	a5,a5,a4
    8000642a:	40200713          	li	a4,1026
    8000642e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006432:	00d5151b          	slliw	a0,a0,0xd
    80006436:	0c2017b7          	lui	a5,0xc201
    8000643a:	953e                	add	a0,a0,a5
    8000643c:	00052023          	sw	zero,0(a0)
}
    80006440:	60a2                	ld	ra,8(sp)
    80006442:	6402                	ld	s0,0(sp)
    80006444:	0141                	addi	sp,sp,16
    80006446:	8082                	ret

0000000080006448 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006448:	1141                	addi	sp,sp,-16
    8000644a:	e406                	sd	ra,8(sp)
    8000644c:	e022                	sd	s0,0(sp)
    8000644e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006450:	ffffc097          	auipc	ra,0xffffc
    80006454:	970080e7          	jalr	-1680(ra) # 80001dc0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006458:	00d5179b          	slliw	a5,a0,0xd
    8000645c:	0c201537          	lui	a0,0xc201
    80006460:	953e                	add	a0,a0,a5
  return irq;
}
    80006462:	4148                	lw	a0,4(a0)
    80006464:	60a2                	ld	ra,8(sp)
    80006466:	6402                	ld	s0,0(sp)
    80006468:	0141                	addi	sp,sp,16
    8000646a:	8082                	ret

000000008000646c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000646c:	1101                	addi	sp,sp,-32
    8000646e:	ec06                	sd	ra,24(sp)
    80006470:	e822                	sd	s0,16(sp)
    80006472:	e426                	sd	s1,8(sp)
    80006474:	1000                	addi	s0,sp,32
    80006476:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006478:	ffffc097          	auipc	ra,0xffffc
    8000647c:	948080e7          	jalr	-1720(ra) # 80001dc0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006480:	00d5151b          	slliw	a0,a0,0xd
    80006484:	0c2017b7          	lui	a5,0xc201
    80006488:	97aa                	add	a5,a5,a0
    8000648a:	c3c4                	sw	s1,4(a5)
}
    8000648c:	60e2                	ld	ra,24(sp)
    8000648e:	6442                	ld	s0,16(sp)
    80006490:	64a2                	ld	s1,8(sp)
    80006492:	6105                	addi	sp,sp,32
    80006494:	8082                	ret

0000000080006496 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006496:	1141                	addi	sp,sp,-16
    80006498:	e406                	sd	ra,8(sp)
    8000649a:	e022                	sd	s0,0(sp)
    8000649c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000649e:	479d                	li	a5,7
    800064a0:	06a7c963          	blt	a5,a0,80006512 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800064a4:	0001d797          	auipc	a5,0x1d
    800064a8:	b5c78793          	addi	a5,a5,-1188 # 80023000 <disk>
    800064ac:	00a78733          	add	a4,a5,a0
    800064b0:	6789                	lui	a5,0x2
    800064b2:	97ba                	add	a5,a5,a4
    800064b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800064b8:	e7ad                	bnez	a5,80006522 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064ba:	00451793          	slli	a5,a0,0x4
    800064be:	0001f717          	auipc	a4,0x1f
    800064c2:	b4270713          	addi	a4,a4,-1214 # 80025000 <disk+0x2000>
    800064c6:	6314                	ld	a3,0(a4)
    800064c8:	96be                	add	a3,a3,a5
    800064ca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800064ce:	6314                	ld	a3,0(a4)
    800064d0:	96be                	add	a3,a3,a5
    800064d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800064d6:	6314                	ld	a3,0(a4)
    800064d8:	96be                	add	a3,a3,a5
    800064da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800064de:	6318                	ld	a4,0(a4)
    800064e0:	97ba                	add	a5,a5,a4
    800064e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800064e6:	0001d797          	auipc	a5,0x1d
    800064ea:	b1a78793          	addi	a5,a5,-1254 # 80023000 <disk>
    800064ee:	97aa                	add	a5,a5,a0
    800064f0:	6509                	lui	a0,0x2
    800064f2:	953e                	add	a0,a0,a5
    800064f4:	4785                	li	a5,1
    800064f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800064fa:	0001f517          	auipc	a0,0x1f
    800064fe:	b1e50513          	addi	a0,a0,-1250 # 80025018 <disk+0x2018>
    80006502:	ffffc097          	auipc	ra,0xffffc
    80006506:	374080e7          	jalr	884(ra) # 80002876 <wakeup>
}
    8000650a:	60a2                	ld	ra,8(sp)
    8000650c:	6402                	ld	s0,0(sp)
    8000650e:	0141                	addi	sp,sp,16
    80006510:	8082                	ret
    panic("free_desc 1");
    80006512:	00002517          	auipc	a0,0x2
    80006516:	30650513          	addi	a0,a0,774 # 80008818 <syscalls+0x338>
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	024080e7          	jalr	36(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006522:	00002517          	auipc	a0,0x2
    80006526:	30650513          	addi	a0,a0,774 # 80008828 <syscalls+0x348>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	014080e7          	jalr	20(ra) # 8000053e <panic>

0000000080006532 <virtio_disk_init>:
{
    80006532:	1101                	addi	sp,sp,-32
    80006534:	ec06                	sd	ra,24(sp)
    80006536:	e822                	sd	s0,16(sp)
    80006538:	e426                	sd	s1,8(sp)
    8000653a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000653c:	00002597          	auipc	a1,0x2
    80006540:	2fc58593          	addi	a1,a1,764 # 80008838 <syscalls+0x358>
    80006544:	0001f517          	auipc	a0,0x1f
    80006548:	be450513          	addi	a0,a0,-1052 # 80025128 <disk+0x2128>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	608080e7          	jalr	1544(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006554:	100017b7          	lui	a5,0x10001
    80006558:	4398                	lw	a4,0(a5)
    8000655a:	2701                	sext.w	a4,a4
    8000655c:	747277b7          	lui	a5,0x74727
    80006560:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006564:	0ef71163          	bne	a4,a5,80006646 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006568:	100017b7          	lui	a5,0x10001
    8000656c:	43dc                	lw	a5,4(a5)
    8000656e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006570:	4705                	li	a4,1
    80006572:	0ce79a63          	bne	a5,a4,80006646 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006576:	100017b7          	lui	a5,0x10001
    8000657a:	479c                	lw	a5,8(a5)
    8000657c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000657e:	4709                	li	a4,2
    80006580:	0ce79363          	bne	a5,a4,80006646 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006584:	100017b7          	lui	a5,0x10001
    80006588:	47d8                	lw	a4,12(a5)
    8000658a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000658c:	554d47b7          	lui	a5,0x554d4
    80006590:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006594:	0af71963          	bne	a4,a5,80006646 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006598:	100017b7          	lui	a5,0x10001
    8000659c:	4705                	li	a4,1
    8000659e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065a0:	470d                	li	a4,3
    800065a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800065a6:	c7ffe737          	lui	a4,0xc7ffe
    800065aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800065ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800065b0:	2701                	sext.w	a4,a4
    800065b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065b4:	472d                	li	a4,11
    800065b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065b8:	473d                	li	a4,15
    800065ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800065bc:	6705                	lui	a4,0x1
    800065be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800065c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065c4:	5bdc                	lw	a5,52(a5)
    800065c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800065c8:	c7d9                	beqz	a5,80006656 <virtio_disk_init+0x124>
  if(max < NUM)
    800065ca:	471d                	li	a4,7
    800065cc:	08f77d63          	bgeu	a4,a5,80006666 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065d0:	100014b7          	lui	s1,0x10001
    800065d4:	47a1                	li	a5,8
    800065d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800065d8:	6609                	lui	a2,0x2
    800065da:	4581                	li	a1,0
    800065dc:	0001d517          	auipc	a0,0x1d
    800065e0:	a2450513          	addi	a0,a0,-1500 # 80023000 <disk>
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	720080e7          	jalr	1824(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800065ec:	0001d717          	auipc	a4,0x1d
    800065f0:	a1470713          	addi	a4,a4,-1516 # 80023000 <disk>
    800065f4:	00c75793          	srli	a5,a4,0xc
    800065f8:	2781                	sext.w	a5,a5
    800065fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800065fc:	0001f797          	auipc	a5,0x1f
    80006600:	a0478793          	addi	a5,a5,-1532 # 80025000 <disk+0x2000>
    80006604:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006606:	0001d717          	auipc	a4,0x1d
    8000660a:	a7a70713          	addi	a4,a4,-1414 # 80023080 <disk+0x80>
    8000660e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006610:	0001e717          	auipc	a4,0x1e
    80006614:	9f070713          	addi	a4,a4,-1552 # 80024000 <disk+0x1000>
    80006618:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000661a:	4705                	li	a4,1
    8000661c:	00e78c23          	sb	a4,24(a5)
    80006620:	00e78ca3          	sb	a4,25(a5)
    80006624:	00e78d23          	sb	a4,26(a5)
    80006628:	00e78da3          	sb	a4,27(a5)
    8000662c:	00e78e23          	sb	a4,28(a5)
    80006630:	00e78ea3          	sb	a4,29(a5)
    80006634:	00e78f23          	sb	a4,30(a5)
    80006638:	00e78fa3          	sb	a4,31(a5)
}
    8000663c:	60e2                	ld	ra,24(sp)
    8000663e:	6442                	ld	s0,16(sp)
    80006640:	64a2                	ld	s1,8(sp)
    80006642:	6105                	addi	sp,sp,32
    80006644:	8082                	ret
    panic("could not find virtio disk");
    80006646:	00002517          	auipc	a0,0x2
    8000664a:	20250513          	addi	a0,a0,514 # 80008848 <syscalls+0x368>
    8000664e:	ffffa097          	auipc	ra,0xffffa
    80006652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006656:	00002517          	auipc	a0,0x2
    8000665a:	21250513          	addi	a0,a0,530 # 80008868 <syscalls+0x388>
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006666:	00002517          	auipc	a0,0x2
    8000666a:	22250513          	addi	a0,a0,546 # 80008888 <syscalls+0x3a8>
    8000666e:	ffffa097          	auipc	ra,0xffffa
    80006672:	ed0080e7          	jalr	-304(ra) # 8000053e <panic>

0000000080006676 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006676:	7159                	addi	sp,sp,-112
    80006678:	f486                	sd	ra,104(sp)
    8000667a:	f0a2                	sd	s0,96(sp)
    8000667c:	eca6                	sd	s1,88(sp)
    8000667e:	e8ca                	sd	s2,80(sp)
    80006680:	e4ce                	sd	s3,72(sp)
    80006682:	e0d2                	sd	s4,64(sp)
    80006684:	fc56                	sd	s5,56(sp)
    80006686:	f85a                	sd	s6,48(sp)
    80006688:	f45e                	sd	s7,40(sp)
    8000668a:	f062                	sd	s8,32(sp)
    8000668c:	ec66                	sd	s9,24(sp)
    8000668e:	e86a                	sd	s10,16(sp)
    80006690:	1880                	addi	s0,sp,112
    80006692:	892a                	mv	s2,a0
    80006694:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006696:	00c52c83          	lw	s9,12(a0)
    8000669a:	001c9c9b          	slliw	s9,s9,0x1
    8000669e:	1c82                	slli	s9,s9,0x20
    800066a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800066a4:	0001f517          	auipc	a0,0x1f
    800066a8:	a8450513          	addi	a0,a0,-1404 # 80025128 <disk+0x2128>
    800066ac:	ffffa097          	auipc	ra,0xffffa
    800066b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800066b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800066b8:	0001db97          	auipc	s7,0x1d
    800066bc:	948b8b93          	addi	s7,s7,-1720 # 80023000 <disk>
    800066c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800066c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800066c4:	8a4e                	mv	s4,s3
    800066c6:	a051                	j	8000674a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800066c8:	00fb86b3          	add	a3,s7,a5
    800066cc:	96da                	add	a3,a3,s6
    800066ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800066d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800066d4:	0207c563          	bltz	a5,800066fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800066d8:	2485                	addiw	s1,s1,1
    800066da:	0711                	addi	a4,a4,4
    800066dc:	25548063          	beq	s1,s5,8000691c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800066e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800066e2:	0001f697          	auipc	a3,0x1f
    800066e6:	93668693          	addi	a3,a3,-1738 # 80025018 <disk+0x2018>
    800066ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800066ec:	0006c583          	lbu	a1,0(a3)
    800066f0:	fde1                	bnez	a1,800066c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800066f2:	2785                	addiw	a5,a5,1
    800066f4:	0685                	addi	a3,a3,1
    800066f6:	ff879be3          	bne	a5,s8,800066ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800066fa:	57fd                	li	a5,-1
    800066fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800066fe:	02905a63          	blez	s1,80006732 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006702:	f9042503          	lw	a0,-112(s0)
    80006706:	00000097          	auipc	ra,0x0
    8000670a:	d90080e7          	jalr	-624(ra) # 80006496 <free_desc>
      for(int j = 0; j < i; j++)
    8000670e:	4785                	li	a5,1
    80006710:	0297d163          	bge	a5,s1,80006732 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006714:	f9442503          	lw	a0,-108(s0)
    80006718:	00000097          	auipc	ra,0x0
    8000671c:	d7e080e7          	jalr	-642(ra) # 80006496 <free_desc>
      for(int j = 0; j < i; j++)
    80006720:	4789                	li	a5,2
    80006722:	0097d863          	bge	a5,s1,80006732 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006726:	f9842503          	lw	a0,-104(s0)
    8000672a:	00000097          	auipc	ra,0x0
    8000672e:	d6c080e7          	jalr	-660(ra) # 80006496 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006732:	0001f597          	auipc	a1,0x1f
    80006736:	9f658593          	addi	a1,a1,-1546 # 80025128 <disk+0x2128>
    8000673a:	0001f517          	auipc	a0,0x1f
    8000673e:	8de50513          	addi	a0,a0,-1826 # 80025018 <disk+0x2018>
    80006742:	ffffc097          	auipc	ra,0xffffc
    80006746:	f8c080e7          	jalr	-116(ra) # 800026ce <sleep>
  for(int i = 0; i < 3; i++){
    8000674a:	f9040713          	addi	a4,s0,-112
    8000674e:	84ce                	mv	s1,s3
    80006750:	bf41                	j	800066e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006752:	20058713          	addi	a4,a1,512
    80006756:	00471693          	slli	a3,a4,0x4
    8000675a:	0001d717          	auipc	a4,0x1d
    8000675e:	8a670713          	addi	a4,a4,-1882 # 80023000 <disk>
    80006762:	9736                	add	a4,a4,a3
    80006764:	4685                	li	a3,1
    80006766:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000676a:	20058713          	addi	a4,a1,512
    8000676e:	00471693          	slli	a3,a4,0x4
    80006772:	0001d717          	auipc	a4,0x1d
    80006776:	88e70713          	addi	a4,a4,-1906 # 80023000 <disk>
    8000677a:	9736                	add	a4,a4,a3
    8000677c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006780:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006784:	7679                	lui	a2,0xffffe
    80006786:	963e                	add	a2,a2,a5
    80006788:	0001f697          	auipc	a3,0x1f
    8000678c:	87868693          	addi	a3,a3,-1928 # 80025000 <disk+0x2000>
    80006790:	6298                	ld	a4,0(a3)
    80006792:	9732                	add	a4,a4,a2
    80006794:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006796:	6298                	ld	a4,0(a3)
    80006798:	9732                	add	a4,a4,a2
    8000679a:	4541                	li	a0,16
    8000679c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000679e:	6298                	ld	a4,0(a3)
    800067a0:	9732                	add	a4,a4,a2
    800067a2:	4505                	li	a0,1
    800067a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800067a8:	f9442703          	lw	a4,-108(s0)
    800067ac:	6288                	ld	a0,0(a3)
    800067ae:	962a                	add	a2,a2,a0
    800067b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800067b4:	0712                	slli	a4,a4,0x4
    800067b6:	6290                	ld	a2,0(a3)
    800067b8:	963a                	add	a2,a2,a4
    800067ba:	05890513          	addi	a0,s2,88
    800067be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800067c0:	6294                	ld	a3,0(a3)
    800067c2:	96ba                	add	a3,a3,a4
    800067c4:	40000613          	li	a2,1024
    800067c8:	c690                	sw	a2,8(a3)
  if(write)
    800067ca:	140d0063          	beqz	s10,8000690a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800067ce:	0001f697          	auipc	a3,0x1f
    800067d2:	8326b683          	ld	a3,-1998(a3) # 80025000 <disk+0x2000>
    800067d6:	96ba                	add	a3,a3,a4
    800067d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067dc:	0001d817          	auipc	a6,0x1d
    800067e0:	82480813          	addi	a6,a6,-2012 # 80023000 <disk>
    800067e4:	0001f517          	auipc	a0,0x1f
    800067e8:	81c50513          	addi	a0,a0,-2020 # 80025000 <disk+0x2000>
    800067ec:	6114                	ld	a3,0(a0)
    800067ee:	96ba                	add	a3,a3,a4
    800067f0:	00c6d603          	lhu	a2,12(a3)
    800067f4:	00166613          	ori	a2,a2,1
    800067f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067fc:	f9842683          	lw	a3,-104(s0)
    80006800:	6110                	ld	a2,0(a0)
    80006802:	9732                	add	a4,a4,a2
    80006804:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006808:	20058613          	addi	a2,a1,512
    8000680c:	0612                	slli	a2,a2,0x4
    8000680e:	9642                	add	a2,a2,a6
    80006810:	577d                	li	a4,-1
    80006812:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006816:	00469713          	slli	a4,a3,0x4
    8000681a:	6114                	ld	a3,0(a0)
    8000681c:	96ba                	add	a3,a3,a4
    8000681e:	03078793          	addi	a5,a5,48
    80006822:	97c2                	add	a5,a5,a6
    80006824:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006826:	611c                	ld	a5,0(a0)
    80006828:	97ba                	add	a5,a5,a4
    8000682a:	4685                	li	a3,1
    8000682c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000682e:	611c                	ld	a5,0(a0)
    80006830:	97ba                	add	a5,a5,a4
    80006832:	4809                	li	a6,2
    80006834:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006838:	611c                	ld	a5,0(a0)
    8000683a:	973e                	add	a4,a4,a5
    8000683c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006840:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006844:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006848:	6518                	ld	a4,8(a0)
    8000684a:	00275783          	lhu	a5,2(a4)
    8000684e:	8b9d                	andi	a5,a5,7
    80006850:	0786                	slli	a5,a5,0x1
    80006852:	97ba                	add	a5,a5,a4
    80006854:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006858:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000685c:	6518                	ld	a4,8(a0)
    8000685e:	00275783          	lhu	a5,2(a4)
    80006862:	2785                	addiw	a5,a5,1
    80006864:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006868:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000686c:	100017b7          	lui	a5,0x10001
    80006870:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006874:	00492703          	lw	a4,4(s2)
    80006878:	4785                	li	a5,1
    8000687a:	02f71163          	bne	a4,a5,8000689c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000687e:	0001f997          	auipc	s3,0x1f
    80006882:	8aa98993          	addi	s3,s3,-1878 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006886:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006888:	85ce                	mv	a1,s3
    8000688a:	854a                	mv	a0,s2
    8000688c:	ffffc097          	auipc	ra,0xffffc
    80006890:	e42080e7          	jalr	-446(ra) # 800026ce <sleep>
  while(b->disk == 1) {
    80006894:	00492783          	lw	a5,4(s2)
    80006898:	fe9788e3          	beq	a5,s1,80006888 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000689c:	f9042903          	lw	s2,-112(s0)
    800068a0:	20090793          	addi	a5,s2,512
    800068a4:	00479713          	slli	a4,a5,0x4
    800068a8:	0001c797          	auipc	a5,0x1c
    800068ac:	75878793          	addi	a5,a5,1880 # 80023000 <disk>
    800068b0:	97ba                	add	a5,a5,a4
    800068b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800068b6:	0001e997          	auipc	s3,0x1e
    800068ba:	74a98993          	addi	s3,s3,1866 # 80025000 <disk+0x2000>
    800068be:	00491713          	slli	a4,s2,0x4
    800068c2:	0009b783          	ld	a5,0(s3)
    800068c6:	97ba                	add	a5,a5,a4
    800068c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068cc:	854a                	mv	a0,s2
    800068ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068d2:	00000097          	auipc	ra,0x0
    800068d6:	bc4080e7          	jalr	-1084(ra) # 80006496 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068da:	8885                	andi	s1,s1,1
    800068dc:	f0ed                	bnez	s1,800068be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068de:	0001f517          	auipc	a0,0x1f
    800068e2:	84a50513          	addi	a0,a0,-1974 # 80025128 <disk+0x2128>
    800068e6:	ffffa097          	auipc	ra,0xffffa
    800068ea:	3c4080e7          	jalr	964(ra) # 80000caa <release>
}
    800068ee:	70a6                	ld	ra,104(sp)
    800068f0:	7406                	ld	s0,96(sp)
    800068f2:	64e6                	ld	s1,88(sp)
    800068f4:	6946                	ld	s2,80(sp)
    800068f6:	69a6                	ld	s3,72(sp)
    800068f8:	6a06                	ld	s4,64(sp)
    800068fa:	7ae2                	ld	s5,56(sp)
    800068fc:	7b42                	ld	s6,48(sp)
    800068fe:	7ba2                	ld	s7,40(sp)
    80006900:	7c02                	ld	s8,32(sp)
    80006902:	6ce2                	ld	s9,24(sp)
    80006904:	6d42                	ld	s10,16(sp)
    80006906:	6165                	addi	sp,sp,112
    80006908:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000690a:	0001e697          	auipc	a3,0x1e
    8000690e:	6f66b683          	ld	a3,1782(a3) # 80025000 <disk+0x2000>
    80006912:	96ba                	add	a3,a3,a4
    80006914:	4609                	li	a2,2
    80006916:	00c69623          	sh	a2,12(a3)
    8000691a:	b5c9                	j	800067dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000691c:	f9042583          	lw	a1,-112(s0)
    80006920:	20058793          	addi	a5,a1,512
    80006924:	0792                	slli	a5,a5,0x4
    80006926:	0001c517          	auipc	a0,0x1c
    8000692a:	78250513          	addi	a0,a0,1922 # 800230a8 <disk+0xa8>
    8000692e:	953e                	add	a0,a0,a5
  if(write)
    80006930:	e20d11e3          	bnez	s10,80006752 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006934:	20058713          	addi	a4,a1,512
    80006938:	00471693          	slli	a3,a4,0x4
    8000693c:	0001c717          	auipc	a4,0x1c
    80006940:	6c470713          	addi	a4,a4,1732 # 80023000 <disk>
    80006944:	9736                	add	a4,a4,a3
    80006946:	0a072423          	sw	zero,168(a4)
    8000694a:	b505                	j	8000676a <virtio_disk_rw+0xf4>

000000008000694c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000694c:	1101                	addi	sp,sp,-32
    8000694e:	ec06                	sd	ra,24(sp)
    80006950:	e822                	sd	s0,16(sp)
    80006952:	e426                	sd	s1,8(sp)
    80006954:	e04a                	sd	s2,0(sp)
    80006956:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006958:	0001e517          	auipc	a0,0x1e
    8000695c:	7d050513          	addi	a0,a0,2000 # 80025128 <disk+0x2128>
    80006960:	ffffa097          	auipc	ra,0xffffa
    80006964:	284080e7          	jalr	644(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006968:	10001737          	lui	a4,0x10001
    8000696c:	533c                	lw	a5,96(a4)
    8000696e:	8b8d                	andi	a5,a5,3
    80006970:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006972:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006976:	0001e797          	auipc	a5,0x1e
    8000697a:	68a78793          	addi	a5,a5,1674 # 80025000 <disk+0x2000>
    8000697e:	6b94                	ld	a3,16(a5)
    80006980:	0207d703          	lhu	a4,32(a5)
    80006984:	0026d783          	lhu	a5,2(a3)
    80006988:	06f70163          	beq	a4,a5,800069ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000698c:	0001c917          	auipc	s2,0x1c
    80006990:	67490913          	addi	s2,s2,1652 # 80023000 <disk>
    80006994:	0001e497          	auipc	s1,0x1e
    80006998:	66c48493          	addi	s1,s1,1644 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000699c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069a0:	6898                	ld	a4,16(s1)
    800069a2:	0204d783          	lhu	a5,32(s1)
    800069a6:	8b9d                	andi	a5,a5,7
    800069a8:	078e                	slli	a5,a5,0x3
    800069aa:	97ba                	add	a5,a5,a4
    800069ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069ae:	20078713          	addi	a4,a5,512
    800069b2:	0712                	slli	a4,a4,0x4
    800069b4:	974a                	add	a4,a4,s2
    800069b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800069ba:	e731                	bnez	a4,80006a06 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069bc:	20078793          	addi	a5,a5,512
    800069c0:	0792                	slli	a5,a5,0x4
    800069c2:	97ca                	add	a5,a5,s2
    800069c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800069c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069ca:	ffffc097          	auipc	ra,0xffffc
    800069ce:	eac080e7          	jalr	-340(ra) # 80002876 <wakeup>

    disk.used_idx += 1;
    800069d2:	0204d783          	lhu	a5,32(s1)
    800069d6:	2785                	addiw	a5,a5,1
    800069d8:	17c2                	slli	a5,a5,0x30
    800069da:	93c1                	srli	a5,a5,0x30
    800069dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069e0:	6898                	ld	a4,16(s1)
    800069e2:	00275703          	lhu	a4,2(a4)
    800069e6:	faf71be3          	bne	a4,a5,8000699c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800069ea:	0001e517          	auipc	a0,0x1e
    800069ee:	73e50513          	addi	a0,a0,1854 # 80025128 <disk+0x2128>
    800069f2:	ffffa097          	auipc	ra,0xffffa
    800069f6:	2b8080e7          	jalr	696(ra) # 80000caa <release>
}
    800069fa:	60e2                	ld	ra,24(sp)
    800069fc:	6442                	ld	s0,16(sp)
    800069fe:	64a2                	ld	s1,8(sp)
    80006a00:	6902                	ld	s2,0(sp)
    80006a02:	6105                	addi	sp,sp,32
    80006a04:	8082                	ret
      panic("virtio_disk_intr status");
    80006a06:	00002517          	auipc	a0,0x2
    80006a0a:	ea250513          	addi	a0,a0,-350 # 800088a8 <syscalls+0x3c8>
    80006a0e:	ffffa097          	auipc	ra,0xffffa
    80006a12:	b30080e7          	jalr	-1232(ra) # 8000053e <panic>

0000000080006a16 <cas>:
    80006a16:	100522af          	lr.w	t0,(a0)
    80006a1a:	00b29563          	bne	t0,a1,80006a24 <fail>
    80006a1e:	18c5252f          	sc.w	a0,a2,(a0)
    80006a22:	8082                	ret

0000000080006a24 <fail>:
    80006a24:	4505                	li	a0,1
    80006a26:	8082                	ret
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
