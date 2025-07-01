
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00005117          	auipc	sp,0x5
    80000004:	1f010113          	addi	sp,sp,496 # 800051f0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000052:	00005717          	auipc	a4,0x5
    80000056:	05e70713          	addi	a4,a4,94 # 800050b0 <timer_scratch>
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
    80000064:	00002797          	auipc	a5,0x2
    80000068:	40c78793          	addi	a5,a5,1036 # 80002470 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffed74f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	92e78793          	addi	a5,a5,-1746 # 800009dc <main>
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
    800000e6:	f37ff0ef          	jal	ra,8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ea:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000ee:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f0:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f2:	30200073          	mret
}
    800000f6:	60a2                	ld	ra,8(sp)
    800000f8:	6402                	ld	s0,0(sp)
    800000fa:	0141                	addi	sp,sp,16
    800000fc:	8082                	ret

00000000800000fe <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800000fe:	7179                	addi	sp,sp,-48
    80000100:	f406                	sd	ra,40(sp)
    80000102:	f022                	sd	s0,32(sp)
    80000104:	ec26                	sd	s1,24(sp)
    80000106:	e84a                	sd	s2,16(sp)
    80000108:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000010a:	c219                	beqz	a2,80000110 <printint+0x12>
    8000010c:	08054463          	bltz	a0,80000194 <printint+0x96>
    x = -xx;
  else
    x = xx;
    80000110:	2501                	sext.w	a0,a0
    80000112:	4881                	li	a7,0
    80000114:	fd040693          	addi	a3,s0,-48

  i = 0;
    80000118:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    8000011a:	2581                	sext.w	a1,a1
    8000011c:	00004617          	auipc	a2,0x4
    80000120:	f1c60613          	addi	a2,a2,-228 # 80004038 <digits>
    80000124:	883a                	mv	a6,a4
    80000126:	2705                	addiw	a4,a4,1
    80000128:	02b577bb          	remuw	a5,a0,a1
    8000012c:	1782                	slli	a5,a5,0x20
    8000012e:	9381                	srli	a5,a5,0x20
    80000130:	97b2                	add	a5,a5,a2
    80000132:	0007c783          	lbu	a5,0(a5) # 10000 <_entry-0x7fff0000>
    80000136:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    8000013a:	0005079b          	sext.w	a5,a0
    8000013e:	02b5553b          	divuw	a0,a0,a1
    80000142:	0685                	addi	a3,a3,1
    80000144:	feb7f0e3          	bgeu	a5,a1,80000124 <printint+0x26>

  if(sign)
    80000148:	00088b63          	beqz	a7,8000015e <printint+0x60>
    buf[i++] = '-';
    8000014c:	fe040793          	addi	a5,s0,-32
    80000150:	973e                	add	a4,a4,a5
    80000152:	02d00793          	li	a5,45
    80000156:	fef70823          	sb	a5,-16(a4)
    8000015a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000015e:	02e05563          	blez	a4,80000188 <printint+0x8a>
    80000162:	fd040793          	addi	a5,s0,-48
    80000166:	00e784b3          	add	s1,a5,a4
    8000016a:	fff78913          	addi	s2,a5,-1
    8000016e:	993a                	add	s2,s2,a4
    80000170:	377d                	addiw	a4,a4,-1
    80000172:	1702                	slli	a4,a4,0x20
    80000174:	9301                	srli	a4,a4,0x20
    80000176:	40e90933          	sub	s2,s2,a4
    uartputc_sync(buf[i]);
    8000017a:	fff4c503          	lbu	a0,-1(s1)
    8000017e:	282000ef          	jal	ra,80000400 <uartputc_sync>
  while(--i >= 0)
    80000182:	14fd                	addi	s1,s1,-1
    80000184:	ff249be3          	bne	s1,s2,8000017a <printint+0x7c>
}
    80000188:	70a2                	ld	ra,40(sp)
    8000018a:	7402                	ld	s0,32(sp)
    8000018c:	64e2                	ld	s1,24(sp)
    8000018e:	6942                	ld	s2,16(sp)
    80000190:	6145                	addi	sp,sp,48
    80000192:	8082                	ret
    x = -xx;
    80000194:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000198:	4885                	li	a7,1
    x = -xx;
    8000019a:	bfad                	j	80000114 <printint+0x16>

000000008000019c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000019c:	1101                	addi	sp,sp,-32
    8000019e:	ec06                	sd	ra,24(sp)
    800001a0:	e822                	sd	s0,16(sp)
    800001a2:	e426                	sd	s1,8(sp)
    800001a4:	1000                	addi	s0,sp,32
    800001a6:	84aa                	mv	s1,a0
  pr.locking = 0;
    800001a8:	0000d797          	auipc	a5,0xd
    800001ac:	0607a023          	sw	zero,96(a5) # 8000d208 <pr+0x18>
  printf("panic: ");
    800001b0:	00004517          	auipc	a0,0x4
    800001b4:	e6050513          	addi	a0,a0,-416 # 80004010 <etext+0x10>
    800001b8:	022000ef          	jal	ra,800001da <printf>
  printf(s);
    800001bc:	8526                	mv	a0,s1
    800001be:	01c000ef          	jal	ra,800001da <printf>
  printf("\n");
    800001c2:	00004517          	auipc	a0,0x4
    800001c6:	1f650513          	addi	a0,a0,502 # 800043b8 <digits+0x380>
    800001ca:	010000ef          	jal	ra,800001da <printf>
  panicked = 1; // freeze uart output from other CPUs
    800001ce:	4785                	li	a5,1
    800001d0:	00005717          	auipc	a4,0x5
    800001d4:	eaf72023          	sw	a5,-352(a4) # 80005070 <panicked>
  for(;;)
    800001d8:	a001                	j	800001d8 <panic+0x3c>

00000000800001da <printf>:
{
    800001da:	7131                	addi	sp,sp,-192
    800001dc:	fc86                	sd	ra,120(sp)
    800001de:	f8a2                	sd	s0,112(sp)
    800001e0:	f4a6                	sd	s1,104(sp)
    800001e2:	f0ca                	sd	s2,96(sp)
    800001e4:	ecce                	sd	s3,88(sp)
    800001e6:	e8d2                	sd	s4,80(sp)
    800001e8:	e4d6                	sd	s5,72(sp)
    800001ea:	e0da                	sd	s6,64(sp)
    800001ec:	fc5e                	sd	s7,56(sp)
    800001ee:	f862                	sd	s8,48(sp)
    800001f0:	f466                	sd	s9,40(sp)
    800001f2:	f06a                	sd	s10,32(sp)
    800001f4:	ec6e                	sd	s11,24(sp)
    800001f6:	0100                	addi	s0,sp,128
    800001f8:	8a2a                	mv	s4,a0
    800001fa:	e40c                	sd	a1,8(s0)
    800001fc:	e810                	sd	a2,16(s0)
    800001fe:	ec14                	sd	a3,24(s0)
    80000200:	f018                	sd	a4,32(s0)
    80000202:	f41c                	sd	a5,40(s0)
    80000204:	03043823          	sd	a6,48(s0)
    80000208:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000020c:	0000dd97          	auipc	s11,0xd
    80000210:	ffcdad83          	lw	s11,-4(s11) # 8000d208 <pr+0x18>
  if(locking)
    80000214:	020d9b63          	bnez	s11,8000024a <printf+0x70>
  if (fmt == 0)
    80000218:	040a0063          	beqz	s4,80000258 <printf+0x7e>
  va_start(ap, fmt);
    8000021c:	00840793          	addi	a5,s0,8
    80000220:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000224:	000a4503          	lbu	a0,0(s4)
    80000228:	12050763          	beqz	a0,80000356 <printf+0x17c>
    8000022c:	4981                	li	s3,0
    if(c != '%'){
    8000022e:	02500a93          	li	s5,37
    switch(c){
    80000232:	07000b93          	li	s7,112
  uartputc_sync('x');
    80000236:	4d41                	li	s10,16
    uartputc_sync(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000238:	00004b17          	auipc	s6,0x4
    8000023c:	e00b0b13          	addi	s6,s6,-512 # 80004038 <digits>
    switch(c){
    80000240:	07300c93          	li	s9,115
    80000244:	06400c13          	li	s8,100
    80000248:	a03d                	j	80000276 <printf+0x9c>
    acquire(&pr.lock);
    8000024a:	0000d517          	auipc	a0,0xd
    8000024e:	fa650513          	addi	a0,a0,-90 # 8000d1f0 <pr>
    80000252:	514000ef          	jal	ra,80000766 <acquire>
    80000256:	b7c9                	j	80000218 <printf+0x3e>
    panic("null fmt");
    80000258:	00004517          	auipc	a0,0x4
    8000025c:	dc850513          	addi	a0,a0,-568 # 80004020 <etext+0x20>
    80000260:	f3dff0ef          	jal	ra,8000019c <panic>
      uartputc_sync(c);
    80000264:	19c000ef          	jal	ra,80000400 <uartputc_sync>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000268:	2985                	addiw	s3,s3,1
    8000026a:	013a07b3          	add	a5,s4,s3
    8000026e:	0007c503          	lbu	a0,0(a5)
    80000272:	0e050263          	beqz	a0,80000356 <printf+0x17c>
    if(c != '%'){
    80000276:	ff5517e3          	bne	a0,s5,80000264 <printf+0x8a>
    c = fmt[++i] & 0xff;
    8000027a:	2985                	addiw	s3,s3,1
    8000027c:	013a07b3          	add	a5,s4,s3
    80000280:	0007c783          	lbu	a5,0(a5)
    80000284:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000288:	c7f9                	beqz	a5,80000356 <printf+0x17c>
    switch(c){
    8000028a:	05778663          	beq	a5,s7,800002d6 <printf+0xfc>
    8000028e:	02fbf463          	bgeu	s7,a5,800002b6 <printf+0xdc>
    80000292:	07978e63          	beq	a5,s9,8000030e <printf+0x134>
    80000296:	07800713          	li	a4,120
    8000029a:	0ae79763          	bne	a5,a4,80000348 <printf+0x16e>
      printint(va_arg(ap, int), 16, 1);
    8000029e:	f8843783          	ld	a5,-120(s0)
    800002a2:	00878713          	addi	a4,a5,8
    800002a6:	f8e43423          	sd	a4,-120(s0)
    800002aa:	4605                	li	a2,1
    800002ac:	85ea                	mv	a1,s10
    800002ae:	4388                	lw	a0,0(a5)
    800002b0:	e4fff0ef          	jal	ra,800000fe <printint>
      break;
    800002b4:	bf55                	j	80000268 <printf+0x8e>
    switch(c){
    800002b6:	09578563          	beq	a5,s5,80000340 <printf+0x166>
    800002ba:	09879763          	bne	a5,s8,80000348 <printf+0x16e>
      printint(va_arg(ap, int), 10, 1);
    800002be:	f8843783          	ld	a5,-120(s0)
    800002c2:	00878713          	addi	a4,a5,8
    800002c6:	f8e43423          	sd	a4,-120(s0)
    800002ca:	4605                	li	a2,1
    800002cc:	45a9                	li	a1,10
    800002ce:	4388                	lw	a0,0(a5)
    800002d0:	e2fff0ef          	jal	ra,800000fe <printint>
      break;
    800002d4:	bf51                	j	80000268 <printf+0x8e>
      printptr(va_arg(ap, uint64));
    800002d6:	f8843783          	ld	a5,-120(s0)
    800002da:	00878713          	addi	a4,a5,8
    800002de:	f8e43423          	sd	a4,-120(s0)
    800002e2:	0007b903          	ld	s2,0(a5)
  uartputc_sync('0');
    800002e6:	03000513          	li	a0,48
    800002ea:	116000ef          	jal	ra,80000400 <uartputc_sync>
  uartputc_sync('x');
    800002ee:	07800513          	li	a0,120
    800002f2:	10e000ef          	jal	ra,80000400 <uartputc_sync>
    800002f6:	84ea                	mv	s1,s10
    uartputc_sync(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800002f8:	03c95793          	srli	a5,s2,0x3c
    800002fc:	97da                	add	a5,a5,s6
    800002fe:	0007c503          	lbu	a0,0(a5)
    80000302:	0fe000ef          	jal	ra,80000400 <uartputc_sync>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000306:	0912                	slli	s2,s2,0x4
    80000308:	34fd                	addiw	s1,s1,-1
    8000030a:	f4fd                	bnez	s1,800002f8 <printf+0x11e>
    8000030c:	bfb1                	j	80000268 <printf+0x8e>
      if((s = va_arg(ap, char*)) == 0)
    8000030e:	f8843783          	ld	a5,-120(s0)
    80000312:	00878713          	addi	a4,a5,8
    80000316:	f8e43423          	sd	a4,-120(s0)
    8000031a:	6384                	ld	s1,0(a5)
    8000031c:	c899                	beqz	s1,80000332 <printf+0x158>
      for(; *s; s++)
    8000031e:	0004c503          	lbu	a0,0(s1)
    80000322:	d139                	beqz	a0,80000268 <printf+0x8e>
        uartputc_sync(*s);
    80000324:	0dc000ef          	jal	ra,80000400 <uartputc_sync>
      for(; *s; s++)
    80000328:	0485                	addi	s1,s1,1
    8000032a:	0004c503          	lbu	a0,0(s1)
    8000032e:	f97d                	bnez	a0,80000324 <printf+0x14a>
    80000330:	bf25                	j	80000268 <printf+0x8e>
        s = "(null)";
    80000332:	00004497          	auipc	s1,0x4
    80000336:	ce648493          	addi	s1,s1,-794 # 80004018 <etext+0x18>
      for(; *s; s++)
    8000033a:	02800513          	li	a0,40
    8000033e:	b7dd                	j	80000324 <printf+0x14a>
      uartputc_sync('%');
    80000340:	8556                	mv	a0,s5
    80000342:	0be000ef          	jal	ra,80000400 <uartputc_sync>
      break;
    80000346:	b70d                	j	80000268 <printf+0x8e>
      uartputc_sync('%');
    80000348:	8556                	mv	a0,s5
    8000034a:	0b6000ef          	jal	ra,80000400 <uartputc_sync>
      uartputc_sync(c);
    8000034e:	8526                	mv	a0,s1
    80000350:	0b0000ef          	jal	ra,80000400 <uartputc_sync>
      break;
    80000354:	bf11                	j	80000268 <printf+0x8e>
  if(locking)
    80000356:	020d9163          	bnez	s11,80000378 <printf+0x19e>
}
    8000035a:	70e6                	ld	ra,120(sp)
    8000035c:	7446                	ld	s0,112(sp)
    8000035e:	74a6                	ld	s1,104(sp)
    80000360:	7906                	ld	s2,96(sp)
    80000362:	69e6                	ld	s3,88(sp)
    80000364:	6a46                	ld	s4,80(sp)
    80000366:	6aa6                	ld	s5,72(sp)
    80000368:	6b06                	ld	s6,64(sp)
    8000036a:	7be2                	ld	s7,56(sp)
    8000036c:	7c42                	ld	s8,48(sp)
    8000036e:	7ca2                	ld	s9,40(sp)
    80000370:	7d02                	ld	s10,32(sp)
    80000372:	6de2                	ld	s11,24(sp)
    80000374:	6129                	addi	sp,sp,192
    80000376:	8082                	ret
    release(&pr.lock);
    80000378:	0000d517          	auipc	a0,0xd
    8000037c:	e7850513          	addi	a0,a0,-392 # 8000d1f0 <pr>
    80000380:	47e000ef          	jal	ra,800007fe <release>
}
    80000384:	bfd9                	j	8000035a <printf+0x180>

0000000080000386 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000386:	1101                	addi	sp,sp,-32
    80000388:	ec06                	sd	ra,24(sp)
    8000038a:	e822                	sd	s0,16(sp)
    8000038c:	e426                	sd	s1,8(sp)
    8000038e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000390:	0000d497          	auipc	s1,0xd
    80000394:	e6048493          	addi	s1,s1,-416 # 8000d1f0 <pr>
    80000398:	00004597          	auipc	a1,0x4
    8000039c:	c9858593          	addi	a1,a1,-872 # 80004030 <etext+0x30>
    800003a0:	8526                	mv	a0,s1
    800003a2:	344000ef          	jal	ra,800006e6 <initlock>
  pr.locking = 1;
    800003a6:	4785                	li	a5,1
    800003a8:	cc9c                	sw	a5,24(s1)
}
    800003aa:	60e2                	ld	ra,24(sp)
    800003ac:	6442                	ld	s0,16(sp)
    800003ae:	64a2                	ld	s1,8(sp)
    800003b0:	6105                	addi	sp,sp,32
    800003b2:	8082                	ret

00000000800003b4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800003b4:	1141                	addi	sp,sp,-16
    800003b6:	e406                	sd	ra,8(sp)
    800003b8:	e022                	sd	s0,0(sp)
    800003ba:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800003bc:	100007b7          	lui	a5,0x10000
    800003c0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800003c4:	f8000713          	li	a4,-128
    800003c8:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800003cc:	470d                	li	a4,3
    800003ce:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800003d2:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800003d6:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800003da:	469d                	li	a3,7
    800003dc:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800003e0:	00e780a3          	sb	a4,1(a5)
  
  initlock(&uart_tx_lock, "uart");
    800003e4:	00004597          	auipc	a1,0x4
    800003e8:	c6c58593          	addi	a1,a1,-916 # 80004050 <digits+0x18>
    800003ec:	0000d517          	auipc	a0,0xd
    800003f0:	e2450513          	addi	a0,a0,-476 # 8000d210 <uart_tx_lock>
    800003f4:	2f2000ef          	jal	ra,800006e6 <initlock>
}
    800003f8:	60a2                	ld	ra,8(sp)
    800003fa:	6402                	ld	s0,0(sp)
    800003fc:	0141                	addi	sp,sp,16
    800003fe:	8082                	ret

0000000080000400 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000400:	1101                	addi	sp,sp,-32
    80000402:	ec06                	sd	ra,24(sp)
    80000404:	e822                	sd	s0,16(sp)
    80000406:	e426                	sd	s1,8(sp)
    80000408:	1000                	addi	s0,sp,32
    8000040a:	84aa                	mv	s1,a0
  push_off();
    8000040c:	31a000ef          	jal	ra,80000726 <push_off>

  if(panicked){
    80000410:	00005797          	auipc	a5,0x5
    80000414:	c607a783          	lw	a5,-928(a5) # 80005070 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000418:	10000737          	lui	a4,0x10000
  if(panicked){
    8000041c:	c391                	beqz	a5,80000420 <uartputc_sync+0x20>
    for(;;)
    8000041e:	a001                	j	8000041e <uartputc_sync+0x1e>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000420:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000424:	0207f793          	andi	a5,a5,32
    80000428:	dfe5                	beqz	a5,80000420 <uartputc_sync+0x20>
    ;
  WriteReg(THR, c);
    8000042a:	0ff4f513          	andi	a0,s1,255
    8000042e:	100007b7          	lui	a5,0x10000
    80000432:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000436:	374000ef          	jal	ra,800007aa <pop_off>
}
    8000043a:	60e2                	ld	ra,24(sp)
    8000043c:	6442                	ld	s0,16(sp)
    8000043e:	64a2                	ld	s1,8(sp)
    80000440:	6105                	addi	sp,sp,32
    80000442:	8082                	ret

0000000080000444 <uartstart>:
// in the transmit buffer, send it.
// caller must hold uart_tx_lock.
// called from both the top- and bottom-half.
void
uartstart()
{
    80000444:	1141                	addi	sp,sp,-16
    80000446:	e422                	sd	s0,8(sp)
    80000448:	0800                	addi	s0,sp,16
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000044a:	00005797          	auipc	a5,0x5
    8000044e:	c2e7b783          	ld	a5,-978(a5) # 80005078 <uart_tx_r>
    80000452:	00005717          	auipc	a4,0x5
    80000456:	c2e73703          	ld	a4,-978(a4) # 80005080 <uart_tx_w>
    8000045a:	04f70263          	beq	a4,a5,8000049e <uartstart+0x5a>
      // transmit buffer is empty.
      ReadReg(ISR);
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000045e:	100006b7          	lui	a3,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000462:	0000d517          	auipc	a0,0xd
    80000466:	dae50513          	addi	a0,a0,-594 # 8000d210 <uart_tx_lock>
    uart_tx_r += 1;
    8000046a:	00005617          	auipc	a2,0x5
    8000046e:	c0e60613          	addi	a2,a2,-1010 # 80005078 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000472:	00005597          	auipc	a1,0x5
    80000476:	c0e58593          	addi	a1,a1,-1010 # 80005080 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000047a:	0056c703          	lbu	a4,5(a3) # 10000005 <_entry-0x6ffffffb>
    8000047e:	02077713          	andi	a4,a4,32
    80000482:	c315                	beqz	a4,800004a6 <uartstart+0x62>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000484:	01f7f713          	andi	a4,a5,31
    80000488:	972a                	add	a4,a4,a0
    8000048a:	01874703          	lbu	a4,24(a4)
    uart_tx_r += 1;
    8000048e:	0785                	addi	a5,a5,1
    80000490:	e21c                	sd	a5,0(a2)
    
    // maybe uartputc() is waiting for space in the buffer.
    // wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    80000492:	00e68023          	sb	a4,0(a3)
    if(uart_tx_w == uart_tx_r){
    80000496:	621c                	ld	a5,0(a2)
    80000498:	6198                	ld	a4,0(a1)
    8000049a:	fef710e3          	bne	a4,a5,8000047a <uartstart+0x36>
      ReadReg(ISR);
    8000049e:	100007b7          	lui	a5,0x10000
    800004a2:	0027c783          	lbu	a5,2(a5) # 10000002 <_entry-0x6ffffffe>
  }
}
    800004a6:	6422                	ld	s0,8(sp)
    800004a8:	0141                	addi	sp,sp,16
    800004aa:	8082                	ret

00000000800004ac <uartputc>:
{
    800004ac:	7179                	addi	sp,sp,-48
    800004ae:	f406                	sd	ra,40(sp)
    800004b0:	f022                	sd	s0,32(sp)
    800004b2:	ec26                	sd	s1,24(sp)
    800004b4:	e84a                	sd	s2,16(sp)
    800004b6:	e44e                	sd	s3,8(sp)
    800004b8:	e052                	sd	s4,0(sp)
    800004ba:	1800                	addi	s0,sp,48
    800004bc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800004be:	0000d517          	auipc	a0,0xd
    800004c2:	d5250513          	addi	a0,a0,-686 # 8000d210 <uart_tx_lock>
    800004c6:	2a0000ef          	jal	ra,80000766 <acquire>
  if(panicked){
    800004ca:	00005797          	auipc	a5,0x5
    800004ce:	ba67a783          	lw	a5,-1114(a5) # 80005070 <panicked>
    800004d2:	efbd                	bnez	a5,80000550 <uartputc+0xa4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800004d4:	00005717          	auipc	a4,0x5
    800004d8:	bac73703          	ld	a4,-1108(a4) # 80005080 <uart_tx_w>
    800004dc:	00005797          	auipc	a5,0x5
    800004e0:	b9c7b783          	ld	a5,-1124(a5) # 80005078 <uart_tx_r>
    800004e4:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800004e8:	0000d997          	auipc	s3,0xd
    800004ec:	d2898993          	addi	s3,s3,-728 # 8000d210 <uart_tx_lock>
    800004f0:	00005497          	auipc	s1,0x5
    800004f4:	b8848493          	addi	s1,s1,-1144 # 80005078 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800004f8:	00005917          	auipc	s2,0x5
    800004fc:	b8890913          	addi	s2,s2,-1144 # 80005080 <uart_tx_w>
    80000500:	00e79d63          	bne	a5,a4,8000051a <uartputc+0x6e>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000504:	85ce                	mv	a1,s3
    80000506:	8526                	mv	a0,s1
    80000508:	488010ef          	jal	ra,80001990 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000050c:	00093703          	ld	a4,0(s2)
    80000510:	609c                	ld	a5,0(s1)
    80000512:	02078793          	addi	a5,a5,32
    80000516:	fee787e3          	beq	a5,a4,80000504 <uartputc+0x58>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000051a:	0000d497          	auipc	s1,0xd
    8000051e:	cf648493          	addi	s1,s1,-778 # 8000d210 <uart_tx_lock>
    80000522:	01f77793          	andi	a5,a4,31
    80000526:	97a6                	add	a5,a5,s1
    80000528:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    8000052c:	0705                	addi	a4,a4,1
    8000052e:	00005797          	auipc	a5,0x5
    80000532:	b4e7b923          	sd	a4,-1198(a5) # 80005080 <uart_tx_w>
  uartstart();
    80000536:	f0fff0ef          	jal	ra,80000444 <uartstart>
  release(&uart_tx_lock);
    8000053a:	8526                	mv	a0,s1
    8000053c:	2c2000ef          	jal	ra,800007fe <release>
}
    80000540:	70a2                	ld	ra,40(sp)
    80000542:	7402                	ld	s0,32(sp)
    80000544:	64e2                	ld	s1,24(sp)
    80000546:	6942                	ld	s2,16(sp)
    80000548:	69a2                	ld	s3,8(sp)
    8000054a:	6a02                	ld	s4,0(sp)
    8000054c:	6145                	addi	sp,sp,48
    8000054e:	8082                	ret
    for(;;)
    80000550:	a001                	j	80000550 <uartputc+0xa4>

0000000080000552 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000552:	1141                	addi	sp,sp,-16
    80000554:	e422                	sd	s0,8(sp)
    80000556:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000558:	100007b7          	lui	a5,0x10000
    8000055c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000560:	8b85                	andi	a5,a5,1
    80000562:	cb91                	beqz	a5,80000576 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000564:	100007b7          	lui	a5,0x10000
    80000568:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000056c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000570:	6422                	ld	s0,8(sp)
    80000572:	0141                	addi	sp,sp,16
    80000574:	8082                	ret
    return -1;
    80000576:	557d                	li	a0,-1
    80000578:	bfe5                	j	80000570 <uartgetc+0x1e>

000000008000057a <uartintr>:
// arrived, or the uart is ready for more output, or
// both. called from devintr().

void
uartintr(void)
{
    8000057a:	1101                	addi	sp,sp,-32
    8000057c:	ec06                	sd	ra,24(sp)
    8000057e:	e822                	sd	s0,16(sp)
    80000580:	e426                	sd	s1,8(sp)
    80000582:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000584:	54fd                	li	s1,-1
    80000586:	a019                	j	8000058c <uartintr+0x12>
      break;
    uartputc_sync(c);
    80000588:	e79ff0ef          	jal	ra,80000400 <uartputc_sync>
    int c = uartgetc();
    8000058c:	fc7ff0ef          	jal	ra,80000552 <uartgetc>
    if(c == -1)
    80000590:	fe951ce3          	bne	a0,s1,80000588 <uartintr+0xe>
    
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000594:	0000d497          	auipc	s1,0xd
    80000598:	c7c48493          	addi	s1,s1,-900 # 8000d210 <uart_tx_lock>
    8000059c:	8526                	mv	a0,s1
    8000059e:	1c8000ef          	jal	ra,80000766 <acquire>
  uartstart();
    800005a2:	ea3ff0ef          	jal	ra,80000444 <uartstart>
  release(&uart_tx_lock);
    800005a6:	8526                	mv	a0,s1
    800005a8:	256000ef          	jal	ra,800007fe <release>
}
    800005ac:	60e2                	ld	ra,24(sp)
    800005ae:	6442                	ld	s0,16(sp)
    800005b0:	64a2                	ld	s1,8(sp)
    800005b2:	6105                	addi	sp,sp,32
    800005b4:	8082                	ret

00000000800005b6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800005b6:	1101                	addi	sp,sp,-32
    800005b8:	ec06                	sd	ra,24(sp)
    800005ba:	e822                	sd	s0,16(sp)
    800005bc:	e426                	sd	s1,8(sp)
    800005be:	e04a                	sd	s2,0(sp)
    800005c0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800005c2:	03451793          	slli	a5,a0,0x34
    800005c6:	e7a9                	bnez	a5,80000610 <kfree+0x5a>
    800005c8:	84aa                	mv	s1,a0
    800005ca:	00011797          	auipc	a5,0x11
    800005ce:	ae678793          	addi	a5,a5,-1306 # 800110b0 <end>
    800005d2:	02f56f63          	bltu	a0,a5,80000610 <kfree+0x5a>
    800005d6:	47c5                	li	a5,17
    800005d8:	07ee                	slli	a5,a5,0x1b
    800005da:	02f57b63          	bgeu	a0,a5,80000610 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800005de:	6605                	lui	a2,0x1
    800005e0:	4585                	li	a1,1
    800005e2:	258000ef          	jal	ra,8000083a <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    800005e6:	0000d917          	auipc	s2,0xd
    800005ea:	c6290913          	addi	s2,s2,-926 # 8000d248 <kmem>
    800005ee:	854a                	mv	a0,s2
    800005f0:	176000ef          	jal	ra,80000766 <acquire>
  r->next = kmem.freelist;
    800005f4:	01893783          	ld	a5,24(s2)
    800005f8:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    800005fa:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    800005fe:	854a                	mv	a0,s2
    80000600:	1fe000ef          	jal	ra,800007fe <release>
}
    80000604:	60e2                	ld	ra,24(sp)
    80000606:	6442                	ld	s0,16(sp)
    80000608:	64a2                	ld	s1,8(sp)
    8000060a:	6902                	ld	s2,0(sp)
    8000060c:	6105                	addi	sp,sp,32
    8000060e:	8082                	ret
    panic("kfree");
    80000610:	00004517          	auipc	a0,0x4
    80000614:	a4850513          	addi	a0,a0,-1464 # 80004058 <digits+0x20>
    80000618:	b85ff0ef          	jal	ra,8000019c <panic>

000000008000061c <freerange>:
{
    8000061c:	7179                	addi	sp,sp,-48
    8000061e:	f406                	sd	ra,40(sp)
    80000620:	f022                	sd	s0,32(sp)
    80000622:	ec26                	sd	s1,24(sp)
    80000624:	e84a                	sd	s2,16(sp)
    80000626:	e44e                	sd	s3,8(sp)
    80000628:	e052                	sd	s4,0(sp)
    8000062a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    8000062c:	6785                	lui	a5,0x1
    8000062e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000632:	94aa                	add	s1,s1,a0
    80000634:	757d                	lui	a0,0xfffff
    80000636:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000638:	94be                	add	s1,s1,a5
    8000063a:	0095ec63          	bltu	a1,s1,80000652 <freerange+0x36>
    8000063e:	892e                	mv	s2,a1
    kfree(p);
    80000640:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000642:	6985                	lui	s3,0x1
    kfree(p);
    80000644:	01448533          	add	a0,s1,s4
    80000648:	f6fff0ef          	jal	ra,800005b6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    8000064c:	94ce                	add	s1,s1,s3
    8000064e:	fe997be3          	bgeu	s2,s1,80000644 <freerange+0x28>
}
    80000652:	70a2                	ld	ra,40(sp)
    80000654:	7402                	ld	s0,32(sp)
    80000656:	64e2                	ld	s1,24(sp)
    80000658:	6942                	ld	s2,16(sp)
    8000065a:	69a2                	ld	s3,8(sp)
    8000065c:	6a02                	ld	s4,0(sp)
    8000065e:	6145                	addi	sp,sp,48
    80000660:	8082                	ret

0000000080000662 <kinit>:
{
    80000662:	1141                	addi	sp,sp,-16
    80000664:	e406                	sd	ra,8(sp)
    80000666:	e022                	sd	s0,0(sp)
    80000668:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    8000066a:	00004597          	auipc	a1,0x4
    8000066e:	9f658593          	addi	a1,a1,-1546 # 80004060 <digits+0x28>
    80000672:	0000d517          	auipc	a0,0xd
    80000676:	bd650513          	addi	a0,a0,-1066 # 8000d248 <kmem>
    8000067a:	06c000ef          	jal	ra,800006e6 <initlock>
  freerange(end, (void*)PHYSTOP);
    8000067e:	45c5                	li	a1,17
    80000680:	05ee                	slli	a1,a1,0x1b
    80000682:	00011517          	auipc	a0,0x11
    80000686:	a2e50513          	addi	a0,a0,-1490 # 800110b0 <end>
    8000068a:	f93ff0ef          	jal	ra,8000061c <freerange>
}
    8000068e:	60a2                	ld	ra,8(sp)
    80000690:	6402                	ld	s0,0(sp)
    80000692:	0141                	addi	sp,sp,16
    80000694:	8082                	ret

0000000080000696 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000696:	1101                	addi	sp,sp,-32
    80000698:	ec06                	sd	ra,24(sp)
    8000069a:	e822                	sd	s0,16(sp)
    8000069c:	e426                	sd	s1,8(sp)
    8000069e:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    800006a0:	0000d497          	auipc	s1,0xd
    800006a4:	ba848493          	addi	s1,s1,-1112 # 8000d248 <kmem>
    800006a8:	8526                	mv	a0,s1
    800006aa:	0bc000ef          	jal	ra,80000766 <acquire>
  r = kmem.freelist;
    800006ae:	6c84                	ld	s1,24(s1)
  if(r)
    800006b0:	c485                	beqz	s1,800006d8 <kalloc+0x42>
    kmem.freelist = r->next;
    800006b2:	609c                	ld	a5,0(s1)
    800006b4:	0000d517          	auipc	a0,0xd
    800006b8:	b9450513          	addi	a0,a0,-1132 # 8000d248 <kmem>
    800006bc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    800006be:	140000ef          	jal	ra,800007fe <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    800006c2:	6605                	lui	a2,0x1
    800006c4:	4595                	li	a1,5
    800006c6:	8526                	mv	a0,s1
    800006c8:	172000ef          	jal	ra,8000083a <memset>
  return (void*)r;
}
    800006cc:	8526                	mv	a0,s1
    800006ce:	60e2                	ld	ra,24(sp)
    800006d0:	6442                	ld	s0,16(sp)
    800006d2:	64a2                	ld	s1,8(sp)
    800006d4:	6105                	addi	sp,sp,32
    800006d6:	8082                	ret
  release(&kmem.lock);
    800006d8:	0000d517          	auipc	a0,0xd
    800006dc:	b7050513          	addi	a0,a0,-1168 # 8000d248 <kmem>
    800006e0:	11e000ef          	jal	ra,800007fe <release>
  if(r)
    800006e4:	b7e5                	j	800006cc <kalloc+0x36>

00000000800006e6 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    800006e6:	1141                	addi	sp,sp,-16
    800006e8:	e422                	sd	s0,8(sp)
    800006ea:	0800                	addi	s0,sp,16
  lk->name = name;
    800006ec:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800006ee:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800006f2:	00053823          	sd	zero,16(a0)
}
    800006f6:	6422                	ld	s0,8(sp)
    800006f8:	0141                	addi	sp,sp,16
    800006fa:	8082                	ret

00000000800006fc <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    800006fc:	411c                	lw	a5,0(a0)
    800006fe:	e399                	bnez	a5,80000704 <holding+0x8>
    80000700:	4501                	li	a0,0
  return r;
}
    80000702:	8082                	ret
{
    80000704:	1101                	addi	sp,sp,-32
    80000706:	ec06                	sd	ra,24(sp)
    80000708:	e822                	sd	s0,16(sp)
    8000070a:	e426                	sd	s1,8(sp)
    8000070c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    8000070e:	6904                	ld	s1,16(a0)
    80000710:	465000ef          	jal	ra,80001374 <mycpu>
    80000714:	40a48533          	sub	a0,s1,a0
    80000718:	00153513          	seqz	a0,a0
}
    8000071c:	60e2                	ld	ra,24(sp)
    8000071e:	6442                	ld	s0,16(sp)
    80000720:	64a2                	ld	s1,8(sp)
    80000722:	6105                	addi	sp,sp,32
    80000724:	8082                	ret

0000000080000726 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000726:	1101                	addi	sp,sp,-32
    80000728:	ec06                	sd	ra,24(sp)
    8000072a:	e822                	sd	s0,16(sp)
    8000072c:	e426                	sd	s1,8(sp)
    8000072e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000730:	100024f3          	csrr	s1,sstatus
    80000734:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000738:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000073a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    8000073e:	437000ef          	jal	ra,80001374 <mycpu>
    80000742:	5d3c                	lw	a5,120(a0)
    80000744:	cb99                	beqz	a5,8000075a <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000746:	42f000ef          	jal	ra,80001374 <mycpu>
    8000074a:	5d3c                	lw	a5,120(a0)
    8000074c:	2785                	addiw	a5,a5,1
    8000074e:	dd3c                	sw	a5,120(a0)
}
    80000750:	60e2                	ld	ra,24(sp)
    80000752:	6442                	ld	s0,16(sp)
    80000754:	64a2                	ld	s1,8(sp)
    80000756:	6105                	addi	sp,sp,32
    80000758:	8082                	ret
    mycpu()->intena = old;
    8000075a:	41b000ef          	jal	ra,80001374 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    8000075e:	8085                	srli	s1,s1,0x1
    80000760:	8885                	andi	s1,s1,1
    80000762:	dd64                	sw	s1,124(a0)
    80000764:	b7cd                	j	80000746 <push_off+0x20>

0000000080000766 <acquire>:
{
    80000766:	1101                	addi	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	addi	s0,sp,32
    80000770:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000772:	fb5ff0ef          	jal	ra,80000726 <push_off>
  if(holding(lk))
    80000776:	8526                	mv	a0,s1
    80000778:	f85ff0ef          	jal	ra,800006fc <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    8000077c:	4705                	li	a4,1
  if(holding(lk))
    8000077e:	e105                	bnez	a0,8000079e <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000780:	87ba                	mv	a5,a4
    80000782:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000786:	2781                	sext.w	a5,a5
    80000788:	ffe5                	bnez	a5,80000780 <acquire+0x1a>
  __sync_synchronize();
    8000078a:	0ff0000f          	fence
  lk->cpu = mycpu();
    8000078e:	3e7000ef          	jal	ra,80001374 <mycpu>
    80000792:	e888                	sd	a0,16(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret
    panic("acquire");
    8000079e:	00004517          	auipc	a0,0x4
    800007a2:	8ca50513          	addi	a0,a0,-1846 # 80004068 <digits+0x30>
    800007a6:	9f7ff0ef          	jal	ra,8000019c <panic>

00000000800007aa <pop_off>:

void
pop_off(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    800007b2:	3c3000ef          	jal	ra,80001374 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800007b6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800007ba:	8b89                	andi	a5,a5,2
  if(intr_get())
    800007bc:	e78d                	bnez	a5,800007e6 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    800007be:	5d3c                	lw	a5,120(a0)
    800007c0:	02f05963          	blez	a5,800007f2 <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    800007c4:	37fd                	addiw	a5,a5,-1
    800007c6:	0007871b          	sext.w	a4,a5
    800007ca:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    800007cc:	eb09                	bnez	a4,800007de <pop_off+0x34>
    800007ce:	5d7c                	lw	a5,124(a0)
    800007d0:	c799                	beqz	a5,800007de <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800007d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800007d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800007da:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret
    panic("pop_off - interruptible");
    800007e6:	00004517          	auipc	a0,0x4
    800007ea:	88a50513          	addi	a0,a0,-1910 # 80004070 <digits+0x38>
    800007ee:	9afff0ef          	jal	ra,8000019c <panic>
    panic("pop_off");
    800007f2:	00004517          	auipc	a0,0x4
    800007f6:	89650513          	addi	a0,a0,-1898 # 80004088 <digits+0x50>
    800007fa:	9a3ff0ef          	jal	ra,8000019c <panic>

00000000800007fe <release>:
{
    800007fe:	1101                	addi	sp,sp,-32
    80000800:	ec06                	sd	ra,24(sp)
    80000802:	e822                	sd	s0,16(sp)
    80000804:	e426                	sd	s1,8(sp)
    80000806:	1000                	addi	s0,sp,32
    80000808:	84aa                	mv	s1,a0
  if(!holding(lk))
    8000080a:	ef3ff0ef          	jal	ra,800006fc <holding>
    8000080e:	c105                	beqz	a0,8000082e <release+0x30>
  lk->cpu = 0;
    80000810:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000814:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000818:	0f50000f          	fence	iorw,ow
    8000081c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000820:	f8bff0ef          	jal	ra,800007aa <pop_off>
}
    80000824:	60e2                	ld	ra,24(sp)
    80000826:	6442                	ld	s0,16(sp)
    80000828:	64a2                	ld	s1,8(sp)
    8000082a:	6105                	addi	sp,sp,32
    8000082c:	8082                	ret
    panic("release");
    8000082e:	00004517          	auipc	a0,0x4
    80000832:	86250513          	addi	a0,a0,-1950 # 80004090 <digits+0x58>
    80000836:	967ff0ef          	jal	ra,8000019c <panic>

000000008000083a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000083a:	1141                	addi	sp,sp,-16
    8000083c:	e422                	sd	s0,8(sp)
    8000083e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000840:	ca19                	beqz	a2,80000856 <memset+0x1c>
    80000842:	87aa                	mv	a5,a0
    80000844:	1602                	slli	a2,a2,0x20
    80000846:	9201                	srli	a2,a2,0x20
    80000848:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    8000084c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000850:	0785                	addi	a5,a5,1
    80000852:	fee79de3          	bne	a5,a4,8000084c <memset+0x12>
  }
  return dst;
}
    80000856:	6422                	ld	s0,8(sp)
    80000858:	0141                	addi	sp,sp,16
    8000085a:	8082                	ret

000000008000085c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    8000085c:	1141                	addi	sp,sp,-16
    8000085e:	e422                	sd	s0,8(sp)
    80000860:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000862:	ca05                	beqz	a2,80000892 <memcmp+0x36>
    80000864:	fff6069b          	addiw	a3,a2,-1
    80000868:	1682                	slli	a3,a3,0x20
    8000086a:	9281                	srli	a3,a3,0x20
    8000086c:	0685                	addi	a3,a3,1
    8000086e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000870:	00054783          	lbu	a5,0(a0)
    80000874:	0005c703          	lbu	a4,0(a1)
    80000878:	00e79863          	bne	a5,a4,80000888 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000087c:	0505                	addi	a0,a0,1
    8000087e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000880:	fed518e3          	bne	a0,a3,80000870 <memcmp+0x14>
  }

  return 0;
    80000884:	4501                	li	a0,0
    80000886:	a019                	j	8000088c <memcmp+0x30>
      return *s1 - *s2;
    80000888:	40e7853b          	subw	a0,a5,a4
}
    8000088c:	6422                	ld	s0,8(sp)
    8000088e:	0141                	addi	sp,sp,16
    80000890:	8082                	ret
  return 0;
    80000892:	4501                	li	a0,0
    80000894:	bfe5                	j	8000088c <memcmp+0x30>

0000000080000896 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000896:	1141                	addi	sp,sp,-16
    80000898:	e422                	sd	s0,8(sp)
    8000089a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000089c:	c205                	beqz	a2,800008bc <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000089e:	02a5e263          	bltu	a1,a0,800008c2 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800008a2:	1602                	slli	a2,a2,0x20
    800008a4:	9201                	srli	a2,a2,0x20
    800008a6:	00c587b3          	add	a5,a1,a2
{
    800008aa:	872a                	mv	a4,a0
      *d++ = *s++;
    800008ac:	0585                	addi	a1,a1,1
    800008ae:	0705                	addi	a4,a4,1
    800008b0:	fff5c683          	lbu	a3,-1(a1)
    800008b4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800008b8:	fef59ae3          	bne	a1,a5,800008ac <memmove+0x16>

  return dst;
}
    800008bc:	6422                	ld	s0,8(sp)
    800008be:	0141                	addi	sp,sp,16
    800008c0:	8082                	ret
  if(s < d && s + n > d){
    800008c2:	02061693          	slli	a3,a2,0x20
    800008c6:	9281                	srli	a3,a3,0x20
    800008c8:	00d58733          	add	a4,a1,a3
    800008cc:	fce57be3          	bgeu	a0,a4,800008a2 <memmove+0xc>
    d += n;
    800008d0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800008d2:	fff6079b          	addiw	a5,a2,-1
    800008d6:	1782                	slli	a5,a5,0x20
    800008d8:	9381                	srli	a5,a5,0x20
    800008da:	fff7c793          	not	a5,a5
    800008de:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800008e0:	177d                	addi	a4,a4,-1
    800008e2:	16fd                	addi	a3,a3,-1
    800008e4:	00074603          	lbu	a2,0(a4)
    800008e8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800008ec:	fee79ae3          	bne	a5,a4,800008e0 <memmove+0x4a>
    800008f0:	b7f1                	j	800008bc <memmove+0x26>

00000000800008f2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800008f2:	1141                	addi	sp,sp,-16
    800008f4:	e406                	sd	ra,8(sp)
    800008f6:	e022                	sd	s0,0(sp)
    800008f8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800008fa:	f9dff0ef          	jal	ra,80000896 <memmove>
}
    800008fe:	60a2                	ld	ra,8(sp)
    80000900:	6402                	ld	s0,0(sp)
    80000902:	0141                	addi	sp,sp,16
    80000904:	8082                	ret

0000000080000906 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000906:	1141                	addi	sp,sp,-16
    80000908:	e422                	sd	s0,8(sp)
    8000090a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000090c:	ce11                	beqz	a2,80000928 <strncmp+0x22>
    8000090e:	00054783          	lbu	a5,0(a0)
    80000912:	cf89                	beqz	a5,8000092c <strncmp+0x26>
    80000914:	0005c703          	lbu	a4,0(a1)
    80000918:	00f71a63          	bne	a4,a5,8000092c <strncmp+0x26>
    n--, p++, q++;
    8000091c:	367d                	addiw	a2,a2,-1
    8000091e:	0505                	addi	a0,a0,1
    80000920:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000922:	f675                	bnez	a2,8000090e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000924:	4501                	li	a0,0
    80000926:	a809                	j	80000938 <strncmp+0x32>
    80000928:	4501                	li	a0,0
    8000092a:	a039                	j	80000938 <strncmp+0x32>
  if(n == 0)
    8000092c:	ca09                	beqz	a2,8000093e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000092e:	00054503          	lbu	a0,0(a0)
    80000932:	0005c783          	lbu	a5,0(a1)
    80000936:	9d1d                	subw	a0,a0,a5
}
    80000938:	6422                	ld	s0,8(sp)
    8000093a:	0141                	addi	sp,sp,16
    8000093c:	8082                	ret
    return 0;
    8000093e:	4501                	li	a0,0
    80000940:	bfe5                	j	80000938 <strncmp+0x32>

