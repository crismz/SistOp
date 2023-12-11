
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8a070713          	addi	a4,a4,-1888 # 800088f0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	bbe78793          	addi	a5,a5,-1090 # 80005c20 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc89f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	400080e7          	jalr	1024(ra) # 8000252a <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8a650513          	addi	a0,a0,-1882 # 80010a30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	89648493          	addi	s1,s1,-1898 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	92690913          	addi	s2,s2,-1754 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7f4080e7          	jalr	2036(ra) # 800019b4 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1ac080e7          	jalr	428(ra) # 80002374 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ef6080e7          	jalr	-266(ra) # 800020cc <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2c2080e7          	jalr	706(ra) # 800024d4 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72b23          	sw	a5,-1962(a4) # 80010ac8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

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
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	76450513          	addi	a0,a0,1892 # 80010a30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	28e080e7          	jalr	654(ra) # 80002580 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	73650513          	addi	a0,a0,1846 # 80010a30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	71270713          	addi	a4,a4,1810 # 80010a30 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6e878793          	addi	a5,a5,1768 # 80010a30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7527a783          	lw	a5,1874(a5) # 80010ac8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6a670713          	addi	a4,a4,1702 # 80010a30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	69648493          	addi	s1,s1,1686 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	65a70713          	addi	a4,a4,1626 # 80010a30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72223          	sw	a5,1764(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	61e78793          	addi	a5,a5,1566 # 80010a30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7ab23          	sw	a2,1686(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	68a50513          	addi	a0,a0,1674 # 80010ac8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cea080e7          	jalr	-790(ra) # 80002130 <wakeup>
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
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5d050513          	addi	a0,a0,1488 # 80010a30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	95078793          	addi	a5,a5,-1712 # 80020dc8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
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
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
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
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5a07a223          	sw	zero,1444(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	32f72823          	sw	a5,816(a4) # 800088b0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	534dad83          	lw	s11,1332(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4de50513          	addi	a0,a0,1246 # 80010ad8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	38050513          	addi	a0,a0,896 # 80010ad8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	36448493          	addi	s1,s1,868 # 80010ad8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	32450513          	addi	a0,a0,804 # 80010af8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0b07a783          	lw	a5,176(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0807b783          	ld	a5,128(a5) # 800088b8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	08073703          	ld	a4,128(a4) # 800088c0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	296a0a13          	addi	s4,s4,662 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	04e48493          	addi	s1,s1,78 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	04e98993          	addi	s3,s3,78 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	89c080e7          	jalr	-1892(ra) # 80002130 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	22850513          	addi	a0,a0,552 # 80010af8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	fd07a783          	lw	a5,-48(a5) # 800088b0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	fd673703          	ld	a4,-42(a4) # 800088c0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fc67b783          	ld	a5,-58(a5) # 800088b8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	1fa98993          	addi	s3,s3,506 # 80010af8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fb248493          	addi	s1,s1,-78 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fb290913          	addi	s2,s2,-78 # 800088c0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	7ae080e7          	jalr	1966(ra) # 800020cc <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1c448493          	addi	s1,s1,452 # 80010af8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f6e7bc23          	sd	a4,-136(a5) # 800088c0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	13e48493          	addi	s1,s1,318 # 80010af8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	56478793          	addi	a5,a5,1380 # 80021f60 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	11490913          	addi	s2,s2,276 # 80010b30 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	07650513          	addi	a0,a0,118 # 80010b30 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	49250513          	addi	a0,a0,1170 # 80021f60 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	04048493          	addi	s1,s1,64 # 80010b30 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	02850513          	addi	a0,a0,40 # 80010b30 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	ffc50513          	addi	a0,a0,-4 # 80010b30 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e28080e7          	jalr	-472(ra) # 80001998 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	df6080e7          	jalr	-522(ra) # 80001998 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	dea080e7          	jalr	-534(ra) # 80001998 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dd2080e7          	jalr	-558(ra) # 80001998 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d92080e7          	jalr	-622(ra) # 80001998 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d66080e7          	jalr	-666(ra) # 80001998 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd0a1>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b08080e7          	jalr	-1272(ra) # 80001988 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a4070713          	addi	a4,a4,-1472 # 800088c8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	aec080e7          	jalr	-1300(ra) # 80001988 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	808080e7          	jalr	-2040(ra) # 800026c6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	d9a080e7          	jalr	-614(ra) # 80005c60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe4080e7          	jalr	-28(ra) # 80001eb2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	768080e7          	jalr	1896(ra) # 8000269e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	788080e7          	jalr	1928(ra) # 800026c6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	d04080e7          	jalr	-764(ra) # 80005c4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	d12080e7          	jalr	-750(ra) # 80005c60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	eac080e7          	jalr	-340(ra) # 80002e02 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	54c080e7          	jalr	1356(ra) # 800034aa <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	4f2080e7          	jalr	1266(ra) # 80004458 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	dfa080e7          	jalr	-518(ra) # 80005d68 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d1e080e7          	jalr	-738(ra) # 80001c94 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72223          	sw	a5,-1724(a4) # 800088c8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9387b783          	ld	a5,-1736(a5) # 800088d0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd097>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	66a7be23          	sd	a0,1660(a5) # 800088d0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd0a0>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	73448493          	addi	s1,s1,1844 # 80010f80 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	31aa0a13          	addi	s4,s4,794 # 80016b80 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	17048493          	addi	s1,s1,368
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	26850513          	addi	a0,a0,616 # 80010b50 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	26850513          	addi	a0,a0,616 # 80010b68 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	67048493          	addi	s1,s1,1648 # 80010f80 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	24e98993          	addi	s3,s3,590 # 80016b80 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
      p->chosen = 0;
    80001964:	1604a623          	sw	zero,364(s1)
      p->priority = 0;
    80001968:	1604a423          	sw	zero,360(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	17048493          	addi	s1,s1,368
    80001970:	fd3495e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    80001974:	70e2                	ld	ra,56(sp)
    80001976:	7442                	ld	s0,48(sp)
    80001978:	74a2                	ld	s1,40(sp)
    8000197a:	7902                	ld	s2,32(sp)
    8000197c:	69e2                	ld	s3,24(sp)
    8000197e:	6a42                	ld	s4,16(sp)
    80001980:	6aa2                	ld	s5,8(sp)
    80001982:	6b02                	ld	s6,0(sp)
    80001984:	6121                	addi	sp,sp,64
    80001986:	8082                	ret

0000000080001988 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001988:	1141                	addi	sp,sp,-16
    8000198a:	e422                	sd	s0,8(sp)
    8000198c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001990:	2501                	sext.w	a0,a0
    80001992:	6422                	ld	s0,8(sp)
    80001994:	0141                	addi	sp,sp,16
    80001996:	8082                	ret

0000000080001998 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001998:	1141                	addi	sp,sp,-16
    8000199a:	e422                	sd	s0,8(sp)
    8000199c:	0800                	addi	s0,sp,16
    8000199e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a0:	2781                	sext.w	a5,a5
    800019a2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a4:	0000f517          	auipc	a0,0xf
    800019a8:	1dc50513          	addi	a0,a0,476 # 80010b80 <cpus>
    800019ac:	953e                	add	a0,a0,a5
    800019ae:	6422                	ld	s0,8(sp)
    800019b0:	0141                	addi	sp,sp,16
    800019b2:	8082                	ret

00000000800019b4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019b4:	1101                	addi	sp,sp,-32
    800019b6:	ec06                	sd	ra,24(sp)
    800019b8:	e822                	sd	s0,16(sp)
    800019ba:	e426                	sd	s1,8(sp)
    800019bc:	1000                	addi	s0,sp,32
  push_off();
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	1cc080e7          	jalr	460(ra) # 80000b8a <push_off>
    800019c6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c8:	2781                	sext.w	a5,a5
    800019ca:	079e                	slli	a5,a5,0x7
    800019cc:	0000f717          	auipc	a4,0xf
    800019d0:	18470713          	addi	a4,a4,388 # 80010b50 <pid_lock>
    800019d4:	97ba                	add	a5,a5,a4
    800019d6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	252080e7          	jalr	594(ra) # 80000c2a <pop_off>
  return p;
}
    800019e0:	8526                	mv	a0,s1
    800019e2:	60e2                	ld	ra,24(sp)
    800019e4:	6442                	ld	s0,16(sp)
    800019e6:	64a2                	ld	s1,8(sp)
    800019e8:	6105                	addi	sp,sp,32
    800019ea:	8082                	ret

00000000800019ec <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ec:	1141                	addi	sp,sp,-16
    800019ee:	e406                	sd	ra,8(sp)
    800019f0:	e022                	sd	s0,0(sp)
    800019f2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	fc0080e7          	jalr	-64(ra) # 800019b4 <myproc>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	28e080e7          	jalr	654(ra) # 80000c8a <release>

  if (first) {
    80001a04:	00007797          	auipc	a5,0x7
    80001a08:	e3c7a783          	lw	a5,-452(a5) # 80008840 <first.1>
    80001a0c:	eb89                	bnez	a5,80001a1e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0e:	00001097          	auipc	ra,0x1
    80001a12:	cd0080e7          	jalr	-816(ra) # 800026de <usertrapret>
}
    80001a16:	60a2                	ld	ra,8(sp)
    80001a18:	6402                	ld	s0,0(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret
    first = 0;
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	e207a123          	sw	zero,-478(a5) # 80008840 <first.1>
    fsinit(ROOTDEV);
    80001a26:	4505                	li	a0,1
    80001a28:	00002097          	auipc	ra,0x2
    80001a2c:	a02080e7          	jalr	-1534(ra) # 8000342a <fsinit>
    80001a30:	bff9                	j	80001a0e <forkret+0x22>

0000000080001a32 <allocpid>:
{
    80001a32:	1101                	addi	sp,sp,-32
    80001a34:	ec06                	sd	ra,24(sp)
    80001a36:	e822                	sd	s0,16(sp)
    80001a38:	e426                	sd	s1,8(sp)
    80001a3a:	e04a                	sd	s2,0(sp)
    80001a3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3e:	0000f917          	auipc	s2,0xf
    80001a42:	11290913          	addi	s2,s2,274 # 80010b50 <pid_lock>
    80001a46:	854a                	mv	a0,s2
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	18e080e7          	jalr	398(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a50:	00007797          	auipc	a5,0x7
    80001a54:	df478793          	addi	a5,a5,-524 # 80008844 <nextpid>
    80001a58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5a:	0014871b          	addiw	a4,s1,1
    80001a5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	228080e7          	jalr	552(ra) # 80000c8a <release>
}
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	60e2                	ld	ra,24(sp)
    80001a6e:	6442                	ld	s0,16(sp)
    80001a70:	64a2                	ld	s1,8(sp)
    80001a72:	6902                	ld	s2,0(sp)
    80001a74:	6105                	addi	sp,sp,32
    80001a76:	8082                	ret

0000000080001a78 <proc_pagetable>:
{
    80001a78:	1101                	addi	sp,sp,-32
    80001a7a:	ec06                	sd	ra,24(sp)
    80001a7c:	e822                	sd	s0,16(sp)
    80001a7e:	e426                	sd	s1,8(sp)
    80001a80:	e04a                	sd	s2,0(sp)
    80001a82:	1000                	addi	s0,sp,32
    80001a84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a86:	00000097          	auipc	ra,0x0
    80001a8a:	8a2080e7          	jalr	-1886(ra) # 80001328 <uvmcreate>
    80001a8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a90:	c121                	beqz	a0,80001ad0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a92:	4729                	li	a4,10
    80001a94:	00005697          	auipc	a3,0x5
    80001a98:	56c68693          	addi	a3,a3,1388 # 80007000 <_trampoline>
    80001a9c:	6605                	lui	a2,0x1
    80001a9e:	040005b7          	lui	a1,0x4000
    80001aa2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aa4:	05b2                	slli	a1,a1,0xc
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5f8080e7          	jalr	1528(ra) # 8000109e <mappages>
    80001aae:	02054863          	bltz	a0,80001ade <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab2:	4719                	li	a4,6
    80001ab4:	05893683          	ld	a3,88(s2)
    80001ab8:	6605                	lui	a2,0x1
    80001aba:	020005b7          	lui	a1,0x2000
    80001abe:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ac0:	05b6                	slli	a1,a1,0xd
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	5da080e7          	jalr	1498(ra) # 8000109e <mappages>
    80001acc:	02054163          	bltz	a0,80001aee <proc_pagetable+0x76>
}
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	60e2                	ld	ra,24(sp)
    80001ad4:	6442                	ld	s0,16(sp)
    80001ad6:	64a2                	ld	s1,8(sp)
    80001ad8:	6902                	ld	s2,0(sp)
    80001ada:	6105                	addi	sp,sp,32
    80001adc:	8082                	ret
    uvmfree(pagetable, 0);
    80001ade:	4581                	li	a1,0
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	00000097          	auipc	ra,0x0
    80001ae6:	a4c080e7          	jalr	-1460(ra) # 8000152e <uvmfree>
    return 0;
    80001aea:	4481                	li	s1,0
    80001aec:	b7d5                	j	80001ad0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	8526                	mv	a0,s1
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	768080e7          	jalr	1896(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b04:	4581                	li	a1,0
    80001b06:	8526                	mv	a0,s1
    80001b08:	00000097          	auipc	ra,0x0
    80001b0c:	a26080e7          	jalr	-1498(ra) # 8000152e <uvmfree>
    return 0;
    80001b10:	4481                	li	s1,0
    80001b12:	bf7d                	j	80001ad0 <proc_pagetable+0x58>

0000000080001b14 <proc_freepagetable>:
{
    80001b14:	1101                	addi	sp,sp,-32
    80001b16:	ec06                	sd	ra,24(sp)
    80001b18:	e822                	sd	s0,16(sp)
    80001b1a:	e426                	sd	s1,8(sp)
    80001b1c:	e04a                	sd	s2,0(sp)
    80001b1e:	1000                	addi	s0,sp,32
    80001b20:	84aa                	mv	s1,a0
    80001b22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b24:	4681                	li	a3,0
    80001b26:	4605                	li	a2,1
    80001b28:	040005b7          	lui	a1,0x4000
    80001b2c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b2e:	05b2                	slli	a1,a1,0xc
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	734080e7          	jalr	1844(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	020005b7          	lui	a1,0x2000
    80001b40:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b42:	05b6                	slli	a1,a1,0xd
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	71e080e7          	jalr	1822(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4e:	85ca                	mv	a1,s2
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	9dc080e7          	jalr	-1572(ra) # 8000152e <uvmfree>
}
    80001b5a:	60e2                	ld	ra,24(sp)
    80001b5c:	6442                	ld	s0,16(sp)
    80001b5e:	64a2                	ld	s1,8(sp)
    80001b60:	6902                	ld	s2,0(sp)
    80001b62:	6105                	addi	sp,sp,32
    80001b64:	8082                	ret

0000000080001b66 <freeproc>:
{
    80001b66:	1101                	addi	sp,sp,-32
    80001b68:	ec06                	sd	ra,24(sp)
    80001b6a:	e822                	sd	s0,16(sp)
    80001b6c:	e426                	sd	s1,8(sp)
    80001b6e:	1000                	addi	s0,sp,32
    80001b70:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b72:	6d28                	ld	a0,88(a0)
    80001b74:	c509                	beqz	a0,80001b7e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	e72080e7          	jalr	-398(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b7e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b82:	68a8                	ld	a0,80(s1)
    80001b84:	c511                	beqz	a0,80001b90 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b86:	64ac                	ld	a1,72(s1)
    80001b88:	00000097          	auipc	ra,0x0
    80001b8c:	f8c080e7          	jalr	-116(ra) # 80001b14 <proc_freepagetable>
  p->pagetable = 0;
    80001b90:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b94:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b98:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b9c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bac:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb0:	0004ac23          	sw	zero,24(s1)
  p->chosen = 0;
    80001bb4:	1604a623          	sw	zero,364(s1)
  p->priority = 0;
    80001bb8:	1604a423          	sw	zero,360(s1)
}
    80001bbc:	60e2                	ld	ra,24(sp)
    80001bbe:	6442                	ld	s0,16(sp)
    80001bc0:	64a2                	ld	s1,8(sp)
    80001bc2:	6105                	addi	sp,sp,32
    80001bc4:	8082                	ret

0000000080001bc6 <allocproc>:
{
    80001bc6:	1101                	addi	sp,sp,-32
    80001bc8:	ec06                	sd	ra,24(sp)
    80001bca:	e822                	sd	s0,16(sp)
    80001bcc:	e426                	sd	s1,8(sp)
    80001bce:	e04a                	sd	s2,0(sp)
    80001bd0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	0000f497          	auipc	s1,0xf
    80001bd6:	3ae48493          	addi	s1,s1,942 # 80010f80 <proc>
    80001bda:	00015917          	auipc	s2,0x15
    80001bde:	fa690913          	addi	s2,s2,-90 # 80016b80 <tickslock>
    acquire(&p->lock);
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	ff2080e7          	jalr	-14(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bec:	4c9c                	lw	a5,24(s1)
    80001bee:	cf81                	beqz	a5,80001c06 <allocproc+0x40>
      release(&p->lock);
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	098080e7          	jalr	152(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfa:	17048493          	addi	s1,s1,368
    80001bfe:	ff2492e3          	bne	s1,s2,80001be2 <allocproc+0x1c>
  return 0;
    80001c02:	4481                	li	s1,0
    80001c04:	a889                	j	80001c56 <allocproc+0x90>
  p->pid = allocpid();
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	e2c080e7          	jalr	-468(ra) # 80001a32 <allocpid>
    80001c0e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c10:	4785                	li	a5,1
    80001c12:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	ed2080e7          	jalr	-302(ra) # 80000ae6 <kalloc>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	eca8                	sd	a0,88(s1)
    80001c20:	c131                	beqz	a0,80001c64 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c22:	8526                	mv	a0,s1
    80001c24:	00000097          	auipc	ra,0x0
    80001c28:	e54080e7          	jalr	-428(ra) # 80001a78 <proc_pagetable>
    80001c2c:	892a                	mv	s2,a0
    80001c2e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c30:	c531                	beqz	a0,80001c7c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c32:	07000613          	li	a2,112
    80001c36:	4581                	li	a1,0
    80001c38:	06048513          	addi	a0,s1,96
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	096080e7          	jalr	150(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c44:	00000797          	auipc	a5,0x0
    80001c48:	da878793          	addi	a5,a5,-600 # 800019ec <forkret>
    80001c4c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c4e:	60bc                	ld	a5,64(s1)
    80001c50:	6705                	lui	a4,0x1
    80001c52:	97ba                	add	a5,a5,a4
    80001c54:	f4bc                	sd	a5,104(s1)
}
    80001c56:	8526                	mv	a0,s1
    80001c58:	60e2                	ld	ra,24(sp)
    80001c5a:	6442                	ld	s0,16(sp)
    80001c5c:	64a2                	ld	s1,8(sp)
    80001c5e:	6902                	ld	s2,0(sp)
    80001c60:	6105                	addi	sp,sp,32
    80001c62:	8082                	ret
    freeproc(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	f00080e7          	jalr	-256(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	01a080e7          	jalr	26(ra) # 80000c8a <release>
    return 0;
    80001c78:	84ca                	mv	s1,s2
    80001c7a:	bff1                	j	80001c56 <allocproc+0x90>
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	ee8080e7          	jalr	-280(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	002080e7          	jalr	2(ra) # 80000c8a <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	b7d1                	j	80001c56 <allocproc+0x90>

0000000080001c94 <userinit>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	f28080e7          	jalr	-216(ra) # 80001bc6 <allocproc>
    80001ca6:	84aa                	mv	s1,a0
  initproc = p;
    80001ca8:	00007797          	auipc	a5,0x7
    80001cac:	c2a7b823          	sd	a0,-976(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cb0:	03400613          	li	a2,52
    80001cb4:	00007597          	auipc	a1,0x7
    80001cb8:	b9c58593          	addi	a1,a1,-1124 # 80008850 <initcode>
    80001cbc:	6928                	ld	a0,80(a0)
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	698080e7          	jalr	1688(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cc6:	6785                	lui	a5,0x1
    80001cc8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cca:	6cb8                	ld	a4,88(s1)
    80001ccc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd0:	6cb8                	ld	a4,88(s1)
    80001cd2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd4:	4641                	li	a2,16
    80001cd6:	00006597          	auipc	a1,0x6
    80001cda:	52a58593          	addi	a1,a1,1322 # 80008200 <digits+0x1c0>
    80001cde:	15848513          	addi	a0,s1,344
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	13a080e7          	jalr	314(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cea:	00006517          	auipc	a0,0x6
    80001cee:	52650513          	addi	a0,a0,1318 # 80008210 <digits+0x1d0>
    80001cf2:	00002097          	auipc	ra,0x2
    80001cf6:	162080e7          	jalr	354(ra) # 80003e54 <namei>
    80001cfa:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfe:	478d                	li	a5,3
    80001d00:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	f86080e7          	jalr	-122(ra) # 80000c8a <release>
}
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6105                	addi	sp,sp,32
    80001d14:	8082                	ret

0000000080001d16 <growproc>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
    80001d22:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	c90080e7          	jalr	-880(ra) # 800019b4 <myproc>
    80001d2c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d2e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d30:	01204c63          	bgtz	s2,80001d48 <growproc+0x32>
  } else if(n < 0){
    80001d34:	02094663          	bltz	s2,80001d60 <growproc+0x4a>
  p->sz = sz;
    80001d38:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d3a:	4501                	li	a0,0
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6902                	ld	s2,0(sp)
    80001d44:	6105                	addi	sp,sp,32
    80001d46:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d48:	4691                	li	a3,4
    80001d4a:	00b90633          	add	a2,s2,a1
    80001d4e:	6928                	ld	a0,80(a0)
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	6c0080e7          	jalr	1728(ra) # 80001410 <uvmalloc>
    80001d58:	85aa                	mv	a1,a0
    80001d5a:	fd79                	bnez	a0,80001d38 <growproc+0x22>
      return -1;
    80001d5c:	557d                	li	a0,-1
    80001d5e:	bff9                	j	80001d3c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d60:	00b90633          	add	a2,s2,a1
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	662080e7          	jalr	1634(ra) # 800013c8 <uvmdealloc>
    80001d6e:	85aa                	mv	a1,a0
    80001d70:	b7e1                	j	80001d38 <growproc+0x22>

0000000080001d72 <fork>:
{
    80001d72:	7139                	addi	sp,sp,-64
    80001d74:	fc06                	sd	ra,56(sp)
    80001d76:	f822                	sd	s0,48(sp)
    80001d78:	f426                	sd	s1,40(sp)
    80001d7a:	f04a                	sd	s2,32(sp)
    80001d7c:	ec4e                	sd	s3,24(sp)
    80001d7e:	e852                	sd	s4,16(sp)
    80001d80:	e456                	sd	s5,8(sp)
    80001d82:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	c30080e7          	jalr	-976(ra) # 800019b4 <myproc>
    80001d8c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	e38080e7          	jalr	-456(ra) # 80001bc6 <allocproc>
    80001d96:	10050c63          	beqz	a0,80001eae <fork+0x13c>
    80001d9a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d9c:	048ab603          	ld	a2,72(s5)
    80001da0:	692c                	ld	a1,80(a0)
    80001da2:	050ab503          	ld	a0,80(s5)
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	7c2080e7          	jalr	1986(ra) # 80001568 <uvmcopy>
    80001dae:	04054863          	bltz	a0,80001dfe <fork+0x8c>
  np->sz = p->sz;
    80001db2:	048ab783          	ld	a5,72(s5)
    80001db6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dba:	058ab683          	ld	a3,88(s5)
    80001dbe:	87b6                	mv	a5,a3
    80001dc0:	058a3703          	ld	a4,88(s4)
    80001dc4:	12068693          	addi	a3,a3,288
    80001dc8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dcc:	6788                	ld	a0,8(a5)
    80001dce:	6b8c                	ld	a1,16(a5)
    80001dd0:	6f90                	ld	a2,24(a5)
    80001dd2:	01073023          	sd	a6,0(a4)
    80001dd6:	e708                	sd	a0,8(a4)
    80001dd8:	eb0c                	sd	a1,16(a4)
    80001dda:	ef10                	sd	a2,24(a4)
    80001ddc:	02078793          	addi	a5,a5,32
    80001de0:	02070713          	addi	a4,a4,32
    80001de4:	fed792e3          	bne	a5,a3,80001dc8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001de8:	058a3783          	ld	a5,88(s4)
    80001dec:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001df0:	0d0a8493          	addi	s1,s5,208
    80001df4:	0d0a0913          	addi	s2,s4,208
    80001df8:	150a8993          	addi	s3,s5,336
    80001dfc:	a00d                	j	80001e1e <fork+0xac>
    freeproc(np);
    80001dfe:	8552                	mv	a0,s4
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	d66080e7          	jalr	-666(ra) # 80001b66 <freeproc>
    release(&np->lock);
    80001e08:	8552                	mv	a0,s4
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	e80080e7          	jalr	-384(ra) # 80000c8a <release>
    return -1;
    80001e12:	597d                	li	s2,-1
    80001e14:	a059                	j	80001e9a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e16:	04a1                	addi	s1,s1,8
    80001e18:	0921                	addi	s2,s2,8
    80001e1a:	01348b63          	beq	s1,s3,80001e30 <fork+0xbe>
    if(p->ofile[i])
    80001e1e:	6088                	ld	a0,0(s1)
    80001e20:	d97d                	beqz	a0,80001e16 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e22:	00002097          	auipc	ra,0x2
    80001e26:	6c8080e7          	jalr	1736(ra) # 800044ea <filedup>
    80001e2a:	00a93023          	sd	a0,0(s2)
    80001e2e:	b7e5                	j	80001e16 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e30:	150ab503          	ld	a0,336(s5)
    80001e34:	00002097          	auipc	ra,0x2
    80001e38:	836080e7          	jalr	-1994(ra) # 8000366a <idup>
    80001e3c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e40:	4641                	li	a2,16
    80001e42:	158a8593          	addi	a1,s5,344
    80001e46:	158a0513          	addi	a0,s4,344
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	fd2080e7          	jalr	-46(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e52:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e56:	8552                	mv	a0,s4
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	e32080e7          	jalr	-462(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e60:	0000f497          	auipc	s1,0xf
    80001e64:	d0848493          	addi	s1,s1,-760 # 80010b68 <wait_lock>
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	d6c080e7          	jalr	-660(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e72:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e76:	8526                	mv	a0,s1
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	e12080e7          	jalr	-494(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	d54080e7          	jalr	-684(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e8a:	478d                	li	a5,3
    80001e8c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e90:	8552                	mv	a0,s4
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	df8080e7          	jalr	-520(ra) # 80000c8a <release>
}
    80001e9a:	854a                	mv	a0,s2
    80001e9c:	70e2                	ld	ra,56(sp)
    80001e9e:	7442                	ld	s0,48(sp)
    80001ea0:	74a2                	ld	s1,40(sp)
    80001ea2:	7902                	ld	s2,32(sp)
    80001ea4:	69e2                	ld	s3,24(sp)
    80001ea6:	6a42                	ld	s4,16(sp)
    80001ea8:	6aa2                	ld	s5,8(sp)
    80001eaa:	6121                	addi	sp,sp,64
    80001eac:	8082                	ret
    return -1;
    80001eae:	597d                	li	s2,-1
    80001eb0:	b7ed                	j	80001e9a <fork+0x128>

0000000080001eb2 <scheduler>:
{
    80001eb2:	711d                	addi	sp,sp,-96
    80001eb4:	ec86                	sd	ra,88(sp)
    80001eb6:	e8a2                	sd	s0,80(sp)
    80001eb8:	e4a6                	sd	s1,72(sp)
    80001eba:	e0ca                	sd	s2,64(sp)
    80001ebc:	fc4e                	sd	s3,56(sp)
    80001ebe:	f852                	sd	s4,48(sp)
    80001ec0:	f456                	sd	s5,40(sp)
    80001ec2:	f05a                	sd	s6,32(sp)
    80001ec4:	ec5e                	sd	s7,24(sp)
    80001ec6:	e862                	sd	s8,16(sp)
    80001ec8:	e466                	sd	s9,8(sp)
    80001eca:	e06a                	sd	s10,0(sp)
    80001ecc:	1080                	addi	s0,sp,96
    80001ece:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed2:	00779b93          	slli	s7,a5,0x7
    80001ed6:	0000f717          	auipc	a4,0xf
    80001eda:	c7a70713          	addi	a4,a4,-902 # 80010b50 <pid_lock>
    80001ede:	975e                	add	a4,a4,s7
    80001ee0:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);          
    80001ee4:	0000f717          	auipc	a4,0xf
    80001ee8:	ca470713          	addi	a4,a4,-860 # 80010b88 <cpus+0x8>
    80001eec:	9bba                	add	s7,s7,a4
          p->state = RUNNING;
    80001eee:	4c11                	li	s8,4
          c->proc = p;
    80001ef0:	079e                	slli	a5,a5,0x7
    80001ef2:	0000fb17          	auipc	s6,0xf
    80001ef6:	c5eb0b13          	addi	s6,s6,-930 # 80010b50 <pid_lock>
    80001efa:	9b3e                	add	s6,s6,a5
      for(p = proc; p < &proc[NPROC]; p++){
    80001efc:	00015917          	auipc	s2,0x15
    80001f00:	c8490913          	addi	s2,s2,-892 # 80016b80 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0c:	10079073          	csrw	sstatus,a5
    uint i = 0;
    80001f10:	4a81                	li	s5,0
        if(p->state == RUNNABLE && p->priority == i){
    80001f12:	4a0d                	li	s4,3
    80001f14:	a049                	j	80001f96 <scheduler+0xe4>
          else if(p->priority < NPRIO-1) {
    80001f16:	06fcf363          	bgeu	s9,a5,80001f7c <scheduler+0xca>
          c->proc = 0;              
    80001f1a:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d6a080e7          	jalr	-662(ra) # 80000c8a <release>
      for(p = proc; p < &proc[NPROC]; p++){
    80001f28:	17048493          	addi	s1,s1,368
    80001f2c:	05248c63          	beq	s1,s2,80001f84 <scheduler+0xd2>
        acquire(&p->lock);
    80001f30:	8526                	mv	a0,s1
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	ca4080e7          	jalr	-860(ra) # 80000bd6 <acquire>
        if(p->state == RUNNABLE && p->priority == i){
    80001f3a:	4c9c                	lw	a5,24(s1)
    80001f3c:	ff4791e3          	bne	a5,s4,80001f1e <scheduler+0x6c>
    80001f40:	1684a783          	lw	a5,360(s1)
    80001f44:	fd579de3          	bne	a5,s5,80001f1e <scheduler+0x6c>
          p->chosen++;          
    80001f48:	16c4a783          	lw	a5,364(s1)
    80001f4c:	2785                	addiw	a5,a5,1
    80001f4e:	16f4a623          	sw	a5,364(s1)
          p->state = RUNNING;
    80001f52:	0184ac23          	sw	s8,24(s1)
          c->proc = p;
    80001f56:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);          
    80001f5a:	06048593          	addi	a1,s1,96
    80001f5e:	855e                	mv	a0,s7
    80001f60:	00000097          	auipc	ra,0x0
    80001f64:	6d4080e7          	jalr	1748(ra) # 80002634 <swtch>
          if(p->priority > 0 && p->state == SLEEPING) {
    80001f68:	1684a783          	lw	a5,360(s1)
    80001f6c:	cb81                	beqz	a5,80001f7c <scheduler+0xca>
    80001f6e:	4c98                	lw	a4,24(s1)
    80001f70:	fba713e3          	bne	a4,s10,80001f16 <scheduler+0x64>
            p->priority--;
    80001f74:	37fd                	addiw	a5,a5,-1
    80001f76:	16f4a423          	sw	a5,360(s1)
    80001f7a:	b745                	j	80001f1a <scheduler+0x68>
            p->priority++;
    80001f7c:	2785                	addiw	a5,a5,1
    80001f7e:	16f4a423          	sw	a5,360(s1)
    80001f82:	bf61                	j	80001f1a <scheduler+0x68>
      i++;
    80001f84:	2a85                	addiw	s5,s5,1
      if(ticks%16==0){
    80001f86:	00007797          	auipc	a5,0x7
    80001f8a:	95a7a783          	lw	a5,-1702(a5) # 800088e0 <ticks>
    80001f8e:	8bbd                	andi	a5,a5,15
    80001f90:	cb91                	beqz	a5,80001fa4 <scheduler+0xf2>
    while(i < NPRIO){      
    80001f92:	f74a89e3          	beq	s5,s4,80001f04 <scheduler+0x52>
      for(p = proc; p < &proc[NPROC]; p++){
    80001f96:	0000f497          	auipc	s1,0xf
    80001f9a:	fea48493          	addi	s1,s1,-22 # 80010f80 <proc>
          if(p->priority > 0 && p->state == SLEEPING) {
    80001f9e:	4d09                	li	s10,2
          else if(p->priority < NPRIO-1) {
    80001fa0:	4c85                	li	s9,1
    80001fa2:	b779                	j	80001f30 <scheduler+0x7e>
        for(p = proc; p < &proc[NPROC]; p++) {
    80001fa4:	0000f797          	auipc	a5,0xf
    80001fa8:	fdc78793          	addi	a5,a5,-36 # 80010f80 <proc>
          p->priority = 0;
    80001fac:	1607a423          	sw	zero,360(a5)
        for(p = proc; p < &proc[NPROC]; p++) {
    80001fb0:	17078793          	addi	a5,a5,368
    80001fb4:	ff279ce3          	bne	a5,s2,80001fac <scheduler+0xfa>
    80001fb8:	bfe9                	j	80001f92 <scheduler+0xe0>

0000000080001fba <sched>:
{
    80001fba:	7179                	addi	sp,sp,-48
    80001fbc:	f406                	sd	ra,40(sp)
    80001fbe:	f022                	sd	s0,32(sp)
    80001fc0:	ec26                	sd	s1,24(sp)
    80001fc2:	e84a                	sd	s2,16(sp)
    80001fc4:	e44e                	sd	s3,8(sp)
    80001fc6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc8:	00000097          	auipc	ra,0x0
    80001fcc:	9ec080e7          	jalr	-1556(ra) # 800019b4 <myproc>
    80001fd0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	b8a080e7          	jalr	-1142(ra) # 80000b5c <holding>
    80001fda:	c93d                	beqz	a0,80002050 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fdc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fde:	2781                	sext.w	a5,a5
    80001fe0:	079e                	slli	a5,a5,0x7
    80001fe2:	0000f717          	auipc	a4,0xf
    80001fe6:	b6e70713          	addi	a4,a4,-1170 # 80010b50 <pid_lock>
    80001fea:	97ba                	add	a5,a5,a4
    80001fec:	0a87a703          	lw	a4,168(a5)
    80001ff0:	4785                	li	a5,1
    80001ff2:	06f71763          	bne	a4,a5,80002060 <sched+0xa6>
  if(p->state == RUNNING)
    80001ff6:	4c98                	lw	a4,24(s1)
    80001ff8:	4791                	li	a5,4
    80001ffa:	06f70b63          	beq	a4,a5,80002070 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002002:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002004:	efb5                	bnez	a5,80002080 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002006:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002008:	0000f917          	auipc	s2,0xf
    8000200c:	b4890913          	addi	s2,s2,-1208 # 80010b50 <pid_lock>
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	97ca                	add	a5,a5,s2
    80002016:	0ac7a983          	lw	s3,172(a5)
    8000201a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000201c:	2781                	sext.w	a5,a5
    8000201e:	079e                	slli	a5,a5,0x7
    80002020:	0000f597          	auipc	a1,0xf
    80002024:	b6858593          	addi	a1,a1,-1176 # 80010b88 <cpus+0x8>
    80002028:	95be                	add	a1,a1,a5
    8000202a:	06048513          	addi	a0,s1,96
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	606080e7          	jalr	1542(ra) # 80002634 <swtch>
    80002036:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002038:	2781                	sext.w	a5,a5
    8000203a:	079e                	slli	a5,a5,0x7
    8000203c:	993e                	add	s2,s2,a5
    8000203e:	0b392623          	sw	s3,172(s2)
}
    80002042:	70a2                	ld	ra,40(sp)
    80002044:	7402                	ld	s0,32(sp)
    80002046:	64e2                	ld	s1,24(sp)
    80002048:	6942                	ld	s2,16(sp)
    8000204a:	69a2                	ld	s3,8(sp)
    8000204c:	6145                	addi	sp,sp,48
    8000204e:	8082                	ret
    panic("sched p->lock");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1c850513          	addi	a0,a0,456 # 80008218 <digits+0x1d8>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4e8080e7          	jalr	1256(ra) # 80000540 <panic>
    panic("sched locks");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1c850513          	addi	a0,a0,456 # 80008228 <digits+0x1e8>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4d8080e7          	jalr	1240(ra) # 80000540 <panic>
    panic("sched running");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1c850513          	addi	a0,a0,456 # 80008238 <digits+0x1f8>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4c8080e7          	jalr	1224(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	1c850513          	addi	a0,a0,456 # 80008248 <digits+0x208>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4b8080e7          	jalr	1208(ra) # 80000540 <panic>

0000000080002090 <yield>:
{
    80002090:	1101                	addi	sp,sp,-32
    80002092:	ec06                	sd	ra,24(sp)
    80002094:	e822                	sd	s0,16(sp)
    80002096:	e426                	sd	s1,8(sp)
    80002098:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	91a080e7          	jalr	-1766(ra) # 800019b4 <myproc>
    800020a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b32080e7          	jalr	-1230(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020ac:	478d                	li	a5,3
    800020ae:	cc9c                	sw	a5,24(s1)
  sched();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	f0a080e7          	jalr	-246(ra) # 80001fba <sched>
  release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bd0080e7          	jalr	-1072(ra) # 80000c8a <release>
}
    800020c2:	60e2                	ld	ra,24(sp)
    800020c4:	6442                	ld	s0,16(sp)
    800020c6:	64a2                	ld	s1,8(sp)
    800020c8:	6105                	addi	sp,sp,32
    800020ca:	8082                	ret

00000000800020cc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020cc:	7179                	addi	sp,sp,-48
    800020ce:	f406                	sd	ra,40(sp)
    800020d0:	f022                	sd	s0,32(sp)
    800020d2:	ec26                	sd	s1,24(sp)
    800020d4:	e84a                	sd	s2,16(sp)
    800020d6:	e44e                	sd	s3,8(sp)
    800020d8:	1800                	addi	s0,sp,48
    800020da:	89aa                	mv	s3,a0
    800020dc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	8d6080e7          	jalr	-1834(ra) # 800019b4 <myproc>
    800020e6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	aee080e7          	jalr	-1298(ra) # 80000bd6 <acquire>
  release(lk);
    800020f0:	854a                	mv	a0,s2
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	b98080e7          	jalr	-1128(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020fa:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020fe:	4789                	li	a5,2
    80002100:	cc9c                	sw	a5,24(s1)

  sched();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	eb8080e7          	jalr	-328(ra) # 80001fba <sched>

  // Tidy up.
  p->chan = 0;
    8000210a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	b7a080e7          	jalr	-1158(ra) # 80000c8a <release>
  acquire(lk);
    80002118:	854a                	mv	a0,s2
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	abc080e7          	jalr	-1348(ra) # 80000bd6 <acquire>
}
    80002122:	70a2                	ld	ra,40(sp)
    80002124:	7402                	ld	s0,32(sp)
    80002126:	64e2                	ld	s1,24(sp)
    80002128:	6942                	ld	s2,16(sp)
    8000212a:	69a2                	ld	s3,8(sp)
    8000212c:	6145                	addi	sp,sp,48
    8000212e:	8082                	ret

0000000080002130 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002130:	7139                	addi	sp,sp,-64
    80002132:	fc06                	sd	ra,56(sp)
    80002134:	f822                	sd	s0,48(sp)
    80002136:	f426                	sd	s1,40(sp)
    80002138:	f04a                	sd	s2,32(sp)
    8000213a:	ec4e                	sd	s3,24(sp)
    8000213c:	e852                	sd	s4,16(sp)
    8000213e:	e456                	sd	s5,8(sp)
    80002140:	0080                	addi	s0,sp,64
    80002142:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002144:	0000f497          	auipc	s1,0xf
    80002148:	e3c48493          	addi	s1,s1,-452 # 80010f80 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000214c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000214e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002150:	00015917          	auipc	s2,0x15
    80002154:	a3090913          	addi	s2,s2,-1488 # 80016b80 <tickslock>
    80002158:	a811                	j	8000216c <wakeup+0x3c>
      }
      release(&p->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002164:	17048493          	addi	s1,s1,368
    80002168:	03248663          	beq	s1,s2,80002194 <wakeup+0x64>
    if(p != myproc()){
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	848080e7          	jalr	-1976(ra) # 800019b4 <myproc>
    80002174:	fea488e3          	beq	s1,a0,80002164 <wakeup+0x34>
      acquire(&p->lock);
    80002178:	8526                	mv	a0,s1
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	a5c080e7          	jalr	-1444(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002182:	4c9c                	lw	a5,24(s1)
    80002184:	fd379be3          	bne	a5,s3,8000215a <wakeup+0x2a>
    80002188:	709c                	ld	a5,32(s1)
    8000218a:	fd4798e3          	bne	a5,s4,8000215a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000218e:	0154ac23          	sw	s5,24(s1)
    80002192:	b7e1                	j	8000215a <wakeup+0x2a>
    }
  }
}
    80002194:	70e2                	ld	ra,56(sp)
    80002196:	7442                	ld	s0,48(sp)
    80002198:	74a2                	ld	s1,40(sp)
    8000219a:	7902                	ld	s2,32(sp)
    8000219c:	69e2                	ld	s3,24(sp)
    8000219e:	6a42                	ld	s4,16(sp)
    800021a0:	6aa2                	ld	s5,8(sp)
    800021a2:	6121                	addi	sp,sp,64
    800021a4:	8082                	ret

00000000800021a6 <reparent>:
{
    800021a6:	7179                	addi	sp,sp,-48
    800021a8:	f406                	sd	ra,40(sp)
    800021aa:	f022                	sd	s0,32(sp)
    800021ac:	ec26                	sd	s1,24(sp)
    800021ae:	e84a                	sd	s2,16(sp)
    800021b0:	e44e                	sd	s3,8(sp)
    800021b2:	e052                	sd	s4,0(sp)
    800021b4:	1800                	addi	s0,sp,48
    800021b6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b8:	0000f497          	auipc	s1,0xf
    800021bc:	dc848493          	addi	s1,s1,-568 # 80010f80 <proc>
      pp->parent = initproc;
    800021c0:	00006a17          	auipc	s4,0x6
    800021c4:	718a0a13          	addi	s4,s4,1816 # 800088d8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021c8:	00015997          	auipc	s3,0x15
    800021cc:	9b898993          	addi	s3,s3,-1608 # 80016b80 <tickslock>
    800021d0:	a029                	j	800021da <reparent+0x34>
    800021d2:	17048493          	addi	s1,s1,368
    800021d6:	01348d63          	beq	s1,s3,800021f0 <reparent+0x4a>
    if(pp->parent == p){
    800021da:	7c9c                	ld	a5,56(s1)
    800021dc:	ff279be3          	bne	a5,s2,800021d2 <reparent+0x2c>
      pp->parent = initproc;
    800021e0:	000a3503          	ld	a0,0(s4)
    800021e4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	f4a080e7          	jalr	-182(ra) # 80002130 <wakeup>
    800021ee:	b7d5                	j	800021d2 <reparent+0x2c>
}
    800021f0:	70a2                	ld	ra,40(sp)
    800021f2:	7402                	ld	s0,32(sp)
    800021f4:	64e2                	ld	s1,24(sp)
    800021f6:	6942                	ld	s2,16(sp)
    800021f8:	69a2                	ld	s3,8(sp)
    800021fa:	6a02                	ld	s4,0(sp)
    800021fc:	6145                	addi	sp,sp,48
    800021fe:	8082                	ret

0000000080002200 <exit>:
{
    80002200:	7179                	addi	sp,sp,-48
    80002202:	f406                	sd	ra,40(sp)
    80002204:	f022                	sd	s0,32(sp)
    80002206:	ec26                	sd	s1,24(sp)
    80002208:	e84a                	sd	s2,16(sp)
    8000220a:	e44e                	sd	s3,8(sp)
    8000220c:	e052                	sd	s4,0(sp)
    8000220e:	1800                	addi	s0,sp,48
    80002210:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	7a2080e7          	jalr	1954(ra) # 800019b4 <myproc>
    8000221a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000221c:	00006797          	auipc	a5,0x6
    80002220:	6bc7b783          	ld	a5,1724(a5) # 800088d8 <initproc>
    80002224:	0d050493          	addi	s1,a0,208
    80002228:	15050913          	addi	s2,a0,336
    8000222c:	02a79363          	bne	a5,a0,80002252 <exit+0x52>
    panic("init exiting");
    80002230:	00006517          	auipc	a0,0x6
    80002234:	03050513          	addi	a0,a0,48 # 80008260 <digits+0x220>
    80002238:	ffffe097          	auipc	ra,0xffffe
    8000223c:	308080e7          	jalr	776(ra) # 80000540 <panic>
      fileclose(f);
    80002240:	00002097          	auipc	ra,0x2
    80002244:	2fc080e7          	jalr	764(ra) # 8000453c <fileclose>
      p->ofile[fd] = 0;
    80002248:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000224c:	04a1                	addi	s1,s1,8
    8000224e:	01248563          	beq	s1,s2,80002258 <exit+0x58>
    if(p->ofile[fd]){
    80002252:	6088                	ld	a0,0(s1)
    80002254:	f575                	bnez	a0,80002240 <exit+0x40>
    80002256:	bfdd                	j	8000224c <exit+0x4c>
  begin_op();
    80002258:	00002097          	auipc	ra,0x2
    8000225c:	e1c080e7          	jalr	-484(ra) # 80004074 <begin_op>
  iput(p->cwd);
    80002260:	1509b503          	ld	a0,336(s3)
    80002264:	00001097          	auipc	ra,0x1
    80002268:	5fe080e7          	jalr	1534(ra) # 80003862 <iput>
  end_op();
    8000226c:	00002097          	auipc	ra,0x2
    80002270:	e86080e7          	jalr	-378(ra) # 800040f2 <end_op>
  p->cwd = 0;
    80002274:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002278:	0000f497          	auipc	s1,0xf
    8000227c:	8f048493          	addi	s1,s1,-1808 # 80010b68 <wait_lock>
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	954080e7          	jalr	-1708(ra) # 80000bd6 <acquire>
  reparent(p);
    8000228a:	854e                	mv	a0,s3
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	f1a080e7          	jalr	-230(ra) # 800021a6 <reparent>
  wakeup(p->parent);
    80002294:	0389b503          	ld	a0,56(s3)
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	e98080e7          	jalr	-360(ra) # 80002130 <wakeup>
  acquire(&p->lock);
    800022a0:	854e                	mv	a0,s3
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	934080e7          	jalr	-1740(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022aa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022ae:	4795                	li	a5,5
    800022b0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9d4080e7          	jalr	-1580(ra) # 80000c8a <release>
  sched();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	cfc080e7          	jalr	-772(ra) # 80001fba <sched>
  panic("zombie exit");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	faa50513          	addi	a0,a0,-86 # 80008270 <digits+0x230>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	272080e7          	jalr	626(ra) # 80000540 <panic>

00000000800022d6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022d6:	7179                	addi	sp,sp,-48
    800022d8:	f406                	sd	ra,40(sp)
    800022da:	f022                	sd	s0,32(sp)
    800022dc:	ec26                	sd	s1,24(sp)
    800022de:	e84a                	sd	s2,16(sp)
    800022e0:	e44e                	sd	s3,8(sp)
    800022e2:	1800                	addi	s0,sp,48
    800022e4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022e6:	0000f497          	auipc	s1,0xf
    800022ea:	c9a48493          	addi	s1,s1,-870 # 80010f80 <proc>
    800022ee:	00015997          	auipc	s3,0x15
    800022f2:	89298993          	addi	s3,s3,-1902 # 80016b80 <tickslock>
    acquire(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	8de080e7          	jalr	-1826(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002300:	589c                	lw	a5,48(s1)
    80002302:	01278d63          	beq	a5,s2,8000231c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	982080e7          	jalr	-1662(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002310:	17048493          	addi	s1,s1,368
    80002314:	ff3491e3          	bne	s1,s3,800022f6 <kill+0x20>
  }
  return -1;
    80002318:	557d                	li	a0,-1
    8000231a:	a829                	j	80002334 <kill+0x5e>
      p->killed = 1;
    8000231c:	4785                	li	a5,1
    8000231e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002320:	4c98                	lw	a4,24(s1)
    80002322:	4789                	li	a5,2
    80002324:	00f70f63          	beq	a4,a5,80002342 <kill+0x6c>
      release(&p->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	960080e7          	jalr	-1696(ra) # 80000c8a <release>
      return 0;
    80002332:	4501                	li	a0,0
}
    80002334:	70a2                	ld	ra,40(sp)
    80002336:	7402                	ld	s0,32(sp)
    80002338:	64e2                	ld	s1,24(sp)
    8000233a:	6942                	ld	s2,16(sp)
    8000233c:	69a2                	ld	s3,8(sp)
    8000233e:	6145                	addi	sp,sp,48
    80002340:	8082                	ret
        p->state = RUNNABLE;
    80002342:	478d                	li	a5,3
    80002344:	cc9c                	sw	a5,24(s1)
    80002346:	b7cd                	j	80002328 <kill+0x52>

0000000080002348 <setkilled>:

void
setkilled(struct proc *p)
{
    80002348:	1101                	addi	sp,sp,-32
    8000234a:	ec06                	sd	ra,24(sp)
    8000234c:	e822                	sd	s0,16(sp)
    8000234e:	e426                	sd	s1,8(sp)
    80002350:	1000                	addi	s0,sp,32
    80002352:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	882080e7          	jalr	-1918(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000235c:	4785                	li	a5,1
    8000235e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
}
    8000236a:	60e2                	ld	ra,24(sp)
    8000236c:	6442                	ld	s0,16(sp)
    8000236e:	64a2                	ld	s1,8(sp)
    80002370:	6105                	addi	sp,sp,32
    80002372:	8082                	ret

0000000080002374 <killed>:

int
killed(struct proc *p)
{
    80002374:	1101                	addi	sp,sp,-32
    80002376:	ec06                	sd	ra,24(sp)
    80002378:	e822                	sd	s0,16(sp)
    8000237a:	e426                	sd	s1,8(sp)
    8000237c:	e04a                	sd	s2,0(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	854080e7          	jalr	-1964(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000238a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	8fa080e7          	jalr	-1798(ra) # 80000c8a <release>
  return k;
}
    80002398:	854a                	mv	a0,s2
    8000239a:	60e2                	ld	ra,24(sp)
    8000239c:	6442                	ld	s0,16(sp)
    8000239e:	64a2                	ld	s1,8(sp)
    800023a0:	6902                	ld	s2,0(sp)
    800023a2:	6105                	addi	sp,sp,32
    800023a4:	8082                	ret

00000000800023a6 <wait>:
{
    800023a6:	715d                	addi	sp,sp,-80
    800023a8:	e486                	sd	ra,72(sp)
    800023aa:	e0a2                	sd	s0,64(sp)
    800023ac:	fc26                	sd	s1,56(sp)
    800023ae:	f84a                	sd	s2,48(sp)
    800023b0:	f44e                	sd	s3,40(sp)
    800023b2:	f052                	sd	s4,32(sp)
    800023b4:	ec56                	sd	s5,24(sp)
    800023b6:	e85a                	sd	s6,16(sp)
    800023b8:	e45e                	sd	s7,8(sp)
    800023ba:	e062                	sd	s8,0(sp)
    800023bc:	0880                	addi	s0,sp,80
    800023be:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	5f4080e7          	jalr	1524(ra) # 800019b4 <myproc>
    800023c8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ca:	0000e517          	auipc	a0,0xe
    800023ce:	79e50513          	addi	a0,a0,1950 # 80010b68 <wait_lock>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	804080e7          	jalr	-2044(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023da:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023dc:	4a15                	li	s4,5
        havekids = 1;
    800023de:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e0:	00014997          	auipc	s3,0x14
    800023e4:	7a098993          	addi	s3,s3,1952 # 80016b80 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023e8:	0000ec17          	auipc	s8,0xe
    800023ec:	780c0c13          	addi	s8,s8,1920 # 80010b68 <wait_lock>
    havekids = 0;
    800023f0:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f2:	0000f497          	auipc	s1,0xf
    800023f6:	b8e48493          	addi	s1,s1,-1138 # 80010f80 <proc>
    800023fa:	a0bd                	j	80002468 <wait+0xc2>
          pid = pp->pid;
    800023fc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002400:	000b0e63          	beqz	s6,8000241c <wait+0x76>
    80002404:	4691                	li	a3,4
    80002406:	02c48613          	addi	a2,s1,44
    8000240a:	85da                	mv	a1,s6
    8000240c:	05093503          	ld	a0,80(s2)
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	25c080e7          	jalr	604(ra) # 8000166c <copyout>
    80002418:	02054563          	bltz	a0,80002442 <wait+0x9c>
          freeproc(pp);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	748080e7          	jalr	1864(ra) # 80001b66 <freeproc>
          release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
          release(&wait_lock);
    80002430:	0000e517          	auipc	a0,0xe
    80002434:	73850513          	addi	a0,a0,1848 # 80010b68 <wait_lock>
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	852080e7          	jalr	-1966(ra) # 80000c8a <release>
          return pid;
    80002440:	a0b5                	j	800024ac <wait+0x106>
            release(&pp->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
            release(&wait_lock);
    8000244c:	0000e517          	auipc	a0,0xe
    80002450:	71c50513          	addi	a0,a0,1820 # 80010b68 <wait_lock>
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	836080e7          	jalr	-1994(ra) # 80000c8a <release>
            return -1;
    8000245c:	59fd                	li	s3,-1
    8000245e:	a0b9                	j	800024ac <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002460:	17048493          	addi	s1,s1,368
    80002464:	03348463          	beq	s1,s3,8000248c <wait+0xe6>
      if(pp->parent == p){
    80002468:	7c9c                	ld	a5,56(s1)
    8000246a:	ff279be3          	bne	a5,s2,80002460 <wait+0xba>
        acquire(&pp->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	766080e7          	jalr	1894(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002478:	4c9c                	lw	a5,24(s1)
    8000247a:	f94781e3          	beq	a5,s4,800023fc <wait+0x56>
        release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	80a080e7          	jalr	-2038(ra) # 80000c8a <release>
        havekids = 1;
    80002488:	8756                	mv	a4,s5
    8000248a:	bfd9                	j	80002460 <wait+0xba>
    if(!havekids || killed(p)){
    8000248c:	c719                	beqz	a4,8000249a <wait+0xf4>
    8000248e:	854a                	mv	a0,s2
    80002490:	00000097          	auipc	ra,0x0
    80002494:	ee4080e7          	jalr	-284(ra) # 80002374 <killed>
    80002498:	c51d                	beqz	a0,800024c6 <wait+0x120>
      release(&wait_lock);
    8000249a:	0000e517          	auipc	a0,0xe
    8000249e:	6ce50513          	addi	a0,a0,1742 # 80010b68 <wait_lock>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7e8080e7          	jalr	2024(ra) # 80000c8a <release>
      return -1;
    800024aa:	59fd                	li	s3,-1
}
    800024ac:	854e                	mv	a0,s3
    800024ae:	60a6                	ld	ra,72(sp)
    800024b0:	6406                	ld	s0,64(sp)
    800024b2:	74e2                	ld	s1,56(sp)
    800024b4:	7942                	ld	s2,48(sp)
    800024b6:	79a2                	ld	s3,40(sp)
    800024b8:	7a02                	ld	s4,32(sp)
    800024ba:	6ae2                	ld	s5,24(sp)
    800024bc:	6b42                	ld	s6,16(sp)
    800024be:	6ba2                	ld	s7,8(sp)
    800024c0:	6c02                	ld	s8,0(sp)
    800024c2:	6161                	addi	sp,sp,80
    800024c4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c6:	85e2                	mv	a1,s8
    800024c8:	854a                	mv	a0,s2
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	c02080e7          	jalr	-1022(ra) # 800020cc <sleep>
    havekids = 0;
    800024d2:	bf39                	j	800023f0 <wait+0x4a>

00000000800024d4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	e052                	sd	s4,0(sp)
    800024e2:	1800                	addi	s0,sp,48
    800024e4:	84aa                	mv	s1,a0
    800024e6:	892e                	mv	s2,a1
    800024e8:	89b2                	mv	s3,a2
    800024ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	4c8080e7          	jalr	1224(ra) # 800019b4 <myproc>
  if(user_dst){
    800024f4:	c08d                	beqz	s1,80002516 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024f6:	86d2                	mv	a3,s4
    800024f8:	864e                	mv	a2,s3
    800024fa:	85ca                	mv	a1,s2
    800024fc:	6928                	ld	a0,80(a0)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	16e080e7          	jalr	366(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002506:	70a2                	ld	ra,40(sp)
    80002508:	7402                	ld	s0,32(sp)
    8000250a:	64e2                	ld	s1,24(sp)
    8000250c:	6942                	ld	s2,16(sp)
    8000250e:	69a2                	ld	s3,8(sp)
    80002510:	6a02                	ld	s4,0(sp)
    80002512:	6145                	addi	sp,sp,48
    80002514:	8082                	ret
    memmove((char *)dst, src, len);
    80002516:	000a061b          	sext.w	a2,s4
    8000251a:	85ce                	mv	a1,s3
    8000251c:	854a                	mv	a0,s2
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	810080e7          	jalr	-2032(ra) # 80000d2e <memmove>
    return 0;
    80002526:	8526                	mv	a0,s1
    80002528:	bff9                	j	80002506 <either_copyout+0x32>

000000008000252a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	e052                	sd	s4,0(sp)
    80002538:	1800                	addi	s0,sp,48
    8000253a:	892a                	mv	s2,a0
    8000253c:	84ae                	mv	s1,a1
    8000253e:	89b2                	mv	s3,a2
    80002540:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	472080e7          	jalr	1138(ra) # 800019b4 <myproc>
  if(user_src){
    8000254a:	c08d                	beqz	s1,8000256c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000254c:	86d2                	mv	a3,s4
    8000254e:	864e                	mv	a2,s3
    80002550:	85ca                	mv	a1,s2
    80002552:	6928                	ld	a0,80(a0)
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	1a4080e7          	jalr	420(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000255c:	70a2                	ld	ra,40(sp)
    8000255e:	7402                	ld	s0,32(sp)
    80002560:	64e2                	ld	s1,24(sp)
    80002562:	6942                	ld	s2,16(sp)
    80002564:	69a2                	ld	s3,8(sp)
    80002566:	6a02                	ld	s4,0(sp)
    80002568:	6145                	addi	sp,sp,48
    8000256a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000256c:	000a061b          	sext.w	a2,s4
    80002570:	85ce                	mv	a1,s3
    80002572:	854a                	mv	a0,s2
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	7ba080e7          	jalr	1978(ra) # 80000d2e <memmove>
    return 0;
    8000257c:	8526                	mv	a0,s1
    8000257e:	bff9                	j	8000255c <either_copyin+0x32>

0000000080002580 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002580:	715d                	addi	sp,sp,-80
    80002582:	e486                	sd	ra,72(sp)
    80002584:	e0a2                	sd	s0,64(sp)
    80002586:	fc26                	sd	s1,56(sp)
    80002588:	f84a                	sd	s2,48(sp)
    8000258a:	f44e                	sd	s3,40(sp)
    8000258c:	f052                	sd	s4,32(sp)
    8000258e:	ec56                	sd	s5,24(sp)
    80002590:	e85a                	sd	s6,16(sp)
    80002592:	e45e                	sd	s7,8(sp)
    80002594:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002596:	00006517          	auipc	a0,0x6
    8000259a:	b3250513          	addi	a0,a0,-1230 # 800080c8 <digits+0x88>
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	fec080e7          	jalr	-20(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a6:	0000f497          	auipc	s1,0xf
    800025aa:	b3248493          	addi	s1,s1,-1230 # 800110d8 <proc+0x158>
    800025ae:	00014917          	auipc	s2,0x14
    800025b2:	72a90913          	addi	s2,s2,1834 # 80016cd8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025b8:	00006997          	auipc	s3,0x6
    800025bc:	cc898993          	addi	s3,s3,-824 # 80008280 <digits+0x240>
    printf("%d %d %d %s %s",p->priority, p->chosen, p->pid, state, p->name);
    800025c0:	00006a97          	auipc	s5,0x6
    800025c4:	cc8a8a93          	addi	s5,s5,-824 # 80008288 <digits+0x248>
    printf("\n");
    800025c8:	00006a17          	auipc	s4,0x6
    800025cc:	b00a0a13          	addi	s4,s4,-1280 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d0:	00006b97          	auipc	s7,0x6
    800025d4:	cf8b8b93          	addi	s7,s7,-776 # 800082c8 <states.0>
    800025d8:	a01d                	j	800025fe <procdump+0x7e>
    printf("%d %d %d %s %s",p->priority, p->chosen, p->pid, state, p->name);
    800025da:	ed87a683          	lw	a3,-296(a5)
    800025de:	4bd0                	lw	a2,20(a5)
    800025e0:	4b8c                	lw	a1,16(a5)
    800025e2:	8556                	mv	a0,s5
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	fa6080e7          	jalr	-90(ra) # 8000058a <printf>
    printf("\n");
    800025ec:	8552                	mv	a0,s4
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	f9c080e7          	jalr	-100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f6:	17048493          	addi	s1,s1,368
    800025fa:	03248263          	beq	s1,s2,8000261e <procdump+0x9e>
    if(p->state == UNUSED)
    800025fe:	87a6                	mv	a5,s1
    80002600:	ec04a683          	lw	a3,-320(s1)
    80002604:	daed                	beqz	a3,800025f6 <procdump+0x76>
      state = "???";
    80002606:	874e                	mv	a4,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	fcdb69e3          	bltu	s6,a3,800025da <procdump+0x5a>
    8000260c:	02069713          	slli	a4,a3,0x20
    80002610:	01d75693          	srli	a3,a4,0x1d
    80002614:	96de                	add	a3,a3,s7
    80002616:	6298                	ld	a4,0(a3)
    80002618:	f369                	bnez	a4,800025da <procdump+0x5a>
      state = "???";
    8000261a:	874e                	mv	a4,s3
    8000261c:	bf7d                	j	800025da <procdump+0x5a>
  }
}
    8000261e:	60a6                	ld	ra,72(sp)
    80002620:	6406                	ld	s0,64(sp)
    80002622:	74e2                	ld	s1,56(sp)
    80002624:	7942                	ld	s2,48(sp)
    80002626:	79a2                	ld	s3,40(sp)
    80002628:	7a02                	ld	s4,32(sp)
    8000262a:	6ae2                	ld	s5,24(sp)
    8000262c:	6b42                	ld	s6,16(sp)
    8000262e:	6ba2                	ld	s7,8(sp)
    80002630:	6161                	addi	sp,sp,80
    80002632:	8082                	ret

0000000080002634 <swtch>:
    80002634:	00153023          	sd	ra,0(a0)
    80002638:	00253423          	sd	sp,8(a0)
    8000263c:	e900                	sd	s0,16(a0)
    8000263e:	ed04                	sd	s1,24(a0)
    80002640:	03253023          	sd	s2,32(a0)
    80002644:	03353423          	sd	s3,40(a0)
    80002648:	03453823          	sd	s4,48(a0)
    8000264c:	03553c23          	sd	s5,56(a0)
    80002650:	05653023          	sd	s6,64(a0)
    80002654:	05753423          	sd	s7,72(a0)
    80002658:	05853823          	sd	s8,80(a0)
    8000265c:	05953c23          	sd	s9,88(a0)
    80002660:	07a53023          	sd	s10,96(a0)
    80002664:	07b53423          	sd	s11,104(a0)
    80002668:	0005b083          	ld	ra,0(a1)
    8000266c:	0085b103          	ld	sp,8(a1)
    80002670:	6980                	ld	s0,16(a1)
    80002672:	6d84                	ld	s1,24(a1)
    80002674:	0205b903          	ld	s2,32(a1)
    80002678:	0285b983          	ld	s3,40(a1)
    8000267c:	0305ba03          	ld	s4,48(a1)
    80002680:	0385ba83          	ld	s5,56(a1)
    80002684:	0405bb03          	ld	s6,64(a1)
    80002688:	0485bb83          	ld	s7,72(a1)
    8000268c:	0505bc03          	ld	s8,80(a1)
    80002690:	0585bc83          	ld	s9,88(a1)
    80002694:	0605bd03          	ld	s10,96(a1)
    80002698:	0685bd83          	ld	s11,104(a1)
    8000269c:	8082                	ret

000000008000269e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000269e:	1141                	addi	sp,sp,-16
    800026a0:	e406                	sd	ra,8(sp)
    800026a2:	e022                	sd	s0,0(sp)
    800026a4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026a6:	00006597          	auipc	a1,0x6
    800026aa:	c5258593          	addi	a1,a1,-942 # 800082f8 <states.0+0x30>
    800026ae:	00014517          	auipc	a0,0x14
    800026b2:	4d250513          	addi	a0,a0,1234 # 80016b80 <tickslock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	490080e7          	jalr	1168(ra) # 80000b46 <initlock>
}
    800026be:	60a2                	ld	ra,8(sp)
    800026c0:	6402                	ld	s0,0(sp)
    800026c2:	0141                	addi	sp,sp,16
    800026c4:	8082                	ret

00000000800026c6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026c6:	1141                	addi	sp,sp,-16
    800026c8:	e422                	sd	s0,8(sp)
    800026ca:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026cc:	00003797          	auipc	a5,0x3
    800026d0:	4c478793          	addi	a5,a5,1220 # 80005b90 <kernelvec>
    800026d4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026d8:	6422                	ld	s0,8(sp)
    800026da:	0141                	addi	sp,sp,16
    800026dc:	8082                	ret

00000000800026de <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026de:	1141                	addi	sp,sp,-16
    800026e0:	e406                	sd	ra,8(sp)
    800026e2:	e022                	sd	s0,0(sp)
    800026e4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	2ce080e7          	jalr	718(ra) # 800019b4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026f2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026f4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026f8:	00005697          	auipc	a3,0x5
    800026fc:	90868693          	addi	a3,a3,-1784 # 80007000 <_trampoline>
    80002700:	00005717          	auipc	a4,0x5
    80002704:	90070713          	addi	a4,a4,-1792 # 80007000 <_trampoline>
    80002708:	8f15                	sub	a4,a4,a3
    8000270a:	040007b7          	lui	a5,0x4000
    8000270e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002710:	07b2                	slli	a5,a5,0xc
    80002712:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002714:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002718:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000271a:	18002673          	csrr	a2,satp
    8000271e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002720:	6d30                	ld	a2,88(a0)
    80002722:	6138                	ld	a4,64(a0)
    80002724:	6585                	lui	a1,0x1
    80002726:	972e                	add	a4,a4,a1
    80002728:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000272a:	6d38                	ld	a4,88(a0)
    8000272c:	00000617          	auipc	a2,0x0
    80002730:	13060613          	addi	a2,a2,304 # 8000285c <usertrap>
    80002734:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002736:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002738:	8612                	mv	a2,tp
    8000273a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000273c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002740:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002744:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002748:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000274c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000274e:	6f18                	ld	a4,24(a4)
    80002750:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002754:	6928                	ld	a0,80(a0)
    80002756:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002758:	00005717          	auipc	a4,0x5
    8000275c:	94470713          	addi	a4,a4,-1724 # 8000709c <userret>
    80002760:	8f15                	sub	a4,a4,a3
    80002762:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002764:	577d                	li	a4,-1
    80002766:	177e                	slli	a4,a4,0x3f
    80002768:	8d59                	or	a0,a0,a4
    8000276a:	9782                	jalr	a5
}
    8000276c:	60a2                	ld	ra,8(sp)
    8000276e:	6402                	ld	s0,0(sp)
    80002770:	0141                	addi	sp,sp,16
    80002772:	8082                	ret

0000000080002774 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002774:	1101                	addi	sp,sp,-32
    80002776:	ec06                	sd	ra,24(sp)
    80002778:	e822                	sd	s0,16(sp)
    8000277a:	e426                	sd	s1,8(sp)
    8000277c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000277e:	00014497          	auipc	s1,0x14
    80002782:	40248493          	addi	s1,s1,1026 # 80016b80 <tickslock>
    80002786:	8526                	mv	a0,s1
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	44e080e7          	jalr	1102(ra) # 80000bd6 <acquire>
  ticks++;
    80002790:	00006517          	auipc	a0,0x6
    80002794:	15050513          	addi	a0,a0,336 # 800088e0 <ticks>
    80002798:	411c                	lw	a5,0(a0)
    8000279a:	2785                	addiw	a5,a5,1
    8000279c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000279e:	00000097          	auipc	ra,0x0
    800027a2:	992080e7          	jalr	-1646(ra) # 80002130 <wakeup>
  release(&tickslock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	4e2080e7          	jalr	1250(ra) # 80000c8a <release>
}
    800027b0:	60e2                	ld	ra,24(sp)
    800027b2:	6442                	ld	s0,16(sp)
    800027b4:	64a2                	ld	s1,8(sp)
    800027b6:	6105                	addi	sp,sp,32
    800027b8:	8082                	ret

00000000800027ba <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ba:	1101                	addi	sp,sp,-32
    800027bc:	ec06                	sd	ra,24(sp)
    800027be:	e822                	sd	s0,16(sp)
    800027c0:	e426                	sd	s1,8(sp)
    800027c2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027c4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027c8:	00074d63          	bltz	a4,800027e2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027cc:	57fd                	li	a5,-1
    800027ce:	17fe                	slli	a5,a5,0x3f
    800027d0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027d2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027d4:	06f70363          	beq	a4,a5,8000283a <devintr+0x80>
  }
}
    800027d8:	60e2                	ld	ra,24(sp)
    800027da:	6442                	ld	s0,16(sp)
    800027dc:	64a2                	ld	s1,8(sp)
    800027de:	6105                	addi	sp,sp,32
    800027e0:	8082                	ret
     (scause & 0xff) == 9){
    800027e2:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027e6:	46a5                	li	a3,9
    800027e8:	fed792e3          	bne	a5,a3,800027cc <devintr+0x12>
    int irq = plic_claim();
    800027ec:	00003097          	auipc	ra,0x3
    800027f0:	4ac080e7          	jalr	1196(ra) # 80005c98 <plic_claim>
    800027f4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027f6:	47a9                	li	a5,10
    800027f8:	02f50763          	beq	a0,a5,80002826 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027fc:	4785                	li	a5,1
    800027fe:	02f50963          	beq	a0,a5,80002830 <devintr+0x76>
    return 1;
    80002802:	4505                	li	a0,1
    } else if(irq){
    80002804:	d8f1                	beqz	s1,800027d8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002806:	85a6                	mv	a1,s1
    80002808:	00006517          	auipc	a0,0x6
    8000280c:	af850513          	addi	a0,a0,-1288 # 80008300 <states.0+0x38>
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	d7a080e7          	jalr	-646(ra) # 8000058a <printf>
      plic_complete(irq);
    80002818:	8526                	mv	a0,s1
    8000281a:	00003097          	auipc	ra,0x3
    8000281e:	4a2080e7          	jalr	1186(ra) # 80005cbc <plic_complete>
    return 1;
    80002822:	4505                	li	a0,1
    80002824:	bf55                	j	800027d8 <devintr+0x1e>
      uartintr();
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	172080e7          	jalr	370(ra) # 80000998 <uartintr>
    8000282e:	b7ed                	j	80002818 <devintr+0x5e>
      virtio_disk_intr();
    80002830:	00004097          	auipc	ra,0x4
    80002834:	954080e7          	jalr	-1708(ra) # 80006184 <virtio_disk_intr>
    80002838:	b7c5                	j	80002818 <devintr+0x5e>
    if(cpuid() == 0){
    8000283a:	fffff097          	auipc	ra,0xfffff
    8000283e:	14e080e7          	jalr	334(ra) # 80001988 <cpuid>
    80002842:	c901                	beqz	a0,80002852 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002844:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002848:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000284a:	14479073          	csrw	sip,a5
    return 2;
    8000284e:	4509                	li	a0,2
    80002850:	b761                	j	800027d8 <devintr+0x1e>
      clockintr();
    80002852:	00000097          	auipc	ra,0x0
    80002856:	f22080e7          	jalr	-222(ra) # 80002774 <clockintr>
    8000285a:	b7ed                	j	80002844 <devintr+0x8a>

000000008000285c <usertrap>:
{
    8000285c:	1101                	addi	sp,sp,-32
    8000285e:	ec06                	sd	ra,24(sp)
    80002860:	e822                	sd	s0,16(sp)
    80002862:	e426                	sd	s1,8(sp)
    80002864:	e04a                	sd	s2,0(sp)
    80002866:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000286c:	1007f793          	andi	a5,a5,256
    80002870:	e3b1                	bnez	a5,800028b4 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002872:	00003797          	auipc	a5,0x3
    80002876:	31e78793          	addi	a5,a5,798 # 80005b90 <kernelvec>
    8000287a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	136080e7          	jalr	310(ra) # 800019b4 <myproc>
    80002886:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002888:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000288a:	14102773          	csrr	a4,sepc
    8000288e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002890:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002894:	47a1                	li	a5,8
    80002896:	02f70763          	beq	a4,a5,800028c4 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	f20080e7          	jalr	-224(ra) # 800027ba <devintr>
    800028a2:	892a                	mv	s2,a0
    800028a4:	c151                	beqz	a0,80002928 <usertrap+0xcc>
  if(killed(p))
    800028a6:	8526                	mv	a0,s1
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	acc080e7          	jalr	-1332(ra) # 80002374 <killed>
    800028b0:	c929                	beqz	a0,80002902 <usertrap+0xa6>
    800028b2:	a099                	j	800028f8 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028b4:	00006517          	auipc	a0,0x6
    800028b8:	a6c50513          	addi	a0,a0,-1428 # 80008320 <states.0+0x58>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	c84080e7          	jalr	-892(ra) # 80000540 <panic>
    if(killed(p))
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	ab0080e7          	jalr	-1360(ra) # 80002374 <killed>
    800028cc:	e921                	bnez	a0,8000291c <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028ce:	6cb8                	ld	a4,88(s1)
    800028d0:	6f1c                	ld	a5,24(a4)
    800028d2:	0791                	addi	a5,a5,4
    800028d4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028da:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028de:	10079073          	csrw	sstatus,a5
    syscall();
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	2d4080e7          	jalr	724(ra) # 80002bb6 <syscall>
  if(killed(p))
    800028ea:	8526                	mv	a0,s1
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	a88080e7          	jalr	-1400(ra) # 80002374 <killed>
    800028f4:	c911                	beqz	a0,80002908 <usertrap+0xac>
    800028f6:	4901                	li	s2,0
    exit(-1);
    800028f8:	557d                	li	a0,-1
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	906080e7          	jalr	-1786(ra) # 80002200 <exit>
  if(which_dev == 2)
    80002902:	4789                	li	a5,2
    80002904:	04f90f63          	beq	s2,a5,80002962 <usertrap+0x106>
  usertrapret();
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	dd6080e7          	jalr	-554(ra) # 800026de <usertrapret>
}
    80002910:	60e2                	ld	ra,24(sp)
    80002912:	6442                	ld	s0,16(sp)
    80002914:	64a2                	ld	s1,8(sp)
    80002916:	6902                	ld	s2,0(sp)
    80002918:	6105                	addi	sp,sp,32
    8000291a:	8082                	ret
      exit(-1);
    8000291c:	557d                	li	a0,-1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	8e2080e7          	jalr	-1822(ra) # 80002200 <exit>
    80002926:	b765                	j	800028ce <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000292c:	5890                	lw	a2,48(s1)
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	a1250513          	addi	a0,a0,-1518 # 80008340 <states.0+0x78>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c54080e7          	jalr	-940(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002942:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a2a50513          	addi	a0,a0,-1494 # 80008370 <states.0+0xa8>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c3c080e7          	jalr	-964(ra) # 8000058a <printf>
    setkilled(p);
    80002956:	8526                	mv	a0,s1
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	9f0080e7          	jalr	-1552(ra) # 80002348 <setkilled>
    80002960:	b769                	j	800028ea <usertrap+0x8e>
    yield();
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	72e080e7          	jalr	1838(ra) # 80002090 <yield>
    8000296a:	bf79                	j	80002908 <usertrap+0xac>

000000008000296c <kerneltrap>:
{
    8000296c:	7179                	addi	sp,sp,-48
    8000296e:	f406                	sd	ra,40(sp)
    80002970:	f022                	sd	s0,32(sp)
    80002972:	ec26                	sd	s1,24(sp)
    80002974:	e84a                	sd	s2,16(sp)
    80002976:	e44e                	sd	s3,8(sp)
    80002978:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002982:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002986:	1004f793          	andi	a5,s1,256
    8000298a:	cb85                	beqz	a5,800029ba <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000298c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002990:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002992:	ef85                	bnez	a5,800029ca <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002994:	00000097          	auipc	ra,0x0
    80002998:	e26080e7          	jalr	-474(ra) # 800027ba <devintr>
    8000299c:	cd1d                	beqz	a0,800029da <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000299e:	4789                	li	a5,2
    800029a0:	06f50a63          	beq	a0,a5,80002a14 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a8:	10049073          	csrw	sstatus,s1
}
    800029ac:	70a2                	ld	ra,40(sp)
    800029ae:	7402                	ld	s0,32(sp)
    800029b0:	64e2                	ld	s1,24(sp)
    800029b2:	6942                	ld	s2,16(sp)
    800029b4:	69a2                	ld	s3,8(sp)
    800029b6:	6145                	addi	sp,sp,48
    800029b8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ba:	00006517          	auipc	a0,0x6
    800029be:	9d650513          	addi	a0,a0,-1578 # 80008390 <states.0+0xc8>
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	b7e080e7          	jalr	-1154(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9ee50513          	addi	a0,a0,-1554 # 800083b8 <states.0+0xf0>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	b6e080e7          	jalr	-1170(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    800029da:	85ce                	mv	a1,s3
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	9fc50513          	addi	a0,a0,-1540 # 800083d8 <states.0+0x110>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	ba6080e7          	jalr	-1114(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	9f450513          	addi	a0,a0,-1548 # 800083e8 <states.0+0x120>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b8e080e7          	jalr	-1138(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	9fc50513          	addi	a0,a0,-1540 # 80008400 <states.0+0x138>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b34080e7          	jalr	-1228(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a14:	fffff097          	auipc	ra,0xfffff
    80002a18:	fa0080e7          	jalr	-96(ra) # 800019b4 <myproc>
    80002a1c:	d541                	beqz	a0,800029a4 <kerneltrap+0x38>
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	f96080e7          	jalr	-106(ra) # 800019b4 <myproc>
    80002a26:	4d18                	lw	a4,24(a0)
    80002a28:	4791                	li	a5,4
    80002a2a:	f6f71de3          	bne	a4,a5,800029a4 <kerneltrap+0x38>
    yield();
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	662080e7          	jalr	1634(ra) # 80002090 <yield>
    80002a36:	b7bd                	j	800029a4 <kerneltrap+0x38>

0000000080002a38 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a38:	1101                	addi	sp,sp,-32
    80002a3a:	ec06                	sd	ra,24(sp)
    80002a3c:	e822                	sd	s0,16(sp)
    80002a3e:	e426                	sd	s1,8(sp)
    80002a40:	1000                	addi	s0,sp,32
    80002a42:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	f70080e7          	jalr	-144(ra) # 800019b4 <myproc>
  switch (n) {
    80002a4c:	4795                	li	a5,5
    80002a4e:	0497e163          	bltu	a5,s1,80002a90 <argraw+0x58>
    80002a52:	048a                	slli	s1,s1,0x2
    80002a54:	00006717          	auipc	a4,0x6
    80002a58:	9e470713          	addi	a4,a4,-1564 # 80008438 <states.0+0x170>
    80002a5c:	94ba                	add	s1,s1,a4
    80002a5e:	409c                	lw	a5,0(s1)
    80002a60:	97ba                	add	a5,a5,a4
    80002a62:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a64:	6d3c                	ld	a5,88(a0)
    80002a66:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6105                	addi	sp,sp,32
    80002a70:	8082                	ret
    return p->trapframe->a1;
    80002a72:	6d3c                	ld	a5,88(a0)
    80002a74:	7fa8                	ld	a0,120(a5)
    80002a76:	bfcd                	j	80002a68 <argraw+0x30>
    return p->trapframe->a2;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	63c8                	ld	a0,128(a5)
    80002a7c:	b7f5                	j	80002a68 <argraw+0x30>
    return p->trapframe->a3;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	67c8                	ld	a0,136(a5)
    80002a82:	b7dd                	j	80002a68 <argraw+0x30>
    return p->trapframe->a4;
    80002a84:	6d3c                	ld	a5,88(a0)
    80002a86:	6bc8                	ld	a0,144(a5)
    80002a88:	b7c5                	j	80002a68 <argraw+0x30>
    return p->trapframe->a5;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	6fc8                	ld	a0,152(a5)
    80002a8e:	bfe9                	j	80002a68 <argraw+0x30>
  panic("argraw");
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	98050513          	addi	a0,a0,-1664 # 80008410 <states.0+0x148>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	aa8080e7          	jalr	-1368(ra) # 80000540 <panic>

0000000080002aa0 <fetchaddr>:
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	e04a                	sd	s2,0(sp)
    80002aaa:	1000                	addi	s0,sp,32
    80002aac:	84aa                	mv	s1,a0
    80002aae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	f04080e7          	jalr	-252(ra) # 800019b4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ab8:	653c                	ld	a5,72(a0)
    80002aba:	02f4f863          	bgeu	s1,a5,80002aea <fetchaddr+0x4a>
    80002abe:	00848713          	addi	a4,s1,8
    80002ac2:	02e7e663          	bltu	a5,a4,80002aee <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ac6:	46a1                	li	a3,8
    80002ac8:	8626                	mv	a2,s1
    80002aca:	85ca                	mv	a1,s2
    80002acc:	6928                	ld	a0,80(a0)
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	c2a080e7          	jalr	-982(ra) # 800016f8 <copyin>
    80002ad6:	00a03533          	snez	a0,a0
    80002ada:	40a00533          	neg	a0,a0
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6902                	ld	s2,0(sp)
    80002ae6:	6105                	addi	sp,sp,32
    80002ae8:	8082                	ret
    return -1;
    80002aea:	557d                	li	a0,-1
    80002aec:	bfcd                	j	80002ade <fetchaddr+0x3e>
    80002aee:	557d                	li	a0,-1
    80002af0:	b7fd                	j	80002ade <fetchaddr+0x3e>

0000000080002af2 <fetchstr>:
{
    80002af2:	7179                	addi	sp,sp,-48
    80002af4:	f406                	sd	ra,40(sp)
    80002af6:	f022                	sd	s0,32(sp)
    80002af8:	ec26                	sd	s1,24(sp)
    80002afa:	e84a                	sd	s2,16(sp)
    80002afc:	e44e                	sd	s3,8(sp)
    80002afe:	1800                	addi	s0,sp,48
    80002b00:	892a                	mv	s2,a0
    80002b02:	84ae                	mv	s1,a1
    80002b04:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	eae080e7          	jalr	-338(ra) # 800019b4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b0e:	86ce                	mv	a3,s3
    80002b10:	864a                	mv	a2,s2
    80002b12:	85a6                	mv	a1,s1
    80002b14:	6928                	ld	a0,80(a0)
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	c70080e7          	jalr	-912(ra) # 80001786 <copyinstr>
    80002b1e:	00054e63          	bltz	a0,80002b3a <fetchstr+0x48>
  return strlen(buf);
    80002b22:	8526                	mv	a0,s1
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	32a080e7          	jalr	810(ra) # 80000e4e <strlen>
}
    80002b2c:	70a2                	ld	ra,40(sp)
    80002b2e:	7402                	ld	s0,32(sp)
    80002b30:	64e2                	ld	s1,24(sp)
    80002b32:	6942                	ld	s2,16(sp)
    80002b34:	69a2                	ld	s3,8(sp)
    80002b36:	6145                	addi	sp,sp,48
    80002b38:	8082                	ret
    return -1;
    80002b3a:	557d                	li	a0,-1
    80002b3c:	bfc5                	j	80002b2c <fetchstr+0x3a>

0000000080002b3e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b3e:	1101                	addi	sp,sp,-32
    80002b40:	ec06                	sd	ra,24(sp)
    80002b42:	e822                	sd	s0,16(sp)
    80002b44:	e426                	sd	s1,8(sp)
    80002b46:	1000                	addi	s0,sp,32
    80002b48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	eee080e7          	jalr	-274(ra) # 80002a38 <argraw>
    80002b52:	c088                	sw	a0,0(s1)
}
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6105                	addi	sp,sp,32
    80002b5c:	8082                	ret

0000000080002b5e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b5e:	1101                	addi	sp,sp,-32
    80002b60:	ec06                	sd	ra,24(sp)
    80002b62:	e822                	sd	s0,16(sp)
    80002b64:	e426                	sd	s1,8(sp)
    80002b66:	1000                	addi	s0,sp,32
    80002b68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	ece080e7          	jalr	-306(ra) # 80002a38 <argraw>
    80002b72:	e088                	sd	a0,0(s1)
}
    80002b74:	60e2                	ld	ra,24(sp)
    80002b76:	6442                	ld	s0,16(sp)
    80002b78:	64a2                	ld	s1,8(sp)
    80002b7a:	6105                	addi	sp,sp,32
    80002b7c:	8082                	ret

0000000080002b7e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b7e:	7179                	addi	sp,sp,-48
    80002b80:	f406                	sd	ra,40(sp)
    80002b82:	f022                	sd	s0,32(sp)
    80002b84:	ec26                	sd	s1,24(sp)
    80002b86:	e84a                	sd	s2,16(sp)
    80002b88:	1800                	addi	s0,sp,48
    80002b8a:	84ae                	mv	s1,a1
    80002b8c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b8e:	fd840593          	addi	a1,s0,-40
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	fcc080e7          	jalr	-52(ra) # 80002b5e <argaddr>
  return fetchstr(addr, buf, max);
    80002b9a:	864a                	mv	a2,s2
    80002b9c:	85a6                	mv	a1,s1
    80002b9e:	fd843503          	ld	a0,-40(s0)
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	f50080e7          	jalr	-176(ra) # 80002af2 <fetchstr>
}
    80002baa:	70a2                	ld	ra,40(sp)
    80002bac:	7402                	ld	s0,32(sp)
    80002bae:	64e2                	ld	s1,24(sp)
    80002bb0:	6942                	ld	s2,16(sp)
    80002bb2:	6145                	addi	sp,sp,48
    80002bb4:	8082                	ret

0000000080002bb6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	e04a                	sd	s2,0(sp)
    80002bc0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	df2080e7          	jalr	-526(ra) # 800019b4 <myproc>
    80002bca:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bcc:	05853903          	ld	s2,88(a0)
    80002bd0:	0a893783          	ld	a5,168(s2)
    80002bd4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bd8:	37fd                	addiw	a5,a5,-1
    80002bda:	4751                	li	a4,20
    80002bdc:	00f76f63          	bltu	a4,a5,80002bfa <syscall+0x44>
    80002be0:	00369713          	slli	a4,a3,0x3
    80002be4:	00006797          	auipc	a5,0x6
    80002be8:	86c78793          	addi	a5,a5,-1940 # 80008450 <syscalls>
    80002bec:	97ba                	add	a5,a5,a4
    80002bee:	639c                	ld	a5,0(a5)
    80002bf0:	c789                	beqz	a5,80002bfa <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002bf2:	9782                	jalr	a5
    80002bf4:	06a93823          	sd	a0,112(s2)
    80002bf8:	a839                	j	80002c16 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bfa:	15848613          	addi	a2,s1,344
    80002bfe:	588c                	lw	a1,48(s1)
    80002c00:	00006517          	auipc	a0,0x6
    80002c04:	81850513          	addi	a0,a0,-2024 # 80008418 <states.0+0x150>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	982080e7          	jalr	-1662(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c10:	6cbc                	ld	a5,88(s1)
    80002c12:	577d                	li	a4,-1
    80002c14:	fbb8                	sd	a4,112(a5)
  }
}
    80002c16:	60e2                	ld	ra,24(sp)
    80002c18:	6442                	ld	s0,16(sp)
    80002c1a:	64a2                	ld	s1,8(sp)
    80002c1c:	6902                	ld	s2,0(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret

0000000080002c22 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c22:	1101                	addi	sp,sp,-32
    80002c24:	ec06                	sd	ra,24(sp)
    80002c26:	e822                	sd	s0,16(sp)
    80002c28:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c2a:	fec40593          	addi	a1,s0,-20
    80002c2e:	4501                	li	a0,0
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	f0e080e7          	jalr	-242(ra) # 80002b3e <argint>
  exit(n);
    80002c38:	fec42503          	lw	a0,-20(s0)
    80002c3c:	fffff097          	auipc	ra,0xfffff
    80002c40:	5c4080e7          	jalr	1476(ra) # 80002200 <exit>
  return 0;  // not reached
}
    80002c44:	4501                	li	a0,0
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret

0000000080002c4e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c4e:	1141                	addi	sp,sp,-16
    80002c50:	e406                	sd	ra,8(sp)
    80002c52:	e022                	sd	s0,0(sp)
    80002c54:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	d5e080e7          	jalr	-674(ra) # 800019b4 <myproc>
}
    80002c5e:	5908                	lw	a0,48(a0)
    80002c60:	60a2                	ld	ra,8(sp)
    80002c62:	6402                	ld	s0,0(sp)
    80002c64:	0141                	addi	sp,sp,16
    80002c66:	8082                	ret

0000000080002c68 <sys_fork>:

uint64
sys_fork(void)
{
    80002c68:	1141                	addi	sp,sp,-16
    80002c6a:	e406                	sd	ra,8(sp)
    80002c6c:	e022                	sd	s0,0(sp)
    80002c6e:	0800                	addi	s0,sp,16
  return fork();
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	102080e7          	jalr	258(ra) # 80001d72 <fork>
}
    80002c78:	60a2                	ld	ra,8(sp)
    80002c7a:	6402                	ld	s0,0(sp)
    80002c7c:	0141                	addi	sp,sp,16
    80002c7e:	8082                	ret

0000000080002c80 <sys_wait>:

uint64
sys_wait(void)
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c88:	fe840593          	addi	a1,s0,-24
    80002c8c:	4501                	li	a0,0
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	ed0080e7          	jalr	-304(ra) # 80002b5e <argaddr>
  return wait(p);
    80002c96:	fe843503          	ld	a0,-24(s0)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	70c080e7          	jalr	1804(ra) # 800023a6 <wait>
}
    80002ca2:	60e2                	ld	ra,24(sp)
    80002ca4:	6442                	ld	s0,16(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002caa:	7179                	addi	sp,sp,-48
    80002cac:	f406                	sd	ra,40(sp)
    80002cae:	f022                	sd	s0,32(sp)
    80002cb0:	ec26                	sd	s1,24(sp)
    80002cb2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cb4:	fdc40593          	addi	a1,s0,-36
    80002cb8:	4501                	li	a0,0
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	e84080e7          	jalr	-380(ra) # 80002b3e <argint>
  addr = myproc()->sz;
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	cf2080e7          	jalr	-782(ra) # 800019b4 <myproc>
    80002cca:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002ccc:	fdc42503          	lw	a0,-36(s0)
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	046080e7          	jalr	70(ra) # 80001d16 <growproc>
    80002cd8:	00054863          	bltz	a0,80002ce8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002cdc:	8526                	mv	a0,s1
    80002cde:	70a2                	ld	ra,40(sp)
    80002ce0:	7402                	ld	s0,32(sp)
    80002ce2:	64e2                	ld	s1,24(sp)
    80002ce4:	6145                	addi	sp,sp,48
    80002ce6:	8082                	ret
    return -1;
    80002ce8:	54fd                	li	s1,-1
    80002cea:	bfcd                	j	80002cdc <sys_sbrk+0x32>

0000000080002cec <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cec:	7139                	addi	sp,sp,-64
    80002cee:	fc06                	sd	ra,56(sp)
    80002cf0:	f822                	sd	s0,48(sp)
    80002cf2:	f426                	sd	s1,40(sp)
    80002cf4:	f04a                	sd	s2,32(sp)
    80002cf6:	ec4e                	sd	s3,24(sp)
    80002cf8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cfa:	fcc40593          	addi	a1,s0,-52
    80002cfe:	4501                	li	a0,0
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	e3e080e7          	jalr	-450(ra) # 80002b3e <argint>
  acquire(&tickslock);
    80002d08:	00014517          	auipc	a0,0x14
    80002d0c:	e7850513          	addi	a0,a0,-392 # 80016b80 <tickslock>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	ec6080e7          	jalr	-314(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d18:	00006917          	auipc	s2,0x6
    80002d1c:	bc892903          	lw	s2,-1080(s2) # 800088e0 <ticks>
  while(ticks - ticks0 < n){
    80002d20:	fcc42783          	lw	a5,-52(s0)
    80002d24:	cf9d                	beqz	a5,80002d62 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d26:	00014997          	auipc	s3,0x14
    80002d2a:	e5a98993          	addi	s3,s3,-422 # 80016b80 <tickslock>
    80002d2e:	00006497          	auipc	s1,0x6
    80002d32:	bb248493          	addi	s1,s1,-1102 # 800088e0 <ticks>
    if(killed(myproc())){
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	c7e080e7          	jalr	-898(ra) # 800019b4 <myproc>
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	636080e7          	jalr	1590(ra) # 80002374 <killed>
    80002d46:	ed15                	bnez	a0,80002d82 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d48:	85ce                	mv	a1,s3
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	380080e7          	jalr	896(ra) # 800020cc <sleep>
  while(ticks - ticks0 < n){
    80002d54:	409c                	lw	a5,0(s1)
    80002d56:	412787bb          	subw	a5,a5,s2
    80002d5a:	fcc42703          	lw	a4,-52(s0)
    80002d5e:	fce7ece3          	bltu	a5,a4,80002d36 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d62:	00014517          	auipc	a0,0x14
    80002d66:	e1e50513          	addi	a0,a0,-482 # 80016b80 <tickslock>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	f20080e7          	jalr	-224(ra) # 80000c8a <release>
  return 0;
    80002d72:	4501                	li	a0,0
}
    80002d74:	70e2                	ld	ra,56(sp)
    80002d76:	7442                	ld	s0,48(sp)
    80002d78:	74a2                	ld	s1,40(sp)
    80002d7a:	7902                	ld	s2,32(sp)
    80002d7c:	69e2                	ld	s3,24(sp)
    80002d7e:	6121                	addi	sp,sp,64
    80002d80:	8082                	ret
      release(&tickslock);
    80002d82:	00014517          	auipc	a0,0x14
    80002d86:	dfe50513          	addi	a0,a0,-514 # 80016b80 <tickslock>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	f00080e7          	jalr	-256(ra) # 80000c8a <release>
      return -1;
    80002d92:	557d                	li	a0,-1
    80002d94:	b7c5                	j	80002d74 <sys_sleep+0x88>

0000000080002d96 <sys_kill>:

uint64
sys_kill(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d9e:	fec40593          	addi	a1,s0,-20
    80002da2:	4501                	li	a0,0
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	d9a080e7          	jalr	-614(ra) # 80002b3e <argint>
  return kill(pid);
    80002dac:	fec42503          	lw	a0,-20(s0)
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	526080e7          	jalr	1318(ra) # 800022d6 <kill>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	e426                	sd	s1,8(sp)
    80002dc8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dca:	00014517          	auipc	a0,0x14
    80002dce:	db650513          	addi	a0,a0,-586 # 80016b80 <tickslock>
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	e04080e7          	jalr	-508(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002dda:	00006497          	auipc	s1,0x6
    80002dde:	b064a483          	lw	s1,-1274(s1) # 800088e0 <ticks>
  release(&tickslock);
    80002de2:	00014517          	auipc	a0,0x14
    80002de6:	d9e50513          	addi	a0,a0,-610 # 80016b80 <tickslock>
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	ea0080e7          	jalr	-352(ra) # 80000c8a <release>
  return xticks;
}
    80002df2:	02049513          	slli	a0,s1,0x20
    80002df6:	9101                	srli	a0,a0,0x20
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret

0000000080002e02 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e02:	7179                	addi	sp,sp,-48
    80002e04:	f406                	sd	ra,40(sp)
    80002e06:	f022                	sd	s0,32(sp)
    80002e08:	ec26                	sd	s1,24(sp)
    80002e0a:	e84a                	sd	s2,16(sp)
    80002e0c:	e44e                	sd	s3,8(sp)
    80002e0e:	e052                	sd	s4,0(sp)
    80002e10:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e12:	00005597          	auipc	a1,0x5
    80002e16:	6ee58593          	addi	a1,a1,1774 # 80008500 <syscalls+0xb0>
    80002e1a:	00014517          	auipc	a0,0x14
    80002e1e:	d7e50513          	addi	a0,a0,-642 # 80016b98 <bcache>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	d24080e7          	jalr	-732(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e2a:	0001c797          	auipc	a5,0x1c
    80002e2e:	d6e78793          	addi	a5,a5,-658 # 8001eb98 <bcache+0x8000>
    80002e32:	0001c717          	auipc	a4,0x1c
    80002e36:	fce70713          	addi	a4,a4,-50 # 8001ee00 <bcache+0x8268>
    80002e3a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e3e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e42:	00014497          	auipc	s1,0x14
    80002e46:	d6e48493          	addi	s1,s1,-658 # 80016bb0 <bcache+0x18>
    b->next = bcache.head.next;
    80002e4a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e4c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e4e:	00005a17          	auipc	s4,0x5
    80002e52:	6baa0a13          	addi	s4,s4,1722 # 80008508 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002e56:	2b893783          	ld	a5,696(s2)
    80002e5a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e5c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e60:	85d2                	mv	a1,s4
    80002e62:	01048513          	addi	a0,s1,16
    80002e66:	00001097          	auipc	ra,0x1
    80002e6a:	4c8080e7          	jalr	1224(ra) # 8000432e <initsleeplock>
    bcache.head.next->prev = b;
    80002e6e:	2b893783          	ld	a5,696(s2)
    80002e72:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e74:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e78:	45848493          	addi	s1,s1,1112
    80002e7c:	fd349de3          	bne	s1,s3,80002e56 <binit+0x54>
  }
}
    80002e80:	70a2                	ld	ra,40(sp)
    80002e82:	7402                	ld	s0,32(sp)
    80002e84:	64e2                	ld	s1,24(sp)
    80002e86:	6942                	ld	s2,16(sp)
    80002e88:	69a2                	ld	s3,8(sp)
    80002e8a:	6a02                	ld	s4,0(sp)
    80002e8c:	6145                	addi	sp,sp,48
    80002e8e:	8082                	ret

0000000080002e90 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	1800                	addi	s0,sp,48
    80002e9e:	892a                	mv	s2,a0
    80002ea0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	cf650513          	addi	a0,a0,-778 # 80016b98 <bcache>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	d2c080e7          	jalr	-724(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eb2:	0001c497          	auipc	s1,0x1c
    80002eb6:	f9e4b483          	ld	s1,-98(s1) # 8001ee50 <bcache+0x82b8>
    80002eba:	0001c797          	auipc	a5,0x1c
    80002ebe:	f4678793          	addi	a5,a5,-186 # 8001ee00 <bcache+0x8268>
    80002ec2:	02f48f63          	beq	s1,a5,80002f00 <bread+0x70>
    80002ec6:	873e                	mv	a4,a5
    80002ec8:	a021                	j	80002ed0 <bread+0x40>
    80002eca:	68a4                	ld	s1,80(s1)
    80002ecc:	02e48a63          	beq	s1,a4,80002f00 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ed0:	449c                	lw	a5,8(s1)
    80002ed2:	ff279ce3          	bne	a5,s2,80002eca <bread+0x3a>
    80002ed6:	44dc                	lw	a5,12(s1)
    80002ed8:	ff3799e3          	bne	a5,s3,80002eca <bread+0x3a>
      b->refcnt++;
    80002edc:	40bc                	lw	a5,64(s1)
    80002ede:	2785                	addiw	a5,a5,1
    80002ee0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ee2:	00014517          	auipc	a0,0x14
    80002ee6:	cb650513          	addi	a0,a0,-842 # 80016b98 <bcache>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	da0080e7          	jalr	-608(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ef2:	01048513          	addi	a0,s1,16
    80002ef6:	00001097          	auipc	ra,0x1
    80002efa:	472080e7          	jalr	1138(ra) # 80004368 <acquiresleep>
      return b;
    80002efe:	a8b9                	j	80002f5c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f00:	0001c497          	auipc	s1,0x1c
    80002f04:	f484b483          	ld	s1,-184(s1) # 8001ee48 <bcache+0x82b0>
    80002f08:	0001c797          	auipc	a5,0x1c
    80002f0c:	ef878793          	addi	a5,a5,-264 # 8001ee00 <bcache+0x8268>
    80002f10:	00f48863          	beq	s1,a5,80002f20 <bread+0x90>
    80002f14:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f16:	40bc                	lw	a5,64(s1)
    80002f18:	cf81                	beqz	a5,80002f30 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f1a:	64a4                	ld	s1,72(s1)
    80002f1c:	fee49de3          	bne	s1,a4,80002f16 <bread+0x86>
  panic("bget: no buffers");
    80002f20:	00005517          	auipc	a0,0x5
    80002f24:	5f050513          	addi	a0,a0,1520 # 80008510 <syscalls+0xc0>
    80002f28:	ffffd097          	auipc	ra,0xffffd
    80002f2c:	618080e7          	jalr	1560(ra) # 80000540 <panic>
      b->dev = dev;
    80002f30:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f34:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f38:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f3c:	4785                	li	a5,1
    80002f3e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f40:	00014517          	auipc	a0,0x14
    80002f44:	c5850513          	addi	a0,a0,-936 # 80016b98 <bcache>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d42080e7          	jalr	-702(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f50:	01048513          	addi	a0,s1,16
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	414080e7          	jalr	1044(ra) # 80004368 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f5c:	409c                	lw	a5,0(s1)
    80002f5e:	cb89                	beqz	a5,80002f70 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f60:	8526                	mv	a0,s1
    80002f62:	70a2                	ld	ra,40(sp)
    80002f64:	7402                	ld	s0,32(sp)
    80002f66:	64e2                	ld	s1,24(sp)
    80002f68:	6942                	ld	s2,16(sp)
    80002f6a:	69a2                	ld	s3,8(sp)
    80002f6c:	6145                	addi	sp,sp,48
    80002f6e:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f70:	4581                	li	a1,0
    80002f72:	8526                	mv	a0,s1
    80002f74:	00003097          	auipc	ra,0x3
    80002f78:	fde080e7          	jalr	-34(ra) # 80005f52 <virtio_disk_rw>
    b->valid = 1;
    80002f7c:	4785                	li	a5,1
    80002f7e:	c09c                	sw	a5,0(s1)
  return b;
    80002f80:	b7c5                	j	80002f60 <bread+0xd0>

0000000080002f82 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	e426                	sd	s1,8(sp)
    80002f8a:	1000                	addi	s0,sp,32
    80002f8c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f8e:	0541                	addi	a0,a0,16
    80002f90:	00001097          	auipc	ra,0x1
    80002f94:	472080e7          	jalr	1138(ra) # 80004402 <holdingsleep>
    80002f98:	cd01                	beqz	a0,80002fb0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f9a:	4585                	li	a1,1
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	00003097          	auipc	ra,0x3
    80002fa2:	fb4080e7          	jalr	-76(ra) # 80005f52 <virtio_disk_rw>
}
    80002fa6:	60e2                	ld	ra,24(sp)
    80002fa8:	6442                	ld	s0,16(sp)
    80002faa:	64a2                	ld	s1,8(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret
    panic("bwrite");
    80002fb0:	00005517          	auipc	a0,0x5
    80002fb4:	57850513          	addi	a0,a0,1400 # 80008528 <syscalls+0xd8>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	588080e7          	jalr	1416(ra) # 80000540 <panic>

0000000080002fc0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	e426                	sd	s1,8(sp)
    80002fc8:	e04a                	sd	s2,0(sp)
    80002fca:	1000                	addi	s0,sp,32
    80002fcc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fce:	01050913          	addi	s2,a0,16
    80002fd2:	854a                	mv	a0,s2
    80002fd4:	00001097          	auipc	ra,0x1
    80002fd8:	42e080e7          	jalr	1070(ra) # 80004402 <holdingsleep>
    80002fdc:	c92d                	beqz	a0,8000304e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fde:	854a                	mv	a0,s2
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	3de080e7          	jalr	990(ra) # 800043be <releasesleep>

  acquire(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	bb050513          	addi	a0,a0,-1104 # 80016b98 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	be6080e7          	jalr	-1050(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002ff8:	40bc                	lw	a5,64(s1)
    80002ffa:	37fd                	addiw	a5,a5,-1
    80002ffc:	0007871b          	sext.w	a4,a5
    80003000:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003002:	eb05                	bnez	a4,80003032 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003004:	68bc                	ld	a5,80(s1)
    80003006:	64b8                	ld	a4,72(s1)
    80003008:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000300a:	64bc                	ld	a5,72(s1)
    8000300c:	68b8                	ld	a4,80(s1)
    8000300e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003010:	0001c797          	auipc	a5,0x1c
    80003014:	b8878793          	addi	a5,a5,-1144 # 8001eb98 <bcache+0x8000>
    80003018:	2b87b703          	ld	a4,696(a5)
    8000301c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000301e:	0001c717          	auipc	a4,0x1c
    80003022:	de270713          	addi	a4,a4,-542 # 8001ee00 <bcache+0x8268>
    80003026:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003028:	2b87b703          	ld	a4,696(a5)
    8000302c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000302e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	b6650513          	addi	a0,a0,-1178 # 80016b98 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c50080e7          	jalr	-944(ra) # 80000c8a <release>
}
    80003042:	60e2                	ld	ra,24(sp)
    80003044:	6442                	ld	s0,16(sp)
    80003046:	64a2                	ld	s1,8(sp)
    80003048:	6902                	ld	s2,0(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret
    panic("brelse");
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	4e250513          	addi	a0,a0,1250 # 80008530 <syscalls+0xe0>
    80003056:	ffffd097          	auipc	ra,0xffffd
    8000305a:	4ea080e7          	jalr	1258(ra) # 80000540 <panic>

000000008000305e <bpin>:

void
bpin(struct buf *b) {
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	1000                	addi	s0,sp,32
    80003068:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000306a:	00014517          	auipc	a0,0x14
    8000306e:	b2e50513          	addi	a0,a0,-1234 # 80016b98 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	b64080e7          	jalr	-1180(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000307a:	40bc                	lw	a5,64(s1)
    8000307c:	2785                	addiw	a5,a5,1
    8000307e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003080:	00014517          	auipc	a0,0x14
    80003084:	b1850513          	addi	a0,a0,-1256 # 80016b98 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	c02080e7          	jalr	-1022(ra) # 80000c8a <release>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret

000000008000309a <bunpin>:

void
bunpin(struct buf *b) {
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	addi	s0,sp,32
    800030a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a6:	00014517          	auipc	a0,0x14
    800030aa:	af250513          	addi	a0,a0,-1294 # 80016b98 <bcache>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	b28080e7          	jalr	-1240(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030b6:	40bc                	lw	a5,64(s1)
    800030b8:	37fd                	addiw	a5,a5,-1
    800030ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	adc50513          	addi	a0,a0,-1316 # 80016b98 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bc6080e7          	jalr	-1082(ra) # 80000c8a <release>
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret

00000000800030d6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	e426                	sd	s1,8(sp)
    800030de:	e04a                	sd	s2,0(sp)
    800030e0:	1000                	addi	s0,sp,32
    800030e2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030e4:	00d5d59b          	srliw	a1,a1,0xd
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	18c7a783          	lw	a5,396(a5) # 8001f274 <sb+0x1c>
    800030f0:	9dbd                	addw	a1,a1,a5
    800030f2:	00000097          	auipc	ra,0x0
    800030f6:	d9e080e7          	jalr	-610(ra) # 80002e90 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030fa:	0074f713          	andi	a4,s1,7
    800030fe:	4785                	li	a5,1
    80003100:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003104:	14ce                	slli	s1,s1,0x33
    80003106:	90d9                	srli	s1,s1,0x36
    80003108:	00950733          	add	a4,a0,s1
    8000310c:	05874703          	lbu	a4,88(a4)
    80003110:	00e7f6b3          	and	a3,a5,a4
    80003114:	c69d                	beqz	a3,80003142 <bfree+0x6c>
    80003116:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003118:	94aa                	add	s1,s1,a0
    8000311a:	fff7c793          	not	a5,a5
    8000311e:	8f7d                	and	a4,a4,a5
    80003120:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003124:	00001097          	auipc	ra,0x1
    80003128:	126080e7          	jalr	294(ra) # 8000424a <log_write>
  brelse(bp);
    8000312c:	854a                	mv	a0,s2
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	e92080e7          	jalr	-366(ra) # 80002fc0 <brelse>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6902                	ld	s2,0(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret
    panic("freeing free block");
    80003142:	00005517          	auipc	a0,0x5
    80003146:	3f650513          	addi	a0,a0,1014 # 80008538 <syscalls+0xe8>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	3f6080e7          	jalr	1014(ra) # 80000540 <panic>

0000000080003152 <balloc>:
{
    80003152:	711d                	addi	sp,sp,-96
    80003154:	ec86                	sd	ra,88(sp)
    80003156:	e8a2                	sd	s0,80(sp)
    80003158:	e4a6                	sd	s1,72(sp)
    8000315a:	e0ca                	sd	s2,64(sp)
    8000315c:	fc4e                	sd	s3,56(sp)
    8000315e:	f852                	sd	s4,48(sp)
    80003160:	f456                	sd	s5,40(sp)
    80003162:	f05a                	sd	s6,32(sp)
    80003164:	ec5e                	sd	s7,24(sp)
    80003166:	e862                	sd	s8,16(sp)
    80003168:	e466                	sd	s9,8(sp)
    8000316a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	0f07a783          	lw	a5,240(a5) # 8001f25c <sb+0x4>
    80003174:	cff5                	beqz	a5,80003270 <balloc+0x11e>
    80003176:	8baa                	mv	s7,a0
    80003178:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000317a:	0001cb17          	auipc	s6,0x1c
    8000317e:	0deb0b13          	addi	s6,s6,222 # 8001f258 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003182:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003184:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003186:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003188:	6c89                	lui	s9,0x2
    8000318a:	a061                	j	80003212 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000318c:	97ca                	add	a5,a5,s2
    8000318e:	8e55                	or	a2,a2,a3
    80003190:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003194:	854a                	mv	a0,s2
    80003196:	00001097          	auipc	ra,0x1
    8000319a:	0b4080e7          	jalr	180(ra) # 8000424a <log_write>
        brelse(bp);
    8000319e:	854a                	mv	a0,s2
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	e20080e7          	jalr	-480(ra) # 80002fc0 <brelse>
  bp = bread(dev, bno);
    800031a8:	85a6                	mv	a1,s1
    800031aa:	855e                	mv	a0,s7
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	ce4080e7          	jalr	-796(ra) # 80002e90 <bread>
    800031b4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031b6:	40000613          	li	a2,1024
    800031ba:	4581                	li	a1,0
    800031bc:	05850513          	addi	a0,a0,88
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	b12080e7          	jalr	-1262(ra) # 80000cd2 <memset>
  log_write(bp);
    800031c8:	854a                	mv	a0,s2
    800031ca:	00001097          	auipc	ra,0x1
    800031ce:	080080e7          	jalr	128(ra) # 8000424a <log_write>
  brelse(bp);
    800031d2:	854a                	mv	a0,s2
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	dec080e7          	jalr	-532(ra) # 80002fc0 <brelse>
}
    800031dc:	8526                	mv	a0,s1
    800031de:	60e6                	ld	ra,88(sp)
    800031e0:	6446                	ld	s0,80(sp)
    800031e2:	64a6                	ld	s1,72(sp)
    800031e4:	6906                	ld	s2,64(sp)
    800031e6:	79e2                	ld	s3,56(sp)
    800031e8:	7a42                	ld	s4,48(sp)
    800031ea:	7aa2                	ld	s5,40(sp)
    800031ec:	7b02                	ld	s6,32(sp)
    800031ee:	6be2                	ld	s7,24(sp)
    800031f0:	6c42                	ld	s8,16(sp)
    800031f2:	6ca2                	ld	s9,8(sp)
    800031f4:	6125                	addi	sp,sp,96
    800031f6:	8082                	ret
    brelse(bp);
    800031f8:	854a                	mv	a0,s2
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	dc6080e7          	jalr	-570(ra) # 80002fc0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003202:	015c87bb          	addw	a5,s9,s5
    80003206:	00078a9b          	sext.w	s5,a5
    8000320a:	004b2703          	lw	a4,4(s6)
    8000320e:	06eaf163          	bgeu	s5,a4,80003270 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003212:	41fad79b          	sraiw	a5,s5,0x1f
    80003216:	0137d79b          	srliw	a5,a5,0x13
    8000321a:	015787bb          	addw	a5,a5,s5
    8000321e:	40d7d79b          	sraiw	a5,a5,0xd
    80003222:	01cb2583          	lw	a1,28(s6)
    80003226:	9dbd                	addw	a1,a1,a5
    80003228:	855e                	mv	a0,s7
    8000322a:	00000097          	auipc	ra,0x0
    8000322e:	c66080e7          	jalr	-922(ra) # 80002e90 <bread>
    80003232:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003234:	004b2503          	lw	a0,4(s6)
    80003238:	000a849b          	sext.w	s1,s5
    8000323c:	8762                	mv	a4,s8
    8000323e:	faa4fde3          	bgeu	s1,a0,800031f8 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003242:	00777693          	andi	a3,a4,7
    80003246:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000324a:	41f7579b          	sraiw	a5,a4,0x1f
    8000324e:	01d7d79b          	srliw	a5,a5,0x1d
    80003252:	9fb9                	addw	a5,a5,a4
    80003254:	4037d79b          	sraiw	a5,a5,0x3
    80003258:	00f90633          	add	a2,s2,a5
    8000325c:	05864603          	lbu	a2,88(a2)
    80003260:	00c6f5b3          	and	a1,a3,a2
    80003264:	d585                	beqz	a1,8000318c <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003266:	2705                	addiw	a4,a4,1
    80003268:	2485                	addiw	s1,s1,1
    8000326a:	fd471ae3          	bne	a4,s4,8000323e <balloc+0xec>
    8000326e:	b769                	j	800031f8 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003270:	00005517          	auipc	a0,0x5
    80003274:	2e050513          	addi	a0,a0,736 # 80008550 <syscalls+0x100>
    80003278:	ffffd097          	auipc	ra,0xffffd
    8000327c:	312080e7          	jalr	786(ra) # 8000058a <printf>
  return 0;
    80003280:	4481                	li	s1,0
    80003282:	bfa9                	j	800031dc <balloc+0x8a>

0000000080003284 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003284:	7179                	addi	sp,sp,-48
    80003286:	f406                	sd	ra,40(sp)
    80003288:	f022                	sd	s0,32(sp)
    8000328a:	ec26                	sd	s1,24(sp)
    8000328c:	e84a                	sd	s2,16(sp)
    8000328e:	e44e                	sd	s3,8(sp)
    80003290:	e052                	sd	s4,0(sp)
    80003292:	1800                	addi	s0,sp,48
    80003294:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003296:	47ad                	li	a5,11
    80003298:	02b7e863          	bltu	a5,a1,800032c8 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000329c:	02059793          	slli	a5,a1,0x20
    800032a0:	01e7d593          	srli	a1,a5,0x1e
    800032a4:	00b504b3          	add	s1,a0,a1
    800032a8:	0504a903          	lw	s2,80(s1)
    800032ac:	06091e63          	bnez	s2,80003328 <bmap+0xa4>
      addr = balloc(ip->dev);
    800032b0:	4108                	lw	a0,0(a0)
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	ea0080e7          	jalr	-352(ra) # 80003152 <balloc>
    800032ba:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032be:	06090563          	beqz	s2,80003328 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800032c2:	0524a823          	sw	s2,80(s1)
    800032c6:	a08d                	j	80003328 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800032c8:	ff45849b          	addiw	s1,a1,-12
    800032cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032d0:	0ff00793          	li	a5,255
    800032d4:	08e7e563          	bltu	a5,a4,8000335e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032d8:	08052903          	lw	s2,128(a0)
    800032dc:	00091d63          	bnez	s2,800032f6 <bmap+0x72>
      addr = balloc(ip->dev);
    800032e0:	4108                	lw	a0,0(a0)
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	e70080e7          	jalr	-400(ra) # 80003152 <balloc>
    800032ea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032ee:	02090d63          	beqz	s2,80003328 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032f2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800032f6:	85ca                	mv	a1,s2
    800032f8:	0009a503          	lw	a0,0(s3)
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	b94080e7          	jalr	-1132(ra) # 80002e90 <bread>
    80003304:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003306:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000330a:	02049713          	slli	a4,s1,0x20
    8000330e:	01e75593          	srli	a1,a4,0x1e
    80003312:	00b784b3          	add	s1,a5,a1
    80003316:	0004a903          	lw	s2,0(s1)
    8000331a:	02090063          	beqz	s2,8000333a <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000331e:	8552                	mv	a0,s4
    80003320:	00000097          	auipc	ra,0x0
    80003324:	ca0080e7          	jalr	-864(ra) # 80002fc0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003328:	854a                	mv	a0,s2
    8000332a:	70a2                	ld	ra,40(sp)
    8000332c:	7402                	ld	s0,32(sp)
    8000332e:	64e2                	ld	s1,24(sp)
    80003330:	6942                	ld	s2,16(sp)
    80003332:	69a2                	ld	s3,8(sp)
    80003334:	6a02                	ld	s4,0(sp)
    80003336:	6145                	addi	sp,sp,48
    80003338:	8082                	ret
      addr = balloc(ip->dev);
    8000333a:	0009a503          	lw	a0,0(s3)
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	e14080e7          	jalr	-492(ra) # 80003152 <balloc>
    80003346:	0005091b          	sext.w	s2,a0
      if(addr){
    8000334a:	fc090ae3          	beqz	s2,8000331e <bmap+0x9a>
        a[bn] = addr;
    8000334e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003352:	8552                	mv	a0,s4
    80003354:	00001097          	auipc	ra,0x1
    80003358:	ef6080e7          	jalr	-266(ra) # 8000424a <log_write>
    8000335c:	b7c9                	j	8000331e <bmap+0x9a>
  panic("bmap: out of range");
    8000335e:	00005517          	auipc	a0,0x5
    80003362:	20a50513          	addi	a0,a0,522 # 80008568 <syscalls+0x118>
    80003366:	ffffd097          	auipc	ra,0xffffd
    8000336a:	1da080e7          	jalr	474(ra) # 80000540 <panic>

000000008000336e <iget>:
{
    8000336e:	7179                	addi	sp,sp,-48
    80003370:	f406                	sd	ra,40(sp)
    80003372:	f022                	sd	s0,32(sp)
    80003374:	ec26                	sd	s1,24(sp)
    80003376:	e84a                	sd	s2,16(sp)
    80003378:	e44e                	sd	s3,8(sp)
    8000337a:	e052                	sd	s4,0(sp)
    8000337c:	1800                	addi	s0,sp,48
    8000337e:	89aa                	mv	s3,a0
    80003380:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003382:	0001c517          	auipc	a0,0x1c
    80003386:	ef650513          	addi	a0,a0,-266 # 8001f278 <itable>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	84c080e7          	jalr	-1972(ra) # 80000bd6 <acquire>
  empty = 0;
    80003392:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003394:	0001c497          	auipc	s1,0x1c
    80003398:	efc48493          	addi	s1,s1,-260 # 8001f290 <itable+0x18>
    8000339c:	0001e697          	auipc	a3,0x1e
    800033a0:	98468693          	addi	a3,a3,-1660 # 80020d20 <log>
    800033a4:	a039                	j	800033b2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033a6:	02090b63          	beqz	s2,800033dc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033aa:	08848493          	addi	s1,s1,136
    800033ae:	02d48a63          	beq	s1,a3,800033e2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033b2:	449c                	lw	a5,8(s1)
    800033b4:	fef059e3          	blez	a5,800033a6 <iget+0x38>
    800033b8:	4098                	lw	a4,0(s1)
    800033ba:	ff3716e3          	bne	a4,s3,800033a6 <iget+0x38>
    800033be:	40d8                	lw	a4,4(s1)
    800033c0:	ff4713e3          	bne	a4,s4,800033a6 <iget+0x38>
      ip->ref++;
    800033c4:	2785                	addiw	a5,a5,1
    800033c6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033c8:	0001c517          	auipc	a0,0x1c
    800033cc:	eb050513          	addi	a0,a0,-336 # 8001f278 <itable>
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
      return ip;
    800033d8:	8926                	mv	s2,s1
    800033da:	a03d                	j	80003408 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033dc:	f7f9                	bnez	a5,800033aa <iget+0x3c>
    800033de:	8926                	mv	s2,s1
    800033e0:	b7e9                	j	800033aa <iget+0x3c>
  if(empty == 0)
    800033e2:	02090c63          	beqz	s2,8000341a <iget+0xac>
  ip->dev = dev;
    800033e6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033ea:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033ee:	4785                	li	a5,1
    800033f0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033f4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033f8:	0001c517          	auipc	a0,0x1c
    800033fc:	e8050513          	addi	a0,a0,-384 # 8001f278 <itable>
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	88a080e7          	jalr	-1910(ra) # 80000c8a <release>
}
    80003408:	854a                	mv	a0,s2
    8000340a:	70a2                	ld	ra,40(sp)
    8000340c:	7402                	ld	s0,32(sp)
    8000340e:	64e2                	ld	s1,24(sp)
    80003410:	6942                	ld	s2,16(sp)
    80003412:	69a2                	ld	s3,8(sp)
    80003414:	6a02                	ld	s4,0(sp)
    80003416:	6145                	addi	sp,sp,48
    80003418:	8082                	ret
    panic("iget: no inodes");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	16650513          	addi	a0,a0,358 # 80008580 <syscalls+0x130>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	11e080e7          	jalr	286(ra) # 80000540 <panic>

000000008000342a <fsinit>:
fsinit(int dev) {
    8000342a:	7179                	addi	sp,sp,-48
    8000342c:	f406                	sd	ra,40(sp)
    8000342e:	f022                	sd	s0,32(sp)
    80003430:	ec26                	sd	s1,24(sp)
    80003432:	e84a                	sd	s2,16(sp)
    80003434:	e44e                	sd	s3,8(sp)
    80003436:	1800                	addi	s0,sp,48
    80003438:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000343a:	4585                	li	a1,1
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	a54080e7          	jalr	-1452(ra) # 80002e90 <bread>
    80003444:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003446:	0001c997          	auipc	s3,0x1c
    8000344a:	e1298993          	addi	s3,s3,-494 # 8001f258 <sb>
    8000344e:	02000613          	li	a2,32
    80003452:	05850593          	addi	a1,a0,88
    80003456:	854e                	mv	a0,s3
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	8d6080e7          	jalr	-1834(ra) # 80000d2e <memmove>
  brelse(bp);
    80003460:	8526                	mv	a0,s1
    80003462:	00000097          	auipc	ra,0x0
    80003466:	b5e080e7          	jalr	-1186(ra) # 80002fc0 <brelse>
  if(sb.magic != FSMAGIC)
    8000346a:	0009a703          	lw	a4,0(s3)
    8000346e:	102037b7          	lui	a5,0x10203
    80003472:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003476:	02f71263          	bne	a4,a5,8000349a <fsinit+0x70>
  initlog(dev, &sb);
    8000347a:	0001c597          	auipc	a1,0x1c
    8000347e:	dde58593          	addi	a1,a1,-546 # 8001f258 <sb>
    80003482:	854a                	mv	a0,s2
    80003484:	00001097          	auipc	ra,0x1
    80003488:	b4a080e7          	jalr	-1206(ra) # 80003fce <initlog>
}
    8000348c:	70a2                	ld	ra,40(sp)
    8000348e:	7402                	ld	s0,32(sp)
    80003490:	64e2                	ld	s1,24(sp)
    80003492:	6942                	ld	s2,16(sp)
    80003494:	69a2                	ld	s3,8(sp)
    80003496:	6145                	addi	sp,sp,48
    80003498:	8082                	ret
    panic("invalid file system");
    8000349a:	00005517          	auipc	a0,0x5
    8000349e:	0f650513          	addi	a0,a0,246 # 80008590 <syscalls+0x140>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	09e080e7          	jalr	158(ra) # 80000540 <panic>

00000000800034aa <iinit>:
{
    800034aa:	7179                	addi	sp,sp,-48
    800034ac:	f406                	sd	ra,40(sp)
    800034ae:	f022                	sd	s0,32(sp)
    800034b0:	ec26                	sd	s1,24(sp)
    800034b2:	e84a                	sd	s2,16(sp)
    800034b4:	e44e                	sd	s3,8(sp)
    800034b6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034b8:	00005597          	auipc	a1,0x5
    800034bc:	0f058593          	addi	a1,a1,240 # 800085a8 <syscalls+0x158>
    800034c0:	0001c517          	auipc	a0,0x1c
    800034c4:	db850513          	addi	a0,a0,-584 # 8001f278 <itable>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	67e080e7          	jalr	1662(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034d0:	0001c497          	auipc	s1,0x1c
    800034d4:	dd048493          	addi	s1,s1,-560 # 8001f2a0 <itable+0x28>
    800034d8:	0001e997          	auipc	s3,0x1e
    800034dc:	85898993          	addi	s3,s3,-1960 # 80020d30 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034e0:	00005917          	auipc	s2,0x5
    800034e4:	0d090913          	addi	s2,s2,208 # 800085b0 <syscalls+0x160>
    800034e8:	85ca                	mv	a1,s2
    800034ea:	8526                	mv	a0,s1
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	e42080e7          	jalr	-446(ra) # 8000432e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034f4:	08848493          	addi	s1,s1,136
    800034f8:	ff3498e3          	bne	s1,s3,800034e8 <iinit+0x3e>
}
    800034fc:	70a2                	ld	ra,40(sp)
    800034fe:	7402                	ld	s0,32(sp)
    80003500:	64e2                	ld	s1,24(sp)
    80003502:	6942                	ld	s2,16(sp)
    80003504:	69a2                	ld	s3,8(sp)
    80003506:	6145                	addi	sp,sp,48
    80003508:	8082                	ret

000000008000350a <ialloc>:
{
    8000350a:	715d                	addi	sp,sp,-80
    8000350c:	e486                	sd	ra,72(sp)
    8000350e:	e0a2                	sd	s0,64(sp)
    80003510:	fc26                	sd	s1,56(sp)
    80003512:	f84a                	sd	s2,48(sp)
    80003514:	f44e                	sd	s3,40(sp)
    80003516:	f052                	sd	s4,32(sp)
    80003518:	ec56                	sd	s5,24(sp)
    8000351a:	e85a                	sd	s6,16(sp)
    8000351c:	e45e                	sd	s7,8(sp)
    8000351e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003520:	0001c717          	auipc	a4,0x1c
    80003524:	d4472703          	lw	a4,-700(a4) # 8001f264 <sb+0xc>
    80003528:	4785                	li	a5,1
    8000352a:	04e7fa63          	bgeu	a5,a4,8000357e <ialloc+0x74>
    8000352e:	8aaa                	mv	s5,a0
    80003530:	8bae                	mv	s7,a1
    80003532:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003534:	0001ca17          	auipc	s4,0x1c
    80003538:	d24a0a13          	addi	s4,s4,-732 # 8001f258 <sb>
    8000353c:	00048b1b          	sext.w	s6,s1
    80003540:	0044d593          	srli	a1,s1,0x4
    80003544:	018a2783          	lw	a5,24(s4)
    80003548:	9dbd                	addw	a1,a1,a5
    8000354a:	8556                	mv	a0,s5
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	944080e7          	jalr	-1724(ra) # 80002e90 <bread>
    80003554:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003556:	05850993          	addi	s3,a0,88
    8000355a:	00f4f793          	andi	a5,s1,15
    8000355e:	079a                	slli	a5,a5,0x6
    80003560:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003562:	00099783          	lh	a5,0(s3)
    80003566:	c3a1                	beqz	a5,800035a6 <ialloc+0x9c>
    brelse(bp);
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	a58080e7          	jalr	-1448(ra) # 80002fc0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003570:	0485                	addi	s1,s1,1
    80003572:	00ca2703          	lw	a4,12(s4)
    80003576:	0004879b          	sext.w	a5,s1
    8000357a:	fce7e1e3          	bltu	a5,a4,8000353c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000357e:	00005517          	auipc	a0,0x5
    80003582:	03a50513          	addi	a0,a0,58 # 800085b8 <syscalls+0x168>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	004080e7          	jalr	4(ra) # 8000058a <printf>
  return 0;
    8000358e:	4501                	li	a0,0
}
    80003590:	60a6                	ld	ra,72(sp)
    80003592:	6406                	ld	s0,64(sp)
    80003594:	74e2                	ld	s1,56(sp)
    80003596:	7942                	ld	s2,48(sp)
    80003598:	79a2                	ld	s3,40(sp)
    8000359a:	7a02                	ld	s4,32(sp)
    8000359c:	6ae2                	ld	s5,24(sp)
    8000359e:	6b42                	ld	s6,16(sp)
    800035a0:	6ba2                	ld	s7,8(sp)
    800035a2:	6161                	addi	sp,sp,80
    800035a4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800035a6:	04000613          	li	a2,64
    800035aa:	4581                	li	a1,0
    800035ac:	854e                	mv	a0,s3
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	724080e7          	jalr	1828(ra) # 80000cd2 <memset>
      dip->type = type;
    800035b6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035ba:	854a                	mv	a0,s2
    800035bc:	00001097          	auipc	ra,0x1
    800035c0:	c8e080e7          	jalr	-882(ra) # 8000424a <log_write>
      brelse(bp);
    800035c4:	854a                	mv	a0,s2
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	9fa080e7          	jalr	-1542(ra) # 80002fc0 <brelse>
      return iget(dev, inum);
    800035ce:	85da                	mv	a1,s6
    800035d0:	8556                	mv	a0,s5
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	d9c080e7          	jalr	-612(ra) # 8000336e <iget>
    800035da:	bf5d                	j	80003590 <ialloc+0x86>

00000000800035dc <iupdate>:
{
    800035dc:	1101                	addi	sp,sp,-32
    800035de:	ec06                	sd	ra,24(sp)
    800035e0:	e822                	sd	s0,16(sp)
    800035e2:	e426                	sd	s1,8(sp)
    800035e4:	e04a                	sd	s2,0(sp)
    800035e6:	1000                	addi	s0,sp,32
    800035e8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035ea:	415c                	lw	a5,4(a0)
    800035ec:	0047d79b          	srliw	a5,a5,0x4
    800035f0:	0001c597          	auipc	a1,0x1c
    800035f4:	c805a583          	lw	a1,-896(a1) # 8001f270 <sb+0x18>
    800035f8:	9dbd                	addw	a1,a1,a5
    800035fa:	4108                	lw	a0,0(a0)
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	894080e7          	jalr	-1900(ra) # 80002e90 <bread>
    80003604:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003606:	05850793          	addi	a5,a0,88
    8000360a:	40d8                	lw	a4,4(s1)
    8000360c:	8b3d                	andi	a4,a4,15
    8000360e:	071a                	slli	a4,a4,0x6
    80003610:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003612:	04449703          	lh	a4,68(s1)
    80003616:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000361a:	04649703          	lh	a4,70(s1)
    8000361e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003622:	04849703          	lh	a4,72(s1)
    80003626:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000362a:	04a49703          	lh	a4,74(s1)
    8000362e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003632:	44f8                	lw	a4,76(s1)
    80003634:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003636:	03400613          	li	a2,52
    8000363a:	05048593          	addi	a1,s1,80
    8000363e:	00c78513          	addi	a0,a5,12
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	6ec080e7          	jalr	1772(ra) # 80000d2e <memmove>
  log_write(bp);
    8000364a:	854a                	mv	a0,s2
    8000364c:	00001097          	auipc	ra,0x1
    80003650:	bfe080e7          	jalr	-1026(ra) # 8000424a <log_write>
  brelse(bp);
    80003654:	854a                	mv	a0,s2
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	96a080e7          	jalr	-1686(ra) # 80002fc0 <brelse>
}
    8000365e:	60e2                	ld	ra,24(sp)
    80003660:	6442                	ld	s0,16(sp)
    80003662:	64a2                	ld	s1,8(sp)
    80003664:	6902                	ld	s2,0(sp)
    80003666:	6105                	addi	sp,sp,32
    80003668:	8082                	ret

000000008000366a <idup>:
{
    8000366a:	1101                	addi	sp,sp,-32
    8000366c:	ec06                	sd	ra,24(sp)
    8000366e:	e822                	sd	s0,16(sp)
    80003670:	e426                	sd	s1,8(sp)
    80003672:	1000                	addi	s0,sp,32
    80003674:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003676:	0001c517          	auipc	a0,0x1c
    8000367a:	c0250513          	addi	a0,a0,-1022 # 8001f278 <itable>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	558080e7          	jalr	1368(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003686:	449c                	lw	a5,8(s1)
    80003688:	2785                	addiw	a5,a5,1
    8000368a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000368c:	0001c517          	auipc	a0,0x1c
    80003690:	bec50513          	addi	a0,a0,-1044 # 8001f278 <itable>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	5f6080e7          	jalr	1526(ra) # 80000c8a <release>
}
    8000369c:	8526                	mv	a0,s1
    8000369e:	60e2                	ld	ra,24(sp)
    800036a0:	6442                	ld	s0,16(sp)
    800036a2:	64a2                	ld	s1,8(sp)
    800036a4:	6105                	addi	sp,sp,32
    800036a6:	8082                	ret

00000000800036a8 <ilock>:
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	e04a                	sd	s2,0(sp)
    800036b2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036b4:	c115                	beqz	a0,800036d8 <ilock+0x30>
    800036b6:	84aa                	mv	s1,a0
    800036b8:	451c                	lw	a5,8(a0)
    800036ba:	00f05f63          	blez	a5,800036d8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036be:	0541                	addi	a0,a0,16
    800036c0:	00001097          	auipc	ra,0x1
    800036c4:	ca8080e7          	jalr	-856(ra) # 80004368 <acquiresleep>
  if(ip->valid == 0){
    800036c8:	40bc                	lw	a5,64(s1)
    800036ca:	cf99                	beqz	a5,800036e8 <ilock+0x40>
}
    800036cc:	60e2                	ld	ra,24(sp)
    800036ce:	6442                	ld	s0,16(sp)
    800036d0:	64a2                	ld	s1,8(sp)
    800036d2:	6902                	ld	s2,0(sp)
    800036d4:	6105                	addi	sp,sp,32
    800036d6:	8082                	ret
    panic("ilock");
    800036d8:	00005517          	auipc	a0,0x5
    800036dc:	ef850513          	addi	a0,a0,-264 # 800085d0 <syscalls+0x180>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	e60080e7          	jalr	-416(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036e8:	40dc                	lw	a5,4(s1)
    800036ea:	0047d79b          	srliw	a5,a5,0x4
    800036ee:	0001c597          	auipc	a1,0x1c
    800036f2:	b825a583          	lw	a1,-1150(a1) # 8001f270 <sb+0x18>
    800036f6:	9dbd                	addw	a1,a1,a5
    800036f8:	4088                	lw	a0,0(s1)
    800036fa:	fffff097          	auipc	ra,0xfffff
    800036fe:	796080e7          	jalr	1942(ra) # 80002e90 <bread>
    80003702:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003704:	05850593          	addi	a1,a0,88
    80003708:	40dc                	lw	a5,4(s1)
    8000370a:	8bbd                	andi	a5,a5,15
    8000370c:	079a                	slli	a5,a5,0x6
    8000370e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003710:	00059783          	lh	a5,0(a1)
    80003714:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003718:	00259783          	lh	a5,2(a1)
    8000371c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003720:	00459783          	lh	a5,4(a1)
    80003724:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003728:	00659783          	lh	a5,6(a1)
    8000372c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003730:	459c                	lw	a5,8(a1)
    80003732:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003734:	03400613          	li	a2,52
    80003738:	05b1                	addi	a1,a1,12
    8000373a:	05048513          	addi	a0,s1,80
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	5f0080e7          	jalr	1520(ra) # 80000d2e <memmove>
    brelse(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	878080e7          	jalr	-1928(ra) # 80002fc0 <brelse>
    ip->valid = 1;
    80003750:	4785                	li	a5,1
    80003752:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003754:	04449783          	lh	a5,68(s1)
    80003758:	fbb5                	bnez	a5,800036cc <ilock+0x24>
      panic("ilock: no type");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	e7e50513          	addi	a0,a0,-386 # 800085d8 <syscalls+0x188>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	dde080e7          	jalr	-546(ra) # 80000540 <panic>

000000008000376a <iunlock>:
{
    8000376a:	1101                	addi	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	e426                	sd	s1,8(sp)
    80003772:	e04a                	sd	s2,0(sp)
    80003774:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003776:	c905                	beqz	a0,800037a6 <iunlock+0x3c>
    80003778:	84aa                	mv	s1,a0
    8000377a:	01050913          	addi	s2,a0,16
    8000377e:	854a                	mv	a0,s2
    80003780:	00001097          	auipc	ra,0x1
    80003784:	c82080e7          	jalr	-894(ra) # 80004402 <holdingsleep>
    80003788:	cd19                	beqz	a0,800037a6 <iunlock+0x3c>
    8000378a:	449c                	lw	a5,8(s1)
    8000378c:	00f05d63          	blez	a5,800037a6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003790:	854a                	mv	a0,s2
    80003792:	00001097          	auipc	ra,0x1
    80003796:	c2c080e7          	jalr	-980(ra) # 800043be <releasesleep>
}
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6902                	ld	s2,0(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret
    panic("iunlock");
    800037a6:	00005517          	auipc	a0,0x5
    800037aa:	e4250513          	addi	a0,a0,-446 # 800085e8 <syscalls+0x198>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	d92080e7          	jalr	-622(ra) # 80000540 <panic>

00000000800037b6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037b6:	7179                	addi	sp,sp,-48
    800037b8:	f406                	sd	ra,40(sp)
    800037ba:	f022                	sd	s0,32(sp)
    800037bc:	ec26                	sd	s1,24(sp)
    800037be:	e84a                	sd	s2,16(sp)
    800037c0:	e44e                	sd	s3,8(sp)
    800037c2:	e052                	sd	s4,0(sp)
    800037c4:	1800                	addi	s0,sp,48
    800037c6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037c8:	05050493          	addi	s1,a0,80
    800037cc:	08050913          	addi	s2,a0,128
    800037d0:	a021                	j	800037d8 <itrunc+0x22>
    800037d2:	0491                	addi	s1,s1,4
    800037d4:	01248d63          	beq	s1,s2,800037ee <itrunc+0x38>
    if(ip->addrs[i]){
    800037d8:	408c                	lw	a1,0(s1)
    800037da:	dde5                	beqz	a1,800037d2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037dc:	0009a503          	lw	a0,0(s3)
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	8f6080e7          	jalr	-1802(ra) # 800030d6 <bfree>
      ip->addrs[i] = 0;
    800037e8:	0004a023          	sw	zero,0(s1)
    800037ec:	b7dd                	j	800037d2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037ee:	0809a583          	lw	a1,128(s3)
    800037f2:	e185                	bnez	a1,80003812 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037f4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037f8:	854e                	mv	a0,s3
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	de2080e7          	jalr	-542(ra) # 800035dc <iupdate>
}
    80003802:	70a2                	ld	ra,40(sp)
    80003804:	7402                	ld	s0,32(sp)
    80003806:	64e2                	ld	s1,24(sp)
    80003808:	6942                	ld	s2,16(sp)
    8000380a:	69a2                	ld	s3,8(sp)
    8000380c:	6a02                	ld	s4,0(sp)
    8000380e:	6145                	addi	sp,sp,48
    80003810:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003812:	0009a503          	lw	a0,0(s3)
    80003816:	fffff097          	auipc	ra,0xfffff
    8000381a:	67a080e7          	jalr	1658(ra) # 80002e90 <bread>
    8000381e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003820:	05850493          	addi	s1,a0,88
    80003824:	45850913          	addi	s2,a0,1112
    80003828:	a021                	j	80003830 <itrunc+0x7a>
    8000382a:	0491                	addi	s1,s1,4
    8000382c:	01248b63          	beq	s1,s2,80003842 <itrunc+0x8c>
      if(a[j])
    80003830:	408c                	lw	a1,0(s1)
    80003832:	dde5                	beqz	a1,8000382a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003834:	0009a503          	lw	a0,0(s3)
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	89e080e7          	jalr	-1890(ra) # 800030d6 <bfree>
    80003840:	b7ed                	j	8000382a <itrunc+0x74>
    brelse(bp);
    80003842:	8552                	mv	a0,s4
    80003844:	fffff097          	auipc	ra,0xfffff
    80003848:	77c080e7          	jalr	1916(ra) # 80002fc0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000384c:	0809a583          	lw	a1,128(s3)
    80003850:	0009a503          	lw	a0,0(s3)
    80003854:	00000097          	auipc	ra,0x0
    80003858:	882080e7          	jalr	-1918(ra) # 800030d6 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000385c:	0809a023          	sw	zero,128(s3)
    80003860:	bf51                	j	800037f4 <itrunc+0x3e>

0000000080003862 <iput>:
{
    80003862:	1101                	addi	sp,sp,-32
    80003864:	ec06                	sd	ra,24(sp)
    80003866:	e822                	sd	s0,16(sp)
    80003868:	e426                	sd	s1,8(sp)
    8000386a:	e04a                	sd	s2,0(sp)
    8000386c:	1000                	addi	s0,sp,32
    8000386e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003870:	0001c517          	auipc	a0,0x1c
    80003874:	a0850513          	addi	a0,a0,-1528 # 8001f278 <itable>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	35e080e7          	jalr	862(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003880:	4498                	lw	a4,8(s1)
    80003882:	4785                	li	a5,1
    80003884:	02f70363          	beq	a4,a5,800038aa <iput+0x48>
  ip->ref--;
    80003888:	449c                	lw	a5,8(s1)
    8000388a:	37fd                	addiw	a5,a5,-1
    8000388c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000388e:	0001c517          	auipc	a0,0x1c
    80003892:	9ea50513          	addi	a0,a0,-1558 # 8001f278 <itable>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	3f4080e7          	jalr	1012(ra) # 80000c8a <release>
}
    8000389e:	60e2                	ld	ra,24(sp)
    800038a0:	6442                	ld	s0,16(sp)
    800038a2:	64a2                	ld	s1,8(sp)
    800038a4:	6902                	ld	s2,0(sp)
    800038a6:	6105                	addi	sp,sp,32
    800038a8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038aa:	40bc                	lw	a5,64(s1)
    800038ac:	dff1                	beqz	a5,80003888 <iput+0x26>
    800038ae:	04a49783          	lh	a5,74(s1)
    800038b2:	fbf9                	bnez	a5,80003888 <iput+0x26>
    acquiresleep(&ip->lock);
    800038b4:	01048913          	addi	s2,s1,16
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	aae080e7          	jalr	-1362(ra) # 80004368 <acquiresleep>
    release(&itable.lock);
    800038c2:	0001c517          	auipc	a0,0x1c
    800038c6:	9b650513          	addi	a0,a0,-1610 # 8001f278 <itable>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	3c0080e7          	jalr	960(ra) # 80000c8a <release>
    itrunc(ip);
    800038d2:	8526                	mv	a0,s1
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	ee2080e7          	jalr	-286(ra) # 800037b6 <itrunc>
    ip->type = 0;
    800038dc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038e0:	8526                	mv	a0,s1
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	cfa080e7          	jalr	-774(ra) # 800035dc <iupdate>
    ip->valid = 0;
    800038ea:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	ace080e7          	jalr	-1330(ra) # 800043be <releasesleep>
    acquire(&itable.lock);
    800038f8:	0001c517          	auipc	a0,0x1c
    800038fc:	98050513          	addi	a0,a0,-1664 # 8001f278 <itable>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	2d6080e7          	jalr	726(ra) # 80000bd6 <acquire>
    80003908:	b741                	j	80003888 <iput+0x26>

000000008000390a <iunlockput>:
{
    8000390a:	1101                	addi	sp,sp,-32
    8000390c:	ec06                	sd	ra,24(sp)
    8000390e:	e822                	sd	s0,16(sp)
    80003910:	e426                	sd	s1,8(sp)
    80003912:	1000                	addi	s0,sp,32
    80003914:	84aa                	mv	s1,a0
  iunlock(ip);
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	e54080e7          	jalr	-428(ra) # 8000376a <iunlock>
  iput(ip);
    8000391e:	8526                	mv	a0,s1
    80003920:	00000097          	auipc	ra,0x0
    80003924:	f42080e7          	jalr	-190(ra) # 80003862 <iput>
}
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret

0000000080003932 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003932:	1141                	addi	sp,sp,-16
    80003934:	e422                	sd	s0,8(sp)
    80003936:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003938:	411c                	lw	a5,0(a0)
    8000393a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000393c:	415c                	lw	a5,4(a0)
    8000393e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003940:	04451783          	lh	a5,68(a0)
    80003944:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003948:	04a51783          	lh	a5,74(a0)
    8000394c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003950:	04c56783          	lwu	a5,76(a0)
    80003954:	e99c                	sd	a5,16(a1)
}
    80003956:	6422                	ld	s0,8(sp)
    80003958:	0141                	addi	sp,sp,16
    8000395a:	8082                	ret

000000008000395c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000395c:	457c                	lw	a5,76(a0)
    8000395e:	0ed7e963          	bltu	a5,a3,80003a50 <readi+0xf4>
{
    80003962:	7159                	addi	sp,sp,-112
    80003964:	f486                	sd	ra,104(sp)
    80003966:	f0a2                	sd	s0,96(sp)
    80003968:	eca6                	sd	s1,88(sp)
    8000396a:	e8ca                	sd	s2,80(sp)
    8000396c:	e4ce                	sd	s3,72(sp)
    8000396e:	e0d2                	sd	s4,64(sp)
    80003970:	fc56                	sd	s5,56(sp)
    80003972:	f85a                	sd	s6,48(sp)
    80003974:	f45e                	sd	s7,40(sp)
    80003976:	f062                	sd	s8,32(sp)
    80003978:	ec66                	sd	s9,24(sp)
    8000397a:	e86a                	sd	s10,16(sp)
    8000397c:	e46e                	sd	s11,8(sp)
    8000397e:	1880                	addi	s0,sp,112
    80003980:	8b2a                	mv	s6,a0
    80003982:	8bae                	mv	s7,a1
    80003984:	8a32                	mv	s4,a2
    80003986:	84b6                	mv	s1,a3
    80003988:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000398a:	9f35                	addw	a4,a4,a3
    return 0;
    8000398c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000398e:	0ad76063          	bltu	a4,a3,80003a2e <readi+0xd2>
  if(off + n > ip->size)
    80003992:	00e7f463          	bgeu	a5,a4,8000399a <readi+0x3e>
    n = ip->size - off;
    80003996:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000399a:	0a0a8963          	beqz	s5,80003a4c <readi+0xf0>
    8000399e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039a4:	5c7d                	li	s8,-1
    800039a6:	a82d                	j	800039e0 <readi+0x84>
    800039a8:	020d1d93          	slli	s11,s10,0x20
    800039ac:	020ddd93          	srli	s11,s11,0x20
    800039b0:	05890613          	addi	a2,s2,88
    800039b4:	86ee                	mv	a3,s11
    800039b6:	963a                	add	a2,a2,a4
    800039b8:	85d2                	mv	a1,s4
    800039ba:	855e                	mv	a0,s7
    800039bc:	fffff097          	auipc	ra,0xfffff
    800039c0:	b18080e7          	jalr	-1256(ra) # 800024d4 <either_copyout>
    800039c4:	05850d63          	beq	a0,s8,80003a1e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039c8:	854a                	mv	a0,s2
    800039ca:	fffff097          	auipc	ra,0xfffff
    800039ce:	5f6080e7          	jalr	1526(ra) # 80002fc0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d2:	013d09bb          	addw	s3,s10,s3
    800039d6:	009d04bb          	addw	s1,s10,s1
    800039da:	9a6e                	add	s4,s4,s11
    800039dc:	0559f763          	bgeu	s3,s5,80003a2a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800039e0:	00a4d59b          	srliw	a1,s1,0xa
    800039e4:	855a                	mv	a0,s6
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	89e080e7          	jalr	-1890(ra) # 80003284 <bmap>
    800039ee:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039f2:	cd85                	beqz	a1,80003a2a <readi+0xce>
    bp = bread(ip->dev, addr);
    800039f4:	000b2503          	lw	a0,0(s6)
    800039f8:	fffff097          	auipc	ra,0xfffff
    800039fc:	498080e7          	jalr	1176(ra) # 80002e90 <bread>
    80003a00:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a02:	3ff4f713          	andi	a4,s1,1023
    80003a06:	40ec87bb          	subw	a5,s9,a4
    80003a0a:	413a86bb          	subw	a3,s5,s3
    80003a0e:	8d3e                	mv	s10,a5
    80003a10:	2781                	sext.w	a5,a5
    80003a12:	0006861b          	sext.w	a2,a3
    80003a16:	f8f679e3          	bgeu	a2,a5,800039a8 <readi+0x4c>
    80003a1a:	8d36                	mv	s10,a3
    80003a1c:	b771                	j	800039a8 <readi+0x4c>
      brelse(bp);
    80003a1e:	854a                	mv	a0,s2
    80003a20:	fffff097          	auipc	ra,0xfffff
    80003a24:	5a0080e7          	jalr	1440(ra) # 80002fc0 <brelse>
      tot = -1;
    80003a28:	59fd                	li	s3,-1
  }
  return tot;
    80003a2a:	0009851b          	sext.w	a0,s3
}
    80003a2e:	70a6                	ld	ra,104(sp)
    80003a30:	7406                	ld	s0,96(sp)
    80003a32:	64e6                	ld	s1,88(sp)
    80003a34:	6946                	ld	s2,80(sp)
    80003a36:	69a6                	ld	s3,72(sp)
    80003a38:	6a06                	ld	s4,64(sp)
    80003a3a:	7ae2                	ld	s5,56(sp)
    80003a3c:	7b42                	ld	s6,48(sp)
    80003a3e:	7ba2                	ld	s7,40(sp)
    80003a40:	7c02                	ld	s8,32(sp)
    80003a42:	6ce2                	ld	s9,24(sp)
    80003a44:	6d42                	ld	s10,16(sp)
    80003a46:	6da2                	ld	s11,8(sp)
    80003a48:	6165                	addi	sp,sp,112
    80003a4a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4c:	89d6                	mv	s3,s5
    80003a4e:	bff1                	j	80003a2a <readi+0xce>
    return 0;
    80003a50:	4501                	li	a0,0
}
    80003a52:	8082                	ret

0000000080003a54 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a54:	457c                	lw	a5,76(a0)
    80003a56:	10d7e863          	bltu	a5,a3,80003b66 <writei+0x112>
{
    80003a5a:	7159                	addi	sp,sp,-112
    80003a5c:	f486                	sd	ra,104(sp)
    80003a5e:	f0a2                	sd	s0,96(sp)
    80003a60:	eca6                	sd	s1,88(sp)
    80003a62:	e8ca                	sd	s2,80(sp)
    80003a64:	e4ce                	sd	s3,72(sp)
    80003a66:	e0d2                	sd	s4,64(sp)
    80003a68:	fc56                	sd	s5,56(sp)
    80003a6a:	f85a                	sd	s6,48(sp)
    80003a6c:	f45e                	sd	s7,40(sp)
    80003a6e:	f062                	sd	s8,32(sp)
    80003a70:	ec66                	sd	s9,24(sp)
    80003a72:	e86a                	sd	s10,16(sp)
    80003a74:	e46e                	sd	s11,8(sp)
    80003a76:	1880                	addi	s0,sp,112
    80003a78:	8aaa                	mv	s5,a0
    80003a7a:	8bae                	mv	s7,a1
    80003a7c:	8a32                	mv	s4,a2
    80003a7e:	8936                	mv	s2,a3
    80003a80:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a82:	00e687bb          	addw	a5,a3,a4
    80003a86:	0ed7e263          	bltu	a5,a3,80003b6a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a8a:	00043737          	lui	a4,0x43
    80003a8e:	0ef76063          	bltu	a4,a5,80003b6e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a92:	0c0b0863          	beqz	s6,80003b62 <writei+0x10e>
    80003a96:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a98:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a9c:	5c7d                	li	s8,-1
    80003a9e:	a091                	j	80003ae2 <writei+0x8e>
    80003aa0:	020d1d93          	slli	s11,s10,0x20
    80003aa4:	020ddd93          	srli	s11,s11,0x20
    80003aa8:	05848513          	addi	a0,s1,88
    80003aac:	86ee                	mv	a3,s11
    80003aae:	8652                	mv	a2,s4
    80003ab0:	85de                	mv	a1,s7
    80003ab2:	953a                	add	a0,a0,a4
    80003ab4:	fffff097          	auipc	ra,0xfffff
    80003ab8:	a76080e7          	jalr	-1418(ra) # 8000252a <either_copyin>
    80003abc:	07850263          	beq	a0,s8,80003b20 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	788080e7          	jalr	1928(ra) # 8000424a <log_write>
    brelse(bp);
    80003aca:	8526                	mv	a0,s1
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	4f4080e7          	jalr	1268(ra) # 80002fc0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad4:	013d09bb          	addw	s3,s10,s3
    80003ad8:	012d093b          	addw	s2,s10,s2
    80003adc:	9a6e                	add	s4,s4,s11
    80003ade:	0569f663          	bgeu	s3,s6,80003b2a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ae2:	00a9559b          	srliw	a1,s2,0xa
    80003ae6:	8556                	mv	a0,s5
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	79c080e7          	jalr	1948(ra) # 80003284 <bmap>
    80003af0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003af4:	c99d                	beqz	a1,80003b2a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003af6:	000aa503          	lw	a0,0(s5)
    80003afa:	fffff097          	auipc	ra,0xfffff
    80003afe:	396080e7          	jalr	918(ra) # 80002e90 <bread>
    80003b02:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b04:	3ff97713          	andi	a4,s2,1023
    80003b08:	40ec87bb          	subw	a5,s9,a4
    80003b0c:	413b06bb          	subw	a3,s6,s3
    80003b10:	8d3e                	mv	s10,a5
    80003b12:	2781                	sext.w	a5,a5
    80003b14:	0006861b          	sext.w	a2,a3
    80003b18:	f8f674e3          	bgeu	a2,a5,80003aa0 <writei+0x4c>
    80003b1c:	8d36                	mv	s10,a3
    80003b1e:	b749                	j	80003aa0 <writei+0x4c>
      brelse(bp);
    80003b20:	8526                	mv	a0,s1
    80003b22:	fffff097          	auipc	ra,0xfffff
    80003b26:	49e080e7          	jalr	1182(ra) # 80002fc0 <brelse>
  }

  if(off > ip->size)
    80003b2a:	04caa783          	lw	a5,76(s5)
    80003b2e:	0127f463          	bgeu	a5,s2,80003b36 <writei+0xe2>
    ip->size = off;
    80003b32:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b36:	8556                	mv	a0,s5
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	aa4080e7          	jalr	-1372(ra) # 800035dc <iupdate>

  return tot;
    80003b40:	0009851b          	sext.w	a0,s3
}
    80003b44:	70a6                	ld	ra,104(sp)
    80003b46:	7406                	ld	s0,96(sp)
    80003b48:	64e6                	ld	s1,88(sp)
    80003b4a:	6946                	ld	s2,80(sp)
    80003b4c:	69a6                	ld	s3,72(sp)
    80003b4e:	6a06                	ld	s4,64(sp)
    80003b50:	7ae2                	ld	s5,56(sp)
    80003b52:	7b42                	ld	s6,48(sp)
    80003b54:	7ba2                	ld	s7,40(sp)
    80003b56:	7c02                	ld	s8,32(sp)
    80003b58:	6ce2                	ld	s9,24(sp)
    80003b5a:	6d42                	ld	s10,16(sp)
    80003b5c:	6da2                	ld	s11,8(sp)
    80003b5e:	6165                	addi	sp,sp,112
    80003b60:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b62:	89da                	mv	s3,s6
    80003b64:	bfc9                	j	80003b36 <writei+0xe2>
    return -1;
    80003b66:	557d                	li	a0,-1
}
    80003b68:	8082                	ret
    return -1;
    80003b6a:	557d                	li	a0,-1
    80003b6c:	bfe1                	j	80003b44 <writei+0xf0>
    return -1;
    80003b6e:	557d                	li	a0,-1
    80003b70:	bfd1                	j	80003b44 <writei+0xf0>

0000000080003b72 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b72:	1141                	addi	sp,sp,-16
    80003b74:	e406                	sd	ra,8(sp)
    80003b76:	e022                	sd	s0,0(sp)
    80003b78:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b7a:	4639                	li	a2,14
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	226080e7          	jalr	550(ra) # 80000da2 <strncmp>
}
    80003b84:	60a2                	ld	ra,8(sp)
    80003b86:	6402                	ld	s0,0(sp)
    80003b88:	0141                	addi	sp,sp,16
    80003b8a:	8082                	ret

0000000080003b8c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b8c:	7139                	addi	sp,sp,-64
    80003b8e:	fc06                	sd	ra,56(sp)
    80003b90:	f822                	sd	s0,48(sp)
    80003b92:	f426                	sd	s1,40(sp)
    80003b94:	f04a                	sd	s2,32(sp)
    80003b96:	ec4e                	sd	s3,24(sp)
    80003b98:	e852                	sd	s4,16(sp)
    80003b9a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b9c:	04451703          	lh	a4,68(a0)
    80003ba0:	4785                	li	a5,1
    80003ba2:	00f71a63          	bne	a4,a5,80003bb6 <dirlookup+0x2a>
    80003ba6:	892a                	mv	s2,a0
    80003ba8:	89ae                	mv	s3,a1
    80003baa:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bac:	457c                	lw	a5,76(a0)
    80003bae:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bb0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bb2:	e79d                	bnez	a5,80003be0 <dirlookup+0x54>
    80003bb4:	a8a5                	j	80003c2c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bb6:	00005517          	auipc	a0,0x5
    80003bba:	a3a50513          	addi	a0,a0,-1478 # 800085f0 <syscalls+0x1a0>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	982080e7          	jalr	-1662(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003bc6:	00005517          	auipc	a0,0x5
    80003bca:	a4250513          	addi	a0,a0,-1470 # 80008608 <syscalls+0x1b8>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	972080e7          	jalr	-1678(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bd6:	24c1                	addiw	s1,s1,16
    80003bd8:	04c92783          	lw	a5,76(s2)
    80003bdc:	04f4f763          	bgeu	s1,a5,80003c2a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003be0:	4741                	li	a4,16
    80003be2:	86a6                	mv	a3,s1
    80003be4:	fc040613          	addi	a2,s0,-64
    80003be8:	4581                	li	a1,0
    80003bea:	854a                	mv	a0,s2
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	d70080e7          	jalr	-656(ra) # 8000395c <readi>
    80003bf4:	47c1                	li	a5,16
    80003bf6:	fcf518e3          	bne	a0,a5,80003bc6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bfa:	fc045783          	lhu	a5,-64(s0)
    80003bfe:	dfe1                	beqz	a5,80003bd6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c00:	fc240593          	addi	a1,s0,-62
    80003c04:	854e                	mv	a0,s3
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	f6c080e7          	jalr	-148(ra) # 80003b72 <namecmp>
    80003c0e:	f561                	bnez	a0,80003bd6 <dirlookup+0x4a>
      if(poff)
    80003c10:	000a0463          	beqz	s4,80003c18 <dirlookup+0x8c>
        *poff = off;
    80003c14:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c18:	fc045583          	lhu	a1,-64(s0)
    80003c1c:	00092503          	lw	a0,0(s2)
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	74e080e7          	jalr	1870(ra) # 8000336e <iget>
    80003c28:	a011                	j	80003c2c <dirlookup+0xa0>
  return 0;
    80003c2a:	4501                	li	a0,0
}
    80003c2c:	70e2                	ld	ra,56(sp)
    80003c2e:	7442                	ld	s0,48(sp)
    80003c30:	74a2                	ld	s1,40(sp)
    80003c32:	7902                	ld	s2,32(sp)
    80003c34:	69e2                	ld	s3,24(sp)
    80003c36:	6a42                	ld	s4,16(sp)
    80003c38:	6121                	addi	sp,sp,64
    80003c3a:	8082                	ret

0000000080003c3c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c3c:	711d                	addi	sp,sp,-96
    80003c3e:	ec86                	sd	ra,88(sp)
    80003c40:	e8a2                	sd	s0,80(sp)
    80003c42:	e4a6                	sd	s1,72(sp)
    80003c44:	e0ca                	sd	s2,64(sp)
    80003c46:	fc4e                	sd	s3,56(sp)
    80003c48:	f852                	sd	s4,48(sp)
    80003c4a:	f456                	sd	s5,40(sp)
    80003c4c:	f05a                	sd	s6,32(sp)
    80003c4e:	ec5e                	sd	s7,24(sp)
    80003c50:	e862                	sd	s8,16(sp)
    80003c52:	e466                	sd	s9,8(sp)
    80003c54:	e06a                	sd	s10,0(sp)
    80003c56:	1080                	addi	s0,sp,96
    80003c58:	84aa                	mv	s1,a0
    80003c5a:	8b2e                	mv	s6,a1
    80003c5c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c5e:	00054703          	lbu	a4,0(a0)
    80003c62:	02f00793          	li	a5,47
    80003c66:	02f70363          	beq	a4,a5,80003c8c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c6a:	ffffe097          	auipc	ra,0xffffe
    80003c6e:	d4a080e7          	jalr	-694(ra) # 800019b4 <myproc>
    80003c72:	15053503          	ld	a0,336(a0)
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	9f4080e7          	jalr	-1548(ra) # 8000366a <idup>
    80003c7e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c80:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c84:	4cb5                	li	s9,13
  len = path - s;
    80003c86:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c88:	4c05                	li	s8,1
    80003c8a:	a87d                	j	80003d48 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c8c:	4585                	li	a1,1
    80003c8e:	4505                	li	a0,1
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	6de080e7          	jalr	1758(ra) # 8000336e <iget>
    80003c98:	8a2a                	mv	s4,a0
    80003c9a:	b7dd                	j	80003c80 <namex+0x44>
      iunlockput(ip);
    80003c9c:	8552                	mv	a0,s4
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	c6c080e7          	jalr	-916(ra) # 8000390a <iunlockput>
      return 0;
    80003ca6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ca8:	8552                	mv	a0,s4
    80003caa:	60e6                	ld	ra,88(sp)
    80003cac:	6446                	ld	s0,80(sp)
    80003cae:	64a6                	ld	s1,72(sp)
    80003cb0:	6906                	ld	s2,64(sp)
    80003cb2:	79e2                	ld	s3,56(sp)
    80003cb4:	7a42                	ld	s4,48(sp)
    80003cb6:	7aa2                	ld	s5,40(sp)
    80003cb8:	7b02                	ld	s6,32(sp)
    80003cba:	6be2                	ld	s7,24(sp)
    80003cbc:	6c42                	ld	s8,16(sp)
    80003cbe:	6ca2                	ld	s9,8(sp)
    80003cc0:	6d02                	ld	s10,0(sp)
    80003cc2:	6125                	addi	sp,sp,96
    80003cc4:	8082                	ret
      iunlock(ip);
    80003cc6:	8552                	mv	a0,s4
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	aa2080e7          	jalr	-1374(ra) # 8000376a <iunlock>
      return ip;
    80003cd0:	bfe1                	j	80003ca8 <namex+0x6c>
      iunlockput(ip);
    80003cd2:	8552                	mv	a0,s4
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	c36080e7          	jalr	-970(ra) # 8000390a <iunlockput>
      return 0;
    80003cdc:	8a4e                	mv	s4,s3
    80003cde:	b7e9                	j	80003ca8 <namex+0x6c>
  len = path - s;
    80003ce0:	40998633          	sub	a2,s3,s1
    80003ce4:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003ce8:	09acd863          	bge	s9,s10,80003d78 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003cec:	4639                	li	a2,14
    80003cee:	85a6                	mv	a1,s1
    80003cf0:	8556                	mv	a0,s5
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	03c080e7          	jalr	60(ra) # 80000d2e <memmove>
    80003cfa:	84ce                	mv	s1,s3
  while(*path == '/')
    80003cfc:	0004c783          	lbu	a5,0(s1)
    80003d00:	01279763          	bne	a5,s2,80003d0e <namex+0xd2>
    path++;
    80003d04:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d06:	0004c783          	lbu	a5,0(s1)
    80003d0a:	ff278de3          	beq	a5,s2,80003d04 <namex+0xc8>
    ilock(ip);
    80003d0e:	8552                	mv	a0,s4
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	998080e7          	jalr	-1640(ra) # 800036a8 <ilock>
    if(ip->type != T_DIR){
    80003d18:	044a1783          	lh	a5,68(s4)
    80003d1c:	f98790e3          	bne	a5,s8,80003c9c <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d20:	000b0563          	beqz	s6,80003d2a <namex+0xee>
    80003d24:	0004c783          	lbu	a5,0(s1)
    80003d28:	dfd9                	beqz	a5,80003cc6 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d2a:	865e                	mv	a2,s7
    80003d2c:	85d6                	mv	a1,s5
    80003d2e:	8552                	mv	a0,s4
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	e5c080e7          	jalr	-420(ra) # 80003b8c <dirlookup>
    80003d38:	89aa                	mv	s3,a0
    80003d3a:	dd41                	beqz	a0,80003cd2 <namex+0x96>
    iunlockput(ip);
    80003d3c:	8552                	mv	a0,s4
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	bcc080e7          	jalr	-1076(ra) # 8000390a <iunlockput>
    ip = next;
    80003d46:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d48:	0004c783          	lbu	a5,0(s1)
    80003d4c:	01279763          	bne	a5,s2,80003d5a <namex+0x11e>
    path++;
    80003d50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d52:	0004c783          	lbu	a5,0(s1)
    80003d56:	ff278de3          	beq	a5,s2,80003d50 <namex+0x114>
  if(*path == 0)
    80003d5a:	cb9d                	beqz	a5,80003d90 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d5c:	0004c783          	lbu	a5,0(s1)
    80003d60:	89a6                	mv	s3,s1
  len = path - s;
    80003d62:	8d5e                	mv	s10,s7
    80003d64:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d66:	01278963          	beq	a5,s2,80003d78 <namex+0x13c>
    80003d6a:	dbbd                	beqz	a5,80003ce0 <namex+0xa4>
    path++;
    80003d6c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d6e:	0009c783          	lbu	a5,0(s3)
    80003d72:	ff279ce3          	bne	a5,s2,80003d6a <namex+0x12e>
    80003d76:	b7ad                	j	80003ce0 <namex+0xa4>
    memmove(name, s, len);
    80003d78:	2601                	sext.w	a2,a2
    80003d7a:	85a6                	mv	a1,s1
    80003d7c:	8556                	mv	a0,s5
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	fb0080e7          	jalr	-80(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003d86:	9d56                	add	s10,s10,s5
    80003d88:	000d0023          	sb	zero,0(s10)
    80003d8c:	84ce                	mv	s1,s3
    80003d8e:	b7bd                	j	80003cfc <namex+0xc0>
  if(nameiparent){
    80003d90:	f00b0ce3          	beqz	s6,80003ca8 <namex+0x6c>
    iput(ip);
    80003d94:	8552                	mv	a0,s4
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	acc080e7          	jalr	-1332(ra) # 80003862 <iput>
    return 0;
    80003d9e:	4a01                	li	s4,0
    80003da0:	b721                	j	80003ca8 <namex+0x6c>

0000000080003da2 <dirlink>:
{
    80003da2:	7139                	addi	sp,sp,-64
    80003da4:	fc06                	sd	ra,56(sp)
    80003da6:	f822                	sd	s0,48(sp)
    80003da8:	f426                	sd	s1,40(sp)
    80003daa:	f04a                	sd	s2,32(sp)
    80003dac:	ec4e                	sd	s3,24(sp)
    80003dae:	e852                	sd	s4,16(sp)
    80003db0:	0080                	addi	s0,sp,64
    80003db2:	892a                	mv	s2,a0
    80003db4:	8a2e                	mv	s4,a1
    80003db6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003db8:	4601                	li	a2,0
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	dd2080e7          	jalr	-558(ra) # 80003b8c <dirlookup>
    80003dc2:	e93d                	bnez	a0,80003e38 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc4:	04c92483          	lw	s1,76(s2)
    80003dc8:	c49d                	beqz	s1,80003df6 <dirlink+0x54>
    80003dca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dcc:	4741                	li	a4,16
    80003dce:	86a6                	mv	a3,s1
    80003dd0:	fc040613          	addi	a2,s0,-64
    80003dd4:	4581                	li	a1,0
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	b84080e7          	jalr	-1148(ra) # 8000395c <readi>
    80003de0:	47c1                	li	a5,16
    80003de2:	06f51163          	bne	a0,a5,80003e44 <dirlink+0xa2>
    if(de.inum == 0)
    80003de6:	fc045783          	lhu	a5,-64(s0)
    80003dea:	c791                	beqz	a5,80003df6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dec:	24c1                	addiw	s1,s1,16
    80003dee:	04c92783          	lw	a5,76(s2)
    80003df2:	fcf4ede3          	bltu	s1,a5,80003dcc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003df6:	4639                	li	a2,14
    80003df8:	85d2                	mv	a1,s4
    80003dfa:	fc240513          	addi	a0,s0,-62
    80003dfe:	ffffd097          	auipc	ra,0xffffd
    80003e02:	fe0080e7          	jalr	-32(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003e06:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0a:	4741                	li	a4,16
    80003e0c:	86a6                	mv	a3,s1
    80003e0e:	fc040613          	addi	a2,s0,-64
    80003e12:	4581                	li	a1,0
    80003e14:	854a                	mv	a0,s2
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	c3e080e7          	jalr	-962(ra) # 80003a54 <writei>
    80003e1e:	1541                	addi	a0,a0,-16
    80003e20:	00a03533          	snez	a0,a0
    80003e24:	40a00533          	neg	a0,a0
}
    80003e28:	70e2                	ld	ra,56(sp)
    80003e2a:	7442                	ld	s0,48(sp)
    80003e2c:	74a2                	ld	s1,40(sp)
    80003e2e:	7902                	ld	s2,32(sp)
    80003e30:	69e2                	ld	s3,24(sp)
    80003e32:	6a42                	ld	s4,16(sp)
    80003e34:	6121                	addi	sp,sp,64
    80003e36:	8082                	ret
    iput(ip);
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	a2a080e7          	jalr	-1494(ra) # 80003862 <iput>
    return -1;
    80003e40:	557d                	li	a0,-1
    80003e42:	b7dd                	j	80003e28 <dirlink+0x86>
      panic("dirlink read");
    80003e44:	00004517          	auipc	a0,0x4
    80003e48:	7d450513          	addi	a0,a0,2004 # 80008618 <syscalls+0x1c8>
    80003e4c:	ffffc097          	auipc	ra,0xffffc
    80003e50:	6f4080e7          	jalr	1780(ra) # 80000540 <panic>

0000000080003e54 <namei>:

struct inode*
namei(char *path)
{
    80003e54:	1101                	addi	sp,sp,-32
    80003e56:	ec06                	sd	ra,24(sp)
    80003e58:	e822                	sd	s0,16(sp)
    80003e5a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e5c:	fe040613          	addi	a2,s0,-32
    80003e60:	4581                	li	a1,0
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	dda080e7          	jalr	-550(ra) # 80003c3c <namex>
}
    80003e6a:	60e2                	ld	ra,24(sp)
    80003e6c:	6442                	ld	s0,16(sp)
    80003e6e:	6105                	addi	sp,sp,32
    80003e70:	8082                	ret

0000000080003e72 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e72:	1141                	addi	sp,sp,-16
    80003e74:	e406                	sd	ra,8(sp)
    80003e76:	e022                	sd	s0,0(sp)
    80003e78:	0800                	addi	s0,sp,16
    80003e7a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e7c:	4585                	li	a1,1
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	dbe080e7          	jalr	-578(ra) # 80003c3c <namex>
}
    80003e86:	60a2                	ld	ra,8(sp)
    80003e88:	6402                	ld	s0,0(sp)
    80003e8a:	0141                	addi	sp,sp,16
    80003e8c:	8082                	ret

0000000080003e8e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e8e:	1101                	addi	sp,sp,-32
    80003e90:	ec06                	sd	ra,24(sp)
    80003e92:	e822                	sd	s0,16(sp)
    80003e94:	e426                	sd	s1,8(sp)
    80003e96:	e04a                	sd	s2,0(sp)
    80003e98:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e9a:	0001d917          	auipc	s2,0x1d
    80003e9e:	e8690913          	addi	s2,s2,-378 # 80020d20 <log>
    80003ea2:	01892583          	lw	a1,24(s2)
    80003ea6:	02892503          	lw	a0,40(s2)
    80003eaa:	fffff097          	auipc	ra,0xfffff
    80003eae:	fe6080e7          	jalr	-26(ra) # 80002e90 <bread>
    80003eb2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eb4:	02c92683          	lw	a3,44(s2)
    80003eb8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eba:	02d05863          	blez	a3,80003eea <write_head+0x5c>
    80003ebe:	0001d797          	auipc	a5,0x1d
    80003ec2:	e9278793          	addi	a5,a5,-366 # 80020d50 <log+0x30>
    80003ec6:	05c50713          	addi	a4,a0,92
    80003eca:	36fd                	addiw	a3,a3,-1
    80003ecc:	02069613          	slli	a2,a3,0x20
    80003ed0:	01e65693          	srli	a3,a2,0x1e
    80003ed4:	0001d617          	auipc	a2,0x1d
    80003ed8:	e8060613          	addi	a2,a2,-384 # 80020d54 <log+0x34>
    80003edc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ede:	4390                	lw	a2,0(a5)
    80003ee0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ee2:	0791                	addi	a5,a5,4
    80003ee4:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003ee6:	fed79ce3          	bne	a5,a3,80003ede <write_head+0x50>
  }
  bwrite(buf);
    80003eea:	8526                	mv	a0,s1
    80003eec:	fffff097          	auipc	ra,0xfffff
    80003ef0:	096080e7          	jalr	150(ra) # 80002f82 <bwrite>
  brelse(buf);
    80003ef4:	8526                	mv	a0,s1
    80003ef6:	fffff097          	auipc	ra,0xfffff
    80003efa:	0ca080e7          	jalr	202(ra) # 80002fc0 <brelse>
}
    80003efe:	60e2                	ld	ra,24(sp)
    80003f00:	6442                	ld	s0,16(sp)
    80003f02:	64a2                	ld	s1,8(sp)
    80003f04:	6902                	ld	s2,0(sp)
    80003f06:	6105                	addi	sp,sp,32
    80003f08:	8082                	ret

0000000080003f0a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f0a:	0001d797          	auipc	a5,0x1d
    80003f0e:	e427a783          	lw	a5,-446(a5) # 80020d4c <log+0x2c>
    80003f12:	0af05d63          	blez	a5,80003fcc <install_trans+0xc2>
{
    80003f16:	7139                	addi	sp,sp,-64
    80003f18:	fc06                	sd	ra,56(sp)
    80003f1a:	f822                	sd	s0,48(sp)
    80003f1c:	f426                	sd	s1,40(sp)
    80003f1e:	f04a                	sd	s2,32(sp)
    80003f20:	ec4e                	sd	s3,24(sp)
    80003f22:	e852                	sd	s4,16(sp)
    80003f24:	e456                	sd	s5,8(sp)
    80003f26:	e05a                	sd	s6,0(sp)
    80003f28:	0080                	addi	s0,sp,64
    80003f2a:	8b2a                	mv	s6,a0
    80003f2c:	0001da97          	auipc	s5,0x1d
    80003f30:	e24a8a93          	addi	s5,s5,-476 # 80020d50 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f34:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f36:	0001d997          	auipc	s3,0x1d
    80003f3a:	dea98993          	addi	s3,s3,-534 # 80020d20 <log>
    80003f3e:	a00d                	j	80003f60 <install_trans+0x56>
    brelse(lbuf);
    80003f40:	854a                	mv	a0,s2
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	07e080e7          	jalr	126(ra) # 80002fc0 <brelse>
    brelse(dbuf);
    80003f4a:	8526                	mv	a0,s1
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	074080e7          	jalr	116(ra) # 80002fc0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f54:	2a05                	addiw	s4,s4,1
    80003f56:	0a91                	addi	s5,s5,4
    80003f58:	02c9a783          	lw	a5,44(s3)
    80003f5c:	04fa5e63          	bge	s4,a5,80003fb8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f60:	0189a583          	lw	a1,24(s3)
    80003f64:	014585bb          	addw	a1,a1,s4
    80003f68:	2585                	addiw	a1,a1,1
    80003f6a:	0289a503          	lw	a0,40(s3)
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	f22080e7          	jalr	-222(ra) # 80002e90 <bread>
    80003f76:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f78:	000aa583          	lw	a1,0(s5)
    80003f7c:	0289a503          	lw	a0,40(s3)
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	f10080e7          	jalr	-240(ra) # 80002e90 <bread>
    80003f88:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f8a:	40000613          	li	a2,1024
    80003f8e:	05890593          	addi	a1,s2,88
    80003f92:	05850513          	addi	a0,a0,88
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	d98080e7          	jalr	-616(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f9e:	8526                	mv	a0,s1
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	fe2080e7          	jalr	-30(ra) # 80002f82 <bwrite>
    if(recovering == 0)
    80003fa8:	f80b1ce3          	bnez	s6,80003f40 <install_trans+0x36>
      bunpin(dbuf);
    80003fac:	8526                	mv	a0,s1
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	0ec080e7          	jalr	236(ra) # 8000309a <bunpin>
    80003fb6:	b769                	j	80003f40 <install_trans+0x36>
}
    80003fb8:	70e2                	ld	ra,56(sp)
    80003fba:	7442                	ld	s0,48(sp)
    80003fbc:	74a2                	ld	s1,40(sp)
    80003fbe:	7902                	ld	s2,32(sp)
    80003fc0:	69e2                	ld	s3,24(sp)
    80003fc2:	6a42                	ld	s4,16(sp)
    80003fc4:	6aa2                	ld	s5,8(sp)
    80003fc6:	6b02                	ld	s6,0(sp)
    80003fc8:	6121                	addi	sp,sp,64
    80003fca:	8082                	ret
    80003fcc:	8082                	ret

0000000080003fce <initlog>:
{
    80003fce:	7179                	addi	sp,sp,-48
    80003fd0:	f406                	sd	ra,40(sp)
    80003fd2:	f022                	sd	s0,32(sp)
    80003fd4:	ec26                	sd	s1,24(sp)
    80003fd6:	e84a                	sd	s2,16(sp)
    80003fd8:	e44e                	sd	s3,8(sp)
    80003fda:	1800                	addi	s0,sp,48
    80003fdc:	892a                	mv	s2,a0
    80003fde:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fe0:	0001d497          	auipc	s1,0x1d
    80003fe4:	d4048493          	addi	s1,s1,-704 # 80020d20 <log>
    80003fe8:	00004597          	auipc	a1,0x4
    80003fec:	64058593          	addi	a1,a1,1600 # 80008628 <syscalls+0x1d8>
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	ffffd097          	auipc	ra,0xffffd
    80003ff6:	b54080e7          	jalr	-1196(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003ffa:	0149a583          	lw	a1,20(s3)
    80003ffe:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004000:	0109a783          	lw	a5,16(s3)
    80004004:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004006:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000400a:	854a                	mv	a0,s2
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	e84080e7          	jalr	-380(ra) # 80002e90 <bread>
  log.lh.n = lh->n;
    80004014:	4d34                	lw	a3,88(a0)
    80004016:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004018:	02d05663          	blez	a3,80004044 <initlog+0x76>
    8000401c:	05c50793          	addi	a5,a0,92
    80004020:	0001d717          	auipc	a4,0x1d
    80004024:	d3070713          	addi	a4,a4,-720 # 80020d50 <log+0x30>
    80004028:	36fd                	addiw	a3,a3,-1
    8000402a:	02069613          	slli	a2,a3,0x20
    8000402e:	01e65693          	srli	a3,a2,0x1e
    80004032:	06050613          	addi	a2,a0,96
    80004036:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004038:	4390                	lw	a2,0(a5)
    8000403a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000403c:	0791                	addi	a5,a5,4
    8000403e:	0711                	addi	a4,a4,4
    80004040:	fed79ce3          	bne	a5,a3,80004038 <initlog+0x6a>
  brelse(buf);
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	f7c080e7          	jalr	-132(ra) # 80002fc0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000404c:	4505                	li	a0,1
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	ebc080e7          	jalr	-324(ra) # 80003f0a <install_trans>
  log.lh.n = 0;
    80004056:	0001d797          	auipc	a5,0x1d
    8000405a:	ce07ab23          	sw	zero,-778(a5) # 80020d4c <log+0x2c>
  write_head(); // clear the log
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	e30080e7          	jalr	-464(ra) # 80003e8e <write_head>
}
    80004066:	70a2                	ld	ra,40(sp)
    80004068:	7402                	ld	s0,32(sp)
    8000406a:	64e2                	ld	s1,24(sp)
    8000406c:	6942                	ld	s2,16(sp)
    8000406e:	69a2                	ld	s3,8(sp)
    80004070:	6145                	addi	sp,sp,48
    80004072:	8082                	ret

0000000080004074 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004074:	1101                	addi	sp,sp,-32
    80004076:	ec06                	sd	ra,24(sp)
    80004078:	e822                	sd	s0,16(sp)
    8000407a:	e426                	sd	s1,8(sp)
    8000407c:	e04a                	sd	s2,0(sp)
    8000407e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004080:	0001d517          	auipc	a0,0x1d
    80004084:	ca050513          	addi	a0,a0,-864 # 80020d20 <log>
    80004088:	ffffd097          	auipc	ra,0xffffd
    8000408c:	b4e080e7          	jalr	-1202(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004090:	0001d497          	auipc	s1,0x1d
    80004094:	c9048493          	addi	s1,s1,-880 # 80020d20 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004098:	4979                	li	s2,30
    8000409a:	a039                	j	800040a8 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000409c:	85a6                	mv	a1,s1
    8000409e:	8526                	mv	a0,s1
    800040a0:	ffffe097          	auipc	ra,0xffffe
    800040a4:	02c080e7          	jalr	44(ra) # 800020cc <sleep>
    if(log.committing){
    800040a8:	50dc                	lw	a5,36(s1)
    800040aa:	fbed                	bnez	a5,8000409c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ac:	5098                	lw	a4,32(s1)
    800040ae:	2705                	addiw	a4,a4,1
    800040b0:	0007069b          	sext.w	a3,a4
    800040b4:	0027179b          	slliw	a5,a4,0x2
    800040b8:	9fb9                	addw	a5,a5,a4
    800040ba:	0017979b          	slliw	a5,a5,0x1
    800040be:	54d8                	lw	a4,44(s1)
    800040c0:	9fb9                	addw	a5,a5,a4
    800040c2:	00f95963          	bge	s2,a5,800040d4 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040c6:	85a6                	mv	a1,s1
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffe097          	auipc	ra,0xffffe
    800040ce:	002080e7          	jalr	2(ra) # 800020cc <sleep>
    800040d2:	bfd9                	j	800040a8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040d4:	0001d517          	auipc	a0,0x1d
    800040d8:	c4c50513          	addi	a0,a0,-948 # 80020d20 <log>
    800040dc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	bac080e7          	jalr	-1108(ra) # 80000c8a <release>
      break;
    }
  }
}
    800040e6:	60e2                	ld	ra,24(sp)
    800040e8:	6442                	ld	s0,16(sp)
    800040ea:	64a2                	ld	s1,8(sp)
    800040ec:	6902                	ld	s2,0(sp)
    800040ee:	6105                	addi	sp,sp,32
    800040f0:	8082                	ret

00000000800040f2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040f2:	7139                	addi	sp,sp,-64
    800040f4:	fc06                	sd	ra,56(sp)
    800040f6:	f822                	sd	s0,48(sp)
    800040f8:	f426                	sd	s1,40(sp)
    800040fa:	f04a                	sd	s2,32(sp)
    800040fc:	ec4e                	sd	s3,24(sp)
    800040fe:	e852                	sd	s4,16(sp)
    80004100:	e456                	sd	s5,8(sp)
    80004102:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004104:	0001d497          	auipc	s1,0x1d
    80004108:	c1c48493          	addi	s1,s1,-996 # 80020d20 <log>
    8000410c:	8526                	mv	a0,s1
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	ac8080e7          	jalr	-1336(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004116:	509c                	lw	a5,32(s1)
    80004118:	37fd                	addiw	a5,a5,-1
    8000411a:	0007891b          	sext.w	s2,a5
    8000411e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004120:	50dc                	lw	a5,36(s1)
    80004122:	e7b9                	bnez	a5,80004170 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004124:	04091e63          	bnez	s2,80004180 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004128:	0001d497          	auipc	s1,0x1d
    8000412c:	bf848493          	addi	s1,s1,-1032 # 80020d20 <log>
    80004130:	4785                	li	a5,1
    80004132:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004134:	8526                	mv	a0,s1
    80004136:	ffffd097          	auipc	ra,0xffffd
    8000413a:	b54080e7          	jalr	-1196(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000413e:	54dc                	lw	a5,44(s1)
    80004140:	06f04763          	bgtz	a5,800041ae <end_op+0xbc>
    acquire(&log.lock);
    80004144:	0001d497          	auipc	s1,0x1d
    80004148:	bdc48493          	addi	s1,s1,-1060 # 80020d20 <log>
    8000414c:	8526                	mv	a0,s1
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	a88080e7          	jalr	-1400(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004156:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000415a:	8526                	mv	a0,s1
    8000415c:	ffffe097          	auipc	ra,0xffffe
    80004160:	fd4080e7          	jalr	-44(ra) # 80002130 <wakeup>
    release(&log.lock);
    80004164:	8526                	mv	a0,s1
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	b24080e7          	jalr	-1244(ra) # 80000c8a <release>
}
    8000416e:	a03d                	j	8000419c <end_op+0xaa>
    panic("log.committing");
    80004170:	00004517          	auipc	a0,0x4
    80004174:	4c050513          	addi	a0,a0,1216 # 80008630 <syscalls+0x1e0>
    80004178:	ffffc097          	auipc	ra,0xffffc
    8000417c:	3c8080e7          	jalr	968(ra) # 80000540 <panic>
    wakeup(&log);
    80004180:	0001d497          	auipc	s1,0x1d
    80004184:	ba048493          	addi	s1,s1,-1120 # 80020d20 <log>
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffe097          	auipc	ra,0xffffe
    8000418e:	fa6080e7          	jalr	-90(ra) # 80002130 <wakeup>
  release(&log.lock);
    80004192:	8526                	mv	a0,s1
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	af6080e7          	jalr	-1290(ra) # 80000c8a <release>
}
    8000419c:	70e2                	ld	ra,56(sp)
    8000419e:	7442                	ld	s0,48(sp)
    800041a0:	74a2                	ld	s1,40(sp)
    800041a2:	7902                	ld	s2,32(sp)
    800041a4:	69e2                	ld	s3,24(sp)
    800041a6:	6a42                	ld	s4,16(sp)
    800041a8:	6aa2                	ld	s5,8(sp)
    800041aa:	6121                	addi	sp,sp,64
    800041ac:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ae:	0001da97          	auipc	s5,0x1d
    800041b2:	ba2a8a93          	addi	s5,s5,-1118 # 80020d50 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041b6:	0001da17          	auipc	s4,0x1d
    800041ba:	b6aa0a13          	addi	s4,s4,-1174 # 80020d20 <log>
    800041be:	018a2583          	lw	a1,24(s4)
    800041c2:	012585bb          	addw	a1,a1,s2
    800041c6:	2585                	addiw	a1,a1,1
    800041c8:	028a2503          	lw	a0,40(s4)
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	cc4080e7          	jalr	-828(ra) # 80002e90 <bread>
    800041d4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041d6:	000aa583          	lw	a1,0(s5)
    800041da:	028a2503          	lw	a0,40(s4)
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	cb2080e7          	jalr	-846(ra) # 80002e90 <bread>
    800041e6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041e8:	40000613          	li	a2,1024
    800041ec:	05850593          	addi	a1,a0,88
    800041f0:	05848513          	addi	a0,s1,88
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	b3a080e7          	jalr	-1222(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800041fc:	8526                	mv	a0,s1
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	d84080e7          	jalr	-636(ra) # 80002f82 <bwrite>
    brelse(from);
    80004206:	854e                	mv	a0,s3
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	db8080e7          	jalr	-584(ra) # 80002fc0 <brelse>
    brelse(to);
    80004210:	8526                	mv	a0,s1
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	dae080e7          	jalr	-594(ra) # 80002fc0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000421a:	2905                	addiw	s2,s2,1
    8000421c:	0a91                	addi	s5,s5,4
    8000421e:	02ca2783          	lw	a5,44(s4)
    80004222:	f8f94ee3          	blt	s2,a5,800041be <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	c68080e7          	jalr	-920(ra) # 80003e8e <write_head>
    install_trans(0); // Now install writes to home locations
    8000422e:	4501                	li	a0,0
    80004230:	00000097          	auipc	ra,0x0
    80004234:	cda080e7          	jalr	-806(ra) # 80003f0a <install_trans>
    log.lh.n = 0;
    80004238:	0001d797          	auipc	a5,0x1d
    8000423c:	b007aa23          	sw	zero,-1260(a5) # 80020d4c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004240:	00000097          	auipc	ra,0x0
    80004244:	c4e080e7          	jalr	-946(ra) # 80003e8e <write_head>
    80004248:	bdf5                	j	80004144 <end_op+0x52>

000000008000424a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000424a:	1101                	addi	sp,sp,-32
    8000424c:	ec06                	sd	ra,24(sp)
    8000424e:	e822                	sd	s0,16(sp)
    80004250:	e426                	sd	s1,8(sp)
    80004252:	e04a                	sd	s2,0(sp)
    80004254:	1000                	addi	s0,sp,32
    80004256:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004258:	0001d917          	auipc	s2,0x1d
    8000425c:	ac890913          	addi	s2,s2,-1336 # 80020d20 <log>
    80004260:	854a                	mv	a0,s2
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	974080e7          	jalr	-1676(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000426a:	02c92603          	lw	a2,44(s2)
    8000426e:	47f5                	li	a5,29
    80004270:	06c7c563          	blt	a5,a2,800042da <log_write+0x90>
    80004274:	0001d797          	auipc	a5,0x1d
    80004278:	ac87a783          	lw	a5,-1336(a5) # 80020d3c <log+0x1c>
    8000427c:	37fd                	addiw	a5,a5,-1
    8000427e:	04f65e63          	bge	a2,a5,800042da <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004282:	0001d797          	auipc	a5,0x1d
    80004286:	abe7a783          	lw	a5,-1346(a5) # 80020d40 <log+0x20>
    8000428a:	06f05063          	blez	a5,800042ea <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000428e:	4781                	li	a5,0
    80004290:	06c05563          	blez	a2,800042fa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004294:	44cc                	lw	a1,12(s1)
    80004296:	0001d717          	auipc	a4,0x1d
    8000429a:	aba70713          	addi	a4,a4,-1350 # 80020d50 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000429e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042a0:	4314                	lw	a3,0(a4)
    800042a2:	04b68c63          	beq	a3,a1,800042fa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042a6:	2785                	addiw	a5,a5,1
    800042a8:	0711                	addi	a4,a4,4
    800042aa:	fef61be3          	bne	a2,a5,800042a0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ae:	0621                	addi	a2,a2,8
    800042b0:	060a                	slli	a2,a2,0x2
    800042b2:	0001d797          	auipc	a5,0x1d
    800042b6:	a6e78793          	addi	a5,a5,-1426 # 80020d20 <log>
    800042ba:	97b2                	add	a5,a5,a2
    800042bc:	44d8                	lw	a4,12(s1)
    800042be:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042c0:	8526                	mv	a0,s1
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	d9c080e7          	jalr	-612(ra) # 8000305e <bpin>
    log.lh.n++;
    800042ca:	0001d717          	auipc	a4,0x1d
    800042ce:	a5670713          	addi	a4,a4,-1450 # 80020d20 <log>
    800042d2:	575c                	lw	a5,44(a4)
    800042d4:	2785                	addiw	a5,a5,1
    800042d6:	d75c                	sw	a5,44(a4)
    800042d8:	a82d                	j	80004312 <log_write+0xc8>
    panic("too big a transaction");
    800042da:	00004517          	auipc	a0,0x4
    800042de:	36650513          	addi	a0,a0,870 # 80008640 <syscalls+0x1f0>
    800042e2:	ffffc097          	auipc	ra,0xffffc
    800042e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800042ea:	00004517          	auipc	a0,0x4
    800042ee:	36e50513          	addi	a0,a0,878 # 80008658 <syscalls+0x208>
    800042f2:	ffffc097          	auipc	ra,0xffffc
    800042f6:	24e080e7          	jalr	590(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800042fa:	00878693          	addi	a3,a5,8
    800042fe:	068a                	slli	a3,a3,0x2
    80004300:	0001d717          	auipc	a4,0x1d
    80004304:	a2070713          	addi	a4,a4,-1504 # 80020d20 <log>
    80004308:	9736                	add	a4,a4,a3
    8000430a:	44d4                	lw	a3,12(s1)
    8000430c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000430e:	faf609e3          	beq	a2,a5,800042c0 <log_write+0x76>
  }
  release(&log.lock);
    80004312:	0001d517          	auipc	a0,0x1d
    80004316:	a0e50513          	addi	a0,a0,-1522 # 80020d20 <log>
    8000431a:	ffffd097          	auipc	ra,0xffffd
    8000431e:	970080e7          	jalr	-1680(ra) # 80000c8a <release>
}
    80004322:	60e2                	ld	ra,24(sp)
    80004324:	6442                	ld	s0,16(sp)
    80004326:	64a2                	ld	s1,8(sp)
    80004328:	6902                	ld	s2,0(sp)
    8000432a:	6105                	addi	sp,sp,32
    8000432c:	8082                	ret

000000008000432e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000432e:	1101                	addi	sp,sp,-32
    80004330:	ec06                	sd	ra,24(sp)
    80004332:	e822                	sd	s0,16(sp)
    80004334:	e426                	sd	s1,8(sp)
    80004336:	e04a                	sd	s2,0(sp)
    80004338:	1000                	addi	s0,sp,32
    8000433a:	84aa                	mv	s1,a0
    8000433c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000433e:	00004597          	auipc	a1,0x4
    80004342:	33a58593          	addi	a1,a1,826 # 80008678 <syscalls+0x228>
    80004346:	0521                	addi	a0,a0,8
    80004348:	ffffc097          	auipc	ra,0xffffc
    8000434c:	7fe080e7          	jalr	2046(ra) # 80000b46 <initlock>
  lk->name = name;
    80004350:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004354:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004358:	0204a423          	sw	zero,40(s1)
}
    8000435c:	60e2                	ld	ra,24(sp)
    8000435e:	6442                	ld	s0,16(sp)
    80004360:	64a2                	ld	s1,8(sp)
    80004362:	6902                	ld	s2,0(sp)
    80004364:	6105                	addi	sp,sp,32
    80004366:	8082                	ret

0000000080004368 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004368:	1101                	addi	sp,sp,-32
    8000436a:	ec06                	sd	ra,24(sp)
    8000436c:	e822                	sd	s0,16(sp)
    8000436e:	e426                	sd	s1,8(sp)
    80004370:	e04a                	sd	s2,0(sp)
    80004372:	1000                	addi	s0,sp,32
    80004374:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004376:	00850913          	addi	s2,a0,8
    8000437a:	854a                	mv	a0,s2
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	85a080e7          	jalr	-1958(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004384:	409c                	lw	a5,0(s1)
    80004386:	cb89                	beqz	a5,80004398 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004388:	85ca                	mv	a1,s2
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffe097          	auipc	ra,0xffffe
    80004390:	d40080e7          	jalr	-704(ra) # 800020cc <sleep>
  while (lk->locked) {
    80004394:	409c                	lw	a5,0(s1)
    80004396:	fbed                	bnez	a5,80004388 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004398:	4785                	li	a5,1
    8000439a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	618080e7          	jalr	1560(ra) # 800019b4 <myproc>
    800043a4:	591c                	lw	a5,48(a0)
    800043a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043a8:	854a                	mv	a0,s2
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	8e0080e7          	jalr	-1824(ra) # 80000c8a <release>
}
    800043b2:	60e2                	ld	ra,24(sp)
    800043b4:	6442                	ld	s0,16(sp)
    800043b6:	64a2                	ld	s1,8(sp)
    800043b8:	6902                	ld	s2,0(sp)
    800043ba:	6105                	addi	sp,sp,32
    800043bc:	8082                	ret

00000000800043be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec06                	sd	ra,24(sp)
    800043c2:	e822                	sd	s0,16(sp)
    800043c4:	e426                	sd	s1,8(sp)
    800043c6:	e04a                	sd	s2,0(sp)
    800043c8:	1000                	addi	s0,sp,32
    800043ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043cc:	00850913          	addi	s2,a0,8
    800043d0:	854a                	mv	a0,s2
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	804080e7          	jalr	-2044(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800043da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043e2:	8526                	mv	a0,s1
    800043e4:	ffffe097          	auipc	ra,0xffffe
    800043e8:	d4c080e7          	jalr	-692(ra) # 80002130 <wakeup>
  release(&lk->lk);
    800043ec:	854a                	mv	a0,s2
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	89c080e7          	jalr	-1892(ra) # 80000c8a <release>
}
    800043f6:	60e2                	ld	ra,24(sp)
    800043f8:	6442                	ld	s0,16(sp)
    800043fa:	64a2                	ld	s1,8(sp)
    800043fc:	6902                	ld	s2,0(sp)
    800043fe:	6105                	addi	sp,sp,32
    80004400:	8082                	ret

0000000080004402 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004402:	7179                	addi	sp,sp,-48
    80004404:	f406                	sd	ra,40(sp)
    80004406:	f022                	sd	s0,32(sp)
    80004408:	ec26                	sd	s1,24(sp)
    8000440a:	e84a                	sd	s2,16(sp)
    8000440c:	e44e                	sd	s3,8(sp)
    8000440e:	1800                	addi	s0,sp,48
    80004410:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004412:	00850913          	addi	s2,a0,8
    80004416:	854a                	mv	a0,s2
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004420:	409c                	lw	a5,0(s1)
    80004422:	ef99                	bnez	a5,80004440 <holdingsleep+0x3e>
    80004424:	4481                	li	s1,0
  release(&lk->lk);
    80004426:	854a                	mv	a0,s2
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
  return r;
}
    80004430:	8526                	mv	a0,s1
    80004432:	70a2                	ld	ra,40(sp)
    80004434:	7402                	ld	s0,32(sp)
    80004436:	64e2                	ld	s1,24(sp)
    80004438:	6942                	ld	s2,16(sp)
    8000443a:	69a2                	ld	s3,8(sp)
    8000443c:	6145                	addi	sp,sp,48
    8000443e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004440:	0284a983          	lw	s3,40(s1)
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	570080e7          	jalr	1392(ra) # 800019b4 <myproc>
    8000444c:	5904                	lw	s1,48(a0)
    8000444e:	413484b3          	sub	s1,s1,s3
    80004452:	0014b493          	seqz	s1,s1
    80004456:	bfc1                	j	80004426 <holdingsleep+0x24>

0000000080004458 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004458:	1141                	addi	sp,sp,-16
    8000445a:	e406                	sd	ra,8(sp)
    8000445c:	e022                	sd	s0,0(sp)
    8000445e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004460:	00004597          	auipc	a1,0x4
    80004464:	22858593          	addi	a1,a1,552 # 80008688 <syscalls+0x238>
    80004468:	0001d517          	auipc	a0,0x1d
    8000446c:	a0050513          	addi	a0,a0,-1536 # 80020e68 <ftable>
    80004470:	ffffc097          	auipc	ra,0xffffc
    80004474:	6d6080e7          	jalr	1750(ra) # 80000b46 <initlock>
}
    80004478:	60a2                	ld	ra,8(sp)
    8000447a:	6402                	ld	s0,0(sp)
    8000447c:	0141                	addi	sp,sp,16
    8000447e:	8082                	ret

0000000080004480 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004480:	1101                	addi	sp,sp,-32
    80004482:	ec06                	sd	ra,24(sp)
    80004484:	e822                	sd	s0,16(sp)
    80004486:	e426                	sd	s1,8(sp)
    80004488:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000448a:	0001d517          	auipc	a0,0x1d
    8000448e:	9de50513          	addi	a0,a0,-1570 # 80020e68 <ftable>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	744080e7          	jalr	1860(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000449a:	0001d497          	auipc	s1,0x1d
    8000449e:	9e648493          	addi	s1,s1,-1562 # 80020e80 <ftable+0x18>
    800044a2:	0001e717          	auipc	a4,0x1e
    800044a6:	97e70713          	addi	a4,a4,-1666 # 80021e20 <disk>
    if(f->ref == 0){
    800044aa:	40dc                	lw	a5,4(s1)
    800044ac:	cf99                	beqz	a5,800044ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ae:	02848493          	addi	s1,s1,40
    800044b2:	fee49ce3          	bne	s1,a4,800044aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044b6:	0001d517          	auipc	a0,0x1d
    800044ba:	9b250513          	addi	a0,a0,-1614 # 80020e68 <ftable>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7cc080e7          	jalr	1996(ra) # 80000c8a <release>
  return 0;
    800044c6:	4481                	li	s1,0
    800044c8:	a819                	j	800044de <filealloc+0x5e>
      f->ref = 1;
    800044ca:	4785                	li	a5,1
    800044cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044ce:	0001d517          	auipc	a0,0x1d
    800044d2:	99a50513          	addi	a0,a0,-1638 # 80020e68 <ftable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
}
    800044de:	8526                	mv	a0,s1
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	64a2                	ld	s1,8(sp)
    800044e6:	6105                	addi	sp,sp,32
    800044e8:	8082                	ret

00000000800044ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044ea:	1101                	addi	sp,sp,-32
    800044ec:	ec06                	sd	ra,24(sp)
    800044ee:	e822                	sd	s0,16(sp)
    800044f0:	e426                	sd	s1,8(sp)
    800044f2:	1000                	addi	s0,sp,32
    800044f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044f6:	0001d517          	auipc	a0,0x1d
    800044fa:	97250513          	addi	a0,a0,-1678 # 80020e68 <ftable>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	6d8080e7          	jalr	1752(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004506:	40dc                	lw	a5,4(s1)
    80004508:	02f05263          	blez	a5,8000452c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000450c:	2785                	addiw	a5,a5,1
    8000450e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004510:	0001d517          	auipc	a0,0x1d
    80004514:	95850513          	addi	a0,a0,-1704 # 80020e68 <ftable>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	772080e7          	jalr	1906(ra) # 80000c8a <release>
  return f;
}
    80004520:	8526                	mv	a0,s1
    80004522:	60e2                	ld	ra,24(sp)
    80004524:	6442                	ld	s0,16(sp)
    80004526:	64a2                	ld	s1,8(sp)
    80004528:	6105                	addi	sp,sp,32
    8000452a:	8082                	ret
    panic("filedup");
    8000452c:	00004517          	auipc	a0,0x4
    80004530:	16450513          	addi	a0,a0,356 # 80008690 <syscalls+0x240>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	00c080e7          	jalr	12(ra) # 80000540 <panic>

000000008000453c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000453c:	7139                	addi	sp,sp,-64
    8000453e:	fc06                	sd	ra,56(sp)
    80004540:	f822                	sd	s0,48(sp)
    80004542:	f426                	sd	s1,40(sp)
    80004544:	f04a                	sd	s2,32(sp)
    80004546:	ec4e                	sd	s3,24(sp)
    80004548:	e852                	sd	s4,16(sp)
    8000454a:	e456                	sd	s5,8(sp)
    8000454c:	0080                	addi	s0,sp,64
    8000454e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004550:	0001d517          	auipc	a0,0x1d
    80004554:	91850513          	addi	a0,a0,-1768 # 80020e68 <ftable>
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	67e080e7          	jalr	1662(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004560:	40dc                	lw	a5,4(s1)
    80004562:	06f05163          	blez	a5,800045c4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004566:	37fd                	addiw	a5,a5,-1
    80004568:	0007871b          	sext.w	a4,a5
    8000456c:	c0dc                	sw	a5,4(s1)
    8000456e:	06e04363          	bgtz	a4,800045d4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004572:	0004a903          	lw	s2,0(s1)
    80004576:	0094ca83          	lbu	s5,9(s1)
    8000457a:	0104ba03          	ld	s4,16(s1)
    8000457e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004582:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004586:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000458a:	0001d517          	auipc	a0,0x1d
    8000458e:	8de50513          	addi	a0,a0,-1826 # 80020e68 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	6f8080e7          	jalr	1784(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000459a:	4785                	li	a5,1
    8000459c:	04f90d63          	beq	s2,a5,800045f6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045a0:	3979                	addiw	s2,s2,-2
    800045a2:	4785                	li	a5,1
    800045a4:	0527e063          	bltu	a5,s2,800045e4 <fileclose+0xa8>
    begin_op();
    800045a8:	00000097          	auipc	ra,0x0
    800045ac:	acc080e7          	jalr	-1332(ra) # 80004074 <begin_op>
    iput(ff.ip);
    800045b0:	854e                	mv	a0,s3
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	2b0080e7          	jalr	688(ra) # 80003862 <iput>
    end_op();
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	b38080e7          	jalr	-1224(ra) # 800040f2 <end_op>
    800045c2:	a00d                	j	800045e4 <fileclose+0xa8>
    panic("fileclose");
    800045c4:	00004517          	auipc	a0,0x4
    800045c8:	0d450513          	addi	a0,a0,212 # 80008698 <syscalls+0x248>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	f74080e7          	jalr	-140(ra) # 80000540 <panic>
    release(&ftable.lock);
    800045d4:	0001d517          	auipc	a0,0x1d
    800045d8:	89450513          	addi	a0,a0,-1900 # 80020e68 <ftable>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	6ae080e7          	jalr	1710(ra) # 80000c8a <release>
  }
}
    800045e4:	70e2                	ld	ra,56(sp)
    800045e6:	7442                	ld	s0,48(sp)
    800045e8:	74a2                	ld	s1,40(sp)
    800045ea:	7902                	ld	s2,32(sp)
    800045ec:	69e2                	ld	s3,24(sp)
    800045ee:	6a42                	ld	s4,16(sp)
    800045f0:	6aa2                	ld	s5,8(sp)
    800045f2:	6121                	addi	sp,sp,64
    800045f4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045f6:	85d6                	mv	a1,s5
    800045f8:	8552                	mv	a0,s4
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	34c080e7          	jalr	844(ra) # 80004946 <pipeclose>
    80004602:	b7cd                	j	800045e4 <fileclose+0xa8>

0000000080004604 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004604:	715d                	addi	sp,sp,-80
    80004606:	e486                	sd	ra,72(sp)
    80004608:	e0a2                	sd	s0,64(sp)
    8000460a:	fc26                	sd	s1,56(sp)
    8000460c:	f84a                	sd	s2,48(sp)
    8000460e:	f44e                	sd	s3,40(sp)
    80004610:	0880                	addi	s0,sp,80
    80004612:	84aa                	mv	s1,a0
    80004614:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004616:	ffffd097          	auipc	ra,0xffffd
    8000461a:	39e080e7          	jalr	926(ra) # 800019b4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000461e:	409c                	lw	a5,0(s1)
    80004620:	37f9                	addiw	a5,a5,-2
    80004622:	4705                	li	a4,1
    80004624:	04f76763          	bltu	a4,a5,80004672 <filestat+0x6e>
    80004628:	892a                	mv	s2,a0
    ilock(f->ip);
    8000462a:	6c88                	ld	a0,24(s1)
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	07c080e7          	jalr	124(ra) # 800036a8 <ilock>
    stati(f->ip, &st);
    80004634:	fb840593          	addi	a1,s0,-72
    80004638:	6c88                	ld	a0,24(s1)
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	2f8080e7          	jalr	760(ra) # 80003932 <stati>
    iunlock(f->ip);
    80004642:	6c88                	ld	a0,24(s1)
    80004644:	fffff097          	auipc	ra,0xfffff
    80004648:	126080e7          	jalr	294(ra) # 8000376a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000464c:	46e1                	li	a3,24
    8000464e:	fb840613          	addi	a2,s0,-72
    80004652:	85ce                	mv	a1,s3
    80004654:	05093503          	ld	a0,80(s2)
    80004658:	ffffd097          	auipc	ra,0xffffd
    8000465c:	014080e7          	jalr	20(ra) # 8000166c <copyout>
    80004660:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004664:	60a6                	ld	ra,72(sp)
    80004666:	6406                	ld	s0,64(sp)
    80004668:	74e2                	ld	s1,56(sp)
    8000466a:	7942                	ld	s2,48(sp)
    8000466c:	79a2                	ld	s3,40(sp)
    8000466e:	6161                	addi	sp,sp,80
    80004670:	8082                	ret
  return -1;
    80004672:	557d                	li	a0,-1
    80004674:	bfc5                	j	80004664 <filestat+0x60>

0000000080004676 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004676:	7179                	addi	sp,sp,-48
    80004678:	f406                	sd	ra,40(sp)
    8000467a:	f022                	sd	s0,32(sp)
    8000467c:	ec26                	sd	s1,24(sp)
    8000467e:	e84a                	sd	s2,16(sp)
    80004680:	e44e                	sd	s3,8(sp)
    80004682:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004684:	00854783          	lbu	a5,8(a0)
    80004688:	c3d5                	beqz	a5,8000472c <fileread+0xb6>
    8000468a:	84aa                	mv	s1,a0
    8000468c:	89ae                	mv	s3,a1
    8000468e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004690:	411c                	lw	a5,0(a0)
    80004692:	4705                	li	a4,1
    80004694:	04e78963          	beq	a5,a4,800046e6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004698:	470d                	li	a4,3
    8000469a:	04e78d63          	beq	a5,a4,800046f4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000469e:	4709                	li	a4,2
    800046a0:	06e79e63          	bne	a5,a4,8000471c <fileread+0xa6>
    ilock(f->ip);
    800046a4:	6d08                	ld	a0,24(a0)
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	002080e7          	jalr	2(ra) # 800036a8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046ae:	874a                	mv	a4,s2
    800046b0:	5094                	lw	a3,32(s1)
    800046b2:	864e                	mv	a2,s3
    800046b4:	4585                	li	a1,1
    800046b6:	6c88                	ld	a0,24(s1)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	2a4080e7          	jalr	676(ra) # 8000395c <readi>
    800046c0:	892a                	mv	s2,a0
    800046c2:	00a05563          	blez	a0,800046cc <fileread+0x56>
      f->off += r;
    800046c6:	509c                	lw	a5,32(s1)
    800046c8:	9fa9                	addw	a5,a5,a0
    800046ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046cc:	6c88                	ld	a0,24(s1)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	09c080e7          	jalr	156(ra) # 8000376a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046d6:	854a                	mv	a0,s2
    800046d8:	70a2                	ld	ra,40(sp)
    800046da:	7402                	ld	s0,32(sp)
    800046dc:	64e2                	ld	s1,24(sp)
    800046de:	6942                	ld	s2,16(sp)
    800046e0:	69a2                	ld	s3,8(sp)
    800046e2:	6145                	addi	sp,sp,48
    800046e4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046e6:	6908                	ld	a0,16(a0)
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	3c6080e7          	jalr	966(ra) # 80004aae <piperead>
    800046f0:	892a                	mv	s2,a0
    800046f2:	b7d5                	j	800046d6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046f4:	02451783          	lh	a5,36(a0)
    800046f8:	03079693          	slli	a3,a5,0x30
    800046fc:	92c1                	srli	a3,a3,0x30
    800046fe:	4725                	li	a4,9
    80004700:	02d76863          	bltu	a4,a3,80004730 <fileread+0xba>
    80004704:	0792                	slli	a5,a5,0x4
    80004706:	0001c717          	auipc	a4,0x1c
    8000470a:	6c270713          	addi	a4,a4,1730 # 80020dc8 <devsw>
    8000470e:	97ba                	add	a5,a5,a4
    80004710:	639c                	ld	a5,0(a5)
    80004712:	c38d                	beqz	a5,80004734 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004714:	4505                	li	a0,1
    80004716:	9782                	jalr	a5
    80004718:	892a                	mv	s2,a0
    8000471a:	bf75                	j	800046d6 <fileread+0x60>
    panic("fileread");
    8000471c:	00004517          	auipc	a0,0x4
    80004720:	f8c50513          	addi	a0,a0,-116 # 800086a8 <syscalls+0x258>
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	e1c080e7          	jalr	-484(ra) # 80000540 <panic>
    return -1;
    8000472c:	597d                	li	s2,-1
    8000472e:	b765                	j	800046d6 <fileread+0x60>
      return -1;
    80004730:	597d                	li	s2,-1
    80004732:	b755                	j	800046d6 <fileread+0x60>
    80004734:	597d                	li	s2,-1
    80004736:	b745                	j	800046d6 <fileread+0x60>

0000000080004738 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004738:	715d                	addi	sp,sp,-80
    8000473a:	e486                	sd	ra,72(sp)
    8000473c:	e0a2                	sd	s0,64(sp)
    8000473e:	fc26                	sd	s1,56(sp)
    80004740:	f84a                	sd	s2,48(sp)
    80004742:	f44e                	sd	s3,40(sp)
    80004744:	f052                	sd	s4,32(sp)
    80004746:	ec56                	sd	s5,24(sp)
    80004748:	e85a                	sd	s6,16(sp)
    8000474a:	e45e                	sd	s7,8(sp)
    8000474c:	e062                	sd	s8,0(sp)
    8000474e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004750:	00954783          	lbu	a5,9(a0)
    80004754:	10078663          	beqz	a5,80004860 <filewrite+0x128>
    80004758:	892a                	mv	s2,a0
    8000475a:	8b2e                	mv	s6,a1
    8000475c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000475e:	411c                	lw	a5,0(a0)
    80004760:	4705                	li	a4,1
    80004762:	02e78263          	beq	a5,a4,80004786 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004766:	470d                	li	a4,3
    80004768:	02e78663          	beq	a5,a4,80004794 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000476c:	4709                	li	a4,2
    8000476e:	0ee79163          	bne	a5,a4,80004850 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004772:	0ac05d63          	blez	a2,8000482c <filewrite+0xf4>
    int i = 0;
    80004776:	4981                	li	s3,0
    80004778:	6b85                	lui	s7,0x1
    8000477a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000477e:	6c05                	lui	s8,0x1
    80004780:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004784:	a861                	j	8000481c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004786:	6908                	ld	a0,16(a0)
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	22e080e7          	jalr	558(ra) # 800049b6 <pipewrite>
    80004790:	8a2a                	mv	s4,a0
    80004792:	a045                	j	80004832 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004794:	02451783          	lh	a5,36(a0)
    80004798:	03079693          	slli	a3,a5,0x30
    8000479c:	92c1                	srli	a3,a3,0x30
    8000479e:	4725                	li	a4,9
    800047a0:	0cd76263          	bltu	a4,a3,80004864 <filewrite+0x12c>
    800047a4:	0792                	slli	a5,a5,0x4
    800047a6:	0001c717          	auipc	a4,0x1c
    800047aa:	62270713          	addi	a4,a4,1570 # 80020dc8 <devsw>
    800047ae:	97ba                	add	a5,a5,a4
    800047b0:	679c                	ld	a5,8(a5)
    800047b2:	cbdd                	beqz	a5,80004868 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047b4:	4505                	li	a0,1
    800047b6:	9782                	jalr	a5
    800047b8:	8a2a                	mv	s4,a0
    800047ba:	a8a5                	j	80004832 <filewrite+0xfa>
    800047bc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047c0:	00000097          	auipc	ra,0x0
    800047c4:	8b4080e7          	jalr	-1868(ra) # 80004074 <begin_op>
      ilock(f->ip);
    800047c8:	01893503          	ld	a0,24(s2)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	edc080e7          	jalr	-292(ra) # 800036a8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047d4:	8756                	mv	a4,s5
    800047d6:	02092683          	lw	a3,32(s2)
    800047da:	01698633          	add	a2,s3,s6
    800047de:	4585                	li	a1,1
    800047e0:	01893503          	ld	a0,24(s2)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	270080e7          	jalr	624(ra) # 80003a54 <writei>
    800047ec:	84aa                	mv	s1,a0
    800047ee:	00a05763          	blez	a0,800047fc <filewrite+0xc4>
        f->off += r;
    800047f2:	02092783          	lw	a5,32(s2)
    800047f6:	9fa9                	addw	a5,a5,a0
    800047f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047fc:	01893503          	ld	a0,24(s2)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	f6a080e7          	jalr	-150(ra) # 8000376a <iunlock>
      end_op();
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	8ea080e7          	jalr	-1814(ra) # 800040f2 <end_op>

      if(r != n1){
    80004810:	009a9f63          	bne	s5,s1,8000482e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004814:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004818:	0149db63          	bge	s3,s4,8000482e <filewrite+0xf6>
      int n1 = n - i;
    8000481c:	413a04bb          	subw	s1,s4,s3
    80004820:	0004879b          	sext.w	a5,s1
    80004824:	f8fbdce3          	bge	s7,a5,800047bc <filewrite+0x84>
    80004828:	84e2                	mv	s1,s8
    8000482a:	bf49                	j	800047bc <filewrite+0x84>
    int i = 0;
    8000482c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000482e:	013a1f63          	bne	s4,s3,8000484c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004832:	8552                	mv	a0,s4
    80004834:	60a6                	ld	ra,72(sp)
    80004836:	6406                	ld	s0,64(sp)
    80004838:	74e2                	ld	s1,56(sp)
    8000483a:	7942                	ld	s2,48(sp)
    8000483c:	79a2                	ld	s3,40(sp)
    8000483e:	7a02                	ld	s4,32(sp)
    80004840:	6ae2                	ld	s5,24(sp)
    80004842:	6b42                	ld	s6,16(sp)
    80004844:	6ba2                	ld	s7,8(sp)
    80004846:	6c02                	ld	s8,0(sp)
    80004848:	6161                	addi	sp,sp,80
    8000484a:	8082                	ret
    ret = (i == n ? n : -1);
    8000484c:	5a7d                	li	s4,-1
    8000484e:	b7d5                	j	80004832 <filewrite+0xfa>
    panic("filewrite");
    80004850:	00004517          	auipc	a0,0x4
    80004854:	e6850513          	addi	a0,a0,-408 # 800086b8 <syscalls+0x268>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	ce8080e7          	jalr	-792(ra) # 80000540 <panic>
    return -1;
    80004860:	5a7d                	li	s4,-1
    80004862:	bfc1                	j	80004832 <filewrite+0xfa>
      return -1;
    80004864:	5a7d                	li	s4,-1
    80004866:	b7f1                	j	80004832 <filewrite+0xfa>
    80004868:	5a7d                	li	s4,-1
    8000486a:	b7e1                	j	80004832 <filewrite+0xfa>

000000008000486c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000486c:	7179                	addi	sp,sp,-48
    8000486e:	f406                	sd	ra,40(sp)
    80004870:	f022                	sd	s0,32(sp)
    80004872:	ec26                	sd	s1,24(sp)
    80004874:	e84a                	sd	s2,16(sp)
    80004876:	e44e                	sd	s3,8(sp)
    80004878:	e052                	sd	s4,0(sp)
    8000487a:	1800                	addi	s0,sp,48
    8000487c:	84aa                	mv	s1,a0
    8000487e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004880:	0005b023          	sd	zero,0(a1)
    80004884:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	bf8080e7          	jalr	-1032(ra) # 80004480 <filealloc>
    80004890:	e088                	sd	a0,0(s1)
    80004892:	c551                	beqz	a0,8000491e <pipealloc+0xb2>
    80004894:	00000097          	auipc	ra,0x0
    80004898:	bec080e7          	jalr	-1044(ra) # 80004480 <filealloc>
    8000489c:	00aa3023          	sd	a0,0(s4)
    800048a0:	c92d                	beqz	a0,80004912 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	244080e7          	jalr	580(ra) # 80000ae6 <kalloc>
    800048aa:	892a                	mv	s2,a0
    800048ac:	c125                	beqz	a0,8000490c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048ae:	4985                	li	s3,1
    800048b0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048b4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048b8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048bc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048c0:	00004597          	auipc	a1,0x4
    800048c4:	e0858593          	addi	a1,a1,-504 # 800086c8 <syscalls+0x278>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	27e080e7          	jalr	638(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800048d0:	609c                	ld	a5,0(s1)
    800048d2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048d6:	609c                	ld	a5,0(s1)
    800048d8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048dc:	609c                	ld	a5,0(s1)
    800048de:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048e2:	609c                	ld	a5,0(s1)
    800048e4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048e8:	000a3783          	ld	a5,0(s4)
    800048ec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048f0:	000a3783          	ld	a5,0(s4)
    800048f4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048f8:	000a3783          	ld	a5,0(s4)
    800048fc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004900:	000a3783          	ld	a5,0(s4)
    80004904:	0127b823          	sd	s2,16(a5)
  return 0;
    80004908:	4501                	li	a0,0
    8000490a:	a025                	j	80004932 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000490c:	6088                	ld	a0,0(s1)
    8000490e:	e501                	bnez	a0,80004916 <pipealloc+0xaa>
    80004910:	a039                	j	8000491e <pipealloc+0xb2>
    80004912:	6088                	ld	a0,0(s1)
    80004914:	c51d                	beqz	a0,80004942 <pipealloc+0xd6>
    fileclose(*f0);
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	c26080e7          	jalr	-986(ra) # 8000453c <fileclose>
  if(*f1)
    8000491e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004922:	557d                	li	a0,-1
  if(*f1)
    80004924:	c799                	beqz	a5,80004932 <pipealloc+0xc6>
    fileclose(*f1);
    80004926:	853e                	mv	a0,a5
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	c14080e7          	jalr	-1004(ra) # 8000453c <fileclose>
  return -1;
    80004930:	557d                	li	a0,-1
}
    80004932:	70a2                	ld	ra,40(sp)
    80004934:	7402                	ld	s0,32(sp)
    80004936:	64e2                	ld	s1,24(sp)
    80004938:	6942                	ld	s2,16(sp)
    8000493a:	69a2                	ld	s3,8(sp)
    8000493c:	6a02                	ld	s4,0(sp)
    8000493e:	6145                	addi	sp,sp,48
    80004940:	8082                	ret
  return -1;
    80004942:	557d                	li	a0,-1
    80004944:	b7fd                	j	80004932 <pipealloc+0xc6>

0000000080004946 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004946:	1101                	addi	sp,sp,-32
    80004948:	ec06                	sd	ra,24(sp)
    8000494a:	e822                	sd	s0,16(sp)
    8000494c:	e426                	sd	s1,8(sp)
    8000494e:	e04a                	sd	s2,0(sp)
    80004950:	1000                	addi	s0,sp,32
    80004952:	84aa                	mv	s1,a0
    80004954:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	280080e7          	jalr	640(ra) # 80000bd6 <acquire>
  if(writable){
    8000495e:	02090d63          	beqz	s2,80004998 <pipeclose+0x52>
    pi->writeopen = 0;
    80004962:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004966:	21848513          	addi	a0,s1,536
    8000496a:	ffffd097          	auipc	ra,0xffffd
    8000496e:	7c6080e7          	jalr	1990(ra) # 80002130 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004972:	2204b783          	ld	a5,544(s1)
    80004976:	eb95                	bnez	a5,800049aa <pipeclose+0x64>
    release(&pi->lock);
    80004978:	8526                	mv	a0,s1
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	310080e7          	jalr	784(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	064080e7          	jalr	100(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    8000498c:	60e2                	ld	ra,24(sp)
    8000498e:	6442                	ld	s0,16(sp)
    80004990:	64a2                	ld	s1,8(sp)
    80004992:	6902                	ld	s2,0(sp)
    80004994:	6105                	addi	sp,sp,32
    80004996:	8082                	ret
    pi->readopen = 0;
    80004998:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000499c:	21c48513          	addi	a0,s1,540
    800049a0:	ffffd097          	auipc	ra,0xffffd
    800049a4:	790080e7          	jalr	1936(ra) # 80002130 <wakeup>
    800049a8:	b7e9                	j	80004972 <pipeclose+0x2c>
    release(&pi->lock);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2de080e7          	jalr	734(ra) # 80000c8a <release>
}
    800049b4:	bfe1                	j	8000498c <pipeclose+0x46>

00000000800049b6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049b6:	711d                	addi	sp,sp,-96
    800049b8:	ec86                	sd	ra,88(sp)
    800049ba:	e8a2                	sd	s0,80(sp)
    800049bc:	e4a6                	sd	s1,72(sp)
    800049be:	e0ca                	sd	s2,64(sp)
    800049c0:	fc4e                	sd	s3,56(sp)
    800049c2:	f852                	sd	s4,48(sp)
    800049c4:	f456                	sd	s5,40(sp)
    800049c6:	f05a                	sd	s6,32(sp)
    800049c8:	ec5e                	sd	s7,24(sp)
    800049ca:	e862                	sd	s8,16(sp)
    800049cc:	1080                	addi	s0,sp,96
    800049ce:	84aa                	mv	s1,a0
    800049d0:	8aae                	mv	s5,a1
    800049d2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049d4:	ffffd097          	auipc	ra,0xffffd
    800049d8:	fe0080e7          	jalr	-32(ra) # 800019b4 <myproc>
    800049dc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049de:	8526                	mv	a0,s1
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	1f6080e7          	jalr	502(ra) # 80000bd6 <acquire>
  while(i < n){
    800049e8:	0b405663          	blez	s4,80004a94 <pipewrite+0xde>
  int i = 0;
    800049ec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049f0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049f4:	21c48b93          	addi	s7,s1,540
    800049f8:	a089                	j	80004a3a <pipewrite+0x84>
      release(&pi->lock);
    800049fa:	8526                	mv	a0,s1
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	28e080e7          	jalr	654(ra) # 80000c8a <release>
      return -1;
    80004a04:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a06:	854a                	mv	a0,s2
    80004a08:	60e6                	ld	ra,88(sp)
    80004a0a:	6446                	ld	s0,80(sp)
    80004a0c:	64a6                	ld	s1,72(sp)
    80004a0e:	6906                	ld	s2,64(sp)
    80004a10:	79e2                	ld	s3,56(sp)
    80004a12:	7a42                	ld	s4,48(sp)
    80004a14:	7aa2                	ld	s5,40(sp)
    80004a16:	7b02                	ld	s6,32(sp)
    80004a18:	6be2                	ld	s7,24(sp)
    80004a1a:	6c42                	ld	s8,16(sp)
    80004a1c:	6125                	addi	sp,sp,96
    80004a1e:	8082                	ret
      wakeup(&pi->nread);
    80004a20:	8562                	mv	a0,s8
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	70e080e7          	jalr	1806(ra) # 80002130 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a2a:	85a6                	mv	a1,s1
    80004a2c:	855e                	mv	a0,s7
    80004a2e:	ffffd097          	auipc	ra,0xffffd
    80004a32:	69e080e7          	jalr	1694(ra) # 800020cc <sleep>
  while(i < n){
    80004a36:	07495063          	bge	s2,s4,80004a96 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a3a:	2204a783          	lw	a5,544(s1)
    80004a3e:	dfd5                	beqz	a5,800049fa <pipewrite+0x44>
    80004a40:	854e                	mv	a0,s3
    80004a42:	ffffe097          	auipc	ra,0xffffe
    80004a46:	932080e7          	jalr	-1742(ra) # 80002374 <killed>
    80004a4a:	f945                	bnez	a0,800049fa <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a4c:	2184a783          	lw	a5,536(s1)
    80004a50:	21c4a703          	lw	a4,540(s1)
    80004a54:	2007879b          	addiw	a5,a5,512
    80004a58:	fcf704e3          	beq	a4,a5,80004a20 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a5c:	4685                	li	a3,1
    80004a5e:	01590633          	add	a2,s2,s5
    80004a62:	faf40593          	addi	a1,s0,-81
    80004a66:	0509b503          	ld	a0,80(s3)
    80004a6a:	ffffd097          	auipc	ra,0xffffd
    80004a6e:	c8e080e7          	jalr	-882(ra) # 800016f8 <copyin>
    80004a72:	03650263          	beq	a0,s6,80004a96 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a76:	21c4a783          	lw	a5,540(s1)
    80004a7a:	0017871b          	addiw	a4,a5,1
    80004a7e:	20e4ae23          	sw	a4,540(s1)
    80004a82:	1ff7f793          	andi	a5,a5,511
    80004a86:	97a6                	add	a5,a5,s1
    80004a88:	faf44703          	lbu	a4,-81(s0)
    80004a8c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a90:	2905                	addiw	s2,s2,1
    80004a92:	b755                	j	80004a36 <pipewrite+0x80>
  int i = 0;
    80004a94:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a96:	21848513          	addi	a0,s1,536
    80004a9a:	ffffd097          	auipc	ra,0xffffd
    80004a9e:	696080e7          	jalr	1686(ra) # 80002130 <wakeup>
  release(&pi->lock);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1e6080e7          	jalr	486(ra) # 80000c8a <release>
  return i;
    80004aac:	bfa9                	j	80004a06 <pipewrite+0x50>

0000000080004aae <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aae:	715d                	addi	sp,sp,-80
    80004ab0:	e486                	sd	ra,72(sp)
    80004ab2:	e0a2                	sd	s0,64(sp)
    80004ab4:	fc26                	sd	s1,56(sp)
    80004ab6:	f84a                	sd	s2,48(sp)
    80004ab8:	f44e                	sd	s3,40(sp)
    80004aba:	f052                	sd	s4,32(sp)
    80004abc:	ec56                	sd	s5,24(sp)
    80004abe:	e85a                	sd	s6,16(sp)
    80004ac0:	0880                	addi	s0,sp,80
    80004ac2:	84aa                	mv	s1,a0
    80004ac4:	892e                	mv	s2,a1
    80004ac6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	eec080e7          	jalr	-276(ra) # 800019b4 <myproc>
    80004ad0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	102080e7          	jalr	258(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004adc:	2184a703          	lw	a4,536(s1)
    80004ae0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ae4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae8:	02f71763          	bne	a4,a5,80004b16 <piperead+0x68>
    80004aec:	2244a783          	lw	a5,548(s1)
    80004af0:	c39d                	beqz	a5,80004b16 <piperead+0x68>
    if(killed(pr)){
    80004af2:	8552                	mv	a0,s4
    80004af4:	ffffe097          	auipc	ra,0xffffe
    80004af8:	880080e7          	jalr	-1920(ra) # 80002374 <killed>
    80004afc:	e949                	bnez	a0,80004b8e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004afe:	85a6                	mv	a1,s1
    80004b00:	854e                	mv	a0,s3
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	5ca080e7          	jalr	1482(ra) # 800020cc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b0a:	2184a703          	lw	a4,536(s1)
    80004b0e:	21c4a783          	lw	a5,540(s1)
    80004b12:	fcf70de3          	beq	a4,a5,80004aec <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b16:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b18:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b1a:	05505463          	blez	s5,80004b62 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b1e:	2184a783          	lw	a5,536(s1)
    80004b22:	21c4a703          	lw	a4,540(s1)
    80004b26:	02f70e63          	beq	a4,a5,80004b62 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b2a:	0017871b          	addiw	a4,a5,1
    80004b2e:	20e4ac23          	sw	a4,536(s1)
    80004b32:	1ff7f793          	andi	a5,a5,511
    80004b36:	97a6                	add	a5,a5,s1
    80004b38:	0187c783          	lbu	a5,24(a5)
    80004b3c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b40:	4685                	li	a3,1
    80004b42:	fbf40613          	addi	a2,s0,-65
    80004b46:	85ca                	mv	a1,s2
    80004b48:	050a3503          	ld	a0,80(s4)
    80004b4c:	ffffd097          	auipc	ra,0xffffd
    80004b50:	b20080e7          	jalr	-1248(ra) # 8000166c <copyout>
    80004b54:	01650763          	beq	a0,s6,80004b62 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b58:	2985                	addiw	s3,s3,1
    80004b5a:	0905                	addi	s2,s2,1
    80004b5c:	fd3a91e3          	bne	s5,s3,80004b1e <piperead+0x70>
    80004b60:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b62:	21c48513          	addi	a0,s1,540
    80004b66:	ffffd097          	auipc	ra,0xffffd
    80004b6a:	5ca080e7          	jalr	1482(ra) # 80002130 <wakeup>
  release(&pi->lock);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	11a080e7          	jalr	282(ra) # 80000c8a <release>
  return i;
}
    80004b78:	854e                	mv	a0,s3
    80004b7a:	60a6                	ld	ra,72(sp)
    80004b7c:	6406                	ld	s0,64(sp)
    80004b7e:	74e2                	ld	s1,56(sp)
    80004b80:	7942                	ld	s2,48(sp)
    80004b82:	79a2                	ld	s3,40(sp)
    80004b84:	7a02                	ld	s4,32(sp)
    80004b86:	6ae2                	ld	s5,24(sp)
    80004b88:	6b42                	ld	s6,16(sp)
    80004b8a:	6161                	addi	sp,sp,80
    80004b8c:	8082                	ret
      release(&pi->lock);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	0fa080e7          	jalr	250(ra) # 80000c8a <release>
      return -1;
    80004b98:	59fd                	li	s3,-1
    80004b9a:	bff9                	j	80004b78 <piperead+0xca>

0000000080004b9c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004b9c:	1141                	addi	sp,sp,-16
    80004b9e:	e422                	sd	s0,8(sp)
    80004ba0:	0800                	addi	s0,sp,16
    80004ba2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ba4:	8905                	andi	a0,a0,1
    80004ba6:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ba8:	8b89                	andi	a5,a5,2
    80004baa:	c399                	beqz	a5,80004bb0 <flags2perm+0x14>
      perm |= PTE_W;
    80004bac:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bb0:	6422                	ld	s0,8(sp)
    80004bb2:	0141                	addi	sp,sp,16
    80004bb4:	8082                	ret

0000000080004bb6 <exec>:

int
exec(char *path, char **argv)
{
    80004bb6:	de010113          	addi	sp,sp,-544
    80004bba:	20113c23          	sd	ra,536(sp)
    80004bbe:	20813823          	sd	s0,528(sp)
    80004bc2:	20913423          	sd	s1,520(sp)
    80004bc6:	21213023          	sd	s2,512(sp)
    80004bca:	ffce                	sd	s3,504(sp)
    80004bcc:	fbd2                	sd	s4,496(sp)
    80004bce:	f7d6                	sd	s5,488(sp)
    80004bd0:	f3da                	sd	s6,480(sp)
    80004bd2:	efde                	sd	s7,472(sp)
    80004bd4:	ebe2                	sd	s8,464(sp)
    80004bd6:	e7e6                	sd	s9,456(sp)
    80004bd8:	e3ea                	sd	s10,448(sp)
    80004bda:	ff6e                	sd	s11,440(sp)
    80004bdc:	1400                	addi	s0,sp,544
    80004bde:	892a                	mv	s2,a0
    80004be0:	dea43423          	sd	a0,-536(s0)
    80004be4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	dcc080e7          	jalr	-564(ra) # 800019b4 <myproc>
    80004bf0:	84aa                	mv	s1,a0

  begin_op();
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	482080e7          	jalr	1154(ra) # 80004074 <begin_op>

  if((ip = namei(path)) == 0){
    80004bfa:	854a                	mv	a0,s2
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	258080e7          	jalr	600(ra) # 80003e54 <namei>
    80004c04:	c93d                	beqz	a0,80004c7a <exec+0xc4>
    80004c06:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	aa0080e7          	jalr	-1376(ra) # 800036a8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c10:	04000713          	li	a4,64
    80004c14:	4681                	li	a3,0
    80004c16:	e5040613          	addi	a2,s0,-432
    80004c1a:	4581                	li	a1,0
    80004c1c:	8556                	mv	a0,s5
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	d3e080e7          	jalr	-706(ra) # 8000395c <readi>
    80004c26:	04000793          	li	a5,64
    80004c2a:	00f51a63          	bne	a0,a5,80004c3e <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c2e:	e5042703          	lw	a4,-432(s0)
    80004c32:	464c47b7          	lui	a5,0x464c4
    80004c36:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c3a:	04f70663          	beq	a4,a5,80004c86 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c3e:	8556                	mv	a0,s5
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	cca080e7          	jalr	-822(ra) # 8000390a <iunlockput>
    end_op();
    80004c48:	fffff097          	auipc	ra,0xfffff
    80004c4c:	4aa080e7          	jalr	1194(ra) # 800040f2 <end_op>
  }
  return -1;
    80004c50:	557d                	li	a0,-1
}
    80004c52:	21813083          	ld	ra,536(sp)
    80004c56:	21013403          	ld	s0,528(sp)
    80004c5a:	20813483          	ld	s1,520(sp)
    80004c5e:	20013903          	ld	s2,512(sp)
    80004c62:	79fe                	ld	s3,504(sp)
    80004c64:	7a5e                	ld	s4,496(sp)
    80004c66:	7abe                	ld	s5,488(sp)
    80004c68:	7b1e                	ld	s6,480(sp)
    80004c6a:	6bfe                	ld	s7,472(sp)
    80004c6c:	6c5e                	ld	s8,464(sp)
    80004c6e:	6cbe                	ld	s9,456(sp)
    80004c70:	6d1e                	ld	s10,448(sp)
    80004c72:	7dfa                	ld	s11,440(sp)
    80004c74:	22010113          	addi	sp,sp,544
    80004c78:	8082                	ret
    end_op();
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	478080e7          	jalr	1144(ra) # 800040f2 <end_op>
    return -1;
    80004c82:	557d                	li	a0,-1
    80004c84:	b7f9                	j	80004c52 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	df0080e7          	jalr	-528(ra) # 80001a78 <proc_pagetable>
    80004c90:	8b2a                	mv	s6,a0
    80004c92:	d555                	beqz	a0,80004c3e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c94:	e7042783          	lw	a5,-400(s0)
    80004c98:	e8845703          	lhu	a4,-376(s0)
    80004c9c:	c735                	beqz	a4,80004d08 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c9e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ca0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ca4:	6a05                	lui	s4,0x1
    80004ca6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004caa:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004cae:	6d85                	lui	s11,0x1
    80004cb0:	7d7d                	lui	s10,0xfffff
    80004cb2:	ac3d                	j	80004ef0 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cb4:	00004517          	auipc	a0,0x4
    80004cb8:	a1c50513          	addi	a0,a0,-1508 # 800086d0 <syscalls+0x280>
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	884080e7          	jalr	-1916(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cc4:	874a                	mv	a4,s2
    80004cc6:	009c86bb          	addw	a3,s9,s1
    80004cca:	4581                	li	a1,0
    80004ccc:	8556                	mv	a0,s5
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	c8e080e7          	jalr	-882(ra) # 8000395c <readi>
    80004cd6:	2501                	sext.w	a0,a0
    80004cd8:	1aa91963          	bne	s2,a0,80004e8a <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004cdc:	009d84bb          	addw	s1,s11,s1
    80004ce0:	013d09bb          	addw	s3,s10,s3
    80004ce4:	1f74f663          	bgeu	s1,s7,80004ed0 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004ce8:	02049593          	slli	a1,s1,0x20
    80004cec:	9181                	srli	a1,a1,0x20
    80004cee:	95e2                	add	a1,a1,s8
    80004cf0:	855a                	mv	a0,s6
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	36a080e7          	jalr	874(ra) # 8000105c <walkaddr>
    80004cfa:	862a                	mv	a2,a0
    if(pa == 0)
    80004cfc:	dd45                	beqz	a0,80004cb4 <exec+0xfe>
      n = PGSIZE;
    80004cfe:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d00:	fd49f2e3          	bgeu	s3,s4,80004cc4 <exec+0x10e>
      n = sz - i;
    80004d04:	894e                	mv	s2,s3
    80004d06:	bf7d                	j	80004cc4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d08:	4901                	li	s2,0
  iunlockput(ip);
    80004d0a:	8556                	mv	a0,s5
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	bfe080e7          	jalr	-1026(ra) # 8000390a <iunlockput>
  end_op();
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	3de080e7          	jalr	990(ra) # 800040f2 <end_op>
  p = myproc();
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	c98080e7          	jalr	-872(ra) # 800019b4 <myproc>
    80004d24:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d26:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d2a:	6785                	lui	a5,0x1
    80004d2c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d2e:	97ca                	add	a5,a5,s2
    80004d30:	777d                	lui	a4,0xfffff
    80004d32:	8ff9                	and	a5,a5,a4
    80004d34:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d38:	4691                	li	a3,4
    80004d3a:	6609                	lui	a2,0x2
    80004d3c:	963e                	add	a2,a2,a5
    80004d3e:	85be                	mv	a1,a5
    80004d40:	855a                	mv	a0,s6
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	6ce080e7          	jalr	1742(ra) # 80001410 <uvmalloc>
    80004d4a:	8c2a                	mv	s8,a0
  ip = 0;
    80004d4c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d4e:	12050e63          	beqz	a0,80004e8a <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d52:	75f9                	lui	a1,0xffffe
    80004d54:	95aa                	add	a1,a1,a0
    80004d56:	855a                	mv	a0,s6
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	8e2080e7          	jalr	-1822(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004d60:	7afd                	lui	s5,0xfffff
    80004d62:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d64:	df043783          	ld	a5,-528(s0)
    80004d68:	6388                	ld	a0,0(a5)
    80004d6a:	c925                	beqz	a0,80004dda <exec+0x224>
    80004d6c:	e9040993          	addi	s3,s0,-368
    80004d70:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d74:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d76:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	0d6080e7          	jalr	214(ra) # 80000e4e <strlen>
    80004d80:	0015079b          	addiw	a5,a0,1
    80004d84:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d88:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d8c:	13596663          	bltu	s2,s5,80004eb8 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d90:	df043d83          	ld	s11,-528(s0)
    80004d94:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d98:	8552                	mv	a0,s4
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	0b4080e7          	jalr	180(ra) # 80000e4e <strlen>
    80004da2:	0015069b          	addiw	a3,a0,1
    80004da6:	8652                	mv	a2,s4
    80004da8:	85ca                	mv	a1,s2
    80004daa:	855a                	mv	a0,s6
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	8c0080e7          	jalr	-1856(ra) # 8000166c <copyout>
    80004db4:	10054663          	bltz	a0,80004ec0 <exec+0x30a>
    ustack[argc] = sp;
    80004db8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dbc:	0485                	addi	s1,s1,1
    80004dbe:	008d8793          	addi	a5,s11,8
    80004dc2:	def43823          	sd	a5,-528(s0)
    80004dc6:	008db503          	ld	a0,8(s11)
    80004dca:	c911                	beqz	a0,80004dde <exec+0x228>
    if(argc >= MAXARG)
    80004dcc:	09a1                	addi	s3,s3,8
    80004dce:	fb3c95e3          	bne	s9,s3,80004d78 <exec+0x1c2>
  sz = sz1;
    80004dd2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dd6:	4a81                	li	s5,0
    80004dd8:	a84d                	j	80004e8a <exec+0x2d4>
  sp = sz;
    80004dda:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ddc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dde:	00349793          	slli	a5,s1,0x3
    80004de2:	f9078793          	addi	a5,a5,-112
    80004de6:	97a2                	add	a5,a5,s0
    80004de8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004dec:	00148693          	addi	a3,s1,1
    80004df0:	068e                	slli	a3,a3,0x3
    80004df2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004df6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004dfa:	01597663          	bgeu	s2,s5,80004e06 <exec+0x250>
  sz = sz1;
    80004dfe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e02:	4a81                	li	s5,0
    80004e04:	a059                	j	80004e8a <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e06:	e9040613          	addi	a2,s0,-368
    80004e0a:	85ca                	mv	a1,s2
    80004e0c:	855a                	mv	a0,s6
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	85e080e7          	jalr	-1954(ra) # 8000166c <copyout>
    80004e16:	0a054963          	bltz	a0,80004ec8 <exec+0x312>
  p->trapframe->a1 = sp;
    80004e1a:	058bb783          	ld	a5,88(s7)
    80004e1e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e22:	de843783          	ld	a5,-536(s0)
    80004e26:	0007c703          	lbu	a4,0(a5)
    80004e2a:	cf11                	beqz	a4,80004e46 <exec+0x290>
    80004e2c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e2e:	02f00693          	li	a3,47
    80004e32:	a039                	j	80004e40 <exec+0x28a>
      last = s+1;
    80004e34:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e38:	0785                	addi	a5,a5,1
    80004e3a:	fff7c703          	lbu	a4,-1(a5)
    80004e3e:	c701                	beqz	a4,80004e46 <exec+0x290>
    if(*s == '/')
    80004e40:	fed71ce3          	bne	a4,a3,80004e38 <exec+0x282>
    80004e44:	bfc5                	j	80004e34 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e46:	4641                	li	a2,16
    80004e48:	de843583          	ld	a1,-536(s0)
    80004e4c:	158b8513          	addi	a0,s7,344
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	fcc080e7          	jalr	-52(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004e58:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e5c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e60:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e64:	058bb783          	ld	a5,88(s7)
    80004e68:	e6843703          	ld	a4,-408(s0)
    80004e6c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e6e:	058bb783          	ld	a5,88(s7)
    80004e72:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e76:	85ea                	mv	a1,s10
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	c9c080e7          	jalr	-868(ra) # 80001b14 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e80:	0004851b          	sext.w	a0,s1
    80004e84:	b3f9                	j	80004c52 <exec+0x9c>
    80004e86:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e8a:	df843583          	ld	a1,-520(s0)
    80004e8e:	855a                	mv	a0,s6
    80004e90:	ffffd097          	auipc	ra,0xffffd
    80004e94:	c84080e7          	jalr	-892(ra) # 80001b14 <proc_freepagetable>
  if(ip){
    80004e98:	da0a93e3          	bnez	s5,80004c3e <exec+0x88>
  return -1;
    80004e9c:	557d                	li	a0,-1
    80004e9e:	bb55                	j	80004c52 <exec+0x9c>
    80004ea0:	df243c23          	sd	s2,-520(s0)
    80004ea4:	b7dd                	j	80004e8a <exec+0x2d4>
    80004ea6:	df243c23          	sd	s2,-520(s0)
    80004eaa:	b7c5                	j	80004e8a <exec+0x2d4>
    80004eac:	df243c23          	sd	s2,-520(s0)
    80004eb0:	bfe9                	j	80004e8a <exec+0x2d4>
    80004eb2:	df243c23          	sd	s2,-520(s0)
    80004eb6:	bfd1                	j	80004e8a <exec+0x2d4>
  sz = sz1;
    80004eb8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ebc:	4a81                	li	s5,0
    80004ebe:	b7f1                	j	80004e8a <exec+0x2d4>
  sz = sz1;
    80004ec0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec4:	4a81                	li	s5,0
    80004ec6:	b7d1                	j	80004e8a <exec+0x2d4>
  sz = sz1;
    80004ec8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ecc:	4a81                	li	s5,0
    80004ece:	bf75                	j	80004e8a <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ed0:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed4:	e0843783          	ld	a5,-504(s0)
    80004ed8:	0017869b          	addiw	a3,a5,1
    80004edc:	e0d43423          	sd	a3,-504(s0)
    80004ee0:	e0043783          	ld	a5,-512(s0)
    80004ee4:	0387879b          	addiw	a5,a5,56
    80004ee8:	e8845703          	lhu	a4,-376(s0)
    80004eec:	e0e6dfe3          	bge	a3,a4,80004d0a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ef0:	2781                	sext.w	a5,a5
    80004ef2:	e0f43023          	sd	a5,-512(s0)
    80004ef6:	03800713          	li	a4,56
    80004efa:	86be                	mv	a3,a5
    80004efc:	e1840613          	addi	a2,s0,-488
    80004f00:	4581                	li	a1,0
    80004f02:	8556                	mv	a0,s5
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	a58080e7          	jalr	-1448(ra) # 8000395c <readi>
    80004f0c:	03800793          	li	a5,56
    80004f10:	f6f51be3          	bne	a0,a5,80004e86 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004f14:	e1842783          	lw	a5,-488(s0)
    80004f18:	4705                	li	a4,1
    80004f1a:	fae79de3          	bne	a5,a4,80004ed4 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004f1e:	e4043483          	ld	s1,-448(s0)
    80004f22:	e3843783          	ld	a5,-456(s0)
    80004f26:	f6f4ede3          	bltu	s1,a5,80004ea0 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f2a:	e2843783          	ld	a5,-472(s0)
    80004f2e:	94be                	add	s1,s1,a5
    80004f30:	f6f4ebe3          	bltu	s1,a5,80004ea6 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80004f34:	de043703          	ld	a4,-544(s0)
    80004f38:	8ff9                	and	a5,a5,a4
    80004f3a:	fbad                	bnez	a5,80004eac <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f3c:	e1c42503          	lw	a0,-484(s0)
    80004f40:	00000097          	auipc	ra,0x0
    80004f44:	c5c080e7          	jalr	-932(ra) # 80004b9c <flags2perm>
    80004f48:	86aa                	mv	a3,a0
    80004f4a:	8626                	mv	a2,s1
    80004f4c:	85ca                	mv	a1,s2
    80004f4e:	855a                	mv	a0,s6
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	4c0080e7          	jalr	1216(ra) # 80001410 <uvmalloc>
    80004f58:	dea43c23          	sd	a0,-520(s0)
    80004f5c:	d939                	beqz	a0,80004eb2 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f5e:	e2843c03          	ld	s8,-472(s0)
    80004f62:	e2042c83          	lw	s9,-480(s0)
    80004f66:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f6a:	f60b83e3          	beqz	s7,80004ed0 <exec+0x31a>
    80004f6e:	89de                	mv	s3,s7
    80004f70:	4481                	li	s1,0
    80004f72:	bb9d                	j	80004ce8 <exec+0x132>

0000000080004f74 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f74:	7179                	addi	sp,sp,-48
    80004f76:	f406                	sd	ra,40(sp)
    80004f78:	f022                	sd	s0,32(sp)
    80004f7a:	ec26                	sd	s1,24(sp)
    80004f7c:	e84a                	sd	s2,16(sp)
    80004f7e:	1800                	addi	s0,sp,48
    80004f80:	892e                	mv	s2,a1
    80004f82:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f84:	fdc40593          	addi	a1,s0,-36
    80004f88:	ffffe097          	auipc	ra,0xffffe
    80004f8c:	bb6080e7          	jalr	-1098(ra) # 80002b3e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f90:	fdc42703          	lw	a4,-36(s0)
    80004f94:	47bd                	li	a5,15
    80004f96:	02e7eb63          	bltu	a5,a4,80004fcc <argfd+0x58>
    80004f9a:	ffffd097          	auipc	ra,0xffffd
    80004f9e:	a1a080e7          	jalr	-1510(ra) # 800019b4 <myproc>
    80004fa2:	fdc42703          	lw	a4,-36(s0)
    80004fa6:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd0ba>
    80004faa:	078e                	slli	a5,a5,0x3
    80004fac:	953e                	add	a0,a0,a5
    80004fae:	611c                	ld	a5,0(a0)
    80004fb0:	c385                	beqz	a5,80004fd0 <argfd+0x5c>
    return -1;
  if(pfd)
    80004fb2:	00090463          	beqz	s2,80004fba <argfd+0x46>
    *pfd = fd;
    80004fb6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fba:	4501                	li	a0,0
  if(pf)
    80004fbc:	c091                	beqz	s1,80004fc0 <argfd+0x4c>
    *pf = f;
    80004fbe:	e09c                	sd	a5,0(s1)
}
    80004fc0:	70a2                	ld	ra,40(sp)
    80004fc2:	7402                	ld	s0,32(sp)
    80004fc4:	64e2                	ld	s1,24(sp)
    80004fc6:	6942                	ld	s2,16(sp)
    80004fc8:	6145                	addi	sp,sp,48
    80004fca:	8082                	ret
    return -1;
    80004fcc:	557d                	li	a0,-1
    80004fce:	bfcd                	j	80004fc0 <argfd+0x4c>
    80004fd0:	557d                	li	a0,-1
    80004fd2:	b7fd                	j	80004fc0 <argfd+0x4c>

0000000080004fd4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fd4:	1101                	addi	sp,sp,-32
    80004fd6:	ec06                	sd	ra,24(sp)
    80004fd8:	e822                	sd	s0,16(sp)
    80004fda:	e426                	sd	s1,8(sp)
    80004fdc:	1000                	addi	s0,sp,32
    80004fde:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	9d4080e7          	jalr	-1580(ra) # 800019b4 <myproc>
    80004fe8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fea:	0d050793          	addi	a5,a0,208
    80004fee:	4501                	li	a0,0
    80004ff0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ff2:	6398                	ld	a4,0(a5)
    80004ff4:	cb19                	beqz	a4,8000500a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ff6:	2505                	addiw	a0,a0,1
    80004ff8:	07a1                	addi	a5,a5,8
    80004ffa:	fed51ce3          	bne	a0,a3,80004ff2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ffe:	557d                	li	a0,-1
}
    80005000:	60e2                	ld	ra,24(sp)
    80005002:	6442                	ld	s0,16(sp)
    80005004:	64a2                	ld	s1,8(sp)
    80005006:	6105                	addi	sp,sp,32
    80005008:	8082                	ret
      p->ofile[fd] = f;
    8000500a:	01a50793          	addi	a5,a0,26
    8000500e:	078e                	slli	a5,a5,0x3
    80005010:	963e                	add	a2,a2,a5
    80005012:	e204                	sd	s1,0(a2)
      return fd;
    80005014:	b7f5                	j	80005000 <fdalloc+0x2c>

0000000080005016 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005016:	715d                	addi	sp,sp,-80
    80005018:	e486                	sd	ra,72(sp)
    8000501a:	e0a2                	sd	s0,64(sp)
    8000501c:	fc26                	sd	s1,56(sp)
    8000501e:	f84a                	sd	s2,48(sp)
    80005020:	f44e                	sd	s3,40(sp)
    80005022:	f052                	sd	s4,32(sp)
    80005024:	ec56                	sd	s5,24(sp)
    80005026:	e85a                	sd	s6,16(sp)
    80005028:	0880                	addi	s0,sp,80
    8000502a:	8b2e                	mv	s6,a1
    8000502c:	89b2                	mv	s3,a2
    8000502e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005030:	fb040593          	addi	a1,s0,-80
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	e3e080e7          	jalr	-450(ra) # 80003e72 <nameiparent>
    8000503c:	84aa                	mv	s1,a0
    8000503e:	14050f63          	beqz	a0,8000519c <create+0x186>
    return 0;

  ilock(dp);
    80005042:	ffffe097          	auipc	ra,0xffffe
    80005046:	666080e7          	jalr	1638(ra) # 800036a8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000504a:	4601                	li	a2,0
    8000504c:	fb040593          	addi	a1,s0,-80
    80005050:	8526                	mv	a0,s1
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	b3a080e7          	jalr	-1222(ra) # 80003b8c <dirlookup>
    8000505a:	8aaa                	mv	s5,a0
    8000505c:	c931                	beqz	a0,800050b0 <create+0x9a>
    iunlockput(dp);
    8000505e:	8526                	mv	a0,s1
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	8aa080e7          	jalr	-1878(ra) # 8000390a <iunlockput>
    ilock(ip);
    80005068:	8556                	mv	a0,s5
    8000506a:	ffffe097          	auipc	ra,0xffffe
    8000506e:	63e080e7          	jalr	1598(ra) # 800036a8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005072:	000b059b          	sext.w	a1,s6
    80005076:	4789                	li	a5,2
    80005078:	02f59563          	bne	a1,a5,800050a2 <create+0x8c>
    8000507c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0e4>
    80005080:	37f9                	addiw	a5,a5,-2
    80005082:	17c2                	slli	a5,a5,0x30
    80005084:	93c1                	srli	a5,a5,0x30
    80005086:	4705                	li	a4,1
    80005088:	00f76d63          	bltu	a4,a5,800050a2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000508c:	8556                	mv	a0,s5
    8000508e:	60a6                	ld	ra,72(sp)
    80005090:	6406                	ld	s0,64(sp)
    80005092:	74e2                	ld	s1,56(sp)
    80005094:	7942                	ld	s2,48(sp)
    80005096:	79a2                	ld	s3,40(sp)
    80005098:	7a02                	ld	s4,32(sp)
    8000509a:	6ae2                	ld	s5,24(sp)
    8000509c:	6b42                	ld	s6,16(sp)
    8000509e:	6161                	addi	sp,sp,80
    800050a0:	8082                	ret
    iunlockput(ip);
    800050a2:	8556                	mv	a0,s5
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	866080e7          	jalr	-1946(ra) # 8000390a <iunlockput>
    return 0;
    800050ac:	4a81                	li	s5,0
    800050ae:	bff9                	j	8000508c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800050b0:	85da                	mv	a1,s6
    800050b2:	4088                	lw	a0,0(s1)
    800050b4:	ffffe097          	auipc	ra,0xffffe
    800050b8:	456080e7          	jalr	1110(ra) # 8000350a <ialloc>
    800050bc:	8a2a                	mv	s4,a0
    800050be:	c539                	beqz	a0,8000510c <create+0xf6>
  ilock(ip);
    800050c0:	ffffe097          	auipc	ra,0xffffe
    800050c4:	5e8080e7          	jalr	1512(ra) # 800036a8 <ilock>
  ip->major = major;
    800050c8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800050cc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050d0:	4905                	li	s2,1
    800050d2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800050d6:	8552                	mv	a0,s4
    800050d8:	ffffe097          	auipc	ra,0xffffe
    800050dc:	504080e7          	jalr	1284(ra) # 800035dc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050e0:	000b059b          	sext.w	a1,s6
    800050e4:	03258b63          	beq	a1,s2,8000511a <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800050e8:	004a2603          	lw	a2,4(s4)
    800050ec:	fb040593          	addi	a1,s0,-80
    800050f0:	8526                	mv	a0,s1
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	cb0080e7          	jalr	-848(ra) # 80003da2 <dirlink>
    800050fa:	06054f63          	bltz	a0,80005178 <create+0x162>
  iunlockput(dp);
    800050fe:	8526                	mv	a0,s1
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	80a080e7          	jalr	-2038(ra) # 8000390a <iunlockput>
  return ip;
    80005108:	8ad2                	mv	s5,s4
    8000510a:	b749                	j	8000508c <create+0x76>
    iunlockput(dp);
    8000510c:	8526                	mv	a0,s1
    8000510e:	ffffe097          	auipc	ra,0xffffe
    80005112:	7fc080e7          	jalr	2044(ra) # 8000390a <iunlockput>
    return 0;
    80005116:	8ad2                	mv	s5,s4
    80005118:	bf95                	j	8000508c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000511a:	004a2603          	lw	a2,4(s4)
    8000511e:	00003597          	auipc	a1,0x3
    80005122:	5d258593          	addi	a1,a1,1490 # 800086f0 <syscalls+0x2a0>
    80005126:	8552                	mv	a0,s4
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	c7a080e7          	jalr	-902(ra) # 80003da2 <dirlink>
    80005130:	04054463          	bltz	a0,80005178 <create+0x162>
    80005134:	40d0                	lw	a2,4(s1)
    80005136:	00003597          	auipc	a1,0x3
    8000513a:	5c258593          	addi	a1,a1,1474 # 800086f8 <syscalls+0x2a8>
    8000513e:	8552                	mv	a0,s4
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	c62080e7          	jalr	-926(ra) # 80003da2 <dirlink>
    80005148:	02054863          	bltz	a0,80005178 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000514c:	004a2603          	lw	a2,4(s4)
    80005150:	fb040593          	addi	a1,s0,-80
    80005154:	8526                	mv	a0,s1
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	c4c080e7          	jalr	-948(ra) # 80003da2 <dirlink>
    8000515e:	00054d63          	bltz	a0,80005178 <create+0x162>
    dp->nlink++;  // for ".."
    80005162:	04a4d783          	lhu	a5,74(s1)
    80005166:	2785                	addiw	a5,a5,1
    80005168:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000516c:	8526                	mv	a0,s1
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	46e080e7          	jalr	1134(ra) # 800035dc <iupdate>
    80005176:	b761                	j	800050fe <create+0xe8>
  ip->nlink = 0;
    80005178:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000517c:	8552                	mv	a0,s4
    8000517e:	ffffe097          	auipc	ra,0xffffe
    80005182:	45e080e7          	jalr	1118(ra) # 800035dc <iupdate>
  iunlockput(ip);
    80005186:	8552                	mv	a0,s4
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	782080e7          	jalr	1922(ra) # 8000390a <iunlockput>
  iunlockput(dp);
    80005190:	8526                	mv	a0,s1
    80005192:	ffffe097          	auipc	ra,0xffffe
    80005196:	778080e7          	jalr	1912(ra) # 8000390a <iunlockput>
  return 0;
    8000519a:	bdcd                	j	8000508c <create+0x76>
    return 0;
    8000519c:	8aaa                	mv	s5,a0
    8000519e:	b5fd                	j	8000508c <create+0x76>

00000000800051a0 <sys_dup>:
{
    800051a0:	7179                	addi	sp,sp,-48
    800051a2:	f406                	sd	ra,40(sp)
    800051a4:	f022                	sd	s0,32(sp)
    800051a6:	ec26                	sd	s1,24(sp)
    800051a8:	e84a                	sd	s2,16(sp)
    800051aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051ac:	fd840613          	addi	a2,s0,-40
    800051b0:	4581                	li	a1,0
    800051b2:	4501                	li	a0,0
    800051b4:	00000097          	auipc	ra,0x0
    800051b8:	dc0080e7          	jalr	-576(ra) # 80004f74 <argfd>
    return -1;
    800051bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051be:	02054363          	bltz	a0,800051e4 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051c2:	fd843903          	ld	s2,-40(s0)
    800051c6:	854a                	mv	a0,s2
    800051c8:	00000097          	auipc	ra,0x0
    800051cc:	e0c080e7          	jalr	-500(ra) # 80004fd4 <fdalloc>
    800051d0:	84aa                	mv	s1,a0
    return -1;
    800051d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051d4:	00054863          	bltz	a0,800051e4 <sys_dup+0x44>
  filedup(f);
    800051d8:	854a                	mv	a0,s2
    800051da:	fffff097          	auipc	ra,0xfffff
    800051de:	310080e7          	jalr	784(ra) # 800044ea <filedup>
  return fd;
    800051e2:	87a6                	mv	a5,s1
}
    800051e4:	853e                	mv	a0,a5
    800051e6:	70a2                	ld	ra,40(sp)
    800051e8:	7402                	ld	s0,32(sp)
    800051ea:	64e2                	ld	s1,24(sp)
    800051ec:	6942                	ld	s2,16(sp)
    800051ee:	6145                	addi	sp,sp,48
    800051f0:	8082                	ret

00000000800051f2 <sys_read>:
{
    800051f2:	7179                	addi	sp,sp,-48
    800051f4:	f406                	sd	ra,40(sp)
    800051f6:	f022                	sd	s0,32(sp)
    800051f8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051fa:	fd840593          	addi	a1,s0,-40
    800051fe:	4505                	li	a0,1
    80005200:	ffffe097          	auipc	ra,0xffffe
    80005204:	95e080e7          	jalr	-1698(ra) # 80002b5e <argaddr>
  argint(2, &n);
    80005208:	fe440593          	addi	a1,s0,-28
    8000520c:	4509                	li	a0,2
    8000520e:	ffffe097          	auipc	ra,0xffffe
    80005212:	930080e7          	jalr	-1744(ra) # 80002b3e <argint>
  if(argfd(0, 0, &f) < 0)
    80005216:	fe840613          	addi	a2,s0,-24
    8000521a:	4581                	li	a1,0
    8000521c:	4501                	li	a0,0
    8000521e:	00000097          	auipc	ra,0x0
    80005222:	d56080e7          	jalr	-682(ra) # 80004f74 <argfd>
    80005226:	87aa                	mv	a5,a0
    return -1;
    80005228:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000522a:	0007cc63          	bltz	a5,80005242 <sys_read+0x50>
  return fileread(f, p, n);
    8000522e:	fe442603          	lw	a2,-28(s0)
    80005232:	fd843583          	ld	a1,-40(s0)
    80005236:	fe843503          	ld	a0,-24(s0)
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	43c080e7          	jalr	1084(ra) # 80004676 <fileread>
}
    80005242:	70a2                	ld	ra,40(sp)
    80005244:	7402                	ld	s0,32(sp)
    80005246:	6145                	addi	sp,sp,48
    80005248:	8082                	ret

000000008000524a <sys_write>:
{
    8000524a:	7179                	addi	sp,sp,-48
    8000524c:	f406                	sd	ra,40(sp)
    8000524e:	f022                	sd	s0,32(sp)
    80005250:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005252:	fd840593          	addi	a1,s0,-40
    80005256:	4505                	li	a0,1
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	906080e7          	jalr	-1786(ra) # 80002b5e <argaddr>
  argint(2, &n);
    80005260:	fe440593          	addi	a1,s0,-28
    80005264:	4509                	li	a0,2
    80005266:	ffffe097          	auipc	ra,0xffffe
    8000526a:	8d8080e7          	jalr	-1832(ra) # 80002b3e <argint>
  if(argfd(0, 0, &f) < 0)
    8000526e:	fe840613          	addi	a2,s0,-24
    80005272:	4581                	li	a1,0
    80005274:	4501                	li	a0,0
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	cfe080e7          	jalr	-770(ra) # 80004f74 <argfd>
    8000527e:	87aa                	mv	a5,a0
    return -1;
    80005280:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005282:	0007cc63          	bltz	a5,8000529a <sys_write+0x50>
  return filewrite(f, p, n);
    80005286:	fe442603          	lw	a2,-28(s0)
    8000528a:	fd843583          	ld	a1,-40(s0)
    8000528e:	fe843503          	ld	a0,-24(s0)
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	4a6080e7          	jalr	1190(ra) # 80004738 <filewrite>
}
    8000529a:	70a2                	ld	ra,40(sp)
    8000529c:	7402                	ld	s0,32(sp)
    8000529e:	6145                	addi	sp,sp,48
    800052a0:	8082                	ret

00000000800052a2 <sys_close>:
{
    800052a2:	1101                	addi	sp,sp,-32
    800052a4:	ec06                	sd	ra,24(sp)
    800052a6:	e822                	sd	s0,16(sp)
    800052a8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052aa:	fe040613          	addi	a2,s0,-32
    800052ae:	fec40593          	addi	a1,s0,-20
    800052b2:	4501                	li	a0,0
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	cc0080e7          	jalr	-832(ra) # 80004f74 <argfd>
    return -1;
    800052bc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052be:	02054463          	bltz	a0,800052e6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052c2:	ffffc097          	auipc	ra,0xffffc
    800052c6:	6f2080e7          	jalr	1778(ra) # 800019b4 <myproc>
    800052ca:	fec42783          	lw	a5,-20(s0)
    800052ce:	07e9                	addi	a5,a5,26
    800052d0:	078e                	slli	a5,a5,0x3
    800052d2:	953e                	add	a0,a0,a5
    800052d4:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800052d8:	fe043503          	ld	a0,-32(s0)
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	260080e7          	jalr	608(ra) # 8000453c <fileclose>
  return 0;
    800052e4:	4781                	li	a5,0
}
    800052e6:	853e                	mv	a0,a5
    800052e8:	60e2                	ld	ra,24(sp)
    800052ea:	6442                	ld	s0,16(sp)
    800052ec:	6105                	addi	sp,sp,32
    800052ee:	8082                	ret

00000000800052f0 <sys_fstat>:
{
    800052f0:	1101                	addi	sp,sp,-32
    800052f2:	ec06                	sd	ra,24(sp)
    800052f4:	e822                	sd	s0,16(sp)
    800052f6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052f8:	fe040593          	addi	a1,s0,-32
    800052fc:	4505                	li	a0,1
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	860080e7          	jalr	-1952(ra) # 80002b5e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005306:	fe840613          	addi	a2,s0,-24
    8000530a:	4581                	li	a1,0
    8000530c:	4501                	li	a0,0
    8000530e:	00000097          	auipc	ra,0x0
    80005312:	c66080e7          	jalr	-922(ra) # 80004f74 <argfd>
    80005316:	87aa                	mv	a5,a0
    return -1;
    80005318:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000531a:	0007ca63          	bltz	a5,8000532e <sys_fstat+0x3e>
  return filestat(f, st);
    8000531e:	fe043583          	ld	a1,-32(s0)
    80005322:	fe843503          	ld	a0,-24(s0)
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	2de080e7          	jalr	734(ra) # 80004604 <filestat>
}
    8000532e:	60e2                	ld	ra,24(sp)
    80005330:	6442                	ld	s0,16(sp)
    80005332:	6105                	addi	sp,sp,32
    80005334:	8082                	ret

0000000080005336 <sys_link>:
{
    80005336:	7169                	addi	sp,sp,-304
    80005338:	f606                	sd	ra,296(sp)
    8000533a:	f222                	sd	s0,288(sp)
    8000533c:	ee26                	sd	s1,280(sp)
    8000533e:	ea4a                	sd	s2,272(sp)
    80005340:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005342:	08000613          	li	a2,128
    80005346:	ed040593          	addi	a1,s0,-304
    8000534a:	4501                	li	a0,0
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	832080e7          	jalr	-1998(ra) # 80002b7e <argstr>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005356:	10054e63          	bltz	a0,80005472 <sys_link+0x13c>
    8000535a:	08000613          	li	a2,128
    8000535e:	f5040593          	addi	a1,s0,-176
    80005362:	4505                	li	a0,1
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	81a080e7          	jalr	-2022(ra) # 80002b7e <argstr>
    return -1;
    8000536c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000536e:	10054263          	bltz	a0,80005472 <sys_link+0x13c>
  begin_op();
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	d02080e7          	jalr	-766(ra) # 80004074 <begin_op>
  if((ip = namei(old)) == 0){
    8000537a:	ed040513          	addi	a0,s0,-304
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	ad6080e7          	jalr	-1322(ra) # 80003e54 <namei>
    80005386:	84aa                	mv	s1,a0
    80005388:	c551                	beqz	a0,80005414 <sys_link+0xde>
  ilock(ip);
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	31e080e7          	jalr	798(ra) # 800036a8 <ilock>
  if(ip->type == T_DIR){
    80005392:	04449703          	lh	a4,68(s1)
    80005396:	4785                	li	a5,1
    80005398:	08f70463          	beq	a4,a5,80005420 <sys_link+0xea>
  ip->nlink++;
    8000539c:	04a4d783          	lhu	a5,74(s1)
    800053a0:	2785                	addiw	a5,a5,1
    800053a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053a6:	8526                	mv	a0,s1
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	234080e7          	jalr	564(ra) # 800035dc <iupdate>
  iunlock(ip);
    800053b0:	8526                	mv	a0,s1
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	3b8080e7          	jalr	952(ra) # 8000376a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053ba:	fd040593          	addi	a1,s0,-48
    800053be:	f5040513          	addi	a0,s0,-176
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	ab0080e7          	jalr	-1360(ra) # 80003e72 <nameiparent>
    800053ca:	892a                	mv	s2,a0
    800053cc:	c935                	beqz	a0,80005440 <sys_link+0x10a>
  ilock(dp);
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	2da080e7          	jalr	730(ra) # 800036a8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053d6:	00092703          	lw	a4,0(s2)
    800053da:	409c                	lw	a5,0(s1)
    800053dc:	04f71d63          	bne	a4,a5,80005436 <sys_link+0x100>
    800053e0:	40d0                	lw	a2,4(s1)
    800053e2:	fd040593          	addi	a1,s0,-48
    800053e6:	854a                	mv	a0,s2
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	9ba080e7          	jalr	-1606(ra) # 80003da2 <dirlink>
    800053f0:	04054363          	bltz	a0,80005436 <sys_link+0x100>
  iunlockput(dp);
    800053f4:	854a                	mv	a0,s2
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	514080e7          	jalr	1300(ra) # 8000390a <iunlockput>
  iput(ip);
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	462080e7          	jalr	1122(ra) # 80003862 <iput>
  end_op();
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	cea080e7          	jalr	-790(ra) # 800040f2 <end_op>
  return 0;
    80005410:	4781                	li	a5,0
    80005412:	a085                	j	80005472 <sys_link+0x13c>
    end_op();
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	cde080e7          	jalr	-802(ra) # 800040f2 <end_op>
    return -1;
    8000541c:	57fd                	li	a5,-1
    8000541e:	a891                	j	80005472 <sys_link+0x13c>
    iunlockput(ip);
    80005420:	8526                	mv	a0,s1
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	4e8080e7          	jalr	1256(ra) # 8000390a <iunlockput>
    end_op();
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	cc8080e7          	jalr	-824(ra) # 800040f2 <end_op>
    return -1;
    80005432:	57fd                	li	a5,-1
    80005434:	a83d                	j	80005472 <sys_link+0x13c>
    iunlockput(dp);
    80005436:	854a                	mv	a0,s2
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	4d2080e7          	jalr	1234(ra) # 8000390a <iunlockput>
  ilock(ip);
    80005440:	8526                	mv	a0,s1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	266080e7          	jalr	614(ra) # 800036a8 <ilock>
  ip->nlink--;
    8000544a:	04a4d783          	lhu	a5,74(s1)
    8000544e:	37fd                	addiw	a5,a5,-1
    80005450:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	186080e7          	jalr	390(ra) # 800035dc <iupdate>
  iunlockput(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	4aa080e7          	jalr	1194(ra) # 8000390a <iunlockput>
  end_op();
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	c8a080e7          	jalr	-886(ra) # 800040f2 <end_op>
  return -1;
    80005470:	57fd                	li	a5,-1
}
    80005472:	853e                	mv	a0,a5
    80005474:	70b2                	ld	ra,296(sp)
    80005476:	7412                	ld	s0,288(sp)
    80005478:	64f2                	ld	s1,280(sp)
    8000547a:	6952                	ld	s2,272(sp)
    8000547c:	6155                	addi	sp,sp,304
    8000547e:	8082                	ret

0000000080005480 <sys_unlink>:
{
    80005480:	7151                	addi	sp,sp,-240
    80005482:	f586                	sd	ra,232(sp)
    80005484:	f1a2                	sd	s0,224(sp)
    80005486:	eda6                	sd	s1,216(sp)
    80005488:	e9ca                	sd	s2,208(sp)
    8000548a:	e5ce                	sd	s3,200(sp)
    8000548c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000548e:	08000613          	li	a2,128
    80005492:	f3040593          	addi	a1,s0,-208
    80005496:	4501                	li	a0,0
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	6e6080e7          	jalr	1766(ra) # 80002b7e <argstr>
    800054a0:	18054163          	bltz	a0,80005622 <sys_unlink+0x1a2>
  begin_op();
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	bd0080e7          	jalr	-1072(ra) # 80004074 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054ac:	fb040593          	addi	a1,s0,-80
    800054b0:	f3040513          	addi	a0,s0,-208
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	9be080e7          	jalr	-1602(ra) # 80003e72 <nameiparent>
    800054bc:	84aa                	mv	s1,a0
    800054be:	c979                	beqz	a0,80005594 <sys_unlink+0x114>
  ilock(dp);
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	1e8080e7          	jalr	488(ra) # 800036a8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054c8:	00003597          	auipc	a1,0x3
    800054cc:	22858593          	addi	a1,a1,552 # 800086f0 <syscalls+0x2a0>
    800054d0:	fb040513          	addi	a0,s0,-80
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	69e080e7          	jalr	1694(ra) # 80003b72 <namecmp>
    800054dc:	14050a63          	beqz	a0,80005630 <sys_unlink+0x1b0>
    800054e0:	00003597          	auipc	a1,0x3
    800054e4:	21858593          	addi	a1,a1,536 # 800086f8 <syscalls+0x2a8>
    800054e8:	fb040513          	addi	a0,s0,-80
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	686080e7          	jalr	1670(ra) # 80003b72 <namecmp>
    800054f4:	12050e63          	beqz	a0,80005630 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054f8:	f2c40613          	addi	a2,s0,-212
    800054fc:	fb040593          	addi	a1,s0,-80
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	68a080e7          	jalr	1674(ra) # 80003b8c <dirlookup>
    8000550a:	892a                	mv	s2,a0
    8000550c:	12050263          	beqz	a0,80005630 <sys_unlink+0x1b0>
  ilock(ip);
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	198080e7          	jalr	408(ra) # 800036a8 <ilock>
  if(ip->nlink < 1)
    80005518:	04a91783          	lh	a5,74(s2)
    8000551c:	08f05263          	blez	a5,800055a0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005520:	04491703          	lh	a4,68(s2)
    80005524:	4785                	li	a5,1
    80005526:	08f70563          	beq	a4,a5,800055b0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000552a:	4641                	li	a2,16
    8000552c:	4581                	li	a1,0
    8000552e:	fc040513          	addi	a0,s0,-64
    80005532:	ffffb097          	auipc	ra,0xffffb
    80005536:	7a0080e7          	jalr	1952(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000553a:	4741                	li	a4,16
    8000553c:	f2c42683          	lw	a3,-212(s0)
    80005540:	fc040613          	addi	a2,s0,-64
    80005544:	4581                	li	a1,0
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	50c080e7          	jalr	1292(ra) # 80003a54 <writei>
    80005550:	47c1                	li	a5,16
    80005552:	0af51563          	bne	a0,a5,800055fc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005556:	04491703          	lh	a4,68(s2)
    8000555a:	4785                	li	a5,1
    8000555c:	0af70863          	beq	a4,a5,8000560c <sys_unlink+0x18c>
  iunlockput(dp);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	3a8080e7          	jalr	936(ra) # 8000390a <iunlockput>
  ip->nlink--;
    8000556a:	04a95783          	lhu	a5,74(s2)
    8000556e:	37fd                	addiw	a5,a5,-1
    80005570:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	066080e7          	jalr	102(ra) # 800035dc <iupdate>
  iunlockput(ip);
    8000557e:	854a                	mv	a0,s2
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	38a080e7          	jalr	906(ra) # 8000390a <iunlockput>
  end_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	b6a080e7          	jalr	-1174(ra) # 800040f2 <end_op>
  return 0;
    80005590:	4501                	li	a0,0
    80005592:	a84d                	j	80005644 <sys_unlink+0x1c4>
    end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	b5e080e7          	jalr	-1186(ra) # 800040f2 <end_op>
    return -1;
    8000559c:	557d                	li	a0,-1
    8000559e:	a05d                	j	80005644 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055a0:	00003517          	auipc	a0,0x3
    800055a4:	16050513          	addi	a0,a0,352 # 80008700 <syscalls+0x2b0>
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	f98080e7          	jalr	-104(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055b0:	04c92703          	lw	a4,76(s2)
    800055b4:	02000793          	li	a5,32
    800055b8:	f6e7f9e3          	bgeu	a5,a4,8000552a <sys_unlink+0xaa>
    800055bc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055c0:	4741                	li	a4,16
    800055c2:	86ce                	mv	a3,s3
    800055c4:	f1840613          	addi	a2,s0,-232
    800055c8:	4581                	li	a1,0
    800055ca:	854a                	mv	a0,s2
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	390080e7          	jalr	912(ra) # 8000395c <readi>
    800055d4:	47c1                	li	a5,16
    800055d6:	00f51b63          	bne	a0,a5,800055ec <sys_unlink+0x16c>
    if(de.inum != 0)
    800055da:	f1845783          	lhu	a5,-232(s0)
    800055de:	e7a1                	bnez	a5,80005626 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055e0:	29c1                	addiw	s3,s3,16
    800055e2:	04c92783          	lw	a5,76(s2)
    800055e6:	fcf9ede3          	bltu	s3,a5,800055c0 <sys_unlink+0x140>
    800055ea:	b781                	j	8000552a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055ec:	00003517          	auipc	a0,0x3
    800055f0:	12c50513          	addi	a0,a0,300 # 80008718 <syscalls+0x2c8>
    800055f4:	ffffb097          	auipc	ra,0xffffb
    800055f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
    panic("unlink: writei");
    800055fc:	00003517          	auipc	a0,0x3
    80005600:	13450513          	addi	a0,a0,308 # 80008730 <syscalls+0x2e0>
    80005604:	ffffb097          	auipc	ra,0xffffb
    80005608:	f3c080e7          	jalr	-196(ra) # 80000540 <panic>
    dp->nlink--;
    8000560c:	04a4d783          	lhu	a5,74(s1)
    80005610:	37fd                	addiw	a5,a5,-1
    80005612:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	fc4080e7          	jalr	-60(ra) # 800035dc <iupdate>
    80005620:	b781                	j	80005560 <sys_unlink+0xe0>
    return -1;
    80005622:	557d                	li	a0,-1
    80005624:	a005                	j	80005644 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005626:	854a                	mv	a0,s2
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	2e2080e7          	jalr	738(ra) # 8000390a <iunlockput>
  iunlockput(dp);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	2d8080e7          	jalr	728(ra) # 8000390a <iunlockput>
  end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	ab8080e7          	jalr	-1352(ra) # 800040f2 <end_op>
  return -1;
    80005642:	557d                	li	a0,-1
}
    80005644:	70ae                	ld	ra,232(sp)
    80005646:	740e                	ld	s0,224(sp)
    80005648:	64ee                	ld	s1,216(sp)
    8000564a:	694e                	ld	s2,208(sp)
    8000564c:	69ae                	ld	s3,200(sp)
    8000564e:	616d                	addi	sp,sp,240
    80005650:	8082                	ret

0000000080005652 <sys_open>:

uint64
sys_open(void)
{
    80005652:	7131                	addi	sp,sp,-192
    80005654:	fd06                	sd	ra,184(sp)
    80005656:	f922                	sd	s0,176(sp)
    80005658:	f526                	sd	s1,168(sp)
    8000565a:	f14a                	sd	s2,160(sp)
    8000565c:	ed4e                	sd	s3,152(sp)
    8000565e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005660:	f4c40593          	addi	a1,s0,-180
    80005664:	4505                	li	a0,1
    80005666:	ffffd097          	auipc	ra,0xffffd
    8000566a:	4d8080e7          	jalr	1240(ra) # 80002b3e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000566e:	08000613          	li	a2,128
    80005672:	f5040593          	addi	a1,s0,-176
    80005676:	4501                	li	a0,0
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	506080e7          	jalr	1286(ra) # 80002b7e <argstr>
    80005680:	87aa                	mv	a5,a0
    return -1;
    80005682:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005684:	0a07c963          	bltz	a5,80005736 <sys_open+0xe4>

  begin_op();
    80005688:	fffff097          	auipc	ra,0xfffff
    8000568c:	9ec080e7          	jalr	-1556(ra) # 80004074 <begin_op>

  if(omode & O_CREATE){
    80005690:	f4c42783          	lw	a5,-180(s0)
    80005694:	2007f793          	andi	a5,a5,512
    80005698:	cfc5                	beqz	a5,80005750 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000569a:	4681                	li	a3,0
    8000569c:	4601                	li	a2,0
    8000569e:	4589                	li	a1,2
    800056a0:	f5040513          	addi	a0,s0,-176
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	972080e7          	jalr	-1678(ra) # 80005016 <create>
    800056ac:	84aa                	mv	s1,a0
    if(ip == 0){
    800056ae:	c959                	beqz	a0,80005744 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056b0:	04449703          	lh	a4,68(s1)
    800056b4:	478d                	li	a5,3
    800056b6:	00f71763          	bne	a4,a5,800056c4 <sys_open+0x72>
    800056ba:	0464d703          	lhu	a4,70(s1)
    800056be:	47a5                	li	a5,9
    800056c0:	0ce7ed63          	bltu	a5,a4,8000579a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	dbc080e7          	jalr	-580(ra) # 80004480 <filealloc>
    800056cc:	89aa                	mv	s3,a0
    800056ce:	10050363          	beqz	a0,800057d4 <sys_open+0x182>
    800056d2:	00000097          	auipc	ra,0x0
    800056d6:	902080e7          	jalr	-1790(ra) # 80004fd4 <fdalloc>
    800056da:	892a                	mv	s2,a0
    800056dc:	0e054763          	bltz	a0,800057ca <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056e0:	04449703          	lh	a4,68(s1)
    800056e4:	478d                	li	a5,3
    800056e6:	0cf70563          	beq	a4,a5,800057b0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056ea:	4789                	li	a5,2
    800056ec:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056f0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056f4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056f8:	f4c42783          	lw	a5,-180(s0)
    800056fc:	0017c713          	xori	a4,a5,1
    80005700:	8b05                	andi	a4,a4,1
    80005702:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005706:	0037f713          	andi	a4,a5,3
    8000570a:	00e03733          	snez	a4,a4
    8000570e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005712:	4007f793          	andi	a5,a5,1024
    80005716:	c791                	beqz	a5,80005722 <sys_open+0xd0>
    80005718:	04449703          	lh	a4,68(s1)
    8000571c:	4789                	li	a5,2
    8000571e:	0af70063          	beq	a4,a5,800057be <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005722:	8526                	mv	a0,s1
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	046080e7          	jalr	70(ra) # 8000376a <iunlock>
  end_op();
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	9c6080e7          	jalr	-1594(ra) # 800040f2 <end_op>

  return fd;
    80005734:	854a                	mv	a0,s2
}
    80005736:	70ea                	ld	ra,184(sp)
    80005738:	744a                	ld	s0,176(sp)
    8000573a:	74aa                	ld	s1,168(sp)
    8000573c:	790a                	ld	s2,160(sp)
    8000573e:	69ea                	ld	s3,152(sp)
    80005740:	6129                	addi	sp,sp,192
    80005742:	8082                	ret
      end_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	9ae080e7          	jalr	-1618(ra) # 800040f2 <end_op>
      return -1;
    8000574c:	557d                	li	a0,-1
    8000574e:	b7e5                	j	80005736 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005750:	f5040513          	addi	a0,s0,-176
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	700080e7          	jalr	1792(ra) # 80003e54 <namei>
    8000575c:	84aa                	mv	s1,a0
    8000575e:	c905                	beqz	a0,8000578e <sys_open+0x13c>
    ilock(ip);
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	f48080e7          	jalr	-184(ra) # 800036a8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005768:	04449703          	lh	a4,68(s1)
    8000576c:	4785                	li	a5,1
    8000576e:	f4f711e3          	bne	a4,a5,800056b0 <sys_open+0x5e>
    80005772:	f4c42783          	lw	a5,-180(s0)
    80005776:	d7b9                	beqz	a5,800056c4 <sys_open+0x72>
      iunlockput(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	190080e7          	jalr	400(ra) # 8000390a <iunlockput>
      end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	970080e7          	jalr	-1680(ra) # 800040f2 <end_op>
      return -1;
    8000578a:	557d                	li	a0,-1
    8000578c:	b76d                	j	80005736 <sys_open+0xe4>
      end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	964080e7          	jalr	-1692(ra) # 800040f2 <end_op>
      return -1;
    80005796:	557d                	li	a0,-1
    80005798:	bf79                	j	80005736 <sys_open+0xe4>
    iunlockput(ip);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	16e080e7          	jalr	366(ra) # 8000390a <iunlockput>
    end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	94e080e7          	jalr	-1714(ra) # 800040f2 <end_op>
    return -1;
    800057ac:	557d                	li	a0,-1
    800057ae:	b761                	j	80005736 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057b0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057b4:	04649783          	lh	a5,70(s1)
    800057b8:	02f99223          	sh	a5,36(s3)
    800057bc:	bf25                	j	800056f4 <sys_open+0xa2>
    itrunc(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	ff6080e7          	jalr	-10(ra) # 800037b6 <itrunc>
    800057c8:	bfa9                	j	80005722 <sys_open+0xd0>
      fileclose(f);
    800057ca:	854e                	mv	a0,s3
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	d70080e7          	jalr	-656(ra) # 8000453c <fileclose>
    iunlockput(ip);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	134080e7          	jalr	308(ra) # 8000390a <iunlockput>
    end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	914080e7          	jalr	-1772(ra) # 800040f2 <end_op>
    return -1;
    800057e6:	557d                	li	a0,-1
    800057e8:	b7b9                	j	80005736 <sys_open+0xe4>

00000000800057ea <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057ea:	7175                	addi	sp,sp,-144
    800057ec:	e506                	sd	ra,136(sp)
    800057ee:	e122                	sd	s0,128(sp)
    800057f0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	882080e7          	jalr	-1918(ra) # 80004074 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057fa:	08000613          	li	a2,128
    800057fe:	f7040593          	addi	a1,s0,-144
    80005802:	4501                	li	a0,0
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	37a080e7          	jalr	890(ra) # 80002b7e <argstr>
    8000580c:	02054963          	bltz	a0,8000583e <sys_mkdir+0x54>
    80005810:	4681                	li	a3,0
    80005812:	4601                	li	a2,0
    80005814:	4585                	li	a1,1
    80005816:	f7040513          	addi	a0,s0,-144
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	7fc080e7          	jalr	2044(ra) # 80005016 <create>
    80005822:	cd11                	beqz	a0,8000583e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	0e6080e7          	jalr	230(ra) # 8000390a <iunlockput>
  end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	8c6080e7          	jalr	-1850(ra) # 800040f2 <end_op>
  return 0;
    80005834:	4501                	li	a0,0
}
    80005836:	60aa                	ld	ra,136(sp)
    80005838:	640a                	ld	s0,128(sp)
    8000583a:	6149                	addi	sp,sp,144
    8000583c:	8082                	ret
    end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	8b4080e7          	jalr	-1868(ra) # 800040f2 <end_op>
    return -1;
    80005846:	557d                	li	a0,-1
    80005848:	b7fd                	j	80005836 <sys_mkdir+0x4c>

000000008000584a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000584a:	7135                	addi	sp,sp,-160
    8000584c:	ed06                	sd	ra,152(sp)
    8000584e:	e922                	sd	s0,144(sp)
    80005850:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	822080e7          	jalr	-2014(ra) # 80004074 <begin_op>
  argint(1, &major);
    8000585a:	f6c40593          	addi	a1,s0,-148
    8000585e:	4505                	li	a0,1
    80005860:	ffffd097          	auipc	ra,0xffffd
    80005864:	2de080e7          	jalr	734(ra) # 80002b3e <argint>
  argint(2, &minor);
    80005868:	f6840593          	addi	a1,s0,-152
    8000586c:	4509                	li	a0,2
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	2d0080e7          	jalr	720(ra) # 80002b3e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005876:	08000613          	li	a2,128
    8000587a:	f7040593          	addi	a1,s0,-144
    8000587e:	4501                	li	a0,0
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	2fe080e7          	jalr	766(ra) # 80002b7e <argstr>
    80005888:	02054b63          	bltz	a0,800058be <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000588c:	f6841683          	lh	a3,-152(s0)
    80005890:	f6c41603          	lh	a2,-148(s0)
    80005894:	458d                	li	a1,3
    80005896:	f7040513          	addi	a0,s0,-144
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	77c080e7          	jalr	1916(ra) # 80005016 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a2:	cd11                	beqz	a0,800058be <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	066080e7          	jalr	102(ra) # 8000390a <iunlockput>
  end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	846080e7          	jalr	-1978(ra) # 800040f2 <end_op>
  return 0;
    800058b4:	4501                	li	a0,0
}
    800058b6:	60ea                	ld	ra,152(sp)
    800058b8:	644a                	ld	s0,144(sp)
    800058ba:	610d                	addi	sp,sp,160
    800058bc:	8082                	ret
    end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	834080e7          	jalr	-1996(ra) # 800040f2 <end_op>
    return -1;
    800058c6:	557d                	li	a0,-1
    800058c8:	b7fd                	j	800058b6 <sys_mknod+0x6c>

00000000800058ca <sys_chdir>:

uint64
sys_chdir(void)
{
    800058ca:	7135                	addi	sp,sp,-160
    800058cc:	ed06                	sd	ra,152(sp)
    800058ce:	e922                	sd	s0,144(sp)
    800058d0:	e526                	sd	s1,136(sp)
    800058d2:	e14a                	sd	s2,128(sp)
    800058d4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058d6:	ffffc097          	auipc	ra,0xffffc
    800058da:	0de080e7          	jalr	222(ra) # 800019b4 <myproc>
    800058de:	892a                	mv	s2,a0
  
  begin_op();
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	794080e7          	jalr	1940(ra) # 80004074 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058e8:	08000613          	li	a2,128
    800058ec:	f6040593          	addi	a1,s0,-160
    800058f0:	4501                	li	a0,0
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	28c080e7          	jalr	652(ra) # 80002b7e <argstr>
    800058fa:	04054b63          	bltz	a0,80005950 <sys_chdir+0x86>
    800058fe:	f6040513          	addi	a0,s0,-160
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	552080e7          	jalr	1362(ra) # 80003e54 <namei>
    8000590a:	84aa                	mv	s1,a0
    8000590c:	c131                	beqz	a0,80005950 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	d9a080e7          	jalr	-614(ra) # 800036a8 <ilock>
  if(ip->type != T_DIR){
    80005916:	04449703          	lh	a4,68(s1)
    8000591a:	4785                	li	a5,1
    8000591c:	04f71063          	bne	a4,a5,8000595c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005920:	8526                	mv	a0,s1
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	e48080e7          	jalr	-440(ra) # 8000376a <iunlock>
  iput(p->cwd);
    8000592a:	15093503          	ld	a0,336(s2)
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	f34080e7          	jalr	-204(ra) # 80003862 <iput>
  end_op();
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	7bc080e7          	jalr	1980(ra) # 800040f2 <end_op>
  p->cwd = ip;
    8000593e:	14993823          	sd	s1,336(s2)
  return 0;
    80005942:	4501                	li	a0,0
}
    80005944:	60ea                	ld	ra,152(sp)
    80005946:	644a                	ld	s0,144(sp)
    80005948:	64aa                	ld	s1,136(sp)
    8000594a:	690a                	ld	s2,128(sp)
    8000594c:	610d                	addi	sp,sp,160
    8000594e:	8082                	ret
    end_op();
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	7a2080e7          	jalr	1954(ra) # 800040f2 <end_op>
    return -1;
    80005958:	557d                	li	a0,-1
    8000595a:	b7ed                	j	80005944 <sys_chdir+0x7a>
    iunlockput(ip);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	fac080e7          	jalr	-84(ra) # 8000390a <iunlockput>
    end_op();
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	78c080e7          	jalr	1932(ra) # 800040f2 <end_op>
    return -1;
    8000596e:	557d                	li	a0,-1
    80005970:	bfd1                	j	80005944 <sys_chdir+0x7a>

0000000080005972 <sys_exec>:

uint64
sys_exec(void)
{
    80005972:	7145                	addi	sp,sp,-464
    80005974:	e786                	sd	ra,456(sp)
    80005976:	e3a2                	sd	s0,448(sp)
    80005978:	ff26                	sd	s1,440(sp)
    8000597a:	fb4a                	sd	s2,432(sp)
    8000597c:	f74e                	sd	s3,424(sp)
    8000597e:	f352                	sd	s4,416(sp)
    80005980:	ef56                	sd	s5,408(sp)
    80005982:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005984:	e3840593          	addi	a1,s0,-456
    80005988:	4505                	li	a0,1
    8000598a:	ffffd097          	auipc	ra,0xffffd
    8000598e:	1d4080e7          	jalr	468(ra) # 80002b5e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005992:	08000613          	li	a2,128
    80005996:	f4040593          	addi	a1,s0,-192
    8000599a:	4501                	li	a0,0
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	1e2080e7          	jalr	482(ra) # 80002b7e <argstr>
    800059a4:	87aa                	mv	a5,a0
    return -1;
    800059a6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800059a8:	0c07c363          	bltz	a5,80005a6e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059ac:	10000613          	li	a2,256
    800059b0:	4581                	li	a1,0
    800059b2:	e4040513          	addi	a0,s0,-448
    800059b6:	ffffb097          	auipc	ra,0xffffb
    800059ba:	31c080e7          	jalr	796(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059be:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059c2:	89a6                	mv	s3,s1
    800059c4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059c6:	02000a13          	li	s4,32
    800059ca:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059ce:	00391513          	slli	a0,s2,0x3
    800059d2:	e3040593          	addi	a1,s0,-464
    800059d6:	e3843783          	ld	a5,-456(s0)
    800059da:	953e                	add	a0,a0,a5
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	0c4080e7          	jalr	196(ra) # 80002aa0 <fetchaddr>
    800059e4:	02054a63          	bltz	a0,80005a18 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800059e8:	e3043783          	ld	a5,-464(s0)
    800059ec:	c3b9                	beqz	a5,80005a32 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059ee:	ffffb097          	auipc	ra,0xffffb
    800059f2:	0f8080e7          	jalr	248(ra) # 80000ae6 <kalloc>
    800059f6:	85aa                	mv	a1,a0
    800059f8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059fc:	cd11                	beqz	a0,80005a18 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059fe:	6605                	lui	a2,0x1
    80005a00:	e3043503          	ld	a0,-464(s0)
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	0ee080e7          	jalr	238(ra) # 80002af2 <fetchstr>
    80005a0c:	00054663          	bltz	a0,80005a18 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a10:	0905                	addi	s2,s2,1
    80005a12:	09a1                	addi	s3,s3,8
    80005a14:	fb491be3          	bne	s2,s4,800059ca <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a18:	f4040913          	addi	s2,s0,-192
    80005a1c:	6088                	ld	a0,0(s1)
    80005a1e:	c539                	beqz	a0,80005a6c <sys_exec+0xfa>
    kfree(argv[i]);
    80005a20:	ffffb097          	auipc	ra,0xffffb
    80005a24:	fc8080e7          	jalr	-56(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a28:	04a1                	addi	s1,s1,8
    80005a2a:	ff2499e3          	bne	s1,s2,80005a1c <sys_exec+0xaa>
  return -1;
    80005a2e:	557d                	li	a0,-1
    80005a30:	a83d                	j	80005a6e <sys_exec+0xfc>
      argv[i] = 0;
    80005a32:	0a8e                	slli	s5,s5,0x3
    80005a34:	fc0a8793          	addi	a5,s5,-64
    80005a38:	00878ab3          	add	s5,a5,s0
    80005a3c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a40:	e4040593          	addi	a1,s0,-448
    80005a44:	f4040513          	addi	a0,s0,-192
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	16e080e7          	jalr	366(ra) # 80004bb6 <exec>
    80005a50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a52:	f4040993          	addi	s3,s0,-192
    80005a56:	6088                	ld	a0,0(s1)
    80005a58:	c901                	beqz	a0,80005a68 <sys_exec+0xf6>
    kfree(argv[i]);
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	f8e080e7          	jalr	-114(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a62:	04a1                	addi	s1,s1,8
    80005a64:	ff3499e3          	bne	s1,s3,80005a56 <sys_exec+0xe4>
  return ret;
    80005a68:	854a                	mv	a0,s2
    80005a6a:	a011                	j	80005a6e <sys_exec+0xfc>
  return -1;
    80005a6c:	557d                	li	a0,-1
}
    80005a6e:	60be                	ld	ra,456(sp)
    80005a70:	641e                	ld	s0,448(sp)
    80005a72:	74fa                	ld	s1,440(sp)
    80005a74:	795a                	ld	s2,432(sp)
    80005a76:	79ba                	ld	s3,424(sp)
    80005a78:	7a1a                	ld	s4,416(sp)
    80005a7a:	6afa                	ld	s5,408(sp)
    80005a7c:	6179                	addi	sp,sp,464
    80005a7e:	8082                	ret

0000000080005a80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a80:	7139                	addi	sp,sp,-64
    80005a82:	fc06                	sd	ra,56(sp)
    80005a84:	f822                	sd	s0,48(sp)
    80005a86:	f426                	sd	s1,40(sp)
    80005a88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a8a:	ffffc097          	auipc	ra,0xffffc
    80005a8e:	f2a080e7          	jalr	-214(ra) # 800019b4 <myproc>
    80005a92:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a94:	fd840593          	addi	a1,s0,-40
    80005a98:	4501                	li	a0,0
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	0c4080e7          	jalr	196(ra) # 80002b5e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005aa2:	fc840593          	addi	a1,s0,-56
    80005aa6:	fd040513          	addi	a0,s0,-48
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	dc2080e7          	jalr	-574(ra) # 8000486c <pipealloc>
    return -1;
    80005ab2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ab4:	0c054463          	bltz	a0,80005b7c <sys_pipe+0xfc>
  fd0 = -1;
    80005ab8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005abc:	fd043503          	ld	a0,-48(s0)
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	514080e7          	jalr	1300(ra) # 80004fd4 <fdalloc>
    80005ac8:	fca42223          	sw	a0,-60(s0)
    80005acc:	08054b63          	bltz	a0,80005b62 <sys_pipe+0xe2>
    80005ad0:	fc843503          	ld	a0,-56(s0)
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	500080e7          	jalr	1280(ra) # 80004fd4 <fdalloc>
    80005adc:	fca42023          	sw	a0,-64(s0)
    80005ae0:	06054863          	bltz	a0,80005b50 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ae4:	4691                	li	a3,4
    80005ae6:	fc440613          	addi	a2,s0,-60
    80005aea:	fd843583          	ld	a1,-40(s0)
    80005aee:	68a8                	ld	a0,80(s1)
    80005af0:	ffffc097          	auipc	ra,0xffffc
    80005af4:	b7c080e7          	jalr	-1156(ra) # 8000166c <copyout>
    80005af8:	02054063          	bltz	a0,80005b18 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005afc:	4691                	li	a3,4
    80005afe:	fc040613          	addi	a2,s0,-64
    80005b02:	fd843583          	ld	a1,-40(s0)
    80005b06:	0591                	addi	a1,a1,4
    80005b08:	68a8                	ld	a0,80(s1)
    80005b0a:	ffffc097          	auipc	ra,0xffffc
    80005b0e:	b62080e7          	jalr	-1182(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b12:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b14:	06055463          	bgez	a0,80005b7c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b18:	fc442783          	lw	a5,-60(s0)
    80005b1c:	07e9                	addi	a5,a5,26
    80005b1e:	078e                	slli	a5,a5,0x3
    80005b20:	97a6                	add	a5,a5,s1
    80005b22:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b26:	fc042783          	lw	a5,-64(s0)
    80005b2a:	07e9                	addi	a5,a5,26
    80005b2c:	078e                	slli	a5,a5,0x3
    80005b2e:	94be                	add	s1,s1,a5
    80005b30:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b34:	fd043503          	ld	a0,-48(s0)
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	a04080e7          	jalr	-1532(ra) # 8000453c <fileclose>
    fileclose(wf);
    80005b40:	fc843503          	ld	a0,-56(s0)
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	9f8080e7          	jalr	-1544(ra) # 8000453c <fileclose>
    return -1;
    80005b4c:	57fd                	li	a5,-1
    80005b4e:	a03d                	j	80005b7c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b50:	fc442783          	lw	a5,-60(s0)
    80005b54:	0007c763          	bltz	a5,80005b62 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b58:	07e9                	addi	a5,a5,26
    80005b5a:	078e                	slli	a5,a5,0x3
    80005b5c:	97a6                	add	a5,a5,s1
    80005b5e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b62:	fd043503          	ld	a0,-48(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	9d6080e7          	jalr	-1578(ra) # 8000453c <fileclose>
    fileclose(wf);
    80005b6e:	fc843503          	ld	a0,-56(s0)
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	9ca080e7          	jalr	-1590(ra) # 8000453c <fileclose>
    return -1;
    80005b7a:	57fd                	li	a5,-1
}
    80005b7c:	853e                	mv	a0,a5
    80005b7e:	70e2                	ld	ra,56(sp)
    80005b80:	7442                	ld	s0,48(sp)
    80005b82:	74a2                	ld	s1,40(sp)
    80005b84:	6121                	addi	sp,sp,64
    80005b86:	8082                	ret
	...

0000000080005b90 <kernelvec>:
    80005b90:	7111                	addi	sp,sp,-256
    80005b92:	e006                	sd	ra,0(sp)
    80005b94:	e40a                	sd	sp,8(sp)
    80005b96:	e80e                	sd	gp,16(sp)
    80005b98:	ec12                	sd	tp,24(sp)
    80005b9a:	f016                	sd	t0,32(sp)
    80005b9c:	f41a                	sd	t1,40(sp)
    80005b9e:	f81e                	sd	t2,48(sp)
    80005ba0:	fc22                	sd	s0,56(sp)
    80005ba2:	e0a6                	sd	s1,64(sp)
    80005ba4:	e4aa                	sd	a0,72(sp)
    80005ba6:	e8ae                	sd	a1,80(sp)
    80005ba8:	ecb2                	sd	a2,88(sp)
    80005baa:	f0b6                	sd	a3,96(sp)
    80005bac:	f4ba                	sd	a4,104(sp)
    80005bae:	f8be                	sd	a5,112(sp)
    80005bb0:	fcc2                	sd	a6,120(sp)
    80005bb2:	e146                	sd	a7,128(sp)
    80005bb4:	e54a                	sd	s2,136(sp)
    80005bb6:	e94e                	sd	s3,144(sp)
    80005bb8:	ed52                	sd	s4,152(sp)
    80005bba:	f156                	sd	s5,160(sp)
    80005bbc:	f55a                	sd	s6,168(sp)
    80005bbe:	f95e                	sd	s7,176(sp)
    80005bc0:	fd62                	sd	s8,184(sp)
    80005bc2:	e1e6                	sd	s9,192(sp)
    80005bc4:	e5ea                	sd	s10,200(sp)
    80005bc6:	e9ee                	sd	s11,208(sp)
    80005bc8:	edf2                	sd	t3,216(sp)
    80005bca:	f1f6                	sd	t4,224(sp)
    80005bcc:	f5fa                	sd	t5,232(sp)
    80005bce:	f9fe                	sd	t6,240(sp)
    80005bd0:	d9dfc0ef          	jal	ra,8000296c <kerneltrap>
    80005bd4:	6082                	ld	ra,0(sp)
    80005bd6:	6122                	ld	sp,8(sp)
    80005bd8:	61c2                	ld	gp,16(sp)
    80005bda:	7282                	ld	t0,32(sp)
    80005bdc:	7322                	ld	t1,40(sp)
    80005bde:	73c2                	ld	t2,48(sp)
    80005be0:	7462                	ld	s0,56(sp)
    80005be2:	6486                	ld	s1,64(sp)
    80005be4:	6526                	ld	a0,72(sp)
    80005be6:	65c6                	ld	a1,80(sp)
    80005be8:	6666                	ld	a2,88(sp)
    80005bea:	7686                	ld	a3,96(sp)
    80005bec:	7726                	ld	a4,104(sp)
    80005bee:	77c6                	ld	a5,112(sp)
    80005bf0:	7866                	ld	a6,120(sp)
    80005bf2:	688a                	ld	a7,128(sp)
    80005bf4:	692a                	ld	s2,136(sp)
    80005bf6:	69ca                	ld	s3,144(sp)
    80005bf8:	6a6a                	ld	s4,152(sp)
    80005bfa:	7a8a                	ld	s5,160(sp)
    80005bfc:	7b2a                	ld	s6,168(sp)
    80005bfe:	7bca                	ld	s7,176(sp)
    80005c00:	7c6a                	ld	s8,184(sp)
    80005c02:	6c8e                	ld	s9,192(sp)
    80005c04:	6d2e                	ld	s10,200(sp)
    80005c06:	6dce                	ld	s11,208(sp)
    80005c08:	6e6e                	ld	t3,216(sp)
    80005c0a:	7e8e                	ld	t4,224(sp)
    80005c0c:	7f2e                	ld	t5,232(sp)
    80005c0e:	7fce                	ld	t6,240(sp)
    80005c10:	6111                	addi	sp,sp,256
    80005c12:	10200073          	sret
    80005c16:	00000013          	nop
    80005c1a:	00000013          	nop
    80005c1e:	0001                	nop

0000000080005c20 <timervec>:
    80005c20:	34051573          	csrrw	a0,mscratch,a0
    80005c24:	e10c                	sd	a1,0(a0)
    80005c26:	e510                	sd	a2,8(a0)
    80005c28:	e914                	sd	a3,16(a0)
    80005c2a:	6d0c                	ld	a1,24(a0)
    80005c2c:	7110                	ld	a2,32(a0)
    80005c2e:	6194                	ld	a3,0(a1)
    80005c30:	96b2                	add	a3,a3,a2
    80005c32:	e194                	sd	a3,0(a1)
    80005c34:	4589                	li	a1,2
    80005c36:	14459073          	csrw	sip,a1
    80005c3a:	6914                	ld	a3,16(a0)
    80005c3c:	6510                	ld	a2,8(a0)
    80005c3e:	610c                	ld	a1,0(a0)
    80005c40:	34051573          	csrrw	a0,mscratch,a0
    80005c44:	30200073          	mret
	...

0000000080005c4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c4a:	1141                	addi	sp,sp,-16
    80005c4c:	e422                	sd	s0,8(sp)
    80005c4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c50:	0c0007b7          	lui	a5,0xc000
    80005c54:	4705                	li	a4,1
    80005c56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c58:	c3d8                	sw	a4,4(a5)
}
    80005c5a:	6422                	ld	s0,8(sp)
    80005c5c:	0141                	addi	sp,sp,16
    80005c5e:	8082                	ret

0000000080005c60 <plicinithart>:

void
plicinithart(void)
{
    80005c60:	1141                	addi	sp,sp,-16
    80005c62:	e406                	sd	ra,8(sp)
    80005c64:	e022                	sd	s0,0(sp)
    80005c66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	d20080e7          	jalr	-736(ra) # 80001988 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c70:	0085171b          	slliw	a4,a0,0x8
    80005c74:	0c0027b7          	lui	a5,0xc002
    80005c78:	97ba                	add	a5,a5,a4
    80005c7a:	40200713          	li	a4,1026
    80005c7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c82:	00d5151b          	slliw	a0,a0,0xd
    80005c86:	0c2017b7          	lui	a5,0xc201
    80005c8a:	97aa                	add	a5,a5,a0
    80005c8c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005c90:	60a2                	ld	ra,8(sp)
    80005c92:	6402                	ld	s0,0(sp)
    80005c94:	0141                	addi	sp,sp,16
    80005c96:	8082                	ret

0000000080005c98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c98:	1141                	addi	sp,sp,-16
    80005c9a:	e406                	sd	ra,8(sp)
    80005c9c:	e022                	sd	s0,0(sp)
    80005c9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ca0:	ffffc097          	auipc	ra,0xffffc
    80005ca4:	ce8080e7          	jalr	-792(ra) # 80001988 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ca8:	00d5151b          	slliw	a0,a0,0xd
    80005cac:	0c2017b7          	lui	a5,0xc201
    80005cb0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005cb2:	43c8                	lw	a0,4(a5)
    80005cb4:	60a2                	ld	ra,8(sp)
    80005cb6:	6402                	ld	s0,0(sp)
    80005cb8:	0141                	addi	sp,sp,16
    80005cba:	8082                	ret

0000000080005cbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cbc:	1101                	addi	sp,sp,-32
    80005cbe:	ec06                	sd	ra,24(sp)
    80005cc0:	e822                	sd	s0,16(sp)
    80005cc2:	e426                	sd	s1,8(sp)
    80005cc4:	1000                	addi	s0,sp,32
    80005cc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	cc0080e7          	jalr	-832(ra) # 80001988 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cd0:	00d5151b          	slliw	a0,a0,0xd
    80005cd4:	0c2017b7          	lui	a5,0xc201
    80005cd8:	97aa                	add	a5,a5,a0
    80005cda:	c3c4                	sw	s1,4(a5)
}
    80005cdc:	60e2                	ld	ra,24(sp)
    80005cde:	6442                	ld	s0,16(sp)
    80005ce0:	64a2                	ld	s1,8(sp)
    80005ce2:	6105                	addi	sp,sp,32
    80005ce4:	8082                	ret

0000000080005ce6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ce6:	1141                	addi	sp,sp,-16
    80005ce8:	e406                	sd	ra,8(sp)
    80005cea:	e022                	sd	s0,0(sp)
    80005cec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cee:	479d                	li	a5,7
    80005cf0:	04a7cc63          	blt	a5,a0,80005d48 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005cf4:	0001c797          	auipc	a5,0x1c
    80005cf8:	12c78793          	addi	a5,a5,300 # 80021e20 <disk>
    80005cfc:	97aa                	add	a5,a5,a0
    80005cfe:	0187c783          	lbu	a5,24(a5)
    80005d02:	ebb9                	bnez	a5,80005d58 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d04:	00451693          	slli	a3,a0,0x4
    80005d08:	0001c797          	auipc	a5,0x1c
    80005d0c:	11878793          	addi	a5,a5,280 # 80021e20 <disk>
    80005d10:	6398                	ld	a4,0(a5)
    80005d12:	9736                	add	a4,a4,a3
    80005d14:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005d18:	6398                	ld	a4,0(a5)
    80005d1a:	9736                	add	a4,a4,a3
    80005d1c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d20:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d24:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d28:	97aa                	add	a5,a5,a0
    80005d2a:	4705                	li	a4,1
    80005d2c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005d30:	0001c517          	auipc	a0,0x1c
    80005d34:	10850513          	addi	a0,a0,264 # 80021e38 <disk+0x18>
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	3f8080e7          	jalr	1016(ra) # 80002130 <wakeup>
}
    80005d40:	60a2                	ld	ra,8(sp)
    80005d42:	6402                	ld	s0,0(sp)
    80005d44:	0141                	addi	sp,sp,16
    80005d46:	8082                	ret
    panic("free_desc 1");
    80005d48:	00003517          	auipc	a0,0x3
    80005d4c:	9f850513          	addi	a0,a0,-1544 # 80008740 <syscalls+0x2f0>
    80005d50:	ffffa097          	auipc	ra,0xffffa
    80005d54:	7f0080e7          	jalr	2032(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005d58:	00003517          	auipc	a0,0x3
    80005d5c:	9f850513          	addi	a0,a0,-1544 # 80008750 <syscalls+0x300>
    80005d60:	ffffa097          	auipc	ra,0xffffa
    80005d64:	7e0080e7          	jalr	2016(ra) # 80000540 <panic>

0000000080005d68 <virtio_disk_init>:
{
    80005d68:	1101                	addi	sp,sp,-32
    80005d6a:	ec06                	sd	ra,24(sp)
    80005d6c:	e822                	sd	s0,16(sp)
    80005d6e:	e426                	sd	s1,8(sp)
    80005d70:	e04a                	sd	s2,0(sp)
    80005d72:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d74:	00003597          	auipc	a1,0x3
    80005d78:	9ec58593          	addi	a1,a1,-1556 # 80008760 <syscalls+0x310>
    80005d7c:	0001c517          	auipc	a0,0x1c
    80005d80:	1cc50513          	addi	a0,a0,460 # 80021f48 <disk+0x128>
    80005d84:	ffffb097          	auipc	ra,0xffffb
    80005d88:	dc2080e7          	jalr	-574(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d8c:	100017b7          	lui	a5,0x10001
    80005d90:	4398                	lw	a4,0(a5)
    80005d92:	2701                	sext.w	a4,a4
    80005d94:	747277b7          	lui	a5,0x74727
    80005d98:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d9c:	14f71b63          	bne	a4,a5,80005ef2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005da0:	100017b7          	lui	a5,0x10001
    80005da4:	43dc                	lw	a5,4(a5)
    80005da6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005da8:	4709                	li	a4,2
    80005daa:	14e79463          	bne	a5,a4,80005ef2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dae:	100017b7          	lui	a5,0x10001
    80005db2:	479c                	lw	a5,8(a5)
    80005db4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005db6:	12e79e63          	bne	a5,a4,80005ef2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dba:	100017b7          	lui	a5,0x10001
    80005dbe:	47d8                	lw	a4,12(a5)
    80005dc0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dc2:	554d47b7          	lui	a5,0x554d4
    80005dc6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dca:	12f71463          	bne	a4,a5,80005ef2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dce:	100017b7          	lui	a5,0x10001
    80005dd2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dd6:	4705                	li	a4,1
    80005dd8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dda:	470d                	li	a4,3
    80005ddc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dde:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005de0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005de4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7ff>
    80005de8:	8f75                	and	a4,a4,a3
    80005dea:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dec:	472d                	li	a4,11
    80005dee:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005df0:	5bbc                	lw	a5,112(a5)
    80005df2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005df6:	8ba1                	andi	a5,a5,8
    80005df8:	10078563          	beqz	a5,80005f02 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dfc:	100017b7          	lui	a5,0x10001
    80005e00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e04:	43fc                	lw	a5,68(a5)
    80005e06:	2781                	sext.w	a5,a5
    80005e08:	10079563          	bnez	a5,80005f12 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	5bdc                	lw	a5,52(a5)
    80005e12:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e14:	10078763          	beqz	a5,80005f22 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005e18:	471d                	li	a4,7
    80005e1a:	10f77c63          	bgeu	a4,a5,80005f32 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005e1e:	ffffb097          	auipc	ra,0xffffb
    80005e22:	cc8080e7          	jalr	-824(ra) # 80000ae6 <kalloc>
    80005e26:	0001c497          	auipc	s1,0x1c
    80005e2a:	ffa48493          	addi	s1,s1,-6 # 80021e20 <disk>
    80005e2e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e30:	ffffb097          	auipc	ra,0xffffb
    80005e34:	cb6080e7          	jalr	-842(ra) # 80000ae6 <kalloc>
    80005e38:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e3a:	ffffb097          	auipc	ra,0xffffb
    80005e3e:	cac080e7          	jalr	-852(ra) # 80000ae6 <kalloc>
    80005e42:	87aa                	mv	a5,a0
    80005e44:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e46:	6088                	ld	a0,0(s1)
    80005e48:	cd6d                	beqz	a0,80005f42 <virtio_disk_init+0x1da>
    80005e4a:	0001c717          	auipc	a4,0x1c
    80005e4e:	fde73703          	ld	a4,-34(a4) # 80021e28 <disk+0x8>
    80005e52:	cb65                	beqz	a4,80005f42 <virtio_disk_init+0x1da>
    80005e54:	c7fd                	beqz	a5,80005f42 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005e56:	6605                	lui	a2,0x1
    80005e58:	4581                	li	a1,0
    80005e5a:	ffffb097          	auipc	ra,0xffffb
    80005e5e:	e78080e7          	jalr	-392(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e62:	0001c497          	auipc	s1,0x1c
    80005e66:	fbe48493          	addi	s1,s1,-66 # 80021e20 <disk>
    80005e6a:	6605                	lui	a2,0x1
    80005e6c:	4581                	li	a1,0
    80005e6e:	6488                	ld	a0,8(s1)
    80005e70:	ffffb097          	auipc	ra,0xffffb
    80005e74:	e62080e7          	jalr	-414(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e78:	6605                	lui	a2,0x1
    80005e7a:	4581                	li	a1,0
    80005e7c:	6888                	ld	a0,16(s1)
    80005e7e:	ffffb097          	auipc	ra,0xffffb
    80005e82:	e54080e7          	jalr	-428(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e86:	100017b7          	lui	a5,0x10001
    80005e8a:	4721                	li	a4,8
    80005e8c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e8e:	4098                	lw	a4,0(s1)
    80005e90:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e94:	40d8                	lw	a4,4(s1)
    80005e96:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e9a:	6498                	ld	a4,8(s1)
    80005e9c:	0007069b          	sext.w	a3,a4
    80005ea0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005ea4:	9701                	srai	a4,a4,0x20
    80005ea6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005eaa:	6898                	ld	a4,16(s1)
    80005eac:	0007069b          	sext.w	a3,a4
    80005eb0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005eb4:	9701                	srai	a4,a4,0x20
    80005eb6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005eba:	4705                	li	a4,1
    80005ebc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005ebe:	00e48c23          	sb	a4,24(s1)
    80005ec2:	00e48ca3          	sb	a4,25(s1)
    80005ec6:	00e48d23          	sb	a4,26(s1)
    80005eca:	00e48da3          	sb	a4,27(s1)
    80005ece:	00e48e23          	sb	a4,28(s1)
    80005ed2:	00e48ea3          	sb	a4,29(s1)
    80005ed6:	00e48f23          	sb	a4,30(s1)
    80005eda:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ede:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee2:	0727a823          	sw	s2,112(a5)
}
    80005ee6:	60e2                	ld	ra,24(sp)
    80005ee8:	6442                	ld	s0,16(sp)
    80005eea:	64a2                	ld	s1,8(sp)
    80005eec:	6902                	ld	s2,0(sp)
    80005eee:	6105                	addi	sp,sp,32
    80005ef0:	8082                	ret
    panic("could not find virtio disk");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	87e50513          	addi	a0,a0,-1922 # 80008770 <syscalls+0x320>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	646080e7          	jalr	1606(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	88e50513          	addi	a0,a0,-1906 # 80008790 <syscalls+0x340>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	636080e7          	jalr	1590(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	89e50513          	addi	a0,a0,-1890 # 800087b0 <syscalls+0x360>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	626080e7          	jalr	1574(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	8ae50513          	addi	a0,a0,-1874 # 800087d0 <syscalls+0x380>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	616080e7          	jalr	1558(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	8be50513          	addi	a0,a0,-1858 # 800087f0 <syscalls+0x3a0>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	606080e7          	jalr	1542(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005f42:	00003517          	auipc	a0,0x3
    80005f46:	8ce50513          	addi	a0,a0,-1842 # 80008810 <syscalls+0x3c0>
    80005f4a:	ffffa097          	auipc	ra,0xffffa
    80005f4e:	5f6080e7          	jalr	1526(ra) # 80000540 <panic>

0000000080005f52 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f52:	7119                	addi	sp,sp,-128
    80005f54:	fc86                	sd	ra,120(sp)
    80005f56:	f8a2                	sd	s0,112(sp)
    80005f58:	f4a6                	sd	s1,104(sp)
    80005f5a:	f0ca                	sd	s2,96(sp)
    80005f5c:	ecce                	sd	s3,88(sp)
    80005f5e:	e8d2                	sd	s4,80(sp)
    80005f60:	e4d6                	sd	s5,72(sp)
    80005f62:	e0da                	sd	s6,64(sp)
    80005f64:	fc5e                	sd	s7,56(sp)
    80005f66:	f862                	sd	s8,48(sp)
    80005f68:	f466                	sd	s9,40(sp)
    80005f6a:	f06a                	sd	s10,32(sp)
    80005f6c:	ec6e                	sd	s11,24(sp)
    80005f6e:	0100                	addi	s0,sp,128
    80005f70:	8aaa                	mv	s5,a0
    80005f72:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f74:	00c52d03          	lw	s10,12(a0)
    80005f78:	001d1d1b          	slliw	s10,s10,0x1
    80005f7c:	1d02                	slli	s10,s10,0x20
    80005f7e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005f82:	0001c517          	auipc	a0,0x1c
    80005f86:	fc650513          	addi	a0,a0,-58 # 80021f48 <disk+0x128>
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	c4c080e7          	jalr	-948(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005f92:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f94:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f96:	0001cb97          	auipc	s7,0x1c
    80005f9a:	e8ab8b93          	addi	s7,s7,-374 # 80021e20 <disk>
  for(int i = 0; i < 3; i++){
    80005f9e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fa0:	0001cc97          	auipc	s9,0x1c
    80005fa4:	fa8c8c93          	addi	s9,s9,-88 # 80021f48 <disk+0x128>
    80005fa8:	a08d                	j	8000600a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005faa:	00fb8733          	add	a4,s7,a5
    80005fae:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fb2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fb4:	0207c563          	bltz	a5,80005fde <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005fb8:	2905                	addiw	s2,s2,1
    80005fba:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005fbc:	05690c63          	beq	s2,s6,80006014 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005fc0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005fc2:	0001c717          	auipc	a4,0x1c
    80005fc6:	e5e70713          	addi	a4,a4,-418 # 80021e20 <disk>
    80005fca:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005fcc:	01874683          	lbu	a3,24(a4)
    80005fd0:	fee9                	bnez	a3,80005faa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005fd2:	2785                	addiw	a5,a5,1
    80005fd4:	0705                	addi	a4,a4,1
    80005fd6:	fe979be3          	bne	a5,s1,80005fcc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005fda:	57fd                	li	a5,-1
    80005fdc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fde:	01205d63          	blez	s2,80005ff8 <virtio_disk_rw+0xa6>
    80005fe2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fe4:	000a2503          	lw	a0,0(s4)
    80005fe8:	00000097          	auipc	ra,0x0
    80005fec:	cfe080e7          	jalr	-770(ra) # 80005ce6 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff0:	2d85                	addiw	s11,s11,1
    80005ff2:	0a11                	addi	s4,s4,4
    80005ff4:	ff2d98e3          	bne	s11,s2,80005fe4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ff8:	85e6                	mv	a1,s9
    80005ffa:	0001c517          	auipc	a0,0x1c
    80005ffe:	e3e50513          	addi	a0,a0,-450 # 80021e38 <disk+0x18>
    80006002:	ffffc097          	auipc	ra,0xffffc
    80006006:	0ca080e7          	jalr	202(ra) # 800020cc <sleep>
  for(int i = 0; i < 3; i++){
    8000600a:	f8040a13          	addi	s4,s0,-128
{
    8000600e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006010:	894e                	mv	s2,s3
    80006012:	b77d                	j	80005fc0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006014:	f8042503          	lw	a0,-128(s0)
    80006018:	00a50713          	addi	a4,a0,10
    8000601c:	0712                	slli	a4,a4,0x4

  if(write)
    8000601e:	0001c797          	auipc	a5,0x1c
    80006022:	e0278793          	addi	a5,a5,-510 # 80021e20 <disk>
    80006026:	00e786b3          	add	a3,a5,a4
    8000602a:	01803633          	snez	a2,s8
    8000602e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006030:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006034:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006038:	f6070613          	addi	a2,a4,-160
    8000603c:	6394                	ld	a3,0(a5)
    8000603e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006040:	00870593          	addi	a1,a4,8
    80006044:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006046:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006048:	0007b803          	ld	a6,0(a5)
    8000604c:	9642                	add	a2,a2,a6
    8000604e:	46c1                	li	a3,16
    80006050:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006052:	4585                	li	a1,1
    80006054:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006058:	f8442683          	lw	a3,-124(s0)
    8000605c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006060:	0692                	slli	a3,a3,0x4
    80006062:	9836                	add	a6,a6,a3
    80006064:	058a8613          	addi	a2,s5,88
    80006068:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000606c:	0007b803          	ld	a6,0(a5)
    80006070:	96c2                	add	a3,a3,a6
    80006072:	40000613          	li	a2,1024
    80006076:	c690                	sw	a2,8(a3)
  if(write)
    80006078:	001c3613          	seqz	a2,s8
    8000607c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006080:	00166613          	ori	a2,a2,1
    80006084:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006088:	f8842603          	lw	a2,-120(s0)
    8000608c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006090:	00250693          	addi	a3,a0,2
    80006094:	0692                	slli	a3,a3,0x4
    80006096:	96be                	add	a3,a3,a5
    80006098:	58fd                	li	a7,-1
    8000609a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000609e:	0612                	slli	a2,a2,0x4
    800060a0:	9832                	add	a6,a6,a2
    800060a2:	f9070713          	addi	a4,a4,-112
    800060a6:	973e                	add	a4,a4,a5
    800060a8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800060ac:	6398                	ld	a4,0(a5)
    800060ae:	9732                	add	a4,a4,a2
    800060b0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060b2:	4609                	li	a2,2
    800060b4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800060b8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060bc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800060c0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060c4:	6794                	ld	a3,8(a5)
    800060c6:	0026d703          	lhu	a4,2(a3)
    800060ca:	8b1d                	andi	a4,a4,7
    800060cc:	0706                	slli	a4,a4,0x1
    800060ce:	96ba                	add	a3,a3,a4
    800060d0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800060d4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060d8:	6798                	ld	a4,8(a5)
    800060da:	00275783          	lhu	a5,2(a4)
    800060de:	2785                	addiw	a5,a5,1
    800060e0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060e4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060e8:	100017b7          	lui	a5,0x10001
    800060ec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060f0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800060f4:	0001c917          	auipc	s2,0x1c
    800060f8:	e5490913          	addi	s2,s2,-428 # 80021f48 <disk+0x128>
  while(b->disk == 1) {
    800060fc:	4485                	li	s1,1
    800060fe:	00b79c63          	bne	a5,a1,80006116 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006102:	85ca                	mv	a1,s2
    80006104:	8556                	mv	a0,s5
    80006106:	ffffc097          	auipc	ra,0xffffc
    8000610a:	fc6080e7          	jalr	-58(ra) # 800020cc <sleep>
  while(b->disk == 1) {
    8000610e:	004aa783          	lw	a5,4(s5)
    80006112:	fe9788e3          	beq	a5,s1,80006102 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006116:	f8042903          	lw	s2,-128(s0)
    8000611a:	00290713          	addi	a4,s2,2
    8000611e:	0712                	slli	a4,a4,0x4
    80006120:	0001c797          	auipc	a5,0x1c
    80006124:	d0078793          	addi	a5,a5,-768 # 80021e20 <disk>
    80006128:	97ba                	add	a5,a5,a4
    8000612a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000612e:	0001c997          	auipc	s3,0x1c
    80006132:	cf298993          	addi	s3,s3,-782 # 80021e20 <disk>
    80006136:	00491713          	slli	a4,s2,0x4
    8000613a:	0009b783          	ld	a5,0(s3)
    8000613e:	97ba                	add	a5,a5,a4
    80006140:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006144:	854a                	mv	a0,s2
    80006146:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000614a:	00000097          	auipc	ra,0x0
    8000614e:	b9c080e7          	jalr	-1124(ra) # 80005ce6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006152:	8885                	andi	s1,s1,1
    80006154:	f0ed                	bnez	s1,80006136 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006156:	0001c517          	auipc	a0,0x1c
    8000615a:	df250513          	addi	a0,a0,-526 # 80021f48 <disk+0x128>
    8000615e:	ffffb097          	auipc	ra,0xffffb
    80006162:	b2c080e7          	jalr	-1236(ra) # 80000c8a <release>
}
    80006166:	70e6                	ld	ra,120(sp)
    80006168:	7446                	ld	s0,112(sp)
    8000616a:	74a6                	ld	s1,104(sp)
    8000616c:	7906                	ld	s2,96(sp)
    8000616e:	69e6                	ld	s3,88(sp)
    80006170:	6a46                	ld	s4,80(sp)
    80006172:	6aa6                	ld	s5,72(sp)
    80006174:	6b06                	ld	s6,64(sp)
    80006176:	7be2                	ld	s7,56(sp)
    80006178:	7c42                	ld	s8,48(sp)
    8000617a:	7ca2                	ld	s9,40(sp)
    8000617c:	7d02                	ld	s10,32(sp)
    8000617e:	6de2                	ld	s11,24(sp)
    80006180:	6109                	addi	sp,sp,128
    80006182:	8082                	ret

0000000080006184 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006184:	1101                	addi	sp,sp,-32
    80006186:	ec06                	sd	ra,24(sp)
    80006188:	e822                	sd	s0,16(sp)
    8000618a:	e426                	sd	s1,8(sp)
    8000618c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000618e:	0001c497          	auipc	s1,0x1c
    80006192:	c9248493          	addi	s1,s1,-878 # 80021e20 <disk>
    80006196:	0001c517          	auipc	a0,0x1c
    8000619a:	db250513          	addi	a0,a0,-590 # 80021f48 <disk+0x128>
    8000619e:	ffffb097          	auipc	ra,0xffffb
    800061a2:	a38080e7          	jalr	-1480(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061a6:	10001737          	lui	a4,0x10001
    800061aa:	533c                	lw	a5,96(a4)
    800061ac:	8b8d                	andi	a5,a5,3
    800061ae:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061b0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061b4:	689c                	ld	a5,16(s1)
    800061b6:	0204d703          	lhu	a4,32(s1)
    800061ba:	0027d783          	lhu	a5,2(a5)
    800061be:	04f70863          	beq	a4,a5,8000620e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800061c2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061c6:	6898                	ld	a4,16(s1)
    800061c8:	0204d783          	lhu	a5,32(s1)
    800061cc:	8b9d                	andi	a5,a5,7
    800061ce:	078e                	slli	a5,a5,0x3
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061d4:	00278713          	addi	a4,a5,2
    800061d8:	0712                	slli	a4,a4,0x4
    800061da:	9726                	add	a4,a4,s1
    800061dc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800061e0:	e721                	bnez	a4,80006228 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061e2:	0789                	addi	a5,a5,2
    800061e4:	0792                	slli	a5,a5,0x4
    800061e6:	97a6                	add	a5,a5,s1
    800061e8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800061ea:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061ee:	ffffc097          	auipc	ra,0xffffc
    800061f2:	f42080e7          	jalr	-190(ra) # 80002130 <wakeup>

    disk.used_idx += 1;
    800061f6:	0204d783          	lhu	a5,32(s1)
    800061fa:	2785                	addiw	a5,a5,1
    800061fc:	17c2                	slli	a5,a5,0x30
    800061fe:	93c1                	srli	a5,a5,0x30
    80006200:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006204:	6898                	ld	a4,16(s1)
    80006206:	00275703          	lhu	a4,2(a4)
    8000620a:	faf71ce3          	bne	a4,a5,800061c2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000620e:	0001c517          	auipc	a0,0x1c
    80006212:	d3a50513          	addi	a0,a0,-710 # 80021f48 <disk+0x128>
    80006216:	ffffb097          	auipc	ra,0xffffb
    8000621a:	a74080e7          	jalr	-1420(ra) # 80000c8a <release>
}
    8000621e:	60e2                	ld	ra,24(sp)
    80006220:	6442                	ld	s0,16(sp)
    80006222:	64a2                	ld	s1,8(sp)
    80006224:	6105                	addi	sp,sp,32
    80006226:	8082                	ret
      panic("virtio_disk_intr status");
    80006228:	00002517          	auipc	a0,0x2
    8000622c:	60050513          	addi	a0,a0,1536 # 80008828 <syscalls+0x3d8>
    80006230:	ffffa097          	auipc	ra,0xffffa
    80006234:	310080e7          	jalr	784(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
