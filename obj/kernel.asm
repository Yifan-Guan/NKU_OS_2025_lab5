
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
ffffffffc0200062:	704050ef          	jal	ffffffffc0205766 <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	72258593          	addi	a1,a1,1826 # ffffffffc0205790 <etext>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	73a50513          	addi	a0,a0,1850 # ffffffffc02057b0 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6e0020ef          	jal	ffffffffc0202766 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	1cd030ef          	jal	ffffffffc0203a5e <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	61b040ef          	jal	ffffffffc0204eb0 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7af040ef          	jal	ffffffffc0205050 <cpu_idle>

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
ffffffffc02000ba:	70250513          	addi	a0,a0,1794 # ffffffffc02057b8 <etext+0x28>
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
ffffffffc0200188:	1c4050ef          	jal	ffffffffc020534c <vprintfmt>
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
ffffffffc02001bc:	190050ef          	jal	ffffffffc020534c <vprintfmt>
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
ffffffffc020022c:	59850513          	addi	a0,a0,1432 # ffffffffc02057c0 <etext+0x30>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00005517          	auipc	a0,0x5
ffffffffc0200242:	5a250513          	addi	a0,a0,1442 # ffffffffc02057e0 <etext+0x50>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00005597          	auipc	a1,0x5
ffffffffc020024e:	54658593          	addi	a1,a1,1350 # ffffffffc0205790 <etext>
ffffffffc0200252:	00005517          	auipc	a0,0x5
ffffffffc0200256:	5ae50513          	addi	a0,a0,1454 # ffffffffc0205800 <etext+0x70>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	00097597          	auipc	a1,0x97
ffffffffc0200262:	0c258593          	addi	a1,a1,194 # ffffffffc0297320 <buf>
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0205820 <etext+0x90>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	0009b597          	auipc	a1,0x9b
ffffffffc0200276:	55e58593          	addi	a1,a1,1374 # ffffffffc029b7d0 <end>
ffffffffc020027a:	00005517          	auipc	a0,0x5
ffffffffc020027e:	5c650513          	addi	a0,a0,1478 # ffffffffc0205840 <etext+0xb0>
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
ffffffffc02002aa:	5ba50513          	addi	a0,a0,1466 # ffffffffc0205860 <etext+0xd0>
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
ffffffffc02002b8:	5dc60613          	addi	a2,a2,1500 # ffffffffc0205890 <etext+0x100>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	5e850513          	addi	a0,a0,1512 # ffffffffc02058a8 <etext+0x118>
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
ffffffffc02002da:	1d240413          	addi	s0,s0,466 # ffffffffc02074a8 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	21248493          	addi	s1,s1,530 # ffffffffc02074f0 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00005517          	auipc	a0,0x5
ffffffffc02002ee:	5d650513          	addi	a0,a0,1494 # ffffffffc02058c0 <etext+0x130>
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
ffffffffc0200332:	5a250513          	addi	a0,a0,1442 # ffffffffc02058d0 <etext+0x140>
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
ffffffffc020034a:	5b250513          	addi	a0,a0,1458 # ffffffffc02058f8 <etext+0x168>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	14ca8a93          	addi	s5,s5,332 # ffffffffc02074a8 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0205920 <etext+0x190>
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
ffffffffc0200388:	12448493          	addi	s1,s1,292 # ffffffffc02074a8 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	366050ef          	jal	ffffffffc02056f8 <strcmp>
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
ffffffffc02003a8:	5ac50513          	addi	a0,a0,1452 # ffffffffc0205950 <etext+0x1c0>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00005517          	auipc	a0,0x5
ffffffffc02003b6:	57650513          	addi	a0,a0,1398 # ffffffffc0205928 <etext+0x198>
ffffffffc02003ba:	39a050ef          	jal	ffffffffc0205754 <strchr>
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
ffffffffc02003f8:	53450513          	addi	a0,a0,1332 # ffffffffc0205928 <etext+0x198>
ffffffffc02003fc:	358050ef          	jal	ffffffffc0205754 <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00005517          	auipc	a0,0x5
ffffffffc0200410:	52450513          	addi	a0,a0,1316 # ffffffffc0205930 <etext+0x1a0>
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
ffffffffc0200470:	58c50513          	addi	a0,a0,1420 # ffffffffc02059f8 <etext+0x268>
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
ffffffffc020048e:	58e50513          	addi	a0,a0,1422 # ffffffffc0205a18 <etext+0x288>
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
ffffffffc02004c2:	56250513          	addi	a0,a0,1378 # ffffffffc0205a20 <etext+0x290>
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
ffffffffc02004e4:	53850513          	addi	a0,a0,1336 # ffffffffc0205a18 <etext+0x288>
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
ffffffffc020051e:	52650513          	addi	a0,a0,1318 # ffffffffc0205a40 <etext+0x2b0>
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
ffffffffc02005be:	4a650513          	addi	a0,a0,1190 # ffffffffc0205a60 <etext+0x2d0>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	49e50513          	addi	a0,a0,1182 # ffffffffc0205a70 <etext+0x2e0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	49850513          	addi	a0,a0,1176 # ffffffffc0205a80 <etext+0x2f0>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	4a250513          	addi	a0,a0,1186 # ffffffffc0205a98 <etext+0x308>
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
ffffffffc02006ec:	47850513          	addi	a0,a0,1144 # ffffffffc0205b60 <etext+0x3d0>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	4a050513          	addi	a0,a0,1184 # ffffffffc0205b98 <etext+0x408>
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
ffffffffc0200710:	3ac50513          	addi	a0,a0,940 # ffffffffc0205ab8 <etext+0x328>
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
ffffffffc0200752:	761040ef          	jal	ffffffffc02056b2 <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	38458593          	addi	a1,a1,900 # ffffffffc0205ae0 <etext+0x350>
ffffffffc0200764:	7c9040ef          	jal	ffffffffc020572c <strncmp>
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
ffffffffc020078c:	36058593          	addi	a1,a1,864 # ffffffffc0205ae8 <etext+0x358>
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
ffffffffc02007be:	73b040ef          	jal	ffffffffc02056f8 <strcmp>
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
ffffffffc02007e2:	31250513          	addi	a0,a0,786 # ffffffffc0205af0 <etext+0x360>
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
ffffffffc02008ac:	26850513          	addi	a0,a0,616 # ffffffffc0205b10 <etext+0x380>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	26e50513          	addi	a0,a0,622 # ffffffffc0205b28 <etext+0x398>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	27c50513          	addi	a0,a0,636 # ffffffffc0205b48 <etext+0x3b8>
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
ffffffffc0200914:	4dc78793          	addi	a5,a5,1244 # ffffffffc0200dec <__alltraps>
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
ffffffffc0200932:	28250513          	addi	a0,a0,642 # ffffffffc0205bb0 <etext+0x420>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	28a50513          	addi	a0,a0,650 # ffffffffc0205bc8 <etext+0x438>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	29450513          	addi	a0,a0,660 # ffffffffc0205be0 <etext+0x450>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	29e50513          	addi	a0,a0,670 # ffffffffc0205bf8 <etext+0x468>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	2a850513          	addi	a0,a0,680 # ffffffffc0205c10 <etext+0x480>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	2b250513          	addi	a0,a0,690 # ffffffffc0205c28 <etext+0x498>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	2bc50513          	addi	a0,a0,700 # ffffffffc0205c40 <etext+0x4b0>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	2c650513          	addi	a0,a0,710 # ffffffffc0205c58 <etext+0x4c8>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	2d050513          	addi	a0,a0,720 # ffffffffc0205c70 <etext+0x4e0>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	2da50513          	addi	a0,a0,730 # ffffffffc0205c88 <etext+0x4f8>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	2e450513          	addi	a0,a0,740 # ffffffffc0205ca0 <etext+0x510>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	2ee50513          	addi	a0,a0,750 # ffffffffc0205cb8 <etext+0x528>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	2f850513          	addi	a0,a0,760 # ffffffffc0205cd0 <etext+0x540>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	30250513          	addi	a0,a0,770 # ffffffffc0205ce8 <etext+0x558>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	30c50513          	addi	a0,a0,780 # ffffffffc0205d00 <etext+0x570>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	31650513          	addi	a0,a0,790 # ffffffffc0205d18 <etext+0x588>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	32050513          	addi	a0,a0,800 # ffffffffc0205d30 <etext+0x5a0>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	32a50513          	addi	a0,a0,810 # ffffffffc0205d48 <etext+0x5b8>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	33450513          	addi	a0,a0,820 # ffffffffc0205d60 <etext+0x5d0>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	33e50513          	addi	a0,a0,830 # ffffffffc0205d78 <etext+0x5e8>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	34850513          	addi	a0,a0,840 # ffffffffc0205d90 <etext+0x600>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	35250513          	addi	a0,a0,850 # ffffffffc0205da8 <etext+0x618>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	35c50513          	addi	a0,a0,860 # ffffffffc0205dc0 <etext+0x630>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	36650513          	addi	a0,a0,870 # ffffffffc0205dd8 <etext+0x648>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	37050513          	addi	a0,a0,880 # ffffffffc0205df0 <etext+0x660>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	37a50513          	addi	a0,a0,890 # ffffffffc0205e08 <etext+0x678>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	38450513          	addi	a0,a0,900 # ffffffffc0205e20 <etext+0x690>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	38e50513          	addi	a0,a0,910 # ffffffffc0205e38 <etext+0x6a8>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	39850513          	addi	a0,a0,920 # ffffffffc0205e50 <etext+0x6c0>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	3a250513          	addi	a0,a0,930 # ffffffffc0205e68 <etext+0x6d8>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	3ac50513          	addi	a0,a0,940 # ffffffffc0205e80 <etext+0x6f0>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	3b250513          	addi	a0,a0,946 # ffffffffc0205e98 <etext+0x708>
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
ffffffffc0200b00:	3b450513          	addi	a0,a0,948 # ffffffffc0205eb0 <etext+0x720>
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
ffffffffc0200b18:	3b450513          	addi	a0,a0,948 # ffffffffc0205ec8 <etext+0x738>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	3bc50513          	addi	a0,a0,956 # ffffffffc0205ee0 <etext+0x750>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	3c450513          	addi	a0,a0,964 # ffffffffc0205ef8 <etext+0x768>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	3c050513          	addi	a0,a0,960 # ffffffffc0205f08 <etext+0x778>
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
ffffffffc0200b68:	98c70713          	addi	a4,a4,-1652 # ffffffffc02074f0 <commands+0x48>
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
ffffffffc0200b7a:	40a50513          	addi	a0,a0,1034 # ffffffffc0205f80 <etext+0x7f0>
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	3de50513          	addi	a0,a0,990 # ffffffffc0205f60 <etext+0x7d0>
ffffffffc0200b8a:	e0aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	39250513          	addi	a0,a0,914 # ffffffffc0205f20 <etext+0x790>
ffffffffc0200b96:	dfeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b9a:	00005517          	auipc	a0,0x5
ffffffffc0200b9e:	3a650513          	addi	a0,a0,934 # ffffffffc0205f40 <etext+0x7b0>
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
ffffffffc0200c0a:	39a50513          	addi	a0,a0,922 # ffffffffc0205fa0 <etext+0x810>
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
ffffffffc0200c1a:	14f76663          	bltu	a4,a5,ffffffffc0200d66 <exception_handler+0x152>
ffffffffc0200c1e:	00007717          	auipc	a4,0x7
ffffffffc0200c22:	90270713          	addi	a4,a4,-1790 # ffffffffc0207520 <commands+0x78>
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
ffffffffc0200c3c:	45850513          	addi	a0,a0,1112 # ffffffffc0206090 <etext+0x900>
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
ffffffffc0200c54:	6000406f          	j	ffffffffc0205254 <syscall>
}
ffffffffc0200c58:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c5a:	00005517          	auipc	a0,0x5
ffffffffc0200c5e:	45650513          	addi	a0,a0,1110 # ffffffffc02060b0 <etext+0x920>
}
ffffffffc0200c62:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c64:	d30ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c68:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c6a:	00005517          	auipc	a0,0x5
ffffffffc0200c6e:	46650513          	addi	a0,a0,1126 # ffffffffc02060d0 <etext+0x940>
}
ffffffffc0200c72:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c74:	d20ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c78:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c7a:	00005517          	auipc	a0,0x5
ffffffffc0200c7e:	47650513          	addi	a0,a0,1142 # ffffffffc02060f0 <etext+0x960>
}
ffffffffc0200c82:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c84:	d10ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c88:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c8a:	00005517          	auipc	a0,0x5
ffffffffc0200c8e:	47e50513          	addi	a0,a0,1150 # ffffffffc0206108 <etext+0x978>
}
ffffffffc0200c92:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c98:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200c9a:	00005517          	auipc	a0,0x5
ffffffffc0200c9e:	48650513          	addi	a0,a0,1158 # ffffffffc0206120 <etext+0x990>
}
ffffffffc0200ca2:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200ca4:	cf0ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200ca8:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200caa:	00005517          	auipc	a0,0x5
ffffffffc0200cae:	31650513          	addi	a0,a0,790 # ffffffffc0205fc0 <etext+0x830>
}
ffffffffc0200cb2:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cb4:	ce0ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cb8:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cba:	00005517          	auipc	a0,0x5
ffffffffc0200cbe:	32650513          	addi	a0,a0,806 # ffffffffc0205fe0 <etext+0x850>
}
ffffffffc0200cc2:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cc4:	cd0ff06f          	j	ffffffffc0200194 <cprintf>
        tf->epc += 4; 
ffffffffc0200cc8:	10853783          	ld	a5,264(a0)
        tf->gpr.a0 = -1;  // 设置返回值为-1
ffffffffc0200ccc:	577d                	li	a4,-1
ffffffffc0200cce:	e938                	sd	a4,80(a0)
        tf->epc += 4; 
ffffffffc0200cd0:	0791                	addi	a5,a5,4
ffffffffc0200cd2:	10f53423          	sd	a5,264(a0)
}
ffffffffc0200cd6:	60e2                	ld	ra,24(sp)
ffffffffc0200cd8:	6105                	addi	sp,sp,32
ffffffffc0200cda:	8082                	ret
ffffffffc0200cdc:	e42a                	sd	a0,8(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cde:	00005517          	auipc	a0,0x5
ffffffffc0200ce2:	32250513          	addi	a0,a0,802 # ffffffffc0206000 <etext+0x870>
ffffffffc0200ce6:	caeff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200cea:	66a2                	ld	a3,8(sp)
ffffffffc0200cec:	47a9                	li	a5,10
ffffffffc0200cee:	66d8                	ld	a4,136(a3)
ffffffffc0200cf0:	fef713e3          	bne	a4,a5,ffffffffc0200cd6 <exception_handler+0xc2>
            tf->epc += 4;
ffffffffc0200cf4:	1086b783          	ld	a5,264(a3)
ffffffffc0200cf8:	0791                	addi	a5,a5,4
ffffffffc0200cfa:	10f6b423          	sd	a5,264(a3)
            syscall();
ffffffffc0200cfe:	556040ef          	jal	ffffffffc0205254 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d02:	0009b717          	auipc	a4,0x9b
ffffffffc0200d06:	ab673703          	ld	a4,-1354(a4) # ffffffffc029b7b8 <current>
ffffffffc0200d0a:	6522                	ld	a0,8(sp)
}
ffffffffc0200d0c:	60e2                	ld	ra,24(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d0e:	6b0c                	ld	a1,16(a4)
ffffffffc0200d10:	6789                	lui	a5,0x2
ffffffffc0200d12:	95be                	add	a1,a1,a5
}
ffffffffc0200d14:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d16:	a255                	j	ffffffffc0200eba <kernel_execve_ret>
}
ffffffffc0200d18:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200d1a:	00005517          	auipc	a0,0x5
ffffffffc0200d1e:	2f650513          	addi	a0,a0,758 # ffffffffc0206010 <etext+0x880>
}
ffffffffc0200d22:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200d24:	c70ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d28:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200d2a:	00005517          	auipc	a0,0x5
ffffffffc0200d2e:	30650513          	addi	a0,a0,774 # ffffffffc0206030 <etext+0x8a0>
}
ffffffffc0200d32:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d34:	c60ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d38:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d3a:	00005517          	auipc	a0,0x5
ffffffffc0200d3e:	33e50513          	addi	a0,a0,830 # ffffffffc0206078 <etext+0x8e8>
}
ffffffffc0200d42:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d44:	c50ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d48:	60e2                	ld	ra,24(sp)
ffffffffc0200d4a:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d4c:	b365                	j	ffffffffc0200af4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d4e:	00005617          	auipc	a2,0x5
ffffffffc0200d52:	2fa60613          	addi	a2,a2,762 # ffffffffc0206048 <etext+0x8b8>
ffffffffc0200d56:	0c100593          	li	a1,193
ffffffffc0200d5a:	00005517          	auipc	a0,0x5
ffffffffc0200d5e:	30650513          	addi	a0,a0,774 # ffffffffc0206060 <etext+0x8d0>
ffffffffc0200d62:	ee4ff0ef          	jal	ffffffffc0200446 <__panic>
        print_trapframe(tf);
ffffffffc0200d66:	b379                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200d68 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d68:	0009b717          	auipc	a4,0x9b
ffffffffc0200d6c:	a5073703          	ld	a4,-1456(a4) # ffffffffc029b7b8 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d70:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d74:	cf21                	beqz	a4,ffffffffc0200dcc <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d76:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d7a:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d7e:	1101                	addi	sp,sp,-32
ffffffffc0200d80:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d82:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d86:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d88:	e432                	sd	a2,8(sp)
ffffffffc0200d8a:	e042                	sd	a6,0(sp)
ffffffffc0200d8c:	0205c763          	bltz	a1,ffffffffc0200dba <trap+0x52>
        exception_handler(tf);
ffffffffc0200d90:	e85ff0ef          	jal	ffffffffc0200c14 <exception_handler>
ffffffffc0200d94:	6622                	ld	a2,8(sp)
ffffffffc0200d96:	6802                	ld	a6,0(sp)
ffffffffc0200d98:	0009b697          	auipc	a3,0x9b
ffffffffc0200d9c:	a2068693          	addi	a3,a3,-1504 # ffffffffc029b7b8 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200da0:	6298                	ld	a4,0(a3)
ffffffffc0200da2:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200da6:	e619                	bnez	a2,ffffffffc0200db4 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200da8:	0b072783          	lw	a5,176(a4)
ffffffffc0200dac:	8b85                	andi	a5,a5,1
ffffffffc0200dae:	e79d                	bnez	a5,ffffffffc0200ddc <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200db0:	6f1c                	ld	a5,24(a4)
ffffffffc0200db2:	e38d                	bnez	a5,ffffffffc0200dd4 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200db4:	60e2                	ld	ra,24(sp)
ffffffffc0200db6:	6105                	addi	sp,sp,32
ffffffffc0200db8:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200dba:	d9dff0ef          	jal	ffffffffc0200b56 <interrupt_handler>
ffffffffc0200dbe:	6802                	ld	a6,0(sp)
ffffffffc0200dc0:	6622                	ld	a2,8(sp)
ffffffffc0200dc2:	0009b697          	auipc	a3,0x9b
ffffffffc0200dc6:	9f668693          	addi	a3,a3,-1546 # ffffffffc029b7b8 <current>
ffffffffc0200dca:	bfd9                	j	ffffffffc0200da0 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dcc:	0005c363          	bltz	a1,ffffffffc0200dd2 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200dd0:	b591                	j	ffffffffc0200c14 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dd2:	b351                	j	ffffffffc0200b56 <interrupt_handler>
}
ffffffffc0200dd4:	60e2                	ld	ra,24(sp)
ffffffffc0200dd6:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200dd8:	3900406f          	j	ffffffffc0205168 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ddc:	555d                	li	a0,-9
ffffffffc0200dde:	62a030ef          	jal	ffffffffc0204408 <do_exit>
            if (current->need_resched)
ffffffffc0200de2:	0009b717          	auipc	a4,0x9b
ffffffffc0200de6:	9d673703          	ld	a4,-1578(a4) # ffffffffc029b7b8 <current>
ffffffffc0200dea:	b7d9                	j	ffffffffc0200db0 <trap+0x48>

ffffffffc0200dec <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200dec:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200df0:	00011463          	bnez	sp,ffffffffc0200df8 <__alltraps+0xc>
ffffffffc0200df4:	14002173          	csrr	sp,sscratch
ffffffffc0200df8:	712d                	addi	sp,sp,-288
ffffffffc0200dfa:	e002                	sd	zero,0(sp)
ffffffffc0200dfc:	e406                	sd	ra,8(sp)
ffffffffc0200dfe:	ec0e                	sd	gp,24(sp)
ffffffffc0200e00:	f012                	sd	tp,32(sp)
ffffffffc0200e02:	f416                	sd	t0,40(sp)
ffffffffc0200e04:	f81a                	sd	t1,48(sp)
ffffffffc0200e06:	fc1e                	sd	t2,56(sp)
ffffffffc0200e08:	e0a2                	sd	s0,64(sp)
ffffffffc0200e0a:	e4a6                	sd	s1,72(sp)
ffffffffc0200e0c:	e8aa                	sd	a0,80(sp)
ffffffffc0200e0e:	ecae                	sd	a1,88(sp)
ffffffffc0200e10:	f0b2                	sd	a2,96(sp)
ffffffffc0200e12:	f4b6                	sd	a3,104(sp)
ffffffffc0200e14:	f8ba                	sd	a4,112(sp)
ffffffffc0200e16:	fcbe                	sd	a5,120(sp)
ffffffffc0200e18:	e142                	sd	a6,128(sp)
ffffffffc0200e1a:	e546                	sd	a7,136(sp)
ffffffffc0200e1c:	e94a                	sd	s2,144(sp)
ffffffffc0200e1e:	ed4e                	sd	s3,152(sp)
ffffffffc0200e20:	f152                	sd	s4,160(sp)
ffffffffc0200e22:	f556                	sd	s5,168(sp)
ffffffffc0200e24:	f95a                	sd	s6,176(sp)
ffffffffc0200e26:	fd5e                	sd	s7,184(sp)
ffffffffc0200e28:	e1e2                	sd	s8,192(sp)
ffffffffc0200e2a:	e5e6                	sd	s9,200(sp)
ffffffffc0200e2c:	e9ea                	sd	s10,208(sp)
ffffffffc0200e2e:	edee                	sd	s11,216(sp)
ffffffffc0200e30:	f1f2                	sd	t3,224(sp)
ffffffffc0200e32:	f5f6                	sd	t4,232(sp)
ffffffffc0200e34:	f9fa                	sd	t5,240(sp)
ffffffffc0200e36:	fdfe                	sd	t6,248(sp)
ffffffffc0200e38:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e3c:	100024f3          	csrr	s1,sstatus
ffffffffc0200e40:	14102973          	csrr	s2,sepc
ffffffffc0200e44:	143029f3          	csrr	s3,stval
ffffffffc0200e48:	14202a73          	csrr	s4,scause
ffffffffc0200e4c:	e822                	sd	s0,16(sp)
ffffffffc0200e4e:	e226                	sd	s1,256(sp)
ffffffffc0200e50:	e64a                	sd	s2,264(sp)
ffffffffc0200e52:	ea4e                	sd	s3,272(sp)
ffffffffc0200e54:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e56:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e58:	f11ff0ef          	jal	ffffffffc0200d68 <trap>

ffffffffc0200e5c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e5c:	6492                	ld	s1,256(sp)
ffffffffc0200e5e:	6932                	ld	s2,264(sp)
ffffffffc0200e60:	1004f413          	andi	s0,s1,256
ffffffffc0200e64:	e401                	bnez	s0,ffffffffc0200e6c <__trapret+0x10>
ffffffffc0200e66:	1200                	addi	s0,sp,288
ffffffffc0200e68:	14041073          	csrw	sscratch,s0
ffffffffc0200e6c:	10049073          	csrw	sstatus,s1
ffffffffc0200e70:	14191073          	csrw	sepc,s2
ffffffffc0200e74:	60a2                	ld	ra,8(sp)
ffffffffc0200e76:	61e2                	ld	gp,24(sp)
ffffffffc0200e78:	7202                	ld	tp,32(sp)
ffffffffc0200e7a:	72a2                	ld	t0,40(sp)
ffffffffc0200e7c:	7342                	ld	t1,48(sp)
ffffffffc0200e7e:	73e2                	ld	t2,56(sp)
ffffffffc0200e80:	6406                	ld	s0,64(sp)
ffffffffc0200e82:	64a6                	ld	s1,72(sp)
ffffffffc0200e84:	6546                	ld	a0,80(sp)
ffffffffc0200e86:	65e6                	ld	a1,88(sp)
ffffffffc0200e88:	7606                	ld	a2,96(sp)
ffffffffc0200e8a:	76a6                	ld	a3,104(sp)
ffffffffc0200e8c:	7746                	ld	a4,112(sp)
ffffffffc0200e8e:	77e6                	ld	a5,120(sp)
ffffffffc0200e90:	680a                	ld	a6,128(sp)
ffffffffc0200e92:	68aa                	ld	a7,136(sp)
ffffffffc0200e94:	694a                	ld	s2,144(sp)
ffffffffc0200e96:	69ea                	ld	s3,152(sp)
ffffffffc0200e98:	7a0a                	ld	s4,160(sp)
ffffffffc0200e9a:	7aaa                	ld	s5,168(sp)
ffffffffc0200e9c:	7b4a                	ld	s6,176(sp)
ffffffffc0200e9e:	7bea                	ld	s7,184(sp)
ffffffffc0200ea0:	6c0e                	ld	s8,192(sp)
ffffffffc0200ea2:	6cae                	ld	s9,200(sp)
ffffffffc0200ea4:	6d4e                	ld	s10,208(sp)
ffffffffc0200ea6:	6dee                	ld	s11,216(sp)
ffffffffc0200ea8:	7e0e                	ld	t3,224(sp)
ffffffffc0200eaa:	7eae                	ld	t4,232(sp)
ffffffffc0200eac:	7f4e                	ld	t5,240(sp)
ffffffffc0200eae:	7fee                	ld	t6,248(sp)
ffffffffc0200eb0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eb2:	10200073          	sret

ffffffffc0200eb6 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200eb6:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200eb8:	b755                	j	ffffffffc0200e5c <__trapret>

ffffffffc0200eba <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200eba:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200ebe:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200ec2:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200ec6:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200eca:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200ece:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200ed2:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ed6:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200eda:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200ede:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200ee0:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200ee2:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200ee4:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200ee6:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ee8:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200eea:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200eec:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200eee:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200ef0:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200ef2:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200ef4:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200ef6:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200ef8:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200efa:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200efc:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200efe:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f00:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f02:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f04:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f06:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f08:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f0a:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f0c:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f0e:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f10:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f12:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f14:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f16:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f18:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f1a:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f1c:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f1e:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f20:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f22:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f24:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f26:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f28:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f2a:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f2c:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f2e:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f30:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f32:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f34:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f36:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f38:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f3a:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f3c:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f3e:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f40:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f42:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f44:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f46:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200f48:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200f4a:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200f4c:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200f4e:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200f50:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200f52:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200f54:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200f56:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200f58:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200f5a:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200f5c:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200f5e:	812e                	mv	sp,a1
ffffffffc0200f60:	bdf5                	j	ffffffffc0200e5c <__trapret>

ffffffffc0200f62 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f62:	00096797          	auipc	a5,0x96
ffffffffc0200f66:	7be78793          	addi	a5,a5,1982 # ffffffffc0297720 <free_area>
ffffffffc0200f6a:	e79c                	sd	a5,8(a5)
ffffffffc0200f6c:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f6e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f72:	8082                	ret

ffffffffc0200f74 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f74:	00096517          	auipc	a0,0x96
ffffffffc0200f78:	7bc56503          	lwu	a0,1980(a0) # ffffffffc0297730 <free_area+0x10>
ffffffffc0200f7c:	8082                	ret

ffffffffc0200f7e <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f7e:	711d                	addi	sp,sp,-96
ffffffffc0200f80:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f82:	00096917          	auipc	s2,0x96
ffffffffc0200f86:	79e90913          	addi	s2,s2,1950 # ffffffffc0297720 <free_area>
ffffffffc0200f8a:	00893783          	ld	a5,8(s2)
ffffffffc0200f8e:	ec86                	sd	ra,88(sp)
ffffffffc0200f90:	e8a2                	sd	s0,80(sp)
ffffffffc0200f92:	e4a6                	sd	s1,72(sp)
ffffffffc0200f94:	fc4e                	sd	s3,56(sp)
ffffffffc0200f96:	f852                	sd	s4,48(sp)
ffffffffc0200f98:	f456                	sd	s5,40(sp)
ffffffffc0200f9a:	f05a                	sd	s6,32(sp)
ffffffffc0200f9c:	ec5e                	sd	s7,24(sp)
ffffffffc0200f9e:	e862                	sd	s8,16(sp)
ffffffffc0200fa0:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fa2:	2f278363          	beq	a5,s2,ffffffffc0201288 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200fa6:	4401                	li	s0,0
ffffffffc0200fa8:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200faa:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200fae:	8b09                	andi	a4,a4,2
ffffffffc0200fb0:	2e070063          	beqz	a4,ffffffffc0201290 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200fb4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fb8:	679c                	ld	a5,8(a5)
ffffffffc0200fba:	2485                	addiw	s1,s1,1
ffffffffc0200fbc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fbe:	ff2796e3          	bne	a5,s2,ffffffffc0200faa <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200fc2:	89a2                	mv	s3,s0
ffffffffc0200fc4:	741000ef          	jal	ffffffffc0201f04 <nr_free_pages>
ffffffffc0200fc8:	73351463          	bne	a0,s3,ffffffffc02016f0 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fcc:	4505                	li	a0,1
ffffffffc0200fce:	6c5000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0200fd2:	8a2a                	mv	s4,a0
ffffffffc0200fd4:	44050e63          	beqz	a0,ffffffffc0201430 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fd8:	4505                	li	a0,1
ffffffffc0200fda:	6b9000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0200fde:	89aa                	mv	s3,a0
ffffffffc0200fe0:	72050863          	beqz	a0,ffffffffc0201710 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fe4:	4505                	li	a0,1
ffffffffc0200fe6:	6ad000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0200fea:	8aaa                	mv	s5,a0
ffffffffc0200fec:	4c050263          	beqz	a0,ffffffffc02014b0 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ff0:	40a987b3          	sub	a5,s3,a0
ffffffffc0200ff4:	40aa0733          	sub	a4,s4,a0
ffffffffc0200ff8:	0017b793          	seqz	a5,a5
ffffffffc0200ffc:	00173713          	seqz	a4,a4
ffffffffc0201000:	8fd9                	or	a5,a5,a4
ffffffffc0201002:	30079763          	bnez	a5,ffffffffc0201310 <default_check+0x392>
ffffffffc0201006:	313a0563          	beq	s4,s3,ffffffffc0201310 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020100a:	000a2783          	lw	a5,0(s4)
ffffffffc020100e:	2a079163          	bnez	a5,ffffffffc02012b0 <default_check+0x332>
ffffffffc0201012:	0009a783          	lw	a5,0(s3)
ffffffffc0201016:	28079d63          	bnez	a5,ffffffffc02012b0 <default_check+0x332>
ffffffffc020101a:	411c                	lw	a5,0(a0)
ffffffffc020101c:	28079a63          	bnez	a5,ffffffffc02012b0 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201020:	0009a797          	auipc	a5,0x9a
ffffffffc0201024:	7887b783          	ld	a5,1928(a5) # ffffffffc029b7a8 <pages>
ffffffffc0201028:	00007617          	auipc	a2,0x7
ffffffffc020102c:	89063603          	ld	a2,-1904(a2) # ffffffffc02078b8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201030:	0009a697          	auipc	a3,0x9a
ffffffffc0201034:	7706b683          	ld	a3,1904(a3) # ffffffffc029b7a0 <npage>
ffffffffc0201038:	40fa0733          	sub	a4,s4,a5
ffffffffc020103c:	8719                	srai	a4,a4,0x6
ffffffffc020103e:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201040:	0732                	slli	a4,a4,0xc
ffffffffc0201042:	06b2                	slli	a3,a3,0xc
ffffffffc0201044:	2ad77663          	bgeu	a4,a3,ffffffffc02012f0 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0201048:	40f98733          	sub	a4,s3,a5
ffffffffc020104c:	8719                	srai	a4,a4,0x6
ffffffffc020104e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201050:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201052:	4cd77f63          	bgeu	a4,a3,ffffffffc0201530 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc0201056:	40f507b3          	sub	a5,a0,a5
ffffffffc020105a:	8799                	srai	a5,a5,0x6
ffffffffc020105c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020105e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201060:	32d7f863          	bgeu	a5,a3,ffffffffc0201390 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0201064:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201066:	00093c03          	ld	s8,0(s2)
ffffffffc020106a:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc020106e:	00096b17          	auipc	s6,0x96
ffffffffc0201072:	6c2b2b03          	lw	s6,1730(s6) # ffffffffc0297730 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0201076:	01293023          	sd	s2,0(s2)
ffffffffc020107a:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc020107e:	00096797          	auipc	a5,0x96
ffffffffc0201082:	6a07a923          	sw	zero,1714(a5) # ffffffffc0297730 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201086:	60d000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc020108a:	2e051363          	bnez	a0,ffffffffc0201370 <default_check+0x3f2>
    free_page(p0);
ffffffffc020108e:	8552                	mv	a0,s4
ffffffffc0201090:	4585                	li	a1,1
ffffffffc0201092:	63b000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p1);
ffffffffc0201096:	854e                	mv	a0,s3
ffffffffc0201098:	4585                	li	a1,1
ffffffffc020109a:	633000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p2);
ffffffffc020109e:	8556                	mv	a0,s5
ffffffffc02010a0:	4585                	li	a1,1
ffffffffc02010a2:	62b000ef          	jal	ffffffffc0201ecc <free_pages>
    assert(nr_free == 3);
ffffffffc02010a6:	00096717          	auipc	a4,0x96
ffffffffc02010aa:	68a72703          	lw	a4,1674(a4) # ffffffffc0297730 <free_area+0x10>
ffffffffc02010ae:	478d                	li	a5,3
ffffffffc02010b0:	2af71063          	bne	a4,a5,ffffffffc0201350 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010b4:	4505                	li	a0,1
ffffffffc02010b6:	5dd000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010ba:	89aa                	mv	s3,a0
ffffffffc02010bc:	26050a63          	beqz	a0,ffffffffc0201330 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010c0:	4505                	li	a0,1
ffffffffc02010c2:	5d1000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010c6:	8aaa                	mv	s5,a0
ffffffffc02010c8:	3c050463          	beqz	a0,ffffffffc0201490 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010cc:	4505                	li	a0,1
ffffffffc02010ce:	5c5000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010d2:	8a2a                	mv	s4,a0
ffffffffc02010d4:	38050e63          	beqz	a0,ffffffffc0201470 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc02010d8:	4505                	li	a0,1
ffffffffc02010da:	5b9000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010de:	36051963          	bnez	a0,ffffffffc0201450 <default_check+0x4d2>
    free_page(p0);
ffffffffc02010e2:	4585                	li	a1,1
ffffffffc02010e4:	854e                	mv	a0,s3
ffffffffc02010e6:	5e7000ef          	jal	ffffffffc0201ecc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02010ea:	00893783          	ld	a5,8(s2)
ffffffffc02010ee:	1f278163          	beq	a5,s2,ffffffffc02012d0 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc02010f2:	4505                	li	a0,1
ffffffffc02010f4:	59f000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010f8:	8caa                	mv	s9,a0
ffffffffc02010fa:	30a99b63          	bne	s3,a0,ffffffffc0201410 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc02010fe:	4505                	li	a0,1
ffffffffc0201100:	593000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201104:	2e051663          	bnez	a0,ffffffffc02013f0 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201108:	00096797          	auipc	a5,0x96
ffffffffc020110c:	6287a783          	lw	a5,1576(a5) # ffffffffc0297730 <free_area+0x10>
ffffffffc0201110:	2c079063          	bnez	a5,ffffffffc02013d0 <default_check+0x452>
    free_page(p);
ffffffffc0201114:	8566                	mv	a0,s9
ffffffffc0201116:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201118:	01893023          	sd	s8,0(s2)
ffffffffc020111c:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201120:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201124:	5a9000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p1);
ffffffffc0201128:	8556                	mv	a0,s5
ffffffffc020112a:	4585                	li	a1,1
ffffffffc020112c:	5a1000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p2);
ffffffffc0201130:	8552                	mv	a0,s4
ffffffffc0201132:	4585                	li	a1,1
ffffffffc0201134:	599000ef          	jal	ffffffffc0201ecc <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201138:	4515                	li	a0,5
ffffffffc020113a:	559000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc020113e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201140:	26050863          	beqz	a0,ffffffffc02013b0 <default_check+0x432>
ffffffffc0201144:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc0201146:	8b89                	andi	a5,a5,2
ffffffffc0201148:	54079463          	bnez	a5,ffffffffc0201690 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020114c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020114e:	00093b83          	ld	s7,0(s2)
ffffffffc0201152:	00893b03          	ld	s6,8(s2)
ffffffffc0201156:	01293023          	sd	s2,0(s2)
ffffffffc020115a:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc020115e:	535000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201162:	50051763          	bnez	a0,ffffffffc0201670 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201166:	08098a13          	addi	s4,s3,128
ffffffffc020116a:	8552                	mv	a0,s4
ffffffffc020116c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020116e:	00096c17          	auipc	s8,0x96
ffffffffc0201172:	5c2c2c03          	lw	s8,1474(s8) # ffffffffc0297730 <free_area+0x10>
    nr_free = 0;
ffffffffc0201176:	00096797          	auipc	a5,0x96
ffffffffc020117a:	5a07ad23          	sw	zero,1466(a5) # ffffffffc0297730 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020117e:	54f000ef          	jal	ffffffffc0201ecc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201182:	4511                	li	a0,4
ffffffffc0201184:	50f000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201188:	4c051463          	bnez	a0,ffffffffc0201650 <default_check+0x6d2>
ffffffffc020118c:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201190:	8b89                	andi	a5,a5,2
ffffffffc0201192:	48078f63          	beqz	a5,ffffffffc0201630 <default_check+0x6b2>
ffffffffc0201196:	0909a503          	lw	a0,144(s3)
ffffffffc020119a:	478d                	li	a5,3
ffffffffc020119c:	48f51a63          	bne	a0,a5,ffffffffc0201630 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011a0:	4f3000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02011a4:	8aaa                	mv	s5,a0
ffffffffc02011a6:	46050563          	beqz	a0,ffffffffc0201610 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02011aa:	4505                	li	a0,1
ffffffffc02011ac:	4e7000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02011b0:	44051063          	bnez	a0,ffffffffc02015f0 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02011b4:	415a1e63          	bne	s4,s5,ffffffffc02015d0 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011b8:	4585                	li	a1,1
ffffffffc02011ba:	854e                	mv	a0,s3
ffffffffc02011bc:	511000ef          	jal	ffffffffc0201ecc <free_pages>
    free_pages(p1, 3);
ffffffffc02011c0:	8552                	mv	a0,s4
ffffffffc02011c2:	458d                	li	a1,3
ffffffffc02011c4:	509000ef          	jal	ffffffffc0201ecc <free_pages>
ffffffffc02011c8:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011cc:	8b89                	andi	a5,a5,2
ffffffffc02011ce:	3e078163          	beqz	a5,ffffffffc02015b0 <default_check+0x632>
ffffffffc02011d2:	0109aa83          	lw	s5,16(s3)
ffffffffc02011d6:	4785                	li	a5,1
ffffffffc02011d8:	3cfa9c63          	bne	s5,a5,ffffffffc02015b0 <default_check+0x632>
ffffffffc02011dc:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011e0:	8b89                	andi	a5,a5,2
ffffffffc02011e2:	3a078763          	beqz	a5,ffffffffc0201590 <default_check+0x612>
ffffffffc02011e6:	010a2703          	lw	a4,16(s4)
ffffffffc02011ea:	478d                	li	a5,3
ffffffffc02011ec:	3af71263          	bne	a4,a5,ffffffffc0201590 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011f0:	8556                	mv	a0,s5
ffffffffc02011f2:	4a1000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02011f6:	36a99d63          	bne	s3,a0,ffffffffc0201570 <default_check+0x5f2>
    free_page(p0);
ffffffffc02011fa:	85d6                	mv	a1,s5
ffffffffc02011fc:	4d1000ef          	jal	ffffffffc0201ecc <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201200:	4509                	li	a0,2
ffffffffc0201202:	491000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201206:	34aa1563          	bne	s4,a0,ffffffffc0201550 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc020120a:	4589                	li	a1,2
ffffffffc020120c:	4c1000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p2);
ffffffffc0201210:	04098513          	addi	a0,s3,64
ffffffffc0201214:	85d6                	mv	a1,s5
ffffffffc0201216:	4b7000ef          	jal	ffffffffc0201ecc <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020121a:	4515                	li	a0,5
ffffffffc020121c:	477000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201220:	89aa                	mv	s3,a0
ffffffffc0201222:	48050763          	beqz	a0,ffffffffc02016b0 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc0201226:	8556                	mv	a0,s5
ffffffffc0201228:	46b000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc020122c:	2e051263          	bnez	a0,ffffffffc0201510 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201230:	00096797          	auipc	a5,0x96
ffffffffc0201234:	5007a783          	lw	a5,1280(a5) # ffffffffc0297730 <free_area+0x10>
ffffffffc0201238:	2a079c63          	bnez	a5,ffffffffc02014f0 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020123c:	854e                	mv	a0,s3
ffffffffc020123e:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201240:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201244:	01793023          	sd	s7,0(s2)
ffffffffc0201248:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc020124c:	481000ef          	jal	ffffffffc0201ecc <free_pages>
    return listelm->next;
ffffffffc0201250:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201254:	01278963          	beq	a5,s2,ffffffffc0201266 <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201258:	ff87a703          	lw	a4,-8(a5)
ffffffffc020125c:	679c                	ld	a5,8(a5)
ffffffffc020125e:	34fd                	addiw	s1,s1,-1
ffffffffc0201260:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201262:	ff279be3          	bne	a5,s2,ffffffffc0201258 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc0201266:	26049563          	bnez	s1,ffffffffc02014d0 <default_check+0x552>
    assert(total == 0);
ffffffffc020126a:	46041363          	bnez	s0,ffffffffc02016d0 <default_check+0x752>
}
ffffffffc020126e:	60e6                	ld	ra,88(sp)
ffffffffc0201270:	6446                	ld	s0,80(sp)
ffffffffc0201272:	64a6                	ld	s1,72(sp)
ffffffffc0201274:	6906                	ld	s2,64(sp)
ffffffffc0201276:	79e2                	ld	s3,56(sp)
ffffffffc0201278:	7a42                	ld	s4,48(sp)
ffffffffc020127a:	7aa2                	ld	s5,40(sp)
ffffffffc020127c:	7b02                	ld	s6,32(sp)
ffffffffc020127e:	6be2                	ld	s7,24(sp)
ffffffffc0201280:	6c42                	ld	s8,16(sp)
ffffffffc0201282:	6ca2                	ld	s9,8(sp)
ffffffffc0201284:	6125                	addi	sp,sp,96
ffffffffc0201286:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201288:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020128a:	4401                	li	s0,0
ffffffffc020128c:	4481                	li	s1,0
ffffffffc020128e:	bb1d                	j	ffffffffc0200fc4 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201290:	00005697          	auipc	a3,0x5
ffffffffc0201294:	ea868693          	addi	a3,a3,-344 # ffffffffc0206138 <etext+0x9a8>
ffffffffc0201298:	00005617          	auipc	a2,0x5
ffffffffc020129c:	eb060613          	addi	a2,a2,-336 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02012a0:	11000593          	li	a1,272
ffffffffc02012a4:	00005517          	auipc	a0,0x5
ffffffffc02012a8:	ebc50513          	addi	a0,a0,-324 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02012ac:	99aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012b0:	00005697          	auipc	a3,0x5
ffffffffc02012b4:	f7068693          	addi	a3,a3,-144 # ffffffffc0206220 <etext+0xa90>
ffffffffc02012b8:	00005617          	auipc	a2,0x5
ffffffffc02012bc:	e9060613          	addi	a2,a2,-368 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02012c0:	0dc00593          	li	a1,220
ffffffffc02012c4:	00005517          	auipc	a0,0x5
ffffffffc02012c8:	e9c50513          	addi	a0,a0,-356 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02012cc:	97aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012d0:	00005697          	auipc	a3,0x5
ffffffffc02012d4:	01868693          	addi	a3,a3,24 # ffffffffc02062e8 <etext+0xb58>
ffffffffc02012d8:	00005617          	auipc	a2,0x5
ffffffffc02012dc:	e7060613          	addi	a2,a2,-400 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02012e0:	0f700593          	li	a1,247
ffffffffc02012e4:	00005517          	auipc	a0,0x5
ffffffffc02012e8:	e7c50513          	addi	a0,a0,-388 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02012ec:	95aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012f0:	00005697          	auipc	a3,0x5
ffffffffc02012f4:	f7068693          	addi	a3,a3,-144 # ffffffffc0206260 <etext+0xad0>
ffffffffc02012f8:	00005617          	auipc	a2,0x5
ffffffffc02012fc:	e5060613          	addi	a2,a2,-432 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201300:	0de00593          	li	a1,222
ffffffffc0201304:	00005517          	auipc	a0,0x5
ffffffffc0201308:	e5c50513          	addi	a0,a0,-420 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020130c:	93aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201310:	00005697          	auipc	a3,0x5
ffffffffc0201314:	ee868693          	addi	a3,a3,-280 # ffffffffc02061f8 <etext+0xa68>
ffffffffc0201318:	00005617          	auipc	a2,0x5
ffffffffc020131c:	e3060613          	addi	a2,a2,-464 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201320:	0db00593          	li	a1,219
ffffffffc0201324:	00005517          	auipc	a0,0x5
ffffffffc0201328:	e3c50513          	addi	a0,a0,-452 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020132c:	91aff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201330:	00005697          	auipc	a3,0x5
ffffffffc0201334:	e6868693          	addi	a3,a3,-408 # ffffffffc0206198 <etext+0xa08>
ffffffffc0201338:	00005617          	auipc	a2,0x5
ffffffffc020133c:	e1060613          	addi	a2,a2,-496 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201340:	0f000593          	li	a1,240
ffffffffc0201344:	00005517          	auipc	a0,0x5
ffffffffc0201348:	e1c50513          	addi	a0,a0,-484 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020134c:	8faff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc0201350:	00005697          	auipc	a3,0x5
ffffffffc0201354:	f8868693          	addi	a3,a3,-120 # ffffffffc02062d8 <etext+0xb48>
ffffffffc0201358:	00005617          	auipc	a2,0x5
ffffffffc020135c:	df060613          	addi	a2,a2,-528 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201360:	0ee00593          	li	a1,238
ffffffffc0201364:	00005517          	auipc	a0,0x5
ffffffffc0201368:	dfc50513          	addi	a0,a0,-516 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020136c:	8daff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201370:	00005697          	auipc	a3,0x5
ffffffffc0201374:	f5068693          	addi	a3,a3,-176 # ffffffffc02062c0 <etext+0xb30>
ffffffffc0201378:	00005617          	auipc	a2,0x5
ffffffffc020137c:	dd060613          	addi	a2,a2,-560 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201380:	0e900593          	li	a1,233
ffffffffc0201384:	00005517          	auipc	a0,0x5
ffffffffc0201388:	ddc50513          	addi	a0,a0,-548 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020138c:	8baff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201390:	00005697          	auipc	a3,0x5
ffffffffc0201394:	f1068693          	addi	a3,a3,-240 # ffffffffc02062a0 <etext+0xb10>
ffffffffc0201398:	00005617          	auipc	a2,0x5
ffffffffc020139c:	db060613          	addi	a2,a2,-592 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02013a0:	0e000593          	li	a1,224
ffffffffc02013a4:	00005517          	auipc	a0,0x5
ffffffffc02013a8:	dbc50513          	addi	a0,a0,-580 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02013ac:	89aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc02013b0:	00005697          	auipc	a3,0x5
ffffffffc02013b4:	f8068693          	addi	a3,a3,-128 # ffffffffc0206330 <etext+0xba0>
ffffffffc02013b8:	00005617          	auipc	a2,0x5
ffffffffc02013bc:	d9060613          	addi	a2,a2,-624 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02013c0:	11800593          	li	a1,280
ffffffffc02013c4:	00005517          	auipc	a0,0x5
ffffffffc02013c8:	d9c50513          	addi	a0,a0,-612 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02013cc:	87aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02013d0:	00005697          	auipc	a3,0x5
ffffffffc02013d4:	f5068693          	addi	a3,a3,-176 # ffffffffc0206320 <etext+0xb90>
ffffffffc02013d8:	00005617          	auipc	a2,0x5
ffffffffc02013dc:	d7060613          	addi	a2,a2,-656 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02013e0:	0fd00593          	li	a1,253
ffffffffc02013e4:	00005517          	auipc	a0,0x5
ffffffffc02013e8:	d7c50513          	addi	a0,a0,-644 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02013ec:	85aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f0:	00005697          	auipc	a3,0x5
ffffffffc02013f4:	ed068693          	addi	a3,a3,-304 # ffffffffc02062c0 <etext+0xb30>
ffffffffc02013f8:	00005617          	auipc	a2,0x5
ffffffffc02013fc:	d5060613          	addi	a2,a2,-688 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201400:	0fb00593          	li	a1,251
ffffffffc0201404:	00005517          	auipc	a0,0x5
ffffffffc0201408:	d5c50513          	addi	a0,a0,-676 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020140c:	83aff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201410:	00005697          	auipc	a3,0x5
ffffffffc0201414:	ef068693          	addi	a3,a3,-272 # ffffffffc0206300 <etext+0xb70>
ffffffffc0201418:	00005617          	auipc	a2,0x5
ffffffffc020141c:	d3060613          	addi	a2,a2,-720 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201420:	0fa00593          	li	a1,250
ffffffffc0201424:	00005517          	auipc	a0,0x5
ffffffffc0201428:	d3c50513          	addi	a0,a0,-708 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020142c:	81aff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201430:	00005697          	auipc	a3,0x5
ffffffffc0201434:	d6868693          	addi	a3,a3,-664 # ffffffffc0206198 <etext+0xa08>
ffffffffc0201438:	00005617          	auipc	a2,0x5
ffffffffc020143c:	d1060613          	addi	a2,a2,-752 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201440:	0d700593          	li	a1,215
ffffffffc0201444:	00005517          	auipc	a0,0x5
ffffffffc0201448:	d1c50513          	addi	a0,a0,-740 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020144c:	ffbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201450:	00005697          	auipc	a3,0x5
ffffffffc0201454:	e7068693          	addi	a3,a3,-400 # ffffffffc02062c0 <etext+0xb30>
ffffffffc0201458:	00005617          	auipc	a2,0x5
ffffffffc020145c:	cf060613          	addi	a2,a2,-784 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201460:	0f400593          	li	a1,244
ffffffffc0201464:	00005517          	auipc	a0,0x5
ffffffffc0201468:	cfc50513          	addi	a0,a0,-772 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020146c:	fdbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201470:	00005697          	auipc	a3,0x5
ffffffffc0201474:	d6868693          	addi	a3,a3,-664 # ffffffffc02061d8 <etext+0xa48>
ffffffffc0201478:	00005617          	auipc	a2,0x5
ffffffffc020147c:	cd060613          	addi	a2,a2,-816 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201480:	0f200593          	li	a1,242
ffffffffc0201484:	00005517          	auipc	a0,0x5
ffffffffc0201488:	cdc50513          	addi	a0,a0,-804 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020148c:	fbbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201490:	00005697          	auipc	a3,0x5
ffffffffc0201494:	d2868693          	addi	a3,a3,-728 # ffffffffc02061b8 <etext+0xa28>
ffffffffc0201498:	00005617          	auipc	a2,0x5
ffffffffc020149c:	cb060613          	addi	a2,a2,-848 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02014a0:	0f100593          	li	a1,241
ffffffffc02014a4:	00005517          	auipc	a0,0x5
ffffffffc02014a8:	cbc50513          	addi	a0,a0,-836 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02014ac:	f9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014b0:	00005697          	auipc	a3,0x5
ffffffffc02014b4:	d2868693          	addi	a3,a3,-728 # ffffffffc02061d8 <etext+0xa48>
ffffffffc02014b8:	00005617          	auipc	a2,0x5
ffffffffc02014bc:	c9060613          	addi	a2,a2,-880 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02014c0:	0d900593          	li	a1,217
ffffffffc02014c4:	00005517          	auipc	a0,0x5
ffffffffc02014c8:	c9c50513          	addi	a0,a0,-868 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02014cc:	f7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02014d0:	00005697          	auipc	a3,0x5
ffffffffc02014d4:	fb068693          	addi	a3,a3,-80 # ffffffffc0206480 <etext+0xcf0>
ffffffffc02014d8:	00005617          	auipc	a2,0x5
ffffffffc02014dc:	c7060613          	addi	a2,a2,-912 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02014e0:	14600593          	li	a1,326
ffffffffc02014e4:	00005517          	auipc	a0,0x5
ffffffffc02014e8:	c7c50513          	addi	a0,a0,-900 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02014ec:	f5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02014f0:	00005697          	auipc	a3,0x5
ffffffffc02014f4:	e3068693          	addi	a3,a3,-464 # ffffffffc0206320 <etext+0xb90>
ffffffffc02014f8:	00005617          	auipc	a2,0x5
ffffffffc02014fc:	c5060613          	addi	a2,a2,-944 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201500:	13a00593          	li	a1,314
ffffffffc0201504:	00005517          	auipc	a0,0x5
ffffffffc0201508:	c5c50513          	addi	a0,a0,-932 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020150c:	f3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201510:	00005697          	auipc	a3,0x5
ffffffffc0201514:	db068693          	addi	a3,a3,-592 # ffffffffc02062c0 <etext+0xb30>
ffffffffc0201518:	00005617          	auipc	a2,0x5
ffffffffc020151c:	c3060613          	addi	a2,a2,-976 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201520:	13800593          	li	a1,312
ffffffffc0201524:	00005517          	auipc	a0,0x5
ffffffffc0201528:	c3c50513          	addi	a0,a0,-964 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020152c:	f1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201530:	00005697          	auipc	a3,0x5
ffffffffc0201534:	d5068693          	addi	a3,a3,-688 # ffffffffc0206280 <etext+0xaf0>
ffffffffc0201538:	00005617          	auipc	a2,0x5
ffffffffc020153c:	c1060613          	addi	a2,a2,-1008 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201540:	0df00593          	li	a1,223
ffffffffc0201544:	00005517          	auipc	a0,0x5
ffffffffc0201548:	c1c50513          	addi	a0,a0,-996 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020154c:	efbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201550:	00005697          	auipc	a3,0x5
ffffffffc0201554:	ef068693          	addi	a3,a3,-272 # ffffffffc0206440 <etext+0xcb0>
ffffffffc0201558:	00005617          	auipc	a2,0x5
ffffffffc020155c:	bf060613          	addi	a2,a2,-1040 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201560:	13200593          	li	a1,306
ffffffffc0201564:	00005517          	auipc	a0,0x5
ffffffffc0201568:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020156c:	edbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201570:	00005697          	auipc	a3,0x5
ffffffffc0201574:	eb068693          	addi	a3,a3,-336 # ffffffffc0206420 <etext+0xc90>
ffffffffc0201578:	00005617          	auipc	a2,0x5
ffffffffc020157c:	bd060613          	addi	a2,a2,-1072 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201580:	13000593          	li	a1,304
ffffffffc0201584:	00005517          	auipc	a0,0x5
ffffffffc0201588:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020158c:	ebbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201590:	00005697          	auipc	a3,0x5
ffffffffc0201594:	e6868693          	addi	a3,a3,-408 # ffffffffc02063f8 <etext+0xc68>
ffffffffc0201598:	00005617          	auipc	a2,0x5
ffffffffc020159c:	bb060613          	addi	a2,a2,-1104 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02015a0:	12e00593          	li	a1,302
ffffffffc02015a4:	00005517          	auipc	a0,0x5
ffffffffc02015a8:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02015ac:	e9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015b0:	00005697          	auipc	a3,0x5
ffffffffc02015b4:	e2068693          	addi	a3,a3,-480 # ffffffffc02063d0 <etext+0xc40>
ffffffffc02015b8:	00005617          	auipc	a2,0x5
ffffffffc02015bc:	b9060613          	addi	a2,a2,-1136 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02015c0:	12d00593          	li	a1,301
ffffffffc02015c4:	00005517          	auipc	a0,0x5
ffffffffc02015c8:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02015cc:	e7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015d0:	00005697          	auipc	a3,0x5
ffffffffc02015d4:	df068693          	addi	a3,a3,-528 # ffffffffc02063c0 <etext+0xc30>
ffffffffc02015d8:	00005617          	auipc	a2,0x5
ffffffffc02015dc:	b7060613          	addi	a2,a2,-1168 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02015e0:	12800593          	li	a1,296
ffffffffc02015e4:	00005517          	auipc	a0,0x5
ffffffffc02015e8:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02015ec:	e5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015f0:	00005697          	auipc	a3,0x5
ffffffffc02015f4:	cd068693          	addi	a3,a3,-816 # ffffffffc02062c0 <etext+0xb30>
ffffffffc02015f8:	00005617          	auipc	a2,0x5
ffffffffc02015fc:	b5060613          	addi	a2,a2,-1200 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201600:	12700593          	li	a1,295
ffffffffc0201604:	00005517          	auipc	a0,0x5
ffffffffc0201608:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020160c:	e3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201610:	00005697          	auipc	a3,0x5
ffffffffc0201614:	d9068693          	addi	a3,a3,-624 # ffffffffc02063a0 <etext+0xc10>
ffffffffc0201618:	00005617          	auipc	a2,0x5
ffffffffc020161c:	b3060613          	addi	a2,a2,-1232 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201620:	12600593          	li	a1,294
ffffffffc0201624:	00005517          	auipc	a0,0x5
ffffffffc0201628:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020162c:	e1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201630:	00005697          	auipc	a3,0x5
ffffffffc0201634:	d4068693          	addi	a3,a3,-704 # ffffffffc0206370 <etext+0xbe0>
ffffffffc0201638:	00005617          	auipc	a2,0x5
ffffffffc020163c:	b1060613          	addi	a2,a2,-1264 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201640:	12500593          	li	a1,293
ffffffffc0201644:	00005517          	auipc	a0,0x5
ffffffffc0201648:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020164c:	dfbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201650:	00005697          	auipc	a3,0x5
ffffffffc0201654:	d0868693          	addi	a3,a3,-760 # ffffffffc0206358 <etext+0xbc8>
ffffffffc0201658:	00005617          	auipc	a2,0x5
ffffffffc020165c:	af060613          	addi	a2,a2,-1296 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201660:	12400593          	li	a1,292
ffffffffc0201664:	00005517          	auipc	a0,0x5
ffffffffc0201668:	afc50513          	addi	a0,a0,-1284 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020166c:	ddbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201670:	00005697          	auipc	a3,0x5
ffffffffc0201674:	c5068693          	addi	a3,a3,-944 # ffffffffc02062c0 <etext+0xb30>
ffffffffc0201678:	00005617          	auipc	a2,0x5
ffffffffc020167c:	ad060613          	addi	a2,a2,-1328 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201680:	11e00593          	li	a1,286
ffffffffc0201684:	00005517          	auipc	a0,0x5
ffffffffc0201688:	adc50513          	addi	a0,a0,-1316 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020168c:	dbbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201690:	00005697          	auipc	a3,0x5
ffffffffc0201694:	cb068693          	addi	a3,a3,-848 # ffffffffc0206340 <etext+0xbb0>
ffffffffc0201698:	00005617          	auipc	a2,0x5
ffffffffc020169c:	ab060613          	addi	a2,a2,-1360 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02016a0:	11900593          	li	a1,281
ffffffffc02016a4:	00005517          	auipc	a0,0x5
ffffffffc02016a8:	abc50513          	addi	a0,a0,-1348 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02016ac:	d9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016b0:	00005697          	auipc	a3,0x5
ffffffffc02016b4:	db068693          	addi	a3,a3,-592 # ffffffffc0206460 <etext+0xcd0>
ffffffffc02016b8:	00005617          	auipc	a2,0x5
ffffffffc02016bc:	a9060613          	addi	a2,a2,-1392 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02016c0:	13700593          	li	a1,311
ffffffffc02016c4:	00005517          	auipc	a0,0x5
ffffffffc02016c8:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02016cc:	d7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02016d0:	00005697          	auipc	a3,0x5
ffffffffc02016d4:	dc068693          	addi	a3,a3,-576 # ffffffffc0206490 <etext+0xd00>
ffffffffc02016d8:	00005617          	auipc	a2,0x5
ffffffffc02016dc:	a7060613          	addi	a2,a2,-1424 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02016e0:	14700593          	li	a1,327
ffffffffc02016e4:	00005517          	auipc	a0,0x5
ffffffffc02016e8:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0206160 <etext+0x9d0>
ffffffffc02016ec:	d5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc02016f0:	00005697          	auipc	a3,0x5
ffffffffc02016f4:	a8868693          	addi	a3,a3,-1400 # ffffffffc0206178 <etext+0x9e8>
ffffffffc02016f8:	00005617          	auipc	a2,0x5
ffffffffc02016fc:	a5060613          	addi	a2,a2,-1456 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201700:	11300593          	li	a1,275
ffffffffc0201704:	00005517          	auipc	a0,0x5
ffffffffc0201708:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020170c:	d3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201710:	00005697          	auipc	a3,0x5
ffffffffc0201714:	aa868693          	addi	a3,a3,-1368 # ffffffffc02061b8 <etext+0xa28>
ffffffffc0201718:	00005617          	auipc	a2,0x5
ffffffffc020171c:	a3060613          	addi	a2,a2,-1488 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201720:	0d800593          	li	a1,216
ffffffffc0201724:	00005517          	auipc	a0,0x5
ffffffffc0201728:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020172c:	d1bfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201730 <default_free_pages>:
{
ffffffffc0201730:	1141                	addi	sp,sp,-16
ffffffffc0201732:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201734:	14058663          	beqz	a1,ffffffffc0201880 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201738:	00659713          	slli	a4,a1,0x6
ffffffffc020173c:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201740:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201742:	c30d                	beqz	a4,ffffffffc0201764 <default_free_pages+0x34>
ffffffffc0201744:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201746:	8b05                	andi	a4,a4,1
ffffffffc0201748:	10071c63          	bnez	a4,ffffffffc0201860 <default_free_pages+0x130>
ffffffffc020174c:	6798                	ld	a4,8(a5)
ffffffffc020174e:	8b09                	andi	a4,a4,2
ffffffffc0201750:	10071863          	bnez	a4,ffffffffc0201860 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201754:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201758:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020175c:	04078793          	addi	a5,a5,64
ffffffffc0201760:	fed792e3          	bne	a5,a3,ffffffffc0201744 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201764:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201766:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020176a:	4789                	li	a5,2
ffffffffc020176c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201770:	00096717          	auipc	a4,0x96
ffffffffc0201774:	fc072703          	lw	a4,-64(a4) # ffffffffc0297730 <free_area+0x10>
ffffffffc0201778:	00096697          	auipc	a3,0x96
ffffffffc020177c:	fa868693          	addi	a3,a3,-88 # ffffffffc0297720 <free_area>
    return list->next == list;
ffffffffc0201780:	669c                	ld	a5,8(a3)
ffffffffc0201782:	9f2d                	addw	a4,a4,a1
ffffffffc0201784:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201786:	0ad78163          	beq	a5,a3,ffffffffc0201828 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc020178a:	fe878713          	addi	a4,a5,-24
ffffffffc020178e:	4581                	li	a1,0
ffffffffc0201790:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201794:	00e56a63          	bltu	a0,a4,ffffffffc02017a8 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201798:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020179a:	04d70c63          	beq	a4,a3,ffffffffc02017f2 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc020179e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017a0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017a4:	fee57ae3          	bgeu	a0,a4,ffffffffc0201798 <default_free_pages+0x68>
ffffffffc02017a8:	c199                	beqz	a1,ffffffffc02017ae <default_free_pages+0x7e>
ffffffffc02017aa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017ae:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017b0:	e390                	sd	a2,0(a5)
ffffffffc02017b2:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02017b4:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017b6:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02017b8:	00d70d63          	beq	a4,a3,ffffffffc02017d2 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017bc:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017c0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017c4:	02059813          	slli	a6,a1,0x20
ffffffffc02017c8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017cc:	97b2                	add	a5,a5,a2
ffffffffc02017ce:	02f50c63          	beq	a0,a5,ffffffffc0201806 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017d2:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017d4:	00d78c63          	beq	a5,a3,ffffffffc02017ec <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017d8:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017da:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017de:	02061593          	slli	a1,a2,0x20
ffffffffc02017e2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017e6:	972a                	add	a4,a4,a0
ffffffffc02017e8:	04e68c63          	beq	a3,a4,ffffffffc0201840 <default_free_pages+0x110>
}
ffffffffc02017ec:	60a2                	ld	ra,8(sp)
ffffffffc02017ee:	0141                	addi	sp,sp,16
ffffffffc02017f0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017f2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017f4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017f6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017f8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017fa:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02017fc:	02d70f63          	beq	a4,a3,ffffffffc020183a <default_free_pages+0x10a>
ffffffffc0201800:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201802:	87ba                	mv	a5,a4
ffffffffc0201804:	bf71                	j	ffffffffc02017a0 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201806:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201808:	5875                	li	a6,-3
ffffffffc020180a:	9fad                	addw	a5,a5,a1
ffffffffc020180c:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201810:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201814:	01853803          	ld	a6,24(a0)
ffffffffc0201818:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020181a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020181c:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_exit_out_size+0xfe5e30>
    return listelm->next;
ffffffffc0201820:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201822:	0105b023          	sd	a6,0(a1)
ffffffffc0201826:	b77d                	j	ffffffffc02017d4 <default_free_pages+0xa4>
}
ffffffffc0201828:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020182a:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020182e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201830:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201832:	e398                	sd	a4,0(a5)
ffffffffc0201834:	e798                	sd	a4,8(a5)
}
ffffffffc0201836:	0141                	addi	sp,sp,16
ffffffffc0201838:	8082                	ret
ffffffffc020183a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020183c:	873e                	mv	a4,a5
ffffffffc020183e:	bfad                	j	ffffffffc02017b8 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201840:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201844:	56f5                	li	a3,-3
ffffffffc0201846:	9f31                	addw	a4,a4,a2
ffffffffc0201848:	c918                	sw	a4,16(a0)
ffffffffc020184a:	ff078713          	addi	a4,a5,-16
ffffffffc020184e:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201852:	6398                	ld	a4,0(a5)
ffffffffc0201854:	679c                	ld	a5,8(a5)
}
ffffffffc0201856:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201858:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020185a:	e398                	sd	a4,0(a5)
ffffffffc020185c:	0141                	addi	sp,sp,16
ffffffffc020185e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201860:	00005697          	auipc	a3,0x5
ffffffffc0201864:	c4868693          	addi	a3,a3,-952 # ffffffffc02064a8 <etext+0xd18>
ffffffffc0201868:	00005617          	auipc	a2,0x5
ffffffffc020186c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201870:	09400593          	li	a1,148
ffffffffc0201874:	00005517          	auipc	a0,0x5
ffffffffc0201878:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020187c:	bcbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201880:	00005697          	auipc	a3,0x5
ffffffffc0201884:	c2068693          	addi	a3,a3,-992 # ffffffffc02064a0 <etext+0xd10>
ffffffffc0201888:	00005617          	auipc	a2,0x5
ffffffffc020188c:	8c060613          	addi	a2,a2,-1856 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201890:	09000593          	li	a1,144
ffffffffc0201894:	00005517          	auipc	a0,0x5
ffffffffc0201898:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0206160 <etext+0x9d0>
ffffffffc020189c:	babfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02018a0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018a0:	c951                	beqz	a0,ffffffffc0201934 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02018a2:	00096597          	auipc	a1,0x96
ffffffffc02018a6:	e8e5a583          	lw	a1,-370(a1) # ffffffffc0297730 <free_area+0x10>
ffffffffc02018aa:	86aa                	mv	a3,a0
ffffffffc02018ac:	02059793          	slli	a5,a1,0x20
ffffffffc02018b0:	9381                	srli	a5,a5,0x20
ffffffffc02018b2:	00a7ef63          	bltu	a5,a0,ffffffffc02018d0 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02018b6:	00096617          	auipc	a2,0x96
ffffffffc02018ba:	e6a60613          	addi	a2,a2,-406 # ffffffffc0297720 <free_area>
ffffffffc02018be:	87b2                	mv	a5,a2
ffffffffc02018c0:	a029                	j	ffffffffc02018ca <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02018c2:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02018c6:	00d77763          	bgeu	a4,a3,ffffffffc02018d4 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02018ca:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018cc:	fec79be3          	bne	a5,a2,ffffffffc02018c2 <default_alloc_pages+0x22>
        return NULL;
ffffffffc02018d0:	4501                	li	a0,0
}
ffffffffc02018d2:	8082                	ret
        if (page->property > n)
ffffffffc02018d4:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02018d8:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018dc:	6798                	ld	a4,8(a5)
ffffffffc02018de:	02089313          	slli	t1,a7,0x20
ffffffffc02018e2:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02018e6:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02018ea:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02018ee:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc02018f2:	0266fa63          	bgeu	a3,t1,ffffffffc0201926 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02018f6:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02018fa:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02018fe:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201900:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201904:	00870313          	addi	t1,a4,8
ffffffffc0201908:	4889                	li	a7,2
ffffffffc020190a:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020190e:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201912:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201916:	0068b023          	sd	t1,0(a7)
ffffffffc020191a:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020191e:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0201922:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201926:	9d95                	subw	a1,a1,a3
ffffffffc0201928:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020192a:	5775                	li	a4,-3
ffffffffc020192c:	17c1                	addi	a5,a5,-16
ffffffffc020192e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201932:	8082                	ret
{
ffffffffc0201934:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201936:	00005697          	auipc	a3,0x5
ffffffffc020193a:	b6a68693          	addi	a3,a3,-1174 # ffffffffc02064a0 <etext+0xd10>
ffffffffc020193e:	00005617          	auipc	a2,0x5
ffffffffc0201942:	80a60613          	addi	a2,a2,-2038 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201946:	06c00593          	li	a1,108
ffffffffc020194a:	00005517          	auipc	a0,0x5
ffffffffc020194e:	81650513          	addi	a0,a0,-2026 # ffffffffc0206160 <etext+0x9d0>
{
ffffffffc0201952:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201954:	af3fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201958 <default_init_memmap>:
{
ffffffffc0201958:	1141                	addi	sp,sp,-16
ffffffffc020195a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020195c:	c9e1                	beqz	a1,ffffffffc0201a2c <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc020195e:	00659713          	slli	a4,a1,0x6
ffffffffc0201962:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201966:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201968:	cf11                	beqz	a4,ffffffffc0201984 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020196a:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020196c:	8b05                	andi	a4,a4,1
ffffffffc020196e:	cf59                	beqz	a4,ffffffffc0201a0c <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201970:	0007a823          	sw	zero,16(a5)
ffffffffc0201974:	0007b423          	sd	zero,8(a5)
ffffffffc0201978:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020197c:	04078793          	addi	a5,a5,64
ffffffffc0201980:	fed795e3          	bne	a5,a3,ffffffffc020196a <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201984:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201986:	4789                	li	a5,2
ffffffffc0201988:	00850713          	addi	a4,a0,8
ffffffffc020198c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201990:	00096717          	auipc	a4,0x96
ffffffffc0201994:	da072703          	lw	a4,-608(a4) # ffffffffc0297730 <free_area+0x10>
ffffffffc0201998:	00096697          	auipc	a3,0x96
ffffffffc020199c:	d8868693          	addi	a3,a3,-632 # ffffffffc0297720 <free_area>
    return list->next == list;
ffffffffc02019a0:	669c                	ld	a5,8(a3)
ffffffffc02019a2:	9f2d                	addw	a4,a4,a1
ffffffffc02019a4:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02019a6:	04d78663          	beq	a5,a3,ffffffffc02019f2 <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02019aa:	fe878713          	addi	a4,a5,-24
ffffffffc02019ae:	4581                	li	a1,0
ffffffffc02019b0:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02019b4:	00e56a63          	bltu	a0,a4,ffffffffc02019c8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019b8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019ba:	02d70263          	beq	a4,a3,ffffffffc02019de <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02019be:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019c0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019c4:	fee57ae3          	bgeu	a0,a4,ffffffffc02019b8 <default_init_memmap+0x60>
ffffffffc02019c8:	c199                	beqz	a1,ffffffffc02019ce <default_init_memmap+0x76>
ffffffffc02019ca:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019ce:	6398                	ld	a4,0(a5)
}
ffffffffc02019d0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019d2:	e390                	sd	a2,0(a5)
ffffffffc02019d4:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02019d6:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02019d8:	f11c                	sd	a5,32(a0)
ffffffffc02019da:	0141                	addi	sp,sp,16
ffffffffc02019dc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019de:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019e0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019e2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019e4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02019e6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02019e8:	00d70e63          	beq	a4,a3,ffffffffc0201a04 <default_init_memmap+0xac>
ffffffffc02019ec:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02019ee:	87ba                	mv	a5,a4
ffffffffc02019f0:	bfc1                	j	ffffffffc02019c0 <default_init_memmap+0x68>
}
ffffffffc02019f2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02019f4:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02019f8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019fa:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02019fc:	e398                	sd	a4,0(a5)
ffffffffc02019fe:	e798                	sd	a4,8(a5)
}
ffffffffc0201a00:	0141                	addi	sp,sp,16
ffffffffc0201a02:	8082                	ret
ffffffffc0201a04:	60a2                	ld	ra,8(sp)
ffffffffc0201a06:	e290                	sd	a2,0(a3)
ffffffffc0201a08:	0141                	addi	sp,sp,16
ffffffffc0201a0a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a0c:	00005697          	auipc	a3,0x5
ffffffffc0201a10:	ac468693          	addi	a3,a3,-1340 # ffffffffc02064d0 <etext+0xd40>
ffffffffc0201a14:	00004617          	auipc	a2,0x4
ffffffffc0201a18:	73460613          	addi	a2,a2,1844 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201a1c:	04b00593          	li	a1,75
ffffffffc0201a20:	00004517          	auipc	a0,0x4
ffffffffc0201a24:	74050513          	addi	a0,a0,1856 # ffffffffc0206160 <etext+0x9d0>
ffffffffc0201a28:	a1ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201a2c:	00005697          	auipc	a3,0x5
ffffffffc0201a30:	a7468693          	addi	a3,a3,-1420 # ffffffffc02064a0 <etext+0xd10>
ffffffffc0201a34:	00004617          	auipc	a2,0x4
ffffffffc0201a38:	71460613          	addi	a2,a2,1812 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201a3c:	04700593          	li	a1,71
ffffffffc0201a40:	00004517          	auipc	a0,0x4
ffffffffc0201a44:	72050513          	addi	a0,a0,1824 # ffffffffc0206160 <etext+0x9d0>
ffffffffc0201a48:	9fffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201a4c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a4c:	c531                	beqz	a0,ffffffffc0201a98 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201a4e:	e9b9                	bnez	a1,ffffffffc0201aa4 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a50:	100027f3          	csrr	a5,sstatus
ffffffffc0201a54:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a56:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a58:	efb1                	bnez	a5,ffffffffc0201ab4 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a5a:	00096797          	auipc	a5,0x96
ffffffffc0201a5e:	8b67b783          	ld	a5,-1866(a5) # ffffffffc0297310 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a62:	873e                	mv	a4,a5
ffffffffc0201a64:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a66:	02a77a63          	bgeu	a4,a0,ffffffffc0201a9a <slob_free+0x4e>
ffffffffc0201a6a:	00f56463          	bltu	a0,a5,ffffffffc0201a72 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a6e:	fef76ae3          	bltu	a4,a5,ffffffffc0201a62 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a72:	4110                	lw	a2,0(a0)
ffffffffc0201a74:	00461693          	slli	a3,a2,0x4
ffffffffc0201a78:	96aa                	add	a3,a3,a0
ffffffffc0201a7a:	0ad78463          	beq	a5,a3,ffffffffc0201b22 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a7e:	4310                	lw	a2,0(a4)
ffffffffc0201a80:	e51c                	sd	a5,8(a0)
ffffffffc0201a82:	00461693          	slli	a3,a2,0x4
ffffffffc0201a86:	96ba                	add	a3,a3,a4
ffffffffc0201a88:	08d50163          	beq	a0,a3,ffffffffc0201b0a <slob_free+0xbe>
ffffffffc0201a8c:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201a8e:	00096797          	auipc	a5,0x96
ffffffffc0201a92:	88e7b123          	sd	a4,-1918(a5) # ffffffffc0297310 <slobfree>
    if (flag)
ffffffffc0201a96:	e9a5                	bnez	a1,ffffffffc0201b06 <slob_free+0xba>
ffffffffc0201a98:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a9a:	fcf574e3          	bgeu	a0,a5,ffffffffc0201a62 <slob_free+0x16>
ffffffffc0201a9e:	fcf762e3          	bltu	a4,a5,ffffffffc0201a62 <slob_free+0x16>
ffffffffc0201aa2:	bfc1                	j	ffffffffc0201a72 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201aa4:	25bd                	addiw	a1,a1,15
ffffffffc0201aa6:	8191                	srli	a1,a1,0x4
ffffffffc0201aa8:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aaa:	100027f3          	csrr	a5,sstatus
ffffffffc0201aae:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ab0:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ab2:	d7c5                	beqz	a5,ffffffffc0201a5a <slob_free+0xe>
{
ffffffffc0201ab4:	1101                	addi	sp,sp,-32
ffffffffc0201ab6:	e42a                	sd	a0,8(sp)
ffffffffc0201ab8:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201aba:	e4bfe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201abe:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ac0:	00096797          	auipc	a5,0x96
ffffffffc0201ac4:	8507b783          	ld	a5,-1968(a5) # ffffffffc0297310 <slobfree>
ffffffffc0201ac8:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aca:	873e                	mv	a4,a5
ffffffffc0201acc:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ace:	06a77663          	bgeu	a4,a0,ffffffffc0201b3a <slob_free+0xee>
ffffffffc0201ad2:	00f56463          	bltu	a0,a5,ffffffffc0201ada <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ad6:	fef76ae3          	bltu	a4,a5,ffffffffc0201aca <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201ada:	4110                	lw	a2,0(a0)
ffffffffc0201adc:	00461693          	slli	a3,a2,0x4
ffffffffc0201ae0:	96aa                	add	a3,a3,a0
ffffffffc0201ae2:	06d78363          	beq	a5,a3,ffffffffc0201b48 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201ae6:	4310                	lw	a2,0(a4)
ffffffffc0201ae8:	e51c                	sd	a5,8(a0)
ffffffffc0201aea:	00461693          	slli	a3,a2,0x4
ffffffffc0201aee:	96ba                	add	a3,a3,a4
ffffffffc0201af0:	06d50163          	beq	a0,a3,ffffffffc0201b52 <slob_free+0x106>
ffffffffc0201af4:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201af6:	00096797          	auipc	a5,0x96
ffffffffc0201afa:	80e7bd23          	sd	a4,-2022(a5) # ffffffffc0297310 <slobfree>
    if (flag)
ffffffffc0201afe:	e1a9                	bnez	a1,ffffffffc0201b40 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b00:	60e2                	ld	ra,24(sp)
ffffffffc0201b02:	6105                	addi	sp,sp,32
ffffffffc0201b04:	8082                	ret
        intr_enable();
ffffffffc0201b06:	df9fe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201b0a:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b0c:	853e                	mv	a0,a5
ffffffffc0201b0e:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b10:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b14:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b16:	00095797          	auipc	a5,0x95
ffffffffc0201b1a:	7ee7bd23          	sd	a4,2042(a5) # ffffffffc0297310 <slobfree>
    if (flag)
ffffffffc0201b1e:	ddad                	beqz	a1,ffffffffc0201a98 <slob_free+0x4c>
ffffffffc0201b20:	b7dd                	j	ffffffffc0201b06 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b22:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b24:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b26:	9eb1                	addw	a3,a3,a2
ffffffffc0201b28:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b2a:	4310                	lw	a2,0(a4)
ffffffffc0201b2c:	e51c                	sd	a5,8(a0)
ffffffffc0201b2e:	00461693          	slli	a3,a2,0x4
ffffffffc0201b32:	96ba                	add	a3,a3,a4
ffffffffc0201b34:	f4d51ce3          	bne	a0,a3,ffffffffc0201a8c <slob_free+0x40>
ffffffffc0201b38:	bfc9                	j	ffffffffc0201b0a <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b3a:	f8f56ee3          	bltu	a0,a5,ffffffffc0201ad6 <slob_free+0x8a>
ffffffffc0201b3e:	b771                	j	ffffffffc0201aca <slob_free+0x7e>
}
ffffffffc0201b40:	60e2                	ld	ra,24(sp)
ffffffffc0201b42:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201b44:	dbbfe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201b48:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b4a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b4c:	9eb1                	addw	a3,a3,a2
ffffffffc0201b4e:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201b50:	bf59                	j	ffffffffc0201ae6 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201b52:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b54:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201b56:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b5a:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201b5c:	bf61                	j	ffffffffc0201af4 <slob_free+0xa8>

ffffffffc0201b5e <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b5e:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b60:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b62:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b66:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b68:	32a000ef          	jal	ffffffffc0201e92 <alloc_pages>
	if (!page)
ffffffffc0201b6c:	c91d                	beqz	a0,ffffffffc0201ba2 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b6e:	0009a697          	auipc	a3,0x9a
ffffffffc0201b72:	c3a6b683          	ld	a3,-966(a3) # ffffffffc029b7a8 <pages>
ffffffffc0201b76:	00006797          	auipc	a5,0x6
ffffffffc0201b7a:	d427b783          	ld	a5,-702(a5) # ffffffffc02078b8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201b7e:	0009a717          	auipc	a4,0x9a
ffffffffc0201b82:	c2273703          	ld	a4,-990(a4) # ffffffffc029b7a0 <npage>
    return page - pages + nbase;
ffffffffc0201b86:	8d15                	sub	a0,a0,a3
ffffffffc0201b88:	8519                	srai	a0,a0,0x6
ffffffffc0201b8a:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201b8c:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b90:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b92:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b94:	00e7fa63          	bgeu	a5,a4,ffffffffc0201ba8 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b98:	0009a797          	auipc	a5,0x9a
ffffffffc0201b9c:	c007b783          	ld	a5,-1024(a5) # ffffffffc029b798 <va_pa_offset>
ffffffffc0201ba0:	953e                	add	a0,a0,a5
}
ffffffffc0201ba2:	60a2                	ld	ra,8(sp)
ffffffffc0201ba4:	0141                	addi	sp,sp,16
ffffffffc0201ba6:	8082                	ret
ffffffffc0201ba8:	86aa                	mv	a3,a0
ffffffffc0201baa:	00005617          	auipc	a2,0x5
ffffffffc0201bae:	94e60613          	addi	a2,a2,-1714 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0201bb2:	07100593          	li	a1,113
ffffffffc0201bb6:	00005517          	auipc	a0,0x5
ffffffffc0201bba:	96a50513          	addi	a0,a0,-1686 # ffffffffc0206520 <etext+0xd90>
ffffffffc0201bbe:	889fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201bc2 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201bc2:	7179                	addi	sp,sp,-48
ffffffffc0201bc4:	f406                	sd	ra,40(sp)
ffffffffc0201bc6:	f022                	sd	s0,32(sp)
ffffffffc0201bc8:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bca:	01050713          	addi	a4,a0,16
ffffffffc0201bce:	6785                	lui	a5,0x1
ffffffffc0201bd0:	0af77e63          	bgeu	a4,a5,ffffffffc0201c8c <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bd4:	00f50413          	addi	s0,a0,15
ffffffffc0201bd8:	8011                	srli	s0,s0,0x4
ffffffffc0201bda:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bdc:	100025f3          	csrr	a1,sstatus
ffffffffc0201be0:	8989                	andi	a1,a1,2
ffffffffc0201be2:	edd1                	bnez	a1,ffffffffc0201c7e <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201be4:	00095497          	auipc	s1,0x95
ffffffffc0201be8:	72c48493          	addi	s1,s1,1836 # ffffffffc0297310 <slobfree>
ffffffffc0201bec:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bee:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201bf0:	4314                	lw	a3,0(a4)
ffffffffc0201bf2:	0886da63          	bge	a3,s0,ffffffffc0201c86 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201bf6:	00e60a63          	beq	a2,a4,ffffffffc0201c0a <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bfa:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201bfc:	4394                	lw	a3,0(a5)
ffffffffc0201bfe:	0286d863          	bge	a3,s0,ffffffffc0201c2e <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c02:	6090                	ld	a2,0(s1)
ffffffffc0201c04:	873e                	mv	a4,a5
ffffffffc0201c06:	fee61ae3          	bne	a2,a4,ffffffffc0201bfa <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c0a:	e9b1                	bnez	a1,ffffffffc0201c5e <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c0c:	4501                	li	a0,0
ffffffffc0201c0e:	f51ff0ef          	jal	ffffffffc0201b5e <__slob_get_free_pages.constprop.0>
ffffffffc0201c12:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c14:	c915                	beqz	a0,ffffffffc0201c48 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c16:	6585                	lui	a1,0x1
ffffffffc0201c18:	e35ff0ef          	jal	ffffffffc0201a4c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c1c:	100025f3          	csrr	a1,sstatus
ffffffffc0201c20:	8989                	andi	a1,a1,2
ffffffffc0201c22:	e98d                	bnez	a1,ffffffffc0201c54 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c24:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c26:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c28:	4394                	lw	a3,0(a5)
ffffffffc0201c2a:	fc86cce3          	blt	a3,s0,ffffffffc0201c02 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c2e:	04d40563          	beq	s0,a3,ffffffffc0201c78 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c32:	00441613          	slli	a2,s0,0x4
ffffffffc0201c36:	963e                	add	a2,a2,a5
ffffffffc0201c38:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c3a:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201c3c:	9e81                	subw	a3,a3,s0
ffffffffc0201c3e:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201c40:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201c42:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201c44:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201c46:	ed99                	bnez	a1,ffffffffc0201c64 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201c48:	70a2                	ld	ra,40(sp)
ffffffffc0201c4a:	7402                	ld	s0,32(sp)
ffffffffc0201c4c:	64e2                	ld	s1,24(sp)
ffffffffc0201c4e:	853e                	mv	a0,a5
ffffffffc0201c50:	6145                	addi	sp,sp,48
ffffffffc0201c52:	8082                	ret
        intr_disable();
ffffffffc0201c54:	cb1fe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201c58:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201c5a:	4585                	li	a1,1
ffffffffc0201c5c:	b7e9                	j	ffffffffc0201c26 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201c5e:	ca1fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c62:	b76d                	j	ffffffffc0201c0c <slob_alloc.constprop.0+0x4a>
ffffffffc0201c64:	e43e                	sd	a5,8(sp)
ffffffffc0201c66:	c99fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c6a:	67a2                	ld	a5,8(sp)
}
ffffffffc0201c6c:	70a2                	ld	ra,40(sp)
ffffffffc0201c6e:	7402                	ld	s0,32(sp)
ffffffffc0201c70:	64e2                	ld	s1,24(sp)
ffffffffc0201c72:	853e                	mv	a0,a5
ffffffffc0201c74:	6145                	addi	sp,sp,48
ffffffffc0201c76:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c78:	6794                	ld	a3,8(a5)
ffffffffc0201c7a:	e714                	sd	a3,8(a4)
ffffffffc0201c7c:	b7e1                	j	ffffffffc0201c44 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201c7e:	c87fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201c82:	4585                	li	a1,1
ffffffffc0201c84:	b785                	j	ffffffffc0201be4 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c86:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201c88:	8732                	mv	a4,a2
ffffffffc0201c8a:	b755                	j	ffffffffc0201c2e <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c8c:	00005697          	auipc	a3,0x5
ffffffffc0201c90:	8a468693          	addi	a3,a3,-1884 # ffffffffc0206530 <etext+0xda0>
ffffffffc0201c94:	00004617          	auipc	a2,0x4
ffffffffc0201c98:	4b460613          	addi	a2,a2,1204 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0201c9c:	06300593          	li	a1,99
ffffffffc0201ca0:	00005517          	auipc	a0,0x5
ffffffffc0201ca4:	8b050513          	addi	a0,a0,-1872 # ffffffffc0206550 <etext+0xdc0>
ffffffffc0201ca8:	f9efe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201cac <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cac:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201cae:	00005517          	auipc	a0,0x5
ffffffffc0201cb2:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0206568 <etext+0xdd8>
{
ffffffffc0201cb6:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201cb8:	cdcfe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cbc:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cbe:	00005517          	auipc	a0,0x5
ffffffffc0201cc2:	8c250513          	addi	a0,a0,-1854 # ffffffffc0206580 <etext+0xdf0>
}
ffffffffc0201cc6:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cc8:	cccfe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201ccc <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201ccc:	4501                	li	a0,0
ffffffffc0201cce:	8082                	ret

ffffffffc0201cd0 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cd0:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cd2:	6685                	lui	a3,0x1
{
ffffffffc0201cd4:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cd6:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7be1>
ffffffffc0201cd8:	04a6f963          	bgeu	a3,a0,ffffffffc0201d2a <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cdc:	e42a                	sd	a0,8(sp)
ffffffffc0201cde:	4561                	li	a0,24
ffffffffc0201ce0:	e822                	sd	s0,16(sp)
ffffffffc0201ce2:	ee1ff0ef          	jal	ffffffffc0201bc2 <slob_alloc.constprop.0>
ffffffffc0201ce6:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201ce8:	c541                	beqz	a0,ffffffffc0201d70 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201cea:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201cec:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201cee:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201cf0:	00f75763          	bge	a4,a5,ffffffffc0201cfe <kmalloc+0x2e>
ffffffffc0201cf4:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201cf8:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cfa:	fef74de3          	blt	a4,a5,ffffffffc0201cf4 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201cfe:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d00:	e5fff0ef          	jal	ffffffffc0201b5e <__slob_get_free_pages.constprop.0>
ffffffffc0201d04:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d06:	cd31                	beqz	a0,ffffffffc0201d62 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d08:	100027f3          	csrr	a5,sstatus
ffffffffc0201d0c:	8b89                	andi	a5,a5,2
ffffffffc0201d0e:	eb85                	bnez	a5,ffffffffc0201d3e <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d10:	0009a797          	auipc	a5,0x9a
ffffffffc0201d14:	a687b783          	ld	a5,-1432(a5) # ffffffffc029b778 <bigblocks>
		bigblocks = bb;
ffffffffc0201d18:	0009a717          	auipc	a4,0x9a
ffffffffc0201d1c:	a6873023          	sd	s0,-1440(a4) # ffffffffc029b778 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d20:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d22:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d24:	60e2                	ld	ra,24(sp)
ffffffffc0201d26:	6105                	addi	sp,sp,32
ffffffffc0201d28:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d2a:	0541                	addi	a0,a0,16
ffffffffc0201d2c:	e97ff0ef          	jal	ffffffffc0201bc2 <slob_alloc.constprop.0>
ffffffffc0201d30:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d32:	0541                	addi	a0,a0,16
ffffffffc0201d34:	fbe5                	bnez	a5,ffffffffc0201d24 <kmalloc+0x54>
		return 0;
ffffffffc0201d36:	4501                	li	a0,0
}
ffffffffc0201d38:	60e2                	ld	ra,24(sp)
ffffffffc0201d3a:	6105                	addi	sp,sp,32
ffffffffc0201d3c:	8082                	ret
        intr_disable();
ffffffffc0201d3e:	bc7fe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d42:	0009a797          	auipc	a5,0x9a
ffffffffc0201d46:	a367b783          	ld	a5,-1482(a5) # ffffffffc029b778 <bigblocks>
		bigblocks = bb;
ffffffffc0201d4a:	0009a717          	auipc	a4,0x9a
ffffffffc0201d4e:	a2873723          	sd	s0,-1490(a4) # ffffffffc029b778 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d52:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201d54:	babfe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201d58:	6408                	ld	a0,8(s0)
}
ffffffffc0201d5a:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201d5c:	6442                	ld	s0,16(sp)
}
ffffffffc0201d5e:	6105                	addi	sp,sp,32
ffffffffc0201d60:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d62:	8522                	mv	a0,s0
ffffffffc0201d64:	45e1                	li	a1,24
ffffffffc0201d66:	ce7ff0ef          	jal	ffffffffc0201a4c <slob_free>
		return 0;
ffffffffc0201d6a:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d6c:	6442                	ld	s0,16(sp)
ffffffffc0201d6e:	b7e9                	j	ffffffffc0201d38 <kmalloc+0x68>
ffffffffc0201d70:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201d72:	4501                	li	a0,0
ffffffffc0201d74:	b7d1                	j	ffffffffc0201d38 <kmalloc+0x68>

ffffffffc0201d76 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d76:	c571                	beqz	a0,ffffffffc0201e42 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d78:	03451793          	slli	a5,a0,0x34
ffffffffc0201d7c:	e3e1                	bnez	a5,ffffffffc0201e3c <kfree+0xc6>
{
ffffffffc0201d7e:	1101                	addi	sp,sp,-32
ffffffffc0201d80:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d82:	100027f3          	csrr	a5,sstatus
ffffffffc0201d86:	8b89                	andi	a5,a5,2
ffffffffc0201d88:	e7c1                	bnez	a5,ffffffffc0201e10 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d8a:	0009a797          	auipc	a5,0x9a
ffffffffc0201d8e:	9ee7b783          	ld	a5,-1554(a5) # ffffffffc029b778 <bigblocks>
    return 0;
ffffffffc0201d92:	4581                	li	a1,0
ffffffffc0201d94:	cbad                	beqz	a5,ffffffffc0201e06 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d96:	0009a617          	auipc	a2,0x9a
ffffffffc0201d9a:	9e260613          	addi	a2,a2,-1566 # ffffffffc029b778 <bigblocks>
ffffffffc0201d9e:	a021                	j	ffffffffc0201da6 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201da0:	01070613          	addi	a2,a4,16
ffffffffc0201da4:	c3a5                	beqz	a5,ffffffffc0201e04 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201da6:	6794                	ld	a3,8(a5)
ffffffffc0201da8:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201daa:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201dac:	fea69ae3          	bne	a3,a0,ffffffffc0201da0 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201db0:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201db2:	edb5                	bnez	a1,ffffffffc0201e2e <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201db4:	c02007b7          	lui	a5,0xc0200
ffffffffc0201db8:	0af56263          	bltu	a0,a5,ffffffffc0201e5c <kfree+0xe6>
ffffffffc0201dbc:	0009a797          	auipc	a5,0x9a
ffffffffc0201dc0:	9dc7b783          	ld	a5,-1572(a5) # ffffffffc029b798 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201dc4:	0009a697          	auipc	a3,0x9a
ffffffffc0201dc8:	9dc6b683          	ld	a3,-1572(a3) # ffffffffc029b7a0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201dcc:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201dce:	00c55793          	srli	a5,a0,0xc
ffffffffc0201dd2:	06d7f963          	bgeu	a5,a3,ffffffffc0201e44 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dd6:	00006617          	auipc	a2,0x6
ffffffffc0201dda:	ae263603          	ld	a2,-1310(a2) # ffffffffc02078b8 <nbase>
ffffffffc0201dde:	0009a517          	auipc	a0,0x9a
ffffffffc0201de2:	9ca53503          	ld	a0,-1590(a0) # ffffffffc029b7a8 <pages>
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201de6:	4314                	lw	a3,0(a4)
ffffffffc0201de8:	8f91                	sub	a5,a5,a2
ffffffffc0201dea:	079a                	slli	a5,a5,0x6
ffffffffc0201dec:	4585                	li	a1,1
ffffffffc0201dee:	953e                	add	a0,a0,a5
ffffffffc0201df0:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201df4:	e03a                	sd	a4,0(sp)
ffffffffc0201df6:	0d6000ef          	jal	ffffffffc0201ecc <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dfa:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201dfc:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dfe:	45e1                	li	a1,24
}
ffffffffc0201e00:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e02:	b1a9                	j	ffffffffc0201a4c <slob_free>
ffffffffc0201e04:	e185                	bnez	a1,ffffffffc0201e24 <kfree+0xae>
}
ffffffffc0201e06:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e08:	1541                	addi	a0,a0,-16
ffffffffc0201e0a:	4581                	li	a1,0
}
ffffffffc0201e0c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e0e:	b93d                	j	ffffffffc0201a4c <slob_free>
        intr_disable();
ffffffffc0201e10:	e02a                	sd	a0,0(sp)
ffffffffc0201e12:	af3fe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e16:	0009a797          	auipc	a5,0x9a
ffffffffc0201e1a:	9627b783          	ld	a5,-1694(a5) # ffffffffc029b778 <bigblocks>
ffffffffc0201e1e:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e20:	4585                	li	a1,1
ffffffffc0201e22:	fbb5                	bnez	a5,ffffffffc0201d96 <kfree+0x20>
ffffffffc0201e24:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e26:	ad9fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e2a:	6502                	ld	a0,0(sp)
ffffffffc0201e2c:	bfe9                	j	ffffffffc0201e06 <kfree+0x90>
ffffffffc0201e2e:	e42a                	sd	a0,8(sp)
ffffffffc0201e30:	e03a                	sd	a4,0(sp)
ffffffffc0201e32:	acdfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e36:	6522                	ld	a0,8(sp)
ffffffffc0201e38:	6702                	ld	a4,0(sp)
ffffffffc0201e3a:	bfad                	j	ffffffffc0201db4 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e3c:	1541                	addi	a0,a0,-16
ffffffffc0201e3e:	4581                	li	a1,0
ffffffffc0201e40:	b131                	j	ffffffffc0201a4c <slob_free>
ffffffffc0201e42:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e44:	00004617          	auipc	a2,0x4
ffffffffc0201e48:	78460613          	addi	a2,a2,1924 # ffffffffc02065c8 <etext+0xe38>
ffffffffc0201e4c:	06900593          	li	a1,105
ffffffffc0201e50:	00004517          	auipc	a0,0x4
ffffffffc0201e54:	6d050513          	addi	a0,a0,1744 # ffffffffc0206520 <etext+0xd90>
ffffffffc0201e58:	deefe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e5c:	86aa                	mv	a3,a0
ffffffffc0201e5e:	00004617          	auipc	a2,0x4
ffffffffc0201e62:	74260613          	addi	a2,a2,1858 # ffffffffc02065a0 <etext+0xe10>
ffffffffc0201e66:	07700593          	li	a1,119
ffffffffc0201e6a:	00004517          	auipc	a0,0x4
ffffffffc0201e6e:	6b650513          	addi	a0,a0,1718 # ffffffffc0206520 <etext+0xd90>
ffffffffc0201e72:	dd4fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e76 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e76:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e78:	00004617          	auipc	a2,0x4
ffffffffc0201e7c:	75060613          	addi	a2,a2,1872 # ffffffffc02065c8 <etext+0xe38>
ffffffffc0201e80:	06900593          	li	a1,105
ffffffffc0201e84:	00004517          	auipc	a0,0x4
ffffffffc0201e88:	69c50513          	addi	a0,a0,1692 # ffffffffc0206520 <etext+0xd90>
pa2page(uintptr_t pa)
ffffffffc0201e8c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e8e:	db8fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e92 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e92:	100027f3          	csrr	a5,sstatus
ffffffffc0201e96:	8b89                	andi	a5,a5,2
ffffffffc0201e98:	e799                	bnez	a5,ffffffffc0201ea6 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e9a:	0009a797          	auipc	a5,0x9a
ffffffffc0201e9e:	8e67b783          	ld	a5,-1818(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201ea2:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea4:	8782                	jr	a5
{
ffffffffc0201ea6:	1101                	addi	sp,sp,-32
ffffffffc0201ea8:	ec06                	sd	ra,24(sp)
ffffffffc0201eaa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201eac:	a59fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eb0:	0009a797          	auipc	a5,0x9a
ffffffffc0201eb4:	8d07b783          	ld	a5,-1840(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201eb8:	6522                	ld	a0,8(sp)
ffffffffc0201eba:	6f9c                	ld	a5,24(a5)
ffffffffc0201ebc:	9782                	jalr	a5
ffffffffc0201ebe:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ec0:	a3ffe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ec4:	60e2                	ld	ra,24(sp)
ffffffffc0201ec6:	6522                	ld	a0,8(sp)
ffffffffc0201ec8:	6105                	addi	sp,sp,32
ffffffffc0201eca:	8082                	ret

ffffffffc0201ecc <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ecc:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed0:	8b89                	andi	a5,a5,2
ffffffffc0201ed2:	e799                	bnez	a5,ffffffffc0201ee0 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ed4:	0009a797          	auipc	a5,0x9a
ffffffffc0201ed8:	8ac7b783          	ld	a5,-1876(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201edc:	739c                	ld	a5,32(a5)
ffffffffc0201ede:	8782                	jr	a5
{
ffffffffc0201ee0:	1101                	addi	sp,sp,-32
ffffffffc0201ee2:	ec06                	sd	ra,24(sp)
ffffffffc0201ee4:	e42e                	sd	a1,8(sp)
ffffffffc0201ee6:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201ee8:	a1dfe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201eec:	0009a797          	auipc	a5,0x9a
ffffffffc0201ef0:	8947b783          	ld	a5,-1900(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201ef4:	65a2                	ld	a1,8(sp)
ffffffffc0201ef6:	6502                	ld	a0,0(sp)
ffffffffc0201ef8:	739c                	ld	a5,32(a5)
ffffffffc0201efa:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201efc:	60e2                	ld	ra,24(sp)
ffffffffc0201efe:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f00:	9fffe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201f04 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f04:	100027f3          	csrr	a5,sstatus
ffffffffc0201f08:	8b89                	andi	a5,a5,2
ffffffffc0201f0a:	e799                	bnez	a5,ffffffffc0201f18 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f0c:	0009a797          	auipc	a5,0x9a
ffffffffc0201f10:	8747b783          	ld	a5,-1932(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201f14:	779c                	ld	a5,40(a5)
ffffffffc0201f16:	8782                	jr	a5
{
ffffffffc0201f18:	1101                	addi	sp,sp,-32
ffffffffc0201f1a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f1c:	9e9fe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f20:	0009a797          	auipc	a5,0x9a
ffffffffc0201f24:	8607b783          	ld	a5,-1952(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201f28:	779c                	ld	a5,40(a5)
ffffffffc0201f2a:	9782                	jalr	a5
ffffffffc0201f2c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f2e:	9d1fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f32:	60e2                	ld	ra,24(sp)
ffffffffc0201f34:	6522                	ld	a0,8(sp)
ffffffffc0201f36:	6105                	addi	sp,sp,32
ffffffffc0201f38:	8082                	ret

ffffffffc0201f3a <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f3a:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f3e:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f42:	078e                	slli	a5,a5,0x3
ffffffffc0201f44:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f48:	6314                	ld	a3,0(a4)
{
ffffffffc0201f4a:	7139                	addi	sp,sp,-64
ffffffffc0201f4c:	f822                	sd	s0,48(sp)
ffffffffc0201f4e:	f426                	sd	s1,40(sp)
ffffffffc0201f50:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f52:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f56:	842e                	mv	s0,a1
ffffffffc0201f58:	8832                	mv	a6,a2
ffffffffc0201f5a:	0009a497          	auipc	s1,0x9a
ffffffffc0201f5e:	84648493          	addi	s1,s1,-1978 # ffffffffc029b7a0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f62:	ebd1                	bnez	a5,ffffffffc0201ff6 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f64:	16060d63          	beqz	a2,ffffffffc02020de <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f68:	100027f3          	csrr	a5,sstatus
ffffffffc0201f6c:	8b89                	andi	a5,a5,2
ffffffffc0201f6e:	16079e63          	bnez	a5,ffffffffc02020ea <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f72:	0009a797          	auipc	a5,0x9a
ffffffffc0201f76:	80e7b783          	ld	a5,-2034(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0201f7a:	4505                	li	a0,1
ffffffffc0201f7c:	e43a                	sd	a4,8(sp)
ffffffffc0201f7e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f80:	e832                	sd	a2,16(sp)
ffffffffc0201f82:	9782                	jalr	a5
ffffffffc0201f84:	6722                	ld	a4,8(sp)
ffffffffc0201f86:	6842                	ld	a6,16(sp)
ffffffffc0201f88:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f8a:	14078a63          	beqz	a5,ffffffffc02020de <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f8e:	0009a517          	auipc	a0,0x9a
ffffffffc0201f92:	81a53503          	ld	a0,-2022(a0) # ffffffffc029b7a8 <pages>
ffffffffc0201f96:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f9a:	0009a497          	auipc	s1,0x9a
ffffffffc0201f9e:	80648493          	addi	s1,s1,-2042 # ffffffffc029b7a0 <npage>
ffffffffc0201fa2:	40a78533          	sub	a0,a5,a0
ffffffffc0201fa6:	8519                	srai	a0,a0,0x6
ffffffffc0201fa8:	9546                	add	a0,a0,a7
ffffffffc0201faa:	6090                	ld	a2,0(s1)
ffffffffc0201fac:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201fb0:	4585                	li	a1,1
ffffffffc0201fb2:	82b1                	srli	a3,a3,0xc
ffffffffc0201fb4:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fb6:	0532                	slli	a0,a0,0xc
ffffffffc0201fb8:	1ac6f763          	bgeu	a3,a2,ffffffffc0202166 <get_pte+0x22c>
ffffffffc0201fbc:	00099697          	auipc	a3,0x99
ffffffffc0201fc0:	7dc6b683          	ld	a3,2012(a3) # ffffffffc029b798 <va_pa_offset>
ffffffffc0201fc4:	6605                	lui	a2,0x1
ffffffffc0201fc6:	4581                	li	a1,0
ffffffffc0201fc8:	9536                	add	a0,a0,a3
ffffffffc0201fca:	ec42                	sd	a6,24(sp)
ffffffffc0201fcc:	e83e                	sd	a5,16(sp)
ffffffffc0201fce:	e43a                	sd	a4,8(sp)
ffffffffc0201fd0:	796030ef          	jal	ffffffffc0205766 <memset>
    return page - pages + nbase;
ffffffffc0201fd4:	00099697          	auipc	a3,0x99
ffffffffc0201fd8:	7d46b683          	ld	a3,2004(a3) # ffffffffc029b7a8 <pages>
ffffffffc0201fdc:	67c2                	ld	a5,16(sp)
ffffffffc0201fde:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fe2:	6722                	ld	a4,8(sp)
ffffffffc0201fe4:	40d786b3          	sub	a3,a5,a3
ffffffffc0201fe8:	8699                	srai	a3,a3,0x6
ffffffffc0201fea:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fec:	06aa                	slli	a3,a3,0xa
ffffffffc0201fee:	6862                	ld	a6,24(sp)
ffffffffc0201ff0:	0116e693          	ori	a3,a3,17
ffffffffc0201ff4:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ff6:	c006f693          	andi	a3,a3,-1024
ffffffffc0201ffa:	6098                	ld	a4,0(s1)
ffffffffc0201ffc:	068a                	slli	a3,a3,0x2
ffffffffc0201ffe:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202002:	14e7f663          	bgeu	a5,a4,ffffffffc020214e <get_pte+0x214>
ffffffffc0202006:	00099897          	auipc	a7,0x99
ffffffffc020200a:	79288893          	addi	a7,a7,1938 # ffffffffc029b798 <va_pa_offset>
ffffffffc020200e:	0008b603          	ld	a2,0(a7)
ffffffffc0202012:	01545793          	srli	a5,s0,0x15
ffffffffc0202016:	1ff7f793          	andi	a5,a5,511
ffffffffc020201a:	96b2                	add	a3,a3,a2
ffffffffc020201c:	078e                	slli	a5,a5,0x3
ffffffffc020201e:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202020:	6394                	ld	a3,0(a5)
ffffffffc0202022:	0016f613          	andi	a2,a3,1
ffffffffc0202026:	e659                	bnez	a2,ffffffffc02020b4 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202028:	0a080b63          	beqz	a6,ffffffffc02020de <get_pte+0x1a4>
ffffffffc020202c:	10002773          	csrr	a4,sstatus
ffffffffc0202030:	8b09                	andi	a4,a4,2
ffffffffc0202032:	ef71                	bnez	a4,ffffffffc020210e <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202034:	00099717          	auipc	a4,0x99
ffffffffc0202038:	74c73703          	ld	a4,1868(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc020203c:	4505                	li	a0,1
ffffffffc020203e:	e43e                	sd	a5,8(sp)
ffffffffc0202040:	6f18                	ld	a4,24(a4)
ffffffffc0202042:	9702                	jalr	a4
ffffffffc0202044:	67a2                	ld	a5,8(sp)
ffffffffc0202046:	872a                	mv	a4,a0
ffffffffc0202048:	00099897          	auipc	a7,0x99
ffffffffc020204c:	75088893          	addi	a7,a7,1872 # ffffffffc029b798 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202050:	c759                	beqz	a4,ffffffffc02020de <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0202052:	00099697          	auipc	a3,0x99
ffffffffc0202056:	7566b683          	ld	a3,1878(a3) # ffffffffc029b7a8 <pages>
ffffffffc020205a:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020205e:	608c                	ld	a1,0(s1)
ffffffffc0202060:	40d706b3          	sub	a3,a4,a3
ffffffffc0202064:	8699                	srai	a3,a3,0x6
ffffffffc0202066:	96c2                	add	a3,a3,a6
ffffffffc0202068:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc020206c:	4505                	li	a0,1
ffffffffc020206e:	8231                	srli	a2,a2,0xc
ffffffffc0202070:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0202072:	06b2                	slli	a3,a3,0xc
ffffffffc0202074:	10b67663          	bgeu	a2,a1,ffffffffc0202180 <get_pte+0x246>
ffffffffc0202078:	0008b503          	ld	a0,0(a7)
ffffffffc020207c:	6605                	lui	a2,0x1
ffffffffc020207e:	4581                	li	a1,0
ffffffffc0202080:	9536                	add	a0,a0,a3
ffffffffc0202082:	e83a                	sd	a4,16(sp)
ffffffffc0202084:	e43e                	sd	a5,8(sp)
ffffffffc0202086:	6e0030ef          	jal	ffffffffc0205766 <memset>
    return page - pages + nbase;
ffffffffc020208a:	00099697          	auipc	a3,0x99
ffffffffc020208e:	71e6b683          	ld	a3,1822(a3) # ffffffffc029b7a8 <pages>
ffffffffc0202092:	6742                	ld	a4,16(sp)
ffffffffc0202094:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202098:	67a2                	ld	a5,8(sp)
ffffffffc020209a:	40d706b3          	sub	a3,a4,a3
ffffffffc020209e:	8699                	srai	a3,a3,0x6
ffffffffc02020a0:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020a2:	06aa                	slli	a3,a3,0xa
ffffffffc02020a4:	0116e693          	ori	a3,a3,17
ffffffffc02020a8:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020aa:	6098                	ld	a4,0(s1)
ffffffffc02020ac:	00099897          	auipc	a7,0x99
ffffffffc02020b0:	6ec88893          	addi	a7,a7,1772 # ffffffffc029b798 <va_pa_offset>
ffffffffc02020b4:	c006f693          	andi	a3,a3,-1024
ffffffffc02020b8:	068a                	slli	a3,a3,0x2
ffffffffc02020ba:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020be:	06e7fc63          	bgeu	a5,a4,ffffffffc0202136 <get_pte+0x1fc>
ffffffffc02020c2:	0008b783          	ld	a5,0(a7)
ffffffffc02020c6:	8031                	srli	s0,s0,0xc
ffffffffc02020c8:	1ff47413          	andi	s0,s0,511
ffffffffc02020cc:	040e                	slli	s0,s0,0x3
ffffffffc02020ce:	96be                	add	a3,a3,a5
}
ffffffffc02020d0:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020d2:	00868533          	add	a0,a3,s0
}
ffffffffc02020d6:	7442                	ld	s0,48(sp)
ffffffffc02020d8:	74a2                	ld	s1,40(sp)
ffffffffc02020da:	6121                	addi	sp,sp,64
ffffffffc02020dc:	8082                	ret
ffffffffc02020de:	70e2                	ld	ra,56(sp)
ffffffffc02020e0:	7442                	ld	s0,48(sp)
ffffffffc02020e2:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc02020e4:	4501                	li	a0,0
}
ffffffffc02020e6:	6121                	addi	sp,sp,64
ffffffffc02020e8:	8082                	ret
        intr_disable();
ffffffffc02020ea:	e83a                	sd	a4,16(sp)
ffffffffc02020ec:	ec32                	sd	a2,24(sp)
ffffffffc02020ee:	817fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020f2:	00099797          	auipc	a5,0x99
ffffffffc02020f6:	68e7b783          	ld	a5,1678(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc02020fa:	4505                	li	a0,1
ffffffffc02020fc:	6f9c                	ld	a5,24(a5)
ffffffffc02020fe:	9782                	jalr	a5
ffffffffc0202100:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202102:	ffcfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202106:	6862                	ld	a6,24(sp)
ffffffffc0202108:	6742                	ld	a4,16(sp)
ffffffffc020210a:	67a2                	ld	a5,8(sp)
ffffffffc020210c:	bdbd                	j	ffffffffc0201f8a <get_pte+0x50>
        intr_disable();
ffffffffc020210e:	e83e                	sd	a5,16(sp)
ffffffffc0202110:	ff4fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202114:	00099717          	auipc	a4,0x99
ffffffffc0202118:	66c73703          	ld	a4,1644(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc020211c:	4505                	li	a0,1
ffffffffc020211e:	6f18                	ld	a4,24(a4)
ffffffffc0202120:	9702                	jalr	a4
ffffffffc0202122:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202124:	fdafe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202128:	6722                	ld	a4,8(sp)
ffffffffc020212a:	67c2                	ld	a5,16(sp)
ffffffffc020212c:	00099897          	auipc	a7,0x99
ffffffffc0202130:	66c88893          	addi	a7,a7,1644 # ffffffffc029b798 <va_pa_offset>
ffffffffc0202134:	bf31                	j	ffffffffc0202050 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202136:	00004617          	auipc	a2,0x4
ffffffffc020213a:	3c260613          	addi	a2,a2,962 # ffffffffc02064f8 <etext+0xd68>
ffffffffc020213e:	0fa00593          	li	a1,250
ffffffffc0202142:	00004517          	auipc	a0,0x4
ffffffffc0202146:	4a650513          	addi	a0,a0,1190 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020214a:	afcfe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020214e:	00004617          	auipc	a2,0x4
ffffffffc0202152:	3aa60613          	addi	a2,a2,938 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0202156:	0ed00593          	li	a1,237
ffffffffc020215a:	00004517          	auipc	a0,0x4
ffffffffc020215e:	48e50513          	addi	a0,a0,1166 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202162:	ae4fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202166:	86aa                	mv	a3,a0
ffffffffc0202168:	00004617          	auipc	a2,0x4
ffffffffc020216c:	39060613          	addi	a2,a2,912 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0202170:	0e900593          	li	a1,233
ffffffffc0202174:	00004517          	auipc	a0,0x4
ffffffffc0202178:	47450513          	addi	a0,a0,1140 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020217c:	acafe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202180:	00004617          	auipc	a2,0x4
ffffffffc0202184:	37860613          	addi	a2,a2,888 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0202188:	0f700593          	li	a1,247
ffffffffc020218c:	00004517          	auipc	a0,0x4
ffffffffc0202190:	45c50513          	addi	a0,a0,1116 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202194:	ab2fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202198 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202198:	1141                	addi	sp,sp,-16
ffffffffc020219a:	e022                	sd	s0,0(sp)
ffffffffc020219c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020219e:	4601                	li	a2,0
{
ffffffffc02021a0:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021a2:	d99ff0ef          	jal	ffffffffc0201f3a <get_pte>
    if (ptep_store != NULL)
ffffffffc02021a6:	c011                	beqz	s0,ffffffffc02021aa <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021a8:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021aa:	c511                	beqz	a0,ffffffffc02021b6 <get_page+0x1e>
ffffffffc02021ac:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021ae:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021b0:	0017f713          	andi	a4,a5,1
ffffffffc02021b4:	e709                	bnez	a4,ffffffffc02021be <get_page+0x26>
}
ffffffffc02021b6:	60a2                	ld	ra,8(sp)
ffffffffc02021b8:	6402                	ld	s0,0(sp)
ffffffffc02021ba:	0141                	addi	sp,sp,16
ffffffffc02021bc:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02021be:	00099717          	auipc	a4,0x99
ffffffffc02021c2:	5e273703          	ld	a4,1506(a4) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02021c6:	078a                	slli	a5,a5,0x2
ffffffffc02021c8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021ca:	00e7ff63          	bgeu	a5,a4,ffffffffc02021e8 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02021ce:	00099517          	auipc	a0,0x99
ffffffffc02021d2:	5da53503          	ld	a0,1498(a0) # ffffffffc029b7a8 <pages>
ffffffffc02021d6:	60a2                	ld	ra,8(sp)
ffffffffc02021d8:	6402                	ld	s0,0(sp)
ffffffffc02021da:	079a                	slli	a5,a5,0x6
ffffffffc02021dc:	fe000737          	lui	a4,0xfe000
ffffffffc02021e0:	97ba                	add	a5,a5,a4
ffffffffc02021e2:	953e                	add	a0,a0,a5
ffffffffc02021e4:	0141                	addi	sp,sp,16
ffffffffc02021e6:	8082                	ret
ffffffffc02021e8:	c8fff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc02021ec <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021ec:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ee:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021f2:	e486                	sd	ra,72(sp)
ffffffffc02021f4:	e0a2                	sd	s0,64(sp)
ffffffffc02021f6:	fc26                	sd	s1,56(sp)
ffffffffc02021f8:	f84a                	sd	s2,48(sp)
ffffffffc02021fa:	f44e                	sd	s3,40(sp)
ffffffffc02021fc:	f052                	sd	s4,32(sp)
ffffffffc02021fe:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202200:	03479713          	slli	a4,a5,0x34
ffffffffc0202204:	ef61                	bnez	a4,ffffffffc02022dc <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc0202206:	00200a37          	lui	s4,0x200
ffffffffc020220a:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020220e:	0145b733          	sltu	a4,a1,s4
ffffffffc0202212:	0017b793          	seqz	a5,a5
ffffffffc0202216:	8fd9                	or	a5,a5,a4
ffffffffc0202218:	842e                	mv	s0,a1
ffffffffc020221a:	84b2                	mv	s1,a2
ffffffffc020221c:	e3e5                	bnez	a5,ffffffffc02022fc <unmap_range+0x110>
ffffffffc020221e:	4785                	li	a5,1
ffffffffc0202220:	07fe                	slli	a5,a5,0x1f
ffffffffc0202222:	0785                	addi	a5,a5,1
ffffffffc0202224:	892a                	mv	s2,a0
ffffffffc0202226:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202228:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc020222c:	0cf67863          	bgeu	a2,a5,ffffffffc02022fc <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202230:	4601                	li	a2,0
ffffffffc0202232:	85a2                	mv	a1,s0
ffffffffc0202234:	854a                	mv	a0,s2
ffffffffc0202236:	d05ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc020223a:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc020223c:	cd31                	beqz	a0,ffffffffc0202298 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc020223e:	6118                	ld	a4,0(a0)
ffffffffc0202240:	ef11                	bnez	a4,ffffffffc020225c <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202242:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202244:	c019                	beqz	s0,ffffffffc020224a <unmap_range+0x5e>
ffffffffc0202246:	fe9465e3          	bltu	s0,s1,ffffffffc0202230 <unmap_range+0x44>
}
ffffffffc020224a:	60a6                	ld	ra,72(sp)
ffffffffc020224c:	6406                	ld	s0,64(sp)
ffffffffc020224e:	74e2                	ld	s1,56(sp)
ffffffffc0202250:	7942                	ld	s2,48(sp)
ffffffffc0202252:	79a2                	ld	s3,40(sp)
ffffffffc0202254:	7a02                	ld	s4,32(sp)
ffffffffc0202256:	6ae2                	ld	s5,24(sp)
ffffffffc0202258:	6161                	addi	sp,sp,80
ffffffffc020225a:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc020225c:	00177693          	andi	a3,a4,1
ffffffffc0202260:	d2ed                	beqz	a3,ffffffffc0202242 <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc0202262:	00099697          	auipc	a3,0x99
ffffffffc0202266:	53e6b683          	ld	a3,1342(a3) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020226a:	070a                	slli	a4,a4,0x2
ffffffffc020226c:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020226e:	0ad77763          	bgeu	a4,a3,ffffffffc020231c <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc0202272:	00099517          	auipc	a0,0x99
ffffffffc0202276:	53653503          	ld	a0,1334(a0) # ffffffffc029b7a8 <pages>
ffffffffc020227a:	071a                	slli	a4,a4,0x6
ffffffffc020227c:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202280:	9736                	add	a4,a4,a3
ffffffffc0202282:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202284:	4118                	lw	a4,0(a0)
ffffffffc0202286:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd6482f>
ffffffffc0202288:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020228a:	cb19                	beqz	a4,ffffffffc02022a0 <unmap_range+0xb4>
        *ptep = 0;
ffffffffc020228c:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202290:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202294:	944e                	add	s0,s0,s3
ffffffffc0202296:	b77d                	j	ffffffffc0202244 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202298:	9452                	add	s0,s0,s4
ffffffffc020229a:	01547433          	and	s0,s0,s5
            continue;
ffffffffc020229e:	b75d                	j	ffffffffc0202244 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022a0:	10002773          	csrr	a4,sstatus
ffffffffc02022a4:	8b09                	andi	a4,a4,2
ffffffffc02022a6:	eb19                	bnez	a4,ffffffffc02022bc <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02022a8:	00099717          	auipc	a4,0x99
ffffffffc02022ac:	4d873703          	ld	a4,1240(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc02022b0:	4585                	li	a1,1
ffffffffc02022b2:	e03e                	sd	a5,0(sp)
ffffffffc02022b4:	7318                	ld	a4,32(a4)
ffffffffc02022b6:	9702                	jalr	a4
    if (flag)
ffffffffc02022b8:	6782                	ld	a5,0(sp)
ffffffffc02022ba:	bfc9                	j	ffffffffc020228c <unmap_range+0xa0>
        intr_disable();
ffffffffc02022bc:	e43e                	sd	a5,8(sp)
ffffffffc02022be:	e02a                	sd	a0,0(sp)
ffffffffc02022c0:	e44fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02022c4:	00099717          	auipc	a4,0x99
ffffffffc02022c8:	4bc73703          	ld	a4,1212(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc02022cc:	6502                	ld	a0,0(sp)
ffffffffc02022ce:	4585                	li	a1,1
ffffffffc02022d0:	7318                	ld	a4,32(a4)
ffffffffc02022d2:	9702                	jalr	a4
        intr_enable();
ffffffffc02022d4:	e2afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02022d8:	67a2                	ld	a5,8(sp)
ffffffffc02022da:	bf4d                	j	ffffffffc020228c <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022dc:	00004697          	auipc	a3,0x4
ffffffffc02022e0:	31c68693          	addi	a3,a3,796 # ffffffffc02065f8 <etext+0xe68>
ffffffffc02022e4:	00004617          	auipc	a2,0x4
ffffffffc02022e8:	e6460613          	addi	a2,a2,-412 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02022ec:	12000593          	li	a1,288
ffffffffc02022f0:	00004517          	auipc	a0,0x4
ffffffffc02022f4:	2f850513          	addi	a0,a0,760 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02022f8:	94efe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022fc:	00004697          	auipc	a3,0x4
ffffffffc0202300:	32c68693          	addi	a3,a3,812 # ffffffffc0206628 <etext+0xe98>
ffffffffc0202304:	00004617          	auipc	a2,0x4
ffffffffc0202308:	e4460613          	addi	a2,a2,-444 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020230c:	12100593          	li	a1,289
ffffffffc0202310:	00004517          	auipc	a0,0x4
ffffffffc0202314:	2d850513          	addi	a0,a0,728 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202318:	92efe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020231c:	b5bff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc0202320 <exit_range>:
{
ffffffffc0202320:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202322:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202326:	ed06                	sd	ra,152(sp)
ffffffffc0202328:	e922                	sd	s0,144(sp)
ffffffffc020232a:	e526                	sd	s1,136(sp)
ffffffffc020232c:	e14a                	sd	s2,128(sp)
ffffffffc020232e:	fcce                	sd	s3,120(sp)
ffffffffc0202330:	f8d2                	sd	s4,112(sp)
ffffffffc0202332:	f4d6                	sd	s5,104(sp)
ffffffffc0202334:	f0da                	sd	s6,96(sp)
ffffffffc0202336:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202338:	17d2                	slli	a5,a5,0x34
ffffffffc020233a:	22079263          	bnez	a5,ffffffffc020255e <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc020233e:	00200937          	lui	s2,0x200
ffffffffc0202342:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202346:	0125b733          	sltu	a4,a1,s2
ffffffffc020234a:	0017b793          	seqz	a5,a5
ffffffffc020234e:	8fd9                	or	a5,a5,a4
ffffffffc0202350:	26079263          	bnez	a5,ffffffffc02025b4 <exit_range+0x294>
ffffffffc0202354:	4785                	li	a5,1
ffffffffc0202356:	07fe                	slli	a5,a5,0x1f
ffffffffc0202358:	0785                	addi	a5,a5,1
ffffffffc020235a:	24f67d63          	bgeu	a2,a5,ffffffffc02025b4 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020235e:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202362:	ffe007b7          	lui	a5,0xffe00
ffffffffc0202366:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202368:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020236a:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc020236e:	00099a97          	auipc	s5,0x99
ffffffffc0202372:	432a8a93          	addi	s5,s5,1074 # ffffffffc029b7a0 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202376:	400009b7          	lui	s3,0x40000
ffffffffc020237a:	a809                	j	ffffffffc020238c <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc020237c:	013487b3          	add	a5,s1,s3
ffffffffc0202380:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202384:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202386:	c3f1                	beqz	a5,ffffffffc020244a <exit_range+0x12a>
ffffffffc0202388:	0cc7f163          	bgeu	a5,a2,ffffffffc020244a <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020238c:	01e4d413          	srli	s0,s1,0x1e
ffffffffc0202390:	1ff47413          	andi	s0,s0,511
ffffffffc0202394:	040e                	slli	s0,s0,0x3
ffffffffc0202396:	9452                	add	s0,s0,s4
ffffffffc0202398:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc020239c:	0018f793          	andi	a5,a7,1
ffffffffc02023a0:	dff1                	beqz	a5,ffffffffc020237c <exit_range+0x5c>
ffffffffc02023a2:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023a6:	088a                	slli	a7,a7,0x2
ffffffffc02023a8:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02023ac:	20f8f263          	bgeu	a7,a5,ffffffffc02025b0 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b0:	fff802b7          	lui	t0,0xfff80
ffffffffc02023b4:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02023b8:	000803b7          	lui	t2,0x80
ffffffffc02023bc:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02023c0:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023c4:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02023c6:	1cf77863          	bgeu	a4,a5,ffffffffc0202596 <exit_range+0x276>
ffffffffc02023ca:	00099f97          	auipc	t6,0x99
ffffffffc02023ce:	3cef8f93          	addi	t6,t6,974 # ffffffffc029b798 <va_pa_offset>
ffffffffc02023d2:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02023d6:	4e85                	li	t4,1
ffffffffc02023d8:	6b05                	lui	s6,0x1
ffffffffc02023da:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023dc:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023e0:	01585713          	srli	a4,a6,0x15
ffffffffc02023e4:	1ff77713          	andi	a4,a4,511
ffffffffc02023e8:	070e                	slli	a4,a4,0x3
ffffffffc02023ea:	9772                	add	a4,a4,t3
ffffffffc02023ec:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc02023ee:	0017f693          	andi	a3,a5,1
ffffffffc02023f2:	e6bd                	bnez	a3,ffffffffc0202460 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc02023f4:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc02023f6:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023f8:	00080863          	beqz	a6,ffffffffc0202408 <exit_range+0xe8>
ffffffffc02023fc:	879a                	mv	a5,t1
ffffffffc02023fe:	00667363          	bgeu	a2,t1,ffffffffc0202404 <exit_range+0xe4>
ffffffffc0202402:	87b2                	mv	a5,a2
ffffffffc0202404:	fcf86ee3          	bltu	a6,a5,ffffffffc02023e0 <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202408:	f60e8ae3          	beqz	t4,ffffffffc020237c <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc020240c:	000ab783          	ld	a5,0(s5)
ffffffffc0202410:	1af8f063          	bgeu	a7,a5,ffffffffc02025b0 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202414:	00099517          	auipc	a0,0x99
ffffffffc0202418:	39453503          	ld	a0,916(a0) # ffffffffc029b7a8 <pages>
ffffffffc020241c:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020241e:	100027f3          	csrr	a5,sstatus
ffffffffc0202422:	8b89                	andi	a5,a5,2
ffffffffc0202424:	10079b63          	bnez	a5,ffffffffc020253a <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202428:	00099797          	auipc	a5,0x99
ffffffffc020242c:	3587b783          	ld	a5,856(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0202430:	4585                	li	a1,1
ffffffffc0202432:	e432                	sd	a2,8(sp)
ffffffffc0202434:	739c                	ld	a5,32(a5)
ffffffffc0202436:	9782                	jalr	a5
ffffffffc0202438:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc020243a:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc020243e:	013487b3          	add	a5,s1,s3
ffffffffc0202442:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202446:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202448:	f3a1                	bnez	a5,ffffffffc0202388 <exit_range+0x68>
}
ffffffffc020244a:	60ea                	ld	ra,152(sp)
ffffffffc020244c:	644a                	ld	s0,144(sp)
ffffffffc020244e:	64aa                	ld	s1,136(sp)
ffffffffc0202450:	690a                	ld	s2,128(sp)
ffffffffc0202452:	79e6                	ld	s3,120(sp)
ffffffffc0202454:	7a46                	ld	s4,112(sp)
ffffffffc0202456:	7aa6                	ld	s5,104(sp)
ffffffffc0202458:	7b06                	ld	s6,96(sp)
ffffffffc020245a:	6be6                	ld	s7,88(sp)
ffffffffc020245c:	610d                	addi	sp,sp,160
ffffffffc020245e:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202460:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202464:	078a                	slli	a5,a5,0x2
ffffffffc0202466:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202468:	14a7f463          	bgeu	a5,a0,ffffffffc02025b0 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc020246c:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc020246e:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc0202472:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202476:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc020247a:	10abf263          	bgeu	s7,a0,ffffffffc020257e <exit_range+0x25e>
ffffffffc020247e:	000fb783          	ld	a5,0(t6)
ffffffffc0202482:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202484:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc0202488:	629c                	ld	a5,0(a3)
ffffffffc020248a:	8b85                	andi	a5,a5,1
ffffffffc020248c:	f7ad                	bnez	a5,ffffffffc02023f6 <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020248e:	06a1                	addi	a3,a3,8
ffffffffc0202490:	fea69ce3          	bne	a3,a0,ffffffffc0202488 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc0202494:	00099517          	auipc	a0,0x99
ffffffffc0202498:	31453503          	ld	a0,788(a0) # ffffffffc029b7a8 <pages>
ffffffffc020249c:	952e                	add	a0,a0,a1
ffffffffc020249e:	100027f3          	csrr	a5,sstatus
ffffffffc02024a2:	8b89                	andi	a5,a5,2
ffffffffc02024a4:	e3b9                	bnez	a5,ffffffffc02024ea <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02024a6:	00099797          	auipc	a5,0x99
ffffffffc02024aa:	2da7b783          	ld	a5,730(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc02024ae:	4585                	li	a1,1
ffffffffc02024b0:	e0b2                	sd	a2,64(sp)
ffffffffc02024b2:	739c                	ld	a5,32(a5)
ffffffffc02024b4:	fc1a                	sd	t1,56(sp)
ffffffffc02024b6:	f846                	sd	a7,48(sp)
ffffffffc02024b8:	f47a                	sd	t5,40(sp)
ffffffffc02024ba:	f072                	sd	t3,32(sp)
ffffffffc02024bc:	ec76                	sd	t4,24(sp)
ffffffffc02024be:	e842                	sd	a6,16(sp)
ffffffffc02024c0:	e43a                	sd	a4,8(sp)
ffffffffc02024c2:	9782                	jalr	a5
    if (flag)
ffffffffc02024c4:	6722                	ld	a4,8(sp)
ffffffffc02024c6:	6842                	ld	a6,16(sp)
ffffffffc02024c8:	6ee2                	ld	t4,24(sp)
ffffffffc02024ca:	7e02                	ld	t3,32(sp)
ffffffffc02024cc:	7f22                	ld	t5,40(sp)
ffffffffc02024ce:	78c2                	ld	a7,48(sp)
ffffffffc02024d0:	7362                	ld	t1,56(sp)
ffffffffc02024d2:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024d4:	fff802b7          	lui	t0,0xfff80
ffffffffc02024d8:	000803b7          	lui	t2,0x80
ffffffffc02024dc:	00099f97          	auipc	t6,0x99
ffffffffc02024e0:	2bcf8f93          	addi	t6,t6,700 # ffffffffc029b798 <va_pa_offset>
ffffffffc02024e4:	00073023          	sd	zero,0(a4)
ffffffffc02024e8:	b739                	j	ffffffffc02023f6 <exit_range+0xd6>
        intr_disable();
ffffffffc02024ea:	e4b2                	sd	a2,72(sp)
ffffffffc02024ec:	e09a                	sd	t1,64(sp)
ffffffffc02024ee:	fc46                	sd	a7,56(sp)
ffffffffc02024f0:	f47a                	sd	t5,40(sp)
ffffffffc02024f2:	f072                	sd	t3,32(sp)
ffffffffc02024f4:	ec76                	sd	t4,24(sp)
ffffffffc02024f6:	e842                	sd	a6,16(sp)
ffffffffc02024f8:	e43a                	sd	a4,8(sp)
ffffffffc02024fa:	f82a                	sd	a0,48(sp)
ffffffffc02024fc:	c08fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202500:	00099797          	auipc	a5,0x99
ffffffffc0202504:	2807b783          	ld	a5,640(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0202508:	7542                	ld	a0,48(sp)
ffffffffc020250a:	4585                	li	a1,1
ffffffffc020250c:	739c                	ld	a5,32(a5)
ffffffffc020250e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202510:	beefe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202514:	6722                	ld	a4,8(sp)
ffffffffc0202516:	6626                	ld	a2,72(sp)
ffffffffc0202518:	6306                	ld	t1,64(sp)
ffffffffc020251a:	78e2                	ld	a7,56(sp)
ffffffffc020251c:	7f22                	ld	t5,40(sp)
ffffffffc020251e:	7e02                	ld	t3,32(sp)
ffffffffc0202520:	6ee2                	ld	t4,24(sp)
ffffffffc0202522:	6842                	ld	a6,16(sp)
ffffffffc0202524:	00099f97          	auipc	t6,0x99
ffffffffc0202528:	274f8f93          	addi	t6,t6,628 # ffffffffc029b798 <va_pa_offset>
ffffffffc020252c:	000803b7          	lui	t2,0x80
ffffffffc0202530:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202534:	00073023          	sd	zero,0(a4)
ffffffffc0202538:	bd7d                	j	ffffffffc02023f6 <exit_range+0xd6>
        intr_disable();
ffffffffc020253a:	e832                	sd	a2,16(sp)
ffffffffc020253c:	e42a                	sd	a0,8(sp)
ffffffffc020253e:	bc6fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202542:	00099797          	auipc	a5,0x99
ffffffffc0202546:	23e7b783          	ld	a5,574(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc020254a:	6522                	ld	a0,8(sp)
ffffffffc020254c:	4585                	li	a1,1
ffffffffc020254e:	739c                	ld	a5,32(a5)
ffffffffc0202550:	9782                	jalr	a5
        intr_enable();
ffffffffc0202552:	bacfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202556:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202558:	00043023          	sd	zero,0(s0)
ffffffffc020255c:	b5cd                	j	ffffffffc020243e <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020255e:	00004697          	auipc	a3,0x4
ffffffffc0202562:	09a68693          	addi	a3,a3,154 # ffffffffc02065f8 <etext+0xe68>
ffffffffc0202566:	00004617          	auipc	a2,0x4
ffffffffc020256a:	be260613          	addi	a2,a2,-1054 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020256e:	13500593          	li	a1,309
ffffffffc0202572:	00004517          	auipc	a0,0x4
ffffffffc0202576:	07650513          	addi	a0,a0,118 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020257a:	ecdfd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020257e:	00004617          	auipc	a2,0x4
ffffffffc0202582:	f7a60613          	addi	a2,a2,-134 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0202586:	07100593          	li	a1,113
ffffffffc020258a:	00004517          	auipc	a0,0x4
ffffffffc020258e:	f9650513          	addi	a0,a0,-106 # ffffffffc0206520 <etext+0xd90>
ffffffffc0202592:	eb5fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202596:	86f2                	mv	a3,t3
ffffffffc0202598:	00004617          	auipc	a2,0x4
ffffffffc020259c:	f6060613          	addi	a2,a2,-160 # ffffffffc02064f8 <etext+0xd68>
ffffffffc02025a0:	07100593          	li	a1,113
ffffffffc02025a4:	00004517          	auipc	a0,0x4
ffffffffc02025a8:	f7c50513          	addi	a0,a0,-132 # ffffffffc0206520 <etext+0xd90>
ffffffffc02025ac:	e9bfd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02025b0:	8c7ff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025b4:	00004697          	auipc	a3,0x4
ffffffffc02025b8:	07468693          	addi	a3,a3,116 # ffffffffc0206628 <etext+0xe98>
ffffffffc02025bc:	00004617          	auipc	a2,0x4
ffffffffc02025c0:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02025c4:	13600593          	li	a1,310
ffffffffc02025c8:	00004517          	auipc	a0,0x4
ffffffffc02025cc:	02050513          	addi	a0,a0,32 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02025d0:	e77fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02025d4 <page_remove>:
{
ffffffffc02025d4:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025d6:	4601                	li	a2,0
{
ffffffffc02025d8:	e822                	sd	s0,16(sp)
ffffffffc02025da:	ec06                	sd	ra,24(sp)
ffffffffc02025dc:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025de:	95dff0ef          	jal	ffffffffc0201f3a <get_pte>
    if (ptep != NULL)
ffffffffc02025e2:	c511                	beqz	a0,ffffffffc02025ee <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc02025e4:	6118                	ld	a4,0(a0)
ffffffffc02025e6:	87aa                	mv	a5,a0
ffffffffc02025e8:	00177693          	andi	a3,a4,1
ffffffffc02025ec:	e689                	bnez	a3,ffffffffc02025f6 <page_remove+0x22>
}
ffffffffc02025ee:	60e2                	ld	ra,24(sp)
ffffffffc02025f0:	6442                	ld	s0,16(sp)
ffffffffc02025f2:	6105                	addi	sp,sp,32
ffffffffc02025f4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02025f6:	00099697          	auipc	a3,0x99
ffffffffc02025fa:	1aa6b683          	ld	a3,426(a3) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02025fe:	070a                	slli	a4,a4,0x2
ffffffffc0202600:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202602:	06d77563          	bgeu	a4,a3,ffffffffc020266c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202606:	00099517          	auipc	a0,0x99
ffffffffc020260a:	1a253503          	ld	a0,418(a0) # ffffffffc029b7a8 <pages>
ffffffffc020260e:	071a                	slli	a4,a4,0x6
ffffffffc0202610:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202614:	9736                	add	a4,a4,a3
ffffffffc0202616:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202618:	4118                	lw	a4,0(a0)
ffffffffc020261a:	377d                	addiw	a4,a4,-1
ffffffffc020261c:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020261e:	cb09                	beqz	a4,ffffffffc0202630 <page_remove+0x5c>
        *ptep = 0;
ffffffffc0202620:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202624:	12040073          	sfence.vma	s0
}
ffffffffc0202628:	60e2                	ld	ra,24(sp)
ffffffffc020262a:	6442                	ld	s0,16(sp)
ffffffffc020262c:	6105                	addi	sp,sp,32
ffffffffc020262e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202630:	10002773          	csrr	a4,sstatus
ffffffffc0202634:	8b09                	andi	a4,a4,2
ffffffffc0202636:	eb19                	bnez	a4,ffffffffc020264c <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202638:	00099717          	auipc	a4,0x99
ffffffffc020263c:	14873703          	ld	a4,328(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc0202640:	4585                	li	a1,1
ffffffffc0202642:	e03e                	sd	a5,0(sp)
ffffffffc0202644:	7318                	ld	a4,32(a4)
ffffffffc0202646:	9702                	jalr	a4
    if (flag)
ffffffffc0202648:	6782                	ld	a5,0(sp)
ffffffffc020264a:	bfd9                	j	ffffffffc0202620 <page_remove+0x4c>
        intr_disable();
ffffffffc020264c:	e43e                	sd	a5,8(sp)
ffffffffc020264e:	e02a                	sd	a0,0(sp)
ffffffffc0202650:	ab4fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202654:	00099717          	auipc	a4,0x99
ffffffffc0202658:	12c73703          	ld	a4,300(a4) # ffffffffc029b780 <pmm_manager>
ffffffffc020265c:	6502                	ld	a0,0(sp)
ffffffffc020265e:	4585                	li	a1,1
ffffffffc0202660:	7318                	ld	a4,32(a4)
ffffffffc0202662:	9702                	jalr	a4
        intr_enable();
ffffffffc0202664:	a9afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202668:	67a2                	ld	a5,8(sp)
ffffffffc020266a:	bf5d                	j	ffffffffc0202620 <page_remove+0x4c>
ffffffffc020266c:	80bff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc0202670 <page_insert>:
{
ffffffffc0202670:	7139                	addi	sp,sp,-64
ffffffffc0202672:	f426                	sd	s1,40(sp)
ffffffffc0202674:	84b2                	mv	s1,a2
ffffffffc0202676:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202678:	4605                	li	a2,1
{
ffffffffc020267a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020267c:	85a6                	mv	a1,s1
{
ffffffffc020267e:	fc06                	sd	ra,56(sp)
ffffffffc0202680:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202682:	8b9ff0ef          	jal	ffffffffc0201f3a <get_pte>
    if (ptep == NULL)
ffffffffc0202686:	cd61                	beqz	a0,ffffffffc020275e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202688:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020268a:	611c                	ld	a5,0(a0)
ffffffffc020268c:	66a2                	ld	a3,8(sp)
ffffffffc020268e:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7bcf>
ffffffffc0202692:	c010                	sw	a2,0(s0)
ffffffffc0202694:	0017f613          	andi	a2,a5,1
ffffffffc0202698:	872a                	mv	a4,a0
ffffffffc020269a:	e61d                	bnez	a2,ffffffffc02026c8 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020269c:	00099617          	auipc	a2,0x99
ffffffffc02026a0:	10c63603          	ld	a2,268(a2) # ffffffffc029b7a8 <pages>
    return page - pages + nbase;
ffffffffc02026a4:	8c11                	sub	s0,s0,a2
ffffffffc02026a6:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026a8:	200007b7          	lui	a5,0x20000
ffffffffc02026ac:	042a                	slli	s0,s0,0xa
ffffffffc02026ae:	943e                	add	s0,s0,a5
ffffffffc02026b0:	8ec1                	or	a3,a3,s0
ffffffffc02026b2:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026b6:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026b8:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02026bc:	4501                	li	a0,0
}
ffffffffc02026be:	70e2                	ld	ra,56(sp)
ffffffffc02026c0:	7442                	ld	s0,48(sp)
ffffffffc02026c2:	74a2                	ld	s1,40(sp)
ffffffffc02026c4:	6121                	addi	sp,sp,64
ffffffffc02026c6:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026c8:	00099617          	auipc	a2,0x99
ffffffffc02026cc:	0d863603          	ld	a2,216(a2) # ffffffffc029b7a0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026d0:	078a                	slli	a5,a5,0x2
ffffffffc02026d2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026d4:	08c7f763          	bgeu	a5,a2,ffffffffc0202762 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026d8:	00099617          	auipc	a2,0x99
ffffffffc02026dc:	0d063603          	ld	a2,208(a2) # ffffffffc029b7a8 <pages>
ffffffffc02026e0:	fe000537          	lui	a0,0xfe000
ffffffffc02026e4:	079a                	slli	a5,a5,0x6
ffffffffc02026e6:	97aa                	add	a5,a5,a0
ffffffffc02026e8:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02026ec:	00a40963          	beq	s0,a0,ffffffffc02026fe <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02026f0:	411c                	lw	a5,0(a0)
ffffffffc02026f2:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_exit_out_size+0x1fff5e27>
ffffffffc02026f4:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc02026f6:	c791                	beqz	a5,ffffffffc0202702 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026f8:	12048073          	sfence.vma	s1
}
ffffffffc02026fc:	b765                	j	ffffffffc02026a4 <page_insert+0x34>
ffffffffc02026fe:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202700:	b755                	j	ffffffffc02026a4 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202702:	100027f3          	csrr	a5,sstatus
ffffffffc0202706:	8b89                	andi	a5,a5,2
ffffffffc0202708:	e39d                	bnez	a5,ffffffffc020272e <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc020270a:	00099797          	auipc	a5,0x99
ffffffffc020270e:	0767b783          	ld	a5,118(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0202712:	4585                	li	a1,1
ffffffffc0202714:	e83a                	sd	a4,16(sp)
ffffffffc0202716:	739c                	ld	a5,32(a5)
ffffffffc0202718:	e436                	sd	a3,8(sp)
ffffffffc020271a:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020271c:	00099617          	auipc	a2,0x99
ffffffffc0202720:	08c63603          	ld	a2,140(a2) # ffffffffc029b7a8 <pages>
ffffffffc0202724:	66a2                	ld	a3,8(sp)
ffffffffc0202726:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202728:	12048073          	sfence.vma	s1
ffffffffc020272c:	bfa5                	j	ffffffffc02026a4 <page_insert+0x34>
        intr_disable();
ffffffffc020272e:	ec3a                	sd	a4,24(sp)
ffffffffc0202730:	e836                	sd	a3,16(sp)
ffffffffc0202732:	e42a                	sd	a0,8(sp)
ffffffffc0202734:	9d0fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202738:	00099797          	auipc	a5,0x99
ffffffffc020273c:	0487b783          	ld	a5,72(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0202740:	6522                	ld	a0,8(sp)
ffffffffc0202742:	4585                	li	a1,1
ffffffffc0202744:	739c                	ld	a5,32(a5)
ffffffffc0202746:	9782                	jalr	a5
        intr_enable();
ffffffffc0202748:	9b6fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020274c:	00099617          	auipc	a2,0x99
ffffffffc0202750:	05c63603          	ld	a2,92(a2) # ffffffffc029b7a8 <pages>
ffffffffc0202754:	6762                	ld	a4,24(sp)
ffffffffc0202756:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202758:	12048073          	sfence.vma	s1
ffffffffc020275c:	b7a1                	j	ffffffffc02026a4 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc020275e:	5571                	li	a0,-4
ffffffffc0202760:	bfb9                	j	ffffffffc02026be <page_insert+0x4e>
ffffffffc0202762:	f14ff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc0202766 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202766:	00005797          	auipc	a5,0x5
ffffffffc020276a:	dfa78793          	addi	a5,a5,-518 # ffffffffc0207560 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020276e:	638c                	ld	a1,0(a5)
{
ffffffffc0202770:	7159                	addi	sp,sp,-112
ffffffffc0202772:	f486                	sd	ra,104(sp)
ffffffffc0202774:	e8ca                	sd	s2,80(sp)
ffffffffc0202776:	e4ce                	sd	s3,72(sp)
ffffffffc0202778:	f85a                	sd	s6,48(sp)
ffffffffc020277a:	f0a2                	sd	s0,96(sp)
ffffffffc020277c:	eca6                	sd	s1,88(sp)
ffffffffc020277e:	e0d2                	sd	s4,64(sp)
ffffffffc0202780:	fc56                	sd	s5,56(sp)
ffffffffc0202782:	f45e                	sd	s7,40(sp)
ffffffffc0202784:	f062                	sd	s8,32(sp)
ffffffffc0202786:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202788:	00099b17          	auipc	s6,0x99
ffffffffc020278c:	ff8b0b13          	addi	s6,s6,-8 # ffffffffc029b780 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202790:	00004517          	auipc	a0,0x4
ffffffffc0202794:	eb050513          	addi	a0,a0,-336 # ffffffffc0206640 <etext+0xeb0>
    pmm_manager = &default_pmm_manager;
ffffffffc0202798:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020279c:	9f9fd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027a0:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027a4:	00099997          	auipc	s3,0x99
ffffffffc02027a8:	ff498993          	addi	s3,s3,-12 # ffffffffc029b798 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027ac:	679c                	ld	a5,8(a5)
ffffffffc02027ae:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027b0:	57f5                	li	a5,-3
ffffffffc02027b2:	07fa                	slli	a5,a5,0x1e
ffffffffc02027b4:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027b8:	932fe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc02027bc:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027be:	936fe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027c2:	70050e63          	beqz	a0,ffffffffc0202ede <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027c6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027c8:	00004517          	auipc	a0,0x4
ffffffffc02027cc:	eb050513          	addi	a0,a0,-336 # ffffffffc0206678 <etext+0xee8>
ffffffffc02027d0:	9c5fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027d4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027d8:	864a                	mv	a2,s2
ffffffffc02027da:	85a6                	mv	a1,s1
ffffffffc02027dc:	fff40693          	addi	a3,s0,-1
ffffffffc02027e0:	00004517          	auipc	a0,0x4
ffffffffc02027e4:	eb050513          	addi	a0,a0,-336 # ffffffffc0206690 <etext+0xf00>
ffffffffc02027e8:	9adfd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02027ec:	c80007b7          	lui	a5,0xc8000
ffffffffc02027f0:	8522                	mv	a0,s0
ffffffffc02027f2:	5287ed63          	bltu	a5,s0,ffffffffc0202d2c <pmm_init+0x5c6>
ffffffffc02027f6:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027f8:	0009a617          	auipc	a2,0x9a
ffffffffc02027fc:	fd760613          	addi	a2,a2,-41 # ffffffffc029c7cf <end+0xfff>
ffffffffc0202800:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc0202802:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202804:	00099b97          	auipc	s7,0x99
ffffffffc0202808:	fa4b8b93          	addi	s7,s7,-92 # ffffffffc029b7a8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020280c:	00099497          	auipc	s1,0x99
ffffffffc0202810:	f9448493          	addi	s1,s1,-108 # ffffffffc029b7a0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202814:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202818:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020281a:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020281e:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202820:	02f50763          	beq	a0,a5,ffffffffc020284e <pmm_init+0xe8>
ffffffffc0202824:	4701                	li	a4,0
ffffffffc0202826:	4585                	li	a1,1
ffffffffc0202828:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020282c:	00671793          	slli	a5,a4,0x6
ffffffffc0202830:	97b2                	add	a5,a5,a2
ffffffffc0202832:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_exit_out_size+0x75e30>
ffffffffc0202834:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202838:	6088                	ld	a0,0(s1)
ffffffffc020283a:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020283c:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202840:	00d507b3          	add	a5,a0,a3
ffffffffc0202844:	fef764e3          	bltu	a4,a5,ffffffffc020282c <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202848:	079a                	slli	a5,a5,0x6
ffffffffc020284a:	00f606b3          	add	a3,a2,a5
ffffffffc020284e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202852:	16f6eee3          	bltu	a3,a5,ffffffffc02031ce <pmm_init+0xa68>
ffffffffc0202856:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020285a:	77fd                	lui	a5,0xfffff
ffffffffc020285c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020285e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202860:	4e86ed63          	bltu	a3,s0,ffffffffc0202d5a <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202864:	00004517          	auipc	a0,0x4
ffffffffc0202868:	e5450513          	addi	a0,a0,-428 # ffffffffc02066b8 <etext+0xf28>
ffffffffc020286c:	929fd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202870:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202874:	00099917          	auipc	s2,0x99
ffffffffc0202878:	f1c90913          	addi	s2,s2,-228 # ffffffffc029b790 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020287c:	7b9c                	ld	a5,48(a5)
ffffffffc020287e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202880:	00004517          	auipc	a0,0x4
ffffffffc0202884:	e5050513          	addi	a0,a0,-432 # ffffffffc02066d0 <etext+0xf40>
ffffffffc0202888:	90dfd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020288c:	00007697          	auipc	a3,0x7
ffffffffc0202890:	77468693          	addi	a3,a3,1908 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202894:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202898:	c02007b7          	lui	a5,0xc0200
ffffffffc020289c:	2af6eee3          	bltu	a3,a5,ffffffffc0203358 <pmm_init+0xbf2>
ffffffffc02028a0:	0009b783          	ld	a5,0(s3)
ffffffffc02028a4:	8e9d                	sub	a3,a3,a5
ffffffffc02028a6:	00099797          	auipc	a5,0x99
ffffffffc02028aa:	eed7b123          	sd	a3,-286(a5) # ffffffffc029b788 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028ae:	100027f3          	csrr	a5,sstatus
ffffffffc02028b2:	8b89                	andi	a5,a5,2
ffffffffc02028b4:	48079963          	bnez	a5,ffffffffc0202d46 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028b8:	000b3783          	ld	a5,0(s6)
ffffffffc02028bc:	779c                	ld	a5,40(a5)
ffffffffc02028be:	9782                	jalr	a5
ffffffffc02028c0:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028c2:	6098                	ld	a4,0(s1)
ffffffffc02028c4:	c80007b7          	lui	a5,0xc8000
ffffffffc02028c8:	83b1                	srli	a5,a5,0xc
ffffffffc02028ca:	66e7e663          	bltu	a5,a4,ffffffffc0202f36 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028ce:	00093503          	ld	a0,0(s2)
ffffffffc02028d2:	64050263          	beqz	a0,ffffffffc0202f16 <pmm_init+0x7b0>
ffffffffc02028d6:	03451793          	slli	a5,a0,0x34
ffffffffc02028da:	62079e63          	bnez	a5,ffffffffc0202f16 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028de:	4601                	li	a2,0
ffffffffc02028e0:	4581                	li	a1,0
ffffffffc02028e2:	8b7ff0ef          	jal	ffffffffc0202198 <get_page>
ffffffffc02028e6:	240519e3          	bnez	a0,ffffffffc0203338 <pmm_init+0xbd2>
ffffffffc02028ea:	100027f3          	csrr	a5,sstatus
ffffffffc02028ee:	8b89                	andi	a5,a5,2
ffffffffc02028f0:	44079063          	bnez	a5,ffffffffc0202d30 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028f4:	000b3783          	ld	a5,0(s6)
ffffffffc02028f8:	4505                	li	a0,1
ffffffffc02028fa:	6f9c                	ld	a5,24(a5)
ffffffffc02028fc:	9782                	jalr	a5
ffffffffc02028fe:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202900:	00093503          	ld	a0,0(s2)
ffffffffc0202904:	4681                	li	a3,0
ffffffffc0202906:	4601                	li	a2,0
ffffffffc0202908:	85d2                	mv	a1,s4
ffffffffc020290a:	d67ff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc020290e:	280511e3          	bnez	a0,ffffffffc0203390 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202912:	00093503          	ld	a0,0(s2)
ffffffffc0202916:	4601                	li	a2,0
ffffffffc0202918:	4581                	li	a1,0
ffffffffc020291a:	e20ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc020291e:	240509e3          	beqz	a0,ffffffffc0203370 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202922:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202924:	0017f713          	andi	a4,a5,1
ffffffffc0202928:	58070f63          	beqz	a4,ffffffffc0202ec6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc020292c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020292e:	078a                	slli	a5,a5,0x2
ffffffffc0202930:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202932:	58e7f863          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202936:	000bb683          	ld	a3,0(s7)
ffffffffc020293a:	079a                	slli	a5,a5,0x6
ffffffffc020293c:	fe000637          	lui	a2,0xfe000
ffffffffc0202940:	97b2                	add	a5,a5,a2
ffffffffc0202942:	97b6                	add	a5,a5,a3
ffffffffc0202944:	14fa1ae3          	bne	s4,a5,ffffffffc0203298 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202948:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_exit_out_size+0x1f5e28>
ffffffffc020294c:	4785                	li	a5,1
ffffffffc020294e:	12f695e3          	bne	a3,a5,ffffffffc0203278 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202952:	00093503          	ld	a0,0(s2)
ffffffffc0202956:	77fd                	lui	a5,0xfffff
ffffffffc0202958:	6114                	ld	a3,0(a0)
ffffffffc020295a:	068a                	slli	a3,a3,0x2
ffffffffc020295c:	8efd                	and	a3,a3,a5
ffffffffc020295e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202962:	0ee67fe3          	bgeu	a2,a4,ffffffffc0203260 <pmm_init+0xafa>
ffffffffc0202966:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020296a:	96e2                	add	a3,a3,s8
ffffffffc020296c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202970:	0a8a                	slli	s5,s5,0x2
ffffffffc0202972:	00fafab3          	and	s5,s5,a5
ffffffffc0202976:	00cad793          	srli	a5,s5,0xc
ffffffffc020297a:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0203246 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020297e:	4601                	li	a2,0
ffffffffc0202980:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202982:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202984:	db6ff0ef          	jal	ffffffffc0201f3a <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202988:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020298a:	05851ee3          	bne	a0,s8,ffffffffc02031e6 <pmm_init+0xa80>
ffffffffc020298e:	100027f3          	csrr	a5,sstatus
ffffffffc0202992:	8b89                	andi	a5,a5,2
ffffffffc0202994:	3e079b63          	bnez	a5,ffffffffc0202d8a <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202998:	000b3783          	ld	a5,0(s6)
ffffffffc020299c:	4505                	li	a0,1
ffffffffc020299e:	6f9c                	ld	a5,24(a5)
ffffffffc02029a0:	9782                	jalr	a5
ffffffffc02029a2:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029a4:	00093503          	ld	a0,0(s2)
ffffffffc02029a8:	46d1                	li	a3,20
ffffffffc02029aa:	6605                	lui	a2,0x1
ffffffffc02029ac:	85e2                	mv	a1,s8
ffffffffc02029ae:	cc3ff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc02029b2:	06051ae3          	bnez	a0,ffffffffc0203226 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029b6:	00093503          	ld	a0,0(s2)
ffffffffc02029ba:	4601                	li	a2,0
ffffffffc02029bc:	6585                	lui	a1,0x1
ffffffffc02029be:	d7cff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc02029c2:	040502e3          	beqz	a0,ffffffffc0203206 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02029c6:	611c                	ld	a5,0(a0)
ffffffffc02029c8:	0107f713          	andi	a4,a5,16
ffffffffc02029cc:	7e070163          	beqz	a4,ffffffffc02031ae <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02029d0:	8b91                	andi	a5,a5,4
ffffffffc02029d2:	7a078e63          	beqz	a5,ffffffffc020318e <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029d6:	00093503          	ld	a0,0(s2)
ffffffffc02029da:	611c                	ld	a5,0(a0)
ffffffffc02029dc:	8bc1                	andi	a5,a5,16
ffffffffc02029de:	78078863          	beqz	a5,ffffffffc020316e <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02029e2:	000c2703          	lw	a4,0(s8)
ffffffffc02029e6:	4785                	li	a5,1
ffffffffc02029e8:	76f71363          	bne	a4,a5,ffffffffc020314e <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029ec:	4681                	li	a3,0
ffffffffc02029ee:	6605                	lui	a2,0x1
ffffffffc02029f0:	85d2                	mv	a1,s4
ffffffffc02029f2:	c7fff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc02029f6:	72051c63          	bnez	a0,ffffffffc020312e <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02029fa:	000a2703          	lw	a4,0(s4)
ffffffffc02029fe:	4789                	li	a5,2
ffffffffc0202a00:	70f71763          	bne	a4,a5,ffffffffc020310e <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202a04:	000c2783          	lw	a5,0(s8)
ffffffffc0202a08:	6e079363          	bnez	a5,ffffffffc02030ee <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a0c:	00093503          	ld	a0,0(s2)
ffffffffc0202a10:	4601                	li	a2,0
ffffffffc0202a12:	6585                	lui	a1,0x1
ffffffffc0202a14:	d26ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0202a18:	6a050b63          	beqz	a0,ffffffffc02030ce <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a1c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a1e:	00177793          	andi	a5,a4,1
ffffffffc0202a22:	4a078263          	beqz	a5,ffffffffc0202ec6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a26:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a28:	00271793          	slli	a5,a4,0x2
ffffffffc0202a2c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a2e:	48d7fa63          	bgeu	a5,a3,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a32:	000bb683          	ld	a3,0(s7)
ffffffffc0202a36:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a3a:	97d6                	add	a5,a5,s5
ffffffffc0202a3c:	079a                	slli	a5,a5,0x6
ffffffffc0202a3e:	97b6                	add	a5,a5,a3
ffffffffc0202a40:	66fa1763          	bne	s4,a5,ffffffffc02030ae <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a44:	8b41                	andi	a4,a4,16
ffffffffc0202a46:	64071463          	bnez	a4,ffffffffc020308e <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a4a:	00093503          	ld	a0,0(s2)
ffffffffc0202a4e:	4581                	li	a1,0
ffffffffc0202a50:	b85ff0ef          	jal	ffffffffc02025d4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a54:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a58:	4785                	li	a5,1
ffffffffc0202a5a:	60fc9a63          	bne	s9,a5,ffffffffc020306e <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202a5e:	000c2783          	lw	a5,0(s8)
ffffffffc0202a62:	5e079663          	bnez	a5,ffffffffc020304e <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a66:	00093503          	ld	a0,0(s2)
ffffffffc0202a6a:	6585                	lui	a1,0x1
ffffffffc0202a6c:	b69ff0ef          	jal	ffffffffc02025d4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a70:	000a2783          	lw	a5,0(s4)
ffffffffc0202a74:	52079d63          	bnez	a5,ffffffffc0202fae <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202a78:	000c2783          	lw	a5,0(s8)
ffffffffc0202a7c:	50079963          	bnez	a5,ffffffffc0202f8e <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a80:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a84:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a86:	000a3783          	ld	a5,0(s4)
ffffffffc0202a8a:	078a                	slli	a5,a5,0x2
ffffffffc0202a8c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a8e:	42e7fa63          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a92:	000bb503          	ld	a0,0(s7)
ffffffffc0202a96:	97d6                	add	a5,a5,s5
ffffffffc0202a98:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202a9a:	00f506b3          	add	a3,a0,a5
ffffffffc0202a9e:	4294                	lw	a3,0(a3)
ffffffffc0202aa0:	4d969763          	bne	a3,s9,ffffffffc0202f6e <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202aa4:	8799                	srai	a5,a5,0x6
ffffffffc0202aa6:	00080637          	lui	a2,0x80
ffffffffc0202aaa:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202aac:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202ab0:	4ae7f363          	bgeu	a5,a4,ffffffffc0202f56 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ab4:	0009b783          	ld	a5,0(s3)
ffffffffc0202ab8:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aba:	639c                	ld	a5,0(a5)
ffffffffc0202abc:	078a                	slli	a5,a5,0x2
ffffffffc0202abe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ac0:	40e7f163          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ac4:	8f91                	sub	a5,a5,a2
ffffffffc0202ac6:	079a                	slli	a5,a5,0x6
ffffffffc0202ac8:	953e                	add	a0,a0,a5
ffffffffc0202aca:	100027f3          	csrr	a5,sstatus
ffffffffc0202ace:	8b89                	andi	a5,a5,2
ffffffffc0202ad0:	30079863          	bnez	a5,ffffffffc0202de0 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202ad4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ad8:	4585                	li	a1,1
ffffffffc0202ada:	739c                	ld	a5,32(a5)
ffffffffc0202adc:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ade:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202ae2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ae4:	078a                	slli	a5,a5,0x2
ffffffffc0202ae6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ae8:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aec:	000bb503          	ld	a0,0(s7)
ffffffffc0202af0:	fe000737          	lui	a4,0xfe000
ffffffffc0202af4:	079a                	slli	a5,a5,0x6
ffffffffc0202af6:	97ba                	add	a5,a5,a4
ffffffffc0202af8:	953e                	add	a0,a0,a5
ffffffffc0202afa:	100027f3          	csrr	a5,sstatus
ffffffffc0202afe:	8b89                	andi	a5,a5,2
ffffffffc0202b00:	2c079463          	bnez	a5,ffffffffc0202dc8 <pmm_init+0x662>
ffffffffc0202b04:	000b3783          	ld	a5,0(s6)
ffffffffc0202b08:	4585                	li	a1,1
ffffffffc0202b0a:	739c                	ld	a5,32(a5)
ffffffffc0202b0c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b0e:	00093783          	ld	a5,0(s2)
ffffffffc0202b12:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd63830>
    asm volatile("sfence.vma");
ffffffffc0202b16:	12000073          	sfence.vma
ffffffffc0202b1a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b1e:	8b89                	andi	a5,a5,2
ffffffffc0202b20:	28079a63          	bnez	a5,ffffffffc0202db4 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b24:	000b3783          	ld	a5,0(s6)
ffffffffc0202b28:	779c                	ld	a5,40(a5)
ffffffffc0202b2a:	9782                	jalr	a5
ffffffffc0202b2c:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b2e:	4d441063          	bne	s0,s4,ffffffffc0202fee <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b32:	00004517          	auipc	a0,0x4
ffffffffc0202b36:	eee50513          	addi	a0,a0,-274 # ffffffffc0206a20 <etext+0x1290>
ffffffffc0202b3a:	e5afd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202b3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b42:	8b89                	andi	a5,a5,2
ffffffffc0202b44:	24079e63          	bnez	a5,ffffffffc0202da0 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b48:	000b3783          	ld	a5,0(s6)
ffffffffc0202b4c:	779c                	ld	a5,40(a5)
ffffffffc0202b4e:	9782                	jalr	a5
ffffffffc0202b50:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b52:	609c                	ld	a5,0(s1)
ffffffffc0202b54:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b58:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b5a:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b5e:	6a85                	lui	s5,0x1
ffffffffc0202b60:	02e47c63          	bgeu	s0,a4,ffffffffc0202b98 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b64:	00c45713          	srli	a4,s0,0xc
ffffffffc0202b68:	30f77063          	bgeu	a4,a5,ffffffffc0202e68 <pmm_init+0x702>
ffffffffc0202b6c:	0009b583          	ld	a1,0(s3)
ffffffffc0202b70:	00093503          	ld	a0,0(s2)
ffffffffc0202b74:	4601                	li	a2,0
ffffffffc0202b76:	95a2                	add	a1,a1,s0
ffffffffc0202b78:	bc2ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0202b7c:	32050363          	beqz	a0,ffffffffc0202ea2 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b80:	611c                	ld	a5,0(a0)
ffffffffc0202b82:	078a                	slli	a5,a5,0x2
ffffffffc0202b84:	0147f7b3          	and	a5,a5,s4
ffffffffc0202b88:	2e879d63          	bne	a5,s0,ffffffffc0202e82 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b8c:	609c                	ld	a5,0(s1)
ffffffffc0202b8e:	9456                	add	s0,s0,s5
ffffffffc0202b90:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b94:	fce468e3          	bltu	s0,a4,ffffffffc0202b64 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b98:	00093783          	ld	a5,0(s2)
ffffffffc0202b9c:	639c                	ld	a5,0(a5)
ffffffffc0202b9e:	42079863          	bnez	a5,ffffffffc0202fce <pmm_init+0x868>
ffffffffc0202ba2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ba6:	8b89                	andi	a5,a5,2
ffffffffc0202ba8:	24079863          	bnez	a5,ffffffffc0202df8 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bac:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb0:	4505                	li	a0,1
ffffffffc0202bb2:	6f9c                	ld	a5,24(a5)
ffffffffc0202bb4:	9782                	jalr	a5
ffffffffc0202bb6:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bb8:	00093503          	ld	a0,0(s2)
ffffffffc0202bbc:	4699                	li	a3,6
ffffffffc0202bbe:	10000613          	li	a2,256
ffffffffc0202bc2:	85a2                	mv	a1,s0
ffffffffc0202bc4:	aadff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc0202bc8:	46051363          	bnez	a0,ffffffffc020302e <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202bcc:	4018                	lw	a4,0(s0)
ffffffffc0202bce:	4785                	li	a5,1
ffffffffc0202bd0:	42f71f63          	bne	a4,a5,ffffffffc020300e <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	6605                	lui	a2,0x1
ffffffffc0202bda:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7ad0>
ffffffffc0202bde:	4699                	li	a3,6
ffffffffc0202be0:	85a2                	mv	a1,s0
ffffffffc0202be2:	a8fff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc0202be6:	72051963          	bnez	a0,ffffffffc0203318 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202bea:	4018                	lw	a4,0(s0)
ffffffffc0202bec:	4789                	li	a5,2
ffffffffc0202bee:	70f71563          	bne	a4,a5,ffffffffc02032f8 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bf2:	00004597          	auipc	a1,0x4
ffffffffc0202bf6:	f7658593          	addi	a1,a1,-138 # ffffffffc0206b68 <etext+0x13d8>
ffffffffc0202bfa:	10000513          	li	a0,256
ffffffffc0202bfe:	2e9020ef          	jal	ffffffffc02056e6 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c02:	6585                	lui	a1,0x1
ffffffffc0202c04:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7ad0>
ffffffffc0202c08:	10000513          	li	a0,256
ffffffffc0202c0c:	2ed020ef          	jal	ffffffffc02056f8 <strcmp>
ffffffffc0202c10:	6c051463          	bnez	a0,ffffffffc02032d8 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202c14:	000bb683          	ld	a3,0(s7)
ffffffffc0202c18:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c1c:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c1e:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c22:	8699                	srai	a3,a3,0x6
ffffffffc0202c24:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c26:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c2a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c2c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c2e:	32e7f463          	bgeu	a5,a4,ffffffffc0202f56 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c32:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c36:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c3a:	97b6                	add	a5,a5,a3
ffffffffc0202c3c:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x75f28>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c40:	273020ef          	jal	ffffffffc02056b2 <strlen>
ffffffffc0202c44:	66051a63          	bnez	a0,ffffffffc02032b8 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c48:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c4c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c4e:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd63830>
ffffffffc0202c52:	078a                	slli	a5,a5,0x2
ffffffffc0202c54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c56:	26e7f663          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c5a:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202c5e:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202f56 <pmm_init+0x7f0>
ffffffffc0202c62:	0009b783          	ld	a5,0(s3)
ffffffffc0202c66:	00f689b3          	add	s3,a3,a5
ffffffffc0202c6a:	100027f3          	csrr	a5,sstatus
ffffffffc0202c6e:	8b89                	andi	a5,a5,2
ffffffffc0202c70:	1e079163          	bnez	a5,ffffffffc0202e52 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202c74:	000b3783          	ld	a5,0(s6)
ffffffffc0202c78:	8522                	mv	a0,s0
ffffffffc0202c7a:	4585                	li	a1,1
ffffffffc0202c7c:	739c                	ld	a5,32(a5)
ffffffffc0202c7e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c80:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202c84:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c86:	078a                	slli	a5,a5,0x2
ffffffffc0202c88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c8a:	22e7fc63          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c8e:	000bb503          	ld	a0,0(s7)
ffffffffc0202c92:	fe000737          	lui	a4,0xfe000
ffffffffc0202c96:	079a                	slli	a5,a5,0x6
ffffffffc0202c98:	97ba                	add	a5,a5,a4
ffffffffc0202c9a:	953e                	add	a0,a0,a5
ffffffffc0202c9c:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca0:	8b89                	andi	a5,a5,2
ffffffffc0202ca2:	18079c63          	bnez	a5,ffffffffc0202e3a <pmm_init+0x6d4>
ffffffffc0202ca6:	000b3783          	ld	a5,0(s6)
ffffffffc0202caa:	4585                	li	a1,1
ffffffffc0202cac:	739c                	ld	a5,32(a5)
ffffffffc0202cae:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb0:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202cb4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb6:	078a                	slli	a5,a5,0x2
ffffffffc0202cb8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cba:	20e7f463          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cbe:	000bb503          	ld	a0,0(s7)
ffffffffc0202cc2:	fe000737          	lui	a4,0xfe000
ffffffffc0202cc6:	079a                	slli	a5,a5,0x6
ffffffffc0202cc8:	97ba                	add	a5,a5,a4
ffffffffc0202cca:	953e                	add	a0,a0,a5
ffffffffc0202ccc:	100027f3          	csrr	a5,sstatus
ffffffffc0202cd0:	8b89                	andi	a5,a5,2
ffffffffc0202cd2:	14079863          	bnez	a5,ffffffffc0202e22 <pmm_init+0x6bc>
ffffffffc0202cd6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cda:	4585                	li	a1,1
ffffffffc0202cdc:	739c                	ld	a5,32(a5)
ffffffffc0202cde:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ce0:	00093783          	ld	a5,0(s2)
ffffffffc0202ce4:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202ce8:	12000073          	sfence.vma
ffffffffc0202cec:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf0:	8b89                	andi	a5,a5,2
ffffffffc0202cf2:	10079e63          	bnez	a5,ffffffffc0202e0e <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfa:	779c                	ld	a5,40(a5)
ffffffffc0202cfc:	9782                	jalr	a5
ffffffffc0202cfe:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d00:	1e8c1b63          	bne	s8,s0,ffffffffc0202ef6 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d04:	00004517          	auipc	a0,0x4
ffffffffc0202d08:	edc50513          	addi	a0,a0,-292 # ffffffffc0206be0 <etext+0x1450>
ffffffffc0202d0c:	c88fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202d10:	7406                	ld	s0,96(sp)
ffffffffc0202d12:	70a6                	ld	ra,104(sp)
ffffffffc0202d14:	64e6                	ld	s1,88(sp)
ffffffffc0202d16:	6946                	ld	s2,80(sp)
ffffffffc0202d18:	69a6                	ld	s3,72(sp)
ffffffffc0202d1a:	6a06                	ld	s4,64(sp)
ffffffffc0202d1c:	7ae2                	ld	s5,56(sp)
ffffffffc0202d1e:	7b42                	ld	s6,48(sp)
ffffffffc0202d20:	7ba2                	ld	s7,40(sp)
ffffffffc0202d22:	7c02                	ld	s8,32(sp)
ffffffffc0202d24:	6ce2                	ld	s9,24(sp)
ffffffffc0202d26:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d28:	f85fe06f          	j	ffffffffc0201cac <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202d2c:	853e                	mv	a0,a5
ffffffffc0202d2e:	b4e1                	j	ffffffffc02027f6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202d30:	bd5fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d34:	000b3783          	ld	a5,0(s6)
ffffffffc0202d38:	4505                	li	a0,1
ffffffffc0202d3a:	6f9c                	ld	a5,24(a5)
ffffffffc0202d3c:	9782                	jalr	a5
ffffffffc0202d3e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d40:	bbffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d44:	be75                	j	ffffffffc0202900 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202d46:	bbffd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d4a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d4e:	779c                	ld	a5,40(a5)
ffffffffc0202d50:	9782                	jalr	a5
ffffffffc0202d52:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d54:	babfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d58:	b6ad                	j	ffffffffc02028c2 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d5a:	6705                	lui	a4,0x1
ffffffffc0202d5c:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7bd1>
ffffffffc0202d5e:	96ba                	add	a3,a3,a4
ffffffffc0202d60:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d62:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d66:	14a77e63          	bgeu	a4,a0,ffffffffc0202ec2 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d6a:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d6e:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202d70:	071a                	slli	a4,a4,0x6
ffffffffc0202d72:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202d76:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202d78:	6a9c                	ld	a5,16(a3)
ffffffffc0202d7a:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d7e:	00e60533          	add	a0,a2,a4
ffffffffc0202d82:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d84:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d88:	bcf1                	j	ffffffffc0202864 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202d8a:	b7bfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d92:	4505                	li	a0,1
ffffffffc0202d94:	6f9c                	ld	a5,24(a5)
ffffffffc0202d96:	9782                	jalr	a5
ffffffffc0202d98:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d9a:	b65fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d9e:	b119                	j	ffffffffc02029a4 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202da0:	b65fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202da4:	000b3783          	ld	a5,0(s6)
ffffffffc0202da8:	779c                	ld	a5,40(a5)
ffffffffc0202daa:	9782                	jalr	a5
ffffffffc0202dac:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dae:	b51fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202db2:	b345                	j	ffffffffc0202b52 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202db4:	b51fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202db8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dbc:	779c                	ld	a5,40(a5)
ffffffffc0202dbe:	9782                	jalr	a5
ffffffffc0202dc0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dc2:	b3dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dc6:	b3a5                	j	ffffffffc0202b2e <pmm_init+0x3c8>
ffffffffc0202dc8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dca:	b3bfd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dce:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd2:	6522                	ld	a0,8(sp)
ffffffffc0202dd4:	4585                	li	a1,1
ffffffffc0202dd6:	739c                	ld	a5,32(a5)
ffffffffc0202dd8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dda:	b25fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dde:	bb05                	j	ffffffffc0202b0e <pmm_init+0x3a8>
ffffffffc0202de0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202de2:	b23fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202de6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dea:	6522                	ld	a0,8(sp)
ffffffffc0202dec:	4585                	li	a1,1
ffffffffc0202dee:	739c                	ld	a5,32(a5)
ffffffffc0202df0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202df2:	b0dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202df6:	b1e5                	j	ffffffffc0202ade <pmm_init+0x378>
        intr_disable();
ffffffffc0202df8:	b0dfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dfc:	000b3783          	ld	a5,0(s6)
ffffffffc0202e00:	4505                	li	a0,1
ffffffffc0202e02:	6f9c                	ld	a5,24(a5)
ffffffffc0202e04:	9782                	jalr	a5
ffffffffc0202e06:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e08:	af7fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e0c:	b375                	j	ffffffffc0202bb8 <pmm_init+0x452>
        intr_disable();
ffffffffc0202e0e:	af7fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e12:	000b3783          	ld	a5,0(s6)
ffffffffc0202e16:	779c                	ld	a5,40(a5)
ffffffffc0202e18:	9782                	jalr	a5
ffffffffc0202e1a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e1c:	ae3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e20:	b5c5                	j	ffffffffc0202d00 <pmm_init+0x59a>
ffffffffc0202e22:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e24:	ae1fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e28:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2c:	6522                	ld	a0,8(sp)
ffffffffc0202e2e:	4585                	li	a1,1
ffffffffc0202e30:	739c                	ld	a5,32(a5)
ffffffffc0202e32:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e34:	acbfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e38:	b565                	j	ffffffffc0202ce0 <pmm_init+0x57a>
ffffffffc0202e3a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e3c:	ac9fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e40:	000b3783          	ld	a5,0(s6)
ffffffffc0202e44:	6522                	ld	a0,8(sp)
ffffffffc0202e46:	4585                	li	a1,1
ffffffffc0202e48:	739c                	ld	a5,32(a5)
ffffffffc0202e4a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e4c:	ab3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e50:	b585                	j	ffffffffc0202cb0 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202e52:	ab3fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e56:	000b3783          	ld	a5,0(s6)
ffffffffc0202e5a:	8522                	mv	a0,s0
ffffffffc0202e5c:	4585                	li	a1,1
ffffffffc0202e5e:	739c                	ld	a5,32(a5)
ffffffffc0202e60:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e62:	a9dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e66:	bd29                	j	ffffffffc0202c80 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e68:	86a2                	mv	a3,s0
ffffffffc0202e6a:	00003617          	auipc	a2,0x3
ffffffffc0202e6e:	68e60613          	addi	a2,a2,1678 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0202e72:	24c00593          	li	a1,588
ffffffffc0202e76:	00003517          	auipc	a0,0x3
ffffffffc0202e7a:	77250513          	addi	a0,a0,1906 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202e7e:	dc8fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e82:	00004697          	auipc	a3,0x4
ffffffffc0202e86:	bfe68693          	addi	a3,a3,-1026 # ffffffffc0206a80 <etext+0x12f0>
ffffffffc0202e8a:	00003617          	auipc	a2,0x3
ffffffffc0202e8e:	2be60613          	addi	a2,a2,702 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202e92:	24d00593          	li	a1,589
ffffffffc0202e96:	00003517          	auipc	a0,0x3
ffffffffc0202e9a:	75250513          	addi	a0,a0,1874 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202e9e:	da8fd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ea2:	00004697          	auipc	a3,0x4
ffffffffc0202ea6:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0206a40 <etext+0x12b0>
ffffffffc0202eaa:	00003617          	auipc	a2,0x3
ffffffffc0202eae:	29e60613          	addi	a2,a2,670 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202eb2:	24c00593          	li	a1,588
ffffffffc0202eb6:	00003517          	auipc	a0,0x3
ffffffffc0202eba:	73250513          	addi	a0,a0,1842 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202ebe:	d88fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202ec2:	fb5fe0ef          	jal	ffffffffc0201e76 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202ec6:	00004617          	auipc	a2,0x4
ffffffffc0202eca:	91a60613          	addi	a2,a2,-1766 # ffffffffc02067e0 <etext+0x1050>
ffffffffc0202ece:	07f00593          	li	a1,127
ffffffffc0202ed2:	00003517          	auipc	a0,0x3
ffffffffc0202ed6:	64e50513          	addi	a0,a0,1614 # ffffffffc0206520 <etext+0xd90>
ffffffffc0202eda:	d6cfd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202ede:	00003617          	auipc	a2,0x3
ffffffffc0202ee2:	77a60613          	addi	a2,a2,1914 # ffffffffc0206658 <etext+0xec8>
ffffffffc0202ee6:	06500593          	li	a1,101
ffffffffc0202eea:	00003517          	auipc	a0,0x3
ffffffffc0202eee:	6fe50513          	addi	a0,a0,1790 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202ef2:	d54fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ef6:	00004697          	auipc	a3,0x4
ffffffffc0202efa:	b0268693          	addi	a3,a3,-1278 # ffffffffc02069f8 <etext+0x1268>
ffffffffc0202efe:	00003617          	auipc	a2,0x3
ffffffffc0202f02:	24a60613          	addi	a2,a2,586 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202f06:	26700593          	li	a1,615
ffffffffc0202f0a:	00003517          	auipc	a0,0x3
ffffffffc0202f0e:	6de50513          	addi	a0,a0,1758 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202f12:	d34fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f16:	00003697          	auipc	a3,0x3
ffffffffc0202f1a:	7fa68693          	addi	a3,a3,2042 # ffffffffc0206710 <etext+0xf80>
ffffffffc0202f1e:	00003617          	auipc	a2,0x3
ffffffffc0202f22:	22a60613          	addi	a2,a2,554 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202f26:	20e00593          	li	a1,526
ffffffffc0202f2a:	00003517          	auipc	a0,0x3
ffffffffc0202f2e:	6be50513          	addi	a0,a0,1726 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202f32:	d14fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f36:	00003697          	auipc	a3,0x3
ffffffffc0202f3a:	7ba68693          	addi	a3,a3,1978 # ffffffffc02066f0 <etext+0xf60>
ffffffffc0202f3e:	00003617          	auipc	a2,0x3
ffffffffc0202f42:	20a60613          	addi	a2,a2,522 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202f46:	20d00593          	li	a1,525
ffffffffc0202f4a:	00003517          	auipc	a0,0x3
ffffffffc0202f4e:	69e50513          	addi	a0,a0,1694 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202f52:	cf4fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f56:	00003617          	auipc	a2,0x3
ffffffffc0202f5a:	5a260613          	addi	a2,a2,1442 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0202f5e:	07100593          	li	a1,113
ffffffffc0202f62:	00003517          	auipc	a0,0x3
ffffffffc0202f66:	5be50513          	addi	a0,a0,1470 # ffffffffc0206520 <etext+0xd90>
ffffffffc0202f6a:	cdcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f6e:	00004697          	auipc	a3,0x4
ffffffffc0202f72:	a5a68693          	addi	a3,a3,-1446 # ffffffffc02069c8 <etext+0x1238>
ffffffffc0202f76:	00003617          	auipc	a2,0x3
ffffffffc0202f7a:	1d260613          	addi	a2,a2,466 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202f7e:	23500593          	li	a1,565
ffffffffc0202f82:	00003517          	auipc	a0,0x3
ffffffffc0202f86:	66650513          	addi	a0,a0,1638 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202f8a:	cbcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f8e:	00004697          	auipc	a3,0x4
ffffffffc0202f92:	9f268693          	addi	a3,a3,-1550 # ffffffffc0206980 <etext+0x11f0>
ffffffffc0202f96:	00003617          	auipc	a2,0x3
ffffffffc0202f9a:	1b260613          	addi	a2,a2,434 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202f9e:	23300593          	li	a1,563
ffffffffc0202fa2:	00003517          	auipc	a0,0x3
ffffffffc0202fa6:	64650513          	addi	a0,a0,1606 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202faa:	c9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fae:	00004697          	auipc	a3,0x4
ffffffffc0202fb2:	a0268693          	addi	a3,a3,-1534 # ffffffffc02069b0 <etext+0x1220>
ffffffffc0202fb6:	00003617          	auipc	a2,0x3
ffffffffc0202fba:	19260613          	addi	a2,a2,402 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202fbe:	23200593          	li	a1,562
ffffffffc0202fc2:	00003517          	auipc	a0,0x3
ffffffffc0202fc6:	62650513          	addi	a0,a0,1574 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202fca:	c7cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fce:	00004697          	auipc	a3,0x4
ffffffffc0202fd2:	aca68693          	addi	a3,a3,-1334 # ffffffffc0206a98 <etext+0x1308>
ffffffffc0202fd6:	00003617          	auipc	a2,0x3
ffffffffc0202fda:	17260613          	addi	a2,a2,370 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202fde:	25000593          	li	a1,592
ffffffffc0202fe2:	00003517          	auipc	a0,0x3
ffffffffc0202fe6:	60650513          	addi	a0,a0,1542 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0202fea:	c5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fee:	00004697          	auipc	a3,0x4
ffffffffc0202ff2:	a0a68693          	addi	a3,a3,-1526 # ffffffffc02069f8 <etext+0x1268>
ffffffffc0202ff6:	00003617          	auipc	a2,0x3
ffffffffc0202ffa:	15260613          	addi	a2,a2,338 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0202ffe:	23d00593          	li	a1,573
ffffffffc0203002:	00003517          	auipc	a0,0x3
ffffffffc0203006:	5e650513          	addi	a0,a0,1510 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020300a:	c3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020300e:	00004697          	auipc	a3,0x4
ffffffffc0203012:	ae268693          	addi	a3,a3,-1310 # ffffffffc0206af0 <etext+0x1360>
ffffffffc0203016:	00003617          	auipc	a2,0x3
ffffffffc020301a:	13260613          	addi	a2,a2,306 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020301e:	25500593          	li	a1,597
ffffffffc0203022:	00003517          	auipc	a0,0x3
ffffffffc0203026:	5c650513          	addi	a0,a0,1478 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020302a:	c1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020302e:	00004697          	auipc	a3,0x4
ffffffffc0203032:	a8268693          	addi	a3,a3,-1406 # ffffffffc0206ab0 <etext+0x1320>
ffffffffc0203036:	00003617          	auipc	a2,0x3
ffffffffc020303a:	11260613          	addi	a2,a2,274 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020303e:	25400593          	li	a1,596
ffffffffc0203042:	00003517          	auipc	a0,0x3
ffffffffc0203046:	5a650513          	addi	a0,a0,1446 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020304a:	bfcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020304e:	00004697          	auipc	a3,0x4
ffffffffc0203052:	93268693          	addi	a3,a3,-1742 # ffffffffc0206980 <etext+0x11f0>
ffffffffc0203056:	00003617          	auipc	a2,0x3
ffffffffc020305a:	0f260613          	addi	a2,a2,242 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020305e:	22f00593          	li	a1,559
ffffffffc0203062:	00003517          	auipc	a0,0x3
ffffffffc0203066:	58650513          	addi	a0,a0,1414 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020306a:	bdcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020306e:	00003697          	auipc	a3,0x3
ffffffffc0203072:	7b268693          	addi	a3,a3,1970 # ffffffffc0206820 <etext+0x1090>
ffffffffc0203076:	00003617          	auipc	a2,0x3
ffffffffc020307a:	0d260613          	addi	a2,a2,210 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020307e:	22e00593          	li	a1,558
ffffffffc0203082:	00003517          	auipc	a0,0x3
ffffffffc0203086:	56650513          	addi	a0,a0,1382 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020308a:	bbcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020308e:	00004697          	auipc	a3,0x4
ffffffffc0203092:	90a68693          	addi	a3,a3,-1782 # ffffffffc0206998 <etext+0x1208>
ffffffffc0203096:	00003617          	auipc	a2,0x3
ffffffffc020309a:	0b260613          	addi	a2,a2,178 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020309e:	22b00593          	li	a1,555
ffffffffc02030a2:	00003517          	auipc	a0,0x3
ffffffffc02030a6:	54650513          	addi	a0,a0,1350 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02030aa:	b9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030ae:	00003697          	auipc	a3,0x3
ffffffffc02030b2:	75a68693          	addi	a3,a3,1882 # ffffffffc0206808 <etext+0x1078>
ffffffffc02030b6:	00003617          	auipc	a2,0x3
ffffffffc02030ba:	09260613          	addi	a2,a2,146 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02030be:	22a00593          	li	a1,554
ffffffffc02030c2:	00003517          	auipc	a0,0x3
ffffffffc02030c6:	52650513          	addi	a0,a0,1318 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02030ca:	b7cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030ce:	00003697          	auipc	a3,0x3
ffffffffc02030d2:	7da68693          	addi	a3,a3,2010 # ffffffffc02068a8 <etext+0x1118>
ffffffffc02030d6:	00003617          	auipc	a2,0x3
ffffffffc02030da:	07260613          	addi	a2,a2,114 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02030de:	22900593          	li	a1,553
ffffffffc02030e2:	00003517          	auipc	a0,0x3
ffffffffc02030e6:	50650513          	addi	a0,a0,1286 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02030ea:	b5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030ee:	00004697          	auipc	a3,0x4
ffffffffc02030f2:	89268693          	addi	a3,a3,-1902 # ffffffffc0206980 <etext+0x11f0>
ffffffffc02030f6:	00003617          	auipc	a2,0x3
ffffffffc02030fa:	05260613          	addi	a2,a2,82 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02030fe:	22800593          	li	a1,552
ffffffffc0203102:	00003517          	auipc	a0,0x3
ffffffffc0203106:	4e650513          	addi	a0,a0,1254 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020310a:	b3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020310e:	00004697          	auipc	a3,0x4
ffffffffc0203112:	85a68693          	addi	a3,a3,-1958 # ffffffffc0206968 <etext+0x11d8>
ffffffffc0203116:	00003617          	auipc	a2,0x3
ffffffffc020311a:	03260613          	addi	a2,a2,50 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020311e:	22700593          	li	a1,551
ffffffffc0203122:	00003517          	auipc	a0,0x3
ffffffffc0203126:	4c650513          	addi	a0,a0,1222 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020312a:	b1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020312e:	00004697          	auipc	a3,0x4
ffffffffc0203132:	80a68693          	addi	a3,a3,-2038 # ffffffffc0206938 <etext+0x11a8>
ffffffffc0203136:	00003617          	auipc	a2,0x3
ffffffffc020313a:	01260613          	addi	a2,a2,18 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020313e:	22600593          	li	a1,550
ffffffffc0203142:	00003517          	auipc	a0,0x3
ffffffffc0203146:	4a650513          	addi	a0,a0,1190 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020314a:	afcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020314e:	00003697          	auipc	a3,0x3
ffffffffc0203152:	7d268693          	addi	a3,a3,2002 # ffffffffc0206920 <etext+0x1190>
ffffffffc0203156:	00003617          	auipc	a2,0x3
ffffffffc020315a:	ff260613          	addi	a2,a2,-14 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020315e:	22400593          	li	a1,548
ffffffffc0203162:	00003517          	auipc	a0,0x3
ffffffffc0203166:	48650513          	addi	a0,a0,1158 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020316a:	adcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020316e:	00003697          	auipc	a3,0x3
ffffffffc0203172:	79268693          	addi	a3,a3,1938 # ffffffffc0206900 <etext+0x1170>
ffffffffc0203176:	00003617          	auipc	a2,0x3
ffffffffc020317a:	fd260613          	addi	a2,a2,-46 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020317e:	22300593          	li	a1,547
ffffffffc0203182:	00003517          	auipc	a0,0x3
ffffffffc0203186:	46650513          	addi	a0,a0,1126 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020318a:	abcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020318e:	00003697          	auipc	a3,0x3
ffffffffc0203192:	76268693          	addi	a3,a3,1890 # ffffffffc02068f0 <etext+0x1160>
ffffffffc0203196:	00003617          	auipc	a2,0x3
ffffffffc020319a:	fb260613          	addi	a2,a2,-78 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020319e:	22200593          	li	a1,546
ffffffffc02031a2:	00003517          	auipc	a0,0x3
ffffffffc02031a6:	44650513          	addi	a0,a0,1094 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02031aa:	a9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031ae:	00003697          	auipc	a3,0x3
ffffffffc02031b2:	73268693          	addi	a3,a3,1842 # ffffffffc02068e0 <etext+0x1150>
ffffffffc02031b6:	00003617          	auipc	a2,0x3
ffffffffc02031ba:	f9260613          	addi	a2,a2,-110 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02031be:	22100593          	li	a1,545
ffffffffc02031c2:	00003517          	auipc	a0,0x3
ffffffffc02031c6:	42650513          	addi	a0,a0,1062 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02031ca:	a7cfd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02031ce:	00003617          	auipc	a2,0x3
ffffffffc02031d2:	3d260613          	addi	a2,a2,978 # ffffffffc02065a0 <etext+0xe10>
ffffffffc02031d6:	08100593          	li	a1,129
ffffffffc02031da:	00003517          	auipc	a0,0x3
ffffffffc02031de:	40e50513          	addi	a0,a0,1038 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02031e2:	a64fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02031e6:	00003697          	auipc	a3,0x3
ffffffffc02031ea:	65268693          	addi	a3,a3,1618 # ffffffffc0206838 <etext+0x10a8>
ffffffffc02031ee:	00003617          	auipc	a2,0x3
ffffffffc02031f2:	f5a60613          	addi	a2,a2,-166 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02031f6:	21c00593          	li	a1,540
ffffffffc02031fa:	00003517          	auipc	a0,0x3
ffffffffc02031fe:	3ee50513          	addi	a0,a0,1006 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203202:	a44fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203206:	00003697          	auipc	a3,0x3
ffffffffc020320a:	6a268693          	addi	a3,a3,1698 # ffffffffc02068a8 <etext+0x1118>
ffffffffc020320e:	00003617          	auipc	a2,0x3
ffffffffc0203212:	f3a60613          	addi	a2,a2,-198 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203216:	22000593          	li	a1,544
ffffffffc020321a:	00003517          	auipc	a0,0x3
ffffffffc020321e:	3ce50513          	addi	a0,a0,974 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203222:	a24fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203226:	00003697          	auipc	a3,0x3
ffffffffc020322a:	64268693          	addi	a3,a3,1602 # ffffffffc0206868 <etext+0x10d8>
ffffffffc020322e:	00003617          	auipc	a2,0x3
ffffffffc0203232:	f1a60613          	addi	a2,a2,-230 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203236:	21f00593          	li	a1,543
ffffffffc020323a:	00003517          	auipc	a0,0x3
ffffffffc020323e:	3ae50513          	addi	a0,a0,942 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203242:	a04fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203246:	86d6                	mv	a3,s5
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	2b060613          	addi	a2,a2,688 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0203250:	21b00593          	li	a1,539
ffffffffc0203254:	00003517          	auipc	a0,0x3
ffffffffc0203258:	39450513          	addi	a0,a0,916 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020325c:	9eafd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203260:	00003617          	auipc	a2,0x3
ffffffffc0203264:	29860613          	addi	a2,a2,664 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0203268:	21a00593          	li	a1,538
ffffffffc020326c:	00003517          	auipc	a0,0x3
ffffffffc0203270:	37c50513          	addi	a0,a0,892 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203274:	9d2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203278:	00003697          	auipc	a3,0x3
ffffffffc020327c:	5a868693          	addi	a3,a3,1448 # ffffffffc0206820 <etext+0x1090>
ffffffffc0203280:	00003617          	auipc	a2,0x3
ffffffffc0203284:	ec860613          	addi	a2,a2,-312 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203288:	21800593          	li	a1,536
ffffffffc020328c:	00003517          	auipc	a0,0x3
ffffffffc0203290:	35c50513          	addi	a0,a0,860 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203294:	9b2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203298:	00003697          	auipc	a3,0x3
ffffffffc020329c:	57068693          	addi	a3,a3,1392 # ffffffffc0206808 <etext+0x1078>
ffffffffc02032a0:	00003617          	auipc	a2,0x3
ffffffffc02032a4:	ea860613          	addi	a2,a2,-344 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02032a8:	21700593          	li	a1,535
ffffffffc02032ac:	00003517          	auipc	a0,0x3
ffffffffc02032b0:	33c50513          	addi	a0,a0,828 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02032b4:	992fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032b8:	00004697          	auipc	a3,0x4
ffffffffc02032bc:	90068693          	addi	a3,a3,-1792 # ffffffffc0206bb8 <etext+0x1428>
ffffffffc02032c0:	00003617          	auipc	a2,0x3
ffffffffc02032c4:	e8860613          	addi	a2,a2,-376 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02032c8:	25e00593          	li	a1,606
ffffffffc02032cc:	00003517          	auipc	a0,0x3
ffffffffc02032d0:	31c50513          	addi	a0,a0,796 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02032d4:	972fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032d8:	00004697          	auipc	a3,0x4
ffffffffc02032dc:	8a868693          	addi	a3,a3,-1880 # ffffffffc0206b80 <etext+0x13f0>
ffffffffc02032e0:	00003617          	auipc	a2,0x3
ffffffffc02032e4:	e6860613          	addi	a2,a2,-408 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02032e8:	25b00593          	li	a1,603
ffffffffc02032ec:	00003517          	auipc	a0,0x3
ffffffffc02032f0:	2fc50513          	addi	a0,a0,764 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02032f4:	952fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032f8:	00004697          	auipc	a3,0x4
ffffffffc02032fc:	85868693          	addi	a3,a3,-1960 # ffffffffc0206b50 <etext+0x13c0>
ffffffffc0203300:	00003617          	auipc	a2,0x3
ffffffffc0203304:	e4860613          	addi	a2,a2,-440 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203308:	25700593          	li	a1,599
ffffffffc020330c:	00003517          	auipc	a0,0x3
ffffffffc0203310:	2dc50513          	addi	a0,a0,732 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203314:	932fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203318:	00003697          	auipc	a3,0x3
ffffffffc020331c:	7f068693          	addi	a3,a3,2032 # ffffffffc0206b08 <etext+0x1378>
ffffffffc0203320:	00003617          	auipc	a2,0x3
ffffffffc0203324:	e2860613          	addi	a2,a2,-472 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203328:	25600593          	li	a1,598
ffffffffc020332c:	00003517          	auipc	a0,0x3
ffffffffc0203330:	2bc50513          	addi	a0,a0,700 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203334:	912fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0203338:	00003697          	auipc	a3,0x3
ffffffffc020333c:	41868693          	addi	a3,a3,1048 # ffffffffc0206750 <etext+0xfc0>
ffffffffc0203340:	00003617          	auipc	a2,0x3
ffffffffc0203344:	e0860613          	addi	a2,a2,-504 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203348:	20f00593          	li	a1,527
ffffffffc020334c:	00003517          	auipc	a0,0x3
ffffffffc0203350:	29c50513          	addi	a0,a0,668 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203354:	8f2fd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203358:	00003617          	auipc	a2,0x3
ffffffffc020335c:	24860613          	addi	a2,a2,584 # ffffffffc02065a0 <etext+0xe10>
ffffffffc0203360:	0c900593          	li	a1,201
ffffffffc0203364:	00003517          	auipc	a0,0x3
ffffffffc0203368:	28450513          	addi	a0,a0,644 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020336c:	8dafd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203370:	00003697          	auipc	a3,0x3
ffffffffc0203374:	44068693          	addi	a3,a3,1088 # ffffffffc02067b0 <etext+0x1020>
ffffffffc0203378:	00003617          	auipc	a2,0x3
ffffffffc020337c:	dd060613          	addi	a2,a2,-560 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203380:	21600593          	li	a1,534
ffffffffc0203384:	00003517          	auipc	a0,0x3
ffffffffc0203388:	26450513          	addi	a0,a0,612 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020338c:	8bafd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203390:	00003697          	auipc	a3,0x3
ffffffffc0203394:	3f068693          	addi	a3,a3,1008 # ffffffffc0206780 <etext+0xff0>
ffffffffc0203398:	00003617          	auipc	a2,0x3
ffffffffc020339c:	db060613          	addi	a2,a2,-592 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02033a0:	21300593          	li	a1,531
ffffffffc02033a4:	00003517          	auipc	a0,0x3
ffffffffc02033a8:	24450513          	addi	a0,a0,580 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02033ac:	89afd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02033b0 <copy_range>:
{
ffffffffc02033b0:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033b2:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033b6:	f486                	sd	ra,104(sp)
ffffffffc02033b8:	f0a2                	sd	s0,96(sp)
ffffffffc02033ba:	eca6                	sd	s1,88(sp)
ffffffffc02033bc:	e8ca                	sd	s2,80(sp)
ffffffffc02033be:	e4ce                	sd	s3,72(sp)
ffffffffc02033c0:	e0d2                	sd	s4,64(sp)
ffffffffc02033c2:	fc56                	sd	s5,56(sp)
ffffffffc02033c4:	f85a                	sd	s6,48(sp)
ffffffffc02033c6:	f45e                	sd	s7,40(sp)
ffffffffc02033c8:	f062                	sd	s8,32(sp)
ffffffffc02033ca:	ec66                	sd	s9,24(sp)
ffffffffc02033cc:	e86a                	sd	s10,16(sp)
ffffffffc02033ce:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033d0:	03479713          	slli	a4,a5,0x34
ffffffffc02033d4:	20071f63          	bnez	a4,ffffffffc02035f2 <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc02033d8:	002007b7          	lui	a5,0x200
ffffffffc02033dc:	00d63733          	sltu	a4,a2,a3
ffffffffc02033e0:	00f637b3          	sltu	a5,a2,a5
ffffffffc02033e4:	00173713          	seqz	a4,a4
ffffffffc02033e8:	8fd9                	or	a5,a5,a4
ffffffffc02033ea:	8432                	mv	s0,a2
ffffffffc02033ec:	8936                	mv	s2,a3
ffffffffc02033ee:	1e079263          	bnez	a5,ffffffffc02035d2 <copy_range+0x222>
ffffffffc02033f2:	4785                	li	a5,1
ffffffffc02033f4:	07fe                	slli	a5,a5,0x1f
ffffffffc02033f6:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e29>
ffffffffc02033f8:	1cf6fd63          	bgeu	a3,a5,ffffffffc02035d2 <copy_range+0x222>
ffffffffc02033fc:	5b7d                	li	s6,-1
ffffffffc02033fe:	8baa                	mv	s7,a0
ffffffffc0203400:	8a2e                	mv	s4,a1
ffffffffc0203402:	6a85                	lui	s5,0x1
ffffffffc0203404:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc0203408:	00098c97          	auipc	s9,0x98
ffffffffc020340c:	398c8c93          	addi	s9,s9,920 # ffffffffc029b7a0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203410:	00098c17          	auipc	s8,0x98
ffffffffc0203414:	398c0c13          	addi	s8,s8,920 # ffffffffc029b7a8 <pages>
ffffffffc0203418:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020341c:	4601                	li	a2,0
ffffffffc020341e:	85a2                	mv	a1,s0
ffffffffc0203420:	8552                	mv	a0,s4
ffffffffc0203422:	b19fe0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0203426:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203428:	0e050a63          	beqz	a0,ffffffffc020351c <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc020342c:	611c                	ld	a5,0(a0)
ffffffffc020342e:	8b85                	andi	a5,a5,1
ffffffffc0203430:	e78d                	bnez	a5,ffffffffc020345a <copy_range+0xaa>
        start += PGSIZE;
ffffffffc0203432:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0203434:	c019                	beqz	s0,ffffffffc020343a <copy_range+0x8a>
ffffffffc0203436:	ff2463e3          	bltu	s0,s2,ffffffffc020341c <copy_range+0x6c>
    return 0;
ffffffffc020343a:	4501                	li	a0,0
}
ffffffffc020343c:	70a6                	ld	ra,104(sp)
ffffffffc020343e:	7406                	ld	s0,96(sp)
ffffffffc0203440:	64e6                	ld	s1,88(sp)
ffffffffc0203442:	6946                	ld	s2,80(sp)
ffffffffc0203444:	69a6                	ld	s3,72(sp)
ffffffffc0203446:	6a06                	ld	s4,64(sp)
ffffffffc0203448:	7ae2                	ld	s5,56(sp)
ffffffffc020344a:	7b42                	ld	s6,48(sp)
ffffffffc020344c:	7ba2                	ld	s7,40(sp)
ffffffffc020344e:	7c02                	ld	s8,32(sp)
ffffffffc0203450:	6ce2                	ld	s9,24(sp)
ffffffffc0203452:	6d42                	ld	s10,16(sp)
ffffffffc0203454:	6da2                	ld	s11,8(sp)
ffffffffc0203456:	6165                	addi	sp,sp,112
ffffffffc0203458:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc020345a:	4605                	li	a2,1
ffffffffc020345c:	85a2                	mv	a1,s0
ffffffffc020345e:	855e                	mv	a0,s7
ffffffffc0203460:	adbfe0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0203464:	c165                	beqz	a0,ffffffffc0203544 <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203466:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc020346a:	0019f793          	andi	a5,s3,1
ffffffffc020346e:	14078663          	beqz	a5,ffffffffc02035ba <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc0203472:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203476:	00299793          	slli	a5,s3,0x2
ffffffffc020347a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020347c:	12e7f363          	bgeu	a5,a4,ffffffffc02035a2 <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc0203480:	000c3483          	ld	s1,0(s8)
ffffffffc0203484:	97ea                	add	a5,a5,s10
ffffffffc0203486:	079a                	slli	a5,a5,0x6
ffffffffc0203488:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020348a:	100027f3          	csrr	a5,sstatus
ffffffffc020348e:	8b89                	andi	a5,a5,2
ffffffffc0203490:	efc9                	bnez	a5,ffffffffc020352a <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203492:	00098797          	auipc	a5,0x98
ffffffffc0203496:	2ee7b783          	ld	a5,750(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc020349a:	4505                	li	a0,1
ffffffffc020349c:	6f9c                	ld	a5,24(a5)
ffffffffc020349e:	9782                	jalr	a5
ffffffffc02034a0:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc02034a2:	c0e5                	beqz	s1,ffffffffc0203582 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc02034a4:	0a0d8f63          	beqz	s11,ffffffffc0203562 <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc02034a8:	000c3783          	ld	a5,0(s8)
ffffffffc02034ac:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc02034b0:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc02034b4:	40f486b3          	sub	a3,s1,a5
ffffffffc02034b8:	8699                	srai	a3,a3,0x6
ffffffffc02034ba:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02034bc:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034c0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034c2:	08e5f463          	bgeu	a1,a4,ffffffffc020354a <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc02034c6:	40fd87b3          	sub	a5,s11,a5
ffffffffc02034ca:	8799                	srai	a5,a5,0x6
ffffffffc02034cc:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc02034ce:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034d2:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034d4:	06e67a63          	bgeu	a2,a4,ffffffffc0203548 <copy_range+0x198>
ffffffffc02034d8:	00098517          	auipc	a0,0x98
ffffffffc02034dc:	2c053503          	ld	a0,704(a0) # ffffffffc029b798 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034e0:	6605                	lui	a2,0x1
ffffffffc02034e2:	00a685b3          	add	a1,a3,a0
ffffffffc02034e6:	953e                	add	a0,a0,a5
ffffffffc02034e8:	290020ef          	jal	ffffffffc0205778 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034ec:	01f9f693          	andi	a3,s3,31
ffffffffc02034f0:	85ee                	mv	a1,s11
ffffffffc02034f2:	8622                	mv	a2,s0
ffffffffc02034f4:	855e                	mv	a0,s7
ffffffffc02034f6:	97aff0ef          	jal	ffffffffc0202670 <page_insert>
            assert(ret == 0);
ffffffffc02034fa:	dd05                	beqz	a0,ffffffffc0203432 <copy_range+0x82>
ffffffffc02034fc:	00003697          	auipc	a3,0x3
ffffffffc0203500:	72468693          	addi	a3,a3,1828 # ffffffffc0206c20 <etext+0x1490>
ffffffffc0203504:	00003617          	auipc	a2,0x3
ffffffffc0203508:	c4460613          	addi	a2,a2,-956 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020350c:	1ab00593          	li	a1,427
ffffffffc0203510:	00003517          	auipc	a0,0x3
ffffffffc0203514:	0d850513          	addi	a0,a0,216 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203518:	f2ffc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020351c:	002007b7          	lui	a5,0x200
ffffffffc0203520:	97a2                	add	a5,a5,s0
ffffffffc0203522:	ffe00437          	lui	s0,0xffe00
ffffffffc0203526:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc0203528:	b731                	j	ffffffffc0203434 <copy_range+0x84>
        intr_disable();
ffffffffc020352a:	bdafd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020352e:	00098797          	auipc	a5,0x98
ffffffffc0203532:	2527b783          	ld	a5,594(a5) # ffffffffc029b780 <pmm_manager>
ffffffffc0203536:	4505                	li	a0,1
ffffffffc0203538:	6f9c                	ld	a5,24(a5)
ffffffffc020353a:	9782                	jalr	a5
ffffffffc020353c:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc020353e:	bc0fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0203542:	b785                	j	ffffffffc02034a2 <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc0203544:	5571                	li	a0,-4
ffffffffc0203546:	bddd                	j	ffffffffc020343c <copy_range+0x8c>
ffffffffc0203548:	86be                	mv	a3,a5
ffffffffc020354a:	00003617          	auipc	a2,0x3
ffffffffc020354e:	fae60613          	addi	a2,a2,-82 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0203552:	07100593          	li	a1,113
ffffffffc0203556:	00003517          	auipc	a0,0x3
ffffffffc020355a:	fca50513          	addi	a0,a0,-54 # ffffffffc0206520 <etext+0xd90>
ffffffffc020355e:	ee9fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(npage != NULL);
ffffffffc0203562:	00003697          	auipc	a3,0x3
ffffffffc0203566:	6ae68693          	addi	a3,a3,1710 # ffffffffc0206c10 <etext+0x1480>
ffffffffc020356a:	00003617          	auipc	a2,0x3
ffffffffc020356e:	bde60613          	addi	a2,a2,-1058 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203572:	19e00593          	li	a1,414
ffffffffc0203576:	00003517          	auipc	a0,0x3
ffffffffc020357a:	07250513          	addi	a0,a0,114 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020357e:	ec9fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(page != NULL);
ffffffffc0203582:	00003697          	auipc	a3,0x3
ffffffffc0203586:	67e68693          	addi	a3,a3,1662 # ffffffffc0206c00 <etext+0x1470>
ffffffffc020358a:	00003617          	auipc	a2,0x3
ffffffffc020358e:	bbe60613          	addi	a2,a2,-1090 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203592:	19d00593          	li	a1,413
ffffffffc0203596:	00003517          	auipc	a0,0x3
ffffffffc020359a:	05250513          	addi	a0,a0,82 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020359e:	ea9fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02035a2:	00003617          	auipc	a2,0x3
ffffffffc02035a6:	02660613          	addi	a2,a2,38 # ffffffffc02065c8 <etext+0xe38>
ffffffffc02035aa:	06900593          	li	a1,105
ffffffffc02035ae:	00003517          	auipc	a0,0x3
ffffffffc02035b2:	f7250513          	addi	a0,a0,-142 # ffffffffc0206520 <etext+0xd90>
ffffffffc02035b6:	e91fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035ba:	00003617          	auipc	a2,0x3
ffffffffc02035be:	22660613          	addi	a2,a2,550 # ffffffffc02067e0 <etext+0x1050>
ffffffffc02035c2:	07f00593          	li	a1,127
ffffffffc02035c6:	00003517          	auipc	a0,0x3
ffffffffc02035ca:	f5a50513          	addi	a0,a0,-166 # ffffffffc0206520 <etext+0xd90>
ffffffffc02035ce:	e79fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02035d2:	00003697          	auipc	a3,0x3
ffffffffc02035d6:	05668693          	addi	a3,a3,86 # ffffffffc0206628 <etext+0xe98>
ffffffffc02035da:	00003617          	auipc	a2,0x3
ffffffffc02035de:	b6e60613          	addi	a2,a2,-1170 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02035e2:	18500593          	li	a1,389
ffffffffc02035e6:	00003517          	auipc	a0,0x3
ffffffffc02035ea:	00250513          	addi	a0,a0,2 # ffffffffc02065e8 <etext+0xe58>
ffffffffc02035ee:	e59fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035f2:	00003697          	auipc	a3,0x3
ffffffffc02035f6:	00668693          	addi	a3,a3,6 # ffffffffc02065f8 <etext+0xe68>
ffffffffc02035fa:	00003617          	auipc	a2,0x3
ffffffffc02035fe:	b4e60613          	addi	a2,a2,-1202 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203602:	18400593          	li	a1,388
ffffffffc0203606:	00003517          	auipc	a0,0x3
ffffffffc020360a:	fe250513          	addi	a0,a0,-30 # ffffffffc02065e8 <etext+0xe58>
ffffffffc020360e:	e39fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203612 <pgdir_alloc_page>:
{
ffffffffc0203612:	7139                	addi	sp,sp,-64
ffffffffc0203614:	f426                	sd	s1,40(sp)
ffffffffc0203616:	f04a                	sd	s2,32(sp)
ffffffffc0203618:	ec4e                	sd	s3,24(sp)
ffffffffc020361a:	fc06                	sd	ra,56(sp)
ffffffffc020361c:	f822                	sd	s0,48(sp)
ffffffffc020361e:	892a                	mv	s2,a0
ffffffffc0203620:	84ae                	mv	s1,a1
ffffffffc0203622:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203624:	100027f3          	csrr	a5,sstatus
ffffffffc0203628:	8b89                	andi	a5,a5,2
ffffffffc020362a:	ebb5                	bnez	a5,ffffffffc020369e <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc020362c:	00098417          	auipc	s0,0x98
ffffffffc0203630:	15440413          	addi	s0,s0,340 # ffffffffc029b780 <pmm_manager>
ffffffffc0203634:	601c                	ld	a5,0(s0)
ffffffffc0203636:	4505                	li	a0,1
ffffffffc0203638:	6f9c                	ld	a5,24(a5)
ffffffffc020363a:	9782                	jalr	a5
ffffffffc020363c:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc020363e:	c5b9                	beqz	a1,ffffffffc020368c <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203640:	86ce                	mv	a3,s3
ffffffffc0203642:	854a                	mv	a0,s2
ffffffffc0203644:	8626                	mv	a2,s1
ffffffffc0203646:	e42e                	sd	a1,8(sp)
ffffffffc0203648:	828ff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc020364c:	65a2                	ld	a1,8(sp)
ffffffffc020364e:	e515                	bnez	a0,ffffffffc020367a <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc0203650:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc0203652:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc0203654:	4785                	li	a5,1
ffffffffc0203656:	02f70c63          	beq	a4,a5,ffffffffc020368e <pgdir_alloc_page+0x7c>
ffffffffc020365a:	00003697          	auipc	a3,0x3
ffffffffc020365e:	5d668693          	addi	a3,a3,1494 # ffffffffc0206c30 <etext+0x14a0>
ffffffffc0203662:	00003617          	auipc	a2,0x3
ffffffffc0203666:	ae660613          	addi	a2,a2,-1306 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020366a:	1f400593          	li	a1,500
ffffffffc020366e:	00003517          	auipc	a0,0x3
ffffffffc0203672:	f7a50513          	addi	a0,a0,-134 # ffffffffc02065e8 <etext+0xe58>
ffffffffc0203676:	dd1fc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020367a:	100027f3          	csrr	a5,sstatus
ffffffffc020367e:	8b89                	andi	a5,a5,2
ffffffffc0203680:	ef95                	bnez	a5,ffffffffc02036bc <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc0203682:	601c                	ld	a5,0(s0)
ffffffffc0203684:	852e                	mv	a0,a1
ffffffffc0203686:	4585                	li	a1,1
ffffffffc0203688:	739c                	ld	a5,32(a5)
ffffffffc020368a:	9782                	jalr	a5
            return NULL;
ffffffffc020368c:	4581                	li	a1,0
}
ffffffffc020368e:	70e2                	ld	ra,56(sp)
ffffffffc0203690:	7442                	ld	s0,48(sp)
ffffffffc0203692:	74a2                	ld	s1,40(sp)
ffffffffc0203694:	7902                	ld	s2,32(sp)
ffffffffc0203696:	69e2                	ld	s3,24(sp)
ffffffffc0203698:	852e                	mv	a0,a1
ffffffffc020369a:	6121                	addi	sp,sp,64
ffffffffc020369c:	8082                	ret
        intr_disable();
ffffffffc020369e:	a66fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036a2:	00098417          	auipc	s0,0x98
ffffffffc02036a6:	0de40413          	addi	s0,s0,222 # ffffffffc029b780 <pmm_manager>
ffffffffc02036aa:	601c                	ld	a5,0(s0)
ffffffffc02036ac:	4505                	li	a0,1
ffffffffc02036ae:	6f9c                	ld	a5,24(a5)
ffffffffc02036b0:	9782                	jalr	a5
ffffffffc02036b2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02036b4:	a4afd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036b8:	65a2                	ld	a1,8(sp)
ffffffffc02036ba:	b751                	j	ffffffffc020363e <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc02036bc:	a48fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02036c0:	601c                	ld	a5,0(s0)
ffffffffc02036c2:	6522                	ld	a0,8(sp)
ffffffffc02036c4:	4585                	li	a1,1
ffffffffc02036c6:	739c                	ld	a5,32(a5)
ffffffffc02036c8:	9782                	jalr	a5
        intr_enable();
ffffffffc02036ca:	a34fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036ce:	bf7d                	j	ffffffffc020368c <pgdir_alloc_page+0x7a>

ffffffffc02036d0 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036d0:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02036d2:	00003697          	auipc	a3,0x3
ffffffffc02036d6:	57668693          	addi	a3,a3,1398 # ffffffffc0206c48 <etext+0x14b8>
ffffffffc02036da:	00003617          	auipc	a2,0x3
ffffffffc02036de:	a6e60613          	addi	a2,a2,-1426 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02036e2:	07400593          	li	a1,116
ffffffffc02036e6:	00003517          	auipc	a0,0x3
ffffffffc02036ea:	58250513          	addi	a0,a0,1410 # ffffffffc0206c68 <etext+0x14d8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036ee:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036f0:	d57fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02036f4 <mm_create>:
{
ffffffffc02036f4:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036f6:	04000513          	li	a0,64
{
ffffffffc02036fa:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036fc:	dd4fe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (mm != NULL)
ffffffffc0203700:	cd19                	beqz	a0,ffffffffc020371e <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203702:	e508                	sd	a0,8(a0)
ffffffffc0203704:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203706:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020370a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020370e:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203712:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203716:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020371a:	02053c23          	sd	zero,56(a0)
}
ffffffffc020371e:	60a2                	ld	ra,8(sp)
ffffffffc0203720:	0141                	addi	sp,sp,16
ffffffffc0203722:	8082                	ret

ffffffffc0203724 <find_vma>:
    if (mm != NULL)
ffffffffc0203724:	c505                	beqz	a0,ffffffffc020374c <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0203726:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203728:	c781                	beqz	a5,ffffffffc0203730 <find_vma+0xc>
ffffffffc020372a:	6798                	ld	a4,8(a5)
ffffffffc020372c:	02e5f363          	bgeu	a1,a4,ffffffffc0203752 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203730:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0203732:	00f50d63          	beq	a0,a5,ffffffffc020374c <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203736:	fe87b703          	ld	a4,-24(a5)
ffffffffc020373a:	00e5e663          	bltu	a1,a4,ffffffffc0203746 <find_vma+0x22>
ffffffffc020373e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203742:	00e5ee63          	bltu	a1,a4,ffffffffc020375e <find_vma+0x3a>
ffffffffc0203746:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203748:	fef517e3          	bne	a0,a5,ffffffffc0203736 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc020374c:	4781                	li	a5,0
}
ffffffffc020374e:	853e                	mv	a0,a5
ffffffffc0203750:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203752:	6b98                	ld	a4,16(a5)
ffffffffc0203754:	fce5fee3          	bgeu	a1,a4,ffffffffc0203730 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0203758:	e91c                	sd	a5,16(a0)
}
ffffffffc020375a:	853e                	mv	a0,a5
ffffffffc020375c:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc020375e:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203760:	e91c                	sd	a5,16(a0)
ffffffffc0203762:	bfe5                	j	ffffffffc020375a <find_vma+0x36>

ffffffffc0203764 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203764:	6590                	ld	a2,8(a1)
ffffffffc0203766:	0105b803          	ld	a6,16(a1)
{
ffffffffc020376a:	1141                	addi	sp,sp,-16
ffffffffc020376c:	e406                	sd	ra,8(sp)
ffffffffc020376e:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203770:	01066763          	bltu	a2,a6,ffffffffc020377e <insert_vma_struct+0x1a>
ffffffffc0203774:	a8b9                	j	ffffffffc02037d2 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203776:	fe87b703          	ld	a4,-24(a5)
ffffffffc020377a:	04e66763          	bltu	a2,a4,ffffffffc02037c8 <insert_vma_struct+0x64>
ffffffffc020377e:	86be                	mv	a3,a5
ffffffffc0203780:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203782:	fef51ae3          	bne	a0,a5,ffffffffc0203776 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203786:	02a68463          	beq	a3,a0,ffffffffc02037ae <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020378a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020378e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203792:	08e8f063          	bgeu	a7,a4,ffffffffc0203812 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203796:	04e66e63          	bltu	a2,a4,ffffffffc02037f2 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc020379a:	00f50a63          	beq	a0,a5,ffffffffc02037ae <insert_vma_struct+0x4a>
ffffffffc020379e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037a2:	05076863          	bltu	a4,a6,ffffffffc02037f2 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02037a6:	ff07b603          	ld	a2,-16(a5)
ffffffffc02037aa:	02c77263          	bgeu	a4,a2,ffffffffc02037ce <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02037ae:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02037b0:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02037b2:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02037b6:	e390                	sd	a2,0(a5)
ffffffffc02037b8:	e690                	sd	a2,8(a3)
}
ffffffffc02037ba:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02037bc:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02037be:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02037c0:	2705                	addiw	a4,a4,1
ffffffffc02037c2:	d118                	sw	a4,32(a0)
}
ffffffffc02037c4:	0141                	addi	sp,sp,16
ffffffffc02037c6:	8082                	ret
    if (le_prev != list)
ffffffffc02037c8:	fca691e3          	bne	a3,a0,ffffffffc020378a <insert_vma_struct+0x26>
ffffffffc02037cc:	bfd9                	j	ffffffffc02037a2 <insert_vma_struct+0x3e>
ffffffffc02037ce:	f03ff0ef          	jal	ffffffffc02036d0 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037d2:	00003697          	auipc	a3,0x3
ffffffffc02037d6:	4a668693          	addi	a3,a3,1190 # ffffffffc0206c78 <etext+0x14e8>
ffffffffc02037da:	00003617          	auipc	a2,0x3
ffffffffc02037de:	96e60613          	addi	a2,a2,-1682 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02037e2:	07a00593          	li	a1,122
ffffffffc02037e6:	00003517          	auipc	a0,0x3
ffffffffc02037ea:	48250513          	addi	a0,a0,1154 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc02037ee:	c59fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037f2:	00003697          	auipc	a3,0x3
ffffffffc02037f6:	4c668693          	addi	a3,a3,1222 # ffffffffc0206cb8 <etext+0x1528>
ffffffffc02037fa:	00003617          	auipc	a2,0x3
ffffffffc02037fe:	94e60613          	addi	a2,a2,-1714 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203802:	07300593          	li	a1,115
ffffffffc0203806:	00003517          	auipc	a0,0x3
ffffffffc020380a:	46250513          	addi	a0,a0,1122 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc020380e:	c39fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203812:	00003697          	auipc	a3,0x3
ffffffffc0203816:	48668693          	addi	a3,a3,1158 # ffffffffc0206c98 <etext+0x1508>
ffffffffc020381a:	00003617          	auipc	a2,0x3
ffffffffc020381e:	92e60613          	addi	a2,a2,-1746 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203822:	07200593          	li	a1,114
ffffffffc0203826:	00003517          	auipc	a0,0x3
ffffffffc020382a:	44250513          	addi	a0,a0,1090 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc020382e:	c19fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203832 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203832:	591c                	lw	a5,48(a0)
{
ffffffffc0203834:	1141                	addi	sp,sp,-16
ffffffffc0203836:	e406                	sd	ra,8(sp)
ffffffffc0203838:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020383a:	e78d                	bnez	a5,ffffffffc0203864 <mm_destroy+0x32>
ffffffffc020383c:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020383e:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203840:	00a40c63          	beq	s0,a0,ffffffffc0203858 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203844:	6118                	ld	a4,0(a0)
ffffffffc0203846:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203848:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020384a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020384c:	e398                	sd	a4,0(a5)
ffffffffc020384e:	d28fe0ef          	jal	ffffffffc0201d76 <kfree>
    return listelm->next;
ffffffffc0203852:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203854:	fea418e3          	bne	s0,a0,ffffffffc0203844 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203858:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020385a:	6402                	ld	s0,0(sp)
ffffffffc020385c:	60a2                	ld	ra,8(sp)
ffffffffc020385e:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203860:	d16fe06f          	j	ffffffffc0201d76 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203864:	00003697          	auipc	a3,0x3
ffffffffc0203868:	47468693          	addi	a3,a3,1140 # ffffffffc0206cd8 <etext+0x1548>
ffffffffc020386c:	00003617          	auipc	a2,0x3
ffffffffc0203870:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203874:	09e00593          	li	a1,158
ffffffffc0203878:	00003517          	auipc	a0,0x3
ffffffffc020387c:	3f050513          	addi	a0,a0,1008 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203880:	bc7fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203884 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203884:	6785                	lui	a5,0x1
ffffffffc0203886:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7bd1>
ffffffffc0203888:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc020388a:	4785                	li	a5,1
{
ffffffffc020388c:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020388e:	962e                	add	a2,a2,a1
ffffffffc0203890:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc0203892:	07fe                	slli	a5,a5,0x1f
{
ffffffffc0203894:	f822                	sd	s0,48(sp)
ffffffffc0203896:	f426                	sd	s1,40(sp)
ffffffffc0203898:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020389c:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02038a0:	0785                	addi	a5,a5,1
ffffffffc02038a2:	0084b633          	sltu	a2,s1,s0
ffffffffc02038a6:	00f437b3          	sltu	a5,s0,a5
ffffffffc02038aa:	00163613          	seqz	a2,a2
ffffffffc02038ae:	0017b793          	seqz	a5,a5
{
ffffffffc02038b2:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02038b4:	8fd1                	or	a5,a5,a2
ffffffffc02038b6:	ebbd                	bnez	a5,ffffffffc020392c <mm_map+0xa8>
ffffffffc02038b8:	002007b7          	lui	a5,0x200
ffffffffc02038bc:	06f4e863          	bltu	s1,a5,ffffffffc020392c <mm_map+0xa8>
ffffffffc02038c0:	f04a                	sd	s2,32(sp)
ffffffffc02038c2:	ec4e                	sd	s3,24(sp)
ffffffffc02038c4:	e852                	sd	s4,16(sp)
ffffffffc02038c6:	892a                	mv	s2,a0
ffffffffc02038c8:	89ba                	mv	s3,a4
ffffffffc02038ca:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02038cc:	c135                	beqz	a0,ffffffffc0203930 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02038ce:	85a6                	mv	a1,s1
ffffffffc02038d0:	e55ff0ef          	jal	ffffffffc0203724 <find_vma>
ffffffffc02038d4:	c501                	beqz	a0,ffffffffc02038dc <mm_map+0x58>
ffffffffc02038d6:	651c                	ld	a5,8(a0)
ffffffffc02038d8:	0487e763          	bltu	a5,s0,ffffffffc0203926 <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038dc:	03000513          	li	a0,48
ffffffffc02038e0:	bf0fe0ef          	jal	ffffffffc0201cd0 <kmalloc>
ffffffffc02038e4:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02038e6:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02038e8:	c59d                	beqz	a1,ffffffffc0203916 <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc02038ea:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc02038ec:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02038ee:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02038f2:	854a                	mv	a0,s2
ffffffffc02038f4:	e42e                	sd	a1,8(sp)
ffffffffc02038f6:	e6fff0ef          	jal	ffffffffc0203764 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc02038fa:	65a2                	ld	a1,8(sp)
ffffffffc02038fc:	00098463          	beqz	s3,ffffffffc0203904 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203900:	00b9b023          	sd	a1,0(s3)
ffffffffc0203904:	7902                	ld	s2,32(sp)
ffffffffc0203906:	69e2                	ld	s3,24(sp)
ffffffffc0203908:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc020390a:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc020390c:	70e2                	ld	ra,56(sp)
ffffffffc020390e:	7442                	ld	s0,48(sp)
ffffffffc0203910:	74a2                	ld	s1,40(sp)
ffffffffc0203912:	6121                	addi	sp,sp,64
ffffffffc0203914:	8082                	ret
ffffffffc0203916:	70e2                	ld	ra,56(sp)
ffffffffc0203918:	7442                	ld	s0,48(sp)
ffffffffc020391a:	7902                	ld	s2,32(sp)
ffffffffc020391c:	69e2                	ld	s3,24(sp)
ffffffffc020391e:	6a42                	ld	s4,16(sp)
ffffffffc0203920:	74a2                	ld	s1,40(sp)
ffffffffc0203922:	6121                	addi	sp,sp,64
ffffffffc0203924:	8082                	ret
ffffffffc0203926:	7902                	ld	s2,32(sp)
ffffffffc0203928:	69e2                	ld	s3,24(sp)
ffffffffc020392a:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc020392c:	5575                	li	a0,-3
ffffffffc020392e:	bff9                	j	ffffffffc020390c <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203930:	00003697          	auipc	a3,0x3
ffffffffc0203934:	3c068693          	addi	a3,a3,960 # ffffffffc0206cf0 <etext+0x1560>
ffffffffc0203938:	00003617          	auipc	a2,0x3
ffffffffc020393c:	81060613          	addi	a2,a2,-2032 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203940:	0b300593          	li	a1,179
ffffffffc0203944:	00003517          	auipc	a0,0x3
ffffffffc0203948:	32450513          	addi	a0,a0,804 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc020394c:	afbfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203950 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203950:	7139                	addi	sp,sp,-64
ffffffffc0203952:	fc06                	sd	ra,56(sp)
ffffffffc0203954:	f822                	sd	s0,48(sp)
ffffffffc0203956:	f426                	sd	s1,40(sp)
ffffffffc0203958:	f04a                	sd	s2,32(sp)
ffffffffc020395a:	ec4e                	sd	s3,24(sp)
ffffffffc020395c:	e852                	sd	s4,16(sp)
ffffffffc020395e:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203960:	c525                	beqz	a0,ffffffffc02039c8 <dup_mmap+0x78>
ffffffffc0203962:	892a                	mv	s2,a0
ffffffffc0203964:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203966:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203968:	c1a5                	beqz	a1,ffffffffc02039c8 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc020396a:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc020396c:	04848c63          	beq	s1,s0,ffffffffc02039c4 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203970:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203974:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203978:	ff043a03          	ld	s4,-16(s0)
ffffffffc020397c:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203980:	b50fe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (vma != NULL)
ffffffffc0203984:	c515                	beqz	a0,ffffffffc02039b0 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203986:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203988:	01553423          	sd	s5,8(a0)
ffffffffc020398c:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203990:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc0203994:	854a                	mv	a0,s2
ffffffffc0203996:	dcfff0ef          	jal	ffffffffc0203764 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020399a:	ff043683          	ld	a3,-16(s0)
ffffffffc020399e:	fe843603          	ld	a2,-24(s0)
ffffffffc02039a2:	6c8c                	ld	a1,24(s1)
ffffffffc02039a4:	01893503          	ld	a0,24(s2)
ffffffffc02039a8:	4701                	li	a4,0
ffffffffc02039aa:	a07ff0ef          	jal	ffffffffc02033b0 <copy_range>
ffffffffc02039ae:	dd55                	beqz	a0,ffffffffc020396a <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc02039b0:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02039b2:	70e2                	ld	ra,56(sp)
ffffffffc02039b4:	7442                	ld	s0,48(sp)
ffffffffc02039b6:	74a2                	ld	s1,40(sp)
ffffffffc02039b8:	7902                	ld	s2,32(sp)
ffffffffc02039ba:	69e2                	ld	s3,24(sp)
ffffffffc02039bc:	6a42                	ld	s4,16(sp)
ffffffffc02039be:	6aa2                	ld	s5,8(sp)
ffffffffc02039c0:	6121                	addi	sp,sp,64
ffffffffc02039c2:	8082                	ret
    return 0;
ffffffffc02039c4:	4501                	li	a0,0
ffffffffc02039c6:	b7f5                	j	ffffffffc02039b2 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc02039c8:	00003697          	auipc	a3,0x3
ffffffffc02039cc:	33868693          	addi	a3,a3,824 # ffffffffc0206d00 <etext+0x1570>
ffffffffc02039d0:	00002617          	auipc	a2,0x2
ffffffffc02039d4:	77860613          	addi	a2,a2,1912 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02039d8:	0cf00593          	li	a1,207
ffffffffc02039dc:	00003517          	auipc	a0,0x3
ffffffffc02039e0:	28c50513          	addi	a0,a0,652 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc02039e4:	a63fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02039e8 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02039e8:	1101                	addi	sp,sp,-32
ffffffffc02039ea:	ec06                	sd	ra,24(sp)
ffffffffc02039ec:	e822                	sd	s0,16(sp)
ffffffffc02039ee:	e426                	sd	s1,8(sp)
ffffffffc02039f0:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039f2:	c531                	beqz	a0,ffffffffc0203a3e <exit_mmap+0x56>
ffffffffc02039f4:	591c                	lw	a5,48(a0)
ffffffffc02039f6:	84aa                	mv	s1,a0
ffffffffc02039f8:	e3b9                	bnez	a5,ffffffffc0203a3e <exit_mmap+0x56>
    return listelm->next;
ffffffffc02039fa:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02039fc:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a00:	02850663          	beq	a0,s0,ffffffffc0203a2c <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a04:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a08:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a0c:	854a                	mv	a0,s2
ffffffffc0203a0e:	fdefe0ef          	jal	ffffffffc02021ec <unmap_range>
ffffffffc0203a12:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a14:	fe8498e3          	bne	s1,s0,ffffffffc0203a04 <exit_mmap+0x1c>
ffffffffc0203a18:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a1a:	00848c63          	beq	s1,s0,ffffffffc0203a32 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a1e:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a22:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a26:	854a                	mv	a0,s2
ffffffffc0203a28:	8f9fe0ef          	jal	ffffffffc0202320 <exit_range>
ffffffffc0203a2c:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a2e:	fe8498e3          	bne	s1,s0,ffffffffc0203a1e <exit_mmap+0x36>
    }
}
ffffffffc0203a32:	60e2                	ld	ra,24(sp)
ffffffffc0203a34:	6442                	ld	s0,16(sp)
ffffffffc0203a36:	64a2                	ld	s1,8(sp)
ffffffffc0203a38:	6902                	ld	s2,0(sp)
ffffffffc0203a3a:	6105                	addi	sp,sp,32
ffffffffc0203a3c:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a3e:	00003697          	auipc	a3,0x3
ffffffffc0203a42:	2e268693          	addi	a3,a3,738 # ffffffffc0206d20 <etext+0x1590>
ffffffffc0203a46:	00002617          	auipc	a2,0x2
ffffffffc0203a4a:	70260613          	addi	a2,a2,1794 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203a4e:	0e800593          	li	a1,232
ffffffffc0203a52:	00003517          	auipc	a0,0x3
ffffffffc0203a56:	21650513          	addi	a0,a0,534 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203a5a:	9edfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a5e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a5e:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a60:	04000513          	li	a0,64
{
ffffffffc0203a64:	f406                	sd	ra,40(sp)
ffffffffc0203a66:	f022                	sd	s0,32(sp)
ffffffffc0203a68:	ec26                	sd	s1,24(sp)
ffffffffc0203a6a:	e84a                	sd	s2,16(sp)
ffffffffc0203a6c:	e44e                	sd	s3,8(sp)
ffffffffc0203a6e:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a70:	a60fe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (mm != NULL)
ffffffffc0203a74:	16050c63          	beqz	a0,ffffffffc0203bec <vmm_init+0x18e>
ffffffffc0203a78:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203a7a:	e508                	sd	a0,8(a0)
ffffffffc0203a7c:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a7e:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a82:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a86:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a8a:	02053423          	sd	zero,40(a0)
ffffffffc0203a8e:	02052823          	sw	zero,48(a0)
ffffffffc0203a92:	02053c23          	sd	zero,56(a0)
ffffffffc0203a96:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a9a:	03000513          	li	a0,48
ffffffffc0203a9e:	a32fe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (vma != NULL)
ffffffffc0203aa2:	12050563          	beqz	a0,ffffffffc0203bcc <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203aa6:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203aaa:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203aac:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203ab0:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ab2:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203ab4:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203ab6:	8522                	mv	a0,s0
ffffffffc0203ab8:	cadff0ef          	jal	ffffffffc0203764 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203abc:	fcf9                	bnez	s1,ffffffffc0203a9a <vmm_init+0x3c>
ffffffffc0203abe:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ac2:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ac6:	03000513          	li	a0,48
ffffffffc0203aca:	a06fe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (vma != NULL)
ffffffffc0203ace:	12050f63          	beqz	a0,ffffffffc0203c0c <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203ad2:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203ad6:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203ad8:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203adc:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ade:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ae0:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203ae2:	8522                	mv	a0,s0
ffffffffc0203ae4:	c81ff0ef          	jal	ffffffffc0203764 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ae8:	fd249fe3          	bne	s1,s2,ffffffffc0203ac6 <vmm_init+0x68>
    return listelm->next;
ffffffffc0203aec:	641c                	ld	a5,8(s0)
ffffffffc0203aee:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203af0:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203af4:	1ef40c63          	beq	s0,a5,ffffffffc0203cec <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203af8:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f5e10>
ffffffffc0203afc:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b00:	12d61663          	bne	a2,a3,ffffffffc0203c2c <vmm_init+0x1ce>
ffffffffc0203b04:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b08:	12e69263          	bne	a3,a4,ffffffffc0203c2c <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203b0c:	0715                	addi	a4,a4,5
ffffffffc0203b0e:	679c                	ld	a5,8(a5)
ffffffffc0203b10:	feb712e3          	bne	a4,a1,ffffffffc0203af4 <vmm_init+0x96>
ffffffffc0203b14:	491d                	li	s2,7
ffffffffc0203b16:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b18:	85a6                	mv	a1,s1
ffffffffc0203b1a:	8522                	mv	a0,s0
ffffffffc0203b1c:	c09ff0ef          	jal	ffffffffc0203724 <find_vma>
ffffffffc0203b20:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b22:	20050563          	beqz	a0,ffffffffc0203d2c <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b26:	00148593          	addi	a1,s1,1
ffffffffc0203b2a:	8522                	mv	a0,s0
ffffffffc0203b2c:	bf9ff0ef          	jal	ffffffffc0203724 <find_vma>
ffffffffc0203b30:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b32:	1c050d63          	beqz	a0,ffffffffc0203d0c <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b36:	85ca                	mv	a1,s2
ffffffffc0203b38:	8522                	mv	a0,s0
ffffffffc0203b3a:	bebff0ef          	jal	ffffffffc0203724 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b3e:	18051763          	bnez	a0,ffffffffc0203ccc <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b42:	00348593          	addi	a1,s1,3
ffffffffc0203b46:	8522                	mv	a0,s0
ffffffffc0203b48:	bddff0ef          	jal	ffffffffc0203724 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b4c:	16051063          	bnez	a0,ffffffffc0203cac <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b50:	00448593          	addi	a1,s1,4
ffffffffc0203b54:	8522                	mv	a0,s0
ffffffffc0203b56:	bcfff0ef          	jal	ffffffffc0203724 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b5a:	12051963          	bnez	a0,ffffffffc0203c8c <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b5e:	008a3783          	ld	a5,8(s4)
ffffffffc0203b62:	10979563          	bne	a5,s1,ffffffffc0203c6c <vmm_init+0x20e>
ffffffffc0203b66:	010a3783          	ld	a5,16(s4)
ffffffffc0203b6a:	11279163          	bne	a5,s2,ffffffffc0203c6c <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b6e:	0089b783          	ld	a5,8(s3)
ffffffffc0203b72:	0c979d63          	bne	a5,s1,ffffffffc0203c4c <vmm_init+0x1ee>
ffffffffc0203b76:	0109b783          	ld	a5,16(s3)
ffffffffc0203b7a:	0d279963          	bne	a5,s2,ffffffffc0203c4c <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b7e:	0495                	addi	s1,s1,5
ffffffffc0203b80:	1f900793          	li	a5,505
ffffffffc0203b84:	0915                	addi	s2,s2,5
ffffffffc0203b86:	f8f499e3          	bne	s1,a5,ffffffffc0203b18 <vmm_init+0xba>
ffffffffc0203b8a:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b8c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b8e:	85a6                	mv	a1,s1
ffffffffc0203b90:	8522                	mv	a0,s0
ffffffffc0203b92:	b93ff0ef          	jal	ffffffffc0203724 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203b96:	1a051b63          	bnez	a0,ffffffffc0203d4c <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203b9a:	14fd                	addi	s1,s1,-1
ffffffffc0203b9c:	ff2499e3          	bne	s1,s2,ffffffffc0203b8e <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203ba0:	8522                	mv	a0,s0
ffffffffc0203ba2:	c91ff0ef          	jal	ffffffffc0203832 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ba6:	00003517          	auipc	a0,0x3
ffffffffc0203baa:	2ea50513          	addi	a0,a0,746 # ffffffffc0206e90 <etext+0x1700>
ffffffffc0203bae:	de6fc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203bb2:	7402                	ld	s0,32(sp)
ffffffffc0203bb4:	70a2                	ld	ra,40(sp)
ffffffffc0203bb6:	64e2                	ld	s1,24(sp)
ffffffffc0203bb8:	6942                	ld	s2,16(sp)
ffffffffc0203bba:	69a2                	ld	s3,8(sp)
ffffffffc0203bbc:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bbe:	00003517          	auipc	a0,0x3
ffffffffc0203bc2:	2f250513          	addi	a0,a0,754 # ffffffffc0206eb0 <etext+0x1720>
}
ffffffffc0203bc6:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bc8:	dccfc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203bcc:	00003697          	auipc	a3,0x3
ffffffffc0203bd0:	17468693          	addi	a3,a3,372 # ffffffffc0206d40 <etext+0x15b0>
ffffffffc0203bd4:	00002617          	auipc	a2,0x2
ffffffffc0203bd8:	57460613          	addi	a2,a2,1396 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203bdc:	12c00593          	li	a1,300
ffffffffc0203be0:	00003517          	auipc	a0,0x3
ffffffffc0203be4:	08850513          	addi	a0,a0,136 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203be8:	85ffc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203bec:	00003697          	auipc	a3,0x3
ffffffffc0203bf0:	10468693          	addi	a3,a3,260 # ffffffffc0206cf0 <etext+0x1560>
ffffffffc0203bf4:	00002617          	auipc	a2,0x2
ffffffffc0203bf8:	55460613          	addi	a2,a2,1364 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203bfc:	12400593          	li	a1,292
ffffffffc0203c00:	00003517          	auipc	a0,0x3
ffffffffc0203c04:	06850513          	addi	a0,a0,104 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203c08:	83ffc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203c0c:	00003697          	auipc	a3,0x3
ffffffffc0203c10:	13468693          	addi	a3,a3,308 # ffffffffc0206d40 <etext+0x15b0>
ffffffffc0203c14:	00002617          	auipc	a2,0x2
ffffffffc0203c18:	53460613          	addi	a2,a2,1332 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203c1c:	13300593          	li	a1,307
ffffffffc0203c20:	00003517          	auipc	a0,0x3
ffffffffc0203c24:	04850513          	addi	a0,a0,72 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203c28:	81ffc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c2c:	00003697          	auipc	a3,0x3
ffffffffc0203c30:	13c68693          	addi	a3,a3,316 # ffffffffc0206d68 <etext+0x15d8>
ffffffffc0203c34:	00002617          	auipc	a2,0x2
ffffffffc0203c38:	51460613          	addi	a2,a2,1300 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203c3c:	13d00593          	li	a1,317
ffffffffc0203c40:	00003517          	auipc	a0,0x3
ffffffffc0203c44:	02850513          	addi	a0,a0,40 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203c48:	ffefc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c4c:	00003697          	auipc	a3,0x3
ffffffffc0203c50:	1d468693          	addi	a3,a3,468 # ffffffffc0206e20 <etext+0x1690>
ffffffffc0203c54:	00002617          	auipc	a2,0x2
ffffffffc0203c58:	4f460613          	addi	a2,a2,1268 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203c5c:	14f00593          	li	a1,335
ffffffffc0203c60:	00003517          	auipc	a0,0x3
ffffffffc0203c64:	00850513          	addi	a0,a0,8 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203c68:	fdefc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c6c:	00003697          	auipc	a3,0x3
ffffffffc0203c70:	18468693          	addi	a3,a3,388 # ffffffffc0206df0 <etext+0x1660>
ffffffffc0203c74:	00002617          	auipc	a2,0x2
ffffffffc0203c78:	4d460613          	addi	a2,a2,1236 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203c7c:	14e00593          	li	a1,334
ffffffffc0203c80:	00003517          	auipc	a0,0x3
ffffffffc0203c84:	fe850513          	addi	a0,a0,-24 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203c88:	fbefc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203c8c:	00003697          	auipc	a3,0x3
ffffffffc0203c90:	15468693          	addi	a3,a3,340 # ffffffffc0206de0 <etext+0x1650>
ffffffffc0203c94:	00002617          	auipc	a2,0x2
ffffffffc0203c98:	4b460613          	addi	a2,a2,1204 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203c9c:	14c00593          	li	a1,332
ffffffffc0203ca0:	00003517          	auipc	a0,0x3
ffffffffc0203ca4:	fc850513          	addi	a0,a0,-56 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203ca8:	f9efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203cac:	00003697          	auipc	a3,0x3
ffffffffc0203cb0:	12468693          	addi	a3,a3,292 # ffffffffc0206dd0 <etext+0x1640>
ffffffffc0203cb4:	00002617          	auipc	a2,0x2
ffffffffc0203cb8:	49460613          	addi	a2,a2,1172 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203cbc:	14a00593          	li	a1,330
ffffffffc0203cc0:	00003517          	auipc	a0,0x3
ffffffffc0203cc4:	fa850513          	addi	a0,a0,-88 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203cc8:	f7efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203ccc:	00003697          	auipc	a3,0x3
ffffffffc0203cd0:	0f468693          	addi	a3,a3,244 # ffffffffc0206dc0 <etext+0x1630>
ffffffffc0203cd4:	00002617          	auipc	a2,0x2
ffffffffc0203cd8:	47460613          	addi	a2,a2,1140 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203cdc:	14800593          	li	a1,328
ffffffffc0203ce0:	00003517          	auipc	a0,0x3
ffffffffc0203ce4:	f8850513          	addi	a0,a0,-120 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203ce8:	f5efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203cec:	00003697          	auipc	a3,0x3
ffffffffc0203cf0:	06468693          	addi	a3,a3,100 # ffffffffc0206d50 <etext+0x15c0>
ffffffffc0203cf4:	00002617          	auipc	a2,0x2
ffffffffc0203cf8:	45460613          	addi	a2,a2,1108 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203cfc:	13b00593          	li	a1,315
ffffffffc0203d00:	00003517          	auipc	a0,0x3
ffffffffc0203d04:	f6850513          	addi	a0,a0,-152 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203d08:	f3efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203d0c:	00003697          	auipc	a3,0x3
ffffffffc0203d10:	0a468693          	addi	a3,a3,164 # ffffffffc0206db0 <etext+0x1620>
ffffffffc0203d14:	00002617          	auipc	a2,0x2
ffffffffc0203d18:	43460613          	addi	a2,a2,1076 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203d1c:	14600593          	li	a1,326
ffffffffc0203d20:	00003517          	auipc	a0,0x3
ffffffffc0203d24:	f4850513          	addi	a0,a0,-184 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203d28:	f1efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203d2c:	00003697          	auipc	a3,0x3
ffffffffc0203d30:	07468693          	addi	a3,a3,116 # ffffffffc0206da0 <etext+0x1610>
ffffffffc0203d34:	00002617          	auipc	a2,0x2
ffffffffc0203d38:	41460613          	addi	a2,a2,1044 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203d3c:	14400593          	li	a1,324
ffffffffc0203d40:	00003517          	auipc	a0,0x3
ffffffffc0203d44:	f2850513          	addi	a0,a0,-216 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203d48:	efefc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d4c:	6914                	ld	a3,16(a0)
ffffffffc0203d4e:	6510                	ld	a2,8(a0)
ffffffffc0203d50:	0004859b          	sext.w	a1,s1
ffffffffc0203d54:	00003517          	auipc	a0,0x3
ffffffffc0203d58:	0fc50513          	addi	a0,a0,252 # ffffffffc0206e50 <etext+0x16c0>
ffffffffc0203d5c:	c38fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203d60:	00003697          	auipc	a3,0x3
ffffffffc0203d64:	11868693          	addi	a3,a3,280 # ffffffffc0206e78 <etext+0x16e8>
ffffffffc0203d68:	00002617          	auipc	a2,0x2
ffffffffc0203d6c:	3e060613          	addi	a2,a2,992 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0203d70:	15900593          	li	a1,345
ffffffffc0203d74:	00003517          	auipc	a0,0x3
ffffffffc0203d78:	ef450513          	addi	a0,a0,-268 # ffffffffc0206c68 <etext+0x14d8>
ffffffffc0203d7c:	ecafc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203d80 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d80:	7179                	addi	sp,sp,-48
ffffffffc0203d82:	f022                	sd	s0,32(sp)
ffffffffc0203d84:	f406                	sd	ra,40(sp)
ffffffffc0203d86:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d88:	c52d                	beqz	a0,ffffffffc0203df2 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d8a:	002007b7          	lui	a5,0x200
ffffffffc0203d8e:	04f5ed63          	bltu	a1,a5,ffffffffc0203de8 <user_mem_check+0x68>
ffffffffc0203d92:	ec26                	sd	s1,24(sp)
ffffffffc0203d94:	00c584b3          	add	s1,a1,a2
ffffffffc0203d98:	0695ff63          	bgeu	a1,s1,ffffffffc0203e16 <user_mem_check+0x96>
ffffffffc0203d9c:	4785                	li	a5,1
ffffffffc0203d9e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203da0:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e29>
ffffffffc0203da2:	06f4fa63          	bgeu	s1,a5,ffffffffc0203e16 <user_mem_check+0x96>
ffffffffc0203da6:	e84a                	sd	s2,16(sp)
ffffffffc0203da8:	e44e                	sd	s3,8(sp)
ffffffffc0203daa:	8936                	mv	s2,a3
ffffffffc0203dac:	89aa                	mv	s3,a0
ffffffffc0203dae:	a829                	j	ffffffffc0203dc8 <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203db0:	6685                	lui	a3,0x1
ffffffffc0203db2:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203db4:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203db8:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dba:	c685                	beqz	a3,ffffffffc0203de2 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dbc:	c399                	beqz	a5,ffffffffc0203dc2 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203dbe:	02e46263          	bltu	s0,a4,ffffffffc0203de2 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203dc2:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203dc4:	04947b63          	bgeu	s0,s1,ffffffffc0203e1a <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203dc8:	85a2                	mv	a1,s0
ffffffffc0203dca:	854e                	mv	a0,s3
ffffffffc0203dcc:	959ff0ef          	jal	ffffffffc0203724 <find_vma>
ffffffffc0203dd0:	c909                	beqz	a0,ffffffffc0203de2 <user_mem_check+0x62>
ffffffffc0203dd2:	6518                	ld	a4,8(a0)
ffffffffc0203dd4:	00e46763          	bltu	s0,a4,ffffffffc0203de2 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dd8:	4d1c                	lw	a5,24(a0)
ffffffffc0203dda:	fc091be3          	bnez	s2,ffffffffc0203db0 <user_mem_check+0x30>
ffffffffc0203dde:	8b85                	andi	a5,a5,1
ffffffffc0203de0:	f3ed                	bnez	a5,ffffffffc0203dc2 <user_mem_check+0x42>
ffffffffc0203de2:	64e2                	ld	s1,24(sp)
ffffffffc0203de4:	6942                	ld	s2,16(sp)
ffffffffc0203de6:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203de8:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203dea:	70a2                	ld	ra,40(sp)
ffffffffc0203dec:	7402                	ld	s0,32(sp)
ffffffffc0203dee:	6145                	addi	sp,sp,48
ffffffffc0203df0:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203df2:	c02007b7          	lui	a5,0xc0200
ffffffffc0203df6:	fef5eae3          	bltu	a1,a5,ffffffffc0203dea <user_mem_check+0x6a>
ffffffffc0203dfa:	c80007b7          	lui	a5,0xc8000
ffffffffc0203dfe:	962e                	add	a2,a2,a1
ffffffffc0203e00:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d64831>
ffffffffc0203e02:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203e06:	00f63633          	sltu	a2,a2,a5
ffffffffc0203e0a:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e0c:	00867533          	and	a0,a2,s0
ffffffffc0203e10:	7402                	ld	s0,32(sp)
ffffffffc0203e12:	6145                	addi	sp,sp,48
ffffffffc0203e14:	8082                	ret
ffffffffc0203e16:	64e2                	ld	s1,24(sp)
ffffffffc0203e18:	bfc1                	j	ffffffffc0203de8 <user_mem_check+0x68>
ffffffffc0203e1a:	64e2                	ld	s1,24(sp)
ffffffffc0203e1c:	6942                	ld	s2,16(sp)
ffffffffc0203e1e:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203e20:	4505                	li	a0,1
ffffffffc0203e22:	b7e1                	j	ffffffffc0203dea <user_mem_check+0x6a>

ffffffffc0203e24 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e24:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e26:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e28:	5e0000ef          	jal	ffffffffc0204408 <do_exit>

ffffffffc0203e2c <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e2c:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e2e:	10800513          	li	a0,264
{
ffffffffc0203e32:	e022                	sd	s0,0(sp)
ffffffffc0203e34:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e36:	e9bfd0ef          	jal	ffffffffc0201cd0 <kmalloc>
ffffffffc0203e3a:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203e3c:	cd21                	beqz	a0,ffffffffc0203e94 <alloc_proc+0x68>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        // 初始化进程状态为未初始化
        proc->state = PROC_UNINIT;
ffffffffc0203e3e:	57fd                	li	a5,-1
ffffffffc0203e40:	1782                	slli	a5,a5,0x20
ffffffffc0203e42:	e11c                	sd	a5,0(a0)
        // 初始化进程ID为-1（无效ID）
        proc->pid = -1;
        // 初始化运行次数为0
        proc->runs = 0;
ffffffffc0203e44:	00052423          	sw	zero,8(a0)
        // 初始化内核栈地址为0
        proc->kstack = 0;
ffffffffc0203e48:	00053823          	sd	zero,16(a0)
        // 初始化不需要重新调度
        proc->need_resched = 0;
ffffffffc0203e4c:	00053c23          	sd	zero,24(a0)
        // 初始化父进程指针为NULL
        proc->parent = NULL;
ffffffffc0203e50:	02053023          	sd	zero,32(a0)
        // 初始化内存管理结构为NULL
        proc->mm = NULL;
ffffffffc0203e54:	02053423          	sd	zero,40(a0)
        // 初始化上下文结构体（全部设为0）
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203e58:	07000613          	li	a2,112
ffffffffc0203e5c:	4581                	li	a1,0
ffffffffc0203e5e:	03050513          	addi	a0,a0,48
ffffffffc0203e62:	105010ef          	jal	ffffffffc0205766 <memset>
        // 初始化陷阱帧指针为NULL
        proc->tf = NULL;
        // 初始化页目录基址为boot_pgdir
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203e66:	00098797          	auipc	a5,0x98
ffffffffc0203e6a:	9227b783          	ld	a5,-1758(a5) # ffffffffc029b788 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc0203e6e:	0a043023          	sd	zero,160(s0)
        // 初始化标志位为0
        proc->flags = 0;
ffffffffc0203e72:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203e76:	f45c                	sd	a5,168(s0)
        // 初始化进程名称为空字符串
        memset(proc->name, 0, PROC_NAME_LEN + 1); 
ffffffffc0203e78:	0b440513          	addi	a0,s0,180
ffffffffc0203e7c:	4641                	li	a2,16
ffffffffc0203e7e:	4581                	li	a1,0
ffffffffc0203e80:	0e7010ef          	jal	ffffffffc0205766 <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0; 
ffffffffc0203e84:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;  
ffffffffc0203e88:	10043023          	sd	zero,256(s0)
ffffffffc0203e8c:	0e043c23          	sd	zero,248(s0)
ffffffffc0203e90:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0203e94:	60a2                	ld	ra,8(sp)
ffffffffc0203e96:	8522                	mv	a0,s0
ffffffffc0203e98:	6402                	ld	s0,0(sp)
ffffffffc0203e9a:	0141                	addi	sp,sp,16
ffffffffc0203e9c:	8082                	ret

ffffffffc0203e9e <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e9e:	00098797          	auipc	a5,0x98
ffffffffc0203ea2:	91a7b783          	ld	a5,-1766(a5) # ffffffffc029b7b8 <current>
ffffffffc0203ea6:	73c8                	ld	a0,160(a5)
ffffffffc0203ea8:	80efd06f          	j	ffffffffc0200eb6 <forkrets>

ffffffffc0203eac <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eac:	00098797          	auipc	a5,0x98
ffffffffc0203eb0:	90c7b783          	ld	a5,-1780(a5) # ffffffffc029b7b8 <current>
{
ffffffffc0203eb4:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eb6:	00003617          	auipc	a2,0x3
ffffffffc0203eba:	01260613          	addi	a2,a2,18 # ffffffffc0206ec8 <etext+0x1738>
ffffffffc0203ebe:	43cc                	lw	a1,4(a5)
ffffffffc0203ec0:	00003517          	auipc	a0,0x3
ffffffffc0203ec4:	01850513          	addi	a0,a0,24 # ffffffffc0206ed8 <etext+0x1748>
{
ffffffffc0203ec8:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eca:	acafc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0203ece:	3fe05797          	auipc	a5,0x3fe05
ffffffffc0203ed2:	d3278793          	addi	a5,a5,-718 # 8c00 <_binary_obj___user_faultread_out_size>
ffffffffc0203ed6:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc0203ed8:	00003517          	auipc	a0,0x3
ffffffffc0203edc:	ff050513          	addi	a0,a0,-16 # ffffffffc0206ec8 <etext+0x1738>
ffffffffc0203ee0:	0002d797          	auipc	a5,0x2d
ffffffffc0203ee4:	73078793          	addi	a5,a5,1840 # ffffffffc0231610 <_binary_obj___user_faultread_out_start>
ffffffffc0203ee8:	f03e                	sd	a5,32(sp)
ffffffffc0203eea:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203eec:	e802                	sd	zero,16(sp)
ffffffffc0203eee:	7c4010ef          	jal	ffffffffc02056b2 <strlen>
ffffffffc0203ef2:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203ef4:	4511                	li	a0,4
ffffffffc0203ef6:	55a2                	lw	a1,40(sp)
ffffffffc0203ef8:	4662                	lw	a2,24(sp)
ffffffffc0203efa:	5682                	lw	a3,32(sp)
ffffffffc0203efc:	4722                	lw	a4,8(sp)
ffffffffc0203efe:	48a9                	li	a7,10
ffffffffc0203f00:	9002                	ebreak
ffffffffc0203f02:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203f04:	65c2                	ld	a1,16(sp)
ffffffffc0203f06:	00003517          	auipc	a0,0x3
ffffffffc0203f0a:	ffa50513          	addi	a0,a0,-6 # ffffffffc0206f00 <etext+0x1770>
ffffffffc0203f0e:	a86fc0ef          	jal	ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203f12:	00003617          	auipc	a2,0x3
ffffffffc0203f16:	ffe60613          	addi	a2,a2,-2 # ffffffffc0206f10 <etext+0x1780>
ffffffffc0203f1a:	3be00593          	li	a1,958
ffffffffc0203f1e:	00003517          	auipc	a0,0x3
ffffffffc0203f22:	01250513          	addi	a0,a0,18 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0203f26:	d20fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203f2a <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f2a:	6d14                	ld	a3,24(a0)
{
ffffffffc0203f2c:	1141                	addi	sp,sp,-16
ffffffffc0203f2e:	e406                	sd	ra,8(sp)
ffffffffc0203f30:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f34:	02f6ee63          	bltu	a3,a5,ffffffffc0203f70 <put_pgdir+0x46>
ffffffffc0203f38:	00098717          	auipc	a4,0x98
ffffffffc0203f3c:	86073703          	ld	a4,-1952(a4) # ffffffffc029b798 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203f40:	00098797          	auipc	a5,0x98
ffffffffc0203f44:	8607b783          	ld	a5,-1952(a5) # ffffffffc029b7a0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203f48:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203f4a:	82b1                	srli	a3,a3,0xc
ffffffffc0203f4c:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f88 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f50:	00004797          	auipc	a5,0x4
ffffffffc0203f54:	9687b783          	ld	a5,-1688(a5) # ffffffffc02078b8 <nbase>
ffffffffc0203f58:	00098517          	auipc	a0,0x98
ffffffffc0203f5c:	85053503          	ld	a0,-1968(a0) # ffffffffc029b7a8 <pages>
}
ffffffffc0203f60:	60a2                	ld	ra,8(sp)
ffffffffc0203f62:	8e9d                	sub	a3,a3,a5
ffffffffc0203f64:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f66:	4585                	li	a1,1
ffffffffc0203f68:	9536                	add	a0,a0,a3
}
ffffffffc0203f6a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f6c:	f61fd06f          	j	ffffffffc0201ecc <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f70:	00002617          	auipc	a2,0x2
ffffffffc0203f74:	63060613          	addi	a2,a2,1584 # ffffffffc02065a0 <etext+0xe10>
ffffffffc0203f78:	07700593          	li	a1,119
ffffffffc0203f7c:	00002517          	auipc	a0,0x2
ffffffffc0203f80:	5a450513          	addi	a0,a0,1444 # ffffffffc0206520 <etext+0xd90>
ffffffffc0203f84:	cc2fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f88:	00002617          	auipc	a2,0x2
ffffffffc0203f8c:	64060613          	addi	a2,a2,1600 # ffffffffc02065c8 <etext+0xe38>
ffffffffc0203f90:	06900593          	li	a1,105
ffffffffc0203f94:	00002517          	auipc	a0,0x2
ffffffffc0203f98:	58c50513          	addi	a0,a0,1420 # ffffffffc0206520 <etext+0xd90>
ffffffffc0203f9c:	caafc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203fa0 <proc_run>:
    if (proc != current)
ffffffffc0203fa0:	00098697          	auipc	a3,0x98
ffffffffc0203fa4:	8186b683          	ld	a3,-2024(a3) # ffffffffc029b7b8 <current>
ffffffffc0203fa8:	04a68463          	beq	a3,a0,ffffffffc0203ff0 <proc_run+0x50>
{
ffffffffc0203fac:	1101                	addi	sp,sp,-32
ffffffffc0203fae:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fb0:	100027f3          	csrr	a5,sstatus
ffffffffc0203fb4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203fb6:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fb8:	ef8d                	bnez	a5,ffffffffc0203ff2 <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fba:	755c                	ld	a5,168(a0)
ffffffffc0203fbc:	577d                	li	a4,-1
ffffffffc0203fbe:	177e                	slli	a4,a4,0x3f
ffffffffc0203fc0:	83b1                	srli	a5,a5,0xc
ffffffffc0203fc2:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc0203fc4:	00097597          	auipc	a1,0x97
ffffffffc0203fc8:	7ea5ba23          	sd	a0,2036(a1) # ffffffffc029b7b8 <current>
ffffffffc0203fcc:	8fd9                	or	a5,a5,a4
ffffffffc0203fce:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203fd2:	03050593          	addi	a1,a0,48
ffffffffc0203fd6:	03068513          	addi	a0,a3,48
ffffffffc0203fda:	090010ef          	jal	ffffffffc020506a <switch_to>
    if (flag)
ffffffffc0203fde:	6602                	ld	a2,0(sp)
ffffffffc0203fe0:	e601                	bnez	a2,ffffffffc0203fe8 <proc_run+0x48>
}
ffffffffc0203fe2:	60e2                	ld	ra,24(sp)
ffffffffc0203fe4:	6105                	addi	sp,sp,32
ffffffffc0203fe6:	8082                	ret
ffffffffc0203fe8:	60e2                	ld	ra,24(sp)
ffffffffc0203fea:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203fec:	913fc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0203ff0:	8082                	ret
ffffffffc0203ff2:	e42a                	sd	a0,8(sp)
ffffffffc0203ff4:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc0203ff6:	90ffc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0203ffa:	6522                	ld	a0,8(sp)
ffffffffc0203ffc:	6682                	ld	a3,0(sp)
ffffffffc0203ffe:	4605                	li	a2,1
ffffffffc0204000:	bf6d                	j	ffffffffc0203fba <proc_run+0x1a>

ffffffffc0204002 <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc0204002:	00097797          	auipc	a5,0x97
ffffffffc0204006:	7ae7a783          	lw	a5,1966(a5) # ffffffffc029b7b0 <nr_process>
{
ffffffffc020400a:	7159                	addi	sp,sp,-112
ffffffffc020400c:	e4ce                	sd	s3,72(sp)
ffffffffc020400e:	f486                	sd	ra,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204010:	6985                	lui	s3,0x1
ffffffffc0204012:	3337d463          	bge	a5,s3,ffffffffc020433a <do_fork+0x338>
ffffffffc0204016:	f0a2                	sd	s0,96(sp)
ffffffffc0204018:	eca6                	sd	s1,88(sp)
ffffffffc020401a:	e8ca                	sd	s2,80(sp)
ffffffffc020401c:	e86a                	sd	s10,16(sp)
ffffffffc020401e:	892e                	mv	s2,a1
ffffffffc0204020:	84b2                	mv	s1,a2
ffffffffc0204022:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL){
ffffffffc0204024:	e09ff0ef          	jal	ffffffffc0203e2c <alloc_proc>
ffffffffc0204028:	842a                	mv	s0,a0
ffffffffc020402a:	2e050463          	beqz	a0,ffffffffc0204312 <do_fork+0x310>
ffffffffc020402e:	f45e                	sd	s7,40(sp)
    proc->parent = current;
ffffffffc0204030:	00097b97          	auipc	s7,0x97
ffffffffc0204034:	788b8b93          	addi	s7,s7,1928 # ffffffffc029b7b8 <current>
ffffffffc0204038:	000bb783          	ld	a5,0(s7)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020403c:	4509                	li	a0,2
    proc->parent = current;
ffffffffc020403e:	f01c                	sd	a5,32(s0)
    current->wait_state = 0; // set current process's wait_state is 0
ffffffffc0204040:	0e07a623          	sw	zero,236(a5)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204044:	e4ffd0ef          	jal	ffffffffc0201e92 <alloc_pages>
    if (page != NULL)
ffffffffc0204048:	2c050163          	beqz	a0,ffffffffc020430a <do_fork+0x308>
ffffffffc020404c:	e0d2                	sd	s4,64(sp)
    return page - pages + nbase;
ffffffffc020404e:	00097a17          	auipc	s4,0x97
ffffffffc0204052:	75aa0a13          	addi	s4,s4,1882 # ffffffffc029b7a8 <pages>
ffffffffc0204056:	000a3783          	ld	a5,0(s4)
ffffffffc020405a:	fc56                	sd	s5,56(sp)
ffffffffc020405c:	00004a97          	auipc	s5,0x4
ffffffffc0204060:	85ca8a93          	addi	s5,s5,-1956 # ffffffffc02078b8 <nbase>
ffffffffc0204064:	000ab703          	ld	a4,0(s5)
ffffffffc0204068:	40f506b3          	sub	a3,a0,a5
ffffffffc020406c:	f85a                	sd	s6,48(sp)
    return KADDR(page2pa(page));
ffffffffc020406e:	00097b17          	auipc	s6,0x97
ffffffffc0204072:	732b0b13          	addi	s6,s6,1842 # ffffffffc029b7a0 <npage>
ffffffffc0204076:	ec66                	sd	s9,24(sp)
    return page - pages + nbase;
ffffffffc0204078:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020407a:	5cfd                	li	s9,-1
ffffffffc020407c:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc0204080:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204082:	00ccdc93          	srli	s9,s9,0xc
ffffffffc0204086:	0196f633          	and	a2,a3,s9
ffffffffc020408a:	f062                	sd	s8,32(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc020408c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020408e:	2cf67463          	bgeu	a2,a5,ffffffffc0204356 <do_fork+0x354>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204092:	000bb603          	ld	a2,0(s7)
ffffffffc0204096:	00097b97          	auipc	s7,0x97
ffffffffc020409a:	702b8b93          	addi	s7,s7,1794 # ffffffffc029b798 <va_pa_offset>
ffffffffc020409e:	000bb783          	ld	a5,0(s7)
ffffffffc02040a2:	02863c03          	ld	s8,40(a2)
ffffffffc02040a6:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02040a8:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc02040aa:	020c0863          	beqz	s8,ffffffffc02040da <do_fork+0xd8>
    if (clone_flags & CLONE_VM)
ffffffffc02040ae:	100d7793          	andi	a5,s10,256
ffffffffc02040b2:	18078063          	beqz	a5,ffffffffc0204232 <do_fork+0x230>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02040b6:	030c2703          	lw	a4,48(s8)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040ba:	018c3783          	ld	a5,24(s8)
ffffffffc02040be:	c02006b7          	lui	a3,0xc0200
ffffffffc02040c2:	2705                	addiw	a4,a4,1
ffffffffc02040c4:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc02040c8:	03843423          	sd	s8,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040cc:	2ad7ed63          	bltu	a5,a3,ffffffffc0204386 <do_fork+0x384>
ffffffffc02040d0:	000bb703          	ld	a4,0(s7)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040d4:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040d6:	8f99                	sub	a5,a5,a4
ffffffffc02040d8:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040da:	6789                	lui	a5,0x2
ffffffffc02040dc:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6cf0>
ffffffffc02040e0:	96be                	add	a3,a3,a5
ffffffffc02040e2:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc02040e4:	87b6                	mv	a5,a3
ffffffffc02040e6:	12048713          	addi	a4,s1,288
ffffffffc02040ea:	6890                	ld	a2,16(s1)
ffffffffc02040ec:	6088                	ld	a0,0(s1)
ffffffffc02040ee:	648c                	ld	a1,8(s1)
ffffffffc02040f0:	eb90                	sd	a2,16(a5)
ffffffffc02040f2:	e388                	sd	a0,0(a5)
ffffffffc02040f4:	e78c                	sd	a1,8(a5)
ffffffffc02040f6:	6c90                	ld	a2,24(s1)
ffffffffc02040f8:	02048493          	addi	s1,s1,32
ffffffffc02040fc:	02078793          	addi	a5,a5,32
ffffffffc0204100:	fec7bc23          	sd	a2,-8(a5)
ffffffffc0204104:	fee493e3          	bne	s1,a4,ffffffffc02040ea <do_fork+0xe8>
    proc->tf->gpr.a0 = 0;
ffffffffc0204108:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020410c:	20090963          	beqz	s2,ffffffffc020431e <do_fork+0x31c>
    if (++last_pid >= MAX_PID)
ffffffffc0204110:	00093517          	auipc	a0,0x93
ffffffffc0204114:	20c52503          	lw	a0,524(a0) # ffffffffc029731c <last_pid.1>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204118:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020411c:	00000797          	auipc	a5,0x0
ffffffffc0204120:	d8278793          	addi	a5,a5,-638 # ffffffffc0203e9e <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0204124:	2505                	addiw	a0,a0,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204126:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204128:	fc14                	sd	a3,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc020412a:	00093717          	auipc	a4,0x93
ffffffffc020412e:	1ea72923          	sw	a0,498(a4) # ffffffffc029731c <last_pid.1>
ffffffffc0204132:	6789                	lui	a5,0x2
ffffffffc0204134:	1ef55763          	bge	a0,a5,ffffffffc0204322 <do_fork+0x320>
    if (last_pid >= next_safe)
ffffffffc0204138:	00093797          	auipc	a5,0x93
ffffffffc020413c:	1e07a783          	lw	a5,480(a5) # ffffffffc0297318 <next_safe.0>
ffffffffc0204140:	00097497          	auipc	s1,0x97
ffffffffc0204144:	5f848493          	addi	s1,s1,1528 # ffffffffc029b738 <proc_list>
ffffffffc0204148:	06f54563          	blt	a0,a5,ffffffffc02041b2 <do_fork+0x1b0>
ffffffffc020414c:	00097497          	auipc	s1,0x97
ffffffffc0204150:	5ec48493          	addi	s1,s1,1516 # ffffffffc029b738 <proc_list>
ffffffffc0204154:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc0204158:	6789                	lui	a5,0x2
ffffffffc020415a:	00093717          	auipc	a4,0x93
ffffffffc020415e:	1af72f23          	sw	a5,446(a4) # ffffffffc0297318 <next_safe.0>
ffffffffc0204162:	86aa                	mv	a3,a0
ffffffffc0204164:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204166:	04988063          	beq	a7,s1,ffffffffc02041a6 <do_fork+0x1a4>
ffffffffc020416a:	882e                	mv	a6,a1
ffffffffc020416c:	87c6                	mv	a5,a7
ffffffffc020416e:	6609                	lui	a2,0x2
ffffffffc0204170:	a811                	j	ffffffffc0204184 <do_fork+0x182>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204172:	00e6d663          	bge	a3,a4,ffffffffc020417e <do_fork+0x17c>
ffffffffc0204176:	00c75463          	bge	a4,a2,ffffffffc020417e <do_fork+0x17c>
                next_safe = proc->pid;
ffffffffc020417a:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020417c:	4805                	li	a6,1
ffffffffc020417e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204180:	00978d63          	beq	a5,s1,ffffffffc020419a <do_fork+0x198>
            if (proc->pid == last_pid)
ffffffffc0204184:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6c94>
ffffffffc0204188:	fed715e3          	bne	a4,a3,ffffffffc0204172 <do_fork+0x170>
                if (++last_pid >= next_safe)
ffffffffc020418c:	2685                	addiw	a3,a3,1
ffffffffc020418e:	1ac6d063          	bge	a3,a2,ffffffffc020432e <do_fork+0x32c>
ffffffffc0204192:	679c                	ld	a5,8(a5)
ffffffffc0204194:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204196:	fe9797e3          	bne	a5,s1,ffffffffc0204184 <do_fork+0x182>
ffffffffc020419a:	00080663          	beqz	a6,ffffffffc02041a6 <do_fork+0x1a4>
ffffffffc020419e:	00093797          	auipc	a5,0x93
ffffffffc02041a2:	16c7ad23          	sw	a2,378(a5) # ffffffffc0297318 <next_safe.0>
ffffffffc02041a6:	c591                	beqz	a1,ffffffffc02041b2 <do_fork+0x1b0>
ffffffffc02041a8:	00093797          	auipc	a5,0x93
ffffffffc02041ac:	16d7aa23          	sw	a3,372(a5) # ffffffffc029731c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041b0:	8536                	mv	a0,a3
    proc->pid = get_pid();
ffffffffc02041b2:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041b4:	45a9                	li	a1,10
ffffffffc02041b6:	11a010ef          	jal	ffffffffc02052d0 <hash32>
ffffffffc02041ba:	02051793          	slli	a5,a0,0x20
ffffffffc02041be:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041c2:	00093797          	auipc	a5,0x93
ffffffffc02041c6:	57678793          	addi	a5,a5,1398 # ffffffffc0297738 <hash_list>
ffffffffc02041ca:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02041cc:	6518                	ld	a4,8(a0)
ffffffffc02041ce:	0d840793          	addi	a5,s0,216
ffffffffc02041d2:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc02041d4:	e31c                	sd	a5,0(a4)
ffffffffc02041d6:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02041d8:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02041da:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041de:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc02041e0:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02041e2:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc02041e4:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041e8:	7b74                	ld	a3,240(a4)
ffffffffc02041ea:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc02041ec:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02041ee:	e464                	sd	s1,200(s0)
ffffffffc02041f0:	10d43023          	sd	a3,256(s0)
ffffffffc02041f4:	c299                	beqz	a3,ffffffffc02041fa <do_fork+0x1f8>
        proc->optr->yptr = proc;
ffffffffc02041f6:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc02041f8:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc02041fa:	00097797          	auipc	a5,0x97
ffffffffc02041fe:	5b67a783          	lw	a5,1462(a5) # ffffffffc029b7b0 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204202:	fb60                	sd	s0,240(a4)
    wakeup_proc(proc);
ffffffffc0204204:	8522                	mv	a0,s0
    nr_process++;
ffffffffc0204206:	2785                	addiw	a5,a5,1
ffffffffc0204208:	00097717          	auipc	a4,0x97
ffffffffc020420c:	5af72423          	sw	a5,1448(a4) # ffffffffc029b7b0 <nr_process>
    wakeup_proc(proc);
ffffffffc0204210:	6c5000ef          	jal	ffffffffc02050d4 <wakeup_proc>
    ret = proc->pid;
ffffffffc0204214:	4048                	lw	a0,4(s0)
ffffffffc0204216:	64e6                	ld	s1,88(sp)
ffffffffc0204218:	7406                	ld	s0,96(sp)
ffffffffc020421a:	6946                	ld	s2,80(sp)
ffffffffc020421c:	6a06                	ld	s4,64(sp)
ffffffffc020421e:	7ae2                	ld	s5,56(sp)
ffffffffc0204220:	7b42                	ld	s6,48(sp)
ffffffffc0204222:	7ba2                	ld	s7,40(sp)
ffffffffc0204224:	7c02                	ld	s8,32(sp)
ffffffffc0204226:	6ce2                	ld	s9,24(sp)
ffffffffc0204228:	6d42                	ld	s10,16(sp)
}
ffffffffc020422a:	70a6                	ld	ra,104(sp)
ffffffffc020422c:	69a6                	ld	s3,72(sp)
ffffffffc020422e:	6165                	addi	sp,sp,112
ffffffffc0204230:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204232:	e43a                	sd	a4,8(sp)
ffffffffc0204234:	cc0ff0ef          	jal	ffffffffc02036f4 <mm_create>
ffffffffc0204238:	8d2a                	mv	s10,a0
ffffffffc020423a:	c959                	beqz	a0,ffffffffc02042d0 <do_fork+0x2ce>
    if ((page = alloc_page()) == NULL)
ffffffffc020423c:	4505                	li	a0,1
ffffffffc020423e:	c55fd0ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0204242:	c541                	beqz	a0,ffffffffc02042ca <do_fork+0x2c8>
    return page - pages + nbase;
ffffffffc0204244:	000a3683          	ld	a3,0(s4)
ffffffffc0204248:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc020424a:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc020424e:	40d506b3          	sub	a3,a0,a3
ffffffffc0204252:	8699                	srai	a3,a3,0x6
ffffffffc0204254:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204256:	0196fcb3          	and	s9,a3,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc020425a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020425c:	0efcfd63          	bgeu	s9,a5,ffffffffc0204356 <do_fork+0x354>
ffffffffc0204260:	000bb783          	ld	a5,0(s7)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204264:	00097597          	auipc	a1,0x97
ffffffffc0204268:	52c5b583          	ld	a1,1324(a1) # ffffffffc029b790 <boot_pgdir_va>
ffffffffc020426c:	864e                	mv	a2,s3
ffffffffc020426e:	00f689b3          	add	s3,a3,a5
ffffffffc0204272:	854e                	mv	a0,s3
ffffffffc0204274:	504010ef          	jal	ffffffffc0205778 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204278:	038c0c93          	addi	s9,s8,56
    mm->pgdir = pgdir;
ffffffffc020427c:	013d3c23          	sd	s3,24(s10) # fffffffffff80018 <end+0x3fce4848>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204280:	4785                	li	a5,1
ffffffffc0204282:	40fcb7af          	amoor.d	a5,a5,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204286:	03f79713          	slli	a4,a5,0x3f
ffffffffc020428a:	03f75793          	srli	a5,a4,0x3f
ffffffffc020428e:	4985                	li	s3,1
ffffffffc0204290:	cb91                	beqz	a5,ffffffffc02042a4 <do_fork+0x2a2>
    {
        schedule();
ffffffffc0204292:	6d7000ef          	jal	ffffffffc0205168 <schedule>
ffffffffc0204296:	413cb7af          	amoor.d	a5,s3,(s9)
    while (!try_lock(lock))
ffffffffc020429a:	03f79713          	slli	a4,a5,0x3f
ffffffffc020429e:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042a2:	fbe5                	bnez	a5,ffffffffc0204292 <do_fork+0x290>
        ret = dup_mmap(mm, oldmm);
ffffffffc02042a4:	85e2                	mv	a1,s8
ffffffffc02042a6:	856a                	mv	a0,s10
ffffffffc02042a8:	ea8ff0ef          	jal	ffffffffc0203950 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02042ac:	57f9                	li	a5,-2
ffffffffc02042ae:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc02042b2:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02042b4:	0e078663          	beqz	a5,ffffffffc02043a0 <do_fork+0x39e>
    if ((mm = mm_create()) == NULL)
ffffffffc02042b8:	8c6a                	mv	s8,s10
    if (ret != 0)
ffffffffc02042ba:	de050ee3          	beqz	a0,ffffffffc02040b6 <do_fork+0xb4>
    exit_mmap(mm);
ffffffffc02042be:	856a                	mv	a0,s10
ffffffffc02042c0:	f28ff0ef          	jal	ffffffffc02039e8 <exit_mmap>
    put_pgdir(mm);
ffffffffc02042c4:	856a                	mv	a0,s10
ffffffffc02042c6:	c65ff0ef          	jal	ffffffffc0203f2a <put_pgdir>
    mm_destroy(mm);
ffffffffc02042ca:	856a                	mv	a0,s10
ffffffffc02042cc:	d66ff0ef          	jal	ffffffffc0203832 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02042d0:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02042d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02042d6:	08f6ec63          	bltu	a3,a5,ffffffffc020436e <do_fork+0x36c>
ffffffffc02042da:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage)
ffffffffc02042de:	000b3703          	ld	a4,0(s6)
    return pa2page(PADDR(kva));
ffffffffc02042e2:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02042e6:	83b1                	srli	a5,a5,0xc
ffffffffc02042e8:	04e7fb63          	bgeu	a5,a4,ffffffffc020433e <do_fork+0x33c>
    return &pages[PPN(pa) - nbase];
ffffffffc02042ec:	000ab703          	ld	a4,0(s5)
ffffffffc02042f0:	000a3503          	ld	a0,0(s4)
ffffffffc02042f4:	4589                	li	a1,2
ffffffffc02042f6:	8f99                	sub	a5,a5,a4
ffffffffc02042f8:	079a                	slli	a5,a5,0x6
ffffffffc02042fa:	953e                	add	a0,a0,a5
ffffffffc02042fc:	bd1fd0ef          	jal	ffffffffc0201ecc <free_pages>
}
ffffffffc0204300:	6a06                	ld	s4,64(sp)
ffffffffc0204302:	7ae2                	ld	s5,56(sp)
ffffffffc0204304:	7b42                	ld	s6,48(sp)
ffffffffc0204306:	7c02                	ld	s8,32(sp)
ffffffffc0204308:	6ce2                	ld	s9,24(sp)
    kfree(proc);
ffffffffc020430a:	8522                	mv	a0,s0
ffffffffc020430c:	a6bfd0ef          	jal	ffffffffc0201d76 <kfree>
ffffffffc0204310:	7ba2                	ld	s7,40(sp)
ffffffffc0204312:	7406                	ld	s0,96(sp)
ffffffffc0204314:	64e6                	ld	s1,88(sp)
ffffffffc0204316:	6946                	ld	s2,80(sp)
ffffffffc0204318:	6d42                	ld	s10,16(sp)
    ret = -E_NO_MEM;
ffffffffc020431a:	5571                	li	a0,-4
    return ret;
ffffffffc020431c:	b739                	j	ffffffffc020422a <do_fork+0x228>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020431e:	8936                	mv	s2,a3
ffffffffc0204320:	bbc5                	j	ffffffffc0204110 <do_fork+0x10e>
        last_pid = 1;
ffffffffc0204322:	4505                	li	a0,1
ffffffffc0204324:	00093797          	auipc	a5,0x93
ffffffffc0204328:	fea7ac23          	sw	a0,-8(a5) # ffffffffc029731c <last_pid.1>
        goto inside;
ffffffffc020432c:	b505                	j	ffffffffc020414c <do_fork+0x14a>
                    if (last_pid >= MAX_PID)
ffffffffc020432e:	6789                	lui	a5,0x2
ffffffffc0204330:	00f6c363          	blt	a3,a5,ffffffffc0204336 <do_fork+0x334>
                        last_pid = 1;
ffffffffc0204334:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204336:	4585                	li	a1,1
ffffffffc0204338:	b53d                	j	ffffffffc0204166 <do_fork+0x164>
    int ret = -E_NO_FREE_PROC;
ffffffffc020433a:	556d                	li	a0,-5
ffffffffc020433c:	b5fd                	j	ffffffffc020422a <do_fork+0x228>
        panic("pa2page called with invalid pa");
ffffffffc020433e:	00002617          	auipc	a2,0x2
ffffffffc0204342:	28a60613          	addi	a2,a2,650 # ffffffffc02065c8 <etext+0xe38>
ffffffffc0204346:	06900593          	li	a1,105
ffffffffc020434a:	00002517          	auipc	a0,0x2
ffffffffc020434e:	1d650513          	addi	a0,a0,470 # ffffffffc0206520 <etext+0xd90>
ffffffffc0204352:	8f4fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204356:	00002617          	auipc	a2,0x2
ffffffffc020435a:	1a260613          	addi	a2,a2,418 # ffffffffc02064f8 <etext+0xd68>
ffffffffc020435e:	07100593          	li	a1,113
ffffffffc0204362:	00002517          	auipc	a0,0x2
ffffffffc0204366:	1be50513          	addi	a0,a0,446 # ffffffffc0206520 <etext+0xd90>
ffffffffc020436a:	8dcfc0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020436e:	00002617          	auipc	a2,0x2
ffffffffc0204372:	23260613          	addi	a2,a2,562 # ffffffffc02065a0 <etext+0xe10>
ffffffffc0204376:	07700593          	li	a1,119
ffffffffc020437a:	00002517          	auipc	a0,0x2
ffffffffc020437e:	1a650513          	addi	a0,a0,422 # ffffffffc0206520 <etext+0xd90>
ffffffffc0204382:	8c4fc0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204386:	86be                	mv	a3,a5
ffffffffc0204388:	00002617          	auipc	a2,0x2
ffffffffc020438c:	21860613          	addi	a2,a2,536 # ffffffffc02065a0 <etext+0xe10>
ffffffffc0204390:	1a000593          	li	a1,416
ffffffffc0204394:	00003517          	auipc	a0,0x3
ffffffffc0204398:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020439c:	8aafc0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc02043a0:	00003617          	auipc	a2,0x3
ffffffffc02043a4:	ba860613          	addi	a2,a2,-1112 # ffffffffc0206f48 <etext+0x17b8>
ffffffffc02043a8:	03f00593          	li	a1,63
ffffffffc02043ac:	00003517          	auipc	a0,0x3
ffffffffc02043b0:	bac50513          	addi	a0,a0,-1108 # ffffffffc0206f58 <etext+0x17c8>
ffffffffc02043b4:	892fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02043b8 <kernel_thread>:
{
ffffffffc02043b8:	7129                	addi	sp,sp,-320
ffffffffc02043ba:	fa22                	sd	s0,304(sp)
ffffffffc02043bc:	f626                	sd	s1,296(sp)
ffffffffc02043be:	f24a                	sd	s2,288(sp)
ffffffffc02043c0:	842a                	mv	s0,a0
ffffffffc02043c2:	84ae                	mv	s1,a1
ffffffffc02043c4:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043c6:	850a                	mv	a0,sp
ffffffffc02043c8:	12000613          	li	a2,288
ffffffffc02043cc:	4581                	li	a1,0
{
ffffffffc02043ce:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043d0:	396010ef          	jal	ffffffffc0205766 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02043d4:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02043d6:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043d8:	100027f3          	csrr	a5,sstatus
ffffffffc02043dc:	edd7f793          	andi	a5,a5,-291
ffffffffc02043e0:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043e4:	860a                	mv	a2,sp
ffffffffc02043e6:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043ea:	00000717          	auipc	a4,0x0
ffffffffc02043ee:	a3a70713          	addi	a4,a4,-1478 # ffffffffc0203e24 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043f2:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043f4:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043f6:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043f8:	c0bff0ef          	jal	ffffffffc0204002 <do_fork>
}
ffffffffc02043fc:	70f2                	ld	ra,312(sp)
ffffffffc02043fe:	7452                	ld	s0,304(sp)
ffffffffc0204400:	74b2                	ld	s1,296(sp)
ffffffffc0204402:	7912                	ld	s2,288(sp)
ffffffffc0204404:	6131                	addi	sp,sp,320
ffffffffc0204406:	8082                	ret

ffffffffc0204408 <do_exit>:
{
ffffffffc0204408:	7179                	addi	sp,sp,-48
ffffffffc020440a:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc020440c:	00097417          	auipc	s0,0x97
ffffffffc0204410:	3ac40413          	addi	s0,s0,940 # ffffffffc029b7b8 <current>
ffffffffc0204414:	601c                	ld	a5,0(s0)
ffffffffc0204416:	00097717          	auipc	a4,0x97
ffffffffc020441a:	3b273703          	ld	a4,946(a4) # ffffffffc029b7c8 <idleproc>
{
ffffffffc020441e:	f406                	sd	ra,40(sp)
ffffffffc0204420:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc0204422:	0ce78b63          	beq	a5,a4,ffffffffc02044f8 <do_exit+0xf0>
    if (current == initproc)
ffffffffc0204426:	00097497          	auipc	s1,0x97
ffffffffc020442a:	39a48493          	addi	s1,s1,922 # ffffffffc029b7c0 <initproc>
ffffffffc020442e:	6098                	ld	a4,0(s1)
ffffffffc0204430:	e84a                	sd	s2,16(sp)
ffffffffc0204432:	0ee78a63          	beq	a5,a4,ffffffffc0204526 <do_exit+0x11e>
ffffffffc0204436:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc0204438:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc020443a:	c115                	beqz	a0,ffffffffc020445e <do_exit+0x56>
ffffffffc020443c:	00097797          	auipc	a5,0x97
ffffffffc0204440:	34c7b783          	ld	a5,844(a5) # ffffffffc029b788 <boot_pgdir_pa>
ffffffffc0204444:	577d                	li	a4,-1
ffffffffc0204446:	177e                	slli	a4,a4,0x3f
ffffffffc0204448:	83b1                	srli	a5,a5,0xc
ffffffffc020444a:	8fd9                	or	a5,a5,a4
ffffffffc020444c:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204450:	591c                	lw	a5,48(a0)
ffffffffc0204452:	37fd                	addiw	a5,a5,-1
ffffffffc0204454:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc0204456:	cfd5                	beqz	a5,ffffffffc0204512 <do_exit+0x10a>
        current->mm = NULL;
ffffffffc0204458:	601c                	ld	a5,0(s0)
ffffffffc020445a:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020445e:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc0204460:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204464:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204466:	100027f3          	csrr	a5,sstatus
ffffffffc020446a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020446c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020446e:	ebe1                	bnez	a5,ffffffffc020453e <do_exit+0x136>
        proc = current->parent;
ffffffffc0204470:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204472:	800007b7          	lui	a5,0x80000
ffffffffc0204476:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        proc = current->parent;
ffffffffc0204478:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020447a:	0ec52703          	lw	a4,236(a0)
ffffffffc020447e:	0cf70463          	beq	a4,a5,ffffffffc0204546 <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc0204482:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204484:	800005b7          	lui	a1,0x80000
ffffffffc0204488:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        while (current->cptr != NULL)
ffffffffc020448a:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020448c:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc020448e:	e789                	bnez	a5,ffffffffc0204498 <do_exit+0x90>
ffffffffc0204490:	a83d                	j	ffffffffc02044ce <do_exit+0xc6>
ffffffffc0204492:	6018                	ld	a4,0(s0)
ffffffffc0204494:	7b7c                	ld	a5,240(a4)
ffffffffc0204496:	cf85                	beqz	a5,ffffffffc02044ce <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204498:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020449c:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020449e:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc02044a0:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044a4:	7978                	ld	a4,240(a0)
ffffffffc02044a6:	10e7b023          	sd	a4,256(a5)
ffffffffc02044aa:	c311                	beqz	a4,ffffffffc02044ae <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc02044ac:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044ae:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02044b0:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02044b2:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044b4:	fcc71fe3          	bne	a4,a2,ffffffffc0204492 <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044b8:	0ec52783          	lw	a5,236(a0)
ffffffffc02044bc:	fcb79be3          	bne	a5,a1,ffffffffc0204492 <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc02044c0:	415000ef          	jal	ffffffffc02050d4 <wakeup_proc>
ffffffffc02044c4:	800005b7          	lui	a1,0x80000
ffffffffc02044c8:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
ffffffffc02044ca:	460d                	li	a2,3
ffffffffc02044cc:	b7d9                	j	ffffffffc0204492 <do_exit+0x8a>
    if (flag)
ffffffffc02044ce:	02091263          	bnez	s2,ffffffffc02044f2 <do_exit+0xea>
    schedule();
ffffffffc02044d2:	497000ef          	jal	ffffffffc0205168 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02044d6:	601c                	ld	a5,0(s0)
ffffffffc02044d8:	00003617          	auipc	a2,0x3
ffffffffc02044dc:	ab860613          	addi	a2,a2,-1352 # ffffffffc0206f90 <etext+0x1800>
ffffffffc02044e0:	24300593          	li	a1,579
ffffffffc02044e4:	43d4                	lw	a3,4(a5)
ffffffffc02044e6:	00003517          	auipc	a0,0x3
ffffffffc02044ea:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc02044ee:	f59fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc02044f2:	c0cfc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02044f6:	bff1                	j	ffffffffc02044d2 <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc02044f8:	00003617          	auipc	a2,0x3
ffffffffc02044fc:	a7860613          	addi	a2,a2,-1416 # ffffffffc0206f70 <etext+0x17e0>
ffffffffc0204500:	20f00593          	li	a1,527
ffffffffc0204504:	00003517          	auipc	a0,0x3
ffffffffc0204508:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020450c:	e84a                	sd	s2,16(sp)
ffffffffc020450e:	f39fb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc0204512:	e42a                	sd	a0,8(sp)
ffffffffc0204514:	cd4ff0ef          	jal	ffffffffc02039e8 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204518:	6522                	ld	a0,8(sp)
ffffffffc020451a:	a11ff0ef          	jal	ffffffffc0203f2a <put_pgdir>
            mm_destroy(mm);
ffffffffc020451e:	6522                	ld	a0,8(sp)
ffffffffc0204520:	b12ff0ef          	jal	ffffffffc0203832 <mm_destroy>
ffffffffc0204524:	bf15                	j	ffffffffc0204458 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc0204526:	00003617          	auipc	a2,0x3
ffffffffc020452a:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0206f80 <etext+0x17f0>
ffffffffc020452e:	21300593          	li	a1,531
ffffffffc0204532:	00003517          	auipc	a0,0x3
ffffffffc0204536:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020453a:	f0dfb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc020453e:	bc6fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204542:	4905                	li	s2,1
ffffffffc0204544:	b735                	j	ffffffffc0204470 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc0204546:	38f000ef          	jal	ffffffffc02050d4 <wakeup_proc>
ffffffffc020454a:	bf25                	j	ffffffffc0204482 <do_exit+0x7a>

ffffffffc020454c <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc020454c:	7179                	addi	sp,sp,-48
ffffffffc020454e:	ec26                	sd	s1,24(sp)
ffffffffc0204550:	e84a                	sd	s2,16(sp)
ffffffffc0204552:	e44e                	sd	s3,8(sp)
ffffffffc0204554:	f406                	sd	ra,40(sp)
ffffffffc0204556:	f022                	sd	s0,32(sp)
ffffffffc0204558:	84aa                	mv	s1,a0
ffffffffc020455a:	892e                	mv	s2,a1
ffffffffc020455c:	00097997          	auipc	s3,0x97
ffffffffc0204560:	25c98993          	addi	s3,s3,604 # ffffffffc029b7b8 <current>
    if (pid != 0)
ffffffffc0204564:	cd19                	beqz	a0,ffffffffc0204582 <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204566:	6789                	lui	a5,0x2
ffffffffc0204568:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc020456a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020456e:	12e7f563          	bgeu	a5,a4,ffffffffc0204698 <do_wait.part.0+0x14c>
}
ffffffffc0204572:	70a2                	ld	ra,40(sp)
ffffffffc0204574:	7402                	ld	s0,32(sp)
ffffffffc0204576:	64e2                	ld	s1,24(sp)
ffffffffc0204578:	6942                	ld	s2,16(sp)
ffffffffc020457a:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc020457c:	5579                	li	a0,-2
}
ffffffffc020457e:	6145                	addi	sp,sp,48
ffffffffc0204580:	8082                	ret
        proc = current->cptr;
ffffffffc0204582:	0009b703          	ld	a4,0(s3)
ffffffffc0204586:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204588:	d46d                	beqz	s0,ffffffffc0204572 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020458a:	468d                	li	a3,3
ffffffffc020458c:	a021                	j	ffffffffc0204594 <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020458e:	10043403          	ld	s0,256(s0)
ffffffffc0204592:	c075                	beqz	s0,ffffffffc0204676 <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204594:	401c                	lw	a5,0(s0)
ffffffffc0204596:	fed79ce3          	bne	a5,a3,ffffffffc020458e <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc020459a:	00097797          	auipc	a5,0x97
ffffffffc020459e:	22e7b783          	ld	a5,558(a5) # ffffffffc029b7c8 <idleproc>
ffffffffc02045a2:	14878263          	beq	a5,s0,ffffffffc02046e6 <do_wait.part.0+0x19a>
ffffffffc02045a6:	00097797          	auipc	a5,0x97
ffffffffc02045aa:	21a7b783          	ld	a5,538(a5) # ffffffffc029b7c0 <initproc>
ffffffffc02045ae:	12f40c63          	beq	s0,a5,ffffffffc02046e6 <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc02045b2:	00090663          	beqz	s2,ffffffffc02045be <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc02045b6:	0e842783          	lw	a5,232(s0)
ffffffffc02045ba:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045be:	100027f3          	csrr	a5,sstatus
ffffffffc02045c2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045c4:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045c6:	10079963          	bnez	a5,ffffffffc02046d8 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02045ca:	6c74                	ld	a3,216(s0)
ffffffffc02045cc:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc02045ce:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc02045d2:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02045d4:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02045d6:	6474                	ld	a3,200(s0)
ffffffffc02045d8:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc02045da:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02045dc:	e314                	sd	a3,0(a4)
ffffffffc02045de:	c789                	beqz	a5,ffffffffc02045e8 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc02045e0:	7c78                	ld	a4,248(s0)
ffffffffc02045e2:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc02045e4:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc02045e8:	7c78                	ld	a4,248(s0)
ffffffffc02045ea:	c36d                	beqz	a4,ffffffffc02046cc <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc02045ec:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc02045f0:	00097797          	auipc	a5,0x97
ffffffffc02045f4:	1c07a783          	lw	a5,448(a5) # ffffffffc029b7b0 <nr_process>
ffffffffc02045f8:	37fd                	addiw	a5,a5,-1
ffffffffc02045fa:	00097717          	auipc	a4,0x97
ffffffffc02045fe:	1af72b23          	sw	a5,438(a4) # ffffffffc029b7b0 <nr_process>
    if (flag)
ffffffffc0204602:	e271                	bnez	a2,ffffffffc02046c6 <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204604:	6814                	ld	a3,16(s0)
ffffffffc0204606:	c02007b7          	lui	a5,0xc0200
ffffffffc020460a:	10f6e663          	bltu	a3,a5,ffffffffc0204716 <do_wait.part.0+0x1ca>
ffffffffc020460e:	00097717          	auipc	a4,0x97
ffffffffc0204612:	18a73703          	ld	a4,394(a4) # ffffffffc029b798 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0204616:	00097797          	auipc	a5,0x97
ffffffffc020461a:	18a7b783          	ld	a5,394(a5) # ffffffffc029b7a0 <npage>
    return pa2page(PADDR(kva));
ffffffffc020461e:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0204620:	82b1                	srli	a3,a3,0xc
ffffffffc0204622:	0cf6fe63          	bgeu	a3,a5,ffffffffc02046fe <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc0204626:	00003797          	auipc	a5,0x3
ffffffffc020462a:	2927b783          	ld	a5,658(a5) # ffffffffc02078b8 <nbase>
ffffffffc020462e:	00097517          	auipc	a0,0x97
ffffffffc0204632:	17a53503          	ld	a0,378(a0) # ffffffffc029b7a8 <pages>
ffffffffc0204636:	4589                	li	a1,2
ffffffffc0204638:	8e9d                	sub	a3,a3,a5
ffffffffc020463a:	069a                	slli	a3,a3,0x6
ffffffffc020463c:	9536                	add	a0,a0,a3
ffffffffc020463e:	88ffd0ef          	jal	ffffffffc0201ecc <free_pages>
    kfree(proc);
ffffffffc0204642:	8522                	mv	a0,s0
ffffffffc0204644:	f32fd0ef          	jal	ffffffffc0201d76 <kfree>
}
ffffffffc0204648:	70a2                	ld	ra,40(sp)
ffffffffc020464a:	7402                	ld	s0,32(sp)
ffffffffc020464c:	64e2                	ld	s1,24(sp)
ffffffffc020464e:	6942                	ld	s2,16(sp)
ffffffffc0204650:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc0204652:	4501                	li	a0,0
}
ffffffffc0204654:	6145                	addi	sp,sp,48
ffffffffc0204656:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204658:	00097997          	auipc	s3,0x97
ffffffffc020465c:	16098993          	addi	s3,s3,352 # ffffffffc029b7b8 <current>
ffffffffc0204660:	0009b703          	ld	a4,0(s3)
ffffffffc0204664:	f487b683          	ld	a3,-184(a5)
ffffffffc0204668:	f0e695e3          	bne	a3,a4,ffffffffc0204572 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020466c:	f287a603          	lw	a2,-216(a5)
ffffffffc0204670:	468d                	li	a3,3
ffffffffc0204672:	06d60063          	beq	a2,a3,ffffffffc02046d2 <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc0204676:	800007b7          	lui	a5,0x80000
ffffffffc020467a:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e29>
        current->state = PROC_SLEEPING;
ffffffffc020467c:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc020467e:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc0204682:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc0204684:	2e5000ef          	jal	ffffffffc0205168 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204688:	0009b783          	ld	a5,0(s3)
ffffffffc020468c:	0b07a783          	lw	a5,176(a5)
ffffffffc0204690:	8b85                	andi	a5,a5,1
ffffffffc0204692:	e7b9                	bnez	a5,ffffffffc02046e0 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc0204694:	ee0487e3          	beqz	s1,ffffffffc0204582 <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204698:	45a9                	li	a1,10
ffffffffc020469a:	8526                	mv	a0,s1
ffffffffc020469c:	435000ef          	jal	ffffffffc02052d0 <hash32>
ffffffffc02046a0:	02051793          	slli	a5,a0,0x20
ffffffffc02046a4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02046a8:	00093797          	auipc	a5,0x93
ffffffffc02046ac:	09078793          	addi	a5,a5,144 # ffffffffc0297738 <hash_list>
ffffffffc02046b0:	953e                	add	a0,a0,a5
ffffffffc02046b2:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc02046b4:	a029                	j	ffffffffc02046be <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc02046b6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02046ba:	f8970fe3          	beq	a4,s1,ffffffffc0204658 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc02046be:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02046c0:	fef51be3          	bne	a0,a5,ffffffffc02046b6 <do_wait.part.0+0x16a>
ffffffffc02046c4:	b57d                	j	ffffffffc0204572 <do_wait.part.0+0x26>
        intr_enable();
ffffffffc02046c6:	a38fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02046ca:	bf2d                	j	ffffffffc0204604 <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc02046cc:	7018                	ld	a4,32(s0)
ffffffffc02046ce:	fb7c                	sd	a5,240(a4)
ffffffffc02046d0:	b705                	j	ffffffffc02045f0 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02046d2:	f2878413          	addi	s0,a5,-216
ffffffffc02046d6:	b5d1                	j	ffffffffc020459a <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc02046d8:	a2cfc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02046dc:	4605                	li	a2,1
ffffffffc02046de:	b5f5                	j	ffffffffc02045ca <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc02046e0:	555d                	li	a0,-9
ffffffffc02046e2:	d27ff0ef          	jal	ffffffffc0204408 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc02046e6:	00003617          	auipc	a2,0x3
ffffffffc02046ea:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0206fb0 <etext+0x1820>
ffffffffc02046ee:	36600593          	li	a1,870
ffffffffc02046f2:	00003517          	auipc	a0,0x3
ffffffffc02046f6:	83e50513          	addi	a0,a0,-1986 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc02046fa:	d4dfb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02046fe:	00002617          	auipc	a2,0x2
ffffffffc0204702:	eca60613          	addi	a2,a2,-310 # ffffffffc02065c8 <etext+0xe38>
ffffffffc0204706:	06900593          	li	a1,105
ffffffffc020470a:	00002517          	auipc	a0,0x2
ffffffffc020470e:	e1650513          	addi	a0,a0,-490 # ffffffffc0206520 <etext+0xd90>
ffffffffc0204712:	d35fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204716:	00002617          	auipc	a2,0x2
ffffffffc020471a:	e8a60613          	addi	a2,a2,-374 # ffffffffc02065a0 <etext+0xe10>
ffffffffc020471e:	07700593          	li	a1,119
ffffffffc0204722:	00002517          	auipc	a0,0x2
ffffffffc0204726:	dfe50513          	addi	a0,a0,-514 # ffffffffc0206520 <etext+0xd90>
ffffffffc020472a:	d1dfb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020472e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020472e:	1141                	addi	sp,sp,-16
ffffffffc0204730:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204732:	fd2fd0ef          	jal	ffffffffc0201f04 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204736:	d96fd0ef          	jal	ffffffffc0201ccc <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020473a:	4601                	li	a2,0
ffffffffc020473c:	4581                	li	a1,0
ffffffffc020473e:	fffff517          	auipc	a0,0xfffff
ffffffffc0204742:	76e50513          	addi	a0,a0,1902 # ffffffffc0203eac <user_main>
ffffffffc0204746:	c73ff0ef          	jal	ffffffffc02043b8 <kernel_thread>
    if (pid <= 0)
ffffffffc020474a:	00a04563          	bgtz	a0,ffffffffc0204754 <init_main+0x26>
ffffffffc020474e:	a071                	j	ffffffffc02047da <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204750:	219000ef          	jal	ffffffffc0205168 <schedule>
    if (code_store != NULL)
ffffffffc0204754:	4581                	li	a1,0
ffffffffc0204756:	4501                	li	a0,0
ffffffffc0204758:	df5ff0ef          	jal	ffffffffc020454c <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc020475c:	d975                	beqz	a0,ffffffffc0204750 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020475e:	00003517          	auipc	a0,0x3
ffffffffc0204762:	89250513          	addi	a0,a0,-1902 # ffffffffc0206ff0 <etext+0x1860>
ffffffffc0204766:	a2ffb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020476a:	00097797          	auipc	a5,0x97
ffffffffc020476e:	0567b783          	ld	a5,86(a5) # ffffffffc029b7c0 <initproc>
ffffffffc0204772:	7bf8                	ld	a4,240(a5)
ffffffffc0204774:	e339                	bnez	a4,ffffffffc02047ba <init_main+0x8c>
ffffffffc0204776:	7ff8                	ld	a4,248(a5)
ffffffffc0204778:	e329                	bnez	a4,ffffffffc02047ba <init_main+0x8c>
ffffffffc020477a:	1007b703          	ld	a4,256(a5)
ffffffffc020477e:	ef15                	bnez	a4,ffffffffc02047ba <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204780:	00097697          	auipc	a3,0x97
ffffffffc0204784:	0306a683          	lw	a3,48(a3) # ffffffffc029b7b0 <nr_process>
ffffffffc0204788:	4709                	li	a4,2
ffffffffc020478a:	0ae69463          	bne	a3,a4,ffffffffc0204832 <init_main+0x104>
ffffffffc020478e:	00097697          	auipc	a3,0x97
ffffffffc0204792:	faa68693          	addi	a3,a3,-86 # ffffffffc029b738 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204796:	6698                	ld	a4,8(a3)
ffffffffc0204798:	0c878793          	addi	a5,a5,200
ffffffffc020479c:	06f71b63          	bne	a4,a5,ffffffffc0204812 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047a0:	629c                	ld	a5,0(a3)
ffffffffc02047a2:	04f71863          	bne	a4,a5,ffffffffc02047f2 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02047a6:	00003517          	auipc	a0,0x3
ffffffffc02047aa:	93250513          	addi	a0,a0,-1742 # ffffffffc02070d8 <etext+0x1948>
ffffffffc02047ae:	9e7fb0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02047b2:	60a2                	ld	ra,8(sp)
ffffffffc02047b4:	4501                	li	a0,0
ffffffffc02047b6:	0141                	addi	sp,sp,16
ffffffffc02047b8:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02047ba:	00003697          	auipc	a3,0x3
ffffffffc02047be:	85e68693          	addi	a3,a3,-1954 # ffffffffc0207018 <etext+0x1888>
ffffffffc02047c2:	00002617          	auipc	a2,0x2
ffffffffc02047c6:	98660613          	addi	a2,a2,-1658 # ffffffffc0206148 <etext+0x9b8>
ffffffffc02047ca:	3d400593          	li	a1,980
ffffffffc02047ce:	00002517          	auipc	a0,0x2
ffffffffc02047d2:	76250513          	addi	a0,a0,1890 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc02047d6:	c71fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc02047da:	00002617          	auipc	a2,0x2
ffffffffc02047de:	7f660613          	addi	a2,a2,2038 # ffffffffc0206fd0 <etext+0x1840>
ffffffffc02047e2:	3cb00593          	li	a1,971
ffffffffc02047e6:	00002517          	auipc	a0,0x2
ffffffffc02047ea:	74a50513          	addi	a0,a0,1866 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc02047ee:	c59fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047f2:	00003697          	auipc	a3,0x3
ffffffffc02047f6:	8b668693          	addi	a3,a3,-1866 # ffffffffc02070a8 <etext+0x1918>
ffffffffc02047fa:	00002617          	auipc	a2,0x2
ffffffffc02047fe:	94e60613          	addi	a2,a2,-1714 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204802:	3d700593          	li	a1,983
ffffffffc0204806:	00002517          	auipc	a0,0x2
ffffffffc020480a:	72a50513          	addi	a0,a0,1834 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020480e:	c39fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204812:	00003697          	auipc	a3,0x3
ffffffffc0204816:	86668693          	addi	a3,a3,-1946 # ffffffffc0207078 <etext+0x18e8>
ffffffffc020481a:	00002617          	auipc	a2,0x2
ffffffffc020481e:	92e60613          	addi	a2,a2,-1746 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204822:	3d600593          	li	a1,982
ffffffffc0204826:	00002517          	auipc	a0,0x2
ffffffffc020482a:	70a50513          	addi	a0,a0,1802 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020482e:	c19fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc0204832:	00003697          	auipc	a3,0x3
ffffffffc0204836:	83668693          	addi	a3,a3,-1994 # ffffffffc0207068 <etext+0x18d8>
ffffffffc020483a:	00002617          	auipc	a2,0x2
ffffffffc020483e:	90e60613          	addi	a2,a2,-1778 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204842:	3d500593          	li	a1,981
ffffffffc0204846:	00002517          	auipc	a0,0x2
ffffffffc020484a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020484e:	bf9fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204852 <do_execve>:
{
ffffffffc0204852:	7171                	addi	sp,sp,-176
ffffffffc0204854:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204856:	00097d17          	auipc	s10,0x97
ffffffffc020485a:	f62d0d13          	addi	s10,s10,-158 # ffffffffc029b7b8 <current>
ffffffffc020485e:	000d3783          	ld	a5,0(s10)
{
ffffffffc0204862:	e94a                	sd	s2,144(sp)
ffffffffc0204864:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204866:	0287b903          	ld	s2,40(a5)
{
ffffffffc020486a:	84ae                	mv	s1,a1
ffffffffc020486c:	e54e                	sd	s3,136(sp)
ffffffffc020486e:	ec32                	sd	a2,24(sp)
ffffffffc0204870:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204872:	85aa                	mv	a1,a0
ffffffffc0204874:	8626                	mv	a2,s1
ffffffffc0204876:	854a                	mv	a0,s2
ffffffffc0204878:	4681                	li	a3,0
{
ffffffffc020487a:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020487c:	d04ff0ef          	jal	ffffffffc0203d80 <user_mem_check>
ffffffffc0204880:	46050f63          	beqz	a0,ffffffffc0204cfe <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204884:	4641                	li	a2,16
ffffffffc0204886:	1808                	addi	a0,sp,48
ffffffffc0204888:	4581                	li	a1,0
ffffffffc020488a:	6dd000ef          	jal	ffffffffc0205766 <memset>
    if (len > PROC_NAME_LEN)
ffffffffc020488e:	47bd                	li	a5,15
ffffffffc0204890:	8626                	mv	a2,s1
ffffffffc0204892:	0e97ef63          	bltu	a5,s1,ffffffffc0204990 <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc0204896:	85ce                	mv	a1,s3
ffffffffc0204898:	1808                	addi	a0,sp,48
ffffffffc020489a:	6df000ef          	jal	ffffffffc0205778 <memcpy>
    if (mm != NULL)
ffffffffc020489e:	10090063          	beqz	s2,ffffffffc020499e <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc02048a2:	00002517          	auipc	a0,0x2
ffffffffc02048a6:	44e50513          	addi	a0,a0,1102 # ffffffffc0206cf0 <etext+0x1560>
ffffffffc02048aa:	921fb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc02048ae:	00097797          	auipc	a5,0x97
ffffffffc02048b2:	eda7b783          	ld	a5,-294(a5) # ffffffffc029b788 <boot_pgdir_pa>
ffffffffc02048b6:	577d                	li	a4,-1
ffffffffc02048b8:	177e                	slli	a4,a4,0x3f
ffffffffc02048ba:	83b1                	srli	a5,a5,0xc
ffffffffc02048bc:	8fd9                	or	a5,a5,a4
ffffffffc02048be:	18079073          	csrw	satp,a5
ffffffffc02048c2:	03092783          	lw	a5,48(s2)
ffffffffc02048c6:	37fd                	addiw	a5,a5,-1
ffffffffc02048c8:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc02048cc:	30078563          	beqz	a5,ffffffffc0204bd6 <do_execve+0x384>
        current->mm = NULL;
ffffffffc02048d0:	000d3783          	ld	a5,0(s10)
ffffffffc02048d4:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02048d8:	e1dfe0ef          	jal	ffffffffc02036f4 <mm_create>
ffffffffc02048dc:	892a                	mv	s2,a0
ffffffffc02048de:	22050063          	beqz	a0,ffffffffc0204afe <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc02048e2:	4505                	li	a0,1
ffffffffc02048e4:	daefd0ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02048e8:	42050063          	beqz	a0,ffffffffc0204d08 <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc02048ec:	f0e2                	sd	s8,96(sp)
ffffffffc02048ee:	00097c17          	auipc	s8,0x97
ffffffffc02048f2:	ebac0c13          	addi	s8,s8,-326 # ffffffffc029b7a8 <pages>
ffffffffc02048f6:	000c3783          	ld	a5,0(s8)
ffffffffc02048fa:	f4de                	sd	s7,104(sp)
ffffffffc02048fc:	00003b97          	auipc	s7,0x3
ffffffffc0204900:	fbcbbb83          	ld	s7,-68(s7) # ffffffffc02078b8 <nbase>
ffffffffc0204904:	40f506b3          	sub	a3,a0,a5
ffffffffc0204908:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc020490a:	00097c97          	auipc	s9,0x97
ffffffffc020490e:	e96c8c93          	addi	s9,s9,-362 # ffffffffc029b7a0 <npage>
ffffffffc0204912:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc0204914:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204916:	5b7d                	li	s6,-1
ffffffffc0204918:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc020491c:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc020491e:	00cb5713          	srli	a4,s6,0xc
ffffffffc0204922:	e83a                	sd	a4,16(sp)
ffffffffc0204924:	fcd6                	sd	s5,120(sp)
ffffffffc0204926:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204928:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020492a:	40f77263          	bgeu	a4,a5,ffffffffc0204d2e <do_execve+0x4dc>
ffffffffc020492e:	00097a97          	auipc	s5,0x97
ffffffffc0204932:	e6aa8a93          	addi	s5,s5,-406 # ffffffffc029b798 <va_pa_offset>
ffffffffc0204936:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020493a:	00097597          	auipc	a1,0x97
ffffffffc020493e:	e565b583          	ld	a1,-426(a1) # ffffffffc029b790 <boot_pgdir_va>
ffffffffc0204942:	6605                	lui	a2,0x1
ffffffffc0204944:	00f684b3          	add	s1,a3,a5
ffffffffc0204948:	8526                	mv	a0,s1
ffffffffc020494a:	62f000ef          	jal	ffffffffc0205778 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020494e:	66e2                	ld	a3,24(sp)
ffffffffc0204950:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204954:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204958:	4298                	lw	a4,0(a3)
ffffffffc020495a:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464ba3a7>
ffffffffc020495e:	06f70863          	beq	a4,a5,ffffffffc02049ce <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc0204962:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc0204964:	854a                	mv	a0,s2
ffffffffc0204966:	dc4ff0ef          	jal	ffffffffc0203f2a <put_pgdir>
ffffffffc020496a:	7ae6                	ld	s5,120(sp)
ffffffffc020496c:	7b46                	ld	s6,112(sp)
ffffffffc020496e:	7ba6                	ld	s7,104(sp)
ffffffffc0204970:	7c06                	ld	s8,96(sp)
ffffffffc0204972:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204974:	854a                	mv	a0,s2
ffffffffc0204976:	ebdfe0ef          	jal	ffffffffc0203832 <mm_destroy>
    do_exit(ret);
ffffffffc020497a:	8526                	mv	a0,s1
ffffffffc020497c:	f122                	sd	s0,160(sp)
ffffffffc020497e:	e152                	sd	s4,128(sp)
ffffffffc0204980:	fcd6                	sd	s5,120(sp)
ffffffffc0204982:	f8da                	sd	s6,112(sp)
ffffffffc0204984:	f4de                	sd	s7,104(sp)
ffffffffc0204986:	f0e2                	sd	s8,96(sp)
ffffffffc0204988:	ece6                	sd	s9,88(sp)
ffffffffc020498a:	e4ee                	sd	s11,72(sp)
ffffffffc020498c:	a7dff0ef          	jal	ffffffffc0204408 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204990:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204992:	85ce                	mv	a1,s3
ffffffffc0204994:	1808                	addi	a0,sp,48
ffffffffc0204996:	5e3000ef          	jal	ffffffffc0205778 <memcpy>
    if (mm != NULL)
ffffffffc020499a:	f00914e3          	bnez	s2,ffffffffc02048a2 <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc020499e:	000d3783          	ld	a5,0(s10)
ffffffffc02049a2:	779c                	ld	a5,40(a5)
ffffffffc02049a4:	db95                	beqz	a5,ffffffffc02048d8 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02049a6:	00002617          	auipc	a2,0x2
ffffffffc02049aa:	75260613          	addi	a2,a2,1874 # ffffffffc02070f8 <etext+0x1968>
ffffffffc02049ae:	24f00593          	li	a1,591
ffffffffc02049b2:	00002517          	auipc	a0,0x2
ffffffffc02049b6:	57e50513          	addi	a0,a0,1406 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc02049ba:	f122                	sd	s0,160(sp)
ffffffffc02049bc:	e152                	sd	s4,128(sp)
ffffffffc02049be:	fcd6                	sd	s5,120(sp)
ffffffffc02049c0:	f8da                	sd	s6,112(sp)
ffffffffc02049c2:	f4de                	sd	s7,104(sp)
ffffffffc02049c4:	f0e2                	sd	s8,96(sp)
ffffffffc02049c6:	ece6                	sd	s9,88(sp)
ffffffffc02049c8:	e4ee                	sd	s11,72(sp)
ffffffffc02049ca:	a7dfb0ef          	jal	ffffffffc0200446 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049ce:	0386d703          	lhu	a4,56(a3)
ffffffffc02049d2:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02049d4:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049d8:	00371793          	slli	a5,a4,0x3
ffffffffc02049dc:	8f99                	sub	a5,a5,a4
ffffffffc02049de:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02049e0:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049e2:	97d2                	add	a5,a5,s4
ffffffffc02049e4:	f122                	sd	s0,160(sp)
ffffffffc02049e6:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02049e8:	00fa7e63          	bgeu	s4,a5,ffffffffc0204a04 <do_execve+0x1b2>
ffffffffc02049ec:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02049ee:	000a2783          	lw	a5,0(s4)
ffffffffc02049f2:	4705                	li	a4,1
ffffffffc02049f4:	10e78763          	beq	a5,a4,ffffffffc0204b02 <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc02049f8:	77a2                	ld	a5,40(sp)
ffffffffc02049fa:	038a0a13          	addi	s4,s4,56
ffffffffc02049fe:	fefa68e3          	bltu	s4,a5,ffffffffc02049ee <do_execve+0x19c>
ffffffffc0204a02:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204a04:	4701                	li	a4,0
ffffffffc0204a06:	46ad                	li	a3,11
ffffffffc0204a08:	00100637          	lui	a2,0x100
ffffffffc0204a0c:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204a10:	854a                	mv	a0,s2
ffffffffc0204a12:	e73fe0ef          	jal	ffffffffc0203884 <mm_map>
ffffffffc0204a16:	84aa                	mv	s1,a0
ffffffffc0204a18:	1a051963          	bnez	a0,ffffffffc0204bca <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204a1c:	01893503          	ld	a0,24(s2)
ffffffffc0204a20:	467d                	li	a2,31
ffffffffc0204a22:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204a26:	bedfe0ef          	jal	ffffffffc0203612 <pgdir_alloc_page>
ffffffffc0204a2a:	3a050163          	beqz	a0,ffffffffc0204dcc <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a2e:	01893503          	ld	a0,24(s2)
ffffffffc0204a32:	467d                	li	a2,31
ffffffffc0204a34:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204a38:	bdbfe0ef          	jal	ffffffffc0203612 <pgdir_alloc_page>
ffffffffc0204a3c:	36050763          	beqz	a0,ffffffffc0204daa <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a40:	01893503          	ld	a0,24(s2)
ffffffffc0204a44:	467d                	li	a2,31
ffffffffc0204a46:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204a4a:	bc9fe0ef          	jal	ffffffffc0203612 <pgdir_alloc_page>
ffffffffc0204a4e:	32050d63          	beqz	a0,ffffffffc0204d88 <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a52:	01893503          	ld	a0,24(s2)
ffffffffc0204a56:	467d                	li	a2,31
ffffffffc0204a58:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204a5c:	bb7fe0ef          	jal	ffffffffc0203612 <pgdir_alloc_page>
ffffffffc0204a60:	30050363          	beqz	a0,ffffffffc0204d66 <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc0204a64:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204a68:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a6c:	01893683          	ld	a3,24(s2)
ffffffffc0204a70:	2785                	addiw	a5,a5,1
ffffffffc0204a72:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204a76:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5e50>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a7a:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a7e:	2cf6e763          	bltu	a3,a5,ffffffffc0204d4c <do_execve+0x4fa>
ffffffffc0204a82:	000ab783          	ld	a5,0(s5)
ffffffffc0204a86:	577d                	li	a4,-1
ffffffffc0204a88:	177e                	slli	a4,a4,0x3f
ffffffffc0204a8a:	8e9d                	sub	a3,a3,a5
ffffffffc0204a8c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204a90:	f654                	sd	a3,168(a2)
ffffffffc0204a92:	8fd9                	or	a5,a5,a4
ffffffffc0204a94:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204a98:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a9a:	4581                	li	a1,0
ffffffffc0204a9c:	12000613          	li	a2,288
ffffffffc0204aa0:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204aa2:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204aa6:	4c1000ef          	jal	ffffffffc0205766 <memset>
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204aaa:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204aac:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204ab0:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204ab4:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;              // user stack top
ffffffffc0204ab6:	4785                	li	a5,1
ffffffffc0204ab8:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204aba:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;              // entry point of the ELF
ffffffffc0204abe:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;              // user stack top
ffffffffc0204ac2:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204ac4:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ac8:	4641                	li	a2,16
ffffffffc0204aca:	4581                	li	a1,0
ffffffffc0204acc:	0b498513          	addi	a0,s3,180
ffffffffc0204ad0:	497000ef          	jal	ffffffffc0205766 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ad4:	180c                	addi	a1,sp,48
ffffffffc0204ad6:	0b498513          	addi	a0,s3,180
ffffffffc0204ada:	463d                	li	a2,15
ffffffffc0204adc:	49d000ef          	jal	ffffffffc0205778 <memcpy>
ffffffffc0204ae0:	740a                	ld	s0,160(sp)
ffffffffc0204ae2:	6a0a                	ld	s4,128(sp)
ffffffffc0204ae4:	7ae6                	ld	s5,120(sp)
ffffffffc0204ae6:	7b46                	ld	s6,112(sp)
ffffffffc0204ae8:	7ba6                	ld	s7,104(sp)
ffffffffc0204aea:	7c06                	ld	s8,96(sp)
ffffffffc0204aec:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204aee:	70aa                	ld	ra,168(sp)
ffffffffc0204af0:	694a                	ld	s2,144(sp)
ffffffffc0204af2:	69aa                	ld	s3,136(sp)
ffffffffc0204af4:	6d46                	ld	s10,80(sp)
ffffffffc0204af6:	8526                	mv	a0,s1
ffffffffc0204af8:	64ea                	ld	s1,152(sp)
ffffffffc0204afa:	614d                	addi	sp,sp,176
ffffffffc0204afc:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204afe:	54f1                	li	s1,-4
ffffffffc0204b00:	bdad                	j	ffffffffc020497a <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204b02:	028a3603          	ld	a2,40(s4)
ffffffffc0204b06:	020a3783          	ld	a5,32(s4)
ffffffffc0204b0a:	20f66363          	bltu	a2,a5,ffffffffc0204d10 <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b0e:	004a2783          	lw	a5,4(s4)
ffffffffc0204b12:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b16:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b1a:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b1c:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b1e:	c6f1                	beqz	a3,ffffffffc0204bea <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b20:	1c079763          	bnez	a5,ffffffffc0204cee <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b24:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204b26:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204b2a:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204b2c:	c709                	beqz	a4,ffffffffc0204b36 <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc0204b2e:	67a2                	ld	a5,8(sp)
ffffffffc0204b30:	0087e793          	ori	a5,a5,8
ffffffffc0204b34:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204b36:	010a3583          	ld	a1,16(s4)
ffffffffc0204b3a:	4701                	li	a4,0
ffffffffc0204b3c:	854a                	mv	a0,s2
ffffffffc0204b3e:	d47fe0ef          	jal	ffffffffc0203884 <mm_map>
ffffffffc0204b42:	84aa                	mv	s1,a0
ffffffffc0204b44:	1c051463          	bnez	a0,ffffffffc0204d0c <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b48:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b4c:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b50:	77fd                	lui	a5,0xfffff
ffffffffc0204b52:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b56:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204b58:	1a9b7563          	bgeu	s6,s1,ffffffffc0204d02 <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b5c:	008a3983          	ld	s3,8(s4)
ffffffffc0204b60:	67e2                	ld	a5,24(sp)
ffffffffc0204b62:	99be                	add	s3,s3,a5
ffffffffc0204b64:	a881                	j	ffffffffc0204bb4 <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b66:	6785                	lui	a5,0x1
ffffffffc0204b68:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204b6c:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204b70:	01b4e463          	bltu	s1,s11,ffffffffc0204b78 <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b74:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204b78:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204b7c:	67c2                	ld	a5,16(sp)
ffffffffc0204b7e:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204b82:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b86:	8699                	srai	a3,a3,0x6
ffffffffc0204b88:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204b8a:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b8e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b90:	18a87363          	bgeu	a6,a0,ffffffffc0204d16 <do_execve+0x4c4>
ffffffffc0204b94:	000ab503          	ld	a0,0(s5)
ffffffffc0204b98:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b9c:	e032                	sd	a2,0(sp)
ffffffffc0204b9e:	9536                	add	a0,a0,a3
ffffffffc0204ba0:	952e                	add	a0,a0,a1
ffffffffc0204ba2:	85ce                	mv	a1,s3
ffffffffc0204ba4:	3d5000ef          	jal	ffffffffc0205778 <memcpy>
            start += size, from += size;
ffffffffc0204ba8:	6602                	ld	a2,0(sp)
ffffffffc0204baa:	9b32                	add	s6,s6,a2
ffffffffc0204bac:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204bae:	049b7563          	bgeu	s6,s1,ffffffffc0204bf8 <do_execve+0x3a6>
ffffffffc0204bb2:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204bb4:	01893503          	ld	a0,24(s2)
ffffffffc0204bb8:	6622                	ld	a2,8(sp)
ffffffffc0204bba:	e02e                	sd	a1,0(sp)
ffffffffc0204bbc:	a57fe0ef          	jal	ffffffffc0203612 <pgdir_alloc_page>
ffffffffc0204bc0:	6582                	ld	a1,0(sp)
ffffffffc0204bc2:	842a                	mv	s0,a0
ffffffffc0204bc4:	f14d                	bnez	a0,ffffffffc0204b66 <do_execve+0x314>
ffffffffc0204bc6:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204bc8:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204bca:	854a                	mv	a0,s2
ffffffffc0204bcc:	e1dfe0ef          	jal	ffffffffc02039e8 <exit_mmap>
ffffffffc0204bd0:	740a                	ld	s0,160(sp)
ffffffffc0204bd2:	6a0a                	ld	s4,128(sp)
ffffffffc0204bd4:	bb41                	j	ffffffffc0204964 <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204bd6:	854a                	mv	a0,s2
ffffffffc0204bd8:	e11fe0ef          	jal	ffffffffc02039e8 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204bdc:	854a                	mv	a0,s2
ffffffffc0204bde:	b4cff0ef          	jal	ffffffffc0203f2a <put_pgdir>
            mm_destroy(mm);
ffffffffc0204be2:	854a                	mv	a0,s2
ffffffffc0204be4:	c4ffe0ef          	jal	ffffffffc0203832 <mm_destroy>
ffffffffc0204be8:	b1e5                	j	ffffffffc02048d0 <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bea:	0e078e63          	beqz	a5,ffffffffc0204ce6 <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204bee:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204bf0:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204bf4:	e43e                	sd	a5,8(sp)
ffffffffc0204bf6:	bf1d                	j	ffffffffc0204b2c <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204bf8:	010a3483          	ld	s1,16(s4)
ffffffffc0204bfc:	028a3683          	ld	a3,40(s4)
ffffffffc0204c00:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204c02:	07bb7c63          	bgeu	s6,s11,ffffffffc0204c7a <do_execve+0x428>
            if (start == end)
ffffffffc0204c06:	df6489e3          	beq	s1,s6,ffffffffc02049f8 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204c0a:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204c0e:	0fb4f563          	bgeu	s1,s11,ffffffffc0204cf8 <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204c12:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c16:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204c1a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c1e:	8699                	srai	a3,a3,0x6
ffffffffc0204c20:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c22:	00c69593          	slli	a1,a3,0xc
ffffffffc0204c26:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c28:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c2a:	0ec5f663          	bgeu	a1,a2,ffffffffc0204d16 <do_execve+0x4c4>
ffffffffc0204c2e:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c32:	6505                	lui	a0,0x1
ffffffffc0204c34:	955a                	add	a0,a0,s6
ffffffffc0204c36:	96b2                	add	a3,a3,a2
ffffffffc0204c38:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c3c:	9536                	add	a0,a0,a3
ffffffffc0204c3e:	864e                	mv	a2,s3
ffffffffc0204c40:	4581                	li	a1,0
ffffffffc0204c42:	325000ef          	jal	ffffffffc0205766 <memset>
            start += size;
ffffffffc0204c46:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204c48:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204c4c:	01b4f463          	bgeu	s1,s11,ffffffffc0204c54 <do_execve+0x402>
ffffffffc0204c50:	db6484e3          	beq	s1,s6,ffffffffc02049f8 <do_execve+0x1a6>
ffffffffc0204c54:	e299                	bnez	a3,ffffffffc0204c5a <do_execve+0x408>
ffffffffc0204c56:	03bb0263          	beq	s6,s11,ffffffffc0204c7a <do_execve+0x428>
ffffffffc0204c5a:	00002697          	auipc	a3,0x2
ffffffffc0204c5e:	4c668693          	addi	a3,a3,1222 # ffffffffc0207120 <etext+0x1990>
ffffffffc0204c62:	00001617          	auipc	a2,0x1
ffffffffc0204c66:	4e660613          	addi	a2,a2,1254 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204c6a:	2b800593          	li	a1,696
ffffffffc0204c6e:	00002517          	auipc	a0,0x2
ffffffffc0204c72:	2c250513          	addi	a0,a0,706 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0204c76:	fd0fb0ef          	jal	ffffffffc0200446 <__panic>
        while (start < end)
ffffffffc0204c7a:	d69b7fe3          	bgeu	s6,s1,ffffffffc02049f8 <do_execve+0x1a6>
ffffffffc0204c7e:	56fd                	li	a3,-1
ffffffffc0204c80:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204c84:	f03e                	sd	a5,32(sp)
ffffffffc0204c86:	a0b9                	j	ffffffffc0204cd4 <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c88:	6785                	lui	a5,0x1
ffffffffc0204c8a:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204c8e:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204c92:	0104e463          	bltu	s1,a6,ffffffffc0204c9a <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c96:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204c9a:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c9e:	7782                	ld	a5,32(sp)
ffffffffc0204ca0:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204ca4:	40d406b3          	sub	a3,s0,a3
ffffffffc0204ca8:	8699                	srai	a3,a3,0x6
ffffffffc0204caa:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204cac:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cb0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cb2:	06b57263          	bgeu	a0,a1,ffffffffc0204d16 <do_execve+0x4c4>
ffffffffc0204cb6:	000ab583          	ld	a1,0(s5)
ffffffffc0204cba:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cbe:	864e                	mv	a2,s3
ffffffffc0204cc0:	96ae                	add	a3,a3,a1
ffffffffc0204cc2:	9536                	add	a0,a0,a3
ffffffffc0204cc4:	4581                	li	a1,0
            start += size;
ffffffffc0204cc6:	9b4e                	add	s6,s6,s3
ffffffffc0204cc8:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cca:	29d000ef          	jal	ffffffffc0205766 <memset>
        while (start < end)
ffffffffc0204cce:	d29b75e3          	bgeu	s6,s1,ffffffffc02049f8 <do_execve+0x1a6>
ffffffffc0204cd2:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204cd4:	01893503          	ld	a0,24(s2)
ffffffffc0204cd8:	6622                	ld	a2,8(sp)
ffffffffc0204cda:	85ee                	mv	a1,s11
ffffffffc0204cdc:	937fe0ef          	jal	ffffffffc0203612 <pgdir_alloc_page>
ffffffffc0204ce0:	842a                	mv	s0,a0
ffffffffc0204ce2:	f15d                	bnez	a0,ffffffffc0204c88 <do_execve+0x436>
ffffffffc0204ce4:	b5cd                	j	ffffffffc0204bc6 <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204ce6:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ce8:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204cea:	e43e                	sd	a5,8(sp)
ffffffffc0204cec:	b581                	j	ffffffffc0204b2c <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204cee:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204cf0:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204cf4:	e43e                	sd	a5,8(sp)
ffffffffc0204cf6:	bd1d                	j	ffffffffc0204b2c <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cf8:	416d89b3          	sub	s3,s11,s6
ffffffffc0204cfc:	bf19                	j	ffffffffc0204c12 <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204cfe:	54f5                	li	s1,-3
ffffffffc0204d00:	b3fd                	j	ffffffffc0204aee <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204d02:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204d04:	84da                	mv	s1,s6
ffffffffc0204d06:	bddd                	j	ffffffffc0204bfc <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204d08:	54f1                	li	s1,-4
ffffffffc0204d0a:	b1ad                	j	ffffffffc0204974 <do_execve+0x122>
ffffffffc0204d0c:	6da6                	ld	s11,72(sp)
ffffffffc0204d0e:	bd75                	j	ffffffffc0204bca <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204d10:	6da6                	ld	s11,72(sp)
ffffffffc0204d12:	54e1                	li	s1,-8
ffffffffc0204d14:	bd5d                	j	ffffffffc0204bca <do_execve+0x378>
ffffffffc0204d16:	00001617          	auipc	a2,0x1
ffffffffc0204d1a:	7e260613          	addi	a2,a2,2018 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0204d1e:	07100593          	li	a1,113
ffffffffc0204d22:	00001517          	auipc	a0,0x1
ffffffffc0204d26:	7fe50513          	addi	a0,a0,2046 # ffffffffc0206520 <etext+0xd90>
ffffffffc0204d2a:	f1cfb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0204d2e:	00001617          	auipc	a2,0x1
ffffffffc0204d32:	7ca60613          	addi	a2,a2,1994 # ffffffffc02064f8 <etext+0xd68>
ffffffffc0204d36:	07100593          	li	a1,113
ffffffffc0204d3a:	00001517          	auipc	a0,0x1
ffffffffc0204d3e:	7e650513          	addi	a0,a0,2022 # ffffffffc0206520 <etext+0xd90>
ffffffffc0204d42:	f122                	sd	s0,160(sp)
ffffffffc0204d44:	e152                	sd	s4,128(sp)
ffffffffc0204d46:	e4ee                	sd	s11,72(sp)
ffffffffc0204d48:	efefb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d4c:	00002617          	auipc	a2,0x2
ffffffffc0204d50:	85460613          	addi	a2,a2,-1964 # ffffffffc02065a0 <etext+0xe10>
ffffffffc0204d54:	2d700593          	li	a1,727
ffffffffc0204d58:	00002517          	auipc	a0,0x2
ffffffffc0204d5c:	1d850513          	addi	a0,a0,472 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0204d60:	e4ee                	sd	s11,72(sp)
ffffffffc0204d62:	ee4fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d66:	00002697          	auipc	a3,0x2
ffffffffc0204d6a:	4d268693          	addi	a3,a3,1234 # ffffffffc0207238 <etext+0x1aa8>
ffffffffc0204d6e:	00001617          	auipc	a2,0x1
ffffffffc0204d72:	3da60613          	addi	a2,a2,986 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204d76:	2d200593          	li	a1,722
ffffffffc0204d7a:	00002517          	auipc	a0,0x2
ffffffffc0204d7e:	1b650513          	addi	a0,a0,438 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0204d82:	e4ee                	sd	s11,72(sp)
ffffffffc0204d84:	ec2fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d88:	00002697          	auipc	a3,0x2
ffffffffc0204d8c:	46868693          	addi	a3,a3,1128 # ffffffffc02071f0 <etext+0x1a60>
ffffffffc0204d90:	00001617          	auipc	a2,0x1
ffffffffc0204d94:	3b860613          	addi	a2,a2,952 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204d98:	2d100593          	li	a1,721
ffffffffc0204d9c:	00002517          	auipc	a0,0x2
ffffffffc0204da0:	19450513          	addi	a0,a0,404 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0204da4:	e4ee                	sd	s11,72(sp)
ffffffffc0204da6:	ea0fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204daa:	00002697          	auipc	a3,0x2
ffffffffc0204dae:	3fe68693          	addi	a3,a3,1022 # ffffffffc02071a8 <etext+0x1a18>
ffffffffc0204db2:	00001617          	auipc	a2,0x1
ffffffffc0204db6:	39660613          	addi	a2,a2,918 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204dba:	2d000593          	li	a1,720
ffffffffc0204dbe:	00002517          	auipc	a0,0x2
ffffffffc0204dc2:	17250513          	addi	a0,a0,370 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0204dc6:	e4ee                	sd	s11,72(sp)
ffffffffc0204dc8:	e7efb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204dcc:	00002697          	auipc	a3,0x2
ffffffffc0204dd0:	39468693          	addi	a3,a3,916 # ffffffffc0207160 <etext+0x19d0>
ffffffffc0204dd4:	00001617          	auipc	a2,0x1
ffffffffc0204dd8:	37460613          	addi	a2,a2,884 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0204ddc:	2cf00593          	li	a1,719
ffffffffc0204de0:	00002517          	auipc	a0,0x2
ffffffffc0204de4:	15050513          	addi	a0,a0,336 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0204de8:	e4ee                	sd	s11,72(sp)
ffffffffc0204dea:	e5cfb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204dee <do_yield>:
    current->need_resched = 1;
ffffffffc0204dee:	00097797          	auipc	a5,0x97
ffffffffc0204df2:	9ca7b783          	ld	a5,-1590(a5) # ffffffffc029b7b8 <current>
ffffffffc0204df6:	4705                	li	a4,1
}
ffffffffc0204df8:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204dfa:	ef98                	sd	a4,24(a5)
}
ffffffffc0204dfc:	8082                	ret

ffffffffc0204dfe <do_wait>:
    if (code_store != NULL)
ffffffffc0204dfe:	c59d                	beqz	a1,ffffffffc0204e2c <do_wait+0x2e>
{
ffffffffc0204e00:	1101                	addi	sp,sp,-32
ffffffffc0204e02:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204e04:	00097517          	auipc	a0,0x97
ffffffffc0204e08:	9b453503          	ld	a0,-1612(a0) # ffffffffc029b7b8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e0c:	4685                	li	a3,1
ffffffffc0204e0e:	4611                	li	a2,4
ffffffffc0204e10:	7508                	ld	a0,40(a0)
{
ffffffffc0204e12:	ec06                	sd	ra,24(sp)
ffffffffc0204e14:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e16:	f6bfe0ef          	jal	ffffffffc0203d80 <user_mem_check>
ffffffffc0204e1a:	6702                	ld	a4,0(sp)
ffffffffc0204e1c:	67a2                	ld	a5,8(sp)
ffffffffc0204e1e:	c909                	beqz	a0,ffffffffc0204e30 <do_wait+0x32>
}
ffffffffc0204e20:	60e2                	ld	ra,24(sp)
ffffffffc0204e22:	85be                	mv	a1,a5
ffffffffc0204e24:	853a                	mv	a0,a4
ffffffffc0204e26:	6105                	addi	sp,sp,32
ffffffffc0204e28:	f24ff06f          	j	ffffffffc020454c <do_wait.part.0>
ffffffffc0204e2c:	f20ff06f          	j	ffffffffc020454c <do_wait.part.0>
ffffffffc0204e30:	60e2                	ld	ra,24(sp)
ffffffffc0204e32:	5575                	li	a0,-3
ffffffffc0204e34:	6105                	addi	sp,sp,32
ffffffffc0204e36:	8082                	ret

ffffffffc0204e38 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e38:	6789                	lui	a5,0x2
ffffffffc0204e3a:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e3e:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc0204e40:	06e7e463          	bltu	a5,a4,ffffffffc0204ea8 <do_kill+0x70>
{
ffffffffc0204e44:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e46:	45a9                	li	a1,10
{
ffffffffc0204e48:	ec06                	sd	ra,24(sp)
ffffffffc0204e4a:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e4c:	484000ef          	jal	ffffffffc02052d0 <hash32>
ffffffffc0204e50:	02051793          	slli	a5,a0,0x20
ffffffffc0204e54:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e58:	00093797          	auipc	a5,0x93
ffffffffc0204e5c:	8e078793          	addi	a5,a5,-1824 # ffffffffc0297738 <hash_list>
ffffffffc0204e60:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204e62:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e64:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e66:	a029                	j	ffffffffc0204e70 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204e68:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204e6c:	00c70963          	beq	a4,a2,ffffffffc0204e7e <do_kill+0x46>
ffffffffc0204e70:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204e72:	fea69be3          	bne	a3,a0,ffffffffc0204e68 <do_kill+0x30>
}
ffffffffc0204e76:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204e78:	5575                	li	a0,-3
}
ffffffffc0204e7a:	6105                	addi	sp,sp,32
ffffffffc0204e7c:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204e7e:	fd852703          	lw	a4,-40(a0)
ffffffffc0204e82:	00177693          	andi	a3,a4,1
ffffffffc0204e86:	e29d                	bnez	a3,ffffffffc0204eac <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204e88:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204e8a:	00176713          	ori	a4,a4,1
ffffffffc0204e8e:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204e92:	0006c663          	bltz	a3,ffffffffc0204e9e <do_kill+0x66>
            return 0;
ffffffffc0204e96:	4501                	li	a0,0
}
ffffffffc0204e98:	60e2                	ld	ra,24(sp)
ffffffffc0204e9a:	6105                	addi	sp,sp,32
ffffffffc0204e9c:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204e9e:	f2850513          	addi	a0,a0,-216
ffffffffc0204ea2:	232000ef          	jal	ffffffffc02050d4 <wakeup_proc>
ffffffffc0204ea6:	bfc5                	j	ffffffffc0204e96 <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204ea8:	5575                	li	a0,-3
}
ffffffffc0204eaa:	8082                	ret
        return -E_KILLED;
ffffffffc0204eac:	555d                	li	a0,-9
ffffffffc0204eae:	b7ed                	j	ffffffffc0204e98 <do_kill+0x60>

ffffffffc0204eb0 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204eb0:	1101                	addi	sp,sp,-32
ffffffffc0204eb2:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204eb4:	00097797          	auipc	a5,0x97
ffffffffc0204eb8:	88478793          	addi	a5,a5,-1916 # ffffffffc029b738 <proc_list>
ffffffffc0204ebc:	ec06                	sd	ra,24(sp)
ffffffffc0204ebe:	e822                	sd	s0,16(sp)
ffffffffc0204ec0:	e04a                	sd	s2,0(sp)
ffffffffc0204ec2:	00093497          	auipc	s1,0x93
ffffffffc0204ec6:	87648493          	addi	s1,s1,-1930 # ffffffffc0297738 <hash_list>
ffffffffc0204eca:	e79c                	sd	a5,8(a5)
ffffffffc0204ecc:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204ece:	00097717          	auipc	a4,0x97
ffffffffc0204ed2:	86a70713          	addi	a4,a4,-1942 # ffffffffc029b738 <proc_list>
ffffffffc0204ed6:	87a6                	mv	a5,s1
ffffffffc0204ed8:	e79c                	sd	a5,8(a5)
ffffffffc0204eda:	e39c                	sd	a5,0(a5)
ffffffffc0204edc:	07c1                	addi	a5,a5,16
ffffffffc0204ede:	fee79de3          	bne	a5,a4,ffffffffc0204ed8 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204ee2:	f4bfe0ef          	jal	ffffffffc0203e2c <alloc_proc>
ffffffffc0204ee6:	00097917          	auipc	s2,0x97
ffffffffc0204eea:	8e290913          	addi	s2,s2,-1822 # ffffffffc029b7c8 <idleproc>
ffffffffc0204eee:	00a93023          	sd	a0,0(s2)
ffffffffc0204ef2:	10050363          	beqz	a0,ffffffffc0204ff8 <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204ef6:	4789                	li	a5,2
ffffffffc0204ef8:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204efa:	00003797          	auipc	a5,0x3
ffffffffc0204efe:	10678793          	addi	a5,a5,262 # ffffffffc0208000 <bootstack>
ffffffffc0204f02:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f04:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204f08:	4785                	li	a5,1
ffffffffc0204f0a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f0c:	4641                	li	a2,16
ffffffffc0204f0e:	8522                	mv	a0,s0
ffffffffc0204f10:	4581                	li	a1,0
ffffffffc0204f12:	055000ef          	jal	ffffffffc0205766 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f16:	8522                	mv	a0,s0
ffffffffc0204f18:	463d                	li	a2,15
ffffffffc0204f1a:	00002597          	auipc	a1,0x2
ffffffffc0204f1e:	37e58593          	addi	a1,a1,894 # ffffffffc0207298 <etext+0x1b08>
ffffffffc0204f22:	057000ef          	jal	ffffffffc0205778 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f26:	00097797          	auipc	a5,0x97
ffffffffc0204f2a:	88a7a783          	lw	a5,-1910(a5) # ffffffffc029b7b0 <nr_process>

    current = idleproc;
ffffffffc0204f2e:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f32:	4601                	li	a2,0
    nr_process++;
ffffffffc0204f34:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f36:	4581                	li	a1,0
ffffffffc0204f38:	fffff517          	auipc	a0,0xfffff
ffffffffc0204f3c:	7f650513          	addi	a0,a0,2038 # ffffffffc020472e <init_main>
    current = idleproc;
ffffffffc0204f40:	00097697          	auipc	a3,0x97
ffffffffc0204f44:	86e6bc23          	sd	a4,-1928(a3) # ffffffffc029b7b8 <current>
    nr_process++;
ffffffffc0204f48:	00097717          	auipc	a4,0x97
ffffffffc0204f4c:	86f72423          	sw	a5,-1944(a4) # ffffffffc029b7b0 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f50:	c68ff0ef          	jal	ffffffffc02043b8 <kernel_thread>
ffffffffc0204f54:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204f56:	08a05563          	blez	a0,ffffffffc0204fe0 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f5a:	6789                	lui	a5,0x2
ffffffffc0204f5c:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bd2>
ffffffffc0204f5e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f62:	02e7e463          	bltu	a5,a4,ffffffffc0204f8a <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f66:	45a9                	li	a1,10
ffffffffc0204f68:	368000ef          	jal	ffffffffc02052d0 <hash32>
ffffffffc0204f6c:	02051713          	slli	a4,a0,0x20
ffffffffc0204f70:	01c75793          	srli	a5,a4,0x1c
ffffffffc0204f74:	00f486b3          	add	a3,s1,a5
ffffffffc0204f78:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f7a:	a029                	j	ffffffffc0204f84 <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0204f7c:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f80:	04870d63          	beq	a4,s0,ffffffffc0204fda <proc_init+0x12a>
    return listelm->next;
ffffffffc0204f84:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f86:	fef69be3          	bne	a3,a5,ffffffffc0204f7c <proc_init+0xcc>
    return NULL;
ffffffffc0204f8a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f8c:	0b478413          	addi	s0,a5,180
ffffffffc0204f90:	4641                	li	a2,16
ffffffffc0204f92:	4581                	li	a1,0
ffffffffc0204f94:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204f96:	00097717          	auipc	a4,0x97
ffffffffc0204f9a:	82f73523          	sd	a5,-2006(a4) # ffffffffc029b7c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f9e:	7c8000ef          	jal	ffffffffc0205766 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fa2:	8522                	mv	a0,s0
ffffffffc0204fa4:	463d                	li	a2,15
ffffffffc0204fa6:	00002597          	auipc	a1,0x2
ffffffffc0204faa:	31a58593          	addi	a1,a1,794 # ffffffffc02072c0 <etext+0x1b30>
ffffffffc0204fae:	7ca000ef          	jal	ffffffffc0205778 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204fb2:	00093783          	ld	a5,0(s2)
ffffffffc0204fb6:	cfad                	beqz	a5,ffffffffc0205030 <proc_init+0x180>
ffffffffc0204fb8:	43dc                	lw	a5,4(a5)
ffffffffc0204fba:	ebbd                	bnez	a5,ffffffffc0205030 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204fbc:	00097797          	auipc	a5,0x97
ffffffffc0204fc0:	8047b783          	ld	a5,-2044(a5) # ffffffffc029b7c0 <initproc>
ffffffffc0204fc4:	c7b1                	beqz	a5,ffffffffc0205010 <proc_init+0x160>
ffffffffc0204fc6:	43d8                	lw	a4,4(a5)
ffffffffc0204fc8:	4785                	li	a5,1
ffffffffc0204fca:	04f71363          	bne	a4,a5,ffffffffc0205010 <proc_init+0x160>
}
ffffffffc0204fce:	60e2                	ld	ra,24(sp)
ffffffffc0204fd0:	6442                	ld	s0,16(sp)
ffffffffc0204fd2:	64a2                	ld	s1,8(sp)
ffffffffc0204fd4:	6902                	ld	s2,0(sp)
ffffffffc0204fd6:	6105                	addi	sp,sp,32
ffffffffc0204fd8:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204fda:	f2878793          	addi	a5,a5,-216
ffffffffc0204fde:	b77d                	j	ffffffffc0204f8c <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0204fe0:	00002617          	auipc	a2,0x2
ffffffffc0204fe4:	2c060613          	addi	a2,a2,704 # ffffffffc02072a0 <etext+0x1b10>
ffffffffc0204fe8:	3fa00593          	li	a1,1018
ffffffffc0204fec:	00002517          	auipc	a0,0x2
ffffffffc0204ff0:	f4450513          	addi	a0,a0,-188 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc0204ff4:	c52fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204ff8:	00002617          	auipc	a2,0x2
ffffffffc0204ffc:	28860613          	addi	a2,a2,648 # ffffffffc0207280 <etext+0x1af0>
ffffffffc0205000:	3eb00593          	li	a1,1003
ffffffffc0205004:	00002517          	auipc	a0,0x2
ffffffffc0205008:	f2c50513          	addi	a0,a0,-212 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020500c:	c3afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205010:	00002697          	auipc	a3,0x2
ffffffffc0205014:	2e068693          	addi	a3,a3,736 # ffffffffc02072f0 <etext+0x1b60>
ffffffffc0205018:	00001617          	auipc	a2,0x1
ffffffffc020501c:	13060613          	addi	a2,a2,304 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0205020:	40100593          	li	a1,1025
ffffffffc0205024:	00002517          	auipc	a0,0x2
ffffffffc0205028:	f0c50513          	addi	a0,a0,-244 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020502c:	c1afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205030:	00002697          	auipc	a3,0x2
ffffffffc0205034:	29868693          	addi	a3,a3,664 # ffffffffc02072c8 <etext+0x1b38>
ffffffffc0205038:	00001617          	auipc	a2,0x1
ffffffffc020503c:	11060613          	addi	a2,a2,272 # ffffffffc0206148 <etext+0x9b8>
ffffffffc0205040:	40000593          	li	a1,1024
ffffffffc0205044:	00002517          	auipc	a0,0x2
ffffffffc0205048:	eec50513          	addi	a0,a0,-276 # ffffffffc0206f30 <etext+0x17a0>
ffffffffc020504c:	bfafb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205050 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205050:	1141                	addi	sp,sp,-16
ffffffffc0205052:	e022                	sd	s0,0(sp)
ffffffffc0205054:	e406                	sd	ra,8(sp)
ffffffffc0205056:	00096417          	auipc	s0,0x96
ffffffffc020505a:	76240413          	addi	s0,s0,1890 # ffffffffc029b7b8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020505e:	6018                	ld	a4,0(s0)
ffffffffc0205060:	6f1c                	ld	a5,24(a4)
ffffffffc0205062:	dffd                	beqz	a5,ffffffffc0205060 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205064:	104000ef          	jal	ffffffffc0205168 <schedule>
ffffffffc0205068:	bfdd                	j	ffffffffc020505e <cpu_idle+0xe>

ffffffffc020506a <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020506a:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020506e:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205072:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205074:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205076:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020507a:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020507e:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205082:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205086:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020508a:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020508e:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205092:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205096:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020509a:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020509e:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02050a2:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02050a6:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02050a8:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02050aa:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02050ae:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02050b2:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02050b6:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02050ba:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02050be:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02050c2:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02050c6:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02050ca:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02050ce:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02050d2:	8082                	ret

ffffffffc02050d4 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02050d4:	4118                	lw	a4,0(a0)
{
ffffffffc02050d6:	1101                	addi	sp,sp,-32
ffffffffc02050d8:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02050da:	478d                	li	a5,3
ffffffffc02050dc:	06f70763          	beq	a4,a5,ffffffffc020514a <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02050e0:	100027f3          	csrr	a5,sstatus
ffffffffc02050e4:	8b89                	andi	a5,a5,2
ffffffffc02050e6:	eb91                	bnez	a5,ffffffffc02050fa <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02050e8:	4789                	li	a5,2
ffffffffc02050ea:	02f70763          	beq	a4,a5,ffffffffc0205118 <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02050ee:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc02050f0:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc02050f2:	0e052623          	sw	zero,236(a0)
}
ffffffffc02050f6:	6105                	addi	sp,sp,32
ffffffffc02050f8:	8082                	ret
        intr_disable();
ffffffffc02050fa:	e42a                	sd	a0,8(sp)
ffffffffc02050fc:	809fb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205100:	6522                	ld	a0,8(sp)
ffffffffc0205102:	4789                	li	a5,2
ffffffffc0205104:	4118                	lw	a4,0(a0)
ffffffffc0205106:	02f70663          	beq	a4,a5,ffffffffc0205132 <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc020510a:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc020510c:	0e052623          	sw	zero,236(a0)
}
ffffffffc0205110:	60e2                	ld	ra,24(sp)
ffffffffc0205112:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205114:	feafb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0205118:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc020511a:	00002617          	auipc	a2,0x2
ffffffffc020511e:	23660613          	addi	a2,a2,566 # ffffffffc0207350 <etext+0x1bc0>
ffffffffc0205122:	45d1                	li	a1,20
ffffffffc0205124:	00002517          	auipc	a0,0x2
ffffffffc0205128:	21450513          	addi	a0,a0,532 # ffffffffc0207338 <etext+0x1ba8>
}
ffffffffc020512c:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc020512e:	b82fb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc0205132:	00002617          	auipc	a2,0x2
ffffffffc0205136:	21e60613          	addi	a2,a2,542 # ffffffffc0207350 <etext+0x1bc0>
ffffffffc020513a:	45d1                	li	a1,20
ffffffffc020513c:	00002517          	auipc	a0,0x2
ffffffffc0205140:	1fc50513          	addi	a0,a0,508 # ffffffffc0207338 <etext+0x1ba8>
ffffffffc0205144:	b6cfb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc0205148:	b7e1                	j	ffffffffc0205110 <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020514a:	00002697          	auipc	a3,0x2
ffffffffc020514e:	1ce68693          	addi	a3,a3,462 # ffffffffc0207318 <etext+0x1b88>
ffffffffc0205152:	00001617          	auipc	a2,0x1
ffffffffc0205156:	ff660613          	addi	a2,a2,-10 # ffffffffc0206148 <etext+0x9b8>
ffffffffc020515a:	45a5                	li	a1,9
ffffffffc020515c:	00002517          	auipc	a0,0x2
ffffffffc0205160:	1dc50513          	addi	a0,a0,476 # ffffffffc0207338 <etext+0x1ba8>
ffffffffc0205164:	ae2fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205168 <schedule>:

void schedule(void)
{
ffffffffc0205168:	1101                	addi	sp,sp,-32
ffffffffc020516a:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020516c:	100027f3          	csrr	a5,sstatus
ffffffffc0205170:	8b89                	andi	a5,a5,2
ffffffffc0205172:	4301                	li	t1,0
ffffffffc0205174:	e3c1                	bnez	a5,ffffffffc02051f4 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205176:	00096897          	auipc	a7,0x96
ffffffffc020517a:	6428b883          	ld	a7,1602(a7) # ffffffffc029b7b8 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020517e:	00096517          	auipc	a0,0x96
ffffffffc0205182:	64a53503          	ld	a0,1610(a0) # ffffffffc029b7c8 <idleproc>
        current->need_resched = 0;
ffffffffc0205186:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020518a:	04a88f63          	beq	a7,a0,ffffffffc02051e8 <schedule+0x80>
ffffffffc020518e:	0c888693          	addi	a3,a7,200
ffffffffc0205192:	00096617          	auipc	a2,0x96
ffffffffc0205196:	5a660613          	addi	a2,a2,1446 # ffffffffc029b738 <proc_list>
        le = last;
ffffffffc020519a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020519c:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc020519e:	4809                	li	a6,2
ffffffffc02051a0:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02051a2:	00c78863          	beq	a5,a2,ffffffffc02051b2 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc02051a6:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02051aa:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02051ae:	03070363          	beq	a4,a6,ffffffffc02051d4 <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02051b2:	fef697e3          	bne	a3,a5,ffffffffc02051a0 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051b6:	ed99                	bnez	a1,ffffffffc02051d4 <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02051b8:	451c                	lw	a5,8(a0)
ffffffffc02051ba:	2785                	addiw	a5,a5,1
ffffffffc02051bc:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02051be:	00a88663          	beq	a7,a0,ffffffffc02051ca <schedule+0x62>
ffffffffc02051c2:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc02051c4:	dddfe0ef          	jal	ffffffffc0203fa0 <proc_run>
ffffffffc02051c8:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc02051ca:	00031b63          	bnez	t1,ffffffffc02051e0 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051ce:	60e2                	ld	ra,24(sp)
ffffffffc02051d0:	6105                	addi	sp,sp,32
ffffffffc02051d2:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051d4:	4198                	lw	a4,0(a1)
ffffffffc02051d6:	4789                	li	a5,2
ffffffffc02051d8:	fef710e3          	bne	a4,a5,ffffffffc02051b8 <schedule+0x50>
ffffffffc02051dc:	852e                	mv	a0,a1
ffffffffc02051de:	bfe9                	j	ffffffffc02051b8 <schedule+0x50>
}
ffffffffc02051e0:	60e2                	ld	ra,24(sp)
ffffffffc02051e2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051e4:	f1afb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02051e8:	00096617          	auipc	a2,0x96
ffffffffc02051ec:	55060613          	addi	a2,a2,1360 # ffffffffc029b738 <proc_list>
ffffffffc02051f0:	86b2                	mv	a3,a2
ffffffffc02051f2:	b765                	j	ffffffffc020519a <schedule+0x32>
        intr_disable();
ffffffffc02051f4:	f10fb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02051f8:	4305                	li	t1,1
ffffffffc02051fa:	bfb5                	j	ffffffffc0205176 <schedule+0xe>

ffffffffc02051fc <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02051fc:	00096797          	auipc	a5,0x96
ffffffffc0205200:	5bc7b783          	ld	a5,1468(a5) # ffffffffc029b7b8 <current>
}
ffffffffc0205204:	43c8                	lw	a0,4(a5)
ffffffffc0205206:	8082                	ret

ffffffffc0205208 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205208:	4501                	li	a0,0
ffffffffc020520a:	8082                	ret

ffffffffc020520c <sys_putc>:
    cputchar(c);
ffffffffc020520c:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020520e:	1141                	addi	sp,sp,-16
ffffffffc0205210:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205212:	fb7fa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc0205216:	60a2                	ld	ra,8(sp)
ffffffffc0205218:	4501                	li	a0,0
ffffffffc020521a:	0141                	addi	sp,sp,16
ffffffffc020521c:	8082                	ret

ffffffffc020521e <sys_kill>:
    return do_kill(pid);
ffffffffc020521e:	4108                	lw	a0,0(a0)
ffffffffc0205220:	c19ff06f          	j	ffffffffc0204e38 <do_kill>

ffffffffc0205224 <sys_yield>:
    return do_yield();
ffffffffc0205224:	bcbff06f          	j	ffffffffc0204dee <do_yield>

ffffffffc0205228 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205228:	6d14                	ld	a3,24(a0)
ffffffffc020522a:	6910                	ld	a2,16(a0)
ffffffffc020522c:	650c                	ld	a1,8(a0)
ffffffffc020522e:	6108                	ld	a0,0(a0)
ffffffffc0205230:	e22ff06f          	j	ffffffffc0204852 <do_execve>

ffffffffc0205234 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205234:	650c                	ld	a1,8(a0)
ffffffffc0205236:	4108                	lw	a0,0(a0)
ffffffffc0205238:	bc7ff06f          	j	ffffffffc0204dfe <do_wait>

ffffffffc020523c <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020523c:	00096797          	auipc	a5,0x96
ffffffffc0205240:	57c7b783          	ld	a5,1404(a5) # ffffffffc029b7b8 <current>
    return do_fork(0, stack, tf);
ffffffffc0205244:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc0205246:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205248:	6a0c                	ld	a1,16(a2)
ffffffffc020524a:	db9fe06f          	j	ffffffffc0204002 <do_fork>

ffffffffc020524e <sys_exit>:
    return do_exit(error_code);
ffffffffc020524e:	4108                	lw	a0,0(a0)
ffffffffc0205250:	9b8ff06f          	j	ffffffffc0204408 <do_exit>

ffffffffc0205254 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc0205254:	00096697          	auipc	a3,0x96
ffffffffc0205258:	5646b683          	ld	a3,1380(a3) # ffffffffc029b7b8 <current>
syscall(void) {
ffffffffc020525c:	715d                	addi	sp,sp,-80
ffffffffc020525e:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205260:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205262:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205264:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205266:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205268:	02d7ec63          	bltu	a5,a3,ffffffffc02052a0 <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc020526c:	00002797          	auipc	a5,0x2
ffffffffc0205270:	32c78793          	addi	a5,a5,812 # ffffffffc0207598 <syscalls>
ffffffffc0205274:	00369613          	slli	a2,a3,0x3
ffffffffc0205278:	97b2                	add	a5,a5,a2
ffffffffc020527a:	639c                	ld	a5,0(a5)
ffffffffc020527c:	c395                	beqz	a5,ffffffffc02052a0 <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc020527e:	7028                	ld	a0,96(s0)
ffffffffc0205280:	742c                	ld	a1,104(s0)
ffffffffc0205282:	7830                	ld	a2,112(s0)
ffffffffc0205284:	7c34                	ld	a3,120(s0)
ffffffffc0205286:	6c38                	ld	a4,88(s0)
ffffffffc0205288:	f02a                	sd	a0,32(sp)
ffffffffc020528a:	f42e                	sd	a1,40(sp)
ffffffffc020528c:	f832                	sd	a2,48(sp)
ffffffffc020528e:	fc36                	sd	a3,56(sp)
ffffffffc0205290:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205292:	0828                	addi	a0,sp,24
ffffffffc0205294:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205296:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205298:	e828                	sd	a0,80(s0)
}
ffffffffc020529a:	6406                	ld	s0,64(sp)
ffffffffc020529c:	6161                	addi	sp,sp,80
ffffffffc020529e:	8082                	ret
    print_trapframe(tf);
ffffffffc02052a0:	8522                	mv	a0,s0
ffffffffc02052a2:	e436                	sd	a3,8(sp)
ffffffffc02052a4:	851fb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02052a8:	00096797          	auipc	a5,0x96
ffffffffc02052ac:	5107b783          	ld	a5,1296(a5) # ffffffffc029b7b8 <current>
ffffffffc02052b0:	66a2                	ld	a3,8(sp)
ffffffffc02052b2:	00002617          	auipc	a2,0x2
ffffffffc02052b6:	0be60613          	addi	a2,a2,190 # ffffffffc0207370 <etext+0x1be0>
ffffffffc02052ba:	43d8                	lw	a4,4(a5)
ffffffffc02052bc:	06200593          	li	a1,98
ffffffffc02052c0:	0b478793          	addi	a5,a5,180
ffffffffc02052c4:	00002517          	auipc	a0,0x2
ffffffffc02052c8:	0dc50513          	addi	a0,a0,220 # ffffffffc02073a0 <etext+0x1c10>
ffffffffc02052cc:	97afb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02052d0 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02052d0:	9e3707b7          	lui	a5,0x9e370
ffffffffc02052d4:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e365e29>
ffffffffc02052d6:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc02052da:	02000513          	li	a0,32
ffffffffc02052de:	9d0d                	subw	a0,a0,a1
}
ffffffffc02052e0:	00a7d53b          	srlw	a0,a5,a0
ffffffffc02052e4:	8082                	ret

ffffffffc02052e6 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052e6:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02052e8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052ec:	f022                	sd	s0,32(sp)
ffffffffc02052ee:	ec26                	sd	s1,24(sp)
ffffffffc02052f0:	e84a                	sd	s2,16(sp)
ffffffffc02052f2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02052f4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052f8:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02052fa:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02052fe:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205302:	84aa                	mv	s1,a0
ffffffffc0205304:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0205306:	03067d63          	bgeu	a2,a6,ffffffffc0205340 <printnum+0x5a>
ffffffffc020530a:	e44e                	sd	s3,8(sp)
ffffffffc020530c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020530e:	4785                	li	a5,1
ffffffffc0205310:	00e7d763          	bge	a5,a4,ffffffffc020531e <printnum+0x38>
            putch(padc, putdat);
ffffffffc0205314:	85ca                	mv	a1,s2
ffffffffc0205316:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0205318:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020531a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020531c:	fc65                	bnez	s0,ffffffffc0205314 <printnum+0x2e>
ffffffffc020531e:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205320:	00002797          	auipc	a5,0x2
ffffffffc0205324:	09878793          	addi	a5,a5,152 # ffffffffc02073b8 <etext+0x1c28>
ffffffffc0205328:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020532a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020532c:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0205330:	70a2                	ld	ra,40(sp)
ffffffffc0205332:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205334:	85ca                	mv	a1,s2
ffffffffc0205336:	87a6                	mv	a5,s1
}
ffffffffc0205338:	6942                	ld	s2,16(sp)
ffffffffc020533a:	64e2                	ld	s1,24(sp)
ffffffffc020533c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020533e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205340:	03065633          	divu	a2,a2,a6
ffffffffc0205344:	8722                	mv	a4,s0
ffffffffc0205346:	fa1ff0ef          	jal	ffffffffc02052e6 <printnum>
ffffffffc020534a:	bfd9                	j	ffffffffc0205320 <printnum+0x3a>

ffffffffc020534c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020534c:	7119                	addi	sp,sp,-128
ffffffffc020534e:	f4a6                	sd	s1,104(sp)
ffffffffc0205350:	f0ca                	sd	s2,96(sp)
ffffffffc0205352:	ecce                	sd	s3,88(sp)
ffffffffc0205354:	e8d2                	sd	s4,80(sp)
ffffffffc0205356:	e4d6                	sd	s5,72(sp)
ffffffffc0205358:	e0da                	sd	s6,64(sp)
ffffffffc020535a:	f862                	sd	s8,48(sp)
ffffffffc020535c:	fc86                	sd	ra,120(sp)
ffffffffc020535e:	f8a2                	sd	s0,112(sp)
ffffffffc0205360:	fc5e                	sd	s7,56(sp)
ffffffffc0205362:	f466                	sd	s9,40(sp)
ffffffffc0205364:	f06a                	sd	s10,32(sp)
ffffffffc0205366:	ec6e                	sd	s11,24(sp)
ffffffffc0205368:	84aa                	mv	s1,a0
ffffffffc020536a:	8c32                	mv	s8,a2
ffffffffc020536c:	8a36                	mv	s4,a3
ffffffffc020536e:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205370:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205374:	05500b13          	li	s6,85
ffffffffc0205378:	00002a97          	auipc	s5,0x2
ffffffffc020537c:	320a8a93          	addi	s5,s5,800 # ffffffffc0207698 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205380:	000c4503          	lbu	a0,0(s8)
ffffffffc0205384:	001c0413          	addi	s0,s8,1
ffffffffc0205388:	01350a63          	beq	a0,s3,ffffffffc020539c <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc020538c:	cd0d                	beqz	a0,ffffffffc02053c6 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc020538e:	85ca                	mv	a1,s2
ffffffffc0205390:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205392:	00044503          	lbu	a0,0(s0)
ffffffffc0205396:	0405                	addi	s0,s0,1
ffffffffc0205398:	ff351ae3          	bne	a0,s3,ffffffffc020538c <vprintfmt+0x40>
        width = precision = -1;
ffffffffc020539c:	5cfd                	li	s9,-1
ffffffffc020539e:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02053a0:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02053a4:	4b81                	li	s7,0
ffffffffc02053a6:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053a8:	00044683          	lbu	a3,0(s0)
ffffffffc02053ac:	00140c13          	addi	s8,s0,1
ffffffffc02053b0:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02053b4:	0ff5f593          	zext.b	a1,a1
ffffffffc02053b8:	02bb6663          	bltu	s6,a1,ffffffffc02053e4 <vprintfmt+0x98>
ffffffffc02053bc:	058a                	slli	a1,a1,0x2
ffffffffc02053be:	95d6                	add	a1,a1,s5
ffffffffc02053c0:	4198                	lw	a4,0(a1)
ffffffffc02053c2:	9756                	add	a4,a4,s5
ffffffffc02053c4:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02053c6:	70e6                	ld	ra,120(sp)
ffffffffc02053c8:	7446                	ld	s0,112(sp)
ffffffffc02053ca:	74a6                	ld	s1,104(sp)
ffffffffc02053cc:	7906                	ld	s2,96(sp)
ffffffffc02053ce:	69e6                	ld	s3,88(sp)
ffffffffc02053d0:	6a46                	ld	s4,80(sp)
ffffffffc02053d2:	6aa6                	ld	s5,72(sp)
ffffffffc02053d4:	6b06                	ld	s6,64(sp)
ffffffffc02053d6:	7be2                	ld	s7,56(sp)
ffffffffc02053d8:	7c42                	ld	s8,48(sp)
ffffffffc02053da:	7ca2                	ld	s9,40(sp)
ffffffffc02053dc:	7d02                	ld	s10,32(sp)
ffffffffc02053de:	6de2                	ld	s11,24(sp)
ffffffffc02053e0:	6109                	addi	sp,sp,128
ffffffffc02053e2:	8082                	ret
            putch('%', putdat);
ffffffffc02053e4:	85ca                	mv	a1,s2
ffffffffc02053e6:	02500513          	li	a0,37
ffffffffc02053ea:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02053ec:	fff44783          	lbu	a5,-1(s0)
ffffffffc02053f0:	02500713          	li	a4,37
ffffffffc02053f4:	8c22                	mv	s8,s0
ffffffffc02053f6:	f8e785e3          	beq	a5,a4,ffffffffc0205380 <vprintfmt+0x34>
ffffffffc02053fa:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02053fe:	1c7d                	addi	s8,s8,-1
ffffffffc0205400:	fee79de3          	bne	a5,a4,ffffffffc02053fa <vprintfmt+0xae>
ffffffffc0205404:	bfb5                	j	ffffffffc0205380 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0205406:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc020540a:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc020540c:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205410:	fd06071b          	addiw	a4,a2,-48
ffffffffc0205414:	24e56a63          	bltu	a0,a4,ffffffffc0205668 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0205418:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020541a:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc020541c:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205420:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205424:	0197073b          	addw	a4,a4,s9
ffffffffc0205428:	0017171b          	slliw	a4,a4,0x1
ffffffffc020542c:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc020542e:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205432:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205434:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0205438:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc020543c:	feb570e3          	bgeu	a0,a1,ffffffffc020541c <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0205440:	f60d54e3          	bgez	s10,ffffffffc02053a8 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0205444:	8d66                	mv	s10,s9
ffffffffc0205446:	5cfd                	li	s9,-1
ffffffffc0205448:	b785                	j	ffffffffc02053a8 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020544a:	8db6                	mv	s11,a3
ffffffffc020544c:	8462                	mv	s0,s8
ffffffffc020544e:	bfa9                	j	ffffffffc02053a8 <vprintfmt+0x5c>
ffffffffc0205450:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0205452:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0205454:	bf91                	j	ffffffffc02053a8 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0205456:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205458:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020545c:	00f74463          	blt	a4,a5,ffffffffc0205464 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205460:	1a078763          	beqz	a5,ffffffffc020560e <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0205464:	000a3603          	ld	a2,0(s4)
ffffffffc0205468:	46c1                	li	a3,16
ffffffffc020546a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020546c:	000d879b          	sext.w	a5,s11
ffffffffc0205470:	876a                	mv	a4,s10
ffffffffc0205472:	85ca                	mv	a1,s2
ffffffffc0205474:	8526                	mv	a0,s1
ffffffffc0205476:	e71ff0ef          	jal	ffffffffc02052e6 <printnum>
            break;
ffffffffc020547a:	b719                	j	ffffffffc0205380 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc020547c:	000a2503          	lw	a0,0(s4)
ffffffffc0205480:	85ca                	mv	a1,s2
ffffffffc0205482:	0a21                	addi	s4,s4,8
ffffffffc0205484:	9482                	jalr	s1
            break;
ffffffffc0205486:	bded                	j	ffffffffc0205380 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205488:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020548a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020548e:	00f74463          	blt	a4,a5,ffffffffc0205496 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0205492:	16078963          	beqz	a5,ffffffffc0205604 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0205496:	000a3603          	ld	a2,0(s4)
ffffffffc020549a:	46a9                	li	a3,10
ffffffffc020549c:	8a2e                	mv	s4,a1
ffffffffc020549e:	b7f9                	j	ffffffffc020546c <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02054a0:	85ca                	mv	a1,s2
ffffffffc02054a2:	03000513          	li	a0,48
ffffffffc02054a6:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02054a8:	85ca                	mv	a1,s2
ffffffffc02054aa:	07800513          	li	a0,120
ffffffffc02054ae:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02054b0:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02054b4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02054b6:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02054b8:	bf55                	j	ffffffffc020546c <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02054ba:	85ca                	mv	a1,s2
ffffffffc02054bc:	02500513          	li	a0,37
ffffffffc02054c0:	9482                	jalr	s1
            break;
ffffffffc02054c2:	bd7d                	j	ffffffffc0205380 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02054c4:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c8:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02054ca:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02054cc:	bf95                	j	ffffffffc0205440 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02054ce:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054d0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02054d4:	00f74463          	blt	a4,a5,ffffffffc02054dc <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02054d8:	12078163          	beqz	a5,ffffffffc02055fa <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02054dc:	000a3603          	ld	a2,0(s4)
ffffffffc02054e0:	46a1                	li	a3,8
ffffffffc02054e2:	8a2e                	mv	s4,a1
ffffffffc02054e4:	b761                	j	ffffffffc020546c <vprintfmt+0x120>
            if (width < 0)
ffffffffc02054e6:	876a                	mv	a4,s10
ffffffffc02054e8:	000d5363          	bgez	s10,ffffffffc02054ee <vprintfmt+0x1a2>
ffffffffc02054ec:	4701                	li	a4,0
ffffffffc02054ee:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054f2:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02054f4:	bd55                	j	ffffffffc02053a8 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc02054f6:	000d841b          	sext.w	s0,s11
ffffffffc02054fa:	fd340793          	addi	a5,s0,-45
ffffffffc02054fe:	00f037b3          	snez	a5,a5
ffffffffc0205502:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205506:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc020550a:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020550c:	008a0793          	addi	a5,s4,8
ffffffffc0205510:	e43e                	sd	a5,8(sp)
ffffffffc0205512:	100d8c63          	beqz	s11,ffffffffc020562a <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0205516:	12071363          	bnez	a4,ffffffffc020563c <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020551a:	000dc783          	lbu	a5,0(s11)
ffffffffc020551e:	0007851b          	sext.w	a0,a5
ffffffffc0205522:	c78d                	beqz	a5,ffffffffc020554c <vprintfmt+0x200>
ffffffffc0205524:	0d85                	addi	s11,s11,1
ffffffffc0205526:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205528:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020552c:	000cc563          	bltz	s9,ffffffffc0205536 <vprintfmt+0x1ea>
ffffffffc0205530:	3cfd                	addiw	s9,s9,-1
ffffffffc0205532:	008c8d63          	beq	s9,s0,ffffffffc020554c <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205536:	020b9663          	bnez	s7,ffffffffc0205562 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc020553a:	85ca                	mv	a1,s2
ffffffffc020553c:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020553e:	000dc783          	lbu	a5,0(s11)
ffffffffc0205542:	0d85                	addi	s11,s11,1
ffffffffc0205544:	3d7d                	addiw	s10,s10,-1
ffffffffc0205546:	0007851b          	sext.w	a0,a5
ffffffffc020554a:	f3ed                	bnez	a5,ffffffffc020552c <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc020554c:	01a05963          	blez	s10,ffffffffc020555e <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0205550:	85ca                	mv	a1,s2
ffffffffc0205552:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0205556:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0205558:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc020555a:	fe0d1be3          	bnez	s10,ffffffffc0205550 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020555e:	6a22                	ld	s4,8(sp)
ffffffffc0205560:	b505                	j	ffffffffc0205380 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205562:	3781                	addiw	a5,a5,-32
ffffffffc0205564:	fcfa7be3          	bgeu	s4,a5,ffffffffc020553a <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0205568:	03f00513          	li	a0,63
ffffffffc020556c:	85ca                	mv	a1,s2
ffffffffc020556e:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205570:	000dc783          	lbu	a5,0(s11)
ffffffffc0205574:	0d85                	addi	s11,s11,1
ffffffffc0205576:	3d7d                	addiw	s10,s10,-1
ffffffffc0205578:	0007851b          	sext.w	a0,a5
ffffffffc020557c:	dbe1                	beqz	a5,ffffffffc020554c <vprintfmt+0x200>
ffffffffc020557e:	fa0cd9e3          	bgez	s9,ffffffffc0205530 <vprintfmt+0x1e4>
ffffffffc0205582:	b7c5                	j	ffffffffc0205562 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0205584:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205588:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc020558a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020558c:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205590:	8fb9                	xor	a5,a5,a4
ffffffffc0205592:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205596:	02d64563          	blt	a2,a3,ffffffffc02055c0 <vprintfmt+0x274>
ffffffffc020559a:	00002797          	auipc	a5,0x2
ffffffffc020559e:	25678793          	addi	a5,a5,598 # ffffffffc02077f0 <error_string>
ffffffffc02055a2:	00369713          	slli	a4,a3,0x3
ffffffffc02055a6:	97ba                	add	a5,a5,a4
ffffffffc02055a8:	639c                	ld	a5,0(a5)
ffffffffc02055aa:	cb99                	beqz	a5,ffffffffc02055c0 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02055ac:	86be                	mv	a3,a5
ffffffffc02055ae:	00000617          	auipc	a2,0x0
ffffffffc02055b2:	20a60613          	addi	a2,a2,522 # ffffffffc02057b8 <etext+0x28>
ffffffffc02055b6:	85ca                	mv	a1,s2
ffffffffc02055b8:	8526                	mv	a0,s1
ffffffffc02055ba:	0d8000ef          	jal	ffffffffc0205692 <printfmt>
ffffffffc02055be:	b3c9                	j	ffffffffc0205380 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02055c0:	00002617          	auipc	a2,0x2
ffffffffc02055c4:	e1860613          	addi	a2,a2,-488 # ffffffffc02073d8 <etext+0x1c48>
ffffffffc02055c8:	85ca                	mv	a1,s2
ffffffffc02055ca:	8526                	mv	a0,s1
ffffffffc02055cc:	0c6000ef          	jal	ffffffffc0205692 <printfmt>
ffffffffc02055d0:	bb45                	j	ffffffffc0205380 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02055d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055d4:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02055d8:	00f74363          	blt	a4,a5,ffffffffc02055de <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02055dc:	cf81                	beqz	a5,ffffffffc02055f4 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02055de:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02055e2:	02044b63          	bltz	s0,ffffffffc0205618 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02055e6:	8622                	mv	a2,s0
ffffffffc02055e8:	8a5e                	mv	s4,s7
ffffffffc02055ea:	46a9                	li	a3,10
ffffffffc02055ec:	b541                	j	ffffffffc020546c <vprintfmt+0x120>
            lflag ++;
ffffffffc02055ee:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055f0:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02055f2:	bb5d                	j	ffffffffc02053a8 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc02055f4:	000a2403          	lw	s0,0(s4)
ffffffffc02055f8:	b7ed                	j	ffffffffc02055e2 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02055fa:	000a6603          	lwu	a2,0(s4)
ffffffffc02055fe:	46a1                	li	a3,8
ffffffffc0205600:	8a2e                	mv	s4,a1
ffffffffc0205602:	b5ad                	j	ffffffffc020546c <vprintfmt+0x120>
ffffffffc0205604:	000a6603          	lwu	a2,0(s4)
ffffffffc0205608:	46a9                	li	a3,10
ffffffffc020560a:	8a2e                	mv	s4,a1
ffffffffc020560c:	b585                	j	ffffffffc020546c <vprintfmt+0x120>
ffffffffc020560e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205612:	46c1                	li	a3,16
ffffffffc0205614:	8a2e                	mv	s4,a1
ffffffffc0205616:	bd99                	j	ffffffffc020546c <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0205618:	85ca                	mv	a1,s2
ffffffffc020561a:	02d00513          	li	a0,45
ffffffffc020561e:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205620:	40800633          	neg	a2,s0
ffffffffc0205624:	8a5e                	mv	s4,s7
ffffffffc0205626:	46a9                	li	a3,10
ffffffffc0205628:	b591                	j	ffffffffc020546c <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc020562a:	e329                	bnez	a4,ffffffffc020566c <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020562c:	02800793          	li	a5,40
ffffffffc0205630:	853e                	mv	a0,a5
ffffffffc0205632:	00002d97          	auipc	s11,0x2
ffffffffc0205636:	d9fd8d93          	addi	s11,s11,-609 # ffffffffc02073d1 <etext+0x1c41>
ffffffffc020563a:	b5f5                	j	ffffffffc0205526 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020563c:	85e6                	mv	a1,s9
ffffffffc020563e:	856e                	mv	a0,s11
ffffffffc0205640:	08a000ef          	jal	ffffffffc02056ca <strnlen>
ffffffffc0205644:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0205648:	01a05863          	blez	s10,ffffffffc0205658 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc020564c:	85ca                	mv	a1,s2
ffffffffc020564e:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205650:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0205652:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205654:	fe0d1ce3          	bnez	s10,ffffffffc020564c <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205658:	000dc783          	lbu	a5,0(s11)
ffffffffc020565c:	0007851b          	sext.w	a0,a5
ffffffffc0205660:	ec0792e3          	bnez	a5,ffffffffc0205524 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205664:	6a22                	ld	s4,8(sp)
ffffffffc0205666:	bb29                	j	ffffffffc0205380 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205668:	8462                	mv	s0,s8
ffffffffc020566a:	bbd9                	j	ffffffffc0205440 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020566c:	85e6                	mv	a1,s9
ffffffffc020566e:	00002517          	auipc	a0,0x2
ffffffffc0205672:	d6250513          	addi	a0,a0,-670 # ffffffffc02073d0 <etext+0x1c40>
ffffffffc0205676:	054000ef          	jal	ffffffffc02056ca <strnlen>
ffffffffc020567a:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020567e:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0205682:	00002d97          	auipc	s11,0x2
ffffffffc0205686:	d4ed8d93          	addi	s11,s11,-690 # ffffffffc02073d0 <etext+0x1c40>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020568a:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020568c:	fda040e3          	bgtz	s10,ffffffffc020564c <vprintfmt+0x300>
ffffffffc0205690:	bd51                	j	ffffffffc0205524 <vprintfmt+0x1d8>

ffffffffc0205692 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205692:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205694:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205698:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020569a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020569c:	ec06                	sd	ra,24(sp)
ffffffffc020569e:	f83a                	sd	a4,48(sp)
ffffffffc02056a0:	fc3e                	sd	a5,56(sp)
ffffffffc02056a2:	e0c2                	sd	a6,64(sp)
ffffffffc02056a4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02056a6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02056a8:	ca5ff0ef          	jal	ffffffffc020534c <vprintfmt>
}
ffffffffc02056ac:	60e2                	ld	ra,24(sp)
ffffffffc02056ae:	6161                	addi	sp,sp,80
ffffffffc02056b0:	8082                	ret

ffffffffc02056b2 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02056b2:	00054783          	lbu	a5,0(a0)
ffffffffc02056b6:	cb81                	beqz	a5,ffffffffc02056c6 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02056b8:	4781                	li	a5,0
        cnt ++;
ffffffffc02056ba:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02056bc:	00f50733          	add	a4,a0,a5
ffffffffc02056c0:	00074703          	lbu	a4,0(a4)
ffffffffc02056c4:	fb7d                	bnez	a4,ffffffffc02056ba <strlen+0x8>
    }
    return cnt;
}
ffffffffc02056c6:	853e                	mv	a0,a5
ffffffffc02056c8:	8082                	ret

ffffffffc02056ca <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02056ca:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02056cc:	e589                	bnez	a1,ffffffffc02056d6 <strnlen+0xc>
ffffffffc02056ce:	a811                	j	ffffffffc02056e2 <strnlen+0x18>
        cnt ++;
ffffffffc02056d0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02056d2:	00f58863          	beq	a1,a5,ffffffffc02056e2 <strnlen+0x18>
ffffffffc02056d6:	00f50733          	add	a4,a0,a5
ffffffffc02056da:	00074703          	lbu	a4,0(a4)
ffffffffc02056de:	fb6d                	bnez	a4,ffffffffc02056d0 <strnlen+0x6>
ffffffffc02056e0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02056e2:	852e                	mv	a0,a1
ffffffffc02056e4:	8082                	ret

ffffffffc02056e6 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02056e6:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02056e8:	0005c703          	lbu	a4,0(a1)
ffffffffc02056ec:	0585                	addi	a1,a1,1
ffffffffc02056ee:	0785                	addi	a5,a5,1
ffffffffc02056f0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02056f4:	fb75                	bnez	a4,ffffffffc02056e8 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02056f6:	8082                	ret

ffffffffc02056f8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02056f8:	00054783          	lbu	a5,0(a0)
ffffffffc02056fc:	e791                	bnez	a5,ffffffffc0205708 <strcmp+0x10>
ffffffffc02056fe:	a01d                	j	ffffffffc0205724 <strcmp+0x2c>
ffffffffc0205700:	00054783          	lbu	a5,0(a0)
ffffffffc0205704:	cb99                	beqz	a5,ffffffffc020571a <strcmp+0x22>
ffffffffc0205706:	0585                	addi	a1,a1,1
ffffffffc0205708:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020570c:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020570e:	fef709e3          	beq	a4,a5,ffffffffc0205700 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205712:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205716:	9d19                	subw	a0,a0,a4
ffffffffc0205718:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020571a:	0015c703          	lbu	a4,1(a1)
ffffffffc020571e:	4501                	li	a0,0
}
ffffffffc0205720:	9d19                	subw	a0,a0,a4
ffffffffc0205722:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205724:	0005c703          	lbu	a4,0(a1)
ffffffffc0205728:	4501                	li	a0,0
ffffffffc020572a:	b7f5                	j	ffffffffc0205716 <strcmp+0x1e>

ffffffffc020572c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020572c:	ce01                	beqz	a2,ffffffffc0205744 <strncmp+0x18>
ffffffffc020572e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205732:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205734:	cb91                	beqz	a5,ffffffffc0205748 <strncmp+0x1c>
ffffffffc0205736:	0005c703          	lbu	a4,0(a1)
ffffffffc020573a:	00f71763          	bne	a4,a5,ffffffffc0205748 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc020573e:	0505                	addi	a0,a0,1
ffffffffc0205740:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205742:	f675                	bnez	a2,ffffffffc020572e <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205744:	4501                	li	a0,0
ffffffffc0205746:	8082                	ret
ffffffffc0205748:	00054503          	lbu	a0,0(a0)
ffffffffc020574c:	0005c783          	lbu	a5,0(a1)
ffffffffc0205750:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205752:	8082                	ret

ffffffffc0205754 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205754:	a021                	j	ffffffffc020575c <strchr+0x8>
        if (*s == c) {
ffffffffc0205756:	00f58763          	beq	a1,a5,ffffffffc0205764 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc020575a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020575c:	00054783          	lbu	a5,0(a0)
ffffffffc0205760:	fbfd                	bnez	a5,ffffffffc0205756 <strchr+0x2>
    }
    return NULL;
ffffffffc0205762:	4501                	li	a0,0
}
ffffffffc0205764:	8082                	ret

ffffffffc0205766 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205766:	ca01                	beqz	a2,ffffffffc0205776 <memset+0x10>
ffffffffc0205768:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020576a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020576c:	0785                	addi	a5,a5,1
ffffffffc020576e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205772:	fef61de3          	bne	a2,a5,ffffffffc020576c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205776:	8082                	ret

ffffffffc0205778 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205778:	ca19                	beqz	a2,ffffffffc020578e <memcpy+0x16>
ffffffffc020577a:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020577c:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020577e:	0005c703          	lbu	a4,0(a1)
ffffffffc0205782:	0585                	addi	a1,a1,1
ffffffffc0205784:	0785                	addi	a5,a5,1
ffffffffc0205786:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020578a:	feb61ae3          	bne	a2,a1,ffffffffc020577e <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020578e:	8082                	ret