0000000080000942 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000942:	1141                	addi	sp,sp,-16
    80000944:	e422                	sd	s0,8(sp)
    80000946:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000948:	872a                	mv	a4,a0
    8000094a:	8832                	mv	a6,a2
    8000094c:	367d                	addiw	a2,a2,-1
    8000094e:	01005963          	blez	a6,80000960 <strncpy+0x1e>
    80000952:	0705                	addi	a4,a4,1
    80000954:	0005c783          	lbu	a5,0(a1)
    80000958:	fef70fa3          	sb	a5,-1(a4)
    8000095c:	0585                	addi	a1,a1,1
    8000095e:	f7f5                	bnez	a5,8000094a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000960:	86ba                	mv	a3,a4
    80000962:	00c05c63          	blez	a2,8000097a <strncpy+0x38>
    *s++ = 0;
    80000966:	0685                	addi	a3,a3,1
    80000968:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    8000096c:	fff6c793          	not	a5,a3
    80000970:	9fb9                	addw	a5,a5,a4
    80000972:	010787bb          	addw	a5,a5,a6
    80000976:	fef048e3          	bgtz	a5,80000966 <strncpy+0x24>
  return os;
}
    8000097a:	6422                	ld	s0,8(sp)
    8000097c:	0141                	addi	sp,sp,16
    8000097e:	8082                	ret

0000000080000980 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000986:	02c05363          	blez	a2,800009ac <safestrcpy+0x2c>
    8000098a:	fff6069b          	addiw	a3,a2,-1
    8000098e:	1682                	slli	a3,a3,0x20
    80000990:	9281                	srli	a3,a3,0x20
    80000992:	96ae                	add	a3,a3,a1
    80000994:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000996:	00d58963          	beq	a1,a3,800009a8 <safestrcpy+0x28>
    8000099a:	0585                	addi	a1,a1,1
    8000099c:	0785                	addi	a5,a5,1
    8000099e:	fff5c703          	lbu	a4,-1(a1)
    800009a2:	fee78fa3          	sb	a4,-1(a5)
    800009a6:	fb65                	bnez	a4,80000996 <safestrcpy+0x16>
    ;
  *s = 0;
    800009a8:	00078023          	sb	zero,0(a5)
  return os;
}
    800009ac:	6422                	ld	s0,8(sp)
    800009ae:	0141                	addi	sp,sp,16
    800009b0:	8082                	ret

00000000800009b2 <strlen>:

int
strlen(const char *s)
{
    800009b2:	1141                	addi	sp,sp,-16
    800009b4:	e422                	sd	s0,8(sp)
    800009b6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800009b8:	00054783          	lbu	a5,0(a0)
    800009bc:	cf91                	beqz	a5,800009d8 <strlen+0x26>
    800009be:	0505                	addi	a0,a0,1
    800009c0:	87aa                	mv	a5,a0
    800009c2:	4685                	li	a3,1
    800009c4:	9e89                	subw	a3,a3,a0
    800009c6:	00f6853b          	addw	a0,a3,a5
    800009ca:	0785                	addi	a5,a5,1
    800009cc:	fff7c703          	lbu	a4,-1(a5)
    800009d0:	fb7d                	bnez	a4,800009c6 <strlen+0x14>
    ;
  return n;
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
  for(n = 0; s[n]; n++)
    800009d8:	4501                	li	a0,0
    800009da:	bfe5                	j	800009d2 <strlen+0x20>

00000000800009dc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800009dc:	1141                	addi	sp,sp,-16
    800009de:	e406                	sd	ra,8(sp)
    800009e0:	e022                	sd	s0,0(sp)
    800009e2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    800009e4:	181000ef          	jal	ra,80001364 <cpuid>
    plicinithart();  // ask PLIC for device interrupts
    __sync_synchronize();
    started = 1;
    userinit();      // first user process
  } else {
    while(started == 0)
    800009e8:	00004717          	auipc	a4,0x4
    800009ec:	6a070713          	addi	a4,a4,1696 # 80005088 <started>
  if(cpuid() == 0){
    800009f0:	cd05                	beqz	a0,80000a28 <main+0x4c>
    while(started == 0)
    800009f2:	431c                	lw	a5,0(a4)
    800009f4:	2781                	sext.w	a5,a5
    800009f6:	dff5                	beqz	a5,800009f2 <main+0x16>
      ;
    __sync_synchronize();
    800009f8:	0ff0000f          	fence
    printf("cpu %d is booting!\n", cpuid());
    800009fc:	169000ef          	jal	ra,80001364 <cpuid>
    80000a00:	85aa                	mv	a1,a0
    80000a02:	00003517          	auipc	a0,0x3
    80000a06:	69650513          	addi	a0,a0,1686 # 80004098 <digits+0x60>
    80000a0a:	fd0ff0ef          	jal	ra,800001da <printf>
    kvminithart();    // turn on paging
    80000a0e:	068000ef          	jal	ra,80000a76 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000a12:	38c010ef          	jal	ra,80001d9e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000a16:	317010ef          	jal	ra,8000252c <plicinithart>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000a1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000a20:	10079073          	csrw	sstatus,a5
  }

  intr_off(); // Ensure interrupts are disabled before scheduler
  scheduler();      
    80000a24:	5f3000ef          	jal	ra,80001816 <scheduler>
    printfinit();
    80000a28:	95fff0ef          	jal	ra,80000386 <printfinit>
    printf("cpu %d is booting!\n", cpuid()); 
    80000a2c:	139000ef          	jal	ra,80001364 <cpuid>
    80000a30:	85aa                	mv	a1,a0
    80000a32:	00003517          	auipc	a0,0x3
    80000a36:	66650513          	addi	a0,a0,1638 # 80004098 <digits+0x60>
    80000a3a:	fa0ff0ef          	jal	ra,800001da <printf>
    kinit();         // physical page allocator
    80000a3e:	c25ff0ef          	jal	ra,80000662 <kinit>
    uartinit();
    80000a42:	973ff0ef          	jal	ra,800003b4 <uartinit>
    kvminit();       // create kernel page table
    80000a46:	29e000ef          	jal	ra,80000ce4 <kvminit>
    kvminithart();   // turn on paging
    80000a4a:	02c000ef          	jal	ra,80000a76 <kvminithart>
    procinit();      // process table
    80000a4e:	06f000ef          	jal	ra,800012bc <procinit>
    trapinit();      // trap vectors
    80000a52:	328010ef          	jal	ra,80001d7a <trapinit>
    trapinithart();  // install kernel trap vector
    80000a56:	348010ef          	jal	ra,80001d9e <trapinithart>
    plicinit();      // set up interrupt controller
    80000a5a:	2bd010ef          	jal	ra,80002516 <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000a5e:	2cf010ef          	jal	ra,8000252c <plicinithart>
    __sync_synchronize();
    80000a62:	0ff0000f          	fence
    started = 1;
    80000a66:	4785                	li	a5,1
    80000a68:	00004717          	auipc	a4,0x4
    80000a6c:	62f72023          	sw	a5,1568(a4) # 80005088 <started>
    userinit();      // first user process
    80000a70:	383000ef          	jal	ra,800015f2 <userinit>
    80000a74:	b75d                	j	80000a1a <main+0x3e>

0000000080000a76 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000a76:	1141                	addi	sp,sp,-16
    80000a78:	e422                	sd	s0,8(sp)
    80000a7a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000a7c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000a80:	00004797          	auipc	a5,0x4
    80000a84:	6107b783          	ld	a5,1552(a5) # 80005090 <kernel_pagetable>
    80000a88:	83b1                	srli	a5,a5,0xc
    80000a8a:	577d                	li	a4,-1
    80000a8c:	177e                	slli	a4,a4,0x3f
    80000a8e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000a90:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000a94:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000a98:	6422                	ld	s0,8(sp)
    80000a9a:	0141                	addi	sp,sp,16
    80000a9c:	8082                	ret

0000000080000a9e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000a9e:	7139                	addi	sp,sp,-64
    80000aa0:	fc06                	sd	ra,56(sp)
    80000aa2:	f822                	sd	s0,48(sp)
    80000aa4:	f426                	sd	s1,40(sp)
    80000aa6:	f04a                	sd	s2,32(sp)
    80000aa8:	ec4e                	sd	s3,24(sp)
    80000aaa:	e852                	sd	s4,16(sp)
    80000aac:	e456                	sd	s5,8(sp)
    80000aae:	e05a                	sd	s6,0(sp)
    80000ab0:	0080                	addi	s0,sp,64
    80000ab2:	84aa                	mv	s1,a0
    80000ab4:	89ae                	mv	s3,a1
    80000ab6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ab8:	57fd                	li	a5,-1
    80000aba:	83e9                	srli	a5,a5,0x1a
    80000abc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000abe:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ac0:	02b7fc63          	bgeu	a5,a1,80000af8 <walk+0x5a>
    panic("walk");
    80000ac4:	00003517          	auipc	a0,0x3
    80000ac8:	5ec50513          	addi	a0,a0,1516 # 800040b0 <digits+0x78>
    80000acc:	ed0ff0ef          	jal	ra,8000019c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ad0:	060a8263          	beqz	s5,80000b34 <walk+0x96>
    80000ad4:	bc3ff0ef          	jal	ra,80000696 <kalloc>
    80000ad8:	84aa                	mv	s1,a0
    80000ada:	c139                	beqz	a0,80000b20 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000adc:	6605                	lui	a2,0x1
    80000ade:	4581                	li	a1,0
    80000ae0:	d5bff0ef          	jal	ra,8000083a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ae4:	00c4d793          	srli	a5,s1,0xc
    80000ae8:	07aa                	slli	a5,a5,0xa
    80000aea:	0017e793          	ori	a5,a5,1
    80000aee:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000af2:	3a5d                	addiw	s4,s4,-9
    80000af4:	036a0063          	beq	s4,s6,80000b14 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000af8:	0149d933          	srl	s2,s3,s4
    80000afc:	1ff97913          	andi	s2,s2,511
    80000b00:	090e                	slli	s2,s2,0x3
    80000b02:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000b04:	00093483          	ld	s1,0(s2)
    80000b08:	0014f793          	andi	a5,s1,1
    80000b0c:	d3f1                	beqz	a5,80000ad0 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000b0e:	80a9                	srli	s1,s1,0xa
    80000b10:	04b2                	slli	s1,s1,0xc
    80000b12:	b7c5                	j	80000af2 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000b14:	00c9d513          	srli	a0,s3,0xc
    80000b18:	1ff57513          	andi	a0,a0,511
    80000b1c:	050e                	slli	a0,a0,0x3
    80000b1e:	9526                	add	a0,a0,s1
}
    80000b20:	70e2                	ld	ra,56(sp)
    80000b22:	7442                	ld	s0,48(sp)
    80000b24:	74a2                	ld	s1,40(sp)
    80000b26:	7902                	ld	s2,32(sp)
    80000b28:	69e2                	ld	s3,24(sp)
    80000b2a:	6a42                	ld	s4,16(sp)
    80000b2c:	6aa2                	ld	s5,8(sp)
    80000b2e:	6b02                	ld	s6,0(sp)
    80000b30:	6121                	addi	sp,sp,64
    80000b32:	8082                	ret
        return 0;
    80000b34:	4501                	li	a0,0
    80000b36:	b7ed                	j	80000b20 <walk+0x82>

