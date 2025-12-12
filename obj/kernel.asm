
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00097517          	auipc	a0,0x97
ffffffffc020004e:	2d650513          	addi	a0,a0,726 # ffffffffc0297320 <buf>
ffffffffc0200052:	0009b617          	auipc	a2,0x9b
ffffffffc0200056:	77e60613          	addi	a2,a2,1918 # ffffffffc029b7d0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0209ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	708050ef          	jal	ffffffffc020576a <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	72a58593          	addi	a1,a1,1834 # ffffffffc0205798 <etext+0x4>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	74250513          	addi	a0,a0,1858 # ffffffffc02057b8 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6e4020ef          	jal	ffffffffc020276a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	1d1030ef          	jal	ffffffffc0203a62 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	61f040ef          	jal	ffffffffc0204eb4 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7b3040ef          	jal	ffffffffc0205054 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00005517          	auipc	a0,0x5
ffffffffc02000ba:	70a50513          	addi	a0,a0,1802 # ffffffffc02057c0 <etext+0x2c>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	00097997          	auipc	s3,0x97
ffffffffc02000ca:	25a98993          	addi	s3,s3,602 # ffffffffc0297320 <buf>
        c = getchar();
ffffffffc02000ce:	148000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	11a000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	00097517          	auipc	a0,0x97
ffffffffc0200144:	1e050513          	addi	a0,a0,480 # ffffffffc0297320 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	3e6000ef          	jal	ffffffffc0200548 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	1c8050ef          	jal	ffffffffc0205350 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	194050ef          	jal	ffffffffc0205350 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	a641                	j	ffffffffc0200548 <cons_putc>

ffffffffc02001ca <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ca:	1101                	addi	sp,sp,-32
ffffffffc02001cc:	e822                	sd	s0,16(sp)
ffffffffc02001ce:	ec06                	sd	ra,24(sp)
ffffffffc02001d0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d2:	00054503          	lbu	a0,0(a0)
ffffffffc02001d6:	c51d                	beqz	a0,ffffffffc0200204 <cputs+0x3a>
ffffffffc02001d8:	e426                	sd	s1,8(sp)
ffffffffc02001da:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001dc:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001de:	36a000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e2:	00044503          	lbu	a0,0(s0)
ffffffffc02001e6:	0405                	addi	s0,s0,1
ffffffffc02001e8:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ea:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001ec:	f96d                	bnez	a0,ffffffffc02001de <cputs+0x14>
    cons_putc(c);
ffffffffc02001ee:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f0:	0027841b          	addiw	s0,a5,2
ffffffffc02001f4:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001f6:	352000ef          	jal	ffffffffc0200548 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fa:	60e2                	ld	ra,24(sp)
ffffffffc02001fc:	8522                	mv	a0,s0
ffffffffc02001fe:	6442                	ld	s0,16(sp)
ffffffffc0200200:	6105                	addi	sp,sp,32
ffffffffc0200202:	8082                	ret
    cons_putc(c);
ffffffffc0200204:	4529                	li	a0,10
ffffffffc0200206:	342000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020a:	4405                	li	s0,1
}
ffffffffc020020c:	60e2                	ld	ra,24(sp)
ffffffffc020020e:	8522                	mv	a0,s0
ffffffffc0200210:	6442                	ld	s0,16(sp)
ffffffffc0200212:	6105                	addi	sp,sp,32
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200216:	1141                	addi	sp,sp,-16
ffffffffc0200218:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021a:	362000ef          	jal	ffffffffc020057c <cons_getc>
ffffffffc020021e:	dd75                	beqz	a0,ffffffffc020021a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	0141                	addi	sp,sp,16
ffffffffc0200224:	8082                	ret

ffffffffc0200226 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc0200226:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	00005517          	auipc	a0,0x5
ffffffffc020022c:	5a050513          	addi	a0,a0,1440 # ffffffffc02057c8 <etext+0x34>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00005517          	auipc	a0,0x5
ffffffffc0200242:	5aa50513          	addi	a0,a0,1450 # ffffffffc02057e8 <etext+0x54>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00005597          	auipc	a1,0x5
ffffffffc020024e:	54a58593          	addi	a1,a1,1354 # ffffffffc0205794 <etext>
ffffffffc0200252:	00005517          	auipc	a0,0x5
ffffffffc0200256:	5b650513          	addi	a0,a0,1462 # ffffffffc0205808 <etext+0x74>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	00097597          	auipc	a1,0x97
ffffffffc0200262:	0c258593          	addi	a1,a1,194 # ffffffffc0297320 <buf>
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	5c250513          	addi	a0,a0,1474 # ffffffffc0205828 <etext+0x94>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	0009b597          	auipc	a1,0x9b
ffffffffc0200276:	55e58593          	addi	a1,a1,1374 # ffffffffc029b7d0 <end>
ffffffffc020027a:	00005517          	auipc	a0,0x5
ffffffffc020027e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0205848 <etext+0xb4>
ffffffffc0200282:	f13ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200286:	00000717          	auipc	a4,0x0
ffffffffc020028a:	dc470713          	addi	a4,a4,-572 # ffffffffc020004a <kern_init>
ffffffffc020028e:	0009c797          	auipc	a5,0x9c
ffffffffc0200292:	94178793          	addi	a5,a5,-1727 # ffffffffc029bbcf <end+0x3ff>
ffffffffc0200296:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	5c250513          	addi	a0,a0,1474 # ffffffffc0205868 <etext+0xd4>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	b5d5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	5e460613          	addi	a2,a2,1508 # ffffffffc0205898 <etext+0x104>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	5f050513          	addi	a0,a0,1520 # ffffffffc02058b0 <etext+0x11c>
{
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	17c000ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002ce:	1101                	addi	sp,sp,-32
ffffffffc02002d0:	e822                	sd	s0,16(sp)
ffffffffc02002d2:	e426                	sd	s1,8(sp)
ffffffffc02002d4:	ec06                	sd	ra,24(sp)
ffffffffc02002d6:	00007417          	auipc	s0,0x7
ffffffffc02002da:	1f240413          	addi	s0,s0,498 # ffffffffc02074c8 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	23248493          	addi	s1,s1,562 # ffffffffc0207510 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00005517          	auipc	a0,0x5
ffffffffc02002ee:	5de50513          	addi	a0,a0,1502 # ffffffffc02058c8 <etext+0x134>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f2:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f4:	ea1ff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f8:	fe9417e3          	bne	s0,s1,ffffffffc02002e6 <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002fc:	60e2                	ld	ra,24(sp)
ffffffffc02002fe:	6442                	ld	s0,16(sp)
ffffffffc0200300:	64a2                	ld	s1,8(sp)
ffffffffc0200302:	4501                	li	a0,0
ffffffffc0200304:	6105                	addi	sp,sp,32
ffffffffc0200306:	8082                	ret

ffffffffc0200308 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200308:	1141                	addi	sp,sp,-16
ffffffffc020030a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020030c:	f1bff0ef          	jal	ffffffffc0200226 <print_kerninfo>
    return 0;
}
ffffffffc0200310:	60a2                	ld	ra,8(sp)
ffffffffc0200312:	4501                	li	a0,0
ffffffffc0200314:	0141                	addi	sp,sp,16
ffffffffc0200316:	8082                	ret

ffffffffc0200318 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200318:	1141                	addi	sp,sp,-16
ffffffffc020031a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020031c:	f97ff0ef          	jal	ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200320:	60a2                	ld	ra,8(sp)
ffffffffc0200322:	4501                	li	a0,0
ffffffffc0200324:	0141                	addi	sp,sp,16
ffffffffc0200326:	8082                	ret

ffffffffc0200328 <kmonitor>:
{
ffffffffc0200328:	7131                	addi	sp,sp,-192
ffffffffc020032a:	e952                	sd	s4,144(sp)
ffffffffc020032c:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032e:	00005517          	auipc	a0,0x5
ffffffffc0200332:	5aa50513          	addi	a0,a0,1450 # ffffffffc02058d8 <etext+0x144>
{
ffffffffc0200336:	fd06                	sd	ra,184(sp)
ffffffffc0200338:	f922                	sd	s0,176(sp)
ffffffffc020033a:	f526                	sd	s1,168(sp)
ffffffffc020033c:	ed4e                	sd	s3,152(sp)
ffffffffc020033e:	e556                	sd	s5,136(sp)
ffffffffc0200340:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200342:	e53ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200346:	00005517          	auipc	a0,0x5
ffffffffc020034a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0205900 <etext+0x16c>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	16ca8a93          	addi	s5,s5,364 # ffffffffc02074c8 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	5c250513          	addi	a0,a0,1474 # ffffffffc0205928 <etext+0x194>
ffffffffc020036e:	d39ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200372:	842a                	mv	s0,a0
ffffffffc0200374:	d96d                	beqz	a0,ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200376:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020037c:	e99d                	bnez	a1,ffffffffc02003b2 <kmonitor+0x8a>
    int argc = 0;
ffffffffc020037e:	8b26                	mv	s6,s1
    if (argc == 0)
ffffffffc0200380:	fe0b03e3          	beqz	s6,ffffffffc0200366 <kmonitor+0x3e>
ffffffffc0200384:	00007497          	auipc	s1,0x7
ffffffffc0200388:	14448493          	addi	s1,s1,324 # ffffffffc02074c8 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	36a050ef          	jal	ffffffffc02056fc <strcmp>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200396:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200398:	c149                	beqz	a0,ffffffffc020041a <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020039a:	2405                	addiw	s0,s0,1
ffffffffc020039c:	04e1                	addi	s1,s1,24
ffffffffc020039e:	fef418e3          	bne	s0,a5,ffffffffc020038e <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a2:	6582                	ld	a1,0(sp)
ffffffffc02003a4:	00005517          	auipc	a0,0x5
ffffffffc02003a8:	5b450513          	addi	a0,a0,1460 # ffffffffc0205958 <etext+0x1c4>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00005517          	auipc	a0,0x5
ffffffffc02003b6:	57e50513          	addi	a0,a0,1406 # ffffffffc0205930 <etext+0x19c>
ffffffffc02003ba:	39e050ef          	jal	ffffffffc0205758 <strchr>
ffffffffc02003be:	c901                	beqz	a0,ffffffffc02003ce <kmonitor+0xa6>
ffffffffc02003c0:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc02003c4:	00040023          	sb	zero,0(s0)
ffffffffc02003c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ca:	d9d5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003cc:	b7dd                	j	ffffffffc02003b2 <kmonitor+0x8a>
        if (*buf == '\0')
ffffffffc02003ce:	00044783          	lbu	a5,0(s0)
ffffffffc02003d2:	d7d5                	beqz	a5,ffffffffc020037e <kmonitor+0x56>
        if (argc == MAXARGS - 1)
ffffffffc02003d4:	03348b63          	beq	s1,s3,ffffffffc020040a <kmonitor+0xe2>
        argv[argc++] = buf;
ffffffffc02003d8:	00349793          	slli	a5,s1,0x3
ffffffffc02003dc:	978a                	add	a5,a5,sp
ffffffffc02003de:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e0:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc02003e4:	2485                	addiw	s1,s1,1
ffffffffc02003e6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e8:	e591                	bnez	a1,ffffffffc02003f4 <kmonitor+0xcc>
ffffffffc02003ea:	bf59                	j	ffffffffc0200380 <kmonitor+0x58>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc02003f0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003f2:	d5d1                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003f4:	00005517          	auipc	a0,0x5
ffffffffc02003f8:	53c50513          	addi	a0,a0,1340 # ffffffffc0205930 <etext+0x19c>
ffffffffc02003fc:	35c050ef          	jal	ffffffffc0205758 <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00005517          	auipc	a0,0x5
ffffffffc0200410:	52c50513          	addi	a0,a0,1324 # ffffffffc0205938 <etext+0x1a4>
ffffffffc0200414:	d81ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200418:	b7c1                	j	ffffffffc02003d8 <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97d6                	add	a5,a5,s5
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042a:	8652                	mv	a2,s4
ffffffffc020042c:	002c                	addi	a1,sp,8
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200430:	f2055be3          	bgez	a0,ffffffffc0200366 <kmonitor+0x3e>
}
ffffffffc0200434:	70ea                	ld	ra,184(sp)
ffffffffc0200436:	744a                	ld	s0,176(sp)
ffffffffc0200438:	74aa                	ld	s1,168(sp)
ffffffffc020043a:	69ea                	ld	s3,152(sp)
ffffffffc020043c:	6a4a                	ld	s4,144(sp)
ffffffffc020043e:	6aaa                	ld	s5,136(sp)
ffffffffc0200440:	6b0a                	ld	s6,128(sp)
ffffffffc0200442:	6129                	addi	sp,sp,192
ffffffffc0200444:	8082                	ret

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc0200446:	0009b317          	auipc	t1,0x9b
ffffffffc020044a:	30233303          	ld	t1,770(t1) # ffffffffc029b748 <is_panic>
{
ffffffffc020044e:	715d                	addi	sp,sp,-80
ffffffffc0200450:	ec06                	sd	ra,24(sp)
ffffffffc0200452:	f436                	sd	a3,40(sp)
ffffffffc0200454:	f83a                	sd	a4,48(sp)
ffffffffc0200456:	fc3e                	sd	a5,56(sp)
ffffffffc0200458:	e0c2                	sd	a6,64(sp)
ffffffffc020045a:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc020045c:	02031e63          	bnez	t1,ffffffffc0200498 <__panic+0x52>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200460:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200462:	103c                	addi	a5,sp,40
ffffffffc0200464:	e822                	sd	s0,16(sp)
ffffffffc0200466:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200468:	862e                	mv	a2,a1
ffffffffc020046a:	85aa                	mv	a1,a0
ffffffffc020046c:	00005517          	auipc	a0,0x5
ffffffffc0200470:	59450513          	addi	a0,a0,1428 # ffffffffc0205a00 <etext+0x26c>
    is_panic = 1;
ffffffffc0200474:	0009b697          	auipc	a3,0x9b
ffffffffc0200478:	2ce6ba23          	sd	a4,724(a3) # ffffffffc029b748 <is_panic>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d17ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cefff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00005517          	auipc	a0,0x5
ffffffffc020048e:	59650513          	addi	a0,a0,1430 # ffffffffc0205a20 <etext+0x28c>
ffffffffc0200492:	d03ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200496:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200498:	4501                	li	a0,0
ffffffffc020049a:	4581                	li	a1,0
ffffffffc020049c:	4601                	li	a2,0
ffffffffc020049e:	48a1                	li	a7,8
ffffffffc02004a0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a4:	460000ef          	jal	ffffffffc0200904 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	e7fff0ef          	jal	ffffffffc0200328 <kmonitor>
    while (1)
ffffffffc02004ae:	bfed                	j	ffffffffc02004a8 <__panic+0x62>

ffffffffc02004b0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004b0:	715d                	addi	sp,sp,-80
ffffffffc02004b2:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	02810313          	addi	t1,sp,40
{
ffffffffc02004b8:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ba:	862e                	mv	a2,a1
ffffffffc02004bc:	85aa                	mv	a1,a0
ffffffffc02004be:	00005517          	auipc	a0,0x5
ffffffffc02004c2:	56a50513          	addi	a0,a0,1386 # ffffffffc0205a28 <etext+0x294>
{
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
ffffffffc02004c8:	f436                	sd	a3,40(sp)
ffffffffc02004ca:	f83a                	sd	a4,48(sp)
ffffffffc02004cc:	fc3e                	sd	a5,56(sp)
ffffffffc02004ce:	e0c2                	sd	a6,64(sp)
ffffffffc02004d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d2:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d4:	cc1ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004d8:	65a2                	ld	a1,8(sp)
ffffffffc02004da:	8522                	mv	a0,s0
ffffffffc02004dc:	c99ff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004e0:	00005517          	auipc	a0,0x5
ffffffffc02004e4:	54050513          	addi	a0,a0,1344 # ffffffffc0205a20 <etext+0x28c>
ffffffffc02004e8:	cadff0ef          	jal	ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc02004ec:	60e2                	ld	ra,24(sp)
ffffffffc02004ee:	6442                	ld	s0,16(sp)
ffffffffc02004f0:	6161                	addi	sp,sp,80
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f4:	67e1                	lui	a5,0x18
ffffffffc02004f6:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xe4c8>
ffffffffc02004fa:	0009b717          	auipc	a4,0x9b
ffffffffc02004fe:	24f73b23          	sd	a5,598(a4) # ffffffffc029b750 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200502:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200506:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200508:	953e                	add	a0,a0,a5
ffffffffc020050a:	4601                	li	a2,0
ffffffffc020050c:	4881                	li	a7,0
ffffffffc020050e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200512:	02000793          	li	a5,32
ffffffffc0200516:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051a:	00005517          	auipc	a0,0x5
ffffffffc020051e:	52e50513          	addi	a0,a0,1326 # ffffffffc0205a48 <etext+0x2b4>
    ticks = 0;
ffffffffc0200522:	0009b797          	auipc	a5,0x9b
ffffffffc0200526:	2207bb23          	sd	zero,566(a5) # ffffffffc029b758 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052a:	b1ad                	j	ffffffffc0200194 <cprintf>

ffffffffc020052c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020052c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200530:	0009b797          	auipc	a5,0x9b
ffffffffc0200534:	2207b783          	ld	a5,544(a5) # ffffffffc029b750 <timebase>
ffffffffc0200538:	4581                	li	a1,0
ffffffffc020053a:	4601                	li	a2,0
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
ffffffffc0200544:	8082                	ret

ffffffffc0200546 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200546:	8082                	ret

ffffffffc0200548 <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200548:	100027f3          	csrr	a5,sstatus
ffffffffc020054c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020054e:	0ff57513          	zext.b	a0,a0
ffffffffc0200552:	e799                	bnez	a5,ffffffffc0200560 <cons_putc+0x18>
ffffffffc0200554:	4581                	li	a1,0
ffffffffc0200556:	4601                	li	a2,0
ffffffffc0200558:	4885                	li	a7,1
ffffffffc020055a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020055e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200560:	1101                	addi	sp,sp,-32
ffffffffc0200562:	ec06                	sd	ra,24(sp)
ffffffffc0200564:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200566:	39e000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020056a:	6522                	ld	a0,8(sp)
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4885                	li	a7,1
ffffffffc0200572:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200576:	60e2                	ld	ra,24(sp)
ffffffffc0200578:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc020057a:	a651                	j	ffffffffc02008fe <intr_enable>

ffffffffc020057c <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020057c:	100027f3          	csrr	a5,sstatus
ffffffffc0200580:	8b89                	andi	a5,a5,2
ffffffffc0200582:	eb89                	bnez	a5,ffffffffc0200594 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4889                	li	a7,2
ffffffffc020058c:	00000073          	ecall
ffffffffc0200590:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200592:	8082                	ret
int cons_getc(void) {
ffffffffc0200594:	1101                	addi	sp,sp,-32
ffffffffc0200596:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200598:	36c000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020059c:	4501                	li	a0,0
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4889                	li	a7,2
ffffffffc02005a4:	00000073          	ecall
ffffffffc02005a8:	2501                	sext.w	a0,a0
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ac:	352000ef          	jal	ffffffffc02008fe <intr_enable>
}
ffffffffc02005b0:	60e2                	ld	ra,24(sp)
ffffffffc02005b2:	6522                	ld	a0,8(sp)
ffffffffc02005b4:	6105                	addi	sp,sp,32
ffffffffc02005b6:	8082                	ret

ffffffffc02005b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b8:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005ba:	00005517          	auipc	a0,0x5
ffffffffc02005be:	4ae50513          	addi	a0,a0,1198 # ffffffffc0205a68 <etext+0x2d4>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	4a650513          	addi	a0,a0,1190 # ffffffffc0205a78 <etext+0x2e4>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	4a050513          	addi	a0,a0,1184 # ffffffffc0205a88 <etext+0x2f4>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	4aa50513          	addi	a0,a0,1194 # ffffffffc0205aa0 <etext+0x30c>
    if (boot_dtb == 0) {
ffffffffc02005fe:	10070163          	beqz	a4,ffffffffc0200700 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200602:	57f5                	li	a5,-3
ffffffffc0200604:	07fa                	slli	a5,a5,0x1e
ffffffffc0200606:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200608:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020060a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020060e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe4471d>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200612:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200616:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8e49                	or	a2,a2,a0
ffffffffc020062a:	0ff7f793          	zext.b	a5,a5
ffffffffc020062e:	8dd1                	or	a1,a1,a2
ffffffffc0200630:	07a2                	slli	a5,a5,0x8
ffffffffc0200632:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200634:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200638:	0cd59863          	bne	a1,a3,ffffffffc0200708 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020063c:	4710                	lw	a2,8(a4)
ffffffffc020063e:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200640:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200646:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020064e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200652:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200656:	0186959b          	slliw	a1,a3,0x18
ffffffffc020065a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200662:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200666:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020066a:	01c56533          	or	a0,a0,t3
ffffffffc020066e:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0ff6f693          	zext.b	a3,a3
ffffffffc0200682:	8c49                	or	s0,s0,a0
ffffffffc0200684:	0622                	slli	a2,a2,0x8
ffffffffc0200686:	8fcd                	or	a5,a5,a1
ffffffffc0200688:	06a2                	slli	a3,a3,0x8
ffffffffc020068a:	8c51                	or	s0,s0,a2
ffffffffc020068c:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068e:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200690:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200692:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200694:	9381                	srli	a5,a5,0x20
ffffffffc0200696:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200698:	4301                	li	t1,0
        switch (token) {
ffffffffc020069a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020069c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020069e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc02006a2:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a4:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006aa:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	8ed1                	or	a3,a3,a2
ffffffffc02006c0:	0ff77713          	zext.b	a4,a4
ffffffffc02006c4:	8fd5                	or	a5,a5,a3
ffffffffc02006c6:	0722                	slli	a4,a4,0x8
ffffffffc02006c8:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006ca:	05178763          	beq	a5,a7,ffffffffc0200718 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ce:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006d0:	00f8e963          	bltu	a7,a5,ffffffffc02006e2 <dtb_init+0x12a>
ffffffffc02006d4:	07c78d63          	beq	a5,t3,ffffffffc020074e <dtb_init+0x196>
ffffffffc02006d8:	4709                	li	a4,2
ffffffffc02006da:	00e79763          	bne	a5,a4,ffffffffc02006e8 <dtb_init+0x130>
ffffffffc02006de:	4301                	li	t1,0
ffffffffc02006e0:	b7d1                	j	ffffffffc02006a4 <dtb_init+0xec>
ffffffffc02006e2:	4711                	li	a4,4
ffffffffc02006e4:	fce780e3          	beq	a5,a4,ffffffffc02006a4 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e8:	00005517          	auipc	a0,0x5
ffffffffc02006ec:	48050513          	addi	a0,a0,1152 # ffffffffc0205b68 <etext+0x3d4>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	4a850513          	addi	a0,a0,1192 # ffffffffc0205ba0 <etext+0x40c>
}
ffffffffc0200700:	7402                	ld	s0,32(sp)
ffffffffc0200702:	70a2                	ld	ra,40(sp)
ffffffffc0200704:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200706:	b479                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200708:	7402                	ld	s0,32(sp)
ffffffffc020070a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020070c:	00005517          	auipc	a0,0x5
ffffffffc0200710:	3b450513          	addi	a0,a0,948 # ffffffffc0205ac0 <etext+0x32c>
}
ffffffffc0200714:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200716:	bcbd                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200718:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020071e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	8ed1                	or	a3,a3,a2
ffffffffc0200734:	0ff77713          	zext.b	a4,a4
ffffffffc0200738:	8fd5                	or	a5,a5,a3
ffffffffc020073a:	0722                	slli	a4,a4,0x8
ffffffffc020073c:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020073e:	04031463          	bnez	t1,ffffffffc0200786 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200742:	1782                	slli	a5,a5,0x20
ffffffffc0200744:	9381                	srli	a5,a5,0x20
ffffffffc0200746:	043d                	addi	s0,s0,15
ffffffffc0200748:	943e                	add	s0,s0,a5
ffffffffc020074a:	9871                	andi	s0,s0,-4
                break;
ffffffffc020074c:	bfa1                	j	ffffffffc02006a4 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc020074e:	8522                	mv	a0,s0
ffffffffc0200750:	e01a                	sd	t1,0(sp)
ffffffffc0200752:	765040ef          	jal	ffffffffc02056b6 <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	38c58593          	addi	a1,a1,908 # ffffffffc0205ae8 <etext+0x354>
ffffffffc0200764:	7cd040ef          	jal	ffffffffc0205730 <strncmp>
ffffffffc0200768:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020076a:	0411                	addi	s0,s0,4
ffffffffc020076c:	0004879b          	sext.w	a5,s1
ffffffffc0200770:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200776:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200778:	00a36333          	or	t1,t1,a0
                break;
ffffffffc020077c:	00ff0837          	lui	a6,0xff0
ffffffffc0200780:	488d                	li	a7,3
ffffffffc0200782:	4e05                	li	t3,1
ffffffffc0200784:	b705                	j	ffffffffc02006a4 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200786:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200788:	00005597          	auipc	a1,0x5
ffffffffc020078c:	36858593          	addi	a1,a1,872 # ffffffffc0205af0 <etext+0x35c>
ffffffffc0200790:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200792:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200796:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020079e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a6:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007aa:	8ed1                	or	a3,a3,a2
ffffffffc02007ac:	0ff77713          	zext.b	a4,a4
ffffffffc02007b0:	0722                	slli	a4,a4,0x8
ffffffffc02007b2:	8d55                	or	a0,a0,a3
ffffffffc02007b4:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b6:	1502                	slli	a0,a0,0x20
ffffffffc02007b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	954a                	add	a0,a0,s2
ffffffffc02007bc:	e01a                	sd	t1,0(sp)
ffffffffc02007be:	73f040ef          	jal	ffffffffc02056fc <strcmp>
ffffffffc02007c2:	67a2                	ld	a5,8(sp)
ffffffffc02007c4:	473d                	li	a4,15
ffffffffc02007c6:	6302                	ld	t1,0(sp)
ffffffffc02007c8:	00ff0837          	lui	a6,0xff0
ffffffffc02007cc:	488d                	li	a7,3
ffffffffc02007ce:	4e05                	li	t3,1
ffffffffc02007d0:	f6f779e3          	bgeu	a4,a5,ffffffffc0200742 <dtb_init+0x18a>
ffffffffc02007d4:	f53d                	bnez	a0,ffffffffc0200742 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d6:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007da:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007de:	00005517          	auipc	a0,0x5
ffffffffc02007e2:	31a50513          	addi	a0,a0,794 # ffffffffc0205af8 <etext+0x364>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ea:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007ee:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007f2:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007fe:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200802:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080e:	01037333          	and	t1,t1,a6
ffffffffc0200812:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200816:	01e5e5b3          	or	a1,a1,t5
ffffffffc020081a:	0ff7f793          	zext.b	a5,a5
ffffffffc020081e:	01de6e33          	or	t3,t3,t4
ffffffffc0200822:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200826:	01067633          	and	a2,a2,a6
ffffffffc020082a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020082e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	07a2                	slli	a5,a5,0x8
ffffffffc0200834:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200838:	0186df1b          	srliw	t5,a3,0x18
ffffffffc020083c:	01875e9b          	srliw	t4,a4,0x18
ffffffffc0200840:	8ddd                	or	a1,a1,a5
ffffffffc0200842:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200846:	0186979b          	slliw	a5,a3,0x18
ffffffffc020084a:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200862:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200866:	08a2                	slli	a7,a7,0x8
ffffffffc0200868:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020086c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200870:	0ff6f693          	zext.b	a3,a3
ffffffffc0200874:	01de6833          	or	a6,t3,t4
ffffffffc0200878:	0ff77713          	zext.b	a4,a4
ffffffffc020087c:	01166633          	or	a2,a2,a7
ffffffffc0200880:	0067e7b3          	or	a5,a5,t1
ffffffffc0200884:	06a2                	slli	a3,a3,0x8
ffffffffc0200886:	01046433          	or	s0,s0,a6
ffffffffc020088a:	0722                	slli	a4,a4,0x8
ffffffffc020088c:	8fd5                	or	a5,a5,a3
ffffffffc020088e:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	1582                	slli	a1,a1,0x20
ffffffffc0200892:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200896:	9201                	srli	a2,a2,0x20
ffffffffc0200898:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020089a:	1402                	slli	s0,s0,0x20
ffffffffc020089c:	00b7e4b3          	or	s1,a5,a1
ffffffffc02008a0:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008a2:	8f3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a6:	85a6                	mv	a1,s1
ffffffffc02008a8:	00005517          	auipc	a0,0x5
ffffffffc02008ac:	27050513          	addi	a0,a0,624 # ffffffffc0205b18 <etext+0x384>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	27650513          	addi	a0,a0,630 # ffffffffc0205b30 <etext+0x39c>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	28450513          	addi	a0,a0,644 # ffffffffc0205b50 <etext+0x3bc>
ffffffffc02008d4:	8c1ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc02008d8:	0009b797          	auipc	a5,0x9b
ffffffffc02008dc:	e897b823          	sd	s1,-368(a5) # ffffffffc029b768 <memory_base>
        memory_size = mem_size;
ffffffffc02008e0:	0009b797          	auipc	a5,0x9b
ffffffffc02008e4:	e887b023          	sd	s0,-384(a5) # ffffffffc029b760 <memory_size>
ffffffffc02008e8:	b531                	j	ffffffffc02006f4 <dtb_init+0x13c>

ffffffffc02008ea <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008ea:	0009b517          	auipc	a0,0x9b
ffffffffc02008ee:	e7e53503          	ld	a0,-386(a0) # ffffffffc029b768 <memory_base>
ffffffffc02008f2:	8082                	ret

ffffffffc02008f4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008f4:	0009b517          	auipc	a0,0x9b
ffffffffc02008f8:	e6c53503          	ld	a0,-404(a0) # ffffffffc029b760 <memory_size>
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200904:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200908:	8082                	ret

ffffffffc020090a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020090a:	8082                	ret

ffffffffc020090c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020090c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200910:	00000797          	auipc	a5,0x0
ffffffffc0200914:	4e078793          	addi	a5,a5,1248 # ffffffffc0200df0 <__alltraps>
ffffffffc0200918:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020091c:	000407b7          	lui	a5,0x40
ffffffffc0200920:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200924:	8082                	ret

ffffffffc0200926 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200926:	610c                	ld	a1,0(a0)
{
ffffffffc0200928:	1141                	addi	sp,sp,-16
ffffffffc020092a:	e022                	sd	s0,0(sp)
ffffffffc020092c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020092e:	00005517          	auipc	a0,0x5
ffffffffc0200932:	28a50513          	addi	a0,a0,650 # ffffffffc0205bb8 <etext+0x424>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	29250513          	addi	a0,a0,658 # ffffffffc0205bd0 <etext+0x43c>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	29c50513          	addi	a0,a0,668 # ffffffffc0205be8 <etext+0x454>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	2a650513          	addi	a0,a0,678 # ffffffffc0205c00 <etext+0x46c>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	2b050513          	addi	a0,a0,688 # ffffffffc0205c18 <etext+0x484>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	2ba50513          	addi	a0,a0,698 # ffffffffc0205c30 <etext+0x49c>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	2c450513          	addi	a0,a0,708 # ffffffffc0205c48 <etext+0x4b4>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	2ce50513          	addi	a0,a0,718 # ffffffffc0205c60 <etext+0x4cc>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	2d850513          	addi	a0,a0,728 # ffffffffc0205c78 <etext+0x4e4>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	2e250513          	addi	a0,a0,738 # ffffffffc0205c90 <etext+0x4fc>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	2ec50513          	addi	a0,a0,748 # ffffffffc0205ca8 <etext+0x514>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	2f650513          	addi	a0,a0,758 # ffffffffc0205cc0 <etext+0x52c>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	30050513          	addi	a0,a0,768 # ffffffffc0205cd8 <etext+0x544>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	30a50513          	addi	a0,a0,778 # ffffffffc0205cf0 <etext+0x55c>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	31450513          	addi	a0,a0,788 # ffffffffc0205d08 <etext+0x574>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	31e50513          	addi	a0,a0,798 # ffffffffc0205d20 <etext+0x58c>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	32850513          	addi	a0,a0,808 # ffffffffc0205d38 <etext+0x5a4>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	33250513          	addi	a0,a0,818 # ffffffffc0205d50 <etext+0x5bc>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	33c50513          	addi	a0,a0,828 # ffffffffc0205d68 <etext+0x5d4>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	34650513          	addi	a0,a0,838 # ffffffffc0205d80 <etext+0x5ec>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	35050513          	addi	a0,a0,848 # ffffffffc0205d98 <etext+0x604>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	35a50513          	addi	a0,a0,858 # ffffffffc0205db0 <etext+0x61c>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	36450513          	addi	a0,a0,868 # ffffffffc0205dc8 <etext+0x634>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	36e50513          	addi	a0,a0,878 # ffffffffc0205de0 <etext+0x64c>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	37850513          	addi	a0,a0,888 # ffffffffc0205df8 <etext+0x664>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	38250513          	addi	a0,a0,898 # ffffffffc0205e10 <etext+0x67c>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	38c50513          	addi	a0,a0,908 # ffffffffc0205e28 <etext+0x694>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	39650513          	addi	a0,a0,918 # ffffffffc0205e40 <etext+0x6ac>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	3a050513          	addi	a0,a0,928 # ffffffffc0205e58 <etext+0x6c4>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	3aa50513          	addi	a0,a0,938 # ffffffffc0205e70 <etext+0x6dc>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	3b450513          	addi	a0,a0,948 # ffffffffc0205e88 <etext+0x6f4>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	3ba50513          	addi	a0,a0,954 # ffffffffc0205ea0 <etext+0x70c>
}
ffffffffc0200aee:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af0:	ea4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200af4 <print_trapframe>:
{
ffffffffc0200af4:	1141                	addi	sp,sp,-16
ffffffffc0200af6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af8:	85aa                	mv	a1,a0
{
ffffffffc0200afa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200afc:	00005517          	auipc	a0,0x5
ffffffffc0200b00:	3bc50513          	addi	a0,a0,956 # ffffffffc0205eb8 <etext+0x724>
{
ffffffffc0200b04:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b06:	e8eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b0a:	8522                	mv	a0,s0
ffffffffc0200b0c:	e1bff0ef          	jal	ffffffffc0200926 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b10:	10043583          	ld	a1,256(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	3bc50513          	addi	a0,a0,956 # ffffffffc0205ed0 <etext+0x73c>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	3c450513          	addi	a0,a0,964 # ffffffffc0205ee8 <etext+0x754>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	3cc50513          	addi	a0,a0,972 # ffffffffc0205f00 <etext+0x76c>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	3c850513          	addi	a0,a0,968 # ffffffffc0205f10 <etext+0x77c>
}
ffffffffc0200b50:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b52:	e42ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b56 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    static size_t ticks = 0;
    switch (cause)
ffffffffc0200b56:	11853783          	ld	a5,280(a0)
ffffffffc0200b5a:	472d                	li	a4,11
ffffffffc0200b5c:	0786                	slli	a5,a5,0x1
ffffffffc0200b5e:	8385                	srli	a5,a5,0x1
ffffffffc0200b60:	0af76963          	bltu	a4,a5,ffffffffc0200c12 <interrupt_handler+0xbc>
ffffffffc0200b64:	00007717          	auipc	a4,0x7
ffffffffc0200b68:	9ac70713          	addi	a4,a4,-1620 # ffffffffc0207510 <commands+0x48>
ffffffffc0200b6c:	078a                	slli	a5,a5,0x2
ffffffffc0200b6e:	97ba                	add	a5,a5,a4
ffffffffc0200b70:	439c                	lw	a5,0(a5)
ffffffffc0200b72:	97ba                	add	a5,a5,a4
ffffffffc0200b74:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	41250513          	addi	a0,a0,1042 # ffffffffc0205f88 <etext+0x7f4>
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	3e650513          	addi	a0,a0,998 # ffffffffc0205f68 <etext+0x7d4>
ffffffffc0200b8a:	e0aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	39a50513          	addi	a0,a0,922 # ffffffffc0205f28 <etext+0x794>
ffffffffc0200b96:	dfeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b9a:	00005517          	auipc	a0,0x5
ffffffffc0200b9e:	3ae50513          	addi	a0,a0,942 # ffffffffc0205f48 <etext+0x7b4>
ffffffffc0200ba2:	df2ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200ba6:	1141                	addi	sp,sp,-16
ffffffffc0200ba8:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
ffffffffc0200baa:	983ff0ef          	jal	ffffffffc020052c <clock_set_next_event>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200bae:	0009b697          	auipc	a3,0x9b
ffffffffc0200bb2:	bc26b683          	ld	a3,-1086(a3) # ffffffffc029b770 <ticks.0>
ffffffffc0200bb6:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200bba:	28f70713          	addi	a4,a4,655 # 28f5c28f <_binary_obj___user_exit_out_size+0x28f520b7>
ffffffffc0200bbe:	5c28f7b7          	lui	a5,0x5c28f
ffffffffc0200bc2:	5c378793          	addi	a5,a5,1475 # 5c28f5c3 <_binary_obj___user_exit_out_size+0x5c2853eb>
ffffffffc0200bc6:	0685                	addi	a3,a3,1
ffffffffc0200bc8:	1702                	slli	a4,a4,0x20
ffffffffc0200bca:	973e                	add	a4,a4,a5
ffffffffc0200bcc:	0026d793          	srli	a5,a3,0x2
ffffffffc0200bd0:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200bd4:	06400713          	li	a4,100
ffffffffc0200bd8:	0009b617          	auipc	a2,0x9b
ffffffffc0200bdc:	b8d63c23          	sd	a3,-1128(a2) # ffffffffc029b770 <ticks.0>
ffffffffc0200be0:	8389                	srli	a5,a5,0x2
ffffffffc0200be2:	02e787b3          	mul	a5,a5,a4
ffffffffc0200be6:	00f69d63          	bne	a3,a5,ffffffffc0200c00 <interrupt_handler+0xaa>
            if (current != NULL && current->state == PROC_RUNNABLE) {
ffffffffc0200bea:	0009b797          	auipc	a5,0x9b
ffffffffc0200bee:	bce7b783          	ld	a5,-1074(a5) # ffffffffc029b7b8 <current>
ffffffffc0200bf2:	c799                	beqz	a5,ffffffffc0200c00 <interrupt_handler+0xaa>
ffffffffc0200bf4:	4394                	lw	a3,0(a5)
ffffffffc0200bf6:	4709                	li	a4,2
ffffffffc0200bf8:	00e69463          	bne	a3,a4,ffffffffc0200c00 <interrupt_handler+0xaa>
                current->need_resched = 1;
ffffffffc0200bfc:	4705                	li	a4,1
ffffffffc0200bfe:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c00:	60a2                	ld	ra,8(sp)
ffffffffc0200c02:	0141                	addi	sp,sp,16
ffffffffc0200c04:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c06:	00005517          	auipc	a0,0x5
ffffffffc0200c0a:	3a250513          	addi	a0,a0,930 # ffffffffc0205fa8 <etext+0x814>
ffffffffc0200c0e:	d86ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c12:	b5cd                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200c14 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c14:	11853783          	ld	a5,280(a0)
ffffffffc0200c18:	473d                	li	a4,15
ffffffffc0200c1a:	14f76763          	bltu	a4,a5,ffffffffc0200d68 <exception_handler+0x154>
ffffffffc0200c1e:	00007717          	auipc	a4,0x7
ffffffffc0200c22:	92270713          	addi	a4,a4,-1758 # ffffffffc0207540 <commands+0x78>
ffffffffc0200c26:	078a                	slli	a5,a5,0x2
ffffffffc0200c28:	97ba                	add	a5,a5,a4
ffffffffc0200c2a:	439c                	lw	a5,0(a5)
{
ffffffffc0200c2c:	1101                	addi	sp,sp,-32
ffffffffc0200c2e:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c30:	97ba                	add	a5,a5,a4
ffffffffc0200c32:	86aa                	mv	a3,a0
ffffffffc0200c34:	8782                	jr	a5
ffffffffc0200c36:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c38:	00005517          	auipc	a0,0x5
ffffffffc0200c3c:	47850513          	addi	a0,a0,1144 # ffffffffc02060b0 <etext+0x91c>
ffffffffc0200c40:	d54ff0ef          	jal	ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200c44:	66a2                	ld	a3,8(sp)
ffffffffc0200c46:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c4a:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c4c:	0791                	addi	a5,a5,4
ffffffffc0200c4e:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c52:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c54:	6040406f          	j	ffffffffc0205258 <syscall>
}
ffffffffc0200c58:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c5a:	00005517          	auipc	a0,0x5
ffffffffc0200c5e:	47650513          	addi	a0,a0,1142 # ffffffffc02060d0 <etext+0x93c>
}
ffffffffc0200c62:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c64:	d30ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c68:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c6a:	00005517          	auipc	a0,0x5
ffffffffc0200c6e:	48650513          	addi	a0,a0,1158 # ffffffffc02060f0 <etext+0x95c>
}
ffffffffc0200c72:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c74:	d20ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c78:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c7a:	00005517          	auipc	a0,0x5
ffffffffc0200c7e:	49650513          	addi	a0,a0,1174 # ffffffffc0206110 <etext+0x97c>
}
ffffffffc0200c82:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c84:	d10ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c88:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c8a:	00005517          	auipc	a0,0x5
ffffffffc0200c8e:	49e50513          	addi	a0,a0,1182 # ffffffffc0206128 <etext+0x994>
}
ffffffffc0200c92:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c98:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200c9a:	00005517          	auipc	a0,0x5
ffffffffc0200c9e:	4a650513          	addi	a0,a0,1190 # ffffffffc0206140 <etext+0x9ac>
}
ffffffffc0200ca2:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200ca4:	cf0ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200ca8:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200caa:	00005517          	auipc	a0,0x5
ffffffffc0200cae:	31e50513          	addi	a0,a0,798 # ffffffffc0205fc8 <etext+0x834>
}
ffffffffc0200cb2:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cb4:	ce0ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cb8:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cba:	00005517          	auipc	a0,0x5
ffffffffc0200cbe:	32e50513          	addi	a0,a0,814 # ffffffffc0205fe8 <etext+0x854>
}
ffffffffc0200cc2:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cc4:	cd0ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cc8:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200cca:	00005517          	auipc	a0,0x5
ffffffffc0200cce:	33e50513          	addi	a0,a0,830 # ffffffffc0206008 <etext+0x874>
}
ffffffffc0200cd2:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cd4:	cc0ff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200cd8:	e42a                	sd	a0,8(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cda:	00005517          	auipc	a0,0x5
ffffffffc0200cde:	34650513          	addi	a0,a0,838 # ffffffffc0206020 <etext+0x88c>
ffffffffc0200ce2:	cb2ff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200ce6:	66a2                	ld	a3,8(sp)
ffffffffc0200ce8:	47a9                	li	a5,10
ffffffffc0200cea:	66d8                	ld	a4,136(a3)
ffffffffc0200cec:	04f70c63          	beq	a4,a5,ffffffffc0200d44 <exception_handler+0x130>
}
ffffffffc0200cf0:	60e2                	ld	ra,24(sp)
ffffffffc0200cf2:	6105                	addi	sp,sp,32
ffffffffc0200cf4:	8082                	ret
ffffffffc0200cf6:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200cf8:	00005517          	auipc	a0,0x5
ffffffffc0200cfc:	33850513          	addi	a0,a0,824 # ffffffffc0206030 <etext+0x89c>
}
ffffffffc0200d00:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200d02:	c92ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d06:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200d08:	00005517          	auipc	a0,0x5
ffffffffc0200d0c:	34850513          	addi	a0,a0,840 # ffffffffc0206050 <etext+0x8bc>
}
ffffffffc0200d10:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d12:	c82ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d16:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d18:	00005517          	auipc	a0,0x5
ffffffffc0200d1c:	38050513          	addi	a0,a0,896 # ffffffffc0206098 <etext+0x904>
}
ffffffffc0200d20:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d22:	c72ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d26:	60e2                	ld	ra,24(sp)
ffffffffc0200d28:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d2a:	b3e9                	j	ffffffffc0200af4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d2c:	00005617          	auipc	a2,0x5
ffffffffc0200d30:	33c60613          	addi	a2,a2,828 # ffffffffc0206068 <etext+0x8d4>
ffffffffc0200d34:	0c000593          	li	a1,192
ffffffffc0200d38:	00005517          	auipc	a0,0x5
ffffffffc0200d3c:	34850513          	addi	a0,a0,840 # ffffffffc0206080 <etext+0x8ec>
ffffffffc0200d40:	f06ff0ef          	jal	ffffffffc0200446 <__panic>
            tf->epc += 4;
ffffffffc0200d44:	1086b783          	ld	a5,264(a3)
ffffffffc0200d48:	0791                	addi	a5,a5,4
ffffffffc0200d4a:	10f6b423          	sd	a5,264(a3)
            syscall();
ffffffffc0200d4e:	50a040ef          	jal	ffffffffc0205258 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d52:	0009b717          	auipc	a4,0x9b
ffffffffc0200d56:	a6673703          	ld	a4,-1434(a4) # ffffffffc029b7b8 <current>
ffffffffc0200d5a:	6522                	ld	a0,8(sp)
}
ffffffffc0200d5c:	60e2                	ld	ra,24(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d5e:	6b0c                	ld	a1,16(a4)
ffffffffc0200d60:	6789                	lui	a5,0x2
ffffffffc0200d62:	95be                	add	a1,a1,a5
}
ffffffffc0200d64:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d66:	aaa1                	j	ffffffffc0200ebe <kernel_execve_ret>
        print_trapframe(tf);
ffffffffc0200d68:	b371                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200d6a <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d6a:	0009b717          	auipc	a4,0x9b
ffffffffc0200d6e:	a4e73703          	ld	a4,-1458(a4) # ffffffffc029b7b8 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d72:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d76:	cf21                	beqz	a4,ffffffffc0200dce <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d78:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d7c:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d80:	1101                	addi	sp,sp,-32
ffffffffc0200d82:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d84:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d88:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d8a:	e432                	sd	a2,8(sp)
ffffffffc0200d8c:	e042                	sd	a6,0(sp)
ffffffffc0200d8e:	0205c763          	bltz	a1,ffffffffc0200dbc <trap+0x52>
        exception_handler(tf);
ffffffffc0200d92:	e83ff0ef          	jal	ffffffffc0200c14 <exception_handler>
ffffffffc0200d96:	6622                	ld	a2,8(sp)
ffffffffc0200d98:	6802                	ld	a6,0(sp)
ffffffffc0200d9a:	0009b697          	auipc	a3,0x9b
ffffffffc0200d9e:	a1e68693          	addi	a3,a3,-1506 # ffffffffc029b7b8 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200da2:	6298                	ld	a4,0(a3)
ffffffffc0200da4:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200da8:	e619                	bnez	a2,ffffffffc0200db6 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200daa:	0b072783          	lw	a5,176(a4)
ffffffffc0200dae:	8b85                	andi	a5,a5,1
ffffffffc0200db0:	e79d                	bnez	a5,ffffffffc0200dde <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200db2:	6f1c                	ld	a5,24(a4)
ffffffffc0200db4:	e38d                	bnez	a5,ffffffffc0200dd6 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200db6:	60e2                	ld	ra,24(sp)
ffffffffc0200db8:	6105                	addi	sp,sp,32
ffffffffc0200dba:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200dbc:	d9bff0ef          	jal	ffffffffc0200b56 <interrupt_handler>
ffffffffc0200dc0:	6802                	ld	a6,0(sp)
ffffffffc0200dc2:	6622                	ld	a2,8(sp)
ffffffffc0200dc4:	0009b697          	auipc	a3,0x9b
ffffffffc0200dc8:	9f468693          	addi	a3,a3,-1548 # ffffffffc029b7b8 <current>
ffffffffc0200dcc:	bfd9                	j	ffffffffc0200da2 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dce:	0005c363          	bltz	a1,ffffffffc0200dd4 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200dd2:	b589                	j	ffffffffc0200c14 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dd4:	b349                	j	ffffffffc0200b56 <interrupt_handler>
}
ffffffffc0200dd6:	60e2                	ld	ra,24(sp)
ffffffffc0200dd8:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200dda:	3920406f          	j	ffffffffc020516c <schedule>
                do_exit(-E_KILLED);
ffffffffc0200dde:	555d                	li	a0,-9
ffffffffc0200de0:	62c030ef          	jal	ffffffffc020440c <do_exit>
            if (current->need_resched)
ffffffffc0200de4:	0009b717          	auipc	a4,0x9b
ffffffffc0200de8:	9d473703          	ld	a4,-1580(a4) # ffffffffc029b7b8 <current>
ffffffffc0200dec:	b7d9                	j	ffffffffc0200db2 <trap+0x48>
	...

ffffffffc0200df0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200df0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200df4:	00011463          	bnez	sp,ffffffffc0200dfc <__alltraps+0xc>
ffffffffc0200df8:	14002173          	csrr	sp,sscratch
ffffffffc0200dfc:	712d                	addi	sp,sp,-288
ffffffffc0200dfe:	e002                	sd	zero,0(sp)
ffffffffc0200e00:	e406                	sd	ra,8(sp)
ffffffffc0200e02:	ec0e                	sd	gp,24(sp)
ffffffffc0200e04:	f012                	sd	tp,32(sp)
ffffffffc0200e06:	f416                	sd	t0,40(sp)
ffffffffc0200e08:	f81a                	sd	t1,48(sp)
ffffffffc0200e0a:	fc1e                	sd	t2,56(sp)
ffffffffc0200e0c:	e0a2                	sd	s0,64(sp)
ffffffffc0200e0e:	e4a6                	sd	s1,72(sp)
ffffffffc0200e10:	e8aa                	sd	a0,80(sp)
ffffffffc0200e12:	ecae                	sd	a1,88(sp)
ffffffffc0200e14:	f0b2                	sd	a2,96(sp)
ffffffffc0200e16:	f4b6                	sd	a3,104(sp)
ffffffffc0200e18:	f8ba                	sd	a4,112(sp)
ffffffffc0200e1a:	fcbe                	sd	a5,120(sp)
ffffffffc0200e1c:	e142                	sd	a6,128(sp)
ffffffffc0200e1e:	e546                	sd	a7,136(sp)
ffffffffc0200e20:	e94a                	sd	s2,144(sp)
ffffffffc0200e22:	ed4e                	sd	s3,152(sp)
ffffffffc0200e24:	f152                	sd	s4,160(sp)
ffffffffc0200e26:	f556                	sd	s5,168(sp)
ffffffffc0200e28:	f95a                	sd	s6,176(sp)
ffffffffc0200e2a:	fd5e                	sd	s7,184(sp)
ffffffffc0200e2c:	e1e2                	sd	s8,192(sp)
ffffffffc0200e2e:	e5e6                	sd	s9,200(sp)
ffffffffc0200e30:	e9ea                	sd	s10,208(sp)
ffffffffc0200e32:	edee                	sd	s11,216(sp)
ffffffffc0200e34:	f1f2                	sd	t3,224(sp)
ffffffffc0200e36:	f5f6                	sd	t4,232(sp)
ffffffffc0200e38:	f9fa                	sd	t5,240(sp)
ffffffffc0200e3a:	fdfe                	sd	t6,248(sp)
ffffffffc0200e3c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e40:	100024f3          	csrr	s1,sstatus
ffffffffc0200e44:	14102973          	csrr	s2,sepc
ffffffffc0200e48:	143029f3          	csrr	s3,stval
ffffffffc0200e4c:	14202a73          	csrr	s4,scause
ffffffffc0200e50:	e822                	sd	s0,16(sp)
ffffffffc0200e52:	e226                	sd	s1,256(sp)
ffffffffc0200e54:	e64a                	sd	s2,264(sp)
ffffffffc0200e56:	ea4e                	sd	s3,272(sp)
ffffffffc0200e58:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e5a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e5c:	f0fff0ef          	jal	ffffffffc0200d6a <trap>

ffffffffc0200e60 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e60:	6492                	ld	s1,256(sp)
ffffffffc0200e62:	6932                	ld	s2,264(sp)
ffffffffc0200e64:	1004f413          	andi	s0,s1,256
ffffffffc0200e68:	e401                	bnez	s0,ffffffffc0200e70 <__trapret+0x10>
ffffffffc0200e6a:	1200                	addi	s0,sp,288
ffffffffc0200e6c:	14041073          	csrw	sscratch,s0
ffffffffc0200e70:	10049073          	csrw	sstatus,s1
ffffffffc0200e74:	14191073          	csrw	sepc,s2
ffffffffc0200e78:	60a2                	ld	ra,8(sp)
ffffffffc0200e7a:	61e2                	ld	gp,24(sp)
ffffffffc0200e7c:	7202                	ld	tp,32(sp)
ffffffffc0200e7e:	72a2                	ld	t0,40(sp)
ffffffffc0200e80:	7342                	ld	t1,48(sp)
ffffffffc0200e82:	73e2                	ld	t2,56(sp)
ffffffffc0200e84:	6406                	ld	s0,64(sp)
ffffffffc0200e86:	64a6                	ld	s1,72(sp)
ffffffffc0200e88:	6546                	ld	a0,80(sp)
ffffffffc0200e8a:	65e6                	ld	a1,88(sp)
ffffffffc0200e8c:	7606                	ld	a2,96(sp)
ffffffffc0200e8e:	76a6                	ld	a3,104(sp)
ffffffffc0200e90:	7746                	ld	a4,112(sp)
ffffffffc0200e92:	77e6                	ld	a5,120(sp)
ffffffffc0200e94:	680a                	ld	a6,128(sp)
ffffffffc0200e96:	68aa                	ld	a7,136(sp)
ffffffffc0200e98:	694a                	ld	s2,144(sp)
ffffffffc0200e9a:	69ea                	ld	s3,152(sp)
ffffffffc0200e9c:	7a0a                	ld	s4,160(sp)
ffffffffc0200e9e:	7aaa                	ld	s5,168(sp)
ffffffffc0200ea0:	7b4a                	ld	s6,176(sp)
ffffffffc0200ea2:	7bea                	ld	s7,184(sp)
ffffffffc0200ea4:	6c0e                	ld	s8,192(sp)
ffffffffc0200ea6:	6cae                	ld	s9,200(sp)
ffffffffc0200ea8:	6d4e                	ld	s10,208(sp)
ffffffffc0200eaa:	6dee                	ld	s11,216(sp)
ffffffffc0200eac:	7e0e                	ld	t3,224(sp)
ffffffffc0200eae:	7eae                	ld	t4,232(sp)
ffffffffc0200eb0:	7f4e                	ld	t5,240(sp)
ffffffffc0200eb2:	7fee                	ld	t6,248(sp)
ffffffffc0200eb4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eb6:	10200073          	sret

ffffffffc0200eba <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200eba:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200ebc:	b755                	j	ffffffffc0200e60 <__trapret>

ffffffffc0200ebe <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200ebe:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200ec2:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200ec6:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200eca:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200ece:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200ed2:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200ed6:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200eda:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200ede:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200ee2:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200ee4:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200ee6:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200ee8:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200eea:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200eec:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200eee:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200ef0:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200ef2:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200ef4:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200ef6:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200ef8:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200efa:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200efc:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200efe:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f00:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f02:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f04:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f06:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f08:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f0a:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f0c:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f0e:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f10:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f12:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f14:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f16:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f18:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f1a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f1c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f1e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f20:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f22:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f24:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f26:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f28:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f2a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f2c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f2e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f30:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f32:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f34:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f36:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f38:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f3a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f3c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f3e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f40:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f42:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f44:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f46:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f48:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f4a:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200f4c:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200f4e:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200f50:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200f52:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200f54:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200f56:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200f58:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200f5a:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200f5c:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200f5e:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200f60:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200f62:	812e                	mv	sp,a1
ffffffffc0200f64:	bdf5                	j	ffffffffc0200e60 <__trapret>

ffffffffc0200f66 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f66:	00096797          	auipc	a5,0x96
ffffffffc0200f6a:	7ba78793          	addi	a5,a5,1978 # ffffffffc0297720 <free_area>
ffffffffc0200f6e:	e79c                	sd	a5,8(a5)
ffffffffc0200f70:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f72:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f76:	8082                	ret

ffffffffc0200f78 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f78:	00096517          	auipc	a0,0x96
ffffffffc0200f7c:	7b856503          	lwu	a0,1976(a0) # ffffffffc0297730 <free_area+0x10>
ffffffffc0200f80:	8082                	ret

ffffffffc0200f82 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f82:	711d                	addi	sp,sp,-96
ffffffffc0200f84:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f86:	00096917          	auipc	s2,0x96
ffffffffc0200f8a:	79a90913          	addi	s2,s2,1946 # ffffffffc0297720 <free_area>
ffffffffc0200f8e:	00893783          	ld	a5,8(s2)
ffffffffc0200f92:	ec86                	sd	ra,88(sp)
ffffffffc0200f94:	e8a2                	sd	s0,80(sp)
ffffffffc0200f96:	e4a6                	sd	s1,72(sp)
ffffffffc0200f98:	fc4e                	sd	s3,56(sp)
ffffffffc0200f9a:	f852                	sd	s4,48(sp)
ffffffffc0200f9c:	f456                	sd	s5,40(sp)
ffffffffc0200f9e:	f05a                	sd	s6,32(sp)
ffffffffc0200fa0:	ec5e                	sd	s7,24(sp)
ffffffffc0200fa2:	e862                	sd	s8,16(sp)
ffffffffc0200fa4:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fa6:	2f278363          	beq	a5,s2,ffffffffc020128c <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200faa:	4401                	li	s0,0
ffffffffc0200fac:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200fae:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200fb2:	8b09                	andi	a4,a4,2
ffffffffc0200fb4:	2e070063          	beqz	a4,ffffffffc0201294 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200fb8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fbc:	679c                	ld	a5,8(a5)
ffffffffc0200fbe:	2485                	addiw	s1,s1,1
ffffffffc0200fc0:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fc2:	ff2796e3          	bne	a5,s2,ffffffffc0200fae <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200fc6:	89a2                	mv	s3,s0
ffffffffc0200fc8:	741000ef          	jal	ffffffffc0201f08 <nr_free_pages>
ffffffffc0200fcc:	73351463          	bne	a0,s3,ffffffffc02016f4 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	6c5000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0200fd6:	8a2a                	mv	s4,a0
ffffffffc0200fd8:	44050e63          	beqz	a0,ffffffffc0201434 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fdc:	4505                	li	a0,1
ffffffffc0200fde:	6b9000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0200fe2:	89aa                	mv	s3,a0
ffffffffc0200fe4:	72050863          	beqz	a0,ffffffffc0201714 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fe8:	4505                	li	a0,1
ffffffffc0200fea:	6ad000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0200fee:	8aaa                	mv	s5,a0
ffffffffc0200ff0:	4c050263          	beqz	a0,ffffffffc02014b4 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ff4:	40a987b3          	sub	a5,s3,a0
ffffffffc0200ff8:	40aa0733          	sub	a4,s4,a0
ffffffffc0200ffc:	0017b793          	seqz	a5,a5
ffffffffc0201000:	00173713          	seqz	a4,a4
ffffffffc0201004:	8fd9                	or	a5,a5,a4
ffffffffc0201006:	30079763          	bnez	a5,ffffffffc0201314 <default_check+0x392>
ffffffffc020100a:	313a0563          	beq	s4,s3,ffffffffc0201314 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020100e:	000a2783          	lw	a5,0(s4)
ffffffffc0201012:	2a079163          	bnez	a5,ffffffffc02012b4 <default_check+0x332>
ffffffffc0201016:	0009a783          	lw	a5,0(s3)
ffffffffc020101a:	28079d63          	bnez	a5,ffffffffc02012b4 <default_check+0x332>
ffffffffc020101e:	411c                	lw	a5,0(a0)
ffffffffc0201020:	28079a63          	bnez	a5,ffffffffc02012b4 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201024:	0009a797          	auipc	a5,0x9a
ffffffffc0201028:	7847b783          	ld	a5,1924(a5) # ffffffffc029b7a8 <pages>
ffffffffc020102c:	00007617          	auipc	a2,0x7
ffffffffc0201030:	8ac63603          	ld	a2,-1876(a2) # ffffffffc02078d8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201034:	0009a697          	auipc	a3,0x9a
ffffffffc0201038:	76c6b683          	ld	a3,1900(a3) # ffffffffc029b7a0 <npage>
ffffffffc020103c:	40fa0733          	sub	a4,s4,a5
ffffffffc0201040:	8719                	srai	a4,a4,0x6
ffffffffc0201042:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201044:	0732                	slli	a4,a4,0xc
ffffffffc0201046:	06b2                	slli	a3,a3,0xc
ffffffffc0201048:	2ad77663          	bgeu	a4,a3,ffffffffc02012f4 <default_check+0x372>
    return page - pages + nbase;
ffffffffc020104c:	40f98733          	sub	a4,s3,a5
ffffffffc0201050:	8719                	srai	a4,a4,0x6
ffffffffc0201052:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201054:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201056:	4cd77f63          	bgeu	a4,a3,ffffffffc0201534 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc020105a:	40f507b3          	sub	a5,a0,a5
ffffffffc020105e:	8799                	srai	a5,a5,0x6
ffffffffc0201060:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201062:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201064:	32d7f863          	bgeu	a5,a3,ffffffffc0201394 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0201068:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020106a:	00093c03          	ld	s8,0(s2)
ffffffffc020106e:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0201072:	00096b17          	auipc	s6,0x96
ffffffffc0201076:	6beb2b03          	lw	s6,1726(s6) # ffffffffc0297730 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc020107a:	01293023          	sd	s2,0(s2)
ffffffffc020107e:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0201082:	00096797          	auipc	a5,0x96
ffffffffc0201086:	6a07a723          	sw	zero,1710(a5) # ffffffffc0297730 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020108a:	60d000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc020108e:	2e051363          	bnez	a0,ffffffffc0201374 <default_check+0x3f2>
    free_page(p0);
ffffffffc0201092:	8552                	mv	a0,s4
ffffffffc0201094:	4585                	li	a1,1
ffffffffc0201096:	63b000ef          	jal	ffffffffc0201ed0 <free_pages>
    free_page(p1);
ffffffffc020109a:	854e                	mv	a0,s3
ffffffffc020109c:	4585                	li	a1,1
ffffffffc020109e:	633000ef          	jal	ffffffffc0201ed0 <free_pages>
    free_page(p2);
ffffffffc02010a2:	8556                	mv	a0,s5
ffffffffc02010a4:	4585                	li	a1,1
ffffffffc02010a6:	62b000ef          	jal	ffffffffc0201ed0 <free_pages>
    assert(nr_free == 3);
ffffffffc02010aa:	00096717          	auipc	a4,0x96
ffffffffc02010ae:	68672703          	lw	a4,1670(a4) # ffffffffc0297730 <free_area+0x10>
ffffffffc02010b2:	478d                	li	a5,3
ffffffffc02010b4:	2af71063          	bne	a4,a5,ffffffffc0201354 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010b8:	4505                	li	a0,1
ffffffffc02010ba:	5dd000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02010be:	89aa                	mv	s3,a0
ffffffffc02010c0:	26050a63          	beqz	a0,ffffffffc0201334 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010c4:	4505                	li	a0,1
ffffffffc02010c6:	5d1000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02010ca:	8aaa                	mv	s5,a0
ffffffffc02010cc:	3c050463          	beqz	a0,ffffffffc0201494 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010d0:	4505                	li	a0,1
ffffffffc02010d2:	5c5000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02010d6:	8a2a                	mv	s4,a0
ffffffffc02010d8:	38050e63          	beqz	a0,ffffffffc0201474 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc02010dc:	4505                	li	a0,1
ffffffffc02010de:	5b9000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02010e2:	36051963          	bnez	a0,ffffffffc0201454 <default_check+0x4d2>
    free_page(p0);
ffffffffc02010e6:	4585                	li	a1,1
ffffffffc02010e8:	854e                	mv	a0,s3
ffffffffc02010ea:	5e7000ef          	jal	ffffffffc0201ed0 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02010ee:	00893783          	ld	a5,8(s2)
ffffffffc02010f2:	1f278163          	beq	a5,s2,ffffffffc02012d4 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc02010f6:	4505                	li	a0,1
ffffffffc02010f8:	59f000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02010fc:	8caa                	mv	s9,a0
ffffffffc02010fe:	30a99b63          	bne	s3,a0,ffffffffc0201414 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc0201102:	4505                	li	a0,1
ffffffffc0201104:	593000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0201108:	2e051663          	bnez	a0,ffffffffc02013f4 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc020110c:	00096797          	auipc	a5,0x96
ffffffffc0201110:	6247a783          	lw	a5,1572(a5) # ffffffffc0297730 <free_area+0x10>
ffffffffc0201114:	2c079063          	bnez	a5,ffffffffc02013d4 <default_check+0x452>
    free_page(p);
ffffffffc0201118:	8566                	mv	a0,s9
ffffffffc020111a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020111c:	01893023          	sd	s8,0(s2)
ffffffffc0201120:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201124:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201128:	5a9000ef          	jal	ffffffffc0201ed0 <free_pages>
    free_page(p1);
ffffffffc020112c:	8556                	mv	a0,s5
ffffffffc020112e:	4585                	li	a1,1
ffffffffc0201130:	5a1000ef          	jal	ffffffffc0201ed0 <free_pages>
    free_page(p2);
ffffffffc0201134:	8552                	mv	a0,s4
ffffffffc0201136:	4585                	li	a1,1
ffffffffc0201138:	599000ef          	jal	ffffffffc0201ed0 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020113c:	4515                	li	a0,5
ffffffffc020113e:	559000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0201142:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201144:	26050863          	beqz	a0,ffffffffc02013b4 <default_check+0x432>
ffffffffc0201148:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc020114a:	8b89                	andi	a5,a5,2
ffffffffc020114c:	54079463          	bnez	a5,ffffffffc0201694 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201150:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201152:	00093b83          	ld	s7,0(s2)
ffffffffc0201156:	00893b03          	ld	s6,8(s2)
ffffffffc020115a:	01293023          	sd	s2,0(s2)
ffffffffc020115e:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0201162:	535000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0201166:	50051763          	bnez	a0,ffffffffc0201674 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020116a:	08098a13          	addi	s4,s3,128
ffffffffc020116e:	8552                	mv	a0,s4
ffffffffc0201170:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201172:	00096c17          	auipc	s8,0x96
ffffffffc0201176:	5bec2c03          	lw	s8,1470(s8) # ffffffffc0297730 <free_area+0x10>
    nr_free = 0;
ffffffffc020117a:	00096797          	auipc	a5,0x96
ffffffffc020117e:	5a07ab23          	sw	zero,1462(a5) # ffffffffc0297730 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201182:	54f000ef          	jal	ffffffffc0201ed0 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201186:	4511                	li	a0,4
ffffffffc0201188:	50f000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc020118c:	4c051463          	bnez	a0,ffffffffc0201654 <default_check+0x6d2>
ffffffffc0201190:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201194:	8b89                	andi	a5,a5,2
ffffffffc0201196:	48078f63          	beqz	a5,ffffffffc0201634 <default_check+0x6b2>
ffffffffc020119a:	0909a503          	lw	a0,144(s3)
ffffffffc020119e:	478d                	li	a5,3
ffffffffc02011a0:	48f51a63          	bne	a0,a5,ffffffffc0201634 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011a4:	4f3000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02011a8:	8aaa                	mv	s5,a0
ffffffffc02011aa:	46050563          	beqz	a0,ffffffffc0201614 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02011ae:	4505                	li	a0,1
ffffffffc02011b0:	4e7000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02011b4:	44051063          	bnez	a0,ffffffffc02015f4 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02011b8:	415a1e63          	bne	s4,s5,ffffffffc02015d4 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011bc:	4585                	li	a1,1
ffffffffc02011be:	854e                	mv	a0,s3
ffffffffc02011c0:	511000ef          	jal	ffffffffc0201ed0 <free_pages>
    free_pages(p1, 3);
ffffffffc02011c4:	8552                	mv	a0,s4
ffffffffc02011c6:	458d                	li	a1,3
ffffffffc02011c8:	509000ef          	jal	ffffffffc0201ed0 <free_pages>
ffffffffc02011cc:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011d0:	8b89                	andi	a5,a5,2
ffffffffc02011d2:	3e078163          	beqz	a5,ffffffffc02015b4 <default_check+0x632>
ffffffffc02011d6:	0109aa83          	lw	s5,16(s3)
ffffffffc02011da:	4785                	li	a5,1
ffffffffc02011dc:	3cfa9c63          	bne	s5,a5,ffffffffc02015b4 <default_check+0x632>
ffffffffc02011e0:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011e4:	8b89                	andi	a5,a5,2
ffffffffc02011e6:	3a078763          	beqz	a5,ffffffffc0201594 <default_check+0x612>
ffffffffc02011ea:	010a2703          	lw	a4,16(s4)
ffffffffc02011ee:	478d                	li	a5,3
ffffffffc02011f0:	3af71263          	bne	a4,a5,ffffffffc0201594 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011f4:	8556                	mv	a0,s5
ffffffffc02011f6:	4a1000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02011fa:	36a99d63          	bne	s3,a0,ffffffffc0201574 <default_check+0x5f2>
    free_page(p0);
ffffffffc02011fe:	85d6                	mv	a1,s5
ffffffffc0201200:	4d1000ef          	jal	ffffffffc0201ed0 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201204:	4509                	li	a0,2
ffffffffc0201206:	491000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc020120a:	34aa1563          	bne	s4,a0,ffffffffc0201554 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc020120e:	4589                	li	a1,2
ffffffffc0201210:	4c1000ef          	jal	ffffffffc0201ed0 <free_pages>
    free_page(p2);
ffffffffc0201214:	04098513          	addi	a0,s3,64
ffffffffc0201218:	85d6                	mv	a1,s5
ffffffffc020121a:	4b7000ef          	jal	ffffffffc0201ed0 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020121e:	4515                	li	a0,5
ffffffffc0201220:	477000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0201224:	89aa                	mv	s3,a0
ffffffffc0201226:	48050763          	beqz	a0,ffffffffc02016b4 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc020122a:	8556                	mv	a0,s5
ffffffffc020122c:	46b000ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0201230:	2e051263          	bnez	a0,ffffffffc0201514 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201234:	00096797          	auipc	a5,0x96
ffffffffc0201238:	4fc7a783          	lw	a5,1276(a5) # ffffffffc0297730 <free_area+0x10>
ffffffffc020123c:	2a079c63          	bnez	a5,ffffffffc02014f4 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201240:	854e                	mv	a0,s3
ffffffffc0201242:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201244:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201248:	01793023          	sd	s7,0(s2)
ffffffffc020124c:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201250:	481000ef          	jal	ffffffffc0201ed0 <free_pages>
    return listelm->next;
ffffffffc0201254:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201258:	01278963          	beq	a5,s2,ffffffffc020126a <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020125c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201260:	679c                	ld	a5,8(a5)
ffffffffc0201262:	34fd                	addiw	s1,s1,-1
ffffffffc0201264:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201266:	ff279be3          	bne	a5,s2,ffffffffc020125c <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc020126a:	26049563          	bnez	s1,ffffffffc02014d4 <default_check+0x552>
    assert(total == 0);
ffffffffc020126e:	46041363          	bnez	s0,ffffffffc02016d4 <default_check+0x752>
}
ffffffffc0201272:	60e6                	ld	ra,88(sp)
ffffffffc0201274:	6446                	ld	s0,80(sp)
ffffffffc0201276:	64a6                	ld	s1,72(sp)
ffffffffc0201278:	6906                	ld	s2,64(sp)
ffffffffc020127a:	79e2                	ld	s3,56(sp)
ffffffffc020127c:	7a42                	ld	s4,48(sp)
ffffffffc020127e:	7aa2                	ld	s5,40(sp)
ffffffffc0201280:	7b02                	ld	s6,32(sp)
ffffffffc0201282:	6be2                	ld	s7,24(sp)
ffffffffc0201284:	6c42                	ld	s8,16(sp)
ffffffffc0201286:	6ca2                	ld	s9,8(sp)
ffffffffc0201288:	6125                	addi	sp,sp,96
ffffffffc020128a:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc020128c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020128e:	4401                	li	s0,0
ffffffffc0201290:	4481                	li	s1,0
ffffffffc0201292:	bb1d                	j	ffffffffc0200fc8 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201294:	00005697          	auipc	a3,0x5
ffffffffc0201298:	ec468693          	addi	a3,a3,-316 # ffffffffc0206158 <etext+0x9c4>
ffffffffc020129c:	00005617          	auipc	a2,0x5
ffffffffc02012a0:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02012a4:	11000593          	li	a1,272
ffffffffc02012a8:	00005517          	auipc	a0,0x5
ffffffffc02012ac:	ed850513          	addi	a0,a0,-296 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02012b0:	996ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012b4:	00005697          	auipc	a3,0x5
ffffffffc02012b8:	f8c68693          	addi	a3,a3,-116 # ffffffffc0206240 <etext+0xaac>
ffffffffc02012bc:	00005617          	auipc	a2,0x5
ffffffffc02012c0:	eac60613          	addi	a2,a2,-340 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02012c4:	0dc00593          	li	a1,220
ffffffffc02012c8:	00005517          	auipc	a0,0x5
ffffffffc02012cc:	eb850513          	addi	a0,a0,-328 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02012d0:	976ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012d4:	00005697          	auipc	a3,0x5
ffffffffc02012d8:	03468693          	addi	a3,a3,52 # ffffffffc0206308 <etext+0xb74>
ffffffffc02012dc:	00005617          	auipc	a2,0x5
ffffffffc02012e0:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02012e4:	0f700593          	li	a1,247
ffffffffc02012e8:	00005517          	auipc	a0,0x5
ffffffffc02012ec:	e9850513          	addi	a0,a0,-360 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02012f0:	956ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012f4:	00005697          	auipc	a3,0x5
ffffffffc02012f8:	f8c68693          	addi	a3,a3,-116 # ffffffffc0206280 <etext+0xaec>
ffffffffc02012fc:	00005617          	auipc	a2,0x5
ffffffffc0201300:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201304:	0de00593          	li	a1,222
ffffffffc0201308:	00005517          	auipc	a0,0x5
ffffffffc020130c:	e7850513          	addi	a0,a0,-392 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201310:	936ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201314:	00005697          	auipc	a3,0x5
ffffffffc0201318:	f0468693          	addi	a3,a3,-252 # ffffffffc0206218 <etext+0xa84>
ffffffffc020131c:	00005617          	auipc	a2,0x5
ffffffffc0201320:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201324:	0db00593          	li	a1,219
ffffffffc0201328:	00005517          	auipc	a0,0x5
ffffffffc020132c:	e5850513          	addi	a0,a0,-424 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201330:	916ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201334:	00005697          	auipc	a3,0x5
ffffffffc0201338:	e8468693          	addi	a3,a3,-380 # ffffffffc02061b8 <etext+0xa24>
ffffffffc020133c:	00005617          	auipc	a2,0x5
ffffffffc0201340:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201344:	0f000593          	li	a1,240
ffffffffc0201348:	00005517          	auipc	a0,0x5
ffffffffc020134c:	e3850513          	addi	a0,a0,-456 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201350:	8f6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc0201354:	00005697          	auipc	a3,0x5
ffffffffc0201358:	fa468693          	addi	a3,a3,-92 # ffffffffc02062f8 <etext+0xb64>
ffffffffc020135c:	00005617          	auipc	a2,0x5
ffffffffc0201360:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201364:	0ee00593          	li	a1,238
ffffffffc0201368:	00005517          	auipc	a0,0x5
ffffffffc020136c:	e1850513          	addi	a0,a0,-488 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201370:	8d6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201374:	00005697          	auipc	a3,0x5
ffffffffc0201378:	f6c68693          	addi	a3,a3,-148 # ffffffffc02062e0 <etext+0xb4c>
ffffffffc020137c:	00005617          	auipc	a2,0x5
ffffffffc0201380:	dec60613          	addi	a2,a2,-532 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201384:	0e900593          	li	a1,233
ffffffffc0201388:	00005517          	auipc	a0,0x5
ffffffffc020138c:	df850513          	addi	a0,a0,-520 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201390:	8b6ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201394:	00005697          	auipc	a3,0x5
ffffffffc0201398:	f2c68693          	addi	a3,a3,-212 # ffffffffc02062c0 <etext+0xb2c>
ffffffffc020139c:	00005617          	auipc	a2,0x5
ffffffffc02013a0:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02013a4:	0e000593          	li	a1,224
ffffffffc02013a8:	00005517          	auipc	a0,0x5
ffffffffc02013ac:	dd850513          	addi	a0,a0,-552 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02013b0:	896ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc02013b4:	00005697          	auipc	a3,0x5
ffffffffc02013b8:	f9c68693          	addi	a3,a3,-100 # ffffffffc0206350 <etext+0xbbc>
ffffffffc02013bc:	00005617          	auipc	a2,0x5
ffffffffc02013c0:	dac60613          	addi	a2,a2,-596 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02013c4:	11800593          	li	a1,280
ffffffffc02013c8:	00005517          	auipc	a0,0x5
ffffffffc02013cc:	db850513          	addi	a0,a0,-584 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02013d0:	876ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02013d4:	00005697          	auipc	a3,0x5
ffffffffc02013d8:	f6c68693          	addi	a3,a3,-148 # ffffffffc0206340 <etext+0xbac>
ffffffffc02013dc:	00005617          	auipc	a2,0x5
ffffffffc02013e0:	d8c60613          	addi	a2,a2,-628 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02013e4:	0fd00593          	li	a1,253
ffffffffc02013e8:	00005517          	auipc	a0,0x5
ffffffffc02013ec:	d9850513          	addi	a0,a0,-616 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02013f0:	856ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f4:	00005697          	auipc	a3,0x5
ffffffffc02013f8:	eec68693          	addi	a3,a3,-276 # ffffffffc02062e0 <etext+0xb4c>
ffffffffc02013fc:	00005617          	auipc	a2,0x5
ffffffffc0201400:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201404:	0fb00593          	li	a1,251
ffffffffc0201408:	00005517          	auipc	a0,0x5
ffffffffc020140c:	d7850513          	addi	a0,a0,-648 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201410:	836ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201414:	00005697          	auipc	a3,0x5
ffffffffc0201418:	f0c68693          	addi	a3,a3,-244 # ffffffffc0206320 <etext+0xb8c>
ffffffffc020141c:	00005617          	auipc	a2,0x5
ffffffffc0201420:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201424:	0fa00593          	li	a1,250
ffffffffc0201428:	00005517          	auipc	a0,0x5
ffffffffc020142c:	d5850513          	addi	a0,a0,-680 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201430:	816ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201434:	00005697          	auipc	a3,0x5
ffffffffc0201438:	d8468693          	addi	a3,a3,-636 # ffffffffc02061b8 <etext+0xa24>
ffffffffc020143c:	00005617          	auipc	a2,0x5
ffffffffc0201440:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201444:	0d700593          	li	a1,215
ffffffffc0201448:	00005517          	auipc	a0,0x5
ffffffffc020144c:	d3850513          	addi	a0,a0,-712 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201450:	ff7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201454:	00005697          	auipc	a3,0x5
ffffffffc0201458:	e8c68693          	addi	a3,a3,-372 # ffffffffc02062e0 <etext+0xb4c>
ffffffffc020145c:	00005617          	auipc	a2,0x5
ffffffffc0201460:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201464:	0f400593          	li	a1,244
ffffffffc0201468:	00005517          	auipc	a0,0x5
ffffffffc020146c:	d1850513          	addi	a0,a0,-744 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201470:	fd7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201474:	00005697          	auipc	a3,0x5
ffffffffc0201478:	d8468693          	addi	a3,a3,-636 # ffffffffc02061f8 <etext+0xa64>
ffffffffc020147c:	00005617          	auipc	a2,0x5
ffffffffc0201480:	cec60613          	addi	a2,a2,-788 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201484:	0f200593          	li	a1,242
ffffffffc0201488:	00005517          	auipc	a0,0x5
ffffffffc020148c:	cf850513          	addi	a0,a0,-776 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201490:	fb7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201494:	00005697          	auipc	a3,0x5
ffffffffc0201498:	d4468693          	addi	a3,a3,-700 # ffffffffc02061d8 <etext+0xa44>
ffffffffc020149c:	00005617          	auipc	a2,0x5
ffffffffc02014a0:	ccc60613          	addi	a2,a2,-820 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02014a4:	0f100593          	li	a1,241
ffffffffc02014a8:	00005517          	auipc	a0,0x5
ffffffffc02014ac:	cd850513          	addi	a0,a0,-808 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02014b0:	f97fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014b4:	00005697          	auipc	a3,0x5
ffffffffc02014b8:	d4468693          	addi	a3,a3,-700 # ffffffffc02061f8 <etext+0xa64>
ffffffffc02014bc:	00005617          	auipc	a2,0x5
ffffffffc02014c0:	cac60613          	addi	a2,a2,-852 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02014c4:	0d900593          	li	a1,217
ffffffffc02014c8:	00005517          	auipc	a0,0x5
ffffffffc02014cc:	cb850513          	addi	a0,a0,-840 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02014d0:	f77fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02014d4:	00005697          	auipc	a3,0x5
ffffffffc02014d8:	fcc68693          	addi	a3,a3,-52 # ffffffffc02064a0 <etext+0xd0c>
ffffffffc02014dc:	00005617          	auipc	a2,0x5
ffffffffc02014e0:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02014e4:	14600593          	li	a1,326
ffffffffc02014e8:	00005517          	auipc	a0,0x5
ffffffffc02014ec:	c9850513          	addi	a0,a0,-872 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02014f0:	f57fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02014f4:	00005697          	auipc	a3,0x5
ffffffffc02014f8:	e4c68693          	addi	a3,a3,-436 # ffffffffc0206340 <etext+0xbac>
ffffffffc02014fc:	00005617          	auipc	a2,0x5
ffffffffc0201500:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201504:	13a00593          	li	a1,314
ffffffffc0201508:	00005517          	auipc	a0,0x5
ffffffffc020150c:	c7850513          	addi	a0,a0,-904 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201510:	f37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201514:	00005697          	auipc	a3,0x5
ffffffffc0201518:	dcc68693          	addi	a3,a3,-564 # ffffffffc02062e0 <etext+0xb4c>
ffffffffc020151c:	00005617          	auipc	a2,0x5
ffffffffc0201520:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201524:	13800593          	li	a1,312
ffffffffc0201528:	00005517          	auipc	a0,0x5
ffffffffc020152c:	c5850513          	addi	a0,a0,-936 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201530:	f17fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201534:	00005697          	auipc	a3,0x5
ffffffffc0201538:	d6c68693          	addi	a3,a3,-660 # ffffffffc02062a0 <etext+0xb0c>
ffffffffc020153c:	00005617          	auipc	a2,0x5
ffffffffc0201540:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201544:	0df00593          	li	a1,223
ffffffffc0201548:	00005517          	auipc	a0,0x5
ffffffffc020154c:	c3850513          	addi	a0,a0,-968 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201550:	ef7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201554:	00005697          	auipc	a3,0x5
ffffffffc0201558:	f0c68693          	addi	a3,a3,-244 # ffffffffc0206460 <etext+0xccc>
ffffffffc020155c:	00005617          	auipc	a2,0x5
ffffffffc0201560:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201564:	13200593          	li	a1,306
ffffffffc0201568:	00005517          	auipc	a0,0x5
ffffffffc020156c:	c1850513          	addi	a0,a0,-1000 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201570:	ed7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201574:	00005697          	auipc	a3,0x5
ffffffffc0201578:	ecc68693          	addi	a3,a3,-308 # ffffffffc0206440 <etext+0xcac>
ffffffffc020157c:	00005617          	auipc	a2,0x5
ffffffffc0201580:	bec60613          	addi	a2,a2,-1044 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201584:	13000593          	li	a1,304
ffffffffc0201588:	00005517          	auipc	a0,0x5
ffffffffc020158c:	bf850513          	addi	a0,a0,-1032 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201590:	eb7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201594:	00005697          	auipc	a3,0x5
ffffffffc0201598:	e8468693          	addi	a3,a3,-380 # ffffffffc0206418 <etext+0xc84>
ffffffffc020159c:	00005617          	auipc	a2,0x5
ffffffffc02015a0:	bcc60613          	addi	a2,a2,-1076 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02015a4:	12e00593          	li	a1,302
ffffffffc02015a8:	00005517          	auipc	a0,0x5
ffffffffc02015ac:	bd850513          	addi	a0,a0,-1064 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02015b0:	e97fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015b4:	00005697          	auipc	a3,0x5
ffffffffc02015b8:	e3c68693          	addi	a3,a3,-452 # ffffffffc02063f0 <etext+0xc5c>
ffffffffc02015bc:	00005617          	auipc	a2,0x5
ffffffffc02015c0:	bac60613          	addi	a2,a2,-1108 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02015c4:	12d00593          	li	a1,301
ffffffffc02015c8:	00005517          	auipc	a0,0x5
ffffffffc02015cc:	bb850513          	addi	a0,a0,-1096 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02015d0:	e77fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015d4:	00005697          	auipc	a3,0x5
ffffffffc02015d8:	e0c68693          	addi	a3,a3,-500 # ffffffffc02063e0 <etext+0xc4c>
ffffffffc02015dc:	00005617          	auipc	a2,0x5
ffffffffc02015e0:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02015e4:	12800593          	li	a1,296
ffffffffc02015e8:	00005517          	auipc	a0,0x5
ffffffffc02015ec:	b9850513          	addi	a0,a0,-1128 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02015f0:	e57fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015f4:	00005697          	auipc	a3,0x5
ffffffffc02015f8:	cec68693          	addi	a3,a3,-788 # ffffffffc02062e0 <etext+0xb4c>
ffffffffc02015fc:	00005617          	auipc	a2,0x5
ffffffffc0201600:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201604:	12700593          	li	a1,295
ffffffffc0201608:	00005517          	auipc	a0,0x5
ffffffffc020160c:	b7850513          	addi	a0,a0,-1160 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201610:	e37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201614:	00005697          	auipc	a3,0x5
ffffffffc0201618:	dac68693          	addi	a3,a3,-596 # ffffffffc02063c0 <etext+0xc2c>
ffffffffc020161c:	00005617          	auipc	a2,0x5
ffffffffc0201620:	b4c60613          	addi	a2,a2,-1204 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201624:	12600593          	li	a1,294
ffffffffc0201628:	00005517          	auipc	a0,0x5
ffffffffc020162c:	b5850513          	addi	a0,a0,-1192 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201630:	e17fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201634:	00005697          	auipc	a3,0x5
ffffffffc0201638:	d5c68693          	addi	a3,a3,-676 # ffffffffc0206390 <etext+0xbfc>
ffffffffc020163c:	00005617          	auipc	a2,0x5
ffffffffc0201640:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201644:	12500593          	li	a1,293
ffffffffc0201648:	00005517          	auipc	a0,0x5
ffffffffc020164c:	b3850513          	addi	a0,a0,-1224 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201650:	df7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201654:	00005697          	auipc	a3,0x5
ffffffffc0201658:	d2468693          	addi	a3,a3,-732 # ffffffffc0206378 <etext+0xbe4>
ffffffffc020165c:	00005617          	auipc	a2,0x5
ffffffffc0201660:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201664:	12400593          	li	a1,292
ffffffffc0201668:	00005517          	auipc	a0,0x5
ffffffffc020166c:	b1850513          	addi	a0,a0,-1256 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201670:	dd7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201674:	00005697          	auipc	a3,0x5
ffffffffc0201678:	c6c68693          	addi	a3,a3,-916 # ffffffffc02062e0 <etext+0xb4c>
ffffffffc020167c:	00005617          	auipc	a2,0x5
ffffffffc0201680:	aec60613          	addi	a2,a2,-1300 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201684:	11e00593          	li	a1,286
ffffffffc0201688:	00005517          	auipc	a0,0x5
ffffffffc020168c:	af850513          	addi	a0,a0,-1288 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201690:	db7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201694:	00005697          	auipc	a3,0x5
ffffffffc0201698:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206360 <etext+0xbcc>
ffffffffc020169c:	00005617          	auipc	a2,0x5
ffffffffc02016a0:	acc60613          	addi	a2,a2,-1332 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02016a4:	11900593          	li	a1,281
ffffffffc02016a8:	00005517          	auipc	a0,0x5
ffffffffc02016ac:	ad850513          	addi	a0,a0,-1320 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02016b0:	d97fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016b4:	00005697          	auipc	a3,0x5
ffffffffc02016b8:	dcc68693          	addi	a3,a3,-564 # ffffffffc0206480 <etext+0xcec>
ffffffffc02016bc:	00005617          	auipc	a2,0x5
ffffffffc02016c0:	aac60613          	addi	a2,a2,-1364 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02016c4:	13700593          	li	a1,311
ffffffffc02016c8:	00005517          	auipc	a0,0x5
ffffffffc02016cc:	ab850513          	addi	a0,a0,-1352 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02016d0:	d77fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02016d4:	00005697          	auipc	a3,0x5
ffffffffc02016d8:	ddc68693          	addi	a3,a3,-548 # ffffffffc02064b0 <etext+0xd1c>
ffffffffc02016dc:	00005617          	auipc	a2,0x5
ffffffffc02016e0:	a8c60613          	addi	a2,a2,-1396 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02016e4:	14700593          	li	a1,327
ffffffffc02016e8:	00005517          	auipc	a0,0x5
ffffffffc02016ec:	a9850513          	addi	a0,a0,-1384 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02016f0:	d57fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc02016f4:	00005697          	auipc	a3,0x5
ffffffffc02016f8:	aa468693          	addi	a3,a3,-1372 # ffffffffc0206198 <etext+0xa04>
ffffffffc02016fc:	00005617          	auipc	a2,0x5
ffffffffc0201700:	a6c60613          	addi	a2,a2,-1428 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201704:	11300593          	li	a1,275
ffffffffc0201708:	00005517          	auipc	a0,0x5
ffffffffc020170c:	a7850513          	addi	a0,a0,-1416 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201710:	d37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201714:	00005697          	auipc	a3,0x5
ffffffffc0201718:	ac468693          	addi	a3,a3,-1340 # ffffffffc02061d8 <etext+0xa44>
ffffffffc020171c:	00005617          	auipc	a2,0x5
ffffffffc0201720:	a4c60613          	addi	a2,a2,-1460 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201724:	0d800593          	li	a1,216
ffffffffc0201728:	00005517          	auipc	a0,0x5
ffffffffc020172c:	a5850513          	addi	a0,a0,-1448 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201730:	d17fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201734 <default_free_pages>:
{
ffffffffc0201734:	1141                	addi	sp,sp,-16
ffffffffc0201736:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201738:	14058663          	beqz	a1,ffffffffc0201884 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc020173c:	00659713          	slli	a4,a1,0x6
ffffffffc0201740:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201744:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201746:	c30d                	beqz	a4,ffffffffc0201768 <default_free_pages+0x34>
ffffffffc0201748:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020174a:	8b05                	andi	a4,a4,1
ffffffffc020174c:	10071c63          	bnez	a4,ffffffffc0201864 <default_free_pages+0x130>
ffffffffc0201750:	6798                	ld	a4,8(a5)
ffffffffc0201752:	8b09                	andi	a4,a4,2
ffffffffc0201754:	10071863          	bnez	a4,ffffffffc0201864 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201758:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020175c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201760:	04078793          	addi	a5,a5,64
ffffffffc0201764:	fed792e3          	bne	a5,a3,ffffffffc0201748 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201768:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020176a:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020176e:	4789                	li	a5,2
ffffffffc0201770:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201774:	00096717          	auipc	a4,0x96
ffffffffc0201778:	fbc72703          	lw	a4,-68(a4) # ffffffffc0297730 <free_area+0x10>
ffffffffc020177c:	00096697          	auipc	a3,0x96
ffffffffc0201780:	fa468693          	addi	a3,a3,-92 # ffffffffc0297720 <free_area>
    return list->next == list;
ffffffffc0201784:	669c                	ld	a5,8(a3)
ffffffffc0201786:	9f2d                	addw	a4,a4,a1
ffffffffc0201788:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc020178a:	0ad78163          	beq	a5,a3,ffffffffc020182c <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc020178e:	fe878713          	addi	a4,a5,-24
ffffffffc0201792:	4581                	li	a1,0
ffffffffc0201794:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201798:	00e56a63          	bltu	a0,a4,ffffffffc02017ac <default_free_pages+0x78>
    return listelm->next;
ffffffffc020179c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020179e:	04d70c63          	beq	a4,a3,ffffffffc02017f6 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc02017a2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017a4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017a8:	fee57ae3          	bgeu	a0,a4,ffffffffc020179c <default_free_pages+0x68>
ffffffffc02017ac:	c199                	beqz	a1,ffffffffc02017b2 <default_free_pages+0x7e>
ffffffffc02017ae:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017b2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017b4:	e390                	sd	a2,0(a5)
ffffffffc02017b6:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02017b8:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017ba:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02017bc:	00d70d63          	beq	a4,a3,ffffffffc02017d6 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017c0:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017c4:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017c8:	02059813          	slli	a6,a1,0x20
ffffffffc02017cc:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017d0:	97b2                	add	a5,a5,a2
ffffffffc02017d2:	02f50c63          	beq	a0,a5,ffffffffc020180a <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017d6:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017d8:	00d78c63          	beq	a5,a3,ffffffffc02017f0 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017dc:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017de:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017e2:	02061593          	slli	a1,a2,0x20
ffffffffc02017e6:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017ea:	972a                	add	a4,a4,a0
ffffffffc02017ec:	04e68c63          	beq	a3,a4,ffffffffc0201844 <default_free_pages+0x110>
}
ffffffffc02017f0:	60a2                	ld	ra,8(sp)
ffffffffc02017f2:	0141                	addi	sp,sp,16
ffffffffc02017f4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017f6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017f8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017fa:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017fc:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017fe:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201800:	02d70f63          	beq	a4,a3,ffffffffc020183e <default_free_pages+0x10a>
ffffffffc0201804:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201806:	87ba                	mv	a5,a4
ffffffffc0201808:	bf71                	j	ffffffffc02017a4 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020180a:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020180c:	5875                	li	a6,-3
ffffffffc020180e:	9fad                	addw	a5,a5,a1
ffffffffc0201810:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201814:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201818:	01853803          	ld	a6,24(a0)
ffffffffc020181c:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020181e:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201820:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_exit_out_size+0xfe5e30>
    return listelm->next;
ffffffffc0201824:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201826:	0105b023          	sd	a6,0(a1)
ffffffffc020182a:	b77d                	j	ffffffffc02017d8 <default_free_pages+0xa4>
}
ffffffffc020182c:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020182e:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201832:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201834:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201836:	e398                	sd	a4,0(a5)
ffffffffc0201838:	e798                	sd	a4,8(a5)
}
ffffffffc020183a:	0141                	addi	sp,sp,16
ffffffffc020183c:	8082                	ret
ffffffffc020183e:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201840:	873e                	mv	a4,a5
ffffffffc0201842:	bfad                	j	ffffffffc02017bc <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201844:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201848:	56f5                	li	a3,-3
ffffffffc020184a:	9f31                	addw	a4,a4,a2
ffffffffc020184c:	c918                	sw	a4,16(a0)
ffffffffc020184e:	ff078713          	addi	a4,a5,-16
ffffffffc0201852:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201856:	6398                	ld	a4,0(a5)
ffffffffc0201858:	679c                	ld	a5,8(a5)
}
ffffffffc020185a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020185c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020185e:	e398                	sd	a4,0(a5)
ffffffffc0201860:	0141                	addi	sp,sp,16
ffffffffc0201862:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201864:	00005697          	auipc	a3,0x5
ffffffffc0201868:	c6468693          	addi	a3,a3,-924 # ffffffffc02064c8 <etext+0xd34>
ffffffffc020186c:	00005617          	auipc	a2,0x5
ffffffffc0201870:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201874:	09400593          	li	a1,148
ffffffffc0201878:	00005517          	auipc	a0,0x5
ffffffffc020187c:	90850513          	addi	a0,a0,-1784 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201880:	bc7fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201884:	00005697          	auipc	a3,0x5
ffffffffc0201888:	c3c68693          	addi	a3,a3,-964 # ffffffffc02064c0 <etext+0xd2c>
ffffffffc020188c:	00005617          	auipc	a2,0x5
ffffffffc0201890:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201894:	09000593          	li	a1,144
ffffffffc0201898:	00005517          	auipc	a0,0x5
ffffffffc020189c:	8e850513          	addi	a0,a0,-1816 # ffffffffc0206180 <etext+0x9ec>
ffffffffc02018a0:	ba7fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02018a4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018a4:	c951                	beqz	a0,ffffffffc0201938 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02018a6:	00096597          	auipc	a1,0x96
ffffffffc02018aa:	e8a5a583          	lw	a1,-374(a1) # ffffffffc0297730 <free_area+0x10>
ffffffffc02018ae:	86aa                	mv	a3,a0
ffffffffc02018b0:	02059793          	slli	a5,a1,0x20
ffffffffc02018b4:	9381                	srli	a5,a5,0x20
ffffffffc02018b6:	00a7ef63          	bltu	a5,a0,ffffffffc02018d4 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02018ba:	00096617          	auipc	a2,0x96
ffffffffc02018be:	e6660613          	addi	a2,a2,-410 # ffffffffc0297720 <free_area>
ffffffffc02018c2:	87b2                	mv	a5,a2
ffffffffc02018c4:	a029                	j	ffffffffc02018ce <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02018c6:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02018ca:	00d77763          	bgeu	a4,a3,ffffffffc02018d8 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02018ce:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018d0:	fec79be3          	bne	a5,a2,ffffffffc02018c6 <default_alloc_pages+0x22>
        return NULL;
ffffffffc02018d4:	4501                	li	a0,0
}
ffffffffc02018d6:	8082                	ret
        if (page->property > n)
ffffffffc02018d8:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02018dc:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018e0:	6798                	ld	a4,8(a5)
ffffffffc02018e2:	02089313          	slli	t1,a7,0x20
ffffffffc02018e6:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02018ea:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02018ee:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02018f2:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc02018f6:	0266fa63          	bgeu	a3,t1,ffffffffc020192a <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02018fa:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02018fe:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc0201902:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201904:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201908:	00870313          	addi	t1,a4,8
ffffffffc020190c:	4889                	li	a7,2
ffffffffc020190e:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201912:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201916:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc020191a:	0068b023          	sd	t1,0(a7)
ffffffffc020191e:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0201922:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0201926:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc020192a:	9d95                	subw	a1,a1,a3
ffffffffc020192c:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020192e:	5775                	li	a4,-3
ffffffffc0201930:	17c1                	addi	a5,a5,-16
ffffffffc0201932:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201936:	8082                	ret
{
ffffffffc0201938:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020193a:	00005697          	auipc	a3,0x5
ffffffffc020193e:	b8668693          	addi	a3,a3,-1146 # ffffffffc02064c0 <etext+0xd2c>
ffffffffc0201942:	00005617          	auipc	a2,0x5
ffffffffc0201946:	82660613          	addi	a2,a2,-2010 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020194a:	06c00593          	li	a1,108
ffffffffc020194e:	00005517          	auipc	a0,0x5
ffffffffc0201952:	83250513          	addi	a0,a0,-1998 # ffffffffc0206180 <etext+0x9ec>
{
ffffffffc0201956:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201958:	aeffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020195c <default_init_memmap>:
{
ffffffffc020195c:	1141                	addi	sp,sp,-16
ffffffffc020195e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201960:	c9e1                	beqz	a1,ffffffffc0201a30 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc0201962:	00659713          	slli	a4,a1,0x6
ffffffffc0201966:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020196a:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020196c:	cf11                	beqz	a4,ffffffffc0201988 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020196e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201970:	8b05                	andi	a4,a4,1
ffffffffc0201972:	cf59                	beqz	a4,ffffffffc0201a10 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201974:	0007a823          	sw	zero,16(a5)
ffffffffc0201978:	0007b423          	sd	zero,8(a5)
ffffffffc020197c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201980:	04078793          	addi	a5,a5,64
ffffffffc0201984:	fed795e3          	bne	a5,a3,ffffffffc020196e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201988:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020198a:	4789                	li	a5,2
ffffffffc020198c:	00850713          	addi	a4,a0,8
ffffffffc0201990:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201994:	00096717          	auipc	a4,0x96
ffffffffc0201998:	d9c72703          	lw	a4,-612(a4) # ffffffffc0297730 <free_area+0x10>
ffffffffc020199c:	00096697          	auipc	a3,0x96
ffffffffc02019a0:	d8468693          	addi	a3,a3,-636 # ffffffffc0297720 <free_area>
    return list->next == list;
ffffffffc02019a4:	669c                	ld	a5,8(a3)
ffffffffc02019a6:	9f2d                	addw	a4,a4,a1
ffffffffc02019a8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02019aa:	04d78663          	beq	a5,a3,ffffffffc02019f6 <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02019ae:	fe878713          	addi	a4,a5,-24
ffffffffc02019b2:	4581                	li	a1,0
ffffffffc02019b4:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02019b8:	00e56a63          	bltu	a0,a4,ffffffffc02019cc <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019bc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019be:	02d70263          	beq	a4,a3,ffffffffc02019e2 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02019c2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019c4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019c8:	fee57ae3          	bgeu	a0,a4,ffffffffc02019bc <default_init_memmap+0x60>
ffffffffc02019cc:	c199                	beqz	a1,ffffffffc02019d2 <default_init_memmap+0x76>
ffffffffc02019ce:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019d2:	6398                	ld	a4,0(a5)
}
ffffffffc02019d4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019d6:	e390                	sd	a2,0(a5)
ffffffffc02019d8:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02019da:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02019dc:	f11c                	sd	a5,32(a0)
ffffffffc02019de:	0141                	addi	sp,sp,16
ffffffffc02019e0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019e2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019e4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019e6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019e8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02019ea:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02019ec:	00d70e63          	beq	a4,a3,ffffffffc0201a08 <default_init_memmap+0xac>
ffffffffc02019f0:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02019f2:	87ba                	mv	a5,a4
ffffffffc02019f4:	bfc1                	j	ffffffffc02019c4 <default_init_memmap+0x68>
}
ffffffffc02019f6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02019f8:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02019fc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019fe:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201a00:	e398                	sd	a4,0(a5)
ffffffffc0201a02:	e798                	sd	a4,8(a5)
}
ffffffffc0201a04:	0141                	addi	sp,sp,16
ffffffffc0201a06:	8082                	ret
ffffffffc0201a08:	60a2                	ld	ra,8(sp)
ffffffffc0201a0a:	e290                	sd	a2,0(a3)
ffffffffc0201a0c:	0141                	addi	sp,sp,16
ffffffffc0201a0e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a10:	00005697          	auipc	a3,0x5
ffffffffc0201a14:	ae068693          	addi	a3,a3,-1312 # ffffffffc02064f0 <etext+0xd5c>
ffffffffc0201a18:	00004617          	auipc	a2,0x4
ffffffffc0201a1c:	75060613          	addi	a2,a2,1872 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201a20:	04b00593          	li	a1,75
ffffffffc0201a24:	00004517          	auipc	a0,0x4
ffffffffc0201a28:	75c50513          	addi	a0,a0,1884 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201a2c:	a1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201a30:	00005697          	auipc	a3,0x5
ffffffffc0201a34:	a9068693          	addi	a3,a3,-1392 # ffffffffc02064c0 <etext+0xd2c>
ffffffffc0201a38:	00004617          	auipc	a2,0x4
ffffffffc0201a3c:	73060613          	addi	a2,a2,1840 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201a40:	04700593          	li	a1,71
ffffffffc0201a44:	00004517          	auipc	a0,0x4
ffffffffc0201a48:	73c50513          	addi	a0,a0,1852 # ffffffffc0206180 <etext+0x9ec>
ffffffffc0201a4c:	9fbfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201a50 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a50:	c531                	beqz	a0,ffffffffc0201a9c <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201a52:	e9b9                	bnez	a1,ffffffffc0201aa8 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a54:	100027f3          	csrr	a5,sstatus
ffffffffc0201a58:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a5a:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a5c:	efb1                	bnez	a5,ffffffffc0201ab8 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a5e:	00096797          	auipc	a5,0x96
ffffffffc0201a62:	8b27b783          	ld	a5,-1870(a5) # ffffffffc0297310 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a66:	873e                	mv	a4,a5
ffffffffc0201a68:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a6a:	02a77a63          	bgeu	a4,a0,ffffffffc0201a9e <slob_free+0x4e>
ffffffffc0201a6e:	00f56463          	bltu	a0,a5,ffffffffc0201a76 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a72:	fef76ae3          	bltu	a4,a5,ffffffffc0201a66 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a76:	4110                	lw	a2,0(a0)
ffffffffc0201a78:	00461693          	slli	a3,a2,0x4
ffffffffc0201a7c:	96aa                	add	a3,a3,a0
ffffffffc0201a7e:	0ad78463          	beq	a5,a3,ffffffffc0201b26 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a82:	4310                	lw	a2,0(a4)
ffffffffc0201a84:	e51c                	sd	a5,8(a0)
ffffffffc0201a86:	00461693          	slli	a3,a2,0x4
ffffffffc0201a8a:	96ba                	add	a3,a3,a4
ffffffffc0201a8c:	08d50163          	beq	a0,a3,ffffffffc0201b0e <slob_free+0xbe>
ffffffffc0201a90:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201a92:	00096797          	auipc	a5,0x96
ffffffffc0201a96:	86e7bf23          	sd	a4,-1922(a5) # ffffffffc0297310 <slobfree>
    if (flag)
ffffffffc0201a9a:	e9a5                	bnez	a1,ffffffffc0201b0a <slob_free+0xba>
ffffffffc0201a9c:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a9e:	fcf574e3          	bgeu	a0,a5,ffffffffc0201a66 <slob_free+0x16>
ffffffffc0201aa2:	fcf762e3          	bltu	a4,a5,ffffffffc0201a66 <slob_free+0x16>
ffffffffc0201aa6:	bfc1                	j	ffffffffc0201a76 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201aa8:	25bd                	addiw	a1,a1,15
ffffffffc0201aaa:	8191                	srli	a1,a1,0x4
ffffffffc0201aac:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aae:	100027f3          	csrr	a5,sstatus
ffffffffc0201ab2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ab4:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ab6:	d7c5                	beqz	a5,ffffffffc0201a5e <slob_free+0xe>
{
ffffffffc0201ab8:	1101                	addi	sp,sp,-32
ffffffffc0201aba:	e42a                	sd	a0,8(sp)
ffffffffc0201abc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201abe:	e47fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201ac2:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ac4:	00096797          	auipc	a5,0x96
ffffffffc0201ac8:	84c7b783          	ld	a5,-1972(a5) # ffffffffc0297310 <slobfree>
ffffffffc0201acc:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ace:	873e                	mv	a4,a5
ffffffffc0201ad0:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ad2:	06a77663          	bgeu	a4,a0,ffffffffc0201b3e <slob_free+0xee>
ffffffffc0201ad6:	00f56463          	bltu	a0,a5,ffffffffc0201ade <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ada:	fef76ae3          	bltu	a4,a5,ffffffffc0201ace <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201ade:	4110                	lw	a2,0(a0)
ffffffffc0201ae0:	00461693          	slli	a3,a2,0x4
ffffffffc0201ae4:	96aa                	add	a3,a3,a0
ffffffffc0201ae6:	06d78363          	beq	a5,a3,ffffffffc0201b4c <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201aea:	4310                	lw	a2,0(a4)
ffffffffc0201aec:	e51c                	sd	a5,8(a0)
ffffffffc0201aee:	00461693          	slli	a3,a2,0x4
ffffffffc0201af2:	96ba                	add	a3,a3,a4
ffffffffc0201af4:	06d50163          	beq	a0,a3,ffffffffc0201b56 <slob_free+0x106>
ffffffffc0201af8:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201afa:	00096797          	auipc	a5,0x96
ffffffffc0201afe:	80e7bb23          	sd	a4,-2026(a5) # ffffffffc0297310 <slobfree>
    if (flag)
ffffffffc0201b02:	e1a9                	bnez	a1,ffffffffc0201b44 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b04:	60e2                	ld	ra,24(sp)
ffffffffc0201b06:	6105                	addi	sp,sp,32
ffffffffc0201b08:	8082                	ret
        intr_enable();
ffffffffc0201b0a:	df5fe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201b0e:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b10:	853e                	mv	a0,a5
ffffffffc0201b12:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b14:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b18:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b1a:	00095797          	auipc	a5,0x95
ffffffffc0201b1e:	7ee7bb23          	sd	a4,2038(a5) # ffffffffc0297310 <slobfree>
    if (flag)
ffffffffc0201b22:	ddad                	beqz	a1,ffffffffc0201a9c <slob_free+0x4c>
ffffffffc0201b24:	b7dd                	j	ffffffffc0201b0a <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b26:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b28:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b2a:	9eb1                	addw	a3,a3,a2
ffffffffc0201b2c:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b2e:	4310                	lw	a2,0(a4)
ffffffffc0201b30:	e51c                	sd	a5,8(a0)
ffffffffc0201b32:	00461693          	slli	a3,a2,0x4
ffffffffc0201b36:	96ba                	add	a3,a3,a4
ffffffffc0201b38:	f4d51ce3          	bne	a0,a3,ffffffffc0201a90 <slob_free+0x40>
ffffffffc0201b3c:	bfc9                	j	ffffffffc0201b0e <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b3e:	f8f56ee3          	bltu	a0,a5,ffffffffc0201ada <slob_free+0x8a>
ffffffffc0201b42:	b771                	j	ffffffffc0201ace <slob_free+0x7e>
}
ffffffffc0201b44:	60e2                	ld	ra,24(sp)
ffffffffc0201b46:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201b48:	db7fe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201b4c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b4e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b50:	9eb1                	addw	a3,a3,a2
ffffffffc0201b52:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201b54:	bf59                	j	ffffffffc0201aea <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201b56:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b58:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201b5a:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b5e:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201b60:	bf61                	j	ffffffffc0201af8 <slob_free+0xa8>

ffffffffc0201b62 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b62:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b64:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b66:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b6a:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b6c:	32a000ef          	jal	ffffffffc0201e96 <alloc_pages>
	if (!page)
ffffffffc0201b70:	c91d                	beqz	a0,ffffffffc0201ba6 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b72:	0009a697          	auipc	a3,0x9a
ffffffffc0201b76:	c366b683          	ld	a3,-970(a3) # ffffffffc029b7a8 <pages>
ffffffffc0201b7a:	00006797          	auipc	a5,0x6
ffffffffc0201b7e:	d5e7b783          	ld	a5,-674(a5) # ffffffffc02078d8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201b82:	0009a717          	auipc	a4,0x9a
ffffffffc0201b86:	c1e73703          	ld	a4,-994(a4) # ffffffffc029b7a0 <npage>
    return page - pages + nbase;
ffffffffc0201b8a:	8d15                	sub	a0,a0,a3
ffffffffc0201b8c:	8519                	srai	a0,a0,0x6
ffffffffc0201b8e:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201b90:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b94:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b96:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b98:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bac <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b9c:	0009a797          	auipc	a5,0x9a
ffffffffc0201ba0:	bfc7b783          	ld	a5,-1028(a5) # ffffffffc029b798 <va_pa_offset>
ffffffffc0201ba4:	953e                	add	a0,a0,a5
}
ffffffffc0201ba6:	60a2                	ld	ra,8(sp)
ffffffffc0201ba8:	0141                	addi	sp,sp,16
ffffffffc0201baa:	8082                	ret
ffffffffc0201bac:	86aa                	mv	a3,a0
ffffffffc0201bae:	00005617          	auipc	a2,0x5
ffffffffc0201bb2:	96a60613          	addi	a2,a2,-1686 # ffffffffc0206518 <etext+0xd84>
ffffffffc0201bb6:	07100593          	li	a1,113
ffffffffc0201bba:	00005517          	auipc	a0,0x5
ffffffffc0201bbe:	98650513          	addi	a0,a0,-1658 # ffffffffc0206540 <etext+0xdac>
ffffffffc0201bc2:	885fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201bc6 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201bc6:	7179                	addi	sp,sp,-48
ffffffffc0201bc8:	f406                	sd	ra,40(sp)
ffffffffc0201bca:	f022                	sd	s0,32(sp)
ffffffffc0201bcc:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bce:	01050713          	addi	a4,a0,16
ffffffffc0201bd2:	6785                	lui	a5,0x1
ffffffffc0201bd4:	0af77e63          	bgeu	a4,a5,ffffffffc0201c90 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bd8:	00f50413          	addi	s0,a0,15
ffffffffc0201bdc:	8011                	srli	s0,s0,0x4
ffffffffc0201bde:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201be0:	100025f3          	csrr	a1,sstatus
ffffffffc0201be4:	8989                	andi	a1,a1,2
ffffffffc0201be6:	edd1                	bnez	a1,ffffffffc0201c82 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201be8:	00095497          	auipc	s1,0x95
ffffffffc0201bec:	72848493          	addi	s1,s1,1832 # ffffffffc0297310 <slobfree>
ffffffffc0201bf0:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bf2:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201bf4:	4314                	lw	a3,0(a4)
ffffffffc0201bf6:	0886da63          	bge	a3,s0,ffffffffc0201c8a <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201bfa:	00e60a63          	beq	a2,a4,ffffffffc0201c0e <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bfe:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c00:	4394                	lw	a3,0(a5)
ffffffffc0201c02:	0286d863          	bge	a3,s0,ffffffffc0201c32 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c06:	6090                	ld	a2,0(s1)
ffffffffc0201c08:	873e                	mv	a4,a5
ffffffffc0201c0a:	fee61ae3          	bne	a2,a4,ffffffffc0201bfe <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c0e:	e9b1                	bnez	a1,ffffffffc0201c62 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c10:	4501                	li	a0,0
ffffffffc0201c12:	f51ff0ef          	jal	ffffffffc0201b62 <__slob_get_free_pages.constprop.0>
ffffffffc0201c16:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c18:	c915                	beqz	a0,ffffffffc0201c4c <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c1a:	6585                	lui	a1,0x1
ffffffffc0201c1c:	e35ff0ef          	jal	ffffffffc0201a50 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c20:	100025f3          	csrr	a1,sstatus
ffffffffc0201c24:	8989                	andi	a1,a1,2
ffffffffc0201c26:	e98d                	bnez	a1,ffffffffc0201c58 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c28:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c2a:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c2c:	4394                	lw	a3,0(a5)
ffffffffc0201c2e:	fc86cce3          	blt	a3,s0,ffffffffc0201c06 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c32:	04d40563          	beq	s0,a3,ffffffffc0201c7c <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c36:	00441613          	slli	a2,s0,0x4
ffffffffc0201c3a:	963e                	add	a2,a2,a5
ffffffffc0201c3c:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c3e:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201c40:	9e81                	subw	a3,a3,s0
ffffffffc0201c42:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201c44:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201c46:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201c48:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201c4a:	ed99                	bnez	a1,ffffffffc0201c68 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201c4c:	70a2                	ld	ra,40(sp)
ffffffffc0201c4e:	7402                	ld	s0,32(sp)
ffffffffc0201c50:	64e2                	ld	s1,24(sp)
ffffffffc0201c52:	853e                	mv	a0,a5
ffffffffc0201c54:	6145                	addi	sp,sp,48
ffffffffc0201c56:	8082                	ret
        intr_disable();
ffffffffc0201c58:	cadfe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201c5c:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201c5e:	4585                	li	a1,1
ffffffffc0201c60:	b7e9                	j	ffffffffc0201c2a <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201c62:	c9dfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c66:	b76d                	j	ffffffffc0201c10 <slob_alloc.constprop.0+0x4a>
ffffffffc0201c68:	e43e                	sd	a5,8(sp)
ffffffffc0201c6a:	c95fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c6e:	67a2                	ld	a5,8(sp)
}
ffffffffc0201c70:	70a2                	ld	ra,40(sp)
ffffffffc0201c72:	7402                	ld	s0,32(sp)
ffffffffc0201c74:	64e2                	ld	s1,24(sp)
ffffffffc0201c76:	853e                	mv	a0,a5
ffffffffc0201c78:	6145                	addi	sp,sp,48
ffffffffc0201c7a:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c7c:	6794                	ld	a3,8(a5)
ffffffffc0201c7e:	e714                	sd	a3,8(a4)
ffffffffc0201c80:	b7e1                	j	ffffffffc0201c48 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201c82:	c83fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201c86:	4585                	li	a1,1
ffffffffc0201c88:	b785                	j	ffffffffc0201be8 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c8a:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201c8c:	8732                	mv	a4,a2
ffffffffc0201c8e:	b755                	j	ffffffffc0201c32 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c90:	00005697          	auipc	a3,0x5
ffffffffc0201c94:	8c068693          	addi	a3,a3,-1856 # ffffffffc0206550 <etext+0xdbc>
ffffffffc0201c98:	00004617          	auipc	a2,0x4
ffffffffc0201c9c:	4d060613          	addi	a2,a2,1232 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0201ca0:	06300593          	li	a1,99
ffffffffc0201ca4:	00005517          	auipc	a0,0x5
ffffffffc0201ca8:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0206570 <etext+0xddc>
ffffffffc0201cac:	f9afe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201cb0 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cb0:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201cb2:	00005517          	auipc	a0,0x5
ffffffffc0201cb6:	8d650513          	addi	a0,a0,-1834 # ffffffffc0206588 <etext+0xdf4>
{
ffffffffc0201cba:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201cbc:	cd8fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cc0:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cc2:	00005517          	auipc	a0,0x5
ffffffffc0201cc6:	8de50513          	addi	a0,a0,-1826 # ffffffffc02065a0 <etext+0xe0c>
}
ffffffffc0201cca:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ccc:	cc8fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201cd0 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201cd0:	4501                	li	a0,0
ffffffffc0201cd2:	8082                	ret

ffffffffc0201cd4 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cd4:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cd6:	6685                	lui	a3,0x1
{
ffffffffc0201cd8:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cda:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7be1>
ffffffffc0201cdc:	04a6f963          	bgeu	a3,a0,ffffffffc0201d2e <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ce0:	e42a                	sd	a0,8(sp)
ffffffffc0201ce2:	4561                	li	a0,24
ffffffffc0201ce4:	e822                	sd	s0,16(sp)
ffffffffc0201ce6:	ee1ff0ef          	jal	ffffffffc0201bc6 <slob_alloc.constprop.0>
ffffffffc0201cea:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201cec:	c541                	beqz	a0,ffffffffc0201d74 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201cee:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201cf0:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201cf2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201cf4:	00f75763          	bge	a4,a5,ffffffffc0201d02 <kmalloc+0x2e>
ffffffffc0201cf8:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201cfc:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cfe:	fef74de3          	blt	a4,a5,ffffffffc0201cf8 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201d02:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d04:	e5fff0ef          	jal	ffffffffc0201b62 <__slob_get_free_pages.constprop.0>
ffffffffc0201d08:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d0a:	cd31                	beqz	a0,ffffffffc0201d66 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d10:	8b89                	andi	a5,a5,2
ffffffffc0201d12:	eb85                	bnez	a5,ffffffffc0201d42 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d14:	0009a797          	auipc	a5,0x9a
ffffffffc0201d18:	a647b783          	ld	a5,-1436(a5) # ffffffffc029b778 <bigblocks>
		bigblocks = bb;
ffffffffc0201d1c:	0009a717          	auipc	a4,0x9a
ffffffffc0201d20:	a4873e23          	sd	s0,-1444(a4) # ffffffffc029b778 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d24:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d26:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d28:	60e2                	ld	ra,24(sp)
ffffffffc0201d2a:	6105                	addi	sp,sp,32
ffffffffc0201d2c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d2e:	0541                	addi	a0,a0,16
ffffffffc0201d30:	e97ff0ef          	jal	ffffffffc0201bc6 <slob_alloc.constprop.0>
ffffffffc0201d34:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d36:	0541                	addi	a0,a0,16
ffffffffc0201d38:	fbe5                	bnez	a5,ffffffffc0201d28 <kmalloc+0x54>
		return 0;
ffffffffc0201d3a:	4501                	li	a0,0
}
ffffffffc0201d3c:	60e2                	ld	ra,24(sp)
ffffffffc0201d3e:	6105                	addi	sp,sp,32
ffffffffc0201d40:	8082                	ret
        intr_disable();
ffffffffc0201d42:	bc3fe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d46:	0009a797          	auipc	a5,0x9a
ffffffffc0201d4a:	a327b783          	ld	a5,-1486(a5) # ffffffffc029b778 <bigblocks>
		bigblocks = bb;
ffffffffc0201d4e:	0009a717          	auipc	a4,0x9a
ffffffffc0201d52:	a2873523          	sd	s0,-1494(a4) # ffffffffc029b778 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d56:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201d58:	ba7fe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201d5c:	6408                	ld	a0,8(s0)
}
ffffffffc0201d5e:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201d60:	6442                	ld	s0,16(sp)
}
ffffffffc0201d62:	6105                	addi	sp,sp,32
ffffffffc0201d64:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d66:	8522                	mv	a0,s0
ffffffffc0201d68:	45e1                	li	a1,24
ffffffffc0201d6a:	ce7ff0ef          	jal	ffffffffc0201a50 <slob_free>
		return 0;
ffffffffc0201d6e:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d70:	6442                	ld	s0,16(sp)
ffffffffc0201d72:	b7e9                	j	ffffffffc0201d3c <kmalloc+0x68>
ffffffffc0201d74:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201d76:	4501                	li	a0,0
ffffffffc0201d78:	b7d1                	j	ffffffffc0201d3c <kmalloc+0x68>

ffffffffc0201d7a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d7a:	c571                	beqz	a0,ffffffffc0201e46 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d7c:	03451793          	slli	a5,a0,0x34
ffffffffc0201d80:	e3e1                	bnez	a5,ffffffffc0201e40 <kfree+0xc6>
{
ffffffffc0201d82:	1101                	addi	sp,sp,-32
ffffffffc0201d84:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d86:	100027f3          	csrr	a5,sstatus
ffffffffc0201d8a:	8b89                	andi	a5,a5,2
ffffffffc0201d8c:	e7c1                	bnez	a5,ffffffffc0201e14 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d8e:	0009a797          	auipc	a5,0x9a
ffffffffc0201d92:	9ea7b783          	ld	a5,-1558(a5) # ffffffffc029b778 <bigblocks>
    return 0;
ffffffffc0201d96:	4581                	li	a1,0
ffffffffc0201d98:	cbad                	beqz	a5,ffffffffc0201e0a <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d9a:	0009a617          	auipc	a2,0x9a
ffffffffc0201d9e:	9de60613          	addi	a2,a2,-1570 # ffffffffc029b778 <bigblocks>
ffffffffc0201da2:	a021                	j	ffffffffc0201daa <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201da4:	01070613          	addi	a2,a4,16
ffffffffc0201da8:	c3a5                	beqz	a5,ffffffffc0201e08 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201daa:	6794                	ld	a3,8(a5)
ffffffffc0201dac:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201dae:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201db0:	fea69ae3          	bne	a3,a0,ffffffffc0201da4 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201db4:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201db6:	edb5                	bnez	a1,ffffffffc0201e32 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201db8:	c02007b7          	lui	a5,0xc0200
ffffffffc0201dbc:	0af56263          	bltu	a0,a5,ffffffffc0201e60 <kfree+0xe6>
ffffffffc0201dc0:	0009a797          	auipc	a5,0x9a
ffffffffc0201dc4:	9d87b783          	ld	a5,-1576(a5) # ffffffffc029b798 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201dc8:	0009a697          	auipc	a3,0x9a
ffffffffc0201dcc:	9d86b683          	ld	a3,-1576(a3) # ffffffffc029b7a0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201dd0:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201dd2:	00c55793          	srli	a5,a0,0xc
ffffffffc0201dd6:	06d7f963          	bgeu	a5,a3,ffffffffc0201e48 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dda:	00006617          	auipc	a2,0x6
ffffffffc0201dde:	afe63603          	ld	a2,-1282(a2) # ffffffffc02078d8 <nbase>
ffffffffc0201de2:	0009a517          	auipc	a0,0x9a
ffffffffc0201de6:	9c653503          	ld	a0,-1594(a0) # ffffffffc029b7a8 <pages>
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201dea:	4314                	lw	a3,0(a4)
ffffffffc0201dec:	8f91                	sub	a5,a5,a2
ffffffffc0201dee:	079a                	slli	a5,a5,0x6
ffffffffc0201df0:	4585                	li	a1,1
ffffffffc0201df2:	953e                	add	a0,a0,a5
ffffffffc0201df4:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201df8:	e03a                	sd	a4,0(sp)
ffffffffc0201dfa:	0d6000ef          	jal	ffffffffc0201ed0 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dfe:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e00:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e02:	45e1                	li	a1,24
}
ffffffffc0201e04:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e06:	b1a9                	j	ffffffffc0201a50 <slob_free>
ffffffffc0201e08:	e185                	bnez	a1,ffffffffc0201e28 <kfree+0xae>
}
ffffffffc0201e0a:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e0c:	1541                	addi	a0,a0,-16
ffffffffc0201e0e:	4581                	li	a1,0
}
ffffffffc0201e10:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e12:	b93d                	j	ffffffffc0201a50 <slob_free>
        intr_disable();
ffffffffc0201e14:	e02a                	sd	a0,0(sp)
ffffffffc0201e16:	aeffe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e1a:	0009a797          	auipc	a5,0x9a
ffffffffc0201e1e:	95e7b783          	ld	a5,-1698(a5) # ffffffffc029b778 <bigblocks>
ffffffffc0201e22:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e24:	4585                	li	a1,1
ffffffffc0201e26:	fbb5                	bnez	a5,ffffffffc0201d9a <kfree+0x20>
ffffffffc0201e28:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e2a:	ad5fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e2e:	6502                	ld	a0,0(sp)
ffffffffc0201e30:	bfe9                	j	ffffffffc0201e0a <kfree+0x90>
ffffffffc0201e32:	e42a                	sd	a0,8(sp)
ffffffffc0201e34:	e03a                	sd	a4,0(sp)
ffffffffc0201e36:	ac9fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e3a:	6522                	ld	a0,8(sp)
ffffffffc0201e3c:	6702                	ld	a4,0(sp)
ffffffffc0201e3e:	bfad                	j	ffffffffc0201db8 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e40:	1541                	addi	a0,a0,-16
ffffffffc0201e42:	4581                	li	a1,0
ffffffffc0201e44:	b131                	j	ffffffffc0201a50 <slob_free>
ffffffffc0201e46:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e48:	00004617          	auipc	a2,0x4
ffffffffc0201e4c:	7a060613          	addi	a2,a2,1952 # ffffffffc02065e8 <etext+0xe54>
ffffffffc0201e50:	06900593          	li	a1,105
ffffffffc0201e54:	00004517          	auipc	a0,0x4
ffffffffc0201e58:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206540 <etext+0xdac>
ffffffffc0201e5c:	deafe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e60:	86aa                	mv	a3,a0
ffffffffc0201e62:	00004617          	auipc	a2,0x4
ffffffffc0201e66:	75e60613          	addi	a2,a2,1886 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc0201e6a:	07700593          	li	a1,119
ffffffffc0201e6e:	00004517          	auipc	a0,0x4
ffffffffc0201e72:	6d250513          	addi	a0,a0,1746 # ffffffffc0206540 <etext+0xdac>
ffffffffc0201e76:	dd0fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e7a <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e7a:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e7c:	00004617          	auipc	a2,0x4
ffffffffc0201e80:	76c60613          	addi	a2,a2,1900 # ffffffffc02065e8 <etext+0xe54>
ffffffffc0201e84:	06900593          	li	a1,105
ffffffffc0201e88:	00004517          	auipc	a0,0x4
ffffffffc0201e8c:	6b850513          	addi	a0,a0,1720 # ffffffffc0206540 <etext+0xdac>
pa2page(uintptr_t pa)
ffffffffc0201e90:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e92:	db4fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e96 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e96:	100027f3          	csrr	a5,sstatus
ffffffffc0201e9a:	8b89                	andi	a5,a5,2
ffffffffc0201e9c:	e799                	bnez	a5,ffffffffc0201eaa <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e9e:	0009a797          	auipc	a5,0x9a
ffffffffc0201ea2:	8e27b783          	ld	a5,-1822(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201ea6:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea8:	8782                	jr	a5
{
ffffffffc0201eaa:	1101                	addi	sp,sp,-32
ffffffffc0201eac:	ec06                	sd	ra,24(sp)
ffffffffc0201eae:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201eb0:	a55fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eb4:	0009a797          	auipc	a5,0x9a
ffffffffc0201eb8:	8cc7b783          	ld	a5,-1844(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201ebc:	6522                	ld	a0,8(sp)
ffffffffc0201ebe:	6f9c                	ld	a5,24(a5)
ffffffffc0201ec0:	9782                	jalr	a5
ffffffffc0201ec2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ec4:	a3bfe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ec8:	60e2                	ld	ra,24(sp)
ffffffffc0201eca:	6522                	ld	a0,8(sp)
ffffffffc0201ecc:	6105                	addi	sp,sp,32
ffffffffc0201ece:	8082                	ret

ffffffffc0201ed0 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ed0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed4:	8b89                	andi	a5,a5,2
ffffffffc0201ed6:	e799                	bnez	a5,ffffffffc0201ee4 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ed8:	0009a797          	auipc	a5,0x9a
ffffffffc0201edc:	8a87b783          	ld	a5,-1880(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201ee0:	739c                	ld	a5,32(a5)
ffffffffc0201ee2:	8782                	jr	a5
{
ffffffffc0201ee4:	1101                	addi	sp,sp,-32
ffffffffc0201ee6:	ec06                	sd	ra,24(sp)
ffffffffc0201ee8:	e42e                	sd	a1,8(sp)
ffffffffc0201eea:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201eec:	a19fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ef0:	0009a797          	auipc	a5,0x9a
ffffffffc0201ef4:	8907b783          	ld	a5,-1904(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201ef8:	65a2                	ld	a1,8(sp)
ffffffffc0201efa:	6502                	ld	a0,0(sp)
ffffffffc0201efc:	739c                	ld	a5,32(a5)
ffffffffc0201efe:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f00:	60e2                	ld	ra,24(sp)
ffffffffc0201f02:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f04:	9fbfe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201f08 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f08:	100027f3          	csrr	a5,sstatus
ffffffffc0201f0c:	8b89                	andi	a5,a5,2
ffffffffc0201f0e:	e799                	bnez	a5,ffffffffc0201f1c <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f10:	0009a797          	auipc	a5,0x9a
ffffffffc0201f14:	8707b783          	ld	a5,-1936(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201f18:	779c                	ld	a5,40(a5)
ffffffffc0201f1a:	8782                	jr	a5
{
ffffffffc0201f1c:	1101                	addi	sp,sp,-32
ffffffffc0201f1e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f20:	9e5fe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f24:	0009a797          	auipc	a5,0x9a
ffffffffc0201f28:	85c7b783          	ld	a5,-1956(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201f2c:	779c                	ld	a5,40(a5)
ffffffffc0201f2e:	9782                	jalr	a5
ffffffffc0201f30:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f32:	9cdfe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f36:	60e2                	ld	ra,24(sp)
ffffffffc0201f38:	6522                	ld	a0,8(sp)
ffffffffc0201f3a:	6105                	addi	sp,sp,32
ffffffffc0201f3c:	8082                	ret

ffffffffc0201f3e <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f3e:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f42:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f46:	078e                	slli	a5,a5,0x3
ffffffffc0201f48:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f4c:	6314                	ld	a3,0(a4)
{
ffffffffc0201f4e:	7139                	addi	sp,sp,-64
ffffffffc0201f50:	f822                	sd	s0,48(sp)
ffffffffc0201f52:	f426                	sd	s1,40(sp)
ffffffffc0201f54:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f56:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f5a:	842e                	mv	s0,a1
ffffffffc0201f5c:	8832                	mv	a6,a2
ffffffffc0201f5e:	0009a497          	auipc	s1,0x9a
ffffffffc0201f62:	84248493          	addi	s1,s1,-1982 # ffffffffc029b7a0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f66:	ebd1                	bnez	a5,ffffffffc0201ffa <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f68:	16060d63          	beqz	a2,ffffffffc02020e2 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f6c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f70:	8b89                	andi	a5,a5,2
ffffffffc0201f72:	16079e63          	bnez	a5,ffffffffc02020ee <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f76:	0009a797          	auipc	a5,0x9a
ffffffffc0201f7a:	80a7b783          	ld	a5,-2038(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201f7e:	4505                	li	a0,1
ffffffffc0201f80:	e43a                	sd	a4,8(sp)
ffffffffc0201f82:	6f9c                	ld	a5,24(a5)
ffffffffc0201f84:	e832                	sd	a2,16(sp)
ffffffffc0201f86:	9782                	jalr	a5
ffffffffc0201f88:	6722                	ld	a4,8(sp)
ffffffffc0201f8a:	6842                	ld	a6,16(sp)
ffffffffc0201f8c:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f8e:	14078a63          	beqz	a5,ffffffffc02020e2 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f92:	0009a517          	auipc	a0,0x9a
ffffffffc0201f96:	81653503          	ld	a0,-2026(a0) # ffffffffc029b7a8 <pages>
ffffffffc0201f9a:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f9e:	0009a497          	auipc	s1,0x9a
ffffffffc0201fa2:	80248493          	addi	s1,s1,-2046 # ffffffffc029b7a0 <npage>
ffffffffc0201fa6:	40a78533          	sub	a0,a5,a0
ffffffffc0201faa:	8519                	srai	a0,a0,0x6
ffffffffc0201fac:	9546                	add	a0,a0,a7
ffffffffc0201fae:	6090                	ld	a2,0(s1)
ffffffffc0201fb0:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201fb4:	4585                	li	a1,1
ffffffffc0201fb6:	82b1                	srli	a3,a3,0xc
ffffffffc0201fb8:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fba:	0532                	slli	a0,a0,0xc
ffffffffc0201fbc:	1ac6f763          	bgeu	a3,a2,ffffffffc020216a <get_pte+0x22c>
ffffffffc0201fc0:	00099697          	auipc	a3,0x99
ffffffffc0201fc4:	7d86b683          	ld	a3,2008(a3) # ffffffffc029b798 <va_pa_offset>
ffffffffc0201fc8:	6605                	lui	a2,0x1
ffffffffc0201fca:	4581                	li	a1,0
ffffffffc0201fcc:	9536                	add	a0,a0,a3
ffffffffc0201fce:	ec42                	sd	a6,24(sp)
ffffffffc0201fd0:	e83e                	sd	a5,16(sp)
ffffffffc0201fd2:	e43a                	sd	a4,8(sp)
ffffffffc0201fd4:	796030ef          	jal	ffffffffc020576a <memset>
    return page - pages + nbase;
ffffffffc0201fd8:	00099697          	auipc	a3,0x99
ffffffffc0201fdc:	7d06b683          	ld	a3,2000(a3) # ffffffffc029b7a8 <pages>
ffffffffc0201fe0:	67c2                	ld	a5,16(sp)
ffffffffc0201fe2:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fe6:	6722                	ld	a4,8(sp)
ffffffffc0201fe8:	40d786b3          	sub	a3,a5,a3
ffffffffc0201fec:	8699                	srai	a3,a3,0x6
ffffffffc0201fee:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ff0:	06aa                	slli	a3,a3,0xa
ffffffffc0201ff2:	6862                	ld	a6,24(sp)
ffffffffc0201ff4:	0116e693          	ori	a3,a3,17
ffffffffc0201ff8:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ffa:	c006f693          	andi	a3,a3,-1024
ffffffffc0201ffe:	6098                	ld	a4,0(s1)
ffffffffc0202000:	068a                	slli	a3,a3,0x2
ffffffffc0202002:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202006:	14e7f663          	bgeu	a5,a4,ffffffffc0202152 <get_pte+0x214>
ffffffffc020200a:	00099897          	auipc	a7,0x99
ffffffffc020200e:	78e88893          	addi	a7,a7,1934 # ffffffffc029b798 <va_pa_offset>
ffffffffc0202012:	0008b603          	ld	a2,0(a7)
ffffffffc0202016:	01545793          	srli	a5,s0,0x15
ffffffffc020201a:	1ff7f793          	andi	a5,a5,511
ffffffffc020201e:	96b2                	add	a3,a3,a2
ffffffffc0202020:	078e                	slli	a5,a5,0x3
ffffffffc0202022:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202024:	6394                	ld	a3,0(a5)
ffffffffc0202026:	0016f613          	andi	a2,a3,1
ffffffffc020202a:	e659                	bnez	a2,ffffffffc02020b8 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020202c:	0a080b63          	beqz	a6,ffffffffc02020e2 <get_pte+0x1a4>
ffffffffc0202030:	10002773          	csrr	a4,sstatus
ffffffffc0202034:	8b09                	andi	a4,a4,2
ffffffffc0202036:	ef71                	bnez	a4,ffffffffc0202112 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202038:	00099717          	auipc	a4,0x99
ffffffffc020203c:	74873703          	ld	a4,1864(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc0202040:	4505                	li	a0,1
ffffffffc0202042:	e43e                	sd	a5,8(sp)
ffffffffc0202044:	6f18                	ld	a4,24(a4)
ffffffffc0202046:	9702                	jalr	a4
ffffffffc0202048:	67a2                	ld	a5,8(sp)
ffffffffc020204a:	872a                	mv	a4,a0
ffffffffc020204c:	00099897          	auipc	a7,0x99
ffffffffc0202050:	74c88893          	addi	a7,a7,1868 # ffffffffc029b798 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202054:	c759                	beqz	a4,ffffffffc02020e2 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0202056:	00099697          	auipc	a3,0x99
ffffffffc020205a:	7526b683          	ld	a3,1874(a3) # ffffffffc029b7a8 <pages>
ffffffffc020205e:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202062:	608c                	ld	a1,0(s1)
ffffffffc0202064:	40d706b3          	sub	a3,a4,a3
ffffffffc0202068:	8699                	srai	a3,a3,0x6
ffffffffc020206a:	96c2                	add	a3,a3,a6
ffffffffc020206c:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0202070:	4505                	li	a0,1
ffffffffc0202072:	8231                	srli	a2,a2,0xc
ffffffffc0202074:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0202076:	06b2                	slli	a3,a3,0xc
ffffffffc0202078:	10b67663          	bgeu	a2,a1,ffffffffc0202184 <get_pte+0x246>
ffffffffc020207c:	0008b503          	ld	a0,0(a7)
ffffffffc0202080:	6605                	lui	a2,0x1
ffffffffc0202082:	4581                	li	a1,0
ffffffffc0202084:	9536                	add	a0,a0,a3
ffffffffc0202086:	e83a                	sd	a4,16(sp)
ffffffffc0202088:	e43e                	sd	a5,8(sp)
ffffffffc020208a:	6e0030ef          	jal	ffffffffc020576a <memset>
    return page - pages + nbase;
ffffffffc020208e:	00099697          	auipc	a3,0x99
ffffffffc0202092:	71a6b683          	ld	a3,1818(a3) # ffffffffc029b7a8 <pages>
ffffffffc0202096:	6742                	ld	a4,16(sp)
ffffffffc0202098:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020209c:	67a2                	ld	a5,8(sp)
ffffffffc020209e:	40d706b3          	sub	a3,a4,a3
ffffffffc02020a2:	8699                	srai	a3,a3,0x6
ffffffffc02020a4:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020a6:	06aa                	slli	a3,a3,0xa
ffffffffc02020a8:	0116e693          	ori	a3,a3,17
ffffffffc02020ac:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020ae:	6098                	ld	a4,0(s1)
ffffffffc02020b0:	00099897          	auipc	a7,0x99
ffffffffc02020b4:	6e888893          	addi	a7,a7,1768 # ffffffffc029b798 <va_pa_offset>
ffffffffc02020b8:	c006f693          	andi	a3,a3,-1024
ffffffffc02020bc:	068a                	slli	a3,a3,0x2
ffffffffc02020be:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020c2:	06e7fc63          	bgeu	a5,a4,ffffffffc020213a <get_pte+0x1fc>
ffffffffc02020c6:	0008b783          	ld	a5,0(a7)
ffffffffc02020ca:	8031                	srli	s0,s0,0xc
ffffffffc02020cc:	1ff47413          	andi	s0,s0,511
ffffffffc02020d0:	040e                	slli	s0,s0,0x3
ffffffffc02020d2:	96be                	add	a3,a3,a5
}
ffffffffc02020d4:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020d6:	00868533          	add	a0,a3,s0
}
ffffffffc02020da:	7442                	ld	s0,48(sp)
ffffffffc02020dc:	74a2                	ld	s1,40(sp)
ffffffffc02020de:	6121                	addi	sp,sp,64
ffffffffc02020e0:	8082                	ret
ffffffffc02020e2:	70e2                	ld	ra,56(sp)
ffffffffc02020e4:	7442                	ld	s0,48(sp)
ffffffffc02020e6:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc02020e8:	4501                	li	a0,0
}
ffffffffc02020ea:	6121                	addi	sp,sp,64
ffffffffc02020ec:	8082                	ret
        intr_disable();
ffffffffc02020ee:	e83a                	sd	a4,16(sp)
ffffffffc02020f0:	ec32                	sd	a2,24(sp)
ffffffffc02020f2:	813fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020f6:	00099797          	auipc	a5,0x99
ffffffffc02020fa:	68a7b783          	ld	a5,1674(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc02020fe:	4505                	li	a0,1
ffffffffc0202100:	6f9c                	ld	a5,24(a5)
ffffffffc0202102:	9782                	jalr	a5
ffffffffc0202104:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202106:	ff8fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020210a:	6862                	ld	a6,24(sp)
ffffffffc020210c:	6742                	ld	a4,16(sp)
ffffffffc020210e:	67a2                	ld	a5,8(sp)
ffffffffc0202110:	bdbd                	j	ffffffffc0201f8e <get_pte+0x50>
        intr_disable();
ffffffffc0202112:	e83e                	sd	a5,16(sp)
ffffffffc0202114:	ff0fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202118:	00099717          	auipc	a4,0x99
ffffffffc020211c:	66873703          	ld	a4,1640(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc0202120:	4505                	li	a0,1
ffffffffc0202122:	6f18                	ld	a4,24(a4)
ffffffffc0202124:	9702                	jalr	a4
ffffffffc0202126:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202128:	fd6fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020212c:	6722                	ld	a4,8(sp)
ffffffffc020212e:	67c2                	ld	a5,16(sp)
ffffffffc0202130:	00099897          	auipc	a7,0x99
ffffffffc0202134:	66888893          	addi	a7,a7,1640 # ffffffffc029b798 <va_pa_offset>
ffffffffc0202138:	bf31                	j	ffffffffc0202054 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020213a:	00004617          	auipc	a2,0x4
ffffffffc020213e:	3de60613          	addi	a2,a2,990 # ffffffffc0206518 <etext+0xd84>
ffffffffc0202142:	0fa00593          	li	a1,250
ffffffffc0202146:	00004517          	auipc	a0,0x4
ffffffffc020214a:	4c250513          	addi	a0,a0,1218 # ffffffffc0206608 <etext+0xe74>
ffffffffc020214e:	af8fe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202152:	00004617          	auipc	a2,0x4
ffffffffc0202156:	3c660613          	addi	a2,a2,966 # ffffffffc0206518 <etext+0xd84>
ffffffffc020215a:	0ed00593          	li	a1,237
ffffffffc020215e:	00004517          	auipc	a0,0x4
ffffffffc0202162:	4aa50513          	addi	a0,a0,1194 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202166:	ae0fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020216a:	86aa                	mv	a3,a0
ffffffffc020216c:	00004617          	auipc	a2,0x4
ffffffffc0202170:	3ac60613          	addi	a2,a2,940 # ffffffffc0206518 <etext+0xd84>
ffffffffc0202174:	0e900593          	li	a1,233
ffffffffc0202178:	00004517          	auipc	a0,0x4
ffffffffc020217c:	49050513          	addi	a0,a0,1168 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202180:	ac6fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202184:	00004617          	auipc	a2,0x4
ffffffffc0202188:	39460613          	addi	a2,a2,916 # ffffffffc0206518 <etext+0xd84>
ffffffffc020218c:	0f700593          	li	a1,247
ffffffffc0202190:	00004517          	auipc	a0,0x4
ffffffffc0202194:	47850513          	addi	a0,a0,1144 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202198:	aaefe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020219c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020219c:	1141                	addi	sp,sp,-16
ffffffffc020219e:	e022                	sd	s0,0(sp)
ffffffffc02021a0:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021a2:	4601                	li	a2,0
{
ffffffffc02021a4:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021a6:	d99ff0ef          	jal	ffffffffc0201f3e <get_pte>
    if (ptep_store != NULL)
ffffffffc02021aa:	c011                	beqz	s0,ffffffffc02021ae <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021ac:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021ae:	c511                	beqz	a0,ffffffffc02021ba <get_page+0x1e>
ffffffffc02021b0:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021b2:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021b4:	0017f713          	andi	a4,a5,1
ffffffffc02021b8:	e709                	bnez	a4,ffffffffc02021c2 <get_page+0x26>
}
ffffffffc02021ba:	60a2                	ld	ra,8(sp)
ffffffffc02021bc:	6402                	ld	s0,0(sp)
ffffffffc02021be:	0141                	addi	sp,sp,16
ffffffffc02021c0:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02021c2:	00099717          	auipc	a4,0x99
ffffffffc02021c6:	5de73703          	ld	a4,1502(a4) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02021ca:	078a                	slli	a5,a5,0x2
ffffffffc02021cc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021ce:	00e7ff63          	bgeu	a5,a4,ffffffffc02021ec <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02021d2:	00099517          	auipc	a0,0x99
ffffffffc02021d6:	5d653503          	ld	a0,1494(a0) # ffffffffc029b7a8 <pages>
ffffffffc02021da:	60a2                	ld	ra,8(sp)
ffffffffc02021dc:	6402                	ld	s0,0(sp)
ffffffffc02021de:	079a                	slli	a5,a5,0x6
ffffffffc02021e0:	fe000737          	lui	a4,0xfe000
ffffffffc02021e4:	97ba                	add	a5,a5,a4
ffffffffc02021e6:	953e                	add	a0,a0,a5
ffffffffc02021e8:	0141                	addi	sp,sp,16
ffffffffc02021ea:	8082                	ret
ffffffffc02021ec:	c8fff0ef          	jal	ffffffffc0201e7a <pa2page.part.0>

ffffffffc02021f0 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021f0:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021f2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021f6:	e486                	sd	ra,72(sp)
ffffffffc02021f8:	e0a2                	sd	s0,64(sp)
ffffffffc02021fa:	fc26                	sd	s1,56(sp)
ffffffffc02021fc:	f84a                	sd	s2,48(sp)
ffffffffc02021fe:	f44e                	sd	s3,40(sp)
ffffffffc0202200:	f052                	sd	s4,32(sp)
ffffffffc0202202:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202204:	03479713          	slli	a4,a5,0x34
ffffffffc0202208:	ef61                	bnez	a4,ffffffffc02022e0 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc020220a:	00200a37          	lui	s4,0x200
ffffffffc020220e:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202212:	0145b733          	sltu	a4,a1,s4
ffffffffc0202216:	0017b793          	seqz	a5,a5
ffffffffc020221a:	8fd9                	or	a5,a5,a4
ffffffffc020221c:	842e                	mv	s0,a1
ffffffffc020221e:	84b2                	mv	s1,a2
ffffffffc0202220:	e3e5                	bnez	a5,ffffffffc0202300 <unmap_range+0x110>
ffffffffc0202222:	4785                	li	a5,1
ffffffffc0202224:	07fe                	slli	a5,a5,0x1f
ffffffffc0202226:	0785                	addi	a5,a5,1
ffffffffc0202228:	892a                	mv	s2,a0
ffffffffc020222a:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020222c:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202230:	0cf67863          	bgeu	a2,a5,ffffffffc0202300 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202234:	4601                	li	a2,0
ffffffffc0202236:	85a2                	mv	a1,s0
ffffffffc0202238:	854a                	mv	a0,s2
ffffffffc020223a:	d05ff0ef          	jal	ffffffffc0201f3e <get_pte>
ffffffffc020223e:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202240:	cd31                	beqz	a0,ffffffffc020229c <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc0202242:	6118                	ld	a4,0(a0)
ffffffffc0202244:	ef11                	bnez	a4,ffffffffc0202260 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202246:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202248:	c019                	beqz	s0,ffffffffc020224e <unmap_range+0x5e>
ffffffffc020224a:	fe9465e3          	bltu	s0,s1,ffffffffc0202234 <unmap_range+0x44>
}
ffffffffc020224e:	60a6                	ld	ra,72(sp)
ffffffffc0202250:	6406                	ld	s0,64(sp)
ffffffffc0202252:	74e2                	ld	s1,56(sp)
ffffffffc0202254:	7942                	ld	s2,48(sp)
ffffffffc0202256:	79a2                	ld	s3,40(sp)
ffffffffc0202258:	7a02                	ld	s4,32(sp)
ffffffffc020225a:	6ae2                	ld	s5,24(sp)
ffffffffc020225c:	6161                	addi	sp,sp,80
ffffffffc020225e:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202260:	00177693          	andi	a3,a4,1
ffffffffc0202264:	d2ed                	beqz	a3,ffffffffc0202246 <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc0202266:	00099697          	auipc	a3,0x99
ffffffffc020226a:	53a6b683          	ld	a3,1338(a3) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020226e:	070a                	slli	a4,a4,0x2
ffffffffc0202270:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202272:	0ad77763          	bgeu	a4,a3,ffffffffc0202320 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc0202276:	00099517          	auipc	a0,0x99
ffffffffc020227a:	53253503          	ld	a0,1330(a0) # ffffffffc029b7a8 <pages>
ffffffffc020227e:	071a                	slli	a4,a4,0x6
ffffffffc0202280:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202284:	9736                	add	a4,a4,a3
ffffffffc0202286:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202288:	4118                	lw	a4,0(a0)
ffffffffc020228a:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd6482f>
ffffffffc020228c:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020228e:	cb19                	beqz	a4,ffffffffc02022a4 <unmap_range+0xb4>
        *ptep = 0;
ffffffffc0202290:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202294:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202298:	944e                	add	s0,s0,s3
ffffffffc020229a:	b77d                	j	ffffffffc0202248 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020229c:	9452                	add	s0,s0,s4
ffffffffc020229e:	01547433          	and	s0,s0,s5
            continue;
ffffffffc02022a2:	b75d                	j	ffffffffc0202248 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022a4:	10002773          	csrr	a4,sstatus
ffffffffc02022a8:	8b09                	andi	a4,a4,2
ffffffffc02022aa:	eb19                	bnez	a4,ffffffffc02022c0 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02022ac:	00099717          	auipc	a4,0x99
ffffffffc02022b0:	4d473703          	ld	a4,1236(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc02022b4:	4585                	li	a1,1
ffffffffc02022b6:	e03e                	sd	a5,0(sp)
ffffffffc02022b8:	7318                	ld	a4,32(a4)
ffffffffc02022ba:	9702                	jalr	a4
    if (flag)
ffffffffc02022bc:	6782                	ld	a5,0(sp)
ffffffffc02022be:	bfc9                	j	ffffffffc0202290 <unmap_range+0xa0>
        intr_disable();
ffffffffc02022c0:	e43e                	sd	a5,8(sp)
ffffffffc02022c2:	e02a                	sd	a0,0(sp)
ffffffffc02022c4:	e40fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02022c8:	00099717          	auipc	a4,0x99
ffffffffc02022cc:	4b873703          	ld	a4,1208(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc02022d0:	6502                	ld	a0,0(sp)
ffffffffc02022d2:	4585                	li	a1,1
ffffffffc02022d4:	7318                	ld	a4,32(a4)
ffffffffc02022d6:	9702                	jalr	a4
        intr_enable();
ffffffffc02022d8:	e26fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02022dc:	67a2                	ld	a5,8(sp)
ffffffffc02022de:	bf4d                	j	ffffffffc0202290 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022e0:	00004697          	auipc	a3,0x4
ffffffffc02022e4:	33868693          	addi	a3,a3,824 # ffffffffc0206618 <etext+0xe84>
ffffffffc02022e8:	00004617          	auipc	a2,0x4
ffffffffc02022ec:	e8060613          	addi	a2,a2,-384 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02022f0:	12000593          	li	a1,288
ffffffffc02022f4:	00004517          	auipc	a0,0x4
ffffffffc02022f8:	31450513          	addi	a0,a0,788 # ffffffffc0206608 <etext+0xe74>
ffffffffc02022fc:	94afe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202300:	00004697          	auipc	a3,0x4
ffffffffc0202304:	34868693          	addi	a3,a3,840 # ffffffffc0206648 <etext+0xeb4>
ffffffffc0202308:	00004617          	auipc	a2,0x4
ffffffffc020230c:	e6060613          	addi	a2,a2,-416 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202310:	12100593          	li	a1,289
ffffffffc0202314:	00004517          	auipc	a0,0x4
ffffffffc0202318:	2f450513          	addi	a0,a0,756 # ffffffffc0206608 <etext+0xe74>
ffffffffc020231c:	92afe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202320:	b5bff0ef          	jal	ffffffffc0201e7a <pa2page.part.0>

ffffffffc0202324 <exit_range>:
{
ffffffffc0202324:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202326:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020232a:	ed06                	sd	ra,152(sp)
ffffffffc020232c:	e922                	sd	s0,144(sp)
ffffffffc020232e:	e526                	sd	s1,136(sp)
ffffffffc0202330:	e14a                	sd	s2,128(sp)
ffffffffc0202332:	fcce                	sd	s3,120(sp)
ffffffffc0202334:	f8d2                	sd	s4,112(sp)
ffffffffc0202336:	f4d6                	sd	s5,104(sp)
ffffffffc0202338:	f0da                	sd	s6,96(sp)
ffffffffc020233a:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020233c:	17d2                	slli	a5,a5,0x34
ffffffffc020233e:	22079263          	bnez	a5,ffffffffc0202562 <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc0202342:	00200937          	lui	s2,0x200
ffffffffc0202346:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020234a:	0125b733          	sltu	a4,a1,s2
ffffffffc020234e:	0017b793          	seqz	a5,a5
ffffffffc0202352:	8fd9                	or	a5,a5,a4
ffffffffc0202354:	26079263          	bnez	a5,ffffffffc02025b8 <exit_range+0x294>
ffffffffc0202358:	4785                	li	a5,1
ffffffffc020235a:	07fe                	slli	a5,a5,0x1f
ffffffffc020235c:	0785                	addi	a5,a5,1
ffffffffc020235e:	24f67d63          	bgeu	a2,a5,ffffffffc02025b8 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202362:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202366:	ffe007b7          	lui	a5,0xffe00
ffffffffc020236a:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020236c:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020236e:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc0202372:	00099a97          	auipc	s5,0x99
ffffffffc0202376:	42ea8a93          	addi	s5,s5,1070 # ffffffffc029b7a0 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020237a:	400009b7          	lui	s3,0x40000
ffffffffc020237e:	a809                	j	ffffffffc0202390 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc0202380:	013487b3          	add	a5,s1,s3
ffffffffc0202384:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202388:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc020238a:	c3f1                	beqz	a5,ffffffffc020244e <exit_range+0x12a>
ffffffffc020238c:	0cc7f163          	bgeu	a5,a2,ffffffffc020244e <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202390:	01e4d413          	srli	s0,s1,0x1e
ffffffffc0202394:	1ff47413          	andi	s0,s0,511
ffffffffc0202398:	040e                	slli	s0,s0,0x3
ffffffffc020239a:	9452                	add	s0,s0,s4
ffffffffc020239c:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc02023a0:	0018f793          	andi	a5,a7,1
ffffffffc02023a4:	dff1                	beqz	a5,ffffffffc0202380 <exit_range+0x5c>
ffffffffc02023a6:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023aa:	088a                	slli	a7,a7,0x2
ffffffffc02023ac:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02023b0:	20f8f263          	bgeu	a7,a5,ffffffffc02025b4 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b4:	fff802b7          	lui	t0,0xfff80
ffffffffc02023b8:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02023bc:	000803b7          	lui	t2,0x80
ffffffffc02023c0:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02023c4:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023c8:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02023ca:	1cf77863          	bgeu	a4,a5,ffffffffc020259a <exit_range+0x276>
ffffffffc02023ce:	00099f97          	auipc	t6,0x99
ffffffffc02023d2:	3caf8f93          	addi	t6,t6,970 # ffffffffc029b798 <va_pa_offset>
ffffffffc02023d6:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02023da:	4e85                	li	t4,1
ffffffffc02023dc:	6b05                	lui	s6,0x1
ffffffffc02023de:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023e0:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023e4:	01585713          	srli	a4,a6,0x15
ffffffffc02023e8:	1ff77713          	andi	a4,a4,511
ffffffffc02023ec:	070e                	slli	a4,a4,0x3
ffffffffc02023ee:	9772                	add	a4,a4,t3
ffffffffc02023f0:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc02023f2:	0017f693          	andi	a3,a5,1
ffffffffc02023f6:	e6bd                	bnez	a3,ffffffffc0202464 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc02023f8:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc02023fa:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023fc:	00080863          	beqz	a6,ffffffffc020240c <exit_range+0xe8>
ffffffffc0202400:	879a                	mv	a5,t1
ffffffffc0202402:	00667363          	bgeu	a2,t1,ffffffffc0202408 <exit_range+0xe4>
ffffffffc0202406:	87b2                	mv	a5,a2
ffffffffc0202408:	fcf86ee3          	bltu	a6,a5,ffffffffc02023e4 <exit_range+0xc0>
            if (free_pd0)
ffffffffc020240c:	f60e8ae3          	beqz	t4,ffffffffc0202380 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202410:	000ab783          	ld	a5,0(s5)
ffffffffc0202414:	1af8f063          	bgeu	a7,a5,ffffffffc02025b4 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202418:	00099517          	auipc	a0,0x99
ffffffffc020241c:	39053503          	ld	a0,912(a0) # ffffffffc029b7a8 <pages>
ffffffffc0202420:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202422:	100027f3          	csrr	a5,sstatus
ffffffffc0202426:	8b89                	andi	a5,a5,2
ffffffffc0202428:	10079b63          	bnez	a5,ffffffffc020253e <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc020242c:	00099797          	auipc	a5,0x99
ffffffffc0202430:	3547b783          	ld	a5,852(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0202434:	4585                	li	a1,1
ffffffffc0202436:	e432                	sd	a2,8(sp)
ffffffffc0202438:	739c                	ld	a5,32(a5)
ffffffffc020243a:	9782                	jalr	a5
ffffffffc020243c:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc020243e:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc0202442:	013487b3          	add	a5,s1,s3
ffffffffc0202446:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc020244a:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc020244c:	f3a1                	bnez	a5,ffffffffc020238c <exit_range+0x68>
}
ffffffffc020244e:	60ea                	ld	ra,152(sp)
ffffffffc0202450:	644a                	ld	s0,144(sp)
ffffffffc0202452:	64aa                	ld	s1,136(sp)
ffffffffc0202454:	690a                	ld	s2,128(sp)
ffffffffc0202456:	79e6                	ld	s3,120(sp)
ffffffffc0202458:	7a46                	ld	s4,112(sp)
ffffffffc020245a:	7aa6                	ld	s5,104(sp)
ffffffffc020245c:	7b06                	ld	s6,96(sp)
ffffffffc020245e:	6be6                	ld	s7,88(sp)
ffffffffc0202460:	610d                	addi	sp,sp,160
ffffffffc0202462:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202464:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202468:	078a                	slli	a5,a5,0x2
ffffffffc020246a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020246c:	14a7f463          	bgeu	a5,a0,ffffffffc02025b4 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202470:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc0202472:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc0202476:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020247a:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc020247e:	10abf263          	bgeu	s7,a0,ffffffffc0202582 <exit_range+0x25e>
ffffffffc0202482:	000fb783          	ld	a5,0(t6)
ffffffffc0202486:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202488:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc020248c:	629c                	ld	a5,0(a3)
ffffffffc020248e:	8b85                	andi	a5,a5,1
ffffffffc0202490:	f7ad                	bnez	a5,ffffffffc02023fa <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202492:	06a1                	addi	a3,a3,8
ffffffffc0202494:	fea69ce3          	bne	a3,a0,ffffffffc020248c <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc0202498:	00099517          	auipc	a0,0x99
ffffffffc020249c:	31053503          	ld	a0,784(a0) # ffffffffc029b7a8 <pages>
ffffffffc02024a0:	952e                	add	a0,a0,a1
ffffffffc02024a2:	100027f3          	csrr	a5,sstatus
ffffffffc02024a6:	8b89                	andi	a5,a5,2
ffffffffc02024a8:	e3b9                	bnez	a5,ffffffffc02024ee <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02024aa:	00099797          	auipc	a5,0x99
ffffffffc02024ae:	2d67b783          	ld	a5,726(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc02024b2:	4585                	li	a1,1
ffffffffc02024b4:	e0b2                	sd	a2,64(sp)
ffffffffc02024b6:	739c                	ld	a5,32(a5)
ffffffffc02024b8:	fc1a                	sd	t1,56(sp)
ffffffffc02024ba:	f846                	sd	a7,48(sp)
ffffffffc02024bc:	f47a                	sd	t5,40(sp)
ffffffffc02024be:	f072                	sd	t3,32(sp)
ffffffffc02024c0:	ec76                	sd	t4,24(sp)
ffffffffc02024c2:	e842                	sd	a6,16(sp)
ffffffffc02024c4:	e43a                	sd	a4,8(sp)
ffffffffc02024c6:	9782                	jalr	a5
    if (flag)
ffffffffc02024c8:	6722                	ld	a4,8(sp)
ffffffffc02024ca:	6842                	ld	a6,16(sp)
ffffffffc02024cc:	6ee2                	ld	t4,24(sp)
ffffffffc02024ce:	7e02                	ld	t3,32(sp)
ffffffffc02024d0:	7f22                	ld	t5,40(sp)
ffffffffc02024d2:	78c2                	ld	a7,48(sp)
ffffffffc02024d4:	7362                	ld	t1,56(sp)
ffffffffc02024d6:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024d8:	fff802b7          	lui	t0,0xfff80
ffffffffc02024dc:	000803b7          	lui	t2,0x80
ffffffffc02024e0:	00099f97          	auipc	t6,0x99
ffffffffc02024e4:	2b8f8f93          	addi	t6,t6,696 # ffffffffc029b798 <va_pa_offset>
ffffffffc02024e8:	00073023          	sd	zero,0(a4)
ffffffffc02024ec:	b739                	j	ffffffffc02023fa <exit_range+0xd6>
        intr_disable();
ffffffffc02024ee:	e4b2                	sd	a2,72(sp)
ffffffffc02024f0:	e09a                	sd	t1,64(sp)
ffffffffc02024f2:	fc46                	sd	a7,56(sp)
ffffffffc02024f4:	f47a                	sd	t5,40(sp)
ffffffffc02024f6:	f072                	sd	t3,32(sp)
ffffffffc02024f8:	ec76                	sd	t4,24(sp)
ffffffffc02024fa:	e842                	sd	a6,16(sp)
ffffffffc02024fc:	e43a                	sd	a4,8(sp)
ffffffffc02024fe:	f82a                	sd	a0,48(sp)
ffffffffc0202500:	c04fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202504:	00099797          	auipc	a5,0x99
ffffffffc0202508:	27c7b783          	ld	a5,636(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc020250c:	7542                	ld	a0,48(sp)
ffffffffc020250e:	4585                	li	a1,1
ffffffffc0202510:	739c                	ld	a5,32(a5)
ffffffffc0202512:	9782                	jalr	a5
        intr_enable();
ffffffffc0202514:	beafe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202518:	6722                	ld	a4,8(sp)
ffffffffc020251a:	6626                	ld	a2,72(sp)
ffffffffc020251c:	6306                	ld	t1,64(sp)
ffffffffc020251e:	78e2                	ld	a7,56(sp)
ffffffffc0202520:	7f22                	ld	t5,40(sp)
ffffffffc0202522:	7e02                	ld	t3,32(sp)
ffffffffc0202524:	6ee2                	ld	t4,24(sp)
ffffffffc0202526:	6842                	ld	a6,16(sp)
ffffffffc0202528:	00099f97          	auipc	t6,0x99
ffffffffc020252c:	270f8f93          	addi	t6,t6,624 # ffffffffc029b798 <va_pa_offset>
ffffffffc0202530:	000803b7          	lui	t2,0x80
ffffffffc0202534:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202538:	00073023          	sd	zero,0(a4)
ffffffffc020253c:	bd7d                	j	ffffffffc02023fa <exit_range+0xd6>
        intr_disable();
ffffffffc020253e:	e832                	sd	a2,16(sp)
ffffffffc0202540:	e42a                	sd	a0,8(sp)
ffffffffc0202542:	bc2fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202546:	00099797          	auipc	a5,0x99
ffffffffc020254a:	23a7b783          	ld	a5,570(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc020254e:	6522                	ld	a0,8(sp)
ffffffffc0202550:	4585                	li	a1,1
ffffffffc0202552:	739c                	ld	a5,32(a5)
ffffffffc0202554:	9782                	jalr	a5
        intr_enable();
ffffffffc0202556:	ba8fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020255a:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc020255c:	00043023          	sd	zero,0(s0)
ffffffffc0202560:	b5cd                	j	ffffffffc0202442 <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202562:	00004697          	auipc	a3,0x4
ffffffffc0202566:	0b668693          	addi	a3,a3,182 # ffffffffc0206618 <etext+0xe84>
ffffffffc020256a:	00004617          	auipc	a2,0x4
ffffffffc020256e:	bfe60613          	addi	a2,a2,-1026 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202572:	13500593          	li	a1,309
ffffffffc0202576:	00004517          	auipc	a0,0x4
ffffffffc020257a:	09250513          	addi	a0,a0,146 # ffffffffc0206608 <etext+0xe74>
ffffffffc020257e:	ec9fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202582:	00004617          	auipc	a2,0x4
ffffffffc0202586:	f9660613          	addi	a2,a2,-106 # ffffffffc0206518 <etext+0xd84>
ffffffffc020258a:	07100593          	li	a1,113
ffffffffc020258e:	00004517          	auipc	a0,0x4
ffffffffc0202592:	fb250513          	addi	a0,a0,-78 # ffffffffc0206540 <etext+0xdac>
ffffffffc0202596:	eb1fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020259a:	86f2                	mv	a3,t3
ffffffffc020259c:	00004617          	auipc	a2,0x4
ffffffffc02025a0:	f7c60613          	addi	a2,a2,-132 # ffffffffc0206518 <etext+0xd84>
ffffffffc02025a4:	07100593          	li	a1,113
ffffffffc02025a8:	00004517          	auipc	a0,0x4
ffffffffc02025ac:	f9850513          	addi	a0,a0,-104 # ffffffffc0206540 <etext+0xdac>
ffffffffc02025b0:	e97fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02025b4:	8c7ff0ef          	jal	ffffffffc0201e7a <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025b8:	00004697          	auipc	a3,0x4
ffffffffc02025bc:	09068693          	addi	a3,a3,144 # ffffffffc0206648 <etext+0xeb4>
ffffffffc02025c0:	00004617          	auipc	a2,0x4
ffffffffc02025c4:	ba860613          	addi	a2,a2,-1112 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02025c8:	13600593          	li	a1,310
ffffffffc02025cc:	00004517          	auipc	a0,0x4
ffffffffc02025d0:	03c50513          	addi	a0,a0,60 # ffffffffc0206608 <etext+0xe74>
ffffffffc02025d4:	e73fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02025d8 <page_remove>:
{
ffffffffc02025d8:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025da:	4601                	li	a2,0
{
ffffffffc02025dc:	e822                	sd	s0,16(sp)
ffffffffc02025de:	ec06                	sd	ra,24(sp)
ffffffffc02025e0:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025e2:	95dff0ef          	jal	ffffffffc0201f3e <get_pte>
    if (ptep != NULL)
ffffffffc02025e6:	c511                	beqz	a0,ffffffffc02025f2 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc02025e8:	6118                	ld	a4,0(a0)
ffffffffc02025ea:	87aa                	mv	a5,a0
ffffffffc02025ec:	00177693          	andi	a3,a4,1
ffffffffc02025f0:	e689                	bnez	a3,ffffffffc02025fa <page_remove+0x22>
}
ffffffffc02025f2:	60e2                	ld	ra,24(sp)
ffffffffc02025f4:	6442                	ld	s0,16(sp)
ffffffffc02025f6:	6105                	addi	sp,sp,32
ffffffffc02025f8:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02025fa:	00099697          	auipc	a3,0x99
ffffffffc02025fe:	1a66b683          	ld	a3,422(a3) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202602:	070a                	slli	a4,a4,0x2
ffffffffc0202604:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202606:	06d77563          	bgeu	a4,a3,ffffffffc0202670 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020260a:	00099517          	auipc	a0,0x99
ffffffffc020260e:	19e53503          	ld	a0,414(a0) # ffffffffc029b7a8 <pages>
ffffffffc0202612:	071a                	slli	a4,a4,0x6
ffffffffc0202614:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202618:	9736                	add	a4,a4,a3
ffffffffc020261a:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc020261c:	4118                	lw	a4,0(a0)
ffffffffc020261e:	377d                	addiw	a4,a4,-1
ffffffffc0202620:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202622:	cb09                	beqz	a4,ffffffffc0202634 <page_remove+0x5c>
        *ptep = 0;
ffffffffc0202624:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202628:	12040073          	sfence.vma	s0
}
ffffffffc020262c:	60e2                	ld	ra,24(sp)
ffffffffc020262e:	6442                	ld	s0,16(sp)
ffffffffc0202630:	6105                	addi	sp,sp,32
ffffffffc0202632:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202634:	10002773          	csrr	a4,sstatus
ffffffffc0202638:	8b09                	andi	a4,a4,2
ffffffffc020263a:	eb19                	bnez	a4,ffffffffc0202650 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc020263c:	00099717          	auipc	a4,0x99
ffffffffc0202640:	14473703          	ld	a4,324(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc0202644:	4585                	li	a1,1
ffffffffc0202646:	e03e                	sd	a5,0(sp)
ffffffffc0202648:	7318                	ld	a4,32(a4)
ffffffffc020264a:	9702                	jalr	a4
    if (flag)
ffffffffc020264c:	6782                	ld	a5,0(sp)
ffffffffc020264e:	bfd9                	j	ffffffffc0202624 <page_remove+0x4c>
        intr_disable();
ffffffffc0202650:	e43e                	sd	a5,8(sp)
ffffffffc0202652:	e02a                	sd	a0,0(sp)
ffffffffc0202654:	ab0fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202658:	00099717          	auipc	a4,0x99
ffffffffc020265c:	12873703          	ld	a4,296(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc0202660:	6502                	ld	a0,0(sp)
ffffffffc0202662:	4585                	li	a1,1
ffffffffc0202664:	7318                	ld	a4,32(a4)
ffffffffc0202666:	9702                	jalr	a4
        intr_enable();
ffffffffc0202668:	a96fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020266c:	67a2                	ld	a5,8(sp)
ffffffffc020266e:	bf5d                	j	ffffffffc0202624 <page_remove+0x4c>
ffffffffc0202670:	80bff0ef          	jal	ffffffffc0201e7a <pa2page.part.0>

ffffffffc0202674 <page_insert>:
{
ffffffffc0202674:	7139                	addi	sp,sp,-64
ffffffffc0202676:	f426                	sd	s1,40(sp)
ffffffffc0202678:	84b2                	mv	s1,a2
ffffffffc020267a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020267c:	4605                	li	a2,1
{
ffffffffc020267e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202680:	85a6                	mv	a1,s1
{
ffffffffc0202682:	fc06                	sd	ra,56(sp)
ffffffffc0202684:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202686:	8b9ff0ef          	jal	ffffffffc0201f3e <get_pte>
    if (ptep == NULL)
ffffffffc020268a:	cd61                	beqz	a0,ffffffffc0202762 <page_insert+0xee>
    page->ref += 1;
ffffffffc020268c:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020268e:	611c                	ld	a5,0(a0)
ffffffffc0202690:	66a2                	ld	a3,8(sp)
ffffffffc0202692:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7bcf>
ffffffffc0202696:	c010                	sw	a2,0(s0)
ffffffffc0202698:	0017f613          	andi	a2,a5,1
ffffffffc020269c:	872a                	mv	a4,a0
ffffffffc020269e:	e61d                	bnez	a2,ffffffffc02026cc <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc02026a0:	00099617          	auipc	a2,0x99
ffffffffc02026a4:	10863603          	ld	a2,264(a2) # ffffffffc029b7a8 <pages>
    return page - pages + nbase;
ffffffffc02026a8:	8c11                	sub	s0,s0,a2
ffffffffc02026aa:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026ac:	200007b7          	lui	a5,0x20000
ffffffffc02026b0:	042a                	slli	s0,s0,0xa
ffffffffc02026b2:	943e                	add	s0,s0,a5
ffffffffc02026b4:	8ec1                	or	a3,a3,s0
ffffffffc02026b6:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026ba:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026bc:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02026c0:	4501                	li	a0,0
}
ffffffffc02026c2:	70e2                	ld	ra,56(sp)
ffffffffc02026c4:	7442                	ld	s0,48(sp)
ffffffffc02026c6:	74a2                	ld	s1,40(sp)
ffffffffc02026c8:	6121                	addi	sp,sp,64
ffffffffc02026ca:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026cc:	00099617          	auipc	a2,0x99
ffffffffc02026d0:	0d463603          	ld	a2,212(a2) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026d4:	078a                	slli	a5,a5,0x2
ffffffffc02026d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026d8:	08c7f763          	bgeu	a5,a2,ffffffffc0202766 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026dc:	00099617          	auipc	a2,0x99
ffffffffc02026e0:	0cc63603          	ld	a2,204(a2) # ffffffffc029b7a8 <pages>
ffffffffc02026e4:	fe000537          	lui	a0,0xfe000
ffffffffc02026e8:	079a                	slli	a5,a5,0x6
ffffffffc02026ea:	97aa                	add	a5,a5,a0
ffffffffc02026ec:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02026f0:	00a40963          	beq	s0,a0,ffffffffc0202702 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02026f4:	411c                	lw	a5,0(a0)
ffffffffc02026f6:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_exit_out_size+0x1fff5e27>
ffffffffc02026f8:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc02026fa:	c791                	beqz	a5,ffffffffc0202706 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026fc:	12048073          	sfence.vma	s1
}
ffffffffc0202700:	b765                	j	ffffffffc02026a8 <page_insert+0x34>
ffffffffc0202702:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202704:	b755                	j	ffffffffc02026a8 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202706:	100027f3          	csrr	a5,sstatus
ffffffffc020270a:	8b89                	andi	a5,a5,2
ffffffffc020270c:	e39d                	bnez	a5,ffffffffc0202732 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc020270e:	00099797          	auipc	a5,0x99
ffffffffc0202712:	0727b783          	ld	a5,114(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0202716:	4585                	li	a1,1
ffffffffc0202718:	e83a                	sd	a4,16(sp)
ffffffffc020271a:	739c                	ld	a5,32(a5)
ffffffffc020271c:	e436                	sd	a3,8(sp)
ffffffffc020271e:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202720:	00099617          	auipc	a2,0x99
ffffffffc0202724:	08863603          	ld	a2,136(a2) # ffffffffc029b7a8 <pages>
ffffffffc0202728:	66a2                	ld	a3,8(sp)
ffffffffc020272a:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020272c:	12048073          	sfence.vma	s1
ffffffffc0202730:	bfa5                	j	ffffffffc02026a8 <page_insert+0x34>
        intr_disable();
ffffffffc0202732:	ec3a                	sd	a4,24(sp)
ffffffffc0202734:	e836                	sd	a3,16(sp)
ffffffffc0202736:	e42a                	sd	a0,8(sp)
ffffffffc0202738:	9ccfe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020273c:	00099797          	auipc	a5,0x99
ffffffffc0202740:	0447b783          	ld	a5,68(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0202744:	6522                	ld	a0,8(sp)
ffffffffc0202746:	4585                	li	a1,1
ffffffffc0202748:	739c                	ld	a5,32(a5)
ffffffffc020274a:	9782                	jalr	a5
        intr_enable();
ffffffffc020274c:	9b2fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202750:	00099617          	auipc	a2,0x99
ffffffffc0202754:	05863603          	ld	a2,88(a2) # ffffffffc029b7a8 <pages>
ffffffffc0202758:	6762                	ld	a4,24(sp)
ffffffffc020275a:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020275c:	12048073          	sfence.vma	s1
ffffffffc0202760:	b7a1                	j	ffffffffc02026a8 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc0202762:	5571                	li	a0,-4
ffffffffc0202764:	bfb9                	j	ffffffffc02026c2 <page_insert+0x4e>
ffffffffc0202766:	f14ff0ef          	jal	ffffffffc0201e7a <pa2page.part.0>

ffffffffc020276a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020276a:	00005797          	auipc	a5,0x5
ffffffffc020276e:	e1678793          	addi	a5,a5,-490 # ffffffffc0207580 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202772:	638c                	ld	a1,0(a5)
{
ffffffffc0202774:	7159                	addi	sp,sp,-112
ffffffffc0202776:	f486                	sd	ra,104(sp)
ffffffffc0202778:	e8ca                	sd	s2,80(sp)
ffffffffc020277a:	e4ce                	sd	s3,72(sp)
ffffffffc020277c:	f85a                	sd	s6,48(sp)
ffffffffc020277e:	f0a2                	sd	s0,96(sp)
ffffffffc0202780:	eca6                	sd	s1,88(sp)
ffffffffc0202782:	e0d2                	sd	s4,64(sp)
ffffffffc0202784:	fc56                	sd	s5,56(sp)
ffffffffc0202786:	f45e                	sd	s7,40(sp)
ffffffffc0202788:	f062                	sd	s8,32(sp)
ffffffffc020278a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020278c:	00099b17          	auipc	s6,0x99
ffffffffc0202790:	ff4b0b13          	addi	s6,s6,-12 # ffffffffc029b780 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202794:	00004517          	auipc	a0,0x4
ffffffffc0202798:	ecc50513          	addi	a0,a0,-308 # ffffffffc0206660 <etext+0xecc>
    pmm_manager = &default_pmm_manager;
ffffffffc020279c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027a0:	9f5fd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027a4:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027a8:	00099997          	auipc	s3,0x99
ffffffffc02027ac:	ff098993          	addi	s3,s3,-16 # ffffffffc029b798 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027b0:	679c                	ld	a5,8(a5)
ffffffffc02027b2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027b4:	57f5                	li	a5,-3
ffffffffc02027b6:	07fa                	slli	a5,a5,0x1e
ffffffffc02027b8:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027bc:	92efe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc02027c0:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027c2:	932fe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027c6:	70050e63          	beqz	a0,ffffffffc0202ee2 <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027ca:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027cc:	00004517          	auipc	a0,0x4
ffffffffc02027d0:	ecc50513          	addi	a0,a0,-308 # ffffffffc0206698 <etext+0xf04>
ffffffffc02027d4:	9c1fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027d8:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027dc:	864a                	mv	a2,s2
ffffffffc02027de:	85a6                	mv	a1,s1
ffffffffc02027e0:	fff40693          	addi	a3,s0,-1
ffffffffc02027e4:	00004517          	auipc	a0,0x4
ffffffffc02027e8:	ecc50513          	addi	a0,a0,-308 # ffffffffc02066b0 <etext+0xf1c>
ffffffffc02027ec:	9a9fd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02027f0:	c80007b7          	lui	a5,0xc8000
ffffffffc02027f4:	8522                	mv	a0,s0
ffffffffc02027f6:	5287ed63          	bltu	a5,s0,ffffffffc0202d30 <pmm_init+0x5c6>
ffffffffc02027fa:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027fc:	0009a617          	auipc	a2,0x9a
ffffffffc0202800:	fd360613          	addi	a2,a2,-45 # ffffffffc029c7cf <end+0xfff>
ffffffffc0202804:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc0202806:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202808:	00099b97          	auipc	s7,0x99
ffffffffc020280c:	fa0b8b93          	addi	s7,s7,-96 # ffffffffc029b7a8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202810:	00099497          	auipc	s1,0x99
ffffffffc0202814:	f9048493          	addi	s1,s1,-112 # ffffffffc029b7a0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202818:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc020281c:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020281e:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202822:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202824:	02f50763          	beq	a0,a5,ffffffffc0202852 <pmm_init+0xe8>
ffffffffc0202828:	4701                	li	a4,0
ffffffffc020282a:	4585                	li	a1,1
ffffffffc020282c:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202830:	00671793          	slli	a5,a4,0x6
ffffffffc0202834:	97b2                	add	a5,a5,a2
ffffffffc0202836:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_exit_out_size+0x75e30>
ffffffffc0202838:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020283c:	6088                	ld	a0,0(s1)
ffffffffc020283e:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202840:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202844:	00d507b3          	add	a5,a0,a3
ffffffffc0202848:	fef764e3          	bltu	a4,a5,ffffffffc0202830 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020284c:	079a                	slli	a5,a5,0x6
ffffffffc020284e:	00f606b3          	add	a3,a2,a5
ffffffffc0202852:	c02007b7          	lui	a5,0xc0200
ffffffffc0202856:	16f6eee3          	bltu	a3,a5,ffffffffc02031d2 <pmm_init+0xa68>
ffffffffc020285a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020285e:	77fd                	lui	a5,0xfffff
ffffffffc0202860:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202862:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202864:	4e86ed63          	bltu	a3,s0,ffffffffc0202d5e <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202868:	00004517          	auipc	a0,0x4
ffffffffc020286c:	e7050513          	addi	a0,a0,-400 # ffffffffc02066d8 <etext+0xf44>
ffffffffc0202870:	925fd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202874:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202878:	00099917          	auipc	s2,0x99
ffffffffc020287c:	f1890913          	addi	s2,s2,-232 # ffffffffc029b790 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202880:	7b9c                	ld	a5,48(a5)
ffffffffc0202882:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202884:	00004517          	auipc	a0,0x4
ffffffffc0202888:	e6c50513          	addi	a0,a0,-404 # ffffffffc02066f0 <etext+0xf5c>
ffffffffc020288c:	909fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202890:	00007697          	auipc	a3,0x7
ffffffffc0202894:	77068693          	addi	a3,a3,1904 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202898:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020289c:	c02007b7          	lui	a5,0xc0200
ffffffffc02028a0:	2af6eee3          	bltu	a3,a5,ffffffffc020335c <pmm_init+0xbf2>
ffffffffc02028a4:	0009b783          	ld	a5,0(s3)
ffffffffc02028a8:	8e9d                	sub	a3,a3,a5
ffffffffc02028aa:	00099797          	auipc	a5,0x99
ffffffffc02028ae:	ecd7bf23          	sd	a3,-290(a5) # ffffffffc029b788 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028b2:	100027f3          	csrr	a5,sstatus
ffffffffc02028b6:	8b89                	andi	a5,a5,2
ffffffffc02028b8:	48079963          	bnez	a5,ffffffffc0202d4a <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028bc:	000b3783          	ld	a5,0(s6)
ffffffffc02028c0:	779c                	ld	a5,40(a5)
ffffffffc02028c2:	9782                	jalr	a5
ffffffffc02028c4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028c6:	6098                	ld	a4,0(s1)
ffffffffc02028c8:	c80007b7          	lui	a5,0xc8000
ffffffffc02028cc:	83b1                	srli	a5,a5,0xc
ffffffffc02028ce:	66e7e663          	bltu	a5,a4,ffffffffc0202f3a <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028d2:	00093503          	ld	a0,0(s2)
ffffffffc02028d6:	64050263          	beqz	a0,ffffffffc0202f1a <pmm_init+0x7b0>
ffffffffc02028da:	03451793          	slli	a5,a0,0x34
ffffffffc02028de:	62079e63          	bnez	a5,ffffffffc0202f1a <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028e2:	4601                	li	a2,0
ffffffffc02028e4:	4581                	li	a1,0
ffffffffc02028e6:	8b7ff0ef          	jal	ffffffffc020219c <get_page>
ffffffffc02028ea:	240519e3          	bnez	a0,ffffffffc020333c <pmm_init+0xbd2>
ffffffffc02028ee:	100027f3          	csrr	a5,sstatus
ffffffffc02028f2:	8b89                	andi	a5,a5,2
ffffffffc02028f4:	44079063          	bnez	a5,ffffffffc0202d34 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028f8:	000b3783          	ld	a5,0(s6)
ffffffffc02028fc:	4505                	li	a0,1
ffffffffc02028fe:	6f9c                	ld	a5,24(a5)
ffffffffc0202900:	9782                	jalr	a5
ffffffffc0202902:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202904:	00093503          	ld	a0,0(s2)
ffffffffc0202908:	4681                	li	a3,0
ffffffffc020290a:	4601                	li	a2,0
ffffffffc020290c:	85d2                	mv	a1,s4
ffffffffc020290e:	d67ff0ef          	jal	ffffffffc0202674 <page_insert>
ffffffffc0202912:	280511e3          	bnez	a0,ffffffffc0203394 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202916:	00093503          	ld	a0,0(s2)
ffffffffc020291a:	4601                	li	a2,0
ffffffffc020291c:	4581                	li	a1,0
ffffffffc020291e:	e20ff0ef          	jal	ffffffffc0201f3e <get_pte>
ffffffffc0202922:	240509e3          	beqz	a0,ffffffffc0203374 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202926:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202928:	0017f713          	andi	a4,a5,1
ffffffffc020292c:	58070f63          	beqz	a4,ffffffffc0202eca <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202930:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202932:	078a                	slli	a5,a5,0x2
ffffffffc0202934:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202936:	58e7f863          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020293a:	000bb683          	ld	a3,0(s7)
ffffffffc020293e:	079a                	slli	a5,a5,0x6
ffffffffc0202940:	fe000637          	lui	a2,0xfe000
ffffffffc0202944:	97b2                	add	a5,a5,a2
ffffffffc0202946:	97b6                	add	a5,a5,a3
ffffffffc0202948:	14fa1ae3          	bne	s4,a5,ffffffffc020329c <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc020294c:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_exit_out_size+0x1f5e28>
ffffffffc0202950:	4785                	li	a5,1
ffffffffc0202952:	12f695e3          	bne	a3,a5,ffffffffc020327c <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202956:	00093503          	ld	a0,0(s2)
ffffffffc020295a:	77fd                	lui	a5,0xfffff
ffffffffc020295c:	6114                	ld	a3,0(a0)
ffffffffc020295e:	068a                	slli	a3,a3,0x2
ffffffffc0202960:	8efd                	and	a3,a3,a5
ffffffffc0202962:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202966:	0ee67fe3          	bgeu	a2,a4,ffffffffc0203264 <pmm_init+0xafa>
ffffffffc020296a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020296e:	96e2                	add	a3,a3,s8
ffffffffc0202970:	0006ba83          	ld	s5,0(a3)
ffffffffc0202974:	0a8a                	slli	s5,s5,0x2
ffffffffc0202976:	00fafab3          	and	s5,s5,a5
ffffffffc020297a:	00cad793          	srli	a5,s5,0xc
ffffffffc020297e:	0ce7f6e3          	bgeu	a5,a4,ffffffffc020324a <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202982:	4601                	li	a2,0
ffffffffc0202984:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202986:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202988:	db6ff0ef          	jal	ffffffffc0201f3e <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020298c:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020298e:	05851ee3          	bne	a0,s8,ffffffffc02031ea <pmm_init+0xa80>
ffffffffc0202992:	100027f3          	csrr	a5,sstatus
ffffffffc0202996:	8b89                	andi	a5,a5,2
ffffffffc0202998:	3e079b63          	bnez	a5,ffffffffc0202d8e <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc020299c:	000b3783          	ld	a5,0(s6)
ffffffffc02029a0:	4505                	li	a0,1
ffffffffc02029a2:	6f9c                	ld	a5,24(a5)
ffffffffc02029a4:	9782                	jalr	a5
ffffffffc02029a6:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029a8:	00093503          	ld	a0,0(s2)
ffffffffc02029ac:	46d1                	li	a3,20
ffffffffc02029ae:	6605                	lui	a2,0x1
ffffffffc02029b0:	85e2                	mv	a1,s8
ffffffffc02029b2:	cc3ff0ef          	jal	ffffffffc0202674 <page_insert>
ffffffffc02029b6:	06051ae3          	bnez	a0,ffffffffc020322a <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029ba:	00093503          	ld	a0,0(s2)
ffffffffc02029be:	4601                	li	a2,0
ffffffffc02029c0:	6585                	lui	a1,0x1
ffffffffc02029c2:	d7cff0ef          	jal	ffffffffc0201f3e <get_pte>
ffffffffc02029c6:	040502e3          	beqz	a0,ffffffffc020320a <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02029ca:	611c                	ld	a5,0(a0)
ffffffffc02029cc:	0107f713          	andi	a4,a5,16
ffffffffc02029d0:	7e070163          	beqz	a4,ffffffffc02031b2 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02029d4:	8b91                	andi	a5,a5,4
ffffffffc02029d6:	7a078e63          	beqz	a5,ffffffffc0203192 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029da:	00093503          	ld	a0,0(s2)
ffffffffc02029de:	611c                	ld	a5,0(a0)
ffffffffc02029e0:	8bc1                	andi	a5,a5,16
ffffffffc02029e2:	78078863          	beqz	a5,ffffffffc0203172 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02029e6:	000c2703          	lw	a4,0(s8)
ffffffffc02029ea:	4785                	li	a5,1
ffffffffc02029ec:	76f71363          	bne	a4,a5,ffffffffc0203152 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029f0:	4681                	li	a3,0
ffffffffc02029f2:	6605                	lui	a2,0x1
ffffffffc02029f4:	85d2                	mv	a1,s4
ffffffffc02029f6:	c7fff0ef          	jal	ffffffffc0202674 <page_insert>
ffffffffc02029fa:	72051c63          	bnez	a0,ffffffffc0203132 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02029fe:	000a2703          	lw	a4,0(s4)
ffffffffc0202a02:	4789                	li	a5,2
ffffffffc0202a04:	70f71763          	bne	a4,a5,ffffffffc0203112 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202a08:	000c2783          	lw	a5,0(s8)
ffffffffc0202a0c:	6e079363          	bnez	a5,ffffffffc02030f2 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a10:	00093503          	ld	a0,0(s2)
ffffffffc0202a14:	4601                	li	a2,0
ffffffffc0202a16:	6585                	lui	a1,0x1
ffffffffc0202a18:	d26ff0ef          	jal	ffffffffc0201f3e <get_pte>
ffffffffc0202a1c:	6a050b63          	beqz	a0,ffffffffc02030d2 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a20:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a22:	00177793          	andi	a5,a4,1
ffffffffc0202a26:	4a078263          	beqz	a5,ffffffffc0202eca <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a2a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a2c:	00271793          	slli	a5,a4,0x2
ffffffffc0202a30:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a32:	48d7fa63          	bgeu	a5,a3,ffffffffc0202ec6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a36:	000bb683          	ld	a3,0(s7)
ffffffffc0202a3a:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a3e:	97d6                	add	a5,a5,s5
ffffffffc0202a40:	079a                	slli	a5,a5,0x6
ffffffffc0202a42:	97b6                	add	a5,a5,a3
ffffffffc0202a44:	66fa1763          	bne	s4,a5,ffffffffc02030b2 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a48:	8b41                	andi	a4,a4,16
ffffffffc0202a4a:	64071463          	bnez	a4,ffffffffc0203092 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a4e:	00093503          	ld	a0,0(s2)
ffffffffc0202a52:	4581                	li	a1,0
ffffffffc0202a54:	b85ff0ef          	jal	ffffffffc02025d8 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a58:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a5c:	4785                	li	a5,1
ffffffffc0202a5e:	60fc9a63          	bne	s9,a5,ffffffffc0203072 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202a62:	000c2783          	lw	a5,0(s8)
ffffffffc0202a66:	5e079663          	bnez	a5,ffffffffc0203052 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a6a:	00093503          	ld	a0,0(s2)
ffffffffc0202a6e:	6585                	lui	a1,0x1
ffffffffc0202a70:	b69ff0ef          	jal	ffffffffc02025d8 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a74:	000a2783          	lw	a5,0(s4)
ffffffffc0202a78:	52079d63          	bnez	a5,ffffffffc0202fb2 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202a7c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a80:	50079963          	bnez	a5,ffffffffc0202f92 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a84:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a88:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a8a:	000a3783          	ld	a5,0(s4)
ffffffffc0202a8e:	078a                	slli	a5,a5,0x2
ffffffffc0202a90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a92:	42e7fa63          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a96:	000bb503          	ld	a0,0(s7)
ffffffffc0202a9a:	97d6                	add	a5,a5,s5
ffffffffc0202a9c:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202a9e:	00f506b3          	add	a3,a0,a5
ffffffffc0202aa2:	4294                	lw	a3,0(a3)
ffffffffc0202aa4:	4d969763          	bne	a3,s9,ffffffffc0202f72 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202aa8:	8799                	srai	a5,a5,0x6
ffffffffc0202aaa:	00080637          	lui	a2,0x80
ffffffffc0202aae:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ab0:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202ab4:	4ae7f363          	bgeu	a5,a4,ffffffffc0202f5a <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ab8:	0009b783          	ld	a5,0(s3)
ffffffffc0202abc:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202abe:	639c                	ld	a5,0(a5)
ffffffffc0202ac0:	078a                	slli	a5,a5,0x2
ffffffffc0202ac2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ac4:	40e7f163          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ac8:	8f91                	sub	a5,a5,a2
ffffffffc0202aca:	079a                	slli	a5,a5,0x6
ffffffffc0202acc:	953e                	add	a0,a0,a5
ffffffffc0202ace:	100027f3          	csrr	a5,sstatus
ffffffffc0202ad2:	8b89                	andi	a5,a5,2
ffffffffc0202ad4:	30079863          	bnez	a5,ffffffffc0202de4 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202ad8:	000b3783          	ld	a5,0(s6)
ffffffffc0202adc:	4585                	li	a1,1
ffffffffc0202ade:	739c                	ld	a5,32(a5)
ffffffffc0202ae0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ae2:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202ae6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ae8:	078a                	slli	a5,a5,0x2
ffffffffc0202aea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aec:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202af0:	000bb503          	ld	a0,0(s7)
ffffffffc0202af4:	fe000737          	lui	a4,0xfe000
ffffffffc0202af8:	079a                	slli	a5,a5,0x6
ffffffffc0202afa:	97ba                	add	a5,a5,a4
ffffffffc0202afc:	953e                	add	a0,a0,a5
ffffffffc0202afe:	100027f3          	csrr	a5,sstatus
ffffffffc0202b02:	8b89                	andi	a5,a5,2
ffffffffc0202b04:	2c079463          	bnez	a5,ffffffffc0202dcc <pmm_init+0x662>
ffffffffc0202b08:	000b3783          	ld	a5,0(s6)
ffffffffc0202b0c:	4585                	li	a1,1
ffffffffc0202b0e:	739c                	ld	a5,32(a5)
ffffffffc0202b10:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b12:	00093783          	ld	a5,0(s2)
ffffffffc0202b16:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd63830>
    asm volatile("sfence.vma");
ffffffffc0202b1a:	12000073          	sfence.vma
ffffffffc0202b1e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b22:	8b89                	andi	a5,a5,2
ffffffffc0202b24:	28079a63          	bnez	a5,ffffffffc0202db8 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b28:	000b3783          	ld	a5,0(s6)
ffffffffc0202b2c:	779c                	ld	a5,40(a5)
ffffffffc0202b2e:	9782                	jalr	a5
ffffffffc0202b30:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b32:	4d441063          	bne	s0,s4,ffffffffc0202ff2 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b36:	00004517          	auipc	a0,0x4
ffffffffc0202b3a:	f0a50513          	addi	a0,a0,-246 # ffffffffc0206a40 <etext+0x12ac>
ffffffffc0202b3e:	e56fd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202b42:	100027f3          	csrr	a5,sstatus
ffffffffc0202b46:	8b89                	andi	a5,a5,2
ffffffffc0202b48:	24079e63          	bnez	a5,ffffffffc0202da4 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b4c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b50:	779c                	ld	a5,40(a5)
ffffffffc0202b52:	9782                	jalr	a5
ffffffffc0202b54:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b56:	609c                	ld	a5,0(s1)
ffffffffc0202b58:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b5c:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b5e:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b62:	6a85                	lui	s5,0x1
ffffffffc0202b64:	02e47c63          	bgeu	s0,a4,ffffffffc0202b9c <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b68:	00c45713          	srli	a4,s0,0xc
ffffffffc0202b6c:	30f77063          	bgeu	a4,a5,ffffffffc0202e6c <pmm_init+0x702>
ffffffffc0202b70:	0009b583          	ld	a1,0(s3)
ffffffffc0202b74:	00093503          	ld	a0,0(s2)
ffffffffc0202b78:	4601                	li	a2,0
ffffffffc0202b7a:	95a2                	add	a1,a1,s0
ffffffffc0202b7c:	bc2ff0ef          	jal	ffffffffc0201f3e <get_pte>
ffffffffc0202b80:	32050363          	beqz	a0,ffffffffc0202ea6 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b84:	611c                	ld	a5,0(a0)
ffffffffc0202b86:	078a                	slli	a5,a5,0x2
ffffffffc0202b88:	0147f7b3          	and	a5,a5,s4
ffffffffc0202b8c:	2e879d63          	bne	a5,s0,ffffffffc0202e86 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b90:	609c                	ld	a5,0(s1)
ffffffffc0202b92:	9456                	add	s0,s0,s5
ffffffffc0202b94:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b98:	fce468e3          	bltu	s0,a4,ffffffffc0202b68 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b9c:	00093783          	ld	a5,0(s2)
ffffffffc0202ba0:	639c                	ld	a5,0(a5)
ffffffffc0202ba2:	42079863          	bnez	a5,ffffffffc0202fd2 <pmm_init+0x868>
ffffffffc0202ba6:	100027f3          	csrr	a5,sstatus
ffffffffc0202baa:	8b89                	andi	a5,a5,2
ffffffffc0202bac:	24079863          	bnez	a5,ffffffffc0202dfc <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bb0:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb4:	4505                	li	a0,1
ffffffffc0202bb6:	6f9c                	ld	a5,24(a5)
ffffffffc0202bb8:	9782                	jalr	a5
ffffffffc0202bba:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bbc:	00093503          	ld	a0,0(s2)
ffffffffc0202bc0:	4699                	li	a3,6
ffffffffc0202bc2:	10000613          	li	a2,256
ffffffffc0202bc6:	85a2                	mv	a1,s0
ffffffffc0202bc8:	aadff0ef          	jal	ffffffffc0202674 <page_insert>
ffffffffc0202bcc:	46051363          	bnez	a0,ffffffffc0203032 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202bd0:	4018                	lw	a4,0(s0)
ffffffffc0202bd2:	4785                	li	a5,1
ffffffffc0202bd4:	42f71f63          	bne	a4,a5,ffffffffc0203012 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bd8:	00093503          	ld	a0,0(s2)
ffffffffc0202bdc:	6605                	lui	a2,0x1
ffffffffc0202bde:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7ad0>
ffffffffc0202be2:	4699                	li	a3,6
ffffffffc0202be4:	85a2                	mv	a1,s0
ffffffffc0202be6:	a8fff0ef          	jal	ffffffffc0202674 <page_insert>
ffffffffc0202bea:	72051963          	bnez	a0,ffffffffc020331c <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202bee:	4018                	lw	a4,0(s0)
ffffffffc0202bf0:	4789                	li	a5,2
ffffffffc0202bf2:	70f71563          	bne	a4,a5,ffffffffc02032fc <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bf6:	00004597          	auipc	a1,0x4
ffffffffc0202bfa:	f9258593          	addi	a1,a1,-110 # ffffffffc0206b88 <etext+0x13f4>
ffffffffc0202bfe:	10000513          	li	a0,256
ffffffffc0202c02:	2e9020ef          	jal	ffffffffc02056ea <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c06:	6585                	lui	a1,0x1
ffffffffc0202c08:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7ad0>
ffffffffc0202c0c:	10000513          	li	a0,256
ffffffffc0202c10:	2ed020ef          	jal	ffffffffc02056fc <strcmp>
ffffffffc0202c14:	6c051463          	bnez	a0,ffffffffc02032dc <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202c18:	000bb683          	ld	a3,0(s7)
ffffffffc0202c1c:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c20:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c22:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c26:	8699                	srai	a3,a3,0x6
ffffffffc0202c28:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c2a:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c2e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c30:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c32:	32e7f463          	bgeu	a5,a4,ffffffffc0202f5a <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c36:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c3a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c3e:	97b6                	add	a5,a5,a3
ffffffffc0202c40:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x75f28>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c44:	273020ef          	jal	ffffffffc02056b6 <strlen>
ffffffffc0202c48:	66051a63          	bnez	a0,ffffffffc02032bc <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c4c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c50:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c52:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd63830>
ffffffffc0202c56:	078a                	slli	a5,a5,0x2
ffffffffc0202c58:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c5a:	26e7f663          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c5e:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202c62:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202f5a <pmm_init+0x7f0>
ffffffffc0202c66:	0009b783          	ld	a5,0(s3)
ffffffffc0202c6a:	00f689b3          	add	s3,a3,a5
ffffffffc0202c6e:	100027f3          	csrr	a5,sstatus
ffffffffc0202c72:	8b89                	andi	a5,a5,2
ffffffffc0202c74:	1e079163          	bnez	a5,ffffffffc0202e56 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202c78:	000b3783          	ld	a5,0(s6)
ffffffffc0202c7c:	8522                	mv	a0,s0
ffffffffc0202c7e:	4585                	li	a1,1
ffffffffc0202c80:	739c                	ld	a5,32(a5)
ffffffffc0202c82:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c84:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202c88:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c8a:	078a                	slli	a5,a5,0x2
ffffffffc0202c8c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c8e:	22e7fc63          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c92:	000bb503          	ld	a0,0(s7)
ffffffffc0202c96:	fe000737          	lui	a4,0xfe000
ffffffffc0202c9a:	079a                	slli	a5,a5,0x6
ffffffffc0202c9c:	97ba                	add	a5,a5,a4
ffffffffc0202c9e:	953e                	add	a0,a0,a5
ffffffffc0202ca0:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca4:	8b89                	andi	a5,a5,2
ffffffffc0202ca6:	18079c63          	bnez	a5,ffffffffc0202e3e <pmm_init+0x6d4>
ffffffffc0202caa:	000b3783          	ld	a5,0(s6)
ffffffffc0202cae:	4585                	li	a1,1
ffffffffc0202cb0:	739c                	ld	a5,32(a5)
ffffffffc0202cb2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb4:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202cb8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cba:	078a                	slli	a5,a5,0x2
ffffffffc0202cbc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cbe:	20e7f463          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cc2:	000bb503          	ld	a0,0(s7)
ffffffffc0202cc6:	fe000737          	lui	a4,0xfe000
ffffffffc0202cca:	079a                	slli	a5,a5,0x6
ffffffffc0202ccc:	97ba                	add	a5,a5,a4
ffffffffc0202cce:	953e                	add	a0,a0,a5
ffffffffc0202cd0:	100027f3          	csrr	a5,sstatus
ffffffffc0202cd4:	8b89                	andi	a5,a5,2
ffffffffc0202cd6:	14079863          	bnez	a5,ffffffffc0202e26 <pmm_init+0x6bc>
ffffffffc0202cda:	000b3783          	ld	a5,0(s6)
ffffffffc0202cde:	4585                	li	a1,1
ffffffffc0202ce0:	739c                	ld	a5,32(a5)
ffffffffc0202ce2:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ce4:	00093783          	ld	a5,0(s2)
ffffffffc0202ce8:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202cec:	12000073          	sfence.vma
ffffffffc0202cf0:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf4:	8b89                	andi	a5,a5,2
ffffffffc0202cf6:	10079e63          	bnez	a5,ffffffffc0202e12 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cfa:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfe:	779c                	ld	a5,40(a5)
ffffffffc0202d00:	9782                	jalr	a5
ffffffffc0202d02:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d04:	1e8c1b63          	bne	s8,s0,ffffffffc0202efa <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d08:	00004517          	auipc	a0,0x4
ffffffffc0202d0c:	ef850513          	addi	a0,a0,-264 # ffffffffc0206c00 <etext+0x146c>
ffffffffc0202d10:	c84fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202d14:	7406                	ld	s0,96(sp)
ffffffffc0202d16:	70a6                	ld	ra,104(sp)
ffffffffc0202d18:	64e6                	ld	s1,88(sp)
ffffffffc0202d1a:	6946                	ld	s2,80(sp)
ffffffffc0202d1c:	69a6                	ld	s3,72(sp)
ffffffffc0202d1e:	6a06                	ld	s4,64(sp)
ffffffffc0202d20:	7ae2                	ld	s5,56(sp)
ffffffffc0202d22:	7b42                	ld	s6,48(sp)
ffffffffc0202d24:	7ba2                	ld	s7,40(sp)
ffffffffc0202d26:	7c02                	ld	s8,32(sp)
ffffffffc0202d28:	6ce2                	ld	s9,24(sp)
ffffffffc0202d2a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d2c:	f85fe06f          	j	ffffffffc0201cb0 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202d30:	853e                	mv	a0,a5
ffffffffc0202d32:	b4e1                	j	ffffffffc02027fa <pmm_init+0x90>
        intr_disable();
ffffffffc0202d34:	bd1fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d38:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3c:	4505                	li	a0,1
ffffffffc0202d3e:	6f9c                	ld	a5,24(a5)
ffffffffc0202d40:	9782                	jalr	a5
ffffffffc0202d42:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d44:	bbbfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d48:	be75                	j	ffffffffc0202904 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202d4a:	bbbfd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d4e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d52:	779c                	ld	a5,40(a5)
ffffffffc0202d54:	9782                	jalr	a5
ffffffffc0202d56:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d58:	ba7fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d5c:	b6ad                	j	ffffffffc02028c6 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d5e:	6705                	lui	a4,0x1
ffffffffc0202d60:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7bd1>
ffffffffc0202d62:	96ba                	add	a3,a3,a4
ffffffffc0202d64:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d66:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d6a:	14a77e63          	bgeu	a4,a0,ffffffffc0202ec6 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d6e:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d72:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202d74:	071a                	slli	a4,a4,0x6
ffffffffc0202d76:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202d7a:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202d7c:	6a9c                	ld	a5,16(a3)
ffffffffc0202d7e:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d82:	00e60533          	add	a0,a2,a4
ffffffffc0202d86:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d88:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d8c:	bcf1                	j	ffffffffc0202868 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202d8e:	b77fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d92:	000b3783          	ld	a5,0(s6)
ffffffffc0202d96:	4505                	li	a0,1
ffffffffc0202d98:	6f9c                	ld	a5,24(a5)
ffffffffc0202d9a:	9782                	jalr	a5
ffffffffc0202d9c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d9e:	b61fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202da2:	b119                	j	ffffffffc02029a8 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202da4:	b61fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202da8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dac:	779c                	ld	a5,40(a5)
ffffffffc0202dae:	9782                	jalr	a5
ffffffffc0202db0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202db2:	b4dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202db6:	b345                	j	ffffffffc0202b56 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202db8:	b4dfd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202dbc:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc0:	779c                	ld	a5,40(a5)
ffffffffc0202dc2:	9782                	jalr	a5
ffffffffc0202dc4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dc6:	b39fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dca:	b3a5                	j	ffffffffc0202b32 <pmm_init+0x3c8>
ffffffffc0202dcc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dce:	b37fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dd2:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd6:	6522                	ld	a0,8(sp)
ffffffffc0202dd8:	4585                	li	a1,1
ffffffffc0202dda:	739c                	ld	a5,32(a5)
ffffffffc0202ddc:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dde:	b21fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202de2:	bb05                	j	ffffffffc0202b12 <pmm_init+0x3a8>
ffffffffc0202de4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202de6:	b1ffd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202dea:	000b3783          	ld	a5,0(s6)
ffffffffc0202dee:	6522                	ld	a0,8(sp)
ffffffffc0202df0:	4585                	li	a1,1
ffffffffc0202df2:	739c                	ld	a5,32(a5)
ffffffffc0202df4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202df6:	b09fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dfa:	b1e5                	j	ffffffffc0202ae2 <pmm_init+0x378>
        intr_disable();
ffffffffc0202dfc:	b09fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e00:	000b3783          	ld	a5,0(s6)
ffffffffc0202e04:	4505                	li	a0,1
ffffffffc0202e06:	6f9c                	ld	a5,24(a5)
ffffffffc0202e08:	9782                	jalr	a5
ffffffffc0202e0a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e0c:	af3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e10:	b375                	j	ffffffffc0202bbc <pmm_init+0x452>
        intr_disable();
ffffffffc0202e12:	af3fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e16:	000b3783          	ld	a5,0(s6)
ffffffffc0202e1a:	779c                	ld	a5,40(a5)
ffffffffc0202e1c:	9782                	jalr	a5
ffffffffc0202e1e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e20:	adffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e24:	b5c5                	j	ffffffffc0202d04 <pmm_init+0x59a>
ffffffffc0202e26:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e28:	addfd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e2c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e30:	6522                	ld	a0,8(sp)
ffffffffc0202e32:	4585                	li	a1,1
ffffffffc0202e34:	739c                	ld	a5,32(a5)
ffffffffc0202e36:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e38:	ac7fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e3c:	b565                	j	ffffffffc0202ce4 <pmm_init+0x57a>
ffffffffc0202e3e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e40:	ac5fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e44:	000b3783          	ld	a5,0(s6)
ffffffffc0202e48:	6522                	ld	a0,8(sp)
ffffffffc0202e4a:	4585                	li	a1,1
ffffffffc0202e4c:	739c                	ld	a5,32(a5)
ffffffffc0202e4e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e50:	aaffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e54:	b585                	j	ffffffffc0202cb4 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202e56:	aaffd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e5a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e5e:	8522                	mv	a0,s0
ffffffffc0202e60:	4585                	li	a1,1
ffffffffc0202e62:	739c                	ld	a5,32(a5)
ffffffffc0202e64:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e66:	a99fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e6a:	bd29                	j	ffffffffc0202c84 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e6c:	86a2                	mv	a3,s0
ffffffffc0202e6e:	00003617          	auipc	a2,0x3
ffffffffc0202e72:	6aa60613          	addi	a2,a2,1706 # ffffffffc0206518 <etext+0xd84>
ffffffffc0202e76:	24c00593          	li	a1,588
ffffffffc0202e7a:	00003517          	auipc	a0,0x3
ffffffffc0202e7e:	78e50513          	addi	a0,a0,1934 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202e82:	dc4fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e86:	00004697          	auipc	a3,0x4
ffffffffc0202e8a:	c1a68693          	addi	a3,a3,-998 # ffffffffc0206aa0 <etext+0x130c>
ffffffffc0202e8e:	00003617          	auipc	a2,0x3
ffffffffc0202e92:	2da60613          	addi	a2,a2,730 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202e96:	24d00593          	li	a1,589
ffffffffc0202e9a:	00003517          	auipc	a0,0x3
ffffffffc0202e9e:	76e50513          	addi	a0,a0,1902 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202ea2:	da4fd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ea6:	00004697          	auipc	a3,0x4
ffffffffc0202eaa:	bba68693          	addi	a3,a3,-1094 # ffffffffc0206a60 <etext+0x12cc>
ffffffffc0202eae:	00003617          	auipc	a2,0x3
ffffffffc0202eb2:	2ba60613          	addi	a2,a2,698 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202eb6:	24c00593          	li	a1,588
ffffffffc0202eba:	00003517          	auipc	a0,0x3
ffffffffc0202ebe:	74e50513          	addi	a0,a0,1870 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202ec2:	d84fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202ec6:	fb5fe0ef          	jal	ffffffffc0201e7a <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202eca:	00004617          	auipc	a2,0x4
ffffffffc0202ece:	93660613          	addi	a2,a2,-1738 # ffffffffc0206800 <etext+0x106c>
ffffffffc0202ed2:	07f00593          	li	a1,127
ffffffffc0202ed6:	00003517          	auipc	a0,0x3
ffffffffc0202eda:	66a50513          	addi	a0,a0,1642 # ffffffffc0206540 <etext+0xdac>
ffffffffc0202ede:	d68fd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202ee2:	00003617          	auipc	a2,0x3
ffffffffc0202ee6:	79660613          	addi	a2,a2,1942 # ffffffffc0206678 <etext+0xee4>
ffffffffc0202eea:	06500593          	li	a1,101
ffffffffc0202eee:	00003517          	auipc	a0,0x3
ffffffffc0202ef2:	71a50513          	addi	a0,a0,1818 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202ef6:	d50fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202efa:	00004697          	auipc	a3,0x4
ffffffffc0202efe:	b1e68693          	addi	a3,a3,-1250 # ffffffffc0206a18 <etext+0x1284>
ffffffffc0202f02:	00003617          	auipc	a2,0x3
ffffffffc0202f06:	26660613          	addi	a2,a2,614 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202f0a:	26700593          	li	a1,615
ffffffffc0202f0e:	00003517          	auipc	a0,0x3
ffffffffc0202f12:	6fa50513          	addi	a0,a0,1786 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202f16:	d30fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f1a:	00004697          	auipc	a3,0x4
ffffffffc0202f1e:	81668693          	addi	a3,a3,-2026 # ffffffffc0206730 <etext+0xf9c>
ffffffffc0202f22:	00003617          	auipc	a2,0x3
ffffffffc0202f26:	24660613          	addi	a2,a2,582 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202f2a:	20e00593          	li	a1,526
ffffffffc0202f2e:	00003517          	auipc	a0,0x3
ffffffffc0202f32:	6da50513          	addi	a0,a0,1754 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202f36:	d10fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f3a:	00003697          	auipc	a3,0x3
ffffffffc0202f3e:	7d668693          	addi	a3,a3,2006 # ffffffffc0206710 <etext+0xf7c>
ffffffffc0202f42:	00003617          	auipc	a2,0x3
ffffffffc0202f46:	22660613          	addi	a2,a2,550 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202f4a:	20d00593          	li	a1,525
ffffffffc0202f4e:	00003517          	auipc	a0,0x3
ffffffffc0202f52:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202f56:	cf0fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f5a:	00003617          	auipc	a2,0x3
ffffffffc0202f5e:	5be60613          	addi	a2,a2,1470 # ffffffffc0206518 <etext+0xd84>
ffffffffc0202f62:	07100593          	li	a1,113
ffffffffc0202f66:	00003517          	auipc	a0,0x3
ffffffffc0202f6a:	5da50513          	addi	a0,a0,1498 # ffffffffc0206540 <etext+0xdac>
ffffffffc0202f6e:	cd8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f72:	00004697          	auipc	a3,0x4
ffffffffc0202f76:	a7668693          	addi	a3,a3,-1418 # ffffffffc02069e8 <etext+0x1254>
ffffffffc0202f7a:	00003617          	auipc	a2,0x3
ffffffffc0202f7e:	1ee60613          	addi	a2,a2,494 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202f82:	23500593          	li	a1,565
ffffffffc0202f86:	00003517          	auipc	a0,0x3
ffffffffc0202f8a:	68250513          	addi	a0,a0,1666 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202f8e:	cb8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f92:	00004697          	auipc	a3,0x4
ffffffffc0202f96:	a0e68693          	addi	a3,a3,-1522 # ffffffffc02069a0 <etext+0x120c>
ffffffffc0202f9a:	00003617          	auipc	a2,0x3
ffffffffc0202f9e:	1ce60613          	addi	a2,a2,462 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202fa2:	23300593          	li	a1,563
ffffffffc0202fa6:	00003517          	auipc	a0,0x3
ffffffffc0202faa:	66250513          	addi	a0,a0,1634 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202fae:	c98fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fb2:	00004697          	auipc	a3,0x4
ffffffffc0202fb6:	a1e68693          	addi	a3,a3,-1506 # ffffffffc02069d0 <etext+0x123c>
ffffffffc0202fba:	00003617          	auipc	a2,0x3
ffffffffc0202fbe:	1ae60613          	addi	a2,a2,430 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202fc2:	23200593          	li	a1,562
ffffffffc0202fc6:	00003517          	auipc	a0,0x3
ffffffffc0202fca:	64250513          	addi	a0,a0,1602 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202fce:	c78fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fd2:	00004697          	auipc	a3,0x4
ffffffffc0202fd6:	ae668693          	addi	a3,a3,-1306 # ffffffffc0206ab8 <etext+0x1324>
ffffffffc0202fda:	00003617          	auipc	a2,0x3
ffffffffc0202fde:	18e60613          	addi	a2,a2,398 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0202fe2:	25000593          	li	a1,592
ffffffffc0202fe6:	00003517          	auipc	a0,0x3
ffffffffc0202fea:	62250513          	addi	a0,a0,1570 # ffffffffc0206608 <etext+0xe74>
ffffffffc0202fee:	c58fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ff2:	00004697          	auipc	a3,0x4
ffffffffc0202ff6:	a2668693          	addi	a3,a3,-1498 # ffffffffc0206a18 <etext+0x1284>
ffffffffc0202ffa:	00003617          	auipc	a2,0x3
ffffffffc0202ffe:	16e60613          	addi	a2,a2,366 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203002:	23d00593          	li	a1,573
ffffffffc0203006:	00003517          	auipc	a0,0x3
ffffffffc020300a:	60250513          	addi	a0,a0,1538 # ffffffffc0206608 <etext+0xe74>
ffffffffc020300e:	c38fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203012:	00004697          	auipc	a3,0x4
ffffffffc0203016:	afe68693          	addi	a3,a3,-1282 # ffffffffc0206b10 <etext+0x137c>
ffffffffc020301a:	00003617          	auipc	a2,0x3
ffffffffc020301e:	14e60613          	addi	a2,a2,334 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203022:	25500593          	li	a1,597
ffffffffc0203026:	00003517          	auipc	a0,0x3
ffffffffc020302a:	5e250513          	addi	a0,a0,1506 # ffffffffc0206608 <etext+0xe74>
ffffffffc020302e:	c18fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203032:	00004697          	auipc	a3,0x4
ffffffffc0203036:	a9e68693          	addi	a3,a3,-1378 # ffffffffc0206ad0 <etext+0x133c>
ffffffffc020303a:	00003617          	auipc	a2,0x3
ffffffffc020303e:	12e60613          	addi	a2,a2,302 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203042:	25400593          	li	a1,596
ffffffffc0203046:	00003517          	auipc	a0,0x3
ffffffffc020304a:	5c250513          	addi	a0,a0,1474 # ffffffffc0206608 <etext+0xe74>
ffffffffc020304e:	bf8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203052:	00004697          	auipc	a3,0x4
ffffffffc0203056:	94e68693          	addi	a3,a3,-1714 # ffffffffc02069a0 <etext+0x120c>
ffffffffc020305a:	00003617          	auipc	a2,0x3
ffffffffc020305e:	10e60613          	addi	a2,a2,270 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203062:	22f00593          	li	a1,559
ffffffffc0203066:	00003517          	auipc	a0,0x3
ffffffffc020306a:	5a250513          	addi	a0,a0,1442 # ffffffffc0206608 <etext+0xe74>
ffffffffc020306e:	bd8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203072:	00003697          	auipc	a3,0x3
ffffffffc0203076:	7ce68693          	addi	a3,a3,1998 # ffffffffc0206840 <etext+0x10ac>
ffffffffc020307a:	00003617          	auipc	a2,0x3
ffffffffc020307e:	0ee60613          	addi	a2,a2,238 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203082:	22e00593          	li	a1,558
ffffffffc0203086:	00003517          	auipc	a0,0x3
ffffffffc020308a:	58250513          	addi	a0,a0,1410 # ffffffffc0206608 <etext+0xe74>
ffffffffc020308e:	bb8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203092:	00004697          	auipc	a3,0x4
ffffffffc0203096:	92668693          	addi	a3,a3,-1754 # ffffffffc02069b8 <etext+0x1224>
ffffffffc020309a:	00003617          	auipc	a2,0x3
ffffffffc020309e:	0ce60613          	addi	a2,a2,206 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02030a2:	22b00593          	li	a1,555
ffffffffc02030a6:	00003517          	auipc	a0,0x3
ffffffffc02030aa:	56250513          	addi	a0,a0,1378 # ffffffffc0206608 <etext+0xe74>
ffffffffc02030ae:	b98fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030b2:	00003697          	auipc	a3,0x3
ffffffffc02030b6:	77668693          	addi	a3,a3,1910 # ffffffffc0206828 <etext+0x1094>
ffffffffc02030ba:	00003617          	auipc	a2,0x3
ffffffffc02030be:	0ae60613          	addi	a2,a2,174 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02030c2:	22a00593          	li	a1,554
ffffffffc02030c6:	00003517          	auipc	a0,0x3
ffffffffc02030ca:	54250513          	addi	a0,a0,1346 # ffffffffc0206608 <etext+0xe74>
ffffffffc02030ce:	b78fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030d2:	00003697          	auipc	a3,0x3
ffffffffc02030d6:	7f668693          	addi	a3,a3,2038 # ffffffffc02068c8 <etext+0x1134>
ffffffffc02030da:	00003617          	auipc	a2,0x3
ffffffffc02030de:	08e60613          	addi	a2,a2,142 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02030e2:	22900593          	li	a1,553
ffffffffc02030e6:	00003517          	auipc	a0,0x3
ffffffffc02030ea:	52250513          	addi	a0,a0,1314 # ffffffffc0206608 <etext+0xe74>
ffffffffc02030ee:	b58fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030f2:	00004697          	auipc	a3,0x4
ffffffffc02030f6:	8ae68693          	addi	a3,a3,-1874 # ffffffffc02069a0 <etext+0x120c>
ffffffffc02030fa:	00003617          	auipc	a2,0x3
ffffffffc02030fe:	06e60613          	addi	a2,a2,110 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203102:	22800593          	li	a1,552
ffffffffc0203106:	00003517          	auipc	a0,0x3
ffffffffc020310a:	50250513          	addi	a0,a0,1282 # ffffffffc0206608 <etext+0xe74>
ffffffffc020310e:	b38fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203112:	00004697          	auipc	a3,0x4
ffffffffc0203116:	87668693          	addi	a3,a3,-1930 # ffffffffc0206988 <etext+0x11f4>
ffffffffc020311a:	00003617          	auipc	a2,0x3
ffffffffc020311e:	04e60613          	addi	a2,a2,78 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203122:	22700593          	li	a1,551
ffffffffc0203126:	00003517          	auipc	a0,0x3
ffffffffc020312a:	4e250513          	addi	a0,a0,1250 # ffffffffc0206608 <etext+0xe74>
ffffffffc020312e:	b18fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203132:	00004697          	auipc	a3,0x4
ffffffffc0203136:	82668693          	addi	a3,a3,-2010 # ffffffffc0206958 <etext+0x11c4>
ffffffffc020313a:	00003617          	auipc	a2,0x3
ffffffffc020313e:	02e60613          	addi	a2,a2,46 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203142:	22600593          	li	a1,550
ffffffffc0203146:	00003517          	auipc	a0,0x3
ffffffffc020314a:	4c250513          	addi	a0,a0,1218 # ffffffffc0206608 <etext+0xe74>
ffffffffc020314e:	af8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203152:	00003697          	auipc	a3,0x3
ffffffffc0203156:	7ee68693          	addi	a3,a3,2030 # ffffffffc0206940 <etext+0x11ac>
ffffffffc020315a:	00003617          	auipc	a2,0x3
ffffffffc020315e:	00e60613          	addi	a2,a2,14 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203162:	22400593          	li	a1,548
ffffffffc0203166:	00003517          	auipc	a0,0x3
ffffffffc020316a:	4a250513          	addi	a0,a0,1186 # ffffffffc0206608 <etext+0xe74>
ffffffffc020316e:	ad8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203172:	00003697          	auipc	a3,0x3
ffffffffc0203176:	7ae68693          	addi	a3,a3,1966 # ffffffffc0206920 <etext+0x118c>
ffffffffc020317a:	00003617          	auipc	a2,0x3
ffffffffc020317e:	fee60613          	addi	a2,a2,-18 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203182:	22300593          	li	a1,547
ffffffffc0203186:	00003517          	auipc	a0,0x3
ffffffffc020318a:	48250513          	addi	a0,a0,1154 # ffffffffc0206608 <etext+0xe74>
ffffffffc020318e:	ab8fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203192:	00003697          	auipc	a3,0x3
ffffffffc0203196:	77e68693          	addi	a3,a3,1918 # ffffffffc0206910 <etext+0x117c>
ffffffffc020319a:	00003617          	auipc	a2,0x3
ffffffffc020319e:	fce60613          	addi	a2,a2,-50 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02031a2:	22200593          	li	a1,546
ffffffffc02031a6:	00003517          	auipc	a0,0x3
ffffffffc02031aa:	46250513          	addi	a0,a0,1122 # ffffffffc0206608 <etext+0xe74>
ffffffffc02031ae:	a98fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031b2:	00003697          	auipc	a3,0x3
ffffffffc02031b6:	74e68693          	addi	a3,a3,1870 # ffffffffc0206900 <etext+0x116c>
ffffffffc02031ba:	00003617          	auipc	a2,0x3
ffffffffc02031be:	fae60613          	addi	a2,a2,-82 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02031c2:	22100593          	li	a1,545
ffffffffc02031c6:	00003517          	auipc	a0,0x3
ffffffffc02031ca:	44250513          	addi	a0,a0,1090 # ffffffffc0206608 <etext+0xe74>
ffffffffc02031ce:	a78fd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02031d2:	00003617          	auipc	a2,0x3
ffffffffc02031d6:	3ee60613          	addi	a2,a2,1006 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc02031da:	08100593          	li	a1,129
ffffffffc02031de:	00003517          	auipc	a0,0x3
ffffffffc02031e2:	42a50513          	addi	a0,a0,1066 # ffffffffc0206608 <etext+0xe74>
ffffffffc02031e6:	a60fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02031ea:	00003697          	auipc	a3,0x3
ffffffffc02031ee:	66e68693          	addi	a3,a3,1646 # ffffffffc0206858 <etext+0x10c4>
ffffffffc02031f2:	00003617          	auipc	a2,0x3
ffffffffc02031f6:	f7660613          	addi	a2,a2,-138 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02031fa:	21c00593          	li	a1,540
ffffffffc02031fe:	00003517          	auipc	a0,0x3
ffffffffc0203202:	40a50513          	addi	a0,a0,1034 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203206:	a40fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020320a:	00003697          	auipc	a3,0x3
ffffffffc020320e:	6be68693          	addi	a3,a3,1726 # ffffffffc02068c8 <etext+0x1134>
ffffffffc0203212:	00003617          	auipc	a2,0x3
ffffffffc0203216:	f5660613          	addi	a2,a2,-170 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020321a:	22000593          	li	a1,544
ffffffffc020321e:	00003517          	auipc	a0,0x3
ffffffffc0203222:	3ea50513          	addi	a0,a0,1002 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203226:	a20fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020322a:	00003697          	auipc	a3,0x3
ffffffffc020322e:	65e68693          	addi	a3,a3,1630 # ffffffffc0206888 <etext+0x10f4>
ffffffffc0203232:	00003617          	auipc	a2,0x3
ffffffffc0203236:	f3660613          	addi	a2,a2,-202 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020323a:	21f00593          	li	a1,543
ffffffffc020323e:	00003517          	auipc	a0,0x3
ffffffffc0203242:	3ca50513          	addi	a0,a0,970 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203246:	a00fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020324a:	86d6                	mv	a3,s5
ffffffffc020324c:	00003617          	auipc	a2,0x3
ffffffffc0203250:	2cc60613          	addi	a2,a2,716 # ffffffffc0206518 <etext+0xd84>
ffffffffc0203254:	21b00593          	li	a1,539
ffffffffc0203258:	00003517          	auipc	a0,0x3
ffffffffc020325c:	3b050513          	addi	a0,a0,944 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203260:	9e6fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203264:	00003617          	auipc	a2,0x3
ffffffffc0203268:	2b460613          	addi	a2,a2,692 # ffffffffc0206518 <etext+0xd84>
ffffffffc020326c:	21a00593          	li	a1,538
ffffffffc0203270:	00003517          	auipc	a0,0x3
ffffffffc0203274:	39850513          	addi	a0,a0,920 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203278:	9cefd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020327c:	00003697          	auipc	a3,0x3
ffffffffc0203280:	5c468693          	addi	a3,a3,1476 # ffffffffc0206840 <etext+0x10ac>
ffffffffc0203284:	00003617          	auipc	a2,0x3
ffffffffc0203288:	ee460613          	addi	a2,a2,-284 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020328c:	21800593          	li	a1,536
ffffffffc0203290:	00003517          	auipc	a0,0x3
ffffffffc0203294:	37850513          	addi	a0,a0,888 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203298:	9aefd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020329c:	00003697          	auipc	a3,0x3
ffffffffc02032a0:	58c68693          	addi	a3,a3,1420 # ffffffffc0206828 <etext+0x1094>
ffffffffc02032a4:	00003617          	auipc	a2,0x3
ffffffffc02032a8:	ec460613          	addi	a2,a2,-316 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02032ac:	21700593          	li	a1,535
ffffffffc02032b0:	00003517          	auipc	a0,0x3
ffffffffc02032b4:	35850513          	addi	a0,a0,856 # ffffffffc0206608 <etext+0xe74>
ffffffffc02032b8:	98efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032bc:	00004697          	auipc	a3,0x4
ffffffffc02032c0:	91c68693          	addi	a3,a3,-1764 # ffffffffc0206bd8 <etext+0x1444>
ffffffffc02032c4:	00003617          	auipc	a2,0x3
ffffffffc02032c8:	ea460613          	addi	a2,a2,-348 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02032cc:	25e00593          	li	a1,606
ffffffffc02032d0:	00003517          	auipc	a0,0x3
ffffffffc02032d4:	33850513          	addi	a0,a0,824 # ffffffffc0206608 <etext+0xe74>
ffffffffc02032d8:	96efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032dc:	00004697          	auipc	a3,0x4
ffffffffc02032e0:	8c468693          	addi	a3,a3,-1852 # ffffffffc0206ba0 <etext+0x140c>
ffffffffc02032e4:	00003617          	auipc	a2,0x3
ffffffffc02032e8:	e8460613          	addi	a2,a2,-380 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02032ec:	25b00593          	li	a1,603
ffffffffc02032f0:	00003517          	auipc	a0,0x3
ffffffffc02032f4:	31850513          	addi	a0,a0,792 # ffffffffc0206608 <etext+0xe74>
ffffffffc02032f8:	94efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032fc:	00004697          	auipc	a3,0x4
ffffffffc0203300:	87468693          	addi	a3,a3,-1932 # ffffffffc0206b70 <etext+0x13dc>
ffffffffc0203304:	00003617          	auipc	a2,0x3
ffffffffc0203308:	e6460613          	addi	a2,a2,-412 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020330c:	25700593          	li	a1,599
ffffffffc0203310:	00003517          	auipc	a0,0x3
ffffffffc0203314:	2f850513          	addi	a0,a0,760 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203318:	92efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020331c:	00004697          	auipc	a3,0x4
ffffffffc0203320:	80c68693          	addi	a3,a3,-2036 # ffffffffc0206b28 <etext+0x1394>
ffffffffc0203324:	00003617          	auipc	a2,0x3
ffffffffc0203328:	e4460613          	addi	a2,a2,-444 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020332c:	25600593          	li	a1,598
ffffffffc0203330:	00003517          	auipc	a0,0x3
ffffffffc0203334:	2d850513          	addi	a0,a0,728 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203338:	90efd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020333c:	00003697          	auipc	a3,0x3
ffffffffc0203340:	43468693          	addi	a3,a3,1076 # ffffffffc0206770 <etext+0xfdc>
ffffffffc0203344:	00003617          	auipc	a2,0x3
ffffffffc0203348:	e2460613          	addi	a2,a2,-476 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020334c:	20f00593          	li	a1,527
ffffffffc0203350:	00003517          	auipc	a0,0x3
ffffffffc0203354:	2b850513          	addi	a0,a0,696 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203358:	8eefd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020335c:	00003617          	auipc	a2,0x3
ffffffffc0203360:	26460613          	addi	a2,a2,612 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc0203364:	0c900593          	li	a1,201
ffffffffc0203368:	00003517          	auipc	a0,0x3
ffffffffc020336c:	2a050513          	addi	a0,a0,672 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203370:	8d6fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203374:	00003697          	auipc	a3,0x3
ffffffffc0203378:	45c68693          	addi	a3,a3,1116 # ffffffffc02067d0 <etext+0x103c>
ffffffffc020337c:	00003617          	auipc	a2,0x3
ffffffffc0203380:	dec60613          	addi	a2,a2,-532 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203384:	21600593          	li	a1,534
ffffffffc0203388:	00003517          	auipc	a0,0x3
ffffffffc020338c:	28050513          	addi	a0,a0,640 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203390:	8b6fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203394:	00003697          	auipc	a3,0x3
ffffffffc0203398:	40c68693          	addi	a3,a3,1036 # ffffffffc02067a0 <etext+0x100c>
ffffffffc020339c:	00003617          	auipc	a2,0x3
ffffffffc02033a0:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02033a4:	21300593          	li	a1,531
ffffffffc02033a8:	00003517          	auipc	a0,0x3
ffffffffc02033ac:	26050513          	addi	a0,a0,608 # ffffffffc0206608 <etext+0xe74>
ffffffffc02033b0:	896fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02033b4 <copy_range>:
{
ffffffffc02033b4:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033b6:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033ba:	f486                	sd	ra,104(sp)
ffffffffc02033bc:	f0a2                	sd	s0,96(sp)
ffffffffc02033be:	eca6                	sd	s1,88(sp)
ffffffffc02033c0:	e8ca                	sd	s2,80(sp)
ffffffffc02033c2:	e4ce                	sd	s3,72(sp)
ffffffffc02033c4:	e0d2                	sd	s4,64(sp)
ffffffffc02033c6:	fc56                	sd	s5,56(sp)
ffffffffc02033c8:	f85a                	sd	s6,48(sp)
ffffffffc02033ca:	f45e                	sd	s7,40(sp)
ffffffffc02033cc:	f062                	sd	s8,32(sp)
ffffffffc02033ce:	ec66                	sd	s9,24(sp)
ffffffffc02033d0:	e86a                	sd	s10,16(sp)
ffffffffc02033d2:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033d4:	03479713          	slli	a4,a5,0x34
ffffffffc02033d8:	20071f63          	bnez	a4,ffffffffc02035f6 <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc02033dc:	002007b7          	lui	a5,0x200
ffffffffc02033e0:	00d63733          	sltu	a4,a2,a3
ffffffffc02033e4:	00f637b3          	sltu	a5,a2,a5
ffffffffc02033e8:	00173713          	seqz	a4,a4
ffffffffc02033ec:	8fd9                	or	a5,a5,a4
ffffffffc02033ee:	8432                	mv	s0,a2
ffffffffc02033f0:	8936                	mv	s2,a3
ffffffffc02033f2:	1e079263          	bnez	a5,ffffffffc02035d6 <copy_range+0x222>
ffffffffc02033f6:	4785                	li	a5,1
ffffffffc02033f8:	07fe                	slli	a5,a5,0x1f
ffffffffc02033fa:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e29>
ffffffffc02033fc:	1cf6fd63          	bgeu	a3,a5,ffffffffc02035d6 <copy_range+0x222>
ffffffffc0203400:	5b7d                	li	s6,-1
ffffffffc0203402:	8baa                	mv	s7,a0
ffffffffc0203404:	8a2e                	mv	s4,a1
ffffffffc0203406:	6a85                	lui	s5,0x1
ffffffffc0203408:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc020340c:	00098c97          	auipc	s9,0x98
ffffffffc0203410:	394c8c93          	addi	s9,s9,916 # ffffffffc029b7a0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203414:	00098c17          	auipc	s8,0x98
ffffffffc0203418:	394c0c13          	addi	s8,s8,916 # ffffffffc029b7a8 <pages>
ffffffffc020341c:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203420:	4601                	li	a2,0
ffffffffc0203422:	85a2                	mv	a1,s0
ffffffffc0203424:	8552                	mv	a0,s4
ffffffffc0203426:	b19fe0ef          	jal	ffffffffc0201f3e <get_pte>
ffffffffc020342a:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020342c:	0e050a63          	beqz	a0,ffffffffc0203520 <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc0203430:	611c                	ld	a5,0(a0)
ffffffffc0203432:	8b85                	andi	a5,a5,1
ffffffffc0203434:	e78d                	bnez	a5,ffffffffc020345e <copy_range+0xaa>
        start += PGSIZE;
ffffffffc0203436:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0203438:	c019                	beqz	s0,ffffffffc020343e <copy_range+0x8a>
ffffffffc020343a:	ff2463e3          	bltu	s0,s2,ffffffffc0203420 <copy_range+0x6c>
    return 0;
ffffffffc020343e:	4501                	li	a0,0
}
ffffffffc0203440:	70a6                	ld	ra,104(sp)
ffffffffc0203442:	7406                	ld	s0,96(sp)
ffffffffc0203444:	64e6                	ld	s1,88(sp)
ffffffffc0203446:	6946                	ld	s2,80(sp)
ffffffffc0203448:	69a6                	ld	s3,72(sp)
ffffffffc020344a:	6a06                	ld	s4,64(sp)
ffffffffc020344c:	7ae2                	ld	s5,56(sp)
ffffffffc020344e:	7b42                	ld	s6,48(sp)
ffffffffc0203450:	7ba2                	ld	s7,40(sp)
ffffffffc0203452:	7c02                	ld	s8,32(sp)
ffffffffc0203454:	6ce2                	ld	s9,24(sp)
ffffffffc0203456:	6d42                	ld	s10,16(sp)
ffffffffc0203458:	6da2                	ld	s11,8(sp)
ffffffffc020345a:	6165                	addi	sp,sp,112
ffffffffc020345c:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc020345e:	4605                	li	a2,1
ffffffffc0203460:	85a2                	mv	a1,s0
ffffffffc0203462:	855e                	mv	a0,s7
ffffffffc0203464:	adbfe0ef          	jal	ffffffffc0201f3e <get_pte>
ffffffffc0203468:	c165                	beqz	a0,ffffffffc0203548 <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020346a:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc020346e:	0019f793          	andi	a5,s3,1
ffffffffc0203472:	14078663          	beqz	a5,ffffffffc02035be <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc0203476:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020347a:	00299793          	slli	a5,s3,0x2
ffffffffc020347e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203480:	12e7f363          	bgeu	a5,a4,ffffffffc02035a6 <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc0203484:	000c3483          	ld	s1,0(s8)
ffffffffc0203488:	97ea                	add	a5,a5,s10
ffffffffc020348a:	079a                	slli	a5,a5,0x6
ffffffffc020348c:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020348e:	100027f3          	csrr	a5,sstatus
ffffffffc0203492:	8b89                	andi	a5,a5,2
ffffffffc0203494:	efc9                	bnez	a5,ffffffffc020352e <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203496:	00098797          	auipc	a5,0x98
ffffffffc020349a:	2ea7b783          	ld	a5,746(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc020349e:	4505                	li	a0,1
ffffffffc02034a0:	6f9c                	ld	a5,24(a5)
ffffffffc02034a2:	9782                	jalr	a5
ffffffffc02034a4:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc02034a6:	c0e5                	beqz	s1,ffffffffc0203586 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc02034a8:	0a0d8f63          	beqz	s11,ffffffffc0203566 <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc02034ac:	000c3783          	ld	a5,0(s8)
ffffffffc02034b0:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc02034b4:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc02034b8:	40f486b3          	sub	a3,s1,a5
ffffffffc02034bc:	8699                	srai	a3,a3,0x6
ffffffffc02034be:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02034c0:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034c4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034c6:	08e5f463          	bgeu	a1,a4,ffffffffc020354e <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc02034ca:	40fd87b3          	sub	a5,s11,a5
ffffffffc02034ce:	8799                	srai	a5,a5,0x6
ffffffffc02034d0:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc02034d2:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034d6:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034d8:	06e67a63          	bgeu	a2,a4,ffffffffc020354c <copy_range+0x198>
ffffffffc02034dc:	00098517          	auipc	a0,0x98
ffffffffc02034e0:	2bc53503          	ld	a0,700(a0) # ffffffffc029b798 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034e4:	6605                	lui	a2,0x1
ffffffffc02034e6:	00a685b3          	add	a1,a3,a0
ffffffffc02034ea:	953e                	add	a0,a0,a5
ffffffffc02034ec:	290020ef          	jal	ffffffffc020577c <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034f0:	01f9f693          	andi	a3,s3,31
ffffffffc02034f4:	85ee                	mv	a1,s11
ffffffffc02034f6:	8622                	mv	a2,s0
ffffffffc02034f8:	855e                	mv	a0,s7
ffffffffc02034fa:	97aff0ef          	jal	ffffffffc0202674 <page_insert>
            assert(ret == 0);
ffffffffc02034fe:	dd05                	beqz	a0,ffffffffc0203436 <copy_range+0x82>
ffffffffc0203500:	00003697          	auipc	a3,0x3
ffffffffc0203504:	74068693          	addi	a3,a3,1856 # ffffffffc0206c40 <etext+0x14ac>
ffffffffc0203508:	00003617          	auipc	a2,0x3
ffffffffc020350c:	c6060613          	addi	a2,a2,-928 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203510:	1ab00593          	li	a1,427
ffffffffc0203514:	00003517          	auipc	a0,0x3
ffffffffc0203518:	0f450513          	addi	a0,a0,244 # ffffffffc0206608 <etext+0xe74>
ffffffffc020351c:	f2bfc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203520:	002007b7          	lui	a5,0x200
ffffffffc0203524:	97a2                	add	a5,a5,s0
ffffffffc0203526:	ffe00437          	lui	s0,0xffe00
ffffffffc020352a:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc020352c:	b731                	j	ffffffffc0203438 <copy_range+0x84>
        intr_disable();
ffffffffc020352e:	bd6fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203532:	00098797          	auipc	a5,0x98
ffffffffc0203536:	24e7b783          	ld	a5,590(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc020353a:	4505                	li	a0,1
ffffffffc020353c:	6f9c                	ld	a5,24(a5)
ffffffffc020353e:	9782                	jalr	a5
ffffffffc0203540:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc0203542:	bbcfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0203546:	b785                	j	ffffffffc02034a6 <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc0203548:	5571                	li	a0,-4
ffffffffc020354a:	bddd                	j	ffffffffc0203440 <copy_range+0x8c>
ffffffffc020354c:	86be                	mv	a3,a5
ffffffffc020354e:	00003617          	auipc	a2,0x3
ffffffffc0203552:	fca60613          	addi	a2,a2,-54 # ffffffffc0206518 <etext+0xd84>
ffffffffc0203556:	07100593          	li	a1,113
ffffffffc020355a:	00003517          	auipc	a0,0x3
ffffffffc020355e:	fe650513          	addi	a0,a0,-26 # ffffffffc0206540 <etext+0xdac>
ffffffffc0203562:	ee5fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(npage != NULL);
ffffffffc0203566:	00003697          	auipc	a3,0x3
ffffffffc020356a:	6ca68693          	addi	a3,a3,1738 # ffffffffc0206c30 <etext+0x149c>
ffffffffc020356e:	00003617          	auipc	a2,0x3
ffffffffc0203572:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203576:	19e00593          	li	a1,414
ffffffffc020357a:	00003517          	auipc	a0,0x3
ffffffffc020357e:	08e50513          	addi	a0,a0,142 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203582:	ec5fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(page != NULL);
ffffffffc0203586:	00003697          	auipc	a3,0x3
ffffffffc020358a:	69a68693          	addi	a3,a3,1690 # ffffffffc0206c20 <etext+0x148c>
ffffffffc020358e:	00003617          	auipc	a2,0x3
ffffffffc0203592:	bda60613          	addi	a2,a2,-1062 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203596:	19d00593          	li	a1,413
ffffffffc020359a:	00003517          	auipc	a0,0x3
ffffffffc020359e:	06e50513          	addi	a0,a0,110 # ffffffffc0206608 <etext+0xe74>
ffffffffc02035a2:	ea5fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02035a6:	00003617          	auipc	a2,0x3
ffffffffc02035aa:	04260613          	addi	a2,a2,66 # ffffffffc02065e8 <etext+0xe54>
ffffffffc02035ae:	06900593          	li	a1,105
ffffffffc02035b2:	00003517          	auipc	a0,0x3
ffffffffc02035b6:	f8e50513          	addi	a0,a0,-114 # ffffffffc0206540 <etext+0xdac>
ffffffffc02035ba:	e8dfc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035be:	00003617          	auipc	a2,0x3
ffffffffc02035c2:	24260613          	addi	a2,a2,578 # ffffffffc0206800 <etext+0x106c>
ffffffffc02035c6:	07f00593          	li	a1,127
ffffffffc02035ca:	00003517          	auipc	a0,0x3
ffffffffc02035ce:	f7650513          	addi	a0,a0,-138 # ffffffffc0206540 <etext+0xdac>
ffffffffc02035d2:	e75fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02035d6:	00003697          	auipc	a3,0x3
ffffffffc02035da:	07268693          	addi	a3,a3,114 # ffffffffc0206648 <etext+0xeb4>
ffffffffc02035de:	00003617          	auipc	a2,0x3
ffffffffc02035e2:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02035e6:	18500593          	li	a1,389
ffffffffc02035ea:	00003517          	auipc	a0,0x3
ffffffffc02035ee:	01e50513          	addi	a0,a0,30 # ffffffffc0206608 <etext+0xe74>
ffffffffc02035f2:	e55fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035f6:	00003697          	auipc	a3,0x3
ffffffffc02035fa:	02268693          	addi	a3,a3,34 # ffffffffc0206618 <etext+0xe84>
ffffffffc02035fe:	00003617          	auipc	a2,0x3
ffffffffc0203602:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203606:	18400593          	li	a1,388
ffffffffc020360a:	00003517          	auipc	a0,0x3
ffffffffc020360e:	ffe50513          	addi	a0,a0,-2 # ffffffffc0206608 <etext+0xe74>
ffffffffc0203612:	e35fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203616 <pgdir_alloc_page>:
{
ffffffffc0203616:	7139                	addi	sp,sp,-64
ffffffffc0203618:	f426                	sd	s1,40(sp)
ffffffffc020361a:	f04a                	sd	s2,32(sp)
ffffffffc020361c:	ec4e                	sd	s3,24(sp)
ffffffffc020361e:	fc06                	sd	ra,56(sp)
ffffffffc0203620:	f822                	sd	s0,48(sp)
ffffffffc0203622:	892a                	mv	s2,a0
ffffffffc0203624:	84ae                	mv	s1,a1
ffffffffc0203626:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203628:	100027f3          	csrr	a5,sstatus
ffffffffc020362c:	8b89                	andi	a5,a5,2
ffffffffc020362e:	ebb5                	bnez	a5,ffffffffc02036a2 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203630:	00098417          	auipc	s0,0x98
ffffffffc0203634:	15040413          	addi	s0,s0,336 # ffffffffc029b780 <pmm_manager>
ffffffffc0203638:	601c                	ld	a5,0(s0)
ffffffffc020363a:	4505                	li	a0,1
ffffffffc020363c:	6f9c                	ld	a5,24(a5)
ffffffffc020363e:	9782                	jalr	a5
ffffffffc0203640:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc0203642:	c5b9                	beqz	a1,ffffffffc0203690 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203644:	86ce                	mv	a3,s3
ffffffffc0203646:	854a                	mv	a0,s2
ffffffffc0203648:	8626                	mv	a2,s1
ffffffffc020364a:	e42e                	sd	a1,8(sp)
ffffffffc020364c:	828ff0ef          	jal	ffffffffc0202674 <page_insert>
ffffffffc0203650:	65a2                	ld	a1,8(sp)
ffffffffc0203652:	e515                	bnez	a0,ffffffffc020367e <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc0203654:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc0203656:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc0203658:	4785                	li	a5,1
ffffffffc020365a:	02f70c63          	beq	a4,a5,ffffffffc0203692 <pgdir_alloc_page+0x7c>
ffffffffc020365e:	00003697          	auipc	a3,0x3
ffffffffc0203662:	5f268693          	addi	a3,a3,1522 # ffffffffc0206c50 <etext+0x14bc>
ffffffffc0203666:	00003617          	auipc	a2,0x3
ffffffffc020366a:	b0260613          	addi	a2,a2,-1278 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020366e:	1f400593          	li	a1,500
ffffffffc0203672:	00003517          	auipc	a0,0x3
ffffffffc0203676:	f9650513          	addi	a0,a0,-106 # ffffffffc0206608 <etext+0xe74>
ffffffffc020367a:	dcdfc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020367e:	100027f3          	csrr	a5,sstatus
ffffffffc0203682:	8b89                	andi	a5,a5,2
ffffffffc0203684:	ef95                	bnez	a5,ffffffffc02036c0 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc0203686:	601c                	ld	a5,0(s0)
ffffffffc0203688:	852e                	mv	a0,a1
ffffffffc020368a:	4585                	li	a1,1
ffffffffc020368c:	739c                	ld	a5,32(a5)
ffffffffc020368e:	9782                	jalr	a5
            return NULL;
ffffffffc0203690:	4581                	li	a1,0
}
ffffffffc0203692:	70e2                	ld	ra,56(sp)
ffffffffc0203694:	7442                	ld	s0,48(sp)
ffffffffc0203696:	74a2                	ld	s1,40(sp)
ffffffffc0203698:	7902                	ld	s2,32(sp)
ffffffffc020369a:	69e2                	ld	s3,24(sp)
ffffffffc020369c:	852e                	mv	a0,a1
ffffffffc020369e:	6121                	addi	sp,sp,64
ffffffffc02036a0:	8082                	ret
        intr_disable();
ffffffffc02036a2:	a62fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036a6:	00098417          	auipc	s0,0x98
ffffffffc02036aa:	0da40413          	addi	s0,s0,218 # ffffffffc029b780 <pmm_manager>
ffffffffc02036ae:	601c                	ld	a5,0(s0)
ffffffffc02036b0:	4505                	li	a0,1
ffffffffc02036b2:	6f9c                	ld	a5,24(a5)
ffffffffc02036b4:	9782                	jalr	a5
ffffffffc02036b6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02036b8:	a46fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036bc:	65a2                	ld	a1,8(sp)
ffffffffc02036be:	b751                	j	ffffffffc0203642 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc02036c0:	a44fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02036c4:	601c                	ld	a5,0(s0)
ffffffffc02036c6:	6522                	ld	a0,8(sp)
ffffffffc02036c8:	4585                	li	a1,1
ffffffffc02036ca:	739c                	ld	a5,32(a5)
ffffffffc02036cc:	9782                	jalr	a5
        intr_enable();
ffffffffc02036ce:	a30fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036d2:	bf7d                	j	ffffffffc0203690 <pgdir_alloc_page+0x7a>

ffffffffc02036d4 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036d4:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02036d6:	00003697          	auipc	a3,0x3
ffffffffc02036da:	59268693          	addi	a3,a3,1426 # ffffffffc0206c68 <etext+0x14d4>
ffffffffc02036de:	00003617          	auipc	a2,0x3
ffffffffc02036e2:	a8a60613          	addi	a2,a2,-1398 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02036e6:	07400593          	li	a1,116
ffffffffc02036ea:	00003517          	auipc	a0,0x3
ffffffffc02036ee:	59e50513          	addi	a0,a0,1438 # ffffffffc0206c88 <etext+0x14f4>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036f2:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036f4:	d53fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02036f8 <mm_create>:
{
ffffffffc02036f8:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036fa:	04000513          	li	a0,64
{
ffffffffc02036fe:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203700:	dd4fe0ef          	jal	ffffffffc0201cd4 <kmalloc>
    if (mm != NULL)
ffffffffc0203704:	cd19                	beqz	a0,ffffffffc0203722 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203706:	e508                	sd	a0,8(a0)
ffffffffc0203708:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020370a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020370e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203712:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203716:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020371a:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020371e:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203722:	60a2                	ld	ra,8(sp)
ffffffffc0203724:	0141                	addi	sp,sp,16
ffffffffc0203726:	8082                	ret

ffffffffc0203728 <find_vma>:
    if (mm != NULL)
ffffffffc0203728:	c505                	beqz	a0,ffffffffc0203750 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc020372a:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020372c:	c781                	beqz	a5,ffffffffc0203734 <find_vma+0xc>
ffffffffc020372e:	6798                	ld	a4,8(a5)
ffffffffc0203730:	02e5f363          	bgeu	a1,a4,ffffffffc0203756 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203734:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0203736:	00f50d63          	beq	a0,a5,ffffffffc0203750 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020373a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020373e:	00e5e663          	bltu	a1,a4,ffffffffc020374a <find_vma+0x22>
ffffffffc0203742:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203746:	00e5ee63          	bltu	a1,a4,ffffffffc0203762 <find_vma+0x3a>
ffffffffc020374a:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020374c:	fef517e3          	bne	a0,a5,ffffffffc020373a <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0203750:	4781                	li	a5,0
}
ffffffffc0203752:	853e                	mv	a0,a5
ffffffffc0203754:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203756:	6b98                	ld	a4,16(a5)
ffffffffc0203758:	fce5fee3          	bgeu	a1,a4,ffffffffc0203734 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020375c:	e91c                	sd	a5,16(a0)
}
ffffffffc020375e:	853e                	mv	a0,a5
ffffffffc0203760:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203762:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203764:	e91c                	sd	a5,16(a0)
ffffffffc0203766:	bfe5                	j	ffffffffc020375e <find_vma+0x36>

ffffffffc0203768 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203768:	6590                	ld	a2,8(a1)
ffffffffc020376a:	0105b803          	ld	a6,16(a1)
{
ffffffffc020376e:	1141                	addi	sp,sp,-16
ffffffffc0203770:	e406                	sd	ra,8(sp)
ffffffffc0203772:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203774:	01066763          	bltu	a2,a6,ffffffffc0203782 <insert_vma_struct+0x1a>
ffffffffc0203778:	a8b9                	j	ffffffffc02037d6 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020377a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020377e:	04e66763          	bltu	a2,a4,ffffffffc02037cc <insert_vma_struct+0x64>
ffffffffc0203782:	86be                	mv	a3,a5
ffffffffc0203784:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203786:	fef51ae3          	bne	a0,a5,ffffffffc020377a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020378a:	02a68463          	beq	a3,a0,ffffffffc02037b2 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020378e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203792:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203796:	08e8f063          	bgeu	a7,a4,ffffffffc0203816 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020379a:	04e66e63          	bltu	a2,a4,ffffffffc02037f6 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc020379e:	00f50a63          	beq	a0,a5,ffffffffc02037b2 <insert_vma_struct+0x4a>
ffffffffc02037a2:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037a6:	05076863          	bltu	a4,a6,ffffffffc02037f6 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02037aa:	ff07b603          	ld	a2,-16(a5)
ffffffffc02037ae:	02c77263          	bgeu	a4,a2,ffffffffc02037d2 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02037b2:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02037b4:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02037b6:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02037ba:	e390                	sd	a2,0(a5)
ffffffffc02037bc:	e690                	sd	a2,8(a3)
}
ffffffffc02037be:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02037c0:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02037c2:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02037c4:	2705                	addiw	a4,a4,1
ffffffffc02037c6:	d118                	sw	a4,32(a0)
}
ffffffffc02037c8:	0141                	addi	sp,sp,16
ffffffffc02037ca:	8082                	ret
    if (le_prev != list)
ffffffffc02037cc:	fca691e3          	bne	a3,a0,ffffffffc020378e <insert_vma_struct+0x26>
ffffffffc02037d0:	bfd9                	j	ffffffffc02037a6 <insert_vma_struct+0x3e>
ffffffffc02037d2:	f03ff0ef          	jal	ffffffffc02036d4 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037d6:	00003697          	auipc	a3,0x3
ffffffffc02037da:	4c268693          	addi	a3,a3,1218 # ffffffffc0206c98 <etext+0x1504>
ffffffffc02037de:	00003617          	auipc	a2,0x3
ffffffffc02037e2:	98a60613          	addi	a2,a2,-1654 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02037e6:	07a00593          	li	a1,122
ffffffffc02037ea:	00003517          	auipc	a0,0x3
ffffffffc02037ee:	49e50513          	addi	a0,a0,1182 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc02037f2:	c55fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037f6:	00003697          	auipc	a3,0x3
ffffffffc02037fa:	4e268693          	addi	a3,a3,1250 # ffffffffc0206cd8 <etext+0x1544>
ffffffffc02037fe:	00003617          	auipc	a2,0x3
ffffffffc0203802:	96a60613          	addi	a2,a2,-1686 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203806:	07300593          	li	a1,115
ffffffffc020380a:	00003517          	auipc	a0,0x3
ffffffffc020380e:	47e50513          	addi	a0,a0,1150 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203812:	c35fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203816:	00003697          	auipc	a3,0x3
ffffffffc020381a:	4a268693          	addi	a3,a3,1186 # ffffffffc0206cb8 <etext+0x1524>
ffffffffc020381e:	00003617          	auipc	a2,0x3
ffffffffc0203822:	94a60613          	addi	a2,a2,-1718 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203826:	07200593          	li	a1,114
ffffffffc020382a:	00003517          	auipc	a0,0x3
ffffffffc020382e:	45e50513          	addi	a0,a0,1118 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203832:	c15fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203836 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203836:	591c                	lw	a5,48(a0)
{
ffffffffc0203838:	1141                	addi	sp,sp,-16
ffffffffc020383a:	e406                	sd	ra,8(sp)
ffffffffc020383c:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020383e:	e78d                	bnez	a5,ffffffffc0203868 <mm_destroy+0x32>
ffffffffc0203840:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203842:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203844:	00a40c63          	beq	s0,a0,ffffffffc020385c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203848:	6118                	ld	a4,0(a0)
ffffffffc020384a:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020384c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020384e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203850:	e398                	sd	a4,0(a5)
ffffffffc0203852:	d28fe0ef          	jal	ffffffffc0201d7a <kfree>
    return listelm->next;
ffffffffc0203856:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203858:	fea418e3          	bne	s0,a0,ffffffffc0203848 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020385c:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020385e:	6402                	ld	s0,0(sp)
ffffffffc0203860:	60a2                	ld	ra,8(sp)
ffffffffc0203862:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203864:	d16fe06f          	j	ffffffffc0201d7a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203868:	00003697          	auipc	a3,0x3
ffffffffc020386c:	49068693          	addi	a3,a3,1168 # ffffffffc0206cf8 <etext+0x1564>
ffffffffc0203870:	00003617          	auipc	a2,0x3
ffffffffc0203874:	8f860613          	addi	a2,a2,-1800 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203878:	09e00593          	li	a1,158
ffffffffc020387c:	00003517          	auipc	a0,0x3
ffffffffc0203880:	40c50513          	addi	a0,a0,1036 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203884:	bc3fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203888 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203888:	6785                	lui	a5,0x1
ffffffffc020388a:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7bd1>
ffffffffc020388c:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc020388e:	4785                	li	a5,1
{
ffffffffc0203890:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203892:	962e                	add	a2,a2,a1
ffffffffc0203894:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc0203896:	07fe                	slli	a5,a5,0x1f
{
ffffffffc0203898:	f822                	sd	s0,48(sp)
ffffffffc020389a:	f426                	sd	s1,40(sp)
ffffffffc020389c:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038a0:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02038a4:	0785                	addi	a5,a5,1
ffffffffc02038a6:	0084b633          	sltu	a2,s1,s0
ffffffffc02038aa:	00f437b3          	sltu	a5,s0,a5
ffffffffc02038ae:	00163613          	seqz	a2,a2
ffffffffc02038b2:	0017b793          	seqz	a5,a5
{
ffffffffc02038b6:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02038b8:	8fd1                	or	a5,a5,a2
ffffffffc02038ba:	ebbd                	bnez	a5,ffffffffc0203930 <mm_map+0xa8>
ffffffffc02038bc:	002007b7          	lui	a5,0x200
ffffffffc02038c0:	06f4e863          	bltu	s1,a5,ffffffffc0203930 <mm_map+0xa8>
ffffffffc02038c4:	f04a                	sd	s2,32(sp)
ffffffffc02038c6:	ec4e                	sd	s3,24(sp)
ffffffffc02038c8:	e852                	sd	s4,16(sp)
ffffffffc02038ca:	892a                	mv	s2,a0
ffffffffc02038cc:	89ba                	mv	s3,a4
ffffffffc02038ce:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02038d0:	c135                	beqz	a0,ffffffffc0203934 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02038d2:	85a6                	mv	a1,s1
ffffffffc02038d4:	e55ff0ef          	jal	ffffffffc0203728 <find_vma>
ffffffffc02038d8:	c501                	beqz	a0,ffffffffc02038e0 <mm_map+0x58>
ffffffffc02038da:	651c                	ld	a5,8(a0)
ffffffffc02038dc:	0487e763          	bltu	a5,s0,ffffffffc020392a <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038e0:	03000513          	li	a0,48
ffffffffc02038e4:	bf0fe0ef          	jal	ffffffffc0201cd4 <kmalloc>
ffffffffc02038e8:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02038ea:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02038ec:	c59d                	beqz	a1,ffffffffc020391a <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc02038ee:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc02038f0:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02038f2:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02038f6:	854a                	mv	a0,s2
ffffffffc02038f8:	e42e                	sd	a1,8(sp)
ffffffffc02038fa:	e6fff0ef          	jal	ffffffffc0203768 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc02038fe:	65a2                	ld	a1,8(sp)
ffffffffc0203900:	00098463          	beqz	s3,ffffffffc0203908 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203904:	00b9b023          	sd	a1,0(s3)
ffffffffc0203908:	7902                	ld	s2,32(sp)
ffffffffc020390a:	69e2                	ld	s3,24(sp)
ffffffffc020390c:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc020390e:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0203910:	70e2                	ld	ra,56(sp)
ffffffffc0203912:	7442                	ld	s0,48(sp)
ffffffffc0203914:	74a2                	ld	s1,40(sp)
ffffffffc0203916:	6121                	addi	sp,sp,64
ffffffffc0203918:	8082                	ret
ffffffffc020391a:	70e2                	ld	ra,56(sp)
ffffffffc020391c:	7442                	ld	s0,48(sp)
ffffffffc020391e:	7902                	ld	s2,32(sp)
ffffffffc0203920:	69e2                	ld	s3,24(sp)
ffffffffc0203922:	6a42                	ld	s4,16(sp)
ffffffffc0203924:	74a2                	ld	s1,40(sp)
ffffffffc0203926:	6121                	addi	sp,sp,64
ffffffffc0203928:	8082                	ret
ffffffffc020392a:	7902                	ld	s2,32(sp)
ffffffffc020392c:	69e2                	ld	s3,24(sp)
ffffffffc020392e:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc0203930:	5575                	li	a0,-3
ffffffffc0203932:	bff9                	j	ffffffffc0203910 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203934:	00003697          	auipc	a3,0x3
ffffffffc0203938:	3dc68693          	addi	a3,a3,988 # ffffffffc0206d10 <etext+0x157c>
ffffffffc020393c:	00003617          	auipc	a2,0x3
ffffffffc0203940:	82c60613          	addi	a2,a2,-2004 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203944:	0b300593          	li	a1,179
ffffffffc0203948:	00003517          	auipc	a0,0x3
ffffffffc020394c:	34050513          	addi	a0,a0,832 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203950:	af7fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203954 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203954:	7139                	addi	sp,sp,-64
ffffffffc0203956:	fc06                	sd	ra,56(sp)
ffffffffc0203958:	f822                	sd	s0,48(sp)
ffffffffc020395a:	f426                	sd	s1,40(sp)
ffffffffc020395c:	f04a                	sd	s2,32(sp)
ffffffffc020395e:	ec4e                	sd	s3,24(sp)
ffffffffc0203960:	e852                	sd	s4,16(sp)
ffffffffc0203962:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203964:	c525                	beqz	a0,ffffffffc02039cc <dup_mmap+0x78>
ffffffffc0203966:	892a                	mv	s2,a0
ffffffffc0203968:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020396a:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc020396c:	c1a5                	beqz	a1,ffffffffc02039cc <dup_mmap+0x78>
    return listelm->prev;
ffffffffc020396e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203970:	04848c63          	beq	s1,s0,ffffffffc02039c8 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203974:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203978:	fe843a83          	ld	s5,-24(s0)
ffffffffc020397c:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203980:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203984:	b50fe0ef          	jal	ffffffffc0201cd4 <kmalloc>
    if (vma != NULL)
ffffffffc0203988:	c515                	beqz	a0,ffffffffc02039b4 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020398a:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc020398c:	01553423          	sd	s5,8(a0)
ffffffffc0203990:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203994:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc0203998:	854a                	mv	a0,s2
ffffffffc020399a:	dcfff0ef          	jal	ffffffffc0203768 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020399e:	ff043683          	ld	a3,-16(s0)
ffffffffc02039a2:	fe843603          	ld	a2,-24(s0)
ffffffffc02039a6:	6c8c                	ld	a1,24(s1)
ffffffffc02039a8:	01893503          	ld	a0,24(s2)
ffffffffc02039ac:	4701                	li	a4,0
ffffffffc02039ae:	a07ff0ef          	jal	ffffffffc02033b4 <copy_range>
ffffffffc02039b2:	dd55                	beqz	a0,ffffffffc020396e <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc02039b4:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02039b6:	70e2                	ld	ra,56(sp)
ffffffffc02039b8:	7442                	ld	s0,48(sp)
ffffffffc02039ba:	74a2                	ld	s1,40(sp)
ffffffffc02039bc:	7902                	ld	s2,32(sp)
ffffffffc02039be:	69e2                	ld	s3,24(sp)
ffffffffc02039c0:	6a42                	ld	s4,16(sp)
ffffffffc02039c2:	6aa2                	ld	s5,8(sp)
ffffffffc02039c4:	6121                	addi	sp,sp,64
ffffffffc02039c6:	8082                	ret
    return 0;
ffffffffc02039c8:	4501                	li	a0,0
ffffffffc02039ca:	b7f5                	j	ffffffffc02039b6 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc02039cc:	00003697          	auipc	a3,0x3
ffffffffc02039d0:	35468693          	addi	a3,a3,852 # ffffffffc0206d20 <etext+0x158c>
ffffffffc02039d4:	00002617          	auipc	a2,0x2
ffffffffc02039d8:	79460613          	addi	a2,a2,1940 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02039dc:	0cf00593          	li	a1,207
ffffffffc02039e0:	00003517          	auipc	a0,0x3
ffffffffc02039e4:	2a850513          	addi	a0,a0,680 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc02039e8:	a5ffc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02039ec <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02039ec:	1101                	addi	sp,sp,-32
ffffffffc02039ee:	ec06                	sd	ra,24(sp)
ffffffffc02039f0:	e822                	sd	s0,16(sp)
ffffffffc02039f2:	e426                	sd	s1,8(sp)
ffffffffc02039f4:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039f6:	c531                	beqz	a0,ffffffffc0203a42 <exit_mmap+0x56>
ffffffffc02039f8:	591c                	lw	a5,48(a0)
ffffffffc02039fa:	84aa                	mv	s1,a0
ffffffffc02039fc:	e3b9                	bnez	a5,ffffffffc0203a42 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02039fe:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a00:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a04:	02850663          	beq	a0,s0,ffffffffc0203a30 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a08:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a0c:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a10:	854a                	mv	a0,s2
ffffffffc0203a12:	fdefe0ef          	jal	ffffffffc02021f0 <unmap_range>
ffffffffc0203a16:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a18:	fe8498e3          	bne	s1,s0,ffffffffc0203a08 <exit_mmap+0x1c>
ffffffffc0203a1c:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a1e:	00848c63          	beq	s1,s0,ffffffffc0203a36 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a22:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a26:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a2a:	854a                	mv	a0,s2
ffffffffc0203a2c:	8f9fe0ef          	jal	ffffffffc0202324 <exit_range>
ffffffffc0203a30:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a32:	fe8498e3          	bne	s1,s0,ffffffffc0203a22 <exit_mmap+0x36>
    }
}
ffffffffc0203a36:	60e2                	ld	ra,24(sp)
ffffffffc0203a38:	6442                	ld	s0,16(sp)
ffffffffc0203a3a:	64a2                	ld	s1,8(sp)
ffffffffc0203a3c:	6902                	ld	s2,0(sp)
ffffffffc0203a3e:	6105                	addi	sp,sp,32
ffffffffc0203a40:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a42:	00003697          	auipc	a3,0x3
ffffffffc0203a46:	2fe68693          	addi	a3,a3,766 # ffffffffc0206d40 <etext+0x15ac>
ffffffffc0203a4a:	00002617          	auipc	a2,0x2
ffffffffc0203a4e:	71e60613          	addi	a2,a2,1822 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203a52:	0e800593          	li	a1,232
ffffffffc0203a56:	00003517          	auipc	a0,0x3
ffffffffc0203a5a:	23250513          	addi	a0,a0,562 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203a5e:	9e9fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a62 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a62:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a64:	04000513          	li	a0,64
{
ffffffffc0203a68:	f406                	sd	ra,40(sp)
ffffffffc0203a6a:	f022                	sd	s0,32(sp)
ffffffffc0203a6c:	ec26                	sd	s1,24(sp)
ffffffffc0203a6e:	e84a                	sd	s2,16(sp)
ffffffffc0203a70:	e44e                	sd	s3,8(sp)
ffffffffc0203a72:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a74:	a60fe0ef          	jal	ffffffffc0201cd4 <kmalloc>
    if (mm != NULL)
ffffffffc0203a78:	16050c63          	beqz	a0,ffffffffc0203bf0 <vmm_init+0x18e>
ffffffffc0203a7c:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203a7e:	e508                	sd	a0,8(a0)
ffffffffc0203a80:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a82:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a86:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a8a:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a8e:	02053423          	sd	zero,40(a0)
ffffffffc0203a92:	02052823          	sw	zero,48(a0)
ffffffffc0203a96:	02053c23          	sd	zero,56(a0)
ffffffffc0203a9a:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a9e:	03000513          	li	a0,48
ffffffffc0203aa2:	a32fe0ef          	jal	ffffffffc0201cd4 <kmalloc>
    if (vma != NULL)
ffffffffc0203aa6:	12050563          	beqz	a0,ffffffffc0203bd0 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203aaa:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203aae:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203ab0:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203ab4:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ab6:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203ab8:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203aba:	8522                	mv	a0,s0
ffffffffc0203abc:	cadff0ef          	jal	ffffffffc0203768 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203ac0:	fcf9                	bnez	s1,ffffffffc0203a9e <vmm_init+0x3c>
ffffffffc0203ac2:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ac6:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aca:	03000513          	li	a0,48
ffffffffc0203ace:	a06fe0ef          	jal	ffffffffc0201cd4 <kmalloc>
    if (vma != NULL)
ffffffffc0203ad2:	12050f63          	beqz	a0,ffffffffc0203c10 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203ad6:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203ada:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203adc:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203ae0:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ae2:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ae4:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203ae6:	8522                	mv	a0,s0
ffffffffc0203ae8:	c81ff0ef          	jal	ffffffffc0203768 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203aec:	fd249fe3          	bne	s1,s2,ffffffffc0203aca <vmm_init+0x68>
    return listelm->next;
ffffffffc0203af0:	641c                	ld	a5,8(s0)
ffffffffc0203af2:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203af4:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203af8:	1ef40c63          	beq	s0,a5,ffffffffc0203cf0 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203afc:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f5e10>
ffffffffc0203b00:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b04:	12d61663          	bne	a2,a3,ffffffffc0203c30 <vmm_init+0x1ce>
ffffffffc0203b08:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b0c:	12e69263          	bne	a3,a4,ffffffffc0203c30 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203b10:	0715                	addi	a4,a4,5
ffffffffc0203b12:	679c                	ld	a5,8(a5)
ffffffffc0203b14:	feb712e3          	bne	a4,a1,ffffffffc0203af8 <vmm_init+0x96>
ffffffffc0203b18:	491d                	li	s2,7
ffffffffc0203b1a:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b1c:	85a6                	mv	a1,s1
ffffffffc0203b1e:	8522                	mv	a0,s0
ffffffffc0203b20:	c09ff0ef          	jal	ffffffffc0203728 <find_vma>
ffffffffc0203b24:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b26:	20050563          	beqz	a0,ffffffffc0203d30 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b2a:	00148593          	addi	a1,s1,1
ffffffffc0203b2e:	8522                	mv	a0,s0
ffffffffc0203b30:	bf9ff0ef          	jal	ffffffffc0203728 <find_vma>
ffffffffc0203b34:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b36:	1c050d63          	beqz	a0,ffffffffc0203d10 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b3a:	85ca                	mv	a1,s2
ffffffffc0203b3c:	8522                	mv	a0,s0
ffffffffc0203b3e:	bebff0ef          	jal	ffffffffc0203728 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b42:	18051763          	bnez	a0,ffffffffc0203cd0 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b46:	00348593          	addi	a1,s1,3
ffffffffc0203b4a:	8522                	mv	a0,s0
ffffffffc0203b4c:	bddff0ef          	jal	ffffffffc0203728 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b50:	16051063          	bnez	a0,ffffffffc0203cb0 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b54:	00448593          	addi	a1,s1,4
ffffffffc0203b58:	8522                	mv	a0,s0
ffffffffc0203b5a:	bcfff0ef          	jal	ffffffffc0203728 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b5e:	12051963          	bnez	a0,ffffffffc0203c90 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b62:	008a3783          	ld	a5,8(s4)
ffffffffc0203b66:	10979563          	bne	a5,s1,ffffffffc0203c70 <vmm_init+0x20e>
ffffffffc0203b6a:	010a3783          	ld	a5,16(s4)
ffffffffc0203b6e:	11279163          	bne	a5,s2,ffffffffc0203c70 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b72:	0089b783          	ld	a5,8(s3)
ffffffffc0203b76:	0c979d63          	bne	a5,s1,ffffffffc0203c50 <vmm_init+0x1ee>
ffffffffc0203b7a:	0109b783          	ld	a5,16(s3)
ffffffffc0203b7e:	0d279963          	bne	a5,s2,ffffffffc0203c50 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b82:	0495                	addi	s1,s1,5
ffffffffc0203b84:	1f900793          	li	a5,505
ffffffffc0203b88:	0915                	addi	s2,s2,5
ffffffffc0203b8a:	f8f499e3          	bne	s1,a5,ffffffffc0203b1c <vmm_init+0xba>
ffffffffc0203b8e:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b90:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b92:	85a6                	mv	a1,s1
ffffffffc0203b94:	8522                	mv	a0,s0
ffffffffc0203b96:	b93ff0ef          	jal	ffffffffc0203728 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203b9a:	1a051b63          	bnez	a0,ffffffffc0203d50 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203b9e:	14fd                	addi	s1,s1,-1
ffffffffc0203ba0:	ff2499e3          	bne	s1,s2,ffffffffc0203b92 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203ba4:	8522                	mv	a0,s0
ffffffffc0203ba6:	c91ff0ef          	jal	ffffffffc0203836 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203baa:	00003517          	auipc	a0,0x3
ffffffffc0203bae:	30650513          	addi	a0,a0,774 # ffffffffc0206eb0 <etext+0x171c>
ffffffffc0203bb2:	de2fc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203bb6:	7402                	ld	s0,32(sp)
ffffffffc0203bb8:	70a2                	ld	ra,40(sp)
ffffffffc0203bba:	64e2                	ld	s1,24(sp)
ffffffffc0203bbc:	6942                	ld	s2,16(sp)
ffffffffc0203bbe:	69a2                	ld	s3,8(sp)
ffffffffc0203bc0:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bc2:	00003517          	auipc	a0,0x3
ffffffffc0203bc6:	30e50513          	addi	a0,a0,782 # ffffffffc0206ed0 <etext+0x173c>
}
ffffffffc0203bca:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bcc:	dc8fc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203bd0:	00003697          	auipc	a3,0x3
ffffffffc0203bd4:	19068693          	addi	a3,a3,400 # ffffffffc0206d60 <etext+0x15cc>
ffffffffc0203bd8:	00002617          	auipc	a2,0x2
ffffffffc0203bdc:	59060613          	addi	a2,a2,1424 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203be0:	12c00593          	li	a1,300
ffffffffc0203be4:	00003517          	auipc	a0,0x3
ffffffffc0203be8:	0a450513          	addi	a0,a0,164 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203bec:	85bfc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203bf0:	00003697          	auipc	a3,0x3
ffffffffc0203bf4:	12068693          	addi	a3,a3,288 # ffffffffc0206d10 <etext+0x157c>
ffffffffc0203bf8:	00002617          	auipc	a2,0x2
ffffffffc0203bfc:	57060613          	addi	a2,a2,1392 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203c00:	12400593          	li	a1,292
ffffffffc0203c04:	00003517          	auipc	a0,0x3
ffffffffc0203c08:	08450513          	addi	a0,a0,132 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203c0c:	83bfc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203c10:	00003697          	auipc	a3,0x3
ffffffffc0203c14:	15068693          	addi	a3,a3,336 # ffffffffc0206d60 <etext+0x15cc>
ffffffffc0203c18:	00002617          	auipc	a2,0x2
ffffffffc0203c1c:	55060613          	addi	a2,a2,1360 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203c20:	13300593          	li	a1,307
ffffffffc0203c24:	00003517          	auipc	a0,0x3
ffffffffc0203c28:	06450513          	addi	a0,a0,100 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203c2c:	81bfc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c30:	00003697          	auipc	a3,0x3
ffffffffc0203c34:	15868693          	addi	a3,a3,344 # ffffffffc0206d88 <etext+0x15f4>
ffffffffc0203c38:	00002617          	auipc	a2,0x2
ffffffffc0203c3c:	53060613          	addi	a2,a2,1328 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203c40:	13d00593          	li	a1,317
ffffffffc0203c44:	00003517          	auipc	a0,0x3
ffffffffc0203c48:	04450513          	addi	a0,a0,68 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203c4c:	ffafc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c50:	00003697          	auipc	a3,0x3
ffffffffc0203c54:	1f068693          	addi	a3,a3,496 # ffffffffc0206e40 <etext+0x16ac>
ffffffffc0203c58:	00002617          	auipc	a2,0x2
ffffffffc0203c5c:	51060613          	addi	a2,a2,1296 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203c60:	14f00593          	li	a1,335
ffffffffc0203c64:	00003517          	auipc	a0,0x3
ffffffffc0203c68:	02450513          	addi	a0,a0,36 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203c6c:	fdafc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c70:	00003697          	auipc	a3,0x3
ffffffffc0203c74:	1a068693          	addi	a3,a3,416 # ffffffffc0206e10 <etext+0x167c>
ffffffffc0203c78:	00002617          	auipc	a2,0x2
ffffffffc0203c7c:	4f060613          	addi	a2,a2,1264 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203c80:	14e00593          	li	a1,334
ffffffffc0203c84:	00003517          	auipc	a0,0x3
ffffffffc0203c88:	00450513          	addi	a0,a0,4 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203c8c:	fbafc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203c90:	00003697          	auipc	a3,0x3
ffffffffc0203c94:	17068693          	addi	a3,a3,368 # ffffffffc0206e00 <etext+0x166c>
ffffffffc0203c98:	00002617          	auipc	a2,0x2
ffffffffc0203c9c:	4d060613          	addi	a2,a2,1232 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203ca0:	14c00593          	li	a1,332
ffffffffc0203ca4:	00003517          	auipc	a0,0x3
ffffffffc0203ca8:	fe450513          	addi	a0,a0,-28 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203cac:	f9afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203cb0:	00003697          	auipc	a3,0x3
ffffffffc0203cb4:	14068693          	addi	a3,a3,320 # ffffffffc0206df0 <etext+0x165c>
ffffffffc0203cb8:	00002617          	auipc	a2,0x2
ffffffffc0203cbc:	4b060613          	addi	a2,a2,1200 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203cc0:	14a00593          	li	a1,330
ffffffffc0203cc4:	00003517          	auipc	a0,0x3
ffffffffc0203cc8:	fc450513          	addi	a0,a0,-60 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203ccc:	f7afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203cd0:	00003697          	auipc	a3,0x3
ffffffffc0203cd4:	11068693          	addi	a3,a3,272 # ffffffffc0206de0 <etext+0x164c>
ffffffffc0203cd8:	00002617          	auipc	a2,0x2
ffffffffc0203cdc:	49060613          	addi	a2,a2,1168 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203ce0:	14800593          	li	a1,328
ffffffffc0203ce4:	00003517          	auipc	a0,0x3
ffffffffc0203ce8:	fa450513          	addi	a0,a0,-92 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203cec:	f5afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203cf0:	00003697          	auipc	a3,0x3
ffffffffc0203cf4:	08068693          	addi	a3,a3,128 # ffffffffc0206d70 <etext+0x15dc>
ffffffffc0203cf8:	00002617          	auipc	a2,0x2
ffffffffc0203cfc:	47060613          	addi	a2,a2,1136 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203d00:	13b00593          	li	a1,315
ffffffffc0203d04:	00003517          	auipc	a0,0x3
ffffffffc0203d08:	f8450513          	addi	a0,a0,-124 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203d0c:	f3afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203d10:	00003697          	auipc	a3,0x3
ffffffffc0203d14:	0c068693          	addi	a3,a3,192 # ffffffffc0206dd0 <etext+0x163c>
ffffffffc0203d18:	00002617          	auipc	a2,0x2
ffffffffc0203d1c:	45060613          	addi	a2,a2,1104 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203d20:	14600593          	li	a1,326
ffffffffc0203d24:	00003517          	auipc	a0,0x3
ffffffffc0203d28:	f6450513          	addi	a0,a0,-156 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203d2c:	f1afc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203d30:	00003697          	auipc	a3,0x3
ffffffffc0203d34:	09068693          	addi	a3,a3,144 # ffffffffc0206dc0 <etext+0x162c>
ffffffffc0203d38:	00002617          	auipc	a2,0x2
ffffffffc0203d3c:	43060613          	addi	a2,a2,1072 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203d40:	14400593          	li	a1,324
ffffffffc0203d44:	00003517          	auipc	a0,0x3
ffffffffc0203d48:	f4450513          	addi	a0,a0,-188 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203d4c:	efafc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d50:	6914                	ld	a3,16(a0)
ffffffffc0203d52:	6510                	ld	a2,8(a0)
ffffffffc0203d54:	0004859b          	sext.w	a1,s1
ffffffffc0203d58:	00003517          	auipc	a0,0x3
ffffffffc0203d5c:	11850513          	addi	a0,a0,280 # ffffffffc0206e70 <etext+0x16dc>
ffffffffc0203d60:	c34fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203d64:	00003697          	auipc	a3,0x3
ffffffffc0203d68:	13468693          	addi	a3,a3,308 # ffffffffc0206e98 <etext+0x1704>
ffffffffc0203d6c:	00002617          	auipc	a2,0x2
ffffffffc0203d70:	3fc60613          	addi	a2,a2,1020 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0203d74:	15900593          	li	a1,345
ffffffffc0203d78:	00003517          	auipc	a0,0x3
ffffffffc0203d7c:	f1050513          	addi	a0,a0,-240 # ffffffffc0206c88 <etext+0x14f4>
ffffffffc0203d80:	ec6fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203d84 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d84:	7179                	addi	sp,sp,-48
ffffffffc0203d86:	f022                	sd	s0,32(sp)
ffffffffc0203d88:	f406                	sd	ra,40(sp)
ffffffffc0203d8a:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d8c:	c52d                	beqz	a0,ffffffffc0203df6 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d8e:	002007b7          	lui	a5,0x200
ffffffffc0203d92:	04f5ed63          	bltu	a1,a5,ffffffffc0203dec <user_mem_check+0x68>
ffffffffc0203d96:	ec26                	sd	s1,24(sp)
ffffffffc0203d98:	00c584b3          	add	s1,a1,a2
ffffffffc0203d9c:	0695ff63          	bgeu	a1,s1,ffffffffc0203e1a <user_mem_check+0x96>
ffffffffc0203da0:	4785                	li	a5,1
ffffffffc0203da2:	07fe                	slli	a5,a5,0x1f
ffffffffc0203da4:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e29>
ffffffffc0203da6:	06f4fa63          	bgeu	s1,a5,ffffffffc0203e1a <user_mem_check+0x96>
ffffffffc0203daa:	e84a                	sd	s2,16(sp)
ffffffffc0203dac:	e44e                	sd	s3,8(sp)
ffffffffc0203dae:	8936                	mv	s2,a3
ffffffffc0203db0:	89aa                	mv	s3,a0
ffffffffc0203db2:	a829                	j	ffffffffc0203dcc <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203db4:	6685                	lui	a3,0x1
ffffffffc0203db6:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203db8:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dbc:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dbe:	c685                	beqz	a3,ffffffffc0203de6 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dc0:	c399                	beqz	a5,ffffffffc0203dc6 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203dc2:	02e46263          	bltu	s0,a4,ffffffffc0203de6 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203dc6:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203dc8:	04947b63          	bgeu	s0,s1,ffffffffc0203e1e <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203dcc:	85a2                	mv	a1,s0
ffffffffc0203dce:	854e                	mv	a0,s3
ffffffffc0203dd0:	959ff0ef          	jal	ffffffffc0203728 <find_vma>
ffffffffc0203dd4:	c909                	beqz	a0,ffffffffc0203de6 <user_mem_check+0x62>
ffffffffc0203dd6:	6518                	ld	a4,8(a0)
ffffffffc0203dd8:	00e46763          	bltu	s0,a4,ffffffffc0203de6 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203ddc:	4d1c                	lw	a5,24(a0)
ffffffffc0203dde:	fc091be3          	bnez	s2,ffffffffc0203db4 <user_mem_check+0x30>
ffffffffc0203de2:	8b85                	andi	a5,a5,1
ffffffffc0203de4:	f3ed                	bnez	a5,ffffffffc0203dc6 <user_mem_check+0x42>
ffffffffc0203de6:	64e2                	ld	s1,24(sp)
ffffffffc0203de8:	6942                	ld	s2,16(sp)
ffffffffc0203dea:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203dec:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203dee:	70a2                	ld	ra,40(sp)
ffffffffc0203df0:	7402                	ld	s0,32(sp)
ffffffffc0203df2:	6145                	addi	sp,sp,48
ffffffffc0203df4:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203df6:	c02007b7          	lui	a5,0xc0200
ffffffffc0203dfa:	fef5eae3          	bltu	a1,a5,ffffffffc0203dee <user_mem_check+0x6a>
ffffffffc0203dfe:	c80007b7          	lui	a5,0xc8000
ffffffffc0203e02:	962e                	add	a2,a2,a1
ffffffffc0203e04:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d64831>
ffffffffc0203e06:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203e0a:	00f63633          	sltu	a2,a2,a5
ffffffffc0203e0e:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e10:	00867533          	and	a0,a2,s0
ffffffffc0203e14:	7402                	ld	s0,32(sp)
ffffffffc0203e16:	6145                	addi	sp,sp,48
ffffffffc0203e18:	8082                	ret
ffffffffc0203e1a:	64e2                	ld	s1,24(sp)
ffffffffc0203e1c:	bfc1                	j	ffffffffc0203dec <user_mem_check+0x68>
ffffffffc0203e1e:	64e2                	ld	s1,24(sp)
ffffffffc0203e20:	6942                	ld	s2,16(sp)
ffffffffc0203e22:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203e24:	4505                	li	a0,1
ffffffffc0203e26:	b7e1                	j	ffffffffc0203dee <user_mem_check+0x6a>

ffffffffc0203e28 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e28:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e2a:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e2c:	5e0000ef          	jal	ffffffffc020440c <do_exit>

ffffffffc0203e30 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e30:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e32:	10800513          	li	a0,264
{
ffffffffc0203e36:	e022                	sd	s0,0(sp)
ffffffffc0203e38:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e3a:	e9bfd0ef          	jal	ffffffffc0201cd4 <kmalloc>
ffffffffc0203e3e:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203e40:	cd21                	beqz	a0,ffffffffc0203e98 <alloc_proc+0x68>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        // 初始化进程状态为未初始化
        proc->state = PROC_UNINIT;
ffffffffc0203e42:	57fd                	li	a5,-1
ffffffffc0203e44:	1782                	slli	a5,a5,0x20
ffffffffc0203e46:	e11c                	sd	a5,0(a0)
        // 初始化进程ID为-1（无效ID）
        proc->pid = -1;
        // 初始化运行次数为0
        proc->runs = 0;
ffffffffc0203e48:	00052423          	sw	zero,8(a0)
        // 初始化内核栈地址为0
        proc->kstack = 0;
ffffffffc0203e4c:	00053823          	sd	zero,16(a0)
        // 初始化不需要重新调度
        proc->need_resched = 0;
ffffffffc0203e50:	00053c23          	sd	zero,24(a0)
        // 初始化父进程指针为NULL
        proc->parent = NULL;
ffffffffc0203e54:	02053023          	sd	zero,32(a0)
        // 初始化内存管理结构为NULL
        proc->mm = NULL;
ffffffffc0203e58:	02053423          	sd	zero,40(a0)
        // 初始化上下文结构体（全部设为0）
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203e5c:	07000613          	li	a2,112
ffffffffc0203e60:	4581                	li	a1,0
ffffffffc0203e62:	03050513          	addi	a0,a0,48
ffffffffc0203e66:	105010ef          	jal	ffffffffc020576a <memset>
        // 初始化陷阱帧指针为NULL
        proc->tf = NULL;
        // 初始化页目录基址为boot_pgdir
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203e6a:	00098797          	auipc	a5,0x98
ffffffffc0203e6e:	91e7b783          	ld	a5,-1762(a5) # ffffffffc029b788 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc0203e72:	0a043023          	sd	zero,160(s0)
        // 初始化标志位为0
        proc->flags = 0;
ffffffffc0203e76:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203e7a:	f45c                	sd	a5,168(s0)
        // 初始化进程名称为空字符串
        memset(proc->name, 0, PROC_NAME_LEN + 1); 
ffffffffc0203e7c:	0b440513          	addi	a0,s0,180
ffffffffc0203e80:	4641                	li	a2,16
ffffffffc0203e82:	4581                	li	a1,0
ffffffffc0203e84:	0e7010ef          	jal	ffffffffc020576a <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0; 
ffffffffc0203e88:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;  
ffffffffc0203e8c:	10043023          	sd	zero,256(s0)
ffffffffc0203e90:	0e043c23          	sd	zero,248(s0)
ffffffffc0203e94:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0203e98:	60a2                	ld	ra,8(sp)
ffffffffc0203e9a:	8522                	mv	a0,s0
ffffffffc0203e9c:	6402                	ld	s0,0(sp)
ffffffffc0203e9e:	0141                	addi	sp,sp,16
ffffffffc0203ea0:	8082                	ret

ffffffffc0203ea2 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203ea2:	00098797          	auipc	a5,0x98
ffffffffc0203ea6:	9167b783          	ld	a5,-1770(a5) # ffffffffc029b7b8 <current>
ffffffffc0203eaa:	73c8                	ld	a0,160(a5)
ffffffffc0203eac:	80efd06f          	j	ffffffffc0200eba <forkrets>

ffffffffc0203eb0 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eb0:	00098797          	auipc	a5,0x98
ffffffffc0203eb4:	9087b783          	ld	a5,-1784(a5) # ffffffffc029b7b8 <current>
{
ffffffffc0203eb8:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eba:	00003617          	auipc	a2,0x3
ffffffffc0203ebe:	02e60613          	addi	a2,a2,46 # ffffffffc0206ee8 <etext+0x1754>
ffffffffc0203ec2:	43cc                	lw	a1,4(a5)
ffffffffc0203ec4:	00003517          	auipc	a0,0x3
ffffffffc0203ec8:	03450513          	addi	a0,a0,52 # ffffffffc0206ef8 <etext+0x1764>
{
ffffffffc0203ecc:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203ece:	ac6fc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0203ed2:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203ed6:	a1e78793          	addi	a5,a5,-1506 # 98f0 <_binary_obj___user_forktest_out_size>
ffffffffc0203eda:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc0203edc:	00003517          	auipc	a0,0x3
ffffffffc0203ee0:	00c50513          	addi	a0,a0,12 # ffffffffc0206ee8 <etext+0x1754>
ffffffffc0203ee4:	0003f797          	auipc	a5,0x3f
ffffffffc0203ee8:	7c478793          	addi	a5,a5,1988 # ffffffffc02436a8 <_binary_obj___user_forktest_out_start>
ffffffffc0203eec:	f03e                	sd	a5,32(sp)
ffffffffc0203eee:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203ef0:	e802                	sd	zero,16(sp)
ffffffffc0203ef2:	7c4010ef          	jal	ffffffffc02056b6 <strlen>
ffffffffc0203ef6:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203ef8:	4511                	li	a0,4
ffffffffc0203efa:	55a2                	lw	a1,40(sp)
ffffffffc0203efc:	4662                	lw	a2,24(sp)
ffffffffc0203efe:	5682                	lw	a3,32(sp)
ffffffffc0203f00:	4722                	lw	a4,8(sp)
ffffffffc0203f02:	48a9                	li	a7,10
ffffffffc0203f04:	9002                	ebreak
ffffffffc0203f06:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203f08:	65c2                	ld	a1,16(sp)
ffffffffc0203f0a:	00003517          	auipc	a0,0x3
ffffffffc0203f0e:	01650513          	addi	a0,a0,22 # ffffffffc0206f20 <etext+0x178c>
ffffffffc0203f12:	a82fc0ef          	jal	ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203f16:	00003617          	auipc	a2,0x3
ffffffffc0203f1a:	01a60613          	addi	a2,a2,26 # ffffffffc0206f30 <etext+0x179c>
ffffffffc0203f1e:	3be00593          	li	a1,958
ffffffffc0203f22:	00003517          	auipc	a0,0x3
ffffffffc0203f26:	02e50513          	addi	a0,a0,46 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0203f2a:	d1cfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203f2e <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f2e:	6d14                	ld	a3,24(a0)
{
ffffffffc0203f30:	1141                	addi	sp,sp,-16
ffffffffc0203f32:	e406                	sd	ra,8(sp)
ffffffffc0203f34:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f38:	02f6ee63          	bltu	a3,a5,ffffffffc0203f74 <put_pgdir+0x46>
ffffffffc0203f3c:	00098717          	auipc	a4,0x98
ffffffffc0203f40:	85c73703          	ld	a4,-1956(a4) # ffffffffc029b798 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203f44:	00098797          	auipc	a5,0x98
ffffffffc0203f48:	85c7b783          	ld	a5,-1956(a5) # ffffffffc029b7a0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203f4c:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203f4e:	82b1                	srli	a3,a3,0xc
ffffffffc0203f50:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f8c <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f54:	00004797          	auipc	a5,0x4
ffffffffc0203f58:	9847b783          	ld	a5,-1660(a5) # ffffffffc02078d8 <nbase>
ffffffffc0203f5c:	00098517          	auipc	a0,0x98
ffffffffc0203f60:	84c53503          	ld	a0,-1972(a0) # ffffffffc029b7a8 <pages>
}
ffffffffc0203f64:	60a2                	ld	ra,8(sp)
ffffffffc0203f66:	8e9d                	sub	a3,a3,a5
ffffffffc0203f68:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f6a:	4585                	li	a1,1
ffffffffc0203f6c:	9536                	add	a0,a0,a3
}
ffffffffc0203f6e:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f70:	f61fd06f          	j	ffffffffc0201ed0 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f74:	00002617          	auipc	a2,0x2
ffffffffc0203f78:	64c60613          	addi	a2,a2,1612 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc0203f7c:	07700593          	li	a1,119
ffffffffc0203f80:	00002517          	auipc	a0,0x2
ffffffffc0203f84:	5c050513          	addi	a0,a0,1472 # ffffffffc0206540 <etext+0xdac>
ffffffffc0203f88:	cbefc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f8c:	00002617          	auipc	a2,0x2
ffffffffc0203f90:	65c60613          	addi	a2,a2,1628 # ffffffffc02065e8 <etext+0xe54>
ffffffffc0203f94:	06900593          	li	a1,105
ffffffffc0203f98:	00002517          	auipc	a0,0x2
ffffffffc0203f9c:	5a850513          	addi	a0,a0,1448 # ffffffffc0206540 <etext+0xdac>
ffffffffc0203fa0:	ca6fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203fa4 <proc_run>:
    if (proc != current)
ffffffffc0203fa4:	00098697          	auipc	a3,0x98
ffffffffc0203fa8:	8146b683          	ld	a3,-2028(a3) # ffffffffc029b7b8 <current>
ffffffffc0203fac:	04a68463          	beq	a3,a0,ffffffffc0203ff4 <proc_run+0x50>
{
ffffffffc0203fb0:	1101                	addi	sp,sp,-32
ffffffffc0203fb2:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fb4:	100027f3          	csrr	a5,sstatus
ffffffffc0203fb8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203fba:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fbc:	ef8d                	bnez	a5,ffffffffc0203ff6 <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fbe:	755c                	ld	a5,168(a0)
ffffffffc0203fc0:	577d                	li	a4,-1
ffffffffc0203fc2:	177e                	slli	a4,a4,0x3f
ffffffffc0203fc4:	83b1                	srli	a5,a5,0xc
ffffffffc0203fc6:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc0203fc8:	00097597          	auipc	a1,0x97
ffffffffc0203fcc:	7ea5b823          	sd	a0,2032(a1) # ffffffffc029b7b8 <current>
ffffffffc0203fd0:	8fd9                	or	a5,a5,a4
ffffffffc0203fd2:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203fd6:	03050593          	addi	a1,a0,48
ffffffffc0203fda:	03068513          	addi	a0,a3,48
ffffffffc0203fde:	090010ef          	jal	ffffffffc020506e <switch_to>
    if (flag)
ffffffffc0203fe2:	6602                	ld	a2,0(sp)
ffffffffc0203fe4:	e601                	bnez	a2,ffffffffc0203fec <proc_run+0x48>
}
ffffffffc0203fe6:	60e2                	ld	ra,24(sp)
ffffffffc0203fe8:	6105                	addi	sp,sp,32
ffffffffc0203fea:	8082                	ret
ffffffffc0203fec:	60e2                	ld	ra,24(sp)
ffffffffc0203fee:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203ff0:	90ffc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0203ff4:	8082                	ret
ffffffffc0203ff6:	e42a                	sd	a0,8(sp)
ffffffffc0203ff8:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc0203ffa:	90bfc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0203ffe:	6522                	ld	a0,8(sp)
ffffffffc0204000:	6682                	ld	a3,0(sp)
ffffffffc0204002:	4605                	li	a2,1
ffffffffc0204004:	bf6d                	j	ffffffffc0203fbe <proc_run+0x1a>

ffffffffc0204006 <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc0204006:	00097797          	auipc	a5,0x97
ffffffffc020400a:	7aa7a783          	lw	a5,1962(a5) # ffffffffc029b7b0 <nr_process>
{
ffffffffc020400e:	7159                	addi	sp,sp,-112
ffffffffc0204010:	e4ce                	sd	s3,72(sp)
ffffffffc0204012:	f486                	sd	ra,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204014:	6985                	lui	s3,0x1
ffffffffc0204016:	3337d463          	bge	a5,s3,ffffffffc020433e <do_fork+0x338>
ffffffffc020401a:	f0a2                	sd	s0,96(sp)
ffffffffc020401c:	eca6                	sd	s1,88(sp)
ffffffffc020401e:	e8ca                	sd	s2,80(sp)
ffffffffc0204020:	e86a                	sd	s10,16(sp)
ffffffffc0204022:	892e                	mv	s2,a1
ffffffffc0204024:	84b2                	mv	s1,a2
ffffffffc0204026:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL){
ffffffffc0204028:	e09ff0ef          	jal	ffffffffc0203e30 <alloc_proc>
ffffffffc020402c:	842a                	mv	s0,a0
ffffffffc020402e:	2e050463          	beqz	a0,ffffffffc0204316 <do_fork+0x310>
ffffffffc0204032:	f45e                	sd	s7,40(sp)
    proc->parent = current;
ffffffffc0204034:	00097b97          	auipc	s7,0x97
ffffffffc0204038:	784b8b93          	addi	s7,s7,1924 # ffffffffc029b7b8 <current>
ffffffffc020403c:	000bb783          	ld	a5,0(s7)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204040:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0204042:	f01c                	sd	a5,32(s0)
    current->wait_state = 0; // set current process's wait_state is 0
ffffffffc0204044:	0e07a623          	sw	zero,236(a5)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204048:	e4ffd0ef          	jal	ffffffffc0201e96 <alloc_pages>
    if (page != NULL)
ffffffffc020404c:	2c050163          	beqz	a0,ffffffffc020430e <do_fork+0x308>
ffffffffc0204050:	e0d2                	sd	s4,64(sp)
    return page - pages + nbase;
ffffffffc0204052:	00097a17          	auipc	s4,0x97
ffffffffc0204056:	756a0a13          	addi	s4,s4,1878 # ffffffffc029b7a8 <pages>
ffffffffc020405a:	000a3783          	ld	a5,0(s4)
ffffffffc020405e:	fc56                	sd	s5,56(sp)
ffffffffc0204060:	00004a97          	auipc	s5,0x4
ffffffffc0204064:	878a8a93          	addi	s5,s5,-1928 # ffffffffc02078d8 <nbase>
ffffffffc0204068:	000ab703          	ld	a4,0(s5)
ffffffffc020406c:	40f506b3          	sub	a3,a0,a5
ffffffffc0204070:	f85a                	sd	s6,48(sp)
    return KADDR(page2pa(page));
ffffffffc0204072:	00097b17          	auipc	s6,0x97
ffffffffc0204076:	72eb0b13          	addi	s6,s6,1838 # ffffffffc029b7a0 <npage>
ffffffffc020407a:	ec66                	sd	s9,24(sp)
    return page - pages + nbase;
ffffffffc020407c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020407e:	5cfd                	li	s9,-1
ffffffffc0204080:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc0204084:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204086:	00ccdc93          	srli	s9,s9,0xc
ffffffffc020408a:	0196f633          	and	a2,a3,s9
ffffffffc020408e:	f062                	sd	s8,32(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0204090:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204092:	2cf67463          	bgeu	a2,a5,ffffffffc020435a <do_fork+0x354>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204096:	000bb603          	ld	a2,0(s7)
ffffffffc020409a:	00097b97          	auipc	s7,0x97
ffffffffc020409e:	6feb8b93          	addi	s7,s7,1790 # ffffffffc029b798 <va_pa_offset>
ffffffffc02040a2:	000bb783          	ld	a5,0(s7)
ffffffffc02040a6:	02863c03          	ld	s8,40(a2)
ffffffffc02040aa:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02040ac:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc02040ae:	020c0863          	beqz	s8,ffffffffc02040de <do_fork+0xd8>
    if (clone_flags & CLONE_VM)
ffffffffc02040b2:	100d7793          	andi	a5,s10,256
ffffffffc02040b6:	18078063          	beqz	a5,ffffffffc0204236 <do_fork+0x230>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02040ba:	030c2703          	lw	a4,48(s8)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040be:	018c3783          	ld	a5,24(s8)
ffffffffc02040c2:	c02006b7          	lui	a3,0xc0200
ffffffffc02040c6:	2705                	addiw	a4,a4,1
ffffffffc02040c8:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc02040cc:	03843423          	sd	s8,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040d0:	2ad7ed63          	bltu	a5,a3,ffffffffc020438a <do_fork+0x384>
ffffffffc02040d4:	000bb703          	ld	a4,0(s7)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040d8:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040da:	8f99                	sub	a5,a5,a4
ffffffffc02040dc:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040de:	6789                	lui	a5,0x2
ffffffffc02040e0:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6cf0>
ffffffffc02040e4:	96be                	add	a3,a3,a5
ffffffffc02040e6:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc02040e8:	87b6                	mv	a5,a3
ffffffffc02040ea:	12048713          	addi	a4,s1,288
ffffffffc02040ee:	6890                	ld	a2,16(s1)
ffffffffc02040f0:	6088                	ld	a0,0(s1)
ffffffffc02040f2:	648c                	ld	a1,8(s1)
ffffffffc02040f4:	eb90                	sd	a2,16(a5)
ffffffffc02040f6:	e388                	sd	a0,0(a5)
ffffffffc02040f8:	e78c                	sd	a1,8(a5)
ffffffffc02040fa:	6c90                	ld	a2,24(s1)
ffffffffc02040fc:	02048493          	addi	s1,s1,32
ffffffffc0204100:	02078793          	addi	a5,a5,32
ffffffffc0204104:	fec7bc23          	sd	a2,-8(a5)
ffffffffc0204108:	fee493e3          	bne	s1,a4,ffffffffc02040ee <do_fork+0xe8>
    proc->tf->gpr.a0 = 0;
ffffffffc020410c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204110:	20090963          	beqz	s2,ffffffffc0204322 <do_fork+0x31c>
    if (++last_pid >= MAX_PID)
ffffffffc0204114:	00093517          	auipc	a0,0x93
ffffffffc0204118:	20852503          	lw	a0,520(a0) # ffffffffc029731c <last_pid.1>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020411c:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204120:	00000797          	auipc	a5,0x0
ffffffffc0204124:	d8278793          	addi	a5,a5,-638 # ffffffffc0203ea2 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0204128:	2505                	addiw	a0,a0,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020412a:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020412c:	fc14                	sd	a3,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc020412e:	00093717          	auipc	a4,0x93
ffffffffc0204132:	1ea72723          	sw	a0,494(a4) # ffffffffc029731c <last_pid.1>
ffffffffc0204136:	6789                	lui	a5,0x2
ffffffffc0204138:	1ef55763          	bge	a0,a5,ffffffffc0204326 <do_fork+0x320>
    if (last_pid >= next_safe)
ffffffffc020413c:	00093797          	auipc	a5,0x93
ffffffffc0204140:	1dc7a783          	lw	a5,476(a5) # ffffffffc0297318 <next_safe.0>
ffffffffc0204144:	00097497          	auipc	s1,0x97
ffffffffc0204148:	5f448493          	addi	s1,s1,1524 # ffffffffc029b738 <proc_list>
ffffffffc020414c:	06f54563          	blt	a0,a5,ffffffffc02041b6 <do_fork+0x1b0>
ffffffffc0204150:	00097497          	auipc	s1,0x97
ffffffffc0204154:	5e848493          	addi	s1,s1,1512 # ffffffffc029b738 <proc_list>
ffffffffc0204158:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc020415c:	6789                	lui	a5,0x2
ffffffffc020415e:	00093717          	auipc	a4,0x93
ffffffffc0204162:	1af72d23          	sw	a5,442(a4) # ffffffffc0297318 <next_safe.0>
ffffffffc0204166:	86aa                	mv	a3,a0
ffffffffc0204168:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020416a:	04988063          	beq	a7,s1,ffffffffc02041aa <do_fork+0x1a4>
ffffffffc020416e:	882e                	mv	a6,a1
ffffffffc0204170:	87c6                	mv	a5,a7
ffffffffc0204172:	6609                	lui	a2,0x2
ffffffffc0204174:	a811                	j	ffffffffc0204188 <do_fork+0x182>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204176:	00e6d663          	bge	a3,a4,ffffffffc0204182 <do_fork+0x17c>
ffffffffc020417a:	00c75463          	bge	a4,a2,ffffffffc0204182 <do_fork+0x17c>
                next_safe = proc->pid;
ffffffffc020417e:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204180:	4805                	li	a6,1
ffffffffc0204182:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204184:	00978d63          	beq	a5,s1,ffffffffc020419e <do_fork+0x198>
            if (proc->pid == last_pid)
ffffffffc0204188:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6c94>
ffffffffc020418c:	fed715e3          	bne	a4,a3,ffffffffc0204176 <do_fork+0x170>
                if (++last_pid >= next_safe)
ffffffffc0204190:	2685                	addiw	a3,a3,1
ffffffffc0204192:	1ac6d063          	bge	a3,a2,ffffffffc0204332 <do_fork+0x32c>
ffffffffc0204196:	679c                	ld	a5,8(a5)
ffffffffc0204198:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020419a:	fe9797e3          	bne	a5,s1,ffffffffc0204188 <do_fork+0x182>
ffffffffc020419e:	00080663          	beqz	a6,ffffffffc02041aa <do_fork+0x1a4>
ffffffffc02041a2:	00093797          	auipc	a5,0x93
ffffffffc02041a6:	16c7ab23          	sw	a2,374(a5) # ffffffffc0297318 <next_safe.0>
ffffffffc02041aa:	c591                	beqz	a1,ffffffffc02041b6 <do_fork+0x1b0>
ffffffffc02041ac:	00093797          	auipc	a5,0x93
ffffffffc02041b0:	16d7a823          	sw	a3,368(a5) # ffffffffc029731c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041b4:	8536                	mv	a0,a3
    proc->pid = get_pid();
ffffffffc02041b6:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041b8:	45a9                	li	a1,10
ffffffffc02041ba:	11a010ef          	jal	ffffffffc02052d4 <hash32>
ffffffffc02041be:	02051793          	slli	a5,a0,0x20
ffffffffc02041c2:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041c6:	00093797          	auipc	a5,0x93
ffffffffc02041ca:	57278793          	addi	a5,a5,1394 # ffffffffc0297738 <hash_list>
ffffffffc02041ce:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02041d0:	6518                	ld	a4,8(a0)
ffffffffc02041d2:	0d840793          	addi	a5,s0,216
ffffffffc02041d6:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc02041d8:	e31c                	sd	a5,0(a4)
ffffffffc02041da:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02041dc:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02041de:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041e2:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc02041e4:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02041e6:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc02041e8:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041ec:	7b74                	ld	a3,240(a4)
ffffffffc02041ee:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc02041f0:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02041f2:	e464                	sd	s1,200(s0)
ffffffffc02041f4:	10d43023          	sd	a3,256(s0)
ffffffffc02041f8:	c299                	beqz	a3,ffffffffc02041fe <do_fork+0x1f8>
        proc->optr->yptr = proc;
ffffffffc02041fa:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc02041fc:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc02041fe:	00097797          	auipc	a5,0x97
ffffffffc0204202:	5b27a783          	lw	a5,1458(a5) # ffffffffc029b7b0 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204206:	fb60                	sd	s0,240(a4)
    wakeup_proc(proc);
ffffffffc0204208:	8522                	mv	a0,s0
    nr_process++;
ffffffffc020420a:	2785                	addiw	a5,a5,1
ffffffffc020420c:	00097717          	auipc	a4,0x97
ffffffffc0204210:	5af72223          	sw	a5,1444(a4) # ffffffffc029b7b0 <nr_process>
    wakeup_proc(proc);
ffffffffc0204214:	6c5000ef          	jal	ffffffffc02050d8 <wakeup_proc>
    ret = proc->pid;
ffffffffc0204218:	4048                	lw	a0,4(s0)
ffffffffc020421a:	64e6                	ld	s1,88(sp)
ffffffffc020421c:	7406                	ld	s0,96(sp)
ffffffffc020421e:	6946                	ld	s2,80(sp)
ffffffffc0204220:	6a06                	ld	s4,64(sp)
ffffffffc0204222:	7ae2                	ld	s5,56(sp)
ffffffffc0204224:	7b42                	ld	s6,48(sp)
ffffffffc0204226:	7ba2                	ld	s7,40(sp)
ffffffffc0204228:	7c02                	ld	s8,32(sp)
ffffffffc020422a:	6ce2                	ld	s9,24(sp)
ffffffffc020422c:	6d42                	ld	s10,16(sp)
}
ffffffffc020422e:	70a6                	ld	ra,104(sp)
ffffffffc0204230:	69a6                	ld	s3,72(sp)
ffffffffc0204232:	6165                	addi	sp,sp,112
ffffffffc0204234:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204236:	e43a                	sd	a4,8(sp)
ffffffffc0204238:	cc0ff0ef          	jal	ffffffffc02036f8 <mm_create>
ffffffffc020423c:	8d2a                	mv	s10,a0
ffffffffc020423e:	c959                	beqz	a0,ffffffffc02042d4 <do_fork+0x2ce>
    if ((page = alloc_page()) == NULL)
ffffffffc0204240:	4505                	li	a0,1
ffffffffc0204242:	c55fd0ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc0204246:	c541                	beqz	a0,ffffffffc02042ce <do_fork+0x2c8>
    return page - pages + nbase;
ffffffffc0204248:	000a3683          	ld	a3,0(s4)
ffffffffc020424c:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc020424e:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc0204252:	40d506b3          	sub	a3,a0,a3
ffffffffc0204256:	8699                	srai	a3,a3,0x6
ffffffffc0204258:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc020425a:	0196fcb3          	and	s9,a3,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc020425e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204260:	0efcfd63          	bgeu	s9,a5,ffffffffc020435a <do_fork+0x354>
ffffffffc0204264:	000bb783          	ld	a5,0(s7)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204268:	00097597          	auipc	a1,0x97
ffffffffc020426c:	5285b583          	ld	a1,1320(a1) # ffffffffc029b790 <boot_pgdir_va>
ffffffffc0204270:	864e                	mv	a2,s3
ffffffffc0204272:	00f689b3          	add	s3,a3,a5
ffffffffc0204276:	854e                	mv	a0,s3
ffffffffc0204278:	504010ef          	jal	ffffffffc020577c <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020427c:	038c0c93          	addi	s9,s8,56
    mm->pgdir = pgdir;
ffffffffc0204280:	013d3c23          	sd	s3,24(s10) # fffffffffff80018 <end+0x3fce4848>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204284:	4785                	li	a5,1
ffffffffc0204286:	40fcb7af          	amoor.d	a5,a5,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020428a:	03f79713          	slli	a4,a5,0x3f
ffffffffc020428e:	03f75793          	srli	a5,a4,0x3f
ffffffffc0204292:	4985                	li	s3,1
ffffffffc0204294:	cb91                	beqz	a5,ffffffffc02042a8 <do_fork+0x2a2>
    {
        schedule();
ffffffffc0204296:	6d7000ef          	jal	ffffffffc020516c <schedule>
ffffffffc020429a:	413cb7af          	amoor.d	a5,s3,(s9)
    while (!try_lock(lock))
ffffffffc020429e:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042a2:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042a6:	fbe5                	bnez	a5,ffffffffc0204296 <do_fork+0x290>
        ret = dup_mmap(mm, oldmm);
ffffffffc02042a8:	85e2                	mv	a1,s8
ffffffffc02042aa:	856a                	mv	a0,s10
ffffffffc02042ac:	ea8ff0ef          	jal	ffffffffc0203954 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02042b0:	57f9                	li	a5,-2
ffffffffc02042b2:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc02042b6:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02042b8:	0e078663          	beqz	a5,ffffffffc02043a4 <do_fork+0x39e>
    if ((mm = mm_create()) == NULL)
ffffffffc02042bc:	8c6a                	mv	s8,s10
    if (ret != 0)
ffffffffc02042be:	de050ee3          	beqz	a0,ffffffffc02040ba <do_fork+0xb4>
    exit_mmap(mm);
ffffffffc02042c2:	856a                	mv	a0,s10
ffffffffc02042c4:	f28ff0ef          	jal	ffffffffc02039ec <exit_mmap>
    put_pgdir(mm);
ffffffffc02042c8:	856a                	mv	a0,s10
ffffffffc02042ca:	c65ff0ef          	jal	ffffffffc0203f2e <put_pgdir>
    mm_destroy(mm);
ffffffffc02042ce:	856a                	mv	a0,s10
ffffffffc02042d0:	d66ff0ef          	jal	ffffffffc0203836 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02042d4:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02042d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02042da:	08f6ec63          	bltu	a3,a5,ffffffffc0204372 <do_fork+0x36c>
ffffffffc02042de:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage)
ffffffffc02042e2:	000b3703          	ld	a4,0(s6)
    return pa2page(PADDR(kva));
ffffffffc02042e6:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02042ea:	83b1                	srli	a5,a5,0xc
ffffffffc02042ec:	04e7fb63          	bgeu	a5,a4,ffffffffc0204342 <do_fork+0x33c>
    return &pages[PPN(pa) - nbase];
ffffffffc02042f0:	000ab703          	ld	a4,0(s5)
ffffffffc02042f4:	000a3503          	ld	a0,0(s4)
ffffffffc02042f8:	4589                	li	a1,2
ffffffffc02042fa:	8f99                	sub	a5,a5,a4
ffffffffc02042fc:	079a                	slli	a5,a5,0x6
ffffffffc02042fe:	953e                	add	a0,a0,a5
ffffffffc0204300:	bd1fd0ef          	jal	ffffffffc0201ed0 <free_pages>
}
ffffffffc0204304:	6a06                	ld	s4,64(sp)
ffffffffc0204306:	7ae2                	ld	s5,56(sp)
ffffffffc0204308:	7b42                	ld	s6,48(sp)
ffffffffc020430a:	7c02                	ld	s8,32(sp)
ffffffffc020430c:	6ce2                	ld	s9,24(sp)
    kfree(proc);
ffffffffc020430e:	8522                	mv	a0,s0
ffffffffc0204310:	a6bfd0ef          	jal	ffffffffc0201d7a <kfree>
ffffffffc0204314:	7ba2                	ld	s7,40(sp)
ffffffffc0204316:	7406                	ld	s0,96(sp)
ffffffffc0204318:	64e6                	ld	s1,88(sp)
ffffffffc020431a:	6946                	ld	s2,80(sp)
ffffffffc020431c:	6d42                	ld	s10,16(sp)
    ret = -E_NO_MEM;
ffffffffc020431e:	5571                	li	a0,-4
    return ret;
ffffffffc0204320:	b739                	j	ffffffffc020422e <do_fork+0x228>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204322:	8936                	mv	s2,a3
ffffffffc0204324:	bbc5                	j	ffffffffc0204114 <do_fork+0x10e>
        last_pid = 1;
ffffffffc0204326:	4505                	li	a0,1
ffffffffc0204328:	00093797          	auipc	a5,0x93
ffffffffc020432c:	fea7aa23          	sw	a0,-12(a5) # ffffffffc029731c <last_pid.1>
        goto inside;
ffffffffc0204330:	b505                	j	ffffffffc0204150 <do_fork+0x14a>
                    if (last_pid >= MAX_PID)
ffffffffc0204332:	6789                	lui	a5,0x2
ffffffffc0204334:	00f6c363          	blt	a3,a5,ffffffffc020433a <do_fork+0x334>
                        last_pid = 1;
ffffffffc0204338:	4685                	li	a3,1
                    goto repeat;
ffffffffc020433a:	4585                	li	a1,1
ffffffffc020433c:	b53d                	j	ffffffffc020416a <do_fork+0x164>
    int ret = -E_NO_FREE_PROC;
ffffffffc020433e:	556d                	li	a0,-5
ffffffffc0204340:	b5fd                	j	ffffffffc020422e <do_fork+0x228>
        panic("pa2page called with invalid pa");
ffffffffc0204342:	00002617          	auipc	a2,0x2
ffffffffc0204346:	2a660613          	addi	a2,a2,678 # ffffffffc02065e8 <etext+0xe54>
ffffffffc020434a:	06900593          	li	a1,105
ffffffffc020434e:	00002517          	auipc	a0,0x2
ffffffffc0204352:	1f250513          	addi	a0,a0,498 # ffffffffc0206540 <etext+0xdac>
ffffffffc0204356:	8f0fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020435a:	00002617          	auipc	a2,0x2
ffffffffc020435e:	1be60613          	addi	a2,a2,446 # ffffffffc0206518 <etext+0xd84>
ffffffffc0204362:	07100593          	li	a1,113
ffffffffc0204366:	00002517          	auipc	a0,0x2
ffffffffc020436a:	1da50513          	addi	a0,a0,474 # ffffffffc0206540 <etext+0xdac>
ffffffffc020436e:	8d8fc0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204372:	00002617          	auipc	a2,0x2
ffffffffc0204376:	24e60613          	addi	a2,a2,590 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc020437a:	07700593          	li	a1,119
ffffffffc020437e:	00002517          	auipc	a0,0x2
ffffffffc0204382:	1c250513          	addi	a0,a0,450 # ffffffffc0206540 <etext+0xdac>
ffffffffc0204386:	8c0fc0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020438a:	86be                	mv	a3,a5
ffffffffc020438c:	00002617          	auipc	a2,0x2
ffffffffc0204390:	23460613          	addi	a2,a2,564 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc0204394:	1a000593          	li	a1,416
ffffffffc0204398:	00003517          	auipc	a0,0x3
ffffffffc020439c:	bb850513          	addi	a0,a0,-1096 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc02043a0:	8a6fc0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc02043a4:	00003617          	auipc	a2,0x3
ffffffffc02043a8:	bc460613          	addi	a2,a2,-1084 # ffffffffc0206f68 <etext+0x17d4>
ffffffffc02043ac:	03f00593          	li	a1,63
ffffffffc02043b0:	00003517          	auipc	a0,0x3
ffffffffc02043b4:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206f78 <etext+0x17e4>
ffffffffc02043b8:	88efc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02043bc <kernel_thread>:
{
ffffffffc02043bc:	7129                	addi	sp,sp,-320
ffffffffc02043be:	fa22                	sd	s0,304(sp)
ffffffffc02043c0:	f626                	sd	s1,296(sp)
ffffffffc02043c2:	f24a                	sd	s2,288(sp)
ffffffffc02043c4:	842a                	mv	s0,a0
ffffffffc02043c6:	84ae                	mv	s1,a1
ffffffffc02043c8:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043ca:	850a                	mv	a0,sp
ffffffffc02043cc:	12000613          	li	a2,288
ffffffffc02043d0:	4581                	li	a1,0
{
ffffffffc02043d2:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043d4:	396010ef          	jal	ffffffffc020576a <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02043d8:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02043da:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043dc:	100027f3          	csrr	a5,sstatus
ffffffffc02043e0:	edd7f793          	andi	a5,a5,-291
ffffffffc02043e4:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043e8:	860a                	mv	a2,sp
ffffffffc02043ea:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043ee:	00000717          	auipc	a4,0x0
ffffffffc02043f2:	a3a70713          	addi	a4,a4,-1478 # ffffffffc0203e28 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043f6:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043f8:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043fa:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043fc:	c0bff0ef          	jal	ffffffffc0204006 <do_fork>
}
ffffffffc0204400:	70f2                	ld	ra,312(sp)
ffffffffc0204402:	7452                	ld	s0,304(sp)
ffffffffc0204404:	74b2                	ld	s1,296(sp)
ffffffffc0204406:	7912                	ld	s2,288(sp)
ffffffffc0204408:	6131                	addi	sp,sp,320
ffffffffc020440a:	8082                	ret

ffffffffc020440c <do_exit>:
{
ffffffffc020440c:	7179                	addi	sp,sp,-48
ffffffffc020440e:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204410:	00097417          	auipc	s0,0x97
ffffffffc0204414:	3a840413          	addi	s0,s0,936 # ffffffffc029b7b8 <current>
ffffffffc0204418:	601c                	ld	a5,0(s0)
ffffffffc020441a:	00097717          	auipc	a4,0x97
ffffffffc020441e:	3ae73703          	ld	a4,942(a4) # ffffffffc029b7c8 <idleproc>
{
ffffffffc0204422:	f406                	sd	ra,40(sp)
ffffffffc0204424:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc0204426:	0ce78b63          	beq	a5,a4,ffffffffc02044fc <do_exit+0xf0>
    if (current == initproc)
ffffffffc020442a:	00097497          	auipc	s1,0x97
ffffffffc020442e:	39648493          	addi	s1,s1,918 # ffffffffc029b7c0 <initproc>
ffffffffc0204432:	6098                	ld	a4,0(s1)
ffffffffc0204434:	e84a                	sd	s2,16(sp)
ffffffffc0204436:	0ee78a63          	beq	a5,a4,ffffffffc020452a <do_exit+0x11e>
ffffffffc020443a:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc020443c:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc020443e:	c115                	beqz	a0,ffffffffc0204462 <do_exit+0x56>
ffffffffc0204440:	00097797          	auipc	a5,0x97
ffffffffc0204444:	3487b783          	ld	a5,840(a5) # ffffffffc029b788 <boot_pgdir_pa>
ffffffffc0204448:	577d                	li	a4,-1
ffffffffc020444a:	177e                	slli	a4,a4,0x3f
ffffffffc020444c:	83b1                	srli	a5,a5,0xc
ffffffffc020444e:	8fd9                	or	a5,a5,a4
ffffffffc0204450:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204454:	591c                	lw	a5,48(a0)
ffffffffc0204456:	37fd                	addiw	a5,a5,-1
ffffffffc0204458:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc020445a:	cfd5                	beqz	a5,ffffffffc0204516 <do_exit+0x10a>
        current->mm = NULL;
ffffffffc020445c:	601c                	ld	a5,0(s0)
ffffffffc020445e:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204462:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc0204464:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204468:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020446a:	100027f3          	csrr	a5,sstatus
ffffffffc020446e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204470:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204472:	ebe1                	bnez	a5,ffffffffc0204542 <do_exit+0x136>
        proc = current->parent;
ffffffffc0204474:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204476:	800007b7          	lui	a5,0x80000
ffffffffc020447a:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        proc = current->parent;
ffffffffc020447c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020447e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204482:	0cf70463          	beq	a4,a5,ffffffffc020454a <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc0204486:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204488:	800005b7          	lui	a1,0x80000
ffffffffc020448c:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        while (current->cptr != NULL)
ffffffffc020448e:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204490:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204492:	e789                	bnez	a5,ffffffffc020449c <do_exit+0x90>
ffffffffc0204494:	a83d                	j	ffffffffc02044d2 <do_exit+0xc6>
ffffffffc0204496:	6018                	ld	a4,0(s0)
ffffffffc0204498:	7b7c                	ld	a5,240(a4)
ffffffffc020449a:	cf85                	beqz	a5,ffffffffc02044d2 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc020449c:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044a0:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02044a2:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc02044a4:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044a8:	7978                	ld	a4,240(a0)
ffffffffc02044aa:	10e7b023          	sd	a4,256(a5)
ffffffffc02044ae:	c311                	beqz	a4,ffffffffc02044b2 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc02044b0:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044b2:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02044b4:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02044b6:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044b8:	fcc71fe3          	bne	a4,a2,ffffffffc0204496 <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044bc:	0ec52783          	lw	a5,236(a0)
ffffffffc02044c0:	fcb79be3          	bne	a5,a1,ffffffffc0204496 <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc02044c4:	415000ef          	jal	ffffffffc02050d8 <wakeup_proc>
ffffffffc02044c8:	800005b7          	lui	a1,0x80000
ffffffffc02044cc:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
ffffffffc02044ce:	460d                	li	a2,3
ffffffffc02044d0:	b7d9                	j	ffffffffc0204496 <do_exit+0x8a>
    if (flag)
ffffffffc02044d2:	02091263          	bnez	s2,ffffffffc02044f6 <do_exit+0xea>
    schedule();
ffffffffc02044d6:	497000ef          	jal	ffffffffc020516c <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02044da:	601c                	ld	a5,0(s0)
ffffffffc02044dc:	00003617          	auipc	a2,0x3
ffffffffc02044e0:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206fb0 <etext+0x181c>
ffffffffc02044e4:	24300593          	li	a1,579
ffffffffc02044e8:	43d4                	lw	a3,4(a5)
ffffffffc02044ea:	00003517          	auipc	a0,0x3
ffffffffc02044ee:	a6650513          	addi	a0,a0,-1434 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc02044f2:	f55fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc02044f6:	c08fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02044fa:	bff1                	j	ffffffffc02044d6 <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc02044fc:	00003617          	auipc	a2,0x3
ffffffffc0204500:	a9460613          	addi	a2,a2,-1388 # ffffffffc0206f90 <etext+0x17fc>
ffffffffc0204504:	20f00593          	li	a1,527
ffffffffc0204508:	00003517          	auipc	a0,0x3
ffffffffc020450c:	a4850513          	addi	a0,a0,-1464 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204510:	e84a                	sd	s2,16(sp)
ffffffffc0204512:	f35fb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc0204516:	e42a                	sd	a0,8(sp)
ffffffffc0204518:	cd4ff0ef          	jal	ffffffffc02039ec <exit_mmap>
            put_pgdir(mm);
ffffffffc020451c:	6522                	ld	a0,8(sp)
ffffffffc020451e:	a11ff0ef          	jal	ffffffffc0203f2e <put_pgdir>
            mm_destroy(mm);
ffffffffc0204522:	6522                	ld	a0,8(sp)
ffffffffc0204524:	b12ff0ef          	jal	ffffffffc0203836 <mm_destroy>
ffffffffc0204528:	bf15                	j	ffffffffc020445c <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc020452a:	00003617          	auipc	a2,0x3
ffffffffc020452e:	a7660613          	addi	a2,a2,-1418 # ffffffffc0206fa0 <etext+0x180c>
ffffffffc0204532:	21300593          	li	a1,531
ffffffffc0204536:	00003517          	auipc	a0,0x3
ffffffffc020453a:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc020453e:	f09fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc0204542:	bc2fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204546:	4905                	li	s2,1
ffffffffc0204548:	b735                	j	ffffffffc0204474 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc020454a:	38f000ef          	jal	ffffffffc02050d8 <wakeup_proc>
ffffffffc020454e:	bf25                	j	ffffffffc0204486 <do_exit+0x7a>

ffffffffc0204550 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204550:	7179                	addi	sp,sp,-48
ffffffffc0204552:	ec26                	sd	s1,24(sp)
ffffffffc0204554:	e84a                	sd	s2,16(sp)
ffffffffc0204556:	e44e                	sd	s3,8(sp)
ffffffffc0204558:	f406                	sd	ra,40(sp)
ffffffffc020455a:	f022                	sd	s0,32(sp)
ffffffffc020455c:	84aa                	mv	s1,a0
ffffffffc020455e:	892e                	mv	s2,a1
ffffffffc0204560:	00097997          	auipc	s3,0x97
ffffffffc0204564:	25898993          	addi	s3,s3,600 # ffffffffc029b7b8 <current>
    if (pid != 0)
ffffffffc0204568:	cd19                	beqz	a0,ffffffffc0204586 <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc020456a:	6789                	lui	a5,0x2
ffffffffc020456c:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc020456e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204572:	12e7f563          	bgeu	a5,a4,ffffffffc020469c <do_wait.part.0+0x14c>
}
ffffffffc0204576:	70a2                	ld	ra,40(sp)
ffffffffc0204578:	7402                	ld	s0,32(sp)
ffffffffc020457a:	64e2                	ld	s1,24(sp)
ffffffffc020457c:	6942                	ld	s2,16(sp)
ffffffffc020457e:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204580:	5579                	li	a0,-2
}
ffffffffc0204582:	6145                	addi	sp,sp,48
ffffffffc0204584:	8082                	ret
        proc = current->cptr;
ffffffffc0204586:	0009b703          	ld	a4,0(s3)
ffffffffc020458a:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020458c:	d46d                	beqz	s0,ffffffffc0204576 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020458e:	468d                	li	a3,3
ffffffffc0204590:	a021                	j	ffffffffc0204598 <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204592:	10043403          	ld	s0,256(s0)
ffffffffc0204596:	c075                	beqz	s0,ffffffffc020467a <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204598:	401c                	lw	a5,0(s0)
ffffffffc020459a:	fed79ce3          	bne	a5,a3,ffffffffc0204592 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc020459e:	00097797          	auipc	a5,0x97
ffffffffc02045a2:	22a7b783          	ld	a5,554(a5) # ffffffffc029b7c8 <idleproc>
ffffffffc02045a6:	14878263          	beq	a5,s0,ffffffffc02046ea <do_wait.part.0+0x19a>
ffffffffc02045aa:	00097797          	auipc	a5,0x97
ffffffffc02045ae:	2167b783          	ld	a5,534(a5) # ffffffffc029b7c0 <initproc>
ffffffffc02045b2:	12f40c63          	beq	s0,a5,ffffffffc02046ea <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc02045b6:	00090663          	beqz	s2,ffffffffc02045c2 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc02045ba:	0e842783          	lw	a5,232(s0)
ffffffffc02045be:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045c2:	100027f3          	csrr	a5,sstatus
ffffffffc02045c6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045c8:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045ca:	10079963          	bnez	a5,ffffffffc02046dc <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02045ce:	6c74                	ld	a3,216(s0)
ffffffffc02045d0:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc02045d2:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc02045d6:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02045d8:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02045da:	6474                	ld	a3,200(s0)
ffffffffc02045dc:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc02045de:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02045e0:	e314                	sd	a3,0(a4)
ffffffffc02045e2:	c789                	beqz	a5,ffffffffc02045ec <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc02045e4:	7c78                	ld	a4,248(s0)
ffffffffc02045e6:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc02045e8:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc02045ec:	7c78                	ld	a4,248(s0)
ffffffffc02045ee:	c36d                	beqz	a4,ffffffffc02046d0 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc02045f0:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc02045f4:	00097797          	auipc	a5,0x97
ffffffffc02045f8:	1bc7a783          	lw	a5,444(a5) # ffffffffc029b7b0 <nr_process>
ffffffffc02045fc:	37fd                	addiw	a5,a5,-1
ffffffffc02045fe:	00097717          	auipc	a4,0x97
ffffffffc0204602:	1af72923          	sw	a5,434(a4) # ffffffffc029b7b0 <nr_process>
    if (flag)
ffffffffc0204606:	e271                	bnez	a2,ffffffffc02046ca <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204608:	6814                	ld	a3,16(s0)
ffffffffc020460a:	c02007b7          	lui	a5,0xc0200
ffffffffc020460e:	10f6e663          	bltu	a3,a5,ffffffffc020471a <do_wait.part.0+0x1ca>
ffffffffc0204612:	00097717          	auipc	a4,0x97
ffffffffc0204616:	18673703          	ld	a4,390(a4) # ffffffffc029b798 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc020461a:	00097797          	auipc	a5,0x97
ffffffffc020461e:	1867b783          	ld	a5,390(a5) # ffffffffc029b7a0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0204622:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0204624:	82b1                	srli	a3,a3,0xc
ffffffffc0204626:	0cf6fe63          	bgeu	a3,a5,ffffffffc0204702 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc020462a:	00003797          	auipc	a5,0x3
ffffffffc020462e:	2ae7b783          	ld	a5,686(a5) # ffffffffc02078d8 <nbase>
ffffffffc0204632:	00097517          	auipc	a0,0x97
ffffffffc0204636:	17653503          	ld	a0,374(a0) # ffffffffc029b7a8 <pages>
ffffffffc020463a:	4589                	li	a1,2
ffffffffc020463c:	8e9d                	sub	a3,a3,a5
ffffffffc020463e:	069a                	slli	a3,a3,0x6
ffffffffc0204640:	9536                	add	a0,a0,a3
ffffffffc0204642:	88ffd0ef          	jal	ffffffffc0201ed0 <free_pages>
    kfree(proc);
ffffffffc0204646:	8522                	mv	a0,s0
ffffffffc0204648:	f32fd0ef          	jal	ffffffffc0201d7a <kfree>
}
ffffffffc020464c:	70a2                	ld	ra,40(sp)
ffffffffc020464e:	7402                	ld	s0,32(sp)
ffffffffc0204650:	64e2                	ld	s1,24(sp)
ffffffffc0204652:	6942                	ld	s2,16(sp)
ffffffffc0204654:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc0204656:	4501                	li	a0,0
}
ffffffffc0204658:	6145                	addi	sp,sp,48
ffffffffc020465a:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020465c:	00097997          	auipc	s3,0x97
ffffffffc0204660:	15c98993          	addi	s3,s3,348 # ffffffffc029b7b8 <current>
ffffffffc0204664:	0009b703          	ld	a4,0(s3)
ffffffffc0204668:	f487b683          	ld	a3,-184(a5)
ffffffffc020466c:	f0e695e3          	bne	a3,a4,ffffffffc0204576 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204670:	f287a603          	lw	a2,-216(a5)
ffffffffc0204674:	468d                	li	a3,3
ffffffffc0204676:	06d60063          	beq	a2,a3,ffffffffc02046d6 <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc020467a:	800007b7          	lui	a5,0x80000
ffffffffc020467e:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        current->state = PROC_SLEEPING;
ffffffffc0204680:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204682:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc0204686:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc0204688:	2e5000ef          	jal	ffffffffc020516c <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020468c:	0009b783          	ld	a5,0(s3)
ffffffffc0204690:	0b07a783          	lw	a5,176(a5)
ffffffffc0204694:	8b85                	andi	a5,a5,1
ffffffffc0204696:	e7b9                	bnez	a5,ffffffffc02046e4 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc0204698:	ee0487e3          	beqz	s1,ffffffffc0204586 <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020469c:	45a9                	li	a1,10
ffffffffc020469e:	8526                	mv	a0,s1
ffffffffc02046a0:	435000ef          	jal	ffffffffc02052d4 <hash32>
ffffffffc02046a4:	02051793          	slli	a5,a0,0x20
ffffffffc02046a8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02046ac:	00093797          	auipc	a5,0x93
ffffffffc02046b0:	08c78793          	addi	a5,a5,140 # ffffffffc0297738 <hash_list>
ffffffffc02046b4:	953e                	add	a0,a0,a5
ffffffffc02046b6:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc02046b8:	a029                	j	ffffffffc02046c2 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc02046ba:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02046be:	f8970fe3          	beq	a4,s1,ffffffffc020465c <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc02046c2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02046c4:	fef51be3          	bne	a0,a5,ffffffffc02046ba <do_wait.part.0+0x16a>
ffffffffc02046c8:	b57d                	j	ffffffffc0204576 <do_wait.part.0+0x26>
        intr_enable();
ffffffffc02046ca:	a34fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02046ce:	bf2d                	j	ffffffffc0204608 <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc02046d0:	7018                	ld	a4,32(s0)
ffffffffc02046d2:	fb7c                	sd	a5,240(a4)
ffffffffc02046d4:	b705                	j	ffffffffc02045f4 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02046d6:	f2878413          	addi	s0,a5,-216
ffffffffc02046da:	b5d1                	j	ffffffffc020459e <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc02046dc:	a28fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02046e0:	4605                	li	a2,1
ffffffffc02046e2:	b5f5                	j	ffffffffc02045ce <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc02046e4:	555d                	li	a0,-9
ffffffffc02046e6:	d27ff0ef          	jal	ffffffffc020440c <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc02046ea:	00003617          	auipc	a2,0x3
ffffffffc02046ee:	8e660613          	addi	a2,a2,-1818 # ffffffffc0206fd0 <etext+0x183c>
ffffffffc02046f2:	36600593          	li	a1,870
ffffffffc02046f6:	00003517          	auipc	a0,0x3
ffffffffc02046fa:	85a50513          	addi	a0,a0,-1958 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc02046fe:	d49fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204702:	00002617          	auipc	a2,0x2
ffffffffc0204706:	ee660613          	addi	a2,a2,-282 # ffffffffc02065e8 <etext+0xe54>
ffffffffc020470a:	06900593          	li	a1,105
ffffffffc020470e:	00002517          	auipc	a0,0x2
ffffffffc0204712:	e3250513          	addi	a0,a0,-462 # ffffffffc0206540 <etext+0xdac>
ffffffffc0204716:	d31fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020471a:	00002617          	auipc	a2,0x2
ffffffffc020471e:	ea660613          	addi	a2,a2,-346 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc0204722:	07700593          	li	a1,119
ffffffffc0204726:	00002517          	auipc	a0,0x2
ffffffffc020472a:	e1a50513          	addi	a0,a0,-486 # ffffffffc0206540 <etext+0xdac>
ffffffffc020472e:	d19fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204732 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204732:	1141                	addi	sp,sp,-16
ffffffffc0204734:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204736:	fd2fd0ef          	jal	ffffffffc0201f08 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020473a:	d96fd0ef          	jal	ffffffffc0201cd0 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020473e:	4601                	li	a2,0
ffffffffc0204740:	4581                	li	a1,0
ffffffffc0204742:	fffff517          	auipc	a0,0xfffff
ffffffffc0204746:	76e50513          	addi	a0,a0,1902 # ffffffffc0203eb0 <user_main>
ffffffffc020474a:	c73ff0ef          	jal	ffffffffc02043bc <kernel_thread>
    if (pid <= 0)
ffffffffc020474e:	00a04563          	bgtz	a0,ffffffffc0204758 <init_main+0x26>
ffffffffc0204752:	a071                	j	ffffffffc02047de <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204754:	219000ef          	jal	ffffffffc020516c <schedule>
    if (code_store != NULL)
ffffffffc0204758:	4581                	li	a1,0
ffffffffc020475a:	4501                	li	a0,0
ffffffffc020475c:	df5ff0ef          	jal	ffffffffc0204550 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204760:	d975                	beqz	a0,ffffffffc0204754 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204762:	00003517          	auipc	a0,0x3
ffffffffc0204766:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0207010 <etext+0x187c>
ffffffffc020476a:	a2bfb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020476e:	00097797          	auipc	a5,0x97
ffffffffc0204772:	0527b783          	ld	a5,82(a5) # ffffffffc029b7c0 <initproc>
ffffffffc0204776:	7bf8                	ld	a4,240(a5)
ffffffffc0204778:	e339                	bnez	a4,ffffffffc02047be <init_main+0x8c>
ffffffffc020477a:	7ff8                	ld	a4,248(a5)
ffffffffc020477c:	e329                	bnez	a4,ffffffffc02047be <init_main+0x8c>
ffffffffc020477e:	1007b703          	ld	a4,256(a5)
ffffffffc0204782:	ef15                	bnez	a4,ffffffffc02047be <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204784:	00097697          	auipc	a3,0x97
ffffffffc0204788:	02c6a683          	lw	a3,44(a3) # ffffffffc029b7b0 <nr_process>
ffffffffc020478c:	4709                	li	a4,2
ffffffffc020478e:	0ae69463          	bne	a3,a4,ffffffffc0204836 <init_main+0x104>
ffffffffc0204792:	00097697          	auipc	a3,0x97
ffffffffc0204796:	fa668693          	addi	a3,a3,-90 # ffffffffc029b738 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020479a:	6698                	ld	a4,8(a3)
ffffffffc020479c:	0c878793          	addi	a5,a5,200
ffffffffc02047a0:	06f71b63          	bne	a4,a5,ffffffffc0204816 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047a4:	629c                	ld	a5,0(a3)
ffffffffc02047a6:	04f71863          	bne	a4,a5,ffffffffc02047f6 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02047aa:	00003517          	auipc	a0,0x3
ffffffffc02047ae:	94e50513          	addi	a0,a0,-1714 # ffffffffc02070f8 <etext+0x1964>
ffffffffc02047b2:	9e3fb0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02047b6:	60a2                	ld	ra,8(sp)
ffffffffc02047b8:	4501                	li	a0,0
ffffffffc02047ba:	0141                	addi	sp,sp,16
ffffffffc02047bc:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02047be:	00003697          	auipc	a3,0x3
ffffffffc02047c2:	87a68693          	addi	a3,a3,-1926 # ffffffffc0207038 <etext+0x18a4>
ffffffffc02047c6:	00002617          	auipc	a2,0x2
ffffffffc02047ca:	9a260613          	addi	a2,a2,-1630 # ffffffffc0206168 <etext+0x9d4>
ffffffffc02047ce:	3d400593          	li	a1,980
ffffffffc02047d2:	00002517          	auipc	a0,0x2
ffffffffc02047d6:	77e50513          	addi	a0,a0,1918 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc02047da:	c6dfb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc02047de:	00003617          	auipc	a2,0x3
ffffffffc02047e2:	81260613          	addi	a2,a2,-2030 # ffffffffc0206ff0 <etext+0x185c>
ffffffffc02047e6:	3cb00593          	li	a1,971
ffffffffc02047ea:	00002517          	auipc	a0,0x2
ffffffffc02047ee:	76650513          	addi	a0,a0,1894 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc02047f2:	c55fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047f6:	00003697          	auipc	a3,0x3
ffffffffc02047fa:	8d268693          	addi	a3,a3,-1838 # ffffffffc02070c8 <etext+0x1934>
ffffffffc02047fe:	00002617          	auipc	a2,0x2
ffffffffc0204802:	96a60613          	addi	a2,a2,-1686 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204806:	3d700593          	li	a1,983
ffffffffc020480a:	00002517          	auipc	a0,0x2
ffffffffc020480e:	74650513          	addi	a0,a0,1862 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204812:	c35fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204816:	00003697          	auipc	a3,0x3
ffffffffc020481a:	88268693          	addi	a3,a3,-1918 # ffffffffc0207098 <etext+0x1904>
ffffffffc020481e:	00002617          	auipc	a2,0x2
ffffffffc0204822:	94a60613          	addi	a2,a2,-1718 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204826:	3d600593          	li	a1,982
ffffffffc020482a:	00002517          	auipc	a0,0x2
ffffffffc020482e:	72650513          	addi	a0,a0,1830 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204832:	c15fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc0204836:	00003697          	auipc	a3,0x3
ffffffffc020483a:	85268693          	addi	a3,a3,-1966 # ffffffffc0207088 <etext+0x18f4>
ffffffffc020483e:	00002617          	auipc	a2,0x2
ffffffffc0204842:	92a60613          	addi	a2,a2,-1750 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204846:	3d500593          	li	a1,981
ffffffffc020484a:	00002517          	auipc	a0,0x2
ffffffffc020484e:	70650513          	addi	a0,a0,1798 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204852:	bf5fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204856 <do_execve>:
{
ffffffffc0204856:	7171                	addi	sp,sp,-176
ffffffffc0204858:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020485a:	00097d17          	auipc	s10,0x97
ffffffffc020485e:	f5ed0d13          	addi	s10,s10,-162 # ffffffffc029b7b8 <current>
ffffffffc0204862:	000d3783          	ld	a5,0(s10)
{
ffffffffc0204866:	e94a                	sd	s2,144(sp)
ffffffffc0204868:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020486a:	0287b903          	ld	s2,40(a5)
{
ffffffffc020486e:	84ae                	mv	s1,a1
ffffffffc0204870:	e54e                	sd	s3,136(sp)
ffffffffc0204872:	ec32                	sd	a2,24(sp)
ffffffffc0204874:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204876:	85aa                	mv	a1,a0
ffffffffc0204878:	8626                	mv	a2,s1
ffffffffc020487a:	854a                	mv	a0,s2
ffffffffc020487c:	4681                	li	a3,0
{
ffffffffc020487e:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204880:	d04ff0ef          	jal	ffffffffc0203d84 <user_mem_check>
ffffffffc0204884:	46050f63          	beqz	a0,ffffffffc0204d02 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204888:	4641                	li	a2,16
ffffffffc020488a:	1808                	addi	a0,sp,48
ffffffffc020488c:	4581                	li	a1,0
ffffffffc020488e:	6dd000ef          	jal	ffffffffc020576a <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204892:	47bd                	li	a5,15
ffffffffc0204894:	8626                	mv	a2,s1
ffffffffc0204896:	0e97ef63          	bltu	a5,s1,ffffffffc0204994 <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc020489a:	85ce                	mv	a1,s3
ffffffffc020489c:	1808                	addi	a0,sp,48
ffffffffc020489e:	6df000ef          	jal	ffffffffc020577c <memcpy>
    if (mm != NULL)
ffffffffc02048a2:	10090063          	beqz	s2,ffffffffc02049a2 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc02048a6:	00002517          	auipc	a0,0x2
ffffffffc02048aa:	46a50513          	addi	a0,a0,1130 # ffffffffc0206d10 <etext+0x157c>
ffffffffc02048ae:	91dfb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc02048b2:	00097797          	auipc	a5,0x97
ffffffffc02048b6:	ed67b783          	ld	a5,-298(a5) # ffffffffc029b788 <boot_pgdir_pa>
ffffffffc02048ba:	577d                	li	a4,-1
ffffffffc02048bc:	177e                	slli	a4,a4,0x3f
ffffffffc02048be:	83b1                	srli	a5,a5,0xc
ffffffffc02048c0:	8fd9                	or	a5,a5,a4
ffffffffc02048c2:	18079073          	csrw	satp,a5
ffffffffc02048c6:	03092783          	lw	a5,48(s2)
ffffffffc02048ca:	37fd                	addiw	a5,a5,-1
ffffffffc02048cc:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc02048d0:	30078563          	beqz	a5,ffffffffc0204bda <do_execve+0x384>
        current->mm = NULL;
ffffffffc02048d4:	000d3783          	ld	a5,0(s10)
ffffffffc02048d8:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02048dc:	e1dfe0ef          	jal	ffffffffc02036f8 <mm_create>
ffffffffc02048e0:	892a                	mv	s2,a0
ffffffffc02048e2:	22050063          	beqz	a0,ffffffffc0204b02 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc02048e6:	4505                	li	a0,1
ffffffffc02048e8:	daefd0ef          	jal	ffffffffc0201e96 <alloc_pages>
ffffffffc02048ec:	42050063          	beqz	a0,ffffffffc0204d0c <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc02048f0:	f0e2                	sd	s8,96(sp)
ffffffffc02048f2:	00097c17          	auipc	s8,0x97
ffffffffc02048f6:	eb6c0c13          	addi	s8,s8,-330 # ffffffffc029b7a8 <pages>
ffffffffc02048fa:	000c3783          	ld	a5,0(s8)
ffffffffc02048fe:	f4de                	sd	s7,104(sp)
ffffffffc0204900:	00003b97          	auipc	s7,0x3
ffffffffc0204904:	fd8bbb83          	ld	s7,-40(s7) # ffffffffc02078d8 <nbase>
ffffffffc0204908:	40f506b3          	sub	a3,a0,a5
ffffffffc020490c:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc020490e:	00097c97          	auipc	s9,0x97
ffffffffc0204912:	e92c8c93          	addi	s9,s9,-366 # ffffffffc029b7a0 <npage>
ffffffffc0204916:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc0204918:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020491a:	5b7d                	li	s6,-1
ffffffffc020491c:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc0204920:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204922:	00cb5713          	srli	a4,s6,0xc
ffffffffc0204926:	e83a                	sd	a4,16(sp)
ffffffffc0204928:	fcd6                	sd	s5,120(sp)
ffffffffc020492a:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020492c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020492e:	40f77263          	bgeu	a4,a5,ffffffffc0204d32 <do_execve+0x4dc>
ffffffffc0204932:	00097a97          	auipc	s5,0x97
ffffffffc0204936:	e66a8a93          	addi	s5,s5,-410 # ffffffffc029b798 <va_pa_offset>
ffffffffc020493a:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020493e:	00097597          	auipc	a1,0x97
ffffffffc0204942:	e525b583          	ld	a1,-430(a1) # ffffffffc029b790 <boot_pgdir_va>
ffffffffc0204946:	6605                	lui	a2,0x1
ffffffffc0204948:	00f684b3          	add	s1,a3,a5
ffffffffc020494c:	8526                	mv	a0,s1
ffffffffc020494e:	62f000ef          	jal	ffffffffc020577c <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204952:	66e2                	ld	a3,24(sp)
ffffffffc0204954:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204958:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020495c:	4298                	lw	a4,0(a3)
ffffffffc020495e:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464ba3a7>
ffffffffc0204962:	06f70863          	beq	a4,a5,ffffffffc02049d2 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc0204966:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc0204968:	854a                	mv	a0,s2
ffffffffc020496a:	dc4ff0ef          	jal	ffffffffc0203f2e <put_pgdir>
ffffffffc020496e:	7ae6                	ld	s5,120(sp)
ffffffffc0204970:	7b46                	ld	s6,112(sp)
ffffffffc0204972:	7ba6                	ld	s7,104(sp)
ffffffffc0204974:	7c06                	ld	s8,96(sp)
ffffffffc0204976:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204978:	854a                	mv	a0,s2
ffffffffc020497a:	ebdfe0ef          	jal	ffffffffc0203836 <mm_destroy>
    do_exit(ret);
ffffffffc020497e:	8526                	mv	a0,s1
ffffffffc0204980:	f122                	sd	s0,160(sp)
ffffffffc0204982:	e152                	sd	s4,128(sp)
ffffffffc0204984:	fcd6                	sd	s5,120(sp)
ffffffffc0204986:	f8da                	sd	s6,112(sp)
ffffffffc0204988:	f4de                	sd	s7,104(sp)
ffffffffc020498a:	f0e2                	sd	s8,96(sp)
ffffffffc020498c:	ece6                	sd	s9,88(sp)
ffffffffc020498e:	e4ee                	sd	s11,72(sp)
ffffffffc0204990:	a7dff0ef          	jal	ffffffffc020440c <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204994:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204996:	85ce                	mv	a1,s3
ffffffffc0204998:	1808                	addi	a0,sp,48
ffffffffc020499a:	5e3000ef          	jal	ffffffffc020577c <memcpy>
    if (mm != NULL)
ffffffffc020499e:	f00914e3          	bnez	s2,ffffffffc02048a6 <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc02049a2:	000d3783          	ld	a5,0(s10)
ffffffffc02049a6:	779c                	ld	a5,40(a5)
ffffffffc02049a8:	db95                	beqz	a5,ffffffffc02048dc <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02049aa:	00002617          	auipc	a2,0x2
ffffffffc02049ae:	76e60613          	addi	a2,a2,1902 # ffffffffc0207118 <etext+0x1984>
ffffffffc02049b2:	24f00593          	li	a1,591
ffffffffc02049b6:	00002517          	auipc	a0,0x2
ffffffffc02049ba:	59a50513          	addi	a0,a0,1434 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc02049be:	f122                	sd	s0,160(sp)
ffffffffc02049c0:	e152                	sd	s4,128(sp)
ffffffffc02049c2:	fcd6                	sd	s5,120(sp)
ffffffffc02049c4:	f8da                	sd	s6,112(sp)
ffffffffc02049c6:	f4de                	sd	s7,104(sp)
ffffffffc02049c8:	f0e2                	sd	s8,96(sp)
ffffffffc02049ca:	ece6                	sd	s9,88(sp)
ffffffffc02049cc:	e4ee                	sd	s11,72(sp)
ffffffffc02049ce:	a79fb0ef          	jal	ffffffffc0200446 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049d2:	0386d703          	lhu	a4,56(a3)
ffffffffc02049d6:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02049d8:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049dc:	00371793          	slli	a5,a4,0x3
ffffffffc02049e0:	8f99                	sub	a5,a5,a4
ffffffffc02049e2:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02049e4:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049e6:	97d2                	add	a5,a5,s4
ffffffffc02049e8:	f122                	sd	s0,160(sp)
ffffffffc02049ea:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02049ec:	00fa7e63          	bgeu	s4,a5,ffffffffc0204a08 <do_execve+0x1b2>
ffffffffc02049f0:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02049f2:	000a2783          	lw	a5,0(s4)
ffffffffc02049f6:	4705                	li	a4,1
ffffffffc02049f8:	10e78763          	beq	a5,a4,ffffffffc0204b06 <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc02049fc:	77a2                	ld	a5,40(sp)
ffffffffc02049fe:	038a0a13          	addi	s4,s4,56
ffffffffc0204a02:	fefa68e3          	bltu	s4,a5,ffffffffc02049f2 <do_execve+0x19c>
ffffffffc0204a06:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204a08:	4701                	li	a4,0
ffffffffc0204a0a:	46ad                	li	a3,11
ffffffffc0204a0c:	00100637          	lui	a2,0x100
ffffffffc0204a10:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204a14:	854a                	mv	a0,s2
ffffffffc0204a16:	e73fe0ef          	jal	ffffffffc0203888 <mm_map>
ffffffffc0204a1a:	84aa                	mv	s1,a0
ffffffffc0204a1c:	1a051963          	bnez	a0,ffffffffc0204bce <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204a20:	01893503          	ld	a0,24(s2)
ffffffffc0204a24:	467d                	li	a2,31
ffffffffc0204a26:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204a2a:	bedfe0ef          	jal	ffffffffc0203616 <pgdir_alloc_page>
ffffffffc0204a2e:	3a050163          	beqz	a0,ffffffffc0204dd0 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a32:	01893503          	ld	a0,24(s2)
ffffffffc0204a36:	467d                	li	a2,31
ffffffffc0204a38:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204a3c:	bdbfe0ef          	jal	ffffffffc0203616 <pgdir_alloc_page>
ffffffffc0204a40:	36050763          	beqz	a0,ffffffffc0204dae <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a44:	01893503          	ld	a0,24(s2)
ffffffffc0204a48:	467d                	li	a2,31
ffffffffc0204a4a:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204a4e:	bc9fe0ef          	jal	ffffffffc0203616 <pgdir_alloc_page>
ffffffffc0204a52:	32050d63          	beqz	a0,ffffffffc0204d8c <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a56:	01893503          	ld	a0,24(s2)
ffffffffc0204a5a:	467d                	li	a2,31
ffffffffc0204a5c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204a60:	bb7fe0ef          	jal	ffffffffc0203616 <pgdir_alloc_page>
ffffffffc0204a64:	30050363          	beqz	a0,ffffffffc0204d6a <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc0204a68:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204a6c:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a70:	01893683          	ld	a3,24(s2)
ffffffffc0204a74:	2785                	addiw	a5,a5,1
ffffffffc0204a76:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204a7a:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5e50>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a7e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a82:	2cf6e763          	bltu	a3,a5,ffffffffc0204d50 <do_execve+0x4fa>
ffffffffc0204a86:	000ab783          	ld	a5,0(s5)
ffffffffc0204a8a:	577d                	li	a4,-1
ffffffffc0204a8c:	177e                	slli	a4,a4,0x3f
ffffffffc0204a8e:	8e9d                	sub	a3,a3,a5
ffffffffc0204a90:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204a94:	f654                	sd	a3,168(a2)
ffffffffc0204a96:	8fd9                	or	a5,a5,a4
ffffffffc0204a98:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204a9c:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a9e:	4581                	li	a1,0
ffffffffc0204aa0:	12000613          	li	a2,288
ffffffffc0204aa4:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204aa6:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204aaa:	4c1000ef          	jal	ffffffffc020576a <memset>
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204aae:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ab0:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204ab4:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204ab8:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;              // user stack top
ffffffffc0204aba:	4785                	li	a5,1
ffffffffc0204abc:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204abe:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204ac2:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;              // user stack top
ffffffffc0204ac6:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204ac8:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204acc:	4641                	li	a2,16
ffffffffc0204ace:	4581                	li	a1,0
ffffffffc0204ad0:	0b498513          	addi	a0,s3,180
ffffffffc0204ad4:	497000ef          	jal	ffffffffc020576a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ad8:	180c                	addi	a1,sp,48
ffffffffc0204ada:	0b498513          	addi	a0,s3,180
ffffffffc0204ade:	463d                	li	a2,15
ffffffffc0204ae0:	49d000ef          	jal	ffffffffc020577c <memcpy>
ffffffffc0204ae4:	740a                	ld	s0,160(sp)
ffffffffc0204ae6:	6a0a                	ld	s4,128(sp)
ffffffffc0204ae8:	7ae6                	ld	s5,120(sp)
ffffffffc0204aea:	7b46                	ld	s6,112(sp)
ffffffffc0204aec:	7ba6                	ld	s7,104(sp)
ffffffffc0204aee:	7c06                	ld	s8,96(sp)
ffffffffc0204af0:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204af2:	70aa                	ld	ra,168(sp)
ffffffffc0204af4:	694a                	ld	s2,144(sp)
ffffffffc0204af6:	69aa                	ld	s3,136(sp)
ffffffffc0204af8:	6d46                	ld	s10,80(sp)
ffffffffc0204afa:	8526                	mv	a0,s1
ffffffffc0204afc:	64ea                	ld	s1,152(sp)
ffffffffc0204afe:	614d                	addi	sp,sp,176
ffffffffc0204b00:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204b02:	54f1                	li	s1,-4
ffffffffc0204b04:	bdad                	j	ffffffffc020497e <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204b06:	028a3603          	ld	a2,40(s4)
ffffffffc0204b0a:	020a3783          	ld	a5,32(s4)
ffffffffc0204b0e:	20f66363          	bltu	a2,a5,ffffffffc0204d14 <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b12:	004a2783          	lw	a5,4(s4)
ffffffffc0204b16:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b1a:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b1e:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b20:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b22:	c6f1                	beqz	a3,ffffffffc0204bee <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b24:	1c079763          	bnez	a5,ffffffffc0204cf2 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b28:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204b2a:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204b2e:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204b30:	c709                	beqz	a4,ffffffffc0204b3a <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc0204b32:	67a2                	ld	a5,8(sp)
ffffffffc0204b34:	0087e793          	ori	a5,a5,8
ffffffffc0204b38:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204b3a:	010a3583          	ld	a1,16(s4)
ffffffffc0204b3e:	4701                	li	a4,0
ffffffffc0204b40:	854a                	mv	a0,s2
ffffffffc0204b42:	d47fe0ef          	jal	ffffffffc0203888 <mm_map>
ffffffffc0204b46:	84aa                	mv	s1,a0
ffffffffc0204b48:	1c051463          	bnez	a0,ffffffffc0204d10 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b4c:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b50:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b54:	77fd                	lui	a5,0xfffff
ffffffffc0204b56:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b5a:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204b5c:	1a9b7563          	bgeu	s6,s1,ffffffffc0204d06 <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b60:	008a3983          	ld	s3,8(s4)
ffffffffc0204b64:	67e2                	ld	a5,24(sp)
ffffffffc0204b66:	99be                	add	s3,s3,a5
ffffffffc0204b68:	a881                	j	ffffffffc0204bb8 <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b6a:	6785                	lui	a5,0x1
ffffffffc0204b6c:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204b70:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204b74:	01b4e463          	bltu	s1,s11,ffffffffc0204b7c <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b78:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204b7c:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204b80:	67c2                	ld	a5,16(sp)
ffffffffc0204b82:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204b86:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b8a:	8699                	srai	a3,a3,0x6
ffffffffc0204b8c:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204b8e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b92:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b94:	18a87363          	bgeu	a6,a0,ffffffffc0204d1a <do_execve+0x4c4>
ffffffffc0204b98:	000ab503          	ld	a0,0(s5)
ffffffffc0204b9c:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204ba0:	e032                	sd	a2,0(sp)
ffffffffc0204ba2:	9536                	add	a0,a0,a3
ffffffffc0204ba4:	952e                	add	a0,a0,a1
ffffffffc0204ba6:	85ce                	mv	a1,s3
ffffffffc0204ba8:	3d5000ef          	jal	ffffffffc020577c <memcpy>
            start += size, from += size;
ffffffffc0204bac:	6602                	ld	a2,0(sp)
ffffffffc0204bae:	9b32                	add	s6,s6,a2
ffffffffc0204bb0:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204bb2:	049b7563          	bgeu	s6,s1,ffffffffc0204bfc <do_execve+0x3a6>
ffffffffc0204bb6:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204bb8:	01893503          	ld	a0,24(s2)
ffffffffc0204bbc:	6622                	ld	a2,8(sp)
ffffffffc0204bbe:	e02e                	sd	a1,0(sp)
ffffffffc0204bc0:	a57fe0ef          	jal	ffffffffc0203616 <pgdir_alloc_page>
ffffffffc0204bc4:	6582                	ld	a1,0(sp)
ffffffffc0204bc6:	842a                	mv	s0,a0
ffffffffc0204bc8:	f14d                	bnez	a0,ffffffffc0204b6a <do_execve+0x314>
ffffffffc0204bca:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204bcc:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204bce:	854a                	mv	a0,s2
ffffffffc0204bd0:	e1dfe0ef          	jal	ffffffffc02039ec <exit_mmap>
ffffffffc0204bd4:	740a                	ld	s0,160(sp)
ffffffffc0204bd6:	6a0a                	ld	s4,128(sp)
ffffffffc0204bd8:	bb41                	j	ffffffffc0204968 <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204bda:	854a                	mv	a0,s2
ffffffffc0204bdc:	e11fe0ef          	jal	ffffffffc02039ec <exit_mmap>
            put_pgdir(mm);
ffffffffc0204be0:	854a                	mv	a0,s2
ffffffffc0204be2:	b4cff0ef          	jal	ffffffffc0203f2e <put_pgdir>
            mm_destroy(mm);
ffffffffc0204be6:	854a                	mv	a0,s2
ffffffffc0204be8:	c4ffe0ef          	jal	ffffffffc0203836 <mm_destroy>
ffffffffc0204bec:	b1e5                	j	ffffffffc02048d4 <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bee:	0e078e63          	beqz	a5,ffffffffc0204cea <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204bf2:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204bf4:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204bf8:	e43e                	sd	a5,8(sp)
ffffffffc0204bfa:	bf1d                	j	ffffffffc0204b30 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204bfc:	010a3483          	ld	s1,16(s4)
ffffffffc0204c00:	028a3683          	ld	a3,40(s4)
ffffffffc0204c04:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204c06:	07bb7c63          	bgeu	s6,s11,ffffffffc0204c7e <do_execve+0x428>
            if (start == end)
ffffffffc0204c0a:	df6489e3          	beq	s1,s6,ffffffffc02049fc <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204c0e:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204c12:	0fb4f563          	bgeu	s1,s11,ffffffffc0204cfc <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204c16:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c1a:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204c1e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c22:	8699                	srai	a3,a3,0x6
ffffffffc0204c24:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c26:	00c69593          	slli	a1,a3,0xc
ffffffffc0204c2a:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c2c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c2e:	0ec5f663          	bgeu	a1,a2,ffffffffc0204d1a <do_execve+0x4c4>
ffffffffc0204c32:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c36:	6505                	lui	a0,0x1
ffffffffc0204c38:	955a                	add	a0,a0,s6
ffffffffc0204c3a:	96b2                	add	a3,a3,a2
ffffffffc0204c3c:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c40:	9536                	add	a0,a0,a3
ffffffffc0204c42:	864e                	mv	a2,s3
ffffffffc0204c44:	4581                	li	a1,0
ffffffffc0204c46:	325000ef          	jal	ffffffffc020576a <memset>
            start += size;
ffffffffc0204c4a:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204c4c:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204c50:	01b4f463          	bgeu	s1,s11,ffffffffc0204c58 <do_execve+0x402>
ffffffffc0204c54:	db6484e3          	beq	s1,s6,ffffffffc02049fc <do_execve+0x1a6>
ffffffffc0204c58:	e299                	bnez	a3,ffffffffc0204c5e <do_execve+0x408>
ffffffffc0204c5a:	03bb0263          	beq	s6,s11,ffffffffc0204c7e <do_execve+0x428>
ffffffffc0204c5e:	00002697          	auipc	a3,0x2
ffffffffc0204c62:	4e268693          	addi	a3,a3,1250 # ffffffffc0207140 <etext+0x19ac>
ffffffffc0204c66:	00001617          	auipc	a2,0x1
ffffffffc0204c6a:	50260613          	addi	a2,a2,1282 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204c6e:	2b800593          	li	a1,696
ffffffffc0204c72:	00002517          	auipc	a0,0x2
ffffffffc0204c76:	2de50513          	addi	a0,a0,734 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204c7a:	fccfb0ef          	jal	ffffffffc0200446 <__panic>
        while (start < end)
ffffffffc0204c7e:	d69b7fe3          	bgeu	s6,s1,ffffffffc02049fc <do_execve+0x1a6>
ffffffffc0204c82:	56fd                	li	a3,-1
ffffffffc0204c84:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204c88:	f03e                	sd	a5,32(sp)
ffffffffc0204c8a:	a0b9                	j	ffffffffc0204cd8 <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c8c:	6785                	lui	a5,0x1
ffffffffc0204c8e:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204c92:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204c96:	0104e463          	bltu	s1,a6,ffffffffc0204c9e <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c9a:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204c9e:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204ca2:	7782                	ld	a5,32(sp)
ffffffffc0204ca4:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204ca8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cac:	8699                	srai	a3,a3,0x6
ffffffffc0204cae:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204cb0:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cb4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cb6:	06b57263          	bgeu	a0,a1,ffffffffc0204d1a <do_execve+0x4c4>
ffffffffc0204cba:	000ab583          	ld	a1,0(s5)
ffffffffc0204cbe:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cc2:	864e                	mv	a2,s3
ffffffffc0204cc4:	96ae                	add	a3,a3,a1
ffffffffc0204cc6:	9536                	add	a0,a0,a3
ffffffffc0204cc8:	4581                	li	a1,0
            start += size;
ffffffffc0204cca:	9b4e                	add	s6,s6,s3
ffffffffc0204ccc:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cce:	29d000ef          	jal	ffffffffc020576a <memset>
        while (start < end)
ffffffffc0204cd2:	d29b75e3          	bgeu	s6,s1,ffffffffc02049fc <do_execve+0x1a6>
ffffffffc0204cd6:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204cd8:	01893503          	ld	a0,24(s2)
ffffffffc0204cdc:	6622                	ld	a2,8(sp)
ffffffffc0204cde:	85ee                	mv	a1,s11
ffffffffc0204ce0:	937fe0ef          	jal	ffffffffc0203616 <pgdir_alloc_page>
ffffffffc0204ce4:	842a                	mv	s0,a0
ffffffffc0204ce6:	f15d                	bnez	a0,ffffffffc0204c8c <do_execve+0x436>
ffffffffc0204ce8:	b5cd                	j	ffffffffc0204bca <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204cea:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204cec:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204cee:	e43e                	sd	a5,8(sp)
ffffffffc0204cf0:	b581                	j	ffffffffc0204b30 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204cf2:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204cf4:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204cf8:	e43e                	sd	a5,8(sp)
ffffffffc0204cfa:	bd1d                	j	ffffffffc0204b30 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cfc:	416d89b3          	sub	s3,s11,s6
ffffffffc0204d00:	bf19                	j	ffffffffc0204c16 <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204d02:	54f5                	li	s1,-3
ffffffffc0204d04:	b3fd                	j	ffffffffc0204af2 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204d06:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204d08:	84da                	mv	s1,s6
ffffffffc0204d0a:	bddd                	j	ffffffffc0204c00 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204d0c:	54f1                	li	s1,-4
ffffffffc0204d0e:	b1ad                	j	ffffffffc0204978 <do_execve+0x122>
ffffffffc0204d10:	6da6                	ld	s11,72(sp)
ffffffffc0204d12:	bd75                	j	ffffffffc0204bce <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204d14:	6da6                	ld	s11,72(sp)
ffffffffc0204d16:	54e1                	li	s1,-8
ffffffffc0204d18:	bd5d                	j	ffffffffc0204bce <do_execve+0x378>
ffffffffc0204d1a:	00001617          	auipc	a2,0x1
ffffffffc0204d1e:	7fe60613          	addi	a2,a2,2046 # ffffffffc0206518 <etext+0xd84>
ffffffffc0204d22:	07100593          	li	a1,113
ffffffffc0204d26:	00002517          	auipc	a0,0x2
ffffffffc0204d2a:	81a50513          	addi	a0,a0,-2022 # ffffffffc0206540 <etext+0xdac>
ffffffffc0204d2e:	f18fb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0204d32:	00001617          	auipc	a2,0x1
ffffffffc0204d36:	7e660613          	addi	a2,a2,2022 # ffffffffc0206518 <etext+0xd84>
ffffffffc0204d3a:	07100593          	li	a1,113
ffffffffc0204d3e:	00002517          	auipc	a0,0x2
ffffffffc0204d42:	80250513          	addi	a0,a0,-2046 # ffffffffc0206540 <etext+0xdac>
ffffffffc0204d46:	f122                	sd	s0,160(sp)
ffffffffc0204d48:	e152                	sd	s4,128(sp)
ffffffffc0204d4a:	e4ee                	sd	s11,72(sp)
ffffffffc0204d4c:	efafb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d50:	00002617          	auipc	a2,0x2
ffffffffc0204d54:	87060613          	addi	a2,a2,-1936 # ffffffffc02065c0 <etext+0xe2c>
ffffffffc0204d58:	2d700593          	li	a1,727
ffffffffc0204d5c:	00002517          	auipc	a0,0x2
ffffffffc0204d60:	1f450513          	addi	a0,a0,500 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204d64:	e4ee                	sd	s11,72(sp)
ffffffffc0204d66:	ee0fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d6a:	00002697          	auipc	a3,0x2
ffffffffc0204d6e:	4ee68693          	addi	a3,a3,1262 # ffffffffc0207258 <etext+0x1ac4>
ffffffffc0204d72:	00001617          	auipc	a2,0x1
ffffffffc0204d76:	3f660613          	addi	a2,a2,1014 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204d7a:	2d200593          	li	a1,722
ffffffffc0204d7e:	00002517          	auipc	a0,0x2
ffffffffc0204d82:	1d250513          	addi	a0,a0,466 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204d86:	e4ee                	sd	s11,72(sp)
ffffffffc0204d88:	ebefb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d8c:	00002697          	auipc	a3,0x2
ffffffffc0204d90:	48468693          	addi	a3,a3,1156 # ffffffffc0207210 <etext+0x1a7c>
ffffffffc0204d94:	00001617          	auipc	a2,0x1
ffffffffc0204d98:	3d460613          	addi	a2,a2,980 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204d9c:	2d100593          	li	a1,721
ffffffffc0204da0:	00002517          	auipc	a0,0x2
ffffffffc0204da4:	1b050513          	addi	a0,a0,432 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204da8:	e4ee                	sd	s11,72(sp)
ffffffffc0204daa:	e9cfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204dae:	00002697          	auipc	a3,0x2
ffffffffc0204db2:	41a68693          	addi	a3,a3,1050 # ffffffffc02071c8 <etext+0x1a34>
ffffffffc0204db6:	00001617          	auipc	a2,0x1
ffffffffc0204dba:	3b260613          	addi	a2,a2,946 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204dbe:	2d000593          	li	a1,720
ffffffffc0204dc2:	00002517          	auipc	a0,0x2
ffffffffc0204dc6:	18e50513          	addi	a0,a0,398 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204dca:	e4ee                	sd	s11,72(sp)
ffffffffc0204dcc:	e7afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204dd0:	00002697          	auipc	a3,0x2
ffffffffc0204dd4:	3b068693          	addi	a3,a3,944 # ffffffffc0207180 <etext+0x19ec>
ffffffffc0204dd8:	00001617          	auipc	a2,0x1
ffffffffc0204ddc:	39060613          	addi	a2,a2,912 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0204de0:	2cf00593          	li	a1,719
ffffffffc0204de4:	00002517          	auipc	a0,0x2
ffffffffc0204de8:	16c50513          	addi	a0,a0,364 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204dec:	e4ee                	sd	s11,72(sp)
ffffffffc0204dee:	e58fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204df2 <do_yield>:
    current->need_resched = 1;
ffffffffc0204df2:	00097797          	auipc	a5,0x97
ffffffffc0204df6:	9c67b783          	ld	a5,-1594(a5) # ffffffffc029b7b8 <current>
ffffffffc0204dfa:	4705                	li	a4,1
}
ffffffffc0204dfc:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204dfe:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e00:	8082                	ret

ffffffffc0204e02 <do_wait>:
    if (code_store != NULL)
ffffffffc0204e02:	c59d                	beqz	a1,ffffffffc0204e30 <do_wait+0x2e>
{
ffffffffc0204e04:	1101                	addi	sp,sp,-32
ffffffffc0204e06:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204e08:	00097517          	auipc	a0,0x97
ffffffffc0204e0c:	9b053503          	ld	a0,-1616(a0) # ffffffffc029b7b8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e10:	4685                	li	a3,1
ffffffffc0204e12:	4611                	li	a2,4
ffffffffc0204e14:	7508                	ld	a0,40(a0)
{
ffffffffc0204e16:	ec06                	sd	ra,24(sp)
ffffffffc0204e18:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e1a:	f6bfe0ef          	jal	ffffffffc0203d84 <user_mem_check>
ffffffffc0204e1e:	6702                	ld	a4,0(sp)
ffffffffc0204e20:	67a2                	ld	a5,8(sp)
ffffffffc0204e22:	c909                	beqz	a0,ffffffffc0204e34 <do_wait+0x32>
}
ffffffffc0204e24:	60e2                	ld	ra,24(sp)
ffffffffc0204e26:	85be                	mv	a1,a5
ffffffffc0204e28:	853a                	mv	a0,a4
ffffffffc0204e2a:	6105                	addi	sp,sp,32
ffffffffc0204e2c:	f24ff06f          	j	ffffffffc0204550 <do_wait.part.0>
ffffffffc0204e30:	f20ff06f          	j	ffffffffc0204550 <do_wait.part.0>
ffffffffc0204e34:	60e2                	ld	ra,24(sp)
ffffffffc0204e36:	5575                	li	a0,-3
ffffffffc0204e38:	6105                	addi	sp,sp,32
ffffffffc0204e3a:	8082                	ret

ffffffffc0204e3c <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e3c:	6789                	lui	a5,0x2
ffffffffc0204e3e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e42:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc0204e44:	06e7e463          	bltu	a5,a4,ffffffffc0204eac <do_kill+0x70>
{
ffffffffc0204e48:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e4a:	45a9                	li	a1,10
{
ffffffffc0204e4c:	ec06                	sd	ra,24(sp)
ffffffffc0204e4e:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e50:	484000ef          	jal	ffffffffc02052d4 <hash32>
ffffffffc0204e54:	02051793          	slli	a5,a0,0x20
ffffffffc0204e58:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e5c:	00093797          	auipc	a5,0x93
ffffffffc0204e60:	8dc78793          	addi	a5,a5,-1828 # ffffffffc0297738 <hash_list>
ffffffffc0204e64:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204e66:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e68:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e6a:	a029                	j	ffffffffc0204e74 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204e6c:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204e70:	00c70963          	beq	a4,a2,ffffffffc0204e82 <do_kill+0x46>
ffffffffc0204e74:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204e76:	fea69be3          	bne	a3,a0,ffffffffc0204e6c <do_kill+0x30>
}
ffffffffc0204e7a:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204e7c:	5575                	li	a0,-3
}
ffffffffc0204e7e:	6105                	addi	sp,sp,32
ffffffffc0204e80:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204e82:	fd852703          	lw	a4,-40(a0)
ffffffffc0204e86:	00177693          	andi	a3,a4,1
ffffffffc0204e8a:	e29d                	bnez	a3,ffffffffc0204eb0 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204e8c:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204e8e:	00176713          	ori	a4,a4,1
ffffffffc0204e92:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204e96:	0006c663          	bltz	a3,ffffffffc0204ea2 <do_kill+0x66>
            return 0;
ffffffffc0204e9a:	4501                	li	a0,0
}
ffffffffc0204e9c:	60e2                	ld	ra,24(sp)
ffffffffc0204e9e:	6105                	addi	sp,sp,32
ffffffffc0204ea0:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204ea2:	f2850513          	addi	a0,a0,-216
ffffffffc0204ea6:	232000ef          	jal	ffffffffc02050d8 <wakeup_proc>
ffffffffc0204eaa:	bfc5                	j	ffffffffc0204e9a <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204eac:	5575                	li	a0,-3
}
ffffffffc0204eae:	8082                	ret
        return -E_KILLED;
ffffffffc0204eb0:	555d                	li	a0,-9
ffffffffc0204eb2:	b7ed                	j	ffffffffc0204e9c <do_kill+0x60>

ffffffffc0204eb4 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204eb4:	1101                	addi	sp,sp,-32
ffffffffc0204eb6:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204eb8:	00097797          	auipc	a5,0x97
ffffffffc0204ebc:	88078793          	addi	a5,a5,-1920 # ffffffffc029b738 <proc_list>
ffffffffc0204ec0:	ec06                	sd	ra,24(sp)
ffffffffc0204ec2:	e822                	sd	s0,16(sp)
ffffffffc0204ec4:	e04a                	sd	s2,0(sp)
ffffffffc0204ec6:	00093497          	auipc	s1,0x93
ffffffffc0204eca:	87248493          	addi	s1,s1,-1934 # ffffffffc0297738 <hash_list>
ffffffffc0204ece:	e79c                	sd	a5,8(a5)
ffffffffc0204ed0:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204ed2:	00097717          	auipc	a4,0x97
ffffffffc0204ed6:	86670713          	addi	a4,a4,-1946 # ffffffffc029b738 <proc_list>
ffffffffc0204eda:	87a6                	mv	a5,s1
ffffffffc0204edc:	e79c                	sd	a5,8(a5)
ffffffffc0204ede:	e39c                	sd	a5,0(a5)
ffffffffc0204ee0:	07c1                	addi	a5,a5,16
ffffffffc0204ee2:	fee79de3          	bne	a5,a4,ffffffffc0204edc <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204ee6:	f4bfe0ef          	jal	ffffffffc0203e30 <alloc_proc>
ffffffffc0204eea:	00097917          	auipc	s2,0x97
ffffffffc0204eee:	8de90913          	addi	s2,s2,-1826 # ffffffffc029b7c8 <idleproc>
ffffffffc0204ef2:	00a93023          	sd	a0,0(s2)
ffffffffc0204ef6:	10050363          	beqz	a0,ffffffffc0204ffc <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204efa:	4789                	li	a5,2
ffffffffc0204efc:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204efe:	00003797          	auipc	a5,0x3
ffffffffc0204f02:	10278793          	addi	a5,a5,258 # ffffffffc0208000 <bootstack>
ffffffffc0204f06:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f08:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204f0c:	4785                	li	a5,1
ffffffffc0204f0e:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f10:	4641                	li	a2,16
ffffffffc0204f12:	8522                	mv	a0,s0
ffffffffc0204f14:	4581                	li	a1,0
ffffffffc0204f16:	055000ef          	jal	ffffffffc020576a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f1a:	8522                	mv	a0,s0
ffffffffc0204f1c:	463d                	li	a2,15
ffffffffc0204f1e:	00002597          	auipc	a1,0x2
ffffffffc0204f22:	39a58593          	addi	a1,a1,922 # ffffffffc02072b8 <etext+0x1b24>
ffffffffc0204f26:	057000ef          	jal	ffffffffc020577c <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f2a:	00097797          	auipc	a5,0x97
ffffffffc0204f2e:	8867a783          	lw	a5,-1914(a5) # ffffffffc029b7b0 <nr_process>

    current = idleproc;
ffffffffc0204f32:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f36:	4601                	li	a2,0
    nr_process++;
ffffffffc0204f38:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f3a:	4581                	li	a1,0
ffffffffc0204f3c:	fffff517          	auipc	a0,0xfffff
ffffffffc0204f40:	7f650513          	addi	a0,a0,2038 # ffffffffc0204732 <init_main>
    current = idleproc;
ffffffffc0204f44:	00097697          	auipc	a3,0x97
ffffffffc0204f48:	86e6ba23          	sd	a4,-1932(a3) # ffffffffc029b7b8 <current>
    nr_process++;
ffffffffc0204f4c:	00097717          	auipc	a4,0x97
ffffffffc0204f50:	86f72223          	sw	a5,-1948(a4) # ffffffffc029b7b0 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f54:	c68ff0ef          	jal	ffffffffc02043bc <kernel_thread>
ffffffffc0204f58:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204f5a:	08a05563          	blez	a0,ffffffffc0204fe4 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f5e:	6789                	lui	a5,0x2
ffffffffc0204f60:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc0204f62:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f66:	02e7e463          	bltu	a5,a4,ffffffffc0204f8e <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f6a:	45a9                	li	a1,10
ffffffffc0204f6c:	368000ef          	jal	ffffffffc02052d4 <hash32>
ffffffffc0204f70:	02051713          	slli	a4,a0,0x20
ffffffffc0204f74:	01c75793          	srli	a5,a4,0x1c
ffffffffc0204f78:	00f486b3          	add	a3,s1,a5
ffffffffc0204f7c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f7e:	a029                	j	ffffffffc0204f88 <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0204f80:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f84:	04870d63          	beq	a4,s0,ffffffffc0204fde <proc_init+0x12a>
    return listelm->next;
ffffffffc0204f88:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f8a:	fef69be3          	bne	a3,a5,ffffffffc0204f80 <proc_init+0xcc>
    return NULL;
ffffffffc0204f8e:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f90:	0b478413          	addi	s0,a5,180
ffffffffc0204f94:	4641                	li	a2,16
ffffffffc0204f96:	4581                	li	a1,0
ffffffffc0204f98:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204f9a:	00097717          	auipc	a4,0x97
ffffffffc0204f9e:	82f73323          	sd	a5,-2010(a4) # ffffffffc029b7c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fa2:	7c8000ef          	jal	ffffffffc020576a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fa6:	8522                	mv	a0,s0
ffffffffc0204fa8:	463d                	li	a2,15
ffffffffc0204faa:	00002597          	auipc	a1,0x2
ffffffffc0204fae:	33658593          	addi	a1,a1,822 # ffffffffc02072e0 <etext+0x1b4c>
ffffffffc0204fb2:	7ca000ef          	jal	ffffffffc020577c <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204fb6:	00093783          	ld	a5,0(s2)
ffffffffc0204fba:	cfad                	beqz	a5,ffffffffc0205034 <proc_init+0x180>
ffffffffc0204fbc:	43dc                	lw	a5,4(a5)
ffffffffc0204fbe:	ebbd                	bnez	a5,ffffffffc0205034 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204fc0:	00097797          	auipc	a5,0x97
ffffffffc0204fc4:	8007b783          	ld	a5,-2048(a5) # ffffffffc029b7c0 <initproc>
ffffffffc0204fc8:	c7b1                	beqz	a5,ffffffffc0205014 <proc_init+0x160>
ffffffffc0204fca:	43d8                	lw	a4,4(a5)
ffffffffc0204fcc:	4785                	li	a5,1
ffffffffc0204fce:	04f71363          	bne	a4,a5,ffffffffc0205014 <proc_init+0x160>
}
ffffffffc0204fd2:	60e2                	ld	ra,24(sp)
ffffffffc0204fd4:	6442                	ld	s0,16(sp)
ffffffffc0204fd6:	64a2                	ld	s1,8(sp)
ffffffffc0204fd8:	6902                	ld	s2,0(sp)
ffffffffc0204fda:	6105                	addi	sp,sp,32
ffffffffc0204fdc:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204fde:	f2878793          	addi	a5,a5,-216
ffffffffc0204fe2:	b77d                	j	ffffffffc0204f90 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0204fe4:	00002617          	auipc	a2,0x2
ffffffffc0204fe8:	2dc60613          	addi	a2,a2,732 # ffffffffc02072c0 <etext+0x1b2c>
ffffffffc0204fec:	3fa00593          	li	a1,1018
ffffffffc0204ff0:	00002517          	auipc	a0,0x2
ffffffffc0204ff4:	f6050513          	addi	a0,a0,-160 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0204ff8:	c4efb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204ffc:	00002617          	auipc	a2,0x2
ffffffffc0205000:	2a460613          	addi	a2,a2,676 # ffffffffc02072a0 <etext+0x1b0c>
ffffffffc0205004:	3eb00593          	li	a1,1003
ffffffffc0205008:	00002517          	auipc	a0,0x2
ffffffffc020500c:	f4850513          	addi	a0,a0,-184 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0205010:	c36fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205014:	00002697          	auipc	a3,0x2
ffffffffc0205018:	2fc68693          	addi	a3,a3,764 # ffffffffc0207310 <etext+0x1b7c>
ffffffffc020501c:	00001617          	auipc	a2,0x1
ffffffffc0205020:	14c60613          	addi	a2,a2,332 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0205024:	40100593          	li	a1,1025
ffffffffc0205028:	00002517          	auipc	a0,0x2
ffffffffc020502c:	f2850513          	addi	a0,a0,-216 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0205030:	c16fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205034:	00002697          	auipc	a3,0x2
ffffffffc0205038:	2b468693          	addi	a3,a3,692 # ffffffffc02072e8 <etext+0x1b54>
ffffffffc020503c:	00001617          	auipc	a2,0x1
ffffffffc0205040:	12c60613          	addi	a2,a2,300 # ffffffffc0206168 <etext+0x9d4>
ffffffffc0205044:	40000593          	li	a1,1024
ffffffffc0205048:	00002517          	auipc	a0,0x2
ffffffffc020504c:	f0850513          	addi	a0,a0,-248 # ffffffffc0206f50 <etext+0x17bc>
ffffffffc0205050:	bf6fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205054 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205054:	1141                	addi	sp,sp,-16
ffffffffc0205056:	e022                	sd	s0,0(sp)
ffffffffc0205058:	e406                	sd	ra,8(sp)
ffffffffc020505a:	00096417          	auipc	s0,0x96
ffffffffc020505e:	75e40413          	addi	s0,s0,1886 # ffffffffc029b7b8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205062:	6018                	ld	a4,0(s0)
ffffffffc0205064:	6f1c                	ld	a5,24(a4)
ffffffffc0205066:	dffd                	beqz	a5,ffffffffc0205064 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205068:	104000ef          	jal	ffffffffc020516c <schedule>
ffffffffc020506c:	bfdd                	j	ffffffffc0205062 <cpu_idle+0xe>

ffffffffc020506e <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020506e:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205072:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205076:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205078:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020507a:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020507e:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205082:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205086:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020508a:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020508e:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205092:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205096:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020509a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020509e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02050a2:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02050a6:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02050aa:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02050ac:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02050ae:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02050b2:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02050b6:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02050ba:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02050be:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02050c2:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02050c6:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02050ca:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02050ce:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02050d2:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02050d6:	8082                	ret

ffffffffc02050d8 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02050d8:	4118                	lw	a4,0(a0)
{
ffffffffc02050da:	1101                	addi	sp,sp,-32
ffffffffc02050dc:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02050de:	478d                	li	a5,3
ffffffffc02050e0:	06f70763          	beq	a4,a5,ffffffffc020514e <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02050e4:	100027f3          	csrr	a5,sstatus
ffffffffc02050e8:	8b89                	andi	a5,a5,2
ffffffffc02050ea:	eb91                	bnez	a5,ffffffffc02050fe <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02050ec:	4789                	li	a5,2
ffffffffc02050ee:	02f70763          	beq	a4,a5,ffffffffc020511c <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02050f2:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc02050f4:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc02050f6:	0e052623          	sw	zero,236(a0)
}
ffffffffc02050fa:	6105                	addi	sp,sp,32
ffffffffc02050fc:	8082                	ret
        intr_disable();
ffffffffc02050fe:	e42a                	sd	a0,8(sp)
ffffffffc0205100:	805fb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205104:	6522                	ld	a0,8(sp)
ffffffffc0205106:	4789                	li	a5,2
ffffffffc0205108:	4118                	lw	a4,0(a0)
ffffffffc020510a:	02f70663          	beq	a4,a5,ffffffffc0205136 <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc020510e:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205110:	0e052623          	sw	zero,236(a0)
}
ffffffffc0205114:	60e2                	ld	ra,24(sp)
ffffffffc0205116:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205118:	fe6fb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc020511c:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc020511e:	00002617          	auipc	a2,0x2
ffffffffc0205122:	25260613          	addi	a2,a2,594 # ffffffffc0207370 <etext+0x1bdc>
ffffffffc0205126:	45d1                	li	a1,20
ffffffffc0205128:	00002517          	auipc	a0,0x2
ffffffffc020512c:	23050513          	addi	a0,a0,560 # ffffffffc0207358 <etext+0x1bc4>
}
ffffffffc0205130:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc0205132:	b7efb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc0205136:	00002617          	auipc	a2,0x2
ffffffffc020513a:	23a60613          	addi	a2,a2,570 # ffffffffc0207370 <etext+0x1bdc>
ffffffffc020513e:	45d1                	li	a1,20
ffffffffc0205140:	00002517          	auipc	a0,0x2
ffffffffc0205144:	21850513          	addi	a0,a0,536 # ffffffffc0207358 <etext+0x1bc4>
ffffffffc0205148:	b68fb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc020514c:	b7e1                	j	ffffffffc0205114 <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020514e:	00002697          	auipc	a3,0x2
ffffffffc0205152:	1ea68693          	addi	a3,a3,490 # ffffffffc0207338 <etext+0x1ba4>
ffffffffc0205156:	00001617          	auipc	a2,0x1
ffffffffc020515a:	01260613          	addi	a2,a2,18 # ffffffffc0206168 <etext+0x9d4>
ffffffffc020515e:	45a5                	li	a1,9
ffffffffc0205160:	00002517          	auipc	a0,0x2
ffffffffc0205164:	1f850513          	addi	a0,a0,504 # ffffffffc0207358 <etext+0x1bc4>
ffffffffc0205168:	adefb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020516c <schedule>:

void schedule(void)
{
ffffffffc020516c:	1101                	addi	sp,sp,-32
ffffffffc020516e:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205170:	100027f3          	csrr	a5,sstatus
ffffffffc0205174:	8b89                	andi	a5,a5,2
ffffffffc0205176:	4301                	li	t1,0
ffffffffc0205178:	e3c1                	bnez	a5,ffffffffc02051f8 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020517a:	00096897          	auipc	a7,0x96
ffffffffc020517e:	63e8b883          	ld	a7,1598(a7) # ffffffffc029b7b8 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205182:	00096517          	auipc	a0,0x96
ffffffffc0205186:	64653503          	ld	a0,1606(a0) # ffffffffc029b7c8 <idleproc>
        current->need_resched = 0;
ffffffffc020518a:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020518e:	04a88f63          	beq	a7,a0,ffffffffc02051ec <schedule+0x80>
ffffffffc0205192:	0c888693          	addi	a3,a7,200
ffffffffc0205196:	00096617          	auipc	a2,0x96
ffffffffc020519a:	5a260613          	addi	a2,a2,1442 # ffffffffc029b738 <proc_list>
        le = last;
ffffffffc020519e:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02051a0:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02051a2:	4809                	li	a6,2
ffffffffc02051a4:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02051a6:	00c78863          	beq	a5,a2,ffffffffc02051b6 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc02051aa:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02051ae:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02051b2:	03070363          	beq	a4,a6,ffffffffc02051d8 <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02051b6:	fef697e3          	bne	a3,a5,ffffffffc02051a4 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051ba:	ed99                	bnez	a1,ffffffffc02051d8 <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02051bc:	451c                	lw	a5,8(a0)
ffffffffc02051be:	2785                	addiw	a5,a5,1
ffffffffc02051c0:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02051c2:	00a88663          	beq	a7,a0,ffffffffc02051ce <schedule+0x62>
ffffffffc02051c6:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc02051c8:	dddfe0ef          	jal	ffffffffc0203fa4 <proc_run>
ffffffffc02051cc:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc02051ce:	00031b63          	bnez	t1,ffffffffc02051e4 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051d2:	60e2                	ld	ra,24(sp)
ffffffffc02051d4:	6105                	addi	sp,sp,32
ffffffffc02051d6:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051d8:	4198                	lw	a4,0(a1)
ffffffffc02051da:	4789                	li	a5,2
ffffffffc02051dc:	fef710e3          	bne	a4,a5,ffffffffc02051bc <schedule+0x50>
ffffffffc02051e0:	852e                	mv	a0,a1
ffffffffc02051e2:	bfe9                	j	ffffffffc02051bc <schedule+0x50>
}
ffffffffc02051e4:	60e2                	ld	ra,24(sp)
ffffffffc02051e6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051e8:	f16fb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02051ec:	00096617          	auipc	a2,0x96
ffffffffc02051f0:	54c60613          	addi	a2,a2,1356 # ffffffffc029b738 <proc_list>
ffffffffc02051f4:	86b2                	mv	a3,a2
ffffffffc02051f6:	b765                	j	ffffffffc020519e <schedule+0x32>
        intr_disable();
ffffffffc02051f8:	f0cfb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02051fc:	4305                	li	t1,1
ffffffffc02051fe:	bfb5                	j	ffffffffc020517a <schedule+0xe>

ffffffffc0205200 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205200:	00096797          	auipc	a5,0x96
ffffffffc0205204:	5b87b783          	ld	a5,1464(a5) # ffffffffc029b7b8 <current>
}
ffffffffc0205208:	43c8                	lw	a0,4(a5)
ffffffffc020520a:	8082                	ret

ffffffffc020520c <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020520c:	4501                	li	a0,0
ffffffffc020520e:	8082                	ret

ffffffffc0205210 <sys_putc>:
    cputchar(c);
ffffffffc0205210:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205212:	1141                	addi	sp,sp,-16
ffffffffc0205214:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205216:	fb3fa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc020521a:	60a2                	ld	ra,8(sp)
ffffffffc020521c:	4501                	li	a0,0
ffffffffc020521e:	0141                	addi	sp,sp,16
ffffffffc0205220:	8082                	ret

ffffffffc0205222 <sys_kill>:
    return do_kill(pid);
ffffffffc0205222:	4108                	lw	a0,0(a0)
ffffffffc0205224:	c19ff06f          	j	ffffffffc0204e3c <do_kill>

ffffffffc0205228 <sys_yield>:
    return do_yield();
ffffffffc0205228:	bcbff06f          	j	ffffffffc0204df2 <do_yield>

ffffffffc020522c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020522c:	6d14                	ld	a3,24(a0)
ffffffffc020522e:	6910                	ld	a2,16(a0)
ffffffffc0205230:	650c                	ld	a1,8(a0)
ffffffffc0205232:	6108                	ld	a0,0(a0)
ffffffffc0205234:	e22ff06f          	j	ffffffffc0204856 <do_execve>

ffffffffc0205238 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205238:	650c                	ld	a1,8(a0)
ffffffffc020523a:	4108                	lw	a0,0(a0)
ffffffffc020523c:	bc7ff06f          	j	ffffffffc0204e02 <do_wait>

ffffffffc0205240 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205240:	00096797          	auipc	a5,0x96
ffffffffc0205244:	5787b783          	ld	a5,1400(a5) # ffffffffc029b7b8 <current>
    return do_fork(0, stack, tf);
ffffffffc0205248:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc020524a:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020524c:	6a0c                	ld	a1,16(a2)
ffffffffc020524e:	db9fe06f          	j	ffffffffc0204006 <do_fork>

ffffffffc0205252 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205252:	4108                	lw	a0,0(a0)
ffffffffc0205254:	9b8ff06f          	j	ffffffffc020440c <do_exit>

ffffffffc0205258 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc0205258:	00096697          	auipc	a3,0x96
ffffffffc020525c:	5606b683          	ld	a3,1376(a3) # ffffffffc029b7b8 <current>
syscall(void) {
ffffffffc0205260:	715d                	addi	sp,sp,-80
ffffffffc0205262:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205264:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205266:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205268:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020526a:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020526c:	02d7ec63          	bltu	a5,a3,ffffffffc02052a4 <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc0205270:	00002797          	auipc	a5,0x2
ffffffffc0205274:	34878793          	addi	a5,a5,840 # ffffffffc02075b8 <syscalls>
ffffffffc0205278:	00369613          	slli	a2,a3,0x3
ffffffffc020527c:	97b2                	add	a5,a5,a2
ffffffffc020527e:	639c                	ld	a5,0(a5)
ffffffffc0205280:	c395                	beqz	a5,ffffffffc02052a4 <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc0205282:	7028                	ld	a0,96(s0)
ffffffffc0205284:	742c                	ld	a1,104(s0)
ffffffffc0205286:	7830                	ld	a2,112(s0)
ffffffffc0205288:	7c34                	ld	a3,120(s0)
ffffffffc020528a:	6c38                	ld	a4,88(s0)
ffffffffc020528c:	f02a                	sd	a0,32(sp)
ffffffffc020528e:	f42e                	sd	a1,40(sp)
ffffffffc0205290:	f832                	sd	a2,48(sp)
ffffffffc0205292:	fc36                	sd	a3,56(sp)
ffffffffc0205294:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205296:	0828                	addi	a0,sp,24
ffffffffc0205298:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020529a:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020529c:	e828                	sd	a0,80(s0)
}
ffffffffc020529e:	6406                	ld	s0,64(sp)
ffffffffc02052a0:	6161                	addi	sp,sp,80
ffffffffc02052a2:	8082                	ret
    print_trapframe(tf);
ffffffffc02052a4:	8522                	mv	a0,s0
ffffffffc02052a6:	e436                	sd	a3,8(sp)
ffffffffc02052a8:	84dfb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02052ac:	00096797          	auipc	a5,0x96
ffffffffc02052b0:	50c7b783          	ld	a5,1292(a5) # ffffffffc029b7b8 <current>
ffffffffc02052b4:	66a2                	ld	a3,8(sp)
ffffffffc02052b6:	00002617          	auipc	a2,0x2
ffffffffc02052ba:	0da60613          	addi	a2,a2,218 # ffffffffc0207390 <etext+0x1bfc>
ffffffffc02052be:	43d8                	lw	a4,4(a5)
ffffffffc02052c0:	06200593          	li	a1,98
ffffffffc02052c4:	0b478793          	addi	a5,a5,180
ffffffffc02052c8:	00002517          	auipc	a0,0x2
ffffffffc02052cc:	0f850513          	addi	a0,a0,248 # ffffffffc02073c0 <etext+0x1c2c>
ffffffffc02052d0:	976fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02052d4 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02052d4:	9e3707b7          	lui	a5,0x9e370
ffffffffc02052d8:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e365e29>
ffffffffc02052da:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc02052de:	02000513          	li	a0,32
ffffffffc02052e2:	9d0d                	subw	a0,a0,a1
}
ffffffffc02052e4:	00a7d53b          	srlw	a0,a5,a0
ffffffffc02052e8:	8082                	ret

ffffffffc02052ea <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052ea:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02052ec:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052f0:	f022                	sd	s0,32(sp)
ffffffffc02052f2:	ec26                	sd	s1,24(sp)
ffffffffc02052f4:	e84a                	sd	s2,16(sp)
ffffffffc02052f6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02052f8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052fc:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02052fe:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205302:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205306:	84aa                	mv	s1,a0
ffffffffc0205308:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc020530a:	03067d63          	bgeu	a2,a6,ffffffffc0205344 <printnum+0x5a>
ffffffffc020530e:	e44e                	sd	s3,8(sp)
ffffffffc0205310:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205312:	4785                	li	a5,1
ffffffffc0205314:	00e7d763          	bge	a5,a4,ffffffffc0205322 <printnum+0x38>
            putch(padc, putdat);
ffffffffc0205318:	85ca                	mv	a1,s2
ffffffffc020531a:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc020531c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020531e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205320:	fc65                	bnez	s0,ffffffffc0205318 <printnum+0x2e>
ffffffffc0205322:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205324:	00002797          	auipc	a5,0x2
ffffffffc0205328:	0b478793          	addi	a5,a5,180 # ffffffffc02073d8 <etext+0x1c44>
ffffffffc020532c:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020532e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205330:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0205334:	70a2                	ld	ra,40(sp)
ffffffffc0205336:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205338:	85ca                	mv	a1,s2
ffffffffc020533a:	87a6                	mv	a5,s1
}
ffffffffc020533c:	6942                	ld	s2,16(sp)
ffffffffc020533e:	64e2                	ld	s1,24(sp)
ffffffffc0205340:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205342:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205344:	03065633          	divu	a2,a2,a6
ffffffffc0205348:	8722                	mv	a4,s0
ffffffffc020534a:	fa1ff0ef          	jal	ffffffffc02052ea <printnum>
ffffffffc020534e:	bfd9                	j	ffffffffc0205324 <printnum+0x3a>

ffffffffc0205350 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205350:	7119                	addi	sp,sp,-128
ffffffffc0205352:	f4a6                	sd	s1,104(sp)
ffffffffc0205354:	f0ca                	sd	s2,96(sp)
ffffffffc0205356:	ecce                	sd	s3,88(sp)
ffffffffc0205358:	e8d2                	sd	s4,80(sp)
ffffffffc020535a:	e4d6                	sd	s5,72(sp)
ffffffffc020535c:	e0da                	sd	s6,64(sp)
ffffffffc020535e:	f862                	sd	s8,48(sp)
ffffffffc0205360:	fc86                	sd	ra,120(sp)
ffffffffc0205362:	f8a2                	sd	s0,112(sp)
ffffffffc0205364:	fc5e                	sd	s7,56(sp)
ffffffffc0205366:	f466                	sd	s9,40(sp)
ffffffffc0205368:	f06a                	sd	s10,32(sp)
ffffffffc020536a:	ec6e                	sd	s11,24(sp)
ffffffffc020536c:	84aa                	mv	s1,a0
ffffffffc020536e:	8c32                	mv	s8,a2
ffffffffc0205370:	8a36                	mv	s4,a3
ffffffffc0205372:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205374:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205378:	05500b13          	li	s6,85
ffffffffc020537c:	00002a97          	auipc	s5,0x2
ffffffffc0205380:	33ca8a93          	addi	s5,s5,828 # ffffffffc02076b8 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205384:	000c4503          	lbu	a0,0(s8)
ffffffffc0205388:	001c0413          	addi	s0,s8,1
ffffffffc020538c:	01350a63          	beq	a0,s3,ffffffffc02053a0 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0205390:	cd0d                	beqz	a0,ffffffffc02053ca <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0205392:	85ca                	mv	a1,s2
ffffffffc0205394:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205396:	00044503          	lbu	a0,0(s0)
ffffffffc020539a:	0405                	addi	s0,s0,1
ffffffffc020539c:	ff351ae3          	bne	a0,s3,ffffffffc0205390 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02053a0:	5cfd                	li	s9,-1
ffffffffc02053a2:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02053a4:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02053a8:	4b81                	li	s7,0
ffffffffc02053aa:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053ac:	00044683          	lbu	a3,0(s0)
ffffffffc02053b0:	00140c13          	addi	s8,s0,1
ffffffffc02053b4:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02053b8:	0ff5f593          	zext.b	a1,a1
ffffffffc02053bc:	02bb6663          	bltu	s6,a1,ffffffffc02053e8 <vprintfmt+0x98>
ffffffffc02053c0:	058a                	slli	a1,a1,0x2
ffffffffc02053c2:	95d6                	add	a1,a1,s5
ffffffffc02053c4:	4198                	lw	a4,0(a1)
ffffffffc02053c6:	9756                	add	a4,a4,s5
ffffffffc02053c8:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02053ca:	70e6                	ld	ra,120(sp)
ffffffffc02053cc:	7446                	ld	s0,112(sp)
ffffffffc02053ce:	74a6                	ld	s1,104(sp)
ffffffffc02053d0:	7906                	ld	s2,96(sp)
ffffffffc02053d2:	69e6                	ld	s3,88(sp)
ffffffffc02053d4:	6a46                	ld	s4,80(sp)
ffffffffc02053d6:	6aa6                	ld	s5,72(sp)
ffffffffc02053d8:	6b06                	ld	s6,64(sp)
ffffffffc02053da:	7be2                	ld	s7,56(sp)
ffffffffc02053dc:	7c42                	ld	s8,48(sp)
ffffffffc02053de:	7ca2                	ld	s9,40(sp)
ffffffffc02053e0:	7d02                	ld	s10,32(sp)
ffffffffc02053e2:	6de2                	ld	s11,24(sp)
ffffffffc02053e4:	6109                	addi	sp,sp,128
ffffffffc02053e6:	8082                	ret
            putch('%', putdat);
ffffffffc02053e8:	85ca                	mv	a1,s2
ffffffffc02053ea:	02500513          	li	a0,37
ffffffffc02053ee:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02053f0:	fff44783          	lbu	a5,-1(s0)
ffffffffc02053f4:	02500713          	li	a4,37
ffffffffc02053f8:	8c22                	mv	s8,s0
ffffffffc02053fa:	f8e785e3          	beq	a5,a4,ffffffffc0205384 <vprintfmt+0x34>
ffffffffc02053fe:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0205402:	1c7d                	addi	s8,s8,-1
ffffffffc0205404:	fee79de3          	bne	a5,a4,ffffffffc02053fe <vprintfmt+0xae>
ffffffffc0205408:	bfb5                	j	ffffffffc0205384 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020540a:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc020540e:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0205410:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205414:	fd06071b          	addiw	a4,a2,-48
ffffffffc0205418:	24e56a63          	bltu	a0,a4,ffffffffc020566c <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc020541c:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020541e:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0205420:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205424:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205428:	0197073b          	addw	a4,a4,s9
ffffffffc020542c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205430:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205432:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205436:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205438:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020543c:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0205440:	feb570e3          	bgeu	a0,a1,ffffffffc0205420 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0205444:	f60d54e3          	bgez	s10,ffffffffc02053ac <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0205448:	8d66                	mv	s10,s9
ffffffffc020544a:	5cfd                	li	s9,-1
ffffffffc020544c:	b785                	j	ffffffffc02053ac <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020544e:	8db6                	mv	s11,a3
ffffffffc0205450:	8462                	mv	s0,s8
ffffffffc0205452:	bfa9                	j	ffffffffc02053ac <vprintfmt+0x5c>
ffffffffc0205454:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0205456:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0205458:	bf91                	j	ffffffffc02053ac <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020545a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020545c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205460:	00f74463          	blt	a4,a5,ffffffffc0205468 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205464:	1a078763          	beqz	a5,ffffffffc0205612 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0205468:	000a3603          	ld	a2,0(s4)
ffffffffc020546c:	46c1                	li	a3,16
ffffffffc020546e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205470:	000d879b          	sext.w	a5,s11
ffffffffc0205474:	876a                	mv	a4,s10
ffffffffc0205476:	85ca                	mv	a1,s2
ffffffffc0205478:	8526                	mv	a0,s1
ffffffffc020547a:	e71ff0ef          	jal	ffffffffc02052ea <printnum>
            break;
ffffffffc020547e:	b719                	j	ffffffffc0205384 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0205480:	000a2503          	lw	a0,0(s4)
ffffffffc0205484:	85ca                	mv	a1,s2
ffffffffc0205486:	0a21                	addi	s4,s4,8
ffffffffc0205488:	9482                	jalr	s1
            break;
ffffffffc020548a:	bded                	j	ffffffffc0205384 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020548c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020548e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205492:	00f74463          	blt	a4,a5,ffffffffc020549a <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0205496:	16078963          	beqz	a5,ffffffffc0205608 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020549a:	000a3603          	ld	a2,0(s4)
ffffffffc020549e:	46a9                	li	a3,10
ffffffffc02054a0:	8a2e                	mv	s4,a1
ffffffffc02054a2:	b7f9                	j	ffffffffc0205470 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02054a4:	85ca                	mv	a1,s2
ffffffffc02054a6:	03000513          	li	a0,48
ffffffffc02054aa:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02054ac:	85ca                	mv	a1,s2
ffffffffc02054ae:	07800513          	li	a0,120
ffffffffc02054b2:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02054b4:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02054b8:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02054ba:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02054bc:	bf55                	j	ffffffffc0205470 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02054be:	85ca                	mv	a1,s2
ffffffffc02054c0:	02500513          	li	a0,37
ffffffffc02054c4:	9482                	jalr	s1
            break;
ffffffffc02054c6:	bd7d                	j	ffffffffc0205384 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02054c8:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054cc:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02054ce:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02054d0:	bf95                	j	ffffffffc0205444 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02054d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054d4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02054d8:	00f74463          	blt	a4,a5,ffffffffc02054e0 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02054dc:	12078163          	beqz	a5,ffffffffc02055fe <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02054e0:	000a3603          	ld	a2,0(s4)
ffffffffc02054e4:	46a1                	li	a3,8
ffffffffc02054e6:	8a2e                	mv	s4,a1
ffffffffc02054e8:	b761                	j	ffffffffc0205470 <vprintfmt+0x120>
            if (width < 0)
ffffffffc02054ea:	876a                	mv	a4,s10
ffffffffc02054ec:	000d5363          	bgez	s10,ffffffffc02054f2 <vprintfmt+0x1a2>
ffffffffc02054f0:	4701                	li	a4,0
ffffffffc02054f2:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054f6:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02054f8:	bd55                	j	ffffffffc02053ac <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc02054fa:	000d841b          	sext.w	s0,s11
ffffffffc02054fe:	fd340793          	addi	a5,s0,-45
ffffffffc0205502:	00f037b3          	snez	a5,a5
ffffffffc0205506:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020550a:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc020550e:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205510:	008a0793          	addi	a5,s4,8
ffffffffc0205514:	e43e                	sd	a5,8(sp)
ffffffffc0205516:	100d8c63          	beqz	s11,ffffffffc020562e <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc020551a:	12071363          	bnez	a4,ffffffffc0205640 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020551e:	000dc783          	lbu	a5,0(s11)
ffffffffc0205522:	0007851b          	sext.w	a0,a5
ffffffffc0205526:	c78d                	beqz	a5,ffffffffc0205550 <vprintfmt+0x200>
ffffffffc0205528:	0d85                	addi	s11,s11,1
ffffffffc020552a:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020552c:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205530:	000cc563          	bltz	s9,ffffffffc020553a <vprintfmt+0x1ea>
ffffffffc0205534:	3cfd                	addiw	s9,s9,-1
ffffffffc0205536:	008c8d63          	beq	s9,s0,ffffffffc0205550 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020553a:	020b9663          	bnez	s7,ffffffffc0205566 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc020553e:	85ca                	mv	a1,s2
ffffffffc0205540:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205542:	000dc783          	lbu	a5,0(s11)
ffffffffc0205546:	0d85                	addi	s11,s11,1
ffffffffc0205548:	3d7d                	addiw	s10,s10,-1
ffffffffc020554a:	0007851b          	sext.w	a0,a5
ffffffffc020554e:	f3ed                	bnez	a5,ffffffffc0205530 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0205550:	01a05963          	blez	s10,ffffffffc0205562 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0205554:	85ca                	mv	a1,s2
ffffffffc0205556:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020555a:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc020555c:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc020555e:	fe0d1be3          	bnez	s10,ffffffffc0205554 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205562:	6a22                	ld	s4,8(sp)
ffffffffc0205564:	b505                	j	ffffffffc0205384 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205566:	3781                	addiw	a5,a5,-32
ffffffffc0205568:	fcfa7be3          	bgeu	s4,a5,ffffffffc020553e <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc020556c:	03f00513          	li	a0,63
ffffffffc0205570:	85ca                	mv	a1,s2
ffffffffc0205572:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205574:	000dc783          	lbu	a5,0(s11)
ffffffffc0205578:	0d85                	addi	s11,s11,1
ffffffffc020557a:	3d7d                	addiw	s10,s10,-1
ffffffffc020557c:	0007851b          	sext.w	a0,a5
ffffffffc0205580:	dbe1                	beqz	a5,ffffffffc0205550 <vprintfmt+0x200>
ffffffffc0205582:	fa0cd9e3          	bgez	s9,ffffffffc0205534 <vprintfmt+0x1e4>
ffffffffc0205586:	b7c5                	j	ffffffffc0205566 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0205588:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020558c:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc020558e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205590:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205594:	8fb9                	xor	a5,a5,a4
ffffffffc0205596:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020559a:	02d64563          	blt	a2,a3,ffffffffc02055c4 <vprintfmt+0x274>
ffffffffc020559e:	00002797          	auipc	a5,0x2
ffffffffc02055a2:	27278793          	addi	a5,a5,626 # ffffffffc0207810 <error_string>
ffffffffc02055a6:	00369713          	slli	a4,a3,0x3
ffffffffc02055aa:	97ba                	add	a5,a5,a4
ffffffffc02055ac:	639c                	ld	a5,0(a5)
ffffffffc02055ae:	cb99                	beqz	a5,ffffffffc02055c4 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02055b0:	86be                	mv	a3,a5
ffffffffc02055b2:	00000617          	auipc	a2,0x0
ffffffffc02055b6:	20e60613          	addi	a2,a2,526 # ffffffffc02057c0 <etext+0x2c>
ffffffffc02055ba:	85ca                	mv	a1,s2
ffffffffc02055bc:	8526                	mv	a0,s1
ffffffffc02055be:	0d8000ef          	jal	ffffffffc0205696 <printfmt>
ffffffffc02055c2:	b3c9                	j	ffffffffc0205384 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02055c4:	00002617          	auipc	a2,0x2
ffffffffc02055c8:	e3460613          	addi	a2,a2,-460 # ffffffffc02073f8 <etext+0x1c64>
ffffffffc02055cc:	85ca                	mv	a1,s2
ffffffffc02055ce:	8526                	mv	a0,s1
ffffffffc02055d0:	0c6000ef          	jal	ffffffffc0205696 <printfmt>
ffffffffc02055d4:	bb45                	j	ffffffffc0205384 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02055d6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055d8:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02055dc:	00f74363          	blt	a4,a5,ffffffffc02055e2 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02055e0:	cf81                	beqz	a5,ffffffffc02055f8 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02055e2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02055e6:	02044b63          	bltz	s0,ffffffffc020561c <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02055ea:	8622                	mv	a2,s0
ffffffffc02055ec:	8a5e                	mv	s4,s7
ffffffffc02055ee:	46a9                	li	a3,10
ffffffffc02055f0:	b541                	j	ffffffffc0205470 <vprintfmt+0x120>
            lflag ++;
ffffffffc02055f2:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055f4:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02055f6:	bb5d                	j	ffffffffc02053ac <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc02055f8:	000a2403          	lw	s0,0(s4)
ffffffffc02055fc:	b7ed                	j	ffffffffc02055e6 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02055fe:	000a6603          	lwu	a2,0(s4)
ffffffffc0205602:	46a1                	li	a3,8
ffffffffc0205604:	8a2e                	mv	s4,a1
ffffffffc0205606:	b5ad                	j	ffffffffc0205470 <vprintfmt+0x120>
ffffffffc0205608:	000a6603          	lwu	a2,0(s4)
ffffffffc020560c:	46a9                	li	a3,10
ffffffffc020560e:	8a2e                	mv	s4,a1
ffffffffc0205610:	b585                	j	ffffffffc0205470 <vprintfmt+0x120>
ffffffffc0205612:	000a6603          	lwu	a2,0(s4)
ffffffffc0205616:	46c1                	li	a3,16
ffffffffc0205618:	8a2e                	mv	s4,a1
ffffffffc020561a:	bd99                	j	ffffffffc0205470 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc020561c:	85ca                	mv	a1,s2
ffffffffc020561e:	02d00513          	li	a0,45
ffffffffc0205622:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205624:	40800633          	neg	a2,s0
ffffffffc0205628:	8a5e                	mv	s4,s7
ffffffffc020562a:	46a9                	li	a3,10
ffffffffc020562c:	b591                	j	ffffffffc0205470 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc020562e:	e329                	bnez	a4,ffffffffc0205670 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205630:	02800793          	li	a5,40
ffffffffc0205634:	853e                	mv	a0,a5
ffffffffc0205636:	00002d97          	auipc	s11,0x2
ffffffffc020563a:	dbbd8d93          	addi	s11,s11,-581 # ffffffffc02073f1 <etext+0x1c5d>
ffffffffc020563e:	b5f5                	j	ffffffffc020552a <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205640:	85e6                	mv	a1,s9
ffffffffc0205642:	856e                	mv	a0,s11
ffffffffc0205644:	08a000ef          	jal	ffffffffc02056ce <strnlen>
ffffffffc0205648:	40ad0d3b          	subw	s10,s10,a0
ffffffffc020564c:	01a05863          	blez	s10,ffffffffc020565c <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0205650:	85ca                	mv	a1,s2
ffffffffc0205652:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205654:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0205656:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205658:	fe0d1ce3          	bnez	s10,ffffffffc0205650 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020565c:	000dc783          	lbu	a5,0(s11)
ffffffffc0205660:	0007851b          	sext.w	a0,a5
ffffffffc0205664:	ec0792e3          	bnez	a5,ffffffffc0205528 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205668:	6a22                	ld	s4,8(sp)
ffffffffc020566a:	bb29                	j	ffffffffc0205384 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020566c:	8462                	mv	s0,s8
ffffffffc020566e:	bbd9                	j	ffffffffc0205444 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205670:	85e6                	mv	a1,s9
ffffffffc0205672:	00002517          	auipc	a0,0x2
ffffffffc0205676:	d7e50513          	addi	a0,a0,-642 # ffffffffc02073f0 <etext+0x1c5c>
ffffffffc020567a:	054000ef          	jal	ffffffffc02056ce <strnlen>
ffffffffc020567e:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205682:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0205686:	00002d97          	auipc	s11,0x2
ffffffffc020568a:	d6ad8d93          	addi	s11,s11,-662 # ffffffffc02073f0 <etext+0x1c5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020568e:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205690:	fda040e3          	bgtz	s10,ffffffffc0205650 <vprintfmt+0x300>
ffffffffc0205694:	bd51                	j	ffffffffc0205528 <vprintfmt+0x1d8>

ffffffffc0205696 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205696:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205698:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020569c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020569e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02056a0:	ec06                	sd	ra,24(sp)
ffffffffc02056a2:	f83a                	sd	a4,48(sp)
ffffffffc02056a4:	fc3e                	sd	a5,56(sp)
ffffffffc02056a6:	e0c2                	sd	a6,64(sp)
ffffffffc02056a8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02056aa:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02056ac:	ca5ff0ef          	jal	ffffffffc0205350 <vprintfmt>
}
ffffffffc02056b0:	60e2                	ld	ra,24(sp)
ffffffffc02056b2:	6161                	addi	sp,sp,80
ffffffffc02056b4:	8082                	ret

ffffffffc02056b6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02056b6:	00054783          	lbu	a5,0(a0)
ffffffffc02056ba:	cb81                	beqz	a5,ffffffffc02056ca <strlen+0x14>
    size_t cnt = 0;
ffffffffc02056bc:	4781                	li	a5,0
        cnt ++;
ffffffffc02056be:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02056c0:	00f50733          	add	a4,a0,a5
ffffffffc02056c4:	00074703          	lbu	a4,0(a4)
ffffffffc02056c8:	fb7d                	bnez	a4,ffffffffc02056be <strlen+0x8>
    }
    return cnt;
}
ffffffffc02056ca:	853e                	mv	a0,a5
ffffffffc02056cc:	8082                	ret

ffffffffc02056ce <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02056ce:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02056d0:	e589                	bnez	a1,ffffffffc02056da <strnlen+0xc>
ffffffffc02056d2:	a811                	j	ffffffffc02056e6 <strnlen+0x18>
        cnt ++;
ffffffffc02056d4:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02056d6:	00f58863          	beq	a1,a5,ffffffffc02056e6 <strnlen+0x18>
ffffffffc02056da:	00f50733          	add	a4,a0,a5
ffffffffc02056de:	00074703          	lbu	a4,0(a4)
ffffffffc02056e2:	fb6d                	bnez	a4,ffffffffc02056d4 <strnlen+0x6>
ffffffffc02056e4:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02056e6:	852e                	mv	a0,a1
ffffffffc02056e8:	8082                	ret

ffffffffc02056ea <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02056ea:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02056ec:	0005c703          	lbu	a4,0(a1)
ffffffffc02056f0:	0585                	addi	a1,a1,1
ffffffffc02056f2:	0785                	addi	a5,a5,1
ffffffffc02056f4:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02056f8:	fb75                	bnez	a4,ffffffffc02056ec <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02056fa:	8082                	ret

ffffffffc02056fc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02056fc:	00054783          	lbu	a5,0(a0)
ffffffffc0205700:	e791                	bnez	a5,ffffffffc020570c <strcmp+0x10>
ffffffffc0205702:	a01d                	j	ffffffffc0205728 <strcmp+0x2c>
ffffffffc0205704:	00054783          	lbu	a5,0(a0)
ffffffffc0205708:	cb99                	beqz	a5,ffffffffc020571e <strcmp+0x22>
ffffffffc020570a:	0585                	addi	a1,a1,1
ffffffffc020570c:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0205710:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205712:	fef709e3          	beq	a4,a5,ffffffffc0205704 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205716:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020571a:	9d19                	subw	a0,a0,a4
ffffffffc020571c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020571e:	0015c703          	lbu	a4,1(a1)
ffffffffc0205722:	4501                	li	a0,0
}
ffffffffc0205724:	9d19                	subw	a0,a0,a4
ffffffffc0205726:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205728:	0005c703          	lbu	a4,0(a1)
ffffffffc020572c:	4501                	li	a0,0
ffffffffc020572e:	b7f5                	j	ffffffffc020571a <strcmp+0x1e>

ffffffffc0205730 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205730:	ce01                	beqz	a2,ffffffffc0205748 <strncmp+0x18>
ffffffffc0205732:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205736:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205738:	cb91                	beqz	a5,ffffffffc020574c <strncmp+0x1c>
ffffffffc020573a:	0005c703          	lbu	a4,0(a1)
ffffffffc020573e:	00f71763          	bne	a4,a5,ffffffffc020574c <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0205742:	0505                	addi	a0,a0,1
ffffffffc0205744:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205746:	f675                	bnez	a2,ffffffffc0205732 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205748:	4501                	li	a0,0
ffffffffc020574a:	8082                	ret
ffffffffc020574c:	00054503          	lbu	a0,0(a0)
ffffffffc0205750:	0005c783          	lbu	a5,0(a1)
ffffffffc0205754:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205756:	8082                	ret

ffffffffc0205758 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205758:	a021                	j	ffffffffc0205760 <strchr+0x8>
        if (*s == c) {
ffffffffc020575a:	00f58763          	beq	a1,a5,ffffffffc0205768 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc020575e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205760:	00054783          	lbu	a5,0(a0)
ffffffffc0205764:	fbfd                	bnez	a5,ffffffffc020575a <strchr+0x2>
    }
    return NULL;
ffffffffc0205766:	4501                	li	a0,0
}
ffffffffc0205768:	8082                	ret

ffffffffc020576a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020576a:	ca01                	beqz	a2,ffffffffc020577a <memset+0x10>
ffffffffc020576c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020576e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205770:	0785                	addi	a5,a5,1
ffffffffc0205772:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205776:	fef61de3          	bne	a2,a5,ffffffffc0205770 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020577a:	8082                	ret

ffffffffc020577c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020577c:	ca19                	beqz	a2,ffffffffc0205792 <memcpy+0x16>
ffffffffc020577e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205780:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205782:	0005c703          	lbu	a4,0(a1)
ffffffffc0205786:	0585                	addi	a1,a1,1
ffffffffc0205788:	0785                	addi	a5,a5,1
ffffffffc020578a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020578e:	feb61ae3          	bne	a2,a1,ffffffffc0205782 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205792:	8082                	ret
