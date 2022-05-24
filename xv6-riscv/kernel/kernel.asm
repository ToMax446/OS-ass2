
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
    80000068:	31c78793          	addi	a5,a5,796 # 80006380 <timervec>
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
    80000130:	a90080e7          	jalr	-1392(ra) # 80002bbc <either_copyin>
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
    800001c8:	c18080e7          	jalr	-1000(ra) # 80001ddc <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	4ca080e7          	jalr	1226(ra) # 8000269e <sleep>
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
    80000214:	956080e7          	jalr	-1706(ra) # 80002b66 <either_copyout>
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
    800002f6:	920080e7          	jalr	-1760(ra) # 80002c12 <procdump>
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
    8000044a:	400080e7          	jalr	1024(ra) # 80002846 <wakeup>
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
    800008a4:	fa6080e7          	jalr	-90(ra) # 80002846 <wakeup>
    
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
    80000930:	d72080e7          	jalr	-654(ra) # 8000269e <sleep>
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
    80000b82:	23a080e7          	jalr	570(ra) # 80001db8 <mycpu>
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
    80000bb4:	208080e7          	jalr	520(ra) # 80001db8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	1fc080e7          	jalr	508(ra) # 80001db8 <mycpu>
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
    80000bd8:	1e4080e7          	jalr	484(ra) # 80001db8 <mycpu>
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
    80000c18:	1a4080e7          	jalr	420(ra) # 80001db8 <mycpu>
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
    80000c56:	166080e7          	jalr	358(ra) # 80001db8 <mycpu>
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
    80000ebe:	eee080e7          	jalr	-274(ra) # 80001da8 <cpuid>
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
    80000eda:	ed2080e7          	jalr	-302(ra) # 80001da8 <cpuid>
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
    80000efc:	eee080e7          	jalr	-274(ra) # 80002de6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	4c0080e7          	jalr	1216(ra) # 800063c0 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	522080e7          	jalr	1314(ra) # 8000242a <scheduler>
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
    80000f6c:	cd0080e7          	jalr	-816(ra) # 80001c38 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	e4e080e7          	jalr	-434(ra) # 80002dbe <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	e6e080e7          	jalr	-402(ra) # 80002de6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	42a080e7          	jalr	1066(ra) # 800063aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	438080e7          	jalr	1080(ra) # 800063c0 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	614080e7          	jalr	1556(ra) # 800035a4 <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	ca4080e7          	jalr	-860(ra) # 80003c3c <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	c4e080e7          	jalr	-946(ra) # 80004bee <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	53a080e7          	jalr	1338(ra) # 800064e2 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	1ca080e7          	jalr	458(ra) # 8000217a <userinit>
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
    80001268:	93e080e7          	jalr	-1730(ra) # 80001ba2 <proc_mapstacks>
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
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

int leastUsedCPU(){ // get the CPU with least amount of processes
    80001862:	1141                	addi	sp,sp,-16
    80001864:	e422                	sd	s0,8(sp)
    80001866:	0800                	addi	s0,sp,16
  uint64 min = cpus[0].admittedProcs;
    80001868:	00010797          	auipc	a5,0x10
    8000186c:	a3878793          	addi	a5,a5,-1480 # 800112a0 <cpus>
    80001870:	63d4                	ld	a3,128(a5)
  int idMin = 0;
    80001872:	4501                	li	a0,0
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    80001874:	00010617          	auipc	a2,0x10
    80001878:	e6c60613          	addi	a2,a2,-404 # 800116e0 <cpus_ll>
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
    }     
  }
  return idMin;
  ;
}
    800018a4:	6422                	ld	s0,8(sp)
    800018a6:	0141                	addi	sp,sp,16
    800018a8:	8082                	ret

00000000800018aa <remove_from_list>:


int
remove_from_list(int p_index, int *list, struct spinlock *linked_list_lock){
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
  acquire(linked_list_lock);
    800018ce:	8532                	mv	a0,a2
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	314080e7          	jalr	788(ra) # 80000be4 <acquire>
  if(*list == -1){
    800018d8:	000a2903          	lw	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018dc:	57fd                	li	a5,-1
    800018de:	06f90663          	beq	s2,a5,8000194a <remove_from_list+0xa0>
    release(linked_list_lock);
    return -1;
  }
  struct proc *p = 0;
  if(*list == p_index){
    800018e2:	07390b63          	beq	s2,s3,80001958 <remove_from_list+0xae>
    *list = p->next;
    release(&p->linked_list_lock);
    release(linked_list_lock);
    return 0;
  }
  release(linked_list_lock);
    800018e6:	8526                	mv	a0,s1
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	3c2080e7          	jalr	962(ra) # 80000caa <release>
  int inList = 0;
  struct proc *pred_proc = &proc[*list];
    800018f0:	000a2503          	lw	a0,0(s4)
    800018f4:	18800493          	li	s1,392
    800018f8:	02950533          	mul	a0,a0,s1
    800018fc:	00010917          	auipc	s2,0x10
    80001900:	f7c90913          	addi	s2,s2,-132 # 80011878 <proc>
    80001904:	01250db3          	add	s11,a0,s2
  acquire(&pred_proc->linked_list_lock);
    80001908:	04050513          	addi	a0,a0,64
    8000190c:	954a                	add	a0,a0,s2
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	2d6080e7          	jalr	726(ra) # 80000be4 <acquire>
  p = &proc[pred_proc->next];
    80001916:	03cda503          	lw	a0,60(s11)
    8000191a:	2501                	sext.w	a0,a0
    8000191c:	02950533          	mul	a0,a0,s1
    80001920:	012504b3          	add	s1,a0,s2
  acquire(&p->linked_list_lock);
    80001924:	04050513          	addi	a0,a0,64
    80001928:	954a                	add	a0,a0,s2
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	2ba080e7          	jalr	698(ra) # 80000be4 <acquire>
  int done = 0;
    80001932:	4901                	li	s2,0
  int inList = 0;
    80001934:	4d01                	li	s10,0
  while(!done){
    if (pred_proc->next == -1){
    80001936:	5afd                	li	s5,-1
      done = 1;
    80001938:	4c85                	li	s9,1
    8000193a:	8c66                	mv	s8,s9
    8000193c:	18800b93          	li	s7,392
      pred_proc->next = p->next;
      continue;
    }
    release(&pred_proc->linked_list_lock);
    pred_proc = p;
    p = &proc[p->next];
    80001940:	00010a17          	auipc	s4,0x10
    80001944:	f38a0a13          	addi	s4,s4,-200 # 80011878 <proc>
  while(!done){
    80001948:	a8b5                	j	800019c4 <remove_from_list+0x11a>
    release(linked_list_lock);
    8000194a:	8526                	mv	a0,s1
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	35e080e7          	jalr	862(ra) # 80000caa <release>
    return -1;
    80001954:	89ca                	mv	s3,s2
    80001956:	a845                	j	80001a06 <remove_from_list+0x15c>
    acquire(&p->linked_list_lock);
    80001958:	18800a93          	li	s5,392
    8000195c:	035989b3          	mul	s3,s3,s5
    80001960:	04098913          	addi	s2,s3,64 # 1040 <_entry-0x7fffefc0>
    80001964:	00010a97          	auipc	s5,0x10
    80001968:	f14a8a93          	addi	s5,s5,-236 # 80011878 <proc>
    8000196c:	9956                	add	s2,s2,s5
    8000196e:	854a                	mv	a0,s2
    80001970:	fffff097          	auipc	ra,0xfffff
    80001974:	274080e7          	jalr	628(ra) # 80000be4 <acquire>
    *list = p->next;
    80001978:	9ace                	add	s5,s5,s3
    8000197a:	03caa783          	lw	a5,60(s5)
    8000197e:	00fa2023          	sw	a5,0(s4)
    release(&p->linked_list_lock);
    80001982:	854a                	mv	a0,s2
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	326080e7          	jalr	806(ra) # 80000caa <release>
    release(linked_list_lock);
    8000198c:	8526                	mv	a0,s1
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	31c080e7          	jalr	796(ra) # 80000caa <release>
    return 0;
    80001996:	4981                	li	s3,0
    80001998:	a0bd                	j	80001a06 <remove_from_list+0x15c>
    release(&pred_proc->linked_list_lock);
    8000199a:	040d8513          	addi	a0,s11,64
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	30c080e7          	jalr	780(ra) # 80000caa <release>
    p = &proc[p->next];
    800019a6:	5cdc                	lw	a5,60(s1)
    800019a8:	2781                	sext.w	a5,a5
    800019aa:	037787b3          	mul	a5,a5,s7
    800019ae:	01478b33          	add	s6,a5,s4
    acquire(&p->linked_list_lock);
    800019b2:	04078513          	addi	a0,a5,64
    800019b6:	9552                	add	a0,a0,s4
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	22c080e7          	jalr	556(ra) # 80000be4 <acquire>
    800019c0:	8da6                	mv	s11,s1
    p = &proc[p->next];
    800019c2:	84da                	mv	s1,s6
  while(!done){
    800019c4:	02091363          	bnez	s2,800019ea <remove_from_list+0x140>
    if (pred_proc->next == -1){
    800019c8:	03cda783          	lw	a5,60(s11)
    800019cc:	2781                	sext.w	a5,a5
    800019ce:	01578b63          	beq	a5,s5,800019e4 <remove_from_list+0x13a>
    if(p->index == p_index){
    800019d2:	5c9c                	lw	a5,56(s1)
    800019d4:	fd3793e3          	bne	a5,s3,8000199a <remove_from_list+0xf0>
      pred_proc->next = p->next;
    800019d8:	5cdc                	lw	a5,60(s1)
    800019da:	2781                	sext.w	a5,a5
    800019dc:	02fdae23          	sw	a5,60(s11)
      done = 1;
    800019e0:	8966                	mv	s2,s9
      continue;
    800019e2:	b7cd                	j	800019c4 <remove_from_list+0x11a>
      done = 1;
    800019e4:	8962                	mv	s2,s8
      inList = 1;
    800019e6:	8d62                	mv	s10,s8
    800019e8:	bff1                	j	800019c4 <remove_from_list+0x11a>
  }
  release(&p->linked_list_lock);
    800019ea:	04048513          	addi	a0,s1,64
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	2bc080e7          	jalr	700(ra) # 80000caa <release>
  release(&pred_proc->linked_list_lock); 
    800019f6:	040d8513          	addi	a0,s11,64
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	2b0080e7          	jalr	688(ra) # 80000caa <release>
  if (inList)
    80001a02:	020d1263          	bnez	s10,80001a26 <remove_from_list+0x17c>
    return -1;
  return p_index;
}
    80001a06:	854e                	mv	a0,s3
    80001a08:	70a6                	ld	ra,104(sp)
    80001a0a:	7406                	ld	s0,96(sp)
    80001a0c:	64e6                	ld	s1,88(sp)
    80001a0e:	6946                	ld	s2,80(sp)
    80001a10:	69a6                	ld	s3,72(sp)
    80001a12:	6a06                	ld	s4,64(sp)
    80001a14:	7ae2                	ld	s5,56(sp)
    80001a16:	7b42                	ld	s6,48(sp)
    80001a18:	7ba2                	ld	s7,40(sp)
    80001a1a:	7c02                	ld	s8,32(sp)
    80001a1c:	6ce2                	ld	s9,24(sp)
    80001a1e:	6d42                	ld	s10,16(sp)
    80001a20:	6da2                	ld	s11,8(sp)
    80001a22:	6165                	addi	sp,sp,112
    80001a24:	8082                	ret
    return -1;
    80001a26:	59fd                	li	s3,-1
    80001a28:	bff9                	j	80001a06 <remove_from_list+0x15c>

0000000080001a2a <insert_cs>:

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001a2a:	7139                	addi	sp,sp,-64
    80001a2c:	fc06                	sd	ra,56(sp)
    80001a2e:	f822                	sd	s0,48(sp)
    80001a30:	f426                	sd	s1,40(sp)
    80001a32:	f04a                	sd	s2,32(sp)
    80001a34:	ec4e                	sd	s3,24(sp)
    80001a36:	e852                	sd	s4,16(sp)
    80001a38:	e456                	sd	s5,8(sp)
    80001a3a:	e05a                	sd	s6,0(sp)
    80001a3c:	0080                	addi	s0,sp,64
    80001a3e:	892a                	mv	s2,a0
    80001a40:	8aae                	mv	s5,a1
  int curr = pred->index; 
  struct spinlock *pred_lock;
  while (curr != -1) {
    80001a42:	5d18                	lw	a4,56(a0)
    80001a44:	57fd                	li	a5,-1
    80001a46:	04f70a63          	beq	a4,a5,80001a9a <insert_cs+0x70>
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    if(pred->next!=-1){
    80001a4a:	59fd                	li	s3,-1
    80001a4c:	18800b13          	li	s6,392
      pred_lock=&pred->linked_list_lock; // caller acquired
      pred = &proc[pred->next];
    80001a50:	00010a17          	auipc	s4,0x10
    80001a54:	e28a0a13          	addi	s4,s4,-472 # 80011878 <proc>
    80001a58:	a81d                	j	80001a8e <insert_cs+0x64>
      pred_lock=&pred->linked_list_lock; // caller acquired
    80001a5a:	04090513          	addi	a0,s2,64
      pred = &proc[pred->next];
    80001a5e:	03c92483          	lw	s1,60(s2)
    80001a62:	2481                	sext.w	s1,s1
    80001a64:	036484b3          	mul	s1,s1,s6
    80001a68:	01448933          	add	s2,s1,s4
      release(pred_lock);
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	23e080e7          	jalr	574(ra) # 80000caa <release>
      acquire(&pred->linked_list_lock);
    80001a74:	04048493          	addi	s1,s1,64
    80001a78:	009a0533          	add	a0,s4,s1
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	168080e7          	jalr	360(ra) # 80000be4 <acquire>
    }
    curr = pred->next;
    80001a84:	03c92783          	lw	a5,60(s2)
    80001a88:	2781                	sext.w	a5,a5
  while (curr != -1) {
    80001a8a:	01378863          	beq	a5,s3,80001a9a <insert_cs+0x70>
    if(pred->next!=-1){
    80001a8e:	03c92783          	lw	a5,60(s2)
    80001a92:	2781                	sext.w	a5,a5
    80001a94:	ff3788e3          	beq	a5,s3,80001a84 <insert_cs+0x5a>
    80001a98:	b7c9                	j	80001a5a <insert_cs+0x30>
    }
    pred->next = p->index;
    80001a9a:	038aa783          	lw	a5,56(s5)
    80001a9e:	02f92e23          	sw	a5,60(s2)
    release(&pred->linked_list_lock);      
    80001aa2:	04090513          	addi	a0,s2,64
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	204080e7          	jalr	516(ra) # 80000caa <release>
    p->next=-1;
    80001aae:	57fd                	li	a5,-1
    80001ab0:	02faae23          	sw	a5,60(s5)
    return p->index;
}
    80001ab4:	038aa503          	lw	a0,56(s5)
    80001ab8:	70e2                	ld	ra,56(sp)
    80001aba:	7442                	ld	s0,48(sp)
    80001abc:	74a2                	ld	s1,40(sp)
    80001abe:	7902                	ld	s2,32(sp)
    80001ac0:	69e2                	ld	s3,24(sp)
    80001ac2:	6a42                	ld	s4,16(sp)
    80001ac4:	6aa2                	ld	s5,8(sp)
    80001ac6:	6b02                	ld	s6,0(sp)
    80001ac8:	6121                	addi	sp,sp,64
    80001aca:	8082                	ret

0000000080001acc <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock *lock_list){;
    80001acc:	7139                	addi	sp,sp,-64
    80001ace:	fc06                	sd	ra,56(sp)
    80001ad0:	f822                	sd	s0,48(sp)
    80001ad2:	f426                	sd	s1,40(sp)
    80001ad4:	f04a                	sd	s2,32(sp)
    80001ad6:	ec4e                	sd	s3,24(sp)
    80001ad8:	e852                	sd	s4,16(sp)
    80001ada:	e456                	sd	s5,8(sp)
    80001adc:	0080                	addi	s0,sp,64
    80001ade:	84aa                	mv	s1,a0
    80001ae0:	892e                	mv	s2,a1
    80001ae2:	89b2                	mv	s3,a2
  int ret=-1;
  acquire(lock_list);
    80001ae4:	8532                	mv	a0,a2
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	0fe080e7          	jalr	254(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001aee:	00092703          	lw	a4,0(s2)
    80001af2:	57fd                	li	a5,-1
    80001af4:	04f70d63          	beq	a4,a5,80001b4e <insert_to_list+0x82>
    release(&proc[p_index].linked_list_lock);
    ret = p_index;
    release(lock_list);
  }
  else{
    release(lock_list);
    80001af8:	854e                	mv	a0,s3
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	1b0080e7          	jalr	432(ra) # 80000caa <release>
    struct proc *pred;
    pred=&proc[*list];
    80001b02:	00092903          	lw	s2,0(s2)
    80001b06:	18800a13          	li	s4,392
    80001b0a:	03490933          	mul	s2,s2,s4
    acquire(&pred->linked_list_lock);
    80001b0e:	04090513          	addi	a0,s2,64
    80001b12:	00010997          	auipc	s3,0x10
    80001b16:	d6698993          	addi	s3,s3,-666 # 80011878 <proc>
    80001b1a:	954e                	add	a0,a0,s3
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	0c8080e7          	jalr	200(ra) # 80000be4 <acquire>
    ret = insert_cs(pred, &proc[p_index]);
    80001b24:	034485b3          	mul	a1,s1,s4
    80001b28:	95ce                	add	a1,a1,s3
    80001b2a:	01298533          	add	a0,s3,s2
    80001b2e:	00000097          	auipc	ra,0x0
    80001b32:	efc080e7          	jalr	-260(ra) # 80001a2a <insert_cs>
  }
if(ret == -1){
    80001b36:	57fd                	li	a5,-1
    80001b38:	04f50d63          	beq	a0,a5,80001b92 <insert_to_list+0xc6>
  panic("insert is failed");
}
return ret;
}
    80001b3c:	70e2                	ld	ra,56(sp)
    80001b3e:	7442                	ld	s0,48(sp)
    80001b40:	74a2                	ld	s1,40(sp)
    80001b42:	7902                	ld	s2,32(sp)
    80001b44:	69e2                	ld	s3,24(sp)
    80001b46:	6a42                	ld	s4,16(sp)
    80001b48:	6aa2                	ld	s5,8(sp)
    80001b4a:	6121                	addi	sp,sp,64
    80001b4c:	8082                	ret
    *list=p_index;
    80001b4e:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001b52:	18800a13          	li	s4,392
    80001b56:	03448ab3          	mul	s5,s1,s4
    80001b5a:	040a8913          	addi	s2,s5,64
    80001b5e:	00010a17          	auipc	s4,0x10
    80001b62:	d1aa0a13          	addi	s4,s4,-742 # 80011878 <proc>
    80001b66:	9952                	add	s2,s2,s4
    80001b68:	854a                	mv	a0,s2
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	07a080e7          	jalr	122(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001b72:	9a56                	add	s4,s4,s5
    80001b74:	57fd                	li	a5,-1
    80001b76:	02fa2e23          	sw	a5,60(s4)
    release(&proc[p_index].linked_list_lock);
    80001b7a:	854a                	mv	a0,s2
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	12e080e7          	jalr	302(ra) # 80000caa <release>
    release(lock_list);
    80001b84:	854e                	mv	a0,s3
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	124080e7          	jalr	292(ra) # 80000caa <release>
    ret = p_index;
    80001b8e:	8526                	mv	a0,s1
    80001b90:	b75d                	j	80001b36 <insert_to_list+0x6a>
  panic("insert is failed");
    80001b92:	00006517          	auipc	a0,0x6
    80001b96:	67650513          	addi	a0,a0,1654 # 80008208 <digits+0x1c8>
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	9a4080e7          	jalr	-1628(ra) # 8000053e <panic>

0000000080001ba2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001ba2:	7139                	addi	sp,sp,-64
    80001ba4:	fc06                	sd	ra,56(sp)
    80001ba6:	f822                	sd	s0,48(sp)
    80001ba8:	f426                	sd	s1,40(sp)
    80001baa:	f04a                	sd	s2,32(sp)
    80001bac:	ec4e                	sd	s3,24(sp)
    80001bae:	e852                	sd	s4,16(sp)
    80001bb0:	e456                	sd	s5,8(sp)
    80001bb2:	e05a                	sd	s6,0(sp)
    80001bb4:	0080                	addi	s0,sp,64
    80001bb6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb8:	00010497          	auipc	s1,0x10
    80001bbc:	cc048493          	addi	s1,s1,-832 # 80011878 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001bc0:	8b26                	mv	s6,s1
    80001bc2:	00006a97          	auipc	s5,0x6
    80001bc6:	446a8a93          	addi	s5,s5,1094 # 80008008 <etext+0x8>
    80001bca:	04000937          	lui	s2,0x4000
    80001bce:	197d                	addi	s2,s2,-1
    80001bd0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	00016a17          	auipc	s4,0x16
    80001bd6:	ea6a0a13          	addi	s4,s4,-346 # 80017a78 <tickslock>
    char *pa = kalloc();
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	f1a080e7          	jalr	-230(ra) # 80000af4 <kalloc>
    80001be2:	862a                	mv	a2,a0
    if(pa == 0)
    80001be4:	c131                	beqz	a0,80001c28 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001be6:	416485b3          	sub	a1,s1,s6
    80001bea:	858d                	srai	a1,a1,0x3
    80001bec:	000ab783          	ld	a5,0(s5)
    80001bf0:	02f585b3          	mul	a1,a1,a5
    80001bf4:	2585                	addiw	a1,a1,1
    80001bf6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bfa:	4719                	li	a4,6
    80001bfc:	6685                	lui	a3,0x1
    80001bfe:	40b905b3          	sub	a1,s2,a1
    80001c02:	854e                	mv	a0,s3
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	570080e7          	jalr	1392(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	18848493          	addi	s1,s1,392
    80001c10:	fd4495e3          	bne	s1,s4,80001bda <proc_mapstacks+0x38>
  }
}
    80001c14:	70e2                	ld	ra,56(sp)
    80001c16:	7442                	ld	s0,48(sp)
    80001c18:	74a2                	ld	s1,40(sp)
    80001c1a:	7902                	ld	s2,32(sp)
    80001c1c:	69e2                	ld	s3,24(sp)
    80001c1e:	6a42                	ld	s4,16(sp)
    80001c20:	6aa2                	ld	s5,8(sp)
    80001c22:	6b02                	ld	s6,0(sp)
    80001c24:	6121                	addi	sp,sp,64
    80001c26:	8082                	ret
      panic("kalloc");
    80001c28:	00006517          	auipc	a0,0x6
    80001c2c:	5f850513          	addi	a0,a0,1528 # 80008220 <digits+0x1e0>
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080001c38 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001c38:	711d                	addi	sp,sp,-96
    80001c3a:	ec86                	sd	ra,88(sp)
    80001c3c:	e8a2                	sd	s0,80(sp)
    80001c3e:	e4a6                	sd	s1,72(sp)
    80001c40:	e0ca                	sd	s2,64(sp)
    80001c42:	fc4e                	sd	s3,56(sp)
    80001c44:	f852                	sd	s4,48(sp)
    80001c46:	f456                	sd	s5,40(sp)
    80001c48:	f05a                	sd	s6,32(sp)
    80001c4a:	ec5e                	sd	s7,24(sp)
    80001c4c:	e862                	sd	s8,16(sp)
    80001c4e:	e466                	sd	s9,8(sp)
    80001c50:	e06a                	sd	s10,0(sp)
    80001c52:	1080                	addi	s0,sp,96
  struct proc *p;

  for (int i = 0; i<CPUS; i++){
    80001c54:	00010717          	auipc	a4,0x10
    80001c58:	a8c70713          	addi	a4,a4,-1396 # 800116e0 <cpus_ll>
    80001c5c:	0000f797          	auipc	a5,0xf
    80001c60:	64478793          	addi	a5,a5,1604 # 800112a0 <cpus>
    80001c64:	863a                	mv	a2,a4
    cpus_ll[i] = -1;
    80001c66:	56fd                	li	a3,-1
    80001c68:	c314                	sw	a3,0(a4)
    cpus[i].admittedProcs = 0; // set initial cpu's admitted to 0
    80001c6a:	0807b023          	sd	zero,128(a5)
  for (int i = 0; i<CPUS; i++){
    80001c6e:	0711                	addi	a4,a4,4
    80001c70:	08878793          	addi	a5,a5,136
    80001c74:	fec79ae3          	bne	a5,a2,80001c68 <procinit+0x30>
}
  initlock(&pid_lock, "nextpid");
    80001c78:	00006597          	auipc	a1,0x6
    80001c7c:	5b058593          	addi	a1,a1,1456 # 80008228 <digits+0x1e8>
    80001c80:	00010517          	auipc	a0,0x10
    80001c84:	a8050513          	addi	a0,a0,-1408 # 80011700 <pid_lock>
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	ecc080e7          	jalr	-308(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c90:	00006597          	auipc	a1,0x6
    80001c94:	5a058593          	addi	a1,a1,1440 # 80008230 <digits+0x1f0>
    80001c98:	00010517          	auipc	a0,0x10
    80001c9c:	a8050513          	addi	a0,a0,-1408 # 80011718 <wait_lock>
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	eb4080e7          	jalr	-332(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001ca8:	00006597          	auipc	a1,0x6
    80001cac:	59858593          	addi	a1,a1,1432 # 80008240 <digits+0x200>
    80001cb0:	00010517          	auipc	a0,0x10
    80001cb4:	a8050513          	addi	a0,a0,-1408 # 80011730 <sleeping_head>
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	e9c080e7          	jalr	-356(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001cc0:	00006597          	auipc	a1,0x6
    80001cc4:	59058593          	addi	a1,a1,1424 # 80008250 <digits+0x210>
    80001cc8:	00010517          	auipc	a0,0x10
    80001ccc:	a8050513          	addi	a0,a0,-1408 # 80011748 <zombie_head>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	e84080e7          	jalr	-380(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001cd8:	00006597          	auipc	a1,0x6
    80001cdc:	58858593          	addi	a1,a1,1416 # 80008260 <digits+0x220>
    80001ce0:	00010517          	auipc	a0,0x10
    80001ce4:	a8050513          	addi	a0,a0,-1408 # 80011760 <unused_head>
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	e6c080e7          	jalr	-404(ra) # 80000b54 <initlock>
  
  int i=0;
    80001cf0:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf2:	00010497          	auipc	s1,0x10
    80001cf6:	b8648493          	addi	s1,s1,-1146 # 80011878 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001cfa:	8d26                	mv	s10,s1
    80001cfc:	00006c97          	auipc	s9,0x6
    80001d00:	30ccbc83          	ld	s9,780(s9) # 80008008 <etext+0x8>
    80001d04:	040009b7          	lui	s3,0x4000
    80001d08:	19fd                	addi	s3,s3,-1
    80001d0a:	09b2                	slli	s3,s3,0xc

      p->state = UNUSED; 
      p->index = i;
      p->next = -1;
    80001d0c:	5c7d                	li	s8,-1
      p->cpu_num = 0;
      initlock(&p->lock, "proc");
    80001d0e:	00006b97          	auipc	s7,0x6
    80001d12:	562b8b93          	addi	s7,s7,1378 # 80008270 <digits+0x230>
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
    80001d16:	00006b17          	auipc	s6,0x6
    80001d1a:	562b0b13          	addi	s6,s6,1378 # 80008278 <digits+0x238>
      i++;
      insert_to_list(p->index, &unused, &unused_head);
    80001d1e:	00010a97          	auipc	s5,0x10
    80001d22:	a42a8a93          	addi	s5,s5,-1470 # 80011760 <unused_head>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d26:	00016a17          	auipc	s4,0x16
    80001d2a:	d52a0a13          	addi	s4,s4,-686 # 80017a78 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001d2e:	41a487b3          	sub	a5,s1,s10
    80001d32:	878d                	srai	a5,a5,0x3
    80001d34:	039787b3          	mul	a5,a5,s9
    80001d38:	2785                	addiw	a5,a5,1
    80001d3a:	00d7979b          	slliw	a5,a5,0xd
    80001d3e:	40f987b3          	sub	a5,s3,a5
    80001d42:	f0bc                	sd	a5,96(s1)
      p->state = UNUSED; 
    80001d44:	0004ac23          	sw	zero,24(s1)
      p->index = i;
    80001d48:	0324ac23          	sw	s2,56(s1)
      p->next = -1;
    80001d4c:	0384ae23          	sw	s8,60(s1)
      p->cpu_num = 0;
    80001d50:	0204aa23          	sw	zero,52(s1)
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
      insert_to_list(p->index, &unused, &unused_head);
    80001d70:	8656                	mv	a2,s5
    80001d72:	00007597          	auipc	a1,0x7
    80001d76:	b5258593          	addi	a1,a1,-1198 # 800088c4 <unused>
    80001d7a:	5c88                	lw	a0,56(s1)
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	d50080e7          	jalr	-688(ra) # 80001acc <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d84:	18848493          	addi	s1,s1,392
    80001d88:	fb4493e3          	bne	s1,s4,80001d2e <procinit+0xf6>
  }
}
    80001d8c:	60e6                	ld	ra,88(sp)
    80001d8e:	6446                	ld	s0,80(sp)
    80001d90:	64a6                	ld	s1,72(sp)
    80001d92:	6906                	ld	s2,64(sp)
    80001d94:	79e2                	ld	s3,56(sp)
    80001d96:	7a42                	ld	s4,48(sp)
    80001d98:	7aa2                	ld	s5,40(sp)
    80001d9a:	7b02                	ld	s6,32(sp)
    80001d9c:	6be2                	ld	s7,24(sp)
    80001d9e:	6c42                	ld	s8,16(sp)
    80001da0:	6ca2                	ld	s9,8(sp)
    80001da2:	6d02                	ld	s10,0(sp)
    80001da4:	6125                	addi	sp,sp,96
    80001da6:	8082                	ret

0000000080001da8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001da8:	1141                	addi	sp,sp,-16
    80001daa:	e422                	sd	s0,8(sp)
    80001dac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dae:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001db0:	2501                	sext.w	a0,a0
    80001db2:	6422                	ld	s0,8(sp)
    80001db4:	0141                	addi	sp,sp,16
    80001db6:	8082                	ret

0000000080001db8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001db8:	1141                	addi	sp,sp,-16
    80001dba:	e422                	sd	s0,8(sp)
    80001dbc:	0800                	addi	s0,sp,16
    80001dbe:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001dc0:	0007851b          	sext.w	a0,a5
    80001dc4:	00451793          	slli	a5,a0,0x4
    80001dc8:	97aa                	add	a5,a5,a0
    80001dca:	078e                	slli	a5,a5,0x3
  return c;
}
    80001dcc:	0000f517          	auipc	a0,0xf
    80001dd0:	4d450513          	addi	a0,a0,1236 # 800112a0 <cpus>
    80001dd4:	953e                	add	a0,a0,a5
    80001dd6:	6422                	ld	s0,8(sp)
    80001dd8:	0141                	addi	sp,sp,16
    80001dda:	8082                	ret

0000000080001ddc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ddc:	1101                	addi	sp,sp,-32
    80001dde:	ec06                	sd	ra,24(sp)
    80001de0:	e822                	sd	s0,16(sp)
    80001de2:	e426                	sd	s1,8(sp)
    80001de4:	1000                	addi	s0,sp,32
  push_off();
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	db2080e7          	jalr	-590(ra) # 80000b98 <push_off>
    80001dee:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001df0:	0007871b          	sext.w	a4,a5
    80001df4:	00471793          	slli	a5,a4,0x4
    80001df8:	97ba                	add	a5,a5,a4
    80001dfa:	078e                	slli	a5,a5,0x3
    80001dfc:	0000f717          	auipc	a4,0xf
    80001e00:	4a470713          	addi	a4,a4,1188 # 800112a0 <cpus>
    80001e04:	97ba                	add	a5,a5,a4
    80001e06:	6384                	ld	s1,0(a5)
  pop_off();
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e42080e7          	jalr	-446(ra) # 80000c4a <pop_off>
  return p;
}
    80001e10:	8526                	mv	a0,s1
    80001e12:	60e2                	ld	ra,24(sp)
    80001e14:	6442                	ld	s0,16(sp)
    80001e16:	64a2                	ld	s1,8(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret

0000000080001e1c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e1c:	1141                	addi	sp,sp,-16
    80001e1e:	e406                	sd	ra,8(sp)
    80001e20:	e022                	sd	s0,0(sp)
    80001e22:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	fb8080e7          	jalr	-72(ra) # 80001ddc <myproc>
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e7e080e7          	jalr	-386(ra) # 80000caa <release>


  if (first) {
    80001e34:	00007797          	auipc	a5,0x7
    80001e38:	a8c7a783          	lw	a5,-1396(a5) # 800088c0 <first.1747>
    80001e3c:	eb89                	bnez	a5,80001e4e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e3e:	00001097          	auipc	ra,0x1
    80001e42:	fc0080e7          	jalr	-64(ra) # 80002dfe <usertrapret>
}
    80001e46:	60a2                	ld	ra,8(sp)
    80001e48:	6402                	ld	s0,0(sp)
    80001e4a:	0141                	addi	sp,sp,16
    80001e4c:	8082                	ret
    first = 0;
    80001e4e:	00007797          	auipc	a5,0x7
    80001e52:	a607a923          	sw	zero,-1422(a5) # 800088c0 <first.1747>
    fsinit(ROOTDEV);
    80001e56:	4505                	li	a0,1
    80001e58:	00002097          	auipc	ra,0x2
    80001e5c:	d64080e7          	jalr	-668(ra) # 80003bbc <fsinit>
    80001e60:	bff9                	j	80001e3e <forkret+0x22>

0000000080001e62 <inc_cpu_usage>:
inc_cpu_usage(int cpu_num){
    80001e62:	1101                	addi	sp,sp,-32
    80001e64:	ec06                	sd	ra,24(sp)
    80001e66:	e822                	sd	s0,16(sp)
    80001e68:	e426                	sd	s1,8(sp)
    80001e6a:	e04a                	sd	s2,0(sp)
    80001e6c:	1000                	addi	s0,sp,32
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001e6e:	00451493          	slli	s1,a0,0x4
    80001e72:	94aa                	add	s1,s1,a0
    80001e74:	048e                	slli	s1,s1,0x3
    80001e76:	0000f797          	auipc	a5,0xf
    80001e7a:	4aa78793          	addi	a5,a5,1194 # 80011320 <cpus+0x80>
    80001e7e:	94be                	add	s1,s1,a5
    usage = c->admittedProcs;
    80001e80:	00451913          	slli	s2,a0,0x4
    80001e84:	954a                	add	a0,a0,s2
    80001e86:	050e                	slli	a0,a0,0x3
    80001e88:	0000f917          	auipc	s2,0xf
    80001e8c:	41890913          	addi	s2,s2,1048 # 800112a0 <cpus>
    80001e90:	992a                	add	s2,s2,a0
    80001e92:	08093583          	ld	a1,128(s2)
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80001e96:	0015861b          	addiw	a2,a1,1
    80001e9a:	2581                	sext.w	a1,a1
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	00005097          	auipc	ra,0x5
    80001ea2:	b28080e7          	jalr	-1240(ra) # 800069c6 <cas>
    80001ea6:	f575                	bnez	a0,80001e92 <inc_cpu_usage+0x30>
}
    80001ea8:	60e2                	ld	ra,24(sp)
    80001eaa:	6442                	ld	s0,16(sp)
    80001eac:	64a2                	ld	s1,8(sp)
    80001eae:	6902                	ld	s2,0(sp)
    80001eb0:	6105                	addi	sp,sp,32
    80001eb2:	8082                	ret

0000000080001eb4 <allocpid>:
allocpid() {
    80001eb4:	1101                	addi	sp,sp,-32
    80001eb6:	ec06                	sd	ra,24(sp)
    80001eb8:	e822                	sd	s0,16(sp)
    80001eba:	e426                	sd	s1,8(sp)
    80001ebc:	e04a                	sd	s2,0(sp)
    80001ebe:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001ec0:	00007917          	auipc	s2,0x7
    80001ec4:	a1090913          	addi	s2,s2,-1520 # 800088d0 <nextpid>
    80001ec8:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001ecc:	0014861b          	addiw	a2,s1,1
    80001ed0:	85a6                	mv	a1,s1
    80001ed2:	854a                	mv	a0,s2
    80001ed4:	00005097          	auipc	ra,0x5
    80001ed8:	af2080e7          	jalr	-1294(ra) # 800069c6 <cas>
    80001edc:	f575                	bnez	a0,80001ec8 <allocpid+0x14>
}
    80001ede:	8526                	mv	a0,s1
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6902                	ld	s2,0(sp)
    80001ee8:	6105                	addi	sp,sp,32
    80001eea:	8082                	ret

0000000080001eec <proc_pagetable>:
{
    80001eec:	1101                	addi	sp,sp,-32
    80001eee:	ec06                	sd	ra,24(sp)
    80001ef0:	e822                	sd	s0,16(sp)
    80001ef2:	e426                	sd	s1,8(sp)
    80001ef4:	e04a                	sd	s2,0(sp)
    80001ef6:	1000                	addi	s0,sp,32
    80001ef8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	464080e7          	jalr	1124(ra) # 8000135e <uvmcreate>
    80001f02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f04:	c121                	beqz	a0,80001f44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f06:	4729                	li	a4,10
    80001f08:	00005697          	auipc	a3,0x5
    80001f0c:	0f868693          	addi	a3,a3,248 # 80007000 <_trampoline>
    80001f10:	6605                	lui	a2,0x1
    80001f12:	040005b7          	lui	a1,0x4000
    80001f16:	15fd                	addi	a1,a1,-1
    80001f18:	05b2                	slli	a1,a1,0xc
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	1ba080e7          	jalr	442(ra) # 800010d4 <mappages>
    80001f22:	02054863          	bltz	a0,80001f52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f26:	4719                	li	a4,6
    80001f28:	07893683          	ld	a3,120(s2)
    80001f2c:	6605                	lui	a2,0x1
    80001f2e:	020005b7          	lui	a1,0x2000
    80001f32:	15fd                	addi	a1,a1,-1
    80001f34:	05b6                	slli	a1,a1,0xd
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	19c080e7          	jalr	412(ra) # 800010d4 <mappages>
    80001f40:	02054163          	bltz	a0,80001f62 <proc_pagetable+0x76>
}
    80001f44:	8526                	mv	a0,s1
    80001f46:	60e2                	ld	ra,24(sp)
    80001f48:	6442                	ld	s0,16(sp)
    80001f4a:	64a2                	ld	s1,8(sp)
    80001f4c:	6902                	ld	s2,0(sp)
    80001f4e:	6105                	addi	sp,sp,32
    80001f50:	8082                	ret
    uvmfree(pagetable, 0);
    80001f52:	4581                	li	a1,0
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	604080e7          	jalr	1540(ra) # 8000155a <uvmfree>
    return 0;
    80001f5e:	4481                	li	s1,0
    80001f60:	b7d5                	j	80001f44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f62:	4681                	li	a3,0
    80001f64:	4605                	li	a2,1
    80001f66:	040005b7          	lui	a1,0x4000
    80001f6a:	15fd                	addi	a1,a1,-1
    80001f6c:	05b2                	slli	a1,a1,0xc
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	32a080e7          	jalr	810(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001f78:	4581                	li	a1,0
    80001f7a:	8526                	mv	a0,s1
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	5de080e7          	jalr	1502(ra) # 8000155a <uvmfree>
    return 0;
    80001f84:	4481                	li	s1,0
    80001f86:	bf7d                	j	80001f44 <proc_pagetable+0x58>

0000000080001f88 <proc_freepagetable>:
{
    80001f88:	1101                	addi	sp,sp,-32
    80001f8a:	ec06                	sd	ra,24(sp)
    80001f8c:	e822                	sd	s0,16(sp)
    80001f8e:	e426                	sd	s1,8(sp)
    80001f90:	e04a                	sd	s2,0(sp)
    80001f92:	1000                	addi	s0,sp,32
    80001f94:	84aa                	mv	s1,a0
    80001f96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f98:	4681                	li	a3,0
    80001f9a:	4605                	li	a2,1
    80001f9c:	040005b7          	lui	a1,0x4000
    80001fa0:	15fd                	addi	a1,a1,-1
    80001fa2:	05b2                	slli	a1,a1,0xc
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	2f6080e7          	jalr	758(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fac:	4681                	li	a3,0
    80001fae:	4605                	li	a2,1
    80001fb0:	020005b7          	lui	a1,0x2000
    80001fb4:	15fd                	addi	a1,a1,-1
    80001fb6:	05b6                	slli	a1,a1,0xd
    80001fb8:	8526                	mv	a0,s1
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	2e0080e7          	jalr	736(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001fc2:	85ca                	mv	a1,s2
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	594080e7          	jalr	1428(ra) # 8000155a <uvmfree>
}
    80001fce:	60e2                	ld	ra,24(sp)
    80001fd0:	6442                	ld	s0,16(sp)
    80001fd2:	64a2                	ld	s1,8(sp)
    80001fd4:	6902                	ld	s2,0(sp)
    80001fd6:	6105                	addi	sp,sp,32
    80001fd8:	8082                	ret

0000000080001fda <freeproc>:
{
    80001fda:	1101                	addi	sp,sp,-32
    80001fdc:	ec06                	sd	ra,24(sp)
    80001fde:	e822                	sd	s0,16(sp)
    80001fe0:	e426                	sd	s1,8(sp)
    80001fe2:	1000                	addi	s0,sp,32
    80001fe4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fe6:	7d28                	ld	a0,120(a0)
    80001fe8:	c509                	beqz	a0,80001ff2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	a0e080e7          	jalr	-1522(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001ff2:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001ff6:	78a8                	ld	a0,112(s1)
    80001ff8:	c511                	beqz	a0,80002004 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ffa:	74ac                	ld	a1,104(s1)
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	f8c080e7          	jalr	-116(ra) # 80001f88 <proc_freepagetable>
  p->pagetable = 0;
    80002004:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002008:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    8000200c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002010:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002014:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002018:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000201c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002020:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index, &zombie, &zombie_head);
    80002024:	0000f617          	auipc	a2,0xf
    80002028:	72460613          	addi	a2,a2,1828 # 80011748 <zombie_head>
    8000202c:	00007597          	auipc	a1,0x7
    80002030:	89c58593          	addi	a1,a1,-1892 # 800088c8 <zombie>
    80002034:	5c88                	lw	a0,56(s1)
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	874080e7          	jalr	-1932(ra) # 800018aa <remove_from_list>
  p->state = UNUSED;
    8000203e:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index, &unused, &unused_head);
    80002042:	0000f617          	auipc	a2,0xf
    80002046:	71e60613          	addi	a2,a2,1822 # 80011760 <unused_head>
    8000204a:	00007597          	auipc	a1,0x7
    8000204e:	87a58593          	addi	a1,a1,-1926 # 800088c4 <unused>
    80002052:	5c88                	lw	a0,56(s1)
    80002054:	00000097          	auipc	ra,0x0
    80002058:	a78080e7          	jalr	-1416(ra) # 80001acc <insert_to_list>
}
    8000205c:	60e2                	ld	ra,24(sp)
    8000205e:	6442                	ld	s0,16(sp)
    80002060:	64a2                	ld	s1,8(sp)
    80002062:	6105                	addi	sp,sp,32
    80002064:	8082                	ret

0000000080002066 <allocproc>:
{
    80002066:	7179                	addi	sp,sp,-48
    80002068:	f406                	sd	ra,40(sp)
    8000206a:	f022                	sd	s0,32(sp)
    8000206c:	ec26                	sd	s1,24(sp)
    8000206e:	e84a                	sd	s2,16(sp)
    80002070:	e44e                	sd	s3,8(sp)
    80002072:	e052                	sd	s4,0(sp)
    80002074:	1800                	addi	s0,sp,48
  if(unused != -1){
    80002076:	00007917          	auipc	s2,0x7
    8000207a:	84e92903          	lw	s2,-1970(s2) # 800088c4 <unused>
    8000207e:	57fd                	li	a5,-1
  return 0;
    80002080:	4481                	li	s1,0
  if(unused != -1){
    80002082:	0af90b63          	beq	s2,a5,80002138 <allocproc+0xd2>
    p = &proc[unused];
    80002086:	18800993          	li	s3,392
    8000208a:	033909b3          	mul	s3,s2,s3
    8000208e:	0000f497          	auipc	s1,0xf
    80002092:	7ea48493          	addi	s1,s1,2026 # 80011878 <proc>
    80002096:	94ce                	add	s1,s1,s3
    remove_from_list(p->index,&unused, &unused_head);
    80002098:	0000f617          	auipc	a2,0xf
    8000209c:	6c860613          	addi	a2,a2,1736 # 80011760 <unused_head>
    800020a0:	00007597          	auipc	a1,0x7
    800020a4:	82458593          	addi	a1,a1,-2012 # 800088c4 <unused>
    800020a8:	5c88                	lw	a0,56(s1)
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	800080e7          	jalr	-2048(ra) # 800018aa <remove_from_list>
    acquire(&p->lock);
    800020b2:	8526                	mv	a0,s1
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	b30080e7          	jalr	-1232(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	df8080e7          	jalr	-520(ra) # 80001eb4 <allocpid>
    800020c4:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020c6:	4785                	li	a5,1
    800020c8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	a2a080e7          	jalr	-1494(ra) # 80000af4 <kalloc>
    800020d2:	8a2a                	mv	s4,a0
    800020d4:	fca8                	sd	a0,120(s1)
    800020d6:	c935                	beqz	a0,8000214a <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    800020d8:	8526                	mv	a0,s1
    800020da:	00000097          	auipc	ra,0x0
    800020de:	e12080e7          	jalr	-494(ra) # 80001eec <proc_pagetable>
    800020e2:	8a2a                	mv	s4,a0
    800020e4:	18800793          	li	a5,392
    800020e8:	02f90733          	mul	a4,s2,a5
    800020ec:	0000f797          	auipc	a5,0xf
    800020f0:	78c78793          	addi	a5,a5,1932 # 80011878 <proc>
    800020f4:	97ba                	add	a5,a5,a4
    800020f6:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800020f8:	c52d                	beqz	a0,80002162 <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    800020fa:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    800020fe:	0000fa17          	auipc	s4,0xf
    80002102:	77aa0a13          	addi	s4,s4,1914 # 80011878 <proc>
    80002106:	07000613          	li	a2,112
    8000210a:	4581                	li	a1,0
    8000210c:	9552                	add	a0,a0,s4
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	bf6080e7          	jalr	-1034(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    80002116:	18800793          	li	a5,392
    8000211a:	02f90933          	mul	s2,s2,a5
    8000211e:	9952                	add	s2,s2,s4
    80002120:	00000797          	auipc	a5,0x0
    80002124:	cfc78793          	addi	a5,a5,-772 # 80001e1c <forkret>
    80002128:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000212c:	06093783          	ld	a5,96(s2)
    80002130:	6705                	lui	a4,0x1
    80002132:	97ba                	add	a5,a5,a4
    80002134:	08f93423          	sd	a5,136(s2)
}
    80002138:	8526                	mv	a0,s1
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6a02                	ld	s4,0(sp)
    80002146:	6145                	addi	sp,sp,48
    80002148:	8082                	ret
    freeproc(p);
    8000214a:	8526                	mv	a0,s1
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	e8e080e7          	jalr	-370(ra) # 80001fda <freeproc>
    release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b54080e7          	jalr	-1196(ra) # 80000caa <release>
    return 0;
    8000215e:	84d2                	mv	s1,s4
    80002160:	bfe1                	j	80002138 <allocproc+0xd2>
    freeproc(p);
    80002162:	8526                	mv	a0,s1
    80002164:	00000097          	auipc	ra,0x0
    80002168:	e76080e7          	jalr	-394(ra) # 80001fda <freeproc>
    release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b3c080e7          	jalr	-1220(ra) # 80000caa <release>
    return 0;
    80002176:	84d2                	mv	s1,s4
    80002178:	b7c1                	j	80002138 <allocproc+0xd2>

000000008000217a <userinit>:
{
    8000217a:	1101                	addi	sp,sp,-32
    8000217c:	ec06                	sd	ra,24(sp)
    8000217e:	e822                	sd	s0,16(sp)
    80002180:	e426                	sd	s1,8(sp)
    80002182:	1000                	addi	s0,sp,32
  p = allocproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	ee2080e7          	jalr	-286(ra) # 80002066 <allocproc>
    8000218c:	84aa                	mv	s1,a0
  initproc = p;
    8000218e:	00007797          	auipc	a5,0x7
    80002192:	e8a7bd23          	sd	a0,-358(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002196:	03400613          	li	a2,52
    8000219a:	00006597          	auipc	a1,0x6
    8000219e:	74658593          	addi	a1,a1,1862 # 800088e0 <initcode>
    800021a2:	7928                	ld	a0,112(a0)
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	1e8080e7          	jalr	488(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    800021ac:	6785                	lui	a5,0x1
    800021ae:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800021b0:	7cb8                	ld	a4,120(s1)
    800021b2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021b6:	7cb8                	ld	a4,120(s1)
    800021b8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021ba:	4641                	li	a2,16
    800021bc:	00006597          	auipc	a1,0x6
    800021c0:	0c458593          	addi	a1,a1,196 # 80008280 <digits+0x240>
    800021c4:	17848513          	addi	a0,s1,376
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	c8e080e7          	jalr	-882(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800021d0:	00006517          	auipc	a0,0x6
    800021d4:	0c050513          	addi	a0,a0,192 # 80008290 <digits+0x250>
    800021d8:	00002097          	auipc	ra,0x2
    800021dc:	412080e7          	jalr	1042(ra) # 800045ea <namei>
    800021e0:	16a4b823          	sd	a0,368(s1)
  insert_to_list(p->index, &cpus_ll[0], &cpus_head[0]);
    800021e4:	0000f617          	auipc	a2,0xf
    800021e8:	59460613          	addi	a2,a2,1428 # 80011778 <cpus_head>
    800021ec:	0000f597          	auipc	a1,0xf
    800021f0:	4f458593          	addi	a1,a1,1268 # 800116e0 <cpus_ll>
    800021f4:	5c88                	lw	a0,56(s1)
    800021f6:	00000097          	auipc	ra,0x0
    800021fa:	8d6080e7          	jalr	-1834(ra) # 80001acc <insert_to_list>
  inc_cpu_usage(0);
    800021fe:	4501                	li	a0,0
    80002200:	00000097          	auipc	ra,0x0
    80002204:	c62080e7          	jalr	-926(ra) # 80001e62 <inc_cpu_usage>
  p->state = RUNNABLE;
    80002208:	478d                	li	a5,3
    8000220a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a9c080e7          	jalr	-1380(ra) # 80000caa <release>
}
    80002216:	60e2                	ld	ra,24(sp)
    80002218:	6442                	ld	s0,16(sp)
    8000221a:	64a2                	ld	s1,8(sp)
    8000221c:	6105                	addi	sp,sp,32
    8000221e:	8082                	ret

0000000080002220 <growproc>:
{
    80002220:	1101                	addi	sp,sp,-32
    80002222:	ec06                	sd	ra,24(sp)
    80002224:	e822                	sd	s0,16(sp)
    80002226:	e426                	sd	s1,8(sp)
    80002228:	e04a                	sd	s2,0(sp)
    8000222a:	1000                	addi	s0,sp,32
    8000222c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	bae080e7          	jalr	-1106(ra) # 80001ddc <myproc>
    80002236:	892a                	mv	s2,a0
  sz = p->sz;
    80002238:	752c                	ld	a1,104(a0)
    8000223a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000223e:	00904f63          	bgtz	s1,8000225c <growproc+0x3c>
  } else if(n < 0){
    80002242:	0204cc63          	bltz	s1,8000227a <growproc+0x5a>
  p->sz = sz;
    80002246:	1602                	slli	a2,a2,0x20
    80002248:	9201                	srli	a2,a2,0x20
    8000224a:	06c93423          	sd	a2,104(s2)
  return 0;
    8000224e:	4501                	li	a0,0
}
    80002250:	60e2                	ld	ra,24(sp)
    80002252:	6442                	ld	s0,16(sp)
    80002254:	64a2                	ld	s1,8(sp)
    80002256:	6902                	ld	s2,0(sp)
    80002258:	6105                	addi	sp,sp,32
    8000225a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000225c:	9e25                	addw	a2,a2,s1
    8000225e:	1602                	slli	a2,a2,0x20
    80002260:	9201                	srli	a2,a2,0x20
    80002262:	1582                	slli	a1,a1,0x20
    80002264:	9181                	srli	a1,a1,0x20
    80002266:	7928                	ld	a0,112(a0)
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	1de080e7          	jalr	478(ra) # 80001446 <uvmalloc>
    80002270:	0005061b          	sext.w	a2,a0
    80002274:	fa69                	bnez	a2,80002246 <growproc+0x26>
      return -1;
    80002276:	557d                	li	a0,-1
    80002278:	bfe1                	j	80002250 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000227a:	9e25                	addw	a2,a2,s1
    8000227c:	1602                	slli	a2,a2,0x20
    8000227e:	9201                	srli	a2,a2,0x20
    80002280:	1582                	slli	a1,a1,0x20
    80002282:	9181                	srli	a1,a1,0x20
    80002284:	7928                	ld	a0,112(a0)
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	178080e7          	jalr	376(ra) # 800013fe <uvmdealloc>
    8000228e:	0005061b          	sext.w	a2,a0
    80002292:	bf55                	j	80002246 <growproc+0x26>

0000000080002294 <fork>:
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	e052                	sd	s4,0(sp)
    800022a2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	b38080e7          	jalr	-1224(ra) # 80001ddc <myproc>
    800022ac:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	db8080e7          	jalr	-584(ra) # 80002066 <allocproc>
    800022b6:	16050863          	beqz	a0,80002426 <fork+0x192>
    800022ba:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022bc:	0689b603          	ld	a2,104(s3)
    800022c0:	792c                	ld	a1,112(a0)
    800022c2:	0709b503          	ld	a0,112(s3)
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	2cc080e7          	jalr	716(ra) # 80001592 <uvmcopy>
    800022ce:	04054663          	bltz	a0,8000231a <fork+0x86>
  np->sz = p->sz;
    800022d2:	0689b783          	ld	a5,104(s3)
    800022d6:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800022da:	0789b683          	ld	a3,120(s3)
    800022de:	87b6                	mv	a5,a3
    800022e0:	07893703          	ld	a4,120(s2)
    800022e4:	12068693          	addi	a3,a3,288
    800022e8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022ec:	6788                	ld	a0,8(a5)
    800022ee:	6b8c                	ld	a1,16(a5)
    800022f0:	6f90                	ld	a2,24(a5)
    800022f2:	01073023          	sd	a6,0(a4)
    800022f6:	e708                	sd	a0,8(a4)
    800022f8:	eb0c                	sd	a1,16(a4)
    800022fa:	ef10                	sd	a2,24(a4)
    800022fc:	02078793          	addi	a5,a5,32
    80002300:	02070713          	addi	a4,a4,32
    80002304:	fed792e3          	bne	a5,a3,800022e8 <fork+0x54>
  np->trapframe->a0 = 0;
    80002308:	07893783          	ld	a5,120(s2)
    8000230c:	0607b823          	sd	zero,112(a5)
    80002310:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80002314:	17000a13          	li	s4,368
    80002318:	a03d                	j	80002346 <fork+0xb2>
    freeproc(np);
    8000231a:	854a                	mv	a0,s2
    8000231c:	00000097          	auipc	ra,0x0
    80002320:	cbe080e7          	jalr	-834(ra) # 80001fda <freeproc>
    release(&np->lock);
    80002324:	854a                	mv	a0,s2
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	984080e7          	jalr	-1660(ra) # 80000caa <release>
    return -1;
    8000232e:	5a7d                	li	s4,-1
    80002330:	a0d5                	j	80002414 <fork+0x180>
      np->ofile[i] = filedup(p->ofile[i]);
    80002332:	00003097          	auipc	ra,0x3
    80002336:	94e080e7          	jalr	-1714(ra) # 80004c80 <filedup>
    8000233a:	009907b3          	add	a5,s2,s1
    8000233e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002340:	04a1                	addi	s1,s1,8
    80002342:	01448763          	beq	s1,s4,80002350 <fork+0xbc>
    if(p->ofile[i])
    80002346:	009987b3          	add	a5,s3,s1
    8000234a:	6388                	ld	a0,0(a5)
    8000234c:	f17d                	bnez	a0,80002332 <fork+0x9e>
    8000234e:	bfcd                	j	80002340 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002350:	1709b503          	ld	a0,368(s3)
    80002354:	00002097          	auipc	ra,0x2
    80002358:	aa2080e7          	jalr	-1374(ra) # 80003df6 <idup>
    8000235c:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002360:	17890493          	addi	s1,s2,376
    80002364:	4641                	li	a2,16
    80002366:	17898593          	addi	a1,s3,376
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	aea080e7          	jalr	-1302(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    80002374:	03092a03          	lw	s4,48(s2)
  np->cpu_num = p->cpu_num; //giving the child it's parent's cpu_num
    80002378:	0349a783          	lw	a5,52(s3)
    8000237c:	02f92a23          	sw	a5,52(s2)
  int cpui = leastUsedCPU();
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	4e2080e7          	jalr	1250(ra) # 80001862 <leastUsedCPU>
  np->cpu_num = cpui;
    80002388:	02a92a23          	sw	a0,52(s2)
  inc_cpu_usage(cpui);
    8000238c:	00000097          	auipc	ra,0x0
    80002390:	ad6080e7          	jalr	-1322(ra) # 80001e62 <inc_cpu_usage>
  initlock(&np->linked_list_lock, np->name);
    80002394:	85a6                	mv	a1,s1
    80002396:	04090513          	addi	a0,s2,64
    8000239a:	ffffe097          	auipc	ra,0xffffe
    8000239e:	7ba080e7          	jalr	1978(ra) # 80000b54 <initlock>
  release(&np->lock);
    800023a2:	854a                	mv	a0,s2
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	906080e7          	jalr	-1786(ra) # 80000caa <release>
  acquire(&wait_lock);
    800023ac:	0000f497          	auipc	s1,0xf
    800023b0:	36c48493          	addi	s1,s1,876 # 80011718 <wait_lock>
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	82e080e7          	jalr	-2002(ra) # 80000be4 <acquire>
  np->parent = p;
    800023be:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8e6080e7          	jalr	-1818(ra) # 80000caa <release>
  acquire(&np->lock);
    800023cc:	854a                	mv	a0,s2
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	816080e7          	jalr	-2026(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023d6:	478d                	li	a5,3
    800023d8:	00f92c23          	sw	a5,24(s2)
  insert_to_list(np->index, &cpus_ll[np->cpu_num], &cpus_head[np->cpu_num]);
    800023dc:	03492583          	lw	a1,52(s2)
    800023e0:	00159793          	slli	a5,a1,0x1
    800023e4:	97ae                	add	a5,a5,a1
    800023e6:	078e                	slli	a5,a5,0x3
    800023e8:	058a                	slli	a1,a1,0x2
    800023ea:	0000f617          	auipc	a2,0xf
    800023ee:	38e60613          	addi	a2,a2,910 # 80011778 <cpus_head>
    800023f2:	963e                	add	a2,a2,a5
    800023f4:	0000f797          	auipc	a5,0xf
    800023f8:	2ec78793          	addi	a5,a5,748 # 800116e0 <cpus_ll>
    800023fc:	95be                	add	a1,a1,a5
    800023fe:	03892503          	lw	a0,56(s2)
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	6ca080e7          	jalr	1738(ra) # 80001acc <insert_to_list>
  release(&np->lock);
    8000240a:	854a                	mv	a0,s2
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	89e080e7          	jalr	-1890(ra) # 80000caa <release>
}
    80002414:	8552                	mv	a0,s4
    80002416:	70a2                	ld	ra,40(sp)
    80002418:	7402                	ld	s0,32(sp)
    8000241a:	64e2                	ld	s1,24(sp)
    8000241c:	6942                	ld	s2,16(sp)
    8000241e:	69a2                	ld	s3,8(sp)
    80002420:	6a02                	ld	s4,0(sp)
    80002422:	6145                	addi	sp,sp,48
    80002424:	8082                	ret
    return -1;
    80002426:	5a7d                	li	s4,-1
    80002428:	b7f5                	j	80002414 <fork+0x180>

000000008000242a <scheduler>:
{
    8000242a:	711d                	addi	sp,sp,-96
    8000242c:	ec86                	sd	ra,88(sp)
    8000242e:	e8a2                	sd	s0,80(sp)
    80002430:	e4a6                	sd	s1,72(sp)
    80002432:	e0ca                	sd	s2,64(sp)
    80002434:	fc4e                	sd	s3,56(sp)
    80002436:	f852                	sd	s4,48(sp)
    80002438:	f456                	sd	s5,40(sp)
    8000243a:	f05a                	sd	s6,32(sp)
    8000243c:	ec5e                	sd	s7,24(sp)
    8000243e:	e862                	sd	s8,16(sp)
    80002440:	e466                	sd	s9,8(sp)
    80002442:	1080                	addi	s0,sp,96
    80002444:	8712                	mv	a4,tp
  int id = r_tp();
    80002446:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002448:	0000fa17          	auipc	s4,0xf
    8000244c:	e58a0a13          	addi	s4,s4,-424 # 800112a0 <cpus>
    80002450:	00471793          	slli	a5,a4,0x4
    80002454:	00e786b3          	add	a3,a5,a4
    80002458:	068e                	slli	a3,a3,0x3
    8000245a:	96d2                	add	a3,a3,s4
    8000245c:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    80002460:	97ba                	add	a5,a5,a4
    80002462:	078e                	slli	a5,a5,0x3
    80002464:	07a1                	addi	a5,a5,8
    80002466:	9a3e                	add	s4,s4,a5
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002468:	0000f997          	auipc	s3,0xf
    8000246c:	e3898993          	addi	s3,s3,-456 # 800112a0 <cpus>
      p = &proc[cpus_ll[cpuid()]];
    80002470:	0000f497          	auipc	s1,0xf
    80002474:	40848493          	addi	s1,s1,1032 # 80011878 <proc>
      c->proc = p;
    80002478:	8936                	mv	s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000247a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000247e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002482:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002486:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002488:	2781                	sext.w	a5,a5
    8000248a:	078a                	slli	a5,a5,0x2
    8000248c:	97ce                	add	a5,a5,s3
    8000248e:	4407a703          	lw	a4,1088(a5)
    80002492:	57fd                	li	a5,-1
    80002494:	fef703e3          	beq	a4,a5,8000247a <scheduler+0x50>
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    80002498:	0000fb17          	auipc	s6,0xf
    8000249c:	2e0b0b13          	addi	s6,s6,736 # 80011778 <cpus_head>
    800024a0:	0000fa97          	auipc	s5,0xf
    800024a4:	240a8a93          	addi	s5,s5,576 # 800116e0 <cpus_ll>
    800024a8:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    800024aa:	2781                	sext.w	a5,a5
    800024ac:	078a                	slli	a5,a5,0x2
    800024ae:	97ce                	add	a5,a5,s3
    800024b0:	4407ac03          	lw	s8,1088(a5)
    800024b4:	18800b93          	li	s7,392
    800024b8:	037c0bb3          	mul	s7,s8,s7
    800024bc:	009b8cb3          	add	s9,s7,s1
      acquire(&p->lock);
    800024c0:	8566                	mv	a0,s9
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	722080e7          	jalr	1826(ra) # 80000be4 <acquire>
    800024ca:	8592                	mv	a1,tp
    800024cc:	8612                	mv	a2,tp
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    800024ce:	0006079b          	sext.w	a5,a2
    800024d2:	00179613          	slli	a2,a5,0x1
    800024d6:	963e                	add	a2,a2,a5
    800024d8:	060e                	slli	a2,a2,0x3
    800024da:	2581                	sext.w	a1,a1
    800024dc:	058a                	slli	a1,a1,0x2
    800024de:	965a                	add	a2,a2,s6
    800024e0:	95d6                	add	a1,a1,s5
    800024e2:	038ca503          	lw	a0,56(s9)
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	3c4080e7          	jalr	964(ra) # 800018aa <remove_from_list>
      if(removed == -1)
    800024ee:	57fd                	li	a5,-1
    800024f0:	04f50563          	beq	a0,a5,8000253a <scheduler+0x110>
      p->state = RUNNING;
    800024f4:	18800793          	li	a5,392
    800024f8:	02fc0c33          	mul	s8,s8,a5
    800024fc:	9c26                	add	s8,s8,s1
    800024fe:	4791                	li	a5,4
    80002500:	00fc2c23          	sw	a5,24(s8)
      c->proc = p;
    80002504:	01993023          	sd	s9,0(s2)
      swtch(&c->context, &p->context);
    80002508:	080b8593          	addi	a1,s7,128
    8000250c:	95a6                	add	a1,a1,s1
    8000250e:	8552                	mv	a0,s4
    80002510:	00001097          	auipc	ra,0x1
    80002514:	844080e7          	jalr	-1980(ra) # 80002d54 <swtch>
      c->proc = 0;
    80002518:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    8000251c:	8566                	mv	a0,s9
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	78c080e7          	jalr	1932(ra) # 80000caa <release>
    80002526:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002528:	2781                	sext.w	a5,a5
    8000252a:	078a                	slli	a5,a5,0x2
    8000252c:	97ce                	add	a5,a5,s3
    8000252e:	4407a703          	lw	a4,1088(a5)
    80002532:	57fd                	li	a5,-1
    80002534:	f6f71ae3          	bne	a4,a5,800024a8 <scheduler+0x7e>
    80002538:	b789                	j	8000247a <scheduler+0x50>
        panic("could not remove");
    8000253a:	00006517          	auipc	a0,0x6
    8000253e:	d5e50513          	addi	a0,a0,-674 # 80008298 <digits+0x258>
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	ffc080e7          	jalr	-4(ra) # 8000053e <panic>

000000008000254a <sched>:
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	884080e7          	jalr	-1916(ra) # 80001ddc <myproc>
    80002560:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	608080e7          	jalr	1544(ra) # 80000b6a <holding>
    8000256a:	c559                	beqz	a0,800025f8 <sched+0xae>
    8000256c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    8000256e:	0007871b          	sext.w	a4,a5
    80002572:	00471793          	slli	a5,a4,0x4
    80002576:	97ba                	add	a5,a5,a4
    80002578:	078e                	slli	a5,a5,0x3
    8000257a:	0000f717          	auipc	a4,0xf
    8000257e:	d2670713          	addi	a4,a4,-730 # 800112a0 <cpus>
    80002582:	97ba                	add	a5,a5,a4
    80002584:	5fb8                	lw	a4,120(a5)
    80002586:	4785                	li	a5,1
    80002588:	08f71063          	bne	a4,a5,80002608 <sched+0xbe>
  if(p->state == RUNNING)
    8000258c:	4c98                	lw	a4,24(s1)
    8000258e:	4791                	li	a5,4
    80002590:	08f70463          	beq	a4,a5,80002618 <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002594:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002598:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000259a:	e7d9                	bnez	a5,80002628 <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000259c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000259e:	0000f917          	auipc	s2,0xf
    800025a2:	d0290913          	addi	s2,s2,-766 # 800112a0 <cpus>
    800025a6:	0007871b          	sext.w	a4,a5
    800025aa:	00471793          	slli	a5,a4,0x4
    800025ae:	97ba                	add	a5,a5,a4
    800025b0:	078e                	slli	a5,a5,0x3
    800025b2:	97ca                	add	a5,a5,s2
    800025b4:	07c7a983          	lw	s3,124(a5)
    800025b8:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800025ba:	0005879b          	sext.w	a5,a1
    800025be:	00479593          	slli	a1,a5,0x4
    800025c2:	95be                	add	a1,a1,a5
    800025c4:	058e                	slli	a1,a1,0x3
    800025c6:	05a1                	addi	a1,a1,8
    800025c8:	95ca                	add	a1,a1,s2
    800025ca:	08048513          	addi	a0,s1,128
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	786080e7          	jalr	1926(ra) # 80002d54 <swtch>
    800025d6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025d8:	0007871b          	sext.w	a4,a5
    800025dc:	00471793          	slli	a5,a4,0x4
    800025e0:	97ba                	add	a5,a5,a4
    800025e2:	078e                	slli	a5,a5,0x3
    800025e4:	993e                	add	s2,s2,a5
    800025e6:	07392e23          	sw	s3,124(s2)
}
    800025ea:	70a2                	ld	ra,40(sp)
    800025ec:	7402                	ld	s0,32(sp)
    800025ee:	64e2                	ld	s1,24(sp)
    800025f0:	6942                	ld	s2,16(sp)
    800025f2:	69a2                	ld	s3,8(sp)
    800025f4:	6145                	addi	sp,sp,48
    800025f6:	8082                	ret
    panic("sched p->lock");
    800025f8:	00006517          	auipc	a0,0x6
    800025fc:	cb850513          	addi	a0,a0,-840 # 800082b0 <digits+0x270>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
    panic("sched locks");
    80002608:	00006517          	auipc	a0,0x6
    8000260c:	cb850513          	addi	a0,a0,-840 # 800082c0 <digits+0x280>
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
    panic("sched running");
    80002618:	00006517          	auipc	a0,0x6
    8000261c:	cb850513          	addi	a0,a0,-840 # 800082d0 <digits+0x290>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002628:	00006517          	auipc	a0,0x6
    8000262c:	cb850513          	addi	a0,a0,-840 # 800082e0 <digits+0x2a0>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>

0000000080002638 <yield>:
{
    80002638:	1101                	addi	sp,sp,-32
    8000263a:	ec06                	sd	ra,24(sp)
    8000263c:	e822                	sd	s0,16(sp)
    8000263e:	e426                	sd	s1,8(sp)
    80002640:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	79a080e7          	jalr	1946(ra) # 80001ddc <myproc>
    8000264a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	598080e7          	jalr	1432(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002654:	478d                	li	a5,3
    80002656:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002658:	58cc                	lw	a1,52(s1)
    8000265a:	00159793          	slli	a5,a1,0x1
    8000265e:	97ae                	add	a5,a5,a1
    80002660:	078e                	slli	a5,a5,0x3
    80002662:	058a                	slli	a1,a1,0x2
    80002664:	0000f617          	auipc	a2,0xf
    80002668:	11460613          	addi	a2,a2,276 # 80011778 <cpus_head>
    8000266c:	963e                	add	a2,a2,a5
    8000266e:	0000f797          	auipc	a5,0xf
    80002672:	07278793          	addi	a5,a5,114 # 800116e0 <cpus_ll>
    80002676:	95be                	add	a1,a1,a5
    80002678:	5c88                	lw	a0,56(s1)
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	452080e7          	jalr	1106(ra) # 80001acc <insert_to_list>
  sched();
    80002682:	00000097          	auipc	ra,0x0
    80002686:	ec8080e7          	jalr	-312(ra) # 8000254a <sched>
  release(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	61e080e7          	jalr	1566(ra) # 80000caa <release>
}
    80002694:	60e2                	ld	ra,24(sp)
    80002696:	6442                	ld	s0,16(sp)
    80002698:	64a2                	ld	s1,8(sp)
    8000269a:	6105                	addi	sp,sp,32
    8000269c:	8082                	ret

000000008000269e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000269e:	7179                	addi	sp,sp,-48
    800026a0:	f406                	sd	ra,40(sp)
    800026a2:	f022                	sd	s0,32(sp)
    800026a4:	ec26                	sd	s1,24(sp)
    800026a6:	e84a                	sd	s2,16(sp)
    800026a8:	e44e                	sd	s3,8(sp)
    800026aa:	1800                	addi	s0,sp,48
    800026ac:	89aa                	mv	s3,a0
    800026ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	72c080e7          	jalr	1836(ra) # 80001ddc <myproc>
    800026b8:	84aa                	mv	s1,a0
  // Must acquire p->lock in order to change p->state and then call sched.
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.
  // Go to sleep.
  // cas(&p->state, RUNNING, SLEEPING);
  insert_to_list(p->index, &sleeping, &sleeping_head);
    800026ba:	0000f617          	auipc	a2,0xf
    800026be:	07660613          	addi	a2,a2,118 # 80011730 <sleeping_head>
    800026c2:	00006597          	auipc	a1,0x6
    800026c6:	20a58593          	addi	a1,a1,522 # 800088cc <sleeping>
    800026ca:	5d08                	lw	a0,56(a0)
    800026cc:	fffff097          	auipc	ra,0xfffff
    800026d0:	400080e7          	jalr	1024(ra) # 80001acc <insert_to_list>
  p->chan = chan;
    800026d4:	0334b023          	sd	s3,32(s1)
  acquire(&p->lock);  //DOC: sleeplock1
    800026d8:	8526                	mv	a0,s1
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	50a080e7          	jalr	1290(ra) # 80000be4 <acquire>
  p->state = SLEEPING;
    800026e2:	4789                	li	a5,2
    800026e4:	cc9c                	sw	a5,24(s1)
  release(lk);
    800026e6:	854a                	mv	a0,s2
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5c2080e7          	jalr	1474(ra) # 80000caa <release>
  sched();
    800026f0:	00000097          	auipc	ra,0x0
    800026f4:	e5a080e7          	jalr	-422(ra) # 8000254a <sched>
  // Tidy up.
  p->chan = 0;
    800026f8:	0204b023          	sd	zero,32(s1)
  // Reacquire original lock.
  release(&p->lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	5ac080e7          	jalr	1452(ra) # 80000caa <release>
  acquire(lk);
    80002706:	854a                	mv	a0,s2
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	4dc080e7          	jalr	1244(ra) # 80000be4 <acquire>

}
    80002710:	70a2                	ld	ra,40(sp)
    80002712:	7402                	ld	s0,32(sp)
    80002714:	64e2                	ld	s1,24(sp)
    80002716:	6942                	ld	s2,16(sp)
    80002718:	69a2                	ld	s3,8(sp)
    8000271a:	6145                	addi	sp,sp,48
    8000271c:	8082                	ret

000000008000271e <wait>:
{
    8000271e:	715d                	addi	sp,sp,-80
    80002720:	e486                	sd	ra,72(sp)
    80002722:	e0a2                	sd	s0,64(sp)
    80002724:	fc26                	sd	s1,56(sp)
    80002726:	f84a                	sd	s2,48(sp)
    80002728:	f44e                	sd	s3,40(sp)
    8000272a:	f052                	sd	s4,32(sp)
    8000272c:	ec56                	sd	s5,24(sp)
    8000272e:	e85a                	sd	s6,16(sp)
    80002730:	e45e                	sd	s7,8(sp)
    80002732:	e062                	sd	s8,0(sp)
    80002734:	0880                	addi	s0,sp,80
    80002736:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	6a4080e7          	jalr	1700(ra) # 80001ddc <myproc>
    80002740:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002742:	0000f517          	auipc	a0,0xf
    80002746:	fd650513          	addi	a0,a0,-42 # 80011718 <wait_lock>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	49a080e7          	jalr	1178(ra) # 80000be4 <acquire>
    havekids = 0;
    80002752:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002754:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002756:	00015997          	auipc	s3,0x15
    8000275a:	32298993          	addi	s3,s3,802 # 80017a78 <tickslock>
        havekids = 1;
    8000275e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002760:	0000fc17          	auipc	s8,0xf
    80002764:	fb8c0c13          	addi	s8,s8,-72 # 80011718 <wait_lock>
    havekids = 0;
    80002768:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000276a:	0000f497          	auipc	s1,0xf
    8000276e:	10e48493          	addi	s1,s1,270 # 80011878 <proc>
    80002772:	a0bd                	j	800027e0 <wait+0xc2>
          pid = np->pid;
    80002774:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002778:	000b0e63          	beqz	s6,80002794 <wait+0x76>
    8000277c:	4691                	li	a3,4
    8000277e:	02c48613          	addi	a2,s1,44
    80002782:	85da                	mv	a1,s6
    80002784:	07093503          	ld	a0,112(s2)
    80002788:	fffff097          	auipc	ra,0xfffff
    8000278c:	f0e080e7          	jalr	-242(ra) # 80001696 <copyout>
    80002790:	02054563          	bltz	a0,800027ba <wait+0x9c>
          freeproc(np);
    80002794:	8526                	mv	a0,s1
    80002796:	00000097          	auipc	ra,0x0
    8000279a:	844080e7          	jalr	-1980(ra) # 80001fda <freeproc>
          release(&np->lock);
    8000279e:	8526                	mv	a0,s1
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	50a080e7          	jalr	1290(ra) # 80000caa <release>
          release(&wait_lock);
    800027a8:	0000f517          	auipc	a0,0xf
    800027ac:	f7050513          	addi	a0,a0,-144 # 80011718 <wait_lock>
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	4fa080e7          	jalr	1274(ra) # 80000caa <release>
          return pid;
    800027b8:	a09d                	j	8000281e <wait+0x100>
            release(&np->lock);
    800027ba:	8526                	mv	a0,s1
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	4ee080e7          	jalr	1262(ra) # 80000caa <release>
            release(&wait_lock);
    800027c4:	0000f517          	auipc	a0,0xf
    800027c8:	f5450513          	addi	a0,a0,-172 # 80011718 <wait_lock>
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	4de080e7          	jalr	1246(ra) # 80000caa <release>
            return -1;
    800027d4:	59fd                	li	s3,-1
    800027d6:	a0a1                	j	8000281e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800027d8:	18848493          	addi	s1,s1,392
    800027dc:	03348463          	beq	s1,s3,80002804 <wait+0xe6>
      if(np->parent == p){
    800027e0:	6cbc                	ld	a5,88(s1)
    800027e2:	ff279be3          	bne	a5,s2,800027d8 <wait+0xba>
        acquire(&np->lock);
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800027f0:	4c9c                	lw	a5,24(s1)
    800027f2:	f94781e3          	beq	a5,s4,80002774 <wait+0x56>
        release(&np->lock);
    800027f6:	8526                	mv	a0,s1
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	4b2080e7          	jalr	1202(ra) # 80000caa <release>
        havekids = 1;
    80002800:	8756                	mv	a4,s5
    80002802:	bfd9                	j	800027d8 <wait+0xba>
    if(!havekids || p->killed){
    80002804:	c701                	beqz	a4,8000280c <wait+0xee>
    80002806:	02892783          	lw	a5,40(s2)
    8000280a:	c79d                	beqz	a5,80002838 <wait+0x11a>
      release(&wait_lock);
    8000280c:	0000f517          	auipc	a0,0xf
    80002810:	f0c50513          	addi	a0,a0,-244 # 80011718 <wait_lock>
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	496080e7          	jalr	1174(ra) # 80000caa <release>
      return -1;
    8000281c:	59fd                	li	s3,-1
}
    8000281e:	854e                	mv	a0,s3
    80002820:	60a6                	ld	ra,72(sp)
    80002822:	6406                	ld	s0,64(sp)
    80002824:	74e2                	ld	s1,56(sp)
    80002826:	7942                	ld	s2,48(sp)
    80002828:	79a2                	ld	s3,40(sp)
    8000282a:	7a02                	ld	s4,32(sp)
    8000282c:	6ae2                	ld	s5,24(sp)
    8000282e:	6b42                	ld	s6,16(sp)
    80002830:	6ba2                	ld	s7,8(sp)
    80002832:	6c02                	ld	s8,0(sp)
    80002834:	6161                	addi	sp,sp,80
    80002836:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002838:	85e2                	mv	a1,s8
    8000283a:	854a                	mv	a0,s2
    8000283c:	00000097          	auipc	ra,0x0
    80002840:	e62080e7          	jalr	-414(ra) # 8000269e <sleep>
    havekids = 0;
    80002844:	b715                	j	80002768 <wait+0x4a>

0000000080002846 <wakeup>:

void
wakeup(void * chan){
  struct proc *p;
  int index = sleeping;
    80002846:	00006797          	auipc	a5,0x6
    8000284a:	0867a783          	lw	a5,134(a5) # 800088cc <sleeping>
  int pred, next = -1;
  if (index == -1)
    8000284e:	577d                	li	a4,-1
    80002850:	10e78963          	beq	a5,a4,80002962 <wakeup+0x11c>
wakeup(void * chan){
    80002854:	7119                	addi	sp,sp,-128
    80002856:	fc86                	sd	ra,120(sp)
    80002858:	f8a2                	sd	s0,112(sp)
    8000285a:	f4a6                	sd	s1,104(sp)
    8000285c:	f0ca                	sd	s2,96(sp)
    8000285e:	ecce                	sd	s3,88(sp)
    80002860:	e8d2                	sd	s4,80(sp)
    80002862:	e4d6                	sd	s5,72(sp)
    80002864:	e0da                	sd	s6,64(sp)
    80002866:	fc5e                	sd	s7,56(sp)
    80002868:	f862                	sd	s8,48(sp)
    8000286a:	f466                	sd	s9,40(sp)
    8000286c:	f06a                	sd	s10,32(sp)
    8000286e:	ec6e                	sd	s11,24(sp)
    80002870:	0100                	addi	s0,sp,128
    80002872:	8b2a                	mv	s6,a0
  int index = sleeping;
    80002874:	f8f42623          	sw	a5,-116(s0)
  int pred, next = -1;
    80002878:	597d                	li	s2,-1
    return;
  
  do {
    p = &proc[index];
    8000287a:	18800a93          	li	s5,392
    8000287e:	0000fa17          	auipc	s4,0xf
    80002882:	ffaa0a13          	addi	s4,s4,-6 # 80011878 <proc>
    if (p != myproc()) {
      acquire(&p->lock);
      next = p->next;
      if(p->chan == chan && p->state == SLEEPING){
    80002886:	4b89                	li	s7,2
        p->chan = 0;
        p->state = RUNNABLE;
    80002888:	4d8d                	li	s11,3
        // release(&p->lock);
        remove_from_list(p->index, &sleeping, &sleeping_head);
    8000288a:	0000fd17          	auipc	s10,0xf
    8000288e:	ea6d0d13          	addi	s10,s10,-346 # 80011730 <sleeping_head>
         #ifdef ON
          int cpui = leastUsedCPU();
          p->cpu_num = cpui;
          inc_cpu_usage(cpui);
          #endif
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    80002892:	0000fc97          	auipc	s9,0xf
    80002896:	ee6c8c93          	addi	s9,s9,-282 # 80011778 <cpus_head>
    8000289a:	0000fc17          	auipc	s8,0xf
    8000289e:	e46c0c13          	addi	s8,s8,-442 # 800116e0 <cpus_ll>
    800028a2:	a0bd                	j	80002910 <wakeup+0xca>
        p->chan = 0;
    800028a4:	0204b023          	sd	zero,32(s1)
        p->state = RUNNABLE;
    800028a8:	01b4ac23          	sw	s11,24(s1)
        remove_from_list(p->index, &sleeping, &sleeping_head);
    800028ac:	866a                	mv	a2,s10
    800028ae:	00006597          	auipc	a1,0x6
    800028b2:	01e58593          	addi	a1,a1,30 # 800088cc <sleeping>
    800028b6:	5c88                	lw	a0,56(s1)
    800028b8:	fffff097          	auipc	ra,0xfffff
    800028bc:	ff2080e7          	jalr	-14(ra) # 800018aa <remove_from_list>
          int cpui = leastUsedCPU();
    800028c0:	fffff097          	auipc	ra,0xfffff
    800028c4:	fa2080e7          	jalr	-94(ra) # 80001862 <leastUsedCPU>
          p->cpu_num = cpui;
    800028c8:	d8c8                	sw	a0,52(s1)
          inc_cpu_usage(cpui);
    800028ca:	fffff097          	auipc	ra,0xfffff
    800028ce:	598080e7          	jalr	1432(ra) # 80001e62 <inc_cpu_usage>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    800028d2:	58cc                	lw	a1,52(s1)
    800028d4:	00159613          	slli	a2,a1,0x1
    800028d8:	962e                	add	a2,a2,a1
    800028da:	060e                	slli	a2,a2,0x3
    800028dc:	058a                	slli	a1,a1,0x2
    800028de:	9666                	add	a2,a2,s9
    800028e0:	95e2                	add	a1,a1,s8
    800028e2:	5c88                	lw	a0,56(s1)
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	1e8080e7          	jalr	488(ra) # 80001acc <insert_to_list>
        // acquire(&p->lock);
      }
    release(&p->lock);
    800028ec:	8526                	mv	a0,s1
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	3bc080e7          	jalr	956(ra) # 80000caa <release>
    }
    pred = index;
    } while(!cas(&index, pred, next) && next != -1);
    800028f6:	864a                	mv	a2,s2
    800028f8:	f8c42583          	lw	a1,-116(s0)
    800028fc:	f8c40513          	addi	a0,s0,-116
    80002900:	00004097          	auipc	ra,0x4
    80002904:	0c6080e7          	jalr	198(ra) # 800069c6 <cas>
    80002908:	ed15                	bnez	a0,80002944 <wakeup+0xfe>
    8000290a:	57fd                	li	a5,-1
    8000290c:	02f90c63          	beq	s2,a5,80002944 <wakeup+0xfe>
    p = &proc[index];
    80002910:	f8c42983          	lw	s3,-116(s0)
    80002914:	035984b3          	mul	s1,s3,s5
    80002918:	94d2                	add	s1,s1,s4
    if (p != myproc()) {
    8000291a:	fffff097          	auipc	ra,0xfffff
    8000291e:	4c2080e7          	jalr	1218(ra) # 80001ddc <myproc>
    80002922:	fca48ae3          	beq	s1,a0,800028f6 <wakeup+0xb0>
      acquire(&p->lock);
    80002926:	8526                	mv	a0,s1
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	2bc080e7          	jalr	700(ra) # 80000be4 <acquire>
      next = p->next;
    80002930:	03c4a903          	lw	s2,60(s1)
    80002934:	2901                	sext.w	s2,s2
      if(p->chan == chan && p->state == SLEEPING){
    80002936:	709c                	ld	a5,32(s1)
    80002938:	fb679ae3          	bne	a5,s6,800028ec <wakeup+0xa6>
    8000293c:	4c9c                	lw	a5,24(s1)
    8000293e:	fb7797e3          	bne	a5,s7,800028ec <wakeup+0xa6>
    80002942:	b78d                	j	800028a4 <wakeup+0x5e>
  }
    80002944:	70e6                	ld	ra,120(sp)
    80002946:	7446                	ld	s0,112(sp)
    80002948:	74a6                	ld	s1,104(sp)
    8000294a:	7906                	ld	s2,96(sp)
    8000294c:	69e6                	ld	s3,88(sp)
    8000294e:	6a46                	ld	s4,80(sp)
    80002950:	6aa6                	ld	s5,72(sp)
    80002952:	6b06                	ld	s6,64(sp)
    80002954:	7be2                	ld	s7,56(sp)
    80002956:	7c42                	ld	s8,48(sp)
    80002958:	7ca2                	ld	s9,40(sp)
    8000295a:	7d02                	ld	s10,32(sp)
    8000295c:	6de2                	ld	s11,24(sp)
    8000295e:	6109                	addi	sp,sp,128
    80002960:	8082                	ret
    80002962:	8082                	ret

0000000080002964 <reparent>:
{
    80002964:	7179                	addi	sp,sp,-48
    80002966:	f406                	sd	ra,40(sp)
    80002968:	f022                	sd	s0,32(sp)
    8000296a:	ec26                	sd	s1,24(sp)
    8000296c:	e84a                	sd	s2,16(sp)
    8000296e:	e44e                	sd	s3,8(sp)
    80002970:	e052                	sd	s4,0(sp)
    80002972:	1800                	addi	s0,sp,48
    80002974:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002976:	0000f497          	auipc	s1,0xf
    8000297a:	f0248493          	addi	s1,s1,-254 # 80011878 <proc>
      pp->parent = initproc;
    8000297e:	00006a17          	auipc	s4,0x6
    80002982:	6aaa0a13          	addi	s4,s4,1706 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002986:	00015997          	auipc	s3,0x15
    8000298a:	0f298993          	addi	s3,s3,242 # 80017a78 <tickslock>
    8000298e:	a029                	j	80002998 <reparent+0x34>
    80002990:	18848493          	addi	s1,s1,392
    80002994:	01348d63          	beq	s1,s3,800029ae <reparent+0x4a>
    if(pp->parent == p){
    80002998:	6cbc                	ld	a5,88(s1)
    8000299a:	ff279be3          	bne	a5,s2,80002990 <reparent+0x2c>
      pp->parent = initproc;
    8000299e:	000a3503          	ld	a0,0(s4)
    800029a2:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	ea2080e7          	jalr	-350(ra) # 80002846 <wakeup>
    800029ac:	b7d5                	j	80002990 <reparent+0x2c>
}
    800029ae:	70a2                	ld	ra,40(sp)
    800029b0:	7402                	ld	s0,32(sp)
    800029b2:	64e2                	ld	s1,24(sp)
    800029b4:	6942                	ld	s2,16(sp)
    800029b6:	69a2                	ld	s3,8(sp)
    800029b8:	6a02                	ld	s4,0(sp)
    800029ba:	6145                	addi	sp,sp,48
    800029bc:	8082                	ret

00000000800029be <exit>:
{
    800029be:	7179                	addi	sp,sp,-48
    800029c0:	f406                	sd	ra,40(sp)
    800029c2:	f022                	sd	s0,32(sp)
    800029c4:	ec26                	sd	s1,24(sp)
    800029c6:	e84a                	sd	s2,16(sp)
    800029c8:	e44e                	sd	s3,8(sp)
    800029ca:	e052                	sd	s4,0(sp)
    800029cc:	1800                	addi	s0,sp,48
    800029ce:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	40c080e7          	jalr	1036(ra) # 80001ddc <myproc>
    800029d8:	89aa                	mv	s3,a0
  if(p == initproc)
    800029da:	00006797          	auipc	a5,0x6
    800029de:	64e7b783          	ld	a5,1614(a5) # 80009028 <initproc>
    800029e2:	0f050493          	addi	s1,a0,240
    800029e6:	17050913          	addi	s2,a0,368
    800029ea:	02a79363          	bne	a5,a0,80002a10 <exit+0x52>
    panic("init exiting");
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	90a50513          	addi	a0,a0,-1782 # 800082f8 <digits+0x2b8>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>
      fileclose(f);
    800029fe:	00002097          	auipc	ra,0x2
    80002a02:	2d4080e7          	jalr	724(ra) # 80004cd2 <fileclose>
      p->ofile[fd] = 0;
    80002a06:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a0a:	04a1                	addi	s1,s1,8
    80002a0c:	01248563          	beq	s1,s2,80002a16 <exit+0x58>
    if(p->ofile[fd]){
    80002a10:	6088                	ld	a0,0(s1)
    80002a12:	f575                	bnez	a0,800029fe <exit+0x40>
    80002a14:	bfdd                	j	80002a0a <exit+0x4c>
  begin_op();
    80002a16:	00002097          	auipc	ra,0x2
    80002a1a:	df0080e7          	jalr	-528(ra) # 80004806 <begin_op>
  iput(p->cwd);
    80002a1e:	1709b503          	ld	a0,368(s3)
    80002a22:	00001097          	auipc	ra,0x1
    80002a26:	5cc080e7          	jalr	1484(ra) # 80003fee <iput>
  end_op();
    80002a2a:	00002097          	auipc	ra,0x2
    80002a2e:	e5c080e7          	jalr	-420(ra) # 80004886 <end_op>
  p->cwd = 0;
    80002a32:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002a36:	0000f497          	auipc	s1,0xf
    80002a3a:	ce248493          	addi	s1,s1,-798 # 80011718 <wait_lock>
    80002a3e:	8526                	mv	a0,s1
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	1a4080e7          	jalr	420(ra) # 80000be4 <acquire>
  reparent(p);
    80002a48:	854e                	mv	a0,s3
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	f1a080e7          	jalr	-230(ra) # 80002964 <reparent>
  wakeup(p->parent);
    80002a52:	0589b503          	ld	a0,88(s3)
    80002a56:	00000097          	auipc	ra,0x0
    80002a5a:	df0080e7          	jalr	-528(ra) # 80002846 <wakeup>
  acquire(&p->lock);
    80002a5e:	854e                	mv	a0,s3
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	184080e7          	jalr	388(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a68:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002a6c:	4795                	li	a5,5
    80002a6e:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index, &zombie, &zombie_head);
    80002a72:	0000f617          	auipc	a2,0xf
    80002a76:	cd660613          	addi	a2,a2,-810 # 80011748 <zombie_head>
    80002a7a:	00006597          	auipc	a1,0x6
    80002a7e:	e4e58593          	addi	a1,a1,-434 # 800088c8 <zombie>
    80002a82:	0389a503          	lw	a0,56(s3)
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	046080e7          	jalr	70(ra) # 80001acc <insert_to_list>
  release(&wait_lock);
    80002a8e:	8526                	mv	a0,s1
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	21a080e7          	jalr	538(ra) # 80000caa <release>
  sched();
    80002a98:	00000097          	auipc	ra,0x0
    80002a9c:	ab2080e7          	jalr	-1358(ra) # 8000254a <sched>
  panic("zombie exit");
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	86850513          	addi	a0,a0,-1944 # 80008308 <digits+0x2c8>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	a96080e7          	jalr	-1386(ra) # 8000053e <panic>

0000000080002ab0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002ab0:	7179                	addi	sp,sp,-48
    80002ab2:	f406                	sd	ra,40(sp)
    80002ab4:	f022                	sd	s0,32(sp)
    80002ab6:	ec26                	sd	s1,24(sp)
    80002ab8:	e84a                	sd	s2,16(sp)
    80002aba:	e44e                	sd	s3,8(sp)
    80002abc:	1800                	addi	s0,sp,48
    80002abe:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002ac0:	0000f497          	auipc	s1,0xf
    80002ac4:	db848493          	addi	s1,s1,-584 # 80011878 <proc>
    80002ac8:	00015997          	auipc	s3,0x15
    80002acc:	fb098993          	addi	s3,s3,-80 # 80017a78 <tickslock>
    acquire(&p->lock);
    80002ad0:	8526                	mv	a0,s1
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	112080e7          	jalr	274(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002ada:	589c                	lw	a5,48(s1)
    80002adc:	01278d63          	beq	a5,s2,80002af6 <kill+0x46>
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002ae0:	8526                	mv	a0,s1
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	1c8080e7          	jalr	456(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002aea:	18848493          	addi	s1,s1,392
    80002aee:	ff3491e3          	bne	s1,s3,80002ad0 <kill+0x20>
  }
  return -1;
    80002af2:	557d                	li	a0,-1
    80002af4:	a829                	j	80002b0e <kill+0x5e>
      p->killed = 1;
    80002af6:	4785                	li	a5,1
    80002af8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002afa:	4c98                	lw	a4,24(s1)
    80002afc:	4789                	li	a5,2
    80002afe:	00f70f63          	beq	a4,a5,80002b1c <kill+0x6c>
      release(&p->lock);
    80002b02:	8526                	mv	a0,s1
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	1a6080e7          	jalr	422(ra) # 80000caa <release>
      return 0;
    80002b0c:	4501                	li	a0,0
}
    80002b0e:	70a2                	ld	ra,40(sp)
    80002b10:	7402                	ld	s0,32(sp)
    80002b12:	64e2                	ld	s1,24(sp)
    80002b14:	6942                	ld	s2,16(sp)
    80002b16:	69a2                	ld	s3,8(sp)
    80002b18:	6145                	addi	sp,sp,48
    80002b1a:	8082                	ret
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002b1c:	0000f617          	auipc	a2,0xf
    80002b20:	c1460613          	addi	a2,a2,-1004 # 80011730 <sleeping_head>
    80002b24:	00006597          	auipc	a1,0x6
    80002b28:	da858593          	addi	a1,a1,-600 # 800088cc <sleeping>
    80002b2c:	5c88                	lw	a0,56(s1)
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	d7c080e7          	jalr	-644(ra) # 800018aa <remove_from_list>
        p->state = RUNNABLE;
    80002b36:	478d                	li	a5,3
    80002b38:	cc9c                	sw	a5,24(s1)
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002b3a:	58dc                	lw	a5,52(s1)
    80002b3c:	00179713          	slli	a4,a5,0x1
    80002b40:	973e                	add	a4,a4,a5
    80002b42:	070e                	slli	a4,a4,0x3
    80002b44:	078a                	slli	a5,a5,0x2
    80002b46:	0000f617          	auipc	a2,0xf
    80002b4a:	c3260613          	addi	a2,a2,-974 # 80011778 <cpus_head>
    80002b4e:	963a                	add	a2,a2,a4
    80002b50:	0000f597          	auipc	a1,0xf
    80002b54:	b9058593          	addi	a1,a1,-1136 # 800116e0 <cpus_ll>
    80002b58:	95be                	add	a1,a1,a5
    80002b5a:	5c88                	lw	a0,56(s1)
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	f70080e7          	jalr	-144(ra) # 80001acc <insert_to_list>
    80002b64:	bf79                	j	80002b02 <kill+0x52>

0000000080002b66 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len){
    80002b66:	7179                	addi	sp,sp,-48
    80002b68:	f406                	sd	ra,40(sp)
    80002b6a:	f022                	sd	s0,32(sp)
    80002b6c:	ec26                	sd	s1,24(sp)
    80002b6e:	e84a                	sd	s2,16(sp)
    80002b70:	e44e                	sd	s3,8(sp)
    80002b72:	e052                	sd	s4,0(sp)
    80002b74:	1800                	addi	s0,sp,48
    80002b76:	84aa                	mv	s1,a0
    80002b78:	892e                	mv	s2,a1
    80002b7a:	89b2                	mv	s3,a2
    80002b7c:	8a36                	mv	s4,a3

  struct proc *p = myproc();
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	25e080e7          	jalr	606(ra) # 80001ddc <myproc>
  if(user_dst){
    80002b86:	c08d                	beqz	s1,80002ba8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002b88:	86d2                	mv	a3,s4
    80002b8a:	864e                	mv	a2,s3
    80002b8c:	85ca                	mv	a1,s2
    80002b8e:	7928                	ld	a0,112(a0)
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	b06080e7          	jalr	-1274(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002b98:	70a2                	ld	ra,40(sp)
    80002b9a:	7402                	ld	s0,32(sp)
    80002b9c:	64e2                	ld	s1,24(sp)
    80002b9e:	6942                	ld	s2,16(sp)
    80002ba0:	69a2                	ld	s3,8(sp)
    80002ba2:	6a02                	ld	s4,0(sp)
    80002ba4:	6145                	addi	sp,sp,48
    80002ba6:	8082                	ret
    memmove((char *)dst, src, len);
    80002ba8:	000a061b          	sext.w	a2,s4
    80002bac:	85ce                	mv	a1,s3
    80002bae:	854a                	mv	a0,s2
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	1b4080e7          	jalr	436(ra) # 80000d64 <memmove>
    return 0;
    80002bb8:	8526                	mv	a0,s1
    80002bba:	bff9                	j	80002b98 <either_copyout+0x32>

0000000080002bbc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002bbc:	7179                	addi	sp,sp,-48
    80002bbe:	f406                	sd	ra,40(sp)
    80002bc0:	f022                	sd	s0,32(sp)
    80002bc2:	ec26                	sd	s1,24(sp)
    80002bc4:	e84a                	sd	s2,16(sp)
    80002bc6:	e44e                	sd	s3,8(sp)
    80002bc8:	e052                	sd	s4,0(sp)
    80002bca:	1800                	addi	s0,sp,48
    80002bcc:	892a                	mv	s2,a0
    80002bce:	84ae                	mv	s1,a1
    80002bd0:	89b2                	mv	s3,a2
    80002bd2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	208080e7          	jalr	520(ra) # 80001ddc <myproc>
  if(user_src){
    80002bdc:	c08d                	beqz	s1,80002bfe <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002bde:	86d2                	mv	a3,s4
    80002be0:	864e                	mv	a2,s3
    80002be2:	85ca                	mv	a1,s2
    80002be4:	7928                	ld	a0,112(a0)
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	b3c080e7          	jalr	-1220(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002bee:	70a2                	ld	ra,40(sp)
    80002bf0:	7402                	ld	s0,32(sp)
    80002bf2:	64e2                	ld	s1,24(sp)
    80002bf4:	6942                	ld	s2,16(sp)
    80002bf6:	69a2                	ld	s3,8(sp)
    80002bf8:	6a02                	ld	s4,0(sp)
    80002bfa:	6145                	addi	sp,sp,48
    80002bfc:	8082                	ret
    memmove(dst, (char*)src, len);
    80002bfe:	000a061b          	sext.w	a2,s4
    80002c02:	85ce                	mv	a1,s3
    80002c04:	854a                	mv	a0,s2
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	15e080e7          	jalr	350(ra) # 80000d64 <memmove>
    return 0;
    80002c0e:	8526                	mv	a0,s1
    80002c10:	bff9                	j	80002bee <either_copyin+0x32>

0000000080002c12 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002c12:	715d                	addi	sp,sp,-80
    80002c14:	e486                	sd	ra,72(sp)
    80002c16:	e0a2                	sd	s0,64(sp)
    80002c18:	fc26                	sd	s1,56(sp)
    80002c1a:	f84a                	sd	s2,48(sp)
    80002c1c:	f44e                	sd	s3,40(sp)
    80002c1e:	f052                	sd	s4,32(sp)
    80002c20:	ec56                	sd	s5,24(sp)
    80002c22:	e85a                	sd	s6,16(sp)
    80002c24:	e45e                	sd	s7,8(sp)
    80002c26:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	4d050513          	addi	a0,a0,1232 # 800080f8 <digits+0xb8>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	958080e7          	jalr	-1704(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c38:	0000f497          	auipc	s1,0xf
    80002c3c:	db848493          	addi	s1,s1,-584 # 800119f0 <proc+0x178>
    80002c40:	00015917          	auipc	s2,0x15
    80002c44:	fb090913          	addi	s2,s2,-80 # 80017bf0 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c48:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002c4a:	00005997          	auipc	s3,0x5
    80002c4e:	6ce98993          	addi	s3,s3,1742 # 80008318 <digits+0x2d8>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002c52:	00005a97          	auipc	s5,0x5
    80002c56:	6cea8a93          	addi	s5,s5,1742 # 80008320 <digits+0x2e0>
    printf("\n");
    80002c5a:	00005a17          	auipc	s4,0x5
    80002c5e:	49ea0a13          	addi	s4,s4,1182 # 800080f8 <digits+0xb8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c62:	00005b97          	auipc	s7,0x5
    80002c66:	6f6b8b93          	addi	s7,s7,1782 # 80008358 <states.1787>
    80002c6a:	a01d                	j	80002c90 <procdump+0x7e>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002c6c:	ebc6a703          	lw	a4,-324(a3)
    80002c70:	eb86a583          	lw	a1,-328(a3)
    80002c74:	8556                	mv	a0,s5
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	912080e7          	jalr	-1774(ra) # 80000588 <printf>
    printf("\n");
    80002c7e:	8552                	mv	a0,s4
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	908080e7          	jalr	-1784(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c88:	18848493          	addi	s1,s1,392
    80002c8c:	03248163          	beq	s1,s2,80002cae <procdump+0x9c>
    if(p->state == UNUSED)
    80002c90:	86a6                	mv	a3,s1
    80002c92:	ea04a783          	lw	a5,-352(s1)
    80002c96:	dbed                	beqz	a5,80002c88 <procdump+0x76>
      state = "???";
    80002c98:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c9a:	fcfb69e3          	bltu	s6,a5,80002c6c <procdump+0x5a>
    80002c9e:	1782                	slli	a5,a5,0x20
    80002ca0:	9381                	srli	a5,a5,0x20
    80002ca2:	078e                	slli	a5,a5,0x3
    80002ca4:	97de                	add	a5,a5,s7
    80002ca6:	6390                	ld	a2,0(a5)
    80002ca8:	f271                	bnez	a2,80002c6c <procdump+0x5a>
      state = "???";
    80002caa:	864e                	mv	a2,s3
    80002cac:	b7c1                	j	80002c6c <procdump+0x5a>
  }
}
    80002cae:	60a6                	ld	ra,72(sp)
    80002cb0:	6406                	ld	s0,64(sp)
    80002cb2:	74e2                	ld	s1,56(sp)
    80002cb4:	7942                	ld	s2,48(sp)
    80002cb6:	79a2                	ld	s3,40(sp)
    80002cb8:	7a02                	ld	s4,32(sp)
    80002cba:	6ae2                	ld	s5,24(sp)
    80002cbc:	6b42                	ld	s6,16(sp)
    80002cbe:	6ba2                	ld	s7,8(sp)
    80002cc0:	6161                	addi	sp,sp,80
    80002cc2:	8082                	ret

0000000080002cc4 <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002cc4:	1101                	addi	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	e426                	sd	s1,8(sp)
    80002ccc:	1000                	addi	s0,sp,32
    80002cce:	84aa                	mv	s1,a0
// printf("%d\n", 12);
  struct proc *p= myproc();  
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	10c080e7          	jalr	268(ra) # 80001ddc <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002cd8:	8626                	mv	a2,s1
    80002cda:	594c                	lw	a1,52(a0)
    80002cdc:	03450513          	addi	a0,a0,52
    80002ce0:	00004097          	auipc	ra,0x4
    80002ce4:	ce6080e7          	jalr	-794(ra) # 800069c6 <cas>
    80002ce8:	e519                	bnez	a0,80002cf6 <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002cea:	4501                	li	a0,0
}
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	64a2                	ld	s1,8(sp)
    80002cf2:	6105                	addi	sp,sp,32
    80002cf4:	8082                	ret
    yield();
    80002cf6:	00000097          	auipc	ra,0x0
    80002cfa:	942080e7          	jalr	-1726(ra) # 80002638 <yield>
    return cpu_num;
    80002cfe:	8526                	mv	a0,s1
    80002d00:	b7f5                	j	80002cec <set_cpu+0x28>

0000000080002d02 <get_cpu>:

int get_cpu(){ //added as orderd
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	1000                	addi	s0,sp,32
// printf("%d\n", 13);
  struct proc *p = myproc();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	0d2080e7          	jalr	210(ra) # 80001ddc <myproc>
  int ans=0;
    80002d12:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002d16:	5950                	lw	a2,52(a0)
    80002d18:	4581                	li	a1,0
    80002d1a:	fec40513          	addi	a0,s0,-20
    80002d1e:	00004097          	auipc	ra,0x4
    80002d22:	ca8080e7          	jalr	-856(ra) # 800069c6 <cas>
    return ans;
}
    80002d26:	fec42503          	lw	a0,-20(s0)
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <cpu_process_count>:

// int cpu_process_count (int cpu_num){
//   return cpu_usage[cpu_num];
// }
int cpu_process_count(int cpu_num){
    80002d32:	1141                	addi	sp,sp,-16
    80002d34:	e422                	sd	s0,8(sp)
    80002d36:	0800                	addi	s0,sp,16
  struct cpu* c = &cpus[cpu_num];
  uint64 procsNum = c->admittedProcs;
    80002d38:	00451793          	slli	a5,a0,0x4
    80002d3c:	97aa                	add	a5,a5,a0
    80002d3e:	078e                	slli	a5,a5,0x3
    80002d40:	0000e517          	auipc	a0,0xe
    80002d44:	56050513          	addi	a0,a0,1376 # 800112a0 <cpus>
    80002d48:	97aa                	add	a5,a5,a0
  return procsNum;
}
    80002d4a:	0807a503          	lw	a0,128(a5)
    80002d4e:	6422                	ld	s0,8(sp)
    80002d50:	0141                	addi	sp,sp,16
    80002d52:	8082                	ret

0000000080002d54 <swtch>:
    80002d54:	00153023          	sd	ra,0(a0)
    80002d58:	00253423          	sd	sp,8(a0)
    80002d5c:	e900                	sd	s0,16(a0)
    80002d5e:	ed04                	sd	s1,24(a0)
    80002d60:	03253023          	sd	s2,32(a0)
    80002d64:	03353423          	sd	s3,40(a0)
    80002d68:	03453823          	sd	s4,48(a0)
    80002d6c:	03553c23          	sd	s5,56(a0)
    80002d70:	05653023          	sd	s6,64(a0)
    80002d74:	05753423          	sd	s7,72(a0)
    80002d78:	05853823          	sd	s8,80(a0)
    80002d7c:	05953c23          	sd	s9,88(a0)
    80002d80:	07a53023          	sd	s10,96(a0)
    80002d84:	07b53423          	sd	s11,104(a0)
    80002d88:	0005b083          	ld	ra,0(a1)
    80002d8c:	0085b103          	ld	sp,8(a1)
    80002d90:	6980                	ld	s0,16(a1)
    80002d92:	6d84                	ld	s1,24(a1)
    80002d94:	0205b903          	ld	s2,32(a1)
    80002d98:	0285b983          	ld	s3,40(a1)
    80002d9c:	0305ba03          	ld	s4,48(a1)
    80002da0:	0385ba83          	ld	s5,56(a1)
    80002da4:	0405bb03          	ld	s6,64(a1)
    80002da8:	0485bb83          	ld	s7,72(a1)
    80002dac:	0505bc03          	ld	s8,80(a1)
    80002db0:	0585bc83          	ld	s9,88(a1)
    80002db4:	0605bd03          	ld	s10,96(a1)
    80002db8:	0685bd83          	ld	s11,104(a1)
    80002dbc:	8082                	ret

0000000080002dbe <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002dbe:	1141                	addi	sp,sp,-16
    80002dc0:	e406                	sd	ra,8(sp)
    80002dc2:	e022                	sd	s0,0(sp)
    80002dc4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002dc6:	00005597          	auipc	a1,0x5
    80002dca:	5c258593          	addi	a1,a1,1474 # 80008388 <states.1787+0x30>
    80002dce:	00015517          	auipc	a0,0x15
    80002dd2:	caa50513          	addi	a0,a0,-854 # 80017a78 <tickslock>
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	d7e080e7          	jalr	-642(ra) # 80000b54 <initlock>
}
    80002dde:	60a2                	ld	ra,8(sp)
    80002de0:	6402                	ld	s0,0(sp)
    80002de2:	0141                	addi	sp,sp,16
    80002de4:	8082                	ret

0000000080002de6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e422                	sd	s0,8(sp)
    80002dea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dec:	00003797          	auipc	a5,0x3
    80002df0:	50478793          	addi	a5,a5,1284 # 800062f0 <kernelvec>
    80002df4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002df8:	6422                	ld	s0,8(sp)
    80002dfa:	0141                	addi	sp,sp,16
    80002dfc:	8082                	ret

0000000080002dfe <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002dfe:	1141                	addi	sp,sp,-16
    80002e00:	e406                	sd	ra,8(sp)
    80002e02:	e022                	sd	s0,0(sp)
    80002e04:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	fd6080e7          	jalr	-42(ra) # 80001ddc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e14:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e18:	00004617          	auipc	a2,0x4
    80002e1c:	1e860613          	addi	a2,a2,488 # 80007000 <_trampoline>
    80002e20:	00004697          	auipc	a3,0x4
    80002e24:	1e068693          	addi	a3,a3,480 # 80007000 <_trampoline>
    80002e28:	8e91                	sub	a3,a3,a2
    80002e2a:	040007b7          	lui	a5,0x4000
    80002e2e:	17fd                	addi	a5,a5,-1
    80002e30:	07b2                	slli	a5,a5,0xc
    80002e32:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e34:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e38:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e3a:	180026f3          	csrr	a3,satp
    80002e3e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e40:	7d38                	ld	a4,120(a0)
    80002e42:	7134                	ld	a3,96(a0)
    80002e44:	6585                	lui	a1,0x1
    80002e46:	96ae                	add	a3,a3,a1
    80002e48:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e4a:	7d38                	ld	a4,120(a0)
    80002e4c:	00000697          	auipc	a3,0x0
    80002e50:	13868693          	addi	a3,a3,312 # 80002f84 <usertrap>
    80002e54:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e56:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e58:	8692                	mv	a3,tp
    80002e5a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e5c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e60:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e64:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e68:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e6c:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e6e:	6f18                	ld	a4,24(a4)
    80002e70:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e74:	792c                	ld	a1,112(a0)
    80002e76:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e78:	00004717          	auipc	a4,0x4
    80002e7c:	21870713          	addi	a4,a4,536 # 80007090 <userret>
    80002e80:	8f11                	sub	a4,a4,a2
    80002e82:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002e84:	577d                	li	a4,-1
    80002e86:	177e                	slli	a4,a4,0x3f
    80002e88:	8dd9                	or	a1,a1,a4
    80002e8a:	02000537          	lui	a0,0x2000
    80002e8e:	157d                	addi	a0,a0,-1
    80002e90:	0536                	slli	a0,a0,0xd
    80002e92:	9782                	jalr	a5
}
    80002e94:	60a2                	ld	ra,8(sp)
    80002e96:	6402                	ld	s0,0(sp)
    80002e98:	0141                	addi	sp,sp,16
    80002e9a:	8082                	ret

0000000080002e9c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002e9c:	1101                	addi	sp,sp,-32
    80002e9e:	ec06                	sd	ra,24(sp)
    80002ea0:	e822                	sd	s0,16(sp)
    80002ea2:	e426                	sd	s1,8(sp)
    80002ea4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ea6:	00015497          	auipc	s1,0x15
    80002eaa:	bd248493          	addi	s1,s1,-1070 # 80017a78 <tickslock>
    80002eae:	8526                	mv	a0,s1
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	d34080e7          	jalr	-716(ra) # 80000be4 <acquire>
  ticks++;
    80002eb8:	00006517          	auipc	a0,0x6
    80002ebc:	17850513          	addi	a0,a0,376 # 80009030 <ticks>
    80002ec0:	411c                	lw	a5,0(a0)
    80002ec2:	2785                	addiw	a5,a5,1
    80002ec4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	980080e7          	jalr	-1664(ra) # 80002846 <wakeup>
  release(&tickslock);
    80002ece:	8526                	mv	a0,s1
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	dda080e7          	jalr	-550(ra) # 80000caa <release>
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	64a2                	ld	s1,8(sp)
    80002ede:	6105                	addi	sp,sp,32
    80002ee0:	8082                	ret

0000000080002ee2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ee2:	1101                	addi	sp,sp,-32
    80002ee4:	ec06                	sd	ra,24(sp)
    80002ee6:	e822                	sd	s0,16(sp)
    80002ee8:	e426                	sd	s1,8(sp)
    80002eea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eec:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ef0:	00074d63          	bltz	a4,80002f0a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ef4:	57fd                	li	a5,-1
    80002ef6:	17fe                	slli	a5,a5,0x3f
    80002ef8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002efa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002efc:	06f70363          	beq	a4,a5,80002f62 <devintr+0x80>
  }
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret
     (scause & 0xff) == 9){
    80002f0a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f0e:	46a5                	li	a3,9
    80002f10:	fed792e3          	bne	a5,a3,80002ef4 <devintr+0x12>
    int irq = plic_claim();
    80002f14:	00003097          	auipc	ra,0x3
    80002f18:	4e4080e7          	jalr	1252(ra) # 800063f8 <plic_claim>
    80002f1c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f1e:	47a9                	li	a5,10
    80002f20:	02f50763          	beq	a0,a5,80002f4e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f24:	4785                	li	a5,1
    80002f26:	02f50963          	beq	a0,a5,80002f58 <devintr+0x76>
    return 1;
    80002f2a:	4505                	li	a0,1
    } else if(irq){
    80002f2c:	d8f1                	beqz	s1,80002f00 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f2e:	85a6                	mv	a1,s1
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	46050513          	addi	a0,a0,1120 # 80008390 <states.1787+0x38>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f40:	8526                	mv	a0,s1
    80002f42:	00003097          	auipc	ra,0x3
    80002f46:	4da080e7          	jalr	1242(ra) # 8000641c <plic_complete>
    return 1;
    80002f4a:	4505                	li	a0,1
    80002f4c:	bf55                	j	80002f00 <devintr+0x1e>
      uartintr();
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	a5a080e7          	jalr	-1446(ra) # 800009a8 <uartintr>
    80002f56:	b7ed                	j	80002f40 <devintr+0x5e>
      virtio_disk_intr();
    80002f58:	00004097          	auipc	ra,0x4
    80002f5c:	9a4080e7          	jalr	-1628(ra) # 800068fc <virtio_disk_intr>
    80002f60:	b7c5                	j	80002f40 <devintr+0x5e>
    if(cpuid() == 0){
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	e46080e7          	jalr	-442(ra) # 80001da8 <cpuid>
    80002f6a:	c901                	beqz	a0,80002f7a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f6c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f70:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f72:	14479073          	csrw	sip,a5
    return 2;
    80002f76:	4509                	li	a0,2
    80002f78:	b761                	j	80002f00 <devintr+0x1e>
      clockintr();
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	f22080e7          	jalr	-222(ra) # 80002e9c <clockintr>
    80002f82:	b7ed                	j	80002f6c <devintr+0x8a>

0000000080002f84 <usertrap>:
{
    80002f84:	1101                	addi	sp,sp,-32
    80002f86:	ec06                	sd	ra,24(sp)
    80002f88:	e822                	sd	s0,16(sp)
    80002f8a:	e426                	sd	s1,8(sp)
    80002f8c:	e04a                	sd	s2,0(sp)
    80002f8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f90:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002f94:	1007f793          	andi	a5,a5,256
    80002f98:	e3ad                	bnez	a5,80002ffa <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f9a:	00003797          	auipc	a5,0x3
    80002f9e:	35678793          	addi	a5,a5,854 # 800062f0 <kernelvec>
    80002fa2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	e36080e7          	jalr	-458(ra) # 80001ddc <myproc>
    80002fae:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002fb0:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fb2:	14102773          	csrr	a4,sepc
    80002fb6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fb8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002fbc:	47a1                	li	a5,8
    80002fbe:	04f71c63          	bne	a4,a5,80003016 <usertrap+0x92>
    if(p->killed)
    80002fc2:	551c                	lw	a5,40(a0)
    80002fc4:	e3b9                	bnez	a5,8000300a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002fc6:	7cb8                	ld	a4,120(s1)
    80002fc8:	6f1c                	ld	a5,24(a4)
    80002fca:	0791                	addi	a5,a5,4
    80002fcc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fd2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fd6:	10079073          	csrw	sstatus,a5
    syscall();
    80002fda:	00000097          	auipc	ra,0x0
    80002fde:	2e0080e7          	jalr	736(ra) # 800032ba <syscall>
  if(p->killed)
    80002fe2:	549c                	lw	a5,40(s1)
    80002fe4:	ebc1                	bnez	a5,80003074 <usertrap+0xf0>
  usertrapret();
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	e18080e7          	jalr	-488(ra) # 80002dfe <usertrapret>
}
    80002fee:	60e2                	ld	ra,24(sp)
    80002ff0:	6442                	ld	s0,16(sp)
    80002ff2:	64a2                	ld	s1,8(sp)
    80002ff4:	6902                	ld	s2,0(sp)
    80002ff6:	6105                	addi	sp,sp,32
    80002ff8:	8082                	ret
    panic("usertrap: not from user mode");
    80002ffa:	00005517          	auipc	a0,0x5
    80002ffe:	3b650513          	addi	a0,a0,950 # 800083b0 <states.1787+0x58>
    80003002:	ffffd097          	auipc	ra,0xffffd
    80003006:	53c080e7          	jalr	1340(ra) # 8000053e <panic>
      exit(-1);
    8000300a:	557d                	li	a0,-1
    8000300c:	00000097          	auipc	ra,0x0
    80003010:	9b2080e7          	jalr	-1614(ra) # 800029be <exit>
    80003014:	bf4d                	j	80002fc6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003016:	00000097          	auipc	ra,0x0
    8000301a:	ecc080e7          	jalr	-308(ra) # 80002ee2 <devintr>
    8000301e:	892a                	mv	s2,a0
    80003020:	c501                	beqz	a0,80003028 <usertrap+0xa4>
  if(p->killed)
    80003022:	549c                	lw	a5,40(s1)
    80003024:	c3a1                	beqz	a5,80003064 <usertrap+0xe0>
    80003026:	a815                	j	8000305a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003028:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000302c:	5890                	lw	a2,48(s1)
    8000302e:	00005517          	auipc	a0,0x5
    80003032:	3a250513          	addi	a0,a0,930 # 800083d0 <states.1787+0x78>
    80003036:	ffffd097          	auipc	ra,0xffffd
    8000303a:	552080e7          	jalr	1362(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000303e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003042:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	3ba50513          	addi	a0,a0,954 # 80008400 <states.1787+0xa8>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	53a080e7          	jalr	1338(ra) # 80000588 <printf>
    p->killed = 1;
    80003056:	4785                	li	a5,1
    80003058:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000305a:	557d                	li	a0,-1
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	962080e7          	jalr	-1694(ra) # 800029be <exit>
  if(which_dev == 2)
    80003064:	4789                	li	a5,2
    80003066:	f8f910e3          	bne	s2,a5,80002fe6 <usertrap+0x62>
    yield();
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	5ce080e7          	jalr	1486(ra) # 80002638 <yield>
    80003072:	bf95                	j	80002fe6 <usertrap+0x62>
  int which_dev = 0;
    80003074:	4901                	li	s2,0
    80003076:	b7d5                	j	8000305a <usertrap+0xd6>

0000000080003078 <kerneltrap>:
{
    80003078:	7179                	addi	sp,sp,-48
    8000307a:	f406                	sd	ra,40(sp)
    8000307c:	f022                	sd	s0,32(sp)
    8000307e:	ec26                	sd	s1,24(sp)
    80003080:	e84a                	sd	s2,16(sp)
    80003082:	e44e                	sd	s3,8(sp)
    80003084:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003086:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000308a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000308e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003092:	1004f793          	andi	a5,s1,256
    80003096:	cb85                	beqz	a5,800030c6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003098:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000309c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000309e:	ef85                	bnez	a5,800030d6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	e42080e7          	jalr	-446(ra) # 80002ee2 <devintr>
    800030a8:	cd1d                	beqz	a0,800030e6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030aa:	4789                	li	a5,2
    800030ac:	06f50a63          	beq	a0,a5,80003120 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030b0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030b4:	10049073          	csrw	sstatus,s1
}
    800030b8:	70a2                	ld	ra,40(sp)
    800030ba:	7402                	ld	s0,32(sp)
    800030bc:	64e2                	ld	s1,24(sp)
    800030be:	6942                	ld	s2,16(sp)
    800030c0:	69a2                	ld	s3,8(sp)
    800030c2:	6145                	addi	sp,sp,48
    800030c4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030c6:	00005517          	auipc	a0,0x5
    800030ca:	35a50513          	addi	a0,a0,858 # 80008420 <states.1787+0xc8>
    800030ce:	ffffd097          	auipc	ra,0xffffd
    800030d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800030d6:	00005517          	auipc	a0,0x5
    800030da:	37250513          	addi	a0,a0,882 # 80008448 <states.1787+0xf0>
    800030de:	ffffd097          	auipc	ra,0xffffd
    800030e2:	460080e7          	jalr	1120(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800030e6:	85ce                	mv	a1,s3
    800030e8:	00005517          	auipc	a0,0x5
    800030ec:	38050513          	addi	a0,a0,896 # 80008468 <states.1787+0x110>
    800030f0:	ffffd097          	auipc	ra,0xffffd
    800030f4:	498080e7          	jalr	1176(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030f8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030fc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003100:	00005517          	auipc	a0,0x5
    80003104:	37850513          	addi	a0,a0,888 # 80008478 <states.1787+0x120>
    80003108:	ffffd097          	auipc	ra,0xffffd
    8000310c:	480080e7          	jalr	1152(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003110:	00005517          	auipc	a0,0x5
    80003114:	38050513          	addi	a0,a0,896 # 80008490 <states.1787+0x138>
    80003118:	ffffd097          	auipc	ra,0xffffd
    8000311c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	cbc080e7          	jalr	-836(ra) # 80001ddc <myproc>
    80003128:	d541                	beqz	a0,800030b0 <kerneltrap+0x38>
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	cb2080e7          	jalr	-846(ra) # 80001ddc <myproc>
    80003132:	4d18                	lw	a4,24(a0)
    80003134:	4791                	li	a5,4
    80003136:	f6f71de3          	bne	a4,a5,800030b0 <kerneltrap+0x38>
    yield();
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	4fe080e7          	jalr	1278(ra) # 80002638 <yield>
    80003142:	b7bd                	j	800030b0 <kerneltrap+0x38>

0000000080003144 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003144:	1101                	addi	sp,sp,-32
    80003146:	ec06                	sd	ra,24(sp)
    80003148:	e822                	sd	s0,16(sp)
    8000314a:	e426                	sd	s1,8(sp)
    8000314c:	1000                	addi	s0,sp,32
    8000314e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003150:	fffff097          	auipc	ra,0xfffff
    80003154:	c8c080e7          	jalr	-884(ra) # 80001ddc <myproc>
  switch (n) {
    80003158:	4795                	li	a5,5
    8000315a:	0497e163          	bltu	a5,s1,8000319c <argraw+0x58>
    8000315e:	048a                	slli	s1,s1,0x2
    80003160:	00005717          	auipc	a4,0x5
    80003164:	36870713          	addi	a4,a4,872 # 800084c8 <states.1787+0x170>
    80003168:	94ba                	add	s1,s1,a4
    8000316a:	409c                	lw	a5,0(s1)
    8000316c:	97ba                	add	a5,a5,a4
    8000316e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003170:	7d3c                	ld	a5,120(a0)
    80003172:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret
    return p->trapframe->a1;
    8000317e:	7d3c                	ld	a5,120(a0)
    80003180:	7fa8                	ld	a0,120(a5)
    80003182:	bfcd                	j	80003174 <argraw+0x30>
    return p->trapframe->a2;
    80003184:	7d3c                	ld	a5,120(a0)
    80003186:	63c8                	ld	a0,128(a5)
    80003188:	b7f5                	j	80003174 <argraw+0x30>
    return p->trapframe->a3;
    8000318a:	7d3c                	ld	a5,120(a0)
    8000318c:	67c8                	ld	a0,136(a5)
    8000318e:	b7dd                	j	80003174 <argraw+0x30>
    return p->trapframe->a4;
    80003190:	7d3c                	ld	a5,120(a0)
    80003192:	6bc8                	ld	a0,144(a5)
    80003194:	b7c5                	j	80003174 <argraw+0x30>
    return p->trapframe->a5;
    80003196:	7d3c                	ld	a5,120(a0)
    80003198:	6fc8                	ld	a0,152(a5)
    8000319a:	bfe9                	j	80003174 <argraw+0x30>
  panic("argraw");
    8000319c:	00005517          	auipc	a0,0x5
    800031a0:	30450513          	addi	a0,a0,772 # 800084a0 <states.1787+0x148>
    800031a4:	ffffd097          	auipc	ra,0xffffd
    800031a8:	39a080e7          	jalr	922(ra) # 8000053e <panic>

00000000800031ac <fetchaddr>:
{
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	e04a                	sd	s2,0(sp)
    800031b6:	1000                	addi	s0,sp,32
    800031b8:	84aa                	mv	s1,a0
    800031ba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031bc:	fffff097          	auipc	ra,0xfffff
    800031c0:	c20080e7          	jalr	-992(ra) # 80001ddc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031c4:	753c                	ld	a5,104(a0)
    800031c6:	02f4f863          	bgeu	s1,a5,800031f6 <fetchaddr+0x4a>
    800031ca:	00848713          	addi	a4,s1,8
    800031ce:	02e7e663          	bltu	a5,a4,800031fa <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031d2:	46a1                	li	a3,8
    800031d4:	8626                	mv	a2,s1
    800031d6:	85ca                	mv	a1,s2
    800031d8:	7928                	ld	a0,112(a0)
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	548080e7          	jalr	1352(ra) # 80001722 <copyin>
    800031e2:	00a03533          	snez	a0,a0
    800031e6:	40a00533          	neg	a0,a0
}
    800031ea:	60e2                	ld	ra,24(sp)
    800031ec:	6442                	ld	s0,16(sp)
    800031ee:	64a2                	ld	s1,8(sp)
    800031f0:	6902                	ld	s2,0(sp)
    800031f2:	6105                	addi	sp,sp,32
    800031f4:	8082                	ret
    return -1;
    800031f6:	557d                	li	a0,-1
    800031f8:	bfcd                	j	800031ea <fetchaddr+0x3e>
    800031fa:	557d                	li	a0,-1
    800031fc:	b7fd                	j	800031ea <fetchaddr+0x3e>

00000000800031fe <fetchstr>:
{
    800031fe:	7179                	addi	sp,sp,-48
    80003200:	f406                	sd	ra,40(sp)
    80003202:	f022                	sd	s0,32(sp)
    80003204:	ec26                	sd	s1,24(sp)
    80003206:	e84a                	sd	s2,16(sp)
    80003208:	e44e                	sd	s3,8(sp)
    8000320a:	1800                	addi	s0,sp,48
    8000320c:	892a                	mv	s2,a0
    8000320e:	84ae                	mv	s1,a1
    80003210:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003212:	fffff097          	auipc	ra,0xfffff
    80003216:	bca080e7          	jalr	-1078(ra) # 80001ddc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000321a:	86ce                	mv	a3,s3
    8000321c:	864a                	mv	a2,s2
    8000321e:	85a6                	mv	a1,s1
    80003220:	7928                	ld	a0,112(a0)
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	58c080e7          	jalr	1420(ra) # 800017ae <copyinstr>
  if(err < 0)
    8000322a:	00054763          	bltz	a0,80003238 <fetchstr+0x3a>
  return strlen(buf);
    8000322e:	8526                	mv	a0,s1
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	c58080e7          	jalr	-936(ra) # 80000e88 <strlen>
}
    80003238:	70a2                	ld	ra,40(sp)
    8000323a:	7402                	ld	s0,32(sp)
    8000323c:	64e2                	ld	s1,24(sp)
    8000323e:	6942                	ld	s2,16(sp)
    80003240:	69a2                	ld	s3,8(sp)
    80003242:	6145                	addi	sp,sp,48
    80003244:	8082                	ret

0000000080003246 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003246:	1101                	addi	sp,sp,-32
    80003248:	ec06                	sd	ra,24(sp)
    8000324a:	e822                	sd	s0,16(sp)
    8000324c:	e426                	sd	s1,8(sp)
    8000324e:	1000                	addi	s0,sp,32
    80003250:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003252:	00000097          	auipc	ra,0x0
    80003256:	ef2080e7          	jalr	-270(ra) # 80003144 <argraw>
    8000325a:	c088                	sw	a0,0(s1)
  return 0;
}
    8000325c:	4501                	li	a0,0
    8000325e:	60e2                	ld	ra,24(sp)
    80003260:	6442                	ld	s0,16(sp)
    80003262:	64a2                	ld	s1,8(sp)
    80003264:	6105                	addi	sp,sp,32
    80003266:	8082                	ret

0000000080003268 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	e426                	sd	s1,8(sp)
    80003270:	1000                	addi	s0,sp,32
    80003272:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003274:	00000097          	auipc	ra,0x0
    80003278:	ed0080e7          	jalr	-304(ra) # 80003144 <argraw>
    8000327c:	e088                	sd	a0,0(s1)
  return 0;
}
    8000327e:	4501                	li	a0,0
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	64a2                	ld	s1,8(sp)
    80003286:	6105                	addi	sp,sp,32
    80003288:	8082                	ret

000000008000328a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000328a:	1101                	addi	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	e426                	sd	s1,8(sp)
    80003292:	e04a                	sd	s2,0(sp)
    80003294:	1000                	addi	s0,sp,32
    80003296:	84ae                	mv	s1,a1
    80003298:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	eaa080e7          	jalr	-342(ra) # 80003144 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032a2:	864a                	mv	a2,s2
    800032a4:	85a6                	mv	a1,s1
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	f58080e7          	jalr	-168(ra) # 800031fe <fetchstr>
}
    800032ae:	60e2                	ld	ra,24(sp)
    800032b0:	6442                	ld	s0,16(sp)
    800032b2:	64a2                	ld	s1,8(sp)
    800032b4:	6902                	ld	s2,0(sp)
    800032b6:	6105                	addi	sp,sp,32
    800032b8:	8082                	ret

00000000800032ba <syscall>:
[SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    800032ba:	1101                	addi	sp,sp,-32
    800032bc:	ec06                	sd	ra,24(sp)
    800032be:	e822                	sd	s0,16(sp)
    800032c0:	e426                	sd	s1,8(sp)
    800032c2:	e04a                	sd	s2,0(sp)
    800032c4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032c6:	fffff097          	auipc	ra,0xfffff
    800032ca:	b16080e7          	jalr	-1258(ra) # 80001ddc <myproc>
    800032ce:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032d0:	07853903          	ld	s2,120(a0)
    800032d4:	0a893783          	ld	a5,168(s2)
    800032d8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032dc:	37fd                	addiw	a5,a5,-1
    800032de:	475d                	li	a4,23
    800032e0:	00f76f63          	bltu	a4,a5,800032fe <syscall+0x44>
    800032e4:	00369713          	slli	a4,a3,0x3
    800032e8:	00005797          	auipc	a5,0x5
    800032ec:	1f878793          	addi	a5,a5,504 # 800084e0 <syscalls>
    800032f0:	97ba                	add	a5,a5,a4
    800032f2:	639c                	ld	a5,0(a5)
    800032f4:	c789                	beqz	a5,800032fe <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032f6:	9782                	jalr	a5
    800032f8:	06a93823          	sd	a0,112(s2)
    800032fc:	a839                	j	8000331a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032fe:	17848613          	addi	a2,s1,376
    80003302:	588c                	lw	a1,48(s1)
    80003304:	00005517          	auipc	a0,0x5
    80003308:	1a450513          	addi	a0,a0,420 # 800084a8 <states.1787+0x150>
    8000330c:	ffffd097          	auipc	ra,0xffffd
    80003310:	27c080e7          	jalr	636(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003314:	7cbc                	ld	a5,120(s1)
    80003316:	577d                	li	a4,-1
    80003318:	fbb8                	sd	a4,112(a5)
  }
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6902                	ld	s2,0(sp)
    80003322:	6105                	addi	sp,sp,32
    80003324:	8082                	ret

0000000080003326 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003326:	1101                	addi	sp,sp,-32
    80003328:	ec06                	sd	ra,24(sp)
    8000332a:	e822                	sd	s0,16(sp)
    8000332c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000332e:	fec40593          	addi	a1,s0,-20
    80003332:	4501                	li	a0,0
    80003334:	00000097          	auipc	ra,0x0
    80003338:	f12080e7          	jalr	-238(ra) # 80003246 <argint>
    return -1;
    8000333c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000333e:	00054963          	bltz	a0,80003350 <sys_exit+0x2a>
  exit(n);
    80003342:	fec42503          	lw	a0,-20(s0)
    80003346:	fffff097          	auipc	ra,0xfffff
    8000334a:	678080e7          	jalr	1656(ra) # 800029be <exit>
  return 0;  // not reached
    8000334e:	4781                	li	a5,0
}
    80003350:	853e                	mv	a0,a5
    80003352:	60e2                	ld	ra,24(sp)
    80003354:	6442                	ld	s0,16(sp)
    80003356:	6105                	addi	sp,sp,32
    80003358:	8082                	ret

000000008000335a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000335a:	1141                	addi	sp,sp,-16
    8000335c:	e406                	sd	ra,8(sp)
    8000335e:	e022                	sd	s0,0(sp)
    80003360:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003362:	fffff097          	auipc	ra,0xfffff
    80003366:	a7a080e7          	jalr	-1414(ra) # 80001ddc <myproc>
}
    8000336a:	5908                	lw	a0,48(a0)
    8000336c:	60a2                	ld	ra,8(sp)
    8000336e:	6402                	ld	s0,0(sp)
    80003370:	0141                	addi	sp,sp,16
    80003372:	8082                	ret

0000000080003374 <sys_fork>:

uint64
sys_fork(void)
{
    80003374:	1141                	addi	sp,sp,-16
    80003376:	e406                	sd	ra,8(sp)
    80003378:	e022                	sd	s0,0(sp)
    8000337a:	0800                	addi	s0,sp,16
  return fork();
    8000337c:	fffff097          	auipc	ra,0xfffff
    80003380:	f18080e7          	jalr	-232(ra) # 80002294 <fork>
}
    80003384:	60a2                	ld	ra,8(sp)
    80003386:	6402                	ld	s0,0(sp)
    80003388:	0141                	addi	sp,sp,16
    8000338a:	8082                	ret

000000008000338c <sys_wait>:

uint64
sys_wait(void)
{
    8000338c:	1101                	addi	sp,sp,-32
    8000338e:	ec06                	sd	ra,24(sp)
    80003390:	e822                	sd	s0,16(sp)
    80003392:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003394:	fe840593          	addi	a1,s0,-24
    80003398:	4501                	li	a0,0
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	ece080e7          	jalr	-306(ra) # 80003268 <argaddr>
    800033a2:	87aa                	mv	a5,a0
    return -1;
    800033a4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033a6:	0007c863          	bltz	a5,800033b6 <sys_wait+0x2a>
  return wait(p);
    800033aa:	fe843503          	ld	a0,-24(s0)
    800033ae:	fffff097          	auipc	ra,0xfffff
    800033b2:	370080e7          	jalr	880(ra) # 8000271e <wait>
}
    800033b6:	60e2                	ld	ra,24(sp)
    800033b8:	6442                	ld	s0,16(sp)
    800033ba:	6105                	addi	sp,sp,32
    800033bc:	8082                	ret

00000000800033be <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033be:	7179                	addi	sp,sp,-48
    800033c0:	f406                	sd	ra,40(sp)
    800033c2:	f022                	sd	s0,32(sp)
    800033c4:	ec26                	sd	s1,24(sp)
    800033c6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800033c8:	fdc40593          	addi	a1,s0,-36
    800033cc:	4501                	li	a0,0
    800033ce:	00000097          	auipc	ra,0x0
    800033d2:	e78080e7          	jalr	-392(ra) # 80003246 <argint>
    800033d6:	87aa                	mv	a5,a0
    return -1;
    800033d8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800033da:	0207c063          	bltz	a5,800033fa <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800033de:	fffff097          	auipc	ra,0xfffff
    800033e2:	9fe080e7          	jalr	-1538(ra) # 80001ddc <myproc>
    800033e6:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800033e8:	fdc42503          	lw	a0,-36(s0)
    800033ec:	fffff097          	auipc	ra,0xfffff
    800033f0:	e34080e7          	jalr	-460(ra) # 80002220 <growproc>
    800033f4:	00054863          	bltz	a0,80003404 <sys_sbrk+0x46>
    return -1;
  return addr;
    800033f8:	8526                	mv	a0,s1
}
    800033fa:	70a2                	ld	ra,40(sp)
    800033fc:	7402                	ld	s0,32(sp)
    800033fe:	64e2                	ld	s1,24(sp)
    80003400:	6145                	addi	sp,sp,48
    80003402:	8082                	ret
    return -1;
    80003404:	557d                	li	a0,-1
    80003406:	bfd5                	j	800033fa <sys_sbrk+0x3c>

0000000080003408 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003408:	7139                	addi	sp,sp,-64
    8000340a:	fc06                	sd	ra,56(sp)
    8000340c:	f822                	sd	s0,48(sp)
    8000340e:	f426                	sd	s1,40(sp)
    80003410:	f04a                	sd	s2,32(sp)
    80003412:	ec4e                	sd	s3,24(sp)
    80003414:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003416:	fcc40593          	addi	a1,s0,-52
    8000341a:	4501                	li	a0,0
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	e2a080e7          	jalr	-470(ra) # 80003246 <argint>
    return -1;
    80003424:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003426:	06054563          	bltz	a0,80003490 <sys_sleep+0x88>
  acquire(&tickslock);
    8000342a:	00014517          	auipc	a0,0x14
    8000342e:	64e50513          	addi	a0,a0,1614 # 80017a78 <tickslock>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	7b2080e7          	jalr	1970(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000343a:	00006917          	auipc	s2,0x6
    8000343e:	bf692903          	lw	s2,-1034(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003442:	fcc42783          	lw	a5,-52(s0)
    80003446:	cf85                	beqz	a5,8000347e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003448:	00014997          	auipc	s3,0x14
    8000344c:	63098993          	addi	s3,s3,1584 # 80017a78 <tickslock>
    80003450:	00006497          	auipc	s1,0x6
    80003454:	be048493          	addi	s1,s1,-1056 # 80009030 <ticks>
    if(myproc()->killed){
    80003458:	fffff097          	auipc	ra,0xfffff
    8000345c:	984080e7          	jalr	-1660(ra) # 80001ddc <myproc>
    80003460:	551c                	lw	a5,40(a0)
    80003462:	ef9d                	bnez	a5,800034a0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003464:	85ce                	mv	a1,s3
    80003466:	8526                	mv	a0,s1
    80003468:	fffff097          	auipc	ra,0xfffff
    8000346c:	236080e7          	jalr	566(ra) # 8000269e <sleep>
  while(ticks - ticks0 < n){
    80003470:	409c                	lw	a5,0(s1)
    80003472:	412787bb          	subw	a5,a5,s2
    80003476:	fcc42703          	lw	a4,-52(s0)
    8000347a:	fce7efe3          	bltu	a5,a4,80003458 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000347e:	00014517          	auipc	a0,0x14
    80003482:	5fa50513          	addi	a0,a0,1530 # 80017a78 <tickslock>
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	824080e7          	jalr	-2012(ra) # 80000caa <release>
  return 0;
    8000348e:	4781                	li	a5,0
}
    80003490:	853e                	mv	a0,a5
    80003492:	70e2                	ld	ra,56(sp)
    80003494:	7442                	ld	s0,48(sp)
    80003496:	74a2                	ld	s1,40(sp)
    80003498:	7902                	ld	s2,32(sp)
    8000349a:	69e2                	ld	s3,24(sp)
    8000349c:	6121                	addi	sp,sp,64
    8000349e:	8082                	ret
      release(&tickslock);
    800034a0:	00014517          	auipc	a0,0x14
    800034a4:	5d850513          	addi	a0,a0,1496 # 80017a78 <tickslock>
    800034a8:	ffffe097          	auipc	ra,0xffffe
    800034ac:	802080e7          	jalr	-2046(ra) # 80000caa <release>
      return -1;
    800034b0:	57fd                	li	a5,-1
    800034b2:	bff9                	j	80003490 <sys_sleep+0x88>

00000000800034b4 <sys_kill>:

uint64
sys_kill(void)
{
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800034bc:	fec40593          	addi	a1,s0,-20
    800034c0:	4501                	li	a0,0
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	d84080e7          	jalr	-636(ra) # 80003246 <argint>
    800034ca:	87aa                	mv	a5,a0
    return -1;
    800034cc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800034ce:	0007c863          	bltz	a5,800034de <sys_kill+0x2a>
  return kill(pid);
    800034d2:	fec42503          	lw	a0,-20(s0)
    800034d6:	fffff097          	auipc	ra,0xfffff
    800034da:	5da080e7          	jalr	1498(ra) # 80002ab0 <kill>
}
    800034de:	60e2                	ld	ra,24(sp)
    800034e0:	6442                	ld	s0,16(sp)
    800034e2:	6105                	addi	sp,sp,32
    800034e4:	8082                	ret

00000000800034e6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034e6:	1101                	addi	sp,sp,-32
    800034e8:	ec06                	sd	ra,24(sp)
    800034ea:	e822                	sd	s0,16(sp)
    800034ec:	e426                	sd	s1,8(sp)
    800034ee:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034f0:	00014517          	auipc	a0,0x14
    800034f4:	58850513          	addi	a0,a0,1416 # 80017a78 <tickslock>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	6ec080e7          	jalr	1772(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003500:	00006497          	auipc	s1,0x6
    80003504:	b304a483          	lw	s1,-1232(s1) # 80009030 <ticks>
  release(&tickslock);
    80003508:	00014517          	auipc	a0,0x14
    8000350c:	57050513          	addi	a0,a0,1392 # 80017a78 <tickslock>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	79a080e7          	jalr	1946(ra) # 80000caa <release>
  return xticks;
}
    80003518:	02049513          	slli	a0,s1,0x20
    8000351c:	9101                	srli	a0,a0,0x20
    8000351e:	60e2                	ld	ra,24(sp)
    80003520:	6442                	ld	s0,16(sp)
    80003522:	64a2                	ld	s1,8(sp)
    80003524:	6105                	addi	sp,sp,32
    80003526:	8082                	ret

0000000080003528 <sys_get_cpu>:

uint64
sys_get_cpu(void){
    80003528:	1141                	addi	sp,sp,-16
    8000352a:	e406                	sd	ra,8(sp)
    8000352c:	e022                	sd	s0,0(sp)
    8000352e:	0800                	addi	s0,sp,16
  return get_cpu();
    80003530:	fffff097          	auipc	ra,0xfffff
    80003534:	7d2080e7          	jalr	2002(ra) # 80002d02 <get_cpu>
}
    80003538:	60a2                	ld	ra,8(sp)
    8000353a:	6402                	ld	s0,0(sp)
    8000353c:	0141                	addi	sp,sp,16
    8000353e:	8082                	ret

0000000080003540 <sys_set_cpu>:

uint64
sys_set_cpu(void){
    80003540:	1101                	addi	sp,sp,-32
    80003542:	ec06                	sd	ra,24(sp)
    80003544:	e822                	sd	s0,16(sp)
    80003546:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80003548:	fec40593          	addi	a1,s0,-20
    8000354c:	4501                	li	a0,0
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	cf8080e7          	jalr	-776(ra) # 80003246 <argint>
    80003556:	87aa                	mv	a5,a0
    return -1;
    80003558:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    8000355a:	0007c863          	bltz	a5,8000356a <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    8000355e:	fec42503          	lw	a0,-20(s0)
    80003562:	fffff097          	auipc	ra,0xfffff
    80003566:	762080e7          	jalr	1890(ra) # 80002cc4 <set_cpu>
}
    8000356a:	60e2                	ld	ra,24(sp)
    8000356c:	6442                	ld	s0,16(sp)
    8000356e:	6105                	addi	sp,sp,32
    80003570:	8082                	ret

0000000080003572 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    8000357a:	fec40593          	addi	a1,s0,-20
    8000357e:	4501                	li	a0,0
    80003580:	00000097          	auipc	ra,0x0
    80003584:	cc6080e7          	jalr	-826(ra) # 80003246 <argint>
    80003588:	87aa                	mv	a5,a0
    return -1;
    8000358a:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    8000358c:	0007c863          	bltz	a5,8000359c <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_num);
    80003590:	fec42503          	lw	a0,-20(s0)
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	79e080e7          	jalr	1950(ra) # 80002d32 <cpu_process_count>
}
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret

00000000800035a4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035a4:	7179                	addi	sp,sp,-48
    800035a6:	f406                	sd	ra,40(sp)
    800035a8:	f022                	sd	s0,32(sp)
    800035aa:	ec26                	sd	s1,24(sp)
    800035ac:	e84a                	sd	s2,16(sp)
    800035ae:	e44e                	sd	s3,8(sp)
    800035b0:	e052                	sd	s4,0(sp)
    800035b2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035b4:	00005597          	auipc	a1,0x5
    800035b8:	ff458593          	addi	a1,a1,-12 # 800085a8 <syscalls+0xc8>
    800035bc:	00014517          	auipc	a0,0x14
    800035c0:	4d450513          	addi	a0,a0,1236 # 80017a90 <bcache>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	590080e7          	jalr	1424(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035cc:	0001c797          	auipc	a5,0x1c
    800035d0:	4c478793          	addi	a5,a5,1220 # 8001fa90 <bcache+0x8000>
    800035d4:	0001c717          	auipc	a4,0x1c
    800035d8:	72470713          	addi	a4,a4,1828 # 8001fcf8 <bcache+0x8268>
    800035dc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035e0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035e4:	00014497          	auipc	s1,0x14
    800035e8:	4c448493          	addi	s1,s1,1220 # 80017aa8 <bcache+0x18>
    b->next = bcache.head.next;
    800035ec:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035ee:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035f0:	00005a17          	auipc	s4,0x5
    800035f4:	fc0a0a13          	addi	s4,s4,-64 # 800085b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035f8:	2b893783          	ld	a5,696(s2)
    800035fc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035fe:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003602:	85d2                	mv	a1,s4
    80003604:	01048513          	addi	a0,s1,16
    80003608:	00001097          	auipc	ra,0x1
    8000360c:	4bc080e7          	jalr	1212(ra) # 80004ac4 <initsleeplock>
    bcache.head.next->prev = b;
    80003610:	2b893783          	ld	a5,696(s2)
    80003614:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003616:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000361a:	45848493          	addi	s1,s1,1112
    8000361e:	fd349de3          	bne	s1,s3,800035f8 <binit+0x54>
  }
}
    80003622:	70a2                	ld	ra,40(sp)
    80003624:	7402                	ld	s0,32(sp)
    80003626:	64e2                	ld	s1,24(sp)
    80003628:	6942                	ld	s2,16(sp)
    8000362a:	69a2                	ld	s3,8(sp)
    8000362c:	6a02                	ld	s4,0(sp)
    8000362e:	6145                	addi	sp,sp,48
    80003630:	8082                	ret

0000000080003632 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003632:	7179                	addi	sp,sp,-48
    80003634:	f406                	sd	ra,40(sp)
    80003636:	f022                	sd	s0,32(sp)
    80003638:	ec26                	sd	s1,24(sp)
    8000363a:	e84a                	sd	s2,16(sp)
    8000363c:	e44e                	sd	s3,8(sp)
    8000363e:	1800                	addi	s0,sp,48
    80003640:	89aa                	mv	s3,a0
    80003642:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003644:	00014517          	auipc	a0,0x14
    80003648:	44c50513          	addi	a0,a0,1100 # 80017a90 <bcache>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	598080e7          	jalr	1432(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003654:	0001c497          	auipc	s1,0x1c
    80003658:	6f44b483          	ld	s1,1780(s1) # 8001fd48 <bcache+0x82b8>
    8000365c:	0001c797          	auipc	a5,0x1c
    80003660:	69c78793          	addi	a5,a5,1692 # 8001fcf8 <bcache+0x8268>
    80003664:	02f48f63          	beq	s1,a5,800036a2 <bread+0x70>
    80003668:	873e                	mv	a4,a5
    8000366a:	a021                	j	80003672 <bread+0x40>
    8000366c:	68a4                	ld	s1,80(s1)
    8000366e:	02e48a63          	beq	s1,a4,800036a2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003672:	449c                	lw	a5,8(s1)
    80003674:	ff379ce3          	bne	a5,s3,8000366c <bread+0x3a>
    80003678:	44dc                	lw	a5,12(s1)
    8000367a:	ff2799e3          	bne	a5,s2,8000366c <bread+0x3a>
      b->refcnt++;
    8000367e:	40bc                	lw	a5,64(s1)
    80003680:	2785                	addiw	a5,a5,1
    80003682:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003684:	00014517          	auipc	a0,0x14
    80003688:	40c50513          	addi	a0,a0,1036 # 80017a90 <bcache>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	61e080e7          	jalr	1566(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    80003694:	01048513          	addi	a0,s1,16
    80003698:	00001097          	auipc	ra,0x1
    8000369c:	466080e7          	jalr	1126(ra) # 80004afe <acquiresleep>
      return b;
    800036a0:	a8b9                	j	800036fe <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036a2:	0001c497          	auipc	s1,0x1c
    800036a6:	69e4b483          	ld	s1,1694(s1) # 8001fd40 <bcache+0x82b0>
    800036aa:	0001c797          	auipc	a5,0x1c
    800036ae:	64e78793          	addi	a5,a5,1614 # 8001fcf8 <bcache+0x8268>
    800036b2:	00f48863          	beq	s1,a5,800036c2 <bread+0x90>
    800036b6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036b8:	40bc                	lw	a5,64(s1)
    800036ba:	cf81                	beqz	a5,800036d2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036bc:	64a4                	ld	s1,72(s1)
    800036be:	fee49de3          	bne	s1,a4,800036b8 <bread+0x86>
  panic("bget: no buffers");
    800036c2:	00005517          	auipc	a0,0x5
    800036c6:	ef650513          	addi	a0,a0,-266 # 800085b8 <syscalls+0xd8>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	e74080e7          	jalr	-396(ra) # 8000053e <panic>
      b->dev = dev;
    800036d2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036d6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036da:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036de:	4785                	li	a5,1
    800036e0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036e2:	00014517          	auipc	a0,0x14
    800036e6:	3ae50513          	addi	a0,a0,942 # 80017a90 <bcache>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	5c0080e7          	jalr	1472(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    800036f2:	01048513          	addi	a0,s1,16
    800036f6:	00001097          	auipc	ra,0x1
    800036fa:	408080e7          	jalr	1032(ra) # 80004afe <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036fe:	409c                	lw	a5,0(s1)
    80003700:	cb89                	beqz	a5,80003712 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003702:	8526                	mv	a0,s1
    80003704:	70a2                	ld	ra,40(sp)
    80003706:	7402                	ld	s0,32(sp)
    80003708:	64e2                	ld	s1,24(sp)
    8000370a:	6942                	ld	s2,16(sp)
    8000370c:	69a2                	ld	s3,8(sp)
    8000370e:	6145                	addi	sp,sp,48
    80003710:	8082                	ret
    virtio_disk_rw(b, 0);
    80003712:	4581                	li	a1,0
    80003714:	8526                	mv	a0,s1
    80003716:	00003097          	auipc	ra,0x3
    8000371a:	f10080e7          	jalr	-240(ra) # 80006626 <virtio_disk_rw>
    b->valid = 1;
    8000371e:	4785                	li	a5,1
    80003720:	c09c                	sw	a5,0(s1)
  return b;
    80003722:	b7c5                	j	80003702 <bread+0xd0>

0000000080003724 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003724:	1101                	addi	sp,sp,-32
    80003726:	ec06                	sd	ra,24(sp)
    80003728:	e822                	sd	s0,16(sp)
    8000372a:	e426                	sd	s1,8(sp)
    8000372c:	1000                	addi	s0,sp,32
    8000372e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003730:	0541                	addi	a0,a0,16
    80003732:	00001097          	auipc	ra,0x1
    80003736:	466080e7          	jalr	1126(ra) # 80004b98 <holdingsleep>
    8000373a:	cd01                	beqz	a0,80003752 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000373c:	4585                	li	a1,1
    8000373e:	8526                	mv	a0,s1
    80003740:	00003097          	auipc	ra,0x3
    80003744:	ee6080e7          	jalr	-282(ra) # 80006626 <virtio_disk_rw>
}
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	64a2                	ld	s1,8(sp)
    8000374e:	6105                	addi	sp,sp,32
    80003750:	8082                	ret
    panic("bwrite");
    80003752:	00005517          	auipc	a0,0x5
    80003756:	e7e50513          	addi	a0,a0,-386 # 800085d0 <syscalls+0xf0>
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	de4080e7          	jalr	-540(ra) # 8000053e <panic>

0000000080003762 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003762:	1101                	addi	sp,sp,-32
    80003764:	ec06                	sd	ra,24(sp)
    80003766:	e822                	sd	s0,16(sp)
    80003768:	e426                	sd	s1,8(sp)
    8000376a:	e04a                	sd	s2,0(sp)
    8000376c:	1000                	addi	s0,sp,32
    8000376e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003770:	01050913          	addi	s2,a0,16
    80003774:	854a                	mv	a0,s2
    80003776:	00001097          	auipc	ra,0x1
    8000377a:	422080e7          	jalr	1058(ra) # 80004b98 <holdingsleep>
    8000377e:	c92d                	beqz	a0,800037f0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003780:	854a                	mv	a0,s2
    80003782:	00001097          	auipc	ra,0x1
    80003786:	3d2080e7          	jalr	978(ra) # 80004b54 <releasesleep>

  acquire(&bcache.lock);
    8000378a:	00014517          	auipc	a0,0x14
    8000378e:	30650513          	addi	a0,a0,774 # 80017a90 <bcache>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	452080e7          	jalr	1106(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000379a:	40bc                	lw	a5,64(s1)
    8000379c:	37fd                	addiw	a5,a5,-1
    8000379e:	0007871b          	sext.w	a4,a5
    800037a2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037a4:	eb05                	bnez	a4,800037d4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037a6:	68bc                	ld	a5,80(s1)
    800037a8:	64b8                	ld	a4,72(s1)
    800037aa:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037ac:	64bc                	ld	a5,72(s1)
    800037ae:	68b8                	ld	a4,80(s1)
    800037b0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037b2:	0001c797          	auipc	a5,0x1c
    800037b6:	2de78793          	addi	a5,a5,734 # 8001fa90 <bcache+0x8000>
    800037ba:	2b87b703          	ld	a4,696(a5)
    800037be:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037c0:	0001c717          	auipc	a4,0x1c
    800037c4:	53870713          	addi	a4,a4,1336 # 8001fcf8 <bcache+0x8268>
    800037c8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037ca:	2b87b703          	ld	a4,696(a5)
    800037ce:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037d0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037d4:	00014517          	auipc	a0,0x14
    800037d8:	2bc50513          	addi	a0,a0,700 # 80017a90 <bcache>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	4ce080e7          	jalr	1230(ra) # 80000caa <release>
}
    800037e4:	60e2                	ld	ra,24(sp)
    800037e6:	6442                	ld	s0,16(sp)
    800037e8:	64a2                	ld	s1,8(sp)
    800037ea:	6902                	ld	s2,0(sp)
    800037ec:	6105                	addi	sp,sp,32
    800037ee:	8082                	ret
    panic("brelse");
    800037f0:	00005517          	auipc	a0,0x5
    800037f4:	de850513          	addi	a0,a0,-536 # 800085d8 <syscalls+0xf8>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	d46080e7          	jalr	-698(ra) # 8000053e <panic>

0000000080003800 <bpin>:

void
bpin(struct buf *b) {
    80003800:	1101                	addi	sp,sp,-32
    80003802:	ec06                	sd	ra,24(sp)
    80003804:	e822                	sd	s0,16(sp)
    80003806:	e426                	sd	s1,8(sp)
    80003808:	1000                	addi	s0,sp,32
    8000380a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000380c:	00014517          	auipc	a0,0x14
    80003810:	28450513          	addi	a0,a0,644 # 80017a90 <bcache>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	3d0080e7          	jalr	976(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000381c:	40bc                	lw	a5,64(s1)
    8000381e:	2785                	addiw	a5,a5,1
    80003820:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003822:	00014517          	auipc	a0,0x14
    80003826:	26e50513          	addi	a0,a0,622 # 80017a90 <bcache>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	480080e7          	jalr	1152(ra) # 80000caa <release>
}
    80003832:	60e2                	ld	ra,24(sp)
    80003834:	6442                	ld	s0,16(sp)
    80003836:	64a2                	ld	s1,8(sp)
    80003838:	6105                	addi	sp,sp,32
    8000383a:	8082                	ret

000000008000383c <bunpin>:

void
bunpin(struct buf *b) {
    8000383c:	1101                	addi	sp,sp,-32
    8000383e:	ec06                	sd	ra,24(sp)
    80003840:	e822                	sd	s0,16(sp)
    80003842:	e426                	sd	s1,8(sp)
    80003844:	1000                	addi	s0,sp,32
    80003846:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003848:	00014517          	auipc	a0,0x14
    8000384c:	24850513          	addi	a0,a0,584 # 80017a90 <bcache>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	394080e7          	jalr	916(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003858:	40bc                	lw	a5,64(s1)
    8000385a:	37fd                	addiw	a5,a5,-1
    8000385c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000385e:	00014517          	auipc	a0,0x14
    80003862:	23250513          	addi	a0,a0,562 # 80017a90 <bcache>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	444080e7          	jalr	1092(ra) # 80000caa <release>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6105                	addi	sp,sp,32
    80003876:	8082                	ret

0000000080003878 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003878:	1101                	addi	sp,sp,-32
    8000387a:	ec06                	sd	ra,24(sp)
    8000387c:	e822                	sd	s0,16(sp)
    8000387e:	e426                	sd	s1,8(sp)
    80003880:	e04a                	sd	s2,0(sp)
    80003882:	1000                	addi	s0,sp,32
    80003884:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003886:	00d5d59b          	srliw	a1,a1,0xd
    8000388a:	0001d797          	auipc	a5,0x1d
    8000388e:	8e27a783          	lw	a5,-1822(a5) # 8002016c <sb+0x1c>
    80003892:	9dbd                	addw	a1,a1,a5
    80003894:	00000097          	auipc	ra,0x0
    80003898:	d9e080e7          	jalr	-610(ra) # 80003632 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000389c:	0074f713          	andi	a4,s1,7
    800038a0:	4785                	li	a5,1
    800038a2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038a6:	14ce                	slli	s1,s1,0x33
    800038a8:	90d9                	srli	s1,s1,0x36
    800038aa:	00950733          	add	a4,a0,s1
    800038ae:	05874703          	lbu	a4,88(a4)
    800038b2:	00e7f6b3          	and	a3,a5,a4
    800038b6:	c69d                	beqz	a3,800038e4 <bfree+0x6c>
    800038b8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038ba:	94aa                	add	s1,s1,a0
    800038bc:	fff7c793          	not	a5,a5
    800038c0:	8ff9                	and	a5,a5,a4
    800038c2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	118080e7          	jalr	280(ra) # 800049de <log_write>
  brelse(bp);
    800038ce:	854a                	mv	a0,s2
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	e92080e7          	jalr	-366(ra) # 80003762 <brelse>
}
    800038d8:	60e2                	ld	ra,24(sp)
    800038da:	6442                	ld	s0,16(sp)
    800038dc:	64a2                	ld	s1,8(sp)
    800038de:	6902                	ld	s2,0(sp)
    800038e0:	6105                	addi	sp,sp,32
    800038e2:	8082                	ret
    panic("freeing free block");
    800038e4:	00005517          	auipc	a0,0x5
    800038e8:	cfc50513          	addi	a0,a0,-772 # 800085e0 <syscalls+0x100>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	c52080e7          	jalr	-942(ra) # 8000053e <panic>

00000000800038f4 <balloc>:
{
    800038f4:	711d                	addi	sp,sp,-96
    800038f6:	ec86                	sd	ra,88(sp)
    800038f8:	e8a2                	sd	s0,80(sp)
    800038fa:	e4a6                	sd	s1,72(sp)
    800038fc:	e0ca                	sd	s2,64(sp)
    800038fe:	fc4e                	sd	s3,56(sp)
    80003900:	f852                	sd	s4,48(sp)
    80003902:	f456                	sd	s5,40(sp)
    80003904:	f05a                	sd	s6,32(sp)
    80003906:	ec5e                	sd	s7,24(sp)
    80003908:	e862                	sd	s8,16(sp)
    8000390a:	e466                	sd	s9,8(sp)
    8000390c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000390e:	0001d797          	auipc	a5,0x1d
    80003912:	8467a783          	lw	a5,-1978(a5) # 80020154 <sb+0x4>
    80003916:	cbd1                	beqz	a5,800039aa <balloc+0xb6>
    80003918:	8baa                	mv	s7,a0
    8000391a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000391c:	0001db17          	auipc	s6,0x1d
    80003920:	834b0b13          	addi	s6,s6,-1996 # 80020150 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003924:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003926:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003928:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000392a:	6c89                	lui	s9,0x2
    8000392c:	a831                	j	80003948 <balloc+0x54>
    brelse(bp);
    8000392e:	854a                	mv	a0,s2
    80003930:	00000097          	auipc	ra,0x0
    80003934:	e32080e7          	jalr	-462(ra) # 80003762 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003938:	015c87bb          	addw	a5,s9,s5
    8000393c:	00078a9b          	sext.w	s5,a5
    80003940:	004b2703          	lw	a4,4(s6)
    80003944:	06eaf363          	bgeu	s5,a4,800039aa <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003948:	41fad79b          	sraiw	a5,s5,0x1f
    8000394c:	0137d79b          	srliw	a5,a5,0x13
    80003950:	015787bb          	addw	a5,a5,s5
    80003954:	40d7d79b          	sraiw	a5,a5,0xd
    80003958:	01cb2583          	lw	a1,28(s6)
    8000395c:	9dbd                	addw	a1,a1,a5
    8000395e:	855e                	mv	a0,s7
    80003960:	00000097          	auipc	ra,0x0
    80003964:	cd2080e7          	jalr	-814(ra) # 80003632 <bread>
    80003968:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000396a:	004b2503          	lw	a0,4(s6)
    8000396e:	000a849b          	sext.w	s1,s5
    80003972:	8662                	mv	a2,s8
    80003974:	faa4fde3          	bgeu	s1,a0,8000392e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003978:	41f6579b          	sraiw	a5,a2,0x1f
    8000397c:	01d7d69b          	srliw	a3,a5,0x1d
    80003980:	00c6873b          	addw	a4,a3,a2
    80003984:	00777793          	andi	a5,a4,7
    80003988:	9f95                	subw	a5,a5,a3
    8000398a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000398e:	4037571b          	sraiw	a4,a4,0x3
    80003992:	00e906b3          	add	a3,s2,a4
    80003996:	0586c683          	lbu	a3,88(a3)
    8000399a:	00d7f5b3          	and	a1,a5,a3
    8000399e:	cd91                	beqz	a1,800039ba <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039a0:	2605                	addiw	a2,a2,1
    800039a2:	2485                	addiw	s1,s1,1
    800039a4:	fd4618e3          	bne	a2,s4,80003974 <balloc+0x80>
    800039a8:	b759                	j	8000392e <balloc+0x3a>
  panic("balloc: out of blocks");
    800039aa:	00005517          	auipc	a0,0x5
    800039ae:	c4e50513          	addi	a0,a0,-946 # 800085f8 <syscalls+0x118>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	b8c080e7          	jalr	-1140(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039ba:	974a                	add	a4,a4,s2
    800039bc:	8fd5                	or	a5,a5,a3
    800039be:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039c2:	854a                	mv	a0,s2
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	01a080e7          	jalr	26(ra) # 800049de <log_write>
        brelse(bp);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	d94080e7          	jalr	-620(ra) # 80003762 <brelse>
  bp = bread(dev, bno);
    800039d6:	85a6                	mv	a1,s1
    800039d8:	855e                	mv	a0,s7
    800039da:	00000097          	auipc	ra,0x0
    800039de:	c58080e7          	jalr	-936(ra) # 80003632 <bread>
    800039e2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039e4:	40000613          	li	a2,1024
    800039e8:	4581                	li	a1,0
    800039ea:	05850513          	addi	a0,a0,88
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	316080e7          	jalr	790(ra) # 80000d04 <memset>
  log_write(bp);
    800039f6:	854a                	mv	a0,s2
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	fe6080e7          	jalr	-26(ra) # 800049de <log_write>
  brelse(bp);
    80003a00:	854a                	mv	a0,s2
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	d60080e7          	jalr	-672(ra) # 80003762 <brelse>
}
    80003a0a:	8526                	mv	a0,s1
    80003a0c:	60e6                	ld	ra,88(sp)
    80003a0e:	6446                	ld	s0,80(sp)
    80003a10:	64a6                	ld	s1,72(sp)
    80003a12:	6906                	ld	s2,64(sp)
    80003a14:	79e2                	ld	s3,56(sp)
    80003a16:	7a42                	ld	s4,48(sp)
    80003a18:	7aa2                	ld	s5,40(sp)
    80003a1a:	7b02                	ld	s6,32(sp)
    80003a1c:	6be2                	ld	s7,24(sp)
    80003a1e:	6c42                	ld	s8,16(sp)
    80003a20:	6ca2                	ld	s9,8(sp)
    80003a22:	6125                	addi	sp,sp,96
    80003a24:	8082                	ret

0000000080003a26 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a26:	7179                	addi	sp,sp,-48
    80003a28:	f406                	sd	ra,40(sp)
    80003a2a:	f022                	sd	s0,32(sp)
    80003a2c:	ec26                	sd	s1,24(sp)
    80003a2e:	e84a                	sd	s2,16(sp)
    80003a30:	e44e                	sd	s3,8(sp)
    80003a32:	e052                	sd	s4,0(sp)
    80003a34:	1800                	addi	s0,sp,48
    80003a36:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a38:	47ad                	li	a5,11
    80003a3a:	04b7fe63          	bgeu	a5,a1,80003a96 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a3e:	ff45849b          	addiw	s1,a1,-12
    80003a42:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a46:	0ff00793          	li	a5,255
    80003a4a:	0ae7e363          	bltu	a5,a4,80003af0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a4e:	08052583          	lw	a1,128(a0)
    80003a52:	c5ad                	beqz	a1,80003abc <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a54:	00092503          	lw	a0,0(s2)
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	bda080e7          	jalr	-1062(ra) # 80003632 <bread>
    80003a60:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a62:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a66:	02049593          	slli	a1,s1,0x20
    80003a6a:	9181                	srli	a1,a1,0x20
    80003a6c:	058a                	slli	a1,a1,0x2
    80003a6e:	00b784b3          	add	s1,a5,a1
    80003a72:	0004a983          	lw	s3,0(s1)
    80003a76:	04098d63          	beqz	s3,80003ad0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a7a:	8552                	mv	a0,s4
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	ce6080e7          	jalr	-794(ra) # 80003762 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a84:	854e                	mv	a0,s3
    80003a86:	70a2                	ld	ra,40(sp)
    80003a88:	7402                	ld	s0,32(sp)
    80003a8a:	64e2                	ld	s1,24(sp)
    80003a8c:	6942                	ld	s2,16(sp)
    80003a8e:	69a2                	ld	s3,8(sp)
    80003a90:	6a02                	ld	s4,0(sp)
    80003a92:	6145                	addi	sp,sp,48
    80003a94:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a96:	02059493          	slli	s1,a1,0x20
    80003a9a:	9081                	srli	s1,s1,0x20
    80003a9c:	048a                	slli	s1,s1,0x2
    80003a9e:	94aa                	add	s1,s1,a0
    80003aa0:	0504a983          	lw	s3,80(s1)
    80003aa4:	fe0990e3          	bnez	s3,80003a84 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003aa8:	4108                	lw	a0,0(a0)
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	e4a080e7          	jalr	-438(ra) # 800038f4 <balloc>
    80003ab2:	0005099b          	sext.w	s3,a0
    80003ab6:	0534a823          	sw	s3,80(s1)
    80003aba:	b7e9                	j	80003a84 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003abc:	4108                	lw	a0,0(a0)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	e36080e7          	jalr	-458(ra) # 800038f4 <balloc>
    80003ac6:	0005059b          	sext.w	a1,a0
    80003aca:	08b92023          	sw	a1,128(s2)
    80003ace:	b759                	j	80003a54 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ad0:	00092503          	lw	a0,0(s2)
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	e20080e7          	jalr	-480(ra) # 800038f4 <balloc>
    80003adc:	0005099b          	sext.w	s3,a0
    80003ae0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003ae4:	8552                	mv	a0,s4
    80003ae6:	00001097          	auipc	ra,0x1
    80003aea:	ef8080e7          	jalr	-264(ra) # 800049de <log_write>
    80003aee:	b771                	j	80003a7a <bmap+0x54>
  panic("bmap: out of range");
    80003af0:	00005517          	auipc	a0,0x5
    80003af4:	b2050513          	addi	a0,a0,-1248 # 80008610 <syscalls+0x130>
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	a46080e7          	jalr	-1466(ra) # 8000053e <panic>

0000000080003b00 <iget>:
{
    80003b00:	7179                	addi	sp,sp,-48
    80003b02:	f406                	sd	ra,40(sp)
    80003b04:	f022                	sd	s0,32(sp)
    80003b06:	ec26                	sd	s1,24(sp)
    80003b08:	e84a                	sd	s2,16(sp)
    80003b0a:	e44e                	sd	s3,8(sp)
    80003b0c:	e052                	sd	s4,0(sp)
    80003b0e:	1800                	addi	s0,sp,48
    80003b10:	89aa                	mv	s3,a0
    80003b12:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b14:	0001c517          	auipc	a0,0x1c
    80003b18:	65c50513          	addi	a0,a0,1628 # 80020170 <itable>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	0c8080e7          	jalr	200(ra) # 80000be4 <acquire>
  empty = 0;
    80003b24:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b26:	0001c497          	auipc	s1,0x1c
    80003b2a:	66248493          	addi	s1,s1,1634 # 80020188 <itable+0x18>
    80003b2e:	0001e697          	auipc	a3,0x1e
    80003b32:	0ea68693          	addi	a3,a3,234 # 80021c18 <log>
    80003b36:	a039                	j	80003b44 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b38:	02090b63          	beqz	s2,80003b6e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b3c:	08848493          	addi	s1,s1,136
    80003b40:	02d48a63          	beq	s1,a3,80003b74 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b44:	449c                	lw	a5,8(s1)
    80003b46:	fef059e3          	blez	a5,80003b38 <iget+0x38>
    80003b4a:	4098                	lw	a4,0(s1)
    80003b4c:	ff3716e3          	bne	a4,s3,80003b38 <iget+0x38>
    80003b50:	40d8                	lw	a4,4(s1)
    80003b52:	ff4713e3          	bne	a4,s4,80003b38 <iget+0x38>
      ip->ref++;
    80003b56:	2785                	addiw	a5,a5,1
    80003b58:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b5a:	0001c517          	auipc	a0,0x1c
    80003b5e:	61650513          	addi	a0,a0,1558 # 80020170 <itable>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	148080e7          	jalr	328(ra) # 80000caa <release>
      return ip;
    80003b6a:	8926                	mv	s2,s1
    80003b6c:	a03d                	j	80003b9a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b6e:	f7f9                	bnez	a5,80003b3c <iget+0x3c>
    80003b70:	8926                	mv	s2,s1
    80003b72:	b7e9                	j	80003b3c <iget+0x3c>
  if(empty == 0)
    80003b74:	02090c63          	beqz	s2,80003bac <iget+0xac>
  ip->dev = dev;
    80003b78:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b7c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b80:	4785                	li	a5,1
    80003b82:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b86:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b8a:	0001c517          	auipc	a0,0x1c
    80003b8e:	5e650513          	addi	a0,a0,1510 # 80020170 <itable>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	118080e7          	jalr	280(ra) # 80000caa <release>
}
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	70a2                	ld	ra,40(sp)
    80003b9e:	7402                	ld	s0,32(sp)
    80003ba0:	64e2                	ld	s1,24(sp)
    80003ba2:	6942                	ld	s2,16(sp)
    80003ba4:	69a2                	ld	s3,8(sp)
    80003ba6:	6a02                	ld	s4,0(sp)
    80003ba8:	6145                	addi	sp,sp,48
    80003baa:	8082                	ret
    panic("iget: no inodes");
    80003bac:	00005517          	auipc	a0,0x5
    80003bb0:	a7c50513          	addi	a0,a0,-1412 # 80008628 <syscalls+0x148>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	98a080e7          	jalr	-1654(ra) # 8000053e <panic>

0000000080003bbc <fsinit>:
fsinit(int dev) {
    80003bbc:	7179                	addi	sp,sp,-48
    80003bbe:	f406                	sd	ra,40(sp)
    80003bc0:	f022                	sd	s0,32(sp)
    80003bc2:	ec26                	sd	s1,24(sp)
    80003bc4:	e84a                	sd	s2,16(sp)
    80003bc6:	e44e                	sd	s3,8(sp)
    80003bc8:	1800                	addi	s0,sp,48
    80003bca:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bcc:	4585                	li	a1,1
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	a64080e7          	jalr	-1436(ra) # 80003632 <bread>
    80003bd6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bd8:	0001c997          	auipc	s3,0x1c
    80003bdc:	57898993          	addi	s3,s3,1400 # 80020150 <sb>
    80003be0:	02000613          	li	a2,32
    80003be4:	05850593          	addi	a1,a0,88
    80003be8:	854e                	mv	a0,s3
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	17a080e7          	jalr	378(ra) # 80000d64 <memmove>
  brelse(bp);
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	b6e080e7          	jalr	-1170(ra) # 80003762 <brelse>
  if(sb.magic != FSMAGIC)
    80003bfc:	0009a703          	lw	a4,0(s3)
    80003c00:	102037b7          	lui	a5,0x10203
    80003c04:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c08:	02f71263          	bne	a4,a5,80003c2c <fsinit+0x70>
  initlog(dev, &sb);
    80003c0c:	0001c597          	auipc	a1,0x1c
    80003c10:	54458593          	addi	a1,a1,1348 # 80020150 <sb>
    80003c14:	854a                	mv	a0,s2
    80003c16:	00001097          	auipc	ra,0x1
    80003c1a:	b4c080e7          	jalr	-1204(ra) # 80004762 <initlog>
}
    80003c1e:	70a2                	ld	ra,40(sp)
    80003c20:	7402                	ld	s0,32(sp)
    80003c22:	64e2                	ld	s1,24(sp)
    80003c24:	6942                	ld	s2,16(sp)
    80003c26:	69a2                	ld	s3,8(sp)
    80003c28:	6145                	addi	sp,sp,48
    80003c2a:	8082                	ret
    panic("invalid file system");
    80003c2c:	00005517          	auipc	a0,0x5
    80003c30:	a0c50513          	addi	a0,a0,-1524 # 80008638 <syscalls+0x158>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	90a080e7          	jalr	-1782(ra) # 8000053e <panic>

0000000080003c3c <iinit>:
{
    80003c3c:	7179                	addi	sp,sp,-48
    80003c3e:	f406                	sd	ra,40(sp)
    80003c40:	f022                	sd	s0,32(sp)
    80003c42:	ec26                	sd	s1,24(sp)
    80003c44:	e84a                	sd	s2,16(sp)
    80003c46:	e44e                	sd	s3,8(sp)
    80003c48:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c4a:	00005597          	auipc	a1,0x5
    80003c4e:	a0658593          	addi	a1,a1,-1530 # 80008650 <syscalls+0x170>
    80003c52:	0001c517          	auipc	a0,0x1c
    80003c56:	51e50513          	addi	a0,a0,1310 # 80020170 <itable>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	efa080e7          	jalr	-262(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c62:	0001c497          	auipc	s1,0x1c
    80003c66:	53648493          	addi	s1,s1,1334 # 80020198 <itable+0x28>
    80003c6a:	0001e997          	auipc	s3,0x1e
    80003c6e:	fbe98993          	addi	s3,s3,-66 # 80021c28 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c72:	00005917          	auipc	s2,0x5
    80003c76:	9e690913          	addi	s2,s2,-1562 # 80008658 <syscalls+0x178>
    80003c7a:	85ca                	mv	a1,s2
    80003c7c:	8526                	mv	a0,s1
    80003c7e:	00001097          	auipc	ra,0x1
    80003c82:	e46080e7          	jalr	-442(ra) # 80004ac4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c86:	08848493          	addi	s1,s1,136
    80003c8a:	ff3498e3          	bne	s1,s3,80003c7a <iinit+0x3e>
}
    80003c8e:	70a2                	ld	ra,40(sp)
    80003c90:	7402                	ld	s0,32(sp)
    80003c92:	64e2                	ld	s1,24(sp)
    80003c94:	6942                	ld	s2,16(sp)
    80003c96:	69a2                	ld	s3,8(sp)
    80003c98:	6145                	addi	sp,sp,48
    80003c9a:	8082                	ret

0000000080003c9c <ialloc>:
{
    80003c9c:	715d                	addi	sp,sp,-80
    80003c9e:	e486                	sd	ra,72(sp)
    80003ca0:	e0a2                	sd	s0,64(sp)
    80003ca2:	fc26                	sd	s1,56(sp)
    80003ca4:	f84a                	sd	s2,48(sp)
    80003ca6:	f44e                	sd	s3,40(sp)
    80003ca8:	f052                	sd	s4,32(sp)
    80003caa:	ec56                	sd	s5,24(sp)
    80003cac:	e85a                	sd	s6,16(sp)
    80003cae:	e45e                	sd	s7,8(sp)
    80003cb0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb2:	0001c717          	auipc	a4,0x1c
    80003cb6:	4aa72703          	lw	a4,1194(a4) # 8002015c <sb+0xc>
    80003cba:	4785                	li	a5,1
    80003cbc:	04e7fa63          	bgeu	a5,a4,80003d10 <ialloc+0x74>
    80003cc0:	8aaa                	mv	s5,a0
    80003cc2:	8bae                	mv	s7,a1
    80003cc4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cc6:	0001ca17          	auipc	s4,0x1c
    80003cca:	48aa0a13          	addi	s4,s4,1162 # 80020150 <sb>
    80003cce:	00048b1b          	sext.w	s6,s1
    80003cd2:	0044d593          	srli	a1,s1,0x4
    80003cd6:	018a2783          	lw	a5,24(s4)
    80003cda:	9dbd                	addw	a1,a1,a5
    80003cdc:	8556                	mv	a0,s5
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	954080e7          	jalr	-1708(ra) # 80003632 <bread>
    80003ce6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ce8:	05850993          	addi	s3,a0,88
    80003cec:	00f4f793          	andi	a5,s1,15
    80003cf0:	079a                	slli	a5,a5,0x6
    80003cf2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cf4:	00099783          	lh	a5,0(s3)
    80003cf8:	c785                	beqz	a5,80003d20 <ialloc+0x84>
    brelse(bp);
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	a68080e7          	jalr	-1432(ra) # 80003762 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d02:	0485                	addi	s1,s1,1
    80003d04:	00ca2703          	lw	a4,12(s4)
    80003d08:	0004879b          	sext.w	a5,s1
    80003d0c:	fce7e1e3          	bltu	a5,a4,80003cce <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d10:	00005517          	auipc	a0,0x5
    80003d14:	95050513          	addi	a0,a0,-1712 # 80008660 <syscalls+0x180>
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	826080e7          	jalr	-2010(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003d20:	04000613          	li	a2,64
    80003d24:	4581                	li	a1,0
    80003d26:	854e                	mv	a0,s3
    80003d28:	ffffd097          	auipc	ra,0xffffd
    80003d2c:	fdc080e7          	jalr	-36(ra) # 80000d04 <memset>
      dip->type = type;
    80003d30:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d34:	854a                	mv	a0,s2
    80003d36:	00001097          	auipc	ra,0x1
    80003d3a:	ca8080e7          	jalr	-856(ra) # 800049de <log_write>
      brelse(bp);
    80003d3e:	854a                	mv	a0,s2
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	a22080e7          	jalr	-1502(ra) # 80003762 <brelse>
      return iget(dev, inum);
    80003d48:	85da                	mv	a1,s6
    80003d4a:	8556                	mv	a0,s5
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	db4080e7          	jalr	-588(ra) # 80003b00 <iget>
}
    80003d54:	60a6                	ld	ra,72(sp)
    80003d56:	6406                	ld	s0,64(sp)
    80003d58:	74e2                	ld	s1,56(sp)
    80003d5a:	7942                	ld	s2,48(sp)
    80003d5c:	79a2                	ld	s3,40(sp)
    80003d5e:	7a02                	ld	s4,32(sp)
    80003d60:	6ae2                	ld	s5,24(sp)
    80003d62:	6b42                	ld	s6,16(sp)
    80003d64:	6ba2                	ld	s7,8(sp)
    80003d66:	6161                	addi	sp,sp,80
    80003d68:	8082                	ret

0000000080003d6a <iupdate>:
{
    80003d6a:	1101                	addi	sp,sp,-32
    80003d6c:	ec06                	sd	ra,24(sp)
    80003d6e:	e822                	sd	s0,16(sp)
    80003d70:	e426                	sd	s1,8(sp)
    80003d72:	e04a                	sd	s2,0(sp)
    80003d74:	1000                	addi	s0,sp,32
    80003d76:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d78:	415c                	lw	a5,4(a0)
    80003d7a:	0047d79b          	srliw	a5,a5,0x4
    80003d7e:	0001c597          	auipc	a1,0x1c
    80003d82:	3ea5a583          	lw	a1,1002(a1) # 80020168 <sb+0x18>
    80003d86:	9dbd                	addw	a1,a1,a5
    80003d88:	4108                	lw	a0,0(a0)
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	8a8080e7          	jalr	-1880(ra) # 80003632 <bread>
    80003d92:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d94:	05850793          	addi	a5,a0,88
    80003d98:	40c8                	lw	a0,4(s1)
    80003d9a:	893d                	andi	a0,a0,15
    80003d9c:	051a                	slli	a0,a0,0x6
    80003d9e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003da0:	04449703          	lh	a4,68(s1)
    80003da4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003da8:	04649703          	lh	a4,70(s1)
    80003dac:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003db0:	04849703          	lh	a4,72(s1)
    80003db4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003db8:	04a49703          	lh	a4,74(s1)
    80003dbc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003dc0:	44f8                	lw	a4,76(s1)
    80003dc2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dc4:	03400613          	li	a2,52
    80003dc8:	05048593          	addi	a1,s1,80
    80003dcc:	0531                	addi	a0,a0,12
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	f96080e7          	jalr	-106(ra) # 80000d64 <memmove>
  log_write(bp);
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00001097          	auipc	ra,0x1
    80003ddc:	c06080e7          	jalr	-1018(ra) # 800049de <log_write>
  brelse(bp);
    80003de0:	854a                	mv	a0,s2
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	980080e7          	jalr	-1664(ra) # 80003762 <brelse>
}
    80003dea:	60e2                	ld	ra,24(sp)
    80003dec:	6442                	ld	s0,16(sp)
    80003dee:	64a2                	ld	s1,8(sp)
    80003df0:	6902                	ld	s2,0(sp)
    80003df2:	6105                	addi	sp,sp,32
    80003df4:	8082                	ret

0000000080003df6 <idup>:
{
    80003df6:	1101                	addi	sp,sp,-32
    80003df8:	ec06                	sd	ra,24(sp)
    80003dfa:	e822                	sd	s0,16(sp)
    80003dfc:	e426                	sd	s1,8(sp)
    80003dfe:	1000                	addi	s0,sp,32
    80003e00:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e02:	0001c517          	auipc	a0,0x1c
    80003e06:	36e50513          	addi	a0,a0,878 # 80020170 <itable>
    80003e0a:	ffffd097          	auipc	ra,0xffffd
    80003e0e:	dda080e7          	jalr	-550(ra) # 80000be4 <acquire>
  ip->ref++;
    80003e12:	449c                	lw	a5,8(s1)
    80003e14:	2785                	addiw	a5,a5,1
    80003e16:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e18:	0001c517          	auipc	a0,0x1c
    80003e1c:	35850513          	addi	a0,a0,856 # 80020170 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	e8a080e7          	jalr	-374(ra) # 80000caa <release>
}
    80003e28:	8526                	mv	a0,s1
    80003e2a:	60e2                	ld	ra,24(sp)
    80003e2c:	6442                	ld	s0,16(sp)
    80003e2e:	64a2                	ld	s1,8(sp)
    80003e30:	6105                	addi	sp,sp,32
    80003e32:	8082                	ret

0000000080003e34 <ilock>:
{
    80003e34:	1101                	addi	sp,sp,-32
    80003e36:	ec06                	sd	ra,24(sp)
    80003e38:	e822                	sd	s0,16(sp)
    80003e3a:	e426                	sd	s1,8(sp)
    80003e3c:	e04a                	sd	s2,0(sp)
    80003e3e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e40:	c115                	beqz	a0,80003e64 <ilock+0x30>
    80003e42:	84aa                	mv	s1,a0
    80003e44:	451c                	lw	a5,8(a0)
    80003e46:	00f05f63          	blez	a5,80003e64 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e4a:	0541                	addi	a0,a0,16
    80003e4c:	00001097          	auipc	ra,0x1
    80003e50:	cb2080e7          	jalr	-846(ra) # 80004afe <acquiresleep>
  if(ip->valid == 0){
    80003e54:	40bc                	lw	a5,64(s1)
    80003e56:	cf99                	beqz	a5,80003e74 <ilock+0x40>
}
    80003e58:	60e2                	ld	ra,24(sp)
    80003e5a:	6442                	ld	s0,16(sp)
    80003e5c:	64a2                	ld	s1,8(sp)
    80003e5e:	6902                	ld	s2,0(sp)
    80003e60:	6105                	addi	sp,sp,32
    80003e62:	8082                	ret
    panic("ilock");
    80003e64:	00005517          	auipc	a0,0x5
    80003e68:	81450513          	addi	a0,a0,-2028 # 80008678 <syscalls+0x198>
    80003e6c:	ffffc097          	auipc	ra,0xffffc
    80003e70:	6d2080e7          	jalr	1746(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e74:	40dc                	lw	a5,4(s1)
    80003e76:	0047d79b          	srliw	a5,a5,0x4
    80003e7a:	0001c597          	auipc	a1,0x1c
    80003e7e:	2ee5a583          	lw	a1,750(a1) # 80020168 <sb+0x18>
    80003e82:	9dbd                	addw	a1,a1,a5
    80003e84:	4088                	lw	a0,0(s1)
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	7ac080e7          	jalr	1964(ra) # 80003632 <bread>
    80003e8e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e90:	05850593          	addi	a1,a0,88
    80003e94:	40dc                	lw	a5,4(s1)
    80003e96:	8bbd                	andi	a5,a5,15
    80003e98:	079a                	slli	a5,a5,0x6
    80003e9a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e9c:	00059783          	lh	a5,0(a1)
    80003ea0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ea4:	00259783          	lh	a5,2(a1)
    80003ea8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003eac:	00459783          	lh	a5,4(a1)
    80003eb0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003eb4:	00659783          	lh	a5,6(a1)
    80003eb8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ebc:	459c                	lw	a5,8(a1)
    80003ebe:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ec0:	03400613          	li	a2,52
    80003ec4:	05b1                	addi	a1,a1,12
    80003ec6:	05048513          	addi	a0,s1,80
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	e9a080e7          	jalr	-358(ra) # 80000d64 <memmove>
    brelse(bp);
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	88e080e7          	jalr	-1906(ra) # 80003762 <brelse>
    ip->valid = 1;
    80003edc:	4785                	li	a5,1
    80003ede:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ee0:	04449783          	lh	a5,68(s1)
    80003ee4:	fbb5                	bnez	a5,80003e58 <ilock+0x24>
      panic("ilock: no type");
    80003ee6:	00004517          	auipc	a0,0x4
    80003eea:	79a50513          	addi	a0,a0,1946 # 80008680 <syscalls+0x1a0>
    80003eee:	ffffc097          	auipc	ra,0xffffc
    80003ef2:	650080e7          	jalr	1616(ra) # 8000053e <panic>

0000000080003ef6 <iunlock>:
{
    80003ef6:	1101                	addi	sp,sp,-32
    80003ef8:	ec06                	sd	ra,24(sp)
    80003efa:	e822                	sd	s0,16(sp)
    80003efc:	e426                	sd	s1,8(sp)
    80003efe:	e04a                	sd	s2,0(sp)
    80003f00:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f02:	c905                	beqz	a0,80003f32 <iunlock+0x3c>
    80003f04:	84aa                	mv	s1,a0
    80003f06:	01050913          	addi	s2,a0,16
    80003f0a:	854a                	mv	a0,s2
    80003f0c:	00001097          	auipc	ra,0x1
    80003f10:	c8c080e7          	jalr	-884(ra) # 80004b98 <holdingsleep>
    80003f14:	cd19                	beqz	a0,80003f32 <iunlock+0x3c>
    80003f16:	449c                	lw	a5,8(s1)
    80003f18:	00f05d63          	blez	a5,80003f32 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00001097          	auipc	ra,0x1
    80003f22:	c36080e7          	jalr	-970(ra) # 80004b54 <releasesleep>
}
    80003f26:	60e2                	ld	ra,24(sp)
    80003f28:	6442                	ld	s0,16(sp)
    80003f2a:	64a2                	ld	s1,8(sp)
    80003f2c:	6902                	ld	s2,0(sp)
    80003f2e:	6105                	addi	sp,sp,32
    80003f30:	8082                	ret
    panic("iunlock");
    80003f32:	00004517          	auipc	a0,0x4
    80003f36:	75e50513          	addi	a0,a0,1886 # 80008690 <syscalls+0x1b0>
    80003f3a:	ffffc097          	auipc	ra,0xffffc
    80003f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>

0000000080003f42 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f42:	7179                	addi	sp,sp,-48
    80003f44:	f406                	sd	ra,40(sp)
    80003f46:	f022                	sd	s0,32(sp)
    80003f48:	ec26                	sd	s1,24(sp)
    80003f4a:	e84a                	sd	s2,16(sp)
    80003f4c:	e44e                	sd	s3,8(sp)
    80003f4e:	e052                	sd	s4,0(sp)
    80003f50:	1800                	addi	s0,sp,48
    80003f52:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f54:	05050493          	addi	s1,a0,80
    80003f58:	08050913          	addi	s2,a0,128
    80003f5c:	a021                	j	80003f64 <itrunc+0x22>
    80003f5e:	0491                	addi	s1,s1,4
    80003f60:	01248d63          	beq	s1,s2,80003f7a <itrunc+0x38>
    if(ip->addrs[i]){
    80003f64:	408c                	lw	a1,0(s1)
    80003f66:	dde5                	beqz	a1,80003f5e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f68:	0009a503          	lw	a0,0(s3)
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	90c080e7          	jalr	-1780(ra) # 80003878 <bfree>
      ip->addrs[i] = 0;
    80003f74:	0004a023          	sw	zero,0(s1)
    80003f78:	b7dd                	j	80003f5e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f7a:	0809a583          	lw	a1,128(s3)
    80003f7e:	e185                	bnez	a1,80003f9e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f80:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f84:	854e                	mv	a0,s3
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	de4080e7          	jalr	-540(ra) # 80003d6a <iupdate>
}
    80003f8e:	70a2                	ld	ra,40(sp)
    80003f90:	7402                	ld	s0,32(sp)
    80003f92:	64e2                	ld	s1,24(sp)
    80003f94:	6942                	ld	s2,16(sp)
    80003f96:	69a2                	ld	s3,8(sp)
    80003f98:	6a02                	ld	s4,0(sp)
    80003f9a:	6145                	addi	sp,sp,48
    80003f9c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f9e:	0009a503          	lw	a0,0(s3)
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	690080e7          	jalr	1680(ra) # 80003632 <bread>
    80003faa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fac:	05850493          	addi	s1,a0,88
    80003fb0:	45850913          	addi	s2,a0,1112
    80003fb4:	a811                	j	80003fc8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003fb6:	0009a503          	lw	a0,0(s3)
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	8be080e7          	jalr	-1858(ra) # 80003878 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003fc2:	0491                	addi	s1,s1,4
    80003fc4:	01248563          	beq	s1,s2,80003fce <itrunc+0x8c>
      if(a[j])
    80003fc8:	408c                	lw	a1,0(s1)
    80003fca:	dde5                	beqz	a1,80003fc2 <itrunc+0x80>
    80003fcc:	b7ed                	j	80003fb6 <itrunc+0x74>
    brelse(bp);
    80003fce:	8552                	mv	a0,s4
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	792080e7          	jalr	1938(ra) # 80003762 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fd8:	0809a583          	lw	a1,128(s3)
    80003fdc:	0009a503          	lw	a0,0(s3)
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	898080e7          	jalr	-1896(ra) # 80003878 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fe8:	0809a023          	sw	zero,128(s3)
    80003fec:	bf51                	j	80003f80 <itrunc+0x3e>

0000000080003fee <iput>:
{
    80003fee:	1101                	addi	sp,sp,-32
    80003ff0:	ec06                	sd	ra,24(sp)
    80003ff2:	e822                	sd	s0,16(sp)
    80003ff4:	e426                	sd	s1,8(sp)
    80003ff6:	e04a                	sd	s2,0(sp)
    80003ff8:	1000                	addi	s0,sp,32
    80003ffa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ffc:	0001c517          	auipc	a0,0x1c
    80004000:	17450513          	addi	a0,a0,372 # 80020170 <itable>
    80004004:	ffffd097          	auipc	ra,0xffffd
    80004008:	be0080e7          	jalr	-1056(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000400c:	4498                	lw	a4,8(s1)
    8000400e:	4785                	li	a5,1
    80004010:	02f70363          	beq	a4,a5,80004036 <iput+0x48>
  ip->ref--;
    80004014:	449c                	lw	a5,8(s1)
    80004016:	37fd                	addiw	a5,a5,-1
    80004018:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000401a:	0001c517          	auipc	a0,0x1c
    8000401e:	15650513          	addi	a0,a0,342 # 80020170 <itable>
    80004022:	ffffd097          	auipc	ra,0xffffd
    80004026:	c88080e7          	jalr	-888(ra) # 80000caa <release>
}
    8000402a:	60e2                	ld	ra,24(sp)
    8000402c:	6442                	ld	s0,16(sp)
    8000402e:	64a2                	ld	s1,8(sp)
    80004030:	6902                	ld	s2,0(sp)
    80004032:	6105                	addi	sp,sp,32
    80004034:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004036:	40bc                	lw	a5,64(s1)
    80004038:	dff1                	beqz	a5,80004014 <iput+0x26>
    8000403a:	04a49783          	lh	a5,74(s1)
    8000403e:	fbf9                	bnez	a5,80004014 <iput+0x26>
    acquiresleep(&ip->lock);
    80004040:	01048913          	addi	s2,s1,16
    80004044:	854a                	mv	a0,s2
    80004046:	00001097          	auipc	ra,0x1
    8000404a:	ab8080e7          	jalr	-1352(ra) # 80004afe <acquiresleep>
    release(&itable.lock);
    8000404e:	0001c517          	auipc	a0,0x1c
    80004052:	12250513          	addi	a0,a0,290 # 80020170 <itable>
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	c54080e7          	jalr	-940(ra) # 80000caa <release>
    itrunc(ip);
    8000405e:	8526                	mv	a0,s1
    80004060:	00000097          	auipc	ra,0x0
    80004064:	ee2080e7          	jalr	-286(ra) # 80003f42 <itrunc>
    ip->type = 0;
    80004068:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000406c:	8526                	mv	a0,s1
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	cfc080e7          	jalr	-772(ra) # 80003d6a <iupdate>
    ip->valid = 0;
    80004076:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000407a:	854a                	mv	a0,s2
    8000407c:	00001097          	auipc	ra,0x1
    80004080:	ad8080e7          	jalr	-1320(ra) # 80004b54 <releasesleep>
    acquire(&itable.lock);
    80004084:	0001c517          	auipc	a0,0x1c
    80004088:	0ec50513          	addi	a0,a0,236 # 80020170 <itable>
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	b58080e7          	jalr	-1192(ra) # 80000be4 <acquire>
    80004094:	b741                	j	80004014 <iput+0x26>

0000000080004096 <iunlockput>:
{
    80004096:	1101                	addi	sp,sp,-32
    80004098:	ec06                	sd	ra,24(sp)
    8000409a:	e822                	sd	s0,16(sp)
    8000409c:	e426                	sd	s1,8(sp)
    8000409e:	1000                	addi	s0,sp,32
    800040a0:	84aa                	mv	s1,a0
  iunlock(ip);
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	e54080e7          	jalr	-428(ra) # 80003ef6 <iunlock>
  iput(ip);
    800040aa:	8526                	mv	a0,s1
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	f42080e7          	jalr	-190(ra) # 80003fee <iput>
}
    800040b4:	60e2                	ld	ra,24(sp)
    800040b6:	6442                	ld	s0,16(sp)
    800040b8:	64a2                	ld	s1,8(sp)
    800040ba:	6105                	addi	sp,sp,32
    800040bc:	8082                	ret

00000000800040be <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040be:	1141                	addi	sp,sp,-16
    800040c0:	e422                	sd	s0,8(sp)
    800040c2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040c4:	411c                	lw	a5,0(a0)
    800040c6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040c8:	415c                	lw	a5,4(a0)
    800040ca:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040cc:	04451783          	lh	a5,68(a0)
    800040d0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040d4:	04a51783          	lh	a5,74(a0)
    800040d8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040dc:	04c56783          	lwu	a5,76(a0)
    800040e0:	e99c                	sd	a5,16(a1)
}
    800040e2:	6422                	ld	s0,8(sp)
    800040e4:	0141                	addi	sp,sp,16
    800040e6:	8082                	ret

00000000800040e8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040e8:	457c                	lw	a5,76(a0)
    800040ea:	0ed7e963          	bltu	a5,a3,800041dc <readi+0xf4>
{
    800040ee:	7159                	addi	sp,sp,-112
    800040f0:	f486                	sd	ra,104(sp)
    800040f2:	f0a2                	sd	s0,96(sp)
    800040f4:	eca6                	sd	s1,88(sp)
    800040f6:	e8ca                	sd	s2,80(sp)
    800040f8:	e4ce                	sd	s3,72(sp)
    800040fa:	e0d2                	sd	s4,64(sp)
    800040fc:	fc56                	sd	s5,56(sp)
    800040fe:	f85a                	sd	s6,48(sp)
    80004100:	f45e                	sd	s7,40(sp)
    80004102:	f062                	sd	s8,32(sp)
    80004104:	ec66                	sd	s9,24(sp)
    80004106:	e86a                	sd	s10,16(sp)
    80004108:	e46e                	sd	s11,8(sp)
    8000410a:	1880                	addi	s0,sp,112
    8000410c:	8baa                	mv	s7,a0
    8000410e:	8c2e                	mv	s8,a1
    80004110:	8ab2                	mv	s5,a2
    80004112:	84b6                	mv	s1,a3
    80004114:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004116:	9f35                	addw	a4,a4,a3
    return 0;
    80004118:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000411a:	0ad76063          	bltu	a4,a3,800041ba <readi+0xd2>
  if(off + n > ip->size)
    8000411e:	00e7f463          	bgeu	a5,a4,80004126 <readi+0x3e>
    n = ip->size - off;
    80004122:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004126:	0a0b0963          	beqz	s6,800041d8 <readi+0xf0>
    8000412a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000412c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004130:	5cfd                	li	s9,-1
    80004132:	a82d                	j	8000416c <readi+0x84>
    80004134:	020a1d93          	slli	s11,s4,0x20
    80004138:	020ddd93          	srli	s11,s11,0x20
    8000413c:	05890613          	addi	a2,s2,88
    80004140:	86ee                	mv	a3,s11
    80004142:	963a                	add	a2,a2,a4
    80004144:	85d6                	mv	a1,s5
    80004146:	8562                	mv	a0,s8
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	a1e080e7          	jalr	-1506(ra) # 80002b66 <either_copyout>
    80004150:	05950d63          	beq	a0,s9,800041aa <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004154:	854a                	mv	a0,s2
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	60c080e7          	jalr	1548(ra) # 80003762 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000415e:	013a09bb          	addw	s3,s4,s3
    80004162:	009a04bb          	addw	s1,s4,s1
    80004166:	9aee                	add	s5,s5,s11
    80004168:	0569f763          	bgeu	s3,s6,800041b6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000416c:	000ba903          	lw	s2,0(s7)
    80004170:	00a4d59b          	srliw	a1,s1,0xa
    80004174:	855e                	mv	a0,s7
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	8b0080e7          	jalr	-1872(ra) # 80003a26 <bmap>
    8000417e:	0005059b          	sext.w	a1,a0
    80004182:	854a                	mv	a0,s2
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	4ae080e7          	jalr	1198(ra) # 80003632 <bread>
    8000418c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000418e:	3ff4f713          	andi	a4,s1,1023
    80004192:	40ed07bb          	subw	a5,s10,a4
    80004196:	413b06bb          	subw	a3,s6,s3
    8000419a:	8a3e                	mv	s4,a5
    8000419c:	2781                	sext.w	a5,a5
    8000419e:	0006861b          	sext.w	a2,a3
    800041a2:	f8f679e3          	bgeu	a2,a5,80004134 <readi+0x4c>
    800041a6:	8a36                	mv	s4,a3
    800041a8:	b771                	j	80004134 <readi+0x4c>
      brelse(bp);
    800041aa:	854a                	mv	a0,s2
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	5b6080e7          	jalr	1462(ra) # 80003762 <brelse>
      tot = -1;
    800041b4:	59fd                	li	s3,-1
  }
  return tot;
    800041b6:	0009851b          	sext.w	a0,s3
}
    800041ba:	70a6                	ld	ra,104(sp)
    800041bc:	7406                	ld	s0,96(sp)
    800041be:	64e6                	ld	s1,88(sp)
    800041c0:	6946                	ld	s2,80(sp)
    800041c2:	69a6                	ld	s3,72(sp)
    800041c4:	6a06                	ld	s4,64(sp)
    800041c6:	7ae2                	ld	s5,56(sp)
    800041c8:	7b42                	ld	s6,48(sp)
    800041ca:	7ba2                	ld	s7,40(sp)
    800041cc:	7c02                	ld	s8,32(sp)
    800041ce:	6ce2                	ld	s9,24(sp)
    800041d0:	6d42                	ld	s10,16(sp)
    800041d2:	6da2                	ld	s11,8(sp)
    800041d4:	6165                	addi	sp,sp,112
    800041d6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041d8:	89da                	mv	s3,s6
    800041da:	bff1                	j	800041b6 <readi+0xce>
    return 0;
    800041dc:	4501                	li	a0,0
}
    800041de:	8082                	ret

00000000800041e0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041e0:	457c                	lw	a5,76(a0)
    800041e2:	10d7e863          	bltu	a5,a3,800042f2 <writei+0x112>
{
    800041e6:	7159                	addi	sp,sp,-112
    800041e8:	f486                	sd	ra,104(sp)
    800041ea:	f0a2                	sd	s0,96(sp)
    800041ec:	eca6                	sd	s1,88(sp)
    800041ee:	e8ca                	sd	s2,80(sp)
    800041f0:	e4ce                	sd	s3,72(sp)
    800041f2:	e0d2                	sd	s4,64(sp)
    800041f4:	fc56                	sd	s5,56(sp)
    800041f6:	f85a                	sd	s6,48(sp)
    800041f8:	f45e                	sd	s7,40(sp)
    800041fa:	f062                	sd	s8,32(sp)
    800041fc:	ec66                	sd	s9,24(sp)
    800041fe:	e86a                	sd	s10,16(sp)
    80004200:	e46e                	sd	s11,8(sp)
    80004202:	1880                	addi	s0,sp,112
    80004204:	8b2a                	mv	s6,a0
    80004206:	8c2e                	mv	s8,a1
    80004208:	8ab2                	mv	s5,a2
    8000420a:	8936                	mv	s2,a3
    8000420c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000420e:	00e687bb          	addw	a5,a3,a4
    80004212:	0ed7e263          	bltu	a5,a3,800042f6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004216:	00043737          	lui	a4,0x43
    8000421a:	0ef76063          	bltu	a4,a5,800042fa <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000421e:	0c0b8863          	beqz	s7,800042ee <writei+0x10e>
    80004222:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004224:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004228:	5cfd                	li	s9,-1
    8000422a:	a091                	j	8000426e <writei+0x8e>
    8000422c:	02099d93          	slli	s11,s3,0x20
    80004230:	020ddd93          	srli	s11,s11,0x20
    80004234:	05848513          	addi	a0,s1,88
    80004238:	86ee                	mv	a3,s11
    8000423a:	8656                	mv	a2,s5
    8000423c:	85e2                	mv	a1,s8
    8000423e:	953a                	add	a0,a0,a4
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	97c080e7          	jalr	-1668(ra) # 80002bbc <either_copyin>
    80004248:	07950263          	beq	a0,s9,800042ac <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000424c:	8526                	mv	a0,s1
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	790080e7          	jalr	1936(ra) # 800049de <log_write>
    brelse(bp);
    80004256:	8526                	mv	a0,s1
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	50a080e7          	jalr	1290(ra) # 80003762 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004260:	01498a3b          	addw	s4,s3,s4
    80004264:	0129893b          	addw	s2,s3,s2
    80004268:	9aee                	add	s5,s5,s11
    8000426a:	057a7663          	bgeu	s4,s7,800042b6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000426e:	000b2483          	lw	s1,0(s6)
    80004272:	00a9559b          	srliw	a1,s2,0xa
    80004276:	855a                	mv	a0,s6
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	7ae080e7          	jalr	1966(ra) # 80003a26 <bmap>
    80004280:	0005059b          	sext.w	a1,a0
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	3ac080e7          	jalr	940(ra) # 80003632 <bread>
    8000428e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004290:	3ff97713          	andi	a4,s2,1023
    80004294:	40ed07bb          	subw	a5,s10,a4
    80004298:	414b86bb          	subw	a3,s7,s4
    8000429c:	89be                	mv	s3,a5
    8000429e:	2781                	sext.w	a5,a5
    800042a0:	0006861b          	sext.w	a2,a3
    800042a4:	f8f674e3          	bgeu	a2,a5,8000422c <writei+0x4c>
    800042a8:	89b6                	mv	s3,a3
    800042aa:	b749                	j	8000422c <writei+0x4c>
      brelse(bp);
    800042ac:	8526                	mv	a0,s1
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	4b4080e7          	jalr	1204(ra) # 80003762 <brelse>
  }

  if(off > ip->size)
    800042b6:	04cb2783          	lw	a5,76(s6)
    800042ba:	0127f463          	bgeu	a5,s2,800042c2 <writei+0xe2>
    ip->size = off;
    800042be:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042c2:	855a                	mv	a0,s6
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	aa6080e7          	jalr	-1370(ra) # 80003d6a <iupdate>

  return tot;
    800042cc:	000a051b          	sext.w	a0,s4
}
    800042d0:	70a6                	ld	ra,104(sp)
    800042d2:	7406                	ld	s0,96(sp)
    800042d4:	64e6                	ld	s1,88(sp)
    800042d6:	6946                	ld	s2,80(sp)
    800042d8:	69a6                	ld	s3,72(sp)
    800042da:	6a06                	ld	s4,64(sp)
    800042dc:	7ae2                	ld	s5,56(sp)
    800042de:	7b42                	ld	s6,48(sp)
    800042e0:	7ba2                	ld	s7,40(sp)
    800042e2:	7c02                	ld	s8,32(sp)
    800042e4:	6ce2                	ld	s9,24(sp)
    800042e6:	6d42                	ld	s10,16(sp)
    800042e8:	6da2                	ld	s11,8(sp)
    800042ea:	6165                	addi	sp,sp,112
    800042ec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042ee:	8a5e                	mv	s4,s7
    800042f0:	bfc9                	j	800042c2 <writei+0xe2>
    return -1;
    800042f2:	557d                	li	a0,-1
}
    800042f4:	8082                	ret
    return -1;
    800042f6:	557d                	li	a0,-1
    800042f8:	bfe1                	j	800042d0 <writei+0xf0>
    return -1;
    800042fa:	557d                	li	a0,-1
    800042fc:	bfd1                	j	800042d0 <writei+0xf0>

00000000800042fe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042fe:	1141                	addi	sp,sp,-16
    80004300:	e406                	sd	ra,8(sp)
    80004302:	e022                	sd	s0,0(sp)
    80004304:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004306:	4639                	li	a2,14
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	ad4080e7          	jalr	-1324(ra) # 80000ddc <strncmp>
}
    80004310:	60a2                	ld	ra,8(sp)
    80004312:	6402                	ld	s0,0(sp)
    80004314:	0141                	addi	sp,sp,16
    80004316:	8082                	ret

0000000080004318 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004318:	7139                	addi	sp,sp,-64
    8000431a:	fc06                	sd	ra,56(sp)
    8000431c:	f822                	sd	s0,48(sp)
    8000431e:	f426                	sd	s1,40(sp)
    80004320:	f04a                	sd	s2,32(sp)
    80004322:	ec4e                	sd	s3,24(sp)
    80004324:	e852                	sd	s4,16(sp)
    80004326:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004328:	04451703          	lh	a4,68(a0)
    8000432c:	4785                	li	a5,1
    8000432e:	00f71a63          	bne	a4,a5,80004342 <dirlookup+0x2a>
    80004332:	892a                	mv	s2,a0
    80004334:	89ae                	mv	s3,a1
    80004336:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004338:	457c                	lw	a5,76(a0)
    8000433a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000433c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000433e:	e79d                	bnez	a5,8000436c <dirlookup+0x54>
    80004340:	a8a5                	j	800043b8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004342:	00004517          	auipc	a0,0x4
    80004346:	35650513          	addi	a0,a0,854 # 80008698 <syscalls+0x1b8>
    8000434a:	ffffc097          	auipc	ra,0xffffc
    8000434e:	1f4080e7          	jalr	500(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004352:	00004517          	auipc	a0,0x4
    80004356:	35e50513          	addi	a0,a0,862 # 800086b0 <syscalls+0x1d0>
    8000435a:	ffffc097          	auipc	ra,0xffffc
    8000435e:	1e4080e7          	jalr	484(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004362:	24c1                	addiw	s1,s1,16
    80004364:	04c92783          	lw	a5,76(s2)
    80004368:	04f4f763          	bgeu	s1,a5,800043b6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000436c:	4741                	li	a4,16
    8000436e:	86a6                	mv	a3,s1
    80004370:	fc040613          	addi	a2,s0,-64
    80004374:	4581                	li	a1,0
    80004376:	854a                	mv	a0,s2
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	d70080e7          	jalr	-656(ra) # 800040e8 <readi>
    80004380:	47c1                	li	a5,16
    80004382:	fcf518e3          	bne	a0,a5,80004352 <dirlookup+0x3a>
    if(de.inum == 0)
    80004386:	fc045783          	lhu	a5,-64(s0)
    8000438a:	dfe1                	beqz	a5,80004362 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000438c:	fc240593          	addi	a1,s0,-62
    80004390:	854e                	mv	a0,s3
    80004392:	00000097          	auipc	ra,0x0
    80004396:	f6c080e7          	jalr	-148(ra) # 800042fe <namecmp>
    8000439a:	f561                	bnez	a0,80004362 <dirlookup+0x4a>
      if(poff)
    8000439c:	000a0463          	beqz	s4,800043a4 <dirlookup+0x8c>
        *poff = off;
    800043a0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043a4:	fc045583          	lhu	a1,-64(s0)
    800043a8:	00092503          	lw	a0,0(s2)
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	754080e7          	jalr	1876(ra) # 80003b00 <iget>
    800043b4:	a011                	j	800043b8 <dirlookup+0xa0>
  return 0;
    800043b6:	4501                	li	a0,0
}
    800043b8:	70e2                	ld	ra,56(sp)
    800043ba:	7442                	ld	s0,48(sp)
    800043bc:	74a2                	ld	s1,40(sp)
    800043be:	7902                	ld	s2,32(sp)
    800043c0:	69e2                	ld	s3,24(sp)
    800043c2:	6a42                	ld	s4,16(sp)
    800043c4:	6121                	addi	sp,sp,64
    800043c6:	8082                	ret

00000000800043c8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043c8:	711d                	addi	sp,sp,-96
    800043ca:	ec86                	sd	ra,88(sp)
    800043cc:	e8a2                	sd	s0,80(sp)
    800043ce:	e4a6                	sd	s1,72(sp)
    800043d0:	e0ca                	sd	s2,64(sp)
    800043d2:	fc4e                	sd	s3,56(sp)
    800043d4:	f852                	sd	s4,48(sp)
    800043d6:	f456                	sd	s5,40(sp)
    800043d8:	f05a                	sd	s6,32(sp)
    800043da:	ec5e                	sd	s7,24(sp)
    800043dc:	e862                	sd	s8,16(sp)
    800043de:	e466                	sd	s9,8(sp)
    800043e0:	1080                	addi	s0,sp,96
    800043e2:	84aa                	mv	s1,a0
    800043e4:	8b2e                	mv	s6,a1
    800043e6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043e8:	00054703          	lbu	a4,0(a0)
    800043ec:	02f00793          	li	a5,47
    800043f0:	02f70363          	beq	a4,a5,80004416 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043f4:	ffffe097          	auipc	ra,0xffffe
    800043f8:	9e8080e7          	jalr	-1560(ra) # 80001ddc <myproc>
    800043fc:	17053503          	ld	a0,368(a0)
    80004400:	00000097          	auipc	ra,0x0
    80004404:	9f6080e7          	jalr	-1546(ra) # 80003df6 <idup>
    80004408:	89aa                	mv	s3,a0
  while(*path == '/')
    8000440a:	02f00913          	li	s2,47
  len = path - s;
    8000440e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004410:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004412:	4c05                	li	s8,1
    80004414:	a865                	j	800044cc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004416:	4585                	li	a1,1
    80004418:	4505                	li	a0,1
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	6e6080e7          	jalr	1766(ra) # 80003b00 <iget>
    80004422:	89aa                	mv	s3,a0
    80004424:	b7dd                	j	8000440a <namex+0x42>
      iunlockput(ip);
    80004426:	854e                	mv	a0,s3
    80004428:	00000097          	auipc	ra,0x0
    8000442c:	c6e080e7          	jalr	-914(ra) # 80004096 <iunlockput>
      return 0;
    80004430:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004432:	854e                	mv	a0,s3
    80004434:	60e6                	ld	ra,88(sp)
    80004436:	6446                	ld	s0,80(sp)
    80004438:	64a6                	ld	s1,72(sp)
    8000443a:	6906                	ld	s2,64(sp)
    8000443c:	79e2                	ld	s3,56(sp)
    8000443e:	7a42                	ld	s4,48(sp)
    80004440:	7aa2                	ld	s5,40(sp)
    80004442:	7b02                	ld	s6,32(sp)
    80004444:	6be2                	ld	s7,24(sp)
    80004446:	6c42                	ld	s8,16(sp)
    80004448:	6ca2                	ld	s9,8(sp)
    8000444a:	6125                	addi	sp,sp,96
    8000444c:	8082                	ret
      iunlock(ip);
    8000444e:	854e                	mv	a0,s3
    80004450:	00000097          	auipc	ra,0x0
    80004454:	aa6080e7          	jalr	-1370(ra) # 80003ef6 <iunlock>
      return ip;
    80004458:	bfe9                	j	80004432 <namex+0x6a>
      iunlockput(ip);
    8000445a:	854e                	mv	a0,s3
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	c3a080e7          	jalr	-966(ra) # 80004096 <iunlockput>
      return 0;
    80004464:	89d2                	mv	s3,s4
    80004466:	b7f1                	j	80004432 <namex+0x6a>
  len = path - s;
    80004468:	40b48633          	sub	a2,s1,a1
    8000446c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004470:	094cd463          	bge	s9,s4,800044f8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004474:	4639                	li	a2,14
    80004476:	8556                	mv	a0,s5
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	8ec080e7          	jalr	-1812(ra) # 80000d64 <memmove>
  while(*path == '/')
    80004480:	0004c783          	lbu	a5,0(s1)
    80004484:	01279763          	bne	a5,s2,80004492 <namex+0xca>
    path++;
    80004488:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000448a:	0004c783          	lbu	a5,0(s1)
    8000448e:	ff278de3          	beq	a5,s2,80004488 <namex+0xc0>
    ilock(ip);
    80004492:	854e                	mv	a0,s3
    80004494:	00000097          	auipc	ra,0x0
    80004498:	9a0080e7          	jalr	-1632(ra) # 80003e34 <ilock>
    if(ip->type != T_DIR){
    8000449c:	04499783          	lh	a5,68(s3)
    800044a0:	f98793e3          	bne	a5,s8,80004426 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044a4:	000b0563          	beqz	s6,800044ae <namex+0xe6>
    800044a8:	0004c783          	lbu	a5,0(s1)
    800044ac:	d3cd                	beqz	a5,8000444e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044ae:	865e                	mv	a2,s7
    800044b0:	85d6                	mv	a1,s5
    800044b2:	854e                	mv	a0,s3
    800044b4:	00000097          	auipc	ra,0x0
    800044b8:	e64080e7          	jalr	-412(ra) # 80004318 <dirlookup>
    800044bc:	8a2a                	mv	s4,a0
    800044be:	dd51                	beqz	a0,8000445a <namex+0x92>
    iunlockput(ip);
    800044c0:	854e                	mv	a0,s3
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	bd4080e7          	jalr	-1068(ra) # 80004096 <iunlockput>
    ip = next;
    800044ca:	89d2                	mv	s3,s4
  while(*path == '/')
    800044cc:	0004c783          	lbu	a5,0(s1)
    800044d0:	05279763          	bne	a5,s2,8000451e <namex+0x156>
    path++;
    800044d4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044d6:	0004c783          	lbu	a5,0(s1)
    800044da:	ff278de3          	beq	a5,s2,800044d4 <namex+0x10c>
  if(*path == 0)
    800044de:	c79d                	beqz	a5,8000450c <namex+0x144>
    path++;
    800044e0:	85a6                	mv	a1,s1
  len = path - s;
    800044e2:	8a5e                	mv	s4,s7
    800044e4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044e6:	01278963          	beq	a5,s2,800044f8 <namex+0x130>
    800044ea:	dfbd                	beqz	a5,80004468 <namex+0xa0>
    path++;
    800044ec:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044ee:	0004c783          	lbu	a5,0(s1)
    800044f2:	ff279ce3          	bne	a5,s2,800044ea <namex+0x122>
    800044f6:	bf8d                	j	80004468 <namex+0xa0>
    memmove(name, s, len);
    800044f8:	2601                	sext.w	a2,a2
    800044fa:	8556                	mv	a0,s5
    800044fc:	ffffd097          	auipc	ra,0xffffd
    80004500:	868080e7          	jalr	-1944(ra) # 80000d64 <memmove>
    name[len] = 0;
    80004504:	9a56                	add	s4,s4,s5
    80004506:	000a0023          	sb	zero,0(s4)
    8000450a:	bf9d                	j	80004480 <namex+0xb8>
  if(nameiparent){
    8000450c:	f20b03e3          	beqz	s6,80004432 <namex+0x6a>
    iput(ip);
    80004510:	854e                	mv	a0,s3
    80004512:	00000097          	auipc	ra,0x0
    80004516:	adc080e7          	jalr	-1316(ra) # 80003fee <iput>
    return 0;
    8000451a:	4981                	li	s3,0
    8000451c:	bf19                	j	80004432 <namex+0x6a>
  if(*path == 0)
    8000451e:	d7fd                	beqz	a5,8000450c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004520:	0004c783          	lbu	a5,0(s1)
    80004524:	85a6                	mv	a1,s1
    80004526:	b7d1                	j	800044ea <namex+0x122>

0000000080004528 <dirlink>:
{
    80004528:	7139                	addi	sp,sp,-64
    8000452a:	fc06                	sd	ra,56(sp)
    8000452c:	f822                	sd	s0,48(sp)
    8000452e:	f426                	sd	s1,40(sp)
    80004530:	f04a                	sd	s2,32(sp)
    80004532:	ec4e                	sd	s3,24(sp)
    80004534:	e852                	sd	s4,16(sp)
    80004536:	0080                	addi	s0,sp,64
    80004538:	892a                	mv	s2,a0
    8000453a:	8a2e                	mv	s4,a1
    8000453c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000453e:	4601                	li	a2,0
    80004540:	00000097          	auipc	ra,0x0
    80004544:	dd8080e7          	jalr	-552(ra) # 80004318 <dirlookup>
    80004548:	e93d                	bnez	a0,800045be <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000454a:	04c92483          	lw	s1,76(s2)
    8000454e:	c49d                	beqz	s1,8000457c <dirlink+0x54>
    80004550:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004552:	4741                	li	a4,16
    80004554:	86a6                	mv	a3,s1
    80004556:	fc040613          	addi	a2,s0,-64
    8000455a:	4581                	li	a1,0
    8000455c:	854a                	mv	a0,s2
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	b8a080e7          	jalr	-1142(ra) # 800040e8 <readi>
    80004566:	47c1                	li	a5,16
    80004568:	06f51163          	bne	a0,a5,800045ca <dirlink+0xa2>
    if(de.inum == 0)
    8000456c:	fc045783          	lhu	a5,-64(s0)
    80004570:	c791                	beqz	a5,8000457c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004572:	24c1                	addiw	s1,s1,16
    80004574:	04c92783          	lw	a5,76(s2)
    80004578:	fcf4ede3          	bltu	s1,a5,80004552 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000457c:	4639                	li	a2,14
    8000457e:	85d2                	mv	a1,s4
    80004580:	fc240513          	addi	a0,s0,-62
    80004584:	ffffd097          	auipc	ra,0xffffd
    80004588:	894080e7          	jalr	-1900(ra) # 80000e18 <strncpy>
  de.inum = inum;
    8000458c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004590:	4741                	li	a4,16
    80004592:	86a6                	mv	a3,s1
    80004594:	fc040613          	addi	a2,s0,-64
    80004598:	4581                	li	a1,0
    8000459a:	854a                	mv	a0,s2
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	c44080e7          	jalr	-956(ra) # 800041e0 <writei>
    800045a4:	872a                	mv	a4,a0
    800045a6:	47c1                	li	a5,16
  return 0;
    800045a8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045aa:	02f71863          	bne	a4,a5,800045da <dirlink+0xb2>
}
    800045ae:	70e2                	ld	ra,56(sp)
    800045b0:	7442                	ld	s0,48(sp)
    800045b2:	74a2                	ld	s1,40(sp)
    800045b4:	7902                	ld	s2,32(sp)
    800045b6:	69e2                	ld	s3,24(sp)
    800045b8:	6a42                	ld	s4,16(sp)
    800045ba:	6121                	addi	sp,sp,64
    800045bc:	8082                	ret
    iput(ip);
    800045be:	00000097          	auipc	ra,0x0
    800045c2:	a30080e7          	jalr	-1488(ra) # 80003fee <iput>
    return -1;
    800045c6:	557d                	li	a0,-1
    800045c8:	b7dd                	j	800045ae <dirlink+0x86>
      panic("dirlink read");
    800045ca:	00004517          	auipc	a0,0x4
    800045ce:	0f650513          	addi	a0,a0,246 # 800086c0 <syscalls+0x1e0>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>
    panic("dirlink");
    800045da:	00004517          	auipc	a0,0x4
    800045de:	1f650513          	addi	a0,a0,502 # 800087d0 <syscalls+0x2f0>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	f5c080e7          	jalr	-164(ra) # 8000053e <panic>

00000000800045ea <namei>:

struct inode*
namei(char *path)
{
    800045ea:	1101                	addi	sp,sp,-32
    800045ec:	ec06                	sd	ra,24(sp)
    800045ee:	e822                	sd	s0,16(sp)
    800045f0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045f2:	fe040613          	addi	a2,s0,-32
    800045f6:	4581                	li	a1,0
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	dd0080e7          	jalr	-560(ra) # 800043c8 <namex>
}
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	6105                	addi	sp,sp,32
    80004606:	8082                	ret

0000000080004608 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004608:	1141                	addi	sp,sp,-16
    8000460a:	e406                	sd	ra,8(sp)
    8000460c:	e022                	sd	s0,0(sp)
    8000460e:	0800                	addi	s0,sp,16
    80004610:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004612:	4585                	li	a1,1
    80004614:	00000097          	auipc	ra,0x0
    80004618:	db4080e7          	jalr	-588(ra) # 800043c8 <namex>
}
    8000461c:	60a2                	ld	ra,8(sp)
    8000461e:	6402                	ld	s0,0(sp)
    80004620:	0141                	addi	sp,sp,16
    80004622:	8082                	ret

0000000080004624 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	e04a                	sd	s2,0(sp)
    8000462e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004630:	0001d917          	auipc	s2,0x1d
    80004634:	5e890913          	addi	s2,s2,1512 # 80021c18 <log>
    80004638:	01892583          	lw	a1,24(s2)
    8000463c:	02892503          	lw	a0,40(s2)
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	ff2080e7          	jalr	-14(ra) # 80003632 <bread>
    80004648:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000464a:	02c92683          	lw	a3,44(s2)
    8000464e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004650:	02d05763          	blez	a3,8000467e <write_head+0x5a>
    80004654:	0001d797          	auipc	a5,0x1d
    80004658:	5f478793          	addi	a5,a5,1524 # 80021c48 <log+0x30>
    8000465c:	05c50713          	addi	a4,a0,92
    80004660:	36fd                	addiw	a3,a3,-1
    80004662:	1682                	slli	a3,a3,0x20
    80004664:	9281                	srli	a3,a3,0x20
    80004666:	068a                	slli	a3,a3,0x2
    80004668:	0001d617          	auipc	a2,0x1d
    8000466c:	5e460613          	addi	a2,a2,1508 # 80021c4c <log+0x34>
    80004670:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004672:	4390                	lw	a2,0(a5)
    80004674:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004676:	0791                	addi	a5,a5,4
    80004678:	0711                	addi	a4,a4,4
    8000467a:	fed79ce3          	bne	a5,a3,80004672 <write_head+0x4e>
  }
  bwrite(buf);
    8000467e:	8526                	mv	a0,s1
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	0a4080e7          	jalr	164(ra) # 80003724 <bwrite>
  brelse(buf);
    80004688:	8526                	mv	a0,s1
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	0d8080e7          	jalr	216(ra) # 80003762 <brelse>
}
    80004692:	60e2                	ld	ra,24(sp)
    80004694:	6442                	ld	s0,16(sp)
    80004696:	64a2                	ld	s1,8(sp)
    80004698:	6902                	ld	s2,0(sp)
    8000469a:	6105                	addi	sp,sp,32
    8000469c:	8082                	ret

000000008000469e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469e:	0001d797          	auipc	a5,0x1d
    800046a2:	5a67a783          	lw	a5,1446(a5) # 80021c44 <log+0x2c>
    800046a6:	0af05d63          	blez	a5,80004760 <install_trans+0xc2>
{
    800046aa:	7139                	addi	sp,sp,-64
    800046ac:	fc06                	sd	ra,56(sp)
    800046ae:	f822                	sd	s0,48(sp)
    800046b0:	f426                	sd	s1,40(sp)
    800046b2:	f04a                	sd	s2,32(sp)
    800046b4:	ec4e                	sd	s3,24(sp)
    800046b6:	e852                	sd	s4,16(sp)
    800046b8:	e456                	sd	s5,8(sp)
    800046ba:	e05a                	sd	s6,0(sp)
    800046bc:	0080                	addi	s0,sp,64
    800046be:	8b2a                	mv	s6,a0
    800046c0:	0001da97          	auipc	s5,0x1d
    800046c4:	588a8a93          	addi	s5,s5,1416 # 80021c48 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046c8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046ca:	0001d997          	auipc	s3,0x1d
    800046ce:	54e98993          	addi	s3,s3,1358 # 80021c18 <log>
    800046d2:	a035                	j	800046fe <install_trans+0x60>
      bunpin(dbuf);
    800046d4:	8526                	mv	a0,s1
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	166080e7          	jalr	358(ra) # 8000383c <bunpin>
    brelse(lbuf);
    800046de:	854a                	mv	a0,s2
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	082080e7          	jalr	130(ra) # 80003762 <brelse>
    brelse(dbuf);
    800046e8:	8526                	mv	a0,s1
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	078080e7          	jalr	120(ra) # 80003762 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f2:	2a05                	addiw	s4,s4,1
    800046f4:	0a91                	addi	s5,s5,4
    800046f6:	02c9a783          	lw	a5,44(s3)
    800046fa:	04fa5963          	bge	s4,a5,8000474c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046fe:	0189a583          	lw	a1,24(s3)
    80004702:	014585bb          	addw	a1,a1,s4
    80004706:	2585                	addiw	a1,a1,1
    80004708:	0289a503          	lw	a0,40(s3)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	f26080e7          	jalr	-218(ra) # 80003632 <bread>
    80004714:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004716:	000aa583          	lw	a1,0(s5)
    8000471a:	0289a503          	lw	a0,40(s3)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	f14080e7          	jalr	-236(ra) # 80003632 <bread>
    80004726:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004728:	40000613          	li	a2,1024
    8000472c:	05890593          	addi	a1,s2,88
    80004730:	05850513          	addi	a0,a0,88
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	630080e7          	jalr	1584(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000473c:	8526                	mv	a0,s1
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	fe6080e7          	jalr	-26(ra) # 80003724 <bwrite>
    if(recovering == 0)
    80004746:	f80b1ce3          	bnez	s6,800046de <install_trans+0x40>
    8000474a:	b769                	j	800046d4 <install_trans+0x36>
}
    8000474c:	70e2                	ld	ra,56(sp)
    8000474e:	7442                	ld	s0,48(sp)
    80004750:	74a2                	ld	s1,40(sp)
    80004752:	7902                	ld	s2,32(sp)
    80004754:	69e2                	ld	s3,24(sp)
    80004756:	6a42                	ld	s4,16(sp)
    80004758:	6aa2                	ld	s5,8(sp)
    8000475a:	6b02                	ld	s6,0(sp)
    8000475c:	6121                	addi	sp,sp,64
    8000475e:	8082                	ret
    80004760:	8082                	ret

0000000080004762 <initlog>:
{
    80004762:	7179                	addi	sp,sp,-48
    80004764:	f406                	sd	ra,40(sp)
    80004766:	f022                	sd	s0,32(sp)
    80004768:	ec26                	sd	s1,24(sp)
    8000476a:	e84a                	sd	s2,16(sp)
    8000476c:	e44e                	sd	s3,8(sp)
    8000476e:	1800                	addi	s0,sp,48
    80004770:	892a                	mv	s2,a0
    80004772:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004774:	0001d497          	auipc	s1,0x1d
    80004778:	4a448493          	addi	s1,s1,1188 # 80021c18 <log>
    8000477c:	00004597          	auipc	a1,0x4
    80004780:	f5458593          	addi	a1,a1,-172 # 800086d0 <syscalls+0x1f0>
    80004784:	8526                	mv	a0,s1
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	3ce080e7          	jalr	974(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000478e:	0149a583          	lw	a1,20(s3)
    80004792:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004794:	0109a783          	lw	a5,16(s3)
    80004798:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000479a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000479e:	854a                	mv	a0,s2
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	e92080e7          	jalr	-366(ra) # 80003632 <bread>
  log.lh.n = lh->n;
    800047a8:	4d3c                	lw	a5,88(a0)
    800047aa:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047ac:	02f05563          	blez	a5,800047d6 <initlog+0x74>
    800047b0:	05c50713          	addi	a4,a0,92
    800047b4:	0001d697          	auipc	a3,0x1d
    800047b8:	49468693          	addi	a3,a3,1172 # 80021c48 <log+0x30>
    800047bc:	37fd                	addiw	a5,a5,-1
    800047be:	1782                	slli	a5,a5,0x20
    800047c0:	9381                	srli	a5,a5,0x20
    800047c2:	078a                	slli	a5,a5,0x2
    800047c4:	06050613          	addi	a2,a0,96
    800047c8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047ca:	4310                	lw	a2,0(a4)
    800047cc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047ce:	0711                	addi	a4,a4,4
    800047d0:	0691                	addi	a3,a3,4
    800047d2:	fef71ce3          	bne	a4,a5,800047ca <initlog+0x68>
  brelse(buf);
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	f8c080e7          	jalr	-116(ra) # 80003762 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047de:	4505                	li	a0,1
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	ebe080e7          	jalr	-322(ra) # 8000469e <install_trans>
  log.lh.n = 0;
    800047e8:	0001d797          	auipc	a5,0x1d
    800047ec:	4407ae23          	sw	zero,1116(a5) # 80021c44 <log+0x2c>
  write_head(); // clear the log
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	e34080e7          	jalr	-460(ra) # 80004624 <write_head>
}
    800047f8:	70a2                	ld	ra,40(sp)
    800047fa:	7402                	ld	s0,32(sp)
    800047fc:	64e2                	ld	s1,24(sp)
    800047fe:	6942                	ld	s2,16(sp)
    80004800:	69a2                	ld	s3,8(sp)
    80004802:	6145                	addi	sp,sp,48
    80004804:	8082                	ret

0000000080004806 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004806:	1101                	addi	sp,sp,-32
    80004808:	ec06                	sd	ra,24(sp)
    8000480a:	e822                	sd	s0,16(sp)
    8000480c:	e426                	sd	s1,8(sp)
    8000480e:	e04a                	sd	s2,0(sp)
    80004810:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004812:	0001d517          	auipc	a0,0x1d
    80004816:	40650513          	addi	a0,a0,1030 # 80021c18 <log>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	3ca080e7          	jalr	970(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004822:	0001d497          	auipc	s1,0x1d
    80004826:	3f648493          	addi	s1,s1,1014 # 80021c18 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000482a:	4979                	li	s2,30
    8000482c:	a039                	j	8000483a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000482e:	85a6                	mv	a1,s1
    80004830:	8526                	mv	a0,s1
    80004832:	ffffe097          	auipc	ra,0xffffe
    80004836:	e6c080e7          	jalr	-404(ra) # 8000269e <sleep>
    if(log.committing){
    8000483a:	50dc                	lw	a5,36(s1)
    8000483c:	fbed                	bnez	a5,8000482e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000483e:	509c                	lw	a5,32(s1)
    80004840:	0017871b          	addiw	a4,a5,1
    80004844:	0007069b          	sext.w	a3,a4
    80004848:	0027179b          	slliw	a5,a4,0x2
    8000484c:	9fb9                	addw	a5,a5,a4
    8000484e:	0017979b          	slliw	a5,a5,0x1
    80004852:	54d8                	lw	a4,44(s1)
    80004854:	9fb9                	addw	a5,a5,a4
    80004856:	00f95963          	bge	s2,a5,80004868 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000485a:	85a6                	mv	a1,s1
    8000485c:	8526                	mv	a0,s1
    8000485e:	ffffe097          	auipc	ra,0xffffe
    80004862:	e40080e7          	jalr	-448(ra) # 8000269e <sleep>
    80004866:	bfd1                	j	8000483a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004868:	0001d517          	auipc	a0,0x1d
    8000486c:	3b050513          	addi	a0,a0,944 # 80021c18 <log>
    80004870:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	438080e7          	jalr	1080(ra) # 80000caa <release>
      break;
    }
  }
}
    8000487a:	60e2                	ld	ra,24(sp)
    8000487c:	6442                	ld	s0,16(sp)
    8000487e:	64a2                	ld	s1,8(sp)
    80004880:	6902                	ld	s2,0(sp)
    80004882:	6105                	addi	sp,sp,32
    80004884:	8082                	ret

0000000080004886 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004886:	7139                	addi	sp,sp,-64
    80004888:	fc06                	sd	ra,56(sp)
    8000488a:	f822                	sd	s0,48(sp)
    8000488c:	f426                	sd	s1,40(sp)
    8000488e:	f04a                	sd	s2,32(sp)
    80004890:	ec4e                	sd	s3,24(sp)
    80004892:	e852                	sd	s4,16(sp)
    80004894:	e456                	sd	s5,8(sp)
    80004896:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004898:	0001d497          	auipc	s1,0x1d
    8000489c:	38048493          	addi	s1,s1,896 # 80021c18 <log>
    800048a0:	8526                	mv	a0,s1
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	342080e7          	jalr	834(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800048aa:	509c                	lw	a5,32(s1)
    800048ac:	37fd                	addiw	a5,a5,-1
    800048ae:	0007891b          	sext.w	s2,a5
    800048b2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048b4:	50dc                	lw	a5,36(s1)
    800048b6:	efb9                	bnez	a5,80004914 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048b8:	06091663          	bnez	s2,80004924 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800048bc:	0001d497          	auipc	s1,0x1d
    800048c0:	35c48493          	addi	s1,s1,860 # 80021c18 <log>
    800048c4:	4785                	li	a5,1
    800048c6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048c8:	8526                	mv	a0,s1
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	3e0080e7          	jalr	992(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048d2:	54dc                	lw	a5,44(s1)
    800048d4:	06f04763          	bgtz	a5,80004942 <end_op+0xbc>
    acquire(&log.lock);
    800048d8:	0001d497          	auipc	s1,0x1d
    800048dc:	34048493          	addi	s1,s1,832 # 80021c18 <log>
    800048e0:	8526                	mv	a0,s1
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	302080e7          	jalr	770(ra) # 80000be4 <acquire>
    log.committing = 0;
    800048ea:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048ee:	8526                	mv	a0,s1
    800048f0:	ffffe097          	auipc	ra,0xffffe
    800048f4:	f56080e7          	jalr	-170(ra) # 80002846 <wakeup>
    release(&log.lock);
    800048f8:	8526                	mv	a0,s1
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	3b0080e7          	jalr	944(ra) # 80000caa <release>
}
    80004902:	70e2                	ld	ra,56(sp)
    80004904:	7442                	ld	s0,48(sp)
    80004906:	74a2                	ld	s1,40(sp)
    80004908:	7902                	ld	s2,32(sp)
    8000490a:	69e2                	ld	s3,24(sp)
    8000490c:	6a42                	ld	s4,16(sp)
    8000490e:	6aa2                	ld	s5,8(sp)
    80004910:	6121                	addi	sp,sp,64
    80004912:	8082                	ret
    panic("log.committing");
    80004914:	00004517          	auipc	a0,0x4
    80004918:	dc450513          	addi	a0,a0,-572 # 800086d8 <syscalls+0x1f8>
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	c22080e7          	jalr	-990(ra) # 8000053e <panic>
    wakeup(&log);
    80004924:	0001d497          	auipc	s1,0x1d
    80004928:	2f448493          	addi	s1,s1,756 # 80021c18 <log>
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffe097          	auipc	ra,0xffffe
    80004932:	f18080e7          	jalr	-232(ra) # 80002846 <wakeup>
  release(&log.lock);
    80004936:	8526                	mv	a0,s1
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	372080e7          	jalr	882(ra) # 80000caa <release>
  if(do_commit){
    80004940:	b7c9                	j	80004902 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004942:	0001da97          	auipc	s5,0x1d
    80004946:	306a8a93          	addi	s5,s5,774 # 80021c48 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000494a:	0001da17          	auipc	s4,0x1d
    8000494e:	2cea0a13          	addi	s4,s4,718 # 80021c18 <log>
    80004952:	018a2583          	lw	a1,24(s4)
    80004956:	012585bb          	addw	a1,a1,s2
    8000495a:	2585                	addiw	a1,a1,1
    8000495c:	028a2503          	lw	a0,40(s4)
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	cd2080e7          	jalr	-814(ra) # 80003632 <bread>
    80004968:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000496a:	000aa583          	lw	a1,0(s5)
    8000496e:	028a2503          	lw	a0,40(s4)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	cc0080e7          	jalr	-832(ra) # 80003632 <bread>
    8000497a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000497c:	40000613          	li	a2,1024
    80004980:	05850593          	addi	a1,a0,88
    80004984:	05848513          	addi	a0,s1,88
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	3dc080e7          	jalr	988(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    80004990:	8526                	mv	a0,s1
    80004992:	fffff097          	auipc	ra,0xfffff
    80004996:	d92080e7          	jalr	-622(ra) # 80003724 <bwrite>
    brelse(from);
    8000499a:	854e                	mv	a0,s3
    8000499c:	fffff097          	auipc	ra,0xfffff
    800049a0:	dc6080e7          	jalr	-570(ra) # 80003762 <brelse>
    brelse(to);
    800049a4:	8526                	mv	a0,s1
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	dbc080e7          	jalr	-580(ra) # 80003762 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049ae:	2905                	addiw	s2,s2,1
    800049b0:	0a91                	addi	s5,s5,4
    800049b2:	02ca2783          	lw	a5,44(s4)
    800049b6:	f8f94ee3          	blt	s2,a5,80004952 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049ba:	00000097          	auipc	ra,0x0
    800049be:	c6a080e7          	jalr	-918(ra) # 80004624 <write_head>
    install_trans(0); // Now install writes to home locations
    800049c2:	4501                	li	a0,0
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	cda080e7          	jalr	-806(ra) # 8000469e <install_trans>
    log.lh.n = 0;
    800049cc:	0001d797          	auipc	a5,0x1d
    800049d0:	2607ac23          	sw	zero,632(a5) # 80021c44 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	c50080e7          	jalr	-944(ra) # 80004624 <write_head>
    800049dc:	bdf5                	j	800048d8 <end_op+0x52>

00000000800049de <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049de:	1101                	addi	sp,sp,-32
    800049e0:	ec06                	sd	ra,24(sp)
    800049e2:	e822                	sd	s0,16(sp)
    800049e4:	e426                	sd	s1,8(sp)
    800049e6:	e04a                	sd	s2,0(sp)
    800049e8:	1000                	addi	s0,sp,32
    800049ea:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049ec:	0001d917          	auipc	s2,0x1d
    800049f0:	22c90913          	addi	s2,s2,556 # 80021c18 <log>
    800049f4:	854a                	mv	a0,s2
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	1ee080e7          	jalr	494(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049fe:	02c92603          	lw	a2,44(s2)
    80004a02:	47f5                	li	a5,29
    80004a04:	06c7c563          	blt	a5,a2,80004a6e <log_write+0x90>
    80004a08:	0001d797          	auipc	a5,0x1d
    80004a0c:	22c7a783          	lw	a5,556(a5) # 80021c34 <log+0x1c>
    80004a10:	37fd                	addiw	a5,a5,-1
    80004a12:	04f65e63          	bge	a2,a5,80004a6e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a16:	0001d797          	auipc	a5,0x1d
    80004a1a:	2227a783          	lw	a5,546(a5) # 80021c38 <log+0x20>
    80004a1e:	06f05063          	blez	a5,80004a7e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a22:	4781                	li	a5,0
    80004a24:	06c05563          	blez	a2,80004a8e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a28:	44cc                	lw	a1,12(s1)
    80004a2a:	0001d717          	auipc	a4,0x1d
    80004a2e:	21e70713          	addi	a4,a4,542 # 80021c48 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a32:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a34:	4314                	lw	a3,0(a4)
    80004a36:	04b68c63          	beq	a3,a1,80004a8e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a3a:	2785                	addiw	a5,a5,1
    80004a3c:	0711                	addi	a4,a4,4
    80004a3e:	fef61be3          	bne	a2,a5,80004a34 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a42:	0621                	addi	a2,a2,8
    80004a44:	060a                	slli	a2,a2,0x2
    80004a46:	0001d797          	auipc	a5,0x1d
    80004a4a:	1d278793          	addi	a5,a5,466 # 80021c18 <log>
    80004a4e:	963e                	add	a2,a2,a5
    80004a50:	44dc                	lw	a5,12(s1)
    80004a52:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a54:	8526                	mv	a0,s1
    80004a56:	fffff097          	auipc	ra,0xfffff
    80004a5a:	daa080e7          	jalr	-598(ra) # 80003800 <bpin>
    log.lh.n++;
    80004a5e:	0001d717          	auipc	a4,0x1d
    80004a62:	1ba70713          	addi	a4,a4,442 # 80021c18 <log>
    80004a66:	575c                	lw	a5,44(a4)
    80004a68:	2785                	addiw	a5,a5,1
    80004a6a:	d75c                	sw	a5,44(a4)
    80004a6c:	a835                	j	80004aa8 <log_write+0xca>
    panic("too big a transaction");
    80004a6e:	00004517          	auipc	a0,0x4
    80004a72:	c7a50513          	addi	a0,a0,-902 # 800086e8 <syscalls+0x208>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	ac8080e7          	jalr	-1336(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a7e:	00004517          	auipc	a0,0x4
    80004a82:	c8250513          	addi	a0,a0,-894 # 80008700 <syscalls+0x220>
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	ab8080e7          	jalr	-1352(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a8e:	00878713          	addi	a4,a5,8
    80004a92:	00271693          	slli	a3,a4,0x2
    80004a96:	0001d717          	auipc	a4,0x1d
    80004a9a:	18270713          	addi	a4,a4,386 # 80021c18 <log>
    80004a9e:	9736                	add	a4,a4,a3
    80004aa0:	44d4                	lw	a3,12(s1)
    80004aa2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004aa4:	faf608e3          	beq	a2,a5,80004a54 <log_write+0x76>
  }
  release(&log.lock);
    80004aa8:	0001d517          	auipc	a0,0x1d
    80004aac:	17050513          	addi	a0,a0,368 # 80021c18 <log>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1fa080e7          	jalr	506(ra) # 80000caa <release>
}
    80004ab8:	60e2                	ld	ra,24(sp)
    80004aba:	6442                	ld	s0,16(sp)
    80004abc:	64a2                	ld	s1,8(sp)
    80004abe:	6902                	ld	s2,0(sp)
    80004ac0:	6105                	addi	sp,sp,32
    80004ac2:	8082                	ret

0000000080004ac4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ac4:	1101                	addi	sp,sp,-32
    80004ac6:	ec06                	sd	ra,24(sp)
    80004ac8:	e822                	sd	s0,16(sp)
    80004aca:	e426                	sd	s1,8(sp)
    80004acc:	e04a                	sd	s2,0(sp)
    80004ace:	1000                	addi	s0,sp,32
    80004ad0:	84aa                	mv	s1,a0
    80004ad2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ad4:	00004597          	auipc	a1,0x4
    80004ad8:	c4c58593          	addi	a1,a1,-948 # 80008720 <syscalls+0x240>
    80004adc:	0521                	addi	a0,a0,8
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	076080e7          	jalr	118(ra) # 80000b54 <initlock>
  lk->name = name;
    80004ae6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004aea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aee:	0204a423          	sw	zero,40(s1)
}
    80004af2:	60e2                	ld	ra,24(sp)
    80004af4:	6442                	ld	s0,16(sp)
    80004af6:	64a2                	ld	s1,8(sp)
    80004af8:	6902                	ld	s2,0(sp)
    80004afa:	6105                	addi	sp,sp,32
    80004afc:	8082                	ret

0000000080004afe <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004afe:	1101                	addi	sp,sp,-32
    80004b00:	ec06                	sd	ra,24(sp)
    80004b02:	e822                	sd	s0,16(sp)
    80004b04:	e426                	sd	s1,8(sp)
    80004b06:	e04a                	sd	s2,0(sp)
    80004b08:	1000                	addi	s0,sp,32
    80004b0a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b0c:	00850913          	addi	s2,a0,8
    80004b10:	854a                	mv	a0,s2
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	0d2080e7          	jalr	210(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004b1a:	409c                	lw	a5,0(s1)
    80004b1c:	cb89                	beqz	a5,80004b2e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b1e:	85ca                	mv	a1,s2
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffe097          	auipc	ra,0xffffe
    80004b26:	b7c080e7          	jalr	-1156(ra) # 8000269e <sleep>
  while (lk->locked) {
    80004b2a:	409c                	lw	a5,0(s1)
    80004b2c:	fbed                	bnez	a5,80004b1e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b2e:	4785                	li	a5,1
    80004b30:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b32:	ffffd097          	auipc	ra,0xffffd
    80004b36:	2aa080e7          	jalr	682(ra) # 80001ddc <myproc>
    80004b3a:	591c                	lw	a5,48(a0)
    80004b3c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b3e:	854a                	mv	a0,s2
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	16a080e7          	jalr	362(ra) # 80000caa <release>
}
    80004b48:	60e2                	ld	ra,24(sp)
    80004b4a:	6442                	ld	s0,16(sp)
    80004b4c:	64a2                	ld	s1,8(sp)
    80004b4e:	6902                	ld	s2,0(sp)
    80004b50:	6105                	addi	sp,sp,32
    80004b52:	8082                	ret

0000000080004b54 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b54:	1101                	addi	sp,sp,-32
    80004b56:	ec06                	sd	ra,24(sp)
    80004b58:	e822                	sd	s0,16(sp)
    80004b5a:	e426                	sd	s1,8(sp)
    80004b5c:	e04a                	sd	s2,0(sp)
    80004b5e:	1000                	addi	s0,sp,32
    80004b60:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b62:	00850913          	addi	s2,a0,8
    80004b66:	854a                	mv	a0,s2
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	07c080e7          	jalr	124(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b70:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b74:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b78:	8526                	mv	a0,s1
    80004b7a:	ffffe097          	auipc	ra,0xffffe
    80004b7e:	ccc080e7          	jalr	-820(ra) # 80002846 <wakeup>
  release(&lk->lk);
    80004b82:	854a                	mv	a0,s2
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	126080e7          	jalr	294(ra) # 80000caa <release>
}
    80004b8c:	60e2                	ld	ra,24(sp)
    80004b8e:	6442                	ld	s0,16(sp)
    80004b90:	64a2                	ld	s1,8(sp)
    80004b92:	6902                	ld	s2,0(sp)
    80004b94:	6105                	addi	sp,sp,32
    80004b96:	8082                	ret

0000000080004b98 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b98:	7179                	addi	sp,sp,-48
    80004b9a:	f406                	sd	ra,40(sp)
    80004b9c:	f022                	sd	s0,32(sp)
    80004b9e:	ec26                	sd	s1,24(sp)
    80004ba0:	e84a                	sd	s2,16(sp)
    80004ba2:	e44e                	sd	s3,8(sp)
    80004ba4:	1800                	addi	s0,sp,48
    80004ba6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ba8:	00850913          	addi	s2,a0,8
    80004bac:	854a                	mv	a0,s2
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	036080e7          	jalr	54(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bb6:	409c                	lw	a5,0(s1)
    80004bb8:	ef99                	bnez	a5,80004bd6 <holdingsleep+0x3e>
    80004bba:	4481                	li	s1,0
  release(&lk->lk);
    80004bbc:	854a                	mv	a0,s2
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	0ec080e7          	jalr	236(ra) # 80000caa <release>
  return r;
}
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	70a2                	ld	ra,40(sp)
    80004bca:	7402                	ld	s0,32(sp)
    80004bcc:	64e2                	ld	s1,24(sp)
    80004bce:	6942                	ld	s2,16(sp)
    80004bd0:	69a2                	ld	s3,8(sp)
    80004bd2:	6145                	addi	sp,sp,48
    80004bd4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bd6:	0284a983          	lw	s3,40(s1)
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	202080e7          	jalr	514(ra) # 80001ddc <myproc>
    80004be2:	5904                	lw	s1,48(a0)
    80004be4:	413484b3          	sub	s1,s1,s3
    80004be8:	0014b493          	seqz	s1,s1
    80004bec:	bfc1                	j	80004bbc <holdingsleep+0x24>

0000000080004bee <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bee:	1141                	addi	sp,sp,-16
    80004bf0:	e406                	sd	ra,8(sp)
    80004bf2:	e022                	sd	s0,0(sp)
    80004bf4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bf6:	00004597          	auipc	a1,0x4
    80004bfa:	b3a58593          	addi	a1,a1,-1222 # 80008730 <syscalls+0x250>
    80004bfe:	0001d517          	auipc	a0,0x1d
    80004c02:	16250513          	addi	a0,a0,354 # 80021d60 <ftable>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	f4e080e7          	jalr	-178(ra) # 80000b54 <initlock>
}
    80004c0e:	60a2                	ld	ra,8(sp)
    80004c10:	6402                	ld	s0,0(sp)
    80004c12:	0141                	addi	sp,sp,16
    80004c14:	8082                	ret

0000000080004c16 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c16:	1101                	addi	sp,sp,-32
    80004c18:	ec06                	sd	ra,24(sp)
    80004c1a:	e822                	sd	s0,16(sp)
    80004c1c:	e426                	sd	s1,8(sp)
    80004c1e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c20:	0001d517          	auipc	a0,0x1d
    80004c24:	14050513          	addi	a0,a0,320 # 80021d60 <ftable>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	fbc080e7          	jalr	-68(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c30:	0001d497          	auipc	s1,0x1d
    80004c34:	14848493          	addi	s1,s1,328 # 80021d78 <ftable+0x18>
    80004c38:	0001e717          	auipc	a4,0x1e
    80004c3c:	0e070713          	addi	a4,a4,224 # 80022d18 <ftable+0xfb8>
    if(f->ref == 0){
    80004c40:	40dc                	lw	a5,4(s1)
    80004c42:	cf99                	beqz	a5,80004c60 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c44:	02848493          	addi	s1,s1,40
    80004c48:	fee49ce3          	bne	s1,a4,80004c40 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c4c:	0001d517          	auipc	a0,0x1d
    80004c50:	11450513          	addi	a0,a0,276 # 80021d60 <ftable>
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	056080e7          	jalr	86(ra) # 80000caa <release>
  return 0;
    80004c5c:	4481                	li	s1,0
    80004c5e:	a819                	j	80004c74 <filealloc+0x5e>
      f->ref = 1;
    80004c60:	4785                	li	a5,1
    80004c62:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c64:	0001d517          	auipc	a0,0x1d
    80004c68:	0fc50513          	addi	a0,a0,252 # 80021d60 <ftable>
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	03e080e7          	jalr	62(ra) # 80000caa <release>
}
    80004c74:	8526                	mv	a0,s1
    80004c76:	60e2                	ld	ra,24(sp)
    80004c78:	6442                	ld	s0,16(sp)
    80004c7a:	64a2                	ld	s1,8(sp)
    80004c7c:	6105                	addi	sp,sp,32
    80004c7e:	8082                	ret

0000000080004c80 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c80:	1101                	addi	sp,sp,-32
    80004c82:	ec06                	sd	ra,24(sp)
    80004c84:	e822                	sd	s0,16(sp)
    80004c86:	e426                	sd	s1,8(sp)
    80004c88:	1000                	addi	s0,sp,32
    80004c8a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c8c:	0001d517          	auipc	a0,0x1d
    80004c90:	0d450513          	addi	a0,a0,212 # 80021d60 <ftable>
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	f50080e7          	jalr	-176(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c9c:	40dc                	lw	a5,4(s1)
    80004c9e:	02f05263          	blez	a5,80004cc2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ca2:	2785                	addiw	a5,a5,1
    80004ca4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ca6:	0001d517          	auipc	a0,0x1d
    80004caa:	0ba50513          	addi	a0,a0,186 # 80021d60 <ftable>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	ffc080e7          	jalr	-4(ra) # 80000caa <release>
  return f;
}
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	60e2                	ld	ra,24(sp)
    80004cba:	6442                	ld	s0,16(sp)
    80004cbc:	64a2                	ld	s1,8(sp)
    80004cbe:	6105                	addi	sp,sp,32
    80004cc0:	8082                	ret
    panic("filedup");
    80004cc2:	00004517          	auipc	a0,0x4
    80004cc6:	a7650513          	addi	a0,a0,-1418 # 80008738 <syscalls+0x258>
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080004cd2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cd2:	7139                	addi	sp,sp,-64
    80004cd4:	fc06                	sd	ra,56(sp)
    80004cd6:	f822                	sd	s0,48(sp)
    80004cd8:	f426                	sd	s1,40(sp)
    80004cda:	f04a                	sd	s2,32(sp)
    80004cdc:	ec4e                	sd	s3,24(sp)
    80004cde:	e852                	sd	s4,16(sp)
    80004ce0:	e456                	sd	s5,8(sp)
    80004ce2:	0080                	addi	s0,sp,64
    80004ce4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ce6:	0001d517          	auipc	a0,0x1d
    80004cea:	07a50513          	addi	a0,a0,122 # 80021d60 <ftable>
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	ef6080e7          	jalr	-266(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cf6:	40dc                	lw	a5,4(s1)
    80004cf8:	06f05163          	blez	a5,80004d5a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cfc:	37fd                	addiw	a5,a5,-1
    80004cfe:	0007871b          	sext.w	a4,a5
    80004d02:	c0dc                	sw	a5,4(s1)
    80004d04:	06e04363          	bgtz	a4,80004d6a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d08:	0004a903          	lw	s2,0(s1)
    80004d0c:	0094ca83          	lbu	s5,9(s1)
    80004d10:	0104ba03          	ld	s4,16(s1)
    80004d14:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d18:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d1c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d20:	0001d517          	auipc	a0,0x1d
    80004d24:	04050513          	addi	a0,a0,64 # 80021d60 <ftable>
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	f82080e7          	jalr	-126(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004d30:	4785                	li	a5,1
    80004d32:	04f90d63          	beq	s2,a5,80004d8c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d36:	3979                	addiw	s2,s2,-2
    80004d38:	4785                	li	a5,1
    80004d3a:	0527e063          	bltu	a5,s2,80004d7a <fileclose+0xa8>
    begin_op();
    80004d3e:	00000097          	auipc	ra,0x0
    80004d42:	ac8080e7          	jalr	-1336(ra) # 80004806 <begin_op>
    iput(ff.ip);
    80004d46:	854e                	mv	a0,s3
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	2a6080e7          	jalr	678(ra) # 80003fee <iput>
    end_op();
    80004d50:	00000097          	auipc	ra,0x0
    80004d54:	b36080e7          	jalr	-1226(ra) # 80004886 <end_op>
    80004d58:	a00d                	j	80004d7a <fileclose+0xa8>
    panic("fileclose");
    80004d5a:	00004517          	auipc	a0,0x4
    80004d5e:	9e650513          	addi	a0,a0,-1562 # 80008740 <syscalls+0x260>
    80004d62:	ffffb097          	auipc	ra,0xffffb
    80004d66:	7dc080e7          	jalr	2012(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d6a:	0001d517          	auipc	a0,0x1d
    80004d6e:	ff650513          	addi	a0,a0,-10 # 80021d60 <ftable>
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	f38080e7          	jalr	-200(ra) # 80000caa <release>
  }
}
    80004d7a:	70e2                	ld	ra,56(sp)
    80004d7c:	7442                	ld	s0,48(sp)
    80004d7e:	74a2                	ld	s1,40(sp)
    80004d80:	7902                	ld	s2,32(sp)
    80004d82:	69e2                	ld	s3,24(sp)
    80004d84:	6a42                	ld	s4,16(sp)
    80004d86:	6aa2                	ld	s5,8(sp)
    80004d88:	6121                	addi	sp,sp,64
    80004d8a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d8c:	85d6                	mv	a1,s5
    80004d8e:	8552                	mv	a0,s4
    80004d90:	00000097          	auipc	ra,0x0
    80004d94:	34c080e7          	jalr	844(ra) # 800050dc <pipeclose>
    80004d98:	b7cd                	j	80004d7a <fileclose+0xa8>

0000000080004d9a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d9a:	715d                	addi	sp,sp,-80
    80004d9c:	e486                	sd	ra,72(sp)
    80004d9e:	e0a2                	sd	s0,64(sp)
    80004da0:	fc26                	sd	s1,56(sp)
    80004da2:	f84a                	sd	s2,48(sp)
    80004da4:	f44e                	sd	s3,40(sp)
    80004da6:	0880                	addi	s0,sp,80
    80004da8:	84aa                	mv	s1,a0
    80004daa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	030080e7          	jalr	48(ra) # 80001ddc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004db4:	409c                	lw	a5,0(s1)
    80004db6:	37f9                	addiw	a5,a5,-2
    80004db8:	4705                	li	a4,1
    80004dba:	04f76763          	bltu	a4,a5,80004e08 <filestat+0x6e>
    80004dbe:	892a                	mv	s2,a0
    ilock(f->ip);
    80004dc0:	6c88                	ld	a0,24(s1)
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	072080e7          	jalr	114(ra) # 80003e34 <ilock>
    stati(f->ip, &st);
    80004dca:	fb840593          	addi	a1,s0,-72
    80004dce:	6c88                	ld	a0,24(s1)
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	2ee080e7          	jalr	750(ra) # 800040be <stati>
    iunlock(f->ip);
    80004dd8:	6c88                	ld	a0,24(s1)
    80004dda:	fffff097          	auipc	ra,0xfffff
    80004dde:	11c080e7          	jalr	284(ra) # 80003ef6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004de2:	46e1                	li	a3,24
    80004de4:	fb840613          	addi	a2,s0,-72
    80004de8:	85ce                	mv	a1,s3
    80004dea:	07093503          	ld	a0,112(s2)
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	8a8080e7          	jalr	-1880(ra) # 80001696 <copyout>
    80004df6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dfa:	60a6                	ld	ra,72(sp)
    80004dfc:	6406                	ld	s0,64(sp)
    80004dfe:	74e2                	ld	s1,56(sp)
    80004e00:	7942                	ld	s2,48(sp)
    80004e02:	79a2                	ld	s3,40(sp)
    80004e04:	6161                	addi	sp,sp,80
    80004e06:	8082                	ret
  return -1;
    80004e08:	557d                	li	a0,-1
    80004e0a:	bfc5                	j	80004dfa <filestat+0x60>

0000000080004e0c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e0c:	7179                	addi	sp,sp,-48
    80004e0e:	f406                	sd	ra,40(sp)
    80004e10:	f022                	sd	s0,32(sp)
    80004e12:	ec26                	sd	s1,24(sp)
    80004e14:	e84a                	sd	s2,16(sp)
    80004e16:	e44e                	sd	s3,8(sp)
    80004e18:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e1a:	00854783          	lbu	a5,8(a0)
    80004e1e:	c3d5                	beqz	a5,80004ec2 <fileread+0xb6>
    80004e20:	84aa                	mv	s1,a0
    80004e22:	89ae                	mv	s3,a1
    80004e24:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e26:	411c                	lw	a5,0(a0)
    80004e28:	4705                	li	a4,1
    80004e2a:	04e78963          	beq	a5,a4,80004e7c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e2e:	470d                	li	a4,3
    80004e30:	04e78d63          	beq	a5,a4,80004e8a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e34:	4709                	li	a4,2
    80004e36:	06e79e63          	bne	a5,a4,80004eb2 <fileread+0xa6>
    ilock(f->ip);
    80004e3a:	6d08                	ld	a0,24(a0)
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	ff8080e7          	jalr	-8(ra) # 80003e34 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e44:	874a                	mv	a4,s2
    80004e46:	5094                	lw	a3,32(s1)
    80004e48:	864e                	mv	a2,s3
    80004e4a:	4585                	li	a1,1
    80004e4c:	6c88                	ld	a0,24(s1)
    80004e4e:	fffff097          	auipc	ra,0xfffff
    80004e52:	29a080e7          	jalr	666(ra) # 800040e8 <readi>
    80004e56:	892a                	mv	s2,a0
    80004e58:	00a05563          	blez	a0,80004e62 <fileread+0x56>
      f->off += r;
    80004e5c:	509c                	lw	a5,32(s1)
    80004e5e:	9fa9                	addw	a5,a5,a0
    80004e60:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e62:	6c88                	ld	a0,24(s1)
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	092080e7          	jalr	146(ra) # 80003ef6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e6c:	854a                	mv	a0,s2
    80004e6e:	70a2                	ld	ra,40(sp)
    80004e70:	7402                	ld	s0,32(sp)
    80004e72:	64e2                	ld	s1,24(sp)
    80004e74:	6942                	ld	s2,16(sp)
    80004e76:	69a2                	ld	s3,8(sp)
    80004e78:	6145                	addi	sp,sp,48
    80004e7a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e7c:	6908                	ld	a0,16(a0)
    80004e7e:	00000097          	auipc	ra,0x0
    80004e82:	3c8080e7          	jalr	968(ra) # 80005246 <piperead>
    80004e86:	892a                	mv	s2,a0
    80004e88:	b7d5                	j	80004e6c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e8a:	02451783          	lh	a5,36(a0)
    80004e8e:	03079693          	slli	a3,a5,0x30
    80004e92:	92c1                	srli	a3,a3,0x30
    80004e94:	4725                	li	a4,9
    80004e96:	02d76863          	bltu	a4,a3,80004ec6 <fileread+0xba>
    80004e9a:	0792                	slli	a5,a5,0x4
    80004e9c:	0001d717          	auipc	a4,0x1d
    80004ea0:	e2470713          	addi	a4,a4,-476 # 80021cc0 <devsw>
    80004ea4:	97ba                	add	a5,a5,a4
    80004ea6:	639c                	ld	a5,0(a5)
    80004ea8:	c38d                	beqz	a5,80004eca <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004eaa:	4505                	li	a0,1
    80004eac:	9782                	jalr	a5
    80004eae:	892a                	mv	s2,a0
    80004eb0:	bf75                	j	80004e6c <fileread+0x60>
    panic("fileread");
    80004eb2:	00004517          	auipc	a0,0x4
    80004eb6:	89e50513          	addi	a0,a0,-1890 # 80008750 <syscalls+0x270>
    80004eba:	ffffb097          	auipc	ra,0xffffb
    80004ebe:	684080e7          	jalr	1668(ra) # 8000053e <panic>
    return -1;
    80004ec2:	597d                	li	s2,-1
    80004ec4:	b765                	j	80004e6c <fileread+0x60>
      return -1;
    80004ec6:	597d                	li	s2,-1
    80004ec8:	b755                	j	80004e6c <fileread+0x60>
    80004eca:	597d                	li	s2,-1
    80004ecc:	b745                	j	80004e6c <fileread+0x60>

0000000080004ece <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ece:	715d                	addi	sp,sp,-80
    80004ed0:	e486                	sd	ra,72(sp)
    80004ed2:	e0a2                	sd	s0,64(sp)
    80004ed4:	fc26                	sd	s1,56(sp)
    80004ed6:	f84a                	sd	s2,48(sp)
    80004ed8:	f44e                	sd	s3,40(sp)
    80004eda:	f052                	sd	s4,32(sp)
    80004edc:	ec56                	sd	s5,24(sp)
    80004ede:	e85a                	sd	s6,16(sp)
    80004ee0:	e45e                	sd	s7,8(sp)
    80004ee2:	e062                	sd	s8,0(sp)
    80004ee4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ee6:	00954783          	lbu	a5,9(a0)
    80004eea:	10078663          	beqz	a5,80004ff6 <filewrite+0x128>
    80004eee:	892a                	mv	s2,a0
    80004ef0:	8aae                	mv	s5,a1
    80004ef2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ef4:	411c                	lw	a5,0(a0)
    80004ef6:	4705                	li	a4,1
    80004ef8:	02e78263          	beq	a5,a4,80004f1c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004efc:	470d                	li	a4,3
    80004efe:	02e78663          	beq	a5,a4,80004f2a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f02:	4709                	li	a4,2
    80004f04:	0ee79163          	bne	a5,a4,80004fe6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f08:	0ac05d63          	blez	a2,80004fc2 <filewrite+0xf4>
    int i = 0;
    80004f0c:	4981                	li	s3,0
    80004f0e:	6b05                	lui	s6,0x1
    80004f10:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f14:	6b85                	lui	s7,0x1
    80004f16:	c00b8b9b          	addiw	s7,s7,-1024
    80004f1a:	a861                	j	80004fb2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f1c:	6908                	ld	a0,16(a0)
    80004f1e:	00000097          	auipc	ra,0x0
    80004f22:	22e080e7          	jalr	558(ra) # 8000514c <pipewrite>
    80004f26:	8a2a                	mv	s4,a0
    80004f28:	a045                	j	80004fc8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f2a:	02451783          	lh	a5,36(a0)
    80004f2e:	03079693          	slli	a3,a5,0x30
    80004f32:	92c1                	srli	a3,a3,0x30
    80004f34:	4725                	li	a4,9
    80004f36:	0cd76263          	bltu	a4,a3,80004ffa <filewrite+0x12c>
    80004f3a:	0792                	slli	a5,a5,0x4
    80004f3c:	0001d717          	auipc	a4,0x1d
    80004f40:	d8470713          	addi	a4,a4,-636 # 80021cc0 <devsw>
    80004f44:	97ba                	add	a5,a5,a4
    80004f46:	679c                	ld	a5,8(a5)
    80004f48:	cbdd                	beqz	a5,80004ffe <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f4a:	4505                	li	a0,1
    80004f4c:	9782                	jalr	a5
    80004f4e:	8a2a                	mv	s4,a0
    80004f50:	a8a5                	j	80004fc8 <filewrite+0xfa>
    80004f52:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f56:	00000097          	auipc	ra,0x0
    80004f5a:	8b0080e7          	jalr	-1872(ra) # 80004806 <begin_op>
      ilock(f->ip);
    80004f5e:	01893503          	ld	a0,24(s2)
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	ed2080e7          	jalr	-302(ra) # 80003e34 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f6a:	8762                	mv	a4,s8
    80004f6c:	02092683          	lw	a3,32(s2)
    80004f70:	01598633          	add	a2,s3,s5
    80004f74:	4585                	li	a1,1
    80004f76:	01893503          	ld	a0,24(s2)
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	266080e7          	jalr	614(ra) # 800041e0 <writei>
    80004f82:	84aa                	mv	s1,a0
    80004f84:	00a05763          	blez	a0,80004f92 <filewrite+0xc4>
        f->off += r;
    80004f88:	02092783          	lw	a5,32(s2)
    80004f8c:	9fa9                	addw	a5,a5,a0
    80004f8e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f92:	01893503          	ld	a0,24(s2)
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	f60080e7          	jalr	-160(ra) # 80003ef6 <iunlock>
      end_op();
    80004f9e:	00000097          	auipc	ra,0x0
    80004fa2:	8e8080e7          	jalr	-1816(ra) # 80004886 <end_op>

      if(r != n1){
    80004fa6:	009c1f63          	bne	s8,s1,80004fc4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004faa:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fae:	0149db63          	bge	s3,s4,80004fc4 <filewrite+0xf6>
      int n1 = n - i;
    80004fb2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fb6:	84be                	mv	s1,a5
    80004fb8:	2781                	sext.w	a5,a5
    80004fba:	f8fb5ce3          	bge	s6,a5,80004f52 <filewrite+0x84>
    80004fbe:	84de                	mv	s1,s7
    80004fc0:	bf49                	j	80004f52 <filewrite+0x84>
    int i = 0;
    80004fc2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fc4:	013a1f63          	bne	s4,s3,80004fe2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fc8:	8552                	mv	a0,s4
    80004fca:	60a6                	ld	ra,72(sp)
    80004fcc:	6406                	ld	s0,64(sp)
    80004fce:	74e2                	ld	s1,56(sp)
    80004fd0:	7942                	ld	s2,48(sp)
    80004fd2:	79a2                	ld	s3,40(sp)
    80004fd4:	7a02                	ld	s4,32(sp)
    80004fd6:	6ae2                	ld	s5,24(sp)
    80004fd8:	6b42                	ld	s6,16(sp)
    80004fda:	6ba2                	ld	s7,8(sp)
    80004fdc:	6c02                	ld	s8,0(sp)
    80004fde:	6161                	addi	sp,sp,80
    80004fe0:	8082                	ret
    ret = (i == n ? n : -1);
    80004fe2:	5a7d                	li	s4,-1
    80004fe4:	b7d5                	j	80004fc8 <filewrite+0xfa>
    panic("filewrite");
    80004fe6:	00003517          	auipc	a0,0x3
    80004fea:	77a50513          	addi	a0,a0,1914 # 80008760 <syscalls+0x280>
    80004fee:	ffffb097          	auipc	ra,0xffffb
    80004ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>
    return -1;
    80004ff6:	5a7d                	li	s4,-1
    80004ff8:	bfc1                	j	80004fc8 <filewrite+0xfa>
      return -1;
    80004ffa:	5a7d                	li	s4,-1
    80004ffc:	b7f1                	j	80004fc8 <filewrite+0xfa>
    80004ffe:	5a7d                	li	s4,-1
    80005000:	b7e1                	j	80004fc8 <filewrite+0xfa>

0000000080005002 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005002:	7179                	addi	sp,sp,-48
    80005004:	f406                	sd	ra,40(sp)
    80005006:	f022                	sd	s0,32(sp)
    80005008:	ec26                	sd	s1,24(sp)
    8000500a:	e84a                	sd	s2,16(sp)
    8000500c:	e44e                	sd	s3,8(sp)
    8000500e:	e052                	sd	s4,0(sp)
    80005010:	1800                	addi	s0,sp,48
    80005012:	84aa                	mv	s1,a0
    80005014:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005016:	0005b023          	sd	zero,0(a1)
    8000501a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000501e:	00000097          	auipc	ra,0x0
    80005022:	bf8080e7          	jalr	-1032(ra) # 80004c16 <filealloc>
    80005026:	e088                	sd	a0,0(s1)
    80005028:	c551                	beqz	a0,800050b4 <pipealloc+0xb2>
    8000502a:	00000097          	auipc	ra,0x0
    8000502e:	bec080e7          	jalr	-1044(ra) # 80004c16 <filealloc>
    80005032:	00aa3023          	sd	a0,0(s4)
    80005036:	c92d                	beqz	a0,800050a8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005038:	ffffc097          	auipc	ra,0xffffc
    8000503c:	abc080e7          	jalr	-1348(ra) # 80000af4 <kalloc>
    80005040:	892a                	mv	s2,a0
    80005042:	c125                	beqz	a0,800050a2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005044:	4985                	li	s3,1
    80005046:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000504a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000504e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005052:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005056:	00003597          	auipc	a1,0x3
    8000505a:	71a58593          	addi	a1,a1,1818 # 80008770 <syscalls+0x290>
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	af6080e7          	jalr	-1290(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005066:	609c                	ld	a5,0(s1)
    80005068:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000506c:	609c                	ld	a5,0(s1)
    8000506e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005072:	609c                	ld	a5,0(s1)
    80005074:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005078:	609c                	ld	a5,0(s1)
    8000507a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000507e:	000a3783          	ld	a5,0(s4)
    80005082:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005086:	000a3783          	ld	a5,0(s4)
    8000508a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000508e:	000a3783          	ld	a5,0(s4)
    80005092:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005096:	000a3783          	ld	a5,0(s4)
    8000509a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000509e:	4501                	li	a0,0
    800050a0:	a025                	j	800050c8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050a2:	6088                	ld	a0,0(s1)
    800050a4:	e501                	bnez	a0,800050ac <pipealloc+0xaa>
    800050a6:	a039                	j	800050b4 <pipealloc+0xb2>
    800050a8:	6088                	ld	a0,0(s1)
    800050aa:	c51d                	beqz	a0,800050d8 <pipealloc+0xd6>
    fileclose(*f0);
    800050ac:	00000097          	auipc	ra,0x0
    800050b0:	c26080e7          	jalr	-986(ra) # 80004cd2 <fileclose>
  if(*f1)
    800050b4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050b8:	557d                	li	a0,-1
  if(*f1)
    800050ba:	c799                	beqz	a5,800050c8 <pipealloc+0xc6>
    fileclose(*f1);
    800050bc:	853e                	mv	a0,a5
    800050be:	00000097          	auipc	ra,0x0
    800050c2:	c14080e7          	jalr	-1004(ra) # 80004cd2 <fileclose>
  return -1;
    800050c6:	557d                	li	a0,-1
}
    800050c8:	70a2                	ld	ra,40(sp)
    800050ca:	7402                	ld	s0,32(sp)
    800050cc:	64e2                	ld	s1,24(sp)
    800050ce:	6942                	ld	s2,16(sp)
    800050d0:	69a2                	ld	s3,8(sp)
    800050d2:	6a02                	ld	s4,0(sp)
    800050d4:	6145                	addi	sp,sp,48
    800050d6:	8082                	ret
  return -1;
    800050d8:	557d                	li	a0,-1
    800050da:	b7fd                	j	800050c8 <pipealloc+0xc6>

00000000800050dc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050dc:	1101                	addi	sp,sp,-32
    800050de:	ec06                	sd	ra,24(sp)
    800050e0:	e822                	sd	s0,16(sp)
    800050e2:	e426                	sd	s1,8(sp)
    800050e4:	e04a                	sd	s2,0(sp)
    800050e6:	1000                	addi	s0,sp,32
    800050e8:	84aa                	mv	s1,a0
    800050ea:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	af8080e7          	jalr	-1288(ra) # 80000be4 <acquire>
  if(writable){
    800050f4:	02090d63          	beqz	s2,8000512e <pipeclose+0x52>
    pi->writeopen = 0;
    800050f8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050fc:	21848513          	addi	a0,s1,536
    80005100:	ffffd097          	auipc	ra,0xffffd
    80005104:	746080e7          	jalr	1862(ra) # 80002846 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005108:	2204b783          	ld	a5,544(s1)
    8000510c:	eb95                	bnez	a5,80005140 <pipeclose+0x64>
    release(&pi->lock);
    8000510e:	8526                	mv	a0,s1
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	b9a080e7          	jalr	-1126(ra) # 80000caa <release>
    kfree((char*)pi);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	8de080e7          	jalr	-1826(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005122:	60e2                	ld	ra,24(sp)
    80005124:	6442                	ld	s0,16(sp)
    80005126:	64a2                	ld	s1,8(sp)
    80005128:	6902                	ld	s2,0(sp)
    8000512a:	6105                	addi	sp,sp,32
    8000512c:	8082                	ret
    pi->readopen = 0;
    8000512e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005132:	21c48513          	addi	a0,s1,540
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	710080e7          	jalr	1808(ra) # 80002846 <wakeup>
    8000513e:	b7e9                	j	80005108 <pipeclose+0x2c>
    release(&pi->lock);
    80005140:	8526                	mv	a0,s1
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	b68080e7          	jalr	-1176(ra) # 80000caa <release>
}
    8000514a:	bfe1                	j	80005122 <pipeclose+0x46>

000000008000514c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000514c:	7159                	addi	sp,sp,-112
    8000514e:	f486                	sd	ra,104(sp)
    80005150:	f0a2                	sd	s0,96(sp)
    80005152:	eca6                	sd	s1,88(sp)
    80005154:	e8ca                	sd	s2,80(sp)
    80005156:	e4ce                	sd	s3,72(sp)
    80005158:	e0d2                	sd	s4,64(sp)
    8000515a:	fc56                	sd	s5,56(sp)
    8000515c:	f85a                	sd	s6,48(sp)
    8000515e:	f45e                	sd	s7,40(sp)
    80005160:	f062                	sd	s8,32(sp)
    80005162:	ec66                	sd	s9,24(sp)
    80005164:	1880                	addi	s0,sp,112
    80005166:	84aa                	mv	s1,a0
    80005168:	8aae                	mv	s5,a1
    8000516a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000516c:	ffffd097          	auipc	ra,0xffffd
    80005170:	c70080e7          	jalr	-912(ra) # 80001ddc <myproc>
    80005174:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005176:	8526                	mv	a0,s1
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	a6c080e7          	jalr	-1428(ra) # 80000be4 <acquire>
  while(i < n){
    80005180:	0d405163          	blez	s4,80005242 <pipewrite+0xf6>
    80005184:	8ba6                	mv	s7,s1
  int i = 0;
    80005186:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005188:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000518a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000518e:	21c48c13          	addi	s8,s1,540
    80005192:	a08d                	j	800051f4 <pipewrite+0xa8>
      release(&pi->lock);
    80005194:	8526                	mv	a0,s1
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	b14080e7          	jalr	-1260(ra) # 80000caa <release>
      return -1;
    8000519e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051a0:	854a                	mv	a0,s2
    800051a2:	70a6                	ld	ra,104(sp)
    800051a4:	7406                	ld	s0,96(sp)
    800051a6:	64e6                	ld	s1,88(sp)
    800051a8:	6946                	ld	s2,80(sp)
    800051aa:	69a6                	ld	s3,72(sp)
    800051ac:	6a06                	ld	s4,64(sp)
    800051ae:	7ae2                	ld	s5,56(sp)
    800051b0:	7b42                	ld	s6,48(sp)
    800051b2:	7ba2                	ld	s7,40(sp)
    800051b4:	7c02                	ld	s8,32(sp)
    800051b6:	6ce2                	ld	s9,24(sp)
    800051b8:	6165                	addi	sp,sp,112
    800051ba:	8082                	ret
      wakeup(&pi->nread);
    800051bc:	8566                	mv	a0,s9
    800051be:	ffffd097          	auipc	ra,0xffffd
    800051c2:	688080e7          	jalr	1672(ra) # 80002846 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051c6:	85de                	mv	a1,s7
    800051c8:	8562                	mv	a0,s8
    800051ca:	ffffd097          	auipc	ra,0xffffd
    800051ce:	4d4080e7          	jalr	1236(ra) # 8000269e <sleep>
    800051d2:	a839                	j	800051f0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051d4:	21c4a783          	lw	a5,540(s1)
    800051d8:	0017871b          	addiw	a4,a5,1
    800051dc:	20e4ae23          	sw	a4,540(s1)
    800051e0:	1ff7f793          	andi	a5,a5,511
    800051e4:	97a6                	add	a5,a5,s1
    800051e6:	f9f44703          	lbu	a4,-97(s0)
    800051ea:	00e78c23          	sb	a4,24(a5)
      i++;
    800051ee:	2905                	addiw	s2,s2,1
  while(i < n){
    800051f0:	03495d63          	bge	s2,s4,8000522a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051f4:	2204a783          	lw	a5,544(s1)
    800051f8:	dfd1                	beqz	a5,80005194 <pipewrite+0x48>
    800051fa:	0289a783          	lw	a5,40(s3)
    800051fe:	fbd9                	bnez	a5,80005194 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005200:	2184a783          	lw	a5,536(s1)
    80005204:	21c4a703          	lw	a4,540(s1)
    80005208:	2007879b          	addiw	a5,a5,512
    8000520c:	faf708e3          	beq	a4,a5,800051bc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005210:	4685                	li	a3,1
    80005212:	01590633          	add	a2,s2,s5
    80005216:	f9f40593          	addi	a1,s0,-97
    8000521a:	0709b503          	ld	a0,112(s3)
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	504080e7          	jalr	1284(ra) # 80001722 <copyin>
    80005226:	fb6517e3          	bne	a0,s6,800051d4 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000522a:	21848513          	addi	a0,s1,536
    8000522e:	ffffd097          	auipc	ra,0xffffd
    80005232:	618080e7          	jalr	1560(ra) # 80002846 <wakeup>
  release(&pi->lock);
    80005236:	8526                	mv	a0,s1
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	a72080e7          	jalr	-1422(ra) # 80000caa <release>
  return i;
    80005240:	b785                	j	800051a0 <pipewrite+0x54>
  int i = 0;
    80005242:	4901                	li	s2,0
    80005244:	b7dd                	j	8000522a <pipewrite+0xde>

0000000080005246 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005246:	715d                	addi	sp,sp,-80
    80005248:	e486                	sd	ra,72(sp)
    8000524a:	e0a2                	sd	s0,64(sp)
    8000524c:	fc26                	sd	s1,56(sp)
    8000524e:	f84a                	sd	s2,48(sp)
    80005250:	f44e                	sd	s3,40(sp)
    80005252:	f052                	sd	s4,32(sp)
    80005254:	ec56                	sd	s5,24(sp)
    80005256:	e85a                	sd	s6,16(sp)
    80005258:	0880                	addi	s0,sp,80
    8000525a:	84aa                	mv	s1,a0
    8000525c:	892e                	mv	s2,a1
    8000525e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005260:	ffffd097          	auipc	ra,0xffffd
    80005264:	b7c080e7          	jalr	-1156(ra) # 80001ddc <myproc>
    80005268:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000526a:	8b26                	mv	s6,s1
    8000526c:	8526                	mv	a0,s1
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	976080e7          	jalr	-1674(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005276:	2184a703          	lw	a4,536(s1)
    8000527a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000527e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005282:	02f71463          	bne	a4,a5,800052aa <piperead+0x64>
    80005286:	2244a783          	lw	a5,548(s1)
    8000528a:	c385                	beqz	a5,800052aa <piperead+0x64>
    if(pr->killed){
    8000528c:	028a2783          	lw	a5,40(s4)
    80005290:	ebc1                	bnez	a5,80005320 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005292:	85da                	mv	a1,s6
    80005294:	854e                	mv	a0,s3
    80005296:	ffffd097          	auipc	ra,0xffffd
    8000529a:	408080e7          	jalr	1032(ra) # 8000269e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000529e:	2184a703          	lw	a4,536(s1)
    800052a2:	21c4a783          	lw	a5,540(s1)
    800052a6:	fef700e3          	beq	a4,a5,80005286 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052aa:	09505263          	blez	s5,8000532e <piperead+0xe8>
    800052ae:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052b0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052b2:	2184a783          	lw	a5,536(s1)
    800052b6:	21c4a703          	lw	a4,540(s1)
    800052ba:	02f70d63          	beq	a4,a5,800052f4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052be:	0017871b          	addiw	a4,a5,1
    800052c2:	20e4ac23          	sw	a4,536(s1)
    800052c6:	1ff7f793          	andi	a5,a5,511
    800052ca:	97a6                	add	a5,a5,s1
    800052cc:	0187c783          	lbu	a5,24(a5)
    800052d0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052d4:	4685                	li	a3,1
    800052d6:	fbf40613          	addi	a2,s0,-65
    800052da:	85ca                	mv	a1,s2
    800052dc:	070a3503          	ld	a0,112(s4)
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	3b6080e7          	jalr	950(ra) # 80001696 <copyout>
    800052e8:	01650663          	beq	a0,s6,800052f4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ec:	2985                	addiw	s3,s3,1
    800052ee:	0905                	addi	s2,s2,1
    800052f0:	fd3a91e3          	bne	s5,s3,800052b2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052f4:	21c48513          	addi	a0,s1,540
    800052f8:	ffffd097          	auipc	ra,0xffffd
    800052fc:	54e080e7          	jalr	1358(ra) # 80002846 <wakeup>
  release(&pi->lock);
    80005300:	8526                	mv	a0,s1
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	9a8080e7          	jalr	-1624(ra) # 80000caa <release>
  return i;
}
    8000530a:	854e                	mv	a0,s3
    8000530c:	60a6                	ld	ra,72(sp)
    8000530e:	6406                	ld	s0,64(sp)
    80005310:	74e2                	ld	s1,56(sp)
    80005312:	7942                	ld	s2,48(sp)
    80005314:	79a2                	ld	s3,40(sp)
    80005316:	7a02                	ld	s4,32(sp)
    80005318:	6ae2                	ld	s5,24(sp)
    8000531a:	6b42                	ld	s6,16(sp)
    8000531c:	6161                	addi	sp,sp,80
    8000531e:	8082                	ret
      release(&pi->lock);
    80005320:	8526                	mv	a0,s1
    80005322:	ffffc097          	auipc	ra,0xffffc
    80005326:	988080e7          	jalr	-1656(ra) # 80000caa <release>
      return -1;
    8000532a:	59fd                	li	s3,-1
    8000532c:	bff9                	j	8000530a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000532e:	4981                	li	s3,0
    80005330:	b7d1                	j	800052f4 <piperead+0xae>

0000000080005332 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005332:	df010113          	addi	sp,sp,-528
    80005336:	20113423          	sd	ra,520(sp)
    8000533a:	20813023          	sd	s0,512(sp)
    8000533e:	ffa6                	sd	s1,504(sp)
    80005340:	fbca                	sd	s2,496(sp)
    80005342:	f7ce                	sd	s3,488(sp)
    80005344:	f3d2                	sd	s4,480(sp)
    80005346:	efd6                	sd	s5,472(sp)
    80005348:	ebda                	sd	s6,464(sp)
    8000534a:	e7de                	sd	s7,456(sp)
    8000534c:	e3e2                	sd	s8,448(sp)
    8000534e:	ff66                	sd	s9,440(sp)
    80005350:	fb6a                	sd	s10,432(sp)
    80005352:	f76e                	sd	s11,424(sp)
    80005354:	0c00                	addi	s0,sp,528
    80005356:	84aa                	mv	s1,a0
    80005358:	dea43c23          	sd	a0,-520(s0)
    8000535c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005360:	ffffd097          	auipc	ra,0xffffd
    80005364:	a7c080e7          	jalr	-1412(ra) # 80001ddc <myproc>
    80005368:	892a                	mv	s2,a0

  begin_op();
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	49c080e7          	jalr	1180(ra) # 80004806 <begin_op>

  if((ip = namei(path)) == 0){
    80005372:	8526                	mv	a0,s1
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	276080e7          	jalr	630(ra) # 800045ea <namei>
    8000537c:	c92d                	beqz	a0,800053ee <exec+0xbc>
    8000537e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	ab4080e7          	jalr	-1356(ra) # 80003e34 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005388:	04000713          	li	a4,64
    8000538c:	4681                	li	a3,0
    8000538e:	e5040613          	addi	a2,s0,-432
    80005392:	4581                	li	a1,0
    80005394:	8526                	mv	a0,s1
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	d52080e7          	jalr	-686(ra) # 800040e8 <readi>
    8000539e:	04000793          	li	a5,64
    800053a2:	00f51a63          	bne	a0,a5,800053b6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800053a6:	e5042703          	lw	a4,-432(s0)
    800053aa:	464c47b7          	lui	a5,0x464c4
    800053ae:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053b2:	04f70463          	beq	a4,a5,800053fa <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053b6:	8526                	mv	a0,s1
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	cde080e7          	jalr	-802(ra) # 80004096 <iunlockput>
    end_op();
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	4c6080e7          	jalr	1222(ra) # 80004886 <end_op>
  }
  return -1;
    800053c8:	557d                	li	a0,-1
}
    800053ca:	20813083          	ld	ra,520(sp)
    800053ce:	20013403          	ld	s0,512(sp)
    800053d2:	74fe                	ld	s1,504(sp)
    800053d4:	795e                	ld	s2,496(sp)
    800053d6:	79be                	ld	s3,488(sp)
    800053d8:	7a1e                	ld	s4,480(sp)
    800053da:	6afe                	ld	s5,472(sp)
    800053dc:	6b5e                	ld	s6,464(sp)
    800053de:	6bbe                	ld	s7,456(sp)
    800053e0:	6c1e                	ld	s8,448(sp)
    800053e2:	7cfa                	ld	s9,440(sp)
    800053e4:	7d5a                	ld	s10,432(sp)
    800053e6:	7dba                	ld	s11,424(sp)
    800053e8:	21010113          	addi	sp,sp,528
    800053ec:	8082                	ret
    end_op();
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	498080e7          	jalr	1176(ra) # 80004886 <end_op>
    return -1;
    800053f6:	557d                	li	a0,-1
    800053f8:	bfc9                	j	800053ca <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053fa:	854a                	mv	a0,s2
    800053fc:	ffffd097          	auipc	ra,0xffffd
    80005400:	af0080e7          	jalr	-1296(ra) # 80001eec <proc_pagetable>
    80005404:	8baa                	mv	s7,a0
    80005406:	d945                	beqz	a0,800053b6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005408:	e7042983          	lw	s3,-400(s0)
    8000540c:	e8845783          	lhu	a5,-376(s0)
    80005410:	c7ad                	beqz	a5,8000547a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005412:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005414:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005416:	6c85                	lui	s9,0x1
    80005418:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000541c:	def43823          	sd	a5,-528(s0)
    80005420:	a42d                	j	8000564a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005422:	00003517          	auipc	a0,0x3
    80005426:	35650513          	addi	a0,a0,854 # 80008778 <syscalls+0x298>
    8000542a:	ffffb097          	auipc	ra,0xffffb
    8000542e:	114080e7          	jalr	276(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005432:	8756                	mv	a4,s5
    80005434:	012d86bb          	addw	a3,s11,s2
    80005438:	4581                	li	a1,0
    8000543a:	8526                	mv	a0,s1
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	cac080e7          	jalr	-852(ra) # 800040e8 <readi>
    80005444:	2501                	sext.w	a0,a0
    80005446:	1aaa9963          	bne	s5,a0,800055f8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000544a:	6785                	lui	a5,0x1
    8000544c:	0127893b          	addw	s2,a5,s2
    80005450:	77fd                	lui	a5,0xfffff
    80005452:	01478a3b          	addw	s4,a5,s4
    80005456:	1f897163          	bgeu	s2,s8,80005638 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000545a:	02091593          	slli	a1,s2,0x20
    8000545e:	9181                	srli	a1,a1,0x20
    80005460:	95ea                	add	a1,a1,s10
    80005462:	855e                	mv	a0,s7
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	c2e080e7          	jalr	-978(ra) # 80001092 <walkaddr>
    8000546c:	862a                	mv	a2,a0
    if(pa == 0)
    8000546e:	d955                	beqz	a0,80005422 <exec+0xf0>
      n = PGSIZE;
    80005470:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005472:	fd9a70e3          	bgeu	s4,s9,80005432 <exec+0x100>
      n = sz - i;
    80005476:	8ad2                	mv	s5,s4
    80005478:	bf6d                	j	80005432 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000547a:	4901                	li	s2,0
  iunlockput(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	c18080e7          	jalr	-1000(ra) # 80004096 <iunlockput>
  end_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	400080e7          	jalr	1024(ra) # 80004886 <end_op>
  p = myproc();
    8000548e:	ffffd097          	auipc	ra,0xffffd
    80005492:	94e080e7          	jalr	-1714(ra) # 80001ddc <myproc>
    80005496:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005498:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000549c:	6785                	lui	a5,0x1
    8000549e:	17fd                	addi	a5,a5,-1
    800054a0:	993e                	add	s2,s2,a5
    800054a2:	757d                	lui	a0,0xfffff
    800054a4:	00a977b3          	and	a5,s2,a0
    800054a8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054ac:	6609                	lui	a2,0x2
    800054ae:	963e                	add	a2,a2,a5
    800054b0:	85be                	mv	a1,a5
    800054b2:	855e                	mv	a0,s7
    800054b4:	ffffc097          	auipc	ra,0xffffc
    800054b8:	f92080e7          	jalr	-110(ra) # 80001446 <uvmalloc>
    800054bc:	8b2a                	mv	s6,a0
  ip = 0;
    800054be:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054c0:	12050c63          	beqz	a0,800055f8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054c4:	75f9                	lui	a1,0xffffe
    800054c6:	95aa                	add	a1,a1,a0
    800054c8:	855e                	mv	a0,s7
    800054ca:	ffffc097          	auipc	ra,0xffffc
    800054ce:	19a080e7          	jalr	410(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    800054d2:	7c7d                	lui	s8,0xfffff
    800054d4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054d6:	e0043783          	ld	a5,-512(s0)
    800054da:	6388                	ld	a0,0(a5)
    800054dc:	c535                	beqz	a0,80005548 <exec+0x216>
    800054de:	e9040993          	addi	s3,s0,-368
    800054e2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054e6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800054e8:	ffffc097          	auipc	ra,0xffffc
    800054ec:	9a0080e7          	jalr	-1632(ra) # 80000e88 <strlen>
    800054f0:	2505                	addiw	a0,a0,1
    800054f2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054f6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054fa:	13896363          	bltu	s2,s8,80005620 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054fe:	e0043d83          	ld	s11,-512(s0)
    80005502:	000dba03          	ld	s4,0(s11)
    80005506:	8552                	mv	a0,s4
    80005508:	ffffc097          	auipc	ra,0xffffc
    8000550c:	980080e7          	jalr	-1664(ra) # 80000e88 <strlen>
    80005510:	0015069b          	addiw	a3,a0,1
    80005514:	8652                	mv	a2,s4
    80005516:	85ca                	mv	a1,s2
    80005518:	855e                	mv	a0,s7
    8000551a:	ffffc097          	auipc	ra,0xffffc
    8000551e:	17c080e7          	jalr	380(ra) # 80001696 <copyout>
    80005522:	10054363          	bltz	a0,80005628 <exec+0x2f6>
    ustack[argc] = sp;
    80005526:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000552a:	0485                	addi	s1,s1,1
    8000552c:	008d8793          	addi	a5,s11,8
    80005530:	e0f43023          	sd	a5,-512(s0)
    80005534:	008db503          	ld	a0,8(s11)
    80005538:	c911                	beqz	a0,8000554c <exec+0x21a>
    if(argc >= MAXARG)
    8000553a:	09a1                	addi	s3,s3,8
    8000553c:	fb3c96e3          	bne	s9,s3,800054e8 <exec+0x1b6>
  sz = sz1;
    80005540:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005544:	4481                	li	s1,0
    80005546:	a84d                	j	800055f8 <exec+0x2c6>
  sp = sz;
    80005548:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000554a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000554c:	00349793          	slli	a5,s1,0x3
    80005550:	f9040713          	addi	a4,s0,-112
    80005554:	97ba                	add	a5,a5,a4
    80005556:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000555a:	00148693          	addi	a3,s1,1
    8000555e:	068e                	slli	a3,a3,0x3
    80005560:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005564:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005568:	01897663          	bgeu	s2,s8,80005574 <exec+0x242>
  sz = sz1;
    8000556c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005570:	4481                	li	s1,0
    80005572:	a059                	j	800055f8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005574:	e9040613          	addi	a2,s0,-368
    80005578:	85ca                	mv	a1,s2
    8000557a:	855e                	mv	a0,s7
    8000557c:	ffffc097          	auipc	ra,0xffffc
    80005580:	11a080e7          	jalr	282(ra) # 80001696 <copyout>
    80005584:	0a054663          	bltz	a0,80005630 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005588:	078ab783          	ld	a5,120(s5)
    8000558c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005590:	df843783          	ld	a5,-520(s0)
    80005594:	0007c703          	lbu	a4,0(a5)
    80005598:	cf11                	beqz	a4,800055b4 <exec+0x282>
    8000559a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000559c:	02f00693          	li	a3,47
    800055a0:	a039                	j	800055ae <exec+0x27c>
      last = s+1;
    800055a2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055a6:	0785                	addi	a5,a5,1
    800055a8:	fff7c703          	lbu	a4,-1(a5)
    800055ac:	c701                	beqz	a4,800055b4 <exec+0x282>
    if(*s == '/')
    800055ae:	fed71ce3          	bne	a4,a3,800055a6 <exec+0x274>
    800055b2:	bfc5                	j	800055a2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800055b4:	4641                	li	a2,16
    800055b6:	df843583          	ld	a1,-520(s0)
    800055ba:	178a8513          	addi	a0,s5,376
    800055be:	ffffc097          	auipc	ra,0xffffc
    800055c2:	898080e7          	jalr	-1896(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    800055c6:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800055ca:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800055ce:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055d2:	078ab783          	ld	a5,120(s5)
    800055d6:	e6843703          	ld	a4,-408(s0)
    800055da:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055dc:	078ab783          	ld	a5,120(s5)
    800055e0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055e4:	85ea                	mv	a1,s10
    800055e6:	ffffd097          	auipc	ra,0xffffd
    800055ea:	9a2080e7          	jalr	-1630(ra) # 80001f88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055ee:	0004851b          	sext.w	a0,s1
    800055f2:	bbe1                	j	800053ca <exec+0x98>
    800055f4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055f8:	e0843583          	ld	a1,-504(s0)
    800055fc:	855e                	mv	a0,s7
    800055fe:	ffffd097          	auipc	ra,0xffffd
    80005602:	98a080e7          	jalr	-1654(ra) # 80001f88 <proc_freepagetable>
  if(ip){
    80005606:	da0498e3          	bnez	s1,800053b6 <exec+0x84>
  return -1;
    8000560a:	557d                	li	a0,-1
    8000560c:	bb7d                	j	800053ca <exec+0x98>
    8000560e:	e1243423          	sd	s2,-504(s0)
    80005612:	b7dd                	j	800055f8 <exec+0x2c6>
    80005614:	e1243423          	sd	s2,-504(s0)
    80005618:	b7c5                	j	800055f8 <exec+0x2c6>
    8000561a:	e1243423          	sd	s2,-504(s0)
    8000561e:	bfe9                	j	800055f8 <exec+0x2c6>
  sz = sz1;
    80005620:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005624:	4481                	li	s1,0
    80005626:	bfc9                	j	800055f8 <exec+0x2c6>
  sz = sz1;
    80005628:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000562c:	4481                	li	s1,0
    8000562e:	b7e9                	j	800055f8 <exec+0x2c6>
  sz = sz1;
    80005630:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005634:	4481                	li	s1,0
    80005636:	b7c9                	j	800055f8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005638:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000563c:	2b05                	addiw	s6,s6,1
    8000563e:	0389899b          	addiw	s3,s3,56
    80005642:	e8845783          	lhu	a5,-376(s0)
    80005646:	e2fb5be3          	bge	s6,a5,8000547c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000564a:	2981                	sext.w	s3,s3
    8000564c:	03800713          	li	a4,56
    80005650:	86ce                	mv	a3,s3
    80005652:	e1840613          	addi	a2,s0,-488
    80005656:	4581                	li	a1,0
    80005658:	8526                	mv	a0,s1
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	a8e080e7          	jalr	-1394(ra) # 800040e8 <readi>
    80005662:	03800793          	li	a5,56
    80005666:	f8f517e3          	bne	a0,a5,800055f4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000566a:	e1842783          	lw	a5,-488(s0)
    8000566e:	4705                	li	a4,1
    80005670:	fce796e3          	bne	a5,a4,8000563c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005674:	e4043603          	ld	a2,-448(s0)
    80005678:	e3843783          	ld	a5,-456(s0)
    8000567c:	f8f669e3          	bltu	a2,a5,8000560e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005680:	e2843783          	ld	a5,-472(s0)
    80005684:	963e                	add	a2,a2,a5
    80005686:	f8f667e3          	bltu	a2,a5,80005614 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000568a:	85ca                	mv	a1,s2
    8000568c:	855e                	mv	a0,s7
    8000568e:	ffffc097          	auipc	ra,0xffffc
    80005692:	db8080e7          	jalr	-584(ra) # 80001446 <uvmalloc>
    80005696:	e0a43423          	sd	a0,-504(s0)
    8000569a:	d141                	beqz	a0,8000561a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000569c:	e2843d03          	ld	s10,-472(s0)
    800056a0:	df043783          	ld	a5,-528(s0)
    800056a4:	00fd77b3          	and	a5,s10,a5
    800056a8:	fba1                	bnez	a5,800055f8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056aa:	e2042d83          	lw	s11,-480(s0)
    800056ae:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056b2:	f80c03e3          	beqz	s8,80005638 <exec+0x306>
    800056b6:	8a62                	mv	s4,s8
    800056b8:	4901                	li	s2,0
    800056ba:	b345                	j	8000545a <exec+0x128>

00000000800056bc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056bc:	7179                	addi	sp,sp,-48
    800056be:	f406                	sd	ra,40(sp)
    800056c0:	f022                	sd	s0,32(sp)
    800056c2:	ec26                	sd	s1,24(sp)
    800056c4:	e84a                	sd	s2,16(sp)
    800056c6:	1800                	addi	s0,sp,48
    800056c8:	892e                	mv	s2,a1
    800056ca:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056cc:	fdc40593          	addi	a1,s0,-36
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	b76080e7          	jalr	-1162(ra) # 80003246 <argint>
    800056d8:	04054063          	bltz	a0,80005718 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056dc:	fdc42703          	lw	a4,-36(s0)
    800056e0:	47bd                	li	a5,15
    800056e2:	02e7ed63          	bltu	a5,a4,8000571c <argfd+0x60>
    800056e6:	ffffc097          	auipc	ra,0xffffc
    800056ea:	6f6080e7          	jalr	1782(ra) # 80001ddc <myproc>
    800056ee:	fdc42703          	lw	a4,-36(s0)
    800056f2:	01e70793          	addi	a5,a4,30
    800056f6:	078e                	slli	a5,a5,0x3
    800056f8:	953e                	add	a0,a0,a5
    800056fa:	611c                	ld	a5,0(a0)
    800056fc:	c395                	beqz	a5,80005720 <argfd+0x64>
    return -1;
  if(pfd)
    800056fe:	00090463          	beqz	s2,80005706 <argfd+0x4a>
    *pfd = fd;
    80005702:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005706:	4501                	li	a0,0
  if(pf)
    80005708:	c091                	beqz	s1,8000570c <argfd+0x50>
    *pf = f;
    8000570a:	e09c                	sd	a5,0(s1)
}
    8000570c:	70a2                	ld	ra,40(sp)
    8000570e:	7402                	ld	s0,32(sp)
    80005710:	64e2                	ld	s1,24(sp)
    80005712:	6942                	ld	s2,16(sp)
    80005714:	6145                	addi	sp,sp,48
    80005716:	8082                	ret
    return -1;
    80005718:	557d                	li	a0,-1
    8000571a:	bfcd                	j	8000570c <argfd+0x50>
    return -1;
    8000571c:	557d                	li	a0,-1
    8000571e:	b7fd                	j	8000570c <argfd+0x50>
    80005720:	557d                	li	a0,-1
    80005722:	b7ed                	j	8000570c <argfd+0x50>

0000000080005724 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005724:	1101                	addi	sp,sp,-32
    80005726:	ec06                	sd	ra,24(sp)
    80005728:	e822                	sd	s0,16(sp)
    8000572a:	e426                	sd	s1,8(sp)
    8000572c:	1000                	addi	s0,sp,32
    8000572e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005730:	ffffc097          	auipc	ra,0xffffc
    80005734:	6ac080e7          	jalr	1708(ra) # 80001ddc <myproc>
    80005738:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000573a:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000573e:	4501                	li	a0,0
    80005740:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005742:	6398                	ld	a4,0(a5)
    80005744:	cb19                	beqz	a4,8000575a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005746:	2505                	addiw	a0,a0,1
    80005748:	07a1                	addi	a5,a5,8
    8000574a:	fed51ce3          	bne	a0,a3,80005742 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000574e:	557d                	li	a0,-1
}
    80005750:	60e2                	ld	ra,24(sp)
    80005752:	6442                	ld	s0,16(sp)
    80005754:	64a2                	ld	s1,8(sp)
    80005756:	6105                	addi	sp,sp,32
    80005758:	8082                	ret
      p->ofile[fd] = f;
    8000575a:	01e50793          	addi	a5,a0,30
    8000575e:	078e                	slli	a5,a5,0x3
    80005760:	963e                	add	a2,a2,a5
    80005762:	e204                	sd	s1,0(a2)
      return fd;
    80005764:	b7f5                	j	80005750 <fdalloc+0x2c>

0000000080005766 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005766:	715d                	addi	sp,sp,-80
    80005768:	e486                	sd	ra,72(sp)
    8000576a:	e0a2                	sd	s0,64(sp)
    8000576c:	fc26                	sd	s1,56(sp)
    8000576e:	f84a                	sd	s2,48(sp)
    80005770:	f44e                	sd	s3,40(sp)
    80005772:	f052                	sd	s4,32(sp)
    80005774:	ec56                	sd	s5,24(sp)
    80005776:	0880                	addi	s0,sp,80
    80005778:	89ae                	mv	s3,a1
    8000577a:	8ab2                	mv	s5,a2
    8000577c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000577e:	fb040593          	addi	a1,s0,-80
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	e86080e7          	jalr	-378(ra) # 80004608 <nameiparent>
    8000578a:	892a                	mv	s2,a0
    8000578c:	12050f63          	beqz	a0,800058ca <create+0x164>
    return 0;

  ilock(dp);
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	6a4080e7          	jalr	1700(ra) # 80003e34 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005798:	4601                	li	a2,0
    8000579a:	fb040593          	addi	a1,s0,-80
    8000579e:	854a                	mv	a0,s2
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	b78080e7          	jalr	-1160(ra) # 80004318 <dirlookup>
    800057a8:	84aa                	mv	s1,a0
    800057aa:	c921                	beqz	a0,800057fa <create+0x94>
    iunlockput(dp);
    800057ac:	854a                	mv	a0,s2
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	8e8080e7          	jalr	-1816(ra) # 80004096 <iunlockput>
    ilock(ip);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	67c080e7          	jalr	1660(ra) # 80003e34 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057c0:	2981                	sext.w	s3,s3
    800057c2:	4789                	li	a5,2
    800057c4:	02f99463          	bne	s3,a5,800057ec <create+0x86>
    800057c8:	0444d783          	lhu	a5,68(s1)
    800057cc:	37f9                	addiw	a5,a5,-2
    800057ce:	17c2                	slli	a5,a5,0x30
    800057d0:	93c1                	srli	a5,a5,0x30
    800057d2:	4705                	li	a4,1
    800057d4:	00f76c63          	bltu	a4,a5,800057ec <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057d8:	8526                	mv	a0,s1
    800057da:	60a6                	ld	ra,72(sp)
    800057dc:	6406                	ld	s0,64(sp)
    800057de:	74e2                	ld	s1,56(sp)
    800057e0:	7942                	ld	s2,48(sp)
    800057e2:	79a2                	ld	s3,40(sp)
    800057e4:	7a02                	ld	s4,32(sp)
    800057e6:	6ae2                	ld	s5,24(sp)
    800057e8:	6161                	addi	sp,sp,80
    800057ea:	8082                	ret
    iunlockput(ip);
    800057ec:	8526                	mv	a0,s1
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	8a8080e7          	jalr	-1880(ra) # 80004096 <iunlockput>
    return 0;
    800057f6:	4481                	li	s1,0
    800057f8:	b7c5                	j	800057d8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057fa:	85ce                	mv	a1,s3
    800057fc:	00092503          	lw	a0,0(s2)
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	49c080e7          	jalr	1180(ra) # 80003c9c <ialloc>
    80005808:	84aa                	mv	s1,a0
    8000580a:	c529                	beqz	a0,80005854 <create+0xee>
  ilock(ip);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	628080e7          	jalr	1576(ra) # 80003e34 <ilock>
  ip->major = major;
    80005814:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005818:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000581c:	4785                	li	a5,1
    8000581e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	546080e7          	jalr	1350(ra) # 80003d6a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000582c:	2981                	sext.w	s3,s3
    8000582e:	4785                	li	a5,1
    80005830:	02f98a63          	beq	s3,a5,80005864 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005834:	40d0                	lw	a2,4(s1)
    80005836:	fb040593          	addi	a1,s0,-80
    8000583a:	854a                	mv	a0,s2
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	cec080e7          	jalr	-788(ra) # 80004528 <dirlink>
    80005844:	06054b63          	bltz	a0,800058ba <create+0x154>
  iunlockput(dp);
    80005848:	854a                	mv	a0,s2
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	84c080e7          	jalr	-1972(ra) # 80004096 <iunlockput>
  return ip;
    80005852:	b759                	j	800057d8 <create+0x72>
    panic("create: ialloc");
    80005854:	00003517          	auipc	a0,0x3
    80005858:	f4450513          	addi	a0,a0,-188 # 80008798 <syscalls+0x2b8>
    8000585c:	ffffb097          	auipc	ra,0xffffb
    80005860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005864:	04a95783          	lhu	a5,74(s2)
    80005868:	2785                	addiw	a5,a5,1
    8000586a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000586e:	854a                	mv	a0,s2
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	4fa080e7          	jalr	1274(ra) # 80003d6a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005878:	40d0                	lw	a2,4(s1)
    8000587a:	00003597          	auipc	a1,0x3
    8000587e:	f2e58593          	addi	a1,a1,-210 # 800087a8 <syscalls+0x2c8>
    80005882:	8526                	mv	a0,s1
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	ca4080e7          	jalr	-860(ra) # 80004528 <dirlink>
    8000588c:	00054f63          	bltz	a0,800058aa <create+0x144>
    80005890:	00492603          	lw	a2,4(s2)
    80005894:	00003597          	auipc	a1,0x3
    80005898:	f1c58593          	addi	a1,a1,-228 # 800087b0 <syscalls+0x2d0>
    8000589c:	8526                	mv	a0,s1
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	c8a080e7          	jalr	-886(ra) # 80004528 <dirlink>
    800058a6:	f80557e3          	bgez	a0,80005834 <create+0xce>
      panic("create dots");
    800058aa:	00003517          	auipc	a0,0x3
    800058ae:	f0e50513          	addi	a0,a0,-242 # 800087b8 <syscalls+0x2d8>
    800058b2:	ffffb097          	auipc	ra,0xffffb
    800058b6:	c8c080e7          	jalr	-884(ra) # 8000053e <panic>
    panic("create: dirlink");
    800058ba:	00003517          	auipc	a0,0x3
    800058be:	f0e50513          	addi	a0,a0,-242 # 800087c8 <syscalls+0x2e8>
    800058c2:	ffffb097          	auipc	ra,0xffffb
    800058c6:	c7c080e7          	jalr	-900(ra) # 8000053e <panic>
    return 0;
    800058ca:	84aa                	mv	s1,a0
    800058cc:	b731                	j	800057d8 <create+0x72>

00000000800058ce <sys_dup>:
{
    800058ce:	7179                	addi	sp,sp,-48
    800058d0:	f406                	sd	ra,40(sp)
    800058d2:	f022                	sd	s0,32(sp)
    800058d4:	ec26                	sd	s1,24(sp)
    800058d6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058d8:	fd840613          	addi	a2,s0,-40
    800058dc:	4581                	li	a1,0
    800058de:	4501                	li	a0,0
    800058e0:	00000097          	auipc	ra,0x0
    800058e4:	ddc080e7          	jalr	-548(ra) # 800056bc <argfd>
    return -1;
    800058e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058ea:	02054363          	bltz	a0,80005910 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058ee:	fd843503          	ld	a0,-40(s0)
    800058f2:	00000097          	auipc	ra,0x0
    800058f6:	e32080e7          	jalr	-462(ra) # 80005724 <fdalloc>
    800058fa:	84aa                	mv	s1,a0
    return -1;
    800058fc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058fe:	00054963          	bltz	a0,80005910 <sys_dup+0x42>
  filedup(f);
    80005902:	fd843503          	ld	a0,-40(s0)
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	37a080e7          	jalr	890(ra) # 80004c80 <filedup>
  return fd;
    8000590e:	87a6                	mv	a5,s1
}
    80005910:	853e                	mv	a0,a5
    80005912:	70a2                	ld	ra,40(sp)
    80005914:	7402                	ld	s0,32(sp)
    80005916:	64e2                	ld	s1,24(sp)
    80005918:	6145                	addi	sp,sp,48
    8000591a:	8082                	ret

000000008000591c <sys_read>:
{
    8000591c:	7179                	addi	sp,sp,-48
    8000591e:	f406                	sd	ra,40(sp)
    80005920:	f022                	sd	s0,32(sp)
    80005922:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005924:	fe840613          	addi	a2,s0,-24
    80005928:	4581                	li	a1,0
    8000592a:	4501                	li	a0,0
    8000592c:	00000097          	auipc	ra,0x0
    80005930:	d90080e7          	jalr	-624(ra) # 800056bc <argfd>
    return -1;
    80005934:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005936:	04054163          	bltz	a0,80005978 <sys_read+0x5c>
    8000593a:	fe440593          	addi	a1,s0,-28
    8000593e:	4509                	li	a0,2
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	906080e7          	jalr	-1786(ra) # 80003246 <argint>
    return -1;
    80005948:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000594a:	02054763          	bltz	a0,80005978 <sys_read+0x5c>
    8000594e:	fd840593          	addi	a1,s0,-40
    80005952:	4505                	li	a0,1
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	914080e7          	jalr	-1772(ra) # 80003268 <argaddr>
    return -1;
    8000595c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000595e:	00054d63          	bltz	a0,80005978 <sys_read+0x5c>
  return fileread(f, p, n);
    80005962:	fe442603          	lw	a2,-28(s0)
    80005966:	fd843583          	ld	a1,-40(s0)
    8000596a:	fe843503          	ld	a0,-24(s0)
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	49e080e7          	jalr	1182(ra) # 80004e0c <fileread>
    80005976:	87aa                	mv	a5,a0
}
    80005978:	853e                	mv	a0,a5
    8000597a:	70a2                	ld	ra,40(sp)
    8000597c:	7402                	ld	s0,32(sp)
    8000597e:	6145                	addi	sp,sp,48
    80005980:	8082                	ret

0000000080005982 <sys_write>:
{
    80005982:	7179                	addi	sp,sp,-48
    80005984:	f406                	sd	ra,40(sp)
    80005986:	f022                	sd	s0,32(sp)
    80005988:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000598a:	fe840613          	addi	a2,s0,-24
    8000598e:	4581                	li	a1,0
    80005990:	4501                	li	a0,0
    80005992:	00000097          	auipc	ra,0x0
    80005996:	d2a080e7          	jalr	-726(ra) # 800056bc <argfd>
    return -1;
    8000599a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000599c:	04054163          	bltz	a0,800059de <sys_write+0x5c>
    800059a0:	fe440593          	addi	a1,s0,-28
    800059a4:	4509                	li	a0,2
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	8a0080e7          	jalr	-1888(ra) # 80003246 <argint>
    return -1;
    800059ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b0:	02054763          	bltz	a0,800059de <sys_write+0x5c>
    800059b4:	fd840593          	addi	a1,s0,-40
    800059b8:	4505                	li	a0,1
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	8ae080e7          	jalr	-1874(ra) # 80003268 <argaddr>
    return -1;
    800059c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c4:	00054d63          	bltz	a0,800059de <sys_write+0x5c>
  return filewrite(f, p, n);
    800059c8:	fe442603          	lw	a2,-28(s0)
    800059cc:	fd843583          	ld	a1,-40(s0)
    800059d0:	fe843503          	ld	a0,-24(s0)
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	4fa080e7          	jalr	1274(ra) # 80004ece <filewrite>
    800059dc:	87aa                	mv	a5,a0
}
    800059de:	853e                	mv	a0,a5
    800059e0:	70a2                	ld	ra,40(sp)
    800059e2:	7402                	ld	s0,32(sp)
    800059e4:	6145                	addi	sp,sp,48
    800059e6:	8082                	ret

00000000800059e8 <sys_close>:
{
    800059e8:	1101                	addi	sp,sp,-32
    800059ea:	ec06                	sd	ra,24(sp)
    800059ec:	e822                	sd	s0,16(sp)
    800059ee:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059f0:	fe040613          	addi	a2,s0,-32
    800059f4:	fec40593          	addi	a1,s0,-20
    800059f8:	4501                	li	a0,0
    800059fa:	00000097          	auipc	ra,0x0
    800059fe:	cc2080e7          	jalr	-830(ra) # 800056bc <argfd>
    return -1;
    80005a02:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a04:	02054463          	bltz	a0,80005a2c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a08:	ffffc097          	auipc	ra,0xffffc
    80005a0c:	3d4080e7          	jalr	980(ra) # 80001ddc <myproc>
    80005a10:	fec42783          	lw	a5,-20(s0)
    80005a14:	07f9                	addi	a5,a5,30
    80005a16:	078e                	slli	a5,a5,0x3
    80005a18:	97aa                	add	a5,a5,a0
    80005a1a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a1e:	fe043503          	ld	a0,-32(s0)
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	2b0080e7          	jalr	688(ra) # 80004cd2 <fileclose>
  return 0;
    80005a2a:	4781                	li	a5,0
}
    80005a2c:	853e                	mv	a0,a5
    80005a2e:	60e2                	ld	ra,24(sp)
    80005a30:	6442                	ld	s0,16(sp)
    80005a32:	6105                	addi	sp,sp,32
    80005a34:	8082                	ret

0000000080005a36 <sys_fstat>:
{
    80005a36:	1101                	addi	sp,sp,-32
    80005a38:	ec06                	sd	ra,24(sp)
    80005a3a:	e822                	sd	s0,16(sp)
    80005a3c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a3e:	fe840613          	addi	a2,s0,-24
    80005a42:	4581                	li	a1,0
    80005a44:	4501                	li	a0,0
    80005a46:	00000097          	auipc	ra,0x0
    80005a4a:	c76080e7          	jalr	-906(ra) # 800056bc <argfd>
    return -1;
    80005a4e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a50:	02054563          	bltz	a0,80005a7a <sys_fstat+0x44>
    80005a54:	fe040593          	addi	a1,s0,-32
    80005a58:	4505                	li	a0,1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	80e080e7          	jalr	-2034(ra) # 80003268 <argaddr>
    return -1;
    80005a62:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a64:	00054b63          	bltz	a0,80005a7a <sys_fstat+0x44>
  return filestat(f, st);
    80005a68:	fe043583          	ld	a1,-32(s0)
    80005a6c:	fe843503          	ld	a0,-24(s0)
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	32a080e7          	jalr	810(ra) # 80004d9a <filestat>
    80005a78:	87aa                	mv	a5,a0
}
    80005a7a:	853e                	mv	a0,a5
    80005a7c:	60e2                	ld	ra,24(sp)
    80005a7e:	6442                	ld	s0,16(sp)
    80005a80:	6105                	addi	sp,sp,32
    80005a82:	8082                	ret

0000000080005a84 <sys_link>:
{
    80005a84:	7169                	addi	sp,sp,-304
    80005a86:	f606                	sd	ra,296(sp)
    80005a88:	f222                	sd	s0,288(sp)
    80005a8a:	ee26                	sd	s1,280(sp)
    80005a8c:	ea4a                	sd	s2,272(sp)
    80005a8e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a90:	08000613          	li	a2,128
    80005a94:	ed040593          	addi	a1,s0,-304
    80005a98:	4501                	li	a0,0
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	7f0080e7          	jalr	2032(ra) # 8000328a <argstr>
    return -1;
    80005aa2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aa4:	10054e63          	bltz	a0,80005bc0 <sys_link+0x13c>
    80005aa8:	08000613          	li	a2,128
    80005aac:	f5040593          	addi	a1,s0,-176
    80005ab0:	4505                	li	a0,1
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	7d8080e7          	jalr	2008(ra) # 8000328a <argstr>
    return -1;
    80005aba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005abc:	10054263          	bltz	a0,80005bc0 <sys_link+0x13c>
  begin_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	d46080e7          	jalr	-698(ra) # 80004806 <begin_op>
  if((ip = namei(old)) == 0){
    80005ac8:	ed040513          	addi	a0,s0,-304
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	b1e080e7          	jalr	-1250(ra) # 800045ea <namei>
    80005ad4:	84aa                	mv	s1,a0
    80005ad6:	c551                	beqz	a0,80005b62 <sys_link+0xde>
  ilock(ip);
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	35c080e7          	jalr	860(ra) # 80003e34 <ilock>
  if(ip->type == T_DIR){
    80005ae0:	04449703          	lh	a4,68(s1)
    80005ae4:	4785                	li	a5,1
    80005ae6:	08f70463          	beq	a4,a5,80005b6e <sys_link+0xea>
  ip->nlink++;
    80005aea:	04a4d783          	lhu	a5,74(s1)
    80005aee:	2785                	addiw	a5,a5,1
    80005af0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005af4:	8526                	mv	a0,s1
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	274080e7          	jalr	628(ra) # 80003d6a <iupdate>
  iunlock(ip);
    80005afe:	8526                	mv	a0,s1
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	3f6080e7          	jalr	1014(ra) # 80003ef6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b08:	fd040593          	addi	a1,s0,-48
    80005b0c:	f5040513          	addi	a0,s0,-176
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	af8080e7          	jalr	-1288(ra) # 80004608 <nameiparent>
    80005b18:	892a                	mv	s2,a0
    80005b1a:	c935                	beqz	a0,80005b8e <sys_link+0x10a>
  ilock(dp);
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	318080e7          	jalr	792(ra) # 80003e34 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b24:	00092703          	lw	a4,0(s2)
    80005b28:	409c                	lw	a5,0(s1)
    80005b2a:	04f71d63          	bne	a4,a5,80005b84 <sys_link+0x100>
    80005b2e:	40d0                	lw	a2,4(s1)
    80005b30:	fd040593          	addi	a1,s0,-48
    80005b34:	854a                	mv	a0,s2
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	9f2080e7          	jalr	-1550(ra) # 80004528 <dirlink>
    80005b3e:	04054363          	bltz	a0,80005b84 <sys_link+0x100>
  iunlockput(dp);
    80005b42:	854a                	mv	a0,s2
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	552080e7          	jalr	1362(ra) # 80004096 <iunlockput>
  iput(ip);
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	4a0080e7          	jalr	1184(ra) # 80003fee <iput>
  end_op();
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	d30080e7          	jalr	-720(ra) # 80004886 <end_op>
  return 0;
    80005b5e:	4781                	li	a5,0
    80005b60:	a085                	j	80005bc0 <sys_link+0x13c>
    end_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	d24080e7          	jalr	-732(ra) # 80004886 <end_op>
    return -1;
    80005b6a:	57fd                	li	a5,-1
    80005b6c:	a891                	j	80005bc0 <sys_link+0x13c>
    iunlockput(ip);
    80005b6e:	8526                	mv	a0,s1
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	526080e7          	jalr	1318(ra) # 80004096 <iunlockput>
    end_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	d0e080e7          	jalr	-754(ra) # 80004886 <end_op>
    return -1;
    80005b80:	57fd                	li	a5,-1
    80005b82:	a83d                	j	80005bc0 <sys_link+0x13c>
    iunlockput(dp);
    80005b84:	854a                	mv	a0,s2
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	510080e7          	jalr	1296(ra) # 80004096 <iunlockput>
  ilock(ip);
    80005b8e:	8526                	mv	a0,s1
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	2a4080e7          	jalr	676(ra) # 80003e34 <ilock>
  ip->nlink--;
    80005b98:	04a4d783          	lhu	a5,74(s1)
    80005b9c:	37fd                	addiw	a5,a5,-1
    80005b9e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ba2:	8526                	mv	a0,s1
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	1c6080e7          	jalr	454(ra) # 80003d6a <iupdate>
  iunlockput(ip);
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	4e8080e7          	jalr	1256(ra) # 80004096 <iunlockput>
  end_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	cd0080e7          	jalr	-816(ra) # 80004886 <end_op>
  return -1;
    80005bbe:	57fd                	li	a5,-1
}
    80005bc0:	853e                	mv	a0,a5
    80005bc2:	70b2                	ld	ra,296(sp)
    80005bc4:	7412                	ld	s0,288(sp)
    80005bc6:	64f2                	ld	s1,280(sp)
    80005bc8:	6952                	ld	s2,272(sp)
    80005bca:	6155                	addi	sp,sp,304
    80005bcc:	8082                	ret

0000000080005bce <sys_unlink>:
{
    80005bce:	7151                	addi	sp,sp,-240
    80005bd0:	f586                	sd	ra,232(sp)
    80005bd2:	f1a2                	sd	s0,224(sp)
    80005bd4:	eda6                	sd	s1,216(sp)
    80005bd6:	e9ca                	sd	s2,208(sp)
    80005bd8:	e5ce                	sd	s3,200(sp)
    80005bda:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bdc:	08000613          	li	a2,128
    80005be0:	f3040593          	addi	a1,s0,-208
    80005be4:	4501                	li	a0,0
    80005be6:	ffffd097          	auipc	ra,0xffffd
    80005bea:	6a4080e7          	jalr	1700(ra) # 8000328a <argstr>
    80005bee:	18054163          	bltz	a0,80005d70 <sys_unlink+0x1a2>
  begin_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	c14080e7          	jalr	-1004(ra) # 80004806 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bfa:	fb040593          	addi	a1,s0,-80
    80005bfe:	f3040513          	addi	a0,s0,-208
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	a06080e7          	jalr	-1530(ra) # 80004608 <nameiparent>
    80005c0a:	84aa                	mv	s1,a0
    80005c0c:	c979                	beqz	a0,80005ce2 <sys_unlink+0x114>
  ilock(dp);
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	226080e7          	jalr	550(ra) # 80003e34 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c16:	00003597          	auipc	a1,0x3
    80005c1a:	b9258593          	addi	a1,a1,-1134 # 800087a8 <syscalls+0x2c8>
    80005c1e:	fb040513          	addi	a0,s0,-80
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	6dc080e7          	jalr	1756(ra) # 800042fe <namecmp>
    80005c2a:	14050a63          	beqz	a0,80005d7e <sys_unlink+0x1b0>
    80005c2e:	00003597          	auipc	a1,0x3
    80005c32:	b8258593          	addi	a1,a1,-1150 # 800087b0 <syscalls+0x2d0>
    80005c36:	fb040513          	addi	a0,s0,-80
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	6c4080e7          	jalr	1732(ra) # 800042fe <namecmp>
    80005c42:	12050e63          	beqz	a0,80005d7e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c46:	f2c40613          	addi	a2,s0,-212
    80005c4a:	fb040593          	addi	a1,s0,-80
    80005c4e:	8526                	mv	a0,s1
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	6c8080e7          	jalr	1736(ra) # 80004318 <dirlookup>
    80005c58:	892a                	mv	s2,a0
    80005c5a:	12050263          	beqz	a0,80005d7e <sys_unlink+0x1b0>
  ilock(ip);
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	1d6080e7          	jalr	470(ra) # 80003e34 <ilock>
  if(ip->nlink < 1)
    80005c66:	04a91783          	lh	a5,74(s2)
    80005c6a:	08f05263          	blez	a5,80005cee <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c6e:	04491703          	lh	a4,68(s2)
    80005c72:	4785                	li	a5,1
    80005c74:	08f70563          	beq	a4,a5,80005cfe <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c78:	4641                	li	a2,16
    80005c7a:	4581                	li	a1,0
    80005c7c:	fc040513          	addi	a0,s0,-64
    80005c80:	ffffb097          	auipc	ra,0xffffb
    80005c84:	084080e7          	jalr	132(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c88:	4741                	li	a4,16
    80005c8a:	f2c42683          	lw	a3,-212(s0)
    80005c8e:	fc040613          	addi	a2,s0,-64
    80005c92:	4581                	li	a1,0
    80005c94:	8526                	mv	a0,s1
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	54a080e7          	jalr	1354(ra) # 800041e0 <writei>
    80005c9e:	47c1                	li	a5,16
    80005ca0:	0af51563          	bne	a0,a5,80005d4a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ca4:	04491703          	lh	a4,68(s2)
    80005ca8:	4785                	li	a5,1
    80005caa:	0af70863          	beq	a4,a5,80005d5a <sys_unlink+0x18c>
  iunlockput(dp);
    80005cae:	8526                	mv	a0,s1
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	3e6080e7          	jalr	998(ra) # 80004096 <iunlockput>
  ip->nlink--;
    80005cb8:	04a95783          	lhu	a5,74(s2)
    80005cbc:	37fd                	addiw	a5,a5,-1
    80005cbe:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cc2:	854a                	mv	a0,s2
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	0a6080e7          	jalr	166(ra) # 80003d6a <iupdate>
  iunlockput(ip);
    80005ccc:	854a                	mv	a0,s2
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	3c8080e7          	jalr	968(ra) # 80004096 <iunlockput>
  end_op();
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	bb0080e7          	jalr	-1104(ra) # 80004886 <end_op>
  return 0;
    80005cde:	4501                	li	a0,0
    80005ce0:	a84d                	j	80005d92 <sys_unlink+0x1c4>
    end_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	ba4080e7          	jalr	-1116(ra) # 80004886 <end_op>
    return -1;
    80005cea:	557d                	li	a0,-1
    80005cec:	a05d                	j	80005d92 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cee:	00003517          	auipc	a0,0x3
    80005cf2:	aea50513          	addi	a0,a0,-1302 # 800087d8 <syscalls+0x2f8>
    80005cf6:	ffffb097          	auipc	ra,0xffffb
    80005cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cfe:	04c92703          	lw	a4,76(s2)
    80005d02:	02000793          	li	a5,32
    80005d06:	f6e7f9e3          	bgeu	a5,a4,80005c78 <sys_unlink+0xaa>
    80005d0a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d0e:	4741                	li	a4,16
    80005d10:	86ce                	mv	a3,s3
    80005d12:	f1840613          	addi	a2,s0,-232
    80005d16:	4581                	li	a1,0
    80005d18:	854a                	mv	a0,s2
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	3ce080e7          	jalr	974(ra) # 800040e8 <readi>
    80005d22:	47c1                	li	a5,16
    80005d24:	00f51b63          	bne	a0,a5,80005d3a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d28:	f1845783          	lhu	a5,-232(s0)
    80005d2c:	e7a1                	bnez	a5,80005d74 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d2e:	29c1                	addiw	s3,s3,16
    80005d30:	04c92783          	lw	a5,76(s2)
    80005d34:	fcf9ede3          	bltu	s3,a5,80005d0e <sys_unlink+0x140>
    80005d38:	b781                	j	80005c78 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d3a:	00003517          	auipc	a0,0x3
    80005d3e:	ab650513          	addi	a0,a0,-1354 # 800087f0 <syscalls+0x310>
    80005d42:	ffffa097          	auipc	ra,0xffffa
    80005d46:	7fc080e7          	jalr	2044(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d4a:	00003517          	auipc	a0,0x3
    80005d4e:	abe50513          	addi	a0,a0,-1346 # 80008808 <syscalls+0x328>
    80005d52:	ffffa097          	auipc	ra,0xffffa
    80005d56:	7ec080e7          	jalr	2028(ra) # 8000053e <panic>
    dp->nlink--;
    80005d5a:	04a4d783          	lhu	a5,74(s1)
    80005d5e:	37fd                	addiw	a5,a5,-1
    80005d60:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d64:	8526                	mv	a0,s1
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	004080e7          	jalr	4(ra) # 80003d6a <iupdate>
    80005d6e:	b781                	j	80005cae <sys_unlink+0xe0>
    return -1;
    80005d70:	557d                	li	a0,-1
    80005d72:	a005                	j	80005d92 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d74:	854a                	mv	a0,s2
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	320080e7          	jalr	800(ra) # 80004096 <iunlockput>
  iunlockput(dp);
    80005d7e:	8526                	mv	a0,s1
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	316080e7          	jalr	790(ra) # 80004096 <iunlockput>
  end_op();
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	afe080e7          	jalr	-1282(ra) # 80004886 <end_op>
  return -1;
    80005d90:	557d                	li	a0,-1
}
    80005d92:	70ae                	ld	ra,232(sp)
    80005d94:	740e                	ld	s0,224(sp)
    80005d96:	64ee                	ld	s1,216(sp)
    80005d98:	694e                	ld	s2,208(sp)
    80005d9a:	69ae                	ld	s3,200(sp)
    80005d9c:	616d                	addi	sp,sp,240
    80005d9e:	8082                	ret

0000000080005da0 <sys_open>:

uint64
sys_open(void)
{
    80005da0:	7131                	addi	sp,sp,-192
    80005da2:	fd06                	sd	ra,184(sp)
    80005da4:	f922                	sd	s0,176(sp)
    80005da6:	f526                	sd	s1,168(sp)
    80005da8:	f14a                	sd	s2,160(sp)
    80005daa:	ed4e                	sd	s3,152(sp)
    80005dac:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dae:	08000613          	li	a2,128
    80005db2:	f5040593          	addi	a1,s0,-176
    80005db6:	4501                	li	a0,0
    80005db8:	ffffd097          	auipc	ra,0xffffd
    80005dbc:	4d2080e7          	jalr	1234(ra) # 8000328a <argstr>
    return -1;
    80005dc0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dc2:	0c054163          	bltz	a0,80005e84 <sys_open+0xe4>
    80005dc6:	f4c40593          	addi	a1,s0,-180
    80005dca:	4505                	li	a0,1
    80005dcc:	ffffd097          	auipc	ra,0xffffd
    80005dd0:	47a080e7          	jalr	1146(ra) # 80003246 <argint>
    80005dd4:	0a054863          	bltz	a0,80005e84 <sys_open+0xe4>

  begin_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	a2e080e7          	jalr	-1490(ra) # 80004806 <begin_op>

  if(omode & O_CREATE){
    80005de0:	f4c42783          	lw	a5,-180(s0)
    80005de4:	2007f793          	andi	a5,a5,512
    80005de8:	cbdd                	beqz	a5,80005e9e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005dea:	4681                	li	a3,0
    80005dec:	4601                	li	a2,0
    80005dee:	4589                	li	a1,2
    80005df0:	f5040513          	addi	a0,s0,-176
    80005df4:	00000097          	auipc	ra,0x0
    80005df8:	972080e7          	jalr	-1678(ra) # 80005766 <create>
    80005dfc:	892a                	mv	s2,a0
    if(ip == 0){
    80005dfe:	c959                	beqz	a0,80005e94 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e00:	04491703          	lh	a4,68(s2)
    80005e04:	478d                	li	a5,3
    80005e06:	00f71763          	bne	a4,a5,80005e14 <sys_open+0x74>
    80005e0a:	04695703          	lhu	a4,70(s2)
    80005e0e:	47a5                	li	a5,9
    80005e10:	0ce7ec63          	bltu	a5,a4,80005ee8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	e02080e7          	jalr	-510(ra) # 80004c16 <filealloc>
    80005e1c:	89aa                	mv	s3,a0
    80005e1e:	10050263          	beqz	a0,80005f22 <sys_open+0x182>
    80005e22:	00000097          	auipc	ra,0x0
    80005e26:	902080e7          	jalr	-1790(ra) # 80005724 <fdalloc>
    80005e2a:	84aa                	mv	s1,a0
    80005e2c:	0e054663          	bltz	a0,80005f18 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e30:	04491703          	lh	a4,68(s2)
    80005e34:	478d                	li	a5,3
    80005e36:	0cf70463          	beq	a4,a5,80005efe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e3a:	4789                	li	a5,2
    80005e3c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e40:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e44:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e48:	f4c42783          	lw	a5,-180(s0)
    80005e4c:	0017c713          	xori	a4,a5,1
    80005e50:	8b05                	andi	a4,a4,1
    80005e52:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e56:	0037f713          	andi	a4,a5,3
    80005e5a:	00e03733          	snez	a4,a4
    80005e5e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e62:	4007f793          	andi	a5,a5,1024
    80005e66:	c791                	beqz	a5,80005e72 <sys_open+0xd2>
    80005e68:	04491703          	lh	a4,68(s2)
    80005e6c:	4789                	li	a5,2
    80005e6e:	08f70f63          	beq	a4,a5,80005f0c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e72:	854a                	mv	a0,s2
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	082080e7          	jalr	130(ra) # 80003ef6 <iunlock>
  end_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	a0a080e7          	jalr	-1526(ra) # 80004886 <end_op>

  return fd;
}
    80005e84:	8526                	mv	a0,s1
    80005e86:	70ea                	ld	ra,184(sp)
    80005e88:	744a                	ld	s0,176(sp)
    80005e8a:	74aa                	ld	s1,168(sp)
    80005e8c:	790a                	ld	s2,160(sp)
    80005e8e:	69ea                	ld	s3,152(sp)
    80005e90:	6129                	addi	sp,sp,192
    80005e92:	8082                	ret
      end_op();
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	9f2080e7          	jalr	-1550(ra) # 80004886 <end_op>
      return -1;
    80005e9c:	b7e5                	j	80005e84 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e9e:	f5040513          	addi	a0,s0,-176
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	748080e7          	jalr	1864(ra) # 800045ea <namei>
    80005eaa:	892a                	mv	s2,a0
    80005eac:	c905                	beqz	a0,80005edc <sys_open+0x13c>
    ilock(ip);
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	f86080e7          	jalr	-122(ra) # 80003e34 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005eb6:	04491703          	lh	a4,68(s2)
    80005eba:	4785                	li	a5,1
    80005ebc:	f4f712e3          	bne	a4,a5,80005e00 <sys_open+0x60>
    80005ec0:	f4c42783          	lw	a5,-180(s0)
    80005ec4:	dba1                	beqz	a5,80005e14 <sys_open+0x74>
      iunlockput(ip);
    80005ec6:	854a                	mv	a0,s2
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	1ce080e7          	jalr	462(ra) # 80004096 <iunlockput>
      end_op();
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	9b6080e7          	jalr	-1610(ra) # 80004886 <end_op>
      return -1;
    80005ed8:	54fd                	li	s1,-1
    80005eda:	b76d                	j	80005e84 <sys_open+0xe4>
      end_op();
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	9aa080e7          	jalr	-1622(ra) # 80004886 <end_op>
      return -1;
    80005ee4:	54fd                	li	s1,-1
    80005ee6:	bf79                	j	80005e84 <sys_open+0xe4>
    iunlockput(ip);
    80005ee8:	854a                	mv	a0,s2
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	1ac080e7          	jalr	428(ra) # 80004096 <iunlockput>
    end_op();
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	994080e7          	jalr	-1644(ra) # 80004886 <end_op>
    return -1;
    80005efa:	54fd                	li	s1,-1
    80005efc:	b761                	j	80005e84 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005efe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f02:	04691783          	lh	a5,70(s2)
    80005f06:	02f99223          	sh	a5,36(s3)
    80005f0a:	bf2d                	j	80005e44 <sys_open+0xa4>
    itrunc(ip);
    80005f0c:	854a                	mv	a0,s2
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	034080e7          	jalr	52(ra) # 80003f42 <itrunc>
    80005f16:	bfb1                	j	80005e72 <sys_open+0xd2>
      fileclose(f);
    80005f18:	854e                	mv	a0,s3
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	db8080e7          	jalr	-584(ra) # 80004cd2 <fileclose>
    iunlockput(ip);
    80005f22:	854a                	mv	a0,s2
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	172080e7          	jalr	370(ra) # 80004096 <iunlockput>
    end_op();
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	95a080e7          	jalr	-1702(ra) # 80004886 <end_op>
    return -1;
    80005f34:	54fd                	li	s1,-1
    80005f36:	b7b9                	j	80005e84 <sys_open+0xe4>

0000000080005f38 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f38:	7175                	addi	sp,sp,-144
    80005f3a:	e506                	sd	ra,136(sp)
    80005f3c:	e122                	sd	s0,128(sp)
    80005f3e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	8c6080e7          	jalr	-1850(ra) # 80004806 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f48:	08000613          	li	a2,128
    80005f4c:	f7040593          	addi	a1,s0,-144
    80005f50:	4501                	li	a0,0
    80005f52:	ffffd097          	auipc	ra,0xffffd
    80005f56:	338080e7          	jalr	824(ra) # 8000328a <argstr>
    80005f5a:	02054963          	bltz	a0,80005f8c <sys_mkdir+0x54>
    80005f5e:	4681                	li	a3,0
    80005f60:	4601                	li	a2,0
    80005f62:	4585                	li	a1,1
    80005f64:	f7040513          	addi	a0,s0,-144
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	7fe080e7          	jalr	2046(ra) # 80005766 <create>
    80005f70:	cd11                	beqz	a0,80005f8c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	124080e7          	jalr	292(ra) # 80004096 <iunlockput>
  end_op();
    80005f7a:	fffff097          	auipc	ra,0xfffff
    80005f7e:	90c080e7          	jalr	-1780(ra) # 80004886 <end_op>
  return 0;
    80005f82:	4501                	li	a0,0
}
    80005f84:	60aa                	ld	ra,136(sp)
    80005f86:	640a                	ld	s0,128(sp)
    80005f88:	6149                	addi	sp,sp,144
    80005f8a:	8082                	ret
    end_op();
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	8fa080e7          	jalr	-1798(ra) # 80004886 <end_op>
    return -1;
    80005f94:	557d                	li	a0,-1
    80005f96:	b7fd                	j	80005f84 <sys_mkdir+0x4c>

0000000080005f98 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f98:	7135                	addi	sp,sp,-160
    80005f9a:	ed06                	sd	ra,152(sp)
    80005f9c:	e922                	sd	s0,144(sp)
    80005f9e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	866080e7          	jalr	-1946(ra) # 80004806 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fa8:	08000613          	li	a2,128
    80005fac:	f7040593          	addi	a1,s0,-144
    80005fb0:	4501                	li	a0,0
    80005fb2:	ffffd097          	auipc	ra,0xffffd
    80005fb6:	2d8080e7          	jalr	728(ra) # 8000328a <argstr>
    80005fba:	04054a63          	bltz	a0,8000600e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fbe:	f6c40593          	addi	a1,s0,-148
    80005fc2:	4505                	li	a0,1
    80005fc4:	ffffd097          	auipc	ra,0xffffd
    80005fc8:	282080e7          	jalr	642(ra) # 80003246 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fcc:	04054163          	bltz	a0,8000600e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005fd0:	f6840593          	addi	a1,s0,-152
    80005fd4:	4509                	li	a0,2
    80005fd6:	ffffd097          	auipc	ra,0xffffd
    80005fda:	270080e7          	jalr	624(ra) # 80003246 <argint>
     argint(1, &major) < 0 ||
    80005fde:	02054863          	bltz	a0,8000600e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fe2:	f6841683          	lh	a3,-152(s0)
    80005fe6:	f6c41603          	lh	a2,-148(s0)
    80005fea:	458d                	li	a1,3
    80005fec:	f7040513          	addi	a0,s0,-144
    80005ff0:	fffff097          	auipc	ra,0xfffff
    80005ff4:	776080e7          	jalr	1910(ra) # 80005766 <create>
     argint(2, &minor) < 0 ||
    80005ff8:	c919                	beqz	a0,8000600e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ffa:	ffffe097          	auipc	ra,0xffffe
    80005ffe:	09c080e7          	jalr	156(ra) # 80004096 <iunlockput>
  end_op();
    80006002:	fffff097          	auipc	ra,0xfffff
    80006006:	884080e7          	jalr	-1916(ra) # 80004886 <end_op>
  return 0;
    8000600a:	4501                	li	a0,0
    8000600c:	a031                	j	80006018 <sys_mknod+0x80>
    end_op();
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	878080e7          	jalr	-1928(ra) # 80004886 <end_op>
    return -1;
    80006016:	557d                	li	a0,-1
}
    80006018:	60ea                	ld	ra,152(sp)
    8000601a:	644a                	ld	s0,144(sp)
    8000601c:	610d                	addi	sp,sp,160
    8000601e:	8082                	ret

0000000080006020 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006020:	7135                	addi	sp,sp,-160
    80006022:	ed06                	sd	ra,152(sp)
    80006024:	e922                	sd	s0,144(sp)
    80006026:	e526                	sd	s1,136(sp)
    80006028:	e14a                	sd	s2,128(sp)
    8000602a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000602c:	ffffc097          	auipc	ra,0xffffc
    80006030:	db0080e7          	jalr	-592(ra) # 80001ddc <myproc>
    80006034:	892a                	mv	s2,a0
  
  begin_op();
    80006036:	ffffe097          	auipc	ra,0xffffe
    8000603a:	7d0080e7          	jalr	2000(ra) # 80004806 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000603e:	08000613          	li	a2,128
    80006042:	f6040593          	addi	a1,s0,-160
    80006046:	4501                	li	a0,0
    80006048:	ffffd097          	auipc	ra,0xffffd
    8000604c:	242080e7          	jalr	578(ra) # 8000328a <argstr>
    80006050:	04054b63          	bltz	a0,800060a6 <sys_chdir+0x86>
    80006054:	f6040513          	addi	a0,s0,-160
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	592080e7          	jalr	1426(ra) # 800045ea <namei>
    80006060:	84aa                	mv	s1,a0
    80006062:	c131                	beqz	a0,800060a6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	dd0080e7          	jalr	-560(ra) # 80003e34 <ilock>
  if(ip->type != T_DIR){
    8000606c:	04449703          	lh	a4,68(s1)
    80006070:	4785                	li	a5,1
    80006072:	04f71063          	bne	a4,a5,800060b2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006076:	8526                	mv	a0,s1
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	e7e080e7          	jalr	-386(ra) # 80003ef6 <iunlock>
  iput(p->cwd);
    80006080:	17093503          	ld	a0,368(s2)
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	f6a080e7          	jalr	-150(ra) # 80003fee <iput>
  end_op();
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	7fa080e7          	jalr	2042(ra) # 80004886 <end_op>
  p->cwd = ip;
    80006094:	16993823          	sd	s1,368(s2)
  return 0;
    80006098:	4501                	li	a0,0
}
    8000609a:	60ea                	ld	ra,152(sp)
    8000609c:	644a                	ld	s0,144(sp)
    8000609e:	64aa                	ld	s1,136(sp)
    800060a0:	690a                	ld	s2,128(sp)
    800060a2:	610d                	addi	sp,sp,160
    800060a4:	8082                	ret
    end_op();
    800060a6:	ffffe097          	auipc	ra,0xffffe
    800060aa:	7e0080e7          	jalr	2016(ra) # 80004886 <end_op>
    return -1;
    800060ae:	557d                	li	a0,-1
    800060b0:	b7ed                	j	8000609a <sys_chdir+0x7a>
    iunlockput(ip);
    800060b2:	8526                	mv	a0,s1
    800060b4:	ffffe097          	auipc	ra,0xffffe
    800060b8:	fe2080e7          	jalr	-30(ra) # 80004096 <iunlockput>
    end_op();
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	7ca080e7          	jalr	1994(ra) # 80004886 <end_op>
    return -1;
    800060c4:	557d                	li	a0,-1
    800060c6:	bfd1                	j	8000609a <sys_chdir+0x7a>

00000000800060c8 <sys_exec>:

uint64
sys_exec(void)
{
    800060c8:	7145                	addi	sp,sp,-464
    800060ca:	e786                	sd	ra,456(sp)
    800060cc:	e3a2                	sd	s0,448(sp)
    800060ce:	ff26                	sd	s1,440(sp)
    800060d0:	fb4a                	sd	s2,432(sp)
    800060d2:	f74e                	sd	s3,424(sp)
    800060d4:	f352                	sd	s4,416(sp)
    800060d6:	ef56                	sd	s5,408(sp)
    800060d8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060da:	08000613          	li	a2,128
    800060de:	f4040593          	addi	a1,s0,-192
    800060e2:	4501                	li	a0,0
    800060e4:	ffffd097          	auipc	ra,0xffffd
    800060e8:	1a6080e7          	jalr	422(ra) # 8000328a <argstr>
    return -1;
    800060ec:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060ee:	0c054a63          	bltz	a0,800061c2 <sys_exec+0xfa>
    800060f2:	e3840593          	addi	a1,s0,-456
    800060f6:	4505                	li	a0,1
    800060f8:	ffffd097          	auipc	ra,0xffffd
    800060fc:	170080e7          	jalr	368(ra) # 80003268 <argaddr>
    80006100:	0c054163          	bltz	a0,800061c2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006104:	10000613          	li	a2,256
    80006108:	4581                	li	a1,0
    8000610a:	e4040513          	addi	a0,s0,-448
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	bf6080e7          	jalr	-1034(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006116:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000611a:	89a6                	mv	s3,s1
    8000611c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000611e:	02000a13          	li	s4,32
    80006122:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006126:	00391513          	slli	a0,s2,0x3
    8000612a:	e3040593          	addi	a1,s0,-464
    8000612e:	e3843783          	ld	a5,-456(s0)
    80006132:	953e                	add	a0,a0,a5
    80006134:	ffffd097          	auipc	ra,0xffffd
    80006138:	078080e7          	jalr	120(ra) # 800031ac <fetchaddr>
    8000613c:	02054a63          	bltz	a0,80006170 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006140:	e3043783          	ld	a5,-464(s0)
    80006144:	c3b9                	beqz	a5,8000618a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006146:	ffffb097          	auipc	ra,0xffffb
    8000614a:	9ae080e7          	jalr	-1618(ra) # 80000af4 <kalloc>
    8000614e:	85aa                	mv	a1,a0
    80006150:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006154:	cd11                	beqz	a0,80006170 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006156:	6605                	lui	a2,0x1
    80006158:	e3043503          	ld	a0,-464(s0)
    8000615c:	ffffd097          	auipc	ra,0xffffd
    80006160:	0a2080e7          	jalr	162(ra) # 800031fe <fetchstr>
    80006164:	00054663          	bltz	a0,80006170 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006168:	0905                	addi	s2,s2,1
    8000616a:	09a1                	addi	s3,s3,8
    8000616c:	fb491be3          	bne	s2,s4,80006122 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006170:	10048913          	addi	s2,s1,256
    80006174:	6088                	ld	a0,0(s1)
    80006176:	c529                	beqz	a0,800061c0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	880080e7          	jalr	-1920(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006180:	04a1                	addi	s1,s1,8
    80006182:	ff2499e3          	bne	s1,s2,80006174 <sys_exec+0xac>
  return -1;
    80006186:	597d                	li	s2,-1
    80006188:	a82d                	j	800061c2 <sys_exec+0xfa>
      argv[i] = 0;
    8000618a:	0a8e                	slli	s5,s5,0x3
    8000618c:	fc040793          	addi	a5,s0,-64
    80006190:	9abe                	add	s5,s5,a5
    80006192:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006196:	e4040593          	addi	a1,s0,-448
    8000619a:	f4040513          	addi	a0,s0,-192
    8000619e:	fffff097          	auipc	ra,0xfffff
    800061a2:	194080e7          	jalr	404(ra) # 80005332 <exec>
    800061a6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061a8:	10048993          	addi	s3,s1,256
    800061ac:	6088                	ld	a0,0(s1)
    800061ae:	c911                	beqz	a0,800061c2 <sys_exec+0xfa>
    kfree(argv[i]);
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	848080e7          	jalr	-1976(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061b8:	04a1                	addi	s1,s1,8
    800061ba:	ff3499e3          	bne	s1,s3,800061ac <sys_exec+0xe4>
    800061be:	a011                	j	800061c2 <sys_exec+0xfa>
  return -1;
    800061c0:	597d                	li	s2,-1
}
    800061c2:	854a                	mv	a0,s2
    800061c4:	60be                	ld	ra,456(sp)
    800061c6:	641e                	ld	s0,448(sp)
    800061c8:	74fa                	ld	s1,440(sp)
    800061ca:	795a                	ld	s2,432(sp)
    800061cc:	79ba                	ld	s3,424(sp)
    800061ce:	7a1a                	ld	s4,416(sp)
    800061d0:	6afa                	ld	s5,408(sp)
    800061d2:	6179                	addi	sp,sp,464
    800061d4:	8082                	ret

00000000800061d6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800061d6:	7139                	addi	sp,sp,-64
    800061d8:	fc06                	sd	ra,56(sp)
    800061da:	f822                	sd	s0,48(sp)
    800061dc:	f426                	sd	s1,40(sp)
    800061de:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061e0:	ffffc097          	auipc	ra,0xffffc
    800061e4:	bfc080e7          	jalr	-1028(ra) # 80001ddc <myproc>
    800061e8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061ea:	fd840593          	addi	a1,s0,-40
    800061ee:	4501                	li	a0,0
    800061f0:	ffffd097          	auipc	ra,0xffffd
    800061f4:	078080e7          	jalr	120(ra) # 80003268 <argaddr>
    return -1;
    800061f8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061fa:	0e054063          	bltz	a0,800062da <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061fe:	fc840593          	addi	a1,s0,-56
    80006202:	fd040513          	addi	a0,s0,-48
    80006206:	fffff097          	auipc	ra,0xfffff
    8000620a:	dfc080e7          	jalr	-516(ra) # 80005002 <pipealloc>
    return -1;
    8000620e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006210:	0c054563          	bltz	a0,800062da <sys_pipe+0x104>
  fd0 = -1;
    80006214:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006218:	fd043503          	ld	a0,-48(s0)
    8000621c:	fffff097          	auipc	ra,0xfffff
    80006220:	508080e7          	jalr	1288(ra) # 80005724 <fdalloc>
    80006224:	fca42223          	sw	a0,-60(s0)
    80006228:	08054c63          	bltz	a0,800062c0 <sys_pipe+0xea>
    8000622c:	fc843503          	ld	a0,-56(s0)
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	4f4080e7          	jalr	1268(ra) # 80005724 <fdalloc>
    80006238:	fca42023          	sw	a0,-64(s0)
    8000623c:	06054863          	bltz	a0,800062ac <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006240:	4691                	li	a3,4
    80006242:	fc440613          	addi	a2,s0,-60
    80006246:	fd843583          	ld	a1,-40(s0)
    8000624a:	78a8                	ld	a0,112(s1)
    8000624c:	ffffb097          	auipc	ra,0xffffb
    80006250:	44a080e7          	jalr	1098(ra) # 80001696 <copyout>
    80006254:	02054063          	bltz	a0,80006274 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006258:	4691                	li	a3,4
    8000625a:	fc040613          	addi	a2,s0,-64
    8000625e:	fd843583          	ld	a1,-40(s0)
    80006262:	0591                	addi	a1,a1,4
    80006264:	78a8                	ld	a0,112(s1)
    80006266:	ffffb097          	auipc	ra,0xffffb
    8000626a:	430080e7          	jalr	1072(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000626e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006270:	06055563          	bgez	a0,800062da <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006274:	fc442783          	lw	a5,-60(s0)
    80006278:	07f9                	addi	a5,a5,30
    8000627a:	078e                	slli	a5,a5,0x3
    8000627c:	97a6                	add	a5,a5,s1
    8000627e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006282:	fc042503          	lw	a0,-64(s0)
    80006286:	0579                	addi	a0,a0,30
    80006288:	050e                	slli	a0,a0,0x3
    8000628a:	9526                	add	a0,a0,s1
    8000628c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006290:	fd043503          	ld	a0,-48(s0)
    80006294:	fffff097          	auipc	ra,0xfffff
    80006298:	a3e080e7          	jalr	-1474(ra) # 80004cd2 <fileclose>
    fileclose(wf);
    8000629c:	fc843503          	ld	a0,-56(s0)
    800062a0:	fffff097          	auipc	ra,0xfffff
    800062a4:	a32080e7          	jalr	-1486(ra) # 80004cd2 <fileclose>
    return -1;
    800062a8:	57fd                	li	a5,-1
    800062aa:	a805                	j	800062da <sys_pipe+0x104>
    if(fd0 >= 0)
    800062ac:	fc442783          	lw	a5,-60(s0)
    800062b0:	0007c863          	bltz	a5,800062c0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800062b4:	01e78513          	addi	a0,a5,30
    800062b8:	050e                	slli	a0,a0,0x3
    800062ba:	9526                	add	a0,a0,s1
    800062bc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062c0:	fd043503          	ld	a0,-48(s0)
    800062c4:	fffff097          	auipc	ra,0xfffff
    800062c8:	a0e080e7          	jalr	-1522(ra) # 80004cd2 <fileclose>
    fileclose(wf);
    800062cc:	fc843503          	ld	a0,-56(s0)
    800062d0:	fffff097          	auipc	ra,0xfffff
    800062d4:	a02080e7          	jalr	-1534(ra) # 80004cd2 <fileclose>
    return -1;
    800062d8:	57fd                	li	a5,-1
}
    800062da:	853e                	mv	a0,a5
    800062dc:	70e2                	ld	ra,56(sp)
    800062de:	7442                	ld	s0,48(sp)
    800062e0:	74a2                	ld	s1,40(sp)
    800062e2:	6121                	addi	sp,sp,64
    800062e4:	8082                	ret
	...

00000000800062f0 <kernelvec>:
    800062f0:	7111                	addi	sp,sp,-256
    800062f2:	e006                	sd	ra,0(sp)
    800062f4:	e40a                	sd	sp,8(sp)
    800062f6:	e80e                	sd	gp,16(sp)
    800062f8:	ec12                	sd	tp,24(sp)
    800062fa:	f016                	sd	t0,32(sp)
    800062fc:	f41a                	sd	t1,40(sp)
    800062fe:	f81e                	sd	t2,48(sp)
    80006300:	fc22                	sd	s0,56(sp)
    80006302:	e0a6                	sd	s1,64(sp)
    80006304:	e4aa                	sd	a0,72(sp)
    80006306:	e8ae                	sd	a1,80(sp)
    80006308:	ecb2                	sd	a2,88(sp)
    8000630a:	f0b6                	sd	a3,96(sp)
    8000630c:	f4ba                	sd	a4,104(sp)
    8000630e:	f8be                	sd	a5,112(sp)
    80006310:	fcc2                	sd	a6,120(sp)
    80006312:	e146                	sd	a7,128(sp)
    80006314:	e54a                	sd	s2,136(sp)
    80006316:	e94e                	sd	s3,144(sp)
    80006318:	ed52                	sd	s4,152(sp)
    8000631a:	f156                	sd	s5,160(sp)
    8000631c:	f55a                	sd	s6,168(sp)
    8000631e:	f95e                	sd	s7,176(sp)
    80006320:	fd62                	sd	s8,184(sp)
    80006322:	e1e6                	sd	s9,192(sp)
    80006324:	e5ea                	sd	s10,200(sp)
    80006326:	e9ee                	sd	s11,208(sp)
    80006328:	edf2                	sd	t3,216(sp)
    8000632a:	f1f6                	sd	t4,224(sp)
    8000632c:	f5fa                	sd	t5,232(sp)
    8000632e:	f9fe                	sd	t6,240(sp)
    80006330:	d49fc0ef          	jal	ra,80003078 <kerneltrap>
    80006334:	6082                	ld	ra,0(sp)
    80006336:	6122                	ld	sp,8(sp)
    80006338:	61c2                	ld	gp,16(sp)
    8000633a:	7282                	ld	t0,32(sp)
    8000633c:	7322                	ld	t1,40(sp)
    8000633e:	73c2                	ld	t2,48(sp)
    80006340:	7462                	ld	s0,56(sp)
    80006342:	6486                	ld	s1,64(sp)
    80006344:	6526                	ld	a0,72(sp)
    80006346:	65c6                	ld	a1,80(sp)
    80006348:	6666                	ld	a2,88(sp)
    8000634a:	7686                	ld	a3,96(sp)
    8000634c:	7726                	ld	a4,104(sp)
    8000634e:	77c6                	ld	a5,112(sp)
    80006350:	7866                	ld	a6,120(sp)
    80006352:	688a                	ld	a7,128(sp)
    80006354:	692a                	ld	s2,136(sp)
    80006356:	69ca                	ld	s3,144(sp)
    80006358:	6a6a                	ld	s4,152(sp)
    8000635a:	7a8a                	ld	s5,160(sp)
    8000635c:	7b2a                	ld	s6,168(sp)
    8000635e:	7bca                	ld	s7,176(sp)
    80006360:	7c6a                	ld	s8,184(sp)
    80006362:	6c8e                	ld	s9,192(sp)
    80006364:	6d2e                	ld	s10,200(sp)
    80006366:	6dce                	ld	s11,208(sp)
    80006368:	6e6e                	ld	t3,216(sp)
    8000636a:	7e8e                	ld	t4,224(sp)
    8000636c:	7f2e                	ld	t5,232(sp)
    8000636e:	7fce                	ld	t6,240(sp)
    80006370:	6111                	addi	sp,sp,256
    80006372:	10200073          	sret
    80006376:	00000013          	nop
    8000637a:	00000013          	nop
    8000637e:	0001                	nop

0000000080006380 <timervec>:
    80006380:	34051573          	csrrw	a0,mscratch,a0
    80006384:	e10c                	sd	a1,0(a0)
    80006386:	e510                	sd	a2,8(a0)
    80006388:	e914                	sd	a3,16(a0)
    8000638a:	6d0c                	ld	a1,24(a0)
    8000638c:	7110                	ld	a2,32(a0)
    8000638e:	6194                	ld	a3,0(a1)
    80006390:	96b2                	add	a3,a3,a2
    80006392:	e194                	sd	a3,0(a1)
    80006394:	4589                	li	a1,2
    80006396:	14459073          	csrw	sip,a1
    8000639a:	6914                	ld	a3,16(a0)
    8000639c:	6510                	ld	a2,8(a0)
    8000639e:	610c                	ld	a1,0(a0)
    800063a0:	34051573          	csrrw	a0,mscratch,a0
    800063a4:	30200073          	mret
	...

00000000800063aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063aa:	1141                	addi	sp,sp,-16
    800063ac:	e422                	sd	s0,8(sp)
    800063ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063b0:	0c0007b7          	lui	a5,0xc000
    800063b4:	4705                	li	a4,1
    800063b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063b8:	c3d8                	sw	a4,4(a5)
}
    800063ba:	6422                	ld	s0,8(sp)
    800063bc:	0141                	addi	sp,sp,16
    800063be:	8082                	ret

00000000800063c0 <plicinithart>:

void
plicinithart(void)
{
    800063c0:	1141                	addi	sp,sp,-16
    800063c2:	e406                	sd	ra,8(sp)
    800063c4:	e022                	sd	s0,0(sp)
    800063c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063c8:	ffffc097          	auipc	ra,0xffffc
    800063cc:	9e0080e7          	jalr	-1568(ra) # 80001da8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063d0:	0085171b          	slliw	a4,a0,0x8
    800063d4:	0c0027b7          	lui	a5,0xc002
    800063d8:	97ba                	add	a5,a5,a4
    800063da:	40200713          	li	a4,1026
    800063de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063e2:	00d5151b          	slliw	a0,a0,0xd
    800063e6:	0c2017b7          	lui	a5,0xc201
    800063ea:	953e                	add	a0,a0,a5
    800063ec:	00052023          	sw	zero,0(a0)
}
    800063f0:	60a2                	ld	ra,8(sp)
    800063f2:	6402                	ld	s0,0(sp)
    800063f4:	0141                	addi	sp,sp,16
    800063f6:	8082                	ret

00000000800063f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063f8:	1141                	addi	sp,sp,-16
    800063fa:	e406                	sd	ra,8(sp)
    800063fc:	e022                	sd	s0,0(sp)
    800063fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006400:	ffffc097          	auipc	ra,0xffffc
    80006404:	9a8080e7          	jalr	-1624(ra) # 80001da8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006408:	00d5179b          	slliw	a5,a0,0xd
    8000640c:	0c201537          	lui	a0,0xc201
    80006410:	953e                	add	a0,a0,a5
  return irq;
}
    80006412:	4148                	lw	a0,4(a0)
    80006414:	60a2                	ld	ra,8(sp)
    80006416:	6402                	ld	s0,0(sp)
    80006418:	0141                	addi	sp,sp,16
    8000641a:	8082                	ret

000000008000641c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000641c:	1101                	addi	sp,sp,-32
    8000641e:	ec06                	sd	ra,24(sp)
    80006420:	e822                	sd	s0,16(sp)
    80006422:	e426                	sd	s1,8(sp)
    80006424:	1000                	addi	s0,sp,32
    80006426:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006428:	ffffc097          	auipc	ra,0xffffc
    8000642c:	980080e7          	jalr	-1664(ra) # 80001da8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006430:	00d5151b          	slliw	a0,a0,0xd
    80006434:	0c2017b7          	lui	a5,0xc201
    80006438:	97aa                	add	a5,a5,a0
    8000643a:	c3c4                	sw	s1,4(a5)
}
    8000643c:	60e2                	ld	ra,24(sp)
    8000643e:	6442                	ld	s0,16(sp)
    80006440:	64a2                	ld	s1,8(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret

0000000080006446 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006446:	1141                	addi	sp,sp,-16
    80006448:	e406                	sd	ra,8(sp)
    8000644a:	e022                	sd	s0,0(sp)
    8000644c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000644e:	479d                	li	a5,7
    80006450:	06a7c963          	blt	a5,a0,800064c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006454:	0001d797          	auipc	a5,0x1d
    80006458:	bac78793          	addi	a5,a5,-1108 # 80023000 <disk>
    8000645c:	00a78733          	add	a4,a5,a0
    80006460:	6789                	lui	a5,0x2
    80006462:	97ba                	add	a5,a5,a4
    80006464:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006468:	e7ad                	bnez	a5,800064d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000646a:	00451793          	slli	a5,a0,0x4
    8000646e:	0001f717          	auipc	a4,0x1f
    80006472:	b9270713          	addi	a4,a4,-1134 # 80025000 <disk+0x2000>
    80006476:	6314                	ld	a3,0(a4)
    80006478:	96be                	add	a3,a3,a5
    8000647a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000647e:	6314                	ld	a3,0(a4)
    80006480:	96be                	add	a3,a3,a5
    80006482:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006486:	6314                	ld	a3,0(a4)
    80006488:	96be                	add	a3,a3,a5
    8000648a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000648e:	6318                	ld	a4,0(a4)
    80006490:	97ba                	add	a5,a5,a4
    80006492:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006496:	0001d797          	auipc	a5,0x1d
    8000649a:	b6a78793          	addi	a5,a5,-1174 # 80023000 <disk>
    8000649e:	97aa                	add	a5,a5,a0
    800064a0:	6509                	lui	a0,0x2
    800064a2:	953e                	add	a0,a0,a5
    800064a4:	4785                	li	a5,1
    800064a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800064aa:	0001f517          	auipc	a0,0x1f
    800064ae:	b6e50513          	addi	a0,a0,-1170 # 80025018 <disk+0x2018>
    800064b2:	ffffc097          	auipc	ra,0xffffc
    800064b6:	394080e7          	jalr	916(ra) # 80002846 <wakeup>
}
    800064ba:	60a2                	ld	ra,8(sp)
    800064bc:	6402                	ld	s0,0(sp)
    800064be:	0141                	addi	sp,sp,16
    800064c0:	8082                	ret
    panic("free_desc 1");
    800064c2:	00002517          	auipc	a0,0x2
    800064c6:	35650513          	addi	a0,a0,854 # 80008818 <syscalls+0x338>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	074080e7          	jalr	116(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	35650513          	addi	a0,a0,854 # 80008828 <syscalls+0x348>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	064080e7          	jalr	100(ra) # 8000053e <panic>

00000000800064e2 <virtio_disk_init>:
{
    800064e2:	1101                	addi	sp,sp,-32
    800064e4:	ec06                	sd	ra,24(sp)
    800064e6:	e822                	sd	s0,16(sp)
    800064e8:	e426                	sd	s1,8(sp)
    800064ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064ec:	00002597          	auipc	a1,0x2
    800064f0:	34c58593          	addi	a1,a1,844 # 80008838 <syscalls+0x358>
    800064f4:	0001f517          	auipc	a0,0x1f
    800064f8:	c3450513          	addi	a0,a0,-972 # 80025128 <disk+0x2128>
    800064fc:	ffffa097          	auipc	ra,0xffffa
    80006500:	658080e7          	jalr	1624(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006504:	100017b7          	lui	a5,0x10001
    80006508:	4398                	lw	a4,0(a5)
    8000650a:	2701                	sext.w	a4,a4
    8000650c:	747277b7          	lui	a5,0x74727
    80006510:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006514:	0ef71163          	bne	a4,a5,800065f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006518:	100017b7          	lui	a5,0x10001
    8000651c:	43dc                	lw	a5,4(a5)
    8000651e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006520:	4705                	li	a4,1
    80006522:	0ce79a63          	bne	a5,a4,800065f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006526:	100017b7          	lui	a5,0x10001
    8000652a:	479c                	lw	a5,8(a5)
    8000652c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000652e:	4709                	li	a4,2
    80006530:	0ce79363          	bne	a5,a4,800065f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006534:	100017b7          	lui	a5,0x10001
    80006538:	47d8                	lw	a4,12(a5)
    8000653a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000653c:	554d47b7          	lui	a5,0x554d4
    80006540:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006544:	0af71963          	bne	a4,a5,800065f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006548:	100017b7          	lui	a5,0x10001
    8000654c:	4705                	li	a4,1
    8000654e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006550:	470d                	li	a4,3
    80006552:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006554:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006556:	c7ffe737          	lui	a4,0xc7ffe
    8000655a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000655e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006560:	2701                	sext.w	a4,a4
    80006562:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006564:	472d                	li	a4,11
    80006566:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006568:	473d                	li	a4,15
    8000656a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000656c:	6705                	lui	a4,0x1
    8000656e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006570:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006574:	5bdc                	lw	a5,52(a5)
    80006576:	2781                	sext.w	a5,a5
  if(max == 0)
    80006578:	c7d9                	beqz	a5,80006606 <virtio_disk_init+0x124>
  if(max < NUM)
    8000657a:	471d                	li	a4,7
    8000657c:	08f77d63          	bgeu	a4,a5,80006616 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006580:	100014b7          	lui	s1,0x10001
    80006584:	47a1                	li	a5,8
    80006586:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006588:	6609                	lui	a2,0x2
    8000658a:	4581                	li	a1,0
    8000658c:	0001d517          	auipc	a0,0x1d
    80006590:	a7450513          	addi	a0,a0,-1420 # 80023000 <disk>
    80006594:	ffffa097          	auipc	ra,0xffffa
    80006598:	770080e7          	jalr	1904(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000659c:	0001d717          	auipc	a4,0x1d
    800065a0:	a6470713          	addi	a4,a4,-1436 # 80023000 <disk>
    800065a4:	00c75793          	srli	a5,a4,0xc
    800065a8:	2781                	sext.w	a5,a5
    800065aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800065ac:	0001f797          	auipc	a5,0x1f
    800065b0:	a5478793          	addi	a5,a5,-1452 # 80025000 <disk+0x2000>
    800065b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800065b6:	0001d717          	auipc	a4,0x1d
    800065ba:	aca70713          	addi	a4,a4,-1334 # 80023080 <disk+0x80>
    800065be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800065c0:	0001e717          	auipc	a4,0x1e
    800065c4:	a4070713          	addi	a4,a4,-1472 # 80024000 <disk+0x1000>
    800065c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065ca:	4705                	li	a4,1
    800065cc:	00e78c23          	sb	a4,24(a5)
    800065d0:	00e78ca3          	sb	a4,25(a5)
    800065d4:	00e78d23          	sb	a4,26(a5)
    800065d8:	00e78da3          	sb	a4,27(a5)
    800065dc:	00e78e23          	sb	a4,28(a5)
    800065e0:	00e78ea3          	sb	a4,29(a5)
    800065e4:	00e78f23          	sb	a4,30(a5)
    800065e8:	00e78fa3          	sb	a4,31(a5)
}
    800065ec:	60e2                	ld	ra,24(sp)
    800065ee:	6442                	ld	s0,16(sp)
    800065f0:	64a2                	ld	s1,8(sp)
    800065f2:	6105                	addi	sp,sp,32
    800065f4:	8082                	ret
    panic("could not find virtio disk");
    800065f6:	00002517          	auipc	a0,0x2
    800065fa:	25250513          	addi	a0,a0,594 # 80008848 <syscalls+0x368>
    800065fe:	ffffa097          	auipc	ra,0xffffa
    80006602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006606:	00002517          	auipc	a0,0x2
    8000660a:	26250513          	addi	a0,a0,610 # 80008868 <syscalls+0x388>
    8000660e:	ffffa097          	auipc	ra,0xffffa
    80006612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006616:	00002517          	auipc	a0,0x2
    8000661a:	27250513          	addi	a0,a0,626 # 80008888 <syscalls+0x3a8>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>

0000000080006626 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006626:	7159                	addi	sp,sp,-112
    80006628:	f486                	sd	ra,104(sp)
    8000662a:	f0a2                	sd	s0,96(sp)
    8000662c:	eca6                	sd	s1,88(sp)
    8000662e:	e8ca                	sd	s2,80(sp)
    80006630:	e4ce                	sd	s3,72(sp)
    80006632:	e0d2                	sd	s4,64(sp)
    80006634:	fc56                	sd	s5,56(sp)
    80006636:	f85a                	sd	s6,48(sp)
    80006638:	f45e                	sd	s7,40(sp)
    8000663a:	f062                	sd	s8,32(sp)
    8000663c:	ec66                	sd	s9,24(sp)
    8000663e:	e86a                	sd	s10,16(sp)
    80006640:	1880                	addi	s0,sp,112
    80006642:	892a                	mv	s2,a0
    80006644:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006646:	00c52c83          	lw	s9,12(a0)
    8000664a:	001c9c9b          	slliw	s9,s9,0x1
    8000664e:	1c82                	slli	s9,s9,0x20
    80006650:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006654:	0001f517          	auipc	a0,0x1f
    80006658:	ad450513          	addi	a0,a0,-1324 # 80025128 <disk+0x2128>
    8000665c:	ffffa097          	auipc	ra,0xffffa
    80006660:	588080e7          	jalr	1416(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006664:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006666:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006668:	0001db97          	auipc	s7,0x1d
    8000666c:	998b8b93          	addi	s7,s7,-1640 # 80023000 <disk>
    80006670:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006672:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006674:	8a4e                	mv	s4,s3
    80006676:	a051                	j	800066fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006678:	00fb86b3          	add	a3,s7,a5
    8000667c:	96da                	add	a3,a3,s6
    8000667e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006682:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006684:	0207c563          	bltz	a5,800066ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006688:	2485                	addiw	s1,s1,1
    8000668a:	0711                	addi	a4,a4,4
    8000668c:	25548063          	beq	s1,s5,800068cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006690:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006692:	0001f697          	auipc	a3,0x1f
    80006696:	98668693          	addi	a3,a3,-1658 # 80025018 <disk+0x2018>
    8000669a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000669c:	0006c583          	lbu	a1,0(a3)
    800066a0:	fde1                	bnez	a1,80006678 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800066a2:	2785                	addiw	a5,a5,1
    800066a4:	0685                	addi	a3,a3,1
    800066a6:	ff879be3          	bne	a5,s8,8000669c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800066aa:	57fd                	li	a5,-1
    800066ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800066ae:	02905a63          	blez	s1,800066e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066b2:	f9042503          	lw	a0,-112(s0)
    800066b6:	00000097          	auipc	ra,0x0
    800066ba:	d90080e7          	jalr	-624(ra) # 80006446 <free_desc>
      for(int j = 0; j < i; j++)
    800066be:	4785                	li	a5,1
    800066c0:	0297d163          	bge	a5,s1,800066e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066c4:	f9442503          	lw	a0,-108(s0)
    800066c8:	00000097          	auipc	ra,0x0
    800066cc:	d7e080e7          	jalr	-642(ra) # 80006446 <free_desc>
      for(int j = 0; j < i; j++)
    800066d0:	4789                	li	a5,2
    800066d2:	0097d863          	bge	a5,s1,800066e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066d6:	f9842503          	lw	a0,-104(s0)
    800066da:	00000097          	auipc	ra,0x0
    800066de:	d6c080e7          	jalr	-660(ra) # 80006446 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066e2:	0001f597          	auipc	a1,0x1f
    800066e6:	a4658593          	addi	a1,a1,-1466 # 80025128 <disk+0x2128>
    800066ea:	0001f517          	auipc	a0,0x1f
    800066ee:	92e50513          	addi	a0,a0,-1746 # 80025018 <disk+0x2018>
    800066f2:	ffffc097          	auipc	ra,0xffffc
    800066f6:	fac080e7          	jalr	-84(ra) # 8000269e <sleep>
  for(int i = 0; i < 3; i++){
    800066fa:	f9040713          	addi	a4,s0,-112
    800066fe:	84ce                	mv	s1,s3
    80006700:	bf41                	j	80006690 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006702:	20058713          	addi	a4,a1,512
    80006706:	00471693          	slli	a3,a4,0x4
    8000670a:	0001d717          	auipc	a4,0x1d
    8000670e:	8f670713          	addi	a4,a4,-1802 # 80023000 <disk>
    80006712:	9736                	add	a4,a4,a3
    80006714:	4685                	li	a3,1
    80006716:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000671a:	20058713          	addi	a4,a1,512
    8000671e:	00471693          	slli	a3,a4,0x4
    80006722:	0001d717          	auipc	a4,0x1d
    80006726:	8de70713          	addi	a4,a4,-1826 # 80023000 <disk>
    8000672a:	9736                	add	a4,a4,a3
    8000672c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006730:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006734:	7679                	lui	a2,0xffffe
    80006736:	963e                	add	a2,a2,a5
    80006738:	0001f697          	auipc	a3,0x1f
    8000673c:	8c868693          	addi	a3,a3,-1848 # 80025000 <disk+0x2000>
    80006740:	6298                	ld	a4,0(a3)
    80006742:	9732                	add	a4,a4,a2
    80006744:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006746:	6298                	ld	a4,0(a3)
    80006748:	9732                	add	a4,a4,a2
    8000674a:	4541                	li	a0,16
    8000674c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000674e:	6298                	ld	a4,0(a3)
    80006750:	9732                	add	a4,a4,a2
    80006752:	4505                	li	a0,1
    80006754:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006758:	f9442703          	lw	a4,-108(s0)
    8000675c:	6288                	ld	a0,0(a3)
    8000675e:	962a                	add	a2,a2,a0
    80006760:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006764:	0712                	slli	a4,a4,0x4
    80006766:	6290                	ld	a2,0(a3)
    80006768:	963a                	add	a2,a2,a4
    8000676a:	05890513          	addi	a0,s2,88
    8000676e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006770:	6294                	ld	a3,0(a3)
    80006772:	96ba                	add	a3,a3,a4
    80006774:	40000613          	li	a2,1024
    80006778:	c690                	sw	a2,8(a3)
  if(write)
    8000677a:	140d0063          	beqz	s10,800068ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000677e:	0001f697          	auipc	a3,0x1f
    80006782:	8826b683          	ld	a3,-1918(a3) # 80025000 <disk+0x2000>
    80006786:	96ba                	add	a3,a3,a4
    80006788:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000678c:	0001d817          	auipc	a6,0x1d
    80006790:	87480813          	addi	a6,a6,-1932 # 80023000 <disk>
    80006794:	0001f517          	auipc	a0,0x1f
    80006798:	86c50513          	addi	a0,a0,-1940 # 80025000 <disk+0x2000>
    8000679c:	6114                	ld	a3,0(a0)
    8000679e:	96ba                	add	a3,a3,a4
    800067a0:	00c6d603          	lhu	a2,12(a3)
    800067a4:	00166613          	ori	a2,a2,1
    800067a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067ac:	f9842683          	lw	a3,-104(s0)
    800067b0:	6110                	ld	a2,0(a0)
    800067b2:	9732                	add	a4,a4,a2
    800067b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067b8:	20058613          	addi	a2,a1,512
    800067bc:	0612                	slli	a2,a2,0x4
    800067be:	9642                	add	a2,a2,a6
    800067c0:	577d                	li	a4,-1
    800067c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067c6:	00469713          	slli	a4,a3,0x4
    800067ca:	6114                	ld	a3,0(a0)
    800067cc:	96ba                	add	a3,a3,a4
    800067ce:	03078793          	addi	a5,a5,48
    800067d2:	97c2                	add	a5,a5,a6
    800067d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067d6:	611c                	ld	a5,0(a0)
    800067d8:	97ba                	add	a5,a5,a4
    800067da:	4685                	li	a3,1
    800067dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067de:	611c                	ld	a5,0(a0)
    800067e0:	97ba                	add	a5,a5,a4
    800067e2:	4809                	li	a6,2
    800067e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800067e8:	611c                	ld	a5,0(a0)
    800067ea:	973e                	add	a4,a4,a5
    800067ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067f8:	6518                	ld	a4,8(a0)
    800067fa:	00275783          	lhu	a5,2(a4)
    800067fe:	8b9d                	andi	a5,a5,7
    80006800:	0786                	slli	a5,a5,0x1
    80006802:	97ba                	add	a5,a5,a4
    80006804:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006808:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000680c:	6518                	ld	a4,8(a0)
    8000680e:	00275783          	lhu	a5,2(a4)
    80006812:	2785                	addiw	a5,a5,1
    80006814:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006818:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000681c:	100017b7          	lui	a5,0x10001
    80006820:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006824:	00492703          	lw	a4,4(s2)
    80006828:	4785                	li	a5,1
    8000682a:	02f71163          	bne	a4,a5,8000684c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000682e:	0001f997          	auipc	s3,0x1f
    80006832:	8fa98993          	addi	s3,s3,-1798 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006836:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006838:	85ce                	mv	a1,s3
    8000683a:	854a                	mv	a0,s2
    8000683c:	ffffc097          	auipc	ra,0xffffc
    80006840:	e62080e7          	jalr	-414(ra) # 8000269e <sleep>
  while(b->disk == 1) {
    80006844:	00492783          	lw	a5,4(s2)
    80006848:	fe9788e3          	beq	a5,s1,80006838 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000684c:	f9042903          	lw	s2,-112(s0)
    80006850:	20090793          	addi	a5,s2,512
    80006854:	00479713          	slli	a4,a5,0x4
    80006858:	0001c797          	auipc	a5,0x1c
    8000685c:	7a878793          	addi	a5,a5,1960 # 80023000 <disk>
    80006860:	97ba                	add	a5,a5,a4
    80006862:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006866:	0001e997          	auipc	s3,0x1e
    8000686a:	79a98993          	addi	s3,s3,1946 # 80025000 <disk+0x2000>
    8000686e:	00491713          	slli	a4,s2,0x4
    80006872:	0009b783          	ld	a5,0(s3)
    80006876:	97ba                	add	a5,a5,a4
    80006878:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000687c:	854a                	mv	a0,s2
    8000687e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006882:	00000097          	auipc	ra,0x0
    80006886:	bc4080e7          	jalr	-1084(ra) # 80006446 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000688a:	8885                	andi	s1,s1,1
    8000688c:	f0ed                	bnez	s1,8000686e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000688e:	0001f517          	auipc	a0,0x1f
    80006892:	89a50513          	addi	a0,a0,-1894 # 80025128 <disk+0x2128>
    80006896:	ffffa097          	auipc	ra,0xffffa
    8000689a:	414080e7          	jalr	1044(ra) # 80000caa <release>
}
    8000689e:	70a6                	ld	ra,104(sp)
    800068a0:	7406                	ld	s0,96(sp)
    800068a2:	64e6                	ld	s1,88(sp)
    800068a4:	6946                	ld	s2,80(sp)
    800068a6:	69a6                	ld	s3,72(sp)
    800068a8:	6a06                	ld	s4,64(sp)
    800068aa:	7ae2                	ld	s5,56(sp)
    800068ac:	7b42                	ld	s6,48(sp)
    800068ae:	7ba2                	ld	s7,40(sp)
    800068b0:	7c02                	ld	s8,32(sp)
    800068b2:	6ce2                	ld	s9,24(sp)
    800068b4:	6d42                	ld	s10,16(sp)
    800068b6:	6165                	addi	sp,sp,112
    800068b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068ba:	0001e697          	auipc	a3,0x1e
    800068be:	7466b683          	ld	a3,1862(a3) # 80025000 <disk+0x2000>
    800068c2:	96ba                	add	a3,a3,a4
    800068c4:	4609                	li	a2,2
    800068c6:	00c69623          	sh	a2,12(a3)
    800068ca:	b5c9                	j	8000678c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068cc:	f9042583          	lw	a1,-112(s0)
    800068d0:	20058793          	addi	a5,a1,512
    800068d4:	0792                	slli	a5,a5,0x4
    800068d6:	0001c517          	auipc	a0,0x1c
    800068da:	7d250513          	addi	a0,a0,2002 # 800230a8 <disk+0xa8>
    800068de:	953e                	add	a0,a0,a5
  if(write)
    800068e0:	e20d11e3          	bnez	s10,80006702 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800068e4:	20058713          	addi	a4,a1,512
    800068e8:	00471693          	slli	a3,a4,0x4
    800068ec:	0001c717          	auipc	a4,0x1c
    800068f0:	71470713          	addi	a4,a4,1812 # 80023000 <disk>
    800068f4:	9736                	add	a4,a4,a3
    800068f6:	0a072423          	sw	zero,168(a4)
    800068fa:	b505                	j	8000671a <virtio_disk_rw+0xf4>

00000000800068fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068fc:	1101                	addi	sp,sp,-32
    800068fe:	ec06                	sd	ra,24(sp)
    80006900:	e822                	sd	s0,16(sp)
    80006902:	e426                	sd	s1,8(sp)
    80006904:	e04a                	sd	s2,0(sp)
    80006906:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006908:	0001f517          	auipc	a0,0x1f
    8000690c:	82050513          	addi	a0,a0,-2016 # 80025128 <disk+0x2128>
    80006910:	ffffa097          	auipc	ra,0xffffa
    80006914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006918:	10001737          	lui	a4,0x10001
    8000691c:	533c                	lw	a5,96(a4)
    8000691e:	8b8d                	andi	a5,a5,3
    80006920:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006922:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006926:	0001e797          	auipc	a5,0x1e
    8000692a:	6da78793          	addi	a5,a5,1754 # 80025000 <disk+0x2000>
    8000692e:	6b94                	ld	a3,16(a5)
    80006930:	0207d703          	lhu	a4,32(a5)
    80006934:	0026d783          	lhu	a5,2(a3)
    80006938:	06f70163          	beq	a4,a5,8000699a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000693c:	0001c917          	auipc	s2,0x1c
    80006940:	6c490913          	addi	s2,s2,1732 # 80023000 <disk>
    80006944:	0001e497          	auipc	s1,0x1e
    80006948:	6bc48493          	addi	s1,s1,1724 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000694c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006950:	6898                	ld	a4,16(s1)
    80006952:	0204d783          	lhu	a5,32(s1)
    80006956:	8b9d                	andi	a5,a5,7
    80006958:	078e                	slli	a5,a5,0x3
    8000695a:	97ba                	add	a5,a5,a4
    8000695c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000695e:	20078713          	addi	a4,a5,512
    80006962:	0712                	slli	a4,a4,0x4
    80006964:	974a                	add	a4,a4,s2
    80006966:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000696a:	e731                	bnez	a4,800069b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000696c:	20078793          	addi	a5,a5,512
    80006970:	0792                	slli	a5,a5,0x4
    80006972:	97ca                	add	a5,a5,s2
    80006974:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006976:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000697a:	ffffc097          	auipc	ra,0xffffc
    8000697e:	ecc080e7          	jalr	-308(ra) # 80002846 <wakeup>

    disk.used_idx += 1;
    80006982:	0204d783          	lhu	a5,32(s1)
    80006986:	2785                	addiw	a5,a5,1
    80006988:	17c2                	slli	a5,a5,0x30
    8000698a:	93c1                	srli	a5,a5,0x30
    8000698c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006990:	6898                	ld	a4,16(s1)
    80006992:	00275703          	lhu	a4,2(a4)
    80006996:	faf71be3          	bne	a4,a5,8000694c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000699a:	0001e517          	auipc	a0,0x1e
    8000699e:	78e50513          	addi	a0,a0,1934 # 80025128 <disk+0x2128>
    800069a2:	ffffa097          	auipc	ra,0xffffa
    800069a6:	308080e7          	jalr	776(ra) # 80000caa <release>
}
    800069aa:	60e2                	ld	ra,24(sp)
    800069ac:	6442                	ld	s0,16(sp)
    800069ae:	64a2                	ld	s1,8(sp)
    800069b0:	6902                	ld	s2,0(sp)
    800069b2:	6105                	addi	sp,sp,32
    800069b4:	8082                	ret
      panic("virtio_disk_intr status");
    800069b6:	00002517          	auipc	a0,0x2
    800069ba:	ef250513          	addi	a0,a0,-270 # 800088a8 <syscalls+0x3c8>
    800069be:	ffffa097          	auipc	ra,0xffffa
    800069c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>

00000000800069c6 <cas>:
    800069c6:	100522af          	lr.w	t0,(a0)
    800069ca:	00b29563          	bne	t0,a1,800069d4 <fail>
    800069ce:	18c5252f          	sc.w	a0,a2,(a0)
    800069d2:	8082                	ret

00000000800069d4 <fail>:
    800069d4:	4505                	li	a0,1
    800069d6:	8082                	ret
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