0000000080000b38 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000b38:	57fd                	li	a5,-1
    80000b3a:	83e9                	srli	a5,a5,0x1a
    80000b3c:	00b7f463          	bgeu	a5,a1,80000b44 <walkaddr+0xc>
    return 0;
    80000b40:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000b42:	8082                	ret
{
    80000b44:	1141                	addi	sp,sp,-16
    80000b46:	e406                	sd	ra,8(sp)
    80000b48:	e022                	sd	s0,0(sp)
    80000b4a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000b4c:	4601                	li	a2,0
    80000b4e:	f51ff0ef          	jal	ra,80000a9e <walk>
  if(pte == 0)
    80000b52:	c105                	beqz	a0,80000b72 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000b54:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000b56:	0117f693          	andi	a3,a5,17
    80000b5a:	4745                	li	a4,17
    return 0;
    80000b5c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000b5e:	00e68663          	beq	a3,a4,80000b6a <walkaddr+0x32>
}
    80000b62:	60a2                	ld	ra,8(sp)
    80000b64:	6402                	ld	s0,0(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret
  pa = PTE2PA(*pte);
    80000b6a:	00a7d513          	srli	a0,a5,0xa
    80000b6e:	0532                	slli	a0,a0,0xc
  return pa;
    80000b70:	bfcd                	j	80000b62 <walkaddr+0x2a>
    return 0;
    80000b72:	4501                	li	a0,0
    80000b74:	b7fd                	j	80000b62 <walkaddr+0x2a>

0000000080000b76 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000b76:	715d                	addi	sp,sp,-80
    80000b78:	e486                	sd	ra,72(sp)
    80000b7a:	e0a2                	sd	s0,64(sp)
    80000b7c:	fc26                	sd	s1,56(sp)
    80000b7e:	f84a                	sd	s2,48(sp)
    80000b80:	f44e                	sd	s3,40(sp)
    80000b82:	f052                	sd	s4,32(sp)
    80000b84:	ec56                	sd	s5,24(sp)
    80000b86:	e85a                	sd	s6,16(sp)
    80000b88:	e45e                	sd	s7,8(sp)
    80000b8a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80000b8c:	c629                	beqz	a2,80000bd6 <mappages+0x60>
    80000b8e:	8aaa                	mv	s5,a0
    80000b90:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80000b92:	77fd                	lui	a5,0xfffff
    80000b94:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80000b98:	15fd                	addi	a1,a1,-1
    80000b9a:	00c589b3          	add	s3,a1,a2
    80000b9e:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80000ba2:	8952                	mv	s2,s4
    80000ba4:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80000ba8:	6b85                	lui	s7,0x1
    80000baa:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80000bae:	4605                	li	a2,1
    80000bb0:	85ca                	mv	a1,s2
    80000bb2:	8556                	mv	a0,s5
    80000bb4:	eebff0ef          	jal	ra,80000a9e <walk>
    80000bb8:	c91d                	beqz	a0,80000bee <mappages+0x78>
    if(*pte & PTE_V)
    80000bba:	611c                	ld	a5,0(a0)
    80000bbc:	8b85                	andi	a5,a5,1
    80000bbe:	e395                	bnez	a5,80000be2 <mappages+0x6c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80000bc0:	80b1                	srli	s1,s1,0xc
    80000bc2:	04aa                	slli	s1,s1,0xa
    80000bc4:	0164e4b3          	or	s1,s1,s6
    80000bc8:	0014e493          	ori	s1,s1,1
    80000bcc:	e104                	sd	s1,0(a0)
    if(a == last)
    80000bce:	03390c63          	beq	s2,s3,80000c06 <mappages+0x90>
    a += PGSIZE;
    80000bd2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80000bd4:	bfd9                	j	80000baa <mappages+0x34>
    panic("mappages: size");
    80000bd6:	00003517          	auipc	a0,0x3
    80000bda:	4e250513          	addi	a0,a0,1250 # 800040b8 <digits+0x80>
    80000bde:	dbeff0ef          	jal	ra,8000019c <panic>
      panic("mappages: remap");
    80000be2:	00003517          	auipc	a0,0x3
    80000be6:	4e650513          	addi	a0,a0,1254 # 800040c8 <digits+0x90>
    80000bea:	db2ff0ef          	jal	ra,8000019c <panic>
      return -1;
    80000bee:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80000bf0:	60a6                	ld	ra,72(sp)
    80000bf2:	6406                	ld	s0,64(sp)
    80000bf4:	74e2                	ld	s1,56(sp)
    80000bf6:	7942                	ld	s2,48(sp)
    80000bf8:	79a2                	ld	s3,40(sp)
    80000bfa:	7a02                	ld	s4,32(sp)
    80000bfc:	6ae2                	ld	s5,24(sp)
    80000bfe:	6b42                	ld	s6,16(sp)
    80000c00:	6ba2                	ld	s7,8(sp)
    80000c02:	6161                	addi	sp,sp,80
    80000c04:	8082                	ret
  return 0;
    80000c06:	4501                	li	a0,0
    80000c08:	b7e5                	j	80000bf0 <mappages+0x7a>

0000000080000c0a <kvmmap>:
{
    80000c0a:	1141                	addi	sp,sp,-16
    80000c0c:	e406                	sd	ra,8(sp)
    80000c0e:	e022                	sd	s0,0(sp)
    80000c10:	0800                	addi	s0,sp,16
    80000c12:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80000c14:	86b2                	mv	a3,a2
    80000c16:	863e                	mv	a2,a5
    80000c18:	f5fff0ef          	jal	ra,80000b76 <mappages>
    80000c1c:	e509                	bnez	a0,80000c26 <kvmmap+0x1c>
}
    80000c1e:	60a2                	ld	ra,8(sp)
    80000c20:	6402                	ld	s0,0(sp)
    80000c22:	0141                	addi	sp,sp,16
    80000c24:	8082                	ret
    panic("kvmmap");
    80000c26:	00003517          	auipc	a0,0x3
    80000c2a:	4b250513          	addi	a0,a0,1202 # 800040d8 <digits+0xa0>
    80000c2e:	d6eff0ef          	jal	ra,8000019c <panic>

0000000080000c32 <kvmmake>:
{
    80000c32:	1101                	addi	sp,sp,-32
    80000c34:	ec06                	sd	ra,24(sp)
    80000c36:	e822                	sd	s0,16(sp)
    80000c38:	e426                	sd	s1,8(sp)
    80000c3a:	e04a                	sd	s2,0(sp)
    80000c3c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80000c3e:	a59ff0ef          	jal	ra,80000696 <kalloc>
    80000c42:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80000c44:	6605                	lui	a2,0x1
    80000c46:	4581                	li	a1,0
    80000c48:	bf3ff0ef          	jal	ra,8000083a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80000c4c:	4719                	li	a4,6
    80000c4e:	6685                	lui	a3,0x1
    80000c50:	10000637          	lui	a2,0x10000
    80000c54:	100005b7          	lui	a1,0x10000
    80000c58:	8526                	mv	a0,s1
    80000c5a:	fb1ff0ef          	jal	ra,80000c0a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80000c5e:	4719                	li	a4,6
    80000c60:	6685                	lui	a3,0x1
    80000c62:	10001637          	lui	a2,0x10001
    80000c66:	100015b7          	lui	a1,0x10001
    80000c6a:	8526                	mv	a0,s1
    80000c6c:	f9fff0ef          	jal	ra,80000c0a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80000c70:	4719                	li	a4,6
    80000c72:	004006b7          	lui	a3,0x400
    80000c76:	0c000637          	lui	a2,0xc000
    80000c7a:	0c0005b7          	lui	a1,0xc000
    80000c7e:	8526                	mv	a0,s1
    80000c80:	f8bff0ef          	jal	ra,80000c0a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80000c84:	00003917          	auipc	s2,0x3
    80000c88:	37c90913          	addi	s2,s2,892 # 80004000 <etext>
    80000c8c:	4729                	li	a4,10
    80000c8e:	80003697          	auipc	a3,0x80003
    80000c92:	37268693          	addi	a3,a3,882 # 4000 <_entry-0x7fffc000>
    80000c96:	4605                	li	a2,1
    80000c98:	067e                	slli	a2,a2,0x1f
    80000c9a:	85b2                	mv	a1,a2
    80000c9c:	8526                	mv	a0,s1
    80000c9e:	f6dff0ef          	jal	ra,80000c0a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80000ca2:	4719                	li	a4,6
    80000ca4:	46c5                	li	a3,17
    80000ca6:	06ee                	slli	a3,a3,0x1b
    80000ca8:	412686b3          	sub	a3,a3,s2
    80000cac:	864a                	mv	a2,s2
    80000cae:	85ca                	mv	a1,s2
    80000cb0:	8526                	mv	a0,s1
    80000cb2:	f59ff0ef          	jal	ra,80000c0a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80000cb6:	4729                	li	a4,10
    80000cb8:	6685                	lui	a3,0x1
    80000cba:	00002617          	auipc	a2,0x2
    80000cbe:	34660613          	addi	a2,a2,838 # 80003000 <_trampoline>
    80000cc2:	040005b7          	lui	a1,0x4000
    80000cc6:	15fd                	addi	a1,a1,-1
    80000cc8:	05b2                	slli	a1,a1,0xc
    80000cca:	8526                	mv	a0,s1
    80000ccc:	f3fff0ef          	jal	ra,80000c0a <kvmmap>
  proc_mapstacks(kpgtbl);
    80000cd0:	8526                	mv	a0,s1
    80000cd2:	560000ef          	jal	ra,80001232 <proc_mapstacks>
}
    80000cd6:	8526                	mv	a0,s1
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6902                	ld	s2,0(sp)
    80000ce0:	6105                	addi	sp,sp,32
    80000ce2:	8082                	ret

0000000080000ce4 <kvminit>:
{
    80000ce4:	1141                	addi	sp,sp,-16
    80000ce6:	e406                	sd	ra,8(sp)
    80000ce8:	e022                	sd	s0,0(sp)
    80000cea:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80000cec:	f47ff0ef          	jal	ra,80000c32 <kvmmake>
    80000cf0:	00004797          	auipc	a5,0x4
    80000cf4:	3aa7b023          	sd	a0,928(a5) # 80005090 <kernel_pagetable>
}
    80000cf8:	60a2                	ld	ra,8(sp)
    80000cfa:	6402                	ld	s0,0(sp)
    80000cfc:	0141                	addi	sp,sp,16
    80000cfe:	8082                	ret

0000000080000d00 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80000d00:	715d                	addi	sp,sp,-80
    80000d02:	e486                	sd	ra,72(sp)
    80000d04:	e0a2                	sd	s0,64(sp)
    80000d06:	fc26                	sd	s1,56(sp)
    80000d08:	f84a                	sd	s2,48(sp)
    80000d0a:	f44e                	sd	s3,40(sp)
    80000d0c:	f052                	sd	s4,32(sp)
    80000d0e:	ec56                	sd	s5,24(sp)
    80000d10:	e85a                	sd	s6,16(sp)
    80000d12:	e45e                	sd	s7,8(sp)
    80000d14:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80000d16:	03459793          	slli	a5,a1,0x34
    80000d1a:	e795                	bnez	a5,80000d46 <uvmunmap+0x46>
    80000d1c:	8a2a                	mv	s4,a0
    80000d1e:	892e                	mv	s2,a1
    80000d20:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80000d22:	0632                	slli	a2,a2,0xc
    80000d24:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80000d28:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80000d2a:	6b05                	lui	s6,0x1
    80000d2c:	0535ea63          	bltu	a1,s3,80000d80 <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80000d30:	60a6                	ld	ra,72(sp)
    80000d32:	6406                	ld	s0,64(sp)
    80000d34:	74e2                	ld	s1,56(sp)
    80000d36:	7942                	ld	s2,48(sp)
    80000d38:	79a2                	ld	s3,40(sp)
    80000d3a:	7a02                	ld	s4,32(sp)
    80000d3c:	6ae2                	ld	s5,24(sp)
    80000d3e:	6b42                	ld	s6,16(sp)
    80000d40:	6ba2                	ld	s7,8(sp)
    80000d42:	6161                	addi	sp,sp,80
    80000d44:	8082                	ret
    panic("uvmunmap: not aligned");
    80000d46:	00003517          	auipc	a0,0x3
    80000d4a:	39a50513          	addi	a0,a0,922 # 800040e0 <digits+0xa8>
    80000d4e:	c4eff0ef          	jal	ra,8000019c <panic>
      panic("uvmunmap: walk");
    80000d52:	00003517          	auipc	a0,0x3
    80000d56:	3a650513          	addi	a0,a0,934 # 800040f8 <digits+0xc0>
    80000d5a:	c42ff0ef          	jal	ra,8000019c <panic>
      panic("uvmunmap: not mapped");
    80000d5e:	00003517          	auipc	a0,0x3
    80000d62:	3aa50513          	addi	a0,a0,938 # 80004108 <digits+0xd0>
    80000d66:	c36ff0ef          	jal	ra,8000019c <panic>
      panic("uvmunmap: not a leaf");
    80000d6a:	00003517          	auipc	a0,0x3
    80000d6e:	3b650513          	addi	a0,a0,950 # 80004120 <digits+0xe8>
    80000d72:	c2aff0ef          	jal	ra,8000019c <panic>
    *pte = 0;
    80000d76:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80000d7a:	995a                	add	s2,s2,s6
    80000d7c:	fb397ae3          	bgeu	s2,s3,80000d30 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80000d80:	4601                	li	a2,0
    80000d82:	85ca                	mv	a1,s2
    80000d84:	8552                	mv	a0,s4
    80000d86:	d19ff0ef          	jal	ra,80000a9e <walk>
    80000d8a:	84aa                	mv	s1,a0
    80000d8c:	d179                	beqz	a0,80000d52 <uvmunmap+0x52>
    if((*pte & PTE_V) == 0)
    80000d8e:	6108                	ld	a0,0(a0)
    80000d90:	00157793          	andi	a5,a0,1
    80000d94:	d7e9                	beqz	a5,80000d5e <uvmunmap+0x5e>
    if(PTE_FLAGS(*pte) == PTE_V)
    80000d96:	3ff57793          	andi	a5,a0,1023
    80000d9a:	fd7788e3          	beq	a5,s7,80000d6a <uvmunmap+0x6a>
    if(do_free){
    80000d9e:	fc0a8ce3          	beqz	s5,80000d76 <uvmunmap+0x76>
      uint64 pa = PTE2PA(*pte);
    80000da2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80000da4:	0532                	slli	a0,a0,0xc
    80000da6:	811ff0ef          	jal	ra,800005b6 <kfree>
    80000daa:	b7f1                	j	80000d76 <uvmunmap+0x76>

0000000080000dac <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80000dac:	1101                	addi	sp,sp,-32
    80000dae:	ec06                	sd	ra,24(sp)
    80000db0:	e822                	sd	s0,16(sp)
    80000db2:	e426                	sd	s1,8(sp)
    80000db4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80000db6:	8e1ff0ef          	jal	ra,80000696 <kalloc>
    80000dba:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80000dbc:	c509                	beqz	a0,80000dc6 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80000dbe:	6605                	lui	a2,0x1
    80000dc0:	4581                	li	a1,0
    80000dc2:	a79ff0ef          	jal	ra,8000083a <memset>
  return pagetable;
}
    80000dc6:	8526                	mv	a0,s1
    80000dc8:	60e2                	ld	ra,24(sp)
    80000dca:	6442                	ld	s0,16(sp)
    80000dcc:	64a2                	ld	s1,8(sp)
    80000dce:	6105                	addi	sp,sp,32
    80000dd0:	8082                	ret

0000000080000dd2 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80000dd2:	7179                	addi	sp,sp,-48
    80000dd4:	f406                	sd	ra,40(sp)
    80000dd6:	f022                	sd	s0,32(sp)
    80000dd8:	ec26                	sd	s1,24(sp)
    80000dda:	e84a                	sd	s2,16(sp)
    80000ddc:	e44e                	sd	s3,8(sp)
    80000dde:	e052                	sd	s4,0(sp)
    80000de0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80000de2:	6785                	lui	a5,0x1
    80000de4:	04f67063          	bgeu	a2,a5,80000e24 <uvmfirst+0x52>
    80000de8:	8a2a                	mv	s4,a0
    80000dea:	89ae                	mv	s3,a1
    80000dec:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80000dee:	8a9ff0ef          	jal	ra,80000696 <kalloc>
    80000df2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80000df4:	6605                	lui	a2,0x1
    80000df6:	4581                	li	a1,0
    80000df8:	a43ff0ef          	jal	ra,8000083a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80000dfc:	4779                	li	a4,30
    80000dfe:	86ca                	mv	a3,s2
    80000e00:	6605                	lui	a2,0x1
    80000e02:	4581                	li	a1,0
    80000e04:	8552                	mv	a0,s4
    80000e06:	d71ff0ef          	jal	ra,80000b76 <mappages>
  memmove(mem, src, sz);
    80000e0a:	8626                	mv	a2,s1
    80000e0c:	85ce                	mv	a1,s3
    80000e0e:	854a                	mv	a0,s2
    80000e10:	a87ff0ef          	jal	ra,80000896 <memmove>
}
    80000e14:	70a2                	ld	ra,40(sp)
    80000e16:	7402                	ld	s0,32(sp)
    80000e18:	64e2                	ld	s1,24(sp)
    80000e1a:	6942                	ld	s2,16(sp)
    80000e1c:	69a2                	ld	s3,8(sp)
    80000e1e:	6a02                	ld	s4,0(sp)
    80000e20:	6145                	addi	sp,sp,48
    80000e22:	8082                	ret
    panic("uvmfirst: more than a page");
    80000e24:	00003517          	auipc	a0,0x3
    80000e28:	31450513          	addi	a0,a0,788 # 80004138 <digits+0x100>
    80000e2c:	b70ff0ef          	jal	ra,8000019c <panic>

0000000080000e30 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80000e30:	1101                	addi	sp,sp,-32
    80000e32:	ec06                	sd	ra,24(sp)
    80000e34:	e822                	sd	s0,16(sp)
    80000e36:	e426                	sd	s1,8(sp)
    80000e38:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80000e3a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80000e3c:	00b67d63          	bgeu	a2,a1,80000e56 <uvmdealloc+0x26>
    80000e40:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80000e42:	6785                	lui	a5,0x1
    80000e44:	17fd                	addi	a5,a5,-1
    80000e46:	00f60733          	add	a4,a2,a5
    80000e4a:	767d                	lui	a2,0xfffff
    80000e4c:	8f71                	and	a4,a4,a2
    80000e4e:	97ae                	add	a5,a5,a1
    80000e50:	8ff1                	and	a5,a5,a2
    80000e52:	00f76863          	bltu	a4,a5,80000e62 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80000e56:	8526                	mv	a0,s1
    80000e58:	60e2                	ld	ra,24(sp)
    80000e5a:	6442                	ld	s0,16(sp)
    80000e5c:	64a2                	ld	s1,8(sp)
    80000e5e:	6105                	addi	sp,sp,32
    80000e60:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80000e62:	8f99                	sub	a5,a5,a4
    80000e64:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80000e66:	4685                	li	a3,1
    80000e68:	0007861b          	sext.w	a2,a5
    80000e6c:	85ba                	mv	a1,a4
    80000e6e:	e93ff0ef          	jal	ra,80000d00 <uvmunmap>
    80000e72:	b7d5                	j	80000e56 <uvmdealloc+0x26>

0000000080000e74 <uvmalloc>:
  if(newsz < oldsz)
    80000e74:	08b66963          	bltu	a2,a1,80000f06 <uvmalloc+0x92>
{
    80000e78:	7139                	addi	sp,sp,-64
    80000e7a:	fc06                	sd	ra,56(sp)
    80000e7c:	f822                	sd	s0,48(sp)
    80000e7e:	f426                	sd	s1,40(sp)
    80000e80:	f04a                	sd	s2,32(sp)
    80000e82:	ec4e                	sd	s3,24(sp)
    80000e84:	e852                	sd	s4,16(sp)
    80000e86:	e456                	sd	s5,8(sp)
    80000e88:	e05a                	sd	s6,0(sp)
    80000e8a:	0080                	addi	s0,sp,64
    80000e8c:	8aaa                	mv	s5,a0
    80000e8e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80000e90:	6985                	lui	s3,0x1
    80000e92:	19fd                	addi	s3,s3,-1
    80000e94:	95ce                	add	a1,a1,s3
    80000e96:	79fd                	lui	s3,0xfffff
    80000e98:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80000e9c:	06c9f763          	bgeu	s3,a2,80000f0a <uvmalloc+0x96>
    80000ea0:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80000ea2:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80000ea6:	ff0ff0ef          	jal	ra,80000696 <kalloc>
    80000eaa:	84aa                	mv	s1,a0
    if(mem == 0){
    80000eac:	c11d                	beqz	a0,80000ed2 <uvmalloc+0x5e>
    memset(mem, 0, PGSIZE);
    80000eae:	6605                	lui	a2,0x1
    80000eb0:	4581                	li	a1,0
    80000eb2:	989ff0ef          	jal	ra,8000083a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80000eb6:	875a                	mv	a4,s6
    80000eb8:	86a6                	mv	a3,s1
    80000eba:	6605                	lui	a2,0x1
    80000ebc:	85ca                	mv	a1,s2
    80000ebe:	8556                	mv	a0,s5
    80000ec0:	cb7ff0ef          	jal	ra,80000b76 <mappages>
    80000ec4:	e51d                	bnez	a0,80000ef2 <uvmalloc+0x7e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80000ec6:	6785                	lui	a5,0x1
    80000ec8:	993e                	add	s2,s2,a5
    80000eca:	fd496ee3          	bltu	s2,s4,80000ea6 <uvmalloc+0x32>
  return newsz;
    80000ece:	8552                	mv	a0,s4
    80000ed0:	a039                	j	80000ede <uvmalloc+0x6a>
      uvmdealloc(pagetable, a, oldsz);
    80000ed2:	864e                	mv	a2,s3
    80000ed4:	85ca                	mv	a1,s2
    80000ed6:	8556                	mv	a0,s5
    80000ed8:	f59ff0ef          	jal	ra,80000e30 <uvmdealloc>
      return 0;
    80000edc:	4501                	li	a0,0
}
    80000ede:	70e2                	ld	ra,56(sp)
    80000ee0:	7442                	ld	s0,48(sp)
    80000ee2:	74a2                	ld	s1,40(sp)
    80000ee4:	7902                	ld	s2,32(sp)
    80000ee6:	69e2                	ld	s3,24(sp)
    80000ee8:	6a42                	ld	s4,16(sp)
    80000eea:	6aa2                	ld	s5,8(sp)
    80000eec:	6b02                	ld	s6,0(sp)
    80000eee:	6121                	addi	sp,sp,64
    80000ef0:	8082                	ret
      kfree(mem);
    80000ef2:	8526                	mv	a0,s1
    80000ef4:	ec2ff0ef          	jal	ra,800005b6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80000ef8:	864e                	mv	a2,s3
    80000efa:	85ca                	mv	a1,s2
    80000efc:	8556                	mv	a0,s5
    80000efe:	f33ff0ef          	jal	ra,80000e30 <uvmdealloc>
      return 0;
    80000f02:	4501                	li	a0,0
    80000f04:	bfe9                	j	80000ede <uvmalloc+0x6a>
    return oldsz;
    80000f06:	852e                	mv	a0,a1
}
    80000f08:	8082                	ret
  return newsz;
    80000f0a:	8532                	mv	a0,a2
    80000f0c:	bfc9                	j	80000ede <uvmalloc+0x6a>

0000000080000f0e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80000f0e:	7179                	addi	sp,sp,-48
    80000f10:	f406                	sd	ra,40(sp)
    80000f12:	f022                	sd	s0,32(sp)
    80000f14:	ec26                	sd	s1,24(sp)
    80000f16:	e84a                	sd	s2,16(sp)
    80000f18:	e44e                	sd	s3,8(sp)
    80000f1a:	e052                	sd	s4,0(sp)
    80000f1c:	1800                	addi	s0,sp,48
    80000f1e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000f20:	84aa                	mv	s1,a0
    80000f22:	6905                	lui	s2,0x1
    80000f24:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000f26:	4985                	li	s3,1
    80000f28:	a811                	j	80000f3c <freewalk+0x2e>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80000f2a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80000f2c:	0532                	slli	a0,a0,0xc
    80000f2e:	fe1ff0ef          	jal	ra,80000f0e <freewalk>
      pagetable[i] = 0;
    80000f32:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80000f36:	04a1                	addi	s1,s1,8
    80000f38:	01248f63          	beq	s1,s2,80000f56 <freewalk+0x48>
    pte_t pte = pagetable[i];
    80000f3c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000f3e:	00f57793          	andi	a5,a0,15
    80000f42:	ff3784e3          	beq	a5,s3,80000f2a <freewalk+0x1c>
    } else if(pte & PTE_V){
    80000f46:	8905                	andi	a0,a0,1
    80000f48:	d57d                	beqz	a0,80000f36 <freewalk+0x28>
      panic("freewalk: leaf");
    80000f4a:	00003517          	auipc	a0,0x3
    80000f4e:	20e50513          	addi	a0,a0,526 # 80004158 <digits+0x120>
    80000f52:	a4aff0ef          	jal	ra,8000019c <panic>
    }
  }
  kfree((void*)pagetable);
    80000f56:	8552                	mv	a0,s4
    80000f58:	e5eff0ef          	jal	ra,800005b6 <kfree>
}
    80000f5c:	70a2                	ld	ra,40(sp)
    80000f5e:	7402                	ld	s0,32(sp)
    80000f60:	64e2                	ld	s1,24(sp)
    80000f62:	6942                	ld	s2,16(sp)
    80000f64:	69a2                	ld	s3,8(sp)
    80000f66:	6a02                	ld	s4,0(sp)
    80000f68:	6145                	addi	sp,sp,48
    80000f6a:	8082                	ret

