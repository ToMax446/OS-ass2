
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
    80000068:	33c78793          	addi	a5,a5,828 # 800063a0 <timervec>
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
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
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
    80000130:	b58080e7          	jalr	-1192(ra) # 80002c84 <either_copyin>
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
    800001c8:	c12080e7          	jalr	-1006(ra) # 80001dd6 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	50a080e7          	jalr	1290(ra) # 800026de <sleep>
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
    80000214:	a1e080e7          	jalr	-1506(ra) # 80002c2e <either_copyout>
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
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
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
    800002f6:	9e8080e7          	jalr	-1560(ra) # 80002cda <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    8000044a:	462080e7          	jalr	1122(ra) # 800028a8 <wakeup>
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
    8000047c:	7c878793          	addi	a5,a5,1992 # 80021c40 <devsw>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
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
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
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
    800008a4:	008080e7          	jalr	8(ra) # 800028a8 <wakeup>
    
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
    80000930:	db2080e7          	jalr	-590(ra) # 800026de <sleep>
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
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
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
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
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
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

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
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
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
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
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
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
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
    80000b82:	23c080e7          	jalr	572(ra) # 80001dba <mycpu>
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
    80000bb4:	20a080e7          	jalr	522(ra) # 80001dba <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	1fe080e7          	jalr	510(ra) # 80001dba <mycpu>
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
    80000bd8:	1e6080e7          	jalr	486(ra) # 80001dba <mycpu>
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
    80000c18:	1a6080e7          	jalr	422(ra) # 80001dba <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	17a080e7          	jalr	378(ra) # 80001dba <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1){
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");}
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");}
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk)){
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	f14080e7          	jalr	-236(ra) # 80001daa <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ef8080e7          	jalr	-264(ra) # 80001daa <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	fb4080e7          	jalr	-76(ra) # 80002e88 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	504080e7          	jalr	1284(ra) # 800063e0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	53e080e7          	jalr	1342(ra) # 80002422 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	ce2080e7          	jalr	-798(ra) # 80001c26 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	f14080e7          	jalr	-236(ra) # 80002e60 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	f34080e7          	jalr	-204(ra) # 80002e88 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	46e080e7          	jalr	1134(ra) # 800063ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	47c080e7          	jalr	1148(ra) # 800063e0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	65e080e7          	jalr	1630(ra) # 800035ca <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	cee080e7          	jalr	-786(ra) # 80003c62 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c98080e7          	jalr	-872(ra) # 80004c14 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	57e080e7          	jalr	1406(ra) # 80006502 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	1d8080e7          	jalr	472(ra) # 80002164 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00001097          	auipc	ra,0x1
    80001244:	950080e7          	jalr	-1712(ra) # 80001b90 <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <remove_cs>:
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

int
remove_cs(struct proc *pred, struct proc *curr, struct proc *p){ //created
    8000183e:	715d                	addi	sp,sp,-80
    80001840:	e486                	sd	ra,72(sp)
    80001842:	e0a2                	sd	s0,64(sp)
    80001844:	fc26                	sd	s1,56(sp)
    80001846:	f84a                	sd	s2,48(sp)
    80001848:	f44e                	sd	s3,40(sp)
    8000184a:	f052                	sd	s4,32(sp)
    8000184c:	ec56                	sd	s5,24(sp)
    8000184e:	e85a                	sd	s6,16(sp)
    80001850:	e45e                	sd	s7,8(sp)
    80001852:	0880                	addi	s0,sp,80
int ret=-1;
//printf("remove cs p->index=%d\n", p->index);
//printf("pred: %d\ncurr: %d\n", pred->index, curr->index);
int curr_inx=curr->index;
    80001854:	0385a903          	lw	s2,56(a1) # 4000038 <_entry-0x7bffffc8>
while (curr_inx != -1) {
    80001858:	57fd                	li	a5,-1
    8000185a:	08f90563          	beq	s2,a5,800018e4 <remove_cs+0xa6>
    8000185e:	8baa                	mv	s7,a0
    80001860:	84ae                	mv	s1,a1
    80001862:	8a32                	mv	s4,a2
    release(&pred->linked_list_lock);
    //printf("%d\n",132);
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    pred = curr;
    curr_inx =curr->next;
    if(curr_inx!=-1){
    80001864:	5afd                	li	s5,-1
    80001866:	18800b13          	li	s6,392
      curr = &proc[curr->next];
    8000186a:	00010997          	auipc	s3,0x10
    8000186e:	f8e98993          	addi	s3,s3,-114 # 800117f8 <proc>
    80001872:	a099                	j	800018b8 <remove_cs+0x7a>
      pred->next = curr->next;
    80001874:	5cdc                	lw	a5,60(s1)
    80001876:	2781                	sext.w	a5,a5
    80001878:	02fbae23          	sw	a5,60(s7) # fffffffffffff03c <end+0xffffffff7ffd903c>
      ret = curr->index;
    8000187c:	0384a903          	lw	s2,56(s1)
      release(&curr->linked_list_lock);
    80001880:	04048513          	addi	a0,s1,64
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	414080e7          	jalr	1044(ra) # 80000c98 <release>
      release(&pred->linked_list_lock);
    8000188c:	040b8513          	addi	a0,s7,64
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	408080e7          	jalr	1032(ra) # 80000c98 <release>
      return ret;
    80001898:	a0b1                	j	800018e4 <remove_cs+0xa6>
      curr = &proc[curr->next];
    8000189a:	5cc8                	lw	a0,60(s1)
    8000189c:	2501                	sext.w	a0,a0
    8000189e:	03650533          	mul	a0,a0,s6
    800018a2:	01350933          	add	s2,a0,s3
      acquire(&curr->linked_list_lock);
    800018a6:	04050513          	addi	a0,a0,64
    800018aa:	954e                	add	a0,a0,s3
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	338080e7          	jalr	824(ra) # 80000be4 <acquire>
    800018b4:	8ba6                	mv	s7,s1
      curr = &proc[curr->next];
    800018b6:	84ca                	mv	s1,s2
  if ( p->index == curr->index) {
    800018b8:	038a2703          	lw	a4,56(s4) # fffffffffffff038 <end+0xffffffff7ffd9038>
    800018bc:	5c9c                	lw	a5,56(s1)
    800018be:	faf70be3          	beq	a4,a5,80001874 <remove_cs+0x36>
    release(&pred->linked_list_lock);
    800018c2:	040b8513          	addi	a0,s7,64
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	3d2080e7          	jalr	978(ra) # 80000c98 <release>
    curr_inx =curr->next;
    800018ce:	03c4a903          	lw	s2,60(s1)
    800018d2:	2901                	sext.w	s2,s2
    if(curr_inx!=-1){
    800018d4:	fd5913e3          	bne	s2,s5,8000189a <remove_cs+0x5c>
    }
    else{
      release(&curr->linked_list_lock);
    800018d8:	04048513          	addi	a0,s1,64
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	3bc080e7          	jalr	956(ra) # 80000c98 <release>
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    //printf("after lock\n");
  }
  // panic("item not found");
  return -1;
}
    800018e4:	854a                	mv	a0,s2
    800018e6:	60a6                	ld	ra,72(sp)
    800018e8:	6406                	ld	s0,64(sp)
    800018ea:	74e2                	ld	s1,56(sp)
    800018ec:	7942                	ld	s2,48(sp)
    800018ee:	79a2                	ld	s3,40(sp)
    800018f0:	7a02                	ld	s4,32(sp)
    800018f2:	6ae2                	ld	s5,24(sp)
    800018f4:	6b42                	ld	s6,16(sp)
    800018f6:	6ba2                	ld	s7,8(sp)
    800018f8:	6161                	addi	sp,sp,80
    800018fa:	8082                	ret

00000000800018fc <remove_from_list>:

int remove_from_list(int p_index, int *list,struct spinlock lock_list){
    800018fc:	7139                	addi	sp,sp,-64
    800018fe:	fc06                	sd	ra,56(sp)
    80001900:	f822                	sd	s0,48(sp)
    80001902:	f426                	sd	s1,40(sp)
    80001904:	f04a                	sd	s2,32(sp)
    80001906:	ec4e                	sd	s3,24(sp)
    80001908:	e852                	sd	s4,16(sp)
    8000190a:	e456                	sd	s5,8(sp)
    8000190c:	e05a                	sd	s6,0(sp)
    8000190e:	0080                	addi	s0,sp,64
    80001910:	84aa                	mv	s1,a0
    80001912:	89ae                	mv	s3,a1
    80001914:	8932                	mv	s2,a2
  // printf("entered remove from list\n");
  //printf("trying to remove %d\n", p_index);
  int ret=-1;
  acquire(&lock_list);
    80001916:	8532                	mv	a0,a2
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	2cc080e7          	jalr	716(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001920:	0009a783          	lw	a5,0(s3)
    80001924:	577d                	li	a4,-1
    80001926:	08e78c63          	beq	a5,a4,800019be <remove_from_list+0xc2>
    release(&lock_list);
    panic("the remove from list faild.\n");
  }
  else{
    //if(proc[*list].next==-1){ // only one is on the list
        if(p_index == *list){
    8000192a:	0a978763          	beq	a5,s1,800019d8 <remove_from_list+0xdc>
          ret=p_index;
          return ret;
        }
    //}
    else{
      release(&lock_list);
    8000192e:	854a                	mv	a0,s2
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	368080e7          	jalr	872(ra) # 80000c98 <release>
      struct proc *pred;
      struct proc *curr;
      pred=&proc[*list];
    80001938:	0009a983          	lw	s3,0(s3)
    8000193c:	18800793          	li	a5,392
    80001940:	02f987b3          	mul	a5,s3,a5
    80001944:	00010917          	auipc	s2,0x10
    80001948:	eb490913          	addi	s2,s2,-332 # 800117f8 <proc>
    8000194c:	01278a33          	add	s4,a5,s2
      acquire(&pred->linked_list_lock);
    80001950:	04078793          	addi	a5,a5,64
    80001954:	993e                	add	s2,s2,a5
    80001956:	854a                	mv	a0,s2
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	28c080e7          	jalr	652(ra) # 80000be4 <acquire>
      if(pred->next==-1)
    80001960:	03ca2783          	lw	a5,60(s4)
    80001964:	2781                	sext.w	a5,a5
    80001966:	577d                	li	a4,-1
    80001968:	08e78b63          	beq	a5,a4,800019fe <remove_from_list+0x102>
      {
        release(&pred->linked_list_lock);
        panic("the item is not in the list\n");
      }
      curr=&proc[pred->next];
    8000196c:	00010a97          	auipc	s5,0x10
    80001970:	e8ca8a93          	addi	s5,s5,-372 # 800117f8 <proc>
    80001974:	18800b13          	li	s6,392
    80001978:	036989b3          	mul	s3,s3,s6
    8000197c:	99d6                	add	s3,s3,s5
    8000197e:	03c9a903          	lw	s2,60(s3)
    80001982:	2901                	sext.w	s2,s2
    80001984:	03690933          	mul	s2,s2,s6
      acquire(&curr->linked_list_lock);
    80001988:	04090513          	addi	a0,s2,64
    8000198c:	9556                	add	a0,a0,s5
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	256080e7          	jalr	598(ra) # 80000be4 <acquire>
      //printf("pred is:%d the curr is:%d\n", pred->index,curr->index);
     
      ret = remove_cs(pred, curr, &proc[p_index]);
    80001996:	03648633          	mul	a2,s1,s6
    8000199a:	9656                	add	a2,a2,s5
    8000199c:	012a85b3          	add	a1,s5,s2
    800019a0:	8552                	mv	a0,s4
    800019a2:	00000097          	auipc	ra,0x0
    800019a6:	e9c080e7          	jalr	-356(ra) # 8000183e <remove_cs>
    }
  }
  //printf("here4\n");
  //release(&lock_list);
  return ret;
}
    800019aa:	70e2                	ld	ra,56(sp)
    800019ac:	7442                	ld	s0,48(sp)
    800019ae:	74a2                	ld	s1,40(sp)
    800019b0:	7902                	ld	s2,32(sp)
    800019b2:	69e2                	ld	s3,24(sp)
    800019b4:	6a42                	ld	s4,16(sp)
    800019b6:	6aa2                	ld	s5,8(sp)
    800019b8:	6b02                	ld	s6,0(sp)
    800019ba:	6121                	addi	sp,sp,64
    800019bc:	8082                	ret
    release(&lock_list);
    800019be:	854a                	mv	a0,s2
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	2d8080e7          	jalr	728(ra) # 80000c98 <release>
    panic("the remove from list faild.\n");
    800019c8:	00007517          	auipc	a0,0x7
    800019cc:	81050513          	addi	a0,a0,-2032 # 800081d8 <digits+0x198>
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>
          *list = proc[p_index].next;
    800019d8:	18800793          	li	a5,392
    800019dc:	02f48733          	mul	a4,s1,a5
    800019e0:	00010797          	auipc	a5,0x10
    800019e4:	e1878793          	addi	a5,a5,-488 # 800117f8 <proc>
    800019e8:	97ba                	add	a5,a5,a4
    800019ea:	5fdc                	lw	a5,60(a5)
    800019ec:	00f9a023          	sw	a5,0(s3)
          release(&lock_list);
    800019f0:	854a                	mv	a0,s2
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	2a6080e7          	jalr	678(ra) # 80000c98 <release>
          return ret;
    800019fa:	8526                	mv	a0,s1
    800019fc:	b77d                	j	800019aa <remove_from_list+0xae>
        release(&pred->linked_list_lock);
    800019fe:	854a                	mv	a0,s2
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	298080e7          	jalr	664(ra) # 80000c98 <release>
        panic("the item is not in the list\n");
    80001a08:	00006517          	auipc	a0,0x6
    80001a0c:	7f050513          	addi	a0,a0,2032 # 800081f8 <digits+0x1b8>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	b2e080e7          	jalr	-1234(ra) # 8000053e <panic>

0000000080001a18 <insert_cs>:

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
  //struct proc *curr=pred;
  //printf("insert cs");
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
    80001a42:	dbaa0a13          	addi	s4,s4,-582 # 800117f8 <proc>
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
    80001a5e:	23e080e7          	jalr	574(ra) # 80000c98 <release>
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
    //printf("exitloop\n");
    pred->next = p->index;
    80001a88:	038aa783          	lw	a5,56(s5)
    80001a8c:	02f92e23          	sw	a5,60(s2)
    release(&pred->linked_list_lock);
    80001a90:	04090513          	addi	a0,s2,64
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	204080e7          	jalr	516(ra) # 80000c98 <release>
    //printf("the pred is:%d pred->next:%d p->index=%d\n",pred->index,pred->next,p->index);
    //printf("the p->index is:%d\n",p->index);
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
insert_to_list(int p_index, int *list,struct spinlock lock_list){;
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
  acquire(&lock_list);
    80001ad2:	8532                	mv	a0,a2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	110080e7          	jalr	272(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001adc:	00092703          	lw	a4,0(s2)
    80001ae0:	57fd                	li	a5,-1
    80001ae2:	04f70d63          	beq	a4,a5,80001b3c <insert_to_list+0x82>
    ret=p_index;
    //printf("here\nlist pointer: %d, list next %d\n",*list, proc[*list].next);
    release(&lock_list);
  }
  else{
    release(&lock_list);
    80001ae6:	854e                	mv	a0,s3
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    80001af0:	00092903          	lw	s2,0(s2)
    80001af4:	18800a13          	li	s4,392
    80001af8:	03490933          	mul	s2,s2,s4
    //printf("the index of the first prosses in the list is:%d %d\n",*list,pred->next);
    acquire(&pred->linked_list_lock);
    80001afc:	04090513          	addi	a0,s2,64
    80001b00:	00010997          	auipc	s3,0x10
    80001b04:	cf898993          	addi	s3,s3,-776 # 800117f8 <proc>
    80001b08:	954e                	add	a0,a0,s3
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	0da080e7          	jalr	218(ra) # 80000be4 <acquire>
    //curr=&proc[pred->next];
    //acquire(&curr->lock);
    ret=insert_cs(pred, &proc[p_index]);
    80001b12:	034485b3          	mul	a1,s1,s4
    80001b16:	95ce                	add	a1,a1,s3
    80001b18:	01298533          	add	a0,s3,s2
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	efc080e7          	jalr	-260(ra) # 80001a18 <insert_cs>
    //release(&curr->lock);
    // release(&pred->linked_list_lock);
    //printf("ret is:%d \n",ret);  
  }
if(ret==-1){
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
    80001b50:	caca0a13          	addi	s4,s4,-852 # 800117f8 <proc>
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
    80001b6e:	12e080e7          	jalr	302(ra) # 80000c98 <release>
    release(&lock_list);
    80001b72:	854e                	mv	a0,s3
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	124080e7          	jalr	292(ra) # 80000c98 <release>
    ret=p_index;
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	b75d                	j	80001b24 <insert_to_list+0x6a>
  panic("insert is failed");
    80001b80:	00006517          	auipc	a0,0x6
    80001b84:	69850513          	addi	a0,a0,1688 # 80008218 <digits+0x1d8>
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
    80001baa:	c5248493          	addi	s1,s1,-942 # 800117f8 <proc>
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
    80001bc4:	e38a0a13          	addi	s4,s4,-456 # 800179f8 <tickslock>
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
    80001bf6:	55e080e7          	jalr	1374(ra) # 80001150 <kvmmap>
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
    80001c1a:	61a50513          	addi	a0,a0,1562 # 80008230 <digits+0x1f0>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>

0000000080001c26 <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80001c26:	7119                	addi	sp,sp,-128
    80001c28:	fc86                	sd	ra,120(sp)
    80001c2a:	f8a2                	sd	s0,112(sp)
    80001c2c:	f4a6                	sd	s1,104(sp)
    80001c2e:	f0ca                	sd	s2,96(sp)
    80001c30:	ecce                	sd	s3,88(sp)
    80001c32:	e8d2                	sd	s4,80(sp)
    80001c34:	e4d6                	sd	s5,72(sp)
    80001c36:	e0da                	sd	s6,64(sp)
    80001c38:	fc5e                	sd	s7,56(sp)
    80001c3a:	f862                	sd	s8,48(sp)
    80001c3c:	f466                	sd	s9,40(sp)
    80001c3e:	0100                	addi	s0,sp,128
  //printf("entered procinit\n");
  struct proc *p;

  for (int i = 0; i<NCPU; i++){
    80001c40:	0000f497          	auipc	s1,0xf
    80001c44:	66048493          	addi	s1,s1,1632 # 800112a0 <cpus_ll>
    80001c48:	0000f917          	auipc	s2,0xf
    80001c4c:	67890913          	addi	s2,s2,1656 # 800112c0 <pid_lock>
    cas(&cpus_ll[i],0,-1); 
    80001c50:	567d                	li	a2,-1
    80001c52:	4581                	li	a1,0
    80001c54:	8526                	mv	a0,s1
    80001c56:	00005097          	auipc	ra,0x5
    80001c5a:	d90080e7          	jalr	-624(ra) # 800069e6 <cas>
  for (int i = 0; i<NCPU; i++){
    80001c5e:	0491                	addi	s1,s1,4
    80001c60:	ff2498e3          	bne	s1,s2,80001c50 <procinit+0x2a>
    //printf("done cpus_ll[%d]=%d\n",i ,cpus_ll[i]);
}
  
  initlock(&pid_lock, "nextpid");
    80001c64:	00006597          	auipc	a1,0x6
    80001c68:	5d458593          	addi	a1,a1,1492 # 80008238 <digits+0x1f8>
    80001c6c:	0000f517          	auipc	a0,0xf
    80001c70:	65450513          	addi	a0,a0,1620 # 800112c0 <pid_lock>
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	ee0080e7          	jalr	-288(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c7c:	00006597          	auipc	a1,0x6
    80001c80:	5c458593          	addi	a1,a1,1476 # 80008240 <digits+0x200>
    80001c84:	0000f517          	auipc	a0,0xf
    80001c88:	65450513          	addi	a0,a0,1620 # 800112d8 <wait_lock>
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	ec8080e7          	jalr	-312(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001c94:	00006597          	auipc	a1,0x6
    80001c98:	5bc58593          	addi	a1,a1,1468 # 80008250 <digits+0x210>
    80001c9c:	0000f517          	auipc	a0,0xf
    80001ca0:	65450513          	addi	a0,a0,1620 # 800112f0 <sleeping_head>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	eb0080e7          	jalr	-336(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001cac:	00006597          	auipc	a1,0x6
    80001cb0:	5b458593          	addi	a1,a1,1460 # 80008260 <digits+0x220>
    80001cb4:	0000f517          	auipc	a0,0xf
    80001cb8:	65450513          	addi	a0,a0,1620 # 80011308 <zombie_head>
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	e98080e7          	jalr	-360(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001cc4:	00006597          	auipc	a1,0x6
    80001cc8:	5ac58593          	addi	a1,a1,1452 # 80008270 <digits+0x230>
    80001ccc:	0000f517          	auipc	a0,0xf
    80001cd0:	65450513          	addi	a0,a0,1620 # 80011320 <unused_head>
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	e80080e7          	jalr	-384(ra) # 80000b54 <initlock>
  
  int i=0; //added
    80001cdc:	4981                	li	s3,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cde:	00010497          	auipc	s1,0x10
    80001ce2:	b1a48493          	addi	s1,s1,-1254 # 800117f8 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001ce6:	8ca6                	mv	s9,s1
    80001ce8:	00006c17          	auipc	s8,0x6
    80001cec:	318c3c03          	ld	s8,792(s8) # 80008000 <etext>
    80001cf0:	04000a37          	lui	s4,0x4000
    80001cf4:	1a7d                	addi	s4,s4,-1
    80001cf6:	0a32                	slli	s4,s4,0xc
      //added:
      p->state = UNUSED; 
      p->index = i;
      p->next = -1;
    80001cf8:	5bfd                	li	s7,-1
      p->cpu_num = 0;
      initlock(&p->lock, "proc");
    80001cfa:	00006b17          	auipc	s6,0x6
    80001cfe:	586b0b13          	addi	s6,s6,1414 # 80008280 <digits+0x240>
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
      i++;
      insert_to_list(p->index, &unused, unused_head);
    80001d02:	0000f917          	auipc	s2,0xf
    80001d06:	59e90913          	addi	s2,s2,1438 # 800112a0 <cpus_ll>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0a:	00016a97          	auipc	s5,0x16
    80001d0e:	ceea8a93          	addi	s5,s5,-786 # 800179f8 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001d12:	419487b3          	sub	a5,s1,s9
    80001d16:	878d                	srai	a5,a5,0x3
    80001d18:	038787b3          	mul	a5,a5,s8
    80001d1c:	2785                	addiw	a5,a5,1
    80001d1e:	00d7979b          	slliw	a5,a5,0xd
    80001d22:	40fa07b3          	sub	a5,s4,a5
    80001d26:	f0bc                	sd	a5,96(s1)
      p->state = UNUSED; 
    80001d28:	0004ac23          	sw	zero,24(s1)
      p->index = i;
    80001d2c:	0334ac23          	sw	s3,56(s1)
      p->next = -1;
    80001d30:	0374ae23          	sw	s7,60(s1)
      p->cpu_num = 0;
    80001d34:	0204aa23          	sw	zero,52(s1)
      initlock(&p->lock, "proc");
    80001d38:	85da                	mv	a1,s6
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	e18080e7          	jalr	-488(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, name);
    80001d44:	00006597          	auipc	a1,0x6
    80001d48:	54458593          	addi	a1,a1,1348 # 80008288 <digits+0x248>
    80001d4c:	04048513          	addi	a0,s1,64
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	e04080e7          	jalr	-508(ra) # 80000b54 <initlock>
      i++;
    80001d58:	2985                	addiw	s3,s3,1
      insert_to_list(p->index, &unused, unused_head);
    80001d5a:	08093783          	ld	a5,128(s2)
    80001d5e:	f8f43023          	sd	a5,-128(s0)
    80001d62:	08893783          	ld	a5,136(s2)
    80001d66:	f8f43423          	sd	a5,-120(s0)
    80001d6a:	09093783          	ld	a5,144(s2)
    80001d6e:	f8f43823          	sd	a5,-112(s0)
    80001d72:	f8040613          	addi	a2,s0,-128
    80001d76:	00007597          	auipc	a1,0x7
    80001d7a:	b4e58593          	addi	a1,a1,-1202 # 800088c4 <unused>
    80001d7e:	5c88                	lw	a0,56(s1)
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	d3a080e7          	jalr	-710(ra) # 80001aba <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d88:	18848493          	addi	s1,s1,392
    80001d8c:	f95493e3          	bne	s1,s5,80001d12 <procinit+0xec>
  
  
  //printf("the head of the unused list is %d, and the value of next is:%d\n ",unused,proc[unused].next);
      
  //printf("finished procinit\n");
}
    80001d90:	70e6                	ld	ra,120(sp)
    80001d92:	7446                	ld	s0,112(sp)
    80001d94:	74a6                	ld	s1,104(sp)
    80001d96:	7906                	ld	s2,96(sp)
    80001d98:	69e6                	ld	s3,88(sp)
    80001d9a:	6a46                	ld	s4,80(sp)
    80001d9c:	6aa6                	ld	s5,72(sp)
    80001d9e:	6b06                	ld	s6,64(sp)
    80001da0:	7be2                	ld	s7,56(sp)
    80001da2:	7c42                	ld	s8,48(sp)
    80001da4:	7ca2                	ld	s9,40(sp)
    80001da6:	6109                	addi	sp,sp,128
    80001da8:	8082                	ret

0000000080001daa <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001daa:	1141                	addi	sp,sp,-16
    80001dac:	e422                	sd	s0,8(sp)
    80001dae:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001db0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001db2:	2501                	sext.w	a0,a0
    80001db4:	6422                	ld	s0,8(sp)
    80001db6:	0141                	addi	sp,sp,16
    80001db8:	8082                	ret

0000000080001dba <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001dba:	1141                	addi	sp,sp,-16
    80001dbc:	e422                	sd	s0,8(sp)
    80001dbe:	0800                	addi	s0,sp,16
    80001dc0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001dc2:	2781                	sext.w	a5,a5
    80001dc4:	079e                	slli	a5,a5,0x7
  return c;
}
    80001dc6:	0000f517          	auipc	a0,0xf
    80001dca:	57250513          	addi	a0,a0,1394 # 80011338 <cpus>
    80001dce:	953e                	add	a0,a0,a5
    80001dd0:	6422                	ld	s0,8(sp)
    80001dd2:	0141                	addi	sp,sp,16
    80001dd4:	8082                	ret

0000000080001dd6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001dd6:	1101                	addi	sp,sp,-32
    80001dd8:	ec06                	sd	ra,24(sp)
    80001dda:	e822                	sd	s0,16(sp)
    80001ddc:	e426                	sd	s1,8(sp)
    80001dde:	1000                	addi	s0,sp,32
  push_off();
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	db8080e7          	jalr	-584(ra) # 80000b98 <push_off>
    80001de8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001dea:	2781                	sext.w	a5,a5
    80001dec:	079e                	slli	a5,a5,0x7
    80001dee:	0000f717          	auipc	a4,0xf
    80001df2:	4b270713          	addi	a4,a4,1202 # 800112a0 <cpus_ll>
    80001df6:	97ba                	add	a5,a5,a4
    80001df8:	6fc4                	ld	s1,152(a5)
  // printf("first cpu-noff%d\n", c->noff);
  pop_off();
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e3e080e7          	jalr	-450(ra) # 80000c38 <pop_off>
  // printf("second cpu-noff%d\n", c->noff);
  return p;
}
    80001e02:	8526                	mv	a0,s1
    80001e04:	60e2                	ld	ra,24(sp)
    80001e06:	6442                	ld	s0,16(sp)
    80001e08:	64a2                	ld	s1,8(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret

0000000080001e0e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e0e:	1141                	addi	sp,sp,-16
    80001e10:	e406                	sd	ra,8(sp)
    80001e12:	e022                	sd	s0,0(sp)
    80001e14:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	fc0080e7          	jalr	-64(ra) # 80001dd6 <myproc>
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	e7a080e7          	jalr	-390(ra) # 80000c98 <release>


  if (first) {
    80001e26:	00007797          	auipc	a5,0x7
    80001e2a:	a9a7a783          	lw	a5,-1382(a5) # 800088c0 <first.1728>
    80001e2e:	eb89                	bnez	a5,80001e40 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e30:	00001097          	auipc	ra,0x1
    80001e34:	070080e7          	jalr	112(ra) # 80002ea0 <usertrapret>
}
    80001e38:	60a2                	ld	ra,8(sp)
    80001e3a:	6402                	ld	s0,0(sp)
    80001e3c:	0141                	addi	sp,sp,16
    80001e3e:	8082                	ret
    first = 0;
    80001e40:	00007797          	auipc	a5,0x7
    80001e44:	a807a023          	sw	zero,-1408(a5) # 800088c0 <first.1728>
    fsinit(ROOTDEV);
    80001e48:	4505                	li	a0,1
    80001e4a:	00002097          	auipc	ra,0x2
    80001e4e:	d98080e7          	jalr	-616(ra) # 80003be2 <fsinit>
    80001e52:	bff9                	j	80001e30 <forkret+0x22>

0000000080001e54 <allocpid>:
allocpid() { //changed as ordered in task 2
    80001e54:	1101                	addi	sp,sp,-32
    80001e56:	ec06                	sd	ra,24(sp)
    80001e58:	e822                	sd	s0,16(sp)
    80001e5a:	e426                	sd	s1,8(sp)
    80001e5c:	e04a                	sd	s2,0(sp)
    80001e5e:	1000                	addi	s0,sp,32
      pid = nextpid;
    80001e60:	00007917          	auipc	s2,0x7
    80001e64:	a7090913          	addi	s2,s2,-1424 # 800088d0 <nextpid>
    80001e68:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    80001e6c:	0014861b          	addiw	a2,s1,1
    80001e70:	85a6                	mv	a1,s1
    80001e72:	854a                	mv	a0,s2
    80001e74:	00005097          	auipc	ra,0x5
    80001e78:	b72080e7          	jalr	-1166(ra) # 800069e6 <cas>
    80001e7c:	f575                	bnez	a0,80001e68 <allocpid+0x14>
}
    80001e7e:	8526                	mv	a0,s1
    80001e80:	60e2                	ld	ra,24(sp)
    80001e82:	6442                	ld	s0,16(sp)
    80001e84:	64a2                	ld	s1,8(sp)
    80001e86:	6902                	ld	s2,0(sp)
    80001e88:	6105                	addi	sp,sp,32
    80001e8a:	8082                	ret

0000000080001e8c <proc_pagetable>:
{
    80001e8c:	1101                	addi	sp,sp,-32
    80001e8e:	ec06                	sd	ra,24(sp)
    80001e90:	e822                	sd	s0,16(sp)
    80001e92:	e426                	sd	s1,8(sp)
    80001e94:	e04a                	sd	s2,0(sp)
    80001e96:	1000                	addi	s0,sp,32
    80001e98:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	4a0080e7          	jalr	1184(ra) # 8000133a <uvmcreate>
    80001ea2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ea4:	c121                	beqz	a0,80001ee4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ea6:	4729                	li	a4,10
    80001ea8:	00005697          	auipc	a3,0x5
    80001eac:	15868693          	addi	a3,a3,344 # 80007000 <_trampoline>
    80001eb0:	6605                	lui	a2,0x1
    80001eb2:	040005b7          	lui	a1,0x4000
    80001eb6:	15fd                	addi	a1,a1,-1
    80001eb8:	05b2                	slli	a1,a1,0xc
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	1f6080e7          	jalr	502(ra) # 800010b0 <mappages>
    80001ec2:	02054863          	bltz	a0,80001ef2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ec6:	4719                	li	a4,6
    80001ec8:	07893683          	ld	a3,120(s2)
    80001ecc:	6605                	lui	a2,0x1
    80001ece:	020005b7          	lui	a1,0x2000
    80001ed2:	15fd                	addi	a1,a1,-1
    80001ed4:	05b6                	slli	a1,a1,0xd
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	1d8080e7          	jalr	472(ra) # 800010b0 <mappages>
    80001ee0:	02054163          	bltz	a0,80001f02 <proc_pagetable+0x76>
}
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	60e2                	ld	ra,24(sp)
    80001ee8:	6442                	ld	s0,16(sp)
    80001eea:	64a2                	ld	s1,8(sp)
    80001eec:	6902                	ld	s2,0(sp)
    80001eee:	6105                	addi	sp,sp,32
    80001ef0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ef2:	4581                	li	a1,0
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	640080e7          	jalr	1600(ra) # 80001536 <uvmfree>
    return 0;
    80001efe:	4481                	li	s1,0
    80001f00:	b7d5                	j	80001ee4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f02:	4681                	li	a3,0
    80001f04:	4605                	li	a2,1
    80001f06:	040005b7          	lui	a1,0x4000
    80001f0a:	15fd                	addi	a1,a1,-1
    80001f0c:	05b2                	slli	a1,a1,0xc
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	366080e7          	jalr	870(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f18:	4581                	li	a1,0
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	61a080e7          	jalr	1562(ra) # 80001536 <uvmfree>
    return 0;
    80001f24:	4481                	li	s1,0
    80001f26:	bf7d                	j	80001ee4 <proc_pagetable+0x58>

0000000080001f28 <proc_freepagetable>:
{
    80001f28:	1101                	addi	sp,sp,-32
    80001f2a:	ec06                	sd	ra,24(sp)
    80001f2c:	e822                	sd	s0,16(sp)
    80001f2e:	e426                	sd	s1,8(sp)
    80001f30:	e04a                	sd	s2,0(sp)
    80001f32:	1000                	addi	s0,sp,32
    80001f34:	84aa                	mv	s1,a0
    80001f36:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f38:	4681                	li	a3,0
    80001f3a:	4605                	li	a2,1
    80001f3c:	040005b7          	lui	a1,0x4000
    80001f40:	15fd                	addi	a1,a1,-1
    80001f42:	05b2                	slli	a1,a1,0xc
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	332080e7          	jalr	818(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f4c:	4681                	li	a3,0
    80001f4e:	4605                	li	a2,1
    80001f50:	020005b7          	lui	a1,0x2000
    80001f54:	15fd                	addi	a1,a1,-1
    80001f56:	05b6                	slli	a1,a1,0xd
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	31c080e7          	jalr	796(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001f62:	85ca                	mv	a1,s2
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	5d0080e7          	jalr	1488(ra) # 80001536 <uvmfree>
}
    80001f6e:	60e2                	ld	ra,24(sp)
    80001f70:	6442                	ld	s0,16(sp)
    80001f72:	64a2                	ld	s1,8(sp)
    80001f74:	6902                	ld	s2,0(sp)
    80001f76:	6105                	addi	sp,sp,32
    80001f78:	8082                	ret

0000000080001f7a <freeproc>:
{
    80001f7a:	7139                	addi	sp,sp,-64
    80001f7c:	fc06                	sd	ra,56(sp)
    80001f7e:	f822                	sd	s0,48(sp)
    80001f80:	f426                	sd	s1,40(sp)
    80001f82:	f04a                	sd	s2,32(sp)
    80001f84:	0080                	addi	s0,sp,64
    80001f86:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f88:	7d28                	ld	a0,120(a0)
    80001f8a:	c509                	beqz	a0,80001f94 <freeproc+0x1a>
    kfree((void*)p->trapframe);
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	a6c080e7          	jalr	-1428(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001f94:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001f98:	78a8                	ld	a0,112(s1)
    80001f9a:	c511                	beqz	a0,80001fa6 <freeproc+0x2c>
    proc_freepagetable(p->pagetable, p->sz);
    80001f9c:	74ac                	ld	a1,104(s1)
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	f8a080e7          	jalr	-118(ra) # 80001f28 <proc_freepagetable>
  p->pagetable = 0;
    80001fa6:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001faa:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001fae:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001fb2:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001fb6:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001fba:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001fbe:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001fc2:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index, &zombie, zombie_head);
    80001fc6:	0000f917          	auipc	s2,0xf
    80001fca:	2da90913          	addi	s2,s2,730 # 800112a0 <cpus_ll>
    80001fce:	06893783          	ld	a5,104(s2)
    80001fd2:	fcf43023          	sd	a5,-64(s0)
    80001fd6:	07093783          	ld	a5,112(s2)
    80001fda:	fcf43423          	sd	a5,-56(s0)
    80001fde:	07893783          	ld	a5,120(s2)
    80001fe2:	fcf43823          	sd	a5,-48(s0)
    80001fe6:	fc040613          	addi	a2,s0,-64
    80001fea:	00007597          	auipc	a1,0x7
    80001fee:	8de58593          	addi	a1,a1,-1826 # 800088c8 <zombie>
    80001ff2:	5c88                	lw	a0,56(s1)
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	908080e7          	jalr	-1784(ra) # 800018fc <remove_from_list>
  p->state = UNUSED;
    80001ffc:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index, &unused, unused_head);
    80002000:	08093783          	ld	a5,128(s2)
    80002004:	fcf43023          	sd	a5,-64(s0)
    80002008:	08893783          	ld	a5,136(s2)
    8000200c:	fcf43423          	sd	a5,-56(s0)
    80002010:	09093783          	ld	a5,144(s2)
    80002014:	fcf43823          	sd	a5,-48(s0)
    80002018:	fc040613          	addi	a2,s0,-64
    8000201c:	00007597          	auipc	a1,0x7
    80002020:	8a858593          	addi	a1,a1,-1880 # 800088c4 <unused>
    80002024:	5c88                	lw	a0,56(s1)
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	a94080e7          	jalr	-1388(ra) # 80001aba <insert_to_list>
}
    8000202e:	70e2                	ld	ra,56(sp)
    80002030:	7442                	ld	s0,48(sp)
    80002032:	74a2                	ld	s1,40(sp)
    80002034:	7902                	ld	s2,32(sp)
    80002036:	6121                	addi	sp,sp,64
    80002038:	8082                	ret

000000008000203a <allocproc>:
{
    8000203a:	715d                	addi	sp,sp,-80
    8000203c:	e486                	sd	ra,72(sp)
    8000203e:	e0a2                	sd	s0,64(sp)
    80002040:	fc26                	sd	s1,56(sp)
    80002042:	f84a                	sd	s2,48(sp)
    80002044:	f44e                	sd	s3,40(sp)
    80002046:	f052                	sd	s4,32(sp)
    80002048:	0880                	addi	s0,sp,80
  if(unused != -1){
    8000204a:	00007917          	auipc	s2,0x7
    8000204e:	87a92903          	lw	s2,-1926(s2) # 800088c4 <unused>
    80002052:	57fd                	li	a5,-1
  return 0;
    80002054:	4481                	li	s1,0
  if(unused != -1){
    80002056:	0cf90663          	beq	s2,a5,80002122 <allocproc+0xe8>
    p = &proc[unused];
    8000205a:	18800993          	li	s3,392
    8000205e:	033909b3          	mul	s3,s2,s3
    80002062:	0000f497          	auipc	s1,0xf
    80002066:	79648493          	addi	s1,s1,1942 # 800117f8 <proc>
    8000206a:	94ce                	add	s1,s1,s3
    remove_from_list(p->index,&unused,unused_head);
    8000206c:	0000f797          	auipc	a5,0xf
    80002070:	23478793          	addi	a5,a5,564 # 800112a0 <cpus_ll>
    80002074:	63d8                	ld	a4,128(a5)
    80002076:	fae43823          	sd	a4,-80(s0)
    8000207a:	67d8                	ld	a4,136(a5)
    8000207c:	fae43c23          	sd	a4,-72(s0)
    80002080:	6bdc                	ld	a5,144(a5)
    80002082:	fcf43023          	sd	a5,-64(s0)
    80002086:	fb040613          	addi	a2,s0,-80
    8000208a:	00007597          	auipc	a1,0x7
    8000208e:	83a58593          	addi	a1,a1,-1990 # 800088c4 <unused>
    80002092:	5c88                	lw	a0,56(s1)
    80002094:	00000097          	auipc	ra,0x0
    80002098:	868080e7          	jalr	-1944(ra) # 800018fc <remove_from_list>
    acquire(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	dae080e7          	jalr	-594(ra) # 80001e54 <allocpid>
    800020ae:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020b0:	4785                	li	a5,1
    800020b2:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	a40080e7          	jalr	-1472(ra) # 80000af4 <kalloc>
    800020bc:	8a2a                	mv	s4,a0
    800020be:	fca8                	sd	a0,120(s1)
    800020c0:	c935                	beqz	a0,80002134 <allocproc+0xfa>
  p->pagetable = proc_pagetable(p);
    800020c2:	8526                	mv	a0,s1
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	dc8080e7          	jalr	-568(ra) # 80001e8c <proc_pagetable>
    800020cc:	8a2a                	mv	s4,a0
    800020ce:	18800793          	li	a5,392
    800020d2:	02f90733          	mul	a4,s2,a5
    800020d6:	0000f797          	auipc	a5,0xf
    800020da:	72278793          	addi	a5,a5,1826 # 800117f8 <proc>
    800020de:	97ba                	add	a5,a5,a4
    800020e0:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800020e2:	c52d                	beqz	a0,8000214c <allocproc+0x112>
  memset(&p->context, 0, sizeof(p->context));
    800020e4:	08098513          	addi	a0,s3,128
    800020e8:	0000fa17          	auipc	s4,0xf
    800020ec:	710a0a13          	addi	s4,s4,1808 # 800117f8 <proc>
    800020f0:	07000613          	li	a2,112
    800020f4:	4581                	li	a1,0
    800020f6:	9552                	add	a0,a0,s4
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	be8080e7          	jalr	-1048(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002100:	18800793          	li	a5,392
    80002104:	02f90933          	mul	s2,s2,a5
    80002108:	9952                	add	s2,s2,s4
    8000210a:	00000797          	auipc	a5,0x0
    8000210e:	d0478793          	addi	a5,a5,-764 # 80001e0e <forkret>
    80002112:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002116:	06093783          	ld	a5,96(s2)
    8000211a:	6705                	lui	a4,0x1
    8000211c:	97ba                	add	a5,a5,a4
    8000211e:	08f93423          	sd	a5,136(s2)
}
    80002122:	8526                	mv	a0,s1
    80002124:	60a6                	ld	ra,72(sp)
    80002126:	6406                	ld	s0,64(sp)
    80002128:	74e2                	ld	s1,56(sp)
    8000212a:	7942                	ld	s2,48(sp)
    8000212c:	79a2                	ld	s3,40(sp)
    8000212e:	7a02                	ld	s4,32(sp)
    80002130:	6161                	addi	sp,sp,80
    80002132:	8082                	ret
    freeproc(p);
    80002134:	8526                	mv	a0,s1
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	e44080e7          	jalr	-444(ra) # 80001f7a <freeproc>
    release(&p->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b58080e7          	jalr	-1192(ra) # 80000c98 <release>
    return 0;
    80002148:	84d2                	mv	s1,s4
    8000214a:	bfe1                	j	80002122 <allocproc+0xe8>
    freeproc(p);
    8000214c:	8526                	mv	a0,s1
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	e2c080e7          	jalr	-468(ra) # 80001f7a <freeproc>
    release(&p->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b40080e7          	jalr	-1216(ra) # 80000c98 <release>
    return 0;
    80002160:	84d2                	mv	s1,s4
    80002162:	b7c1                	j	80002122 <allocproc+0xe8>

0000000080002164 <userinit>:
{
    80002164:	7139                	addi	sp,sp,-64
    80002166:	fc06                	sd	ra,56(sp)
    80002168:	f822                	sd	s0,48(sp)
    8000216a:	f426                	sd	s1,40(sp)
    8000216c:	0080                	addi	s0,sp,64
  p = allocproc();
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	ecc080e7          	jalr	-308(ra) # 8000203a <allocproc>
    80002176:	84aa                	mv	s1,a0
  initproc = p;
    80002178:	00007797          	auipc	a5,0x7
    8000217c:	eaa7b823          	sd	a0,-336(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002180:	03400613          	li	a2,52
    80002184:	00006597          	auipc	a1,0x6
    80002188:	75c58593          	addi	a1,a1,1884 # 800088e0 <initcode>
    8000218c:	7928                	ld	a0,112(a0)
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	1da080e7          	jalr	474(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002196:	6785                	lui	a5,0x1
    80002198:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    8000219a:	7cb8                	ld	a4,120(s1)
    8000219c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021a0:	7cb8                	ld	a4,120(s1)
    800021a2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021a4:	4641                	li	a2,16
    800021a6:	00006597          	auipc	a1,0x6
    800021aa:	0ea58593          	addi	a1,a1,234 # 80008290 <digits+0x250>
    800021ae:	17848513          	addi	a0,s1,376
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	c80080e7          	jalr	-896(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800021ba:	00006517          	auipc	a0,0x6
    800021be:	0e650513          	addi	a0,a0,230 # 800082a0 <digits+0x260>
    800021c2:	00002097          	auipc	ra,0x2
    800021c6:	44e080e7          	jalr	1102(ra) # 80004610 <namei>
    800021ca:	16a4b823          	sd	a0,368(s1)
  insert_to_list(p->index, &cpus_ll[0], cpus_head[0]);
    800021ce:	0000f597          	auipc	a1,0xf
    800021d2:	0d258593          	addi	a1,a1,210 # 800112a0 <cpus_ll>
    800021d6:	4985b783          	ld	a5,1176(a1)
    800021da:	fcf43023          	sd	a5,-64(s0)
    800021de:	4a05b783          	ld	a5,1184(a1)
    800021e2:	fcf43423          	sd	a5,-56(s0)
    800021e6:	4a85b783          	ld	a5,1192(a1)
    800021ea:	fcf43823          	sd	a5,-48(s0)
    800021ee:	fc040613          	addi	a2,s0,-64
    800021f2:	5c88                	lw	a0,56(s1)
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	8c6080e7          	jalr	-1850(ra) # 80001aba <insert_to_list>
  p->state = RUNNABLE;
    800021fc:	478d                	li	a5,3
    800021fe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	a96080e7          	jalr	-1386(ra) # 80000c98 <release>
}
    8000220a:	70e2                	ld	ra,56(sp)
    8000220c:	7442                	ld	s0,48(sp)
    8000220e:	74a2                	ld	s1,40(sp)
    80002210:	6121                	addi	sp,sp,64
    80002212:	8082                	ret

0000000080002214 <growproc>:
{
    80002214:	1101                	addi	sp,sp,-32
    80002216:	ec06                	sd	ra,24(sp)
    80002218:	e822                	sd	s0,16(sp)
    8000221a:	e426                	sd	s1,8(sp)
    8000221c:	e04a                	sd	s2,0(sp)
    8000221e:	1000                	addi	s0,sp,32
    80002220:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002222:	00000097          	auipc	ra,0x0
    80002226:	bb4080e7          	jalr	-1100(ra) # 80001dd6 <myproc>
    8000222a:	892a                	mv	s2,a0
  sz = p->sz;
    8000222c:	752c                	ld	a1,104(a0)
    8000222e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002232:	00904f63          	bgtz	s1,80002250 <growproc+0x3c>
  } else if(n < 0){
    80002236:	0204cc63          	bltz	s1,8000226e <growproc+0x5a>
  p->sz = sz;
    8000223a:	1602                	slli	a2,a2,0x20
    8000223c:	9201                	srli	a2,a2,0x20
    8000223e:	06c93423          	sd	a2,104(s2)
  return 0;
    80002242:	4501                	li	a0,0
}
    80002244:	60e2                	ld	ra,24(sp)
    80002246:	6442                	ld	s0,16(sp)
    80002248:	64a2                	ld	s1,8(sp)
    8000224a:	6902                	ld	s2,0(sp)
    8000224c:	6105                	addi	sp,sp,32
    8000224e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002250:	9e25                	addw	a2,a2,s1
    80002252:	1602                	slli	a2,a2,0x20
    80002254:	9201                	srli	a2,a2,0x20
    80002256:	1582                	slli	a1,a1,0x20
    80002258:	9181                	srli	a1,a1,0x20
    8000225a:	7928                	ld	a0,112(a0)
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	1c6080e7          	jalr	454(ra) # 80001422 <uvmalloc>
    80002264:	0005061b          	sext.w	a2,a0
    80002268:	fa69                	bnez	a2,8000223a <growproc+0x26>
      return -1;
    8000226a:	557d                	li	a0,-1
    8000226c:	bfe1                	j	80002244 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000226e:	9e25                	addw	a2,a2,s1
    80002270:	1602                	slli	a2,a2,0x20
    80002272:	9201                	srli	a2,a2,0x20
    80002274:	1582                	slli	a1,a1,0x20
    80002276:	9181                	srli	a1,a1,0x20
    80002278:	7928                	ld	a0,112(a0)
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	160080e7          	jalr	352(ra) # 800013da <uvmdealloc>
    80002282:	0005061b          	sext.w	a2,a0
    80002286:	bf55                	j	8000223a <growproc+0x26>

0000000080002288 <fork>:
{
    80002288:	711d                	addi	sp,sp,-96
    8000228a:	ec86                	sd	ra,88(sp)
    8000228c:	e8a2                	sd	s0,80(sp)
    8000228e:	e4a6                	sd	s1,72(sp)
    80002290:	e0ca                	sd	s2,64(sp)
    80002292:	fc4e                	sd	s3,56(sp)
    80002294:	f852                	sd	s4,48(sp)
    80002296:	f456                	sd	s5,40(sp)
    80002298:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	b3c080e7          	jalr	-1220(ra) # 80001dd6 <myproc>
    800022a2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	d96080e7          	jalr	-618(ra) # 8000203a <allocproc>
    800022ac:	16050963          	beqz	a0,8000241e <fork+0x196>
    800022b0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022b2:	06893603          	ld	a2,104(s2)
    800022b6:	792c                	ld	a1,112(a0)
    800022b8:	07093503          	ld	a0,112(s2)
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	2b2080e7          	jalr	690(ra) # 8000156e <uvmcopy>
    800022c4:	04054663          	bltz	a0,80002310 <fork+0x88>
  np->sz = p->sz;
    800022c8:	06893783          	ld	a5,104(s2)
    800022cc:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    800022d0:	07893683          	ld	a3,120(s2)
    800022d4:	87b6                	mv	a5,a3
    800022d6:	0789b703          	ld	a4,120(s3)
    800022da:	12068693          	addi	a3,a3,288
    800022de:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022e2:	6788                	ld	a0,8(a5)
    800022e4:	6b8c                	ld	a1,16(a5)
    800022e6:	6f90                	ld	a2,24(a5)
    800022e8:	01073023          	sd	a6,0(a4)
    800022ec:	e708                	sd	a0,8(a4)
    800022ee:	eb0c                	sd	a1,16(a4)
    800022f0:	ef10                	sd	a2,24(a4)
    800022f2:	02078793          	addi	a5,a5,32
    800022f6:	02070713          	addi	a4,a4,32
    800022fa:	fed792e3          	bne	a5,a3,800022de <fork+0x56>
  np->trapframe->a0 = 0;
    800022fe:	0789b783          	ld	a5,120(s3)
    80002302:	0607b823          	sd	zero,112(a5)
    80002306:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000230a:	17000a13          	li	s4,368
    8000230e:	a03d                	j	8000233c <fork+0xb4>
    freeproc(np);
    80002310:	854e                	mv	a0,s3
    80002312:	00000097          	auipc	ra,0x0
    80002316:	c68080e7          	jalr	-920(ra) # 80001f7a <freeproc>
    release(&np->lock);
    8000231a:	854e                	mv	a0,s3
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
    return -1;
    80002324:	5afd                	li	s5,-1
    80002326:	a0d5                	j	8000240a <fork+0x182>
      np->ofile[i] = filedup(p->ofile[i]);
    80002328:	00003097          	auipc	ra,0x3
    8000232c:	97e080e7          	jalr	-1666(ra) # 80004ca6 <filedup>
    80002330:	009987b3          	add	a5,s3,s1
    80002334:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002336:	04a1                	addi	s1,s1,8
    80002338:	01448763          	beq	s1,s4,80002346 <fork+0xbe>
    if(p->ofile[i])
    8000233c:	009907b3          	add	a5,s2,s1
    80002340:	6388                	ld	a0,0(a5)
    80002342:	f17d                	bnez	a0,80002328 <fork+0xa0>
    80002344:	bfcd                	j	80002336 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002346:	17093503          	ld	a0,368(s2)
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	ad2080e7          	jalr	-1326(ra) # 80003e1c <idup>
    80002352:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002356:	17898493          	addi	s1,s3,376
    8000235a:	4641                	li	a2,16
    8000235c:	17890593          	addi	a1,s2,376
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	ad0080e7          	jalr	-1328(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000236a:	0309aa83          	lw	s5,48(s3)
  np->cpu_num=p->cpu_num; //giving the child it's parent's cpu_num (the only change)
    8000236e:	03492783          	lw	a5,52(s2)
    80002372:	02f9aa23          	sw	a5,52(s3)
  initlock(&np->linked_list_lock, np->name);
    80002376:	85a6                	mv	a1,s1
    80002378:	04098513          	addi	a0,s3,64
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	7d8080e7          	jalr	2008(ra) # 80000b54 <initlock>
  release(&np->lock);
    80002384:	854e                	mv	a0,s3
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000238e:	0000f497          	auipc	s1,0xf
    80002392:	f1248493          	addi	s1,s1,-238 # 800112a0 <cpus_ll>
    80002396:	0000fa17          	auipc	s4,0xf
    8000239a:	f42a0a13          	addi	s4,s4,-190 # 800112d8 <wait_lock>
    8000239e:	8552                	mv	a0,s4
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	844080e7          	jalr	-1980(ra) # 80000be4 <acquire>
  np->parent = p;
    800023a8:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    800023ac:	8552                	mv	a0,s4
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	8ea080e7          	jalr	-1814(ra) # 80000c98 <release>
  acquire(&np->lock);
    800023b6:	854e                	mv	a0,s3
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	82c080e7          	jalr	-2004(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023c0:	478d                	li	a5,3
    800023c2:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(np->index, &cpus_ll[p->cpu_num], cpus_head[p->cpu_num]);
    800023c6:	03492583          	lw	a1,52(s2)
    800023ca:	00159793          	slli	a5,a1,0x1
    800023ce:	97ae                	add	a5,a5,a1
    800023d0:	078e                	slli	a5,a5,0x3
    800023d2:	97a6                	add	a5,a5,s1
    800023d4:	4987b703          	ld	a4,1176(a5)
    800023d8:	fae43023          	sd	a4,-96(s0)
    800023dc:	4a07b703          	ld	a4,1184(a5)
    800023e0:	fae43423          	sd	a4,-88(s0)
    800023e4:	4a87b783          	ld	a5,1192(a5)
    800023e8:	faf43823          	sd	a5,-80(s0)
    800023ec:	058a                	slli	a1,a1,0x2
    800023ee:	fa040613          	addi	a2,s0,-96
    800023f2:	95a6                	add	a1,a1,s1
    800023f4:	0389a503          	lw	a0,56(s3)
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	6c2080e7          	jalr	1730(ra) # 80001aba <insert_to_list>
  release(&np->lock);
    80002400:	854e                	mv	a0,s3
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
}
    8000240a:	8556                	mv	a0,s5
    8000240c:	60e6                	ld	ra,88(sp)
    8000240e:	6446                	ld	s0,80(sp)
    80002410:	64a6                	ld	s1,72(sp)
    80002412:	6906                	ld	s2,64(sp)
    80002414:	79e2                	ld	s3,56(sp)
    80002416:	7a42                	ld	s4,48(sp)
    80002418:	7aa2                	ld	s5,40(sp)
    8000241a:	6125                	addi	sp,sp,96
    8000241c:	8082                	ret
    return -1;
    8000241e:	5afd                	li	s5,-1
    80002420:	b7ed                	j	8000240a <fork+0x182>

0000000080002422 <scheduler>:
{
    80002422:	7175                	addi	sp,sp,-144
    80002424:	e506                	sd	ra,136(sp)
    80002426:	e122                	sd	s0,128(sp)
    80002428:	fca6                	sd	s1,120(sp)
    8000242a:	f8ca                	sd	s2,112(sp)
    8000242c:	f4ce                	sd	s3,104(sp)
    8000242e:	f0d2                	sd	s4,96(sp)
    80002430:	ecd6                	sd	s5,88(sp)
    80002432:	e8da                	sd	s6,80(sp)
    80002434:	e4de                	sd	s7,72(sp)
    80002436:	e0e2                	sd	s8,64(sp)
    80002438:	fc66                	sd	s9,56(sp)
    8000243a:	f86a                	sd	s10,48(sp)
    8000243c:	f46e                	sd	s11,40(sp)
    8000243e:	0900                	addi	s0,sp,144
    80002440:	8b92                	mv	s7,tp
  int id = r_tp();
    80002442:	2b81                	sext.w	s7,s7
  c->proc = 0;
    80002444:	007b9c93          	slli	s9,s7,0x7
    80002448:	0000f797          	auipc	a5,0xf
    8000244c:	e5878793          	addi	a5,a5,-424 # 800112a0 <cpus_ll>
    80002450:	97e6                	add	a5,a5,s9
    80002452:	0807bc23          	sd	zero,152(a5)
      swtch(&c->context, &p->context);
    80002456:	0000f797          	auipc	a5,0xf
    8000245a:	eea78793          	addi	a5,a5,-278 # 80011340 <cpus+0x8>
    8000245e:	9cbe                	add	s9,s9,a5
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002460:	0000f917          	auipc	s2,0xf
    80002464:	e4090913          	addi	s2,s2,-448 # 800112a0 <cpus_ll>
    80002468:	5c7d                	li	s8,-1
      p = &proc[cpus_ll[cpuid()]];
    8000246a:	0000fa97          	auipc	s5,0xf
    8000246e:	38ea8a93          	addi	s5,s5,910 # 800117f8 <proc>
      c->proc = p;
    80002472:	0b9e                	slli	s7,s7,0x7
    80002474:	9bca                	add	s7,s7,s2
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002476:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000247a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000247e:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002482:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002484:	2781                	sext.w	a5,a5
    80002486:	078a                	slli	a5,a5,0x2
    80002488:	97ca                	add	a5,a5,s2
    8000248a:	439c                	lw	a5,0(a5)
    8000248c:	ff8785e3          	beq	a5,s8,80002476 <scheduler+0x54>
    80002490:	18800b13          	li	s6,392
      p->state = RUNNING;
    80002494:	4d11                	li	s10,4
    80002496:	a0bd                	j	80002504 <scheduler+0xe2>
        panic("could not remove");
    80002498:	00006517          	auipc	a0,0x6
    8000249c:	e1050513          	addi	a0,a0,-496 # 800082a8 <digits+0x268>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	09e080e7          	jalr	158(ra) # 8000053e <panic>
    800024a8:	8592                	mv	a1,tp
    800024aa:	8792                	mv	a5,tp
        insert_to_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
    800024ac:	0007871b          	sext.w	a4,a5
    800024b0:	00171793          	slli	a5,a4,0x1
    800024b4:	97ba                	add	a5,a5,a4
    800024b6:	078e                	slli	a5,a5,0x3
    800024b8:	97ca                	add	a5,a5,s2
    800024ba:	4987b703          	ld	a4,1176(a5)
    800024be:	f6e43823          	sd	a4,-144(s0)
    800024c2:	4a07b703          	ld	a4,1184(a5)
    800024c6:	f6e43c23          	sd	a4,-136(s0)
    800024ca:	4a87b783          	ld	a5,1192(a5)
    800024ce:	f8f43023          	sd	a5,-128(s0)
    800024d2:	2581                	sext.w	a1,a1
    800024d4:	058a                	slli	a1,a1,0x2
    800024d6:	f7040613          	addi	a2,s0,-144
    800024da:	95ca                	add	a1,a1,s2
    800024dc:	038da503          	lw	a0,56(s11)
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	5da080e7          	jalr	1498(ra) # 80001aba <insert_to_list>
        c->proc = 0;
    800024e8:	080bbc23          	sd	zero,152(s7)
        release(&p->lock);
    800024ec:	854e                	mv	a0,s3
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	7aa080e7          	jalr	1962(ra) # 80000c98 <release>
    800024f6:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800024f8:	2781                	sext.w	a5,a5
    800024fa:	078a                	slli	a5,a5,0x2
    800024fc:	97ca                	add	a5,a5,s2
    800024fe:	439c                	lw	a5,0(a5)
    80002500:	f7878be3          	beq	a5,s8,80002476 <scheduler+0x54>
    80002504:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    80002506:	2781                	sext.w	a5,a5
    80002508:	078a                	slli	a5,a5,0x2
    8000250a:	97ca                	add	a5,a5,s2
    8000250c:	4384                	lw	s1,0(a5)
    8000250e:	03648a33          	mul	s4,s1,s6
    80002512:	015a09b3          	add	s3,s4,s5
      acquire(&p->lock);
    80002516:	854e                	mv	a0,s3
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	6cc080e7          	jalr	1740(ra) # 80000be4 <acquire>
    80002520:	8592                	mv	a1,tp
    80002522:	8792                	mv	a5,tp
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], cpus_head[cpuid()]);
    80002524:	0007871b          	sext.w	a4,a5
    80002528:	00171793          	slli	a5,a4,0x1
    8000252c:	97ba                	add	a5,a5,a4
    8000252e:	078e                	slli	a5,a5,0x3
    80002530:	97ca                	add	a5,a5,s2
    80002532:	4987b703          	ld	a4,1176(a5)
    80002536:	f6e43823          	sd	a4,-144(s0)
    8000253a:	4a07b703          	ld	a4,1184(a5)
    8000253e:	f6e43c23          	sd	a4,-136(s0)
    80002542:	4a87b783          	ld	a5,1192(a5)
    80002546:	f8f43023          	sd	a5,-128(s0)
    8000254a:	2581                	sext.w	a1,a1
    8000254c:	058a                	slli	a1,a1,0x2
    8000254e:	f7040613          	addi	a2,s0,-144
    80002552:	95ca                	add	a1,a1,s2
    80002554:	0389a503          	lw	a0,56(s3)
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	3a4080e7          	jalr	932(ra) # 800018fc <remove_from_list>
      if(removed == -1)
    80002560:	f3850ce3          	beq	a0,s8,80002498 <scheduler+0x76>
      p->state = RUNNING;
    80002564:	03648db3          	mul	s11,s1,s6
    80002568:	9dd6                	add	s11,s11,s5
    8000256a:	01adac23          	sw	s10,24(s11)
      c->proc = p;
    8000256e:	093bbc23          	sd	s3,152(s7)
      swtch(&c->context, &p->context);
    80002572:	080a0593          	addi	a1,s4,128
    80002576:	95d6                	add	a1,a1,s5
    80002578:	8566                	mv	a0,s9
    8000257a:	00001097          	auipc	ra,0x1
    8000257e:	87c080e7          	jalr	-1924(ra) # 80002df6 <swtch>
      if(p->state != ZOMBIE){
    80002582:	018da703          	lw	a4,24(s11)
    80002586:	4795                	li	a5,5
    80002588:	f6f700e3          	beq	a4,a5,800024e8 <scheduler+0xc6>
    8000258c:	bf31                	j	800024a8 <scheduler+0x86>

000000008000258e <sched>:
{
    8000258e:	7179                	addi	sp,sp,-48
    80002590:	f406                	sd	ra,40(sp)
    80002592:	f022                	sd	s0,32(sp)
    80002594:	ec26                	sd	s1,24(sp)
    80002596:	e84a                	sd	s2,16(sp)
    80002598:	e44e                	sd	s3,8(sp)
    8000259a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000259c:	00000097          	auipc	ra,0x0
    800025a0:	83a080e7          	jalr	-1990(ra) # 80001dd6 <myproc>
    800025a4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	5c4080e7          	jalr	1476(ra) # 80000b6a <holding>
    800025ae:	c93d                	beqz	a0,80002624 <sched+0x96>
    800025b0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    800025b2:	2781                	sext.w	a5,a5
    800025b4:	079e                	slli	a5,a5,0x7
    800025b6:	0000f717          	auipc	a4,0xf
    800025ba:	cea70713          	addi	a4,a4,-790 # 800112a0 <cpus_ll>
    800025be:	97ba                	add	a5,a5,a4
    800025c0:	1107a703          	lw	a4,272(a5)
    800025c4:	4785                	li	a5,1
    800025c6:	06f71763          	bne	a4,a5,80002634 <sched+0xa6>
  if(p->state == RUNNING)
    800025ca:	4c98                	lw	a4,24(s1)
    800025cc:	4791                	li	a5,4
    800025ce:	06f70b63          	beq	a4,a5,80002644 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025d2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025d6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025d8:	efb5                	bnez	a5,80002654 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025da:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025dc:	0000f917          	auipc	s2,0xf
    800025e0:	cc490913          	addi	s2,s2,-828 # 800112a0 <cpus_ll>
    800025e4:	2781                	sext.w	a5,a5
    800025e6:	079e                	slli	a5,a5,0x7
    800025e8:	97ca                	add	a5,a5,s2
    800025ea:	1147a983          	lw	s3,276(a5)
    800025ee:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800025f0:	2781                	sext.w	a5,a5
    800025f2:	079e                	slli	a5,a5,0x7
    800025f4:	0000f597          	auipc	a1,0xf
    800025f8:	d4c58593          	addi	a1,a1,-692 # 80011340 <cpus+0x8>
    800025fc:	95be                	add	a1,a1,a5
    800025fe:	08048513          	addi	a0,s1,128
    80002602:	00000097          	auipc	ra,0x0
    80002606:	7f4080e7          	jalr	2036(ra) # 80002df6 <swtch>
    8000260a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000260c:	2781                	sext.w	a5,a5
    8000260e:	079e                	slli	a5,a5,0x7
    80002610:	97ca                	add	a5,a5,s2
    80002612:	1137aa23          	sw	s3,276(a5)
}
    80002616:	70a2                	ld	ra,40(sp)
    80002618:	7402                	ld	s0,32(sp)
    8000261a:	64e2                	ld	s1,24(sp)
    8000261c:	6942                	ld	s2,16(sp)
    8000261e:	69a2                	ld	s3,8(sp)
    80002620:	6145                	addi	sp,sp,48
    80002622:	8082                	ret
    panic("sched p->lock");
    80002624:	00006517          	auipc	a0,0x6
    80002628:	c9c50513          	addi	a0,a0,-868 # 800082c0 <digits+0x280>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>
    panic("sched locks");
    80002634:	00006517          	auipc	a0,0x6
    80002638:	c9c50513          	addi	a0,a0,-868 # 800082d0 <digits+0x290>
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>
    panic("sched running");
    80002644:	00006517          	auipc	a0,0x6
    80002648:	c9c50513          	addi	a0,a0,-868 # 800082e0 <digits+0x2a0>
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002654:	00006517          	auipc	a0,0x6
    80002658:	c9c50513          	addi	a0,a0,-868 # 800082f0 <digits+0x2b0>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>

0000000080002664 <yield>:
{
    80002664:	7139                	addi	sp,sp,-64
    80002666:	fc06                	sd	ra,56(sp)
    80002668:	f822                	sd	s0,48(sp)
    8000266a:	f426                	sd	s1,40(sp)
    8000266c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	768080e7          	jalr	1896(ra) # 80001dd6 <myproc>
    80002676:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	56c080e7          	jalr	1388(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002680:	478d                	li	a5,3
    80002682:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index, &cpus_ll[p->cpu_num], cpus_head[p->cpu_num]);
    80002684:	58d8                	lw	a4,52(s1)
    80002686:	0000f597          	auipc	a1,0xf
    8000268a:	c1a58593          	addi	a1,a1,-998 # 800112a0 <cpus_ll>
    8000268e:	00171793          	slli	a5,a4,0x1
    80002692:	97ba                	add	a5,a5,a4
    80002694:	078e                	slli	a5,a5,0x3
    80002696:	97ae                	add	a5,a5,a1
    80002698:	4987b683          	ld	a3,1176(a5)
    8000269c:	fcd43023          	sd	a3,-64(s0)
    800026a0:	4a07b683          	ld	a3,1184(a5)
    800026a4:	fcd43423          	sd	a3,-56(s0)
    800026a8:	4a87b783          	ld	a5,1192(a5)
    800026ac:	fcf43823          	sd	a5,-48(s0)
    800026b0:	070a                	slli	a4,a4,0x2
    800026b2:	fc040613          	addi	a2,s0,-64
    800026b6:	95ba                	add	a1,a1,a4
    800026b8:	5c88                	lw	a0,56(s1)
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	400080e7          	jalr	1024(ra) # 80001aba <insert_to_list>
  sched();
    800026c2:	00000097          	auipc	ra,0x0
    800026c6:	ecc080e7          	jalr	-308(ra) # 8000258e <sched>
  release(&p->lock);
    800026ca:	8526                	mv	a0,s1
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	5cc080e7          	jalr	1484(ra) # 80000c98 <release>
}
    800026d4:	70e2                	ld	ra,56(sp)
    800026d6:	7442                	ld	s0,48(sp)
    800026d8:	74a2                	ld	s1,40(sp)
    800026da:	6121                	addi	sp,sp,64
    800026dc:	8082                	ret

00000000800026de <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800026de:	715d                	addi	sp,sp,-80
    800026e0:	e486                	sd	ra,72(sp)
    800026e2:	e0a2                	sd	s0,64(sp)
    800026e4:	fc26                	sd	s1,56(sp)
    800026e6:	f84a                	sd	s2,48(sp)
    800026e8:	f44e                	sd	s3,40(sp)
    800026ea:	0880                	addi	s0,sp,80
    800026ec:	89aa                	mv	s3,a0
    800026ee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800026f0:	fffff097          	auipc	ra,0xfffff
    800026f4:	6e6080e7          	jalr	1766(ra) # 80001dd6 <myproc>
    800026f8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.
  // Go to sleep.
  // cas(&p->state, RUNNING, SLEEPING);
  //printf("the number of locks is:%d\n",mycpu()->noff);
  insert_to_list(p->index, &sleeping, sleeping_head);
    800026fa:	0000f797          	auipc	a5,0xf
    800026fe:	ba678793          	addi	a5,a5,-1114 # 800112a0 <cpus_ll>
    80002702:	6bb8                	ld	a4,80(a5)
    80002704:	fae43823          	sd	a4,-80(s0)
    80002708:	6fb8                	ld	a4,88(a5)
    8000270a:	fae43c23          	sd	a4,-72(s0)
    8000270e:	73bc                	ld	a5,96(a5)
    80002710:	fcf43023          	sd	a5,-64(s0)
    80002714:	fb040613          	addi	a2,s0,-80
    80002718:	00006597          	auipc	a1,0x6
    8000271c:	1b458593          	addi	a1,a1,436 # 800088cc <sleeping>
    80002720:	5d08                	lw	a0,56(a0)
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	398080e7          	jalr	920(ra) # 80001aba <insert_to_list>
  p->chan = chan;
    8000272a:	0334b023          	sd	s3,32(s1)
  // if (p->state == RUNNING){
  //   p->state = SLEEPING;
  //   }
  cas(&p->state, RUNNING, RUNNABLE);
    8000272e:	460d                	li	a2,3
    80002730:	4591                	li	a1,4
    80002732:	01848513          	addi	a0,s1,24
    80002736:	00004097          	auipc	ra,0x4
    8000273a:	2b0080e7          	jalr	688(ra) # 800069e6 <cas>
  release(lk);
    8000273e:	854a                	mv	a0,s2
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	558080e7          	jalr	1368(ra) # 80000c98 <release>
  acquire(&p->lock);  //DOC: sleeplock1
    80002748:	8526                	mv	a0,s1
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	49a080e7          	jalr	1178(ra) # 80000be4 <acquire>
  sched();
    80002752:	00000097          	auipc	ra,0x0
    80002756:	e3c080e7          	jalr	-452(ra) # 8000258e <sched>
  // Tidy up.
  p->chan = 0;
    8000275a:	0204b023          	sd	zero,32(s1)
  // Reacquire original lock.
  release(&p->lock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	538080e7          	jalr	1336(ra) # 80000c98 <release>
  acquire(lk);
    80002768:	854a                	mv	a0,s2
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	47a080e7          	jalr	1146(ra) # 80000be4 <acquire>
    //printf("exit sleep\n");

}
    80002772:	60a6                	ld	ra,72(sp)
    80002774:	6406                	ld	s0,64(sp)
    80002776:	74e2                	ld	s1,56(sp)
    80002778:	7942                	ld	s2,48(sp)
    8000277a:	79a2                	ld	s3,40(sp)
    8000277c:	6161                	addi	sp,sp,80
    8000277e:	8082                	ret

0000000080002780 <wait>:
{
    80002780:	715d                	addi	sp,sp,-80
    80002782:	e486                	sd	ra,72(sp)
    80002784:	e0a2                	sd	s0,64(sp)
    80002786:	fc26                	sd	s1,56(sp)
    80002788:	f84a                	sd	s2,48(sp)
    8000278a:	f44e                	sd	s3,40(sp)
    8000278c:	f052                	sd	s4,32(sp)
    8000278e:	ec56                	sd	s5,24(sp)
    80002790:	e85a                	sd	s6,16(sp)
    80002792:	e45e                	sd	s7,8(sp)
    80002794:	e062                	sd	s8,0(sp)
    80002796:	0880                	addi	s0,sp,80
    80002798:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	63c080e7          	jalr	1596(ra) # 80001dd6 <myproc>
    800027a2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027a4:	0000f517          	auipc	a0,0xf
    800027a8:	b3450513          	addi	a0,a0,-1228 # 800112d8 <wait_lock>
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	438080e7          	jalr	1080(ra) # 80000be4 <acquire>
    havekids = 0;
    800027b4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027b6:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800027b8:	00015997          	auipc	s3,0x15
    800027bc:	24098993          	addi	s3,s3,576 # 800179f8 <tickslock>
        havekids = 1;
    800027c0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027c2:	0000fc17          	auipc	s8,0xf
    800027c6:	b16c0c13          	addi	s8,s8,-1258 # 800112d8 <wait_lock>
    havekids = 0;
    800027ca:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027cc:	0000f497          	auipc	s1,0xf
    800027d0:	02c48493          	addi	s1,s1,44 # 800117f8 <proc>
    800027d4:	a0bd                	j	80002842 <wait+0xc2>
          pid = np->pid;
    800027d6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027da:	000b0e63          	beqz	s6,800027f6 <wait+0x76>
    800027de:	4691                	li	a3,4
    800027e0:	02c48613          	addi	a2,s1,44
    800027e4:	85da                	mv	a1,s6
    800027e6:	07093503          	ld	a0,112(s2)
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	e88080e7          	jalr	-376(ra) # 80001672 <copyout>
    800027f2:	02054563          	bltz	a0,8000281c <wait+0x9c>
          freeproc(np);
    800027f6:	8526                	mv	a0,s1
    800027f8:	fffff097          	auipc	ra,0xfffff
    800027fc:	782080e7          	jalr	1922(ra) # 80001f7a <freeproc>
          release(&np->lock);
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	496080e7          	jalr	1174(ra) # 80000c98 <release>
          release(&wait_lock);
    8000280a:	0000f517          	auipc	a0,0xf
    8000280e:	ace50513          	addi	a0,a0,-1330 # 800112d8 <wait_lock>
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
          return pid;
    8000281a:	a09d                	j	80002880 <wait+0x100>
            release(&np->lock);
    8000281c:	8526                	mv	a0,s1
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	47a080e7          	jalr	1146(ra) # 80000c98 <release>
            release(&wait_lock);
    80002826:	0000f517          	auipc	a0,0xf
    8000282a:	ab250513          	addi	a0,a0,-1358 # 800112d8 <wait_lock>
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	46a080e7          	jalr	1130(ra) # 80000c98 <release>
            return -1;
    80002836:	59fd                	li	s3,-1
    80002838:	a0a1                	j	80002880 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000283a:	18848493          	addi	s1,s1,392
    8000283e:	03348463          	beq	s1,s3,80002866 <wait+0xe6>
      if(np->parent == p){
    80002842:	6cbc                	ld	a5,88(s1)
    80002844:	ff279be3          	bne	a5,s2,8000283a <wait+0xba>
        acquire(&np->lock);
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	39a080e7          	jalr	922(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002852:	4c9c                	lw	a5,24(s1)
    80002854:	f94781e3          	beq	a5,s4,800027d6 <wait+0x56>
        release(&np->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	43e080e7          	jalr	1086(ra) # 80000c98 <release>
        havekids = 1;
    80002862:	8756                	mv	a4,s5
    80002864:	bfd9                	j	8000283a <wait+0xba>
    if(!havekids || p->killed){
    80002866:	c701                	beqz	a4,8000286e <wait+0xee>
    80002868:	02892783          	lw	a5,40(s2)
    8000286c:	c79d                	beqz	a5,8000289a <wait+0x11a>
      release(&wait_lock);
    8000286e:	0000f517          	auipc	a0,0xf
    80002872:	a6a50513          	addi	a0,a0,-1430 # 800112d8 <wait_lock>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
      return -1;
    8000287e:	59fd                	li	s3,-1
}
    80002880:	854e                	mv	a0,s3
    80002882:	60a6                	ld	ra,72(sp)
    80002884:	6406                	ld	s0,64(sp)
    80002886:	74e2                	ld	s1,56(sp)
    80002888:	7942                	ld	s2,48(sp)
    8000288a:	79a2                	ld	s3,40(sp)
    8000288c:	7a02                	ld	s4,32(sp)
    8000288e:	6ae2                	ld	s5,24(sp)
    80002890:	6b42                	ld	s6,16(sp)
    80002892:	6ba2                	ld	s7,8(sp)
    80002894:	6c02                	ld	s8,0(sp)
    80002896:	6161                	addi	sp,sp,80
    80002898:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000289a:	85e2                	mv	a1,s8
    8000289c:	854a                	mv	a0,s2
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	e40080e7          	jalr	-448(ra) # 800026de <sleep>
    havekids = 0;
    800028a6:	b715                	j	800027ca <wait+0x4a>

00000000800028a8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028a8:	7119                	addi	sp,sp,-128
    800028aa:	fc86                	sd	ra,120(sp)
    800028ac:	f8a2                	sd	s0,112(sp)
    800028ae:	f4a6                	sd	s1,104(sp)
    800028b0:	f0ca                	sd	s2,96(sp)
    800028b2:	ecce                	sd	s3,88(sp)
    800028b4:	e8d2                	sd	s4,80(sp)
    800028b6:	e4d6                	sd	s5,72(sp)
    800028b8:	e0da                	sd	s6,64(sp)
    800028ba:	fc5e                	sd	s7,56(sp)
    800028bc:	f862                	sd	s8,48(sp)
    800028be:	f466                	sd	s9,40(sp)
    800028c0:	0100                	addi	s0,sp,128
  struct proc *p;
  if (sleeping == -1){
    800028c2:	00006497          	auipc	s1,0x6
    800028c6:	00a4a483          	lw	s1,10(s1) # 800088cc <sleeping>
    800028ca:	57fd                	li	a5,-1
    800028cc:	0ef48f63          	beq	s1,a5,800029ca <wakeup+0x122>
    800028d0:	89aa                	mv	s3,a0
    return;
  }
  p = &proc[sleeping];
    800028d2:	18800793          	li	a5,392
    800028d6:	02f484b3          	mul	s1,s1,a5
    800028da:	0000f797          	auipc	a5,0xf
    800028de:	f1e78793          	addi	a5,a5,-226 # 800117f8 <proc>
    800028e2:	94be                	add	s1,s1,a5
  int curr= proc[sleeping].index;
  while(curr!=-1) { // loop through all sleepers
    800028e4:	5c98                	lw	a4,56(s1)
    800028e6:	57fd                	li	a5,-1
    800028e8:	0ef70163          	beq	a4,a5,800029ca <wakeup+0x122>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->chan == chan && p->state == SLEEPING) {
    800028ec:	4b09                	li	s6,2
        remove_from_list(p->index, &sleeping, sleeping_head);
    800028ee:	0000fb97          	auipc	s7,0xf
    800028f2:	9b2b8b93          	addi	s7,s7,-1614 # 800112a0 <cpus_ll>
    800028f6:	00006c17          	auipc	s8,0x6
    800028fa:	fd6c0c13          	addi	s8,s8,-42 # 800088cc <sleeping>
        cas(&p->state, SLEEPING, RUNNABLE);
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
      }
      release(&p->lock);
    }
    if(p->next!=-1)
    800028fe:	597d                	li	s2,-1
      p = &proc[p->next];
    80002900:	18800a93          	li	s5,392
    80002904:	0000fa17          	auipc	s4,0xf
    80002908:	ef4a0a13          	addi	s4,s4,-268 # 800117f8 <proc>
    8000290c:	a01d                	j	80002932 <wakeup+0x8a>
      release(&p->lock);
    8000290e:	8566                	mv	a0,s9
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	388080e7          	jalr	904(ra) # 80000c98 <release>
    if(p->next!=-1)
    80002918:	5cdc                	lw	a5,60(s1)
    8000291a:	2781                	sext.w	a5,a5
    8000291c:	01278763          	beq	a5,s2,8000292a <wakeup+0x82>
      p = &proc[p->next];
    80002920:	5cc4                	lw	s1,60(s1)
    80002922:	2481                	sext.w	s1,s1
    80002924:	035484b3          	mul	s1,s1,s5
    80002928:	94d2                	add	s1,s1,s4
    curr=p->next;
    8000292a:	5cdc                	lw	a5,60(s1)
    8000292c:	2781                	sext.w	a5,a5
  while(curr!=-1) { // loop through all sleepers
    8000292e:	09278e63          	beq	a5,s2,800029ca <wakeup+0x122>
    if(p != myproc()){
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	4a4080e7          	jalr	1188(ra) # 80001dd6 <myproc>
    8000293a:	fca48fe3          	beq	s1,a0,80002918 <wakeup+0x70>
      acquire(&p->lock);
    8000293e:	8ca6                	mv	s9,s1
    80002940:	8526                	mv	a0,s1
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	2a2080e7          	jalr	674(ra) # 80000be4 <acquire>
      if(p->chan == chan && p->state == SLEEPING) {
    8000294a:	709c                	ld	a5,32(s1)
    8000294c:	fd3791e3          	bne	a5,s3,8000290e <wakeup+0x66>
    80002950:	4c9c                	lw	a5,24(s1)
    80002952:	fb679ee3          	bne	a5,s6,8000290e <wakeup+0x66>
        remove_from_list(p->index, &sleeping, sleeping_head);
    80002956:	050bb783          	ld	a5,80(s7)
    8000295a:	f8f43023          	sd	a5,-128(s0)
    8000295e:	058bb783          	ld	a5,88(s7)
    80002962:	f8f43423          	sd	a5,-120(s0)
    80002966:	060bb783          	ld	a5,96(s7)
    8000296a:	f8f43823          	sd	a5,-112(s0)
    8000296e:	f8040613          	addi	a2,s0,-128
    80002972:	85e2                	mv	a1,s8
    80002974:	5c88                	lw	a0,56(s1)
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	f86080e7          	jalr	-122(ra) # 800018fc <remove_from_list>
        p->chan=0;
    8000297e:	0204b023          	sd	zero,32(s1)
        cas(&p->state, SLEEPING, RUNNABLE);
    80002982:	460d                	li	a2,3
    80002984:	85da                	mv	a1,s6
    80002986:	01848513          	addi	a0,s1,24
    8000298a:	00004097          	auipc	ra,0x4
    8000298e:	05c080e7          	jalr	92(ra) # 800069e6 <cas>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
    80002992:	58cc                	lw	a1,52(s1)
    80002994:	00159793          	slli	a5,a1,0x1
    80002998:	97ae                	add	a5,a5,a1
    8000299a:	078e                	slli	a5,a5,0x3
    8000299c:	97de                	add	a5,a5,s7
    8000299e:	4987b703          	ld	a4,1176(a5)
    800029a2:	f8e43023          	sd	a4,-128(s0)
    800029a6:	4a07b703          	ld	a4,1184(a5)
    800029aa:	f8e43423          	sd	a4,-120(s0)
    800029ae:	4a87b783          	ld	a5,1192(a5)
    800029b2:	f8f43823          	sd	a5,-112(s0)
    800029b6:	058a                	slli	a1,a1,0x2
    800029b8:	f8040613          	addi	a2,s0,-128
    800029bc:	95de                	add	a1,a1,s7
    800029be:	5c88                	lw	a0,56(s1)
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	0fa080e7          	jalr	250(ra) # 80001aba <insert_to_list>
    800029c8:	b799                	j	8000290e <wakeup+0x66>
  }
}
    800029ca:	70e6                	ld	ra,120(sp)
    800029cc:	7446                	ld	s0,112(sp)
    800029ce:	74a6                	ld	s1,104(sp)
    800029d0:	7906                	ld	s2,96(sp)
    800029d2:	69e6                	ld	s3,88(sp)
    800029d4:	6a46                	ld	s4,80(sp)
    800029d6:	6aa6                	ld	s5,72(sp)
    800029d8:	6b06                	ld	s6,64(sp)
    800029da:	7be2                	ld	s7,56(sp)
    800029dc:	7c42                	ld	s8,48(sp)
    800029de:	7ca2                	ld	s9,40(sp)
    800029e0:	6109                	addi	sp,sp,128
    800029e2:	8082                	ret

00000000800029e4 <reparent>:
{
    800029e4:	7179                	addi	sp,sp,-48
    800029e6:	f406                	sd	ra,40(sp)
    800029e8:	f022                	sd	s0,32(sp)
    800029ea:	ec26                	sd	s1,24(sp)
    800029ec:	e84a                	sd	s2,16(sp)
    800029ee:	e44e                	sd	s3,8(sp)
    800029f0:	e052                	sd	s4,0(sp)
    800029f2:	1800                	addi	s0,sp,48
    800029f4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800029f6:	0000f497          	auipc	s1,0xf
    800029fa:	e0248493          	addi	s1,s1,-510 # 800117f8 <proc>
      pp->parent = initproc;
    800029fe:	00006a17          	auipc	s4,0x6
    80002a02:	62aa0a13          	addi	s4,s4,1578 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002a06:	00015997          	auipc	s3,0x15
    80002a0a:	ff298993          	addi	s3,s3,-14 # 800179f8 <tickslock>
    80002a0e:	a029                	j	80002a18 <reparent+0x34>
    80002a10:	18848493          	addi	s1,s1,392
    80002a14:	01348d63          	beq	s1,s3,80002a2e <reparent+0x4a>
    if(pp->parent == p){
    80002a18:	6cbc                	ld	a5,88(s1)
    80002a1a:	ff279be3          	bne	a5,s2,80002a10 <reparent+0x2c>
      pp->parent = initproc;
    80002a1e:	000a3503          	ld	a0,0(s4)
    80002a22:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	e84080e7          	jalr	-380(ra) # 800028a8 <wakeup>
    80002a2c:	b7d5                	j	80002a10 <reparent+0x2c>
}
    80002a2e:	70a2                	ld	ra,40(sp)
    80002a30:	7402                	ld	s0,32(sp)
    80002a32:	64e2                	ld	s1,24(sp)
    80002a34:	6942                	ld	s2,16(sp)
    80002a36:	69a2                	ld	s3,8(sp)
    80002a38:	6a02                	ld	s4,0(sp)
    80002a3a:	6145                	addi	sp,sp,48
    80002a3c:	8082                	ret

0000000080002a3e <exit>:
{
    80002a3e:	715d                	addi	sp,sp,-80
    80002a40:	e486                	sd	ra,72(sp)
    80002a42:	e0a2                	sd	s0,64(sp)
    80002a44:	fc26                	sd	s1,56(sp)
    80002a46:	f84a                	sd	s2,48(sp)
    80002a48:	f44e                	sd	s3,40(sp)
    80002a4a:	f052                	sd	s4,32(sp)
    80002a4c:	0880                	addi	s0,sp,80
    80002a4e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	386080e7          	jalr	902(ra) # 80001dd6 <myproc>
    80002a58:	89aa                	mv	s3,a0
  if(p == initproc)
    80002a5a:	00006797          	auipc	a5,0x6
    80002a5e:	5ce7b783          	ld	a5,1486(a5) # 80009028 <initproc>
    80002a62:	0f050493          	addi	s1,a0,240
    80002a66:	17050913          	addi	s2,a0,368
    80002a6a:	02a79363          	bne	a5,a0,80002a90 <exit+0x52>
    panic("init exiting");
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	89a50513          	addi	a0,a0,-1894 # 80008308 <digits+0x2c8>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	ac8080e7          	jalr	-1336(ra) # 8000053e <panic>
      fileclose(f);
    80002a7e:	00002097          	auipc	ra,0x2
    80002a82:	27a080e7          	jalr	634(ra) # 80004cf8 <fileclose>
      p->ofile[fd] = 0;
    80002a86:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a8a:	04a1                	addi	s1,s1,8
    80002a8c:	01248563          	beq	s1,s2,80002a96 <exit+0x58>
    if(p->ofile[fd]){
    80002a90:	6088                	ld	a0,0(s1)
    80002a92:	f575                	bnez	a0,80002a7e <exit+0x40>
    80002a94:	bfdd                	j	80002a8a <exit+0x4c>
  begin_op();
    80002a96:	00002097          	auipc	ra,0x2
    80002a9a:	d96080e7          	jalr	-618(ra) # 8000482c <begin_op>
  iput(p->cwd);
    80002a9e:	1709b503          	ld	a0,368(s3)
    80002aa2:	00001097          	auipc	ra,0x1
    80002aa6:	572080e7          	jalr	1394(ra) # 80004014 <iput>
  end_op();
    80002aaa:	00002097          	auipc	ra,0x2
    80002aae:	e02080e7          	jalr	-510(ra) # 800048ac <end_op>
  p->cwd = 0;
    80002ab2:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002ab6:	0000e497          	auipc	s1,0xe
    80002aba:	7ea48493          	addi	s1,s1,2026 # 800112a0 <cpus_ll>
    80002abe:	0000f917          	auipc	s2,0xf
    80002ac2:	81a90913          	addi	s2,s2,-2022 # 800112d8 <wait_lock>
    80002ac6:	854a                	mv	a0,s2
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	11c080e7          	jalr	284(ra) # 80000be4 <acquire>
  reparent(p);
    80002ad0:	854e                	mv	a0,s3
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	f12080e7          	jalr	-238(ra) # 800029e4 <reparent>
  wakeup(p->parent);
    80002ada:	0589b503          	ld	a0,88(s3)
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	dca080e7          	jalr	-566(ra) # 800028a8 <wakeup>
  acquire(&p->lock);
    80002ae6:	854e                	mv	a0,s3
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	0fc080e7          	jalr	252(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002af0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002af4:	4795                	li	a5,5
    80002af6:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index, &zombie, zombie_head);
    80002afa:	74bc                	ld	a5,104(s1)
    80002afc:	faf43823          	sd	a5,-80(s0)
    80002b00:	78bc                	ld	a5,112(s1)
    80002b02:	faf43c23          	sd	a5,-72(s0)
    80002b06:	7cbc                	ld	a5,120(s1)
    80002b08:	fcf43023          	sd	a5,-64(s0)
    80002b0c:	fb040613          	addi	a2,s0,-80
    80002b10:	00006597          	auipc	a1,0x6
    80002b14:	db858593          	addi	a1,a1,-584 # 800088c8 <zombie>
    80002b18:	0389a503          	lw	a0,56(s3)
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	f9e080e7          	jalr	-98(ra) # 80001aba <insert_to_list>
  release(&wait_lock);
    80002b24:	854a                	mv	a0,s2
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	172080e7          	jalr	370(ra) # 80000c98 <release>
  sched();
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	a60080e7          	jalr	-1440(ra) # 8000258e <sched>
  panic("zombie exit");
    80002b36:	00005517          	auipc	a0,0x5
    80002b3a:	7e250513          	addi	a0,a0,2018 # 80008318 <digits+0x2d8>
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	a00080e7          	jalr	-1536(ra) # 8000053e <panic>

0000000080002b46 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002b46:	715d                	addi	sp,sp,-80
    80002b48:	e486                	sd	ra,72(sp)
    80002b4a:	e0a2                	sd	s0,64(sp)
    80002b4c:	fc26                	sd	s1,56(sp)
    80002b4e:	f84a                	sd	s2,48(sp)
    80002b50:	f44e                	sd	s3,40(sp)
    80002b52:	0880                	addi	s0,sp,80
    80002b54:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002b56:	0000f497          	auipc	s1,0xf
    80002b5a:	ca248493          	addi	s1,s1,-862 # 800117f8 <proc>
    80002b5e:	00015997          	auipc	s3,0x15
    80002b62:	e9a98993          	addi	s3,s3,-358 # 800179f8 <tickslock>
    acquire(&p->lock);
    80002b66:	8526                	mv	a0,s1
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	07c080e7          	jalr	124(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002b70:	589c                	lw	a5,48(s1)
    80002b72:	01278d63          	beq	a5,s2,80002b8c <kill+0x46>
      if (ret != -1);
      insert_to_list(p->index, &cpus_ll[p->cpu_num], cpus_head[p->cpu_num]);
      }
      return 0;
    }
    release(&p->lock);
    80002b76:	8526                	mv	a0,s1
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	120080e7          	jalr	288(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b80:	18848493          	addi	s1,s1,392
    80002b84:	ff3491e3          	bne	s1,s3,80002b66 <kill+0x20>
  }
  return -1;
    80002b88:	557d                	li	a0,-1
    80002b8a:	a831                	j	80002ba6 <kill+0x60>
      p->killed = 1;
    80002b8c:	4785                	li	a5,1
    80002b8e:	d49c                	sw	a5,40(s1)
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002b90:	460d                	li	a2,3
    80002b92:	4589                	li	a1,2
    80002b94:	01848513          	addi	a0,s1,24
    80002b98:	00004097          	auipc	ra,0x4
    80002b9c:	e4e080e7          	jalr	-434(ra) # 800069e6 <cas>
    80002ba0:	87aa                	mv	a5,a0
      return 0;
    80002ba2:	4501                	li	a0,0
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002ba4:	cb81                	beqz	a5,80002bb4 <kill+0x6e>
}
    80002ba6:	60a6                	ld	ra,72(sp)
    80002ba8:	6406                	ld	s0,64(sp)
    80002baa:	74e2                	ld	s1,56(sp)
    80002bac:	7942                	ld	s2,48(sp)
    80002bae:	79a2                	ld	s3,40(sp)
    80002bb0:	6161                	addi	sp,sp,80
    80002bb2:	8082                	ret
        int ret = remove_from_list(p->index, &sleeping, sleeping_head);
    80002bb4:	0000e917          	auipc	s2,0xe
    80002bb8:	6ec90913          	addi	s2,s2,1772 # 800112a0 <cpus_ll>
    80002bbc:	05093783          	ld	a5,80(s2)
    80002bc0:	faf43823          	sd	a5,-80(s0)
    80002bc4:	05893783          	ld	a5,88(s2)
    80002bc8:	faf43c23          	sd	a5,-72(s0)
    80002bcc:	06093783          	ld	a5,96(s2)
    80002bd0:	fcf43023          	sd	a5,-64(s0)
    80002bd4:	fb040613          	addi	a2,s0,-80
    80002bd8:	00006597          	auipc	a1,0x6
    80002bdc:	cf458593          	addi	a1,a1,-780 # 800088cc <sleeping>
    80002be0:	5c88                	lw	a0,56(s1)
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	d1a080e7          	jalr	-742(ra) # 800018fc <remove_from_list>
      release(&p->lock);
    80002bea:	8526                	mv	a0,s1
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	0ac080e7          	jalr	172(ra) # 80000c98 <release>
      insert_to_list(p->index, &cpus_ll[p->cpu_num], cpus_head[p->cpu_num]);
    80002bf4:	58cc                	lw	a1,52(s1)
    80002bf6:	00159793          	slli	a5,a1,0x1
    80002bfa:	97ae                	add	a5,a5,a1
    80002bfc:	078e                	slli	a5,a5,0x3
    80002bfe:	97ca                	add	a5,a5,s2
    80002c00:	4987b703          	ld	a4,1176(a5)
    80002c04:	fae43823          	sd	a4,-80(s0)
    80002c08:	4a07b703          	ld	a4,1184(a5)
    80002c0c:	fae43c23          	sd	a4,-72(s0)
    80002c10:	4a87b783          	ld	a5,1192(a5)
    80002c14:	fcf43023          	sd	a5,-64(s0)
    80002c18:	058a                	slli	a1,a1,0x2
    80002c1a:	fb040613          	addi	a2,s0,-80
    80002c1e:	95ca                	add	a1,a1,s2
    80002c20:	5c88                	lw	a0,56(s1)
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	e98080e7          	jalr	-360(ra) # 80001aba <insert_to_list>
      return 0;
    80002c2a:	4501                	li	a0,0
    80002c2c:	bfad                	j	80002ba6 <kill+0x60>

0000000080002c2e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len){
    80002c2e:	7179                	addi	sp,sp,-48
    80002c30:	f406                	sd	ra,40(sp)
    80002c32:	f022                	sd	s0,32(sp)
    80002c34:	ec26                	sd	s1,24(sp)
    80002c36:	e84a                	sd	s2,16(sp)
    80002c38:	e44e                	sd	s3,8(sp)
    80002c3a:	e052                	sd	s4,0(sp)
    80002c3c:	1800                	addi	s0,sp,48
    80002c3e:	84aa                	mv	s1,a0
    80002c40:	892e                	mv	s2,a1
    80002c42:	89b2                	mv	s3,a2
    80002c44:	8a36                	mv	s4,a3

  struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	190080e7          	jalr	400(ra) # 80001dd6 <myproc>
  if(user_dst){
    80002c4e:	c08d                	beqz	s1,80002c70 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002c50:	86d2                	mv	a3,s4
    80002c52:	864e                	mv	a2,s3
    80002c54:	85ca                	mv	a1,s2
    80002c56:	7928                	ld	a0,112(a0)
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	a1a080e7          	jalr	-1510(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002c60:	70a2                	ld	ra,40(sp)
    80002c62:	7402                	ld	s0,32(sp)
    80002c64:	64e2                	ld	s1,24(sp)
    80002c66:	6942                	ld	s2,16(sp)
    80002c68:	69a2                	ld	s3,8(sp)
    80002c6a:	6a02                	ld	s4,0(sp)
    80002c6c:	6145                	addi	sp,sp,48
    80002c6e:	8082                	ret
    memmove((char *)dst, src, len);
    80002c70:	000a061b          	sext.w	a2,s4
    80002c74:	85ce                	mv	a1,s3
    80002c76:	854a                	mv	a0,s2
    80002c78:	ffffe097          	auipc	ra,0xffffe
    80002c7c:	0c8080e7          	jalr	200(ra) # 80000d40 <memmove>
    return 0;
    80002c80:	8526                	mv	a0,s1
    80002c82:	bff9                	j	80002c60 <either_copyout+0x32>

0000000080002c84 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c84:	7179                	addi	sp,sp,-48
    80002c86:	f406                	sd	ra,40(sp)
    80002c88:	f022                	sd	s0,32(sp)
    80002c8a:	ec26                	sd	s1,24(sp)
    80002c8c:	e84a                	sd	s2,16(sp)
    80002c8e:	e44e                	sd	s3,8(sp)
    80002c90:	e052                	sd	s4,0(sp)
    80002c92:	1800                	addi	s0,sp,48
    80002c94:	892a                	mv	s2,a0
    80002c96:	84ae                	mv	s1,a1
    80002c98:	89b2                	mv	s3,a2
    80002c9a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	13a080e7          	jalr	314(ra) # 80001dd6 <myproc>
  if(user_src){
    80002ca4:	c08d                	beqz	s1,80002cc6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002ca6:	86d2                	mv	a3,s4
    80002ca8:	864e                	mv	a2,s3
    80002caa:	85ca                	mv	a1,s2
    80002cac:	7928                	ld	a0,112(a0)
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	a50080e7          	jalr	-1456(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002cb6:	70a2                	ld	ra,40(sp)
    80002cb8:	7402                	ld	s0,32(sp)
    80002cba:	64e2                	ld	s1,24(sp)
    80002cbc:	6942                	ld	s2,16(sp)
    80002cbe:	69a2                	ld	s3,8(sp)
    80002cc0:	6a02                	ld	s4,0(sp)
    80002cc2:	6145                	addi	sp,sp,48
    80002cc4:	8082                	ret
    memmove(dst, (char*)src, len);
    80002cc6:	000a061b          	sext.w	a2,s4
    80002cca:	85ce                	mv	a1,s3
    80002ccc:	854a                	mv	a0,s2
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	072080e7          	jalr	114(ra) # 80000d40 <memmove>
    return 0;
    80002cd6:	8526                	mv	a0,s1
    80002cd8:	bff9                	j	80002cb6 <either_copyin+0x32>

0000000080002cda <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002cda:	715d                	addi	sp,sp,-80
    80002cdc:	e486                	sd	ra,72(sp)
    80002cde:	e0a2                	sd	s0,64(sp)
    80002ce0:	fc26                	sd	s1,56(sp)
    80002ce2:	f84a                	sd	s2,48(sp)
    80002ce4:	f44e                	sd	s3,40(sp)
    80002ce6:	f052                	sd	s4,32(sp)
    80002ce8:	ec56                	sd	s5,24(sp)
    80002cea:	e85a                	sd	s6,16(sp)
    80002cec:	e45e                	sd	s7,8(sp)
    80002cee:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	3d850513          	addi	a0,a0,984 # 800080c8 <digits+0x88>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	890080e7          	jalr	-1904(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d00:	0000f497          	auipc	s1,0xf
    80002d04:	c7048493          	addi	s1,s1,-912 # 80011970 <proc+0x178>
    80002d08:	00015917          	auipc	s2,0x15
    80002d0c:	e6890913          	addi	s2,s2,-408 # 80017b70 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d10:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002d12:	00005997          	auipc	s3,0x5
    80002d16:	61698993          	addi	s3,s3,1558 # 80008328 <digits+0x2e8>
    printf("%d %s %s", p->pid, state, p->name);
    80002d1a:	00005a97          	auipc	s5,0x5
    80002d1e:	616a8a93          	addi	s5,s5,1558 # 80008330 <digits+0x2f0>
    printf("\n");
    80002d22:	00005a17          	auipc	s4,0x5
    80002d26:	3a6a0a13          	addi	s4,s4,934 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d2a:	00005b97          	auipc	s7,0x5
    80002d2e:	63eb8b93          	addi	s7,s7,1598 # 80008368 <states.1767>
    80002d32:	a00d                	j	80002d54 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002d34:	eb86a583          	lw	a1,-328(a3)
    80002d38:	8556                	mv	a0,s5
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	84e080e7          	jalr	-1970(ra) # 80000588 <printf>
    printf("\n");
    80002d42:	8552                	mv	a0,s4
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	844080e7          	jalr	-1980(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d4c:	18848493          	addi	s1,s1,392
    80002d50:	03248163          	beq	s1,s2,80002d72 <procdump+0x98>
    if(p->state == UNUSED)
    80002d54:	86a6                	mv	a3,s1
    80002d56:	ea04a783          	lw	a5,-352(s1)
    80002d5a:	dbed                	beqz	a5,80002d4c <procdump+0x72>
      state = "???";
    80002d5c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d5e:	fcfb6be3          	bltu	s6,a5,80002d34 <procdump+0x5a>
    80002d62:	1782                	slli	a5,a5,0x20
    80002d64:	9381                	srli	a5,a5,0x20
    80002d66:	078e                	slli	a5,a5,0x3
    80002d68:	97de                	add	a5,a5,s7
    80002d6a:	6390                	ld	a2,0(a5)
    80002d6c:	f661                	bnez	a2,80002d34 <procdump+0x5a>
      state = "???";
    80002d6e:	864e                	mv	a2,s3
    80002d70:	b7d1                	j	80002d34 <procdump+0x5a>
  }
}
    80002d72:	60a6                	ld	ra,72(sp)
    80002d74:	6406                	ld	s0,64(sp)
    80002d76:	74e2                	ld	s1,56(sp)
    80002d78:	7942                	ld	s2,48(sp)
    80002d7a:	79a2                	ld	s3,40(sp)
    80002d7c:	7a02                	ld	s4,32(sp)
    80002d7e:	6ae2                	ld	s5,24(sp)
    80002d80:	6b42                	ld	s6,16(sp)
    80002d82:	6ba2                	ld	s7,8(sp)
    80002d84:	6161                	addi	sp,sp,80
    80002d86:	8082                	ret

0000000080002d88 <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	e426                	sd	s1,8(sp)
    80002d90:	1000                	addi	s0,sp,32
    80002d92:	84aa                	mv	s1,a0
// printf("%d\n", 12);
  struct proc *p= myproc();  
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	042080e7          	jalr	66(ra) # 80001dd6 <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002d9c:	8626                	mv	a2,s1
    80002d9e:	594c                	lw	a1,52(a0)
    80002da0:	03450513          	addi	a0,a0,52
    80002da4:	00004097          	auipc	ra,0x4
    80002da8:	c42080e7          	jalr	-958(ra) # 800069e6 <cas>
    80002dac:	e519                	bnez	a0,80002dba <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002dae:	4501                	li	a0,0
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret
    yield();
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	8aa080e7          	jalr	-1878(ra) # 80002664 <yield>
    return cpu_num;
    80002dc2:	8526                	mv	a0,s1
    80002dc4:	b7f5                	j	80002db0 <set_cpu+0x28>

0000000080002dc6 <get_cpu>:

int get_cpu(){ //added as orderd
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	1000                	addi	s0,sp,32
// printf("%d\n", 13);
  struct proc *p=myproc();
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	008080e7          	jalr	8(ra) # 80001dd6 <myproc>
  int ans=0;
    80002dd6:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002dda:	5950                	lw	a2,52(a0)
    80002ddc:	4581                	li	a1,0
    80002dde:	fec40513          	addi	a0,s0,-20
    80002de2:	00004097          	auipc	ra,0x4
    80002de6:	c04080e7          	jalr	-1020(ra) # 800069e6 <cas>
    return ans;
}
    80002dea:	fec42503          	lw	a0,-20(s0)
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	6105                	addi	sp,sp,32
    80002df4:	8082                	ret

0000000080002df6 <swtch>:
    80002df6:	00153023          	sd	ra,0(a0)
    80002dfa:	00253423          	sd	sp,8(a0)
    80002dfe:	e900                	sd	s0,16(a0)
    80002e00:	ed04                	sd	s1,24(a0)
    80002e02:	03253023          	sd	s2,32(a0)
    80002e06:	03353423          	sd	s3,40(a0)
    80002e0a:	03453823          	sd	s4,48(a0)
    80002e0e:	03553c23          	sd	s5,56(a0)
    80002e12:	05653023          	sd	s6,64(a0)
    80002e16:	05753423          	sd	s7,72(a0)
    80002e1a:	05853823          	sd	s8,80(a0)
    80002e1e:	05953c23          	sd	s9,88(a0)
    80002e22:	07a53023          	sd	s10,96(a0)
    80002e26:	07b53423          	sd	s11,104(a0)
    80002e2a:	0005b083          	ld	ra,0(a1)
    80002e2e:	0085b103          	ld	sp,8(a1)
    80002e32:	6980                	ld	s0,16(a1)
    80002e34:	6d84                	ld	s1,24(a1)
    80002e36:	0205b903          	ld	s2,32(a1)
    80002e3a:	0285b983          	ld	s3,40(a1)
    80002e3e:	0305ba03          	ld	s4,48(a1)
    80002e42:	0385ba83          	ld	s5,56(a1)
    80002e46:	0405bb03          	ld	s6,64(a1)
    80002e4a:	0485bb83          	ld	s7,72(a1)
    80002e4e:	0505bc03          	ld	s8,80(a1)
    80002e52:	0585bc83          	ld	s9,88(a1)
    80002e56:	0605bd03          	ld	s10,96(a1)
    80002e5a:	0685bd83          	ld	s11,104(a1)
    80002e5e:	8082                	ret

0000000080002e60 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002e60:	1141                	addi	sp,sp,-16
    80002e62:	e406                	sd	ra,8(sp)
    80002e64:	e022                	sd	s0,0(sp)
    80002e66:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e68:	00005597          	auipc	a1,0x5
    80002e6c:	53058593          	addi	a1,a1,1328 # 80008398 <states.1767+0x30>
    80002e70:	00015517          	auipc	a0,0x15
    80002e74:	b8850513          	addi	a0,a0,-1144 # 800179f8 <tickslock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	cdc080e7          	jalr	-804(ra) # 80000b54 <initlock>
}
    80002e80:	60a2                	ld	ra,8(sp)
    80002e82:	6402                	ld	s0,0(sp)
    80002e84:	0141                	addi	sp,sp,16
    80002e86:	8082                	ret

0000000080002e88 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e88:	1141                	addi	sp,sp,-16
    80002e8a:	e422                	sd	s0,8(sp)
    80002e8c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e8e:	00003797          	auipc	a5,0x3
    80002e92:	48278793          	addi	a5,a5,1154 # 80006310 <kernelvec>
    80002e96:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e9a:	6422                	ld	s0,8(sp)
    80002e9c:	0141                	addi	sp,sp,16
    80002e9e:	8082                	ret

0000000080002ea0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ea0:	1141                	addi	sp,sp,-16
    80002ea2:	e406                	sd	ra,8(sp)
    80002ea4:	e022                	sd	s0,0(sp)
    80002ea6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	f2e080e7          	jalr	-210(ra) # 80001dd6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002eb4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eb6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002eba:	00004617          	auipc	a2,0x4
    80002ebe:	14660613          	addi	a2,a2,326 # 80007000 <_trampoline>
    80002ec2:	00004697          	auipc	a3,0x4
    80002ec6:	13e68693          	addi	a3,a3,318 # 80007000 <_trampoline>
    80002eca:	8e91                	sub	a3,a3,a2
    80002ecc:	040007b7          	lui	a5,0x4000
    80002ed0:	17fd                	addi	a5,a5,-1
    80002ed2:	07b2                	slli	a5,a5,0xc
    80002ed4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ed6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002eda:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002edc:	180026f3          	csrr	a3,satp
    80002ee0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ee2:	7d38                	ld	a4,120(a0)
    80002ee4:	7134                	ld	a3,96(a0)
    80002ee6:	6585                	lui	a1,0x1
    80002ee8:	96ae                	add	a3,a3,a1
    80002eea:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002eec:	7d38                	ld	a4,120(a0)
    80002eee:	00000697          	auipc	a3,0x0
    80002ef2:	13868693          	addi	a3,a3,312 # 80003026 <usertrap>
    80002ef6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ef8:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002efa:	8692                	mv	a3,tp
    80002efc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002efe:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f02:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002f06:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f0a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f0e:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f10:	6f18                	ld	a4,24(a4)
    80002f12:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f16:	792c                	ld	a1,112(a0)
    80002f18:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f1a:	00004717          	auipc	a4,0x4
    80002f1e:	17670713          	addi	a4,a4,374 # 80007090 <userret>
    80002f22:	8f11                	sub	a4,a4,a2
    80002f24:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f26:	577d                	li	a4,-1
    80002f28:	177e                	slli	a4,a4,0x3f
    80002f2a:	8dd9                	or	a1,a1,a4
    80002f2c:	02000537          	lui	a0,0x2000
    80002f30:	157d                	addi	a0,a0,-1
    80002f32:	0536                	slli	a0,a0,0xd
    80002f34:	9782                	jalr	a5
}
    80002f36:	60a2                	ld	ra,8(sp)
    80002f38:	6402                	ld	s0,0(sp)
    80002f3a:	0141                	addi	sp,sp,16
    80002f3c:	8082                	ret

0000000080002f3e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	e426                	sd	s1,8(sp)
    80002f46:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f48:	00015497          	auipc	s1,0x15
    80002f4c:	ab048493          	addi	s1,s1,-1360 # 800179f8 <tickslock>
    80002f50:	8526                	mv	a0,s1
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	c92080e7          	jalr	-878(ra) # 80000be4 <acquire>
  ticks++;
    80002f5a:	00006517          	auipc	a0,0x6
    80002f5e:	0d650513          	addi	a0,a0,214 # 80009030 <ticks>
    80002f62:	411c                	lw	a5,0(a0)
    80002f64:	2785                	addiw	a5,a5,1
    80002f66:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	940080e7          	jalr	-1728(ra) # 800028a8 <wakeup>
  release(&tickslock);
    80002f70:	8526                	mv	a0,s1
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	d26080e7          	jalr	-730(ra) # 80000c98 <release>
}
    80002f7a:	60e2                	ld	ra,24(sp)
    80002f7c:	6442                	ld	s0,16(sp)
    80002f7e:	64a2                	ld	s1,8(sp)
    80002f80:	6105                	addi	sp,sp,32
    80002f82:	8082                	ret

0000000080002f84 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f84:	1101                	addi	sp,sp,-32
    80002f86:	ec06                	sd	ra,24(sp)
    80002f88:	e822                	sd	s0,16(sp)
    80002f8a:	e426                	sd	s1,8(sp)
    80002f8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f8e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f92:	00074d63          	bltz	a4,80002fac <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f96:	57fd                	li	a5,-1
    80002f98:	17fe                	slli	a5,a5,0x3f
    80002f9a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f9c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f9e:	06f70363          	beq	a4,a5,80003004 <devintr+0x80>
  }
}
    80002fa2:	60e2                	ld	ra,24(sp)
    80002fa4:	6442                	ld	s0,16(sp)
    80002fa6:	64a2                	ld	s1,8(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret
     (scause & 0xff) == 9){
    80002fac:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002fb0:	46a5                	li	a3,9
    80002fb2:	fed792e3          	bne	a5,a3,80002f96 <devintr+0x12>
    int irq = plic_claim();
    80002fb6:	00003097          	auipc	ra,0x3
    80002fba:	462080e7          	jalr	1122(ra) # 80006418 <plic_claim>
    80002fbe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002fc0:	47a9                	li	a5,10
    80002fc2:	02f50763          	beq	a0,a5,80002ff0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002fc6:	4785                	li	a5,1
    80002fc8:	02f50963          	beq	a0,a5,80002ffa <devintr+0x76>
    return 1;
    80002fcc:	4505                	li	a0,1
    } else if(irq){
    80002fce:	d8f1                	beqz	s1,80002fa2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002fd0:	85a6                	mv	a1,s1
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	3ce50513          	addi	a0,a0,974 # 800083a0 <states.1767+0x38>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	5ae080e7          	jalr	1454(ra) # 80000588 <printf>
      plic_complete(irq);
    80002fe2:	8526                	mv	a0,s1
    80002fe4:	00003097          	auipc	ra,0x3
    80002fe8:	458080e7          	jalr	1112(ra) # 8000643c <plic_complete>
    return 1;
    80002fec:	4505                	li	a0,1
    80002fee:	bf55                	j	80002fa2 <devintr+0x1e>
      uartintr();
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	9b8080e7          	jalr	-1608(ra) # 800009a8 <uartintr>
    80002ff8:	b7ed                	j	80002fe2 <devintr+0x5e>
      virtio_disk_intr();
    80002ffa:	00004097          	auipc	ra,0x4
    80002ffe:	922080e7          	jalr	-1758(ra) # 8000691c <virtio_disk_intr>
    80003002:	b7c5                	j	80002fe2 <devintr+0x5e>
    if(cpuid() == 0){
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	da6080e7          	jalr	-602(ra) # 80001daa <cpuid>
    8000300c:	c901                	beqz	a0,8000301c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000300e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003012:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003014:	14479073          	csrw	sip,a5
    return 2;
    80003018:	4509                	li	a0,2
    8000301a:	b761                	j	80002fa2 <devintr+0x1e>
      clockintr();
    8000301c:	00000097          	auipc	ra,0x0
    80003020:	f22080e7          	jalr	-222(ra) # 80002f3e <clockintr>
    80003024:	b7ed                	j	8000300e <devintr+0x8a>

0000000080003026 <usertrap>:
{
    80003026:	1101                	addi	sp,sp,-32
    80003028:	ec06                	sd	ra,24(sp)
    8000302a:	e822                	sd	s0,16(sp)
    8000302c:	e426                	sd	s1,8(sp)
    8000302e:	e04a                	sd	s2,0(sp)
    80003030:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003032:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003036:	1007f793          	andi	a5,a5,256
    8000303a:	e3ad                	bnez	a5,8000309c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000303c:	00003797          	auipc	a5,0x3
    80003040:	2d478793          	addi	a5,a5,724 # 80006310 <kernelvec>
    80003044:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	d8e080e7          	jalr	-626(ra) # 80001dd6 <myproc>
    80003050:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003052:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003054:	14102773          	csrr	a4,sepc
    80003058:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000305a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000305e:	47a1                	li	a5,8
    80003060:	04f71c63          	bne	a4,a5,800030b8 <usertrap+0x92>
    if(p->killed)
    80003064:	551c                	lw	a5,40(a0)
    80003066:	e3b9                	bnez	a5,800030ac <usertrap+0x86>
    p->trapframe->epc += 4;
    80003068:	7cb8                	ld	a4,120(s1)
    8000306a:	6f1c                	ld	a5,24(a4)
    8000306c:	0791                	addi	a5,a5,4
    8000306e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003070:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003074:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003078:	10079073          	csrw	sstatus,a5
    syscall();
    8000307c:	00000097          	auipc	ra,0x0
    80003080:	2e0080e7          	jalr	736(ra) # 8000335c <syscall>
  if(p->killed)
    80003084:	549c                	lw	a5,40(s1)
    80003086:	ebc1                	bnez	a5,80003116 <usertrap+0xf0>
  usertrapret();
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	e18080e7          	jalr	-488(ra) # 80002ea0 <usertrapret>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6902                	ld	s2,0(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret
    panic("usertrap: not from user mode");
    8000309c:	00005517          	auipc	a0,0x5
    800030a0:	32450513          	addi	a0,a0,804 # 800083c0 <states.1767+0x58>
    800030a4:	ffffd097          	auipc	ra,0xffffd
    800030a8:	49a080e7          	jalr	1178(ra) # 8000053e <panic>
      exit(-1);
    800030ac:	557d                	li	a0,-1
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	990080e7          	jalr	-1648(ra) # 80002a3e <exit>
    800030b6:	bf4d                	j	80003068 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800030b8:	00000097          	auipc	ra,0x0
    800030bc:	ecc080e7          	jalr	-308(ra) # 80002f84 <devintr>
    800030c0:	892a                	mv	s2,a0
    800030c2:	c501                	beqz	a0,800030ca <usertrap+0xa4>
  if(p->killed)
    800030c4:	549c                	lw	a5,40(s1)
    800030c6:	c3a1                	beqz	a5,80003106 <usertrap+0xe0>
    800030c8:	a815                	j	800030fc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030ca:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800030ce:	5890                	lw	a2,48(s1)
    800030d0:	00005517          	auipc	a0,0x5
    800030d4:	31050513          	addi	a0,a0,784 # 800083e0 <states.1767+0x78>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	4b0080e7          	jalr	1200(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030e0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030e4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030e8:	00005517          	auipc	a0,0x5
    800030ec:	32850513          	addi	a0,a0,808 # 80008410 <states.1767+0xa8>
    800030f0:	ffffd097          	auipc	ra,0xffffd
    800030f4:	498080e7          	jalr	1176(ra) # 80000588 <printf>
    p->killed = 1;
    800030f8:	4785                	li	a5,1
    800030fa:	d49c                	sw	a5,40(s1)
    exit(-1);
    800030fc:	557d                	li	a0,-1
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	940080e7          	jalr	-1728(ra) # 80002a3e <exit>
  if(which_dev == 2)
    80003106:	4789                	li	a5,2
    80003108:	f8f910e3          	bne	s2,a5,80003088 <usertrap+0x62>
    yield();
    8000310c:	fffff097          	auipc	ra,0xfffff
    80003110:	558080e7          	jalr	1368(ra) # 80002664 <yield>
    80003114:	bf95                	j	80003088 <usertrap+0x62>
  int which_dev = 0;
    80003116:	4901                	li	s2,0
    80003118:	b7d5                	j	800030fc <usertrap+0xd6>

000000008000311a <kerneltrap>:
{
    8000311a:	7179                	addi	sp,sp,-48
    8000311c:	f406                	sd	ra,40(sp)
    8000311e:	f022                	sd	s0,32(sp)
    80003120:	ec26                	sd	s1,24(sp)
    80003122:	e84a                	sd	s2,16(sp)
    80003124:	e44e                	sd	s3,8(sp)
    80003126:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003128:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000312c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003130:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003134:	1004f793          	andi	a5,s1,256
    80003138:	cb85                	beqz	a5,80003168 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000313a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000313e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003140:	ef85                	bnez	a5,80003178 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003142:	00000097          	auipc	ra,0x0
    80003146:	e42080e7          	jalr	-446(ra) # 80002f84 <devintr>
    8000314a:	cd1d                	beqz	a0,80003188 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000314c:	4789                	li	a5,2
    8000314e:	06f50a63          	beq	a0,a5,800031c2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003152:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003156:	10049073          	csrw	sstatus,s1
}
    8000315a:	70a2                	ld	ra,40(sp)
    8000315c:	7402                	ld	s0,32(sp)
    8000315e:	64e2                	ld	s1,24(sp)
    80003160:	6942                	ld	s2,16(sp)
    80003162:	69a2                	ld	s3,8(sp)
    80003164:	6145                	addi	sp,sp,48
    80003166:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003168:	00005517          	auipc	a0,0x5
    8000316c:	2c850513          	addi	a0,a0,712 # 80008430 <states.1767+0xc8>
    80003170:	ffffd097          	auipc	ra,0xffffd
    80003174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003178:	00005517          	auipc	a0,0x5
    8000317c:	2e050513          	addi	a0,a0,736 # 80008458 <states.1767+0xf0>
    80003180:	ffffd097          	auipc	ra,0xffffd
    80003184:	3be080e7          	jalr	958(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003188:	85ce                	mv	a1,s3
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	2ee50513          	addi	a0,a0,750 # 80008478 <states.1767+0x110>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	3f6080e7          	jalr	1014(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000319a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000319e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031a2:	00005517          	auipc	a0,0x5
    800031a6:	2e650513          	addi	a0,a0,742 # 80008488 <states.1767+0x120>
    800031aa:	ffffd097          	auipc	ra,0xffffd
    800031ae:	3de080e7          	jalr	990(ra) # 80000588 <printf>
    panic("kerneltrap");
    800031b2:	00005517          	auipc	a0,0x5
    800031b6:	2ee50513          	addi	a0,a0,750 # 800084a0 <states.1767+0x138>
    800031ba:	ffffd097          	auipc	ra,0xffffd
    800031be:	384080e7          	jalr	900(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031c2:	fffff097          	auipc	ra,0xfffff
    800031c6:	c14080e7          	jalr	-1004(ra) # 80001dd6 <myproc>
    800031ca:	d541                	beqz	a0,80003152 <kerneltrap+0x38>
    800031cc:	fffff097          	auipc	ra,0xfffff
    800031d0:	c0a080e7          	jalr	-1014(ra) # 80001dd6 <myproc>
    800031d4:	4d18                	lw	a4,24(a0)
    800031d6:	4791                	li	a5,4
    800031d8:	f6f71de3          	bne	a4,a5,80003152 <kerneltrap+0x38>
    yield();
    800031dc:	fffff097          	auipc	ra,0xfffff
    800031e0:	488080e7          	jalr	1160(ra) # 80002664 <yield>
    800031e4:	b7bd                	j	80003152 <kerneltrap+0x38>

00000000800031e6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	1000                	addi	s0,sp,32
    800031f0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800031f2:	fffff097          	auipc	ra,0xfffff
    800031f6:	be4080e7          	jalr	-1052(ra) # 80001dd6 <myproc>
  switch (n) {
    800031fa:	4795                	li	a5,5
    800031fc:	0497e163          	bltu	a5,s1,8000323e <argraw+0x58>
    80003200:	048a                	slli	s1,s1,0x2
    80003202:	00005717          	auipc	a4,0x5
    80003206:	2d670713          	addi	a4,a4,726 # 800084d8 <states.1767+0x170>
    8000320a:	94ba                	add	s1,s1,a4
    8000320c:	409c                	lw	a5,0(s1)
    8000320e:	97ba                	add	a5,a5,a4
    80003210:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003212:	7d3c                	ld	a5,120(a0)
    80003214:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret
    return p->trapframe->a1;
    80003220:	7d3c                	ld	a5,120(a0)
    80003222:	7fa8                	ld	a0,120(a5)
    80003224:	bfcd                	j	80003216 <argraw+0x30>
    return p->trapframe->a2;
    80003226:	7d3c                	ld	a5,120(a0)
    80003228:	63c8                	ld	a0,128(a5)
    8000322a:	b7f5                	j	80003216 <argraw+0x30>
    return p->trapframe->a3;
    8000322c:	7d3c                	ld	a5,120(a0)
    8000322e:	67c8                	ld	a0,136(a5)
    80003230:	b7dd                	j	80003216 <argraw+0x30>
    return p->trapframe->a4;
    80003232:	7d3c                	ld	a5,120(a0)
    80003234:	6bc8                	ld	a0,144(a5)
    80003236:	b7c5                	j	80003216 <argraw+0x30>
    return p->trapframe->a5;
    80003238:	7d3c                	ld	a5,120(a0)
    8000323a:	6fc8                	ld	a0,152(a5)
    8000323c:	bfe9                	j	80003216 <argraw+0x30>
  panic("argraw");
    8000323e:	00005517          	auipc	a0,0x5
    80003242:	27250513          	addi	a0,a0,626 # 800084b0 <states.1767+0x148>
    80003246:	ffffd097          	auipc	ra,0xffffd
    8000324a:	2f8080e7          	jalr	760(ra) # 8000053e <panic>

000000008000324e <fetchaddr>:
{
    8000324e:	1101                	addi	sp,sp,-32
    80003250:	ec06                	sd	ra,24(sp)
    80003252:	e822                	sd	s0,16(sp)
    80003254:	e426                	sd	s1,8(sp)
    80003256:	e04a                	sd	s2,0(sp)
    80003258:	1000                	addi	s0,sp,32
    8000325a:	84aa                	mv	s1,a0
    8000325c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000325e:	fffff097          	auipc	ra,0xfffff
    80003262:	b78080e7          	jalr	-1160(ra) # 80001dd6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003266:	753c                	ld	a5,104(a0)
    80003268:	02f4f863          	bgeu	s1,a5,80003298 <fetchaddr+0x4a>
    8000326c:	00848713          	addi	a4,s1,8
    80003270:	02e7e663          	bltu	a5,a4,8000329c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003274:	46a1                	li	a3,8
    80003276:	8626                	mv	a2,s1
    80003278:	85ca                	mv	a1,s2
    8000327a:	7928                	ld	a0,112(a0)
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	482080e7          	jalr	1154(ra) # 800016fe <copyin>
    80003284:	00a03533          	snez	a0,a0
    80003288:	40a00533          	neg	a0,a0
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6902                	ld	s2,0(sp)
    80003294:	6105                	addi	sp,sp,32
    80003296:	8082                	ret
    return -1;
    80003298:	557d                	li	a0,-1
    8000329a:	bfcd                	j	8000328c <fetchaddr+0x3e>
    8000329c:	557d                	li	a0,-1
    8000329e:	b7fd                	j	8000328c <fetchaddr+0x3e>

00000000800032a0 <fetchstr>:
{
    800032a0:	7179                	addi	sp,sp,-48
    800032a2:	f406                	sd	ra,40(sp)
    800032a4:	f022                	sd	s0,32(sp)
    800032a6:	ec26                	sd	s1,24(sp)
    800032a8:	e84a                	sd	s2,16(sp)
    800032aa:	e44e                	sd	s3,8(sp)
    800032ac:	1800                	addi	s0,sp,48
    800032ae:	892a                	mv	s2,a0
    800032b0:	84ae                	mv	s1,a1
    800032b2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800032b4:	fffff097          	auipc	ra,0xfffff
    800032b8:	b22080e7          	jalr	-1246(ra) # 80001dd6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800032bc:	86ce                	mv	a3,s3
    800032be:	864a                	mv	a2,s2
    800032c0:	85a6                	mv	a1,s1
    800032c2:	7928                	ld	a0,112(a0)
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	4c6080e7          	jalr	1222(ra) # 8000178a <copyinstr>
  if(err < 0)
    800032cc:	00054763          	bltz	a0,800032da <fetchstr+0x3a>
  return strlen(buf);
    800032d0:	8526                	mv	a0,s1
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	b92080e7          	jalr	-1134(ra) # 80000e64 <strlen>
}
    800032da:	70a2                	ld	ra,40(sp)
    800032dc:	7402                	ld	s0,32(sp)
    800032de:	64e2                	ld	s1,24(sp)
    800032e0:	6942                	ld	s2,16(sp)
    800032e2:	69a2                	ld	s3,8(sp)
    800032e4:	6145                	addi	sp,sp,48
    800032e6:	8082                	ret

00000000800032e8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800032e8:	1101                	addi	sp,sp,-32
    800032ea:	ec06                	sd	ra,24(sp)
    800032ec:	e822                	sd	s0,16(sp)
    800032ee:	e426                	sd	s1,8(sp)
    800032f0:	1000                	addi	s0,sp,32
    800032f2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	ef2080e7          	jalr	-270(ra) # 800031e6 <argraw>
    800032fc:	c088                	sw	a0,0(s1)
  return 0;
}
    800032fe:	4501                	li	a0,0
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6105                	addi	sp,sp,32
    80003308:	8082                	ret

000000008000330a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000330a:	1101                	addi	sp,sp,-32
    8000330c:	ec06                	sd	ra,24(sp)
    8000330e:	e822                	sd	s0,16(sp)
    80003310:	e426                	sd	s1,8(sp)
    80003312:	1000                	addi	s0,sp,32
    80003314:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	ed0080e7          	jalr	-304(ra) # 800031e6 <argraw>
    8000331e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003320:	4501                	li	a0,0
    80003322:	60e2                	ld	ra,24(sp)
    80003324:	6442                	ld	s0,16(sp)
    80003326:	64a2                	ld	s1,8(sp)
    80003328:	6105                	addi	sp,sp,32
    8000332a:	8082                	ret

000000008000332c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000332c:	1101                	addi	sp,sp,-32
    8000332e:	ec06                	sd	ra,24(sp)
    80003330:	e822                	sd	s0,16(sp)
    80003332:	e426                	sd	s1,8(sp)
    80003334:	e04a                	sd	s2,0(sp)
    80003336:	1000                	addi	s0,sp,32
    80003338:	84ae                	mv	s1,a1
    8000333a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	eaa080e7          	jalr	-342(ra) # 800031e6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003344:	864a                	mv	a2,s2
    80003346:	85a6                	mv	a1,s1
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	f58080e7          	jalr	-168(ra) # 800032a0 <fetchstr>
}
    80003350:	60e2                	ld	ra,24(sp)
    80003352:	6442                	ld	s0,16(sp)
    80003354:	64a2                	ld	s1,8(sp)
    80003356:	6902                	ld	s2,0(sp)
    80003358:	6105                	addi	sp,sp,32
    8000335a:	8082                	ret

000000008000335c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000335c:	1101                	addi	sp,sp,-32
    8000335e:	ec06                	sd	ra,24(sp)
    80003360:	e822                	sd	s0,16(sp)
    80003362:	e426                	sd	s1,8(sp)
    80003364:	e04a                	sd	s2,0(sp)
    80003366:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003368:	fffff097          	auipc	ra,0xfffff
    8000336c:	a6e080e7          	jalr	-1426(ra) # 80001dd6 <myproc>
    80003370:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003372:	07853903          	ld	s2,120(a0)
    80003376:	0a893783          	ld	a5,168(s2)
    8000337a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000337e:	37fd                	addiw	a5,a5,-1
    80003380:	4751                	li	a4,20
    80003382:	00f76f63          	bltu	a4,a5,800033a0 <syscall+0x44>
    80003386:	00369713          	slli	a4,a3,0x3
    8000338a:	00005797          	auipc	a5,0x5
    8000338e:	16678793          	addi	a5,a5,358 # 800084f0 <syscalls>
    80003392:	97ba                	add	a5,a5,a4
    80003394:	639c                	ld	a5,0(a5)
    80003396:	c789                	beqz	a5,800033a0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003398:	9782                	jalr	a5
    8000339a:	06a93823          	sd	a0,112(s2)
    8000339e:	a839                	j	800033bc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800033a0:	17848613          	addi	a2,s1,376
    800033a4:	588c                	lw	a1,48(s1)
    800033a6:	00005517          	auipc	a0,0x5
    800033aa:	11250513          	addi	a0,a0,274 # 800084b8 <states.1767+0x150>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	1da080e7          	jalr	474(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800033b6:	7cbc                	ld	a5,120(s1)
    800033b8:	577d                	li	a4,-1
    800033ba:	fbb8                	sd	a4,112(a5)
  }
}
    800033bc:	60e2                	ld	ra,24(sp)
    800033be:	6442                	ld	s0,16(sp)
    800033c0:	64a2                	ld	s1,8(sp)
    800033c2:	6902                	ld	s2,0(sp)
    800033c4:	6105                	addi	sp,sp,32
    800033c6:	8082                	ret

00000000800033c8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800033c8:	1101                	addi	sp,sp,-32
    800033ca:	ec06                	sd	ra,24(sp)
    800033cc:	e822                	sd	s0,16(sp)
    800033ce:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800033d0:	fec40593          	addi	a1,s0,-20
    800033d4:	4501                	li	a0,0
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	f12080e7          	jalr	-238(ra) # 800032e8 <argint>
    return -1;
    800033de:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033e0:	00054963          	bltz	a0,800033f2 <sys_exit+0x2a>
  exit(n);
    800033e4:	fec42503          	lw	a0,-20(s0)
    800033e8:	fffff097          	auipc	ra,0xfffff
    800033ec:	656080e7          	jalr	1622(ra) # 80002a3e <exit>
  return 0;  // not reached
    800033f0:	4781                	li	a5,0
}
    800033f2:	853e                	mv	a0,a5
    800033f4:	60e2                	ld	ra,24(sp)
    800033f6:	6442                	ld	s0,16(sp)
    800033f8:	6105                	addi	sp,sp,32
    800033fa:	8082                	ret

00000000800033fc <sys_getpid>:

uint64
sys_getpid(void)
{
    800033fc:	1141                	addi	sp,sp,-16
    800033fe:	e406                	sd	ra,8(sp)
    80003400:	e022                	sd	s0,0(sp)
    80003402:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	9d2080e7          	jalr	-1582(ra) # 80001dd6 <myproc>
}
    8000340c:	5908                	lw	a0,48(a0)
    8000340e:	60a2                	ld	ra,8(sp)
    80003410:	6402                	ld	s0,0(sp)
    80003412:	0141                	addi	sp,sp,16
    80003414:	8082                	ret

0000000080003416 <sys_fork>:

uint64
sys_fork(void)
{
    80003416:	1141                	addi	sp,sp,-16
    80003418:	e406                	sd	ra,8(sp)
    8000341a:	e022                	sd	s0,0(sp)
    8000341c:	0800                	addi	s0,sp,16
  return fork();
    8000341e:	fffff097          	auipc	ra,0xfffff
    80003422:	e6a080e7          	jalr	-406(ra) # 80002288 <fork>
}
    80003426:	60a2                	ld	ra,8(sp)
    80003428:	6402                	ld	s0,0(sp)
    8000342a:	0141                	addi	sp,sp,16
    8000342c:	8082                	ret

000000008000342e <sys_wait>:

uint64
sys_wait(void)
{
    8000342e:	1101                	addi	sp,sp,-32
    80003430:	ec06                	sd	ra,24(sp)
    80003432:	e822                	sd	s0,16(sp)
    80003434:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003436:	fe840593          	addi	a1,s0,-24
    8000343a:	4501                	li	a0,0
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	ece080e7          	jalr	-306(ra) # 8000330a <argaddr>
    80003444:	87aa                	mv	a5,a0
    return -1;
    80003446:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003448:	0007c863          	bltz	a5,80003458 <sys_wait+0x2a>
  return wait(p);
    8000344c:	fe843503          	ld	a0,-24(s0)
    80003450:	fffff097          	auipc	ra,0xfffff
    80003454:	330080e7          	jalr	816(ra) # 80002780 <wait>
}
    80003458:	60e2                	ld	ra,24(sp)
    8000345a:	6442                	ld	s0,16(sp)
    8000345c:	6105                	addi	sp,sp,32
    8000345e:	8082                	ret

0000000080003460 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003460:	7179                	addi	sp,sp,-48
    80003462:	f406                	sd	ra,40(sp)
    80003464:	f022                	sd	s0,32(sp)
    80003466:	ec26                	sd	s1,24(sp)
    80003468:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000346a:	fdc40593          	addi	a1,s0,-36
    8000346e:	4501                	li	a0,0
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e78080e7          	jalr	-392(ra) # 800032e8 <argint>
    80003478:	87aa                	mv	a5,a0
    return -1;
    8000347a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000347c:	0207c063          	bltz	a5,8000349c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003480:	fffff097          	auipc	ra,0xfffff
    80003484:	956080e7          	jalr	-1706(ra) # 80001dd6 <myproc>
    80003488:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    8000348a:	fdc42503          	lw	a0,-36(s0)
    8000348e:	fffff097          	auipc	ra,0xfffff
    80003492:	d86080e7          	jalr	-634(ra) # 80002214 <growproc>
    80003496:	00054863          	bltz	a0,800034a6 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000349a:	8526                	mv	a0,s1
}
    8000349c:	70a2                	ld	ra,40(sp)
    8000349e:	7402                	ld	s0,32(sp)
    800034a0:	64e2                	ld	s1,24(sp)
    800034a2:	6145                	addi	sp,sp,48
    800034a4:	8082                	ret
    return -1;
    800034a6:	557d                	li	a0,-1
    800034a8:	bfd5                	j	8000349c <sys_sbrk+0x3c>

00000000800034aa <sys_sleep>:

uint64
sys_sleep(void)
{
    800034aa:	7139                	addi	sp,sp,-64
    800034ac:	fc06                	sd	ra,56(sp)
    800034ae:	f822                	sd	s0,48(sp)
    800034b0:	f426                	sd	s1,40(sp)
    800034b2:	f04a                	sd	s2,32(sp)
    800034b4:	ec4e                	sd	s3,24(sp)
    800034b6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800034b8:	fcc40593          	addi	a1,s0,-52
    800034bc:	4501                	li	a0,0
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	e2a080e7          	jalr	-470(ra) # 800032e8 <argint>
    return -1;
    800034c6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034c8:	06054563          	bltz	a0,80003532 <sys_sleep+0x88>
  acquire(&tickslock);
    800034cc:	00014517          	auipc	a0,0x14
    800034d0:	52c50513          	addi	a0,a0,1324 # 800179f8 <tickslock>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	710080e7          	jalr	1808(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800034dc:	00006917          	auipc	s2,0x6
    800034e0:	b5492903          	lw	s2,-1196(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800034e4:	fcc42783          	lw	a5,-52(s0)
    800034e8:	cf85                	beqz	a5,80003520 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034ea:	00014997          	auipc	s3,0x14
    800034ee:	50e98993          	addi	s3,s3,1294 # 800179f8 <tickslock>
    800034f2:	00006497          	auipc	s1,0x6
    800034f6:	b3e48493          	addi	s1,s1,-1218 # 80009030 <ticks>
    if(myproc()->killed){
    800034fa:	fffff097          	auipc	ra,0xfffff
    800034fe:	8dc080e7          	jalr	-1828(ra) # 80001dd6 <myproc>
    80003502:	551c                	lw	a5,40(a0)
    80003504:	ef9d                	bnez	a5,80003542 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003506:	85ce                	mv	a1,s3
    80003508:	8526                	mv	a0,s1
    8000350a:	fffff097          	auipc	ra,0xfffff
    8000350e:	1d4080e7          	jalr	468(ra) # 800026de <sleep>
  while(ticks - ticks0 < n){
    80003512:	409c                	lw	a5,0(s1)
    80003514:	412787bb          	subw	a5,a5,s2
    80003518:	fcc42703          	lw	a4,-52(s0)
    8000351c:	fce7efe3          	bltu	a5,a4,800034fa <sys_sleep+0x50>
  }
  release(&tickslock);
    80003520:	00014517          	auipc	a0,0x14
    80003524:	4d850513          	addi	a0,a0,1240 # 800179f8 <tickslock>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	770080e7          	jalr	1904(ra) # 80000c98 <release>
  return 0;
    80003530:	4781                	li	a5,0
}
    80003532:	853e                	mv	a0,a5
    80003534:	70e2                	ld	ra,56(sp)
    80003536:	7442                	ld	s0,48(sp)
    80003538:	74a2                	ld	s1,40(sp)
    8000353a:	7902                	ld	s2,32(sp)
    8000353c:	69e2                	ld	s3,24(sp)
    8000353e:	6121                	addi	sp,sp,64
    80003540:	8082                	ret
      release(&tickslock);
    80003542:	00014517          	auipc	a0,0x14
    80003546:	4b650513          	addi	a0,a0,1206 # 800179f8 <tickslock>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	74e080e7          	jalr	1870(ra) # 80000c98 <release>
      return -1;
    80003552:	57fd                	li	a5,-1
    80003554:	bff9                	j	80003532 <sys_sleep+0x88>

0000000080003556 <sys_kill>:

uint64
sys_kill(void)
{
    80003556:	1101                	addi	sp,sp,-32
    80003558:	ec06                	sd	ra,24(sp)
    8000355a:	e822                	sd	s0,16(sp)
    8000355c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000355e:	fec40593          	addi	a1,s0,-20
    80003562:	4501                	li	a0,0
    80003564:	00000097          	auipc	ra,0x0
    80003568:	d84080e7          	jalr	-636(ra) # 800032e8 <argint>
    8000356c:	87aa                	mv	a5,a0
    return -1;
    8000356e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003570:	0007c863          	bltz	a5,80003580 <sys_kill+0x2a>
  return kill(pid);
    80003574:	fec42503          	lw	a0,-20(s0)
    80003578:	fffff097          	auipc	ra,0xfffff
    8000357c:	5ce080e7          	jalr	1486(ra) # 80002b46 <kill>
}
    80003580:	60e2                	ld	ra,24(sp)
    80003582:	6442                	ld	s0,16(sp)
    80003584:	6105                	addi	sp,sp,32
    80003586:	8082                	ret

0000000080003588 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003588:	1101                	addi	sp,sp,-32
    8000358a:	ec06                	sd	ra,24(sp)
    8000358c:	e822                	sd	s0,16(sp)
    8000358e:	e426                	sd	s1,8(sp)
    80003590:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003592:	00014517          	auipc	a0,0x14
    80003596:	46650513          	addi	a0,a0,1126 # 800179f8 <tickslock>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	64a080e7          	jalr	1610(ra) # 80000be4 <acquire>
  xticks = ticks;
    800035a2:	00006497          	auipc	s1,0x6
    800035a6:	a8e4a483          	lw	s1,-1394(s1) # 80009030 <ticks>
  release(&tickslock);
    800035aa:	00014517          	auipc	a0,0x14
    800035ae:	44e50513          	addi	a0,a0,1102 # 800179f8 <tickslock>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6e6080e7          	jalr	1766(ra) # 80000c98 <release>
  return xticks;
}
    800035ba:	02049513          	slli	a0,s1,0x20
    800035be:	9101                	srli	a0,a0,0x20
    800035c0:	60e2                	ld	ra,24(sp)
    800035c2:	6442                	ld	s0,16(sp)
    800035c4:	64a2                	ld	s1,8(sp)
    800035c6:	6105                	addi	sp,sp,32
    800035c8:	8082                	ret

00000000800035ca <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035ca:	7179                	addi	sp,sp,-48
    800035cc:	f406                	sd	ra,40(sp)
    800035ce:	f022                	sd	s0,32(sp)
    800035d0:	ec26                	sd	s1,24(sp)
    800035d2:	e84a                	sd	s2,16(sp)
    800035d4:	e44e                	sd	s3,8(sp)
    800035d6:	e052                	sd	s4,0(sp)
    800035d8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035da:	00005597          	auipc	a1,0x5
    800035de:	fc658593          	addi	a1,a1,-58 # 800085a0 <syscalls+0xb0>
    800035e2:	00014517          	auipc	a0,0x14
    800035e6:	42e50513          	addi	a0,a0,1070 # 80017a10 <bcache>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	56a080e7          	jalr	1386(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035f2:	0001c797          	auipc	a5,0x1c
    800035f6:	41e78793          	addi	a5,a5,1054 # 8001fa10 <bcache+0x8000>
    800035fa:	0001c717          	auipc	a4,0x1c
    800035fe:	67e70713          	addi	a4,a4,1662 # 8001fc78 <bcache+0x8268>
    80003602:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003606:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000360a:	00014497          	auipc	s1,0x14
    8000360e:	41e48493          	addi	s1,s1,1054 # 80017a28 <bcache+0x18>
    b->next = bcache.head.next;
    80003612:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003614:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003616:	00005a17          	auipc	s4,0x5
    8000361a:	f92a0a13          	addi	s4,s4,-110 # 800085a8 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000361e:	2b893783          	ld	a5,696(s2)
    80003622:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003624:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003628:	85d2                	mv	a1,s4
    8000362a:	01048513          	addi	a0,s1,16
    8000362e:	00001097          	auipc	ra,0x1
    80003632:	4bc080e7          	jalr	1212(ra) # 80004aea <initsleeplock>
    bcache.head.next->prev = b;
    80003636:	2b893783          	ld	a5,696(s2)
    8000363a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000363c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003640:	45848493          	addi	s1,s1,1112
    80003644:	fd349de3          	bne	s1,s3,8000361e <binit+0x54>
  }
}
    80003648:	70a2                	ld	ra,40(sp)
    8000364a:	7402                	ld	s0,32(sp)
    8000364c:	64e2                	ld	s1,24(sp)
    8000364e:	6942                	ld	s2,16(sp)
    80003650:	69a2                	ld	s3,8(sp)
    80003652:	6a02                	ld	s4,0(sp)
    80003654:	6145                	addi	sp,sp,48
    80003656:	8082                	ret

0000000080003658 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	1800                	addi	s0,sp,48
    80003666:	89aa                	mv	s3,a0
    80003668:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000366a:	00014517          	auipc	a0,0x14
    8000366e:	3a650513          	addi	a0,a0,934 # 80017a10 <bcache>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	572080e7          	jalr	1394(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000367a:	0001c497          	auipc	s1,0x1c
    8000367e:	64e4b483          	ld	s1,1614(s1) # 8001fcc8 <bcache+0x82b8>
    80003682:	0001c797          	auipc	a5,0x1c
    80003686:	5f678793          	addi	a5,a5,1526 # 8001fc78 <bcache+0x8268>
    8000368a:	02f48f63          	beq	s1,a5,800036c8 <bread+0x70>
    8000368e:	873e                	mv	a4,a5
    80003690:	a021                	j	80003698 <bread+0x40>
    80003692:	68a4                	ld	s1,80(s1)
    80003694:	02e48a63          	beq	s1,a4,800036c8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003698:	449c                	lw	a5,8(s1)
    8000369a:	ff379ce3          	bne	a5,s3,80003692 <bread+0x3a>
    8000369e:	44dc                	lw	a5,12(s1)
    800036a0:	ff2799e3          	bne	a5,s2,80003692 <bread+0x3a>
      b->refcnt++;
    800036a4:	40bc                	lw	a5,64(s1)
    800036a6:	2785                	addiw	a5,a5,1
    800036a8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036aa:	00014517          	auipc	a0,0x14
    800036ae:	36650513          	addi	a0,a0,870 # 80017a10 <bcache>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036ba:	01048513          	addi	a0,s1,16
    800036be:	00001097          	auipc	ra,0x1
    800036c2:	466080e7          	jalr	1126(ra) # 80004b24 <acquiresleep>
      return b;
    800036c6:	a8b9                	j	80003724 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036c8:	0001c497          	auipc	s1,0x1c
    800036cc:	5f84b483          	ld	s1,1528(s1) # 8001fcc0 <bcache+0x82b0>
    800036d0:	0001c797          	auipc	a5,0x1c
    800036d4:	5a878793          	addi	a5,a5,1448 # 8001fc78 <bcache+0x8268>
    800036d8:	00f48863          	beq	s1,a5,800036e8 <bread+0x90>
    800036dc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036de:	40bc                	lw	a5,64(s1)
    800036e0:	cf81                	beqz	a5,800036f8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036e2:	64a4                	ld	s1,72(s1)
    800036e4:	fee49de3          	bne	s1,a4,800036de <bread+0x86>
  panic("bget: no buffers");
    800036e8:	00005517          	auipc	a0,0x5
    800036ec:	ec850513          	addi	a0,a0,-312 # 800085b0 <syscalls+0xc0>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	e4e080e7          	jalr	-434(ra) # 8000053e <panic>
      b->dev = dev;
    800036f8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036fc:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003700:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003704:	4785                	li	a5,1
    80003706:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003708:	00014517          	auipc	a0,0x14
    8000370c:	30850513          	addi	a0,a0,776 # 80017a10 <bcache>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	588080e7          	jalr	1416(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003718:	01048513          	addi	a0,s1,16
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	408080e7          	jalr	1032(ra) # 80004b24 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003724:	409c                	lw	a5,0(s1)
    80003726:	cb89                	beqz	a5,80003738 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003728:	8526                	mv	a0,s1
    8000372a:	70a2                	ld	ra,40(sp)
    8000372c:	7402                	ld	s0,32(sp)
    8000372e:	64e2                	ld	s1,24(sp)
    80003730:	6942                	ld	s2,16(sp)
    80003732:	69a2                	ld	s3,8(sp)
    80003734:	6145                	addi	sp,sp,48
    80003736:	8082                	ret
    virtio_disk_rw(b, 0);
    80003738:	4581                	li	a1,0
    8000373a:	8526                	mv	a0,s1
    8000373c:	00003097          	auipc	ra,0x3
    80003740:	f0a080e7          	jalr	-246(ra) # 80006646 <virtio_disk_rw>
    b->valid = 1;
    80003744:	4785                	li	a5,1
    80003746:	c09c                	sw	a5,0(s1)
  return b;
    80003748:	b7c5                	j	80003728 <bread+0xd0>

000000008000374a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	1000                	addi	s0,sp,32
    80003754:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003756:	0541                	addi	a0,a0,16
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	466080e7          	jalr	1126(ra) # 80004bbe <holdingsleep>
    80003760:	cd01                	beqz	a0,80003778 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003762:	4585                	li	a1,1
    80003764:	8526                	mv	a0,s1
    80003766:	00003097          	auipc	ra,0x3
    8000376a:	ee0080e7          	jalr	-288(ra) # 80006646 <virtio_disk_rw>
}
    8000376e:	60e2                	ld	ra,24(sp)
    80003770:	6442                	ld	s0,16(sp)
    80003772:	64a2                	ld	s1,8(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret
    panic("bwrite");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	e5050513          	addi	a0,a0,-432 # 800085c8 <syscalls+0xd8>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dbe080e7          	jalr	-578(ra) # 8000053e <panic>

0000000080003788 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	e04a                	sd	s2,0(sp)
    80003792:	1000                	addi	s0,sp,32
    80003794:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003796:	01050913          	addi	s2,a0,16
    8000379a:	854a                	mv	a0,s2
    8000379c:	00001097          	auipc	ra,0x1
    800037a0:	422080e7          	jalr	1058(ra) # 80004bbe <holdingsleep>
    800037a4:	c92d                	beqz	a0,80003816 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00001097          	auipc	ra,0x1
    800037ac:	3d2080e7          	jalr	978(ra) # 80004b7a <releasesleep>

  acquire(&bcache.lock);
    800037b0:	00014517          	auipc	a0,0x14
    800037b4:	26050513          	addi	a0,a0,608 # 80017a10 <bcache>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	42c080e7          	jalr	1068(ra) # 80000be4 <acquire>
  b->refcnt--;
    800037c0:	40bc                	lw	a5,64(s1)
    800037c2:	37fd                	addiw	a5,a5,-1
    800037c4:	0007871b          	sext.w	a4,a5
    800037c8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037ca:	eb05                	bnez	a4,800037fa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037cc:	68bc                	ld	a5,80(s1)
    800037ce:	64b8                	ld	a4,72(s1)
    800037d0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037d2:	64bc                	ld	a5,72(s1)
    800037d4:	68b8                	ld	a4,80(s1)
    800037d6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037d8:	0001c797          	auipc	a5,0x1c
    800037dc:	23878793          	addi	a5,a5,568 # 8001fa10 <bcache+0x8000>
    800037e0:	2b87b703          	ld	a4,696(a5)
    800037e4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037e6:	0001c717          	auipc	a4,0x1c
    800037ea:	49270713          	addi	a4,a4,1170 # 8001fc78 <bcache+0x8268>
    800037ee:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037f0:	2b87b703          	ld	a4,696(a5)
    800037f4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037f6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037fa:	00014517          	auipc	a0,0x14
    800037fe:	21650513          	addi	a0,a0,534 # 80017a10 <bcache>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	496080e7          	jalr	1174(ra) # 80000c98 <release>
}
    8000380a:	60e2                	ld	ra,24(sp)
    8000380c:	6442                	ld	s0,16(sp)
    8000380e:	64a2                	ld	s1,8(sp)
    80003810:	6902                	ld	s2,0(sp)
    80003812:	6105                	addi	sp,sp,32
    80003814:	8082                	ret
    panic("brelse");
    80003816:	00005517          	auipc	a0,0x5
    8000381a:	dba50513          	addi	a0,a0,-582 # 800085d0 <syscalls+0xe0>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>

0000000080003826 <bpin>:

void
bpin(struct buf *b) {
    80003826:	1101                	addi	sp,sp,-32
    80003828:	ec06                	sd	ra,24(sp)
    8000382a:	e822                	sd	s0,16(sp)
    8000382c:	e426                	sd	s1,8(sp)
    8000382e:	1000                	addi	s0,sp,32
    80003830:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003832:	00014517          	auipc	a0,0x14
    80003836:	1de50513          	addi	a0,a0,478 # 80017a10 <bcache>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	3aa080e7          	jalr	938(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003842:	40bc                	lw	a5,64(s1)
    80003844:	2785                	addiw	a5,a5,1
    80003846:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003848:	00014517          	auipc	a0,0x14
    8000384c:	1c850513          	addi	a0,a0,456 # 80017a10 <bcache>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	448080e7          	jalr	1096(ra) # 80000c98 <release>
}
    80003858:	60e2                	ld	ra,24(sp)
    8000385a:	6442                	ld	s0,16(sp)
    8000385c:	64a2                	ld	s1,8(sp)
    8000385e:	6105                	addi	sp,sp,32
    80003860:	8082                	ret

0000000080003862 <bunpin>:

void
bunpin(struct buf *b) {
    80003862:	1101                	addi	sp,sp,-32
    80003864:	ec06                	sd	ra,24(sp)
    80003866:	e822                	sd	s0,16(sp)
    80003868:	e426                	sd	s1,8(sp)
    8000386a:	1000                	addi	s0,sp,32
    8000386c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000386e:	00014517          	auipc	a0,0x14
    80003872:	1a250513          	addi	a0,a0,418 # 80017a10 <bcache>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	36e080e7          	jalr	878(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000387e:	40bc                	lw	a5,64(s1)
    80003880:	37fd                	addiw	a5,a5,-1
    80003882:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003884:	00014517          	auipc	a0,0x14
    80003888:	18c50513          	addi	a0,a0,396 # 80017a10 <bcache>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	40c080e7          	jalr	1036(ra) # 80000c98 <release>
}
    80003894:	60e2                	ld	ra,24(sp)
    80003896:	6442                	ld	s0,16(sp)
    80003898:	64a2                	ld	s1,8(sp)
    8000389a:	6105                	addi	sp,sp,32
    8000389c:	8082                	ret

000000008000389e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000389e:	1101                	addi	sp,sp,-32
    800038a0:	ec06                	sd	ra,24(sp)
    800038a2:	e822                	sd	s0,16(sp)
    800038a4:	e426                	sd	s1,8(sp)
    800038a6:	e04a                	sd	s2,0(sp)
    800038a8:	1000                	addi	s0,sp,32
    800038aa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800038ac:	00d5d59b          	srliw	a1,a1,0xd
    800038b0:	0001d797          	auipc	a5,0x1d
    800038b4:	83c7a783          	lw	a5,-1988(a5) # 800200ec <sb+0x1c>
    800038b8:	9dbd                	addw	a1,a1,a5
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	d9e080e7          	jalr	-610(ra) # 80003658 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038c2:	0074f713          	andi	a4,s1,7
    800038c6:	4785                	li	a5,1
    800038c8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038cc:	14ce                	slli	s1,s1,0x33
    800038ce:	90d9                	srli	s1,s1,0x36
    800038d0:	00950733          	add	a4,a0,s1
    800038d4:	05874703          	lbu	a4,88(a4)
    800038d8:	00e7f6b3          	and	a3,a5,a4
    800038dc:	c69d                	beqz	a3,8000390a <bfree+0x6c>
    800038de:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038e0:	94aa                	add	s1,s1,a0
    800038e2:	fff7c793          	not	a5,a5
    800038e6:	8ff9                	and	a5,a5,a4
    800038e8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038ec:	00001097          	auipc	ra,0x1
    800038f0:	118080e7          	jalr	280(ra) # 80004a04 <log_write>
  brelse(bp);
    800038f4:	854a                	mv	a0,s2
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	e92080e7          	jalr	-366(ra) # 80003788 <brelse>
}
    800038fe:	60e2                	ld	ra,24(sp)
    80003900:	6442                	ld	s0,16(sp)
    80003902:	64a2                	ld	s1,8(sp)
    80003904:	6902                	ld	s2,0(sp)
    80003906:	6105                	addi	sp,sp,32
    80003908:	8082                	ret
    panic("freeing free block");
    8000390a:	00005517          	auipc	a0,0x5
    8000390e:	cce50513          	addi	a0,a0,-818 # 800085d8 <syscalls+0xe8>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	c2c080e7          	jalr	-980(ra) # 8000053e <panic>

000000008000391a <balloc>:
{
    8000391a:	711d                	addi	sp,sp,-96
    8000391c:	ec86                	sd	ra,88(sp)
    8000391e:	e8a2                	sd	s0,80(sp)
    80003920:	e4a6                	sd	s1,72(sp)
    80003922:	e0ca                	sd	s2,64(sp)
    80003924:	fc4e                	sd	s3,56(sp)
    80003926:	f852                	sd	s4,48(sp)
    80003928:	f456                	sd	s5,40(sp)
    8000392a:	f05a                	sd	s6,32(sp)
    8000392c:	ec5e                	sd	s7,24(sp)
    8000392e:	e862                	sd	s8,16(sp)
    80003930:	e466                	sd	s9,8(sp)
    80003932:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003934:	0001c797          	auipc	a5,0x1c
    80003938:	7a07a783          	lw	a5,1952(a5) # 800200d4 <sb+0x4>
    8000393c:	cbd1                	beqz	a5,800039d0 <balloc+0xb6>
    8000393e:	8baa                	mv	s7,a0
    80003940:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003942:	0001cb17          	auipc	s6,0x1c
    80003946:	78eb0b13          	addi	s6,s6,1934 # 800200d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000394a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000394c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000394e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003950:	6c89                	lui	s9,0x2
    80003952:	a831                	j	8000396e <balloc+0x54>
    brelse(bp);
    80003954:	854a                	mv	a0,s2
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	e32080e7          	jalr	-462(ra) # 80003788 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000395e:	015c87bb          	addw	a5,s9,s5
    80003962:	00078a9b          	sext.w	s5,a5
    80003966:	004b2703          	lw	a4,4(s6)
    8000396a:	06eaf363          	bgeu	s5,a4,800039d0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000396e:	41fad79b          	sraiw	a5,s5,0x1f
    80003972:	0137d79b          	srliw	a5,a5,0x13
    80003976:	015787bb          	addw	a5,a5,s5
    8000397a:	40d7d79b          	sraiw	a5,a5,0xd
    8000397e:	01cb2583          	lw	a1,28(s6)
    80003982:	9dbd                	addw	a1,a1,a5
    80003984:	855e                	mv	a0,s7
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	cd2080e7          	jalr	-814(ra) # 80003658 <bread>
    8000398e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003990:	004b2503          	lw	a0,4(s6)
    80003994:	000a849b          	sext.w	s1,s5
    80003998:	8662                	mv	a2,s8
    8000399a:	faa4fde3          	bgeu	s1,a0,80003954 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000399e:	41f6579b          	sraiw	a5,a2,0x1f
    800039a2:	01d7d69b          	srliw	a3,a5,0x1d
    800039a6:	00c6873b          	addw	a4,a3,a2
    800039aa:	00777793          	andi	a5,a4,7
    800039ae:	9f95                	subw	a5,a5,a3
    800039b0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039b4:	4037571b          	sraiw	a4,a4,0x3
    800039b8:	00e906b3          	add	a3,s2,a4
    800039bc:	0586c683          	lbu	a3,88(a3)
    800039c0:	00d7f5b3          	and	a1,a5,a3
    800039c4:	cd91                	beqz	a1,800039e0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c6:	2605                	addiw	a2,a2,1
    800039c8:	2485                	addiw	s1,s1,1
    800039ca:	fd4618e3          	bne	a2,s4,8000399a <balloc+0x80>
    800039ce:	b759                	j	80003954 <balloc+0x3a>
  panic("balloc: out of blocks");
    800039d0:	00005517          	auipc	a0,0x5
    800039d4:	c2050513          	addi	a0,a0,-992 # 800085f0 <syscalls+0x100>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	b66080e7          	jalr	-1178(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039e0:	974a                	add	a4,a4,s2
    800039e2:	8fd5                	or	a5,a5,a3
    800039e4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039e8:	854a                	mv	a0,s2
    800039ea:	00001097          	auipc	ra,0x1
    800039ee:	01a080e7          	jalr	26(ra) # 80004a04 <log_write>
        brelse(bp);
    800039f2:	854a                	mv	a0,s2
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	d94080e7          	jalr	-620(ra) # 80003788 <brelse>
  bp = bread(dev, bno);
    800039fc:	85a6                	mv	a1,s1
    800039fe:	855e                	mv	a0,s7
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	c58080e7          	jalr	-936(ra) # 80003658 <bread>
    80003a08:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a0a:	40000613          	li	a2,1024
    80003a0e:	4581                	li	a1,0
    80003a10:	05850513          	addi	a0,a0,88
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	2cc080e7          	jalr	716(ra) # 80000ce0 <memset>
  log_write(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00001097          	auipc	ra,0x1
    80003a22:	fe6080e7          	jalr	-26(ra) # 80004a04 <log_write>
  brelse(bp);
    80003a26:	854a                	mv	a0,s2
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	d60080e7          	jalr	-672(ra) # 80003788 <brelse>
}
    80003a30:	8526                	mv	a0,s1
    80003a32:	60e6                	ld	ra,88(sp)
    80003a34:	6446                	ld	s0,80(sp)
    80003a36:	64a6                	ld	s1,72(sp)
    80003a38:	6906                	ld	s2,64(sp)
    80003a3a:	79e2                	ld	s3,56(sp)
    80003a3c:	7a42                	ld	s4,48(sp)
    80003a3e:	7aa2                	ld	s5,40(sp)
    80003a40:	7b02                	ld	s6,32(sp)
    80003a42:	6be2                	ld	s7,24(sp)
    80003a44:	6c42                	ld	s8,16(sp)
    80003a46:	6ca2                	ld	s9,8(sp)
    80003a48:	6125                	addi	sp,sp,96
    80003a4a:	8082                	ret

0000000080003a4c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a4c:	7179                	addi	sp,sp,-48
    80003a4e:	f406                	sd	ra,40(sp)
    80003a50:	f022                	sd	s0,32(sp)
    80003a52:	ec26                	sd	s1,24(sp)
    80003a54:	e84a                	sd	s2,16(sp)
    80003a56:	e44e                	sd	s3,8(sp)
    80003a58:	e052                	sd	s4,0(sp)
    80003a5a:	1800                	addi	s0,sp,48
    80003a5c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a5e:	47ad                	li	a5,11
    80003a60:	04b7fe63          	bgeu	a5,a1,80003abc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a64:	ff45849b          	addiw	s1,a1,-12
    80003a68:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a6c:	0ff00793          	li	a5,255
    80003a70:	0ae7e363          	bltu	a5,a4,80003b16 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a74:	08052583          	lw	a1,128(a0)
    80003a78:	c5ad                	beqz	a1,80003ae2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a7a:	00092503          	lw	a0,0(s2)
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	bda080e7          	jalr	-1062(ra) # 80003658 <bread>
    80003a86:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a88:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a8c:	02049593          	slli	a1,s1,0x20
    80003a90:	9181                	srli	a1,a1,0x20
    80003a92:	058a                	slli	a1,a1,0x2
    80003a94:	00b784b3          	add	s1,a5,a1
    80003a98:	0004a983          	lw	s3,0(s1)
    80003a9c:	04098d63          	beqz	s3,80003af6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003aa0:	8552                	mv	a0,s4
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	ce6080e7          	jalr	-794(ra) # 80003788 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003aaa:	854e                	mv	a0,s3
    80003aac:	70a2                	ld	ra,40(sp)
    80003aae:	7402                	ld	s0,32(sp)
    80003ab0:	64e2                	ld	s1,24(sp)
    80003ab2:	6942                	ld	s2,16(sp)
    80003ab4:	69a2                	ld	s3,8(sp)
    80003ab6:	6a02                	ld	s4,0(sp)
    80003ab8:	6145                	addi	sp,sp,48
    80003aba:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003abc:	02059493          	slli	s1,a1,0x20
    80003ac0:	9081                	srli	s1,s1,0x20
    80003ac2:	048a                	slli	s1,s1,0x2
    80003ac4:	94aa                	add	s1,s1,a0
    80003ac6:	0504a983          	lw	s3,80(s1)
    80003aca:	fe0990e3          	bnez	s3,80003aaa <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003ace:	4108                	lw	a0,0(a0)
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	e4a080e7          	jalr	-438(ra) # 8000391a <balloc>
    80003ad8:	0005099b          	sext.w	s3,a0
    80003adc:	0534a823          	sw	s3,80(s1)
    80003ae0:	b7e9                	j	80003aaa <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003ae2:	4108                	lw	a0,0(a0)
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	e36080e7          	jalr	-458(ra) # 8000391a <balloc>
    80003aec:	0005059b          	sext.w	a1,a0
    80003af0:	08b92023          	sw	a1,128(s2)
    80003af4:	b759                	j	80003a7a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003af6:	00092503          	lw	a0,0(s2)
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	e20080e7          	jalr	-480(ra) # 8000391a <balloc>
    80003b02:	0005099b          	sext.w	s3,a0
    80003b06:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b0a:	8552                	mv	a0,s4
    80003b0c:	00001097          	auipc	ra,0x1
    80003b10:	ef8080e7          	jalr	-264(ra) # 80004a04 <log_write>
    80003b14:	b771                	j	80003aa0 <bmap+0x54>
  panic("bmap: out of range");
    80003b16:	00005517          	auipc	a0,0x5
    80003b1a:	af250513          	addi	a0,a0,-1294 # 80008608 <syscalls+0x118>
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	a20080e7          	jalr	-1504(ra) # 8000053e <panic>

0000000080003b26 <iget>:
{
    80003b26:	7179                	addi	sp,sp,-48
    80003b28:	f406                	sd	ra,40(sp)
    80003b2a:	f022                	sd	s0,32(sp)
    80003b2c:	ec26                	sd	s1,24(sp)
    80003b2e:	e84a                	sd	s2,16(sp)
    80003b30:	e44e                	sd	s3,8(sp)
    80003b32:	e052                	sd	s4,0(sp)
    80003b34:	1800                	addi	s0,sp,48
    80003b36:	89aa                	mv	s3,a0
    80003b38:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b3a:	0001c517          	auipc	a0,0x1c
    80003b3e:	5b650513          	addi	a0,a0,1462 # 800200f0 <itable>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	0a2080e7          	jalr	162(ra) # 80000be4 <acquire>
  empty = 0;
    80003b4a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b4c:	0001c497          	auipc	s1,0x1c
    80003b50:	5bc48493          	addi	s1,s1,1468 # 80020108 <itable+0x18>
    80003b54:	0001e697          	auipc	a3,0x1e
    80003b58:	04468693          	addi	a3,a3,68 # 80021b98 <log>
    80003b5c:	a039                	j	80003b6a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b5e:	02090b63          	beqz	s2,80003b94 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b62:	08848493          	addi	s1,s1,136
    80003b66:	02d48a63          	beq	s1,a3,80003b9a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b6a:	449c                	lw	a5,8(s1)
    80003b6c:	fef059e3          	blez	a5,80003b5e <iget+0x38>
    80003b70:	4098                	lw	a4,0(s1)
    80003b72:	ff3716e3          	bne	a4,s3,80003b5e <iget+0x38>
    80003b76:	40d8                	lw	a4,4(s1)
    80003b78:	ff4713e3          	bne	a4,s4,80003b5e <iget+0x38>
      ip->ref++;
    80003b7c:	2785                	addiw	a5,a5,1
    80003b7e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b80:	0001c517          	auipc	a0,0x1c
    80003b84:	57050513          	addi	a0,a0,1392 # 800200f0 <itable>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	110080e7          	jalr	272(ra) # 80000c98 <release>
      return ip;
    80003b90:	8926                	mv	s2,s1
    80003b92:	a03d                	j	80003bc0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b94:	f7f9                	bnez	a5,80003b62 <iget+0x3c>
    80003b96:	8926                	mv	s2,s1
    80003b98:	b7e9                	j	80003b62 <iget+0x3c>
  if(empty == 0)
    80003b9a:	02090c63          	beqz	s2,80003bd2 <iget+0xac>
  ip->dev = dev;
    80003b9e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ba2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ba6:	4785                	li	a5,1
    80003ba8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003bac:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003bb0:	0001c517          	auipc	a0,0x1c
    80003bb4:	54050513          	addi	a0,a0,1344 # 800200f0 <itable>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	0e0080e7          	jalr	224(ra) # 80000c98 <release>
}
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	70a2                	ld	ra,40(sp)
    80003bc4:	7402                	ld	s0,32(sp)
    80003bc6:	64e2                	ld	s1,24(sp)
    80003bc8:	6942                	ld	s2,16(sp)
    80003bca:	69a2                	ld	s3,8(sp)
    80003bcc:	6a02                	ld	s4,0(sp)
    80003bce:	6145                	addi	sp,sp,48
    80003bd0:	8082                	ret
    panic("iget: no inodes");
    80003bd2:	00005517          	auipc	a0,0x5
    80003bd6:	a4e50513          	addi	a0,a0,-1458 # 80008620 <syscalls+0x130>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	964080e7          	jalr	-1692(ra) # 8000053e <panic>

0000000080003be2 <fsinit>:
fsinit(int dev) {
    80003be2:	7179                	addi	sp,sp,-48
    80003be4:	f406                	sd	ra,40(sp)
    80003be6:	f022                	sd	s0,32(sp)
    80003be8:	ec26                	sd	s1,24(sp)
    80003bea:	e84a                	sd	s2,16(sp)
    80003bec:	e44e                	sd	s3,8(sp)
    80003bee:	1800                	addi	s0,sp,48
    80003bf0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bf2:	4585                	li	a1,1
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	a64080e7          	jalr	-1436(ra) # 80003658 <bread>
    80003bfc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bfe:	0001c997          	auipc	s3,0x1c
    80003c02:	4d298993          	addi	s3,s3,1234 # 800200d0 <sb>
    80003c06:	02000613          	li	a2,32
    80003c0a:	05850593          	addi	a1,a0,88
    80003c0e:	854e                	mv	a0,s3
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	130080e7          	jalr	304(ra) # 80000d40 <memmove>
  brelse(bp);
    80003c18:	8526                	mv	a0,s1
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	b6e080e7          	jalr	-1170(ra) # 80003788 <brelse>
  if(sb.magic != FSMAGIC)
    80003c22:	0009a703          	lw	a4,0(s3)
    80003c26:	102037b7          	lui	a5,0x10203
    80003c2a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c2e:	02f71263          	bne	a4,a5,80003c52 <fsinit+0x70>
  initlog(dev, &sb);
    80003c32:	0001c597          	auipc	a1,0x1c
    80003c36:	49e58593          	addi	a1,a1,1182 # 800200d0 <sb>
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00001097          	auipc	ra,0x1
    80003c40:	b4c080e7          	jalr	-1204(ra) # 80004788 <initlog>
}
    80003c44:	70a2                	ld	ra,40(sp)
    80003c46:	7402                	ld	s0,32(sp)
    80003c48:	64e2                	ld	s1,24(sp)
    80003c4a:	6942                	ld	s2,16(sp)
    80003c4c:	69a2                	ld	s3,8(sp)
    80003c4e:	6145                	addi	sp,sp,48
    80003c50:	8082                	ret
    panic("invalid file system");
    80003c52:	00005517          	auipc	a0,0x5
    80003c56:	9de50513          	addi	a0,a0,-1570 # 80008630 <syscalls+0x140>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	8e4080e7          	jalr	-1820(ra) # 8000053e <panic>

0000000080003c62 <iinit>:
{
    80003c62:	7179                	addi	sp,sp,-48
    80003c64:	f406                	sd	ra,40(sp)
    80003c66:	f022                	sd	s0,32(sp)
    80003c68:	ec26                	sd	s1,24(sp)
    80003c6a:	e84a                	sd	s2,16(sp)
    80003c6c:	e44e                	sd	s3,8(sp)
    80003c6e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c70:	00005597          	auipc	a1,0x5
    80003c74:	9d858593          	addi	a1,a1,-1576 # 80008648 <syscalls+0x158>
    80003c78:	0001c517          	auipc	a0,0x1c
    80003c7c:	47850513          	addi	a0,a0,1144 # 800200f0 <itable>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	ed4080e7          	jalr	-300(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c88:	0001c497          	auipc	s1,0x1c
    80003c8c:	49048493          	addi	s1,s1,1168 # 80020118 <itable+0x28>
    80003c90:	0001e997          	auipc	s3,0x1e
    80003c94:	f1898993          	addi	s3,s3,-232 # 80021ba8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c98:	00005917          	auipc	s2,0x5
    80003c9c:	9b890913          	addi	s2,s2,-1608 # 80008650 <syscalls+0x160>
    80003ca0:	85ca                	mv	a1,s2
    80003ca2:	8526                	mv	a0,s1
    80003ca4:	00001097          	auipc	ra,0x1
    80003ca8:	e46080e7          	jalr	-442(ra) # 80004aea <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003cac:	08848493          	addi	s1,s1,136
    80003cb0:	ff3498e3          	bne	s1,s3,80003ca0 <iinit+0x3e>
}
    80003cb4:	70a2                	ld	ra,40(sp)
    80003cb6:	7402                	ld	s0,32(sp)
    80003cb8:	64e2                	ld	s1,24(sp)
    80003cba:	6942                	ld	s2,16(sp)
    80003cbc:	69a2                	ld	s3,8(sp)
    80003cbe:	6145                	addi	sp,sp,48
    80003cc0:	8082                	ret

0000000080003cc2 <ialloc>:
{
    80003cc2:	715d                	addi	sp,sp,-80
    80003cc4:	e486                	sd	ra,72(sp)
    80003cc6:	e0a2                	sd	s0,64(sp)
    80003cc8:	fc26                	sd	s1,56(sp)
    80003cca:	f84a                	sd	s2,48(sp)
    80003ccc:	f44e                	sd	s3,40(sp)
    80003cce:	f052                	sd	s4,32(sp)
    80003cd0:	ec56                	sd	s5,24(sp)
    80003cd2:	e85a                	sd	s6,16(sp)
    80003cd4:	e45e                	sd	s7,8(sp)
    80003cd6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cd8:	0001c717          	auipc	a4,0x1c
    80003cdc:	40472703          	lw	a4,1028(a4) # 800200dc <sb+0xc>
    80003ce0:	4785                	li	a5,1
    80003ce2:	04e7fa63          	bgeu	a5,a4,80003d36 <ialloc+0x74>
    80003ce6:	8aaa                	mv	s5,a0
    80003ce8:	8bae                	mv	s7,a1
    80003cea:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cec:	0001ca17          	auipc	s4,0x1c
    80003cf0:	3e4a0a13          	addi	s4,s4,996 # 800200d0 <sb>
    80003cf4:	00048b1b          	sext.w	s6,s1
    80003cf8:	0044d593          	srli	a1,s1,0x4
    80003cfc:	018a2783          	lw	a5,24(s4)
    80003d00:	9dbd                	addw	a1,a1,a5
    80003d02:	8556                	mv	a0,s5
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	954080e7          	jalr	-1708(ra) # 80003658 <bread>
    80003d0c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d0e:	05850993          	addi	s3,a0,88
    80003d12:	00f4f793          	andi	a5,s1,15
    80003d16:	079a                	slli	a5,a5,0x6
    80003d18:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d1a:	00099783          	lh	a5,0(s3)
    80003d1e:	c785                	beqz	a5,80003d46 <ialloc+0x84>
    brelse(bp);
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	a68080e7          	jalr	-1432(ra) # 80003788 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d28:	0485                	addi	s1,s1,1
    80003d2a:	00ca2703          	lw	a4,12(s4)
    80003d2e:	0004879b          	sext.w	a5,s1
    80003d32:	fce7e1e3          	bltu	a5,a4,80003cf4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d36:	00005517          	auipc	a0,0x5
    80003d3a:	92250513          	addi	a0,a0,-1758 # 80008658 <syscalls+0x168>
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	800080e7          	jalr	-2048(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003d46:	04000613          	li	a2,64
    80003d4a:	4581                	li	a1,0
    80003d4c:	854e                	mv	a0,s3
    80003d4e:	ffffd097          	auipc	ra,0xffffd
    80003d52:	f92080e7          	jalr	-110(ra) # 80000ce0 <memset>
      dip->type = type;
    80003d56:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	00001097          	auipc	ra,0x1
    80003d60:	ca8080e7          	jalr	-856(ra) # 80004a04 <log_write>
      brelse(bp);
    80003d64:	854a                	mv	a0,s2
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	a22080e7          	jalr	-1502(ra) # 80003788 <brelse>
      return iget(dev, inum);
    80003d6e:	85da                	mv	a1,s6
    80003d70:	8556                	mv	a0,s5
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	db4080e7          	jalr	-588(ra) # 80003b26 <iget>
}
    80003d7a:	60a6                	ld	ra,72(sp)
    80003d7c:	6406                	ld	s0,64(sp)
    80003d7e:	74e2                	ld	s1,56(sp)
    80003d80:	7942                	ld	s2,48(sp)
    80003d82:	79a2                	ld	s3,40(sp)
    80003d84:	7a02                	ld	s4,32(sp)
    80003d86:	6ae2                	ld	s5,24(sp)
    80003d88:	6b42                	ld	s6,16(sp)
    80003d8a:	6ba2                	ld	s7,8(sp)
    80003d8c:	6161                	addi	sp,sp,80
    80003d8e:	8082                	ret

0000000080003d90 <iupdate>:
{
    80003d90:	1101                	addi	sp,sp,-32
    80003d92:	ec06                	sd	ra,24(sp)
    80003d94:	e822                	sd	s0,16(sp)
    80003d96:	e426                	sd	s1,8(sp)
    80003d98:	e04a                	sd	s2,0(sp)
    80003d9a:	1000                	addi	s0,sp,32
    80003d9c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d9e:	415c                	lw	a5,4(a0)
    80003da0:	0047d79b          	srliw	a5,a5,0x4
    80003da4:	0001c597          	auipc	a1,0x1c
    80003da8:	3445a583          	lw	a1,836(a1) # 800200e8 <sb+0x18>
    80003dac:	9dbd                	addw	a1,a1,a5
    80003dae:	4108                	lw	a0,0(a0)
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	8a8080e7          	jalr	-1880(ra) # 80003658 <bread>
    80003db8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dba:	05850793          	addi	a5,a0,88
    80003dbe:	40c8                	lw	a0,4(s1)
    80003dc0:	893d                	andi	a0,a0,15
    80003dc2:	051a                	slli	a0,a0,0x6
    80003dc4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003dc6:	04449703          	lh	a4,68(s1)
    80003dca:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003dce:	04649703          	lh	a4,70(s1)
    80003dd2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003dd6:	04849703          	lh	a4,72(s1)
    80003dda:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003dde:	04a49703          	lh	a4,74(s1)
    80003de2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003de6:	44f8                	lw	a4,76(s1)
    80003de8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dea:	03400613          	li	a2,52
    80003dee:	05048593          	addi	a1,s1,80
    80003df2:	0531                	addi	a0,a0,12
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	f4c080e7          	jalr	-180(ra) # 80000d40 <memmove>
  log_write(bp);
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	c06080e7          	jalr	-1018(ra) # 80004a04 <log_write>
  brelse(bp);
    80003e06:	854a                	mv	a0,s2
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	980080e7          	jalr	-1664(ra) # 80003788 <brelse>
}
    80003e10:	60e2                	ld	ra,24(sp)
    80003e12:	6442                	ld	s0,16(sp)
    80003e14:	64a2                	ld	s1,8(sp)
    80003e16:	6902                	ld	s2,0(sp)
    80003e18:	6105                	addi	sp,sp,32
    80003e1a:	8082                	ret

0000000080003e1c <idup>:
{
    80003e1c:	1101                	addi	sp,sp,-32
    80003e1e:	ec06                	sd	ra,24(sp)
    80003e20:	e822                	sd	s0,16(sp)
    80003e22:	e426                	sd	s1,8(sp)
    80003e24:	1000                	addi	s0,sp,32
    80003e26:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e28:	0001c517          	auipc	a0,0x1c
    80003e2c:	2c850513          	addi	a0,a0,712 # 800200f0 <itable>
    80003e30:	ffffd097          	auipc	ra,0xffffd
    80003e34:	db4080e7          	jalr	-588(ra) # 80000be4 <acquire>
  ip->ref++;
    80003e38:	449c                	lw	a5,8(s1)
    80003e3a:	2785                	addiw	a5,a5,1
    80003e3c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e3e:	0001c517          	auipc	a0,0x1c
    80003e42:	2b250513          	addi	a0,a0,690 # 800200f0 <itable>
    80003e46:	ffffd097          	auipc	ra,0xffffd
    80003e4a:	e52080e7          	jalr	-430(ra) # 80000c98 <release>
}
    80003e4e:	8526                	mv	a0,s1
    80003e50:	60e2                	ld	ra,24(sp)
    80003e52:	6442                	ld	s0,16(sp)
    80003e54:	64a2                	ld	s1,8(sp)
    80003e56:	6105                	addi	sp,sp,32
    80003e58:	8082                	ret

0000000080003e5a <ilock>:
{
    80003e5a:	1101                	addi	sp,sp,-32
    80003e5c:	ec06                	sd	ra,24(sp)
    80003e5e:	e822                	sd	s0,16(sp)
    80003e60:	e426                	sd	s1,8(sp)
    80003e62:	e04a                	sd	s2,0(sp)
    80003e64:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e66:	c115                	beqz	a0,80003e8a <ilock+0x30>
    80003e68:	84aa                	mv	s1,a0
    80003e6a:	451c                	lw	a5,8(a0)
    80003e6c:	00f05f63          	blez	a5,80003e8a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e70:	0541                	addi	a0,a0,16
    80003e72:	00001097          	auipc	ra,0x1
    80003e76:	cb2080e7          	jalr	-846(ra) # 80004b24 <acquiresleep>
  if(ip->valid == 0){
    80003e7a:	40bc                	lw	a5,64(s1)
    80003e7c:	cf99                	beqz	a5,80003e9a <ilock+0x40>
}
    80003e7e:	60e2                	ld	ra,24(sp)
    80003e80:	6442                	ld	s0,16(sp)
    80003e82:	64a2                	ld	s1,8(sp)
    80003e84:	6902                	ld	s2,0(sp)
    80003e86:	6105                	addi	sp,sp,32
    80003e88:	8082                	ret
    panic("ilock");
    80003e8a:	00004517          	auipc	a0,0x4
    80003e8e:	7e650513          	addi	a0,a0,2022 # 80008670 <syscalls+0x180>
    80003e92:	ffffc097          	auipc	ra,0xffffc
    80003e96:	6ac080e7          	jalr	1708(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e9a:	40dc                	lw	a5,4(s1)
    80003e9c:	0047d79b          	srliw	a5,a5,0x4
    80003ea0:	0001c597          	auipc	a1,0x1c
    80003ea4:	2485a583          	lw	a1,584(a1) # 800200e8 <sb+0x18>
    80003ea8:	9dbd                	addw	a1,a1,a5
    80003eaa:	4088                	lw	a0,0(s1)
    80003eac:	fffff097          	auipc	ra,0xfffff
    80003eb0:	7ac080e7          	jalr	1964(ra) # 80003658 <bread>
    80003eb4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003eb6:	05850593          	addi	a1,a0,88
    80003eba:	40dc                	lw	a5,4(s1)
    80003ebc:	8bbd                	andi	a5,a5,15
    80003ebe:	079a                	slli	a5,a5,0x6
    80003ec0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ec2:	00059783          	lh	a5,0(a1)
    80003ec6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003eca:	00259783          	lh	a5,2(a1)
    80003ece:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ed2:	00459783          	lh	a5,4(a1)
    80003ed6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003eda:	00659783          	lh	a5,6(a1)
    80003ede:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ee2:	459c                	lw	a5,8(a1)
    80003ee4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ee6:	03400613          	li	a2,52
    80003eea:	05b1                	addi	a1,a1,12
    80003eec:	05048513          	addi	a0,s1,80
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	e50080e7          	jalr	-432(ra) # 80000d40 <memmove>
    brelse(bp);
    80003ef8:	854a                	mv	a0,s2
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	88e080e7          	jalr	-1906(ra) # 80003788 <brelse>
    ip->valid = 1;
    80003f02:	4785                	li	a5,1
    80003f04:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f06:	04449783          	lh	a5,68(s1)
    80003f0a:	fbb5                	bnez	a5,80003e7e <ilock+0x24>
      panic("ilock: no type");
    80003f0c:	00004517          	auipc	a0,0x4
    80003f10:	76c50513          	addi	a0,a0,1900 # 80008678 <syscalls+0x188>
    80003f14:	ffffc097          	auipc	ra,0xffffc
    80003f18:	62a080e7          	jalr	1578(ra) # 8000053e <panic>

0000000080003f1c <iunlock>:
{
    80003f1c:	1101                	addi	sp,sp,-32
    80003f1e:	ec06                	sd	ra,24(sp)
    80003f20:	e822                	sd	s0,16(sp)
    80003f22:	e426                	sd	s1,8(sp)
    80003f24:	e04a                	sd	s2,0(sp)
    80003f26:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f28:	c905                	beqz	a0,80003f58 <iunlock+0x3c>
    80003f2a:	84aa                	mv	s1,a0
    80003f2c:	01050913          	addi	s2,a0,16
    80003f30:	854a                	mv	a0,s2
    80003f32:	00001097          	auipc	ra,0x1
    80003f36:	c8c080e7          	jalr	-884(ra) # 80004bbe <holdingsleep>
    80003f3a:	cd19                	beqz	a0,80003f58 <iunlock+0x3c>
    80003f3c:	449c                	lw	a5,8(s1)
    80003f3e:	00f05d63          	blez	a5,80003f58 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f42:	854a                	mv	a0,s2
    80003f44:	00001097          	auipc	ra,0x1
    80003f48:	c36080e7          	jalr	-970(ra) # 80004b7a <releasesleep>
}
    80003f4c:	60e2                	ld	ra,24(sp)
    80003f4e:	6442                	ld	s0,16(sp)
    80003f50:	64a2                	ld	s1,8(sp)
    80003f52:	6902                	ld	s2,0(sp)
    80003f54:	6105                	addi	sp,sp,32
    80003f56:	8082                	ret
    panic("iunlock");
    80003f58:	00004517          	auipc	a0,0x4
    80003f5c:	73050513          	addi	a0,a0,1840 # 80008688 <syscalls+0x198>
    80003f60:	ffffc097          	auipc	ra,0xffffc
    80003f64:	5de080e7          	jalr	1502(ra) # 8000053e <panic>

0000000080003f68 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f68:	7179                	addi	sp,sp,-48
    80003f6a:	f406                	sd	ra,40(sp)
    80003f6c:	f022                	sd	s0,32(sp)
    80003f6e:	ec26                	sd	s1,24(sp)
    80003f70:	e84a                	sd	s2,16(sp)
    80003f72:	e44e                	sd	s3,8(sp)
    80003f74:	e052                	sd	s4,0(sp)
    80003f76:	1800                	addi	s0,sp,48
    80003f78:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f7a:	05050493          	addi	s1,a0,80
    80003f7e:	08050913          	addi	s2,a0,128
    80003f82:	a021                	j	80003f8a <itrunc+0x22>
    80003f84:	0491                	addi	s1,s1,4
    80003f86:	01248d63          	beq	s1,s2,80003fa0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f8a:	408c                	lw	a1,0(s1)
    80003f8c:	dde5                	beqz	a1,80003f84 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f8e:	0009a503          	lw	a0,0(s3)
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	90c080e7          	jalr	-1780(ra) # 8000389e <bfree>
      ip->addrs[i] = 0;
    80003f9a:	0004a023          	sw	zero,0(s1)
    80003f9e:	b7dd                	j	80003f84 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003fa0:	0809a583          	lw	a1,128(s3)
    80003fa4:	e185                	bnez	a1,80003fc4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003fa6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	de4080e7          	jalr	-540(ra) # 80003d90 <iupdate>
}
    80003fb4:	70a2                	ld	ra,40(sp)
    80003fb6:	7402                	ld	s0,32(sp)
    80003fb8:	64e2                	ld	s1,24(sp)
    80003fba:	6942                	ld	s2,16(sp)
    80003fbc:	69a2                	ld	s3,8(sp)
    80003fbe:	6a02                	ld	s4,0(sp)
    80003fc0:	6145                	addi	sp,sp,48
    80003fc2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fc4:	0009a503          	lw	a0,0(s3)
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	690080e7          	jalr	1680(ra) # 80003658 <bread>
    80003fd0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fd2:	05850493          	addi	s1,a0,88
    80003fd6:	45850913          	addi	s2,a0,1112
    80003fda:	a811                	j	80003fee <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003fdc:	0009a503          	lw	a0,0(s3)
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	8be080e7          	jalr	-1858(ra) # 8000389e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003fe8:	0491                	addi	s1,s1,4
    80003fea:	01248563          	beq	s1,s2,80003ff4 <itrunc+0x8c>
      if(a[j])
    80003fee:	408c                	lw	a1,0(s1)
    80003ff0:	dde5                	beqz	a1,80003fe8 <itrunc+0x80>
    80003ff2:	b7ed                	j	80003fdc <itrunc+0x74>
    brelse(bp);
    80003ff4:	8552                	mv	a0,s4
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	792080e7          	jalr	1938(ra) # 80003788 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ffe:	0809a583          	lw	a1,128(s3)
    80004002:	0009a503          	lw	a0,0(s3)
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	898080e7          	jalr	-1896(ra) # 8000389e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000400e:	0809a023          	sw	zero,128(s3)
    80004012:	bf51                	j	80003fa6 <itrunc+0x3e>

0000000080004014 <iput>:
{
    80004014:	1101                	addi	sp,sp,-32
    80004016:	ec06                	sd	ra,24(sp)
    80004018:	e822                	sd	s0,16(sp)
    8000401a:	e426                	sd	s1,8(sp)
    8000401c:	e04a                	sd	s2,0(sp)
    8000401e:	1000                	addi	s0,sp,32
    80004020:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004022:	0001c517          	auipc	a0,0x1c
    80004026:	0ce50513          	addi	a0,a0,206 # 800200f0 <itable>
    8000402a:	ffffd097          	auipc	ra,0xffffd
    8000402e:	bba080e7          	jalr	-1094(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004032:	4498                	lw	a4,8(s1)
    80004034:	4785                	li	a5,1
    80004036:	02f70363          	beq	a4,a5,8000405c <iput+0x48>
  ip->ref--;
    8000403a:	449c                	lw	a5,8(s1)
    8000403c:	37fd                	addiw	a5,a5,-1
    8000403e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004040:	0001c517          	auipc	a0,0x1c
    80004044:	0b050513          	addi	a0,a0,176 # 800200f0 <itable>
    80004048:	ffffd097          	auipc	ra,0xffffd
    8000404c:	c50080e7          	jalr	-944(ra) # 80000c98 <release>
}
    80004050:	60e2                	ld	ra,24(sp)
    80004052:	6442                	ld	s0,16(sp)
    80004054:	64a2                	ld	s1,8(sp)
    80004056:	6902                	ld	s2,0(sp)
    80004058:	6105                	addi	sp,sp,32
    8000405a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000405c:	40bc                	lw	a5,64(s1)
    8000405e:	dff1                	beqz	a5,8000403a <iput+0x26>
    80004060:	04a49783          	lh	a5,74(s1)
    80004064:	fbf9                	bnez	a5,8000403a <iput+0x26>
    acquiresleep(&ip->lock);
    80004066:	01048913          	addi	s2,s1,16
    8000406a:	854a                	mv	a0,s2
    8000406c:	00001097          	auipc	ra,0x1
    80004070:	ab8080e7          	jalr	-1352(ra) # 80004b24 <acquiresleep>
    release(&itable.lock);
    80004074:	0001c517          	auipc	a0,0x1c
    80004078:	07c50513          	addi	a0,a0,124 # 800200f0 <itable>
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	c1c080e7          	jalr	-996(ra) # 80000c98 <release>
    itrunc(ip);
    80004084:	8526                	mv	a0,s1
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	ee2080e7          	jalr	-286(ra) # 80003f68 <itrunc>
    ip->type = 0;
    8000408e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004092:	8526                	mv	a0,s1
    80004094:	00000097          	auipc	ra,0x0
    80004098:	cfc080e7          	jalr	-772(ra) # 80003d90 <iupdate>
    ip->valid = 0;
    8000409c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040a0:	854a                	mv	a0,s2
    800040a2:	00001097          	auipc	ra,0x1
    800040a6:	ad8080e7          	jalr	-1320(ra) # 80004b7a <releasesleep>
    acquire(&itable.lock);
    800040aa:	0001c517          	auipc	a0,0x1c
    800040ae:	04650513          	addi	a0,a0,70 # 800200f0 <itable>
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	b32080e7          	jalr	-1230(ra) # 80000be4 <acquire>
    800040ba:	b741                	j	8000403a <iput+0x26>

00000000800040bc <iunlockput>:
{
    800040bc:	1101                	addi	sp,sp,-32
    800040be:	ec06                	sd	ra,24(sp)
    800040c0:	e822                	sd	s0,16(sp)
    800040c2:	e426                	sd	s1,8(sp)
    800040c4:	1000                	addi	s0,sp,32
    800040c6:	84aa                	mv	s1,a0
  iunlock(ip);
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	e54080e7          	jalr	-428(ra) # 80003f1c <iunlock>
  iput(ip);
    800040d0:	8526                	mv	a0,s1
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	f42080e7          	jalr	-190(ra) # 80004014 <iput>
}
    800040da:	60e2                	ld	ra,24(sp)
    800040dc:	6442                	ld	s0,16(sp)
    800040de:	64a2                	ld	s1,8(sp)
    800040e0:	6105                	addi	sp,sp,32
    800040e2:	8082                	ret

00000000800040e4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040e4:	1141                	addi	sp,sp,-16
    800040e6:	e422                	sd	s0,8(sp)
    800040e8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040ea:	411c                	lw	a5,0(a0)
    800040ec:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040ee:	415c                	lw	a5,4(a0)
    800040f0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040f2:	04451783          	lh	a5,68(a0)
    800040f6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040fa:	04a51783          	lh	a5,74(a0)
    800040fe:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004102:	04c56783          	lwu	a5,76(a0)
    80004106:	e99c                	sd	a5,16(a1)
}
    80004108:	6422                	ld	s0,8(sp)
    8000410a:	0141                	addi	sp,sp,16
    8000410c:	8082                	ret

000000008000410e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000410e:	457c                	lw	a5,76(a0)
    80004110:	0ed7e963          	bltu	a5,a3,80004202 <readi+0xf4>
{
    80004114:	7159                	addi	sp,sp,-112
    80004116:	f486                	sd	ra,104(sp)
    80004118:	f0a2                	sd	s0,96(sp)
    8000411a:	eca6                	sd	s1,88(sp)
    8000411c:	e8ca                	sd	s2,80(sp)
    8000411e:	e4ce                	sd	s3,72(sp)
    80004120:	e0d2                	sd	s4,64(sp)
    80004122:	fc56                	sd	s5,56(sp)
    80004124:	f85a                	sd	s6,48(sp)
    80004126:	f45e                	sd	s7,40(sp)
    80004128:	f062                	sd	s8,32(sp)
    8000412a:	ec66                	sd	s9,24(sp)
    8000412c:	e86a                	sd	s10,16(sp)
    8000412e:	e46e                	sd	s11,8(sp)
    80004130:	1880                	addi	s0,sp,112
    80004132:	8baa                	mv	s7,a0
    80004134:	8c2e                	mv	s8,a1
    80004136:	8ab2                	mv	s5,a2
    80004138:	84b6                	mv	s1,a3
    8000413a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000413c:	9f35                	addw	a4,a4,a3
    return 0;
    8000413e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004140:	0ad76063          	bltu	a4,a3,800041e0 <readi+0xd2>
  if(off + n > ip->size)
    80004144:	00e7f463          	bgeu	a5,a4,8000414c <readi+0x3e>
    n = ip->size - off;
    80004148:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000414c:	0a0b0963          	beqz	s6,800041fe <readi+0xf0>
    80004150:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004152:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004156:	5cfd                	li	s9,-1
    80004158:	a82d                	j	80004192 <readi+0x84>
    8000415a:	020a1d93          	slli	s11,s4,0x20
    8000415e:	020ddd93          	srli	s11,s11,0x20
    80004162:	05890613          	addi	a2,s2,88
    80004166:	86ee                	mv	a3,s11
    80004168:	963a                	add	a2,a2,a4
    8000416a:	85d6                	mv	a1,s5
    8000416c:	8562                	mv	a0,s8
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	ac0080e7          	jalr	-1344(ra) # 80002c2e <either_copyout>
    80004176:	05950d63          	beq	a0,s9,800041d0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000417a:	854a                	mv	a0,s2
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	60c080e7          	jalr	1548(ra) # 80003788 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004184:	013a09bb          	addw	s3,s4,s3
    80004188:	009a04bb          	addw	s1,s4,s1
    8000418c:	9aee                	add	s5,s5,s11
    8000418e:	0569f763          	bgeu	s3,s6,800041dc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004192:	000ba903          	lw	s2,0(s7)
    80004196:	00a4d59b          	srliw	a1,s1,0xa
    8000419a:	855e                	mv	a0,s7
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	8b0080e7          	jalr	-1872(ra) # 80003a4c <bmap>
    800041a4:	0005059b          	sext.w	a1,a0
    800041a8:	854a                	mv	a0,s2
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	4ae080e7          	jalr	1198(ra) # 80003658 <bread>
    800041b2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041b4:	3ff4f713          	andi	a4,s1,1023
    800041b8:	40ed07bb          	subw	a5,s10,a4
    800041bc:	413b06bb          	subw	a3,s6,s3
    800041c0:	8a3e                	mv	s4,a5
    800041c2:	2781                	sext.w	a5,a5
    800041c4:	0006861b          	sext.w	a2,a3
    800041c8:	f8f679e3          	bgeu	a2,a5,8000415a <readi+0x4c>
    800041cc:	8a36                	mv	s4,a3
    800041ce:	b771                	j	8000415a <readi+0x4c>
      brelse(bp);
    800041d0:	854a                	mv	a0,s2
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	5b6080e7          	jalr	1462(ra) # 80003788 <brelse>
      tot = -1;
    800041da:	59fd                	li	s3,-1
  }
  return tot;
    800041dc:	0009851b          	sext.w	a0,s3
}
    800041e0:	70a6                	ld	ra,104(sp)
    800041e2:	7406                	ld	s0,96(sp)
    800041e4:	64e6                	ld	s1,88(sp)
    800041e6:	6946                	ld	s2,80(sp)
    800041e8:	69a6                	ld	s3,72(sp)
    800041ea:	6a06                	ld	s4,64(sp)
    800041ec:	7ae2                	ld	s5,56(sp)
    800041ee:	7b42                	ld	s6,48(sp)
    800041f0:	7ba2                	ld	s7,40(sp)
    800041f2:	7c02                	ld	s8,32(sp)
    800041f4:	6ce2                	ld	s9,24(sp)
    800041f6:	6d42                	ld	s10,16(sp)
    800041f8:	6da2                	ld	s11,8(sp)
    800041fa:	6165                	addi	sp,sp,112
    800041fc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041fe:	89da                	mv	s3,s6
    80004200:	bff1                	j	800041dc <readi+0xce>
    return 0;
    80004202:	4501                	li	a0,0
}
    80004204:	8082                	ret

0000000080004206 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004206:	457c                	lw	a5,76(a0)
    80004208:	10d7e863          	bltu	a5,a3,80004318 <writei+0x112>
{
    8000420c:	7159                	addi	sp,sp,-112
    8000420e:	f486                	sd	ra,104(sp)
    80004210:	f0a2                	sd	s0,96(sp)
    80004212:	eca6                	sd	s1,88(sp)
    80004214:	e8ca                	sd	s2,80(sp)
    80004216:	e4ce                	sd	s3,72(sp)
    80004218:	e0d2                	sd	s4,64(sp)
    8000421a:	fc56                	sd	s5,56(sp)
    8000421c:	f85a                	sd	s6,48(sp)
    8000421e:	f45e                	sd	s7,40(sp)
    80004220:	f062                	sd	s8,32(sp)
    80004222:	ec66                	sd	s9,24(sp)
    80004224:	e86a                	sd	s10,16(sp)
    80004226:	e46e                	sd	s11,8(sp)
    80004228:	1880                	addi	s0,sp,112
    8000422a:	8b2a                	mv	s6,a0
    8000422c:	8c2e                	mv	s8,a1
    8000422e:	8ab2                	mv	s5,a2
    80004230:	8936                	mv	s2,a3
    80004232:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004234:	00e687bb          	addw	a5,a3,a4
    80004238:	0ed7e263          	bltu	a5,a3,8000431c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000423c:	00043737          	lui	a4,0x43
    80004240:	0ef76063          	bltu	a4,a5,80004320 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004244:	0c0b8863          	beqz	s7,80004314 <writei+0x10e>
    80004248:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000424a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000424e:	5cfd                	li	s9,-1
    80004250:	a091                	j	80004294 <writei+0x8e>
    80004252:	02099d93          	slli	s11,s3,0x20
    80004256:	020ddd93          	srli	s11,s11,0x20
    8000425a:	05848513          	addi	a0,s1,88
    8000425e:	86ee                	mv	a3,s11
    80004260:	8656                	mv	a2,s5
    80004262:	85e2                	mv	a1,s8
    80004264:	953a                	add	a0,a0,a4
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	a1e080e7          	jalr	-1506(ra) # 80002c84 <either_copyin>
    8000426e:	07950263          	beq	a0,s9,800042d2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004272:	8526                	mv	a0,s1
    80004274:	00000097          	auipc	ra,0x0
    80004278:	790080e7          	jalr	1936(ra) # 80004a04 <log_write>
    brelse(bp);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	50a080e7          	jalr	1290(ra) # 80003788 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004286:	01498a3b          	addw	s4,s3,s4
    8000428a:	0129893b          	addw	s2,s3,s2
    8000428e:	9aee                	add	s5,s5,s11
    80004290:	057a7663          	bgeu	s4,s7,800042dc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004294:	000b2483          	lw	s1,0(s6)
    80004298:	00a9559b          	srliw	a1,s2,0xa
    8000429c:	855a                	mv	a0,s6
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	7ae080e7          	jalr	1966(ra) # 80003a4c <bmap>
    800042a6:	0005059b          	sext.w	a1,a0
    800042aa:	8526                	mv	a0,s1
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	3ac080e7          	jalr	940(ra) # 80003658 <bread>
    800042b4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042b6:	3ff97713          	andi	a4,s2,1023
    800042ba:	40ed07bb          	subw	a5,s10,a4
    800042be:	414b86bb          	subw	a3,s7,s4
    800042c2:	89be                	mv	s3,a5
    800042c4:	2781                	sext.w	a5,a5
    800042c6:	0006861b          	sext.w	a2,a3
    800042ca:	f8f674e3          	bgeu	a2,a5,80004252 <writei+0x4c>
    800042ce:	89b6                	mv	s3,a3
    800042d0:	b749                	j	80004252 <writei+0x4c>
      brelse(bp);
    800042d2:	8526                	mv	a0,s1
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	4b4080e7          	jalr	1204(ra) # 80003788 <brelse>
  }

  if(off > ip->size)
    800042dc:	04cb2783          	lw	a5,76(s6)
    800042e0:	0127f463          	bgeu	a5,s2,800042e8 <writei+0xe2>
    ip->size = off;
    800042e4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042e8:	855a                	mv	a0,s6
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	aa6080e7          	jalr	-1370(ra) # 80003d90 <iupdate>

  return tot;
    800042f2:	000a051b          	sext.w	a0,s4
}
    800042f6:	70a6                	ld	ra,104(sp)
    800042f8:	7406                	ld	s0,96(sp)
    800042fa:	64e6                	ld	s1,88(sp)
    800042fc:	6946                	ld	s2,80(sp)
    800042fe:	69a6                	ld	s3,72(sp)
    80004300:	6a06                	ld	s4,64(sp)
    80004302:	7ae2                	ld	s5,56(sp)
    80004304:	7b42                	ld	s6,48(sp)
    80004306:	7ba2                	ld	s7,40(sp)
    80004308:	7c02                	ld	s8,32(sp)
    8000430a:	6ce2                	ld	s9,24(sp)
    8000430c:	6d42                	ld	s10,16(sp)
    8000430e:	6da2                	ld	s11,8(sp)
    80004310:	6165                	addi	sp,sp,112
    80004312:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004314:	8a5e                	mv	s4,s7
    80004316:	bfc9                	j	800042e8 <writei+0xe2>
    return -1;
    80004318:	557d                	li	a0,-1
}
    8000431a:	8082                	ret
    return -1;
    8000431c:	557d                	li	a0,-1
    8000431e:	bfe1                	j	800042f6 <writei+0xf0>
    return -1;
    80004320:	557d                	li	a0,-1
    80004322:	bfd1                	j	800042f6 <writei+0xf0>

0000000080004324 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004324:	1141                	addi	sp,sp,-16
    80004326:	e406                	sd	ra,8(sp)
    80004328:	e022                	sd	s0,0(sp)
    8000432a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000432c:	4639                	li	a2,14
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	a8a080e7          	jalr	-1398(ra) # 80000db8 <strncmp>
}
    80004336:	60a2                	ld	ra,8(sp)
    80004338:	6402                	ld	s0,0(sp)
    8000433a:	0141                	addi	sp,sp,16
    8000433c:	8082                	ret

000000008000433e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000433e:	7139                	addi	sp,sp,-64
    80004340:	fc06                	sd	ra,56(sp)
    80004342:	f822                	sd	s0,48(sp)
    80004344:	f426                	sd	s1,40(sp)
    80004346:	f04a                	sd	s2,32(sp)
    80004348:	ec4e                	sd	s3,24(sp)
    8000434a:	e852                	sd	s4,16(sp)
    8000434c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000434e:	04451703          	lh	a4,68(a0)
    80004352:	4785                	li	a5,1
    80004354:	00f71a63          	bne	a4,a5,80004368 <dirlookup+0x2a>
    80004358:	892a                	mv	s2,a0
    8000435a:	89ae                	mv	s3,a1
    8000435c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000435e:	457c                	lw	a5,76(a0)
    80004360:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004362:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004364:	e79d                	bnez	a5,80004392 <dirlookup+0x54>
    80004366:	a8a5                	j	800043de <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004368:	00004517          	auipc	a0,0x4
    8000436c:	32850513          	addi	a0,a0,808 # 80008690 <syscalls+0x1a0>
    80004370:	ffffc097          	auipc	ra,0xffffc
    80004374:	1ce080e7          	jalr	462(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004378:	00004517          	auipc	a0,0x4
    8000437c:	33050513          	addi	a0,a0,816 # 800086a8 <syscalls+0x1b8>
    80004380:	ffffc097          	auipc	ra,0xffffc
    80004384:	1be080e7          	jalr	446(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004388:	24c1                	addiw	s1,s1,16
    8000438a:	04c92783          	lw	a5,76(s2)
    8000438e:	04f4f763          	bgeu	s1,a5,800043dc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004392:	4741                	li	a4,16
    80004394:	86a6                	mv	a3,s1
    80004396:	fc040613          	addi	a2,s0,-64
    8000439a:	4581                	li	a1,0
    8000439c:	854a                	mv	a0,s2
    8000439e:	00000097          	auipc	ra,0x0
    800043a2:	d70080e7          	jalr	-656(ra) # 8000410e <readi>
    800043a6:	47c1                	li	a5,16
    800043a8:	fcf518e3          	bne	a0,a5,80004378 <dirlookup+0x3a>
    if(de.inum == 0)
    800043ac:	fc045783          	lhu	a5,-64(s0)
    800043b0:	dfe1                	beqz	a5,80004388 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043b2:	fc240593          	addi	a1,s0,-62
    800043b6:	854e                	mv	a0,s3
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	f6c080e7          	jalr	-148(ra) # 80004324 <namecmp>
    800043c0:	f561                	bnez	a0,80004388 <dirlookup+0x4a>
      if(poff)
    800043c2:	000a0463          	beqz	s4,800043ca <dirlookup+0x8c>
        *poff = off;
    800043c6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043ca:	fc045583          	lhu	a1,-64(s0)
    800043ce:	00092503          	lw	a0,0(s2)
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	754080e7          	jalr	1876(ra) # 80003b26 <iget>
    800043da:	a011                	j	800043de <dirlookup+0xa0>
  return 0;
    800043dc:	4501                	li	a0,0
}
    800043de:	70e2                	ld	ra,56(sp)
    800043e0:	7442                	ld	s0,48(sp)
    800043e2:	74a2                	ld	s1,40(sp)
    800043e4:	7902                	ld	s2,32(sp)
    800043e6:	69e2                	ld	s3,24(sp)
    800043e8:	6a42                	ld	s4,16(sp)
    800043ea:	6121                	addi	sp,sp,64
    800043ec:	8082                	ret

00000000800043ee <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043ee:	711d                	addi	sp,sp,-96
    800043f0:	ec86                	sd	ra,88(sp)
    800043f2:	e8a2                	sd	s0,80(sp)
    800043f4:	e4a6                	sd	s1,72(sp)
    800043f6:	e0ca                	sd	s2,64(sp)
    800043f8:	fc4e                	sd	s3,56(sp)
    800043fa:	f852                	sd	s4,48(sp)
    800043fc:	f456                	sd	s5,40(sp)
    800043fe:	f05a                	sd	s6,32(sp)
    80004400:	ec5e                	sd	s7,24(sp)
    80004402:	e862                	sd	s8,16(sp)
    80004404:	e466                	sd	s9,8(sp)
    80004406:	1080                	addi	s0,sp,96
    80004408:	84aa                	mv	s1,a0
    8000440a:	8b2e                	mv	s6,a1
    8000440c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000440e:	00054703          	lbu	a4,0(a0)
    80004412:	02f00793          	li	a5,47
    80004416:	02f70363          	beq	a4,a5,8000443c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000441a:	ffffe097          	auipc	ra,0xffffe
    8000441e:	9bc080e7          	jalr	-1604(ra) # 80001dd6 <myproc>
    80004422:	17053503          	ld	a0,368(a0)
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	9f6080e7          	jalr	-1546(ra) # 80003e1c <idup>
    8000442e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004430:	02f00913          	li	s2,47
  len = path - s;
    80004434:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004436:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004438:	4c05                	li	s8,1
    8000443a:	a865                	j	800044f2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000443c:	4585                	li	a1,1
    8000443e:	4505                	li	a0,1
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	6e6080e7          	jalr	1766(ra) # 80003b26 <iget>
    80004448:	89aa                	mv	s3,a0
    8000444a:	b7dd                	j	80004430 <namex+0x42>
      iunlockput(ip);
    8000444c:	854e                	mv	a0,s3
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	c6e080e7          	jalr	-914(ra) # 800040bc <iunlockput>
      return 0;
    80004456:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004458:	854e                	mv	a0,s3
    8000445a:	60e6                	ld	ra,88(sp)
    8000445c:	6446                	ld	s0,80(sp)
    8000445e:	64a6                	ld	s1,72(sp)
    80004460:	6906                	ld	s2,64(sp)
    80004462:	79e2                	ld	s3,56(sp)
    80004464:	7a42                	ld	s4,48(sp)
    80004466:	7aa2                	ld	s5,40(sp)
    80004468:	7b02                	ld	s6,32(sp)
    8000446a:	6be2                	ld	s7,24(sp)
    8000446c:	6c42                	ld	s8,16(sp)
    8000446e:	6ca2                	ld	s9,8(sp)
    80004470:	6125                	addi	sp,sp,96
    80004472:	8082                	ret
      iunlock(ip);
    80004474:	854e                	mv	a0,s3
    80004476:	00000097          	auipc	ra,0x0
    8000447a:	aa6080e7          	jalr	-1370(ra) # 80003f1c <iunlock>
      return ip;
    8000447e:	bfe9                	j	80004458 <namex+0x6a>
      iunlockput(ip);
    80004480:	854e                	mv	a0,s3
    80004482:	00000097          	auipc	ra,0x0
    80004486:	c3a080e7          	jalr	-966(ra) # 800040bc <iunlockput>
      return 0;
    8000448a:	89d2                	mv	s3,s4
    8000448c:	b7f1                	j	80004458 <namex+0x6a>
  len = path - s;
    8000448e:	40b48633          	sub	a2,s1,a1
    80004492:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004496:	094cd463          	bge	s9,s4,8000451e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000449a:	4639                	li	a2,14
    8000449c:	8556                	mv	a0,s5
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	8a2080e7          	jalr	-1886(ra) # 80000d40 <memmove>
  while(*path == '/')
    800044a6:	0004c783          	lbu	a5,0(s1)
    800044aa:	01279763          	bne	a5,s2,800044b8 <namex+0xca>
    path++;
    800044ae:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044b0:	0004c783          	lbu	a5,0(s1)
    800044b4:	ff278de3          	beq	a5,s2,800044ae <namex+0xc0>
    ilock(ip);
    800044b8:	854e                	mv	a0,s3
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	9a0080e7          	jalr	-1632(ra) # 80003e5a <ilock>
    if(ip->type != T_DIR){
    800044c2:	04499783          	lh	a5,68(s3)
    800044c6:	f98793e3          	bne	a5,s8,8000444c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044ca:	000b0563          	beqz	s6,800044d4 <namex+0xe6>
    800044ce:	0004c783          	lbu	a5,0(s1)
    800044d2:	d3cd                	beqz	a5,80004474 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044d4:	865e                	mv	a2,s7
    800044d6:	85d6                	mv	a1,s5
    800044d8:	854e                	mv	a0,s3
    800044da:	00000097          	auipc	ra,0x0
    800044de:	e64080e7          	jalr	-412(ra) # 8000433e <dirlookup>
    800044e2:	8a2a                	mv	s4,a0
    800044e4:	dd51                	beqz	a0,80004480 <namex+0x92>
    iunlockput(ip);
    800044e6:	854e                	mv	a0,s3
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	bd4080e7          	jalr	-1068(ra) # 800040bc <iunlockput>
    ip = next;
    800044f0:	89d2                	mv	s3,s4
  while(*path == '/')
    800044f2:	0004c783          	lbu	a5,0(s1)
    800044f6:	05279763          	bne	a5,s2,80004544 <namex+0x156>
    path++;
    800044fa:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044fc:	0004c783          	lbu	a5,0(s1)
    80004500:	ff278de3          	beq	a5,s2,800044fa <namex+0x10c>
  if(*path == 0)
    80004504:	c79d                	beqz	a5,80004532 <namex+0x144>
    path++;
    80004506:	85a6                	mv	a1,s1
  len = path - s;
    80004508:	8a5e                	mv	s4,s7
    8000450a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000450c:	01278963          	beq	a5,s2,8000451e <namex+0x130>
    80004510:	dfbd                	beqz	a5,8000448e <namex+0xa0>
    path++;
    80004512:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004514:	0004c783          	lbu	a5,0(s1)
    80004518:	ff279ce3          	bne	a5,s2,80004510 <namex+0x122>
    8000451c:	bf8d                	j	8000448e <namex+0xa0>
    memmove(name, s, len);
    8000451e:	2601                	sext.w	a2,a2
    80004520:	8556                	mv	a0,s5
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	81e080e7          	jalr	-2018(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000452a:	9a56                	add	s4,s4,s5
    8000452c:	000a0023          	sb	zero,0(s4)
    80004530:	bf9d                	j	800044a6 <namex+0xb8>
  if(nameiparent){
    80004532:	f20b03e3          	beqz	s6,80004458 <namex+0x6a>
    iput(ip);
    80004536:	854e                	mv	a0,s3
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	adc080e7          	jalr	-1316(ra) # 80004014 <iput>
    return 0;
    80004540:	4981                	li	s3,0
    80004542:	bf19                	j	80004458 <namex+0x6a>
  if(*path == 0)
    80004544:	d7fd                	beqz	a5,80004532 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004546:	0004c783          	lbu	a5,0(s1)
    8000454a:	85a6                	mv	a1,s1
    8000454c:	b7d1                	j	80004510 <namex+0x122>

000000008000454e <dirlink>:
{
    8000454e:	7139                	addi	sp,sp,-64
    80004550:	fc06                	sd	ra,56(sp)
    80004552:	f822                	sd	s0,48(sp)
    80004554:	f426                	sd	s1,40(sp)
    80004556:	f04a                	sd	s2,32(sp)
    80004558:	ec4e                	sd	s3,24(sp)
    8000455a:	e852                	sd	s4,16(sp)
    8000455c:	0080                	addi	s0,sp,64
    8000455e:	892a                	mv	s2,a0
    80004560:	8a2e                	mv	s4,a1
    80004562:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004564:	4601                	li	a2,0
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	dd8080e7          	jalr	-552(ra) # 8000433e <dirlookup>
    8000456e:	e93d                	bnez	a0,800045e4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004570:	04c92483          	lw	s1,76(s2)
    80004574:	c49d                	beqz	s1,800045a2 <dirlink+0x54>
    80004576:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004578:	4741                	li	a4,16
    8000457a:	86a6                	mv	a3,s1
    8000457c:	fc040613          	addi	a2,s0,-64
    80004580:	4581                	li	a1,0
    80004582:	854a                	mv	a0,s2
    80004584:	00000097          	auipc	ra,0x0
    80004588:	b8a080e7          	jalr	-1142(ra) # 8000410e <readi>
    8000458c:	47c1                	li	a5,16
    8000458e:	06f51163          	bne	a0,a5,800045f0 <dirlink+0xa2>
    if(de.inum == 0)
    80004592:	fc045783          	lhu	a5,-64(s0)
    80004596:	c791                	beqz	a5,800045a2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004598:	24c1                	addiw	s1,s1,16
    8000459a:	04c92783          	lw	a5,76(s2)
    8000459e:	fcf4ede3          	bltu	s1,a5,80004578 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800045a2:	4639                	li	a2,14
    800045a4:	85d2                	mv	a1,s4
    800045a6:	fc240513          	addi	a0,s0,-62
    800045aa:	ffffd097          	auipc	ra,0xffffd
    800045ae:	84a080e7          	jalr	-1974(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800045b2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045b6:	4741                	li	a4,16
    800045b8:	86a6                	mv	a3,s1
    800045ba:	fc040613          	addi	a2,s0,-64
    800045be:	4581                	li	a1,0
    800045c0:	854a                	mv	a0,s2
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	c44080e7          	jalr	-956(ra) # 80004206 <writei>
    800045ca:	872a                	mv	a4,a0
    800045cc:	47c1                	li	a5,16
  return 0;
    800045ce:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045d0:	02f71863          	bne	a4,a5,80004600 <dirlink+0xb2>
}
    800045d4:	70e2                	ld	ra,56(sp)
    800045d6:	7442                	ld	s0,48(sp)
    800045d8:	74a2                	ld	s1,40(sp)
    800045da:	7902                	ld	s2,32(sp)
    800045dc:	69e2                	ld	s3,24(sp)
    800045de:	6a42                	ld	s4,16(sp)
    800045e0:	6121                	addi	sp,sp,64
    800045e2:	8082                	ret
    iput(ip);
    800045e4:	00000097          	auipc	ra,0x0
    800045e8:	a30080e7          	jalr	-1488(ra) # 80004014 <iput>
    return -1;
    800045ec:	557d                	li	a0,-1
    800045ee:	b7dd                	j	800045d4 <dirlink+0x86>
      panic("dirlink read");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	0c850513          	addi	a0,a0,200 # 800086b8 <syscalls+0x1c8>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
    panic("dirlink");
    80004600:	00004517          	auipc	a0,0x4
    80004604:	1c850513          	addi	a0,a0,456 # 800087c8 <syscalls+0x2d8>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>

0000000080004610 <namei>:

struct inode*
namei(char *path)
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004618:	fe040613          	addi	a2,s0,-32
    8000461c:	4581                	li	a1,0
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	dd0080e7          	jalr	-560(ra) # 800043ee <namex>
}
    80004626:	60e2                	ld	ra,24(sp)
    80004628:	6442                	ld	s0,16(sp)
    8000462a:	6105                	addi	sp,sp,32
    8000462c:	8082                	ret

000000008000462e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000462e:	1141                	addi	sp,sp,-16
    80004630:	e406                	sd	ra,8(sp)
    80004632:	e022                	sd	s0,0(sp)
    80004634:	0800                	addi	s0,sp,16
    80004636:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004638:	4585                	li	a1,1
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	db4080e7          	jalr	-588(ra) # 800043ee <namex>
}
    80004642:	60a2                	ld	ra,8(sp)
    80004644:	6402                	ld	s0,0(sp)
    80004646:	0141                	addi	sp,sp,16
    80004648:	8082                	ret

000000008000464a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000464a:	1101                	addi	sp,sp,-32
    8000464c:	ec06                	sd	ra,24(sp)
    8000464e:	e822                	sd	s0,16(sp)
    80004650:	e426                	sd	s1,8(sp)
    80004652:	e04a                	sd	s2,0(sp)
    80004654:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004656:	0001d917          	auipc	s2,0x1d
    8000465a:	54290913          	addi	s2,s2,1346 # 80021b98 <log>
    8000465e:	01892583          	lw	a1,24(s2)
    80004662:	02892503          	lw	a0,40(s2)
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	ff2080e7          	jalr	-14(ra) # 80003658 <bread>
    8000466e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004670:	02c92683          	lw	a3,44(s2)
    80004674:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004676:	02d05763          	blez	a3,800046a4 <write_head+0x5a>
    8000467a:	0001d797          	auipc	a5,0x1d
    8000467e:	54e78793          	addi	a5,a5,1358 # 80021bc8 <log+0x30>
    80004682:	05c50713          	addi	a4,a0,92
    80004686:	36fd                	addiw	a3,a3,-1
    80004688:	1682                	slli	a3,a3,0x20
    8000468a:	9281                	srli	a3,a3,0x20
    8000468c:	068a                	slli	a3,a3,0x2
    8000468e:	0001d617          	auipc	a2,0x1d
    80004692:	53e60613          	addi	a2,a2,1342 # 80021bcc <log+0x34>
    80004696:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004698:	4390                	lw	a2,0(a5)
    8000469a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000469c:	0791                	addi	a5,a5,4
    8000469e:	0711                	addi	a4,a4,4
    800046a0:	fed79ce3          	bne	a5,a3,80004698 <write_head+0x4e>
  }
  bwrite(buf);
    800046a4:	8526                	mv	a0,s1
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	0a4080e7          	jalr	164(ra) # 8000374a <bwrite>
  brelse(buf);
    800046ae:	8526                	mv	a0,s1
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	0d8080e7          	jalr	216(ra) # 80003788 <brelse>
}
    800046b8:	60e2                	ld	ra,24(sp)
    800046ba:	6442                	ld	s0,16(sp)
    800046bc:	64a2                	ld	s1,8(sp)
    800046be:	6902                	ld	s2,0(sp)
    800046c0:	6105                	addi	sp,sp,32
    800046c2:	8082                	ret

00000000800046c4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046c4:	0001d797          	auipc	a5,0x1d
    800046c8:	5007a783          	lw	a5,1280(a5) # 80021bc4 <log+0x2c>
    800046cc:	0af05d63          	blez	a5,80004786 <install_trans+0xc2>
{
    800046d0:	7139                	addi	sp,sp,-64
    800046d2:	fc06                	sd	ra,56(sp)
    800046d4:	f822                	sd	s0,48(sp)
    800046d6:	f426                	sd	s1,40(sp)
    800046d8:	f04a                	sd	s2,32(sp)
    800046da:	ec4e                	sd	s3,24(sp)
    800046dc:	e852                	sd	s4,16(sp)
    800046de:	e456                	sd	s5,8(sp)
    800046e0:	e05a                	sd	s6,0(sp)
    800046e2:	0080                	addi	s0,sp,64
    800046e4:	8b2a                	mv	s6,a0
    800046e6:	0001da97          	auipc	s5,0x1d
    800046ea:	4e2a8a93          	addi	s5,s5,1250 # 80021bc8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ee:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046f0:	0001d997          	auipc	s3,0x1d
    800046f4:	4a898993          	addi	s3,s3,1192 # 80021b98 <log>
    800046f8:	a035                	j	80004724 <install_trans+0x60>
      bunpin(dbuf);
    800046fa:	8526                	mv	a0,s1
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	166080e7          	jalr	358(ra) # 80003862 <bunpin>
    brelse(lbuf);
    80004704:	854a                	mv	a0,s2
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	082080e7          	jalr	130(ra) # 80003788 <brelse>
    brelse(dbuf);
    8000470e:	8526                	mv	a0,s1
    80004710:	fffff097          	auipc	ra,0xfffff
    80004714:	078080e7          	jalr	120(ra) # 80003788 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004718:	2a05                	addiw	s4,s4,1
    8000471a:	0a91                	addi	s5,s5,4
    8000471c:	02c9a783          	lw	a5,44(s3)
    80004720:	04fa5963          	bge	s4,a5,80004772 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004724:	0189a583          	lw	a1,24(s3)
    80004728:	014585bb          	addw	a1,a1,s4
    8000472c:	2585                	addiw	a1,a1,1
    8000472e:	0289a503          	lw	a0,40(s3)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	f26080e7          	jalr	-218(ra) # 80003658 <bread>
    8000473a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000473c:	000aa583          	lw	a1,0(s5)
    80004740:	0289a503          	lw	a0,40(s3)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	f14080e7          	jalr	-236(ra) # 80003658 <bread>
    8000474c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000474e:	40000613          	li	a2,1024
    80004752:	05890593          	addi	a1,s2,88
    80004756:	05850513          	addi	a0,a0,88
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	5e6080e7          	jalr	1510(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004762:	8526                	mv	a0,s1
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	fe6080e7          	jalr	-26(ra) # 8000374a <bwrite>
    if(recovering == 0)
    8000476c:	f80b1ce3          	bnez	s6,80004704 <install_trans+0x40>
    80004770:	b769                	j	800046fa <install_trans+0x36>
}
    80004772:	70e2                	ld	ra,56(sp)
    80004774:	7442                	ld	s0,48(sp)
    80004776:	74a2                	ld	s1,40(sp)
    80004778:	7902                	ld	s2,32(sp)
    8000477a:	69e2                	ld	s3,24(sp)
    8000477c:	6a42                	ld	s4,16(sp)
    8000477e:	6aa2                	ld	s5,8(sp)
    80004780:	6b02                	ld	s6,0(sp)
    80004782:	6121                	addi	sp,sp,64
    80004784:	8082                	ret
    80004786:	8082                	ret

0000000080004788 <initlog>:
{
    80004788:	7179                	addi	sp,sp,-48
    8000478a:	f406                	sd	ra,40(sp)
    8000478c:	f022                	sd	s0,32(sp)
    8000478e:	ec26                	sd	s1,24(sp)
    80004790:	e84a                	sd	s2,16(sp)
    80004792:	e44e                	sd	s3,8(sp)
    80004794:	1800                	addi	s0,sp,48
    80004796:	892a                	mv	s2,a0
    80004798:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000479a:	0001d497          	auipc	s1,0x1d
    8000479e:	3fe48493          	addi	s1,s1,1022 # 80021b98 <log>
    800047a2:	00004597          	auipc	a1,0x4
    800047a6:	f2658593          	addi	a1,a1,-218 # 800086c8 <syscalls+0x1d8>
    800047aa:	8526                	mv	a0,s1
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	3a8080e7          	jalr	936(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800047b4:	0149a583          	lw	a1,20(s3)
    800047b8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047ba:	0109a783          	lw	a5,16(s3)
    800047be:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047c0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047c4:	854a                	mv	a0,s2
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	e92080e7          	jalr	-366(ra) # 80003658 <bread>
  log.lh.n = lh->n;
    800047ce:	4d3c                	lw	a5,88(a0)
    800047d0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047d2:	02f05563          	blez	a5,800047fc <initlog+0x74>
    800047d6:	05c50713          	addi	a4,a0,92
    800047da:	0001d697          	auipc	a3,0x1d
    800047de:	3ee68693          	addi	a3,a3,1006 # 80021bc8 <log+0x30>
    800047e2:	37fd                	addiw	a5,a5,-1
    800047e4:	1782                	slli	a5,a5,0x20
    800047e6:	9381                	srli	a5,a5,0x20
    800047e8:	078a                	slli	a5,a5,0x2
    800047ea:	06050613          	addi	a2,a0,96
    800047ee:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047f0:	4310                	lw	a2,0(a4)
    800047f2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047f4:	0711                	addi	a4,a4,4
    800047f6:	0691                	addi	a3,a3,4
    800047f8:	fef71ce3          	bne	a4,a5,800047f0 <initlog+0x68>
  brelse(buf);
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	f8c080e7          	jalr	-116(ra) # 80003788 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004804:	4505                	li	a0,1
    80004806:	00000097          	auipc	ra,0x0
    8000480a:	ebe080e7          	jalr	-322(ra) # 800046c4 <install_trans>
  log.lh.n = 0;
    8000480e:	0001d797          	auipc	a5,0x1d
    80004812:	3a07ab23          	sw	zero,950(a5) # 80021bc4 <log+0x2c>
  write_head(); // clear the log
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	e34080e7          	jalr	-460(ra) # 8000464a <write_head>
}
    8000481e:	70a2                	ld	ra,40(sp)
    80004820:	7402                	ld	s0,32(sp)
    80004822:	64e2                	ld	s1,24(sp)
    80004824:	6942                	ld	s2,16(sp)
    80004826:	69a2                	ld	s3,8(sp)
    80004828:	6145                	addi	sp,sp,48
    8000482a:	8082                	ret

000000008000482c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	e04a                	sd	s2,0(sp)
    80004836:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004838:	0001d517          	auipc	a0,0x1d
    8000483c:	36050513          	addi	a0,a0,864 # 80021b98 <log>
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	3a4080e7          	jalr	932(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004848:	0001d497          	auipc	s1,0x1d
    8000484c:	35048493          	addi	s1,s1,848 # 80021b98 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004850:	4979                	li	s2,30
    80004852:	a039                	j	80004860 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004854:	85a6                	mv	a1,s1
    80004856:	8526                	mv	a0,s1
    80004858:	ffffe097          	auipc	ra,0xffffe
    8000485c:	e86080e7          	jalr	-378(ra) # 800026de <sleep>
    if(log.committing){
    80004860:	50dc                	lw	a5,36(s1)
    80004862:	fbed                	bnez	a5,80004854 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004864:	509c                	lw	a5,32(s1)
    80004866:	0017871b          	addiw	a4,a5,1
    8000486a:	0007069b          	sext.w	a3,a4
    8000486e:	0027179b          	slliw	a5,a4,0x2
    80004872:	9fb9                	addw	a5,a5,a4
    80004874:	0017979b          	slliw	a5,a5,0x1
    80004878:	54d8                	lw	a4,44(s1)
    8000487a:	9fb9                	addw	a5,a5,a4
    8000487c:	00f95963          	bge	s2,a5,8000488e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004880:	85a6                	mv	a1,s1
    80004882:	8526                	mv	a0,s1
    80004884:	ffffe097          	auipc	ra,0xffffe
    80004888:	e5a080e7          	jalr	-422(ra) # 800026de <sleep>
    8000488c:	bfd1                	j	80004860 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000488e:	0001d517          	auipc	a0,0x1d
    80004892:	30a50513          	addi	a0,a0,778 # 80021b98 <log>
    80004896:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	400080e7          	jalr	1024(ra) # 80000c98 <release>
      break;
    }
  }
}
    800048a0:	60e2                	ld	ra,24(sp)
    800048a2:	6442                	ld	s0,16(sp)
    800048a4:	64a2                	ld	s1,8(sp)
    800048a6:	6902                	ld	s2,0(sp)
    800048a8:	6105                	addi	sp,sp,32
    800048aa:	8082                	ret

00000000800048ac <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048ac:	7139                	addi	sp,sp,-64
    800048ae:	fc06                	sd	ra,56(sp)
    800048b0:	f822                	sd	s0,48(sp)
    800048b2:	f426                	sd	s1,40(sp)
    800048b4:	f04a                	sd	s2,32(sp)
    800048b6:	ec4e                	sd	s3,24(sp)
    800048b8:	e852                	sd	s4,16(sp)
    800048ba:	e456                	sd	s5,8(sp)
    800048bc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048be:	0001d497          	auipc	s1,0x1d
    800048c2:	2da48493          	addi	s1,s1,730 # 80021b98 <log>
    800048c6:	8526                	mv	a0,s1
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800048d0:	509c                	lw	a5,32(s1)
    800048d2:	37fd                	addiw	a5,a5,-1
    800048d4:	0007891b          	sext.w	s2,a5
    800048d8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048da:	50dc                	lw	a5,36(s1)
    800048dc:	efb9                	bnez	a5,8000493a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048de:	06091663          	bnez	s2,8000494a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800048e2:	0001d497          	auipc	s1,0x1d
    800048e6:	2b648493          	addi	s1,s1,694 # 80021b98 <log>
    800048ea:	4785                	li	a5,1
    800048ec:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048ee:	8526                	mv	a0,s1
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	3a8080e7          	jalr	936(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048f8:	54dc                	lw	a5,44(s1)
    800048fa:	06f04763          	bgtz	a5,80004968 <end_op+0xbc>
    acquire(&log.lock);
    800048fe:	0001d497          	auipc	s1,0x1d
    80004902:	29a48493          	addi	s1,s1,666 # 80021b98 <log>
    80004906:	8526                	mv	a0,s1
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	2dc080e7          	jalr	732(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004910:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004914:	8526                	mv	a0,s1
    80004916:	ffffe097          	auipc	ra,0xffffe
    8000491a:	f92080e7          	jalr	-110(ra) # 800028a8 <wakeup>
    release(&log.lock);
    8000491e:	8526                	mv	a0,s1
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	378080e7          	jalr	888(ra) # 80000c98 <release>
}
    80004928:	70e2                	ld	ra,56(sp)
    8000492a:	7442                	ld	s0,48(sp)
    8000492c:	74a2                	ld	s1,40(sp)
    8000492e:	7902                	ld	s2,32(sp)
    80004930:	69e2                	ld	s3,24(sp)
    80004932:	6a42                	ld	s4,16(sp)
    80004934:	6aa2                	ld	s5,8(sp)
    80004936:	6121                	addi	sp,sp,64
    80004938:	8082                	ret
    panic("log.committing");
    8000493a:	00004517          	auipc	a0,0x4
    8000493e:	d9650513          	addi	a0,a0,-618 # 800086d0 <syscalls+0x1e0>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	bfc080e7          	jalr	-1028(ra) # 8000053e <panic>
    wakeup(&log);
    8000494a:	0001d497          	auipc	s1,0x1d
    8000494e:	24e48493          	addi	s1,s1,590 # 80021b98 <log>
    80004952:	8526                	mv	a0,s1
    80004954:	ffffe097          	auipc	ra,0xffffe
    80004958:	f54080e7          	jalr	-172(ra) # 800028a8 <wakeup>
  release(&log.lock);
    8000495c:	8526                	mv	a0,s1
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	33a080e7          	jalr	826(ra) # 80000c98 <release>
  if(do_commit){
    80004966:	b7c9                	j	80004928 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004968:	0001da97          	auipc	s5,0x1d
    8000496c:	260a8a93          	addi	s5,s5,608 # 80021bc8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004970:	0001da17          	auipc	s4,0x1d
    80004974:	228a0a13          	addi	s4,s4,552 # 80021b98 <log>
    80004978:	018a2583          	lw	a1,24(s4)
    8000497c:	012585bb          	addw	a1,a1,s2
    80004980:	2585                	addiw	a1,a1,1
    80004982:	028a2503          	lw	a0,40(s4)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	cd2080e7          	jalr	-814(ra) # 80003658 <bread>
    8000498e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004990:	000aa583          	lw	a1,0(s5)
    80004994:	028a2503          	lw	a0,40(s4)
    80004998:	fffff097          	auipc	ra,0xfffff
    8000499c:	cc0080e7          	jalr	-832(ra) # 80003658 <bread>
    800049a0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800049a2:	40000613          	li	a2,1024
    800049a6:	05850593          	addi	a1,a0,88
    800049aa:	05848513          	addi	a0,s1,88
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	392080e7          	jalr	914(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800049b6:	8526                	mv	a0,s1
    800049b8:	fffff097          	auipc	ra,0xfffff
    800049bc:	d92080e7          	jalr	-622(ra) # 8000374a <bwrite>
    brelse(from);
    800049c0:	854e                	mv	a0,s3
    800049c2:	fffff097          	auipc	ra,0xfffff
    800049c6:	dc6080e7          	jalr	-570(ra) # 80003788 <brelse>
    brelse(to);
    800049ca:	8526                	mv	a0,s1
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	dbc080e7          	jalr	-580(ra) # 80003788 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049d4:	2905                	addiw	s2,s2,1
    800049d6:	0a91                	addi	s5,s5,4
    800049d8:	02ca2783          	lw	a5,44(s4)
    800049dc:	f8f94ee3          	blt	s2,a5,80004978 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	c6a080e7          	jalr	-918(ra) # 8000464a <write_head>
    install_trans(0); // Now install writes to home locations
    800049e8:	4501                	li	a0,0
    800049ea:	00000097          	auipc	ra,0x0
    800049ee:	cda080e7          	jalr	-806(ra) # 800046c4 <install_trans>
    log.lh.n = 0;
    800049f2:	0001d797          	auipc	a5,0x1d
    800049f6:	1c07a923          	sw	zero,466(a5) # 80021bc4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	c50080e7          	jalr	-944(ra) # 8000464a <write_head>
    80004a02:	bdf5                	j	800048fe <end_op+0x52>

0000000080004a04 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a04:	1101                	addi	sp,sp,-32
    80004a06:	ec06                	sd	ra,24(sp)
    80004a08:	e822                	sd	s0,16(sp)
    80004a0a:	e426                	sd	s1,8(sp)
    80004a0c:	e04a                	sd	s2,0(sp)
    80004a0e:	1000                	addi	s0,sp,32
    80004a10:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a12:	0001d917          	auipc	s2,0x1d
    80004a16:	18690913          	addi	s2,s2,390 # 80021b98 <log>
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	1c8080e7          	jalr	456(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a24:	02c92603          	lw	a2,44(s2)
    80004a28:	47f5                	li	a5,29
    80004a2a:	06c7c563          	blt	a5,a2,80004a94 <log_write+0x90>
    80004a2e:	0001d797          	auipc	a5,0x1d
    80004a32:	1867a783          	lw	a5,390(a5) # 80021bb4 <log+0x1c>
    80004a36:	37fd                	addiw	a5,a5,-1
    80004a38:	04f65e63          	bge	a2,a5,80004a94 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a3c:	0001d797          	auipc	a5,0x1d
    80004a40:	17c7a783          	lw	a5,380(a5) # 80021bb8 <log+0x20>
    80004a44:	06f05063          	blez	a5,80004aa4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a48:	4781                	li	a5,0
    80004a4a:	06c05563          	blez	a2,80004ab4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a4e:	44cc                	lw	a1,12(s1)
    80004a50:	0001d717          	auipc	a4,0x1d
    80004a54:	17870713          	addi	a4,a4,376 # 80021bc8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a58:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a5a:	4314                	lw	a3,0(a4)
    80004a5c:	04b68c63          	beq	a3,a1,80004ab4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a60:	2785                	addiw	a5,a5,1
    80004a62:	0711                	addi	a4,a4,4
    80004a64:	fef61be3          	bne	a2,a5,80004a5a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a68:	0621                	addi	a2,a2,8
    80004a6a:	060a                	slli	a2,a2,0x2
    80004a6c:	0001d797          	auipc	a5,0x1d
    80004a70:	12c78793          	addi	a5,a5,300 # 80021b98 <log>
    80004a74:	963e                	add	a2,a2,a5
    80004a76:	44dc                	lw	a5,12(s1)
    80004a78:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a7a:	8526                	mv	a0,s1
    80004a7c:	fffff097          	auipc	ra,0xfffff
    80004a80:	daa080e7          	jalr	-598(ra) # 80003826 <bpin>
    log.lh.n++;
    80004a84:	0001d717          	auipc	a4,0x1d
    80004a88:	11470713          	addi	a4,a4,276 # 80021b98 <log>
    80004a8c:	575c                	lw	a5,44(a4)
    80004a8e:	2785                	addiw	a5,a5,1
    80004a90:	d75c                	sw	a5,44(a4)
    80004a92:	a835                	j	80004ace <log_write+0xca>
    panic("too big a transaction");
    80004a94:	00004517          	auipc	a0,0x4
    80004a98:	c4c50513          	addi	a0,a0,-948 # 800086e0 <syscalls+0x1f0>
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	aa2080e7          	jalr	-1374(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004aa4:	00004517          	auipc	a0,0x4
    80004aa8:	c5450513          	addi	a0,a0,-940 # 800086f8 <syscalls+0x208>
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004ab4:	00878713          	addi	a4,a5,8
    80004ab8:	00271693          	slli	a3,a4,0x2
    80004abc:	0001d717          	auipc	a4,0x1d
    80004ac0:	0dc70713          	addi	a4,a4,220 # 80021b98 <log>
    80004ac4:	9736                	add	a4,a4,a3
    80004ac6:	44d4                	lw	a3,12(s1)
    80004ac8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004aca:	faf608e3          	beq	a2,a5,80004a7a <log_write+0x76>
  }
  release(&log.lock);
    80004ace:	0001d517          	auipc	a0,0x1d
    80004ad2:	0ca50513          	addi	a0,a0,202 # 80021b98 <log>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	1c2080e7          	jalr	450(ra) # 80000c98 <release>
}
    80004ade:	60e2                	ld	ra,24(sp)
    80004ae0:	6442                	ld	s0,16(sp)
    80004ae2:	64a2                	ld	s1,8(sp)
    80004ae4:	6902                	ld	s2,0(sp)
    80004ae6:	6105                	addi	sp,sp,32
    80004ae8:	8082                	ret

0000000080004aea <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004aea:	1101                	addi	sp,sp,-32
    80004aec:	ec06                	sd	ra,24(sp)
    80004aee:	e822                	sd	s0,16(sp)
    80004af0:	e426                	sd	s1,8(sp)
    80004af2:	e04a                	sd	s2,0(sp)
    80004af4:	1000                	addi	s0,sp,32
    80004af6:	84aa                	mv	s1,a0
    80004af8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004afa:	00004597          	auipc	a1,0x4
    80004afe:	c1e58593          	addi	a1,a1,-994 # 80008718 <syscalls+0x228>
    80004b02:	0521                	addi	a0,a0,8
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	050080e7          	jalr	80(ra) # 80000b54 <initlock>
  lk->name = name;
    80004b0c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b10:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b14:	0204a423          	sw	zero,40(s1)
}
    80004b18:	60e2                	ld	ra,24(sp)
    80004b1a:	6442                	ld	s0,16(sp)
    80004b1c:	64a2                	ld	s1,8(sp)
    80004b1e:	6902                	ld	s2,0(sp)
    80004b20:	6105                	addi	sp,sp,32
    80004b22:	8082                	ret

0000000080004b24 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b24:	1101                	addi	sp,sp,-32
    80004b26:	ec06                	sd	ra,24(sp)
    80004b28:	e822                	sd	s0,16(sp)
    80004b2a:	e426                	sd	s1,8(sp)
    80004b2c:	e04a                	sd	s2,0(sp)
    80004b2e:	1000                	addi	s0,sp,32
    80004b30:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b32:	00850913          	addi	s2,a0,8
    80004b36:	854a                	mv	a0,s2
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	0ac080e7          	jalr	172(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004b40:	409c                	lw	a5,0(s1)
    80004b42:	cb89                	beqz	a5,80004b54 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b44:	85ca                	mv	a1,s2
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffe097          	auipc	ra,0xffffe
    80004b4c:	b96080e7          	jalr	-1130(ra) # 800026de <sleep>
  while (lk->locked) {
    80004b50:	409c                	lw	a5,0(s1)
    80004b52:	fbed                	bnez	a5,80004b44 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b54:	4785                	li	a5,1
    80004b56:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	27e080e7          	jalr	638(ra) # 80001dd6 <myproc>
    80004b60:	591c                	lw	a5,48(a0)
    80004b62:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b64:	854a                	mv	a0,s2
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
}
    80004b6e:	60e2                	ld	ra,24(sp)
    80004b70:	6442                	ld	s0,16(sp)
    80004b72:	64a2                	ld	s1,8(sp)
    80004b74:	6902                	ld	s2,0(sp)
    80004b76:	6105                	addi	sp,sp,32
    80004b78:	8082                	ret

0000000080004b7a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b7a:	1101                	addi	sp,sp,-32
    80004b7c:	ec06                	sd	ra,24(sp)
    80004b7e:	e822                	sd	s0,16(sp)
    80004b80:	e426                	sd	s1,8(sp)
    80004b82:	e04a                	sd	s2,0(sp)
    80004b84:	1000                	addi	s0,sp,32
    80004b86:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b88:	00850913          	addi	s2,a0,8
    80004b8c:	854a                	mv	a0,s2
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	056080e7          	jalr	86(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b96:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b9a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffe097          	auipc	ra,0xffffe
    80004ba4:	d08080e7          	jalr	-760(ra) # 800028a8 <wakeup>
  release(&lk->lk);
    80004ba8:	854a                	mv	a0,s2
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
}
    80004bb2:	60e2                	ld	ra,24(sp)
    80004bb4:	6442                	ld	s0,16(sp)
    80004bb6:	64a2                	ld	s1,8(sp)
    80004bb8:	6902                	ld	s2,0(sp)
    80004bba:	6105                	addi	sp,sp,32
    80004bbc:	8082                	ret

0000000080004bbe <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004bbe:	7179                	addi	sp,sp,-48
    80004bc0:	f406                	sd	ra,40(sp)
    80004bc2:	f022                	sd	s0,32(sp)
    80004bc4:	ec26                	sd	s1,24(sp)
    80004bc6:	e84a                	sd	s2,16(sp)
    80004bc8:	e44e                	sd	s3,8(sp)
    80004bca:	1800                	addi	s0,sp,48
    80004bcc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bce:	00850913          	addi	s2,a0,8
    80004bd2:	854a                	mv	a0,s2
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	010080e7          	jalr	16(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bdc:	409c                	lw	a5,0(s1)
    80004bde:	ef99                	bnez	a5,80004bfc <holdingsleep+0x3e>
    80004be0:	4481                	li	s1,0
  release(&lk->lk);
    80004be2:	854a                	mv	a0,s2
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	0b4080e7          	jalr	180(ra) # 80000c98 <release>
  return r;
}
    80004bec:	8526                	mv	a0,s1
    80004bee:	70a2                	ld	ra,40(sp)
    80004bf0:	7402                	ld	s0,32(sp)
    80004bf2:	64e2                	ld	s1,24(sp)
    80004bf4:	6942                	ld	s2,16(sp)
    80004bf6:	69a2                	ld	s3,8(sp)
    80004bf8:	6145                	addi	sp,sp,48
    80004bfa:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bfc:	0284a983          	lw	s3,40(s1)
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	1d6080e7          	jalr	470(ra) # 80001dd6 <myproc>
    80004c08:	5904                	lw	s1,48(a0)
    80004c0a:	413484b3          	sub	s1,s1,s3
    80004c0e:	0014b493          	seqz	s1,s1
    80004c12:	bfc1                	j	80004be2 <holdingsleep+0x24>

0000000080004c14 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c14:	1141                	addi	sp,sp,-16
    80004c16:	e406                	sd	ra,8(sp)
    80004c18:	e022                	sd	s0,0(sp)
    80004c1a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c1c:	00004597          	auipc	a1,0x4
    80004c20:	b0c58593          	addi	a1,a1,-1268 # 80008728 <syscalls+0x238>
    80004c24:	0001d517          	auipc	a0,0x1d
    80004c28:	0bc50513          	addi	a0,a0,188 # 80021ce0 <ftable>
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	f28080e7          	jalr	-216(ra) # 80000b54 <initlock>
}
    80004c34:	60a2                	ld	ra,8(sp)
    80004c36:	6402                	ld	s0,0(sp)
    80004c38:	0141                	addi	sp,sp,16
    80004c3a:	8082                	ret

0000000080004c3c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c3c:	1101                	addi	sp,sp,-32
    80004c3e:	ec06                	sd	ra,24(sp)
    80004c40:	e822                	sd	s0,16(sp)
    80004c42:	e426                	sd	s1,8(sp)
    80004c44:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c46:	0001d517          	auipc	a0,0x1d
    80004c4a:	09a50513          	addi	a0,a0,154 # 80021ce0 <ftable>
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	f96080e7          	jalr	-106(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c56:	0001d497          	auipc	s1,0x1d
    80004c5a:	0a248493          	addi	s1,s1,162 # 80021cf8 <ftable+0x18>
    80004c5e:	0001e717          	auipc	a4,0x1e
    80004c62:	03a70713          	addi	a4,a4,58 # 80022c98 <ftable+0xfb8>
    if(f->ref == 0){
    80004c66:	40dc                	lw	a5,4(s1)
    80004c68:	cf99                	beqz	a5,80004c86 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c6a:	02848493          	addi	s1,s1,40
    80004c6e:	fee49ce3          	bne	s1,a4,80004c66 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c72:	0001d517          	auipc	a0,0x1d
    80004c76:	06e50513          	addi	a0,a0,110 # 80021ce0 <ftable>
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	01e080e7          	jalr	30(ra) # 80000c98 <release>
  return 0;
    80004c82:	4481                	li	s1,0
    80004c84:	a819                	j	80004c9a <filealloc+0x5e>
      f->ref = 1;
    80004c86:	4785                	li	a5,1
    80004c88:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c8a:	0001d517          	auipc	a0,0x1d
    80004c8e:	05650513          	addi	a0,a0,86 # 80021ce0 <ftable>
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	006080e7          	jalr	6(ra) # 80000c98 <release>
}
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	60e2                	ld	ra,24(sp)
    80004c9e:	6442                	ld	s0,16(sp)
    80004ca0:	64a2                	ld	s1,8(sp)
    80004ca2:	6105                	addi	sp,sp,32
    80004ca4:	8082                	ret

0000000080004ca6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ca6:	1101                	addi	sp,sp,-32
    80004ca8:	ec06                	sd	ra,24(sp)
    80004caa:	e822                	sd	s0,16(sp)
    80004cac:	e426                	sd	s1,8(sp)
    80004cae:	1000                	addi	s0,sp,32
    80004cb0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004cb2:	0001d517          	auipc	a0,0x1d
    80004cb6:	02e50513          	addi	a0,a0,46 # 80021ce0 <ftable>
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	f2a080e7          	jalr	-214(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cc2:	40dc                	lw	a5,4(s1)
    80004cc4:	02f05263          	blez	a5,80004ce8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cc8:	2785                	addiw	a5,a5,1
    80004cca:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ccc:	0001d517          	auipc	a0,0x1d
    80004cd0:	01450513          	addi	a0,a0,20 # 80021ce0 <ftable>
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	fc4080e7          	jalr	-60(ra) # 80000c98 <release>
  return f;
}
    80004cdc:	8526                	mv	a0,s1
    80004cde:	60e2                	ld	ra,24(sp)
    80004ce0:	6442                	ld	s0,16(sp)
    80004ce2:	64a2                	ld	s1,8(sp)
    80004ce4:	6105                	addi	sp,sp,32
    80004ce6:	8082                	ret
    panic("filedup");
    80004ce8:	00004517          	auipc	a0,0x4
    80004cec:	a4850513          	addi	a0,a0,-1464 # 80008730 <syscalls+0x240>
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	84e080e7          	jalr	-1970(ra) # 8000053e <panic>

0000000080004cf8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cf8:	7139                	addi	sp,sp,-64
    80004cfa:	fc06                	sd	ra,56(sp)
    80004cfc:	f822                	sd	s0,48(sp)
    80004cfe:	f426                	sd	s1,40(sp)
    80004d00:	f04a                	sd	s2,32(sp)
    80004d02:	ec4e                	sd	s3,24(sp)
    80004d04:	e852                	sd	s4,16(sp)
    80004d06:	e456                	sd	s5,8(sp)
    80004d08:	0080                	addi	s0,sp,64
    80004d0a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d0c:	0001d517          	auipc	a0,0x1d
    80004d10:	fd450513          	addi	a0,a0,-44 # 80021ce0 <ftable>
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	ed0080e7          	jalr	-304(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d1c:	40dc                	lw	a5,4(s1)
    80004d1e:	06f05163          	blez	a5,80004d80 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d22:	37fd                	addiw	a5,a5,-1
    80004d24:	0007871b          	sext.w	a4,a5
    80004d28:	c0dc                	sw	a5,4(s1)
    80004d2a:	06e04363          	bgtz	a4,80004d90 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d2e:	0004a903          	lw	s2,0(s1)
    80004d32:	0094ca83          	lbu	s5,9(s1)
    80004d36:	0104ba03          	ld	s4,16(s1)
    80004d3a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d3e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d42:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d46:	0001d517          	auipc	a0,0x1d
    80004d4a:	f9a50513          	addi	a0,a0,-102 # 80021ce0 <ftable>
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	f4a080e7          	jalr	-182(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004d56:	4785                	li	a5,1
    80004d58:	04f90d63          	beq	s2,a5,80004db2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d5c:	3979                	addiw	s2,s2,-2
    80004d5e:	4785                	li	a5,1
    80004d60:	0527e063          	bltu	a5,s2,80004da0 <fileclose+0xa8>
    begin_op();
    80004d64:	00000097          	auipc	ra,0x0
    80004d68:	ac8080e7          	jalr	-1336(ra) # 8000482c <begin_op>
    iput(ff.ip);
    80004d6c:	854e                	mv	a0,s3
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	2a6080e7          	jalr	678(ra) # 80004014 <iput>
    end_op();
    80004d76:	00000097          	auipc	ra,0x0
    80004d7a:	b36080e7          	jalr	-1226(ra) # 800048ac <end_op>
    80004d7e:	a00d                	j	80004da0 <fileclose+0xa8>
    panic("fileclose");
    80004d80:	00004517          	auipc	a0,0x4
    80004d84:	9b850513          	addi	a0,a0,-1608 # 80008738 <syscalls+0x248>
    80004d88:	ffffb097          	auipc	ra,0xffffb
    80004d8c:	7b6080e7          	jalr	1974(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d90:	0001d517          	auipc	a0,0x1d
    80004d94:	f5050513          	addi	a0,a0,-176 # 80021ce0 <ftable>
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	f00080e7          	jalr	-256(ra) # 80000c98 <release>
  }
}
    80004da0:	70e2                	ld	ra,56(sp)
    80004da2:	7442                	ld	s0,48(sp)
    80004da4:	74a2                	ld	s1,40(sp)
    80004da6:	7902                	ld	s2,32(sp)
    80004da8:	69e2                	ld	s3,24(sp)
    80004daa:	6a42                	ld	s4,16(sp)
    80004dac:	6aa2                	ld	s5,8(sp)
    80004dae:	6121                	addi	sp,sp,64
    80004db0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004db2:	85d6                	mv	a1,s5
    80004db4:	8552                	mv	a0,s4
    80004db6:	00000097          	auipc	ra,0x0
    80004dba:	34c080e7          	jalr	844(ra) # 80005102 <pipeclose>
    80004dbe:	b7cd                	j	80004da0 <fileclose+0xa8>

0000000080004dc0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004dc0:	715d                	addi	sp,sp,-80
    80004dc2:	e486                	sd	ra,72(sp)
    80004dc4:	e0a2                	sd	s0,64(sp)
    80004dc6:	fc26                	sd	s1,56(sp)
    80004dc8:	f84a                	sd	s2,48(sp)
    80004dca:	f44e                	sd	s3,40(sp)
    80004dcc:	0880                	addi	s0,sp,80
    80004dce:	84aa                	mv	s1,a0
    80004dd0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	004080e7          	jalr	4(ra) # 80001dd6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004dda:	409c                	lw	a5,0(s1)
    80004ddc:	37f9                	addiw	a5,a5,-2
    80004dde:	4705                	li	a4,1
    80004de0:	04f76763          	bltu	a4,a5,80004e2e <filestat+0x6e>
    80004de4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004de6:	6c88                	ld	a0,24(s1)
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	072080e7          	jalr	114(ra) # 80003e5a <ilock>
    stati(f->ip, &st);
    80004df0:	fb840593          	addi	a1,s0,-72
    80004df4:	6c88                	ld	a0,24(s1)
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	2ee080e7          	jalr	750(ra) # 800040e4 <stati>
    iunlock(f->ip);
    80004dfe:	6c88                	ld	a0,24(s1)
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	11c080e7          	jalr	284(ra) # 80003f1c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e08:	46e1                	li	a3,24
    80004e0a:	fb840613          	addi	a2,s0,-72
    80004e0e:	85ce                	mv	a1,s3
    80004e10:	07093503          	ld	a0,112(s2)
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	85e080e7          	jalr	-1954(ra) # 80001672 <copyout>
    80004e1c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e20:	60a6                	ld	ra,72(sp)
    80004e22:	6406                	ld	s0,64(sp)
    80004e24:	74e2                	ld	s1,56(sp)
    80004e26:	7942                	ld	s2,48(sp)
    80004e28:	79a2                	ld	s3,40(sp)
    80004e2a:	6161                	addi	sp,sp,80
    80004e2c:	8082                	ret
  return -1;
    80004e2e:	557d                	li	a0,-1
    80004e30:	bfc5                	j	80004e20 <filestat+0x60>

0000000080004e32 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e32:	7179                	addi	sp,sp,-48
    80004e34:	f406                	sd	ra,40(sp)
    80004e36:	f022                	sd	s0,32(sp)
    80004e38:	ec26                	sd	s1,24(sp)
    80004e3a:	e84a                	sd	s2,16(sp)
    80004e3c:	e44e                	sd	s3,8(sp)
    80004e3e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e40:	00854783          	lbu	a5,8(a0)
    80004e44:	c3d5                	beqz	a5,80004ee8 <fileread+0xb6>
    80004e46:	84aa                	mv	s1,a0
    80004e48:	89ae                	mv	s3,a1
    80004e4a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e4c:	411c                	lw	a5,0(a0)
    80004e4e:	4705                	li	a4,1
    80004e50:	04e78963          	beq	a5,a4,80004ea2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e54:	470d                	li	a4,3
    80004e56:	04e78d63          	beq	a5,a4,80004eb0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e5a:	4709                	li	a4,2
    80004e5c:	06e79e63          	bne	a5,a4,80004ed8 <fileread+0xa6>
    ilock(f->ip);
    80004e60:	6d08                	ld	a0,24(a0)
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	ff8080e7          	jalr	-8(ra) # 80003e5a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e6a:	874a                	mv	a4,s2
    80004e6c:	5094                	lw	a3,32(s1)
    80004e6e:	864e                	mv	a2,s3
    80004e70:	4585                	li	a1,1
    80004e72:	6c88                	ld	a0,24(s1)
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	29a080e7          	jalr	666(ra) # 8000410e <readi>
    80004e7c:	892a                	mv	s2,a0
    80004e7e:	00a05563          	blez	a0,80004e88 <fileread+0x56>
      f->off += r;
    80004e82:	509c                	lw	a5,32(s1)
    80004e84:	9fa9                	addw	a5,a5,a0
    80004e86:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e88:	6c88                	ld	a0,24(s1)
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	092080e7          	jalr	146(ra) # 80003f1c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e92:	854a                	mv	a0,s2
    80004e94:	70a2                	ld	ra,40(sp)
    80004e96:	7402                	ld	s0,32(sp)
    80004e98:	64e2                	ld	s1,24(sp)
    80004e9a:	6942                	ld	s2,16(sp)
    80004e9c:	69a2                	ld	s3,8(sp)
    80004e9e:	6145                	addi	sp,sp,48
    80004ea0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ea2:	6908                	ld	a0,16(a0)
    80004ea4:	00000097          	auipc	ra,0x0
    80004ea8:	3c8080e7          	jalr	968(ra) # 8000526c <piperead>
    80004eac:	892a                	mv	s2,a0
    80004eae:	b7d5                	j	80004e92 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004eb0:	02451783          	lh	a5,36(a0)
    80004eb4:	03079693          	slli	a3,a5,0x30
    80004eb8:	92c1                	srli	a3,a3,0x30
    80004eba:	4725                	li	a4,9
    80004ebc:	02d76863          	bltu	a4,a3,80004eec <fileread+0xba>
    80004ec0:	0792                	slli	a5,a5,0x4
    80004ec2:	0001d717          	auipc	a4,0x1d
    80004ec6:	d7e70713          	addi	a4,a4,-642 # 80021c40 <devsw>
    80004eca:	97ba                	add	a5,a5,a4
    80004ecc:	639c                	ld	a5,0(a5)
    80004ece:	c38d                	beqz	a5,80004ef0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ed0:	4505                	li	a0,1
    80004ed2:	9782                	jalr	a5
    80004ed4:	892a                	mv	s2,a0
    80004ed6:	bf75                	j	80004e92 <fileread+0x60>
    panic("fileread");
    80004ed8:	00004517          	auipc	a0,0x4
    80004edc:	87050513          	addi	a0,a0,-1936 # 80008748 <syscalls+0x258>
    80004ee0:	ffffb097          	auipc	ra,0xffffb
    80004ee4:	65e080e7          	jalr	1630(ra) # 8000053e <panic>
    return -1;
    80004ee8:	597d                	li	s2,-1
    80004eea:	b765                	j	80004e92 <fileread+0x60>
      return -1;
    80004eec:	597d                	li	s2,-1
    80004eee:	b755                	j	80004e92 <fileread+0x60>
    80004ef0:	597d                	li	s2,-1
    80004ef2:	b745                	j	80004e92 <fileread+0x60>

0000000080004ef4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ef4:	715d                	addi	sp,sp,-80
    80004ef6:	e486                	sd	ra,72(sp)
    80004ef8:	e0a2                	sd	s0,64(sp)
    80004efa:	fc26                	sd	s1,56(sp)
    80004efc:	f84a                	sd	s2,48(sp)
    80004efe:	f44e                	sd	s3,40(sp)
    80004f00:	f052                	sd	s4,32(sp)
    80004f02:	ec56                	sd	s5,24(sp)
    80004f04:	e85a                	sd	s6,16(sp)
    80004f06:	e45e                	sd	s7,8(sp)
    80004f08:	e062                	sd	s8,0(sp)
    80004f0a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f0c:	00954783          	lbu	a5,9(a0)
    80004f10:	10078663          	beqz	a5,8000501c <filewrite+0x128>
    80004f14:	892a                	mv	s2,a0
    80004f16:	8aae                	mv	s5,a1
    80004f18:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f1a:	411c                	lw	a5,0(a0)
    80004f1c:	4705                	li	a4,1
    80004f1e:	02e78263          	beq	a5,a4,80004f42 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f22:	470d                	li	a4,3
    80004f24:	02e78663          	beq	a5,a4,80004f50 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f28:	4709                	li	a4,2
    80004f2a:	0ee79163          	bne	a5,a4,8000500c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f2e:	0ac05d63          	blez	a2,80004fe8 <filewrite+0xf4>
    int i = 0;
    80004f32:	4981                	li	s3,0
    80004f34:	6b05                	lui	s6,0x1
    80004f36:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f3a:	6b85                	lui	s7,0x1
    80004f3c:	c00b8b9b          	addiw	s7,s7,-1024
    80004f40:	a861                	j	80004fd8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f42:	6908                	ld	a0,16(a0)
    80004f44:	00000097          	auipc	ra,0x0
    80004f48:	22e080e7          	jalr	558(ra) # 80005172 <pipewrite>
    80004f4c:	8a2a                	mv	s4,a0
    80004f4e:	a045                	j	80004fee <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f50:	02451783          	lh	a5,36(a0)
    80004f54:	03079693          	slli	a3,a5,0x30
    80004f58:	92c1                	srli	a3,a3,0x30
    80004f5a:	4725                	li	a4,9
    80004f5c:	0cd76263          	bltu	a4,a3,80005020 <filewrite+0x12c>
    80004f60:	0792                	slli	a5,a5,0x4
    80004f62:	0001d717          	auipc	a4,0x1d
    80004f66:	cde70713          	addi	a4,a4,-802 # 80021c40 <devsw>
    80004f6a:	97ba                	add	a5,a5,a4
    80004f6c:	679c                	ld	a5,8(a5)
    80004f6e:	cbdd                	beqz	a5,80005024 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f70:	4505                	li	a0,1
    80004f72:	9782                	jalr	a5
    80004f74:	8a2a                	mv	s4,a0
    80004f76:	a8a5                	j	80004fee <filewrite+0xfa>
    80004f78:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f7c:	00000097          	auipc	ra,0x0
    80004f80:	8b0080e7          	jalr	-1872(ra) # 8000482c <begin_op>
      ilock(f->ip);
    80004f84:	01893503          	ld	a0,24(s2)
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	ed2080e7          	jalr	-302(ra) # 80003e5a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f90:	8762                	mv	a4,s8
    80004f92:	02092683          	lw	a3,32(s2)
    80004f96:	01598633          	add	a2,s3,s5
    80004f9a:	4585                	li	a1,1
    80004f9c:	01893503          	ld	a0,24(s2)
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	266080e7          	jalr	614(ra) # 80004206 <writei>
    80004fa8:	84aa                	mv	s1,a0
    80004faa:	00a05763          	blez	a0,80004fb8 <filewrite+0xc4>
        f->off += r;
    80004fae:	02092783          	lw	a5,32(s2)
    80004fb2:	9fa9                	addw	a5,a5,a0
    80004fb4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004fb8:	01893503          	ld	a0,24(s2)
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	f60080e7          	jalr	-160(ra) # 80003f1c <iunlock>
      end_op();
    80004fc4:	00000097          	auipc	ra,0x0
    80004fc8:	8e8080e7          	jalr	-1816(ra) # 800048ac <end_op>

      if(r != n1){
    80004fcc:	009c1f63          	bne	s8,s1,80004fea <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004fd0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fd4:	0149db63          	bge	s3,s4,80004fea <filewrite+0xf6>
      int n1 = n - i;
    80004fd8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fdc:	84be                	mv	s1,a5
    80004fde:	2781                	sext.w	a5,a5
    80004fe0:	f8fb5ce3          	bge	s6,a5,80004f78 <filewrite+0x84>
    80004fe4:	84de                	mv	s1,s7
    80004fe6:	bf49                	j	80004f78 <filewrite+0x84>
    int i = 0;
    80004fe8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fea:	013a1f63          	bne	s4,s3,80005008 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fee:	8552                	mv	a0,s4
    80004ff0:	60a6                	ld	ra,72(sp)
    80004ff2:	6406                	ld	s0,64(sp)
    80004ff4:	74e2                	ld	s1,56(sp)
    80004ff6:	7942                	ld	s2,48(sp)
    80004ff8:	79a2                	ld	s3,40(sp)
    80004ffa:	7a02                	ld	s4,32(sp)
    80004ffc:	6ae2                	ld	s5,24(sp)
    80004ffe:	6b42                	ld	s6,16(sp)
    80005000:	6ba2                	ld	s7,8(sp)
    80005002:	6c02                	ld	s8,0(sp)
    80005004:	6161                	addi	sp,sp,80
    80005006:	8082                	ret
    ret = (i == n ? n : -1);
    80005008:	5a7d                	li	s4,-1
    8000500a:	b7d5                	j	80004fee <filewrite+0xfa>
    panic("filewrite");
    8000500c:	00003517          	auipc	a0,0x3
    80005010:	74c50513          	addi	a0,a0,1868 # 80008758 <syscalls+0x268>
    80005014:	ffffb097          	auipc	ra,0xffffb
    80005018:	52a080e7          	jalr	1322(ra) # 8000053e <panic>
    return -1;
    8000501c:	5a7d                	li	s4,-1
    8000501e:	bfc1                	j	80004fee <filewrite+0xfa>
      return -1;
    80005020:	5a7d                	li	s4,-1
    80005022:	b7f1                	j	80004fee <filewrite+0xfa>
    80005024:	5a7d                	li	s4,-1
    80005026:	b7e1                	j	80004fee <filewrite+0xfa>

0000000080005028 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005028:	7179                	addi	sp,sp,-48
    8000502a:	f406                	sd	ra,40(sp)
    8000502c:	f022                	sd	s0,32(sp)
    8000502e:	ec26                	sd	s1,24(sp)
    80005030:	e84a                	sd	s2,16(sp)
    80005032:	e44e                	sd	s3,8(sp)
    80005034:	e052                	sd	s4,0(sp)
    80005036:	1800                	addi	s0,sp,48
    80005038:	84aa                	mv	s1,a0
    8000503a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000503c:	0005b023          	sd	zero,0(a1)
    80005040:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005044:	00000097          	auipc	ra,0x0
    80005048:	bf8080e7          	jalr	-1032(ra) # 80004c3c <filealloc>
    8000504c:	e088                	sd	a0,0(s1)
    8000504e:	c551                	beqz	a0,800050da <pipealloc+0xb2>
    80005050:	00000097          	auipc	ra,0x0
    80005054:	bec080e7          	jalr	-1044(ra) # 80004c3c <filealloc>
    80005058:	00aa3023          	sd	a0,0(s4)
    8000505c:	c92d                	beqz	a0,800050ce <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	a96080e7          	jalr	-1386(ra) # 80000af4 <kalloc>
    80005066:	892a                	mv	s2,a0
    80005068:	c125                	beqz	a0,800050c8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000506a:	4985                	li	s3,1
    8000506c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005070:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005074:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005078:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000507c:	00003597          	auipc	a1,0x3
    80005080:	6ec58593          	addi	a1,a1,1772 # 80008768 <syscalls+0x278>
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	ad0080e7          	jalr	-1328(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000508c:	609c                	ld	a5,0(s1)
    8000508e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005092:	609c                	ld	a5,0(s1)
    80005094:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005098:	609c                	ld	a5,0(s1)
    8000509a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000509e:	609c                	ld	a5,0(s1)
    800050a0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800050a4:	000a3783          	ld	a5,0(s4)
    800050a8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050ac:	000a3783          	ld	a5,0(s4)
    800050b0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050b4:	000a3783          	ld	a5,0(s4)
    800050b8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050bc:	000a3783          	ld	a5,0(s4)
    800050c0:	0127b823          	sd	s2,16(a5)
  return 0;
    800050c4:	4501                	li	a0,0
    800050c6:	a025                	j	800050ee <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050c8:	6088                	ld	a0,0(s1)
    800050ca:	e501                	bnez	a0,800050d2 <pipealloc+0xaa>
    800050cc:	a039                	j	800050da <pipealloc+0xb2>
    800050ce:	6088                	ld	a0,0(s1)
    800050d0:	c51d                	beqz	a0,800050fe <pipealloc+0xd6>
    fileclose(*f0);
    800050d2:	00000097          	auipc	ra,0x0
    800050d6:	c26080e7          	jalr	-986(ra) # 80004cf8 <fileclose>
  if(*f1)
    800050da:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050de:	557d                	li	a0,-1
  if(*f1)
    800050e0:	c799                	beqz	a5,800050ee <pipealloc+0xc6>
    fileclose(*f1);
    800050e2:	853e                	mv	a0,a5
    800050e4:	00000097          	auipc	ra,0x0
    800050e8:	c14080e7          	jalr	-1004(ra) # 80004cf8 <fileclose>
  return -1;
    800050ec:	557d                	li	a0,-1
}
    800050ee:	70a2                	ld	ra,40(sp)
    800050f0:	7402                	ld	s0,32(sp)
    800050f2:	64e2                	ld	s1,24(sp)
    800050f4:	6942                	ld	s2,16(sp)
    800050f6:	69a2                	ld	s3,8(sp)
    800050f8:	6a02                	ld	s4,0(sp)
    800050fa:	6145                	addi	sp,sp,48
    800050fc:	8082                	ret
  return -1;
    800050fe:	557d                	li	a0,-1
    80005100:	b7fd                	j	800050ee <pipealloc+0xc6>

0000000080005102 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005102:	1101                	addi	sp,sp,-32
    80005104:	ec06                	sd	ra,24(sp)
    80005106:	e822                	sd	s0,16(sp)
    80005108:	e426                	sd	s1,8(sp)
    8000510a:	e04a                	sd	s2,0(sp)
    8000510c:	1000                	addi	s0,sp,32
    8000510e:	84aa                	mv	s1,a0
    80005110:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	ad2080e7          	jalr	-1326(ra) # 80000be4 <acquire>
  if(writable){
    8000511a:	02090d63          	beqz	s2,80005154 <pipeclose+0x52>
    pi->writeopen = 0;
    8000511e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005122:	21848513          	addi	a0,s1,536
    80005126:	ffffd097          	auipc	ra,0xffffd
    8000512a:	782080e7          	jalr	1922(ra) # 800028a8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000512e:	2204b783          	ld	a5,544(s1)
    80005132:	eb95                	bnez	a5,80005166 <pipeclose+0x64>
    release(&pi->lock);
    80005134:	8526                	mv	a0,s1
    80005136:	ffffc097          	auipc	ra,0xffffc
    8000513a:	b62080e7          	jalr	-1182(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000513e:	8526                	mv	a0,s1
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	8b8080e7          	jalr	-1864(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005148:	60e2                	ld	ra,24(sp)
    8000514a:	6442                	ld	s0,16(sp)
    8000514c:	64a2                	ld	s1,8(sp)
    8000514e:	6902                	ld	s2,0(sp)
    80005150:	6105                	addi	sp,sp,32
    80005152:	8082                	ret
    pi->readopen = 0;
    80005154:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005158:	21c48513          	addi	a0,s1,540
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	74c080e7          	jalr	1868(ra) # 800028a8 <wakeup>
    80005164:	b7e9                	j	8000512e <pipeclose+0x2c>
    release(&pi->lock);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	b30080e7          	jalr	-1232(ra) # 80000c98 <release>
}
    80005170:	bfe1                	j	80005148 <pipeclose+0x46>

0000000080005172 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005172:	7159                	addi	sp,sp,-112
    80005174:	f486                	sd	ra,104(sp)
    80005176:	f0a2                	sd	s0,96(sp)
    80005178:	eca6                	sd	s1,88(sp)
    8000517a:	e8ca                	sd	s2,80(sp)
    8000517c:	e4ce                	sd	s3,72(sp)
    8000517e:	e0d2                	sd	s4,64(sp)
    80005180:	fc56                	sd	s5,56(sp)
    80005182:	f85a                	sd	s6,48(sp)
    80005184:	f45e                	sd	s7,40(sp)
    80005186:	f062                	sd	s8,32(sp)
    80005188:	ec66                	sd	s9,24(sp)
    8000518a:	1880                	addi	s0,sp,112
    8000518c:	84aa                	mv	s1,a0
    8000518e:	8aae                	mv	s5,a1
    80005190:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	c44080e7          	jalr	-956(ra) # 80001dd6 <myproc>
    8000519a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000519c:	8526                	mv	a0,s1
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	a46080e7          	jalr	-1466(ra) # 80000be4 <acquire>
  while(i < n){
    800051a6:	0d405163          	blez	s4,80005268 <pipewrite+0xf6>
    800051aa:	8ba6                	mv	s7,s1
  int i = 0;
    800051ac:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051ae:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051b0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800051b4:	21c48c13          	addi	s8,s1,540
    800051b8:	a08d                	j	8000521a <pipewrite+0xa8>
      release(&pi->lock);
    800051ba:	8526                	mv	a0,s1
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	adc080e7          	jalr	-1316(ra) # 80000c98 <release>
      return -1;
    800051c4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051c6:	854a                	mv	a0,s2
    800051c8:	70a6                	ld	ra,104(sp)
    800051ca:	7406                	ld	s0,96(sp)
    800051cc:	64e6                	ld	s1,88(sp)
    800051ce:	6946                	ld	s2,80(sp)
    800051d0:	69a6                	ld	s3,72(sp)
    800051d2:	6a06                	ld	s4,64(sp)
    800051d4:	7ae2                	ld	s5,56(sp)
    800051d6:	7b42                	ld	s6,48(sp)
    800051d8:	7ba2                	ld	s7,40(sp)
    800051da:	7c02                	ld	s8,32(sp)
    800051dc:	6ce2                	ld	s9,24(sp)
    800051de:	6165                	addi	sp,sp,112
    800051e0:	8082                	ret
      wakeup(&pi->nread);
    800051e2:	8566                	mv	a0,s9
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	6c4080e7          	jalr	1732(ra) # 800028a8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051ec:	85de                	mv	a1,s7
    800051ee:	8562                	mv	a0,s8
    800051f0:	ffffd097          	auipc	ra,0xffffd
    800051f4:	4ee080e7          	jalr	1262(ra) # 800026de <sleep>
    800051f8:	a839                	j	80005216 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051fa:	21c4a783          	lw	a5,540(s1)
    800051fe:	0017871b          	addiw	a4,a5,1
    80005202:	20e4ae23          	sw	a4,540(s1)
    80005206:	1ff7f793          	andi	a5,a5,511
    8000520a:	97a6                	add	a5,a5,s1
    8000520c:	f9f44703          	lbu	a4,-97(s0)
    80005210:	00e78c23          	sb	a4,24(a5)
      i++;
    80005214:	2905                	addiw	s2,s2,1
  while(i < n){
    80005216:	03495d63          	bge	s2,s4,80005250 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000521a:	2204a783          	lw	a5,544(s1)
    8000521e:	dfd1                	beqz	a5,800051ba <pipewrite+0x48>
    80005220:	0289a783          	lw	a5,40(s3)
    80005224:	fbd9                	bnez	a5,800051ba <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005226:	2184a783          	lw	a5,536(s1)
    8000522a:	21c4a703          	lw	a4,540(s1)
    8000522e:	2007879b          	addiw	a5,a5,512
    80005232:	faf708e3          	beq	a4,a5,800051e2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005236:	4685                	li	a3,1
    80005238:	01590633          	add	a2,s2,s5
    8000523c:	f9f40593          	addi	a1,s0,-97
    80005240:	0709b503          	ld	a0,112(s3)
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	4ba080e7          	jalr	1210(ra) # 800016fe <copyin>
    8000524c:	fb6517e3          	bne	a0,s6,800051fa <pipewrite+0x88>
  wakeup(&pi->nread);
    80005250:	21848513          	addi	a0,s1,536
    80005254:	ffffd097          	auipc	ra,0xffffd
    80005258:	654080e7          	jalr	1620(ra) # 800028a8 <wakeup>
  release(&pi->lock);
    8000525c:	8526                	mv	a0,s1
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	a3a080e7          	jalr	-1478(ra) # 80000c98 <release>
  return i;
    80005266:	b785                	j	800051c6 <pipewrite+0x54>
  int i = 0;
    80005268:	4901                	li	s2,0
    8000526a:	b7dd                	j	80005250 <pipewrite+0xde>

000000008000526c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000526c:	715d                	addi	sp,sp,-80
    8000526e:	e486                	sd	ra,72(sp)
    80005270:	e0a2                	sd	s0,64(sp)
    80005272:	fc26                	sd	s1,56(sp)
    80005274:	f84a                	sd	s2,48(sp)
    80005276:	f44e                	sd	s3,40(sp)
    80005278:	f052                	sd	s4,32(sp)
    8000527a:	ec56                	sd	s5,24(sp)
    8000527c:	e85a                	sd	s6,16(sp)
    8000527e:	0880                	addi	s0,sp,80
    80005280:	84aa                	mv	s1,a0
    80005282:	892e                	mv	s2,a1
    80005284:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005286:	ffffd097          	auipc	ra,0xffffd
    8000528a:	b50080e7          	jalr	-1200(ra) # 80001dd6 <myproc>
    8000528e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005290:	8b26                	mv	s6,s1
    80005292:	8526                	mv	a0,s1
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000529c:	2184a703          	lw	a4,536(s1)
    800052a0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052a4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052a8:	02f71463          	bne	a4,a5,800052d0 <piperead+0x64>
    800052ac:	2244a783          	lw	a5,548(s1)
    800052b0:	c385                	beqz	a5,800052d0 <piperead+0x64>
    if(pr->killed){
    800052b2:	028a2783          	lw	a5,40(s4)
    800052b6:	ebc1                	bnez	a5,80005346 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052b8:	85da                	mv	a1,s6
    800052ba:	854e                	mv	a0,s3
    800052bc:	ffffd097          	auipc	ra,0xffffd
    800052c0:	422080e7          	jalr	1058(ra) # 800026de <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052c4:	2184a703          	lw	a4,536(s1)
    800052c8:	21c4a783          	lw	a5,540(s1)
    800052cc:	fef700e3          	beq	a4,a5,800052ac <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052d0:	09505263          	blez	s5,80005354 <piperead+0xe8>
    800052d4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052d6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052d8:	2184a783          	lw	a5,536(s1)
    800052dc:	21c4a703          	lw	a4,540(s1)
    800052e0:	02f70d63          	beq	a4,a5,8000531a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052e4:	0017871b          	addiw	a4,a5,1
    800052e8:	20e4ac23          	sw	a4,536(s1)
    800052ec:	1ff7f793          	andi	a5,a5,511
    800052f0:	97a6                	add	a5,a5,s1
    800052f2:	0187c783          	lbu	a5,24(a5)
    800052f6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052fa:	4685                	li	a3,1
    800052fc:	fbf40613          	addi	a2,s0,-65
    80005300:	85ca                	mv	a1,s2
    80005302:	070a3503          	ld	a0,112(s4)
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	36c080e7          	jalr	876(ra) # 80001672 <copyout>
    8000530e:	01650663          	beq	a0,s6,8000531a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005312:	2985                	addiw	s3,s3,1
    80005314:	0905                	addi	s2,s2,1
    80005316:	fd3a91e3          	bne	s5,s3,800052d8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000531a:	21c48513          	addi	a0,s1,540
    8000531e:	ffffd097          	auipc	ra,0xffffd
    80005322:	58a080e7          	jalr	1418(ra) # 800028a8 <wakeup>
  release(&pi->lock);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
  return i;
}
    80005330:	854e                	mv	a0,s3
    80005332:	60a6                	ld	ra,72(sp)
    80005334:	6406                	ld	s0,64(sp)
    80005336:	74e2                	ld	s1,56(sp)
    80005338:	7942                	ld	s2,48(sp)
    8000533a:	79a2                	ld	s3,40(sp)
    8000533c:	7a02                	ld	s4,32(sp)
    8000533e:	6ae2                	ld	s5,24(sp)
    80005340:	6b42                	ld	s6,16(sp)
    80005342:	6161                	addi	sp,sp,80
    80005344:	8082                	ret
      release(&pi->lock);
    80005346:	8526                	mv	a0,s1
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	950080e7          	jalr	-1712(ra) # 80000c98 <release>
      return -1;
    80005350:	59fd                	li	s3,-1
    80005352:	bff9                	j	80005330 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005354:	4981                	li	s3,0
    80005356:	b7d1                	j	8000531a <piperead+0xae>

0000000080005358 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005358:	df010113          	addi	sp,sp,-528
    8000535c:	20113423          	sd	ra,520(sp)
    80005360:	20813023          	sd	s0,512(sp)
    80005364:	ffa6                	sd	s1,504(sp)
    80005366:	fbca                	sd	s2,496(sp)
    80005368:	f7ce                	sd	s3,488(sp)
    8000536a:	f3d2                	sd	s4,480(sp)
    8000536c:	efd6                	sd	s5,472(sp)
    8000536e:	ebda                	sd	s6,464(sp)
    80005370:	e7de                	sd	s7,456(sp)
    80005372:	e3e2                	sd	s8,448(sp)
    80005374:	ff66                	sd	s9,440(sp)
    80005376:	fb6a                	sd	s10,432(sp)
    80005378:	f76e                	sd	s11,424(sp)
    8000537a:	0c00                	addi	s0,sp,528
    8000537c:	84aa                	mv	s1,a0
    8000537e:	dea43c23          	sd	a0,-520(s0)
    80005382:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005386:	ffffd097          	auipc	ra,0xffffd
    8000538a:	a50080e7          	jalr	-1456(ra) # 80001dd6 <myproc>
    8000538e:	892a                	mv	s2,a0

  begin_op();
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	49c080e7          	jalr	1180(ra) # 8000482c <begin_op>

  if((ip = namei(path)) == 0){
    80005398:	8526                	mv	a0,s1
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	276080e7          	jalr	630(ra) # 80004610 <namei>
    800053a2:	c92d                	beqz	a0,80005414 <exec+0xbc>
    800053a4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	ab4080e7          	jalr	-1356(ra) # 80003e5a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800053ae:	04000713          	li	a4,64
    800053b2:	4681                	li	a3,0
    800053b4:	e5040613          	addi	a2,s0,-432
    800053b8:	4581                	li	a1,0
    800053ba:	8526                	mv	a0,s1
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	d52080e7          	jalr	-686(ra) # 8000410e <readi>
    800053c4:	04000793          	li	a5,64
    800053c8:	00f51a63          	bne	a0,a5,800053dc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800053cc:	e5042703          	lw	a4,-432(s0)
    800053d0:	464c47b7          	lui	a5,0x464c4
    800053d4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053d8:	04f70463          	beq	a4,a5,80005420 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053dc:	8526                	mv	a0,s1
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	cde080e7          	jalr	-802(ra) # 800040bc <iunlockput>
    end_op();
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	4c6080e7          	jalr	1222(ra) # 800048ac <end_op>
  }
  return -1;
    800053ee:	557d                	li	a0,-1
}
    800053f0:	20813083          	ld	ra,520(sp)
    800053f4:	20013403          	ld	s0,512(sp)
    800053f8:	74fe                	ld	s1,504(sp)
    800053fa:	795e                	ld	s2,496(sp)
    800053fc:	79be                	ld	s3,488(sp)
    800053fe:	7a1e                	ld	s4,480(sp)
    80005400:	6afe                	ld	s5,472(sp)
    80005402:	6b5e                	ld	s6,464(sp)
    80005404:	6bbe                	ld	s7,456(sp)
    80005406:	6c1e                	ld	s8,448(sp)
    80005408:	7cfa                	ld	s9,440(sp)
    8000540a:	7d5a                	ld	s10,432(sp)
    8000540c:	7dba                	ld	s11,424(sp)
    8000540e:	21010113          	addi	sp,sp,528
    80005412:	8082                	ret
    end_op();
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	498080e7          	jalr	1176(ra) # 800048ac <end_op>
    return -1;
    8000541c:	557d                	li	a0,-1
    8000541e:	bfc9                	j	800053f0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005420:	854a                	mv	a0,s2
    80005422:	ffffd097          	auipc	ra,0xffffd
    80005426:	a6a080e7          	jalr	-1430(ra) # 80001e8c <proc_pagetable>
    8000542a:	8baa                	mv	s7,a0
    8000542c:	d945                	beqz	a0,800053dc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000542e:	e7042983          	lw	s3,-400(s0)
    80005432:	e8845783          	lhu	a5,-376(s0)
    80005436:	c7ad                	beqz	a5,800054a0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005438:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000543a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000543c:	6c85                	lui	s9,0x1
    8000543e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005442:	def43823          	sd	a5,-528(s0)
    80005446:	a42d                	j	80005670 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005448:	00003517          	auipc	a0,0x3
    8000544c:	32850513          	addi	a0,a0,808 # 80008770 <syscalls+0x280>
    80005450:	ffffb097          	auipc	ra,0xffffb
    80005454:	0ee080e7          	jalr	238(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005458:	8756                	mv	a4,s5
    8000545a:	012d86bb          	addw	a3,s11,s2
    8000545e:	4581                	li	a1,0
    80005460:	8526                	mv	a0,s1
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	cac080e7          	jalr	-852(ra) # 8000410e <readi>
    8000546a:	2501                	sext.w	a0,a0
    8000546c:	1aaa9963          	bne	s5,a0,8000561e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005470:	6785                	lui	a5,0x1
    80005472:	0127893b          	addw	s2,a5,s2
    80005476:	77fd                	lui	a5,0xfffff
    80005478:	01478a3b          	addw	s4,a5,s4
    8000547c:	1f897163          	bgeu	s2,s8,8000565e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005480:	02091593          	slli	a1,s2,0x20
    80005484:	9181                	srli	a1,a1,0x20
    80005486:	95ea                	add	a1,a1,s10
    80005488:	855e                	mv	a0,s7
    8000548a:	ffffc097          	auipc	ra,0xffffc
    8000548e:	be4080e7          	jalr	-1052(ra) # 8000106e <walkaddr>
    80005492:	862a                	mv	a2,a0
    if(pa == 0)
    80005494:	d955                	beqz	a0,80005448 <exec+0xf0>
      n = PGSIZE;
    80005496:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005498:	fd9a70e3          	bgeu	s4,s9,80005458 <exec+0x100>
      n = sz - i;
    8000549c:	8ad2                	mv	s5,s4
    8000549e:	bf6d                	j	80005458 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054a0:	4901                	li	s2,0
  iunlockput(ip);
    800054a2:	8526                	mv	a0,s1
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	c18080e7          	jalr	-1000(ra) # 800040bc <iunlockput>
  end_op();
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	400080e7          	jalr	1024(ra) # 800048ac <end_op>
  p = myproc();
    800054b4:	ffffd097          	auipc	ra,0xffffd
    800054b8:	922080e7          	jalr	-1758(ra) # 80001dd6 <myproc>
    800054bc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054be:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800054c2:	6785                	lui	a5,0x1
    800054c4:	17fd                	addi	a5,a5,-1
    800054c6:	993e                	add	s2,s2,a5
    800054c8:	757d                	lui	a0,0xfffff
    800054ca:	00a977b3          	and	a5,s2,a0
    800054ce:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054d2:	6609                	lui	a2,0x2
    800054d4:	963e                	add	a2,a2,a5
    800054d6:	85be                	mv	a1,a5
    800054d8:	855e                	mv	a0,s7
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	f48080e7          	jalr	-184(ra) # 80001422 <uvmalloc>
    800054e2:	8b2a                	mv	s6,a0
  ip = 0;
    800054e4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054e6:	12050c63          	beqz	a0,8000561e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054ea:	75f9                	lui	a1,0xffffe
    800054ec:	95aa                	add	a1,a1,a0
    800054ee:	855e                	mv	a0,s7
    800054f0:	ffffc097          	auipc	ra,0xffffc
    800054f4:	150080e7          	jalr	336(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800054f8:	7c7d                	lui	s8,0xfffff
    800054fa:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054fc:	e0043783          	ld	a5,-512(s0)
    80005500:	6388                	ld	a0,0(a5)
    80005502:	c535                	beqz	a0,8000556e <exec+0x216>
    80005504:	e9040993          	addi	s3,s0,-368
    80005508:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000550c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000550e:	ffffc097          	auipc	ra,0xffffc
    80005512:	956080e7          	jalr	-1706(ra) # 80000e64 <strlen>
    80005516:	2505                	addiw	a0,a0,1
    80005518:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000551c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005520:	13896363          	bltu	s2,s8,80005646 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005524:	e0043d83          	ld	s11,-512(s0)
    80005528:	000dba03          	ld	s4,0(s11)
    8000552c:	8552                	mv	a0,s4
    8000552e:	ffffc097          	auipc	ra,0xffffc
    80005532:	936080e7          	jalr	-1738(ra) # 80000e64 <strlen>
    80005536:	0015069b          	addiw	a3,a0,1
    8000553a:	8652                	mv	a2,s4
    8000553c:	85ca                	mv	a1,s2
    8000553e:	855e                	mv	a0,s7
    80005540:	ffffc097          	auipc	ra,0xffffc
    80005544:	132080e7          	jalr	306(ra) # 80001672 <copyout>
    80005548:	10054363          	bltz	a0,8000564e <exec+0x2f6>
    ustack[argc] = sp;
    8000554c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005550:	0485                	addi	s1,s1,1
    80005552:	008d8793          	addi	a5,s11,8
    80005556:	e0f43023          	sd	a5,-512(s0)
    8000555a:	008db503          	ld	a0,8(s11)
    8000555e:	c911                	beqz	a0,80005572 <exec+0x21a>
    if(argc >= MAXARG)
    80005560:	09a1                	addi	s3,s3,8
    80005562:	fb3c96e3          	bne	s9,s3,8000550e <exec+0x1b6>
  sz = sz1;
    80005566:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000556a:	4481                	li	s1,0
    8000556c:	a84d                	j	8000561e <exec+0x2c6>
  sp = sz;
    8000556e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005570:	4481                	li	s1,0
  ustack[argc] = 0;
    80005572:	00349793          	slli	a5,s1,0x3
    80005576:	f9040713          	addi	a4,s0,-112
    8000557a:	97ba                	add	a5,a5,a4
    8000557c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005580:	00148693          	addi	a3,s1,1
    80005584:	068e                	slli	a3,a3,0x3
    80005586:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000558a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000558e:	01897663          	bgeu	s2,s8,8000559a <exec+0x242>
  sz = sz1;
    80005592:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005596:	4481                	li	s1,0
    80005598:	a059                	j	8000561e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000559a:	e9040613          	addi	a2,s0,-368
    8000559e:	85ca                	mv	a1,s2
    800055a0:	855e                	mv	a0,s7
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	0d0080e7          	jalr	208(ra) # 80001672 <copyout>
    800055aa:	0a054663          	bltz	a0,80005656 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800055ae:	078ab783          	ld	a5,120(s5)
    800055b2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055b6:	df843783          	ld	a5,-520(s0)
    800055ba:	0007c703          	lbu	a4,0(a5)
    800055be:	cf11                	beqz	a4,800055da <exec+0x282>
    800055c0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055c2:	02f00693          	li	a3,47
    800055c6:	a039                	j	800055d4 <exec+0x27c>
      last = s+1;
    800055c8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055cc:	0785                	addi	a5,a5,1
    800055ce:	fff7c703          	lbu	a4,-1(a5)
    800055d2:	c701                	beqz	a4,800055da <exec+0x282>
    if(*s == '/')
    800055d4:	fed71ce3          	bne	a4,a3,800055cc <exec+0x274>
    800055d8:	bfc5                	j	800055c8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800055da:	4641                	li	a2,16
    800055dc:	df843583          	ld	a1,-520(s0)
    800055e0:	178a8513          	addi	a0,s5,376
    800055e4:	ffffc097          	auipc	ra,0xffffc
    800055e8:	84e080e7          	jalr	-1970(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800055ec:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800055f0:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800055f4:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055f8:	078ab783          	ld	a5,120(s5)
    800055fc:	e6843703          	ld	a4,-408(s0)
    80005600:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005602:	078ab783          	ld	a5,120(s5)
    80005606:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000560a:	85ea                	mv	a1,s10
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	91c080e7          	jalr	-1764(ra) # 80001f28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005614:	0004851b          	sext.w	a0,s1
    80005618:	bbe1                	j	800053f0 <exec+0x98>
    8000561a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000561e:	e0843583          	ld	a1,-504(s0)
    80005622:	855e                	mv	a0,s7
    80005624:	ffffd097          	auipc	ra,0xffffd
    80005628:	904080e7          	jalr	-1788(ra) # 80001f28 <proc_freepagetable>
  if(ip){
    8000562c:	da0498e3          	bnez	s1,800053dc <exec+0x84>
  return -1;
    80005630:	557d                	li	a0,-1
    80005632:	bb7d                	j	800053f0 <exec+0x98>
    80005634:	e1243423          	sd	s2,-504(s0)
    80005638:	b7dd                	j	8000561e <exec+0x2c6>
    8000563a:	e1243423          	sd	s2,-504(s0)
    8000563e:	b7c5                	j	8000561e <exec+0x2c6>
    80005640:	e1243423          	sd	s2,-504(s0)
    80005644:	bfe9                	j	8000561e <exec+0x2c6>
  sz = sz1;
    80005646:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000564a:	4481                	li	s1,0
    8000564c:	bfc9                	j	8000561e <exec+0x2c6>
  sz = sz1;
    8000564e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005652:	4481                	li	s1,0
    80005654:	b7e9                	j	8000561e <exec+0x2c6>
  sz = sz1;
    80005656:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000565a:	4481                	li	s1,0
    8000565c:	b7c9                	j	8000561e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000565e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005662:	2b05                	addiw	s6,s6,1
    80005664:	0389899b          	addiw	s3,s3,56
    80005668:	e8845783          	lhu	a5,-376(s0)
    8000566c:	e2fb5be3          	bge	s6,a5,800054a2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005670:	2981                	sext.w	s3,s3
    80005672:	03800713          	li	a4,56
    80005676:	86ce                	mv	a3,s3
    80005678:	e1840613          	addi	a2,s0,-488
    8000567c:	4581                	li	a1,0
    8000567e:	8526                	mv	a0,s1
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	a8e080e7          	jalr	-1394(ra) # 8000410e <readi>
    80005688:	03800793          	li	a5,56
    8000568c:	f8f517e3          	bne	a0,a5,8000561a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005690:	e1842783          	lw	a5,-488(s0)
    80005694:	4705                	li	a4,1
    80005696:	fce796e3          	bne	a5,a4,80005662 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000569a:	e4043603          	ld	a2,-448(s0)
    8000569e:	e3843783          	ld	a5,-456(s0)
    800056a2:	f8f669e3          	bltu	a2,a5,80005634 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056a6:	e2843783          	ld	a5,-472(s0)
    800056aa:	963e                	add	a2,a2,a5
    800056ac:	f8f667e3          	bltu	a2,a5,8000563a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056b0:	85ca                	mv	a1,s2
    800056b2:	855e                	mv	a0,s7
    800056b4:	ffffc097          	auipc	ra,0xffffc
    800056b8:	d6e080e7          	jalr	-658(ra) # 80001422 <uvmalloc>
    800056bc:	e0a43423          	sd	a0,-504(s0)
    800056c0:	d141                	beqz	a0,80005640 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800056c2:	e2843d03          	ld	s10,-472(s0)
    800056c6:	df043783          	ld	a5,-528(s0)
    800056ca:	00fd77b3          	and	a5,s10,a5
    800056ce:	fba1                	bnez	a5,8000561e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056d0:	e2042d83          	lw	s11,-480(s0)
    800056d4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056d8:	f80c03e3          	beqz	s8,8000565e <exec+0x306>
    800056dc:	8a62                	mv	s4,s8
    800056de:	4901                	li	s2,0
    800056e0:	b345                	j	80005480 <exec+0x128>

00000000800056e2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056e2:	7179                	addi	sp,sp,-48
    800056e4:	f406                	sd	ra,40(sp)
    800056e6:	f022                	sd	s0,32(sp)
    800056e8:	ec26                	sd	s1,24(sp)
    800056ea:	e84a                	sd	s2,16(sp)
    800056ec:	1800                	addi	s0,sp,48
    800056ee:	892e                	mv	s2,a1
    800056f0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056f2:	fdc40593          	addi	a1,s0,-36
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	bf2080e7          	jalr	-1038(ra) # 800032e8 <argint>
    800056fe:	04054063          	bltz	a0,8000573e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005702:	fdc42703          	lw	a4,-36(s0)
    80005706:	47bd                	li	a5,15
    80005708:	02e7ed63          	bltu	a5,a4,80005742 <argfd+0x60>
    8000570c:	ffffc097          	auipc	ra,0xffffc
    80005710:	6ca080e7          	jalr	1738(ra) # 80001dd6 <myproc>
    80005714:	fdc42703          	lw	a4,-36(s0)
    80005718:	01e70793          	addi	a5,a4,30
    8000571c:	078e                	slli	a5,a5,0x3
    8000571e:	953e                	add	a0,a0,a5
    80005720:	611c                	ld	a5,0(a0)
    80005722:	c395                	beqz	a5,80005746 <argfd+0x64>
    return -1;
  if(pfd)
    80005724:	00090463          	beqz	s2,8000572c <argfd+0x4a>
    *pfd = fd;
    80005728:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000572c:	4501                	li	a0,0
  if(pf)
    8000572e:	c091                	beqz	s1,80005732 <argfd+0x50>
    *pf = f;
    80005730:	e09c                	sd	a5,0(s1)
}
    80005732:	70a2                	ld	ra,40(sp)
    80005734:	7402                	ld	s0,32(sp)
    80005736:	64e2                	ld	s1,24(sp)
    80005738:	6942                	ld	s2,16(sp)
    8000573a:	6145                	addi	sp,sp,48
    8000573c:	8082                	ret
    return -1;
    8000573e:	557d                	li	a0,-1
    80005740:	bfcd                	j	80005732 <argfd+0x50>
    return -1;
    80005742:	557d                	li	a0,-1
    80005744:	b7fd                	j	80005732 <argfd+0x50>
    80005746:	557d                	li	a0,-1
    80005748:	b7ed                	j	80005732 <argfd+0x50>

000000008000574a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000574a:	1101                	addi	sp,sp,-32
    8000574c:	ec06                	sd	ra,24(sp)
    8000574e:	e822                	sd	s0,16(sp)
    80005750:	e426                	sd	s1,8(sp)
    80005752:	1000                	addi	s0,sp,32
    80005754:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005756:	ffffc097          	auipc	ra,0xffffc
    8000575a:	680080e7          	jalr	1664(ra) # 80001dd6 <myproc>
    8000575e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005760:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005764:	4501                	li	a0,0
    80005766:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005768:	6398                	ld	a4,0(a5)
    8000576a:	cb19                	beqz	a4,80005780 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000576c:	2505                	addiw	a0,a0,1
    8000576e:	07a1                	addi	a5,a5,8
    80005770:	fed51ce3          	bne	a0,a3,80005768 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005774:	557d                	li	a0,-1
}
    80005776:	60e2                	ld	ra,24(sp)
    80005778:	6442                	ld	s0,16(sp)
    8000577a:	64a2                	ld	s1,8(sp)
    8000577c:	6105                	addi	sp,sp,32
    8000577e:	8082                	ret
      p->ofile[fd] = f;
    80005780:	01e50793          	addi	a5,a0,30
    80005784:	078e                	slli	a5,a5,0x3
    80005786:	963e                	add	a2,a2,a5
    80005788:	e204                	sd	s1,0(a2)
      return fd;
    8000578a:	b7f5                	j	80005776 <fdalloc+0x2c>

000000008000578c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000578c:	715d                	addi	sp,sp,-80
    8000578e:	e486                	sd	ra,72(sp)
    80005790:	e0a2                	sd	s0,64(sp)
    80005792:	fc26                	sd	s1,56(sp)
    80005794:	f84a                	sd	s2,48(sp)
    80005796:	f44e                	sd	s3,40(sp)
    80005798:	f052                	sd	s4,32(sp)
    8000579a:	ec56                	sd	s5,24(sp)
    8000579c:	0880                	addi	s0,sp,80
    8000579e:	89ae                	mv	s3,a1
    800057a0:	8ab2                	mv	s5,a2
    800057a2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057a4:	fb040593          	addi	a1,s0,-80
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	e86080e7          	jalr	-378(ra) # 8000462e <nameiparent>
    800057b0:	892a                	mv	s2,a0
    800057b2:	12050f63          	beqz	a0,800058f0 <create+0x164>
    return 0;

  ilock(dp);
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	6a4080e7          	jalr	1700(ra) # 80003e5a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057be:	4601                	li	a2,0
    800057c0:	fb040593          	addi	a1,s0,-80
    800057c4:	854a                	mv	a0,s2
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	b78080e7          	jalr	-1160(ra) # 8000433e <dirlookup>
    800057ce:	84aa                	mv	s1,a0
    800057d0:	c921                	beqz	a0,80005820 <create+0x94>
    iunlockput(dp);
    800057d2:	854a                	mv	a0,s2
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	8e8080e7          	jalr	-1816(ra) # 800040bc <iunlockput>
    ilock(ip);
    800057dc:	8526                	mv	a0,s1
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	67c080e7          	jalr	1660(ra) # 80003e5a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057e6:	2981                	sext.w	s3,s3
    800057e8:	4789                	li	a5,2
    800057ea:	02f99463          	bne	s3,a5,80005812 <create+0x86>
    800057ee:	0444d783          	lhu	a5,68(s1)
    800057f2:	37f9                	addiw	a5,a5,-2
    800057f4:	17c2                	slli	a5,a5,0x30
    800057f6:	93c1                	srli	a5,a5,0x30
    800057f8:	4705                	li	a4,1
    800057fa:	00f76c63          	bltu	a4,a5,80005812 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057fe:	8526                	mv	a0,s1
    80005800:	60a6                	ld	ra,72(sp)
    80005802:	6406                	ld	s0,64(sp)
    80005804:	74e2                	ld	s1,56(sp)
    80005806:	7942                	ld	s2,48(sp)
    80005808:	79a2                	ld	s3,40(sp)
    8000580a:	7a02                	ld	s4,32(sp)
    8000580c:	6ae2                	ld	s5,24(sp)
    8000580e:	6161                	addi	sp,sp,80
    80005810:	8082                	ret
    iunlockput(ip);
    80005812:	8526                	mv	a0,s1
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	8a8080e7          	jalr	-1880(ra) # 800040bc <iunlockput>
    return 0;
    8000581c:	4481                	li	s1,0
    8000581e:	b7c5                	j	800057fe <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005820:	85ce                	mv	a1,s3
    80005822:	00092503          	lw	a0,0(s2)
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	49c080e7          	jalr	1180(ra) # 80003cc2 <ialloc>
    8000582e:	84aa                	mv	s1,a0
    80005830:	c529                	beqz	a0,8000587a <create+0xee>
  ilock(ip);
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	628080e7          	jalr	1576(ra) # 80003e5a <ilock>
  ip->major = major;
    8000583a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000583e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005842:	4785                	li	a5,1
    80005844:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	546080e7          	jalr	1350(ra) # 80003d90 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005852:	2981                	sext.w	s3,s3
    80005854:	4785                	li	a5,1
    80005856:	02f98a63          	beq	s3,a5,8000588a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000585a:	40d0                	lw	a2,4(s1)
    8000585c:	fb040593          	addi	a1,s0,-80
    80005860:	854a                	mv	a0,s2
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	cec080e7          	jalr	-788(ra) # 8000454e <dirlink>
    8000586a:	06054b63          	bltz	a0,800058e0 <create+0x154>
  iunlockput(dp);
    8000586e:	854a                	mv	a0,s2
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	84c080e7          	jalr	-1972(ra) # 800040bc <iunlockput>
  return ip;
    80005878:	b759                	j	800057fe <create+0x72>
    panic("create: ialloc");
    8000587a:	00003517          	auipc	a0,0x3
    8000587e:	f1650513          	addi	a0,a0,-234 # 80008790 <syscalls+0x2a0>
    80005882:	ffffb097          	auipc	ra,0xffffb
    80005886:	cbc080e7          	jalr	-836(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000588a:	04a95783          	lhu	a5,74(s2)
    8000588e:	2785                	addiw	a5,a5,1
    80005890:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	4fa080e7          	jalr	1274(ra) # 80003d90 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000589e:	40d0                	lw	a2,4(s1)
    800058a0:	00003597          	auipc	a1,0x3
    800058a4:	f0058593          	addi	a1,a1,-256 # 800087a0 <syscalls+0x2b0>
    800058a8:	8526                	mv	a0,s1
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	ca4080e7          	jalr	-860(ra) # 8000454e <dirlink>
    800058b2:	00054f63          	bltz	a0,800058d0 <create+0x144>
    800058b6:	00492603          	lw	a2,4(s2)
    800058ba:	00003597          	auipc	a1,0x3
    800058be:	eee58593          	addi	a1,a1,-274 # 800087a8 <syscalls+0x2b8>
    800058c2:	8526                	mv	a0,s1
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	c8a080e7          	jalr	-886(ra) # 8000454e <dirlink>
    800058cc:	f80557e3          	bgez	a0,8000585a <create+0xce>
      panic("create dots");
    800058d0:	00003517          	auipc	a0,0x3
    800058d4:	ee050513          	addi	a0,a0,-288 # 800087b0 <syscalls+0x2c0>
    800058d8:	ffffb097          	auipc	ra,0xffffb
    800058dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>
    panic("create: dirlink");
    800058e0:	00003517          	auipc	a0,0x3
    800058e4:	ee050513          	addi	a0,a0,-288 # 800087c0 <syscalls+0x2d0>
    800058e8:	ffffb097          	auipc	ra,0xffffb
    800058ec:	c56080e7          	jalr	-938(ra) # 8000053e <panic>
    return 0;
    800058f0:	84aa                	mv	s1,a0
    800058f2:	b731                	j	800057fe <create+0x72>

00000000800058f4 <sys_dup>:
{
    800058f4:	7179                	addi	sp,sp,-48
    800058f6:	f406                	sd	ra,40(sp)
    800058f8:	f022                	sd	s0,32(sp)
    800058fa:	ec26                	sd	s1,24(sp)
    800058fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058fe:	fd840613          	addi	a2,s0,-40
    80005902:	4581                	li	a1,0
    80005904:	4501                	li	a0,0
    80005906:	00000097          	auipc	ra,0x0
    8000590a:	ddc080e7          	jalr	-548(ra) # 800056e2 <argfd>
    return -1;
    8000590e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005910:	02054363          	bltz	a0,80005936 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005914:	fd843503          	ld	a0,-40(s0)
    80005918:	00000097          	auipc	ra,0x0
    8000591c:	e32080e7          	jalr	-462(ra) # 8000574a <fdalloc>
    80005920:	84aa                	mv	s1,a0
    return -1;
    80005922:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005924:	00054963          	bltz	a0,80005936 <sys_dup+0x42>
  filedup(f);
    80005928:	fd843503          	ld	a0,-40(s0)
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	37a080e7          	jalr	890(ra) # 80004ca6 <filedup>
  return fd;
    80005934:	87a6                	mv	a5,s1
}
    80005936:	853e                	mv	a0,a5
    80005938:	70a2                	ld	ra,40(sp)
    8000593a:	7402                	ld	s0,32(sp)
    8000593c:	64e2                	ld	s1,24(sp)
    8000593e:	6145                	addi	sp,sp,48
    80005940:	8082                	ret

0000000080005942 <sys_read>:
{
    80005942:	7179                	addi	sp,sp,-48
    80005944:	f406                	sd	ra,40(sp)
    80005946:	f022                	sd	s0,32(sp)
    80005948:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000594a:	fe840613          	addi	a2,s0,-24
    8000594e:	4581                	li	a1,0
    80005950:	4501                	li	a0,0
    80005952:	00000097          	auipc	ra,0x0
    80005956:	d90080e7          	jalr	-624(ra) # 800056e2 <argfd>
    return -1;
    8000595a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000595c:	04054163          	bltz	a0,8000599e <sys_read+0x5c>
    80005960:	fe440593          	addi	a1,s0,-28
    80005964:	4509                	li	a0,2
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	982080e7          	jalr	-1662(ra) # 800032e8 <argint>
    return -1;
    8000596e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005970:	02054763          	bltz	a0,8000599e <sys_read+0x5c>
    80005974:	fd840593          	addi	a1,s0,-40
    80005978:	4505                	li	a0,1
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	990080e7          	jalr	-1648(ra) # 8000330a <argaddr>
    return -1;
    80005982:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005984:	00054d63          	bltz	a0,8000599e <sys_read+0x5c>
  return fileread(f, p, n);
    80005988:	fe442603          	lw	a2,-28(s0)
    8000598c:	fd843583          	ld	a1,-40(s0)
    80005990:	fe843503          	ld	a0,-24(s0)
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	49e080e7          	jalr	1182(ra) # 80004e32 <fileread>
    8000599c:	87aa                	mv	a5,a0
}
    8000599e:	853e                	mv	a0,a5
    800059a0:	70a2                	ld	ra,40(sp)
    800059a2:	7402                	ld	s0,32(sp)
    800059a4:	6145                	addi	sp,sp,48
    800059a6:	8082                	ret

00000000800059a8 <sys_write>:
{
    800059a8:	7179                	addi	sp,sp,-48
    800059aa:	f406                	sd	ra,40(sp)
    800059ac:	f022                	sd	s0,32(sp)
    800059ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b0:	fe840613          	addi	a2,s0,-24
    800059b4:	4581                	li	a1,0
    800059b6:	4501                	li	a0,0
    800059b8:	00000097          	auipc	ra,0x0
    800059bc:	d2a080e7          	jalr	-726(ra) # 800056e2 <argfd>
    return -1;
    800059c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c2:	04054163          	bltz	a0,80005a04 <sys_write+0x5c>
    800059c6:	fe440593          	addi	a1,s0,-28
    800059ca:	4509                	li	a0,2
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	91c080e7          	jalr	-1764(ra) # 800032e8 <argint>
    return -1;
    800059d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059d6:	02054763          	bltz	a0,80005a04 <sys_write+0x5c>
    800059da:	fd840593          	addi	a1,s0,-40
    800059de:	4505                	li	a0,1
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	92a080e7          	jalr	-1750(ra) # 8000330a <argaddr>
    return -1;
    800059e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059ea:	00054d63          	bltz	a0,80005a04 <sys_write+0x5c>
  return filewrite(f, p, n);
    800059ee:	fe442603          	lw	a2,-28(s0)
    800059f2:	fd843583          	ld	a1,-40(s0)
    800059f6:	fe843503          	ld	a0,-24(s0)
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	4fa080e7          	jalr	1274(ra) # 80004ef4 <filewrite>
    80005a02:	87aa                	mv	a5,a0
}
    80005a04:	853e                	mv	a0,a5
    80005a06:	70a2                	ld	ra,40(sp)
    80005a08:	7402                	ld	s0,32(sp)
    80005a0a:	6145                	addi	sp,sp,48
    80005a0c:	8082                	ret

0000000080005a0e <sys_close>:
{
    80005a0e:	1101                	addi	sp,sp,-32
    80005a10:	ec06                	sd	ra,24(sp)
    80005a12:	e822                	sd	s0,16(sp)
    80005a14:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a16:	fe040613          	addi	a2,s0,-32
    80005a1a:	fec40593          	addi	a1,s0,-20
    80005a1e:	4501                	li	a0,0
    80005a20:	00000097          	auipc	ra,0x0
    80005a24:	cc2080e7          	jalr	-830(ra) # 800056e2 <argfd>
    return -1;
    80005a28:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a2a:	02054463          	bltz	a0,80005a52 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a2e:	ffffc097          	auipc	ra,0xffffc
    80005a32:	3a8080e7          	jalr	936(ra) # 80001dd6 <myproc>
    80005a36:	fec42783          	lw	a5,-20(s0)
    80005a3a:	07f9                	addi	a5,a5,30
    80005a3c:	078e                	slli	a5,a5,0x3
    80005a3e:	97aa                	add	a5,a5,a0
    80005a40:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a44:	fe043503          	ld	a0,-32(s0)
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	2b0080e7          	jalr	688(ra) # 80004cf8 <fileclose>
  return 0;
    80005a50:	4781                	li	a5,0
}
    80005a52:	853e                	mv	a0,a5
    80005a54:	60e2                	ld	ra,24(sp)
    80005a56:	6442                	ld	s0,16(sp)
    80005a58:	6105                	addi	sp,sp,32
    80005a5a:	8082                	ret

0000000080005a5c <sys_fstat>:
{
    80005a5c:	1101                	addi	sp,sp,-32
    80005a5e:	ec06                	sd	ra,24(sp)
    80005a60:	e822                	sd	s0,16(sp)
    80005a62:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a64:	fe840613          	addi	a2,s0,-24
    80005a68:	4581                	li	a1,0
    80005a6a:	4501                	li	a0,0
    80005a6c:	00000097          	auipc	ra,0x0
    80005a70:	c76080e7          	jalr	-906(ra) # 800056e2 <argfd>
    return -1;
    80005a74:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a76:	02054563          	bltz	a0,80005aa0 <sys_fstat+0x44>
    80005a7a:	fe040593          	addi	a1,s0,-32
    80005a7e:	4505                	li	a0,1
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	88a080e7          	jalr	-1910(ra) # 8000330a <argaddr>
    return -1;
    80005a88:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a8a:	00054b63          	bltz	a0,80005aa0 <sys_fstat+0x44>
  return filestat(f, st);
    80005a8e:	fe043583          	ld	a1,-32(s0)
    80005a92:	fe843503          	ld	a0,-24(s0)
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	32a080e7          	jalr	810(ra) # 80004dc0 <filestat>
    80005a9e:	87aa                	mv	a5,a0
}
    80005aa0:	853e                	mv	a0,a5
    80005aa2:	60e2                	ld	ra,24(sp)
    80005aa4:	6442                	ld	s0,16(sp)
    80005aa6:	6105                	addi	sp,sp,32
    80005aa8:	8082                	ret

0000000080005aaa <sys_link>:
{
    80005aaa:	7169                	addi	sp,sp,-304
    80005aac:	f606                	sd	ra,296(sp)
    80005aae:	f222                	sd	s0,288(sp)
    80005ab0:	ee26                	sd	s1,280(sp)
    80005ab2:	ea4a                	sd	s2,272(sp)
    80005ab4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ab6:	08000613          	li	a2,128
    80005aba:	ed040593          	addi	a1,s0,-304
    80005abe:	4501                	li	a0,0
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	86c080e7          	jalr	-1940(ra) # 8000332c <argstr>
    return -1;
    80005ac8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aca:	10054e63          	bltz	a0,80005be6 <sys_link+0x13c>
    80005ace:	08000613          	li	a2,128
    80005ad2:	f5040593          	addi	a1,s0,-176
    80005ad6:	4505                	li	a0,1
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	854080e7          	jalr	-1964(ra) # 8000332c <argstr>
    return -1;
    80005ae0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ae2:	10054263          	bltz	a0,80005be6 <sys_link+0x13c>
  begin_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	d46080e7          	jalr	-698(ra) # 8000482c <begin_op>
  if((ip = namei(old)) == 0){
    80005aee:	ed040513          	addi	a0,s0,-304
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	b1e080e7          	jalr	-1250(ra) # 80004610 <namei>
    80005afa:	84aa                	mv	s1,a0
    80005afc:	c551                	beqz	a0,80005b88 <sys_link+0xde>
  ilock(ip);
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	35c080e7          	jalr	860(ra) # 80003e5a <ilock>
  if(ip->type == T_DIR){
    80005b06:	04449703          	lh	a4,68(s1)
    80005b0a:	4785                	li	a5,1
    80005b0c:	08f70463          	beq	a4,a5,80005b94 <sys_link+0xea>
  ip->nlink++;
    80005b10:	04a4d783          	lhu	a5,74(s1)
    80005b14:	2785                	addiw	a5,a5,1
    80005b16:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	274080e7          	jalr	628(ra) # 80003d90 <iupdate>
  iunlock(ip);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	3f6080e7          	jalr	1014(ra) # 80003f1c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b2e:	fd040593          	addi	a1,s0,-48
    80005b32:	f5040513          	addi	a0,s0,-176
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	af8080e7          	jalr	-1288(ra) # 8000462e <nameiparent>
    80005b3e:	892a                	mv	s2,a0
    80005b40:	c935                	beqz	a0,80005bb4 <sys_link+0x10a>
  ilock(dp);
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	318080e7          	jalr	792(ra) # 80003e5a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b4a:	00092703          	lw	a4,0(s2)
    80005b4e:	409c                	lw	a5,0(s1)
    80005b50:	04f71d63          	bne	a4,a5,80005baa <sys_link+0x100>
    80005b54:	40d0                	lw	a2,4(s1)
    80005b56:	fd040593          	addi	a1,s0,-48
    80005b5a:	854a                	mv	a0,s2
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	9f2080e7          	jalr	-1550(ra) # 8000454e <dirlink>
    80005b64:	04054363          	bltz	a0,80005baa <sys_link+0x100>
  iunlockput(dp);
    80005b68:	854a                	mv	a0,s2
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	552080e7          	jalr	1362(ra) # 800040bc <iunlockput>
  iput(ip);
    80005b72:	8526                	mv	a0,s1
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	4a0080e7          	jalr	1184(ra) # 80004014 <iput>
  end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	d30080e7          	jalr	-720(ra) # 800048ac <end_op>
  return 0;
    80005b84:	4781                	li	a5,0
    80005b86:	a085                	j	80005be6 <sys_link+0x13c>
    end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	d24080e7          	jalr	-732(ra) # 800048ac <end_op>
    return -1;
    80005b90:	57fd                	li	a5,-1
    80005b92:	a891                	j	80005be6 <sys_link+0x13c>
    iunlockput(ip);
    80005b94:	8526                	mv	a0,s1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	526080e7          	jalr	1318(ra) # 800040bc <iunlockput>
    end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	d0e080e7          	jalr	-754(ra) # 800048ac <end_op>
    return -1;
    80005ba6:	57fd                	li	a5,-1
    80005ba8:	a83d                	j	80005be6 <sys_link+0x13c>
    iunlockput(dp);
    80005baa:	854a                	mv	a0,s2
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	510080e7          	jalr	1296(ra) # 800040bc <iunlockput>
  ilock(ip);
    80005bb4:	8526                	mv	a0,s1
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	2a4080e7          	jalr	676(ra) # 80003e5a <ilock>
  ip->nlink--;
    80005bbe:	04a4d783          	lhu	a5,74(s1)
    80005bc2:	37fd                	addiw	a5,a5,-1
    80005bc4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	1c6080e7          	jalr	454(ra) # 80003d90 <iupdate>
  iunlockput(ip);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	4e8080e7          	jalr	1256(ra) # 800040bc <iunlockput>
  end_op();
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	cd0080e7          	jalr	-816(ra) # 800048ac <end_op>
  return -1;
    80005be4:	57fd                	li	a5,-1
}
    80005be6:	853e                	mv	a0,a5
    80005be8:	70b2                	ld	ra,296(sp)
    80005bea:	7412                	ld	s0,288(sp)
    80005bec:	64f2                	ld	s1,280(sp)
    80005bee:	6952                	ld	s2,272(sp)
    80005bf0:	6155                	addi	sp,sp,304
    80005bf2:	8082                	ret

0000000080005bf4 <sys_unlink>:
{
    80005bf4:	7151                	addi	sp,sp,-240
    80005bf6:	f586                	sd	ra,232(sp)
    80005bf8:	f1a2                	sd	s0,224(sp)
    80005bfa:	eda6                	sd	s1,216(sp)
    80005bfc:	e9ca                	sd	s2,208(sp)
    80005bfe:	e5ce                	sd	s3,200(sp)
    80005c00:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c02:	08000613          	li	a2,128
    80005c06:	f3040593          	addi	a1,s0,-208
    80005c0a:	4501                	li	a0,0
    80005c0c:	ffffd097          	auipc	ra,0xffffd
    80005c10:	720080e7          	jalr	1824(ra) # 8000332c <argstr>
    80005c14:	18054163          	bltz	a0,80005d96 <sys_unlink+0x1a2>
  begin_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	c14080e7          	jalr	-1004(ra) # 8000482c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c20:	fb040593          	addi	a1,s0,-80
    80005c24:	f3040513          	addi	a0,s0,-208
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	a06080e7          	jalr	-1530(ra) # 8000462e <nameiparent>
    80005c30:	84aa                	mv	s1,a0
    80005c32:	c979                	beqz	a0,80005d08 <sys_unlink+0x114>
  ilock(dp);
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	226080e7          	jalr	550(ra) # 80003e5a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c3c:	00003597          	auipc	a1,0x3
    80005c40:	b6458593          	addi	a1,a1,-1180 # 800087a0 <syscalls+0x2b0>
    80005c44:	fb040513          	addi	a0,s0,-80
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	6dc080e7          	jalr	1756(ra) # 80004324 <namecmp>
    80005c50:	14050a63          	beqz	a0,80005da4 <sys_unlink+0x1b0>
    80005c54:	00003597          	auipc	a1,0x3
    80005c58:	b5458593          	addi	a1,a1,-1196 # 800087a8 <syscalls+0x2b8>
    80005c5c:	fb040513          	addi	a0,s0,-80
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	6c4080e7          	jalr	1732(ra) # 80004324 <namecmp>
    80005c68:	12050e63          	beqz	a0,80005da4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c6c:	f2c40613          	addi	a2,s0,-212
    80005c70:	fb040593          	addi	a1,s0,-80
    80005c74:	8526                	mv	a0,s1
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	6c8080e7          	jalr	1736(ra) # 8000433e <dirlookup>
    80005c7e:	892a                	mv	s2,a0
    80005c80:	12050263          	beqz	a0,80005da4 <sys_unlink+0x1b0>
  ilock(ip);
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	1d6080e7          	jalr	470(ra) # 80003e5a <ilock>
  if(ip->nlink < 1)
    80005c8c:	04a91783          	lh	a5,74(s2)
    80005c90:	08f05263          	blez	a5,80005d14 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c94:	04491703          	lh	a4,68(s2)
    80005c98:	4785                	li	a5,1
    80005c9a:	08f70563          	beq	a4,a5,80005d24 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c9e:	4641                	li	a2,16
    80005ca0:	4581                	li	a1,0
    80005ca2:	fc040513          	addi	a0,s0,-64
    80005ca6:	ffffb097          	auipc	ra,0xffffb
    80005caa:	03a080e7          	jalr	58(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cae:	4741                	li	a4,16
    80005cb0:	f2c42683          	lw	a3,-212(s0)
    80005cb4:	fc040613          	addi	a2,s0,-64
    80005cb8:	4581                	li	a1,0
    80005cba:	8526                	mv	a0,s1
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	54a080e7          	jalr	1354(ra) # 80004206 <writei>
    80005cc4:	47c1                	li	a5,16
    80005cc6:	0af51563          	bne	a0,a5,80005d70 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cca:	04491703          	lh	a4,68(s2)
    80005cce:	4785                	li	a5,1
    80005cd0:	0af70863          	beq	a4,a5,80005d80 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cd4:	8526                	mv	a0,s1
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	3e6080e7          	jalr	998(ra) # 800040bc <iunlockput>
  ip->nlink--;
    80005cde:	04a95783          	lhu	a5,74(s2)
    80005ce2:	37fd                	addiw	a5,a5,-1
    80005ce4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ce8:	854a                	mv	a0,s2
    80005cea:	ffffe097          	auipc	ra,0xffffe
    80005cee:	0a6080e7          	jalr	166(ra) # 80003d90 <iupdate>
  iunlockput(ip);
    80005cf2:	854a                	mv	a0,s2
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	3c8080e7          	jalr	968(ra) # 800040bc <iunlockput>
  end_op();
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	bb0080e7          	jalr	-1104(ra) # 800048ac <end_op>
  return 0;
    80005d04:	4501                	li	a0,0
    80005d06:	a84d                	j	80005db8 <sys_unlink+0x1c4>
    end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	ba4080e7          	jalr	-1116(ra) # 800048ac <end_op>
    return -1;
    80005d10:	557d                	li	a0,-1
    80005d12:	a05d                	j	80005db8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d14:	00003517          	auipc	a0,0x3
    80005d18:	abc50513          	addi	a0,a0,-1348 # 800087d0 <syscalls+0x2e0>
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	822080e7          	jalr	-2014(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d24:	04c92703          	lw	a4,76(s2)
    80005d28:	02000793          	li	a5,32
    80005d2c:	f6e7f9e3          	bgeu	a5,a4,80005c9e <sys_unlink+0xaa>
    80005d30:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d34:	4741                	li	a4,16
    80005d36:	86ce                	mv	a3,s3
    80005d38:	f1840613          	addi	a2,s0,-232
    80005d3c:	4581                	li	a1,0
    80005d3e:	854a                	mv	a0,s2
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	3ce080e7          	jalr	974(ra) # 8000410e <readi>
    80005d48:	47c1                	li	a5,16
    80005d4a:	00f51b63          	bne	a0,a5,80005d60 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d4e:	f1845783          	lhu	a5,-232(s0)
    80005d52:	e7a1                	bnez	a5,80005d9a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d54:	29c1                	addiw	s3,s3,16
    80005d56:	04c92783          	lw	a5,76(s2)
    80005d5a:	fcf9ede3          	bltu	s3,a5,80005d34 <sys_unlink+0x140>
    80005d5e:	b781                	j	80005c9e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d60:	00003517          	auipc	a0,0x3
    80005d64:	a8850513          	addi	a0,a0,-1400 # 800087e8 <syscalls+0x2f8>
    80005d68:	ffffa097          	auipc	ra,0xffffa
    80005d6c:	7d6080e7          	jalr	2006(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d70:	00003517          	auipc	a0,0x3
    80005d74:	a9050513          	addi	a0,a0,-1392 # 80008800 <syscalls+0x310>
    80005d78:	ffffa097          	auipc	ra,0xffffa
    80005d7c:	7c6080e7          	jalr	1990(ra) # 8000053e <panic>
    dp->nlink--;
    80005d80:	04a4d783          	lhu	a5,74(s1)
    80005d84:	37fd                	addiw	a5,a5,-1
    80005d86:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d8a:	8526                	mv	a0,s1
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	004080e7          	jalr	4(ra) # 80003d90 <iupdate>
    80005d94:	b781                	j	80005cd4 <sys_unlink+0xe0>
    return -1;
    80005d96:	557d                	li	a0,-1
    80005d98:	a005                	j	80005db8 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d9a:	854a                	mv	a0,s2
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	320080e7          	jalr	800(ra) # 800040bc <iunlockput>
  iunlockput(dp);
    80005da4:	8526                	mv	a0,s1
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	316080e7          	jalr	790(ra) # 800040bc <iunlockput>
  end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	afe080e7          	jalr	-1282(ra) # 800048ac <end_op>
  return -1;
    80005db6:	557d                	li	a0,-1
}
    80005db8:	70ae                	ld	ra,232(sp)
    80005dba:	740e                	ld	s0,224(sp)
    80005dbc:	64ee                	ld	s1,216(sp)
    80005dbe:	694e                	ld	s2,208(sp)
    80005dc0:	69ae                	ld	s3,200(sp)
    80005dc2:	616d                	addi	sp,sp,240
    80005dc4:	8082                	ret

0000000080005dc6 <sys_open>:

uint64
sys_open(void)
{
    80005dc6:	7131                	addi	sp,sp,-192
    80005dc8:	fd06                	sd	ra,184(sp)
    80005dca:	f922                	sd	s0,176(sp)
    80005dcc:	f526                	sd	s1,168(sp)
    80005dce:	f14a                	sd	s2,160(sp)
    80005dd0:	ed4e                	sd	s3,152(sp)
    80005dd2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dd4:	08000613          	li	a2,128
    80005dd8:	f5040593          	addi	a1,s0,-176
    80005ddc:	4501                	li	a0,0
    80005dde:	ffffd097          	auipc	ra,0xffffd
    80005de2:	54e080e7          	jalr	1358(ra) # 8000332c <argstr>
    return -1;
    80005de6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005de8:	0c054163          	bltz	a0,80005eaa <sys_open+0xe4>
    80005dec:	f4c40593          	addi	a1,s0,-180
    80005df0:	4505                	li	a0,1
    80005df2:	ffffd097          	auipc	ra,0xffffd
    80005df6:	4f6080e7          	jalr	1270(ra) # 800032e8 <argint>
    80005dfa:	0a054863          	bltz	a0,80005eaa <sys_open+0xe4>

  begin_op();
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	a2e080e7          	jalr	-1490(ra) # 8000482c <begin_op>

  if(omode & O_CREATE){
    80005e06:	f4c42783          	lw	a5,-180(s0)
    80005e0a:	2007f793          	andi	a5,a5,512
    80005e0e:	cbdd                	beqz	a5,80005ec4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e10:	4681                	li	a3,0
    80005e12:	4601                	li	a2,0
    80005e14:	4589                	li	a1,2
    80005e16:	f5040513          	addi	a0,s0,-176
    80005e1a:	00000097          	auipc	ra,0x0
    80005e1e:	972080e7          	jalr	-1678(ra) # 8000578c <create>
    80005e22:	892a                	mv	s2,a0
    if(ip == 0){
    80005e24:	c959                	beqz	a0,80005eba <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e26:	04491703          	lh	a4,68(s2)
    80005e2a:	478d                	li	a5,3
    80005e2c:	00f71763          	bne	a4,a5,80005e3a <sys_open+0x74>
    80005e30:	04695703          	lhu	a4,70(s2)
    80005e34:	47a5                	li	a5,9
    80005e36:	0ce7ec63          	bltu	a5,a4,80005f0e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	e02080e7          	jalr	-510(ra) # 80004c3c <filealloc>
    80005e42:	89aa                	mv	s3,a0
    80005e44:	10050263          	beqz	a0,80005f48 <sys_open+0x182>
    80005e48:	00000097          	auipc	ra,0x0
    80005e4c:	902080e7          	jalr	-1790(ra) # 8000574a <fdalloc>
    80005e50:	84aa                	mv	s1,a0
    80005e52:	0e054663          	bltz	a0,80005f3e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e56:	04491703          	lh	a4,68(s2)
    80005e5a:	478d                	li	a5,3
    80005e5c:	0cf70463          	beq	a4,a5,80005f24 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e60:	4789                	li	a5,2
    80005e62:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e66:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e6a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e6e:	f4c42783          	lw	a5,-180(s0)
    80005e72:	0017c713          	xori	a4,a5,1
    80005e76:	8b05                	andi	a4,a4,1
    80005e78:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e7c:	0037f713          	andi	a4,a5,3
    80005e80:	00e03733          	snez	a4,a4
    80005e84:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e88:	4007f793          	andi	a5,a5,1024
    80005e8c:	c791                	beqz	a5,80005e98 <sys_open+0xd2>
    80005e8e:	04491703          	lh	a4,68(s2)
    80005e92:	4789                	li	a5,2
    80005e94:	08f70f63          	beq	a4,a5,80005f32 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e98:	854a                	mv	a0,s2
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	082080e7          	jalr	130(ra) # 80003f1c <iunlock>
  end_op();
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	a0a080e7          	jalr	-1526(ra) # 800048ac <end_op>

  return fd;
}
    80005eaa:	8526                	mv	a0,s1
    80005eac:	70ea                	ld	ra,184(sp)
    80005eae:	744a                	ld	s0,176(sp)
    80005eb0:	74aa                	ld	s1,168(sp)
    80005eb2:	790a                	ld	s2,160(sp)
    80005eb4:	69ea                	ld	s3,152(sp)
    80005eb6:	6129                	addi	sp,sp,192
    80005eb8:	8082                	ret
      end_op();
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	9f2080e7          	jalr	-1550(ra) # 800048ac <end_op>
      return -1;
    80005ec2:	b7e5                	j	80005eaa <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ec4:	f5040513          	addi	a0,s0,-176
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	748080e7          	jalr	1864(ra) # 80004610 <namei>
    80005ed0:	892a                	mv	s2,a0
    80005ed2:	c905                	beqz	a0,80005f02 <sys_open+0x13c>
    ilock(ip);
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	f86080e7          	jalr	-122(ra) # 80003e5a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005edc:	04491703          	lh	a4,68(s2)
    80005ee0:	4785                	li	a5,1
    80005ee2:	f4f712e3          	bne	a4,a5,80005e26 <sys_open+0x60>
    80005ee6:	f4c42783          	lw	a5,-180(s0)
    80005eea:	dba1                	beqz	a5,80005e3a <sys_open+0x74>
      iunlockput(ip);
    80005eec:	854a                	mv	a0,s2
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	1ce080e7          	jalr	462(ra) # 800040bc <iunlockput>
      end_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	9b6080e7          	jalr	-1610(ra) # 800048ac <end_op>
      return -1;
    80005efe:	54fd                	li	s1,-1
    80005f00:	b76d                	j	80005eaa <sys_open+0xe4>
      end_op();
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	9aa080e7          	jalr	-1622(ra) # 800048ac <end_op>
      return -1;
    80005f0a:	54fd                	li	s1,-1
    80005f0c:	bf79                	j	80005eaa <sys_open+0xe4>
    iunlockput(ip);
    80005f0e:	854a                	mv	a0,s2
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	1ac080e7          	jalr	428(ra) # 800040bc <iunlockput>
    end_op();
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	994080e7          	jalr	-1644(ra) # 800048ac <end_op>
    return -1;
    80005f20:	54fd                	li	s1,-1
    80005f22:	b761                	j	80005eaa <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f24:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f28:	04691783          	lh	a5,70(s2)
    80005f2c:	02f99223          	sh	a5,36(s3)
    80005f30:	bf2d                	j	80005e6a <sys_open+0xa4>
    itrunc(ip);
    80005f32:	854a                	mv	a0,s2
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	034080e7          	jalr	52(ra) # 80003f68 <itrunc>
    80005f3c:	bfb1                	j	80005e98 <sys_open+0xd2>
      fileclose(f);
    80005f3e:	854e                	mv	a0,s3
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	db8080e7          	jalr	-584(ra) # 80004cf8 <fileclose>
    iunlockput(ip);
    80005f48:	854a                	mv	a0,s2
    80005f4a:	ffffe097          	auipc	ra,0xffffe
    80005f4e:	172080e7          	jalr	370(ra) # 800040bc <iunlockput>
    end_op();
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	95a080e7          	jalr	-1702(ra) # 800048ac <end_op>
    return -1;
    80005f5a:	54fd                	li	s1,-1
    80005f5c:	b7b9                	j	80005eaa <sys_open+0xe4>

0000000080005f5e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f5e:	7175                	addi	sp,sp,-144
    80005f60:	e506                	sd	ra,136(sp)
    80005f62:	e122                	sd	s0,128(sp)
    80005f64:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	8c6080e7          	jalr	-1850(ra) # 8000482c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f6e:	08000613          	li	a2,128
    80005f72:	f7040593          	addi	a1,s0,-144
    80005f76:	4501                	li	a0,0
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	3b4080e7          	jalr	948(ra) # 8000332c <argstr>
    80005f80:	02054963          	bltz	a0,80005fb2 <sys_mkdir+0x54>
    80005f84:	4681                	li	a3,0
    80005f86:	4601                	li	a2,0
    80005f88:	4585                	li	a1,1
    80005f8a:	f7040513          	addi	a0,s0,-144
    80005f8e:	fffff097          	auipc	ra,0xfffff
    80005f92:	7fe080e7          	jalr	2046(ra) # 8000578c <create>
    80005f96:	cd11                	beqz	a0,80005fb2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	124080e7          	jalr	292(ra) # 800040bc <iunlockput>
  end_op();
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	90c080e7          	jalr	-1780(ra) # 800048ac <end_op>
  return 0;
    80005fa8:	4501                	li	a0,0
}
    80005faa:	60aa                	ld	ra,136(sp)
    80005fac:	640a                	ld	s0,128(sp)
    80005fae:	6149                	addi	sp,sp,144
    80005fb0:	8082                	ret
    end_op();
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	8fa080e7          	jalr	-1798(ra) # 800048ac <end_op>
    return -1;
    80005fba:	557d                	li	a0,-1
    80005fbc:	b7fd                	j	80005faa <sys_mkdir+0x4c>

0000000080005fbe <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fbe:	7135                	addi	sp,sp,-160
    80005fc0:	ed06                	sd	ra,152(sp)
    80005fc2:	e922                	sd	s0,144(sp)
    80005fc4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	866080e7          	jalr	-1946(ra) # 8000482c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fce:	08000613          	li	a2,128
    80005fd2:	f7040593          	addi	a1,s0,-144
    80005fd6:	4501                	li	a0,0
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	354080e7          	jalr	852(ra) # 8000332c <argstr>
    80005fe0:	04054a63          	bltz	a0,80006034 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fe4:	f6c40593          	addi	a1,s0,-148
    80005fe8:	4505                	li	a0,1
    80005fea:	ffffd097          	auipc	ra,0xffffd
    80005fee:	2fe080e7          	jalr	766(ra) # 800032e8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ff2:	04054163          	bltz	a0,80006034 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ff6:	f6840593          	addi	a1,s0,-152
    80005ffa:	4509                	li	a0,2
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	2ec080e7          	jalr	748(ra) # 800032e8 <argint>
     argint(1, &major) < 0 ||
    80006004:	02054863          	bltz	a0,80006034 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006008:	f6841683          	lh	a3,-152(s0)
    8000600c:	f6c41603          	lh	a2,-148(s0)
    80006010:	458d                	li	a1,3
    80006012:	f7040513          	addi	a0,s0,-144
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	776080e7          	jalr	1910(ra) # 8000578c <create>
     argint(2, &minor) < 0 ||
    8000601e:	c919                	beqz	a0,80006034 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006020:	ffffe097          	auipc	ra,0xffffe
    80006024:	09c080e7          	jalr	156(ra) # 800040bc <iunlockput>
  end_op();
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	884080e7          	jalr	-1916(ra) # 800048ac <end_op>
  return 0;
    80006030:	4501                	li	a0,0
    80006032:	a031                	j	8000603e <sys_mknod+0x80>
    end_op();
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	878080e7          	jalr	-1928(ra) # 800048ac <end_op>
    return -1;
    8000603c:	557d                	li	a0,-1
}
    8000603e:	60ea                	ld	ra,152(sp)
    80006040:	644a                	ld	s0,144(sp)
    80006042:	610d                	addi	sp,sp,160
    80006044:	8082                	ret

0000000080006046 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006046:	7135                	addi	sp,sp,-160
    80006048:	ed06                	sd	ra,152(sp)
    8000604a:	e922                	sd	s0,144(sp)
    8000604c:	e526                	sd	s1,136(sp)
    8000604e:	e14a                	sd	s2,128(sp)
    80006050:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006052:	ffffc097          	auipc	ra,0xffffc
    80006056:	d84080e7          	jalr	-636(ra) # 80001dd6 <myproc>
    8000605a:	892a                	mv	s2,a0
  
  begin_op();
    8000605c:	ffffe097          	auipc	ra,0xffffe
    80006060:	7d0080e7          	jalr	2000(ra) # 8000482c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006064:	08000613          	li	a2,128
    80006068:	f6040593          	addi	a1,s0,-160
    8000606c:	4501                	li	a0,0
    8000606e:	ffffd097          	auipc	ra,0xffffd
    80006072:	2be080e7          	jalr	702(ra) # 8000332c <argstr>
    80006076:	04054b63          	bltz	a0,800060cc <sys_chdir+0x86>
    8000607a:	f6040513          	addi	a0,s0,-160
    8000607e:	ffffe097          	auipc	ra,0xffffe
    80006082:	592080e7          	jalr	1426(ra) # 80004610 <namei>
    80006086:	84aa                	mv	s1,a0
    80006088:	c131                	beqz	a0,800060cc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	dd0080e7          	jalr	-560(ra) # 80003e5a <ilock>
  if(ip->type != T_DIR){
    80006092:	04449703          	lh	a4,68(s1)
    80006096:	4785                	li	a5,1
    80006098:	04f71063          	bne	a4,a5,800060d8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000609c:	8526                	mv	a0,s1
    8000609e:	ffffe097          	auipc	ra,0xffffe
    800060a2:	e7e080e7          	jalr	-386(ra) # 80003f1c <iunlock>
  iput(p->cwd);
    800060a6:	17093503          	ld	a0,368(s2)
    800060aa:	ffffe097          	auipc	ra,0xffffe
    800060ae:	f6a080e7          	jalr	-150(ra) # 80004014 <iput>
  end_op();
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	7fa080e7          	jalr	2042(ra) # 800048ac <end_op>
  p->cwd = ip;
    800060ba:	16993823          	sd	s1,368(s2)
  return 0;
    800060be:	4501                	li	a0,0
}
    800060c0:	60ea                	ld	ra,152(sp)
    800060c2:	644a                	ld	s0,144(sp)
    800060c4:	64aa                	ld	s1,136(sp)
    800060c6:	690a                	ld	s2,128(sp)
    800060c8:	610d                	addi	sp,sp,160
    800060ca:	8082                	ret
    end_op();
    800060cc:	ffffe097          	auipc	ra,0xffffe
    800060d0:	7e0080e7          	jalr	2016(ra) # 800048ac <end_op>
    return -1;
    800060d4:	557d                	li	a0,-1
    800060d6:	b7ed                	j	800060c0 <sys_chdir+0x7a>
    iunlockput(ip);
    800060d8:	8526                	mv	a0,s1
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	fe2080e7          	jalr	-30(ra) # 800040bc <iunlockput>
    end_op();
    800060e2:	ffffe097          	auipc	ra,0xffffe
    800060e6:	7ca080e7          	jalr	1994(ra) # 800048ac <end_op>
    return -1;
    800060ea:	557d                	li	a0,-1
    800060ec:	bfd1                	j	800060c0 <sys_chdir+0x7a>

00000000800060ee <sys_exec>:

uint64
sys_exec(void)
{
    800060ee:	7145                	addi	sp,sp,-464
    800060f0:	e786                	sd	ra,456(sp)
    800060f2:	e3a2                	sd	s0,448(sp)
    800060f4:	ff26                	sd	s1,440(sp)
    800060f6:	fb4a                	sd	s2,432(sp)
    800060f8:	f74e                	sd	s3,424(sp)
    800060fa:	f352                	sd	s4,416(sp)
    800060fc:	ef56                	sd	s5,408(sp)
    800060fe:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006100:	08000613          	li	a2,128
    80006104:	f4040593          	addi	a1,s0,-192
    80006108:	4501                	li	a0,0
    8000610a:	ffffd097          	auipc	ra,0xffffd
    8000610e:	222080e7          	jalr	546(ra) # 8000332c <argstr>
    return -1;
    80006112:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006114:	0c054a63          	bltz	a0,800061e8 <sys_exec+0xfa>
    80006118:	e3840593          	addi	a1,s0,-456
    8000611c:	4505                	li	a0,1
    8000611e:	ffffd097          	auipc	ra,0xffffd
    80006122:	1ec080e7          	jalr	492(ra) # 8000330a <argaddr>
    80006126:	0c054163          	bltz	a0,800061e8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000612a:	10000613          	li	a2,256
    8000612e:	4581                	li	a1,0
    80006130:	e4040513          	addi	a0,s0,-448
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	bac080e7          	jalr	-1108(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000613c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006140:	89a6                	mv	s3,s1
    80006142:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006144:	02000a13          	li	s4,32
    80006148:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000614c:	00391513          	slli	a0,s2,0x3
    80006150:	e3040593          	addi	a1,s0,-464
    80006154:	e3843783          	ld	a5,-456(s0)
    80006158:	953e                	add	a0,a0,a5
    8000615a:	ffffd097          	auipc	ra,0xffffd
    8000615e:	0f4080e7          	jalr	244(ra) # 8000324e <fetchaddr>
    80006162:	02054a63          	bltz	a0,80006196 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006166:	e3043783          	ld	a5,-464(s0)
    8000616a:	c3b9                	beqz	a5,800061b0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000616c:	ffffb097          	auipc	ra,0xffffb
    80006170:	988080e7          	jalr	-1656(ra) # 80000af4 <kalloc>
    80006174:	85aa                	mv	a1,a0
    80006176:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000617a:	cd11                	beqz	a0,80006196 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000617c:	6605                	lui	a2,0x1
    8000617e:	e3043503          	ld	a0,-464(s0)
    80006182:	ffffd097          	auipc	ra,0xffffd
    80006186:	11e080e7          	jalr	286(ra) # 800032a0 <fetchstr>
    8000618a:	00054663          	bltz	a0,80006196 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000618e:	0905                	addi	s2,s2,1
    80006190:	09a1                	addi	s3,s3,8
    80006192:	fb491be3          	bne	s2,s4,80006148 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006196:	10048913          	addi	s2,s1,256
    8000619a:	6088                	ld	a0,0(s1)
    8000619c:	c529                	beqz	a0,800061e6 <sys_exec+0xf8>
    kfree(argv[i]);
    8000619e:	ffffb097          	auipc	ra,0xffffb
    800061a2:	85a080e7          	jalr	-1958(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061a6:	04a1                	addi	s1,s1,8
    800061a8:	ff2499e3          	bne	s1,s2,8000619a <sys_exec+0xac>
  return -1;
    800061ac:	597d                	li	s2,-1
    800061ae:	a82d                	j	800061e8 <sys_exec+0xfa>
      argv[i] = 0;
    800061b0:	0a8e                	slli	s5,s5,0x3
    800061b2:	fc040793          	addi	a5,s0,-64
    800061b6:	9abe                	add	s5,s5,a5
    800061b8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061bc:	e4040593          	addi	a1,s0,-448
    800061c0:	f4040513          	addi	a0,s0,-192
    800061c4:	fffff097          	auipc	ra,0xfffff
    800061c8:	194080e7          	jalr	404(ra) # 80005358 <exec>
    800061cc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061ce:	10048993          	addi	s3,s1,256
    800061d2:	6088                	ld	a0,0(s1)
    800061d4:	c911                	beqz	a0,800061e8 <sys_exec+0xfa>
    kfree(argv[i]);
    800061d6:	ffffb097          	auipc	ra,0xffffb
    800061da:	822080e7          	jalr	-2014(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061de:	04a1                	addi	s1,s1,8
    800061e0:	ff3499e3          	bne	s1,s3,800061d2 <sys_exec+0xe4>
    800061e4:	a011                	j	800061e8 <sys_exec+0xfa>
  return -1;
    800061e6:	597d                	li	s2,-1
}
    800061e8:	854a                	mv	a0,s2
    800061ea:	60be                	ld	ra,456(sp)
    800061ec:	641e                	ld	s0,448(sp)
    800061ee:	74fa                	ld	s1,440(sp)
    800061f0:	795a                	ld	s2,432(sp)
    800061f2:	79ba                	ld	s3,424(sp)
    800061f4:	7a1a                	ld	s4,416(sp)
    800061f6:	6afa                	ld	s5,408(sp)
    800061f8:	6179                	addi	sp,sp,464
    800061fa:	8082                	ret

00000000800061fc <sys_pipe>:

uint64
sys_pipe(void)
{
    800061fc:	7139                	addi	sp,sp,-64
    800061fe:	fc06                	sd	ra,56(sp)
    80006200:	f822                	sd	s0,48(sp)
    80006202:	f426                	sd	s1,40(sp)
    80006204:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	bd0080e7          	jalr	-1072(ra) # 80001dd6 <myproc>
    8000620e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006210:	fd840593          	addi	a1,s0,-40
    80006214:	4501                	li	a0,0
    80006216:	ffffd097          	auipc	ra,0xffffd
    8000621a:	0f4080e7          	jalr	244(ra) # 8000330a <argaddr>
    return -1;
    8000621e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006220:	0e054063          	bltz	a0,80006300 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006224:	fc840593          	addi	a1,s0,-56
    80006228:	fd040513          	addi	a0,s0,-48
    8000622c:	fffff097          	auipc	ra,0xfffff
    80006230:	dfc080e7          	jalr	-516(ra) # 80005028 <pipealloc>
    return -1;
    80006234:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006236:	0c054563          	bltz	a0,80006300 <sys_pipe+0x104>
  fd0 = -1;
    8000623a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000623e:	fd043503          	ld	a0,-48(s0)
    80006242:	fffff097          	auipc	ra,0xfffff
    80006246:	508080e7          	jalr	1288(ra) # 8000574a <fdalloc>
    8000624a:	fca42223          	sw	a0,-60(s0)
    8000624e:	08054c63          	bltz	a0,800062e6 <sys_pipe+0xea>
    80006252:	fc843503          	ld	a0,-56(s0)
    80006256:	fffff097          	auipc	ra,0xfffff
    8000625a:	4f4080e7          	jalr	1268(ra) # 8000574a <fdalloc>
    8000625e:	fca42023          	sw	a0,-64(s0)
    80006262:	06054863          	bltz	a0,800062d2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006266:	4691                	li	a3,4
    80006268:	fc440613          	addi	a2,s0,-60
    8000626c:	fd843583          	ld	a1,-40(s0)
    80006270:	78a8                	ld	a0,112(s1)
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	400080e7          	jalr	1024(ra) # 80001672 <copyout>
    8000627a:	02054063          	bltz	a0,8000629a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000627e:	4691                	li	a3,4
    80006280:	fc040613          	addi	a2,s0,-64
    80006284:	fd843583          	ld	a1,-40(s0)
    80006288:	0591                	addi	a1,a1,4
    8000628a:	78a8                	ld	a0,112(s1)
    8000628c:	ffffb097          	auipc	ra,0xffffb
    80006290:	3e6080e7          	jalr	998(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006294:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006296:	06055563          	bgez	a0,80006300 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000629a:	fc442783          	lw	a5,-60(s0)
    8000629e:	07f9                	addi	a5,a5,30
    800062a0:	078e                	slli	a5,a5,0x3
    800062a2:	97a6                	add	a5,a5,s1
    800062a4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062a8:	fc042503          	lw	a0,-64(s0)
    800062ac:	0579                	addi	a0,a0,30
    800062ae:	050e                	slli	a0,a0,0x3
    800062b0:	9526                	add	a0,a0,s1
    800062b2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062b6:	fd043503          	ld	a0,-48(s0)
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	a3e080e7          	jalr	-1474(ra) # 80004cf8 <fileclose>
    fileclose(wf);
    800062c2:	fc843503          	ld	a0,-56(s0)
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	a32080e7          	jalr	-1486(ra) # 80004cf8 <fileclose>
    return -1;
    800062ce:	57fd                	li	a5,-1
    800062d0:	a805                	j	80006300 <sys_pipe+0x104>
    if(fd0 >= 0)
    800062d2:	fc442783          	lw	a5,-60(s0)
    800062d6:	0007c863          	bltz	a5,800062e6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800062da:	01e78513          	addi	a0,a5,30
    800062de:	050e                	slli	a0,a0,0x3
    800062e0:	9526                	add	a0,a0,s1
    800062e2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062e6:	fd043503          	ld	a0,-48(s0)
    800062ea:	fffff097          	auipc	ra,0xfffff
    800062ee:	a0e080e7          	jalr	-1522(ra) # 80004cf8 <fileclose>
    fileclose(wf);
    800062f2:	fc843503          	ld	a0,-56(s0)
    800062f6:	fffff097          	auipc	ra,0xfffff
    800062fa:	a02080e7          	jalr	-1534(ra) # 80004cf8 <fileclose>
    return -1;
    800062fe:	57fd                	li	a5,-1
}
    80006300:	853e                	mv	a0,a5
    80006302:	70e2                	ld	ra,56(sp)
    80006304:	7442                	ld	s0,48(sp)
    80006306:	74a2                	ld	s1,40(sp)
    80006308:	6121                	addi	sp,sp,64
    8000630a:	8082                	ret
    8000630c:	0000                	unimp
	...

0000000080006310 <kernelvec>:
    80006310:	7111                	addi	sp,sp,-256
    80006312:	e006                	sd	ra,0(sp)
    80006314:	e40a                	sd	sp,8(sp)
    80006316:	e80e                	sd	gp,16(sp)
    80006318:	ec12                	sd	tp,24(sp)
    8000631a:	f016                	sd	t0,32(sp)
    8000631c:	f41a                	sd	t1,40(sp)
    8000631e:	f81e                	sd	t2,48(sp)
    80006320:	fc22                	sd	s0,56(sp)
    80006322:	e0a6                	sd	s1,64(sp)
    80006324:	e4aa                	sd	a0,72(sp)
    80006326:	e8ae                	sd	a1,80(sp)
    80006328:	ecb2                	sd	a2,88(sp)
    8000632a:	f0b6                	sd	a3,96(sp)
    8000632c:	f4ba                	sd	a4,104(sp)
    8000632e:	f8be                	sd	a5,112(sp)
    80006330:	fcc2                	sd	a6,120(sp)
    80006332:	e146                	sd	a7,128(sp)
    80006334:	e54a                	sd	s2,136(sp)
    80006336:	e94e                	sd	s3,144(sp)
    80006338:	ed52                	sd	s4,152(sp)
    8000633a:	f156                	sd	s5,160(sp)
    8000633c:	f55a                	sd	s6,168(sp)
    8000633e:	f95e                	sd	s7,176(sp)
    80006340:	fd62                	sd	s8,184(sp)
    80006342:	e1e6                	sd	s9,192(sp)
    80006344:	e5ea                	sd	s10,200(sp)
    80006346:	e9ee                	sd	s11,208(sp)
    80006348:	edf2                	sd	t3,216(sp)
    8000634a:	f1f6                	sd	t4,224(sp)
    8000634c:	f5fa                	sd	t5,232(sp)
    8000634e:	f9fe                	sd	t6,240(sp)
    80006350:	dcbfc0ef          	jal	ra,8000311a <kerneltrap>
    80006354:	6082                	ld	ra,0(sp)
    80006356:	6122                	ld	sp,8(sp)
    80006358:	61c2                	ld	gp,16(sp)
    8000635a:	7282                	ld	t0,32(sp)
    8000635c:	7322                	ld	t1,40(sp)
    8000635e:	73c2                	ld	t2,48(sp)
    80006360:	7462                	ld	s0,56(sp)
    80006362:	6486                	ld	s1,64(sp)
    80006364:	6526                	ld	a0,72(sp)
    80006366:	65c6                	ld	a1,80(sp)
    80006368:	6666                	ld	a2,88(sp)
    8000636a:	7686                	ld	a3,96(sp)
    8000636c:	7726                	ld	a4,104(sp)
    8000636e:	77c6                	ld	a5,112(sp)
    80006370:	7866                	ld	a6,120(sp)
    80006372:	688a                	ld	a7,128(sp)
    80006374:	692a                	ld	s2,136(sp)
    80006376:	69ca                	ld	s3,144(sp)
    80006378:	6a6a                	ld	s4,152(sp)
    8000637a:	7a8a                	ld	s5,160(sp)
    8000637c:	7b2a                	ld	s6,168(sp)
    8000637e:	7bca                	ld	s7,176(sp)
    80006380:	7c6a                	ld	s8,184(sp)
    80006382:	6c8e                	ld	s9,192(sp)
    80006384:	6d2e                	ld	s10,200(sp)
    80006386:	6dce                	ld	s11,208(sp)
    80006388:	6e6e                	ld	t3,216(sp)
    8000638a:	7e8e                	ld	t4,224(sp)
    8000638c:	7f2e                	ld	t5,232(sp)
    8000638e:	7fce                	ld	t6,240(sp)
    80006390:	6111                	addi	sp,sp,256
    80006392:	10200073          	sret
    80006396:	00000013          	nop
    8000639a:	00000013          	nop
    8000639e:	0001                	nop

00000000800063a0 <timervec>:
    800063a0:	34051573          	csrrw	a0,mscratch,a0
    800063a4:	e10c                	sd	a1,0(a0)
    800063a6:	e510                	sd	a2,8(a0)
    800063a8:	e914                	sd	a3,16(a0)
    800063aa:	6d0c                	ld	a1,24(a0)
    800063ac:	7110                	ld	a2,32(a0)
    800063ae:	6194                	ld	a3,0(a1)
    800063b0:	96b2                	add	a3,a3,a2
    800063b2:	e194                	sd	a3,0(a1)
    800063b4:	4589                	li	a1,2
    800063b6:	14459073          	csrw	sip,a1
    800063ba:	6914                	ld	a3,16(a0)
    800063bc:	6510                	ld	a2,8(a0)
    800063be:	610c                	ld	a1,0(a0)
    800063c0:	34051573          	csrrw	a0,mscratch,a0
    800063c4:	30200073          	mret
	...

00000000800063ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063ca:	1141                	addi	sp,sp,-16
    800063cc:	e422                	sd	s0,8(sp)
    800063ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063d0:	0c0007b7          	lui	a5,0xc000
    800063d4:	4705                	li	a4,1
    800063d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063d8:	c3d8                	sw	a4,4(a5)
}
    800063da:	6422                	ld	s0,8(sp)
    800063dc:	0141                	addi	sp,sp,16
    800063de:	8082                	ret

00000000800063e0 <plicinithart>:

void
plicinithart(void)
{
    800063e0:	1141                	addi	sp,sp,-16
    800063e2:	e406                	sd	ra,8(sp)
    800063e4:	e022                	sd	s0,0(sp)
    800063e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063e8:	ffffc097          	auipc	ra,0xffffc
    800063ec:	9c2080e7          	jalr	-1598(ra) # 80001daa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063f0:	0085171b          	slliw	a4,a0,0x8
    800063f4:	0c0027b7          	lui	a5,0xc002
    800063f8:	97ba                	add	a5,a5,a4
    800063fa:	40200713          	li	a4,1026
    800063fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006402:	00d5151b          	slliw	a0,a0,0xd
    80006406:	0c2017b7          	lui	a5,0xc201
    8000640a:	953e                	add	a0,a0,a5
    8000640c:	00052023          	sw	zero,0(a0)
}
    80006410:	60a2                	ld	ra,8(sp)
    80006412:	6402                	ld	s0,0(sp)
    80006414:	0141                	addi	sp,sp,16
    80006416:	8082                	ret

0000000080006418 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006418:	1141                	addi	sp,sp,-16
    8000641a:	e406                	sd	ra,8(sp)
    8000641c:	e022                	sd	s0,0(sp)
    8000641e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006420:	ffffc097          	auipc	ra,0xffffc
    80006424:	98a080e7          	jalr	-1654(ra) # 80001daa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006428:	00d5179b          	slliw	a5,a0,0xd
    8000642c:	0c201537          	lui	a0,0xc201
    80006430:	953e                	add	a0,a0,a5
  return irq;
}
    80006432:	4148                	lw	a0,4(a0)
    80006434:	60a2                	ld	ra,8(sp)
    80006436:	6402                	ld	s0,0(sp)
    80006438:	0141                	addi	sp,sp,16
    8000643a:	8082                	ret

000000008000643c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000643c:	1101                	addi	sp,sp,-32
    8000643e:	ec06                	sd	ra,24(sp)
    80006440:	e822                	sd	s0,16(sp)
    80006442:	e426                	sd	s1,8(sp)
    80006444:	1000                	addi	s0,sp,32
    80006446:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	962080e7          	jalr	-1694(ra) # 80001daa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006450:	00d5151b          	slliw	a0,a0,0xd
    80006454:	0c2017b7          	lui	a5,0xc201
    80006458:	97aa                	add	a5,a5,a0
    8000645a:	c3c4                	sw	s1,4(a5)
}
    8000645c:	60e2                	ld	ra,24(sp)
    8000645e:	6442                	ld	s0,16(sp)
    80006460:	64a2                	ld	s1,8(sp)
    80006462:	6105                	addi	sp,sp,32
    80006464:	8082                	ret

0000000080006466 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006466:	1141                	addi	sp,sp,-16
    80006468:	e406                	sd	ra,8(sp)
    8000646a:	e022                	sd	s0,0(sp)
    8000646c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000646e:	479d                	li	a5,7
    80006470:	06a7c963          	blt	a5,a0,800064e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006474:	0001d797          	auipc	a5,0x1d
    80006478:	b8c78793          	addi	a5,a5,-1140 # 80023000 <disk>
    8000647c:	00a78733          	add	a4,a5,a0
    80006480:	6789                	lui	a5,0x2
    80006482:	97ba                	add	a5,a5,a4
    80006484:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006488:	e7ad                	bnez	a5,800064f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000648a:	00451793          	slli	a5,a0,0x4
    8000648e:	0001f717          	auipc	a4,0x1f
    80006492:	b7270713          	addi	a4,a4,-1166 # 80025000 <disk+0x2000>
    80006496:	6314                	ld	a3,0(a4)
    80006498:	96be                	add	a3,a3,a5
    8000649a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000649e:	6314                	ld	a3,0(a4)
    800064a0:	96be                	add	a3,a3,a5
    800064a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800064a6:	6314                	ld	a3,0(a4)
    800064a8:	96be                	add	a3,a3,a5
    800064aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800064ae:	6318                	ld	a4,0(a4)
    800064b0:	97ba                	add	a5,a5,a4
    800064b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800064b6:	0001d797          	auipc	a5,0x1d
    800064ba:	b4a78793          	addi	a5,a5,-1206 # 80023000 <disk>
    800064be:	97aa                	add	a5,a5,a0
    800064c0:	6509                	lui	a0,0x2
    800064c2:	953e                	add	a0,a0,a5
    800064c4:	4785                	li	a5,1
    800064c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800064ca:	0001f517          	auipc	a0,0x1f
    800064ce:	b4e50513          	addi	a0,a0,-1202 # 80025018 <disk+0x2018>
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	3d6080e7          	jalr	982(ra) # 800028a8 <wakeup>
}
    800064da:	60a2                	ld	ra,8(sp)
    800064dc:	6402                	ld	s0,0(sp)
    800064de:	0141                	addi	sp,sp,16
    800064e0:	8082                	ret
    panic("free_desc 1");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	32e50513          	addi	a0,a0,814 # 80008810 <syscalls+0x320>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	054080e7          	jalr	84(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064f2:	00002517          	auipc	a0,0x2
    800064f6:	32e50513          	addi	a0,a0,814 # 80008820 <syscalls+0x330>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	044080e7          	jalr	68(ra) # 8000053e <panic>

0000000080006502 <virtio_disk_init>:
{
    80006502:	1101                	addi	sp,sp,-32
    80006504:	ec06                	sd	ra,24(sp)
    80006506:	e822                	sd	s0,16(sp)
    80006508:	e426                	sd	s1,8(sp)
    8000650a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000650c:	00002597          	auipc	a1,0x2
    80006510:	32458593          	addi	a1,a1,804 # 80008830 <syscalls+0x340>
    80006514:	0001f517          	auipc	a0,0x1f
    80006518:	c1450513          	addi	a0,a0,-1004 # 80025128 <disk+0x2128>
    8000651c:	ffffa097          	auipc	ra,0xffffa
    80006520:	638080e7          	jalr	1592(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006524:	100017b7          	lui	a5,0x10001
    80006528:	4398                	lw	a4,0(a5)
    8000652a:	2701                	sext.w	a4,a4
    8000652c:	747277b7          	lui	a5,0x74727
    80006530:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006534:	0ef71163          	bne	a4,a5,80006616 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006538:	100017b7          	lui	a5,0x10001
    8000653c:	43dc                	lw	a5,4(a5)
    8000653e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006540:	4705                	li	a4,1
    80006542:	0ce79a63          	bne	a5,a4,80006616 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006546:	100017b7          	lui	a5,0x10001
    8000654a:	479c                	lw	a5,8(a5)
    8000654c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000654e:	4709                	li	a4,2
    80006550:	0ce79363          	bne	a5,a4,80006616 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006554:	100017b7          	lui	a5,0x10001
    80006558:	47d8                	lw	a4,12(a5)
    8000655a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000655c:	554d47b7          	lui	a5,0x554d4
    80006560:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006564:	0af71963          	bne	a4,a5,80006616 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006568:	100017b7          	lui	a5,0x10001
    8000656c:	4705                	li	a4,1
    8000656e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006570:	470d                	li	a4,3
    80006572:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006574:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006576:	c7ffe737          	lui	a4,0xc7ffe
    8000657a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000657e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006580:	2701                	sext.w	a4,a4
    80006582:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006584:	472d                	li	a4,11
    80006586:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006588:	473d                	li	a4,15
    8000658a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000658c:	6705                	lui	a4,0x1
    8000658e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006590:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006594:	5bdc                	lw	a5,52(a5)
    80006596:	2781                	sext.w	a5,a5
  if(max == 0)
    80006598:	c7d9                	beqz	a5,80006626 <virtio_disk_init+0x124>
  if(max < NUM)
    8000659a:	471d                	li	a4,7
    8000659c:	08f77d63          	bgeu	a4,a5,80006636 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065a0:	100014b7          	lui	s1,0x10001
    800065a4:	47a1                	li	a5,8
    800065a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800065a8:	6609                	lui	a2,0x2
    800065aa:	4581                	li	a1,0
    800065ac:	0001d517          	auipc	a0,0x1d
    800065b0:	a5450513          	addi	a0,a0,-1452 # 80023000 <disk>
    800065b4:	ffffa097          	auipc	ra,0xffffa
    800065b8:	72c080e7          	jalr	1836(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800065bc:	0001d717          	auipc	a4,0x1d
    800065c0:	a4470713          	addi	a4,a4,-1468 # 80023000 <disk>
    800065c4:	00c75793          	srli	a5,a4,0xc
    800065c8:	2781                	sext.w	a5,a5
    800065ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800065cc:	0001f797          	auipc	a5,0x1f
    800065d0:	a3478793          	addi	a5,a5,-1484 # 80025000 <disk+0x2000>
    800065d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800065d6:	0001d717          	auipc	a4,0x1d
    800065da:	aaa70713          	addi	a4,a4,-1366 # 80023080 <disk+0x80>
    800065de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800065e0:	0001e717          	auipc	a4,0x1e
    800065e4:	a2070713          	addi	a4,a4,-1504 # 80024000 <disk+0x1000>
    800065e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065ea:	4705                	li	a4,1
    800065ec:	00e78c23          	sb	a4,24(a5)
    800065f0:	00e78ca3          	sb	a4,25(a5)
    800065f4:	00e78d23          	sb	a4,26(a5)
    800065f8:	00e78da3          	sb	a4,27(a5)
    800065fc:	00e78e23          	sb	a4,28(a5)
    80006600:	00e78ea3          	sb	a4,29(a5)
    80006604:	00e78f23          	sb	a4,30(a5)
    80006608:	00e78fa3          	sb	a4,31(a5)
}
    8000660c:	60e2                	ld	ra,24(sp)
    8000660e:	6442                	ld	s0,16(sp)
    80006610:	64a2                	ld	s1,8(sp)
    80006612:	6105                	addi	sp,sp,32
    80006614:	8082                	ret
    panic("could not find virtio disk");
    80006616:	00002517          	auipc	a0,0x2
    8000661a:	22a50513          	addi	a0,a0,554 # 80008840 <syscalls+0x350>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006626:	00002517          	auipc	a0,0x2
    8000662a:	23a50513          	addi	a0,a0,570 # 80008860 <syscalls+0x370>
    8000662e:	ffffa097          	auipc	ra,0xffffa
    80006632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006636:	00002517          	auipc	a0,0x2
    8000663a:	24a50513          	addi	a0,a0,586 # 80008880 <syscalls+0x390>
    8000663e:	ffffa097          	auipc	ra,0xffffa
    80006642:	f00080e7          	jalr	-256(ra) # 8000053e <panic>

0000000080006646 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006646:	7159                	addi	sp,sp,-112
    80006648:	f486                	sd	ra,104(sp)
    8000664a:	f0a2                	sd	s0,96(sp)
    8000664c:	eca6                	sd	s1,88(sp)
    8000664e:	e8ca                	sd	s2,80(sp)
    80006650:	e4ce                	sd	s3,72(sp)
    80006652:	e0d2                	sd	s4,64(sp)
    80006654:	fc56                	sd	s5,56(sp)
    80006656:	f85a                	sd	s6,48(sp)
    80006658:	f45e                	sd	s7,40(sp)
    8000665a:	f062                	sd	s8,32(sp)
    8000665c:	ec66                	sd	s9,24(sp)
    8000665e:	e86a                	sd	s10,16(sp)
    80006660:	1880                	addi	s0,sp,112
    80006662:	892a                	mv	s2,a0
    80006664:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006666:	00c52c83          	lw	s9,12(a0)
    8000666a:	001c9c9b          	slliw	s9,s9,0x1
    8000666e:	1c82                	slli	s9,s9,0x20
    80006670:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006674:	0001f517          	auipc	a0,0x1f
    80006678:	ab450513          	addi	a0,a0,-1356 # 80025128 <disk+0x2128>
    8000667c:	ffffa097          	auipc	ra,0xffffa
    80006680:	568080e7          	jalr	1384(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006684:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006686:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006688:	0001db97          	auipc	s7,0x1d
    8000668c:	978b8b93          	addi	s7,s7,-1672 # 80023000 <disk>
    80006690:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006692:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006694:	8a4e                	mv	s4,s3
    80006696:	a051                	j	8000671a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006698:	00fb86b3          	add	a3,s7,a5
    8000669c:	96da                	add	a3,a3,s6
    8000669e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800066a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800066a4:	0207c563          	bltz	a5,800066ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800066a8:	2485                	addiw	s1,s1,1
    800066aa:	0711                	addi	a4,a4,4
    800066ac:	25548063          	beq	s1,s5,800068ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800066b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800066b2:	0001f697          	auipc	a3,0x1f
    800066b6:	96668693          	addi	a3,a3,-1690 # 80025018 <disk+0x2018>
    800066ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800066bc:	0006c583          	lbu	a1,0(a3)
    800066c0:	fde1                	bnez	a1,80006698 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800066c2:	2785                	addiw	a5,a5,1
    800066c4:	0685                	addi	a3,a3,1
    800066c6:	ff879be3          	bne	a5,s8,800066bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800066ca:	57fd                	li	a5,-1
    800066cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800066ce:	02905a63          	blez	s1,80006702 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066d2:	f9042503          	lw	a0,-112(s0)
    800066d6:	00000097          	auipc	ra,0x0
    800066da:	d90080e7          	jalr	-624(ra) # 80006466 <free_desc>
      for(int j = 0; j < i; j++)
    800066de:	4785                	li	a5,1
    800066e0:	0297d163          	bge	a5,s1,80006702 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066e4:	f9442503          	lw	a0,-108(s0)
    800066e8:	00000097          	auipc	ra,0x0
    800066ec:	d7e080e7          	jalr	-642(ra) # 80006466 <free_desc>
      for(int j = 0; j < i; j++)
    800066f0:	4789                	li	a5,2
    800066f2:	0097d863          	bge	a5,s1,80006702 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066f6:	f9842503          	lw	a0,-104(s0)
    800066fa:	00000097          	auipc	ra,0x0
    800066fe:	d6c080e7          	jalr	-660(ra) # 80006466 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006702:	0001f597          	auipc	a1,0x1f
    80006706:	a2658593          	addi	a1,a1,-1498 # 80025128 <disk+0x2128>
    8000670a:	0001f517          	auipc	a0,0x1f
    8000670e:	90e50513          	addi	a0,a0,-1778 # 80025018 <disk+0x2018>
    80006712:	ffffc097          	auipc	ra,0xffffc
    80006716:	fcc080e7          	jalr	-52(ra) # 800026de <sleep>
  for(int i = 0; i < 3; i++){
    8000671a:	f9040713          	addi	a4,s0,-112
    8000671e:	84ce                	mv	s1,s3
    80006720:	bf41                	j	800066b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006722:	20058713          	addi	a4,a1,512
    80006726:	00471693          	slli	a3,a4,0x4
    8000672a:	0001d717          	auipc	a4,0x1d
    8000672e:	8d670713          	addi	a4,a4,-1834 # 80023000 <disk>
    80006732:	9736                	add	a4,a4,a3
    80006734:	4685                	li	a3,1
    80006736:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000673a:	20058713          	addi	a4,a1,512
    8000673e:	00471693          	slli	a3,a4,0x4
    80006742:	0001d717          	auipc	a4,0x1d
    80006746:	8be70713          	addi	a4,a4,-1858 # 80023000 <disk>
    8000674a:	9736                	add	a4,a4,a3
    8000674c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006750:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006754:	7679                	lui	a2,0xffffe
    80006756:	963e                	add	a2,a2,a5
    80006758:	0001f697          	auipc	a3,0x1f
    8000675c:	8a868693          	addi	a3,a3,-1880 # 80025000 <disk+0x2000>
    80006760:	6298                	ld	a4,0(a3)
    80006762:	9732                	add	a4,a4,a2
    80006764:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006766:	6298                	ld	a4,0(a3)
    80006768:	9732                	add	a4,a4,a2
    8000676a:	4541                	li	a0,16
    8000676c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000676e:	6298                	ld	a4,0(a3)
    80006770:	9732                	add	a4,a4,a2
    80006772:	4505                	li	a0,1
    80006774:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006778:	f9442703          	lw	a4,-108(s0)
    8000677c:	6288                	ld	a0,0(a3)
    8000677e:	962a                	add	a2,a2,a0
    80006780:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006784:	0712                	slli	a4,a4,0x4
    80006786:	6290                	ld	a2,0(a3)
    80006788:	963a                	add	a2,a2,a4
    8000678a:	05890513          	addi	a0,s2,88
    8000678e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006790:	6294                	ld	a3,0(a3)
    80006792:	96ba                	add	a3,a3,a4
    80006794:	40000613          	li	a2,1024
    80006798:	c690                	sw	a2,8(a3)
  if(write)
    8000679a:	140d0063          	beqz	s10,800068da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000679e:	0001f697          	auipc	a3,0x1f
    800067a2:	8626b683          	ld	a3,-1950(a3) # 80025000 <disk+0x2000>
    800067a6:	96ba                	add	a3,a3,a4
    800067a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067ac:	0001d817          	auipc	a6,0x1d
    800067b0:	85480813          	addi	a6,a6,-1964 # 80023000 <disk>
    800067b4:	0001f517          	auipc	a0,0x1f
    800067b8:	84c50513          	addi	a0,a0,-1972 # 80025000 <disk+0x2000>
    800067bc:	6114                	ld	a3,0(a0)
    800067be:	96ba                	add	a3,a3,a4
    800067c0:	00c6d603          	lhu	a2,12(a3)
    800067c4:	00166613          	ori	a2,a2,1
    800067c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067cc:	f9842683          	lw	a3,-104(s0)
    800067d0:	6110                	ld	a2,0(a0)
    800067d2:	9732                	add	a4,a4,a2
    800067d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067d8:	20058613          	addi	a2,a1,512
    800067dc:	0612                	slli	a2,a2,0x4
    800067de:	9642                	add	a2,a2,a6
    800067e0:	577d                	li	a4,-1
    800067e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067e6:	00469713          	slli	a4,a3,0x4
    800067ea:	6114                	ld	a3,0(a0)
    800067ec:	96ba                	add	a3,a3,a4
    800067ee:	03078793          	addi	a5,a5,48
    800067f2:	97c2                	add	a5,a5,a6
    800067f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067f6:	611c                	ld	a5,0(a0)
    800067f8:	97ba                	add	a5,a5,a4
    800067fa:	4685                	li	a3,1
    800067fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067fe:	611c                	ld	a5,0(a0)
    80006800:	97ba                	add	a5,a5,a4
    80006802:	4809                	li	a6,2
    80006804:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006808:	611c                	ld	a5,0(a0)
    8000680a:	973e                	add	a4,a4,a5
    8000680c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006810:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006814:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006818:	6518                	ld	a4,8(a0)
    8000681a:	00275783          	lhu	a5,2(a4)
    8000681e:	8b9d                	andi	a5,a5,7
    80006820:	0786                	slli	a5,a5,0x1
    80006822:	97ba                	add	a5,a5,a4
    80006824:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006828:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000682c:	6518                	ld	a4,8(a0)
    8000682e:	00275783          	lhu	a5,2(a4)
    80006832:	2785                	addiw	a5,a5,1
    80006834:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006838:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000683c:	100017b7          	lui	a5,0x10001
    80006840:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006844:	00492703          	lw	a4,4(s2)
    80006848:	4785                	li	a5,1
    8000684a:	02f71163          	bne	a4,a5,8000686c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000684e:	0001f997          	auipc	s3,0x1f
    80006852:	8da98993          	addi	s3,s3,-1830 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006856:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006858:	85ce                	mv	a1,s3
    8000685a:	854a                	mv	a0,s2
    8000685c:	ffffc097          	auipc	ra,0xffffc
    80006860:	e82080e7          	jalr	-382(ra) # 800026de <sleep>
  while(b->disk == 1) {
    80006864:	00492783          	lw	a5,4(s2)
    80006868:	fe9788e3          	beq	a5,s1,80006858 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000686c:	f9042903          	lw	s2,-112(s0)
    80006870:	20090793          	addi	a5,s2,512
    80006874:	00479713          	slli	a4,a5,0x4
    80006878:	0001c797          	auipc	a5,0x1c
    8000687c:	78878793          	addi	a5,a5,1928 # 80023000 <disk>
    80006880:	97ba                	add	a5,a5,a4
    80006882:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006886:	0001e997          	auipc	s3,0x1e
    8000688a:	77a98993          	addi	s3,s3,1914 # 80025000 <disk+0x2000>
    8000688e:	00491713          	slli	a4,s2,0x4
    80006892:	0009b783          	ld	a5,0(s3)
    80006896:	97ba                	add	a5,a5,a4
    80006898:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000689c:	854a                	mv	a0,s2
    8000689e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068a2:	00000097          	auipc	ra,0x0
    800068a6:	bc4080e7          	jalr	-1084(ra) # 80006466 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068aa:	8885                	andi	s1,s1,1
    800068ac:	f0ed                	bnez	s1,8000688e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068ae:	0001f517          	auipc	a0,0x1f
    800068b2:	87a50513          	addi	a0,a0,-1926 # 80025128 <disk+0x2128>
    800068b6:	ffffa097          	auipc	ra,0xffffa
    800068ba:	3e2080e7          	jalr	994(ra) # 80000c98 <release>
}
    800068be:	70a6                	ld	ra,104(sp)
    800068c0:	7406                	ld	s0,96(sp)
    800068c2:	64e6                	ld	s1,88(sp)
    800068c4:	6946                	ld	s2,80(sp)
    800068c6:	69a6                	ld	s3,72(sp)
    800068c8:	6a06                	ld	s4,64(sp)
    800068ca:	7ae2                	ld	s5,56(sp)
    800068cc:	7b42                	ld	s6,48(sp)
    800068ce:	7ba2                	ld	s7,40(sp)
    800068d0:	7c02                	ld	s8,32(sp)
    800068d2:	6ce2                	ld	s9,24(sp)
    800068d4:	6d42                	ld	s10,16(sp)
    800068d6:	6165                	addi	sp,sp,112
    800068d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068da:	0001e697          	auipc	a3,0x1e
    800068de:	7266b683          	ld	a3,1830(a3) # 80025000 <disk+0x2000>
    800068e2:	96ba                	add	a3,a3,a4
    800068e4:	4609                	li	a2,2
    800068e6:	00c69623          	sh	a2,12(a3)
    800068ea:	b5c9                	j	800067ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068ec:	f9042583          	lw	a1,-112(s0)
    800068f0:	20058793          	addi	a5,a1,512
    800068f4:	0792                	slli	a5,a5,0x4
    800068f6:	0001c517          	auipc	a0,0x1c
    800068fa:	7b250513          	addi	a0,a0,1970 # 800230a8 <disk+0xa8>
    800068fe:	953e                	add	a0,a0,a5
  if(write)
    80006900:	e20d11e3          	bnez	s10,80006722 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006904:	20058713          	addi	a4,a1,512
    80006908:	00471693          	slli	a3,a4,0x4
    8000690c:	0001c717          	auipc	a4,0x1c
    80006910:	6f470713          	addi	a4,a4,1780 # 80023000 <disk>
    80006914:	9736                	add	a4,a4,a3
    80006916:	0a072423          	sw	zero,168(a4)
    8000691a:	b505                	j	8000673a <virtio_disk_rw+0xf4>

000000008000691c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000691c:	1101                	addi	sp,sp,-32
    8000691e:	ec06                	sd	ra,24(sp)
    80006920:	e822                	sd	s0,16(sp)
    80006922:	e426                	sd	s1,8(sp)
    80006924:	e04a                	sd	s2,0(sp)
    80006926:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006928:	0001f517          	auipc	a0,0x1f
    8000692c:	80050513          	addi	a0,a0,-2048 # 80025128 <disk+0x2128>
    80006930:	ffffa097          	auipc	ra,0xffffa
    80006934:	2b4080e7          	jalr	692(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006938:	10001737          	lui	a4,0x10001
    8000693c:	533c                	lw	a5,96(a4)
    8000693e:	8b8d                	andi	a5,a5,3
    80006940:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006942:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006946:	0001e797          	auipc	a5,0x1e
    8000694a:	6ba78793          	addi	a5,a5,1722 # 80025000 <disk+0x2000>
    8000694e:	6b94                	ld	a3,16(a5)
    80006950:	0207d703          	lhu	a4,32(a5)
    80006954:	0026d783          	lhu	a5,2(a3)
    80006958:	06f70163          	beq	a4,a5,800069ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000695c:	0001c917          	auipc	s2,0x1c
    80006960:	6a490913          	addi	s2,s2,1700 # 80023000 <disk>
    80006964:	0001e497          	auipc	s1,0x1e
    80006968:	69c48493          	addi	s1,s1,1692 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000696c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006970:	6898                	ld	a4,16(s1)
    80006972:	0204d783          	lhu	a5,32(s1)
    80006976:	8b9d                	andi	a5,a5,7
    80006978:	078e                	slli	a5,a5,0x3
    8000697a:	97ba                	add	a5,a5,a4
    8000697c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000697e:	20078713          	addi	a4,a5,512
    80006982:	0712                	slli	a4,a4,0x4
    80006984:	974a                	add	a4,a4,s2
    80006986:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000698a:	e731                	bnez	a4,800069d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000698c:	20078793          	addi	a5,a5,512
    80006990:	0792                	slli	a5,a5,0x4
    80006992:	97ca                	add	a5,a5,s2
    80006994:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006996:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000699a:	ffffc097          	auipc	ra,0xffffc
    8000699e:	f0e080e7          	jalr	-242(ra) # 800028a8 <wakeup>

    disk.used_idx += 1;
    800069a2:	0204d783          	lhu	a5,32(s1)
    800069a6:	2785                	addiw	a5,a5,1
    800069a8:	17c2                	slli	a5,a5,0x30
    800069aa:	93c1                	srli	a5,a5,0x30
    800069ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069b0:	6898                	ld	a4,16(s1)
    800069b2:	00275703          	lhu	a4,2(a4)
    800069b6:	faf71be3          	bne	a4,a5,8000696c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800069ba:	0001e517          	auipc	a0,0x1e
    800069be:	76e50513          	addi	a0,a0,1902 # 80025128 <disk+0x2128>
    800069c2:	ffffa097          	auipc	ra,0xffffa
    800069c6:	2d6080e7          	jalr	726(ra) # 80000c98 <release>
}
    800069ca:	60e2                	ld	ra,24(sp)
    800069cc:	6442                	ld	s0,16(sp)
    800069ce:	64a2                	ld	s1,8(sp)
    800069d0:	6902                	ld	s2,0(sp)
    800069d2:	6105                	addi	sp,sp,32
    800069d4:	8082                	ret
      panic("virtio_disk_intr status");
    800069d6:	00002517          	auipc	a0,0x2
    800069da:	eca50513          	addi	a0,a0,-310 # 800088a0 <syscalls+0x3b0>
    800069de:	ffffa097          	auipc	ra,0xffffa
    800069e2:	b60080e7          	jalr	-1184(ra) # 8000053e <panic>

00000000800069e6 <cas>:
    800069e6:	100522af          	lr.w	t0,(a0)
    800069ea:	00b29563          	bne	t0,a1,800069f4 <fail>
    800069ee:	18c5252f          	sc.w	a0,a2,(a0)
    800069f2:	8082                	ret

00000000800069f4 <fail>:
    800069f4:	4505                	li	a0,1
    800069f6:	8082                	ret
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
