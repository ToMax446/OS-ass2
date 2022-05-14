
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
    80000068:	7bc78793          	addi	a5,a5,1980 # 80006820 <timervec>
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
    80000130:	fbe080e7          	jalr	-66(ra) # 800030ea <either_copyin>
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
    800001c8:	138080e7          	jalr	312(ra) # 800022fc <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	a88080e7          	jalr	-1400(ra) # 80002c5c <sleep>
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
    80000214:	e74080e7          	jalr	-396(ra) # 80003084 <either_copyout>
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
    800002f6:	e5e080e7          	jalr	-418(ra) # 80003150 <procdump>
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
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	9c2080e7          	jalr	-1598(ra) # 80002e08 <wakeup>
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
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	1c878793          	addi	a5,a5,456 # 80021640 <devsw>
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
    80000570:	ec450513          	addi	a0,a0,-316 # 80008430 <digits+0x3f0>
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
    800008a4:	568080e7          	jalr	1384(ra) # 80002e08 <wakeup>
    
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
    80000930:	330080e7          	jalr	816(ra) # 80002c5c <sleep>
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
    80000b82:	762080e7          	jalr	1890(ra) # 800022e0 <mycpu>
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
    80000bb4:	730080e7          	jalr	1840(ra) # 800022e0 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	724080e7          	jalr	1828(ra) # 800022e0 <mycpu>
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
    80000bd8:	70c080e7          	jalr	1804(ra) # 800022e0 <mycpu>
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
    80000c18:	6cc080e7          	jalr	1740(ra) # 800022e0 <mycpu>
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
    80000c56:	68e080e7          	jalr	1678(ra) # 800022e0 <mycpu>
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
    80000ebe:	416080e7          	jalr	1046(ra) # 800022d0 <cpuid>
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
    80000eda:	3fa080e7          	jalr	1018(ra) # 800022d0 <cpuid>
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
    80000efc:	406080e7          	jalr	1030(ra) # 800032fe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00006097          	auipc	ra,0x6
    80000f04:	960080e7          	jalr	-1696(ra) # 80006860 <plicinithart>
  }

  scheduler();        
    80000f08:	00002097          	auipc	ra,0x2
    80000f0c:	a70080e7          	jalr	-1424(ra) # 80002978 <scheduler>
    consoleinit();
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	540080e7          	jalr	1344(ra) # 80000450 <consoleinit>
    printfinit();
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	856080e7          	jalr	-1962(ra) # 8000076e <printfinit>
    printf("\n");
    80000f20:	00007517          	auipc	a0,0x7
    80000f24:	51050513          	addi	a0,a0,1296 # 80008430 <digits+0x3f0>
    80000f28:	fffff097          	auipc	ra,0xfffff
    80000f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	19850513          	addi	a0,a0,408 # 800080c8 <digits+0x88>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	4f050513          	addi	a0,a0,1264 # 80008430 <digits+0x3f0>
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
    80000f6c:	21e080e7          	jalr	542(ra) # 80002186 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	366080e7          	jalr	870(ra) # 800032d6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	386080e7          	jalr	902(ra) # 800032fe <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00006097          	auipc	ra,0x6
    80000f84:	8ca080e7          	jalr	-1846(ra) # 8000684a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00006097          	auipc	ra,0x6
    80000f8c:	8d8080e7          	jalr	-1832(ra) # 80006860 <plicinithart>
    binit();         // buffer cache
    80000f90:	00003097          	auipc	ra,0x3
    80000f94:	ab0080e7          	jalr	-1360(ra) # 80003a40 <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	140080e7          	jalr	320(ra) # 800040d8 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	0ea080e7          	jalr	234(ra) # 8000508a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00006097          	auipc	ra,0x6
    80000fac:	9da080e7          	jalr	-1574(ra) # 80006982 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	6b4080e7          	jalr	1716(ra) # 80002664 <userinit>
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
    80001268:	e8c080e7          	jalr	-372(ra) # 800020f0 <proc_mapstacks>
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
    80001862:	711d                	addi	sp,sp,-96
    80001864:	ec86                	sd	ra,88(sp)
    80001866:	e8a2                	sd	s0,80(sp)
    80001868:	e4a6                	sd	s1,72(sp)
    8000186a:	e0ca                	sd	s2,64(sp)
    8000186c:	fc4e                	sd	s3,56(sp)
    8000186e:	f852                	sd	s4,48(sp)
    80001870:	f456                	sd	s5,40(sp)
    80001872:	f05a                	sd	s6,32(sp)
    80001874:	ec5e                	sd	s7,24(sp)
    80001876:	e862                	sd	s8,16(sp)
    80001878:	e466                	sd	s9,8(sp)
    8000187a:	1080                	addi	s0,sp,96
    8000187c:	8caa                	mv	s9,a0
    8000187e:	892e                	mv	s2,a1
    80001880:	8a32                	mv	s4,a2
printf("p->index%d\n", p->index);
    80001882:	5e0c                	lw	a1,56(a2)
    80001884:	00007517          	auipc	a0,0x7
    80001888:	97c50513          	addi	a0,a0,-1668 # 80008200 <digits+0x1c0>
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	cfc080e7          	jalr	-772(ra) # 80000588 <printf>
printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
    80001894:	03892603          	lw	a2,56(s2) # 1038 <_entry-0x7fffefc8>
    80001898:	038ca583          	lw	a1,56(s9)
    8000189c:	00007517          	auipc	a0,0x7
    800018a0:	97450513          	addi	a0,a0,-1676 # 80008210 <digits+0x1d0>
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	ce4080e7          	jalr	-796(ra) # 80000588 <printf>
  while (curr->index <= p->index) {
    800018ac:	03892783          	lw	a5,56(s2)
    800018b0:	038a2703          	lw	a4,56(s4) # fffffffffffff038 <end+0xffffffff7ffd9038>
    800018b4:	0cf74163          	blt	a4,a5,80001976 <remove_cs+0x114>
  if ( p->index == curr->index) {
      pred->next = curr->next;
      return curr->index; 
    }
  release(&pred->lock);
  printf("%d\n",132);
    800018b8:	00007c17          	auipc	s8,0x7
    800018bc:	070c0c13          	addi	s8,s8,112 # 80008928 <states.1768+0x168>
   printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
    800018c0:	00007997          	auipc	s3,0x7
    800018c4:	95098993          	addi	s3,s3,-1712 # 80008210 <digits+0x1d0>
    pred = curr;
    curr = &proc[curr->next];
    800018c8:	17000b93          	li	s7,368
    800018cc:	00010b17          	auipc	s6,0x10
    800018d0:	f2cb0b13          	addi	s6,s6,-212 # 800117f8 <proc>
    printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
    acquire(&curr->lock);
    printf("after lock\n");
    800018d4:	00007a97          	auipc	s5,0x7
    800018d8:	954a8a93          	addi	s5,s5,-1708 # 80008228 <digits+0x1e8>
    800018dc:	a011                	j	800018e0 <remove_cs+0x7e>
    curr = &proc[curr->next];
    800018de:	8926                	mv	s2,s1
  if ( p->index == curr->index) {
    800018e0:	06e78763          	beq	a5,a4,8000194e <remove_cs+0xec>
  release(&pred->lock);
    800018e4:	8566                	mv	a0,s9
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	3c4080e7          	jalr	964(ra) # 80000caa <release>
  printf("%d\n",132);
    800018ee:	08400593          	li	a1,132
    800018f2:	8562                	mv	a0,s8
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	c94080e7          	jalr	-876(ra) # 80000588 <printf>
   printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
    800018fc:	03892603          	lw	a2,56(s2)
    80001900:	038ca583          	lw	a1,56(s9)
    80001904:	854e                	mv	a0,s3
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	c82080e7          	jalr	-894(ra) # 80000588 <printf>
    curr = &proc[curr->next];
    8000190e:	03c92483          	lw	s1,60(s2)
    80001912:	2481                	sext.w	s1,s1
    80001914:	037484b3          	mul	s1,s1,s7
    80001918:	94da                	add	s1,s1,s6
    printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
    8000191a:	5c90                	lw	a2,56(s1)
    8000191c:	03892583          	lw	a1,56(s2)
    80001920:	854e                	mv	a0,s3
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	c66080e7          	jalr	-922(ra) # 80000588 <printf>
    acquire(&curr->lock);
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	2b8080e7          	jalr	696(ra) # 80000be4 <acquire>
    printf("after lock\n");
    80001934:	8556                	mv	a0,s5
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	c52080e7          	jalr	-942(ra) # 80000588 <printf>
  while (curr->index <= p->index) {
    8000193e:	5c9c                	lw	a5,56(s1)
    80001940:	038a2703          	lw	a4,56(s4)
    80001944:	8cca                	mv	s9,s2
    80001946:	f8f75ce3          	bge	a4,a5,800018de <remove_cs+0x7c>
  }

return -1;
    8000194a:	557d                	li	a0,-1
    8000194c:	a801                	j	8000195c <remove_cs+0xfa>
      pred->next = curr->next;
    8000194e:	03c92783          	lw	a5,60(s2)
    80001952:	2781                	sext.w	a5,a5
    80001954:	02fcae23          	sw	a5,60(s9)
      return curr->index; 
    80001958:	03892503          	lw	a0,56(s2)
}
    8000195c:	60e6                	ld	ra,88(sp)
    8000195e:	6446                	ld	s0,80(sp)
    80001960:	64a6                	ld	s1,72(sp)
    80001962:	6906                	ld	s2,64(sp)
    80001964:	79e2                	ld	s3,56(sp)
    80001966:	7a42                	ld	s4,48(sp)
    80001968:	7aa2                	ld	s5,40(sp)
    8000196a:	7b02                	ld	s6,32(sp)
    8000196c:	6be2                	ld	s7,24(sp)
    8000196e:	6c42                	ld	s8,16(sp)
    80001970:	6ca2                	ld	s9,8(sp)
    80001972:	6125                	addi	sp,sp,96
    80001974:	8082                	ret
return -1;
    80001976:	557d                	li	a0,-1
    80001978:	b7d5                	j	8000195c <remove_cs+0xfa>

000000008000197a <remove_from_list>:

int
remove_from_list(struct proc *p){ //created
    8000197a:	7139                	addi	sp,sp,-64
    8000197c:	fc06                	sd	ra,56(sp)
    8000197e:	f822                	sd	s0,48(sp)
    80001980:	f426                	sd	s1,40(sp)
    80001982:	f04a                	sd	s2,32(sp)
    80001984:	ec4e                	sd	s3,24(sp)
    80001986:	e852                	sd	s4,16(sp)
    80001988:	e456                	sd	s5,8(sp)
    8000198a:	e05a                	sd	s6,0(sp)
    8000198c:	0080                	addi	s0,sp,64
    8000198e:	84aa                	mv	s1,a0
  printf("entered remove_from_list\n");
    80001990:	00007517          	auipc	a0,0x7
    80001994:	8a850513          	addi	a0,a0,-1880 # 80008238 <digits+0x1f8>
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	bf0080e7          	jalr	-1040(ra) # 80000588 <printf>
  struct proc *pred;
  struct proc *curr;
  int ret=-1;
  switch (p->state)
    800019a0:	4c9c                	lw	a5,24(s1)
    800019a2:	470d                	li	a4,3
    800019a4:	1ce78e63          	beq	a5,a4,80001b80 <remove_from_list+0x206>
    800019a8:	0af76963          	bltu	a4,a5,80001a5a <remove_from_list+0xe0>
    800019ac:	14078263          	beqz	a5,80001af0 <remove_from_list+0x176>
    800019b0:	4709                	li	a4,2
    800019b2:	2ee79e63          	bne	a5,a4,80001cae <remove_from_list+0x334>
  {
  case SLEEPING:
    acquire(&sleeping_head);
    800019b6:	00010a17          	auipc	s4,0x10
    800019ba:	8eaa0a13          	addi	s4,s4,-1814 # 800112a0 <sleeping_head>
    800019be:	8552                	mv	a0,s4
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	224080e7          	jalr	548(ra) # 80000be4 <acquire>
    pred=&proc[sleeping];
    800019c8:	00007997          	auipc	s3,0x7
    800019cc:	3549a983          	lw	s3,852(s3) # 80008d1c <sleeping>
    800019d0:	17000b13          	li	s6,368
    800019d4:	036989b3          	mul	s3,s3,s6
    800019d8:	00010a97          	auipc	s5,0x10
    800019dc:	e20a8a93          	addi	s5,s5,-480 # 800117f8 <proc>
    800019e0:	99d6                	add	s3,s3,s5
    acquire(&pred->lock);
    800019e2:	854e                	mv	a0,s3
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	200080e7          	jalr	512(ra) # 80000be4 <acquire>
    curr=&proc[pred->next];
    800019ec:	03c9a903          	lw	s2,60(s3)
    800019f0:	2901                	sext.w	s2,s2
    800019f2:	03690933          	mul	s2,s2,s6
    800019f6:	9956                	add	s2,s2,s5
    acquire(&curr->lock);
    800019f8:	854a                	mv	a0,s2
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	1ea080e7          	jalr	490(ra) # 80000be4 <acquire>
    ret=remove_cs(pred, curr, p);
    80001a02:	8626                	mv	a2,s1
    80001a04:	85ca                	mv	a1,s2
    80001a06:	854e                	mv	a0,s3
    80001a08:	00000097          	auipc	ra,0x0
    80001a0c:	e5a080e7          	jalr	-422(ra) # 80001862 <remove_cs>
    80001a10:	84aa                	mv	s1,a0
    release(&curr->lock);
    80001a12:	854a                	mv	a0,s2
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	296080e7          	jalr	662(ra) # 80000caa <release>
    release(&pred->lock);
    80001a1c:	854e                	mv	a0,s3
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	28c080e7          	jalr	652(ra) # 80000caa <release>
    release(&sleeping_head);
    80001a26:	8552                	mv	a0,s4
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	282080e7          	jalr	642(ra) # 80000caa <release>
    printf("%d",158); //2
    80001a30:	09e00593          	li	a1,158
    80001a34:	00007517          	auipc	a0,0x7
    80001a38:	82450513          	addi	a0,a0,-2012 # 80008258 <digits+0x218>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	b4c080e7          	jalr	-1204(ra) # 80000588 <printf>
    printf("the problem is here\n");
    break;
  }

  return p->index;
}
    80001a44:	8526                	mv	a0,s1
    80001a46:	70e2                	ld	ra,56(sp)
    80001a48:	7442                	ld	s0,48(sp)
    80001a4a:	74a2                	ld	s1,40(sp)
    80001a4c:	7902                	ld	s2,32(sp)
    80001a4e:	69e2                	ld	s3,24(sp)
    80001a50:	6a42                	ld	s4,16(sp)
    80001a52:	6aa2                	ld	s5,8(sp)
    80001a54:	6b02                	ld	s6,0(sp)
    80001a56:	6121                	addi	sp,sp,64
    80001a58:	8082                	ret
  switch (p->state)
    80001a5a:	4715                	li	a4,5
    80001a5c:	24e79963          	bne	a5,a4,80001cae <remove_from_list+0x334>
    acquire(&zombie_head);
    80001a60:	00010a17          	auipc	s4,0x10
    80001a64:	858a0a13          	addi	s4,s4,-1960 # 800112b8 <zombie_head>
    80001a68:	8552                	mv	a0,s4
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	17a080e7          	jalr	378(ra) # 80000be4 <acquire>
    pred=&proc[zombie];
    80001a72:	00007997          	auipc	s3,0x7
    80001a76:	2a69a983          	lw	s3,678(s3) # 80008d18 <zombie>
    80001a7a:	17000b13          	li	s6,368
    80001a7e:	036989b3          	mul	s3,s3,s6
    80001a82:	00010a97          	auipc	s5,0x10
    80001a86:	d76a8a93          	addi	s5,s5,-650 # 800117f8 <proc>
    80001a8a:	99d6                	add	s3,s3,s5
    acquire(&pred->lock);
    80001a8c:	854e                	mv	a0,s3
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	156080e7          	jalr	342(ra) # 80000be4 <acquire>
    curr=&proc[pred->next];
    80001a96:	03c9a903          	lw	s2,60(s3)
    80001a9a:	2901                	sext.w	s2,s2
    80001a9c:	03690933          	mul	s2,s2,s6
    80001aa0:	9956                	add	s2,s2,s5
    acquire(&curr->lock);
    80001aa2:	854a                	mv	a0,s2
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	140080e7          	jalr	320(ra) # 80000be4 <acquire>
    ret=remove_cs(pred, curr, p);
    80001aac:	8626                	mv	a2,s1
    80001aae:	85ca                	mv	a1,s2
    80001ab0:	854e                	mv	a0,s3
    80001ab2:	00000097          	auipc	ra,0x0
    80001ab6:	db0080e7          	jalr	-592(ra) # 80001862 <remove_cs>
    80001aba:	84aa                	mv	s1,a0
    release(&curr->lock);
    80001abc:	854a                	mv	a0,s2
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	1ec080e7          	jalr	492(ra) # 80000caa <release>
    release(&pred->lock);
    80001ac6:	854e                	mv	a0,s3
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	1e2080e7          	jalr	482(ra) # 80000caa <release>
    release(&zombie_head);
    80001ad0:	8552                	mv	a0,s4
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	1d8080e7          	jalr	472(ra) # 80000caa <release>
    printf("%d",171); //3
    80001ada:	0ab00593          	li	a1,171
    80001ade:	00006517          	auipc	a0,0x6
    80001ae2:	77a50513          	addi	a0,a0,1914 # 80008258 <digits+0x218>
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	aa2080e7          	jalr	-1374(ra) # 80000588 <printf>
    return ret;
    80001aee:	bf99                	j	80001a44 <remove_from_list+0xca>
    acquire(&unused_head);
    80001af0:	0000fa17          	auipc	s4,0xf
    80001af4:	7e0a0a13          	addi	s4,s4,2016 # 800112d0 <unused_head>
    80001af8:	8552                	mv	a0,s4
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	0ea080e7          	jalr	234(ra) # 80000be4 <acquire>
    pred = &proc[unused];
    80001b02:	00007917          	auipc	s2,0x7
    80001b06:	21292903          	lw	s2,530(s2) # 80008d14 <unused>
    80001b0a:	17000b13          	li	s6,368
    80001b0e:	03690933          	mul	s2,s2,s6
    80001b12:	00010a97          	auipc	s5,0x10
    80001b16:	ce6a8a93          	addi	s5,s5,-794 # 800117f8 <proc>
    80001b1a:	9956                	add	s2,s2,s5
    printf("pred lock: %s\n", pred->lock.name);
    80001b1c:	00893583          	ld	a1,8(s2)
    80001b20:	00006517          	auipc	a0,0x6
    80001b24:	74050513          	addi	a0,a0,1856 # 80008260 <digits+0x220>
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	a60080e7          	jalr	-1440(ra) # 80000588 <printf>
    acquire(&pred->lock);
    80001b30:	854a                	mv	a0,s2
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	0b2080e7          	jalr	178(ra) # 80000be4 <acquire>
    curr=&proc[pred->next];
    80001b3a:	03c92983          	lw	s3,60(s2)
    80001b3e:	2981                	sext.w	s3,s3
    80001b40:	036989b3          	mul	s3,s3,s6
    80001b44:	99d6                	add	s3,s3,s5
    acquire(&curr->lock);
    80001b46:	854e                	mv	a0,s3
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	09c080e7          	jalr	156(ra) # 80000be4 <acquire>
    ret=remove_cs(pred, curr, p);
    80001b50:	8626                	mv	a2,s1
    80001b52:	85ce                	mv	a1,s3
    80001b54:	854a                	mv	a0,s2
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	d0c080e7          	jalr	-756(ra) # 80001862 <remove_cs>
    80001b5e:	84aa                	mv	s1,a0
    release(&curr->lock);
    80001b60:	854e                	mv	a0,s3
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	148080e7          	jalr	328(ra) # 80000caa <release>
    release(&pred->lock);
    80001b6a:	854a                	mv	a0,s2
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	13e080e7          	jalr	318(ra) # 80000caa <release>
    release(&unused_head);
    80001b74:	8552                	mv	a0,s4
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	134080e7          	jalr	308(ra) # 80000caa <release>
    return ret;
    80001b7e:	b5d9                	j	80001a44 <remove_from_list+0xca>
       printf("entered runnable\n");
    80001b80:	00006517          	auipc	a0,0x6
    80001b84:	6f050513          	addi	a0,a0,1776 # 80008270 <digits+0x230>
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	a00080e7          	jalr	-1536(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b90:	8512                	mv	a0,tp
      acquire(&cpus_head[cpuid()]);
    80001b92:	0000f917          	auipc	s2,0xf
    80001b96:	70e90913          	addi	s2,s2,1806 # 800112a0 <sleeping_head>
    80001b9a:	0000fa17          	auipc	s4,0xf
    80001b9e:	74ea0a13          	addi	s4,s4,1870 # 800112e8 <cpus_head>
    80001ba2:	0005079b          	sext.w	a5,a0
    80001ba6:	00179513          	slli	a0,a5,0x1
    80001baa:	953e                	add	a0,a0,a5
    80001bac:	050e                	slli	a0,a0,0x3
    80001bae:	9552                	add	a0,a0,s4
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	034080e7          	jalr	52(ra) # 80000be4 <acquire>
      printf("acquire(&cpus_head[cpuid()])\n");
    80001bb8:	00006517          	auipc	a0,0x6
    80001bbc:	6d050513          	addi	a0,a0,1744 # 80008288 <digits+0x248>
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	9c8080e7          	jalr	-1592(ra) # 80000588 <printf>
    80001bc8:	8792                	mv	a5,tp
      pred = &proc[cpus_ll[cpuid()]];
    80001bca:	2781                	sext.w	a5,a5
    80001bcc:	078a                	slli	a5,a5,0x2
    80001bce:	97ca                	add	a5,a5,s2
    80001bd0:	1087a983          	lw	s3,264(a5)
    80001bd4:	17000b13          	li	s6,368
    80001bd8:	036989b3          	mul	s3,s3,s6
    80001bdc:	00010a97          	auipc	s5,0x10
    80001be0:	c1ca8a93          	addi	s5,s5,-996 # 800117f8 <proc>
    80001be4:	99d6                	add	s3,s3,s5
    80001be6:	8792                	mv	a5,tp
      printf("the index of pred is:%d\n",proc[cpus_ll[cpuid()]].index);
    80001be8:	2781                	sext.w	a5,a5
    80001bea:	078a                	slli	a5,a5,0x2
    80001bec:	97ca                	add	a5,a5,s2
    80001bee:	1087a783          	lw	a5,264(a5)
    80001bf2:	036787b3          	mul	a5,a5,s6
    80001bf6:	97d6                	add	a5,a5,s5
    80001bf8:	5f8c                	lw	a1,56(a5)
    80001bfa:	00006517          	auipc	a0,0x6
    80001bfe:	6ae50513          	addi	a0,a0,1710 # 800082a8 <digits+0x268>
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	986080e7          	jalr	-1658(ra) # 80000588 <printf>
      printf("its comes here\n");
    80001c0a:	00006517          	auipc	a0,0x6
    80001c0e:	6be50513          	addi	a0,a0,1726 # 800082c8 <digits+0x288>
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	976080e7          	jalr	-1674(ra) # 80000588 <printf>
      acquire(&pred->lock);
    80001c1a:	854e                	mv	a0,s3
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	fc8080e7          	jalr	-56(ra) # 80000be4 <acquire>
      printf("but not here\n");
    80001c24:	00006517          	auipc	a0,0x6
    80001c28:	6b450513          	addi	a0,a0,1716 # 800082d8 <digits+0x298>
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	95c080e7          	jalr	-1700(ra) # 80000588 <printf>
      printf("acquire(&pred->lock);\n");
    80001c34:	00006517          	auipc	a0,0x6
    80001c38:	6b450513          	addi	a0,a0,1716 # 800082e8 <digits+0x2a8>
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	94c080e7          	jalr	-1716(ra) # 80000588 <printf>
      curr=&proc[pred->next];
    80001c44:	03c9a903          	lw	s2,60(s3)
    80001c48:	2901                	sext.w	s2,s2
    80001c4a:	03690933          	mul	s2,s2,s6
    80001c4e:	9956                	add	s2,s2,s5
      printf("curr->pid= %d\n", curr->pid);
    80001c50:	03092583          	lw	a1,48(s2)
    80001c54:	00006517          	auipc	a0,0x6
    80001c58:	6ac50513          	addi	a0,a0,1708 # 80008300 <digits+0x2c0>
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	92c080e7          	jalr	-1748(ra) # 80000588 <printf>
      acquire(&curr->lock);
    80001c64:	854a                	mv	a0,s2
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	f7e080e7          	jalr	-130(ra) # 80000be4 <acquire>
      ret = remove_cs(pred, curr, p);
    80001c6e:	8626                	mv	a2,s1
    80001c70:	85ca                	mv	a1,s2
    80001c72:	854e                	mv	a0,s3
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	bee080e7          	jalr	-1042(ra) # 80001862 <remove_cs>
    80001c7c:	84aa                	mv	s1,a0
    80001c7e:	8512                	mv	a0,tp
      release(&cpus_head[cpuid()]);
    80001c80:	0005079b          	sext.w	a5,a0
    80001c84:	00179513          	slli	a0,a5,0x1
    80001c88:	953e                	add	a0,a0,a5
    80001c8a:	050e                	slli	a0,a0,0x3
    80001c8c:	9552                	add	a0,a0,s4
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	01c080e7          	jalr	28(ra) # 80000caa <release>
      printf("%d\n%d\n",126,ret); 
    80001c96:	8626                	mv	a2,s1
    80001c98:	07e00593          	li	a1,126
    80001c9c:	00006517          	auipc	a0,0x6
    80001ca0:	67450513          	addi	a0,a0,1652 # 80008310 <digits+0x2d0>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	8e4080e7          	jalr	-1820(ra) # 80000588 <printf>
      return ret;
    80001cac:	bb61                	j	80001a44 <remove_from_list+0xca>
    printf("the problem is here\n");
    80001cae:	00006517          	auipc	a0,0x6
    80001cb2:	66a50513          	addi	a0,a0,1642 # 80008318 <digits+0x2d8>
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	8d2080e7          	jalr	-1838(ra) # 80000588 <printf>
  return p->index;
    80001cbe:	5c84                	lw	s1,56(s1)
    80001cc0:	b351                	j	80001a44 <remove_from_list+0xca>

0000000080001cc2 <insert_cs>:

int
insert_cs(struct proc *pred, struct proc *curr, struct proc *p){  //created
    80001cc2:	715d                	addi	sp,sp,-80
    80001cc4:	e486                	sd	ra,72(sp)
    80001cc6:	e0a2                	sd	s0,64(sp)
    80001cc8:	fc26                	sd	s1,56(sp)
    80001cca:	f84a                	sd	s2,48(sp)
    80001ccc:	f44e                	sd	s3,40(sp)
    80001cce:	f052                	sd	s4,32(sp)
    80001cd0:	ec56                	sd	s5,24(sp)
    80001cd2:	e85a                	sd	s6,16(sp)
    80001cd4:	e45e                	sd	s7,8(sp)
    80001cd6:	0880                	addi	s0,sp,80
    80001cd8:	84ae                	mv	s1,a1
    80001cda:	8b32                	mv	s6,a2
  while (curr->next != -1) {
    80001cdc:	5ddc                	lw	a5,60(a1)
    80001cde:	2781                	sext.w	a5,a5
    80001ce0:	577d                	li	a4,-1
    80001ce2:	04e78863          	beq	a5,a4,80001d32 <insert_cs+0x70>
    80001ce6:	8baa                	mv	s7,a0
    printf("135 release\n");
    80001ce8:	00006a97          	auipc	s5,0x6
    80001cec:	648a8a93          	addi	s5,s5,1608 # 80008330 <digits+0x2f0>
    release(&pred->lock);
    pred = curr;
    curr = &proc[curr->next];
    80001cf0:	17000a13          	li	s4,368
    80001cf4:	00010997          	auipc	s3,0x10
    80001cf8:	b0498993          	addi	s3,s3,-1276 # 800117f8 <proc>
  while (curr->next != -1) {
    80001cfc:	597d                	li	s2,-1
    printf("135 release\n");
    80001cfe:	8556                	mv	a0,s5
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	888080e7          	jalr	-1912(ra) # 80000588 <printf>
    release(&pred->lock);
    80001d08:	855e                	mv	a0,s7
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	fa0080e7          	jalr	-96(ra) # 80000caa <release>
    curr = &proc[curr->next];
    80001d12:	5ccc                	lw	a1,60(s1)
    80001d14:	2581                	sext.w	a1,a1
    80001d16:	8ba6                	mv	s7,s1
    80001d18:	034585b3          	mul	a1,a1,s4
    80001d1c:	013584b3          	add	s1,a1,s3
    acquire(&curr->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	ec2080e7          	jalr	-318(ra) # 80000be4 <acquire>
  while (curr->next != -1) {
    80001d2a:	5cdc                	lw	a5,60(s1)
    80001d2c:	2781                	sext.w	a5,a5
    80001d2e:	fd2798e3          	bne	a5,s2,80001cfe <insert_cs+0x3c>
    }
    printf("wjdfjh\n");
    80001d32:	00006517          	auipc	a0,0x6
    80001d36:	60e50513          	addi	a0,a0,1550 # 80008340 <digits+0x300>
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	84e080e7          	jalr	-1970(ra) # 80000588 <printf>
    curr->next = p->index;
    80001d42:	038b2583          	lw	a1,56(s6)
    80001d46:	dccc                	sw	a1,60(s1)
    printf("the p->index is:%d\n",p->index);
    80001d48:	00006517          	auipc	a0,0x6
    80001d4c:	60050513          	addi	a0,a0,1536 # 80008348 <digits+0x308>
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	838080e7          	jalr	-1992(ra) # 80000588 <printf>
    p->next=-1;
    80001d58:	57fd                	li	a5,-1
    80001d5a:	02fb2e23          	sw	a5,60(s6)
    printf("183\n");
    80001d5e:	00006517          	auipc	a0,0x6
    80001d62:	60250513          	addi	a0,a0,1538 # 80008360 <digits+0x320>
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	822080e7          	jalr	-2014(ra) # 80000588 <printf>
    return p->index; 
}
    80001d6e:	038b2503          	lw	a0,56(s6)
    80001d72:	60a6                	ld	ra,72(sp)
    80001d74:	6406                	ld	s0,64(sp)
    80001d76:	74e2                	ld	s1,56(sp)
    80001d78:	7942                	ld	s2,48(sp)
    80001d7a:	79a2                	ld	s3,40(sp)
    80001d7c:	7a02                	ld	s4,32(sp)
    80001d7e:	6ae2                	ld	s5,24(sp)
    80001d80:	6b42                	ld	s6,16(sp)
    80001d82:	6ba2                	ld	s7,8(sp)
    80001d84:	6161                	addi	sp,sp,80
    80001d86:	8082                	ret

0000000080001d88 <insert_to_list>:

int
insert_to_list(struct proc *p){ //created
    80001d88:	7139                	addi	sp,sp,-64
    80001d8a:	fc06                	sd	ra,56(sp)
    80001d8c:	f822                	sd	s0,48(sp)
    80001d8e:	f426                	sd	s1,40(sp)
    80001d90:	f04a                	sd	s2,32(sp)
    80001d92:	ec4e                	sd	s3,24(sp)
    80001d94:	e852                	sd	s4,16(sp)
    80001d96:	e456                	sd	s5,8(sp)
    80001d98:	e05a                	sd	s6,0(sp)
    80001d9a:	0080                	addi	s0,sp,64
    80001d9c:	84aa                	mv	s1,a0
  printf("entered insert_to_list\n");
    80001d9e:	00006517          	auipc	a0,0x6
    80001da2:	5ca50513          	addi	a0,a0,1482 # 80008368 <digits+0x328>
    80001da6:	ffffe097          	auipc	ra,0xffffe
    80001daa:	7e2080e7          	jalr	2018(ra) # 80000588 <printf>
  struct proc *pred;
  struct proc *curr;
  int ret=-1;
  switch (p->state)
    80001dae:	4c9c                	lw	a5,24(s1)
    80001db0:	470d                	li	a4,3
    80001db2:	1ee78e63          	beq	a5,a4,80001fae <insert_to_list+0x226>
    80001db6:	0af76763          	bltu	a4,a5,80001e64 <insert_to_list+0xdc>
    80001dba:	14078963          	beqz	a5,80001f0c <insert_to_list+0x184>
    80001dbe:	4709                	li	a4,2
    80001dc0:	30e79e63          	bne	a5,a4,800020dc <insert_to_list+0x354>
  {
  case SLEEPING:
    printf("entered sleeping\n");
    80001dc4:	00006517          	auipc	a0,0x6
    80001dc8:	5bc50513          	addi	a0,a0,1468 # 80008380 <digits+0x340>
    80001dcc:	ffffe097          	auipc	ra,0xffffe
    80001dd0:	7bc080e7          	jalr	1980(ra) # 80000588 <printf>
    acquire(&sleeping_head);
    80001dd4:	0000fa17          	auipc	s4,0xf
    80001dd8:	4cca0a13          	addi	s4,s4,1228 # 800112a0 <sleeping_head>
    80001ddc:	8552                	mv	a0,s4
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	e06080e7          	jalr	-506(ra) # 80000be4 <acquire>
    pred=&proc[sleeping];
    80001de6:	00007997          	auipc	s3,0x7
    80001dea:	f369a983          	lw	s3,-202(s3) # 80008d1c <sleeping>
    80001dee:	17000b13          	li	s6,368
    80001df2:	036989b3          	mul	s3,s3,s6
    80001df6:	00010a97          	auipc	s5,0x10
    80001dfa:	a02a8a93          	addi	s5,s5,-1534 # 800117f8 <proc>
    80001dfe:	99d6                	add	s3,s3,s5
    acquire(&pred->lock);
    80001e00:	854e                	mv	a0,s3
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	de2080e7          	jalr	-542(ra) # 80000be4 <acquire>
    curr=&proc[pred->next];
    80001e0a:	03c9a903          	lw	s2,60(s3)
    80001e0e:	2901                	sext.w	s2,s2
    80001e10:	03690933          	mul	s2,s2,s6
    80001e14:	9956                	add	s2,s2,s5
    acquire(&curr->lock);
    80001e16:	854a                	mv	a0,s2
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	dcc080e7          	jalr	-564(ra) # 80000be4 <acquire>
    ret=insert_cs(pred, curr, p);
    80001e20:	8626                	mv	a2,s1
    80001e22:	85ca                	mv	a1,s2
    80001e24:	854e                	mv	a0,s3
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	e9c080e7          	jalr	-356(ra) # 80001cc2 <insert_cs>
    80001e2e:	84aa                	mv	s1,a0
    release(&curr->lock);
    80001e30:	854a                	mv	a0,s2
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e78080e7          	jalr	-392(ra) # 80000caa <release>
    release(&pred->lock);
    80001e3a:	854e                	mv	a0,s3
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e6e080e7          	jalr	-402(ra) # 80000caa <release>
    release(&sleeping_head);
    80001e44:	8552                	mv	a0,s4
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e64080e7          	jalr	-412(ra) # 80000caa <release>
    printf("the problem is here\n");
    return ret;
  }

  return p->index;
}
    80001e4e:	8526                	mv	a0,s1
    80001e50:	70e2                	ld	ra,56(sp)
    80001e52:	7442                	ld	s0,48(sp)
    80001e54:	74a2                	ld	s1,40(sp)
    80001e56:	7902                	ld	s2,32(sp)
    80001e58:	69e2                	ld	s3,24(sp)
    80001e5a:	6a42                	ld	s4,16(sp)
    80001e5c:	6aa2                	ld	s5,8(sp)
    80001e5e:	6b02                	ld	s6,0(sp)
    80001e60:	6121                	addi	sp,sp,64
    80001e62:	8082                	ret
  switch (p->state)
    80001e64:	4715                	li	a4,5
    80001e66:	26e79b63          	bne	a5,a4,800020dc <insert_to_list+0x354>
    printf("entered zombie\n");
    80001e6a:	00006517          	auipc	a0,0x6
    80001e6e:	52e50513          	addi	a0,a0,1326 # 80008398 <digits+0x358>
    80001e72:	ffffe097          	auipc	ra,0xffffe
    80001e76:	716080e7          	jalr	1814(ra) # 80000588 <printf>
    acquire(&zombie_head);
    80001e7a:	0000fa17          	auipc	s4,0xf
    80001e7e:	43ea0a13          	addi	s4,s4,1086 # 800112b8 <zombie_head>
    80001e82:	8552                	mv	a0,s4
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	d60080e7          	jalr	-672(ra) # 80000be4 <acquire>
    pred=&proc[zombie];
    80001e8c:	00007997          	auipc	s3,0x7
    80001e90:	e8c9a983          	lw	s3,-372(s3) # 80008d18 <zombie>
    80001e94:	17000b13          	li	s6,368
    80001e98:	036989b3          	mul	s3,s3,s6
    80001e9c:	00010a97          	auipc	s5,0x10
    80001ea0:	95ca8a93          	addi	s5,s5,-1700 # 800117f8 <proc>
    80001ea4:	99d6                	add	s3,s3,s5
    acquire(&pred->lock);
    80001ea6:	854e                	mv	a0,s3
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	d3c080e7          	jalr	-708(ra) # 80000be4 <acquire>
    curr=&proc[pred->next];
    80001eb0:	03c9a903          	lw	s2,60(s3)
    80001eb4:	2901                	sext.w	s2,s2
    80001eb6:	03690933          	mul	s2,s2,s6
    80001eba:	9956                	add	s2,s2,s5
    acquire(&curr->lock);
    80001ebc:	854a                	mv	a0,s2
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	d26080e7          	jalr	-730(ra) # 80000be4 <acquire>
    ret=insert_cs(pred, curr, p);
    80001ec6:	8626                	mv	a2,s1
    80001ec8:	85ca                	mv	a1,s2
    80001eca:	854e                	mv	a0,s3
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	df6080e7          	jalr	-522(ra) # 80001cc2 <insert_cs>
    80001ed4:	84aa                	mv	s1,a0
    release(&curr->lock);
    80001ed6:	854a                	mv	a0,s2
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	dd2080e7          	jalr	-558(ra) # 80000caa <release>
    release(&pred->lock);
    80001ee0:	854e                	mv	a0,s3
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	dc8080e7          	jalr	-568(ra) # 80000caa <release>
    release(&zombie_head);
    80001eea:	8552                	mv	a0,s4
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	dbe080e7          	jalr	-578(ra) # 80000caa <release>
    printf("%d\n%d\n",181,ret);
    80001ef4:	8626                	mv	a2,s1
    80001ef6:	0b500593          	li	a1,181
    80001efa:	00006517          	auipc	a0,0x6
    80001efe:	41650513          	addi	a0,a0,1046 # 80008310 <digits+0x2d0>
    80001f02:	ffffe097          	auipc	ra,0xffffe
    80001f06:	686080e7          	jalr	1670(ra) # 80000588 <printf>
    return ret;
    80001f0a:	b791                	j	80001e4e <insert_to_list+0xc6>
    printf("entered unused\n");
    80001f0c:	00006517          	auipc	a0,0x6
    80001f10:	49c50513          	addi	a0,a0,1180 # 800083a8 <digits+0x368>
    80001f14:	ffffe097          	auipc	ra,0xffffe
    80001f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    acquire(&unused_head);
    80001f1c:	0000fa17          	auipc	s4,0xf
    80001f20:	3b4a0a13          	addi	s4,s4,948 # 800112d0 <unused_head>
    80001f24:	8552                	mv	a0,s4
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	cbe080e7          	jalr	-834(ra) # 80000be4 <acquire>
    pred=&proc[unused];
    80001f2e:	00007997          	auipc	s3,0x7
    80001f32:	de69a983          	lw	s3,-538(s3) # 80008d14 <unused>
    80001f36:	17000b13          	li	s6,368
    80001f3a:	036989b3          	mul	s3,s3,s6
    80001f3e:	00010a97          	auipc	s5,0x10
    80001f42:	8baa8a93          	addi	s5,s5,-1862 # 800117f8 <proc>
    80001f46:	99d6                	add	s3,s3,s5
    acquire(&pred->lock);
    80001f48:	854e                	mv	a0,s3
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	c9a080e7          	jalr	-870(ra) # 80000be4 <acquire>
    curr=&proc[pred->next];
    80001f52:	03c9a903          	lw	s2,60(s3)
    80001f56:	2901                	sext.w	s2,s2
    80001f58:	03690933          	mul	s2,s2,s6
    80001f5c:	9956                	add	s2,s2,s5
    acquire(&curr->lock);
    80001f5e:	854a                	mv	a0,s2
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	c84080e7          	jalr	-892(ra) # 80000be4 <acquire>
    ret=insert_cs(pred, curr, p);
    80001f68:	8626                	mv	a2,s1
    80001f6a:	85ca                	mv	a1,s2
    80001f6c:	854e                	mv	a0,s3
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	d54080e7          	jalr	-684(ra) # 80001cc2 <insert_cs>
    80001f76:	84aa                	mv	s1,a0
    release(&curr->lock);
    80001f78:	854a                	mv	a0,s2
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	d30080e7          	jalr	-720(ra) # 80000caa <release>
    release(&pred->lock);
    80001f82:	854e                	mv	a0,s3
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	d26080e7          	jalr	-730(ra) # 80000caa <release>
    release(&unused_head);
    80001f8c:	8552                	mv	a0,s4
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	d1c080e7          	jalr	-740(ra) # 80000caa <release>
    printf("%d\n%d\n",195,ret); 
    80001f96:	8626                	mv	a2,s1
    80001f98:	0c300593          	li	a1,195
    80001f9c:	00006517          	auipc	a0,0x6
    80001fa0:	37450513          	addi	a0,a0,884 # 80008310 <digits+0x2d0>
    80001fa4:	ffffe097          	auipc	ra,0xffffe
    80001fa8:	5e4080e7          	jalr	1508(ra) # 80000588 <printf>
    return ret;
    80001fac:	b54d                	j	80001e4e <insert_to_list+0xc6>
    printf("entered runnable\n");
    80001fae:	00006517          	auipc	a0,0x6
    80001fb2:	2c250513          	addi	a0,a0,706 # 80008270 <digits+0x230>
    80001fb6:	ffffe097          	auipc	ra,0xffffe
    80001fba:	5d2080e7          	jalr	1490(ra) # 80000588 <printf>
    80001fbe:	8512                	mv	a0,tp
      acquire(&cpus_head[cpuid()]);
    80001fc0:	0000f917          	auipc	s2,0xf
    80001fc4:	2e090913          	addi	s2,s2,736 # 800112a0 <sleeping_head>
    80001fc8:	0000fa17          	auipc	s4,0xf
    80001fcc:	320a0a13          	addi	s4,s4,800 # 800112e8 <cpus_head>
    80001fd0:	0005079b          	sext.w	a5,a0
    80001fd4:	00179513          	slli	a0,a5,0x1
    80001fd8:	953e                	add	a0,a0,a5
    80001fda:	050e                	slli	a0,a0,0x3
    80001fdc:	9552                	add	a0,a0,s4
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	c06080e7          	jalr	-1018(ra) # 80000be4 <acquire>
      printf("acquire(&cpus_head[cpuid()])\n");
    80001fe6:	00006517          	auipc	a0,0x6
    80001fea:	2a250513          	addi	a0,a0,674 # 80008288 <digits+0x248>
    80001fee:	ffffe097          	auipc	ra,0xffffe
    80001ff2:	59a080e7          	jalr	1434(ra) # 80000588 <printf>
    80001ff6:	8792                	mv	a5,tp
      pred = &proc[cpus_ll[cpuid()]];
    80001ff8:	2781                	sext.w	a5,a5
    80001ffa:	078a                	slli	a5,a5,0x2
    80001ffc:	97ca                	add	a5,a5,s2
    80001ffe:	1087a983          	lw	s3,264(a5)
    80002002:	17000b13          	li	s6,368
    80002006:	036989b3          	mul	s3,s3,s6
    8000200a:	0000fa97          	auipc	s5,0xf
    8000200e:	7eea8a93          	addi	s5,s5,2030 # 800117f8 <proc>
    80002012:	99d6                	add	s3,s3,s5
    80002014:	8792                	mv	a5,tp
      printf("the index of pred is:%d\n",proc[cpus_ll[cpuid()]].index);
    80002016:	2781                	sext.w	a5,a5
    80002018:	078a                	slli	a5,a5,0x2
    8000201a:	97ca                	add	a5,a5,s2
    8000201c:	1087a783          	lw	a5,264(a5)
    80002020:	036787b3          	mul	a5,a5,s6
    80002024:	97d6                	add	a5,a5,s5
    80002026:	5f8c                	lw	a1,56(a5)
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	28050513          	addi	a0,a0,640 # 800082a8 <digits+0x268>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	558080e7          	jalr	1368(ra) # 80000588 <printf>
      printf("its comes here\n");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	29050513          	addi	a0,a0,656 # 800082c8 <digits+0x288>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	548080e7          	jalr	1352(ra) # 80000588 <printf>
      acquire(&pred->lock);
    80002048:	854e                	mv	a0,s3
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	b9a080e7          	jalr	-1126(ra) # 80000be4 <acquire>
      printf("but not here\n");
    80002052:	00006517          	auipc	a0,0x6
    80002056:	28650513          	addi	a0,a0,646 # 800082d8 <digits+0x298>
    8000205a:	ffffe097          	auipc	ra,0xffffe
    8000205e:	52e080e7          	jalr	1326(ra) # 80000588 <printf>
      printf("acquire(&pred->lock);\n");
    80002062:	00006517          	auipc	a0,0x6
    80002066:	28650513          	addi	a0,a0,646 # 800082e8 <digits+0x2a8>
    8000206a:	ffffe097          	auipc	ra,0xffffe
    8000206e:	51e080e7          	jalr	1310(ra) # 80000588 <printf>
      curr=&proc[pred->next];
    80002072:	03c9a903          	lw	s2,60(s3)
    80002076:	2901                	sext.w	s2,s2
    80002078:	03690933          	mul	s2,s2,s6
    8000207c:	9956                	add	s2,s2,s5
      printf("curr->pid= %d\n", curr->pid);
    8000207e:	03092583          	lw	a1,48(s2)
    80002082:	00006517          	auipc	a0,0x6
    80002086:	27e50513          	addi	a0,a0,638 # 80008300 <digits+0x2c0>
    8000208a:	ffffe097          	auipc	ra,0xffffe
    8000208e:	4fe080e7          	jalr	1278(ra) # 80000588 <printf>
      acquire(&curr->lock);
    80002092:	854a                	mv	a0,s2
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b50080e7          	jalr	-1200(ra) # 80000be4 <acquire>
      ret=insert_cs(pred, curr, p);
    8000209c:	8626                	mv	a2,s1
    8000209e:	85ca                	mv	a1,s2
    800020a0:	854e                	mv	a0,s3
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	c20080e7          	jalr	-992(ra) # 80001cc2 <insert_cs>
    800020aa:	84aa                	mv	s1,a0
    800020ac:	8512                	mv	a0,tp
      release(&cpus_head[cpuid()]);
    800020ae:	0005079b          	sext.w	a5,a0
    800020b2:	00179513          	slli	a0,a5,0x1
    800020b6:	953e                	add	a0,a0,a5
    800020b8:	050e                	slli	a0,a0,0x3
    800020ba:	9552                	add	a0,a0,s4
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	bee080e7          	jalr	-1042(ra) # 80000caa <release>
      printf("%d\n%d\n",210,ret); 
    800020c4:	8626                	mv	a2,s1
    800020c6:	0d200593          	li	a1,210
    800020ca:	00006517          	auipc	a0,0x6
    800020ce:	24650513          	addi	a0,a0,582 # 80008310 <digits+0x2d0>
    800020d2:	ffffe097          	auipc	ra,0xffffe
    800020d6:	4b6080e7          	jalr	1206(ra) # 80000588 <printf>
      return ret;
    800020da:	bb95                	j	80001e4e <insert_to_list+0xc6>
    printf("the problem is here\n");
    800020dc:	00006517          	auipc	a0,0x6
    800020e0:	23c50513          	addi	a0,a0,572 # 80008318 <digits+0x2d8>
    800020e4:	ffffe097          	auipc	ra,0xffffe
    800020e8:	4a4080e7          	jalr	1188(ra) # 80000588 <printf>
    return ret;
    800020ec:	54fd                	li	s1,-1
    800020ee:	b385                	j	80001e4e <insert_to_list+0xc6>

00000000800020f0 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800020f0:	7139                	addi	sp,sp,-64
    800020f2:	fc06                	sd	ra,56(sp)
    800020f4:	f822                	sd	s0,48(sp)
    800020f6:	f426                	sd	s1,40(sp)
    800020f8:	f04a                	sd	s2,32(sp)
    800020fa:	ec4e                	sd	s3,24(sp)
    800020fc:	e852                	sd	s4,16(sp)
    800020fe:	e456                	sd	s5,8(sp)
    80002100:	e05a                	sd	s6,0(sp)
    80002102:	0080                	addi	s0,sp,64
    80002104:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80002106:	0000f497          	auipc	s1,0xf
    8000210a:	6f248493          	addi	s1,s1,1778 # 800117f8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000210e:	8b26                	mv	s6,s1
    80002110:	00006a97          	auipc	s5,0x6
    80002114:	ef0a8a93          	addi	s5,s5,-272 # 80008000 <etext>
    80002118:	04000937          	lui	s2,0x4000
    8000211c:	197d                	addi	s2,s2,-1
    8000211e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002120:	00015a17          	auipc	s4,0x15
    80002124:	2d8a0a13          	addi	s4,s4,728 # 800173f8 <tickslock>
    char *pa = kalloc();
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	9cc080e7          	jalr	-1588(ra) # 80000af4 <kalloc>
    80002130:	862a                	mv	a2,a0
    if(pa == 0)
    80002132:	c131                	beqz	a0,80002176 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80002134:	416485b3          	sub	a1,s1,s6
    80002138:	8591                	srai	a1,a1,0x4
    8000213a:	000ab783          	ld	a5,0(s5)
    8000213e:	02f585b3          	mul	a1,a1,a5
    80002142:	2585                	addiw	a1,a1,1
    80002144:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80002148:	4719                	li	a4,6
    8000214a:	6685                	lui	a3,0x1
    8000214c:	40b905b3          	sub	a1,s2,a1
    80002150:	854e                	mv	a0,s3
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	022080e7          	jalr	34(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000215a:	17048493          	addi	s1,s1,368
    8000215e:	fd4495e3          	bne	s1,s4,80002128 <proc_mapstacks+0x38>
  }
}
    80002162:	70e2                	ld	ra,56(sp)
    80002164:	7442                	ld	s0,48(sp)
    80002166:	74a2                	ld	s1,40(sp)
    80002168:	7902                	ld	s2,32(sp)
    8000216a:	69e2                	ld	s3,24(sp)
    8000216c:	6a42                	ld	s4,16(sp)
    8000216e:	6aa2                	ld	s5,8(sp)
    80002170:	6b02                	ld	s6,0(sp)
    80002172:	6121                	addi	sp,sp,64
    80002174:	8082                	ret
      panic("kalloc");
    80002176:	00006517          	auipc	a0,0x6
    8000217a:	24250513          	addi	a0,a0,578 # 800083b8 <digits+0x378>
    8000217e:	ffffe097          	auipc	ra,0xffffe
    80002182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>

0000000080002186 <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80002186:	715d                	addi	sp,sp,-80
    80002188:	e486                	sd	ra,72(sp)
    8000218a:	e0a2                	sd	s0,64(sp)
    8000218c:	fc26                	sd	s1,56(sp)
    8000218e:	f84a                	sd	s2,48(sp)
    80002190:	f44e                	sd	s3,40(sp)
    80002192:	f052                	sd	s4,32(sp)
    80002194:	ec56                	sd	s5,24(sp)
    80002196:	e85a                	sd	s6,16(sp)
    80002198:	e45e                	sd	s7,8(sp)
    8000219a:	e062                	sd	s8,0(sp)
    8000219c:	0880                	addi	s0,sp,80
  printf("entered procinit\n");
    8000219e:	00006517          	auipc	a0,0x6
    800021a2:	22250513          	addi	a0,a0,546 # 800083c0 <digits+0x380>
    800021a6:	ffffe097          	auipc	ra,0xffffe
    800021aa:	3e2080e7          	jalr	994(ra) # 80000588 <printf>
  struct proc *p;

  for (int i = 0; i<NCPU; i++){
    800021ae:	0000f497          	auipc	s1,0xf
    800021b2:	13a48493          	addi	s1,s1,314 # 800112e8 <cpus_head>
    800021b6:	0000f997          	auipc	s3,0xf
    800021ba:	1f298993          	addi	s3,s3,498 # 800113a8 <cpus_ll>
  initlock(&cpus_head[i], "customLock");
    800021be:	00006917          	auipc	s2,0x6
    800021c2:	21a90913          	addi	s2,s2,538 # 800083d8 <digits+0x398>
    800021c6:	85ca                	mv	a1,s2
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	98a080e7          	jalr	-1654(ra) # 80000b54 <initlock>
  for (int i = 0; i<NCPU; i++){
    800021d2:	04e1                	addi	s1,s1,24
    800021d4:	fe9999e3          	bne	s3,s1,800021c6 <procinit+0x40>
}
  
  initlock(&pid_lock, "nextpid");
    800021d8:	00006597          	auipc	a1,0x6
    800021dc:	21058593          	addi	a1,a1,528 # 800083e8 <digits+0x3a8>
    800021e0:	0000f517          	auipc	a0,0xf
    800021e4:	1e850513          	addi	a0,a0,488 # 800113c8 <pid_lock>
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	96c080e7          	jalr	-1684(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800021f0:	00006597          	auipc	a1,0x6
    800021f4:	20058593          	addi	a1,a1,512 # 800083f0 <digits+0x3b0>
    800021f8:	0000f517          	auipc	a0,0xf
    800021fc:	1e850513          	addi	a0,a0,488 # 800113e0 <wait_lock>
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	954080e7          	jalr	-1708(ra) # 80000b54 <initlock>
  int i=0; //added
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
    80002208:	00006597          	auipc	a1,0x6
    8000220c:	1f858593          	addi	a1,a1,504 # 80008400 <digits+0x3c0>
    80002210:	0000f517          	auipc	a0,0xf
    80002214:	5e850513          	addi	a0,a0,1512 # 800117f8 <proc>
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	93c080e7          	jalr	-1732(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002220:	0000f497          	auipc	s1,0xf
    80002224:	5d848493          	addi	s1,s1,1496 # 800117f8 <proc>
    80002228:	040007b7          	lui	a5,0x4000
    8000222c:	17f5                	addi	a5,a5,-3
    8000222e:	07b2                	slli	a5,a5,0xc
    80002230:	e4bc                	sd	a5,72(s1)
      //added:
      p->state= UNUSED; 
    80002232:	0004ac23          	sw	zero,24(s1)
      p->index=i; 
    80002236:	0204ac23          	sw	zero,56(s1)
    8000223a:	4905                	li	s2,1
      initlock(&p->lock, "proc");
    8000223c:	00006c17          	auipc	s8,0x6
    80002240:	1c4c0c13          	addi	s8,s8,452 # 80008400 <digits+0x3c0>
      p->kstack = KSTACK((int) (p - proc));
    80002244:	8ba6                	mv	s7,s1
    80002246:	00006b17          	auipc	s6,0x6
    8000224a:	dbab0b13          	addi	s6,s6,-582 # 80008000 <etext>
    8000224e:	04000a37          	lui	s4,0x4000
    80002252:	1a7d                	addi	s4,s4,-1
    80002254:	0a32                	slli	s4,s4,0xc
      if(p == &proc[NPROC]-1){ 
    80002256:	00015a97          	auipc	s5,0x15
    8000225a:	032a8a93          	addi	s5,s5,50 # 80017288 <proc+0x5a90>
        p->next=-1;
      }
      else
        p->next=i+1;
    8000225e:	0009099b          	sext.w	s3,s2
    80002262:	0334ae23          	sw	s3,60(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80002266:	17048493          	addi	s1,s1,368
      initlock(&p->lock, "proc");
    8000226a:	85e2                	mv	a1,s8
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	8e6080e7          	jalr	-1818(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002276:	417487b3          	sub	a5,s1,s7
    8000227a:	8791                	srai	a5,a5,0x4
    8000227c:	000b3703          	ld	a4,0(s6)
    80002280:	02e787b3          	mul	a5,a5,a4
    80002284:	2785                	addiw	a5,a5,1
    80002286:	00d7979b          	slliw	a5,a5,0xd
    8000228a:	40fa07b3          	sub	a5,s4,a5
    8000228e:	e4bc                	sd	a5,72(s1)
      p->state= UNUSED; 
    80002290:	0004ac23          	sw	zero,24(s1)
      p->index=i; 
    80002294:	0334ac23          	sw	s3,56(s1)
      if(p == &proc[NPROC]-1){ 
    80002298:	2905                	addiw	s2,s2,1
    8000229a:	fd5492e3          	bne	s1,s5,8000225e <procinit+0xd8>
        p->next=-1;
    8000229e:	57fd                	li	a5,-1
    800022a0:	00015717          	auipc	a4,0x15
    800022a4:	02f72223          	sw	a5,36(a4) # 800172c4 <proc+0x5acc>
      // else{
      //   insert_to_list(p);
      //   printf("p->state while pid!=0 = %s\n", p->state);
      // } 
 // }
  printf("finished procinit\n");
    800022a8:	00006517          	auipc	a0,0x6
    800022ac:	16050513          	addi	a0,a0,352 # 80008408 <digits+0x3c8>
    800022b0:	ffffe097          	auipc	ra,0xffffe
    800022b4:	2d8080e7          	jalr	728(ra) # 80000588 <printf>
}
    800022b8:	60a6                	ld	ra,72(sp)
    800022ba:	6406                	ld	s0,64(sp)
    800022bc:	74e2                	ld	s1,56(sp)
    800022be:	7942                	ld	s2,48(sp)
    800022c0:	79a2                	ld	s3,40(sp)
    800022c2:	7a02                	ld	s4,32(sp)
    800022c4:	6ae2                	ld	s5,24(sp)
    800022c6:	6b42                	ld	s6,16(sp)
    800022c8:	6ba2                	ld	s7,8(sp)
    800022ca:	6c02                	ld	s8,0(sp)
    800022cc:	6161                	addi	sp,sp,80
    800022ce:	8082                	ret

00000000800022d0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800022d0:	1141                	addi	sp,sp,-16
    800022d2:	e422                	sd	s0,8(sp)
    800022d4:	0800                	addi	s0,sp,16
    800022d6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800022d8:	2501                	sext.w	a0,a0
    800022da:	6422                	ld	s0,8(sp)
    800022dc:	0141                	addi	sp,sp,16
    800022de:	8082                	ret

00000000800022e0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    800022e0:	1141                	addi	sp,sp,-16
    800022e2:	e422                	sd	s0,8(sp)
    800022e4:	0800                	addi	s0,sp,16
    800022e6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800022e8:	2781                	sext.w	a5,a5
    800022ea:	079e                	slli	a5,a5,0x7
  return c;
}
    800022ec:	0000f517          	auipc	a0,0xf
    800022f0:	10c50513          	addi	a0,a0,268 # 800113f8 <cpus>
    800022f4:	953e                	add	a0,a0,a5
    800022f6:	6422                	ld	s0,8(sp)
    800022f8:	0141                	addi	sp,sp,16
    800022fa:	8082                	ret

00000000800022fc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	1000                	addi	s0,sp,32
  push_off();
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	892080e7          	jalr	-1902(ra) # 80000b98 <push_off>
    8000230e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002310:	2781                	sext.w	a5,a5
    80002312:	079e                	slli	a5,a5,0x7
    80002314:	0000f717          	auipc	a4,0xf
    80002318:	f8c70713          	addi	a4,a4,-116 # 800112a0 <sleeping_head>
    8000231c:	97ba                	add	a5,a5,a4
    8000231e:	1587b483          	ld	s1,344(a5) # 4000158 <_entry-0x7bfffea8>
  pop_off();
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	928080e7          	jalr	-1752(ra) # 80000c4a <pop_off>
  return p;
}
    8000232a:	8526                	mv	a0,s1
    8000232c:	60e2                	ld	ra,24(sp)
    8000232e:	6442                	ld	s0,16(sp)
    80002330:	64a2                	ld	s1,8(sp)
    80002332:	6105                	addi	sp,sp,32
    80002334:	8082                	ret

0000000080002336 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80002336:	1141                	addi	sp,sp,-16
    80002338:	e406                	sd	ra,8(sp)
    8000233a:	e022                	sd	s0,0(sp)
    8000233c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	fbe080e7          	jalr	-66(ra) # 800022fc <myproc>
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	964080e7          	jalr	-1692(ra) # 80000caa <release>

  if (first) {
    8000234e:	00007797          	auipc	a5,0x7
    80002352:	9c27a783          	lw	a5,-1598(a5) # 80008d10 <first.1731>
    80002356:	eb89                	bnez	a5,80002368 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80002358:	00001097          	auipc	ra,0x1
    8000235c:	fbe080e7          	jalr	-66(ra) # 80003316 <usertrapret>
}
    80002360:	60a2                	ld	ra,8(sp)
    80002362:	6402                	ld	s0,0(sp)
    80002364:	0141                	addi	sp,sp,16
    80002366:	8082                	ret
    first = 0;
    80002368:	00007797          	auipc	a5,0x7
    8000236c:	9a07a423          	sw	zero,-1624(a5) # 80008d10 <first.1731>
    fsinit(ROOTDEV);
    80002370:	4505                	li	a0,1
    80002372:	00002097          	auipc	ra,0x2
    80002376:	ce6080e7          	jalr	-794(ra) # 80004058 <fsinit>
    8000237a:	bff9                	j	80002358 <forkret+0x22>

000000008000237c <allocpid>:
allocpid() { //changed as ordered in task 2
    8000237c:	1101                	addi	sp,sp,-32
    8000237e:	ec06                	sd	ra,24(sp)
    80002380:	e822                	sd	s0,16(sp)
    80002382:	e426                	sd	s1,8(sp)
    80002384:	e04a                	sd	s2,0(sp)
    80002386:	1000                	addi	s0,sp,32
      pid = nextpid;
    80002388:	00007917          	auipc	s2,0x7
    8000238c:	99890913          	addi	s2,s2,-1640 # 80008d20 <nextpid>
    80002390:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80002394:	0014861b          	addiw	a2,s1,1
    80002398:	85a6                	mv	a1,s1
    8000239a:	854a                	mv	a0,s2
    8000239c:	00005097          	auipc	ra,0x5
    800023a0:	aca080e7          	jalr	-1334(ra) # 80006e66 <cas>
    800023a4:	f575                	bnez	a0,80002390 <allocpid+0x14>
}
    800023a6:	8526                	mv	a0,s1
    800023a8:	60e2                	ld	ra,24(sp)
    800023aa:	6442                	ld	s0,16(sp)
    800023ac:	64a2                	ld	s1,8(sp)
    800023ae:	6902                	ld	s2,0(sp)
    800023b0:	6105                	addi	sp,sp,32
    800023b2:	8082                	ret

00000000800023b4 <proc_pagetable>:
{
    800023b4:	1101                	addi	sp,sp,-32
    800023b6:	ec06                	sd	ra,24(sp)
    800023b8:	e822                	sd	s0,16(sp)
    800023ba:	e426                	sd	s1,8(sp)
    800023bc:	e04a                	sd	s2,0(sp)
    800023be:	1000                	addi	s0,sp,32
    800023c0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	f9c080e7          	jalr	-100(ra) # 8000135e <uvmcreate>
    800023ca:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800023cc:	c121                	beqz	a0,8000240c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800023ce:	4729                	li	a4,10
    800023d0:	00005697          	auipc	a3,0x5
    800023d4:	c3068693          	addi	a3,a3,-976 # 80007000 <_trampoline>
    800023d8:	6605                	lui	a2,0x1
    800023da:	040005b7          	lui	a1,0x4000
    800023de:	15fd                	addi	a1,a1,-1
    800023e0:	05b2                	slli	a1,a1,0xc
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	cf2080e7          	jalr	-782(ra) # 800010d4 <mappages>
    800023ea:	02054863          	bltz	a0,8000241a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800023ee:	4719                	li	a4,6
    800023f0:	06093683          	ld	a3,96(s2)
    800023f4:	6605                	lui	a2,0x1
    800023f6:	020005b7          	lui	a1,0x2000
    800023fa:	15fd                	addi	a1,a1,-1
    800023fc:	05b6                	slli	a1,a1,0xd
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	cd4080e7          	jalr	-812(ra) # 800010d4 <mappages>
    80002408:	02054163          	bltz	a0,8000242a <proc_pagetable+0x76>
}
    8000240c:	8526                	mv	a0,s1
    8000240e:	60e2                	ld	ra,24(sp)
    80002410:	6442                	ld	s0,16(sp)
    80002412:	64a2                	ld	s1,8(sp)
    80002414:	6902                	ld	s2,0(sp)
    80002416:	6105                	addi	sp,sp,32
    80002418:	8082                	ret
    uvmfree(pagetable, 0);
    8000241a:	4581                	li	a1,0
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	13c080e7          	jalr	316(ra) # 8000155a <uvmfree>
    return 0;
    80002426:	4481                	li	s1,0
    80002428:	b7d5                	j	8000240c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000242a:	4681                	li	a3,0
    8000242c:	4605                	li	a2,1
    8000242e:	040005b7          	lui	a1,0x4000
    80002432:	15fd                	addi	a1,a1,-1
    80002434:	05b2                	slli	a1,a1,0xc
    80002436:	8526                	mv	a0,s1
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	e62080e7          	jalr	-414(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80002440:	4581                	li	a1,0
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	116080e7          	jalr	278(ra) # 8000155a <uvmfree>
    return 0;
    8000244c:	4481                	li	s1,0
    8000244e:	bf7d                	j	8000240c <proc_pagetable+0x58>

0000000080002450 <proc_freepagetable>:
{
    80002450:	1101                	addi	sp,sp,-32
    80002452:	ec06                	sd	ra,24(sp)
    80002454:	e822                	sd	s0,16(sp)
    80002456:	e426                	sd	s1,8(sp)
    80002458:	e04a                	sd	s2,0(sp)
    8000245a:	1000                	addi	s0,sp,32
    8000245c:	84aa                	mv	s1,a0
    8000245e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002460:	4681                	li	a3,0
    80002462:	4605                	li	a2,1
    80002464:	040005b7          	lui	a1,0x4000
    80002468:	15fd                	addi	a1,a1,-1
    8000246a:	05b2                	slli	a1,a1,0xc
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	e2e080e7          	jalr	-466(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002474:	4681                	li	a3,0
    80002476:	4605                	li	a2,1
    80002478:	020005b7          	lui	a1,0x2000
    8000247c:	15fd                	addi	a1,a1,-1
    8000247e:	05b6                	slli	a1,a1,0xd
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	e18080e7          	jalr	-488(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    8000248a:	85ca                	mv	a1,s2
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	0cc080e7          	jalr	204(ra) # 8000155a <uvmfree>
}
    80002496:	60e2                	ld	ra,24(sp)
    80002498:	6442                	ld	s0,16(sp)
    8000249a:	64a2                	ld	s1,8(sp)
    8000249c:	6902                	ld	s2,0(sp)
    8000249e:	6105                	addi	sp,sp,32
    800024a0:	8082                	ret

00000000800024a2 <freeproc>:
{
    800024a2:	1101                	addi	sp,sp,-32
    800024a4:	ec06                	sd	ra,24(sp)
    800024a6:	e822                	sd	s0,16(sp)
    800024a8:	e426                	sd	s1,8(sp)
    800024aa:	e04a                	sd	s2,0(sp)
    800024ac:	1000                	addi	s0,sp,32
    800024ae:	84aa                	mv	s1,a0
  printf("entered freeproc\n");
    800024b0:	00006517          	auipc	a0,0x6
    800024b4:	f7050513          	addi	a0,a0,-144 # 80008420 <digits+0x3e0>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	0d0080e7          	jalr	208(ra) # 80000588 <printf>
  if(p->trapframe)
    800024c0:	70a8                	ld	a0,96(s1)
    800024c2:	c509                	beqz	a0,800024cc <freeproc+0x2a>
    kfree((void*)p->trapframe);
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	534080e7          	jalr	1332(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    800024cc:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    800024d0:	6ca8                	ld	a0,88(s1)
    800024d2:	c511                	beqz	a0,800024de <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    800024d4:	68ac                	ld	a1,80(s1)
    800024d6:	00000097          	auipc	ra,0x0
    800024da:	f7a080e7          	jalr	-134(ra) # 80002450 <proc_freepagetable>
  p->pagetable = 0;
    800024de:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    800024e2:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    800024e6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800024ea:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    800024ee:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    800024f2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800024f6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800024fa:	0204a623          	sw	zero,44(s1)
  int index = remove_from_list(p);
    800024fe:	8526                	mv	a0,s1
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	47a080e7          	jalr	1146(ra) # 8000197a <remove_from_list>
    80002508:	892a                	mv	s2,a0
  p->state = UNUSED;
    8000250a:	0004ac23          	sw	zero,24(s1)
  printf("calling insert from freeproc\n");
    8000250e:	00006517          	auipc	a0,0x6
    80002512:	f2a50513          	addi	a0,a0,-214 # 80008438 <digits+0x3f8>
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	072080e7          	jalr	114(ra) # 80000588 <printf>
  insert_to_list(&proc[index]);
    8000251e:	17000513          	li	a0,368
    80002522:	02a90933          	mul	s2,s2,a0
    80002526:	0000f517          	auipc	a0,0xf
    8000252a:	2d250513          	addi	a0,a0,722 # 800117f8 <proc>
    8000252e:	954a                	add	a0,a0,s2
    80002530:	00000097          	auipc	ra,0x0
    80002534:	858080e7          	jalr	-1960(ra) # 80001d88 <insert_to_list>
  printf("exiting insert from freeproc\n");
    80002538:	00006517          	auipc	a0,0x6
    8000253c:	f2050513          	addi	a0,a0,-224 # 80008458 <digits+0x418>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	048080e7          	jalr	72(ra) # 80000588 <printf>
}
    80002548:	60e2                	ld	ra,24(sp)
    8000254a:	6442                	ld	s0,16(sp)
    8000254c:	64a2                	ld	s1,8(sp)
    8000254e:	6902                	ld	s2,0(sp)
    80002550:	6105                	addi	sp,sp,32
    80002552:	8082                	ret

0000000080002554 <allocproc>:
{
    80002554:	1101                	addi	sp,sp,-32
    80002556:	ec06                	sd	ra,24(sp)
    80002558:	e822                	sd	s0,16(sp)
    8000255a:	e426                	sd	s1,8(sp)
    8000255c:	e04a                	sd	s2,0(sp)
    8000255e:	1000                	addi	s0,sp,32
  printf("entered allocproc\n");
    80002560:	00006517          	auipc	a0,0x6
    80002564:	f1850513          	addi	a0,a0,-232 # 80008478 <digits+0x438>
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	020080e7          	jalr	32(ra) # 80000588 <printf>
  acquire(&unused_head);
    80002570:	0000f517          	auipc	a0,0xf
    80002574:	d6050513          	addi	a0,a0,-672 # 800112d0 <unused_head>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	66c080e7          	jalr	1644(ra) # 80000be4 <acquire>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002580:	0000f497          	auipc	s1,0xf
    80002584:	27848493          	addi	s1,s1,632 # 800117f8 <proc>
    80002588:	00015917          	auipc	s2,0x15
    8000258c:	e7090913          	addi	s2,s2,-400 # 800173f8 <tickslock>
    acquire(&p->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	652080e7          	jalr	1618(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    8000259a:	4c9c                	lw	a5,24(s1)
    8000259c:	cf81                	beqz	a5,800025b4 <allocproc+0x60>
      release(&p->lock);
    8000259e:	8526                	mv	a0,s1
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	70a080e7          	jalr	1802(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025a8:	17048493          	addi	s1,s1,368
    800025ac:	ff2492e3          	bne	s1,s2,80002590 <allocproc+0x3c>
  return 0;
    800025b0:	4481                	li	s1,0
    800025b2:	a895                	j	80002626 <allocproc+0xd2>
  p->pid = allocpid();
    800025b4:	00000097          	auipc	ra,0x0
    800025b8:	dc8080e7          	jalr	-568(ra) # 8000237c <allocpid>
    800025bc:	d888                	sw	a0,48(s1)
  p->state = USED;
    800025be:	4785                	li	a5,1
    800025c0:	cc9c                	sw	a5,24(s1)
  printf("allocpid, p->state= %d\n", p->state);
    800025c2:	4585                	li	a1,1
    800025c4:	00006517          	auipc	a0,0x6
    800025c8:	ecc50513          	addi	a0,a0,-308 # 80008490 <digits+0x450>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbc080e7          	jalr	-68(ra) # 80000588 <printf>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	520080e7          	jalr	1312(ra) # 80000af4 <kalloc>
    800025dc:	892a                	mv	s2,a0
    800025de:	f0a8                	sd	a0,96(s1)
    800025e0:	c931                	beqz	a0,80002634 <allocproc+0xe0>
  p->pagetable = proc_pagetable(p);
    800025e2:	8526                	mv	a0,s1
    800025e4:	00000097          	auipc	ra,0x0
    800025e8:	dd0080e7          	jalr	-560(ra) # 800023b4 <proc_pagetable>
    800025ec:	892a                	mv	s2,a0
    800025ee:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    800025f0:	cd31                	beqz	a0,8000264c <allocproc+0xf8>
  memset(&p->context, 0, sizeof(p->context));
    800025f2:	07000613          	li	a2,112
    800025f6:	4581                	li	a1,0
    800025f8:	06848513          	addi	a0,s1,104
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	708080e7          	jalr	1800(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    80002604:	00000797          	auipc	a5,0x0
    80002608:	d3278793          	addi	a5,a5,-718 # 80002336 <forkret>
    8000260c:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    8000260e:	64bc                	ld	a5,72(s1)
    80002610:	6705                	lui	a4,0x1
    80002612:	97ba                	add	a5,a5,a4
    80002614:	f8bc                	sd	a5,112(s1)
  release (&unused_head);
    80002616:	0000f517          	auipc	a0,0xf
    8000261a:	cba50513          	addi	a0,a0,-838 # 800112d0 <unused_head>
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	68c080e7          	jalr	1676(ra) # 80000caa <release>
}
    80002626:	8526                	mv	a0,s1
    80002628:	60e2                	ld	ra,24(sp)
    8000262a:	6442                	ld	s0,16(sp)
    8000262c:	64a2                	ld	s1,8(sp)
    8000262e:	6902                	ld	s2,0(sp)
    80002630:	6105                	addi	sp,sp,32
    80002632:	8082                	ret
    freeproc(p);
    80002634:	8526                	mv	a0,s1
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	e6c080e7          	jalr	-404(ra) # 800024a2 <freeproc>
    release(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	66a080e7          	jalr	1642(ra) # 80000caa <release>
    return 0;
    80002648:	84ca                	mv	s1,s2
    8000264a:	bff1                	j	80002626 <allocproc+0xd2>
    freeproc(p);
    8000264c:	8526                	mv	a0,s1
    8000264e:	00000097          	auipc	ra,0x0
    80002652:	e54080e7          	jalr	-428(ra) # 800024a2 <freeproc>
    release(&p->lock);
    80002656:	8526                	mv	a0,s1
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	652080e7          	jalr	1618(ra) # 80000caa <release>
    return 0;
    80002660:	84ca                	mv	s1,s2
    80002662:	b7d1                	j	80002626 <allocproc+0xd2>

0000000080002664 <userinit>:
{
    80002664:	1101                	addi	sp,sp,-32
    80002666:	ec06                	sd	ra,24(sp)
    80002668:	e822                	sd	s0,16(sp)
    8000266a:	e426                	sd	s1,8(sp)
    8000266c:	1000                	addi	s0,sp,32
  printf("entered userinit\n");
    8000266e:	00006517          	auipc	a0,0x6
    80002672:	e3a50513          	addi	a0,a0,-454 # 800084a8 <digits+0x468>
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	f12080e7          	jalr	-238(ra) # 80000588 <printf>
  p = allocproc();
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	ed6080e7          	jalr	-298(ra) # 80002554 <allocproc>
    80002686:	84aa                	mv	s1,a0
  printf("userinit, p->state= %d\n", p->state);
    80002688:	4d0c                	lw	a1,24(a0)
    8000268a:	00006517          	auipc	a0,0x6
    8000268e:	e3650513          	addi	a0,a0,-458 # 800084c0 <digits+0x480>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	ef6080e7          	jalr	-266(ra) # 80000588 <printf>
  initproc = p;
    8000269a:	00007797          	auipc	a5,0x7
    8000269e:	9897b723          	sd	s1,-1650(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800026a2:	03400613          	li	a2,52
    800026a6:	00006597          	auipc	a1,0x6
    800026aa:	68a58593          	addi	a1,a1,1674 # 80008d30 <initcode>
    800026ae:	6ca8                	ld	a0,88(s1)
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	cdc080e7          	jalr	-804(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    800026b8:	6785                	lui	a5,0x1
    800026ba:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    800026bc:	70b8                	ld	a4,96(s1)
    800026be:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800026c2:	70b8                	ld	a4,96(s1)
    800026c4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800026c6:	4641                	li	a2,16
    800026c8:	00006597          	auipc	a1,0x6
    800026cc:	e1058593          	addi	a1,a1,-496 # 800084d8 <digits+0x498>
    800026d0:	16048513          	addi	a0,s1,352
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	782080e7          	jalr	1922(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800026dc:	00006517          	auipc	a0,0x6
    800026e0:	e0c50513          	addi	a0,a0,-500 # 800084e8 <digits+0x4a8>
    800026e4:	00002097          	auipc	ra,0x2
    800026e8:	3a2080e7          	jalr	930(ra) # 80004a86 <namei>
    800026ec:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    800026f0:	478d                	li	a5,3
    800026f2:	cc9c                	sw	a5,24(s1)
  printf("userinit, p->state= %d\n", p->state);
    800026f4:	458d                	li	a1,3
    800026f6:	00006517          	auipc	a0,0x6
    800026fa:	dca50513          	addi	a0,a0,-566 # 800084c0 <digits+0x480>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	e8a080e7          	jalr	-374(ra) # 80000588 <printf>
    80002706:	8792                	mv	a5,tp
  cpus_ll[cpuid()]=p->index;
    80002708:	5c8c                	lw	a1,56(s1)
    8000270a:	2781                	sext.w	a5,a5
    8000270c:	078a                	slli	a5,a5,0x2
    8000270e:	0000f717          	auipc	a4,0xf
    80002712:	b9270713          	addi	a4,a4,-1134 # 800112a0 <sleeping_head>
    80002716:	97ba                	add	a5,a5,a4
    80002718:	10b7a423          	sw	a1,264(a5) # 1108 <_entry-0x7fffeef8>
  printf("userinit, p->index= %d\n", p->index);
    8000271c:	00006517          	auipc	a0,0x6
    80002720:	dd450513          	addi	a0,a0,-556 # 800084f0 <digits+0x4b0>
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	e64080e7          	jalr	-412(ra) # 80000588 <printf>
  release(&p->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	57c080e7          	jalr	1404(ra) # 80000caa <release>
  insert_to_list(p);
    80002736:	8526                	mv	a0,s1
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	650080e7          	jalr	1616(ra) # 80001d88 <insert_to_list>
    printf("calling insert from userinit\n");
    80002740:	00006517          	auipc	a0,0x6
    80002744:	dc850513          	addi	a0,a0,-568 # 80008508 <digits+0x4c8>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	e40080e7          	jalr	-448(ra) # 80000588 <printf>
  printf("exiting insert from userinit\n");
    80002750:	00006517          	auipc	a0,0x6
    80002754:	dd850513          	addi	a0,a0,-552 # 80008528 <digits+0x4e8>
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	e30080e7          	jalr	-464(ra) # 80000588 <printf>
}
    80002760:	60e2                	ld	ra,24(sp)
    80002762:	6442                	ld	s0,16(sp)
    80002764:	64a2                	ld	s1,8(sp)
    80002766:	6105                	addi	sp,sp,32
    80002768:	8082                	ret

000000008000276a <growproc>:
{
    8000276a:	1101                	addi	sp,sp,-32
    8000276c:	ec06                	sd	ra,24(sp)
    8000276e:	e822                	sd	s0,16(sp)
    80002770:	e426                	sd	s1,8(sp)
    80002772:	e04a                	sd	s2,0(sp)
    80002774:	1000                	addi	s0,sp,32
    80002776:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002778:	00000097          	auipc	ra,0x0
    8000277c:	b84080e7          	jalr	-1148(ra) # 800022fc <myproc>
    80002780:	892a                	mv	s2,a0
  sz = p->sz;
    80002782:	692c                	ld	a1,80(a0)
    80002784:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002788:	00904f63          	bgtz	s1,800027a6 <growproc+0x3c>
  } else if(n < 0){
    8000278c:	0204cc63          	bltz	s1,800027c4 <growproc+0x5a>
  p->sz = sz;
    80002790:	1602                	slli	a2,a2,0x20
    80002792:	9201                	srli	a2,a2,0x20
    80002794:	04c93823          	sd	a2,80(s2)
  return 0;
    80002798:	4501                	li	a0,0
}
    8000279a:	60e2                	ld	ra,24(sp)
    8000279c:	6442                	ld	s0,16(sp)
    8000279e:	64a2                	ld	s1,8(sp)
    800027a0:	6902                	ld	s2,0(sp)
    800027a2:	6105                	addi	sp,sp,32
    800027a4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800027a6:	9e25                	addw	a2,a2,s1
    800027a8:	1602                	slli	a2,a2,0x20
    800027aa:	9201                	srli	a2,a2,0x20
    800027ac:	1582                	slli	a1,a1,0x20
    800027ae:	9181                	srli	a1,a1,0x20
    800027b0:	6d28                	ld	a0,88(a0)
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	c94080e7          	jalr	-876(ra) # 80001446 <uvmalloc>
    800027ba:	0005061b          	sext.w	a2,a0
    800027be:	fa69                	bnez	a2,80002790 <growproc+0x26>
      return -1;
    800027c0:	557d                	li	a0,-1
    800027c2:	bfe1                	j	8000279a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800027c4:	9e25                	addw	a2,a2,s1
    800027c6:	1602                	slli	a2,a2,0x20
    800027c8:	9201                	srli	a2,a2,0x20
    800027ca:	1582                	slli	a1,a1,0x20
    800027cc:	9181                	srli	a1,a1,0x20
    800027ce:	6d28                	ld	a0,88(a0)
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	c2e080e7          	jalr	-978(ra) # 800013fe <uvmdealloc>
    800027d8:	0005061b          	sext.w	a2,a0
    800027dc:	bf55                	j	80002790 <growproc+0x26>

00000000800027de <fork>:
{
    800027de:	7179                	addi	sp,sp,-48
    800027e0:	f406                	sd	ra,40(sp)
    800027e2:	f022                	sd	s0,32(sp)
    800027e4:	ec26                	sd	s1,24(sp)
    800027e6:	e84a                	sd	s2,16(sp)
    800027e8:	e44e                	sd	s3,8(sp)
    800027ea:	e052                	sd	s4,0(sp)
    800027ec:	1800                	addi	s0,sp,48
  printf("entered fork\n");
    800027ee:	00006517          	auipc	a0,0x6
    800027f2:	d5a50513          	addi	a0,a0,-678 # 80008548 <digits+0x508>
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	d92080e7          	jalr	-622(ra) # 80000588 <printf>
  struct proc *p = myproc();
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	afe080e7          	jalr	-1282(ra) # 800022fc <myproc>
    80002806:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	d4c080e7          	jalr	-692(ra) # 80002554 <allocproc>
    80002810:	16050263          	beqz	a0,80002974 <fork+0x196>
    80002814:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002816:	05093603          	ld	a2,80(s2)
    8000281a:	6d2c                	ld	a1,88(a0)
    8000281c:	05893503          	ld	a0,88(s2)
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	d72080e7          	jalr	-654(ra) # 80001592 <uvmcopy>
    80002828:	04054663          	bltz	a0,80002874 <fork+0x96>
  np->sz = p->sz;
    8000282c:	05093783          	ld	a5,80(s2)
    80002830:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80002834:	06093683          	ld	a3,96(s2)
    80002838:	87b6                	mv	a5,a3
    8000283a:	0609b703          	ld	a4,96(s3)
    8000283e:	12068693          	addi	a3,a3,288
    80002842:	0007b803          	ld	a6,0(a5)
    80002846:	6788                	ld	a0,8(a5)
    80002848:	6b8c                	ld	a1,16(a5)
    8000284a:	6f90                	ld	a2,24(a5)
    8000284c:	01073023          	sd	a6,0(a4)
    80002850:	e708                	sd	a0,8(a4)
    80002852:	eb0c                	sd	a1,16(a4)
    80002854:	ef10                	sd	a2,24(a4)
    80002856:	02078793          	addi	a5,a5,32
    8000285a:	02070713          	addi	a4,a4,32
    8000285e:	fed792e3          	bne	a5,a3,80002842 <fork+0x64>
  np->trapframe->a0 = 0;
    80002862:	0609b783          	ld	a5,96(s3)
    80002866:	0607b823          	sd	zero,112(a5)
    8000286a:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000286e:	15800a13          	li	s4,344
    80002872:	a03d                	j	800028a0 <fork+0xc2>
    freeproc(np);
    80002874:	854e                	mv	a0,s3
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	c2c080e7          	jalr	-980(ra) # 800024a2 <freeproc>
    release(&np->lock);
    8000287e:	854e                	mv	a0,s3
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	42a080e7          	jalr	1066(ra) # 80000caa <release>
    return -1;
    80002888:	5a7d                	li	s4,-1
    8000288a:	a8e1                	j	80002962 <fork+0x184>
      np->ofile[i] = filedup(p->ofile[i]);
    8000288c:	00003097          	auipc	ra,0x3
    80002890:	890080e7          	jalr	-1904(ra) # 8000511c <filedup>
    80002894:	009987b3          	add	a5,s3,s1
    80002898:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000289a:	04a1                	addi	s1,s1,8
    8000289c:	01448763          	beq	s1,s4,800028aa <fork+0xcc>
    if(p->ofile[i])
    800028a0:	009907b3          	add	a5,s2,s1
    800028a4:	6388                	ld	a0,0(a5)
    800028a6:	f17d                	bnez	a0,8000288c <fork+0xae>
    800028a8:	bfcd                	j	8000289a <fork+0xbc>
  np->cwd = idup(p->cwd);
    800028aa:	15893503          	ld	a0,344(s2)
    800028ae:	00002097          	auipc	ra,0x2
    800028b2:	9e4080e7          	jalr	-1564(ra) # 80004292 <idup>
    800028b6:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800028ba:	4641                	li	a2,16
    800028bc:	16090593          	addi	a1,s2,352
    800028c0:	16098513          	addi	a0,s3,352
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	592080e7          	jalr	1426(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    800028cc:	0309aa03          	lw	s4,48(s3)
  np->cpu_num=p->cpu_num; //giving the child it's parent's cpu_num (the only change)
    800028d0:	03492783          	lw	a5,52(s2)
    800028d4:	02f9aa23          	sw	a5,52(s3)
  printf("559 release\n");
    800028d8:	00006517          	auipc	a0,0x6
    800028dc:	c8050513          	addi	a0,a0,-896 # 80008558 <digits+0x518>
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	ca8080e7          	jalr	-856(ra) # 80000588 <printf>
  release(&np->lock);
    800028e8:	854e                	mv	a0,s3
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	3c0080e7          	jalr	960(ra) # 80000caa <release>
  acquire(&wait_lock);
    800028f2:	0000f497          	auipc	s1,0xf
    800028f6:	aee48493          	addi	s1,s1,-1298 # 800113e0 <wait_lock>
    800028fa:	8526                	mv	a0,s1
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	2e8080e7          	jalr	744(ra) # 80000be4 <acquire>
  np->parent = p;
    80002904:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80002908:	8526                	mv	a0,s1
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	3a0080e7          	jalr	928(ra) # 80000caa <release>
  acquire(&np->lock);
    80002912:	854e                	mv	a0,s3
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	2d0080e7          	jalr	720(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000291c:	478d                	li	a5,3
    8000291e:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(np);
    80002922:	854e                	mv	a0,s3
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	464080e7          	jalr	1124(ra) # 80001d88 <insert_to_list>
  release(&np->lock);
    8000292c:	854e                	mv	a0,s3
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	37c080e7          	jalr	892(ra) # 80000caa <release>
  printf("the np->next=%d\n",np->next);
    80002936:	03c9a583          	lw	a1,60(s3)
    8000293a:	2581                	sext.w	a1,a1
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	c2c50513          	addi	a0,a0,-980 # 80008568 <digits+0x528>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c44080e7          	jalr	-956(ra) # 80000588 <printf>
  printf("the p->next=%d\n",p->next);
    8000294c:	03c92583          	lw	a1,60(s2)
    80002950:	2581                	sext.w	a1,a1
    80002952:	00006517          	auipc	a0,0x6
    80002956:	c2e50513          	addi	a0,a0,-978 # 80008580 <digits+0x540>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	c2e080e7          	jalr	-978(ra) # 80000588 <printf>
}
    80002962:	8552                	mv	a0,s4
    80002964:	70a2                	ld	ra,40(sp)
    80002966:	7402                	ld	s0,32(sp)
    80002968:	64e2                	ld	s1,24(sp)
    8000296a:	6942                	ld	s2,16(sp)
    8000296c:	69a2                	ld	s3,8(sp)
    8000296e:	6a02                	ld	s4,0(sp)
    80002970:	6145                	addi	sp,sp,48
    80002972:	8082                	ret
    return -1;
    80002974:	5a7d                	li	s4,-1
    80002976:	b7f5                	j	80002962 <fork+0x184>

0000000080002978 <scheduler>:
{
    80002978:	711d                	addi	sp,sp,-96
    8000297a:	ec86                	sd	ra,88(sp)
    8000297c:	e8a2                	sd	s0,80(sp)
    8000297e:	e4a6                	sd	s1,72(sp)
    80002980:	e0ca                	sd	s2,64(sp)
    80002982:	fc4e                	sd	s3,56(sp)
    80002984:	f852                	sd	s4,48(sp)
    80002986:	f456                	sd	s5,40(sp)
    80002988:	f05a                	sd	s6,32(sp)
    8000298a:	ec5e                	sd	s7,24(sp)
    8000298c:	e862                	sd	s8,16(sp)
    8000298e:	e466                	sd	s9,8(sp)
    80002990:	e06a                	sd	s10,0(sp)
    80002992:	1080                	addi	s0,sp,96
  printf("entered scheduler\n");
    80002994:	00006517          	auipc	a0,0x6
    80002998:	bfc50513          	addi	a0,a0,-1028 # 80008590 <digits+0x550>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	bec080e7          	jalr	-1044(ra) # 80000588 <printf>
    800029a4:	8792                	mv	a5,tp
  int id = r_tp();
    800029a6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800029a8:	00779c13          	slli	s8,a5,0x7
    800029ac:	0000f717          	auipc	a4,0xf
    800029b0:	8f470713          	addi	a4,a4,-1804 # 800112a0 <sleeping_head>
    800029b4:	9762                	add	a4,a4,s8
    800029b6:	14073c23          	sd	zero,344(a4)
        swtch(&c->context, &p->context);
    800029ba:	0000f717          	auipc	a4,0xf
    800029be:	a4670713          	addi	a4,a4,-1466 # 80011400 <cpus+0x8>
    800029c2:	9c3a                	add	s8,s8,a4
    acquire(&cpus_head[cpuid()]);
    800029c4:	0000fa17          	auipc	s4,0xf
    800029c8:	8dca0a13          	addi	s4,s4,-1828 # 800112a0 <sleeping_head>
    800029cc:	0000fb97          	auipc	s7,0xf
    800029d0:	91cb8b93          	addi	s7,s7,-1764 # 800112e8 <cpus_head>
    printf("the cpuid=%d\n",cpuid());
    800029d4:	00006d17          	auipc	s10,0x6
    800029d8:	bd4d0d13          	addi	s10,s10,-1068 # 800085a8 <digits+0x568>
    printf("the cpus_ll[cpuid()]=%d\n",cpus_ll[cpuid()]);
    800029dc:	00006c97          	auipc	s9,0x6
    800029e0:	bdcc8c93          	addi	s9,s9,-1060 # 800085b8 <digits+0x578>
    printf("the proc[cpus_ll[cpuid()]].next=%d\n",proc[cpus_ll[cpuid()]].next);
    800029e4:	0000f997          	auipc	s3,0xf
    800029e8:	e1498993          	addi	s3,s3,-492 # 800117f8 <proc>
    800029ec:	17000a93          	li	s5,368
    c->proc = p;
    800029f0:	079e                	slli	a5,a5,0x7
    800029f2:	00fa0b33          	add	s6,s4,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029fa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029fe:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a02:	8512                	mv	a0,tp
    acquire(&cpus_head[cpuid()]);
    80002a04:	0005079b          	sext.w	a5,a0
    80002a08:	00179513          	slli	a0,a5,0x1
    80002a0c:	953e                	add	a0,a0,a5
    80002a0e:	050e                	slli	a0,a0,0x3
    80002a10:	955e                	add	a0,a0,s7
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	1d2080e7          	jalr	466(ra) # 80000be4 <acquire>
    80002a1a:	8592                	mv	a1,tp
    printf("the cpuid=%d\n",cpuid());
    80002a1c:	2581                	sext.w	a1,a1
    80002a1e:	856a                	mv	a0,s10
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b68080e7          	jalr	-1176(ra) # 80000588 <printf>
    80002a28:	8792                	mv	a5,tp
    printf("the cpus_ll[cpuid()]=%d\n",cpus_ll[cpuid()]);
    80002a2a:	2781                	sext.w	a5,a5
    80002a2c:	078a                	slli	a5,a5,0x2
    80002a2e:	97d2                	add	a5,a5,s4
    80002a30:	1087a583          	lw	a1,264(a5)
    80002a34:	8566                	mv	a0,s9
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b52080e7          	jalr	-1198(ra) # 80000588 <printf>
    80002a3e:	8792                	mv	a5,tp
    printf("the proc[cpus_ll[cpuid()]].next=%d\n",proc[cpus_ll[cpuid()]].next);
    80002a40:	2781                	sext.w	a5,a5
    80002a42:	078a                	slli	a5,a5,0x2
    80002a44:	97d2                	add	a5,a5,s4
    80002a46:	1087a783          	lw	a5,264(a5)
    80002a4a:	035787b3          	mul	a5,a5,s5
    80002a4e:	97ce                	add	a5,a5,s3
    80002a50:	5fcc                	lw	a1,60(a5)
    80002a52:	2581                	sext.w	a1,a1
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	b8450513          	addi	a0,a0,-1148 # 800085d8 <digits+0x598>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	b2c080e7          	jalr	-1236(ra) # 80000588 <printf>
    80002a64:	8792                	mv	a5,tp
    p = &proc[proc[cpus_ll[cpuid()]].next];
    80002a66:	2781                	sext.w	a5,a5
    80002a68:	078a                	slli	a5,a5,0x2
    80002a6a:	97d2                	add	a5,a5,s4
    80002a6c:	1087a783          	lw	a5,264(a5)
    80002a70:	035787b3          	mul	a5,a5,s5
    80002a74:	97ce                	add	a5,a5,s3
    80002a76:	03c7a903          	lw	s2,60(a5)
    80002a7a:	2901                	sext.w	s2,s2
    80002a7c:	03590933          	mul	s2,s2,s5
    80002a80:	013904b3          	add	s1,s2,s3
    printf("the index of p after choosing:%d\n",p->index);
    80002a84:	5c8c                	lw	a1,56(s1)
    80002a86:	00006517          	auipc	a0,0x6
    80002a8a:	b7a50513          	addi	a0,a0,-1158 # 80008600 <digits+0x5c0>
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	afa080e7          	jalr	-1286(ra) # 80000588 <printf>
    printf("p.next= %d, pid=%d\n", p->next, p->pid);
    80002a96:	5ccc                	lw	a1,60(s1)
    80002a98:	5890                	lw	a2,48(s1)
    80002a9a:	2581                	sext.w	a1,a1
    80002a9c:	00006517          	auipc	a0,0x6
    80002aa0:	b8c50513          	addi	a0,a0,-1140 # 80008628 <digits+0x5e8>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	ae4080e7          	jalr	-1308(ra) # 80000588 <printf>
    80002aac:	8512                	mv	a0,tp
    release(&cpus_head[cpuid()]);
    80002aae:	0005079b          	sext.w	a5,a0
    80002ab2:	00179513          	slli	a0,a5,0x1
    80002ab6:	953e                	add	a0,a0,a5
    80002ab8:	050e                	slli	a0,a0,0x3
    80002aba:	955e                	add	a0,a0,s7
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	1ee080e7          	jalr	494(ra) # 80000caa <release>
    acquire(&p->lock);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	11e080e7          	jalr	286(ra) # 80000be4 <acquire>
    printf("after acquire and change state\n");
    80002ace:	00006517          	auipc	a0,0x6
    80002ad2:	b7250513          	addi	a0,a0,-1166 # 80008640 <digits+0x600>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	ab2080e7          	jalr	-1358(ra) # 80000588 <printf>
    remove_from_list(p);
    80002ade:	8526                	mv	a0,s1
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	e9a080e7          	jalr	-358(ra) # 8000197a <remove_from_list>
    p->state = RUNNING;
    80002ae8:	4791                	li	a5,4
    80002aea:	cc9c                	sw	a5,24(s1)
    c->proc = p;
    80002aec:	149b3c23          	sd	s1,344(s6)
        swtch(&c->context, &p->context);
    80002af0:	06890593          	addi	a1,s2,104
    80002af4:	95ce                	add	a1,a1,s3
    80002af6:	8562                	mv	a0,s8
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	774080e7          	jalr	1908(ra) # 8000326c <swtch>
        insert_to_list(p);
    80002b00:	8526                	mv	a0,s1
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	286080e7          	jalr	646(ra) # 80001d88 <insert_to_list>
        printf("exit swtc\n");
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	b5650513          	addi	a0,a0,-1194 # 80008660 <digits+0x620>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
        c->proc = 0;
    80002b1a:	140b3c23          	sd	zero,344(s6)
      release(&p->lock);
    80002b1e:	8526                	mv	a0,s1
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	18a080e7          	jalr	394(ra) # 80000caa <release>
  for(;;){
    80002b28:	b5f9                	j	800029f6 <scheduler+0x7e>

0000000080002b2a <sched>:
{
    80002b2a:	7179                	addi	sp,sp,-48
    80002b2c:	f406                	sd	ra,40(sp)
    80002b2e:	f022                	sd	s0,32(sp)
    80002b30:	ec26                	sd	s1,24(sp)
    80002b32:	e84a                	sd	s2,16(sp)
    80002b34:	e44e                	sd	s3,8(sp)
    80002b36:	1800                	addi	s0,sp,48
  printf("entered sched\n");
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	b3850513          	addi	a0,a0,-1224 # 80008670 <digits+0x630>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	a48080e7          	jalr	-1464(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	7b4080e7          	jalr	1972(ra) # 800022fc <myproc>
    80002b50:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	018080e7          	jalr	24(ra) # 80000b6a <holding>
    80002b5a:	c93d                	beqz	a0,80002bd0 <sched+0xa6>
    80002b5c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002b5e:	2781                	sext.w	a5,a5
    80002b60:	079e                	slli	a5,a5,0x7
    80002b62:	0000e717          	auipc	a4,0xe
    80002b66:	73e70713          	addi	a4,a4,1854 # 800112a0 <sleeping_head>
    80002b6a:	97ba                	add	a5,a5,a4
    80002b6c:	1d07a703          	lw	a4,464(a5)
    80002b70:	4785                	li	a5,1
    80002b72:	06f71763          	bne	a4,a5,80002be0 <sched+0xb6>
  if(p->state == RUNNING)
    80002b76:	4c98                	lw	a4,24(s1)
    80002b78:	4791                	li	a5,4
    80002b7a:	06f70b63          	beq	a4,a5,80002bf0 <sched+0xc6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b82:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002b84:	efb5                	bnez	a5,80002c00 <sched+0xd6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b86:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002b88:	0000e917          	auipc	s2,0xe
    80002b8c:	71890913          	addi	s2,s2,1816 # 800112a0 <sleeping_head>
    80002b90:	2781                	sext.w	a5,a5
    80002b92:	079e                	slli	a5,a5,0x7
    80002b94:	97ca                	add	a5,a5,s2
    80002b96:	1d47a983          	lw	s3,468(a5)
    80002b9a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002b9c:	2781                	sext.w	a5,a5
    80002b9e:	079e                	slli	a5,a5,0x7
    80002ba0:	0000f597          	auipc	a1,0xf
    80002ba4:	86058593          	addi	a1,a1,-1952 # 80011400 <cpus+0x8>
    80002ba8:	95be                	add	a1,a1,a5
    80002baa:	06848513          	addi	a0,s1,104
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	6be080e7          	jalr	1726(ra) # 8000326c <swtch>
    80002bb6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002bb8:	2781                	sext.w	a5,a5
    80002bba:	079e                	slli	a5,a5,0x7
    80002bbc:	97ca                	add	a5,a5,s2
    80002bbe:	1d37aa23          	sw	s3,468(a5)
}
    80002bc2:	70a2                	ld	ra,40(sp)
    80002bc4:	7402                	ld	s0,32(sp)
    80002bc6:	64e2                	ld	s1,24(sp)
    80002bc8:	6942                	ld	s2,16(sp)
    80002bca:	69a2                	ld	s3,8(sp)
    80002bcc:	6145                	addi	sp,sp,48
    80002bce:	8082                	ret
    panic("sched p->lock");
    80002bd0:	00006517          	auipc	a0,0x6
    80002bd4:	ab050513          	addi	a0,a0,-1360 # 80008680 <digits+0x640>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	966080e7          	jalr	-1690(ra) # 8000053e <panic>
    panic("sched locks");
    80002be0:	00006517          	auipc	a0,0x6
    80002be4:	ab050513          	addi	a0,a0,-1360 # 80008690 <digits+0x650>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	956080e7          	jalr	-1706(ra) # 8000053e <panic>
    panic("sched running");
    80002bf0:	00006517          	auipc	a0,0x6
    80002bf4:	ab050513          	addi	a0,a0,-1360 # 800086a0 <digits+0x660>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	946080e7          	jalr	-1722(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002c00:	00006517          	auipc	a0,0x6
    80002c04:	ab050513          	addi	a0,a0,-1360 # 800086b0 <digits+0x670>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	936080e7          	jalr	-1738(ra) # 8000053e <panic>

0000000080002c10 <yield>:
{
    80002c10:	1101                	addi	sp,sp,-32
    80002c12:	ec06                	sd	ra,24(sp)
    80002c14:	e822                	sd	s0,16(sp)
    80002c16:	e426                	sd	s1,8(sp)
    80002c18:	1000                	addi	s0,sp,32
  printf("entered yield\n");
    80002c1a:	00006517          	auipc	a0,0x6
    80002c1e:	aae50513          	addi	a0,a0,-1362 # 800086c8 <digits+0x688>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	966080e7          	jalr	-1690(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	6d2080e7          	jalr	1746(ra) # 800022fc <myproc>
    80002c32:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	fb0080e7          	jalr	-80(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002c3c:	478d                	li	a5,3
    80002c3e:	cc9c                	sw	a5,24(s1)
  sched();
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	eea080e7          	jalr	-278(ra) # 80002b2a <sched>
  release(&p->lock);
    80002c48:	8526                	mv	a0,s1
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	060080e7          	jalr	96(ra) # 80000caa <release>
}
    80002c52:	60e2                	ld	ra,24(sp)
    80002c54:	6442                	ld	s0,16(sp)
    80002c56:	64a2                	ld	s1,8(sp)
    80002c58:	6105                	addi	sp,sp,32
    80002c5a:	8082                	ret

0000000080002c5c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002c5c:	7179                	addi	sp,sp,-48
    80002c5e:	f406                	sd	ra,40(sp)
    80002c60:	f022                	sd	s0,32(sp)
    80002c62:	ec26                	sd	s1,24(sp)
    80002c64:	e84a                	sd	s2,16(sp)
    80002c66:	e44e                	sd	s3,8(sp)
    80002c68:	1800                	addi	s0,sp,48
    80002c6a:	89aa                	mv	s3,a0
    80002c6c:	892e                	mv	s2,a1
  printf("entered sleep\n");
    80002c6e:	00006517          	auipc	a0,0x6
    80002c72:	a6a50513          	addi	a0,a0,-1430 # 800086d8 <digits+0x698>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	912080e7          	jalr	-1774(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	67e080e7          	jalr	1662(ra) # 800022fc <myproc>
    80002c86:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002c88:	ffffe097          	auipc	ra,0xffffe
    80002c8c:	f5c080e7          	jalr	-164(ra) # 80000be4 <acquire>
  release(lk);
    80002c90:	854a                	mv	a0,s2
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	018080e7          	jalr	24(ra) # 80000caa <release>

  // Go to sleep.
  p->chan = chan;
    80002c9a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002c9e:	4789                	li	a5,2
    80002ca0:	cc9c                	sw	a5,24(s1)

  sched();
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	e88080e7          	jalr	-376(ra) # 80002b2a <sched>

  // Tidy up.
  p->chan = 0;
    80002caa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002cae:	8526                	mv	a0,s1
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	ffa080e7          	jalr	-6(ra) # 80000caa <release>
  acquire(lk);
    80002cb8:	854a                	mv	a0,s2
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	f2a080e7          	jalr	-214(ra) # 80000be4 <acquire>
}
    80002cc2:	70a2                	ld	ra,40(sp)
    80002cc4:	7402                	ld	s0,32(sp)
    80002cc6:	64e2                	ld	s1,24(sp)
    80002cc8:	6942                	ld	s2,16(sp)
    80002cca:	69a2                	ld	s3,8(sp)
    80002ccc:	6145                	addi	sp,sp,48
    80002cce:	8082                	ret

0000000080002cd0 <wait>:
{
    80002cd0:	715d                	addi	sp,sp,-80
    80002cd2:	e486                	sd	ra,72(sp)
    80002cd4:	e0a2                	sd	s0,64(sp)
    80002cd6:	fc26                	sd	s1,56(sp)
    80002cd8:	f84a                	sd	s2,48(sp)
    80002cda:	f44e                	sd	s3,40(sp)
    80002cdc:	f052                	sd	s4,32(sp)
    80002cde:	ec56                	sd	s5,24(sp)
    80002ce0:	e85a                	sd	s6,16(sp)
    80002ce2:	e45e                	sd	s7,8(sp)
    80002ce4:	e062                	sd	s8,0(sp)
    80002ce6:	0880                	addi	s0,sp,80
    80002ce8:	8b2a                	mv	s6,a0
  printf("entered wait\n");
    80002cea:	00006517          	auipc	a0,0x6
    80002cee:	9fe50513          	addi	a0,a0,-1538 # 800086e8 <digits+0x6a8>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	896080e7          	jalr	-1898(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	602080e7          	jalr	1538(ra) # 800022fc <myproc>
    80002d02:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002d04:	0000e517          	auipc	a0,0xe
    80002d08:	6dc50513          	addi	a0,a0,1756 # 800113e0 <wait_lock>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	ed8080e7          	jalr	-296(ra) # 80000be4 <acquire>
    havekids = 0;
    80002d14:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002d16:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002d18:	00014997          	auipc	s3,0x14
    80002d1c:	6e098993          	addi	s3,s3,1760 # 800173f8 <tickslock>
        havekids = 1;
    80002d20:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002d22:	0000ec17          	auipc	s8,0xe
    80002d26:	6bec0c13          	addi	s8,s8,1726 # 800113e0 <wait_lock>
    havekids = 0;
    80002d2a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002d2c:	0000f497          	auipc	s1,0xf
    80002d30:	acc48493          	addi	s1,s1,-1332 # 800117f8 <proc>
    80002d34:	a0bd                	j	80002da2 <wait+0xd2>
          pid = np->pid;
    80002d36:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002d3a:	000b0e63          	beqz	s6,80002d56 <wait+0x86>
    80002d3e:	4691                	li	a3,4
    80002d40:	02c48613          	addi	a2,s1,44
    80002d44:	85da                	mv	a1,s6
    80002d46:	05893503          	ld	a0,88(s2)
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	94c080e7          	jalr	-1716(ra) # 80001696 <copyout>
    80002d52:	02054563          	bltz	a0,80002d7c <wait+0xac>
          freeproc(np);
    80002d56:	8526                	mv	a0,s1
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	74a080e7          	jalr	1866(ra) # 800024a2 <freeproc>
          release(&np->lock);
    80002d60:	8526                	mv	a0,s1
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	f48080e7          	jalr	-184(ra) # 80000caa <release>
          release(&wait_lock);
    80002d6a:	0000e517          	auipc	a0,0xe
    80002d6e:	67650513          	addi	a0,a0,1654 # 800113e0 <wait_lock>
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	f38080e7          	jalr	-200(ra) # 80000caa <release>
          return pid;
    80002d7a:	a09d                	j	80002de0 <wait+0x110>
            release(&np->lock);
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	f2c080e7          	jalr	-212(ra) # 80000caa <release>
            release(&wait_lock);
    80002d86:	0000e517          	auipc	a0,0xe
    80002d8a:	65a50513          	addi	a0,a0,1626 # 800113e0 <wait_lock>
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	f1c080e7          	jalr	-228(ra) # 80000caa <release>
            return -1;
    80002d96:	59fd                	li	s3,-1
    80002d98:	a0a1                	j	80002de0 <wait+0x110>
    for(np = proc; np < &proc[NPROC]; np++){
    80002d9a:	17048493          	addi	s1,s1,368
    80002d9e:	03348463          	beq	s1,s3,80002dc6 <wait+0xf6>
      if(np->parent == p){
    80002da2:	60bc                	ld	a5,64(s1)
    80002da4:	ff279be3          	bne	a5,s2,80002d9a <wait+0xca>
        acquire(&np->lock);
    80002da8:	8526                	mv	a0,s1
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	e3a080e7          	jalr	-454(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002db2:	4c9c                	lw	a5,24(s1)
    80002db4:	f94781e3          	beq	a5,s4,80002d36 <wait+0x66>
        release(&np->lock);
    80002db8:	8526                	mv	a0,s1
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	ef0080e7          	jalr	-272(ra) # 80000caa <release>
        havekids = 1;
    80002dc2:	8756                	mv	a4,s5
    80002dc4:	bfd9                	j	80002d9a <wait+0xca>
    if(!havekids || p->killed){
    80002dc6:	c701                	beqz	a4,80002dce <wait+0xfe>
    80002dc8:	02892783          	lw	a5,40(s2)
    80002dcc:	c79d                	beqz	a5,80002dfa <wait+0x12a>
      release(&wait_lock);
    80002dce:	0000e517          	auipc	a0,0xe
    80002dd2:	61250513          	addi	a0,a0,1554 # 800113e0 <wait_lock>
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	ed4080e7          	jalr	-300(ra) # 80000caa <release>
      return -1;
    80002dde:	59fd                	li	s3,-1
}
    80002de0:	854e                	mv	a0,s3
    80002de2:	60a6                	ld	ra,72(sp)
    80002de4:	6406                	ld	s0,64(sp)
    80002de6:	74e2                	ld	s1,56(sp)
    80002de8:	7942                	ld	s2,48(sp)
    80002dea:	79a2                	ld	s3,40(sp)
    80002dec:	7a02                	ld	s4,32(sp)
    80002dee:	6ae2                	ld	s5,24(sp)
    80002df0:	6b42                	ld	s6,16(sp)
    80002df2:	6ba2                	ld	s7,8(sp)
    80002df4:	6c02                	ld	s8,0(sp)
    80002df6:	6161                	addi	sp,sp,80
    80002df8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002dfa:	85e2                	mv	a1,s8
    80002dfc:	854a                	mv	a0,s2
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	e5e080e7          	jalr	-418(ra) # 80002c5c <sleep>
    havekids = 0;
    80002e06:	b715                	j	80002d2a <wait+0x5a>

0000000080002e08 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002e08:	7139                	addi	sp,sp,-64
    80002e0a:	fc06                	sd	ra,56(sp)
    80002e0c:	f822                	sd	s0,48(sp)
    80002e0e:	f426                	sd	s1,40(sp)
    80002e10:	f04a                	sd	s2,32(sp)
    80002e12:	ec4e                	sd	s3,24(sp)
    80002e14:	e852                	sd	s4,16(sp)
    80002e16:	e456                	sd	s5,8(sp)
    80002e18:	0080                	addi	s0,sp,64
    80002e1a:	8a2a                	mv	s4,a0
  printf("entered wakeup\n");
    80002e1c:	00006517          	auipc	a0,0x6
    80002e20:	8dc50513          	addi	a0,a0,-1828 # 800086f8 <digits+0x6b8>
    80002e24:	ffffd097          	auipc	ra,0xffffd
    80002e28:	764080e7          	jalr	1892(ra) # 80000588 <printf>
  struct proc *p;
  if (sleeping == -1) // if no one is sleeping - do nothing
    80002e2c:	00006717          	auipc	a4,0x6
    80002e30:	ef072703          	lw	a4,-272(a4) # 80008d1c <sleeping>
    80002e34:	57fd                	li	a5,-1
    80002e36:	08f70563          	beq	a4,a5,80002ec0 <wakeup+0xb8>
    return;
  acquire(&sleeping_head);
    80002e3a:	0000e517          	auipc	a0,0xe
    80002e3e:	46650513          	addi	a0,a0,1126 # 800112a0 <sleeping_head>
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	da2080e7          	jalr	-606(ra) # 80000be4 <acquire>
  p = &proc[sleeping];
    80002e4a:	00006497          	auipc	s1,0x6
    80002e4e:	ed24a483          	lw	s1,-302(s1) # 80008d1c <sleeping>
    80002e52:	17000793          	li	a5,368
    80002e56:	02f484b3          	mul	s1,s1,a5
    80002e5a:	0000f797          	auipc	a5,0xf
    80002e5e:	99e78793          	addi	a5,a5,-1634 # 800117f8 <proc>
    80002e62:	94be                	add	s1,s1,a5
  while(p->next != -1 ) {
    80002e64:	5cdc                	lw	a5,60(s1)
    80002e66:	2781                	sext.w	a5,a5
    80002e68:	577d                	li	a4,-1
    80002e6a:	04e78b63          	beq	a5,a4,80002ec0 <wakeup+0xb8>
    if(p != myproc()){
      printf("process p->pid = %d\n", p->pid);
    80002e6e:	00006997          	auipc	s3,0x6
    80002e72:	89a98993          	addi	s3,s3,-1894 # 80008708 <digits+0x6c8>
      acquire(&p->lock);
      if(p->chan == chan) {
        p->state = RUNNABLE;
    80002e76:	4a8d                	li	s5,3
  while(p->next != -1 ) {
    80002e78:	597d                	li	s2,-1
    80002e7a:	a831                	j	80002e96 <wakeup+0x8e>
        p->state = RUNNABLE;
    80002e7c:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002e80:	8526                	mv	a0,s1
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e28080e7          	jalr	-472(ra) # 80000caa <release>
    }
    p++;
    80002e8a:	17048493          	addi	s1,s1,368
  while(p->next != -1 ) {
    80002e8e:	5cdc                	lw	a5,60(s1)
    80002e90:	2781                	sext.w	a5,a5
    80002e92:	03278763          	beq	a5,s2,80002ec0 <wakeup+0xb8>
    if(p != myproc()){
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	466080e7          	jalr	1126(ra) # 800022fc <myproc>
    80002e9e:	fea486e3          	beq	s1,a0,80002e8a <wakeup+0x82>
      printf("process p->pid = %d\n", p->pid);
    80002ea2:	588c                	lw	a1,48(s1)
    80002ea4:	854e                	mv	a0,s3
    80002ea6:	ffffd097          	auipc	ra,0xffffd
    80002eaa:	6e2080e7          	jalr	1762(ra) # 80000588 <printf>
      acquire(&p->lock);
    80002eae:	8526                	mv	a0,s1
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	d34080e7          	jalr	-716(ra) # 80000be4 <acquire>
      if(p->chan == chan) {
    80002eb8:	709c                	ld	a5,32(s1)
    80002eba:	fd4793e3          	bne	a5,s4,80002e80 <wakeup+0x78>
    80002ebe:	bf7d                	j	80002e7c <wakeup+0x74>
  }
}
    80002ec0:	70e2                	ld	ra,56(sp)
    80002ec2:	7442                	ld	s0,48(sp)
    80002ec4:	74a2                	ld	s1,40(sp)
    80002ec6:	7902                	ld	s2,32(sp)
    80002ec8:	69e2                	ld	s3,24(sp)
    80002eca:	6a42                	ld	s4,16(sp)
    80002ecc:	6aa2                	ld	s5,8(sp)
    80002ece:	6121                	addi	sp,sp,64
    80002ed0:	8082                	ret

0000000080002ed2 <reparent>:
{
    80002ed2:	7179                	addi	sp,sp,-48
    80002ed4:	f406                	sd	ra,40(sp)
    80002ed6:	f022                	sd	s0,32(sp)
    80002ed8:	ec26                	sd	s1,24(sp)
    80002eda:	e84a                	sd	s2,16(sp)
    80002edc:	e44e                	sd	s3,8(sp)
    80002ede:	e052                	sd	s4,0(sp)
    80002ee0:	1800                	addi	s0,sp,48
    80002ee2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ee4:	0000f497          	auipc	s1,0xf
    80002ee8:	91448493          	addi	s1,s1,-1772 # 800117f8 <proc>
      pp->parent = initproc;
    80002eec:	00006a17          	auipc	s4,0x6
    80002ef0:	13ca0a13          	addi	s4,s4,316 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ef4:	00014997          	auipc	s3,0x14
    80002ef8:	50498993          	addi	s3,s3,1284 # 800173f8 <tickslock>
    80002efc:	a029                	j	80002f06 <reparent+0x34>
    80002efe:	17048493          	addi	s1,s1,368
    80002f02:	01348d63          	beq	s1,s3,80002f1c <reparent+0x4a>
    if(pp->parent == p){
    80002f06:	60bc                	ld	a5,64(s1)
    80002f08:	ff279be3          	bne	a5,s2,80002efe <reparent+0x2c>
      pp->parent = initproc;
    80002f0c:	000a3503          	ld	a0,0(s4)
    80002f10:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002f12:	00000097          	auipc	ra,0x0
    80002f16:	ef6080e7          	jalr	-266(ra) # 80002e08 <wakeup>
    80002f1a:	b7d5                	j	80002efe <reparent+0x2c>
}
    80002f1c:	70a2                	ld	ra,40(sp)
    80002f1e:	7402                	ld	s0,32(sp)
    80002f20:	64e2                	ld	s1,24(sp)
    80002f22:	6942                	ld	s2,16(sp)
    80002f24:	69a2                	ld	s3,8(sp)
    80002f26:	6a02                	ld	s4,0(sp)
    80002f28:	6145                	addi	sp,sp,48
    80002f2a:	8082                	ret

0000000080002f2c <exit>:
{
    80002f2c:	7179                	addi	sp,sp,-48
    80002f2e:	f406                	sd	ra,40(sp)
    80002f30:	f022                	sd	s0,32(sp)
    80002f32:	ec26                	sd	s1,24(sp)
    80002f34:	e84a                	sd	s2,16(sp)
    80002f36:	e44e                	sd	s3,8(sp)
    80002f38:	e052                	sd	s4,0(sp)
    80002f3a:	1800                	addi	s0,sp,48
    80002f3c:	8a2a                	mv	s4,a0
  printf("entered exit\n");
    80002f3e:	00005517          	auipc	a0,0x5
    80002f42:	7e250513          	addi	a0,a0,2018 # 80008720 <digits+0x6e0>
    80002f46:	ffffd097          	auipc	ra,0xffffd
    80002f4a:	642080e7          	jalr	1602(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	3ae080e7          	jalr	942(ra) # 800022fc <myproc>
    80002f56:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f58:	00006797          	auipc	a5,0x6
    80002f5c:	0d07b783          	ld	a5,208(a5) # 80009028 <initproc>
    80002f60:	0d850493          	addi	s1,a0,216
    80002f64:	15850913          	addi	s2,a0,344
    80002f68:	02a79363          	bne	a5,a0,80002f8e <exit+0x62>
    panic("init exiting");
    80002f6c:	00005517          	auipc	a0,0x5
    80002f70:	7c450513          	addi	a0,a0,1988 # 80008730 <digits+0x6f0>
    80002f74:	ffffd097          	auipc	ra,0xffffd
    80002f78:	5ca080e7          	jalr	1482(ra) # 8000053e <panic>
      fileclose(f);
    80002f7c:	00002097          	auipc	ra,0x2
    80002f80:	1f2080e7          	jalr	498(ra) # 8000516e <fileclose>
      p->ofile[fd] = 0;
    80002f84:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f88:	04a1                	addi	s1,s1,8
    80002f8a:	01248563          	beq	s1,s2,80002f94 <exit+0x68>
    if(p->ofile[fd]){
    80002f8e:	6088                	ld	a0,0(s1)
    80002f90:	f575                	bnez	a0,80002f7c <exit+0x50>
    80002f92:	bfdd                	j	80002f88 <exit+0x5c>
  begin_op();
    80002f94:	00002097          	auipc	ra,0x2
    80002f98:	d0e080e7          	jalr	-754(ra) # 80004ca2 <begin_op>
  iput(p->cwd);
    80002f9c:	1589b503          	ld	a0,344(s3)
    80002fa0:	00001097          	auipc	ra,0x1
    80002fa4:	4ea080e7          	jalr	1258(ra) # 8000448a <iput>
  end_op();
    80002fa8:	00002097          	auipc	ra,0x2
    80002fac:	d7a080e7          	jalr	-646(ra) # 80004d22 <end_op>
  p->cwd = 0;
    80002fb0:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002fb4:	0000e497          	auipc	s1,0xe
    80002fb8:	42c48493          	addi	s1,s1,1068 # 800113e0 <wait_lock>
    80002fbc:	8526                	mv	a0,s1
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	c26080e7          	jalr	-986(ra) # 80000be4 <acquire>
  reparent(p);
    80002fc6:	854e                	mv	a0,s3
    80002fc8:	00000097          	auipc	ra,0x0
    80002fcc:	f0a080e7          	jalr	-246(ra) # 80002ed2 <reparent>
  wakeup(p->parent);
    80002fd0:	0409b503          	ld	a0,64(s3)
    80002fd4:	00000097          	auipc	ra,0x0
    80002fd8:	e34080e7          	jalr	-460(ra) # 80002e08 <wakeup>
  acquire(&p->lock);
    80002fdc:	854e                	mv	a0,s3
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	c06080e7          	jalr	-1018(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002fe6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002fea:	4795                	li	a5,5
    80002fec:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002ff0:	8526                	mv	a0,s1
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	cb8080e7          	jalr	-840(ra) # 80000caa <release>
  sched();
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	b30080e7          	jalr	-1232(ra) # 80002b2a <sched>
  panic("zombie exit");
    80003002:	00005517          	auipc	a0,0x5
    80003006:	73e50513          	addi	a0,a0,1854 # 80008740 <digits+0x700>
    8000300a:	ffffd097          	auipc	ra,0xffffd
    8000300e:	534080e7          	jalr	1332(ra) # 8000053e <panic>

0000000080003012 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80003012:	7179                	addi	sp,sp,-48
    80003014:	f406                	sd	ra,40(sp)
    80003016:	f022                	sd	s0,32(sp)
    80003018:	ec26                	sd	s1,24(sp)
    8000301a:	e84a                	sd	s2,16(sp)
    8000301c:	e44e                	sd	s3,8(sp)
    8000301e:	1800                	addi	s0,sp,48
    80003020:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80003022:	0000e497          	auipc	s1,0xe
    80003026:	7d648493          	addi	s1,s1,2006 # 800117f8 <proc>
    8000302a:	00014997          	auipc	s3,0x14
    8000302e:	3ce98993          	addi	s3,s3,974 # 800173f8 <tickslock>
    acquire(&p->lock);
    80003032:	8526                	mv	a0,s1
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	bb0080e7          	jalr	-1104(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000303c:	589c                	lw	a5,48(s1)
    8000303e:	01278d63          	beq	a5,s2,80003058 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80003042:	8526                	mv	a0,s1
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	c66080e7          	jalr	-922(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000304c:	17048493          	addi	s1,s1,368
    80003050:	ff3491e3          	bne	s1,s3,80003032 <kill+0x20>
  }
  return -1;
    80003054:	557d                	li	a0,-1
    80003056:	a829                	j	80003070 <kill+0x5e>
      p->killed = 1;
    80003058:	4785                	li	a5,1
    8000305a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000305c:	4c98                	lw	a4,24(s1)
    8000305e:	4789                	li	a5,2
    80003060:	00f70f63          	beq	a4,a5,8000307e <kill+0x6c>
      release(&p->lock);
    80003064:	8526                	mv	a0,s1
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	c44080e7          	jalr	-956(ra) # 80000caa <release>
      return 0;
    8000306e:	4501                	li	a0,0
}
    80003070:	70a2                	ld	ra,40(sp)
    80003072:	7402                	ld	s0,32(sp)
    80003074:	64e2                	ld	s1,24(sp)
    80003076:	6942                	ld	s2,16(sp)
    80003078:	69a2                	ld	s3,8(sp)
    8000307a:	6145                	addi	sp,sp,48
    8000307c:	8082                	ret
        p->state = RUNNABLE;
    8000307e:	478d                	li	a5,3
    80003080:	cc9c                	sw	a5,24(s1)
    80003082:	b7cd                	j	80003064 <kill+0x52>

0000000080003084 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80003084:	7179                	addi	sp,sp,-48
    80003086:	f406                	sd	ra,40(sp)
    80003088:	f022                	sd	s0,32(sp)
    8000308a:	ec26                	sd	s1,24(sp)
    8000308c:	e84a                	sd	s2,16(sp)
    8000308e:	e44e                	sd	s3,8(sp)
    80003090:	e052                	sd	s4,0(sp)
    80003092:	1800                	addi	s0,sp,48
    80003094:	84aa                	mv	s1,a0
    80003096:	892e                	mv	s2,a1
    80003098:	89b2                	mv	s3,a2
    8000309a:	8a36                	mv	s4,a3
  printf("entered either_copyout\n");
    8000309c:	00005517          	auipc	a0,0x5
    800030a0:	6b450513          	addi	a0,a0,1716 # 80008750 <digits+0x710>
    800030a4:	ffffd097          	auipc	ra,0xffffd
    800030a8:	4e4080e7          	jalr	1252(ra) # 80000588 <printf>
  struct proc *p = myproc();
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	250080e7          	jalr	592(ra) # 800022fc <myproc>
  if(user_dst){
    800030b4:	c08d                	beqz	s1,800030d6 <either_copyout+0x52>
    return copyout(p->pagetable, dst, src, len);
    800030b6:	86d2                	mv	a3,s4
    800030b8:	864e                	mv	a2,s3
    800030ba:	85ca                	mv	a1,s2
    800030bc:	6d28                	ld	a0,88(a0)
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	5d8080e7          	jalr	1496(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800030c6:	70a2                	ld	ra,40(sp)
    800030c8:	7402                	ld	s0,32(sp)
    800030ca:	64e2                	ld	s1,24(sp)
    800030cc:	6942                	ld	s2,16(sp)
    800030ce:	69a2                	ld	s3,8(sp)
    800030d0:	6a02                	ld	s4,0(sp)
    800030d2:	6145                	addi	sp,sp,48
    800030d4:	8082                	ret
    memmove((char *)dst, src, len);
    800030d6:	000a061b          	sext.w	a2,s4
    800030da:	85ce                	mv	a1,s3
    800030dc:	854a                	mv	a0,s2
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	c86080e7          	jalr	-890(ra) # 80000d64 <memmove>
    return 0;
    800030e6:	8526                	mv	a0,s1
    800030e8:	bff9                	j	800030c6 <either_copyout+0x42>

00000000800030ea <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800030ea:	7179                	addi	sp,sp,-48
    800030ec:	f406                	sd	ra,40(sp)
    800030ee:	f022                	sd	s0,32(sp)
    800030f0:	ec26                	sd	s1,24(sp)
    800030f2:	e84a                	sd	s2,16(sp)
    800030f4:	e44e                	sd	s3,8(sp)
    800030f6:	e052                	sd	s4,0(sp)
    800030f8:	1800                	addi	s0,sp,48
    800030fa:	892a                	mv	s2,a0
    800030fc:	84ae                	mv	s1,a1
    800030fe:	89b2                	mv	s3,a2
    80003100:	8a36                	mv	s4,a3
  printf("entered either_copyin\n");
    80003102:	00005517          	auipc	a0,0x5
    80003106:	66650513          	addi	a0,a0,1638 # 80008768 <digits+0x728>
    8000310a:	ffffd097          	auipc	ra,0xffffd
    8000310e:	47e080e7          	jalr	1150(ra) # 80000588 <printf>
  struct proc *p = myproc();
    80003112:	fffff097          	auipc	ra,0xfffff
    80003116:	1ea080e7          	jalr	490(ra) # 800022fc <myproc>
  if(user_src){
    8000311a:	c08d                	beqz	s1,8000313c <either_copyin+0x52>
    return copyin(p->pagetable, dst, src, len);
    8000311c:	86d2                	mv	a3,s4
    8000311e:	864e                	mv	a2,s3
    80003120:	85ca                	mv	a1,s2
    80003122:	6d28                	ld	a0,88(a0)
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	5fe080e7          	jalr	1534(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000312c:	70a2                	ld	ra,40(sp)
    8000312e:	7402                	ld	s0,32(sp)
    80003130:	64e2                	ld	s1,24(sp)
    80003132:	6942                	ld	s2,16(sp)
    80003134:	69a2                	ld	s3,8(sp)
    80003136:	6a02                	ld	s4,0(sp)
    80003138:	6145                	addi	sp,sp,48
    8000313a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000313c:	000a061b          	sext.w	a2,s4
    80003140:	85ce                	mv	a1,s3
    80003142:	854a                	mv	a0,s2
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	c20080e7          	jalr	-992(ra) # 80000d64 <memmove>
    return 0;
    8000314c:	8526                	mv	a0,s1
    8000314e:	bff9                	j	8000312c <either_copyin+0x42>

0000000080003150 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003150:	715d                	addi	sp,sp,-80
    80003152:	e486                	sd	ra,72(sp)
    80003154:	e0a2                	sd	s0,64(sp)
    80003156:	fc26                	sd	s1,56(sp)
    80003158:	f84a                	sd	s2,48(sp)
    8000315a:	f44e                	sd	s3,40(sp)
    8000315c:	f052                	sd	s4,32(sp)
    8000315e:	ec56                	sd	s5,24(sp)
    80003160:	e85a                	sd	s6,16(sp)
    80003162:	e45e                	sd	s7,8(sp)
    80003164:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003166:	00005517          	auipc	a0,0x5
    8000316a:	2ca50513          	addi	a0,a0,714 # 80008430 <digits+0x3f0>
    8000316e:	ffffd097          	auipc	ra,0xffffd
    80003172:	41a080e7          	jalr	1050(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003176:	0000e497          	auipc	s1,0xe
    8000317a:	7e248493          	addi	s1,s1,2018 # 80011958 <proc+0x160>
    8000317e:	00014917          	auipc	s2,0x14
    80003182:	3da90913          	addi	s2,s2,986 # 80017558 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003186:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003188:	00005997          	auipc	s3,0x5
    8000318c:	5f898993          	addi	s3,s3,1528 # 80008780 <digits+0x740>
    printf("%d %s %s", p->pid, state, p->name);
    80003190:	00005a97          	auipc	s5,0x5
    80003194:	5f8a8a93          	addi	s5,s5,1528 # 80008788 <digits+0x748>
    printf("\n");
    80003198:	00005a17          	auipc	s4,0x5
    8000319c:	298a0a13          	addi	s4,s4,664 # 80008430 <digits+0x3f0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031a0:	00005b97          	auipc	s7,0x5
    800031a4:	620b8b93          	addi	s7,s7,1568 # 800087c0 <states.1768>
    800031a8:	a00d                	j	800031ca <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800031aa:	ed06a583          	lw	a1,-304(a3)
    800031ae:	8556                	mv	a0,s5
    800031b0:	ffffd097          	auipc	ra,0xffffd
    800031b4:	3d8080e7          	jalr	984(ra) # 80000588 <printf>
    printf("\n");
    800031b8:	8552                	mv	a0,s4
    800031ba:	ffffd097          	auipc	ra,0xffffd
    800031be:	3ce080e7          	jalr	974(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800031c2:	17048493          	addi	s1,s1,368
    800031c6:	03248163          	beq	s1,s2,800031e8 <procdump+0x98>
    if(p->state == UNUSED)
    800031ca:	86a6                	mv	a3,s1
    800031cc:	eb84a783          	lw	a5,-328(s1)
    800031d0:	dbed                	beqz	a5,800031c2 <procdump+0x72>
      state = "???";
    800031d2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031d4:	fcfb6be3          	bltu	s6,a5,800031aa <procdump+0x5a>
    800031d8:	1782                	slli	a5,a5,0x20
    800031da:	9381                	srli	a5,a5,0x20
    800031dc:	078e                	slli	a5,a5,0x3
    800031de:	97de                	add	a5,a5,s7
    800031e0:	6390                	ld	a2,0(a5)
    800031e2:	f661                	bnez	a2,800031aa <procdump+0x5a>
      state = "???";
    800031e4:	864e                	mv	a2,s3
    800031e6:	b7d1                	j	800031aa <procdump+0x5a>
  }
}
    800031e8:	60a6                	ld	ra,72(sp)
    800031ea:	6406                	ld	s0,64(sp)
    800031ec:	74e2                	ld	s1,56(sp)
    800031ee:	7942                	ld	s2,48(sp)
    800031f0:	79a2                	ld	s3,40(sp)
    800031f2:	7a02                	ld	s4,32(sp)
    800031f4:	6ae2                	ld	s5,24(sp)
    800031f6:	6b42                	ld	s6,16(sp)
    800031f8:	6ba2                	ld	s7,8(sp)
    800031fa:	6161                	addi	sp,sp,80
    800031fc:	8082                	ret

00000000800031fe <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	e426                	sd	s1,8(sp)
    80003206:	1000                	addi	s0,sp,32
    80003208:	84aa                	mv	s1,a0
  struct proc *p= myproc();  
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	0f2080e7          	jalr	242(ra) # 800022fc <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80003212:	8626                	mv	a2,s1
    80003214:	594c                	lw	a1,52(a0)
    80003216:	03450513          	addi	a0,a0,52
    8000321a:	00004097          	auipc	ra,0x4
    8000321e:	c4c080e7          	jalr	-948(ra) # 80006e66 <cas>
    80003222:	e519                	bnez	a0,80003230 <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80003224:	4501                	li	a0,0
}
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	64a2                	ld	s1,8(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret
    yield();
    80003230:	00000097          	auipc	ra,0x0
    80003234:	9e0080e7          	jalr	-1568(ra) # 80002c10 <yield>
    return cpu_num;
    80003238:	8526                	mv	a0,s1
    8000323a:	b7f5                	j	80003226 <set_cpu+0x28>

000000008000323c <get_cpu>:

int get_cpu(){ //added as orderd
    8000323c:	1101                	addi	sp,sp,-32
    8000323e:	ec06                	sd	ra,24(sp)
    80003240:	e822                	sd	s0,16(sp)
    80003242:	1000                	addi	s0,sp,32
  struct proc *p=myproc();
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	0b8080e7          	jalr	184(ra) # 800022fc <myproc>
  int ans=0;
    8000324c:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80003250:	5950                	lw	a2,52(a0)
    80003252:	4581                	li	a1,0
    80003254:	fec40513          	addi	a0,s0,-20
    80003258:	00004097          	auipc	ra,0x4
    8000325c:	c0e080e7          	jalr	-1010(ra) # 80006e66 <cas>
    return ans;
}
    80003260:	fec42503          	lw	a0,-20(s0)
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	6105                	addi	sp,sp,32
    8000326a:	8082                	ret

000000008000326c <swtch>:
    8000326c:	00153023          	sd	ra,0(a0)
    80003270:	00253423          	sd	sp,8(a0)
    80003274:	e900                	sd	s0,16(a0)
    80003276:	ed04                	sd	s1,24(a0)
    80003278:	03253023          	sd	s2,32(a0)
    8000327c:	03353423          	sd	s3,40(a0)
    80003280:	03453823          	sd	s4,48(a0)
    80003284:	03553c23          	sd	s5,56(a0)
    80003288:	05653023          	sd	s6,64(a0)
    8000328c:	05753423          	sd	s7,72(a0)
    80003290:	05853823          	sd	s8,80(a0)
    80003294:	05953c23          	sd	s9,88(a0)
    80003298:	07a53023          	sd	s10,96(a0)
    8000329c:	07b53423          	sd	s11,104(a0)
    800032a0:	0005b083          	ld	ra,0(a1)
    800032a4:	0085b103          	ld	sp,8(a1)
    800032a8:	6980                	ld	s0,16(a1)
    800032aa:	6d84                	ld	s1,24(a1)
    800032ac:	0205b903          	ld	s2,32(a1)
    800032b0:	0285b983          	ld	s3,40(a1)
    800032b4:	0305ba03          	ld	s4,48(a1)
    800032b8:	0385ba83          	ld	s5,56(a1)
    800032bc:	0405bb03          	ld	s6,64(a1)
    800032c0:	0485bb83          	ld	s7,72(a1)
    800032c4:	0505bc03          	ld	s8,80(a1)
    800032c8:	0585bc83          	ld	s9,88(a1)
    800032cc:	0605bd03          	ld	s10,96(a1)
    800032d0:	0685bd83          	ld	s11,104(a1)
    800032d4:	8082                	ret

00000000800032d6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800032d6:	1141                	addi	sp,sp,-16
    800032d8:	e406                	sd	ra,8(sp)
    800032da:	e022                	sd	s0,0(sp)
    800032dc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800032de:	00005597          	auipc	a1,0x5
    800032e2:	51258593          	addi	a1,a1,1298 # 800087f0 <states.1768+0x30>
    800032e6:	00014517          	auipc	a0,0x14
    800032ea:	11250513          	addi	a0,a0,274 # 800173f8 <tickslock>
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	866080e7          	jalr	-1946(ra) # 80000b54 <initlock>
}
    800032f6:	60a2                	ld	ra,8(sp)
    800032f8:	6402                	ld	s0,0(sp)
    800032fa:	0141                	addi	sp,sp,16
    800032fc:	8082                	ret

00000000800032fe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800032fe:	1141                	addi	sp,sp,-16
    80003300:	e422                	sd	s0,8(sp)
    80003302:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003304:	00003797          	auipc	a5,0x3
    80003308:	48c78793          	addi	a5,a5,1164 # 80006790 <kernelvec>
    8000330c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003310:	6422                	ld	s0,8(sp)
    80003312:	0141                	addi	sp,sp,16
    80003314:	8082                	ret

0000000080003316 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003316:	1141                	addi	sp,sp,-16
    80003318:	e406                	sd	ra,8(sp)
    8000331a:	e022                	sd	s0,0(sp)
    8000331c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000331e:	fffff097          	auipc	ra,0xfffff
    80003322:	fde080e7          	jalr	-34(ra) # 800022fc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003326:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000332a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000332c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003330:	00004617          	auipc	a2,0x4
    80003334:	cd060613          	addi	a2,a2,-816 # 80007000 <_trampoline>
    80003338:	00004697          	auipc	a3,0x4
    8000333c:	cc868693          	addi	a3,a3,-824 # 80007000 <_trampoline>
    80003340:	8e91                	sub	a3,a3,a2
    80003342:	040007b7          	lui	a5,0x4000
    80003346:	17fd                	addi	a5,a5,-1
    80003348:	07b2                	slli	a5,a5,0xc
    8000334a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000334c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003350:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003352:	180026f3          	csrr	a3,satp
    80003356:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003358:	7138                	ld	a4,96(a0)
    8000335a:	6534                	ld	a3,72(a0)
    8000335c:	6585                	lui	a1,0x1
    8000335e:	96ae                	add	a3,a3,a1
    80003360:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003362:	7138                	ld	a4,96(a0)
    80003364:	00000697          	auipc	a3,0x0
    80003368:	13868693          	addi	a3,a3,312 # 8000349c <usertrap>
    8000336c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000336e:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003370:	8692                	mv	a3,tp
    80003372:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003374:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003378:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000337c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003380:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003384:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003386:	6f18                	ld	a4,24(a4)
    80003388:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000338c:	6d2c                	ld	a1,88(a0)
    8000338e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003390:	00004717          	auipc	a4,0x4
    80003394:	d0070713          	addi	a4,a4,-768 # 80007090 <userret>
    80003398:	8f11                	sub	a4,a4,a2
    8000339a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000339c:	577d                	li	a4,-1
    8000339e:	177e                	slli	a4,a4,0x3f
    800033a0:	8dd9                	or	a1,a1,a4
    800033a2:	02000537          	lui	a0,0x2000
    800033a6:	157d                	addi	a0,a0,-1
    800033a8:	0536                	slli	a0,a0,0xd
    800033aa:	9782                	jalr	a5
}
    800033ac:	60a2                	ld	ra,8(sp)
    800033ae:	6402                	ld	s0,0(sp)
    800033b0:	0141                	addi	sp,sp,16
    800033b2:	8082                	ret

00000000800033b4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800033b4:	1101                	addi	sp,sp,-32
    800033b6:	ec06                	sd	ra,24(sp)
    800033b8:	e822                	sd	s0,16(sp)
    800033ba:	e426                	sd	s1,8(sp)
    800033bc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800033be:	00014497          	auipc	s1,0x14
    800033c2:	03a48493          	addi	s1,s1,58 # 800173f8 <tickslock>
    800033c6:	8526                	mv	a0,s1
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	81c080e7          	jalr	-2020(ra) # 80000be4 <acquire>
  ticks++;
    800033d0:	00006517          	auipc	a0,0x6
    800033d4:	c6050513          	addi	a0,a0,-928 # 80009030 <ticks>
    800033d8:	411c                	lw	a5,0(a0)
    800033da:	2785                	addiw	a5,a5,1
    800033dc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	a2a080e7          	jalr	-1494(ra) # 80002e08 <wakeup>
  release(&tickslock);
    800033e6:	8526                	mv	a0,s1
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	8c2080e7          	jalr	-1854(ra) # 80000caa <release>
}
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	64a2                	ld	s1,8(sp)
    800033f6:	6105                	addi	sp,sp,32
    800033f8:	8082                	ret

00000000800033fa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800033fa:	1101                	addi	sp,sp,-32
    800033fc:	ec06                	sd	ra,24(sp)
    800033fe:	e822                	sd	s0,16(sp)
    80003400:	e426                	sd	s1,8(sp)
    80003402:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003404:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003408:	00074d63          	bltz	a4,80003422 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000340c:	57fd                	li	a5,-1
    8000340e:	17fe                	slli	a5,a5,0x3f
    80003410:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003412:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003414:	06f70363          	beq	a4,a5,8000347a <devintr+0x80>
  }
}
    80003418:	60e2                	ld	ra,24(sp)
    8000341a:	6442                	ld	s0,16(sp)
    8000341c:	64a2                	ld	s1,8(sp)
    8000341e:	6105                	addi	sp,sp,32
    80003420:	8082                	ret
     (scause & 0xff) == 9){
    80003422:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003426:	46a5                	li	a3,9
    80003428:	fed792e3          	bne	a5,a3,8000340c <devintr+0x12>
    int irq = plic_claim();
    8000342c:	00003097          	auipc	ra,0x3
    80003430:	46c080e7          	jalr	1132(ra) # 80006898 <plic_claim>
    80003434:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003436:	47a9                	li	a5,10
    80003438:	02f50763          	beq	a0,a5,80003466 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000343c:	4785                	li	a5,1
    8000343e:	02f50963          	beq	a0,a5,80003470 <devintr+0x76>
    return 1;
    80003442:	4505                	li	a0,1
    } else if(irq){
    80003444:	d8f1                	beqz	s1,80003418 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003446:	85a6                	mv	a1,s1
    80003448:	00005517          	auipc	a0,0x5
    8000344c:	3b050513          	addi	a0,a0,944 # 800087f8 <states.1768+0x38>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	138080e7          	jalr	312(ra) # 80000588 <printf>
      plic_complete(irq);
    80003458:	8526                	mv	a0,s1
    8000345a:	00003097          	auipc	ra,0x3
    8000345e:	462080e7          	jalr	1122(ra) # 800068bc <plic_complete>
    return 1;
    80003462:	4505                	li	a0,1
    80003464:	bf55                	j	80003418 <devintr+0x1e>
      uartintr();
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	542080e7          	jalr	1346(ra) # 800009a8 <uartintr>
    8000346e:	b7ed                	j	80003458 <devintr+0x5e>
      virtio_disk_intr();
    80003470:	00004097          	auipc	ra,0x4
    80003474:	92c080e7          	jalr	-1748(ra) # 80006d9c <virtio_disk_intr>
    80003478:	b7c5                	j	80003458 <devintr+0x5e>
    if(cpuid() == 0){
    8000347a:	fffff097          	auipc	ra,0xfffff
    8000347e:	e56080e7          	jalr	-426(ra) # 800022d0 <cpuid>
    80003482:	c901                	beqz	a0,80003492 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003484:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003488:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000348a:	14479073          	csrw	sip,a5
    return 2;
    8000348e:	4509                	li	a0,2
    80003490:	b761                	j	80003418 <devintr+0x1e>
      clockintr();
    80003492:	00000097          	auipc	ra,0x0
    80003496:	f22080e7          	jalr	-222(ra) # 800033b4 <clockintr>
    8000349a:	b7ed                	j	80003484 <devintr+0x8a>

000000008000349c <usertrap>:
{
    8000349c:	1101                	addi	sp,sp,-32
    8000349e:	ec06                	sd	ra,24(sp)
    800034a0:	e822                	sd	s0,16(sp)
    800034a2:	e426                	sd	s1,8(sp)
    800034a4:	e04a                	sd	s2,0(sp)
    800034a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034a8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800034ac:	1007f793          	andi	a5,a5,256
    800034b0:	e3ad                	bnez	a5,80003512 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800034b2:	00003797          	auipc	a5,0x3
    800034b6:	2de78793          	addi	a5,a5,734 # 80006790 <kernelvec>
    800034ba:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800034be:	fffff097          	auipc	ra,0xfffff
    800034c2:	e3e080e7          	jalr	-450(ra) # 800022fc <myproc>
    800034c6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800034c8:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034ca:	14102773          	csrr	a4,sepc
    800034ce:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034d0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800034d4:	47a1                	li	a5,8
    800034d6:	04f71c63          	bne	a4,a5,8000352e <usertrap+0x92>
    if(p->killed)
    800034da:	551c                	lw	a5,40(a0)
    800034dc:	e3b9                	bnez	a5,80003522 <usertrap+0x86>
    p->trapframe->epc += 4;
    800034de:	70b8                	ld	a4,96(s1)
    800034e0:	6f1c                	ld	a5,24(a4)
    800034e2:	0791                	addi	a5,a5,4
    800034e4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800034ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034ee:	10079073          	csrw	sstatus,a5
    syscall();
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	2e0080e7          	jalr	736(ra) # 800037d2 <syscall>
  if(p->killed)
    800034fa:	549c                	lw	a5,40(s1)
    800034fc:	ebc1                	bnez	a5,8000358c <usertrap+0xf0>
  usertrapret();
    800034fe:	00000097          	auipc	ra,0x0
    80003502:	e18080e7          	jalr	-488(ra) # 80003316 <usertrapret>
}
    80003506:	60e2                	ld	ra,24(sp)
    80003508:	6442                	ld	s0,16(sp)
    8000350a:	64a2                	ld	s1,8(sp)
    8000350c:	6902                	ld	s2,0(sp)
    8000350e:	6105                	addi	sp,sp,32
    80003510:	8082                	ret
    panic("usertrap: not from user mode");
    80003512:	00005517          	auipc	a0,0x5
    80003516:	30650513          	addi	a0,a0,774 # 80008818 <states.1768+0x58>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	024080e7          	jalr	36(ra) # 8000053e <panic>
      exit(-1);
    80003522:	557d                	li	a0,-1
    80003524:	00000097          	auipc	ra,0x0
    80003528:	a08080e7          	jalr	-1528(ra) # 80002f2c <exit>
    8000352c:	bf4d                	j	800034de <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	ecc080e7          	jalr	-308(ra) # 800033fa <devintr>
    80003536:	892a                	mv	s2,a0
    80003538:	c501                	beqz	a0,80003540 <usertrap+0xa4>
  if(p->killed)
    8000353a:	549c                	lw	a5,40(s1)
    8000353c:	c3a1                	beqz	a5,8000357c <usertrap+0xe0>
    8000353e:	a815                	j	80003572 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003540:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003544:	5890                	lw	a2,48(s1)
    80003546:	00005517          	auipc	a0,0x5
    8000354a:	2f250513          	addi	a0,a0,754 # 80008838 <states.1768+0x78>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	03a080e7          	jalr	58(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003556:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000355a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000355e:	00005517          	auipc	a0,0x5
    80003562:	30a50513          	addi	a0,a0,778 # 80008868 <states.1768+0xa8>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	022080e7          	jalr	34(ra) # 80000588 <printf>
    p->killed = 1;
    8000356e:	4785                	li	a5,1
    80003570:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003572:	557d                	li	a0,-1
    80003574:	00000097          	auipc	ra,0x0
    80003578:	9b8080e7          	jalr	-1608(ra) # 80002f2c <exit>
  if(which_dev == 2)
    8000357c:	4789                	li	a5,2
    8000357e:	f8f910e3          	bne	s2,a5,800034fe <usertrap+0x62>
    yield();
    80003582:	fffff097          	auipc	ra,0xfffff
    80003586:	68e080e7          	jalr	1678(ra) # 80002c10 <yield>
    8000358a:	bf95                	j	800034fe <usertrap+0x62>
  int which_dev = 0;
    8000358c:	4901                	li	s2,0
    8000358e:	b7d5                	j	80003572 <usertrap+0xd6>

0000000080003590 <kerneltrap>:
{
    80003590:	7179                	addi	sp,sp,-48
    80003592:	f406                	sd	ra,40(sp)
    80003594:	f022                	sd	s0,32(sp)
    80003596:	ec26                	sd	s1,24(sp)
    80003598:	e84a                	sd	s2,16(sp)
    8000359a:	e44e                	sd	s3,8(sp)
    8000359c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000359e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035a2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035a6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800035aa:	1004f793          	andi	a5,s1,256
    800035ae:	cb85                	beqz	a5,800035de <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800035b4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800035b6:	ef85                	bnez	a5,800035ee <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800035b8:	00000097          	auipc	ra,0x0
    800035bc:	e42080e7          	jalr	-446(ra) # 800033fa <devintr>
    800035c0:	cd1d                	beqz	a0,800035fe <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800035c2:	4789                	li	a5,2
    800035c4:	06f50a63          	beq	a0,a5,80003638 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800035c8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800035cc:	10049073          	csrw	sstatus,s1
}
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6942                	ld	s2,16(sp)
    800035d8:	69a2                	ld	s3,8(sp)
    800035da:	6145                	addi	sp,sp,48
    800035dc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800035de:	00005517          	auipc	a0,0x5
    800035e2:	2aa50513          	addi	a0,a0,682 # 80008888 <states.1768+0xc8>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800035ee:	00005517          	auipc	a0,0x5
    800035f2:	2c250513          	addi	a0,a0,706 # 800088b0 <states.1768+0xf0>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800035fe:	85ce                	mv	a1,s3
    80003600:	00005517          	auipc	a0,0x5
    80003604:	2d050513          	addi	a0,a0,720 # 800088d0 <states.1768+0x110>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	f80080e7          	jalr	-128(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003610:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003614:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003618:	00005517          	auipc	a0,0x5
    8000361c:	2c850513          	addi	a0,a0,712 # 800088e0 <states.1768+0x120>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f68080e7          	jalr	-152(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003628:	00005517          	auipc	a0,0x5
    8000362c:	2d050513          	addi	a0,a0,720 # 800088f8 <states.1768+0x138>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003638:	fffff097          	auipc	ra,0xfffff
    8000363c:	cc4080e7          	jalr	-828(ra) # 800022fc <myproc>
    80003640:	d541                	beqz	a0,800035c8 <kerneltrap+0x38>
    80003642:	fffff097          	auipc	ra,0xfffff
    80003646:	cba080e7          	jalr	-838(ra) # 800022fc <myproc>
    8000364a:	4d18                	lw	a4,24(a0)
    8000364c:	4791                	li	a5,4
    8000364e:	f6f71de3          	bne	a4,a5,800035c8 <kerneltrap+0x38>
    yield();
    80003652:	fffff097          	auipc	ra,0xfffff
    80003656:	5be080e7          	jalr	1470(ra) # 80002c10 <yield>
    8000365a:	b7bd                	j	800035c8 <kerneltrap+0x38>

000000008000365c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	1000                	addi	s0,sp,32
    80003666:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003668:	fffff097          	auipc	ra,0xfffff
    8000366c:	c94080e7          	jalr	-876(ra) # 800022fc <myproc>
  switch (n) {
    80003670:	4795                	li	a5,5
    80003672:	0497e163          	bltu	a5,s1,800036b4 <argraw+0x58>
    80003676:	048a                	slli	s1,s1,0x2
    80003678:	00005717          	auipc	a4,0x5
    8000367c:	2b870713          	addi	a4,a4,696 # 80008930 <states.1768+0x170>
    80003680:	94ba                	add	s1,s1,a4
    80003682:	409c                	lw	a5,0(s1)
    80003684:	97ba                	add	a5,a5,a4
    80003686:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003688:	713c                	ld	a5,96(a0)
    8000368a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000368c:	60e2                	ld	ra,24(sp)
    8000368e:	6442                	ld	s0,16(sp)
    80003690:	64a2                	ld	s1,8(sp)
    80003692:	6105                	addi	sp,sp,32
    80003694:	8082                	ret
    return p->trapframe->a1;
    80003696:	713c                	ld	a5,96(a0)
    80003698:	7fa8                	ld	a0,120(a5)
    8000369a:	bfcd                	j	8000368c <argraw+0x30>
    return p->trapframe->a2;
    8000369c:	713c                	ld	a5,96(a0)
    8000369e:	63c8                	ld	a0,128(a5)
    800036a0:	b7f5                	j	8000368c <argraw+0x30>
    return p->trapframe->a3;
    800036a2:	713c                	ld	a5,96(a0)
    800036a4:	67c8                	ld	a0,136(a5)
    800036a6:	b7dd                	j	8000368c <argraw+0x30>
    return p->trapframe->a4;
    800036a8:	713c                	ld	a5,96(a0)
    800036aa:	6bc8                	ld	a0,144(a5)
    800036ac:	b7c5                	j	8000368c <argraw+0x30>
    return p->trapframe->a5;
    800036ae:	713c                	ld	a5,96(a0)
    800036b0:	6fc8                	ld	a0,152(a5)
    800036b2:	bfe9                	j	8000368c <argraw+0x30>
  panic("argraw");
    800036b4:	00005517          	auipc	a0,0x5
    800036b8:	25450513          	addi	a0,a0,596 # 80008908 <states.1768+0x148>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	e82080e7          	jalr	-382(ra) # 8000053e <panic>

00000000800036c4 <fetchaddr>:
{
    800036c4:	1101                	addi	sp,sp,-32
    800036c6:	ec06                	sd	ra,24(sp)
    800036c8:	e822                	sd	s0,16(sp)
    800036ca:	e426                	sd	s1,8(sp)
    800036cc:	e04a                	sd	s2,0(sp)
    800036ce:	1000                	addi	s0,sp,32
    800036d0:	84aa                	mv	s1,a0
    800036d2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800036d4:	fffff097          	auipc	ra,0xfffff
    800036d8:	c28080e7          	jalr	-984(ra) # 800022fc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800036dc:	693c                	ld	a5,80(a0)
    800036de:	02f4f863          	bgeu	s1,a5,8000370e <fetchaddr+0x4a>
    800036e2:	00848713          	addi	a4,s1,8
    800036e6:	02e7e663          	bltu	a5,a4,80003712 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800036ea:	46a1                	li	a3,8
    800036ec:	8626                	mv	a2,s1
    800036ee:	85ca                	mv	a1,s2
    800036f0:	6d28                	ld	a0,88(a0)
    800036f2:	ffffe097          	auipc	ra,0xffffe
    800036f6:	030080e7          	jalr	48(ra) # 80001722 <copyin>
    800036fa:	00a03533          	snez	a0,a0
    800036fe:	40a00533          	neg	a0,a0
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	64a2                	ld	s1,8(sp)
    80003708:	6902                	ld	s2,0(sp)
    8000370a:	6105                	addi	sp,sp,32
    8000370c:	8082                	ret
    return -1;
    8000370e:	557d                	li	a0,-1
    80003710:	bfcd                	j	80003702 <fetchaddr+0x3e>
    80003712:	557d                	li	a0,-1
    80003714:	b7fd                	j	80003702 <fetchaddr+0x3e>

0000000080003716 <fetchstr>:
{
    80003716:	7179                	addi	sp,sp,-48
    80003718:	f406                	sd	ra,40(sp)
    8000371a:	f022                	sd	s0,32(sp)
    8000371c:	ec26                	sd	s1,24(sp)
    8000371e:	e84a                	sd	s2,16(sp)
    80003720:	e44e                	sd	s3,8(sp)
    80003722:	1800                	addi	s0,sp,48
    80003724:	892a                	mv	s2,a0
    80003726:	84ae                	mv	s1,a1
    80003728:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000372a:	fffff097          	auipc	ra,0xfffff
    8000372e:	bd2080e7          	jalr	-1070(ra) # 800022fc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003732:	86ce                	mv	a3,s3
    80003734:	864a                	mv	a2,s2
    80003736:	85a6                	mv	a1,s1
    80003738:	6d28                	ld	a0,88(a0)
    8000373a:	ffffe097          	auipc	ra,0xffffe
    8000373e:	074080e7          	jalr	116(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003742:	00054763          	bltz	a0,80003750 <fetchstr+0x3a>
  return strlen(buf);
    80003746:	8526                	mv	a0,s1
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	740080e7          	jalr	1856(ra) # 80000e88 <strlen>
}
    80003750:	70a2                	ld	ra,40(sp)
    80003752:	7402                	ld	s0,32(sp)
    80003754:	64e2                	ld	s1,24(sp)
    80003756:	6942                	ld	s2,16(sp)
    80003758:	69a2                	ld	s3,8(sp)
    8000375a:	6145                	addi	sp,sp,48
    8000375c:	8082                	ret

000000008000375e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000375e:	1101                	addi	sp,sp,-32
    80003760:	ec06                	sd	ra,24(sp)
    80003762:	e822                	sd	s0,16(sp)
    80003764:	e426                	sd	s1,8(sp)
    80003766:	1000                	addi	s0,sp,32
    80003768:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	ef2080e7          	jalr	-270(ra) # 8000365c <argraw>
    80003772:	c088                	sw	a0,0(s1)
  return 0;
}
    80003774:	4501                	li	a0,0
    80003776:	60e2                	ld	ra,24(sp)
    80003778:	6442                	ld	s0,16(sp)
    8000377a:	64a2                	ld	s1,8(sp)
    8000377c:	6105                	addi	sp,sp,32
    8000377e:	8082                	ret

0000000080003780 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003780:	1101                	addi	sp,sp,-32
    80003782:	ec06                	sd	ra,24(sp)
    80003784:	e822                	sd	s0,16(sp)
    80003786:	e426                	sd	s1,8(sp)
    80003788:	1000                	addi	s0,sp,32
    8000378a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	ed0080e7          	jalr	-304(ra) # 8000365c <argraw>
    80003794:	e088                	sd	a0,0(s1)
  return 0;
}
    80003796:	4501                	li	a0,0
    80003798:	60e2                	ld	ra,24(sp)
    8000379a:	6442                	ld	s0,16(sp)
    8000379c:	64a2                	ld	s1,8(sp)
    8000379e:	6105                	addi	sp,sp,32
    800037a0:	8082                	ret

00000000800037a2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800037a2:	1101                	addi	sp,sp,-32
    800037a4:	ec06                	sd	ra,24(sp)
    800037a6:	e822                	sd	s0,16(sp)
    800037a8:	e426                	sd	s1,8(sp)
    800037aa:	e04a                	sd	s2,0(sp)
    800037ac:	1000                	addi	s0,sp,32
    800037ae:	84ae                	mv	s1,a1
    800037b0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	eaa080e7          	jalr	-342(ra) # 8000365c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800037ba:	864a                	mv	a2,s2
    800037bc:	85a6                	mv	a1,s1
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	f58080e7          	jalr	-168(ra) # 80003716 <fetchstr>
}
    800037c6:	60e2                	ld	ra,24(sp)
    800037c8:	6442                	ld	s0,16(sp)
    800037ca:	64a2                	ld	s1,8(sp)
    800037cc:	6902                	ld	s2,0(sp)
    800037ce:	6105                	addi	sp,sp,32
    800037d0:	8082                	ret

00000000800037d2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800037d2:	1101                	addi	sp,sp,-32
    800037d4:	ec06                	sd	ra,24(sp)
    800037d6:	e822                	sd	s0,16(sp)
    800037d8:	e426                	sd	s1,8(sp)
    800037da:	e04a                	sd	s2,0(sp)
    800037dc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800037de:	fffff097          	auipc	ra,0xfffff
    800037e2:	b1e080e7          	jalr	-1250(ra) # 800022fc <myproc>
    800037e6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800037e8:	06053903          	ld	s2,96(a0)
    800037ec:	0a893783          	ld	a5,168(s2)
    800037f0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800037f4:	37fd                	addiw	a5,a5,-1
    800037f6:	4751                	li	a4,20
    800037f8:	00f76f63          	bltu	a4,a5,80003816 <syscall+0x44>
    800037fc:	00369713          	slli	a4,a3,0x3
    80003800:	00005797          	auipc	a5,0x5
    80003804:	14878793          	addi	a5,a5,328 # 80008948 <syscalls>
    80003808:	97ba                	add	a5,a5,a4
    8000380a:	639c                	ld	a5,0(a5)
    8000380c:	c789                	beqz	a5,80003816 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000380e:	9782                	jalr	a5
    80003810:	06a93823          	sd	a0,112(s2)
    80003814:	a839                	j	80003832 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003816:	16048613          	addi	a2,s1,352
    8000381a:	588c                	lw	a1,48(s1)
    8000381c:	00005517          	auipc	a0,0x5
    80003820:	0f450513          	addi	a0,a0,244 # 80008910 <states.1768+0x150>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	d64080e7          	jalr	-668(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000382c:	70bc                	ld	a5,96(s1)
    8000382e:	577d                	li	a4,-1
    80003830:	fbb8                	sd	a4,112(a5)
  }
}
    80003832:	60e2                	ld	ra,24(sp)
    80003834:	6442                	ld	s0,16(sp)
    80003836:	64a2                	ld	s1,8(sp)
    80003838:	6902                	ld	s2,0(sp)
    8000383a:	6105                	addi	sp,sp,32
    8000383c:	8082                	ret

000000008000383e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000383e:	1101                	addi	sp,sp,-32
    80003840:	ec06                	sd	ra,24(sp)
    80003842:	e822                	sd	s0,16(sp)
    80003844:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003846:	fec40593          	addi	a1,s0,-20
    8000384a:	4501                	li	a0,0
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	f12080e7          	jalr	-238(ra) # 8000375e <argint>
    return -1;
    80003854:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003856:	00054963          	bltz	a0,80003868 <sys_exit+0x2a>
  exit(n);
    8000385a:	fec42503          	lw	a0,-20(s0)
    8000385e:	fffff097          	auipc	ra,0xfffff
    80003862:	6ce080e7          	jalr	1742(ra) # 80002f2c <exit>
  return 0;  // not reached
    80003866:	4781                	li	a5,0
}
    80003868:	853e                	mv	a0,a5
    8000386a:	60e2                	ld	ra,24(sp)
    8000386c:	6442                	ld	s0,16(sp)
    8000386e:	6105                	addi	sp,sp,32
    80003870:	8082                	ret

0000000080003872 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003872:	1141                	addi	sp,sp,-16
    80003874:	e406                	sd	ra,8(sp)
    80003876:	e022                	sd	s0,0(sp)
    80003878:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000387a:	fffff097          	auipc	ra,0xfffff
    8000387e:	a82080e7          	jalr	-1406(ra) # 800022fc <myproc>
}
    80003882:	5908                	lw	a0,48(a0)
    80003884:	60a2                	ld	ra,8(sp)
    80003886:	6402                	ld	s0,0(sp)
    80003888:	0141                	addi	sp,sp,16
    8000388a:	8082                	ret

000000008000388c <sys_fork>:

uint64
sys_fork(void)
{
    8000388c:	1141                	addi	sp,sp,-16
    8000388e:	e406                	sd	ra,8(sp)
    80003890:	e022                	sd	s0,0(sp)
    80003892:	0800                	addi	s0,sp,16
  return fork();
    80003894:	fffff097          	auipc	ra,0xfffff
    80003898:	f4a080e7          	jalr	-182(ra) # 800027de <fork>
}
    8000389c:	60a2                	ld	ra,8(sp)
    8000389e:	6402                	ld	s0,0(sp)
    800038a0:	0141                	addi	sp,sp,16
    800038a2:	8082                	ret

00000000800038a4 <sys_wait>:

uint64
sys_wait(void)
{
    800038a4:	1101                	addi	sp,sp,-32
    800038a6:	ec06                	sd	ra,24(sp)
    800038a8:	e822                	sd	s0,16(sp)
    800038aa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800038ac:	fe840593          	addi	a1,s0,-24
    800038b0:	4501                	li	a0,0
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	ece080e7          	jalr	-306(ra) # 80003780 <argaddr>
    800038ba:	87aa                	mv	a5,a0
    return -1;
    800038bc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800038be:	0007c863          	bltz	a5,800038ce <sys_wait+0x2a>
  return wait(p);
    800038c2:	fe843503          	ld	a0,-24(s0)
    800038c6:	fffff097          	auipc	ra,0xfffff
    800038ca:	40a080e7          	jalr	1034(ra) # 80002cd0 <wait>
}
    800038ce:	60e2                	ld	ra,24(sp)
    800038d0:	6442                	ld	s0,16(sp)
    800038d2:	6105                	addi	sp,sp,32
    800038d4:	8082                	ret

00000000800038d6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800038d6:	7179                	addi	sp,sp,-48
    800038d8:	f406                	sd	ra,40(sp)
    800038da:	f022                	sd	s0,32(sp)
    800038dc:	ec26                	sd	s1,24(sp)
    800038de:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800038e0:	fdc40593          	addi	a1,s0,-36
    800038e4:	4501                	li	a0,0
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	e78080e7          	jalr	-392(ra) # 8000375e <argint>
    800038ee:	87aa                	mv	a5,a0
    return -1;
    800038f0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800038f2:	0207c063          	bltz	a5,80003912 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800038f6:	fffff097          	auipc	ra,0xfffff
    800038fa:	a06080e7          	jalr	-1530(ra) # 800022fc <myproc>
    800038fe:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80003900:	fdc42503          	lw	a0,-36(s0)
    80003904:	fffff097          	auipc	ra,0xfffff
    80003908:	e66080e7          	jalr	-410(ra) # 8000276a <growproc>
    8000390c:	00054863          	bltz	a0,8000391c <sys_sbrk+0x46>
    return -1;
  return addr;
    80003910:	8526                	mv	a0,s1
}
    80003912:	70a2                	ld	ra,40(sp)
    80003914:	7402                	ld	s0,32(sp)
    80003916:	64e2                	ld	s1,24(sp)
    80003918:	6145                	addi	sp,sp,48
    8000391a:	8082                	ret
    return -1;
    8000391c:	557d                	li	a0,-1
    8000391e:	bfd5                	j	80003912 <sys_sbrk+0x3c>

0000000080003920 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003920:	7139                	addi	sp,sp,-64
    80003922:	fc06                	sd	ra,56(sp)
    80003924:	f822                	sd	s0,48(sp)
    80003926:	f426                	sd	s1,40(sp)
    80003928:	f04a                	sd	s2,32(sp)
    8000392a:	ec4e                	sd	s3,24(sp)
    8000392c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000392e:	fcc40593          	addi	a1,s0,-52
    80003932:	4501                	li	a0,0
    80003934:	00000097          	auipc	ra,0x0
    80003938:	e2a080e7          	jalr	-470(ra) # 8000375e <argint>
    return -1;
    8000393c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000393e:	06054563          	bltz	a0,800039a8 <sys_sleep+0x88>
  acquire(&tickslock);
    80003942:	00014517          	auipc	a0,0x14
    80003946:	ab650513          	addi	a0,a0,-1354 # 800173f8 <tickslock>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	29a080e7          	jalr	666(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003952:	00005917          	auipc	s2,0x5
    80003956:	6de92903          	lw	s2,1758(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000395a:	fcc42783          	lw	a5,-52(s0)
    8000395e:	cf85                	beqz	a5,80003996 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003960:	00014997          	auipc	s3,0x14
    80003964:	a9898993          	addi	s3,s3,-1384 # 800173f8 <tickslock>
    80003968:	00005497          	auipc	s1,0x5
    8000396c:	6c848493          	addi	s1,s1,1736 # 80009030 <ticks>
    if(myproc()->killed){
    80003970:	fffff097          	auipc	ra,0xfffff
    80003974:	98c080e7          	jalr	-1652(ra) # 800022fc <myproc>
    80003978:	551c                	lw	a5,40(a0)
    8000397a:	ef9d                	bnez	a5,800039b8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000397c:	85ce                	mv	a1,s3
    8000397e:	8526                	mv	a0,s1
    80003980:	fffff097          	auipc	ra,0xfffff
    80003984:	2dc080e7          	jalr	732(ra) # 80002c5c <sleep>
  while(ticks - ticks0 < n){
    80003988:	409c                	lw	a5,0(s1)
    8000398a:	412787bb          	subw	a5,a5,s2
    8000398e:	fcc42703          	lw	a4,-52(s0)
    80003992:	fce7efe3          	bltu	a5,a4,80003970 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003996:	00014517          	auipc	a0,0x14
    8000399a:	a6250513          	addi	a0,a0,-1438 # 800173f8 <tickslock>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	30c080e7          	jalr	780(ra) # 80000caa <release>
  return 0;
    800039a6:	4781                	li	a5,0
}
    800039a8:	853e                	mv	a0,a5
    800039aa:	70e2                	ld	ra,56(sp)
    800039ac:	7442                	ld	s0,48(sp)
    800039ae:	74a2                	ld	s1,40(sp)
    800039b0:	7902                	ld	s2,32(sp)
    800039b2:	69e2                	ld	s3,24(sp)
    800039b4:	6121                	addi	sp,sp,64
    800039b6:	8082                	ret
      release(&tickslock);
    800039b8:	00014517          	auipc	a0,0x14
    800039bc:	a4050513          	addi	a0,a0,-1472 # 800173f8 <tickslock>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	2ea080e7          	jalr	746(ra) # 80000caa <release>
      return -1;
    800039c8:	57fd                	li	a5,-1
    800039ca:	bff9                	j	800039a8 <sys_sleep+0x88>

00000000800039cc <sys_kill>:

uint64
sys_kill(void)
{
    800039cc:	1101                	addi	sp,sp,-32
    800039ce:	ec06                	sd	ra,24(sp)
    800039d0:	e822                	sd	s0,16(sp)
    800039d2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800039d4:	fec40593          	addi	a1,s0,-20
    800039d8:	4501                	li	a0,0
    800039da:	00000097          	auipc	ra,0x0
    800039de:	d84080e7          	jalr	-636(ra) # 8000375e <argint>
    800039e2:	87aa                	mv	a5,a0
    return -1;
    800039e4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800039e6:	0007c863          	bltz	a5,800039f6 <sys_kill+0x2a>
  return kill(pid);
    800039ea:	fec42503          	lw	a0,-20(s0)
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	624080e7          	jalr	1572(ra) # 80003012 <kill>
}
    800039f6:	60e2                	ld	ra,24(sp)
    800039f8:	6442                	ld	s0,16(sp)
    800039fa:	6105                	addi	sp,sp,32
    800039fc:	8082                	ret

00000000800039fe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800039fe:	1101                	addi	sp,sp,-32
    80003a00:	ec06                	sd	ra,24(sp)
    80003a02:	e822                	sd	s0,16(sp)
    80003a04:	e426                	sd	s1,8(sp)
    80003a06:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003a08:	00014517          	auipc	a0,0x14
    80003a0c:	9f050513          	addi	a0,a0,-1552 # 800173f8 <tickslock>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	1d4080e7          	jalr	468(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003a18:	00005497          	auipc	s1,0x5
    80003a1c:	6184a483          	lw	s1,1560(s1) # 80009030 <ticks>
  release(&tickslock);
    80003a20:	00014517          	auipc	a0,0x14
    80003a24:	9d850513          	addi	a0,a0,-1576 # 800173f8 <tickslock>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	282080e7          	jalr	642(ra) # 80000caa <release>
  return xticks;
}
    80003a30:	02049513          	slli	a0,s1,0x20
    80003a34:	9101                	srli	a0,a0,0x20
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret

0000000080003a40 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a40:	7179                	addi	sp,sp,-48
    80003a42:	f406                	sd	ra,40(sp)
    80003a44:	f022                	sd	s0,32(sp)
    80003a46:	ec26                	sd	s1,24(sp)
    80003a48:	e84a                	sd	s2,16(sp)
    80003a4a:	e44e                	sd	s3,8(sp)
    80003a4c:	e052                	sd	s4,0(sp)
    80003a4e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a50:	00005597          	auipc	a1,0x5
    80003a54:	fa858593          	addi	a1,a1,-88 # 800089f8 <syscalls+0xb0>
    80003a58:	00014517          	auipc	a0,0x14
    80003a5c:	9b850513          	addi	a0,a0,-1608 # 80017410 <bcache>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	0f4080e7          	jalr	244(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a68:	0001c797          	auipc	a5,0x1c
    80003a6c:	9a878793          	addi	a5,a5,-1624 # 8001f410 <bcache+0x8000>
    80003a70:	0001c717          	auipc	a4,0x1c
    80003a74:	c0870713          	addi	a4,a4,-1016 # 8001f678 <bcache+0x8268>
    80003a78:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a7c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a80:	00014497          	auipc	s1,0x14
    80003a84:	9a848493          	addi	s1,s1,-1624 # 80017428 <bcache+0x18>
    b->next = bcache.head.next;
    80003a88:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a8a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a8c:	00005a17          	auipc	s4,0x5
    80003a90:	f74a0a13          	addi	s4,s4,-140 # 80008a00 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003a94:	2b893783          	ld	a5,696(s2)
    80003a98:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a9a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a9e:	85d2                	mv	a1,s4
    80003aa0:	01048513          	addi	a0,s1,16
    80003aa4:	00001097          	auipc	ra,0x1
    80003aa8:	4bc080e7          	jalr	1212(ra) # 80004f60 <initsleeplock>
    bcache.head.next->prev = b;
    80003aac:	2b893783          	ld	a5,696(s2)
    80003ab0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003ab2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ab6:	45848493          	addi	s1,s1,1112
    80003aba:	fd349de3          	bne	s1,s3,80003a94 <binit+0x54>
  }
}
    80003abe:	70a2                	ld	ra,40(sp)
    80003ac0:	7402                	ld	s0,32(sp)
    80003ac2:	64e2                	ld	s1,24(sp)
    80003ac4:	6942                	ld	s2,16(sp)
    80003ac6:	69a2                	ld	s3,8(sp)
    80003ac8:	6a02                	ld	s4,0(sp)
    80003aca:	6145                	addi	sp,sp,48
    80003acc:	8082                	ret

0000000080003ace <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003ace:	7179                	addi	sp,sp,-48
    80003ad0:	f406                	sd	ra,40(sp)
    80003ad2:	f022                	sd	s0,32(sp)
    80003ad4:	ec26                	sd	s1,24(sp)
    80003ad6:	e84a                	sd	s2,16(sp)
    80003ad8:	e44e                	sd	s3,8(sp)
    80003ada:	1800                	addi	s0,sp,48
    80003adc:	89aa                	mv	s3,a0
    80003ade:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003ae0:	00014517          	auipc	a0,0x14
    80003ae4:	93050513          	addi	a0,a0,-1744 # 80017410 <bcache>
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	0fc080e7          	jalr	252(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003af0:	0001c497          	auipc	s1,0x1c
    80003af4:	bd84b483          	ld	s1,-1064(s1) # 8001f6c8 <bcache+0x82b8>
    80003af8:	0001c797          	auipc	a5,0x1c
    80003afc:	b8078793          	addi	a5,a5,-1152 # 8001f678 <bcache+0x8268>
    80003b00:	02f48f63          	beq	s1,a5,80003b3e <bread+0x70>
    80003b04:	873e                	mv	a4,a5
    80003b06:	a021                	j	80003b0e <bread+0x40>
    80003b08:	68a4                	ld	s1,80(s1)
    80003b0a:	02e48a63          	beq	s1,a4,80003b3e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b0e:	449c                	lw	a5,8(s1)
    80003b10:	ff379ce3          	bne	a5,s3,80003b08 <bread+0x3a>
    80003b14:	44dc                	lw	a5,12(s1)
    80003b16:	ff2799e3          	bne	a5,s2,80003b08 <bread+0x3a>
      b->refcnt++;
    80003b1a:	40bc                	lw	a5,64(s1)
    80003b1c:	2785                	addiw	a5,a5,1
    80003b1e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b20:	00014517          	auipc	a0,0x14
    80003b24:	8f050513          	addi	a0,a0,-1808 # 80017410 <bcache>
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	182080e7          	jalr	386(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    80003b30:	01048513          	addi	a0,s1,16
    80003b34:	00001097          	auipc	ra,0x1
    80003b38:	466080e7          	jalr	1126(ra) # 80004f9a <acquiresleep>
      return b;
    80003b3c:	a8b9                	j	80003b9a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b3e:	0001c497          	auipc	s1,0x1c
    80003b42:	b824b483          	ld	s1,-1150(s1) # 8001f6c0 <bcache+0x82b0>
    80003b46:	0001c797          	auipc	a5,0x1c
    80003b4a:	b3278793          	addi	a5,a5,-1230 # 8001f678 <bcache+0x8268>
    80003b4e:	00f48863          	beq	s1,a5,80003b5e <bread+0x90>
    80003b52:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b54:	40bc                	lw	a5,64(s1)
    80003b56:	cf81                	beqz	a5,80003b6e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b58:	64a4                	ld	s1,72(s1)
    80003b5a:	fee49de3          	bne	s1,a4,80003b54 <bread+0x86>
  panic("bget: no buffers");
    80003b5e:	00005517          	auipc	a0,0x5
    80003b62:	eaa50513          	addi	a0,a0,-342 # 80008a08 <syscalls+0xc0>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	9d8080e7          	jalr	-1576(ra) # 8000053e <panic>
      b->dev = dev;
    80003b6e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003b72:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003b76:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b7a:	4785                	li	a5,1
    80003b7c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b7e:	00014517          	auipc	a0,0x14
    80003b82:	89250513          	addi	a0,a0,-1902 # 80017410 <bcache>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	124080e7          	jalr	292(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    80003b8e:	01048513          	addi	a0,s1,16
    80003b92:	00001097          	auipc	ra,0x1
    80003b96:	408080e7          	jalr	1032(ra) # 80004f9a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b9a:	409c                	lw	a5,0(s1)
    80003b9c:	cb89                	beqz	a5,80003bae <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	70a2                	ld	ra,40(sp)
    80003ba2:	7402                	ld	s0,32(sp)
    80003ba4:	64e2                	ld	s1,24(sp)
    80003ba6:	6942                	ld	s2,16(sp)
    80003ba8:	69a2                	ld	s3,8(sp)
    80003baa:	6145                	addi	sp,sp,48
    80003bac:	8082                	ret
    virtio_disk_rw(b, 0);
    80003bae:	4581                	li	a1,0
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	00003097          	auipc	ra,0x3
    80003bb6:	f14080e7          	jalr	-236(ra) # 80006ac6 <virtio_disk_rw>
    b->valid = 1;
    80003bba:	4785                	li	a5,1
    80003bbc:	c09c                	sw	a5,0(s1)
  return b;
    80003bbe:	b7c5                	j	80003b9e <bread+0xd0>

0000000080003bc0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003bc0:	1101                	addi	sp,sp,-32
    80003bc2:	ec06                	sd	ra,24(sp)
    80003bc4:	e822                	sd	s0,16(sp)
    80003bc6:	e426                	sd	s1,8(sp)
    80003bc8:	1000                	addi	s0,sp,32
    80003bca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bcc:	0541                	addi	a0,a0,16
    80003bce:	00001097          	auipc	ra,0x1
    80003bd2:	466080e7          	jalr	1126(ra) # 80005034 <holdingsleep>
    80003bd6:	cd01                	beqz	a0,80003bee <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003bd8:	4585                	li	a1,1
    80003bda:	8526                	mv	a0,s1
    80003bdc:	00003097          	auipc	ra,0x3
    80003be0:	eea080e7          	jalr	-278(ra) # 80006ac6 <virtio_disk_rw>
}
    80003be4:	60e2                	ld	ra,24(sp)
    80003be6:	6442                	ld	s0,16(sp)
    80003be8:	64a2                	ld	s1,8(sp)
    80003bea:	6105                	addi	sp,sp,32
    80003bec:	8082                	ret
    panic("bwrite");
    80003bee:	00005517          	auipc	a0,0x5
    80003bf2:	e3250513          	addi	a0,a0,-462 # 80008a20 <syscalls+0xd8>
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	948080e7          	jalr	-1720(ra) # 8000053e <panic>

0000000080003bfe <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003bfe:	1101                	addi	sp,sp,-32
    80003c00:	ec06                	sd	ra,24(sp)
    80003c02:	e822                	sd	s0,16(sp)
    80003c04:	e426                	sd	s1,8(sp)
    80003c06:	e04a                	sd	s2,0(sp)
    80003c08:	1000                	addi	s0,sp,32
    80003c0a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c0c:	01050913          	addi	s2,a0,16
    80003c10:	854a                	mv	a0,s2
    80003c12:	00001097          	auipc	ra,0x1
    80003c16:	422080e7          	jalr	1058(ra) # 80005034 <holdingsleep>
    80003c1a:	c92d                	beqz	a0,80003c8c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	00001097          	auipc	ra,0x1
    80003c22:	3d2080e7          	jalr	978(ra) # 80004ff0 <releasesleep>

  acquire(&bcache.lock);
    80003c26:	00013517          	auipc	a0,0x13
    80003c2a:	7ea50513          	addi	a0,a0,2026 # 80017410 <bcache>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	fb6080e7          	jalr	-74(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003c36:	40bc                	lw	a5,64(s1)
    80003c38:	37fd                	addiw	a5,a5,-1
    80003c3a:	0007871b          	sext.w	a4,a5
    80003c3e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c40:	eb05                	bnez	a4,80003c70 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c42:	68bc                	ld	a5,80(s1)
    80003c44:	64b8                	ld	a4,72(s1)
    80003c46:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c48:	64bc                	ld	a5,72(s1)
    80003c4a:	68b8                	ld	a4,80(s1)
    80003c4c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c4e:	0001b797          	auipc	a5,0x1b
    80003c52:	7c278793          	addi	a5,a5,1986 # 8001f410 <bcache+0x8000>
    80003c56:	2b87b703          	ld	a4,696(a5)
    80003c5a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c5c:	0001c717          	auipc	a4,0x1c
    80003c60:	a1c70713          	addi	a4,a4,-1508 # 8001f678 <bcache+0x8268>
    80003c64:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c66:	2b87b703          	ld	a4,696(a5)
    80003c6a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c6c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c70:	00013517          	auipc	a0,0x13
    80003c74:	7a050513          	addi	a0,a0,1952 # 80017410 <bcache>
    80003c78:	ffffd097          	auipc	ra,0xffffd
    80003c7c:	032080e7          	jalr	50(ra) # 80000caa <release>
}
    80003c80:	60e2                	ld	ra,24(sp)
    80003c82:	6442                	ld	s0,16(sp)
    80003c84:	64a2                	ld	s1,8(sp)
    80003c86:	6902                	ld	s2,0(sp)
    80003c88:	6105                	addi	sp,sp,32
    80003c8a:	8082                	ret
    panic("brelse");
    80003c8c:	00005517          	auipc	a0,0x5
    80003c90:	d9c50513          	addi	a0,a0,-612 # 80008a28 <syscalls+0xe0>
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	8aa080e7          	jalr	-1878(ra) # 8000053e <panic>

0000000080003c9c <bpin>:

void
bpin(struct buf *b) {
    80003c9c:	1101                	addi	sp,sp,-32
    80003c9e:	ec06                	sd	ra,24(sp)
    80003ca0:	e822                	sd	s0,16(sp)
    80003ca2:	e426                	sd	s1,8(sp)
    80003ca4:	1000                	addi	s0,sp,32
    80003ca6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003ca8:	00013517          	auipc	a0,0x13
    80003cac:	76850513          	addi	a0,a0,1896 # 80017410 <bcache>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	f34080e7          	jalr	-204(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003cb8:	40bc                	lw	a5,64(s1)
    80003cba:	2785                	addiw	a5,a5,1
    80003cbc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003cbe:	00013517          	auipc	a0,0x13
    80003cc2:	75250513          	addi	a0,a0,1874 # 80017410 <bcache>
    80003cc6:	ffffd097          	auipc	ra,0xffffd
    80003cca:	fe4080e7          	jalr	-28(ra) # 80000caa <release>
}
    80003cce:	60e2                	ld	ra,24(sp)
    80003cd0:	6442                	ld	s0,16(sp)
    80003cd2:	64a2                	ld	s1,8(sp)
    80003cd4:	6105                	addi	sp,sp,32
    80003cd6:	8082                	ret

0000000080003cd8 <bunpin>:

void
bunpin(struct buf *b) {
    80003cd8:	1101                	addi	sp,sp,-32
    80003cda:	ec06                	sd	ra,24(sp)
    80003cdc:	e822                	sd	s0,16(sp)
    80003cde:	e426                	sd	s1,8(sp)
    80003ce0:	1000                	addi	s0,sp,32
    80003ce2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003ce4:	00013517          	auipc	a0,0x13
    80003ce8:	72c50513          	addi	a0,a0,1836 # 80017410 <bcache>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	ef8080e7          	jalr	-264(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003cf4:	40bc                	lw	a5,64(s1)
    80003cf6:	37fd                	addiw	a5,a5,-1
    80003cf8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003cfa:	00013517          	auipc	a0,0x13
    80003cfe:	71650513          	addi	a0,a0,1814 # 80017410 <bcache>
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	fa8080e7          	jalr	-88(ra) # 80000caa <release>
}
    80003d0a:	60e2                	ld	ra,24(sp)
    80003d0c:	6442                	ld	s0,16(sp)
    80003d0e:	64a2                	ld	s1,8(sp)
    80003d10:	6105                	addi	sp,sp,32
    80003d12:	8082                	ret

0000000080003d14 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d14:	1101                	addi	sp,sp,-32
    80003d16:	ec06                	sd	ra,24(sp)
    80003d18:	e822                	sd	s0,16(sp)
    80003d1a:	e426                	sd	s1,8(sp)
    80003d1c:	e04a                	sd	s2,0(sp)
    80003d1e:	1000                	addi	s0,sp,32
    80003d20:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d22:	00d5d59b          	srliw	a1,a1,0xd
    80003d26:	0001c797          	auipc	a5,0x1c
    80003d2a:	dc67a783          	lw	a5,-570(a5) # 8001faec <sb+0x1c>
    80003d2e:	9dbd                	addw	a1,a1,a5
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	d9e080e7          	jalr	-610(ra) # 80003ace <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d38:	0074f713          	andi	a4,s1,7
    80003d3c:	4785                	li	a5,1
    80003d3e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d42:	14ce                	slli	s1,s1,0x33
    80003d44:	90d9                	srli	s1,s1,0x36
    80003d46:	00950733          	add	a4,a0,s1
    80003d4a:	05874703          	lbu	a4,88(a4)
    80003d4e:	00e7f6b3          	and	a3,a5,a4
    80003d52:	c69d                	beqz	a3,80003d80 <bfree+0x6c>
    80003d54:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d56:	94aa                	add	s1,s1,a0
    80003d58:	fff7c793          	not	a5,a5
    80003d5c:	8ff9                	and	a5,a5,a4
    80003d5e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d62:	00001097          	auipc	ra,0x1
    80003d66:	118080e7          	jalr	280(ra) # 80004e7a <log_write>
  brelse(bp);
    80003d6a:	854a                	mv	a0,s2
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	e92080e7          	jalr	-366(ra) # 80003bfe <brelse>
}
    80003d74:	60e2                	ld	ra,24(sp)
    80003d76:	6442                	ld	s0,16(sp)
    80003d78:	64a2                	ld	s1,8(sp)
    80003d7a:	6902                	ld	s2,0(sp)
    80003d7c:	6105                	addi	sp,sp,32
    80003d7e:	8082                	ret
    panic("freeing free block");
    80003d80:	00005517          	auipc	a0,0x5
    80003d84:	cb050513          	addi	a0,a0,-848 # 80008a30 <syscalls+0xe8>
    80003d88:	ffffc097          	auipc	ra,0xffffc
    80003d8c:	7b6080e7          	jalr	1974(ra) # 8000053e <panic>

0000000080003d90 <balloc>:
{
    80003d90:	711d                	addi	sp,sp,-96
    80003d92:	ec86                	sd	ra,88(sp)
    80003d94:	e8a2                	sd	s0,80(sp)
    80003d96:	e4a6                	sd	s1,72(sp)
    80003d98:	e0ca                	sd	s2,64(sp)
    80003d9a:	fc4e                	sd	s3,56(sp)
    80003d9c:	f852                	sd	s4,48(sp)
    80003d9e:	f456                	sd	s5,40(sp)
    80003da0:	f05a                	sd	s6,32(sp)
    80003da2:	ec5e                	sd	s7,24(sp)
    80003da4:	e862                	sd	s8,16(sp)
    80003da6:	e466                	sd	s9,8(sp)
    80003da8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003daa:	0001c797          	auipc	a5,0x1c
    80003dae:	d2a7a783          	lw	a5,-726(a5) # 8001fad4 <sb+0x4>
    80003db2:	cbd1                	beqz	a5,80003e46 <balloc+0xb6>
    80003db4:	8baa                	mv	s7,a0
    80003db6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003db8:	0001cb17          	auipc	s6,0x1c
    80003dbc:	d18b0b13          	addi	s6,s6,-744 # 8001fad0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dc0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003dc2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dc4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003dc6:	6c89                	lui	s9,0x2
    80003dc8:	a831                	j	80003de4 <balloc+0x54>
    brelse(bp);
    80003dca:	854a                	mv	a0,s2
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	e32080e7          	jalr	-462(ra) # 80003bfe <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003dd4:	015c87bb          	addw	a5,s9,s5
    80003dd8:	00078a9b          	sext.w	s5,a5
    80003ddc:	004b2703          	lw	a4,4(s6)
    80003de0:	06eaf363          	bgeu	s5,a4,80003e46 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003de4:	41fad79b          	sraiw	a5,s5,0x1f
    80003de8:	0137d79b          	srliw	a5,a5,0x13
    80003dec:	015787bb          	addw	a5,a5,s5
    80003df0:	40d7d79b          	sraiw	a5,a5,0xd
    80003df4:	01cb2583          	lw	a1,28(s6)
    80003df8:	9dbd                	addw	a1,a1,a5
    80003dfa:	855e                	mv	a0,s7
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	cd2080e7          	jalr	-814(ra) # 80003ace <bread>
    80003e04:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e06:	004b2503          	lw	a0,4(s6)
    80003e0a:	000a849b          	sext.w	s1,s5
    80003e0e:	8662                	mv	a2,s8
    80003e10:	faa4fde3          	bgeu	s1,a0,80003dca <balloc+0x3a>
      m = 1 << (bi % 8);
    80003e14:	41f6579b          	sraiw	a5,a2,0x1f
    80003e18:	01d7d69b          	srliw	a3,a5,0x1d
    80003e1c:	00c6873b          	addw	a4,a3,a2
    80003e20:	00777793          	andi	a5,a4,7
    80003e24:	9f95                	subw	a5,a5,a3
    80003e26:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e2a:	4037571b          	sraiw	a4,a4,0x3
    80003e2e:	00e906b3          	add	a3,s2,a4
    80003e32:	0586c683          	lbu	a3,88(a3)
    80003e36:	00d7f5b3          	and	a1,a5,a3
    80003e3a:	cd91                	beqz	a1,80003e56 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e3c:	2605                	addiw	a2,a2,1
    80003e3e:	2485                	addiw	s1,s1,1
    80003e40:	fd4618e3          	bne	a2,s4,80003e10 <balloc+0x80>
    80003e44:	b759                	j	80003dca <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e46:	00005517          	auipc	a0,0x5
    80003e4a:	c0250513          	addi	a0,a0,-1022 # 80008a48 <syscalls+0x100>
    80003e4e:	ffffc097          	auipc	ra,0xffffc
    80003e52:	6f0080e7          	jalr	1776(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e56:	974a                	add	a4,a4,s2
    80003e58:	8fd5                	or	a5,a5,a3
    80003e5a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e5e:	854a                	mv	a0,s2
    80003e60:	00001097          	auipc	ra,0x1
    80003e64:	01a080e7          	jalr	26(ra) # 80004e7a <log_write>
        brelse(bp);
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	d94080e7          	jalr	-620(ra) # 80003bfe <brelse>
  bp = bread(dev, bno);
    80003e72:	85a6                	mv	a1,s1
    80003e74:	855e                	mv	a0,s7
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	c58080e7          	jalr	-936(ra) # 80003ace <bread>
    80003e7e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e80:	40000613          	li	a2,1024
    80003e84:	4581                	li	a1,0
    80003e86:	05850513          	addi	a0,a0,88
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	e7a080e7          	jalr	-390(ra) # 80000d04 <memset>
  log_write(bp);
    80003e92:	854a                	mv	a0,s2
    80003e94:	00001097          	auipc	ra,0x1
    80003e98:	fe6080e7          	jalr	-26(ra) # 80004e7a <log_write>
  brelse(bp);
    80003e9c:	854a                	mv	a0,s2
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	d60080e7          	jalr	-672(ra) # 80003bfe <brelse>
}
    80003ea6:	8526                	mv	a0,s1
    80003ea8:	60e6                	ld	ra,88(sp)
    80003eaa:	6446                	ld	s0,80(sp)
    80003eac:	64a6                	ld	s1,72(sp)
    80003eae:	6906                	ld	s2,64(sp)
    80003eb0:	79e2                	ld	s3,56(sp)
    80003eb2:	7a42                	ld	s4,48(sp)
    80003eb4:	7aa2                	ld	s5,40(sp)
    80003eb6:	7b02                	ld	s6,32(sp)
    80003eb8:	6be2                	ld	s7,24(sp)
    80003eba:	6c42                	ld	s8,16(sp)
    80003ebc:	6ca2                	ld	s9,8(sp)
    80003ebe:	6125                	addi	sp,sp,96
    80003ec0:	8082                	ret

0000000080003ec2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ec2:	7179                	addi	sp,sp,-48
    80003ec4:	f406                	sd	ra,40(sp)
    80003ec6:	f022                	sd	s0,32(sp)
    80003ec8:	ec26                	sd	s1,24(sp)
    80003eca:	e84a                	sd	s2,16(sp)
    80003ecc:	e44e                	sd	s3,8(sp)
    80003ece:	e052                	sd	s4,0(sp)
    80003ed0:	1800                	addi	s0,sp,48
    80003ed2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ed4:	47ad                	li	a5,11
    80003ed6:	04b7fe63          	bgeu	a5,a1,80003f32 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003eda:	ff45849b          	addiw	s1,a1,-12
    80003ede:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ee2:	0ff00793          	li	a5,255
    80003ee6:	0ae7e363          	bltu	a5,a4,80003f8c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003eea:	08052583          	lw	a1,128(a0)
    80003eee:	c5ad                	beqz	a1,80003f58 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ef0:	00092503          	lw	a0,0(s2)
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	bda080e7          	jalr	-1062(ra) # 80003ace <bread>
    80003efc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003efe:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003f02:	02049593          	slli	a1,s1,0x20
    80003f06:	9181                	srli	a1,a1,0x20
    80003f08:	058a                	slli	a1,a1,0x2
    80003f0a:	00b784b3          	add	s1,a5,a1
    80003f0e:	0004a983          	lw	s3,0(s1)
    80003f12:	04098d63          	beqz	s3,80003f6c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003f16:	8552                	mv	a0,s4
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	ce6080e7          	jalr	-794(ra) # 80003bfe <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f20:	854e                	mv	a0,s3
    80003f22:	70a2                	ld	ra,40(sp)
    80003f24:	7402                	ld	s0,32(sp)
    80003f26:	64e2                	ld	s1,24(sp)
    80003f28:	6942                	ld	s2,16(sp)
    80003f2a:	69a2                	ld	s3,8(sp)
    80003f2c:	6a02                	ld	s4,0(sp)
    80003f2e:	6145                	addi	sp,sp,48
    80003f30:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f32:	02059493          	slli	s1,a1,0x20
    80003f36:	9081                	srli	s1,s1,0x20
    80003f38:	048a                	slli	s1,s1,0x2
    80003f3a:	94aa                	add	s1,s1,a0
    80003f3c:	0504a983          	lw	s3,80(s1)
    80003f40:	fe0990e3          	bnez	s3,80003f20 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f44:	4108                	lw	a0,0(a0)
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	e4a080e7          	jalr	-438(ra) # 80003d90 <balloc>
    80003f4e:	0005099b          	sext.w	s3,a0
    80003f52:	0534a823          	sw	s3,80(s1)
    80003f56:	b7e9                	j	80003f20 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003f58:	4108                	lw	a0,0(a0)
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	e36080e7          	jalr	-458(ra) # 80003d90 <balloc>
    80003f62:	0005059b          	sext.w	a1,a0
    80003f66:	08b92023          	sw	a1,128(s2)
    80003f6a:	b759                	j	80003ef0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003f6c:	00092503          	lw	a0,0(s2)
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	e20080e7          	jalr	-480(ra) # 80003d90 <balloc>
    80003f78:	0005099b          	sext.w	s3,a0
    80003f7c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003f80:	8552                	mv	a0,s4
    80003f82:	00001097          	auipc	ra,0x1
    80003f86:	ef8080e7          	jalr	-264(ra) # 80004e7a <log_write>
    80003f8a:	b771                	j	80003f16 <bmap+0x54>
  panic("bmap: out of range");
    80003f8c:	00005517          	auipc	a0,0x5
    80003f90:	ad450513          	addi	a0,a0,-1324 # 80008a60 <syscalls+0x118>
    80003f94:	ffffc097          	auipc	ra,0xffffc
    80003f98:	5aa080e7          	jalr	1450(ra) # 8000053e <panic>

0000000080003f9c <iget>:
{
    80003f9c:	7179                	addi	sp,sp,-48
    80003f9e:	f406                	sd	ra,40(sp)
    80003fa0:	f022                	sd	s0,32(sp)
    80003fa2:	ec26                	sd	s1,24(sp)
    80003fa4:	e84a                	sd	s2,16(sp)
    80003fa6:	e44e                	sd	s3,8(sp)
    80003fa8:	e052                	sd	s4,0(sp)
    80003faa:	1800                	addi	s0,sp,48
    80003fac:	89aa                	mv	s3,a0
    80003fae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003fb0:	0001c517          	auipc	a0,0x1c
    80003fb4:	b4050513          	addi	a0,a0,-1216 # 8001faf0 <itable>
    80003fb8:	ffffd097          	auipc	ra,0xffffd
    80003fbc:	c2c080e7          	jalr	-980(ra) # 80000be4 <acquire>
  empty = 0;
    80003fc0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fc2:	0001c497          	auipc	s1,0x1c
    80003fc6:	b4648493          	addi	s1,s1,-1210 # 8001fb08 <itable+0x18>
    80003fca:	0001d697          	auipc	a3,0x1d
    80003fce:	5ce68693          	addi	a3,a3,1486 # 80021598 <log>
    80003fd2:	a039                	j	80003fe0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fd4:	02090b63          	beqz	s2,8000400a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fd8:	08848493          	addi	s1,s1,136
    80003fdc:	02d48a63          	beq	s1,a3,80004010 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003fe0:	449c                	lw	a5,8(s1)
    80003fe2:	fef059e3          	blez	a5,80003fd4 <iget+0x38>
    80003fe6:	4098                	lw	a4,0(s1)
    80003fe8:	ff3716e3          	bne	a4,s3,80003fd4 <iget+0x38>
    80003fec:	40d8                	lw	a4,4(s1)
    80003fee:	ff4713e3          	bne	a4,s4,80003fd4 <iget+0x38>
      ip->ref++;
    80003ff2:	2785                	addiw	a5,a5,1
    80003ff4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ff6:	0001c517          	auipc	a0,0x1c
    80003ffa:	afa50513          	addi	a0,a0,-1286 # 8001faf0 <itable>
    80003ffe:	ffffd097          	auipc	ra,0xffffd
    80004002:	cac080e7          	jalr	-852(ra) # 80000caa <release>
      return ip;
    80004006:	8926                	mv	s2,s1
    80004008:	a03d                	j	80004036 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000400a:	f7f9                	bnez	a5,80003fd8 <iget+0x3c>
    8000400c:	8926                	mv	s2,s1
    8000400e:	b7e9                	j	80003fd8 <iget+0x3c>
  if(empty == 0)
    80004010:	02090c63          	beqz	s2,80004048 <iget+0xac>
  ip->dev = dev;
    80004014:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004018:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000401c:	4785                	li	a5,1
    8000401e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004022:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004026:	0001c517          	auipc	a0,0x1c
    8000402a:	aca50513          	addi	a0,a0,-1334 # 8001faf0 <itable>
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	c7c080e7          	jalr	-900(ra) # 80000caa <release>
}
    80004036:	854a                	mv	a0,s2
    80004038:	70a2                	ld	ra,40(sp)
    8000403a:	7402                	ld	s0,32(sp)
    8000403c:	64e2                	ld	s1,24(sp)
    8000403e:	6942                	ld	s2,16(sp)
    80004040:	69a2                	ld	s3,8(sp)
    80004042:	6a02                	ld	s4,0(sp)
    80004044:	6145                	addi	sp,sp,48
    80004046:	8082                	ret
    panic("iget: no inodes");
    80004048:	00005517          	auipc	a0,0x5
    8000404c:	a3050513          	addi	a0,a0,-1488 # 80008a78 <syscalls+0x130>
    80004050:	ffffc097          	auipc	ra,0xffffc
    80004054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>

0000000080004058 <fsinit>:
fsinit(int dev) {
    80004058:	7179                	addi	sp,sp,-48
    8000405a:	f406                	sd	ra,40(sp)
    8000405c:	f022                	sd	s0,32(sp)
    8000405e:	ec26                	sd	s1,24(sp)
    80004060:	e84a                	sd	s2,16(sp)
    80004062:	e44e                	sd	s3,8(sp)
    80004064:	1800                	addi	s0,sp,48
    80004066:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004068:	4585                	li	a1,1
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	a64080e7          	jalr	-1436(ra) # 80003ace <bread>
    80004072:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004074:	0001c997          	auipc	s3,0x1c
    80004078:	a5c98993          	addi	s3,s3,-1444 # 8001fad0 <sb>
    8000407c:	02000613          	li	a2,32
    80004080:	05850593          	addi	a1,a0,88
    80004084:	854e                	mv	a0,s3
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	cde080e7          	jalr	-802(ra) # 80000d64 <memmove>
  brelse(bp);
    8000408e:	8526                	mv	a0,s1
    80004090:	00000097          	auipc	ra,0x0
    80004094:	b6e080e7          	jalr	-1170(ra) # 80003bfe <brelse>
  if(sb.magic != FSMAGIC)
    80004098:	0009a703          	lw	a4,0(s3)
    8000409c:	102037b7          	lui	a5,0x10203
    800040a0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800040a4:	02f71263          	bne	a4,a5,800040c8 <fsinit+0x70>
  initlog(dev, &sb);
    800040a8:	0001c597          	auipc	a1,0x1c
    800040ac:	a2858593          	addi	a1,a1,-1496 # 8001fad0 <sb>
    800040b0:	854a                	mv	a0,s2
    800040b2:	00001097          	auipc	ra,0x1
    800040b6:	b4c080e7          	jalr	-1204(ra) # 80004bfe <initlog>
}
    800040ba:	70a2                	ld	ra,40(sp)
    800040bc:	7402                	ld	s0,32(sp)
    800040be:	64e2                	ld	s1,24(sp)
    800040c0:	6942                	ld	s2,16(sp)
    800040c2:	69a2                	ld	s3,8(sp)
    800040c4:	6145                	addi	sp,sp,48
    800040c6:	8082                	ret
    panic("invalid file system");
    800040c8:	00005517          	auipc	a0,0x5
    800040cc:	9c050513          	addi	a0,a0,-1600 # 80008a88 <syscalls+0x140>
    800040d0:	ffffc097          	auipc	ra,0xffffc
    800040d4:	46e080e7          	jalr	1134(ra) # 8000053e <panic>

00000000800040d8 <iinit>:
{
    800040d8:	7179                	addi	sp,sp,-48
    800040da:	f406                	sd	ra,40(sp)
    800040dc:	f022                	sd	s0,32(sp)
    800040de:	ec26                	sd	s1,24(sp)
    800040e0:	e84a                	sd	s2,16(sp)
    800040e2:	e44e                	sd	s3,8(sp)
    800040e4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800040e6:	00005597          	auipc	a1,0x5
    800040ea:	9ba58593          	addi	a1,a1,-1606 # 80008aa0 <syscalls+0x158>
    800040ee:	0001c517          	auipc	a0,0x1c
    800040f2:	a0250513          	addi	a0,a0,-1534 # 8001faf0 <itable>
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	a5e080e7          	jalr	-1442(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800040fe:	0001c497          	auipc	s1,0x1c
    80004102:	a1a48493          	addi	s1,s1,-1510 # 8001fb18 <itable+0x28>
    80004106:	0001d997          	auipc	s3,0x1d
    8000410a:	4a298993          	addi	s3,s3,1186 # 800215a8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000410e:	00005917          	auipc	s2,0x5
    80004112:	99a90913          	addi	s2,s2,-1638 # 80008aa8 <syscalls+0x160>
    80004116:	85ca                	mv	a1,s2
    80004118:	8526                	mv	a0,s1
    8000411a:	00001097          	auipc	ra,0x1
    8000411e:	e46080e7          	jalr	-442(ra) # 80004f60 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004122:	08848493          	addi	s1,s1,136
    80004126:	ff3498e3          	bne	s1,s3,80004116 <iinit+0x3e>
}
    8000412a:	70a2                	ld	ra,40(sp)
    8000412c:	7402                	ld	s0,32(sp)
    8000412e:	64e2                	ld	s1,24(sp)
    80004130:	6942                	ld	s2,16(sp)
    80004132:	69a2                	ld	s3,8(sp)
    80004134:	6145                	addi	sp,sp,48
    80004136:	8082                	ret

0000000080004138 <ialloc>:
{
    80004138:	715d                	addi	sp,sp,-80
    8000413a:	e486                	sd	ra,72(sp)
    8000413c:	e0a2                	sd	s0,64(sp)
    8000413e:	fc26                	sd	s1,56(sp)
    80004140:	f84a                	sd	s2,48(sp)
    80004142:	f44e                	sd	s3,40(sp)
    80004144:	f052                	sd	s4,32(sp)
    80004146:	ec56                	sd	s5,24(sp)
    80004148:	e85a                	sd	s6,16(sp)
    8000414a:	e45e                	sd	s7,8(sp)
    8000414c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000414e:	0001c717          	auipc	a4,0x1c
    80004152:	98e72703          	lw	a4,-1650(a4) # 8001fadc <sb+0xc>
    80004156:	4785                	li	a5,1
    80004158:	04e7fa63          	bgeu	a5,a4,800041ac <ialloc+0x74>
    8000415c:	8aaa                	mv	s5,a0
    8000415e:	8bae                	mv	s7,a1
    80004160:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004162:	0001ca17          	auipc	s4,0x1c
    80004166:	96ea0a13          	addi	s4,s4,-1682 # 8001fad0 <sb>
    8000416a:	00048b1b          	sext.w	s6,s1
    8000416e:	0044d593          	srli	a1,s1,0x4
    80004172:	018a2783          	lw	a5,24(s4)
    80004176:	9dbd                	addw	a1,a1,a5
    80004178:	8556                	mv	a0,s5
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	954080e7          	jalr	-1708(ra) # 80003ace <bread>
    80004182:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004184:	05850993          	addi	s3,a0,88
    80004188:	00f4f793          	andi	a5,s1,15
    8000418c:	079a                	slli	a5,a5,0x6
    8000418e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004190:	00099783          	lh	a5,0(s3)
    80004194:	c785                	beqz	a5,800041bc <ialloc+0x84>
    brelse(bp);
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	a68080e7          	jalr	-1432(ra) # 80003bfe <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000419e:	0485                	addi	s1,s1,1
    800041a0:	00ca2703          	lw	a4,12(s4)
    800041a4:	0004879b          	sext.w	a5,s1
    800041a8:	fce7e1e3          	bltu	a5,a4,8000416a <ialloc+0x32>
  panic("ialloc: no inodes");
    800041ac:	00005517          	auipc	a0,0x5
    800041b0:	90450513          	addi	a0,a0,-1788 # 80008ab0 <syscalls+0x168>
    800041b4:	ffffc097          	auipc	ra,0xffffc
    800041b8:	38a080e7          	jalr	906(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800041bc:	04000613          	li	a2,64
    800041c0:	4581                	li	a1,0
    800041c2:	854e                	mv	a0,s3
    800041c4:	ffffd097          	auipc	ra,0xffffd
    800041c8:	b40080e7          	jalr	-1216(ra) # 80000d04 <memset>
      dip->type = type;
    800041cc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800041d0:	854a                	mv	a0,s2
    800041d2:	00001097          	auipc	ra,0x1
    800041d6:	ca8080e7          	jalr	-856(ra) # 80004e7a <log_write>
      brelse(bp);
    800041da:	854a                	mv	a0,s2
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	a22080e7          	jalr	-1502(ra) # 80003bfe <brelse>
      return iget(dev, inum);
    800041e4:	85da                	mv	a1,s6
    800041e6:	8556                	mv	a0,s5
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	db4080e7          	jalr	-588(ra) # 80003f9c <iget>
}
    800041f0:	60a6                	ld	ra,72(sp)
    800041f2:	6406                	ld	s0,64(sp)
    800041f4:	74e2                	ld	s1,56(sp)
    800041f6:	7942                	ld	s2,48(sp)
    800041f8:	79a2                	ld	s3,40(sp)
    800041fa:	7a02                	ld	s4,32(sp)
    800041fc:	6ae2                	ld	s5,24(sp)
    800041fe:	6b42                	ld	s6,16(sp)
    80004200:	6ba2                	ld	s7,8(sp)
    80004202:	6161                	addi	sp,sp,80
    80004204:	8082                	ret

0000000080004206 <iupdate>:
{
    80004206:	1101                	addi	sp,sp,-32
    80004208:	ec06                	sd	ra,24(sp)
    8000420a:	e822                	sd	s0,16(sp)
    8000420c:	e426                	sd	s1,8(sp)
    8000420e:	e04a                	sd	s2,0(sp)
    80004210:	1000                	addi	s0,sp,32
    80004212:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004214:	415c                	lw	a5,4(a0)
    80004216:	0047d79b          	srliw	a5,a5,0x4
    8000421a:	0001c597          	auipc	a1,0x1c
    8000421e:	8ce5a583          	lw	a1,-1842(a1) # 8001fae8 <sb+0x18>
    80004222:	9dbd                	addw	a1,a1,a5
    80004224:	4108                	lw	a0,0(a0)
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	8a8080e7          	jalr	-1880(ra) # 80003ace <bread>
    8000422e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004230:	05850793          	addi	a5,a0,88
    80004234:	40c8                	lw	a0,4(s1)
    80004236:	893d                	andi	a0,a0,15
    80004238:	051a                	slli	a0,a0,0x6
    8000423a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000423c:	04449703          	lh	a4,68(s1)
    80004240:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004244:	04649703          	lh	a4,70(s1)
    80004248:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000424c:	04849703          	lh	a4,72(s1)
    80004250:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004254:	04a49703          	lh	a4,74(s1)
    80004258:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000425c:	44f8                	lw	a4,76(s1)
    8000425e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004260:	03400613          	li	a2,52
    80004264:	05048593          	addi	a1,s1,80
    80004268:	0531                	addi	a0,a0,12
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	afa080e7          	jalr	-1286(ra) # 80000d64 <memmove>
  log_write(bp);
    80004272:	854a                	mv	a0,s2
    80004274:	00001097          	auipc	ra,0x1
    80004278:	c06080e7          	jalr	-1018(ra) # 80004e7a <log_write>
  brelse(bp);
    8000427c:	854a                	mv	a0,s2
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	980080e7          	jalr	-1664(ra) # 80003bfe <brelse>
}
    80004286:	60e2                	ld	ra,24(sp)
    80004288:	6442                	ld	s0,16(sp)
    8000428a:	64a2                	ld	s1,8(sp)
    8000428c:	6902                	ld	s2,0(sp)
    8000428e:	6105                	addi	sp,sp,32
    80004290:	8082                	ret

0000000080004292 <idup>:
{
    80004292:	1101                	addi	sp,sp,-32
    80004294:	ec06                	sd	ra,24(sp)
    80004296:	e822                	sd	s0,16(sp)
    80004298:	e426                	sd	s1,8(sp)
    8000429a:	1000                	addi	s0,sp,32
    8000429c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000429e:	0001c517          	auipc	a0,0x1c
    800042a2:	85250513          	addi	a0,a0,-1966 # 8001faf0 <itable>
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	93e080e7          	jalr	-1730(ra) # 80000be4 <acquire>
  ip->ref++;
    800042ae:	449c                	lw	a5,8(s1)
    800042b0:	2785                	addiw	a5,a5,1
    800042b2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042b4:	0001c517          	auipc	a0,0x1c
    800042b8:	83c50513          	addi	a0,a0,-1988 # 8001faf0 <itable>
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	9ee080e7          	jalr	-1554(ra) # 80000caa <release>
}
    800042c4:	8526                	mv	a0,s1
    800042c6:	60e2                	ld	ra,24(sp)
    800042c8:	6442                	ld	s0,16(sp)
    800042ca:	64a2                	ld	s1,8(sp)
    800042cc:	6105                	addi	sp,sp,32
    800042ce:	8082                	ret

00000000800042d0 <ilock>:
{
    800042d0:	1101                	addi	sp,sp,-32
    800042d2:	ec06                	sd	ra,24(sp)
    800042d4:	e822                	sd	s0,16(sp)
    800042d6:	e426                	sd	s1,8(sp)
    800042d8:	e04a                	sd	s2,0(sp)
    800042da:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800042dc:	c115                	beqz	a0,80004300 <ilock+0x30>
    800042de:	84aa                	mv	s1,a0
    800042e0:	451c                	lw	a5,8(a0)
    800042e2:	00f05f63          	blez	a5,80004300 <ilock+0x30>
  acquiresleep(&ip->lock);
    800042e6:	0541                	addi	a0,a0,16
    800042e8:	00001097          	auipc	ra,0x1
    800042ec:	cb2080e7          	jalr	-846(ra) # 80004f9a <acquiresleep>
  if(ip->valid == 0){
    800042f0:	40bc                	lw	a5,64(s1)
    800042f2:	cf99                	beqz	a5,80004310 <ilock+0x40>
}
    800042f4:	60e2                	ld	ra,24(sp)
    800042f6:	6442                	ld	s0,16(sp)
    800042f8:	64a2                	ld	s1,8(sp)
    800042fa:	6902                	ld	s2,0(sp)
    800042fc:	6105                	addi	sp,sp,32
    800042fe:	8082                	ret
    panic("ilock");
    80004300:	00004517          	auipc	a0,0x4
    80004304:	7c850513          	addi	a0,a0,1992 # 80008ac8 <syscalls+0x180>
    80004308:	ffffc097          	auipc	ra,0xffffc
    8000430c:	236080e7          	jalr	566(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004310:	40dc                	lw	a5,4(s1)
    80004312:	0047d79b          	srliw	a5,a5,0x4
    80004316:	0001b597          	auipc	a1,0x1b
    8000431a:	7d25a583          	lw	a1,2002(a1) # 8001fae8 <sb+0x18>
    8000431e:	9dbd                	addw	a1,a1,a5
    80004320:	4088                	lw	a0,0(s1)
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	7ac080e7          	jalr	1964(ra) # 80003ace <bread>
    8000432a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000432c:	05850593          	addi	a1,a0,88
    80004330:	40dc                	lw	a5,4(s1)
    80004332:	8bbd                	andi	a5,a5,15
    80004334:	079a                	slli	a5,a5,0x6
    80004336:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004338:	00059783          	lh	a5,0(a1)
    8000433c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004340:	00259783          	lh	a5,2(a1)
    80004344:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004348:	00459783          	lh	a5,4(a1)
    8000434c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004350:	00659783          	lh	a5,6(a1)
    80004354:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004358:	459c                	lw	a5,8(a1)
    8000435a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000435c:	03400613          	li	a2,52
    80004360:	05b1                	addi	a1,a1,12
    80004362:	05048513          	addi	a0,s1,80
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	9fe080e7          	jalr	-1538(ra) # 80000d64 <memmove>
    brelse(bp);
    8000436e:	854a                	mv	a0,s2
    80004370:	00000097          	auipc	ra,0x0
    80004374:	88e080e7          	jalr	-1906(ra) # 80003bfe <brelse>
    ip->valid = 1;
    80004378:	4785                	li	a5,1
    8000437a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000437c:	04449783          	lh	a5,68(s1)
    80004380:	fbb5                	bnez	a5,800042f4 <ilock+0x24>
      panic("ilock: no type");
    80004382:	00004517          	auipc	a0,0x4
    80004386:	74e50513          	addi	a0,a0,1870 # 80008ad0 <syscalls+0x188>
    8000438a:	ffffc097          	auipc	ra,0xffffc
    8000438e:	1b4080e7          	jalr	436(ra) # 8000053e <panic>

0000000080004392 <iunlock>:
{
    80004392:	1101                	addi	sp,sp,-32
    80004394:	ec06                	sd	ra,24(sp)
    80004396:	e822                	sd	s0,16(sp)
    80004398:	e426                	sd	s1,8(sp)
    8000439a:	e04a                	sd	s2,0(sp)
    8000439c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000439e:	c905                	beqz	a0,800043ce <iunlock+0x3c>
    800043a0:	84aa                	mv	s1,a0
    800043a2:	01050913          	addi	s2,a0,16
    800043a6:	854a                	mv	a0,s2
    800043a8:	00001097          	auipc	ra,0x1
    800043ac:	c8c080e7          	jalr	-884(ra) # 80005034 <holdingsleep>
    800043b0:	cd19                	beqz	a0,800043ce <iunlock+0x3c>
    800043b2:	449c                	lw	a5,8(s1)
    800043b4:	00f05d63          	blez	a5,800043ce <iunlock+0x3c>
  releasesleep(&ip->lock);
    800043b8:	854a                	mv	a0,s2
    800043ba:	00001097          	auipc	ra,0x1
    800043be:	c36080e7          	jalr	-970(ra) # 80004ff0 <releasesleep>
}
    800043c2:	60e2                	ld	ra,24(sp)
    800043c4:	6442                	ld	s0,16(sp)
    800043c6:	64a2                	ld	s1,8(sp)
    800043c8:	6902                	ld	s2,0(sp)
    800043ca:	6105                	addi	sp,sp,32
    800043cc:	8082                	ret
    panic("iunlock");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	71250513          	addi	a0,a0,1810 # 80008ae0 <syscalls+0x198>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	168080e7          	jalr	360(ra) # 8000053e <panic>

00000000800043de <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800043de:	7179                	addi	sp,sp,-48
    800043e0:	f406                	sd	ra,40(sp)
    800043e2:	f022                	sd	s0,32(sp)
    800043e4:	ec26                	sd	s1,24(sp)
    800043e6:	e84a                	sd	s2,16(sp)
    800043e8:	e44e                	sd	s3,8(sp)
    800043ea:	e052                	sd	s4,0(sp)
    800043ec:	1800                	addi	s0,sp,48
    800043ee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800043f0:	05050493          	addi	s1,a0,80
    800043f4:	08050913          	addi	s2,a0,128
    800043f8:	a021                	j	80004400 <itrunc+0x22>
    800043fa:	0491                	addi	s1,s1,4
    800043fc:	01248d63          	beq	s1,s2,80004416 <itrunc+0x38>
    if(ip->addrs[i]){
    80004400:	408c                	lw	a1,0(s1)
    80004402:	dde5                	beqz	a1,800043fa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004404:	0009a503          	lw	a0,0(s3)
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	90c080e7          	jalr	-1780(ra) # 80003d14 <bfree>
      ip->addrs[i] = 0;
    80004410:	0004a023          	sw	zero,0(s1)
    80004414:	b7dd                	j	800043fa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004416:	0809a583          	lw	a1,128(s3)
    8000441a:	e185                	bnez	a1,8000443a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000441c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004420:	854e                	mv	a0,s3
    80004422:	00000097          	auipc	ra,0x0
    80004426:	de4080e7          	jalr	-540(ra) # 80004206 <iupdate>
}
    8000442a:	70a2                	ld	ra,40(sp)
    8000442c:	7402                	ld	s0,32(sp)
    8000442e:	64e2                	ld	s1,24(sp)
    80004430:	6942                	ld	s2,16(sp)
    80004432:	69a2                	ld	s3,8(sp)
    80004434:	6a02                	ld	s4,0(sp)
    80004436:	6145                	addi	sp,sp,48
    80004438:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000443a:	0009a503          	lw	a0,0(s3)
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	690080e7          	jalr	1680(ra) # 80003ace <bread>
    80004446:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004448:	05850493          	addi	s1,a0,88
    8000444c:	45850913          	addi	s2,a0,1112
    80004450:	a811                	j	80004464 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004452:	0009a503          	lw	a0,0(s3)
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	8be080e7          	jalr	-1858(ra) # 80003d14 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000445e:	0491                	addi	s1,s1,4
    80004460:	01248563          	beq	s1,s2,8000446a <itrunc+0x8c>
      if(a[j])
    80004464:	408c                	lw	a1,0(s1)
    80004466:	dde5                	beqz	a1,8000445e <itrunc+0x80>
    80004468:	b7ed                	j	80004452 <itrunc+0x74>
    brelse(bp);
    8000446a:	8552                	mv	a0,s4
    8000446c:	fffff097          	auipc	ra,0xfffff
    80004470:	792080e7          	jalr	1938(ra) # 80003bfe <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004474:	0809a583          	lw	a1,128(s3)
    80004478:	0009a503          	lw	a0,0(s3)
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	898080e7          	jalr	-1896(ra) # 80003d14 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004484:	0809a023          	sw	zero,128(s3)
    80004488:	bf51                	j	8000441c <itrunc+0x3e>

000000008000448a <iput>:
{
    8000448a:	1101                	addi	sp,sp,-32
    8000448c:	ec06                	sd	ra,24(sp)
    8000448e:	e822                	sd	s0,16(sp)
    80004490:	e426                	sd	s1,8(sp)
    80004492:	e04a                	sd	s2,0(sp)
    80004494:	1000                	addi	s0,sp,32
    80004496:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004498:	0001b517          	auipc	a0,0x1b
    8000449c:	65850513          	addi	a0,a0,1624 # 8001faf0 <itable>
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	744080e7          	jalr	1860(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044a8:	4498                	lw	a4,8(s1)
    800044aa:	4785                	li	a5,1
    800044ac:	02f70363          	beq	a4,a5,800044d2 <iput+0x48>
  ip->ref--;
    800044b0:	449c                	lw	a5,8(s1)
    800044b2:	37fd                	addiw	a5,a5,-1
    800044b4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044b6:	0001b517          	auipc	a0,0x1b
    800044ba:	63a50513          	addi	a0,a0,1594 # 8001faf0 <itable>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7ec080e7          	jalr	2028(ra) # 80000caa <release>
}
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6902                	ld	s2,0(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044d2:	40bc                	lw	a5,64(s1)
    800044d4:	dff1                	beqz	a5,800044b0 <iput+0x26>
    800044d6:	04a49783          	lh	a5,74(s1)
    800044da:	fbf9                	bnez	a5,800044b0 <iput+0x26>
    acquiresleep(&ip->lock);
    800044dc:	01048913          	addi	s2,s1,16
    800044e0:	854a                	mv	a0,s2
    800044e2:	00001097          	auipc	ra,0x1
    800044e6:	ab8080e7          	jalr	-1352(ra) # 80004f9a <acquiresleep>
    release(&itable.lock);
    800044ea:	0001b517          	auipc	a0,0x1b
    800044ee:	60650513          	addi	a0,a0,1542 # 8001faf0 <itable>
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	7b8080e7          	jalr	1976(ra) # 80000caa <release>
    itrunc(ip);
    800044fa:	8526                	mv	a0,s1
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	ee2080e7          	jalr	-286(ra) # 800043de <itrunc>
    ip->type = 0;
    80004504:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004508:	8526                	mv	a0,s1
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	cfc080e7          	jalr	-772(ra) # 80004206 <iupdate>
    ip->valid = 0;
    80004512:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004516:	854a                	mv	a0,s2
    80004518:	00001097          	auipc	ra,0x1
    8000451c:	ad8080e7          	jalr	-1320(ra) # 80004ff0 <releasesleep>
    acquire(&itable.lock);
    80004520:	0001b517          	auipc	a0,0x1b
    80004524:	5d050513          	addi	a0,a0,1488 # 8001faf0 <itable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	6bc080e7          	jalr	1724(ra) # 80000be4 <acquire>
    80004530:	b741                	j	800044b0 <iput+0x26>

0000000080004532 <iunlockput>:
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	1000                	addi	s0,sp,32
    8000453c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000453e:	00000097          	auipc	ra,0x0
    80004542:	e54080e7          	jalr	-428(ra) # 80004392 <iunlock>
  iput(ip);
    80004546:	8526                	mv	a0,s1
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	f42080e7          	jalr	-190(ra) # 8000448a <iput>
}
    80004550:	60e2                	ld	ra,24(sp)
    80004552:	6442                	ld	s0,16(sp)
    80004554:	64a2                	ld	s1,8(sp)
    80004556:	6105                	addi	sp,sp,32
    80004558:	8082                	ret

000000008000455a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000455a:	1141                	addi	sp,sp,-16
    8000455c:	e422                	sd	s0,8(sp)
    8000455e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004560:	411c                	lw	a5,0(a0)
    80004562:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004564:	415c                	lw	a5,4(a0)
    80004566:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004568:	04451783          	lh	a5,68(a0)
    8000456c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004570:	04a51783          	lh	a5,74(a0)
    80004574:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004578:	04c56783          	lwu	a5,76(a0)
    8000457c:	e99c                	sd	a5,16(a1)
}
    8000457e:	6422                	ld	s0,8(sp)
    80004580:	0141                	addi	sp,sp,16
    80004582:	8082                	ret

0000000080004584 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004584:	457c                	lw	a5,76(a0)
    80004586:	0ed7e963          	bltu	a5,a3,80004678 <readi+0xf4>
{
    8000458a:	7159                	addi	sp,sp,-112
    8000458c:	f486                	sd	ra,104(sp)
    8000458e:	f0a2                	sd	s0,96(sp)
    80004590:	eca6                	sd	s1,88(sp)
    80004592:	e8ca                	sd	s2,80(sp)
    80004594:	e4ce                	sd	s3,72(sp)
    80004596:	e0d2                	sd	s4,64(sp)
    80004598:	fc56                	sd	s5,56(sp)
    8000459a:	f85a                	sd	s6,48(sp)
    8000459c:	f45e                	sd	s7,40(sp)
    8000459e:	f062                	sd	s8,32(sp)
    800045a0:	ec66                	sd	s9,24(sp)
    800045a2:	e86a                	sd	s10,16(sp)
    800045a4:	e46e                	sd	s11,8(sp)
    800045a6:	1880                	addi	s0,sp,112
    800045a8:	8baa                	mv	s7,a0
    800045aa:	8c2e                	mv	s8,a1
    800045ac:	8ab2                	mv	s5,a2
    800045ae:	84b6                	mv	s1,a3
    800045b0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800045b2:	9f35                	addw	a4,a4,a3
    return 0;
    800045b4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800045b6:	0ad76063          	bltu	a4,a3,80004656 <readi+0xd2>
  if(off + n > ip->size)
    800045ba:	00e7f463          	bgeu	a5,a4,800045c2 <readi+0x3e>
    n = ip->size - off;
    800045be:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045c2:	0a0b0963          	beqz	s6,80004674 <readi+0xf0>
    800045c6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800045c8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800045cc:	5cfd                	li	s9,-1
    800045ce:	a82d                	j	80004608 <readi+0x84>
    800045d0:	020a1d93          	slli	s11,s4,0x20
    800045d4:	020ddd93          	srli	s11,s11,0x20
    800045d8:	05890613          	addi	a2,s2,88
    800045dc:	86ee                	mv	a3,s11
    800045de:	963a                	add	a2,a2,a4
    800045e0:	85d6                	mv	a1,s5
    800045e2:	8562                	mv	a0,s8
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	aa0080e7          	jalr	-1376(ra) # 80003084 <either_copyout>
    800045ec:	05950d63          	beq	a0,s9,80004646 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800045f0:	854a                	mv	a0,s2
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	60c080e7          	jalr	1548(ra) # 80003bfe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045fa:	013a09bb          	addw	s3,s4,s3
    800045fe:	009a04bb          	addw	s1,s4,s1
    80004602:	9aee                	add	s5,s5,s11
    80004604:	0569f763          	bgeu	s3,s6,80004652 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004608:	000ba903          	lw	s2,0(s7)
    8000460c:	00a4d59b          	srliw	a1,s1,0xa
    80004610:	855e                	mv	a0,s7
    80004612:	00000097          	auipc	ra,0x0
    80004616:	8b0080e7          	jalr	-1872(ra) # 80003ec2 <bmap>
    8000461a:	0005059b          	sext.w	a1,a0
    8000461e:	854a                	mv	a0,s2
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	4ae080e7          	jalr	1198(ra) # 80003ace <bread>
    80004628:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000462a:	3ff4f713          	andi	a4,s1,1023
    8000462e:	40ed07bb          	subw	a5,s10,a4
    80004632:	413b06bb          	subw	a3,s6,s3
    80004636:	8a3e                	mv	s4,a5
    80004638:	2781                	sext.w	a5,a5
    8000463a:	0006861b          	sext.w	a2,a3
    8000463e:	f8f679e3          	bgeu	a2,a5,800045d0 <readi+0x4c>
    80004642:	8a36                	mv	s4,a3
    80004644:	b771                	j	800045d0 <readi+0x4c>
      brelse(bp);
    80004646:	854a                	mv	a0,s2
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	5b6080e7          	jalr	1462(ra) # 80003bfe <brelse>
      tot = -1;
    80004650:	59fd                	li	s3,-1
  }
  return tot;
    80004652:	0009851b          	sext.w	a0,s3
}
    80004656:	70a6                	ld	ra,104(sp)
    80004658:	7406                	ld	s0,96(sp)
    8000465a:	64e6                	ld	s1,88(sp)
    8000465c:	6946                	ld	s2,80(sp)
    8000465e:	69a6                	ld	s3,72(sp)
    80004660:	6a06                	ld	s4,64(sp)
    80004662:	7ae2                	ld	s5,56(sp)
    80004664:	7b42                	ld	s6,48(sp)
    80004666:	7ba2                	ld	s7,40(sp)
    80004668:	7c02                	ld	s8,32(sp)
    8000466a:	6ce2                	ld	s9,24(sp)
    8000466c:	6d42                	ld	s10,16(sp)
    8000466e:	6da2                	ld	s11,8(sp)
    80004670:	6165                	addi	sp,sp,112
    80004672:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004674:	89da                	mv	s3,s6
    80004676:	bff1                	j	80004652 <readi+0xce>
    return 0;
    80004678:	4501                	li	a0,0
}
    8000467a:	8082                	ret

000000008000467c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000467c:	457c                	lw	a5,76(a0)
    8000467e:	10d7e863          	bltu	a5,a3,8000478e <writei+0x112>
{
    80004682:	7159                	addi	sp,sp,-112
    80004684:	f486                	sd	ra,104(sp)
    80004686:	f0a2                	sd	s0,96(sp)
    80004688:	eca6                	sd	s1,88(sp)
    8000468a:	e8ca                	sd	s2,80(sp)
    8000468c:	e4ce                	sd	s3,72(sp)
    8000468e:	e0d2                	sd	s4,64(sp)
    80004690:	fc56                	sd	s5,56(sp)
    80004692:	f85a                	sd	s6,48(sp)
    80004694:	f45e                	sd	s7,40(sp)
    80004696:	f062                	sd	s8,32(sp)
    80004698:	ec66                	sd	s9,24(sp)
    8000469a:	e86a                	sd	s10,16(sp)
    8000469c:	e46e                	sd	s11,8(sp)
    8000469e:	1880                	addi	s0,sp,112
    800046a0:	8b2a                	mv	s6,a0
    800046a2:	8c2e                	mv	s8,a1
    800046a4:	8ab2                	mv	s5,a2
    800046a6:	8936                	mv	s2,a3
    800046a8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800046aa:	00e687bb          	addw	a5,a3,a4
    800046ae:	0ed7e263          	bltu	a5,a3,80004792 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800046b2:	00043737          	lui	a4,0x43
    800046b6:	0ef76063          	bltu	a4,a5,80004796 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046ba:	0c0b8863          	beqz	s7,8000478a <writei+0x10e>
    800046be:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800046c0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800046c4:	5cfd                	li	s9,-1
    800046c6:	a091                	j	8000470a <writei+0x8e>
    800046c8:	02099d93          	slli	s11,s3,0x20
    800046cc:	020ddd93          	srli	s11,s11,0x20
    800046d0:	05848513          	addi	a0,s1,88
    800046d4:	86ee                	mv	a3,s11
    800046d6:	8656                	mv	a2,s5
    800046d8:	85e2                	mv	a1,s8
    800046da:	953a                	add	a0,a0,a4
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	a0e080e7          	jalr	-1522(ra) # 800030ea <either_copyin>
    800046e4:	07950263          	beq	a0,s9,80004748 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800046e8:	8526                	mv	a0,s1
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	790080e7          	jalr	1936(ra) # 80004e7a <log_write>
    brelse(bp);
    800046f2:	8526                	mv	a0,s1
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	50a080e7          	jalr	1290(ra) # 80003bfe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046fc:	01498a3b          	addw	s4,s3,s4
    80004700:	0129893b          	addw	s2,s3,s2
    80004704:	9aee                	add	s5,s5,s11
    80004706:	057a7663          	bgeu	s4,s7,80004752 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000470a:	000b2483          	lw	s1,0(s6)
    8000470e:	00a9559b          	srliw	a1,s2,0xa
    80004712:	855a                	mv	a0,s6
    80004714:	fffff097          	auipc	ra,0xfffff
    80004718:	7ae080e7          	jalr	1966(ra) # 80003ec2 <bmap>
    8000471c:	0005059b          	sext.w	a1,a0
    80004720:	8526                	mv	a0,s1
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	3ac080e7          	jalr	940(ra) # 80003ace <bread>
    8000472a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000472c:	3ff97713          	andi	a4,s2,1023
    80004730:	40ed07bb          	subw	a5,s10,a4
    80004734:	414b86bb          	subw	a3,s7,s4
    80004738:	89be                	mv	s3,a5
    8000473a:	2781                	sext.w	a5,a5
    8000473c:	0006861b          	sext.w	a2,a3
    80004740:	f8f674e3          	bgeu	a2,a5,800046c8 <writei+0x4c>
    80004744:	89b6                	mv	s3,a3
    80004746:	b749                	j	800046c8 <writei+0x4c>
      brelse(bp);
    80004748:	8526                	mv	a0,s1
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	4b4080e7          	jalr	1204(ra) # 80003bfe <brelse>
  }

  if(off > ip->size)
    80004752:	04cb2783          	lw	a5,76(s6)
    80004756:	0127f463          	bgeu	a5,s2,8000475e <writei+0xe2>
    ip->size = off;
    8000475a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000475e:	855a                	mv	a0,s6
    80004760:	00000097          	auipc	ra,0x0
    80004764:	aa6080e7          	jalr	-1370(ra) # 80004206 <iupdate>

  return tot;
    80004768:	000a051b          	sext.w	a0,s4
}
    8000476c:	70a6                	ld	ra,104(sp)
    8000476e:	7406                	ld	s0,96(sp)
    80004770:	64e6                	ld	s1,88(sp)
    80004772:	6946                	ld	s2,80(sp)
    80004774:	69a6                	ld	s3,72(sp)
    80004776:	6a06                	ld	s4,64(sp)
    80004778:	7ae2                	ld	s5,56(sp)
    8000477a:	7b42                	ld	s6,48(sp)
    8000477c:	7ba2                	ld	s7,40(sp)
    8000477e:	7c02                	ld	s8,32(sp)
    80004780:	6ce2                	ld	s9,24(sp)
    80004782:	6d42                	ld	s10,16(sp)
    80004784:	6da2                	ld	s11,8(sp)
    80004786:	6165                	addi	sp,sp,112
    80004788:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000478a:	8a5e                	mv	s4,s7
    8000478c:	bfc9                	j	8000475e <writei+0xe2>
    return -1;
    8000478e:	557d                	li	a0,-1
}
    80004790:	8082                	ret
    return -1;
    80004792:	557d                	li	a0,-1
    80004794:	bfe1                	j	8000476c <writei+0xf0>
    return -1;
    80004796:	557d                	li	a0,-1
    80004798:	bfd1                	j	8000476c <writei+0xf0>

000000008000479a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000479a:	1141                	addi	sp,sp,-16
    8000479c:	e406                	sd	ra,8(sp)
    8000479e:	e022                	sd	s0,0(sp)
    800047a0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800047a2:	4639                	li	a2,14
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	638080e7          	jalr	1592(ra) # 80000ddc <strncmp>
}
    800047ac:	60a2                	ld	ra,8(sp)
    800047ae:	6402                	ld	s0,0(sp)
    800047b0:	0141                	addi	sp,sp,16
    800047b2:	8082                	ret

00000000800047b4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800047b4:	7139                	addi	sp,sp,-64
    800047b6:	fc06                	sd	ra,56(sp)
    800047b8:	f822                	sd	s0,48(sp)
    800047ba:	f426                	sd	s1,40(sp)
    800047bc:	f04a                	sd	s2,32(sp)
    800047be:	ec4e                	sd	s3,24(sp)
    800047c0:	e852                	sd	s4,16(sp)
    800047c2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800047c4:	04451703          	lh	a4,68(a0)
    800047c8:	4785                	li	a5,1
    800047ca:	00f71a63          	bne	a4,a5,800047de <dirlookup+0x2a>
    800047ce:	892a                	mv	s2,a0
    800047d0:	89ae                	mv	s3,a1
    800047d2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800047d4:	457c                	lw	a5,76(a0)
    800047d6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800047d8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047da:	e79d                	bnez	a5,80004808 <dirlookup+0x54>
    800047dc:	a8a5                	j	80004854 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800047de:	00004517          	auipc	a0,0x4
    800047e2:	30a50513          	addi	a0,a0,778 # 80008ae8 <syscalls+0x1a0>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	d58080e7          	jalr	-680(ra) # 8000053e <panic>
      panic("dirlookup read");
    800047ee:	00004517          	auipc	a0,0x4
    800047f2:	31250513          	addi	a0,a0,786 # 80008b00 <syscalls+0x1b8>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	d48080e7          	jalr	-696(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047fe:	24c1                	addiw	s1,s1,16
    80004800:	04c92783          	lw	a5,76(s2)
    80004804:	04f4f763          	bgeu	s1,a5,80004852 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004808:	4741                	li	a4,16
    8000480a:	86a6                	mv	a3,s1
    8000480c:	fc040613          	addi	a2,s0,-64
    80004810:	4581                	li	a1,0
    80004812:	854a                	mv	a0,s2
    80004814:	00000097          	auipc	ra,0x0
    80004818:	d70080e7          	jalr	-656(ra) # 80004584 <readi>
    8000481c:	47c1                	li	a5,16
    8000481e:	fcf518e3          	bne	a0,a5,800047ee <dirlookup+0x3a>
    if(de.inum == 0)
    80004822:	fc045783          	lhu	a5,-64(s0)
    80004826:	dfe1                	beqz	a5,800047fe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004828:	fc240593          	addi	a1,s0,-62
    8000482c:	854e                	mv	a0,s3
    8000482e:	00000097          	auipc	ra,0x0
    80004832:	f6c080e7          	jalr	-148(ra) # 8000479a <namecmp>
    80004836:	f561                	bnez	a0,800047fe <dirlookup+0x4a>
      if(poff)
    80004838:	000a0463          	beqz	s4,80004840 <dirlookup+0x8c>
        *poff = off;
    8000483c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004840:	fc045583          	lhu	a1,-64(s0)
    80004844:	00092503          	lw	a0,0(s2)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	754080e7          	jalr	1876(ra) # 80003f9c <iget>
    80004850:	a011                	j	80004854 <dirlookup+0xa0>
  return 0;
    80004852:	4501                	li	a0,0
}
    80004854:	70e2                	ld	ra,56(sp)
    80004856:	7442                	ld	s0,48(sp)
    80004858:	74a2                	ld	s1,40(sp)
    8000485a:	7902                	ld	s2,32(sp)
    8000485c:	69e2                	ld	s3,24(sp)
    8000485e:	6a42                	ld	s4,16(sp)
    80004860:	6121                	addi	sp,sp,64
    80004862:	8082                	ret

0000000080004864 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004864:	711d                	addi	sp,sp,-96
    80004866:	ec86                	sd	ra,88(sp)
    80004868:	e8a2                	sd	s0,80(sp)
    8000486a:	e4a6                	sd	s1,72(sp)
    8000486c:	e0ca                	sd	s2,64(sp)
    8000486e:	fc4e                	sd	s3,56(sp)
    80004870:	f852                	sd	s4,48(sp)
    80004872:	f456                	sd	s5,40(sp)
    80004874:	f05a                	sd	s6,32(sp)
    80004876:	ec5e                	sd	s7,24(sp)
    80004878:	e862                	sd	s8,16(sp)
    8000487a:	e466                	sd	s9,8(sp)
    8000487c:	1080                	addi	s0,sp,96
    8000487e:	84aa                	mv	s1,a0
    80004880:	8b2e                	mv	s6,a1
    80004882:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004884:	00054703          	lbu	a4,0(a0)
    80004888:	02f00793          	li	a5,47
    8000488c:	02f70363          	beq	a4,a5,800048b2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004890:	ffffe097          	auipc	ra,0xffffe
    80004894:	a6c080e7          	jalr	-1428(ra) # 800022fc <myproc>
    80004898:	15853503          	ld	a0,344(a0)
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	9f6080e7          	jalr	-1546(ra) # 80004292 <idup>
    800048a4:	89aa                	mv	s3,a0
  while(*path == '/')
    800048a6:	02f00913          	li	s2,47
  len = path - s;
    800048aa:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800048ac:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800048ae:	4c05                	li	s8,1
    800048b0:	a865                	j	80004968 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800048b2:	4585                	li	a1,1
    800048b4:	4505                	li	a0,1
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	6e6080e7          	jalr	1766(ra) # 80003f9c <iget>
    800048be:	89aa                	mv	s3,a0
    800048c0:	b7dd                	j	800048a6 <namex+0x42>
      iunlockput(ip);
    800048c2:	854e                	mv	a0,s3
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	c6e080e7          	jalr	-914(ra) # 80004532 <iunlockput>
      return 0;
    800048cc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800048ce:	854e                	mv	a0,s3
    800048d0:	60e6                	ld	ra,88(sp)
    800048d2:	6446                	ld	s0,80(sp)
    800048d4:	64a6                	ld	s1,72(sp)
    800048d6:	6906                	ld	s2,64(sp)
    800048d8:	79e2                	ld	s3,56(sp)
    800048da:	7a42                	ld	s4,48(sp)
    800048dc:	7aa2                	ld	s5,40(sp)
    800048de:	7b02                	ld	s6,32(sp)
    800048e0:	6be2                	ld	s7,24(sp)
    800048e2:	6c42                	ld	s8,16(sp)
    800048e4:	6ca2                	ld	s9,8(sp)
    800048e6:	6125                	addi	sp,sp,96
    800048e8:	8082                	ret
      iunlock(ip);
    800048ea:	854e                	mv	a0,s3
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	aa6080e7          	jalr	-1370(ra) # 80004392 <iunlock>
      return ip;
    800048f4:	bfe9                	j	800048ce <namex+0x6a>
      iunlockput(ip);
    800048f6:	854e                	mv	a0,s3
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	c3a080e7          	jalr	-966(ra) # 80004532 <iunlockput>
      return 0;
    80004900:	89d2                	mv	s3,s4
    80004902:	b7f1                	j	800048ce <namex+0x6a>
  len = path - s;
    80004904:	40b48633          	sub	a2,s1,a1
    80004908:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000490c:	094cd463          	bge	s9,s4,80004994 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004910:	4639                	li	a2,14
    80004912:	8556                	mv	a0,s5
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	450080e7          	jalr	1104(ra) # 80000d64 <memmove>
  while(*path == '/')
    8000491c:	0004c783          	lbu	a5,0(s1)
    80004920:	01279763          	bne	a5,s2,8000492e <namex+0xca>
    path++;
    80004924:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004926:	0004c783          	lbu	a5,0(s1)
    8000492a:	ff278de3          	beq	a5,s2,80004924 <namex+0xc0>
    ilock(ip);
    8000492e:	854e                	mv	a0,s3
    80004930:	00000097          	auipc	ra,0x0
    80004934:	9a0080e7          	jalr	-1632(ra) # 800042d0 <ilock>
    if(ip->type != T_DIR){
    80004938:	04499783          	lh	a5,68(s3)
    8000493c:	f98793e3          	bne	a5,s8,800048c2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004940:	000b0563          	beqz	s6,8000494a <namex+0xe6>
    80004944:	0004c783          	lbu	a5,0(s1)
    80004948:	d3cd                	beqz	a5,800048ea <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000494a:	865e                	mv	a2,s7
    8000494c:	85d6                	mv	a1,s5
    8000494e:	854e                	mv	a0,s3
    80004950:	00000097          	auipc	ra,0x0
    80004954:	e64080e7          	jalr	-412(ra) # 800047b4 <dirlookup>
    80004958:	8a2a                	mv	s4,a0
    8000495a:	dd51                	beqz	a0,800048f6 <namex+0x92>
    iunlockput(ip);
    8000495c:	854e                	mv	a0,s3
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	bd4080e7          	jalr	-1068(ra) # 80004532 <iunlockput>
    ip = next;
    80004966:	89d2                	mv	s3,s4
  while(*path == '/')
    80004968:	0004c783          	lbu	a5,0(s1)
    8000496c:	05279763          	bne	a5,s2,800049ba <namex+0x156>
    path++;
    80004970:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004972:	0004c783          	lbu	a5,0(s1)
    80004976:	ff278de3          	beq	a5,s2,80004970 <namex+0x10c>
  if(*path == 0)
    8000497a:	c79d                	beqz	a5,800049a8 <namex+0x144>
    path++;
    8000497c:	85a6                	mv	a1,s1
  len = path - s;
    8000497e:	8a5e                	mv	s4,s7
    80004980:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004982:	01278963          	beq	a5,s2,80004994 <namex+0x130>
    80004986:	dfbd                	beqz	a5,80004904 <namex+0xa0>
    path++;
    80004988:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000498a:	0004c783          	lbu	a5,0(s1)
    8000498e:	ff279ce3          	bne	a5,s2,80004986 <namex+0x122>
    80004992:	bf8d                	j	80004904 <namex+0xa0>
    memmove(name, s, len);
    80004994:	2601                	sext.w	a2,a2
    80004996:	8556                	mv	a0,s5
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	3cc080e7          	jalr	972(ra) # 80000d64 <memmove>
    name[len] = 0;
    800049a0:	9a56                	add	s4,s4,s5
    800049a2:	000a0023          	sb	zero,0(s4)
    800049a6:	bf9d                	j	8000491c <namex+0xb8>
  if(nameiparent){
    800049a8:	f20b03e3          	beqz	s6,800048ce <namex+0x6a>
    iput(ip);
    800049ac:	854e                	mv	a0,s3
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	adc080e7          	jalr	-1316(ra) # 8000448a <iput>
    return 0;
    800049b6:	4981                	li	s3,0
    800049b8:	bf19                	j	800048ce <namex+0x6a>
  if(*path == 0)
    800049ba:	d7fd                	beqz	a5,800049a8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800049bc:	0004c783          	lbu	a5,0(s1)
    800049c0:	85a6                	mv	a1,s1
    800049c2:	b7d1                	j	80004986 <namex+0x122>

00000000800049c4 <dirlink>:
{
    800049c4:	7139                	addi	sp,sp,-64
    800049c6:	fc06                	sd	ra,56(sp)
    800049c8:	f822                	sd	s0,48(sp)
    800049ca:	f426                	sd	s1,40(sp)
    800049cc:	f04a                	sd	s2,32(sp)
    800049ce:	ec4e                	sd	s3,24(sp)
    800049d0:	e852                	sd	s4,16(sp)
    800049d2:	0080                	addi	s0,sp,64
    800049d4:	892a                	mv	s2,a0
    800049d6:	8a2e                	mv	s4,a1
    800049d8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800049da:	4601                	li	a2,0
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	dd8080e7          	jalr	-552(ra) # 800047b4 <dirlookup>
    800049e4:	e93d                	bnez	a0,80004a5a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049e6:	04c92483          	lw	s1,76(s2)
    800049ea:	c49d                	beqz	s1,80004a18 <dirlink+0x54>
    800049ec:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049ee:	4741                	li	a4,16
    800049f0:	86a6                	mv	a3,s1
    800049f2:	fc040613          	addi	a2,s0,-64
    800049f6:	4581                	li	a1,0
    800049f8:	854a                	mv	a0,s2
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	b8a080e7          	jalr	-1142(ra) # 80004584 <readi>
    80004a02:	47c1                	li	a5,16
    80004a04:	06f51163          	bne	a0,a5,80004a66 <dirlink+0xa2>
    if(de.inum == 0)
    80004a08:	fc045783          	lhu	a5,-64(s0)
    80004a0c:	c791                	beqz	a5,80004a18 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a0e:	24c1                	addiw	s1,s1,16
    80004a10:	04c92783          	lw	a5,76(s2)
    80004a14:	fcf4ede3          	bltu	s1,a5,800049ee <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a18:	4639                	li	a2,14
    80004a1a:	85d2                	mv	a1,s4
    80004a1c:	fc240513          	addi	a0,s0,-62
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	3f8080e7          	jalr	1016(ra) # 80000e18 <strncpy>
  de.inum = inum;
    80004a28:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a2c:	4741                	li	a4,16
    80004a2e:	86a6                	mv	a3,s1
    80004a30:	fc040613          	addi	a2,s0,-64
    80004a34:	4581                	li	a1,0
    80004a36:	854a                	mv	a0,s2
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	c44080e7          	jalr	-956(ra) # 8000467c <writei>
    80004a40:	872a                	mv	a4,a0
    80004a42:	47c1                	li	a5,16
  return 0;
    80004a44:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a46:	02f71863          	bne	a4,a5,80004a76 <dirlink+0xb2>
}
    80004a4a:	70e2                	ld	ra,56(sp)
    80004a4c:	7442                	ld	s0,48(sp)
    80004a4e:	74a2                	ld	s1,40(sp)
    80004a50:	7902                	ld	s2,32(sp)
    80004a52:	69e2                	ld	s3,24(sp)
    80004a54:	6a42                	ld	s4,16(sp)
    80004a56:	6121                	addi	sp,sp,64
    80004a58:	8082                	ret
    iput(ip);
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	a30080e7          	jalr	-1488(ra) # 8000448a <iput>
    return -1;
    80004a62:	557d                	li	a0,-1
    80004a64:	b7dd                	j	80004a4a <dirlink+0x86>
      panic("dirlink read");
    80004a66:	00004517          	auipc	a0,0x4
    80004a6a:	0aa50513          	addi	a0,a0,170 # 80008b10 <syscalls+0x1c8>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
    panic("dirlink");
    80004a76:	00004517          	auipc	a0,0x4
    80004a7a:	1aa50513          	addi	a0,a0,426 # 80008c20 <syscalls+0x2d8>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>

0000000080004a86 <namei>:

struct inode*
namei(char *path)
{
    80004a86:	1101                	addi	sp,sp,-32
    80004a88:	ec06                	sd	ra,24(sp)
    80004a8a:	e822                	sd	s0,16(sp)
    80004a8c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a8e:	fe040613          	addi	a2,s0,-32
    80004a92:	4581                	li	a1,0
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	dd0080e7          	jalr	-560(ra) # 80004864 <namex>
}
    80004a9c:	60e2                	ld	ra,24(sp)
    80004a9e:	6442                	ld	s0,16(sp)
    80004aa0:	6105                	addi	sp,sp,32
    80004aa2:	8082                	ret

0000000080004aa4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004aa4:	1141                	addi	sp,sp,-16
    80004aa6:	e406                	sd	ra,8(sp)
    80004aa8:	e022                	sd	s0,0(sp)
    80004aaa:	0800                	addi	s0,sp,16
    80004aac:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004aae:	4585                	li	a1,1
    80004ab0:	00000097          	auipc	ra,0x0
    80004ab4:	db4080e7          	jalr	-588(ra) # 80004864 <namex>
}
    80004ab8:	60a2                	ld	ra,8(sp)
    80004aba:	6402                	ld	s0,0(sp)
    80004abc:	0141                	addi	sp,sp,16
    80004abe:	8082                	ret

0000000080004ac0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004ac0:	1101                	addi	sp,sp,-32
    80004ac2:	ec06                	sd	ra,24(sp)
    80004ac4:	e822                	sd	s0,16(sp)
    80004ac6:	e426                	sd	s1,8(sp)
    80004ac8:	e04a                	sd	s2,0(sp)
    80004aca:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004acc:	0001d917          	auipc	s2,0x1d
    80004ad0:	acc90913          	addi	s2,s2,-1332 # 80021598 <log>
    80004ad4:	01892583          	lw	a1,24(s2)
    80004ad8:	02892503          	lw	a0,40(s2)
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	ff2080e7          	jalr	-14(ra) # 80003ace <bread>
    80004ae4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004ae6:	02c92683          	lw	a3,44(s2)
    80004aea:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004aec:	02d05763          	blez	a3,80004b1a <write_head+0x5a>
    80004af0:	0001d797          	auipc	a5,0x1d
    80004af4:	ad878793          	addi	a5,a5,-1320 # 800215c8 <log+0x30>
    80004af8:	05c50713          	addi	a4,a0,92
    80004afc:	36fd                	addiw	a3,a3,-1
    80004afe:	1682                	slli	a3,a3,0x20
    80004b00:	9281                	srli	a3,a3,0x20
    80004b02:	068a                	slli	a3,a3,0x2
    80004b04:	0001d617          	auipc	a2,0x1d
    80004b08:	ac860613          	addi	a2,a2,-1336 # 800215cc <log+0x34>
    80004b0c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b0e:	4390                	lw	a2,0(a5)
    80004b10:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b12:	0791                	addi	a5,a5,4
    80004b14:	0711                	addi	a4,a4,4
    80004b16:	fed79ce3          	bne	a5,a3,80004b0e <write_head+0x4e>
  }
  bwrite(buf);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	0a4080e7          	jalr	164(ra) # 80003bc0 <bwrite>
  brelse(buf);
    80004b24:	8526                	mv	a0,s1
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	0d8080e7          	jalr	216(ra) # 80003bfe <brelse>
}
    80004b2e:	60e2                	ld	ra,24(sp)
    80004b30:	6442                	ld	s0,16(sp)
    80004b32:	64a2                	ld	s1,8(sp)
    80004b34:	6902                	ld	s2,0(sp)
    80004b36:	6105                	addi	sp,sp,32
    80004b38:	8082                	ret

0000000080004b3a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b3a:	0001d797          	auipc	a5,0x1d
    80004b3e:	a8a7a783          	lw	a5,-1398(a5) # 800215c4 <log+0x2c>
    80004b42:	0af05d63          	blez	a5,80004bfc <install_trans+0xc2>
{
    80004b46:	7139                	addi	sp,sp,-64
    80004b48:	fc06                	sd	ra,56(sp)
    80004b4a:	f822                	sd	s0,48(sp)
    80004b4c:	f426                	sd	s1,40(sp)
    80004b4e:	f04a                	sd	s2,32(sp)
    80004b50:	ec4e                	sd	s3,24(sp)
    80004b52:	e852                	sd	s4,16(sp)
    80004b54:	e456                	sd	s5,8(sp)
    80004b56:	e05a                	sd	s6,0(sp)
    80004b58:	0080                	addi	s0,sp,64
    80004b5a:	8b2a                	mv	s6,a0
    80004b5c:	0001da97          	auipc	s5,0x1d
    80004b60:	a6ca8a93          	addi	s5,s5,-1428 # 800215c8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b64:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b66:	0001d997          	auipc	s3,0x1d
    80004b6a:	a3298993          	addi	s3,s3,-1486 # 80021598 <log>
    80004b6e:	a035                	j	80004b9a <install_trans+0x60>
      bunpin(dbuf);
    80004b70:	8526                	mv	a0,s1
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	166080e7          	jalr	358(ra) # 80003cd8 <bunpin>
    brelse(lbuf);
    80004b7a:	854a                	mv	a0,s2
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	082080e7          	jalr	130(ra) # 80003bfe <brelse>
    brelse(dbuf);
    80004b84:	8526                	mv	a0,s1
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	078080e7          	jalr	120(ra) # 80003bfe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b8e:	2a05                	addiw	s4,s4,1
    80004b90:	0a91                	addi	s5,s5,4
    80004b92:	02c9a783          	lw	a5,44(s3)
    80004b96:	04fa5963          	bge	s4,a5,80004be8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b9a:	0189a583          	lw	a1,24(s3)
    80004b9e:	014585bb          	addw	a1,a1,s4
    80004ba2:	2585                	addiw	a1,a1,1
    80004ba4:	0289a503          	lw	a0,40(s3)
    80004ba8:	fffff097          	auipc	ra,0xfffff
    80004bac:	f26080e7          	jalr	-218(ra) # 80003ace <bread>
    80004bb0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004bb2:	000aa583          	lw	a1,0(s5)
    80004bb6:	0289a503          	lw	a0,40(s3)
    80004bba:	fffff097          	auipc	ra,0xfffff
    80004bbe:	f14080e7          	jalr	-236(ra) # 80003ace <bread>
    80004bc2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004bc4:	40000613          	li	a2,1024
    80004bc8:	05890593          	addi	a1,s2,88
    80004bcc:	05850513          	addi	a0,a0,88
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	194080e7          	jalr	404(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bd8:	8526                	mv	a0,s1
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	fe6080e7          	jalr	-26(ra) # 80003bc0 <bwrite>
    if(recovering == 0)
    80004be2:	f80b1ce3          	bnez	s6,80004b7a <install_trans+0x40>
    80004be6:	b769                	j	80004b70 <install_trans+0x36>
}
    80004be8:	70e2                	ld	ra,56(sp)
    80004bea:	7442                	ld	s0,48(sp)
    80004bec:	74a2                	ld	s1,40(sp)
    80004bee:	7902                	ld	s2,32(sp)
    80004bf0:	69e2                	ld	s3,24(sp)
    80004bf2:	6a42                	ld	s4,16(sp)
    80004bf4:	6aa2                	ld	s5,8(sp)
    80004bf6:	6b02                	ld	s6,0(sp)
    80004bf8:	6121                	addi	sp,sp,64
    80004bfa:	8082                	ret
    80004bfc:	8082                	ret

0000000080004bfe <initlog>:
{
    80004bfe:	7179                	addi	sp,sp,-48
    80004c00:	f406                	sd	ra,40(sp)
    80004c02:	f022                	sd	s0,32(sp)
    80004c04:	ec26                	sd	s1,24(sp)
    80004c06:	e84a                	sd	s2,16(sp)
    80004c08:	e44e                	sd	s3,8(sp)
    80004c0a:	1800                	addi	s0,sp,48
    80004c0c:	892a                	mv	s2,a0
    80004c0e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c10:	0001d497          	auipc	s1,0x1d
    80004c14:	98848493          	addi	s1,s1,-1656 # 80021598 <log>
    80004c18:	00004597          	auipc	a1,0x4
    80004c1c:	f0858593          	addi	a1,a1,-248 # 80008b20 <syscalls+0x1d8>
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	f32080e7          	jalr	-206(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004c2a:	0149a583          	lw	a1,20(s3)
    80004c2e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c30:	0109a783          	lw	a5,16(s3)
    80004c34:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c36:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c3a:	854a                	mv	a0,s2
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	e92080e7          	jalr	-366(ra) # 80003ace <bread>
  log.lh.n = lh->n;
    80004c44:	4d3c                	lw	a5,88(a0)
    80004c46:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c48:	02f05563          	blez	a5,80004c72 <initlog+0x74>
    80004c4c:	05c50713          	addi	a4,a0,92
    80004c50:	0001d697          	auipc	a3,0x1d
    80004c54:	97868693          	addi	a3,a3,-1672 # 800215c8 <log+0x30>
    80004c58:	37fd                	addiw	a5,a5,-1
    80004c5a:	1782                	slli	a5,a5,0x20
    80004c5c:	9381                	srli	a5,a5,0x20
    80004c5e:	078a                	slli	a5,a5,0x2
    80004c60:	06050613          	addi	a2,a0,96
    80004c64:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c66:	4310                	lw	a2,0(a4)
    80004c68:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004c6a:	0711                	addi	a4,a4,4
    80004c6c:	0691                	addi	a3,a3,4
    80004c6e:	fef71ce3          	bne	a4,a5,80004c66 <initlog+0x68>
  brelse(buf);
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	f8c080e7          	jalr	-116(ra) # 80003bfe <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c7a:	4505                	li	a0,1
    80004c7c:	00000097          	auipc	ra,0x0
    80004c80:	ebe080e7          	jalr	-322(ra) # 80004b3a <install_trans>
  log.lh.n = 0;
    80004c84:	0001d797          	auipc	a5,0x1d
    80004c88:	9407a023          	sw	zero,-1728(a5) # 800215c4 <log+0x2c>
  write_head(); // clear the log
    80004c8c:	00000097          	auipc	ra,0x0
    80004c90:	e34080e7          	jalr	-460(ra) # 80004ac0 <write_head>
}
    80004c94:	70a2                	ld	ra,40(sp)
    80004c96:	7402                	ld	s0,32(sp)
    80004c98:	64e2                	ld	s1,24(sp)
    80004c9a:	6942                	ld	s2,16(sp)
    80004c9c:	69a2                	ld	s3,8(sp)
    80004c9e:	6145                	addi	sp,sp,48
    80004ca0:	8082                	ret

0000000080004ca2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004ca2:	1101                	addi	sp,sp,-32
    80004ca4:	ec06                	sd	ra,24(sp)
    80004ca6:	e822                	sd	s0,16(sp)
    80004ca8:	e426                	sd	s1,8(sp)
    80004caa:	e04a                	sd	s2,0(sp)
    80004cac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004cae:	0001d517          	auipc	a0,0x1d
    80004cb2:	8ea50513          	addi	a0,a0,-1814 # 80021598 <log>
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	f2e080e7          	jalr	-210(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004cbe:	0001d497          	auipc	s1,0x1d
    80004cc2:	8da48493          	addi	s1,s1,-1830 # 80021598 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cc6:	4979                	li	s2,30
    80004cc8:	a039                	j	80004cd6 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004cca:	85a6                	mv	a1,s1
    80004ccc:	8526                	mv	a0,s1
    80004cce:	ffffe097          	auipc	ra,0xffffe
    80004cd2:	f8e080e7          	jalr	-114(ra) # 80002c5c <sleep>
    if(log.committing){
    80004cd6:	50dc                	lw	a5,36(s1)
    80004cd8:	fbed                	bnez	a5,80004cca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cda:	509c                	lw	a5,32(s1)
    80004cdc:	0017871b          	addiw	a4,a5,1
    80004ce0:	0007069b          	sext.w	a3,a4
    80004ce4:	0027179b          	slliw	a5,a4,0x2
    80004ce8:	9fb9                	addw	a5,a5,a4
    80004cea:	0017979b          	slliw	a5,a5,0x1
    80004cee:	54d8                	lw	a4,44(s1)
    80004cf0:	9fb9                	addw	a5,a5,a4
    80004cf2:	00f95963          	bge	s2,a5,80004d04 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004cf6:	85a6                	mv	a1,s1
    80004cf8:	8526                	mv	a0,s1
    80004cfa:	ffffe097          	auipc	ra,0xffffe
    80004cfe:	f62080e7          	jalr	-158(ra) # 80002c5c <sleep>
    80004d02:	bfd1                	j	80004cd6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d04:	0001d517          	auipc	a0,0x1d
    80004d08:	89450513          	addi	a0,a0,-1900 # 80021598 <log>
    80004d0c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	f9c080e7          	jalr	-100(ra) # 80000caa <release>
      break;
    }
  }
}
    80004d16:	60e2                	ld	ra,24(sp)
    80004d18:	6442                	ld	s0,16(sp)
    80004d1a:	64a2                	ld	s1,8(sp)
    80004d1c:	6902                	ld	s2,0(sp)
    80004d1e:	6105                	addi	sp,sp,32
    80004d20:	8082                	ret

0000000080004d22 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d22:	7139                	addi	sp,sp,-64
    80004d24:	fc06                	sd	ra,56(sp)
    80004d26:	f822                	sd	s0,48(sp)
    80004d28:	f426                	sd	s1,40(sp)
    80004d2a:	f04a                	sd	s2,32(sp)
    80004d2c:	ec4e                	sd	s3,24(sp)
    80004d2e:	e852                	sd	s4,16(sp)
    80004d30:	e456                	sd	s5,8(sp)
    80004d32:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d34:	0001d497          	auipc	s1,0x1d
    80004d38:	86448493          	addi	s1,s1,-1948 # 80021598 <log>
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	ea6080e7          	jalr	-346(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004d46:	509c                	lw	a5,32(s1)
    80004d48:	37fd                	addiw	a5,a5,-1
    80004d4a:	0007891b          	sext.w	s2,a5
    80004d4e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d50:	50dc                	lw	a5,36(s1)
    80004d52:	efb9                	bnez	a5,80004db0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d54:	06091663          	bnez	s2,80004dc0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004d58:	0001d497          	auipc	s1,0x1d
    80004d5c:	84048493          	addi	s1,s1,-1984 # 80021598 <log>
    80004d60:	4785                	li	a5,1
    80004d62:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d64:	8526                	mv	a0,s1
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	f44080e7          	jalr	-188(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d6e:	54dc                	lw	a5,44(s1)
    80004d70:	06f04763          	bgtz	a5,80004dde <end_op+0xbc>
    acquire(&log.lock);
    80004d74:	0001d497          	auipc	s1,0x1d
    80004d78:	82448493          	addi	s1,s1,-2012 # 80021598 <log>
    80004d7c:	8526                	mv	a0,s1
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	e66080e7          	jalr	-410(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004d86:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	ffffe097          	auipc	ra,0xffffe
    80004d90:	07c080e7          	jalr	124(ra) # 80002e08 <wakeup>
    release(&log.lock);
    80004d94:	8526                	mv	a0,s1
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	f14080e7          	jalr	-236(ra) # 80000caa <release>
}
    80004d9e:	70e2                	ld	ra,56(sp)
    80004da0:	7442                	ld	s0,48(sp)
    80004da2:	74a2                	ld	s1,40(sp)
    80004da4:	7902                	ld	s2,32(sp)
    80004da6:	69e2                	ld	s3,24(sp)
    80004da8:	6a42                	ld	s4,16(sp)
    80004daa:	6aa2                	ld	s5,8(sp)
    80004dac:	6121                	addi	sp,sp,64
    80004dae:	8082                	ret
    panic("log.committing");
    80004db0:	00004517          	auipc	a0,0x4
    80004db4:	d7850513          	addi	a0,a0,-648 # 80008b28 <syscalls+0x1e0>
    80004db8:	ffffb097          	auipc	ra,0xffffb
    80004dbc:	786080e7          	jalr	1926(ra) # 8000053e <panic>
    wakeup(&log);
    80004dc0:	0001c497          	auipc	s1,0x1c
    80004dc4:	7d848493          	addi	s1,s1,2008 # 80021598 <log>
    80004dc8:	8526                	mv	a0,s1
    80004dca:	ffffe097          	auipc	ra,0xffffe
    80004dce:	03e080e7          	jalr	62(ra) # 80002e08 <wakeup>
  release(&log.lock);
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	ed6080e7          	jalr	-298(ra) # 80000caa <release>
  if(do_commit){
    80004ddc:	b7c9                	j	80004d9e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dde:	0001ca97          	auipc	s5,0x1c
    80004de2:	7eaa8a93          	addi	s5,s5,2026 # 800215c8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004de6:	0001ca17          	auipc	s4,0x1c
    80004dea:	7b2a0a13          	addi	s4,s4,1970 # 80021598 <log>
    80004dee:	018a2583          	lw	a1,24(s4)
    80004df2:	012585bb          	addw	a1,a1,s2
    80004df6:	2585                	addiw	a1,a1,1
    80004df8:	028a2503          	lw	a0,40(s4)
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	cd2080e7          	jalr	-814(ra) # 80003ace <bread>
    80004e04:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e06:	000aa583          	lw	a1,0(s5)
    80004e0a:	028a2503          	lw	a0,40(s4)
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	cc0080e7          	jalr	-832(ra) # 80003ace <bread>
    80004e16:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e18:	40000613          	li	a2,1024
    80004e1c:	05850593          	addi	a1,a0,88
    80004e20:	05848513          	addi	a0,s1,88
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	f40080e7          	jalr	-192(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	d92080e7          	jalr	-622(ra) # 80003bc0 <bwrite>
    brelse(from);
    80004e36:	854e                	mv	a0,s3
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	dc6080e7          	jalr	-570(ra) # 80003bfe <brelse>
    brelse(to);
    80004e40:	8526                	mv	a0,s1
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	dbc080e7          	jalr	-580(ra) # 80003bfe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e4a:	2905                	addiw	s2,s2,1
    80004e4c:	0a91                	addi	s5,s5,4
    80004e4e:	02ca2783          	lw	a5,44(s4)
    80004e52:	f8f94ee3          	blt	s2,a5,80004dee <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e56:	00000097          	auipc	ra,0x0
    80004e5a:	c6a080e7          	jalr	-918(ra) # 80004ac0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e5e:	4501                	li	a0,0
    80004e60:	00000097          	auipc	ra,0x0
    80004e64:	cda080e7          	jalr	-806(ra) # 80004b3a <install_trans>
    log.lh.n = 0;
    80004e68:	0001c797          	auipc	a5,0x1c
    80004e6c:	7407ae23          	sw	zero,1884(a5) # 800215c4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	c50080e7          	jalr	-944(ra) # 80004ac0 <write_head>
    80004e78:	bdf5                	j	80004d74 <end_op+0x52>

0000000080004e7a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e7a:	1101                	addi	sp,sp,-32
    80004e7c:	ec06                	sd	ra,24(sp)
    80004e7e:	e822                	sd	s0,16(sp)
    80004e80:	e426                	sd	s1,8(sp)
    80004e82:	e04a                	sd	s2,0(sp)
    80004e84:	1000                	addi	s0,sp,32
    80004e86:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e88:	0001c917          	auipc	s2,0x1c
    80004e8c:	71090913          	addi	s2,s2,1808 # 80021598 <log>
    80004e90:	854a                	mv	a0,s2
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	d52080e7          	jalr	-686(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e9a:	02c92603          	lw	a2,44(s2)
    80004e9e:	47f5                	li	a5,29
    80004ea0:	06c7c563          	blt	a5,a2,80004f0a <log_write+0x90>
    80004ea4:	0001c797          	auipc	a5,0x1c
    80004ea8:	7107a783          	lw	a5,1808(a5) # 800215b4 <log+0x1c>
    80004eac:	37fd                	addiw	a5,a5,-1
    80004eae:	04f65e63          	bge	a2,a5,80004f0a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004eb2:	0001c797          	auipc	a5,0x1c
    80004eb6:	7067a783          	lw	a5,1798(a5) # 800215b8 <log+0x20>
    80004eba:	06f05063          	blez	a5,80004f1a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ebe:	4781                	li	a5,0
    80004ec0:	06c05563          	blez	a2,80004f2a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ec4:	44cc                	lw	a1,12(s1)
    80004ec6:	0001c717          	auipc	a4,0x1c
    80004eca:	70270713          	addi	a4,a4,1794 # 800215c8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ece:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ed0:	4314                	lw	a3,0(a4)
    80004ed2:	04b68c63          	beq	a3,a1,80004f2a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ed6:	2785                	addiw	a5,a5,1
    80004ed8:	0711                	addi	a4,a4,4
    80004eda:	fef61be3          	bne	a2,a5,80004ed0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ede:	0621                	addi	a2,a2,8
    80004ee0:	060a                	slli	a2,a2,0x2
    80004ee2:	0001c797          	auipc	a5,0x1c
    80004ee6:	6b678793          	addi	a5,a5,1718 # 80021598 <log>
    80004eea:	963e                	add	a2,a2,a5
    80004eec:	44dc                	lw	a5,12(s1)
    80004eee:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ef0:	8526                	mv	a0,s1
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	daa080e7          	jalr	-598(ra) # 80003c9c <bpin>
    log.lh.n++;
    80004efa:	0001c717          	auipc	a4,0x1c
    80004efe:	69e70713          	addi	a4,a4,1694 # 80021598 <log>
    80004f02:	575c                	lw	a5,44(a4)
    80004f04:	2785                	addiw	a5,a5,1
    80004f06:	d75c                	sw	a5,44(a4)
    80004f08:	a835                	j	80004f44 <log_write+0xca>
    panic("too big a transaction");
    80004f0a:	00004517          	auipc	a0,0x4
    80004f0e:	c2e50513          	addi	a0,a0,-978 # 80008b38 <syscalls+0x1f0>
    80004f12:	ffffb097          	auipc	ra,0xffffb
    80004f16:	62c080e7          	jalr	1580(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004f1a:	00004517          	auipc	a0,0x4
    80004f1e:	c3650513          	addi	a0,a0,-970 # 80008b50 <syscalls+0x208>
    80004f22:	ffffb097          	auipc	ra,0xffffb
    80004f26:	61c080e7          	jalr	1564(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004f2a:	00878713          	addi	a4,a5,8
    80004f2e:	00271693          	slli	a3,a4,0x2
    80004f32:	0001c717          	auipc	a4,0x1c
    80004f36:	66670713          	addi	a4,a4,1638 # 80021598 <log>
    80004f3a:	9736                	add	a4,a4,a3
    80004f3c:	44d4                	lw	a3,12(s1)
    80004f3e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f40:	faf608e3          	beq	a2,a5,80004ef0 <log_write+0x76>
  }
  release(&log.lock);
    80004f44:	0001c517          	auipc	a0,0x1c
    80004f48:	65450513          	addi	a0,a0,1620 # 80021598 <log>
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	d5e080e7          	jalr	-674(ra) # 80000caa <release>
}
    80004f54:	60e2                	ld	ra,24(sp)
    80004f56:	6442                	ld	s0,16(sp)
    80004f58:	64a2                	ld	s1,8(sp)
    80004f5a:	6902                	ld	s2,0(sp)
    80004f5c:	6105                	addi	sp,sp,32
    80004f5e:	8082                	ret

0000000080004f60 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f60:	1101                	addi	sp,sp,-32
    80004f62:	ec06                	sd	ra,24(sp)
    80004f64:	e822                	sd	s0,16(sp)
    80004f66:	e426                	sd	s1,8(sp)
    80004f68:	e04a                	sd	s2,0(sp)
    80004f6a:	1000                	addi	s0,sp,32
    80004f6c:	84aa                	mv	s1,a0
    80004f6e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f70:	00004597          	auipc	a1,0x4
    80004f74:	c0058593          	addi	a1,a1,-1024 # 80008b70 <syscalls+0x228>
    80004f78:	0521                	addi	a0,a0,8
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	bda080e7          	jalr	-1062(ra) # 80000b54 <initlock>
  lk->name = name;
    80004f82:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f86:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f8a:	0204a423          	sw	zero,40(s1)
}
    80004f8e:	60e2                	ld	ra,24(sp)
    80004f90:	6442                	ld	s0,16(sp)
    80004f92:	64a2                	ld	s1,8(sp)
    80004f94:	6902                	ld	s2,0(sp)
    80004f96:	6105                	addi	sp,sp,32
    80004f98:	8082                	ret

0000000080004f9a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f9a:	1101                	addi	sp,sp,-32
    80004f9c:	ec06                	sd	ra,24(sp)
    80004f9e:	e822                	sd	s0,16(sp)
    80004fa0:	e426                	sd	s1,8(sp)
    80004fa2:	e04a                	sd	s2,0(sp)
    80004fa4:	1000                	addi	s0,sp,32
    80004fa6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fa8:	00850913          	addi	s2,a0,8
    80004fac:	854a                	mv	a0,s2
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	c36080e7          	jalr	-970(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004fb6:	409c                	lw	a5,0(s1)
    80004fb8:	cb89                	beqz	a5,80004fca <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004fba:	85ca                	mv	a1,s2
    80004fbc:	8526                	mv	a0,s1
    80004fbe:	ffffe097          	auipc	ra,0xffffe
    80004fc2:	c9e080e7          	jalr	-866(ra) # 80002c5c <sleep>
  while (lk->locked) {
    80004fc6:	409c                	lw	a5,0(s1)
    80004fc8:	fbed                	bnez	a5,80004fba <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fca:	4785                	li	a5,1
    80004fcc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	32e080e7          	jalr	814(ra) # 800022fc <myproc>
    80004fd6:	591c                	lw	a5,48(a0)
    80004fd8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fda:	854a                	mv	a0,s2
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	cce080e7          	jalr	-818(ra) # 80000caa <release>
}
    80004fe4:	60e2                	ld	ra,24(sp)
    80004fe6:	6442                	ld	s0,16(sp)
    80004fe8:	64a2                	ld	s1,8(sp)
    80004fea:	6902                	ld	s2,0(sp)
    80004fec:	6105                	addi	sp,sp,32
    80004fee:	8082                	ret

0000000080004ff0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ff0:	1101                	addi	sp,sp,-32
    80004ff2:	ec06                	sd	ra,24(sp)
    80004ff4:	e822                	sd	s0,16(sp)
    80004ff6:	e426                	sd	s1,8(sp)
    80004ff8:	e04a                	sd	s2,0(sp)
    80004ffa:	1000                	addi	s0,sp,32
    80004ffc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ffe:	00850913          	addi	s2,a0,8
    80005002:	854a                	mv	a0,s2
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	be0080e7          	jalr	-1056(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000500c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005010:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005014:	8526                	mv	a0,s1
    80005016:	ffffe097          	auipc	ra,0xffffe
    8000501a:	df2080e7          	jalr	-526(ra) # 80002e08 <wakeup>
  release(&lk->lk);
    8000501e:	854a                	mv	a0,s2
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	c8a080e7          	jalr	-886(ra) # 80000caa <release>
}
    80005028:	60e2                	ld	ra,24(sp)
    8000502a:	6442                	ld	s0,16(sp)
    8000502c:	64a2                	ld	s1,8(sp)
    8000502e:	6902                	ld	s2,0(sp)
    80005030:	6105                	addi	sp,sp,32
    80005032:	8082                	ret

0000000080005034 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005034:	7179                	addi	sp,sp,-48
    80005036:	f406                	sd	ra,40(sp)
    80005038:	f022                	sd	s0,32(sp)
    8000503a:	ec26                	sd	s1,24(sp)
    8000503c:	e84a                	sd	s2,16(sp)
    8000503e:	e44e                	sd	s3,8(sp)
    80005040:	1800                	addi	s0,sp,48
    80005042:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005044:	00850913          	addi	s2,a0,8
    80005048:	854a                	mv	a0,s2
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	b9a080e7          	jalr	-1126(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005052:	409c                	lw	a5,0(s1)
    80005054:	ef99                	bnez	a5,80005072 <holdingsleep+0x3e>
    80005056:	4481                	li	s1,0
  release(&lk->lk);
    80005058:	854a                	mv	a0,s2
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	c50080e7          	jalr	-944(ra) # 80000caa <release>
  return r;
}
    80005062:	8526                	mv	a0,s1
    80005064:	70a2                	ld	ra,40(sp)
    80005066:	7402                	ld	s0,32(sp)
    80005068:	64e2                	ld	s1,24(sp)
    8000506a:	6942                	ld	s2,16(sp)
    8000506c:	69a2                	ld	s3,8(sp)
    8000506e:	6145                	addi	sp,sp,48
    80005070:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005072:	0284a983          	lw	s3,40(s1)
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	286080e7          	jalr	646(ra) # 800022fc <myproc>
    8000507e:	5904                	lw	s1,48(a0)
    80005080:	413484b3          	sub	s1,s1,s3
    80005084:	0014b493          	seqz	s1,s1
    80005088:	bfc1                	j	80005058 <holdingsleep+0x24>

000000008000508a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000508a:	1141                	addi	sp,sp,-16
    8000508c:	e406                	sd	ra,8(sp)
    8000508e:	e022                	sd	s0,0(sp)
    80005090:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005092:	00004597          	auipc	a1,0x4
    80005096:	aee58593          	addi	a1,a1,-1298 # 80008b80 <syscalls+0x238>
    8000509a:	0001c517          	auipc	a0,0x1c
    8000509e:	64650513          	addi	a0,a0,1606 # 800216e0 <ftable>
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	ab2080e7          	jalr	-1358(ra) # 80000b54 <initlock>
}
    800050aa:	60a2                	ld	ra,8(sp)
    800050ac:	6402                	ld	s0,0(sp)
    800050ae:	0141                	addi	sp,sp,16
    800050b0:	8082                	ret

00000000800050b2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800050b2:	1101                	addi	sp,sp,-32
    800050b4:	ec06                	sd	ra,24(sp)
    800050b6:	e822                	sd	s0,16(sp)
    800050b8:	e426                	sd	s1,8(sp)
    800050ba:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050bc:	0001c517          	auipc	a0,0x1c
    800050c0:	62450513          	addi	a0,a0,1572 # 800216e0 <ftable>
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	b20080e7          	jalr	-1248(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050cc:	0001c497          	auipc	s1,0x1c
    800050d0:	62c48493          	addi	s1,s1,1580 # 800216f8 <ftable+0x18>
    800050d4:	0001d717          	auipc	a4,0x1d
    800050d8:	5c470713          	addi	a4,a4,1476 # 80022698 <ftable+0xfb8>
    if(f->ref == 0){
    800050dc:	40dc                	lw	a5,4(s1)
    800050de:	cf99                	beqz	a5,800050fc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050e0:	02848493          	addi	s1,s1,40
    800050e4:	fee49ce3          	bne	s1,a4,800050dc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050e8:	0001c517          	auipc	a0,0x1c
    800050ec:	5f850513          	addi	a0,a0,1528 # 800216e0 <ftable>
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	bba080e7          	jalr	-1094(ra) # 80000caa <release>
  return 0;
    800050f8:	4481                	li	s1,0
    800050fa:	a819                	j	80005110 <filealloc+0x5e>
      f->ref = 1;
    800050fc:	4785                	li	a5,1
    800050fe:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005100:	0001c517          	auipc	a0,0x1c
    80005104:	5e050513          	addi	a0,a0,1504 # 800216e0 <ftable>
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	ba2080e7          	jalr	-1118(ra) # 80000caa <release>
}
    80005110:	8526                	mv	a0,s1
    80005112:	60e2                	ld	ra,24(sp)
    80005114:	6442                	ld	s0,16(sp)
    80005116:	64a2                	ld	s1,8(sp)
    80005118:	6105                	addi	sp,sp,32
    8000511a:	8082                	ret

000000008000511c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000511c:	1101                	addi	sp,sp,-32
    8000511e:	ec06                	sd	ra,24(sp)
    80005120:	e822                	sd	s0,16(sp)
    80005122:	e426                	sd	s1,8(sp)
    80005124:	1000                	addi	s0,sp,32
    80005126:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005128:	0001c517          	auipc	a0,0x1c
    8000512c:	5b850513          	addi	a0,a0,1464 # 800216e0 <ftable>
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	ab4080e7          	jalr	-1356(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005138:	40dc                	lw	a5,4(s1)
    8000513a:	02f05263          	blez	a5,8000515e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000513e:	2785                	addiw	a5,a5,1
    80005140:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005142:	0001c517          	auipc	a0,0x1c
    80005146:	59e50513          	addi	a0,a0,1438 # 800216e0 <ftable>
    8000514a:	ffffc097          	auipc	ra,0xffffc
    8000514e:	b60080e7          	jalr	-1184(ra) # 80000caa <release>
  return f;
}
    80005152:	8526                	mv	a0,s1
    80005154:	60e2                	ld	ra,24(sp)
    80005156:	6442                	ld	s0,16(sp)
    80005158:	64a2                	ld	s1,8(sp)
    8000515a:	6105                	addi	sp,sp,32
    8000515c:	8082                	ret
    panic("filedup");
    8000515e:	00004517          	auipc	a0,0x4
    80005162:	a2a50513          	addi	a0,a0,-1494 # 80008b88 <syscalls+0x240>
    80005166:	ffffb097          	auipc	ra,0xffffb
    8000516a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000516e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000516e:	7139                	addi	sp,sp,-64
    80005170:	fc06                	sd	ra,56(sp)
    80005172:	f822                	sd	s0,48(sp)
    80005174:	f426                	sd	s1,40(sp)
    80005176:	f04a                	sd	s2,32(sp)
    80005178:	ec4e                	sd	s3,24(sp)
    8000517a:	e852                	sd	s4,16(sp)
    8000517c:	e456                	sd	s5,8(sp)
    8000517e:	0080                	addi	s0,sp,64
    80005180:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005182:	0001c517          	auipc	a0,0x1c
    80005186:	55e50513          	addi	a0,a0,1374 # 800216e0 <ftable>
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	a5a080e7          	jalr	-1446(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005192:	40dc                	lw	a5,4(s1)
    80005194:	06f05163          	blez	a5,800051f6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005198:	37fd                	addiw	a5,a5,-1
    8000519a:	0007871b          	sext.w	a4,a5
    8000519e:	c0dc                	sw	a5,4(s1)
    800051a0:	06e04363          	bgtz	a4,80005206 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800051a4:	0004a903          	lw	s2,0(s1)
    800051a8:	0094ca83          	lbu	s5,9(s1)
    800051ac:	0104ba03          	ld	s4,16(s1)
    800051b0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800051b4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800051b8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051bc:	0001c517          	auipc	a0,0x1c
    800051c0:	52450513          	addi	a0,a0,1316 # 800216e0 <ftable>
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	ae6080e7          	jalr	-1306(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    800051cc:	4785                	li	a5,1
    800051ce:	04f90d63          	beq	s2,a5,80005228 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051d2:	3979                	addiw	s2,s2,-2
    800051d4:	4785                	li	a5,1
    800051d6:	0527e063          	bltu	a5,s2,80005216 <fileclose+0xa8>
    begin_op();
    800051da:	00000097          	auipc	ra,0x0
    800051de:	ac8080e7          	jalr	-1336(ra) # 80004ca2 <begin_op>
    iput(ff.ip);
    800051e2:	854e                	mv	a0,s3
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	2a6080e7          	jalr	678(ra) # 8000448a <iput>
    end_op();
    800051ec:	00000097          	auipc	ra,0x0
    800051f0:	b36080e7          	jalr	-1226(ra) # 80004d22 <end_op>
    800051f4:	a00d                	j	80005216 <fileclose+0xa8>
    panic("fileclose");
    800051f6:	00004517          	auipc	a0,0x4
    800051fa:	99a50513          	addi	a0,a0,-1638 # 80008b90 <syscalls+0x248>
    800051fe:	ffffb097          	auipc	ra,0xffffb
    80005202:	340080e7          	jalr	832(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005206:	0001c517          	auipc	a0,0x1c
    8000520a:	4da50513          	addi	a0,a0,1242 # 800216e0 <ftable>
    8000520e:	ffffc097          	auipc	ra,0xffffc
    80005212:	a9c080e7          	jalr	-1380(ra) # 80000caa <release>
  }
}
    80005216:	70e2                	ld	ra,56(sp)
    80005218:	7442                	ld	s0,48(sp)
    8000521a:	74a2                	ld	s1,40(sp)
    8000521c:	7902                	ld	s2,32(sp)
    8000521e:	69e2                	ld	s3,24(sp)
    80005220:	6a42                	ld	s4,16(sp)
    80005222:	6aa2                	ld	s5,8(sp)
    80005224:	6121                	addi	sp,sp,64
    80005226:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005228:	85d6                	mv	a1,s5
    8000522a:	8552                	mv	a0,s4
    8000522c:	00000097          	auipc	ra,0x0
    80005230:	34c080e7          	jalr	844(ra) # 80005578 <pipeclose>
    80005234:	b7cd                	j	80005216 <fileclose+0xa8>

0000000080005236 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005236:	715d                	addi	sp,sp,-80
    80005238:	e486                	sd	ra,72(sp)
    8000523a:	e0a2                	sd	s0,64(sp)
    8000523c:	fc26                	sd	s1,56(sp)
    8000523e:	f84a                	sd	s2,48(sp)
    80005240:	f44e                	sd	s3,40(sp)
    80005242:	0880                	addi	s0,sp,80
    80005244:	84aa                	mv	s1,a0
    80005246:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	0b4080e7          	jalr	180(ra) # 800022fc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005250:	409c                	lw	a5,0(s1)
    80005252:	37f9                	addiw	a5,a5,-2
    80005254:	4705                	li	a4,1
    80005256:	04f76763          	bltu	a4,a5,800052a4 <filestat+0x6e>
    8000525a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000525c:	6c88                	ld	a0,24(s1)
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	072080e7          	jalr	114(ra) # 800042d0 <ilock>
    stati(f->ip, &st);
    80005266:	fb840593          	addi	a1,s0,-72
    8000526a:	6c88                	ld	a0,24(s1)
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	2ee080e7          	jalr	750(ra) # 8000455a <stati>
    iunlock(f->ip);
    80005274:	6c88                	ld	a0,24(s1)
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	11c080e7          	jalr	284(ra) # 80004392 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000527e:	46e1                	li	a3,24
    80005280:	fb840613          	addi	a2,s0,-72
    80005284:	85ce                	mv	a1,s3
    80005286:	05893503          	ld	a0,88(s2)
    8000528a:	ffffc097          	auipc	ra,0xffffc
    8000528e:	40c080e7          	jalr	1036(ra) # 80001696 <copyout>
    80005292:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005296:	60a6                	ld	ra,72(sp)
    80005298:	6406                	ld	s0,64(sp)
    8000529a:	74e2                	ld	s1,56(sp)
    8000529c:	7942                	ld	s2,48(sp)
    8000529e:	79a2                	ld	s3,40(sp)
    800052a0:	6161                	addi	sp,sp,80
    800052a2:	8082                	ret
  return -1;
    800052a4:	557d                	li	a0,-1
    800052a6:	bfc5                	j	80005296 <filestat+0x60>

00000000800052a8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800052a8:	7179                	addi	sp,sp,-48
    800052aa:	f406                	sd	ra,40(sp)
    800052ac:	f022                	sd	s0,32(sp)
    800052ae:	ec26                	sd	s1,24(sp)
    800052b0:	e84a                	sd	s2,16(sp)
    800052b2:	e44e                	sd	s3,8(sp)
    800052b4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800052b6:	00854783          	lbu	a5,8(a0)
    800052ba:	c3d5                	beqz	a5,8000535e <fileread+0xb6>
    800052bc:	84aa                	mv	s1,a0
    800052be:	89ae                	mv	s3,a1
    800052c0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052c2:	411c                	lw	a5,0(a0)
    800052c4:	4705                	li	a4,1
    800052c6:	04e78963          	beq	a5,a4,80005318 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052ca:	470d                	li	a4,3
    800052cc:	04e78d63          	beq	a5,a4,80005326 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052d0:	4709                	li	a4,2
    800052d2:	06e79e63          	bne	a5,a4,8000534e <fileread+0xa6>
    ilock(f->ip);
    800052d6:	6d08                	ld	a0,24(a0)
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	ff8080e7          	jalr	-8(ra) # 800042d0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052e0:	874a                	mv	a4,s2
    800052e2:	5094                	lw	a3,32(s1)
    800052e4:	864e                	mv	a2,s3
    800052e6:	4585                	li	a1,1
    800052e8:	6c88                	ld	a0,24(s1)
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	29a080e7          	jalr	666(ra) # 80004584 <readi>
    800052f2:	892a                	mv	s2,a0
    800052f4:	00a05563          	blez	a0,800052fe <fileread+0x56>
      f->off += r;
    800052f8:	509c                	lw	a5,32(s1)
    800052fa:	9fa9                	addw	a5,a5,a0
    800052fc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052fe:	6c88                	ld	a0,24(s1)
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	092080e7          	jalr	146(ra) # 80004392 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005308:	854a                	mv	a0,s2
    8000530a:	70a2                	ld	ra,40(sp)
    8000530c:	7402                	ld	s0,32(sp)
    8000530e:	64e2                	ld	s1,24(sp)
    80005310:	6942                	ld	s2,16(sp)
    80005312:	69a2                	ld	s3,8(sp)
    80005314:	6145                	addi	sp,sp,48
    80005316:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005318:	6908                	ld	a0,16(a0)
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	3c8080e7          	jalr	968(ra) # 800056e2 <piperead>
    80005322:	892a                	mv	s2,a0
    80005324:	b7d5                	j	80005308 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005326:	02451783          	lh	a5,36(a0)
    8000532a:	03079693          	slli	a3,a5,0x30
    8000532e:	92c1                	srli	a3,a3,0x30
    80005330:	4725                	li	a4,9
    80005332:	02d76863          	bltu	a4,a3,80005362 <fileread+0xba>
    80005336:	0792                	slli	a5,a5,0x4
    80005338:	0001c717          	auipc	a4,0x1c
    8000533c:	30870713          	addi	a4,a4,776 # 80021640 <devsw>
    80005340:	97ba                	add	a5,a5,a4
    80005342:	639c                	ld	a5,0(a5)
    80005344:	c38d                	beqz	a5,80005366 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005346:	4505                	li	a0,1
    80005348:	9782                	jalr	a5
    8000534a:	892a                	mv	s2,a0
    8000534c:	bf75                	j	80005308 <fileread+0x60>
    panic("fileread");
    8000534e:	00004517          	auipc	a0,0x4
    80005352:	85250513          	addi	a0,a0,-1966 # 80008ba0 <syscalls+0x258>
    80005356:	ffffb097          	auipc	ra,0xffffb
    8000535a:	1e8080e7          	jalr	488(ra) # 8000053e <panic>
    return -1;
    8000535e:	597d                	li	s2,-1
    80005360:	b765                	j	80005308 <fileread+0x60>
      return -1;
    80005362:	597d                	li	s2,-1
    80005364:	b755                	j	80005308 <fileread+0x60>
    80005366:	597d                	li	s2,-1
    80005368:	b745                	j	80005308 <fileread+0x60>

000000008000536a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000536a:	715d                	addi	sp,sp,-80
    8000536c:	e486                	sd	ra,72(sp)
    8000536e:	e0a2                	sd	s0,64(sp)
    80005370:	fc26                	sd	s1,56(sp)
    80005372:	f84a                	sd	s2,48(sp)
    80005374:	f44e                	sd	s3,40(sp)
    80005376:	f052                	sd	s4,32(sp)
    80005378:	ec56                	sd	s5,24(sp)
    8000537a:	e85a                	sd	s6,16(sp)
    8000537c:	e45e                	sd	s7,8(sp)
    8000537e:	e062                	sd	s8,0(sp)
    80005380:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005382:	00954783          	lbu	a5,9(a0)
    80005386:	10078663          	beqz	a5,80005492 <filewrite+0x128>
    8000538a:	892a                	mv	s2,a0
    8000538c:	8aae                	mv	s5,a1
    8000538e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005390:	411c                	lw	a5,0(a0)
    80005392:	4705                	li	a4,1
    80005394:	02e78263          	beq	a5,a4,800053b8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005398:	470d                	li	a4,3
    8000539a:	02e78663          	beq	a5,a4,800053c6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000539e:	4709                	li	a4,2
    800053a0:	0ee79163          	bne	a5,a4,80005482 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800053a4:	0ac05d63          	blez	a2,8000545e <filewrite+0xf4>
    int i = 0;
    800053a8:	4981                	li	s3,0
    800053aa:	6b05                	lui	s6,0x1
    800053ac:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053b0:	6b85                	lui	s7,0x1
    800053b2:	c00b8b9b          	addiw	s7,s7,-1024
    800053b6:	a861                	j	8000544e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800053b8:	6908                	ld	a0,16(a0)
    800053ba:	00000097          	auipc	ra,0x0
    800053be:	22e080e7          	jalr	558(ra) # 800055e8 <pipewrite>
    800053c2:	8a2a                	mv	s4,a0
    800053c4:	a045                	j	80005464 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053c6:	02451783          	lh	a5,36(a0)
    800053ca:	03079693          	slli	a3,a5,0x30
    800053ce:	92c1                	srli	a3,a3,0x30
    800053d0:	4725                	li	a4,9
    800053d2:	0cd76263          	bltu	a4,a3,80005496 <filewrite+0x12c>
    800053d6:	0792                	slli	a5,a5,0x4
    800053d8:	0001c717          	auipc	a4,0x1c
    800053dc:	26870713          	addi	a4,a4,616 # 80021640 <devsw>
    800053e0:	97ba                	add	a5,a5,a4
    800053e2:	679c                	ld	a5,8(a5)
    800053e4:	cbdd                	beqz	a5,8000549a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053e6:	4505                	li	a0,1
    800053e8:	9782                	jalr	a5
    800053ea:	8a2a                	mv	s4,a0
    800053ec:	a8a5                	j	80005464 <filewrite+0xfa>
    800053ee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053f2:	00000097          	auipc	ra,0x0
    800053f6:	8b0080e7          	jalr	-1872(ra) # 80004ca2 <begin_op>
      ilock(f->ip);
    800053fa:	01893503          	ld	a0,24(s2)
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	ed2080e7          	jalr	-302(ra) # 800042d0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005406:	8762                	mv	a4,s8
    80005408:	02092683          	lw	a3,32(s2)
    8000540c:	01598633          	add	a2,s3,s5
    80005410:	4585                	li	a1,1
    80005412:	01893503          	ld	a0,24(s2)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	266080e7          	jalr	614(ra) # 8000467c <writei>
    8000541e:	84aa                	mv	s1,a0
    80005420:	00a05763          	blez	a0,8000542e <filewrite+0xc4>
        f->off += r;
    80005424:	02092783          	lw	a5,32(s2)
    80005428:	9fa9                	addw	a5,a5,a0
    8000542a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000542e:	01893503          	ld	a0,24(s2)
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	f60080e7          	jalr	-160(ra) # 80004392 <iunlock>
      end_op();
    8000543a:	00000097          	auipc	ra,0x0
    8000543e:	8e8080e7          	jalr	-1816(ra) # 80004d22 <end_op>

      if(r != n1){
    80005442:	009c1f63          	bne	s8,s1,80005460 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005446:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000544a:	0149db63          	bge	s3,s4,80005460 <filewrite+0xf6>
      int n1 = n - i;
    8000544e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005452:	84be                	mv	s1,a5
    80005454:	2781                	sext.w	a5,a5
    80005456:	f8fb5ce3          	bge	s6,a5,800053ee <filewrite+0x84>
    8000545a:	84de                	mv	s1,s7
    8000545c:	bf49                	j	800053ee <filewrite+0x84>
    int i = 0;
    8000545e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005460:	013a1f63          	bne	s4,s3,8000547e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005464:	8552                	mv	a0,s4
    80005466:	60a6                	ld	ra,72(sp)
    80005468:	6406                	ld	s0,64(sp)
    8000546a:	74e2                	ld	s1,56(sp)
    8000546c:	7942                	ld	s2,48(sp)
    8000546e:	79a2                	ld	s3,40(sp)
    80005470:	7a02                	ld	s4,32(sp)
    80005472:	6ae2                	ld	s5,24(sp)
    80005474:	6b42                	ld	s6,16(sp)
    80005476:	6ba2                	ld	s7,8(sp)
    80005478:	6c02                	ld	s8,0(sp)
    8000547a:	6161                	addi	sp,sp,80
    8000547c:	8082                	ret
    ret = (i == n ? n : -1);
    8000547e:	5a7d                	li	s4,-1
    80005480:	b7d5                	j	80005464 <filewrite+0xfa>
    panic("filewrite");
    80005482:	00003517          	auipc	a0,0x3
    80005486:	72e50513          	addi	a0,a0,1838 # 80008bb0 <syscalls+0x268>
    8000548a:	ffffb097          	auipc	ra,0xffffb
    8000548e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>
    return -1;
    80005492:	5a7d                	li	s4,-1
    80005494:	bfc1                	j	80005464 <filewrite+0xfa>
      return -1;
    80005496:	5a7d                	li	s4,-1
    80005498:	b7f1                	j	80005464 <filewrite+0xfa>
    8000549a:	5a7d                	li	s4,-1
    8000549c:	b7e1                	j	80005464 <filewrite+0xfa>

000000008000549e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000549e:	7179                	addi	sp,sp,-48
    800054a0:	f406                	sd	ra,40(sp)
    800054a2:	f022                	sd	s0,32(sp)
    800054a4:	ec26                	sd	s1,24(sp)
    800054a6:	e84a                	sd	s2,16(sp)
    800054a8:	e44e                	sd	s3,8(sp)
    800054aa:	e052                	sd	s4,0(sp)
    800054ac:	1800                	addi	s0,sp,48
    800054ae:	84aa                	mv	s1,a0
    800054b0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800054b2:	0005b023          	sd	zero,0(a1)
    800054b6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800054ba:	00000097          	auipc	ra,0x0
    800054be:	bf8080e7          	jalr	-1032(ra) # 800050b2 <filealloc>
    800054c2:	e088                	sd	a0,0(s1)
    800054c4:	c551                	beqz	a0,80005550 <pipealloc+0xb2>
    800054c6:	00000097          	auipc	ra,0x0
    800054ca:	bec080e7          	jalr	-1044(ra) # 800050b2 <filealloc>
    800054ce:	00aa3023          	sd	a0,0(s4)
    800054d2:	c92d                	beqz	a0,80005544 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054d4:	ffffb097          	auipc	ra,0xffffb
    800054d8:	620080e7          	jalr	1568(ra) # 80000af4 <kalloc>
    800054dc:	892a                	mv	s2,a0
    800054de:	c125                	beqz	a0,8000553e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054e0:	4985                	li	s3,1
    800054e2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054e6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800054ea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800054ee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800054f2:	00003597          	auipc	a1,0x3
    800054f6:	6ce58593          	addi	a1,a1,1742 # 80008bc0 <syscalls+0x278>
    800054fa:	ffffb097          	auipc	ra,0xffffb
    800054fe:	65a080e7          	jalr	1626(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005502:	609c                	ld	a5,0(s1)
    80005504:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005508:	609c                	ld	a5,0(s1)
    8000550a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000550e:	609c                	ld	a5,0(s1)
    80005510:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005514:	609c                	ld	a5,0(s1)
    80005516:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000551a:	000a3783          	ld	a5,0(s4)
    8000551e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005522:	000a3783          	ld	a5,0(s4)
    80005526:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000552a:	000a3783          	ld	a5,0(s4)
    8000552e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005532:	000a3783          	ld	a5,0(s4)
    80005536:	0127b823          	sd	s2,16(a5)
  return 0;
    8000553a:	4501                	li	a0,0
    8000553c:	a025                	j	80005564 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000553e:	6088                	ld	a0,0(s1)
    80005540:	e501                	bnez	a0,80005548 <pipealloc+0xaa>
    80005542:	a039                	j	80005550 <pipealloc+0xb2>
    80005544:	6088                	ld	a0,0(s1)
    80005546:	c51d                	beqz	a0,80005574 <pipealloc+0xd6>
    fileclose(*f0);
    80005548:	00000097          	auipc	ra,0x0
    8000554c:	c26080e7          	jalr	-986(ra) # 8000516e <fileclose>
  if(*f1)
    80005550:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005554:	557d                	li	a0,-1
  if(*f1)
    80005556:	c799                	beqz	a5,80005564 <pipealloc+0xc6>
    fileclose(*f1);
    80005558:	853e                	mv	a0,a5
    8000555a:	00000097          	auipc	ra,0x0
    8000555e:	c14080e7          	jalr	-1004(ra) # 8000516e <fileclose>
  return -1;
    80005562:	557d                	li	a0,-1
}
    80005564:	70a2                	ld	ra,40(sp)
    80005566:	7402                	ld	s0,32(sp)
    80005568:	64e2                	ld	s1,24(sp)
    8000556a:	6942                	ld	s2,16(sp)
    8000556c:	69a2                	ld	s3,8(sp)
    8000556e:	6a02                	ld	s4,0(sp)
    80005570:	6145                	addi	sp,sp,48
    80005572:	8082                	ret
  return -1;
    80005574:	557d                	li	a0,-1
    80005576:	b7fd                	j	80005564 <pipealloc+0xc6>

0000000080005578 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005578:	1101                	addi	sp,sp,-32
    8000557a:	ec06                	sd	ra,24(sp)
    8000557c:	e822                	sd	s0,16(sp)
    8000557e:	e426                	sd	s1,8(sp)
    80005580:	e04a                	sd	s2,0(sp)
    80005582:	1000                	addi	s0,sp,32
    80005584:	84aa                	mv	s1,a0
    80005586:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005588:	ffffb097          	auipc	ra,0xffffb
    8000558c:	65c080e7          	jalr	1628(ra) # 80000be4 <acquire>
  if(writable){
    80005590:	02090d63          	beqz	s2,800055ca <pipeclose+0x52>
    pi->writeopen = 0;
    80005594:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005598:	21848513          	addi	a0,s1,536
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	86c080e7          	jalr	-1940(ra) # 80002e08 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800055a4:	2204b783          	ld	a5,544(s1)
    800055a8:	eb95                	bnez	a5,800055dc <pipeclose+0x64>
    release(&pi->lock);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffb097          	auipc	ra,0xffffb
    800055b0:	6fe080e7          	jalr	1790(ra) # 80000caa <release>
    kfree((char*)pi);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffb097          	auipc	ra,0xffffb
    800055ba:	442080e7          	jalr	1090(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800055be:	60e2                	ld	ra,24(sp)
    800055c0:	6442                	ld	s0,16(sp)
    800055c2:	64a2                	ld	s1,8(sp)
    800055c4:	6902                	ld	s2,0(sp)
    800055c6:	6105                	addi	sp,sp,32
    800055c8:	8082                	ret
    pi->readopen = 0;
    800055ca:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055ce:	21c48513          	addi	a0,s1,540
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	836080e7          	jalr	-1994(ra) # 80002e08 <wakeup>
    800055da:	b7e9                	j	800055a4 <pipeclose+0x2c>
    release(&pi->lock);
    800055dc:	8526                	mv	a0,s1
    800055de:	ffffb097          	auipc	ra,0xffffb
    800055e2:	6cc080e7          	jalr	1740(ra) # 80000caa <release>
}
    800055e6:	bfe1                	j	800055be <pipeclose+0x46>

00000000800055e8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800055e8:	7159                	addi	sp,sp,-112
    800055ea:	f486                	sd	ra,104(sp)
    800055ec:	f0a2                	sd	s0,96(sp)
    800055ee:	eca6                	sd	s1,88(sp)
    800055f0:	e8ca                	sd	s2,80(sp)
    800055f2:	e4ce                	sd	s3,72(sp)
    800055f4:	e0d2                	sd	s4,64(sp)
    800055f6:	fc56                	sd	s5,56(sp)
    800055f8:	f85a                	sd	s6,48(sp)
    800055fa:	f45e                	sd	s7,40(sp)
    800055fc:	f062                	sd	s8,32(sp)
    800055fe:	ec66                	sd	s9,24(sp)
    80005600:	1880                	addi	s0,sp,112
    80005602:	84aa                	mv	s1,a0
    80005604:	8aae                	mv	s5,a1
    80005606:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005608:	ffffd097          	auipc	ra,0xffffd
    8000560c:	cf4080e7          	jalr	-780(ra) # 800022fc <myproc>
    80005610:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005612:	8526                	mv	a0,s1
    80005614:	ffffb097          	auipc	ra,0xffffb
    80005618:	5d0080e7          	jalr	1488(ra) # 80000be4 <acquire>
  while(i < n){
    8000561c:	0d405163          	blez	s4,800056de <pipewrite+0xf6>
    80005620:	8ba6                	mv	s7,s1
  int i = 0;
    80005622:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005624:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005626:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000562a:	21c48c13          	addi	s8,s1,540
    8000562e:	a08d                	j	80005690 <pipewrite+0xa8>
      release(&pi->lock);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	678080e7          	jalr	1656(ra) # 80000caa <release>
      return -1;
    8000563a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000563c:	854a                	mv	a0,s2
    8000563e:	70a6                	ld	ra,104(sp)
    80005640:	7406                	ld	s0,96(sp)
    80005642:	64e6                	ld	s1,88(sp)
    80005644:	6946                	ld	s2,80(sp)
    80005646:	69a6                	ld	s3,72(sp)
    80005648:	6a06                	ld	s4,64(sp)
    8000564a:	7ae2                	ld	s5,56(sp)
    8000564c:	7b42                	ld	s6,48(sp)
    8000564e:	7ba2                	ld	s7,40(sp)
    80005650:	7c02                	ld	s8,32(sp)
    80005652:	6ce2                	ld	s9,24(sp)
    80005654:	6165                	addi	sp,sp,112
    80005656:	8082                	ret
      wakeup(&pi->nread);
    80005658:	8566                	mv	a0,s9
    8000565a:	ffffd097          	auipc	ra,0xffffd
    8000565e:	7ae080e7          	jalr	1966(ra) # 80002e08 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005662:	85de                	mv	a1,s7
    80005664:	8562                	mv	a0,s8
    80005666:	ffffd097          	auipc	ra,0xffffd
    8000566a:	5f6080e7          	jalr	1526(ra) # 80002c5c <sleep>
    8000566e:	a839                	j	8000568c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005670:	21c4a783          	lw	a5,540(s1)
    80005674:	0017871b          	addiw	a4,a5,1
    80005678:	20e4ae23          	sw	a4,540(s1)
    8000567c:	1ff7f793          	andi	a5,a5,511
    80005680:	97a6                	add	a5,a5,s1
    80005682:	f9f44703          	lbu	a4,-97(s0)
    80005686:	00e78c23          	sb	a4,24(a5)
      i++;
    8000568a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000568c:	03495d63          	bge	s2,s4,800056c6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005690:	2204a783          	lw	a5,544(s1)
    80005694:	dfd1                	beqz	a5,80005630 <pipewrite+0x48>
    80005696:	0289a783          	lw	a5,40(s3)
    8000569a:	fbd9                	bnez	a5,80005630 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000569c:	2184a783          	lw	a5,536(s1)
    800056a0:	21c4a703          	lw	a4,540(s1)
    800056a4:	2007879b          	addiw	a5,a5,512
    800056a8:	faf708e3          	beq	a4,a5,80005658 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056ac:	4685                	li	a3,1
    800056ae:	01590633          	add	a2,s2,s5
    800056b2:	f9f40593          	addi	a1,s0,-97
    800056b6:	0589b503          	ld	a0,88(s3)
    800056ba:	ffffc097          	auipc	ra,0xffffc
    800056be:	068080e7          	jalr	104(ra) # 80001722 <copyin>
    800056c2:	fb6517e3          	bne	a0,s6,80005670 <pipewrite+0x88>
  wakeup(&pi->nread);
    800056c6:	21848513          	addi	a0,s1,536
    800056ca:	ffffd097          	auipc	ra,0xffffd
    800056ce:	73e080e7          	jalr	1854(ra) # 80002e08 <wakeup>
  release(&pi->lock);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffb097          	auipc	ra,0xffffb
    800056d8:	5d6080e7          	jalr	1494(ra) # 80000caa <release>
  return i;
    800056dc:	b785                	j	8000563c <pipewrite+0x54>
  int i = 0;
    800056de:	4901                	li	s2,0
    800056e0:	b7dd                	j	800056c6 <pipewrite+0xde>

00000000800056e2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056e2:	715d                	addi	sp,sp,-80
    800056e4:	e486                	sd	ra,72(sp)
    800056e6:	e0a2                	sd	s0,64(sp)
    800056e8:	fc26                	sd	s1,56(sp)
    800056ea:	f84a                	sd	s2,48(sp)
    800056ec:	f44e                	sd	s3,40(sp)
    800056ee:	f052                	sd	s4,32(sp)
    800056f0:	ec56                	sd	s5,24(sp)
    800056f2:	e85a                	sd	s6,16(sp)
    800056f4:	0880                	addi	s0,sp,80
    800056f6:	84aa                	mv	s1,a0
    800056f8:	892e                	mv	s2,a1
    800056fa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056fc:	ffffd097          	auipc	ra,0xffffd
    80005700:	c00080e7          	jalr	-1024(ra) # 800022fc <myproc>
    80005704:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005706:	8b26                	mv	s6,s1
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	4da080e7          	jalr	1242(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005712:	2184a703          	lw	a4,536(s1)
    80005716:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000571a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000571e:	02f71463          	bne	a4,a5,80005746 <piperead+0x64>
    80005722:	2244a783          	lw	a5,548(s1)
    80005726:	c385                	beqz	a5,80005746 <piperead+0x64>
    if(pr->killed){
    80005728:	028a2783          	lw	a5,40(s4)
    8000572c:	ebc1                	bnez	a5,800057bc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000572e:	85da                	mv	a1,s6
    80005730:	854e                	mv	a0,s3
    80005732:	ffffd097          	auipc	ra,0xffffd
    80005736:	52a080e7          	jalr	1322(ra) # 80002c5c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000573a:	2184a703          	lw	a4,536(s1)
    8000573e:	21c4a783          	lw	a5,540(s1)
    80005742:	fef700e3          	beq	a4,a5,80005722 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005746:	09505263          	blez	s5,800057ca <piperead+0xe8>
    8000574a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000574c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000574e:	2184a783          	lw	a5,536(s1)
    80005752:	21c4a703          	lw	a4,540(s1)
    80005756:	02f70d63          	beq	a4,a5,80005790 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000575a:	0017871b          	addiw	a4,a5,1
    8000575e:	20e4ac23          	sw	a4,536(s1)
    80005762:	1ff7f793          	andi	a5,a5,511
    80005766:	97a6                	add	a5,a5,s1
    80005768:	0187c783          	lbu	a5,24(a5)
    8000576c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005770:	4685                	li	a3,1
    80005772:	fbf40613          	addi	a2,s0,-65
    80005776:	85ca                	mv	a1,s2
    80005778:	058a3503          	ld	a0,88(s4)
    8000577c:	ffffc097          	auipc	ra,0xffffc
    80005780:	f1a080e7          	jalr	-230(ra) # 80001696 <copyout>
    80005784:	01650663          	beq	a0,s6,80005790 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005788:	2985                	addiw	s3,s3,1
    8000578a:	0905                	addi	s2,s2,1
    8000578c:	fd3a91e3          	bne	s5,s3,8000574e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005790:	21c48513          	addi	a0,s1,540
    80005794:	ffffd097          	auipc	ra,0xffffd
    80005798:	674080e7          	jalr	1652(ra) # 80002e08 <wakeup>
  release(&pi->lock);
    8000579c:	8526                	mv	a0,s1
    8000579e:	ffffb097          	auipc	ra,0xffffb
    800057a2:	50c080e7          	jalr	1292(ra) # 80000caa <release>
  return i;
}
    800057a6:	854e                	mv	a0,s3
    800057a8:	60a6                	ld	ra,72(sp)
    800057aa:	6406                	ld	s0,64(sp)
    800057ac:	74e2                	ld	s1,56(sp)
    800057ae:	7942                	ld	s2,48(sp)
    800057b0:	79a2                	ld	s3,40(sp)
    800057b2:	7a02                	ld	s4,32(sp)
    800057b4:	6ae2                	ld	s5,24(sp)
    800057b6:	6b42                	ld	s6,16(sp)
    800057b8:	6161                	addi	sp,sp,80
    800057ba:	8082                	ret
      release(&pi->lock);
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	4ec080e7          	jalr	1260(ra) # 80000caa <release>
      return -1;
    800057c6:	59fd                	li	s3,-1
    800057c8:	bff9                	j	800057a6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057ca:	4981                	li	s3,0
    800057cc:	b7d1                	j	80005790 <piperead+0xae>

00000000800057ce <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800057ce:	df010113          	addi	sp,sp,-528
    800057d2:	20113423          	sd	ra,520(sp)
    800057d6:	20813023          	sd	s0,512(sp)
    800057da:	ffa6                	sd	s1,504(sp)
    800057dc:	fbca                	sd	s2,496(sp)
    800057de:	f7ce                	sd	s3,488(sp)
    800057e0:	f3d2                	sd	s4,480(sp)
    800057e2:	efd6                	sd	s5,472(sp)
    800057e4:	ebda                	sd	s6,464(sp)
    800057e6:	e7de                	sd	s7,456(sp)
    800057e8:	e3e2                	sd	s8,448(sp)
    800057ea:	ff66                	sd	s9,440(sp)
    800057ec:	fb6a                	sd	s10,432(sp)
    800057ee:	f76e                	sd	s11,424(sp)
    800057f0:	0c00                	addi	s0,sp,528
    800057f2:	84aa                	mv	s1,a0
    800057f4:	dea43c23          	sd	a0,-520(s0)
    800057f8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	b00080e7          	jalr	-1280(ra) # 800022fc <myproc>
    80005804:	892a                	mv	s2,a0

  begin_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	49c080e7          	jalr	1180(ra) # 80004ca2 <begin_op>

  if((ip = namei(path)) == 0){
    8000580e:	8526                	mv	a0,s1
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	276080e7          	jalr	630(ra) # 80004a86 <namei>
    80005818:	c92d                	beqz	a0,8000588a <exec+0xbc>
    8000581a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	ab4080e7          	jalr	-1356(ra) # 800042d0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005824:	04000713          	li	a4,64
    80005828:	4681                	li	a3,0
    8000582a:	e5040613          	addi	a2,s0,-432
    8000582e:	4581                	li	a1,0
    80005830:	8526                	mv	a0,s1
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	d52080e7          	jalr	-686(ra) # 80004584 <readi>
    8000583a:	04000793          	li	a5,64
    8000583e:	00f51a63          	bne	a0,a5,80005852 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005842:	e5042703          	lw	a4,-432(s0)
    80005846:	464c47b7          	lui	a5,0x464c4
    8000584a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000584e:	04f70463          	beq	a4,a5,80005896 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	cde080e7          	jalr	-802(ra) # 80004532 <iunlockput>
    end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	4c6080e7          	jalr	1222(ra) # 80004d22 <end_op>
  }
  return -1;
    80005864:	557d                	li	a0,-1
}
    80005866:	20813083          	ld	ra,520(sp)
    8000586a:	20013403          	ld	s0,512(sp)
    8000586e:	74fe                	ld	s1,504(sp)
    80005870:	795e                	ld	s2,496(sp)
    80005872:	79be                	ld	s3,488(sp)
    80005874:	7a1e                	ld	s4,480(sp)
    80005876:	6afe                	ld	s5,472(sp)
    80005878:	6b5e                	ld	s6,464(sp)
    8000587a:	6bbe                	ld	s7,456(sp)
    8000587c:	6c1e                	ld	s8,448(sp)
    8000587e:	7cfa                	ld	s9,440(sp)
    80005880:	7d5a                	ld	s10,432(sp)
    80005882:	7dba                	ld	s11,424(sp)
    80005884:	21010113          	addi	sp,sp,528
    80005888:	8082                	ret
    end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	498080e7          	jalr	1176(ra) # 80004d22 <end_op>
    return -1;
    80005892:	557d                	li	a0,-1
    80005894:	bfc9                	j	80005866 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005896:	854a                	mv	a0,s2
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	b1c080e7          	jalr	-1252(ra) # 800023b4 <proc_pagetable>
    800058a0:	8baa                	mv	s7,a0
    800058a2:	d945                	beqz	a0,80005852 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058a4:	e7042983          	lw	s3,-400(s0)
    800058a8:	e8845783          	lhu	a5,-376(s0)
    800058ac:	c7ad                	beqz	a5,80005916 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058ae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058b0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800058b2:	6c85                	lui	s9,0x1
    800058b4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800058b8:	def43823          	sd	a5,-528(s0)
    800058bc:	a42d                	j	80005ae6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800058be:	00003517          	auipc	a0,0x3
    800058c2:	30a50513          	addi	a0,a0,778 # 80008bc8 <syscalls+0x280>
    800058c6:	ffffb097          	auipc	ra,0xffffb
    800058ca:	c78080e7          	jalr	-904(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800058ce:	8756                	mv	a4,s5
    800058d0:	012d86bb          	addw	a3,s11,s2
    800058d4:	4581                	li	a1,0
    800058d6:	8526                	mv	a0,s1
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	cac080e7          	jalr	-852(ra) # 80004584 <readi>
    800058e0:	2501                	sext.w	a0,a0
    800058e2:	1aaa9963          	bne	s5,a0,80005a94 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800058e6:	6785                	lui	a5,0x1
    800058e8:	0127893b          	addw	s2,a5,s2
    800058ec:	77fd                	lui	a5,0xfffff
    800058ee:	01478a3b          	addw	s4,a5,s4
    800058f2:	1f897163          	bgeu	s2,s8,80005ad4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800058f6:	02091593          	slli	a1,s2,0x20
    800058fa:	9181                	srli	a1,a1,0x20
    800058fc:	95ea                	add	a1,a1,s10
    800058fe:	855e                	mv	a0,s7
    80005900:	ffffb097          	auipc	ra,0xffffb
    80005904:	792080e7          	jalr	1938(ra) # 80001092 <walkaddr>
    80005908:	862a                	mv	a2,a0
    if(pa == 0)
    8000590a:	d955                	beqz	a0,800058be <exec+0xf0>
      n = PGSIZE;
    8000590c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000590e:	fd9a70e3          	bgeu	s4,s9,800058ce <exec+0x100>
      n = sz - i;
    80005912:	8ad2                	mv	s5,s4
    80005914:	bf6d                	j	800058ce <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005916:	4901                	li	s2,0
  iunlockput(ip);
    80005918:	8526                	mv	a0,s1
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	c18080e7          	jalr	-1000(ra) # 80004532 <iunlockput>
  end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	400080e7          	jalr	1024(ra) # 80004d22 <end_op>
  p = myproc();
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	9d2080e7          	jalr	-1582(ra) # 800022fc <myproc>
    80005932:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005934:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005938:	6785                	lui	a5,0x1
    8000593a:	17fd                	addi	a5,a5,-1
    8000593c:	993e                	add	s2,s2,a5
    8000593e:	757d                	lui	a0,0xfffff
    80005940:	00a977b3          	and	a5,s2,a0
    80005944:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005948:	6609                	lui	a2,0x2
    8000594a:	963e                	add	a2,a2,a5
    8000594c:	85be                	mv	a1,a5
    8000594e:	855e                	mv	a0,s7
    80005950:	ffffc097          	auipc	ra,0xffffc
    80005954:	af6080e7          	jalr	-1290(ra) # 80001446 <uvmalloc>
    80005958:	8b2a                	mv	s6,a0
  ip = 0;
    8000595a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000595c:	12050c63          	beqz	a0,80005a94 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005960:	75f9                	lui	a1,0xffffe
    80005962:	95aa                	add	a1,a1,a0
    80005964:	855e                	mv	a0,s7
    80005966:	ffffc097          	auipc	ra,0xffffc
    8000596a:	cfe080e7          	jalr	-770(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    8000596e:	7c7d                	lui	s8,0xfffff
    80005970:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005972:	e0043783          	ld	a5,-512(s0)
    80005976:	6388                	ld	a0,0(a5)
    80005978:	c535                	beqz	a0,800059e4 <exec+0x216>
    8000597a:	e9040993          	addi	s3,s0,-368
    8000597e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005982:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005984:	ffffb097          	auipc	ra,0xffffb
    80005988:	504080e7          	jalr	1284(ra) # 80000e88 <strlen>
    8000598c:	2505                	addiw	a0,a0,1
    8000598e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005992:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005996:	13896363          	bltu	s2,s8,80005abc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000599a:	e0043d83          	ld	s11,-512(s0)
    8000599e:	000dba03          	ld	s4,0(s11)
    800059a2:	8552                	mv	a0,s4
    800059a4:	ffffb097          	auipc	ra,0xffffb
    800059a8:	4e4080e7          	jalr	1252(ra) # 80000e88 <strlen>
    800059ac:	0015069b          	addiw	a3,a0,1
    800059b0:	8652                	mv	a2,s4
    800059b2:	85ca                	mv	a1,s2
    800059b4:	855e                	mv	a0,s7
    800059b6:	ffffc097          	auipc	ra,0xffffc
    800059ba:	ce0080e7          	jalr	-800(ra) # 80001696 <copyout>
    800059be:	10054363          	bltz	a0,80005ac4 <exec+0x2f6>
    ustack[argc] = sp;
    800059c2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800059c6:	0485                	addi	s1,s1,1
    800059c8:	008d8793          	addi	a5,s11,8
    800059cc:	e0f43023          	sd	a5,-512(s0)
    800059d0:	008db503          	ld	a0,8(s11)
    800059d4:	c911                	beqz	a0,800059e8 <exec+0x21a>
    if(argc >= MAXARG)
    800059d6:	09a1                	addi	s3,s3,8
    800059d8:	fb3c96e3          	bne	s9,s3,80005984 <exec+0x1b6>
  sz = sz1;
    800059dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059e0:	4481                	li	s1,0
    800059e2:	a84d                	j	80005a94 <exec+0x2c6>
  sp = sz;
    800059e4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800059e6:	4481                	li	s1,0
  ustack[argc] = 0;
    800059e8:	00349793          	slli	a5,s1,0x3
    800059ec:	f9040713          	addi	a4,s0,-112
    800059f0:	97ba                	add	a5,a5,a4
    800059f2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800059f6:	00148693          	addi	a3,s1,1
    800059fa:	068e                	slli	a3,a3,0x3
    800059fc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a00:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a04:	01897663          	bgeu	s2,s8,80005a10 <exec+0x242>
  sz = sz1;
    80005a08:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a0c:	4481                	li	s1,0
    80005a0e:	a059                	j	80005a94 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a10:	e9040613          	addi	a2,s0,-368
    80005a14:	85ca                	mv	a1,s2
    80005a16:	855e                	mv	a0,s7
    80005a18:	ffffc097          	auipc	ra,0xffffc
    80005a1c:	c7e080e7          	jalr	-898(ra) # 80001696 <copyout>
    80005a20:	0a054663          	bltz	a0,80005acc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005a24:	060ab783          	ld	a5,96(s5)
    80005a28:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a2c:	df843783          	ld	a5,-520(s0)
    80005a30:	0007c703          	lbu	a4,0(a5)
    80005a34:	cf11                	beqz	a4,80005a50 <exec+0x282>
    80005a36:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a38:	02f00693          	li	a3,47
    80005a3c:	a039                	j	80005a4a <exec+0x27c>
      last = s+1;
    80005a3e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a42:	0785                	addi	a5,a5,1
    80005a44:	fff7c703          	lbu	a4,-1(a5)
    80005a48:	c701                	beqz	a4,80005a50 <exec+0x282>
    if(*s == '/')
    80005a4a:	fed71ce3          	bne	a4,a3,80005a42 <exec+0x274>
    80005a4e:	bfc5                	j	80005a3e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a50:	4641                	li	a2,16
    80005a52:	df843583          	ld	a1,-520(s0)
    80005a56:	160a8513          	addi	a0,s5,352
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	3fc080e7          	jalr	1020(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a62:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005a66:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005a6a:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a6e:	060ab783          	ld	a5,96(s5)
    80005a72:	e6843703          	ld	a4,-408(s0)
    80005a76:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a78:	060ab783          	ld	a5,96(s5)
    80005a7c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a80:	85ea                	mv	a1,s10
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	9ce080e7          	jalr	-1586(ra) # 80002450 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a8a:	0004851b          	sext.w	a0,s1
    80005a8e:	bbe1                	j	80005866 <exec+0x98>
    80005a90:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005a94:	e0843583          	ld	a1,-504(s0)
    80005a98:	855e                	mv	a0,s7
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	9b6080e7          	jalr	-1610(ra) # 80002450 <proc_freepagetable>
  if(ip){
    80005aa2:	da0498e3          	bnez	s1,80005852 <exec+0x84>
  return -1;
    80005aa6:	557d                	li	a0,-1
    80005aa8:	bb7d                	j	80005866 <exec+0x98>
    80005aaa:	e1243423          	sd	s2,-504(s0)
    80005aae:	b7dd                	j	80005a94 <exec+0x2c6>
    80005ab0:	e1243423          	sd	s2,-504(s0)
    80005ab4:	b7c5                	j	80005a94 <exec+0x2c6>
    80005ab6:	e1243423          	sd	s2,-504(s0)
    80005aba:	bfe9                	j	80005a94 <exec+0x2c6>
  sz = sz1;
    80005abc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ac0:	4481                	li	s1,0
    80005ac2:	bfc9                	j	80005a94 <exec+0x2c6>
  sz = sz1;
    80005ac4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ac8:	4481                	li	s1,0
    80005aca:	b7e9                	j	80005a94 <exec+0x2c6>
  sz = sz1;
    80005acc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ad0:	4481                	li	s1,0
    80005ad2:	b7c9                	j	80005a94 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005ad4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005ad8:	2b05                	addiw	s6,s6,1
    80005ada:	0389899b          	addiw	s3,s3,56
    80005ade:	e8845783          	lhu	a5,-376(s0)
    80005ae2:	e2fb5be3          	bge	s6,a5,80005918 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005ae6:	2981                	sext.w	s3,s3
    80005ae8:	03800713          	li	a4,56
    80005aec:	86ce                	mv	a3,s3
    80005aee:	e1840613          	addi	a2,s0,-488
    80005af2:	4581                	li	a1,0
    80005af4:	8526                	mv	a0,s1
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	a8e080e7          	jalr	-1394(ra) # 80004584 <readi>
    80005afe:	03800793          	li	a5,56
    80005b02:	f8f517e3          	bne	a0,a5,80005a90 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005b06:	e1842783          	lw	a5,-488(s0)
    80005b0a:	4705                	li	a4,1
    80005b0c:	fce796e3          	bne	a5,a4,80005ad8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005b10:	e4043603          	ld	a2,-448(s0)
    80005b14:	e3843783          	ld	a5,-456(s0)
    80005b18:	f8f669e3          	bltu	a2,a5,80005aaa <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005b1c:	e2843783          	ld	a5,-472(s0)
    80005b20:	963e                	add	a2,a2,a5
    80005b22:	f8f667e3          	bltu	a2,a5,80005ab0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b26:	85ca                	mv	a1,s2
    80005b28:	855e                	mv	a0,s7
    80005b2a:	ffffc097          	auipc	ra,0xffffc
    80005b2e:	91c080e7          	jalr	-1764(ra) # 80001446 <uvmalloc>
    80005b32:	e0a43423          	sd	a0,-504(s0)
    80005b36:	d141                	beqz	a0,80005ab6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005b38:	e2843d03          	ld	s10,-472(s0)
    80005b3c:	df043783          	ld	a5,-528(s0)
    80005b40:	00fd77b3          	and	a5,s10,a5
    80005b44:	fba1                	bnez	a5,80005a94 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b46:	e2042d83          	lw	s11,-480(s0)
    80005b4a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b4e:	f80c03e3          	beqz	s8,80005ad4 <exec+0x306>
    80005b52:	8a62                	mv	s4,s8
    80005b54:	4901                	li	s2,0
    80005b56:	b345                	j	800058f6 <exec+0x128>

0000000080005b58 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b58:	7179                	addi	sp,sp,-48
    80005b5a:	f406                	sd	ra,40(sp)
    80005b5c:	f022                	sd	s0,32(sp)
    80005b5e:	ec26                	sd	s1,24(sp)
    80005b60:	e84a                	sd	s2,16(sp)
    80005b62:	1800                	addi	s0,sp,48
    80005b64:	892e                	mv	s2,a1
    80005b66:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005b68:	fdc40593          	addi	a1,s0,-36
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	bf2080e7          	jalr	-1038(ra) # 8000375e <argint>
    80005b74:	04054063          	bltz	a0,80005bb4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b78:	fdc42703          	lw	a4,-36(s0)
    80005b7c:	47bd                	li	a5,15
    80005b7e:	02e7ed63          	bltu	a5,a4,80005bb8 <argfd+0x60>
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	77a080e7          	jalr	1914(ra) # 800022fc <myproc>
    80005b8a:	fdc42703          	lw	a4,-36(s0)
    80005b8e:	01a70793          	addi	a5,a4,26
    80005b92:	078e                	slli	a5,a5,0x3
    80005b94:	953e                	add	a0,a0,a5
    80005b96:	651c                	ld	a5,8(a0)
    80005b98:	c395                	beqz	a5,80005bbc <argfd+0x64>
    return -1;
  if(pfd)
    80005b9a:	00090463          	beqz	s2,80005ba2 <argfd+0x4a>
    *pfd = fd;
    80005b9e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005ba2:	4501                	li	a0,0
  if(pf)
    80005ba4:	c091                	beqz	s1,80005ba8 <argfd+0x50>
    *pf = f;
    80005ba6:	e09c                	sd	a5,0(s1)
}
    80005ba8:	70a2                	ld	ra,40(sp)
    80005baa:	7402                	ld	s0,32(sp)
    80005bac:	64e2                	ld	s1,24(sp)
    80005bae:	6942                	ld	s2,16(sp)
    80005bb0:	6145                	addi	sp,sp,48
    80005bb2:	8082                	ret
    return -1;
    80005bb4:	557d                	li	a0,-1
    80005bb6:	bfcd                	j	80005ba8 <argfd+0x50>
    return -1;
    80005bb8:	557d                	li	a0,-1
    80005bba:	b7fd                	j	80005ba8 <argfd+0x50>
    80005bbc:	557d                	li	a0,-1
    80005bbe:	b7ed                	j	80005ba8 <argfd+0x50>

0000000080005bc0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005bc0:	1101                	addi	sp,sp,-32
    80005bc2:	ec06                	sd	ra,24(sp)
    80005bc4:	e822                	sd	s0,16(sp)
    80005bc6:	e426                	sd	s1,8(sp)
    80005bc8:	1000                	addi	s0,sp,32
    80005bca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005bcc:	ffffc097          	auipc	ra,0xffffc
    80005bd0:	730080e7          	jalr	1840(ra) # 800022fc <myproc>
    80005bd4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005bd6:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    80005bda:	4501                	li	a0,0
    80005bdc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005bde:	6398                	ld	a4,0(a5)
    80005be0:	cb19                	beqz	a4,80005bf6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005be2:	2505                	addiw	a0,a0,1
    80005be4:	07a1                	addi	a5,a5,8
    80005be6:	fed51ce3          	bne	a0,a3,80005bde <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005bea:	557d                	li	a0,-1
}
    80005bec:	60e2                	ld	ra,24(sp)
    80005bee:	6442                	ld	s0,16(sp)
    80005bf0:	64a2                	ld	s1,8(sp)
    80005bf2:	6105                	addi	sp,sp,32
    80005bf4:	8082                	ret
      p->ofile[fd] = f;
    80005bf6:	01a50793          	addi	a5,a0,26
    80005bfa:	078e                	slli	a5,a5,0x3
    80005bfc:	963e                	add	a2,a2,a5
    80005bfe:	e604                	sd	s1,8(a2)
      return fd;
    80005c00:	b7f5                	j	80005bec <fdalloc+0x2c>

0000000080005c02 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c02:	715d                	addi	sp,sp,-80
    80005c04:	e486                	sd	ra,72(sp)
    80005c06:	e0a2                	sd	s0,64(sp)
    80005c08:	fc26                	sd	s1,56(sp)
    80005c0a:	f84a                	sd	s2,48(sp)
    80005c0c:	f44e                	sd	s3,40(sp)
    80005c0e:	f052                	sd	s4,32(sp)
    80005c10:	ec56                	sd	s5,24(sp)
    80005c12:	0880                	addi	s0,sp,80
    80005c14:	89ae                	mv	s3,a1
    80005c16:	8ab2                	mv	s5,a2
    80005c18:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005c1a:	fb040593          	addi	a1,s0,-80
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	e86080e7          	jalr	-378(ra) # 80004aa4 <nameiparent>
    80005c26:	892a                	mv	s2,a0
    80005c28:	12050f63          	beqz	a0,80005d66 <create+0x164>
    return 0;

  ilock(dp);
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	6a4080e7          	jalr	1700(ra) # 800042d0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c34:	4601                	li	a2,0
    80005c36:	fb040593          	addi	a1,s0,-80
    80005c3a:	854a                	mv	a0,s2
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	b78080e7          	jalr	-1160(ra) # 800047b4 <dirlookup>
    80005c44:	84aa                	mv	s1,a0
    80005c46:	c921                	beqz	a0,80005c96 <create+0x94>
    iunlockput(dp);
    80005c48:	854a                	mv	a0,s2
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	8e8080e7          	jalr	-1816(ra) # 80004532 <iunlockput>
    ilock(ip);
    80005c52:	8526                	mv	a0,s1
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	67c080e7          	jalr	1660(ra) # 800042d0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c5c:	2981                	sext.w	s3,s3
    80005c5e:	4789                	li	a5,2
    80005c60:	02f99463          	bne	s3,a5,80005c88 <create+0x86>
    80005c64:	0444d783          	lhu	a5,68(s1)
    80005c68:	37f9                	addiw	a5,a5,-2
    80005c6a:	17c2                	slli	a5,a5,0x30
    80005c6c:	93c1                	srli	a5,a5,0x30
    80005c6e:	4705                	li	a4,1
    80005c70:	00f76c63          	bltu	a4,a5,80005c88 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005c74:	8526                	mv	a0,s1
    80005c76:	60a6                	ld	ra,72(sp)
    80005c78:	6406                	ld	s0,64(sp)
    80005c7a:	74e2                	ld	s1,56(sp)
    80005c7c:	7942                	ld	s2,48(sp)
    80005c7e:	79a2                	ld	s3,40(sp)
    80005c80:	7a02                	ld	s4,32(sp)
    80005c82:	6ae2                	ld	s5,24(sp)
    80005c84:	6161                	addi	sp,sp,80
    80005c86:	8082                	ret
    iunlockput(ip);
    80005c88:	8526                	mv	a0,s1
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	8a8080e7          	jalr	-1880(ra) # 80004532 <iunlockput>
    return 0;
    80005c92:	4481                	li	s1,0
    80005c94:	b7c5                	j	80005c74 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005c96:	85ce                	mv	a1,s3
    80005c98:	00092503          	lw	a0,0(s2)
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	49c080e7          	jalr	1180(ra) # 80004138 <ialloc>
    80005ca4:	84aa                	mv	s1,a0
    80005ca6:	c529                	beqz	a0,80005cf0 <create+0xee>
  ilock(ip);
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	628080e7          	jalr	1576(ra) # 800042d0 <ilock>
  ip->major = major;
    80005cb0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005cb4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005cb8:	4785                	li	a5,1
    80005cba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cbe:	8526                	mv	a0,s1
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	546080e7          	jalr	1350(ra) # 80004206 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005cc8:	2981                	sext.w	s3,s3
    80005cca:	4785                	li	a5,1
    80005ccc:	02f98a63          	beq	s3,a5,80005d00 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cd0:	40d0                	lw	a2,4(s1)
    80005cd2:	fb040593          	addi	a1,s0,-80
    80005cd6:	854a                	mv	a0,s2
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	cec080e7          	jalr	-788(ra) # 800049c4 <dirlink>
    80005ce0:	06054b63          	bltz	a0,80005d56 <create+0x154>
  iunlockput(dp);
    80005ce4:	854a                	mv	a0,s2
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	84c080e7          	jalr	-1972(ra) # 80004532 <iunlockput>
  return ip;
    80005cee:	b759                	j	80005c74 <create+0x72>
    panic("create: ialloc");
    80005cf0:	00003517          	auipc	a0,0x3
    80005cf4:	ef850513          	addi	a0,a0,-264 # 80008be8 <syscalls+0x2a0>
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	846080e7          	jalr	-1978(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005d00:	04a95783          	lhu	a5,74(s2)
    80005d04:	2785                	addiw	a5,a5,1
    80005d06:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005d0a:	854a                	mv	a0,s2
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	4fa080e7          	jalr	1274(ra) # 80004206 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d14:	40d0                	lw	a2,4(s1)
    80005d16:	00003597          	auipc	a1,0x3
    80005d1a:	ee258593          	addi	a1,a1,-286 # 80008bf8 <syscalls+0x2b0>
    80005d1e:	8526                	mv	a0,s1
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	ca4080e7          	jalr	-860(ra) # 800049c4 <dirlink>
    80005d28:	00054f63          	bltz	a0,80005d46 <create+0x144>
    80005d2c:	00492603          	lw	a2,4(s2)
    80005d30:	00003597          	auipc	a1,0x3
    80005d34:	ed058593          	addi	a1,a1,-304 # 80008c00 <syscalls+0x2b8>
    80005d38:	8526                	mv	a0,s1
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	c8a080e7          	jalr	-886(ra) # 800049c4 <dirlink>
    80005d42:	f80557e3          	bgez	a0,80005cd0 <create+0xce>
      panic("create dots");
    80005d46:	00003517          	auipc	a0,0x3
    80005d4a:	ec250513          	addi	a0,a0,-318 # 80008c08 <syscalls+0x2c0>
    80005d4e:	ffffa097          	auipc	ra,0xffffa
    80005d52:	7f0080e7          	jalr	2032(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005d56:	00003517          	auipc	a0,0x3
    80005d5a:	ec250513          	addi	a0,a0,-318 # 80008c18 <syscalls+0x2d0>
    80005d5e:	ffffa097          	auipc	ra,0xffffa
    80005d62:	7e0080e7          	jalr	2016(ra) # 8000053e <panic>
    return 0;
    80005d66:	84aa                	mv	s1,a0
    80005d68:	b731                	j	80005c74 <create+0x72>

0000000080005d6a <sys_dup>:
{
    80005d6a:	7179                	addi	sp,sp,-48
    80005d6c:	f406                	sd	ra,40(sp)
    80005d6e:	f022                	sd	s0,32(sp)
    80005d70:	ec26                	sd	s1,24(sp)
    80005d72:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d74:	fd840613          	addi	a2,s0,-40
    80005d78:	4581                	li	a1,0
    80005d7a:	4501                	li	a0,0
    80005d7c:	00000097          	auipc	ra,0x0
    80005d80:	ddc080e7          	jalr	-548(ra) # 80005b58 <argfd>
    return -1;
    80005d84:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d86:	02054363          	bltz	a0,80005dac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005d8a:	fd843503          	ld	a0,-40(s0)
    80005d8e:	00000097          	auipc	ra,0x0
    80005d92:	e32080e7          	jalr	-462(ra) # 80005bc0 <fdalloc>
    80005d96:	84aa                	mv	s1,a0
    return -1;
    80005d98:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d9a:	00054963          	bltz	a0,80005dac <sys_dup+0x42>
  filedup(f);
    80005d9e:	fd843503          	ld	a0,-40(s0)
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	37a080e7          	jalr	890(ra) # 8000511c <filedup>
  return fd;
    80005daa:	87a6                	mv	a5,s1
}
    80005dac:	853e                	mv	a0,a5
    80005dae:	70a2                	ld	ra,40(sp)
    80005db0:	7402                	ld	s0,32(sp)
    80005db2:	64e2                	ld	s1,24(sp)
    80005db4:	6145                	addi	sp,sp,48
    80005db6:	8082                	ret

0000000080005db8 <sys_read>:
{
    80005db8:	7179                	addi	sp,sp,-48
    80005dba:	f406                	sd	ra,40(sp)
    80005dbc:	f022                	sd	s0,32(sp)
    80005dbe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dc0:	fe840613          	addi	a2,s0,-24
    80005dc4:	4581                	li	a1,0
    80005dc6:	4501                	li	a0,0
    80005dc8:	00000097          	auipc	ra,0x0
    80005dcc:	d90080e7          	jalr	-624(ra) # 80005b58 <argfd>
    return -1;
    80005dd0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dd2:	04054163          	bltz	a0,80005e14 <sys_read+0x5c>
    80005dd6:	fe440593          	addi	a1,s0,-28
    80005dda:	4509                	li	a0,2
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	982080e7          	jalr	-1662(ra) # 8000375e <argint>
    return -1;
    80005de4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005de6:	02054763          	bltz	a0,80005e14 <sys_read+0x5c>
    80005dea:	fd840593          	addi	a1,s0,-40
    80005dee:	4505                	li	a0,1
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	990080e7          	jalr	-1648(ra) # 80003780 <argaddr>
    return -1;
    80005df8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dfa:	00054d63          	bltz	a0,80005e14 <sys_read+0x5c>
  return fileread(f, p, n);
    80005dfe:	fe442603          	lw	a2,-28(s0)
    80005e02:	fd843583          	ld	a1,-40(s0)
    80005e06:	fe843503          	ld	a0,-24(s0)
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	49e080e7          	jalr	1182(ra) # 800052a8 <fileread>
    80005e12:	87aa                	mv	a5,a0
}
    80005e14:	853e                	mv	a0,a5
    80005e16:	70a2                	ld	ra,40(sp)
    80005e18:	7402                	ld	s0,32(sp)
    80005e1a:	6145                	addi	sp,sp,48
    80005e1c:	8082                	ret

0000000080005e1e <sys_write>:
{
    80005e1e:	7179                	addi	sp,sp,-48
    80005e20:	f406                	sd	ra,40(sp)
    80005e22:	f022                	sd	s0,32(sp)
    80005e24:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e26:	fe840613          	addi	a2,s0,-24
    80005e2a:	4581                	li	a1,0
    80005e2c:	4501                	li	a0,0
    80005e2e:	00000097          	auipc	ra,0x0
    80005e32:	d2a080e7          	jalr	-726(ra) # 80005b58 <argfd>
    return -1;
    80005e36:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e38:	04054163          	bltz	a0,80005e7a <sys_write+0x5c>
    80005e3c:	fe440593          	addi	a1,s0,-28
    80005e40:	4509                	li	a0,2
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	91c080e7          	jalr	-1764(ra) # 8000375e <argint>
    return -1;
    80005e4a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e4c:	02054763          	bltz	a0,80005e7a <sys_write+0x5c>
    80005e50:	fd840593          	addi	a1,s0,-40
    80005e54:	4505                	li	a0,1
    80005e56:	ffffe097          	auipc	ra,0xffffe
    80005e5a:	92a080e7          	jalr	-1750(ra) # 80003780 <argaddr>
    return -1;
    80005e5e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e60:	00054d63          	bltz	a0,80005e7a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005e64:	fe442603          	lw	a2,-28(s0)
    80005e68:	fd843583          	ld	a1,-40(s0)
    80005e6c:	fe843503          	ld	a0,-24(s0)
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	4fa080e7          	jalr	1274(ra) # 8000536a <filewrite>
    80005e78:	87aa                	mv	a5,a0
}
    80005e7a:	853e                	mv	a0,a5
    80005e7c:	70a2                	ld	ra,40(sp)
    80005e7e:	7402                	ld	s0,32(sp)
    80005e80:	6145                	addi	sp,sp,48
    80005e82:	8082                	ret

0000000080005e84 <sys_close>:
{
    80005e84:	1101                	addi	sp,sp,-32
    80005e86:	ec06                	sd	ra,24(sp)
    80005e88:	e822                	sd	s0,16(sp)
    80005e8a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e8c:	fe040613          	addi	a2,s0,-32
    80005e90:	fec40593          	addi	a1,s0,-20
    80005e94:	4501                	li	a0,0
    80005e96:	00000097          	auipc	ra,0x0
    80005e9a:	cc2080e7          	jalr	-830(ra) # 80005b58 <argfd>
    return -1;
    80005e9e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ea0:	02054463          	bltz	a0,80005ec8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ea4:	ffffc097          	auipc	ra,0xffffc
    80005ea8:	458080e7          	jalr	1112(ra) # 800022fc <myproc>
    80005eac:	fec42783          	lw	a5,-20(s0)
    80005eb0:	07e9                	addi	a5,a5,26
    80005eb2:	078e                	slli	a5,a5,0x3
    80005eb4:	97aa                	add	a5,a5,a0
    80005eb6:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005eba:	fe043503          	ld	a0,-32(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	2b0080e7          	jalr	688(ra) # 8000516e <fileclose>
  return 0;
    80005ec6:	4781                	li	a5,0
}
    80005ec8:	853e                	mv	a0,a5
    80005eca:	60e2                	ld	ra,24(sp)
    80005ecc:	6442                	ld	s0,16(sp)
    80005ece:	6105                	addi	sp,sp,32
    80005ed0:	8082                	ret

0000000080005ed2 <sys_fstat>:
{
    80005ed2:	1101                	addi	sp,sp,-32
    80005ed4:	ec06                	sd	ra,24(sp)
    80005ed6:	e822                	sd	s0,16(sp)
    80005ed8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005eda:	fe840613          	addi	a2,s0,-24
    80005ede:	4581                	li	a1,0
    80005ee0:	4501                	li	a0,0
    80005ee2:	00000097          	auipc	ra,0x0
    80005ee6:	c76080e7          	jalr	-906(ra) # 80005b58 <argfd>
    return -1;
    80005eea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005eec:	02054563          	bltz	a0,80005f16 <sys_fstat+0x44>
    80005ef0:	fe040593          	addi	a1,s0,-32
    80005ef4:	4505                	li	a0,1
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	88a080e7          	jalr	-1910(ra) # 80003780 <argaddr>
    return -1;
    80005efe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f00:	00054b63          	bltz	a0,80005f16 <sys_fstat+0x44>
  return filestat(f, st);
    80005f04:	fe043583          	ld	a1,-32(s0)
    80005f08:	fe843503          	ld	a0,-24(s0)
    80005f0c:	fffff097          	auipc	ra,0xfffff
    80005f10:	32a080e7          	jalr	810(ra) # 80005236 <filestat>
    80005f14:	87aa                	mv	a5,a0
}
    80005f16:	853e                	mv	a0,a5
    80005f18:	60e2                	ld	ra,24(sp)
    80005f1a:	6442                	ld	s0,16(sp)
    80005f1c:	6105                	addi	sp,sp,32
    80005f1e:	8082                	ret

0000000080005f20 <sys_link>:
{
    80005f20:	7169                	addi	sp,sp,-304
    80005f22:	f606                	sd	ra,296(sp)
    80005f24:	f222                	sd	s0,288(sp)
    80005f26:	ee26                	sd	s1,280(sp)
    80005f28:	ea4a                	sd	s2,272(sp)
    80005f2a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f2c:	08000613          	li	a2,128
    80005f30:	ed040593          	addi	a1,s0,-304
    80005f34:	4501                	li	a0,0
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	86c080e7          	jalr	-1940(ra) # 800037a2 <argstr>
    return -1;
    80005f3e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f40:	10054e63          	bltz	a0,8000605c <sys_link+0x13c>
    80005f44:	08000613          	li	a2,128
    80005f48:	f5040593          	addi	a1,s0,-176
    80005f4c:	4505                	li	a0,1
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	854080e7          	jalr	-1964(ra) # 800037a2 <argstr>
    return -1;
    80005f56:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f58:	10054263          	bltz	a0,8000605c <sys_link+0x13c>
  begin_op();
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	d46080e7          	jalr	-698(ra) # 80004ca2 <begin_op>
  if((ip = namei(old)) == 0){
    80005f64:	ed040513          	addi	a0,s0,-304
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	b1e080e7          	jalr	-1250(ra) # 80004a86 <namei>
    80005f70:	84aa                	mv	s1,a0
    80005f72:	c551                	beqz	a0,80005ffe <sys_link+0xde>
  ilock(ip);
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	35c080e7          	jalr	860(ra) # 800042d0 <ilock>
  if(ip->type == T_DIR){
    80005f7c:	04449703          	lh	a4,68(s1)
    80005f80:	4785                	li	a5,1
    80005f82:	08f70463          	beq	a4,a5,8000600a <sys_link+0xea>
  ip->nlink++;
    80005f86:	04a4d783          	lhu	a5,74(s1)
    80005f8a:	2785                	addiw	a5,a5,1
    80005f8c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f90:	8526                	mv	a0,s1
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	274080e7          	jalr	628(ra) # 80004206 <iupdate>
  iunlock(ip);
    80005f9a:	8526                	mv	a0,s1
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	3f6080e7          	jalr	1014(ra) # 80004392 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005fa4:	fd040593          	addi	a1,s0,-48
    80005fa8:	f5040513          	addi	a0,s0,-176
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	af8080e7          	jalr	-1288(ra) # 80004aa4 <nameiparent>
    80005fb4:	892a                	mv	s2,a0
    80005fb6:	c935                	beqz	a0,8000602a <sys_link+0x10a>
  ilock(dp);
    80005fb8:	ffffe097          	auipc	ra,0xffffe
    80005fbc:	318080e7          	jalr	792(ra) # 800042d0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005fc0:	00092703          	lw	a4,0(s2)
    80005fc4:	409c                	lw	a5,0(s1)
    80005fc6:	04f71d63          	bne	a4,a5,80006020 <sys_link+0x100>
    80005fca:	40d0                	lw	a2,4(s1)
    80005fcc:	fd040593          	addi	a1,s0,-48
    80005fd0:	854a                	mv	a0,s2
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	9f2080e7          	jalr	-1550(ra) # 800049c4 <dirlink>
    80005fda:	04054363          	bltz	a0,80006020 <sys_link+0x100>
  iunlockput(dp);
    80005fde:	854a                	mv	a0,s2
    80005fe0:	ffffe097          	auipc	ra,0xffffe
    80005fe4:	552080e7          	jalr	1362(ra) # 80004532 <iunlockput>
  iput(ip);
    80005fe8:	8526                	mv	a0,s1
    80005fea:	ffffe097          	auipc	ra,0xffffe
    80005fee:	4a0080e7          	jalr	1184(ra) # 8000448a <iput>
  end_op();
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	d30080e7          	jalr	-720(ra) # 80004d22 <end_op>
  return 0;
    80005ffa:	4781                	li	a5,0
    80005ffc:	a085                	j	8000605c <sys_link+0x13c>
    end_op();
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	d24080e7          	jalr	-732(ra) # 80004d22 <end_op>
    return -1;
    80006006:	57fd                	li	a5,-1
    80006008:	a891                	j	8000605c <sys_link+0x13c>
    iunlockput(ip);
    8000600a:	8526                	mv	a0,s1
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	526080e7          	jalr	1318(ra) # 80004532 <iunlockput>
    end_op();
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	d0e080e7          	jalr	-754(ra) # 80004d22 <end_op>
    return -1;
    8000601c:	57fd                	li	a5,-1
    8000601e:	a83d                	j	8000605c <sys_link+0x13c>
    iunlockput(dp);
    80006020:	854a                	mv	a0,s2
    80006022:	ffffe097          	auipc	ra,0xffffe
    80006026:	510080e7          	jalr	1296(ra) # 80004532 <iunlockput>
  ilock(ip);
    8000602a:	8526                	mv	a0,s1
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	2a4080e7          	jalr	676(ra) # 800042d0 <ilock>
  ip->nlink--;
    80006034:	04a4d783          	lhu	a5,74(s1)
    80006038:	37fd                	addiw	a5,a5,-1
    8000603a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000603e:	8526                	mv	a0,s1
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	1c6080e7          	jalr	454(ra) # 80004206 <iupdate>
  iunlockput(ip);
    80006048:	8526                	mv	a0,s1
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	4e8080e7          	jalr	1256(ra) # 80004532 <iunlockput>
  end_op();
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	cd0080e7          	jalr	-816(ra) # 80004d22 <end_op>
  return -1;
    8000605a:	57fd                	li	a5,-1
}
    8000605c:	853e                	mv	a0,a5
    8000605e:	70b2                	ld	ra,296(sp)
    80006060:	7412                	ld	s0,288(sp)
    80006062:	64f2                	ld	s1,280(sp)
    80006064:	6952                	ld	s2,272(sp)
    80006066:	6155                	addi	sp,sp,304
    80006068:	8082                	ret

000000008000606a <sys_unlink>:
{
    8000606a:	7151                	addi	sp,sp,-240
    8000606c:	f586                	sd	ra,232(sp)
    8000606e:	f1a2                	sd	s0,224(sp)
    80006070:	eda6                	sd	s1,216(sp)
    80006072:	e9ca                	sd	s2,208(sp)
    80006074:	e5ce                	sd	s3,200(sp)
    80006076:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006078:	08000613          	li	a2,128
    8000607c:	f3040593          	addi	a1,s0,-208
    80006080:	4501                	li	a0,0
    80006082:	ffffd097          	auipc	ra,0xffffd
    80006086:	720080e7          	jalr	1824(ra) # 800037a2 <argstr>
    8000608a:	18054163          	bltz	a0,8000620c <sys_unlink+0x1a2>
  begin_op();
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	c14080e7          	jalr	-1004(ra) # 80004ca2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006096:	fb040593          	addi	a1,s0,-80
    8000609a:	f3040513          	addi	a0,s0,-208
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	a06080e7          	jalr	-1530(ra) # 80004aa4 <nameiparent>
    800060a6:	84aa                	mv	s1,a0
    800060a8:	c979                	beqz	a0,8000617e <sys_unlink+0x114>
  ilock(dp);
    800060aa:	ffffe097          	auipc	ra,0xffffe
    800060ae:	226080e7          	jalr	550(ra) # 800042d0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800060b2:	00003597          	auipc	a1,0x3
    800060b6:	b4658593          	addi	a1,a1,-1210 # 80008bf8 <syscalls+0x2b0>
    800060ba:	fb040513          	addi	a0,s0,-80
    800060be:	ffffe097          	auipc	ra,0xffffe
    800060c2:	6dc080e7          	jalr	1756(ra) # 8000479a <namecmp>
    800060c6:	14050a63          	beqz	a0,8000621a <sys_unlink+0x1b0>
    800060ca:	00003597          	auipc	a1,0x3
    800060ce:	b3658593          	addi	a1,a1,-1226 # 80008c00 <syscalls+0x2b8>
    800060d2:	fb040513          	addi	a0,s0,-80
    800060d6:	ffffe097          	auipc	ra,0xffffe
    800060da:	6c4080e7          	jalr	1732(ra) # 8000479a <namecmp>
    800060de:	12050e63          	beqz	a0,8000621a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800060e2:	f2c40613          	addi	a2,s0,-212
    800060e6:	fb040593          	addi	a1,s0,-80
    800060ea:	8526                	mv	a0,s1
    800060ec:	ffffe097          	auipc	ra,0xffffe
    800060f0:	6c8080e7          	jalr	1736(ra) # 800047b4 <dirlookup>
    800060f4:	892a                	mv	s2,a0
    800060f6:	12050263          	beqz	a0,8000621a <sys_unlink+0x1b0>
  ilock(ip);
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	1d6080e7          	jalr	470(ra) # 800042d0 <ilock>
  if(ip->nlink < 1)
    80006102:	04a91783          	lh	a5,74(s2)
    80006106:	08f05263          	blez	a5,8000618a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000610a:	04491703          	lh	a4,68(s2)
    8000610e:	4785                	li	a5,1
    80006110:	08f70563          	beq	a4,a5,8000619a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006114:	4641                	li	a2,16
    80006116:	4581                	li	a1,0
    80006118:	fc040513          	addi	a0,s0,-64
    8000611c:	ffffb097          	auipc	ra,0xffffb
    80006120:	be8080e7          	jalr	-1048(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006124:	4741                	li	a4,16
    80006126:	f2c42683          	lw	a3,-212(s0)
    8000612a:	fc040613          	addi	a2,s0,-64
    8000612e:	4581                	li	a1,0
    80006130:	8526                	mv	a0,s1
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	54a080e7          	jalr	1354(ra) # 8000467c <writei>
    8000613a:	47c1                	li	a5,16
    8000613c:	0af51563          	bne	a0,a5,800061e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006140:	04491703          	lh	a4,68(s2)
    80006144:	4785                	li	a5,1
    80006146:	0af70863          	beq	a4,a5,800061f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000614a:	8526                	mv	a0,s1
    8000614c:	ffffe097          	auipc	ra,0xffffe
    80006150:	3e6080e7          	jalr	998(ra) # 80004532 <iunlockput>
  ip->nlink--;
    80006154:	04a95783          	lhu	a5,74(s2)
    80006158:	37fd                	addiw	a5,a5,-1
    8000615a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000615e:	854a                	mv	a0,s2
    80006160:	ffffe097          	auipc	ra,0xffffe
    80006164:	0a6080e7          	jalr	166(ra) # 80004206 <iupdate>
  iunlockput(ip);
    80006168:	854a                	mv	a0,s2
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	3c8080e7          	jalr	968(ra) # 80004532 <iunlockput>
  end_op();
    80006172:	fffff097          	auipc	ra,0xfffff
    80006176:	bb0080e7          	jalr	-1104(ra) # 80004d22 <end_op>
  return 0;
    8000617a:	4501                	li	a0,0
    8000617c:	a84d                	j	8000622e <sys_unlink+0x1c4>
    end_op();
    8000617e:	fffff097          	auipc	ra,0xfffff
    80006182:	ba4080e7          	jalr	-1116(ra) # 80004d22 <end_op>
    return -1;
    80006186:	557d                	li	a0,-1
    80006188:	a05d                	j	8000622e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000618a:	00003517          	auipc	a0,0x3
    8000618e:	a9e50513          	addi	a0,a0,-1378 # 80008c28 <syscalls+0x2e0>
    80006192:	ffffa097          	auipc	ra,0xffffa
    80006196:	3ac080e7          	jalr	940(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000619a:	04c92703          	lw	a4,76(s2)
    8000619e:	02000793          	li	a5,32
    800061a2:	f6e7f9e3          	bgeu	a5,a4,80006114 <sys_unlink+0xaa>
    800061a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061aa:	4741                	li	a4,16
    800061ac:	86ce                	mv	a3,s3
    800061ae:	f1840613          	addi	a2,s0,-232
    800061b2:	4581                	li	a1,0
    800061b4:	854a                	mv	a0,s2
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	3ce080e7          	jalr	974(ra) # 80004584 <readi>
    800061be:	47c1                	li	a5,16
    800061c0:	00f51b63          	bne	a0,a5,800061d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800061c4:	f1845783          	lhu	a5,-232(s0)
    800061c8:	e7a1                	bnez	a5,80006210 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061ca:	29c1                	addiw	s3,s3,16
    800061cc:	04c92783          	lw	a5,76(s2)
    800061d0:	fcf9ede3          	bltu	s3,a5,800061aa <sys_unlink+0x140>
    800061d4:	b781                	j	80006114 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800061d6:	00003517          	auipc	a0,0x3
    800061da:	a6a50513          	addi	a0,a0,-1430 # 80008c40 <syscalls+0x2f8>
    800061de:	ffffa097          	auipc	ra,0xffffa
    800061e2:	360080e7          	jalr	864(ra) # 8000053e <panic>
    panic("unlink: writei");
    800061e6:	00003517          	auipc	a0,0x3
    800061ea:	a7250513          	addi	a0,a0,-1422 # 80008c58 <syscalls+0x310>
    800061ee:	ffffa097          	auipc	ra,0xffffa
    800061f2:	350080e7          	jalr	848(ra) # 8000053e <panic>
    dp->nlink--;
    800061f6:	04a4d783          	lhu	a5,74(s1)
    800061fa:	37fd                	addiw	a5,a5,-1
    800061fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006200:	8526                	mv	a0,s1
    80006202:	ffffe097          	auipc	ra,0xffffe
    80006206:	004080e7          	jalr	4(ra) # 80004206 <iupdate>
    8000620a:	b781                	j	8000614a <sys_unlink+0xe0>
    return -1;
    8000620c:	557d                	li	a0,-1
    8000620e:	a005                	j	8000622e <sys_unlink+0x1c4>
    iunlockput(ip);
    80006210:	854a                	mv	a0,s2
    80006212:	ffffe097          	auipc	ra,0xffffe
    80006216:	320080e7          	jalr	800(ra) # 80004532 <iunlockput>
  iunlockput(dp);
    8000621a:	8526                	mv	a0,s1
    8000621c:	ffffe097          	auipc	ra,0xffffe
    80006220:	316080e7          	jalr	790(ra) # 80004532 <iunlockput>
  end_op();
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	afe080e7          	jalr	-1282(ra) # 80004d22 <end_op>
  return -1;
    8000622c:	557d                	li	a0,-1
}
    8000622e:	70ae                	ld	ra,232(sp)
    80006230:	740e                	ld	s0,224(sp)
    80006232:	64ee                	ld	s1,216(sp)
    80006234:	694e                	ld	s2,208(sp)
    80006236:	69ae                	ld	s3,200(sp)
    80006238:	616d                	addi	sp,sp,240
    8000623a:	8082                	ret

000000008000623c <sys_open>:

uint64
sys_open(void)
{
    8000623c:	7131                	addi	sp,sp,-192
    8000623e:	fd06                	sd	ra,184(sp)
    80006240:	f922                	sd	s0,176(sp)
    80006242:	f526                	sd	s1,168(sp)
    80006244:	f14a                	sd	s2,160(sp)
    80006246:	ed4e                	sd	s3,152(sp)
    80006248:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000624a:	08000613          	li	a2,128
    8000624e:	f5040593          	addi	a1,s0,-176
    80006252:	4501                	li	a0,0
    80006254:	ffffd097          	auipc	ra,0xffffd
    80006258:	54e080e7          	jalr	1358(ra) # 800037a2 <argstr>
    return -1;
    8000625c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000625e:	0c054163          	bltz	a0,80006320 <sys_open+0xe4>
    80006262:	f4c40593          	addi	a1,s0,-180
    80006266:	4505                	li	a0,1
    80006268:	ffffd097          	auipc	ra,0xffffd
    8000626c:	4f6080e7          	jalr	1270(ra) # 8000375e <argint>
    80006270:	0a054863          	bltz	a0,80006320 <sys_open+0xe4>

  begin_op();
    80006274:	fffff097          	auipc	ra,0xfffff
    80006278:	a2e080e7          	jalr	-1490(ra) # 80004ca2 <begin_op>

  if(omode & O_CREATE){
    8000627c:	f4c42783          	lw	a5,-180(s0)
    80006280:	2007f793          	andi	a5,a5,512
    80006284:	cbdd                	beqz	a5,8000633a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006286:	4681                	li	a3,0
    80006288:	4601                	li	a2,0
    8000628a:	4589                	li	a1,2
    8000628c:	f5040513          	addi	a0,s0,-176
    80006290:	00000097          	auipc	ra,0x0
    80006294:	972080e7          	jalr	-1678(ra) # 80005c02 <create>
    80006298:	892a                	mv	s2,a0
    if(ip == 0){
    8000629a:	c959                	beqz	a0,80006330 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000629c:	04491703          	lh	a4,68(s2)
    800062a0:	478d                	li	a5,3
    800062a2:	00f71763          	bne	a4,a5,800062b0 <sys_open+0x74>
    800062a6:	04695703          	lhu	a4,70(s2)
    800062aa:	47a5                	li	a5,9
    800062ac:	0ce7ec63          	bltu	a5,a4,80006384 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800062b0:	fffff097          	auipc	ra,0xfffff
    800062b4:	e02080e7          	jalr	-510(ra) # 800050b2 <filealloc>
    800062b8:	89aa                	mv	s3,a0
    800062ba:	10050263          	beqz	a0,800063be <sys_open+0x182>
    800062be:	00000097          	auipc	ra,0x0
    800062c2:	902080e7          	jalr	-1790(ra) # 80005bc0 <fdalloc>
    800062c6:	84aa                	mv	s1,a0
    800062c8:	0e054663          	bltz	a0,800063b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800062cc:	04491703          	lh	a4,68(s2)
    800062d0:	478d                	li	a5,3
    800062d2:	0cf70463          	beq	a4,a5,8000639a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062d6:	4789                	li	a5,2
    800062d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800062dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800062e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800062e4:	f4c42783          	lw	a5,-180(s0)
    800062e8:	0017c713          	xori	a4,a5,1
    800062ec:	8b05                	andi	a4,a4,1
    800062ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800062f2:	0037f713          	andi	a4,a5,3
    800062f6:	00e03733          	snez	a4,a4
    800062fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800062fe:	4007f793          	andi	a5,a5,1024
    80006302:	c791                	beqz	a5,8000630e <sys_open+0xd2>
    80006304:	04491703          	lh	a4,68(s2)
    80006308:	4789                	li	a5,2
    8000630a:	08f70f63          	beq	a4,a5,800063a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000630e:	854a                	mv	a0,s2
    80006310:	ffffe097          	auipc	ra,0xffffe
    80006314:	082080e7          	jalr	130(ra) # 80004392 <iunlock>
  end_op();
    80006318:	fffff097          	auipc	ra,0xfffff
    8000631c:	a0a080e7          	jalr	-1526(ra) # 80004d22 <end_op>

  return fd;
}
    80006320:	8526                	mv	a0,s1
    80006322:	70ea                	ld	ra,184(sp)
    80006324:	744a                	ld	s0,176(sp)
    80006326:	74aa                	ld	s1,168(sp)
    80006328:	790a                	ld	s2,160(sp)
    8000632a:	69ea                	ld	s3,152(sp)
    8000632c:	6129                	addi	sp,sp,192
    8000632e:	8082                	ret
      end_op();
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	9f2080e7          	jalr	-1550(ra) # 80004d22 <end_op>
      return -1;
    80006338:	b7e5                	j	80006320 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000633a:	f5040513          	addi	a0,s0,-176
    8000633e:	ffffe097          	auipc	ra,0xffffe
    80006342:	748080e7          	jalr	1864(ra) # 80004a86 <namei>
    80006346:	892a                	mv	s2,a0
    80006348:	c905                	beqz	a0,80006378 <sys_open+0x13c>
    ilock(ip);
    8000634a:	ffffe097          	auipc	ra,0xffffe
    8000634e:	f86080e7          	jalr	-122(ra) # 800042d0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006352:	04491703          	lh	a4,68(s2)
    80006356:	4785                	li	a5,1
    80006358:	f4f712e3          	bne	a4,a5,8000629c <sys_open+0x60>
    8000635c:	f4c42783          	lw	a5,-180(s0)
    80006360:	dba1                	beqz	a5,800062b0 <sys_open+0x74>
      iunlockput(ip);
    80006362:	854a                	mv	a0,s2
    80006364:	ffffe097          	auipc	ra,0xffffe
    80006368:	1ce080e7          	jalr	462(ra) # 80004532 <iunlockput>
      end_op();
    8000636c:	fffff097          	auipc	ra,0xfffff
    80006370:	9b6080e7          	jalr	-1610(ra) # 80004d22 <end_op>
      return -1;
    80006374:	54fd                	li	s1,-1
    80006376:	b76d                	j	80006320 <sys_open+0xe4>
      end_op();
    80006378:	fffff097          	auipc	ra,0xfffff
    8000637c:	9aa080e7          	jalr	-1622(ra) # 80004d22 <end_op>
      return -1;
    80006380:	54fd                	li	s1,-1
    80006382:	bf79                	j	80006320 <sys_open+0xe4>
    iunlockput(ip);
    80006384:	854a                	mv	a0,s2
    80006386:	ffffe097          	auipc	ra,0xffffe
    8000638a:	1ac080e7          	jalr	428(ra) # 80004532 <iunlockput>
    end_op();
    8000638e:	fffff097          	auipc	ra,0xfffff
    80006392:	994080e7          	jalr	-1644(ra) # 80004d22 <end_op>
    return -1;
    80006396:	54fd                	li	s1,-1
    80006398:	b761                	j	80006320 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000639a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000639e:	04691783          	lh	a5,70(s2)
    800063a2:	02f99223          	sh	a5,36(s3)
    800063a6:	bf2d                	j	800062e0 <sys_open+0xa4>
    itrunc(ip);
    800063a8:	854a                	mv	a0,s2
    800063aa:	ffffe097          	auipc	ra,0xffffe
    800063ae:	034080e7          	jalr	52(ra) # 800043de <itrunc>
    800063b2:	bfb1                	j	8000630e <sys_open+0xd2>
      fileclose(f);
    800063b4:	854e                	mv	a0,s3
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	db8080e7          	jalr	-584(ra) # 8000516e <fileclose>
    iunlockput(ip);
    800063be:	854a                	mv	a0,s2
    800063c0:	ffffe097          	auipc	ra,0xffffe
    800063c4:	172080e7          	jalr	370(ra) # 80004532 <iunlockput>
    end_op();
    800063c8:	fffff097          	auipc	ra,0xfffff
    800063cc:	95a080e7          	jalr	-1702(ra) # 80004d22 <end_op>
    return -1;
    800063d0:	54fd                	li	s1,-1
    800063d2:	b7b9                	j	80006320 <sys_open+0xe4>

00000000800063d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063d4:	7175                	addi	sp,sp,-144
    800063d6:	e506                	sd	ra,136(sp)
    800063d8:	e122                	sd	s0,128(sp)
    800063da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800063dc:	fffff097          	auipc	ra,0xfffff
    800063e0:	8c6080e7          	jalr	-1850(ra) # 80004ca2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800063e4:	08000613          	li	a2,128
    800063e8:	f7040593          	addi	a1,s0,-144
    800063ec:	4501                	li	a0,0
    800063ee:	ffffd097          	auipc	ra,0xffffd
    800063f2:	3b4080e7          	jalr	948(ra) # 800037a2 <argstr>
    800063f6:	02054963          	bltz	a0,80006428 <sys_mkdir+0x54>
    800063fa:	4681                	li	a3,0
    800063fc:	4601                	li	a2,0
    800063fe:	4585                	li	a1,1
    80006400:	f7040513          	addi	a0,s0,-144
    80006404:	fffff097          	auipc	ra,0xfffff
    80006408:	7fe080e7          	jalr	2046(ra) # 80005c02 <create>
    8000640c:	cd11                	beqz	a0,80006428 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000640e:	ffffe097          	auipc	ra,0xffffe
    80006412:	124080e7          	jalr	292(ra) # 80004532 <iunlockput>
  end_op();
    80006416:	fffff097          	auipc	ra,0xfffff
    8000641a:	90c080e7          	jalr	-1780(ra) # 80004d22 <end_op>
  return 0;
    8000641e:	4501                	li	a0,0
}
    80006420:	60aa                	ld	ra,136(sp)
    80006422:	640a                	ld	s0,128(sp)
    80006424:	6149                	addi	sp,sp,144
    80006426:	8082                	ret
    end_op();
    80006428:	fffff097          	auipc	ra,0xfffff
    8000642c:	8fa080e7          	jalr	-1798(ra) # 80004d22 <end_op>
    return -1;
    80006430:	557d                	li	a0,-1
    80006432:	b7fd                	j	80006420 <sys_mkdir+0x4c>

0000000080006434 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006434:	7135                	addi	sp,sp,-160
    80006436:	ed06                	sd	ra,152(sp)
    80006438:	e922                	sd	s0,144(sp)
    8000643a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000643c:	fffff097          	auipc	ra,0xfffff
    80006440:	866080e7          	jalr	-1946(ra) # 80004ca2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006444:	08000613          	li	a2,128
    80006448:	f7040593          	addi	a1,s0,-144
    8000644c:	4501                	li	a0,0
    8000644e:	ffffd097          	auipc	ra,0xffffd
    80006452:	354080e7          	jalr	852(ra) # 800037a2 <argstr>
    80006456:	04054a63          	bltz	a0,800064aa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000645a:	f6c40593          	addi	a1,s0,-148
    8000645e:	4505                	li	a0,1
    80006460:	ffffd097          	auipc	ra,0xffffd
    80006464:	2fe080e7          	jalr	766(ra) # 8000375e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006468:	04054163          	bltz	a0,800064aa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000646c:	f6840593          	addi	a1,s0,-152
    80006470:	4509                	li	a0,2
    80006472:	ffffd097          	auipc	ra,0xffffd
    80006476:	2ec080e7          	jalr	748(ra) # 8000375e <argint>
     argint(1, &major) < 0 ||
    8000647a:	02054863          	bltz	a0,800064aa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000647e:	f6841683          	lh	a3,-152(s0)
    80006482:	f6c41603          	lh	a2,-148(s0)
    80006486:	458d                	li	a1,3
    80006488:	f7040513          	addi	a0,s0,-144
    8000648c:	fffff097          	auipc	ra,0xfffff
    80006490:	776080e7          	jalr	1910(ra) # 80005c02 <create>
     argint(2, &minor) < 0 ||
    80006494:	c919                	beqz	a0,800064aa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006496:	ffffe097          	auipc	ra,0xffffe
    8000649a:	09c080e7          	jalr	156(ra) # 80004532 <iunlockput>
  end_op();
    8000649e:	fffff097          	auipc	ra,0xfffff
    800064a2:	884080e7          	jalr	-1916(ra) # 80004d22 <end_op>
  return 0;
    800064a6:	4501                	li	a0,0
    800064a8:	a031                	j	800064b4 <sys_mknod+0x80>
    end_op();
    800064aa:	fffff097          	auipc	ra,0xfffff
    800064ae:	878080e7          	jalr	-1928(ra) # 80004d22 <end_op>
    return -1;
    800064b2:	557d                	li	a0,-1
}
    800064b4:	60ea                	ld	ra,152(sp)
    800064b6:	644a                	ld	s0,144(sp)
    800064b8:	610d                	addi	sp,sp,160
    800064ba:	8082                	ret

00000000800064bc <sys_chdir>:

uint64
sys_chdir(void)
{
    800064bc:	7135                	addi	sp,sp,-160
    800064be:	ed06                	sd	ra,152(sp)
    800064c0:	e922                	sd	s0,144(sp)
    800064c2:	e526                	sd	s1,136(sp)
    800064c4:	e14a                	sd	s2,128(sp)
    800064c6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800064c8:	ffffc097          	auipc	ra,0xffffc
    800064cc:	e34080e7          	jalr	-460(ra) # 800022fc <myproc>
    800064d0:	892a                	mv	s2,a0
  
  begin_op();
    800064d2:	ffffe097          	auipc	ra,0xffffe
    800064d6:	7d0080e7          	jalr	2000(ra) # 80004ca2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064da:	08000613          	li	a2,128
    800064de:	f6040593          	addi	a1,s0,-160
    800064e2:	4501                	li	a0,0
    800064e4:	ffffd097          	auipc	ra,0xffffd
    800064e8:	2be080e7          	jalr	702(ra) # 800037a2 <argstr>
    800064ec:	04054b63          	bltz	a0,80006542 <sys_chdir+0x86>
    800064f0:	f6040513          	addi	a0,s0,-160
    800064f4:	ffffe097          	auipc	ra,0xffffe
    800064f8:	592080e7          	jalr	1426(ra) # 80004a86 <namei>
    800064fc:	84aa                	mv	s1,a0
    800064fe:	c131                	beqz	a0,80006542 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006500:	ffffe097          	auipc	ra,0xffffe
    80006504:	dd0080e7          	jalr	-560(ra) # 800042d0 <ilock>
  if(ip->type != T_DIR){
    80006508:	04449703          	lh	a4,68(s1)
    8000650c:	4785                	li	a5,1
    8000650e:	04f71063          	bne	a4,a5,8000654e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006512:	8526                	mv	a0,s1
    80006514:	ffffe097          	auipc	ra,0xffffe
    80006518:	e7e080e7          	jalr	-386(ra) # 80004392 <iunlock>
  iput(p->cwd);
    8000651c:	15893503          	ld	a0,344(s2)
    80006520:	ffffe097          	auipc	ra,0xffffe
    80006524:	f6a080e7          	jalr	-150(ra) # 8000448a <iput>
  end_op();
    80006528:	ffffe097          	auipc	ra,0xffffe
    8000652c:	7fa080e7          	jalr	2042(ra) # 80004d22 <end_op>
  p->cwd = ip;
    80006530:	14993c23          	sd	s1,344(s2)
  return 0;
    80006534:	4501                	li	a0,0
}
    80006536:	60ea                	ld	ra,152(sp)
    80006538:	644a                	ld	s0,144(sp)
    8000653a:	64aa                	ld	s1,136(sp)
    8000653c:	690a                	ld	s2,128(sp)
    8000653e:	610d                	addi	sp,sp,160
    80006540:	8082                	ret
    end_op();
    80006542:	ffffe097          	auipc	ra,0xffffe
    80006546:	7e0080e7          	jalr	2016(ra) # 80004d22 <end_op>
    return -1;
    8000654a:	557d                	li	a0,-1
    8000654c:	b7ed                	j	80006536 <sys_chdir+0x7a>
    iunlockput(ip);
    8000654e:	8526                	mv	a0,s1
    80006550:	ffffe097          	auipc	ra,0xffffe
    80006554:	fe2080e7          	jalr	-30(ra) # 80004532 <iunlockput>
    end_op();
    80006558:	ffffe097          	auipc	ra,0xffffe
    8000655c:	7ca080e7          	jalr	1994(ra) # 80004d22 <end_op>
    return -1;
    80006560:	557d                	li	a0,-1
    80006562:	bfd1                	j	80006536 <sys_chdir+0x7a>

0000000080006564 <sys_exec>:

uint64
sys_exec(void)
{
    80006564:	7145                	addi	sp,sp,-464
    80006566:	e786                	sd	ra,456(sp)
    80006568:	e3a2                	sd	s0,448(sp)
    8000656a:	ff26                	sd	s1,440(sp)
    8000656c:	fb4a                	sd	s2,432(sp)
    8000656e:	f74e                	sd	s3,424(sp)
    80006570:	f352                	sd	s4,416(sp)
    80006572:	ef56                	sd	s5,408(sp)
    80006574:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006576:	08000613          	li	a2,128
    8000657a:	f4040593          	addi	a1,s0,-192
    8000657e:	4501                	li	a0,0
    80006580:	ffffd097          	auipc	ra,0xffffd
    80006584:	222080e7          	jalr	546(ra) # 800037a2 <argstr>
    return -1;
    80006588:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000658a:	0c054a63          	bltz	a0,8000665e <sys_exec+0xfa>
    8000658e:	e3840593          	addi	a1,s0,-456
    80006592:	4505                	li	a0,1
    80006594:	ffffd097          	auipc	ra,0xffffd
    80006598:	1ec080e7          	jalr	492(ra) # 80003780 <argaddr>
    8000659c:	0c054163          	bltz	a0,8000665e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800065a0:	10000613          	li	a2,256
    800065a4:	4581                	li	a1,0
    800065a6:	e4040513          	addi	a0,s0,-448
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	75a080e7          	jalr	1882(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800065b2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800065b6:	89a6                	mv	s3,s1
    800065b8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800065ba:	02000a13          	li	s4,32
    800065be:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800065c2:	00391513          	slli	a0,s2,0x3
    800065c6:	e3040593          	addi	a1,s0,-464
    800065ca:	e3843783          	ld	a5,-456(s0)
    800065ce:	953e                	add	a0,a0,a5
    800065d0:	ffffd097          	auipc	ra,0xffffd
    800065d4:	0f4080e7          	jalr	244(ra) # 800036c4 <fetchaddr>
    800065d8:	02054a63          	bltz	a0,8000660c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800065dc:	e3043783          	ld	a5,-464(s0)
    800065e0:	c3b9                	beqz	a5,80006626 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800065e2:	ffffa097          	auipc	ra,0xffffa
    800065e6:	512080e7          	jalr	1298(ra) # 80000af4 <kalloc>
    800065ea:	85aa                	mv	a1,a0
    800065ec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800065f0:	cd11                	beqz	a0,8000660c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800065f2:	6605                	lui	a2,0x1
    800065f4:	e3043503          	ld	a0,-464(s0)
    800065f8:	ffffd097          	auipc	ra,0xffffd
    800065fc:	11e080e7          	jalr	286(ra) # 80003716 <fetchstr>
    80006600:	00054663          	bltz	a0,8000660c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006604:	0905                	addi	s2,s2,1
    80006606:	09a1                	addi	s3,s3,8
    80006608:	fb491be3          	bne	s2,s4,800065be <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000660c:	10048913          	addi	s2,s1,256
    80006610:	6088                	ld	a0,0(s1)
    80006612:	c529                	beqz	a0,8000665c <sys_exec+0xf8>
    kfree(argv[i]);
    80006614:	ffffa097          	auipc	ra,0xffffa
    80006618:	3e4080e7          	jalr	996(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000661c:	04a1                	addi	s1,s1,8
    8000661e:	ff2499e3          	bne	s1,s2,80006610 <sys_exec+0xac>
  return -1;
    80006622:	597d                	li	s2,-1
    80006624:	a82d                	j	8000665e <sys_exec+0xfa>
      argv[i] = 0;
    80006626:	0a8e                	slli	s5,s5,0x3
    80006628:	fc040793          	addi	a5,s0,-64
    8000662c:	9abe                	add	s5,s5,a5
    8000662e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006632:	e4040593          	addi	a1,s0,-448
    80006636:	f4040513          	addi	a0,s0,-192
    8000663a:	fffff097          	auipc	ra,0xfffff
    8000663e:	194080e7          	jalr	404(ra) # 800057ce <exec>
    80006642:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006644:	10048993          	addi	s3,s1,256
    80006648:	6088                	ld	a0,0(s1)
    8000664a:	c911                	beqz	a0,8000665e <sys_exec+0xfa>
    kfree(argv[i]);
    8000664c:	ffffa097          	auipc	ra,0xffffa
    80006650:	3ac080e7          	jalr	940(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006654:	04a1                	addi	s1,s1,8
    80006656:	ff3499e3          	bne	s1,s3,80006648 <sys_exec+0xe4>
    8000665a:	a011                	j	8000665e <sys_exec+0xfa>
  return -1;
    8000665c:	597d                	li	s2,-1
}
    8000665e:	854a                	mv	a0,s2
    80006660:	60be                	ld	ra,456(sp)
    80006662:	641e                	ld	s0,448(sp)
    80006664:	74fa                	ld	s1,440(sp)
    80006666:	795a                	ld	s2,432(sp)
    80006668:	79ba                	ld	s3,424(sp)
    8000666a:	7a1a                	ld	s4,416(sp)
    8000666c:	6afa                	ld	s5,408(sp)
    8000666e:	6179                	addi	sp,sp,464
    80006670:	8082                	ret

0000000080006672 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006672:	7139                	addi	sp,sp,-64
    80006674:	fc06                	sd	ra,56(sp)
    80006676:	f822                	sd	s0,48(sp)
    80006678:	f426                	sd	s1,40(sp)
    8000667a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000667c:	ffffc097          	auipc	ra,0xffffc
    80006680:	c80080e7          	jalr	-896(ra) # 800022fc <myproc>
    80006684:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006686:	fd840593          	addi	a1,s0,-40
    8000668a:	4501                	li	a0,0
    8000668c:	ffffd097          	auipc	ra,0xffffd
    80006690:	0f4080e7          	jalr	244(ra) # 80003780 <argaddr>
    return -1;
    80006694:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006696:	0e054063          	bltz	a0,80006776 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000669a:	fc840593          	addi	a1,s0,-56
    8000669e:	fd040513          	addi	a0,s0,-48
    800066a2:	fffff097          	auipc	ra,0xfffff
    800066a6:	dfc080e7          	jalr	-516(ra) # 8000549e <pipealloc>
    return -1;
    800066aa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800066ac:	0c054563          	bltz	a0,80006776 <sys_pipe+0x104>
  fd0 = -1;
    800066b0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800066b4:	fd043503          	ld	a0,-48(s0)
    800066b8:	fffff097          	auipc	ra,0xfffff
    800066bc:	508080e7          	jalr	1288(ra) # 80005bc0 <fdalloc>
    800066c0:	fca42223          	sw	a0,-60(s0)
    800066c4:	08054c63          	bltz	a0,8000675c <sys_pipe+0xea>
    800066c8:	fc843503          	ld	a0,-56(s0)
    800066cc:	fffff097          	auipc	ra,0xfffff
    800066d0:	4f4080e7          	jalr	1268(ra) # 80005bc0 <fdalloc>
    800066d4:	fca42023          	sw	a0,-64(s0)
    800066d8:	06054863          	bltz	a0,80006748 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066dc:	4691                	li	a3,4
    800066de:	fc440613          	addi	a2,s0,-60
    800066e2:	fd843583          	ld	a1,-40(s0)
    800066e6:	6ca8                	ld	a0,88(s1)
    800066e8:	ffffb097          	auipc	ra,0xffffb
    800066ec:	fae080e7          	jalr	-82(ra) # 80001696 <copyout>
    800066f0:	02054063          	bltz	a0,80006710 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800066f4:	4691                	li	a3,4
    800066f6:	fc040613          	addi	a2,s0,-64
    800066fa:	fd843583          	ld	a1,-40(s0)
    800066fe:	0591                	addi	a1,a1,4
    80006700:	6ca8                	ld	a0,88(s1)
    80006702:	ffffb097          	auipc	ra,0xffffb
    80006706:	f94080e7          	jalr	-108(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000670a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000670c:	06055563          	bgez	a0,80006776 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006710:	fc442783          	lw	a5,-60(s0)
    80006714:	07e9                	addi	a5,a5,26
    80006716:	078e                	slli	a5,a5,0x3
    80006718:	97a6                	add	a5,a5,s1
    8000671a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000671e:	fc042503          	lw	a0,-64(s0)
    80006722:	0569                	addi	a0,a0,26
    80006724:	050e                	slli	a0,a0,0x3
    80006726:	9526                	add	a0,a0,s1
    80006728:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000672c:	fd043503          	ld	a0,-48(s0)
    80006730:	fffff097          	auipc	ra,0xfffff
    80006734:	a3e080e7          	jalr	-1474(ra) # 8000516e <fileclose>
    fileclose(wf);
    80006738:	fc843503          	ld	a0,-56(s0)
    8000673c:	fffff097          	auipc	ra,0xfffff
    80006740:	a32080e7          	jalr	-1486(ra) # 8000516e <fileclose>
    return -1;
    80006744:	57fd                	li	a5,-1
    80006746:	a805                	j	80006776 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006748:	fc442783          	lw	a5,-60(s0)
    8000674c:	0007c863          	bltz	a5,8000675c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006750:	01a78513          	addi	a0,a5,26
    80006754:	050e                	slli	a0,a0,0x3
    80006756:	9526                	add	a0,a0,s1
    80006758:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000675c:	fd043503          	ld	a0,-48(s0)
    80006760:	fffff097          	auipc	ra,0xfffff
    80006764:	a0e080e7          	jalr	-1522(ra) # 8000516e <fileclose>
    fileclose(wf);
    80006768:	fc843503          	ld	a0,-56(s0)
    8000676c:	fffff097          	auipc	ra,0xfffff
    80006770:	a02080e7          	jalr	-1534(ra) # 8000516e <fileclose>
    return -1;
    80006774:	57fd                	li	a5,-1
}
    80006776:	853e                	mv	a0,a5
    80006778:	70e2                	ld	ra,56(sp)
    8000677a:	7442                	ld	s0,48(sp)
    8000677c:	74a2                	ld	s1,40(sp)
    8000677e:	6121                	addi	sp,sp,64
    80006780:	8082                	ret
	...

0000000080006790 <kernelvec>:
    80006790:	7111                	addi	sp,sp,-256
    80006792:	e006                	sd	ra,0(sp)
    80006794:	e40a                	sd	sp,8(sp)
    80006796:	e80e                	sd	gp,16(sp)
    80006798:	ec12                	sd	tp,24(sp)
    8000679a:	f016                	sd	t0,32(sp)
    8000679c:	f41a                	sd	t1,40(sp)
    8000679e:	f81e                	sd	t2,48(sp)
    800067a0:	fc22                	sd	s0,56(sp)
    800067a2:	e0a6                	sd	s1,64(sp)
    800067a4:	e4aa                	sd	a0,72(sp)
    800067a6:	e8ae                	sd	a1,80(sp)
    800067a8:	ecb2                	sd	a2,88(sp)
    800067aa:	f0b6                	sd	a3,96(sp)
    800067ac:	f4ba                	sd	a4,104(sp)
    800067ae:	f8be                	sd	a5,112(sp)
    800067b0:	fcc2                	sd	a6,120(sp)
    800067b2:	e146                	sd	a7,128(sp)
    800067b4:	e54a                	sd	s2,136(sp)
    800067b6:	e94e                	sd	s3,144(sp)
    800067b8:	ed52                	sd	s4,152(sp)
    800067ba:	f156                	sd	s5,160(sp)
    800067bc:	f55a                	sd	s6,168(sp)
    800067be:	f95e                	sd	s7,176(sp)
    800067c0:	fd62                	sd	s8,184(sp)
    800067c2:	e1e6                	sd	s9,192(sp)
    800067c4:	e5ea                	sd	s10,200(sp)
    800067c6:	e9ee                	sd	s11,208(sp)
    800067c8:	edf2                	sd	t3,216(sp)
    800067ca:	f1f6                	sd	t4,224(sp)
    800067cc:	f5fa                	sd	t5,232(sp)
    800067ce:	f9fe                	sd	t6,240(sp)
    800067d0:	dc1fc0ef          	jal	ra,80003590 <kerneltrap>
    800067d4:	6082                	ld	ra,0(sp)
    800067d6:	6122                	ld	sp,8(sp)
    800067d8:	61c2                	ld	gp,16(sp)
    800067da:	7282                	ld	t0,32(sp)
    800067dc:	7322                	ld	t1,40(sp)
    800067de:	73c2                	ld	t2,48(sp)
    800067e0:	7462                	ld	s0,56(sp)
    800067e2:	6486                	ld	s1,64(sp)
    800067e4:	6526                	ld	a0,72(sp)
    800067e6:	65c6                	ld	a1,80(sp)
    800067e8:	6666                	ld	a2,88(sp)
    800067ea:	7686                	ld	a3,96(sp)
    800067ec:	7726                	ld	a4,104(sp)
    800067ee:	77c6                	ld	a5,112(sp)
    800067f0:	7866                	ld	a6,120(sp)
    800067f2:	688a                	ld	a7,128(sp)
    800067f4:	692a                	ld	s2,136(sp)
    800067f6:	69ca                	ld	s3,144(sp)
    800067f8:	6a6a                	ld	s4,152(sp)
    800067fa:	7a8a                	ld	s5,160(sp)
    800067fc:	7b2a                	ld	s6,168(sp)
    800067fe:	7bca                	ld	s7,176(sp)
    80006800:	7c6a                	ld	s8,184(sp)
    80006802:	6c8e                	ld	s9,192(sp)
    80006804:	6d2e                	ld	s10,200(sp)
    80006806:	6dce                	ld	s11,208(sp)
    80006808:	6e6e                	ld	t3,216(sp)
    8000680a:	7e8e                	ld	t4,224(sp)
    8000680c:	7f2e                	ld	t5,232(sp)
    8000680e:	7fce                	ld	t6,240(sp)
    80006810:	6111                	addi	sp,sp,256
    80006812:	10200073          	sret
    80006816:	00000013          	nop
    8000681a:	00000013          	nop
    8000681e:	0001                	nop

0000000080006820 <timervec>:
    80006820:	34051573          	csrrw	a0,mscratch,a0
    80006824:	e10c                	sd	a1,0(a0)
    80006826:	e510                	sd	a2,8(a0)
    80006828:	e914                	sd	a3,16(a0)
    8000682a:	6d0c                	ld	a1,24(a0)
    8000682c:	7110                	ld	a2,32(a0)
    8000682e:	6194                	ld	a3,0(a1)
    80006830:	96b2                	add	a3,a3,a2
    80006832:	e194                	sd	a3,0(a1)
    80006834:	4589                	li	a1,2
    80006836:	14459073          	csrw	sip,a1
    8000683a:	6914                	ld	a3,16(a0)
    8000683c:	6510                	ld	a2,8(a0)
    8000683e:	610c                	ld	a1,0(a0)
    80006840:	34051573          	csrrw	a0,mscratch,a0
    80006844:	30200073          	mret
	...

000000008000684a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000684a:	1141                	addi	sp,sp,-16
    8000684c:	e422                	sd	s0,8(sp)
    8000684e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006850:	0c0007b7          	lui	a5,0xc000
    80006854:	4705                	li	a4,1
    80006856:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006858:	c3d8                	sw	a4,4(a5)
}
    8000685a:	6422                	ld	s0,8(sp)
    8000685c:	0141                	addi	sp,sp,16
    8000685e:	8082                	ret

0000000080006860 <plicinithart>:

void
plicinithart(void)
{
    80006860:	1141                	addi	sp,sp,-16
    80006862:	e406                	sd	ra,8(sp)
    80006864:	e022                	sd	s0,0(sp)
    80006866:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006868:	ffffc097          	auipc	ra,0xffffc
    8000686c:	a68080e7          	jalr	-1432(ra) # 800022d0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006870:	0085171b          	slliw	a4,a0,0x8
    80006874:	0c0027b7          	lui	a5,0xc002
    80006878:	97ba                	add	a5,a5,a4
    8000687a:	40200713          	li	a4,1026
    8000687e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006882:	00d5151b          	slliw	a0,a0,0xd
    80006886:	0c2017b7          	lui	a5,0xc201
    8000688a:	953e                	add	a0,a0,a5
    8000688c:	00052023          	sw	zero,0(a0)
}
    80006890:	60a2                	ld	ra,8(sp)
    80006892:	6402                	ld	s0,0(sp)
    80006894:	0141                	addi	sp,sp,16
    80006896:	8082                	ret

0000000080006898 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006898:	1141                	addi	sp,sp,-16
    8000689a:	e406                	sd	ra,8(sp)
    8000689c:	e022                	sd	s0,0(sp)
    8000689e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068a0:	ffffc097          	auipc	ra,0xffffc
    800068a4:	a30080e7          	jalr	-1488(ra) # 800022d0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800068a8:	00d5179b          	slliw	a5,a0,0xd
    800068ac:	0c201537          	lui	a0,0xc201
    800068b0:	953e                	add	a0,a0,a5
  return irq;
}
    800068b2:	4148                	lw	a0,4(a0)
    800068b4:	60a2                	ld	ra,8(sp)
    800068b6:	6402                	ld	s0,0(sp)
    800068b8:	0141                	addi	sp,sp,16
    800068ba:	8082                	ret

00000000800068bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800068bc:	1101                	addi	sp,sp,-32
    800068be:	ec06                	sd	ra,24(sp)
    800068c0:	e822                	sd	s0,16(sp)
    800068c2:	e426                	sd	s1,8(sp)
    800068c4:	1000                	addi	s0,sp,32
    800068c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800068c8:	ffffc097          	auipc	ra,0xffffc
    800068cc:	a08080e7          	jalr	-1528(ra) # 800022d0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800068d0:	00d5151b          	slliw	a0,a0,0xd
    800068d4:	0c2017b7          	lui	a5,0xc201
    800068d8:	97aa                	add	a5,a5,a0
    800068da:	c3c4                	sw	s1,4(a5)
}
    800068dc:	60e2                	ld	ra,24(sp)
    800068de:	6442                	ld	s0,16(sp)
    800068e0:	64a2                	ld	s1,8(sp)
    800068e2:	6105                	addi	sp,sp,32
    800068e4:	8082                	ret

00000000800068e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068e6:	1141                	addi	sp,sp,-16
    800068e8:	e406                	sd	ra,8(sp)
    800068ea:	e022                	sd	s0,0(sp)
    800068ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068ee:	479d                	li	a5,7
    800068f0:	06a7c963          	blt	a5,a0,80006962 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800068f4:	0001c797          	auipc	a5,0x1c
    800068f8:	70c78793          	addi	a5,a5,1804 # 80023000 <disk>
    800068fc:	00a78733          	add	a4,a5,a0
    80006900:	6789                	lui	a5,0x2
    80006902:	97ba                	add	a5,a5,a4
    80006904:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006908:	e7ad                	bnez	a5,80006972 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000690a:	00451793          	slli	a5,a0,0x4
    8000690e:	0001e717          	auipc	a4,0x1e
    80006912:	6f270713          	addi	a4,a4,1778 # 80025000 <disk+0x2000>
    80006916:	6314                	ld	a3,0(a4)
    80006918:	96be                	add	a3,a3,a5
    8000691a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000691e:	6314                	ld	a3,0(a4)
    80006920:	96be                	add	a3,a3,a5
    80006922:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006926:	6314                	ld	a3,0(a4)
    80006928:	96be                	add	a3,a3,a5
    8000692a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000692e:	6318                	ld	a4,0(a4)
    80006930:	97ba                	add	a5,a5,a4
    80006932:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006936:	0001c797          	auipc	a5,0x1c
    8000693a:	6ca78793          	addi	a5,a5,1738 # 80023000 <disk>
    8000693e:	97aa                	add	a5,a5,a0
    80006940:	6509                	lui	a0,0x2
    80006942:	953e                	add	a0,a0,a5
    80006944:	4785                	li	a5,1
    80006946:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000694a:	0001e517          	auipc	a0,0x1e
    8000694e:	6ce50513          	addi	a0,a0,1742 # 80025018 <disk+0x2018>
    80006952:	ffffc097          	auipc	ra,0xffffc
    80006956:	4b6080e7          	jalr	1206(ra) # 80002e08 <wakeup>
}
    8000695a:	60a2                	ld	ra,8(sp)
    8000695c:	6402                	ld	s0,0(sp)
    8000695e:	0141                	addi	sp,sp,16
    80006960:	8082                	ret
    panic("free_desc 1");
    80006962:	00002517          	auipc	a0,0x2
    80006966:	30650513          	addi	a0,a0,774 # 80008c68 <syscalls+0x320>
    8000696a:	ffffa097          	auipc	ra,0xffffa
    8000696e:	bd4080e7          	jalr	-1068(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006972:	00002517          	auipc	a0,0x2
    80006976:	30650513          	addi	a0,a0,774 # 80008c78 <syscalls+0x330>
    8000697a:	ffffa097          	auipc	ra,0xffffa
    8000697e:	bc4080e7          	jalr	-1084(ra) # 8000053e <panic>

0000000080006982 <virtio_disk_init>:
{
    80006982:	1101                	addi	sp,sp,-32
    80006984:	ec06                	sd	ra,24(sp)
    80006986:	e822                	sd	s0,16(sp)
    80006988:	e426                	sd	s1,8(sp)
    8000698a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000698c:	00002597          	auipc	a1,0x2
    80006990:	2fc58593          	addi	a1,a1,764 # 80008c88 <syscalls+0x340>
    80006994:	0001e517          	auipc	a0,0x1e
    80006998:	79450513          	addi	a0,a0,1940 # 80025128 <disk+0x2128>
    8000699c:	ffffa097          	auipc	ra,0xffffa
    800069a0:	1b8080e7          	jalr	440(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069a4:	100017b7          	lui	a5,0x10001
    800069a8:	4398                	lw	a4,0(a5)
    800069aa:	2701                	sext.w	a4,a4
    800069ac:	747277b7          	lui	a5,0x74727
    800069b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800069b4:	0ef71163          	bne	a4,a5,80006a96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800069b8:	100017b7          	lui	a5,0x10001
    800069bc:	43dc                	lw	a5,4(a5)
    800069be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069c0:	4705                	li	a4,1
    800069c2:	0ce79a63          	bne	a5,a4,80006a96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069c6:	100017b7          	lui	a5,0x10001
    800069ca:	479c                	lw	a5,8(a5)
    800069cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800069ce:	4709                	li	a4,2
    800069d0:	0ce79363          	bne	a5,a4,80006a96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800069d4:	100017b7          	lui	a5,0x10001
    800069d8:	47d8                	lw	a4,12(a5)
    800069da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069dc:	554d47b7          	lui	a5,0x554d4
    800069e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800069e4:	0af71963          	bne	a4,a5,80006a96 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800069e8:	100017b7          	lui	a5,0x10001
    800069ec:	4705                	li	a4,1
    800069ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069f0:	470d                	li	a4,3
    800069f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800069f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800069f6:	c7ffe737          	lui	a4,0xc7ffe
    800069fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800069fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a00:	2701                	sext.w	a4,a4
    80006a02:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a04:	472d                	li	a4,11
    80006a06:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a08:	473d                	li	a4,15
    80006a0a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006a0c:	6705                	lui	a4,0x1
    80006a0e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a10:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006a14:	5bdc                	lw	a5,52(a5)
    80006a16:	2781                	sext.w	a5,a5
  if(max == 0)
    80006a18:	c7d9                	beqz	a5,80006aa6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006a1a:	471d                	li	a4,7
    80006a1c:	08f77d63          	bgeu	a4,a5,80006ab6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a20:	100014b7          	lui	s1,0x10001
    80006a24:	47a1                	li	a5,8
    80006a26:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006a28:	6609                	lui	a2,0x2
    80006a2a:	4581                	li	a1,0
    80006a2c:	0001c517          	auipc	a0,0x1c
    80006a30:	5d450513          	addi	a0,a0,1492 # 80023000 <disk>
    80006a34:	ffffa097          	auipc	ra,0xffffa
    80006a38:	2d0080e7          	jalr	720(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006a3c:	0001c717          	auipc	a4,0x1c
    80006a40:	5c470713          	addi	a4,a4,1476 # 80023000 <disk>
    80006a44:	00c75793          	srli	a5,a4,0xc
    80006a48:	2781                	sext.w	a5,a5
    80006a4a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006a4c:	0001e797          	auipc	a5,0x1e
    80006a50:	5b478793          	addi	a5,a5,1460 # 80025000 <disk+0x2000>
    80006a54:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006a56:	0001c717          	auipc	a4,0x1c
    80006a5a:	62a70713          	addi	a4,a4,1578 # 80023080 <disk+0x80>
    80006a5e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006a60:	0001d717          	auipc	a4,0x1d
    80006a64:	5a070713          	addi	a4,a4,1440 # 80024000 <disk+0x1000>
    80006a68:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006a6a:	4705                	li	a4,1
    80006a6c:	00e78c23          	sb	a4,24(a5)
    80006a70:	00e78ca3          	sb	a4,25(a5)
    80006a74:	00e78d23          	sb	a4,26(a5)
    80006a78:	00e78da3          	sb	a4,27(a5)
    80006a7c:	00e78e23          	sb	a4,28(a5)
    80006a80:	00e78ea3          	sb	a4,29(a5)
    80006a84:	00e78f23          	sb	a4,30(a5)
    80006a88:	00e78fa3          	sb	a4,31(a5)
}
    80006a8c:	60e2                	ld	ra,24(sp)
    80006a8e:	6442                	ld	s0,16(sp)
    80006a90:	64a2                	ld	s1,8(sp)
    80006a92:	6105                	addi	sp,sp,32
    80006a94:	8082                	ret
    panic("could not find virtio disk");
    80006a96:	00002517          	auipc	a0,0x2
    80006a9a:	20250513          	addi	a0,a0,514 # 80008c98 <syscalls+0x350>
    80006a9e:	ffffa097          	auipc	ra,0xffffa
    80006aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006aa6:	00002517          	auipc	a0,0x2
    80006aaa:	21250513          	addi	a0,a0,530 # 80008cb8 <syscalls+0x370>
    80006aae:	ffffa097          	auipc	ra,0xffffa
    80006ab2:	a90080e7          	jalr	-1392(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006ab6:	00002517          	auipc	a0,0x2
    80006aba:	22250513          	addi	a0,a0,546 # 80008cd8 <syscalls+0x390>
    80006abe:	ffffa097          	auipc	ra,0xffffa
    80006ac2:	a80080e7          	jalr	-1408(ra) # 8000053e <panic>

0000000080006ac6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006ac6:	7159                	addi	sp,sp,-112
    80006ac8:	f486                	sd	ra,104(sp)
    80006aca:	f0a2                	sd	s0,96(sp)
    80006acc:	eca6                	sd	s1,88(sp)
    80006ace:	e8ca                	sd	s2,80(sp)
    80006ad0:	e4ce                	sd	s3,72(sp)
    80006ad2:	e0d2                	sd	s4,64(sp)
    80006ad4:	fc56                	sd	s5,56(sp)
    80006ad6:	f85a                	sd	s6,48(sp)
    80006ad8:	f45e                	sd	s7,40(sp)
    80006ada:	f062                	sd	s8,32(sp)
    80006adc:	ec66                	sd	s9,24(sp)
    80006ade:	e86a                	sd	s10,16(sp)
    80006ae0:	1880                	addi	s0,sp,112
    80006ae2:	892a                	mv	s2,a0
    80006ae4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006ae6:	00c52c83          	lw	s9,12(a0)
    80006aea:	001c9c9b          	slliw	s9,s9,0x1
    80006aee:	1c82                	slli	s9,s9,0x20
    80006af0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006af4:	0001e517          	auipc	a0,0x1e
    80006af8:	63450513          	addi	a0,a0,1588 # 80025128 <disk+0x2128>
    80006afc:	ffffa097          	auipc	ra,0xffffa
    80006b00:	0e8080e7          	jalr	232(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006b04:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b06:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006b08:	0001cb97          	auipc	s7,0x1c
    80006b0c:	4f8b8b93          	addi	s7,s7,1272 # 80023000 <disk>
    80006b10:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006b12:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006b14:	8a4e                	mv	s4,s3
    80006b16:	a051                	j	80006b9a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006b18:	00fb86b3          	add	a3,s7,a5
    80006b1c:	96da                	add	a3,a3,s6
    80006b1e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006b22:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006b24:	0207c563          	bltz	a5,80006b4e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006b28:	2485                	addiw	s1,s1,1
    80006b2a:	0711                	addi	a4,a4,4
    80006b2c:	25548063          	beq	s1,s5,80006d6c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006b30:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006b32:	0001e697          	auipc	a3,0x1e
    80006b36:	4e668693          	addi	a3,a3,1254 # 80025018 <disk+0x2018>
    80006b3a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006b3c:	0006c583          	lbu	a1,0(a3)
    80006b40:	fde1                	bnez	a1,80006b18 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006b42:	2785                	addiw	a5,a5,1
    80006b44:	0685                	addi	a3,a3,1
    80006b46:	ff879be3          	bne	a5,s8,80006b3c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006b4a:	57fd                	li	a5,-1
    80006b4c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006b4e:	02905a63          	blez	s1,80006b82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b52:	f9042503          	lw	a0,-112(s0)
    80006b56:	00000097          	auipc	ra,0x0
    80006b5a:	d90080e7          	jalr	-624(ra) # 800068e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b5e:	4785                	li	a5,1
    80006b60:	0297d163          	bge	a5,s1,80006b82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b64:	f9442503          	lw	a0,-108(s0)
    80006b68:	00000097          	auipc	ra,0x0
    80006b6c:	d7e080e7          	jalr	-642(ra) # 800068e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b70:	4789                	li	a5,2
    80006b72:	0097d863          	bge	a5,s1,80006b82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b76:	f9842503          	lw	a0,-104(s0)
    80006b7a:	00000097          	auipc	ra,0x0
    80006b7e:	d6c080e7          	jalr	-660(ra) # 800068e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b82:	0001e597          	auipc	a1,0x1e
    80006b86:	5a658593          	addi	a1,a1,1446 # 80025128 <disk+0x2128>
    80006b8a:	0001e517          	auipc	a0,0x1e
    80006b8e:	48e50513          	addi	a0,a0,1166 # 80025018 <disk+0x2018>
    80006b92:	ffffc097          	auipc	ra,0xffffc
    80006b96:	0ca080e7          	jalr	202(ra) # 80002c5c <sleep>
  for(int i = 0; i < 3; i++){
    80006b9a:	f9040713          	addi	a4,s0,-112
    80006b9e:	84ce                	mv	s1,s3
    80006ba0:	bf41                	j	80006b30 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006ba2:	20058713          	addi	a4,a1,512
    80006ba6:	00471693          	slli	a3,a4,0x4
    80006baa:	0001c717          	auipc	a4,0x1c
    80006bae:	45670713          	addi	a4,a4,1110 # 80023000 <disk>
    80006bb2:	9736                	add	a4,a4,a3
    80006bb4:	4685                	li	a3,1
    80006bb6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006bba:	20058713          	addi	a4,a1,512
    80006bbe:	00471693          	slli	a3,a4,0x4
    80006bc2:	0001c717          	auipc	a4,0x1c
    80006bc6:	43e70713          	addi	a4,a4,1086 # 80023000 <disk>
    80006bca:	9736                	add	a4,a4,a3
    80006bcc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006bd0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006bd4:	7679                	lui	a2,0xffffe
    80006bd6:	963e                	add	a2,a2,a5
    80006bd8:	0001e697          	auipc	a3,0x1e
    80006bdc:	42868693          	addi	a3,a3,1064 # 80025000 <disk+0x2000>
    80006be0:	6298                	ld	a4,0(a3)
    80006be2:	9732                	add	a4,a4,a2
    80006be4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006be6:	6298                	ld	a4,0(a3)
    80006be8:	9732                	add	a4,a4,a2
    80006bea:	4541                	li	a0,16
    80006bec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006bee:	6298                	ld	a4,0(a3)
    80006bf0:	9732                	add	a4,a4,a2
    80006bf2:	4505                	li	a0,1
    80006bf4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006bf8:	f9442703          	lw	a4,-108(s0)
    80006bfc:	6288                	ld	a0,0(a3)
    80006bfe:	962a                	add	a2,a2,a0
    80006c00:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c04:	0712                	slli	a4,a4,0x4
    80006c06:	6290                	ld	a2,0(a3)
    80006c08:	963a                	add	a2,a2,a4
    80006c0a:	05890513          	addi	a0,s2,88
    80006c0e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006c10:	6294                	ld	a3,0(a3)
    80006c12:	96ba                	add	a3,a3,a4
    80006c14:	40000613          	li	a2,1024
    80006c18:	c690                	sw	a2,8(a3)
  if(write)
    80006c1a:	140d0063          	beqz	s10,80006d5a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c1e:	0001e697          	auipc	a3,0x1e
    80006c22:	3e26b683          	ld	a3,994(a3) # 80025000 <disk+0x2000>
    80006c26:	96ba                	add	a3,a3,a4
    80006c28:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c2c:	0001c817          	auipc	a6,0x1c
    80006c30:	3d480813          	addi	a6,a6,980 # 80023000 <disk>
    80006c34:	0001e517          	auipc	a0,0x1e
    80006c38:	3cc50513          	addi	a0,a0,972 # 80025000 <disk+0x2000>
    80006c3c:	6114                	ld	a3,0(a0)
    80006c3e:	96ba                	add	a3,a3,a4
    80006c40:	00c6d603          	lhu	a2,12(a3)
    80006c44:	00166613          	ori	a2,a2,1
    80006c48:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c4c:	f9842683          	lw	a3,-104(s0)
    80006c50:	6110                	ld	a2,0(a0)
    80006c52:	9732                	add	a4,a4,a2
    80006c54:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c58:	20058613          	addi	a2,a1,512
    80006c5c:	0612                	slli	a2,a2,0x4
    80006c5e:	9642                	add	a2,a2,a6
    80006c60:	577d                	li	a4,-1
    80006c62:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c66:	00469713          	slli	a4,a3,0x4
    80006c6a:	6114                	ld	a3,0(a0)
    80006c6c:	96ba                	add	a3,a3,a4
    80006c6e:	03078793          	addi	a5,a5,48
    80006c72:	97c2                	add	a5,a5,a6
    80006c74:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006c76:	611c                	ld	a5,0(a0)
    80006c78:	97ba                	add	a5,a5,a4
    80006c7a:	4685                	li	a3,1
    80006c7c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c7e:	611c                	ld	a5,0(a0)
    80006c80:	97ba                	add	a5,a5,a4
    80006c82:	4809                	li	a6,2
    80006c84:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006c88:	611c                	ld	a5,0(a0)
    80006c8a:	973e                	add	a4,a4,a5
    80006c8c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c90:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006c94:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c98:	6518                	ld	a4,8(a0)
    80006c9a:	00275783          	lhu	a5,2(a4)
    80006c9e:	8b9d                	andi	a5,a5,7
    80006ca0:	0786                	slli	a5,a5,0x1
    80006ca2:	97ba                	add	a5,a5,a4
    80006ca4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006ca8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006cac:	6518                	ld	a4,8(a0)
    80006cae:	00275783          	lhu	a5,2(a4)
    80006cb2:	2785                	addiw	a5,a5,1
    80006cb4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006cb8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006cbc:	100017b7          	lui	a5,0x10001
    80006cc0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cc4:	00492703          	lw	a4,4(s2)
    80006cc8:	4785                	li	a5,1
    80006cca:	02f71163          	bne	a4,a5,80006cec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006cce:	0001e997          	auipc	s3,0x1e
    80006cd2:	45a98993          	addi	s3,s3,1114 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006cd6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006cd8:	85ce                	mv	a1,s3
    80006cda:	854a                	mv	a0,s2
    80006cdc:	ffffc097          	auipc	ra,0xffffc
    80006ce0:	f80080e7          	jalr	-128(ra) # 80002c5c <sleep>
  while(b->disk == 1) {
    80006ce4:	00492783          	lw	a5,4(s2)
    80006ce8:	fe9788e3          	beq	a5,s1,80006cd8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006cec:	f9042903          	lw	s2,-112(s0)
    80006cf0:	20090793          	addi	a5,s2,512
    80006cf4:	00479713          	slli	a4,a5,0x4
    80006cf8:	0001c797          	auipc	a5,0x1c
    80006cfc:	30878793          	addi	a5,a5,776 # 80023000 <disk>
    80006d00:	97ba                	add	a5,a5,a4
    80006d02:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d06:	0001e997          	auipc	s3,0x1e
    80006d0a:	2fa98993          	addi	s3,s3,762 # 80025000 <disk+0x2000>
    80006d0e:	00491713          	slli	a4,s2,0x4
    80006d12:	0009b783          	ld	a5,0(s3)
    80006d16:	97ba                	add	a5,a5,a4
    80006d18:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d1c:	854a                	mv	a0,s2
    80006d1e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d22:	00000097          	auipc	ra,0x0
    80006d26:	bc4080e7          	jalr	-1084(ra) # 800068e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d2a:	8885                	andi	s1,s1,1
    80006d2c:	f0ed                	bnez	s1,80006d0e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d2e:	0001e517          	auipc	a0,0x1e
    80006d32:	3fa50513          	addi	a0,a0,1018 # 80025128 <disk+0x2128>
    80006d36:	ffffa097          	auipc	ra,0xffffa
    80006d3a:	f74080e7          	jalr	-140(ra) # 80000caa <release>
}
    80006d3e:	70a6                	ld	ra,104(sp)
    80006d40:	7406                	ld	s0,96(sp)
    80006d42:	64e6                	ld	s1,88(sp)
    80006d44:	6946                	ld	s2,80(sp)
    80006d46:	69a6                	ld	s3,72(sp)
    80006d48:	6a06                	ld	s4,64(sp)
    80006d4a:	7ae2                	ld	s5,56(sp)
    80006d4c:	7b42                	ld	s6,48(sp)
    80006d4e:	7ba2                	ld	s7,40(sp)
    80006d50:	7c02                	ld	s8,32(sp)
    80006d52:	6ce2                	ld	s9,24(sp)
    80006d54:	6d42                	ld	s10,16(sp)
    80006d56:	6165                	addi	sp,sp,112
    80006d58:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006d5a:	0001e697          	auipc	a3,0x1e
    80006d5e:	2a66b683          	ld	a3,678(a3) # 80025000 <disk+0x2000>
    80006d62:	96ba                	add	a3,a3,a4
    80006d64:	4609                	li	a2,2
    80006d66:	00c69623          	sh	a2,12(a3)
    80006d6a:	b5c9                	j	80006c2c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d6c:	f9042583          	lw	a1,-112(s0)
    80006d70:	20058793          	addi	a5,a1,512
    80006d74:	0792                	slli	a5,a5,0x4
    80006d76:	0001c517          	auipc	a0,0x1c
    80006d7a:	33250513          	addi	a0,a0,818 # 800230a8 <disk+0xa8>
    80006d7e:	953e                	add	a0,a0,a5
  if(write)
    80006d80:	e20d11e3          	bnez	s10,80006ba2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006d84:	20058713          	addi	a4,a1,512
    80006d88:	00471693          	slli	a3,a4,0x4
    80006d8c:	0001c717          	auipc	a4,0x1c
    80006d90:	27470713          	addi	a4,a4,628 # 80023000 <disk>
    80006d94:	9736                	add	a4,a4,a3
    80006d96:	0a072423          	sw	zero,168(a4)
    80006d9a:	b505                	j	80006bba <virtio_disk_rw+0xf4>

0000000080006d9c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d9c:	1101                	addi	sp,sp,-32
    80006d9e:	ec06                	sd	ra,24(sp)
    80006da0:	e822                	sd	s0,16(sp)
    80006da2:	e426                	sd	s1,8(sp)
    80006da4:	e04a                	sd	s2,0(sp)
    80006da6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006da8:	0001e517          	auipc	a0,0x1e
    80006dac:	38050513          	addi	a0,a0,896 # 80025128 <disk+0x2128>
    80006db0:	ffffa097          	auipc	ra,0xffffa
    80006db4:	e34080e7          	jalr	-460(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006db8:	10001737          	lui	a4,0x10001
    80006dbc:	533c                	lw	a5,96(a4)
    80006dbe:	8b8d                	andi	a5,a5,3
    80006dc0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006dc2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006dc6:	0001e797          	auipc	a5,0x1e
    80006dca:	23a78793          	addi	a5,a5,570 # 80025000 <disk+0x2000>
    80006dce:	6b94                	ld	a3,16(a5)
    80006dd0:	0207d703          	lhu	a4,32(a5)
    80006dd4:	0026d783          	lhu	a5,2(a3)
    80006dd8:	06f70163          	beq	a4,a5,80006e3a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ddc:	0001c917          	auipc	s2,0x1c
    80006de0:	22490913          	addi	s2,s2,548 # 80023000 <disk>
    80006de4:	0001e497          	auipc	s1,0x1e
    80006de8:	21c48493          	addi	s1,s1,540 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006dec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006df0:	6898                	ld	a4,16(s1)
    80006df2:	0204d783          	lhu	a5,32(s1)
    80006df6:	8b9d                	andi	a5,a5,7
    80006df8:	078e                	slli	a5,a5,0x3
    80006dfa:	97ba                	add	a5,a5,a4
    80006dfc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006dfe:	20078713          	addi	a4,a5,512
    80006e02:	0712                	slli	a4,a4,0x4
    80006e04:	974a                	add	a4,a4,s2
    80006e06:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006e0a:	e731                	bnez	a4,80006e56 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e0c:	20078793          	addi	a5,a5,512
    80006e10:	0792                	slli	a5,a5,0x4
    80006e12:	97ca                	add	a5,a5,s2
    80006e14:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006e16:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e1a:	ffffc097          	auipc	ra,0xffffc
    80006e1e:	fee080e7          	jalr	-18(ra) # 80002e08 <wakeup>

    disk.used_idx += 1;
    80006e22:	0204d783          	lhu	a5,32(s1)
    80006e26:	2785                	addiw	a5,a5,1
    80006e28:	17c2                	slli	a5,a5,0x30
    80006e2a:	93c1                	srli	a5,a5,0x30
    80006e2c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e30:	6898                	ld	a4,16(s1)
    80006e32:	00275703          	lhu	a4,2(a4)
    80006e36:	faf71be3          	bne	a4,a5,80006dec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e3a:	0001e517          	auipc	a0,0x1e
    80006e3e:	2ee50513          	addi	a0,a0,750 # 80025128 <disk+0x2128>
    80006e42:	ffffa097          	auipc	ra,0xffffa
    80006e46:	e68080e7          	jalr	-408(ra) # 80000caa <release>
}
    80006e4a:	60e2                	ld	ra,24(sp)
    80006e4c:	6442                	ld	s0,16(sp)
    80006e4e:	64a2                	ld	s1,8(sp)
    80006e50:	6902                	ld	s2,0(sp)
    80006e52:	6105                	addi	sp,sp,32
    80006e54:	8082                	ret
      panic("virtio_disk_intr status");
    80006e56:	00002517          	auipc	a0,0x2
    80006e5a:	ea250513          	addi	a0,a0,-350 # 80008cf8 <syscalls+0x3b0>
    80006e5e:	ffff9097          	auipc	ra,0xffff9
    80006e62:	6e0080e7          	jalr	1760(ra) # 8000053e <panic>

0000000080006e66 <cas>:
    80006e66:	100522af          	lr.w	t0,(a0)
    80006e6a:	00b29563          	bne	t0,a1,80006e74 <fail>
    80006e6e:	18c5252f          	sc.w	a0,a2,(a0)
    80006e72:	8082                	ret

0000000080006e74 <fail>:
    80006e74:	4505                	li	a0,1
    80006e76:	8082                	ret
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