0000000080000f6c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80000f6c:	1101                	addi	sp,sp,-32
    80000f6e:	ec06                	sd	ra,24(sp)
    80000f70:	e822                	sd	s0,16(sp)
    80000f72:	e426                	sd	s1,8(sp)
    80000f74:	1000                	addi	s0,sp,32
    80000f76:	84aa                	mv	s1,a0
  if(sz > 0)
    80000f78:	e989                	bnez	a1,80000f8a <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80000f7a:	8526                	mv	a0,s1
    80000f7c:	f93ff0ef          	jal	ra,80000f0e <freewalk>
}
    80000f80:	60e2                	ld	ra,24(sp)
    80000f82:	6442                	ld	s0,16(sp)
    80000f84:	64a2                	ld	s1,8(sp)
    80000f86:	6105                	addi	sp,sp,32
    80000f88:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80000f8a:	6605                	lui	a2,0x1
    80000f8c:	167d                	addi	a2,a2,-1
    80000f8e:	962e                	add	a2,a2,a1
    80000f90:	4685                	li	a3,1
    80000f92:	8231                	srli	a2,a2,0xc
    80000f94:	4581                	li	a1,0
    80000f96:	d6bff0ef          	jal	ra,80000d00 <uvmunmap>
    80000f9a:	b7c5                	j	80000f7a <uvmfree+0xe>

0000000080000f9c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80000f9c:	c65d                	beqz	a2,8000104a <uvmcopy+0xae>
{
    80000f9e:	715d                	addi	sp,sp,-80
    80000fa0:	e486                	sd	ra,72(sp)
    80000fa2:	e0a2                	sd	s0,64(sp)
    80000fa4:	fc26                	sd	s1,56(sp)
    80000fa6:	f84a                	sd	s2,48(sp)
    80000fa8:	f44e                	sd	s3,40(sp)
    80000faa:	f052                	sd	s4,32(sp)
    80000fac:	ec56                	sd	s5,24(sp)
    80000fae:	e85a                	sd	s6,16(sp)
    80000fb0:	e45e                	sd	s7,8(sp)
    80000fb2:	0880                	addi	s0,sp,80
    80000fb4:	8b2a                	mv	s6,a0
    80000fb6:	8aae                	mv	s5,a1
    80000fb8:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80000fba:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80000fbc:	4601                	li	a2,0
    80000fbe:	85ce                	mv	a1,s3
    80000fc0:	855a                	mv	a0,s6
    80000fc2:	addff0ef          	jal	ra,80000a9e <walk>
    80000fc6:	c121                	beqz	a0,80001006 <uvmcopy+0x6a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80000fc8:	6118                	ld	a4,0(a0)
    80000fca:	00177793          	andi	a5,a4,1
    80000fce:	c3b1                	beqz	a5,80001012 <uvmcopy+0x76>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80000fd0:	00a75593          	srli	a1,a4,0xa
    80000fd4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80000fd8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80000fdc:	ebaff0ef          	jal	ra,80000696 <kalloc>
    80000fe0:	892a                	mv	s2,a0
    80000fe2:	c129                	beqz	a0,80001024 <uvmcopy+0x88>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80000fe4:	6605                	lui	a2,0x1
    80000fe6:	85de                	mv	a1,s7
    80000fe8:	8afff0ef          	jal	ra,80000896 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80000fec:	8726                	mv	a4,s1
    80000fee:	86ca                	mv	a3,s2
    80000ff0:	6605                	lui	a2,0x1
    80000ff2:	85ce                	mv	a1,s3
    80000ff4:	8556                	mv	a0,s5
    80000ff6:	b81ff0ef          	jal	ra,80000b76 <mappages>
    80000ffa:	e115                	bnez	a0,8000101e <uvmcopy+0x82>
  for(i = 0; i < sz; i += PGSIZE){
    80000ffc:	6785                	lui	a5,0x1
    80000ffe:	99be                	add	s3,s3,a5
    80001000:	fb49eee3          	bltu	s3,s4,80000fbc <uvmcopy+0x20>
    80001004:	a805                	j	80001034 <uvmcopy+0x98>
      panic("uvmcopy: pte should exist");
    80001006:	00003517          	auipc	a0,0x3
    8000100a:	16250513          	addi	a0,a0,354 # 80004168 <digits+0x130>
    8000100e:	98eff0ef          	jal	ra,8000019c <panic>
      panic("uvmcopy: page not present");
    80001012:	00003517          	auipc	a0,0x3
    80001016:	17650513          	addi	a0,a0,374 # 80004188 <digits+0x150>
    8000101a:	982ff0ef          	jal	ra,8000019c <panic>
      kfree(mem);
    8000101e:	854a                	mv	a0,s2
    80001020:	d96ff0ef          	jal	ra,800005b6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001024:	4685                	li	a3,1
    80001026:	00c9d613          	srli	a2,s3,0xc
    8000102a:	4581                	li	a1,0
    8000102c:	8556                	mv	a0,s5
    8000102e:	cd3ff0ef          	jal	ra,80000d00 <uvmunmap>
  return -1;
    80001032:	557d                	li	a0,-1
}
    80001034:	60a6                	ld	ra,72(sp)
    80001036:	6406                	ld	s0,64(sp)
    80001038:	74e2                	ld	s1,56(sp)
    8000103a:	7942                	ld	s2,48(sp)
    8000103c:	79a2                	ld	s3,40(sp)
    8000103e:	7a02                	ld	s4,32(sp)
    80001040:	6ae2                	ld	s5,24(sp)
    80001042:	6b42                	ld	s6,16(sp)
    80001044:	6ba2                	ld	s7,8(sp)
    80001046:	6161                	addi	sp,sp,80
    80001048:	8082                	ret
  return 0;
    8000104a:	4501                	li	a0,0
}
    8000104c:	8082                	ret

000000008000104e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000104e:	1141                	addi	sp,sp,-16
    80001050:	e406                	sd	ra,8(sp)
    80001052:	e022                	sd	s0,0(sp)
    80001054:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001056:	4601                	li	a2,0
    80001058:	a47ff0ef          	jal	ra,80000a9e <walk>
  if(pte == 0)
    8000105c:	c901                	beqz	a0,8000106c <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000105e:	611c                	ld	a5,0(a0)
    80001060:	9bbd                	andi	a5,a5,-17
    80001062:	e11c                	sd	a5,0(a0)
}
    80001064:	60a2                	ld	ra,8(sp)
    80001066:	6402                	ld	s0,0(sp)
    80001068:	0141                	addi	sp,sp,16
    8000106a:	8082                	ret
    panic("uvmclear");
    8000106c:	00003517          	auipc	a0,0x3
    80001070:	13c50513          	addi	a0,a0,316 # 800041a8 <digits+0x170>
    80001074:	928ff0ef          	jal	ra,8000019c <panic>

0000000080001078 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001078:	c2bd                	beqz	a3,800010de <copyout+0x66>
{
    8000107a:	715d                	addi	sp,sp,-80
    8000107c:	e486                	sd	ra,72(sp)
    8000107e:	e0a2                	sd	s0,64(sp)
    80001080:	fc26                	sd	s1,56(sp)
    80001082:	f84a                	sd	s2,48(sp)
    80001084:	f44e                	sd	s3,40(sp)
    80001086:	f052                	sd	s4,32(sp)
    80001088:	ec56                	sd	s5,24(sp)
    8000108a:	e85a                	sd	s6,16(sp)
    8000108c:	e45e                	sd	s7,8(sp)
    8000108e:	e062                	sd	s8,0(sp)
    80001090:	0880                	addi	s0,sp,80
    80001092:	8b2a                	mv	s6,a0
    80001094:	8c2e                	mv	s8,a1
    80001096:	8a32                	mv	s4,a2
    80001098:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000109a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000109c:	6a85                	lui	s5,0x1
    8000109e:	a005                	j	800010be <copyout+0x46>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800010a0:	9562                	add	a0,a0,s8
    800010a2:	0004861b          	sext.w	a2,s1
    800010a6:	85d2                	mv	a1,s4
    800010a8:	41250533          	sub	a0,a0,s2
    800010ac:	feaff0ef          	jal	ra,80000896 <memmove>

    len -= n;
    800010b0:	409989b3          	sub	s3,s3,s1
    src += n;
    800010b4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800010b6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800010ba:	02098063          	beqz	s3,800010da <copyout+0x62>
    va0 = PGROUNDDOWN(dstva);
    800010be:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800010c2:	85ca                	mv	a1,s2
    800010c4:	855a                	mv	a0,s6
    800010c6:	a73ff0ef          	jal	ra,80000b38 <walkaddr>
    if(pa0 == 0)
    800010ca:	cd01                	beqz	a0,800010e2 <copyout+0x6a>
    n = PGSIZE - (dstva - va0);
    800010cc:	418904b3          	sub	s1,s2,s8
    800010d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800010d2:	fc99f7e3          	bgeu	s3,s1,800010a0 <copyout+0x28>
    800010d6:	84ce                	mv	s1,s3
    800010d8:	b7e1                	j	800010a0 <copyout+0x28>
  }
  return 0;
    800010da:	4501                	li	a0,0
    800010dc:	a021                	j	800010e4 <copyout+0x6c>
    800010de:	4501                	li	a0,0
}
    800010e0:	8082                	ret
      return -1;
    800010e2:	557d                	li	a0,-1
}
    800010e4:	60a6                	ld	ra,72(sp)
    800010e6:	6406                	ld	s0,64(sp)
    800010e8:	74e2                	ld	s1,56(sp)
    800010ea:	7942                	ld	s2,48(sp)
    800010ec:	79a2                	ld	s3,40(sp)
    800010ee:	7a02                	ld	s4,32(sp)
    800010f0:	6ae2                	ld	s5,24(sp)
    800010f2:	6b42                	ld	s6,16(sp)
    800010f4:	6ba2                	ld	s7,8(sp)
    800010f6:	6c02                	ld	s8,0(sp)
    800010f8:	6161                	addi	sp,sp,80
    800010fa:	8082                	ret

00000000800010fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800010fc:	c6a5                	beqz	a3,80001164 <copyin+0x68>
{
    800010fe:	715d                	addi	sp,sp,-80
    80001100:	e486                	sd	ra,72(sp)
    80001102:	e0a2                	sd	s0,64(sp)
    80001104:	fc26                	sd	s1,56(sp)
    80001106:	f84a                	sd	s2,48(sp)
    80001108:	f44e                	sd	s3,40(sp)
    8000110a:	f052                	sd	s4,32(sp)
    8000110c:	ec56                	sd	s5,24(sp)
    8000110e:	e85a                	sd	s6,16(sp)
    80001110:	e45e                	sd	s7,8(sp)
    80001112:	e062                	sd	s8,0(sp)
    80001114:	0880                	addi	s0,sp,80
    80001116:	8b2a                	mv	s6,a0
    80001118:	8a2e                	mv	s4,a1
    8000111a:	8c32                	mv	s8,a2
    8000111c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000111e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001120:	6a85                	lui	s5,0x1
    80001122:	a00d                	j	80001144 <copyin+0x48>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001124:	018505b3          	add	a1,a0,s8
    80001128:	0004861b          	sext.w	a2,s1
    8000112c:	412585b3          	sub	a1,a1,s2
    80001130:	8552                	mv	a0,s4
    80001132:	f64ff0ef          	jal	ra,80000896 <memmove>

    len -= n;
    80001136:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000113a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000113c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001140:	02098063          	beqz	s3,80001160 <copyin+0x64>
    va0 = PGROUNDDOWN(srcva);
    80001144:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001148:	85ca                	mv	a1,s2
    8000114a:	855a                	mv	a0,s6
    8000114c:	9edff0ef          	jal	ra,80000b38 <walkaddr>
    if(pa0 == 0)
    80001150:	cd01                	beqz	a0,80001168 <copyin+0x6c>
    n = PGSIZE - (srcva - va0);
    80001152:	418904b3          	sub	s1,s2,s8
    80001156:	94d6                	add	s1,s1,s5
    if(n > len)
    80001158:	fc99f6e3          	bgeu	s3,s1,80001124 <copyin+0x28>
    8000115c:	84ce                	mv	s1,s3
    8000115e:	b7d9                	j	80001124 <copyin+0x28>
  }
  return 0;
    80001160:	4501                	li	a0,0
    80001162:	a021                	j	8000116a <copyin+0x6e>
    80001164:	4501                	li	a0,0
}
    80001166:	8082                	ret
      return -1;
    80001168:	557d                	li	a0,-1
}
    8000116a:	60a6                	ld	ra,72(sp)
    8000116c:	6406                	ld	s0,64(sp)
    8000116e:	74e2                	ld	s1,56(sp)
    80001170:	7942                	ld	s2,48(sp)
    80001172:	79a2                	ld	s3,40(sp)
    80001174:	7a02                	ld	s4,32(sp)
    80001176:	6ae2                	ld	s5,24(sp)
    80001178:	6b42                	ld	s6,16(sp)
    8000117a:	6ba2                	ld	s7,8(sp)
    8000117c:	6c02                	ld	s8,0(sp)
    8000117e:	6161                	addi	sp,sp,80
    80001180:	8082                	ret

0000000080001182 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001182:	c2d5                	beqz	a3,80001226 <copyinstr+0xa4>
{
    80001184:	715d                	addi	sp,sp,-80
    80001186:	e486                	sd	ra,72(sp)
    80001188:	e0a2                	sd	s0,64(sp)
    8000118a:	fc26                	sd	s1,56(sp)
    8000118c:	f84a                	sd	s2,48(sp)
    8000118e:	f44e                	sd	s3,40(sp)
    80001190:	f052                	sd	s4,32(sp)
    80001192:	ec56                	sd	s5,24(sp)
    80001194:	e85a                	sd	s6,16(sp)
    80001196:	e45e                	sd	s7,8(sp)
    80001198:	0880                	addi	s0,sp,80
    8000119a:	8a2a                	mv	s4,a0
    8000119c:	8b2e                	mv	s6,a1
    8000119e:	8bb2                	mv	s7,a2
    800011a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800011a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800011a4:	6985                	lui	s3,0x1
    800011a6:	a035                	j	800011d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800011a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800011ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800011ae:	0017b793          	seqz	a5,a5
    800011b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800011b6:	60a6                	ld	ra,72(sp)
    800011b8:	6406                	ld	s0,64(sp)
    800011ba:	74e2                	ld	s1,56(sp)
    800011bc:	7942                	ld	s2,48(sp)
    800011be:	79a2                	ld	s3,40(sp)
    800011c0:	7a02                	ld	s4,32(sp)
    800011c2:	6ae2                	ld	s5,24(sp)
    800011c4:	6b42                	ld	s6,16(sp)
    800011c6:	6ba2                	ld	s7,8(sp)
    800011c8:	6161                	addi	sp,sp,80
    800011ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800011cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800011d0:	c4b9                	beqz	s1,8000121e <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    800011d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800011d6:	85ca                	mv	a1,s2
    800011d8:	8552                	mv	a0,s4
    800011da:	95fff0ef          	jal	ra,80000b38 <walkaddr>
    if(pa0 == 0)
    800011de:	c131                	beqz	a0,80001222 <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    800011e0:	41790833          	sub	a6,s2,s7
    800011e4:	984e                	add	a6,a6,s3
    if(n > max)
    800011e6:	0104f363          	bgeu	s1,a6,800011ec <copyinstr+0x6a>
    800011ea:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800011ec:	955e                	add	a0,a0,s7
    800011ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800011f2:	fc080de3          	beqz	a6,800011cc <copyinstr+0x4a>
    800011f6:	985a                	add	a6,a6,s6
    800011f8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800011fa:	41650633          	sub	a2,a0,s6
    800011fe:	14fd                	addi	s1,s1,-1
    80001200:	9b26                	add	s6,s6,s1
    80001202:	00f60733          	add	a4,a2,a5
    80001206:	00074703          	lbu	a4,0(a4)
    8000120a:	df59                	beqz	a4,800011a8 <copyinstr+0x26>
        *dst = *p;
    8000120c:	00e78023          	sb	a4,0(a5)
      --max;
    80001210:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001214:	0785                	addi	a5,a5,1
    while(n > 0){
    80001216:	ff0796e3          	bne	a5,a6,80001202 <copyinstr+0x80>
      dst++;
    8000121a:	8b42                	mv	s6,a6
    8000121c:	bf45                	j	800011cc <copyinstr+0x4a>
    8000121e:	4781                	li	a5,0
    80001220:	b779                	j	800011ae <copyinstr+0x2c>
      return -1;
    80001222:	557d                	li	a0,-1
    80001224:	bf49                	j	800011b6 <copyinstr+0x34>
  int got_null = 0;
    80001226:	4781                	li	a5,0
  if(got_null){
    80001228:	0017b793          	seqz	a5,a5
    8000122c:	40f00533          	neg	a0,a5
}
    80001230:	8082                	ret

0000000080001232 <proc_mapstacks>:
// Map it high in memory, followed by an invalid
// guard page.

void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001232:	7139                	addi	sp,sp,-64
    80001234:	fc06                	sd	ra,56(sp)
    80001236:	f822                	sd	s0,48(sp)
    80001238:	f426                	sd	s1,40(sp)
    8000123a:	f04a                	sd	s2,32(sp)
    8000123c:	ec4e                	sd	s3,24(sp)
    8000123e:	e852                	sd	s4,16(sp)
    80001240:	e456                	sd	s5,8(sp)
    80001242:	e05a                	sd	s6,0(sp)
    80001244:	0080                	addi	s0,sp,64
    80001246:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001248:	0000c497          	auipc	s1,0xc
    8000124c:	45048493          	addi	s1,s1,1104 # 8000d698 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001250:	8b26                	mv	s6,s1
    80001252:	00003a97          	auipc	s5,0x3
    80001256:	daea8a93          	addi	s5,s5,-594 # 80004000 <etext>
    8000125a:	04000937          	lui	s2,0x4000
    8000125e:	197d                	addi	s2,s2,-1
    80001260:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001262:	00010a17          	auipc	s4,0x10
    80001266:	e36a0a13          	addi	s4,s4,-458 # 80011098 <tickslock>
    char *pa = kalloc();
    8000126a:	c2cff0ef          	jal	ra,80000696 <kalloc>
    8000126e:	862a                	mv	a2,a0
    if(pa == 0)
    80001270:	c121                	beqz	a0,800012b0 <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int)(p - proc));
    80001272:	416485b3          	sub	a1,s1,s6
    80001276:	858d                	srai	a1,a1,0x3
    80001278:	000ab783          	ld	a5,0(s5)
    8000127c:	02f585b3          	mul	a1,a1,a5
    80001280:	2585                	addiw	a1,a1,1
    80001282:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001286:	4719                	li	a4,6
    80001288:	6685                	lui	a3,0x1
    8000128a:	40b905b3          	sub	a1,s2,a1
    8000128e:	854e                	mv	a0,s3
    80001290:	97bff0ef          	jal	ra,80000c0a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001294:	0e848493          	addi	s1,s1,232
    80001298:	fd4499e3          	bne	s1,s4,8000126a <proc_mapstacks+0x38>
  }
}
    8000129c:	70e2                	ld	ra,56(sp)
    8000129e:	7442                	ld	s0,48(sp)
    800012a0:	74a2                	ld	s1,40(sp)
    800012a2:	7902                	ld	s2,32(sp)
    800012a4:	69e2                	ld	s3,24(sp)
    800012a6:	6a42                	ld	s4,16(sp)
    800012a8:	6aa2                	ld	s5,8(sp)
    800012aa:	6b02                	ld	s6,0(sp)
    800012ac:	6121                	addi	sp,sp,64
    800012ae:	8082                	ret
      panic("kalloc");
    800012b0:	00003517          	auipc	a0,0x3
    800012b4:	f0850513          	addi	a0,a0,-248 # 800041b8 <digits+0x180>
    800012b8:	ee5fe0ef          	jal	ra,8000019c <panic>

00000000800012bc <procinit>:

// initialize the proc table.

void
procinit(void)
{
    800012bc:	7139                	addi	sp,sp,-64
    800012be:	fc06                	sd	ra,56(sp)
    800012c0:	f822                	sd	s0,48(sp)
    800012c2:	f426                	sd	s1,40(sp)
    800012c4:	f04a                	sd	s2,32(sp)
    800012c6:	ec4e                	sd	s3,24(sp)
    800012c8:	e852                	sd	s4,16(sp)
    800012ca:	e456                	sd	s5,8(sp)
    800012cc:	e05a                	sd	s6,0(sp)
    800012ce:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800012d0:	00003597          	auipc	a1,0x3
    800012d4:	ef058593          	addi	a1,a1,-272 # 800041c0 <digits+0x188>
    800012d8:	0000c517          	auipc	a0,0xc
    800012dc:	f9050513          	addi	a0,a0,-112 # 8000d268 <pid_lock>
    800012e0:	c06ff0ef          	jal	ra,800006e6 <initlock>
  initlock(&wait_lock, "wait_lock");
    800012e4:	00003597          	auipc	a1,0x3
    800012e8:	ee458593          	addi	a1,a1,-284 # 800041c8 <digits+0x190>
    800012ec:	0000c517          	auipc	a0,0xc
    800012f0:	f9450513          	addi	a0,a0,-108 # 8000d280 <wait_lock>
    800012f4:	bf2ff0ef          	jal	ra,800006e6 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800012f8:	0000c497          	auipc	s1,0xc
    800012fc:	3a048493          	addi	s1,s1,928 # 8000d698 <proc>
      initlock(&p->lock, "proc");
    80001300:	00003b17          	auipc	s6,0x3
    80001304:	ed8b0b13          	addi	s6,s6,-296 # 800041d8 <digits+0x1a0>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001308:	8aa6                	mv	s5,s1
    8000130a:	00003a17          	auipc	s4,0x3
    8000130e:	cf6a0a13          	addi	s4,s4,-778 # 80004000 <etext>
    80001312:	04000937          	lui	s2,0x4000
    80001316:	197d                	addi	s2,s2,-1
    80001318:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000131a:	00010997          	auipc	s3,0x10
    8000131e:	d7e98993          	addi	s3,s3,-642 # 80011098 <tickslock>
      initlock(&p->lock, "proc");
    80001322:	85da                	mv	a1,s6
    80001324:	8526                	mv	a0,s1
    80001326:	bc0ff0ef          	jal	ra,800006e6 <initlock>
      p->state = UNUSED;
    8000132a:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000132e:	415487b3          	sub	a5,s1,s5
    80001332:	878d                	srai	a5,a5,0x3
    80001334:	000a3703          	ld	a4,0(s4)
    80001338:	02e787b3          	mul	a5,a5,a4
    8000133c:	2785                	addiw	a5,a5,1
    8000133e:	00d7979b          	slliw	a5,a5,0xd
    80001342:	40f907b3          	sub	a5,s2,a5
    80001346:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001348:	0e848493          	addi	s1,s1,232
    8000134c:	fd349be3          	bne	s1,s3,80001322 <procinit+0x66>
  }
}
    80001350:	70e2                	ld	ra,56(sp)
    80001352:	7442                	ld	s0,48(sp)
    80001354:	74a2                	ld	s1,40(sp)
    80001356:	7902                	ld	s2,32(sp)
    80001358:	69e2                	ld	s3,24(sp)
    8000135a:	6a42                	ld	s4,16(sp)
    8000135c:	6aa2                	ld	s5,8(sp)
    8000135e:	6b02                	ld	s6,0(sp)
    80001360:	6121                	addi	sp,sp,64
    80001362:	8082                	ret

0000000080001364 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001364:	1141                	addi	sp,sp,-16
    80001366:	e422                	sd	s0,8(sp)
    80001368:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000136a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000136c:	2501                	sext.w	a0,a0
    8000136e:	6422                	ld	s0,8(sp)
    80001370:	0141                	addi	sp,sp,16
    80001372:	8082                	ret

0000000080001374 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001374:	1141                	addi	sp,sp,-16
    80001376:	e422                	sd	s0,8(sp)
    80001378:	0800                	addi	s0,sp,16
    8000137a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000137c:	2781                	sext.w	a5,a5
    8000137e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001380:	0000c517          	auipc	a0,0xc
    80001384:	f1850513          	addi	a0,a0,-232 # 8000d298 <cpus>
    80001388:	953e                	add	a0,a0,a5
    8000138a:	6422                	ld	s0,8(sp)
    8000138c:	0141                	addi	sp,sp,16
    8000138e:	8082                	ret

0000000080001390 <myproc>:

// Return the current struct proc *, or zero if none.

struct proc*
myproc(void)
{
    80001390:	1101                	addi	sp,sp,-32
    80001392:	ec06                	sd	ra,24(sp)
    80001394:	e822                	sd	s0,16(sp)
    80001396:	e426                	sd	s1,8(sp)
    80001398:	1000                	addi	s0,sp,32
  push_off();
    8000139a:	b8cff0ef          	jal	ra,80000726 <push_off>
    8000139e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800013a0:	2781                	sext.w	a5,a5
    800013a2:	079e                	slli	a5,a5,0x7
    800013a4:	0000c717          	auipc	a4,0xc
    800013a8:	ec470713          	addi	a4,a4,-316 # 8000d268 <pid_lock>
    800013ac:	97ba                	add	a5,a5,a4
    800013ae:	7b84                	ld	s1,48(a5)
  pop_off();
    800013b0:	bfaff0ef          	jal	ra,800007aa <pop_off>
  return p;
}
    800013b4:	8526                	mv	a0,s1
    800013b6:	60e2                	ld	ra,24(sp)
    800013b8:	6442                	ld	s0,16(sp)
    800013ba:	64a2                	ld	s1,8(sp)
    800013bc:	6105                	addi	sp,sp,32
    800013be:	8082                	ret

00000000800013c0 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800013c0:	1141                	addi	sp,sp,-16
    800013c2:	e406                	sd	ra,8(sp)
    800013c4:	e022                	sd	s0,0(sp)
    800013c6:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800013c8:	fc9ff0ef          	jal	ra,80001390 <myproc>
    800013cc:	c32ff0ef          	jal	ra,800007fe <release>

  if (first) {
    800013d0:	00003797          	auipc	a5,0x3
    800013d4:	0d07a783          	lw	a5,208(a5) # 800044a0 <first.0>
    800013d8:	e799                	bnez	a5,800013e6 <forkret+0x26>
    first = 0;
    // ensure other cores see first=0.
    __sync_synchronize();
  }

  usertrapret();
    800013da:	1dd000ef          	jal	ra,80001db6 <usertrapret>
}
    800013de:	60a2                	ld	ra,8(sp)
    800013e0:	6402                	ld	s0,0(sp)
    800013e2:	0141                	addi	sp,sp,16
    800013e4:	8082                	ret
    first = 0;
    800013e6:	00003797          	auipc	a5,0x3
    800013ea:	0a07ad23          	sw	zero,186(a5) # 800044a0 <first.0>
    __sync_synchronize();
    800013ee:	0ff0000f          	fence
    800013f2:	b7e5                	j	800013da <forkret+0x1a>

