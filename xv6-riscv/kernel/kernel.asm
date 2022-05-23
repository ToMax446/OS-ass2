
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
    80000068:	54c78793          	addi	a5,a5,1356 # 800065b0 <timervec>
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
    80000130:	cc8080e7          	jalr	-824(ra) # 80002df4 <either_copyin>
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
    800001c8:	dee080e7          	jalr	-530(ra) # 80001fb2 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	6c4080e7          	jalr	1732(ra) # 80002898 <sleep>
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
    80000214:	b8e080e7          	jalr	-1138(ra) # 80002d9e <either_copyout>
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
    800002f6:	b58080e7          	jalr	-1192(ra) # 80002e4a <procdump>
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
    8000044a:	60a080e7          	jalr	1546(ra) # 80002a50 <wakeup>
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
    800008a4:	1b0080e7          	jalr	432(ra) # 80002a50 <wakeup>
    
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
    80000930:	f6c080e7          	jalr	-148(ra) # 80002898 <sleep>
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
    80000b82:	410080e7          	jalr	1040(ra) # 80001f8e <mycpu>
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
    80000bb4:	3de080e7          	jalr	990(ra) # 80001f8e <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	3d2080e7          	jalr	978(ra) # 80001f8e <mycpu>
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
    80000bd8:	3ba080e7          	jalr	954(ra) # 80001f8e <mycpu>
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
    80000c18:	37a080e7          	jalr	890(ra) # 80001f8e <mycpu>
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
    80000c56:	33c080e7          	jalr	828(ra) # 80001f8e <mycpu>
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
    80000ebe:	0c4080e7          	jalr	196(ra) # 80001f7e <cpuid>
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
    80000eda:	0a8080e7          	jalr	168(ra) # 80001f7e <cpuid>
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
    80000efc:	126080e7          	jalr	294(ra) # 8000301e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f00:	00005097          	auipc	ra,0x5
    80000f04:	6f0080e7          	jalr	1776(ra) # 800065f0 <plicinithart>
  }

  scheduler();        
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	6f0080e7          	jalr	1776(ra) # 800025f8 <scheduler>
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
    80000f6c:	ea6080e7          	jalr	-346(ra) # 80001e0e <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	086080e7          	jalr	134(ra) # 80002ff6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	0a6080e7          	jalr	166(ra) # 8000301e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	65a080e7          	jalr	1626(ra) # 800065da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	668080e7          	jalr	1640(ra) # 800065f0 <plicinithart>
    binit();         // buffer cache
    80000f90:	00003097          	auipc	ra,0x3
    80000f94:	84c080e7          	jalr	-1972(ra) # 800037dc <binit>
    iinit();         // inode table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	edc080e7          	jalr	-292(ra) # 80003e74 <iinit>
    fileinit();      // file table
    80000fa0:	00004097          	auipc	ra,0x4
    80000fa4:	e86080e7          	jalr	-378(ra) # 80004e26 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	76a080e7          	jalr	1898(ra) # 80006712 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	3a0080e7          	jalr	928(ra) # 80002350 <userinit>
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
    80001268:	b14080e7          	jalr	-1260(ra) # 80001d78 <proc_mapstacks>
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
    80001868:	00010717          	auipc	a4,0x10
    8000186c:	a3870713          	addi	a4,a4,-1480 # 800112a0 <cpus>
    80001870:	6350                	ld	a2,128(a4)
  int id = 0;
    80001872:	4781                	li	a5,0
  int idMin = 0;
    80001874:	4501                	li	a0,0
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    80001876:	45a1                	li	a1,8
    uint64 procsNum = c->admittedProcs;
    if (procsNum < min){
      min = procsNum;
      idMin = id;
    }     
    id++;
    80001878:	2785                	addiw	a5,a5,1
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    8000187a:	08870713          	addi	a4,a4,136
    8000187e:	00b78863          	beq	a5,a1,8000188e <leastUsedCPU+0x2c>
    uint64 procsNum = c->admittedProcs;
    80001882:	6354                	ld	a3,128(a4)
    if (procsNum < min){
    80001884:	fec6fae3          	bgeu	a3,a2,80001878 <leastUsedCPU+0x16>
    id++;
    80001888:	853e                	mv	a0,a5
    uint64 procsNum = c->admittedProcs;
    8000188a:	8636                	mv	a2,a3
    8000188c:	b7f5                	j	80001878 <leastUsedCPU+0x16>
  }
  return idMin;
}
    8000188e:	6422                	ld	s0,8(sp)
    80001890:	0141                	addi	sp,sp,16
    80001892:	8082                	ret

0000000080001894 <remove_from_list>:


int
remove_from_list(int to_remove, int* head, struct spinlock *lock){
    80001894:	7159                	addi	sp,sp,-112
    80001896:	f486                	sd	ra,104(sp)
    80001898:	f0a2                	sd	s0,96(sp)
    8000189a:	eca6                	sd	s1,88(sp)
    8000189c:	e8ca                	sd	s2,80(sp)
    8000189e:	e4ce                	sd	s3,72(sp)
    800018a0:	e0d2                	sd	s4,64(sp)
    800018a2:	fc56                	sd	s5,56(sp)
    800018a4:	f85a                	sd	s6,48(sp)
    800018a6:	f45e                	sd	s7,40(sp)
    800018a8:	f062                	sd	s8,32(sp)
    800018aa:	ec66                	sd	s9,24(sp)
    800018ac:	e86a                	sd	s10,16(sp)
    800018ae:	e46e                	sd	s11,8(sp)
    800018b0:	1880                	addi	s0,sp,112
    800018b2:	89aa                	mv	s3,a0
    800018b4:	892e                	mv	s2,a1
    800018b6:	84b2                	mv	s1,a2

  acquire(lock);
    800018b8:	8532                	mv	a0,a2
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	32a080e7          	jalr	810(ra) # 80000be4 <acquire>
  if(*head == -1){
    800018c2:	00092703          	lw	a4,0(s2) # 1000 <_entry-0x7ffff000>
    800018c6:	57fd                	li	a5,-1
    800018c8:	08f70263          	beq	a4,a5,8000194c <remove_from_list+0xb8>
    release(lock);
    return 0;
  }
  release(lock);
    800018cc:	8526                	mv	a0,s1
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	3dc080e7          	jalr	988(ra) # 80000caa <release>

  struct proc *p = 0;

  acquire(lock);
    800018d6:	8526                	mv	a0,s1
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	30c080e7          	jalr	780(ra) # 80000be4 <acquire>
  if(*head == to_remove){
    800018e0:	00092783          	lw	a5,0(s2)
    800018e4:	07378b63          	beq	a5,s3,8000195a <remove_from_list+0xc6>
    release(&p->linked_list_lock);

    release(lock);
    return 1;
  }
  release(lock);
    800018e8:	8526                	mv	a0,s1
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	3c0080e7          	jalr	960(ra) # 80000caa <release>
 
  int not_in_list = 0;
  struct proc *pred_proc = &proc[*head];
    800018f2:	00092503          	lw	a0,0(s2)
    800018f6:	18800493          	li	s1,392
    800018fa:	02950533          	mul	a0,a0,s1
    800018fe:	00010917          	auipc	s2,0x10
    80001902:	f7a90913          	addi	s2,s2,-134 # 80011878 <proc>
    80001906:	01250db3          	add	s11,a0,s2
  acquire(&pred_proc->linked_list_lock);
    8000190a:	04050513          	addi	a0,a0,64
    8000190e:	954a                	add	a0,a0,s2
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
  p = &proc[pred_proc->next];
    80001918:	03cda503          	lw	a0,60(s11)
    8000191c:	2501                	sext.w	a0,a0
    8000191e:	02950533          	mul	a0,a0,s1
    80001922:	012504b3          	add	s1,a0,s2
  acquire(&p->linked_list_lock);
    80001926:	04050513          	addi	a0,a0,64
    8000192a:	954a                	add	a0,a0,s2
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	2b8080e7          	jalr	696(ra) # 80000be4 <acquire>

  int stop = 0;
    80001934:	4901                	li	s2,0
  int not_in_list = 0;
    80001936:	4b81                	li	s7,0
  while(!stop){

    if (pred_proc->next == -1){
    80001938:	5afd                	li	s5,-1
      stop = 1;
    8000193a:	4d05                	li	s10,1
    8000193c:	8cea                	mv	s9,s10
    8000193e:	18800c13          	li	s8,392
    }
    release(&pred_proc->linked_list_lock);

    
    pred_proc = p;
    p = &proc[p->next];
    80001942:	00010a17          	auipc	s4,0x10
    80001946:	f36a0a13          	addi	s4,s4,-202 # 80011878 <proc>
  while(!stop){
    8000194a:	a8b5                	j	800019c6 <remove_from_list+0x132>
    release(lock);
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	35c080e7          	jalr	860(ra) # 80000caa <release>
    return 0;
    80001956:	4501                	li	a0,0
    80001958:	a845                	j	80001a08 <remove_from_list+0x174>
    acquire(&p->linked_list_lock);
    8000195a:	18800a93          	li	s5,392
    8000195e:	035989b3          	mul	s3,s3,s5
    80001962:	04098a13          	addi	s4,s3,64 # 1040 <_entry-0x7fffefc0>
    80001966:	00010a97          	auipc	s5,0x10
    8000196a:	f12a8a93          	addi	s5,s5,-238 # 80011878 <proc>
    8000196e:	9a56                	add	s4,s4,s5
    80001970:	8552                	mv	a0,s4
    80001972:	fffff097          	auipc	ra,0xfffff
    80001976:	272080e7          	jalr	626(ra) # 80000be4 <acquire>
    *head = p->next;
    8000197a:	9ace                	add	s5,s5,s3
    8000197c:	03caa783          	lw	a5,60(s5)
    80001980:	00f92023          	sw	a5,0(s2)
    release(&p->linked_list_lock);
    80001984:	8552                	mv	a0,s4
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	324080e7          	jalr	804(ra) # 80000caa <release>
    release(lock);
    8000198e:	8526                	mv	a0,s1
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	31a080e7          	jalr	794(ra) # 80000caa <release>
    return 1;
    80001998:	4505                	li	a0,1
    8000199a:	a0bd                	j	80001a08 <remove_from_list+0x174>
    release(&pred_proc->linked_list_lock);
    8000199c:	040d8513          	addi	a0,s11,64
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	30a080e7          	jalr	778(ra) # 80000caa <release>
    p = &proc[p->next];
    800019a8:	5cdc                	lw	a5,60(s1)
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	038787b3          	mul	a5,a5,s8
    800019b0:	01478b33          	add	s6,a5,s4
    acquire(&p->linked_list_lock);
    800019b4:	04078513          	addi	a0,a5,64
    800019b8:	9552                	add	a0,a0,s4
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	22a080e7          	jalr	554(ra) # 80000be4 <acquire>
    800019c2:	8da6                	mv	s11,s1
    p = &proc[p->next];
    800019c4:	84da                	mv	s1,s6
  while(!stop){
    800019c6:	02091363          	bnez	s2,800019ec <remove_from_list+0x158>
    if (pred_proc->next == -1){
    800019ca:	03cda783          	lw	a5,60(s11)
    800019ce:	2781                	sext.w	a5,a5
    800019d0:	01578b63          	beq	a5,s5,800019e6 <remove_from_list+0x152>
    if(p->index == to_remove){
    800019d4:	5c9c                	lw	a5,56(s1)
    800019d6:	fd3793e3          	bne	a5,s3,8000199c <remove_from_list+0x108>
      pred_proc->next = p->next;
    800019da:	5cdc                	lw	a5,60(s1)
    800019dc:	2781                	sext.w	a5,a5
    800019de:	02fdae23          	sw	a5,60(s11)
      stop = 1;
    800019e2:	896a                	mv	s2,s10
      continue;
    800019e4:	b7cd                	j	800019c6 <remove_from_list+0x132>
      stop = 1;
    800019e6:	8966                	mv	s2,s9
      not_in_list = 1;
    800019e8:	8be6                	mv	s7,s9
    800019ea:	bff1                	j	800019c6 <remove_from_list+0x132>
  }
  release(&pred_proc->linked_list_lock); // last one to release on the way out
    800019ec:	040d8513          	addi	a0,s11,64
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	2ba080e7          	jalr	698(ra) # 80000caa <release>
  release(&p->linked_list_lock); // last one to release on the way out
    800019f8:	04048513          	addi	a0,s1,64
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	2ae080e7          	jalr	686(ra) # 80000caa <release>
    return 0;
    80001a04:	001bc513          	xori	a0,s7,1
  if (not_in_list)
    return 0;
  return 1;
}
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

0000000080001a26 <remove_cs>:

int
remove_cs(struct proc *pred, struct proc *curr, struct proc *p){ //created
    80001a26:	715d                	addi	sp,sp,-80
    80001a28:	e486                	sd	ra,72(sp)
    80001a2a:	e0a2                	sd	s0,64(sp)
    80001a2c:	fc26                	sd	s1,56(sp)
    80001a2e:	f84a                	sd	s2,48(sp)
    80001a30:	f44e                	sd	s3,40(sp)
    80001a32:	f052                	sd	s4,32(sp)
    80001a34:	ec56                	sd	s5,24(sp)
    80001a36:	e85a                	sd	s6,16(sp)
    80001a38:	e45e                	sd	s7,8(sp)
    80001a3a:	0880                	addi	s0,sp,80
int ret = -1;
int curr_inx = curr->index;
    80001a3c:	0385a903          	lw	s2,56(a1) # 4000038 <_entry-0x7bffffc8>
while (curr_inx != -1) {
    80001a40:	57fd                	li	a5,-1
    80001a42:	08f90563          	beq	s2,a5,80001acc <remove_cs+0xa6>
    80001a46:	8baa                	mv	s7,a0
    80001a48:	84ae                	mv	s1,a1
    80001a4a:	8a32                	mv	s4,a2
      return ret;
    }
    release(&pred->linked_list_lock);
    pred = curr;
    curr_inx =curr->next;
    if(curr_inx!=-1){
    80001a4c:	5afd                	li	s5,-1
    80001a4e:	18800b13          	li	s6,392
      curr = &proc[curr->next];
    80001a52:	00010997          	auipc	s3,0x10
    80001a56:	e2698993          	addi	s3,s3,-474 # 80011878 <proc>
    80001a5a:	a099                	j	80001aa0 <remove_cs+0x7a>
      pred->next = curr->next;
    80001a5c:	5cdc                	lw	a5,60(s1)
    80001a5e:	2781                	sext.w	a5,a5
    80001a60:	02fbae23          	sw	a5,60(s7) # fffffffffffff03c <end+0xffffffff7ffd903c>
      ret = curr->index;
    80001a64:	0384a903          	lw	s2,56(s1)
      release(&curr->linked_list_lock);
    80001a68:	04048513          	addi	a0,s1,64
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	23e080e7          	jalr	574(ra) # 80000caa <release>
      release(&pred->linked_list_lock);
    80001a74:	040b8513          	addi	a0,s7,64
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	232080e7          	jalr	562(ra) # 80000caa <release>
      return ret;
    80001a80:	a0b1                	j	80001acc <remove_cs+0xa6>
      curr = &proc[curr->next];
    80001a82:	5cc8                	lw	a0,60(s1)
    80001a84:	2501                	sext.w	a0,a0
    80001a86:	03650533          	mul	a0,a0,s6
    80001a8a:	01350933          	add	s2,a0,s3
      acquire(&curr->linked_list_lock);
    80001a8e:	04050513          	addi	a0,a0,64
    80001a92:	954e                	add	a0,a0,s3
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	150080e7          	jalr	336(ra) # 80000be4 <acquire>
    80001a9c:	8ba6                	mv	s7,s1
      curr = &proc[curr->next];
    80001a9e:	84ca                	mv	s1,s2
  if ( p->index == curr->index) {
    80001aa0:	038a2703          	lw	a4,56(s4)
    80001aa4:	5c9c                	lw	a5,56(s1)
    80001aa6:	faf70be3          	beq	a4,a5,80001a5c <remove_cs+0x36>
    release(&pred->linked_list_lock);
    80001aaa:	040b8513          	addi	a0,s7,64
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	1fc080e7          	jalr	508(ra) # 80000caa <release>
    curr_inx =curr->next;
    80001ab6:	03c4a903          	lw	s2,60(s1)
    80001aba:	2901                	sext.w	s2,s2
    if(curr_inx!=-1){
    80001abc:	fd5913e3          	bne	s2,s5,80001a82 <remove_cs+0x5c>
    }
    else{
      release(&curr->linked_list_lock);
    80001ac0:	04048513          	addi	a0,s1,64
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	1e6080e7          	jalr	486(ra) # 80000caa <release>
    }
  }
  return -1;
}
    80001acc:	854a                	mv	a0,s2
    80001ace:	60a6                	ld	ra,72(sp)
    80001ad0:	6406                	ld	s0,64(sp)
    80001ad2:	74e2                	ld	s1,56(sp)
    80001ad4:	7942                	ld	s2,48(sp)
    80001ad6:	79a2                	ld	s3,40(sp)
    80001ad8:	7a02                	ld	s4,32(sp)
    80001ada:	6ae2                	ld	s5,24(sp)
    80001adc:	6b42                	ld	s6,16(sp)
    80001ade:	6ba2                	ld	s7,8(sp)
    80001ae0:	6161                	addi	sp,sp,80
    80001ae2:	8082                	ret

0000000080001ae4 <remove_from_list2>:

int remove_from_list2(int p_index, int *list, struct spinlock *lock_list){
    80001ae4:	7139                	addi	sp,sp,-64
    80001ae6:	fc06                	sd	ra,56(sp)
    80001ae8:	f822                	sd	s0,48(sp)
    80001aea:	f426                	sd	s1,40(sp)
    80001aec:	f04a                	sd	s2,32(sp)
    80001aee:	ec4e                	sd	s3,24(sp)
    80001af0:	e852                	sd	s4,16(sp)
    80001af2:	e456                	sd	s5,8(sp)
    80001af4:	e05a                	sd	s6,0(sp)
    80001af6:	0080                	addi	s0,sp,64
    80001af8:	84aa                	mv	s1,a0
    80001afa:	89ae                	mv	s3,a1
    80001afc:	8932                	mv	s2,a2
  int ret=-1;
  acquire(lock_list);
    80001afe:	8532                	mv	a0,a2
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	0e4080e7          	jalr	228(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001b08:	0009a783          	lw	a5,0(s3)
    80001b0c:	577d                	li	a4,-1
    80001b0e:	08e78c63          	beq	a5,a4,80001ba6 <remove_from_list2+0xc2>
    release(lock_list);
    panic("the remove from list faild.\n");
  }
  else{
        if(p_index == *list){
    80001b12:	0a978763          	beq	a5,s1,80001bc0 <remove_from_list2+0xdc>
          release(lock_list);
          ret=p_index;
          return ret;
        }
    else{
      release(lock_list);
    80001b16:	854a                	mv	a0,s2
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	192080e7          	jalr	402(ra) # 80000caa <release>
      struct proc *pred;
      struct proc *curr;
      pred = &proc[*list];
    80001b20:	0009a983          	lw	s3,0(s3)
    80001b24:	18800793          	li	a5,392
    80001b28:	02f987b3          	mul	a5,s3,a5
    80001b2c:	00010917          	auipc	s2,0x10
    80001b30:	d4c90913          	addi	s2,s2,-692 # 80011878 <proc>
    80001b34:	01278a33          	add	s4,a5,s2
      acquire(&pred->linked_list_lock);
    80001b38:	04078793          	addi	a5,a5,64
    80001b3c:	993e                	add	s2,s2,a5
    80001b3e:	854a                	mv	a0,s2
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	0a4080e7          	jalr	164(ra) # 80000be4 <acquire>
      if(pred->next==-1)
    80001b48:	03ca2783          	lw	a5,60(s4)
    80001b4c:	2781                	sext.w	a5,a5
    80001b4e:	577d                	li	a4,-1
    80001b50:	08e78b63          	beq	a5,a4,80001be6 <remove_from_list2+0x102>
      {
        release(&pred->linked_list_lock);
        panic("the item is not in the list\n");
      }
      curr = &proc[pred->next];
    80001b54:	00010a97          	auipc	s5,0x10
    80001b58:	d24a8a93          	addi	s5,s5,-732 # 80011878 <proc>
    80001b5c:	18800b13          	li	s6,392
    80001b60:	036989b3          	mul	s3,s3,s6
    80001b64:	99d6                	add	s3,s3,s5
    80001b66:	03c9a903          	lw	s2,60(s3)
    80001b6a:	2901                	sext.w	s2,s2
    80001b6c:	03690933          	mul	s2,s2,s6
      acquire(&curr->linked_list_lock);     
    80001b70:	04090513          	addi	a0,s2,64
    80001b74:	9556                	add	a0,a0,s5
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	06e080e7          	jalr	110(ra) # 80000be4 <acquire>
      ret = remove_cs(pred, curr, &proc[p_index]);
    80001b7e:	03648633          	mul	a2,s1,s6
    80001b82:	9656                	add	a2,a2,s5
    80001b84:	012a85b3          	add	a1,s5,s2
    80001b88:	8552                	mv	a0,s4
    80001b8a:	00000097          	auipc	ra,0x0
    80001b8e:	e9c080e7          	jalr	-356(ra) # 80001a26 <remove_cs>
    }
  }
  return ret;
}
    80001b92:	70e2                	ld	ra,56(sp)
    80001b94:	7442                	ld	s0,48(sp)
    80001b96:	74a2                	ld	s1,40(sp)
    80001b98:	7902                	ld	s2,32(sp)
    80001b9a:	69e2                	ld	s3,24(sp)
    80001b9c:	6a42                	ld	s4,16(sp)
    80001b9e:	6aa2                	ld	s5,8(sp)
    80001ba0:	6b02                	ld	s6,0(sp)
    80001ba2:	6121                	addi	sp,sp,64
    80001ba4:	8082                	ret
    release(lock_list);
    80001ba6:	854a                	mv	a0,s2
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	102080e7          	jalr	258(ra) # 80000caa <release>
    panic("the remove from list faild.\n");
    80001bb0:	00006517          	auipc	a0,0x6
    80001bb4:	65850513          	addi	a0,a0,1624 # 80008208 <digits+0x1c8>
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	986080e7          	jalr	-1658(ra) # 8000053e <panic>
          *list = proc[p_index].next;
    80001bc0:	18800793          	li	a5,392
    80001bc4:	02f48733          	mul	a4,s1,a5
    80001bc8:	00010797          	auipc	a5,0x10
    80001bcc:	cb078793          	addi	a5,a5,-848 # 80011878 <proc>
    80001bd0:	97ba                	add	a5,a5,a4
    80001bd2:	5fdc                	lw	a5,60(a5)
    80001bd4:	00f9a023          	sw	a5,0(s3)
          release(lock_list);
    80001bd8:	854a                	mv	a0,s2
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	0d0080e7          	jalr	208(ra) # 80000caa <release>
          return ret;
    80001be2:	8526                	mv	a0,s1
    80001be4:	b77d                	j	80001b92 <remove_from_list2+0xae>
        release(&pred->linked_list_lock);
    80001be6:	854a                	mv	a0,s2
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	0c2080e7          	jalr	194(ra) # 80000caa <release>
        panic("the item is not in the list\n");
    80001bf0:	00006517          	auipc	a0,0x6
    80001bf4:	63850513          	addi	a0,a0,1592 # 80008228 <digits+0x1e8>
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	946080e7          	jalr	-1722(ra) # 8000053e <panic>

0000000080001c00 <insert_cs>:

int
insert_cs(struct proc *pred, struct proc *p){  //created
    80001c00:	7139                	addi	sp,sp,-64
    80001c02:	fc06                	sd	ra,56(sp)
    80001c04:	f822                	sd	s0,48(sp)
    80001c06:	f426                	sd	s1,40(sp)
    80001c08:	f04a                	sd	s2,32(sp)
    80001c0a:	ec4e                	sd	s3,24(sp)
    80001c0c:	e852                	sd	s4,16(sp)
    80001c0e:	e456                	sd	s5,8(sp)
    80001c10:	e05a                	sd	s6,0(sp)
    80001c12:	0080                	addi	s0,sp,64
    80001c14:	892a                	mv	s2,a0
    80001c16:	8aae                	mv	s5,a1
  int curr = pred->index; 
  struct spinlock *pred_lock;
  while (curr != -1) {
    80001c18:	5d18                	lw	a4,56(a0)
    80001c1a:	57fd                	li	a5,-1
    80001c1c:	04f70a63          	beq	a4,a5,80001c70 <insert_cs+0x70>
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    if(pred->next!=-1){
    80001c20:	59fd                	li	s3,-1
    80001c22:	18800b13          	li	s6,392
      pred_lock=&pred->linked_list_lock; // caller acquired
      pred = &proc[pred->next];
    80001c26:	00010a17          	auipc	s4,0x10
    80001c2a:	c52a0a13          	addi	s4,s4,-942 # 80011878 <proc>
    80001c2e:	a81d                	j	80001c64 <insert_cs+0x64>
      pred_lock=&pred->linked_list_lock; // caller acquired
    80001c30:	04090513          	addi	a0,s2,64
      pred = &proc[pred->next];
    80001c34:	03c92483          	lw	s1,60(s2)
    80001c38:	2481                	sext.w	s1,s1
    80001c3a:	036484b3          	mul	s1,s1,s6
    80001c3e:	01448933          	add	s2,s1,s4
      release(pred_lock);
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	068080e7          	jalr	104(ra) # 80000caa <release>
      acquire(&pred->linked_list_lock);
    80001c4a:	04048493          	addi	s1,s1,64
    80001c4e:	009a0533          	add	a0,s4,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	f92080e7          	jalr	-110(ra) # 80000be4 <acquire>
    }
    curr = pred->next;
    80001c5a:	03c92783          	lw	a5,60(s2)
    80001c5e:	2781                	sext.w	a5,a5
  while (curr != -1) {
    80001c60:	01378863          	beq	a5,s3,80001c70 <insert_cs+0x70>
    if(pred->next!=-1){
    80001c64:	03c92783          	lw	a5,60(s2)
    80001c68:	2781                	sext.w	a5,a5
    80001c6a:	ff3788e3          	beq	a5,s3,80001c5a <insert_cs+0x5a>
    80001c6e:	b7c9                	j	80001c30 <insert_cs+0x30>
    }
    pred->next = p->index;
    80001c70:	038aa783          	lw	a5,56(s5)
    80001c74:	02f92e23          	sw	a5,60(s2)
    release(&pred->linked_list_lock);      
    80001c78:	04090513          	addi	a0,s2,64
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	02e080e7          	jalr	46(ra) # 80000caa <release>
    p->next=-1;
    80001c84:	57fd                	li	a5,-1
    80001c86:	02faae23          	sw	a5,60(s5)
    return p->index;
}
    80001c8a:	038aa503          	lw	a0,56(s5)
    80001c8e:	70e2                	ld	ra,56(sp)
    80001c90:	7442                	ld	s0,48(sp)
    80001c92:	74a2                	ld	s1,40(sp)
    80001c94:	7902                	ld	s2,32(sp)
    80001c96:	69e2                	ld	s3,24(sp)
    80001c98:	6a42                	ld	s4,16(sp)
    80001c9a:	6aa2                	ld	s5,8(sp)
    80001c9c:	6b02                	ld	s6,0(sp)
    80001c9e:	6121                	addi	sp,sp,64
    80001ca0:	8082                	ret

0000000080001ca2 <insert_to_list>:

int
insert_to_list(int p_index, int *list,struct spinlock *lock_list){;
    80001ca2:	7139                	addi	sp,sp,-64
    80001ca4:	fc06                	sd	ra,56(sp)
    80001ca6:	f822                	sd	s0,48(sp)
    80001ca8:	f426                	sd	s1,40(sp)
    80001caa:	f04a                	sd	s2,32(sp)
    80001cac:	ec4e                	sd	s3,24(sp)
    80001cae:	e852                	sd	s4,16(sp)
    80001cb0:	e456                	sd	s5,8(sp)
    80001cb2:	0080                	addi	s0,sp,64
    80001cb4:	84aa                	mv	s1,a0
    80001cb6:	892e                	mv	s2,a1
    80001cb8:	89b2                	mv	s3,a2
  int ret=-1;
  acquire(lock_list);
    80001cba:	8532                	mv	a0,a2
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	f28080e7          	jalr	-216(ra) # 80000be4 <acquire>
  if(*list==-1){
    80001cc4:	00092703          	lw	a4,0(s2)
    80001cc8:	57fd                	li	a5,-1
    80001cca:	04f70d63          	beq	a4,a5,80001d24 <insert_to_list+0x82>
    release(&proc[p_index].linked_list_lock);
    ret = p_index;
    release(lock_list);
  }
  else{
    release(lock_list);
    80001cce:	854e                	mv	a0,s3
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	fda080e7          	jalr	-38(ra) # 80000caa <release>
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    80001cd8:	00092903          	lw	s2,0(s2)
    80001cdc:	18800a13          	li	s4,392
    80001ce0:	03490933          	mul	s2,s2,s4
    acquire(&pred->linked_list_lock);
    80001ce4:	04090513          	addi	a0,s2,64
    80001ce8:	00010997          	auipc	s3,0x10
    80001cec:	b9098993          	addi	s3,s3,-1136 # 80011878 <proc>
    80001cf0:	954e                	add	a0,a0,s3
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	ef2080e7          	jalr	-270(ra) # 80000be4 <acquire>
    ret = insert_cs(pred, &proc[p_index]);
    80001cfa:	034485b3          	mul	a1,s1,s4
    80001cfe:	95ce                	add	a1,a1,s3
    80001d00:	01298533          	add	a0,s3,s2
    80001d04:	00000097          	auipc	ra,0x0
    80001d08:	efc080e7          	jalr	-260(ra) # 80001c00 <insert_cs>
  }
if(ret == -1){
    80001d0c:	57fd                	li	a5,-1
    80001d0e:	04f50d63          	beq	a0,a5,80001d68 <insert_to_list+0xc6>
  panic("insert is failed");
}
return ret;
}
    80001d12:	70e2                	ld	ra,56(sp)
    80001d14:	7442                	ld	s0,48(sp)
    80001d16:	74a2                	ld	s1,40(sp)
    80001d18:	7902                	ld	s2,32(sp)
    80001d1a:	69e2                	ld	s3,24(sp)
    80001d1c:	6a42                	ld	s4,16(sp)
    80001d1e:	6aa2                	ld	s5,8(sp)
    80001d20:	6121                	addi	sp,sp,64
    80001d22:	8082                	ret
    *list=p_index;
    80001d24:	00992023          	sw	s1,0(s2)
    acquire(&proc[p_index].linked_list_lock);
    80001d28:	18800a13          	li	s4,392
    80001d2c:	03448ab3          	mul	s5,s1,s4
    80001d30:	040a8913          	addi	s2,s5,64
    80001d34:	00010a17          	auipc	s4,0x10
    80001d38:	b44a0a13          	addi	s4,s4,-1212 # 80011878 <proc>
    80001d3c:	9952                	add	s2,s2,s4
    80001d3e:	854a                	mv	a0,s2
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	ea4080e7          	jalr	-348(ra) # 80000be4 <acquire>
    proc[p_index].next=-1;
    80001d48:	9a56                	add	s4,s4,s5
    80001d4a:	57fd                	li	a5,-1
    80001d4c:	02fa2e23          	sw	a5,60(s4)
    release(&proc[p_index].linked_list_lock);
    80001d50:	854a                	mv	a0,s2
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	f58080e7          	jalr	-168(ra) # 80000caa <release>
    release(lock_list);
    80001d5a:	854e                	mv	a0,s3
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	f4e080e7          	jalr	-178(ra) # 80000caa <release>
    ret = p_index;
    80001d64:	8526                	mv	a0,s1
    80001d66:	b75d                	j	80001d0c <insert_to_list+0x6a>
  panic("insert is failed");
    80001d68:	00006517          	auipc	a0,0x6
    80001d6c:	4e050513          	addi	a0,a0,1248 # 80008248 <digits+0x208>
    80001d70:	ffffe097          	auipc	ra,0xffffe
    80001d74:	7ce080e7          	jalr	1998(ra) # 8000053e <panic>

0000000080001d78 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001d78:	7139                	addi	sp,sp,-64
    80001d7a:	fc06                	sd	ra,56(sp)
    80001d7c:	f822                	sd	s0,48(sp)
    80001d7e:	f426                	sd	s1,40(sp)
    80001d80:	f04a                	sd	s2,32(sp)
    80001d82:	ec4e                	sd	s3,24(sp)
    80001d84:	e852                	sd	s4,16(sp)
    80001d86:	e456                	sd	s5,8(sp)
    80001d88:	e05a                	sd	s6,0(sp)
    80001d8a:	0080                	addi	s0,sp,64
    80001d8c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8e:	00010497          	auipc	s1,0x10
    80001d92:	aea48493          	addi	s1,s1,-1302 # 80011878 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001d96:	8b26                	mv	s6,s1
    80001d98:	00006a97          	auipc	s5,0x6
    80001d9c:	268a8a93          	addi	s5,s5,616 # 80008000 <etext>
    80001da0:	04000937          	lui	s2,0x4000
    80001da4:	197d                	addi	s2,s2,-1
    80001da6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001da8:	00016a17          	auipc	s4,0x16
    80001dac:	cd0a0a13          	addi	s4,s4,-816 # 80017a78 <tickslock>
    char *pa = kalloc();
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	d44080e7          	jalr	-700(ra) # 80000af4 <kalloc>
    80001db8:	862a                	mv	a2,a0
    if(pa == 0)
    80001dba:	c131                	beqz	a0,80001dfe <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001dbc:	416485b3          	sub	a1,s1,s6
    80001dc0:	858d                	srai	a1,a1,0x3
    80001dc2:	000ab783          	ld	a5,0(s5)
    80001dc6:	02f585b3          	mul	a1,a1,a5
    80001dca:	2585                	addiw	a1,a1,1
    80001dcc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001dd0:	4719                	li	a4,6
    80001dd2:	6685                	lui	a3,0x1
    80001dd4:	40b905b3          	sub	a1,s2,a1
    80001dd8:	854e                	mv	a0,s3
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	39a080e7          	jalr	922(ra) # 80001174 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de2:	18848493          	addi	s1,s1,392
    80001de6:	fd4495e3          	bne	s1,s4,80001db0 <proc_mapstacks+0x38>
  }
}
    80001dea:	70e2                	ld	ra,56(sp)
    80001dec:	7442                	ld	s0,48(sp)
    80001dee:	74a2                	ld	s1,40(sp)
    80001df0:	7902                	ld	s2,32(sp)
    80001df2:	69e2                	ld	s3,24(sp)
    80001df4:	6a42                	ld	s4,16(sp)
    80001df6:	6aa2                	ld	s5,8(sp)
    80001df8:	6b02                	ld	s6,0(sp)
    80001dfa:	6121                	addi	sp,sp,64
    80001dfc:	8082                	ret
      panic("kalloc");
    80001dfe:	00006517          	auipc	a0,0x6
    80001e02:	46250513          	addi	a0,a0,1122 # 80008260 <digits+0x220>
    80001e06:	ffffe097          	auipc	ra,0xffffe
    80001e0a:	738080e7          	jalr	1848(ra) # 8000053e <panic>

0000000080001e0e <procinit>:

// initialize the proc table at boot time.
void
procinit(void) //changed
{
    80001e0e:	711d                	addi	sp,sp,-96
    80001e10:	ec86                	sd	ra,88(sp)
    80001e12:	e8a2                	sd	s0,80(sp)
    80001e14:	e4a6                	sd	s1,72(sp)
    80001e16:	e0ca                	sd	s2,64(sp)
    80001e18:	fc4e                	sd	s3,56(sp)
    80001e1a:	f852                	sd	s4,48(sp)
    80001e1c:	f456                	sd	s5,40(sp)
    80001e1e:	f05a                	sd	s6,32(sp)
    80001e20:	ec5e                	sd	s7,24(sp)
    80001e22:	e862                	sd	s8,16(sp)
    80001e24:	e466                	sd	s9,8(sp)
    80001e26:	e06a                	sd	s10,0(sp)
    80001e28:	1080                	addi	s0,sp,96
  struct proc *p;

  for (int i = 0; i<CPUS; i++){
    80001e2a:	00010717          	auipc	a4,0x10
    80001e2e:	8b670713          	addi	a4,a4,-1866 # 800116e0 <cpus_ll>
    80001e32:	0000f797          	auipc	a5,0xf
    80001e36:	46e78793          	addi	a5,a5,1134 # 800112a0 <cpus>
    80001e3a:	863a                	mv	a2,a4
    cpus_ll[i] = -1;
    80001e3c:	56fd                	li	a3,-1
    80001e3e:	c314                	sw	a3,0(a4)
    // cpu_usage[i] = 0;    // set initial cpu's admitted to 0
    cpus[i].admittedProcs = 0;
    80001e40:	0807b023          	sd	zero,128(a5)
  for (int i = 0; i<CPUS; i++){
    80001e44:	0711                	addi	a4,a4,4
    80001e46:	08878793          	addi	a5,a5,136
    80001e4a:	fec79ae3          	bne	a5,a2,80001e3e <procinit+0x30>
}
  initlock(&pid_lock, "nextpid");
    80001e4e:	00006597          	auipc	a1,0x6
    80001e52:	41a58593          	addi	a1,a1,1050 # 80008268 <digits+0x228>
    80001e56:	00010517          	auipc	a0,0x10
    80001e5a:	8aa50513          	addi	a0,a0,-1878 # 80011700 <pid_lock>
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	cf6080e7          	jalr	-778(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001e66:	00006597          	auipc	a1,0x6
    80001e6a:	40a58593          	addi	a1,a1,1034 # 80008270 <digits+0x230>
    80001e6e:	00010517          	auipc	a0,0x10
    80001e72:	8aa50513          	addi	a0,a0,-1878 # 80011718 <wait_lock>
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	cde080e7          	jalr	-802(ra) # 80000b54 <initlock>
  initlock(&sleeping_head,"sleeping head");
    80001e7e:	00006597          	auipc	a1,0x6
    80001e82:	40258593          	addi	a1,a1,1026 # 80008280 <digits+0x240>
    80001e86:	00010517          	auipc	a0,0x10
    80001e8a:	8aa50513          	addi	a0,a0,-1878 # 80011730 <sleeping_head>
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	cc6080e7          	jalr	-826(ra) # 80000b54 <initlock>
  initlock(&zombie_head,"zombie head");
    80001e96:	00006597          	auipc	a1,0x6
    80001e9a:	3fa58593          	addi	a1,a1,1018 # 80008290 <digits+0x250>
    80001e9e:	00010517          	auipc	a0,0x10
    80001ea2:	8aa50513          	addi	a0,a0,-1878 # 80011748 <zombie_head>
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	cae080e7          	jalr	-850(ra) # 80000b54 <initlock>
  initlock(&unused_head,"unused head");
    80001eae:	00006597          	auipc	a1,0x6
    80001eb2:	3f258593          	addi	a1,a1,1010 # 800082a0 <digits+0x260>
    80001eb6:	00010517          	auipc	a0,0x10
    80001eba:	8aa50513          	addi	a0,a0,-1878 # 80011760 <unused_head>
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	c96080e7          	jalr	-874(ra) # 80000b54 <initlock>
  
  int i=0; //added
    80001ec6:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ec8:	00010497          	auipc	s1,0x10
    80001ecc:	9b048493          	addi	s1,s1,-1616 # 80011878 <proc>
      p->kstack = KSTACK((int) (p - proc));
    80001ed0:	8d26                	mv	s10,s1
    80001ed2:	00006c97          	auipc	s9,0x6
    80001ed6:	12ecbc83          	ld	s9,302(s9) # 80008000 <etext>
    80001eda:	040009b7          	lui	s3,0x4000
    80001ede:	19fd                	addi	s3,s3,-1
    80001ee0:	09b2                	slli	s3,s3,0xc
      //added:
      p->state = UNUSED; 
      p->index = i;
      p->next = -1;
    80001ee2:	5c7d                	li	s8,-1
      p->cpu_num = 0;
      initlock(&p->lock, "proc");
    80001ee4:	00006b97          	auipc	s7,0x6
    80001ee8:	3ccb8b93          	addi	s7,s7,972 # 800082b0 <digits+0x270>
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
    80001eec:	00006b17          	auipc	s6,0x6
    80001ef0:	3ccb0b13          	addi	s6,s6,972 # 800082b8 <digits+0x278>
      i++;
      insert_to_list(p->index, &unused, &unused_head);
    80001ef4:	00010a97          	auipc	s5,0x10
    80001ef8:	86ca8a93          	addi	s5,s5,-1940 # 80011760 <unused_head>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001efc:	00016a17          	auipc	s4,0x16
    80001f00:	b7ca0a13          	addi	s4,s4,-1156 # 80017a78 <tickslock>
      p->kstack = KSTACK((int) (p - proc));
    80001f04:	41a487b3          	sub	a5,s1,s10
    80001f08:	878d                	srai	a5,a5,0x3
    80001f0a:	039787b3          	mul	a5,a5,s9
    80001f0e:	2785                	addiw	a5,a5,1
    80001f10:	00d7979b          	slliw	a5,a5,0xd
    80001f14:	40f987b3          	sub	a5,s3,a5
    80001f18:	f0bc                	sd	a5,96(s1)
      p->state = UNUSED; 
    80001f1a:	0004ac23          	sw	zero,24(s1)
      p->index = i;
    80001f1e:	0324ac23          	sw	s2,56(s1)
      p->next = -1;
    80001f22:	0384ae23          	sw	s8,60(s1)
      p->cpu_num = 0;
    80001f26:	0204aa23          	sw	zero,52(s1)
      initlock(&p->lock, "proc");
    80001f2a:	85de                	mv	a1,s7
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	c26080e7          	jalr	-986(ra) # 80000b54 <initlock>
      initlock(&p->linked_list_lock, name);
    80001f36:	85da                	mv	a1,s6
    80001f38:	04048513          	addi	a0,s1,64
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	c18080e7          	jalr	-1000(ra) # 80000b54 <initlock>
      i++;
    80001f44:	2905                	addiw	s2,s2,1
      insert_to_list(p->index, &unused, &unused_head);
    80001f46:	8656                	mv	a2,s5
    80001f48:	00007597          	auipc	a1,0x7
    80001f4c:	9bc58593          	addi	a1,a1,-1604 # 80008904 <unused>
    80001f50:	5c88                	lw	a0,56(s1)
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	d50080e7          	jalr	-688(ra) # 80001ca2 <insert_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f5a:	18848493          	addi	s1,s1,392
    80001f5e:	fb4493e3          	bne	s1,s4,80001f04 <procinit+0xf6>
  
  
  //printf("the head of the unused list is %d, and the value of next is:%d\n ",unused,proc[unused].next);
      
  //printf("finished procinit\n");
}
    80001f62:	60e6                	ld	ra,88(sp)
    80001f64:	6446                	ld	s0,80(sp)
    80001f66:	64a6                	ld	s1,72(sp)
    80001f68:	6906                	ld	s2,64(sp)
    80001f6a:	79e2                	ld	s3,56(sp)
    80001f6c:	7a42                	ld	s4,48(sp)
    80001f6e:	7aa2                	ld	s5,40(sp)
    80001f70:	7b02                	ld	s6,32(sp)
    80001f72:	6be2                	ld	s7,24(sp)
    80001f74:	6c42                	ld	s8,16(sp)
    80001f76:	6ca2                	ld	s9,8(sp)
    80001f78:	6d02                	ld	s10,0(sp)
    80001f7a:	6125                	addi	sp,sp,96
    80001f7c:	8082                	ret

0000000080001f7e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001f7e:	1141                	addi	sp,sp,-16
    80001f80:	e422                	sd	s0,8(sp)
    80001f82:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f84:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001f86:	2501                	sext.w	a0,a0
    80001f88:	6422                	ld	s0,8(sp)
    80001f8a:	0141                	addi	sp,sp,16
    80001f8c:	8082                	ret

0000000080001f8e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
    80001f8e:	1141                	addi	sp,sp,-16
    80001f90:	e422                	sd	s0,8(sp)
    80001f92:	0800                	addi	s0,sp,16
    80001f94:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001f96:	0007851b          	sext.w	a0,a5
    80001f9a:	00451793          	slli	a5,a0,0x4
    80001f9e:	97aa                	add	a5,a5,a0
    80001fa0:	078e                	slli	a5,a5,0x3
  return c;
}
    80001fa2:	0000f517          	auipc	a0,0xf
    80001fa6:	2fe50513          	addi	a0,a0,766 # 800112a0 <cpus>
    80001faa:	953e                	add	a0,a0,a5
    80001fac:	6422                	ld	s0,8(sp)
    80001fae:	0141                	addi	sp,sp,16
    80001fb0:	8082                	ret

0000000080001fb2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001fb2:	1101                	addi	sp,sp,-32
    80001fb4:	ec06                	sd	ra,24(sp)
    80001fb6:	e822                	sd	s0,16(sp)
    80001fb8:	e426                	sd	s1,8(sp)
    80001fba:	1000                	addi	s0,sp,32
  push_off();
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	bdc080e7          	jalr	-1060(ra) # 80000b98 <push_off>
    80001fc4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001fc6:	0007871b          	sext.w	a4,a5
    80001fca:	00471793          	slli	a5,a4,0x4
    80001fce:	97ba                	add	a5,a5,a4
    80001fd0:	078e                	slli	a5,a5,0x3
    80001fd2:	0000f717          	auipc	a4,0xf
    80001fd6:	2ce70713          	addi	a4,a4,718 # 800112a0 <cpus>
    80001fda:	97ba                	add	a5,a5,a4
    80001fdc:	6384                	ld	s1,0(a5)
  pop_off();
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	c6c080e7          	jalr	-916(ra) # 80000c4a <pop_off>
  return p;
}
    80001fe6:	8526                	mv	a0,s1
    80001fe8:	60e2                	ld	ra,24(sp)
    80001fea:	6442                	ld	s0,16(sp)
    80001fec:	64a2                	ld	s1,8(sp)
    80001fee:	6105                	addi	sp,sp,32
    80001ff0:	8082                	ret

0000000080001ff2 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ff2:	1141                	addi	sp,sp,-16
    80001ff4:	e406                	sd	ra,8(sp)
    80001ff6:	e022                	sd	s0,0(sp)
    80001ff8:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	fb8080e7          	jalr	-72(ra) # 80001fb2 <myproc>
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	ca8080e7          	jalr	-856(ra) # 80000caa <release>


  if (first) {
    8000200a:	00007797          	auipc	a5,0x7
    8000200e:	8f67a783          	lw	a5,-1802(a5) # 80008900 <first.1767>
    80002012:	eb89                	bnez	a5,80002024 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80002014:	00001097          	auipc	ra,0x1
    80002018:	022080e7          	jalr	34(ra) # 80003036 <usertrapret>
}
    8000201c:	60a2                	ld	ra,8(sp)
    8000201e:	6402                	ld	s0,0(sp)
    80002020:	0141                	addi	sp,sp,16
    80002022:	8082                	ret
    first = 0;
    80002024:	00007797          	auipc	a5,0x7
    80002028:	8c07ae23          	sw	zero,-1828(a5) # 80008900 <first.1767>
    fsinit(ROOTDEV);
    8000202c:	4505                	li	a0,1
    8000202e:	00002097          	auipc	ra,0x2
    80002032:	dc6080e7          	jalr	-570(ra) # 80003df4 <fsinit>
    80002036:	bff9                	j	80002014 <forkret+0x22>

0000000080002038 <inc_cpu_usage>:
inc_cpu_usage(int cpu_num){
    80002038:	1101                	addi	sp,sp,-32
    8000203a:	ec06                	sd	ra,24(sp)
    8000203c:	e822                	sd	s0,16(sp)
    8000203e:	e426                	sd	s1,8(sp)
    80002040:	e04a                	sd	s2,0(sp)
    80002042:	1000                	addi	s0,sp,32
  } while (cas(&c->admittedProcs, usage, usage + 1));
    80002044:	00451493          	slli	s1,a0,0x4
    80002048:	94aa                	add	s1,s1,a0
    8000204a:	048e                	slli	s1,s1,0x3
    8000204c:	0000f797          	auipc	a5,0xf
    80002050:	2d478793          	addi	a5,a5,724 # 80011320 <cpus+0x80>
    80002054:	94be                	add	s1,s1,a5
    usage = c->admittedProcs;
    80002056:	00451913          	slli	s2,a0,0x4
    8000205a:	954a                	add	a0,a0,s2
    8000205c:	050e                	slli	a0,a0,0x3
    8000205e:	0000f917          	auipc	s2,0xf
    80002062:	24290913          	addi	s2,s2,578 # 800112a0 <cpus>
    80002066:	992a                	add	s2,s2,a0
    80002068:	08093583          	ld	a1,128(s2)
  } while (cas(&c->admittedProcs, usage, usage + 1));
    8000206c:	0015861b          	addiw	a2,a1,1
    80002070:	2581                	sext.w	a1,a1
    80002072:	8526                	mv	a0,s1
    80002074:	00005097          	auipc	ra,0x5
    80002078:	b82080e7          	jalr	-1150(ra) # 80006bf6 <cas>
    8000207c:	f575                	bnez	a0,80002068 <inc_cpu_usage+0x30>
}
    8000207e:	60e2                	ld	ra,24(sp)
    80002080:	6442                	ld	s0,16(sp)
    80002082:	64a2                	ld	s1,8(sp)
    80002084:	6902                	ld	s2,0(sp)
    80002086:	6105                	addi	sp,sp,32
    80002088:	8082                	ret

000000008000208a <allocpid>:
allocpid() { //changed as ordered in task 2
    8000208a:	1101                	addi	sp,sp,-32
    8000208c:	ec06                	sd	ra,24(sp)
    8000208e:	e822                	sd	s0,16(sp)
    80002090:	e426                	sd	s1,8(sp)
    80002092:	e04a                	sd	s2,0(sp)
    80002094:	1000                	addi	s0,sp,32
      pid = nextpid;
    80002096:	00007917          	auipc	s2,0x7
    8000209a:	87a90913          	addi	s2,s2,-1926 # 80008910 <nextpid>
    8000209e:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, pid+1));
    800020a2:	0014861b          	addiw	a2,s1,1
    800020a6:	85a6                	mv	a1,s1
    800020a8:	854a                	mv	a0,s2
    800020aa:	00005097          	auipc	ra,0x5
    800020ae:	b4c080e7          	jalr	-1204(ra) # 80006bf6 <cas>
    800020b2:	f575                	bnez	a0,8000209e <allocpid+0x14>
}
    800020b4:	8526                	mv	a0,s1
    800020b6:	60e2                	ld	ra,24(sp)
    800020b8:	6442                	ld	s0,16(sp)
    800020ba:	64a2                	ld	s1,8(sp)
    800020bc:	6902                	ld	s2,0(sp)
    800020be:	6105                	addi	sp,sp,32
    800020c0:	8082                	ret

00000000800020c2 <proc_pagetable>:
{
    800020c2:	1101                	addi	sp,sp,-32
    800020c4:	ec06                	sd	ra,24(sp)
    800020c6:	e822                	sd	s0,16(sp)
    800020c8:	e426                	sd	s1,8(sp)
    800020ca:	e04a                	sd	s2,0(sp)
    800020cc:	1000                	addi	s0,sp,32
    800020ce:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	28e080e7          	jalr	654(ra) # 8000135e <uvmcreate>
    800020d8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800020da:	c121                	beqz	a0,8000211a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800020dc:	4729                	li	a4,10
    800020de:	00005697          	auipc	a3,0x5
    800020e2:	f2268693          	addi	a3,a3,-222 # 80007000 <_trampoline>
    800020e6:	6605                	lui	a2,0x1
    800020e8:	040005b7          	lui	a1,0x4000
    800020ec:	15fd                	addi	a1,a1,-1
    800020ee:	05b2                	slli	a1,a1,0xc
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	fe4080e7          	jalr	-28(ra) # 800010d4 <mappages>
    800020f8:	02054863          	bltz	a0,80002128 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800020fc:	4719                	li	a4,6
    800020fe:	07893683          	ld	a3,120(s2)
    80002102:	6605                	lui	a2,0x1
    80002104:	020005b7          	lui	a1,0x2000
    80002108:	15fd                	addi	a1,a1,-1
    8000210a:	05b6                	slli	a1,a1,0xd
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	fc6080e7          	jalr	-58(ra) # 800010d4 <mappages>
    80002116:	02054163          	bltz	a0,80002138 <proc_pagetable+0x76>
}
    8000211a:	8526                	mv	a0,s1
    8000211c:	60e2                	ld	ra,24(sp)
    8000211e:	6442                	ld	s0,16(sp)
    80002120:	64a2                	ld	s1,8(sp)
    80002122:	6902                	ld	s2,0(sp)
    80002124:	6105                	addi	sp,sp,32
    80002126:	8082                	ret
    uvmfree(pagetable, 0);
    80002128:	4581                	li	a1,0
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	42e080e7          	jalr	1070(ra) # 8000155a <uvmfree>
    return 0;
    80002134:	4481                	li	s1,0
    80002136:	b7d5                	j	8000211a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002138:	4681                	li	a3,0
    8000213a:	4605                	li	a2,1
    8000213c:	040005b7          	lui	a1,0x4000
    80002140:	15fd                	addi	a1,a1,-1
    80002142:	05b2                	slli	a1,a1,0xc
    80002144:	8526                	mv	a0,s1
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	154080e7          	jalr	340(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    8000214e:	4581                	li	a1,0
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	408080e7          	jalr	1032(ra) # 8000155a <uvmfree>
    return 0;
    8000215a:	4481                	li	s1,0
    8000215c:	bf7d                	j	8000211a <proc_pagetable+0x58>

000000008000215e <proc_freepagetable>:
{
    8000215e:	1101                	addi	sp,sp,-32
    80002160:	ec06                	sd	ra,24(sp)
    80002162:	e822                	sd	s0,16(sp)
    80002164:	e426                	sd	s1,8(sp)
    80002166:	e04a                	sd	s2,0(sp)
    80002168:	1000                	addi	s0,sp,32
    8000216a:	84aa                	mv	s1,a0
    8000216c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000216e:	4681                	li	a3,0
    80002170:	4605                	li	a2,1
    80002172:	040005b7          	lui	a1,0x4000
    80002176:	15fd                	addi	a1,a1,-1
    80002178:	05b2                	slli	a1,a1,0xc
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	120080e7          	jalr	288(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002182:	4681                	li	a3,0
    80002184:	4605                	li	a2,1
    80002186:	020005b7          	lui	a1,0x2000
    8000218a:	15fd                	addi	a1,a1,-1
    8000218c:	05b6                	slli	a1,a1,0xd
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	10a080e7          	jalr	266(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80002198:	85ca                	mv	a1,s2
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	3be080e7          	jalr	958(ra) # 8000155a <uvmfree>
}
    800021a4:	60e2                	ld	ra,24(sp)
    800021a6:	6442                	ld	s0,16(sp)
    800021a8:	64a2                	ld	s1,8(sp)
    800021aa:	6902                	ld	s2,0(sp)
    800021ac:	6105                	addi	sp,sp,32
    800021ae:	8082                	ret

00000000800021b0 <freeproc>:
{
    800021b0:	1101                	addi	sp,sp,-32
    800021b2:	ec06                	sd	ra,24(sp)
    800021b4:	e822                	sd	s0,16(sp)
    800021b6:	e426                	sd	s1,8(sp)
    800021b8:	1000                	addi	s0,sp,32
    800021ba:	84aa                	mv	s1,a0
  if(p->trapframe)
    800021bc:	7d28                	ld	a0,120(a0)
    800021be:	c509                	beqz	a0,800021c8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	838080e7          	jalr	-1992(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    800021c8:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    800021cc:	78a8                	ld	a0,112(s1)
    800021ce:	c511                	beqz	a0,800021da <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800021d0:	74ac                	ld	a1,104(s1)
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	f8c080e7          	jalr	-116(ra) # 8000215e <proc_freepagetable>
  p->pagetable = 0;
    800021da:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    800021de:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    800021e2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800021e6:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    800021ea:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    800021ee:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800021f2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800021f6:	0204a623          	sw	zero,44(s1)
 remove_from_list(p->index, &zombie, &zombie_head);
    800021fa:	0000f617          	auipc	a2,0xf
    800021fe:	54e60613          	addi	a2,a2,1358 # 80011748 <zombie_head>
    80002202:	00006597          	auipc	a1,0x6
    80002206:	70658593          	addi	a1,a1,1798 # 80008908 <zombie>
    8000220a:	5c88                	lw	a0,56(s1)
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	688080e7          	jalr	1672(ra) # 80001894 <remove_from_list>
  p->state = UNUSED;
    80002214:	0004ac23          	sw	zero,24(s1)
  insert_to_list(p->index, &unused, &unused_head);
    80002218:	0000f617          	auipc	a2,0xf
    8000221c:	54860613          	addi	a2,a2,1352 # 80011760 <unused_head>
    80002220:	00006597          	auipc	a1,0x6
    80002224:	6e458593          	addi	a1,a1,1764 # 80008904 <unused>
    80002228:	5c88                	lw	a0,56(s1)
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	a78080e7          	jalr	-1416(ra) # 80001ca2 <insert_to_list>
}
    80002232:	60e2                	ld	ra,24(sp)
    80002234:	6442                	ld	s0,16(sp)
    80002236:	64a2                	ld	s1,8(sp)
    80002238:	6105                	addi	sp,sp,32
    8000223a:	8082                	ret

000000008000223c <allocproc>:
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	e052                	sd	s4,0(sp)
    8000224a:	1800                	addi	s0,sp,48
  if(unused != -1){
    8000224c:	00006917          	auipc	s2,0x6
    80002250:	6b892903          	lw	s2,1720(s2) # 80008904 <unused>
    80002254:	57fd                	li	a5,-1
  return 0;
    80002256:	4481                	li	s1,0
  if(unused != -1){
    80002258:	0af90b63          	beq	s2,a5,8000230e <allocproc+0xd2>
    p = &proc[unused];
    8000225c:	18800993          	li	s3,392
    80002260:	033909b3          	mul	s3,s2,s3
    80002264:	0000f497          	auipc	s1,0xf
    80002268:	61448493          	addi	s1,s1,1556 # 80011878 <proc>
    8000226c:	94ce                	add	s1,s1,s3
    remove_from_list(p->index,&unused, &unused_head);
    8000226e:	0000f617          	auipc	a2,0xf
    80002272:	4f260613          	addi	a2,a2,1266 # 80011760 <unused_head>
    80002276:	00006597          	auipc	a1,0x6
    8000227a:	68e58593          	addi	a1,a1,1678 # 80008904 <unused>
    8000227e:	5c88                	lw	a0,56(s1)
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	614080e7          	jalr	1556(ra) # 80001894 <remove_from_list>
    acquire(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	95a080e7          	jalr	-1702(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80002292:	00000097          	auipc	ra,0x0
    80002296:	df8080e7          	jalr	-520(ra) # 8000208a <allocpid>
    8000229a:	d888                	sw	a0,48(s1)
  p->state = USED;
    8000229c:	4785                	li	a5,1
    8000229e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	854080e7          	jalr	-1964(ra) # 80000af4 <kalloc>
    800022a8:	8a2a                	mv	s4,a0
    800022aa:	fca8                	sd	a0,120(s1)
    800022ac:	c935                	beqz	a0,80002320 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    800022ae:	8526                	mv	a0,s1
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	e12080e7          	jalr	-494(ra) # 800020c2 <proc_pagetable>
    800022b8:	8a2a                	mv	s4,a0
    800022ba:	18800793          	li	a5,392
    800022be:	02f90733          	mul	a4,s2,a5
    800022c2:	0000f797          	auipc	a5,0xf
    800022c6:	5b678793          	addi	a5,a5,1462 # 80011878 <proc>
    800022ca:	97ba                	add	a5,a5,a4
    800022cc:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800022ce:	c52d                	beqz	a0,80002338 <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    800022d0:	08098513          	addi	a0,s3,128 # 4000080 <_entry-0x7bffff80>
    800022d4:	0000fa17          	auipc	s4,0xf
    800022d8:	5a4a0a13          	addi	s4,s4,1444 # 80011878 <proc>
    800022dc:	07000613          	li	a2,112
    800022e0:	4581                	li	a1,0
    800022e2:	9552                	add	a0,a0,s4
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a20080e7          	jalr	-1504(ra) # 80000d04 <memset>
  p->context.ra = (uint64)forkret;
    800022ec:	18800793          	li	a5,392
    800022f0:	02f90933          	mul	s2,s2,a5
    800022f4:	9952                	add	s2,s2,s4
    800022f6:	00000797          	auipc	a5,0x0
    800022fa:	cfc78793          	addi	a5,a5,-772 # 80001ff2 <forkret>
    800022fe:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002302:	06093783          	ld	a5,96(s2)
    80002306:	6705                	lui	a4,0x1
    80002308:	97ba                	add	a5,a5,a4
    8000230a:	08f93423          	sd	a5,136(s2)
}
    8000230e:	8526                	mv	a0,s1
    80002310:	70a2                	ld	ra,40(sp)
    80002312:	7402                	ld	s0,32(sp)
    80002314:	64e2                	ld	s1,24(sp)
    80002316:	6942                	ld	s2,16(sp)
    80002318:	69a2                	ld	s3,8(sp)
    8000231a:	6a02                	ld	s4,0(sp)
    8000231c:	6145                	addi	sp,sp,48
    8000231e:	8082                	ret
    freeproc(p);
    80002320:	8526                	mv	a0,s1
    80002322:	00000097          	auipc	ra,0x0
    80002326:	e8e080e7          	jalr	-370(ra) # 800021b0 <freeproc>
    release(&p->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	97e080e7          	jalr	-1666(ra) # 80000caa <release>
    return 0;
    80002334:	84d2                	mv	s1,s4
    80002336:	bfe1                	j	8000230e <allocproc+0xd2>
    freeproc(p);
    80002338:	8526                	mv	a0,s1
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	e76080e7          	jalr	-394(ra) # 800021b0 <freeproc>
    release(&p->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	966080e7          	jalr	-1690(ra) # 80000caa <release>
    return 0;
    8000234c:	84d2                	mv	s1,s4
    8000234e:	b7c1                	j	8000230e <allocproc+0xd2>

0000000080002350 <userinit>:
{
    80002350:	1101                	addi	sp,sp,-32
    80002352:	ec06                	sd	ra,24(sp)
    80002354:	e822                	sd	s0,16(sp)
    80002356:	e426                	sd	s1,8(sp)
    80002358:	1000                	addi	s0,sp,32
  p = allocproc();
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	ee2080e7          	jalr	-286(ra) # 8000223c <allocproc>
    80002362:	84aa                	mv	s1,a0
  initproc = p;
    80002364:	00007797          	auipc	a5,0x7
    80002368:	cca7b223          	sd	a0,-828(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000236c:	03400613          	li	a2,52
    80002370:	00006597          	auipc	a1,0x6
    80002374:	5b058593          	addi	a1,a1,1456 # 80008920 <initcode>
    80002378:	7928                	ld	a0,112(a0)
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	012080e7          	jalr	18(ra) # 8000138c <uvminit>
  p->sz = PGSIZE;
    80002382:	6785                	lui	a5,0x1
    80002384:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80002386:	7cb8                	ld	a4,120(s1)
    80002388:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000238c:	7cb8                	ld	a4,120(s1)
    8000238e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002390:	4641                	li	a2,16
    80002392:	00006597          	auipc	a1,0x6
    80002396:	f2e58593          	addi	a1,a1,-210 # 800082c0 <digits+0x280>
    8000239a:	17848513          	addi	a0,s1,376
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	ab8080e7          	jalr	-1352(ra) # 80000e56 <safestrcpy>
  p->cwd = namei("/");
    800023a6:	00006517          	auipc	a0,0x6
    800023aa:	f2a50513          	addi	a0,a0,-214 # 800082d0 <digits+0x290>
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	474080e7          	jalr	1140(ra) # 80004822 <namei>
    800023b6:	16a4b823          	sd	a0,368(s1)
  insert_to_list(p->index, &cpus_ll[0], &cpus_head[0]);
    800023ba:	0000f617          	auipc	a2,0xf
    800023be:	3be60613          	addi	a2,a2,958 # 80011778 <cpus_head>
    800023c2:	0000f597          	auipc	a1,0xf
    800023c6:	31e58593          	addi	a1,a1,798 # 800116e0 <cpus_ll>
    800023ca:	5c88                	lw	a0,56(s1)
    800023cc:	00000097          	auipc	ra,0x0
    800023d0:	8d6080e7          	jalr	-1834(ra) # 80001ca2 <insert_to_list>
  inc_cpu_usage(0);
    800023d4:	4501                	li	a0,0
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	c62080e7          	jalr	-926(ra) # 80002038 <inc_cpu_usage>
  p->state = RUNNABLE;
    800023de:	478d                	li	a5,3
    800023e0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8c6080e7          	jalr	-1850(ra) # 80000caa <release>
}
    800023ec:	60e2                	ld	ra,24(sp)
    800023ee:	6442                	ld	s0,16(sp)
    800023f0:	64a2                	ld	s1,8(sp)
    800023f2:	6105                	addi	sp,sp,32
    800023f4:	8082                	ret

00000000800023f6 <growproc>:
{
    800023f6:	1101                	addi	sp,sp,-32
    800023f8:	ec06                	sd	ra,24(sp)
    800023fa:	e822                	sd	s0,16(sp)
    800023fc:	e426                	sd	s1,8(sp)
    800023fe:	e04a                	sd	s2,0(sp)
    80002400:	1000                	addi	s0,sp,32
    80002402:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002404:	00000097          	auipc	ra,0x0
    80002408:	bae080e7          	jalr	-1106(ra) # 80001fb2 <myproc>
    8000240c:	892a                	mv	s2,a0
  sz = p->sz;
    8000240e:	752c                	ld	a1,104(a0)
    80002410:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002414:	00904f63          	bgtz	s1,80002432 <growproc+0x3c>
  } else if(n < 0){
    80002418:	0204cc63          	bltz	s1,80002450 <growproc+0x5a>
  p->sz = sz;
    8000241c:	1602                	slli	a2,a2,0x20
    8000241e:	9201                	srli	a2,a2,0x20
    80002420:	06c93423          	sd	a2,104(s2)
  return 0;
    80002424:	4501                	li	a0,0
}
    80002426:	60e2                	ld	ra,24(sp)
    80002428:	6442                	ld	s0,16(sp)
    8000242a:	64a2                	ld	s1,8(sp)
    8000242c:	6902                	ld	s2,0(sp)
    8000242e:	6105                	addi	sp,sp,32
    80002430:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002432:	9e25                	addw	a2,a2,s1
    80002434:	1602                	slli	a2,a2,0x20
    80002436:	9201                	srli	a2,a2,0x20
    80002438:	1582                	slli	a1,a1,0x20
    8000243a:	9181                	srli	a1,a1,0x20
    8000243c:	7928                	ld	a0,112(a0)
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	008080e7          	jalr	8(ra) # 80001446 <uvmalloc>
    80002446:	0005061b          	sext.w	a2,a0
    8000244a:	fa69                	bnez	a2,8000241c <growproc+0x26>
      return -1;
    8000244c:	557d                	li	a0,-1
    8000244e:	bfe1                	j	80002426 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002450:	9e25                	addw	a2,a2,s1
    80002452:	1602                	slli	a2,a2,0x20
    80002454:	9201                	srli	a2,a2,0x20
    80002456:	1582                	slli	a1,a1,0x20
    80002458:	9181                	srli	a1,a1,0x20
    8000245a:	7928                	ld	a0,112(a0)
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	fa2080e7          	jalr	-94(ra) # 800013fe <uvmdealloc>
    80002464:	0005061b          	sext.w	a2,a0
    80002468:	bf55                	j	8000241c <growproc+0x26>

000000008000246a <fork>:
{
    8000246a:	7179                	addi	sp,sp,-48
    8000246c:	f406                	sd	ra,40(sp)
    8000246e:	f022                	sd	s0,32(sp)
    80002470:	ec26                	sd	s1,24(sp)
    80002472:	e84a                	sd	s2,16(sp)
    80002474:	e44e                	sd	s3,8(sp)
    80002476:	e052                	sd	s4,0(sp)
    80002478:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	b38080e7          	jalr	-1224(ra) # 80001fb2 <myproc>
    80002482:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002484:	00000097          	auipc	ra,0x0
    80002488:	db8080e7          	jalr	-584(ra) # 8000223c <allocproc>
    8000248c:	16050463          	beqz	a0,800025f4 <fork+0x18a>
    80002490:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002492:	0689b603          	ld	a2,104(s3)
    80002496:	792c                	ld	a1,112(a0)
    80002498:	0709b503          	ld	a0,112(s3)
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	0f6080e7          	jalr	246(ra) # 80001592 <uvmcopy>
    800024a4:	04054663          	bltz	a0,800024f0 <fork+0x86>
  np->sz = p->sz;
    800024a8:	0689b783          	ld	a5,104(s3)
    800024ac:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800024b0:	0789b683          	ld	a3,120(s3)
    800024b4:	87b6                	mv	a5,a3
    800024b6:	07893703          	ld	a4,120(s2)
    800024ba:	12068693          	addi	a3,a3,288
    800024be:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800024c2:	6788                	ld	a0,8(a5)
    800024c4:	6b8c                	ld	a1,16(a5)
    800024c6:	6f90                	ld	a2,24(a5)
    800024c8:	01073023          	sd	a6,0(a4)
    800024cc:	e708                	sd	a0,8(a4)
    800024ce:	eb0c                	sd	a1,16(a4)
    800024d0:	ef10                	sd	a2,24(a4)
    800024d2:	02078793          	addi	a5,a5,32
    800024d6:	02070713          	addi	a4,a4,32
    800024da:	fed792e3          	bne	a5,a3,800024be <fork+0x54>
  np->trapframe->a0 = 0;
    800024de:	07893783          	ld	a5,120(s2)
    800024e2:	0607b823          	sd	zero,112(a5)
    800024e6:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    800024ea:	17000a13          	li	s4,368
    800024ee:	a03d                	j	8000251c <fork+0xb2>
    freeproc(np);
    800024f0:	854a                	mv	a0,s2
    800024f2:	00000097          	auipc	ra,0x0
    800024f6:	cbe080e7          	jalr	-834(ra) # 800021b0 <freeproc>
    release(&np->lock);
    800024fa:	854a                	mv	a0,s2
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	7ae080e7          	jalr	1966(ra) # 80000caa <release>
    return -1;
    80002504:	5a7d                	li	s4,-1
    80002506:	a8f1                	j	800025e2 <fork+0x178>
      np->ofile[i] = filedup(p->ofile[i]);
    80002508:	00003097          	auipc	ra,0x3
    8000250c:	9b0080e7          	jalr	-1616(ra) # 80004eb8 <filedup>
    80002510:	009907b3          	add	a5,s2,s1
    80002514:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002516:	04a1                	addi	s1,s1,8
    80002518:	01448763          	beq	s1,s4,80002526 <fork+0xbc>
    if(p->ofile[i])
    8000251c:	009987b3          	add	a5,s3,s1
    80002520:	6388                	ld	a0,0(a5)
    80002522:	f17d                	bnez	a0,80002508 <fork+0x9e>
    80002524:	bfcd                	j	80002516 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002526:	1709b503          	ld	a0,368(s3)
    8000252a:	00002097          	auipc	ra,0x2
    8000252e:	b04080e7          	jalr	-1276(ra) # 8000402e <idup>
    80002532:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002536:	17890493          	addi	s1,s2,376
    8000253a:	4641                	li	a2,16
    8000253c:	17898593          	addi	a1,s3,376
    80002540:	8526                	mv	a0,s1
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	914080e7          	jalr	-1772(ra) # 80000e56 <safestrcpy>
  pid = np->pid;
    8000254a:	03092a03          	lw	s4,48(s2)
  int cpui = leastUsedCPU();
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	314080e7          	jalr	788(ra) # 80001862 <leastUsedCPU>
  np->cpu_num = cpui;
    80002556:	02a92a23          	sw	a0,52(s2)
  inc_cpu_usage(cpui);
    8000255a:	00000097          	auipc	ra,0x0
    8000255e:	ade080e7          	jalr	-1314(ra) # 80002038 <inc_cpu_usage>
  initlock(&np->linked_list_lock, np->name);
    80002562:	85a6                	mv	a1,s1
    80002564:	04090513          	addi	a0,s2,64
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	5ec080e7          	jalr	1516(ra) # 80000b54 <initlock>
  release(&np->lock);
    80002570:	854a                	mv	a0,s2
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	738080e7          	jalr	1848(ra) # 80000caa <release>
  acquire(&wait_lock);
    8000257a:	0000f497          	auipc	s1,0xf
    8000257e:	19e48493          	addi	s1,s1,414 # 80011718 <wait_lock>
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
  np->parent = p;
    8000258c:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	718080e7          	jalr	1816(ra) # 80000caa <release>
  acquire(&np->lock);
    8000259a:	854a                	mv	a0,s2
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	648080e7          	jalr	1608(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800025a4:	478d                	li	a5,3
    800025a6:	00f92c23          	sw	a5,24(s2)
  insert_to_list(np->index, &cpus_ll[np->cpu_num], &cpus_head[np->cpu_num]);
    800025aa:	03492583          	lw	a1,52(s2)
    800025ae:	00159793          	slli	a5,a1,0x1
    800025b2:	97ae                	add	a5,a5,a1
    800025b4:	078e                	slli	a5,a5,0x3
    800025b6:	058a                	slli	a1,a1,0x2
    800025b8:	0000f617          	auipc	a2,0xf
    800025bc:	1c060613          	addi	a2,a2,448 # 80011778 <cpus_head>
    800025c0:	963e                	add	a2,a2,a5
    800025c2:	0000f797          	auipc	a5,0xf
    800025c6:	11e78793          	addi	a5,a5,286 # 800116e0 <cpus_ll>
    800025ca:	95be                	add	a1,a1,a5
    800025cc:	03892503          	lw	a0,56(s2)
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	6d2080e7          	jalr	1746(ra) # 80001ca2 <insert_to_list>
  release(&np->lock);
    800025d8:	854a                	mv	a0,s2
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	6d0080e7          	jalr	1744(ra) # 80000caa <release>
}
    800025e2:	8552                	mv	a0,s4
    800025e4:	70a2                	ld	ra,40(sp)
    800025e6:	7402                	ld	s0,32(sp)
    800025e8:	64e2                	ld	s1,24(sp)
    800025ea:	6942                	ld	s2,16(sp)
    800025ec:	69a2                	ld	s3,8(sp)
    800025ee:	6a02                	ld	s4,0(sp)
    800025f0:	6145                	addi	sp,sp,48
    800025f2:	8082                	ret
    return -1;
    800025f4:	5a7d                	li	s4,-1
    800025f6:	b7f5                	j	800025e2 <fork+0x178>

00000000800025f8 <scheduler>:
{
    800025f8:	711d                	addi	sp,sp,-96
    800025fa:	ec86                	sd	ra,88(sp)
    800025fc:	e8a2                	sd	s0,80(sp)
    800025fe:	e4a6                	sd	s1,72(sp)
    80002600:	e0ca                	sd	s2,64(sp)
    80002602:	fc4e                	sd	s3,56(sp)
    80002604:	f852                	sd	s4,48(sp)
    80002606:	f456                	sd	s5,40(sp)
    80002608:	f05a                	sd	s6,32(sp)
    8000260a:	ec5e                	sd	s7,24(sp)
    8000260c:	e862                	sd	s8,16(sp)
    8000260e:	e466                	sd	s9,8(sp)
    80002610:	e06a                	sd	s10,0(sp)
    80002612:	1080                	addi	s0,sp,96
    80002614:	8712                	mv	a4,tp
  int id = r_tp();
    80002616:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002618:	0000fb17          	auipc	s6,0xf
    8000261c:	c88b0b13          	addi	s6,s6,-888 # 800112a0 <cpus>
    80002620:	00471793          	slli	a5,a4,0x4
    80002624:	00e786b3          	add	a3,a5,a4
    80002628:	068e                	slli	a3,a3,0x3
    8000262a:	96da                	add	a3,a3,s6
    8000262c:	0006b023          	sd	zero,0(a3)
      swtch(&c->context, &p->context);
    80002630:	97ba                	add	a5,a5,a4
    80002632:	078e                	slli	a5,a5,0x3
    80002634:	07a1                	addi	a5,a5,8
    80002636:	9b3e                	add	s6,s6,a5
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002638:	0000f997          	auipc	s3,0xf
    8000263c:	c6898993          	addi	s3,s3,-920 # 800112a0 <cpus>
      p = &proc[cpus_ll[cpuid()]];
    80002640:	0000f497          	auipc	s1,0xf
    80002644:	23848493          	addi	s1,s1,568 # 80011878 <proc>
      c->proc = p;
    80002648:	8936                	mv	s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000264e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002652:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002656:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    80002658:	2781                	sext.w	a5,a5
    8000265a:	078a                	slli	a5,a5,0x2
    8000265c:	97ce                	add	a5,a5,s3
    8000265e:	4407a703          	lw	a4,1088(a5)
    80002662:	57fd                	li	a5,-1
    80002664:	fef703e3          	beq	a4,a5,8000264a <scheduler+0x52>
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    80002668:	0000fa97          	auipc	s5,0xf
    8000266c:	110a8a93          	addi	s5,s5,272 # 80011778 <cpus_head>
    80002670:	0000fa17          	auipc	s4,0xf
    80002674:	070a0a13          	addi	s4,s4,112 # 800116e0 <cpus_ll>
    80002678:	a881                	j	800026c8 <scheduler+0xd0>
        panic("could not remove");
    8000267a:	00006517          	auipc	a0,0x6
    8000267e:	c5e50513          	addi	a0,a0,-930 # 800082d8 <digits+0x298>
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	ebc080e7          	jalr	-324(ra) # 8000053e <panic>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    8000268a:	034c2583          	lw	a1,52(s8)
    8000268e:	00159613          	slli	a2,a1,0x1
    80002692:	962e                	add	a2,a2,a1
    80002694:	060e                	slli	a2,a2,0x3
    80002696:	058a                	slli	a1,a1,0x2
    80002698:	9656                	add	a2,a2,s5
    8000269a:	95d2                	add	a1,a1,s4
    8000269c:	038c2503          	lw	a0,56(s8)
    800026a0:	fffff097          	auipc	ra,0xfffff
    800026a4:	602080e7          	jalr	1538(ra) # 80001ca2 <insert_to_list>
      c->proc = 0;
    800026a8:	00093023          	sd	zero,0(s2)
      release(&p->lock);
    800026ac:	8566                	mv	a0,s9
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5fc080e7          	jalr	1532(ra) # 80000caa <release>
    800026b6:	8792                	mv	a5,tp
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
    800026b8:	2781                	sext.w	a5,a5
    800026ba:	078a                	slli	a5,a5,0x2
    800026bc:	97ce                	add	a5,a5,s3
    800026be:	4407a703          	lw	a4,1088(a5)
    800026c2:	57fd                	li	a5,-1
    800026c4:	f8f703e3          	beq	a4,a5,8000264a <scheduler+0x52>
    800026c8:	8792                	mv	a5,tp
      p = &proc[cpus_ll[cpuid()]];
    800026ca:	2781                	sext.w	a5,a5
    800026cc:	078a                	slli	a5,a5,0x2
    800026ce:	97ce                	add	a5,a5,s3
    800026d0:	4407ad03          	lw	s10,1088(a5)
    800026d4:	18800b93          	li	s7,392
    800026d8:	037d0bb3          	mul	s7,s10,s7
    800026dc:	009b8cb3          	add	s9,s7,s1
      acquire(&p->lock);
    800026e0:	8566                	mv	a0,s9
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	502080e7          	jalr	1282(ra) # 80000be4 <acquire>
    800026ea:	8592                	mv	a1,tp
    800026ec:	8612                	mv	a2,tp
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
    800026ee:	0006079b          	sext.w	a5,a2
    800026f2:	00179613          	slli	a2,a5,0x1
    800026f6:	963e                	add	a2,a2,a5
    800026f8:	060e                	slli	a2,a2,0x3
    800026fa:	2581                	sext.w	a1,a1
    800026fc:	058a                	slli	a1,a1,0x2
    800026fe:	9656                	add	a2,a2,s5
    80002700:	95d2                	add	a1,a1,s4
    80002702:	038ca503          	lw	a0,56(s9)
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	18e080e7          	jalr	398(ra) # 80001894 <remove_from_list>
      if(removed == -1)
    8000270e:	57fd                	li	a5,-1
    80002710:	f6f505e3          	beq	a0,a5,8000267a <scheduler+0x82>
      p->state = RUNNING;
    80002714:	18800c13          	li	s8,392
    80002718:	038d0c33          	mul	s8,s10,s8
    8000271c:	9c26                	add	s8,s8,s1
    8000271e:	4791                	li	a5,4
    80002720:	00fc2c23          	sw	a5,24(s8)
      c->proc = p;
    80002724:	01993023          	sd	s9,0(s2)
      swtch(&c->context, &p->context);
    80002728:	080b8593          	addi	a1,s7,128
    8000272c:	95a6                	add	a1,a1,s1
    8000272e:	855a                	mv	a0,s6
    80002730:	00001097          	auipc	ra,0x1
    80002734:	85c080e7          	jalr	-1956(ra) # 80002f8c <swtch>
      if(p->state != ZOMBIE){
    80002738:	018c2703          	lw	a4,24(s8)
    8000273c:	4795                	li	a5,5
    8000273e:	f6f705e3          	beq	a4,a5,800026a8 <scheduler+0xb0>
    80002742:	b7a1                	j	8000268a <scheduler+0x92>

0000000080002744 <sched>:
{
    80002744:	7179                	addi	sp,sp,-48
    80002746:	f406                	sd	ra,40(sp)
    80002748:	f022                	sd	s0,32(sp)
    8000274a:	ec26                	sd	s1,24(sp)
    8000274c:	e84a                	sd	s2,16(sp)
    8000274e:	e44e                	sd	s3,8(sp)
    80002750:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002752:	00000097          	auipc	ra,0x0
    80002756:	860080e7          	jalr	-1952(ra) # 80001fb2 <myproc>
    8000275a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	40e080e7          	jalr	1038(ra) # 80000b6a <holding>
    80002764:	c559                	beqz	a0,800027f2 <sched+0xae>
    80002766:	8792                	mv	a5,tp
  if(mycpu()->noff != 1){
    80002768:	0007871b          	sext.w	a4,a5
    8000276c:	00471793          	slli	a5,a4,0x4
    80002770:	97ba                	add	a5,a5,a4
    80002772:	078e                	slli	a5,a5,0x3
    80002774:	0000f717          	auipc	a4,0xf
    80002778:	b2c70713          	addi	a4,a4,-1236 # 800112a0 <cpus>
    8000277c:	97ba                	add	a5,a5,a4
    8000277e:	5fb8                	lw	a4,120(a5)
    80002780:	4785                	li	a5,1
    80002782:	08f71063          	bne	a4,a5,80002802 <sched+0xbe>
  if(p->state == RUNNING)
    80002786:	4c98                	lw	a4,24(s1)
    80002788:	4791                	li	a5,4
    8000278a:	08f70463          	beq	a4,a5,80002812 <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000278e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002792:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002794:	e7d9                	bnez	a5,80002822 <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002796:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002798:	0000f917          	auipc	s2,0xf
    8000279c:	b0890913          	addi	s2,s2,-1272 # 800112a0 <cpus>
    800027a0:	0007871b          	sext.w	a4,a5
    800027a4:	00471793          	slli	a5,a4,0x4
    800027a8:	97ba                	add	a5,a5,a4
    800027aa:	078e                	slli	a5,a5,0x3
    800027ac:	97ca                	add	a5,a5,s2
    800027ae:	07c7a983          	lw	s3,124(a5)
    800027b2:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800027b4:	0005879b          	sext.w	a5,a1
    800027b8:	00479593          	slli	a1,a5,0x4
    800027bc:	95be                	add	a1,a1,a5
    800027be:	058e                	slli	a1,a1,0x3
    800027c0:	05a1                	addi	a1,a1,8
    800027c2:	95ca                	add	a1,a1,s2
    800027c4:	08048513          	addi	a0,s1,128
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	7c4080e7          	jalr	1988(ra) # 80002f8c <swtch>
    800027d0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800027d2:	0007871b          	sext.w	a4,a5
    800027d6:	00471793          	slli	a5,a4,0x4
    800027da:	97ba                	add	a5,a5,a4
    800027dc:	078e                	slli	a5,a5,0x3
    800027de:	993e                	add	s2,s2,a5
    800027e0:	07392e23          	sw	s3,124(s2)
}
    800027e4:	70a2                	ld	ra,40(sp)
    800027e6:	7402                	ld	s0,32(sp)
    800027e8:	64e2                	ld	s1,24(sp)
    800027ea:	6942                	ld	s2,16(sp)
    800027ec:	69a2                	ld	s3,8(sp)
    800027ee:	6145                	addi	sp,sp,48
    800027f0:	8082                	ret
    panic("sched p->lock");
    800027f2:	00006517          	auipc	a0,0x6
    800027f6:	afe50513          	addi	a0,a0,-1282 # 800082f0 <digits+0x2b0>
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	d44080e7          	jalr	-700(ra) # 8000053e <panic>
    panic("sched locks");
    80002802:	00006517          	auipc	a0,0x6
    80002806:	afe50513          	addi	a0,a0,-1282 # 80008300 <digits+0x2c0>
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	d34080e7          	jalr	-716(ra) # 8000053e <panic>
    panic("sched running");
    80002812:	00006517          	auipc	a0,0x6
    80002816:	afe50513          	addi	a0,a0,-1282 # 80008310 <digits+0x2d0>
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	d24080e7          	jalr	-732(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002822:	00006517          	auipc	a0,0x6
    80002826:	afe50513          	addi	a0,a0,-1282 # 80008320 <digits+0x2e0>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d14080e7          	jalr	-748(ra) # 8000053e <panic>

0000000080002832 <yield>:
{
    80002832:	1101                	addi	sp,sp,-32
    80002834:	ec06                	sd	ra,24(sp)
    80002836:	e822                	sd	s0,16(sp)
    80002838:	e426                	sd	s1,8(sp)
    8000283a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	776080e7          	jalr	1910(ra) # 80001fb2 <myproc>
    80002844:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	39e080e7          	jalr	926(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000284e:	478d                	li	a5,3
    80002850:	cc9c                	sw	a5,24(s1)
  insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002852:	58cc                	lw	a1,52(s1)
    80002854:	00159793          	slli	a5,a1,0x1
    80002858:	97ae                	add	a5,a5,a1
    8000285a:	078e                	slli	a5,a5,0x3
    8000285c:	058a                	slli	a1,a1,0x2
    8000285e:	0000f617          	auipc	a2,0xf
    80002862:	f1a60613          	addi	a2,a2,-230 # 80011778 <cpus_head>
    80002866:	963e                	add	a2,a2,a5
    80002868:	0000f797          	auipc	a5,0xf
    8000286c:	e7878793          	addi	a5,a5,-392 # 800116e0 <cpus_ll>
    80002870:	95be                	add	a1,a1,a5
    80002872:	5c88                	lw	a0,56(s1)
    80002874:	fffff097          	auipc	ra,0xfffff
    80002878:	42e080e7          	jalr	1070(ra) # 80001ca2 <insert_to_list>
  sched();
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	ec8080e7          	jalr	-312(ra) # 80002744 <sched>
  release(&p->lock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	424080e7          	jalr	1060(ra) # 80000caa <release>
}
    8000288e:	60e2                	ld	ra,24(sp)
    80002890:	6442                	ld	s0,16(sp)
    80002892:	64a2                	ld	s1,8(sp)
    80002894:	6105                	addi	sp,sp,32
    80002896:	8082                	ret

0000000080002898 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002898:	7179                	addi	sp,sp,-48
    8000289a:	f406                	sd	ra,40(sp)
    8000289c:	f022                	sd	s0,32(sp)
    8000289e:	ec26                	sd	s1,24(sp)
    800028a0:	e84a                	sd	s2,16(sp)
    800028a2:	e44e                	sd	s3,8(sp)
    800028a4:	1800                	addi	s0,sp,48
    800028a6:	84aa                	mv	s1,a0
    800028a8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800028aa:	fffff097          	auipc	ra,0xfffff
    800028ae:	708080e7          	jalr	1800(ra) # 80001fb2 <myproc>
    800028b2:	892a                	mv	s2,a0
  // Must acquire p->lock in order to change p->state and then call sched.
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.
  // Go to sleep.
  // cas(&p->state, RUNNING, SLEEPING);
  insert_to_list(p->index, &sleeping, &sleeping_head);
    800028b4:	0000f617          	auipc	a2,0xf
    800028b8:	e7c60613          	addi	a2,a2,-388 # 80011730 <sleeping_head>
    800028bc:	00006597          	auipc	a1,0x6
    800028c0:	05058593          	addi	a1,a1,80 # 8000890c <sleeping>
    800028c4:	5d08                	lw	a0,56(a0)
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	3dc080e7          	jalr	988(ra) # 80001ca2 <insert_to_list>
  p->chan = chan;
    800028ce:	02993023          	sd	s1,32(s2)
  // if (p->state == RUNNING){
  //   p->state = SLEEPING;
  //   }
  while(!cas(&p->state, RUNNING, SLEEPING));
    800028d2:	01890493          	addi	s1,s2,24
    800028d6:	4609                	li	a2,2
    800028d8:	4591                	li	a1,4
    800028da:	8526                	mv	a0,s1
    800028dc:	00004097          	auipc	ra,0x4
    800028e0:	31a080e7          	jalr	794(ra) # 80006bf6 <cas>
    800028e4:	d96d                	beqz	a0,800028d6 <sleep+0x3e>
  release(lk);
    800028e6:	854e                	mv	a0,s3
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	3c2080e7          	jalr	962(ra) # 80000caa <release>
  acquire(&p->lock);  //DOC: sleeplock1
    800028f0:	854a                	mv	a0,s2
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	2f2080e7          	jalr	754(ra) # 80000be4 <acquire>
  sched();
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	e4a080e7          	jalr	-438(ra) # 80002744 <sched>
  // Tidy up.
  p->chan = 0;
    80002902:	02093023          	sd	zero,32(s2)
  // Reacquire original lock.
  release(&p->lock);
    80002906:	854a                	mv	a0,s2
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	3a2080e7          	jalr	930(ra) # 80000caa <release>
  acquire(lk);
    80002910:	854e                	mv	a0,s3
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	2d2080e7          	jalr	722(ra) # 80000be4 <acquire>

}
    8000291a:	70a2                	ld	ra,40(sp)
    8000291c:	7402                	ld	s0,32(sp)
    8000291e:	64e2                	ld	s1,24(sp)
    80002920:	6942                	ld	s2,16(sp)
    80002922:	69a2                	ld	s3,8(sp)
    80002924:	6145                	addi	sp,sp,48
    80002926:	8082                	ret

0000000080002928 <wait>:
{
    80002928:	715d                	addi	sp,sp,-80
    8000292a:	e486                	sd	ra,72(sp)
    8000292c:	e0a2                	sd	s0,64(sp)
    8000292e:	fc26                	sd	s1,56(sp)
    80002930:	f84a                	sd	s2,48(sp)
    80002932:	f44e                	sd	s3,40(sp)
    80002934:	f052                	sd	s4,32(sp)
    80002936:	ec56                	sd	s5,24(sp)
    80002938:	e85a                	sd	s6,16(sp)
    8000293a:	e45e                	sd	s7,8(sp)
    8000293c:	e062                	sd	s8,0(sp)
    8000293e:	0880                	addi	s0,sp,80
    80002940:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	670080e7          	jalr	1648(ra) # 80001fb2 <myproc>
    8000294a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000294c:	0000f517          	auipc	a0,0xf
    80002950:	dcc50513          	addi	a0,a0,-564 # 80011718 <wait_lock>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	290080e7          	jalr	656(ra) # 80000be4 <acquire>
    havekids = 0;
    8000295c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000295e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002960:	00015997          	auipc	s3,0x15
    80002964:	11898993          	addi	s3,s3,280 # 80017a78 <tickslock>
        havekids = 1;
    80002968:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000296a:	0000fc17          	auipc	s8,0xf
    8000296e:	daec0c13          	addi	s8,s8,-594 # 80011718 <wait_lock>
    havekids = 0;
    80002972:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002974:	0000f497          	auipc	s1,0xf
    80002978:	f0448493          	addi	s1,s1,-252 # 80011878 <proc>
    8000297c:	a0bd                	j	800029ea <wait+0xc2>
          pid = np->pid;
    8000297e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002982:	000b0e63          	beqz	s6,8000299e <wait+0x76>
    80002986:	4691                	li	a3,4
    80002988:	02c48613          	addi	a2,s1,44
    8000298c:	85da                	mv	a1,s6
    8000298e:	07093503          	ld	a0,112(s2)
    80002992:	fffff097          	auipc	ra,0xfffff
    80002996:	d04080e7          	jalr	-764(ra) # 80001696 <copyout>
    8000299a:	02054563          	bltz	a0,800029c4 <wait+0x9c>
          freeproc(np);
    8000299e:	8526                	mv	a0,s1
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	810080e7          	jalr	-2032(ra) # 800021b0 <freeproc>
          release(&np->lock);
    800029a8:	8526                	mv	a0,s1
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	300080e7          	jalr	768(ra) # 80000caa <release>
          release(&wait_lock);
    800029b2:	0000f517          	auipc	a0,0xf
    800029b6:	d6650513          	addi	a0,a0,-666 # 80011718 <wait_lock>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	2f0080e7          	jalr	752(ra) # 80000caa <release>
          return pid;
    800029c2:	a09d                	j	80002a28 <wait+0x100>
            release(&np->lock);
    800029c4:	8526                	mv	a0,s1
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	2e4080e7          	jalr	740(ra) # 80000caa <release>
            release(&wait_lock);
    800029ce:	0000f517          	auipc	a0,0xf
    800029d2:	d4a50513          	addi	a0,a0,-694 # 80011718 <wait_lock>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	2d4080e7          	jalr	724(ra) # 80000caa <release>
            return -1;
    800029de:	59fd                	li	s3,-1
    800029e0:	a0a1                	j	80002a28 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800029e2:	18848493          	addi	s1,s1,392
    800029e6:	03348463          	beq	s1,s3,80002a0e <wait+0xe6>
      if(np->parent == p){
    800029ea:	6cbc                	ld	a5,88(s1)
    800029ec:	ff279be3          	bne	a5,s2,800029e2 <wait+0xba>
        acquire(&np->lock);
    800029f0:	8526                	mv	a0,s1
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	1f2080e7          	jalr	498(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800029fa:	4c9c                	lw	a5,24(s1)
    800029fc:	f94781e3          	beq	a5,s4,8000297e <wait+0x56>
        release(&np->lock);
    80002a00:	8526                	mv	a0,s1
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	2a8080e7          	jalr	680(ra) # 80000caa <release>
        havekids = 1;
    80002a0a:	8756                	mv	a4,s5
    80002a0c:	bfd9                	j	800029e2 <wait+0xba>
    if(!havekids || p->killed){
    80002a0e:	c701                	beqz	a4,80002a16 <wait+0xee>
    80002a10:	02892783          	lw	a5,40(s2)
    80002a14:	c79d                	beqz	a5,80002a42 <wait+0x11a>
      release(&wait_lock);
    80002a16:	0000f517          	auipc	a0,0xf
    80002a1a:	d0250513          	addi	a0,a0,-766 # 80011718 <wait_lock>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	28c080e7          	jalr	652(ra) # 80000caa <release>
      return -1;
    80002a26:	59fd                	li	s3,-1
}
    80002a28:	854e                	mv	a0,s3
    80002a2a:	60a6                	ld	ra,72(sp)
    80002a2c:	6406                	ld	s0,64(sp)
    80002a2e:	74e2                	ld	s1,56(sp)
    80002a30:	7942                	ld	s2,48(sp)
    80002a32:	79a2                	ld	s3,40(sp)
    80002a34:	7a02                	ld	s4,32(sp)
    80002a36:	6ae2                	ld	s5,24(sp)
    80002a38:	6b42                	ld	s6,16(sp)
    80002a3a:	6ba2                	ld	s7,8(sp)
    80002a3c:	6c02                	ld	s8,0(sp)
    80002a3e:	6161                	addi	sp,sp,80
    80002a40:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002a42:	85e2                	mv	a1,s8
    80002a44:	854a                	mv	a0,s2
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	e52080e7          	jalr	-430(ra) # 80002898 <sleep>
    havekids = 0;
    80002a4e:	b715                	j	80002972 <wait+0x4a>

0000000080002a50 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002a50:	7119                	addi	sp,sp,-128
    80002a52:	fc86                	sd	ra,120(sp)
    80002a54:	f8a2                	sd	s0,112(sp)
    80002a56:	f4a6                	sd	s1,104(sp)
    80002a58:	f0ca                	sd	s2,96(sp)
    80002a5a:	ecce                	sd	s3,88(sp)
    80002a5c:	e8d2                	sd	s4,80(sp)
    80002a5e:	e4d6                	sd	s5,72(sp)
    80002a60:	e0da                	sd	s6,64(sp)
    80002a62:	fc5e                	sd	s7,56(sp)
    80002a64:	f862                	sd	s8,48(sp)
    80002a66:	f466                	sd	s9,40(sp)
    80002a68:	f06a                	sd	s10,32(sp)
    80002a6a:	ec6e                	sd	s11,24(sp)
    80002a6c:	0100                	addi	s0,sp,128
  struct proc *p;
  if (sleeping == -1){
    80002a6e:	00006497          	auipc	s1,0x6
    80002a72:	e9e4a483          	lw	s1,-354(s1) # 8000890c <sleeping>
    80002a76:	57fd                	li	a5,-1
    80002a78:	0ef48c63          	beq	s1,a5,80002b70 <wakeup+0x120>
    80002a7c:	89aa                	mv	s3,a0
    return;
  }
  p = &proc[sleeping];
    80002a7e:	18800793          	li	a5,392
    80002a82:	02f484b3          	mul	s1,s1,a5
    80002a86:	0000f797          	auipc	a5,0xf
    80002a8a:	df278793          	addi	a5,a5,-526 # 80011878 <proc>
    80002a8e:	94be                	add	s1,s1,a5
  int curr= proc[sleeping].index;
  while(curr !=- 1) { // loop through all sleepers
    80002a90:	5c98                	lw	a4,56(s1)
    80002a92:	57fd                	li	a5,-1
    80002a94:	0cf70e63          	beq	a4,a5,80002b70 <wakeup+0x120>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->chan == chan && p->state == SLEEPING) {
    80002a98:	4b89                	li	s7,2
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002a9a:	0000fd97          	auipc	s11,0xf
    80002a9e:	c96d8d93          	addi	s11,s11,-874 # 80011730 <sleeping_head>
    80002aa2:	00006d17          	auipc	s10,0x6
    80002aa6:	e6ad0d13          	addi	s10,s10,-406 # 8000890c <sleeping>
        p->cpu_num = cpui;
        release(&p->lock);
        // while (!cas(&cpus[p->cpu_num].admittedProcs, cpus[p->cpu_num].admittedProcs, cpus[p->cpu_num].admittedProcs + 1))
        inc_cpu_usage(p->cpu_num);
        #endif
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    80002aaa:	0000fc97          	auipc	s9,0xf
    80002aae:	ccec8c93          	addi	s9,s9,-818 # 80011778 <cpus_head>
    80002ab2:	0000fc17          	auipc	s8,0xf
    80002ab6:	c2ec0c13          	addi	s8,s8,-978 # 800116e0 <cpus_ll>
      }
      #ifdef OFF
      release(&p->lock);
      #endif
    }
    if(p->next !=- 1)
    80002aba:	597d                	li	s2,-1
      p = &proc[p->next];
    80002abc:	18800a93          	li	s5,392
    80002ac0:	0000fa17          	auipc	s4,0xf
    80002ac4:	db8a0a13          	addi	s4,s4,-584 # 80011878 <proc>
    80002ac8:	a831                	j	80002ae4 <wakeup+0x94>
    if(p->next !=- 1)
    80002aca:	5cdc                	lw	a5,60(s1)
    80002acc:	2781                	sext.w	a5,a5
    80002ace:	01278763          	beq	a5,s2,80002adc <wakeup+0x8c>
      p = &proc[p->next];
    80002ad2:	5cc4                	lw	s1,60(s1)
    80002ad4:	2481                	sext.w	s1,s1
    80002ad6:	035484b3          	mul	s1,s1,s5
    80002ada:	94d2                	add	s1,s1,s4
    curr=p->next;
    80002adc:	5cdc                	lw	a5,60(s1)
    80002ade:	2781                	sext.w	a5,a5
  while(curr !=- 1) { // loop through all sleepers
    80002ae0:	09278863          	beq	a5,s2,80002b70 <wakeup+0x120>
    if(p != myproc()){
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	4ce080e7          	jalr	1230(ra) # 80001fb2 <myproc>
    80002aec:	fca48fe3          	beq	s1,a0,80002aca <wakeup+0x7a>
      acquire(&p->lock);
    80002af0:	8b26                	mv	s6,s1
    80002af2:	8526                	mv	a0,s1
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	0f0080e7          	jalr	240(ra) # 80000be4 <acquire>
      if(p->chan == chan && p->state == SLEEPING) {
    80002afc:	709c                	ld	a5,32(s1)
    80002afe:	fd3796e3          	bne	a5,s3,80002aca <wakeup+0x7a>
    80002b02:	4c9c                	lw	a5,24(s1)
    80002b04:	fd7793e3          	bne	a5,s7,80002aca <wakeup+0x7a>
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002b08:	866e                	mv	a2,s11
    80002b0a:	85ea                	mv	a1,s10
    80002b0c:	5c88                	lw	a0,56(s1)
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	d86080e7          	jalr	-634(ra) # 80001894 <remove_from_list>
        p->chan=0;
    80002b16:	0204b023          	sd	zero,32(s1)
        while(!cas(&p->state, SLEEPING, RUNNABLE));
    80002b1a:	01848793          	addi	a5,s1,24
    80002b1e:	f8f43423          	sd	a5,-120(s0)
    80002b22:	460d                	li	a2,3
    80002b24:	85de                	mv	a1,s7
    80002b26:	f8843503          	ld	a0,-120(s0)
    80002b2a:	00004097          	auipc	ra,0x4
    80002b2e:	0cc080e7          	jalr	204(ra) # 80006bf6 <cas>
    80002b32:	d965                	beqz	a0,80002b22 <wakeup+0xd2>
        int cpui = leastUsedCPU();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	d2e080e7          	jalr	-722(ra) # 80001862 <leastUsedCPU>
        p->cpu_num = cpui;
    80002b3c:	d8c8                	sw	a0,52(s1)
        release(&p->lock);
    80002b3e:	855a                	mv	a0,s6
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	16a080e7          	jalr	362(ra) # 80000caa <release>
        inc_cpu_usage(p->cpu_num);
    80002b48:	58c8                	lw	a0,52(s1)
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	4ee080e7          	jalr	1262(ra) # 80002038 <inc_cpu_usage>
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
    80002b52:	58dc                	lw	a5,52(s1)
    80002b54:	00179613          	slli	a2,a5,0x1
    80002b58:	963e                	add	a2,a2,a5
    80002b5a:	060e                	slli	a2,a2,0x3
    80002b5c:	078a                	slli	a5,a5,0x2
    80002b5e:	9666                	add	a2,a2,s9
    80002b60:	00fc05b3          	add	a1,s8,a5
    80002b64:	5c88                	lw	a0,56(s1)
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	13c080e7          	jalr	316(ra) # 80001ca2 <insert_to_list>
    80002b6e:	bfb1                	j	80002aca <wakeup+0x7a>
  }
}
    80002b70:	70e6                	ld	ra,120(sp)
    80002b72:	7446                	ld	s0,112(sp)
    80002b74:	74a6                	ld	s1,104(sp)
    80002b76:	7906                	ld	s2,96(sp)
    80002b78:	69e6                	ld	s3,88(sp)
    80002b7a:	6a46                	ld	s4,80(sp)
    80002b7c:	6aa6                	ld	s5,72(sp)
    80002b7e:	6b06                	ld	s6,64(sp)
    80002b80:	7be2                	ld	s7,56(sp)
    80002b82:	7c42                	ld	s8,48(sp)
    80002b84:	7ca2                	ld	s9,40(sp)
    80002b86:	7d02                	ld	s10,32(sp)
    80002b88:	6de2                	ld	s11,24(sp)
    80002b8a:	6109                	addi	sp,sp,128
    80002b8c:	8082                	ret

0000000080002b8e <reparent>:
{
    80002b8e:	7179                	addi	sp,sp,-48
    80002b90:	f406                	sd	ra,40(sp)
    80002b92:	f022                	sd	s0,32(sp)
    80002b94:	ec26                	sd	s1,24(sp)
    80002b96:	e84a                	sd	s2,16(sp)
    80002b98:	e44e                	sd	s3,8(sp)
    80002b9a:	e052                	sd	s4,0(sp)
    80002b9c:	1800                	addi	s0,sp,48
    80002b9e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ba0:	0000f497          	auipc	s1,0xf
    80002ba4:	cd848493          	addi	s1,s1,-808 # 80011878 <proc>
      pp->parent = initproc;
    80002ba8:	00006a17          	auipc	s4,0x6
    80002bac:	480a0a13          	addi	s4,s4,1152 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bb0:	00015997          	auipc	s3,0x15
    80002bb4:	ec898993          	addi	s3,s3,-312 # 80017a78 <tickslock>
    80002bb8:	a029                	j	80002bc2 <reparent+0x34>
    80002bba:	18848493          	addi	s1,s1,392
    80002bbe:	01348d63          	beq	s1,s3,80002bd8 <reparent+0x4a>
    if(pp->parent == p){
    80002bc2:	6cbc                	ld	a5,88(s1)
    80002bc4:	ff279be3          	bne	a5,s2,80002bba <reparent+0x2c>
      pp->parent = initproc;
    80002bc8:	000a3503          	ld	a0,0(s4)
    80002bcc:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	e82080e7          	jalr	-382(ra) # 80002a50 <wakeup>
    80002bd6:	b7d5                	j	80002bba <reparent+0x2c>
}
    80002bd8:	70a2                	ld	ra,40(sp)
    80002bda:	7402                	ld	s0,32(sp)
    80002bdc:	64e2                	ld	s1,24(sp)
    80002bde:	6942                	ld	s2,16(sp)
    80002be0:	69a2                	ld	s3,8(sp)
    80002be2:	6a02                	ld	s4,0(sp)
    80002be4:	6145                	addi	sp,sp,48
    80002be6:	8082                	ret

0000000080002be8 <exit>:
{
    80002be8:	7179                	addi	sp,sp,-48
    80002bea:	f406                	sd	ra,40(sp)
    80002bec:	f022                	sd	s0,32(sp)
    80002bee:	ec26                	sd	s1,24(sp)
    80002bf0:	e84a                	sd	s2,16(sp)
    80002bf2:	e44e                	sd	s3,8(sp)
    80002bf4:	e052                	sd	s4,0(sp)
    80002bf6:	1800                	addi	s0,sp,48
    80002bf8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	3b8080e7          	jalr	952(ra) # 80001fb2 <myproc>
    80002c02:	89aa                	mv	s3,a0
  if(p == initproc)
    80002c04:	00006797          	auipc	a5,0x6
    80002c08:	4247b783          	ld	a5,1060(a5) # 80009028 <initproc>
    80002c0c:	0f050493          	addi	s1,a0,240
    80002c10:	17050913          	addi	s2,a0,368
    80002c14:	02a79363          	bne	a5,a0,80002c3a <exit+0x52>
    panic("init exiting");
    80002c18:	00005517          	auipc	a0,0x5
    80002c1c:	72050513          	addi	a0,a0,1824 # 80008338 <digits+0x2f8>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	91e080e7          	jalr	-1762(ra) # 8000053e <panic>
      fileclose(f);
    80002c28:	00002097          	auipc	ra,0x2
    80002c2c:	2e2080e7          	jalr	738(ra) # 80004f0a <fileclose>
      p->ofile[fd] = 0;
    80002c30:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002c34:	04a1                	addi	s1,s1,8
    80002c36:	01248563          	beq	s1,s2,80002c40 <exit+0x58>
    if(p->ofile[fd]){
    80002c3a:	6088                	ld	a0,0(s1)
    80002c3c:	f575                	bnez	a0,80002c28 <exit+0x40>
    80002c3e:	bfdd                	j	80002c34 <exit+0x4c>
  begin_op();
    80002c40:	00002097          	auipc	ra,0x2
    80002c44:	dfe080e7          	jalr	-514(ra) # 80004a3e <begin_op>
  iput(p->cwd);
    80002c48:	1709b503          	ld	a0,368(s3)
    80002c4c:	00001097          	auipc	ra,0x1
    80002c50:	5da080e7          	jalr	1498(ra) # 80004226 <iput>
  end_op();
    80002c54:	00002097          	auipc	ra,0x2
    80002c58:	e6a080e7          	jalr	-406(ra) # 80004abe <end_op>
  p->cwd = 0;
    80002c5c:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002c60:	0000f497          	auipc	s1,0xf
    80002c64:	ab848493          	addi	s1,s1,-1352 # 80011718 <wait_lock>
    80002c68:	8526                	mv	a0,s1
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	f7a080e7          	jalr	-134(ra) # 80000be4 <acquire>
  reparent(p);
    80002c72:	854e                	mv	a0,s3
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	f1a080e7          	jalr	-230(ra) # 80002b8e <reparent>
  wakeup(p->parent);
    80002c7c:	0589b503          	ld	a0,88(s3)
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	dd0080e7          	jalr	-560(ra) # 80002a50 <wakeup>
  acquire(&p->lock);
    80002c88:	854e                	mv	a0,s3
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	f5a080e7          	jalr	-166(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002c92:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002c96:	4795                	li	a5,5
    80002c98:	00f9ac23          	sw	a5,24(s3)
  insert_to_list(p->index, &zombie, &zombie_head);
    80002c9c:	0000f617          	auipc	a2,0xf
    80002ca0:	aac60613          	addi	a2,a2,-1364 # 80011748 <zombie_head>
    80002ca4:	00006597          	auipc	a1,0x6
    80002ca8:	c6458593          	addi	a1,a1,-924 # 80008908 <zombie>
    80002cac:	0389a503          	lw	a0,56(s3)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	ff2080e7          	jalr	-14(ra) # 80001ca2 <insert_to_list>
  release(&wait_lock);
    80002cb8:	8526                	mv	a0,s1
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	ff0080e7          	jalr	-16(ra) # 80000caa <release>
  sched();
    80002cc2:	00000097          	auipc	ra,0x0
    80002cc6:	a82080e7          	jalr	-1406(ra) # 80002744 <sched>
  panic("zombie exit");
    80002cca:	00005517          	auipc	a0,0x5
    80002cce:	67e50513          	addi	a0,a0,1662 # 80008348 <digits+0x308>
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>

0000000080002cda <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002cda:	7179                	addi	sp,sp,-48
    80002cdc:	f406                	sd	ra,40(sp)
    80002cde:	f022                	sd	s0,32(sp)
    80002ce0:	ec26                	sd	s1,24(sp)
    80002ce2:	e84a                	sd	s2,16(sp)
    80002ce4:	e44e                	sd	s3,8(sp)
    80002ce6:	1800                	addi	s0,sp,48
    80002ce8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002cea:	0000f497          	auipc	s1,0xf
    80002cee:	b8e48493          	addi	s1,s1,-1138 # 80011878 <proc>
    80002cf2:	00015997          	auipc	s3,0x15
    80002cf6:	d8698993          	addi	s3,s3,-634 # 80017a78 <tickslock>
    acquire(&p->lock);
    80002cfa:	8526                	mv	a0,s1
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	ee8080e7          	jalr	-280(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002d04:	589c                	lw	a5,48(s1)
    80002d06:	01278d63          	beq	a5,s2,80002d20 <kill+0x46>
      release(&p->lock);
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
      }
      return 0;
    }
    release(&p->lock);
    80002d0a:	8526                	mv	a0,s1
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	f9e080e7          	jalr	-98(ra) # 80000caa <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d14:	18848493          	addi	s1,s1,392
    80002d18:	ff3491e3          	bne	s1,s3,80002cfa <kill+0x20>
  }
  return -1;
    80002d1c:	557d                	li	a0,-1
    80002d1e:	a831                	j	80002d3a <kill+0x60>
      p->killed = 1;
    80002d20:	4785                	li	a5,1
    80002d22:	d49c                	sw	a5,40(s1)
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002d24:	460d                	li	a2,3
    80002d26:	4589                	li	a1,2
    80002d28:	01848513          	addi	a0,s1,24
    80002d2c:	00004097          	auipc	ra,0x4
    80002d30:	eca080e7          	jalr	-310(ra) # 80006bf6 <cas>
    80002d34:	87aa                	mv	a5,a0
      return 0;
    80002d36:	4501                	li	a0,0
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
    80002d38:	cb81                	beqz	a5,80002d48 <kill+0x6e>
}
    80002d3a:	70a2                	ld	ra,40(sp)
    80002d3c:	7402                	ld	s0,32(sp)
    80002d3e:	64e2                	ld	s1,24(sp)
    80002d40:	6942                	ld	s2,16(sp)
    80002d42:	69a2                	ld	s3,8(sp)
    80002d44:	6145                	addi	sp,sp,48
    80002d46:	8082                	ret
        remove_from_list(p->index, &sleeping, &sleeping_head);
    80002d48:	0000f617          	auipc	a2,0xf
    80002d4c:	9e860613          	addi	a2,a2,-1560 # 80011730 <sleeping_head>
    80002d50:	00006597          	auipc	a1,0x6
    80002d54:	bbc58593          	addi	a1,a1,-1092 # 8000890c <sleeping>
    80002d58:	5c88                	lw	a0,56(s1)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	b3a080e7          	jalr	-1222(ra) # 80001894 <remove_from_list>
        p->state = RUNNABLE;
    80002d62:	478d                	li	a5,3
    80002d64:	cc9c                	sw	a5,24(s1)
      release(&p->lock);
    80002d66:	8526                	mv	a0,s1
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	f42080e7          	jalr	-190(ra) # 80000caa <release>
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
    80002d70:	58cc                	lw	a1,52(s1)
    80002d72:	00159793          	slli	a5,a1,0x1
    80002d76:	97ae                	add	a5,a5,a1
    80002d78:	078e                	slli	a5,a5,0x3
    80002d7a:	058a                	slli	a1,a1,0x2
    80002d7c:	0000f617          	auipc	a2,0xf
    80002d80:	9fc60613          	addi	a2,a2,-1540 # 80011778 <cpus_head>
    80002d84:	963e                	add	a2,a2,a5
    80002d86:	0000f797          	auipc	a5,0xf
    80002d8a:	95a78793          	addi	a5,a5,-1702 # 800116e0 <cpus_ll>
    80002d8e:	95be                	add	a1,a1,a5
    80002d90:	5c88                	lw	a0,56(s1)
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	f10080e7          	jalr	-240(ra) # 80001ca2 <insert_to_list>
      return 0;
    80002d9a:	4501                	li	a0,0
    80002d9c:	bf79                	j	80002d3a <kill+0x60>

0000000080002d9e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len){
    80002d9e:	7179                	addi	sp,sp,-48
    80002da0:	f406                	sd	ra,40(sp)
    80002da2:	f022                	sd	s0,32(sp)
    80002da4:	ec26                	sd	s1,24(sp)
    80002da6:	e84a                	sd	s2,16(sp)
    80002da8:	e44e                	sd	s3,8(sp)
    80002daa:	e052                	sd	s4,0(sp)
    80002dac:	1800                	addi	s0,sp,48
    80002dae:	84aa                	mv	s1,a0
    80002db0:	892e                	mv	s2,a1
    80002db2:	89b2                	mv	s3,a2
    80002db4:	8a36                	mv	s4,a3

  struct proc *p = myproc();
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	1fc080e7          	jalr	508(ra) # 80001fb2 <myproc>
  if(user_dst){
    80002dbe:	c08d                	beqz	s1,80002de0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002dc0:	86d2                	mv	a3,s4
    80002dc2:	864e                	mv	a2,s3
    80002dc4:	85ca                	mv	a1,s2
    80002dc6:	7928                	ld	a0,112(a0)
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	8ce080e7          	jalr	-1842(ra) # 80001696 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002dd0:	70a2                	ld	ra,40(sp)
    80002dd2:	7402                	ld	s0,32(sp)
    80002dd4:	64e2                	ld	s1,24(sp)
    80002dd6:	6942                	ld	s2,16(sp)
    80002dd8:	69a2                	ld	s3,8(sp)
    80002dda:	6a02                	ld	s4,0(sp)
    80002ddc:	6145                	addi	sp,sp,48
    80002dde:	8082                	ret
    memmove((char *)dst, src, len);
    80002de0:	000a061b          	sext.w	a2,s4
    80002de4:	85ce                	mv	a1,s3
    80002de6:	854a                	mv	a0,s2
    80002de8:	ffffe097          	auipc	ra,0xffffe
    80002dec:	f7c080e7          	jalr	-132(ra) # 80000d64 <memmove>
    return 0;
    80002df0:	8526                	mv	a0,s1
    80002df2:	bff9                	j	80002dd0 <either_copyout+0x32>

0000000080002df4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002df4:	7179                	addi	sp,sp,-48
    80002df6:	f406                	sd	ra,40(sp)
    80002df8:	f022                	sd	s0,32(sp)
    80002dfa:	ec26                	sd	s1,24(sp)
    80002dfc:	e84a                	sd	s2,16(sp)
    80002dfe:	e44e                	sd	s3,8(sp)
    80002e00:	e052                	sd	s4,0(sp)
    80002e02:	1800                	addi	s0,sp,48
    80002e04:	892a                	mv	s2,a0
    80002e06:	84ae                	mv	s1,a1
    80002e08:	89b2                	mv	s3,a2
    80002e0a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	1a6080e7          	jalr	422(ra) # 80001fb2 <myproc>
  if(user_src){
    80002e14:	c08d                	beqz	s1,80002e36 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002e16:	86d2                	mv	a3,s4
    80002e18:	864e                	mv	a2,s3
    80002e1a:	85ca                	mv	a1,s2
    80002e1c:	7928                	ld	a0,112(a0)
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	904080e7          	jalr	-1788(ra) # 80001722 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002e26:	70a2                	ld	ra,40(sp)
    80002e28:	7402                	ld	s0,32(sp)
    80002e2a:	64e2                	ld	s1,24(sp)
    80002e2c:	6942                	ld	s2,16(sp)
    80002e2e:	69a2                	ld	s3,8(sp)
    80002e30:	6a02                	ld	s4,0(sp)
    80002e32:	6145                	addi	sp,sp,48
    80002e34:	8082                	ret
    memmove(dst, (char*)src, len);
    80002e36:	000a061b          	sext.w	a2,s4
    80002e3a:	85ce                	mv	a1,s3
    80002e3c:	854a                	mv	a0,s2
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	f26080e7          	jalr	-218(ra) # 80000d64 <memmove>
    return 0;
    80002e46:	8526                	mv	a0,s1
    80002e48:	bff9                	j	80002e26 <either_copyin+0x32>

0000000080002e4a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002e4a:	715d                	addi	sp,sp,-80
    80002e4c:	e486                	sd	ra,72(sp)
    80002e4e:	e0a2                	sd	s0,64(sp)
    80002e50:	fc26                	sd	s1,56(sp)
    80002e52:	f84a                	sd	s2,48(sp)
    80002e54:	f44e                	sd	s3,40(sp)
    80002e56:	f052                	sd	s4,32(sp)
    80002e58:	ec56                	sd	s5,24(sp)
    80002e5a:	e85a                	sd	s6,16(sp)
    80002e5c:	e45e                	sd	s7,8(sp)
    80002e5e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002e60:	00005517          	auipc	a0,0x5
    80002e64:	29850513          	addi	a0,a0,664 # 800080f8 <digits+0xb8>
    80002e68:	ffffd097          	auipc	ra,0xffffd
    80002e6c:	720080e7          	jalr	1824(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002e70:	0000f497          	auipc	s1,0xf
    80002e74:	b8048493          	addi	s1,s1,-1152 # 800119f0 <proc+0x178>
    80002e78:	00015917          	auipc	s2,0x15
    80002e7c:	d7890913          	addi	s2,s2,-648 # 80017bf0 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e80:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002e82:	00005997          	auipc	s3,0x5
    80002e86:	4d698993          	addi	s3,s3,1238 # 80008358 <digits+0x318>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002e8a:	00005a97          	auipc	s5,0x5
    80002e8e:	4d6a8a93          	addi	s5,s5,1238 # 80008360 <digits+0x320>
    printf("\n");
    80002e92:	00005a17          	auipc	s4,0x5
    80002e96:	266a0a13          	addi	s4,s4,614 # 800080f8 <digits+0xb8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e9a:	00005b97          	auipc	s7,0x5
    80002e9e:	4feb8b93          	addi	s7,s7,1278 # 80008398 <states.1812>
    80002ea2:	a01d                	j	80002ec8 <procdump+0x7e>
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    80002ea4:	ebc6a703          	lw	a4,-324(a3)
    80002ea8:	eb86a583          	lw	a1,-328(a3)
    80002eac:	8556                	mv	a0,s5
    80002eae:	ffffd097          	auipc	ra,0xffffd
    80002eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    printf("\n");
    80002eb6:	8552                	mv	a0,s4
    80002eb8:	ffffd097          	auipc	ra,0xffffd
    80002ebc:	6d0080e7          	jalr	1744(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ec0:	18848493          	addi	s1,s1,392
    80002ec4:	03248163          	beq	s1,s2,80002ee6 <procdump+0x9c>
    if(p->state == UNUSED)
    80002ec8:	86a6                	mv	a3,s1
    80002eca:	ea04a783          	lw	a5,-352(s1)
    80002ece:	dbed                	beqz	a5,80002ec0 <procdump+0x76>
      state = "???";
    80002ed0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ed2:	fcfb69e3          	bltu	s6,a5,80002ea4 <procdump+0x5a>
    80002ed6:	1782                	slli	a5,a5,0x20
    80002ed8:	9381                	srli	a5,a5,0x20
    80002eda:	078e                	slli	a5,a5,0x3
    80002edc:	97de                	add	a5,a5,s7
    80002ede:	6390                	ld	a2,0(a5)
    80002ee0:	f271                	bnez	a2,80002ea4 <procdump+0x5a>
      state = "???";
    80002ee2:	864e                	mv	a2,s3
    80002ee4:	b7c1                	j	80002ea4 <procdump+0x5a>
  }
}
    80002ee6:	60a6                	ld	ra,72(sp)
    80002ee8:	6406                	ld	s0,64(sp)
    80002eea:	74e2                	ld	s1,56(sp)
    80002eec:	7942                	ld	s2,48(sp)
    80002eee:	79a2                	ld	s3,40(sp)
    80002ef0:	7a02                	ld	s4,32(sp)
    80002ef2:	6ae2                	ld	s5,24(sp)
    80002ef4:	6b42                	ld	s6,16(sp)
    80002ef6:	6ba2                	ld	s7,8(sp)
    80002ef8:	6161                	addi	sp,sp,80
    80002efa:	8082                	ret

0000000080002efc <set_cpu>:


int set_cpu(int cpu_num){ //added as orderd
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	1000                	addi	s0,sp,32
    80002f06:	84aa                	mv	s1,a0
// printf("%d\n", 12);
  struct proc *p= myproc();  
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	0aa080e7          	jalr	170(ra) # 80001fb2 <myproc>
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    80002f10:	8626                	mv	a2,s1
    80002f12:	594c                	lw	a1,52(a0)
    80002f14:	03450513          	addi	a0,a0,52
    80002f18:	00004097          	auipc	ra,0x4
    80002f1c:	cde080e7          	jalr	-802(ra) # 80006bf6 <cas>
    80002f20:	e519                	bnez	a0,80002f2e <set_cpu+0x32>
    yield();
    return cpu_num;
  }
  return 0;
    80002f22:	4501                	li	a0,0
}
    80002f24:	60e2                	ld	ra,24(sp)
    80002f26:	6442                	ld	s0,16(sp)
    80002f28:	64a2                	ld	s1,8(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret
    yield();
    80002f2e:	00000097          	auipc	ra,0x0
    80002f32:	904080e7          	jalr	-1788(ra) # 80002832 <yield>
    return cpu_num;
    80002f36:	8526                	mv	a0,s1
    80002f38:	b7f5                	j	80002f24 <set_cpu+0x28>

0000000080002f3a <get_cpu>:

int get_cpu(){ //added as orderd
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	1000                	addi	s0,sp,32
// printf("%d\n", 13);
  struct proc *p = myproc();
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	070080e7          	jalr	112(ra) # 80001fb2 <myproc>
  int ans=0;
    80002f4a:	fe042623          	sw	zero,-20(s0)
  cas(&ans, ans, p->cpu_num);
    80002f4e:	5950                	lw	a2,52(a0)
    80002f50:	4581                	li	a1,0
    80002f52:	fec40513          	addi	a0,s0,-20
    80002f56:	00004097          	auipc	ra,0x4
    80002f5a:	ca0080e7          	jalr	-864(ra) # 80006bf6 <cas>
    return ans;
}
    80002f5e:	fec42503          	lw	a0,-20(s0)
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	6105                	addi	sp,sp,32
    80002f68:	8082                	ret

0000000080002f6a <cpu_process_count>:

// int cpu_process_count (int cpu_num){
//   return cpu_usage[cpu_num];
// }
int cpu_process_count(int cpu_num){
    80002f6a:	1141                	addi	sp,sp,-16
    80002f6c:	e422                	sd	s0,8(sp)
    80002f6e:	0800                	addi	s0,sp,16
  struct cpu* c = &cpus[cpu_num];
  uint64 procsNum = c->admittedProcs;
    80002f70:	00451793          	slli	a5,a0,0x4
    80002f74:	97aa                	add	a5,a5,a0
    80002f76:	078e                	slli	a5,a5,0x3
    80002f78:	0000e517          	auipc	a0,0xe
    80002f7c:	32850513          	addi	a0,a0,808 # 800112a0 <cpus>
    80002f80:	97aa                	add	a5,a5,a0
  return procsNum;
}
    80002f82:	0807a503          	lw	a0,128(a5)
    80002f86:	6422                	ld	s0,8(sp)
    80002f88:	0141                	addi	sp,sp,16
    80002f8a:	8082                	ret

0000000080002f8c <swtch>:
    80002f8c:	00153023          	sd	ra,0(a0)
    80002f90:	00253423          	sd	sp,8(a0)
    80002f94:	e900                	sd	s0,16(a0)
    80002f96:	ed04                	sd	s1,24(a0)
    80002f98:	03253023          	sd	s2,32(a0)
    80002f9c:	03353423          	sd	s3,40(a0)
    80002fa0:	03453823          	sd	s4,48(a0)
    80002fa4:	03553c23          	sd	s5,56(a0)
    80002fa8:	05653023          	sd	s6,64(a0)
    80002fac:	05753423          	sd	s7,72(a0)
    80002fb0:	05853823          	sd	s8,80(a0)
    80002fb4:	05953c23          	sd	s9,88(a0)
    80002fb8:	07a53023          	sd	s10,96(a0)
    80002fbc:	07b53423          	sd	s11,104(a0)
    80002fc0:	0005b083          	ld	ra,0(a1)
    80002fc4:	0085b103          	ld	sp,8(a1)
    80002fc8:	6980                	ld	s0,16(a1)
    80002fca:	6d84                	ld	s1,24(a1)
    80002fcc:	0205b903          	ld	s2,32(a1)
    80002fd0:	0285b983          	ld	s3,40(a1)
    80002fd4:	0305ba03          	ld	s4,48(a1)
    80002fd8:	0385ba83          	ld	s5,56(a1)
    80002fdc:	0405bb03          	ld	s6,64(a1)
    80002fe0:	0485bb83          	ld	s7,72(a1)
    80002fe4:	0505bc03          	ld	s8,80(a1)
    80002fe8:	0585bc83          	ld	s9,88(a1)
    80002fec:	0605bd03          	ld	s10,96(a1)
    80002ff0:	0685bd83          	ld	s11,104(a1)
    80002ff4:	8082                	ret

0000000080002ff6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ff6:	1141                	addi	sp,sp,-16
    80002ff8:	e406                	sd	ra,8(sp)
    80002ffa:	e022                	sd	s0,0(sp)
    80002ffc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ffe:	00005597          	auipc	a1,0x5
    80003002:	3ca58593          	addi	a1,a1,970 # 800083c8 <states.1812+0x30>
    80003006:	00015517          	auipc	a0,0x15
    8000300a:	a7250513          	addi	a0,a0,-1422 # 80017a78 <tickslock>
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	b46080e7          	jalr	-1210(ra) # 80000b54 <initlock>
}
    80003016:	60a2                	ld	ra,8(sp)
    80003018:	6402                	ld	s0,0(sp)
    8000301a:	0141                	addi	sp,sp,16
    8000301c:	8082                	ret

000000008000301e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000301e:	1141                	addi	sp,sp,-16
    80003020:	e422                	sd	s0,8(sp)
    80003022:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003024:	00003797          	auipc	a5,0x3
    80003028:	4fc78793          	addi	a5,a5,1276 # 80006520 <kernelvec>
    8000302c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003030:	6422                	ld	s0,8(sp)
    80003032:	0141                	addi	sp,sp,16
    80003034:	8082                	ret

0000000080003036 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003036:	1141                	addi	sp,sp,-16
    80003038:	e406                	sd	ra,8(sp)
    8000303a:	e022                	sd	s0,0(sp)
    8000303c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	f74080e7          	jalr	-140(ra) # 80001fb2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003046:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000304a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000304c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003050:	00004617          	auipc	a2,0x4
    80003054:	fb060613          	addi	a2,a2,-80 # 80007000 <_trampoline>
    80003058:	00004697          	auipc	a3,0x4
    8000305c:	fa868693          	addi	a3,a3,-88 # 80007000 <_trampoline>
    80003060:	8e91                	sub	a3,a3,a2
    80003062:	040007b7          	lui	a5,0x4000
    80003066:	17fd                	addi	a5,a5,-1
    80003068:	07b2                	slli	a5,a5,0xc
    8000306a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000306c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003070:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003072:	180026f3          	csrr	a3,satp
    80003076:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003078:	7d38                	ld	a4,120(a0)
    8000307a:	7134                	ld	a3,96(a0)
    8000307c:	6585                	lui	a1,0x1
    8000307e:	96ae                	add	a3,a3,a1
    80003080:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003082:	7d38                	ld	a4,120(a0)
    80003084:	00000697          	auipc	a3,0x0
    80003088:	13868693          	addi	a3,a3,312 # 800031bc <usertrap>
    8000308c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000308e:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003090:	8692                	mv	a3,tp
    80003092:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003094:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003098:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000309c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030a0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800030a4:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030a6:	6f18                	ld	a4,24(a4)
    800030a8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800030ac:	792c                	ld	a1,112(a0)
    800030ae:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800030b0:	00004717          	auipc	a4,0x4
    800030b4:	fe070713          	addi	a4,a4,-32 # 80007090 <userret>
    800030b8:	8f11                	sub	a4,a4,a2
    800030ba:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800030bc:	577d                	li	a4,-1
    800030be:	177e                	slli	a4,a4,0x3f
    800030c0:	8dd9                	or	a1,a1,a4
    800030c2:	02000537          	lui	a0,0x2000
    800030c6:	157d                	addi	a0,a0,-1
    800030c8:	0536                	slli	a0,a0,0xd
    800030ca:	9782                	jalr	a5
}
    800030cc:	60a2                	ld	ra,8(sp)
    800030ce:	6402                	ld	s0,0(sp)
    800030d0:	0141                	addi	sp,sp,16
    800030d2:	8082                	ret

00000000800030d4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	e426                	sd	s1,8(sp)
    800030dc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800030de:	00015497          	auipc	s1,0x15
    800030e2:	99a48493          	addi	s1,s1,-1638 # 80017a78 <tickslock>
    800030e6:	8526                	mv	a0,s1
    800030e8:	ffffe097          	auipc	ra,0xffffe
    800030ec:	afc080e7          	jalr	-1284(ra) # 80000be4 <acquire>
  ticks++;
    800030f0:	00006517          	auipc	a0,0x6
    800030f4:	f4050513          	addi	a0,a0,-192 # 80009030 <ticks>
    800030f8:	411c                	lw	a5,0(a0)
    800030fa:	2785                	addiw	a5,a5,1
    800030fc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	952080e7          	jalr	-1710(ra) # 80002a50 <wakeup>
  release(&tickslock);
    80003106:	8526                	mv	a0,s1
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	ba2080e7          	jalr	-1118(ra) # 80000caa <release>
}
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	64a2                	ld	s1,8(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003124:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003128:	00074d63          	bltz	a4,80003142 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000312c:	57fd                	li	a5,-1
    8000312e:	17fe                	slli	a5,a5,0x3f
    80003130:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003132:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003134:	06f70363          	beq	a4,a5,8000319a <devintr+0x80>
  }
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret
     (scause & 0xff) == 9){
    80003142:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003146:	46a5                	li	a3,9
    80003148:	fed792e3          	bne	a5,a3,8000312c <devintr+0x12>
    int irq = plic_claim();
    8000314c:	00003097          	auipc	ra,0x3
    80003150:	4dc080e7          	jalr	1244(ra) # 80006628 <plic_claim>
    80003154:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003156:	47a9                	li	a5,10
    80003158:	02f50763          	beq	a0,a5,80003186 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000315c:	4785                	li	a5,1
    8000315e:	02f50963          	beq	a0,a5,80003190 <devintr+0x76>
    return 1;
    80003162:	4505                	li	a0,1
    } else if(irq){
    80003164:	d8f1                	beqz	s1,80003138 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003166:	85a6                	mv	a1,s1
    80003168:	00005517          	auipc	a0,0x5
    8000316c:	26850513          	addi	a0,a0,616 # 800083d0 <states.1812+0x38>
    80003170:	ffffd097          	auipc	ra,0xffffd
    80003174:	418080e7          	jalr	1048(ra) # 80000588 <printf>
      plic_complete(irq);
    80003178:	8526                	mv	a0,s1
    8000317a:	00003097          	auipc	ra,0x3
    8000317e:	4d2080e7          	jalr	1234(ra) # 8000664c <plic_complete>
    return 1;
    80003182:	4505                	li	a0,1
    80003184:	bf55                	j	80003138 <devintr+0x1e>
      uartintr();
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	822080e7          	jalr	-2014(ra) # 800009a8 <uartintr>
    8000318e:	b7ed                	j	80003178 <devintr+0x5e>
      virtio_disk_intr();
    80003190:	00004097          	auipc	ra,0x4
    80003194:	99c080e7          	jalr	-1636(ra) # 80006b2c <virtio_disk_intr>
    80003198:	b7c5                	j	80003178 <devintr+0x5e>
    if(cpuid() == 0){
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	de4080e7          	jalr	-540(ra) # 80001f7e <cpuid>
    800031a2:	c901                	beqz	a0,800031b2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800031a4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800031a8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800031aa:	14479073          	csrw	sip,a5
    return 2;
    800031ae:	4509                	li	a0,2
    800031b0:	b761                	j	80003138 <devintr+0x1e>
      clockintr();
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	f22080e7          	jalr	-222(ra) # 800030d4 <clockintr>
    800031ba:	b7ed                	j	800031a4 <devintr+0x8a>

00000000800031bc <usertrap>:
{
    800031bc:	1101                	addi	sp,sp,-32
    800031be:	ec06                	sd	ra,24(sp)
    800031c0:	e822                	sd	s0,16(sp)
    800031c2:	e426                	sd	s1,8(sp)
    800031c4:	e04a                	sd	s2,0(sp)
    800031c6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031c8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800031cc:	1007f793          	andi	a5,a5,256
    800031d0:	e3ad                	bnez	a5,80003232 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800031d2:	00003797          	auipc	a5,0x3
    800031d6:	34e78793          	addi	a5,a5,846 # 80006520 <kernelvec>
    800031da:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	dd4080e7          	jalr	-556(ra) # 80001fb2 <myproc>
    800031e6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800031e8:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031ea:	14102773          	csrr	a4,sepc
    800031ee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031f0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800031f4:	47a1                	li	a5,8
    800031f6:	04f71c63          	bne	a4,a5,8000324e <usertrap+0x92>
    if(p->killed)
    800031fa:	551c                	lw	a5,40(a0)
    800031fc:	e3b9                	bnez	a5,80003242 <usertrap+0x86>
    p->trapframe->epc += 4;
    800031fe:	7cb8                	ld	a4,120(s1)
    80003200:	6f1c                	ld	a5,24(a4)
    80003202:	0791                	addi	a5,a5,4
    80003204:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003206:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000320a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000320e:	10079073          	csrw	sstatus,a5
    syscall();
    80003212:	00000097          	auipc	ra,0x0
    80003216:	2e0080e7          	jalr	736(ra) # 800034f2 <syscall>
  if(p->killed)
    8000321a:	549c                	lw	a5,40(s1)
    8000321c:	ebc1                	bnez	a5,800032ac <usertrap+0xf0>
  usertrapret();
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	e18080e7          	jalr	-488(ra) # 80003036 <usertrapret>
}
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	64a2                	ld	s1,8(sp)
    8000322c:	6902                	ld	s2,0(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret
    panic("usertrap: not from user mode");
    80003232:	00005517          	auipc	a0,0x5
    80003236:	1be50513          	addi	a0,a0,446 # 800083f0 <states.1812+0x58>
    8000323a:	ffffd097          	auipc	ra,0xffffd
    8000323e:	304080e7          	jalr	772(ra) # 8000053e <panic>
      exit(-1);
    80003242:	557d                	li	a0,-1
    80003244:	00000097          	auipc	ra,0x0
    80003248:	9a4080e7          	jalr	-1628(ra) # 80002be8 <exit>
    8000324c:	bf4d                	j	800031fe <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	ecc080e7          	jalr	-308(ra) # 8000311a <devintr>
    80003256:	892a                	mv	s2,a0
    80003258:	c501                	beqz	a0,80003260 <usertrap+0xa4>
  if(p->killed)
    8000325a:	549c                	lw	a5,40(s1)
    8000325c:	c3a1                	beqz	a5,8000329c <usertrap+0xe0>
    8000325e:	a815                	j	80003292 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003260:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003264:	5890                	lw	a2,48(s1)
    80003266:	00005517          	auipc	a0,0x5
    8000326a:	1aa50513          	addi	a0,a0,426 # 80008410 <states.1812+0x78>
    8000326e:	ffffd097          	auipc	ra,0xffffd
    80003272:	31a080e7          	jalr	794(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003276:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000327a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000327e:	00005517          	auipc	a0,0x5
    80003282:	1c250513          	addi	a0,a0,450 # 80008440 <states.1812+0xa8>
    80003286:	ffffd097          	auipc	ra,0xffffd
    8000328a:	302080e7          	jalr	770(ra) # 80000588 <printf>
    p->killed = 1;
    8000328e:	4785                	li	a5,1
    80003290:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003292:	557d                	li	a0,-1
    80003294:	00000097          	auipc	ra,0x0
    80003298:	954080e7          	jalr	-1708(ra) # 80002be8 <exit>
  if(which_dev == 2)
    8000329c:	4789                	li	a5,2
    8000329e:	f8f910e3          	bne	s2,a5,8000321e <usertrap+0x62>
    yield();
    800032a2:	fffff097          	auipc	ra,0xfffff
    800032a6:	590080e7          	jalr	1424(ra) # 80002832 <yield>
    800032aa:	bf95                	j	8000321e <usertrap+0x62>
  int which_dev = 0;
    800032ac:	4901                	li	s2,0
    800032ae:	b7d5                	j	80003292 <usertrap+0xd6>

00000000800032b0 <kerneltrap>:
{
    800032b0:	7179                	addi	sp,sp,-48
    800032b2:	f406                	sd	ra,40(sp)
    800032b4:	f022                	sd	s0,32(sp)
    800032b6:	ec26                	sd	s1,24(sp)
    800032b8:	e84a                	sd	s2,16(sp)
    800032ba:	e44e                	sd	s3,8(sp)
    800032bc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032be:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032c2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032c6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800032ca:	1004f793          	andi	a5,s1,256
    800032ce:	cb85                	beqz	a5,800032fe <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800032d4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800032d6:	ef85                	bnez	a5,8000330e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	e42080e7          	jalr	-446(ra) # 8000311a <devintr>
    800032e0:	cd1d                	beqz	a0,8000331e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032e2:	4789                	li	a5,2
    800032e4:	06f50a63          	beq	a0,a5,80003358 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032e8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032ec:	10049073          	csrw	sstatus,s1
}
    800032f0:	70a2                	ld	ra,40(sp)
    800032f2:	7402                	ld	s0,32(sp)
    800032f4:	64e2                	ld	s1,24(sp)
    800032f6:	6942                	ld	s2,16(sp)
    800032f8:	69a2                	ld	s3,8(sp)
    800032fa:	6145                	addi	sp,sp,48
    800032fc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032fe:	00005517          	auipc	a0,0x5
    80003302:	16250513          	addi	a0,a0,354 # 80008460 <states.1812+0xc8>
    80003306:	ffffd097          	auipc	ra,0xffffd
    8000330a:	238080e7          	jalr	568(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000330e:	00005517          	auipc	a0,0x5
    80003312:	17a50513          	addi	a0,a0,378 # 80008488 <states.1812+0xf0>
    80003316:	ffffd097          	auipc	ra,0xffffd
    8000331a:	228080e7          	jalr	552(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000331e:	85ce                	mv	a1,s3
    80003320:	00005517          	auipc	a0,0x5
    80003324:	18850513          	addi	a0,a0,392 # 800084a8 <states.1812+0x110>
    80003328:	ffffd097          	auipc	ra,0xffffd
    8000332c:	260080e7          	jalr	608(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003330:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003334:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	18050513          	addi	a0,a0,384 # 800084b8 <states.1812+0x120>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	248080e7          	jalr	584(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003348:	00005517          	auipc	a0,0x5
    8000334c:	18850513          	addi	a0,a0,392 # 800084d0 <states.1812+0x138>
    80003350:	ffffd097          	auipc	ra,0xffffd
    80003354:	1ee080e7          	jalr	494(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003358:	fffff097          	auipc	ra,0xfffff
    8000335c:	c5a080e7          	jalr	-934(ra) # 80001fb2 <myproc>
    80003360:	d541                	beqz	a0,800032e8 <kerneltrap+0x38>
    80003362:	fffff097          	auipc	ra,0xfffff
    80003366:	c50080e7          	jalr	-944(ra) # 80001fb2 <myproc>
    8000336a:	4d18                	lw	a4,24(a0)
    8000336c:	4791                	li	a5,4
    8000336e:	f6f71de3          	bne	a4,a5,800032e8 <kerneltrap+0x38>
    yield();
    80003372:	fffff097          	auipc	ra,0xfffff
    80003376:	4c0080e7          	jalr	1216(ra) # 80002832 <yield>
    8000337a:	b7bd                	j	800032e8 <kerneltrap+0x38>

000000008000337c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	1000                	addi	s0,sp,32
    80003386:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003388:	fffff097          	auipc	ra,0xfffff
    8000338c:	c2a080e7          	jalr	-982(ra) # 80001fb2 <myproc>
  switch (n) {
    80003390:	4795                	li	a5,5
    80003392:	0497e163          	bltu	a5,s1,800033d4 <argraw+0x58>
    80003396:	048a                	slli	s1,s1,0x2
    80003398:	00005717          	auipc	a4,0x5
    8000339c:	17070713          	addi	a4,a4,368 # 80008508 <states.1812+0x170>
    800033a0:	94ba                	add	s1,s1,a4
    800033a2:	409c                	lw	a5,0(s1)
    800033a4:	97ba                	add	a5,a5,a4
    800033a6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800033a8:	7d3c                	ld	a5,120(a0)
    800033aa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800033ac:	60e2                	ld	ra,24(sp)
    800033ae:	6442                	ld	s0,16(sp)
    800033b0:	64a2                	ld	s1,8(sp)
    800033b2:	6105                	addi	sp,sp,32
    800033b4:	8082                	ret
    return p->trapframe->a1;
    800033b6:	7d3c                	ld	a5,120(a0)
    800033b8:	7fa8                	ld	a0,120(a5)
    800033ba:	bfcd                	j	800033ac <argraw+0x30>
    return p->trapframe->a2;
    800033bc:	7d3c                	ld	a5,120(a0)
    800033be:	63c8                	ld	a0,128(a5)
    800033c0:	b7f5                	j	800033ac <argraw+0x30>
    return p->trapframe->a3;
    800033c2:	7d3c                	ld	a5,120(a0)
    800033c4:	67c8                	ld	a0,136(a5)
    800033c6:	b7dd                	j	800033ac <argraw+0x30>
    return p->trapframe->a4;
    800033c8:	7d3c                	ld	a5,120(a0)
    800033ca:	6bc8                	ld	a0,144(a5)
    800033cc:	b7c5                	j	800033ac <argraw+0x30>
    return p->trapframe->a5;
    800033ce:	7d3c                	ld	a5,120(a0)
    800033d0:	6fc8                	ld	a0,152(a5)
    800033d2:	bfe9                	j	800033ac <argraw+0x30>
  panic("argraw");
    800033d4:	00005517          	auipc	a0,0x5
    800033d8:	10c50513          	addi	a0,a0,268 # 800084e0 <states.1812+0x148>
    800033dc:	ffffd097          	auipc	ra,0xffffd
    800033e0:	162080e7          	jalr	354(ra) # 8000053e <panic>

00000000800033e4 <fetchaddr>:
{
    800033e4:	1101                	addi	sp,sp,-32
    800033e6:	ec06                	sd	ra,24(sp)
    800033e8:	e822                	sd	s0,16(sp)
    800033ea:	e426                	sd	s1,8(sp)
    800033ec:	e04a                	sd	s2,0(sp)
    800033ee:	1000                	addi	s0,sp,32
    800033f0:	84aa                	mv	s1,a0
    800033f2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033f4:	fffff097          	auipc	ra,0xfffff
    800033f8:	bbe080e7          	jalr	-1090(ra) # 80001fb2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033fc:	753c                	ld	a5,104(a0)
    800033fe:	02f4f863          	bgeu	s1,a5,8000342e <fetchaddr+0x4a>
    80003402:	00848713          	addi	a4,s1,8
    80003406:	02e7e663          	bltu	a5,a4,80003432 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000340a:	46a1                	li	a3,8
    8000340c:	8626                	mv	a2,s1
    8000340e:	85ca                	mv	a1,s2
    80003410:	7928                	ld	a0,112(a0)
    80003412:	ffffe097          	auipc	ra,0xffffe
    80003416:	310080e7          	jalr	784(ra) # 80001722 <copyin>
    8000341a:	00a03533          	snez	a0,a0
    8000341e:	40a00533          	neg	a0,a0
}
    80003422:	60e2                	ld	ra,24(sp)
    80003424:	6442                	ld	s0,16(sp)
    80003426:	64a2                	ld	s1,8(sp)
    80003428:	6902                	ld	s2,0(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret
    return -1;
    8000342e:	557d                	li	a0,-1
    80003430:	bfcd                	j	80003422 <fetchaddr+0x3e>
    80003432:	557d                	li	a0,-1
    80003434:	b7fd                	j	80003422 <fetchaddr+0x3e>

0000000080003436 <fetchstr>:
{
    80003436:	7179                	addi	sp,sp,-48
    80003438:	f406                	sd	ra,40(sp)
    8000343a:	f022                	sd	s0,32(sp)
    8000343c:	ec26                	sd	s1,24(sp)
    8000343e:	e84a                	sd	s2,16(sp)
    80003440:	e44e                	sd	s3,8(sp)
    80003442:	1800                	addi	s0,sp,48
    80003444:	892a                	mv	s2,a0
    80003446:	84ae                	mv	s1,a1
    80003448:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000344a:	fffff097          	auipc	ra,0xfffff
    8000344e:	b68080e7          	jalr	-1176(ra) # 80001fb2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003452:	86ce                	mv	a3,s3
    80003454:	864a                	mv	a2,s2
    80003456:	85a6                	mv	a1,s1
    80003458:	7928                	ld	a0,112(a0)
    8000345a:	ffffe097          	auipc	ra,0xffffe
    8000345e:	354080e7          	jalr	852(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003462:	00054763          	bltz	a0,80003470 <fetchstr+0x3a>
  return strlen(buf);
    80003466:	8526                	mv	a0,s1
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	a20080e7          	jalr	-1504(ra) # 80000e88 <strlen>
}
    80003470:	70a2                	ld	ra,40(sp)
    80003472:	7402                	ld	s0,32(sp)
    80003474:	64e2                	ld	s1,24(sp)
    80003476:	6942                	ld	s2,16(sp)
    80003478:	69a2                	ld	s3,8(sp)
    8000347a:	6145                	addi	sp,sp,48
    8000347c:	8082                	ret

000000008000347e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000347e:	1101                	addi	sp,sp,-32
    80003480:	ec06                	sd	ra,24(sp)
    80003482:	e822                	sd	s0,16(sp)
    80003484:	e426                	sd	s1,8(sp)
    80003486:	1000                	addi	s0,sp,32
    80003488:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	ef2080e7          	jalr	-270(ra) # 8000337c <argraw>
    80003492:	c088                	sw	a0,0(s1)
  return 0;
}
    80003494:	4501                	li	a0,0
    80003496:	60e2                	ld	ra,24(sp)
    80003498:	6442                	ld	s0,16(sp)
    8000349a:	64a2                	ld	s1,8(sp)
    8000349c:	6105                	addi	sp,sp,32
    8000349e:	8082                	ret

00000000800034a0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800034a0:	1101                	addi	sp,sp,-32
    800034a2:	ec06                	sd	ra,24(sp)
    800034a4:	e822                	sd	s0,16(sp)
    800034a6:	e426                	sd	s1,8(sp)
    800034a8:	1000                	addi	s0,sp,32
    800034aa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	ed0080e7          	jalr	-304(ra) # 8000337c <argraw>
    800034b4:	e088                	sd	a0,0(s1)
  return 0;
}
    800034b6:	4501                	li	a0,0
    800034b8:	60e2                	ld	ra,24(sp)
    800034ba:	6442                	ld	s0,16(sp)
    800034bc:	64a2                	ld	s1,8(sp)
    800034be:	6105                	addi	sp,sp,32
    800034c0:	8082                	ret

00000000800034c2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800034c2:	1101                	addi	sp,sp,-32
    800034c4:	ec06                	sd	ra,24(sp)
    800034c6:	e822                	sd	s0,16(sp)
    800034c8:	e426                	sd	s1,8(sp)
    800034ca:	e04a                	sd	s2,0(sp)
    800034cc:	1000                	addi	s0,sp,32
    800034ce:	84ae                	mv	s1,a1
    800034d0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	eaa080e7          	jalr	-342(ra) # 8000337c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800034da:	864a                	mv	a2,s2
    800034dc:	85a6                	mv	a1,s1
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	f58080e7          	jalr	-168(ra) # 80003436 <fetchstr>
}
    800034e6:	60e2                	ld	ra,24(sp)
    800034e8:	6442                	ld	s0,16(sp)
    800034ea:	64a2                	ld	s1,8(sp)
    800034ec:	6902                	ld	s2,0(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret

00000000800034f2 <syscall>:
[SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    800034f2:	1101                	addi	sp,sp,-32
    800034f4:	ec06                	sd	ra,24(sp)
    800034f6:	e822                	sd	s0,16(sp)
    800034f8:	e426                	sd	s1,8(sp)
    800034fa:	e04a                	sd	s2,0(sp)
    800034fc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034fe:	fffff097          	auipc	ra,0xfffff
    80003502:	ab4080e7          	jalr	-1356(ra) # 80001fb2 <myproc>
    80003506:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003508:	07853903          	ld	s2,120(a0)
    8000350c:	0a893783          	ld	a5,168(s2)
    80003510:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003514:	37fd                	addiw	a5,a5,-1
    80003516:	475d                	li	a4,23
    80003518:	00f76f63          	bltu	a4,a5,80003536 <syscall+0x44>
    8000351c:	00369713          	slli	a4,a3,0x3
    80003520:	00005797          	auipc	a5,0x5
    80003524:	00078793          	mv	a5,a5
    80003528:	97ba                	add	a5,a5,a4
    8000352a:	639c                	ld	a5,0(a5)
    8000352c:	c789                	beqz	a5,80003536 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000352e:	9782                	jalr	a5
    80003530:	06a93823          	sd	a0,112(s2)
    80003534:	a839                	j	80003552 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003536:	17848613          	addi	a2,s1,376
    8000353a:	588c                	lw	a1,48(s1)
    8000353c:	00005517          	auipc	a0,0x5
    80003540:	fac50513          	addi	a0,a0,-84 # 800084e8 <states.1812+0x150>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	044080e7          	jalr	68(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000354c:	7cbc                	ld	a5,120(s1)
    8000354e:	577d                	li	a4,-1
    80003550:	fbb8                	sd	a4,112(a5)
  }
}
    80003552:	60e2                	ld	ra,24(sp)
    80003554:	6442                	ld	s0,16(sp)
    80003556:	64a2                	ld	s1,8(sp)
    80003558:	6902                	ld	s2,0(sp)
    8000355a:	6105                	addi	sp,sp,32
    8000355c:	8082                	ret

000000008000355e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000355e:	1101                	addi	sp,sp,-32
    80003560:	ec06                	sd	ra,24(sp)
    80003562:	e822                	sd	s0,16(sp)
    80003564:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003566:	fec40593          	addi	a1,s0,-20
    8000356a:	4501                	li	a0,0
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	f12080e7          	jalr	-238(ra) # 8000347e <argint>
    return -1;
    80003574:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003576:	00054963          	bltz	a0,80003588 <sys_exit+0x2a>
  exit(n);
    8000357a:	fec42503          	lw	a0,-20(s0)
    8000357e:	fffff097          	auipc	ra,0xfffff
    80003582:	66a080e7          	jalr	1642(ra) # 80002be8 <exit>
  return 0;  // not reached
    80003586:	4781                	li	a5,0
}
    80003588:	853e                	mv	a0,a5
    8000358a:	60e2                	ld	ra,24(sp)
    8000358c:	6442                	ld	s0,16(sp)
    8000358e:	6105                	addi	sp,sp,32
    80003590:	8082                	ret

0000000080003592 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003592:	1141                	addi	sp,sp,-16
    80003594:	e406                	sd	ra,8(sp)
    80003596:	e022                	sd	s0,0(sp)
    80003598:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000359a:	fffff097          	auipc	ra,0xfffff
    8000359e:	a18080e7          	jalr	-1512(ra) # 80001fb2 <myproc>
}
    800035a2:	5908                	lw	a0,48(a0)
    800035a4:	60a2                	ld	ra,8(sp)
    800035a6:	6402                	ld	s0,0(sp)
    800035a8:	0141                	addi	sp,sp,16
    800035aa:	8082                	ret

00000000800035ac <sys_fork>:

uint64
sys_fork(void)
{
    800035ac:	1141                	addi	sp,sp,-16
    800035ae:	e406                	sd	ra,8(sp)
    800035b0:	e022                	sd	s0,0(sp)
    800035b2:	0800                	addi	s0,sp,16
  return fork();
    800035b4:	fffff097          	auipc	ra,0xfffff
    800035b8:	eb6080e7          	jalr	-330(ra) # 8000246a <fork>
}
    800035bc:	60a2                	ld	ra,8(sp)
    800035be:	6402                	ld	s0,0(sp)
    800035c0:	0141                	addi	sp,sp,16
    800035c2:	8082                	ret

00000000800035c4 <sys_wait>:

uint64
sys_wait(void)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800035cc:	fe840593          	addi	a1,s0,-24
    800035d0:	4501                	li	a0,0
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	ece080e7          	jalr	-306(ra) # 800034a0 <argaddr>
    800035da:	87aa                	mv	a5,a0
    return -1;
    800035dc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800035de:	0007c863          	bltz	a5,800035ee <sys_wait+0x2a>
  return wait(p);
    800035e2:	fe843503          	ld	a0,-24(s0)
    800035e6:	fffff097          	auipc	ra,0xfffff
    800035ea:	342080e7          	jalr	834(ra) # 80002928 <wait>
}
    800035ee:	60e2                	ld	ra,24(sp)
    800035f0:	6442                	ld	s0,16(sp)
    800035f2:	6105                	addi	sp,sp,32
    800035f4:	8082                	ret

00000000800035f6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035f6:	7179                	addi	sp,sp,-48
    800035f8:	f406                	sd	ra,40(sp)
    800035fa:	f022                	sd	s0,32(sp)
    800035fc:	ec26                	sd	s1,24(sp)
    800035fe:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003600:	fdc40593          	addi	a1,s0,-36
    80003604:	4501                	li	a0,0
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	e78080e7          	jalr	-392(ra) # 8000347e <argint>
    8000360e:	87aa                	mv	a5,a0
    return -1;
    80003610:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003612:	0207c063          	bltz	a5,80003632 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003616:	fffff097          	auipc	ra,0xfffff
    8000361a:	99c080e7          	jalr	-1636(ra) # 80001fb2 <myproc>
    8000361e:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003620:	fdc42503          	lw	a0,-36(s0)
    80003624:	fffff097          	auipc	ra,0xfffff
    80003628:	dd2080e7          	jalr	-558(ra) # 800023f6 <growproc>
    8000362c:	00054863          	bltz	a0,8000363c <sys_sbrk+0x46>
    return -1;
  return addr;
    80003630:	8526                	mv	a0,s1
}
    80003632:	70a2                	ld	ra,40(sp)
    80003634:	7402                	ld	s0,32(sp)
    80003636:	64e2                	ld	s1,24(sp)
    80003638:	6145                	addi	sp,sp,48
    8000363a:	8082                	ret
    return -1;
    8000363c:	557d                	li	a0,-1
    8000363e:	bfd5                	j	80003632 <sys_sbrk+0x3c>

0000000080003640 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003640:	7139                	addi	sp,sp,-64
    80003642:	fc06                	sd	ra,56(sp)
    80003644:	f822                	sd	s0,48(sp)
    80003646:	f426                	sd	s1,40(sp)
    80003648:	f04a                	sd	s2,32(sp)
    8000364a:	ec4e                	sd	s3,24(sp)
    8000364c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000364e:	fcc40593          	addi	a1,s0,-52
    80003652:	4501                	li	a0,0
    80003654:	00000097          	auipc	ra,0x0
    80003658:	e2a080e7          	jalr	-470(ra) # 8000347e <argint>
    return -1;
    8000365c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000365e:	06054563          	bltz	a0,800036c8 <sys_sleep+0x88>
  acquire(&tickslock);
    80003662:	00014517          	auipc	a0,0x14
    80003666:	41650513          	addi	a0,a0,1046 # 80017a78 <tickslock>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	57a080e7          	jalr	1402(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003672:	00006917          	auipc	s2,0x6
    80003676:	9be92903          	lw	s2,-1602(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000367a:	fcc42783          	lw	a5,-52(s0)
    8000367e:	cf85                	beqz	a5,800036b6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003680:	00014997          	auipc	s3,0x14
    80003684:	3f898993          	addi	s3,s3,1016 # 80017a78 <tickslock>
    80003688:	00006497          	auipc	s1,0x6
    8000368c:	9a848493          	addi	s1,s1,-1624 # 80009030 <ticks>
    if(myproc()->killed){
    80003690:	fffff097          	auipc	ra,0xfffff
    80003694:	922080e7          	jalr	-1758(ra) # 80001fb2 <myproc>
    80003698:	551c                	lw	a5,40(a0)
    8000369a:	ef9d                	bnez	a5,800036d8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000369c:	85ce                	mv	a1,s3
    8000369e:	8526                	mv	a0,s1
    800036a0:	fffff097          	auipc	ra,0xfffff
    800036a4:	1f8080e7          	jalr	504(ra) # 80002898 <sleep>
  while(ticks - ticks0 < n){
    800036a8:	409c                	lw	a5,0(s1)
    800036aa:	412787bb          	subw	a5,a5,s2
    800036ae:	fcc42703          	lw	a4,-52(s0)
    800036b2:	fce7efe3          	bltu	a5,a4,80003690 <sys_sleep+0x50>
  }
  release(&tickslock);
    800036b6:	00014517          	auipc	a0,0x14
    800036ba:	3c250513          	addi	a0,a0,962 # 80017a78 <tickslock>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	5ec080e7          	jalr	1516(ra) # 80000caa <release>
  return 0;
    800036c6:	4781                	li	a5,0
}
    800036c8:	853e                	mv	a0,a5
    800036ca:	70e2                	ld	ra,56(sp)
    800036cc:	7442                	ld	s0,48(sp)
    800036ce:	74a2                	ld	s1,40(sp)
    800036d0:	7902                	ld	s2,32(sp)
    800036d2:	69e2                	ld	s3,24(sp)
    800036d4:	6121                	addi	sp,sp,64
    800036d6:	8082                	ret
      release(&tickslock);
    800036d8:	00014517          	auipc	a0,0x14
    800036dc:	3a050513          	addi	a0,a0,928 # 80017a78 <tickslock>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	5ca080e7          	jalr	1482(ra) # 80000caa <release>
      return -1;
    800036e8:	57fd                	li	a5,-1
    800036ea:	bff9                	j	800036c8 <sys_sleep+0x88>

00000000800036ec <sys_kill>:

uint64
sys_kill(void)
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036f4:	fec40593          	addi	a1,s0,-20
    800036f8:	4501                	li	a0,0
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	d84080e7          	jalr	-636(ra) # 8000347e <argint>
    80003702:	87aa                	mv	a5,a0
    return -1;
    80003704:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003706:	0007c863          	bltz	a5,80003716 <sys_kill+0x2a>
  return kill(pid);
    8000370a:	fec42503          	lw	a0,-20(s0)
    8000370e:	fffff097          	auipc	ra,0xfffff
    80003712:	5cc080e7          	jalr	1484(ra) # 80002cda <kill>
}
    80003716:	60e2                	ld	ra,24(sp)
    80003718:	6442                	ld	s0,16(sp)
    8000371a:	6105                	addi	sp,sp,32
    8000371c:	8082                	ret

000000008000371e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000371e:	1101                	addi	sp,sp,-32
    80003720:	ec06                	sd	ra,24(sp)
    80003722:	e822                	sd	s0,16(sp)
    80003724:	e426                	sd	s1,8(sp)
    80003726:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003728:	00014517          	auipc	a0,0x14
    8000372c:	35050513          	addi	a0,a0,848 # 80017a78 <tickslock>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	4b4080e7          	jalr	1204(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003738:	00006497          	auipc	s1,0x6
    8000373c:	8f84a483          	lw	s1,-1800(s1) # 80009030 <ticks>
  release(&tickslock);
    80003740:	00014517          	auipc	a0,0x14
    80003744:	33850513          	addi	a0,a0,824 # 80017a78 <tickslock>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	562080e7          	jalr	1378(ra) # 80000caa <release>
  return xticks;
}
    80003750:	02049513          	slli	a0,s1,0x20
    80003754:	9101                	srli	a0,a0,0x20
    80003756:	60e2                	ld	ra,24(sp)
    80003758:	6442                	ld	s0,16(sp)
    8000375a:	64a2                	ld	s1,8(sp)
    8000375c:	6105                	addi	sp,sp,32
    8000375e:	8082                	ret

0000000080003760 <sys_get_cpu>:

uint64
sys_get_cpu(void){
    80003760:	1141                	addi	sp,sp,-16
    80003762:	e406                	sd	ra,8(sp)
    80003764:	e022                	sd	s0,0(sp)
    80003766:	0800                	addi	s0,sp,16
  return get_cpu();
    80003768:	fffff097          	auipc	ra,0xfffff
    8000376c:	7d2080e7          	jalr	2002(ra) # 80002f3a <get_cpu>
}
    80003770:	60a2                	ld	ra,8(sp)
    80003772:	6402                	ld	s0,0(sp)
    80003774:	0141                	addi	sp,sp,16
    80003776:	8082                	ret

0000000080003778 <sys_set_cpu>:

uint64
sys_set_cpu(void){
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80003780:	fec40593          	addi	a1,s0,-20
    80003784:	4501                	li	a0,0
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	cf8080e7          	jalr	-776(ra) # 8000347e <argint>
    8000378e:	87aa                	mv	a5,a0
    return -1;
    80003790:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80003792:	0007c863          	bltz	a5,800037a2 <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    80003796:	fec42503          	lw	a0,-20(s0)
    8000379a:	fffff097          	auipc	ra,0xfffff
    8000379e:	762080e7          	jalr	1890(ra) # 80002efc <set_cpu>
}
    800037a2:	60e2                	ld	ra,24(sp)
    800037a4:	6442                	ld	s0,16(sp)
    800037a6:	6105                	addi	sp,sp,32
    800037a8:	8082                	ret

00000000800037aa <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    800037aa:	1101                	addi	sp,sp,-32
    800037ac:	ec06                	sd	ra,24(sp)
    800037ae:	e822                	sd	s0,16(sp)
    800037b0:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    800037b2:	fec40593          	addi	a1,s0,-20
    800037b6:	4501                	li	a0,0
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	cc6080e7          	jalr	-826(ra) # 8000347e <argint>
    800037c0:	87aa                	mv	a5,a0
    return -1;
    800037c2:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    800037c4:	0007c863          	bltz	a5,800037d4 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_num);
    800037c8:	fec42503          	lw	a0,-20(s0)
    800037cc:	fffff097          	auipc	ra,0xfffff
    800037d0:	79e080e7          	jalr	1950(ra) # 80002f6a <cpu_process_count>
}
    800037d4:	60e2                	ld	ra,24(sp)
    800037d6:	6442                	ld	s0,16(sp)
    800037d8:	6105                	addi	sp,sp,32
    800037da:	8082                	ret

00000000800037dc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800037dc:	7179                	addi	sp,sp,-48
    800037de:	f406                	sd	ra,40(sp)
    800037e0:	f022                	sd	s0,32(sp)
    800037e2:	ec26                	sd	s1,24(sp)
    800037e4:	e84a                	sd	s2,16(sp)
    800037e6:	e44e                	sd	s3,8(sp)
    800037e8:	e052                	sd	s4,0(sp)
    800037ea:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800037ec:	00005597          	auipc	a1,0x5
    800037f0:	dfc58593          	addi	a1,a1,-516 # 800085e8 <syscalls+0xc8>
    800037f4:	00014517          	auipc	a0,0x14
    800037f8:	29c50513          	addi	a0,a0,668 # 80017a90 <bcache>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	358080e7          	jalr	856(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003804:	0001c797          	auipc	a5,0x1c
    80003808:	28c78793          	addi	a5,a5,652 # 8001fa90 <bcache+0x8000>
    8000380c:	0001c717          	auipc	a4,0x1c
    80003810:	4ec70713          	addi	a4,a4,1260 # 8001fcf8 <bcache+0x8268>
    80003814:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003818:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000381c:	00014497          	auipc	s1,0x14
    80003820:	28c48493          	addi	s1,s1,652 # 80017aa8 <bcache+0x18>
    b->next = bcache.head.next;
    80003824:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003826:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003828:	00005a17          	auipc	s4,0x5
    8000382c:	dc8a0a13          	addi	s4,s4,-568 # 800085f0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003830:	2b893783          	ld	a5,696(s2)
    80003834:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003836:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000383a:	85d2                	mv	a1,s4
    8000383c:	01048513          	addi	a0,s1,16
    80003840:	00001097          	auipc	ra,0x1
    80003844:	4bc080e7          	jalr	1212(ra) # 80004cfc <initsleeplock>
    bcache.head.next->prev = b;
    80003848:	2b893783          	ld	a5,696(s2)
    8000384c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000384e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003852:	45848493          	addi	s1,s1,1112
    80003856:	fd349de3          	bne	s1,s3,80003830 <binit+0x54>
  }
}
    8000385a:	70a2                	ld	ra,40(sp)
    8000385c:	7402                	ld	s0,32(sp)
    8000385e:	64e2                	ld	s1,24(sp)
    80003860:	6942                	ld	s2,16(sp)
    80003862:	69a2                	ld	s3,8(sp)
    80003864:	6a02                	ld	s4,0(sp)
    80003866:	6145                	addi	sp,sp,48
    80003868:	8082                	ret

000000008000386a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000386a:	7179                	addi	sp,sp,-48
    8000386c:	f406                	sd	ra,40(sp)
    8000386e:	f022                	sd	s0,32(sp)
    80003870:	ec26                	sd	s1,24(sp)
    80003872:	e84a                	sd	s2,16(sp)
    80003874:	e44e                	sd	s3,8(sp)
    80003876:	1800                	addi	s0,sp,48
    80003878:	89aa                	mv	s3,a0
    8000387a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000387c:	00014517          	auipc	a0,0x14
    80003880:	21450513          	addi	a0,a0,532 # 80017a90 <bcache>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	360080e7          	jalr	864(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000388c:	0001c497          	auipc	s1,0x1c
    80003890:	4bc4b483          	ld	s1,1212(s1) # 8001fd48 <bcache+0x82b8>
    80003894:	0001c797          	auipc	a5,0x1c
    80003898:	46478793          	addi	a5,a5,1124 # 8001fcf8 <bcache+0x8268>
    8000389c:	02f48f63          	beq	s1,a5,800038da <bread+0x70>
    800038a0:	873e                	mv	a4,a5
    800038a2:	a021                	j	800038aa <bread+0x40>
    800038a4:	68a4                	ld	s1,80(s1)
    800038a6:	02e48a63          	beq	s1,a4,800038da <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800038aa:	449c                	lw	a5,8(s1)
    800038ac:	ff379ce3          	bne	a5,s3,800038a4 <bread+0x3a>
    800038b0:	44dc                	lw	a5,12(s1)
    800038b2:	ff2799e3          	bne	a5,s2,800038a4 <bread+0x3a>
      b->refcnt++;
    800038b6:	40bc                	lw	a5,64(s1)
    800038b8:	2785                	addiw	a5,a5,1
    800038ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038bc:	00014517          	auipc	a0,0x14
    800038c0:	1d450513          	addi	a0,a0,468 # 80017a90 <bcache>
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	3e6080e7          	jalr	998(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    800038cc:	01048513          	addi	a0,s1,16
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	466080e7          	jalr	1126(ra) # 80004d36 <acquiresleep>
      return b;
    800038d8:	a8b9                	j	80003936 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038da:	0001c497          	auipc	s1,0x1c
    800038de:	4664b483          	ld	s1,1126(s1) # 8001fd40 <bcache+0x82b0>
    800038e2:	0001c797          	auipc	a5,0x1c
    800038e6:	41678793          	addi	a5,a5,1046 # 8001fcf8 <bcache+0x8268>
    800038ea:	00f48863          	beq	s1,a5,800038fa <bread+0x90>
    800038ee:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800038f0:	40bc                	lw	a5,64(s1)
    800038f2:	cf81                	beqz	a5,8000390a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038f4:	64a4                	ld	s1,72(s1)
    800038f6:	fee49de3          	bne	s1,a4,800038f0 <bread+0x86>
  panic("bget: no buffers");
    800038fa:	00005517          	auipc	a0,0x5
    800038fe:	cfe50513          	addi	a0,a0,-770 # 800085f8 <syscalls+0xd8>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	c3c080e7          	jalr	-964(ra) # 8000053e <panic>
      b->dev = dev;
    8000390a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000390e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003912:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003916:	4785                	li	a5,1
    80003918:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000391a:	00014517          	auipc	a0,0x14
    8000391e:	17650513          	addi	a0,a0,374 # 80017a90 <bcache>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	388080e7          	jalr	904(ra) # 80000caa <release>
      acquiresleep(&b->lock);
    8000392a:	01048513          	addi	a0,s1,16
    8000392e:	00001097          	auipc	ra,0x1
    80003932:	408080e7          	jalr	1032(ra) # 80004d36 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003936:	409c                	lw	a5,0(s1)
    80003938:	cb89                	beqz	a5,8000394a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000393a:	8526                	mv	a0,s1
    8000393c:	70a2                	ld	ra,40(sp)
    8000393e:	7402                	ld	s0,32(sp)
    80003940:	64e2                	ld	s1,24(sp)
    80003942:	6942                	ld	s2,16(sp)
    80003944:	69a2                	ld	s3,8(sp)
    80003946:	6145                	addi	sp,sp,48
    80003948:	8082                	ret
    virtio_disk_rw(b, 0);
    8000394a:	4581                	li	a1,0
    8000394c:	8526                	mv	a0,s1
    8000394e:	00003097          	auipc	ra,0x3
    80003952:	f08080e7          	jalr	-248(ra) # 80006856 <virtio_disk_rw>
    b->valid = 1;
    80003956:	4785                	li	a5,1
    80003958:	c09c                	sw	a5,0(s1)
  return b;
    8000395a:	b7c5                	j	8000393a <bread+0xd0>

000000008000395c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000395c:	1101                	addi	sp,sp,-32
    8000395e:	ec06                	sd	ra,24(sp)
    80003960:	e822                	sd	s0,16(sp)
    80003962:	e426                	sd	s1,8(sp)
    80003964:	1000                	addi	s0,sp,32
    80003966:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003968:	0541                	addi	a0,a0,16
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	466080e7          	jalr	1126(ra) # 80004dd0 <holdingsleep>
    80003972:	cd01                	beqz	a0,8000398a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003974:	4585                	li	a1,1
    80003976:	8526                	mv	a0,s1
    80003978:	00003097          	auipc	ra,0x3
    8000397c:	ede080e7          	jalr	-290(ra) # 80006856 <virtio_disk_rw>
}
    80003980:	60e2                	ld	ra,24(sp)
    80003982:	6442                	ld	s0,16(sp)
    80003984:	64a2                	ld	s1,8(sp)
    80003986:	6105                	addi	sp,sp,32
    80003988:	8082                	ret
    panic("bwrite");
    8000398a:	00005517          	auipc	a0,0x5
    8000398e:	c8650513          	addi	a0,a0,-890 # 80008610 <syscalls+0xf0>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	bac080e7          	jalr	-1108(ra) # 8000053e <panic>

000000008000399a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000399a:	1101                	addi	sp,sp,-32
    8000399c:	ec06                	sd	ra,24(sp)
    8000399e:	e822                	sd	s0,16(sp)
    800039a0:	e426                	sd	s1,8(sp)
    800039a2:	e04a                	sd	s2,0(sp)
    800039a4:	1000                	addi	s0,sp,32
    800039a6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039a8:	01050913          	addi	s2,a0,16
    800039ac:	854a                	mv	a0,s2
    800039ae:	00001097          	auipc	ra,0x1
    800039b2:	422080e7          	jalr	1058(ra) # 80004dd0 <holdingsleep>
    800039b6:	c92d                	beqz	a0,80003a28 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	3d2080e7          	jalr	978(ra) # 80004d8c <releasesleep>

  acquire(&bcache.lock);
    800039c2:	00014517          	auipc	a0,0x14
    800039c6:	0ce50513          	addi	a0,a0,206 # 80017a90 <bcache>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	21a080e7          	jalr	538(ra) # 80000be4 <acquire>
  b->refcnt--;
    800039d2:	40bc                	lw	a5,64(s1)
    800039d4:	37fd                	addiw	a5,a5,-1
    800039d6:	0007871b          	sext.w	a4,a5
    800039da:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800039dc:	eb05                	bnez	a4,80003a0c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800039de:	68bc                	ld	a5,80(s1)
    800039e0:	64b8                	ld	a4,72(s1)
    800039e2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800039e4:	64bc                	ld	a5,72(s1)
    800039e6:	68b8                	ld	a4,80(s1)
    800039e8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800039ea:	0001c797          	auipc	a5,0x1c
    800039ee:	0a678793          	addi	a5,a5,166 # 8001fa90 <bcache+0x8000>
    800039f2:	2b87b703          	ld	a4,696(a5)
    800039f6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800039f8:	0001c717          	auipc	a4,0x1c
    800039fc:	30070713          	addi	a4,a4,768 # 8001fcf8 <bcache+0x8268>
    80003a00:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003a02:	2b87b703          	ld	a4,696(a5)
    80003a06:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003a08:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003a0c:	00014517          	auipc	a0,0x14
    80003a10:	08450513          	addi	a0,a0,132 # 80017a90 <bcache>
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	296080e7          	jalr	662(ra) # 80000caa <release>
}
    80003a1c:	60e2                	ld	ra,24(sp)
    80003a1e:	6442                	ld	s0,16(sp)
    80003a20:	64a2                	ld	s1,8(sp)
    80003a22:	6902                	ld	s2,0(sp)
    80003a24:	6105                	addi	sp,sp,32
    80003a26:	8082                	ret
    panic("brelse");
    80003a28:	00005517          	auipc	a0,0x5
    80003a2c:	bf050513          	addi	a0,a0,-1040 # 80008618 <syscalls+0xf8>
    80003a30:	ffffd097          	auipc	ra,0xffffd
    80003a34:	b0e080e7          	jalr	-1266(ra) # 8000053e <panic>

0000000080003a38 <bpin>:

void
bpin(struct buf *b) {
    80003a38:	1101                	addi	sp,sp,-32
    80003a3a:	ec06                	sd	ra,24(sp)
    80003a3c:	e822                	sd	s0,16(sp)
    80003a3e:	e426                	sd	s1,8(sp)
    80003a40:	1000                	addi	s0,sp,32
    80003a42:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a44:	00014517          	auipc	a0,0x14
    80003a48:	04c50513          	addi	a0,a0,76 # 80017a90 <bcache>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	198080e7          	jalr	408(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003a54:	40bc                	lw	a5,64(s1)
    80003a56:	2785                	addiw	a5,a5,1
    80003a58:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a5a:	00014517          	auipc	a0,0x14
    80003a5e:	03650513          	addi	a0,a0,54 # 80017a90 <bcache>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	248080e7          	jalr	584(ra) # 80000caa <release>
}
    80003a6a:	60e2                	ld	ra,24(sp)
    80003a6c:	6442                	ld	s0,16(sp)
    80003a6e:	64a2                	ld	s1,8(sp)
    80003a70:	6105                	addi	sp,sp,32
    80003a72:	8082                	ret

0000000080003a74 <bunpin>:

void
bunpin(struct buf *b) {
    80003a74:	1101                	addi	sp,sp,-32
    80003a76:	ec06                	sd	ra,24(sp)
    80003a78:	e822                	sd	s0,16(sp)
    80003a7a:	e426                	sd	s1,8(sp)
    80003a7c:	1000                	addi	s0,sp,32
    80003a7e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a80:	00014517          	auipc	a0,0x14
    80003a84:	01050513          	addi	a0,a0,16 # 80017a90 <bcache>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	15c080e7          	jalr	348(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003a90:	40bc                	lw	a5,64(s1)
    80003a92:	37fd                	addiw	a5,a5,-1
    80003a94:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a96:	00014517          	auipc	a0,0x14
    80003a9a:	ffa50513          	addi	a0,a0,-6 # 80017a90 <bcache>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	20c080e7          	jalr	524(ra) # 80000caa <release>
}
    80003aa6:	60e2                	ld	ra,24(sp)
    80003aa8:	6442                	ld	s0,16(sp)
    80003aaa:	64a2                	ld	s1,8(sp)
    80003aac:	6105                	addi	sp,sp,32
    80003aae:	8082                	ret

0000000080003ab0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003ab0:	1101                	addi	sp,sp,-32
    80003ab2:	ec06                	sd	ra,24(sp)
    80003ab4:	e822                	sd	s0,16(sp)
    80003ab6:	e426                	sd	s1,8(sp)
    80003ab8:	e04a                	sd	s2,0(sp)
    80003aba:	1000                	addi	s0,sp,32
    80003abc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003abe:	00d5d59b          	srliw	a1,a1,0xd
    80003ac2:	0001c797          	auipc	a5,0x1c
    80003ac6:	6aa7a783          	lw	a5,1706(a5) # 8002016c <sb+0x1c>
    80003aca:	9dbd                	addw	a1,a1,a5
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	d9e080e7          	jalr	-610(ra) # 8000386a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003ad4:	0074f713          	andi	a4,s1,7
    80003ad8:	4785                	li	a5,1
    80003ada:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003ade:	14ce                	slli	s1,s1,0x33
    80003ae0:	90d9                	srli	s1,s1,0x36
    80003ae2:	00950733          	add	a4,a0,s1
    80003ae6:	05874703          	lbu	a4,88(a4)
    80003aea:	00e7f6b3          	and	a3,a5,a4
    80003aee:	c69d                	beqz	a3,80003b1c <bfree+0x6c>
    80003af0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003af2:	94aa                	add	s1,s1,a0
    80003af4:	fff7c793          	not	a5,a5
    80003af8:	8ff9                	and	a5,a5,a4
    80003afa:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003afe:	00001097          	auipc	ra,0x1
    80003b02:	118080e7          	jalr	280(ra) # 80004c16 <log_write>
  brelse(bp);
    80003b06:	854a                	mv	a0,s2
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	e92080e7          	jalr	-366(ra) # 8000399a <brelse>
}
    80003b10:	60e2                	ld	ra,24(sp)
    80003b12:	6442                	ld	s0,16(sp)
    80003b14:	64a2                	ld	s1,8(sp)
    80003b16:	6902                	ld	s2,0(sp)
    80003b18:	6105                	addi	sp,sp,32
    80003b1a:	8082                	ret
    panic("freeing free block");
    80003b1c:	00005517          	auipc	a0,0x5
    80003b20:	b0450513          	addi	a0,a0,-1276 # 80008620 <syscalls+0x100>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	a1a080e7          	jalr	-1510(ra) # 8000053e <panic>

0000000080003b2c <balloc>:
{
    80003b2c:	711d                	addi	sp,sp,-96
    80003b2e:	ec86                	sd	ra,88(sp)
    80003b30:	e8a2                	sd	s0,80(sp)
    80003b32:	e4a6                	sd	s1,72(sp)
    80003b34:	e0ca                	sd	s2,64(sp)
    80003b36:	fc4e                	sd	s3,56(sp)
    80003b38:	f852                	sd	s4,48(sp)
    80003b3a:	f456                	sd	s5,40(sp)
    80003b3c:	f05a                	sd	s6,32(sp)
    80003b3e:	ec5e                	sd	s7,24(sp)
    80003b40:	e862                	sd	s8,16(sp)
    80003b42:	e466                	sd	s9,8(sp)
    80003b44:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b46:	0001c797          	auipc	a5,0x1c
    80003b4a:	60e7a783          	lw	a5,1550(a5) # 80020154 <sb+0x4>
    80003b4e:	cbd1                	beqz	a5,80003be2 <balloc+0xb6>
    80003b50:	8baa                	mv	s7,a0
    80003b52:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b54:	0001cb17          	auipc	s6,0x1c
    80003b58:	5fcb0b13          	addi	s6,s6,1532 # 80020150 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b5c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b5e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b60:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b62:	6c89                	lui	s9,0x2
    80003b64:	a831                	j	80003b80 <balloc+0x54>
    brelse(bp);
    80003b66:	854a                	mv	a0,s2
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	e32080e7          	jalr	-462(ra) # 8000399a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003b70:	015c87bb          	addw	a5,s9,s5
    80003b74:	00078a9b          	sext.w	s5,a5
    80003b78:	004b2703          	lw	a4,4(s6)
    80003b7c:	06eaf363          	bgeu	s5,a4,80003be2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003b80:	41fad79b          	sraiw	a5,s5,0x1f
    80003b84:	0137d79b          	srliw	a5,a5,0x13
    80003b88:	015787bb          	addw	a5,a5,s5
    80003b8c:	40d7d79b          	sraiw	a5,a5,0xd
    80003b90:	01cb2583          	lw	a1,28(s6)
    80003b94:	9dbd                	addw	a1,a1,a5
    80003b96:	855e                	mv	a0,s7
    80003b98:	00000097          	auipc	ra,0x0
    80003b9c:	cd2080e7          	jalr	-814(ra) # 8000386a <bread>
    80003ba0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ba2:	004b2503          	lw	a0,4(s6)
    80003ba6:	000a849b          	sext.w	s1,s5
    80003baa:	8662                	mv	a2,s8
    80003bac:	faa4fde3          	bgeu	s1,a0,80003b66 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003bb0:	41f6579b          	sraiw	a5,a2,0x1f
    80003bb4:	01d7d69b          	srliw	a3,a5,0x1d
    80003bb8:	00c6873b          	addw	a4,a3,a2
    80003bbc:	00777793          	andi	a5,a4,7
    80003bc0:	9f95                	subw	a5,a5,a3
    80003bc2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003bc6:	4037571b          	sraiw	a4,a4,0x3
    80003bca:	00e906b3          	add	a3,s2,a4
    80003bce:	0586c683          	lbu	a3,88(a3)
    80003bd2:	00d7f5b3          	and	a1,a5,a3
    80003bd6:	cd91                	beqz	a1,80003bf2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bd8:	2605                	addiw	a2,a2,1
    80003bda:	2485                	addiw	s1,s1,1
    80003bdc:	fd4618e3          	bne	a2,s4,80003bac <balloc+0x80>
    80003be0:	b759                	j	80003b66 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003be2:	00005517          	auipc	a0,0x5
    80003be6:	a5650513          	addi	a0,a0,-1450 # 80008638 <syscalls+0x118>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	954080e7          	jalr	-1708(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bf2:	974a                	add	a4,a4,s2
    80003bf4:	8fd5                	or	a5,a5,a3
    80003bf6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003bfa:	854a                	mv	a0,s2
    80003bfc:	00001097          	auipc	ra,0x1
    80003c00:	01a080e7          	jalr	26(ra) # 80004c16 <log_write>
        brelse(bp);
    80003c04:	854a                	mv	a0,s2
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	d94080e7          	jalr	-620(ra) # 8000399a <brelse>
  bp = bread(dev, bno);
    80003c0e:	85a6                	mv	a1,s1
    80003c10:	855e                	mv	a0,s7
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	c58080e7          	jalr	-936(ra) # 8000386a <bread>
    80003c1a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003c1c:	40000613          	li	a2,1024
    80003c20:	4581                	li	a1,0
    80003c22:	05850513          	addi	a0,a0,88
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	0de080e7          	jalr	222(ra) # 80000d04 <memset>
  log_write(bp);
    80003c2e:	854a                	mv	a0,s2
    80003c30:	00001097          	auipc	ra,0x1
    80003c34:	fe6080e7          	jalr	-26(ra) # 80004c16 <log_write>
  brelse(bp);
    80003c38:	854a                	mv	a0,s2
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	d60080e7          	jalr	-672(ra) # 8000399a <brelse>
}
    80003c42:	8526                	mv	a0,s1
    80003c44:	60e6                	ld	ra,88(sp)
    80003c46:	6446                	ld	s0,80(sp)
    80003c48:	64a6                	ld	s1,72(sp)
    80003c4a:	6906                	ld	s2,64(sp)
    80003c4c:	79e2                	ld	s3,56(sp)
    80003c4e:	7a42                	ld	s4,48(sp)
    80003c50:	7aa2                	ld	s5,40(sp)
    80003c52:	7b02                	ld	s6,32(sp)
    80003c54:	6be2                	ld	s7,24(sp)
    80003c56:	6c42                	ld	s8,16(sp)
    80003c58:	6ca2                	ld	s9,8(sp)
    80003c5a:	6125                	addi	sp,sp,96
    80003c5c:	8082                	ret

0000000080003c5e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c5e:	7179                	addi	sp,sp,-48
    80003c60:	f406                	sd	ra,40(sp)
    80003c62:	f022                	sd	s0,32(sp)
    80003c64:	ec26                	sd	s1,24(sp)
    80003c66:	e84a                	sd	s2,16(sp)
    80003c68:	e44e                	sd	s3,8(sp)
    80003c6a:	e052                	sd	s4,0(sp)
    80003c6c:	1800                	addi	s0,sp,48
    80003c6e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c70:	47ad                	li	a5,11
    80003c72:	04b7fe63          	bgeu	a5,a1,80003cce <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003c76:	ff45849b          	addiw	s1,a1,-12
    80003c7a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c7e:	0ff00793          	li	a5,255
    80003c82:	0ae7e363          	bltu	a5,a4,80003d28 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003c86:	08052583          	lw	a1,128(a0)
    80003c8a:	c5ad                	beqz	a1,80003cf4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003c8c:	00092503          	lw	a0,0(s2)
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	bda080e7          	jalr	-1062(ra) # 8000386a <bread>
    80003c98:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c9a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c9e:	02049593          	slli	a1,s1,0x20
    80003ca2:	9181                	srli	a1,a1,0x20
    80003ca4:	058a                	slli	a1,a1,0x2
    80003ca6:	00b784b3          	add	s1,a5,a1
    80003caa:	0004a983          	lw	s3,0(s1)
    80003cae:	04098d63          	beqz	s3,80003d08 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003cb2:	8552                	mv	a0,s4
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	ce6080e7          	jalr	-794(ra) # 8000399a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003cbc:	854e                	mv	a0,s3
    80003cbe:	70a2                	ld	ra,40(sp)
    80003cc0:	7402                	ld	s0,32(sp)
    80003cc2:	64e2                	ld	s1,24(sp)
    80003cc4:	6942                	ld	s2,16(sp)
    80003cc6:	69a2                	ld	s3,8(sp)
    80003cc8:	6a02                	ld	s4,0(sp)
    80003cca:	6145                	addi	sp,sp,48
    80003ccc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003cce:	02059493          	slli	s1,a1,0x20
    80003cd2:	9081                	srli	s1,s1,0x20
    80003cd4:	048a                	slli	s1,s1,0x2
    80003cd6:	94aa                	add	s1,s1,a0
    80003cd8:	0504a983          	lw	s3,80(s1)
    80003cdc:	fe0990e3          	bnez	s3,80003cbc <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003ce0:	4108                	lw	a0,0(a0)
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	e4a080e7          	jalr	-438(ra) # 80003b2c <balloc>
    80003cea:	0005099b          	sext.w	s3,a0
    80003cee:	0534a823          	sw	s3,80(s1)
    80003cf2:	b7e9                	j	80003cbc <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003cf4:	4108                	lw	a0,0(a0)
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	e36080e7          	jalr	-458(ra) # 80003b2c <balloc>
    80003cfe:	0005059b          	sext.w	a1,a0
    80003d02:	08b92023          	sw	a1,128(s2)
    80003d06:	b759                	j	80003c8c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003d08:	00092503          	lw	a0,0(s2)
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	e20080e7          	jalr	-480(ra) # 80003b2c <balloc>
    80003d14:	0005099b          	sext.w	s3,a0
    80003d18:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003d1c:	8552                	mv	a0,s4
    80003d1e:	00001097          	auipc	ra,0x1
    80003d22:	ef8080e7          	jalr	-264(ra) # 80004c16 <log_write>
    80003d26:	b771                	j	80003cb2 <bmap+0x54>
  panic("bmap: out of range");
    80003d28:	00005517          	auipc	a0,0x5
    80003d2c:	92850513          	addi	a0,a0,-1752 # 80008650 <syscalls+0x130>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	80e080e7          	jalr	-2034(ra) # 8000053e <panic>

0000000080003d38 <iget>:
{
    80003d38:	7179                	addi	sp,sp,-48
    80003d3a:	f406                	sd	ra,40(sp)
    80003d3c:	f022                	sd	s0,32(sp)
    80003d3e:	ec26                	sd	s1,24(sp)
    80003d40:	e84a                	sd	s2,16(sp)
    80003d42:	e44e                	sd	s3,8(sp)
    80003d44:	e052                	sd	s4,0(sp)
    80003d46:	1800                	addi	s0,sp,48
    80003d48:	89aa                	mv	s3,a0
    80003d4a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d4c:	0001c517          	auipc	a0,0x1c
    80003d50:	42450513          	addi	a0,a0,1060 # 80020170 <itable>
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	e90080e7          	jalr	-368(ra) # 80000be4 <acquire>
  empty = 0;
    80003d5c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d5e:	0001c497          	auipc	s1,0x1c
    80003d62:	42a48493          	addi	s1,s1,1066 # 80020188 <itable+0x18>
    80003d66:	0001e697          	auipc	a3,0x1e
    80003d6a:	eb268693          	addi	a3,a3,-334 # 80021c18 <log>
    80003d6e:	a039                	j	80003d7c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d70:	02090b63          	beqz	s2,80003da6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d74:	08848493          	addi	s1,s1,136
    80003d78:	02d48a63          	beq	s1,a3,80003dac <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d7c:	449c                	lw	a5,8(s1)
    80003d7e:	fef059e3          	blez	a5,80003d70 <iget+0x38>
    80003d82:	4098                	lw	a4,0(s1)
    80003d84:	ff3716e3          	bne	a4,s3,80003d70 <iget+0x38>
    80003d88:	40d8                	lw	a4,4(s1)
    80003d8a:	ff4713e3          	bne	a4,s4,80003d70 <iget+0x38>
      ip->ref++;
    80003d8e:	2785                	addiw	a5,a5,1
    80003d90:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d92:	0001c517          	auipc	a0,0x1c
    80003d96:	3de50513          	addi	a0,a0,990 # 80020170 <itable>
    80003d9a:	ffffd097          	auipc	ra,0xffffd
    80003d9e:	f10080e7          	jalr	-240(ra) # 80000caa <release>
      return ip;
    80003da2:	8926                	mv	s2,s1
    80003da4:	a03d                	j	80003dd2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003da6:	f7f9                	bnez	a5,80003d74 <iget+0x3c>
    80003da8:	8926                	mv	s2,s1
    80003daa:	b7e9                	j	80003d74 <iget+0x3c>
  if(empty == 0)
    80003dac:	02090c63          	beqz	s2,80003de4 <iget+0xac>
  ip->dev = dev;
    80003db0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003db4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003db8:	4785                	li	a5,1
    80003dba:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003dbe:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003dc2:	0001c517          	auipc	a0,0x1c
    80003dc6:	3ae50513          	addi	a0,a0,942 # 80020170 <itable>
    80003dca:	ffffd097          	auipc	ra,0xffffd
    80003dce:	ee0080e7          	jalr	-288(ra) # 80000caa <release>
}
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	70a2                	ld	ra,40(sp)
    80003dd6:	7402                	ld	s0,32(sp)
    80003dd8:	64e2                	ld	s1,24(sp)
    80003dda:	6942                	ld	s2,16(sp)
    80003ddc:	69a2                	ld	s3,8(sp)
    80003dde:	6a02                	ld	s4,0(sp)
    80003de0:	6145                	addi	sp,sp,48
    80003de2:	8082                	ret
    panic("iget: no inodes");
    80003de4:	00005517          	auipc	a0,0x5
    80003de8:	88450513          	addi	a0,a0,-1916 # 80008668 <syscalls+0x148>
    80003dec:	ffffc097          	auipc	ra,0xffffc
    80003df0:	752080e7          	jalr	1874(ra) # 8000053e <panic>

0000000080003df4 <fsinit>:
fsinit(int dev) {
    80003df4:	7179                	addi	sp,sp,-48
    80003df6:	f406                	sd	ra,40(sp)
    80003df8:	f022                	sd	s0,32(sp)
    80003dfa:	ec26                	sd	s1,24(sp)
    80003dfc:	e84a                	sd	s2,16(sp)
    80003dfe:	e44e                	sd	s3,8(sp)
    80003e00:	1800                	addi	s0,sp,48
    80003e02:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003e04:	4585                	li	a1,1
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	a64080e7          	jalr	-1436(ra) # 8000386a <bread>
    80003e0e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003e10:	0001c997          	auipc	s3,0x1c
    80003e14:	34098993          	addi	s3,s3,832 # 80020150 <sb>
    80003e18:	02000613          	li	a2,32
    80003e1c:	05850593          	addi	a1,a0,88
    80003e20:	854e                	mv	a0,s3
    80003e22:	ffffd097          	auipc	ra,0xffffd
    80003e26:	f42080e7          	jalr	-190(ra) # 80000d64 <memmove>
  brelse(bp);
    80003e2a:	8526                	mv	a0,s1
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	b6e080e7          	jalr	-1170(ra) # 8000399a <brelse>
  if(sb.magic != FSMAGIC)
    80003e34:	0009a703          	lw	a4,0(s3)
    80003e38:	102037b7          	lui	a5,0x10203
    80003e3c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e40:	02f71263          	bne	a4,a5,80003e64 <fsinit+0x70>
  initlog(dev, &sb);
    80003e44:	0001c597          	auipc	a1,0x1c
    80003e48:	30c58593          	addi	a1,a1,780 # 80020150 <sb>
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00001097          	auipc	ra,0x1
    80003e52:	b4c080e7          	jalr	-1204(ra) # 8000499a <initlog>
}
    80003e56:	70a2                	ld	ra,40(sp)
    80003e58:	7402                	ld	s0,32(sp)
    80003e5a:	64e2                	ld	s1,24(sp)
    80003e5c:	6942                	ld	s2,16(sp)
    80003e5e:	69a2                	ld	s3,8(sp)
    80003e60:	6145                	addi	sp,sp,48
    80003e62:	8082                	ret
    panic("invalid file system");
    80003e64:	00005517          	auipc	a0,0x5
    80003e68:	81450513          	addi	a0,a0,-2028 # 80008678 <syscalls+0x158>
    80003e6c:	ffffc097          	auipc	ra,0xffffc
    80003e70:	6d2080e7          	jalr	1746(ra) # 8000053e <panic>

0000000080003e74 <iinit>:
{
    80003e74:	7179                	addi	sp,sp,-48
    80003e76:	f406                	sd	ra,40(sp)
    80003e78:	f022                	sd	s0,32(sp)
    80003e7a:	ec26                	sd	s1,24(sp)
    80003e7c:	e84a                	sd	s2,16(sp)
    80003e7e:	e44e                	sd	s3,8(sp)
    80003e80:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e82:	00005597          	auipc	a1,0x5
    80003e86:	80e58593          	addi	a1,a1,-2034 # 80008690 <syscalls+0x170>
    80003e8a:	0001c517          	auipc	a0,0x1c
    80003e8e:	2e650513          	addi	a0,a0,742 # 80020170 <itable>
    80003e92:	ffffd097          	auipc	ra,0xffffd
    80003e96:	cc2080e7          	jalr	-830(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e9a:	0001c497          	auipc	s1,0x1c
    80003e9e:	2fe48493          	addi	s1,s1,766 # 80020198 <itable+0x28>
    80003ea2:	0001e997          	auipc	s3,0x1e
    80003ea6:	d8698993          	addi	s3,s3,-634 # 80021c28 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003eaa:	00004917          	auipc	s2,0x4
    80003eae:	7ee90913          	addi	s2,s2,2030 # 80008698 <syscalls+0x178>
    80003eb2:	85ca                	mv	a1,s2
    80003eb4:	8526                	mv	a0,s1
    80003eb6:	00001097          	auipc	ra,0x1
    80003eba:	e46080e7          	jalr	-442(ra) # 80004cfc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ebe:	08848493          	addi	s1,s1,136
    80003ec2:	ff3498e3          	bne	s1,s3,80003eb2 <iinit+0x3e>
}
    80003ec6:	70a2                	ld	ra,40(sp)
    80003ec8:	7402                	ld	s0,32(sp)
    80003eca:	64e2                	ld	s1,24(sp)
    80003ecc:	6942                	ld	s2,16(sp)
    80003ece:	69a2                	ld	s3,8(sp)
    80003ed0:	6145                	addi	sp,sp,48
    80003ed2:	8082                	ret

0000000080003ed4 <ialloc>:
{
    80003ed4:	715d                	addi	sp,sp,-80
    80003ed6:	e486                	sd	ra,72(sp)
    80003ed8:	e0a2                	sd	s0,64(sp)
    80003eda:	fc26                	sd	s1,56(sp)
    80003edc:	f84a                	sd	s2,48(sp)
    80003ede:	f44e                	sd	s3,40(sp)
    80003ee0:	f052                	sd	s4,32(sp)
    80003ee2:	ec56                	sd	s5,24(sp)
    80003ee4:	e85a                	sd	s6,16(sp)
    80003ee6:	e45e                	sd	s7,8(sp)
    80003ee8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003eea:	0001c717          	auipc	a4,0x1c
    80003eee:	27272703          	lw	a4,626(a4) # 8002015c <sb+0xc>
    80003ef2:	4785                	li	a5,1
    80003ef4:	04e7fa63          	bgeu	a5,a4,80003f48 <ialloc+0x74>
    80003ef8:	8aaa                	mv	s5,a0
    80003efa:	8bae                	mv	s7,a1
    80003efc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003efe:	0001ca17          	auipc	s4,0x1c
    80003f02:	252a0a13          	addi	s4,s4,594 # 80020150 <sb>
    80003f06:	00048b1b          	sext.w	s6,s1
    80003f0a:	0044d593          	srli	a1,s1,0x4
    80003f0e:	018a2783          	lw	a5,24(s4)
    80003f12:	9dbd                	addw	a1,a1,a5
    80003f14:	8556                	mv	a0,s5
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	954080e7          	jalr	-1708(ra) # 8000386a <bread>
    80003f1e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003f20:	05850993          	addi	s3,a0,88
    80003f24:	00f4f793          	andi	a5,s1,15
    80003f28:	079a                	slli	a5,a5,0x6
    80003f2a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003f2c:	00099783          	lh	a5,0(s3)
    80003f30:	c785                	beqz	a5,80003f58 <ialloc+0x84>
    brelse(bp);
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	a68080e7          	jalr	-1432(ra) # 8000399a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f3a:	0485                	addi	s1,s1,1
    80003f3c:	00ca2703          	lw	a4,12(s4)
    80003f40:	0004879b          	sext.w	a5,s1
    80003f44:	fce7e1e3          	bltu	a5,a4,80003f06 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003f48:	00004517          	auipc	a0,0x4
    80003f4c:	75850513          	addi	a0,a0,1880 # 800086a0 <syscalls+0x180>
    80003f50:	ffffc097          	auipc	ra,0xffffc
    80003f54:	5ee080e7          	jalr	1518(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003f58:	04000613          	li	a2,64
    80003f5c:	4581                	li	a1,0
    80003f5e:	854e                	mv	a0,s3
    80003f60:	ffffd097          	auipc	ra,0xffffd
    80003f64:	da4080e7          	jalr	-604(ra) # 80000d04 <memset>
      dip->type = type;
    80003f68:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f6c:	854a                	mv	a0,s2
    80003f6e:	00001097          	auipc	ra,0x1
    80003f72:	ca8080e7          	jalr	-856(ra) # 80004c16 <log_write>
      brelse(bp);
    80003f76:	854a                	mv	a0,s2
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	a22080e7          	jalr	-1502(ra) # 8000399a <brelse>
      return iget(dev, inum);
    80003f80:	85da                	mv	a1,s6
    80003f82:	8556                	mv	a0,s5
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	db4080e7          	jalr	-588(ra) # 80003d38 <iget>
}
    80003f8c:	60a6                	ld	ra,72(sp)
    80003f8e:	6406                	ld	s0,64(sp)
    80003f90:	74e2                	ld	s1,56(sp)
    80003f92:	7942                	ld	s2,48(sp)
    80003f94:	79a2                	ld	s3,40(sp)
    80003f96:	7a02                	ld	s4,32(sp)
    80003f98:	6ae2                	ld	s5,24(sp)
    80003f9a:	6b42                	ld	s6,16(sp)
    80003f9c:	6ba2                	ld	s7,8(sp)
    80003f9e:	6161                	addi	sp,sp,80
    80003fa0:	8082                	ret

0000000080003fa2 <iupdate>:
{
    80003fa2:	1101                	addi	sp,sp,-32
    80003fa4:	ec06                	sd	ra,24(sp)
    80003fa6:	e822                	sd	s0,16(sp)
    80003fa8:	e426                	sd	s1,8(sp)
    80003faa:	e04a                	sd	s2,0(sp)
    80003fac:	1000                	addi	s0,sp,32
    80003fae:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fb0:	415c                	lw	a5,4(a0)
    80003fb2:	0047d79b          	srliw	a5,a5,0x4
    80003fb6:	0001c597          	auipc	a1,0x1c
    80003fba:	1b25a583          	lw	a1,434(a1) # 80020168 <sb+0x18>
    80003fbe:	9dbd                	addw	a1,a1,a5
    80003fc0:	4108                	lw	a0,0(a0)
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	8a8080e7          	jalr	-1880(ra) # 8000386a <bread>
    80003fca:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fcc:	05850793          	addi	a5,a0,88
    80003fd0:	40c8                	lw	a0,4(s1)
    80003fd2:	893d                	andi	a0,a0,15
    80003fd4:	051a                	slli	a0,a0,0x6
    80003fd6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003fd8:	04449703          	lh	a4,68(s1)
    80003fdc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003fe0:	04649703          	lh	a4,70(s1)
    80003fe4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003fe8:	04849703          	lh	a4,72(s1)
    80003fec:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ff0:	04a49703          	lh	a4,74(s1)
    80003ff4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ff8:	44f8                	lw	a4,76(s1)
    80003ffa:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ffc:	03400613          	li	a2,52
    80004000:	05048593          	addi	a1,s1,80
    80004004:	0531                	addi	a0,a0,12
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	d5e080e7          	jalr	-674(ra) # 80000d64 <memmove>
  log_write(bp);
    8000400e:	854a                	mv	a0,s2
    80004010:	00001097          	auipc	ra,0x1
    80004014:	c06080e7          	jalr	-1018(ra) # 80004c16 <log_write>
  brelse(bp);
    80004018:	854a                	mv	a0,s2
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	980080e7          	jalr	-1664(ra) # 8000399a <brelse>
}
    80004022:	60e2                	ld	ra,24(sp)
    80004024:	6442                	ld	s0,16(sp)
    80004026:	64a2                	ld	s1,8(sp)
    80004028:	6902                	ld	s2,0(sp)
    8000402a:	6105                	addi	sp,sp,32
    8000402c:	8082                	ret

000000008000402e <idup>:
{
    8000402e:	1101                	addi	sp,sp,-32
    80004030:	ec06                	sd	ra,24(sp)
    80004032:	e822                	sd	s0,16(sp)
    80004034:	e426                	sd	s1,8(sp)
    80004036:	1000                	addi	s0,sp,32
    80004038:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000403a:	0001c517          	auipc	a0,0x1c
    8000403e:	13650513          	addi	a0,a0,310 # 80020170 <itable>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	ba2080e7          	jalr	-1118(ra) # 80000be4 <acquire>
  ip->ref++;
    8000404a:	449c                	lw	a5,8(s1)
    8000404c:	2785                	addiw	a5,a5,1
    8000404e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004050:	0001c517          	auipc	a0,0x1c
    80004054:	12050513          	addi	a0,a0,288 # 80020170 <itable>
    80004058:	ffffd097          	auipc	ra,0xffffd
    8000405c:	c52080e7          	jalr	-942(ra) # 80000caa <release>
}
    80004060:	8526                	mv	a0,s1
    80004062:	60e2                	ld	ra,24(sp)
    80004064:	6442                	ld	s0,16(sp)
    80004066:	64a2                	ld	s1,8(sp)
    80004068:	6105                	addi	sp,sp,32
    8000406a:	8082                	ret

000000008000406c <ilock>:
{
    8000406c:	1101                	addi	sp,sp,-32
    8000406e:	ec06                	sd	ra,24(sp)
    80004070:	e822                	sd	s0,16(sp)
    80004072:	e426                	sd	s1,8(sp)
    80004074:	e04a                	sd	s2,0(sp)
    80004076:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004078:	c115                	beqz	a0,8000409c <ilock+0x30>
    8000407a:	84aa                	mv	s1,a0
    8000407c:	451c                	lw	a5,8(a0)
    8000407e:	00f05f63          	blez	a5,8000409c <ilock+0x30>
  acquiresleep(&ip->lock);
    80004082:	0541                	addi	a0,a0,16
    80004084:	00001097          	auipc	ra,0x1
    80004088:	cb2080e7          	jalr	-846(ra) # 80004d36 <acquiresleep>
  if(ip->valid == 0){
    8000408c:	40bc                	lw	a5,64(s1)
    8000408e:	cf99                	beqz	a5,800040ac <ilock+0x40>
}
    80004090:	60e2                	ld	ra,24(sp)
    80004092:	6442                	ld	s0,16(sp)
    80004094:	64a2                	ld	s1,8(sp)
    80004096:	6902                	ld	s2,0(sp)
    80004098:	6105                	addi	sp,sp,32
    8000409a:	8082                	ret
    panic("ilock");
    8000409c:	00004517          	auipc	a0,0x4
    800040a0:	61c50513          	addi	a0,a0,1564 # 800086b8 <syscalls+0x198>
    800040a4:	ffffc097          	auipc	ra,0xffffc
    800040a8:	49a080e7          	jalr	1178(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800040ac:	40dc                	lw	a5,4(s1)
    800040ae:	0047d79b          	srliw	a5,a5,0x4
    800040b2:	0001c597          	auipc	a1,0x1c
    800040b6:	0b65a583          	lw	a1,182(a1) # 80020168 <sb+0x18>
    800040ba:	9dbd                	addw	a1,a1,a5
    800040bc:	4088                	lw	a0,0(s1)
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	7ac080e7          	jalr	1964(ra) # 8000386a <bread>
    800040c6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040c8:	05850593          	addi	a1,a0,88
    800040cc:	40dc                	lw	a5,4(s1)
    800040ce:	8bbd                	andi	a5,a5,15
    800040d0:	079a                	slli	a5,a5,0x6
    800040d2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800040d4:	00059783          	lh	a5,0(a1)
    800040d8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800040dc:	00259783          	lh	a5,2(a1)
    800040e0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800040e4:	00459783          	lh	a5,4(a1)
    800040e8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800040ec:	00659783          	lh	a5,6(a1)
    800040f0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800040f4:	459c                	lw	a5,8(a1)
    800040f6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800040f8:	03400613          	li	a2,52
    800040fc:	05b1                	addi	a1,a1,12
    800040fe:	05048513          	addi	a0,s1,80
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	c62080e7          	jalr	-926(ra) # 80000d64 <memmove>
    brelse(bp);
    8000410a:	854a                	mv	a0,s2
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	88e080e7          	jalr	-1906(ra) # 8000399a <brelse>
    ip->valid = 1;
    80004114:	4785                	li	a5,1
    80004116:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004118:	04449783          	lh	a5,68(s1)
    8000411c:	fbb5                	bnez	a5,80004090 <ilock+0x24>
      panic("ilock: no type");
    8000411e:	00004517          	auipc	a0,0x4
    80004122:	5a250513          	addi	a0,a0,1442 # 800086c0 <syscalls+0x1a0>
    80004126:	ffffc097          	auipc	ra,0xffffc
    8000412a:	418080e7          	jalr	1048(ra) # 8000053e <panic>

000000008000412e <iunlock>:
{
    8000412e:	1101                	addi	sp,sp,-32
    80004130:	ec06                	sd	ra,24(sp)
    80004132:	e822                	sd	s0,16(sp)
    80004134:	e426                	sd	s1,8(sp)
    80004136:	e04a                	sd	s2,0(sp)
    80004138:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000413a:	c905                	beqz	a0,8000416a <iunlock+0x3c>
    8000413c:	84aa                	mv	s1,a0
    8000413e:	01050913          	addi	s2,a0,16
    80004142:	854a                	mv	a0,s2
    80004144:	00001097          	auipc	ra,0x1
    80004148:	c8c080e7          	jalr	-884(ra) # 80004dd0 <holdingsleep>
    8000414c:	cd19                	beqz	a0,8000416a <iunlock+0x3c>
    8000414e:	449c                	lw	a5,8(s1)
    80004150:	00f05d63          	blez	a5,8000416a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004154:	854a                	mv	a0,s2
    80004156:	00001097          	auipc	ra,0x1
    8000415a:	c36080e7          	jalr	-970(ra) # 80004d8c <releasesleep>
}
    8000415e:	60e2                	ld	ra,24(sp)
    80004160:	6442                	ld	s0,16(sp)
    80004162:	64a2                	ld	s1,8(sp)
    80004164:	6902                	ld	s2,0(sp)
    80004166:	6105                	addi	sp,sp,32
    80004168:	8082                	ret
    panic("iunlock");
    8000416a:	00004517          	auipc	a0,0x4
    8000416e:	56650513          	addi	a0,a0,1382 # 800086d0 <syscalls+0x1b0>
    80004172:	ffffc097          	auipc	ra,0xffffc
    80004176:	3cc080e7          	jalr	972(ra) # 8000053e <panic>

000000008000417a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000417a:	7179                	addi	sp,sp,-48
    8000417c:	f406                	sd	ra,40(sp)
    8000417e:	f022                	sd	s0,32(sp)
    80004180:	ec26                	sd	s1,24(sp)
    80004182:	e84a                	sd	s2,16(sp)
    80004184:	e44e                	sd	s3,8(sp)
    80004186:	e052                	sd	s4,0(sp)
    80004188:	1800                	addi	s0,sp,48
    8000418a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000418c:	05050493          	addi	s1,a0,80
    80004190:	08050913          	addi	s2,a0,128
    80004194:	a021                	j	8000419c <itrunc+0x22>
    80004196:	0491                	addi	s1,s1,4
    80004198:	01248d63          	beq	s1,s2,800041b2 <itrunc+0x38>
    if(ip->addrs[i]){
    8000419c:	408c                	lw	a1,0(s1)
    8000419e:	dde5                	beqz	a1,80004196 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800041a0:	0009a503          	lw	a0,0(s3)
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	90c080e7          	jalr	-1780(ra) # 80003ab0 <bfree>
      ip->addrs[i] = 0;
    800041ac:	0004a023          	sw	zero,0(s1)
    800041b0:	b7dd                	j	80004196 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800041b2:	0809a583          	lw	a1,128(s3)
    800041b6:	e185                	bnez	a1,800041d6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800041b8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800041bc:	854e                	mv	a0,s3
    800041be:	00000097          	auipc	ra,0x0
    800041c2:	de4080e7          	jalr	-540(ra) # 80003fa2 <iupdate>
}
    800041c6:	70a2                	ld	ra,40(sp)
    800041c8:	7402                	ld	s0,32(sp)
    800041ca:	64e2                	ld	s1,24(sp)
    800041cc:	6942                	ld	s2,16(sp)
    800041ce:	69a2                	ld	s3,8(sp)
    800041d0:	6a02                	ld	s4,0(sp)
    800041d2:	6145                	addi	sp,sp,48
    800041d4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800041d6:	0009a503          	lw	a0,0(s3)
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	690080e7          	jalr	1680(ra) # 8000386a <bread>
    800041e2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800041e4:	05850493          	addi	s1,a0,88
    800041e8:	45850913          	addi	s2,a0,1112
    800041ec:	a811                	j	80004200 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800041ee:	0009a503          	lw	a0,0(s3)
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	8be080e7          	jalr	-1858(ra) # 80003ab0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800041fa:	0491                	addi	s1,s1,4
    800041fc:	01248563          	beq	s1,s2,80004206 <itrunc+0x8c>
      if(a[j])
    80004200:	408c                	lw	a1,0(s1)
    80004202:	dde5                	beqz	a1,800041fa <itrunc+0x80>
    80004204:	b7ed                	j	800041ee <itrunc+0x74>
    brelse(bp);
    80004206:	8552                	mv	a0,s4
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	792080e7          	jalr	1938(ra) # 8000399a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004210:	0809a583          	lw	a1,128(s3)
    80004214:	0009a503          	lw	a0,0(s3)
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	898080e7          	jalr	-1896(ra) # 80003ab0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004220:	0809a023          	sw	zero,128(s3)
    80004224:	bf51                	j	800041b8 <itrunc+0x3e>

0000000080004226 <iput>:
{
    80004226:	1101                	addi	sp,sp,-32
    80004228:	ec06                	sd	ra,24(sp)
    8000422a:	e822                	sd	s0,16(sp)
    8000422c:	e426                	sd	s1,8(sp)
    8000422e:	e04a                	sd	s2,0(sp)
    80004230:	1000                	addi	s0,sp,32
    80004232:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004234:	0001c517          	auipc	a0,0x1c
    80004238:	f3c50513          	addi	a0,a0,-196 # 80020170 <itable>
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	9a8080e7          	jalr	-1624(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004244:	4498                	lw	a4,8(s1)
    80004246:	4785                	li	a5,1
    80004248:	02f70363          	beq	a4,a5,8000426e <iput+0x48>
  ip->ref--;
    8000424c:	449c                	lw	a5,8(s1)
    8000424e:	37fd                	addiw	a5,a5,-1
    80004250:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004252:	0001c517          	auipc	a0,0x1c
    80004256:	f1e50513          	addi	a0,a0,-226 # 80020170 <itable>
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	a50080e7          	jalr	-1456(ra) # 80000caa <release>
}
    80004262:	60e2                	ld	ra,24(sp)
    80004264:	6442                	ld	s0,16(sp)
    80004266:	64a2                	ld	s1,8(sp)
    80004268:	6902                	ld	s2,0(sp)
    8000426a:	6105                	addi	sp,sp,32
    8000426c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000426e:	40bc                	lw	a5,64(s1)
    80004270:	dff1                	beqz	a5,8000424c <iput+0x26>
    80004272:	04a49783          	lh	a5,74(s1)
    80004276:	fbf9                	bnez	a5,8000424c <iput+0x26>
    acquiresleep(&ip->lock);
    80004278:	01048913          	addi	s2,s1,16
    8000427c:	854a                	mv	a0,s2
    8000427e:	00001097          	auipc	ra,0x1
    80004282:	ab8080e7          	jalr	-1352(ra) # 80004d36 <acquiresleep>
    release(&itable.lock);
    80004286:	0001c517          	auipc	a0,0x1c
    8000428a:	eea50513          	addi	a0,a0,-278 # 80020170 <itable>
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	a1c080e7          	jalr	-1508(ra) # 80000caa <release>
    itrunc(ip);
    80004296:	8526                	mv	a0,s1
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	ee2080e7          	jalr	-286(ra) # 8000417a <itrunc>
    ip->type = 0;
    800042a0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800042a4:	8526                	mv	a0,s1
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	cfc080e7          	jalr	-772(ra) # 80003fa2 <iupdate>
    ip->valid = 0;
    800042ae:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800042b2:	854a                	mv	a0,s2
    800042b4:	00001097          	auipc	ra,0x1
    800042b8:	ad8080e7          	jalr	-1320(ra) # 80004d8c <releasesleep>
    acquire(&itable.lock);
    800042bc:	0001c517          	auipc	a0,0x1c
    800042c0:	eb450513          	addi	a0,a0,-332 # 80020170 <itable>
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	920080e7          	jalr	-1760(ra) # 80000be4 <acquire>
    800042cc:	b741                	j	8000424c <iput+0x26>

00000000800042ce <iunlockput>:
{
    800042ce:	1101                	addi	sp,sp,-32
    800042d0:	ec06                	sd	ra,24(sp)
    800042d2:	e822                	sd	s0,16(sp)
    800042d4:	e426                	sd	s1,8(sp)
    800042d6:	1000                	addi	s0,sp,32
    800042d8:	84aa                	mv	s1,a0
  iunlock(ip);
    800042da:	00000097          	auipc	ra,0x0
    800042de:	e54080e7          	jalr	-428(ra) # 8000412e <iunlock>
  iput(ip);
    800042e2:	8526                	mv	a0,s1
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	f42080e7          	jalr	-190(ra) # 80004226 <iput>
}
    800042ec:	60e2                	ld	ra,24(sp)
    800042ee:	6442                	ld	s0,16(sp)
    800042f0:	64a2                	ld	s1,8(sp)
    800042f2:	6105                	addi	sp,sp,32
    800042f4:	8082                	ret

00000000800042f6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800042f6:	1141                	addi	sp,sp,-16
    800042f8:	e422                	sd	s0,8(sp)
    800042fa:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800042fc:	411c                	lw	a5,0(a0)
    800042fe:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004300:	415c                	lw	a5,4(a0)
    80004302:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004304:	04451783          	lh	a5,68(a0)
    80004308:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000430c:	04a51783          	lh	a5,74(a0)
    80004310:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004314:	04c56783          	lwu	a5,76(a0)
    80004318:	e99c                	sd	a5,16(a1)
}
    8000431a:	6422                	ld	s0,8(sp)
    8000431c:	0141                	addi	sp,sp,16
    8000431e:	8082                	ret

0000000080004320 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004320:	457c                	lw	a5,76(a0)
    80004322:	0ed7e963          	bltu	a5,a3,80004414 <readi+0xf4>
{
    80004326:	7159                	addi	sp,sp,-112
    80004328:	f486                	sd	ra,104(sp)
    8000432a:	f0a2                	sd	s0,96(sp)
    8000432c:	eca6                	sd	s1,88(sp)
    8000432e:	e8ca                	sd	s2,80(sp)
    80004330:	e4ce                	sd	s3,72(sp)
    80004332:	e0d2                	sd	s4,64(sp)
    80004334:	fc56                	sd	s5,56(sp)
    80004336:	f85a                	sd	s6,48(sp)
    80004338:	f45e                	sd	s7,40(sp)
    8000433a:	f062                	sd	s8,32(sp)
    8000433c:	ec66                	sd	s9,24(sp)
    8000433e:	e86a                	sd	s10,16(sp)
    80004340:	e46e                	sd	s11,8(sp)
    80004342:	1880                	addi	s0,sp,112
    80004344:	8baa                	mv	s7,a0
    80004346:	8c2e                	mv	s8,a1
    80004348:	8ab2                	mv	s5,a2
    8000434a:	84b6                	mv	s1,a3
    8000434c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000434e:	9f35                	addw	a4,a4,a3
    return 0;
    80004350:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004352:	0ad76063          	bltu	a4,a3,800043f2 <readi+0xd2>
  if(off + n > ip->size)
    80004356:	00e7f463          	bgeu	a5,a4,8000435e <readi+0x3e>
    n = ip->size - off;
    8000435a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000435e:	0a0b0963          	beqz	s6,80004410 <readi+0xf0>
    80004362:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004364:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004368:	5cfd                	li	s9,-1
    8000436a:	a82d                	j	800043a4 <readi+0x84>
    8000436c:	020a1d93          	slli	s11,s4,0x20
    80004370:	020ddd93          	srli	s11,s11,0x20
    80004374:	05890613          	addi	a2,s2,88
    80004378:	86ee                	mv	a3,s11
    8000437a:	963a                	add	a2,a2,a4
    8000437c:	85d6                	mv	a1,s5
    8000437e:	8562                	mv	a0,s8
    80004380:	fffff097          	auipc	ra,0xfffff
    80004384:	a1e080e7          	jalr	-1506(ra) # 80002d9e <either_copyout>
    80004388:	05950d63          	beq	a0,s9,800043e2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000438c:	854a                	mv	a0,s2
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	60c080e7          	jalr	1548(ra) # 8000399a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004396:	013a09bb          	addw	s3,s4,s3
    8000439a:	009a04bb          	addw	s1,s4,s1
    8000439e:	9aee                	add	s5,s5,s11
    800043a0:	0569f763          	bgeu	s3,s6,800043ee <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043a4:	000ba903          	lw	s2,0(s7)
    800043a8:	00a4d59b          	srliw	a1,s1,0xa
    800043ac:	855e                	mv	a0,s7
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	8b0080e7          	jalr	-1872(ra) # 80003c5e <bmap>
    800043b6:	0005059b          	sext.w	a1,a0
    800043ba:	854a                	mv	a0,s2
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	4ae080e7          	jalr	1198(ra) # 8000386a <bread>
    800043c4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043c6:	3ff4f713          	andi	a4,s1,1023
    800043ca:	40ed07bb          	subw	a5,s10,a4
    800043ce:	413b06bb          	subw	a3,s6,s3
    800043d2:	8a3e                	mv	s4,a5
    800043d4:	2781                	sext.w	a5,a5
    800043d6:	0006861b          	sext.w	a2,a3
    800043da:	f8f679e3          	bgeu	a2,a5,8000436c <readi+0x4c>
    800043de:	8a36                	mv	s4,a3
    800043e0:	b771                	j	8000436c <readi+0x4c>
      brelse(bp);
    800043e2:	854a                	mv	a0,s2
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	5b6080e7          	jalr	1462(ra) # 8000399a <brelse>
      tot = -1;
    800043ec:	59fd                	li	s3,-1
  }
  return tot;
    800043ee:	0009851b          	sext.w	a0,s3
}
    800043f2:	70a6                	ld	ra,104(sp)
    800043f4:	7406                	ld	s0,96(sp)
    800043f6:	64e6                	ld	s1,88(sp)
    800043f8:	6946                	ld	s2,80(sp)
    800043fa:	69a6                	ld	s3,72(sp)
    800043fc:	6a06                	ld	s4,64(sp)
    800043fe:	7ae2                	ld	s5,56(sp)
    80004400:	7b42                	ld	s6,48(sp)
    80004402:	7ba2                	ld	s7,40(sp)
    80004404:	7c02                	ld	s8,32(sp)
    80004406:	6ce2                	ld	s9,24(sp)
    80004408:	6d42                	ld	s10,16(sp)
    8000440a:	6da2                	ld	s11,8(sp)
    8000440c:	6165                	addi	sp,sp,112
    8000440e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004410:	89da                	mv	s3,s6
    80004412:	bff1                	j	800043ee <readi+0xce>
    return 0;
    80004414:	4501                	li	a0,0
}
    80004416:	8082                	ret

0000000080004418 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004418:	457c                	lw	a5,76(a0)
    8000441a:	10d7e863          	bltu	a5,a3,8000452a <writei+0x112>
{
    8000441e:	7159                	addi	sp,sp,-112
    80004420:	f486                	sd	ra,104(sp)
    80004422:	f0a2                	sd	s0,96(sp)
    80004424:	eca6                	sd	s1,88(sp)
    80004426:	e8ca                	sd	s2,80(sp)
    80004428:	e4ce                	sd	s3,72(sp)
    8000442a:	e0d2                	sd	s4,64(sp)
    8000442c:	fc56                	sd	s5,56(sp)
    8000442e:	f85a                	sd	s6,48(sp)
    80004430:	f45e                	sd	s7,40(sp)
    80004432:	f062                	sd	s8,32(sp)
    80004434:	ec66                	sd	s9,24(sp)
    80004436:	e86a                	sd	s10,16(sp)
    80004438:	e46e                	sd	s11,8(sp)
    8000443a:	1880                	addi	s0,sp,112
    8000443c:	8b2a                	mv	s6,a0
    8000443e:	8c2e                	mv	s8,a1
    80004440:	8ab2                	mv	s5,a2
    80004442:	8936                	mv	s2,a3
    80004444:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004446:	00e687bb          	addw	a5,a3,a4
    8000444a:	0ed7e263          	bltu	a5,a3,8000452e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000444e:	00043737          	lui	a4,0x43
    80004452:	0ef76063          	bltu	a4,a5,80004532 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004456:	0c0b8863          	beqz	s7,80004526 <writei+0x10e>
    8000445a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000445c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004460:	5cfd                	li	s9,-1
    80004462:	a091                	j	800044a6 <writei+0x8e>
    80004464:	02099d93          	slli	s11,s3,0x20
    80004468:	020ddd93          	srli	s11,s11,0x20
    8000446c:	05848513          	addi	a0,s1,88
    80004470:	86ee                	mv	a3,s11
    80004472:	8656                	mv	a2,s5
    80004474:	85e2                	mv	a1,s8
    80004476:	953a                	add	a0,a0,a4
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	97c080e7          	jalr	-1668(ra) # 80002df4 <either_copyin>
    80004480:	07950263          	beq	a0,s9,800044e4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004484:	8526                	mv	a0,s1
    80004486:	00000097          	auipc	ra,0x0
    8000448a:	790080e7          	jalr	1936(ra) # 80004c16 <log_write>
    brelse(bp);
    8000448e:	8526                	mv	a0,s1
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	50a080e7          	jalr	1290(ra) # 8000399a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004498:	01498a3b          	addw	s4,s3,s4
    8000449c:	0129893b          	addw	s2,s3,s2
    800044a0:	9aee                	add	s5,s5,s11
    800044a2:	057a7663          	bgeu	s4,s7,800044ee <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800044a6:	000b2483          	lw	s1,0(s6)
    800044aa:	00a9559b          	srliw	a1,s2,0xa
    800044ae:	855a                	mv	a0,s6
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	7ae080e7          	jalr	1966(ra) # 80003c5e <bmap>
    800044b8:	0005059b          	sext.w	a1,a0
    800044bc:	8526                	mv	a0,s1
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	3ac080e7          	jalr	940(ra) # 8000386a <bread>
    800044c6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044c8:	3ff97713          	andi	a4,s2,1023
    800044cc:	40ed07bb          	subw	a5,s10,a4
    800044d0:	414b86bb          	subw	a3,s7,s4
    800044d4:	89be                	mv	s3,a5
    800044d6:	2781                	sext.w	a5,a5
    800044d8:	0006861b          	sext.w	a2,a3
    800044dc:	f8f674e3          	bgeu	a2,a5,80004464 <writei+0x4c>
    800044e0:	89b6                	mv	s3,a3
    800044e2:	b749                	j	80004464 <writei+0x4c>
      brelse(bp);
    800044e4:	8526                	mv	a0,s1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	4b4080e7          	jalr	1204(ra) # 8000399a <brelse>
  }

  if(off > ip->size)
    800044ee:	04cb2783          	lw	a5,76(s6)
    800044f2:	0127f463          	bgeu	a5,s2,800044fa <writei+0xe2>
    ip->size = off;
    800044f6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044fa:	855a                	mv	a0,s6
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	aa6080e7          	jalr	-1370(ra) # 80003fa2 <iupdate>

  return tot;
    80004504:	000a051b          	sext.w	a0,s4
}
    80004508:	70a6                	ld	ra,104(sp)
    8000450a:	7406                	ld	s0,96(sp)
    8000450c:	64e6                	ld	s1,88(sp)
    8000450e:	6946                	ld	s2,80(sp)
    80004510:	69a6                	ld	s3,72(sp)
    80004512:	6a06                	ld	s4,64(sp)
    80004514:	7ae2                	ld	s5,56(sp)
    80004516:	7b42                	ld	s6,48(sp)
    80004518:	7ba2                	ld	s7,40(sp)
    8000451a:	7c02                	ld	s8,32(sp)
    8000451c:	6ce2                	ld	s9,24(sp)
    8000451e:	6d42                	ld	s10,16(sp)
    80004520:	6da2                	ld	s11,8(sp)
    80004522:	6165                	addi	sp,sp,112
    80004524:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004526:	8a5e                	mv	s4,s7
    80004528:	bfc9                	j	800044fa <writei+0xe2>
    return -1;
    8000452a:	557d                	li	a0,-1
}
    8000452c:	8082                	ret
    return -1;
    8000452e:	557d                	li	a0,-1
    80004530:	bfe1                	j	80004508 <writei+0xf0>
    return -1;
    80004532:	557d                	li	a0,-1
    80004534:	bfd1                	j	80004508 <writei+0xf0>

0000000080004536 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004536:	1141                	addi	sp,sp,-16
    80004538:	e406                	sd	ra,8(sp)
    8000453a:	e022                	sd	s0,0(sp)
    8000453c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000453e:	4639                	li	a2,14
    80004540:	ffffd097          	auipc	ra,0xffffd
    80004544:	89c080e7          	jalr	-1892(ra) # 80000ddc <strncmp>
}
    80004548:	60a2                	ld	ra,8(sp)
    8000454a:	6402                	ld	s0,0(sp)
    8000454c:	0141                	addi	sp,sp,16
    8000454e:	8082                	ret

0000000080004550 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004550:	7139                	addi	sp,sp,-64
    80004552:	fc06                	sd	ra,56(sp)
    80004554:	f822                	sd	s0,48(sp)
    80004556:	f426                	sd	s1,40(sp)
    80004558:	f04a                	sd	s2,32(sp)
    8000455a:	ec4e                	sd	s3,24(sp)
    8000455c:	e852                	sd	s4,16(sp)
    8000455e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004560:	04451703          	lh	a4,68(a0)
    80004564:	4785                	li	a5,1
    80004566:	00f71a63          	bne	a4,a5,8000457a <dirlookup+0x2a>
    8000456a:	892a                	mv	s2,a0
    8000456c:	89ae                	mv	s3,a1
    8000456e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004570:	457c                	lw	a5,76(a0)
    80004572:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004574:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004576:	e79d                	bnez	a5,800045a4 <dirlookup+0x54>
    80004578:	a8a5                	j	800045f0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000457a:	00004517          	auipc	a0,0x4
    8000457e:	15e50513          	addi	a0,a0,350 # 800086d8 <syscalls+0x1b8>
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	fbc080e7          	jalr	-68(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000458a:	00004517          	auipc	a0,0x4
    8000458e:	16650513          	addi	a0,a0,358 # 800086f0 <syscalls+0x1d0>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000459a:	24c1                	addiw	s1,s1,16
    8000459c:	04c92783          	lw	a5,76(s2)
    800045a0:	04f4f763          	bgeu	s1,a5,800045ee <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045a4:	4741                	li	a4,16
    800045a6:	86a6                	mv	a3,s1
    800045a8:	fc040613          	addi	a2,s0,-64
    800045ac:	4581                	li	a1,0
    800045ae:	854a                	mv	a0,s2
    800045b0:	00000097          	auipc	ra,0x0
    800045b4:	d70080e7          	jalr	-656(ra) # 80004320 <readi>
    800045b8:	47c1                	li	a5,16
    800045ba:	fcf518e3          	bne	a0,a5,8000458a <dirlookup+0x3a>
    if(de.inum == 0)
    800045be:	fc045783          	lhu	a5,-64(s0)
    800045c2:	dfe1                	beqz	a5,8000459a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800045c4:	fc240593          	addi	a1,s0,-62
    800045c8:	854e                	mv	a0,s3
    800045ca:	00000097          	auipc	ra,0x0
    800045ce:	f6c080e7          	jalr	-148(ra) # 80004536 <namecmp>
    800045d2:	f561                	bnez	a0,8000459a <dirlookup+0x4a>
      if(poff)
    800045d4:	000a0463          	beqz	s4,800045dc <dirlookup+0x8c>
        *poff = off;
    800045d8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800045dc:	fc045583          	lhu	a1,-64(s0)
    800045e0:	00092503          	lw	a0,0(s2)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	754080e7          	jalr	1876(ra) # 80003d38 <iget>
    800045ec:	a011                	j	800045f0 <dirlookup+0xa0>
  return 0;
    800045ee:	4501                	li	a0,0
}
    800045f0:	70e2                	ld	ra,56(sp)
    800045f2:	7442                	ld	s0,48(sp)
    800045f4:	74a2                	ld	s1,40(sp)
    800045f6:	7902                	ld	s2,32(sp)
    800045f8:	69e2                	ld	s3,24(sp)
    800045fa:	6a42                	ld	s4,16(sp)
    800045fc:	6121                	addi	sp,sp,64
    800045fe:	8082                	ret

0000000080004600 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004600:	711d                	addi	sp,sp,-96
    80004602:	ec86                	sd	ra,88(sp)
    80004604:	e8a2                	sd	s0,80(sp)
    80004606:	e4a6                	sd	s1,72(sp)
    80004608:	e0ca                	sd	s2,64(sp)
    8000460a:	fc4e                	sd	s3,56(sp)
    8000460c:	f852                	sd	s4,48(sp)
    8000460e:	f456                	sd	s5,40(sp)
    80004610:	f05a                	sd	s6,32(sp)
    80004612:	ec5e                	sd	s7,24(sp)
    80004614:	e862                	sd	s8,16(sp)
    80004616:	e466                	sd	s9,8(sp)
    80004618:	1080                	addi	s0,sp,96
    8000461a:	84aa                	mv	s1,a0
    8000461c:	8b2e                	mv	s6,a1
    8000461e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004620:	00054703          	lbu	a4,0(a0)
    80004624:	02f00793          	li	a5,47
    80004628:	02f70363          	beq	a4,a5,8000464e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000462c:	ffffe097          	auipc	ra,0xffffe
    80004630:	986080e7          	jalr	-1658(ra) # 80001fb2 <myproc>
    80004634:	17053503          	ld	a0,368(a0)
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	9f6080e7          	jalr	-1546(ra) # 8000402e <idup>
    80004640:	89aa                	mv	s3,a0
  while(*path == '/')
    80004642:	02f00913          	li	s2,47
  len = path - s;
    80004646:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004648:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000464a:	4c05                	li	s8,1
    8000464c:	a865                	j	80004704 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000464e:	4585                	li	a1,1
    80004650:	4505                	li	a0,1
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	6e6080e7          	jalr	1766(ra) # 80003d38 <iget>
    8000465a:	89aa                	mv	s3,a0
    8000465c:	b7dd                	j	80004642 <namex+0x42>
      iunlockput(ip);
    8000465e:	854e                	mv	a0,s3
    80004660:	00000097          	auipc	ra,0x0
    80004664:	c6e080e7          	jalr	-914(ra) # 800042ce <iunlockput>
      return 0;
    80004668:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000466a:	854e                	mv	a0,s3
    8000466c:	60e6                	ld	ra,88(sp)
    8000466e:	6446                	ld	s0,80(sp)
    80004670:	64a6                	ld	s1,72(sp)
    80004672:	6906                	ld	s2,64(sp)
    80004674:	79e2                	ld	s3,56(sp)
    80004676:	7a42                	ld	s4,48(sp)
    80004678:	7aa2                	ld	s5,40(sp)
    8000467a:	7b02                	ld	s6,32(sp)
    8000467c:	6be2                	ld	s7,24(sp)
    8000467e:	6c42                	ld	s8,16(sp)
    80004680:	6ca2                	ld	s9,8(sp)
    80004682:	6125                	addi	sp,sp,96
    80004684:	8082                	ret
      iunlock(ip);
    80004686:	854e                	mv	a0,s3
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	aa6080e7          	jalr	-1370(ra) # 8000412e <iunlock>
      return ip;
    80004690:	bfe9                	j	8000466a <namex+0x6a>
      iunlockput(ip);
    80004692:	854e                	mv	a0,s3
    80004694:	00000097          	auipc	ra,0x0
    80004698:	c3a080e7          	jalr	-966(ra) # 800042ce <iunlockput>
      return 0;
    8000469c:	89d2                	mv	s3,s4
    8000469e:	b7f1                	j	8000466a <namex+0x6a>
  len = path - s;
    800046a0:	40b48633          	sub	a2,s1,a1
    800046a4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800046a8:	094cd463          	bge	s9,s4,80004730 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800046ac:	4639                	li	a2,14
    800046ae:	8556                	mv	a0,s5
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	6b4080e7          	jalr	1716(ra) # 80000d64 <memmove>
  while(*path == '/')
    800046b8:	0004c783          	lbu	a5,0(s1)
    800046bc:	01279763          	bne	a5,s2,800046ca <namex+0xca>
    path++;
    800046c0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046c2:	0004c783          	lbu	a5,0(s1)
    800046c6:	ff278de3          	beq	a5,s2,800046c0 <namex+0xc0>
    ilock(ip);
    800046ca:	854e                	mv	a0,s3
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	9a0080e7          	jalr	-1632(ra) # 8000406c <ilock>
    if(ip->type != T_DIR){
    800046d4:	04499783          	lh	a5,68(s3)
    800046d8:	f98793e3          	bne	a5,s8,8000465e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800046dc:	000b0563          	beqz	s6,800046e6 <namex+0xe6>
    800046e0:	0004c783          	lbu	a5,0(s1)
    800046e4:	d3cd                	beqz	a5,80004686 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800046e6:	865e                	mv	a2,s7
    800046e8:	85d6                	mv	a1,s5
    800046ea:	854e                	mv	a0,s3
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	e64080e7          	jalr	-412(ra) # 80004550 <dirlookup>
    800046f4:	8a2a                	mv	s4,a0
    800046f6:	dd51                	beqz	a0,80004692 <namex+0x92>
    iunlockput(ip);
    800046f8:	854e                	mv	a0,s3
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	bd4080e7          	jalr	-1068(ra) # 800042ce <iunlockput>
    ip = next;
    80004702:	89d2                	mv	s3,s4
  while(*path == '/')
    80004704:	0004c783          	lbu	a5,0(s1)
    80004708:	05279763          	bne	a5,s2,80004756 <namex+0x156>
    path++;
    8000470c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000470e:	0004c783          	lbu	a5,0(s1)
    80004712:	ff278de3          	beq	a5,s2,8000470c <namex+0x10c>
  if(*path == 0)
    80004716:	c79d                	beqz	a5,80004744 <namex+0x144>
    path++;
    80004718:	85a6                	mv	a1,s1
  len = path - s;
    8000471a:	8a5e                	mv	s4,s7
    8000471c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000471e:	01278963          	beq	a5,s2,80004730 <namex+0x130>
    80004722:	dfbd                	beqz	a5,800046a0 <namex+0xa0>
    path++;
    80004724:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004726:	0004c783          	lbu	a5,0(s1)
    8000472a:	ff279ce3          	bne	a5,s2,80004722 <namex+0x122>
    8000472e:	bf8d                	j	800046a0 <namex+0xa0>
    memmove(name, s, len);
    80004730:	2601                	sext.w	a2,a2
    80004732:	8556                	mv	a0,s5
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	630080e7          	jalr	1584(ra) # 80000d64 <memmove>
    name[len] = 0;
    8000473c:	9a56                	add	s4,s4,s5
    8000473e:	000a0023          	sb	zero,0(s4)
    80004742:	bf9d                	j	800046b8 <namex+0xb8>
  if(nameiparent){
    80004744:	f20b03e3          	beqz	s6,8000466a <namex+0x6a>
    iput(ip);
    80004748:	854e                	mv	a0,s3
    8000474a:	00000097          	auipc	ra,0x0
    8000474e:	adc080e7          	jalr	-1316(ra) # 80004226 <iput>
    return 0;
    80004752:	4981                	li	s3,0
    80004754:	bf19                	j	8000466a <namex+0x6a>
  if(*path == 0)
    80004756:	d7fd                	beqz	a5,80004744 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004758:	0004c783          	lbu	a5,0(s1)
    8000475c:	85a6                	mv	a1,s1
    8000475e:	b7d1                	j	80004722 <namex+0x122>

0000000080004760 <dirlink>:
{
    80004760:	7139                	addi	sp,sp,-64
    80004762:	fc06                	sd	ra,56(sp)
    80004764:	f822                	sd	s0,48(sp)
    80004766:	f426                	sd	s1,40(sp)
    80004768:	f04a                	sd	s2,32(sp)
    8000476a:	ec4e                	sd	s3,24(sp)
    8000476c:	e852                	sd	s4,16(sp)
    8000476e:	0080                	addi	s0,sp,64
    80004770:	892a                	mv	s2,a0
    80004772:	8a2e                	mv	s4,a1
    80004774:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004776:	4601                	li	a2,0
    80004778:	00000097          	auipc	ra,0x0
    8000477c:	dd8080e7          	jalr	-552(ra) # 80004550 <dirlookup>
    80004780:	e93d                	bnez	a0,800047f6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004782:	04c92483          	lw	s1,76(s2)
    80004786:	c49d                	beqz	s1,800047b4 <dirlink+0x54>
    80004788:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000478a:	4741                	li	a4,16
    8000478c:	86a6                	mv	a3,s1
    8000478e:	fc040613          	addi	a2,s0,-64
    80004792:	4581                	li	a1,0
    80004794:	854a                	mv	a0,s2
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	b8a080e7          	jalr	-1142(ra) # 80004320 <readi>
    8000479e:	47c1                	li	a5,16
    800047a0:	06f51163          	bne	a0,a5,80004802 <dirlink+0xa2>
    if(de.inum == 0)
    800047a4:	fc045783          	lhu	a5,-64(s0)
    800047a8:	c791                	beqz	a5,800047b4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047aa:	24c1                	addiw	s1,s1,16
    800047ac:	04c92783          	lw	a5,76(s2)
    800047b0:	fcf4ede3          	bltu	s1,a5,8000478a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800047b4:	4639                	li	a2,14
    800047b6:	85d2                	mv	a1,s4
    800047b8:	fc240513          	addi	a0,s0,-62
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	65c080e7          	jalr	1628(ra) # 80000e18 <strncpy>
  de.inum = inum;
    800047c4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047c8:	4741                	li	a4,16
    800047ca:	86a6                	mv	a3,s1
    800047cc:	fc040613          	addi	a2,s0,-64
    800047d0:	4581                	li	a1,0
    800047d2:	854a                	mv	a0,s2
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	c44080e7          	jalr	-956(ra) # 80004418 <writei>
    800047dc:	872a                	mv	a4,a0
    800047de:	47c1                	li	a5,16
  return 0;
    800047e0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047e2:	02f71863          	bne	a4,a5,80004812 <dirlink+0xb2>
}
    800047e6:	70e2                	ld	ra,56(sp)
    800047e8:	7442                	ld	s0,48(sp)
    800047ea:	74a2                	ld	s1,40(sp)
    800047ec:	7902                	ld	s2,32(sp)
    800047ee:	69e2                	ld	s3,24(sp)
    800047f0:	6a42                	ld	s4,16(sp)
    800047f2:	6121                	addi	sp,sp,64
    800047f4:	8082                	ret
    iput(ip);
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	a30080e7          	jalr	-1488(ra) # 80004226 <iput>
    return -1;
    800047fe:	557d                	li	a0,-1
    80004800:	b7dd                	j	800047e6 <dirlink+0x86>
      panic("dirlink read");
    80004802:	00004517          	auipc	a0,0x4
    80004806:	efe50513          	addi	a0,a0,-258 # 80008700 <syscalls+0x1e0>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	d34080e7          	jalr	-716(ra) # 8000053e <panic>
    panic("dirlink");
    80004812:	00004517          	auipc	a0,0x4
    80004816:	ffe50513          	addi	a0,a0,-2 # 80008810 <syscalls+0x2f0>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	d24080e7          	jalr	-732(ra) # 8000053e <panic>

0000000080004822 <namei>:

struct inode*
namei(char *path)
{
    80004822:	1101                	addi	sp,sp,-32
    80004824:	ec06                	sd	ra,24(sp)
    80004826:	e822                	sd	s0,16(sp)
    80004828:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000482a:	fe040613          	addi	a2,s0,-32
    8000482e:	4581                	li	a1,0
    80004830:	00000097          	auipc	ra,0x0
    80004834:	dd0080e7          	jalr	-560(ra) # 80004600 <namex>
}
    80004838:	60e2                	ld	ra,24(sp)
    8000483a:	6442                	ld	s0,16(sp)
    8000483c:	6105                	addi	sp,sp,32
    8000483e:	8082                	ret

0000000080004840 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004840:	1141                	addi	sp,sp,-16
    80004842:	e406                	sd	ra,8(sp)
    80004844:	e022                	sd	s0,0(sp)
    80004846:	0800                	addi	s0,sp,16
    80004848:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000484a:	4585                	li	a1,1
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	db4080e7          	jalr	-588(ra) # 80004600 <namex>
}
    80004854:	60a2                	ld	ra,8(sp)
    80004856:	6402                	ld	s0,0(sp)
    80004858:	0141                	addi	sp,sp,16
    8000485a:	8082                	ret

000000008000485c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000485c:	1101                	addi	sp,sp,-32
    8000485e:	ec06                	sd	ra,24(sp)
    80004860:	e822                	sd	s0,16(sp)
    80004862:	e426                	sd	s1,8(sp)
    80004864:	e04a                	sd	s2,0(sp)
    80004866:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004868:	0001d917          	auipc	s2,0x1d
    8000486c:	3b090913          	addi	s2,s2,944 # 80021c18 <log>
    80004870:	01892583          	lw	a1,24(s2)
    80004874:	02892503          	lw	a0,40(s2)
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	ff2080e7          	jalr	-14(ra) # 8000386a <bread>
    80004880:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004882:	02c92683          	lw	a3,44(s2)
    80004886:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004888:	02d05763          	blez	a3,800048b6 <write_head+0x5a>
    8000488c:	0001d797          	auipc	a5,0x1d
    80004890:	3bc78793          	addi	a5,a5,956 # 80021c48 <log+0x30>
    80004894:	05c50713          	addi	a4,a0,92
    80004898:	36fd                	addiw	a3,a3,-1
    8000489a:	1682                	slli	a3,a3,0x20
    8000489c:	9281                	srli	a3,a3,0x20
    8000489e:	068a                	slli	a3,a3,0x2
    800048a0:	0001d617          	auipc	a2,0x1d
    800048a4:	3ac60613          	addi	a2,a2,940 # 80021c4c <log+0x34>
    800048a8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800048aa:	4390                	lw	a2,0(a5)
    800048ac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800048ae:	0791                	addi	a5,a5,4
    800048b0:	0711                	addi	a4,a4,4
    800048b2:	fed79ce3          	bne	a5,a3,800048aa <write_head+0x4e>
  }
  bwrite(buf);
    800048b6:	8526                	mv	a0,s1
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	0a4080e7          	jalr	164(ra) # 8000395c <bwrite>
  brelse(buf);
    800048c0:	8526                	mv	a0,s1
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	0d8080e7          	jalr	216(ra) # 8000399a <brelse>
}
    800048ca:	60e2                	ld	ra,24(sp)
    800048cc:	6442                	ld	s0,16(sp)
    800048ce:	64a2                	ld	s1,8(sp)
    800048d0:	6902                	ld	s2,0(sp)
    800048d2:	6105                	addi	sp,sp,32
    800048d4:	8082                	ret

00000000800048d6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800048d6:	0001d797          	auipc	a5,0x1d
    800048da:	36e7a783          	lw	a5,878(a5) # 80021c44 <log+0x2c>
    800048de:	0af05d63          	blez	a5,80004998 <install_trans+0xc2>
{
    800048e2:	7139                	addi	sp,sp,-64
    800048e4:	fc06                	sd	ra,56(sp)
    800048e6:	f822                	sd	s0,48(sp)
    800048e8:	f426                	sd	s1,40(sp)
    800048ea:	f04a                	sd	s2,32(sp)
    800048ec:	ec4e                	sd	s3,24(sp)
    800048ee:	e852                	sd	s4,16(sp)
    800048f0:	e456                	sd	s5,8(sp)
    800048f2:	e05a                	sd	s6,0(sp)
    800048f4:	0080                	addi	s0,sp,64
    800048f6:	8b2a                	mv	s6,a0
    800048f8:	0001da97          	auipc	s5,0x1d
    800048fc:	350a8a93          	addi	s5,s5,848 # 80021c48 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004900:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004902:	0001d997          	auipc	s3,0x1d
    80004906:	31698993          	addi	s3,s3,790 # 80021c18 <log>
    8000490a:	a035                	j	80004936 <install_trans+0x60>
      bunpin(dbuf);
    8000490c:	8526                	mv	a0,s1
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	166080e7          	jalr	358(ra) # 80003a74 <bunpin>
    brelse(lbuf);
    80004916:	854a                	mv	a0,s2
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	082080e7          	jalr	130(ra) # 8000399a <brelse>
    brelse(dbuf);
    80004920:	8526                	mv	a0,s1
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	078080e7          	jalr	120(ra) # 8000399a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000492a:	2a05                	addiw	s4,s4,1
    8000492c:	0a91                	addi	s5,s5,4
    8000492e:	02c9a783          	lw	a5,44(s3)
    80004932:	04fa5963          	bge	s4,a5,80004984 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004936:	0189a583          	lw	a1,24(s3)
    8000493a:	014585bb          	addw	a1,a1,s4
    8000493e:	2585                	addiw	a1,a1,1
    80004940:	0289a503          	lw	a0,40(s3)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	f26080e7          	jalr	-218(ra) # 8000386a <bread>
    8000494c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000494e:	000aa583          	lw	a1,0(s5)
    80004952:	0289a503          	lw	a0,40(s3)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	f14080e7          	jalr	-236(ra) # 8000386a <bread>
    8000495e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004960:	40000613          	li	a2,1024
    80004964:	05890593          	addi	a1,s2,88
    80004968:	05850513          	addi	a0,a0,88
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	3f8080e7          	jalr	1016(ra) # 80000d64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004974:	8526                	mv	a0,s1
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	fe6080e7          	jalr	-26(ra) # 8000395c <bwrite>
    if(recovering == 0)
    8000497e:	f80b1ce3          	bnez	s6,80004916 <install_trans+0x40>
    80004982:	b769                	j	8000490c <install_trans+0x36>
}
    80004984:	70e2                	ld	ra,56(sp)
    80004986:	7442                	ld	s0,48(sp)
    80004988:	74a2                	ld	s1,40(sp)
    8000498a:	7902                	ld	s2,32(sp)
    8000498c:	69e2                	ld	s3,24(sp)
    8000498e:	6a42                	ld	s4,16(sp)
    80004990:	6aa2                	ld	s5,8(sp)
    80004992:	6b02                	ld	s6,0(sp)
    80004994:	6121                	addi	sp,sp,64
    80004996:	8082                	ret
    80004998:	8082                	ret

000000008000499a <initlog>:
{
    8000499a:	7179                	addi	sp,sp,-48
    8000499c:	f406                	sd	ra,40(sp)
    8000499e:	f022                	sd	s0,32(sp)
    800049a0:	ec26                	sd	s1,24(sp)
    800049a2:	e84a                	sd	s2,16(sp)
    800049a4:	e44e                	sd	s3,8(sp)
    800049a6:	1800                	addi	s0,sp,48
    800049a8:	892a                	mv	s2,a0
    800049aa:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800049ac:	0001d497          	auipc	s1,0x1d
    800049b0:	26c48493          	addi	s1,s1,620 # 80021c18 <log>
    800049b4:	00004597          	auipc	a1,0x4
    800049b8:	d5c58593          	addi	a1,a1,-676 # 80008710 <syscalls+0x1f0>
    800049bc:	8526                	mv	a0,s1
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	196080e7          	jalr	406(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800049c6:	0149a583          	lw	a1,20(s3)
    800049ca:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800049cc:	0109a783          	lw	a5,16(s3)
    800049d0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800049d2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800049d6:	854a                	mv	a0,s2
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	e92080e7          	jalr	-366(ra) # 8000386a <bread>
  log.lh.n = lh->n;
    800049e0:	4d3c                	lw	a5,88(a0)
    800049e2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049e4:	02f05563          	blez	a5,80004a0e <initlog+0x74>
    800049e8:	05c50713          	addi	a4,a0,92
    800049ec:	0001d697          	auipc	a3,0x1d
    800049f0:	25c68693          	addi	a3,a3,604 # 80021c48 <log+0x30>
    800049f4:	37fd                	addiw	a5,a5,-1
    800049f6:	1782                	slli	a5,a5,0x20
    800049f8:	9381                	srli	a5,a5,0x20
    800049fa:	078a                	slli	a5,a5,0x2
    800049fc:	06050613          	addi	a2,a0,96
    80004a00:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004a02:	4310                	lw	a2,0(a4)
    80004a04:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004a06:	0711                	addi	a4,a4,4
    80004a08:	0691                	addi	a3,a3,4
    80004a0a:	fef71ce3          	bne	a4,a5,80004a02 <initlog+0x68>
  brelse(buf);
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	f8c080e7          	jalr	-116(ra) # 8000399a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004a16:	4505                	li	a0,1
    80004a18:	00000097          	auipc	ra,0x0
    80004a1c:	ebe080e7          	jalr	-322(ra) # 800048d6 <install_trans>
  log.lh.n = 0;
    80004a20:	0001d797          	auipc	a5,0x1d
    80004a24:	2207a223          	sw	zero,548(a5) # 80021c44 <log+0x2c>
  write_head(); // clear the log
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	e34080e7          	jalr	-460(ra) # 8000485c <write_head>
}
    80004a30:	70a2                	ld	ra,40(sp)
    80004a32:	7402                	ld	s0,32(sp)
    80004a34:	64e2                	ld	s1,24(sp)
    80004a36:	6942                	ld	s2,16(sp)
    80004a38:	69a2                	ld	s3,8(sp)
    80004a3a:	6145                	addi	sp,sp,48
    80004a3c:	8082                	ret

0000000080004a3e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a3e:	1101                	addi	sp,sp,-32
    80004a40:	ec06                	sd	ra,24(sp)
    80004a42:	e822                	sd	s0,16(sp)
    80004a44:	e426                	sd	s1,8(sp)
    80004a46:	e04a                	sd	s2,0(sp)
    80004a48:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a4a:	0001d517          	auipc	a0,0x1d
    80004a4e:	1ce50513          	addi	a0,a0,462 # 80021c18 <log>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	192080e7          	jalr	402(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004a5a:	0001d497          	auipc	s1,0x1d
    80004a5e:	1be48493          	addi	s1,s1,446 # 80021c18 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a62:	4979                	li	s2,30
    80004a64:	a039                	j	80004a72 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a66:	85a6                	mv	a1,s1
    80004a68:	8526                	mv	a0,s1
    80004a6a:	ffffe097          	auipc	ra,0xffffe
    80004a6e:	e2e080e7          	jalr	-466(ra) # 80002898 <sleep>
    if(log.committing){
    80004a72:	50dc                	lw	a5,36(s1)
    80004a74:	fbed                	bnez	a5,80004a66 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a76:	509c                	lw	a5,32(s1)
    80004a78:	0017871b          	addiw	a4,a5,1
    80004a7c:	0007069b          	sext.w	a3,a4
    80004a80:	0027179b          	slliw	a5,a4,0x2
    80004a84:	9fb9                	addw	a5,a5,a4
    80004a86:	0017979b          	slliw	a5,a5,0x1
    80004a8a:	54d8                	lw	a4,44(s1)
    80004a8c:	9fb9                	addw	a5,a5,a4
    80004a8e:	00f95963          	bge	s2,a5,80004aa0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a92:	85a6                	mv	a1,s1
    80004a94:	8526                	mv	a0,s1
    80004a96:	ffffe097          	auipc	ra,0xffffe
    80004a9a:	e02080e7          	jalr	-510(ra) # 80002898 <sleep>
    80004a9e:	bfd1                	j	80004a72 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004aa0:	0001d517          	auipc	a0,0x1d
    80004aa4:	17850513          	addi	a0,a0,376 # 80021c18 <log>
    80004aa8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	200080e7          	jalr	512(ra) # 80000caa <release>
      break;
    }
  }
}
    80004ab2:	60e2                	ld	ra,24(sp)
    80004ab4:	6442                	ld	s0,16(sp)
    80004ab6:	64a2                	ld	s1,8(sp)
    80004ab8:	6902                	ld	s2,0(sp)
    80004aba:	6105                	addi	sp,sp,32
    80004abc:	8082                	ret

0000000080004abe <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004abe:	7139                	addi	sp,sp,-64
    80004ac0:	fc06                	sd	ra,56(sp)
    80004ac2:	f822                	sd	s0,48(sp)
    80004ac4:	f426                	sd	s1,40(sp)
    80004ac6:	f04a                	sd	s2,32(sp)
    80004ac8:	ec4e                	sd	s3,24(sp)
    80004aca:	e852                	sd	s4,16(sp)
    80004acc:	e456                	sd	s5,8(sp)
    80004ace:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004ad0:	0001d497          	auipc	s1,0x1d
    80004ad4:	14848493          	addi	s1,s1,328 # 80021c18 <log>
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	10a080e7          	jalr	266(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004ae2:	509c                	lw	a5,32(s1)
    80004ae4:	37fd                	addiw	a5,a5,-1
    80004ae6:	0007891b          	sext.w	s2,a5
    80004aea:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004aec:	50dc                	lw	a5,36(s1)
    80004aee:	efb9                	bnez	a5,80004b4c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004af0:	06091663          	bnez	s2,80004b5c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004af4:	0001d497          	auipc	s1,0x1d
    80004af8:	12448493          	addi	s1,s1,292 # 80021c18 <log>
    80004afc:	4785                	li	a5,1
    80004afe:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	1a8080e7          	jalr	424(ra) # 80000caa <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b0a:	54dc                	lw	a5,44(s1)
    80004b0c:	06f04763          	bgtz	a5,80004b7a <end_op+0xbc>
    acquire(&log.lock);
    80004b10:	0001d497          	auipc	s1,0x1d
    80004b14:	10848493          	addi	s1,s1,264 # 80021c18 <log>
    80004b18:	8526                	mv	a0,s1
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	0ca080e7          	jalr	202(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004b22:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b26:	8526                	mv	a0,s1
    80004b28:	ffffe097          	auipc	ra,0xffffe
    80004b2c:	f28080e7          	jalr	-216(ra) # 80002a50 <wakeup>
    release(&log.lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	178080e7          	jalr	376(ra) # 80000caa <release>
}
    80004b3a:	70e2                	ld	ra,56(sp)
    80004b3c:	7442                	ld	s0,48(sp)
    80004b3e:	74a2                	ld	s1,40(sp)
    80004b40:	7902                	ld	s2,32(sp)
    80004b42:	69e2                	ld	s3,24(sp)
    80004b44:	6a42                	ld	s4,16(sp)
    80004b46:	6aa2                	ld	s5,8(sp)
    80004b48:	6121                	addi	sp,sp,64
    80004b4a:	8082                	ret
    panic("log.committing");
    80004b4c:	00004517          	auipc	a0,0x4
    80004b50:	bcc50513          	addi	a0,a0,-1076 # 80008718 <syscalls+0x1f8>
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	9ea080e7          	jalr	-1558(ra) # 8000053e <panic>
    wakeup(&log);
    80004b5c:	0001d497          	auipc	s1,0x1d
    80004b60:	0bc48493          	addi	s1,s1,188 # 80021c18 <log>
    80004b64:	8526                	mv	a0,s1
    80004b66:	ffffe097          	auipc	ra,0xffffe
    80004b6a:	eea080e7          	jalr	-278(ra) # 80002a50 <wakeup>
  release(&log.lock);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	13a080e7          	jalr	314(ra) # 80000caa <release>
  if(do_commit){
    80004b78:	b7c9                	j	80004b3a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b7a:	0001da97          	auipc	s5,0x1d
    80004b7e:	0cea8a93          	addi	s5,s5,206 # 80021c48 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b82:	0001da17          	auipc	s4,0x1d
    80004b86:	096a0a13          	addi	s4,s4,150 # 80021c18 <log>
    80004b8a:	018a2583          	lw	a1,24(s4)
    80004b8e:	012585bb          	addw	a1,a1,s2
    80004b92:	2585                	addiw	a1,a1,1
    80004b94:	028a2503          	lw	a0,40(s4)
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	cd2080e7          	jalr	-814(ra) # 8000386a <bread>
    80004ba0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ba2:	000aa583          	lw	a1,0(s5)
    80004ba6:	028a2503          	lw	a0,40(s4)
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	cc0080e7          	jalr	-832(ra) # 8000386a <bread>
    80004bb2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004bb4:	40000613          	li	a2,1024
    80004bb8:	05850593          	addi	a1,a0,88
    80004bbc:	05848513          	addi	a0,s1,88
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	1a4080e7          	jalr	420(ra) # 80000d64 <memmove>
    bwrite(to);  // write the log
    80004bc8:	8526                	mv	a0,s1
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	d92080e7          	jalr	-622(ra) # 8000395c <bwrite>
    brelse(from);
    80004bd2:	854e                	mv	a0,s3
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	dc6080e7          	jalr	-570(ra) # 8000399a <brelse>
    brelse(to);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	dbc080e7          	jalr	-580(ra) # 8000399a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004be6:	2905                	addiw	s2,s2,1
    80004be8:	0a91                	addi	s5,s5,4
    80004bea:	02ca2783          	lw	a5,44(s4)
    80004bee:	f8f94ee3          	blt	s2,a5,80004b8a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bf2:	00000097          	auipc	ra,0x0
    80004bf6:	c6a080e7          	jalr	-918(ra) # 8000485c <write_head>
    install_trans(0); // Now install writes to home locations
    80004bfa:	4501                	li	a0,0
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	cda080e7          	jalr	-806(ra) # 800048d6 <install_trans>
    log.lh.n = 0;
    80004c04:	0001d797          	auipc	a5,0x1d
    80004c08:	0407a023          	sw	zero,64(a5) # 80021c44 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	c50080e7          	jalr	-944(ra) # 8000485c <write_head>
    80004c14:	bdf5                	j	80004b10 <end_op+0x52>

0000000080004c16 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004c16:	1101                	addi	sp,sp,-32
    80004c18:	ec06                	sd	ra,24(sp)
    80004c1a:	e822                	sd	s0,16(sp)
    80004c1c:	e426                	sd	s1,8(sp)
    80004c1e:	e04a                	sd	s2,0(sp)
    80004c20:	1000                	addi	s0,sp,32
    80004c22:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004c24:	0001d917          	auipc	s2,0x1d
    80004c28:	ff490913          	addi	s2,s2,-12 # 80021c18 <log>
    80004c2c:	854a                	mv	a0,s2
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	fb6080e7          	jalr	-74(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c36:	02c92603          	lw	a2,44(s2)
    80004c3a:	47f5                	li	a5,29
    80004c3c:	06c7c563          	blt	a5,a2,80004ca6 <log_write+0x90>
    80004c40:	0001d797          	auipc	a5,0x1d
    80004c44:	ff47a783          	lw	a5,-12(a5) # 80021c34 <log+0x1c>
    80004c48:	37fd                	addiw	a5,a5,-1
    80004c4a:	04f65e63          	bge	a2,a5,80004ca6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c4e:	0001d797          	auipc	a5,0x1d
    80004c52:	fea7a783          	lw	a5,-22(a5) # 80021c38 <log+0x20>
    80004c56:	06f05063          	blez	a5,80004cb6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c5a:	4781                	li	a5,0
    80004c5c:	06c05563          	blez	a2,80004cc6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c60:	44cc                	lw	a1,12(s1)
    80004c62:	0001d717          	auipc	a4,0x1d
    80004c66:	fe670713          	addi	a4,a4,-26 # 80021c48 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c6a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c6c:	4314                	lw	a3,0(a4)
    80004c6e:	04b68c63          	beq	a3,a1,80004cc6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c72:	2785                	addiw	a5,a5,1
    80004c74:	0711                	addi	a4,a4,4
    80004c76:	fef61be3          	bne	a2,a5,80004c6c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c7a:	0621                	addi	a2,a2,8
    80004c7c:	060a                	slli	a2,a2,0x2
    80004c7e:	0001d797          	auipc	a5,0x1d
    80004c82:	f9a78793          	addi	a5,a5,-102 # 80021c18 <log>
    80004c86:	963e                	add	a2,a2,a5
    80004c88:	44dc                	lw	a5,12(s1)
    80004c8a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	daa080e7          	jalr	-598(ra) # 80003a38 <bpin>
    log.lh.n++;
    80004c96:	0001d717          	auipc	a4,0x1d
    80004c9a:	f8270713          	addi	a4,a4,-126 # 80021c18 <log>
    80004c9e:	575c                	lw	a5,44(a4)
    80004ca0:	2785                	addiw	a5,a5,1
    80004ca2:	d75c                	sw	a5,44(a4)
    80004ca4:	a835                	j	80004ce0 <log_write+0xca>
    panic("too big a transaction");
    80004ca6:	00004517          	auipc	a0,0x4
    80004caa:	a8250513          	addi	a0,a0,-1406 # 80008728 <syscalls+0x208>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004cb6:	00004517          	auipc	a0,0x4
    80004cba:	a8a50513          	addi	a0,a0,-1398 # 80008740 <syscalls+0x220>
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004cc6:	00878713          	addi	a4,a5,8
    80004cca:	00271693          	slli	a3,a4,0x2
    80004cce:	0001d717          	auipc	a4,0x1d
    80004cd2:	f4a70713          	addi	a4,a4,-182 # 80021c18 <log>
    80004cd6:	9736                	add	a4,a4,a3
    80004cd8:	44d4                	lw	a3,12(s1)
    80004cda:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004cdc:	faf608e3          	beq	a2,a5,80004c8c <log_write+0x76>
  }
  release(&log.lock);
    80004ce0:	0001d517          	auipc	a0,0x1d
    80004ce4:	f3850513          	addi	a0,a0,-200 # 80021c18 <log>
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	fc2080e7          	jalr	-62(ra) # 80000caa <release>
}
    80004cf0:	60e2                	ld	ra,24(sp)
    80004cf2:	6442                	ld	s0,16(sp)
    80004cf4:	64a2                	ld	s1,8(sp)
    80004cf6:	6902                	ld	s2,0(sp)
    80004cf8:	6105                	addi	sp,sp,32
    80004cfa:	8082                	ret

0000000080004cfc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004cfc:	1101                	addi	sp,sp,-32
    80004cfe:	ec06                	sd	ra,24(sp)
    80004d00:	e822                	sd	s0,16(sp)
    80004d02:	e426                	sd	s1,8(sp)
    80004d04:	e04a                	sd	s2,0(sp)
    80004d06:	1000                	addi	s0,sp,32
    80004d08:	84aa                	mv	s1,a0
    80004d0a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004d0c:	00004597          	auipc	a1,0x4
    80004d10:	a5458593          	addi	a1,a1,-1452 # 80008760 <syscalls+0x240>
    80004d14:	0521                	addi	a0,a0,8
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	e3e080e7          	jalr	-450(ra) # 80000b54 <initlock>
  lk->name = name;
    80004d1e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004d22:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d26:	0204a423          	sw	zero,40(s1)
}
    80004d2a:	60e2                	ld	ra,24(sp)
    80004d2c:	6442                	ld	s0,16(sp)
    80004d2e:	64a2                	ld	s1,8(sp)
    80004d30:	6902                	ld	s2,0(sp)
    80004d32:	6105                	addi	sp,sp,32
    80004d34:	8082                	ret

0000000080004d36 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d36:	1101                	addi	sp,sp,-32
    80004d38:	ec06                	sd	ra,24(sp)
    80004d3a:	e822                	sd	s0,16(sp)
    80004d3c:	e426                	sd	s1,8(sp)
    80004d3e:	e04a                	sd	s2,0(sp)
    80004d40:	1000                	addi	s0,sp,32
    80004d42:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d44:	00850913          	addi	s2,a0,8
    80004d48:	854a                	mv	a0,s2
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	e9a080e7          	jalr	-358(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004d52:	409c                	lw	a5,0(s1)
    80004d54:	cb89                	beqz	a5,80004d66 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d56:	85ca                	mv	a1,s2
    80004d58:	8526                	mv	a0,s1
    80004d5a:	ffffe097          	auipc	ra,0xffffe
    80004d5e:	b3e080e7          	jalr	-1218(ra) # 80002898 <sleep>
  while (lk->locked) {
    80004d62:	409c                	lw	a5,0(s1)
    80004d64:	fbed                	bnez	a5,80004d56 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d66:	4785                	li	a5,1
    80004d68:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	248080e7          	jalr	584(ra) # 80001fb2 <myproc>
    80004d72:	591c                	lw	a5,48(a0)
    80004d74:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d76:	854a                	mv	a0,s2
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	f32080e7          	jalr	-206(ra) # 80000caa <release>
}
    80004d80:	60e2                	ld	ra,24(sp)
    80004d82:	6442                	ld	s0,16(sp)
    80004d84:	64a2                	ld	s1,8(sp)
    80004d86:	6902                	ld	s2,0(sp)
    80004d88:	6105                	addi	sp,sp,32
    80004d8a:	8082                	ret

0000000080004d8c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d8c:	1101                	addi	sp,sp,-32
    80004d8e:	ec06                	sd	ra,24(sp)
    80004d90:	e822                	sd	s0,16(sp)
    80004d92:	e426                	sd	s1,8(sp)
    80004d94:	e04a                	sd	s2,0(sp)
    80004d96:	1000                	addi	s0,sp,32
    80004d98:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d9a:	00850913          	addi	s2,a0,8
    80004d9e:	854a                	mv	a0,s2
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	e44080e7          	jalr	-444(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004da8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004dac:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffe097          	auipc	ra,0xffffe
    80004db6:	c9e080e7          	jalr	-866(ra) # 80002a50 <wakeup>
  release(&lk->lk);
    80004dba:	854a                	mv	a0,s2
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	eee080e7          	jalr	-274(ra) # 80000caa <release>
}
    80004dc4:	60e2                	ld	ra,24(sp)
    80004dc6:	6442                	ld	s0,16(sp)
    80004dc8:	64a2                	ld	s1,8(sp)
    80004dca:	6902                	ld	s2,0(sp)
    80004dcc:	6105                	addi	sp,sp,32
    80004dce:	8082                	ret

0000000080004dd0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004dd0:	7179                	addi	sp,sp,-48
    80004dd2:	f406                	sd	ra,40(sp)
    80004dd4:	f022                	sd	s0,32(sp)
    80004dd6:	ec26                	sd	s1,24(sp)
    80004dd8:	e84a                	sd	s2,16(sp)
    80004dda:	e44e                	sd	s3,8(sp)
    80004ddc:	1800                	addi	s0,sp,48
    80004dde:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004de0:	00850913          	addi	s2,a0,8
    80004de4:	854a                	mv	a0,s2
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	dfe080e7          	jalr	-514(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dee:	409c                	lw	a5,0(s1)
    80004df0:	ef99                	bnez	a5,80004e0e <holdingsleep+0x3e>
    80004df2:	4481                	li	s1,0
  release(&lk->lk);
    80004df4:	854a                	mv	a0,s2
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	eb4080e7          	jalr	-332(ra) # 80000caa <release>
  return r;
}
    80004dfe:	8526                	mv	a0,s1
    80004e00:	70a2                	ld	ra,40(sp)
    80004e02:	7402                	ld	s0,32(sp)
    80004e04:	64e2                	ld	s1,24(sp)
    80004e06:	6942                	ld	s2,16(sp)
    80004e08:	69a2                	ld	s3,8(sp)
    80004e0a:	6145                	addi	sp,sp,48
    80004e0c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e0e:	0284a983          	lw	s3,40(s1)
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	1a0080e7          	jalr	416(ra) # 80001fb2 <myproc>
    80004e1a:	5904                	lw	s1,48(a0)
    80004e1c:	413484b3          	sub	s1,s1,s3
    80004e20:	0014b493          	seqz	s1,s1
    80004e24:	bfc1                	j	80004df4 <holdingsleep+0x24>

0000000080004e26 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004e26:	1141                	addi	sp,sp,-16
    80004e28:	e406                	sd	ra,8(sp)
    80004e2a:	e022                	sd	s0,0(sp)
    80004e2c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e2e:	00004597          	auipc	a1,0x4
    80004e32:	94258593          	addi	a1,a1,-1726 # 80008770 <syscalls+0x250>
    80004e36:	0001d517          	auipc	a0,0x1d
    80004e3a:	f2a50513          	addi	a0,a0,-214 # 80021d60 <ftable>
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	d16080e7          	jalr	-746(ra) # 80000b54 <initlock>
}
    80004e46:	60a2                	ld	ra,8(sp)
    80004e48:	6402                	ld	s0,0(sp)
    80004e4a:	0141                	addi	sp,sp,16
    80004e4c:	8082                	ret

0000000080004e4e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e4e:	1101                	addi	sp,sp,-32
    80004e50:	ec06                	sd	ra,24(sp)
    80004e52:	e822                	sd	s0,16(sp)
    80004e54:	e426                	sd	s1,8(sp)
    80004e56:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e58:	0001d517          	auipc	a0,0x1d
    80004e5c:	f0850513          	addi	a0,a0,-248 # 80021d60 <ftable>
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	d84080e7          	jalr	-636(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e68:	0001d497          	auipc	s1,0x1d
    80004e6c:	f1048493          	addi	s1,s1,-240 # 80021d78 <ftable+0x18>
    80004e70:	0001e717          	auipc	a4,0x1e
    80004e74:	ea870713          	addi	a4,a4,-344 # 80022d18 <ftable+0xfb8>
    if(f->ref == 0){
    80004e78:	40dc                	lw	a5,4(s1)
    80004e7a:	cf99                	beqz	a5,80004e98 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e7c:	02848493          	addi	s1,s1,40
    80004e80:	fee49ce3          	bne	s1,a4,80004e78 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e84:	0001d517          	auipc	a0,0x1d
    80004e88:	edc50513          	addi	a0,a0,-292 # 80021d60 <ftable>
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	e1e080e7          	jalr	-482(ra) # 80000caa <release>
  return 0;
    80004e94:	4481                	li	s1,0
    80004e96:	a819                	j	80004eac <filealloc+0x5e>
      f->ref = 1;
    80004e98:	4785                	li	a5,1
    80004e9a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e9c:	0001d517          	auipc	a0,0x1d
    80004ea0:	ec450513          	addi	a0,a0,-316 # 80021d60 <ftable>
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	e06080e7          	jalr	-506(ra) # 80000caa <release>
}
    80004eac:	8526                	mv	a0,s1
    80004eae:	60e2                	ld	ra,24(sp)
    80004eb0:	6442                	ld	s0,16(sp)
    80004eb2:	64a2                	ld	s1,8(sp)
    80004eb4:	6105                	addi	sp,sp,32
    80004eb6:	8082                	ret

0000000080004eb8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004eb8:	1101                	addi	sp,sp,-32
    80004eba:	ec06                	sd	ra,24(sp)
    80004ebc:	e822                	sd	s0,16(sp)
    80004ebe:	e426                	sd	s1,8(sp)
    80004ec0:	1000                	addi	s0,sp,32
    80004ec2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ec4:	0001d517          	auipc	a0,0x1d
    80004ec8:	e9c50513          	addi	a0,a0,-356 # 80021d60 <ftable>
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	d18080e7          	jalr	-744(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ed4:	40dc                	lw	a5,4(s1)
    80004ed6:	02f05263          	blez	a5,80004efa <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004eda:	2785                	addiw	a5,a5,1
    80004edc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ede:	0001d517          	auipc	a0,0x1d
    80004ee2:	e8250513          	addi	a0,a0,-382 # 80021d60 <ftable>
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	dc4080e7          	jalr	-572(ra) # 80000caa <release>
  return f;
}
    80004eee:	8526                	mv	a0,s1
    80004ef0:	60e2                	ld	ra,24(sp)
    80004ef2:	6442                	ld	s0,16(sp)
    80004ef4:	64a2                	ld	s1,8(sp)
    80004ef6:	6105                	addi	sp,sp,32
    80004ef8:	8082                	ret
    panic("filedup");
    80004efa:	00004517          	auipc	a0,0x4
    80004efe:	87e50513          	addi	a0,a0,-1922 # 80008778 <syscalls+0x258>
    80004f02:	ffffb097          	auipc	ra,0xffffb
    80004f06:	63c080e7          	jalr	1596(ra) # 8000053e <panic>

0000000080004f0a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f0a:	7139                	addi	sp,sp,-64
    80004f0c:	fc06                	sd	ra,56(sp)
    80004f0e:	f822                	sd	s0,48(sp)
    80004f10:	f426                	sd	s1,40(sp)
    80004f12:	f04a                	sd	s2,32(sp)
    80004f14:	ec4e                	sd	s3,24(sp)
    80004f16:	e852                	sd	s4,16(sp)
    80004f18:	e456                	sd	s5,8(sp)
    80004f1a:	0080                	addi	s0,sp,64
    80004f1c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004f1e:	0001d517          	auipc	a0,0x1d
    80004f22:	e4250513          	addi	a0,a0,-446 # 80021d60 <ftable>
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	cbe080e7          	jalr	-834(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004f2e:	40dc                	lw	a5,4(s1)
    80004f30:	06f05163          	blez	a5,80004f92 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f34:	37fd                	addiw	a5,a5,-1
    80004f36:	0007871b          	sext.w	a4,a5
    80004f3a:	c0dc                	sw	a5,4(s1)
    80004f3c:	06e04363          	bgtz	a4,80004fa2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f40:	0004a903          	lw	s2,0(s1)
    80004f44:	0094ca83          	lbu	s5,9(s1)
    80004f48:	0104ba03          	ld	s4,16(s1)
    80004f4c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f50:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f54:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f58:	0001d517          	auipc	a0,0x1d
    80004f5c:	e0850513          	addi	a0,a0,-504 # 80021d60 <ftable>
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	d4a080e7          	jalr	-694(ra) # 80000caa <release>

  if(ff.type == FD_PIPE){
    80004f68:	4785                	li	a5,1
    80004f6a:	04f90d63          	beq	s2,a5,80004fc4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f6e:	3979                	addiw	s2,s2,-2
    80004f70:	4785                	li	a5,1
    80004f72:	0527e063          	bltu	a5,s2,80004fb2 <fileclose+0xa8>
    begin_op();
    80004f76:	00000097          	auipc	ra,0x0
    80004f7a:	ac8080e7          	jalr	-1336(ra) # 80004a3e <begin_op>
    iput(ff.ip);
    80004f7e:	854e                	mv	a0,s3
    80004f80:	fffff097          	auipc	ra,0xfffff
    80004f84:	2a6080e7          	jalr	678(ra) # 80004226 <iput>
    end_op();
    80004f88:	00000097          	auipc	ra,0x0
    80004f8c:	b36080e7          	jalr	-1226(ra) # 80004abe <end_op>
    80004f90:	a00d                	j	80004fb2 <fileclose+0xa8>
    panic("fileclose");
    80004f92:	00003517          	auipc	a0,0x3
    80004f96:	7ee50513          	addi	a0,a0,2030 # 80008780 <syscalls+0x260>
    80004f9a:	ffffb097          	auipc	ra,0xffffb
    80004f9e:	5a4080e7          	jalr	1444(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004fa2:	0001d517          	auipc	a0,0x1d
    80004fa6:	dbe50513          	addi	a0,a0,-578 # 80021d60 <ftable>
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	d00080e7          	jalr	-768(ra) # 80000caa <release>
  }
}
    80004fb2:	70e2                	ld	ra,56(sp)
    80004fb4:	7442                	ld	s0,48(sp)
    80004fb6:	74a2                	ld	s1,40(sp)
    80004fb8:	7902                	ld	s2,32(sp)
    80004fba:	69e2                	ld	s3,24(sp)
    80004fbc:	6a42                	ld	s4,16(sp)
    80004fbe:	6aa2                	ld	s5,8(sp)
    80004fc0:	6121                	addi	sp,sp,64
    80004fc2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004fc4:	85d6                	mv	a1,s5
    80004fc6:	8552                	mv	a0,s4
    80004fc8:	00000097          	auipc	ra,0x0
    80004fcc:	34c080e7          	jalr	844(ra) # 80005314 <pipeclose>
    80004fd0:	b7cd                	j	80004fb2 <fileclose+0xa8>

0000000080004fd2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004fd2:	715d                	addi	sp,sp,-80
    80004fd4:	e486                	sd	ra,72(sp)
    80004fd6:	e0a2                	sd	s0,64(sp)
    80004fd8:	fc26                	sd	s1,56(sp)
    80004fda:	f84a                	sd	s2,48(sp)
    80004fdc:	f44e                	sd	s3,40(sp)
    80004fde:	0880                	addi	s0,sp,80
    80004fe0:	84aa                	mv	s1,a0
    80004fe2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004fe4:	ffffd097          	auipc	ra,0xffffd
    80004fe8:	fce080e7          	jalr	-50(ra) # 80001fb2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004fec:	409c                	lw	a5,0(s1)
    80004fee:	37f9                	addiw	a5,a5,-2
    80004ff0:	4705                	li	a4,1
    80004ff2:	04f76763          	bltu	a4,a5,80005040 <filestat+0x6e>
    80004ff6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ff8:	6c88                	ld	a0,24(s1)
    80004ffa:	fffff097          	auipc	ra,0xfffff
    80004ffe:	072080e7          	jalr	114(ra) # 8000406c <ilock>
    stati(f->ip, &st);
    80005002:	fb840593          	addi	a1,s0,-72
    80005006:	6c88                	ld	a0,24(s1)
    80005008:	fffff097          	auipc	ra,0xfffff
    8000500c:	2ee080e7          	jalr	750(ra) # 800042f6 <stati>
    iunlock(f->ip);
    80005010:	6c88                	ld	a0,24(s1)
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	11c080e7          	jalr	284(ra) # 8000412e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000501a:	46e1                	li	a3,24
    8000501c:	fb840613          	addi	a2,s0,-72
    80005020:	85ce                	mv	a1,s3
    80005022:	07093503          	ld	a0,112(s2)
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	670080e7          	jalr	1648(ra) # 80001696 <copyout>
    8000502e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005032:	60a6                	ld	ra,72(sp)
    80005034:	6406                	ld	s0,64(sp)
    80005036:	74e2                	ld	s1,56(sp)
    80005038:	7942                	ld	s2,48(sp)
    8000503a:	79a2                	ld	s3,40(sp)
    8000503c:	6161                	addi	sp,sp,80
    8000503e:	8082                	ret
  return -1;
    80005040:	557d                	li	a0,-1
    80005042:	bfc5                	j	80005032 <filestat+0x60>

0000000080005044 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005044:	7179                	addi	sp,sp,-48
    80005046:	f406                	sd	ra,40(sp)
    80005048:	f022                	sd	s0,32(sp)
    8000504a:	ec26                	sd	s1,24(sp)
    8000504c:	e84a                	sd	s2,16(sp)
    8000504e:	e44e                	sd	s3,8(sp)
    80005050:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005052:	00854783          	lbu	a5,8(a0)
    80005056:	c3d5                	beqz	a5,800050fa <fileread+0xb6>
    80005058:	84aa                	mv	s1,a0
    8000505a:	89ae                	mv	s3,a1
    8000505c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000505e:	411c                	lw	a5,0(a0)
    80005060:	4705                	li	a4,1
    80005062:	04e78963          	beq	a5,a4,800050b4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005066:	470d                	li	a4,3
    80005068:	04e78d63          	beq	a5,a4,800050c2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000506c:	4709                	li	a4,2
    8000506e:	06e79e63          	bne	a5,a4,800050ea <fileread+0xa6>
    ilock(f->ip);
    80005072:	6d08                	ld	a0,24(a0)
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	ff8080e7          	jalr	-8(ra) # 8000406c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000507c:	874a                	mv	a4,s2
    8000507e:	5094                	lw	a3,32(s1)
    80005080:	864e                	mv	a2,s3
    80005082:	4585                	li	a1,1
    80005084:	6c88                	ld	a0,24(s1)
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	29a080e7          	jalr	666(ra) # 80004320 <readi>
    8000508e:	892a                	mv	s2,a0
    80005090:	00a05563          	blez	a0,8000509a <fileread+0x56>
      f->off += r;
    80005094:	509c                	lw	a5,32(s1)
    80005096:	9fa9                	addw	a5,a5,a0
    80005098:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000509a:	6c88                	ld	a0,24(s1)
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	092080e7          	jalr	146(ra) # 8000412e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800050a4:	854a                	mv	a0,s2
    800050a6:	70a2                	ld	ra,40(sp)
    800050a8:	7402                	ld	s0,32(sp)
    800050aa:	64e2                	ld	s1,24(sp)
    800050ac:	6942                	ld	s2,16(sp)
    800050ae:	69a2                	ld	s3,8(sp)
    800050b0:	6145                	addi	sp,sp,48
    800050b2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800050b4:	6908                	ld	a0,16(a0)
    800050b6:	00000097          	auipc	ra,0x0
    800050ba:	3c8080e7          	jalr	968(ra) # 8000547e <piperead>
    800050be:	892a                	mv	s2,a0
    800050c0:	b7d5                	j	800050a4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800050c2:	02451783          	lh	a5,36(a0)
    800050c6:	03079693          	slli	a3,a5,0x30
    800050ca:	92c1                	srli	a3,a3,0x30
    800050cc:	4725                	li	a4,9
    800050ce:	02d76863          	bltu	a4,a3,800050fe <fileread+0xba>
    800050d2:	0792                	slli	a5,a5,0x4
    800050d4:	0001d717          	auipc	a4,0x1d
    800050d8:	bec70713          	addi	a4,a4,-1044 # 80021cc0 <devsw>
    800050dc:	97ba                	add	a5,a5,a4
    800050de:	639c                	ld	a5,0(a5)
    800050e0:	c38d                	beqz	a5,80005102 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050e2:	4505                	li	a0,1
    800050e4:	9782                	jalr	a5
    800050e6:	892a                	mv	s2,a0
    800050e8:	bf75                	j	800050a4 <fileread+0x60>
    panic("fileread");
    800050ea:	00003517          	auipc	a0,0x3
    800050ee:	6a650513          	addi	a0,a0,1702 # 80008790 <syscalls+0x270>
    800050f2:	ffffb097          	auipc	ra,0xffffb
    800050f6:	44c080e7          	jalr	1100(ra) # 8000053e <panic>
    return -1;
    800050fa:	597d                	li	s2,-1
    800050fc:	b765                	j	800050a4 <fileread+0x60>
      return -1;
    800050fe:	597d                	li	s2,-1
    80005100:	b755                	j	800050a4 <fileread+0x60>
    80005102:	597d                	li	s2,-1
    80005104:	b745                	j	800050a4 <fileread+0x60>

0000000080005106 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005106:	715d                	addi	sp,sp,-80
    80005108:	e486                	sd	ra,72(sp)
    8000510a:	e0a2                	sd	s0,64(sp)
    8000510c:	fc26                	sd	s1,56(sp)
    8000510e:	f84a                	sd	s2,48(sp)
    80005110:	f44e                	sd	s3,40(sp)
    80005112:	f052                	sd	s4,32(sp)
    80005114:	ec56                	sd	s5,24(sp)
    80005116:	e85a                	sd	s6,16(sp)
    80005118:	e45e                	sd	s7,8(sp)
    8000511a:	e062                	sd	s8,0(sp)
    8000511c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000511e:	00954783          	lbu	a5,9(a0)
    80005122:	10078663          	beqz	a5,8000522e <filewrite+0x128>
    80005126:	892a                	mv	s2,a0
    80005128:	8aae                	mv	s5,a1
    8000512a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000512c:	411c                	lw	a5,0(a0)
    8000512e:	4705                	li	a4,1
    80005130:	02e78263          	beq	a5,a4,80005154 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005134:	470d                	li	a4,3
    80005136:	02e78663          	beq	a5,a4,80005162 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000513a:	4709                	li	a4,2
    8000513c:	0ee79163          	bne	a5,a4,8000521e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005140:	0ac05d63          	blez	a2,800051fa <filewrite+0xf4>
    int i = 0;
    80005144:	4981                	li	s3,0
    80005146:	6b05                	lui	s6,0x1
    80005148:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000514c:	6b85                	lui	s7,0x1
    8000514e:	c00b8b9b          	addiw	s7,s7,-1024
    80005152:	a861                	j	800051ea <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005154:	6908                	ld	a0,16(a0)
    80005156:	00000097          	auipc	ra,0x0
    8000515a:	22e080e7          	jalr	558(ra) # 80005384 <pipewrite>
    8000515e:	8a2a                	mv	s4,a0
    80005160:	a045                	j	80005200 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005162:	02451783          	lh	a5,36(a0)
    80005166:	03079693          	slli	a3,a5,0x30
    8000516a:	92c1                	srli	a3,a3,0x30
    8000516c:	4725                	li	a4,9
    8000516e:	0cd76263          	bltu	a4,a3,80005232 <filewrite+0x12c>
    80005172:	0792                	slli	a5,a5,0x4
    80005174:	0001d717          	auipc	a4,0x1d
    80005178:	b4c70713          	addi	a4,a4,-1204 # 80021cc0 <devsw>
    8000517c:	97ba                	add	a5,a5,a4
    8000517e:	679c                	ld	a5,8(a5)
    80005180:	cbdd                	beqz	a5,80005236 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005182:	4505                	li	a0,1
    80005184:	9782                	jalr	a5
    80005186:	8a2a                	mv	s4,a0
    80005188:	a8a5                	j	80005200 <filewrite+0xfa>
    8000518a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000518e:	00000097          	auipc	ra,0x0
    80005192:	8b0080e7          	jalr	-1872(ra) # 80004a3e <begin_op>
      ilock(f->ip);
    80005196:	01893503          	ld	a0,24(s2)
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	ed2080e7          	jalr	-302(ra) # 8000406c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800051a2:	8762                	mv	a4,s8
    800051a4:	02092683          	lw	a3,32(s2)
    800051a8:	01598633          	add	a2,s3,s5
    800051ac:	4585                	li	a1,1
    800051ae:	01893503          	ld	a0,24(s2)
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	266080e7          	jalr	614(ra) # 80004418 <writei>
    800051ba:	84aa                	mv	s1,a0
    800051bc:	00a05763          	blez	a0,800051ca <filewrite+0xc4>
        f->off += r;
    800051c0:	02092783          	lw	a5,32(s2)
    800051c4:	9fa9                	addw	a5,a5,a0
    800051c6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800051ca:	01893503          	ld	a0,24(s2)
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	f60080e7          	jalr	-160(ra) # 8000412e <iunlock>
      end_op();
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	8e8080e7          	jalr	-1816(ra) # 80004abe <end_op>

      if(r != n1){
    800051de:	009c1f63          	bne	s8,s1,800051fc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051e2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051e6:	0149db63          	bge	s3,s4,800051fc <filewrite+0xf6>
      int n1 = n - i;
    800051ea:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800051ee:	84be                	mv	s1,a5
    800051f0:	2781                	sext.w	a5,a5
    800051f2:	f8fb5ce3          	bge	s6,a5,8000518a <filewrite+0x84>
    800051f6:	84de                	mv	s1,s7
    800051f8:	bf49                	j	8000518a <filewrite+0x84>
    int i = 0;
    800051fa:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051fc:	013a1f63          	bne	s4,s3,8000521a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005200:	8552                	mv	a0,s4
    80005202:	60a6                	ld	ra,72(sp)
    80005204:	6406                	ld	s0,64(sp)
    80005206:	74e2                	ld	s1,56(sp)
    80005208:	7942                	ld	s2,48(sp)
    8000520a:	79a2                	ld	s3,40(sp)
    8000520c:	7a02                	ld	s4,32(sp)
    8000520e:	6ae2                	ld	s5,24(sp)
    80005210:	6b42                	ld	s6,16(sp)
    80005212:	6ba2                	ld	s7,8(sp)
    80005214:	6c02                	ld	s8,0(sp)
    80005216:	6161                	addi	sp,sp,80
    80005218:	8082                	ret
    ret = (i == n ? n : -1);
    8000521a:	5a7d                	li	s4,-1
    8000521c:	b7d5                	j	80005200 <filewrite+0xfa>
    panic("filewrite");
    8000521e:	00003517          	auipc	a0,0x3
    80005222:	58250513          	addi	a0,a0,1410 # 800087a0 <syscalls+0x280>
    80005226:	ffffb097          	auipc	ra,0xffffb
    8000522a:	318080e7          	jalr	792(ra) # 8000053e <panic>
    return -1;
    8000522e:	5a7d                	li	s4,-1
    80005230:	bfc1                	j	80005200 <filewrite+0xfa>
      return -1;
    80005232:	5a7d                	li	s4,-1
    80005234:	b7f1                	j	80005200 <filewrite+0xfa>
    80005236:	5a7d                	li	s4,-1
    80005238:	b7e1                	j	80005200 <filewrite+0xfa>

000000008000523a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000523a:	7179                	addi	sp,sp,-48
    8000523c:	f406                	sd	ra,40(sp)
    8000523e:	f022                	sd	s0,32(sp)
    80005240:	ec26                	sd	s1,24(sp)
    80005242:	e84a                	sd	s2,16(sp)
    80005244:	e44e                	sd	s3,8(sp)
    80005246:	e052                	sd	s4,0(sp)
    80005248:	1800                	addi	s0,sp,48
    8000524a:	84aa                	mv	s1,a0
    8000524c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000524e:	0005b023          	sd	zero,0(a1)
    80005252:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005256:	00000097          	auipc	ra,0x0
    8000525a:	bf8080e7          	jalr	-1032(ra) # 80004e4e <filealloc>
    8000525e:	e088                	sd	a0,0(s1)
    80005260:	c551                	beqz	a0,800052ec <pipealloc+0xb2>
    80005262:	00000097          	auipc	ra,0x0
    80005266:	bec080e7          	jalr	-1044(ra) # 80004e4e <filealloc>
    8000526a:	00aa3023          	sd	a0,0(s4)
    8000526e:	c92d                	beqz	a0,800052e0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	884080e7          	jalr	-1916(ra) # 80000af4 <kalloc>
    80005278:	892a                	mv	s2,a0
    8000527a:	c125                	beqz	a0,800052da <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000527c:	4985                	li	s3,1
    8000527e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005282:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005286:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000528a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000528e:	00003597          	auipc	a1,0x3
    80005292:	52258593          	addi	a1,a1,1314 # 800087b0 <syscalls+0x290>
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	8be080e7          	jalr	-1858(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000529e:	609c                	ld	a5,0(s1)
    800052a0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800052a4:	609c                	ld	a5,0(s1)
    800052a6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800052aa:	609c                	ld	a5,0(s1)
    800052ac:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800052b0:	609c                	ld	a5,0(s1)
    800052b2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800052b6:	000a3783          	ld	a5,0(s4)
    800052ba:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800052be:	000a3783          	ld	a5,0(s4)
    800052c2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800052c6:	000a3783          	ld	a5,0(s4)
    800052ca:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800052ce:	000a3783          	ld	a5,0(s4)
    800052d2:	0127b823          	sd	s2,16(a5)
  return 0;
    800052d6:	4501                	li	a0,0
    800052d8:	a025                	j	80005300 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800052da:	6088                	ld	a0,0(s1)
    800052dc:	e501                	bnez	a0,800052e4 <pipealloc+0xaa>
    800052de:	a039                	j	800052ec <pipealloc+0xb2>
    800052e0:	6088                	ld	a0,0(s1)
    800052e2:	c51d                	beqz	a0,80005310 <pipealloc+0xd6>
    fileclose(*f0);
    800052e4:	00000097          	auipc	ra,0x0
    800052e8:	c26080e7          	jalr	-986(ra) # 80004f0a <fileclose>
  if(*f1)
    800052ec:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800052f0:	557d                	li	a0,-1
  if(*f1)
    800052f2:	c799                	beqz	a5,80005300 <pipealloc+0xc6>
    fileclose(*f1);
    800052f4:	853e                	mv	a0,a5
    800052f6:	00000097          	auipc	ra,0x0
    800052fa:	c14080e7          	jalr	-1004(ra) # 80004f0a <fileclose>
  return -1;
    800052fe:	557d                	li	a0,-1
}
    80005300:	70a2                	ld	ra,40(sp)
    80005302:	7402                	ld	s0,32(sp)
    80005304:	64e2                	ld	s1,24(sp)
    80005306:	6942                	ld	s2,16(sp)
    80005308:	69a2                	ld	s3,8(sp)
    8000530a:	6a02                	ld	s4,0(sp)
    8000530c:	6145                	addi	sp,sp,48
    8000530e:	8082                	ret
  return -1;
    80005310:	557d                	li	a0,-1
    80005312:	b7fd                	j	80005300 <pipealloc+0xc6>

0000000080005314 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005314:	1101                	addi	sp,sp,-32
    80005316:	ec06                	sd	ra,24(sp)
    80005318:	e822                	sd	s0,16(sp)
    8000531a:	e426                	sd	s1,8(sp)
    8000531c:	e04a                	sd	s2,0(sp)
    8000531e:	1000                	addi	s0,sp,32
    80005320:	84aa                	mv	s1,a0
    80005322:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005324:	ffffc097          	auipc	ra,0xffffc
    80005328:	8c0080e7          	jalr	-1856(ra) # 80000be4 <acquire>
  if(writable){
    8000532c:	02090d63          	beqz	s2,80005366 <pipeclose+0x52>
    pi->writeopen = 0;
    80005330:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005334:	21848513          	addi	a0,s1,536
    80005338:	ffffd097          	auipc	ra,0xffffd
    8000533c:	718080e7          	jalr	1816(ra) # 80002a50 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005340:	2204b783          	ld	a5,544(s1)
    80005344:	eb95                	bnez	a5,80005378 <pipeclose+0x64>
    release(&pi->lock);
    80005346:	8526                	mv	a0,s1
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	962080e7          	jalr	-1694(ra) # 80000caa <release>
    kfree((char*)pi);
    80005350:	8526                	mv	a0,s1
    80005352:	ffffb097          	auipc	ra,0xffffb
    80005356:	6a6080e7          	jalr	1702(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000535a:	60e2                	ld	ra,24(sp)
    8000535c:	6442                	ld	s0,16(sp)
    8000535e:	64a2                	ld	s1,8(sp)
    80005360:	6902                	ld	s2,0(sp)
    80005362:	6105                	addi	sp,sp,32
    80005364:	8082                	ret
    pi->readopen = 0;
    80005366:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000536a:	21c48513          	addi	a0,s1,540
    8000536e:	ffffd097          	auipc	ra,0xffffd
    80005372:	6e2080e7          	jalr	1762(ra) # 80002a50 <wakeup>
    80005376:	b7e9                	j	80005340 <pipeclose+0x2c>
    release(&pi->lock);
    80005378:	8526                	mv	a0,s1
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	930080e7          	jalr	-1744(ra) # 80000caa <release>
}
    80005382:	bfe1                	j	8000535a <pipeclose+0x46>

0000000080005384 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005384:	7159                	addi	sp,sp,-112
    80005386:	f486                	sd	ra,104(sp)
    80005388:	f0a2                	sd	s0,96(sp)
    8000538a:	eca6                	sd	s1,88(sp)
    8000538c:	e8ca                	sd	s2,80(sp)
    8000538e:	e4ce                	sd	s3,72(sp)
    80005390:	e0d2                	sd	s4,64(sp)
    80005392:	fc56                	sd	s5,56(sp)
    80005394:	f85a                	sd	s6,48(sp)
    80005396:	f45e                	sd	s7,40(sp)
    80005398:	f062                	sd	s8,32(sp)
    8000539a:	ec66                	sd	s9,24(sp)
    8000539c:	1880                	addi	s0,sp,112
    8000539e:	84aa                	mv	s1,a0
    800053a0:	8aae                	mv	s5,a1
    800053a2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800053a4:	ffffd097          	auipc	ra,0xffffd
    800053a8:	c0e080e7          	jalr	-1010(ra) # 80001fb2 <myproc>
    800053ac:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800053ae:	8526                	mv	a0,s1
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
  while(i < n){
    800053b8:	0d405163          	blez	s4,8000547a <pipewrite+0xf6>
    800053bc:	8ba6                	mv	s7,s1
  int i = 0;
    800053be:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800053c0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800053c2:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800053c6:	21c48c13          	addi	s8,s1,540
    800053ca:	a08d                	j	8000542c <pipewrite+0xa8>
      release(&pi->lock);
    800053cc:	8526                	mv	a0,s1
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	8dc080e7          	jalr	-1828(ra) # 80000caa <release>
      return -1;
    800053d6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800053d8:	854a                	mv	a0,s2
    800053da:	70a6                	ld	ra,104(sp)
    800053dc:	7406                	ld	s0,96(sp)
    800053de:	64e6                	ld	s1,88(sp)
    800053e0:	6946                	ld	s2,80(sp)
    800053e2:	69a6                	ld	s3,72(sp)
    800053e4:	6a06                	ld	s4,64(sp)
    800053e6:	7ae2                	ld	s5,56(sp)
    800053e8:	7b42                	ld	s6,48(sp)
    800053ea:	7ba2                	ld	s7,40(sp)
    800053ec:	7c02                	ld	s8,32(sp)
    800053ee:	6ce2                	ld	s9,24(sp)
    800053f0:	6165                	addi	sp,sp,112
    800053f2:	8082                	ret
      wakeup(&pi->nread);
    800053f4:	8566                	mv	a0,s9
    800053f6:	ffffd097          	auipc	ra,0xffffd
    800053fa:	65a080e7          	jalr	1626(ra) # 80002a50 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800053fe:	85de                	mv	a1,s7
    80005400:	8562                	mv	a0,s8
    80005402:	ffffd097          	auipc	ra,0xffffd
    80005406:	496080e7          	jalr	1174(ra) # 80002898 <sleep>
    8000540a:	a839                	j	80005428 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000540c:	21c4a783          	lw	a5,540(s1)
    80005410:	0017871b          	addiw	a4,a5,1
    80005414:	20e4ae23          	sw	a4,540(s1)
    80005418:	1ff7f793          	andi	a5,a5,511
    8000541c:	97a6                	add	a5,a5,s1
    8000541e:	f9f44703          	lbu	a4,-97(s0)
    80005422:	00e78c23          	sb	a4,24(a5)
      i++;
    80005426:	2905                	addiw	s2,s2,1
  while(i < n){
    80005428:	03495d63          	bge	s2,s4,80005462 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000542c:	2204a783          	lw	a5,544(s1)
    80005430:	dfd1                	beqz	a5,800053cc <pipewrite+0x48>
    80005432:	0289a783          	lw	a5,40(s3)
    80005436:	fbd9                	bnez	a5,800053cc <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005438:	2184a783          	lw	a5,536(s1)
    8000543c:	21c4a703          	lw	a4,540(s1)
    80005440:	2007879b          	addiw	a5,a5,512
    80005444:	faf708e3          	beq	a4,a5,800053f4 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005448:	4685                	li	a3,1
    8000544a:	01590633          	add	a2,s2,s5
    8000544e:	f9f40593          	addi	a1,s0,-97
    80005452:	0709b503          	ld	a0,112(s3)
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	2cc080e7          	jalr	716(ra) # 80001722 <copyin>
    8000545e:	fb6517e3          	bne	a0,s6,8000540c <pipewrite+0x88>
  wakeup(&pi->nread);
    80005462:	21848513          	addi	a0,s1,536
    80005466:	ffffd097          	auipc	ra,0xffffd
    8000546a:	5ea080e7          	jalr	1514(ra) # 80002a50 <wakeup>
  release(&pi->lock);
    8000546e:	8526                	mv	a0,s1
    80005470:	ffffc097          	auipc	ra,0xffffc
    80005474:	83a080e7          	jalr	-1990(ra) # 80000caa <release>
  return i;
    80005478:	b785                	j	800053d8 <pipewrite+0x54>
  int i = 0;
    8000547a:	4901                	li	s2,0
    8000547c:	b7dd                	j	80005462 <pipewrite+0xde>

000000008000547e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000547e:	715d                	addi	sp,sp,-80
    80005480:	e486                	sd	ra,72(sp)
    80005482:	e0a2                	sd	s0,64(sp)
    80005484:	fc26                	sd	s1,56(sp)
    80005486:	f84a                	sd	s2,48(sp)
    80005488:	f44e                	sd	s3,40(sp)
    8000548a:	f052                	sd	s4,32(sp)
    8000548c:	ec56                	sd	s5,24(sp)
    8000548e:	e85a                	sd	s6,16(sp)
    80005490:	0880                	addi	s0,sp,80
    80005492:	84aa                	mv	s1,a0
    80005494:	892e                	mv	s2,a1
    80005496:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	b1a080e7          	jalr	-1254(ra) # 80001fb2 <myproc>
    800054a0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800054a2:	8b26                	mv	s6,s1
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffb097          	auipc	ra,0xffffb
    800054aa:	73e080e7          	jalr	1854(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054ae:	2184a703          	lw	a4,536(s1)
    800054b2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800054b6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054ba:	02f71463          	bne	a4,a5,800054e2 <piperead+0x64>
    800054be:	2244a783          	lw	a5,548(s1)
    800054c2:	c385                	beqz	a5,800054e2 <piperead+0x64>
    if(pr->killed){
    800054c4:	028a2783          	lw	a5,40(s4)
    800054c8:	ebc1                	bnez	a5,80005558 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800054ca:	85da                	mv	a1,s6
    800054cc:	854e                	mv	a0,s3
    800054ce:	ffffd097          	auipc	ra,0xffffd
    800054d2:	3ca080e7          	jalr	970(ra) # 80002898 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054d6:	2184a703          	lw	a4,536(s1)
    800054da:	21c4a783          	lw	a5,540(s1)
    800054de:	fef700e3          	beq	a4,a5,800054be <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054e2:	09505263          	blez	s5,80005566 <piperead+0xe8>
    800054e6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054e8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800054ea:	2184a783          	lw	a5,536(s1)
    800054ee:	21c4a703          	lw	a4,540(s1)
    800054f2:	02f70d63          	beq	a4,a5,8000552c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800054f6:	0017871b          	addiw	a4,a5,1
    800054fa:	20e4ac23          	sw	a4,536(s1)
    800054fe:	1ff7f793          	andi	a5,a5,511
    80005502:	97a6                	add	a5,a5,s1
    80005504:	0187c783          	lbu	a5,24(a5)
    80005508:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000550c:	4685                	li	a3,1
    8000550e:	fbf40613          	addi	a2,s0,-65
    80005512:	85ca                	mv	a1,s2
    80005514:	070a3503          	ld	a0,112(s4)
    80005518:	ffffc097          	auipc	ra,0xffffc
    8000551c:	17e080e7          	jalr	382(ra) # 80001696 <copyout>
    80005520:	01650663          	beq	a0,s6,8000552c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005524:	2985                	addiw	s3,s3,1
    80005526:	0905                	addi	s2,s2,1
    80005528:	fd3a91e3          	bne	s5,s3,800054ea <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000552c:	21c48513          	addi	a0,s1,540
    80005530:	ffffd097          	auipc	ra,0xffffd
    80005534:	520080e7          	jalr	1312(ra) # 80002a50 <wakeup>
  release(&pi->lock);
    80005538:	8526                	mv	a0,s1
    8000553a:	ffffb097          	auipc	ra,0xffffb
    8000553e:	770080e7          	jalr	1904(ra) # 80000caa <release>
  return i;
}
    80005542:	854e                	mv	a0,s3
    80005544:	60a6                	ld	ra,72(sp)
    80005546:	6406                	ld	s0,64(sp)
    80005548:	74e2                	ld	s1,56(sp)
    8000554a:	7942                	ld	s2,48(sp)
    8000554c:	79a2                	ld	s3,40(sp)
    8000554e:	7a02                	ld	s4,32(sp)
    80005550:	6ae2                	ld	s5,24(sp)
    80005552:	6b42                	ld	s6,16(sp)
    80005554:	6161                	addi	sp,sp,80
    80005556:	8082                	ret
      release(&pi->lock);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffb097          	auipc	ra,0xffffb
    8000555e:	750080e7          	jalr	1872(ra) # 80000caa <release>
      return -1;
    80005562:	59fd                	li	s3,-1
    80005564:	bff9                	j	80005542 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005566:	4981                	li	s3,0
    80005568:	b7d1                	j	8000552c <piperead+0xae>

000000008000556a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000556a:	df010113          	addi	sp,sp,-528
    8000556e:	20113423          	sd	ra,520(sp)
    80005572:	20813023          	sd	s0,512(sp)
    80005576:	ffa6                	sd	s1,504(sp)
    80005578:	fbca                	sd	s2,496(sp)
    8000557a:	f7ce                	sd	s3,488(sp)
    8000557c:	f3d2                	sd	s4,480(sp)
    8000557e:	efd6                	sd	s5,472(sp)
    80005580:	ebda                	sd	s6,464(sp)
    80005582:	e7de                	sd	s7,456(sp)
    80005584:	e3e2                	sd	s8,448(sp)
    80005586:	ff66                	sd	s9,440(sp)
    80005588:	fb6a                	sd	s10,432(sp)
    8000558a:	f76e                	sd	s11,424(sp)
    8000558c:	0c00                	addi	s0,sp,528
    8000558e:	84aa                	mv	s1,a0
    80005590:	dea43c23          	sd	a0,-520(s0)
    80005594:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005598:	ffffd097          	auipc	ra,0xffffd
    8000559c:	a1a080e7          	jalr	-1510(ra) # 80001fb2 <myproc>
    800055a0:	892a                	mv	s2,a0

  begin_op();
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	49c080e7          	jalr	1180(ra) # 80004a3e <begin_op>

  if((ip = namei(path)) == 0){
    800055aa:	8526                	mv	a0,s1
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	276080e7          	jalr	630(ra) # 80004822 <namei>
    800055b4:	c92d                	beqz	a0,80005626 <exec+0xbc>
    800055b6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	ab4080e7          	jalr	-1356(ra) # 8000406c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800055c0:	04000713          	li	a4,64
    800055c4:	4681                	li	a3,0
    800055c6:	e5040613          	addi	a2,s0,-432
    800055ca:	4581                	li	a1,0
    800055cc:	8526                	mv	a0,s1
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	d52080e7          	jalr	-686(ra) # 80004320 <readi>
    800055d6:	04000793          	li	a5,64
    800055da:	00f51a63          	bne	a0,a5,800055ee <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800055de:	e5042703          	lw	a4,-432(s0)
    800055e2:	464c47b7          	lui	a5,0x464c4
    800055e6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800055ea:	04f70463          	beq	a4,a5,80005632 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800055ee:	8526                	mv	a0,s1
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	cde080e7          	jalr	-802(ra) # 800042ce <iunlockput>
    end_op();
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	4c6080e7          	jalr	1222(ra) # 80004abe <end_op>
  }
  return -1;
    80005600:	557d                	li	a0,-1
}
    80005602:	20813083          	ld	ra,520(sp)
    80005606:	20013403          	ld	s0,512(sp)
    8000560a:	74fe                	ld	s1,504(sp)
    8000560c:	795e                	ld	s2,496(sp)
    8000560e:	79be                	ld	s3,488(sp)
    80005610:	7a1e                	ld	s4,480(sp)
    80005612:	6afe                	ld	s5,472(sp)
    80005614:	6b5e                	ld	s6,464(sp)
    80005616:	6bbe                	ld	s7,456(sp)
    80005618:	6c1e                	ld	s8,448(sp)
    8000561a:	7cfa                	ld	s9,440(sp)
    8000561c:	7d5a                	ld	s10,432(sp)
    8000561e:	7dba                	ld	s11,424(sp)
    80005620:	21010113          	addi	sp,sp,528
    80005624:	8082                	ret
    end_op();
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	498080e7          	jalr	1176(ra) # 80004abe <end_op>
    return -1;
    8000562e:	557d                	li	a0,-1
    80005630:	bfc9                	j	80005602 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005632:	854a                	mv	a0,s2
    80005634:	ffffd097          	auipc	ra,0xffffd
    80005638:	a8e080e7          	jalr	-1394(ra) # 800020c2 <proc_pagetable>
    8000563c:	8baa                	mv	s7,a0
    8000563e:	d945                	beqz	a0,800055ee <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005640:	e7042983          	lw	s3,-400(s0)
    80005644:	e8845783          	lhu	a5,-376(s0)
    80005648:	c7ad                	beqz	a5,800056b2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000564a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000564c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000564e:	6c85                	lui	s9,0x1
    80005650:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005654:	def43823          	sd	a5,-528(s0)
    80005658:	a42d                	j	80005882 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000565a:	00003517          	auipc	a0,0x3
    8000565e:	15e50513          	addi	a0,a0,350 # 800087b8 <syscalls+0x298>
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	edc080e7          	jalr	-292(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000566a:	8756                	mv	a4,s5
    8000566c:	012d86bb          	addw	a3,s11,s2
    80005670:	4581                	li	a1,0
    80005672:	8526                	mv	a0,s1
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	cac080e7          	jalr	-852(ra) # 80004320 <readi>
    8000567c:	2501                	sext.w	a0,a0
    8000567e:	1aaa9963          	bne	s5,a0,80005830 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005682:	6785                	lui	a5,0x1
    80005684:	0127893b          	addw	s2,a5,s2
    80005688:	77fd                	lui	a5,0xfffff
    8000568a:	01478a3b          	addw	s4,a5,s4
    8000568e:	1f897163          	bgeu	s2,s8,80005870 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005692:	02091593          	slli	a1,s2,0x20
    80005696:	9181                	srli	a1,a1,0x20
    80005698:	95ea                	add	a1,a1,s10
    8000569a:	855e                	mv	a0,s7
    8000569c:	ffffc097          	auipc	ra,0xffffc
    800056a0:	9f6080e7          	jalr	-1546(ra) # 80001092 <walkaddr>
    800056a4:	862a                	mv	a2,a0
    if(pa == 0)
    800056a6:	d955                	beqz	a0,8000565a <exec+0xf0>
      n = PGSIZE;
    800056a8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800056aa:	fd9a70e3          	bgeu	s4,s9,8000566a <exec+0x100>
      n = sz - i;
    800056ae:	8ad2                	mv	s5,s4
    800056b0:	bf6d                	j	8000566a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056b2:	4901                	li	s2,0
  iunlockput(ip);
    800056b4:	8526                	mv	a0,s1
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	c18080e7          	jalr	-1000(ra) # 800042ce <iunlockput>
  end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	400080e7          	jalr	1024(ra) # 80004abe <end_op>
  p = myproc();
    800056c6:	ffffd097          	auipc	ra,0xffffd
    800056ca:	8ec080e7          	jalr	-1812(ra) # 80001fb2 <myproc>
    800056ce:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800056d0:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800056d4:	6785                	lui	a5,0x1
    800056d6:	17fd                	addi	a5,a5,-1
    800056d8:	993e                	add	s2,s2,a5
    800056da:	757d                	lui	a0,0xfffff
    800056dc:	00a977b3          	and	a5,s2,a0
    800056e0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056e4:	6609                	lui	a2,0x2
    800056e6:	963e                	add	a2,a2,a5
    800056e8:	85be                	mv	a1,a5
    800056ea:	855e                	mv	a0,s7
    800056ec:	ffffc097          	auipc	ra,0xffffc
    800056f0:	d5a080e7          	jalr	-678(ra) # 80001446 <uvmalloc>
    800056f4:	8b2a                	mv	s6,a0
  ip = 0;
    800056f6:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056f8:	12050c63          	beqz	a0,80005830 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800056fc:	75f9                	lui	a1,0xffffe
    800056fe:	95aa                	add	a1,a1,a0
    80005700:	855e                	mv	a0,s7
    80005702:	ffffc097          	auipc	ra,0xffffc
    80005706:	f62080e7          	jalr	-158(ra) # 80001664 <uvmclear>
  stackbase = sp - PGSIZE;
    8000570a:	7c7d                	lui	s8,0xfffff
    8000570c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000570e:	e0043783          	ld	a5,-512(s0)
    80005712:	6388                	ld	a0,0(a5)
    80005714:	c535                	beqz	a0,80005780 <exec+0x216>
    80005716:	e9040993          	addi	s3,s0,-368
    8000571a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000571e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005720:	ffffb097          	auipc	ra,0xffffb
    80005724:	768080e7          	jalr	1896(ra) # 80000e88 <strlen>
    80005728:	2505                	addiw	a0,a0,1
    8000572a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000572e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005732:	13896363          	bltu	s2,s8,80005858 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005736:	e0043d83          	ld	s11,-512(s0)
    8000573a:	000dba03          	ld	s4,0(s11)
    8000573e:	8552                	mv	a0,s4
    80005740:	ffffb097          	auipc	ra,0xffffb
    80005744:	748080e7          	jalr	1864(ra) # 80000e88 <strlen>
    80005748:	0015069b          	addiw	a3,a0,1
    8000574c:	8652                	mv	a2,s4
    8000574e:	85ca                	mv	a1,s2
    80005750:	855e                	mv	a0,s7
    80005752:	ffffc097          	auipc	ra,0xffffc
    80005756:	f44080e7          	jalr	-188(ra) # 80001696 <copyout>
    8000575a:	10054363          	bltz	a0,80005860 <exec+0x2f6>
    ustack[argc] = sp;
    8000575e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005762:	0485                	addi	s1,s1,1
    80005764:	008d8793          	addi	a5,s11,8
    80005768:	e0f43023          	sd	a5,-512(s0)
    8000576c:	008db503          	ld	a0,8(s11)
    80005770:	c911                	beqz	a0,80005784 <exec+0x21a>
    if(argc >= MAXARG)
    80005772:	09a1                	addi	s3,s3,8
    80005774:	fb3c96e3          	bne	s9,s3,80005720 <exec+0x1b6>
  sz = sz1;
    80005778:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000577c:	4481                	li	s1,0
    8000577e:	a84d                	j	80005830 <exec+0x2c6>
  sp = sz;
    80005780:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005782:	4481                	li	s1,0
  ustack[argc] = 0;
    80005784:	00349793          	slli	a5,s1,0x3
    80005788:	f9040713          	addi	a4,s0,-112
    8000578c:	97ba                	add	a5,a5,a4
    8000578e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005792:	00148693          	addi	a3,s1,1
    80005796:	068e                	slli	a3,a3,0x3
    80005798:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000579c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800057a0:	01897663          	bgeu	s2,s8,800057ac <exec+0x242>
  sz = sz1;
    800057a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057a8:	4481                	li	s1,0
    800057aa:	a059                	j	80005830 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800057ac:	e9040613          	addi	a2,s0,-368
    800057b0:	85ca                	mv	a1,s2
    800057b2:	855e                	mv	a0,s7
    800057b4:	ffffc097          	auipc	ra,0xffffc
    800057b8:	ee2080e7          	jalr	-286(ra) # 80001696 <copyout>
    800057bc:	0a054663          	bltz	a0,80005868 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800057c0:	078ab783          	ld	a5,120(s5)
    800057c4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800057c8:	df843783          	ld	a5,-520(s0)
    800057cc:	0007c703          	lbu	a4,0(a5)
    800057d0:	cf11                	beqz	a4,800057ec <exec+0x282>
    800057d2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800057d4:	02f00693          	li	a3,47
    800057d8:	a039                	j	800057e6 <exec+0x27c>
      last = s+1;
    800057da:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800057de:	0785                	addi	a5,a5,1
    800057e0:	fff7c703          	lbu	a4,-1(a5)
    800057e4:	c701                	beqz	a4,800057ec <exec+0x282>
    if(*s == '/')
    800057e6:	fed71ce3          	bne	a4,a3,800057de <exec+0x274>
    800057ea:	bfc5                	j	800057da <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800057ec:	4641                	li	a2,16
    800057ee:	df843583          	ld	a1,-520(s0)
    800057f2:	178a8513          	addi	a0,s5,376
    800057f6:	ffffb097          	auipc	ra,0xffffb
    800057fa:	660080e7          	jalr	1632(ra) # 80000e56 <safestrcpy>
  oldpagetable = p->pagetable;
    800057fe:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005802:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005806:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000580a:	078ab783          	ld	a5,120(s5)
    8000580e:	e6843703          	ld	a4,-408(s0)
    80005812:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005814:	078ab783          	ld	a5,120(s5)
    80005818:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000581c:	85ea                	mv	a1,s10
    8000581e:	ffffd097          	auipc	ra,0xffffd
    80005822:	940080e7          	jalr	-1728(ra) # 8000215e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005826:	0004851b          	sext.w	a0,s1
    8000582a:	bbe1                	j	80005602 <exec+0x98>
    8000582c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005830:	e0843583          	ld	a1,-504(s0)
    80005834:	855e                	mv	a0,s7
    80005836:	ffffd097          	auipc	ra,0xffffd
    8000583a:	928080e7          	jalr	-1752(ra) # 8000215e <proc_freepagetable>
  if(ip){
    8000583e:	da0498e3          	bnez	s1,800055ee <exec+0x84>
  return -1;
    80005842:	557d                	li	a0,-1
    80005844:	bb7d                	j	80005602 <exec+0x98>
    80005846:	e1243423          	sd	s2,-504(s0)
    8000584a:	b7dd                	j	80005830 <exec+0x2c6>
    8000584c:	e1243423          	sd	s2,-504(s0)
    80005850:	b7c5                	j	80005830 <exec+0x2c6>
    80005852:	e1243423          	sd	s2,-504(s0)
    80005856:	bfe9                	j	80005830 <exec+0x2c6>
  sz = sz1;
    80005858:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000585c:	4481                	li	s1,0
    8000585e:	bfc9                	j	80005830 <exec+0x2c6>
  sz = sz1;
    80005860:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005864:	4481                	li	s1,0
    80005866:	b7e9                	j	80005830 <exec+0x2c6>
  sz = sz1;
    80005868:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000586c:	4481                	li	s1,0
    8000586e:	b7c9                	j	80005830 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005870:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005874:	2b05                	addiw	s6,s6,1
    80005876:	0389899b          	addiw	s3,s3,56
    8000587a:	e8845783          	lhu	a5,-376(s0)
    8000587e:	e2fb5be3          	bge	s6,a5,800056b4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005882:	2981                	sext.w	s3,s3
    80005884:	03800713          	li	a4,56
    80005888:	86ce                	mv	a3,s3
    8000588a:	e1840613          	addi	a2,s0,-488
    8000588e:	4581                	li	a1,0
    80005890:	8526                	mv	a0,s1
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	a8e080e7          	jalr	-1394(ra) # 80004320 <readi>
    8000589a:	03800793          	li	a5,56
    8000589e:	f8f517e3          	bne	a0,a5,8000582c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800058a2:	e1842783          	lw	a5,-488(s0)
    800058a6:	4705                	li	a4,1
    800058a8:	fce796e3          	bne	a5,a4,80005874 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800058ac:	e4043603          	ld	a2,-448(s0)
    800058b0:	e3843783          	ld	a5,-456(s0)
    800058b4:	f8f669e3          	bltu	a2,a5,80005846 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800058b8:	e2843783          	ld	a5,-472(s0)
    800058bc:	963e                	add	a2,a2,a5
    800058be:	f8f667e3          	bltu	a2,a5,8000584c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800058c2:	85ca                	mv	a1,s2
    800058c4:	855e                	mv	a0,s7
    800058c6:	ffffc097          	auipc	ra,0xffffc
    800058ca:	b80080e7          	jalr	-1152(ra) # 80001446 <uvmalloc>
    800058ce:	e0a43423          	sd	a0,-504(s0)
    800058d2:	d141                	beqz	a0,80005852 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800058d4:	e2843d03          	ld	s10,-472(s0)
    800058d8:	df043783          	ld	a5,-528(s0)
    800058dc:	00fd77b3          	and	a5,s10,a5
    800058e0:	fba1                	bnez	a5,80005830 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800058e2:	e2042d83          	lw	s11,-480(s0)
    800058e6:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800058ea:	f80c03e3          	beqz	s8,80005870 <exec+0x306>
    800058ee:	8a62                	mv	s4,s8
    800058f0:	4901                	li	s2,0
    800058f2:	b345                	j	80005692 <exec+0x128>

00000000800058f4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800058f4:	7179                	addi	sp,sp,-48
    800058f6:	f406                	sd	ra,40(sp)
    800058f8:	f022                	sd	s0,32(sp)
    800058fa:	ec26                	sd	s1,24(sp)
    800058fc:	e84a                	sd	s2,16(sp)
    800058fe:	1800                	addi	s0,sp,48
    80005900:	892e                	mv	s2,a1
    80005902:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005904:	fdc40593          	addi	a1,s0,-36
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	b76080e7          	jalr	-1162(ra) # 8000347e <argint>
    80005910:	04054063          	bltz	a0,80005950 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005914:	fdc42703          	lw	a4,-36(s0)
    80005918:	47bd                	li	a5,15
    8000591a:	02e7ed63          	bltu	a5,a4,80005954 <argfd+0x60>
    8000591e:	ffffc097          	auipc	ra,0xffffc
    80005922:	694080e7          	jalr	1684(ra) # 80001fb2 <myproc>
    80005926:	fdc42703          	lw	a4,-36(s0)
    8000592a:	01e70793          	addi	a5,a4,30
    8000592e:	078e                	slli	a5,a5,0x3
    80005930:	953e                	add	a0,a0,a5
    80005932:	611c                	ld	a5,0(a0)
    80005934:	c395                	beqz	a5,80005958 <argfd+0x64>
    return -1;
  if(pfd)
    80005936:	00090463          	beqz	s2,8000593e <argfd+0x4a>
    *pfd = fd;
    8000593a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000593e:	4501                	li	a0,0
  if(pf)
    80005940:	c091                	beqz	s1,80005944 <argfd+0x50>
    *pf = f;
    80005942:	e09c                	sd	a5,0(s1)
}
    80005944:	70a2                	ld	ra,40(sp)
    80005946:	7402                	ld	s0,32(sp)
    80005948:	64e2                	ld	s1,24(sp)
    8000594a:	6942                	ld	s2,16(sp)
    8000594c:	6145                	addi	sp,sp,48
    8000594e:	8082                	ret
    return -1;
    80005950:	557d                	li	a0,-1
    80005952:	bfcd                	j	80005944 <argfd+0x50>
    return -1;
    80005954:	557d                	li	a0,-1
    80005956:	b7fd                	j	80005944 <argfd+0x50>
    80005958:	557d                	li	a0,-1
    8000595a:	b7ed                	j	80005944 <argfd+0x50>

000000008000595c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000595c:	1101                	addi	sp,sp,-32
    8000595e:	ec06                	sd	ra,24(sp)
    80005960:	e822                	sd	s0,16(sp)
    80005962:	e426                	sd	s1,8(sp)
    80005964:	1000                	addi	s0,sp,32
    80005966:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005968:	ffffc097          	auipc	ra,0xffffc
    8000596c:	64a080e7          	jalr	1610(ra) # 80001fb2 <myproc>
    80005970:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005972:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005976:	4501                	li	a0,0
    80005978:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000597a:	6398                	ld	a4,0(a5)
    8000597c:	cb19                	beqz	a4,80005992 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000597e:	2505                	addiw	a0,a0,1
    80005980:	07a1                	addi	a5,a5,8
    80005982:	fed51ce3          	bne	a0,a3,8000597a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005986:	557d                	li	a0,-1
}
    80005988:	60e2                	ld	ra,24(sp)
    8000598a:	6442                	ld	s0,16(sp)
    8000598c:	64a2                	ld	s1,8(sp)
    8000598e:	6105                	addi	sp,sp,32
    80005990:	8082                	ret
      p->ofile[fd] = f;
    80005992:	01e50793          	addi	a5,a0,30
    80005996:	078e                	slli	a5,a5,0x3
    80005998:	963e                	add	a2,a2,a5
    8000599a:	e204                	sd	s1,0(a2)
      return fd;
    8000599c:	b7f5                	j	80005988 <fdalloc+0x2c>

000000008000599e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000599e:	715d                	addi	sp,sp,-80
    800059a0:	e486                	sd	ra,72(sp)
    800059a2:	e0a2                	sd	s0,64(sp)
    800059a4:	fc26                	sd	s1,56(sp)
    800059a6:	f84a                	sd	s2,48(sp)
    800059a8:	f44e                	sd	s3,40(sp)
    800059aa:	f052                	sd	s4,32(sp)
    800059ac:	ec56                	sd	s5,24(sp)
    800059ae:	0880                	addi	s0,sp,80
    800059b0:	89ae                	mv	s3,a1
    800059b2:	8ab2                	mv	s5,a2
    800059b4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800059b6:	fb040593          	addi	a1,s0,-80
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	e86080e7          	jalr	-378(ra) # 80004840 <nameiparent>
    800059c2:	892a                	mv	s2,a0
    800059c4:	12050f63          	beqz	a0,80005b02 <create+0x164>
    return 0;

  ilock(dp);
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	6a4080e7          	jalr	1700(ra) # 8000406c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800059d0:	4601                	li	a2,0
    800059d2:	fb040593          	addi	a1,s0,-80
    800059d6:	854a                	mv	a0,s2
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	b78080e7          	jalr	-1160(ra) # 80004550 <dirlookup>
    800059e0:	84aa                	mv	s1,a0
    800059e2:	c921                	beqz	a0,80005a32 <create+0x94>
    iunlockput(dp);
    800059e4:	854a                	mv	a0,s2
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	8e8080e7          	jalr	-1816(ra) # 800042ce <iunlockput>
    ilock(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	67c080e7          	jalr	1660(ra) # 8000406c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800059f8:	2981                	sext.w	s3,s3
    800059fa:	4789                	li	a5,2
    800059fc:	02f99463          	bne	s3,a5,80005a24 <create+0x86>
    80005a00:	0444d783          	lhu	a5,68(s1)
    80005a04:	37f9                	addiw	a5,a5,-2
    80005a06:	17c2                	slli	a5,a5,0x30
    80005a08:	93c1                	srli	a5,a5,0x30
    80005a0a:	4705                	li	a4,1
    80005a0c:	00f76c63          	bltu	a4,a5,80005a24 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005a10:	8526                	mv	a0,s1
    80005a12:	60a6                	ld	ra,72(sp)
    80005a14:	6406                	ld	s0,64(sp)
    80005a16:	74e2                	ld	s1,56(sp)
    80005a18:	7942                	ld	s2,48(sp)
    80005a1a:	79a2                	ld	s3,40(sp)
    80005a1c:	7a02                	ld	s4,32(sp)
    80005a1e:	6ae2                	ld	s5,24(sp)
    80005a20:	6161                	addi	sp,sp,80
    80005a22:	8082                	ret
    iunlockput(ip);
    80005a24:	8526                	mv	a0,s1
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	8a8080e7          	jalr	-1880(ra) # 800042ce <iunlockput>
    return 0;
    80005a2e:	4481                	li	s1,0
    80005a30:	b7c5                	j	80005a10 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005a32:	85ce                	mv	a1,s3
    80005a34:	00092503          	lw	a0,0(s2)
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	49c080e7          	jalr	1180(ra) # 80003ed4 <ialloc>
    80005a40:	84aa                	mv	s1,a0
    80005a42:	c529                	beqz	a0,80005a8c <create+0xee>
  ilock(ip);
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	628080e7          	jalr	1576(ra) # 8000406c <ilock>
  ip->major = major;
    80005a4c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005a50:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005a54:	4785                	li	a5,1
    80005a56:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	546080e7          	jalr	1350(ra) # 80003fa2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a64:	2981                	sext.w	s3,s3
    80005a66:	4785                	li	a5,1
    80005a68:	02f98a63          	beq	s3,a5,80005a9c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a6c:	40d0                	lw	a2,4(s1)
    80005a6e:	fb040593          	addi	a1,s0,-80
    80005a72:	854a                	mv	a0,s2
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	cec080e7          	jalr	-788(ra) # 80004760 <dirlink>
    80005a7c:	06054b63          	bltz	a0,80005af2 <create+0x154>
  iunlockput(dp);
    80005a80:	854a                	mv	a0,s2
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	84c080e7          	jalr	-1972(ra) # 800042ce <iunlockput>
  return ip;
    80005a8a:	b759                	j	80005a10 <create+0x72>
    panic("create: ialloc");
    80005a8c:	00003517          	auipc	a0,0x3
    80005a90:	d4c50513          	addi	a0,a0,-692 # 800087d8 <syscalls+0x2b8>
    80005a94:	ffffb097          	auipc	ra,0xffffb
    80005a98:	aaa080e7          	jalr	-1366(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005a9c:	04a95783          	lhu	a5,74(s2)
    80005aa0:	2785                	addiw	a5,a5,1
    80005aa2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	4fa080e7          	jalr	1274(ra) # 80003fa2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005ab0:	40d0                	lw	a2,4(s1)
    80005ab2:	00003597          	auipc	a1,0x3
    80005ab6:	d3658593          	addi	a1,a1,-714 # 800087e8 <syscalls+0x2c8>
    80005aba:	8526                	mv	a0,s1
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	ca4080e7          	jalr	-860(ra) # 80004760 <dirlink>
    80005ac4:	00054f63          	bltz	a0,80005ae2 <create+0x144>
    80005ac8:	00492603          	lw	a2,4(s2)
    80005acc:	00003597          	auipc	a1,0x3
    80005ad0:	d2458593          	addi	a1,a1,-732 # 800087f0 <syscalls+0x2d0>
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	c8a080e7          	jalr	-886(ra) # 80004760 <dirlink>
    80005ade:	f80557e3          	bgez	a0,80005a6c <create+0xce>
      panic("create dots");
    80005ae2:	00003517          	auipc	a0,0x3
    80005ae6:	d1650513          	addi	a0,a0,-746 # 800087f8 <syscalls+0x2d8>
    80005aea:	ffffb097          	auipc	ra,0xffffb
    80005aee:	a54080e7          	jalr	-1452(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005af2:	00003517          	auipc	a0,0x3
    80005af6:	d1650513          	addi	a0,a0,-746 # 80008808 <syscalls+0x2e8>
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>
    return 0;
    80005b02:	84aa                	mv	s1,a0
    80005b04:	b731                	j	80005a10 <create+0x72>

0000000080005b06 <sys_dup>:
{
    80005b06:	7179                	addi	sp,sp,-48
    80005b08:	f406                	sd	ra,40(sp)
    80005b0a:	f022                	sd	s0,32(sp)
    80005b0c:	ec26                	sd	s1,24(sp)
    80005b0e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005b10:	fd840613          	addi	a2,s0,-40
    80005b14:	4581                	li	a1,0
    80005b16:	4501                	li	a0,0
    80005b18:	00000097          	auipc	ra,0x0
    80005b1c:	ddc080e7          	jalr	-548(ra) # 800058f4 <argfd>
    return -1;
    80005b20:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b22:	02054363          	bltz	a0,80005b48 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b26:	fd843503          	ld	a0,-40(s0)
    80005b2a:	00000097          	auipc	ra,0x0
    80005b2e:	e32080e7          	jalr	-462(ra) # 8000595c <fdalloc>
    80005b32:	84aa                	mv	s1,a0
    return -1;
    80005b34:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b36:	00054963          	bltz	a0,80005b48 <sys_dup+0x42>
  filedup(f);
    80005b3a:	fd843503          	ld	a0,-40(s0)
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	37a080e7          	jalr	890(ra) # 80004eb8 <filedup>
  return fd;
    80005b46:	87a6                	mv	a5,s1
}
    80005b48:	853e                	mv	a0,a5
    80005b4a:	70a2                	ld	ra,40(sp)
    80005b4c:	7402                	ld	s0,32(sp)
    80005b4e:	64e2                	ld	s1,24(sp)
    80005b50:	6145                	addi	sp,sp,48
    80005b52:	8082                	ret

0000000080005b54 <sys_read>:
{
    80005b54:	7179                	addi	sp,sp,-48
    80005b56:	f406                	sd	ra,40(sp)
    80005b58:	f022                	sd	s0,32(sp)
    80005b5a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b5c:	fe840613          	addi	a2,s0,-24
    80005b60:	4581                	li	a1,0
    80005b62:	4501                	li	a0,0
    80005b64:	00000097          	auipc	ra,0x0
    80005b68:	d90080e7          	jalr	-624(ra) # 800058f4 <argfd>
    return -1;
    80005b6c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b6e:	04054163          	bltz	a0,80005bb0 <sys_read+0x5c>
    80005b72:	fe440593          	addi	a1,s0,-28
    80005b76:	4509                	li	a0,2
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	906080e7          	jalr	-1786(ra) # 8000347e <argint>
    return -1;
    80005b80:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b82:	02054763          	bltz	a0,80005bb0 <sys_read+0x5c>
    80005b86:	fd840593          	addi	a1,s0,-40
    80005b8a:	4505                	li	a0,1
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	914080e7          	jalr	-1772(ra) # 800034a0 <argaddr>
    return -1;
    80005b94:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b96:	00054d63          	bltz	a0,80005bb0 <sys_read+0x5c>
  return fileread(f, p, n);
    80005b9a:	fe442603          	lw	a2,-28(s0)
    80005b9e:	fd843583          	ld	a1,-40(s0)
    80005ba2:	fe843503          	ld	a0,-24(s0)
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	49e080e7          	jalr	1182(ra) # 80005044 <fileread>
    80005bae:	87aa                	mv	a5,a0
}
    80005bb0:	853e                	mv	a0,a5
    80005bb2:	70a2                	ld	ra,40(sp)
    80005bb4:	7402                	ld	s0,32(sp)
    80005bb6:	6145                	addi	sp,sp,48
    80005bb8:	8082                	ret

0000000080005bba <sys_write>:
{
    80005bba:	7179                	addi	sp,sp,-48
    80005bbc:	f406                	sd	ra,40(sp)
    80005bbe:	f022                	sd	s0,32(sp)
    80005bc0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bc2:	fe840613          	addi	a2,s0,-24
    80005bc6:	4581                	li	a1,0
    80005bc8:	4501                	li	a0,0
    80005bca:	00000097          	auipc	ra,0x0
    80005bce:	d2a080e7          	jalr	-726(ra) # 800058f4 <argfd>
    return -1;
    80005bd2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bd4:	04054163          	bltz	a0,80005c16 <sys_write+0x5c>
    80005bd8:	fe440593          	addi	a1,s0,-28
    80005bdc:	4509                	li	a0,2
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	8a0080e7          	jalr	-1888(ra) # 8000347e <argint>
    return -1;
    80005be6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005be8:	02054763          	bltz	a0,80005c16 <sys_write+0x5c>
    80005bec:	fd840593          	addi	a1,s0,-40
    80005bf0:	4505                	li	a0,1
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	8ae080e7          	jalr	-1874(ra) # 800034a0 <argaddr>
    return -1;
    80005bfa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bfc:	00054d63          	bltz	a0,80005c16 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005c00:	fe442603          	lw	a2,-28(s0)
    80005c04:	fd843583          	ld	a1,-40(s0)
    80005c08:	fe843503          	ld	a0,-24(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	4fa080e7          	jalr	1274(ra) # 80005106 <filewrite>
    80005c14:	87aa                	mv	a5,a0
}
    80005c16:	853e                	mv	a0,a5
    80005c18:	70a2                	ld	ra,40(sp)
    80005c1a:	7402                	ld	s0,32(sp)
    80005c1c:	6145                	addi	sp,sp,48
    80005c1e:	8082                	ret

0000000080005c20 <sys_close>:
{
    80005c20:	1101                	addi	sp,sp,-32
    80005c22:	ec06                	sd	ra,24(sp)
    80005c24:	e822                	sd	s0,16(sp)
    80005c26:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005c28:	fe040613          	addi	a2,s0,-32
    80005c2c:	fec40593          	addi	a1,s0,-20
    80005c30:	4501                	li	a0,0
    80005c32:	00000097          	auipc	ra,0x0
    80005c36:	cc2080e7          	jalr	-830(ra) # 800058f4 <argfd>
    return -1;
    80005c3a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c3c:	02054463          	bltz	a0,80005c64 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c40:	ffffc097          	auipc	ra,0xffffc
    80005c44:	372080e7          	jalr	882(ra) # 80001fb2 <myproc>
    80005c48:	fec42783          	lw	a5,-20(s0)
    80005c4c:	07f9                	addi	a5,a5,30
    80005c4e:	078e                	slli	a5,a5,0x3
    80005c50:	97aa                	add	a5,a5,a0
    80005c52:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005c56:	fe043503          	ld	a0,-32(s0)
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	2b0080e7          	jalr	688(ra) # 80004f0a <fileclose>
  return 0;
    80005c62:	4781                	li	a5,0
}
    80005c64:	853e                	mv	a0,a5
    80005c66:	60e2                	ld	ra,24(sp)
    80005c68:	6442                	ld	s0,16(sp)
    80005c6a:	6105                	addi	sp,sp,32
    80005c6c:	8082                	ret

0000000080005c6e <sys_fstat>:
{
    80005c6e:	1101                	addi	sp,sp,-32
    80005c70:	ec06                	sd	ra,24(sp)
    80005c72:	e822                	sd	s0,16(sp)
    80005c74:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c76:	fe840613          	addi	a2,s0,-24
    80005c7a:	4581                	li	a1,0
    80005c7c:	4501                	li	a0,0
    80005c7e:	00000097          	auipc	ra,0x0
    80005c82:	c76080e7          	jalr	-906(ra) # 800058f4 <argfd>
    return -1;
    80005c86:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c88:	02054563          	bltz	a0,80005cb2 <sys_fstat+0x44>
    80005c8c:	fe040593          	addi	a1,s0,-32
    80005c90:	4505                	li	a0,1
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	80e080e7          	jalr	-2034(ra) # 800034a0 <argaddr>
    return -1;
    80005c9a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c9c:	00054b63          	bltz	a0,80005cb2 <sys_fstat+0x44>
  return filestat(f, st);
    80005ca0:	fe043583          	ld	a1,-32(s0)
    80005ca4:	fe843503          	ld	a0,-24(s0)
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	32a080e7          	jalr	810(ra) # 80004fd2 <filestat>
    80005cb0:	87aa                	mv	a5,a0
}
    80005cb2:	853e                	mv	a0,a5
    80005cb4:	60e2                	ld	ra,24(sp)
    80005cb6:	6442                	ld	s0,16(sp)
    80005cb8:	6105                	addi	sp,sp,32
    80005cba:	8082                	ret

0000000080005cbc <sys_link>:
{
    80005cbc:	7169                	addi	sp,sp,-304
    80005cbe:	f606                	sd	ra,296(sp)
    80005cc0:	f222                	sd	s0,288(sp)
    80005cc2:	ee26                	sd	s1,280(sp)
    80005cc4:	ea4a                	sd	s2,272(sp)
    80005cc6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cc8:	08000613          	li	a2,128
    80005ccc:	ed040593          	addi	a1,s0,-304
    80005cd0:	4501                	li	a0,0
    80005cd2:	ffffd097          	auipc	ra,0xffffd
    80005cd6:	7f0080e7          	jalr	2032(ra) # 800034c2 <argstr>
    return -1;
    80005cda:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cdc:	10054e63          	bltz	a0,80005df8 <sys_link+0x13c>
    80005ce0:	08000613          	li	a2,128
    80005ce4:	f5040593          	addi	a1,s0,-176
    80005ce8:	4505                	li	a0,1
    80005cea:	ffffd097          	auipc	ra,0xffffd
    80005cee:	7d8080e7          	jalr	2008(ra) # 800034c2 <argstr>
    return -1;
    80005cf2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cf4:	10054263          	bltz	a0,80005df8 <sys_link+0x13c>
  begin_op();
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	d46080e7          	jalr	-698(ra) # 80004a3e <begin_op>
  if((ip = namei(old)) == 0){
    80005d00:	ed040513          	addi	a0,s0,-304
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	b1e080e7          	jalr	-1250(ra) # 80004822 <namei>
    80005d0c:	84aa                	mv	s1,a0
    80005d0e:	c551                	beqz	a0,80005d9a <sys_link+0xde>
  ilock(ip);
    80005d10:	ffffe097          	auipc	ra,0xffffe
    80005d14:	35c080e7          	jalr	860(ra) # 8000406c <ilock>
  if(ip->type == T_DIR){
    80005d18:	04449703          	lh	a4,68(s1)
    80005d1c:	4785                	li	a5,1
    80005d1e:	08f70463          	beq	a4,a5,80005da6 <sys_link+0xea>
  ip->nlink++;
    80005d22:	04a4d783          	lhu	a5,74(s1)
    80005d26:	2785                	addiw	a5,a5,1
    80005d28:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d2c:	8526                	mv	a0,s1
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	274080e7          	jalr	628(ra) # 80003fa2 <iupdate>
  iunlock(ip);
    80005d36:	8526                	mv	a0,s1
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	3f6080e7          	jalr	1014(ra) # 8000412e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d40:	fd040593          	addi	a1,s0,-48
    80005d44:	f5040513          	addi	a0,s0,-176
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	af8080e7          	jalr	-1288(ra) # 80004840 <nameiparent>
    80005d50:	892a                	mv	s2,a0
    80005d52:	c935                	beqz	a0,80005dc6 <sys_link+0x10a>
  ilock(dp);
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	318080e7          	jalr	792(ra) # 8000406c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d5c:	00092703          	lw	a4,0(s2)
    80005d60:	409c                	lw	a5,0(s1)
    80005d62:	04f71d63          	bne	a4,a5,80005dbc <sys_link+0x100>
    80005d66:	40d0                	lw	a2,4(s1)
    80005d68:	fd040593          	addi	a1,s0,-48
    80005d6c:	854a                	mv	a0,s2
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	9f2080e7          	jalr	-1550(ra) # 80004760 <dirlink>
    80005d76:	04054363          	bltz	a0,80005dbc <sys_link+0x100>
  iunlockput(dp);
    80005d7a:	854a                	mv	a0,s2
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	552080e7          	jalr	1362(ra) # 800042ce <iunlockput>
  iput(ip);
    80005d84:	8526                	mv	a0,s1
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	4a0080e7          	jalr	1184(ra) # 80004226 <iput>
  end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	d30080e7          	jalr	-720(ra) # 80004abe <end_op>
  return 0;
    80005d96:	4781                	li	a5,0
    80005d98:	a085                	j	80005df8 <sys_link+0x13c>
    end_op();
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	d24080e7          	jalr	-732(ra) # 80004abe <end_op>
    return -1;
    80005da2:	57fd                	li	a5,-1
    80005da4:	a891                	j	80005df8 <sys_link+0x13c>
    iunlockput(ip);
    80005da6:	8526                	mv	a0,s1
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	526080e7          	jalr	1318(ra) # 800042ce <iunlockput>
    end_op();
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	d0e080e7          	jalr	-754(ra) # 80004abe <end_op>
    return -1;
    80005db8:	57fd                	li	a5,-1
    80005dba:	a83d                	j	80005df8 <sys_link+0x13c>
    iunlockput(dp);
    80005dbc:	854a                	mv	a0,s2
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	510080e7          	jalr	1296(ra) # 800042ce <iunlockput>
  ilock(ip);
    80005dc6:	8526                	mv	a0,s1
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	2a4080e7          	jalr	676(ra) # 8000406c <ilock>
  ip->nlink--;
    80005dd0:	04a4d783          	lhu	a5,74(s1)
    80005dd4:	37fd                	addiw	a5,a5,-1
    80005dd6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005dda:	8526                	mv	a0,s1
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	1c6080e7          	jalr	454(ra) # 80003fa2 <iupdate>
  iunlockput(ip);
    80005de4:	8526                	mv	a0,s1
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	4e8080e7          	jalr	1256(ra) # 800042ce <iunlockput>
  end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	cd0080e7          	jalr	-816(ra) # 80004abe <end_op>
  return -1;
    80005df6:	57fd                	li	a5,-1
}
    80005df8:	853e                	mv	a0,a5
    80005dfa:	70b2                	ld	ra,296(sp)
    80005dfc:	7412                	ld	s0,288(sp)
    80005dfe:	64f2                	ld	s1,280(sp)
    80005e00:	6952                	ld	s2,272(sp)
    80005e02:	6155                	addi	sp,sp,304
    80005e04:	8082                	ret

0000000080005e06 <sys_unlink>:
{
    80005e06:	7151                	addi	sp,sp,-240
    80005e08:	f586                	sd	ra,232(sp)
    80005e0a:	f1a2                	sd	s0,224(sp)
    80005e0c:	eda6                	sd	s1,216(sp)
    80005e0e:	e9ca                	sd	s2,208(sp)
    80005e10:	e5ce                	sd	s3,200(sp)
    80005e12:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005e14:	08000613          	li	a2,128
    80005e18:	f3040593          	addi	a1,s0,-208
    80005e1c:	4501                	li	a0,0
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	6a4080e7          	jalr	1700(ra) # 800034c2 <argstr>
    80005e26:	18054163          	bltz	a0,80005fa8 <sys_unlink+0x1a2>
  begin_op();
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	c14080e7          	jalr	-1004(ra) # 80004a3e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e32:	fb040593          	addi	a1,s0,-80
    80005e36:	f3040513          	addi	a0,s0,-208
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	a06080e7          	jalr	-1530(ra) # 80004840 <nameiparent>
    80005e42:	84aa                	mv	s1,a0
    80005e44:	c979                	beqz	a0,80005f1a <sys_unlink+0x114>
  ilock(dp);
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	226080e7          	jalr	550(ra) # 8000406c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e4e:	00003597          	auipc	a1,0x3
    80005e52:	99a58593          	addi	a1,a1,-1638 # 800087e8 <syscalls+0x2c8>
    80005e56:	fb040513          	addi	a0,s0,-80
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	6dc080e7          	jalr	1756(ra) # 80004536 <namecmp>
    80005e62:	14050a63          	beqz	a0,80005fb6 <sys_unlink+0x1b0>
    80005e66:	00003597          	auipc	a1,0x3
    80005e6a:	98a58593          	addi	a1,a1,-1654 # 800087f0 <syscalls+0x2d0>
    80005e6e:	fb040513          	addi	a0,s0,-80
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	6c4080e7          	jalr	1732(ra) # 80004536 <namecmp>
    80005e7a:	12050e63          	beqz	a0,80005fb6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e7e:	f2c40613          	addi	a2,s0,-212
    80005e82:	fb040593          	addi	a1,s0,-80
    80005e86:	8526                	mv	a0,s1
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	6c8080e7          	jalr	1736(ra) # 80004550 <dirlookup>
    80005e90:	892a                	mv	s2,a0
    80005e92:	12050263          	beqz	a0,80005fb6 <sys_unlink+0x1b0>
  ilock(ip);
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	1d6080e7          	jalr	470(ra) # 8000406c <ilock>
  if(ip->nlink < 1)
    80005e9e:	04a91783          	lh	a5,74(s2)
    80005ea2:	08f05263          	blez	a5,80005f26 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ea6:	04491703          	lh	a4,68(s2)
    80005eaa:	4785                	li	a5,1
    80005eac:	08f70563          	beq	a4,a5,80005f36 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005eb0:	4641                	li	a2,16
    80005eb2:	4581                	li	a1,0
    80005eb4:	fc040513          	addi	a0,s0,-64
    80005eb8:	ffffb097          	auipc	ra,0xffffb
    80005ebc:	e4c080e7          	jalr	-436(ra) # 80000d04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ec0:	4741                	li	a4,16
    80005ec2:	f2c42683          	lw	a3,-212(s0)
    80005ec6:	fc040613          	addi	a2,s0,-64
    80005eca:	4581                	li	a1,0
    80005ecc:	8526                	mv	a0,s1
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	54a080e7          	jalr	1354(ra) # 80004418 <writei>
    80005ed6:	47c1                	li	a5,16
    80005ed8:	0af51563          	bne	a0,a5,80005f82 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005edc:	04491703          	lh	a4,68(s2)
    80005ee0:	4785                	li	a5,1
    80005ee2:	0af70863          	beq	a4,a5,80005f92 <sys_unlink+0x18c>
  iunlockput(dp);
    80005ee6:	8526                	mv	a0,s1
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	3e6080e7          	jalr	998(ra) # 800042ce <iunlockput>
  ip->nlink--;
    80005ef0:	04a95783          	lhu	a5,74(s2)
    80005ef4:	37fd                	addiw	a5,a5,-1
    80005ef6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005efa:	854a                	mv	a0,s2
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	0a6080e7          	jalr	166(ra) # 80003fa2 <iupdate>
  iunlockput(ip);
    80005f04:	854a                	mv	a0,s2
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	3c8080e7          	jalr	968(ra) # 800042ce <iunlockput>
  end_op();
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	bb0080e7          	jalr	-1104(ra) # 80004abe <end_op>
  return 0;
    80005f16:	4501                	li	a0,0
    80005f18:	a84d                	j	80005fca <sys_unlink+0x1c4>
    end_op();
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	ba4080e7          	jalr	-1116(ra) # 80004abe <end_op>
    return -1;
    80005f22:	557d                	li	a0,-1
    80005f24:	a05d                	j	80005fca <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005f26:	00003517          	auipc	a0,0x3
    80005f2a:	8f250513          	addi	a0,a0,-1806 # 80008818 <syscalls+0x2f8>
    80005f2e:	ffffa097          	auipc	ra,0xffffa
    80005f32:	610080e7          	jalr	1552(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f36:	04c92703          	lw	a4,76(s2)
    80005f3a:	02000793          	li	a5,32
    80005f3e:	f6e7f9e3          	bgeu	a5,a4,80005eb0 <sys_unlink+0xaa>
    80005f42:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f46:	4741                	li	a4,16
    80005f48:	86ce                	mv	a3,s3
    80005f4a:	f1840613          	addi	a2,s0,-232
    80005f4e:	4581                	li	a1,0
    80005f50:	854a                	mv	a0,s2
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	3ce080e7          	jalr	974(ra) # 80004320 <readi>
    80005f5a:	47c1                	li	a5,16
    80005f5c:	00f51b63          	bne	a0,a5,80005f72 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005f60:	f1845783          	lhu	a5,-232(s0)
    80005f64:	e7a1                	bnez	a5,80005fac <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f66:	29c1                	addiw	s3,s3,16
    80005f68:	04c92783          	lw	a5,76(s2)
    80005f6c:	fcf9ede3          	bltu	s3,a5,80005f46 <sys_unlink+0x140>
    80005f70:	b781                	j	80005eb0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	8be50513          	addi	a0,a0,-1858 # 80008830 <syscalls+0x310>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	8c650513          	addi	a0,a0,-1850 # 80008848 <syscalls+0x328>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b4080e7          	jalr	1460(ra) # 8000053e <panic>
    dp->nlink--;
    80005f92:	04a4d783          	lhu	a5,74(s1)
    80005f96:	37fd                	addiw	a5,a5,-1
    80005f98:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f9c:	8526                	mv	a0,s1
    80005f9e:	ffffe097          	auipc	ra,0xffffe
    80005fa2:	004080e7          	jalr	4(ra) # 80003fa2 <iupdate>
    80005fa6:	b781                	j	80005ee6 <sys_unlink+0xe0>
    return -1;
    80005fa8:	557d                	li	a0,-1
    80005faa:	a005                	j	80005fca <sys_unlink+0x1c4>
    iunlockput(ip);
    80005fac:	854a                	mv	a0,s2
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	320080e7          	jalr	800(ra) # 800042ce <iunlockput>
  iunlockput(dp);
    80005fb6:	8526                	mv	a0,s1
    80005fb8:	ffffe097          	auipc	ra,0xffffe
    80005fbc:	316080e7          	jalr	790(ra) # 800042ce <iunlockput>
  end_op();
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	afe080e7          	jalr	-1282(ra) # 80004abe <end_op>
  return -1;
    80005fc8:	557d                	li	a0,-1
}
    80005fca:	70ae                	ld	ra,232(sp)
    80005fcc:	740e                	ld	s0,224(sp)
    80005fce:	64ee                	ld	s1,216(sp)
    80005fd0:	694e                	ld	s2,208(sp)
    80005fd2:	69ae                	ld	s3,200(sp)
    80005fd4:	616d                	addi	sp,sp,240
    80005fd6:	8082                	ret

0000000080005fd8 <sys_open>:

uint64
sys_open(void)
{
    80005fd8:	7131                	addi	sp,sp,-192
    80005fda:	fd06                	sd	ra,184(sp)
    80005fdc:	f922                	sd	s0,176(sp)
    80005fde:	f526                	sd	s1,168(sp)
    80005fe0:	f14a                	sd	s2,160(sp)
    80005fe2:	ed4e                	sd	s3,152(sp)
    80005fe4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005fe6:	08000613          	li	a2,128
    80005fea:	f5040593          	addi	a1,s0,-176
    80005fee:	4501                	li	a0,0
    80005ff0:	ffffd097          	auipc	ra,0xffffd
    80005ff4:	4d2080e7          	jalr	1234(ra) # 800034c2 <argstr>
    return -1;
    80005ff8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ffa:	0c054163          	bltz	a0,800060bc <sys_open+0xe4>
    80005ffe:	f4c40593          	addi	a1,s0,-180
    80006002:	4505                	li	a0,1
    80006004:	ffffd097          	auipc	ra,0xffffd
    80006008:	47a080e7          	jalr	1146(ra) # 8000347e <argint>
    8000600c:	0a054863          	bltz	a0,800060bc <sys_open+0xe4>

  begin_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	a2e080e7          	jalr	-1490(ra) # 80004a3e <begin_op>

  if(omode & O_CREATE){
    80006018:	f4c42783          	lw	a5,-180(s0)
    8000601c:	2007f793          	andi	a5,a5,512
    80006020:	cbdd                	beqz	a5,800060d6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006022:	4681                	li	a3,0
    80006024:	4601                	li	a2,0
    80006026:	4589                	li	a1,2
    80006028:	f5040513          	addi	a0,s0,-176
    8000602c:	00000097          	auipc	ra,0x0
    80006030:	972080e7          	jalr	-1678(ra) # 8000599e <create>
    80006034:	892a                	mv	s2,a0
    if(ip == 0){
    80006036:	c959                	beqz	a0,800060cc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006038:	04491703          	lh	a4,68(s2)
    8000603c:	478d                	li	a5,3
    8000603e:	00f71763          	bne	a4,a5,8000604c <sys_open+0x74>
    80006042:	04695703          	lhu	a4,70(s2)
    80006046:	47a5                	li	a5,9
    80006048:	0ce7ec63          	bltu	a5,a4,80006120 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000604c:	fffff097          	auipc	ra,0xfffff
    80006050:	e02080e7          	jalr	-510(ra) # 80004e4e <filealloc>
    80006054:	89aa                	mv	s3,a0
    80006056:	10050263          	beqz	a0,8000615a <sys_open+0x182>
    8000605a:	00000097          	auipc	ra,0x0
    8000605e:	902080e7          	jalr	-1790(ra) # 8000595c <fdalloc>
    80006062:	84aa                	mv	s1,a0
    80006064:	0e054663          	bltz	a0,80006150 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006068:	04491703          	lh	a4,68(s2)
    8000606c:	478d                	li	a5,3
    8000606e:	0cf70463          	beq	a4,a5,80006136 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006072:	4789                	li	a5,2
    80006074:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006078:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000607c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006080:	f4c42783          	lw	a5,-180(s0)
    80006084:	0017c713          	xori	a4,a5,1
    80006088:	8b05                	andi	a4,a4,1
    8000608a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000608e:	0037f713          	andi	a4,a5,3
    80006092:	00e03733          	snez	a4,a4
    80006096:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000609a:	4007f793          	andi	a5,a5,1024
    8000609e:	c791                	beqz	a5,800060aa <sys_open+0xd2>
    800060a0:	04491703          	lh	a4,68(s2)
    800060a4:	4789                	li	a5,2
    800060a6:	08f70f63          	beq	a4,a5,80006144 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800060aa:	854a                	mv	a0,s2
    800060ac:	ffffe097          	auipc	ra,0xffffe
    800060b0:	082080e7          	jalr	130(ra) # 8000412e <iunlock>
  end_op();
    800060b4:	fffff097          	auipc	ra,0xfffff
    800060b8:	a0a080e7          	jalr	-1526(ra) # 80004abe <end_op>

  return fd;
}
    800060bc:	8526                	mv	a0,s1
    800060be:	70ea                	ld	ra,184(sp)
    800060c0:	744a                	ld	s0,176(sp)
    800060c2:	74aa                	ld	s1,168(sp)
    800060c4:	790a                	ld	s2,160(sp)
    800060c6:	69ea                	ld	s3,152(sp)
    800060c8:	6129                	addi	sp,sp,192
    800060ca:	8082                	ret
      end_op();
    800060cc:	fffff097          	auipc	ra,0xfffff
    800060d0:	9f2080e7          	jalr	-1550(ra) # 80004abe <end_op>
      return -1;
    800060d4:	b7e5                	j	800060bc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800060d6:	f5040513          	addi	a0,s0,-176
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	748080e7          	jalr	1864(ra) # 80004822 <namei>
    800060e2:	892a                	mv	s2,a0
    800060e4:	c905                	beqz	a0,80006114 <sys_open+0x13c>
    ilock(ip);
    800060e6:	ffffe097          	auipc	ra,0xffffe
    800060ea:	f86080e7          	jalr	-122(ra) # 8000406c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800060ee:	04491703          	lh	a4,68(s2)
    800060f2:	4785                	li	a5,1
    800060f4:	f4f712e3          	bne	a4,a5,80006038 <sys_open+0x60>
    800060f8:	f4c42783          	lw	a5,-180(s0)
    800060fc:	dba1                	beqz	a5,8000604c <sys_open+0x74>
      iunlockput(ip);
    800060fe:	854a                	mv	a0,s2
    80006100:	ffffe097          	auipc	ra,0xffffe
    80006104:	1ce080e7          	jalr	462(ra) # 800042ce <iunlockput>
      end_op();
    80006108:	fffff097          	auipc	ra,0xfffff
    8000610c:	9b6080e7          	jalr	-1610(ra) # 80004abe <end_op>
      return -1;
    80006110:	54fd                	li	s1,-1
    80006112:	b76d                	j	800060bc <sys_open+0xe4>
      end_op();
    80006114:	fffff097          	auipc	ra,0xfffff
    80006118:	9aa080e7          	jalr	-1622(ra) # 80004abe <end_op>
      return -1;
    8000611c:	54fd                	li	s1,-1
    8000611e:	bf79                	j	800060bc <sys_open+0xe4>
    iunlockput(ip);
    80006120:	854a                	mv	a0,s2
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	1ac080e7          	jalr	428(ra) # 800042ce <iunlockput>
    end_op();
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	994080e7          	jalr	-1644(ra) # 80004abe <end_op>
    return -1;
    80006132:	54fd                	li	s1,-1
    80006134:	b761                	j	800060bc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006136:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000613a:	04691783          	lh	a5,70(s2)
    8000613e:	02f99223          	sh	a5,36(s3)
    80006142:	bf2d                	j	8000607c <sys_open+0xa4>
    itrunc(ip);
    80006144:	854a                	mv	a0,s2
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	034080e7          	jalr	52(ra) # 8000417a <itrunc>
    8000614e:	bfb1                	j	800060aa <sys_open+0xd2>
      fileclose(f);
    80006150:	854e                	mv	a0,s3
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	db8080e7          	jalr	-584(ra) # 80004f0a <fileclose>
    iunlockput(ip);
    8000615a:	854a                	mv	a0,s2
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	172080e7          	jalr	370(ra) # 800042ce <iunlockput>
    end_op();
    80006164:	fffff097          	auipc	ra,0xfffff
    80006168:	95a080e7          	jalr	-1702(ra) # 80004abe <end_op>
    return -1;
    8000616c:	54fd                	li	s1,-1
    8000616e:	b7b9                	j	800060bc <sys_open+0xe4>

0000000080006170 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006170:	7175                	addi	sp,sp,-144
    80006172:	e506                	sd	ra,136(sp)
    80006174:	e122                	sd	s0,128(sp)
    80006176:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	8c6080e7          	jalr	-1850(ra) # 80004a3e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006180:	08000613          	li	a2,128
    80006184:	f7040593          	addi	a1,s0,-144
    80006188:	4501                	li	a0,0
    8000618a:	ffffd097          	auipc	ra,0xffffd
    8000618e:	338080e7          	jalr	824(ra) # 800034c2 <argstr>
    80006192:	02054963          	bltz	a0,800061c4 <sys_mkdir+0x54>
    80006196:	4681                	li	a3,0
    80006198:	4601                	li	a2,0
    8000619a:	4585                	li	a1,1
    8000619c:	f7040513          	addi	a0,s0,-144
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	7fe080e7          	jalr	2046(ra) # 8000599e <create>
    800061a8:	cd11                	beqz	a0,800061c4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061aa:	ffffe097          	auipc	ra,0xffffe
    800061ae:	124080e7          	jalr	292(ra) # 800042ce <iunlockput>
  end_op();
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	90c080e7          	jalr	-1780(ra) # 80004abe <end_op>
  return 0;
    800061ba:	4501                	li	a0,0
}
    800061bc:	60aa                	ld	ra,136(sp)
    800061be:	640a                	ld	s0,128(sp)
    800061c0:	6149                	addi	sp,sp,144
    800061c2:	8082                	ret
    end_op();
    800061c4:	fffff097          	auipc	ra,0xfffff
    800061c8:	8fa080e7          	jalr	-1798(ra) # 80004abe <end_op>
    return -1;
    800061cc:	557d                	li	a0,-1
    800061ce:	b7fd                	j	800061bc <sys_mkdir+0x4c>

00000000800061d0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800061d0:	7135                	addi	sp,sp,-160
    800061d2:	ed06                	sd	ra,152(sp)
    800061d4:	e922                	sd	s0,144(sp)
    800061d6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800061d8:	fffff097          	auipc	ra,0xfffff
    800061dc:	866080e7          	jalr	-1946(ra) # 80004a3e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061e0:	08000613          	li	a2,128
    800061e4:	f7040593          	addi	a1,s0,-144
    800061e8:	4501                	li	a0,0
    800061ea:	ffffd097          	auipc	ra,0xffffd
    800061ee:	2d8080e7          	jalr	728(ra) # 800034c2 <argstr>
    800061f2:	04054a63          	bltz	a0,80006246 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800061f6:	f6c40593          	addi	a1,s0,-148
    800061fa:	4505                	li	a0,1
    800061fc:	ffffd097          	auipc	ra,0xffffd
    80006200:	282080e7          	jalr	642(ra) # 8000347e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006204:	04054163          	bltz	a0,80006246 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006208:	f6840593          	addi	a1,s0,-152
    8000620c:	4509                	li	a0,2
    8000620e:	ffffd097          	auipc	ra,0xffffd
    80006212:	270080e7          	jalr	624(ra) # 8000347e <argint>
     argint(1, &major) < 0 ||
    80006216:	02054863          	bltz	a0,80006246 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000621a:	f6841683          	lh	a3,-152(s0)
    8000621e:	f6c41603          	lh	a2,-148(s0)
    80006222:	458d                	li	a1,3
    80006224:	f7040513          	addi	a0,s0,-144
    80006228:	fffff097          	auipc	ra,0xfffff
    8000622c:	776080e7          	jalr	1910(ra) # 8000599e <create>
     argint(2, &minor) < 0 ||
    80006230:	c919                	beqz	a0,80006246 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006232:	ffffe097          	auipc	ra,0xffffe
    80006236:	09c080e7          	jalr	156(ra) # 800042ce <iunlockput>
  end_op();
    8000623a:	fffff097          	auipc	ra,0xfffff
    8000623e:	884080e7          	jalr	-1916(ra) # 80004abe <end_op>
  return 0;
    80006242:	4501                	li	a0,0
    80006244:	a031                	j	80006250 <sys_mknod+0x80>
    end_op();
    80006246:	fffff097          	auipc	ra,0xfffff
    8000624a:	878080e7          	jalr	-1928(ra) # 80004abe <end_op>
    return -1;
    8000624e:	557d                	li	a0,-1
}
    80006250:	60ea                	ld	ra,152(sp)
    80006252:	644a                	ld	s0,144(sp)
    80006254:	610d                	addi	sp,sp,160
    80006256:	8082                	ret

0000000080006258 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006258:	7135                	addi	sp,sp,-160
    8000625a:	ed06                	sd	ra,152(sp)
    8000625c:	e922                	sd	s0,144(sp)
    8000625e:	e526                	sd	s1,136(sp)
    80006260:	e14a                	sd	s2,128(sp)
    80006262:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006264:	ffffc097          	auipc	ra,0xffffc
    80006268:	d4e080e7          	jalr	-690(ra) # 80001fb2 <myproc>
    8000626c:	892a                	mv	s2,a0
  
  begin_op();
    8000626e:	ffffe097          	auipc	ra,0xffffe
    80006272:	7d0080e7          	jalr	2000(ra) # 80004a3e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006276:	08000613          	li	a2,128
    8000627a:	f6040593          	addi	a1,s0,-160
    8000627e:	4501                	li	a0,0
    80006280:	ffffd097          	auipc	ra,0xffffd
    80006284:	242080e7          	jalr	578(ra) # 800034c2 <argstr>
    80006288:	04054b63          	bltz	a0,800062de <sys_chdir+0x86>
    8000628c:	f6040513          	addi	a0,s0,-160
    80006290:	ffffe097          	auipc	ra,0xffffe
    80006294:	592080e7          	jalr	1426(ra) # 80004822 <namei>
    80006298:	84aa                	mv	s1,a0
    8000629a:	c131                	beqz	a0,800062de <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000629c:	ffffe097          	auipc	ra,0xffffe
    800062a0:	dd0080e7          	jalr	-560(ra) # 8000406c <ilock>
  if(ip->type != T_DIR){
    800062a4:	04449703          	lh	a4,68(s1)
    800062a8:	4785                	li	a5,1
    800062aa:	04f71063          	bne	a4,a5,800062ea <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800062ae:	8526                	mv	a0,s1
    800062b0:	ffffe097          	auipc	ra,0xffffe
    800062b4:	e7e080e7          	jalr	-386(ra) # 8000412e <iunlock>
  iput(p->cwd);
    800062b8:	17093503          	ld	a0,368(s2)
    800062bc:	ffffe097          	auipc	ra,0xffffe
    800062c0:	f6a080e7          	jalr	-150(ra) # 80004226 <iput>
  end_op();
    800062c4:	ffffe097          	auipc	ra,0xffffe
    800062c8:	7fa080e7          	jalr	2042(ra) # 80004abe <end_op>
  p->cwd = ip;
    800062cc:	16993823          	sd	s1,368(s2)
  return 0;
    800062d0:	4501                	li	a0,0
}
    800062d2:	60ea                	ld	ra,152(sp)
    800062d4:	644a                	ld	s0,144(sp)
    800062d6:	64aa                	ld	s1,136(sp)
    800062d8:	690a                	ld	s2,128(sp)
    800062da:	610d                	addi	sp,sp,160
    800062dc:	8082                	ret
    end_op();
    800062de:	ffffe097          	auipc	ra,0xffffe
    800062e2:	7e0080e7          	jalr	2016(ra) # 80004abe <end_op>
    return -1;
    800062e6:	557d                	li	a0,-1
    800062e8:	b7ed                	j	800062d2 <sys_chdir+0x7a>
    iunlockput(ip);
    800062ea:	8526                	mv	a0,s1
    800062ec:	ffffe097          	auipc	ra,0xffffe
    800062f0:	fe2080e7          	jalr	-30(ra) # 800042ce <iunlockput>
    end_op();
    800062f4:	ffffe097          	auipc	ra,0xffffe
    800062f8:	7ca080e7          	jalr	1994(ra) # 80004abe <end_op>
    return -1;
    800062fc:	557d                	li	a0,-1
    800062fe:	bfd1                	j	800062d2 <sys_chdir+0x7a>

0000000080006300 <sys_exec>:

uint64
sys_exec(void)
{
    80006300:	7145                	addi	sp,sp,-464
    80006302:	e786                	sd	ra,456(sp)
    80006304:	e3a2                	sd	s0,448(sp)
    80006306:	ff26                	sd	s1,440(sp)
    80006308:	fb4a                	sd	s2,432(sp)
    8000630a:	f74e                	sd	s3,424(sp)
    8000630c:	f352                	sd	s4,416(sp)
    8000630e:	ef56                	sd	s5,408(sp)
    80006310:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006312:	08000613          	li	a2,128
    80006316:	f4040593          	addi	a1,s0,-192
    8000631a:	4501                	li	a0,0
    8000631c:	ffffd097          	auipc	ra,0xffffd
    80006320:	1a6080e7          	jalr	422(ra) # 800034c2 <argstr>
    return -1;
    80006324:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006326:	0c054a63          	bltz	a0,800063fa <sys_exec+0xfa>
    8000632a:	e3840593          	addi	a1,s0,-456
    8000632e:	4505                	li	a0,1
    80006330:	ffffd097          	auipc	ra,0xffffd
    80006334:	170080e7          	jalr	368(ra) # 800034a0 <argaddr>
    80006338:	0c054163          	bltz	a0,800063fa <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000633c:	10000613          	li	a2,256
    80006340:	4581                	li	a1,0
    80006342:	e4040513          	addi	a0,s0,-448
    80006346:	ffffb097          	auipc	ra,0xffffb
    8000634a:	9be080e7          	jalr	-1602(ra) # 80000d04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000634e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006352:	89a6                	mv	s3,s1
    80006354:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006356:	02000a13          	li	s4,32
    8000635a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000635e:	00391513          	slli	a0,s2,0x3
    80006362:	e3040593          	addi	a1,s0,-464
    80006366:	e3843783          	ld	a5,-456(s0)
    8000636a:	953e                	add	a0,a0,a5
    8000636c:	ffffd097          	auipc	ra,0xffffd
    80006370:	078080e7          	jalr	120(ra) # 800033e4 <fetchaddr>
    80006374:	02054a63          	bltz	a0,800063a8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006378:	e3043783          	ld	a5,-464(s0)
    8000637c:	c3b9                	beqz	a5,800063c2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000637e:	ffffa097          	auipc	ra,0xffffa
    80006382:	776080e7          	jalr	1910(ra) # 80000af4 <kalloc>
    80006386:	85aa                	mv	a1,a0
    80006388:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000638c:	cd11                	beqz	a0,800063a8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000638e:	6605                	lui	a2,0x1
    80006390:	e3043503          	ld	a0,-464(s0)
    80006394:	ffffd097          	auipc	ra,0xffffd
    80006398:	0a2080e7          	jalr	162(ra) # 80003436 <fetchstr>
    8000639c:	00054663          	bltz	a0,800063a8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800063a0:	0905                	addi	s2,s2,1
    800063a2:	09a1                	addi	s3,s3,8
    800063a4:	fb491be3          	bne	s2,s4,8000635a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063a8:	10048913          	addi	s2,s1,256
    800063ac:	6088                	ld	a0,0(s1)
    800063ae:	c529                	beqz	a0,800063f8 <sys_exec+0xf8>
    kfree(argv[i]);
    800063b0:	ffffa097          	auipc	ra,0xffffa
    800063b4:	648080e7          	jalr	1608(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063b8:	04a1                	addi	s1,s1,8
    800063ba:	ff2499e3          	bne	s1,s2,800063ac <sys_exec+0xac>
  return -1;
    800063be:	597d                	li	s2,-1
    800063c0:	a82d                	j	800063fa <sys_exec+0xfa>
      argv[i] = 0;
    800063c2:	0a8e                	slli	s5,s5,0x3
    800063c4:	fc040793          	addi	a5,s0,-64
    800063c8:	9abe                	add	s5,s5,a5
    800063ca:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800063ce:	e4040593          	addi	a1,s0,-448
    800063d2:	f4040513          	addi	a0,s0,-192
    800063d6:	fffff097          	auipc	ra,0xfffff
    800063da:	194080e7          	jalr	404(ra) # 8000556a <exec>
    800063de:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063e0:	10048993          	addi	s3,s1,256
    800063e4:	6088                	ld	a0,0(s1)
    800063e6:	c911                	beqz	a0,800063fa <sys_exec+0xfa>
    kfree(argv[i]);
    800063e8:	ffffa097          	auipc	ra,0xffffa
    800063ec:	610080e7          	jalr	1552(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063f0:	04a1                	addi	s1,s1,8
    800063f2:	ff3499e3          	bne	s1,s3,800063e4 <sys_exec+0xe4>
    800063f6:	a011                	j	800063fa <sys_exec+0xfa>
  return -1;
    800063f8:	597d                	li	s2,-1
}
    800063fa:	854a                	mv	a0,s2
    800063fc:	60be                	ld	ra,456(sp)
    800063fe:	641e                	ld	s0,448(sp)
    80006400:	74fa                	ld	s1,440(sp)
    80006402:	795a                	ld	s2,432(sp)
    80006404:	79ba                	ld	s3,424(sp)
    80006406:	7a1a                	ld	s4,416(sp)
    80006408:	6afa                	ld	s5,408(sp)
    8000640a:	6179                	addi	sp,sp,464
    8000640c:	8082                	ret

000000008000640e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000640e:	7139                	addi	sp,sp,-64
    80006410:	fc06                	sd	ra,56(sp)
    80006412:	f822                	sd	s0,48(sp)
    80006414:	f426                	sd	s1,40(sp)
    80006416:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006418:	ffffc097          	auipc	ra,0xffffc
    8000641c:	b9a080e7          	jalr	-1126(ra) # 80001fb2 <myproc>
    80006420:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006422:	fd840593          	addi	a1,s0,-40
    80006426:	4501                	li	a0,0
    80006428:	ffffd097          	auipc	ra,0xffffd
    8000642c:	078080e7          	jalr	120(ra) # 800034a0 <argaddr>
    return -1;
    80006430:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006432:	0e054063          	bltz	a0,80006512 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006436:	fc840593          	addi	a1,s0,-56
    8000643a:	fd040513          	addi	a0,s0,-48
    8000643e:	fffff097          	auipc	ra,0xfffff
    80006442:	dfc080e7          	jalr	-516(ra) # 8000523a <pipealloc>
    return -1;
    80006446:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006448:	0c054563          	bltz	a0,80006512 <sys_pipe+0x104>
  fd0 = -1;
    8000644c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006450:	fd043503          	ld	a0,-48(s0)
    80006454:	fffff097          	auipc	ra,0xfffff
    80006458:	508080e7          	jalr	1288(ra) # 8000595c <fdalloc>
    8000645c:	fca42223          	sw	a0,-60(s0)
    80006460:	08054c63          	bltz	a0,800064f8 <sys_pipe+0xea>
    80006464:	fc843503          	ld	a0,-56(s0)
    80006468:	fffff097          	auipc	ra,0xfffff
    8000646c:	4f4080e7          	jalr	1268(ra) # 8000595c <fdalloc>
    80006470:	fca42023          	sw	a0,-64(s0)
    80006474:	06054863          	bltz	a0,800064e4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006478:	4691                	li	a3,4
    8000647a:	fc440613          	addi	a2,s0,-60
    8000647e:	fd843583          	ld	a1,-40(s0)
    80006482:	78a8                	ld	a0,112(s1)
    80006484:	ffffb097          	auipc	ra,0xffffb
    80006488:	212080e7          	jalr	530(ra) # 80001696 <copyout>
    8000648c:	02054063          	bltz	a0,800064ac <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006490:	4691                	li	a3,4
    80006492:	fc040613          	addi	a2,s0,-64
    80006496:	fd843583          	ld	a1,-40(s0)
    8000649a:	0591                	addi	a1,a1,4
    8000649c:	78a8                	ld	a0,112(s1)
    8000649e:	ffffb097          	auipc	ra,0xffffb
    800064a2:	1f8080e7          	jalr	504(ra) # 80001696 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800064a6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800064a8:	06055563          	bgez	a0,80006512 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800064ac:	fc442783          	lw	a5,-60(s0)
    800064b0:	07f9                	addi	a5,a5,30
    800064b2:	078e                	slli	a5,a5,0x3
    800064b4:	97a6                	add	a5,a5,s1
    800064b6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800064ba:	fc042503          	lw	a0,-64(s0)
    800064be:	0579                	addi	a0,a0,30
    800064c0:	050e                	slli	a0,a0,0x3
    800064c2:	9526                	add	a0,a0,s1
    800064c4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800064c8:	fd043503          	ld	a0,-48(s0)
    800064cc:	fffff097          	auipc	ra,0xfffff
    800064d0:	a3e080e7          	jalr	-1474(ra) # 80004f0a <fileclose>
    fileclose(wf);
    800064d4:	fc843503          	ld	a0,-56(s0)
    800064d8:	fffff097          	auipc	ra,0xfffff
    800064dc:	a32080e7          	jalr	-1486(ra) # 80004f0a <fileclose>
    return -1;
    800064e0:	57fd                	li	a5,-1
    800064e2:	a805                	j	80006512 <sys_pipe+0x104>
    if(fd0 >= 0)
    800064e4:	fc442783          	lw	a5,-60(s0)
    800064e8:	0007c863          	bltz	a5,800064f8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800064ec:	01e78513          	addi	a0,a5,30
    800064f0:	050e                	slli	a0,a0,0x3
    800064f2:	9526                	add	a0,a0,s1
    800064f4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800064f8:	fd043503          	ld	a0,-48(s0)
    800064fc:	fffff097          	auipc	ra,0xfffff
    80006500:	a0e080e7          	jalr	-1522(ra) # 80004f0a <fileclose>
    fileclose(wf);
    80006504:	fc843503          	ld	a0,-56(s0)
    80006508:	fffff097          	auipc	ra,0xfffff
    8000650c:	a02080e7          	jalr	-1534(ra) # 80004f0a <fileclose>
    return -1;
    80006510:	57fd                	li	a5,-1
}
    80006512:	853e                	mv	a0,a5
    80006514:	70e2                	ld	ra,56(sp)
    80006516:	7442                	ld	s0,48(sp)
    80006518:	74a2                	ld	s1,40(sp)
    8000651a:	6121                	addi	sp,sp,64
    8000651c:	8082                	ret
	...

0000000080006520 <kernelvec>:
    80006520:	7111                	addi	sp,sp,-256
    80006522:	e006                	sd	ra,0(sp)
    80006524:	e40a                	sd	sp,8(sp)
    80006526:	e80e                	sd	gp,16(sp)
    80006528:	ec12                	sd	tp,24(sp)
    8000652a:	f016                	sd	t0,32(sp)
    8000652c:	f41a                	sd	t1,40(sp)
    8000652e:	f81e                	sd	t2,48(sp)
    80006530:	fc22                	sd	s0,56(sp)
    80006532:	e0a6                	sd	s1,64(sp)
    80006534:	e4aa                	sd	a0,72(sp)
    80006536:	e8ae                	sd	a1,80(sp)
    80006538:	ecb2                	sd	a2,88(sp)
    8000653a:	f0b6                	sd	a3,96(sp)
    8000653c:	f4ba                	sd	a4,104(sp)
    8000653e:	f8be                	sd	a5,112(sp)
    80006540:	fcc2                	sd	a6,120(sp)
    80006542:	e146                	sd	a7,128(sp)
    80006544:	e54a                	sd	s2,136(sp)
    80006546:	e94e                	sd	s3,144(sp)
    80006548:	ed52                	sd	s4,152(sp)
    8000654a:	f156                	sd	s5,160(sp)
    8000654c:	f55a                	sd	s6,168(sp)
    8000654e:	f95e                	sd	s7,176(sp)
    80006550:	fd62                	sd	s8,184(sp)
    80006552:	e1e6                	sd	s9,192(sp)
    80006554:	e5ea                	sd	s10,200(sp)
    80006556:	e9ee                	sd	s11,208(sp)
    80006558:	edf2                	sd	t3,216(sp)
    8000655a:	f1f6                	sd	t4,224(sp)
    8000655c:	f5fa                	sd	t5,232(sp)
    8000655e:	f9fe                	sd	t6,240(sp)
    80006560:	d51fc0ef          	jal	ra,800032b0 <kerneltrap>
    80006564:	6082                	ld	ra,0(sp)
    80006566:	6122                	ld	sp,8(sp)
    80006568:	61c2                	ld	gp,16(sp)
    8000656a:	7282                	ld	t0,32(sp)
    8000656c:	7322                	ld	t1,40(sp)
    8000656e:	73c2                	ld	t2,48(sp)
    80006570:	7462                	ld	s0,56(sp)
    80006572:	6486                	ld	s1,64(sp)
    80006574:	6526                	ld	a0,72(sp)
    80006576:	65c6                	ld	a1,80(sp)
    80006578:	6666                	ld	a2,88(sp)
    8000657a:	7686                	ld	a3,96(sp)
    8000657c:	7726                	ld	a4,104(sp)
    8000657e:	77c6                	ld	a5,112(sp)
    80006580:	7866                	ld	a6,120(sp)
    80006582:	688a                	ld	a7,128(sp)
    80006584:	692a                	ld	s2,136(sp)
    80006586:	69ca                	ld	s3,144(sp)
    80006588:	6a6a                	ld	s4,152(sp)
    8000658a:	7a8a                	ld	s5,160(sp)
    8000658c:	7b2a                	ld	s6,168(sp)
    8000658e:	7bca                	ld	s7,176(sp)
    80006590:	7c6a                	ld	s8,184(sp)
    80006592:	6c8e                	ld	s9,192(sp)
    80006594:	6d2e                	ld	s10,200(sp)
    80006596:	6dce                	ld	s11,208(sp)
    80006598:	6e6e                	ld	t3,216(sp)
    8000659a:	7e8e                	ld	t4,224(sp)
    8000659c:	7f2e                	ld	t5,232(sp)
    8000659e:	7fce                	ld	t6,240(sp)
    800065a0:	6111                	addi	sp,sp,256
    800065a2:	10200073          	sret
    800065a6:	00000013          	nop
    800065aa:	00000013          	nop
    800065ae:	0001                	nop

00000000800065b0 <timervec>:
    800065b0:	34051573          	csrrw	a0,mscratch,a0
    800065b4:	e10c                	sd	a1,0(a0)
    800065b6:	e510                	sd	a2,8(a0)
    800065b8:	e914                	sd	a3,16(a0)
    800065ba:	6d0c                	ld	a1,24(a0)
    800065bc:	7110                	ld	a2,32(a0)
    800065be:	6194                	ld	a3,0(a1)
    800065c0:	96b2                	add	a3,a3,a2
    800065c2:	e194                	sd	a3,0(a1)
    800065c4:	4589                	li	a1,2
    800065c6:	14459073          	csrw	sip,a1
    800065ca:	6914                	ld	a3,16(a0)
    800065cc:	6510                	ld	a2,8(a0)
    800065ce:	610c                	ld	a1,0(a0)
    800065d0:	34051573          	csrrw	a0,mscratch,a0
    800065d4:	30200073          	mret
	...

00000000800065da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800065da:	1141                	addi	sp,sp,-16
    800065dc:	e422                	sd	s0,8(sp)
    800065de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800065e0:	0c0007b7          	lui	a5,0xc000
    800065e4:	4705                	li	a4,1
    800065e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800065e8:	c3d8                	sw	a4,4(a5)
}
    800065ea:	6422                	ld	s0,8(sp)
    800065ec:	0141                	addi	sp,sp,16
    800065ee:	8082                	ret

00000000800065f0 <plicinithart>:

void
plicinithart(void)
{
    800065f0:	1141                	addi	sp,sp,-16
    800065f2:	e406                	sd	ra,8(sp)
    800065f4:	e022                	sd	s0,0(sp)
    800065f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065f8:	ffffc097          	auipc	ra,0xffffc
    800065fc:	986080e7          	jalr	-1658(ra) # 80001f7e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006600:	0085171b          	slliw	a4,a0,0x8
    80006604:	0c0027b7          	lui	a5,0xc002
    80006608:	97ba                	add	a5,a5,a4
    8000660a:	40200713          	li	a4,1026
    8000660e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006612:	00d5151b          	slliw	a0,a0,0xd
    80006616:	0c2017b7          	lui	a5,0xc201
    8000661a:	953e                	add	a0,a0,a5
    8000661c:	00052023          	sw	zero,0(a0)
}
    80006620:	60a2                	ld	ra,8(sp)
    80006622:	6402                	ld	s0,0(sp)
    80006624:	0141                	addi	sp,sp,16
    80006626:	8082                	ret

0000000080006628 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006628:	1141                	addi	sp,sp,-16
    8000662a:	e406                	sd	ra,8(sp)
    8000662c:	e022                	sd	s0,0(sp)
    8000662e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006630:	ffffc097          	auipc	ra,0xffffc
    80006634:	94e080e7          	jalr	-1714(ra) # 80001f7e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006638:	00d5179b          	slliw	a5,a0,0xd
    8000663c:	0c201537          	lui	a0,0xc201
    80006640:	953e                	add	a0,a0,a5
  return irq;
}
    80006642:	4148                	lw	a0,4(a0)
    80006644:	60a2                	ld	ra,8(sp)
    80006646:	6402                	ld	s0,0(sp)
    80006648:	0141                	addi	sp,sp,16
    8000664a:	8082                	ret

000000008000664c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000664c:	1101                	addi	sp,sp,-32
    8000664e:	ec06                	sd	ra,24(sp)
    80006650:	e822                	sd	s0,16(sp)
    80006652:	e426                	sd	s1,8(sp)
    80006654:	1000                	addi	s0,sp,32
    80006656:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006658:	ffffc097          	auipc	ra,0xffffc
    8000665c:	926080e7          	jalr	-1754(ra) # 80001f7e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006660:	00d5151b          	slliw	a0,a0,0xd
    80006664:	0c2017b7          	lui	a5,0xc201
    80006668:	97aa                	add	a5,a5,a0
    8000666a:	c3c4                	sw	s1,4(a5)
}
    8000666c:	60e2                	ld	ra,24(sp)
    8000666e:	6442                	ld	s0,16(sp)
    80006670:	64a2                	ld	s1,8(sp)
    80006672:	6105                	addi	sp,sp,32
    80006674:	8082                	ret

0000000080006676 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006676:	1141                	addi	sp,sp,-16
    80006678:	e406                	sd	ra,8(sp)
    8000667a:	e022                	sd	s0,0(sp)
    8000667c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000667e:	479d                	li	a5,7
    80006680:	06a7c963          	blt	a5,a0,800066f2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006684:	0001d797          	auipc	a5,0x1d
    80006688:	97c78793          	addi	a5,a5,-1668 # 80023000 <disk>
    8000668c:	00a78733          	add	a4,a5,a0
    80006690:	6789                	lui	a5,0x2
    80006692:	97ba                	add	a5,a5,a4
    80006694:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006698:	e7ad                	bnez	a5,80006702 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000669a:	00451793          	slli	a5,a0,0x4
    8000669e:	0001f717          	auipc	a4,0x1f
    800066a2:	96270713          	addi	a4,a4,-1694 # 80025000 <disk+0x2000>
    800066a6:	6314                	ld	a3,0(a4)
    800066a8:	96be                	add	a3,a3,a5
    800066aa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800066ae:	6314                	ld	a3,0(a4)
    800066b0:	96be                	add	a3,a3,a5
    800066b2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800066b6:	6314                	ld	a3,0(a4)
    800066b8:	96be                	add	a3,a3,a5
    800066ba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800066be:	6318                	ld	a4,0(a4)
    800066c0:	97ba                	add	a5,a5,a4
    800066c2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800066c6:	0001d797          	auipc	a5,0x1d
    800066ca:	93a78793          	addi	a5,a5,-1734 # 80023000 <disk>
    800066ce:	97aa                	add	a5,a5,a0
    800066d0:	6509                	lui	a0,0x2
    800066d2:	953e                	add	a0,a0,a5
    800066d4:	4785                	li	a5,1
    800066d6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800066da:	0001f517          	auipc	a0,0x1f
    800066de:	93e50513          	addi	a0,a0,-1730 # 80025018 <disk+0x2018>
    800066e2:	ffffc097          	auipc	ra,0xffffc
    800066e6:	36e080e7          	jalr	878(ra) # 80002a50 <wakeup>
}
    800066ea:	60a2                	ld	ra,8(sp)
    800066ec:	6402                	ld	s0,0(sp)
    800066ee:	0141                	addi	sp,sp,16
    800066f0:	8082                	ret
    panic("free_desc 1");
    800066f2:	00002517          	auipc	a0,0x2
    800066f6:	16650513          	addi	a0,a0,358 # 80008858 <syscalls+0x338>
    800066fa:	ffffa097          	auipc	ra,0xffffa
    800066fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006702:	00002517          	auipc	a0,0x2
    80006706:	16650513          	addi	a0,a0,358 # 80008868 <syscalls+0x348>
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	e34080e7          	jalr	-460(ra) # 8000053e <panic>

0000000080006712 <virtio_disk_init>:
{
    80006712:	1101                	addi	sp,sp,-32
    80006714:	ec06                	sd	ra,24(sp)
    80006716:	e822                	sd	s0,16(sp)
    80006718:	e426                	sd	s1,8(sp)
    8000671a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000671c:	00002597          	auipc	a1,0x2
    80006720:	15c58593          	addi	a1,a1,348 # 80008878 <syscalls+0x358>
    80006724:	0001f517          	auipc	a0,0x1f
    80006728:	a0450513          	addi	a0,a0,-1532 # 80025128 <disk+0x2128>
    8000672c:	ffffa097          	auipc	ra,0xffffa
    80006730:	428080e7          	jalr	1064(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006734:	100017b7          	lui	a5,0x10001
    80006738:	4398                	lw	a4,0(a5)
    8000673a:	2701                	sext.w	a4,a4
    8000673c:	747277b7          	lui	a5,0x74727
    80006740:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006744:	0ef71163          	bne	a4,a5,80006826 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006748:	100017b7          	lui	a5,0x10001
    8000674c:	43dc                	lw	a5,4(a5)
    8000674e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006750:	4705                	li	a4,1
    80006752:	0ce79a63          	bne	a5,a4,80006826 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006756:	100017b7          	lui	a5,0x10001
    8000675a:	479c                	lw	a5,8(a5)
    8000675c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000675e:	4709                	li	a4,2
    80006760:	0ce79363          	bne	a5,a4,80006826 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006764:	100017b7          	lui	a5,0x10001
    80006768:	47d8                	lw	a4,12(a5)
    8000676a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000676c:	554d47b7          	lui	a5,0x554d4
    80006770:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006774:	0af71963          	bne	a4,a5,80006826 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006778:	100017b7          	lui	a5,0x10001
    8000677c:	4705                	li	a4,1
    8000677e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006780:	470d                	li	a4,3
    80006782:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006784:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006786:	c7ffe737          	lui	a4,0xc7ffe
    8000678a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000678e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006790:	2701                	sext.w	a4,a4
    80006792:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006794:	472d                	li	a4,11
    80006796:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006798:	473d                	li	a4,15
    8000679a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000679c:	6705                	lui	a4,0x1
    8000679e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800067a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800067a4:	5bdc                	lw	a5,52(a5)
    800067a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800067a8:	c7d9                	beqz	a5,80006836 <virtio_disk_init+0x124>
  if(max < NUM)
    800067aa:	471d                	li	a4,7
    800067ac:	08f77d63          	bgeu	a4,a5,80006846 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800067b0:	100014b7          	lui	s1,0x10001
    800067b4:	47a1                	li	a5,8
    800067b6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800067b8:	6609                	lui	a2,0x2
    800067ba:	4581                	li	a1,0
    800067bc:	0001d517          	auipc	a0,0x1d
    800067c0:	84450513          	addi	a0,a0,-1980 # 80023000 <disk>
    800067c4:	ffffa097          	auipc	ra,0xffffa
    800067c8:	540080e7          	jalr	1344(ra) # 80000d04 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800067cc:	0001d717          	auipc	a4,0x1d
    800067d0:	83470713          	addi	a4,a4,-1996 # 80023000 <disk>
    800067d4:	00c75793          	srli	a5,a4,0xc
    800067d8:	2781                	sext.w	a5,a5
    800067da:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800067dc:	0001f797          	auipc	a5,0x1f
    800067e0:	82478793          	addi	a5,a5,-2012 # 80025000 <disk+0x2000>
    800067e4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800067e6:	0001d717          	auipc	a4,0x1d
    800067ea:	89a70713          	addi	a4,a4,-1894 # 80023080 <disk+0x80>
    800067ee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800067f0:	0001e717          	auipc	a4,0x1e
    800067f4:	81070713          	addi	a4,a4,-2032 # 80024000 <disk+0x1000>
    800067f8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800067fa:	4705                	li	a4,1
    800067fc:	00e78c23          	sb	a4,24(a5)
    80006800:	00e78ca3          	sb	a4,25(a5)
    80006804:	00e78d23          	sb	a4,26(a5)
    80006808:	00e78da3          	sb	a4,27(a5)
    8000680c:	00e78e23          	sb	a4,28(a5)
    80006810:	00e78ea3          	sb	a4,29(a5)
    80006814:	00e78f23          	sb	a4,30(a5)
    80006818:	00e78fa3          	sb	a4,31(a5)
}
    8000681c:	60e2                	ld	ra,24(sp)
    8000681e:	6442                	ld	s0,16(sp)
    80006820:	64a2                	ld	s1,8(sp)
    80006822:	6105                	addi	sp,sp,32
    80006824:	8082                	ret
    panic("could not find virtio disk");
    80006826:	00002517          	auipc	a0,0x2
    8000682a:	06250513          	addi	a0,a0,98 # 80008888 <syscalls+0x368>
    8000682e:	ffffa097          	auipc	ra,0xffffa
    80006832:	d10080e7          	jalr	-752(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006836:	00002517          	auipc	a0,0x2
    8000683a:	07250513          	addi	a0,a0,114 # 800088a8 <syscalls+0x388>
    8000683e:	ffffa097          	auipc	ra,0xffffa
    80006842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006846:	00002517          	auipc	a0,0x2
    8000684a:	08250513          	addi	a0,a0,130 # 800088c8 <syscalls+0x3a8>
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	cf0080e7          	jalr	-784(ra) # 8000053e <panic>

0000000080006856 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006856:	7159                	addi	sp,sp,-112
    80006858:	f486                	sd	ra,104(sp)
    8000685a:	f0a2                	sd	s0,96(sp)
    8000685c:	eca6                	sd	s1,88(sp)
    8000685e:	e8ca                	sd	s2,80(sp)
    80006860:	e4ce                	sd	s3,72(sp)
    80006862:	e0d2                	sd	s4,64(sp)
    80006864:	fc56                	sd	s5,56(sp)
    80006866:	f85a                	sd	s6,48(sp)
    80006868:	f45e                	sd	s7,40(sp)
    8000686a:	f062                	sd	s8,32(sp)
    8000686c:	ec66                	sd	s9,24(sp)
    8000686e:	e86a                	sd	s10,16(sp)
    80006870:	1880                	addi	s0,sp,112
    80006872:	892a                	mv	s2,a0
    80006874:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006876:	00c52c83          	lw	s9,12(a0)
    8000687a:	001c9c9b          	slliw	s9,s9,0x1
    8000687e:	1c82                	slli	s9,s9,0x20
    80006880:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006884:	0001f517          	auipc	a0,0x1f
    80006888:	8a450513          	addi	a0,a0,-1884 # 80025128 <disk+0x2128>
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	358080e7          	jalr	856(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006894:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006896:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006898:	0001cb97          	auipc	s7,0x1c
    8000689c:	768b8b93          	addi	s7,s7,1896 # 80023000 <disk>
    800068a0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800068a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800068a4:	8a4e                	mv	s4,s3
    800068a6:	a051                	j	8000692a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800068a8:	00fb86b3          	add	a3,s7,a5
    800068ac:	96da                	add	a3,a3,s6
    800068ae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800068b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800068b4:	0207c563          	bltz	a5,800068de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800068b8:	2485                	addiw	s1,s1,1
    800068ba:	0711                	addi	a4,a4,4
    800068bc:	25548063          	beq	s1,s5,80006afc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800068c0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800068c2:	0001e697          	auipc	a3,0x1e
    800068c6:	75668693          	addi	a3,a3,1878 # 80025018 <disk+0x2018>
    800068ca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800068cc:	0006c583          	lbu	a1,0(a3)
    800068d0:	fde1                	bnez	a1,800068a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800068d2:	2785                	addiw	a5,a5,1
    800068d4:	0685                	addi	a3,a3,1
    800068d6:	ff879be3          	bne	a5,s8,800068cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800068da:	57fd                	li	a5,-1
    800068dc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800068de:	02905a63          	blez	s1,80006912 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068e2:	f9042503          	lw	a0,-112(s0)
    800068e6:	00000097          	auipc	ra,0x0
    800068ea:	d90080e7          	jalr	-624(ra) # 80006676 <free_desc>
      for(int j = 0; j < i; j++)
    800068ee:	4785                	li	a5,1
    800068f0:	0297d163          	bge	a5,s1,80006912 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068f4:	f9442503          	lw	a0,-108(s0)
    800068f8:	00000097          	auipc	ra,0x0
    800068fc:	d7e080e7          	jalr	-642(ra) # 80006676 <free_desc>
      for(int j = 0; j < i; j++)
    80006900:	4789                	li	a5,2
    80006902:	0097d863          	bge	a5,s1,80006912 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006906:	f9842503          	lw	a0,-104(s0)
    8000690a:	00000097          	auipc	ra,0x0
    8000690e:	d6c080e7          	jalr	-660(ra) # 80006676 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006912:	0001f597          	auipc	a1,0x1f
    80006916:	81658593          	addi	a1,a1,-2026 # 80025128 <disk+0x2128>
    8000691a:	0001e517          	auipc	a0,0x1e
    8000691e:	6fe50513          	addi	a0,a0,1790 # 80025018 <disk+0x2018>
    80006922:	ffffc097          	auipc	ra,0xffffc
    80006926:	f76080e7          	jalr	-138(ra) # 80002898 <sleep>
  for(int i = 0; i < 3; i++){
    8000692a:	f9040713          	addi	a4,s0,-112
    8000692e:	84ce                	mv	s1,s3
    80006930:	bf41                	j	800068c0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006932:	20058713          	addi	a4,a1,512
    80006936:	00471693          	slli	a3,a4,0x4
    8000693a:	0001c717          	auipc	a4,0x1c
    8000693e:	6c670713          	addi	a4,a4,1734 # 80023000 <disk>
    80006942:	9736                	add	a4,a4,a3
    80006944:	4685                	li	a3,1
    80006946:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000694a:	20058713          	addi	a4,a1,512
    8000694e:	00471693          	slli	a3,a4,0x4
    80006952:	0001c717          	auipc	a4,0x1c
    80006956:	6ae70713          	addi	a4,a4,1710 # 80023000 <disk>
    8000695a:	9736                	add	a4,a4,a3
    8000695c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006960:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006964:	7679                	lui	a2,0xffffe
    80006966:	963e                	add	a2,a2,a5
    80006968:	0001e697          	auipc	a3,0x1e
    8000696c:	69868693          	addi	a3,a3,1688 # 80025000 <disk+0x2000>
    80006970:	6298                	ld	a4,0(a3)
    80006972:	9732                	add	a4,a4,a2
    80006974:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006976:	6298                	ld	a4,0(a3)
    80006978:	9732                	add	a4,a4,a2
    8000697a:	4541                	li	a0,16
    8000697c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000697e:	6298                	ld	a4,0(a3)
    80006980:	9732                	add	a4,a4,a2
    80006982:	4505                	li	a0,1
    80006984:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006988:	f9442703          	lw	a4,-108(s0)
    8000698c:	6288                	ld	a0,0(a3)
    8000698e:	962a                	add	a2,a2,a0
    80006990:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006994:	0712                	slli	a4,a4,0x4
    80006996:	6290                	ld	a2,0(a3)
    80006998:	963a                	add	a2,a2,a4
    8000699a:	05890513          	addi	a0,s2,88
    8000699e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800069a0:	6294                	ld	a3,0(a3)
    800069a2:	96ba                	add	a3,a3,a4
    800069a4:	40000613          	li	a2,1024
    800069a8:	c690                	sw	a2,8(a3)
  if(write)
    800069aa:	140d0063          	beqz	s10,80006aea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800069ae:	0001e697          	auipc	a3,0x1e
    800069b2:	6526b683          	ld	a3,1618(a3) # 80025000 <disk+0x2000>
    800069b6:	96ba                	add	a3,a3,a4
    800069b8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800069bc:	0001c817          	auipc	a6,0x1c
    800069c0:	64480813          	addi	a6,a6,1604 # 80023000 <disk>
    800069c4:	0001e517          	auipc	a0,0x1e
    800069c8:	63c50513          	addi	a0,a0,1596 # 80025000 <disk+0x2000>
    800069cc:	6114                	ld	a3,0(a0)
    800069ce:	96ba                	add	a3,a3,a4
    800069d0:	00c6d603          	lhu	a2,12(a3)
    800069d4:	00166613          	ori	a2,a2,1
    800069d8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800069dc:	f9842683          	lw	a3,-104(s0)
    800069e0:	6110                	ld	a2,0(a0)
    800069e2:	9732                	add	a4,a4,a2
    800069e4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069e8:	20058613          	addi	a2,a1,512
    800069ec:	0612                	slli	a2,a2,0x4
    800069ee:	9642                	add	a2,a2,a6
    800069f0:	577d                	li	a4,-1
    800069f2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069f6:	00469713          	slli	a4,a3,0x4
    800069fa:	6114                	ld	a3,0(a0)
    800069fc:	96ba                	add	a3,a3,a4
    800069fe:	03078793          	addi	a5,a5,48
    80006a02:	97c2                	add	a5,a5,a6
    80006a04:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006a06:	611c                	ld	a5,0(a0)
    80006a08:	97ba                	add	a5,a5,a4
    80006a0a:	4685                	li	a3,1
    80006a0c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006a0e:	611c                	ld	a5,0(a0)
    80006a10:	97ba                	add	a5,a5,a4
    80006a12:	4809                	li	a6,2
    80006a14:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006a18:	611c                	ld	a5,0(a0)
    80006a1a:	973e                	add	a4,a4,a5
    80006a1c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006a20:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006a24:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006a28:	6518                	ld	a4,8(a0)
    80006a2a:	00275783          	lhu	a5,2(a4)
    80006a2e:	8b9d                	andi	a5,a5,7
    80006a30:	0786                	slli	a5,a5,0x1
    80006a32:	97ba                	add	a5,a5,a4
    80006a34:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006a38:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a3c:	6518                	ld	a4,8(a0)
    80006a3e:	00275783          	lhu	a5,2(a4)
    80006a42:	2785                	addiw	a5,a5,1
    80006a44:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a48:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a4c:	100017b7          	lui	a5,0x10001
    80006a50:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a54:	00492703          	lw	a4,4(s2)
    80006a58:	4785                	li	a5,1
    80006a5a:	02f71163          	bne	a4,a5,80006a7c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006a5e:	0001e997          	auipc	s3,0x1e
    80006a62:	6ca98993          	addi	s3,s3,1738 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006a66:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a68:	85ce                	mv	a1,s3
    80006a6a:	854a                	mv	a0,s2
    80006a6c:	ffffc097          	auipc	ra,0xffffc
    80006a70:	e2c080e7          	jalr	-468(ra) # 80002898 <sleep>
  while(b->disk == 1) {
    80006a74:	00492783          	lw	a5,4(s2)
    80006a78:	fe9788e3          	beq	a5,s1,80006a68 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006a7c:	f9042903          	lw	s2,-112(s0)
    80006a80:	20090793          	addi	a5,s2,512
    80006a84:	00479713          	slli	a4,a5,0x4
    80006a88:	0001c797          	auipc	a5,0x1c
    80006a8c:	57878793          	addi	a5,a5,1400 # 80023000 <disk>
    80006a90:	97ba                	add	a5,a5,a4
    80006a92:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006a96:	0001e997          	auipc	s3,0x1e
    80006a9a:	56a98993          	addi	s3,s3,1386 # 80025000 <disk+0x2000>
    80006a9e:	00491713          	slli	a4,s2,0x4
    80006aa2:	0009b783          	ld	a5,0(s3)
    80006aa6:	97ba                	add	a5,a5,a4
    80006aa8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006aac:	854a                	mv	a0,s2
    80006aae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006ab2:	00000097          	auipc	ra,0x0
    80006ab6:	bc4080e7          	jalr	-1084(ra) # 80006676 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006aba:	8885                	andi	s1,s1,1
    80006abc:	f0ed                	bnez	s1,80006a9e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006abe:	0001e517          	auipc	a0,0x1e
    80006ac2:	66a50513          	addi	a0,a0,1642 # 80025128 <disk+0x2128>
    80006ac6:	ffffa097          	auipc	ra,0xffffa
    80006aca:	1e4080e7          	jalr	484(ra) # 80000caa <release>
}
    80006ace:	70a6                	ld	ra,104(sp)
    80006ad0:	7406                	ld	s0,96(sp)
    80006ad2:	64e6                	ld	s1,88(sp)
    80006ad4:	6946                	ld	s2,80(sp)
    80006ad6:	69a6                	ld	s3,72(sp)
    80006ad8:	6a06                	ld	s4,64(sp)
    80006ada:	7ae2                	ld	s5,56(sp)
    80006adc:	7b42                	ld	s6,48(sp)
    80006ade:	7ba2                	ld	s7,40(sp)
    80006ae0:	7c02                	ld	s8,32(sp)
    80006ae2:	6ce2                	ld	s9,24(sp)
    80006ae4:	6d42                	ld	s10,16(sp)
    80006ae6:	6165                	addi	sp,sp,112
    80006ae8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006aea:	0001e697          	auipc	a3,0x1e
    80006aee:	5166b683          	ld	a3,1302(a3) # 80025000 <disk+0x2000>
    80006af2:	96ba                	add	a3,a3,a4
    80006af4:	4609                	li	a2,2
    80006af6:	00c69623          	sh	a2,12(a3)
    80006afa:	b5c9                	j	800069bc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006afc:	f9042583          	lw	a1,-112(s0)
    80006b00:	20058793          	addi	a5,a1,512
    80006b04:	0792                	slli	a5,a5,0x4
    80006b06:	0001c517          	auipc	a0,0x1c
    80006b0a:	5a250513          	addi	a0,a0,1442 # 800230a8 <disk+0xa8>
    80006b0e:	953e                	add	a0,a0,a5
  if(write)
    80006b10:	e20d11e3          	bnez	s10,80006932 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006b14:	20058713          	addi	a4,a1,512
    80006b18:	00471693          	slli	a3,a4,0x4
    80006b1c:	0001c717          	auipc	a4,0x1c
    80006b20:	4e470713          	addi	a4,a4,1252 # 80023000 <disk>
    80006b24:	9736                	add	a4,a4,a3
    80006b26:	0a072423          	sw	zero,168(a4)
    80006b2a:	b505                	j	8000694a <virtio_disk_rw+0xf4>

0000000080006b2c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006b2c:	1101                	addi	sp,sp,-32
    80006b2e:	ec06                	sd	ra,24(sp)
    80006b30:	e822                	sd	s0,16(sp)
    80006b32:	e426                	sd	s1,8(sp)
    80006b34:	e04a                	sd	s2,0(sp)
    80006b36:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006b38:	0001e517          	auipc	a0,0x1e
    80006b3c:	5f050513          	addi	a0,a0,1520 # 80025128 <disk+0x2128>
    80006b40:	ffffa097          	auipc	ra,0xffffa
    80006b44:	0a4080e7          	jalr	164(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006b48:	10001737          	lui	a4,0x10001
    80006b4c:	533c                	lw	a5,96(a4)
    80006b4e:	8b8d                	andi	a5,a5,3
    80006b50:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006b52:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b56:	0001e797          	auipc	a5,0x1e
    80006b5a:	4aa78793          	addi	a5,a5,1194 # 80025000 <disk+0x2000>
    80006b5e:	6b94                	ld	a3,16(a5)
    80006b60:	0207d703          	lhu	a4,32(a5)
    80006b64:	0026d783          	lhu	a5,2(a3)
    80006b68:	06f70163          	beq	a4,a5,80006bca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b6c:	0001c917          	auipc	s2,0x1c
    80006b70:	49490913          	addi	s2,s2,1172 # 80023000 <disk>
    80006b74:	0001e497          	auipc	s1,0x1e
    80006b78:	48c48493          	addi	s1,s1,1164 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006b7c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b80:	6898                	ld	a4,16(s1)
    80006b82:	0204d783          	lhu	a5,32(s1)
    80006b86:	8b9d                	andi	a5,a5,7
    80006b88:	078e                	slli	a5,a5,0x3
    80006b8a:	97ba                	add	a5,a5,a4
    80006b8c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b8e:	20078713          	addi	a4,a5,512
    80006b92:	0712                	slli	a4,a4,0x4
    80006b94:	974a                	add	a4,a4,s2
    80006b96:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006b9a:	e731                	bnez	a4,80006be6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b9c:	20078793          	addi	a5,a5,512
    80006ba0:	0792                	slli	a5,a5,0x4
    80006ba2:	97ca                	add	a5,a5,s2
    80006ba4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006ba6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006baa:	ffffc097          	auipc	ra,0xffffc
    80006bae:	ea6080e7          	jalr	-346(ra) # 80002a50 <wakeup>

    disk.used_idx += 1;
    80006bb2:	0204d783          	lhu	a5,32(s1)
    80006bb6:	2785                	addiw	a5,a5,1
    80006bb8:	17c2                	slli	a5,a5,0x30
    80006bba:	93c1                	srli	a5,a5,0x30
    80006bbc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006bc0:	6898                	ld	a4,16(s1)
    80006bc2:	00275703          	lhu	a4,2(a4)
    80006bc6:	faf71be3          	bne	a4,a5,80006b7c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006bca:	0001e517          	auipc	a0,0x1e
    80006bce:	55e50513          	addi	a0,a0,1374 # 80025128 <disk+0x2128>
    80006bd2:	ffffa097          	auipc	ra,0xffffa
    80006bd6:	0d8080e7          	jalr	216(ra) # 80000caa <release>
}
    80006bda:	60e2                	ld	ra,24(sp)
    80006bdc:	6442                	ld	s0,16(sp)
    80006bde:	64a2                	ld	s1,8(sp)
    80006be0:	6902                	ld	s2,0(sp)
    80006be2:	6105                	addi	sp,sp,32
    80006be4:	8082                	ret
      panic("virtio_disk_intr status");
    80006be6:	00002517          	auipc	a0,0x2
    80006bea:	d0250513          	addi	a0,a0,-766 # 800088e8 <syscalls+0x3c8>
    80006bee:	ffffa097          	auipc	ra,0xffffa
    80006bf2:	950080e7          	jalr	-1712(ra) # 8000053e <panic>

0000000080006bf6 <cas>:
    80006bf6:	100522af          	lr.w	t0,(a0)
    80006bfa:	00b29563          	bne	t0,a1,80006c04 <fail>
    80006bfe:	18c5252f          	sc.w	a0,a2,(a0)
    80006c02:	8082                	ret

0000000080006c04 <fail>:
    80006c04:	4505                	li	a0,1
    80006c06:	8082                	ret
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
