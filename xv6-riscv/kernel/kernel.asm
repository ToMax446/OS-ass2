
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
    80000068:	39c78793          	addi	a5,a5,924 # 80006400 <timervec>
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
    80000130:	b1a080e7          	jalr	-1254(ra) # 80002c46 <either_copyin>
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
    800001c8:	c00080e7          	jalr	-1024(ra) # 80001dc4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	4d8080e7          	jalr	1240(ra) # 800026ac <sleep>
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
    80000214:	9e0080e7          	jalr	-1568(ra) # 80002bf0 <either_copyout>
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
    800002f6:	9aa080e7          	jalr	-1622(ra) # 80002c9c <procdump>
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
    8000044a:	41e080e7          	jalr	1054(ra) # 80002864 <wakeup>
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
    8000047c:	76878793          	addi	a5,a5,1896 # 80021be0 <devsw>
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
    800008a4:	fc4080e7          	jalr	-60(ra) # 80002864 <wakeup>
    
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
    80000930:	d80080e7          	jalr	-640(ra) # 800026ac <sleep>
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
    80000b82:	222080e7          	jalr	546(ra) # 80001da0 <mycpu>
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
    80000bb4:	1f0080e7          	jalr	496(ra) # 80001da0 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	1e4080e7          	jalr	484(ra) # 80001da0 <mycpu>
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
    80000bd8:	1cc080e7          	jalr	460(ra) # 80001da0 <mycpu>
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
    80000c18:	18c080e7          	jalr	396(ra) # 80001da0 <mycpu>
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
    80000c56:	14e080e7          	jalr	334(ra) # 80001da0 <mycpu>
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
    80000ebe:	ed6080e7          	jalr	-298(ra) # 80001d90 <cpuid>
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
    80000eda:	eba080e7          	jalr	-326(ra) # 80001d90 <cpuid>
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
    80000efc:	f78080e7          	jalr	-136(ra) # 80002e70 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	540080e7          	jalr	1344(ra) # 80006440 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	50a080e7          	jalr	1290(ra) # 80002412 <scheduler>
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
    80000f6c:	cbe080e7          	jalr	-834(ra) # 80001c26 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	ed8080e7          	jalr	-296(ra) # 80002e48 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	ef8080e7          	jalr	-264(ra) # 80002e70 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	4aa080e7          	jalr	1194(ra) # 8000642a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	4b8080e7          	jalr	1208(ra) # 80006440 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	69e080e7          	jalr	1694(ra) # 8000362e <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	d2e080e7          	jalr	-722(ra) # 80003cc6 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	cd8080e7          	jalr	-808(ra) # 80004c78 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	5ba080e7          	jalr	1466(ra) # 80006562 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	1b2080e7          	jalr	434(ra) # 80002162 <userinit>
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
    80001268:	92c080e7          	jalr	-1748(ra) # 80001b90 <proc_mapstacks>
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
  int id = 0;
  int idMin = 0;
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    uint64 procsNum = c->admittedProcs;
    if (procsNum < min){
    80001870:	63c8                	ld	a0,128(a5)
    80001872:	1087b783          	ld	a5,264(a5)
      idMin = id;
    }     
    id++;
  }
  return idMin;
}
    80001876:	00a7b533          	sltu	a0,a5,a0
    8000187a:	6422                	ld	s0,8(sp)
    8000187c:	0141                	addi	sp,sp,16
    8000187e:	8082                	ret

0000000080001880 <remove_from_list>:


int
remove_from_list(int p_index, int *list, struct spinlock *lock_list){
    80001880:	7159                	addi	sp,sp,-112
    80001882:	f486                	sd	ra,104(sp)
    80001884:	f0a2                	sd	s0,96(sp)
    80001886:	eca6                	sd	s1,88(sp)
    80001888:	e8ca                	sd	s2,80(sp)
    8000188a:	e4ce                	sd	s3,72(sp)
    8000188c:	e0d2                	sd	s4,64(sp)
    8000188e:	fc56                	sd	s5,56(sp)
    80001890:	f85a                	sd	s6,48(sp)
    80001892:	f45e                	sd	s7,40(sp)
    80001894:	f062                	sd	s8,32(sp)
    80001896:	ec66                	sd	s9,24(sp)
    80001898:	e86a                	sd	s10,16(sp)
    8000189a:	e46e                	sd	s11,8(sp)
    8000189c:	1880                	addi	s0,sp,112
    8000189e:	89aa                	mv	s3,a0
    800018a0:	8a2e                	mv	s4,a1
    800018a2:	84b2                	mv	s1,a2
  acquire(lock_list);
    800018a4:	8532                	mv	a0,a2
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	33e080e7          	jalr	830(ra) # 80000be4 <acquire>
  if(*list == -1){
    800018ae:	000a2903          	lw	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018b2:	57fd                	li	a5,-1
    800018b4:	08f90263          	beq	s2,a5,80001938 <remove_from_list+0xb8>
    release(lock_list);
    return -1;
  }
  release(lock_list);
    800018b8:	8526                	mv	a0,s1
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	3f0080e7          	jalr	1008(ra) # 80000caa <release>
  struct proc *p = 0;
  acquire(lock_list);
    800018c2:	8526                	mv	a0,s1
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	320080e7          	jalr	800(ra) # 80000be4 <acquire>
  if(*list == p_index){
    800018cc:	000a2783          	lw	a5,0(s4)
    800018d0:	07378b63          	beq	a5,s3,80001946 <remove_from_list+0xc6>
    *list = p->next;
    release(&p->linked_list_lock);
    release(lock_list);
    return 0;
  }
  release(lock_list);
    800018d4:	8526                	mv	a0,s1
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	3d4080e7          	jalr	980(ra) # 80000caa <release>
  int inList = 0;
  struct proc *pred_proc = &proc[*list];
    800018de:	000a2503          	lw	a0,0(s4)
    800018e2:	18800493          	li	s1,392
    800018e6:	02950533          	mul	a0,a0,s1
    800018ea:	00010917          	auipc	s2,0x10
    800018ee:	eae90913          	addi	s2,s2,-338 # 80011798 <proc>
    800018f2:	01250db3          	add	s11,a0,s2
  acquire(&pred_proc->linked_list_lock);
    800018f6:	04050513          	addi	a0,a0,64
    800018fa:	954a                	add	a0,a0,s2
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	2e8080e7          	jalr	744(ra) # 80000be4 <acquire>
  p = &proc[pred_proc->next];
    80001904:	03cda503          	lw	a0,60(s11)
    80001908:	2501                	sext.w	a0,a0
    8000190a:	02950533          	mul	a0,a0,s1
    8000190e:	012504b3          	add	s1,a0,s2
  acquire(&p->linked_list_lock);
    80001912:	04050513          	addi	a0,a0,64
    80001916:	954a                	add	a0,a0,s2
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	2cc080e7          	jalr	716(ra) # 80000be4 <acquire>
  int done = 0;
    80001920:	4901                	li	s2,0
  int inList = 0;
    80001922:	4d01                	li	s10,0
  while(!done){
    if (pred_proc->next == -1){
    80001924:	5afd                	li	s5,-1
      done = 1;
    80001926:	4c85                	li	s9,1
    80001928:	8c66                	mv	s8,s9
    8000192a:	18800b93          	li	s7,392
      pred_proc->next = p->next;
      continue;
    }
    release(&pred_proc->linked_list_lock);
    pred_proc = p;
    p = &proc[p->next];
    8000192e:	00010a17          	auipc	s4,0x10
    80001932:	e6aa0a13          	addi	s4,s4,-406 # 80011798 <proc>
  while(!done){
    80001936:	a8b5                	j	800019b2 <remove_from_list+0x132>
    release(lock_list);
    80001938:	8526                	mv	a0,s1
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	370080e7          	jalr	880(ra) # 80000caa <release>
    return -1;
    80001942:	89ca                	mv	s3,s2
    80001944:	a845                	j	800019f4 <remove_from_list+0x174>
    acquire(&p->linked_list_lock);
    80001946:	18800a93          	li	s5,392
    8000194a:	035989b3          	mul	s3,s3,s5
    8000194e:	04098913          	addi	s2,s3,64 # 1040 <_entry-0x7fffefc0>
    80001952:	00010a97          	auipc	s5,0x10
    80001956:	e46a8a93          	addi	s5,s5,-442 # 80011798 <proc>
    8000195a:	9956                	add	s2,s2,s5
    8000195c:	854a                	mv	a0,s2
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	286080e7          	jalr	646(ra) # 80000be4 <acquire>
    *list = p->next;
    80001966:	9ace                	add	s5,s5,s3
    80001968:	03caa783          	lw	a5,60(s5)
    8000196c:	00fa2023          	sw	a5,0(s4)
    release(&p->linked_list_lock);
    80001970:	854a                	mv	a0,s2
    80001972:	fffff097          	auipc	ra,0xfffff
    80001976:	338080e7          	jalr	824(ra) # 80000caa <release>
    release(lock_list);
    8000197a:	8526                	mv	a0,s1
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	32e080e7          	jalr	814(ra) # 80000caa <release>
    return 0;
    80001984:	4981                	li	s3,0
    80001986:	a0bd                	j	800019f4 <remove_from_list+0x174>
    release(&pred_proc->linked_list_lock);
    80001988:	040d8513          	addi	a0,s11,64
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	31e080e7          	jalr	798(ra) # 80000caa <release>
    p = &proc[p->next];
    80001994:	5cdc                	lw	a5,60(s1)
    80001996:	2781                	sext.w	a5,a5
    80001998:	037787b3          	mul	a5,a5,s7
    8000199c:	01478b33          	add	s6,a5,s4
    acquire(&p->linked_list_lock);
    800019a0:	04078513          	addi	a0,a5,64
    800019a4:	9552                	add	a0,a0,s4
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	23e080e7          	jalr	574(ra) # 80000be4 <acquire>
    800019ae:	8da6                	mv	s11,s1
    p = &proc[p->next];
    800019b0:	84da                	mv	s1,s6
  while(!done){
    800019b2:	02091363          	bnez	s2,800019d8 <remove_from_list+0x158>
    if (pred_proc->next == -1){
    800019b6:	03cda783          	lw	a5,60(s11)
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	01578b63          	beq	a5,s5,800019d2 <remove_from_list+0x152>
    if(p->index == p_index){
    800019c0:	5c9c                	lw	a5,56(s1)
    800019c2:	fd3793e3          	bne	a5,s3,80001988 <remove_from_list+0x108>
      pred_proc->next = p->next;
    800019c6:	5cdc                	lw	a5,60(s1)
    800019c8:	2781                	sext.w	a5,a5
    800019ca:	02fdae23          	sw	a5,60(s11)
      done = 1;
    800019ce:	8966                	mv	s2,s9
      continue;
    800019d0:	b7cd                	j	800019b2 <remove_from_list+0x132>
      done = 1;
    800019d2:	8962                	mv	s2,s8
      inList = 1;
    800019d4:	8d62                	mv	s10,s8
    800019d6:	bff1                	j	800019b2 <remove_from_list+0x132>
  }
  release(&p->linked_list_lock);
    800019d8:	04048513          	addi	a0,s1,64
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	2ce080e7          	jalr	718(ra) # 80000caa <release>
  release(&pred_proc->linked_list_lock); 
    800019e4:	040d8513          	addi	a0,s11,64
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	2c2080e7          	jalr	706(ra) # 80000caa <release>
  if (inList)
    800019f0:	020d1263          	bnez	s10,80001a14 <remove_from_list+0x194>
    return -1;
  return p_index;
}
    800019f4:	854e                	mv	a0,s3
    800019f6:	70a6                	ld	ra,104(sp)
    800019f8:	7406                	ld	s0,96(sp)
    800019fa:	64e6                	ld	s1,88(sp)
    800019fc:	6946                	ld	s2,80(sp)
    800019fe:	69a6                	ld	s3,72(sp)
    80001a00:	6a06                	ld	s4,64(sp)
    80001a02:	7ae2                	ld	s5,56(sp)
    80001a04:	7b42                	ld	s6,48(sp)
    80001a06:	7ba2                	ld	s7,40(sp)
    80001a08:	7c02                	ld	s8,32(sp)
    80001a0a:	6ce2                	ld	s9,24(sp)
    80001a0c:	6d42                	ld	s10,16(sp)
    80001a0e:	6da2                	ld	s11,8(sp)
    80001a10:	6165                	addi	sp,sp,112
    80001a12:	8082                	ret
    return -1;
    80001a14:	59fd                	li	s3,-1
    80001a16:	bff9                	j	800019f4 <remove_from_list+0x174>

0000000080001a18 <insert_cs>:
//   }
//   return ret;
// }

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001a18:	7139                	addi	sp,sp,-64
    80001a1a:	fc06                	sd	ra,56(sp)
    80001a1c:	f822                	sd	s0,48(sp)
    80001a1e:	f426                	sd	s1,40(sp)
    80001a20:	f04a                	sd	s2,32(sp)
    80001a22:	ec4e                	sd	s3,24(sp)
    80001a24:	e852                	sd	s4,16(sp)
    80001a26:	e456                	sd	s5,8(sp)
    80001a28:	e05a                	sd	s6,0(sp)
    80001a2a:	0080                	addi	s0,sp,64
    80001a2c:	892a                	mv	s2,a0
    80001a2e:	8aae                	mv	s5,a1
  int curr = pred->index; 
  struct spinlock *pred_lock;
  while (curr != -1) {
    80001a30:	5d18                	lw	a4,56(a0)
    80001a32:	57fd                	li	a5,-1
    80001a34:	04f70a63          	beq	a4,a5,80001a88 <insert_cs+0x70>
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    if(pred->next!=-1){
    80001a38:	59fd                	li	s3,-1
    80001a3a:	18800b13          	li	s6,392
      pred_lock=&pred->linked_list_lock; // caller acquired
      pred = &proc[pred->next];
    80001a3e:	00010a17          	auipc	s4,0x10
    80001a42:	d5aa0a13          	addi	s4,s4,-678 # 80011798 <proc>
    80001a46:	a81d                	j	80001a7c <insert_cs+0x64>
      pred_lock=&pred->linked_list_lock; // caller acquired
    80001a48:	04090513          	addi	a0,s2,64
      pred = &proc[pred->next];
    80001a4c:	03c92483          	lw	s1,60(s2)
    80001a50:	2481                	sext.w	s1,s1
    80001a52:	036484b3          	mul	s1,s1,s6
    80001a56:	01448933          	add	s2,s1,s4
      release(pred_lock);
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	250080e7          	jalr	592(ra) # 80000caa <release>
      acquire(&pred->linked_list_lock);
    80001a62:	04048493          	addi	s1,s1,64
    80001a66:	009a0533          	add	a0,s4,s1
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	17a080e7          	jalr	378(ra) # 80000be4 <acquire>
    }
    curr = pred->next;
    80001a72:	03c92783          	lw	a5,60(s2)
    80001a76:	2781                	sext.w	a5,a5
  while (curr != -1) {
    80001a78:	01378863          	beq	a5,s3,80001a88 <insert_cs+0x70>
    if(pred->next!=-1){
    80001a7c:	03c92783          	lw	a5,60(s2)
    80001a80:	2781                	sext.w	a5,a5
    80001a82:	ff3788e3          	beq	a5,s3,80001a72 <insert_cs+0x5a>
    80001a86:	b7c9                	j	80001a48 <insert_cs+0x30>
    }
    pred->next = p->index;
    80001a88:	038aa783          	lw	a5,56(s5)
    80001a8c:	02f92e23          	sw	a5,60(s2)
    release(&pred->linked_list_lock);      
    80001a90:	04090513          	addi	a0,s2,64
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	216080e7          	jalr	534(ra) # 80000caa <release>
    p->next=-1;
    80001a9c:	57fd                	li	a5,-1
    80001a9e:	02faae23          	sw	a5,60(s5)
    return p->index;
}
    80001aa2:	038aa503          	lw	a0,56(s5)
    80001aa6:	70e2                	ld	ra,56(sp)
    80001aa8:	7442                	ld	s0,48(sp)
    80001aaa:	74a2                	ld	s1,40(sp)
    80001aac:	7902                	ld	s2,32(sp)
    80001aae:	69e2                	ld	s3,24(sp)
    80001ab0:	6a42                	ld	s4,16(sp)
    80001ab2:	6aa2                	ld	s5,8(sp)
    80001ab4:	6b02                	ld	s6,0(sp)
    80001ab6:	6121                	addi	sp,sp,64
    80001ab8:	8082                	ret

0000000080001aba <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock *lock_list){;
    80001aba:	7139                	addi	sp,sp,-64
    80001abc:	fc06                	sd	ra,56(sp)
    80001abe:	f822                	sd	s0,48(sp)
    80001ac0:	f426                	sd	s1,40(sp)
    80001ac2:	f04a                	sd	s2,32(sp)
    80001ac4:	ec4e                	sd	s3,24(sp)
    80001ac6:	e852                	sd	s4,16(sp)
    80001ac8:	e456                	sd	s5,8(sp)
    80001aca:	0080                	addi	s0,sp,64
    80001acc:	84aa                	mv	s1,a0
    80001ace:	892e                	mv	s2,a1
    80001ad0:	89b2                	mv	s3,a2
  int ret=-1;
  acquire(lock_list);
    80001ad2:	8532                	mv	a0,a2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	110080e7          	jalr	272(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001adc:	00092703          	lw	a4,0(s2)
    80001ae0:	57fd                	li	a5,-1
    80001ae2:	04f70d63          	beq	a4,a5,80001b3c <insert_to_list+0x82>
    release(&proc[p_index].linked_list_lock);
    ret = p_index;
    release(lock_list);
  }
  else{
    release(lock_list);
    80001ae6:	854e                	mv	a0,s3
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	1c2080e7          	jalr	450(ra) # 80000caa <release>
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    80001af0:	00092903          	lw	s2,0(s2)
    80001af4:	18800a13          	li	s4,392
    80001af8:	03490933          	mul	s2,s2,s4
    acquire(&pred->linked_list_lock);
    80001afc:	04090513          	addi	a0,s2,64
    80001b00:	00010997          	auipc	s3,0x10
    80001b04:	c9898993          	addi	s3,s3,-872 # 80011798 <proc>
    80001b08:	954e                	add	a0,a0,s3
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	0da080e7          	jalr	218(ra) # 80000be4 <acquire>
    ret = insert_cs(pred, &proc[p_index]);
    80001b12:	034485b3          	mul	a1,s1,s4
    80001b16:	95ce                	add	a1,a1,s3
    80001b18:	01298533          	add	a0,s3,s2
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	efc080e7          	jalr	-260(ra) # 80001a18 <insert_cs>
  }
if(ret == -1){
    80001b24:	57fd                	li	a5,-1
    80001b26:	04f50d63          	beq	a0,a5,80001b80 <insert_to_list+0xc6>
  panic("insert is failed");
}
return ret;
}
    80001b2a:	70e2                	ld	ra,56(sp)
    80001b2c:	7442                	ld	s0,48(sp)
    80001b2e:	74a2                	ld	s1,40(sp)
    80001b30:	7902                	ld	s2,32(sp)
    80001b32:	69e2                	ld	s3,24(sp)
    80001b34:	6a42                	ld	s4,16(sp)
    80001b36:	6aa2                	ld	s5,8(sp)
    80001b38:	6121                	addi	sp,sp,64
    80001b3a:	8082                	ret
    *list=p_index;
    80001b3c:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001b40:	18800a13          	li	s4,392
    80001b44:	03448ab3          	mul	s5,s1,s4
    80001b48:	040a8913          	addi	s2,s5,64
    80001b4c:	00010a17          	auipc	s4,0x10
    80001b50:	c4ca0a13          	addi	s4,s4,-948 # 80011798 <proc>
    80001b54:	9952                	add	s2,s2,s4
    80001b56:	854a                	mv	a0,s2
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	08c080e7          	jalr	140(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001b60:	9a56                	add	s4,s4,s5
    80001b62:	57fd                	li	a5,-1
    80001b64:	02fa2e23          	sw	a5,60(s4)
    release(&proc[p_index].linked_list_lock);
    80001b68:	854a                	mv	a0,s2
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	140080e7          	jalr	320(ra) # 80000caa <release>
    release(lock_list);
    80001b72:	854e                	mv	a0,s3
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	136080e7          	jalr	310(ra) # 80000caa <release>
    ret = p_index;
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	b75d                	j	80001b24 <insert_to_list+0x6a>
  panic("insert is failed");
    80001b80:	00006517          	auipc	a0,0x6
    80001b84:	68850513          	addi	a0,a0,1672 # 80008208 <digits+0x1c8>
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	9b6080e7          	jalr	-1610(ra) # 8000053e <panic>

0000000080001b90 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001b90:	7139                	addi	sp,sp,-64
    80001b92:	fc06                	sd	ra,56(sp)
    80001b94:	f822                	sd	s0,48(sp)
    80001b96:	f426                	sd	s1,40(sp)
    80001b98:	f04a                	sd	s2,32(sp)
    80001b9a:	ec4e                	sd	s3,24(sp)
    80001b9c:	e852                	sd	s4,16(sp)
    80001b9e:	e456                	sd	s5,8(sp)
    80001ba0:	e05a                	sd	s6,0(sp)
    80001ba2:	0080                	addi	s0,sp,64
    80001ba4:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ba6:	00010497          	auipc	s1,0x10
    80001baa:	bf248493          	addi	s1,s1,-1038 # 80011798 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001bae:	8b26                	mv	s6,s1
    80001bb0:	00006a97          	auipc	s5,0x6
    80001bb4:	450a8a93          	addi	s5,s5,1104 # 80008000 <etext>
    80001bb8:	04000937          	lui	s2,0x4000
    80001bbc:	197d                	addi	s2,s2,-1
    80001bbe:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc0:	00016a17          	auipc	s4,0x16
    80001bc4:	dd8a0a13          	addi	s4,s4,-552 # 80017998 <tickslock>
    char *pa = kalloc();
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	f2c080e7          	jalr	-212(ra) # 80000af4 <kalloc>
    80001bd0:	862a                	mv	a2,a0
    if(pa == 0)
    80001bd2:	c131                	beqz	a0,80001c16 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001bd4:	416485b3          	sub	a1,s1,s6
    80001bd8:	858d                	srai	a1,a1,0x3
    80001bda:	000ab783          	ld	a5,0(s5)
    80001bde:	02f585b3          	mul	a1,a1,a5
    80001be2:	2585                	addiw	a1,a1,1
    80001be4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001be8:	4719                	li	a4,6
    80001bea:	6685                	lui	a3,0x1
    80001bec:	40b905b3          	sub	a1,s2,a1
    80001bf0:	854e                	mv	a0,s3
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	582080e7          	jalr	1410(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfa:	18848493          	addi	s1,s1,392
    80001bfe:	fd4495e3          	bne	s1,s4,80001bc8 <proc_mapstacks+0x38>
  }
}
    80001c02:	70e2                	ld	ra,56(sp)
    80001c04:	7442                	ld	s0,48(sp)
    80001c06:	74a2                	ld	s1,40(sp)
    80001c08:	7902                	ld	s2,32(sp)
    80001c0a:	69e2                	ld	s3,24(sp)
    80001c0c:	6a42                	ld	s4,16(sp)
    80001c0e:	6aa2                	ld	s5,8(sp)
    80001c10:	6b02                	ld	s6,0(sp)
    80001c12:	6121                	addi	sp,sp,64
    80001c14:	8082                	ret
      panic("kalloc");
    80001c16:	00006517          	auipc	a0,0x6
    80001c1a:	60a50513          	addi	a0,a0,1546 # 80008220 <digits+0x1e0>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>

0000000080001c26 <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80001c26:	711d                	addi	sp,sp,-96
    80001c28:	ec86                	sd	ra,88(sp)
    80001c2a:	e8a2                	sd	s0,80(sp)
    80001c2c:	e4a6                	sd	s1,72(sp)
    80001c2e:	e0ca                	sd	s2,64(sp)
    80001c30:	fc4e                	sd	s3,56(sp)
    80001c32:	f852                	sd	s4,48(sp)
    80001c34:	f456                	sd	s5,40(sp)
    80001c36:	f05a                	sd	s6,32(sp)
    80001c38:	ec5e                	sd	s7,24(sp)
    80001c3a:	e862                	sd	s8,16(sp)
    80001c3c:	e466                	sd	s9,8(sp)
    80001c3e:	e06a                	sd	s10,0(sp)
    80001c40:	1080                	addi	s0,sp,96
  struct proc *p;

  for (int i = 0; i<CPUS; i++){
    cpus_ll[i] = -1;
    80001c42:	00007717          	auipc	a4,0x7
    80001c46:	3e670713          	addi	a4,a4,998 # 80009028 <cpus_ll>
    80001c4a:	56fd                	li	a3,-1
    80001c4c:	c314                	sw	a3,0(a4)
    // cpu_usage[i] = 0;    // set initial cpu's admitted to 0
    cpus[i].admittedProcs = 0;
    80001c4e:	0000f797          	auipc	a5,0xf
    80001c52:	65278793          	addi	a5,a5,1618 # 800112a0 <cpus>
    80001c56:	0807b023          	sd	zero,128(a5)
    cpus_ll[i] = -1;
    80001c5a:	c354                	sw	a3,4(a4)
    cpus[i].admittedProcs = 0;
    80001c5c:	1007b423          	sd	zero,264(a5)
}
  initlock(&pid_lock, "nextpid");
    80001c60:	00006597          	auipc	a1,0x6
    80001c64:	5c858593          	addi	a1,a1,1480 # 80008228 <digits+0x1e8>
    80001c68:	00010517          	auipc	a0,0x10
    80001c6c:	a7850513          	addi	a0,a0,-1416 # 800116e0 <pid_lock>
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	ee4080e7          	jalr	-284(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c78:	00006597          	auipc	a1,0x6
    80001c7c:	5b858593          	addi	a1,a1,1464 # 80008230 <digits+0x1f0>
    80001c80:	00010517          	auipc	a0,0x10
    80001c84:	a7850513          	addi	a0,a0,-1416 # 800116f8 <wait_lock>
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	ecc080e7          	jalr	-308(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001c90:	00006597          	auipc	a1,0x6
    80001c94:	5b058593          	addi	a1,a1,1456 # 80008240 <digits+0x200>
    80001c98:	00010517          	auipc	a0,0x10
    80001c9c:	a7850513          	addi	a0,a0,-1416 # 80011710 <sleeping_head>
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	eb4080e7          	jalr	-332(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001ca8:	00006597          	auipc	a1,0x6
    80001cac:	5a858593          	addi	a1,a1,1448 # 80008250 <digits+0x210>
    80001cb0:	00010517          	auipc	a0,0x10
    80001cb4:	a7850513          	addi	a0,a0,-1416 # 80011728 <zombie_head>
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	e9c080e7          	jalr	-356(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001cc0:	00006597          	auipc	a1,0x6
    80001cc4:	5a058593          	addi	a1,a1,1440 # 80008260 <digits+0x220>
    80001cc8:	00010517          	auipc	a0,0x10
    80001ccc:	a7850513          	addi	a0,a0,-1416 # 80011740 <unused_head>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	e84080e7          	jalr	-380(ra) # 80000b54 <initlock>
  
  int i=0; //added
    80001cd8:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cda:	00010497          	auipc	s1,0x10
    80001cde:	abe48493          	addi	s1,s1,-1346 # 80011798 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001ce2:	8d26                	mv	s10,s1
    80001ce4:	00006c97          	auipc	s9,0x6
    80001ce8:	31ccbc83          	ld	s9,796(s9) # 80008000 <etext>
    80001cec:	040009b7          	lui	s3,0x4000
    80001cf0:	19fd                	addi	s3,s3,-1
    80001cf2:	09b2                	slli	s3,s3,0xc
      //added:
      p->state = UNUSED; 
      p->index = i;
      p->next = -1;
    80001cf4:	5c7d                	li	s8,-1
      p->cpu_num = 0;
      initlock(&p->lock, "proc");
    80001cf6:	00006b97          	auipc	s7,0x6
    80001cfa:	57ab8b93          	addi	s7,s7,1402 # 80008270 <digits+0x230>
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
    80001cfe:	00006b17          	auipc	s6,0x6
    80001d02:	57ab0b13          	addi	s6,s6,1402 # 80008278 <digits+0x238>
      i++;
      insert_to_list(p->index, &unused, &unused_head);
    80001d06:	00010a97          	auipc	s5,0x10
    80001d0a:	a3aa8a93          	addi	s5,s5,-1478 # 80011740 <unused_head>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0e:	00016a17          	auipc	s4,0x16
    80001d12:	c8aa0a13          	addi	s4,s4,-886 # 80017998 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001d16:	41a487b3          	sub	a5,s1,s10
    80001d1a:	878d                	srai	a5,a5,0x3
    80001d1c:	039787b3          	mul	a5,a5,s9
    80001d20:	2785                	addiw	a5,a5,1
    80001d22:	00d7979b          	slliw	a5,a5,0xd
    80001d26:	40f987b3          	sub	a5,s3,a5
    80001d2a:	f0bc                	sd	a5,96(s1)
      p->state = UNUSED; 
    80001d2c:	0004ac23          	sw	zero,24(s1)
      p->index = i;
    80001d30:	0324ac23          	sw	s2,56(s1)
      p->next = -1;
    80001d34:	0384ae23          	sw	s8,60(s1)
      p->cpu_num = 0;
    80001d38:	0204aa23          	sw	zero,52(s1)
      initlock(&p->lock, "proc");
    80001d3c:	85de                	mv	a1,s7
    80001d3e:	8526                	mv	a0,s1
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	e14080e7          	jalr	-492(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, name);
    80001d48:	85da                	mv	a1,s6
    80001d4a:	04048513          	addi	a0,s1,64
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	e06080e7          	jalr	-506(ra) # 80000b54 <initlock>
      i++;
    80001d56:	2905                	addiw	s2,s2,1
      insert_to_list(p->index, &unused, &unused_head);
    80001d58:	8656                	mv	a2,s5
    80001d5a:	00007597          	auipc	a1,0x7
    80001d5e:	b6a58593          	addi	a1,a1,-1174 # 800088c4 <unused>
    80001d62:	5c88                	lw	a0,56(s1)
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	d56080e7          	jalr	-682(ra) # 80001aba <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d6c:	18848493          	addi	s1,s1,392
    80001d70:	fb4493e3          	bne	s1,s4,80001d16 <procinit+0xf0>
  
  
  //printf("the head of the unused list is %d, and the value of next is:%d\n ",unused,proc[unused].next);
      
  //printf("finished procinit\n");
}
    80001d74:	60e6                	ld	ra,88(sp)
    80001d76:	6446                	ld	s0,80(sp)
    80001d78:	64a6                	ld	s1,72(sp)
    80001d7a:	6906                	ld	s2,64(sp)
    80001d7c:	79e2                	ld	s3,56(sp)
    80001d7e:	7a42                	ld	s4,48(sp)
    80001d80:	7aa2                	ld	s5,40(sp)
    80001d82:	7b02                	ld	s6,32(sp)
    80001d84:	6be2                	ld	s7,24(sp)
    80001d86:	6c42                	ld	s8,16(sp)
    80001d88:	6ca2                	ld	s9,8(sp)
    80001d8a:	6d02                	ld	s10,0(sp)
    80001d8c:	6125                	addi	sp,sp,96
    80001d8e:	8082                	ret

0000000080001d90 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001d90:	1141                	addi	sp,sp,-16
    80001d92:	e422                	sd	s0,8(sp)
    80001d94:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d96:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d98:	2501                	sext.w	a0,a0
    80001d9a:	6422                	ld	s0,8(sp)
    80001d9c:	0141                	addi	sp,sp,16
    80001d9e:	8082                	ret

0000000080001da0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001da0:	1141                	addi	sp,sp,-16
    80001da2:	e422                	sd	s0,8(sp)
    80001da4:	0800                	addi	s0,sp,16
    80001da6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001da8:	0007851b          	sext.w	a0,a5
    80001dac:	00451793          	slli	a5,a0,0x4
    80001db0:	97aa                	add	a5,a5,a0
    80001db2:	078e                	slli	a5,a5,0x3
  return c;
}
    80001db4:	0000f517          	auipc	a0,0xf
    80001db8:	4ec50513          	addi	a0,a0,1260 # 800112a0 <cpus>
    80001dbc:	953e                	add	a0,a0,a5
    80001dbe:	6422                	ld	s0,8(sp)
    80001dc0:	0141                	addi	sp,sp,16
    80001dc2:	8082                	ret

0000000080001dc4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001dc4:	1101                	addi	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	1000                	addi	s0,sp,32
  push_off();
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	dca080e7          	jalr	-566(ra) # 80000b98 <push_off>
    80001dd6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001dd8:	0007871b          	sext.w	a4,a5
    80001ddc:	00471793          	slli	a5,a4,0x4
    80001de0:	97ba                	add	a5,a5,a4
    80001de2:	078e                	slli	a5,a5,0x3
    80001de4:	0000f717          	auipc	a4,0xf
    80001de8:	4bc70713          	addi	a4,a4,1212 # 800112a0 <cpus>
    80001dec:	97ba                	add	a5,a5,a4
    80001dee:	6384                	ld	s1,0(a5)
  pop_off();
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	e5a080e7          	jalr	-422(ra) # 80000c4a <pop_off>
  return p;
}
    80001df8:	8526                	mv	a0,s1
    80001dfa:	60e2                	ld	ra,24(sp)
    80001dfc:	6442                	ld	s0,16(sp)
    80001dfe:	64a2                	ld	s1,8(sp)
    80001e00:	6105                	addi	sp,sp,32
    80001e02:	8082                	ret

0000000080001e04 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e04:	1141                	addi	sp,sp,-16
    80001e06:	e406                	sd	ra,8(sp)
    80001e08:	e022                	sd	s0,0(sp)
    80001e0a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	fb8080e7          	jalr	-72(ra) # 80001dc4 <myproc>
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	e96080e7          	jalr	-362(ra) # 80000caa <release>


  if (first) {
    80001e1c:	00007797          	auipc	a5,0x7
    80001e20:	aa47a783          	lw	a5,-1372(a5) # 800088c0 <first.1749>
    80001e24:	eb89                	bnez	a5,80001e36 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e26:	00001097          	auipc	ra,0x1
    80001e2a:	062080e7          	jalr	98(ra) # 80002e88 <usertrapret>
}
    80001e2e:	60a2                	ld	ra,8(sp)
    80001e30:	6402                	ld	s0,0(sp)
    80001e32:	0141                	addi	sp,sp,16
    80001e34:	8082                	ret
    first = 0;
    80001e36:	00007797          	auipc	a5,0x7
    80001e3a:	a807a523          	sw	zero,-1398(a5) # 800088c0 <first.1749>
    fsinit(ROOTDEV);
    80001e3e:	4505                	li	a0,1
    80001e40:	00002097          	auipc	ra,0x2
    80001e44:	e06080e7          	jalr	-506(ra) # 80003c46 <fsinit>
    80001e48:	bff9                	j	80001e26 <forkret+0x22>

0000000080001e4a <inc_cpu_usage>:
inc_cpu_usage(int cpu_num){
    80001e4a:	1101                	addi	sp,sp,-32
    80001e4c:	ec06                	sd	ra,24(sp)
    80001e4e:	e822                	sd	s0,16(sp)
    80001e50:	e426                	sd	s1,8(sp)
    80001e52:	e04a                	sd	s2,0(sp)
    80001e54:	1000                	addi	s0,sp,32
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001e56:	00451493          	slli	s1,a0,0x4
    80001e5a:	94aa                	add	s1,s1,a0
    80001e5c:	048e                	slli	s1,s1,0x3
    80001e5e:	0000f797          	auipc	a5,0xf
    80001e62:	4c278793          	addi	a5,a5,1218 # 80011320 <cpus+0x80>
    80001e66:	94be                	add	s1,s1,a5
    usage = c->admittedProcs;
    80001e68:	00451913          	slli	s2,a0,0x4
    80001e6c:	954a                	add	a0,a0,s2
    80001e6e:	050e                	slli	a0,a0,0x3
    80001e70:	0000f917          	auipc	s2,0xf
    80001e74:	43090913          	addi	s2,s2,1072 # 800112a0 <cpus>
    80001e78:	992a                	add	s2,s2,a0
    80001e7a:	08093583          	ld	a1,128(s2)
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001e7e:	0015861b          	addiw	a2,a1,1
    80001e82:	2581                	sext.w	a1,a1
    80001e84:	8526                	mv	a0,s1
    80001e86:	00005097          	auipc	ra,0x5
    80001e8a:	bc0080e7          	jalr	-1088(ra) # 80006a46 <cas>
    80001e8e:	f575                	bnez	a0,80001e7a <inc_cpu_usage+0x30>
}
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6902                	ld	s2,0(sp)
    80001e98:	6105                	addi	sp,sp,32
    80001e9a:	8082                	ret

0000000080001e9c <allocpid>:
allocpid() { //changed as ordered in task 2
    80001e9c:	1101                	addi	sp,sp,-32
    80001e9e:	ec06                	sd	ra,24(sp)
    80001ea0:	e822                	sd	s0,16(sp)
    80001ea2:	e426                	sd	s1,8(sp)
    80001ea4:	e04a                	sd	s2,0(sp)
    80001ea6:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001ea8:	00007917          	auipc	s2,0x7
    80001eac:	a2890913          	addi	s2,s2,-1496 # 800088d0 <nextpid>
    80001eb0:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001eb4:	0014861b          	addiw	a2,s1,1
    80001eb8:	85a6                	mv	a1,s1
    80001eba:	854a                	mv	a0,s2
    80001ebc:	00005097          	auipc	ra,0x5
    80001ec0:	b8a080e7          	jalr	-1142(ra) # 80006a46 <cas>
    80001ec4:	f575                	bnez	a0,80001eb0 <allocpid+0x14>
}
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	60e2                	ld	ra,24(sp)
    80001eca:	6442                	ld	s0,16(sp)
    80001ecc:	64a2                	ld	s1,8(sp)
    80001ece:	6902                	ld	s2,0(sp)
    80001ed0:	6105                	addi	sp,sp,32
    80001ed2:	8082                	ret

0000000080001ed4 <proc_pagetable>:
{
    80001ed4:	1101                	addi	sp,sp,-32
    80001ed6:	ec06                	sd	ra,24(sp)
    80001ed8:	e822                	sd	s0,16(sp)
    80001eda:	e426                	sd	s1,8(sp)
    80001edc:	e04a                	sd	s2,0(sp)
    80001ede:	1000                	addi	s0,sp,32
    80001ee0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	47c080e7          	jalr	1148(ra) # 8000135e <uvmcreate>
    80001eea:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001eec:	c121                	beqz	a0,80001f2c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001eee:	4729                	li	a4,10
    80001ef0:	00005697          	auipc	a3,0x5
    80001ef4:	11068693          	addi	a3,a3,272 # 80007000 <_trampoline>
    80001ef8:	6605                	lui	a2,0x1
    80001efa:	040005b7          	lui	a1,0x4000
    80001efe:	15fd                	addi	a1,a1,-1
    80001f00:	05b2                	slli	a1,a1,0xc
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	1d2080e7          	jalr	466(ra) # 800010d4 <mappages>
    80001f0a:	02054863          	bltz	a0,80001f3a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f0e:	4719                	li	a4,6
    80001f10:	07893683          	ld	a3,120(s2)
    80001f14:	6605                	lui	a2,0x1
    80001f16:	020005b7          	lui	a1,0x2000
    80001f1a:	15fd                	addi	a1,a1,-1
    80001f1c:	05b6                	slli	a1,a1,0xd
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	1b4080e7          	jalr	436(ra) # 800010d4 <mappages>
    80001f28:	02054163          	bltz	a0,80001f4a <proc_pagetable+0x76>
}
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	60e2                	ld	ra,24(sp)
    80001f30:	6442                	ld	s0,16(sp)
    80001f32:	64a2                	ld	s1,8(sp)
    80001f34:	6902                	ld	s2,0(sp)
    80001f36:	6105                	addi	sp,sp,32
    80001f38:	8082                	ret
    uvmfree(pagetable, 0);
    80001f3a:	4581                	li	a1,0
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	61c080e7          	jalr	1564(ra) # 8000155a <uvmfree>
    return 0;
    80001f46:	4481                	li	s1,0
    80001f48:	b7d5                	j	80001f2c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f4a:	4681                	li	a3,0
    80001f4c:	4605                	li	a2,1
    80001f4e:	040005b7          	lui	a1,0x4000
    80001f52:	15fd                	addi	a1,a1,-1
    80001f54:	05b2                	slli	a1,a1,0xc
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	342080e7          	jalr	834(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001f60:	4581                	li	a1,0
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	5f6080e7          	jalr	1526(ra) # 8000155a <uvmfree>
    return 0;
    80001f6c:	4481                	li	s1,0
    80001f6e:	bf7d                	j	80001f2c <proc_pagetable+0x58>

0000000080001f70 <proc_freepagetable>:
{
    80001f70:	1101                	addi	sp,sp,-32
    80001f72:	ec06                	sd	ra,24(sp)
    80001f74:	e822                	sd	s0,16(sp)
    80001f76:	e426                	sd	s1,8(sp)
    80001f78:	e04a                	sd	s2,0(sp)
    80001f7a:	1000                	addi	s0,sp,32
    80001f7c:	84aa                	mv	s1,a0
    80001f7e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f80:	4681                	li	a3,0
    80001f82:	4605                	li	a2,1
    80001f84:	040005b7          	lui	a1,0x4000
    80001f88:	15fd                	addi	a1,a1,-1
    80001f8a:	05b2                	slli	a1,a1,0xc
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	30e080e7          	jalr	782(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f94:	4681                	li	a3,0
    80001f96:	4605                	li	a2,1
    80001f98:	020005b7          	lui	a1,0x2000
    80001f9c:	15fd                	addi	a1,a1,-1
    80001f9e:	05b6                	slli	a1,a1,0xd
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	2f8080e7          	jalr	760(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001faa:	85ca                	mv	a1,s2
    80001fac:	8526                	mv	a0,s1
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	5ac080e7          	jalr	1452(ra) # 8000155a <uvmfree>
}
    80001fb6:	60e2                	ld	ra,24(sp)
    80001fb8:	6442                	ld	s0,16(sp)
    80001fba:	64a2                	ld	s1,8(sp)
    80001fbc:	6902                	ld	s2,0(sp)
    80001fbe:	6105                	addi	sp,sp,32
    80001fc0:	8082                	ret

0000000080001fc2 <freeproc>:
{
    80001fc2:	1101                	addi	sp,sp,-32
    80001fc4:	ec06                	sd	ra,24(sp)
    80001fc6:	e822                	sd	s0,16(sp)
    80001fc8:	e426                	sd	s1,8(sp)
    80001fca:	1000                	addi	s0,sp,32
    80001fcc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fce:	7d28                	ld	a0,120(a0)
    80001fd0:	c509                	beqz	a0,80001fda <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	a26080e7          	jalr	-1498(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001fda:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001fde:	78a8                	ld	a0,112(s1)
    80001fe0:	c511                	beqz	a0,80001fec <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001fe2:	74ac                	ld	a1,104(s1)
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	f8c080e7          	jalr	-116(ra) # 80001f70 <proc_freepagetable>
  p->pagetable = 0;
    80001fec:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001ff0:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001ff4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ff8:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001ffc:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002000:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002004:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002008:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index, &zombie, &zombie_head);
    8000200c:	0000f617          	auipc	a2,0xf
    80002010:	71c60613          	addi	a2,a2,1820 # 80011728 <zombie_head>
    80002014:	00007597          	auipc	a1,0x7
    80002018:	8b458593          	addi	a1,a1,-1868 # 800088c8 <zombie>
    8000201c:	5c88                	lw	a0,56(s1)
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	862080e7          	jalr	-1950(ra) # 80001880 <remove_from_list>
  p->state = UNUSED;
    80002026:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index, &unused, &unused_head);
    8000202a:	0000f617          	auipc	a2,0xf
    8000202e:	71660613          	addi	a2,a2,1814 # 80011740 <unused_head>
    80002032:	00007597          	auipc	a1,0x7
    80002036:	89258593          	addi	a1,a1,-1902 # 800088c4 <unused>
    8000203a:	5c88                	lw	a0,56(s1)
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	a7e080e7          	jalr	-1410(ra) # 80001aba <insert_to_list>
}
    80002044:	60e2                	ld	ra,24(sp)
    80002046:	6442                	ld	s0,16(sp)
    80002048:	64a2                	ld	s1,8(sp)
    8000204a:	6105                	addi	sp,sp,32
    8000204c:	8082                	ret

000000008000204e <allocproc>:
{
    8000204e:	7179                	addi	sp,sp,-48
    80002050:	f406                	sd	ra,40(sp)
    80002052:	f022                	sd	s0,32(sp)
    80002054:	ec26                	sd	s1,24(sp)
    80002056:	e84a                	sd	s2,16(sp)
    80002058:	e44e                	sd	s3,8(sp)
    8000205a:	e052                	sd	s4,0(sp)
    8000205c:	1800                	addi	s0,sp,48
  if(unused != -1){
    8000205e:	00007917          	auipc	s2,0x7
    80002062:	86692903          	lw	s2,-1946(s2) # 800088c4 <unused>
    80002066:	57fd                	li	a5,-1
  return 0;
    80002068:	4481                	li	s1,0
  if(unused != -1){
    8000206a:	0af90b63          	beq	s2,a5,80002120 <allocproc+0xd2>
    p = &proc[unused];
    8000206e:	18800993          	li	s3,392
    80002072:	033909b3          	mul	s3,s2,s3
    80002076:	0000f497          	auipc	s1,0xf
    8000207a:	72248493          	addi	s1,s1,1826 # 80011798 <proc>
    8000207e:	94ce                	add	s1,s1,s3
    remove_from_list(p->index,&unused, &unused_head);
    80002080:	0000f617          	auipc	a2,0xf
    80002084:	6c060613          	addi	a2,a2,1728 # 80011740 <unused_head>
    80002088:	00007597          	auipc	a1,0x7
    8000208c:	83c58593          	addi	a1,a1,-1988 # 800088c4 <unused>
    80002090:	5c88                	lw	a0,56(s1)
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	7ee080e7          	jalr	2030(ra) # 80001880 <remove_from_list>
    acquire(&p->lock);
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	b48080e7          	jalr	-1208(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800020a4:	00000097          	auipc	ra,0x0
    800020a8:	df8080e7          	jalr	-520(ra) # 80001e9c <allocpid>
    800020ac:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020ae:	4785                	li	a5,1
    800020b0:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	a42080e7          	jalr	-1470(ra) # 80000af4 <kalloc>
    800020ba:	8a2a                	mv	s4,a0
    800020bc:	fca8                	sd	a0,120(s1)
    800020be:	c935                	beqz	a0,80002132 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    800020c0:	8526                	mv	a0,s1
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	e12080e7          	jalr	-494(ra) # 80001ed4 <proc_pagetable>
    800020ca:	8a2a                	mv	s4,a0
    800020cc:	18800793          	li	a5,392
    800020d0:	02f90733          	mul	a4,s2,a5
    800020d4:	0000f797          	auipc	a5,0xf
    800020d8:	6c478793          	addi	a5,a5,1732 # 80011798 <proc>
    800020dc:	97ba                	add	a5,a5,a4
    800020de:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800020e0:	c52d                	beqz	a0,8000214a <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    800020e2:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    800020e6:	0000fa17          	auipc	s4,0xf
    800020ea:	6b2a0a13          	addi	s4,s4,1714 # 80011798 <proc>
    800020ee:	07000613          	li	a2,112
    800020f2:	4581                	li	a1,0
    800020f4:	9552                	add	a0,a0,s4
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	c0e080e7          	jalr	-1010(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    800020fe:	18800793          	li	a5,392
    80002102:	02f90933          	mul	s2,s2,a5
    80002106:	9952                	add	s2,s2,s4
    80002108:	00000797          	auipc	a5,0x0
    8000210c:	cfc78793          	addi	a5,a5,-772 # 80001e04 <forkret>
    80002110:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002114:	06093783          	ld	a5,96(s2)
    80002118:	6705                	lui	a4,0x1
    8000211a:	97ba                	add	a5,a5,a4
    8000211c:	08f93423          	sd	a5,136(s2)
}
    80002120:	8526                	mv	a0,s1
    80002122:	70a2                	ld	ra,40(sp)
    80002124:	7402                	ld	s0,32(sp)
    80002126:	64e2                	ld	s1,24(sp)
    80002128:	6942                	ld	s2,16(sp)
    8000212a:	69a2                	ld	s3,8(sp)
    8000212c:	6a02                	ld	s4,0(sp)
    8000212e:	6145                	addi	sp,sp,48
    80002130:	8082                	ret
    freeproc(p);
    80002132:	8526                	mv	a0,s1
    80002134:	00000097          	auipc	ra,0x0
    80002138:	e8e080e7          	jalr	-370(ra) # 80001fc2 <freeproc>
    release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b6c080e7          	jalr	-1172(ra) # 80000caa <release>
    return 0;
    80002146:	84d2                	mv	s1,s4
    80002148:	bfe1                	j	80002120 <allocproc+0xd2>
    freeproc(p);
    8000214a:	8526                	mv	a0,s1
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	e76080e7          	jalr	-394(ra) # 80001fc2 <freeproc>
    release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b54080e7          	jalr	-1196(ra) # 80000caa <release>
    return 0;
    8000215e:	84d2                	mv	s1,s4
    80002160:	b7c1                	j	80002120 <allocproc+0xd2>

0000000080002162 <userinit>:
{
    80002162:	1101                	addi	sp,sp,-32
    80002164:	ec06                	sd	ra,24(sp)
    80002166:	e822                	sd	s0,16(sp)
    80002168:	e426                	sd	s1,8(sp)
    8000216a:	1000                	addi	s0,sp,32
  p = allocproc();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	ee2080e7          	jalr	-286(ra) # 8000204e <allocproc>
    80002174:	84aa                	mv	s1,a0
  initproc = p;
    80002176:	00007797          	auipc	a5,0x7
    8000217a:	eaa7bd23          	sd	a0,-326(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000217e:	03400613          	li	a2,52
    80002182:	00006597          	auipc	a1,0x6
    80002186:	75e58593          	addi	a1,a1,1886 # 800088e0 <initcode>
    8000218a:	7928                	ld	a0,112(a0)
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	200080e7          	jalr	512(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    80002194:	6785                	lui	a5,0x1
    80002196:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80002198:	7cb8                	ld	a4,120(s1)
    8000219a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000219e:	7cb8                	ld	a4,120(s1)
    800021a0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021a2:	4641                	li	a2,16
    800021a4:	00006597          	auipc	a1,0x6
    800021a8:	0dc58593          	addi	a1,a1,220 # 80008280 <digits+0x240>
    800021ac:	17848513          	addi	a0,s1,376
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ca6080e7          	jalr	-858(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0d850513          	addi	a0,a0,216 # 80008290 <digits+0x250>
    800021c0:	00002097          	auipc	ra,0x2
    800021c4:	4b4080e7          	jalr	1204(ra) # 80004674 <namei>
    800021c8:	16a4b823          	sd	a0,368(s1)
  insert_to_list(p->index, &cpus_ll[0], &cpus_head[0]);
    800021cc:	0000f617          	auipc	a2,0xf
    800021d0:	58c60613          	addi	a2,a2,1420 # 80011758 <cpus_head>
    800021d4:	00007597          	auipc	a1,0x7
    800021d8:	e5458593          	addi	a1,a1,-428 # 80009028 <cpus_ll>
    800021dc:	5c88                	lw	a0,56(s1)
    800021de:	00000097          	auipc	ra,0x0
    800021e2:	8dc080e7          	jalr	-1828(ra) # 80001aba <insert_to_list>
  inc_cpu_usage(0);
    800021e6:	4501                	li	a0,0
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	c62080e7          	jalr	-926(ra) # 80001e4a <inc_cpu_usage>
  p->state = RUNNABLE;
    800021f0:	478d                	li	a5,3
    800021f2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	ab4080e7          	jalr	-1356(ra) # 80000caa <release>
}
    800021fe:	60e2                	ld	ra,24(sp)
    80002200:	6442                	ld	s0,16(sp)
    80002202:	64a2                	ld	s1,8(sp)
    80002204:	6105                	addi	sp,sp,32
    80002206:	8082                	ret

0000000080002208 <growproc>:
{
    80002208:	1101                	addi	sp,sp,-32
    8000220a:	ec06                	sd	ra,24(sp)
    8000220c:	e822                	sd	s0,16(sp)
    8000220e:	e426                	sd	s1,8(sp)
    80002210:	e04a                	sd	s2,0(sp)
    80002212:	1000                	addi	s0,sp,32
    80002214:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	bae080e7          	jalr	-1106(ra) # 80001dc4 <myproc>
    8000221e:	892a                	mv	s2,a0
  sz = p->sz;
    80002220:	752c                	ld	a1,104(a0)
    80002222:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002226:	00904f63          	bgtz	s1,80002244 <growproc+0x3c>
  } else if(n < 0){
    8000222a:	0204cc63          	bltz	s1,80002262 <growproc+0x5a>
  p->sz = sz;
    8000222e:	1602                	slli	a2,a2,0x20
    80002230:	9201                	srli	a2,a2,0x20
    80002232:	06c93423          	sd	a2,104(s2)
  return 0;
    80002236:	4501                	li	a0,0
}
    80002238:	60e2                	ld	ra,24(sp)
    8000223a:	6442                	ld	s0,16(sp)
    8000223c:	64a2                	ld	s1,8(sp)
    8000223e:	6902                	ld	s2,0(sp)
    80002240:	6105                	addi	sp,sp,32
    80002242:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002244:	9e25                	addw	a2,a2,s1
    80002246:	1602                	slli	a2,a2,0x20
    80002248:	9201                	srli	a2,a2,0x20
    8000224a:	1582                	slli	a1,a1,0x20
    8000224c:	9181                	srli	a1,a1,0x20
    8000224e:	7928                	ld	a0,112(a0)
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	1f6080e7          	jalr	502(ra) # 80001446 <uvmalloc>
    80002258:	0005061b          	sext.w	a2,a0
    8000225c:	fa69                	bnez	a2,8000222e <growproc+0x26>
      return -1;
    8000225e:	557d                	li	a0,-1
    80002260:	bfe1                	j	80002238 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002262:	9e25                	addw	a2,a2,s1
    80002264:	1602                	slli	a2,a2,0x20
    80002266:	9201                	srli	a2,a2,0x20
    80002268:	1582                	slli	a1,a1,0x20
    8000226a:	9181                	srli	a1,a1,0x20
    8000226c:	7928                	ld	a0,112(a0)
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	190080e7          	jalr	400(ra) # 800013fe <uvmdealloc>
    80002276:	0005061b          	sext.w	a2,a0
    8000227a:	bf55                	j	8000222e <growproc+0x26>

000000008000227c <fork>:
{
    8000227c:	7179                	addi	sp,sp,-48
    8000227e:	f406                	sd	ra,40(sp)
    80002280:	f022                	sd	s0,32(sp)
    80002282:	ec26                	sd	s1,24(sp)
    80002284:	e84a                	sd	s2,16(sp)
    80002286:	e44e                	sd	s3,8(sp)
    80002288:	e052                	sd	s4,0(sp)
    8000228a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	b38080e7          	jalr	-1224(ra) # 80001dc4 <myproc>
    80002294:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	db8080e7          	jalr	-584(ra) # 8000204e <allocproc>
    8000229e:	16050863          	beqz	a0,8000240e <fork+0x192>
    800022a2:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022a4:	0689b603          	ld	a2,104(s3)
    800022a8:	792c                	ld	a1,112(a0)
    800022aa:	0709b503          	ld	a0,112(s3)
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	2e4080e7          	jalr	740(ra) # 80001592 <uvmcopy>
    800022b6:	04054663          	bltz	a0,80002302 <fork+0x86>
  np->sz = p->sz;
    800022ba:	0689b783          	ld	a5,104(s3)
    800022be:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800022c2:	0789b683          	ld	a3,120(s3)
    800022c6:	87b6                	mv	a5,a3
    800022c8:	07893703          	ld	a4,120(s2)
    800022cc:	12068693          	addi	a3,a3,288
    800022d0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022d4:	6788                	ld	a0,8(a5)
    800022d6:	6b8c                	ld	a1,16(a5)
    800022d8:	6f90                	ld	a2,24(a5)
    800022da:	01073023          	sd	a6,0(a4)
    800022de:	e708                	sd	a0,8(a4)
    800022e0:	eb0c                	sd	a1,16(a4)
    800022e2:	ef10                	sd	a2,24(a4)
    800022e4:	02078793          	addi	a5,a5,32
    800022e8:	02070713          	addi	a4,a4,32
    800022ec:	fed792e3          	bne	a5,a3,800022d0 <fork+0x54>
  np->trapframe->a0 = 0;
    800022f0:	07893783          	ld	a5,120(s2)
    800022f4:	0607b823          	sd	zero,112(a5)
    800022f8:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    800022fc:	17000a13          	li	s4,368
    80002300:	a03d                	j	8000232e <fork+0xb2>
    freeproc(np);
    80002302:	854a                	mv	a0,s2
    80002304:	00000097          	auipc	ra,0x0
    80002308:	cbe080e7          	jalr	-834(ra) # 80001fc2 <freeproc>
    release(&np->lock);
    8000230c:	854a                	mv	a0,s2
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	99c080e7          	jalr	-1636(ra) # 80000caa <release>
    return -1;
    80002316:	5a7d                	li	s4,-1
    80002318:	a0d5                	j	800023fc <fork+0x180>
      np->ofile[i] = filedup(p->ofile[i]);
    8000231a:	00003097          	auipc	ra,0x3
    8000231e:	9f0080e7          	jalr	-1552(ra) # 80004d0a <filedup>
    80002322:	009907b3          	add	a5,s2,s1
    80002326:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002328:	04a1                	addi	s1,s1,8
    8000232a:	01448763          	beq	s1,s4,80002338 <fork+0xbc>
    if(p->ofile[i])
    8000232e:	009987b3          	add	a5,s3,s1
    80002332:	6388                	ld	a0,0(a5)
    80002334:	f17d                	bnez	a0,8000231a <fork+0x9e>
    80002336:	bfcd                	j	80002328 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002338:	1709b503          	ld	a0,368(s3)
    8000233c:	00002097          	auipc	ra,0x2
    80002340:	b44080e7          	jalr	-1212(ra) # 80003e80 <idup>
    80002344:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002348:	17890493          	addi	s1,s2,376
    8000234c:	4641                	li	a2,16
    8000234e:	17898593          	addi	a1,s3,376
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	b02080e7          	jalr	-1278(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    8000235c:	03092a03          	lw	s4,48(s2)
  np->cpu_num = p->cpu_num; //giving the child it's parent's cpu_num
    80002360:	0349a783          	lw	a5,52(s3)
    80002364:	02f92a23          	sw	a5,52(s2)
  int cpui = leastUsedCPU();
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	4fa080e7          	jalr	1274(ra) # 80001862 <leastUsedCPU>
  np->cpu_num = cpui;
    80002370:	02a92a23          	sw	a0,52(s2)
  inc_cpu_usage(cpui);
    80002374:	00000097          	auipc	ra,0x0
    80002378:	ad6080e7          	jalr	-1322(ra) # 80001e4a <inc_cpu_usage>
  initlock(&np->linked_list_lock, np->name);
    8000237c:	85a6                	mv	a1,s1
    8000237e:	04090513          	addi	a0,s2,64
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	7d2080e7          	jalr	2002(ra) # 80000b54 <initlock>
  release(&np->lock);
    8000238a:	854a                	mv	a0,s2
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	91e080e7          	jalr	-1762(ra) # 80000caa <release>
  acquire(&wait_lock);
    80002394:	0000f497          	auipc	s1,0xf
    80002398:	36448493          	addi	s1,s1,868 # 800116f8 <wait_lock>
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	846080e7          	jalr	-1978(ra) # 80000be4 <acquire>
  np->parent = p;
    800023a6:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	8fe080e7          	jalr	-1794(ra) # 80000caa <release>
  acquire(&np->lock);
    800023b4:	854a                	mv	a0,s2
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	82e080e7          	jalr	-2002(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023be:	478d                	li	a5,3
    800023c0:	00f92c23          	sw	a5,24(s2)
  insert_to_list(np->index, &cpus_ll[np->cpu_num], &cpus_head[np->cpu_num]);
    800023c4:	03492583          	lw	a1,52(s2)
    800023c8:	00159793          	slli	a5,a1,0x1
    800023cc:	97ae                	add	a5,a5,a1
    800023ce:	078e                	slli	a5,a5,0x3
    800023d0:	058a                	slli	a1,a1,0x2
    800023d2:	0000f617          	auipc	a2,0xf
    800023d6:	38660613          	addi	a2,a2,902 # 80011758 <cpus_head>
    800023da:	963e                	add	a2,a2,a5
    800023dc:	00007797          	auipc	a5,0x7
    800023e0:	c4c78793          	addi	a5,a5,-948 # 80009028 <cpus_ll>
    800023e4:	95be                	add	a1,a1,a5
    800023e6:	03892503          	lw	a0,56(s2)
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	6d0080e7          	jalr	1744(ra) # 80001aba <insert_to_list>
  release(&np->lock);
    800023f2:	854a                	mv	a0,s2
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	8b6080e7          	jalr	-1866(ra) # 80000caa <release>
}
    800023fc:	8552                	mv	a0,s4
    800023fe:	70a2                	ld	ra,40(sp)
    80002400:	7402                	ld	s0,32(sp)
    80002402:	64e2                	ld	s1,24(sp)
    80002404:	6942                	ld	s2,16(sp)
    80002406:	69a2                	ld	s3,8(sp)
    80002408:	6a02                	ld	s4,0(sp)
    8000240a:	6145                	addi	sp,sp,48
    8000240c:	8082                	ret
    return -1;
    8000240e:	5a7d                	li	s4,-1
    80002410:	b7f5                	j	800023fc <fork+0x180>

0000000080002412 <scheduler>:
{
    80002412:	711d                	addi	sp,sp,-96
    80002414:	ec86                	sd	ra,88(sp)
    80002416:	e8a2                	sd	s0,80(sp)
    80002418:	e4a6                	sd	s1,72(sp)
    8000241a:	e0ca                	sd	s2,64(sp)
    8000241c:	fc4e                	sd	s3,56(sp)
    8000241e:	f852                	sd	s4,48(sp)
    80002420:	f456                	sd	s5,40(sp)
    80002422:	f05a                	sd	s6,32(sp)
    80002424:	ec5e                	sd	s7,24(sp)
    80002426:	e862                	sd	s8,16(sp)
    80002428:	e466                	sd	s9,8(sp)
    8000242a:	1080                	addi	s0,sp,96
    8000242c:	8712                	mv	a4,tp
  int id = r_tp();
    8000242e:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002430:	0000fa97          	auipc	s5,0xf
    80002434:	e70a8a93          	addi	s5,s5,-400 # 800112a0 <cpus>
    80002438:	00471793          	slli	a5,a4,0x4
    8000243c:	00e786b3          	add	a3,a5,a4
    80002440:	068e                	slli	a3,a3,0x3
    80002442:	96d6                	add	a3,a3,s5
    80002444:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    80002448:	97ba                	add	a5,a5,a4
    8000244a:	078e                	slli	a5,a5,0x3
    8000244c:	07a1                	addi	a5,a5,8
    8000244e:	9abe                	add	s5,s5,a5
      p = &proc[cpus_ll[cpuid()]];
    80002450:	0000f917          	auipc	s2,0xf
    80002454:	34890913          	addi	s2,s2,840 # 80011798 <proc>
      c->proc = p;
    80002458:	89b6                	mv	s3,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000245a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000245e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002462:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002466:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002468:	2781                	sext.w	a5,a5
    8000246a:	078a                	slli	a5,a5,0x2
    8000246c:	00007717          	auipc	a4,0x7
    80002470:	bbc70713          	addi	a4,a4,-1092 # 80009028 <cpus_ll>
    80002474:	97ba                	add	a5,a5,a4
    80002476:	4398                	lw	a4,0(a5)
    80002478:	57fd                	li	a5,-1
    8000247a:	fef700e3          	beq	a4,a5,8000245a <scheduler+0x48>
      p = &proc[cpus_ll[cpuid()]];
    8000247e:	00007497          	auipc	s1,0x7
    80002482:	baa48493          	addi	s1,s1,-1110 # 80009028 <cpus_ll>
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    80002486:	0000fa17          	auipc	s4,0xf
    8000248a:	2d2a0a13          	addi	s4,s4,722 # 80011758 <cpus_head>
    8000248e:	a0b9                	j	800024dc <scheduler+0xca>
        panic("could not remove");
    80002490:	00006517          	auipc	a0,0x6
    80002494:	e0850513          	addi	a0,a0,-504 # 80008298 <digits+0x258>
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	0a6080e7          	jalr	166(ra) # 8000053e <panic>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    800024a0:	034ba583          	lw	a1,52(s7)
    800024a4:	00159613          	slli	a2,a1,0x1
    800024a8:	962e                	add	a2,a2,a1
    800024aa:	060e                	slli	a2,a2,0x3
    800024ac:	058a                	slli	a1,a1,0x2
    800024ae:	9652                	add	a2,a2,s4
    800024b0:	95a6                	add	a1,a1,s1
    800024b2:	038ba503          	lw	a0,56(s7)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	604080e7          	jalr	1540(ra) # 80001aba <insert_to_list>
      c->proc = 0;
    800024be:	0009b023          	sd	zero,0(s3)
      release(&p->lock);
    800024c2:	8562                	mv	a0,s8
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	7e6080e7          	jalr	2022(ra) # 80000caa <release>
    800024cc:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800024ce:	2781                	sext.w	a5,a5
    800024d0:	078a                	slli	a5,a5,0x2
    800024d2:	97a6                	add	a5,a5,s1
    800024d4:	4398                	lw	a4,0(a5)
    800024d6:	57fd                	li	a5,-1
    800024d8:	f8f701e3          	beq	a4,a5,8000245a <scheduler+0x48>
    800024dc:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    800024de:	2781                	sext.w	a5,a5
    800024e0:	078a                	slli	a5,a5,0x2
    800024e2:	97a6                	add	a5,a5,s1
    800024e4:	0007ac83          	lw	s9,0(a5)
    800024e8:	18800b13          	li	s6,392
    800024ec:	036c8b33          	mul	s6,s9,s6
    800024f0:	012b0c33          	add	s8,s6,s2
      acquire(&p->lock);
    800024f4:	8562                	mv	a0,s8
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	6ee080e7          	jalr	1774(ra) # 80000be4 <acquire>
    800024fe:	8592                	mv	a1,tp
    80002500:	8612                	mv	a2,tp
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    80002502:	0006079b          	sext.w	a5,a2
    80002506:	00179613          	slli	a2,a5,0x1
    8000250a:	963e                	add	a2,a2,a5
    8000250c:	060e                	slli	a2,a2,0x3
    8000250e:	2581                	sext.w	a1,a1
    80002510:	058a                	slli	a1,a1,0x2
    80002512:	9652                	add	a2,a2,s4
    80002514:	95a6                	add	a1,a1,s1
    80002516:	038c2503          	lw	a0,56(s8)
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	366080e7          	jalr	870(ra) # 80001880 <remove_from_list>
      if(removed == -1)
    80002522:	57fd                	li	a5,-1
    80002524:	f6f506e3          	beq	a0,a5,80002490 <scheduler+0x7e>
      p->state = RUNNING;
    80002528:	18800b93          	li	s7,392
    8000252c:	037c8bb3          	mul	s7,s9,s7
    80002530:	9bca                	add	s7,s7,s2
    80002532:	4791                	li	a5,4
    80002534:	00fbac23          	sw	a5,24(s7)
      c->proc = p;
    80002538:	0189b023          	sd	s8,0(s3)
      swtch(&c->context, &p->context);
    8000253c:	080b0593          	addi	a1,s6,128
    80002540:	95ca                	add	a1,a1,s2
    80002542:	8556                	mv	a0,s5
    80002544:	00001097          	auipc	ra,0x1
    80002548:	89a080e7          	jalr	-1894(ra) # 80002dde <swtch>
      if(p->state != ZOMBIE){
    8000254c:	018ba703          	lw	a4,24(s7)
    80002550:	4795                	li	a5,5
    80002552:	f6f706e3          	beq	a4,a5,800024be <scheduler+0xac>
    80002556:	b7a9                	j	800024a0 <scheduler+0x8e>

0000000080002558 <sched>:
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002566:	00000097          	auipc	ra,0x0
    8000256a:	85e080e7          	jalr	-1954(ra) # 80001dc4 <myproc>
    8000256e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	5fa080e7          	jalr	1530(ra) # 80000b6a <holding>
    80002578:	c559                	beqz	a0,80002606 <sched+0xae>
    8000257a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    8000257c:	0007871b          	sext.w	a4,a5
    80002580:	00471793          	slli	a5,a4,0x4
    80002584:	97ba                	add	a5,a5,a4
    80002586:	078e                	slli	a5,a5,0x3
    80002588:	0000f717          	auipc	a4,0xf
    8000258c:	d1870713          	addi	a4,a4,-744 # 800112a0 <cpus>
    80002590:	97ba                	add	a5,a5,a4
    80002592:	5fb8                	lw	a4,120(a5)
    80002594:	4785                	li	a5,1
    80002596:	08f71063          	bne	a4,a5,80002616 <sched+0xbe>
  if(p->state == RUNNING)
    8000259a:	4c98                	lw	a4,24(s1)
    8000259c:	4791                	li	a5,4
    8000259e:	08f70463          	beq	a4,a5,80002626 <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025a2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025a6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025a8:	e7d9                	bnez	a5,80002636 <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025aa:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025ac:	0000f917          	auipc	s2,0xf
    800025b0:	cf490913          	addi	s2,s2,-780 # 800112a0 <cpus>
    800025b4:	0007871b          	sext.w	a4,a5
    800025b8:	00471793          	slli	a5,a4,0x4
    800025bc:	97ba                	add	a5,a5,a4
    800025be:	078e                	slli	a5,a5,0x3
    800025c0:	97ca                	add	a5,a5,s2
    800025c2:	07c7a983          	lw	s3,124(a5)
    800025c6:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800025c8:	0005879b          	sext.w	a5,a1
    800025cc:	00479593          	slli	a1,a5,0x4
    800025d0:	95be                	add	a1,a1,a5
    800025d2:	058e                	slli	a1,a1,0x3
    800025d4:	05a1                	addi	a1,a1,8
    800025d6:	95ca                	add	a1,a1,s2
    800025d8:	08048513          	addi	a0,s1,128
    800025dc:	00001097          	auipc	ra,0x1
    800025e0:	802080e7          	jalr	-2046(ra) # 80002dde <swtch>
    800025e4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025e6:	0007871b          	sext.w	a4,a5
    800025ea:	00471793          	slli	a5,a4,0x4
    800025ee:	97ba                	add	a5,a5,a4
    800025f0:	078e                	slli	a5,a5,0x3
    800025f2:	993e                	add	s2,s2,a5
    800025f4:	07392e23          	sw	s3,124(s2)
}
    800025f8:	70a2                	ld	ra,40(sp)
    800025fa:	7402                	ld	s0,32(sp)
    800025fc:	64e2                	ld	s1,24(sp)
    800025fe:	6942                	ld	s2,16(sp)
    80002600:	69a2                	ld	s3,8(sp)
    80002602:	6145                	addi	sp,sp,48
    80002604:	8082                	ret
    panic("sched p->lock");
    80002606:	00006517          	auipc	a0,0x6
    8000260a:	caa50513          	addi	a0,a0,-854 # 800082b0 <digits+0x270>
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
    panic("sched locks");
    80002616:	00006517          	auipc	a0,0x6
    8000261a:	caa50513          	addi	a0,a0,-854 # 800082c0 <digits+0x280>
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
    panic("sched running");
    80002626:	00006517          	auipc	a0,0x6
    8000262a:	caa50513          	addi	a0,a0,-854 # 800082d0 <digits+0x290>
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002636:	00006517          	auipc	a0,0x6
    8000263a:	caa50513          	addi	a0,a0,-854 # 800082e0 <digits+0x2a0>
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	f00080e7          	jalr	-256(ra) # 8000053e <panic>

0000000080002646 <yield>:
{
    80002646:	1101                	addi	sp,sp,-32
    80002648:	ec06                	sd	ra,24(sp)
    8000264a:	e822                	sd	s0,16(sp)
    8000264c:	e426                	sd	s1,8(sp)
    8000264e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	774080e7          	jalr	1908(ra) # 80001dc4 <myproc>
    80002658:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	58a080e7          	jalr	1418(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002662:	478d                	li	a5,3
    80002664:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002666:	58cc                	lw	a1,52(s1)
    80002668:	00159793          	slli	a5,a1,0x1
    8000266c:	97ae                	add	a5,a5,a1
    8000266e:	078e                	slli	a5,a5,0x3
    80002670:	058a                	slli	a1,a1,0x2
    80002672:	0000f617          	auipc	a2,0xf
    80002676:	0e660613          	addi	a2,a2,230 # 80011758 <cpus_head>
    8000267a:	963e                	add	a2,a2,a5
    8000267c:	00007797          	auipc	a5,0x7
    80002680:	9ac78793          	addi	a5,a5,-1620 # 80009028 <cpus_ll>
    80002684:	95be                	add	a1,a1,a5
    80002686:	5c88                	lw	a0,56(s1)
    80002688:	fffff097          	auipc	ra,0xfffff
    8000268c:	432080e7          	jalr	1074(ra) # 80001aba <insert_to_list>
  sched();
    80002690:	00000097          	auipc	ra,0x0
    80002694:	ec8080e7          	jalr	-312(ra) # 80002558 <sched>
  release(&p->lock);
    80002698:	8526                	mv	a0,s1
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	610080e7          	jalr	1552(ra) # 80000caa <release>
}
    800026a2:	60e2                	ld	ra,24(sp)
    800026a4:	6442                	ld	s0,16(sp)
    800026a6:	64a2                	ld	s1,8(sp)
    800026a8:	6105                	addi	sp,sp,32
    800026aa:	8082                	ret

00000000800026ac <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800026ac:	7179                	addi	sp,sp,-48
    800026ae:	f406                	sd	ra,40(sp)
    800026b0:	f022                	sd	s0,32(sp)
    800026b2:	ec26                	sd	s1,24(sp)
    800026b4:	e84a                	sd	s2,16(sp)
    800026b6:	e44e                	sd	s3,8(sp)
    800026b8:	1800                	addi	s0,sp,48
    800026ba:	84aa                	mv	s1,a0
    800026bc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800026be:	fffff097          	auipc	ra,0xfffff
    800026c2:	706080e7          	jalr	1798(ra) # 80001dc4 <myproc>
    800026c6:	892a                	mv	s2,a0
  // Must acquire p->lock in order to change p->state and then call sched.
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.
  // Go to sleep.
  // cas(&p->state, RUNNING, SLEEPING);
  insert_to_list(p->index, &sleeping, &sleeping_head);
    800026c8:	0000f617          	auipc	a2,0xf
    800026cc:	04860613          	addi	a2,a2,72 # 80011710 <sleeping_head>
    800026d0:	00006597          	auipc	a1,0x6
    800026d4:	1fc58593          	addi	a1,a1,508 # 800088cc <sleeping>
    800026d8:	5d08                	lw	a0,56(a0)
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	3e0080e7          	jalr	992(ra) # 80001aba <insert_to_list>
  p->chan = chan;
    800026e2:	02993023          	sd	s1,32(s2)
  // if (p->state == RUNNING){
  //   p->state = SLEEPING;
  //   }
  while(!cas(&p->state, RUNNING, SLEEPING));
    800026e6:	01890493          	addi	s1,s2,24
    800026ea:	4609                	li	a2,2
    800026ec:	4591                	li	a1,4
    800026ee:	8526                	mv	a0,s1
    800026f0:	00004097          	auipc	ra,0x4
    800026f4:	356080e7          	jalr	854(ra) # 80006a46 <cas>
    800026f8:	d96d                	beqz	a0,800026ea <sleep+0x3e>
  release(lk);
    800026fa:	854e                	mv	a0,s3
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	5ae080e7          	jalr	1454(ra) # 80000caa <release>
  acquire(&p->lock);  //DOC: sleeplock1
    80002704:	854a                	mv	a0,s2
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	4de080e7          	jalr	1246(ra) # 80000be4 <acquire>
  sched();
    8000270e:	00000097          	auipc	ra,0x0
    80002712:	e4a080e7          	jalr	-438(ra) # 80002558 <sched>
  // Tidy up.
  p->chan = 0;
    80002716:	02093023          	sd	zero,32(s2)
  // Reacquire original lock.
  release(&p->lock);
    8000271a:	854a                	mv	a0,s2
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	58e080e7          	jalr	1422(ra) # 80000caa <release>
  acquire(lk);
    80002724:	854e                	mv	a0,s3
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	4be080e7          	jalr	1214(ra) # 80000be4 <acquire>

}
    8000272e:	70a2                	ld	ra,40(sp)
    80002730:	7402                	ld	s0,32(sp)
    80002732:	64e2                	ld	s1,24(sp)
    80002734:	6942                	ld	s2,16(sp)
    80002736:	69a2                	ld	s3,8(sp)
    80002738:	6145                	addi	sp,sp,48
    8000273a:	8082                	ret

000000008000273c <wait>:
{
    8000273c:	715d                	addi	sp,sp,-80
    8000273e:	e486                	sd	ra,72(sp)
    80002740:	e0a2                	sd	s0,64(sp)
    80002742:	fc26                	sd	s1,56(sp)
    80002744:	f84a                	sd	s2,48(sp)
    80002746:	f44e                	sd	s3,40(sp)
    80002748:	f052                	sd	s4,32(sp)
    8000274a:	ec56                	sd	s5,24(sp)
    8000274c:	e85a                	sd	s6,16(sp)
    8000274e:	e45e                	sd	s7,8(sp)
    80002750:	e062                	sd	s8,0(sp)
    80002752:	0880                	addi	s0,sp,80
    80002754:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002756:	fffff097          	auipc	ra,0xfffff
    8000275a:	66e080e7          	jalr	1646(ra) # 80001dc4 <myproc>
    8000275e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002760:	0000f517          	auipc	a0,0xf
    80002764:	f9850513          	addi	a0,a0,-104 # 800116f8 <wait_lock>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	47c080e7          	jalr	1148(ra) # 80000be4 <acquire>
    havekids = 0;
    80002770:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002772:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002774:	00015997          	auipc	s3,0x15
    80002778:	22498993          	addi	s3,s3,548 # 80017998 <tickslock>
        havekids = 1;
    8000277c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000277e:	0000fc17          	auipc	s8,0xf
    80002782:	f7ac0c13          	addi	s8,s8,-134 # 800116f8 <wait_lock>
    havekids = 0;
    80002786:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002788:	0000f497          	auipc	s1,0xf
    8000278c:	01048493          	addi	s1,s1,16 # 80011798 <proc>
    80002790:	a0bd                	j	800027fe <wait+0xc2>
          pid = np->pid;
    80002792:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002796:	000b0e63          	beqz	s6,800027b2 <wait+0x76>
    8000279a:	4691                	li	a3,4
    8000279c:	02c48613          	addi	a2,s1,44
    800027a0:	85da                	mv	a1,s6
    800027a2:	07093503          	ld	a0,112(s2)
    800027a6:	fffff097          	auipc	ra,0xfffff
    800027aa:	ef0080e7          	jalr	-272(ra) # 80001696 <copyout>
    800027ae:	02054563          	bltz	a0,800027d8 <wait+0x9c>
          freeproc(np);
    800027b2:	8526                	mv	a0,s1
    800027b4:	00000097          	auipc	ra,0x0
    800027b8:	80e080e7          	jalr	-2034(ra) # 80001fc2 <freeproc>
          release(&np->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	4ec080e7          	jalr	1260(ra) # 80000caa <release>
          release(&wait_lock);
    800027c6:	0000f517          	auipc	a0,0xf
    800027ca:	f3250513          	addi	a0,a0,-206 # 800116f8 <wait_lock>
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4dc080e7          	jalr	1244(ra) # 80000caa <release>
          return pid;
    800027d6:	a09d                	j	8000283c <wait+0x100>
            release(&np->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4d0080e7          	jalr	1232(ra) # 80000caa <release>
            release(&wait_lock);
    800027e2:	0000f517          	auipc	a0,0xf
    800027e6:	f1650513          	addi	a0,a0,-234 # 800116f8 <wait_lock>
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	4c0080e7          	jalr	1216(ra) # 80000caa <release>
            return -1;
    800027f2:	59fd                	li	s3,-1
    800027f4:	a0a1                	j	8000283c <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800027f6:	18848493          	addi	s1,s1,392
    800027fa:	03348463          	beq	s1,s3,80002822 <wait+0xe6>
      if(np->parent == p){
    800027fe:	6cbc                	ld	a5,88(s1)
    80002800:	ff279be3          	bne	a5,s2,800027f6 <wait+0xba>
        acquire(&np->lock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	3de080e7          	jalr	990(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000280e:	4c9c                	lw	a5,24(s1)
    80002810:	f94781e3          	beq	a5,s4,80002792 <wait+0x56>
        release(&np->lock);
    80002814:	8526                	mv	a0,s1
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	494080e7          	jalr	1172(ra) # 80000caa <release>
        havekids = 1;
    8000281e:	8756                	mv	a4,s5
    80002820:	bfd9                	j	800027f6 <wait+0xba>
    if(!havekids || p->killed){
    80002822:	c701                	beqz	a4,8000282a <wait+0xee>
    80002824:	02892783          	lw	a5,40(s2)
    80002828:	c79d                	beqz	a5,80002856 <wait+0x11a>
      release(&wait_lock);
    8000282a:	0000f517          	auipc	a0,0xf
    8000282e:	ece50513          	addi	a0,a0,-306 # 800116f8 <wait_lock>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	478080e7          	jalr	1144(ra) # 80000caa <release>
      return -1;
    8000283a:	59fd                	li	s3,-1
}
    8000283c:	854e                	mv	a0,s3
    8000283e:	60a6                	ld	ra,72(sp)
    80002840:	6406                	ld	s0,64(sp)
    80002842:	74e2                	ld	s1,56(sp)
    80002844:	7942                	ld	s2,48(sp)
    80002846:	79a2                	ld	s3,40(sp)
    80002848:	7a02                	ld	s4,32(sp)
    8000284a:	6ae2                	ld	s5,24(sp)
    8000284c:	6b42                	ld	s6,16(sp)
    8000284e:	6ba2                	ld	s7,8(sp)
    80002850:	6c02                	ld	s8,0(sp)
    80002852:	6161                	addi	sp,sp,80
    80002854:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002856:	85e2                	mv	a1,s8
    80002858:	854a                	mv	a0,s2
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	e52080e7          	jalr	-430(ra) # 800026ac <sleep>
    havekids = 0;
    80002862:	b715                	j	80002786 <wait+0x4a>

0000000080002864 <wakeup>:
//   }
  
// }
void
wakeup(void *chan)
{
    80002864:	7119                	addi	sp,sp,-128
    80002866:	fc86                	sd	ra,120(sp)
    80002868:	f8a2                	sd	s0,112(sp)
    8000286a:	f4a6                	sd	s1,104(sp)
    8000286c:	f0ca                	sd	s2,96(sp)
    8000286e:	ecce                	sd	s3,88(sp)
    80002870:	e8d2                	sd	s4,80(sp)
    80002872:	e4d6                	sd	s5,72(sp)
    80002874:	e0da                	sd	s6,64(sp)
    80002876:	fc5e                	sd	s7,56(sp)
    80002878:	f862                	sd	s8,48(sp)
    8000287a:	f466                	sd	s9,40(sp)
    8000287c:	f06a                	sd	s10,32(sp)
    8000287e:	ec6e                	sd	s11,24(sp)
    80002880:	0100                	addi	s0,sp,128
    80002882:	8aaa                	mv	s5,a0
  struct proc *p;
  acquire(&sleeping_head);
    80002884:	0000f517          	auipc	a0,0xf
    80002888:	e8c50513          	addi	a0,a0,-372 # 80011710 <sleeping_head>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	358080e7          	jalr	856(ra) # 80000be4 <acquire>
  if (sleeping == -1){
    80002894:	00006717          	auipc	a4,0x6
    80002898:	03872703          	lw	a4,56(a4) # 800088cc <sleeping>
    8000289c:	57fd                	li	a5,-1
    8000289e:	06f70463          	beq	a4,a5,80002906 <wakeup+0xa2>
    release(&sleeping_head);
    return;
  }
  else { 
    release(&sleeping_head);
    800028a2:	0000f517          	auipc	a0,0xf
    800028a6:	e6e50513          	addi	a0,a0,-402 # 80011710 <sleeping_head>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	400080e7          	jalr	1024(ra) # 80000caa <release>
    p = &proc[sleeping];
    800028b2:	00006497          	auipc	s1,0x6
    800028b6:	01a4a483          	lw	s1,26(s1) # 800088cc <sleeping>
    800028ba:	18800793          	li	a5,392
    800028be:	02f484b3          	mul	s1,s1,a5
    800028c2:	0000f797          	auipc	a5,0xf
    800028c6:	ed678793          	addi	a5,a5,-298 # 80011798 <proc>
    800028ca:	94be                	add	s1,s1,a5
    int curr= proc[sleeping].index;
    while(curr !=- 1 && sleeping != -1) { // loop through all sleepers
    800028cc:	5c98                	lw	a4,56(s1)
    800028ce:	57fd                	li	a5,-1
    800028d0:	04f70363          	beq	a4,a5,80002916 <wakeup+0xb2>
    800028d4:	00006997          	auipc	s3,0x6
    800028d8:	ff898993          	addi	s3,s3,-8 # 800088cc <sleeping>
    800028dc:	597d                	li	s2,-1
      if(p != myproc()){
        acquire(&p->lock);
        if(p->chan == chan && p->state == SLEEPING) {
    800028de:	4c09                	li	s8,2
        remove_from_list(p->index, &sleeping, &sleeping_head);
    800028e0:	0000fd97          	auipc	s11,0xf
    800028e4:	e30d8d93          	addi	s11,s11,-464 # 80011710 <sleeping_head>
        p->cpu_num = cpui;
        // release(&p->lock);
        // while (!cas(&cpus[p->cpu_num].admittedProcs, cpus[p->cpu_num].admittedProcs, cpus[p->cpu_num].admittedProcs + 1))
        inc_cpu_usage(p->cpu_num);
        #endif
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    800028e8:	0000fd17          	auipc	s10,0xf
    800028ec:	e70d0d13          	addi	s10,s10,-400 # 80011758 <cpus_head>
    800028f0:	00006c97          	auipc	s9,0x6
    800028f4:	738c8c93          	addi	s9,s9,1848 # 80009028 <cpus_ll>
      // #ifdef OFF
      release(&p->lock);
      // #endif
    }
    if(p->next !=- 1)
      p = &proc[p->next];
    800028f8:	18800b93          	li	s7,392
    800028fc:	0000fb17          	auipc	s6,0xf
    80002900:	e9cb0b13          	addi	s6,s6,-356 # 80011798 <proc>
    80002904:	a891                	j	80002958 <wakeup+0xf4>
    release(&sleeping_head);
    80002906:	0000f517          	auipc	a0,0xf
    8000290a:	e0a50513          	addi	a0,a0,-502 # 80011710 <sleeping_head>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	39c080e7          	jalr	924(ra) # 80000caa <release>
    curr=p->next;
   }
  }
}
    80002916:	70e6                	ld	ra,120(sp)
    80002918:	7446                	ld	s0,112(sp)
    8000291a:	74a6                	ld	s1,104(sp)
    8000291c:	7906                	ld	s2,96(sp)
    8000291e:	69e6                	ld	s3,88(sp)
    80002920:	6a46                	ld	s4,80(sp)
    80002922:	6aa6                	ld	s5,72(sp)
    80002924:	6b06                	ld	s6,64(sp)
    80002926:	7be2                	ld	s7,56(sp)
    80002928:	7c42                	ld	s8,48(sp)
    8000292a:	7ca2                	ld	s9,40(sp)
    8000292c:	7d02                	ld	s10,32(sp)
    8000292e:	6de2                	ld	s11,24(sp)
    80002930:	6109                	addi	sp,sp,128
    80002932:	8082                	ret
      release(&p->lock);
    80002934:	8552                	mv	a0,s4
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	374080e7          	jalr	884(ra) # 80000caa <release>
    if(p->next !=- 1)
    8000293e:	5cdc                	lw	a5,60(s1)
    80002940:	2781                	sext.w	a5,a5
    80002942:	01278763          	beq	a5,s2,80002950 <wakeup+0xec>
      p = &proc[p->next];
    80002946:	5cc4                	lw	s1,60(s1)
    80002948:	2481                	sext.w	s1,s1
    8000294a:	037484b3          	mul	s1,s1,s7
    8000294e:	94da                	add	s1,s1,s6
    curr=p->next;
    80002950:	5cdc                	lw	a5,60(s1)
    80002952:	2781                	sext.w	a5,a5
    while(curr !=- 1 && sleeping != -1) { // loop through all sleepers
    80002954:	fd2781e3          	beq	a5,s2,80002916 <wakeup+0xb2>
    80002958:	0009a783          	lw	a5,0(s3)
    8000295c:	fb278de3          	beq	a5,s2,80002916 <wakeup+0xb2>
      if(p != myproc()){
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	464080e7          	jalr	1124(ra) # 80001dc4 <myproc>
    80002968:	fca48be3          	beq	s1,a0,8000293e <wakeup+0xda>
        acquire(&p->lock);
    8000296c:	8a26                	mv	s4,s1
    8000296e:	8526                	mv	a0,s1
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	274080e7          	jalr	628(ra) # 80000be4 <acquire>
        if(p->chan == chan && p->state == SLEEPING) {
    80002978:	709c                	ld	a5,32(s1)
    8000297a:	fb579de3          	bne	a5,s5,80002934 <wakeup+0xd0>
    8000297e:	4c9c                	lw	a5,24(s1)
    80002980:	fb879ae3          	bne	a5,s8,80002934 <wakeup+0xd0>
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002984:	866e                	mv	a2,s11
    80002986:	85ce                	mv	a1,s3
    80002988:	5c88                	lw	a0,56(s1)
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	ef6080e7          	jalr	-266(ra) # 80001880 <remove_from_list>
        p->chan=0;
    80002992:	0204b023          	sd	zero,32(s1)
        while(!cas(&p->state, SLEEPING, RUNNABLE));
    80002996:	01848793          	addi	a5,s1,24
    8000299a:	f8f43423          	sd	a5,-120(s0)
    8000299e:	460d                	li	a2,3
    800029a0:	85e2                	mv	a1,s8
    800029a2:	f8843503          	ld	a0,-120(s0)
    800029a6:	00004097          	auipc	ra,0x4
    800029aa:	0a0080e7          	jalr	160(ra) # 80006a46 <cas>
    800029ae:	d965                	beqz	a0,8000299e <wakeup+0x13a>
        int cpui = leastUsedCPU();
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	eb2080e7          	jalr	-334(ra) # 80001862 <leastUsedCPU>
        p->cpu_num = cpui;
    800029b8:	d8c8                	sw	a0,52(s1)
        inc_cpu_usage(p->cpu_num);
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	490080e7          	jalr	1168(ra) # 80001e4a <inc_cpu_usage>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    800029c2:	58dc                	lw	a5,52(s1)
    800029c4:	00179613          	slli	a2,a5,0x1
    800029c8:	963e                	add	a2,a2,a5
    800029ca:	060e                	slli	a2,a2,0x3
    800029cc:	078a                	slli	a5,a5,0x2
    800029ce:	966a                	add	a2,a2,s10
    800029d0:	00fc85b3          	add	a1,s9,a5
    800029d4:	5c88                	lw	a0,56(s1)
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	0e4080e7          	jalr	228(ra) # 80001aba <insert_to_list>
    800029de:	bf99                	j	80002934 <wakeup+0xd0>

00000000800029e0 <reparent>:
{
    800029e0:	7179                	addi	sp,sp,-48
    800029e2:	f406                	sd	ra,40(sp)
    800029e4:	f022                	sd	s0,32(sp)
    800029e6:	ec26                	sd	s1,24(sp)
    800029e8:	e84a                	sd	s2,16(sp)
    800029ea:	e44e                	sd	s3,8(sp)
    800029ec:	e052                	sd	s4,0(sp)
    800029ee:	1800                	addi	s0,sp,48
    800029f0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800029f2:	0000f497          	auipc	s1,0xf
    800029f6:	da648493          	addi	s1,s1,-602 # 80011798 <proc>
      pp->parent = initproc;
    800029fa:	00006a17          	auipc	s4,0x6
    800029fe:	636a0a13          	addi	s4,s4,1590 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002a02:	00015997          	auipc	s3,0x15
    80002a06:	f9698993          	addi	s3,s3,-106 # 80017998 <tickslock>
    80002a0a:	a029                	j	80002a14 <reparent+0x34>
    80002a0c:	18848493          	addi	s1,s1,392
    80002a10:	01348d63          	beq	s1,s3,80002a2a <reparent+0x4a>
    if(pp->parent == p){
    80002a14:	6cbc                	ld	a5,88(s1)
    80002a16:	ff279be3          	bne	a5,s2,80002a0c <reparent+0x2c>
      pp->parent = initproc;
    80002a1a:	000a3503          	ld	a0,0(s4)
    80002a1e:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	e44080e7          	jalr	-444(ra) # 80002864 <wakeup>
    80002a28:	b7d5                	j	80002a0c <reparent+0x2c>
}
    80002a2a:	70a2                	ld	ra,40(sp)
    80002a2c:	7402                	ld	s0,32(sp)
    80002a2e:	64e2                	ld	s1,24(sp)
    80002a30:	6942                	ld	s2,16(sp)
    80002a32:	69a2                	ld	s3,8(sp)
    80002a34:	6a02                	ld	s4,0(sp)
    80002a36:	6145                	addi	sp,sp,48
    80002a38:	8082                	ret

0000000080002a3a <exit>:
{
    80002a3a:	7179                	addi	sp,sp,-48
    80002a3c:	f406                	sd	ra,40(sp)
    80002a3e:	f022                	sd	s0,32(sp)
    80002a40:	ec26                	sd	s1,24(sp)
    80002a42:	e84a                	sd	s2,16(sp)
    80002a44:	e44e                	sd	s3,8(sp)
    80002a46:	e052                	sd	s4,0(sp)
    80002a48:	1800                	addi	s0,sp,48
    80002a4a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	378080e7          	jalr	888(ra) # 80001dc4 <myproc>
    80002a54:	89aa                	mv	s3,a0
  if(p == initproc)
    80002a56:	00006797          	auipc	a5,0x6
    80002a5a:	5da7b783          	ld	a5,1498(a5) # 80009030 <initproc>
    80002a5e:	0f050493          	addi	s1,a0,240
    80002a62:	17050913          	addi	s2,a0,368
    80002a66:	02a79363          	bne	a5,a0,80002a8c <exit+0x52>
    panic("init exiting");
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	88e50513          	addi	a0,a0,-1906 # 800082f8 <digits+0x2b8>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	acc080e7          	jalr	-1332(ra) # 8000053e <panic>
      fileclose(f);
    80002a7a:	00002097          	auipc	ra,0x2
    80002a7e:	2e2080e7          	jalr	738(ra) # 80004d5c <fileclose>
      p->ofile[fd] = 0;
    80002a82:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a86:	04a1                	addi	s1,s1,8
    80002a88:	01248563          	beq	s1,s2,80002a92 <exit+0x58>
    if(p->ofile[fd]){
    80002a8c:	6088                	ld	a0,0(s1)
    80002a8e:	f575                	bnez	a0,80002a7a <exit+0x40>
    80002a90:	bfdd                	j	80002a86 <exit+0x4c>
  begin_op();
    80002a92:	00002097          	auipc	ra,0x2
    80002a96:	dfe080e7          	jalr	-514(ra) # 80004890 <begin_op>
  iput(p->cwd);
    80002a9a:	1709b503          	ld	a0,368(s3)
    80002a9e:	00001097          	auipc	ra,0x1
    80002aa2:	5da080e7          	jalr	1498(ra) # 80004078 <iput>
  end_op();
    80002aa6:	00002097          	auipc	ra,0x2
    80002aaa:	e6a080e7          	jalr	-406(ra) # 80004910 <end_op>
  p->cwd = 0;
    80002aae:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002ab2:	0000f497          	auipc	s1,0xf
    80002ab6:	c4648493          	addi	s1,s1,-954 # 800116f8 <wait_lock>
    80002aba:	8526                	mv	a0,s1
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	128080e7          	jalr	296(ra) # 80000be4 <acquire>
  reparent(p);
    80002ac4:	854e                	mv	a0,s3
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	f1a080e7          	jalr	-230(ra) # 800029e0 <reparent>
  wakeup(p->parent);
    80002ace:	0589b503          	ld	a0,88(s3)
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	d92080e7          	jalr	-622(ra) # 80002864 <wakeup>
  acquire(&p->lock);
    80002ada:	854e                	mv	a0,s3
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	108080e7          	jalr	264(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002ae4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002ae8:	4795                	li	a5,5
    80002aea:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index, &zombie, &zombie_head);
    80002aee:	0000f617          	auipc	a2,0xf
    80002af2:	c3a60613          	addi	a2,a2,-966 # 80011728 <zombie_head>
    80002af6:	00006597          	auipc	a1,0x6
    80002afa:	dd258593          	addi	a1,a1,-558 # 800088c8 <zombie>
    80002afe:	0389a503          	lw	a0,56(s3)
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	fb8080e7          	jalr	-72(ra) # 80001aba <insert_to_list>
  release(&wait_lock);
    80002b0a:	8526                	mv	a0,s1
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	19e080e7          	jalr	414(ra) # 80000caa <release>
  sched();
    80002b14:	00000097          	auipc	ra,0x0
    80002b18:	a44080e7          	jalr	-1468(ra) # 80002558 <sched>
  panic("zombie exit");
    80002b1c:	00005517          	auipc	a0,0x5
    80002b20:	7ec50513          	addi	a0,a0,2028 # 80008308 <digits+0x2c8>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a1a080e7          	jalr	-1510(ra) # 8000053e <panic>

0000000080002b2c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002b2c:	7179                	addi	sp,sp,-48
    80002b2e:	f406                	sd	ra,40(sp)
    80002b30:	f022                	sd	s0,32(sp)
    80002b32:	ec26                	sd	s1,24(sp)
    80002b34:	e84a                	sd	s2,16(sp)
    80002b36:	e44e                	sd	s3,8(sp)
    80002b38:	1800                	addi	s0,sp,48
    80002b3a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002b3c:	0000f497          	auipc	s1,0xf
    80002b40:	c5c48493          	addi	s1,s1,-932 # 80011798 <proc>
    80002b44:	00015997          	auipc	s3,0x15
    80002b48:	e5498993          	addi	s3,s3,-428 # 80017998 <tickslock>
    acquire(&p->lock);
    80002b4c:	8526                	mv	a0,s1
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	096080e7          	jalr	150(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002b56:	589c                	lw	a5,48(s1)
    80002b58:	01278d63          	beq	a5,s2,80002b72 <kill+0x46>
      release(&p->lock);
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
      }
      return 0;
    }
    release(&p->lock);
    80002b5c:	8526                	mv	a0,s1
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	14c080e7          	jalr	332(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b66:	18848493          	addi	s1,s1,392
    80002b6a:	ff3491e3          	bne	s1,s3,80002b4c <kill+0x20>
  }
  return -1;
    80002b6e:	557d                	li	a0,-1
    80002b70:	a831                	j	80002b8c <kill+0x60>
      p->killed = 1;
    80002b72:	4785                	li	a5,1
    80002b74:	d49c                	sw	a5,40(s1)
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002b76:	460d                	li	a2,3
    80002b78:	4589                	li	a1,2
    80002b7a:	01848513          	addi	a0,s1,24
    80002b7e:	00004097          	auipc	ra,0x4
    80002b82:	ec8080e7          	jalr	-312(ra) # 80006a46 <cas>
    80002b86:	87aa                	mv	a5,a0
      return 0;
    80002b88:	4501                	li	a0,0
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002b8a:	cb81                	beqz	a5,80002b9a <kill+0x6e>
}
    80002b8c:	70a2                	ld	ra,40(sp)
    80002b8e:	7402                	ld	s0,32(sp)
    80002b90:	64e2                	ld	s1,24(sp)
    80002b92:	6942                	ld	s2,16(sp)
    80002b94:	69a2                	ld	s3,8(sp)
    80002b96:	6145                	addi	sp,sp,48
    80002b98:	8082                	ret
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002b9a:	0000f617          	auipc	a2,0xf
    80002b9e:	b7660613          	addi	a2,a2,-1162 # 80011710 <sleeping_head>
    80002ba2:	00006597          	auipc	a1,0x6
    80002ba6:	d2a58593          	addi	a1,a1,-726 # 800088cc <sleeping>
    80002baa:	5c88                	lw	a0,56(s1)
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	cd4080e7          	jalr	-812(ra) # 80001880 <remove_from_list>
        p->state = RUNNABLE;
    80002bb4:	478d                	li	a5,3
    80002bb6:	cc9c                	sw	a5,24(s1)
      release(&p->lock);
    80002bb8:	8526                	mv	a0,s1
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	0f0080e7          	jalr	240(ra) # 80000caa <release>
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002bc2:	58cc                	lw	a1,52(s1)
    80002bc4:	00159793          	slli	a5,a1,0x1
    80002bc8:	97ae                	add	a5,a5,a1
    80002bca:	078e                	slli	a5,a5,0x3
    80002bcc:	058a                	slli	a1,a1,0x2
    80002bce:	0000f617          	auipc	a2,0xf
    80002bd2:	b8a60613          	addi	a2,a2,-1142 # 80011758 <cpus_head>
    80002bd6:	963e                	add	a2,a2,a5
    80002bd8:	00006797          	auipc	a5,0x6
    80002bdc:	45078793          	addi	a5,a5,1104 # 80009028 <cpus_ll>
    80002be0:	95be                	add	a1,a1,a5
    80002be2:	5c88                	lw	a0,56(s1)
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	ed6080e7          	jalr	-298(ra) # 80001aba <insert_to_list>
      return 0;
    80002bec:	4501                	li	a0,0
    80002bee:	bf79                	j	80002b8c <kill+0x60>

0000000080002bf0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len){
    80002bf0:	7179                	addi	sp,sp,-48
    80002bf2:	f406                	sd	ra,40(sp)
    80002bf4:	f022                	sd	s0,32(sp)
    80002bf6:	ec26                	sd	s1,24(sp)
    80002bf8:	e84a                	sd	s2,16(sp)
    80002bfa:	e44e                	sd	s3,8(sp)
    80002bfc:	e052                	sd	s4,0(sp)
    80002bfe:	1800                	addi	s0,sp,48
    80002c00:	84aa                	mv	s1,a0
    80002c02:	892e                	mv	s2,a1
    80002c04:	89b2                	mv	s3,a2
    80002c06:	8a36                	mv	s4,a3

  struct proc *p = myproc();
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	1bc080e7          	jalr	444(ra) # 80001dc4 <myproc>
  if(user_dst){
    80002c10:	c08d                	beqz	s1,80002c32 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002c12:	86d2                	mv	a3,s4
    80002c14:	864e                	mv	a2,s3
    80002c16:	85ca                	mv	a1,s2
    80002c18:	7928                	ld	a0,112(a0)
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	a7c080e7          	jalr	-1412(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002c22:	70a2                	ld	ra,40(sp)
    80002c24:	7402                	ld	s0,32(sp)
    80002c26:	64e2                	ld	s1,24(sp)
    80002c28:	6942                	ld	s2,16(sp)
    80002c2a:	69a2                	ld	s3,8(sp)
    80002c2c:	6a02                	ld	s4,0(sp)
    80002c2e:	6145                	addi	sp,sp,48
    80002c30:	8082                	ret
    memmove((char *)dst, src, len);
    80002c32:	000a061b          	sext.w	a2,s4
    80002c36:	85ce                	mv	a1,s3
    80002c38:	854a                	mv	a0,s2
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	12a080e7          	jalr	298(ra) # 80000d64 <memmove>
    return 0;
    80002c42:	8526                	mv	a0,s1
    80002c44:	bff9                	j	80002c22 <either_copyout+0x32>

0000000080002c46 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c46:	7179                	addi	sp,sp,-48
    80002c48:	f406                	sd	ra,40(sp)
    80002c4a:	f022                	sd	s0,32(sp)
    80002c4c:	ec26                	sd	s1,24(sp)
    80002c4e:	e84a                	sd	s2,16(sp)
    80002c50:	e44e                	sd	s3,8(sp)
    80002c52:	e052                	sd	s4,0(sp)
    80002c54:	1800                	addi	s0,sp,48
    80002c56:	892a                	mv	s2,a0
    80002c58:	84ae                	mv	s1,a1
    80002c5a:	89b2                	mv	s3,a2
    80002c5c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	166080e7          	jalr	358(ra) # 80001dc4 <myproc>
  if(user_src){
    80002c66:	c08d                	beqz	s1,80002c88 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002c68:	86d2                	mv	a3,s4
    80002c6a:	864e                	mv	a2,s3
    80002c6c:	85ca                	mv	a1,s2
    80002c6e:	7928                	ld	a0,112(a0)
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	ab2080e7          	jalr	-1358(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002c78:	70a2                	ld	ra,40(sp)
    80002c7a:	7402                	ld	s0,32(sp)
    80002c7c:	64e2                	ld	s1,24(sp)
    80002c7e:	6942                	ld	s2,16(sp)
    80002c80:	69a2                	ld	s3,8(sp)
    80002c82:	6a02                	ld	s4,0(sp)
    80002c84:	6145                	addi	sp,sp,48
    80002c86:	8082                	ret
    memmove(dst, (char*)src, len);
    80002c88:	000a061b          	sext.w	a2,s4
    80002c8c:	85ce                	mv	a1,s3
    80002c8e:	854a                	mv	a0,s2
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	0d4080e7          	jalr	212(ra) # 80000d64 <memmove>
    return 0;
    80002c98:	8526                	mv	a0,s1
    80002c9a:	bff9                	j	80002c78 <either_copyin+0x32>

0000000080002c9c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002c9c:	715d                	addi	sp,sp,-80
    80002c9e:	e486                	sd	ra,72(sp)
    80002ca0:	e0a2                	sd	s0,64(sp)
    80002ca2:	fc26                	sd	s1,56(sp)
    80002ca4:	f84a                	sd	s2,48(sp)
    80002ca6:	f44e                	sd	s3,40(sp)
    80002ca8:	f052                	sd	s4,32(sp)
    80002caa:	ec56                	sd	s5,24(sp)
    80002cac:	e85a                	sd	s6,16(sp)
    80002cae:	e45e                	sd	s7,8(sp)
    80002cb0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	44650513          	addi	a0,a0,1094 # 800080f8 <digits+0xb8>
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	8ce080e7          	jalr	-1842(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002cc2:	0000f497          	auipc	s1,0xf
    80002cc6:	c4e48493          	addi	s1,s1,-946 # 80011910 <proc+0x178>
    80002cca:	00015917          	auipc	s2,0x15
    80002cce:	e4690913          	addi	s2,s2,-442 # 80017b10 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cd2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002cd4:	00005997          	auipc	s3,0x5
    80002cd8:	64498993          	addi	s3,s3,1604 # 80008318 <digits+0x2d8>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002cdc:	00005a97          	auipc	s5,0x5
    80002ce0:	644a8a93          	addi	s5,s5,1604 # 80008320 <digits+0x2e0>
    printf("\n");
    80002ce4:	00005a17          	auipc	s4,0x5
    80002ce8:	414a0a13          	addi	s4,s4,1044 # 800080f8 <digits+0xb8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cec:	00005b97          	auipc	s7,0x5
    80002cf0:	66cb8b93          	addi	s7,s7,1644 # 80008358 <states.1794>
    80002cf4:	a01d                	j	80002d1a <procdump+0x7e>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002cf6:	ebc6a703          	lw	a4,-324(a3)
    80002cfa:	eb86a583          	lw	a1,-328(a3)
    80002cfe:	8556                	mv	a0,s5
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	888080e7          	jalr	-1912(ra) # 80000588 <printf>
    printf("\n");
    80002d08:	8552                	mv	a0,s4
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	87e080e7          	jalr	-1922(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d12:	18848493          	addi	s1,s1,392
    80002d16:	03248163          	beq	s1,s2,80002d38 <procdump+0x9c>
    if(p->state == UNUSED)
    80002d1a:	86a6                	mv	a3,s1
    80002d1c:	ea04a783          	lw	a5,-352(s1)
    80002d20:	dbed                	beqz	a5,80002d12 <procdump+0x76>
      state = "???";
    80002d22:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d24:	fcfb69e3          	bltu	s6,a5,80002cf6 <procdump+0x5a>
    80002d28:	1782                	slli	a5,a5,0x20
    80002d2a:	9381                	srli	a5,a5,0x20
    80002d2c:	078e                	slli	a5,a5,0x3
    80002d2e:	97de                	add	a5,a5,s7
    80002d30:	6390                	ld	a2,0(a5)
    80002d32:	f271                	bnez	a2,80002cf6 <procdump+0x5a>
      state = "???";
    80002d34:	864e                	mv	a2,s3
    80002d36:	b7c1                	j	80002cf6 <procdump+0x5a>
  }
}
    80002d38:	60a6                	ld	ra,72(sp)
    80002d3a:	6406                	ld	s0,64(sp)
    80002d3c:	74e2                	ld	s1,56(sp)
    80002d3e:	7942                	ld	s2,48(sp)
    80002d40:	79a2                	ld	s3,40(sp)
    80002d42:	7a02                	ld	s4,32(sp)
    80002d44:	6ae2                	ld	s5,24(sp)
    80002d46:	6b42                	ld	s6,16(sp)
    80002d48:	6ba2                	ld	s7,8(sp)
    80002d4a:	6161                	addi	sp,sp,80
    80002d4c:	8082                	ret

0000000080002d4e <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002d4e:	1101                	addi	sp,sp,-32
    80002d50:	ec06                	sd	ra,24(sp)
    80002d52:	e822                	sd	s0,16(sp)
    80002d54:	e426                	sd	s1,8(sp)
    80002d56:	1000                	addi	s0,sp,32
    80002d58:	84aa                	mv	s1,a0
// printf("%d\n", 12);
  struct proc *p= myproc();  
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	06a080e7          	jalr	106(ra) # 80001dc4 <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002d62:	8626                	mv	a2,s1
    80002d64:	594c                	lw	a1,52(a0)
    80002d66:	03450513          	addi	a0,a0,52
    80002d6a:	00004097          	auipc	ra,0x4
    80002d6e:	cdc080e7          	jalr	-804(ra) # 80006a46 <cas>
    80002d72:	e519                	bnez	a0,80002d80 <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002d74:	4501                	li	a0,0
}
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	64a2                	ld	s1,8(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret
    yield();
    80002d80:	00000097          	auipc	ra,0x0
    80002d84:	8c6080e7          	jalr	-1850(ra) # 80002646 <yield>
    return cpu_num;
    80002d88:	8526                	mv	a0,s1
    80002d8a:	b7f5                	j	80002d76 <set_cpu+0x28>

0000000080002d8c <get_cpu>:

int get_cpu(){ //added as orderd
    80002d8c:	1101                	addi	sp,sp,-32
    80002d8e:	ec06                	sd	ra,24(sp)
    80002d90:	e822                	sd	s0,16(sp)
    80002d92:	1000                	addi	s0,sp,32
// printf("%d\n", 13);
  struct proc *p = myproc();
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	030080e7          	jalr	48(ra) # 80001dc4 <myproc>
  int ans=0;
    80002d9c:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002da0:	5950                	lw	a2,52(a0)
    80002da2:	4581                	li	a1,0
    80002da4:	fec40513          	addi	a0,s0,-20
    80002da8:	00004097          	auipc	ra,0x4
    80002dac:	c9e080e7          	jalr	-866(ra) # 80006a46 <cas>
    return ans;
}
    80002db0:	fec42503          	lw	a0,-20(s0)
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret

0000000080002dbc <cpu_process_count>:

// int cpu_process_count (int cpu_num){
//   return cpu_usage[cpu_num];
// }
int cpu_process_count(int cpu_num){
    80002dbc:	1141                	addi	sp,sp,-16
    80002dbe:	e422                	sd	s0,8(sp)
    80002dc0:	0800                	addi	s0,sp,16
  struct cpu* c = &cpus[cpu_num];
  uint64 procsNum = c->admittedProcs;
    80002dc2:	00451793          	slli	a5,a0,0x4
    80002dc6:	97aa                	add	a5,a5,a0
    80002dc8:	078e                	slli	a5,a5,0x3
    80002dca:	0000e517          	auipc	a0,0xe
    80002dce:	4d650513          	addi	a0,a0,1238 # 800112a0 <cpus>
    80002dd2:	97aa                	add	a5,a5,a0
  return procsNum;
}
    80002dd4:	0807a503          	lw	a0,128(a5)
    80002dd8:	6422                	ld	s0,8(sp)
    80002dda:	0141                	addi	sp,sp,16
    80002ddc:	8082                	ret

0000000080002dde <swtch>:
    80002dde:	00153023          	sd	ra,0(a0)
    80002de2:	00253423          	sd	sp,8(a0)
    80002de6:	e900                	sd	s0,16(a0)
    80002de8:	ed04                	sd	s1,24(a0)
    80002dea:	03253023          	sd	s2,32(a0)
    80002dee:	03353423          	sd	s3,40(a0)
    80002df2:	03453823          	sd	s4,48(a0)
    80002df6:	03553c23          	sd	s5,56(a0)
    80002dfa:	05653023          	sd	s6,64(a0)
    80002dfe:	05753423          	sd	s7,72(a0)
    80002e02:	05853823          	sd	s8,80(a0)
    80002e06:	05953c23          	sd	s9,88(a0)
    80002e0a:	07a53023          	sd	s10,96(a0)
    80002e0e:	07b53423          	sd	s11,104(a0)
    80002e12:	0005b083          	ld	ra,0(a1)
    80002e16:	0085b103          	ld	sp,8(a1)
    80002e1a:	6980                	ld	s0,16(a1)
    80002e1c:	6d84                	ld	s1,24(a1)
    80002e1e:	0205b903          	ld	s2,32(a1)
    80002e22:	0285b983          	ld	s3,40(a1)
    80002e26:	0305ba03          	ld	s4,48(a1)
    80002e2a:	0385ba83          	ld	s5,56(a1)
    80002e2e:	0405bb03          	ld	s6,64(a1)
    80002e32:	0485bb83          	ld	s7,72(a1)
    80002e36:	0505bc03          	ld	s8,80(a1)
    80002e3a:	0585bc83          	ld	s9,88(a1)
    80002e3e:	0605bd03          	ld	s10,96(a1)
    80002e42:	0685bd83          	ld	s11,104(a1)
    80002e46:	8082                	ret

0000000080002e48 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002e48:	1141                	addi	sp,sp,-16
    80002e4a:	e406                	sd	ra,8(sp)
    80002e4c:	e022                	sd	s0,0(sp)
    80002e4e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e50:	00005597          	auipc	a1,0x5
    80002e54:	53858593          	addi	a1,a1,1336 # 80008388 <states.1794+0x30>
    80002e58:	00015517          	auipc	a0,0x15
    80002e5c:	b4050513          	addi	a0,a0,-1216 # 80017998 <tickslock>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	cf4080e7          	jalr	-780(ra) # 80000b54 <initlock>
}
    80002e68:	60a2                	ld	ra,8(sp)
    80002e6a:	6402                	ld	s0,0(sp)
    80002e6c:	0141                	addi	sp,sp,16
    80002e6e:	8082                	ret

0000000080002e70 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e70:	1141                	addi	sp,sp,-16
    80002e72:	e422                	sd	s0,8(sp)
    80002e74:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e76:	00003797          	auipc	a5,0x3
    80002e7a:	4fa78793          	addi	a5,a5,1274 # 80006370 <kernelvec>
    80002e7e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e82:	6422                	ld	s0,8(sp)
    80002e84:	0141                	addi	sp,sp,16
    80002e86:	8082                	ret

0000000080002e88 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e88:	1141                	addi	sp,sp,-16
    80002e8a:	e406                	sd	ra,8(sp)
    80002e8c:	e022                	sd	s0,0(sp)
    80002e8e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	f34080e7          	jalr	-204(ra) # 80001dc4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e9e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ea2:	00004617          	auipc	a2,0x4
    80002ea6:	15e60613          	addi	a2,a2,350 # 80007000 <_trampoline>
    80002eaa:	00004697          	auipc	a3,0x4
    80002eae:	15668693          	addi	a3,a3,342 # 80007000 <_trampoline>
    80002eb2:	8e91                	sub	a3,a3,a2
    80002eb4:	040007b7          	lui	a5,0x4000
    80002eb8:	17fd                	addi	a5,a5,-1
    80002eba:	07b2                	slli	a5,a5,0xc
    80002ebc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ebe:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ec2:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ec4:	180026f3          	csrr	a3,satp
    80002ec8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002eca:	7d38                	ld	a4,120(a0)
    80002ecc:	7134                	ld	a3,96(a0)
    80002ece:	6585                	lui	a1,0x1
    80002ed0:	96ae                	add	a3,a3,a1
    80002ed2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ed4:	7d38                	ld	a4,120(a0)
    80002ed6:	00000697          	auipc	a3,0x0
    80002eda:	13868693          	addi	a3,a3,312 # 8000300e <usertrap>
    80002ede:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ee0:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ee2:	8692                	mv	a3,tp
    80002ee4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002eea:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002eee:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ef2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ef6:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ef8:	6f18                	ld	a4,24(a4)
    80002efa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002efe:	792c                	ld	a1,112(a0)
    80002f00:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f02:	00004717          	auipc	a4,0x4
    80002f06:	18e70713          	addi	a4,a4,398 # 80007090 <userret>
    80002f0a:	8f11                	sub	a4,a4,a2
    80002f0c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f0e:	577d                	li	a4,-1
    80002f10:	177e                	slli	a4,a4,0x3f
    80002f12:	8dd9                	or	a1,a1,a4
    80002f14:	02000537          	lui	a0,0x2000
    80002f18:	157d                	addi	a0,a0,-1
    80002f1a:	0536                	slli	a0,a0,0xd
    80002f1c:	9782                	jalr	a5
}
    80002f1e:	60a2                	ld	ra,8(sp)
    80002f20:	6402                	ld	s0,0(sp)
    80002f22:	0141                	addi	sp,sp,16
    80002f24:	8082                	ret

0000000080002f26 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	e426                	sd	s1,8(sp)
    80002f2e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f30:	00015497          	auipc	s1,0x15
    80002f34:	a6848493          	addi	s1,s1,-1432 # 80017998 <tickslock>
    80002f38:	8526                	mv	a0,s1
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	caa080e7          	jalr	-854(ra) # 80000be4 <acquire>
  ticks++;
    80002f42:	00006517          	auipc	a0,0x6
    80002f46:	0f650513          	addi	a0,a0,246 # 80009038 <ticks>
    80002f4a:	411c                	lw	a5,0(a0)
    80002f4c:	2785                	addiw	a5,a5,1
    80002f4e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	914080e7          	jalr	-1772(ra) # 80002864 <wakeup>
  release(&tickslock);
    80002f58:	8526                	mv	a0,s1
    80002f5a:	ffffe097          	auipc	ra,0xffffe
    80002f5e:	d50080e7          	jalr	-688(ra) # 80000caa <release>
}
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	64a2                	ld	s1,8(sp)
    80002f68:	6105                	addi	sp,sp,32
    80002f6a:	8082                	ret

0000000080002f6c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f6c:	1101                	addi	sp,sp,-32
    80002f6e:	ec06                	sd	ra,24(sp)
    80002f70:	e822                	sd	s0,16(sp)
    80002f72:	e426                	sd	s1,8(sp)
    80002f74:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f76:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f7a:	00074d63          	bltz	a4,80002f94 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f7e:	57fd                	li	a5,-1
    80002f80:	17fe                	slli	a5,a5,0x3f
    80002f82:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f84:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f86:	06f70363          	beq	a4,a5,80002fec <devintr+0x80>
  }
}
    80002f8a:	60e2                	ld	ra,24(sp)
    80002f8c:	6442                	ld	s0,16(sp)
    80002f8e:	64a2                	ld	s1,8(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret
     (scause & 0xff) == 9){
    80002f94:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f98:	46a5                	li	a3,9
    80002f9a:	fed792e3          	bne	a5,a3,80002f7e <devintr+0x12>
    int irq = plic_claim();
    80002f9e:	00003097          	auipc	ra,0x3
    80002fa2:	4da080e7          	jalr	1242(ra) # 80006478 <plic_claim>
    80002fa6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002fa8:	47a9                	li	a5,10
    80002faa:	02f50763          	beq	a0,a5,80002fd8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002fae:	4785                	li	a5,1
    80002fb0:	02f50963          	beq	a0,a5,80002fe2 <devintr+0x76>
    return 1;
    80002fb4:	4505                	li	a0,1
    } else if(irq){
    80002fb6:	d8f1                	beqz	s1,80002f8a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002fb8:	85a6                	mv	a1,s1
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	3d650513          	addi	a0,a0,982 # 80008390 <states.1794+0x38>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	5c6080e7          	jalr	1478(ra) # 80000588 <printf>
      plic_complete(irq);
    80002fca:	8526                	mv	a0,s1
    80002fcc:	00003097          	auipc	ra,0x3
    80002fd0:	4d0080e7          	jalr	1232(ra) # 8000649c <plic_complete>
    return 1;
    80002fd4:	4505                	li	a0,1
    80002fd6:	bf55                	j	80002f8a <devintr+0x1e>
      uartintr();
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	9d0080e7          	jalr	-1584(ra) # 800009a8 <uartintr>
    80002fe0:	b7ed                	j	80002fca <devintr+0x5e>
      virtio_disk_intr();
    80002fe2:	00004097          	auipc	ra,0x4
    80002fe6:	99a080e7          	jalr	-1638(ra) # 8000697c <virtio_disk_intr>
    80002fea:	b7c5                	j	80002fca <devintr+0x5e>
    if(cpuid() == 0){
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	da4080e7          	jalr	-604(ra) # 80001d90 <cpuid>
    80002ff4:	c901                	beqz	a0,80003004 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ff6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ffa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ffc:	14479073          	csrw	sip,a5
    return 2;
    80003000:	4509                	li	a0,2
    80003002:	b761                	j	80002f8a <devintr+0x1e>
      clockintr();
    80003004:	00000097          	auipc	ra,0x0
    80003008:	f22080e7          	jalr	-222(ra) # 80002f26 <clockintr>
    8000300c:	b7ed                	j	80002ff6 <devintr+0x8a>

000000008000300e <usertrap>:
{
    8000300e:	1101                	addi	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	e426                	sd	s1,8(sp)
    80003016:	e04a                	sd	s2,0(sp)
    80003018:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000301a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000301e:	1007f793          	andi	a5,a5,256
    80003022:	e3ad                	bnez	a5,80003084 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003024:	00003797          	auipc	a5,0x3
    80003028:	34c78793          	addi	a5,a5,844 # 80006370 <kernelvec>
    8000302c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	d94080e7          	jalr	-620(ra) # 80001dc4 <myproc>
    80003038:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000303a:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000303c:	14102773          	csrr	a4,sepc
    80003040:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003042:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003046:	47a1                	li	a5,8
    80003048:	04f71c63          	bne	a4,a5,800030a0 <usertrap+0x92>
    if(p->killed)
    8000304c:	551c                	lw	a5,40(a0)
    8000304e:	e3b9                	bnez	a5,80003094 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003050:	7cb8                	ld	a4,120(s1)
    80003052:	6f1c                	ld	a5,24(a4)
    80003054:	0791                	addi	a5,a5,4
    80003056:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003058:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000305c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003060:	10079073          	csrw	sstatus,a5
    syscall();
    80003064:	00000097          	auipc	ra,0x0
    80003068:	2e0080e7          	jalr	736(ra) # 80003344 <syscall>
  if(p->killed)
    8000306c:	549c                	lw	a5,40(s1)
    8000306e:	ebc1                	bnez	a5,800030fe <usertrap+0xf0>
  usertrapret();
    80003070:	00000097          	auipc	ra,0x0
    80003074:	e18080e7          	jalr	-488(ra) # 80002e88 <usertrapret>
}
    80003078:	60e2                	ld	ra,24(sp)
    8000307a:	6442                	ld	s0,16(sp)
    8000307c:	64a2                	ld	s1,8(sp)
    8000307e:	6902                	ld	s2,0(sp)
    80003080:	6105                	addi	sp,sp,32
    80003082:	8082                	ret
    panic("usertrap: not from user mode");
    80003084:	00005517          	auipc	a0,0x5
    80003088:	32c50513          	addi	a0,a0,812 # 800083b0 <states.1794+0x58>
    8000308c:	ffffd097          	auipc	ra,0xffffd
    80003090:	4b2080e7          	jalr	1202(ra) # 8000053e <panic>
      exit(-1);
    80003094:	557d                	li	a0,-1
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	9a4080e7          	jalr	-1628(ra) # 80002a3a <exit>
    8000309e:	bf4d                	j	80003050 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	ecc080e7          	jalr	-308(ra) # 80002f6c <devintr>
    800030a8:	892a                	mv	s2,a0
    800030aa:	c501                	beqz	a0,800030b2 <usertrap+0xa4>
  if(p->killed)
    800030ac:	549c                	lw	a5,40(s1)
    800030ae:	c3a1                	beqz	a5,800030ee <usertrap+0xe0>
    800030b0:	a815                	j	800030e4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030b2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800030b6:	5890                	lw	a2,48(s1)
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	31850513          	addi	a0,a0,792 # 800083d0 <states.1794+0x78>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	4c8080e7          	jalr	1224(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030c8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030cc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030d0:	00005517          	auipc	a0,0x5
    800030d4:	33050513          	addi	a0,a0,816 # 80008400 <states.1794+0xa8>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	4b0080e7          	jalr	1200(ra) # 80000588 <printf>
    p->killed = 1;
    800030e0:	4785                	li	a5,1
    800030e2:	d49c                	sw	a5,40(s1)
    exit(-1);
    800030e4:	557d                	li	a0,-1
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	954080e7          	jalr	-1708(ra) # 80002a3a <exit>
  if(which_dev == 2)
    800030ee:	4789                	li	a5,2
    800030f0:	f8f910e3          	bne	s2,a5,80003070 <usertrap+0x62>
    yield();
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	552080e7          	jalr	1362(ra) # 80002646 <yield>
    800030fc:	bf95                	j	80003070 <usertrap+0x62>
  int which_dev = 0;
    800030fe:	4901                	li	s2,0
    80003100:	b7d5                	j	800030e4 <usertrap+0xd6>

0000000080003102 <kerneltrap>:
{
    80003102:	7179                	addi	sp,sp,-48
    80003104:	f406                	sd	ra,40(sp)
    80003106:	f022                	sd	s0,32(sp)
    80003108:	ec26                	sd	s1,24(sp)
    8000310a:	e84a                	sd	s2,16(sp)
    8000310c:	e44e                	sd	s3,8(sp)
    8000310e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003110:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003114:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003118:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000311c:	1004f793          	andi	a5,s1,256
    80003120:	cb85                	beqz	a5,80003150 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003122:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003126:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003128:	ef85                	bnez	a5,80003160 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	e42080e7          	jalr	-446(ra) # 80002f6c <devintr>
    80003132:	cd1d                	beqz	a0,80003170 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003134:	4789                	li	a5,2
    80003136:	06f50a63          	beq	a0,a5,800031aa <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000313a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000313e:	10049073          	csrw	sstatus,s1
}
    80003142:	70a2                	ld	ra,40(sp)
    80003144:	7402                	ld	s0,32(sp)
    80003146:	64e2                	ld	s1,24(sp)
    80003148:	6942                	ld	s2,16(sp)
    8000314a:	69a2                	ld	s3,8(sp)
    8000314c:	6145                	addi	sp,sp,48
    8000314e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003150:	00005517          	auipc	a0,0x5
    80003154:	2d050513          	addi	a0,a0,720 # 80008420 <states.1794+0xc8>
    80003158:	ffffd097          	auipc	ra,0xffffd
    8000315c:	3e6080e7          	jalr	998(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003160:	00005517          	auipc	a0,0x5
    80003164:	2e850513          	addi	a0,a0,744 # 80008448 <states.1794+0xf0>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	3d6080e7          	jalr	982(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003170:	85ce                	mv	a1,s3
    80003172:	00005517          	auipc	a0,0x5
    80003176:	2f650513          	addi	a0,a0,758 # 80008468 <states.1794+0x110>
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	40e080e7          	jalr	1038(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003182:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003186:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	2ee50513          	addi	a0,a0,750 # 80008478 <states.1794+0x120>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	3f6080e7          	jalr	1014(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000319a:	00005517          	auipc	a0,0x5
    8000319e:	2f650513          	addi	a0,a0,758 # 80008490 <states.1794+0x138>
    800031a2:	ffffd097          	auipc	ra,0xffffd
    800031a6:	39c080e7          	jalr	924(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031aa:	fffff097          	auipc	ra,0xfffff
    800031ae:	c1a080e7          	jalr	-998(ra) # 80001dc4 <myproc>
    800031b2:	d541                	beqz	a0,8000313a <kerneltrap+0x38>
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	c10080e7          	jalr	-1008(ra) # 80001dc4 <myproc>
    800031bc:	4d18                	lw	a4,24(a0)
    800031be:	4791                	li	a5,4
    800031c0:	f6f71de3          	bne	a4,a5,8000313a <kerneltrap+0x38>
    yield();
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	482080e7          	jalr	1154(ra) # 80002646 <yield>
    800031cc:	b7bd                	j	8000313a <kerneltrap+0x38>

00000000800031ce <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800031ce:	1101                	addi	sp,sp,-32
    800031d0:	ec06                	sd	ra,24(sp)
    800031d2:	e822                	sd	s0,16(sp)
    800031d4:	e426                	sd	s1,8(sp)
    800031d6:	1000                	addi	s0,sp,32
    800031d8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	bea080e7          	jalr	-1046(ra) # 80001dc4 <myproc>
  switch (n) {
    800031e2:	4795                	li	a5,5
    800031e4:	0497e163          	bltu	a5,s1,80003226 <argraw+0x58>
    800031e8:	048a                	slli	s1,s1,0x2
    800031ea:	00005717          	auipc	a4,0x5
    800031ee:	2de70713          	addi	a4,a4,734 # 800084c8 <states.1794+0x170>
    800031f2:	94ba                	add	s1,s1,a4
    800031f4:	409c                	lw	a5,0(s1)
    800031f6:	97ba                	add	a5,a5,a4
    800031f8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031fa:	7d3c                	ld	a5,120(a0)
    800031fc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031fe:	60e2                	ld	ra,24(sp)
    80003200:	6442                	ld	s0,16(sp)
    80003202:	64a2                	ld	s1,8(sp)
    80003204:	6105                	addi	sp,sp,32
    80003206:	8082                	ret
    return p->trapframe->a1;
    80003208:	7d3c                	ld	a5,120(a0)
    8000320a:	7fa8                	ld	a0,120(a5)
    8000320c:	bfcd                	j	800031fe <argraw+0x30>
    return p->trapframe->a2;
    8000320e:	7d3c                	ld	a5,120(a0)
    80003210:	63c8                	ld	a0,128(a5)
    80003212:	b7f5                	j	800031fe <argraw+0x30>
    return p->trapframe->a3;
    80003214:	7d3c                	ld	a5,120(a0)
    80003216:	67c8                	ld	a0,136(a5)
    80003218:	b7dd                	j	800031fe <argraw+0x30>
    return p->trapframe->a4;
    8000321a:	7d3c                	ld	a5,120(a0)
    8000321c:	6bc8                	ld	a0,144(a5)
    8000321e:	b7c5                	j	800031fe <argraw+0x30>
    return p->trapframe->a5;
    80003220:	7d3c                	ld	a5,120(a0)
    80003222:	6fc8                	ld	a0,152(a5)
    80003224:	bfe9                	j	800031fe <argraw+0x30>
  panic("argraw");
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	27a50513          	addi	a0,a0,634 # 800084a0 <states.1794+0x148>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	310080e7          	jalr	784(ra) # 8000053e <panic>

0000000080003236 <fetchaddr>:
{
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	e426                	sd	s1,8(sp)
    8000323e:	e04a                	sd	s2,0(sp)
    80003240:	1000                	addi	s0,sp,32
    80003242:	84aa                	mv	s1,a0
    80003244:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	b7e080e7          	jalr	-1154(ra) # 80001dc4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000324e:	753c                	ld	a5,104(a0)
    80003250:	02f4f863          	bgeu	s1,a5,80003280 <fetchaddr+0x4a>
    80003254:	00848713          	addi	a4,s1,8
    80003258:	02e7e663          	bltu	a5,a4,80003284 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000325c:	46a1                	li	a3,8
    8000325e:	8626                	mv	a2,s1
    80003260:	85ca                	mv	a1,s2
    80003262:	7928                	ld	a0,112(a0)
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	4be080e7          	jalr	1214(ra) # 80001722 <copyin>
    8000326c:	00a03533          	snez	a0,a0
    80003270:	40a00533          	neg	a0,a0
}
    80003274:	60e2                	ld	ra,24(sp)
    80003276:	6442                	ld	s0,16(sp)
    80003278:	64a2                	ld	s1,8(sp)
    8000327a:	6902                	ld	s2,0(sp)
    8000327c:	6105                	addi	sp,sp,32
    8000327e:	8082                	ret
    return -1;
    80003280:	557d                	li	a0,-1
    80003282:	bfcd                	j	80003274 <fetchaddr+0x3e>
    80003284:	557d                	li	a0,-1
    80003286:	b7fd                	j	80003274 <fetchaddr+0x3e>

0000000080003288 <fetchstr>:
{
    80003288:	7179                	addi	sp,sp,-48
    8000328a:	f406                	sd	ra,40(sp)
    8000328c:	f022                	sd	s0,32(sp)
    8000328e:	ec26                	sd	s1,24(sp)
    80003290:	e84a                	sd	s2,16(sp)
    80003292:	e44e                	sd	s3,8(sp)
    80003294:	1800                	addi	s0,sp,48
    80003296:	892a                	mv	s2,a0
    80003298:	84ae                	mv	s1,a1
    8000329a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000329c:	fffff097          	auipc	ra,0xfffff
    800032a0:	b28080e7          	jalr	-1240(ra) # 80001dc4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800032a4:	86ce                	mv	a3,s3
    800032a6:	864a                	mv	a2,s2
    800032a8:	85a6                	mv	a1,s1
    800032aa:	7928                	ld	a0,112(a0)
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	502080e7          	jalr	1282(ra) # 800017ae <copyinstr>
  if(err < 0)
    800032b4:	00054763          	bltz	a0,800032c2 <fetchstr+0x3a>
  return strlen(buf);
    800032b8:	8526                	mv	a0,s1
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	bce080e7          	jalr	-1074(ra) # 80000e88 <strlen>
}
    800032c2:	70a2                	ld	ra,40(sp)
    800032c4:	7402                	ld	s0,32(sp)
    800032c6:	64e2                	ld	s1,24(sp)
    800032c8:	6942                	ld	s2,16(sp)
    800032ca:	69a2                	ld	s3,8(sp)
    800032cc:	6145                	addi	sp,sp,48
    800032ce:	8082                	ret

00000000800032d0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800032d0:	1101                	addi	sp,sp,-32
    800032d2:	ec06                	sd	ra,24(sp)
    800032d4:	e822                	sd	s0,16(sp)
    800032d6:	e426                	sd	s1,8(sp)
    800032d8:	1000                	addi	s0,sp,32
    800032da:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	ef2080e7          	jalr	-270(ra) # 800031ce <argraw>
    800032e4:	c088                	sw	a0,0(s1)
  return 0;
}
    800032e6:	4501                	li	a0,0
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret

00000000800032f2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	1000                	addi	s0,sp,32
    800032fc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	ed0080e7          	jalr	-304(ra) # 800031ce <argraw>
    80003306:	e088                	sd	a0,0(s1)
  return 0;
}
    80003308:	4501                	li	a0,0
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6105                	addi	sp,sp,32
    80003312:	8082                	ret

0000000080003314 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003314:	1101                	addi	sp,sp,-32
    80003316:	ec06                	sd	ra,24(sp)
    80003318:	e822                	sd	s0,16(sp)
    8000331a:	e426                	sd	s1,8(sp)
    8000331c:	e04a                	sd	s2,0(sp)
    8000331e:	1000                	addi	s0,sp,32
    80003320:	84ae                	mv	s1,a1
    80003322:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003324:	00000097          	auipc	ra,0x0
    80003328:	eaa080e7          	jalr	-342(ra) # 800031ce <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000332c:	864a                	mv	a2,s2
    8000332e:	85a6                	mv	a1,s1
    80003330:	00000097          	auipc	ra,0x0
    80003334:	f58080e7          	jalr	-168(ra) # 80003288 <fetchstr>
}
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	64a2                	ld	s1,8(sp)
    8000333e:	6902                	ld	s2,0(sp)
    80003340:	6105                	addi	sp,sp,32
    80003342:	8082                	ret

0000000080003344 <syscall>:
[SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    80003344:	1101                	addi	sp,sp,-32
    80003346:	ec06                	sd	ra,24(sp)
    80003348:	e822                	sd	s0,16(sp)
    8000334a:	e426                	sd	s1,8(sp)
    8000334c:	e04a                	sd	s2,0(sp)
    8000334e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003350:	fffff097          	auipc	ra,0xfffff
    80003354:	a74080e7          	jalr	-1420(ra) # 80001dc4 <myproc>
    80003358:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000335a:	07853903          	ld	s2,120(a0)
    8000335e:	0a893783          	ld	a5,168(s2)
    80003362:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003366:	37fd                	addiw	a5,a5,-1
    80003368:	475d                	li	a4,23
    8000336a:	00f76f63          	bltu	a4,a5,80003388 <syscall+0x44>
    8000336e:	00369713          	slli	a4,a3,0x3
    80003372:	00005797          	auipc	a5,0x5
    80003376:	16e78793          	addi	a5,a5,366 # 800084e0 <syscalls>
    8000337a:	97ba                	add	a5,a5,a4
    8000337c:	639c                	ld	a5,0(a5)
    8000337e:	c789                	beqz	a5,80003388 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003380:	9782                	jalr	a5
    80003382:	06a93823          	sd	a0,112(s2)
    80003386:	a839                	j	800033a4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003388:	17848613          	addi	a2,s1,376
    8000338c:	588c                	lw	a1,48(s1)
    8000338e:	00005517          	auipc	a0,0x5
    80003392:	11a50513          	addi	a0,a0,282 # 800084a8 <states.1794+0x150>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	1f2080e7          	jalr	498(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000339e:	7cbc                	ld	a5,120(s1)
    800033a0:	577d                	li	a4,-1
    800033a2:	fbb8                	sd	a4,112(a5)
  }
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6902                	ld	s2,0(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800033b8:	fec40593          	addi	a1,s0,-20
    800033bc:	4501                	li	a0,0
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	f12080e7          	jalr	-238(ra) # 800032d0 <argint>
    return -1;
    800033c6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033c8:	00054963          	bltz	a0,800033da <sys_exit+0x2a>
  exit(n);
    800033cc:	fec42503          	lw	a0,-20(s0)
    800033d0:	fffff097          	auipc	ra,0xfffff
    800033d4:	66a080e7          	jalr	1642(ra) # 80002a3a <exit>
  return 0;  // not reached
    800033d8:	4781                	li	a5,0
}
    800033da:	853e                	mv	a0,a5
    800033dc:	60e2                	ld	ra,24(sp)
    800033de:	6442                	ld	s0,16(sp)
    800033e0:	6105                	addi	sp,sp,32
    800033e2:	8082                	ret

00000000800033e4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033e4:	1141                	addi	sp,sp,-16
    800033e6:	e406                	sd	ra,8(sp)
    800033e8:	e022                	sd	s0,0(sp)
    800033ea:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033ec:	fffff097          	auipc	ra,0xfffff
    800033f0:	9d8080e7          	jalr	-1576(ra) # 80001dc4 <myproc>
}
    800033f4:	5908                	lw	a0,48(a0)
    800033f6:	60a2                	ld	ra,8(sp)
    800033f8:	6402                	ld	s0,0(sp)
    800033fa:	0141                	addi	sp,sp,16
    800033fc:	8082                	ret

00000000800033fe <sys_fork>:

uint64
sys_fork(void)
{
    800033fe:	1141                	addi	sp,sp,-16
    80003400:	e406                	sd	ra,8(sp)
    80003402:	e022                	sd	s0,0(sp)
    80003404:	0800                	addi	s0,sp,16
  return fork();
    80003406:	fffff097          	auipc	ra,0xfffff
    8000340a:	e76080e7          	jalr	-394(ra) # 8000227c <fork>
}
    8000340e:	60a2                	ld	ra,8(sp)
    80003410:	6402                	ld	s0,0(sp)
    80003412:	0141                	addi	sp,sp,16
    80003414:	8082                	ret

0000000080003416 <sys_wait>:

uint64
sys_wait(void)
{
    80003416:	1101                	addi	sp,sp,-32
    80003418:	ec06                	sd	ra,24(sp)
    8000341a:	e822                	sd	s0,16(sp)
    8000341c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000341e:	fe840593          	addi	a1,s0,-24
    80003422:	4501                	li	a0,0
    80003424:	00000097          	auipc	ra,0x0
    80003428:	ece080e7          	jalr	-306(ra) # 800032f2 <argaddr>
    8000342c:	87aa                	mv	a5,a0
    return -1;
    8000342e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003430:	0007c863          	bltz	a5,80003440 <sys_wait+0x2a>
  return wait(p);
    80003434:	fe843503          	ld	a0,-24(s0)
    80003438:	fffff097          	auipc	ra,0xfffff
    8000343c:	304080e7          	jalr	772(ra) # 8000273c <wait>
}
    80003440:	60e2                	ld	ra,24(sp)
    80003442:	6442                	ld	s0,16(sp)
    80003444:	6105                	addi	sp,sp,32
    80003446:	8082                	ret

0000000080003448 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003448:	7179                	addi	sp,sp,-48
    8000344a:	f406                	sd	ra,40(sp)
    8000344c:	f022                	sd	s0,32(sp)
    8000344e:	ec26                	sd	s1,24(sp)
    80003450:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003452:	fdc40593          	addi	a1,s0,-36
    80003456:	4501                	li	a0,0
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e78080e7          	jalr	-392(ra) # 800032d0 <argint>
    80003460:	87aa                	mv	a5,a0
    return -1;
    80003462:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003464:	0207c063          	bltz	a5,80003484 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003468:	fffff097          	auipc	ra,0xfffff
    8000346c:	95c080e7          	jalr	-1700(ra) # 80001dc4 <myproc>
    80003470:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003472:	fdc42503          	lw	a0,-36(s0)
    80003476:	fffff097          	auipc	ra,0xfffff
    8000347a:	d92080e7          	jalr	-622(ra) # 80002208 <growproc>
    8000347e:	00054863          	bltz	a0,8000348e <sys_sbrk+0x46>
    return -1;
  return addr;
    80003482:	8526                	mv	a0,s1
}
    80003484:	70a2                	ld	ra,40(sp)
    80003486:	7402                	ld	s0,32(sp)
    80003488:	64e2                	ld	s1,24(sp)
    8000348a:	6145                	addi	sp,sp,48
    8000348c:	8082                	ret
    return -1;
    8000348e:	557d                	li	a0,-1
    80003490:	bfd5                	j	80003484 <sys_sbrk+0x3c>

0000000080003492 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003492:	7139                	addi	sp,sp,-64
    80003494:	fc06                	sd	ra,56(sp)
    80003496:	f822                	sd	s0,48(sp)
    80003498:	f426                	sd	s1,40(sp)
    8000349a:	f04a                	sd	s2,32(sp)
    8000349c:	ec4e                	sd	s3,24(sp)
    8000349e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800034a0:	fcc40593          	addi	a1,s0,-52
    800034a4:	4501                	li	a0,0
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	e2a080e7          	jalr	-470(ra) # 800032d0 <argint>
    return -1;
    800034ae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034b0:	06054563          	bltz	a0,8000351a <sys_sleep+0x88>
  acquire(&tickslock);
    800034b4:	00014517          	auipc	a0,0x14
    800034b8:	4e450513          	addi	a0,a0,1252 # 80017998 <tickslock>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	728080e7          	jalr	1832(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800034c4:	00006917          	auipc	s2,0x6
    800034c8:	b7492903          	lw	s2,-1164(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    800034cc:	fcc42783          	lw	a5,-52(s0)
    800034d0:	cf85                	beqz	a5,80003508 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034d2:	00014997          	auipc	s3,0x14
    800034d6:	4c698993          	addi	s3,s3,1222 # 80017998 <tickslock>
    800034da:	00006497          	auipc	s1,0x6
    800034de:	b5e48493          	addi	s1,s1,-1186 # 80009038 <ticks>
    if(myproc()->killed){
    800034e2:	fffff097          	auipc	ra,0xfffff
    800034e6:	8e2080e7          	jalr	-1822(ra) # 80001dc4 <myproc>
    800034ea:	551c                	lw	a5,40(a0)
    800034ec:	ef9d                	bnez	a5,8000352a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034ee:	85ce                	mv	a1,s3
    800034f0:	8526                	mv	a0,s1
    800034f2:	fffff097          	auipc	ra,0xfffff
    800034f6:	1ba080e7          	jalr	442(ra) # 800026ac <sleep>
  while(ticks - ticks0 < n){
    800034fa:	409c                	lw	a5,0(s1)
    800034fc:	412787bb          	subw	a5,a5,s2
    80003500:	fcc42703          	lw	a4,-52(s0)
    80003504:	fce7efe3          	bltu	a5,a4,800034e2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003508:	00014517          	auipc	a0,0x14
    8000350c:	49050513          	addi	a0,a0,1168 # 80017998 <tickslock>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	79a080e7          	jalr	1946(ra) # 80000caa <release>
  return 0;
    80003518:	4781                	li	a5,0
}
    8000351a:	853e                	mv	a0,a5
    8000351c:	70e2                	ld	ra,56(sp)
    8000351e:	7442                	ld	s0,48(sp)
    80003520:	74a2                	ld	s1,40(sp)
    80003522:	7902                	ld	s2,32(sp)
    80003524:	69e2                	ld	s3,24(sp)
    80003526:	6121                	addi	sp,sp,64
    80003528:	8082                	ret
      release(&tickslock);
    8000352a:	00014517          	auipc	a0,0x14
    8000352e:	46e50513          	addi	a0,a0,1134 # 80017998 <tickslock>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	778080e7          	jalr	1912(ra) # 80000caa <release>
      return -1;
    8000353a:	57fd                	li	a5,-1
    8000353c:	bff9                	j	8000351a <sys_sleep+0x88>

000000008000353e <sys_kill>:

uint64
sys_kill(void)
{
    8000353e:	1101                	addi	sp,sp,-32
    80003540:	ec06                	sd	ra,24(sp)
    80003542:	e822                	sd	s0,16(sp)
    80003544:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003546:	fec40593          	addi	a1,s0,-20
    8000354a:	4501                	li	a0,0
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	d84080e7          	jalr	-636(ra) # 800032d0 <argint>
    80003554:	87aa                	mv	a5,a0
    return -1;
    80003556:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003558:	0007c863          	bltz	a5,80003568 <sys_kill+0x2a>
  return kill(pid);
    8000355c:	fec42503          	lw	a0,-20(s0)
    80003560:	fffff097          	auipc	ra,0xfffff
    80003564:	5cc080e7          	jalr	1484(ra) # 80002b2c <kill>
}
    80003568:	60e2                	ld	ra,24(sp)
    8000356a:	6442                	ld	s0,16(sp)
    8000356c:	6105                	addi	sp,sp,32
    8000356e:	8082                	ret

0000000080003570 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003570:	1101                	addi	sp,sp,-32
    80003572:	ec06                	sd	ra,24(sp)
    80003574:	e822                	sd	s0,16(sp)
    80003576:	e426                	sd	s1,8(sp)
    80003578:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000357a:	00014517          	auipc	a0,0x14
    8000357e:	41e50513          	addi	a0,a0,1054 # 80017998 <tickslock>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	662080e7          	jalr	1634(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000358a:	00006497          	auipc	s1,0x6
    8000358e:	aae4a483          	lw	s1,-1362(s1) # 80009038 <ticks>
  release(&tickslock);
    80003592:	00014517          	auipc	a0,0x14
    80003596:	40650513          	addi	a0,a0,1030 # 80017998 <tickslock>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	710080e7          	jalr	1808(ra) # 80000caa <release>
  return xticks;
}
    800035a2:	02049513          	slli	a0,s1,0x20
    800035a6:	9101                	srli	a0,a0,0x20
    800035a8:	60e2                	ld	ra,24(sp)
    800035aa:	6442                	ld	s0,16(sp)
    800035ac:	64a2                	ld	s1,8(sp)
    800035ae:	6105                	addi	sp,sp,32
    800035b0:	8082                	ret

00000000800035b2 <sys_get_cpu>:

uint64
sys_get_cpu(void){
    800035b2:	1141                	addi	sp,sp,-16
    800035b4:	e406                	sd	ra,8(sp)
    800035b6:	e022                	sd	s0,0(sp)
    800035b8:	0800                	addi	s0,sp,16
  return get_cpu();
    800035ba:	fffff097          	auipc	ra,0xfffff
    800035be:	7d2080e7          	jalr	2002(ra) # 80002d8c <get_cpu>
}
    800035c2:	60a2                	ld	ra,8(sp)
    800035c4:	6402                	ld	s0,0(sp)
    800035c6:	0141                	addi	sp,sp,16
    800035c8:	8082                	ret

00000000800035ca <sys_set_cpu>:

uint64
sys_set_cpu(void){
    800035ca:	1101                	addi	sp,sp,-32
    800035cc:	ec06                	sd	ra,24(sp)
    800035ce:	e822                	sd	s0,16(sp)
    800035d0:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    800035d2:	fec40593          	addi	a1,s0,-20
    800035d6:	4501                	li	a0,0
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	cf8080e7          	jalr	-776(ra) # 800032d0 <argint>
    800035e0:	87aa                	mv	a5,a0
    return -1;
    800035e2:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800035e4:	0007c863          	bltz	a5,800035f4 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    800035e8:	fec42503          	lw	a0,-20(s0)
    800035ec:	fffff097          	auipc	ra,0xfffff
    800035f0:	762080e7          	jalr	1890(ra) # 80002d4e <set_cpu>
}
    800035f4:	60e2                	ld	ra,24(sp)
    800035f6:	6442                	ld	s0,16(sp)
    800035f8:	6105                	addi	sp,sp,32
    800035fa:	8082                	ret

00000000800035fc <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    800035fc:	1101                	addi	sp,sp,-32
    800035fe:	ec06                	sd	ra,24(sp)
    80003600:	e822                	sd	s0,16(sp)
    80003602:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80003604:	fec40593          	addi	a1,s0,-20
    80003608:	4501                	li	a0,0
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	cc6080e7          	jalr	-826(ra) # 800032d0 <argint>
    80003612:	87aa                	mv	a5,a0
    return -1;
    80003614:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80003616:	0007c863          	bltz	a5,80003626 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_num);
    8000361a:	fec42503          	lw	a0,-20(s0)
    8000361e:	fffff097          	auipc	ra,0xfffff
    80003622:	79e080e7          	jalr	1950(ra) # 80002dbc <cpu_process_count>
}
    80003626:	60e2                	ld	ra,24(sp)
    80003628:	6442                	ld	s0,16(sp)
    8000362a:	6105                	addi	sp,sp,32
    8000362c:	8082                	ret

000000008000362e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000362e:	7179                	addi	sp,sp,-48
    80003630:	f406                	sd	ra,40(sp)
    80003632:	f022                	sd	s0,32(sp)
    80003634:	ec26                	sd	s1,24(sp)
    80003636:	e84a                	sd	s2,16(sp)
    80003638:	e44e                	sd	s3,8(sp)
    8000363a:	e052                	sd	s4,0(sp)
    8000363c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000363e:	00005597          	auipc	a1,0x5
    80003642:	f6a58593          	addi	a1,a1,-150 # 800085a8 <syscalls+0xc8>
    80003646:	00014517          	auipc	a0,0x14
    8000364a:	36a50513          	addi	a0,a0,874 # 800179b0 <bcache>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	506080e7          	jalr	1286(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003656:	0001c797          	auipc	a5,0x1c
    8000365a:	35a78793          	addi	a5,a5,858 # 8001f9b0 <bcache+0x8000>
    8000365e:	0001c717          	auipc	a4,0x1c
    80003662:	5ba70713          	addi	a4,a4,1466 # 8001fc18 <bcache+0x8268>
    80003666:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000366a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000366e:	00014497          	auipc	s1,0x14
    80003672:	35a48493          	addi	s1,s1,858 # 800179c8 <bcache+0x18>
    b->next = bcache.head.next;
    80003676:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003678:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000367a:	00005a17          	auipc	s4,0x5
    8000367e:	f36a0a13          	addi	s4,s4,-202 # 800085b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003682:	2b893783          	ld	a5,696(s2)
    80003686:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003688:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000368c:	85d2                	mv	a1,s4
    8000368e:	01048513          	addi	a0,s1,16
    80003692:	00001097          	auipc	ra,0x1
    80003696:	4bc080e7          	jalr	1212(ra) # 80004b4e <initsleeplock>
    bcache.head.next->prev = b;
    8000369a:	2b893783          	ld	a5,696(s2)
    8000369e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036a4:	45848493          	addi	s1,s1,1112
    800036a8:	fd349de3          	bne	s1,s3,80003682 <binit+0x54>
  }
}
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6a02                	ld	s4,0(sp)
    800036b8:	6145                	addi	sp,sp,48
    800036ba:	8082                	ret

00000000800036bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036bc:	7179                	addi	sp,sp,-48
    800036be:	f406                	sd	ra,40(sp)
    800036c0:	f022                	sd	s0,32(sp)
    800036c2:	ec26                	sd	s1,24(sp)
    800036c4:	e84a                	sd	s2,16(sp)
    800036c6:	e44e                	sd	s3,8(sp)
    800036c8:	1800                	addi	s0,sp,48
    800036ca:	89aa                	mv	s3,a0
    800036cc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800036ce:	00014517          	auipc	a0,0x14
    800036d2:	2e250513          	addi	a0,a0,738 # 800179b0 <bcache>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	50e080e7          	jalr	1294(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036de:	0001c497          	auipc	s1,0x1c
    800036e2:	58a4b483          	ld	s1,1418(s1) # 8001fc68 <bcache+0x82b8>
    800036e6:	0001c797          	auipc	a5,0x1c
    800036ea:	53278793          	addi	a5,a5,1330 # 8001fc18 <bcache+0x8268>
    800036ee:	02f48f63          	beq	s1,a5,8000372c <bread+0x70>
    800036f2:	873e                	mv	a4,a5
    800036f4:	a021                	j	800036fc <bread+0x40>
    800036f6:	68a4                	ld	s1,80(s1)
    800036f8:	02e48a63          	beq	s1,a4,8000372c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036fc:	449c                	lw	a5,8(s1)
    800036fe:	ff379ce3          	bne	a5,s3,800036f6 <bread+0x3a>
    80003702:	44dc                	lw	a5,12(s1)
    80003704:	ff2799e3          	bne	a5,s2,800036f6 <bread+0x3a>
      b->refcnt++;
    80003708:	40bc                	lw	a5,64(s1)
    8000370a:	2785                	addiw	a5,a5,1
    8000370c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000370e:	00014517          	auipc	a0,0x14
    80003712:	2a250513          	addi	a0,a0,674 # 800179b0 <bcache>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	594080e7          	jalr	1428(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000371e:	01048513          	addi	a0,s1,16
    80003722:	00001097          	auipc	ra,0x1
    80003726:	466080e7          	jalr	1126(ra) # 80004b88 <acquiresleep>
      return b;
    8000372a:	a8b9                	j	80003788 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000372c:	0001c497          	auipc	s1,0x1c
    80003730:	5344b483          	ld	s1,1332(s1) # 8001fc60 <bcache+0x82b0>
    80003734:	0001c797          	auipc	a5,0x1c
    80003738:	4e478793          	addi	a5,a5,1252 # 8001fc18 <bcache+0x8268>
    8000373c:	00f48863          	beq	s1,a5,8000374c <bread+0x90>
    80003740:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003742:	40bc                	lw	a5,64(s1)
    80003744:	cf81                	beqz	a5,8000375c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003746:	64a4                	ld	s1,72(s1)
    80003748:	fee49de3          	bne	s1,a4,80003742 <bread+0x86>
  panic("bget: no buffers");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	e6c50513          	addi	a0,a0,-404 # 800085b8 <syscalls+0xd8>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	dea080e7          	jalr	-534(ra) # 8000053e <panic>
      b->dev = dev;
    8000375c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003760:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003764:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003768:	4785                	li	a5,1
    8000376a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000376c:	00014517          	auipc	a0,0x14
    80003770:	24450513          	addi	a0,a0,580 # 800179b0 <bcache>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	536080e7          	jalr	1334(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000377c:	01048513          	addi	a0,s1,16
    80003780:	00001097          	auipc	ra,0x1
    80003784:	408080e7          	jalr	1032(ra) # 80004b88 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003788:	409c                	lw	a5,0(s1)
    8000378a:	cb89                	beqz	a5,8000379c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000378c:	8526                	mv	a0,s1
    8000378e:	70a2                	ld	ra,40(sp)
    80003790:	7402                	ld	s0,32(sp)
    80003792:	64e2                	ld	s1,24(sp)
    80003794:	6942                	ld	s2,16(sp)
    80003796:	69a2                	ld	s3,8(sp)
    80003798:	6145                	addi	sp,sp,48
    8000379a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000379c:	4581                	li	a1,0
    8000379e:	8526                	mv	a0,s1
    800037a0:	00003097          	auipc	ra,0x3
    800037a4:	f06080e7          	jalr	-250(ra) # 800066a6 <virtio_disk_rw>
    b->valid = 1;
    800037a8:	4785                	li	a5,1
    800037aa:	c09c                	sw	a5,0(s1)
  return b;
    800037ac:	b7c5                	j	8000378c <bread+0xd0>

00000000800037ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	1000                	addi	s0,sp,32
    800037b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037ba:	0541                	addi	a0,a0,16
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	466080e7          	jalr	1126(ra) # 80004c22 <holdingsleep>
    800037c4:	cd01                	beqz	a0,800037dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037c6:	4585                	li	a1,1
    800037c8:	8526                	mv	a0,s1
    800037ca:	00003097          	auipc	ra,0x3
    800037ce:	edc080e7          	jalr	-292(ra) # 800066a6 <virtio_disk_rw>
}
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	64a2                	ld	s1,8(sp)
    800037d8:	6105                	addi	sp,sp,32
    800037da:	8082                	ret
    panic("bwrite");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	df450513          	addi	a0,a0,-524 # 800085d0 <syscalls+0xf0>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d5a080e7          	jalr	-678(ra) # 8000053e <panic>

00000000800037ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037ec:	1101                	addi	sp,sp,-32
    800037ee:	ec06                	sd	ra,24(sp)
    800037f0:	e822                	sd	s0,16(sp)
    800037f2:	e426                	sd	s1,8(sp)
    800037f4:	e04a                	sd	s2,0(sp)
    800037f6:	1000                	addi	s0,sp,32
    800037f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037fa:	01050913          	addi	s2,a0,16
    800037fe:	854a                	mv	a0,s2
    80003800:	00001097          	auipc	ra,0x1
    80003804:	422080e7          	jalr	1058(ra) # 80004c22 <holdingsleep>
    80003808:	c92d                	beqz	a0,8000387a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	3d2080e7          	jalr	978(ra) # 80004bde <releasesleep>

  acquire(&bcache.lock);
    80003814:	00014517          	auipc	a0,0x14
    80003818:	19c50513          	addi	a0,a0,412 # 800179b0 <bcache>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	3c8080e7          	jalr	968(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003824:	40bc                	lw	a5,64(s1)
    80003826:	37fd                	addiw	a5,a5,-1
    80003828:	0007871b          	sext.w	a4,a5
    8000382c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000382e:	eb05                	bnez	a4,8000385e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003830:	68bc                	ld	a5,80(s1)
    80003832:	64b8                	ld	a4,72(s1)
    80003834:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003836:	64bc                	ld	a5,72(s1)
    80003838:	68b8                	ld	a4,80(s1)
    8000383a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000383c:	0001c797          	auipc	a5,0x1c
    80003840:	17478793          	addi	a5,a5,372 # 8001f9b0 <bcache+0x8000>
    80003844:	2b87b703          	ld	a4,696(a5)
    80003848:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000384a:	0001c717          	auipc	a4,0x1c
    8000384e:	3ce70713          	addi	a4,a4,974 # 8001fc18 <bcache+0x8268>
    80003852:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003854:	2b87b703          	ld	a4,696(a5)
    80003858:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000385a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000385e:	00014517          	auipc	a0,0x14
    80003862:	15250513          	addi	a0,a0,338 # 800179b0 <bcache>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	444080e7          	jalr	1092(ra) # 80000caa <release>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret
    panic("brelse");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	d5e50513          	addi	a0,a0,-674 # 800085d8 <syscalls+0xf8>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cbc080e7          	jalr	-836(ra) # 8000053e <panic>

000000008000388a <bpin>:

void
bpin(struct buf *b) {
    8000388a:	1101                	addi	sp,sp,-32
    8000388c:	ec06                	sd	ra,24(sp)
    8000388e:	e822                	sd	s0,16(sp)
    80003890:	e426                	sd	s1,8(sp)
    80003892:	1000                	addi	s0,sp,32
    80003894:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003896:	00014517          	auipc	a0,0x14
    8000389a:	11a50513          	addi	a0,a0,282 # 800179b0 <bcache>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	346080e7          	jalr	838(ra) # 80000be4 <acquire>
  b->refcnt++;
    800038a6:	40bc                	lw	a5,64(s1)
    800038a8:	2785                	addiw	a5,a5,1
    800038aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ac:	00014517          	auipc	a0,0x14
    800038b0:	10450513          	addi	a0,a0,260 # 800179b0 <bcache>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	3f6080e7          	jalr	1014(ra) # 80000caa <release>
}
    800038bc:	60e2                	ld	ra,24(sp)
    800038be:	6442                	ld	s0,16(sp)
    800038c0:	64a2                	ld	s1,8(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret

00000000800038c6 <bunpin>:

void
bunpin(struct buf *b) {
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	e426                	sd	s1,8(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d2:	00014517          	auipc	a0,0x14
    800038d6:	0de50513          	addi	a0,a0,222 # 800179b0 <bcache>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	30a080e7          	jalr	778(ra) # 80000be4 <acquire>
  b->refcnt--;
    800038e2:	40bc                	lw	a5,64(s1)
    800038e4:	37fd                	addiw	a5,a5,-1
    800038e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038e8:	00014517          	auipc	a0,0x14
    800038ec:	0c850513          	addi	a0,a0,200 # 800179b0 <bcache>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	3ba080e7          	jalr	954(ra) # 80000caa <release>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret

0000000080003902 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
    8000390e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003910:	00d5d59b          	srliw	a1,a1,0xd
    80003914:	0001c797          	auipc	a5,0x1c
    80003918:	7787a783          	lw	a5,1912(a5) # 8002008c <sb+0x1c>
    8000391c:	9dbd                	addw	a1,a1,a5
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	d9e080e7          	jalr	-610(ra) # 800036bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003926:	0074f713          	andi	a4,s1,7
    8000392a:	4785                	li	a5,1
    8000392c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003930:	14ce                	slli	s1,s1,0x33
    80003932:	90d9                	srli	s1,s1,0x36
    80003934:	00950733          	add	a4,a0,s1
    80003938:	05874703          	lbu	a4,88(a4)
    8000393c:	00e7f6b3          	and	a3,a5,a4
    80003940:	c69d                	beqz	a3,8000396e <bfree+0x6c>
    80003942:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003944:	94aa                	add	s1,s1,a0
    80003946:	fff7c793          	not	a5,a5
    8000394a:	8ff9                	and	a5,a5,a4
    8000394c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003950:	00001097          	auipc	ra,0x1
    80003954:	118080e7          	jalr	280(ra) # 80004a68 <log_write>
  brelse(bp);
    80003958:	854a                	mv	a0,s2
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	e92080e7          	jalr	-366(ra) # 800037ec <brelse>
}
    80003962:	60e2                	ld	ra,24(sp)
    80003964:	6442                	ld	s0,16(sp)
    80003966:	64a2                	ld	s1,8(sp)
    80003968:	6902                	ld	s2,0(sp)
    8000396a:	6105                	addi	sp,sp,32
    8000396c:	8082                	ret
    panic("freeing free block");
    8000396e:	00005517          	auipc	a0,0x5
    80003972:	c7250513          	addi	a0,a0,-910 # 800085e0 <syscalls+0x100>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	bc8080e7          	jalr	-1080(ra) # 8000053e <panic>

000000008000397e <balloc>:
{
    8000397e:	711d                	addi	sp,sp,-96
    80003980:	ec86                	sd	ra,88(sp)
    80003982:	e8a2                	sd	s0,80(sp)
    80003984:	e4a6                	sd	s1,72(sp)
    80003986:	e0ca                	sd	s2,64(sp)
    80003988:	fc4e                	sd	s3,56(sp)
    8000398a:	f852                	sd	s4,48(sp)
    8000398c:	f456                	sd	s5,40(sp)
    8000398e:	f05a                	sd	s6,32(sp)
    80003990:	ec5e                	sd	s7,24(sp)
    80003992:	e862                	sd	s8,16(sp)
    80003994:	e466                	sd	s9,8(sp)
    80003996:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003998:	0001c797          	auipc	a5,0x1c
    8000399c:	6dc7a783          	lw	a5,1756(a5) # 80020074 <sb+0x4>
    800039a0:	cbd1                	beqz	a5,80003a34 <balloc+0xb6>
    800039a2:	8baa                	mv	s7,a0
    800039a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039a6:	0001cb17          	auipc	s6,0x1c
    800039aa:	6cab0b13          	addi	s6,s6,1738 # 80020070 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039b4:	6c89                	lui	s9,0x2
    800039b6:	a831                	j	800039d2 <balloc+0x54>
    brelse(bp);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	e32080e7          	jalr	-462(ra) # 800037ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039c2:	015c87bb          	addw	a5,s9,s5
    800039c6:	00078a9b          	sext.w	s5,a5
    800039ca:	004b2703          	lw	a4,4(s6)
    800039ce:	06eaf363          	bgeu	s5,a4,80003a34 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039d2:	41fad79b          	sraiw	a5,s5,0x1f
    800039d6:	0137d79b          	srliw	a5,a5,0x13
    800039da:	015787bb          	addw	a5,a5,s5
    800039de:	40d7d79b          	sraiw	a5,a5,0xd
    800039e2:	01cb2583          	lw	a1,28(s6)
    800039e6:	9dbd                	addw	a1,a1,a5
    800039e8:	855e                	mv	a0,s7
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	cd2080e7          	jalr	-814(ra) # 800036bc <bread>
    800039f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039f4:	004b2503          	lw	a0,4(s6)
    800039f8:	000a849b          	sext.w	s1,s5
    800039fc:	8662                	mv	a2,s8
    800039fe:	faa4fde3          	bgeu	s1,a0,800039b8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a02:	41f6579b          	sraiw	a5,a2,0x1f
    80003a06:	01d7d69b          	srliw	a3,a5,0x1d
    80003a0a:	00c6873b          	addw	a4,a3,a2
    80003a0e:	00777793          	andi	a5,a4,7
    80003a12:	9f95                	subw	a5,a5,a3
    80003a14:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a18:	4037571b          	sraiw	a4,a4,0x3
    80003a1c:	00e906b3          	add	a3,s2,a4
    80003a20:	0586c683          	lbu	a3,88(a3)
    80003a24:	00d7f5b3          	and	a1,a5,a3
    80003a28:	cd91                	beqz	a1,80003a44 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a2a:	2605                	addiw	a2,a2,1
    80003a2c:	2485                	addiw	s1,s1,1
    80003a2e:	fd4618e3          	bne	a2,s4,800039fe <balloc+0x80>
    80003a32:	b759                	j	800039b8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a34:	00005517          	auipc	a0,0x5
    80003a38:	bc450513          	addi	a0,a0,-1084 # 800085f8 <syscalls+0x118>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a44:	974a                	add	a4,a4,s2
    80003a46:	8fd5                	or	a5,a5,a3
    80003a48:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00001097          	auipc	ra,0x1
    80003a52:	01a080e7          	jalr	26(ra) # 80004a68 <log_write>
        brelse(bp);
    80003a56:	854a                	mv	a0,s2
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	d94080e7          	jalr	-620(ra) # 800037ec <brelse>
  bp = bread(dev, bno);
    80003a60:	85a6                	mv	a1,s1
    80003a62:	855e                	mv	a0,s7
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	c58080e7          	jalr	-936(ra) # 800036bc <bread>
    80003a6c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a6e:	40000613          	li	a2,1024
    80003a72:	4581                	li	a1,0
    80003a74:	05850513          	addi	a0,a0,88
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	28c080e7          	jalr	652(ra) # 80000d04 <memset>
  log_write(bp);
    80003a80:	854a                	mv	a0,s2
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	fe6080e7          	jalr	-26(ra) # 80004a68 <log_write>
  brelse(bp);
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	d60080e7          	jalr	-672(ra) # 800037ec <brelse>
}
    80003a94:	8526                	mv	a0,s1
    80003a96:	60e6                	ld	ra,88(sp)
    80003a98:	6446                	ld	s0,80(sp)
    80003a9a:	64a6                	ld	s1,72(sp)
    80003a9c:	6906                	ld	s2,64(sp)
    80003a9e:	79e2                	ld	s3,56(sp)
    80003aa0:	7a42                	ld	s4,48(sp)
    80003aa2:	7aa2                	ld	s5,40(sp)
    80003aa4:	7b02                	ld	s6,32(sp)
    80003aa6:	6be2                	ld	s7,24(sp)
    80003aa8:	6c42                	ld	s8,16(sp)
    80003aaa:	6ca2                	ld	s9,8(sp)
    80003aac:	6125                	addi	sp,sp,96
    80003aae:	8082                	ret

0000000080003ab0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ab0:	7179                	addi	sp,sp,-48
    80003ab2:	f406                	sd	ra,40(sp)
    80003ab4:	f022                	sd	s0,32(sp)
    80003ab6:	ec26                	sd	s1,24(sp)
    80003ab8:	e84a                	sd	s2,16(sp)
    80003aba:	e44e                	sd	s3,8(sp)
    80003abc:	e052                	sd	s4,0(sp)
    80003abe:	1800                	addi	s0,sp,48
    80003ac0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ac2:	47ad                	li	a5,11
    80003ac4:	04b7fe63          	bgeu	a5,a1,80003b20 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ac8:	ff45849b          	addiw	s1,a1,-12
    80003acc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ad0:	0ff00793          	li	a5,255
    80003ad4:	0ae7e363          	bltu	a5,a4,80003b7a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ad8:	08052583          	lw	a1,128(a0)
    80003adc:	c5ad                	beqz	a1,80003b46 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ade:	00092503          	lw	a0,0(s2)
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	bda080e7          	jalr	-1062(ra) # 800036bc <bread>
    80003aea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003aec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003af0:	02049593          	slli	a1,s1,0x20
    80003af4:	9181                	srli	a1,a1,0x20
    80003af6:	058a                	slli	a1,a1,0x2
    80003af8:	00b784b3          	add	s1,a5,a1
    80003afc:	0004a983          	lw	s3,0(s1)
    80003b00:	04098d63          	beqz	s3,80003b5a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b04:	8552                	mv	a0,s4
    80003b06:	00000097          	auipc	ra,0x0
    80003b0a:	ce6080e7          	jalr	-794(ra) # 800037ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b0e:	854e                	mv	a0,s3
    80003b10:	70a2                	ld	ra,40(sp)
    80003b12:	7402                	ld	s0,32(sp)
    80003b14:	64e2                	ld	s1,24(sp)
    80003b16:	6942                	ld	s2,16(sp)
    80003b18:	69a2                	ld	s3,8(sp)
    80003b1a:	6a02                	ld	s4,0(sp)
    80003b1c:	6145                	addi	sp,sp,48
    80003b1e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b20:	02059493          	slli	s1,a1,0x20
    80003b24:	9081                	srli	s1,s1,0x20
    80003b26:	048a                	slli	s1,s1,0x2
    80003b28:	94aa                	add	s1,s1,a0
    80003b2a:	0504a983          	lw	s3,80(s1)
    80003b2e:	fe0990e3          	bnez	s3,80003b0e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b32:	4108                	lw	a0,0(a0)
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	e4a080e7          	jalr	-438(ra) # 8000397e <balloc>
    80003b3c:	0005099b          	sext.w	s3,a0
    80003b40:	0534a823          	sw	s3,80(s1)
    80003b44:	b7e9                	j	80003b0e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b46:	4108                	lw	a0,0(a0)
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	e36080e7          	jalr	-458(ra) # 8000397e <balloc>
    80003b50:	0005059b          	sext.w	a1,a0
    80003b54:	08b92023          	sw	a1,128(s2)
    80003b58:	b759                	j	80003ade <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b5a:	00092503          	lw	a0,0(s2)
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	e20080e7          	jalr	-480(ra) # 8000397e <balloc>
    80003b66:	0005099b          	sext.w	s3,a0
    80003b6a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b6e:	8552                	mv	a0,s4
    80003b70:	00001097          	auipc	ra,0x1
    80003b74:	ef8080e7          	jalr	-264(ra) # 80004a68 <log_write>
    80003b78:	b771                	j	80003b04 <bmap+0x54>
  panic("bmap: out of range");
    80003b7a:	00005517          	auipc	a0,0x5
    80003b7e:	a9650513          	addi	a0,a0,-1386 # 80008610 <syscalls+0x130>
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	9bc080e7          	jalr	-1604(ra) # 8000053e <panic>

0000000080003b8a <iget>:
{
    80003b8a:	7179                	addi	sp,sp,-48
    80003b8c:	f406                	sd	ra,40(sp)
    80003b8e:	f022                	sd	s0,32(sp)
    80003b90:	ec26                	sd	s1,24(sp)
    80003b92:	e84a                	sd	s2,16(sp)
    80003b94:	e44e                	sd	s3,8(sp)
    80003b96:	e052                	sd	s4,0(sp)
    80003b98:	1800                	addi	s0,sp,48
    80003b9a:	89aa                	mv	s3,a0
    80003b9c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b9e:	0001c517          	auipc	a0,0x1c
    80003ba2:	4f250513          	addi	a0,a0,1266 # 80020090 <itable>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	03e080e7          	jalr	62(ra) # 80000be4 <acquire>
  empty = 0;
    80003bae:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bb0:	0001c497          	auipc	s1,0x1c
    80003bb4:	4f848493          	addi	s1,s1,1272 # 800200a8 <itable+0x18>
    80003bb8:	0001e697          	auipc	a3,0x1e
    80003bbc:	f8068693          	addi	a3,a3,-128 # 80021b38 <log>
    80003bc0:	a039                	j	80003bce <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bc2:	02090b63          	beqz	s2,80003bf8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bc6:	08848493          	addi	s1,s1,136
    80003bca:	02d48a63          	beq	s1,a3,80003bfe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bce:	449c                	lw	a5,8(s1)
    80003bd0:	fef059e3          	blez	a5,80003bc2 <iget+0x38>
    80003bd4:	4098                	lw	a4,0(s1)
    80003bd6:	ff3716e3          	bne	a4,s3,80003bc2 <iget+0x38>
    80003bda:	40d8                	lw	a4,4(s1)
    80003bdc:	ff4713e3          	bne	a4,s4,80003bc2 <iget+0x38>
      ip->ref++;
    80003be0:	2785                	addiw	a5,a5,1
    80003be2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003be4:	0001c517          	auipc	a0,0x1c
    80003be8:	4ac50513          	addi	a0,a0,1196 # 80020090 <itable>
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	0be080e7          	jalr	190(ra) # 80000caa <release>
      return ip;
    80003bf4:	8926                	mv	s2,s1
    80003bf6:	a03d                	j	80003c24 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bf8:	f7f9                	bnez	a5,80003bc6 <iget+0x3c>
    80003bfa:	8926                	mv	s2,s1
    80003bfc:	b7e9                	j	80003bc6 <iget+0x3c>
  if(empty == 0)
    80003bfe:	02090c63          	beqz	s2,80003c36 <iget+0xac>
  ip->dev = dev;
    80003c02:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c06:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c0a:	4785                	li	a5,1
    80003c0c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c10:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c14:	0001c517          	auipc	a0,0x1c
    80003c18:	47c50513          	addi	a0,a0,1148 # 80020090 <itable>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	08e080e7          	jalr	142(ra) # 80000caa <release>
}
    80003c24:	854a                	mv	a0,s2
    80003c26:	70a2                	ld	ra,40(sp)
    80003c28:	7402                	ld	s0,32(sp)
    80003c2a:	64e2                	ld	s1,24(sp)
    80003c2c:	6942                	ld	s2,16(sp)
    80003c2e:	69a2                	ld	s3,8(sp)
    80003c30:	6a02                	ld	s4,0(sp)
    80003c32:	6145                	addi	sp,sp,48
    80003c34:	8082                	ret
    panic("iget: no inodes");
    80003c36:	00005517          	auipc	a0,0x5
    80003c3a:	9f250513          	addi	a0,a0,-1550 # 80008628 <syscalls+0x148>
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	900080e7          	jalr	-1792(ra) # 8000053e <panic>

0000000080003c46 <fsinit>:
fsinit(int dev) {
    80003c46:	7179                	addi	sp,sp,-48
    80003c48:	f406                	sd	ra,40(sp)
    80003c4a:	f022                	sd	s0,32(sp)
    80003c4c:	ec26                	sd	s1,24(sp)
    80003c4e:	e84a                	sd	s2,16(sp)
    80003c50:	e44e                	sd	s3,8(sp)
    80003c52:	1800                	addi	s0,sp,48
    80003c54:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c56:	4585                	li	a1,1
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	a64080e7          	jalr	-1436(ra) # 800036bc <bread>
    80003c60:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c62:	0001c997          	auipc	s3,0x1c
    80003c66:	40e98993          	addi	s3,s3,1038 # 80020070 <sb>
    80003c6a:	02000613          	li	a2,32
    80003c6e:	05850593          	addi	a1,a0,88
    80003c72:	854e                	mv	a0,s3
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	0f0080e7          	jalr	240(ra) # 80000d64 <memmove>
  brelse(bp);
    80003c7c:	8526                	mv	a0,s1
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	b6e080e7          	jalr	-1170(ra) # 800037ec <brelse>
  if(sb.magic != FSMAGIC)
    80003c86:	0009a703          	lw	a4,0(s3)
    80003c8a:	102037b7          	lui	a5,0x10203
    80003c8e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c92:	02f71263          	bne	a4,a5,80003cb6 <fsinit+0x70>
  initlog(dev, &sb);
    80003c96:	0001c597          	auipc	a1,0x1c
    80003c9a:	3da58593          	addi	a1,a1,986 # 80020070 <sb>
    80003c9e:	854a                	mv	a0,s2
    80003ca0:	00001097          	auipc	ra,0x1
    80003ca4:	b4c080e7          	jalr	-1204(ra) # 800047ec <initlog>
}
    80003ca8:	70a2                	ld	ra,40(sp)
    80003caa:	7402                	ld	s0,32(sp)
    80003cac:	64e2                	ld	s1,24(sp)
    80003cae:	6942                	ld	s2,16(sp)
    80003cb0:	69a2                	ld	s3,8(sp)
    80003cb2:	6145                	addi	sp,sp,48
    80003cb4:	8082                	ret
    panic("invalid file system");
    80003cb6:	00005517          	auipc	a0,0x5
    80003cba:	98250513          	addi	a0,a0,-1662 # 80008638 <syscalls+0x158>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>

0000000080003cc6 <iinit>:
{
    80003cc6:	7179                	addi	sp,sp,-48
    80003cc8:	f406                	sd	ra,40(sp)
    80003cca:	f022                	sd	s0,32(sp)
    80003ccc:	ec26                	sd	s1,24(sp)
    80003cce:	e84a                	sd	s2,16(sp)
    80003cd0:	e44e                	sd	s3,8(sp)
    80003cd2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cd4:	00005597          	auipc	a1,0x5
    80003cd8:	97c58593          	addi	a1,a1,-1668 # 80008650 <syscalls+0x170>
    80003cdc:	0001c517          	auipc	a0,0x1c
    80003ce0:	3b450513          	addi	a0,a0,948 # 80020090 <itable>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	e70080e7          	jalr	-400(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003cec:	0001c497          	auipc	s1,0x1c
    80003cf0:	3cc48493          	addi	s1,s1,972 # 800200b8 <itable+0x28>
    80003cf4:	0001e997          	auipc	s3,0x1e
    80003cf8:	e5498993          	addi	s3,s3,-428 # 80021b48 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003cfc:	00005917          	auipc	s2,0x5
    80003d00:	95c90913          	addi	s2,s2,-1700 # 80008658 <syscalls+0x178>
    80003d04:	85ca                	mv	a1,s2
    80003d06:	8526                	mv	a0,s1
    80003d08:	00001097          	auipc	ra,0x1
    80003d0c:	e46080e7          	jalr	-442(ra) # 80004b4e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d10:	08848493          	addi	s1,s1,136
    80003d14:	ff3498e3          	bne	s1,s3,80003d04 <iinit+0x3e>
}
    80003d18:	70a2                	ld	ra,40(sp)
    80003d1a:	7402                	ld	s0,32(sp)
    80003d1c:	64e2                	ld	s1,24(sp)
    80003d1e:	6942                	ld	s2,16(sp)
    80003d20:	69a2                	ld	s3,8(sp)
    80003d22:	6145                	addi	sp,sp,48
    80003d24:	8082                	ret

0000000080003d26 <ialloc>:
{
    80003d26:	715d                	addi	sp,sp,-80
    80003d28:	e486                	sd	ra,72(sp)
    80003d2a:	e0a2                	sd	s0,64(sp)
    80003d2c:	fc26                	sd	s1,56(sp)
    80003d2e:	f84a                	sd	s2,48(sp)
    80003d30:	f44e                	sd	s3,40(sp)
    80003d32:	f052                	sd	s4,32(sp)
    80003d34:	ec56                	sd	s5,24(sp)
    80003d36:	e85a                	sd	s6,16(sp)
    80003d38:	e45e                	sd	s7,8(sp)
    80003d3a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d3c:	0001c717          	auipc	a4,0x1c
    80003d40:	34072703          	lw	a4,832(a4) # 8002007c <sb+0xc>
    80003d44:	4785                	li	a5,1
    80003d46:	04e7fa63          	bgeu	a5,a4,80003d9a <ialloc+0x74>
    80003d4a:	8aaa                	mv	s5,a0
    80003d4c:	8bae                	mv	s7,a1
    80003d4e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d50:	0001ca17          	auipc	s4,0x1c
    80003d54:	320a0a13          	addi	s4,s4,800 # 80020070 <sb>
    80003d58:	00048b1b          	sext.w	s6,s1
    80003d5c:	0044d593          	srli	a1,s1,0x4
    80003d60:	018a2783          	lw	a5,24(s4)
    80003d64:	9dbd                	addw	a1,a1,a5
    80003d66:	8556                	mv	a0,s5
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	954080e7          	jalr	-1708(ra) # 800036bc <bread>
    80003d70:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d72:	05850993          	addi	s3,a0,88
    80003d76:	00f4f793          	andi	a5,s1,15
    80003d7a:	079a                	slli	a5,a5,0x6
    80003d7c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d7e:	00099783          	lh	a5,0(s3)
    80003d82:	c785                	beqz	a5,80003daa <ialloc+0x84>
    brelse(bp);
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	a68080e7          	jalr	-1432(ra) # 800037ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d8c:	0485                	addi	s1,s1,1
    80003d8e:	00ca2703          	lw	a4,12(s4)
    80003d92:	0004879b          	sext.w	a5,s1
    80003d96:	fce7e1e3          	bltu	a5,a4,80003d58 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d9a:	00005517          	auipc	a0,0x5
    80003d9e:	8c650513          	addi	a0,a0,-1850 # 80008660 <syscalls+0x180>
    80003da2:	ffffc097          	auipc	ra,0xffffc
    80003da6:	79c080e7          	jalr	1948(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003daa:	04000613          	li	a2,64
    80003dae:	4581                	li	a1,0
    80003db0:	854e                	mv	a0,s3
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	f52080e7          	jalr	-174(ra) # 80000d04 <memset>
      dip->type = type;
    80003dba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00001097          	auipc	ra,0x1
    80003dc4:	ca8080e7          	jalr	-856(ra) # 80004a68 <log_write>
      brelse(bp);
    80003dc8:	854a                	mv	a0,s2
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	a22080e7          	jalr	-1502(ra) # 800037ec <brelse>
      return iget(dev, inum);
    80003dd2:	85da                	mv	a1,s6
    80003dd4:	8556                	mv	a0,s5
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	db4080e7          	jalr	-588(ra) # 80003b8a <iget>
}
    80003dde:	60a6                	ld	ra,72(sp)
    80003de0:	6406                	ld	s0,64(sp)
    80003de2:	74e2                	ld	s1,56(sp)
    80003de4:	7942                	ld	s2,48(sp)
    80003de6:	79a2                	ld	s3,40(sp)
    80003de8:	7a02                	ld	s4,32(sp)
    80003dea:	6ae2                	ld	s5,24(sp)
    80003dec:	6b42                	ld	s6,16(sp)
    80003dee:	6ba2                	ld	s7,8(sp)
    80003df0:	6161                	addi	sp,sp,80
    80003df2:	8082                	ret

0000000080003df4 <iupdate>:
{
    80003df4:	1101                	addi	sp,sp,-32
    80003df6:	ec06                	sd	ra,24(sp)
    80003df8:	e822                	sd	s0,16(sp)
    80003dfa:	e426                	sd	s1,8(sp)
    80003dfc:	e04a                	sd	s2,0(sp)
    80003dfe:	1000                	addi	s0,sp,32
    80003e00:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e02:	415c                	lw	a5,4(a0)
    80003e04:	0047d79b          	srliw	a5,a5,0x4
    80003e08:	0001c597          	auipc	a1,0x1c
    80003e0c:	2805a583          	lw	a1,640(a1) # 80020088 <sb+0x18>
    80003e10:	9dbd                	addw	a1,a1,a5
    80003e12:	4108                	lw	a0,0(a0)
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	8a8080e7          	jalr	-1880(ra) # 800036bc <bread>
    80003e1c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e1e:	05850793          	addi	a5,a0,88
    80003e22:	40c8                	lw	a0,4(s1)
    80003e24:	893d                	andi	a0,a0,15
    80003e26:	051a                	slli	a0,a0,0x6
    80003e28:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e2a:	04449703          	lh	a4,68(s1)
    80003e2e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e32:	04649703          	lh	a4,70(s1)
    80003e36:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e3a:	04849703          	lh	a4,72(s1)
    80003e3e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e42:	04a49703          	lh	a4,74(s1)
    80003e46:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e4a:	44f8                	lw	a4,76(s1)
    80003e4c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e4e:	03400613          	li	a2,52
    80003e52:	05048593          	addi	a1,s1,80
    80003e56:	0531                	addi	a0,a0,12
    80003e58:	ffffd097          	auipc	ra,0xffffd
    80003e5c:	f0c080e7          	jalr	-244(ra) # 80000d64 <memmove>
  log_write(bp);
    80003e60:	854a                	mv	a0,s2
    80003e62:	00001097          	auipc	ra,0x1
    80003e66:	c06080e7          	jalr	-1018(ra) # 80004a68 <log_write>
  brelse(bp);
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	980080e7          	jalr	-1664(ra) # 800037ec <brelse>
}
    80003e74:	60e2                	ld	ra,24(sp)
    80003e76:	6442                	ld	s0,16(sp)
    80003e78:	64a2                	ld	s1,8(sp)
    80003e7a:	6902                	ld	s2,0(sp)
    80003e7c:	6105                	addi	sp,sp,32
    80003e7e:	8082                	ret

0000000080003e80 <idup>:
{
    80003e80:	1101                	addi	sp,sp,-32
    80003e82:	ec06                	sd	ra,24(sp)
    80003e84:	e822                	sd	s0,16(sp)
    80003e86:	e426                	sd	s1,8(sp)
    80003e88:	1000                	addi	s0,sp,32
    80003e8a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e8c:	0001c517          	auipc	a0,0x1c
    80003e90:	20450513          	addi	a0,a0,516 # 80020090 <itable>
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	d50080e7          	jalr	-688(ra) # 80000be4 <acquire>
  ip->ref++;
    80003e9c:	449c                	lw	a5,8(s1)
    80003e9e:	2785                	addiw	a5,a5,1
    80003ea0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ea2:	0001c517          	auipc	a0,0x1c
    80003ea6:	1ee50513          	addi	a0,a0,494 # 80020090 <itable>
    80003eaa:	ffffd097          	auipc	ra,0xffffd
    80003eae:	e00080e7          	jalr	-512(ra) # 80000caa <release>
}
    80003eb2:	8526                	mv	a0,s1
    80003eb4:	60e2                	ld	ra,24(sp)
    80003eb6:	6442                	ld	s0,16(sp)
    80003eb8:	64a2                	ld	s1,8(sp)
    80003eba:	6105                	addi	sp,sp,32
    80003ebc:	8082                	ret

0000000080003ebe <ilock>:
{
    80003ebe:	1101                	addi	sp,sp,-32
    80003ec0:	ec06                	sd	ra,24(sp)
    80003ec2:	e822                	sd	s0,16(sp)
    80003ec4:	e426                	sd	s1,8(sp)
    80003ec6:	e04a                	sd	s2,0(sp)
    80003ec8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003eca:	c115                	beqz	a0,80003eee <ilock+0x30>
    80003ecc:	84aa                	mv	s1,a0
    80003ece:	451c                	lw	a5,8(a0)
    80003ed0:	00f05f63          	blez	a5,80003eee <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ed4:	0541                	addi	a0,a0,16
    80003ed6:	00001097          	auipc	ra,0x1
    80003eda:	cb2080e7          	jalr	-846(ra) # 80004b88 <acquiresleep>
  if(ip->valid == 0){
    80003ede:	40bc                	lw	a5,64(s1)
    80003ee0:	cf99                	beqz	a5,80003efe <ilock+0x40>
}
    80003ee2:	60e2                	ld	ra,24(sp)
    80003ee4:	6442                	ld	s0,16(sp)
    80003ee6:	64a2                	ld	s1,8(sp)
    80003ee8:	6902                	ld	s2,0(sp)
    80003eea:	6105                	addi	sp,sp,32
    80003eec:	8082                	ret
    panic("ilock");
    80003eee:	00004517          	auipc	a0,0x4
    80003ef2:	78a50513          	addi	a0,a0,1930 # 80008678 <syscalls+0x198>
    80003ef6:	ffffc097          	auipc	ra,0xffffc
    80003efa:	648080e7          	jalr	1608(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003efe:	40dc                	lw	a5,4(s1)
    80003f00:	0047d79b          	srliw	a5,a5,0x4
    80003f04:	0001c597          	auipc	a1,0x1c
    80003f08:	1845a583          	lw	a1,388(a1) # 80020088 <sb+0x18>
    80003f0c:	9dbd                	addw	a1,a1,a5
    80003f0e:	4088                	lw	a0,0(s1)
    80003f10:	fffff097          	auipc	ra,0xfffff
    80003f14:	7ac080e7          	jalr	1964(ra) # 800036bc <bread>
    80003f18:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f1a:	05850593          	addi	a1,a0,88
    80003f1e:	40dc                	lw	a5,4(s1)
    80003f20:	8bbd                	andi	a5,a5,15
    80003f22:	079a                	slli	a5,a5,0x6
    80003f24:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f26:	00059783          	lh	a5,0(a1)
    80003f2a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f2e:	00259783          	lh	a5,2(a1)
    80003f32:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f36:	00459783          	lh	a5,4(a1)
    80003f3a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f3e:	00659783          	lh	a5,6(a1)
    80003f42:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f46:	459c                	lw	a5,8(a1)
    80003f48:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f4a:	03400613          	li	a2,52
    80003f4e:	05b1                	addi	a1,a1,12
    80003f50:	05048513          	addi	a0,s1,80
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	e10080e7          	jalr	-496(ra) # 80000d64 <memmove>
    brelse(bp);
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	88e080e7          	jalr	-1906(ra) # 800037ec <brelse>
    ip->valid = 1;
    80003f66:	4785                	li	a5,1
    80003f68:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f6a:	04449783          	lh	a5,68(s1)
    80003f6e:	fbb5                	bnez	a5,80003ee2 <ilock+0x24>
      panic("ilock: no type");
    80003f70:	00004517          	auipc	a0,0x4
    80003f74:	71050513          	addi	a0,a0,1808 # 80008680 <syscalls+0x1a0>
    80003f78:	ffffc097          	auipc	ra,0xffffc
    80003f7c:	5c6080e7          	jalr	1478(ra) # 8000053e <panic>

0000000080003f80 <iunlock>:
{
    80003f80:	1101                	addi	sp,sp,-32
    80003f82:	ec06                	sd	ra,24(sp)
    80003f84:	e822                	sd	s0,16(sp)
    80003f86:	e426                	sd	s1,8(sp)
    80003f88:	e04a                	sd	s2,0(sp)
    80003f8a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f8c:	c905                	beqz	a0,80003fbc <iunlock+0x3c>
    80003f8e:	84aa                	mv	s1,a0
    80003f90:	01050913          	addi	s2,a0,16
    80003f94:	854a                	mv	a0,s2
    80003f96:	00001097          	auipc	ra,0x1
    80003f9a:	c8c080e7          	jalr	-884(ra) # 80004c22 <holdingsleep>
    80003f9e:	cd19                	beqz	a0,80003fbc <iunlock+0x3c>
    80003fa0:	449c                	lw	a5,8(s1)
    80003fa2:	00f05d63          	blez	a5,80003fbc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fa6:	854a                	mv	a0,s2
    80003fa8:	00001097          	auipc	ra,0x1
    80003fac:	c36080e7          	jalr	-970(ra) # 80004bde <releasesleep>
}
    80003fb0:	60e2                	ld	ra,24(sp)
    80003fb2:	6442                	ld	s0,16(sp)
    80003fb4:	64a2                	ld	s1,8(sp)
    80003fb6:	6902                	ld	s2,0(sp)
    80003fb8:	6105                	addi	sp,sp,32
    80003fba:	8082                	ret
    panic("iunlock");
    80003fbc:	00004517          	auipc	a0,0x4
    80003fc0:	6d450513          	addi	a0,a0,1748 # 80008690 <syscalls+0x1b0>
    80003fc4:	ffffc097          	auipc	ra,0xffffc
    80003fc8:	57a080e7          	jalr	1402(ra) # 8000053e <panic>

0000000080003fcc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fcc:	7179                	addi	sp,sp,-48
    80003fce:	f406                	sd	ra,40(sp)
    80003fd0:	f022                	sd	s0,32(sp)
    80003fd2:	ec26                	sd	s1,24(sp)
    80003fd4:	e84a                	sd	s2,16(sp)
    80003fd6:	e44e                	sd	s3,8(sp)
    80003fd8:	e052                	sd	s4,0(sp)
    80003fda:	1800                	addi	s0,sp,48
    80003fdc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fde:	05050493          	addi	s1,a0,80
    80003fe2:	08050913          	addi	s2,a0,128
    80003fe6:	a021                	j	80003fee <itrunc+0x22>
    80003fe8:	0491                	addi	s1,s1,4
    80003fea:	01248d63          	beq	s1,s2,80004004 <itrunc+0x38>
    if(ip->addrs[i]){
    80003fee:	408c                	lw	a1,0(s1)
    80003ff0:	dde5                	beqz	a1,80003fe8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ff2:	0009a503          	lw	a0,0(s3)
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	90c080e7          	jalr	-1780(ra) # 80003902 <bfree>
      ip->addrs[i] = 0;
    80003ffe:	0004a023          	sw	zero,0(s1)
    80004002:	b7dd                	j	80003fe8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004004:	0809a583          	lw	a1,128(s3)
    80004008:	e185                	bnez	a1,80004028 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000400a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000400e:	854e                	mv	a0,s3
    80004010:	00000097          	auipc	ra,0x0
    80004014:	de4080e7          	jalr	-540(ra) # 80003df4 <iupdate>
}
    80004018:	70a2                	ld	ra,40(sp)
    8000401a:	7402                	ld	s0,32(sp)
    8000401c:	64e2                	ld	s1,24(sp)
    8000401e:	6942                	ld	s2,16(sp)
    80004020:	69a2                	ld	s3,8(sp)
    80004022:	6a02                	ld	s4,0(sp)
    80004024:	6145                	addi	sp,sp,48
    80004026:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004028:	0009a503          	lw	a0,0(s3)
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	690080e7          	jalr	1680(ra) # 800036bc <bread>
    80004034:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004036:	05850493          	addi	s1,a0,88
    8000403a:	45850913          	addi	s2,a0,1112
    8000403e:	a811                	j	80004052 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004040:	0009a503          	lw	a0,0(s3)
    80004044:	00000097          	auipc	ra,0x0
    80004048:	8be080e7          	jalr	-1858(ra) # 80003902 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000404c:	0491                	addi	s1,s1,4
    8000404e:	01248563          	beq	s1,s2,80004058 <itrunc+0x8c>
      if(a[j])
    80004052:	408c                	lw	a1,0(s1)
    80004054:	dde5                	beqz	a1,8000404c <itrunc+0x80>
    80004056:	b7ed                	j	80004040 <itrunc+0x74>
    brelse(bp);
    80004058:	8552                	mv	a0,s4
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	792080e7          	jalr	1938(ra) # 800037ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004062:	0809a583          	lw	a1,128(s3)
    80004066:	0009a503          	lw	a0,0(s3)
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	898080e7          	jalr	-1896(ra) # 80003902 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004072:	0809a023          	sw	zero,128(s3)
    80004076:	bf51                	j	8000400a <itrunc+0x3e>

0000000080004078 <iput>:
{
    80004078:	1101                	addi	sp,sp,-32
    8000407a:	ec06                	sd	ra,24(sp)
    8000407c:	e822                	sd	s0,16(sp)
    8000407e:	e426                	sd	s1,8(sp)
    80004080:	e04a                	sd	s2,0(sp)
    80004082:	1000                	addi	s0,sp,32
    80004084:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004086:	0001c517          	auipc	a0,0x1c
    8000408a:	00a50513          	addi	a0,a0,10 # 80020090 <itable>
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	b56080e7          	jalr	-1194(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004096:	4498                	lw	a4,8(s1)
    80004098:	4785                	li	a5,1
    8000409a:	02f70363          	beq	a4,a5,800040c0 <iput+0x48>
  ip->ref--;
    8000409e:	449c                	lw	a5,8(s1)
    800040a0:	37fd                	addiw	a5,a5,-1
    800040a2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040a4:	0001c517          	auipc	a0,0x1c
    800040a8:	fec50513          	addi	a0,a0,-20 # 80020090 <itable>
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	bfe080e7          	jalr	-1026(ra) # 80000caa <release>
}
    800040b4:	60e2                	ld	ra,24(sp)
    800040b6:	6442                	ld	s0,16(sp)
    800040b8:	64a2                	ld	s1,8(sp)
    800040ba:	6902                	ld	s2,0(sp)
    800040bc:	6105                	addi	sp,sp,32
    800040be:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040c0:	40bc                	lw	a5,64(s1)
    800040c2:	dff1                	beqz	a5,8000409e <iput+0x26>
    800040c4:	04a49783          	lh	a5,74(s1)
    800040c8:	fbf9                	bnez	a5,8000409e <iput+0x26>
    acquiresleep(&ip->lock);
    800040ca:	01048913          	addi	s2,s1,16
    800040ce:	854a                	mv	a0,s2
    800040d0:	00001097          	auipc	ra,0x1
    800040d4:	ab8080e7          	jalr	-1352(ra) # 80004b88 <acquiresleep>
    release(&itable.lock);
    800040d8:	0001c517          	auipc	a0,0x1c
    800040dc:	fb850513          	addi	a0,a0,-72 # 80020090 <itable>
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	bca080e7          	jalr	-1078(ra) # 80000caa <release>
    itrunc(ip);
    800040e8:	8526                	mv	a0,s1
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	ee2080e7          	jalr	-286(ra) # 80003fcc <itrunc>
    ip->type = 0;
    800040f2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040f6:	8526                	mv	a0,s1
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	cfc080e7          	jalr	-772(ra) # 80003df4 <iupdate>
    ip->valid = 0;
    80004100:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004104:	854a                	mv	a0,s2
    80004106:	00001097          	auipc	ra,0x1
    8000410a:	ad8080e7          	jalr	-1320(ra) # 80004bde <releasesleep>
    acquire(&itable.lock);
    8000410e:	0001c517          	auipc	a0,0x1c
    80004112:	f8250513          	addi	a0,a0,-126 # 80020090 <itable>
    80004116:	ffffd097          	auipc	ra,0xffffd
    8000411a:	ace080e7          	jalr	-1330(ra) # 80000be4 <acquire>
    8000411e:	b741                	j	8000409e <iput+0x26>

0000000080004120 <iunlockput>:
{
    80004120:	1101                	addi	sp,sp,-32
    80004122:	ec06                	sd	ra,24(sp)
    80004124:	e822                	sd	s0,16(sp)
    80004126:	e426                	sd	s1,8(sp)
    80004128:	1000                	addi	s0,sp,32
    8000412a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	e54080e7          	jalr	-428(ra) # 80003f80 <iunlock>
  iput(ip);
    80004134:	8526                	mv	a0,s1
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	f42080e7          	jalr	-190(ra) # 80004078 <iput>
}
    8000413e:	60e2                	ld	ra,24(sp)
    80004140:	6442                	ld	s0,16(sp)
    80004142:	64a2                	ld	s1,8(sp)
    80004144:	6105                	addi	sp,sp,32
    80004146:	8082                	ret

0000000080004148 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004148:	1141                	addi	sp,sp,-16
    8000414a:	e422                	sd	s0,8(sp)
    8000414c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000414e:	411c                	lw	a5,0(a0)
    80004150:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004152:	415c                	lw	a5,4(a0)
    80004154:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004156:	04451783          	lh	a5,68(a0)
    8000415a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000415e:	04a51783          	lh	a5,74(a0)
    80004162:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004166:	04c56783          	lwu	a5,76(a0)
    8000416a:	e99c                	sd	a5,16(a1)
}
    8000416c:	6422                	ld	s0,8(sp)
    8000416e:	0141                	addi	sp,sp,16
    80004170:	8082                	ret

0000000080004172 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004172:	457c                	lw	a5,76(a0)
    80004174:	0ed7e963          	bltu	a5,a3,80004266 <readi+0xf4>
{
    80004178:	7159                	addi	sp,sp,-112
    8000417a:	f486                	sd	ra,104(sp)
    8000417c:	f0a2                	sd	s0,96(sp)
    8000417e:	eca6                	sd	s1,88(sp)
    80004180:	e8ca                	sd	s2,80(sp)
    80004182:	e4ce                	sd	s3,72(sp)
    80004184:	e0d2                	sd	s4,64(sp)
    80004186:	fc56                	sd	s5,56(sp)
    80004188:	f85a                	sd	s6,48(sp)
    8000418a:	f45e                	sd	s7,40(sp)
    8000418c:	f062                	sd	s8,32(sp)
    8000418e:	ec66                	sd	s9,24(sp)
    80004190:	e86a                	sd	s10,16(sp)
    80004192:	e46e                	sd	s11,8(sp)
    80004194:	1880                	addi	s0,sp,112
    80004196:	8baa                	mv	s7,a0
    80004198:	8c2e                	mv	s8,a1
    8000419a:	8ab2                	mv	s5,a2
    8000419c:	84b6                	mv	s1,a3
    8000419e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041a0:	9f35                	addw	a4,a4,a3
    return 0;
    800041a2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041a4:	0ad76063          	bltu	a4,a3,80004244 <readi+0xd2>
  if(off + n > ip->size)
    800041a8:	00e7f463          	bgeu	a5,a4,800041b0 <readi+0x3e>
    n = ip->size - off;
    800041ac:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041b0:	0a0b0963          	beqz	s6,80004262 <readi+0xf0>
    800041b4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041b6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041ba:	5cfd                	li	s9,-1
    800041bc:	a82d                	j	800041f6 <readi+0x84>
    800041be:	020a1d93          	slli	s11,s4,0x20
    800041c2:	020ddd93          	srli	s11,s11,0x20
    800041c6:	05890613          	addi	a2,s2,88
    800041ca:	86ee                	mv	a3,s11
    800041cc:	963a                	add	a2,a2,a4
    800041ce:	85d6                	mv	a1,s5
    800041d0:	8562                	mv	a0,s8
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	a1e080e7          	jalr	-1506(ra) # 80002bf0 <either_copyout>
    800041da:	05950d63          	beq	a0,s9,80004234 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041de:	854a                	mv	a0,s2
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	60c080e7          	jalr	1548(ra) # 800037ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041e8:	013a09bb          	addw	s3,s4,s3
    800041ec:	009a04bb          	addw	s1,s4,s1
    800041f0:	9aee                	add	s5,s5,s11
    800041f2:	0569f763          	bgeu	s3,s6,80004240 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041f6:	000ba903          	lw	s2,0(s7)
    800041fa:	00a4d59b          	srliw	a1,s1,0xa
    800041fe:	855e                	mv	a0,s7
    80004200:	00000097          	auipc	ra,0x0
    80004204:	8b0080e7          	jalr	-1872(ra) # 80003ab0 <bmap>
    80004208:	0005059b          	sext.w	a1,a0
    8000420c:	854a                	mv	a0,s2
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	4ae080e7          	jalr	1198(ra) # 800036bc <bread>
    80004216:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004218:	3ff4f713          	andi	a4,s1,1023
    8000421c:	40ed07bb          	subw	a5,s10,a4
    80004220:	413b06bb          	subw	a3,s6,s3
    80004224:	8a3e                	mv	s4,a5
    80004226:	2781                	sext.w	a5,a5
    80004228:	0006861b          	sext.w	a2,a3
    8000422c:	f8f679e3          	bgeu	a2,a5,800041be <readi+0x4c>
    80004230:	8a36                	mv	s4,a3
    80004232:	b771                	j	800041be <readi+0x4c>
      brelse(bp);
    80004234:	854a                	mv	a0,s2
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	5b6080e7          	jalr	1462(ra) # 800037ec <brelse>
      tot = -1;
    8000423e:	59fd                	li	s3,-1
  }
  return tot;
    80004240:	0009851b          	sext.w	a0,s3
}
    80004244:	70a6                	ld	ra,104(sp)
    80004246:	7406                	ld	s0,96(sp)
    80004248:	64e6                	ld	s1,88(sp)
    8000424a:	6946                	ld	s2,80(sp)
    8000424c:	69a6                	ld	s3,72(sp)
    8000424e:	6a06                	ld	s4,64(sp)
    80004250:	7ae2                	ld	s5,56(sp)
    80004252:	7b42                	ld	s6,48(sp)
    80004254:	7ba2                	ld	s7,40(sp)
    80004256:	7c02                	ld	s8,32(sp)
    80004258:	6ce2                	ld	s9,24(sp)
    8000425a:	6d42                	ld	s10,16(sp)
    8000425c:	6da2                	ld	s11,8(sp)
    8000425e:	6165                	addi	sp,sp,112
    80004260:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004262:	89da                	mv	s3,s6
    80004264:	bff1                	j	80004240 <readi+0xce>
    return 0;
    80004266:	4501                	li	a0,0
}
    80004268:	8082                	ret

000000008000426a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000426a:	457c                	lw	a5,76(a0)
    8000426c:	10d7e863          	bltu	a5,a3,8000437c <writei+0x112>
{
    80004270:	7159                	addi	sp,sp,-112
    80004272:	f486                	sd	ra,104(sp)
    80004274:	f0a2                	sd	s0,96(sp)
    80004276:	eca6                	sd	s1,88(sp)
    80004278:	e8ca                	sd	s2,80(sp)
    8000427a:	e4ce                	sd	s3,72(sp)
    8000427c:	e0d2                	sd	s4,64(sp)
    8000427e:	fc56                	sd	s5,56(sp)
    80004280:	f85a                	sd	s6,48(sp)
    80004282:	f45e                	sd	s7,40(sp)
    80004284:	f062                	sd	s8,32(sp)
    80004286:	ec66                	sd	s9,24(sp)
    80004288:	e86a                	sd	s10,16(sp)
    8000428a:	e46e                	sd	s11,8(sp)
    8000428c:	1880                	addi	s0,sp,112
    8000428e:	8b2a                	mv	s6,a0
    80004290:	8c2e                	mv	s8,a1
    80004292:	8ab2                	mv	s5,a2
    80004294:	8936                	mv	s2,a3
    80004296:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004298:	00e687bb          	addw	a5,a3,a4
    8000429c:	0ed7e263          	bltu	a5,a3,80004380 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042a0:	00043737          	lui	a4,0x43
    800042a4:	0ef76063          	bltu	a4,a5,80004384 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042a8:	0c0b8863          	beqz	s7,80004378 <writei+0x10e>
    800042ac:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042ae:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042b2:	5cfd                	li	s9,-1
    800042b4:	a091                	j	800042f8 <writei+0x8e>
    800042b6:	02099d93          	slli	s11,s3,0x20
    800042ba:	020ddd93          	srli	s11,s11,0x20
    800042be:	05848513          	addi	a0,s1,88
    800042c2:	86ee                	mv	a3,s11
    800042c4:	8656                	mv	a2,s5
    800042c6:	85e2                	mv	a1,s8
    800042c8:	953a                	add	a0,a0,a4
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	97c080e7          	jalr	-1668(ra) # 80002c46 <either_copyin>
    800042d2:	07950263          	beq	a0,s9,80004336 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042d6:	8526                	mv	a0,s1
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	790080e7          	jalr	1936(ra) # 80004a68 <log_write>
    brelse(bp);
    800042e0:	8526                	mv	a0,s1
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	50a080e7          	jalr	1290(ra) # 800037ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042ea:	01498a3b          	addw	s4,s3,s4
    800042ee:	0129893b          	addw	s2,s3,s2
    800042f2:	9aee                	add	s5,s5,s11
    800042f4:	057a7663          	bgeu	s4,s7,80004340 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042f8:	000b2483          	lw	s1,0(s6)
    800042fc:	00a9559b          	srliw	a1,s2,0xa
    80004300:	855a                	mv	a0,s6
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	7ae080e7          	jalr	1966(ra) # 80003ab0 <bmap>
    8000430a:	0005059b          	sext.w	a1,a0
    8000430e:	8526                	mv	a0,s1
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	3ac080e7          	jalr	940(ra) # 800036bc <bread>
    80004318:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000431a:	3ff97713          	andi	a4,s2,1023
    8000431e:	40ed07bb          	subw	a5,s10,a4
    80004322:	414b86bb          	subw	a3,s7,s4
    80004326:	89be                	mv	s3,a5
    80004328:	2781                	sext.w	a5,a5
    8000432a:	0006861b          	sext.w	a2,a3
    8000432e:	f8f674e3          	bgeu	a2,a5,800042b6 <writei+0x4c>
    80004332:	89b6                	mv	s3,a3
    80004334:	b749                	j	800042b6 <writei+0x4c>
      brelse(bp);
    80004336:	8526                	mv	a0,s1
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	4b4080e7          	jalr	1204(ra) # 800037ec <brelse>
  }

  if(off > ip->size)
    80004340:	04cb2783          	lw	a5,76(s6)
    80004344:	0127f463          	bgeu	a5,s2,8000434c <writei+0xe2>
    ip->size = off;
    80004348:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000434c:	855a                	mv	a0,s6
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	aa6080e7          	jalr	-1370(ra) # 80003df4 <iupdate>

  return tot;
    80004356:	000a051b          	sext.w	a0,s4
}
    8000435a:	70a6                	ld	ra,104(sp)
    8000435c:	7406                	ld	s0,96(sp)
    8000435e:	64e6                	ld	s1,88(sp)
    80004360:	6946                	ld	s2,80(sp)
    80004362:	69a6                	ld	s3,72(sp)
    80004364:	6a06                	ld	s4,64(sp)
    80004366:	7ae2                	ld	s5,56(sp)
    80004368:	7b42                	ld	s6,48(sp)
    8000436a:	7ba2                	ld	s7,40(sp)
    8000436c:	7c02                	ld	s8,32(sp)
    8000436e:	6ce2                	ld	s9,24(sp)
    80004370:	6d42                	ld	s10,16(sp)
    80004372:	6da2                	ld	s11,8(sp)
    80004374:	6165                	addi	sp,sp,112
    80004376:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004378:	8a5e                	mv	s4,s7
    8000437a:	bfc9                	j	8000434c <writei+0xe2>
    return -1;
    8000437c:	557d                	li	a0,-1
}
    8000437e:	8082                	ret
    return -1;
    80004380:	557d                	li	a0,-1
    80004382:	bfe1                	j	8000435a <writei+0xf0>
    return -1;
    80004384:	557d                	li	a0,-1
    80004386:	bfd1                	j	8000435a <writei+0xf0>

0000000080004388 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004388:	1141                	addi	sp,sp,-16
    8000438a:	e406                	sd	ra,8(sp)
    8000438c:	e022                	sd	s0,0(sp)
    8000438e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004390:	4639                	li	a2,14
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	a4a080e7          	jalr	-1462(ra) # 80000ddc <strncmp>
}
    8000439a:	60a2                	ld	ra,8(sp)
    8000439c:	6402                	ld	s0,0(sp)
    8000439e:	0141                	addi	sp,sp,16
    800043a0:	8082                	ret

00000000800043a2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043a2:	7139                	addi	sp,sp,-64
    800043a4:	fc06                	sd	ra,56(sp)
    800043a6:	f822                	sd	s0,48(sp)
    800043a8:	f426                	sd	s1,40(sp)
    800043aa:	f04a                	sd	s2,32(sp)
    800043ac:	ec4e                	sd	s3,24(sp)
    800043ae:	e852                	sd	s4,16(sp)
    800043b0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043b2:	04451703          	lh	a4,68(a0)
    800043b6:	4785                	li	a5,1
    800043b8:	00f71a63          	bne	a4,a5,800043cc <dirlookup+0x2a>
    800043bc:	892a                	mv	s2,a0
    800043be:	89ae                	mv	s3,a1
    800043c0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c2:	457c                	lw	a5,76(a0)
    800043c4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043c6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c8:	e79d                	bnez	a5,800043f6 <dirlookup+0x54>
    800043ca:	a8a5                	j	80004442 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043cc:	00004517          	auipc	a0,0x4
    800043d0:	2cc50513          	addi	a0,a0,716 # 80008698 <syscalls+0x1b8>
    800043d4:	ffffc097          	auipc	ra,0xffffc
    800043d8:	16a080e7          	jalr	362(ra) # 8000053e <panic>
      panic("dirlookup read");
    800043dc:	00004517          	auipc	a0,0x4
    800043e0:	2d450513          	addi	a0,a0,724 # 800086b0 <syscalls+0x1d0>
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	15a080e7          	jalr	346(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ec:	24c1                	addiw	s1,s1,16
    800043ee:	04c92783          	lw	a5,76(s2)
    800043f2:	04f4f763          	bgeu	s1,a5,80004440 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043f6:	4741                	li	a4,16
    800043f8:	86a6                	mv	a3,s1
    800043fa:	fc040613          	addi	a2,s0,-64
    800043fe:	4581                	li	a1,0
    80004400:	854a                	mv	a0,s2
    80004402:	00000097          	auipc	ra,0x0
    80004406:	d70080e7          	jalr	-656(ra) # 80004172 <readi>
    8000440a:	47c1                	li	a5,16
    8000440c:	fcf518e3          	bne	a0,a5,800043dc <dirlookup+0x3a>
    if(de.inum == 0)
    80004410:	fc045783          	lhu	a5,-64(s0)
    80004414:	dfe1                	beqz	a5,800043ec <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004416:	fc240593          	addi	a1,s0,-62
    8000441a:	854e                	mv	a0,s3
    8000441c:	00000097          	auipc	ra,0x0
    80004420:	f6c080e7          	jalr	-148(ra) # 80004388 <namecmp>
    80004424:	f561                	bnez	a0,800043ec <dirlookup+0x4a>
      if(poff)
    80004426:	000a0463          	beqz	s4,8000442e <dirlookup+0x8c>
        *poff = off;
    8000442a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000442e:	fc045583          	lhu	a1,-64(s0)
    80004432:	00092503          	lw	a0,0(s2)
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	754080e7          	jalr	1876(ra) # 80003b8a <iget>
    8000443e:	a011                	j	80004442 <dirlookup+0xa0>
  return 0;
    80004440:	4501                	li	a0,0
}
    80004442:	70e2                	ld	ra,56(sp)
    80004444:	7442                	ld	s0,48(sp)
    80004446:	74a2                	ld	s1,40(sp)
    80004448:	7902                	ld	s2,32(sp)
    8000444a:	69e2                	ld	s3,24(sp)
    8000444c:	6a42                	ld	s4,16(sp)
    8000444e:	6121                	addi	sp,sp,64
    80004450:	8082                	ret

0000000080004452 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004452:	711d                	addi	sp,sp,-96
    80004454:	ec86                	sd	ra,88(sp)
    80004456:	e8a2                	sd	s0,80(sp)
    80004458:	e4a6                	sd	s1,72(sp)
    8000445a:	e0ca                	sd	s2,64(sp)
    8000445c:	fc4e                	sd	s3,56(sp)
    8000445e:	f852                	sd	s4,48(sp)
    80004460:	f456                	sd	s5,40(sp)
    80004462:	f05a                	sd	s6,32(sp)
    80004464:	ec5e                	sd	s7,24(sp)
    80004466:	e862                	sd	s8,16(sp)
    80004468:	e466                	sd	s9,8(sp)
    8000446a:	1080                	addi	s0,sp,96
    8000446c:	84aa                	mv	s1,a0
    8000446e:	8b2e                	mv	s6,a1
    80004470:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004472:	00054703          	lbu	a4,0(a0)
    80004476:	02f00793          	li	a5,47
    8000447a:	02f70363          	beq	a4,a5,800044a0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000447e:	ffffe097          	auipc	ra,0xffffe
    80004482:	946080e7          	jalr	-1722(ra) # 80001dc4 <myproc>
    80004486:	17053503          	ld	a0,368(a0)
    8000448a:	00000097          	auipc	ra,0x0
    8000448e:	9f6080e7          	jalr	-1546(ra) # 80003e80 <idup>
    80004492:	89aa                	mv	s3,a0
  while(*path == '/')
    80004494:	02f00913          	li	s2,47
  len = path - s;
    80004498:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000449a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000449c:	4c05                	li	s8,1
    8000449e:	a865                	j	80004556 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044a0:	4585                	li	a1,1
    800044a2:	4505                	li	a0,1
    800044a4:	fffff097          	auipc	ra,0xfffff
    800044a8:	6e6080e7          	jalr	1766(ra) # 80003b8a <iget>
    800044ac:	89aa                	mv	s3,a0
    800044ae:	b7dd                	j	80004494 <namex+0x42>
      iunlockput(ip);
    800044b0:	854e                	mv	a0,s3
    800044b2:	00000097          	auipc	ra,0x0
    800044b6:	c6e080e7          	jalr	-914(ra) # 80004120 <iunlockput>
      return 0;
    800044ba:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044bc:	854e                	mv	a0,s3
    800044be:	60e6                	ld	ra,88(sp)
    800044c0:	6446                	ld	s0,80(sp)
    800044c2:	64a6                	ld	s1,72(sp)
    800044c4:	6906                	ld	s2,64(sp)
    800044c6:	79e2                	ld	s3,56(sp)
    800044c8:	7a42                	ld	s4,48(sp)
    800044ca:	7aa2                	ld	s5,40(sp)
    800044cc:	7b02                	ld	s6,32(sp)
    800044ce:	6be2                	ld	s7,24(sp)
    800044d0:	6c42                	ld	s8,16(sp)
    800044d2:	6ca2                	ld	s9,8(sp)
    800044d4:	6125                	addi	sp,sp,96
    800044d6:	8082                	ret
      iunlock(ip);
    800044d8:	854e                	mv	a0,s3
    800044da:	00000097          	auipc	ra,0x0
    800044de:	aa6080e7          	jalr	-1370(ra) # 80003f80 <iunlock>
      return ip;
    800044e2:	bfe9                	j	800044bc <namex+0x6a>
      iunlockput(ip);
    800044e4:	854e                	mv	a0,s3
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	c3a080e7          	jalr	-966(ra) # 80004120 <iunlockput>
      return 0;
    800044ee:	89d2                	mv	s3,s4
    800044f0:	b7f1                	j	800044bc <namex+0x6a>
  len = path - s;
    800044f2:	40b48633          	sub	a2,s1,a1
    800044f6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800044fa:	094cd463          	bge	s9,s4,80004582 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800044fe:	4639                	li	a2,14
    80004500:	8556                	mv	a0,s5
    80004502:	ffffd097          	auipc	ra,0xffffd
    80004506:	862080e7          	jalr	-1950(ra) # 80000d64 <memmove>
  while(*path == '/')
    8000450a:	0004c783          	lbu	a5,0(s1)
    8000450e:	01279763          	bne	a5,s2,8000451c <namex+0xca>
    path++;
    80004512:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004514:	0004c783          	lbu	a5,0(s1)
    80004518:	ff278de3          	beq	a5,s2,80004512 <namex+0xc0>
    ilock(ip);
    8000451c:	854e                	mv	a0,s3
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	9a0080e7          	jalr	-1632(ra) # 80003ebe <ilock>
    if(ip->type != T_DIR){
    80004526:	04499783          	lh	a5,68(s3)
    8000452a:	f98793e3          	bne	a5,s8,800044b0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000452e:	000b0563          	beqz	s6,80004538 <namex+0xe6>
    80004532:	0004c783          	lbu	a5,0(s1)
    80004536:	d3cd                	beqz	a5,800044d8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004538:	865e                	mv	a2,s7
    8000453a:	85d6                	mv	a1,s5
    8000453c:	854e                	mv	a0,s3
    8000453e:	00000097          	auipc	ra,0x0
    80004542:	e64080e7          	jalr	-412(ra) # 800043a2 <dirlookup>
    80004546:	8a2a                	mv	s4,a0
    80004548:	dd51                	beqz	a0,800044e4 <namex+0x92>
    iunlockput(ip);
    8000454a:	854e                	mv	a0,s3
    8000454c:	00000097          	auipc	ra,0x0
    80004550:	bd4080e7          	jalr	-1068(ra) # 80004120 <iunlockput>
    ip = next;
    80004554:	89d2                	mv	s3,s4
  while(*path == '/')
    80004556:	0004c783          	lbu	a5,0(s1)
    8000455a:	05279763          	bne	a5,s2,800045a8 <namex+0x156>
    path++;
    8000455e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004560:	0004c783          	lbu	a5,0(s1)
    80004564:	ff278de3          	beq	a5,s2,8000455e <namex+0x10c>
  if(*path == 0)
    80004568:	c79d                	beqz	a5,80004596 <namex+0x144>
    path++;
    8000456a:	85a6                	mv	a1,s1
  len = path - s;
    8000456c:	8a5e                	mv	s4,s7
    8000456e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004570:	01278963          	beq	a5,s2,80004582 <namex+0x130>
    80004574:	dfbd                	beqz	a5,800044f2 <namex+0xa0>
    path++;
    80004576:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004578:	0004c783          	lbu	a5,0(s1)
    8000457c:	ff279ce3          	bne	a5,s2,80004574 <namex+0x122>
    80004580:	bf8d                	j	800044f2 <namex+0xa0>
    memmove(name, s, len);
    80004582:	2601                	sext.w	a2,a2
    80004584:	8556                	mv	a0,s5
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	7de080e7          	jalr	2014(ra) # 80000d64 <memmove>
    name[len] = 0;
    8000458e:	9a56                	add	s4,s4,s5
    80004590:	000a0023          	sb	zero,0(s4)
    80004594:	bf9d                	j	8000450a <namex+0xb8>
  if(nameiparent){
    80004596:	f20b03e3          	beqz	s6,800044bc <namex+0x6a>
    iput(ip);
    8000459a:	854e                	mv	a0,s3
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	adc080e7          	jalr	-1316(ra) # 80004078 <iput>
    return 0;
    800045a4:	4981                	li	s3,0
    800045a6:	bf19                	j	800044bc <namex+0x6a>
  if(*path == 0)
    800045a8:	d7fd                	beqz	a5,80004596 <namex+0x144>
  while(*path != '/' && *path != 0)
    800045aa:	0004c783          	lbu	a5,0(s1)
    800045ae:	85a6                	mv	a1,s1
    800045b0:	b7d1                	j	80004574 <namex+0x122>

00000000800045b2 <dirlink>:
{
    800045b2:	7139                	addi	sp,sp,-64
    800045b4:	fc06                	sd	ra,56(sp)
    800045b6:	f822                	sd	s0,48(sp)
    800045b8:	f426                	sd	s1,40(sp)
    800045ba:	f04a                	sd	s2,32(sp)
    800045bc:	ec4e                	sd	s3,24(sp)
    800045be:	e852                	sd	s4,16(sp)
    800045c0:	0080                	addi	s0,sp,64
    800045c2:	892a                	mv	s2,a0
    800045c4:	8a2e                	mv	s4,a1
    800045c6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045c8:	4601                	li	a2,0
    800045ca:	00000097          	auipc	ra,0x0
    800045ce:	dd8080e7          	jalr	-552(ra) # 800043a2 <dirlookup>
    800045d2:	e93d                	bnez	a0,80004648 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045d4:	04c92483          	lw	s1,76(s2)
    800045d8:	c49d                	beqz	s1,80004606 <dirlink+0x54>
    800045da:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045dc:	4741                	li	a4,16
    800045de:	86a6                	mv	a3,s1
    800045e0:	fc040613          	addi	a2,s0,-64
    800045e4:	4581                	li	a1,0
    800045e6:	854a                	mv	a0,s2
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	b8a080e7          	jalr	-1142(ra) # 80004172 <readi>
    800045f0:	47c1                	li	a5,16
    800045f2:	06f51163          	bne	a0,a5,80004654 <dirlink+0xa2>
    if(de.inum == 0)
    800045f6:	fc045783          	lhu	a5,-64(s0)
    800045fa:	c791                	beqz	a5,80004606 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045fc:	24c1                	addiw	s1,s1,16
    800045fe:	04c92783          	lw	a5,76(s2)
    80004602:	fcf4ede3          	bltu	s1,a5,800045dc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004606:	4639                	li	a2,14
    80004608:	85d2                	mv	a1,s4
    8000460a:	fc240513          	addi	a0,s0,-62
    8000460e:	ffffd097          	auipc	ra,0xffffd
    80004612:	80a080e7          	jalr	-2038(ra) # 80000e18 <strncpy>
  de.inum = inum;
    80004616:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000461a:	4741                	li	a4,16
    8000461c:	86a6                	mv	a3,s1
    8000461e:	fc040613          	addi	a2,s0,-64
    80004622:	4581                	li	a1,0
    80004624:	854a                	mv	a0,s2
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	c44080e7          	jalr	-956(ra) # 8000426a <writei>
    8000462e:	872a                	mv	a4,a0
    80004630:	47c1                	li	a5,16
  return 0;
    80004632:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004634:	02f71863          	bne	a4,a5,80004664 <dirlink+0xb2>
}
    80004638:	70e2                	ld	ra,56(sp)
    8000463a:	7442                	ld	s0,48(sp)
    8000463c:	74a2                	ld	s1,40(sp)
    8000463e:	7902                	ld	s2,32(sp)
    80004640:	69e2                	ld	s3,24(sp)
    80004642:	6a42                	ld	s4,16(sp)
    80004644:	6121                	addi	sp,sp,64
    80004646:	8082                	ret
    iput(ip);
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	a30080e7          	jalr	-1488(ra) # 80004078 <iput>
    return -1;
    80004650:	557d                	li	a0,-1
    80004652:	b7dd                	j	80004638 <dirlink+0x86>
      panic("dirlink read");
    80004654:	00004517          	auipc	a0,0x4
    80004658:	06c50513          	addi	a0,a0,108 # 800086c0 <syscalls+0x1e0>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>
    panic("dirlink");
    80004664:	00004517          	auipc	a0,0x4
    80004668:	16c50513          	addi	a0,a0,364 # 800087d0 <syscalls+0x2f0>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	ed2080e7          	jalr	-302(ra) # 8000053e <panic>

0000000080004674 <namei>:

struct inode*
namei(char *path)
{
    80004674:	1101                	addi	sp,sp,-32
    80004676:	ec06                	sd	ra,24(sp)
    80004678:	e822                	sd	s0,16(sp)
    8000467a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000467c:	fe040613          	addi	a2,s0,-32
    80004680:	4581                	li	a1,0
    80004682:	00000097          	auipc	ra,0x0
    80004686:	dd0080e7          	jalr	-560(ra) # 80004452 <namex>
}
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	6105                	addi	sp,sp,32
    80004690:	8082                	ret

0000000080004692 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004692:	1141                	addi	sp,sp,-16
    80004694:	e406                	sd	ra,8(sp)
    80004696:	e022                	sd	s0,0(sp)
    80004698:	0800                	addi	s0,sp,16
    8000469a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000469c:	4585                	li	a1,1
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	db4080e7          	jalr	-588(ra) # 80004452 <namex>
}
    800046a6:	60a2                	ld	ra,8(sp)
    800046a8:	6402                	ld	s0,0(sp)
    800046aa:	0141                	addi	sp,sp,16
    800046ac:	8082                	ret

00000000800046ae <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046ae:	1101                	addi	sp,sp,-32
    800046b0:	ec06                	sd	ra,24(sp)
    800046b2:	e822                	sd	s0,16(sp)
    800046b4:	e426                	sd	s1,8(sp)
    800046b6:	e04a                	sd	s2,0(sp)
    800046b8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046ba:	0001d917          	auipc	s2,0x1d
    800046be:	47e90913          	addi	s2,s2,1150 # 80021b38 <log>
    800046c2:	01892583          	lw	a1,24(s2)
    800046c6:	02892503          	lw	a0,40(s2)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	ff2080e7          	jalr	-14(ra) # 800036bc <bread>
    800046d2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046d4:	02c92683          	lw	a3,44(s2)
    800046d8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046da:	02d05763          	blez	a3,80004708 <write_head+0x5a>
    800046de:	0001d797          	auipc	a5,0x1d
    800046e2:	48a78793          	addi	a5,a5,1162 # 80021b68 <log+0x30>
    800046e6:	05c50713          	addi	a4,a0,92
    800046ea:	36fd                	addiw	a3,a3,-1
    800046ec:	1682                	slli	a3,a3,0x20
    800046ee:	9281                	srli	a3,a3,0x20
    800046f0:	068a                	slli	a3,a3,0x2
    800046f2:	0001d617          	auipc	a2,0x1d
    800046f6:	47a60613          	addi	a2,a2,1146 # 80021b6c <log+0x34>
    800046fa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800046fc:	4390                	lw	a2,0(a5)
    800046fe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004700:	0791                	addi	a5,a5,4
    80004702:	0711                	addi	a4,a4,4
    80004704:	fed79ce3          	bne	a5,a3,800046fc <write_head+0x4e>
  }
  bwrite(buf);
    80004708:	8526                	mv	a0,s1
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	0a4080e7          	jalr	164(ra) # 800037ae <bwrite>
  brelse(buf);
    80004712:	8526                	mv	a0,s1
    80004714:	fffff097          	auipc	ra,0xfffff
    80004718:	0d8080e7          	jalr	216(ra) # 800037ec <brelse>
}
    8000471c:	60e2                	ld	ra,24(sp)
    8000471e:	6442                	ld	s0,16(sp)
    80004720:	64a2                	ld	s1,8(sp)
    80004722:	6902                	ld	s2,0(sp)
    80004724:	6105                	addi	sp,sp,32
    80004726:	8082                	ret

0000000080004728 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004728:	0001d797          	auipc	a5,0x1d
    8000472c:	43c7a783          	lw	a5,1084(a5) # 80021b64 <log+0x2c>
    80004730:	0af05d63          	blez	a5,800047ea <install_trans+0xc2>
{
    80004734:	7139                	addi	sp,sp,-64
    80004736:	fc06                	sd	ra,56(sp)
    80004738:	f822                	sd	s0,48(sp)
    8000473a:	f426                	sd	s1,40(sp)
    8000473c:	f04a                	sd	s2,32(sp)
    8000473e:	ec4e                	sd	s3,24(sp)
    80004740:	e852                	sd	s4,16(sp)
    80004742:	e456                	sd	s5,8(sp)
    80004744:	e05a                	sd	s6,0(sp)
    80004746:	0080                	addi	s0,sp,64
    80004748:	8b2a                	mv	s6,a0
    8000474a:	0001da97          	auipc	s5,0x1d
    8000474e:	41ea8a93          	addi	s5,s5,1054 # 80021b68 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004752:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004754:	0001d997          	auipc	s3,0x1d
    80004758:	3e498993          	addi	s3,s3,996 # 80021b38 <log>
    8000475c:	a035                	j	80004788 <install_trans+0x60>
      bunpin(dbuf);
    8000475e:	8526                	mv	a0,s1
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	166080e7          	jalr	358(ra) # 800038c6 <bunpin>
    brelse(lbuf);
    80004768:	854a                	mv	a0,s2
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	082080e7          	jalr	130(ra) # 800037ec <brelse>
    brelse(dbuf);
    80004772:	8526                	mv	a0,s1
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	078080e7          	jalr	120(ra) # 800037ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000477c:	2a05                	addiw	s4,s4,1
    8000477e:	0a91                	addi	s5,s5,4
    80004780:	02c9a783          	lw	a5,44(s3)
    80004784:	04fa5963          	bge	s4,a5,800047d6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004788:	0189a583          	lw	a1,24(s3)
    8000478c:	014585bb          	addw	a1,a1,s4
    80004790:	2585                	addiw	a1,a1,1
    80004792:	0289a503          	lw	a0,40(s3)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	f26080e7          	jalr	-218(ra) # 800036bc <bread>
    8000479e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047a0:	000aa583          	lw	a1,0(s5)
    800047a4:	0289a503          	lw	a0,40(s3)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	f14080e7          	jalr	-236(ra) # 800036bc <bread>
    800047b0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047b2:	40000613          	li	a2,1024
    800047b6:	05890593          	addi	a1,s2,88
    800047ba:	05850513          	addi	a0,a0,88
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	5a6080e7          	jalr	1446(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    800047c6:	8526                	mv	a0,s1
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	fe6080e7          	jalr	-26(ra) # 800037ae <bwrite>
    if(recovering == 0)
    800047d0:	f80b1ce3          	bnez	s6,80004768 <install_trans+0x40>
    800047d4:	b769                	j	8000475e <install_trans+0x36>
}
    800047d6:	70e2                	ld	ra,56(sp)
    800047d8:	7442                	ld	s0,48(sp)
    800047da:	74a2                	ld	s1,40(sp)
    800047dc:	7902                	ld	s2,32(sp)
    800047de:	69e2                	ld	s3,24(sp)
    800047e0:	6a42                	ld	s4,16(sp)
    800047e2:	6aa2                	ld	s5,8(sp)
    800047e4:	6b02                	ld	s6,0(sp)
    800047e6:	6121                	addi	sp,sp,64
    800047e8:	8082                	ret
    800047ea:	8082                	ret

00000000800047ec <initlog>:
{
    800047ec:	7179                	addi	sp,sp,-48
    800047ee:	f406                	sd	ra,40(sp)
    800047f0:	f022                	sd	s0,32(sp)
    800047f2:	ec26                	sd	s1,24(sp)
    800047f4:	e84a                	sd	s2,16(sp)
    800047f6:	e44e                	sd	s3,8(sp)
    800047f8:	1800                	addi	s0,sp,48
    800047fa:	892a                	mv	s2,a0
    800047fc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047fe:	0001d497          	auipc	s1,0x1d
    80004802:	33a48493          	addi	s1,s1,826 # 80021b38 <log>
    80004806:	00004597          	auipc	a1,0x4
    8000480a:	eca58593          	addi	a1,a1,-310 # 800086d0 <syscalls+0x1f0>
    8000480e:	8526                	mv	a0,s1
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	344080e7          	jalr	836(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004818:	0149a583          	lw	a1,20(s3)
    8000481c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000481e:	0109a783          	lw	a5,16(s3)
    80004822:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004824:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004828:	854a                	mv	a0,s2
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	e92080e7          	jalr	-366(ra) # 800036bc <bread>
  log.lh.n = lh->n;
    80004832:	4d3c                	lw	a5,88(a0)
    80004834:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004836:	02f05563          	blez	a5,80004860 <initlog+0x74>
    8000483a:	05c50713          	addi	a4,a0,92
    8000483e:	0001d697          	auipc	a3,0x1d
    80004842:	32a68693          	addi	a3,a3,810 # 80021b68 <log+0x30>
    80004846:	37fd                	addiw	a5,a5,-1
    80004848:	1782                	slli	a5,a5,0x20
    8000484a:	9381                	srli	a5,a5,0x20
    8000484c:	078a                	slli	a5,a5,0x2
    8000484e:	06050613          	addi	a2,a0,96
    80004852:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004854:	4310                	lw	a2,0(a4)
    80004856:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004858:	0711                	addi	a4,a4,4
    8000485a:	0691                	addi	a3,a3,4
    8000485c:	fef71ce3          	bne	a4,a5,80004854 <initlog+0x68>
  brelse(buf);
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	f8c080e7          	jalr	-116(ra) # 800037ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004868:	4505                	li	a0,1
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	ebe080e7          	jalr	-322(ra) # 80004728 <install_trans>
  log.lh.n = 0;
    80004872:	0001d797          	auipc	a5,0x1d
    80004876:	2e07a923          	sw	zero,754(a5) # 80021b64 <log+0x2c>
  write_head(); // clear the log
    8000487a:	00000097          	auipc	ra,0x0
    8000487e:	e34080e7          	jalr	-460(ra) # 800046ae <write_head>
}
    80004882:	70a2                	ld	ra,40(sp)
    80004884:	7402                	ld	s0,32(sp)
    80004886:	64e2                	ld	s1,24(sp)
    80004888:	6942                	ld	s2,16(sp)
    8000488a:	69a2                	ld	s3,8(sp)
    8000488c:	6145                	addi	sp,sp,48
    8000488e:	8082                	ret

0000000080004890 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004890:	1101                	addi	sp,sp,-32
    80004892:	ec06                	sd	ra,24(sp)
    80004894:	e822                	sd	s0,16(sp)
    80004896:	e426                	sd	s1,8(sp)
    80004898:	e04a                	sd	s2,0(sp)
    8000489a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000489c:	0001d517          	auipc	a0,0x1d
    800048a0:	29c50513          	addi	a0,a0,668 # 80021b38 <log>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	340080e7          	jalr	832(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800048ac:	0001d497          	auipc	s1,0x1d
    800048b0:	28c48493          	addi	s1,s1,652 # 80021b38 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048b4:	4979                	li	s2,30
    800048b6:	a039                	j	800048c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800048b8:	85a6                	mv	a1,s1
    800048ba:	8526                	mv	a0,s1
    800048bc:	ffffe097          	auipc	ra,0xffffe
    800048c0:	df0080e7          	jalr	-528(ra) # 800026ac <sleep>
    if(log.committing){
    800048c4:	50dc                	lw	a5,36(s1)
    800048c6:	fbed                	bnez	a5,800048b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048c8:	509c                	lw	a5,32(s1)
    800048ca:	0017871b          	addiw	a4,a5,1
    800048ce:	0007069b          	sext.w	a3,a4
    800048d2:	0027179b          	slliw	a5,a4,0x2
    800048d6:	9fb9                	addw	a5,a5,a4
    800048d8:	0017979b          	slliw	a5,a5,0x1
    800048dc:	54d8                	lw	a4,44(s1)
    800048de:	9fb9                	addw	a5,a5,a4
    800048e0:	00f95963          	bge	s2,a5,800048f2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048e4:	85a6                	mv	a1,s1
    800048e6:	8526                	mv	a0,s1
    800048e8:	ffffe097          	auipc	ra,0xffffe
    800048ec:	dc4080e7          	jalr	-572(ra) # 800026ac <sleep>
    800048f0:	bfd1                	j	800048c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048f2:	0001d517          	auipc	a0,0x1d
    800048f6:	24650513          	addi	a0,a0,582 # 80021b38 <log>
    800048fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	3ae080e7          	jalr	942(ra) # 80000caa <release>
      break;
    }
  }
}
    80004904:	60e2                	ld	ra,24(sp)
    80004906:	6442                	ld	s0,16(sp)
    80004908:	64a2                	ld	s1,8(sp)
    8000490a:	6902                	ld	s2,0(sp)
    8000490c:	6105                	addi	sp,sp,32
    8000490e:	8082                	ret

0000000080004910 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004910:	7139                	addi	sp,sp,-64
    80004912:	fc06                	sd	ra,56(sp)
    80004914:	f822                	sd	s0,48(sp)
    80004916:	f426                	sd	s1,40(sp)
    80004918:	f04a                	sd	s2,32(sp)
    8000491a:	ec4e                	sd	s3,24(sp)
    8000491c:	e852                	sd	s4,16(sp)
    8000491e:	e456                	sd	s5,8(sp)
    80004920:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004922:	0001d497          	auipc	s1,0x1d
    80004926:	21648493          	addi	s1,s1,534 # 80021b38 <log>
    8000492a:	8526                	mv	a0,s1
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	2b8080e7          	jalr	696(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004934:	509c                	lw	a5,32(s1)
    80004936:	37fd                	addiw	a5,a5,-1
    80004938:	0007891b          	sext.w	s2,a5
    8000493c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000493e:	50dc                	lw	a5,36(s1)
    80004940:	efb9                	bnez	a5,8000499e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004942:	06091663          	bnez	s2,800049ae <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004946:	0001d497          	auipc	s1,0x1d
    8000494a:	1f248493          	addi	s1,s1,498 # 80021b38 <log>
    8000494e:	4785                	li	a5,1
    80004950:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004952:	8526                	mv	a0,s1
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	356080e7          	jalr	854(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000495c:	54dc                	lw	a5,44(s1)
    8000495e:	06f04763          	bgtz	a5,800049cc <end_op+0xbc>
    acquire(&log.lock);
    80004962:	0001d497          	auipc	s1,0x1d
    80004966:	1d648493          	addi	s1,s1,470 # 80021b38 <log>
    8000496a:	8526                	mv	a0,s1
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	278080e7          	jalr	632(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004974:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004978:	8526                	mv	a0,s1
    8000497a:	ffffe097          	auipc	ra,0xffffe
    8000497e:	eea080e7          	jalr	-278(ra) # 80002864 <wakeup>
    release(&log.lock);
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	326080e7          	jalr	806(ra) # 80000caa <release>
}
    8000498c:	70e2                	ld	ra,56(sp)
    8000498e:	7442                	ld	s0,48(sp)
    80004990:	74a2                	ld	s1,40(sp)
    80004992:	7902                	ld	s2,32(sp)
    80004994:	69e2                	ld	s3,24(sp)
    80004996:	6a42                	ld	s4,16(sp)
    80004998:	6aa2                	ld	s5,8(sp)
    8000499a:	6121                	addi	sp,sp,64
    8000499c:	8082                	ret
    panic("log.committing");
    8000499e:	00004517          	auipc	a0,0x4
    800049a2:	d3a50513          	addi	a0,a0,-710 # 800086d8 <syscalls+0x1f8>
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	b98080e7          	jalr	-1128(ra) # 8000053e <panic>
    wakeup(&log);
    800049ae:	0001d497          	auipc	s1,0x1d
    800049b2:	18a48493          	addi	s1,s1,394 # 80021b38 <log>
    800049b6:	8526                	mv	a0,s1
    800049b8:	ffffe097          	auipc	ra,0xffffe
    800049bc:	eac080e7          	jalr	-340(ra) # 80002864 <wakeup>
  release(&log.lock);
    800049c0:	8526                	mv	a0,s1
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	2e8080e7          	jalr	744(ra) # 80000caa <release>
  if(do_commit){
    800049ca:	b7c9                	j	8000498c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049cc:	0001da97          	auipc	s5,0x1d
    800049d0:	19ca8a93          	addi	s5,s5,412 # 80021b68 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049d4:	0001da17          	auipc	s4,0x1d
    800049d8:	164a0a13          	addi	s4,s4,356 # 80021b38 <log>
    800049dc:	018a2583          	lw	a1,24(s4)
    800049e0:	012585bb          	addw	a1,a1,s2
    800049e4:	2585                	addiw	a1,a1,1
    800049e6:	028a2503          	lw	a0,40(s4)
    800049ea:	fffff097          	auipc	ra,0xfffff
    800049ee:	cd2080e7          	jalr	-814(ra) # 800036bc <bread>
    800049f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049f4:	000aa583          	lw	a1,0(s5)
    800049f8:	028a2503          	lw	a0,40(s4)
    800049fc:	fffff097          	auipc	ra,0xfffff
    80004a00:	cc0080e7          	jalr	-832(ra) # 800036bc <bread>
    80004a04:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a06:	40000613          	li	a2,1024
    80004a0a:	05850593          	addi	a1,a0,88
    80004a0e:	05848513          	addi	a0,s1,88
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	352080e7          	jalr	850(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	d92080e7          	jalr	-622(ra) # 800037ae <bwrite>
    brelse(from);
    80004a24:	854e                	mv	a0,s3
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	dc6080e7          	jalr	-570(ra) # 800037ec <brelse>
    brelse(to);
    80004a2e:	8526                	mv	a0,s1
    80004a30:	fffff097          	auipc	ra,0xfffff
    80004a34:	dbc080e7          	jalr	-580(ra) # 800037ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a38:	2905                	addiw	s2,s2,1
    80004a3a:	0a91                	addi	s5,s5,4
    80004a3c:	02ca2783          	lw	a5,44(s4)
    80004a40:	f8f94ee3          	blt	s2,a5,800049dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	c6a080e7          	jalr	-918(ra) # 800046ae <write_head>
    install_trans(0); // Now install writes to home locations
    80004a4c:	4501                	li	a0,0
    80004a4e:	00000097          	auipc	ra,0x0
    80004a52:	cda080e7          	jalr	-806(ra) # 80004728 <install_trans>
    log.lh.n = 0;
    80004a56:	0001d797          	auipc	a5,0x1d
    80004a5a:	1007a723          	sw	zero,270(a5) # 80021b64 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	c50080e7          	jalr	-944(ra) # 800046ae <write_head>
    80004a66:	bdf5                	j	80004962 <end_op+0x52>

0000000080004a68 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a68:	1101                	addi	sp,sp,-32
    80004a6a:	ec06                	sd	ra,24(sp)
    80004a6c:	e822                	sd	s0,16(sp)
    80004a6e:	e426                	sd	s1,8(sp)
    80004a70:	e04a                	sd	s2,0(sp)
    80004a72:	1000                	addi	s0,sp,32
    80004a74:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a76:	0001d917          	auipc	s2,0x1d
    80004a7a:	0c290913          	addi	s2,s2,194 # 80021b38 <log>
    80004a7e:	854a                	mv	a0,s2
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	164080e7          	jalr	356(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a88:	02c92603          	lw	a2,44(s2)
    80004a8c:	47f5                	li	a5,29
    80004a8e:	06c7c563          	blt	a5,a2,80004af8 <log_write+0x90>
    80004a92:	0001d797          	auipc	a5,0x1d
    80004a96:	0c27a783          	lw	a5,194(a5) # 80021b54 <log+0x1c>
    80004a9a:	37fd                	addiw	a5,a5,-1
    80004a9c:	04f65e63          	bge	a2,a5,80004af8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004aa0:	0001d797          	auipc	a5,0x1d
    80004aa4:	0b87a783          	lw	a5,184(a5) # 80021b58 <log+0x20>
    80004aa8:	06f05063          	blez	a5,80004b08 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004aac:	4781                	li	a5,0
    80004aae:	06c05563          	blez	a2,80004b18 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ab2:	44cc                	lw	a1,12(s1)
    80004ab4:	0001d717          	auipc	a4,0x1d
    80004ab8:	0b470713          	addi	a4,a4,180 # 80021b68 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004abc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004abe:	4314                	lw	a3,0(a4)
    80004ac0:	04b68c63          	beq	a3,a1,80004b18 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ac4:	2785                	addiw	a5,a5,1
    80004ac6:	0711                	addi	a4,a4,4
    80004ac8:	fef61be3          	bne	a2,a5,80004abe <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004acc:	0621                	addi	a2,a2,8
    80004ace:	060a                	slli	a2,a2,0x2
    80004ad0:	0001d797          	auipc	a5,0x1d
    80004ad4:	06878793          	addi	a5,a5,104 # 80021b38 <log>
    80004ad8:	963e                	add	a2,a2,a5
    80004ada:	44dc                	lw	a5,12(s1)
    80004adc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	daa080e7          	jalr	-598(ra) # 8000388a <bpin>
    log.lh.n++;
    80004ae8:	0001d717          	auipc	a4,0x1d
    80004aec:	05070713          	addi	a4,a4,80 # 80021b38 <log>
    80004af0:	575c                	lw	a5,44(a4)
    80004af2:	2785                	addiw	a5,a5,1
    80004af4:	d75c                	sw	a5,44(a4)
    80004af6:	a835                	j	80004b32 <log_write+0xca>
    panic("too big a transaction");
    80004af8:	00004517          	auipc	a0,0x4
    80004afc:	bf050513          	addi	a0,a0,-1040 # 800086e8 <syscalls+0x208>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	a3e080e7          	jalr	-1474(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b08:	00004517          	auipc	a0,0x4
    80004b0c:	bf850513          	addi	a0,a0,-1032 # 80008700 <syscalls+0x220>
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	a2e080e7          	jalr	-1490(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b18:	00878713          	addi	a4,a5,8
    80004b1c:	00271693          	slli	a3,a4,0x2
    80004b20:	0001d717          	auipc	a4,0x1d
    80004b24:	01870713          	addi	a4,a4,24 # 80021b38 <log>
    80004b28:	9736                	add	a4,a4,a3
    80004b2a:	44d4                	lw	a3,12(s1)
    80004b2c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b2e:	faf608e3          	beq	a2,a5,80004ade <log_write+0x76>
  }
  release(&log.lock);
    80004b32:	0001d517          	auipc	a0,0x1d
    80004b36:	00650513          	addi	a0,a0,6 # 80021b38 <log>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	170080e7          	jalr	368(ra) # 80000caa <release>
}
    80004b42:	60e2                	ld	ra,24(sp)
    80004b44:	6442                	ld	s0,16(sp)
    80004b46:	64a2                	ld	s1,8(sp)
    80004b48:	6902                	ld	s2,0(sp)
    80004b4a:	6105                	addi	sp,sp,32
    80004b4c:	8082                	ret

0000000080004b4e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b4e:	1101                	addi	sp,sp,-32
    80004b50:	ec06                	sd	ra,24(sp)
    80004b52:	e822                	sd	s0,16(sp)
    80004b54:	e426                	sd	s1,8(sp)
    80004b56:	e04a                	sd	s2,0(sp)
    80004b58:	1000                	addi	s0,sp,32
    80004b5a:	84aa                	mv	s1,a0
    80004b5c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b5e:	00004597          	auipc	a1,0x4
    80004b62:	bc258593          	addi	a1,a1,-1086 # 80008720 <syscalls+0x240>
    80004b66:	0521                	addi	a0,a0,8
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	fec080e7          	jalr	-20(ra) # 80000b54 <initlock>
  lk->name = name;
    80004b70:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b74:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b78:	0204a423          	sw	zero,40(s1)
}
    80004b7c:	60e2                	ld	ra,24(sp)
    80004b7e:	6442                	ld	s0,16(sp)
    80004b80:	64a2                	ld	s1,8(sp)
    80004b82:	6902                	ld	s2,0(sp)
    80004b84:	6105                	addi	sp,sp,32
    80004b86:	8082                	ret

0000000080004b88 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b88:	1101                	addi	sp,sp,-32
    80004b8a:	ec06                	sd	ra,24(sp)
    80004b8c:	e822                	sd	s0,16(sp)
    80004b8e:	e426                	sd	s1,8(sp)
    80004b90:	e04a                	sd	s2,0(sp)
    80004b92:	1000                	addi	s0,sp,32
    80004b94:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b96:	00850913          	addi	s2,a0,8
    80004b9a:	854a                	mv	a0,s2
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	048080e7          	jalr	72(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004ba4:	409c                	lw	a5,0(s1)
    80004ba6:	cb89                	beqz	a5,80004bb8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ba8:	85ca                	mv	a1,s2
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffe097          	auipc	ra,0xffffe
    80004bb0:	b00080e7          	jalr	-1280(ra) # 800026ac <sleep>
  while (lk->locked) {
    80004bb4:	409c                	lw	a5,0(s1)
    80004bb6:	fbed                	bnez	a5,80004ba8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bb8:	4785                	li	a5,1
    80004bba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	208080e7          	jalr	520(ra) # 80001dc4 <myproc>
    80004bc4:	591c                	lw	a5,48(a0)
    80004bc6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bc8:	854a                	mv	a0,s2
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	0e0080e7          	jalr	224(ra) # 80000caa <release>
}
    80004bd2:	60e2                	ld	ra,24(sp)
    80004bd4:	6442                	ld	s0,16(sp)
    80004bd6:	64a2                	ld	s1,8(sp)
    80004bd8:	6902                	ld	s2,0(sp)
    80004bda:	6105                	addi	sp,sp,32
    80004bdc:	8082                	ret

0000000080004bde <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004bde:	1101                	addi	sp,sp,-32
    80004be0:	ec06                	sd	ra,24(sp)
    80004be2:	e822                	sd	s0,16(sp)
    80004be4:	e426                	sd	s1,8(sp)
    80004be6:	e04a                	sd	s2,0(sp)
    80004be8:	1000                	addi	s0,sp,32
    80004bea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bec:	00850913          	addi	s2,a0,8
    80004bf0:	854a                	mv	a0,s2
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	ff2080e7          	jalr	-14(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004bfa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bfe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c02:	8526                	mv	a0,s1
    80004c04:	ffffe097          	auipc	ra,0xffffe
    80004c08:	c60080e7          	jalr	-928(ra) # 80002864 <wakeup>
  release(&lk->lk);
    80004c0c:	854a                	mv	a0,s2
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	09c080e7          	jalr	156(ra) # 80000caa <release>
}
    80004c16:	60e2                	ld	ra,24(sp)
    80004c18:	6442                	ld	s0,16(sp)
    80004c1a:	64a2                	ld	s1,8(sp)
    80004c1c:	6902                	ld	s2,0(sp)
    80004c1e:	6105                	addi	sp,sp,32
    80004c20:	8082                	ret

0000000080004c22 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c22:	7179                	addi	sp,sp,-48
    80004c24:	f406                	sd	ra,40(sp)
    80004c26:	f022                	sd	s0,32(sp)
    80004c28:	ec26                	sd	s1,24(sp)
    80004c2a:	e84a                	sd	s2,16(sp)
    80004c2c:	e44e                	sd	s3,8(sp)
    80004c2e:	1800                	addi	s0,sp,48
    80004c30:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c32:	00850913          	addi	s2,a0,8
    80004c36:	854a                	mv	a0,s2
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	fac080e7          	jalr	-84(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c40:	409c                	lw	a5,0(s1)
    80004c42:	ef99                	bnez	a5,80004c60 <holdingsleep+0x3e>
    80004c44:	4481                	li	s1,0
  release(&lk->lk);
    80004c46:	854a                	mv	a0,s2
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	062080e7          	jalr	98(ra) # 80000caa <release>
  return r;
}
    80004c50:	8526                	mv	a0,s1
    80004c52:	70a2                	ld	ra,40(sp)
    80004c54:	7402                	ld	s0,32(sp)
    80004c56:	64e2                	ld	s1,24(sp)
    80004c58:	6942                	ld	s2,16(sp)
    80004c5a:	69a2                	ld	s3,8(sp)
    80004c5c:	6145                	addi	sp,sp,48
    80004c5e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c60:	0284a983          	lw	s3,40(s1)
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	160080e7          	jalr	352(ra) # 80001dc4 <myproc>
    80004c6c:	5904                	lw	s1,48(a0)
    80004c6e:	413484b3          	sub	s1,s1,s3
    80004c72:	0014b493          	seqz	s1,s1
    80004c76:	bfc1                	j	80004c46 <holdingsleep+0x24>

0000000080004c78 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c78:	1141                	addi	sp,sp,-16
    80004c7a:	e406                	sd	ra,8(sp)
    80004c7c:	e022                	sd	s0,0(sp)
    80004c7e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c80:	00004597          	auipc	a1,0x4
    80004c84:	ab058593          	addi	a1,a1,-1360 # 80008730 <syscalls+0x250>
    80004c88:	0001d517          	auipc	a0,0x1d
    80004c8c:	ff850513          	addi	a0,a0,-8 # 80021c80 <ftable>
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	ec4080e7          	jalr	-316(ra) # 80000b54 <initlock>
}
    80004c98:	60a2                	ld	ra,8(sp)
    80004c9a:	6402                	ld	s0,0(sp)
    80004c9c:	0141                	addi	sp,sp,16
    80004c9e:	8082                	ret

0000000080004ca0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ca0:	1101                	addi	sp,sp,-32
    80004ca2:	ec06                	sd	ra,24(sp)
    80004ca4:	e822                	sd	s0,16(sp)
    80004ca6:	e426                	sd	s1,8(sp)
    80004ca8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004caa:	0001d517          	auipc	a0,0x1d
    80004cae:	fd650513          	addi	a0,a0,-42 # 80021c80 <ftable>
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	f32080e7          	jalr	-206(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cba:	0001d497          	auipc	s1,0x1d
    80004cbe:	fde48493          	addi	s1,s1,-34 # 80021c98 <ftable+0x18>
    80004cc2:	0001e717          	auipc	a4,0x1e
    80004cc6:	f7670713          	addi	a4,a4,-138 # 80022c38 <ftable+0xfb8>
    if(f->ref == 0){
    80004cca:	40dc                	lw	a5,4(s1)
    80004ccc:	cf99                	beqz	a5,80004cea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cce:	02848493          	addi	s1,s1,40
    80004cd2:	fee49ce3          	bne	s1,a4,80004cca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cd6:	0001d517          	auipc	a0,0x1d
    80004cda:	faa50513          	addi	a0,a0,-86 # 80021c80 <ftable>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	fcc080e7          	jalr	-52(ra) # 80000caa <release>
  return 0;
    80004ce6:	4481                	li	s1,0
    80004ce8:	a819                	j	80004cfe <filealloc+0x5e>
      f->ref = 1;
    80004cea:	4785                	li	a5,1
    80004cec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004cee:	0001d517          	auipc	a0,0x1d
    80004cf2:	f9250513          	addi	a0,a0,-110 # 80021c80 <ftable>
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	fb4080e7          	jalr	-76(ra) # 80000caa <release>
}
    80004cfe:	8526                	mv	a0,s1
    80004d00:	60e2                	ld	ra,24(sp)
    80004d02:	6442                	ld	s0,16(sp)
    80004d04:	64a2                	ld	s1,8(sp)
    80004d06:	6105                	addi	sp,sp,32
    80004d08:	8082                	ret

0000000080004d0a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d0a:	1101                	addi	sp,sp,-32
    80004d0c:	ec06                	sd	ra,24(sp)
    80004d0e:	e822                	sd	s0,16(sp)
    80004d10:	e426                	sd	s1,8(sp)
    80004d12:	1000                	addi	s0,sp,32
    80004d14:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d16:	0001d517          	auipc	a0,0x1d
    80004d1a:	f6a50513          	addi	a0,a0,-150 # 80021c80 <ftable>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	ec6080e7          	jalr	-314(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d26:	40dc                	lw	a5,4(s1)
    80004d28:	02f05263          	blez	a5,80004d4c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d2c:	2785                	addiw	a5,a5,1
    80004d2e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d30:	0001d517          	auipc	a0,0x1d
    80004d34:	f5050513          	addi	a0,a0,-176 # 80021c80 <ftable>
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	f72080e7          	jalr	-142(ra) # 80000caa <release>
  return f;
}
    80004d40:	8526                	mv	a0,s1
    80004d42:	60e2                	ld	ra,24(sp)
    80004d44:	6442                	ld	s0,16(sp)
    80004d46:	64a2                	ld	s1,8(sp)
    80004d48:	6105                	addi	sp,sp,32
    80004d4a:	8082                	ret
    panic("filedup");
    80004d4c:	00004517          	auipc	a0,0x4
    80004d50:	9ec50513          	addi	a0,a0,-1556 # 80008738 <syscalls+0x258>
    80004d54:	ffffb097          	auipc	ra,0xffffb
    80004d58:	7ea080e7          	jalr	2026(ra) # 8000053e <panic>

0000000080004d5c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d5c:	7139                	addi	sp,sp,-64
    80004d5e:	fc06                	sd	ra,56(sp)
    80004d60:	f822                	sd	s0,48(sp)
    80004d62:	f426                	sd	s1,40(sp)
    80004d64:	f04a                	sd	s2,32(sp)
    80004d66:	ec4e                	sd	s3,24(sp)
    80004d68:	e852                	sd	s4,16(sp)
    80004d6a:	e456                	sd	s5,8(sp)
    80004d6c:	0080                	addi	s0,sp,64
    80004d6e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d70:	0001d517          	auipc	a0,0x1d
    80004d74:	f1050513          	addi	a0,a0,-240 # 80021c80 <ftable>
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	e6c080e7          	jalr	-404(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d80:	40dc                	lw	a5,4(s1)
    80004d82:	06f05163          	blez	a5,80004de4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d86:	37fd                	addiw	a5,a5,-1
    80004d88:	0007871b          	sext.w	a4,a5
    80004d8c:	c0dc                	sw	a5,4(s1)
    80004d8e:	06e04363          	bgtz	a4,80004df4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d92:	0004a903          	lw	s2,0(s1)
    80004d96:	0094ca83          	lbu	s5,9(s1)
    80004d9a:	0104ba03          	ld	s4,16(s1)
    80004d9e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004da2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004da6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004daa:	0001d517          	auipc	a0,0x1d
    80004dae:	ed650513          	addi	a0,a0,-298 # 80021c80 <ftable>
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	ef8080e7          	jalr	-264(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004dba:	4785                	li	a5,1
    80004dbc:	04f90d63          	beq	s2,a5,80004e16 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004dc0:	3979                	addiw	s2,s2,-2
    80004dc2:	4785                	li	a5,1
    80004dc4:	0527e063          	bltu	a5,s2,80004e04 <fileclose+0xa8>
    begin_op();
    80004dc8:	00000097          	auipc	ra,0x0
    80004dcc:	ac8080e7          	jalr	-1336(ra) # 80004890 <begin_op>
    iput(ff.ip);
    80004dd0:	854e                	mv	a0,s3
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	2a6080e7          	jalr	678(ra) # 80004078 <iput>
    end_op();
    80004dda:	00000097          	auipc	ra,0x0
    80004dde:	b36080e7          	jalr	-1226(ra) # 80004910 <end_op>
    80004de2:	a00d                	j	80004e04 <fileclose+0xa8>
    panic("fileclose");
    80004de4:	00004517          	auipc	a0,0x4
    80004de8:	95c50513          	addi	a0,a0,-1700 # 80008740 <syscalls+0x260>
    80004dec:	ffffb097          	auipc	ra,0xffffb
    80004df0:	752080e7          	jalr	1874(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004df4:	0001d517          	auipc	a0,0x1d
    80004df8:	e8c50513          	addi	a0,a0,-372 # 80021c80 <ftable>
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	eae080e7          	jalr	-338(ra) # 80000caa <release>
  }
}
    80004e04:	70e2                	ld	ra,56(sp)
    80004e06:	7442                	ld	s0,48(sp)
    80004e08:	74a2                	ld	s1,40(sp)
    80004e0a:	7902                	ld	s2,32(sp)
    80004e0c:	69e2                	ld	s3,24(sp)
    80004e0e:	6a42                	ld	s4,16(sp)
    80004e10:	6aa2                	ld	s5,8(sp)
    80004e12:	6121                	addi	sp,sp,64
    80004e14:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e16:	85d6                	mv	a1,s5
    80004e18:	8552                	mv	a0,s4
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	34c080e7          	jalr	844(ra) # 80005166 <pipeclose>
    80004e22:	b7cd                	j	80004e04 <fileclose+0xa8>

0000000080004e24 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e24:	715d                	addi	sp,sp,-80
    80004e26:	e486                	sd	ra,72(sp)
    80004e28:	e0a2                	sd	s0,64(sp)
    80004e2a:	fc26                	sd	s1,56(sp)
    80004e2c:	f84a                	sd	s2,48(sp)
    80004e2e:	f44e                	sd	s3,40(sp)
    80004e30:	0880                	addi	s0,sp,80
    80004e32:	84aa                	mv	s1,a0
    80004e34:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	f8e080e7          	jalr	-114(ra) # 80001dc4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e3e:	409c                	lw	a5,0(s1)
    80004e40:	37f9                	addiw	a5,a5,-2
    80004e42:	4705                	li	a4,1
    80004e44:	04f76763          	bltu	a4,a5,80004e92 <filestat+0x6e>
    80004e48:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e4a:	6c88                	ld	a0,24(s1)
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	072080e7          	jalr	114(ra) # 80003ebe <ilock>
    stati(f->ip, &st);
    80004e54:	fb840593          	addi	a1,s0,-72
    80004e58:	6c88                	ld	a0,24(s1)
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	2ee080e7          	jalr	750(ra) # 80004148 <stati>
    iunlock(f->ip);
    80004e62:	6c88                	ld	a0,24(s1)
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	11c080e7          	jalr	284(ra) # 80003f80 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e6c:	46e1                	li	a3,24
    80004e6e:	fb840613          	addi	a2,s0,-72
    80004e72:	85ce                	mv	a1,s3
    80004e74:	07093503          	ld	a0,112(s2)
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	81e080e7          	jalr	-2018(ra) # 80001696 <copyout>
    80004e80:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e84:	60a6                	ld	ra,72(sp)
    80004e86:	6406                	ld	s0,64(sp)
    80004e88:	74e2                	ld	s1,56(sp)
    80004e8a:	7942                	ld	s2,48(sp)
    80004e8c:	79a2                	ld	s3,40(sp)
    80004e8e:	6161                	addi	sp,sp,80
    80004e90:	8082                	ret
  return -1;
    80004e92:	557d                	li	a0,-1
    80004e94:	bfc5                	j	80004e84 <filestat+0x60>

0000000080004e96 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e96:	7179                	addi	sp,sp,-48
    80004e98:	f406                	sd	ra,40(sp)
    80004e9a:	f022                	sd	s0,32(sp)
    80004e9c:	ec26                	sd	s1,24(sp)
    80004e9e:	e84a                	sd	s2,16(sp)
    80004ea0:	e44e                	sd	s3,8(sp)
    80004ea2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ea4:	00854783          	lbu	a5,8(a0)
    80004ea8:	c3d5                	beqz	a5,80004f4c <fileread+0xb6>
    80004eaa:	84aa                	mv	s1,a0
    80004eac:	89ae                	mv	s3,a1
    80004eae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004eb0:	411c                	lw	a5,0(a0)
    80004eb2:	4705                	li	a4,1
    80004eb4:	04e78963          	beq	a5,a4,80004f06 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eb8:	470d                	li	a4,3
    80004eba:	04e78d63          	beq	a5,a4,80004f14 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ebe:	4709                	li	a4,2
    80004ec0:	06e79e63          	bne	a5,a4,80004f3c <fileread+0xa6>
    ilock(f->ip);
    80004ec4:	6d08                	ld	a0,24(a0)
    80004ec6:	fffff097          	auipc	ra,0xfffff
    80004eca:	ff8080e7          	jalr	-8(ra) # 80003ebe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ece:	874a                	mv	a4,s2
    80004ed0:	5094                	lw	a3,32(s1)
    80004ed2:	864e                	mv	a2,s3
    80004ed4:	4585                	li	a1,1
    80004ed6:	6c88                	ld	a0,24(s1)
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	29a080e7          	jalr	666(ra) # 80004172 <readi>
    80004ee0:	892a                	mv	s2,a0
    80004ee2:	00a05563          	blez	a0,80004eec <fileread+0x56>
      f->off += r;
    80004ee6:	509c                	lw	a5,32(s1)
    80004ee8:	9fa9                	addw	a5,a5,a0
    80004eea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004eec:	6c88                	ld	a0,24(s1)
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	092080e7          	jalr	146(ra) # 80003f80 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ef6:	854a                	mv	a0,s2
    80004ef8:	70a2                	ld	ra,40(sp)
    80004efa:	7402                	ld	s0,32(sp)
    80004efc:	64e2                	ld	s1,24(sp)
    80004efe:	6942                	ld	s2,16(sp)
    80004f00:	69a2                	ld	s3,8(sp)
    80004f02:	6145                	addi	sp,sp,48
    80004f04:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f06:	6908                	ld	a0,16(a0)
    80004f08:	00000097          	auipc	ra,0x0
    80004f0c:	3c8080e7          	jalr	968(ra) # 800052d0 <piperead>
    80004f10:	892a                	mv	s2,a0
    80004f12:	b7d5                	j	80004ef6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f14:	02451783          	lh	a5,36(a0)
    80004f18:	03079693          	slli	a3,a5,0x30
    80004f1c:	92c1                	srli	a3,a3,0x30
    80004f1e:	4725                	li	a4,9
    80004f20:	02d76863          	bltu	a4,a3,80004f50 <fileread+0xba>
    80004f24:	0792                	slli	a5,a5,0x4
    80004f26:	0001d717          	auipc	a4,0x1d
    80004f2a:	cba70713          	addi	a4,a4,-838 # 80021be0 <devsw>
    80004f2e:	97ba                	add	a5,a5,a4
    80004f30:	639c                	ld	a5,0(a5)
    80004f32:	c38d                	beqz	a5,80004f54 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f34:	4505                	li	a0,1
    80004f36:	9782                	jalr	a5
    80004f38:	892a                	mv	s2,a0
    80004f3a:	bf75                	j	80004ef6 <fileread+0x60>
    panic("fileread");
    80004f3c:	00004517          	auipc	a0,0x4
    80004f40:	81450513          	addi	a0,a0,-2028 # 80008750 <syscalls+0x270>
    80004f44:	ffffb097          	auipc	ra,0xffffb
    80004f48:	5fa080e7          	jalr	1530(ra) # 8000053e <panic>
    return -1;
    80004f4c:	597d                	li	s2,-1
    80004f4e:	b765                	j	80004ef6 <fileread+0x60>
      return -1;
    80004f50:	597d                	li	s2,-1
    80004f52:	b755                	j	80004ef6 <fileread+0x60>
    80004f54:	597d                	li	s2,-1
    80004f56:	b745                	j	80004ef6 <fileread+0x60>

0000000080004f58 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f58:	715d                	addi	sp,sp,-80
    80004f5a:	e486                	sd	ra,72(sp)
    80004f5c:	e0a2                	sd	s0,64(sp)
    80004f5e:	fc26                	sd	s1,56(sp)
    80004f60:	f84a                	sd	s2,48(sp)
    80004f62:	f44e                	sd	s3,40(sp)
    80004f64:	f052                	sd	s4,32(sp)
    80004f66:	ec56                	sd	s5,24(sp)
    80004f68:	e85a                	sd	s6,16(sp)
    80004f6a:	e45e                	sd	s7,8(sp)
    80004f6c:	e062                	sd	s8,0(sp)
    80004f6e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f70:	00954783          	lbu	a5,9(a0)
    80004f74:	10078663          	beqz	a5,80005080 <filewrite+0x128>
    80004f78:	892a                	mv	s2,a0
    80004f7a:	8aae                	mv	s5,a1
    80004f7c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f7e:	411c                	lw	a5,0(a0)
    80004f80:	4705                	li	a4,1
    80004f82:	02e78263          	beq	a5,a4,80004fa6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f86:	470d                	li	a4,3
    80004f88:	02e78663          	beq	a5,a4,80004fb4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f8c:	4709                	li	a4,2
    80004f8e:	0ee79163          	bne	a5,a4,80005070 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f92:	0ac05d63          	blez	a2,8000504c <filewrite+0xf4>
    int i = 0;
    80004f96:	4981                	li	s3,0
    80004f98:	6b05                	lui	s6,0x1
    80004f9a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f9e:	6b85                	lui	s7,0x1
    80004fa0:	c00b8b9b          	addiw	s7,s7,-1024
    80004fa4:	a861                	j	8000503c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fa6:	6908                	ld	a0,16(a0)
    80004fa8:	00000097          	auipc	ra,0x0
    80004fac:	22e080e7          	jalr	558(ra) # 800051d6 <pipewrite>
    80004fb0:	8a2a                	mv	s4,a0
    80004fb2:	a045                	j	80005052 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fb4:	02451783          	lh	a5,36(a0)
    80004fb8:	03079693          	slli	a3,a5,0x30
    80004fbc:	92c1                	srli	a3,a3,0x30
    80004fbe:	4725                	li	a4,9
    80004fc0:	0cd76263          	bltu	a4,a3,80005084 <filewrite+0x12c>
    80004fc4:	0792                	slli	a5,a5,0x4
    80004fc6:	0001d717          	auipc	a4,0x1d
    80004fca:	c1a70713          	addi	a4,a4,-998 # 80021be0 <devsw>
    80004fce:	97ba                	add	a5,a5,a4
    80004fd0:	679c                	ld	a5,8(a5)
    80004fd2:	cbdd                	beqz	a5,80005088 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fd4:	4505                	li	a0,1
    80004fd6:	9782                	jalr	a5
    80004fd8:	8a2a                	mv	s4,a0
    80004fda:	a8a5                	j	80005052 <filewrite+0xfa>
    80004fdc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fe0:	00000097          	auipc	ra,0x0
    80004fe4:	8b0080e7          	jalr	-1872(ra) # 80004890 <begin_op>
      ilock(f->ip);
    80004fe8:	01893503          	ld	a0,24(s2)
    80004fec:	fffff097          	auipc	ra,0xfffff
    80004ff0:	ed2080e7          	jalr	-302(ra) # 80003ebe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ff4:	8762                	mv	a4,s8
    80004ff6:	02092683          	lw	a3,32(s2)
    80004ffa:	01598633          	add	a2,s3,s5
    80004ffe:	4585                	li	a1,1
    80005000:	01893503          	ld	a0,24(s2)
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	266080e7          	jalr	614(ra) # 8000426a <writei>
    8000500c:	84aa                	mv	s1,a0
    8000500e:	00a05763          	blez	a0,8000501c <filewrite+0xc4>
        f->off += r;
    80005012:	02092783          	lw	a5,32(s2)
    80005016:	9fa9                	addw	a5,a5,a0
    80005018:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000501c:	01893503          	ld	a0,24(s2)
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	f60080e7          	jalr	-160(ra) # 80003f80 <iunlock>
      end_op();
    80005028:	00000097          	auipc	ra,0x0
    8000502c:	8e8080e7          	jalr	-1816(ra) # 80004910 <end_op>

      if(r != n1){
    80005030:	009c1f63          	bne	s8,s1,8000504e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005034:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005038:	0149db63          	bge	s3,s4,8000504e <filewrite+0xf6>
      int n1 = n - i;
    8000503c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005040:	84be                	mv	s1,a5
    80005042:	2781                	sext.w	a5,a5
    80005044:	f8fb5ce3          	bge	s6,a5,80004fdc <filewrite+0x84>
    80005048:	84de                	mv	s1,s7
    8000504a:	bf49                	j	80004fdc <filewrite+0x84>
    int i = 0;
    8000504c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000504e:	013a1f63          	bne	s4,s3,8000506c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005052:	8552                	mv	a0,s4
    80005054:	60a6                	ld	ra,72(sp)
    80005056:	6406                	ld	s0,64(sp)
    80005058:	74e2                	ld	s1,56(sp)
    8000505a:	7942                	ld	s2,48(sp)
    8000505c:	79a2                	ld	s3,40(sp)
    8000505e:	7a02                	ld	s4,32(sp)
    80005060:	6ae2                	ld	s5,24(sp)
    80005062:	6b42                	ld	s6,16(sp)
    80005064:	6ba2                	ld	s7,8(sp)
    80005066:	6c02                	ld	s8,0(sp)
    80005068:	6161                	addi	sp,sp,80
    8000506a:	8082                	ret
    ret = (i == n ? n : -1);
    8000506c:	5a7d                	li	s4,-1
    8000506e:	b7d5                	j	80005052 <filewrite+0xfa>
    panic("filewrite");
    80005070:	00003517          	auipc	a0,0x3
    80005074:	6f050513          	addi	a0,a0,1776 # 80008760 <syscalls+0x280>
    80005078:	ffffb097          	auipc	ra,0xffffb
    8000507c:	4c6080e7          	jalr	1222(ra) # 8000053e <panic>
    return -1;
    80005080:	5a7d                	li	s4,-1
    80005082:	bfc1                	j	80005052 <filewrite+0xfa>
      return -1;
    80005084:	5a7d                	li	s4,-1
    80005086:	b7f1                	j	80005052 <filewrite+0xfa>
    80005088:	5a7d                	li	s4,-1
    8000508a:	b7e1                	j	80005052 <filewrite+0xfa>

000000008000508c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000508c:	7179                	addi	sp,sp,-48
    8000508e:	f406                	sd	ra,40(sp)
    80005090:	f022                	sd	s0,32(sp)
    80005092:	ec26                	sd	s1,24(sp)
    80005094:	e84a                	sd	s2,16(sp)
    80005096:	e44e                	sd	s3,8(sp)
    80005098:	e052                	sd	s4,0(sp)
    8000509a:	1800                	addi	s0,sp,48
    8000509c:	84aa                	mv	s1,a0
    8000509e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050a0:	0005b023          	sd	zero,0(a1)
    800050a4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050a8:	00000097          	auipc	ra,0x0
    800050ac:	bf8080e7          	jalr	-1032(ra) # 80004ca0 <filealloc>
    800050b0:	e088                	sd	a0,0(s1)
    800050b2:	c551                	beqz	a0,8000513e <pipealloc+0xb2>
    800050b4:	00000097          	auipc	ra,0x0
    800050b8:	bec080e7          	jalr	-1044(ra) # 80004ca0 <filealloc>
    800050bc:	00aa3023          	sd	a0,0(s4)
    800050c0:	c92d                	beqz	a0,80005132 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	a32080e7          	jalr	-1486(ra) # 80000af4 <kalloc>
    800050ca:	892a                	mv	s2,a0
    800050cc:	c125                	beqz	a0,8000512c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050ce:	4985                	li	s3,1
    800050d0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050d4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050d8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050dc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050e0:	00003597          	auipc	a1,0x3
    800050e4:	69058593          	addi	a1,a1,1680 # 80008770 <syscalls+0x290>
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	a6c080e7          	jalr	-1428(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800050f0:	609c                	ld	a5,0(s1)
    800050f2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050f6:	609c                	ld	a5,0(s1)
    800050f8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050fc:	609c                	ld	a5,0(s1)
    800050fe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005102:	609c                	ld	a5,0(s1)
    80005104:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005108:	000a3783          	ld	a5,0(s4)
    8000510c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005110:	000a3783          	ld	a5,0(s4)
    80005114:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005118:	000a3783          	ld	a5,0(s4)
    8000511c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005120:	000a3783          	ld	a5,0(s4)
    80005124:	0127b823          	sd	s2,16(a5)
  return 0;
    80005128:	4501                	li	a0,0
    8000512a:	a025                	j	80005152 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000512c:	6088                	ld	a0,0(s1)
    8000512e:	e501                	bnez	a0,80005136 <pipealloc+0xaa>
    80005130:	a039                	j	8000513e <pipealloc+0xb2>
    80005132:	6088                	ld	a0,0(s1)
    80005134:	c51d                	beqz	a0,80005162 <pipealloc+0xd6>
    fileclose(*f0);
    80005136:	00000097          	auipc	ra,0x0
    8000513a:	c26080e7          	jalr	-986(ra) # 80004d5c <fileclose>
  if(*f1)
    8000513e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005142:	557d                	li	a0,-1
  if(*f1)
    80005144:	c799                	beqz	a5,80005152 <pipealloc+0xc6>
    fileclose(*f1);
    80005146:	853e                	mv	a0,a5
    80005148:	00000097          	auipc	ra,0x0
    8000514c:	c14080e7          	jalr	-1004(ra) # 80004d5c <fileclose>
  return -1;
    80005150:	557d                	li	a0,-1
}
    80005152:	70a2                	ld	ra,40(sp)
    80005154:	7402                	ld	s0,32(sp)
    80005156:	64e2                	ld	s1,24(sp)
    80005158:	6942                	ld	s2,16(sp)
    8000515a:	69a2                	ld	s3,8(sp)
    8000515c:	6a02                	ld	s4,0(sp)
    8000515e:	6145                	addi	sp,sp,48
    80005160:	8082                	ret
  return -1;
    80005162:	557d                	li	a0,-1
    80005164:	b7fd                	j	80005152 <pipealloc+0xc6>

0000000080005166 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005166:	1101                	addi	sp,sp,-32
    80005168:	ec06                	sd	ra,24(sp)
    8000516a:	e822                	sd	s0,16(sp)
    8000516c:	e426                	sd	s1,8(sp)
    8000516e:	e04a                	sd	s2,0(sp)
    80005170:	1000                	addi	s0,sp,32
    80005172:	84aa                	mv	s1,a0
    80005174:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005176:	ffffc097          	auipc	ra,0xffffc
    8000517a:	a6e080e7          	jalr	-1426(ra) # 80000be4 <acquire>
  if(writable){
    8000517e:	02090d63          	beqz	s2,800051b8 <pipeclose+0x52>
    pi->writeopen = 0;
    80005182:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005186:	21848513          	addi	a0,s1,536
    8000518a:	ffffd097          	auipc	ra,0xffffd
    8000518e:	6da080e7          	jalr	1754(ra) # 80002864 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005192:	2204b783          	ld	a5,544(s1)
    80005196:	eb95                	bnez	a5,800051ca <pipeclose+0x64>
    release(&pi->lock);
    80005198:	8526                	mv	a0,s1
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	b10080e7          	jalr	-1264(ra) # 80000caa <release>
    kfree((char*)pi);
    800051a2:	8526                	mv	a0,s1
    800051a4:	ffffc097          	auipc	ra,0xffffc
    800051a8:	854080e7          	jalr	-1964(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800051ac:	60e2                	ld	ra,24(sp)
    800051ae:	6442                	ld	s0,16(sp)
    800051b0:	64a2                	ld	s1,8(sp)
    800051b2:	6902                	ld	s2,0(sp)
    800051b4:	6105                	addi	sp,sp,32
    800051b6:	8082                	ret
    pi->readopen = 0;
    800051b8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051bc:	21c48513          	addi	a0,s1,540
    800051c0:	ffffd097          	auipc	ra,0xffffd
    800051c4:	6a4080e7          	jalr	1700(ra) # 80002864 <wakeup>
    800051c8:	b7e9                	j	80005192 <pipeclose+0x2c>
    release(&pi->lock);
    800051ca:	8526                	mv	a0,s1
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	ade080e7          	jalr	-1314(ra) # 80000caa <release>
}
    800051d4:	bfe1                	j	800051ac <pipeclose+0x46>

00000000800051d6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051d6:	7159                	addi	sp,sp,-112
    800051d8:	f486                	sd	ra,104(sp)
    800051da:	f0a2                	sd	s0,96(sp)
    800051dc:	eca6                	sd	s1,88(sp)
    800051de:	e8ca                	sd	s2,80(sp)
    800051e0:	e4ce                	sd	s3,72(sp)
    800051e2:	e0d2                	sd	s4,64(sp)
    800051e4:	fc56                	sd	s5,56(sp)
    800051e6:	f85a                	sd	s6,48(sp)
    800051e8:	f45e                	sd	s7,40(sp)
    800051ea:	f062                	sd	s8,32(sp)
    800051ec:	ec66                	sd	s9,24(sp)
    800051ee:	1880                	addi	s0,sp,112
    800051f0:	84aa                	mv	s1,a0
    800051f2:	8aae                	mv	s5,a1
    800051f4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051f6:	ffffd097          	auipc	ra,0xffffd
    800051fa:	bce080e7          	jalr	-1074(ra) # 80001dc4 <myproc>
    800051fe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005200:	8526                	mv	a0,s1
    80005202:	ffffc097          	auipc	ra,0xffffc
    80005206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
  while(i < n){
    8000520a:	0d405163          	blez	s4,800052cc <pipewrite+0xf6>
    8000520e:	8ba6                	mv	s7,s1
  int i = 0;
    80005210:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005212:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005214:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005218:	21c48c13          	addi	s8,s1,540
    8000521c:	a08d                	j	8000527e <pipewrite+0xa8>
      release(&pi->lock);
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	a8a080e7          	jalr	-1398(ra) # 80000caa <release>
      return -1;
    80005228:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000522a:	854a                	mv	a0,s2
    8000522c:	70a6                	ld	ra,104(sp)
    8000522e:	7406                	ld	s0,96(sp)
    80005230:	64e6                	ld	s1,88(sp)
    80005232:	6946                	ld	s2,80(sp)
    80005234:	69a6                	ld	s3,72(sp)
    80005236:	6a06                	ld	s4,64(sp)
    80005238:	7ae2                	ld	s5,56(sp)
    8000523a:	7b42                	ld	s6,48(sp)
    8000523c:	7ba2                	ld	s7,40(sp)
    8000523e:	7c02                	ld	s8,32(sp)
    80005240:	6ce2                	ld	s9,24(sp)
    80005242:	6165                	addi	sp,sp,112
    80005244:	8082                	ret
      wakeup(&pi->nread);
    80005246:	8566                	mv	a0,s9
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	61c080e7          	jalr	1564(ra) # 80002864 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005250:	85de                	mv	a1,s7
    80005252:	8562                	mv	a0,s8
    80005254:	ffffd097          	auipc	ra,0xffffd
    80005258:	458080e7          	jalr	1112(ra) # 800026ac <sleep>
    8000525c:	a839                	j	8000527a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000525e:	21c4a783          	lw	a5,540(s1)
    80005262:	0017871b          	addiw	a4,a5,1
    80005266:	20e4ae23          	sw	a4,540(s1)
    8000526a:	1ff7f793          	andi	a5,a5,511
    8000526e:	97a6                	add	a5,a5,s1
    80005270:	f9f44703          	lbu	a4,-97(s0)
    80005274:	00e78c23          	sb	a4,24(a5)
      i++;
    80005278:	2905                	addiw	s2,s2,1
  while(i < n){
    8000527a:	03495d63          	bge	s2,s4,800052b4 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000527e:	2204a783          	lw	a5,544(s1)
    80005282:	dfd1                	beqz	a5,8000521e <pipewrite+0x48>
    80005284:	0289a783          	lw	a5,40(s3)
    80005288:	fbd9                	bnez	a5,8000521e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000528a:	2184a783          	lw	a5,536(s1)
    8000528e:	21c4a703          	lw	a4,540(s1)
    80005292:	2007879b          	addiw	a5,a5,512
    80005296:	faf708e3          	beq	a4,a5,80005246 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000529a:	4685                	li	a3,1
    8000529c:	01590633          	add	a2,s2,s5
    800052a0:	f9f40593          	addi	a1,s0,-97
    800052a4:	0709b503          	ld	a0,112(s3)
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	47a080e7          	jalr	1146(ra) # 80001722 <copyin>
    800052b0:	fb6517e3          	bne	a0,s6,8000525e <pipewrite+0x88>
  wakeup(&pi->nread);
    800052b4:	21848513          	addi	a0,s1,536
    800052b8:	ffffd097          	auipc	ra,0xffffd
    800052bc:	5ac080e7          	jalr	1452(ra) # 80002864 <wakeup>
  release(&pi->lock);
    800052c0:	8526                	mv	a0,s1
    800052c2:	ffffc097          	auipc	ra,0xffffc
    800052c6:	9e8080e7          	jalr	-1560(ra) # 80000caa <release>
  return i;
    800052ca:	b785                	j	8000522a <pipewrite+0x54>
  int i = 0;
    800052cc:	4901                	li	s2,0
    800052ce:	b7dd                	j	800052b4 <pipewrite+0xde>

00000000800052d0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052d0:	715d                	addi	sp,sp,-80
    800052d2:	e486                	sd	ra,72(sp)
    800052d4:	e0a2                	sd	s0,64(sp)
    800052d6:	fc26                	sd	s1,56(sp)
    800052d8:	f84a                	sd	s2,48(sp)
    800052da:	f44e                	sd	s3,40(sp)
    800052dc:	f052                	sd	s4,32(sp)
    800052de:	ec56                	sd	s5,24(sp)
    800052e0:	e85a                	sd	s6,16(sp)
    800052e2:	0880                	addi	s0,sp,80
    800052e4:	84aa                	mv	s1,a0
    800052e6:	892e                	mv	s2,a1
    800052e8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052ea:	ffffd097          	auipc	ra,0xffffd
    800052ee:	ada080e7          	jalr	-1318(ra) # 80001dc4 <myproc>
    800052f2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052f4:	8b26                	mv	s6,s1
    800052f6:	8526                	mv	a0,s1
    800052f8:	ffffc097          	auipc	ra,0xffffc
    800052fc:	8ec080e7          	jalr	-1812(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005300:	2184a703          	lw	a4,536(s1)
    80005304:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005308:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000530c:	02f71463          	bne	a4,a5,80005334 <piperead+0x64>
    80005310:	2244a783          	lw	a5,548(s1)
    80005314:	c385                	beqz	a5,80005334 <piperead+0x64>
    if(pr->killed){
    80005316:	028a2783          	lw	a5,40(s4)
    8000531a:	ebc1                	bnez	a5,800053aa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000531c:	85da                	mv	a1,s6
    8000531e:	854e                	mv	a0,s3
    80005320:	ffffd097          	auipc	ra,0xffffd
    80005324:	38c080e7          	jalr	908(ra) # 800026ac <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005328:	2184a703          	lw	a4,536(s1)
    8000532c:	21c4a783          	lw	a5,540(s1)
    80005330:	fef700e3          	beq	a4,a5,80005310 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005334:	09505263          	blez	s5,800053b8 <piperead+0xe8>
    80005338:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000533a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000533c:	2184a783          	lw	a5,536(s1)
    80005340:	21c4a703          	lw	a4,540(s1)
    80005344:	02f70d63          	beq	a4,a5,8000537e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005348:	0017871b          	addiw	a4,a5,1
    8000534c:	20e4ac23          	sw	a4,536(s1)
    80005350:	1ff7f793          	andi	a5,a5,511
    80005354:	97a6                	add	a5,a5,s1
    80005356:	0187c783          	lbu	a5,24(a5)
    8000535a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000535e:	4685                	li	a3,1
    80005360:	fbf40613          	addi	a2,s0,-65
    80005364:	85ca                	mv	a1,s2
    80005366:	070a3503          	ld	a0,112(s4)
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	32c080e7          	jalr	812(ra) # 80001696 <copyout>
    80005372:	01650663          	beq	a0,s6,8000537e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005376:	2985                	addiw	s3,s3,1
    80005378:	0905                	addi	s2,s2,1
    8000537a:	fd3a91e3          	bne	s5,s3,8000533c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000537e:	21c48513          	addi	a0,s1,540
    80005382:	ffffd097          	auipc	ra,0xffffd
    80005386:	4e2080e7          	jalr	1250(ra) # 80002864 <wakeup>
  release(&pi->lock);
    8000538a:	8526                	mv	a0,s1
    8000538c:	ffffc097          	auipc	ra,0xffffc
    80005390:	91e080e7          	jalr	-1762(ra) # 80000caa <release>
  return i;
}
    80005394:	854e                	mv	a0,s3
    80005396:	60a6                	ld	ra,72(sp)
    80005398:	6406                	ld	s0,64(sp)
    8000539a:	74e2                	ld	s1,56(sp)
    8000539c:	7942                	ld	s2,48(sp)
    8000539e:	79a2                	ld	s3,40(sp)
    800053a0:	7a02                	ld	s4,32(sp)
    800053a2:	6ae2                	ld	s5,24(sp)
    800053a4:	6b42                	ld	s6,16(sp)
    800053a6:	6161                	addi	sp,sp,80
    800053a8:	8082                	ret
      release(&pi->lock);
    800053aa:	8526                	mv	a0,s1
    800053ac:	ffffc097          	auipc	ra,0xffffc
    800053b0:	8fe080e7          	jalr	-1794(ra) # 80000caa <release>
      return -1;
    800053b4:	59fd                	li	s3,-1
    800053b6:	bff9                	j	80005394 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053b8:	4981                	li	s3,0
    800053ba:	b7d1                	j	8000537e <piperead+0xae>

00000000800053bc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053bc:	df010113          	addi	sp,sp,-528
    800053c0:	20113423          	sd	ra,520(sp)
    800053c4:	20813023          	sd	s0,512(sp)
    800053c8:	ffa6                	sd	s1,504(sp)
    800053ca:	fbca                	sd	s2,496(sp)
    800053cc:	f7ce                	sd	s3,488(sp)
    800053ce:	f3d2                	sd	s4,480(sp)
    800053d0:	efd6                	sd	s5,472(sp)
    800053d2:	ebda                	sd	s6,464(sp)
    800053d4:	e7de                	sd	s7,456(sp)
    800053d6:	e3e2                	sd	s8,448(sp)
    800053d8:	ff66                	sd	s9,440(sp)
    800053da:	fb6a                	sd	s10,432(sp)
    800053dc:	f76e                	sd	s11,424(sp)
    800053de:	0c00                	addi	s0,sp,528
    800053e0:	84aa                	mv	s1,a0
    800053e2:	dea43c23          	sd	a0,-520(s0)
    800053e6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053ea:	ffffd097          	auipc	ra,0xffffd
    800053ee:	9da080e7          	jalr	-1574(ra) # 80001dc4 <myproc>
    800053f2:	892a                	mv	s2,a0

  begin_op();
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	49c080e7          	jalr	1180(ra) # 80004890 <begin_op>

  if((ip = namei(path)) == 0){
    800053fc:	8526                	mv	a0,s1
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	276080e7          	jalr	630(ra) # 80004674 <namei>
    80005406:	c92d                	beqz	a0,80005478 <exec+0xbc>
    80005408:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	ab4080e7          	jalr	-1356(ra) # 80003ebe <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005412:	04000713          	li	a4,64
    80005416:	4681                	li	a3,0
    80005418:	e5040613          	addi	a2,s0,-432
    8000541c:	4581                	li	a1,0
    8000541e:	8526                	mv	a0,s1
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	d52080e7          	jalr	-686(ra) # 80004172 <readi>
    80005428:	04000793          	li	a5,64
    8000542c:	00f51a63          	bne	a0,a5,80005440 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005430:	e5042703          	lw	a4,-432(s0)
    80005434:	464c47b7          	lui	a5,0x464c4
    80005438:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000543c:	04f70463          	beq	a4,a5,80005484 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005440:	8526                	mv	a0,s1
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	cde080e7          	jalr	-802(ra) # 80004120 <iunlockput>
    end_op();
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	4c6080e7          	jalr	1222(ra) # 80004910 <end_op>
  }
  return -1;
    80005452:	557d                	li	a0,-1
}
    80005454:	20813083          	ld	ra,520(sp)
    80005458:	20013403          	ld	s0,512(sp)
    8000545c:	74fe                	ld	s1,504(sp)
    8000545e:	795e                	ld	s2,496(sp)
    80005460:	79be                	ld	s3,488(sp)
    80005462:	7a1e                	ld	s4,480(sp)
    80005464:	6afe                	ld	s5,472(sp)
    80005466:	6b5e                	ld	s6,464(sp)
    80005468:	6bbe                	ld	s7,456(sp)
    8000546a:	6c1e                	ld	s8,448(sp)
    8000546c:	7cfa                	ld	s9,440(sp)
    8000546e:	7d5a                	ld	s10,432(sp)
    80005470:	7dba                	ld	s11,424(sp)
    80005472:	21010113          	addi	sp,sp,528
    80005476:	8082                	ret
    end_op();
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	498080e7          	jalr	1176(ra) # 80004910 <end_op>
    return -1;
    80005480:	557d                	li	a0,-1
    80005482:	bfc9                	j	80005454 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005484:	854a                	mv	a0,s2
    80005486:	ffffd097          	auipc	ra,0xffffd
    8000548a:	a4e080e7          	jalr	-1458(ra) # 80001ed4 <proc_pagetable>
    8000548e:	8baa                	mv	s7,a0
    80005490:	d945                	beqz	a0,80005440 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005492:	e7042983          	lw	s3,-400(s0)
    80005496:	e8845783          	lhu	a5,-376(s0)
    8000549a:	c7ad                	beqz	a5,80005504 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000549c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000549e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800054a0:	6c85                	lui	s9,0x1
    800054a2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800054a6:	def43823          	sd	a5,-528(s0)
    800054aa:	a42d                	j	800056d4 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054ac:	00003517          	auipc	a0,0x3
    800054b0:	2cc50513          	addi	a0,a0,716 # 80008778 <syscalls+0x298>
    800054b4:	ffffb097          	auipc	ra,0xffffb
    800054b8:	08a080e7          	jalr	138(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054bc:	8756                	mv	a4,s5
    800054be:	012d86bb          	addw	a3,s11,s2
    800054c2:	4581                	li	a1,0
    800054c4:	8526                	mv	a0,s1
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	cac080e7          	jalr	-852(ra) # 80004172 <readi>
    800054ce:	2501                	sext.w	a0,a0
    800054d0:	1aaa9963          	bne	s5,a0,80005682 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800054d4:	6785                	lui	a5,0x1
    800054d6:	0127893b          	addw	s2,a5,s2
    800054da:	77fd                	lui	a5,0xfffff
    800054dc:	01478a3b          	addw	s4,a5,s4
    800054e0:	1f897163          	bgeu	s2,s8,800056c2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800054e4:	02091593          	slli	a1,s2,0x20
    800054e8:	9181                	srli	a1,a1,0x20
    800054ea:	95ea                	add	a1,a1,s10
    800054ec:	855e                	mv	a0,s7
    800054ee:	ffffc097          	auipc	ra,0xffffc
    800054f2:	ba4080e7          	jalr	-1116(ra) # 80001092 <walkaddr>
    800054f6:	862a                	mv	a2,a0
    if(pa == 0)
    800054f8:	d955                	beqz	a0,800054ac <exec+0xf0>
      n = PGSIZE;
    800054fa:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800054fc:	fd9a70e3          	bgeu	s4,s9,800054bc <exec+0x100>
      n = sz - i;
    80005500:	8ad2                	mv	s5,s4
    80005502:	bf6d                	j	800054bc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005504:	4901                	li	s2,0
  iunlockput(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	c18080e7          	jalr	-1000(ra) # 80004120 <iunlockput>
  end_op();
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	400080e7          	jalr	1024(ra) # 80004910 <end_op>
  p = myproc();
    80005518:	ffffd097          	auipc	ra,0xffffd
    8000551c:	8ac080e7          	jalr	-1876(ra) # 80001dc4 <myproc>
    80005520:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005522:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005526:	6785                	lui	a5,0x1
    80005528:	17fd                	addi	a5,a5,-1
    8000552a:	993e                	add	s2,s2,a5
    8000552c:	757d                	lui	a0,0xfffff
    8000552e:	00a977b3          	and	a5,s2,a0
    80005532:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005536:	6609                	lui	a2,0x2
    80005538:	963e                	add	a2,a2,a5
    8000553a:	85be                	mv	a1,a5
    8000553c:	855e                	mv	a0,s7
    8000553e:	ffffc097          	auipc	ra,0xffffc
    80005542:	f08080e7          	jalr	-248(ra) # 80001446 <uvmalloc>
    80005546:	8b2a                	mv	s6,a0
  ip = 0;
    80005548:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000554a:	12050c63          	beqz	a0,80005682 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000554e:	75f9                	lui	a1,0xffffe
    80005550:	95aa                	add	a1,a1,a0
    80005552:	855e                	mv	a0,s7
    80005554:	ffffc097          	auipc	ra,0xffffc
    80005558:	110080e7          	jalr	272(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    8000555c:	7c7d                	lui	s8,0xfffff
    8000555e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005560:	e0043783          	ld	a5,-512(s0)
    80005564:	6388                	ld	a0,0(a5)
    80005566:	c535                	beqz	a0,800055d2 <exec+0x216>
    80005568:	e9040993          	addi	s3,s0,-368
    8000556c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005570:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005572:	ffffc097          	auipc	ra,0xffffc
    80005576:	916080e7          	jalr	-1770(ra) # 80000e88 <strlen>
    8000557a:	2505                	addiw	a0,a0,1
    8000557c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005580:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005584:	13896363          	bltu	s2,s8,800056aa <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005588:	e0043d83          	ld	s11,-512(s0)
    8000558c:	000dba03          	ld	s4,0(s11)
    80005590:	8552                	mv	a0,s4
    80005592:	ffffc097          	auipc	ra,0xffffc
    80005596:	8f6080e7          	jalr	-1802(ra) # 80000e88 <strlen>
    8000559a:	0015069b          	addiw	a3,a0,1
    8000559e:	8652                	mv	a2,s4
    800055a0:	85ca                	mv	a1,s2
    800055a2:	855e                	mv	a0,s7
    800055a4:	ffffc097          	auipc	ra,0xffffc
    800055a8:	0f2080e7          	jalr	242(ra) # 80001696 <copyout>
    800055ac:	10054363          	bltz	a0,800056b2 <exec+0x2f6>
    ustack[argc] = sp;
    800055b0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055b4:	0485                	addi	s1,s1,1
    800055b6:	008d8793          	addi	a5,s11,8
    800055ba:	e0f43023          	sd	a5,-512(s0)
    800055be:	008db503          	ld	a0,8(s11)
    800055c2:	c911                	beqz	a0,800055d6 <exec+0x21a>
    if(argc >= MAXARG)
    800055c4:	09a1                	addi	s3,s3,8
    800055c6:	fb3c96e3          	bne	s9,s3,80005572 <exec+0x1b6>
  sz = sz1;
    800055ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055ce:	4481                	li	s1,0
    800055d0:	a84d                	j	80005682 <exec+0x2c6>
  sp = sz;
    800055d2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800055d4:	4481                	li	s1,0
  ustack[argc] = 0;
    800055d6:	00349793          	slli	a5,s1,0x3
    800055da:	f9040713          	addi	a4,s0,-112
    800055de:	97ba                	add	a5,a5,a4
    800055e0:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800055e4:	00148693          	addi	a3,s1,1
    800055e8:	068e                	slli	a3,a3,0x3
    800055ea:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055ee:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800055f2:	01897663          	bgeu	s2,s8,800055fe <exec+0x242>
  sz = sz1;
    800055f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055fa:	4481                	li	s1,0
    800055fc:	a059                	j	80005682 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055fe:	e9040613          	addi	a2,s0,-368
    80005602:	85ca                	mv	a1,s2
    80005604:	855e                	mv	a0,s7
    80005606:	ffffc097          	auipc	ra,0xffffc
    8000560a:	090080e7          	jalr	144(ra) # 80001696 <copyout>
    8000560e:	0a054663          	bltz	a0,800056ba <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005612:	078ab783          	ld	a5,120(s5)
    80005616:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000561a:	df843783          	ld	a5,-520(s0)
    8000561e:	0007c703          	lbu	a4,0(a5)
    80005622:	cf11                	beqz	a4,8000563e <exec+0x282>
    80005624:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005626:	02f00693          	li	a3,47
    8000562a:	a039                	j	80005638 <exec+0x27c>
      last = s+1;
    8000562c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005630:	0785                	addi	a5,a5,1
    80005632:	fff7c703          	lbu	a4,-1(a5)
    80005636:	c701                	beqz	a4,8000563e <exec+0x282>
    if(*s == '/')
    80005638:	fed71ce3          	bne	a4,a3,80005630 <exec+0x274>
    8000563c:	bfc5                	j	8000562c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000563e:	4641                	li	a2,16
    80005640:	df843583          	ld	a1,-520(s0)
    80005644:	178a8513          	addi	a0,s5,376
    80005648:	ffffc097          	auipc	ra,0xffffc
    8000564c:	80e080e7          	jalr	-2034(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    80005650:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005654:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005658:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000565c:	078ab783          	ld	a5,120(s5)
    80005660:	e6843703          	ld	a4,-408(s0)
    80005664:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005666:	078ab783          	ld	a5,120(s5)
    8000566a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000566e:	85ea                	mv	a1,s10
    80005670:	ffffd097          	auipc	ra,0xffffd
    80005674:	900080e7          	jalr	-1792(ra) # 80001f70 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005678:	0004851b          	sext.w	a0,s1
    8000567c:	bbe1                	j	80005454 <exec+0x98>
    8000567e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005682:	e0843583          	ld	a1,-504(s0)
    80005686:	855e                	mv	a0,s7
    80005688:	ffffd097          	auipc	ra,0xffffd
    8000568c:	8e8080e7          	jalr	-1816(ra) # 80001f70 <proc_freepagetable>
  if(ip){
    80005690:	da0498e3          	bnez	s1,80005440 <exec+0x84>
  return -1;
    80005694:	557d                	li	a0,-1
    80005696:	bb7d                	j	80005454 <exec+0x98>
    80005698:	e1243423          	sd	s2,-504(s0)
    8000569c:	b7dd                	j	80005682 <exec+0x2c6>
    8000569e:	e1243423          	sd	s2,-504(s0)
    800056a2:	b7c5                	j	80005682 <exec+0x2c6>
    800056a4:	e1243423          	sd	s2,-504(s0)
    800056a8:	bfe9                	j	80005682 <exec+0x2c6>
  sz = sz1;
    800056aa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056ae:	4481                	li	s1,0
    800056b0:	bfc9                	j	80005682 <exec+0x2c6>
  sz = sz1;
    800056b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056b6:	4481                	li	s1,0
    800056b8:	b7e9                	j	80005682 <exec+0x2c6>
  sz = sz1;
    800056ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056be:	4481                	li	s1,0
    800056c0:	b7c9                	j	80005682 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056c2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056c6:	2b05                	addiw	s6,s6,1
    800056c8:	0389899b          	addiw	s3,s3,56
    800056cc:	e8845783          	lhu	a5,-376(s0)
    800056d0:	e2fb5be3          	bge	s6,a5,80005506 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056d4:	2981                	sext.w	s3,s3
    800056d6:	03800713          	li	a4,56
    800056da:	86ce                	mv	a3,s3
    800056dc:	e1840613          	addi	a2,s0,-488
    800056e0:	4581                	li	a1,0
    800056e2:	8526                	mv	a0,s1
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	a8e080e7          	jalr	-1394(ra) # 80004172 <readi>
    800056ec:	03800793          	li	a5,56
    800056f0:	f8f517e3          	bne	a0,a5,8000567e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800056f4:	e1842783          	lw	a5,-488(s0)
    800056f8:	4705                	li	a4,1
    800056fa:	fce796e3          	bne	a5,a4,800056c6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800056fe:	e4043603          	ld	a2,-448(s0)
    80005702:	e3843783          	ld	a5,-456(s0)
    80005706:	f8f669e3          	bltu	a2,a5,80005698 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000570a:	e2843783          	ld	a5,-472(s0)
    8000570e:	963e                	add	a2,a2,a5
    80005710:	f8f667e3          	bltu	a2,a5,8000569e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005714:	85ca                	mv	a1,s2
    80005716:	855e                	mv	a0,s7
    80005718:	ffffc097          	auipc	ra,0xffffc
    8000571c:	d2e080e7          	jalr	-722(ra) # 80001446 <uvmalloc>
    80005720:	e0a43423          	sd	a0,-504(s0)
    80005724:	d141                	beqz	a0,800056a4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005726:	e2843d03          	ld	s10,-472(s0)
    8000572a:	df043783          	ld	a5,-528(s0)
    8000572e:	00fd77b3          	and	a5,s10,a5
    80005732:	fba1                	bnez	a5,80005682 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005734:	e2042d83          	lw	s11,-480(s0)
    80005738:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000573c:	f80c03e3          	beqz	s8,800056c2 <exec+0x306>
    80005740:	8a62                	mv	s4,s8
    80005742:	4901                	li	s2,0
    80005744:	b345                	j	800054e4 <exec+0x128>

0000000080005746 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005746:	7179                	addi	sp,sp,-48
    80005748:	f406                	sd	ra,40(sp)
    8000574a:	f022                	sd	s0,32(sp)
    8000574c:	ec26                	sd	s1,24(sp)
    8000574e:	e84a                	sd	s2,16(sp)
    80005750:	1800                	addi	s0,sp,48
    80005752:	892e                	mv	s2,a1
    80005754:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005756:	fdc40593          	addi	a1,s0,-36
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	b76080e7          	jalr	-1162(ra) # 800032d0 <argint>
    80005762:	04054063          	bltz	a0,800057a2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005766:	fdc42703          	lw	a4,-36(s0)
    8000576a:	47bd                	li	a5,15
    8000576c:	02e7ed63          	bltu	a5,a4,800057a6 <argfd+0x60>
    80005770:	ffffc097          	auipc	ra,0xffffc
    80005774:	654080e7          	jalr	1620(ra) # 80001dc4 <myproc>
    80005778:	fdc42703          	lw	a4,-36(s0)
    8000577c:	01e70793          	addi	a5,a4,30
    80005780:	078e                	slli	a5,a5,0x3
    80005782:	953e                	add	a0,a0,a5
    80005784:	611c                	ld	a5,0(a0)
    80005786:	c395                	beqz	a5,800057aa <argfd+0x64>
    return -1;
  if(pfd)
    80005788:	00090463          	beqz	s2,80005790 <argfd+0x4a>
    *pfd = fd;
    8000578c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005790:	4501                	li	a0,0
  if(pf)
    80005792:	c091                	beqz	s1,80005796 <argfd+0x50>
    *pf = f;
    80005794:	e09c                	sd	a5,0(s1)
}
    80005796:	70a2                	ld	ra,40(sp)
    80005798:	7402                	ld	s0,32(sp)
    8000579a:	64e2                	ld	s1,24(sp)
    8000579c:	6942                	ld	s2,16(sp)
    8000579e:	6145                	addi	sp,sp,48
    800057a0:	8082                	ret
    return -1;
    800057a2:	557d                	li	a0,-1
    800057a4:	bfcd                	j	80005796 <argfd+0x50>
    return -1;
    800057a6:	557d                	li	a0,-1
    800057a8:	b7fd                	j	80005796 <argfd+0x50>
    800057aa:	557d                	li	a0,-1
    800057ac:	b7ed                	j	80005796 <argfd+0x50>

00000000800057ae <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057ae:	1101                	addi	sp,sp,-32
    800057b0:	ec06                	sd	ra,24(sp)
    800057b2:	e822                	sd	s0,16(sp)
    800057b4:	e426                	sd	s1,8(sp)
    800057b6:	1000                	addi	s0,sp,32
    800057b8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057ba:	ffffc097          	auipc	ra,0xffffc
    800057be:	60a080e7          	jalr	1546(ra) # 80001dc4 <myproc>
    800057c2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057c4:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    800057c8:	4501                	li	a0,0
    800057ca:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057cc:	6398                	ld	a4,0(a5)
    800057ce:	cb19                	beqz	a4,800057e4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057d0:	2505                	addiw	a0,a0,1
    800057d2:	07a1                	addi	a5,a5,8
    800057d4:	fed51ce3          	bne	a0,a3,800057cc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057d8:	557d                	li	a0,-1
}
    800057da:	60e2                	ld	ra,24(sp)
    800057dc:	6442                	ld	s0,16(sp)
    800057de:	64a2                	ld	s1,8(sp)
    800057e0:	6105                	addi	sp,sp,32
    800057e2:	8082                	ret
      p->ofile[fd] = f;
    800057e4:	01e50793          	addi	a5,a0,30
    800057e8:	078e                	slli	a5,a5,0x3
    800057ea:	963e                	add	a2,a2,a5
    800057ec:	e204                	sd	s1,0(a2)
      return fd;
    800057ee:	b7f5                	j	800057da <fdalloc+0x2c>

00000000800057f0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057f0:	715d                	addi	sp,sp,-80
    800057f2:	e486                	sd	ra,72(sp)
    800057f4:	e0a2                	sd	s0,64(sp)
    800057f6:	fc26                	sd	s1,56(sp)
    800057f8:	f84a                	sd	s2,48(sp)
    800057fa:	f44e                	sd	s3,40(sp)
    800057fc:	f052                	sd	s4,32(sp)
    800057fe:	ec56                	sd	s5,24(sp)
    80005800:	0880                	addi	s0,sp,80
    80005802:	89ae                	mv	s3,a1
    80005804:	8ab2                	mv	s5,a2
    80005806:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005808:	fb040593          	addi	a1,s0,-80
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	e86080e7          	jalr	-378(ra) # 80004692 <nameiparent>
    80005814:	892a                	mv	s2,a0
    80005816:	12050f63          	beqz	a0,80005954 <create+0x164>
    return 0;

  ilock(dp);
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	6a4080e7          	jalr	1700(ra) # 80003ebe <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005822:	4601                	li	a2,0
    80005824:	fb040593          	addi	a1,s0,-80
    80005828:	854a                	mv	a0,s2
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	b78080e7          	jalr	-1160(ra) # 800043a2 <dirlookup>
    80005832:	84aa                	mv	s1,a0
    80005834:	c921                	beqz	a0,80005884 <create+0x94>
    iunlockput(dp);
    80005836:	854a                	mv	a0,s2
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	8e8080e7          	jalr	-1816(ra) # 80004120 <iunlockput>
    ilock(ip);
    80005840:	8526                	mv	a0,s1
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	67c080e7          	jalr	1660(ra) # 80003ebe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000584a:	2981                	sext.w	s3,s3
    8000584c:	4789                	li	a5,2
    8000584e:	02f99463          	bne	s3,a5,80005876 <create+0x86>
    80005852:	0444d783          	lhu	a5,68(s1)
    80005856:	37f9                	addiw	a5,a5,-2
    80005858:	17c2                	slli	a5,a5,0x30
    8000585a:	93c1                	srli	a5,a5,0x30
    8000585c:	4705                	li	a4,1
    8000585e:	00f76c63          	bltu	a4,a5,80005876 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005862:	8526                	mv	a0,s1
    80005864:	60a6                	ld	ra,72(sp)
    80005866:	6406                	ld	s0,64(sp)
    80005868:	74e2                	ld	s1,56(sp)
    8000586a:	7942                	ld	s2,48(sp)
    8000586c:	79a2                	ld	s3,40(sp)
    8000586e:	7a02                	ld	s4,32(sp)
    80005870:	6ae2                	ld	s5,24(sp)
    80005872:	6161                	addi	sp,sp,80
    80005874:	8082                	ret
    iunlockput(ip);
    80005876:	8526                	mv	a0,s1
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	8a8080e7          	jalr	-1880(ra) # 80004120 <iunlockput>
    return 0;
    80005880:	4481                	li	s1,0
    80005882:	b7c5                	j	80005862 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005884:	85ce                	mv	a1,s3
    80005886:	00092503          	lw	a0,0(s2)
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	49c080e7          	jalr	1180(ra) # 80003d26 <ialloc>
    80005892:	84aa                	mv	s1,a0
    80005894:	c529                	beqz	a0,800058de <create+0xee>
  ilock(ip);
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	628080e7          	jalr	1576(ra) # 80003ebe <ilock>
  ip->major = major;
    8000589e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800058a2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800058a6:	4785                	li	a5,1
    800058a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	546080e7          	jalr	1350(ra) # 80003df4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800058b6:	2981                	sext.w	s3,s3
    800058b8:	4785                	li	a5,1
    800058ba:	02f98a63          	beq	s3,a5,800058ee <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800058be:	40d0                	lw	a2,4(s1)
    800058c0:	fb040593          	addi	a1,s0,-80
    800058c4:	854a                	mv	a0,s2
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	cec080e7          	jalr	-788(ra) # 800045b2 <dirlink>
    800058ce:	06054b63          	bltz	a0,80005944 <create+0x154>
  iunlockput(dp);
    800058d2:	854a                	mv	a0,s2
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	84c080e7          	jalr	-1972(ra) # 80004120 <iunlockput>
  return ip;
    800058dc:	b759                	j	80005862 <create+0x72>
    panic("create: ialloc");
    800058de:	00003517          	auipc	a0,0x3
    800058e2:	eba50513          	addi	a0,a0,-326 # 80008798 <syscalls+0x2b8>
    800058e6:	ffffb097          	auipc	ra,0xffffb
    800058ea:	c58080e7          	jalr	-936(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800058ee:	04a95783          	lhu	a5,74(s2)
    800058f2:	2785                	addiw	a5,a5,1
    800058f4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	4fa080e7          	jalr	1274(ra) # 80003df4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005902:	40d0                	lw	a2,4(s1)
    80005904:	00003597          	auipc	a1,0x3
    80005908:	ea458593          	addi	a1,a1,-348 # 800087a8 <syscalls+0x2c8>
    8000590c:	8526                	mv	a0,s1
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	ca4080e7          	jalr	-860(ra) # 800045b2 <dirlink>
    80005916:	00054f63          	bltz	a0,80005934 <create+0x144>
    8000591a:	00492603          	lw	a2,4(s2)
    8000591e:	00003597          	auipc	a1,0x3
    80005922:	e9258593          	addi	a1,a1,-366 # 800087b0 <syscalls+0x2d0>
    80005926:	8526                	mv	a0,s1
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	c8a080e7          	jalr	-886(ra) # 800045b2 <dirlink>
    80005930:	f80557e3          	bgez	a0,800058be <create+0xce>
      panic("create dots");
    80005934:	00003517          	auipc	a0,0x3
    80005938:	e8450513          	addi	a0,a0,-380 # 800087b8 <syscalls+0x2d8>
    8000593c:	ffffb097          	auipc	ra,0xffffb
    80005940:	c02080e7          	jalr	-1022(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005944:	00003517          	auipc	a0,0x3
    80005948:	e8450513          	addi	a0,a0,-380 # 800087c8 <syscalls+0x2e8>
    8000594c:	ffffb097          	auipc	ra,0xffffb
    80005950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>
    return 0;
    80005954:	84aa                	mv	s1,a0
    80005956:	b731                	j	80005862 <create+0x72>

0000000080005958 <sys_dup>:
{
    80005958:	7179                	addi	sp,sp,-48
    8000595a:	f406                	sd	ra,40(sp)
    8000595c:	f022                	sd	s0,32(sp)
    8000595e:	ec26                	sd	s1,24(sp)
    80005960:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005962:	fd840613          	addi	a2,s0,-40
    80005966:	4581                	li	a1,0
    80005968:	4501                	li	a0,0
    8000596a:	00000097          	auipc	ra,0x0
    8000596e:	ddc080e7          	jalr	-548(ra) # 80005746 <argfd>
    return -1;
    80005972:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005974:	02054363          	bltz	a0,8000599a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005978:	fd843503          	ld	a0,-40(s0)
    8000597c:	00000097          	auipc	ra,0x0
    80005980:	e32080e7          	jalr	-462(ra) # 800057ae <fdalloc>
    80005984:	84aa                	mv	s1,a0
    return -1;
    80005986:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005988:	00054963          	bltz	a0,8000599a <sys_dup+0x42>
  filedup(f);
    8000598c:	fd843503          	ld	a0,-40(s0)
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	37a080e7          	jalr	890(ra) # 80004d0a <filedup>
  return fd;
    80005998:	87a6                	mv	a5,s1
}
    8000599a:	853e                	mv	a0,a5
    8000599c:	70a2                	ld	ra,40(sp)
    8000599e:	7402                	ld	s0,32(sp)
    800059a0:	64e2                	ld	s1,24(sp)
    800059a2:	6145                	addi	sp,sp,48
    800059a4:	8082                	ret

00000000800059a6 <sys_read>:
{
    800059a6:	7179                	addi	sp,sp,-48
    800059a8:	f406                	sd	ra,40(sp)
    800059aa:	f022                	sd	s0,32(sp)
    800059ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059ae:	fe840613          	addi	a2,s0,-24
    800059b2:	4581                	li	a1,0
    800059b4:	4501                	li	a0,0
    800059b6:	00000097          	auipc	ra,0x0
    800059ba:	d90080e7          	jalr	-624(ra) # 80005746 <argfd>
    return -1;
    800059be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c0:	04054163          	bltz	a0,80005a02 <sys_read+0x5c>
    800059c4:	fe440593          	addi	a1,s0,-28
    800059c8:	4509                	li	a0,2
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	906080e7          	jalr	-1786(ra) # 800032d0 <argint>
    return -1;
    800059d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059d4:	02054763          	bltz	a0,80005a02 <sys_read+0x5c>
    800059d8:	fd840593          	addi	a1,s0,-40
    800059dc:	4505                	li	a0,1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	914080e7          	jalr	-1772(ra) # 800032f2 <argaddr>
    return -1;
    800059e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059e8:	00054d63          	bltz	a0,80005a02 <sys_read+0x5c>
  return fileread(f, p, n);
    800059ec:	fe442603          	lw	a2,-28(s0)
    800059f0:	fd843583          	ld	a1,-40(s0)
    800059f4:	fe843503          	ld	a0,-24(s0)
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	49e080e7          	jalr	1182(ra) # 80004e96 <fileread>
    80005a00:	87aa                	mv	a5,a0
}
    80005a02:	853e                	mv	a0,a5
    80005a04:	70a2                	ld	ra,40(sp)
    80005a06:	7402                	ld	s0,32(sp)
    80005a08:	6145                	addi	sp,sp,48
    80005a0a:	8082                	ret

0000000080005a0c <sys_write>:
{
    80005a0c:	7179                	addi	sp,sp,-48
    80005a0e:	f406                	sd	ra,40(sp)
    80005a10:	f022                	sd	s0,32(sp)
    80005a12:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a14:	fe840613          	addi	a2,s0,-24
    80005a18:	4581                	li	a1,0
    80005a1a:	4501                	li	a0,0
    80005a1c:	00000097          	auipc	ra,0x0
    80005a20:	d2a080e7          	jalr	-726(ra) # 80005746 <argfd>
    return -1;
    80005a24:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a26:	04054163          	bltz	a0,80005a68 <sys_write+0x5c>
    80005a2a:	fe440593          	addi	a1,s0,-28
    80005a2e:	4509                	li	a0,2
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	8a0080e7          	jalr	-1888(ra) # 800032d0 <argint>
    return -1;
    80005a38:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a3a:	02054763          	bltz	a0,80005a68 <sys_write+0x5c>
    80005a3e:	fd840593          	addi	a1,s0,-40
    80005a42:	4505                	li	a0,1
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	8ae080e7          	jalr	-1874(ra) # 800032f2 <argaddr>
    return -1;
    80005a4c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a4e:	00054d63          	bltz	a0,80005a68 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005a52:	fe442603          	lw	a2,-28(s0)
    80005a56:	fd843583          	ld	a1,-40(s0)
    80005a5a:	fe843503          	ld	a0,-24(s0)
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	4fa080e7          	jalr	1274(ra) # 80004f58 <filewrite>
    80005a66:	87aa                	mv	a5,a0
}
    80005a68:	853e                	mv	a0,a5
    80005a6a:	70a2                	ld	ra,40(sp)
    80005a6c:	7402                	ld	s0,32(sp)
    80005a6e:	6145                	addi	sp,sp,48
    80005a70:	8082                	ret

0000000080005a72 <sys_close>:
{
    80005a72:	1101                	addi	sp,sp,-32
    80005a74:	ec06                	sd	ra,24(sp)
    80005a76:	e822                	sd	s0,16(sp)
    80005a78:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a7a:	fe040613          	addi	a2,s0,-32
    80005a7e:	fec40593          	addi	a1,s0,-20
    80005a82:	4501                	li	a0,0
    80005a84:	00000097          	auipc	ra,0x0
    80005a88:	cc2080e7          	jalr	-830(ra) # 80005746 <argfd>
    return -1;
    80005a8c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a8e:	02054463          	bltz	a0,80005ab6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a92:	ffffc097          	auipc	ra,0xffffc
    80005a96:	332080e7          	jalr	818(ra) # 80001dc4 <myproc>
    80005a9a:	fec42783          	lw	a5,-20(s0)
    80005a9e:	07f9                	addi	a5,a5,30
    80005aa0:	078e                	slli	a5,a5,0x3
    80005aa2:	97aa                	add	a5,a5,a0
    80005aa4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005aa8:	fe043503          	ld	a0,-32(s0)
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	2b0080e7          	jalr	688(ra) # 80004d5c <fileclose>
  return 0;
    80005ab4:	4781                	li	a5,0
}
    80005ab6:	853e                	mv	a0,a5
    80005ab8:	60e2                	ld	ra,24(sp)
    80005aba:	6442                	ld	s0,16(sp)
    80005abc:	6105                	addi	sp,sp,32
    80005abe:	8082                	ret

0000000080005ac0 <sys_fstat>:
{
    80005ac0:	1101                	addi	sp,sp,-32
    80005ac2:	ec06                	sd	ra,24(sp)
    80005ac4:	e822                	sd	s0,16(sp)
    80005ac6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ac8:	fe840613          	addi	a2,s0,-24
    80005acc:	4581                	li	a1,0
    80005ace:	4501                	li	a0,0
    80005ad0:	00000097          	auipc	ra,0x0
    80005ad4:	c76080e7          	jalr	-906(ra) # 80005746 <argfd>
    return -1;
    80005ad8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ada:	02054563          	bltz	a0,80005b04 <sys_fstat+0x44>
    80005ade:	fe040593          	addi	a1,s0,-32
    80005ae2:	4505                	li	a0,1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	80e080e7          	jalr	-2034(ra) # 800032f2 <argaddr>
    return -1;
    80005aec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005aee:	00054b63          	bltz	a0,80005b04 <sys_fstat+0x44>
  return filestat(f, st);
    80005af2:	fe043583          	ld	a1,-32(s0)
    80005af6:	fe843503          	ld	a0,-24(s0)
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	32a080e7          	jalr	810(ra) # 80004e24 <filestat>
    80005b02:	87aa                	mv	a5,a0
}
    80005b04:	853e                	mv	a0,a5
    80005b06:	60e2                	ld	ra,24(sp)
    80005b08:	6442                	ld	s0,16(sp)
    80005b0a:	6105                	addi	sp,sp,32
    80005b0c:	8082                	ret

0000000080005b0e <sys_link>:
{
    80005b0e:	7169                	addi	sp,sp,-304
    80005b10:	f606                	sd	ra,296(sp)
    80005b12:	f222                	sd	s0,288(sp)
    80005b14:	ee26                	sd	s1,280(sp)
    80005b16:	ea4a                	sd	s2,272(sp)
    80005b18:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b1a:	08000613          	li	a2,128
    80005b1e:	ed040593          	addi	a1,s0,-304
    80005b22:	4501                	li	a0,0
    80005b24:	ffffd097          	auipc	ra,0xffffd
    80005b28:	7f0080e7          	jalr	2032(ra) # 80003314 <argstr>
    return -1;
    80005b2c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b2e:	10054e63          	bltz	a0,80005c4a <sys_link+0x13c>
    80005b32:	08000613          	li	a2,128
    80005b36:	f5040593          	addi	a1,s0,-176
    80005b3a:	4505                	li	a0,1
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	7d8080e7          	jalr	2008(ra) # 80003314 <argstr>
    return -1;
    80005b44:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b46:	10054263          	bltz	a0,80005c4a <sys_link+0x13c>
  begin_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	d46080e7          	jalr	-698(ra) # 80004890 <begin_op>
  if((ip = namei(old)) == 0){
    80005b52:	ed040513          	addi	a0,s0,-304
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	b1e080e7          	jalr	-1250(ra) # 80004674 <namei>
    80005b5e:	84aa                	mv	s1,a0
    80005b60:	c551                	beqz	a0,80005bec <sys_link+0xde>
  ilock(ip);
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	35c080e7          	jalr	860(ra) # 80003ebe <ilock>
  if(ip->type == T_DIR){
    80005b6a:	04449703          	lh	a4,68(s1)
    80005b6e:	4785                	li	a5,1
    80005b70:	08f70463          	beq	a4,a5,80005bf8 <sys_link+0xea>
  ip->nlink++;
    80005b74:	04a4d783          	lhu	a5,74(s1)
    80005b78:	2785                	addiw	a5,a5,1
    80005b7a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b7e:	8526                	mv	a0,s1
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	274080e7          	jalr	628(ra) # 80003df4 <iupdate>
  iunlock(ip);
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	3f6080e7          	jalr	1014(ra) # 80003f80 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b92:	fd040593          	addi	a1,s0,-48
    80005b96:	f5040513          	addi	a0,s0,-176
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	af8080e7          	jalr	-1288(ra) # 80004692 <nameiparent>
    80005ba2:	892a                	mv	s2,a0
    80005ba4:	c935                	beqz	a0,80005c18 <sys_link+0x10a>
  ilock(dp);
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	318080e7          	jalr	792(ra) # 80003ebe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005bae:	00092703          	lw	a4,0(s2)
    80005bb2:	409c                	lw	a5,0(s1)
    80005bb4:	04f71d63          	bne	a4,a5,80005c0e <sys_link+0x100>
    80005bb8:	40d0                	lw	a2,4(s1)
    80005bba:	fd040593          	addi	a1,s0,-48
    80005bbe:	854a                	mv	a0,s2
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	9f2080e7          	jalr	-1550(ra) # 800045b2 <dirlink>
    80005bc8:	04054363          	bltz	a0,80005c0e <sys_link+0x100>
  iunlockput(dp);
    80005bcc:	854a                	mv	a0,s2
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	552080e7          	jalr	1362(ra) # 80004120 <iunlockput>
  iput(ip);
    80005bd6:	8526                	mv	a0,s1
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	4a0080e7          	jalr	1184(ra) # 80004078 <iput>
  end_op();
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	d30080e7          	jalr	-720(ra) # 80004910 <end_op>
  return 0;
    80005be8:	4781                	li	a5,0
    80005bea:	a085                	j	80005c4a <sys_link+0x13c>
    end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	d24080e7          	jalr	-732(ra) # 80004910 <end_op>
    return -1;
    80005bf4:	57fd                	li	a5,-1
    80005bf6:	a891                	j	80005c4a <sys_link+0x13c>
    iunlockput(ip);
    80005bf8:	8526                	mv	a0,s1
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	526080e7          	jalr	1318(ra) # 80004120 <iunlockput>
    end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	d0e080e7          	jalr	-754(ra) # 80004910 <end_op>
    return -1;
    80005c0a:	57fd                	li	a5,-1
    80005c0c:	a83d                	j	80005c4a <sys_link+0x13c>
    iunlockput(dp);
    80005c0e:	854a                	mv	a0,s2
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	510080e7          	jalr	1296(ra) # 80004120 <iunlockput>
  ilock(ip);
    80005c18:	8526                	mv	a0,s1
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	2a4080e7          	jalr	676(ra) # 80003ebe <ilock>
  ip->nlink--;
    80005c22:	04a4d783          	lhu	a5,74(s1)
    80005c26:	37fd                	addiw	a5,a5,-1
    80005c28:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	1c6080e7          	jalr	454(ra) # 80003df4 <iupdate>
  iunlockput(ip);
    80005c36:	8526                	mv	a0,s1
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	4e8080e7          	jalr	1256(ra) # 80004120 <iunlockput>
  end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	cd0080e7          	jalr	-816(ra) # 80004910 <end_op>
  return -1;
    80005c48:	57fd                	li	a5,-1
}
    80005c4a:	853e                	mv	a0,a5
    80005c4c:	70b2                	ld	ra,296(sp)
    80005c4e:	7412                	ld	s0,288(sp)
    80005c50:	64f2                	ld	s1,280(sp)
    80005c52:	6952                	ld	s2,272(sp)
    80005c54:	6155                	addi	sp,sp,304
    80005c56:	8082                	ret

0000000080005c58 <sys_unlink>:
{
    80005c58:	7151                	addi	sp,sp,-240
    80005c5a:	f586                	sd	ra,232(sp)
    80005c5c:	f1a2                	sd	s0,224(sp)
    80005c5e:	eda6                	sd	s1,216(sp)
    80005c60:	e9ca                	sd	s2,208(sp)
    80005c62:	e5ce                	sd	s3,200(sp)
    80005c64:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c66:	08000613          	li	a2,128
    80005c6a:	f3040593          	addi	a1,s0,-208
    80005c6e:	4501                	li	a0,0
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	6a4080e7          	jalr	1700(ra) # 80003314 <argstr>
    80005c78:	18054163          	bltz	a0,80005dfa <sys_unlink+0x1a2>
  begin_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	c14080e7          	jalr	-1004(ra) # 80004890 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c84:	fb040593          	addi	a1,s0,-80
    80005c88:	f3040513          	addi	a0,s0,-208
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	a06080e7          	jalr	-1530(ra) # 80004692 <nameiparent>
    80005c94:	84aa                	mv	s1,a0
    80005c96:	c979                	beqz	a0,80005d6c <sys_unlink+0x114>
  ilock(dp);
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	226080e7          	jalr	550(ra) # 80003ebe <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ca0:	00003597          	auipc	a1,0x3
    80005ca4:	b0858593          	addi	a1,a1,-1272 # 800087a8 <syscalls+0x2c8>
    80005ca8:	fb040513          	addi	a0,s0,-80
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	6dc080e7          	jalr	1756(ra) # 80004388 <namecmp>
    80005cb4:	14050a63          	beqz	a0,80005e08 <sys_unlink+0x1b0>
    80005cb8:	00003597          	auipc	a1,0x3
    80005cbc:	af858593          	addi	a1,a1,-1288 # 800087b0 <syscalls+0x2d0>
    80005cc0:	fb040513          	addi	a0,s0,-80
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	6c4080e7          	jalr	1732(ra) # 80004388 <namecmp>
    80005ccc:	12050e63          	beqz	a0,80005e08 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cd0:	f2c40613          	addi	a2,s0,-212
    80005cd4:	fb040593          	addi	a1,s0,-80
    80005cd8:	8526                	mv	a0,s1
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	6c8080e7          	jalr	1736(ra) # 800043a2 <dirlookup>
    80005ce2:	892a                	mv	s2,a0
    80005ce4:	12050263          	beqz	a0,80005e08 <sys_unlink+0x1b0>
  ilock(ip);
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	1d6080e7          	jalr	470(ra) # 80003ebe <ilock>
  if(ip->nlink < 1)
    80005cf0:	04a91783          	lh	a5,74(s2)
    80005cf4:	08f05263          	blez	a5,80005d78 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005cf8:	04491703          	lh	a4,68(s2)
    80005cfc:	4785                	li	a5,1
    80005cfe:	08f70563          	beq	a4,a5,80005d88 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d02:	4641                	li	a2,16
    80005d04:	4581                	li	a1,0
    80005d06:	fc040513          	addi	a0,s0,-64
    80005d0a:	ffffb097          	auipc	ra,0xffffb
    80005d0e:	ffa080e7          	jalr	-6(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d12:	4741                	li	a4,16
    80005d14:	f2c42683          	lw	a3,-212(s0)
    80005d18:	fc040613          	addi	a2,s0,-64
    80005d1c:	4581                	li	a1,0
    80005d1e:	8526                	mv	a0,s1
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	54a080e7          	jalr	1354(ra) # 8000426a <writei>
    80005d28:	47c1                	li	a5,16
    80005d2a:	0af51563          	bne	a0,a5,80005dd4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d2e:	04491703          	lh	a4,68(s2)
    80005d32:	4785                	li	a5,1
    80005d34:	0af70863          	beq	a4,a5,80005de4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d38:	8526                	mv	a0,s1
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	3e6080e7          	jalr	998(ra) # 80004120 <iunlockput>
  ip->nlink--;
    80005d42:	04a95783          	lhu	a5,74(s2)
    80005d46:	37fd                	addiw	a5,a5,-1
    80005d48:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d4c:	854a                	mv	a0,s2
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	0a6080e7          	jalr	166(ra) # 80003df4 <iupdate>
  iunlockput(ip);
    80005d56:	854a                	mv	a0,s2
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	3c8080e7          	jalr	968(ra) # 80004120 <iunlockput>
  end_op();
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	bb0080e7          	jalr	-1104(ra) # 80004910 <end_op>
  return 0;
    80005d68:	4501                	li	a0,0
    80005d6a:	a84d                	j	80005e1c <sys_unlink+0x1c4>
    end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	ba4080e7          	jalr	-1116(ra) # 80004910 <end_op>
    return -1;
    80005d74:	557d                	li	a0,-1
    80005d76:	a05d                	j	80005e1c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d78:	00003517          	auipc	a0,0x3
    80005d7c:	a6050513          	addi	a0,a0,-1440 # 800087d8 <syscalls+0x2f8>
    80005d80:	ffffa097          	auipc	ra,0xffffa
    80005d84:	7be080e7          	jalr	1982(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d88:	04c92703          	lw	a4,76(s2)
    80005d8c:	02000793          	li	a5,32
    80005d90:	f6e7f9e3          	bgeu	a5,a4,80005d02 <sys_unlink+0xaa>
    80005d94:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d98:	4741                	li	a4,16
    80005d9a:	86ce                	mv	a3,s3
    80005d9c:	f1840613          	addi	a2,s0,-232
    80005da0:	4581                	li	a1,0
    80005da2:	854a                	mv	a0,s2
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	3ce080e7          	jalr	974(ra) # 80004172 <readi>
    80005dac:	47c1                	li	a5,16
    80005dae:	00f51b63          	bne	a0,a5,80005dc4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005db2:	f1845783          	lhu	a5,-232(s0)
    80005db6:	e7a1                	bnez	a5,80005dfe <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005db8:	29c1                	addiw	s3,s3,16
    80005dba:	04c92783          	lw	a5,76(s2)
    80005dbe:	fcf9ede3          	bltu	s3,a5,80005d98 <sys_unlink+0x140>
    80005dc2:	b781                	j	80005d02 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005dc4:	00003517          	auipc	a0,0x3
    80005dc8:	a2c50513          	addi	a0,a0,-1492 # 800087f0 <syscalls+0x310>
    80005dcc:	ffffa097          	auipc	ra,0xffffa
    80005dd0:	772080e7          	jalr	1906(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005dd4:	00003517          	auipc	a0,0x3
    80005dd8:	a3450513          	addi	a0,a0,-1484 # 80008808 <syscalls+0x328>
    80005ddc:	ffffa097          	auipc	ra,0xffffa
    80005de0:	762080e7          	jalr	1890(ra) # 8000053e <panic>
    dp->nlink--;
    80005de4:	04a4d783          	lhu	a5,74(s1)
    80005de8:	37fd                	addiw	a5,a5,-1
    80005dea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005dee:	8526                	mv	a0,s1
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	004080e7          	jalr	4(ra) # 80003df4 <iupdate>
    80005df8:	b781                	j	80005d38 <sys_unlink+0xe0>
    return -1;
    80005dfa:	557d                	li	a0,-1
    80005dfc:	a005                	j	80005e1c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005dfe:	854a                	mv	a0,s2
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	320080e7          	jalr	800(ra) # 80004120 <iunlockput>
  iunlockput(dp);
    80005e08:	8526                	mv	a0,s1
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	316080e7          	jalr	790(ra) # 80004120 <iunlockput>
  end_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	afe080e7          	jalr	-1282(ra) # 80004910 <end_op>
  return -1;
    80005e1a:	557d                	li	a0,-1
}
    80005e1c:	70ae                	ld	ra,232(sp)
    80005e1e:	740e                	ld	s0,224(sp)
    80005e20:	64ee                	ld	s1,216(sp)
    80005e22:	694e                	ld	s2,208(sp)
    80005e24:	69ae                	ld	s3,200(sp)
    80005e26:	616d                	addi	sp,sp,240
    80005e28:	8082                	ret

0000000080005e2a <sys_open>:

uint64
sys_open(void)
{
    80005e2a:	7131                	addi	sp,sp,-192
    80005e2c:	fd06                	sd	ra,184(sp)
    80005e2e:	f922                	sd	s0,176(sp)
    80005e30:	f526                	sd	s1,168(sp)
    80005e32:	f14a                	sd	s2,160(sp)
    80005e34:	ed4e                	sd	s3,152(sp)
    80005e36:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e38:	08000613          	li	a2,128
    80005e3c:	f5040593          	addi	a1,s0,-176
    80005e40:	4501                	li	a0,0
    80005e42:	ffffd097          	auipc	ra,0xffffd
    80005e46:	4d2080e7          	jalr	1234(ra) # 80003314 <argstr>
    return -1;
    80005e4a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e4c:	0c054163          	bltz	a0,80005f0e <sys_open+0xe4>
    80005e50:	f4c40593          	addi	a1,s0,-180
    80005e54:	4505                	li	a0,1
    80005e56:	ffffd097          	auipc	ra,0xffffd
    80005e5a:	47a080e7          	jalr	1146(ra) # 800032d0 <argint>
    80005e5e:	0a054863          	bltz	a0,80005f0e <sys_open+0xe4>

  begin_op();
    80005e62:	fffff097          	auipc	ra,0xfffff
    80005e66:	a2e080e7          	jalr	-1490(ra) # 80004890 <begin_op>

  if(omode & O_CREATE){
    80005e6a:	f4c42783          	lw	a5,-180(s0)
    80005e6e:	2007f793          	andi	a5,a5,512
    80005e72:	cbdd                	beqz	a5,80005f28 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e74:	4681                	li	a3,0
    80005e76:	4601                	li	a2,0
    80005e78:	4589                	li	a1,2
    80005e7a:	f5040513          	addi	a0,s0,-176
    80005e7e:	00000097          	auipc	ra,0x0
    80005e82:	972080e7          	jalr	-1678(ra) # 800057f0 <create>
    80005e86:	892a                	mv	s2,a0
    if(ip == 0){
    80005e88:	c959                	beqz	a0,80005f1e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e8a:	04491703          	lh	a4,68(s2)
    80005e8e:	478d                	li	a5,3
    80005e90:	00f71763          	bne	a4,a5,80005e9e <sys_open+0x74>
    80005e94:	04695703          	lhu	a4,70(s2)
    80005e98:	47a5                	li	a5,9
    80005e9a:	0ce7ec63          	bltu	a5,a4,80005f72 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	e02080e7          	jalr	-510(ra) # 80004ca0 <filealloc>
    80005ea6:	89aa                	mv	s3,a0
    80005ea8:	10050263          	beqz	a0,80005fac <sys_open+0x182>
    80005eac:	00000097          	auipc	ra,0x0
    80005eb0:	902080e7          	jalr	-1790(ra) # 800057ae <fdalloc>
    80005eb4:	84aa                	mv	s1,a0
    80005eb6:	0e054663          	bltz	a0,80005fa2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005eba:	04491703          	lh	a4,68(s2)
    80005ebe:	478d                	li	a5,3
    80005ec0:	0cf70463          	beq	a4,a5,80005f88 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ec4:	4789                	li	a5,2
    80005ec6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005eca:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ece:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ed2:	f4c42783          	lw	a5,-180(s0)
    80005ed6:	0017c713          	xori	a4,a5,1
    80005eda:	8b05                	andi	a4,a4,1
    80005edc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ee0:	0037f713          	andi	a4,a5,3
    80005ee4:	00e03733          	snez	a4,a4
    80005ee8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005eec:	4007f793          	andi	a5,a5,1024
    80005ef0:	c791                	beqz	a5,80005efc <sys_open+0xd2>
    80005ef2:	04491703          	lh	a4,68(s2)
    80005ef6:	4789                	li	a5,2
    80005ef8:	08f70f63          	beq	a4,a5,80005f96 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005efc:	854a                	mv	a0,s2
    80005efe:	ffffe097          	auipc	ra,0xffffe
    80005f02:	082080e7          	jalr	130(ra) # 80003f80 <iunlock>
  end_op();
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	a0a080e7          	jalr	-1526(ra) # 80004910 <end_op>

  return fd;
}
    80005f0e:	8526                	mv	a0,s1
    80005f10:	70ea                	ld	ra,184(sp)
    80005f12:	744a                	ld	s0,176(sp)
    80005f14:	74aa                	ld	s1,168(sp)
    80005f16:	790a                	ld	s2,160(sp)
    80005f18:	69ea                	ld	s3,152(sp)
    80005f1a:	6129                	addi	sp,sp,192
    80005f1c:	8082                	ret
      end_op();
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	9f2080e7          	jalr	-1550(ra) # 80004910 <end_op>
      return -1;
    80005f26:	b7e5                	j	80005f0e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f28:	f5040513          	addi	a0,s0,-176
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	748080e7          	jalr	1864(ra) # 80004674 <namei>
    80005f34:	892a                	mv	s2,a0
    80005f36:	c905                	beqz	a0,80005f66 <sys_open+0x13c>
    ilock(ip);
    80005f38:	ffffe097          	auipc	ra,0xffffe
    80005f3c:	f86080e7          	jalr	-122(ra) # 80003ebe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f40:	04491703          	lh	a4,68(s2)
    80005f44:	4785                	li	a5,1
    80005f46:	f4f712e3          	bne	a4,a5,80005e8a <sys_open+0x60>
    80005f4a:	f4c42783          	lw	a5,-180(s0)
    80005f4e:	dba1                	beqz	a5,80005e9e <sys_open+0x74>
      iunlockput(ip);
    80005f50:	854a                	mv	a0,s2
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	1ce080e7          	jalr	462(ra) # 80004120 <iunlockput>
      end_op();
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	9b6080e7          	jalr	-1610(ra) # 80004910 <end_op>
      return -1;
    80005f62:	54fd                	li	s1,-1
    80005f64:	b76d                	j	80005f0e <sys_open+0xe4>
      end_op();
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	9aa080e7          	jalr	-1622(ra) # 80004910 <end_op>
      return -1;
    80005f6e:	54fd                	li	s1,-1
    80005f70:	bf79                	j	80005f0e <sys_open+0xe4>
    iunlockput(ip);
    80005f72:	854a                	mv	a0,s2
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	1ac080e7          	jalr	428(ra) # 80004120 <iunlockput>
    end_op();
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	994080e7          	jalr	-1644(ra) # 80004910 <end_op>
    return -1;
    80005f84:	54fd                	li	s1,-1
    80005f86:	b761                	j	80005f0e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f88:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f8c:	04691783          	lh	a5,70(s2)
    80005f90:	02f99223          	sh	a5,36(s3)
    80005f94:	bf2d                	j	80005ece <sys_open+0xa4>
    itrunc(ip);
    80005f96:	854a                	mv	a0,s2
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	034080e7          	jalr	52(ra) # 80003fcc <itrunc>
    80005fa0:	bfb1                	j	80005efc <sys_open+0xd2>
      fileclose(f);
    80005fa2:	854e                	mv	a0,s3
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	db8080e7          	jalr	-584(ra) # 80004d5c <fileclose>
    iunlockput(ip);
    80005fac:	854a                	mv	a0,s2
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	172080e7          	jalr	370(ra) # 80004120 <iunlockput>
    end_op();
    80005fb6:	fffff097          	auipc	ra,0xfffff
    80005fba:	95a080e7          	jalr	-1702(ra) # 80004910 <end_op>
    return -1;
    80005fbe:	54fd                	li	s1,-1
    80005fc0:	b7b9                	j	80005f0e <sys_open+0xe4>

0000000080005fc2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005fc2:	7175                	addi	sp,sp,-144
    80005fc4:	e506                	sd	ra,136(sp)
    80005fc6:	e122                	sd	s0,128(sp)
    80005fc8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	8c6080e7          	jalr	-1850(ra) # 80004890 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005fd2:	08000613          	li	a2,128
    80005fd6:	f7040593          	addi	a1,s0,-144
    80005fda:	4501                	li	a0,0
    80005fdc:	ffffd097          	auipc	ra,0xffffd
    80005fe0:	338080e7          	jalr	824(ra) # 80003314 <argstr>
    80005fe4:	02054963          	bltz	a0,80006016 <sys_mkdir+0x54>
    80005fe8:	4681                	li	a3,0
    80005fea:	4601                	li	a2,0
    80005fec:	4585                	li	a1,1
    80005fee:	f7040513          	addi	a0,s0,-144
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	7fe080e7          	jalr	2046(ra) # 800057f0 <create>
    80005ffa:	cd11                	beqz	a0,80006016 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	124080e7          	jalr	292(ra) # 80004120 <iunlockput>
  end_op();
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	90c080e7          	jalr	-1780(ra) # 80004910 <end_op>
  return 0;
    8000600c:	4501                	li	a0,0
}
    8000600e:	60aa                	ld	ra,136(sp)
    80006010:	640a                	ld	s0,128(sp)
    80006012:	6149                	addi	sp,sp,144
    80006014:	8082                	ret
    end_op();
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	8fa080e7          	jalr	-1798(ra) # 80004910 <end_op>
    return -1;
    8000601e:	557d                	li	a0,-1
    80006020:	b7fd                	j	8000600e <sys_mkdir+0x4c>

0000000080006022 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006022:	7135                	addi	sp,sp,-160
    80006024:	ed06                	sd	ra,152(sp)
    80006026:	e922                	sd	s0,144(sp)
    80006028:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000602a:	fffff097          	auipc	ra,0xfffff
    8000602e:	866080e7          	jalr	-1946(ra) # 80004890 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006032:	08000613          	li	a2,128
    80006036:	f7040593          	addi	a1,s0,-144
    8000603a:	4501                	li	a0,0
    8000603c:	ffffd097          	auipc	ra,0xffffd
    80006040:	2d8080e7          	jalr	728(ra) # 80003314 <argstr>
    80006044:	04054a63          	bltz	a0,80006098 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006048:	f6c40593          	addi	a1,s0,-148
    8000604c:	4505                	li	a0,1
    8000604e:	ffffd097          	auipc	ra,0xffffd
    80006052:	282080e7          	jalr	642(ra) # 800032d0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006056:	04054163          	bltz	a0,80006098 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000605a:	f6840593          	addi	a1,s0,-152
    8000605e:	4509                	li	a0,2
    80006060:	ffffd097          	auipc	ra,0xffffd
    80006064:	270080e7          	jalr	624(ra) # 800032d0 <argint>
     argint(1, &major) < 0 ||
    80006068:	02054863          	bltz	a0,80006098 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000606c:	f6841683          	lh	a3,-152(s0)
    80006070:	f6c41603          	lh	a2,-148(s0)
    80006074:	458d                	li	a1,3
    80006076:	f7040513          	addi	a0,s0,-144
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	776080e7          	jalr	1910(ra) # 800057f0 <create>
     argint(2, &minor) < 0 ||
    80006082:	c919                	beqz	a0,80006098 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	09c080e7          	jalr	156(ra) # 80004120 <iunlockput>
  end_op();
    8000608c:	fffff097          	auipc	ra,0xfffff
    80006090:	884080e7          	jalr	-1916(ra) # 80004910 <end_op>
  return 0;
    80006094:	4501                	li	a0,0
    80006096:	a031                	j	800060a2 <sys_mknod+0x80>
    end_op();
    80006098:	fffff097          	auipc	ra,0xfffff
    8000609c:	878080e7          	jalr	-1928(ra) # 80004910 <end_op>
    return -1;
    800060a0:	557d                	li	a0,-1
}
    800060a2:	60ea                	ld	ra,152(sp)
    800060a4:	644a                	ld	s0,144(sp)
    800060a6:	610d                	addi	sp,sp,160
    800060a8:	8082                	ret

00000000800060aa <sys_chdir>:

uint64
sys_chdir(void)
{
    800060aa:	7135                	addi	sp,sp,-160
    800060ac:	ed06                	sd	ra,152(sp)
    800060ae:	e922                	sd	s0,144(sp)
    800060b0:	e526                	sd	s1,136(sp)
    800060b2:	e14a                	sd	s2,128(sp)
    800060b4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060b6:	ffffc097          	auipc	ra,0xffffc
    800060ba:	d0e080e7          	jalr	-754(ra) # 80001dc4 <myproc>
    800060be:	892a                	mv	s2,a0
  
  begin_op();
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	7d0080e7          	jalr	2000(ra) # 80004890 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060c8:	08000613          	li	a2,128
    800060cc:	f6040593          	addi	a1,s0,-160
    800060d0:	4501                	li	a0,0
    800060d2:	ffffd097          	auipc	ra,0xffffd
    800060d6:	242080e7          	jalr	578(ra) # 80003314 <argstr>
    800060da:	04054b63          	bltz	a0,80006130 <sys_chdir+0x86>
    800060de:	f6040513          	addi	a0,s0,-160
    800060e2:	ffffe097          	auipc	ra,0xffffe
    800060e6:	592080e7          	jalr	1426(ra) # 80004674 <namei>
    800060ea:	84aa                	mv	s1,a0
    800060ec:	c131                	beqz	a0,80006130 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	dd0080e7          	jalr	-560(ra) # 80003ebe <ilock>
  if(ip->type != T_DIR){
    800060f6:	04449703          	lh	a4,68(s1)
    800060fa:	4785                	li	a5,1
    800060fc:	04f71063          	bne	a4,a5,8000613c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006100:	8526                	mv	a0,s1
    80006102:	ffffe097          	auipc	ra,0xffffe
    80006106:	e7e080e7          	jalr	-386(ra) # 80003f80 <iunlock>
  iput(p->cwd);
    8000610a:	17093503          	ld	a0,368(s2)
    8000610e:	ffffe097          	auipc	ra,0xffffe
    80006112:	f6a080e7          	jalr	-150(ra) # 80004078 <iput>
  end_op();
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	7fa080e7          	jalr	2042(ra) # 80004910 <end_op>
  p->cwd = ip;
    8000611e:	16993823          	sd	s1,368(s2)
  return 0;
    80006122:	4501                	li	a0,0
}
    80006124:	60ea                	ld	ra,152(sp)
    80006126:	644a                	ld	s0,144(sp)
    80006128:	64aa                	ld	s1,136(sp)
    8000612a:	690a                	ld	s2,128(sp)
    8000612c:	610d                	addi	sp,sp,160
    8000612e:	8082                	ret
    end_op();
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	7e0080e7          	jalr	2016(ra) # 80004910 <end_op>
    return -1;
    80006138:	557d                	li	a0,-1
    8000613a:	b7ed                	j	80006124 <sys_chdir+0x7a>
    iunlockput(ip);
    8000613c:	8526                	mv	a0,s1
    8000613e:	ffffe097          	auipc	ra,0xffffe
    80006142:	fe2080e7          	jalr	-30(ra) # 80004120 <iunlockput>
    end_op();
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	7ca080e7          	jalr	1994(ra) # 80004910 <end_op>
    return -1;
    8000614e:	557d                	li	a0,-1
    80006150:	bfd1                	j	80006124 <sys_chdir+0x7a>

0000000080006152 <sys_exec>:

uint64
sys_exec(void)
{
    80006152:	7145                	addi	sp,sp,-464
    80006154:	e786                	sd	ra,456(sp)
    80006156:	e3a2                	sd	s0,448(sp)
    80006158:	ff26                	sd	s1,440(sp)
    8000615a:	fb4a                	sd	s2,432(sp)
    8000615c:	f74e                	sd	s3,424(sp)
    8000615e:	f352                	sd	s4,416(sp)
    80006160:	ef56                	sd	s5,408(sp)
    80006162:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006164:	08000613          	li	a2,128
    80006168:	f4040593          	addi	a1,s0,-192
    8000616c:	4501                	li	a0,0
    8000616e:	ffffd097          	auipc	ra,0xffffd
    80006172:	1a6080e7          	jalr	422(ra) # 80003314 <argstr>
    return -1;
    80006176:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006178:	0c054a63          	bltz	a0,8000624c <sys_exec+0xfa>
    8000617c:	e3840593          	addi	a1,s0,-456
    80006180:	4505                	li	a0,1
    80006182:	ffffd097          	auipc	ra,0xffffd
    80006186:	170080e7          	jalr	368(ra) # 800032f2 <argaddr>
    8000618a:	0c054163          	bltz	a0,8000624c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000618e:	10000613          	li	a2,256
    80006192:	4581                	li	a1,0
    80006194:	e4040513          	addi	a0,s0,-448
    80006198:	ffffb097          	auipc	ra,0xffffb
    8000619c:	b6c080e7          	jalr	-1172(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061a0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061a4:	89a6                	mv	s3,s1
    800061a6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061a8:	02000a13          	li	s4,32
    800061ac:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061b0:	00391513          	slli	a0,s2,0x3
    800061b4:	e3040593          	addi	a1,s0,-464
    800061b8:	e3843783          	ld	a5,-456(s0)
    800061bc:	953e                	add	a0,a0,a5
    800061be:	ffffd097          	auipc	ra,0xffffd
    800061c2:	078080e7          	jalr	120(ra) # 80003236 <fetchaddr>
    800061c6:	02054a63          	bltz	a0,800061fa <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800061ca:	e3043783          	ld	a5,-464(s0)
    800061ce:	c3b9                	beqz	a5,80006214 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	924080e7          	jalr	-1756(ra) # 80000af4 <kalloc>
    800061d8:	85aa                	mv	a1,a0
    800061da:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800061de:	cd11                	beqz	a0,800061fa <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061e0:	6605                	lui	a2,0x1
    800061e2:	e3043503          	ld	a0,-464(s0)
    800061e6:	ffffd097          	auipc	ra,0xffffd
    800061ea:	0a2080e7          	jalr	162(ra) # 80003288 <fetchstr>
    800061ee:	00054663          	bltz	a0,800061fa <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800061f2:	0905                	addi	s2,s2,1
    800061f4:	09a1                	addi	s3,s3,8
    800061f6:	fb491be3          	bne	s2,s4,800061ac <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061fa:	10048913          	addi	s2,s1,256
    800061fe:	6088                	ld	a0,0(s1)
    80006200:	c529                	beqz	a0,8000624a <sys_exec+0xf8>
    kfree(argv[i]);
    80006202:	ffffa097          	auipc	ra,0xffffa
    80006206:	7f6080e7          	jalr	2038(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000620a:	04a1                	addi	s1,s1,8
    8000620c:	ff2499e3          	bne	s1,s2,800061fe <sys_exec+0xac>
  return -1;
    80006210:	597d                	li	s2,-1
    80006212:	a82d                	j	8000624c <sys_exec+0xfa>
      argv[i] = 0;
    80006214:	0a8e                	slli	s5,s5,0x3
    80006216:	fc040793          	addi	a5,s0,-64
    8000621a:	9abe                	add	s5,s5,a5
    8000621c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006220:	e4040593          	addi	a1,s0,-448
    80006224:	f4040513          	addi	a0,s0,-192
    80006228:	fffff097          	auipc	ra,0xfffff
    8000622c:	194080e7          	jalr	404(ra) # 800053bc <exec>
    80006230:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006232:	10048993          	addi	s3,s1,256
    80006236:	6088                	ld	a0,0(s1)
    80006238:	c911                	beqz	a0,8000624c <sys_exec+0xfa>
    kfree(argv[i]);
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	7be080e7          	jalr	1982(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006242:	04a1                	addi	s1,s1,8
    80006244:	ff3499e3          	bne	s1,s3,80006236 <sys_exec+0xe4>
    80006248:	a011                	j	8000624c <sys_exec+0xfa>
  return -1;
    8000624a:	597d                	li	s2,-1
}
    8000624c:	854a                	mv	a0,s2
    8000624e:	60be                	ld	ra,456(sp)
    80006250:	641e                	ld	s0,448(sp)
    80006252:	74fa                	ld	s1,440(sp)
    80006254:	795a                	ld	s2,432(sp)
    80006256:	79ba                	ld	s3,424(sp)
    80006258:	7a1a                	ld	s4,416(sp)
    8000625a:	6afa                	ld	s5,408(sp)
    8000625c:	6179                	addi	sp,sp,464
    8000625e:	8082                	ret

0000000080006260 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006260:	7139                	addi	sp,sp,-64
    80006262:	fc06                	sd	ra,56(sp)
    80006264:	f822                	sd	s0,48(sp)
    80006266:	f426                	sd	s1,40(sp)
    80006268:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000626a:	ffffc097          	auipc	ra,0xffffc
    8000626e:	b5a080e7          	jalr	-1190(ra) # 80001dc4 <myproc>
    80006272:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006274:	fd840593          	addi	a1,s0,-40
    80006278:	4501                	li	a0,0
    8000627a:	ffffd097          	auipc	ra,0xffffd
    8000627e:	078080e7          	jalr	120(ra) # 800032f2 <argaddr>
    return -1;
    80006282:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006284:	0e054063          	bltz	a0,80006364 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006288:	fc840593          	addi	a1,s0,-56
    8000628c:	fd040513          	addi	a0,s0,-48
    80006290:	fffff097          	auipc	ra,0xfffff
    80006294:	dfc080e7          	jalr	-516(ra) # 8000508c <pipealloc>
    return -1;
    80006298:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000629a:	0c054563          	bltz	a0,80006364 <sys_pipe+0x104>
  fd0 = -1;
    8000629e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062a2:	fd043503          	ld	a0,-48(s0)
    800062a6:	fffff097          	auipc	ra,0xfffff
    800062aa:	508080e7          	jalr	1288(ra) # 800057ae <fdalloc>
    800062ae:	fca42223          	sw	a0,-60(s0)
    800062b2:	08054c63          	bltz	a0,8000634a <sys_pipe+0xea>
    800062b6:	fc843503          	ld	a0,-56(s0)
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	4f4080e7          	jalr	1268(ra) # 800057ae <fdalloc>
    800062c2:	fca42023          	sw	a0,-64(s0)
    800062c6:	06054863          	bltz	a0,80006336 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062ca:	4691                	li	a3,4
    800062cc:	fc440613          	addi	a2,s0,-60
    800062d0:	fd843583          	ld	a1,-40(s0)
    800062d4:	78a8                	ld	a0,112(s1)
    800062d6:	ffffb097          	auipc	ra,0xffffb
    800062da:	3c0080e7          	jalr	960(ra) # 80001696 <copyout>
    800062de:	02054063          	bltz	a0,800062fe <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800062e2:	4691                	li	a3,4
    800062e4:	fc040613          	addi	a2,s0,-64
    800062e8:	fd843583          	ld	a1,-40(s0)
    800062ec:	0591                	addi	a1,a1,4
    800062ee:	78a8                	ld	a0,112(s1)
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	3a6080e7          	jalr	934(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800062f8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062fa:	06055563          	bgez	a0,80006364 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800062fe:	fc442783          	lw	a5,-60(s0)
    80006302:	07f9                	addi	a5,a5,30
    80006304:	078e                	slli	a5,a5,0x3
    80006306:	97a6                	add	a5,a5,s1
    80006308:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000630c:	fc042503          	lw	a0,-64(s0)
    80006310:	0579                	addi	a0,a0,30
    80006312:	050e                	slli	a0,a0,0x3
    80006314:	9526                	add	a0,a0,s1
    80006316:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000631a:	fd043503          	ld	a0,-48(s0)
    8000631e:	fffff097          	auipc	ra,0xfffff
    80006322:	a3e080e7          	jalr	-1474(ra) # 80004d5c <fileclose>
    fileclose(wf);
    80006326:	fc843503          	ld	a0,-56(s0)
    8000632a:	fffff097          	auipc	ra,0xfffff
    8000632e:	a32080e7          	jalr	-1486(ra) # 80004d5c <fileclose>
    return -1;
    80006332:	57fd                	li	a5,-1
    80006334:	a805                	j	80006364 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006336:	fc442783          	lw	a5,-60(s0)
    8000633a:	0007c863          	bltz	a5,8000634a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000633e:	01e78513          	addi	a0,a5,30
    80006342:	050e                	slli	a0,a0,0x3
    80006344:	9526                	add	a0,a0,s1
    80006346:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000634a:	fd043503          	ld	a0,-48(s0)
    8000634e:	fffff097          	auipc	ra,0xfffff
    80006352:	a0e080e7          	jalr	-1522(ra) # 80004d5c <fileclose>
    fileclose(wf);
    80006356:	fc843503          	ld	a0,-56(s0)
    8000635a:	fffff097          	auipc	ra,0xfffff
    8000635e:	a02080e7          	jalr	-1534(ra) # 80004d5c <fileclose>
    return -1;
    80006362:	57fd                	li	a5,-1
}
    80006364:	853e                	mv	a0,a5
    80006366:	70e2                	ld	ra,56(sp)
    80006368:	7442                	ld	s0,48(sp)
    8000636a:	74a2                	ld	s1,40(sp)
    8000636c:	6121                	addi	sp,sp,64
    8000636e:	8082                	ret

0000000080006370 <kernelvec>:
    80006370:	7111                	addi	sp,sp,-256
    80006372:	e006                	sd	ra,0(sp)
    80006374:	e40a                	sd	sp,8(sp)
    80006376:	e80e                	sd	gp,16(sp)
    80006378:	ec12                	sd	tp,24(sp)
    8000637a:	f016                	sd	t0,32(sp)
    8000637c:	f41a                	sd	t1,40(sp)
    8000637e:	f81e                	sd	t2,48(sp)
    80006380:	fc22                	sd	s0,56(sp)
    80006382:	e0a6                	sd	s1,64(sp)
    80006384:	e4aa                	sd	a0,72(sp)
    80006386:	e8ae                	sd	a1,80(sp)
    80006388:	ecb2                	sd	a2,88(sp)
    8000638a:	f0b6                	sd	a3,96(sp)
    8000638c:	f4ba                	sd	a4,104(sp)
    8000638e:	f8be                	sd	a5,112(sp)
    80006390:	fcc2                	sd	a6,120(sp)
    80006392:	e146                	sd	a7,128(sp)
    80006394:	e54a                	sd	s2,136(sp)
    80006396:	e94e                	sd	s3,144(sp)
    80006398:	ed52                	sd	s4,152(sp)
    8000639a:	f156                	sd	s5,160(sp)
    8000639c:	f55a                	sd	s6,168(sp)
    8000639e:	f95e                	sd	s7,176(sp)
    800063a0:	fd62                	sd	s8,184(sp)
    800063a2:	e1e6                	sd	s9,192(sp)
    800063a4:	e5ea                	sd	s10,200(sp)
    800063a6:	e9ee                	sd	s11,208(sp)
    800063a8:	edf2                	sd	t3,216(sp)
    800063aa:	f1f6                	sd	t4,224(sp)
    800063ac:	f5fa                	sd	t5,232(sp)
    800063ae:	f9fe                	sd	t6,240(sp)
    800063b0:	d53fc0ef          	jal	ra,80003102 <kerneltrap>
    800063b4:	6082                	ld	ra,0(sp)
    800063b6:	6122                	ld	sp,8(sp)
    800063b8:	61c2                	ld	gp,16(sp)
    800063ba:	7282                	ld	t0,32(sp)
    800063bc:	7322                	ld	t1,40(sp)
    800063be:	73c2                	ld	t2,48(sp)
    800063c0:	7462                	ld	s0,56(sp)
    800063c2:	6486                	ld	s1,64(sp)
    800063c4:	6526                	ld	a0,72(sp)
    800063c6:	65c6                	ld	a1,80(sp)
    800063c8:	6666                	ld	a2,88(sp)
    800063ca:	7686                	ld	a3,96(sp)
    800063cc:	7726                	ld	a4,104(sp)
    800063ce:	77c6                	ld	a5,112(sp)
    800063d0:	7866                	ld	a6,120(sp)
    800063d2:	688a                	ld	a7,128(sp)
    800063d4:	692a                	ld	s2,136(sp)
    800063d6:	69ca                	ld	s3,144(sp)
    800063d8:	6a6a                	ld	s4,152(sp)
    800063da:	7a8a                	ld	s5,160(sp)
    800063dc:	7b2a                	ld	s6,168(sp)
    800063de:	7bca                	ld	s7,176(sp)
    800063e0:	7c6a                	ld	s8,184(sp)
    800063e2:	6c8e                	ld	s9,192(sp)
    800063e4:	6d2e                	ld	s10,200(sp)
    800063e6:	6dce                	ld	s11,208(sp)
    800063e8:	6e6e                	ld	t3,216(sp)
    800063ea:	7e8e                	ld	t4,224(sp)
    800063ec:	7f2e                	ld	t5,232(sp)
    800063ee:	7fce                	ld	t6,240(sp)
    800063f0:	6111                	addi	sp,sp,256
    800063f2:	10200073          	sret
    800063f6:	00000013          	nop
    800063fa:	00000013          	nop
    800063fe:	0001                	nop

0000000080006400 <timervec>:
    80006400:	34051573          	csrrw	a0,mscratch,a0
    80006404:	e10c                	sd	a1,0(a0)
    80006406:	e510                	sd	a2,8(a0)
    80006408:	e914                	sd	a3,16(a0)
    8000640a:	6d0c                	ld	a1,24(a0)
    8000640c:	7110                	ld	a2,32(a0)
    8000640e:	6194                	ld	a3,0(a1)
    80006410:	96b2                	add	a3,a3,a2
    80006412:	e194                	sd	a3,0(a1)
    80006414:	4589                	li	a1,2
    80006416:	14459073          	csrw	sip,a1
    8000641a:	6914                	ld	a3,16(a0)
    8000641c:	6510                	ld	a2,8(a0)
    8000641e:	610c                	ld	a1,0(a0)
    80006420:	34051573          	csrrw	a0,mscratch,a0
    80006424:	30200073          	mret
	...

000000008000642a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000642a:	1141                	addi	sp,sp,-16
    8000642c:	e422                	sd	s0,8(sp)
    8000642e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006430:	0c0007b7          	lui	a5,0xc000
    80006434:	4705                	li	a4,1
    80006436:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006438:	c3d8                	sw	a4,4(a5)
}
    8000643a:	6422                	ld	s0,8(sp)
    8000643c:	0141                	addi	sp,sp,16
    8000643e:	8082                	ret

0000000080006440 <plicinithart>:

void
plicinithart(void)
{
    80006440:	1141                	addi	sp,sp,-16
    80006442:	e406                	sd	ra,8(sp)
    80006444:	e022                	sd	s0,0(sp)
    80006446:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	948080e7          	jalr	-1720(ra) # 80001d90 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006450:	0085171b          	slliw	a4,a0,0x8
    80006454:	0c0027b7          	lui	a5,0xc002
    80006458:	97ba                	add	a5,a5,a4
    8000645a:	40200713          	li	a4,1026
    8000645e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006462:	00d5151b          	slliw	a0,a0,0xd
    80006466:	0c2017b7          	lui	a5,0xc201
    8000646a:	953e                	add	a0,a0,a5
    8000646c:	00052023          	sw	zero,0(a0)
}
    80006470:	60a2                	ld	ra,8(sp)
    80006472:	6402                	ld	s0,0(sp)
    80006474:	0141                	addi	sp,sp,16
    80006476:	8082                	ret

0000000080006478 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006478:	1141                	addi	sp,sp,-16
    8000647a:	e406                	sd	ra,8(sp)
    8000647c:	e022                	sd	s0,0(sp)
    8000647e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006480:	ffffc097          	auipc	ra,0xffffc
    80006484:	910080e7          	jalr	-1776(ra) # 80001d90 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006488:	00d5179b          	slliw	a5,a0,0xd
    8000648c:	0c201537          	lui	a0,0xc201
    80006490:	953e                	add	a0,a0,a5
  return irq;
}
    80006492:	4148                	lw	a0,4(a0)
    80006494:	60a2                	ld	ra,8(sp)
    80006496:	6402                	ld	s0,0(sp)
    80006498:	0141                	addi	sp,sp,16
    8000649a:	8082                	ret

000000008000649c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000649c:	1101                	addi	sp,sp,-32
    8000649e:	ec06                	sd	ra,24(sp)
    800064a0:	e822                	sd	s0,16(sp)
    800064a2:	e426                	sd	s1,8(sp)
    800064a4:	1000                	addi	s0,sp,32
    800064a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	8e8080e7          	jalr	-1816(ra) # 80001d90 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064b0:	00d5151b          	slliw	a0,a0,0xd
    800064b4:	0c2017b7          	lui	a5,0xc201
    800064b8:	97aa                	add	a5,a5,a0
    800064ba:	c3c4                	sw	s1,4(a5)
}
    800064bc:	60e2                	ld	ra,24(sp)
    800064be:	6442                	ld	s0,16(sp)
    800064c0:	64a2                	ld	s1,8(sp)
    800064c2:	6105                	addi	sp,sp,32
    800064c4:	8082                	ret

00000000800064c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064c6:	1141                	addi	sp,sp,-16
    800064c8:	e406                	sd	ra,8(sp)
    800064ca:	e022                	sd	s0,0(sp)
    800064cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800064ce:	479d                	li	a5,7
    800064d0:	06a7c963          	blt	a5,a0,80006542 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800064d4:	0001d797          	auipc	a5,0x1d
    800064d8:	b2c78793          	addi	a5,a5,-1236 # 80023000 <disk>
    800064dc:	00a78733          	add	a4,a5,a0
    800064e0:	6789                	lui	a5,0x2
    800064e2:	97ba                	add	a5,a5,a4
    800064e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800064e8:	e7ad                	bnez	a5,80006552 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064ea:	00451793          	slli	a5,a0,0x4
    800064ee:	0001f717          	auipc	a4,0x1f
    800064f2:	b1270713          	addi	a4,a4,-1262 # 80025000 <disk+0x2000>
    800064f6:	6314                	ld	a3,0(a4)
    800064f8:	96be                	add	a3,a3,a5
    800064fa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800064fe:	6314                	ld	a3,0(a4)
    80006500:	96be                	add	a3,a3,a5
    80006502:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006506:	6314                	ld	a3,0(a4)
    80006508:	96be                	add	a3,a3,a5
    8000650a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000650e:	6318                	ld	a4,0(a4)
    80006510:	97ba                	add	a5,a5,a4
    80006512:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006516:	0001d797          	auipc	a5,0x1d
    8000651a:	aea78793          	addi	a5,a5,-1302 # 80023000 <disk>
    8000651e:	97aa                	add	a5,a5,a0
    80006520:	6509                	lui	a0,0x2
    80006522:	953e                	add	a0,a0,a5
    80006524:	4785                	li	a5,1
    80006526:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000652a:	0001f517          	auipc	a0,0x1f
    8000652e:	aee50513          	addi	a0,a0,-1298 # 80025018 <disk+0x2018>
    80006532:	ffffc097          	auipc	ra,0xffffc
    80006536:	332080e7          	jalr	818(ra) # 80002864 <wakeup>
}
    8000653a:	60a2                	ld	ra,8(sp)
    8000653c:	6402                	ld	s0,0(sp)
    8000653e:	0141                	addi	sp,sp,16
    80006540:	8082                	ret
    panic("free_desc 1");
    80006542:	00002517          	auipc	a0,0x2
    80006546:	2d650513          	addi	a0,a0,726 # 80008818 <syscalls+0x338>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	ff4080e7          	jalr	-12(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006552:	00002517          	auipc	a0,0x2
    80006556:	2d650513          	addi	a0,a0,726 # 80008828 <syscalls+0x348>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	fe4080e7          	jalr	-28(ra) # 8000053e <panic>

0000000080006562 <virtio_disk_init>:
{
    80006562:	1101                	addi	sp,sp,-32
    80006564:	ec06                	sd	ra,24(sp)
    80006566:	e822                	sd	s0,16(sp)
    80006568:	e426                	sd	s1,8(sp)
    8000656a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000656c:	00002597          	auipc	a1,0x2
    80006570:	2cc58593          	addi	a1,a1,716 # 80008838 <syscalls+0x358>
    80006574:	0001f517          	auipc	a0,0x1f
    80006578:	bb450513          	addi	a0,a0,-1100 # 80025128 <disk+0x2128>
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	5d8080e7          	jalr	1496(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006584:	100017b7          	lui	a5,0x10001
    80006588:	4398                	lw	a4,0(a5)
    8000658a:	2701                	sext.w	a4,a4
    8000658c:	747277b7          	lui	a5,0x74727
    80006590:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006594:	0ef71163          	bne	a4,a5,80006676 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006598:	100017b7          	lui	a5,0x10001
    8000659c:	43dc                	lw	a5,4(a5)
    8000659e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065a0:	4705                	li	a4,1
    800065a2:	0ce79a63          	bne	a5,a4,80006676 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065a6:	100017b7          	lui	a5,0x10001
    800065aa:	479c                	lw	a5,8(a5)
    800065ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065ae:	4709                	li	a4,2
    800065b0:	0ce79363          	bne	a5,a4,80006676 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065b4:	100017b7          	lui	a5,0x10001
    800065b8:	47d8                	lw	a4,12(a5)
    800065ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065bc:	554d47b7          	lui	a5,0x554d4
    800065c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065c4:	0af71963          	bne	a4,a5,80006676 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065c8:	100017b7          	lui	a5,0x10001
    800065cc:	4705                	li	a4,1
    800065ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065d0:	470d                	li	a4,3
    800065d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800065d6:	c7ffe737          	lui	a4,0xc7ffe
    800065da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800065de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800065e0:	2701                	sext.w	a4,a4
    800065e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065e4:	472d                	li	a4,11
    800065e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065e8:	473d                	li	a4,15
    800065ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800065ec:	6705                	lui	a4,0x1
    800065ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800065f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065f4:	5bdc                	lw	a5,52(a5)
    800065f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800065f8:	c7d9                	beqz	a5,80006686 <virtio_disk_init+0x124>
  if(max < NUM)
    800065fa:	471d                	li	a4,7
    800065fc:	08f77d63          	bgeu	a4,a5,80006696 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006600:	100014b7          	lui	s1,0x10001
    80006604:	47a1                	li	a5,8
    80006606:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006608:	6609                	lui	a2,0x2
    8000660a:	4581                	li	a1,0
    8000660c:	0001d517          	auipc	a0,0x1d
    80006610:	9f450513          	addi	a0,a0,-1548 # 80023000 <disk>
    80006614:	ffffa097          	auipc	ra,0xffffa
    80006618:	6f0080e7          	jalr	1776(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000661c:	0001d717          	auipc	a4,0x1d
    80006620:	9e470713          	addi	a4,a4,-1564 # 80023000 <disk>
    80006624:	00c75793          	srli	a5,a4,0xc
    80006628:	2781                	sext.w	a5,a5
    8000662a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000662c:	0001f797          	auipc	a5,0x1f
    80006630:	9d478793          	addi	a5,a5,-1580 # 80025000 <disk+0x2000>
    80006634:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006636:	0001d717          	auipc	a4,0x1d
    8000663a:	a4a70713          	addi	a4,a4,-1462 # 80023080 <disk+0x80>
    8000663e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006640:	0001e717          	auipc	a4,0x1e
    80006644:	9c070713          	addi	a4,a4,-1600 # 80024000 <disk+0x1000>
    80006648:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000664a:	4705                	li	a4,1
    8000664c:	00e78c23          	sb	a4,24(a5)
    80006650:	00e78ca3          	sb	a4,25(a5)
    80006654:	00e78d23          	sb	a4,26(a5)
    80006658:	00e78da3          	sb	a4,27(a5)
    8000665c:	00e78e23          	sb	a4,28(a5)
    80006660:	00e78ea3          	sb	a4,29(a5)
    80006664:	00e78f23          	sb	a4,30(a5)
    80006668:	00e78fa3          	sb	a4,31(a5)
}
    8000666c:	60e2                	ld	ra,24(sp)
    8000666e:	6442                	ld	s0,16(sp)
    80006670:	64a2                	ld	s1,8(sp)
    80006672:	6105                	addi	sp,sp,32
    80006674:	8082                	ret
    panic("could not find virtio disk");
    80006676:	00002517          	auipc	a0,0x2
    8000667a:	1d250513          	addi	a0,a0,466 # 80008848 <syscalls+0x368>
    8000667e:	ffffa097          	auipc	ra,0xffffa
    80006682:	ec0080e7          	jalr	-320(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006686:	00002517          	auipc	a0,0x2
    8000668a:	1e250513          	addi	a0,a0,482 # 80008868 <syscalls+0x388>
    8000668e:	ffffa097          	auipc	ra,0xffffa
    80006692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006696:	00002517          	auipc	a0,0x2
    8000669a:	1f250513          	addi	a0,a0,498 # 80008888 <syscalls+0x3a8>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>

00000000800066a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066a6:	7159                	addi	sp,sp,-112
    800066a8:	f486                	sd	ra,104(sp)
    800066aa:	f0a2                	sd	s0,96(sp)
    800066ac:	eca6                	sd	s1,88(sp)
    800066ae:	e8ca                	sd	s2,80(sp)
    800066b0:	e4ce                	sd	s3,72(sp)
    800066b2:	e0d2                	sd	s4,64(sp)
    800066b4:	fc56                	sd	s5,56(sp)
    800066b6:	f85a                	sd	s6,48(sp)
    800066b8:	f45e                	sd	s7,40(sp)
    800066ba:	f062                	sd	s8,32(sp)
    800066bc:	ec66                	sd	s9,24(sp)
    800066be:	e86a                	sd	s10,16(sp)
    800066c0:	1880                	addi	s0,sp,112
    800066c2:	892a                	mv	s2,a0
    800066c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066c6:	00c52c83          	lw	s9,12(a0)
    800066ca:	001c9c9b          	slliw	s9,s9,0x1
    800066ce:	1c82                	slli	s9,s9,0x20
    800066d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800066d4:	0001f517          	auipc	a0,0x1f
    800066d8:	a5450513          	addi	a0,a0,-1452 # 80025128 <disk+0x2128>
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	508080e7          	jalr	1288(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800066e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800066e8:	0001db97          	auipc	s7,0x1d
    800066ec:	918b8b93          	addi	s7,s7,-1768 # 80023000 <disk>
    800066f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800066f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800066f4:	8a4e                	mv	s4,s3
    800066f6:	a051                	j	8000677a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800066f8:	00fb86b3          	add	a3,s7,a5
    800066fc:	96da                	add	a3,a3,s6
    800066fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006702:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006704:	0207c563          	bltz	a5,8000672e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006708:	2485                	addiw	s1,s1,1
    8000670a:	0711                	addi	a4,a4,4
    8000670c:	25548063          	beq	s1,s5,8000694c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006710:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006712:	0001f697          	auipc	a3,0x1f
    80006716:	90668693          	addi	a3,a3,-1786 # 80025018 <disk+0x2018>
    8000671a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000671c:	0006c583          	lbu	a1,0(a3)
    80006720:	fde1                	bnez	a1,800066f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006722:	2785                	addiw	a5,a5,1
    80006724:	0685                	addi	a3,a3,1
    80006726:	ff879be3          	bne	a5,s8,8000671c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000672a:	57fd                	li	a5,-1
    8000672c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000672e:	02905a63          	blez	s1,80006762 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006732:	f9042503          	lw	a0,-112(s0)
    80006736:	00000097          	auipc	ra,0x0
    8000673a:	d90080e7          	jalr	-624(ra) # 800064c6 <free_desc>
      for(int j = 0; j < i; j++)
    8000673e:	4785                	li	a5,1
    80006740:	0297d163          	bge	a5,s1,80006762 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006744:	f9442503          	lw	a0,-108(s0)
    80006748:	00000097          	auipc	ra,0x0
    8000674c:	d7e080e7          	jalr	-642(ra) # 800064c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006750:	4789                	li	a5,2
    80006752:	0097d863          	bge	a5,s1,80006762 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006756:	f9842503          	lw	a0,-104(s0)
    8000675a:	00000097          	auipc	ra,0x0
    8000675e:	d6c080e7          	jalr	-660(ra) # 800064c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006762:	0001f597          	auipc	a1,0x1f
    80006766:	9c658593          	addi	a1,a1,-1594 # 80025128 <disk+0x2128>
    8000676a:	0001f517          	auipc	a0,0x1f
    8000676e:	8ae50513          	addi	a0,a0,-1874 # 80025018 <disk+0x2018>
    80006772:	ffffc097          	auipc	ra,0xffffc
    80006776:	f3a080e7          	jalr	-198(ra) # 800026ac <sleep>
  for(int i = 0; i < 3; i++){
    8000677a:	f9040713          	addi	a4,s0,-112
    8000677e:	84ce                	mv	s1,s3
    80006780:	bf41                	j	80006710 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006782:	20058713          	addi	a4,a1,512
    80006786:	00471693          	slli	a3,a4,0x4
    8000678a:	0001d717          	auipc	a4,0x1d
    8000678e:	87670713          	addi	a4,a4,-1930 # 80023000 <disk>
    80006792:	9736                	add	a4,a4,a3
    80006794:	4685                	li	a3,1
    80006796:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000679a:	20058713          	addi	a4,a1,512
    8000679e:	00471693          	slli	a3,a4,0x4
    800067a2:	0001d717          	auipc	a4,0x1d
    800067a6:	85e70713          	addi	a4,a4,-1954 # 80023000 <disk>
    800067aa:	9736                	add	a4,a4,a3
    800067ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800067b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800067b4:	7679                	lui	a2,0xffffe
    800067b6:	963e                	add	a2,a2,a5
    800067b8:	0001f697          	auipc	a3,0x1f
    800067bc:	84868693          	addi	a3,a3,-1976 # 80025000 <disk+0x2000>
    800067c0:	6298                	ld	a4,0(a3)
    800067c2:	9732                	add	a4,a4,a2
    800067c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067c6:	6298                	ld	a4,0(a3)
    800067c8:	9732                	add	a4,a4,a2
    800067ca:	4541                	li	a0,16
    800067cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067ce:	6298                	ld	a4,0(a3)
    800067d0:	9732                	add	a4,a4,a2
    800067d2:	4505                	li	a0,1
    800067d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800067d8:	f9442703          	lw	a4,-108(s0)
    800067dc:	6288                	ld	a0,0(a3)
    800067de:	962a                	add	a2,a2,a0
    800067e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800067e4:	0712                	slli	a4,a4,0x4
    800067e6:	6290                	ld	a2,0(a3)
    800067e8:	963a                	add	a2,a2,a4
    800067ea:	05890513          	addi	a0,s2,88
    800067ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800067f0:	6294                	ld	a3,0(a3)
    800067f2:	96ba                	add	a3,a3,a4
    800067f4:	40000613          	li	a2,1024
    800067f8:	c690                	sw	a2,8(a3)
  if(write)
    800067fa:	140d0063          	beqz	s10,8000693a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800067fe:	0001f697          	auipc	a3,0x1f
    80006802:	8026b683          	ld	a3,-2046(a3) # 80025000 <disk+0x2000>
    80006806:	96ba                	add	a3,a3,a4
    80006808:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000680c:	0001c817          	auipc	a6,0x1c
    80006810:	7f480813          	addi	a6,a6,2036 # 80023000 <disk>
    80006814:	0001e517          	auipc	a0,0x1e
    80006818:	7ec50513          	addi	a0,a0,2028 # 80025000 <disk+0x2000>
    8000681c:	6114                	ld	a3,0(a0)
    8000681e:	96ba                	add	a3,a3,a4
    80006820:	00c6d603          	lhu	a2,12(a3)
    80006824:	00166613          	ori	a2,a2,1
    80006828:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000682c:	f9842683          	lw	a3,-104(s0)
    80006830:	6110                	ld	a2,0(a0)
    80006832:	9732                	add	a4,a4,a2
    80006834:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006838:	20058613          	addi	a2,a1,512
    8000683c:	0612                	slli	a2,a2,0x4
    8000683e:	9642                	add	a2,a2,a6
    80006840:	577d                	li	a4,-1
    80006842:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006846:	00469713          	slli	a4,a3,0x4
    8000684a:	6114                	ld	a3,0(a0)
    8000684c:	96ba                	add	a3,a3,a4
    8000684e:	03078793          	addi	a5,a5,48
    80006852:	97c2                	add	a5,a5,a6
    80006854:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006856:	611c                	ld	a5,0(a0)
    80006858:	97ba                	add	a5,a5,a4
    8000685a:	4685                	li	a3,1
    8000685c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000685e:	611c                	ld	a5,0(a0)
    80006860:	97ba                	add	a5,a5,a4
    80006862:	4809                	li	a6,2
    80006864:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006868:	611c                	ld	a5,0(a0)
    8000686a:	973e                	add	a4,a4,a5
    8000686c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006870:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006874:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006878:	6518                	ld	a4,8(a0)
    8000687a:	00275783          	lhu	a5,2(a4)
    8000687e:	8b9d                	andi	a5,a5,7
    80006880:	0786                	slli	a5,a5,0x1
    80006882:	97ba                	add	a5,a5,a4
    80006884:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006888:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000688c:	6518                	ld	a4,8(a0)
    8000688e:	00275783          	lhu	a5,2(a4)
    80006892:	2785                	addiw	a5,a5,1
    80006894:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006898:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000689c:	100017b7          	lui	a5,0x10001
    800068a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068a4:	00492703          	lw	a4,4(s2)
    800068a8:	4785                	li	a5,1
    800068aa:	02f71163          	bne	a4,a5,800068cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800068ae:	0001f997          	auipc	s3,0x1f
    800068b2:	87a98993          	addi	s3,s3,-1926 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800068b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800068b8:	85ce                	mv	a1,s3
    800068ba:	854a                	mv	a0,s2
    800068bc:	ffffc097          	auipc	ra,0xffffc
    800068c0:	df0080e7          	jalr	-528(ra) # 800026ac <sleep>
  while(b->disk == 1) {
    800068c4:	00492783          	lw	a5,4(s2)
    800068c8:	fe9788e3          	beq	a5,s1,800068b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800068cc:	f9042903          	lw	s2,-112(s0)
    800068d0:	20090793          	addi	a5,s2,512
    800068d4:	00479713          	slli	a4,a5,0x4
    800068d8:	0001c797          	auipc	a5,0x1c
    800068dc:	72878793          	addi	a5,a5,1832 # 80023000 <disk>
    800068e0:	97ba                	add	a5,a5,a4
    800068e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800068e6:	0001e997          	auipc	s3,0x1e
    800068ea:	71a98993          	addi	s3,s3,1818 # 80025000 <disk+0x2000>
    800068ee:	00491713          	slli	a4,s2,0x4
    800068f2:	0009b783          	ld	a5,0(s3)
    800068f6:	97ba                	add	a5,a5,a4
    800068f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068fc:	854a                	mv	a0,s2
    800068fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006902:	00000097          	auipc	ra,0x0
    80006906:	bc4080e7          	jalr	-1084(ra) # 800064c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000690a:	8885                	andi	s1,s1,1
    8000690c:	f0ed                	bnez	s1,800068ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000690e:	0001f517          	auipc	a0,0x1f
    80006912:	81a50513          	addi	a0,a0,-2022 # 80025128 <disk+0x2128>
    80006916:	ffffa097          	auipc	ra,0xffffa
    8000691a:	394080e7          	jalr	916(ra) # 80000caa <release>
}
    8000691e:	70a6                	ld	ra,104(sp)
    80006920:	7406                	ld	s0,96(sp)
    80006922:	64e6                	ld	s1,88(sp)
    80006924:	6946                	ld	s2,80(sp)
    80006926:	69a6                	ld	s3,72(sp)
    80006928:	6a06                	ld	s4,64(sp)
    8000692a:	7ae2                	ld	s5,56(sp)
    8000692c:	7b42                	ld	s6,48(sp)
    8000692e:	7ba2                	ld	s7,40(sp)
    80006930:	7c02                	ld	s8,32(sp)
    80006932:	6ce2                	ld	s9,24(sp)
    80006934:	6d42                	ld	s10,16(sp)
    80006936:	6165                	addi	sp,sp,112
    80006938:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000693a:	0001e697          	auipc	a3,0x1e
    8000693e:	6c66b683          	ld	a3,1734(a3) # 80025000 <disk+0x2000>
    80006942:	96ba                	add	a3,a3,a4
    80006944:	4609                	li	a2,2
    80006946:	00c69623          	sh	a2,12(a3)
    8000694a:	b5c9                	j	8000680c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000694c:	f9042583          	lw	a1,-112(s0)
    80006950:	20058793          	addi	a5,a1,512
    80006954:	0792                	slli	a5,a5,0x4
    80006956:	0001c517          	auipc	a0,0x1c
    8000695a:	75250513          	addi	a0,a0,1874 # 800230a8 <disk+0xa8>
    8000695e:	953e                	add	a0,a0,a5
  if(write)
    80006960:	e20d11e3          	bnez	s10,80006782 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006964:	20058713          	addi	a4,a1,512
    80006968:	00471693          	slli	a3,a4,0x4
    8000696c:	0001c717          	auipc	a4,0x1c
    80006970:	69470713          	addi	a4,a4,1684 # 80023000 <disk>
    80006974:	9736                	add	a4,a4,a3
    80006976:	0a072423          	sw	zero,168(a4)
    8000697a:	b505                	j	8000679a <virtio_disk_rw+0xf4>

000000008000697c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000697c:	1101                	addi	sp,sp,-32
    8000697e:	ec06                	sd	ra,24(sp)
    80006980:	e822                	sd	s0,16(sp)
    80006982:	e426                	sd	s1,8(sp)
    80006984:	e04a                	sd	s2,0(sp)
    80006986:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006988:	0001e517          	auipc	a0,0x1e
    8000698c:	7a050513          	addi	a0,a0,1952 # 80025128 <disk+0x2128>
    80006990:	ffffa097          	auipc	ra,0xffffa
    80006994:	254080e7          	jalr	596(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006998:	10001737          	lui	a4,0x10001
    8000699c:	533c                	lw	a5,96(a4)
    8000699e:	8b8d                	andi	a5,a5,3
    800069a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069a6:	0001e797          	auipc	a5,0x1e
    800069aa:	65a78793          	addi	a5,a5,1626 # 80025000 <disk+0x2000>
    800069ae:	6b94                	ld	a3,16(a5)
    800069b0:	0207d703          	lhu	a4,32(a5)
    800069b4:	0026d783          	lhu	a5,2(a3)
    800069b8:	06f70163          	beq	a4,a5,80006a1a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069bc:	0001c917          	auipc	s2,0x1c
    800069c0:	64490913          	addi	s2,s2,1604 # 80023000 <disk>
    800069c4:	0001e497          	auipc	s1,0x1e
    800069c8:	63c48493          	addi	s1,s1,1596 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800069cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069d0:	6898                	ld	a4,16(s1)
    800069d2:	0204d783          	lhu	a5,32(s1)
    800069d6:	8b9d                	andi	a5,a5,7
    800069d8:	078e                	slli	a5,a5,0x3
    800069da:	97ba                	add	a5,a5,a4
    800069dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069de:	20078713          	addi	a4,a5,512
    800069e2:	0712                	slli	a4,a4,0x4
    800069e4:	974a                	add	a4,a4,s2
    800069e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800069ea:	e731                	bnez	a4,80006a36 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069ec:	20078793          	addi	a5,a5,512
    800069f0:	0792                	slli	a5,a5,0x4
    800069f2:	97ca                	add	a5,a5,s2
    800069f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800069f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069fa:	ffffc097          	auipc	ra,0xffffc
    800069fe:	e6a080e7          	jalr	-406(ra) # 80002864 <wakeup>

    disk.used_idx += 1;
    80006a02:	0204d783          	lhu	a5,32(s1)
    80006a06:	2785                	addiw	a5,a5,1
    80006a08:	17c2                	slli	a5,a5,0x30
    80006a0a:	93c1                	srli	a5,a5,0x30
    80006a0c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a10:	6898                	ld	a4,16(s1)
    80006a12:	00275703          	lhu	a4,2(a4)
    80006a16:	faf71be3          	bne	a4,a5,800069cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a1a:	0001e517          	auipc	a0,0x1e
    80006a1e:	70e50513          	addi	a0,a0,1806 # 80025128 <disk+0x2128>
    80006a22:	ffffa097          	auipc	ra,0xffffa
    80006a26:	288080e7          	jalr	648(ra) # 80000caa <release>
}
    80006a2a:	60e2                	ld	ra,24(sp)
    80006a2c:	6442                	ld	s0,16(sp)
    80006a2e:	64a2                	ld	s1,8(sp)
    80006a30:	6902                	ld	s2,0(sp)
    80006a32:	6105                	addi	sp,sp,32
    80006a34:	8082                	ret
      panic("virtio_disk_intr status");
    80006a36:	00002517          	auipc	a0,0x2
    80006a3a:	e7250513          	addi	a0,a0,-398 # 800088a8 <syscalls+0x3c8>
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>

0000000080006a46 <cas>:
    80006a46:	100522af          	lr.w	t0,(a0)
    80006a4a:	00b29563          	bne	t0,a1,80006a54 <fail>
    80006a4e:	18c5252f          	sc.w	a0,a2,(a0)
    80006a52:	8082                	ret

0000000080006a54 <fail>:
    80006a54:	4505                	li	a0,1
    80006a56:	8082                	ret
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