00000000800013f4 <allocpid>:
{
    800013f4:	1101                	addi	sp,sp,-32
    800013f6:	ec06                	sd	ra,24(sp)
    800013f8:	e822                	sd	s0,16(sp)
    800013fa:	e426                	sd	s1,8(sp)
    800013fc:	e04a                	sd	s2,0(sp)
    800013fe:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001400:	0000c917          	auipc	s2,0xc
    80001404:	e6890913          	addi	s2,s2,-408 # 8000d268 <pid_lock>
    80001408:	854a                	mv	a0,s2
    8000140a:	b5cff0ef          	jal	ra,80000766 <acquire>
  pid = nextpid;
    8000140e:	00003797          	auipc	a5,0x3
    80001412:	09678793          	addi	a5,a5,150 # 800044a4 <nextpid>
    80001416:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001418:	0014871b          	addiw	a4,s1,1
    8000141c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    8000141e:	854a                	mv	a0,s2
    80001420:	bdeff0ef          	jal	ra,800007fe <release>
}
    80001424:	8526                	mv	a0,s1
    80001426:	60e2                	ld	ra,24(sp)
    80001428:	6442                	ld	s0,16(sp)
    8000142a:	64a2                	ld	s1,8(sp)
    8000142c:	6902                	ld	s2,0(sp)
    8000142e:	6105                	addi	sp,sp,32
    80001430:	8082                	ret

0000000080001432 <proc_pagetable>:
{
    80001432:	1101                	addi	sp,sp,-32
    80001434:	ec06                	sd	ra,24(sp)
    80001436:	e822                	sd	s0,16(sp)
    80001438:	e426                	sd	s1,8(sp)
    8000143a:	e04a                	sd	s2,0(sp)
    8000143c:	1000                	addi	s0,sp,32
    8000143e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001440:	96dff0ef          	jal	ra,80000dac <uvmcreate>
    80001444:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001446:	cd05                	beqz	a0,8000147e <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001448:	4729                	li	a4,10
    8000144a:	00002697          	auipc	a3,0x2
    8000144e:	bb668693          	addi	a3,a3,-1098 # 80003000 <_trampoline>
    80001452:	6605                	lui	a2,0x1
    80001454:	040005b7          	lui	a1,0x4000
    80001458:	15fd                	addi	a1,a1,-1
    8000145a:	05b2                	slli	a1,a1,0xc
    8000145c:	f1aff0ef          	jal	ra,80000b76 <mappages>
    80001460:	02054663          	bltz	a0,8000148c <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001464:	4719                	li	a4,6
    80001466:	05893683          	ld	a3,88(s2)
    8000146a:	6605                	lui	a2,0x1
    8000146c:	020005b7          	lui	a1,0x2000
    80001470:	15fd                	addi	a1,a1,-1
    80001472:	05b6                	slli	a1,a1,0xd
    80001474:	8526                	mv	a0,s1
    80001476:	f00ff0ef          	jal	ra,80000b76 <mappages>
    8000147a:	00054f63          	bltz	a0,80001498 <proc_pagetable+0x66>
}
    8000147e:	8526                	mv	a0,s1
    80001480:	60e2                	ld	ra,24(sp)
    80001482:	6442                	ld	s0,16(sp)
    80001484:	64a2                	ld	s1,8(sp)
    80001486:	6902                	ld	s2,0(sp)
    80001488:	6105                	addi	sp,sp,32
    8000148a:	8082                	ret
    uvmfree(pagetable, 0);
    8000148c:	4581                	li	a1,0
    8000148e:	8526                	mv	a0,s1
    80001490:	addff0ef          	jal	ra,80000f6c <uvmfree>
    return 0;
    80001494:	4481                	li	s1,0
    80001496:	b7e5                	j	8000147e <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001498:	4681                	li	a3,0
    8000149a:	4605                	li	a2,1
    8000149c:	040005b7          	lui	a1,0x4000
    800014a0:	15fd                	addi	a1,a1,-1
    800014a2:	05b2                	slli	a1,a1,0xc
    800014a4:	8526                	mv	a0,s1
    800014a6:	85bff0ef          	jal	ra,80000d00 <uvmunmap>
    uvmfree(pagetable, 0);
    800014aa:	4581                	li	a1,0
    800014ac:	8526                	mv	a0,s1
    800014ae:	abfff0ef          	jal	ra,80000f6c <uvmfree>
    return 0;
    800014b2:	4481                	li	s1,0
    800014b4:	b7e9                	j	8000147e <proc_pagetable+0x4c>

00000000800014b6 <proc_freepagetable>:
{
    800014b6:	1101                	addi	sp,sp,-32
    800014b8:	ec06                	sd	ra,24(sp)
    800014ba:	e822                	sd	s0,16(sp)
    800014bc:	e426                	sd	s1,8(sp)
    800014be:	e04a                	sd	s2,0(sp)
    800014c0:	1000                	addi	s0,sp,32
    800014c2:	84aa                	mv	s1,a0
    800014c4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800014c6:	4681                	li	a3,0
    800014c8:	4605                	li	a2,1
    800014ca:	040005b7          	lui	a1,0x4000
    800014ce:	15fd                	addi	a1,a1,-1
    800014d0:	05b2                	slli	a1,a1,0xc
    800014d2:	82fff0ef          	jal	ra,80000d00 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800014d6:	4681                	li	a3,0
    800014d8:	4605                	li	a2,1
    800014da:	020005b7          	lui	a1,0x2000
    800014de:	15fd                	addi	a1,a1,-1
    800014e0:	05b6                	slli	a1,a1,0xd
    800014e2:	8526                	mv	a0,s1
    800014e4:	81dff0ef          	jal	ra,80000d00 <uvmunmap>
  uvmfree(pagetable, sz);
    800014e8:	85ca                	mv	a1,s2
    800014ea:	8526                	mv	a0,s1
    800014ec:	a81ff0ef          	jal	ra,80000f6c <uvmfree>
}
    800014f0:	60e2                	ld	ra,24(sp)
    800014f2:	6442                	ld	s0,16(sp)
    800014f4:	64a2                	ld	s1,8(sp)
    800014f6:	6902                	ld	s2,0(sp)
    800014f8:	6105                	addi	sp,sp,32
    800014fa:	8082                	ret

00000000800014fc <freeproc>:
{
    800014fc:	1101                	addi	sp,sp,-32
    800014fe:	ec06                	sd	ra,24(sp)
    80001500:	e822                	sd	s0,16(sp)
    80001502:	e426                	sd	s1,8(sp)
    80001504:	1000                	addi	s0,sp,32
    80001506:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001508:	6d28                	ld	a0,88(a0)
    8000150a:	c119                	beqz	a0,80001510 <freeproc+0x14>
    kfree((void*)p->trapframe);
    8000150c:	8aaff0ef          	jal	ra,800005b6 <kfree>
  p->trapframe = 0;
    80001510:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001514:	68a8                	ld	a0,80(s1)
    80001516:	c501                	beqz	a0,8000151e <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001518:	64ac                	ld	a1,72(s1)
    8000151a:	f9dff0ef          	jal	ra,800014b6 <proc_freepagetable>
  p->pagetable = 0;
    8000151e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001522:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001526:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000152a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    8000152e:	0c048c23          	sb	zero,216(s1)
  p->chan = 0;
    80001532:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001536:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000153a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    8000153e:	0004ac23          	sw	zero,24(s1)
}
    80001542:	60e2                	ld	ra,24(sp)
    80001544:	6442                	ld	s0,16(sp)
    80001546:	64a2                	ld	s1,8(sp)
    80001548:	6105                	addi	sp,sp,32
    8000154a:	8082                	ret

000000008000154c <allocproc>:
{
    8000154c:	1101                	addi	sp,sp,-32
    8000154e:	ec06                	sd	ra,24(sp)
    80001550:	e822                	sd	s0,16(sp)
    80001552:	e426                	sd	s1,8(sp)
    80001554:	e04a                	sd	s2,0(sp)
    80001556:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001558:	0000c497          	auipc	s1,0xc
    8000155c:	14048493          	addi	s1,s1,320 # 8000d698 <proc>
    80001560:	00010917          	auipc	s2,0x10
    80001564:	b3890913          	addi	s2,s2,-1224 # 80011098 <tickslock>
    acquire(&p->lock);
    80001568:	8526                	mv	a0,s1
    8000156a:	9fcff0ef          	jal	ra,80000766 <acquire>
    if(p->state == UNUSED) {
    8000156e:	4c9c                	lw	a5,24(s1)
    80001570:	cb91                	beqz	a5,80001584 <allocproc+0x38>
      release(&p->lock);
    80001572:	8526                	mv	a0,s1
    80001574:	a8aff0ef          	jal	ra,800007fe <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001578:	0e848493          	addi	s1,s1,232
    8000157c:	ff2496e3          	bne	s1,s2,80001568 <allocproc+0x1c>
  return 0;
    80001580:	4481                	li	s1,0
    80001582:	a089                	j	800015c4 <allocproc+0x78>
  p->pid = allocpid();
    80001584:	e71ff0ef          	jal	ra,800013f4 <allocpid>
    80001588:	d888                	sw	a0,48(s1)
  p->state = USED;
    8000158a:	4785                	li	a5,1
    8000158c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000158e:	908ff0ef          	jal	ra,80000696 <kalloc>
    80001592:	892a                	mv	s2,a0
    80001594:	eca8                	sd	a0,88(s1)
    80001596:	cd15                	beqz	a0,800015d2 <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001598:	8526                	mv	a0,s1
    8000159a:	e99ff0ef          	jal	ra,80001432 <proc_pagetable>
    8000159e:	892a                	mv	s2,a0
    800015a0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800015a2:	c121                	beqz	a0,800015e2 <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    800015a4:	07000613          	li	a2,112
    800015a8:	4581                	li	a1,0
    800015aa:	06048513          	addi	a0,s1,96
    800015ae:	a8cff0ef          	jal	ra,8000083a <memset>
  p->context.ra = (uint64)forkret;
    800015b2:	00000797          	auipc	a5,0x0
    800015b6:	e0e78793          	addi	a5,a5,-498 # 800013c0 <forkret>
    800015ba:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    800015bc:	60bc                	ld	a5,64(s1)
    800015be:	6705                	lui	a4,0x1
    800015c0:	97ba                	add	a5,a5,a4
    800015c2:	f4bc                	sd	a5,104(s1)
}
    800015c4:	8526                	mv	a0,s1
    800015c6:	60e2                	ld	ra,24(sp)
    800015c8:	6442                	ld	s0,16(sp)
    800015ca:	64a2                	ld	s1,8(sp)
    800015cc:	6902                	ld	s2,0(sp)
    800015ce:	6105                	addi	sp,sp,32
    800015d0:	8082                	ret
    freeproc(p);
    800015d2:	8526                	mv	a0,s1
    800015d4:	f29ff0ef          	jal	ra,800014fc <freeproc>
    release(&p->lock);
    800015d8:	8526                	mv	a0,s1
    800015da:	a24ff0ef          	jal	ra,800007fe <release>
    return 0;
    800015de:	84ca                	mv	s1,s2
    800015e0:	b7d5                	j	800015c4 <allocproc+0x78>
    freeproc(p);
    800015e2:	8526                	mv	a0,s1
    800015e4:	f19ff0ef          	jal	ra,800014fc <freeproc>
    release(&p->lock);
    800015e8:	8526                	mv	a0,s1
    800015ea:	a14ff0ef          	jal	ra,800007fe <release>
    return 0;
    800015ee:	84ca                	mv	s1,s2
    800015f0:	bfd1                	j	800015c4 <allocproc+0x78>

00000000800015f2 <userinit>:
{
    800015f2:	7179                	addi	sp,sp,-48
    800015f4:	f406                	sd	ra,40(sp)
    800015f6:	f022                	sd	s0,32(sp)
    800015f8:	ec26                	sd	s1,24(sp)
    800015fa:	e84a                	sd	s2,16(sp)
    800015fc:	e44e                	sd	s3,8(sp)
    800015fe:	e052                	sd	s4,0(sp)
    80001600:	1800                	addi	s0,sp,48
  p = allocproc();
    80001602:	f4bff0ef          	jal	ra,8000154c <allocproc>
    80001606:	84aa                	mv	s1,a0
  initproc = p;
    80001608:	00004797          	auipc	a5,0x4
    8000160c:	a8a7b823          	sd	a0,-1392(a5) # 80005098 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001610:	6905                	lui	s2,0x1
    80001612:	bb890613          	addi	a2,s2,-1096 # bb8 <_entry-0x7ffff448>
    80001616:	00003597          	auipc	a1,0x3
    8000161a:	e9a58593          	addi	a1,a1,-358 # 800044b0 <initcode>
    8000161e:	6928                	ld	a0,80(a0)
    80001620:	fb2ff0ef          	jal	ra,80000dd2 <uvmfirst>
  p->sz = PGSIZE;
    80001624:	0524b423          	sd	s2,72(s1)
  p->trapframe->epc = 0x708;      // user program counter
    80001628:	6cbc                	ld	a5,88(s1)
    8000162a:	70800713          	li	a4,1800
    8000162e:	ef98                	sd	a4,24(a5)
    80001630:	6985                	lui	s3,0x1
  for(int i = 1; i <= 2; i++) {
    80001632:	6a0d                	lui	s4,0x3
    char *data_mem = kalloc();
    80001634:	862ff0ef          	jal	ra,80000696 <kalloc>
    80001638:	892a                	mv	s2,a0
    if (data_mem == 0) {
    8000163a:	c149                	beqz	a0,800016bc <userinit+0xca>
    memset(data_mem, 0, PGSIZE);  // 初始化为0
    8000163c:	6605                	lui	a2,0x1
    8000163e:	4581                	li	a1,0
    80001640:	9faff0ef          	jal	ra,8000083a <memset>
    if (mappages(p->pagetable, data_va, PGSIZE, (uint64)data_mem, PTE_R | PTE_W | PTE_U) != 0) {
    80001644:	4759                	li	a4,22
    80001646:	86ca                	mv	a3,s2
    80001648:	6605                	lui	a2,0x1
    8000164a:	85ce                	mv	a1,s3
    8000164c:	68a8                	ld	a0,80(s1)
    8000164e:	d28ff0ef          	jal	ra,80000b76 <mappages>
    80001652:	e93d                	bnez	a0,800016c8 <userinit+0xd6>
    p->sz += PGSIZE;
    80001654:	6705                	lui	a4,0x1
    80001656:	64bc                	ld	a5,72(s1)
    80001658:	97ba                	add	a5,a5,a4
    8000165a:	e4bc                	sd	a5,72(s1)
  for(int i = 1; i <= 2; i++) {
    8000165c:	99ba                	add	s3,s3,a4
    8000165e:	fd499be3          	bne	s3,s4,80001634 <userinit+0x42>
  char *stack_mem = kalloc();
    80001662:	834ff0ef          	jal	ra,80000696 <kalloc>
    80001666:	892a                	mv	s2,a0
  if (stack_mem == 0) {
    80001668:	c92d                	beqz	a0,800016da <userinit+0xe8>
  memset(stack_mem, 0, PGSIZE);
    8000166a:	6605                	lui	a2,0x1
    8000166c:	4581                	li	a1,0
    8000166e:	9ccff0ef          	jal	ra,8000083a <memset>
  if (mappages(p->pagetable, stack_va, PGSIZE, (uint64)stack_mem, PTE_R | PTE_W | PTE_U) != 0) {
    80001672:	4759                	li	a4,22
    80001674:	86ca                	mv	a3,s2
    80001676:	6605                	lui	a2,0x1
    80001678:	658d                	lui	a1,0x3
    8000167a:	68a8                	ld	a0,80(s1)
    8000167c:	cfaff0ef          	jal	ra,80000b76 <mappages>
    80001680:	e13d                	bnez	a0,800016e6 <userinit+0xf4>
  p->sz += PGSIZE;
    80001682:	64bc                	ld	a5,72(s1)
    80001684:	6705                	lui	a4,0x1
    80001686:	97ba                	add	a5,a5,a4
    80001688:	e4bc                	sd	a5,72(s1)
  p->trapframe->sp = 4 * PGSIZE;
    8000168a:	6cbc                	ld	a5,88(s1)
    8000168c:	6711                	lui	a4,0x4
    8000168e:	fb98                	sd	a4,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001690:	4641                	li	a2,16
    80001692:	00003597          	auipc	a1,0x3
    80001696:	bce58593          	addi	a1,a1,-1074 # 80004260 <digits+0x228>
    8000169a:	0d848513          	addi	a0,s1,216
    8000169e:	ae2ff0ef          	jal	ra,80000980 <safestrcpy>
  p->state = RUNNABLE;
    800016a2:	478d                	li	a5,3
    800016a4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800016a6:	8526                	mv	a0,s1
    800016a8:	956ff0ef          	jal	ra,800007fe <release>
}
    800016ac:	70a2                	ld	ra,40(sp)
    800016ae:	7402                	ld	s0,32(sp)
    800016b0:	64e2                	ld	s1,24(sp)
    800016b2:	6942                	ld	s2,16(sp)
    800016b4:	69a2                	ld	s3,8(sp)
    800016b6:	6a02                	ld	s4,0(sp)
    800016b8:	6145                	addi	sp,sp,48
    800016ba:	8082                	ret
      panic("kalloc for global data failed");
    800016bc:	00003517          	auipc	a0,0x3
    800016c0:	b2450513          	addi	a0,a0,-1244 # 800041e0 <digits+0x1a8>
    800016c4:	ad9fe0ef          	jal	ra,8000019c <panic>
      kfree(data_mem);
    800016c8:	854a                	mv	a0,s2
    800016ca:	eedfe0ef          	jal	ra,800005b6 <kfree>
      panic("mappages for global data failed");
    800016ce:	00003517          	auipc	a0,0x3
    800016d2:	b3250513          	addi	a0,a0,-1230 # 80004200 <digits+0x1c8>
    800016d6:	ac7fe0ef          	jal	ra,8000019c <panic>
    panic("kalloc for user stack failed");
    800016da:	00003517          	auipc	a0,0x3
    800016de:	b4650513          	addi	a0,a0,-1210 # 80004220 <digits+0x1e8>
    800016e2:	abbfe0ef          	jal	ra,8000019c <panic>
    kfree(stack_mem);
    800016e6:	854a                	mv	a0,s2
    800016e8:	ecffe0ef          	jal	ra,800005b6 <kfree>
    panic("mappages for user stack failed");
    800016ec:	00003517          	auipc	a0,0x3
    800016f0:	b5450513          	addi	a0,a0,-1196 # 80004240 <digits+0x208>
    800016f4:	aa9fe0ef          	jal	ra,8000019c <panic>

00000000800016f8 <growproc>:
{
    800016f8:	1101                	addi	sp,sp,-32
    800016fa:	ec06                	sd	ra,24(sp)
    800016fc:	e822                	sd	s0,16(sp)
    800016fe:	e426                	sd	s1,8(sp)
    80001700:	e04a                	sd	s2,0(sp)
    80001702:	1000                	addi	s0,sp,32
    80001704:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001706:	c8bff0ef          	jal	ra,80001390 <myproc>
    8000170a:	84aa                	mv	s1,a0
  sz = p->sz;
    8000170c:	652c                	ld	a1,72(a0)
  if(n > 0){
    8000170e:	01204c63          	bgtz	s2,80001726 <growproc+0x2e>
  } else if(n < 0){
    80001712:	02094463          	bltz	s2,8000173a <growproc+0x42>
  p->sz = sz;
    80001716:	e4ac                	sd	a1,72(s1)
  return 0;
    80001718:	4501                	li	a0,0
}
    8000171a:	60e2                	ld	ra,24(sp)
    8000171c:	6442                	ld	s0,16(sp)
    8000171e:	64a2                	ld	s1,8(sp)
    80001720:	6902                	ld	s2,0(sp)
    80001722:	6105                	addi	sp,sp,32
    80001724:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001726:	4691                	li	a3,4
    80001728:	00b90633          	add	a2,s2,a1
    8000172c:	6928                	ld	a0,80(a0)
    8000172e:	f46ff0ef          	jal	ra,80000e74 <uvmalloc>
    80001732:	85aa                	mv	a1,a0
    80001734:	f16d                	bnez	a0,80001716 <growproc+0x1e>
      return -1;
    80001736:	557d                	li	a0,-1
    80001738:	b7cd                	j	8000171a <growproc+0x22>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000173a:	00b90633          	add	a2,s2,a1
    8000173e:	6928                	ld	a0,80(a0)
    80001740:	ef0ff0ef          	jal	ra,80000e30 <uvmdealloc>
    80001744:	85aa                	mv	a1,a0
    80001746:	bfc1                	j	80001716 <growproc+0x1e>

0000000080001748 <fork>:
{
    80001748:	7179                	addi	sp,sp,-48
    8000174a:	f406                	sd	ra,40(sp)
    8000174c:	f022                	sd	s0,32(sp)
    8000174e:	ec26                	sd	s1,24(sp)
    80001750:	e84a                	sd	s2,16(sp)
    80001752:	e44e                	sd	s3,8(sp)
    80001754:	e052                	sd	s4,0(sp)
    80001756:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001758:	c39ff0ef          	jal	ra,80001390 <myproc>
    8000175c:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    8000175e:	defff0ef          	jal	ra,8000154c <allocproc>
    80001762:	c945                	beqz	a0,80001812 <fork+0xca>
    80001764:	84aa                	mv	s1,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001766:	048a3603          	ld	a2,72(s4) # 3048 <_entry-0x7fffcfb8>
    8000176a:	692c                	ld	a1,80(a0)
    8000176c:	050a3503          	ld	a0,80(s4)
    80001770:	82dff0ef          	jal	ra,80000f9c <uvmcopy>
    80001774:	08054763          	bltz	a0,80001802 <fork+0xba>
  np->sz = p->sz;
    80001778:	048a3783          	ld	a5,72(s4)
    8000177c:	e4bc                	sd	a5,72(s1)
  *(np->trapframe) = *(p->trapframe);
    8000177e:	058a3683          	ld	a3,88(s4)
    80001782:	87b6                	mv	a5,a3
    80001784:	6cb8                	ld	a4,88(s1)
    80001786:	12068693          	addi	a3,a3,288
    8000178a:	0007b803          	ld	a6,0(a5)
    8000178e:	6788                	ld	a0,8(a5)
    80001790:	6b8c                	ld	a1,16(a5)
    80001792:	6f90                	ld	a2,24(a5)
    80001794:	01073023          	sd	a6,0(a4) # 4000 <_entry-0x7fffc000>
    80001798:	e708                	sd	a0,8(a4)
    8000179a:	eb0c                	sd	a1,16(a4)
    8000179c:	ef10                	sd	a2,24(a4)
    8000179e:	02078793          	addi	a5,a5,32
    800017a2:	02070713          	addi	a4,a4,32
    800017a6:	fed792e3          	bne	a5,a3,8000178a <fork+0x42>
  np->trapframe->a0 = 0;
    800017aa:	6cbc                	ld	a5,88(s1)
    800017ac:	0607b823          	sd	zero,112(a5)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800017b0:	4641                	li	a2,16
    800017b2:	0d8a0593          	addi	a1,s4,216
    800017b6:	0d848513          	addi	a0,s1,216
    800017ba:	9c6ff0ef          	jal	ra,80000980 <safestrcpy>
  pid = np->pid;
    800017be:	0304a983          	lw	s3,48(s1)
  release(&np->lock);
    800017c2:	8526                	mv	a0,s1
    800017c4:	83aff0ef          	jal	ra,800007fe <release>
  acquire(&wait_lock);
    800017c8:	0000c917          	auipc	s2,0xc
    800017cc:	ab890913          	addi	s2,s2,-1352 # 8000d280 <wait_lock>
    800017d0:	854a                	mv	a0,s2
    800017d2:	f95fe0ef          	jal	ra,80000766 <acquire>
  np->parent = p;
    800017d6:	0344bc23          	sd	s4,56(s1)
  release(&wait_lock);
    800017da:	854a                	mv	a0,s2
    800017dc:	822ff0ef          	jal	ra,800007fe <release>
  acquire(&np->lock);
    800017e0:	8526                	mv	a0,s1
    800017e2:	f85fe0ef          	jal	ra,80000766 <acquire>
  np->state = RUNNABLE;
    800017e6:	478d                	li	a5,3
    800017e8:	cc9c                	sw	a5,24(s1)
  release(&np->lock);
    800017ea:	8526                	mv	a0,s1
    800017ec:	812ff0ef          	jal	ra,800007fe <release>
}
    800017f0:	854e                	mv	a0,s3
    800017f2:	70a2                	ld	ra,40(sp)
    800017f4:	7402                	ld	s0,32(sp)
    800017f6:	64e2                	ld	s1,24(sp)
    800017f8:	6942                	ld	s2,16(sp)
    800017fa:	69a2                	ld	s3,8(sp)
    800017fc:	6a02                	ld	s4,0(sp)
    800017fe:	6145                	addi	sp,sp,48
    80001800:	8082                	ret
    freeproc(np);
    80001802:	8526                	mv	a0,s1
    80001804:	cf9ff0ef          	jal	ra,800014fc <freeproc>
    release(&np->lock);
    80001808:	8526                	mv	a0,s1
    8000180a:	ff5fe0ef          	jal	ra,800007fe <release>
    return -1;
    8000180e:	59fd                	li	s3,-1
    80001810:	b7c5                	j	800017f0 <fork+0xa8>
    return -1;
    80001812:	59fd                	li	s3,-1
    80001814:	bff1                	j	800017f0 <fork+0xa8>

0000000080001816 <scheduler>:
{
    80001816:	7139                	addi	sp,sp,-64
    80001818:	fc06                	sd	ra,56(sp)
    8000181a:	f822                	sd	s0,48(sp)
    8000181c:	f426                	sd	s1,40(sp)
    8000181e:	f04a                	sd	s2,32(sp)
    80001820:	ec4e                	sd	s3,24(sp)
    80001822:	e852                	sd	s4,16(sp)
    80001824:	e456                	sd	s5,8(sp)
    80001826:	e05a                	sd	s6,0(sp)
    80001828:	0080                	addi	s0,sp,64
    8000182a:	8792                	mv	a5,tp
  int id = r_tp();
    8000182c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000182e:	00779a93          	slli	s5,a5,0x7
    80001832:	0000c717          	auipc	a4,0xc
    80001836:	a3670713          	addi	a4,a4,-1482 # 8000d268 <pid_lock>
    8000183a:	9756                	add	a4,a4,s5
    8000183c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001840:	0000c717          	auipc	a4,0xc
    80001844:	a6070713          	addi	a4,a4,-1440 # 8000d2a0 <cpus+0x8>
    80001848:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000184a:	498d                	li	s3,3
        p->state = RUNNING;
    8000184c:	4b11                	li	s6,4
        c->proc = p;
    8000184e:	079e                	slli	a5,a5,0x7
    80001850:	0000ca17          	auipc	s4,0xc
    80001854:	a18a0a13          	addi	s4,s4,-1512 # 8000d268 <pid_lock>
    80001858:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000185a:	00010917          	auipc	s2,0x10
    8000185e:	83e90913          	addi	s2,s2,-1986 # 80011098 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001862:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001866:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000186a:	10079073          	csrw	sstatus,a5
    8000186e:	0000c497          	auipc	s1,0xc
    80001872:	e2a48493          	addi	s1,s1,-470 # 8000d698 <proc>
    80001876:	a801                	j	80001886 <scheduler+0x70>
      release(&p->lock);
    80001878:	8526                	mv	a0,s1
    8000187a:	f85fe0ef          	jal	ra,800007fe <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000187e:	0e848493          	addi	s1,s1,232
    80001882:	ff2480e3          	beq	s1,s2,80001862 <scheduler+0x4c>
      acquire(&p->lock);
    80001886:	8526                	mv	a0,s1
    80001888:	edffe0ef          	jal	ra,80000766 <acquire>
      if(p->state == RUNNABLE) {
    8000188c:	4c9c                	lw	a5,24(s1)
    8000188e:	ff3795e3          	bne	a5,s3,80001878 <scheduler+0x62>
        p->state = RUNNING;
    80001892:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001896:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000189a:	06048593          	addi	a1,s1,96
    8000189e:	8556                	mv	a0,s5
    800018a0:	470000ef          	jal	ra,80001d10 <swtch>
        c->proc = 0;
    800018a4:	020a3823          	sd	zero,48(s4)
    800018a8:	bfc1                	j	80001878 <scheduler+0x62>

00000000800018aa <sched>:
{
    800018aa:	7179                	addi	sp,sp,-48
    800018ac:	f406                	sd	ra,40(sp)
    800018ae:	f022                	sd	s0,32(sp)
    800018b0:	ec26                	sd	s1,24(sp)
    800018b2:	e84a                	sd	s2,16(sp)
    800018b4:	e44e                	sd	s3,8(sp)
    800018b6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800018b8:	ad9ff0ef          	jal	ra,80001390 <myproc>
    800018bc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018be:	e3ffe0ef          	jal	ra,800006fc <holding>
    800018c2:	c92d                	beqz	a0,80001934 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    800018c4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800018c6:	2781                	sext.w	a5,a5
    800018c8:	079e                	slli	a5,a5,0x7
    800018ca:	0000c717          	auipc	a4,0xc
    800018ce:	99e70713          	addi	a4,a4,-1634 # 8000d268 <pid_lock>
    800018d2:	97ba                	add	a5,a5,a4
    800018d4:	0a87a703          	lw	a4,168(a5)
    800018d8:	4785                	li	a5,1
    800018da:	06f71363          	bne	a4,a5,80001940 <sched+0x96>
  if(p->state == RUNNING)
    800018de:	4c98                	lw	a4,24(s1)
    800018e0:	4791                	li	a5,4
    800018e2:	06f70563          	beq	a4,a5,8000194c <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800018e6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800018ea:	8b89                	andi	a5,a5,2
  if(intr_get())
    800018ec:	e7b5                	bnez	a5,80001958 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    800018ee:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800018f0:	0000c917          	auipc	s2,0xc
    800018f4:	97890913          	addi	s2,s2,-1672 # 8000d268 <pid_lock>
    800018f8:	2781                	sext.w	a5,a5
    800018fa:	079e                	slli	a5,a5,0x7
    800018fc:	97ca                	add	a5,a5,s2
    800018fe:	0ac7a983          	lw	s3,172(a5)
    80001902:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001904:	2781                	sext.w	a5,a5
    80001906:	079e                	slli	a5,a5,0x7
    80001908:	0000c597          	auipc	a1,0xc
    8000190c:	99858593          	addi	a1,a1,-1640 # 8000d2a0 <cpus+0x8>
    80001910:	95be                	add	a1,a1,a5
    80001912:	06048513          	addi	a0,s1,96
    80001916:	3fa000ef          	jal	ra,80001d10 <swtch>
    8000191a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000191c:	2781                	sext.w	a5,a5
    8000191e:	079e                	slli	a5,a5,0x7
    80001920:	97ca                	add	a5,a5,s2
    80001922:	0b37a623          	sw	s3,172(a5)
}
    80001926:	70a2                	ld	ra,40(sp)
    80001928:	7402                	ld	s0,32(sp)
    8000192a:	64e2                	ld	s1,24(sp)
    8000192c:	6942                	ld	s2,16(sp)
    8000192e:	69a2                	ld	s3,8(sp)
    80001930:	6145                	addi	sp,sp,48
    80001932:	8082                	ret
    panic("sched p->lock");
    80001934:	00003517          	auipc	a0,0x3
    80001938:	93c50513          	addi	a0,a0,-1732 # 80004270 <digits+0x238>
    8000193c:	861fe0ef          	jal	ra,8000019c <panic>
    panic("sched locks");
    80001940:	00003517          	auipc	a0,0x3
    80001944:	94050513          	addi	a0,a0,-1728 # 80004280 <digits+0x248>
    80001948:	855fe0ef          	jal	ra,8000019c <panic>
    panic("sched running");
    8000194c:	00003517          	auipc	a0,0x3
    80001950:	94450513          	addi	a0,a0,-1724 # 80004290 <digits+0x258>
    80001954:	849fe0ef          	jal	ra,8000019c <panic>
    panic("sched interruptible");
    80001958:	00003517          	auipc	a0,0x3
    8000195c:	94850513          	addi	a0,a0,-1720 # 800042a0 <digits+0x268>
    80001960:	83dfe0ef          	jal	ra,8000019c <panic>

0000000080001964 <yield>:
{
    80001964:	1101                	addi	sp,sp,-32
    80001966:	ec06                	sd	ra,24(sp)
    80001968:	e822                	sd	s0,16(sp)
    8000196a:	e426                	sd	s1,8(sp)
    8000196c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000196e:	a23ff0ef          	jal	ra,80001390 <myproc>
    80001972:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001974:	df3fe0ef          	jal	ra,80000766 <acquire>
  p->state = RUNNABLE;
    80001978:	478d                	li	a5,3
    8000197a:	cc9c                	sw	a5,24(s1)
  sched();
    8000197c:	f2fff0ef          	jal	ra,800018aa <sched>
  release(&p->lock);
    80001980:	8526                	mv	a0,s1
    80001982:	e7dfe0ef          	jal	ra,800007fe <release>
}
    80001986:	60e2                	ld	ra,24(sp)
    80001988:	6442                	ld	s0,16(sp)
    8000198a:	64a2                	ld	s1,8(sp)
    8000198c:	6105                	addi	sp,sp,32
    8000198e:	8082                	ret

0000000080001990 <sleep>:

// // Atomically release lock and sleep on chan.
// // Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001990:	7179                	addi	sp,sp,-48
    80001992:	f406                	sd	ra,40(sp)
    80001994:	f022                	sd	s0,32(sp)
    80001996:	ec26                	sd	s1,24(sp)
    80001998:	e84a                	sd	s2,16(sp)
    8000199a:	e44e                	sd	s3,8(sp)
    8000199c:	1800                	addi	s0,sp,48
    8000199e:	89aa                	mv	s3,a0
    800019a0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800019a2:	9efff0ef          	jal	ra,80001390 <myproc>
    800019a6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800019a8:	dbffe0ef          	jal	ra,80000766 <acquire>
  release(lk);
    800019ac:	854a                	mv	a0,s2
    800019ae:	e51fe0ef          	jal	ra,800007fe <release>

  // Go to sleep.
  p->chan = chan;
    800019b2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800019b6:	4789                	li	a5,2
    800019b8:	cc9c                	sw	a5,24(s1)

  sched();
    800019ba:	ef1ff0ef          	jal	ra,800018aa <sched>

  // Tidy up.
  p->chan = 0;
    800019be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800019c2:	8526                	mv	a0,s1
    800019c4:	e3bfe0ef          	jal	ra,800007fe <release>
  acquire(lk);
    800019c8:	854a                	mv	a0,s2
    800019ca:	d9dfe0ef          	jal	ra,80000766 <acquire>
}
    800019ce:	70a2                	ld	ra,40(sp)
    800019d0:	7402                	ld	s0,32(sp)
    800019d2:	64e2                	ld	s1,24(sp)
    800019d4:	6942                	ld	s2,16(sp)
    800019d6:	69a2                	ld	s3,8(sp)
    800019d8:	6145                	addi	sp,sp,48
    800019da:	8082                	ret

00000000800019dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800019dc:	7139                	addi	sp,sp,-64
    800019de:	fc06                	sd	ra,56(sp)
    800019e0:	f822                	sd	s0,48(sp)
    800019e2:	f426                	sd	s1,40(sp)
    800019e4:	f04a                	sd	s2,32(sp)
    800019e6:	ec4e                	sd	s3,24(sp)
    800019e8:	e852                	sd	s4,16(sp)
    800019ea:	e456                	sd	s5,8(sp)
    800019ec:	0080                	addi	s0,sp,64
    800019ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800019f0:	0000c497          	auipc	s1,0xc
    800019f4:	ca848493          	addi	s1,s1,-856 # 8000d698 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800019f8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800019fa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800019fc:	0000f917          	auipc	s2,0xf
    80001a00:	69c90913          	addi	s2,s2,1692 # 80011098 <tickslock>
    80001a04:	a801                	j	80001a14 <wakeup+0x38>
      }
      release(&p->lock);
    80001a06:	8526                	mv	a0,s1
    80001a08:	df7fe0ef          	jal	ra,800007fe <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a0c:	0e848493          	addi	s1,s1,232
    80001a10:	03248263          	beq	s1,s2,80001a34 <wakeup+0x58>
    if(p != myproc()){
    80001a14:	97dff0ef          	jal	ra,80001390 <myproc>
    80001a18:	fea48ae3          	beq	s1,a0,80001a0c <wakeup+0x30>
      acquire(&p->lock);
    80001a1c:	8526                	mv	a0,s1
    80001a1e:	d49fe0ef          	jal	ra,80000766 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001a22:	4c9c                	lw	a5,24(s1)
    80001a24:	ff3791e3          	bne	a5,s3,80001a06 <wakeup+0x2a>
    80001a28:	709c                	ld	a5,32(s1)
    80001a2a:	fd479ee3          	bne	a5,s4,80001a06 <wakeup+0x2a>
        p->state = RUNNABLE;
    80001a2e:	0154ac23          	sw	s5,24(s1)
    80001a32:	bfd1                	j	80001a06 <wakeup+0x2a>
    }
  }
}
    80001a34:	70e2                	ld	ra,56(sp)
    80001a36:	7442                	ld	s0,48(sp)
    80001a38:	74a2                	ld	s1,40(sp)
    80001a3a:	7902                	ld	s2,32(sp)
    80001a3c:	69e2                	ld	s3,24(sp)
    80001a3e:	6a42                	ld	s4,16(sp)
    80001a40:	6aa2                	ld	s5,8(sp)
    80001a42:	6121                	addi	sp,sp,64
    80001a44:	8082                	ret

0000000080001a46 <reparent>:
{
    80001a46:	7179                	addi	sp,sp,-48
    80001a48:	f406                	sd	ra,40(sp)
    80001a4a:	f022                	sd	s0,32(sp)
    80001a4c:	ec26                	sd	s1,24(sp)
    80001a4e:	e84a                	sd	s2,16(sp)
    80001a50:	e44e                	sd	s3,8(sp)
    80001a52:	e052                	sd	s4,0(sp)
    80001a54:	1800                	addi	s0,sp,48
    80001a56:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001a58:	0000c497          	auipc	s1,0xc
    80001a5c:	c4048493          	addi	s1,s1,-960 # 8000d698 <proc>
      pp->parent = initproc;
    80001a60:	00003a17          	auipc	s4,0x3
    80001a64:	638a0a13          	addi	s4,s4,1592 # 80005098 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001a68:	0000f997          	auipc	s3,0xf
    80001a6c:	63098993          	addi	s3,s3,1584 # 80011098 <tickslock>
    80001a70:	a029                	j	80001a7a <reparent+0x34>
    80001a72:	0e848493          	addi	s1,s1,232
    80001a76:	01348b63          	beq	s1,s3,80001a8c <reparent+0x46>
    if(pp->parent == p){
    80001a7a:	7c9c                	ld	a5,56(s1)
    80001a7c:	ff279be3          	bne	a5,s2,80001a72 <reparent+0x2c>
      pp->parent = initproc;
    80001a80:	000a3503          	ld	a0,0(s4)
    80001a84:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80001a86:	f57ff0ef          	jal	ra,800019dc <wakeup>
    80001a8a:	b7e5                	j	80001a72 <reparent+0x2c>
}
    80001a8c:	70a2                	ld	ra,40(sp)
    80001a8e:	7402                	ld	s0,32(sp)
    80001a90:	64e2                	ld	s1,24(sp)
    80001a92:	6942                	ld	s2,16(sp)
    80001a94:	69a2                	ld	s3,8(sp)
    80001a96:	6a02                	ld	s4,0(sp)
    80001a98:	6145                	addi	sp,sp,48
    80001a9a:	8082                	ret

0000000080001a9c <exit>:
{
    80001a9c:	7179                	addi	sp,sp,-48
    80001a9e:	f406                	sd	ra,40(sp)
    80001aa0:	f022                	sd	s0,32(sp)
    80001aa2:	ec26                	sd	s1,24(sp)
    80001aa4:	e84a                	sd	s2,16(sp)
    80001aa6:	e44e                	sd	s3,8(sp)
    80001aa8:	1800                	addi	s0,sp,48
    80001aaa:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001aac:	8e5ff0ef          	jal	ra,80001390 <myproc>
  if(p == initproc)
    80001ab0:	00003797          	auipc	a5,0x3
    80001ab4:	5e87b783          	ld	a5,1512(a5) # 80005098 <initproc>
    80001ab8:	04a78a63          	beq	a5,a0,80001b0c <exit+0x70>
    80001abc:	84aa                	mv	s1,a0
  p->cwd = 0;
    80001abe:	0c053823          	sd	zero,208(a0)
  acquire(&wait_lock);
    80001ac2:	0000b997          	auipc	s3,0xb
    80001ac6:	7be98993          	addi	s3,s3,1982 # 8000d280 <wait_lock>
    80001aca:	854e                	mv	a0,s3
    80001acc:	c9bfe0ef          	jal	ra,80000766 <acquire>
  reparent(p);
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	f75ff0ef          	jal	ra,80001a46 <reparent>
  release(&wait_lock);
    80001ad6:	854e                	mv	a0,s3
    80001ad8:	d27fe0ef          	jal	ra,800007fe <release>
  wakeup(initproc);
    80001adc:	00003517          	auipc	a0,0x3
    80001ae0:	5bc53503          	ld	a0,1468(a0) # 80005098 <initproc>
    80001ae4:	ef9ff0ef          	jal	ra,800019dc <wakeup>
  wakeup(p->parent);
    80001ae8:	7c88                	ld	a0,56(s1)
    80001aea:	ef3ff0ef          	jal	ra,800019dc <wakeup>
  acquire(&p->lock);
    80001aee:	8526                	mv	a0,s1
    80001af0:	c77fe0ef          	jal	ra,80000766 <acquire>
  p->xstate = status;
    80001af4:	0324a623          	sw	s2,44(s1)
  p->state = ZOMBIE;
    80001af8:	4795                	li	a5,5
    80001afa:	cc9c                	sw	a5,24(s1)
  sched();
    80001afc:	dafff0ef          	jal	ra,800018aa <sched>
  panic("zombie exit");
    80001b00:	00002517          	auipc	a0,0x2
    80001b04:	7c850513          	addi	a0,a0,1992 # 800042c8 <digits+0x290>
    80001b08:	e94fe0ef          	jal	ra,8000019c <panic>
    panic("init exiting");
    80001b0c:	00002517          	auipc	a0,0x2
    80001b10:	7ac50513          	addi	a0,a0,1964 # 800042b8 <digits+0x280>
    80001b14:	e88fe0ef          	jal	ra,8000019c <panic>

0000000080001b18 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80001b18:	7179                	addi	sp,sp,-48
    80001b1a:	f406                	sd	ra,40(sp)
    80001b1c:	f022                	sd	s0,32(sp)
    80001b1e:	ec26                	sd	s1,24(sp)
    80001b20:	e84a                	sd	s2,16(sp)
    80001b22:	e44e                	sd	s3,8(sp)
    80001b24:	1800                	addi	s0,sp,48
    80001b26:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80001b28:	0000c497          	auipc	s1,0xc
    80001b2c:	b7048493          	addi	s1,s1,-1168 # 8000d698 <proc>
    80001b30:	0000f997          	auipc	s3,0xf
    80001b34:	56898993          	addi	s3,s3,1384 # 80011098 <tickslock>
    acquire(&p->lock);
    80001b38:	8526                	mv	a0,s1
    80001b3a:	c2dfe0ef          	jal	ra,80000766 <acquire>
    if(p->pid == pid){
    80001b3e:	589c                	lw	a5,48(s1)
    80001b40:	01278b63          	beq	a5,s2,80001b56 <kill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80001b44:	8526                	mv	a0,s1
    80001b46:	cb9fe0ef          	jal	ra,800007fe <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001b4a:	0e848493          	addi	s1,s1,232
    80001b4e:	ff3495e3          	bne	s1,s3,80001b38 <kill+0x20>
  }
  return -1;
    80001b52:	557d                	li	a0,-1
    80001b54:	a819                	j	80001b6a <kill+0x52>
      p->killed = 1;
    80001b56:	4785                	li	a5,1
    80001b58:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80001b5a:	4c98                	lw	a4,24(s1)
    80001b5c:	4789                	li	a5,2
    80001b5e:	00f70d63          	beq	a4,a5,80001b78 <kill+0x60>
      release(&p->lock);
    80001b62:	8526                	mv	a0,s1
    80001b64:	c9bfe0ef          	jal	ra,800007fe <release>
      return 0;
    80001b68:	4501                	li	a0,0
}
    80001b6a:	70a2                	ld	ra,40(sp)
    80001b6c:	7402                	ld	s0,32(sp)
    80001b6e:	64e2                	ld	s1,24(sp)
    80001b70:	6942                	ld	s2,16(sp)
    80001b72:	69a2                	ld	s3,8(sp)
    80001b74:	6145                	addi	sp,sp,48
    80001b76:	8082                	ret
        p->state = RUNNABLE;
    80001b78:	478d                	li	a5,3
    80001b7a:	cc9c                	sw	a5,24(s1)
    80001b7c:	b7dd                	j	80001b62 <kill+0x4a>

0000000080001b7e <setkilled>:

void
setkilled(struct proc *p)
{
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	1000                	addi	s0,sp,32
    80001b88:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001b8a:	bddfe0ef          	jal	ra,80000766 <acquire>
  p->killed = 1;
    80001b8e:	4785                	li	a5,1
    80001b90:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80001b92:	8526                	mv	a0,s1
    80001b94:	c6bfe0ef          	jal	ra,800007fe <release>
}
    80001b98:	60e2                	ld	ra,24(sp)
    80001b9a:	6442                	ld	s0,16(sp)
    80001b9c:	64a2                	ld	s1,8(sp)
    80001b9e:	6105                	addi	sp,sp,32
    80001ba0:	8082                	ret

0000000080001ba2 <killed>:

int
killed(struct proc *p)
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	e04a                	sd	s2,0(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80001bb0:	bb7fe0ef          	jal	ra,80000766 <acquire>
  k = p->killed;
    80001bb4:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80001bb8:	8526                	mv	a0,s1
    80001bba:	c45fe0ef          	jal	ra,800007fe <release>
  return k;
}
    80001bbe:	854a                	mv	a0,s2
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6902                	ld	s2,0(sp)
    80001bc8:	6105                	addi	sp,sp,32
    80001bca:	8082                	ret

0000000080001bcc <wait>:
{
    80001bcc:	715d                	addi	sp,sp,-80
    80001bce:	e486                	sd	ra,72(sp)
    80001bd0:	e0a2                	sd	s0,64(sp)
    80001bd2:	fc26                	sd	s1,56(sp)
    80001bd4:	f84a                	sd	s2,48(sp)
    80001bd6:	f44e                	sd	s3,40(sp)
    80001bd8:	f052                	sd	s4,32(sp)
    80001bda:	ec56                	sd	s5,24(sp)
    80001bdc:	e85a                	sd	s6,16(sp)
    80001bde:	e45e                	sd	s7,8(sp)
    80001be0:	e062                	sd	s8,0(sp)
    80001be2:	0880                	addi	s0,sp,80
    80001be4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80001be6:	faaff0ef          	jal	ra,80001390 <myproc>
    80001bea:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80001bec:	0000b517          	auipc	a0,0xb
    80001bf0:	69450513          	addi	a0,a0,1684 # 8000d280 <wait_lock>
    80001bf4:	b73fe0ef          	jal	ra,80000766 <acquire>
    havekids = 0;
    80001bf8:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80001bfa:	4a15                	li	s4,5
        havekids = 1;
    80001bfc:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001bfe:	0000f997          	auipc	s3,0xf
    80001c02:	49a98993          	addi	s3,s3,1178 # 80011098 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80001c06:	0000bc17          	auipc	s8,0xb
    80001c0a:	67ac0c13          	addi	s8,s8,1658 # 8000d280 <wait_lock>
    havekids = 0;
    80001c0e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001c10:	0000c497          	auipc	s1,0xc
    80001c14:	a8848493          	addi	s1,s1,-1400 # 8000d698 <proc>
    80001c18:	a899                	j	80001c6e <wait+0xa2>
          pid = pp->pid;
    80001c1a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80001c1e:	000b0c63          	beqz	s6,80001c36 <wait+0x6a>
    80001c22:	4691                	li	a3,4
    80001c24:	02c48613          	addi	a2,s1,44
    80001c28:	85da                	mv	a1,s6
    80001c2a:	05093503          	ld	a0,80(s2)
    80001c2e:	c4aff0ef          	jal	ra,80001078 <copyout>
    80001c32:	00054f63          	bltz	a0,80001c50 <wait+0x84>
          freeproc(pp);
    80001c36:	8526                	mv	a0,s1
    80001c38:	8c5ff0ef          	jal	ra,800014fc <freeproc>
          release(&pp->lock);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	bc1fe0ef          	jal	ra,800007fe <release>
          release(&wait_lock);
    80001c42:	0000b517          	auipc	a0,0xb
    80001c46:	63e50513          	addi	a0,a0,1598 # 8000d280 <wait_lock>
    80001c4a:	bb5fe0ef          	jal	ra,800007fe <release>
          return pid;
    80001c4e:	a891                	j	80001ca2 <wait+0xd6>
            release(&pp->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	badfe0ef          	jal	ra,800007fe <release>
            release(&wait_lock);
    80001c56:	0000b517          	auipc	a0,0xb
    80001c5a:	62a50513          	addi	a0,a0,1578 # 8000d280 <wait_lock>
    80001c5e:	ba1fe0ef          	jal	ra,800007fe <release>
            return -1;
    80001c62:	59fd                	li	s3,-1
    80001c64:	a83d                	j	80001ca2 <wait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001c66:	0e848493          	addi	s1,s1,232
    80001c6a:	03348063          	beq	s1,s3,80001c8a <wait+0xbe>
      if(pp->parent == p){
    80001c6e:	7c9c                	ld	a5,56(s1)
    80001c70:	ff279be3          	bne	a5,s2,80001c66 <wait+0x9a>
        acquire(&pp->lock);
    80001c74:	8526                	mv	a0,s1
    80001c76:	af1fe0ef          	jal	ra,80000766 <acquire>
        if(pp->state == ZOMBIE){
    80001c7a:	4c9c                	lw	a5,24(s1)
    80001c7c:	f9478fe3          	beq	a5,s4,80001c1a <wait+0x4e>
        release(&pp->lock);
    80001c80:	8526                	mv	a0,s1
    80001c82:	b7dfe0ef          	jal	ra,800007fe <release>
        havekids = 1;
    80001c86:	8756                	mv	a4,s5
    80001c88:	bff9                	j	80001c66 <wait+0x9a>
    if(!havekids || killed(p)){
    80001c8a:	c709                	beqz	a4,80001c94 <wait+0xc8>
    80001c8c:	854a                	mv	a0,s2
    80001c8e:	f15ff0ef          	jal	ra,80001ba2 <killed>
    80001c92:	c50d                	beqz	a0,80001cbc <wait+0xf0>
      release(&wait_lock);
    80001c94:	0000b517          	auipc	a0,0xb
    80001c98:	5ec50513          	addi	a0,a0,1516 # 8000d280 <wait_lock>
    80001c9c:	b63fe0ef          	jal	ra,800007fe <release>
      return -1;
    80001ca0:	59fd                	li	s3,-1
}
    80001ca2:	854e                	mv	a0,s3
    80001ca4:	60a6                	ld	ra,72(sp)
    80001ca6:	6406                	ld	s0,64(sp)
    80001ca8:	74e2                	ld	s1,56(sp)
    80001caa:	7942                	ld	s2,48(sp)
    80001cac:	79a2                	ld	s3,40(sp)
    80001cae:	7a02                	ld	s4,32(sp)
    80001cb0:	6ae2                	ld	s5,24(sp)
    80001cb2:	6b42                	ld	s6,16(sp)
    80001cb4:	6ba2                	ld	s7,8(sp)
    80001cb6:	6c02                	ld	s8,0(sp)
    80001cb8:	6161                	addi	sp,sp,80
    80001cba:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80001cbc:	85e2                	mv	a1,s8
    80001cbe:	854a                	mv	a0,s2
    80001cc0:	cd1ff0ef          	jal	ra,80001990 <sleep>
    havekids = 0;
    80001cc4:	b7a9                	j	80001c0e <wait+0x42>

0000000080001cc6 <either_copyin>:
// // Copy from either a user address, or kernel address,
// // depending on usr_src.
// // Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80001cc6:	7179                	addi	sp,sp,-48
    80001cc8:	f406                	sd	ra,40(sp)
    80001cca:	f022                	sd	s0,32(sp)
    80001ccc:	ec26                	sd	s1,24(sp)
    80001cce:	e84a                	sd	s2,16(sp)
    80001cd0:	e44e                	sd	s3,8(sp)
    80001cd2:	e052                	sd	s4,0(sp)
    80001cd4:	1800                	addi	s0,sp,48
    80001cd6:	892a                	mv	s2,a0
    80001cd8:	84ae                	mv	s1,a1
    80001cda:	89b2                	mv	s3,a2
    80001cdc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001cde:	eb2ff0ef          	jal	ra,80001390 <myproc>
  if(user_src){
    80001ce2:	cc99                	beqz	s1,80001d00 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80001ce4:	86d2                	mv	a3,s4
    80001ce6:	864e                	mv	a2,s3
    80001ce8:	85ca                	mv	a1,s2
    80001cea:	6928                	ld	a0,80(a0)
    80001cec:	c10ff0ef          	jal	ra,800010fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80001cf0:	70a2                	ld	ra,40(sp)
    80001cf2:	7402                	ld	s0,32(sp)
    80001cf4:	64e2                	ld	s1,24(sp)
    80001cf6:	6942                	ld	s2,16(sp)
    80001cf8:	69a2                	ld	s3,8(sp)
    80001cfa:	6a02                	ld	s4,0(sp)
    80001cfc:	6145                	addi	sp,sp,48
    80001cfe:	8082                	ret
    memmove(dst, (char*)src, len);
    80001d00:	000a061b          	sext.w	a2,s4
    80001d04:	85ce                	mv	a1,s3
    80001d06:	854a                	mv	a0,s2
    80001d08:	b8ffe0ef          	jal	ra,80000896 <memmove>
    return 0;
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	b7cd                	j	80001cf0 <either_copyin+0x2a>

0000000080001d10 <swtch>:
    80001d10:	00153023          	sd	ra,0(a0)
    80001d14:	00253423          	sd	sp,8(a0)
    80001d18:	e900                	sd	s0,16(a0)
    80001d1a:	ed04                	sd	s1,24(a0)
    80001d1c:	03253023          	sd	s2,32(a0)
    80001d20:	03353423          	sd	s3,40(a0)
    80001d24:	03453823          	sd	s4,48(a0)
    80001d28:	03553c23          	sd	s5,56(a0)
    80001d2c:	05653023          	sd	s6,64(a0)
    80001d30:	05753423          	sd	s7,72(a0)
    80001d34:	05853823          	sd	s8,80(a0)
    80001d38:	05953c23          	sd	s9,88(a0)
    80001d3c:	07a53023          	sd	s10,96(a0)
    80001d40:	07b53423          	sd	s11,104(a0)
    80001d44:	0005b083          	ld	ra,0(a1)
    80001d48:	0085b103          	ld	sp,8(a1)
    80001d4c:	6980                	ld	s0,16(a1)
    80001d4e:	6d84                	ld	s1,24(a1)
    80001d50:	0205b903          	ld	s2,32(a1)
    80001d54:	0285b983          	ld	s3,40(a1)
    80001d58:	0305ba03          	ld	s4,48(a1)
    80001d5c:	0385ba83          	ld	s5,56(a1)
    80001d60:	0405bb03          	ld	s6,64(a1)
    80001d64:	0485bb83          	ld	s7,72(a1)
    80001d68:	0505bc03          	ld	s8,80(a1)
    80001d6c:	0585bc83          	ld	s9,88(a1)
    80001d70:	0605bd03          	ld	s10,96(a1)
    80001d74:	0685bd83          	ld	s11,104(a1)
    80001d78:	8082                	ret

0000000080001d7a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80001d7a:	1141                	addi	sp,sp,-16
    80001d7c:	e406                	sd	ra,8(sp)
    80001d7e:	e022                	sd	s0,0(sp)
    80001d80:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80001d82:	00002597          	auipc	a1,0x2
    80001d86:	55658593          	addi	a1,a1,1366 # 800042d8 <digits+0x2a0>
    80001d8a:	0000f517          	auipc	a0,0xf
    80001d8e:	30e50513          	addi	a0,a0,782 # 80011098 <tickslock>
    80001d92:	955fe0ef          	jal	ra,800006e6 <initlock>
}
    80001d96:	60a2                	ld	ra,8(sp)
    80001d98:	6402                	ld	s0,0(sp)
    80001d9a:	0141                	addi	sp,sp,16
    80001d9c:	8082                	ret

0000000080001d9e <trapinithart>:

void
trapinithart(void)
{
    80001d9e:	1141                	addi	sp,sp,-16
    80001da0:	e422                	sd	s0,8(sp)
    80001da2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001da4:	00000797          	auipc	a5,0x0
    80001da8:	63c78793          	addi	a5,a5,1596 # 800023e0 <kernelvec>
    80001dac:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80001db0:	6422                	ld	s0,8(sp)
    80001db2:	0141                	addi	sp,sp,16
    80001db4:	8082                	ret

0000000080001db6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80001db6:	1141                	addi	sp,sp,-16
    80001db8:	e406                	sd	ra,8(sp)
    80001dba:	e022                	sd	s0,0(sp)
    80001dbc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001dbe:	dd2ff0ef          	jal	ra,80001390 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001dc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001dc6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001dc8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80001dcc:	00001617          	auipc	a2,0x1
    80001dd0:	23460613          	addi	a2,a2,564 # 80003000 <_trampoline>
    80001dd4:	00001697          	auipc	a3,0x1
    80001dd8:	22c68693          	addi	a3,a3,556 # 80003000 <_trampoline>
    80001ddc:	8e91                	sub	a3,a3,a2
    80001dde:	040007b7          	lui	a5,0x4000
    80001de2:	17fd                	addi	a5,a5,-1
    80001de4:	07b2                	slli	a5,a5,0xc
    80001de6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001de8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80001dec:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80001dee:	180026f3          	csrr	a3,satp
    80001df2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80001df4:	6d38                	ld	a4,88(a0)
    80001df6:	6134                	ld	a3,64(a0)
    80001df8:	6585                	lui	a1,0x1
    80001dfa:	96ae                	add	a3,a3,a1
    80001dfc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80001dfe:	6d38                	ld	a4,88(a0)
    80001e00:	00000697          	auipc	a3,0x0
    80001e04:	12e68693          	addi	a3,a3,302 # 80001f2e <usertrap>
    80001e08:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80001e0a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e0c:	8692                	mv	a3,tp
    80001e0e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e10:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80001e14:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80001e18:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e1c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80001e20:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001e22:	6f18                	ld	a4,24(a4)
    80001e24:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80001e28:	6928                	ld	a0,80(a0)
    80001e2a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001e2c:	00001717          	auipc	a4,0x1
    80001e30:	27070713          	addi	a4,a4,624 # 8000309c <userret>
    80001e34:	8f11                	sub	a4,a4,a2
    80001e36:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001e38:	577d                	li	a4,-1
    80001e3a:	177e                	slli	a4,a4,0x3f
    80001e3c:	8d59                	or	a0,a0,a4
    80001e3e:	9782                	jalr	a5
}
    80001e40:	60a2                	ld	ra,8(sp)
    80001e42:	6402                	ld	s0,0(sp)
    80001e44:	0141                	addi	sp,sp,16
    80001e46:	8082                	ret

0000000080001e48 <clockintr>:
}
 // 新增：定时器中断计数器
 uint timer_interrupt_count = 0; 
void
clockintr()
{
    80001e48:	1141                	addi	sp,sp,-16
    80001e4a:	e406                	sd	ra,8(sp)
    80001e4c:	e022                	sd	s0,0(sp)
    80001e4e:	0800                	addi	s0,sp,16
  acquire(&tickslock);
    80001e50:	0000f517          	auipc	a0,0xf
    80001e54:	24850513          	addi	a0,a0,584 # 80011098 <tickslock>
    80001e58:	90ffe0ef          	jal	ra,80000766 <acquire>
  ticks++;
    80001e5c:	00003717          	auipc	a4,0x3
    80001e60:	24870713          	addi	a4,a4,584 # 800050a4 <ticks>
    80001e64:	431c                	lw	a5,0(a4)
    80001e66:	2785                	addiw	a5,a5,1
    80001e68:	c31c                	sw	a5,0(a4)
 
  // 新增：处理定时器中断计数
  timer_interrupt_count++;
    80001e6a:	00003717          	auipc	a4,0x3
    80001e6e:	23670713          	addi	a4,a4,566 # 800050a0 <timer_interrupt_count>
    80001e72:	431c                	lw	a5,0(a4)
    80001e74:	2785                	addiw	a5,a5,1
    80001e76:	c31c                	sw	a5,0(a4)
  if (timer_interrupt_count % 30 == 0) {
    80001e78:	4779                	li	a4,30
    80001e7a:	02e7f7bb          	remuw	a5,a5,a4
    80001e7e:	c38d                	beqz	a5,80001ea0 <clockintr+0x58>
    printf("T");
  }
  wakeup(&ticks);
    80001e80:	00003517          	auipc	a0,0x3
    80001e84:	22450513          	addi	a0,a0,548 # 800050a4 <ticks>
    80001e88:	b55ff0ef          	jal	ra,800019dc <wakeup>
  release(&tickslock);
    80001e8c:	0000f517          	auipc	a0,0xf
    80001e90:	20c50513          	addi	a0,a0,524 # 80011098 <tickslock>
    80001e94:	96bfe0ef          	jal	ra,800007fe <release>
}
    80001e98:	60a2                	ld	ra,8(sp)
    80001e9a:	6402                	ld	s0,0(sp)
    80001e9c:	0141                	addi	sp,sp,16
    80001e9e:	8082                	ret
    printf("T");
    80001ea0:	00002517          	auipc	a0,0x2
    80001ea4:	44050513          	addi	a0,a0,1088 # 800042e0 <digits+0x2a8>
    80001ea8:	b32fe0ef          	jal	ra,800001da <printf>
    80001eac:	bfd1                	j	80001e80 <clockintr+0x38>

0000000080001eae <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80001eae:	1101                	addi	sp,sp,-32
    80001eb0:	ec06                	sd	ra,24(sp)
    80001eb2:	e822                	sd	s0,16(sp)
    80001eb4:	e426                	sd	s1,8(sp)
    80001eb6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001eb8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80001ebc:	00074d63          	bltz	a4,80001ed6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80001ec0:	57fd                	li	a5,-1
    80001ec2:	17fe                	slli	a5,a5,0x3f
    80001ec4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80001ec6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80001ec8:	04f70663          	beq	a4,a5,80001f14 <devintr+0x66>
  }
}
    80001ecc:	60e2                	ld	ra,24(sp)
    80001ece:	6442                	ld	s0,16(sp)
    80001ed0:	64a2                	ld	s1,8(sp)
    80001ed2:	6105                	addi	sp,sp,32
    80001ed4:	8082                	ret
     (scause & 0xff) == 9){
    80001ed6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80001eda:	46a5                	li	a3,9
    80001edc:	fed792e3          	bne	a5,a3,80001ec0 <devintr+0x12>
    int irq = plic_claim();
    80001ee0:	680000ef          	jal	ra,80002560 <plic_claim>
    80001ee4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80001ee6:	47a9                	li	a5,10
    80001ee8:	00f50f63          	beq	a0,a5,80001f06 <devintr+0x58>
    } else if(irq == VIRTIO0_IRQ){
    80001eec:	4785                	li	a5,1
    80001eee:	00f50e63          	beq	a0,a5,80001f0a <devintr+0x5c>
    return 1;
    80001ef2:	4505                	li	a0,1
    } else if(irq){
    80001ef4:	dce1                	beqz	s1,80001ecc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80001ef6:	85a6                	mv	a1,s1
    80001ef8:	00002517          	auipc	a0,0x2
    80001efc:	3f050513          	addi	a0,a0,1008 # 800042e8 <digits+0x2b0>
    80001f00:	adafe0ef          	jal	ra,800001da <printf>
    80001f04:	a019                	j	80001f0a <devintr+0x5c>
      uartintr();
    80001f06:	e74fe0ef          	jal	ra,8000057a <uartintr>
      plic_complete(irq);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	674000ef          	jal	ra,80002580 <plic_complete>
    return 1;
    80001f10:	4505                	li	a0,1
    80001f12:	bf6d                	j	80001ecc <devintr+0x1e>
    if(cpuid() == 0){
    80001f14:	c50ff0ef          	jal	ra,80001364 <cpuid>
    80001f18:	c901                	beqz	a0,80001f28 <devintr+0x7a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80001f1a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80001f1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80001f20:	14479073          	csrw	sip,a5
    return 2;
    80001f24:	4509                	li	a0,2
    80001f26:	b75d                	j	80001ecc <devintr+0x1e>
      clockintr();
    80001f28:	f21ff0ef          	jal	ra,80001e48 <clockintr>
    80001f2c:	b7fd                	j	80001f1a <devintr+0x6c>

0000000080001f2e <usertrap>:
{
    80001f2e:	1101                	addi	sp,sp,-32
    80001f30:	ec06                	sd	ra,24(sp)
    80001f32:	e822                	sd	s0,16(sp)
    80001f34:	e426                	sd	s1,8(sp)
    80001f36:	e04a                	sd	s2,0(sp)
    80001f38:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80001f3e:	1007f793          	andi	a5,a5,256
    80001f42:	ef85                	bnez	a5,80001f7a <usertrap+0x4c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001f44:	00000797          	auipc	a5,0x0
    80001f48:	49c78793          	addi	a5,a5,1180 # 800023e0 <kernelvec>
    80001f4c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80001f50:	c40ff0ef          	jal	ra,80001390 <myproc>
    80001f54:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80001f56:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001f58:	14102773          	csrr	a4,sepc
    80001f5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001f5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80001f62:	47a1                	li	a5,8
    80001f64:	02f70163          	beq	a4,a5,80001f86 <usertrap+0x58>
  } else if((which_dev = devintr()) != 0){
    80001f68:	f47ff0ef          	jal	ra,80001eae <devintr>
    80001f6c:	892a                	mv	s2,a0
    80001f6e:	c135                	beqz	a0,80001fd2 <usertrap+0xa4>
  if(killed(p))
    80001f70:	8526                	mv	a0,s1
    80001f72:	c31ff0ef          	jal	ra,80001ba2 <killed>
    80001f76:	cd1d                	beqz	a0,80001fb4 <usertrap+0x86>
    80001f78:	a81d                	j	80001fae <usertrap+0x80>
    panic("usertrap: not from user mode");
    80001f7a:	00002517          	auipc	a0,0x2
    80001f7e:	38e50513          	addi	a0,a0,910 # 80004308 <digits+0x2d0>
    80001f82:	a1afe0ef          	jal	ra,8000019c <panic>
    if(killed(p))
    80001f86:	c1dff0ef          	jal	ra,80001ba2 <killed>
    80001f8a:	e121                	bnez	a0,80001fca <usertrap+0x9c>
    p->trapframe->epc += 4;
    80001f8c:	6cb8                	ld	a4,88(s1)
    80001f8e:	6f1c                	ld	a5,24(a4)
    80001f90:	0791                	addi	a5,a5,4
    80001f92:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    syscall();
    80001fa0:	248000ef          	jal	ra,800021e8 <syscall>
  if(killed(p))
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	bfdff0ef          	jal	ra,80001ba2 <killed>
    80001faa:	c901                	beqz	a0,80001fba <usertrap+0x8c>
    80001fac:	4901                	li	s2,0
    exit(-1);
    80001fae:	557d                	li	a0,-1
    80001fb0:	aedff0ef          	jal	ra,80001a9c <exit>
  if(which_dev == 2)
    80001fb4:	4789                	li	a5,2
    80001fb6:	04f90263          	beq	s2,a5,80001ffa <usertrap+0xcc>
  usertrapret();
    80001fba:	dfdff0ef          	jal	ra,80001db6 <usertrapret>
}
    80001fbe:	60e2                	ld	ra,24(sp)
    80001fc0:	6442                	ld	s0,16(sp)
    80001fc2:	64a2                	ld	s1,8(sp)
    80001fc4:	6902                	ld	s2,0(sp)
    80001fc6:	6105                	addi	sp,sp,32
    80001fc8:	8082                	ret
      exit(-1);
    80001fca:	557d                	li	a0,-1
    80001fcc:	ad1ff0ef          	jal	ra,80001a9c <exit>
    80001fd0:	bf75                	j	80001f8c <usertrap+0x5e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001fd2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80001fd6:	5890                	lw	a2,48(s1)
    80001fd8:	00002517          	auipc	a0,0x2
    80001fdc:	35050513          	addi	a0,a0,848 # 80004328 <digits+0x2f0>
    80001fe0:	9fafe0ef          	jal	ra,800001da <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001fe4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001fe8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80001fec:	00002517          	auipc	a0,0x2
    80001ff0:	36c50513          	addi	a0,a0,876 # 80004358 <digits+0x320>
    80001ff4:	9e6fe0ef          	jal	ra,800001da <printf>
    80001ff8:	b775                	j	80001fa4 <usertrap+0x76>
    yield();
    80001ffa:	96bff0ef          	jal	ra,80001964 <yield>
    80001ffe:	bf75                	j	80001fba <usertrap+0x8c>

0000000080002000 <kerneltrap>:
{
    80002000:	7179                	addi	sp,sp,-48
    80002002:	f406                	sd	ra,40(sp)
    80002004:	f022                	sd	s0,32(sp)
    80002006:	ec26                	sd	s1,24(sp)
    80002008:	e84a                	sd	s2,16(sp)
    8000200a:	e44e                	sd	s3,8(sp)
    8000200c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000200e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002012:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002016:	142029f3          	csrr	s3,scause
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000201e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002020:	e395                	bnez	a5,80002044 <kerneltrap+0x44>
  if((which_dev = devintr()) == 0){
    80002022:	e8dff0ef          	jal	ra,80001eae <devintr>
    80002026:	c50d                	beqz	a0,80002050 <kerneltrap+0x50>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002028:	4789                	li	a5,2
    8000202a:	04f50a63          	beq	a0,a5,8000207e <kerneltrap+0x7e>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000202e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002032:	10049073          	csrw	sstatus,s1
}
    80002036:	70a2                	ld	ra,40(sp)
    80002038:	7402                	ld	s0,32(sp)
    8000203a:	64e2                	ld	s1,24(sp)
    8000203c:	6942                	ld	s2,16(sp)
    8000203e:	69a2                	ld	s3,8(sp)
    80002040:	6145                	addi	sp,sp,48
    80002042:	8082                	ret
    panic("kerneltrap: interrupts enabled");
    80002044:	00002517          	auipc	a0,0x2
    80002048:	33450513          	addi	a0,a0,820 # 80004378 <digits+0x340>
    8000204c:	950fe0ef          	jal	ra,8000019c <panic>
    printf("scause %p\n", scause);
    80002050:	85ce                	mv	a1,s3
    80002052:	00002517          	auipc	a0,0x2
    80002056:	34650513          	addi	a0,a0,838 # 80004398 <digits+0x360>
    8000205a:	980fe0ef          	jal	ra,800001da <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000205e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002062:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002066:	00002517          	auipc	a0,0x2
    8000206a:	34250513          	addi	a0,a0,834 # 800043a8 <digits+0x370>
    8000206e:	96cfe0ef          	jal	ra,800001da <printf>
    panic("kerneltrap");
    80002072:	00002517          	auipc	a0,0x2
    80002076:	34e50513          	addi	a0,a0,846 # 800043c0 <digits+0x388>
    8000207a:	922fe0ef          	jal	ra,8000019c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000207e:	b12ff0ef          	jal	ra,80001390 <myproc>
    80002082:	d555                	beqz	a0,8000202e <kerneltrap+0x2e>
    80002084:	b0cff0ef          	jal	ra,80001390 <myproc>
    80002088:	4d18                	lw	a4,24(a0)
    8000208a:	4791                	li	a5,4
    8000208c:	faf711e3          	bne	a4,a5,8000202e <kerneltrap+0x2e>
    yield();
    80002090:	8d5ff0ef          	jal	ra,80001964 <yield>
    80002094:	bf69                	j	8000202e <kerneltrap+0x2e>

0000000080002096 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002096:	1101                	addi	sp,sp,-32
    80002098:	ec06                	sd	ra,24(sp)
    8000209a:	e822                	sd	s0,16(sp)
    8000209c:	e426                	sd	s1,8(sp)
    8000209e:	1000                	addi	s0,sp,32
    800020a0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020a2:	aeeff0ef          	jal	ra,80001390 <myproc>
  switch (n) {
    800020a6:	4795                	li	a5,5
    800020a8:	0497e163          	bltu	a5,s1,800020ea <argraw+0x54>
    800020ac:	048a                	slli	s1,s1,0x2
    800020ae:	00002717          	auipc	a4,0x2
    800020b2:	32a70713          	addi	a4,a4,810 # 800043d8 <digits+0x3a0>
    800020b6:	94ba                	add	s1,s1,a4
    800020b8:	409c                	lw	a5,0(s1)
    800020ba:	97ba                	add	a5,a5,a4
    800020bc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800020be:	6d3c                	ld	a5,88(a0)
    800020c0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800020c2:	60e2                	ld	ra,24(sp)
    800020c4:	6442                	ld	s0,16(sp)
    800020c6:	64a2                	ld	s1,8(sp)
    800020c8:	6105                	addi	sp,sp,32
    800020ca:	8082                	ret
    return p->trapframe->a1;
    800020cc:	6d3c                	ld	a5,88(a0)
    800020ce:	7fa8                	ld	a0,120(a5)
    800020d0:	bfcd                	j	800020c2 <argraw+0x2c>
    return p->trapframe->a2;
    800020d2:	6d3c                	ld	a5,88(a0)
    800020d4:	63c8                	ld	a0,128(a5)
    800020d6:	b7f5                	j	800020c2 <argraw+0x2c>
    return p->trapframe->a3;
    800020d8:	6d3c                	ld	a5,88(a0)
    800020da:	67c8                	ld	a0,136(a5)
    800020dc:	b7dd                	j	800020c2 <argraw+0x2c>
    return p->trapframe->a4;
    800020de:	6d3c                	ld	a5,88(a0)
    800020e0:	6bc8                	ld	a0,144(a5)
    800020e2:	b7c5                	j	800020c2 <argraw+0x2c>
    return p->trapframe->a5;
    800020e4:	6d3c                	ld	a5,88(a0)
    800020e6:	6fc8                	ld	a0,152(a5)
    800020e8:	bfe9                	j	800020c2 <argraw+0x2c>
  panic("argraw");
    800020ea:	00002517          	auipc	a0,0x2
    800020ee:	2e650513          	addi	a0,a0,742 # 800043d0 <digits+0x398>
    800020f2:	8aafe0ef          	jal	ra,8000019c <panic>

00000000800020f6 <fetchaddr>:
{
    800020f6:	1101                	addi	sp,sp,-32
    800020f8:	ec06                	sd	ra,24(sp)
    800020fa:	e822                	sd	s0,16(sp)
    800020fc:	e426                	sd	s1,8(sp)
    800020fe:	e04a                	sd	s2,0(sp)
    80002100:	1000                	addi	s0,sp,32
    80002102:	84aa                	mv	s1,a0
    80002104:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002106:	a8aff0ef          	jal	ra,80001390 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000210a:	653c                	ld	a5,72(a0)
    8000210c:	02f4f663          	bgeu	s1,a5,80002138 <fetchaddr+0x42>
    80002110:	00848713          	addi	a4,s1,8
    80002114:	02e7e463          	bltu	a5,a4,8000213c <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002118:	46a1                	li	a3,8
    8000211a:	8626                	mv	a2,s1
    8000211c:	85ca                	mv	a1,s2
    8000211e:	6928                	ld	a0,80(a0)
    80002120:	fddfe0ef          	jal	ra,800010fc <copyin>
    80002124:	00a03533          	snez	a0,a0
    80002128:	40a00533          	neg	a0,a0
}
    8000212c:	60e2                	ld	ra,24(sp)
    8000212e:	6442                	ld	s0,16(sp)
    80002130:	64a2                	ld	s1,8(sp)
    80002132:	6902                	ld	s2,0(sp)
    80002134:	6105                	addi	sp,sp,32
    80002136:	8082                	ret
    return -1;
    80002138:	557d                	li	a0,-1
    8000213a:	bfcd                	j	8000212c <fetchaddr+0x36>
    8000213c:	557d                	li	a0,-1
    8000213e:	b7fd                	j	8000212c <fetchaddr+0x36>

0000000080002140 <fetchstr>:
{
    80002140:	7179                	addi	sp,sp,-48
    80002142:	f406                	sd	ra,40(sp)
    80002144:	f022                	sd	s0,32(sp)
    80002146:	ec26                	sd	s1,24(sp)
    80002148:	e84a                	sd	s2,16(sp)
    8000214a:	e44e                	sd	s3,8(sp)
    8000214c:	1800                	addi	s0,sp,48
    8000214e:	892a                	mv	s2,a0
    80002150:	84ae                	mv	s1,a1
    80002152:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002154:	a3cff0ef          	jal	ra,80001390 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002158:	86ce                	mv	a3,s3
    8000215a:	864a                	mv	a2,s2
    8000215c:	85a6                	mv	a1,s1
    8000215e:	6928                	ld	a0,80(a0)
    80002160:	822ff0ef          	jal	ra,80001182 <copyinstr>
    80002164:	00054c63          	bltz	a0,8000217c <fetchstr+0x3c>
  return strlen(buf);
    80002168:	8526                	mv	a0,s1
    8000216a:	849fe0ef          	jal	ra,800009b2 <strlen>
}
    8000216e:	70a2                	ld	ra,40(sp)
    80002170:	7402                	ld	s0,32(sp)
    80002172:	64e2                	ld	s1,24(sp)
    80002174:	6942                	ld	s2,16(sp)
    80002176:	69a2                	ld	s3,8(sp)
    80002178:	6145                	addi	sp,sp,48
    8000217a:	8082                	ret
    return -1;
    8000217c:	557d                	li	a0,-1
    8000217e:	bfc5                	j	8000216e <fetchstr+0x2e>

0000000080002180 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002180:	1101                	addi	sp,sp,-32
    80002182:	ec06                	sd	ra,24(sp)
    80002184:	e822                	sd	s0,16(sp)
    80002186:	e426                	sd	s1,8(sp)
    80002188:	1000                	addi	s0,sp,32
    8000218a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000218c:	f0bff0ef          	jal	ra,80002096 <argraw>
    80002190:	c088                	sw	a0,0(s1)
  // struct proc *p = myproc();
  // printf("%d %s: argint, n: %d, value: %d\n", p->pid, p->name, n, *ip); // 添加日志输出
}
    80002192:	60e2                	ld	ra,24(sp)
    80002194:	6442                	ld	s0,16(sp)
    80002196:	64a2                	ld	s1,8(sp)
    80002198:	6105                	addi	sp,sp,32
    8000219a:	8082                	ret

000000008000219c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    8000219c:	1101                	addi	sp,sp,-32
    8000219e:	ec06                	sd	ra,24(sp)
    800021a0:	e822                	sd	s0,16(sp)
    800021a2:	e426                	sd	s1,8(sp)
    800021a4:	1000                	addi	s0,sp,32
    800021a6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800021a8:	eefff0ef          	jal	ra,80002096 <argraw>
    800021ac:	e088                	sd	a0,0(s1)
}
    800021ae:	60e2                	ld	ra,24(sp)
    800021b0:	6442                	ld	s0,16(sp)
    800021b2:	64a2                	ld	s1,8(sp)
    800021b4:	6105                	addi	sp,sp,32
    800021b6:	8082                	ret

00000000800021b8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800021b8:	7179                	addi	sp,sp,-48
    800021ba:	f406                	sd	ra,40(sp)
    800021bc:	f022                	sd	s0,32(sp)
    800021be:	ec26                	sd	s1,24(sp)
    800021c0:	e84a                	sd	s2,16(sp)
    800021c2:	1800                	addi	s0,sp,48
    800021c4:	84ae                	mv	s1,a1
    800021c6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800021c8:	fd840593          	addi	a1,s0,-40
    800021cc:	fd1ff0ef          	jal	ra,8000219c <argaddr>
  return fetchstr(addr, buf, max);
    800021d0:	864a                	mv	a2,s2
    800021d2:	85a6                	mv	a1,s1
    800021d4:	fd843503          	ld	a0,-40(s0)
    800021d8:	f69ff0ef          	jal	ra,80002140 <fetchstr>
}
    800021dc:	70a2                	ld	ra,40(sp)
    800021de:	7402                	ld	s0,32(sp)
    800021e0:	64e2                	ld	s1,24(sp)
    800021e2:	6942                	ld	s2,16(sp)
    800021e4:	6145                	addi	sp,sp,48
    800021e6:	8082                	ret

00000000800021e8 <syscall>:
[SYS_write]   "write",
};

void
syscall(void)
{
    800021e8:	1101                	addi	sp,sp,-32
    800021ea:	ec06                	sd	ra,24(sp)
    800021ec:	e822                	sd	s0,16(sp)
    800021ee:	e426                	sd	s1,8(sp)
    800021f0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800021f2:	99eff0ef          	jal	ra,80001390 <myproc>
  // int cpu_id = cpuid();

  num = p->trapframe->a7;
    800021f6:	6d24                	ld	s1,88(a0)
    800021f8:	74dc                	ld	a5,168(s1)
  } else {
    // printf("CPU %d: Process %d (%s) called unknown syscall %d\n",
    //        cpuid(), p->pid, p->name, num);
  }
  
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800021fa:	fff7869b          	addiw	a3,a5,-1
    800021fe:	473d                	li	a4,15
    80002200:	00d76e63          	bltu	a4,a3,8000221c <syscall+0x34>
    80002204:	2781                	sext.w	a5,a5
    80002206:	078e                	slli	a5,a5,0x3
    80002208:	00002717          	auipc	a4,0x2
    8000220c:	1e870713          	addi	a4,a4,488 # 800043f0 <syscalls>
    80002210:	97ba                	add	a5,a5,a4
    80002212:	639c                	ld	a5,0(a5)
    80002214:	c781                	beqz	a5,8000221c <syscall+0x34>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002216:	9782                	jalr	a5
    80002218:	f8a8                	sd	a0,112(s1)
    8000221a:	a019                	j	80002220 <syscall+0x38>
  } else {
    // printf("%d %s: unknown sys call %d\n",
    //        p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000221c:	57fd                	li	a5,-1
    8000221e:	f8bc                	sd	a5,112(s1)
  }
}
    80002220:	60e2                	ld	ra,24(sp)
    80002222:	6442                	ld	s0,16(sp)
    80002224:	64a2                	ld	s1,8(sp)
    80002226:	6105                	addi	sp,sp,32
    80002228:	8082                	ret

000000008000222a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000222a:	1101                	addi	sp,sp,-32
    8000222c:	ec06                	sd	ra,24(sp)
    8000222e:	e822                	sd	s0,16(sp)
    80002230:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002232:	fec40593          	addi	a1,s0,-20
    80002236:	4501                	li	a0,0
    80002238:	f49ff0ef          	jal	ra,80002180 <argint>
  // struct proc *p = myproc();
  // printf("%d %s: sys_exit, exit code: %d\n", p->pid, p->name, n); // 添加日志输出
  exit(n);
    8000223c:	fec42503          	lw	a0,-20(s0)
    80002240:	85dff0ef          	jal	ra,80001a9c <exit>
  return 0;  // not reached
}
    80002244:	4501                	li	a0,0
    80002246:	60e2                	ld	ra,24(sp)
    80002248:	6442                	ld	s0,16(sp)
    8000224a:	6105                	addi	sp,sp,32
    8000224c:	8082                	ret

000000008000224e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000224e:	1141                	addi	sp,sp,-16
    80002250:	e406                	sd	ra,8(sp)
    80002252:	e022                	sd	s0,0(sp)
    80002254:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002256:	93aff0ef          	jal	ra,80001390 <myproc>
}
    8000225a:	5908                	lw	a0,48(a0)
    8000225c:	60a2                	ld	ra,8(sp)
    8000225e:	6402                	ld	s0,0(sp)
    80002260:	0141                	addi	sp,sp,16
    80002262:	8082                	ret

0000000080002264 <sys_fork>:

uint64
sys_fork(void)
{
    80002264:	1141                	addi	sp,sp,-16
    80002266:	e406                	sd	ra,8(sp)
    80002268:	e022                	sd	s0,0(sp)
    8000226a:	0800                	addi	s0,sp,16
  uint64 result = fork();
    8000226c:	cdcff0ef          	jal	ra,80001748 <fork>
  // struct proc *p = myproc();
  // printf("%d %s: sys_fork, result: %d\n", p->pid, p->name, (int)result); // 添加日志输出
  return result;
}
    80002270:	60a2                	ld	ra,8(sp)
    80002272:	6402                	ld	s0,0(sp)
    80002274:	0141                	addi	sp,sp,16
    80002276:	8082                	ret

0000000080002278 <sys_wait>:

uint64
sys_wait(void)
{
    80002278:	1101                	addi	sp,sp,-32
    8000227a:	ec06                	sd	ra,24(sp)
    8000227c:	e822                	sd	s0,16(sp)
    8000227e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002280:	fe840593          	addi	a1,s0,-24
    80002284:	4501                	li	a0,0
    80002286:	f17ff0ef          	jal	ra,8000219c <argaddr>
  uint64 result = wait(p);
    8000228a:	fe843503          	ld	a0,-24(s0)
    8000228e:	93fff0ef          	jal	ra,80001bcc <wait>
  // struct proc *proc = myproc();
  // printf("%d %s: sys_wait, result: %d\n", proc->pid, proc->name, (int)result); // 添加日志输出
  return result;
}
    80002292:	60e2                	ld	ra,24(sp)
    80002294:	6442                	ld	s0,16(sp)
    80002296:	6105                	addi	sp,sp,32
    80002298:	8082                	ret

000000008000229a <sys_sbrk>:

static int sbrk_call_count = 0;

uint64
sys_sbrk(void)
{
    8000229a:	7179                	addi	sp,sp,-48
    8000229c:	f406                	sd	ra,40(sp)
    8000229e:	f022                	sd	s0,32(sp)
    800022a0:	ec26                	sd	s1,24(sp)
    800022a2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800022a4:	fdc40593          	addi	a1,s0,-36
    800022a8:	4501                	li	a0,0
    800022aa:	ed7ff0ef          	jal	ra,80002180 <argint>
  addr = myproc()->sz;
    800022ae:	8e2ff0ef          	jal	ra,80001390 <myproc>
    800022b2:	6524                	ld	s1,72(a0)
  sbrk_call_count++;
    800022b4:	00003797          	auipc	a5,0x3
    800022b8:	df478793          	addi	a5,a5,-524 # 800050a8 <sbrk_call_count>
    800022bc:	438c                	lw	a1,0(a5)
    800022be:	2585                	addiw	a1,a1,1
    800022c0:	c38c                	sw	a1,0(a5)
  printf("sbrk called for the %d time\n", sbrk_call_count);
    800022c2:	2581                	sext.w	a1,a1
    800022c4:	00002517          	auipc	a0,0x2
    800022c8:	1b450513          	addi	a0,a0,436 # 80004478 <syscalls+0x88>
    800022cc:	f0ffd0ef          	jal	ra,800001da <printf>
  if(growproc(n) < 0) {
    800022d0:	fdc42503          	lw	a0,-36(s0)
    800022d4:	c24ff0ef          	jal	ra,800016f8 <growproc>
    800022d8:	00054863          	bltz	a0,800022e8 <sys_sbrk+0x4e>
    return -1;
  }
  return addr;
}
    800022dc:	8526                	mv	a0,s1
    800022de:	70a2                	ld	ra,40(sp)
    800022e0:	7402                	ld	s0,32(sp)
    800022e2:	64e2                	ld	s1,24(sp)
    800022e4:	6145                	addi	sp,sp,48
    800022e6:	8082                	ret
    return -1;
    800022e8:	54fd                	li	s1,-1
    800022ea:	bfcd                	j	800022dc <sys_sbrk+0x42>

00000000800022ec <sys_sleep>:

uint64
sys_sleep(void)
{
    800022ec:	7139                	addi	sp,sp,-64
    800022ee:	fc06                	sd	ra,56(sp)
    800022f0:	f822                	sd	s0,48(sp)
    800022f2:	f426                	sd	s1,40(sp)
    800022f4:	f04a                	sd	s2,32(sp)
    800022f6:	ec4e                	sd	s3,24(sp)
    800022f8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800022fa:	fcc40593          	addi	a1,s0,-52
    800022fe:	4501                	li	a0,0
    80002300:	e81ff0ef          	jal	ra,80002180 <argint>
  acquire(&tickslock);
    80002304:	0000f517          	auipc	a0,0xf
    80002308:	d9450513          	addi	a0,a0,-620 # 80011098 <tickslock>
    8000230c:	c5afe0ef          	jal	ra,80000766 <acquire>
  ticks0 = ticks;
    80002310:	00003917          	auipc	s2,0x3
    80002314:	d9492903          	lw	s2,-620(s2) # 800050a4 <ticks>
  while(ticks - ticks0 < n){
    80002318:	fcc42783          	lw	a5,-52(s0)
    8000231c:	cb8d                	beqz	a5,8000234e <sys_sleep+0x62>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000231e:	0000f997          	auipc	s3,0xf
    80002322:	d7a98993          	addi	s3,s3,-646 # 80011098 <tickslock>
    80002326:	00003497          	auipc	s1,0x3
    8000232a:	d7e48493          	addi	s1,s1,-642 # 800050a4 <ticks>
    if(killed(myproc())){
    8000232e:	862ff0ef          	jal	ra,80001390 <myproc>
    80002332:	871ff0ef          	jal	ra,80001ba2 <killed>
    80002336:	e915                	bnez	a0,8000236a <sys_sleep+0x7e>
    sleep(&ticks, &tickslock);
    80002338:	85ce                	mv	a1,s3
    8000233a:	8526                	mv	a0,s1
    8000233c:	e54ff0ef          	jal	ra,80001990 <sleep>
  while(ticks - ticks0 < n){
    80002340:	409c                	lw	a5,0(s1)
    80002342:	412787bb          	subw	a5,a5,s2
    80002346:	fcc42703          	lw	a4,-52(s0)
    8000234a:	fee7e2e3          	bltu	a5,a4,8000232e <sys_sleep+0x42>
  }
  release(&tickslock);
    8000234e:	0000f517          	auipc	a0,0xf
    80002352:	d4a50513          	addi	a0,a0,-694 # 80011098 <tickslock>
    80002356:	ca8fe0ef          	jal	ra,800007fe <release>
  return 0;
    8000235a:	4501                	li	a0,0
}
    8000235c:	70e2                	ld	ra,56(sp)
    8000235e:	7442                	ld	s0,48(sp)
    80002360:	74a2                	ld	s1,40(sp)
    80002362:	7902                	ld	s2,32(sp)
    80002364:	69e2                	ld	s3,24(sp)
    80002366:	6121                	addi	sp,sp,64
    80002368:	8082                	ret
      release(&tickslock);
    8000236a:	0000f517          	auipc	a0,0xf
    8000236e:	d2e50513          	addi	a0,a0,-722 # 80011098 <tickslock>
    80002372:	c8cfe0ef          	jal	ra,800007fe <release>
      return -1;
    80002376:	557d                	li	a0,-1
    80002378:	b7d5                	j	8000235c <sys_sleep+0x70>

000000008000237a <sys_kill>:

uint64
sys_kill(void)
{
    8000237a:	1101                	addi	sp,sp,-32
    8000237c:	ec06                	sd	ra,24(sp)
    8000237e:	e822                	sd	s0,16(sp)
    80002380:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002382:	fec40593          	addi	a1,s0,-20
    80002386:	4501                	li	a0,0
    80002388:	df9ff0ef          	jal	ra,80002180 <argint>
  uint64 result = kill(pid);
    8000238c:	fec42503          	lw	a0,-20(s0)
    80002390:	f88ff0ef          	jal	ra,80001b18 <kill>
  // struct proc *p = myproc();
  // printf("%d %s: sys_kill, target pid: %d, result: %d\n", p->pid, p->name, pid, (int)result); // 添加日志输出
  return result;
}
    80002394:	60e2                	ld	ra,24(sp)
    80002396:	6442                	ld	s0,16(sp)
    80002398:	6105                	addi	sp,sp,32
    8000239a:	8082                	ret

000000008000239c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000239c:	1101                	addi	sp,sp,-32
    8000239e:	ec06                	sd	ra,24(sp)
    800023a0:	e822                	sd	s0,16(sp)
    800023a2:	e426                	sd	s1,8(sp)
    800023a4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800023a6:	0000f517          	auipc	a0,0xf
    800023aa:	cf250513          	addi	a0,a0,-782 # 80011098 <tickslock>
    800023ae:	bb8fe0ef          	jal	ra,80000766 <acquire>
  xticks = ticks;
    800023b2:	00003497          	auipc	s1,0x3
    800023b6:	cf24a483          	lw	s1,-782(s1) # 800050a4 <ticks>
  release(&tickslock);
    800023ba:	0000f517          	auipc	a0,0xf
    800023be:	cde50513          	addi	a0,a0,-802 # 80011098 <tickslock>
    800023c2:	c3cfe0ef          	jal	ra,800007fe <release>
  return xticks;
    800023c6:	02049513          	slli	a0,s1,0x20
    800023ca:	9101                	srli	a0,a0,0x20
    800023cc:	60e2                	ld	ra,24(sp)
    800023ce:	6442                	ld	s0,16(sp)
    800023d0:	64a2                	ld	s1,8(sp)
    800023d2:	6105                	addi	sp,sp,32
    800023d4:	8082                	ret
	...

00000000800023e0 <kernelvec>:
    800023e0:	7111                	addi	sp,sp,-256
    800023e2:	e006                	sd	ra,0(sp)
    800023e4:	e40a                	sd	sp,8(sp)
    800023e6:	e80e                	sd	gp,16(sp)
    800023e8:	ec12                	sd	tp,24(sp)
    800023ea:	f016                	sd	t0,32(sp)
    800023ec:	f41a                	sd	t1,40(sp)
    800023ee:	f81e                	sd	t2,48(sp)
    800023f0:	fc22                	sd	s0,56(sp)
    800023f2:	e0a6                	sd	s1,64(sp)
    800023f4:	e4aa                	sd	a0,72(sp)
    800023f6:	e8ae                	sd	a1,80(sp)
    800023f8:	ecb2                	sd	a2,88(sp)
    800023fa:	f0b6                	sd	a3,96(sp)
    800023fc:	f4ba                	sd	a4,104(sp)
    800023fe:	f8be                	sd	a5,112(sp)
    80002400:	fcc2                	sd	a6,120(sp)
    80002402:	e146                	sd	a7,128(sp)
    80002404:	e54a                	sd	s2,136(sp)
    80002406:	e94e                	sd	s3,144(sp)
    80002408:	ed52                	sd	s4,152(sp)
    8000240a:	f156                	sd	s5,160(sp)
    8000240c:	f55a                	sd	s6,168(sp)
    8000240e:	f95e                	sd	s7,176(sp)
    80002410:	fd62                	sd	s8,184(sp)
    80002412:	e1e6                	sd	s9,192(sp)
    80002414:	e5ea                	sd	s10,200(sp)
    80002416:	e9ee                	sd	s11,208(sp)
    80002418:	edf2                	sd	t3,216(sp)
    8000241a:	f1f6                	sd	t4,224(sp)
    8000241c:	f5fa                	sd	t5,232(sp)
    8000241e:	f9fe                	sd	t6,240(sp)
    80002420:	be1ff0ef          	jal	ra,80002000 <kerneltrap>
    80002424:	6082                	ld	ra,0(sp)
    80002426:	6122                	ld	sp,8(sp)
    80002428:	61c2                	ld	gp,16(sp)
    8000242a:	7282                	ld	t0,32(sp)
    8000242c:	7322                	ld	t1,40(sp)
    8000242e:	73c2                	ld	t2,48(sp)
    80002430:	7462                	ld	s0,56(sp)
    80002432:	6486                	ld	s1,64(sp)
    80002434:	6526                	ld	a0,72(sp)
    80002436:	65c6                	ld	a1,80(sp)
    80002438:	6666                	ld	a2,88(sp)
    8000243a:	7686                	ld	a3,96(sp)
    8000243c:	7726                	ld	a4,104(sp)
    8000243e:	77c6                	ld	a5,112(sp)
    80002440:	7866                	ld	a6,120(sp)
    80002442:	688a                	ld	a7,128(sp)
    80002444:	692a                	ld	s2,136(sp)
    80002446:	69ca                	ld	s3,144(sp)
    80002448:	6a6a                	ld	s4,152(sp)
    8000244a:	7a8a                	ld	s5,160(sp)
    8000244c:	7b2a                	ld	s6,168(sp)
    8000244e:	7bca                	ld	s7,176(sp)
    80002450:	7c6a                	ld	s8,184(sp)
    80002452:	6c8e                	ld	s9,192(sp)
    80002454:	6d2e                	ld	s10,200(sp)
    80002456:	6dce                	ld	s11,208(sp)
    80002458:	6e6e                	ld	t3,216(sp)
    8000245a:	7e8e                	ld	t4,224(sp)
    8000245c:	7f2e                	ld	t5,232(sp)
    8000245e:	7fce                	ld	t6,240(sp)
    80002460:	6111                	addi	sp,sp,256
    80002462:	10200073          	sret
    80002466:	00000013          	nop
    8000246a:	00000013          	nop
    8000246e:	0001                	nop

0000000080002470 <timervec>:
    80002470:	34051573          	csrrw	a0,mscratch,a0
    80002474:	e10c                	sd	a1,0(a0)
    80002476:	e510                	sd	a2,8(a0)
    80002478:	e914                	sd	a3,16(a0)
    8000247a:	6d0c                	ld	a1,24(a0)
    8000247c:	7110                	ld	a2,32(a0)
    8000247e:	6194                	ld	a3,0(a1)
    80002480:	96b2                	add	a3,a3,a2
    80002482:	e194                	sd	a3,0(a1)
    80002484:	4589                	li	a1,2
    80002486:	14459073          	csrw	sip,a1
    8000248a:	6914                	ld	a3,16(a0)
    8000248c:	6510                	ld	a2,8(a0)
    8000248e:	610c                	ld	a1,0(a0)
    80002490:	34051573          	csrrw	a0,mscratch,a0
    80002494:	30200073          	mret
	...

000000008000249a <sys_write>:
// #include "file.h"
// #include "fcntl.h"

uint64
sys_write(void)
{
    8000249a:	715d                	addi	sp,sp,-80
    8000249c:	e486                	sd	ra,72(sp)
    8000249e:	e0a2                	sd	s0,64(sp)
    800024a0:	fc26                	sd	s1,56(sp)
    800024a2:	f84a                	sd	s2,48(sp)
    800024a4:	f44e                	sd	s3,40(sp)
    800024a6:	f052                	sd	s4,32(sp)
    800024a8:	0880                	addi	s0,sp,80
  int n;
  uint64 src;
  int i;
  
  // 获取系统调用参数：文件描述符(忽略)、源地址、字节数
  argaddr(1, &src);
    800024aa:	fc040593          	addi	a1,s0,-64
    800024ae:	4505                	li	a0,1
    800024b0:	cedff0ef          	jal	ra,8000219c <argaddr>
  argint(2, &n);
    800024b4:	fcc40593          	addi	a1,s0,-52
    800024b8:	4509                	li	a0,2
    800024ba:	cc7ff0ef          	jal	ra,80002180 <argint>
  
  // 直接实现consolewrite的功能，忽略文件描述符
  for(i = 0; i < n; i++){
    800024be:	fcc42783          	lw	a5,-52(s0)
    800024c2:	04f05863          	blez	a5,80002512 <sys_write+0x78>
    800024c6:	4481                	li	s1,0
    char c;
    if(either_copyin(&c, 1, src+i, 1) == -1)
    800024c8:	5a7d                	li	s4,-1
    800024ca:	0004891b          	sext.w	s2,s1
    800024ce:	89ca                	mv	s3,s2
    800024d0:	4685                	li	a3,1
    800024d2:	fc043603          	ld	a2,-64(s0)
    800024d6:	9626                	add	a2,a2,s1
    800024d8:	4585                	li	a1,1
    800024da:	fbf40513          	addi	a0,s0,-65
    800024de:	fe8ff0ef          	jal	ra,80001cc6 <either_copyin>
    800024e2:	01450f63          	beq	a0,s4,80002500 <sys_write+0x66>
      break;
    uartputc(c);
    800024e6:	fbf44503          	lbu	a0,-65(s0)
    800024ea:	fc3fd0ef          	jal	ra,800004ac <uartputc>
  for(i = 0; i < n; i++){
    800024ee:	0019099b          	addiw	s3,s2,1
    800024f2:	0485                	addi	s1,s1,1
    800024f4:	fcc42703          	lw	a4,-52(s0)
    800024f8:	0004879b          	sext.w	a5,s1
    800024fc:	fce7c7e3          	blt	a5,a4,800024ca <sys_write+0x30>
  }
  
  return i;
    80002500:	854e                	mv	a0,s3
    80002502:	60a6                	ld	ra,72(sp)
    80002504:	6406                	ld	s0,64(sp)
    80002506:	74e2                	ld	s1,56(sp)
    80002508:	7942                	ld	s2,48(sp)
    8000250a:	79a2                	ld	s3,40(sp)
    8000250c:	7a02                	ld	s4,32(sp)
    8000250e:	6161                	addi	sp,sp,80
    80002510:	8082                	ret
  for(i = 0; i < n; i++){
    80002512:	4981                	li	s3,0
    80002514:	b7f5                	j	80002500 <sys_write+0x66>

0000000080002516 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80002516:	1141                	addi	sp,sp,-16
    80002518:	e422                	sd	s0,8(sp)
    8000251a:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    8000251c:	0c0007b7          	lui	a5,0xc000
    80002520:	4705                	li	a4,1
    80002522:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80002524:	c3d8                	sw	a4,4(a5)
}
    80002526:	6422                	ld	s0,8(sp)
    80002528:	0141                	addi	sp,sp,16
    8000252a:	8082                	ret

000000008000252c <plicinithart>:

void
plicinithart(void)
{
    8000252c:	1141                	addi	sp,sp,-16
    8000252e:	e406                	sd	ra,8(sp)
    80002530:	e022                	sd	s0,0(sp)
    80002532:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80002534:	e31fe0ef          	jal	ra,80001364 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80002538:	0085171b          	slliw	a4,a0,0x8
    8000253c:	0c0027b7          	lui	a5,0xc002
    80002540:	97ba                	add	a5,a5,a4
    80002542:	40200713          	li	a4,1026
    80002546:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    8000254a:	00d5151b          	slliw	a0,a0,0xd
    8000254e:	0c2017b7          	lui	a5,0xc201
    80002552:	953e                	add	a0,a0,a5
    80002554:	00052023          	sw	zero,0(a0)
  
}
    80002558:	60a2                	ld	ra,8(sp)
    8000255a:	6402                	ld	s0,0(sp)
    8000255c:	0141                	addi	sp,sp,16
    8000255e:	8082                	ret

0000000080002560 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80002560:	1141                	addi	sp,sp,-16
    80002562:	e406                	sd	ra,8(sp)
    80002564:	e022                	sd	s0,0(sp)
    80002566:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80002568:	dfdfe0ef          	jal	ra,80001364 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    8000256c:	00d5179b          	slliw	a5,a0,0xd
    80002570:	0c201537          	lui	a0,0xc201
    80002574:	953e                	add	a0,a0,a5
  return irq;
}
    80002576:	4148                	lw	a0,4(a0)
    80002578:	60a2                	ld	ra,8(sp)
    8000257a:	6402                	ld	s0,0(sp)
    8000257c:	0141                	addi	sp,sp,16
    8000257e:	8082                	ret

0000000080002580 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80002580:	1101                	addi	sp,sp,-32
    80002582:	ec06                	sd	ra,24(sp)
    80002584:	e822                	sd	s0,16(sp)
    80002586:	e426                	sd	s1,8(sp)
    80002588:	1000                	addi	s0,sp,32
    8000258a:	84aa                	mv	s1,a0
  int hart = cpuid();
    8000258c:	dd9fe0ef          	jal	ra,80001364 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80002590:	00d5151b          	slliw	a0,a0,0xd
    80002594:	0c2017b7          	lui	a5,0xc201
    80002598:	97aa                	add	a5,a5,a0
    8000259a:	c3c4                	sw	s1,4(a5)
}
    8000259c:	60e2                	ld	ra,24(sp)
    8000259e:	6442                	ld	s0,16(sp)
    800025a0:	64a2                	ld	s1,8(sp)
    800025a2:	6105                	addi	sp,sp,32
    800025a4:	8082                	ret
	...

0000000080003000 <_trampoline>:
    80003000:	14051073          	csrw	sscratch,a0
    80003004:	02000537          	lui	a0,0x2000
    80003008:	357d                	addiw	a0,a0,-1
    8000300a:	0536                	slli	a0,a0,0xd
    8000300c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80003010:	02253823          	sd	sp,48(a0)
    80003014:	02353c23          	sd	gp,56(a0)
    80003018:	04453023          	sd	tp,64(a0)
    8000301c:	04553423          	sd	t0,72(a0)
    80003020:	04653823          	sd	t1,80(a0)
    80003024:	04753c23          	sd	t2,88(a0)
    80003028:	f120                	sd	s0,96(a0)
    8000302a:	f524                	sd	s1,104(a0)
    8000302c:	fd2c                	sd	a1,120(a0)
    8000302e:	e150                	sd	a2,128(a0)
    80003030:	e554                	sd	a3,136(a0)
    80003032:	e958                	sd	a4,144(a0)
    80003034:	ed5c                	sd	a5,152(a0)
    80003036:	0b053023          	sd	a6,160(a0)
    8000303a:	0b153423          	sd	a7,168(a0)
    8000303e:	0b253823          	sd	s2,176(a0)
    80003042:	0b353c23          	sd	s3,184(a0)
    80003046:	0d453023          	sd	s4,192(a0)
    8000304a:	0d553423          	sd	s5,200(a0)
    8000304e:	0d653823          	sd	s6,208(a0)
    80003052:	0d753c23          	sd	s7,216(a0)
    80003056:	0f853023          	sd	s8,224(a0)
    8000305a:	0f953423          	sd	s9,232(a0)
    8000305e:	0fa53823          	sd	s10,240(a0)
    80003062:	0fb53c23          	sd	s11,248(a0)
    80003066:	11c53023          	sd	t3,256(a0)
    8000306a:	11d53423          	sd	t4,264(a0)
    8000306e:	11e53823          	sd	t5,272(a0)
    80003072:	11f53c23          	sd	t6,280(a0)
    80003076:	140022f3          	csrr	t0,sscratch
    8000307a:	06553823          	sd	t0,112(a0)
    8000307e:	00853103          	ld	sp,8(a0)
    80003082:	02053203          	ld	tp,32(a0)
    80003086:	01053283          	ld	t0,16(a0)
    8000308a:	00053303          	ld	t1,0(a0)
    8000308e:	12000073          	sfence.vma
    80003092:	18031073          	csrw	satp,t1
    80003096:	12000073          	sfence.vma
    8000309a:	8282                	jr	t0

000000008000309c <userret>:
    8000309c:	12000073          	sfence.vma
    800030a0:	18051073          	csrw	satp,a0
    800030a4:	12000073          	sfence.vma
    800030a8:	02000537          	lui	a0,0x2000
    800030ac:	357d                	addiw	a0,a0,-1
    800030ae:	0536                	slli	a0,a0,0xd
    800030b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800030b4:	03053103          	ld	sp,48(a0)
    800030b8:	03853183          	ld	gp,56(a0)
    800030bc:	04053203          	ld	tp,64(a0)
    800030c0:	04853283          	ld	t0,72(a0)
    800030c4:	05053303          	ld	t1,80(a0)
    800030c8:	05853383          	ld	t2,88(a0)
    800030cc:	7120                	ld	s0,96(a0)
    800030ce:	7524                	ld	s1,104(a0)
    800030d0:	7d2c                	ld	a1,120(a0)
    800030d2:	6150                	ld	a2,128(a0)
    800030d4:	6554                	ld	a3,136(a0)
    800030d6:	6958                	ld	a4,144(a0)
    800030d8:	6d5c                	ld	a5,152(a0)
    800030da:	0a053803          	ld	a6,160(a0)
    800030de:	0a853883          	ld	a7,168(a0)
    800030e2:	0b053903          	ld	s2,176(a0)
    800030e6:	0b853983          	ld	s3,184(a0)
    800030ea:	0c053a03          	ld	s4,192(a0)
    800030ee:	0c853a83          	ld	s5,200(a0)
    800030f2:	0d053b03          	ld	s6,208(a0)
    800030f6:	0d853b83          	ld	s7,216(a0)
    800030fa:	0e053c03          	ld	s8,224(a0)
    800030fe:	0e853c83          	ld	s9,232(a0)
    80003102:	0f053d03          	ld	s10,240(a0)
    80003106:	0f853d83          	ld	s11,248(a0)
    8000310a:	10053e03          	ld	t3,256(a0)
    8000310e:	10853e83          	ld	t4,264(a0)
    80003112:	11053f03          	ld	t5,272(a0)
    80003116:	11853f83          	ld	t6,280(a0)
    8000311a:	7928                	ld	a0,112(a0)
    8000311c:	10200073          	sret
	...
