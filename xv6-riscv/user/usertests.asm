
user/_usertests:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <copyinstr1>:
}

// what if you pass ridiculous string pointers to system calls?
void
copyinstr1(char *s)
{
       0:	1141                	addi	sp,sp,-16
       2:	e406                	sd	ra,8(sp)
       4:	e022                	sd	s0,0(sp)
       6:	0800                	addi	s0,sp,16
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };

  for(int ai = 0; ai < 2; ai++){
    uint64 addr = addrs[ai];

    int fd = open((char *)addr, O_CREATE|O_WRONLY);
       8:	20100593          	li	a1,513
       c:	4505                	li	a0,1
       e:	057e                	slli	a0,a0,0x1f
      10:	00006097          	auipc	ra,0x6
      14:	8b6080e7          	jalr	-1866(ra) # 58c6 <open>
    if(fd >= 0){
      18:	02055063          	bgez	a0,38 <copyinstr1+0x38>
    int fd = open((char *)addr, O_CREATE|O_WRONLY);
      1c:	20100593          	li	a1,513
      20:	557d                	li	a0,-1
      22:	00006097          	auipc	ra,0x6
      26:	8a4080e7          	jalr	-1884(ra) # 58c6 <open>
    uint64 addr = addrs[ai];
      2a:	55fd                	li	a1,-1
    if(fd >= 0){
      2c:	00055863          	bgez	a0,3c <copyinstr1+0x3c>
      printf("open(%p) returned %d, not -1\n", addr, fd);
      exit(1);
    }
  }
}
      30:	60a2                	ld	ra,8(sp)
      32:	6402                	ld	s0,0(sp)
      34:	0141                	addi	sp,sp,16
      36:	8082                	ret
    uint64 addr = addrs[ai];
      38:	4585                	li	a1,1
      3a:	05fe                	slli	a1,a1,0x1f
      printf("open(%p) returned %d, not -1\n", addr, fd);
      3c:	862a                	mv	a2,a0
      3e:	00006517          	auipc	a0,0x6
      42:	0ca50513          	addi	a0,a0,202 # 6108 <malloc+0x434>
      46:	00006097          	auipc	ra,0x6
      4a:	bd0080e7          	jalr	-1072(ra) # 5c16 <printf>
      exit(1);
      4e:	4505                	li	a0,1
      50:	00006097          	auipc	ra,0x6
      54:	836080e7          	jalr	-1994(ra) # 5886 <exit>

0000000000000058 <bsstest>:
void
bsstest(char *s)
{
  int i;

  for(i = 0; i < sizeof(uninit); i++){
      58:	00009797          	auipc	a5,0x9
      5c:	6a078793          	addi	a5,a5,1696 # 96f8 <uninit>
      60:	0000c697          	auipc	a3,0xc
      64:	da868693          	addi	a3,a3,-600 # be08 <buf>
    if(uninit[i] != '\0'){
      68:	0007c703          	lbu	a4,0(a5)
      6c:	e709                	bnez	a4,76 <bsstest+0x1e>
  for(i = 0; i < sizeof(uninit); i++){
      6e:	0785                	addi	a5,a5,1
      70:	fed79ce3          	bne	a5,a3,68 <bsstest+0x10>
      74:	8082                	ret
{
      76:	1141                	addi	sp,sp,-16
      78:	e406                	sd	ra,8(sp)
      7a:	e022                	sd	s0,0(sp)
      7c:	0800                	addi	s0,sp,16
      printf("%s: bss test failed\n", s);
      7e:	85aa                	mv	a1,a0
      80:	00006517          	auipc	a0,0x6
      84:	0a850513          	addi	a0,a0,168 # 6128 <malloc+0x454>
      88:	00006097          	auipc	ra,0x6
      8c:	b8e080e7          	jalr	-1138(ra) # 5c16 <printf>
      exit(1);
      90:	4505                	li	a0,1
      92:	00005097          	auipc	ra,0x5
      96:	7f4080e7          	jalr	2036(ra) # 5886 <exit>

000000000000009a <opentest>:
{
      9a:	1101                	addi	sp,sp,-32
      9c:	ec06                	sd	ra,24(sp)
      9e:	e822                	sd	s0,16(sp)
      a0:	e426                	sd	s1,8(sp)
      a2:	1000                	addi	s0,sp,32
      a4:	84aa                	mv	s1,a0
  fd = open("echo", 0);
      a6:	4581                	li	a1,0
      a8:	00006517          	auipc	a0,0x6
      ac:	09850513          	addi	a0,a0,152 # 6140 <malloc+0x46c>
      b0:	00006097          	auipc	ra,0x6
      b4:	816080e7          	jalr	-2026(ra) # 58c6 <open>
  if(fd < 0){
      b8:	02054663          	bltz	a0,e4 <opentest+0x4a>
  close(fd);
      bc:	00005097          	auipc	ra,0x5
      c0:	7f2080e7          	jalr	2034(ra) # 58ae <close>
  fd = open("doesnotexist", 0);
      c4:	4581                	li	a1,0
      c6:	00006517          	auipc	a0,0x6
      ca:	09a50513          	addi	a0,a0,154 # 6160 <malloc+0x48c>
      ce:	00005097          	auipc	ra,0x5
      d2:	7f8080e7          	jalr	2040(ra) # 58c6 <open>
  if(fd >= 0){
      d6:	02055563          	bgez	a0,100 <opentest+0x66>
}
      da:	60e2                	ld	ra,24(sp)
      dc:	6442                	ld	s0,16(sp)
      de:	64a2                	ld	s1,8(sp)
      e0:	6105                	addi	sp,sp,32
      e2:	8082                	ret
    printf("%s: open echo failed!\n", s);
      e4:	85a6                	mv	a1,s1
      e6:	00006517          	auipc	a0,0x6
      ea:	06250513          	addi	a0,a0,98 # 6148 <malloc+0x474>
      ee:	00006097          	auipc	ra,0x6
      f2:	b28080e7          	jalr	-1240(ra) # 5c16 <printf>
    exit(1);
      f6:	4505                	li	a0,1
      f8:	00005097          	auipc	ra,0x5
      fc:	78e080e7          	jalr	1934(ra) # 5886 <exit>
    printf("%s: open doesnotexist succeeded!\n", s);
     100:	85a6                	mv	a1,s1
     102:	00006517          	auipc	a0,0x6
     106:	06e50513          	addi	a0,a0,110 # 6170 <malloc+0x49c>
     10a:	00006097          	auipc	ra,0x6
     10e:	b0c080e7          	jalr	-1268(ra) # 5c16 <printf>
    exit(1);
     112:	4505                	li	a0,1
     114:	00005097          	auipc	ra,0x5
     118:	772080e7          	jalr	1906(ra) # 5886 <exit>

000000000000011c <truncate2>:
{
     11c:	7179                	addi	sp,sp,-48
     11e:	f406                	sd	ra,40(sp)
     120:	f022                	sd	s0,32(sp)
     122:	ec26                	sd	s1,24(sp)
     124:	e84a                	sd	s2,16(sp)
     126:	e44e                	sd	s3,8(sp)
     128:	1800                	addi	s0,sp,48
     12a:	89aa                	mv	s3,a0
  unlink("truncfile");
     12c:	00006517          	auipc	a0,0x6
     130:	06c50513          	addi	a0,a0,108 # 6198 <malloc+0x4c4>
     134:	00005097          	auipc	ra,0x5
     138:	7a2080e7          	jalr	1954(ra) # 58d6 <unlink>
  int fd1 = open("truncfile", O_CREATE|O_TRUNC|O_WRONLY);
     13c:	60100593          	li	a1,1537
     140:	00006517          	auipc	a0,0x6
     144:	05850513          	addi	a0,a0,88 # 6198 <malloc+0x4c4>
     148:	00005097          	auipc	ra,0x5
     14c:	77e080e7          	jalr	1918(ra) # 58c6 <open>
     150:	84aa                	mv	s1,a0
  write(fd1, "abcd", 4);
     152:	4611                	li	a2,4
     154:	00006597          	auipc	a1,0x6
     158:	05458593          	addi	a1,a1,84 # 61a8 <malloc+0x4d4>
     15c:	00005097          	auipc	ra,0x5
     160:	74a080e7          	jalr	1866(ra) # 58a6 <write>
  int fd2 = open("truncfile", O_TRUNC|O_WRONLY);
     164:	40100593          	li	a1,1025
     168:	00006517          	auipc	a0,0x6
     16c:	03050513          	addi	a0,a0,48 # 6198 <malloc+0x4c4>
     170:	00005097          	auipc	ra,0x5
     174:	756080e7          	jalr	1878(ra) # 58c6 <open>
     178:	892a                	mv	s2,a0
  int n = write(fd1, "x", 1);
     17a:	4605                	li	a2,1
     17c:	00006597          	auipc	a1,0x6
     180:	03458593          	addi	a1,a1,52 # 61b0 <malloc+0x4dc>
     184:	8526                	mv	a0,s1
     186:	00005097          	auipc	ra,0x5
     18a:	720080e7          	jalr	1824(ra) # 58a6 <write>
  if(n != -1){
     18e:	57fd                	li	a5,-1
     190:	02f51b63          	bne	a0,a5,1c6 <truncate2+0xaa>
  unlink("truncfile");
     194:	00006517          	auipc	a0,0x6
     198:	00450513          	addi	a0,a0,4 # 6198 <malloc+0x4c4>
     19c:	00005097          	auipc	ra,0x5
     1a0:	73a080e7          	jalr	1850(ra) # 58d6 <unlink>
  close(fd1);
     1a4:	8526                	mv	a0,s1
     1a6:	00005097          	auipc	ra,0x5
     1aa:	708080e7          	jalr	1800(ra) # 58ae <close>
  close(fd2);
     1ae:	854a                	mv	a0,s2
     1b0:	00005097          	auipc	ra,0x5
     1b4:	6fe080e7          	jalr	1790(ra) # 58ae <close>
}
     1b8:	70a2                	ld	ra,40(sp)
     1ba:	7402                	ld	s0,32(sp)
     1bc:	64e2                	ld	s1,24(sp)
     1be:	6942                	ld	s2,16(sp)
     1c0:	69a2                	ld	s3,8(sp)
     1c2:	6145                	addi	sp,sp,48
     1c4:	8082                	ret
    printf("%s: write returned %d, expected -1\n", s, n);
     1c6:	862a                	mv	a2,a0
     1c8:	85ce                	mv	a1,s3
     1ca:	00006517          	auipc	a0,0x6
     1ce:	fee50513          	addi	a0,a0,-18 # 61b8 <malloc+0x4e4>
     1d2:	00006097          	auipc	ra,0x6
     1d6:	a44080e7          	jalr	-1468(ra) # 5c16 <printf>
    exit(1);
     1da:	4505                	li	a0,1
     1dc:	00005097          	auipc	ra,0x5
     1e0:	6aa080e7          	jalr	1706(ra) # 5886 <exit>

00000000000001e4 <createtest>:
{
     1e4:	7179                	addi	sp,sp,-48
     1e6:	f406                	sd	ra,40(sp)
     1e8:	f022                	sd	s0,32(sp)
     1ea:	ec26                	sd	s1,24(sp)
     1ec:	e84a                	sd	s2,16(sp)
     1ee:	1800                	addi	s0,sp,48
  name[0] = 'a';
     1f0:	06100793          	li	a5,97
     1f4:	fcf40c23          	sb	a5,-40(s0)
  name[2] = '\0';
     1f8:	fc040d23          	sb	zero,-38(s0)
     1fc:	03000493          	li	s1,48
  for(i = 0; i < N; i++){
     200:	06400913          	li	s2,100
    name[1] = '0' + i;
     204:	fc940ca3          	sb	s1,-39(s0)
    fd = open(name, O_CREATE|O_RDWR);
     208:	20200593          	li	a1,514
     20c:	fd840513          	addi	a0,s0,-40
     210:	00005097          	auipc	ra,0x5
     214:	6b6080e7          	jalr	1718(ra) # 58c6 <open>
    close(fd);
     218:	00005097          	auipc	ra,0x5
     21c:	696080e7          	jalr	1686(ra) # 58ae <close>
  for(i = 0; i < N; i++){
     220:	2485                	addiw	s1,s1,1
     222:	0ff4f493          	andi	s1,s1,255
     226:	fd249fe3          	bne	s1,s2,204 <createtest+0x20>
  name[0] = 'a';
     22a:	06100793          	li	a5,97
     22e:	fcf40c23          	sb	a5,-40(s0)
  name[2] = '\0';
     232:	fc040d23          	sb	zero,-38(s0)
     236:	03000493          	li	s1,48
  for(i = 0; i < N; i++){
     23a:	06400913          	li	s2,100
    name[1] = '0' + i;
     23e:	fc940ca3          	sb	s1,-39(s0)
    unlink(name);
     242:	fd840513          	addi	a0,s0,-40
     246:	00005097          	auipc	ra,0x5
     24a:	690080e7          	jalr	1680(ra) # 58d6 <unlink>
  for(i = 0; i < N; i++){
     24e:	2485                	addiw	s1,s1,1
     250:	0ff4f493          	andi	s1,s1,255
     254:	ff2495e3          	bne	s1,s2,23e <createtest+0x5a>
}
     258:	70a2                	ld	ra,40(sp)
     25a:	7402                	ld	s0,32(sp)
     25c:	64e2                	ld	s1,24(sp)
     25e:	6942                	ld	s2,16(sp)
     260:	6145                	addi	sp,sp,48
     262:	8082                	ret

0000000000000264 <bigwrite>:
{
     264:	715d                	addi	sp,sp,-80
     266:	e486                	sd	ra,72(sp)
     268:	e0a2                	sd	s0,64(sp)
     26a:	fc26                	sd	s1,56(sp)
     26c:	f84a                	sd	s2,48(sp)
     26e:	f44e                	sd	s3,40(sp)
     270:	f052                	sd	s4,32(sp)
     272:	ec56                	sd	s5,24(sp)
     274:	e85a                	sd	s6,16(sp)
     276:	e45e                	sd	s7,8(sp)
     278:	0880                	addi	s0,sp,80
     27a:	8baa                	mv	s7,a0
  unlink("bigwrite");
     27c:	00006517          	auipc	a0,0x6
     280:	d0c50513          	addi	a0,a0,-756 # 5f88 <malloc+0x2b4>
     284:	00005097          	auipc	ra,0x5
     288:	652080e7          	jalr	1618(ra) # 58d6 <unlink>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     28c:	1f300493          	li	s1,499
    fd = open("bigwrite", O_CREATE | O_RDWR);
     290:	00006a97          	auipc	s5,0x6
     294:	cf8a8a93          	addi	s5,s5,-776 # 5f88 <malloc+0x2b4>
      int cc = write(fd, buf, sz);
     298:	0000ca17          	auipc	s4,0xc
     29c:	b70a0a13          	addi	s4,s4,-1168 # be08 <buf>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     2a0:	6b0d                	lui	s6,0x3
     2a2:	1c9b0b13          	addi	s6,s6,457 # 31c9 <subdir+0x103>
    fd = open("bigwrite", O_CREATE | O_RDWR);
     2a6:	20200593          	li	a1,514
     2aa:	8556                	mv	a0,s5
     2ac:	00005097          	auipc	ra,0x5
     2b0:	61a080e7          	jalr	1562(ra) # 58c6 <open>
     2b4:	892a                	mv	s2,a0
    if(fd < 0){
     2b6:	04054d63          	bltz	a0,310 <bigwrite+0xac>
      int cc = write(fd, buf, sz);
     2ba:	8626                	mv	a2,s1
     2bc:	85d2                	mv	a1,s4
     2be:	00005097          	auipc	ra,0x5
     2c2:	5e8080e7          	jalr	1512(ra) # 58a6 <write>
     2c6:	89aa                	mv	s3,a0
      if(cc != sz){
     2c8:	06a49463          	bne	s1,a0,330 <bigwrite+0xcc>
      int cc = write(fd, buf, sz);
     2cc:	8626                	mv	a2,s1
     2ce:	85d2                	mv	a1,s4
     2d0:	854a                	mv	a0,s2
     2d2:	00005097          	auipc	ra,0x5
     2d6:	5d4080e7          	jalr	1492(ra) # 58a6 <write>
      if(cc != sz){
     2da:	04951963          	bne	a0,s1,32c <bigwrite+0xc8>
    close(fd);
     2de:	854a                	mv	a0,s2
     2e0:	00005097          	auipc	ra,0x5
     2e4:	5ce080e7          	jalr	1486(ra) # 58ae <close>
    unlink("bigwrite");
     2e8:	8556                	mv	a0,s5
     2ea:	00005097          	auipc	ra,0x5
     2ee:	5ec080e7          	jalr	1516(ra) # 58d6 <unlink>
  for(sz = 499; sz < (MAXOPBLOCKS+2)*BSIZE; sz += 471){
     2f2:	1d74849b          	addiw	s1,s1,471
     2f6:	fb6498e3          	bne	s1,s6,2a6 <bigwrite+0x42>
}
     2fa:	60a6                	ld	ra,72(sp)
     2fc:	6406                	ld	s0,64(sp)
     2fe:	74e2                	ld	s1,56(sp)
     300:	7942                	ld	s2,48(sp)
     302:	79a2                	ld	s3,40(sp)
     304:	7a02                	ld	s4,32(sp)
     306:	6ae2                	ld	s5,24(sp)
     308:	6b42                	ld	s6,16(sp)
     30a:	6ba2                	ld	s7,8(sp)
     30c:	6161                	addi	sp,sp,80
     30e:	8082                	ret
      printf("%s: cannot create bigwrite\n", s);
     310:	85de                	mv	a1,s7
     312:	00006517          	auipc	a0,0x6
     316:	ece50513          	addi	a0,a0,-306 # 61e0 <malloc+0x50c>
     31a:	00006097          	auipc	ra,0x6
     31e:	8fc080e7          	jalr	-1796(ra) # 5c16 <printf>
      exit(1);
     322:	4505                	li	a0,1
     324:	00005097          	auipc	ra,0x5
     328:	562080e7          	jalr	1378(ra) # 5886 <exit>
     32c:	84ce                	mv	s1,s3
      int cc = write(fd, buf, sz);
     32e:	89aa                	mv	s3,a0
        printf("%s: write(%d) ret %d\n", s, sz, cc);
     330:	86ce                	mv	a3,s3
     332:	8626                	mv	a2,s1
     334:	85de                	mv	a1,s7
     336:	00006517          	auipc	a0,0x6
     33a:	eca50513          	addi	a0,a0,-310 # 6200 <malloc+0x52c>
     33e:	00006097          	auipc	ra,0x6
     342:	8d8080e7          	jalr	-1832(ra) # 5c16 <printf>
        exit(1);
     346:	4505                	li	a0,1
     348:	00005097          	auipc	ra,0x5
     34c:	53e080e7          	jalr	1342(ra) # 5886 <exit>

0000000000000350 <copyin>:
{
     350:	715d                	addi	sp,sp,-80
     352:	e486                	sd	ra,72(sp)
     354:	e0a2                	sd	s0,64(sp)
     356:	fc26                	sd	s1,56(sp)
     358:	f84a                	sd	s2,48(sp)
     35a:	f44e                	sd	s3,40(sp)
     35c:	f052                	sd	s4,32(sp)
     35e:	0880                	addi	s0,sp,80
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };
     360:	4785                	li	a5,1
     362:	07fe                	slli	a5,a5,0x1f
     364:	fcf43023          	sd	a5,-64(s0)
     368:	57fd                	li	a5,-1
     36a:	fcf43423          	sd	a5,-56(s0)
  for(int ai = 0; ai < 2; ai++){
     36e:	fc040913          	addi	s2,s0,-64
    int fd = open("copyin1", O_CREATE|O_WRONLY);
     372:	00006a17          	auipc	s4,0x6
     376:	ea6a0a13          	addi	s4,s4,-346 # 6218 <malloc+0x544>
    uint64 addr = addrs[ai];
     37a:	00093983          	ld	s3,0(s2)
    int fd = open("copyin1", O_CREATE|O_WRONLY);
     37e:	20100593          	li	a1,513
     382:	8552                	mv	a0,s4
     384:	00005097          	auipc	ra,0x5
     388:	542080e7          	jalr	1346(ra) # 58c6 <open>
     38c:	84aa                	mv	s1,a0
    if(fd < 0){
     38e:	08054863          	bltz	a0,41e <copyin+0xce>
    int n = write(fd, (void*)addr, 8192);
     392:	6609                	lui	a2,0x2
     394:	85ce                	mv	a1,s3
     396:	00005097          	auipc	ra,0x5
     39a:	510080e7          	jalr	1296(ra) # 58a6 <write>
    if(n >= 0){
     39e:	08055d63          	bgez	a0,438 <copyin+0xe8>
    close(fd);
     3a2:	8526                	mv	a0,s1
     3a4:	00005097          	auipc	ra,0x5
     3a8:	50a080e7          	jalr	1290(ra) # 58ae <close>
    unlink("copyin1");
     3ac:	8552                	mv	a0,s4
     3ae:	00005097          	auipc	ra,0x5
     3b2:	528080e7          	jalr	1320(ra) # 58d6 <unlink>
    n = write(1, (char*)addr, 8192);
     3b6:	6609                	lui	a2,0x2
     3b8:	85ce                	mv	a1,s3
     3ba:	4505                	li	a0,1
     3bc:	00005097          	auipc	ra,0x5
     3c0:	4ea080e7          	jalr	1258(ra) # 58a6 <write>
    if(n > 0){
     3c4:	08a04963          	bgtz	a0,456 <copyin+0x106>
    if(pipe(fds) < 0){
     3c8:	fb840513          	addi	a0,s0,-72
     3cc:	00005097          	auipc	ra,0x5
     3d0:	4ca080e7          	jalr	1226(ra) # 5896 <pipe>
     3d4:	0a054063          	bltz	a0,474 <copyin+0x124>
    n = write(fds[1], (char*)addr, 8192);
     3d8:	6609                	lui	a2,0x2
     3da:	85ce                	mv	a1,s3
     3dc:	fbc42503          	lw	a0,-68(s0)
     3e0:	00005097          	auipc	ra,0x5
     3e4:	4c6080e7          	jalr	1222(ra) # 58a6 <write>
    if(n > 0){
     3e8:	0aa04363          	bgtz	a0,48e <copyin+0x13e>
    close(fds[0]);
     3ec:	fb842503          	lw	a0,-72(s0)
     3f0:	00005097          	auipc	ra,0x5
     3f4:	4be080e7          	jalr	1214(ra) # 58ae <close>
    close(fds[1]);
     3f8:	fbc42503          	lw	a0,-68(s0)
     3fc:	00005097          	auipc	ra,0x5
     400:	4b2080e7          	jalr	1202(ra) # 58ae <close>
  for(int ai = 0; ai < 2; ai++){
     404:	0921                	addi	s2,s2,8
     406:	fd040793          	addi	a5,s0,-48
     40a:	f6f918e3          	bne	s2,a5,37a <copyin+0x2a>
}
     40e:	60a6                	ld	ra,72(sp)
     410:	6406                	ld	s0,64(sp)
     412:	74e2                	ld	s1,56(sp)
     414:	7942                	ld	s2,48(sp)
     416:	79a2                	ld	s3,40(sp)
     418:	7a02                	ld	s4,32(sp)
     41a:	6161                	addi	sp,sp,80
     41c:	8082                	ret
      printf("open(copyin1) failed\n");
     41e:	00006517          	auipc	a0,0x6
     422:	e0250513          	addi	a0,a0,-510 # 6220 <malloc+0x54c>
     426:	00005097          	auipc	ra,0x5
     42a:	7f0080e7          	jalr	2032(ra) # 5c16 <printf>
      exit(1);
     42e:	4505                	li	a0,1
     430:	00005097          	auipc	ra,0x5
     434:	456080e7          	jalr	1110(ra) # 5886 <exit>
      printf("write(fd, %p, 8192) returned %d, not -1\n", addr, n);
     438:	862a                	mv	a2,a0
     43a:	85ce                	mv	a1,s3
     43c:	00006517          	auipc	a0,0x6
     440:	dfc50513          	addi	a0,a0,-516 # 6238 <malloc+0x564>
     444:	00005097          	auipc	ra,0x5
     448:	7d2080e7          	jalr	2002(ra) # 5c16 <printf>
      exit(1);
     44c:	4505                	li	a0,1
     44e:	00005097          	auipc	ra,0x5
     452:	438080e7          	jalr	1080(ra) # 5886 <exit>
      printf("write(1, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     456:	862a                	mv	a2,a0
     458:	85ce                	mv	a1,s3
     45a:	00006517          	auipc	a0,0x6
     45e:	e0e50513          	addi	a0,a0,-498 # 6268 <malloc+0x594>
     462:	00005097          	auipc	ra,0x5
     466:	7b4080e7          	jalr	1972(ra) # 5c16 <printf>
      exit(1);
     46a:	4505                	li	a0,1
     46c:	00005097          	auipc	ra,0x5
     470:	41a080e7          	jalr	1050(ra) # 5886 <exit>
      printf("pipe() failed\n");
     474:	00006517          	auipc	a0,0x6
     478:	e2450513          	addi	a0,a0,-476 # 6298 <malloc+0x5c4>
     47c:	00005097          	auipc	ra,0x5
     480:	79a080e7          	jalr	1946(ra) # 5c16 <printf>
      exit(1);
     484:	4505                	li	a0,1
     486:	00005097          	auipc	ra,0x5
     48a:	400080e7          	jalr	1024(ra) # 5886 <exit>
      printf("write(pipe, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     48e:	862a                	mv	a2,a0
     490:	85ce                	mv	a1,s3
     492:	00006517          	auipc	a0,0x6
     496:	e1650513          	addi	a0,a0,-490 # 62a8 <malloc+0x5d4>
     49a:	00005097          	auipc	ra,0x5
     49e:	77c080e7          	jalr	1916(ra) # 5c16 <printf>
      exit(1);
     4a2:	4505                	li	a0,1
     4a4:	00005097          	auipc	ra,0x5
     4a8:	3e2080e7          	jalr	994(ra) # 5886 <exit>

00000000000004ac <copyout>:
{
     4ac:	711d                	addi	sp,sp,-96
     4ae:	ec86                	sd	ra,88(sp)
     4b0:	e8a2                	sd	s0,80(sp)
     4b2:	e4a6                	sd	s1,72(sp)
     4b4:	e0ca                	sd	s2,64(sp)
     4b6:	fc4e                	sd	s3,56(sp)
     4b8:	f852                	sd	s4,48(sp)
     4ba:	f456                	sd	s5,40(sp)
     4bc:	1080                	addi	s0,sp,96
  uint64 addrs[] = { 0x80000000LL, 0xffffffffffffffff };
     4be:	4785                	li	a5,1
     4c0:	07fe                	slli	a5,a5,0x1f
     4c2:	faf43823          	sd	a5,-80(s0)
     4c6:	57fd                	li	a5,-1
     4c8:	faf43c23          	sd	a5,-72(s0)
  for(int ai = 0; ai < 2; ai++){
     4cc:	fb040913          	addi	s2,s0,-80
    int fd = open("README", 0);
     4d0:	00006a17          	auipc	s4,0x6
     4d4:	e08a0a13          	addi	s4,s4,-504 # 62d8 <malloc+0x604>
    n = write(fds[1], "x", 1);
     4d8:	00006a97          	auipc	s5,0x6
     4dc:	cd8a8a93          	addi	s5,s5,-808 # 61b0 <malloc+0x4dc>
    uint64 addr = addrs[ai];
     4e0:	00093983          	ld	s3,0(s2)
    int fd = open("README", 0);
     4e4:	4581                	li	a1,0
     4e6:	8552                	mv	a0,s4
     4e8:	00005097          	auipc	ra,0x5
     4ec:	3de080e7          	jalr	990(ra) # 58c6 <open>
     4f0:	84aa                	mv	s1,a0
    if(fd < 0){
     4f2:	08054663          	bltz	a0,57e <copyout+0xd2>
    int n = read(fd, (void*)addr, 8192);
     4f6:	6609                	lui	a2,0x2
     4f8:	85ce                	mv	a1,s3
     4fa:	00005097          	auipc	ra,0x5
     4fe:	3a4080e7          	jalr	932(ra) # 589e <read>
    if(n > 0){
     502:	08a04b63          	bgtz	a0,598 <copyout+0xec>
    close(fd);
     506:	8526                	mv	a0,s1
     508:	00005097          	auipc	ra,0x5
     50c:	3a6080e7          	jalr	934(ra) # 58ae <close>
    if(pipe(fds) < 0){
     510:	fa840513          	addi	a0,s0,-88
     514:	00005097          	auipc	ra,0x5
     518:	382080e7          	jalr	898(ra) # 5896 <pipe>
     51c:	08054d63          	bltz	a0,5b6 <copyout+0x10a>
    n = write(fds[1], "x", 1);
     520:	4605                	li	a2,1
     522:	85d6                	mv	a1,s5
     524:	fac42503          	lw	a0,-84(s0)
     528:	00005097          	auipc	ra,0x5
     52c:	37e080e7          	jalr	894(ra) # 58a6 <write>
    if(n != 1){
     530:	4785                	li	a5,1
     532:	08f51f63          	bne	a0,a5,5d0 <copyout+0x124>
    n = read(fds[0], (void*)addr, 8192);
     536:	6609                	lui	a2,0x2
     538:	85ce                	mv	a1,s3
     53a:	fa842503          	lw	a0,-88(s0)
     53e:	00005097          	auipc	ra,0x5
     542:	360080e7          	jalr	864(ra) # 589e <read>
    if(n > 0){
     546:	0aa04263          	bgtz	a0,5ea <copyout+0x13e>
    close(fds[0]);
     54a:	fa842503          	lw	a0,-88(s0)
     54e:	00005097          	auipc	ra,0x5
     552:	360080e7          	jalr	864(ra) # 58ae <close>
    close(fds[1]);
     556:	fac42503          	lw	a0,-84(s0)
     55a:	00005097          	auipc	ra,0x5
     55e:	354080e7          	jalr	852(ra) # 58ae <close>
  for(int ai = 0; ai < 2; ai++){
     562:	0921                	addi	s2,s2,8
     564:	fc040793          	addi	a5,s0,-64
     568:	f6f91ce3          	bne	s2,a5,4e0 <copyout+0x34>
}
     56c:	60e6                	ld	ra,88(sp)
     56e:	6446                	ld	s0,80(sp)
     570:	64a6                	ld	s1,72(sp)
     572:	6906                	ld	s2,64(sp)
     574:	79e2                	ld	s3,56(sp)
     576:	7a42                	ld	s4,48(sp)
     578:	7aa2                	ld	s5,40(sp)
     57a:	6125                	addi	sp,sp,96
     57c:	8082                	ret
      printf("open(README) failed\n");
     57e:	00006517          	auipc	a0,0x6
     582:	d6250513          	addi	a0,a0,-670 # 62e0 <malloc+0x60c>
     586:	00005097          	auipc	ra,0x5
     58a:	690080e7          	jalr	1680(ra) # 5c16 <printf>
      exit(1);
     58e:	4505                	li	a0,1
     590:	00005097          	auipc	ra,0x5
     594:	2f6080e7          	jalr	758(ra) # 5886 <exit>
      printf("read(fd, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     598:	862a                	mv	a2,a0
     59a:	85ce                	mv	a1,s3
     59c:	00006517          	auipc	a0,0x6
     5a0:	d5c50513          	addi	a0,a0,-676 # 62f8 <malloc+0x624>
     5a4:	00005097          	auipc	ra,0x5
     5a8:	672080e7          	jalr	1650(ra) # 5c16 <printf>
      exit(1);
     5ac:	4505                	li	a0,1
     5ae:	00005097          	auipc	ra,0x5
     5b2:	2d8080e7          	jalr	728(ra) # 5886 <exit>
      printf("pipe() failed\n");
     5b6:	00006517          	auipc	a0,0x6
     5ba:	ce250513          	addi	a0,a0,-798 # 6298 <malloc+0x5c4>
     5be:	00005097          	auipc	ra,0x5
     5c2:	658080e7          	jalr	1624(ra) # 5c16 <printf>
      exit(1);
     5c6:	4505                	li	a0,1
     5c8:	00005097          	auipc	ra,0x5
     5cc:	2be080e7          	jalr	702(ra) # 5886 <exit>
      printf("pipe write failed\n");
     5d0:	00006517          	auipc	a0,0x6
     5d4:	d5850513          	addi	a0,a0,-680 # 6328 <malloc+0x654>
     5d8:	00005097          	auipc	ra,0x5
     5dc:	63e080e7          	jalr	1598(ra) # 5c16 <printf>
      exit(1);
     5e0:	4505                	li	a0,1
     5e2:	00005097          	auipc	ra,0x5
     5e6:	2a4080e7          	jalr	676(ra) # 5886 <exit>
      printf("read(pipe, %p, 8192) returned %d, not -1 or 0\n", addr, n);
     5ea:	862a                	mv	a2,a0
     5ec:	85ce                	mv	a1,s3
     5ee:	00006517          	auipc	a0,0x6
     5f2:	d5250513          	addi	a0,a0,-686 # 6340 <malloc+0x66c>
     5f6:	00005097          	auipc	ra,0x5
     5fa:	620080e7          	jalr	1568(ra) # 5c16 <printf>
      exit(1);
     5fe:	4505                	li	a0,1
     600:	00005097          	auipc	ra,0x5
     604:	286080e7          	jalr	646(ra) # 5886 <exit>

0000000000000608 <truncate1>:
{
     608:	711d                	addi	sp,sp,-96
     60a:	ec86                	sd	ra,88(sp)
     60c:	e8a2                	sd	s0,80(sp)
     60e:	e4a6                	sd	s1,72(sp)
     610:	e0ca                	sd	s2,64(sp)
     612:	fc4e                	sd	s3,56(sp)
     614:	f852                	sd	s4,48(sp)
     616:	f456                	sd	s5,40(sp)
     618:	1080                	addi	s0,sp,96
     61a:	8aaa                	mv	s5,a0
  unlink("truncfile");
     61c:	00006517          	auipc	a0,0x6
     620:	b7c50513          	addi	a0,a0,-1156 # 6198 <malloc+0x4c4>
     624:	00005097          	auipc	ra,0x5
     628:	2b2080e7          	jalr	690(ra) # 58d6 <unlink>
  int fd1 = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
     62c:	60100593          	li	a1,1537
     630:	00006517          	auipc	a0,0x6
     634:	b6850513          	addi	a0,a0,-1176 # 6198 <malloc+0x4c4>
     638:	00005097          	auipc	ra,0x5
     63c:	28e080e7          	jalr	654(ra) # 58c6 <open>
     640:	84aa                	mv	s1,a0
  write(fd1, "abcd", 4);
     642:	4611                	li	a2,4
     644:	00006597          	auipc	a1,0x6
     648:	b6458593          	addi	a1,a1,-1180 # 61a8 <malloc+0x4d4>
     64c:	00005097          	auipc	ra,0x5
     650:	25a080e7          	jalr	602(ra) # 58a6 <write>
  close(fd1);
     654:	8526                	mv	a0,s1
     656:	00005097          	auipc	ra,0x5
     65a:	258080e7          	jalr	600(ra) # 58ae <close>
  int fd2 = open("truncfile", O_RDONLY);
     65e:	4581                	li	a1,0
     660:	00006517          	auipc	a0,0x6
     664:	b3850513          	addi	a0,a0,-1224 # 6198 <malloc+0x4c4>
     668:	00005097          	auipc	ra,0x5
     66c:	25e080e7          	jalr	606(ra) # 58c6 <open>
     670:	84aa                	mv	s1,a0
  int n = read(fd2, buf, sizeof(buf));
     672:	02000613          	li	a2,32
     676:	fa040593          	addi	a1,s0,-96
     67a:	00005097          	auipc	ra,0x5
     67e:	224080e7          	jalr	548(ra) # 589e <read>
  if(n != 4){
     682:	4791                	li	a5,4
     684:	0cf51e63          	bne	a0,a5,760 <truncate1+0x158>
  fd1 = open("truncfile", O_WRONLY|O_TRUNC);
     688:	40100593          	li	a1,1025
     68c:	00006517          	auipc	a0,0x6
     690:	b0c50513          	addi	a0,a0,-1268 # 6198 <malloc+0x4c4>
     694:	00005097          	auipc	ra,0x5
     698:	232080e7          	jalr	562(ra) # 58c6 <open>
     69c:	89aa                	mv	s3,a0
  int fd3 = open("truncfile", O_RDONLY);
     69e:	4581                	li	a1,0
     6a0:	00006517          	auipc	a0,0x6
     6a4:	af850513          	addi	a0,a0,-1288 # 6198 <malloc+0x4c4>
     6a8:	00005097          	auipc	ra,0x5
     6ac:	21e080e7          	jalr	542(ra) # 58c6 <open>
     6b0:	892a                	mv	s2,a0
  n = read(fd3, buf, sizeof(buf));
     6b2:	02000613          	li	a2,32
     6b6:	fa040593          	addi	a1,s0,-96
     6ba:	00005097          	auipc	ra,0x5
     6be:	1e4080e7          	jalr	484(ra) # 589e <read>
     6c2:	8a2a                	mv	s4,a0
  if(n != 0){
     6c4:	ed4d                	bnez	a0,77e <truncate1+0x176>
  n = read(fd2, buf, sizeof(buf));
     6c6:	02000613          	li	a2,32
     6ca:	fa040593          	addi	a1,s0,-96
     6ce:	8526                	mv	a0,s1
     6d0:	00005097          	auipc	ra,0x5
     6d4:	1ce080e7          	jalr	462(ra) # 589e <read>
     6d8:	8a2a                	mv	s4,a0
  if(n != 0){
     6da:	e971                	bnez	a0,7ae <truncate1+0x1a6>
  write(fd1, "abcdef", 6);
     6dc:	4619                	li	a2,6
     6de:	00006597          	auipc	a1,0x6
     6e2:	cf258593          	addi	a1,a1,-782 # 63d0 <malloc+0x6fc>
     6e6:	854e                	mv	a0,s3
     6e8:	00005097          	auipc	ra,0x5
     6ec:	1be080e7          	jalr	446(ra) # 58a6 <write>
  n = read(fd3, buf, sizeof(buf));
     6f0:	02000613          	li	a2,32
     6f4:	fa040593          	addi	a1,s0,-96
     6f8:	854a                	mv	a0,s2
     6fa:	00005097          	auipc	ra,0x5
     6fe:	1a4080e7          	jalr	420(ra) # 589e <read>
  if(n != 6){
     702:	4799                	li	a5,6
     704:	0cf51d63          	bne	a0,a5,7de <truncate1+0x1d6>
  n = read(fd2, buf, sizeof(buf));
     708:	02000613          	li	a2,32
     70c:	fa040593          	addi	a1,s0,-96
     710:	8526                	mv	a0,s1
     712:	00005097          	auipc	ra,0x5
     716:	18c080e7          	jalr	396(ra) # 589e <read>
  if(n != 2){
     71a:	4789                	li	a5,2
     71c:	0ef51063          	bne	a0,a5,7fc <truncate1+0x1f4>
  unlink("truncfile");
     720:	00006517          	auipc	a0,0x6
     724:	a7850513          	addi	a0,a0,-1416 # 6198 <malloc+0x4c4>
     728:	00005097          	auipc	ra,0x5
     72c:	1ae080e7          	jalr	430(ra) # 58d6 <unlink>
  close(fd1);
     730:	854e                	mv	a0,s3
     732:	00005097          	auipc	ra,0x5
     736:	17c080e7          	jalr	380(ra) # 58ae <close>
  close(fd2);
     73a:	8526                	mv	a0,s1
     73c:	00005097          	auipc	ra,0x5
     740:	172080e7          	jalr	370(ra) # 58ae <close>
  close(fd3);
     744:	854a                	mv	a0,s2
     746:	00005097          	auipc	ra,0x5
     74a:	168080e7          	jalr	360(ra) # 58ae <close>
}
     74e:	60e6                	ld	ra,88(sp)
     750:	6446                	ld	s0,80(sp)
     752:	64a6                	ld	s1,72(sp)
     754:	6906                	ld	s2,64(sp)
     756:	79e2                	ld	s3,56(sp)
     758:	7a42                	ld	s4,48(sp)
     75a:	7aa2                	ld	s5,40(sp)
     75c:	6125                	addi	sp,sp,96
     75e:	8082                	ret
    printf("%s: read %d bytes, wanted 4\n", s, n);
     760:	862a                	mv	a2,a0
     762:	85d6                	mv	a1,s5
     764:	00006517          	auipc	a0,0x6
     768:	c0c50513          	addi	a0,a0,-1012 # 6370 <malloc+0x69c>
     76c:	00005097          	auipc	ra,0x5
     770:	4aa080e7          	jalr	1194(ra) # 5c16 <printf>
    exit(1);
     774:	4505                	li	a0,1
     776:	00005097          	auipc	ra,0x5
     77a:	110080e7          	jalr	272(ra) # 5886 <exit>
    printf("aaa fd3=%d\n", fd3);
     77e:	85ca                	mv	a1,s2
     780:	00006517          	auipc	a0,0x6
     784:	c1050513          	addi	a0,a0,-1008 # 6390 <malloc+0x6bc>
     788:	00005097          	auipc	ra,0x5
     78c:	48e080e7          	jalr	1166(ra) # 5c16 <printf>
    printf("%s: read %d bytes, wanted 0\n", s, n);
     790:	8652                	mv	a2,s4
     792:	85d6                	mv	a1,s5
     794:	00006517          	auipc	a0,0x6
     798:	c0c50513          	addi	a0,a0,-1012 # 63a0 <malloc+0x6cc>
     79c:	00005097          	auipc	ra,0x5
     7a0:	47a080e7          	jalr	1146(ra) # 5c16 <printf>
    exit(1);
     7a4:	4505                	li	a0,1
     7a6:	00005097          	auipc	ra,0x5
     7aa:	0e0080e7          	jalr	224(ra) # 5886 <exit>
    printf("bbb fd2=%d\n", fd2);
     7ae:	85a6                	mv	a1,s1
     7b0:	00006517          	auipc	a0,0x6
     7b4:	c1050513          	addi	a0,a0,-1008 # 63c0 <malloc+0x6ec>
     7b8:	00005097          	auipc	ra,0x5
     7bc:	45e080e7          	jalr	1118(ra) # 5c16 <printf>
    printf("%s: read %d bytes, wanted 0\n", s, n);
     7c0:	8652                	mv	a2,s4
     7c2:	85d6                	mv	a1,s5
     7c4:	00006517          	auipc	a0,0x6
     7c8:	bdc50513          	addi	a0,a0,-1060 # 63a0 <malloc+0x6cc>
     7cc:	00005097          	auipc	ra,0x5
     7d0:	44a080e7          	jalr	1098(ra) # 5c16 <printf>
    exit(1);
     7d4:	4505                	li	a0,1
     7d6:	00005097          	auipc	ra,0x5
     7da:	0b0080e7          	jalr	176(ra) # 5886 <exit>
    printf("%s: read %d bytes, wanted 6\n", s, n);
     7de:	862a                	mv	a2,a0
     7e0:	85d6                	mv	a1,s5
     7e2:	00006517          	auipc	a0,0x6
     7e6:	bf650513          	addi	a0,a0,-1034 # 63d8 <malloc+0x704>
     7ea:	00005097          	auipc	ra,0x5
     7ee:	42c080e7          	jalr	1068(ra) # 5c16 <printf>
    exit(1);
     7f2:	4505                	li	a0,1
     7f4:	00005097          	auipc	ra,0x5
     7f8:	092080e7          	jalr	146(ra) # 5886 <exit>
    printf("%s: read %d bytes, wanted 2\n", s, n);
     7fc:	862a                	mv	a2,a0
     7fe:	85d6                	mv	a1,s5
     800:	00006517          	auipc	a0,0x6
     804:	bf850513          	addi	a0,a0,-1032 # 63f8 <malloc+0x724>
     808:	00005097          	auipc	ra,0x5
     80c:	40e080e7          	jalr	1038(ra) # 5c16 <printf>
    exit(1);
     810:	4505                	li	a0,1
     812:	00005097          	auipc	ra,0x5
     816:	074080e7          	jalr	116(ra) # 5886 <exit>

000000000000081a <writetest>:
{
     81a:	7139                	addi	sp,sp,-64
     81c:	fc06                	sd	ra,56(sp)
     81e:	f822                	sd	s0,48(sp)
     820:	f426                	sd	s1,40(sp)
     822:	f04a                	sd	s2,32(sp)
     824:	ec4e                	sd	s3,24(sp)
     826:	e852                	sd	s4,16(sp)
     828:	e456                	sd	s5,8(sp)
     82a:	e05a                	sd	s6,0(sp)
     82c:	0080                	addi	s0,sp,64
     82e:	8b2a                	mv	s6,a0
  fd = open("small", O_CREATE|O_RDWR);
     830:	20200593          	li	a1,514
     834:	00006517          	auipc	a0,0x6
     838:	be450513          	addi	a0,a0,-1052 # 6418 <malloc+0x744>
     83c:	00005097          	auipc	ra,0x5
     840:	08a080e7          	jalr	138(ra) # 58c6 <open>
  if(fd < 0){
     844:	0a054d63          	bltz	a0,8fe <writetest+0xe4>
     848:	892a                	mv	s2,a0
     84a:	4481                	li	s1,0
    if(write(fd, "aaaaaaaaaa", SZ) != SZ){
     84c:	00006997          	auipc	s3,0x6
     850:	bf498993          	addi	s3,s3,-1036 # 6440 <malloc+0x76c>
    if(write(fd, "bbbbbbbbbb", SZ) != SZ){
     854:	00006a97          	auipc	s5,0x6
     858:	c24a8a93          	addi	s5,s5,-988 # 6478 <malloc+0x7a4>
  for(i = 0; i < N; i++){
     85c:	06400a13          	li	s4,100
    if(write(fd, "aaaaaaaaaa", SZ) != SZ){
     860:	4629                	li	a2,10
     862:	85ce                	mv	a1,s3
     864:	854a                	mv	a0,s2
     866:	00005097          	auipc	ra,0x5
     86a:	040080e7          	jalr	64(ra) # 58a6 <write>
     86e:	47a9                	li	a5,10
     870:	0af51563          	bne	a0,a5,91a <writetest+0x100>
    if(write(fd, "bbbbbbbbbb", SZ) != SZ){
     874:	4629                	li	a2,10
     876:	85d6                	mv	a1,s5
     878:	854a                	mv	a0,s2
     87a:	00005097          	auipc	ra,0x5
     87e:	02c080e7          	jalr	44(ra) # 58a6 <write>
     882:	47a9                	li	a5,10
     884:	0af51a63          	bne	a0,a5,938 <writetest+0x11e>
  for(i = 0; i < N; i++){
     888:	2485                	addiw	s1,s1,1
     88a:	fd449be3          	bne	s1,s4,860 <writetest+0x46>
  close(fd);
     88e:	854a                	mv	a0,s2
     890:	00005097          	auipc	ra,0x5
     894:	01e080e7          	jalr	30(ra) # 58ae <close>
  fd = open("small", O_RDONLY);
     898:	4581                	li	a1,0
     89a:	00006517          	auipc	a0,0x6
     89e:	b7e50513          	addi	a0,a0,-1154 # 6418 <malloc+0x744>
     8a2:	00005097          	auipc	ra,0x5
     8a6:	024080e7          	jalr	36(ra) # 58c6 <open>
     8aa:	84aa                	mv	s1,a0
  if(fd < 0){
     8ac:	0a054563          	bltz	a0,956 <writetest+0x13c>
  i = read(fd, buf, N*SZ*2);
     8b0:	7d000613          	li	a2,2000
     8b4:	0000b597          	auipc	a1,0xb
     8b8:	55458593          	addi	a1,a1,1364 # be08 <buf>
     8bc:	00005097          	auipc	ra,0x5
     8c0:	fe2080e7          	jalr	-30(ra) # 589e <read>
  if(i != N*SZ*2){
     8c4:	7d000793          	li	a5,2000
     8c8:	0af51563          	bne	a0,a5,972 <writetest+0x158>
  close(fd);
     8cc:	8526                	mv	a0,s1
     8ce:	00005097          	auipc	ra,0x5
     8d2:	fe0080e7          	jalr	-32(ra) # 58ae <close>
  if(unlink("small") < 0){
     8d6:	00006517          	auipc	a0,0x6
     8da:	b4250513          	addi	a0,a0,-1214 # 6418 <malloc+0x744>
     8de:	00005097          	auipc	ra,0x5
     8e2:	ff8080e7          	jalr	-8(ra) # 58d6 <unlink>
     8e6:	0a054463          	bltz	a0,98e <writetest+0x174>
}
     8ea:	70e2                	ld	ra,56(sp)
     8ec:	7442                	ld	s0,48(sp)
     8ee:	74a2                	ld	s1,40(sp)
     8f0:	7902                	ld	s2,32(sp)
     8f2:	69e2                	ld	s3,24(sp)
     8f4:	6a42                	ld	s4,16(sp)
     8f6:	6aa2                	ld	s5,8(sp)
     8f8:	6b02                	ld	s6,0(sp)
     8fa:	6121                	addi	sp,sp,64
     8fc:	8082                	ret
    printf("%s: error: creat small failed!\n", s);
     8fe:	85da                	mv	a1,s6
     900:	00006517          	auipc	a0,0x6
     904:	b2050513          	addi	a0,a0,-1248 # 6420 <malloc+0x74c>
     908:	00005097          	auipc	ra,0x5
     90c:	30e080e7          	jalr	782(ra) # 5c16 <printf>
    exit(1);
     910:	4505                	li	a0,1
     912:	00005097          	auipc	ra,0x5
     916:	f74080e7          	jalr	-140(ra) # 5886 <exit>
      printf("%s: error: write aa %d new file failed\n", s, i);
     91a:	8626                	mv	a2,s1
     91c:	85da                	mv	a1,s6
     91e:	00006517          	auipc	a0,0x6
     922:	b3250513          	addi	a0,a0,-1230 # 6450 <malloc+0x77c>
     926:	00005097          	auipc	ra,0x5
     92a:	2f0080e7          	jalr	752(ra) # 5c16 <printf>
      exit(1);
     92e:	4505                	li	a0,1
     930:	00005097          	auipc	ra,0x5
     934:	f56080e7          	jalr	-170(ra) # 5886 <exit>
      printf("%s: error: write bb %d new file failed\n", s, i);
     938:	8626                	mv	a2,s1
     93a:	85da                	mv	a1,s6
     93c:	00006517          	auipc	a0,0x6
     940:	b4c50513          	addi	a0,a0,-1204 # 6488 <malloc+0x7b4>
     944:	00005097          	auipc	ra,0x5
     948:	2d2080e7          	jalr	722(ra) # 5c16 <printf>
      exit(1);
     94c:	4505                	li	a0,1
     94e:	00005097          	auipc	ra,0x5
     952:	f38080e7          	jalr	-200(ra) # 5886 <exit>
    printf("%s: error: open small failed!\n", s);
     956:	85da                	mv	a1,s6
     958:	00006517          	auipc	a0,0x6
     95c:	b5850513          	addi	a0,a0,-1192 # 64b0 <malloc+0x7dc>
     960:	00005097          	auipc	ra,0x5
     964:	2b6080e7          	jalr	694(ra) # 5c16 <printf>
    exit(1);
     968:	4505                	li	a0,1
     96a:	00005097          	auipc	ra,0x5
     96e:	f1c080e7          	jalr	-228(ra) # 5886 <exit>
    printf("%s: read failed\n", s);
     972:	85da                	mv	a1,s6
     974:	00006517          	auipc	a0,0x6
     978:	b5c50513          	addi	a0,a0,-1188 # 64d0 <malloc+0x7fc>
     97c:	00005097          	auipc	ra,0x5
     980:	29a080e7          	jalr	666(ra) # 5c16 <printf>
    exit(1);
     984:	4505                	li	a0,1
     986:	00005097          	auipc	ra,0x5
     98a:	f00080e7          	jalr	-256(ra) # 5886 <exit>
    printf("%s: unlink small failed\n", s);
     98e:	85da                	mv	a1,s6
     990:	00006517          	auipc	a0,0x6
     994:	b5850513          	addi	a0,a0,-1192 # 64e8 <malloc+0x814>
     998:	00005097          	auipc	ra,0x5
     99c:	27e080e7          	jalr	638(ra) # 5c16 <printf>
    exit(1);
     9a0:	4505                	li	a0,1
     9a2:	00005097          	auipc	ra,0x5
     9a6:	ee4080e7          	jalr	-284(ra) # 5886 <exit>

00000000000009aa <writebig>:
{
     9aa:	7139                	addi	sp,sp,-64
     9ac:	fc06                	sd	ra,56(sp)
     9ae:	f822                	sd	s0,48(sp)
     9b0:	f426                	sd	s1,40(sp)
     9b2:	f04a                	sd	s2,32(sp)
     9b4:	ec4e                	sd	s3,24(sp)
     9b6:	e852                	sd	s4,16(sp)
     9b8:	e456                	sd	s5,8(sp)
     9ba:	0080                	addi	s0,sp,64
     9bc:	8aaa                	mv	s5,a0
  fd = open("big", O_CREATE|O_RDWR);
     9be:	20200593          	li	a1,514
     9c2:	00006517          	auipc	a0,0x6
     9c6:	b4650513          	addi	a0,a0,-1210 # 6508 <malloc+0x834>
     9ca:	00005097          	auipc	ra,0x5
     9ce:	efc080e7          	jalr	-260(ra) # 58c6 <open>
     9d2:	89aa                	mv	s3,a0
  for(i = 0; i < MAXFILE; i++){
     9d4:	4481                	li	s1,0
    ((int*)buf)[0] = i;
     9d6:	0000b917          	auipc	s2,0xb
     9da:	43290913          	addi	s2,s2,1074 # be08 <buf>
  for(i = 0; i < MAXFILE; i++){
     9de:	10c00a13          	li	s4,268
  if(fd < 0){
     9e2:	06054c63          	bltz	a0,a5a <writebig+0xb0>
    ((int*)buf)[0] = i;
     9e6:	00992023          	sw	s1,0(s2)
    if(write(fd, buf, BSIZE) != BSIZE){
     9ea:	40000613          	li	a2,1024
     9ee:	85ca                	mv	a1,s2
     9f0:	854e                	mv	a0,s3
     9f2:	00005097          	auipc	ra,0x5
     9f6:	eb4080e7          	jalr	-332(ra) # 58a6 <write>
     9fa:	40000793          	li	a5,1024
     9fe:	06f51c63          	bne	a0,a5,a76 <writebig+0xcc>
  for(i = 0; i < MAXFILE; i++){
     a02:	2485                	addiw	s1,s1,1
     a04:	ff4491e3          	bne	s1,s4,9e6 <writebig+0x3c>
  close(fd);
     a08:	854e                	mv	a0,s3
     a0a:	00005097          	auipc	ra,0x5
     a0e:	ea4080e7          	jalr	-348(ra) # 58ae <close>
  fd = open("big", O_RDONLY);
     a12:	4581                	li	a1,0
     a14:	00006517          	auipc	a0,0x6
     a18:	af450513          	addi	a0,a0,-1292 # 6508 <malloc+0x834>
     a1c:	00005097          	auipc	ra,0x5
     a20:	eaa080e7          	jalr	-342(ra) # 58c6 <open>
     a24:	89aa                	mv	s3,a0
  n = 0;
     a26:	4481                	li	s1,0
    i = read(fd, buf, BSIZE);
     a28:	0000b917          	auipc	s2,0xb
     a2c:	3e090913          	addi	s2,s2,992 # be08 <buf>
  if(fd < 0){
     a30:	06054263          	bltz	a0,a94 <writebig+0xea>
    i = read(fd, buf, BSIZE);
     a34:	40000613          	li	a2,1024
     a38:	85ca                	mv	a1,s2
     a3a:	854e                	mv	a0,s3
     a3c:	00005097          	auipc	ra,0x5
     a40:	e62080e7          	jalr	-414(ra) # 589e <read>
    if(i == 0){
     a44:	c535                	beqz	a0,ab0 <writebig+0x106>
    } else if(i != BSIZE){
     a46:	40000793          	li	a5,1024
     a4a:	0af51f63          	bne	a0,a5,b08 <writebig+0x15e>
    if(((int*)buf)[0] != n){
     a4e:	00092683          	lw	a3,0(s2)
     a52:	0c969a63          	bne	a3,s1,b26 <writebig+0x17c>
    n++;
     a56:	2485                	addiw	s1,s1,1
    i = read(fd, buf, BSIZE);
     a58:	bff1                	j	a34 <writebig+0x8a>
    printf("%s: error: creat big failed!\n", s);
     a5a:	85d6                	mv	a1,s5
     a5c:	00006517          	auipc	a0,0x6
     a60:	ab450513          	addi	a0,a0,-1356 # 6510 <malloc+0x83c>
     a64:	00005097          	auipc	ra,0x5
     a68:	1b2080e7          	jalr	434(ra) # 5c16 <printf>
    exit(1);
     a6c:	4505                	li	a0,1
     a6e:	00005097          	auipc	ra,0x5
     a72:	e18080e7          	jalr	-488(ra) # 5886 <exit>
      printf("%s: error: write big file failed\n", s, i);
     a76:	8626                	mv	a2,s1
     a78:	85d6                	mv	a1,s5
     a7a:	00006517          	auipc	a0,0x6
     a7e:	ab650513          	addi	a0,a0,-1354 # 6530 <malloc+0x85c>
     a82:	00005097          	auipc	ra,0x5
     a86:	194080e7          	jalr	404(ra) # 5c16 <printf>
      exit(1);
     a8a:	4505                	li	a0,1
     a8c:	00005097          	auipc	ra,0x5
     a90:	dfa080e7          	jalr	-518(ra) # 5886 <exit>
    printf("%s: error: open big failed!\n", s);
     a94:	85d6                	mv	a1,s5
     a96:	00006517          	auipc	a0,0x6
     a9a:	ac250513          	addi	a0,a0,-1342 # 6558 <malloc+0x884>
     a9e:	00005097          	auipc	ra,0x5
     aa2:	178080e7          	jalr	376(ra) # 5c16 <printf>
    exit(1);
     aa6:	4505                	li	a0,1
     aa8:	00005097          	auipc	ra,0x5
     aac:	dde080e7          	jalr	-546(ra) # 5886 <exit>
      if(n == MAXFILE - 1){
     ab0:	10b00793          	li	a5,267
     ab4:	02f48a63          	beq	s1,a5,ae8 <writebig+0x13e>
  close(fd);
     ab8:	854e                	mv	a0,s3
     aba:	00005097          	auipc	ra,0x5
     abe:	df4080e7          	jalr	-524(ra) # 58ae <close>
  if(unlink("big") < 0){
     ac2:	00006517          	auipc	a0,0x6
     ac6:	a4650513          	addi	a0,a0,-1466 # 6508 <malloc+0x834>
     aca:	00005097          	auipc	ra,0x5
     ace:	e0c080e7          	jalr	-500(ra) # 58d6 <unlink>
     ad2:	06054963          	bltz	a0,b44 <writebig+0x19a>
}
     ad6:	70e2                	ld	ra,56(sp)
     ad8:	7442                	ld	s0,48(sp)
     ada:	74a2                	ld	s1,40(sp)
     adc:	7902                	ld	s2,32(sp)
     ade:	69e2                	ld	s3,24(sp)
     ae0:	6a42                	ld	s4,16(sp)
     ae2:	6aa2                	ld	s5,8(sp)
     ae4:	6121                	addi	sp,sp,64
     ae6:	8082                	ret
        printf("%s: read only %d blocks from big", s, n);
     ae8:	10b00613          	li	a2,267
     aec:	85d6                	mv	a1,s5
     aee:	00006517          	auipc	a0,0x6
     af2:	a8a50513          	addi	a0,a0,-1398 # 6578 <malloc+0x8a4>
     af6:	00005097          	auipc	ra,0x5
     afa:	120080e7          	jalr	288(ra) # 5c16 <printf>
        exit(1);
     afe:	4505                	li	a0,1
     b00:	00005097          	auipc	ra,0x5
     b04:	d86080e7          	jalr	-634(ra) # 5886 <exit>
      printf("%s: read failed %d\n", s, i);
     b08:	862a                	mv	a2,a0
     b0a:	85d6                	mv	a1,s5
     b0c:	00006517          	auipc	a0,0x6
     b10:	a9450513          	addi	a0,a0,-1388 # 65a0 <malloc+0x8cc>
     b14:	00005097          	auipc	ra,0x5
     b18:	102080e7          	jalr	258(ra) # 5c16 <printf>
      exit(1);
     b1c:	4505                	li	a0,1
     b1e:	00005097          	auipc	ra,0x5
     b22:	d68080e7          	jalr	-664(ra) # 5886 <exit>
      printf("%s: read content of block %d is %d\n", s,
     b26:	8626                	mv	a2,s1
     b28:	85d6                	mv	a1,s5
     b2a:	00006517          	auipc	a0,0x6
     b2e:	a8e50513          	addi	a0,a0,-1394 # 65b8 <malloc+0x8e4>
     b32:	00005097          	auipc	ra,0x5
     b36:	0e4080e7          	jalr	228(ra) # 5c16 <printf>
      exit(1);
     b3a:	4505                	li	a0,1
     b3c:	00005097          	auipc	ra,0x5
     b40:	d4a080e7          	jalr	-694(ra) # 5886 <exit>
    printf("%s: unlink big failed\n", s);
     b44:	85d6                	mv	a1,s5
     b46:	00006517          	auipc	a0,0x6
     b4a:	a9a50513          	addi	a0,a0,-1382 # 65e0 <malloc+0x90c>
     b4e:	00005097          	auipc	ra,0x5
     b52:	0c8080e7          	jalr	200(ra) # 5c16 <printf>
    exit(1);
     b56:	4505                	li	a0,1
     b58:	00005097          	auipc	ra,0x5
     b5c:	d2e080e7          	jalr	-722(ra) # 5886 <exit>

0000000000000b60 <unlinkread>:
{
     b60:	7179                	addi	sp,sp,-48
     b62:	f406                	sd	ra,40(sp)
     b64:	f022                	sd	s0,32(sp)
     b66:	ec26                	sd	s1,24(sp)
     b68:	e84a                	sd	s2,16(sp)
     b6a:	e44e                	sd	s3,8(sp)
     b6c:	1800                	addi	s0,sp,48
     b6e:	89aa                	mv	s3,a0
  fd = open("unlinkread", O_CREATE | O_RDWR);
     b70:	20200593          	li	a1,514
     b74:	00005517          	auipc	a0,0x5
     b78:	3a450513          	addi	a0,a0,932 # 5f18 <malloc+0x244>
     b7c:	00005097          	auipc	ra,0x5
     b80:	d4a080e7          	jalr	-694(ra) # 58c6 <open>
  if(fd < 0){
     b84:	0e054563          	bltz	a0,c6e <unlinkread+0x10e>
     b88:	84aa                	mv	s1,a0
  write(fd, "hello", SZ);
     b8a:	4615                	li	a2,5
     b8c:	00006597          	auipc	a1,0x6
     b90:	a8c58593          	addi	a1,a1,-1396 # 6618 <malloc+0x944>
     b94:	00005097          	auipc	ra,0x5
     b98:	d12080e7          	jalr	-750(ra) # 58a6 <write>
  close(fd);
     b9c:	8526                	mv	a0,s1
     b9e:	00005097          	auipc	ra,0x5
     ba2:	d10080e7          	jalr	-752(ra) # 58ae <close>
  fd = open("unlinkread", O_RDWR);
     ba6:	4589                	li	a1,2
     ba8:	00005517          	auipc	a0,0x5
     bac:	37050513          	addi	a0,a0,880 # 5f18 <malloc+0x244>
     bb0:	00005097          	auipc	ra,0x5
     bb4:	d16080e7          	jalr	-746(ra) # 58c6 <open>
     bb8:	84aa                	mv	s1,a0
  if(fd < 0){
     bba:	0c054863          	bltz	a0,c8a <unlinkread+0x12a>
  if(unlink("unlinkread") != 0){
     bbe:	00005517          	auipc	a0,0x5
     bc2:	35a50513          	addi	a0,a0,858 # 5f18 <malloc+0x244>
     bc6:	00005097          	auipc	ra,0x5
     bca:	d10080e7          	jalr	-752(ra) # 58d6 <unlink>
     bce:	ed61                	bnez	a0,ca6 <unlinkread+0x146>
  fd1 = open("unlinkread", O_CREATE | O_RDWR);
     bd0:	20200593          	li	a1,514
     bd4:	00005517          	auipc	a0,0x5
     bd8:	34450513          	addi	a0,a0,836 # 5f18 <malloc+0x244>
     bdc:	00005097          	auipc	ra,0x5
     be0:	cea080e7          	jalr	-790(ra) # 58c6 <open>
     be4:	892a                	mv	s2,a0
  write(fd1, "yyy", 3);
     be6:	460d                	li	a2,3
     be8:	00006597          	auipc	a1,0x6
     bec:	a7858593          	addi	a1,a1,-1416 # 6660 <malloc+0x98c>
     bf0:	00005097          	auipc	ra,0x5
     bf4:	cb6080e7          	jalr	-842(ra) # 58a6 <write>
  close(fd1);
     bf8:	854a                	mv	a0,s2
     bfa:	00005097          	auipc	ra,0x5
     bfe:	cb4080e7          	jalr	-844(ra) # 58ae <close>
  if(read(fd, buf, sizeof(buf)) != SZ){
     c02:	660d                	lui	a2,0x3
     c04:	0000b597          	auipc	a1,0xb
     c08:	20458593          	addi	a1,a1,516 # be08 <buf>
     c0c:	8526                	mv	a0,s1
     c0e:	00005097          	auipc	ra,0x5
     c12:	c90080e7          	jalr	-880(ra) # 589e <read>
     c16:	4795                	li	a5,5
     c18:	0af51563          	bne	a0,a5,cc2 <unlinkread+0x162>
  if(buf[0] != 'h'){
     c1c:	0000b717          	auipc	a4,0xb
     c20:	1ec74703          	lbu	a4,492(a4) # be08 <buf>
     c24:	06800793          	li	a5,104
     c28:	0af71b63          	bne	a4,a5,cde <unlinkread+0x17e>
  if(write(fd, buf, 10) != 10){
     c2c:	4629                	li	a2,10
     c2e:	0000b597          	auipc	a1,0xb
     c32:	1da58593          	addi	a1,a1,474 # be08 <buf>
     c36:	8526                	mv	a0,s1
     c38:	00005097          	auipc	ra,0x5
     c3c:	c6e080e7          	jalr	-914(ra) # 58a6 <write>
     c40:	47a9                	li	a5,10
     c42:	0af51c63          	bne	a0,a5,cfa <unlinkread+0x19a>
  close(fd);
     c46:	8526                	mv	a0,s1
     c48:	00005097          	auipc	ra,0x5
     c4c:	c66080e7          	jalr	-922(ra) # 58ae <close>
  unlink("unlinkread");
     c50:	00005517          	auipc	a0,0x5
     c54:	2c850513          	addi	a0,a0,712 # 5f18 <malloc+0x244>
     c58:	00005097          	auipc	ra,0x5
     c5c:	c7e080e7          	jalr	-898(ra) # 58d6 <unlink>
}
     c60:	70a2                	ld	ra,40(sp)
     c62:	7402                	ld	s0,32(sp)
     c64:	64e2                	ld	s1,24(sp)
     c66:	6942                	ld	s2,16(sp)
     c68:	69a2                	ld	s3,8(sp)
     c6a:	6145                	addi	sp,sp,48
     c6c:	8082                	ret
    printf("%s: create unlinkread failed\n", s);
     c6e:	85ce                	mv	a1,s3
     c70:	00006517          	auipc	a0,0x6
     c74:	98850513          	addi	a0,a0,-1656 # 65f8 <malloc+0x924>
     c78:	00005097          	auipc	ra,0x5
     c7c:	f9e080e7          	jalr	-98(ra) # 5c16 <printf>
    exit(1);
     c80:	4505                	li	a0,1
     c82:	00005097          	auipc	ra,0x5
     c86:	c04080e7          	jalr	-1020(ra) # 5886 <exit>
    printf("%s: open unlinkread failed\n", s);
     c8a:	85ce                	mv	a1,s3
     c8c:	00006517          	auipc	a0,0x6
     c90:	99450513          	addi	a0,a0,-1644 # 6620 <malloc+0x94c>
     c94:	00005097          	auipc	ra,0x5
     c98:	f82080e7          	jalr	-126(ra) # 5c16 <printf>
    exit(1);
     c9c:	4505                	li	a0,1
     c9e:	00005097          	auipc	ra,0x5
     ca2:	be8080e7          	jalr	-1048(ra) # 5886 <exit>
    printf("%s: unlink unlinkread failed\n", s);
     ca6:	85ce                	mv	a1,s3
     ca8:	00006517          	auipc	a0,0x6
     cac:	99850513          	addi	a0,a0,-1640 # 6640 <malloc+0x96c>
     cb0:	00005097          	auipc	ra,0x5
     cb4:	f66080e7          	jalr	-154(ra) # 5c16 <printf>
    exit(1);
     cb8:	4505                	li	a0,1
     cba:	00005097          	auipc	ra,0x5
     cbe:	bcc080e7          	jalr	-1076(ra) # 5886 <exit>
    printf("%s: unlinkread read failed", s);
     cc2:	85ce                	mv	a1,s3
     cc4:	00006517          	auipc	a0,0x6
     cc8:	9a450513          	addi	a0,a0,-1628 # 6668 <malloc+0x994>
     ccc:	00005097          	auipc	ra,0x5
     cd0:	f4a080e7          	jalr	-182(ra) # 5c16 <printf>
    exit(1);
     cd4:	4505                	li	a0,1
     cd6:	00005097          	auipc	ra,0x5
     cda:	bb0080e7          	jalr	-1104(ra) # 5886 <exit>
    printf("%s: unlinkread wrong data\n", s);
     cde:	85ce                	mv	a1,s3
     ce0:	00006517          	auipc	a0,0x6
     ce4:	9a850513          	addi	a0,a0,-1624 # 6688 <malloc+0x9b4>
     ce8:	00005097          	auipc	ra,0x5
     cec:	f2e080e7          	jalr	-210(ra) # 5c16 <printf>
    exit(1);
     cf0:	4505                	li	a0,1
     cf2:	00005097          	auipc	ra,0x5
     cf6:	b94080e7          	jalr	-1132(ra) # 5886 <exit>
    printf("%s: unlinkread write failed\n", s);
     cfa:	85ce                	mv	a1,s3
     cfc:	00006517          	auipc	a0,0x6
     d00:	9ac50513          	addi	a0,a0,-1620 # 66a8 <malloc+0x9d4>
     d04:	00005097          	auipc	ra,0x5
     d08:	f12080e7          	jalr	-238(ra) # 5c16 <printf>
    exit(1);
     d0c:	4505                	li	a0,1
     d0e:	00005097          	auipc	ra,0x5
     d12:	b78080e7          	jalr	-1160(ra) # 5886 <exit>

0000000000000d16 <linktest>:
{
     d16:	1101                	addi	sp,sp,-32
     d18:	ec06                	sd	ra,24(sp)
     d1a:	e822                	sd	s0,16(sp)
     d1c:	e426                	sd	s1,8(sp)
     d1e:	e04a                	sd	s2,0(sp)
     d20:	1000                	addi	s0,sp,32
     d22:	892a                	mv	s2,a0
  unlink("lf1");
     d24:	00006517          	auipc	a0,0x6
     d28:	9a450513          	addi	a0,a0,-1628 # 66c8 <malloc+0x9f4>
     d2c:	00005097          	auipc	ra,0x5
     d30:	baa080e7          	jalr	-1110(ra) # 58d6 <unlink>
  unlink("lf2");
     d34:	00006517          	auipc	a0,0x6
     d38:	99c50513          	addi	a0,a0,-1636 # 66d0 <malloc+0x9fc>
     d3c:	00005097          	auipc	ra,0x5
     d40:	b9a080e7          	jalr	-1126(ra) # 58d6 <unlink>
  fd = open("lf1", O_CREATE|O_RDWR);
     d44:	20200593          	li	a1,514
     d48:	00006517          	auipc	a0,0x6
     d4c:	98050513          	addi	a0,a0,-1664 # 66c8 <malloc+0x9f4>
     d50:	00005097          	auipc	ra,0x5
     d54:	b76080e7          	jalr	-1162(ra) # 58c6 <open>
  if(fd < 0){
     d58:	10054763          	bltz	a0,e66 <linktest+0x150>
     d5c:	84aa                	mv	s1,a0
  if(write(fd, "hello", SZ) != SZ){
     d5e:	4615                	li	a2,5
     d60:	00006597          	auipc	a1,0x6
     d64:	8b858593          	addi	a1,a1,-1864 # 6618 <malloc+0x944>
     d68:	00005097          	auipc	ra,0x5
     d6c:	b3e080e7          	jalr	-1218(ra) # 58a6 <write>
     d70:	4795                	li	a5,5
     d72:	10f51863          	bne	a0,a5,e82 <linktest+0x16c>
  close(fd);
     d76:	8526                	mv	a0,s1
     d78:	00005097          	auipc	ra,0x5
     d7c:	b36080e7          	jalr	-1226(ra) # 58ae <close>
  if(link("lf1", "lf2") < 0){
     d80:	00006597          	auipc	a1,0x6
     d84:	95058593          	addi	a1,a1,-1712 # 66d0 <malloc+0x9fc>
     d88:	00006517          	auipc	a0,0x6
     d8c:	94050513          	addi	a0,a0,-1728 # 66c8 <malloc+0x9f4>
     d90:	00005097          	auipc	ra,0x5
     d94:	b56080e7          	jalr	-1194(ra) # 58e6 <link>
     d98:	10054363          	bltz	a0,e9e <linktest+0x188>
  unlink("lf1");
     d9c:	00006517          	auipc	a0,0x6
     da0:	92c50513          	addi	a0,a0,-1748 # 66c8 <malloc+0x9f4>
     da4:	00005097          	auipc	ra,0x5
     da8:	b32080e7          	jalr	-1230(ra) # 58d6 <unlink>
  if(open("lf1", 0) >= 0){
     dac:	4581                	li	a1,0
     dae:	00006517          	auipc	a0,0x6
     db2:	91a50513          	addi	a0,a0,-1766 # 66c8 <malloc+0x9f4>
     db6:	00005097          	auipc	ra,0x5
     dba:	b10080e7          	jalr	-1264(ra) # 58c6 <open>
     dbe:	0e055e63          	bgez	a0,eba <linktest+0x1a4>
  fd = open("lf2", 0);
     dc2:	4581                	li	a1,0
     dc4:	00006517          	auipc	a0,0x6
     dc8:	90c50513          	addi	a0,a0,-1780 # 66d0 <malloc+0x9fc>
     dcc:	00005097          	auipc	ra,0x5
     dd0:	afa080e7          	jalr	-1286(ra) # 58c6 <open>
     dd4:	84aa                	mv	s1,a0
  if(fd < 0){
     dd6:	10054063          	bltz	a0,ed6 <linktest+0x1c0>
  if(read(fd, buf, sizeof(buf)) != SZ){
     dda:	660d                	lui	a2,0x3
     ddc:	0000b597          	auipc	a1,0xb
     de0:	02c58593          	addi	a1,a1,44 # be08 <buf>
     de4:	00005097          	auipc	ra,0x5
     de8:	aba080e7          	jalr	-1350(ra) # 589e <read>
     dec:	4795                	li	a5,5
     dee:	10f51263          	bne	a0,a5,ef2 <linktest+0x1dc>
  close(fd);
     df2:	8526                	mv	a0,s1
     df4:	00005097          	auipc	ra,0x5
     df8:	aba080e7          	jalr	-1350(ra) # 58ae <close>
  if(link("lf2", "lf2") >= 0){
     dfc:	00006597          	auipc	a1,0x6
     e00:	8d458593          	addi	a1,a1,-1836 # 66d0 <malloc+0x9fc>
     e04:	852e                	mv	a0,a1
     e06:	00005097          	auipc	ra,0x5
     e0a:	ae0080e7          	jalr	-1312(ra) # 58e6 <link>
     e0e:	10055063          	bgez	a0,f0e <linktest+0x1f8>
  unlink("lf2");
     e12:	00006517          	auipc	a0,0x6
     e16:	8be50513          	addi	a0,a0,-1858 # 66d0 <malloc+0x9fc>
     e1a:	00005097          	auipc	ra,0x5
     e1e:	abc080e7          	jalr	-1348(ra) # 58d6 <unlink>
  if(link("lf2", "lf1") >= 0){
     e22:	00006597          	auipc	a1,0x6
     e26:	8a658593          	addi	a1,a1,-1882 # 66c8 <malloc+0x9f4>
     e2a:	00006517          	auipc	a0,0x6
     e2e:	8a650513          	addi	a0,a0,-1882 # 66d0 <malloc+0x9fc>
     e32:	00005097          	auipc	ra,0x5
     e36:	ab4080e7          	jalr	-1356(ra) # 58e6 <link>
     e3a:	0e055863          	bgez	a0,f2a <linktest+0x214>
  if(link(".", "lf1") >= 0){
     e3e:	00006597          	auipc	a1,0x6
     e42:	88a58593          	addi	a1,a1,-1910 # 66c8 <malloc+0x9f4>
     e46:	00006517          	auipc	a0,0x6
     e4a:	99250513          	addi	a0,a0,-1646 # 67d8 <malloc+0xb04>
     e4e:	00005097          	auipc	ra,0x5
     e52:	a98080e7          	jalr	-1384(ra) # 58e6 <link>
     e56:	0e055863          	bgez	a0,f46 <linktest+0x230>
}
     e5a:	60e2                	ld	ra,24(sp)
     e5c:	6442                	ld	s0,16(sp)
     e5e:	64a2                	ld	s1,8(sp)
     e60:	6902                	ld	s2,0(sp)
     e62:	6105                	addi	sp,sp,32
     e64:	8082                	ret
    printf("%s: create lf1 failed\n", s);
     e66:	85ca                	mv	a1,s2
     e68:	00006517          	auipc	a0,0x6
     e6c:	87050513          	addi	a0,a0,-1936 # 66d8 <malloc+0xa04>
     e70:	00005097          	auipc	ra,0x5
     e74:	da6080e7          	jalr	-602(ra) # 5c16 <printf>
    exit(1);
     e78:	4505                	li	a0,1
     e7a:	00005097          	auipc	ra,0x5
     e7e:	a0c080e7          	jalr	-1524(ra) # 5886 <exit>
    printf("%s: write lf1 failed\n", s);
     e82:	85ca                	mv	a1,s2
     e84:	00006517          	auipc	a0,0x6
     e88:	86c50513          	addi	a0,a0,-1940 # 66f0 <malloc+0xa1c>
     e8c:	00005097          	auipc	ra,0x5
     e90:	d8a080e7          	jalr	-630(ra) # 5c16 <printf>
    exit(1);
     e94:	4505                	li	a0,1
     e96:	00005097          	auipc	ra,0x5
     e9a:	9f0080e7          	jalr	-1552(ra) # 5886 <exit>
    printf("%s: link lf1 lf2 failed\n", s);
     e9e:	85ca                	mv	a1,s2
     ea0:	00006517          	auipc	a0,0x6
     ea4:	86850513          	addi	a0,a0,-1944 # 6708 <malloc+0xa34>
     ea8:	00005097          	auipc	ra,0x5
     eac:	d6e080e7          	jalr	-658(ra) # 5c16 <printf>
    exit(1);
     eb0:	4505                	li	a0,1
     eb2:	00005097          	auipc	ra,0x5
     eb6:	9d4080e7          	jalr	-1580(ra) # 5886 <exit>
    printf("%s: unlinked lf1 but it is still there!\n", s);
     eba:	85ca                	mv	a1,s2
     ebc:	00006517          	auipc	a0,0x6
     ec0:	86c50513          	addi	a0,a0,-1940 # 6728 <malloc+0xa54>
     ec4:	00005097          	auipc	ra,0x5
     ec8:	d52080e7          	jalr	-686(ra) # 5c16 <printf>
    exit(1);
     ecc:	4505                	li	a0,1
     ece:	00005097          	auipc	ra,0x5
     ed2:	9b8080e7          	jalr	-1608(ra) # 5886 <exit>
    printf("%s: open lf2 failed\n", s);
     ed6:	85ca                	mv	a1,s2
     ed8:	00006517          	auipc	a0,0x6
     edc:	88050513          	addi	a0,a0,-1920 # 6758 <malloc+0xa84>
     ee0:	00005097          	auipc	ra,0x5
     ee4:	d36080e7          	jalr	-714(ra) # 5c16 <printf>
    exit(1);
     ee8:	4505                	li	a0,1
     eea:	00005097          	auipc	ra,0x5
     eee:	99c080e7          	jalr	-1636(ra) # 5886 <exit>
    printf("%s: read lf2 failed\n", s);
     ef2:	85ca                	mv	a1,s2
     ef4:	00006517          	auipc	a0,0x6
     ef8:	87c50513          	addi	a0,a0,-1924 # 6770 <malloc+0xa9c>
     efc:	00005097          	auipc	ra,0x5
     f00:	d1a080e7          	jalr	-742(ra) # 5c16 <printf>
    exit(1);
     f04:	4505                	li	a0,1
     f06:	00005097          	auipc	ra,0x5
     f0a:	980080e7          	jalr	-1664(ra) # 5886 <exit>
    printf("%s: link lf2 lf2 succeeded! oops\n", s);
     f0e:	85ca                	mv	a1,s2
     f10:	00006517          	auipc	a0,0x6
     f14:	87850513          	addi	a0,a0,-1928 # 6788 <malloc+0xab4>
     f18:	00005097          	auipc	ra,0x5
     f1c:	cfe080e7          	jalr	-770(ra) # 5c16 <printf>
    exit(1);
     f20:	4505                	li	a0,1
     f22:	00005097          	auipc	ra,0x5
     f26:	964080e7          	jalr	-1692(ra) # 5886 <exit>
    printf("%s: link non-existent succeeded! oops\n", s);
     f2a:	85ca                	mv	a1,s2
     f2c:	00006517          	auipc	a0,0x6
     f30:	88450513          	addi	a0,a0,-1916 # 67b0 <malloc+0xadc>
     f34:	00005097          	auipc	ra,0x5
     f38:	ce2080e7          	jalr	-798(ra) # 5c16 <printf>
    exit(1);
     f3c:	4505                	li	a0,1
     f3e:	00005097          	auipc	ra,0x5
     f42:	948080e7          	jalr	-1720(ra) # 5886 <exit>
    printf("%s: link . lf1 succeeded! oops\n", s);
     f46:	85ca                	mv	a1,s2
     f48:	00006517          	auipc	a0,0x6
     f4c:	89850513          	addi	a0,a0,-1896 # 67e0 <malloc+0xb0c>
     f50:	00005097          	auipc	ra,0x5
     f54:	cc6080e7          	jalr	-826(ra) # 5c16 <printf>
    exit(1);
     f58:	4505                	li	a0,1
     f5a:	00005097          	auipc	ra,0x5
     f5e:	92c080e7          	jalr	-1748(ra) # 5886 <exit>

0000000000000f62 <bigdir>:
{
     f62:	715d                	addi	sp,sp,-80
     f64:	e486                	sd	ra,72(sp)
     f66:	e0a2                	sd	s0,64(sp)
     f68:	fc26                	sd	s1,56(sp)
     f6a:	f84a                	sd	s2,48(sp)
     f6c:	f44e                	sd	s3,40(sp)
     f6e:	f052                	sd	s4,32(sp)
     f70:	ec56                	sd	s5,24(sp)
     f72:	e85a                	sd	s6,16(sp)
     f74:	0880                	addi	s0,sp,80
     f76:	89aa                	mv	s3,a0
  unlink("bd");
     f78:	00006517          	auipc	a0,0x6
     f7c:	88850513          	addi	a0,a0,-1912 # 6800 <malloc+0xb2c>
     f80:	00005097          	auipc	ra,0x5
     f84:	956080e7          	jalr	-1706(ra) # 58d6 <unlink>
  fd = open("bd", O_CREATE);
     f88:	20000593          	li	a1,512
     f8c:	00006517          	auipc	a0,0x6
     f90:	87450513          	addi	a0,a0,-1932 # 6800 <malloc+0xb2c>
     f94:	00005097          	auipc	ra,0x5
     f98:	932080e7          	jalr	-1742(ra) # 58c6 <open>
  if(fd < 0){
     f9c:	0c054963          	bltz	a0,106e <bigdir+0x10c>
  close(fd);
     fa0:	00005097          	auipc	ra,0x5
     fa4:	90e080e7          	jalr	-1778(ra) # 58ae <close>
  for(i = 0; i < N; i++){
     fa8:	4901                	li	s2,0
    name[0] = 'x';
     faa:	07800a93          	li	s5,120
    if(link("bd", name) != 0){
     fae:	00006a17          	auipc	s4,0x6
     fb2:	852a0a13          	addi	s4,s4,-1966 # 6800 <malloc+0xb2c>
  for(i = 0; i < N; i++){
     fb6:	1f400b13          	li	s6,500
    name[0] = 'x';
     fba:	fb540823          	sb	s5,-80(s0)
    name[1] = '0' + (i / 64);
     fbe:	41f9579b          	sraiw	a5,s2,0x1f
     fc2:	01a7d71b          	srliw	a4,a5,0x1a
     fc6:	012707bb          	addw	a5,a4,s2
     fca:	4067d69b          	sraiw	a3,a5,0x6
     fce:	0306869b          	addiw	a3,a3,48
     fd2:	fad408a3          	sb	a3,-79(s0)
    name[2] = '0' + (i % 64);
     fd6:	03f7f793          	andi	a5,a5,63
     fda:	9f99                	subw	a5,a5,a4
     fdc:	0307879b          	addiw	a5,a5,48
     fe0:	faf40923          	sb	a5,-78(s0)
    name[3] = '\0';
     fe4:	fa0409a3          	sb	zero,-77(s0)
    if(link("bd", name) != 0){
     fe8:	fb040593          	addi	a1,s0,-80
     fec:	8552                	mv	a0,s4
     fee:	00005097          	auipc	ra,0x5
     ff2:	8f8080e7          	jalr	-1800(ra) # 58e6 <link>
     ff6:	84aa                	mv	s1,a0
     ff8:	e949                	bnez	a0,108a <bigdir+0x128>
  for(i = 0; i < N; i++){
     ffa:	2905                	addiw	s2,s2,1
     ffc:	fb691fe3          	bne	s2,s6,fba <bigdir+0x58>
  unlink("bd");
    1000:	00006517          	auipc	a0,0x6
    1004:	80050513          	addi	a0,a0,-2048 # 6800 <malloc+0xb2c>
    1008:	00005097          	auipc	ra,0x5
    100c:	8ce080e7          	jalr	-1842(ra) # 58d6 <unlink>
    name[0] = 'x';
    1010:	07800913          	li	s2,120
  for(i = 0; i < N; i++){
    1014:	1f400a13          	li	s4,500
    name[0] = 'x';
    1018:	fb240823          	sb	s2,-80(s0)
    name[1] = '0' + (i / 64);
    101c:	41f4d79b          	sraiw	a5,s1,0x1f
    1020:	01a7d71b          	srliw	a4,a5,0x1a
    1024:	009707bb          	addw	a5,a4,s1
    1028:	4067d69b          	sraiw	a3,a5,0x6
    102c:	0306869b          	addiw	a3,a3,48
    1030:	fad408a3          	sb	a3,-79(s0)
    name[2] = '0' + (i % 64);
    1034:	03f7f793          	andi	a5,a5,63
    1038:	9f99                	subw	a5,a5,a4
    103a:	0307879b          	addiw	a5,a5,48
    103e:	faf40923          	sb	a5,-78(s0)
    name[3] = '\0';
    1042:	fa0409a3          	sb	zero,-77(s0)
    if(unlink(name) != 0){
    1046:	fb040513          	addi	a0,s0,-80
    104a:	00005097          	auipc	ra,0x5
    104e:	88c080e7          	jalr	-1908(ra) # 58d6 <unlink>
    1052:	ed21                	bnez	a0,10aa <bigdir+0x148>
  for(i = 0; i < N; i++){
    1054:	2485                	addiw	s1,s1,1
    1056:	fd4491e3          	bne	s1,s4,1018 <bigdir+0xb6>
}
    105a:	60a6                	ld	ra,72(sp)
    105c:	6406                	ld	s0,64(sp)
    105e:	74e2                	ld	s1,56(sp)
    1060:	7942                	ld	s2,48(sp)
    1062:	79a2                	ld	s3,40(sp)
    1064:	7a02                	ld	s4,32(sp)
    1066:	6ae2                	ld	s5,24(sp)
    1068:	6b42                	ld	s6,16(sp)
    106a:	6161                	addi	sp,sp,80
    106c:	8082                	ret
    printf("%s: bigdir create failed\n", s);
    106e:	85ce                	mv	a1,s3
    1070:	00005517          	auipc	a0,0x5
    1074:	79850513          	addi	a0,a0,1944 # 6808 <malloc+0xb34>
    1078:	00005097          	auipc	ra,0x5
    107c:	b9e080e7          	jalr	-1122(ra) # 5c16 <printf>
    exit(1);
    1080:	4505                	li	a0,1
    1082:	00005097          	auipc	ra,0x5
    1086:	804080e7          	jalr	-2044(ra) # 5886 <exit>
      printf("%s: bigdir link(bd, %s) failed\n", s, name);
    108a:	fb040613          	addi	a2,s0,-80
    108e:	85ce                	mv	a1,s3
    1090:	00005517          	auipc	a0,0x5
    1094:	79850513          	addi	a0,a0,1944 # 6828 <malloc+0xb54>
    1098:	00005097          	auipc	ra,0x5
    109c:	b7e080e7          	jalr	-1154(ra) # 5c16 <printf>
      exit(1);
    10a0:	4505                	li	a0,1
    10a2:	00004097          	auipc	ra,0x4
    10a6:	7e4080e7          	jalr	2020(ra) # 5886 <exit>
      printf("%s: bigdir unlink failed", s);
    10aa:	85ce                	mv	a1,s3
    10ac:	00005517          	auipc	a0,0x5
    10b0:	79c50513          	addi	a0,a0,1948 # 6848 <malloc+0xb74>
    10b4:	00005097          	auipc	ra,0x5
    10b8:	b62080e7          	jalr	-1182(ra) # 5c16 <printf>
      exit(1);
    10bc:	4505                	li	a0,1
    10be:	00004097          	auipc	ra,0x4
    10c2:	7c8080e7          	jalr	1992(ra) # 5886 <exit>

00000000000010c6 <validatetest>:
{
    10c6:	7139                	addi	sp,sp,-64
    10c8:	fc06                	sd	ra,56(sp)
    10ca:	f822                	sd	s0,48(sp)
    10cc:	f426                	sd	s1,40(sp)
    10ce:	f04a                	sd	s2,32(sp)
    10d0:	ec4e                	sd	s3,24(sp)
    10d2:	e852                	sd	s4,16(sp)
    10d4:	e456                	sd	s5,8(sp)
    10d6:	e05a                	sd	s6,0(sp)
    10d8:	0080                	addi	s0,sp,64
    10da:	8b2a                	mv	s6,a0
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    10dc:	4481                	li	s1,0
    if(link("nosuchfile", (char*)p) != -1){
    10de:	00005997          	auipc	s3,0x5
    10e2:	78a98993          	addi	s3,s3,1930 # 6868 <malloc+0xb94>
    10e6:	597d                	li	s2,-1
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    10e8:	6a85                	lui	s5,0x1
    10ea:	00114a37          	lui	s4,0x114
    if(link("nosuchfile", (char*)p) != -1){
    10ee:	85a6                	mv	a1,s1
    10f0:	854e                	mv	a0,s3
    10f2:	00004097          	auipc	ra,0x4
    10f6:	7f4080e7          	jalr	2036(ra) # 58e6 <link>
    10fa:	01251f63          	bne	a0,s2,1118 <validatetest+0x52>
  for(p = 0; p <= (uint)hi; p += PGSIZE){
    10fe:	94d6                	add	s1,s1,s5
    1100:	ff4497e3          	bne	s1,s4,10ee <validatetest+0x28>
}
    1104:	70e2                	ld	ra,56(sp)
    1106:	7442                	ld	s0,48(sp)
    1108:	74a2                	ld	s1,40(sp)
    110a:	7902                	ld	s2,32(sp)
    110c:	69e2                	ld	s3,24(sp)
    110e:	6a42                	ld	s4,16(sp)
    1110:	6aa2                	ld	s5,8(sp)
    1112:	6b02                	ld	s6,0(sp)
    1114:	6121                	addi	sp,sp,64
    1116:	8082                	ret
      printf("%s: link should not succeed\n", s);
    1118:	85da                	mv	a1,s6
    111a:	00005517          	auipc	a0,0x5
    111e:	75e50513          	addi	a0,a0,1886 # 6878 <malloc+0xba4>
    1122:	00005097          	auipc	ra,0x5
    1126:	af4080e7          	jalr	-1292(ra) # 5c16 <printf>
      exit(1);
    112a:	4505                	li	a0,1
    112c:	00004097          	auipc	ra,0x4
    1130:	75a080e7          	jalr	1882(ra) # 5886 <exit>

0000000000001134 <pgbug>:
// regression test. copyin(), copyout(), and copyinstr() used to cast
// the virtual page address to uint, which (with certain wild system
// call arguments) resulted in a kernel page faults.
void
pgbug(char *s)
{
    1134:	7179                	addi	sp,sp,-48
    1136:	f406                	sd	ra,40(sp)
    1138:	f022                	sd	s0,32(sp)
    113a:	ec26                	sd	s1,24(sp)
    113c:	1800                	addi	s0,sp,48
  char *argv[1];
  argv[0] = 0;
    113e:	fc043c23          	sd	zero,-40(s0)
  exec((char*)0xeaeb0b5b00002f5e, argv);
    1142:	00007497          	auipc	s1,0x7
    1146:	49e4b483          	ld	s1,1182(s1) # 85e0 <__SDATA_BEGIN__>
    114a:	fd840593          	addi	a1,s0,-40
    114e:	8526                	mv	a0,s1
    1150:	00004097          	auipc	ra,0x4
    1154:	76e080e7          	jalr	1902(ra) # 58be <exec>

  pipe((int*)0xeaeb0b5b00002f5e);
    1158:	8526                	mv	a0,s1
    115a:	00004097          	auipc	ra,0x4
    115e:	73c080e7          	jalr	1852(ra) # 5896 <pipe>

  exit(0);
    1162:	4501                	li	a0,0
    1164:	00004097          	auipc	ra,0x4
    1168:	722080e7          	jalr	1826(ra) # 5886 <exit>

000000000000116c <badarg>:

// regression test. test whether exec() leaks memory if one of the
// arguments is invalid. the test passes if the kernel doesn't panic.
void
badarg(char *s)
{
    116c:	7139                	addi	sp,sp,-64
    116e:	fc06                	sd	ra,56(sp)
    1170:	f822                	sd	s0,48(sp)
    1172:	f426                	sd	s1,40(sp)
    1174:	f04a                	sd	s2,32(sp)
    1176:	ec4e                	sd	s3,24(sp)
    1178:	0080                	addi	s0,sp,64
    117a:	64b1                	lui	s1,0xc
    117c:	35048493          	addi	s1,s1,848 # c350 <buf+0x548>
  for(int i = 0; i < 50000; i++){
    char *argv[2];
    argv[0] = (char*)0xffffffff;
    1180:	597d                	li	s2,-1
    1182:	02095913          	srli	s2,s2,0x20
    argv[1] = 0;
    exec("echo", argv);
    1186:	00005997          	auipc	s3,0x5
    118a:	fba98993          	addi	s3,s3,-70 # 6140 <malloc+0x46c>
    argv[0] = (char*)0xffffffff;
    118e:	fd243023          	sd	s2,-64(s0)
    argv[1] = 0;
    1192:	fc043423          	sd	zero,-56(s0)
    exec("echo", argv);
    1196:	fc040593          	addi	a1,s0,-64
    119a:	854e                	mv	a0,s3
    119c:	00004097          	auipc	ra,0x4
    11a0:	722080e7          	jalr	1826(ra) # 58be <exec>
  for(int i = 0; i < 50000; i++){
    11a4:	34fd                	addiw	s1,s1,-1
    11a6:	f4e5                	bnez	s1,118e <badarg+0x22>
  }
  
  exit(0);
    11a8:	4501                	li	a0,0
    11aa:	00004097          	auipc	ra,0x4
    11ae:	6dc080e7          	jalr	1756(ra) # 5886 <exit>

00000000000011b2 <copyinstr2>:
{
    11b2:	7155                	addi	sp,sp,-208
    11b4:	e586                	sd	ra,200(sp)
    11b6:	e1a2                	sd	s0,192(sp)
    11b8:	0980                	addi	s0,sp,208
  for(int i = 0; i < MAXPATH; i++)
    11ba:	f6840793          	addi	a5,s0,-152
    11be:	fe840693          	addi	a3,s0,-24
    b[i] = 'x';
    11c2:	07800713          	li	a4,120
    11c6:	00e78023          	sb	a4,0(a5)
  for(int i = 0; i < MAXPATH; i++)
    11ca:	0785                	addi	a5,a5,1
    11cc:	fed79de3          	bne	a5,a3,11c6 <copyinstr2+0x14>
  b[MAXPATH] = '\0';
    11d0:	fe040423          	sb	zero,-24(s0)
  int ret = unlink(b);
    11d4:	f6840513          	addi	a0,s0,-152
    11d8:	00004097          	auipc	ra,0x4
    11dc:	6fe080e7          	jalr	1790(ra) # 58d6 <unlink>
  if(ret != -1){
    11e0:	57fd                	li	a5,-1
    11e2:	0ef51063          	bne	a0,a5,12c2 <copyinstr2+0x110>
  int fd = open(b, O_CREATE | O_WRONLY);
    11e6:	20100593          	li	a1,513
    11ea:	f6840513          	addi	a0,s0,-152
    11ee:	00004097          	auipc	ra,0x4
    11f2:	6d8080e7          	jalr	1752(ra) # 58c6 <open>
  if(fd != -1){
    11f6:	57fd                	li	a5,-1
    11f8:	0ef51563          	bne	a0,a5,12e2 <copyinstr2+0x130>
  ret = link(b, b);
    11fc:	f6840593          	addi	a1,s0,-152
    1200:	852e                	mv	a0,a1
    1202:	00004097          	auipc	ra,0x4
    1206:	6e4080e7          	jalr	1764(ra) # 58e6 <link>
  if(ret != -1){
    120a:	57fd                	li	a5,-1
    120c:	0ef51b63          	bne	a0,a5,1302 <copyinstr2+0x150>
  char *args[] = { "xx", 0 };
    1210:	00007797          	auipc	a5,0x7
    1214:	83878793          	addi	a5,a5,-1992 # 7a48 <malloc+0x1d74>
    1218:	f4f43c23          	sd	a5,-168(s0)
    121c:	f6043023          	sd	zero,-160(s0)
  ret = exec(b, args);
    1220:	f5840593          	addi	a1,s0,-168
    1224:	f6840513          	addi	a0,s0,-152
    1228:	00004097          	auipc	ra,0x4
    122c:	696080e7          	jalr	1686(ra) # 58be <exec>
  if(ret != -1){
    1230:	57fd                	li	a5,-1
    1232:	0ef51963          	bne	a0,a5,1324 <copyinstr2+0x172>
  int pid = fork();
    1236:	00004097          	auipc	ra,0x4
    123a:	648080e7          	jalr	1608(ra) # 587e <fork>
  if(pid < 0){
    123e:	10054363          	bltz	a0,1344 <copyinstr2+0x192>
  if(pid == 0){
    1242:	12051463          	bnez	a0,136a <copyinstr2+0x1b8>
    1246:	00007797          	auipc	a5,0x7
    124a:	4aa78793          	addi	a5,a5,1194 # 86f0 <big.1270>
    124e:	00008697          	auipc	a3,0x8
    1252:	4a268693          	addi	a3,a3,1186 # 96f0 <__global_pointer$+0x910>
      big[i] = 'x';
    1256:	07800713          	li	a4,120
    125a:	00e78023          	sb	a4,0(a5)
    for(int i = 0; i < PGSIZE; i++)
    125e:	0785                	addi	a5,a5,1
    1260:	fed79de3          	bne	a5,a3,125a <copyinstr2+0xa8>
    big[PGSIZE] = '\0';
    1264:	00008797          	auipc	a5,0x8
    1268:	48078623          	sb	zero,1164(a5) # 96f0 <__global_pointer$+0x910>
    char *args2[] = { big, big, big, 0 };
    126c:	00007797          	auipc	a5,0x7
    1270:	f5478793          	addi	a5,a5,-172 # 81c0 <malloc+0x24ec>
    1274:	6390                	ld	a2,0(a5)
    1276:	6794                	ld	a3,8(a5)
    1278:	6b98                	ld	a4,16(a5)
    127a:	6f9c                	ld	a5,24(a5)
    127c:	f2c43823          	sd	a2,-208(s0)
    1280:	f2d43c23          	sd	a3,-200(s0)
    1284:	f4e43023          	sd	a4,-192(s0)
    1288:	f4f43423          	sd	a5,-184(s0)
    ret = exec("echo", args2);
    128c:	f3040593          	addi	a1,s0,-208
    1290:	00005517          	auipc	a0,0x5
    1294:	eb050513          	addi	a0,a0,-336 # 6140 <malloc+0x46c>
    1298:	00004097          	auipc	ra,0x4
    129c:	626080e7          	jalr	1574(ra) # 58be <exec>
    if(ret != -1){
    12a0:	57fd                	li	a5,-1
    12a2:	0af50e63          	beq	a0,a5,135e <copyinstr2+0x1ac>
      printf("exec(echo, BIG) returned %d, not -1\n", fd);
    12a6:	55fd                	li	a1,-1
    12a8:	00005517          	auipc	a0,0x5
    12ac:	67850513          	addi	a0,a0,1656 # 6920 <malloc+0xc4c>
    12b0:	00005097          	auipc	ra,0x5
    12b4:	966080e7          	jalr	-1690(ra) # 5c16 <printf>
      exit(1);
    12b8:	4505                	li	a0,1
    12ba:	00004097          	auipc	ra,0x4
    12be:	5cc080e7          	jalr	1484(ra) # 5886 <exit>
    printf("unlink(%s) returned %d, not -1\n", b, ret);
    12c2:	862a                	mv	a2,a0
    12c4:	f6840593          	addi	a1,s0,-152
    12c8:	00005517          	auipc	a0,0x5
    12cc:	5d050513          	addi	a0,a0,1488 # 6898 <malloc+0xbc4>
    12d0:	00005097          	auipc	ra,0x5
    12d4:	946080e7          	jalr	-1722(ra) # 5c16 <printf>
    exit(1);
    12d8:	4505                	li	a0,1
    12da:	00004097          	auipc	ra,0x4
    12de:	5ac080e7          	jalr	1452(ra) # 5886 <exit>
    printf("open(%s) returned %d, not -1\n", b, fd);
    12e2:	862a                	mv	a2,a0
    12e4:	f6840593          	addi	a1,s0,-152
    12e8:	00005517          	auipc	a0,0x5
    12ec:	5d050513          	addi	a0,a0,1488 # 68b8 <malloc+0xbe4>
    12f0:	00005097          	auipc	ra,0x5
    12f4:	926080e7          	jalr	-1754(ra) # 5c16 <printf>
    exit(1);
    12f8:	4505                	li	a0,1
    12fa:	00004097          	auipc	ra,0x4
    12fe:	58c080e7          	jalr	1420(ra) # 5886 <exit>
    printf("link(%s, %s) returned %d, not -1\n", b, b, ret);
    1302:	86aa                	mv	a3,a0
    1304:	f6840613          	addi	a2,s0,-152
    1308:	85b2                	mv	a1,a2
    130a:	00005517          	auipc	a0,0x5
    130e:	5ce50513          	addi	a0,a0,1486 # 68d8 <malloc+0xc04>
    1312:	00005097          	auipc	ra,0x5
    1316:	904080e7          	jalr	-1788(ra) # 5c16 <printf>
    exit(1);
    131a:	4505                	li	a0,1
    131c:	00004097          	auipc	ra,0x4
    1320:	56a080e7          	jalr	1386(ra) # 5886 <exit>
    printf("exec(%s) returned %d, not -1\n", b, fd);
    1324:	567d                	li	a2,-1
    1326:	f6840593          	addi	a1,s0,-152
    132a:	00005517          	auipc	a0,0x5
    132e:	5d650513          	addi	a0,a0,1494 # 6900 <malloc+0xc2c>
    1332:	00005097          	auipc	ra,0x5
    1336:	8e4080e7          	jalr	-1820(ra) # 5c16 <printf>
    exit(1);
    133a:	4505                	li	a0,1
    133c:	00004097          	auipc	ra,0x4
    1340:	54a080e7          	jalr	1354(ra) # 5886 <exit>
    printf("fork failed\n");
    1344:	00006517          	auipc	a0,0x6
    1348:	a3c50513          	addi	a0,a0,-1476 # 6d80 <malloc+0x10ac>
    134c:	00005097          	auipc	ra,0x5
    1350:	8ca080e7          	jalr	-1846(ra) # 5c16 <printf>
    exit(1);
    1354:	4505                	li	a0,1
    1356:	00004097          	auipc	ra,0x4
    135a:	530080e7          	jalr	1328(ra) # 5886 <exit>
    exit(747); // OK
    135e:	2eb00513          	li	a0,747
    1362:	00004097          	auipc	ra,0x4
    1366:	524080e7          	jalr	1316(ra) # 5886 <exit>
  int st = 0;
    136a:	f4042a23          	sw	zero,-172(s0)
  wait(&st);
    136e:	f5440513          	addi	a0,s0,-172
    1372:	00004097          	auipc	ra,0x4
    1376:	51c080e7          	jalr	1308(ra) # 588e <wait>
  if(st != 747){
    137a:	f5442703          	lw	a4,-172(s0)
    137e:	2eb00793          	li	a5,747
    1382:	00f71663          	bne	a4,a5,138e <copyinstr2+0x1dc>
}
    1386:	60ae                	ld	ra,200(sp)
    1388:	640e                	ld	s0,192(sp)
    138a:	6169                	addi	sp,sp,208
    138c:	8082                	ret
    printf("exec(echo, BIG) succeeded, should have failed\n");
    138e:	00005517          	auipc	a0,0x5
    1392:	5ba50513          	addi	a0,a0,1466 # 6948 <malloc+0xc74>
    1396:	00005097          	auipc	ra,0x5
    139a:	880080e7          	jalr	-1920(ra) # 5c16 <printf>
    exit(1);
    139e:	4505                	li	a0,1
    13a0:	00004097          	auipc	ra,0x4
    13a4:	4e6080e7          	jalr	1254(ra) # 5886 <exit>

00000000000013a8 <truncate3>:
{
    13a8:	7159                	addi	sp,sp,-112
    13aa:	f486                	sd	ra,104(sp)
    13ac:	f0a2                	sd	s0,96(sp)
    13ae:	eca6                	sd	s1,88(sp)
    13b0:	e8ca                	sd	s2,80(sp)
    13b2:	e4ce                	sd	s3,72(sp)
    13b4:	e0d2                	sd	s4,64(sp)
    13b6:	fc56                	sd	s5,56(sp)
    13b8:	1880                	addi	s0,sp,112
    13ba:	892a                	mv	s2,a0
  close(open("truncfile", O_CREATE|O_TRUNC|O_WRONLY));
    13bc:	60100593          	li	a1,1537
    13c0:	00005517          	auipc	a0,0x5
    13c4:	dd850513          	addi	a0,a0,-552 # 6198 <malloc+0x4c4>
    13c8:	00004097          	auipc	ra,0x4
    13cc:	4fe080e7          	jalr	1278(ra) # 58c6 <open>
    13d0:	00004097          	auipc	ra,0x4
    13d4:	4de080e7          	jalr	1246(ra) # 58ae <close>
  pid = fork();
    13d8:	00004097          	auipc	ra,0x4
    13dc:	4a6080e7          	jalr	1190(ra) # 587e <fork>
  if(pid < 0){
    13e0:	08054063          	bltz	a0,1460 <truncate3+0xb8>
  if(pid == 0){
    13e4:	e969                	bnez	a0,14b6 <truncate3+0x10e>
    13e6:	06400993          	li	s3,100
      int fd = open("truncfile", O_WRONLY);
    13ea:	00005a17          	auipc	s4,0x5
    13ee:	daea0a13          	addi	s4,s4,-594 # 6198 <malloc+0x4c4>
      int n = write(fd, "1234567890", 10);
    13f2:	00005a97          	auipc	s5,0x5
    13f6:	5b6a8a93          	addi	s5,s5,1462 # 69a8 <malloc+0xcd4>
      int fd = open("truncfile", O_WRONLY);
    13fa:	4585                	li	a1,1
    13fc:	8552                	mv	a0,s4
    13fe:	00004097          	auipc	ra,0x4
    1402:	4c8080e7          	jalr	1224(ra) # 58c6 <open>
    1406:	84aa                	mv	s1,a0
      if(fd < 0){
    1408:	06054a63          	bltz	a0,147c <truncate3+0xd4>
      int n = write(fd, "1234567890", 10);
    140c:	4629                	li	a2,10
    140e:	85d6                	mv	a1,s5
    1410:	00004097          	auipc	ra,0x4
    1414:	496080e7          	jalr	1174(ra) # 58a6 <write>
      if(n != 10){
    1418:	47a9                	li	a5,10
    141a:	06f51f63          	bne	a0,a5,1498 <truncate3+0xf0>
      close(fd);
    141e:	8526                	mv	a0,s1
    1420:	00004097          	auipc	ra,0x4
    1424:	48e080e7          	jalr	1166(ra) # 58ae <close>
      fd = open("truncfile", O_RDONLY);
    1428:	4581                	li	a1,0
    142a:	8552                	mv	a0,s4
    142c:	00004097          	auipc	ra,0x4
    1430:	49a080e7          	jalr	1178(ra) # 58c6 <open>
    1434:	84aa                	mv	s1,a0
      read(fd, buf, sizeof(buf));
    1436:	02000613          	li	a2,32
    143a:	f9840593          	addi	a1,s0,-104
    143e:	00004097          	auipc	ra,0x4
    1442:	460080e7          	jalr	1120(ra) # 589e <read>
      close(fd);
    1446:	8526                	mv	a0,s1
    1448:	00004097          	auipc	ra,0x4
    144c:	466080e7          	jalr	1126(ra) # 58ae <close>
    for(int i = 0; i < 100; i++){
    1450:	39fd                	addiw	s3,s3,-1
    1452:	fa0994e3          	bnez	s3,13fa <truncate3+0x52>
    exit(0);
    1456:	4501                	li	a0,0
    1458:	00004097          	auipc	ra,0x4
    145c:	42e080e7          	jalr	1070(ra) # 5886 <exit>
    printf("%s: fork failed\n", s);
    1460:	85ca                	mv	a1,s2
    1462:	00005517          	auipc	a0,0x5
    1466:	51650513          	addi	a0,a0,1302 # 6978 <malloc+0xca4>
    146a:	00004097          	auipc	ra,0x4
    146e:	7ac080e7          	jalr	1964(ra) # 5c16 <printf>
    exit(1);
    1472:	4505                	li	a0,1
    1474:	00004097          	auipc	ra,0x4
    1478:	412080e7          	jalr	1042(ra) # 5886 <exit>
        printf("%s: open failed\n", s);
    147c:	85ca                	mv	a1,s2
    147e:	00005517          	auipc	a0,0x5
    1482:	51250513          	addi	a0,a0,1298 # 6990 <malloc+0xcbc>
    1486:	00004097          	auipc	ra,0x4
    148a:	790080e7          	jalr	1936(ra) # 5c16 <printf>
        exit(1);
    148e:	4505                	li	a0,1
    1490:	00004097          	auipc	ra,0x4
    1494:	3f6080e7          	jalr	1014(ra) # 5886 <exit>
        printf("%s: write got %d, expected 10\n", s, n);
    1498:	862a                	mv	a2,a0
    149a:	85ca                	mv	a1,s2
    149c:	00005517          	auipc	a0,0x5
    14a0:	51c50513          	addi	a0,a0,1308 # 69b8 <malloc+0xce4>
    14a4:	00004097          	auipc	ra,0x4
    14a8:	772080e7          	jalr	1906(ra) # 5c16 <printf>
        exit(1);
    14ac:	4505                	li	a0,1
    14ae:	00004097          	auipc	ra,0x4
    14b2:	3d8080e7          	jalr	984(ra) # 5886 <exit>
    14b6:	09600993          	li	s3,150
    int fd = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
    14ba:	00005a17          	auipc	s4,0x5
    14be:	cdea0a13          	addi	s4,s4,-802 # 6198 <malloc+0x4c4>
    int n = write(fd, "xxx", 3);
    14c2:	00005a97          	auipc	s5,0x5
    14c6:	516a8a93          	addi	s5,s5,1302 # 69d8 <malloc+0xd04>
    int fd = open("truncfile", O_CREATE|O_WRONLY|O_TRUNC);
    14ca:	60100593          	li	a1,1537
    14ce:	8552                	mv	a0,s4
    14d0:	00004097          	auipc	ra,0x4
    14d4:	3f6080e7          	jalr	1014(ra) # 58c6 <open>
    14d8:	84aa                	mv	s1,a0
    if(fd < 0){
    14da:	04054763          	bltz	a0,1528 <truncate3+0x180>
    int n = write(fd, "xxx", 3);
    14de:	460d                	li	a2,3
    14e0:	85d6                	mv	a1,s5
    14e2:	00004097          	auipc	ra,0x4
    14e6:	3c4080e7          	jalr	964(ra) # 58a6 <write>
    if(n != 3){
    14ea:	478d                	li	a5,3
    14ec:	04f51c63          	bne	a0,a5,1544 <truncate3+0x19c>
    close(fd);
    14f0:	8526                	mv	a0,s1
    14f2:	00004097          	auipc	ra,0x4
    14f6:	3bc080e7          	jalr	956(ra) # 58ae <close>
  for(int i = 0; i < 150; i++){
    14fa:	39fd                	addiw	s3,s3,-1
    14fc:	fc0997e3          	bnez	s3,14ca <truncate3+0x122>
  wait(&xstatus);
    1500:	fbc40513          	addi	a0,s0,-68
    1504:	00004097          	auipc	ra,0x4
    1508:	38a080e7          	jalr	906(ra) # 588e <wait>
  unlink("truncfile");
    150c:	00005517          	auipc	a0,0x5
    1510:	c8c50513          	addi	a0,a0,-884 # 6198 <malloc+0x4c4>
    1514:	00004097          	auipc	ra,0x4
    1518:	3c2080e7          	jalr	962(ra) # 58d6 <unlink>
  exit(xstatus);
    151c:	fbc42503          	lw	a0,-68(s0)
    1520:	00004097          	auipc	ra,0x4
    1524:	366080e7          	jalr	870(ra) # 5886 <exit>
      printf("%s: open failed\n", s);
    1528:	85ca                	mv	a1,s2
    152a:	00005517          	auipc	a0,0x5
    152e:	46650513          	addi	a0,a0,1126 # 6990 <malloc+0xcbc>
    1532:	00004097          	auipc	ra,0x4
    1536:	6e4080e7          	jalr	1764(ra) # 5c16 <printf>
      exit(1);
    153a:	4505                	li	a0,1
    153c:	00004097          	auipc	ra,0x4
    1540:	34a080e7          	jalr	842(ra) # 5886 <exit>
      printf("%s: write got %d, expected 3\n", s, n);
    1544:	862a                	mv	a2,a0
    1546:	85ca                	mv	a1,s2
    1548:	00005517          	auipc	a0,0x5
    154c:	49850513          	addi	a0,a0,1176 # 69e0 <malloc+0xd0c>
    1550:	00004097          	auipc	ra,0x4
    1554:	6c6080e7          	jalr	1734(ra) # 5c16 <printf>
      exit(1);
    1558:	4505                	li	a0,1
    155a:	00004097          	auipc	ra,0x4
    155e:	32c080e7          	jalr	812(ra) # 5886 <exit>

0000000000001562 <exectest>:
{
    1562:	715d                	addi	sp,sp,-80
    1564:	e486                	sd	ra,72(sp)
    1566:	e0a2                	sd	s0,64(sp)
    1568:	fc26                	sd	s1,56(sp)
    156a:	f84a                	sd	s2,48(sp)
    156c:	0880                	addi	s0,sp,80
    156e:	892a                	mv	s2,a0
  char *echoargv[] = { "echo", "OK", 0 };
    1570:	00005797          	auipc	a5,0x5
    1574:	bd078793          	addi	a5,a5,-1072 # 6140 <malloc+0x46c>
    1578:	fcf43023          	sd	a5,-64(s0)
    157c:	00005797          	auipc	a5,0x5
    1580:	48478793          	addi	a5,a5,1156 # 6a00 <malloc+0xd2c>
    1584:	fcf43423          	sd	a5,-56(s0)
    1588:	fc043823          	sd	zero,-48(s0)
  unlink("echo-ok");
    158c:	00005517          	auipc	a0,0x5
    1590:	47c50513          	addi	a0,a0,1148 # 6a08 <malloc+0xd34>
    1594:	00004097          	auipc	ra,0x4
    1598:	342080e7          	jalr	834(ra) # 58d6 <unlink>
  pid = fork();
    159c:	00004097          	auipc	ra,0x4
    15a0:	2e2080e7          	jalr	738(ra) # 587e <fork>
  if(pid < 0) {
    15a4:	04054663          	bltz	a0,15f0 <exectest+0x8e>
    15a8:	84aa                	mv	s1,a0
  if(pid == 0) {
    15aa:	e959                	bnez	a0,1640 <exectest+0xde>
    close(1);
    15ac:	4505                	li	a0,1
    15ae:	00004097          	auipc	ra,0x4
    15b2:	300080e7          	jalr	768(ra) # 58ae <close>
    fd = open("echo-ok", O_CREATE|O_WRONLY);
    15b6:	20100593          	li	a1,513
    15ba:	00005517          	auipc	a0,0x5
    15be:	44e50513          	addi	a0,a0,1102 # 6a08 <malloc+0xd34>
    15c2:	00004097          	auipc	ra,0x4
    15c6:	304080e7          	jalr	772(ra) # 58c6 <open>
    if(fd < 0) {
    15ca:	04054163          	bltz	a0,160c <exectest+0xaa>
    if(fd != 1) {
    15ce:	4785                	li	a5,1
    15d0:	04f50c63          	beq	a0,a5,1628 <exectest+0xc6>
      printf("%s: wrong fd\n", s);
    15d4:	85ca                	mv	a1,s2
    15d6:	00005517          	auipc	a0,0x5
    15da:	45250513          	addi	a0,a0,1106 # 6a28 <malloc+0xd54>
    15de:	00004097          	auipc	ra,0x4
    15e2:	638080e7          	jalr	1592(ra) # 5c16 <printf>
      exit(1);
    15e6:	4505                	li	a0,1
    15e8:	00004097          	auipc	ra,0x4
    15ec:	29e080e7          	jalr	670(ra) # 5886 <exit>
     printf("%s: fork failed\n", s);
    15f0:	85ca                	mv	a1,s2
    15f2:	00005517          	auipc	a0,0x5
    15f6:	38650513          	addi	a0,a0,902 # 6978 <malloc+0xca4>
    15fa:	00004097          	auipc	ra,0x4
    15fe:	61c080e7          	jalr	1564(ra) # 5c16 <printf>
     exit(1);
    1602:	4505                	li	a0,1
    1604:	00004097          	auipc	ra,0x4
    1608:	282080e7          	jalr	642(ra) # 5886 <exit>
      printf("%s: create failed\n", s);
    160c:	85ca                	mv	a1,s2
    160e:	00005517          	auipc	a0,0x5
    1612:	40250513          	addi	a0,a0,1026 # 6a10 <malloc+0xd3c>
    1616:	00004097          	auipc	ra,0x4
    161a:	600080e7          	jalr	1536(ra) # 5c16 <printf>
      exit(1);
    161e:	4505                	li	a0,1
    1620:	00004097          	auipc	ra,0x4
    1624:	266080e7          	jalr	614(ra) # 5886 <exit>
    if(exec("echo", echoargv) < 0){
    1628:	fc040593          	addi	a1,s0,-64
    162c:	00005517          	auipc	a0,0x5
    1630:	b1450513          	addi	a0,a0,-1260 # 6140 <malloc+0x46c>
    1634:	00004097          	auipc	ra,0x4
    1638:	28a080e7          	jalr	650(ra) # 58be <exec>
    163c:	02054163          	bltz	a0,165e <exectest+0xfc>
  if (wait(&xstatus) != pid) {
    1640:	fdc40513          	addi	a0,s0,-36
    1644:	00004097          	auipc	ra,0x4
    1648:	24a080e7          	jalr	586(ra) # 588e <wait>
    164c:	02951763          	bne	a0,s1,167a <exectest+0x118>
  if(xstatus != 0)
    1650:	fdc42503          	lw	a0,-36(s0)
    1654:	cd0d                	beqz	a0,168e <exectest+0x12c>
    exit(xstatus);
    1656:	00004097          	auipc	ra,0x4
    165a:	230080e7          	jalr	560(ra) # 5886 <exit>
      printf("%s: exec echo failed\n", s);
    165e:	85ca                	mv	a1,s2
    1660:	00005517          	auipc	a0,0x5
    1664:	3d850513          	addi	a0,a0,984 # 6a38 <malloc+0xd64>
    1668:	00004097          	auipc	ra,0x4
    166c:	5ae080e7          	jalr	1454(ra) # 5c16 <printf>
      exit(1);
    1670:	4505                	li	a0,1
    1672:	00004097          	auipc	ra,0x4
    1676:	214080e7          	jalr	532(ra) # 5886 <exit>
    printf("%s: wait failed!\n", s);
    167a:	85ca                	mv	a1,s2
    167c:	00005517          	auipc	a0,0x5
    1680:	3d450513          	addi	a0,a0,980 # 6a50 <malloc+0xd7c>
    1684:	00004097          	auipc	ra,0x4
    1688:	592080e7          	jalr	1426(ra) # 5c16 <printf>
    168c:	b7d1                	j	1650 <exectest+0xee>
  fd = open("echo-ok", O_RDONLY);
    168e:	4581                	li	a1,0
    1690:	00005517          	auipc	a0,0x5
    1694:	37850513          	addi	a0,a0,888 # 6a08 <malloc+0xd34>
    1698:	00004097          	auipc	ra,0x4
    169c:	22e080e7          	jalr	558(ra) # 58c6 <open>
  if(fd < 0) {
    16a0:	02054a63          	bltz	a0,16d4 <exectest+0x172>
  if (read(fd, buf, 2) != 2) {
    16a4:	4609                	li	a2,2
    16a6:	fb840593          	addi	a1,s0,-72
    16aa:	00004097          	auipc	ra,0x4
    16ae:	1f4080e7          	jalr	500(ra) # 589e <read>
    16b2:	4789                	li	a5,2
    16b4:	02f50e63          	beq	a0,a5,16f0 <exectest+0x18e>
    printf("%s: read failed\n", s);
    16b8:	85ca                	mv	a1,s2
    16ba:	00005517          	auipc	a0,0x5
    16be:	e1650513          	addi	a0,a0,-490 # 64d0 <malloc+0x7fc>
    16c2:	00004097          	auipc	ra,0x4
    16c6:	554080e7          	jalr	1364(ra) # 5c16 <printf>
    exit(1);
    16ca:	4505                	li	a0,1
    16cc:	00004097          	auipc	ra,0x4
    16d0:	1ba080e7          	jalr	442(ra) # 5886 <exit>
    printf("%s: open failed\n", s);
    16d4:	85ca                	mv	a1,s2
    16d6:	00005517          	auipc	a0,0x5
    16da:	2ba50513          	addi	a0,a0,698 # 6990 <malloc+0xcbc>
    16de:	00004097          	auipc	ra,0x4
    16e2:	538080e7          	jalr	1336(ra) # 5c16 <printf>
    exit(1);
    16e6:	4505                	li	a0,1
    16e8:	00004097          	auipc	ra,0x4
    16ec:	19e080e7          	jalr	414(ra) # 5886 <exit>
  unlink("echo-ok");
    16f0:	00005517          	auipc	a0,0x5
    16f4:	31850513          	addi	a0,a0,792 # 6a08 <malloc+0xd34>
    16f8:	00004097          	auipc	ra,0x4
    16fc:	1de080e7          	jalr	478(ra) # 58d6 <unlink>
  if(buf[0] == 'O' && buf[1] == 'K')
    1700:	fb844703          	lbu	a4,-72(s0)
    1704:	04f00793          	li	a5,79
    1708:	00f71863          	bne	a4,a5,1718 <exectest+0x1b6>
    170c:	fb944703          	lbu	a4,-71(s0)
    1710:	04b00793          	li	a5,75
    1714:	02f70063          	beq	a4,a5,1734 <exectest+0x1d2>
    printf("%s: wrong output\n", s);
    1718:	85ca                	mv	a1,s2
    171a:	00005517          	auipc	a0,0x5
    171e:	34e50513          	addi	a0,a0,846 # 6a68 <malloc+0xd94>
    1722:	00004097          	auipc	ra,0x4
    1726:	4f4080e7          	jalr	1268(ra) # 5c16 <printf>
    exit(1);
    172a:	4505                	li	a0,1
    172c:	00004097          	auipc	ra,0x4
    1730:	15a080e7          	jalr	346(ra) # 5886 <exit>
    exit(0);
    1734:	4501                	li	a0,0
    1736:	00004097          	auipc	ra,0x4
    173a:	150080e7          	jalr	336(ra) # 5886 <exit>

000000000000173e <pipe1>:
{
    173e:	711d                	addi	sp,sp,-96
    1740:	ec86                	sd	ra,88(sp)
    1742:	e8a2                	sd	s0,80(sp)
    1744:	e4a6                	sd	s1,72(sp)
    1746:	e0ca                	sd	s2,64(sp)
    1748:	fc4e                	sd	s3,56(sp)
    174a:	f852                	sd	s4,48(sp)
    174c:	f456                	sd	s5,40(sp)
    174e:	f05a                	sd	s6,32(sp)
    1750:	ec5e                	sd	s7,24(sp)
    1752:	1080                	addi	s0,sp,96
    1754:	892a                	mv	s2,a0
  if(pipe(fds) != 0){
    1756:	fa840513          	addi	a0,s0,-88
    175a:	00004097          	auipc	ra,0x4
    175e:	13c080e7          	jalr	316(ra) # 5896 <pipe>
    1762:	ed25                	bnez	a0,17da <pipe1+0x9c>
    1764:	84aa                	mv	s1,a0
  pid = fork();
    1766:	00004097          	auipc	ra,0x4
    176a:	118080e7          	jalr	280(ra) # 587e <fork>
    176e:	8a2a                	mv	s4,a0
  if(pid == 0){
    1770:	c159                	beqz	a0,17f6 <pipe1+0xb8>
  } else if(pid > 0){
    1772:	16a05e63          	blez	a0,18ee <pipe1+0x1b0>
    close(fds[1]);
    1776:	fac42503          	lw	a0,-84(s0)
    177a:	00004097          	auipc	ra,0x4
    177e:	134080e7          	jalr	308(ra) # 58ae <close>
    total = 0;
    1782:	8a26                	mv	s4,s1
    cc = 1;
    1784:	4985                	li	s3,1
    while((n = read(fds[0], buf, cc)) > 0){
    1786:	0000aa97          	auipc	s5,0xa
    178a:	682a8a93          	addi	s5,s5,1666 # be08 <buf>
      if(cc > sizeof(buf))
    178e:	6b0d                	lui	s6,0x3
    while((n = read(fds[0], buf, cc)) > 0){
    1790:	864e                	mv	a2,s3
    1792:	85d6                	mv	a1,s5
    1794:	fa842503          	lw	a0,-88(s0)
    1798:	00004097          	auipc	ra,0x4
    179c:	106080e7          	jalr	262(ra) # 589e <read>
    17a0:	10a05263          	blez	a0,18a4 <pipe1+0x166>
      for(i = 0; i < n; i++){
    17a4:	0000a717          	auipc	a4,0xa
    17a8:	66470713          	addi	a4,a4,1636 # be08 <buf>
    17ac:	00a4863b          	addw	a2,s1,a0
        if((buf[i] & 0xff) != (seq++ & 0xff)){
    17b0:	00074683          	lbu	a3,0(a4)
    17b4:	0ff4f793          	andi	a5,s1,255
    17b8:	2485                	addiw	s1,s1,1
    17ba:	0cf69163          	bne	a3,a5,187c <pipe1+0x13e>
      for(i = 0; i < n; i++){
    17be:	0705                	addi	a4,a4,1
    17c0:	fec498e3          	bne	s1,a2,17b0 <pipe1+0x72>
      total += n;
    17c4:	00aa0a3b          	addw	s4,s4,a0
      cc = cc * 2;
    17c8:	0019979b          	slliw	a5,s3,0x1
    17cc:	0007899b          	sext.w	s3,a5
      if(cc > sizeof(buf))
    17d0:	013b7363          	bgeu	s6,s3,17d6 <pipe1+0x98>
        cc = sizeof(buf);
    17d4:	89da                	mv	s3,s6
        if((buf[i] & 0xff) != (seq++ & 0xff)){
    17d6:	84b2                	mv	s1,a2
    17d8:	bf65                	j	1790 <pipe1+0x52>
    printf("%s: pipe() failed\n", s);
    17da:	85ca                	mv	a1,s2
    17dc:	00005517          	auipc	a0,0x5
    17e0:	2a450513          	addi	a0,a0,676 # 6a80 <malloc+0xdac>
    17e4:	00004097          	auipc	ra,0x4
    17e8:	432080e7          	jalr	1074(ra) # 5c16 <printf>
    exit(1);
    17ec:	4505                	li	a0,1
    17ee:	00004097          	auipc	ra,0x4
    17f2:	098080e7          	jalr	152(ra) # 5886 <exit>
    close(fds[0]);
    17f6:	fa842503          	lw	a0,-88(s0)
    17fa:	00004097          	auipc	ra,0x4
    17fe:	0b4080e7          	jalr	180(ra) # 58ae <close>
    for(n = 0; n < N; n++){
    1802:	0000ab17          	auipc	s6,0xa
    1806:	606b0b13          	addi	s6,s6,1542 # be08 <buf>
    180a:	416004bb          	negw	s1,s6
    180e:	0ff4f493          	andi	s1,s1,255
    1812:	409b0993          	addi	s3,s6,1033
      if(write(fds[1], buf, SZ) != SZ){
    1816:	8bda                	mv	s7,s6
    for(n = 0; n < N; n++){
    1818:	6a85                	lui	s5,0x1
    181a:	42da8a93          	addi	s5,s5,1069 # 142d <truncate3+0x85>
{
    181e:	87da                	mv	a5,s6
        buf[i] = seq++;
    1820:	0097873b          	addw	a4,a5,s1
    1824:	00e78023          	sb	a4,0(a5)
      for(i = 0; i < SZ; i++)
    1828:	0785                	addi	a5,a5,1
    182a:	fef99be3          	bne	s3,a5,1820 <pipe1+0xe2>
    182e:	409a0a1b          	addiw	s4,s4,1033
      if(write(fds[1], buf, SZ) != SZ){
    1832:	40900613          	li	a2,1033
    1836:	85de                	mv	a1,s7
    1838:	fac42503          	lw	a0,-84(s0)
    183c:	00004097          	auipc	ra,0x4
    1840:	06a080e7          	jalr	106(ra) # 58a6 <write>
    1844:	40900793          	li	a5,1033
    1848:	00f51c63          	bne	a0,a5,1860 <pipe1+0x122>
    for(n = 0; n < N; n++){
    184c:	24a5                	addiw	s1,s1,9
    184e:	0ff4f493          	andi	s1,s1,255
    1852:	fd5a16e3          	bne	s4,s5,181e <pipe1+0xe0>
    exit(0);
    1856:	4501                	li	a0,0
    1858:	00004097          	auipc	ra,0x4
    185c:	02e080e7          	jalr	46(ra) # 5886 <exit>
        printf("%s: pipe1 oops 1\n", s);
    1860:	85ca                	mv	a1,s2
    1862:	00005517          	auipc	a0,0x5
    1866:	23650513          	addi	a0,a0,566 # 6a98 <malloc+0xdc4>
    186a:	00004097          	auipc	ra,0x4
    186e:	3ac080e7          	jalr	940(ra) # 5c16 <printf>
        exit(1);
    1872:	4505                	li	a0,1
    1874:	00004097          	auipc	ra,0x4
    1878:	012080e7          	jalr	18(ra) # 5886 <exit>
          printf("%s: pipe1 oops 2\n", s);
    187c:	85ca                	mv	a1,s2
    187e:	00005517          	auipc	a0,0x5
    1882:	23250513          	addi	a0,a0,562 # 6ab0 <malloc+0xddc>
    1886:	00004097          	auipc	ra,0x4
    188a:	390080e7          	jalr	912(ra) # 5c16 <printf>
}
    188e:	60e6                	ld	ra,88(sp)
    1890:	6446                	ld	s0,80(sp)
    1892:	64a6                	ld	s1,72(sp)
    1894:	6906                	ld	s2,64(sp)
    1896:	79e2                	ld	s3,56(sp)
    1898:	7a42                	ld	s4,48(sp)
    189a:	7aa2                	ld	s5,40(sp)
    189c:	7b02                	ld	s6,32(sp)
    189e:	6be2                	ld	s7,24(sp)
    18a0:	6125                	addi	sp,sp,96
    18a2:	8082                	ret
    if(total != N * SZ){
    18a4:	6785                	lui	a5,0x1
    18a6:	42d78793          	addi	a5,a5,1069 # 142d <truncate3+0x85>
    18aa:	02fa0063          	beq	s4,a5,18ca <pipe1+0x18c>
      printf("%s: pipe1 oops 3 total %d\n", total);
    18ae:	85d2                	mv	a1,s4
    18b0:	00005517          	auipc	a0,0x5
    18b4:	21850513          	addi	a0,a0,536 # 6ac8 <malloc+0xdf4>
    18b8:	00004097          	auipc	ra,0x4
    18bc:	35e080e7          	jalr	862(ra) # 5c16 <printf>
      exit(1);
    18c0:	4505                	li	a0,1
    18c2:	00004097          	auipc	ra,0x4
    18c6:	fc4080e7          	jalr	-60(ra) # 5886 <exit>
    close(fds[0]);
    18ca:	fa842503          	lw	a0,-88(s0)
    18ce:	00004097          	auipc	ra,0x4
    18d2:	fe0080e7          	jalr	-32(ra) # 58ae <close>
    wait(&xstatus);
    18d6:	fa440513          	addi	a0,s0,-92
    18da:	00004097          	auipc	ra,0x4
    18de:	fb4080e7          	jalr	-76(ra) # 588e <wait>
    exit(xstatus);
    18e2:	fa442503          	lw	a0,-92(s0)
    18e6:	00004097          	auipc	ra,0x4
    18ea:	fa0080e7          	jalr	-96(ra) # 5886 <exit>
    printf("%s: fork() failed\n", s);
    18ee:	85ca                	mv	a1,s2
    18f0:	00005517          	auipc	a0,0x5
    18f4:	1f850513          	addi	a0,a0,504 # 6ae8 <malloc+0xe14>
    18f8:	00004097          	auipc	ra,0x4
    18fc:	31e080e7          	jalr	798(ra) # 5c16 <printf>
    exit(1);
    1900:	4505                	li	a0,1
    1902:	00004097          	auipc	ra,0x4
    1906:	f84080e7          	jalr	-124(ra) # 5886 <exit>

000000000000190a <exitwait>:
{
    190a:	7139                	addi	sp,sp,-64
    190c:	fc06                	sd	ra,56(sp)
    190e:	f822                	sd	s0,48(sp)
    1910:	f426                	sd	s1,40(sp)
    1912:	f04a                	sd	s2,32(sp)
    1914:	ec4e                	sd	s3,24(sp)
    1916:	e852                	sd	s4,16(sp)
    1918:	0080                	addi	s0,sp,64
    191a:	8a2a                	mv	s4,a0
  for(i = 0; i < 100; i++){
    191c:	4901                	li	s2,0
    191e:	06400993          	li	s3,100
    pid = fork();
    1922:	00004097          	auipc	ra,0x4
    1926:	f5c080e7          	jalr	-164(ra) # 587e <fork>
    192a:	84aa                	mv	s1,a0
    if(pid < 0){
    192c:	02054a63          	bltz	a0,1960 <exitwait+0x56>
    if(pid){
    1930:	c151                	beqz	a0,19b4 <exitwait+0xaa>
      if(wait(&xstate) != pid){
    1932:	fcc40513          	addi	a0,s0,-52
    1936:	00004097          	auipc	ra,0x4
    193a:	f58080e7          	jalr	-168(ra) # 588e <wait>
    193e:	02951f63          	bne	a0,s1,197c <exitwait+0x72>
      if(i != xstate) {
    1942:	fcc42783          	lw	a5,-52(s0)
    1946:	05279963          	bne	a5,s2,1998 <exitwait+0x8e>
  for(i = 0; i < 100; i++){
    194a:	2905                	addiw	s2,s2,1
    194c:	fd391be3          	bne	s2,s3,1922 <exitwait+0x18>
}
    1950:	70e2                	ld	ra,56(sp)
    1952:	7442                	ld	s0,48(sp)
    1954:	74a2                	ld	s1,40(sp)
    1956:	7902                	ld	s2,32(sp)
    1958:	69e2                	ld	s3,24(sp)
    195a:	6a42                	ld	s4,16(sp)
    195c:	6121                	addi	sp,sp,64
    195e:	8082                	ret
      printf("%s: fork failed\n", s);
    1960:	85d2                	mv	a1,s4
    1962:	00005517          	auipc	a0,0x5
    1966:	01650513          	addi	a0,a0,22 # 6978 <malloc+0xca4>
    196a:	00004097          	auipc	ra,0x4
    196e:	2ac080e7          	jalr	684(ra) # 5c16 <printf>
      exit(1);
    1972:	4505                	li	a0,1
    1974:	00004097          	auipc	ra,0x4
    1978:	f12080e7          	jalr	-238(ra) # 5886 <exit>
        printf("%s: wait wrong pid\n", s);
    197c:	85d2                	mv	a1,s4
    197e:	00005517          	auipc	a0,0x5
    1982:	18250513          	addi	a0,a0,386 # 6b00 <malloc+0xe2c>
    1986:	00004097          	auipc	ra,0x4
    198a:	290080e7          	jalr	656(ra) # 5c16 <printf>
        exit(1);
    198e:	4505                	li	a0,1
    1990:	00004097          	auipc	ra,0x4
    1994:	ef6080e7          	jalr	-266(ra) # 5886 <exit>
        printf("%s: wait wrong exit status\n", s);
    1998:	85d2                	mv	a1,s4
    199a:	00005517          	auipc	a0,0x5
    199e:	17e50513          	addi	a0,a0,382 # 6b18 <malloc+0xe44>
    19a2:	00004097          	auipc	ra,0x4
    19a6:	274080e7          	jalr	628(ra) # 5c16 <printf>
        exit(1);
    19aa:	4505                	li	a0,1
    19ac:	00004097          	auipc	ra,0x4
    19b0:	eda080e7          	jalr	-294(ra) # 5886 <exit>
      exit(i);
    19b4:	854a                	mv	a0,s2
    19b6:	00004097          	auipc	ra,0x4
    19ba:	ed0080e7          	jalr	-304(ra) # 5886 <exit>

00000000000019be <twochildren>:
{
    19be:	1101                	addi	sp,sp,-32
    19c0:	ec06                	sd	ra,24(sp)
    19c2:	e822                	sd	s0,16(sp)
    19c4:	e426                	sd	s1,8(sp)
    19c6:	e04a                	sd	s2,0(sp)
    19c8:	1000                	addi	s0,sp,32
    19ca:	892a                	mv	s2,a0
    19cc:	3e800493          	li	s1,1000
    int pid1 = fork();
    19d0:	00004097          	auipc	ra,0x4
    19d4:	eae080e7          	jalr	-338(ra) # 587e <fork>
    if(pid1 < 0){
    19d8:	02054c63          	bltz	a0,1a10 <twochildren+0x52>
    if(pid1 == 0){
    19dc:	c921                	beqz	a0,1a2c <twochildren+0x6e>
      int pid2 = fork();
    19de:	00004097          	auipc	ra,0x4
    19e2:	ea0080e7          	jalr	-352(ra) # 587e <fork>
      if(pid2 < 0){
    19e6:	04054763          	bltz	a0,1a34 <twochildren+0x76>
      if(pid2 == 0){
    19ea:	c13d                	beqz	a0,1a50 <twochildren+0x92>
        wait(0);
    19ec:	4501                	li	a0,0
    19ee:	00004097          	auipc	ra,0x4
    19f2:	ea0080e7          	jalr	-352(ra) # 588e <wait>
        wait(0);
    19f6:	4501                	li	a0,0
    19f8:	00004097          	auipc	ra,0x4
    19fc:	e96080e7          	jalr	-362(ra) # 588e <wait>
  for(int i = 0; i < 1000; i++){
    1a00:	34fd                	addiw	s1,s1,-1
    1a02:	f4f9                	bnez	s1,19d0 <twochildren+0x12>
}
    1a04:	60e2                	ld	ra,24(sp)
    1a06:	6442                	ld	s0,16(sp)
    1a08:	64a2                	ld	s1,8(sp)
    1a0a:	6902                	ld	s2,0(sp)
    1a0c:	6105                	addi	sp,sp,32
    1a0e:	8082                	ret
      printf("%s: fork failed\n", s);
    1a10:	85ca                	mv	a1,s2
    1a12:	00005517          	auipc	a0,0x5
    1a16:	f6650513          	addi	a0,a0,-154 # 6978 <malloc+0xca4>
    1a1a:	00004097          	auipc	ra,0x4
    1a1e:	1fc080e7          	jalr	508(ra) # 5c16 <printf>
      exit(1);
    1a22:	4505                	li	a0,1
    1a24:	00004097          	auipc	ra,0x4
    1a28:	e62080e7          	jalr	-414(ra) # 5886 <exit>
      exit(0);
    1a2c:	00004097          	auipc	ra,0x4
    1a30:	e5a080e7          	jalr	-422(ra) # 5886 <exit>
        printf("%s: fork failed\n", s);
    1a34:	85ca                	mv	a1,s2
    1a36:	00005517          	auipc	a0,0x5
    1a3a:	f4250513          	addi	a0,a0,-190 # 6978 <malloc+0xca4>
    1a3e:	00004097          	auipc	ra,0x4
    1a42:	1d8080e7          	jalr	472(ra) # 5c16 <printf>
        exit(1);
    1a46:	4505                	li	a0,1
    1a48:	00004097          	auipc	ra,0x4
    1a4c:	e3e080e7          	jalr	-450(ra) # 5886 <exit>
        exit(0);
    1a50:	00004097          	auipc	ra,0x4
    1a54:	e36080e7          	jalr	-458(ra) # 5886 <exit>

0000000000001a58 <forkfork>:
{
    1a58:	7179                	addi	sp,sp,-48
    1a5a:	f406                	sd	ra,40(sp)
    1a5c:	f022                	sd	s0,32(sp)
    1a5e:	ec26                	sd	s1,24(sp)
    1a60:	1800                	addi	s0,sp,48
    1a62:	84aa                	mv	s1,a0
    int pid = fork();
    1a64:	00004097          	auipc	ra,0x4
    1a68:	e1a080e7          	jalr	-486(ra) # 587e <fork>
    if(pid < 0){
    1a6c:	04054163          	bltz	a0,1aae <forkfork+0x56>
    if(pid == 0){
    1a70:	cd29                	beqz	a0,1aca <forkfork+0x72>
    int pid = fork();
    1a72:	00004097          	auipc	ra,0x4
    1a76:	e0c080e7          	jalr	-500(ra) # 587e <fork>
    if(pid < 0){
    1a7a:	02054a63          	bltz	a0,1aae <forkfork+0x56>
    if(pid == 0){
    1a7e:	c531                	beqz	a0,1aca <forkfork+0x72>
    wait(&xstatus);
    1a80:	fdc40513          	addi	a0,s0,-36
    1a84:	00004097          	auipc	ra,0x4
    1a88:	e0a080e7          	jalr	-502(ra) # 588e <wait>
    if(xstatus != 0) {
    1a8c:	fdc42783          	lw	a5,-36(s0)
    1a90:	ebbd                	bnez	a5,1b06 <forkfork+0xae>
    wait(&xstatus);
    1a92:	fdc40513          	addi	a0,s0,-36
    1a96:	00004097          	auipc	ra,0x4
    1a9a:	df8080e7          	jalr	-520(ra) # 588e <wait>
    if(xstatus != 0) {
    1a9e:	fdc42783          	lw	a5,-36(s0)
    1aa2:	e3b5                	bnez	a5,1b06 <forkfork+0xae>
}
    1aa4:	70a2                	ld	ra,40(sp)
    1aa6:	7402                	ld	s0,32(sp)
    1aa8:	64e2                	ld	s1,24(sp)
    1aaa:	6145                	addi	sp,sp,48
    1aac:	8082                	ret
      printf("%s: fork failed", s);
    1aae:	85a6                	mv	a1,s1
    1ab0:	00005517          	auipc	a0,0x5
    1ab4:	08850513          	addi	a0,a0,136 # 6b38 <malloc+0xe64>
    1ab8:	00004097          	auipc	ra,0x4
    1abc:	15e080e7          	jalr	350(ra) # 5c16 <printf>
      exit(1);
    1ac0:	4505                	li	a0,1
    1ac2:	00004097          	auipc	ra,0x4
    1ac6:	dc4080e7          	jalr	-572(ra) # 5886 <exit>
{
    1aca:	0c800493          	li	s1,200
        int pid1 = fork();
    1ace:	00004097          	auipc	ra,0x4
    1ad2:	db0080e7          	jalr	-592(ra) # 587e <fork>
        if(pid1 < 0){
    1ad6:	00054f63          	bltz	a0,1af4 <forkfork+0x9c>
        if(pid1 == 0){
    1ada:	c115                	beqz	a0,1afe <forkfork+0xa6>
        wait(0);
    1adc:	4501                	li	a0,0
    1ade:	00004097          	auipc	ra,0x4
    1ae2:	db0080e7          	jalr	-592(ra) # 588e <wait>
      for(int j = 0; j < 200; j++){
    1ae6:	34fd                	addiw	s1,s1,-1
    1ae8:	f0fd                	bnez	s1,1ace <forkfork+0x76>
      exit(0);
    1aea:	4501                	li	a0,0
    1aec:	00004097          	auipc	ra,0x4
    1af0:	d9a080e7          	jalr	-614(ra) # 5886 <exit>
          exit(1);
    1af4:	4505                	li	a0,1
    1af6:	00004097          	auipc	ra,0x4
    1afa:	d90080e7          	jalr	-624(ra) # 5886 <exit>
          exit(0);
    1afe:	00004097          	auipc	ra,0x4
    1b02:	d88080e7          	jalr	-632(ra) # 5886 <exit>
      printf("%s: fork in child failed", s);
    1b06:	85a6                	mv	a1,s1
    1b08:	00005517          	auipc	a0,0x5
    1b0c:	04050513          	addi	a0,a0,64 # 6b48 <malloc+0xe74>
    1b10:	00004097          	auipc	ra,0x4
    1b14:	106080e7          	jalr	262(ra) # 5c16 <printf>
      exit(1);
    1b18:	4505                	li	a0,1
    1b1a:	00004097          	auipc	ra,0x4
    1b1e:	d6c080e7          	jalr	-660(ra) # 5886 <exit>

0000000000001b22 <reparent2>:
{
    1b22:	1101                	addi	sp,sp,-32
    1b24:	ec06                	sd	ra,24(sp)
    1b26:	e822                	sd	s0,16(sp)
    1b28:	e426                	sd	s1,8(sp)
    1b2a:	1000                	addi	s0,sp,32
    1b2c:	32000493          	li	s1,800
    int pid1 = fork();
    1b30:	00004097          	auipc	ra,0x4
    1b34:	d4e080e7          	jalr	-690(ra) # 587e <fork>
    if(pid1 < 0){
    1b38:	00054f63          	bltz	a0,1b56 <reparent2+0x34>
    if(pid1 == 0){
    1b3c:	c915                	beqz	a0,1b70 <reparent2+0x4e>
    wait(0);
    1b3e:	4501                	li	a0,0
    1b40:	00004097          	auipc	ra,0x4
    1b44:	d4e080e7          	jalr	-690(ra) # 588e <wait>
  for(int i = 0; i < 800; i++){
    1b48:	34fd                	addiw	s1,s1,-1
    1b4a:	f0fd                	bnez	s1,1b30 <reparent2+0xe>
  exit(0);
    1b4c:	4501                	li	a0,0
    1b4e:	00004097          	auipc	ra,0x4
    1b52:	d38080e7          	jalr	-712(ra) # 5886 <exit>
      printf("fork failed\n");
    1b56:	00005517          	auipc	a0,0x5
    1b5a:	22a50513          	addi	a0,a0,554 # 6d80 <malloc+0x10ac>
    1b5e:	00004097          	auipc	ra,0x4
    1b62:	0b8080e7          	jalr	184(ra) # 5c16 <printf>
      exit(1);
    1b66:	4505                	li	a0,1
    1b68:	00004097          	auipc	ra,0x4
    1b6c:	d1e080e7          	jalr	-738(ra) # 5886 <exit>
      fork();
    1b70:	00004097          	auipc	ra,0x4
    1b74:	d0e080e7          	jalr	-754(ra) # 587e <fork>
      fork();
    1b78:	00004097          	auipc	ra,0x4
    1b7c:	d06080e7          	jalr	-762(ra) # 587e <fork>
      exit(0);
    1b80:	4501                	li	a0,0
    1b82:	00004097          	auipc	ra,0x4
    1b86:	d04080e7          	jalr	-764(ra) # 5886 <exit>

0000000000001b8a <createdelete>:
{
    1b8a:	7175                	addi	sp,sp,-144
    1b8c:	e506                	sd	ra,136(sp)
    1b8e:	e122                	sd	s0,128(sp)
    1b90:	fca6                	sd	s1,120(sp)
    1b92:	f8ca                	sd	s2,112(sp)
    1b94:	f4ce                	sd	s3,104(sp)
    1b96:	f0d2                	sd	s4,96(sp)
    1b98:	ecd6                	sd	s5,88(sp)
    1b9a:	e8da                	sd	s6,80(sp)
    1b9c:	e4de                	sd	s7,72(sp)
    1b9e:	e0e2                	sd	s8,64(sp)
    1ba0:	fc66                	sd	s9,56(sp)
    1ba2:	0900                	addi	s0,sp,144
    1ba4:	8caa                	mv	s9,a0
  for(pi = 0; pi < NCHILD; pi++){
    1ba6:	4901                	li	s2,0
    1ba8:	4991                	li	s3,4
    pid = fork();
    1baa:	00004097          	auipc	ra,0x4
    1bae:	cd4080e7          	jalr	-812(ra) # 587e <fork>
    1bb2:	84aa                	mv	s1,a0
    if(pid < 0){
    1bb4:	02054f63          	bltz	a0,1bf2 <createdelete+0x68>
    if(pid == 0){
    1bb8:	c939                	beqz	a0,1c0e <createdelete+0x84>
  for(pi = 0; pi < NCHILD; pi++){
    1bba:	2905                	addiw	s2,s2,1
    1bbc:	ff3917e3          	bne	s2,s3,1baa <createdelete+0x20>
    1bc0:	4491                	li	s1,4
    wait(&xstatus);
    1bc2:	f7c40513          	addi	a0,s0,-132
    1bc6:	00004097          	auipc	ra,0x4
    1bca:	cc8080e7          	jalr	-824(ra) # 588e <wait>
    if(xstatus != 0)
    1bce:	f7c42903          	lw	s2,-132(s0)
    1bd2:	0e091263          	bnez	s2,1cb6 <createdelete+0x12c>
  for(pi = 0; pi < NCHILD; pi++){
    1bd6:	34fd                	addiw	s1,s1,-1
    1bd8:	f4ed                	bnez	s1,1bc2 <createdelete+0x38>
  name[0] = name[1] = name[2] = 0;
    1bda:	f8040123          	sb	zero,-126(s0)
    1bde:	03000993          	li	s3,48
    1be2:	5a7d                	li	s4,-1
    1be4:	07000c13          	li	s8,112
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1be8:	4b21                	li	s6,8
      if((i == 0 || i >= N/2) && fd < 0){
    1bea:	4ba5                	li	s7,9
    for(pi = 0; pi < NCHILD; pi++){
    1bec:	07400a93          	li	s5,116
    1bf0:	a29d                	j	1d56 <createdelete+0x1cc>
      printf("fork failed\n", s);
    1bf2:	85e6                	mv	a1,s9
    1bf4:	00005517          	auipc	a0,0x5
    1bf8:	18c50513          	addi	a0,a0,396 # 6d80 <malloc+0x10ac>
    1bfc:	00004097          	auipc	ra,0x4
    1c00:	01a080e7          	jalr	26(ra) # 5c16 <printf>
      exit(1);
    1c04:	4505                	li	a0,1
    1c06:	00004097          	auipc	ra,0x4
    1c0a:	c80080e7          	jalr	-896(ra) # 5886 <exit>
      name[0] = 'p' + pi;
    1c0e:	0709091b          	addiw	s2,s2,112
    1c12:	f9240023          	sb	s2,-128(s0)
      name[2] = '\0';
    1c16:	f8040123          	sb	zero,-126(s0)
      for(i = 0; i < N; i++){
    1c1a:	4951                	li	s2,20
    1c1c:	a015                	j	1c40 <createdelete+0xb6>
          printf("%s: create failed\n", s);
    1c1e:	85e6                	mv	a1,s9
    1c20:	00005517          	auipc	a0,0x5
    1c24:	df050513          	addi	a0,a0,-528 # 6a10 <malloc+0xd3c>
    1c28:	00004097          	auipc	ra,0x4
    1c2c:	fee080e7          	jalr	-18(ra) # 5c16 <printf>
          exit(1);
    1c30:	4505                	li	a0,1
    1c32:	00004097          	auipc	ra,0x4
    1c36:	c54080e7          	jalr	-940(ra) # 5886 <exit>
      for(i = 0; i < N; i++){
    1c3a:	2485                	addiw	s1,s1,1
    1c3c:	07248863          	beq	s1,s2,1cac <createdelete+0x122>
        name[1] = '0' + i;
    1c40:	0304879b          	addiw	a5,s1,48
    1c44:	f8f400a3          	sb	a5,-127(s0)
        fd = open(name, O_CREATE | O_RDWR);
    1c48:	20200593          	li	a1,514
    1c4c:	f8040513          	addi	a0,s0,-128
    1c50:	00004097          	auipc	ra,0x4
    1c54:	c76080e7          	jalr	-906(ra) # 58c6 <open>
        if(fd < 0){
    1c58:	fc0543e3          	bltz	a0,1c1e <createdelete+0x94>
        close(fd);
    1c5c:	00004097          	auipc	ra,0x4
    1c60:	c52080e7          	jalr	-942(ra) # 58ae <close>
        if(i > 0 && (i % 2 ) == 0){
    1c64:	fc905be3          	blez	s1,1c3a <createdelete+0xb0>
    1c68:	0014f793          	andi	a5,s1,1
    1c6c:	f7f9                	bnez	a5,1c3a <createdelete+0xb0>
          name[1] = '0' + (i / 2);
    1c6e:	01f4d79b          	srliw	a5,s1,0x1f
    1c72:	9fa5                	addw	a5,a5,s1
    1c74:	4017d79b          	sraiw	a5,a5,0x1
    1c78:	0307879b          	addiw	a5,a5,48
    1c7c:	f8f400a3          	sb	a5,-127(s0)
          if(unlink(name) < 0){
    1c80:	f8040513          	addi	a0,s0,-128
    1c84:	00004097          	auipc	ra,0x4
    1c88:	c52080e7          	jalr	-942(ra) # 58d6 <unlink>
    1c8c:	fa0557e3          	bgez	a0,1c3a <createdelete+0xb0>
            printf("%s: unlink failed\n", s);
    1c90:	85e6                	mv	a1,s9
    1c92:	00005517          	auipc	a0,0x5
    1c96:	ed650513          	addi	a0,a0,-298 # 6b68 <malloc+0xe94>
    1c9a:	00004097          	auipc	ra,0x4
    1c9e:	f7c080e7          	jalr	-132(ra) # 5c16 <printf>
            exit(1);
    1ca2:	4505                	li	a0,1
    1ca4:	00004097          	auipc	ra,0x4
    1ca8:	be2080e7          	jalr	-1054(ra) # 5886 <exit>
      exit(0);
    1cac:	4501                	li	a0,0
    1cae:	00004097          	auipc	ra,0x4
    1cb2:	bd8080e7          	jalr	-1064(ra) # 5886 <exit>
      exit(1);
    1cb6:	4505                	li	a0,1
    1cb8:	00004097          	auipc	ra,0x4
    1cbc:	bce080e7          	jalr	-1074(ra) # 5886 <exit>
        printf("%s: oops createdelete %s didn't exist\n", s, name);
    1cc0:	f8040613          	addi	a2,s0,-128
    1cc4:	85e6                	mv	a1,s9
    1cc6:	00005517          	auipc	a0,0x5
    1cca:	eba50513          	addi	a0,a0,-326 # 6b80 <malloc+0xeac>
    1cce:	00004097          	auipc	ra,0x4
    1cd2:	f48080e7          	jalr	-184(ra) # 5c16 <printf>
        exit(1);
    1cd6:	4505                	li	a0,1
    1cd8:	00004097          	auipc	ra,0x4
    1cdc:	bae080e7          	jalr	-1106(ra) # 5886 <exit>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1ce0:	054b7163          	bgeu	s6,s4,1d22 <createdelete+0x198>
      if(fd >= 0)
    1ce4:	02055a63          	bgez	a0,1d18 <createdelete+0x18e>
    for(pi = 0; pi < NCHILD; pi++){
    1ce8:	2485                	addiw	s1,s1,1
    1cea:	0ff4f493          	andi	s1,s1,255
    1cee:	05548c63          	beq	s1,s5,1d46 <createdelete+0x1bc>
      name[0] = 'p' + pi;
    1cf2:	f8940023          	sb	s1,-128(s0)
      name[1] = '0' + i;
    1cf6:	f93400a3          	sb	s3,-127(s0)
      fd = open(name, 0);
    1cfa:	4581                	li	a1,0
    1cfc:	f8040513          	addi	a0,s0,-128
    1d00:	00004097          	auipc	ra,0x4
    1d04:	bc6080e7          	jalr	-1082(ra) # 58c6 <open>
      if((i == 0 || i >= N/2) && fd < 0){
    1d08:	00090463          	beqz	s2,1d10 <createdelete+0x186>
    1d0c:	fd2bdae3          	bge	s7,s2,1ce0 <createdelete+0x156>
    1d10:	fa0548e3          	bltz	a0,1cc0 <createdelete+0x136>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1d14:	014b7963          	bgeu	s6,s4,1d26 <createdelete+0x19c>
        close(fd);
    1d18:	00004097          	auipc	ra,0x4
    1d1c:	b96080e7          	jalr	-1130(ra) # 58ae <close>
    1d20:	b7e1                	j	1ce8 <createdelete+0x15e>
      } else if((i >= 1 && i < N/2) && fd >= 0){
    1d22:	fc0543e3          	bltz	a0,1ce8 <createdelete+0x15e>
        printf("%s: oops createdelete %s did exist\n", s, name);
    1d26:	f8040613          	addi	a2,s0,-128
    1d2a:	85e6                	mv	a1,s9
    1d2c:	00005517          	auipc	a0,0x5
    1d30:	e7c50513          	addi	a0,a0,-388 # 6ba8 <malloc+0xed4>
    1d34:	00004097          	auipc	ra,0x4
    1d38:	ee2080e7          	jalr	-286(ra) # 5c16 <printf>
        exit(1);
    1d3c:	4505                	li	a0,1
    1d3e:	00004097          	auipc	ra,0x4
    1d42:	b48080e7          	jalr	-1208(ra) # 5886 <exit>
  for(i = 0; i < N; i++){
    1d46:	2905                	addiw	s2,s2,1
    1d48:	2a05                	addiw	s4,s4,1
    1d4a:	2985                	addiw	s3,s3,1
    1d4c:	0ff9f993          	andi	s3,s3,255
    1d50:	47d1                	li	a5,20
    1d52:	02f90a63          	beq	s2,a5,1d86 <createdelete+0x1fc>
    for(pi = 0; pi < NCHILD; pi++){
    1d56:	84e2                	mv	s1,s8
    1d58:	bf69                	j	1cf2 <createdelete+0x168>
  for(i = 0; i < N; i++){
    1d5a:	2905                	addiw	s2,s2,1
    1d5c:	0ff97913          	andi	s2,s2,255
    1d60:	2985                	addiw	s3,s3,1
    1d62:	0ff9f993          	andi	s3,s3,255
    1d66:	03490863          	beq	s2,s4,1d96 <createdelete+0x20c>
  name[0] = name[1] = name[2] = 0;
    1d6a:	84d6                	mv	s1,s5
      name[0] = 'p' + i;
    1d6c:	f9240023          	sb	s2,-128(s0)
      name[1] = '0' + i;
    1d70:	f93400a3          	sb	s3,-127(s0)
      unlink(name);
    1d74:	f8040513          	addi	a0,s0,-128
    1d78:	00004097          	auipc	ra,0x4
    1d7c:	b5e080e7          	jalr	-1186(ra) # 58d6 <unlink>
    for(pi = 0; pi < NCHILD; pi++){
    1d80:	34fd                	addiw	s1,s1,-1
    1d82:	f4ed                	bnez	s1,1d6c <createdelete+0x1e2>
    1d84:	bfd9                	j	1d5a <createdelete+0x1d0>
    1d86:	03000993          	li	s3,48
    1d8a:	07000913          	li	s2,112
  name[0] = name[1] = name[2] = 0;
    1d8e:	4a91                	li	s5,4
  for(i = 0; i < N; i++){
    1d90:	08400a13          	li	s4,132
    1d94:	bfd9                	j	1d6a <createdelete+0x1e0>
}
    1d96:	60aa                	ld	ra,136(sp)
    1d98:	640a                	ld	s0,128(sp)
    1d9a:	74e6                	ld	s1,120(sp)
    1d9c:	7946                	ld	s2,112(sp)
    1d9e:	79a6                	ld	s3,104(sp)
    1da0:	7a06                	ld	s4,96(sp)
    1da2:	6ae6                	ld	s5,88(sp)
    1da4:	6b46                	ld	s6,80(sp)
    1da6:	6ba6                	ld	s7,72(sp)
    1da8:	6c06                	ld	s8,64(sp)
    1daa:	7ce2                	ld	s9,56(sp)
    1dac:	6149                	addi	sp,sp,144
    1dae:	8082                	ret

0000000000001db0 <linkunlink>:
{
    1db0:	711d                	addi	sp,sp,-96
    1db2:	ec86                	sd	ra,88(sp)
    1db4:	e8a2                	sd	s0,80(sp)
    1db6:	e4a6                	sd	s1,72(sp)
    1db8:	e0ca                	sd	s2,64(sp)
    1dba:	fc4e                	sd	s3,56(sp)
    1dbc:	f852                	sd	s4,48(sp)
    1dbe:	f456                	sd	s5,40(sp)
    1dc0:	f05a                	sd	s6,32(sp)
    1dc2:	ec5e                	sd	s7,24(sp)
    1dc4:	e862                	sd	s8,16(sp)
    1dc6:	e466                	sd	s9,8(sp)
    1dc8:	1080                	addi	s0,sp,96
    1dca:	84aa                	mv	s1,a0
  unlink("x");
    1dcc:	00004517          	auipc	a0,0x4
    1dd0:	3e450513          	addi	a0,a0,996 # 61b0 <malloc+0x4dc>
    1dd4:	00004097          	auipc	ra,0x4
    1dd8:	b02080e7          	jalr	-1278(ra) # 58d6 <unlink>
  pid = fork();
    1ddc:	00004097          	auipc	ra,0x4
    1de0:	aa2080e7          	jalr	-1374(ra) # 587e <fork>
  if(pid < 0){
    1de4:	02054b63          	bltz	a0,1e1a <linkunlink+0x6a>
    1de8:	8c2a                	mv	s8,a0
  unsigned int x = (pid ? 1 : 97);
    1dea:	4c85                	li	s9,1
    1dec:	e119                	bnez	a0,1df2 <linkunlink+0x42>
    1dee:	06100c93          	li	s9,97
    1df2:	06400493          	li	s1,100
    x = x * 1103515245 + 12345;
    1df6:	41c659b7          	lui	s3,0x41c65
    1dfa:	e6d9899b          	addiw	s3,s3,-403
    1dfe:	690d                	lui	s2,0x3
    1e00:	0399091b          	addiw	s2,s2,57
    if((x % 3) == 0){
    1e04:	4a0d                	li	s4,3
    } else if((x % 3) == 1){
    1e06:	4b05                	li	s6,1
      unlink("x");
    1e08:	00004a97          	auipc	s5,0x4
    1e0c:	3a8a8a93          	addi	s5,s5,936 # 61b0 <malloc+0x4dc>
      link("cat", "x");
    1e10:	00005b97          	auipc	s7,0x5
    1e14:	dc0b8b93          	addi	s7,s7,-576 # 6bd0 <malloc+0xefc>
    1e18:	a091                	j	1e5c <linkunlink+0xac>
    printf("%s: fork failed\n", s);
    1e1a:	85a6                	mv	a1,s1
    1e1c:	00005517          	auipc	a0,0x5
    1e20:	b5c50513          	addi	a0,a0,-1188 # 6978 <malloc+0xca4>
    1e24:	00004097          	auipc	ra,0x4
    1e28:	df2080e7          	jalr	-526(ra) # 5c16 <printf>
    exit(1);
    1e2c:	4505                	li	a0,1
    1e2e:	00004097          	auipc	ra,0x4
    1e32:	a58080e7          	jalr	-1448(ra) # 5886 <exit>
      close(open("x", O_RDWR | O_CREATE));
    1e36:	20200593          	li	a1,514
    1e3a:	8556                	mv	a0,s5
    1e3c:	00004097          	auipc	ra,0x4
    1e40:	a8a080e7          	jalr	-1398(ra) # 58c6 <open>
    1e44:	00004097          	auipc	ra,0x4
    1e48:	a6a080e7          	jalr	-1430(ra) # 58ae <close>
    1e4c:	a031                	j	1e58 <linkunlink+0xa8>
      unlink("x");
    1e4e:	8556                	mv	a0,s5
    1e50:	00004097          	auipc	ra,0x4
    1e54:	a86080e7          	jalr	-1402(ra) # 58d6 <unlink>
  for(i = 0; i < 100; i++){
    1e58:	34fd                	addiw	s1,s1,-1
    1e5a:	c09d                	beqz	s1,1e80 <linkunlink+0xd0>
    x = x * 1103515245 + 12345;
    1e5c:	033c87bb          	mulw	a5,s9,s3
    1e60:	012787bb          	addw	a5,a5,s2
    1e64:	00078c9b          	sext.w	s9,a5
    if((x % 3) == 0){
    1e68:	0347f7bb          	remuw	a5,a5,s4
    1e6c:	d7e9                	beqz	a5,1e36 <linkunlink+0x86>
    } else if((x % 3) == 1){
    1e6e:	ff6790e3          	bne	a5,s6,1e4e <linkunlink+0x9e>
      link("cat", "x");
    1e72:	85d6                	mv	a1,s5
    1e74:	855e                	mv	a0,s7
    1e76:	00004097          	auipc	ra,0x4
    1e7a:	a70080e7          	jalr	-1424(ra) # 58e6 <link>
    1e7e:	bfe9                	j	1e58 <linkunlink+0xa8>
  if(pid)
    1e80:	020c0463          	beqz	s8,1ea8 <linkunlink+0xf8>
    wait(0);
    1e84:	4501                	li	a0,0
    1e86:	00004097          	auipc	ra,0x4
    1e8a:	a08080e7          	jalr	-1528(ra) # 588e <wait>
}
    1e8e:	60e6                	ld	ra,88(sp)
    1e90:	6446                	ld	s0,80(sp)
    1e92:	64a6                	ld	s1,72(sp)
    1e94:	6906                	ld	s2,64(sp)
    1e96:	79e2                	ld	s3,56(sp)
    1e98:	7a42                	ld	s4,48(sp)
    1e9a:	7aa2                	ld	s5,40(sp)
    1e9c:	7b02                	ld	s6,32(sp)
    1e9e:	6be2                	ld	s7,24(sp)
    1ea0:	6c42                	ld	s8,16(sp)
    1ea2:	6ca2                	ld	s9,8(sp)
    1ea4:	6125                	addi	sp,sp,96
    1ea6:	8082                	ret
    exit(0);
    1ea8:	4501                	li	a0,0
    1eaa:	00004097          	auipc	ra,0x4
    1eae:	9dc080e7          	jalr	-1572(ra) # 5886 <exit>

0000000000001eb2 <forktest>:
{
    1eb2:	7179                	addi	sp,sp,-48
    1eb4:	f406                	sd	ra,40(sp)
    1eb6:	f022                	sd	s0,32(sp)
    1eb8:	ec26                	sd	s1,24(sp)
    1eba:	e84a                	sd	s2,16(sp)
    1ebc:	e44e                	sd	s3,8(sp)
    1ebe:	1800                	addi	s0,sp,48
    1ec0:	89aa                	mv	s3,a0
  for(n=0; n<N; n++){
    1ec2:	4481                	li	s1,0
    1ec4:	3e800913          	li	s2,1000
    pid = fork();
    1ec8:	00004097          	auipc	ra,0x4
    1ecc:	9b6080e7          	jalr	-1610(ra) # 587e <fork>
    if(pid < 0)
    1ed0:	02054863          	bltz	a0,1f00 <forktest+0x4e>
    if(pid == 0)
    1ed4:	c115                	beqz	a0,1ef8 <forktest+0x46>
  for(n=0; n<N; n++){
    1ed6:	2485                	addiw	s1,s1,1
    1ed8:	ff2498e3          	bne	s1,s2,1ec8 <forktest+0x16>
    printf("%s: fork claimed to work 1000 times!\n", s);
    1edc:	85ce                	mv	a1,s3
    1ede:	00005517          	auipc	a0,0x5
    1ee2:	d1250513          	addi	a0,a0,-750 # 6bf0 <malloc+0xf1c>
    1ee6:	00004097          	auipc	ra,0x4
    1eea:	d30080e7          	jalr	-720(ra) # 5c16 <printf>
    exit(1);
    1eee:	4505                	li	a0,1
    1ef0:	00004097          	auipc	ra,0x4
    1ef4:	996080e7          	jalr	-1642(ra) # 5886 <exit>
      exit(0);
    1ef8:	00004097          	auipc	ra,0x4
    1efc:	98e080e7          	jalr	-1650(ra) # 5886 <exit>
  if (n == 0) {
    1f00:	cc9d                	beqz	s1,1f3e <forktest+0x8c>
  if(n == N){
    1f02:	3e800793          	li	a5,1000
    1f06:	fcf48be3          	beq	s1,a5,1edc <forktest+0x2a>
  for(; n > 0; n--){
    1f0a:	00905b63          	blez	s1,1f20 <forktest+0x6e>
    if(wait(0) < 0){
    1f0e:	4501                	li	a0,0
    1f10:	00004097          	auipc	ra,0x4
    1f14:	97e080e7          	jalr	-1666(ra) # 588e <wait>
    1f18:	04054163          	bltz	a0,1f5a <forktest+0xa8>
  for(; n > 0; n--){
    1f1c:	34fd                	addiw	s1,s1,-1
    1f1e:	f8e5                	bnez	s1,1f0e <forktest+0x5c>
  if(wait(0) != -1){
    1f20:	4501                	li	a0,0
    1f22:	00004097          	auipc	ra,0x4
    1f26:	96c080e7          	jalr	-1684(ra) # 588e <wait>
    1f2a:	57fd                	li	a5,-1
    1f2c:	04f51563          	bne	a0,a5,1f76 <forktest+0xc4>
}
    1f30:	70a2                	ld	ra,40(sp)
    1f32:	7402                	ld	s0,32(sp)
    1f34:	64e2                	ld	s1,24(sp)
    1f36:	6942                	ld	s2,16(sp)
    1f38:	69a2                	ld	s3,8(sp)
    1f3a:	6145                	addi	sp,sp,48
    1f3c:	8082                	ret
    printf("%s: no fork at all!\n", s);
    1f3e:	85ce                	mv	a1,s3
    1f40:	00005517          	auipc	a0,0x5
    1f44:	c9850513          	addi	a0,a0,-872 # 6bd8 <malloc+0xf04>
    1f48:	00004097          	auipc	ra,0x4
    1f4c:	cce080e7          	jalr	-818(ra) # 5c16 <printf>
    exit(1);
    1f50:	4505                	li	a0,1
    1f52:	00004097          	auipc	ra,0x4
    1f56:	934080e7          	jalr	-1740(ra) # 5886 <exit>
      printf("%s: wait stopped early\n", s);
    1f5a:	85ce                	mv	a1,s3
    1f5c:	00005517          	auipc	a0,0x5
    1f60:	cbc50513          	addi	a0,a0,-836 # 6c18 <malloc+0xf44>
    1f64:	00004097          	auipc	ra,0x4
    1f68:	cb2080e7          	jalr	-846(ra) # 5c16 <printf>
      exit(1);
    1f6c:	4505                	li	a0,1
    1f6e:	00004097          	auipc	ra,0x4
    1f72:	918080e7          	jalr	-1768(ra) # 5886 <exit>
    printf("%s: wait got too many\n", s);
    1f76:	85ce                	mv	a1,s3
    1f78:	00005517          	auipc	a0,0x5
    1f7c:	cb850513          	addi	a0,a0,-840 # 6c30 <malloc+0xf5c>
    1f80:	00004097          	auipc	ra,0x4
    1f84:	c96080e7          	jalr	-874(ra) # 5c16 <printf>
    exit(1);
    1f88:	4505                	li	a0,1
    1f8a:	00004097          	auipc	ra,0x4
    1f8e:	8fc080e7          	jalr	-1796(ra) # 5886 <exit>

0000000000001f92 <kernmem>:
{
    1f92:	715d                	addi	sp,sp,-80
    1f94:	e486                	sd	ra,72(sp)
    1f96:	e0a2                	sd	s0,64(sp)
    1f98:	fc26                	sd	s1,56(sp)
    1f9a:	f84a                	sd	s2,48(sp)
    1f9c:	f44e                	sd	s3,40(sp)
    1f9e:	f052                	sd	s4,32(sp)
    1fa0:	ec56                	sd	s5,24(sp)
    1fa2:	0880                	addi	s0,sp,80
    1fa4:	8a2a                	mv	s4,a0
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    1fa6:	4485                	li	s1,1
    1fa8:	04fe                	slli	s1,s1,0x1f
    if(xstatus != -1)  // did kernel kill child?
    1faa:	5afd                	li	s5,-1
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    1fac:	69b1                	lui	s3,0xc
    1fae:	35098993          	addi	s3,s3,848 # c350 <buf+0x548>
    1fb2:	1003d937          	lui	s2,0x1003d
    1fb6:	090e                	slli	s2,s2,0x3
    1fb8:	48090913          	addi	s2,s2,1152 # 1003d480 <__BSS_END__+0x1002e668>
    pid = fork();
    1fbc:	00004097          	auipc	ra,0x4
    1fc0:	8c2080e7          	jalr	-1854(ra) # 587e <fork>
    if(pid < 0){
    1fc4:	02054963          	bltz	a0,1ff6 <kernmem+0x64>
    if(pid == 0){
    1fc8:	c529                	beqz	a0,2012 <kernmem+0x80>
    wait(&xstatus);
    1fca:	fbc40513          	addi	a0,s0,-68
    1fce:	00004097          	auipc	ra,0x4
    1fd2:	8c0080e7          	jalr	-1856(ra) # 588e <wait>
    if(xstatus != -1)  // did kernel kill child?
    1fd6:	fbc42783          	lw	a5,-68(s0)
    1fda:	05579d63          	bne	a5,s5,2034 <kernmem+0xa2>
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    1fde:	94ce                	add	s1,s1,s3
    1fe0:	fd249ee3          	bne	s1,s2,1fbc <kernmem+0x2a>
}
    1fe4:	60a6                	ld	ra,72(sp)
    1fe6:	6406                	ld	s0,64(sp)
    1fe8:	74e2                	ld	s1,56(sp)
    1fea:	7942                	ld	s2,48(sp)
    1fec:	79a2                	ld	s3,40(sp)
    1fee:	7a02                	ld	s4,32(sp)
    1ff0:	6ae2                	ld	s5,24(sp)
    1ff2:	6161                	addi	sp,sp,80
    1ff4:	8082                	ret
      printf("%s: fork failed\n", s);
    1ff6:	85d2                	mv	a1,s4
    1ff8:	00005517          	auipc	a0,0x5
    1ffc:	98050513          	addi	a0,a0,-1664 # 6978 <malloc+0xca4>
    2000:	00004097          	auipc	ra,0x4
    2004:	c16080e7          	jalr	-1002(ra) # 5c16 <printf>
      exit(1);
    2008:	4505                	li	a0,1
    200a:	00004097          	auipc	ra,0x4
    200e:	87c080e7          	jalr	-1924(ra) # 5886 <exit>
      printf("%s: oops could read %x = %x\n", s, a, *a);
    2012:	0004c683          	lbu	a3,0(s1)
    2016:	8626                	mv	a2,s1
    2018:	85d2                	mv	a1,s4
    201a:	00005517          	auipc	a0,0x5
    201e:	c2e50513          	addi	a0,a0,-978 # 6c48 <malloc+0xf74>
    2022:	00004097          	auipc	ra,0x4
    2026:	bf4080e7          	jalr	-1036(ra) # 5c16 <printf>
      exit(1);
    202a:	4505                	li	a0,1
    202c:	00004097          	auipc	ra,0x4
    2030:	85a080e7          	jalr	-1958(ra) # 5886 <exit>
      exit(1);
    2034:	4505                	li	a0,1
    2036:	00004097          	auipc	ra,0x4
    203a:	850080e7          	jalr	-1968(ra) # 5886 <exit>

000000000000203e <MAXVAplus>:
{
    203e:	7179                	addi	sp,sp,-48
    2040:	f406                	sd	ra,40(sp)
    2042:	f022                	sd	s0,32(sp)
    2044:	ec26                	sd	s1,24(sp)
    2046:	e84a                	sd	s2,16(sp)
    2048:	1800                	addi	s0,sp,48
  volatile uint64 a = MAXVA;
    204a:	4785                	li	a5,1
    204c:	179a                	slli	a5,a5,0x26
    204e:	fcf43c23          	sd	a5,-40(s0)
  for( ; a != 0; a <<= 1){
    2052:	fd843783          	ld	a5,-40(s0)
    2056:	cf85                	beqz	a5,208e <MAXVAplus+0x50>
    2058:	892a                	mv	s2,a0
    if(xstatus != -1)  // did kernel kill child?
    205a:	54fd                	li	s1,-1
    pid = fork();
    205c:	00004097          	auipc	ra,0x4
    2060:	822080e7          	jalr	-2014(ra) # 587e <fork>
    if(pid < 0){
    2064:	02054b63          	bltz	a0,209a <MAXVAplus+0x5c>
    if(pid == 0){
    2068:	c539                	beqz	a0,20b6 <MAXVAplus+0x78>
    wait(&xstatus);
    206a:	fd440513          	addi	a0,s0,-44
    206e:	00004097          	auipc	ra,0x4
    2072:	820080e7          	jalr	-2016(ra) # 588e <wait>
    if(xstatus != -1)  // did kernel kill child?
    2076:	fd442783          	lw	a5,-44(s0)
    207a:	06979463          	bne	a5,s1,20e2 <MAXVAplus+0xa4>
  for( ; a != 0; a <<= 1){
    207e:	fd843783          	ld	a5,-40(s0)
    2082:	0786                	slli	a5,a5,0x1
    2084:	fcf43c23          	sd	a5,-40(s0)
    2088:	fd843783          	ld	a5,-40(s0)
    208c:	fbe1                	bnez	a5,205c <MAXVAplus+0x1e>
}
    208e:	70a2                	ld	ra,40(sp)
    2090:	7402                	ld	s0,32(sp)
    2092:	64e2                	ld	s1,24(sp)
    2094:	6942                	ld	s2,16(sp)
    2096:	6145                	addi	sp,sp,48
    2098:	8082                	ret
      printf("%s: fork failed\n", s);
    209a:	85ca                	mv	a1,s2
    209c:	00005517          	auipc	a0,0x5
    20a0:	8dc50513          	addi	a0,a0,-1828 # 6978 <malloc+0xca4>
    20a4:	00004097          	auipc	ra,0x4
    20a8:	b72080e7          	jalr	-1166(ra) # 5c16 <printf>
      exit(1);
    20ac:	4505                	li	a0,1
    20ae:	00003097          	auipc	ra,0x3
    20b2:	7d8080e7          	jalr	2008(ra) # 5886 <exit>
      *(char*)a = 99;
    20b6:	fd843783          	ld	a5,-40(s0)
    20ba:	06300713          	li	a4,99
    20be:	00e78023          	sb	a4,0(a5)
      printf("%s: oops wrote %x\n", s, a);
    20c2:	fd843603          	ld	a2,-40(s0)
    20c6:	85ca                	mv	a1,s2
    20c8:	00005517          	auipc	a0,0x5
    20cc:	ba050513          	addi	a0,a0,-1120 # 6c68 <malloc+0xf94>
    20d0:	00004097          	auipc	ra,0x4
    20d4:	b46080e7          	jalr	-1210(ra) # 5c16 <printf>
      exit(1);
    20d8:	4505                	li	a0,1
    20da:	00003097          	auipc	ra,0x3
    20de:	7ac080e7          	jalr	1964(ra) # 5886 <exit>
      exit(1);
    20e2:	4505                	li	a0,1
    20e4:	00003097          	auipc	ra,0x3
    20e8:	7a2080e7          	jalr	1954(ra) # 5886 <exit>

00000000000020ec <bigargtest>:
{
    20ec:	7179                	addi	sp,sp,-48
    20ee:	f406                	sd	ra,40(sp)
    20f0:	f022                	sd	s0,32(sp)
    20f2:	ec26                	sd	s1,24(sp)
    20f4:	1800                	addi	s0,sp,48
    20f6:	84aa                	mv	s1,a0
  unlink("bigarg-ok");
    20f8:	00005517          	auipc	a0,0x5
    20fc:	b8850513          	addi	a0,a0,-1144 # 6c80 <malloc+0xfac>
    2100:	00003097          	auipc	ra,0x3
    2104:	7d6080e7          	jalr	2006(ra) # 58d6 <unlink>
  pid = fork();
    2108:	00003097          	auipc	ra,0x3
    210c:	776080e7          	jalr	1910(ra) # 587e <fork>
  if(pid == 0){
    2110:	c121                	beqz	a0,2150 <bigargtest+0x64>
  } else if(pid < 0){
    2112:	0a054063          	bltz	a0,21b2 <bigargtest+0xc6>
  wait(&xstatus);
    2116:	fdc40513          	addi	a0,s0,-36
    211a:	00003097          	auipc	ra,0x3
    211e:	774080e7          	jalr	1908(ra) # 588e <wait>
  if(xstatus != 0)
    2122:	fdc42503          	lw	a0,-36(s0)
    2126:	e545                	bnez	a0,21ce <bigargtest+0xe2>
  fd = open("bigarg-ok", 0);
    2128:	4581                	li	a1,0
    212a:	00005517          	auipc	a0,0x5
    212e:	b5650513          	addi	a0,a0,-1194 # 6c80 <malloc+0xfac>
    2132:	00003097          	auipc	ra,0x3
    2136:	794080e7          	jalr	1940(ra) # 58c6 <open>
  if(fd < 0){
    213a:	08054e63          	bltz	a0,21d6 <bigargtest+0xea>
  close(fd);
    213e:	00003097          	auipc	ra,0x3
    2142:	770080e7          	jalr	1904(ra) # 58ae <close>
}
    2146:	70a2                	ld	ra,40(sp)
    2148:	7402                	ld	s0,32(sp)
    214a:	64e2                	ld	s1,24(sp)
    214c:	6145                	addi	sp,sp,48
    214e:	8082                	ret
    2150:	00006797          	auipc	a5,0x6
    2154:	4a078793          	addi	a5,a5,1184 # 85f0 <args.1859>
    2158:	00006697          	auipc	a3,0x6
    215c:	59068693          	addi	a3,a3,1424 # 86e8 <args.1859+0xf8>
      args[i] = "bigargs test: failed\n                                                                                                                                                                                                       ";
    2160:	00005717          	auipc	a4,0x5
    2164:	b3070713          	addi	a4,a4,-1232 # 6c90 <malloc+0xfbc>
    2168:	e398                	sd	a4,0(a5)
    for(i = 0; i < MAXARG-1; i++)
    216a:	07a1                	addi	a5,a5,8
    216c:	fed79ee3          	bne	a5,a3,2168 <bigargtest+0x7c>
    args[MAXARG-1] = 0;
    2170:	00006597          	auipc	a1,0x6
    2174:	48058593          	addi	a1,a1,1152 # 85f0 <args.1859>
    2178:	0e05bc23          	sd	zero,248(a1)
    exec("echo", args);
    217c:	00004517          	auipc	a0,0x4
    2180:	fc450513          	addi	a0,a0,-60 # 6140 <malloc+0x46c>
    2184:	00003097          	auipc	ra,0x3
    2188:	73a080e7          	jalr	1850(ra) # 58be <exec>
    fd = open("bigarg-ok", O_CREATE);
    218c:	20000593          	li	a1,512
    2190:	00005517          	auipc	a0,0x5
    2194:	af050513          	addi	a0,a0,-1296 # 6c80 <malloc+0xfac>
    2198:	00003097          	auipc	ra,0x3
    219c:	72e080e7          	jalr	1838(ra) # 58c6 <open>
    close(fd);
    21a0:	00003097          	auipc	ra,0x3
    21a4:	70e080e7          	jalr	1806(ra) # 58ae <close>
    exit(0);
    21a8:	4501                	li	a0,0
    21aa:	00003097          	auipc	ra,0x3
    21ae:	6dc080e7          	jalr	1756(ra) # 5886 <exit>
    printf("%s: bigargtest: fork failed\n", s);
    21b2:	85a6                	mv	a1,s1
    21b4:	00005517          	auipc	a0,0x5
    21b8:	bbc50513          	addi	a0,a0,-1092 # 6d70 <malloc+0x109c>
    21bc:	00004097          	auipc	ra,0x4
    21c0:	a5a080e7          	jalr	-1446(ra) # 5c16 <printf>
    exit(1);
    21c4:	4505                	li	a0,1
    21c6:	00003097          	auipc	ra,0x3
    21ca:	6c0080e7          	jalr	1728(ra) # 5886 <exit>
    exit(xstatus);
    21ce:	00003097          	auipc	ra,0x3
    21d2:	6b8080e7          	jalr	1720(ra) # 5886 <exit>
    printf("%s: bigarg test failed!\n", s);
    21d6:	85a6                	mv	a1,s1
    21d8:	00005517          	auipc	a0,0x5
    21dc:	bb850513          	addi	a0,a0,-1096 # 6d90 <malloc+0x10bc>
    21e0:	00004097          	auipc	ra,0x4
    21e4:	a36080e7          	jalr	-1482(ra) # 5c16 <printf>
    exit(1);
    21e8:	4505                	li	a0,1
    21ea:	00003097          	auipc	ra,0x3
    21ee:	69c080e7          	jalr	1692(ra) # 5886 <exit>

00000000000021f2 <stacktest>:
{
    21f2:	7179                	addi	sp,sp,-48
    21f4:	f406                	sd	ra,40(sp)
    21f6:	f022                	sd	s0,32(sp)
    21f8:	ec26                	sd	s1,24(sp)
    21fa:	1800                	addi	s0,sp,48
    21fc:	84aa                	mv	s1,a0
  pid = fork();
    21fe:	00003097          	auipc	ra,0x3
    2202:	680080e7          	jalr	1664(ra) # 587e <fork>
  if(pid == 0) {
    2206:	c115                	beqz	a0,222a <stacktest+0x38>
  } else if(pid < 0){
    2208:	04054463          	bltz	a0,2250 <stacktest+0x5e>
  wait(&xstatus);
    220c:	fdc40513          	addi	a0,s0,-36
    2210:	00003097          	auipc	ra,0x3
    2214:	67e080e7          	jalr	1662(ra) # 588e <wait>
  if(xstatus == -1)  // kernel killed child?
    2218:	fdc42503          	lw	a0,-36(s0)
    221c:	57fd                	li	a5,-1
    221e:	04f50763          	beq	a0,a5,226c <stacktest+0x7a>
    exit(xstatus);
    2222:	00003097          	auipc	ra,0x3
    2226:	664080e7          	jalr	1636(ra) # 5886 <exit>

static inline uint64
r_sp()
{
  uint64 x;
  asm volatile("mv %0, sp" : "=r" (x) );
    222a:	870a                	mv	a4,sp
    printf("%s: stacktest: read below stack %p\n", s, *sp);
    222c:	77fd                	lui	a5,0xfffff
    222e:	97ba                	add	a5,a5,a4
    2230:	0007c603          	lbu	a2,0(a5) # fffffffffffff000 <__BSS_END__+0xffffffffffff01e8>
    2234:	85a6                	mv	a1,s1
    2236:	00005517          	auipc	a0,0x5
    223a:	b7a50513          	addi	a0,a0,-1158 # 6db0 <malloc+0x10dc>
    223e:	00004097          	auipc	ra,0x4
    2242:	9d8080e7          	jalr	-1576(ra) # 5c16 <printf>
    exit(1);
    2246:	4505                	li	a0,1
    2248:	00003097          	auipc	ra,0x3
    224c:	63e080e7          	jalr	1598(ra) # 5886 <exit>
    printf("%s: fork failed\n", s);
    2250:	85a6                	mv	a1,s1
    2252:	00004517          	auipc	a0,0x4
    2256:	72650513          	addi	a0,a0,1830 # 6978 <malloc+0xca4>
    225a:	00004097          	auipc	ra,0x4
    225e:	9bc080e7          	jalr	-1604(ra) # 5c16 <printf>
    exit(1);
    2262:	4505                	li	a0,1
    2264:	00003097          	auipc	ra,0x3
    2268:	622080e7          	jalr	1570(ra) # 5886 <exit>
    exit(0);
    226c:	4501                	li	a0,0
    226e:	00003097          	auipc	ra,0x3
    2272:	618080e7          	jalr	1560(ra) # 5886 <exit>

0000000000002276 <copyinstr3>:
{
    2276:	7179                	addi	sp,sp,-48
    2278:	f406                	sd	ra,40(sp)
    227a:	f022                	sd	s0,32(sp)
    227c:	ec26                	sd	s1,24(sp)
    227e:	1800                	addi	s0,sp,48
  sbrk(8192);
    2280:	6509                	lui	a0,0x2
    2282:	00003097          	auipc	ra,0x3
    2286:	68c080e7          	jalr	1676(ra) # 590e <sbrk>
  uint64 top = (uint64) sbrk(0);
    228a:	4501                	li	a0,0
    228c:	00003097          	auipc	ra,0x3
    2290:	682080e7          	jalr	1666(ra) # 590e <sbrk>
  if((top % PGSIZE) != 0){
    2294:	03451793          	slli	a5,a0,0x34
    2298:	e3c9                	bnez	a5,231a <copyinstr3+0xa4>
  top = (uint64) sbrk(0);
    229a:	4501                	li	a0,0
    229c:	00003097          	auipc	ra,0x3
    22a0:	672080e7          	jalr	1650(ra) # 590e <sbrk>
  if(top % PGSIZE){
    22a4:	03451793          	slli	a5,a0,0x34
    22a8:	e3d9                	bnez	a5,232e <copyinstr3+0xb8>
  char *b = (char *) (top - 1);
    22aa:	fff50493          	addi	s1,a0,-1 # 1fff <kernmem+0x6d>
  *b = 'x';
    22ae:	07800793          	li	a5,120
    22b2:	fef50fa3          	sb	a5,-1(a0)
  int ret = unlink(b);
    22b6:	8526                	mv	a0,s1
    22b8:	00003097          	auipc	ra,0x3
    22bc:	61e080e7          	jalr	1566(ra) # 58d6 <unlink>
  if(ret != -1){
    22c0:	57fd                	li	a5,-1
    22c2:	08f51363          	bne	a0,a5,2348 <copyinstr3+0xd2>
  int fd = open(b, O_CREATE | O_WRONLY);
    22c6:	20100593          	li	a1,513
    22ca:	8526                	mv	a0,s1
    22cc:	00003097          	auipc	ra,0x3
    22d0:	5fa080e7          	jalr	1530(ra) # 58c6 <open>
  if(fd != -1){
    22d4:	57fd                	li	a5,-1
    22d6:	08f51863          	bne	a0,a5,2366 <copyinstr3+0xf0>
  ret = link(b, b);
    22da:	85a6                	mv	a1,s1
    22dc:	8526                	mv	a0,s1
    22de:	00003097          	auipc	ra,0x3
    22e2:	608080e7          	jalr	1544(ra) # 58e6 <link>
  if(ret != -1){
    22e6:	57fd                	li	a5,-1
    22e8:	08f51e63          	bne	a0,a5,2384 <copyinstr3+0x10e>
  char *args[] = { "xx", 0 };
    22ec:	00005797          	auipc	a5,0x5
    22f0:	75c78793          	addi	a5,a5,1884 # 7a48 <malloc+0x1d74>
    22f4:	fcf43823          	sd	a5,-48(s0)
    22f8:	fc043c23          	sd	zero,-40(s0)
  ret = exec(b, args);
    22fc:	fd040593          	addi	a1,s0,-48
    2300:	8526                	mv	a0,s1
    2302:	00003097          	auipc	ra,0x3
    2306:	5bc080e7          	jalr	1468(ra) # 58be <exec>
  if(ret != -1){
    230a:	57fd                	li	a5,-1
    230c:	08f51c63          	bne	a0,a5,23a4 <copyinstr3+0x12e>
}
    2310:	70a2                	ld	ra,40(sp)
    2312:	7402                	ld	s0,32(sp)
    2314:	64e2                	ld	s1,24(sp)
    2316:	6145                	addi	sp,sp,48
    2318:	8082                	ret
    sbrk(PGSIZE - (top % PGSIZE));
    231a:	0347d513          	srli	a0,a5,0x34
    231e:	6785                	lui	a5,0x1
    2320:	40a7853b          	subw	a0,a5,a0
    2324:	00003097          	auipc	ra,0x3
    2328:	5ea080e7          	jalr	1514(ra) # 590e <sbrk>
    232c:	b7bd                	j	229a <copyinstr3+0x24>
    printf("oops\n");
    232e:	00005517          	auipc	a0,0x5
    2332:	aaa50513          	addi	a0,a0,-1366 # 6dd8 <malloc+0x1104>
    2336:	00004097          	auipc	ra,0x4
    233a:	8e0080e7          	jalr	-1824(ra) # 5c16 <printf>
    exit(1);
    233e:	4505                	li	a0,1
    2340:	00003097          	auipc	ra,0x3
    2344:	546080e7          	jalr	1350(ra) # 5886 <exit>
    printf("unlink(%s) returned %d, not -1\n", b, ret);
    2348:	862a                	mv	a2,a0
    234a:	85a6                	mv	a1,s1
    234c:	00004517          	auipc	a0,0x4
    2350:	54c50513          	addi	a0,a0,1356 # 6898 <malloc+0xbc4>
    2354:	00004097          	auipc	ra,0x4
    2358:	8c2080e7          	jalr	-1854(ra) # 5c16 <printf>
    exit(1);
    235c:	4505                	li	a0,1
    235e:	00003097          	auipc	ra,0x3
    2362:	528080e7          	jalr	1320(ra) # 5886 <exit>
    printf("open(%s) returned %d, not -1\n", b, fd);
    2366:	862a                	mv	a2,a0
    2368:	85a6                	mv	a1,s1
    236a:	00004517          	auipc	a0,0x4
    236e:	54e50513          	addi	a0,a0,1358 # 68b8 <malloc+0xbe4>
    2372:	00004097          	auipc	ra,0x4
    2376:	8a4080e7          	jalr	-1884(ra) # 5c16 <printf>
    exit(1);
    237a:	4505                	li	a0,1
    237c:	00003097          	auipc	ra,0x3
    2380:	50a080e7          	jalr	1290(ra) # 5886 <exit>
    printf("link(%s, %s) returned %d, not -1\n", b, b, ret);
    2384:	86aa                	mv	a3,a0
    2386:	8626                	mv	a2,s1
    2388:	85a6                	mv	a1,s1
    238a:	00004517          	auipc	a0,0x4
    238e:	54e50513          	addi	a0,a0,1358 # 68d8 <malloc+0xc04>
    2392:	00004097          	auipc	ra,0x4
    2396:	884080e7          	jalr	-1916(ra) # 5c16 <printf>
    exit(1);
    239a:	4505                	li	a0,1
    239c:	00003097          	auipc	ra,0x3
    23a0:	4ea080e7          	jalr	1258(ra) # 5886 <exit>
    printf("exec(%s) returned %d, not -1\n", b, fd);
    23a4:	567d                	li	a2,-1
    23a6:	85a6                	mv	a1,s1
    23a8:	00004517          	auipc	a0,0x4
    23ac:	55850513          	addi	a0,a0,1368 # 6900 <malloc+0xc2c>
    23b0:	00004097          	auipc	ra,0x4
    23b4:	866080e7          	jalr	-1946(ra) # 5c16 <printf>
    exit(1);
    23b8:	4505                	li	a0,1
    23ba:	00003097          	auipc	ra,0x3
    23be:	4cc080e7          	jalr	1228(ra) # 5886 <exit>

00000000000023c2 <rwsbrk>:
{
    23c2:	1101                	addi	sp,sp,-32
    23c4:	ec06                	sd	ra,24(sp)
    23c6:	e822                	sd	s0,16(sp)
    23c8:	e426                	sd	s1,8(sp)
    23ca:	e04a                	sd	s2,0(sp)
    23cc:	1000                	addi	s0,sp,32
  uint64 a = (uint64) sbrk(8192);
    23ce:	6509                	lui	a0,0x2
    23d0:	00003097          	auipc	ra,0x3
    23d4:	53e080e7          	jalr	1342(ra) # 590e <sbrk>
  if(a == 0xffffffffffffffffLL) {
    23d8:	57fd                	li	a5,-1
    23da:	06f50363          	beq	a0,a5,2440 <rwsbrk+0x7e>
    23de:	84aa                	mv	s1,a0
  if ((uint64) sbrk(-8192) ==  0xffffffffffffffffLL) {
    23e0:	7579                	lui	a0,0xffffe
    23e2:	00003097          	auipc	ra,0x3
    23e6:	52c080e7          	jalr	1324(ra) # 590e <sbrk>
    23ea:	57fd                	li	a5,-1
    23ec:	06f50763          	beq	a0,a5,245a <rwsbrk+0x98>
  fd = open("rwsbrk", O_CREATE|O_WRONLY);
    23f0:	20100593          	li	a1,513
    23f4:	00004517          	auipc	a0,0x4
    23f8:	a3c50513          	addi	a0,a0,-1476 # 5e30 <malloc+0x15c>
    23fc:	00003097          	auipc	ra,0x3
    2400:	4ca080e7          	jalr	1226(ra) # 58c6 <open>
    2404:	892a                	mv	s2,a0
  if(fd < 0){
    2406:	06054763          	bltz	a0,2474 <rwsbrk+0xb2>
  n = write(fd, (void*)(a+4096), 1024);
    240a:	6505                	lui	a0,0x1
    240c:	94aa                	add	s1,s1,a0
    240e:	40000613          	li	a2,1024
    2412:	85a6                	mv	a1,s1
    2414:	854a                	mv	a0,s2
    2416:	00003097          	auipc	ra,0x3
    241a:	490080e7          	jalr	1168(ra) # 58a6 <write>
    241e:	862a                	mv	a2,a0
  if(n >= 0){
    2420:	06054763          	bltz	a0,248e <rwsbrk+0xcc>
    printf("write(fd, %p, 1024) returned %d, not -1\n", a+4096, n);
    2424:	85a6                	mv	a1,s1
    2426:	00005517          	auipc	a0,0x5
    242a:	a0a50513          	addi	a0,a0,-1526 # 6e30 <malloc+0x115c>
    242e:	00003097          	auipc	ra,0x3
    2432:	7e8080e7          	jalr	2024(ra) # 5c16 <printf>
    exit(1);
    2436:	4505                	li	a0,1
    2438:	00003097          	auipc	ra,0x3
    243c:	44e080e7          	jalr	1102(ra) # 5886 <exit>
    printf("sbrk(rwsbrk) failed\n");
    2440:	00005517          	auipc	a0,0x5
    2444:	9a050513          	addi	a0,a0,-1632 # 6de0 <malloc+0x110c>
    2448:	00003097          	auipc	ra,0x3
    244c:	7ce080e7          	jalr	1998(ra) # 5c16 <printf>
    exit(1);
    2450:	4505                	li	a0,1
    2452:	00003097          	auipc	ra,0x3
    2456:	434080e7          	jalr	1076(ra) # 5886 <exit>
    printf("sbrk(rwsbrk) shrink failed\n");
    245a:	00005517          	auipc	a0,0x5
    245e:	99e50513          	addi	a0,a0,-1634 # 6df8 <malloc+0x1124>
    2462:	00003097          	auipc	ra,0x3
    2466:	7b4080e7          	jalr	1972(ra) # 5c16 <printf>
    exit(1);
    246a:	4505                	li	a0,1
    246c:	00003097          	auipc	ra,0x3
    2470:	41a080e7          	jalr	1050(ra) # 5886 <exit>
    printf("open(rwsbrk) failed\n");
    2474:	00005517          	auipc	a0,0x5
    2478:	9a450513          	addi	a0,a0,-1628 # 6e18 <malloc+0x1144>
    247c:	00003097          	auipc	ra,0x3
    2480:	79a080e7          	jalr	1946(ra) # 5c16 <printf>
    exit(1);
    2484:	4505                	li	a0,1
    2486:	00003097          	auipc	ra,0x3
    248a:	400080e7          	jalr	1024(ra) # 5886 <exit>
  close(fd);
    248e:	854a                	mv	a0,s2
    2490:	00003097          	auipc	ra,0x3
    2494:	41e080e7          	jalr	1054(ra) # 58ae <close>
  unlink("rwsbrk");
    2498:	00004517          	auipc	a0,0x4
    249c:	99850513          	addi	a0,a0,-1640 # 5e30 <malloc+0x15c>
    24a0:	00003097          	auipc	ra,0x3
    24a4:	436080e7          	jalr	1078(ra) # 58d6 <unlink>
  fd = open("README", O_RDONLY);
    24a8:	4581                	li	a1,0
    24aa:	00004517          	auipc	a0,0x4
    24ae:	e2e50513          	addi	a0,a0,-466 # 62d8 <malloc+0x604>
    24b2:	00003097          	auipc	ra,0x3
    24b6:	414080e7          	jalr	1044(ra) # 58c6 <open>
    24ba:	892a                	mv	s2,a0
  if(fd < 0){
    24bc:	02054963          	bltz	a0,24ee <rwsbrk+0x12c>
  n = read(fd, (void*)(a+4096), 10);
    24c0:	4629                	li	a2,10
    24c2:	85a6                	mv	a1,s1
    24c4:	00003097          	auipc	ra,0x3
    24c8:	3da080e7          	jalr	986(ra) # 589e <read>
    24cc:	862a                	mv	a2,a0
  if(n >= 0){
    24ce:	02054d63          	bltz	a0,2508 <rwsbrk+0x146>
    printf("read(fd, %p, 10) returned %d, not -1\n", a+4096, n);
    24d2:	85a6                	mv	a1,s1
    24d4:	00005517          	auipc	a0,0x5
    24d8:	98c50513          	addi	a0,a0,-1652 # 6e60 <malloc+0x118c>
    24dc:	00003097          	auipc	ra,0x3
    24e0:	73a080e7          	jalr	1850(ra) # 5c16 <printf>
    exit(1);
    24e4:	4505                	li	a0,1
    24e6:	00003097          	auipc	ra,0x3
    24ea:	3a0080e7          	jalr	928(ra) # 5886 <exit>
    printf("open(rwsbrk) failed\n");
    24ee:	00005517          	auipc	a0,0x5
    24f2:	92a50513          	addi	a0,a0,-1750 # 6e18 <malloc+0x1144>
    24f6:	00003097          	auipc	ra,0x3
    24fa:	720080e7          	jalr	1824(ra) # 5c16 <printf>
    exit(1);
    24fe:	4505                	li	a0,1
    2500:	00003097          	auipc	ra,0x3
    2504:	386080e7          	jalr	902(ra) # 5886 <exit>
  close(fd);
    2508:	854a                	mv	a0,s2
    250a:	00003097          	auipc	ra,0x3
    250e:	3a4080e7          	jalr	932(ra) # 58ae <close>
  exit(0);
    2512:	4501                	li	a0,0
    2514:	00003097          	auipc	ra,0x3
    2518:	372080e7          	jalr	882(ra) # 5886 <exit>

000000000000251c <sbrkbasic>:
{
    251c:	715d                	addi	sp,sp,-80
    251e:	e486                	sd	ra,72(sp)
    2520:	e0a2                	sd	s0,64(sp)
    2522:	fc26                	sd	s1,56(sp)
    2524:	f84a                	sd	s2,48(sp)
    2526:	f44e                	sd	s3,40(sp)
    2528:	f052                	sd	s4,32(sp)
    252a:	ec56                	sd	s5,24(sp)
    252c:	0880                	addi	s0,sp,80
    252e:	8a2a                	mv	s4,a0
  pid = fork();
    2530:	00003097          	auipc	ra,0x3
    2534:	34e080e7          	jalr	846(ra) # 587e <fork>
  if(pid < 0){
    2538:	02054c63          	bltz	a0,2570 <sbrkbasic+0x54>
  if(pid == 0){
    253c:	ed21                	bnez	a0,2594 <sbrkbasic+0x78>
    a = sbrk(TOOMUCH);
    253e:	40000537          	lui	a0,0x40000
    2542:	00003097          	auipc	ra,0x3
    2546:	3cc080e7          	jalr	972(ra) # 590e <sbrk>
    if(a == (char*)0xffffffffffffffffL){
    254a:	57fd                	li	a5,-1
    254c:	02f50f63          	beq	a0,a5,258a <sbrkbasic+0x6e>
    for(b = a; b < a+TOOMUCH; b += 4096){
    2550:	400007b7          	lui	a5,0x40000
    2554:	97aa                	add	a5,a5,a0
      *b = 99;
    2556:	06300693          	li	a3,99
    for(b = a; b < a+TOOMUCH; b += 4096){
    255a:	6705                	lui	a4,0x1
      *b = 99;
    255c:	00d50023          	sb	a3,0(a0) # 40000000 <__BSS_END__+0x3fff11e8>
    for(b = a; b < a+TOOMUCH; b += 4096){
    2560:	953a                	add	a0,a0,a4
    2562:	fef51de3          	bne	a0,a5,255c <sbrkbasic+0x40>
    exit(1);
    2566:	4505                	li	a0,1
    2568:	00003097          	auipc	ra,0x3
    256c:	31e080e7          	jalr	798(ra) # 5886 <exit>
    printf("fork failed in sbrkbasic\n");
    2570:	00005517          	auipc	a0,0x5
    2574:	91850513          	addi	a0,a0,-1768 # 6e88 <malloc+0x11b4>
    2578:	00003097          	auipc	ra,0x3
    257c:	69e080e7          	jalr	1694(ra) # 5c16 <printf>
    exit(1);
    2580:	4505                	li	a0,1
    2582:	00003097          	auipc	ra,0x3
    2586:	304080e7          	jalr	772(ra) # 5886 <exit>
      exit(0);
    258a:	4501                	li	a0,0
    258c:	00003097          	auipc	ra,0x3
    2590:	2fa080e7          	jalr	762(ra) # 5886 <exit>
  wait(&xstatus);
    2594:	fbc40513          	addi	a0,s0,-68
    2598:	00003097          	auipc	ra,0x3
    259c:	2f6080e7          	jalr	758(ra) # 588e <wait>
  if(xstatus == 1){
    25a0:	fbc42703          	lw	a4,-68(s0)
    25a4:	4785                	li	a5,1
    25a6:	00f70e63          	beq	a4,a5,25c2 <sbrkbasic+0xa6>
  a = sbrk(0);
    25aa:	4501                	li	a0,0
    25ac:	00003097          	auipc	ra,0x3
    25b0:	362080e7          	jalr	866(ra) # 590e <sbrk>
    25b4:	84aa                	mv	s1,a0
  for(i = 0; i < 5000; i++){
    25b6:	4901                	li	s2,0
    *b = 1;
    25b8:	4a85                	li	s5,1
  for(i = 0; i < 5000; i++){
    25ba:	6985                	lui	s3,0x1
    25bc:	38898993          	addi	s3,s3,904 # 1388 <copyinstr2+0x1d6>
    25c0:	a005                	j	25e0 <sbrkbasic+0xc4>
    printf("%s: too much memory allocated!\n", s);
    25c2:	85d2                	mv	a1,s4
    25c4:	00005517          	auipc	a0,0x5
    25c8:	8e450513          	addi	a0,a0,-1820 # 6ea8 <malloc+0x11d4>
    25cc:	00003097          	auipc	ra,0x3
    25d0:	64a080e7          	jalr	1610(ra) # 5c16 <printf>
    exit(1);
    25d4:	4505                	li	a0,1
    25d6:	00003097          	auipc	ra,0x3
    25da:	2b0080e7          	jalr	688(ra) # 5886 <exit>
    a = b + 1;
    25de:	84be                	mv	s1,a5
    b = sbrk(1);
    25e0:	4505                	li	a0,1
    25e2:	00003097          	auipc	ra,0x3
    25e6:	32c080e7          	jalr	812(ra) # 590e <sbrk>
    if(b != a){
    25ea:	04951b63          	bne	a0,s1,2640 <sbrkbasic+0x124>
    *b = 1;
    25ee:	01548023          	sb	s5,0(s1)
    a = b + 1;
    25f2:	00148793          	addi	a5,s1,1
  for(i = 0; i < 5000; i++){
    25f6:	2905                	addiw	s2,s2,1
    25f8:	ff3913e3          	bne	s2,s3,25de <sbrkbasic+0xc2>
  pid = fork();
    25fc:	00003097          	auipc	ra,0x3
    2600:	282080e7          	jalr	642(ra) # 587e <fork>
    2604:	892a                	mv	s2,a0
  if(pid < 0){
    2606:	04054e63          	bltz	a0,2662 <sbrkbasic+0x146>
  c = sbrk(1);
    260a:	4505                	li	a0,1
    260c:	00003097          	auipc	ra,0x3
    2610:	302080e7          	jalr	770(ra) # 590e <sbrk>
  c = sbrk(1);
    2614:	4505                	li	a0,1
    2616:	00003097          	auipc	ra,0x3
    261a:	2f8080e7          	jalr	760(ra) # 590e <sbrk>
  if(c != a + 1){
    261e:	0489                	addi	s1,s1,2
    2620:	04a48f63          	beq	s1,a0,267e <sbrkbasic+0x162>
    printf("%s: sbrk test failed post-fork\n", s);
    2624:	85d2                	mv	a1,s4
    2626:	00005517          	auipc	a0,0x5
    262a:	8e250513          	addi	a0,a0,-1822 # 6f08 <malloc+0x1234>
    262e:	00003097          	auipc	ra,0x3
    2632:	5e8080e7          	jalr	1512(ra) # 5c16 <printf>
    exit(1);
    2636:	4505                	li	a0,1
    2638:	00003097          	auipc	ra,0x3
    263c:	24e080e7          	jalr	590(ra) # 5886 <exit>
      printf("%s: sbrk test failed %d %x %x\n", s, i, a, b);
    2640:	872a                	mv	a4,a0
    2642:	86a6                	mv	a3,s1
    2644:	864a                	mv	a2,s2
    2646:	85d2                	mv	a1,s4
    2648:	00005517          	auipc	a0,0x5
    264c:	88050513          	addi	a0,a0,-1920 # 6ec8 <malloc+0x11f4>
    2650:	00003097          	auipc	ra,0x3
    2654:	5c6080e7          	jalr	1478(ra) # 5c16 <printf>
      exit(1);
    2658:	4505                	li	a0,1
    265a:	00003097          	auipc	ra,0x3
    265e:	22c080e7          	jalr	556(ra) # 5886 <exit>
    printf("%s: sbrk test fork failed\n", s);
    2662:	85d2                	mv	a1,s4
    2664:	00005517          	auipc	a0,0x5
    2668:	88450513          	addi	a0,a0,-1916 # 6ee8 <malloc+0x1214>
    266c:	00003097          	auipc	ra,0x3
    2670:	5aa080e7          	jalr	1450(ra) # 5c16 <printf>
    exit(1);
    2674:	4505                	li	a0,1
    2676:	00003097          	auipc	ra,0x3
    267a:	210080e7          	jalr	528(ra) # 5886 <exit>
  if(pid == 0)
    267e:	00091763          	bnez	s2,268c <sbrkbasic+0x170>
    exit(0);
    2682:	4501                	li	a0,0
    2684:	00003097          	auipc	ra,0x3
    2688:	202080e7          	jalr	514(ra) # 5886 <exit>
  wait(&xstatus);
    268c:	fbc40513          	addi	a0,s0,-68
    2690:	00003097          	auipc	ra,0x3
    2694:	1fe080e7          	jalr	510(ra) # 588e <wait>
  exit(xstatus);
    2698:	fbc42503          	lw	a0,-68(s0)
    269c:	00003097          	auipc	ra,0x3
    26a0:	1ea080e7          	jalr	490(ra) # 5886 <exit>

00000000000026a4 <sbrkmuch>:
{
    26a4:	7179                	addi	sp,sp,-48
    26a6:	f406                	sd	ra,40(sp)
    26a8:	f022                	sd	s0,32(sp)
    26aa:	ec26                	sd	s1,24(sp)
    26ac:	e84a                	sd	s2,16(sp)
    26ae:	e44e                	sd	s3,8(sp)
    26b0:	e052                	sd	s4,0(sp)
    26b2:	1800                	addi	s0,sp,48
    26b4:	89aa                	mv	s3,a0
  oldbrk = sbrk(0);
    26b6:	4501                	li	a0,0
    26b8:	00003097          	auipc	ra,0x3
    26bc:	256080e7          	jalr	598(ra) # 590e <sbrk>
    26c0:	892a                	mv	s2,a0
  a = sbrk(0);
    26c2:	4501                	li	a0,0
    26c4:	00003097          	auipc	ra,0x3
    26c8:	24a080e7          	jalr	586(ra) # 590e <sbrk>
    26cc:	84aa                	mv	s1,a0
  p = sbrk(amt);
    26ce:	06400537          	lui	a0,0x6400
    26d2:	9d05                	subw	a0,a0,s1
    26d4:	00003097          	auipc	ra,0x3
    26d8:	23a080e7          	jalr	570(ra) # 590e <sbrk>
  if (p != a) {
    26dc:	0ca49863          	bne	s1,a0,27ac <sbrkmuch+0x108>
  char *eee = sbrk(0);
    26e0:	4501                	li	a0,0
    26e2:	00003097          	auipc	ra,0x3
    26e6:	22c080e7          	jalr	556(ra) # 590e <sbrk>
    26ea:	87aa                	mv	a5,a0
  for(char *pp = a; pp < eee; pp += 4096)
    26ec:	00a4f963          	bgeu	s1,a0,26fe <sbrkmuch+0x5a>
    *pp = 1;
    26f0:	4685                	li	a3,1
  for(char *pp = a; pp < eee; pp += 4096)
    26f2:	6705                	lui	a4,0x1
    *pp = 1;
    26f4:	00d48023          	sb	a3,0(s1)
  for(char *pp = a; pp < eee; pp += 4096)
    26f8:	94ba                	add	s1,s1,a4
    26fa:	fef4ede3          	bltu	s1,a5,26f4 <sbrkmuch+0x50>
  *lastaddr = 99;
    26fe:	064007b7          	lui	a5,0x6400
    2702:	06300713          	li	a4,99
    2706:	fee78fa3          	sb	a4,-1(a5) # 63fffff <__BSS_END__+0x63f11e7>
  a = sbrk(0);
    270a:	4501                	li	a0,0
    270c:	00003097          	auipc	ra,0x3
    2710:	202080e7          	jalr	514(ra) # 590e <sbrk>
    2714:	84aa                	mv	s1,a0
  c = sbrk(-PGSIZE);
    2716:	757d                	lui	a0,0xfffff
    2718:	00003097          	auipc	ra,0x3
    271c:	1f6080e7          	jalr	502(ra) # 590e <sbrk>
  if(c == (char*)0xffffffffffffffffL){
    2720:	57fd                	li	a5,-1
    2722:	0af50363          	beq	a0,a5,27c8 <sbrkmuch+0x124>
  c = sbrk(0);
    2726:	4501                	li	a0,0
    2728:	00003097          	auipc	ra,0x3
    272c:	1e6080e7          	jalr	486(ra) # 590e <sbrk>
  if(c != a - PGSIZE){
    2730:	77fd                	lui	a5,0xfffff
    2732:	97a6                	add	a5,a5,s1
    2734:	0af51863          	bne	a0,a5,27e4 <sbrkmuch+0x140>
  a = sbrk(0);
    2738:	4501                	li	a0,0
    273a:	00003097          	auipc	ra,0x3
    273e:	1d4080e7          	jalr	468(ra) # 590e <sbrk>
    2742:	84aa                	mv	s1,a0
  c = sbrk(PGSIZE);
    2744:	6505                	lui	a0,0x1
    2746:	00003097          	auipc	ra,0x3
    274a:	1c8080e7          	jalr	456(ra) # 590e <sbrk>
    274e:	8a2a                	mv	s4,a0
  if(c != a || sbrk(0) != a + PGSIZE){
    2750:	0aa49a63          	bne	s1,a0,2804 <sbrkmuch+0x160>
    2754:	4501                	li	a0,0
    2756:	00003097          	auipc	ra,0x3
    275a:	1b8080e7          	jalr	440(ra) # 590e <sbrk>
    275e:	6785                	lui	a5,0x1
    2760:	97a6                	add	a5,a5,s1
    2762:	0af51163          	bne	a0,a5,2804 <sbrkmuch+0x160>
  if(*lastaddr == 99){
    2766:	064007b7          	lui	a5,0x6400
    276a:	fff7c703          	lbu	a4,-1(a5) # 63fffff <__BSS_END__+0x63f11e7>
    276e:	06300793          	li	a5,99
    2772:	0af70963          	beq	a4,a5,2824 <sbrkmuch+0x180>
  a = sbrk(0);
    2776:	4501                	li	a0,0
    2778:	00003097          	auipc	ra,0x3
    277c:	196080e7          	jalr	406(ra) # 590e <sbrk>
    2780:	84aa                	mv	s1,a0
  c = sbrk(-(sbrk(0) - oldbrk));
    2782:	4501                	li	a0,0
    2784:	00003097          	auipc	ra,0x3
    2788:	18a080e7          	jalr	394(ra) # 590e <sbrk>
    278c:	40a9053b          	subw	a0,s2,a0
    2790:	00003097          	auipc	ra,0x3
    2794:	17e080e7          	jalr	382(ra) # 590e <sbrk>
  if(c != a){
    2798:	0aa49463          	bne	s1,a0,2840 <sbrkmuch+0x19c>
}
    279c:	70a2                	ld	ra,40(sp)
    279e:	7402                	ld	s0,32(sp)
    27a0:	64e2                	ld	s1,24(sp)
    27a2:	6942                	ld	s2,16(sp)
    27a4:	69a2                	ld	s3,8(sp)
    27a6:	6a02                	ld	s4,0(sp)
    27a8:	6145                	addi	sp,sp,48
    27aa:	8082                	ret
    printf("%s: sbrk test failed to grow big address space; enough phys mem?\n", s);
    27ac:	85ce                	mv	a1,s3
    27ae:	00004517          	auipc	a0,0x4
    27b2:	77a50513          	addi	a0,a0,1914 # 6f28 <malloc+0x1254>
    27b6:	00003097          	auipc	ra,0x3
    27ba:	460080e7          	jalr	1120(ra) # 5c16 <printf>
    exit(1);
    27be:	4505                	li	a0,1
    27c0:	00003097          	auipc	ra,0x3
    27c4:	0c6080e7          	jalr	198(ra) # 5886 <exit>
    printf("%s: sbrk could not deallocate\n", s);
    27c8:	85ce                	mv	a1,s3
    27ca:	00004517          	auipc	a0,0x4
    27ce:	7a650513          	addi	a0,a0,1958 # 6f70 <malloc+0x129c>
    27d2:	00003097          	auipc	ra,0x3
    27d6:	444080e7          	jalr	1092(ra) # 5c16 <printf>
    exit(1);
    27da:	4505                	li	a0,1
    27dc:	00003097          	auipc	ra,0x3
    27e0:	0aa080e7          	jalr	170(ra) # 5886 <exit>
    printf("%s: sbrk deallocation produced wrong address, a %x c %x\n", s, a, c);
    27e4:	86aa                	mv	a3,a0
    27e6:	8626                	mv	a2,s1
    27e8:	85ce                	mv	a1,s3
    27ea:	00004517          	auipc	a0,0x4
    27ee:	7a650513          	addi	a0,a0,1958 # 6f90 <malloc+0x12bc>
    27f2:	00003097          	auipc	ra,0x3
    27f6:	424080e7          	jalr	1060(ra) # 5c16 <printf>
    exit(1);
    27fa:	4505                	li	a0,1
    27fc:	00003097          	auipc	ra,0x3
    2800:	08a080e7          	jalr	138(ra) # 5886 <exit>
    printf("%s: sbrk re-allocation failed, a %x c %x\n", s, a, c);
    2804:	86d2                	mv	a3,s4
    2806:	8626                	mv	a2,s1
    2808:	85ce                	mv	a1,s3
    280a:	00004517          	auipc	a0,0x4
    280e:	7c650513          	addi	a0,a0,1990 # 6fd0 <malloc+0x12fc>
    2812:	00003097          	auipc	ra,0x3
    2816:	404080e7          	jalr	1028(ra) # 5c16 <printf>
    exit(1);
    281a:	4505                	li	a0,1
    281c:	00003097          	auipc	ra,0x3
    2820:	06a080e7          	jalr	106(ra) # 5886 <exit>
    printf("%s: sbrk de-allocation didn't really deallocate\n", s);
    2824:	85ce                	mv	a1,s3
    2826:	00004517          	auipc	a0,0x4
    282a:	7da50513          	addi	a0,a0,2010 # 7000 <malloc+0x132c>
    282e:	00003097          	auipc	ra,0x3
    2832:	3e8080e7          	jalr	1000(ra) # 5c16 <printf>
    exit(1);
    2836:	4505                	li	a0,1
    2838:	00003097          	auipc	ra,0x3
    283c:	04e080e7          	jalr	78(ra) # 5886 <exit>
    printf("%s: sbrk downsize failed, a %x c %x\n", s, a, c);
    2840:	86aa                	mv	a3,a0
    2842:	8626                	mv	a2,s1
    2844:	85ce                	mv	a1,s3
    2846:	00004517          	auipc	a0,0x4
    284a:	7f250513          	addi	a0,a0,2034 # 7038 <malloc+0x1364>
    284e:	00003097          	auipc	ra,0x3
    2852:	3c8080e7          	jalr	968(ra) # 5c16 <printf>
    exit(1);
    2856:	4505                	li	a0,1
    2858:	00003097          	auipc	ra,0x3
    285c:	02e080e7          	jalr	46(ra) # 5886 <exit>

0000000000002860 <sbrkarg>:
{
    2860:	7179                	addi	sp,sp,-48
    2862:	f406                	sd	ra,40(sp)
    2864:	f022                	sd	s0,32(sp)
    2866:	ec26                	sd	s1,24(sp)
    2868:	e84a                	sd	s2,16(sp)
    286a:	e44e                	sd	s3,8(sp)
    286c:	1800                	addi	s0,sp,48
    286e:	89aa                	mv	s3,a0
  a = sbrk(PGSIZE);
    2870:	6505                	lui	a0,0x1
    2872:	00003097          	auipc	ra,0x3
    2876:	09c080e7          	jalr	156(ra) # 590e <sbrk>
    287a:	892a                	mv	s2,a0
  fd = open("sbrk", O_CREATE|O_WRONLY);
    287c:	20100593          	li	a1,513
    2880:	00004517          	auipc	a0,0x4
    2884:	7e050513          	addi	a0,a0,2016 # 7060 <malloc+0x138c>
    2888:	00003097          	auipc	ra,0x3
    288c:	03e080e7          	jalr	62(ra) # 58c6 <open>
    2890:	84aa                	mv	s1,a0
  unlink("sbrk");
    2892:	00004517          	auipc	a0,0x4
    2896:	7ce50513          	addi	a0,a0,1998 # 7060 <malloc+0x138c>
    289a:	00003097          	auipc	ra,0x3
    289e:	03c080e7          	jalr	60(ra) # 58d6 <unlink>
  if(fd < 0)  {
    28a2:	0404c163          	bltz	s1,28e4 <sbrkarg+0x84>
  if ((n = write(fd, a, PGSIZE)) < 0) {
    28a6:	6605                	lui	a2,0x1
    28a8:	85ca                	mv	a1,s2
    28aa:	8526                	mv	a0,s1
    28ac:	00003097          	auipc	ra,0x3
    28b0:	ffa080e7          	jalr	-6(ra) # 58a6 <write>
    28b4:	04054663          	bltz	a0,2900 <sbrkarg+0xa0>
  close(fd);
    28b8:	8526                	mv	a0,s1
    28ba:	00003097          	auipc	ra,0x3
    28be:	ff4080e7          	jalr	-12(ra) # 58ae <close>
  a = sbrk(PGSIZE);
    28c2:	6505                	lui	a0,0x1
    28c4:	00003097          	auipc	ra,0x3
    28c8:	04a080e7          	jalr	74(ra) # 590e <sbrk>
  if(pipe((int *) a) != 0){
    28cc:	00003097          	auipc	ra,0x3
    28d0:	fca080e7          	jalr	-54(ra) # 5896 <pipe>
    28d4:	e521                	bnez	a0,291c <sbrkarg+0xbc>
}
    28d6:	70a2                	ld	ra,40(sp)
    28d8:	7402                	ld	s0,32(sp)
    28da:	64e2                	ld	s1,24(sp)
    28dc:	6942                	ld	s2,16(sp)
    28de:	69a2                	ld	s3,8(sp)
    28e0:	6145                	addi	sp,sp,48
    28e2:	8082                	ret
    printf("%s: open sbrk failed\n", s);
    28e4:	85ce                	mv	a1,s3
    28e6:	00004517          	auipc	a0,0x4
    28ea:	78250513          	addi	a0,a0,1922 # 7068 <malloc+0x1394>
    28ee:	00003097          	auipc	ra,0x3
    28f2:	328080e7          	jalr	808(ra) # 5c16 <printf>
    exit(1);
    28f6:	4505                	li	a0,1
    28f8:	00003097          	auipc	ra,0x3
    28fc:	f8e080e7          	jalr	-114(ra) # 5886 <exit>
    printf("%s: write sbrk failed\n", s);
    2900:	85ce                	mv	a1,s3
    2902:	00004517          	auipc	a0,0x4
    2906:	77e50513          	addi	a0,a0,1918 # 7080 <malloc+0x13ac>
    290a:	00003097          	auipc	ra,0x3
    290e:	30c080e7          	jalr	780(ra) # 5c16 <printf>
    exit(1);
    2912:	4505                	li	a0,1
    2914:	00003097          	auipc	ra,0x3
    2918:	f72080e7          	jalr	-142(ra) # 5886 <exit>
    printf("%s: pipe() failed\n", s);
    291c:	85ce                	mv	a1,s3
    291e:	00004517          	auipc	a0,0x4
    2922:	16250513          	addi	a0,a0,354 # 6a80 <malloc+0xdac>
    2926:	00003097          	auipc	ra,0x3
    292a:	2f0080e7          	jalr	752(ra) # 5c16 <printf>
    exit(1);
    292e:	4505                	li	a0,1
    2930:	00003097          	auipc	ra,0x3
    2934:	f56080e7          	jalr	-170(ra) # 5886 <exit>

0000000000002938 <argptest>:
{
    2938:	1101                	addi	sp,sp,-32
    293a:	ec06                	sd	ra,24(sp)
    293c:	e822                	sd	s0,16(sp)
    293e:	e426                	sd	s1,8(sp)
    2940:	e04a                	sd	s2,0(sp)
    2942:	1000                	addi	s0,sp,32
    2944:	892a                	mv	s2,a0
  fd = open("init", O_RDONLY);
    2946:	4581                	li	a1,0
    2948:	00004517          	auipc	a0,0x4
    294c:	75050513          	addi	a0,a0,1872 # 7098 <malloc+0x13c4>
    2950:	00003097          	auipc	ra,0x3
    2954:	f76080e7          	jalr	-138(ra) # 58c6 <open>
  if (fd < 0) {
    2958:	02054b63          	bltz	a0,298e <argptest+0x56>
    295c:	84aa                	mv	s1,a0
  read(fd, sbrk(0) - 1, -1);
    295e:	4501                	li	a0,0
    2960:	00003097          	auipc	ra,0x3
    2964:	fae080e7          	jalr	-82(ra) # 590e <sbrk>
    2968:	567d                	li	a2,-1
    296a:	fff50593          	addi	a1,a0,-1
    296e:	8526                	mv	a0,s1
    2970:	00003097          	auipc	ra,0x3
    2974:	f2e080e7          	jalr	-210(ra) # 589e <read>
  close(fd);
    2978:	8526                	mv	a0,s1
    297a:	00003097          	auipc	ra,0x3
    297e:	f34080e7          	jalr	-204(ra) # 58ae <close>
}
    2982:	60e2                	ld	ra,24(sp)
    2984:	6442                	ld	s0,16(sp)
    2986:	64a2                	ld	s1,8(sp)
    2988:	6902                	ld	s2,0(sp)
    298a:	6105                	addi	sp,sp,32
    298c:	8082                	ret
    printf("%s: open failed\n", s);
    298e:	85ca                	mv	a1,s2
    2990:	00004517          	auipc	a0,0x4
    2994:	00050513          	mv	a0,a0
    2998:	00003097          	auipc	ra,0x3
    299c:	27e080e7          	jalr	638(ra) # 5c16 <printf>
    exit(1);
    29a0:	4505                	li	a0,1
    29a2:	00003097          	auipc	ra,0x3
    29a6:	ee4080e7          	jalr	-284(ra) # 5886 <exit>

00000000000029aa <sbrkbugs>:
{
    29aa:	1141                	addi	sp,sp,-16
    29ac:	e406                	sd	ra,8(sp)
    29ae:	e022                	sd	s0,0(sp)
    29b0:	0800                	addi	s0,sp,16
  int pid = fork();
    29b2:	00003097          	auipc	ra,0x3
    29b6:	ecc080e7          	jalr	-308(ra) # 587e <fork>
  if(pid < 0){
    29ba:	02054263          	bltz	a0,29de <sbrkbugs+0x34>
  if(pid == 0){
    29be:	ed0d                	bnez	a0,29f8 <sbrkbugs+0x4e>
    int sz = (uint64) sbrk(0);
    29c0:	00003097          	auipc	ra,0x3
    29c4:	f4e080e7          	jalr	-178(ra) # 590e <sbrk>
    sbrk(-sz);
    29c8:	40a0053b          	negw	a0,a0
    29cc:	00003097          	auipc	ra,0x3
    29d0:	f42080e7          	jalr	-190(ra) # 590e <sbrk>
    exit(0);
    29d4:	4501                	li	a0,0
    29d6:	00003097          	auipc	ra,0x3
    29da:	eb0080e7          	jalr	-336(ra) # 5886 <exit>
    printf("fork failed\n");
    29de:	00004517          	auipc	a0,0x4
    29e2:	3a250513          	addi	a0,a0,930 # 6d80 <malloc+0x10ac>
    29e6:	00003097          	auipc	ra,0x3
    29ea:	230080e7          	jalr	560(ra) # 5c16 <printf>
    exit(1);
    29ee:	4505                	li	a0,1
    29f0:	00003097          	auipc	ra,0x3
    29f4:	e96080e7          	jalr	-362(ra) # 5886 <exit>
  wait(0);
    29f8:	4501                	li	a0,0
    29fa:	00003097          	auipc	ra,0x3
    29fe:	e94080e7          	jalr	-364(ra) # 588e <wait>
  pid = fork();
    2a02:	00003097          	auipc	ra,0x3
    2a06:	e7c080e7          	jalr	-388(ra) # 587e <fork>
  if(pid < 0){
    2a0a:	02054563          	bltz	a0,2a34 <sbrkbugs+0x8a>
  if(pid == 0){
    2a0e:	e121                	bnez	a0,2a4e <sbrkbugs+0xa4>
    int sz = (uint64) sbrk(0);
    2a10:	00003097          	auipc	ra,0x3
    2a14:	efe080e7          	jalr	-258(ra) # 590e <sbrk>
    sbrk(-(sz - 3500));
    2a18:	6785                	lui	a5,0x1
    2a1a:	dac7879b          	addiw	a5,a5,-596
    2a1e:	40a7853b          	subw	a0,a5,a0
    2a22:	00003097          	auipc	ra,0x3
    2a26:	eec080e7          	jalr	-276(ra) # 590e <sbrk>
    exit(0);
    2a2a:	4501                	li	a0,0
    2a2c:	00003097          	auipc	ra,0x3
    2a30:	e5a080e7          	jalr	-422(ra) # 5886 <exit>
    printf("fork failed\n");
    2a34:	00004517          	auipc	a0,0x4
    2a38:	34c50513          	addi	a0,a0,844 # 6d80 <malloc+0x10ac>
    2a3c:	00003097          	auipc	ra,0x3
    2a40:	1da080e7          	jalr	474(ra) # 5c16 <printf>
    exit(1);
    2a44:	4505                	li	a0,1
    2a46:	00003097          	auipc	ra,0x3
    2a4a:	e40080e7          	jalr	-448(ra) # 5886 <exit>
  wait(0);
    2a4e:	4501                	li	a0,0
    2a50:	00003097          	auipc	ra,0x3
    2a54:	e3e080e7          	jalr	-450(ra) # 588e <wait>
  pid = fork();
    2a58:	00003097          	auipc	ra,0x3
    2a5c:	e26080e7          	jalr	-474(ra) # 587e <fork>
  if(pid < 0){
    2a60:	02054a63          	bltz	a0,2a94 <sbrkbugs+0xea>
  if(pid == 0){
    2a64:	e529                	bnez	a0,2aae <sbrkbugs+0x104>
    sbrk((10*4096 + 2048) - (uint64)sbrk(0));
    2a66:	00003097          	auipc	ra,0x3
    2a6a:	ea8080e7          	jalr	-344(ra) # 590e <sbrk>
    2a6e:	67ad                	lui	a5,0xb
    2a70:	8007879b          	addiw	a5,a5,-2048
    2a74:	40a7853b          	subw	a0,a5,a0
    2a78:	00003097          	auipc	ra,0x3
    2a7c:	e96080e7          	jalr	-362(ra) # 590e <sbrk>
    sbrk(-10);
    2a80:	5559                	li	a0,-10
    2a82:	00003097          	auipc	ra,0x3
    2a86:	e8c080e7          	jalr	-372(ra) # 590e <sbrk>
    exit(0);
    2a8a:	4501                	li	a0,0
    2a8c:	00003097          	auipc	ra,0x3
    2a90:	dfa080e7          	jalr	-518(ra) # 5886 <exit>
    printf("fork failed\n");
    2a94:	00004517          	auipc	a0,0x4
    2a98:	2ec50513          	addi	a0,a0,748 # 6d80 <malloc+0x10ac>
    2a9c:	00003097          	auipc	ra,0x3
    2aa0:	17a080e7          	jalr	378(ra) # 5c16 <printf>
    exit(1);
    2aa4:	4505                	li	a0,1
    2aa6:	00003097          	auipc	ra,0x3
    2aaa:	de0080e7          	jalr	-544(ra) # 5886 <exit>
  wait(0);
    2aae:	4501                	li	a0,0
    2ab0:	00003097          	auipc	ra,0x3
    2ab4:	dde080e7          	jalr	-546(ra) # 588e <wait>
  exit(0);
    2ab8:	4501                	li	a0,0
    2aba:	00003097          	auipc	ra,0x3
    2abe:	dcc080e7          	jalr	-564(ra) # 5886 <exit>

0000000000002ac2 <sbrklast>:
{
    2ac2:	7179                	addi	sp,sp,-48
    2ac4:	f406                	sd	ra,40(sp)
    2ac6:	f022                	sd	s0,32(sp)
    2ac8:	ec26                	sd	s1,24(sp)
    2aca:	e84a                	sd	s2,16(sp)
    2acc:	e44e                	sd	s3,8(sp)
    2ace:	1800                	addi	s0,sp,48
  uint64 top = (uint64) sbrk(0);
    2ad0:	4501                	li	a0,0
    2ad2:	00003097          	auipc	ra,0x3
    2ad6:	e3c080e7          	jalr	-452(ra) # 590e <sbrk>
  if((top % 4096) != 0)
    2ada:	03451793          	slli	a5,a0,0x34
    2ade:	efc1                	bnez	a5,2b76 <sbrklast+0xb4>
  sbrk(4096);
    2ae0:	6505                	lui	a0,0x1
    2ae2:	00003097          	auipc	ra,0x3
    2ae6:	e2c080e7          	jalr	-468(ra) # 590e <sbrk>
  sbrk(10);
    2aea:	4529                	li	a0,10
    2aec:	00003097          	auipc	ra,0x3
    2af0:	e22080e7          	jalr	-478(ra) # 590e <sbrk>
  sbrk(-20);
    2af4:	5531                	li	a0,-20
    2af6:	00003097          	auipc	ra,0x3
    2afa:	e18080e7          	jalr	-488(ra) # 590e <sbrk>
  top = (uint64) sbrk(0);
    2afe:	4501                	li	a0,0
    2b00:	00003097          	auipc	ra,0x3
    2b04:	e0e080e7          	jalr	-498(ra) # 590e <sbrk>
    2b08:	84aa                	mv	s1,a0
  char *p = (char *) (top - 64);
    2b0a:	fc050913          	addi	s2,a0,-64 # fc0 <bigdir+0x5e>
  p[0] = 'x';
    2b0e:	07800793          	li	a5,120
    2b12:	fcf50023          	sb	a5,-64(a0)
  p[1] = '\0';
    2b16:	fc0500a3          	sb	zero,-63(a0)
  int fd = open(p, O_RDWR|O_CREATE);
    2b1a:	20200593          	li	a1,514
    2b1e:	854a                	mv	a0,s2
    2b20:	00003097          	auipc	ra,0x3
    2b24:	da6080e7          	jalr	-602(ra) # 58c6 <open>
    2b28:	89aa                	mv	s3,a0
  write(fd, p, 1);
    2b2a:	4605                	li	a2,1
    2b2c:	85ca                	mv	a1,s2
    2b2e:	00003097          	auipc	ra,0x3
    2b32:	d78080e7          	jalr	-648(ra) # 58a6 <write>
  close(fd);
    2b36:	854e                	mv	a0,s3
    2b38:	00003097          	auipc	ra,0x3
    2b3c:	d76080e7          	jalr	-650(ra) # 58ae <close>
  fd = open(p, O_RDWR);
    2b40:	4589                	li	a1,2
    2b42:	854a                	mv	a0,s2
    2b44:	00003097          	auipc	ra,0x3
    2b48:	d82080e7          	jalr	-638(ra) # 58c6 <open>
  p[0] = '\0';
    2b4c:	fc048023          	sb	zero,-64(s1)
  read(fd, p, 1);
    2b50:	4605                	li	a2,1
    2b52:	85ca                	mv	a1,s2
    2b54:	00003097          	auipc	ra,0x3
    2b58:	d4a080e7          	jalr	-694(ra) # 589e <read>
  if(p[0] != 'x')
    2b5c:	fc04c703          	lbu	a4,-64(s1)
    2b60:	07800793          	li	a5,120
    2b64:	02f71363          	bne	a4,a5,2b8a <sbrklast+0xc8>
}
    2b68:	70a2                	ld	ra,40(sp)
    2b6a:	7402                	ld	s0,32(sp)
    2b6c:	64e2                	ld	s1,24(sp)
    2b6e:	6942                	ld	s2,16(sp)
    2b70:	69a2                	ld	s3,8(sp)
    2b72:	6145                	addi	sp,sp,48
    2b74:	8082                	ret
    sbrk(4096 - (top % 4096));
    2b76:	0347d513          	srli	a0,a5,0x34
    2b7a:	6785                	lui	a5,0x1
    2b7c:	40a7853b          	subw	a0,a5,a0
    2b80:	00003097          	auipc	ra,0x3
    2b84:	d8e080e7          	jalr	-626(ra) # 590e <sbrk>
    2b88:	bfa1                	j	2ae0 <sbrklast+0x1e>
    exit(1);
    2b8a:	4505                	li	a0,1
    2b8c:	00003097          	auipc	ra,0x3
    2b90:	cfa080e7          	jalr	-774(ra) # 5886 <exit>

0000000000002b94 <sbrk8000>:
{
    2b94:	1141                	addi	sp,sp,-16
    2b96:	e406                	sd	ra,8(sp)
    2b98:	e022                	sd	s0,0(sp)
    2b9a:	0800                	addi	s0,sp,16
  sbrk(0x80000004);
    2b9c:	80000537          	lui	a0,0x80000
    2ba0:	0511                	addi	a0,a0,4
    2ba2:	00003097          	auipc	ra,0x3
    2ba6:	d6c080e7          	jalr	-660(ra) # 590e <sbrk>
  volatile char *top = sbrk(0);
    2baa:	4501                	li	a0,0
    2bac:	00003097          	auipc	ra,0x3
    2bb0:	d62080e7          	jalr	-670(ra) # 590e <sbrk>
  *(top-1) = *(top-1) + 1;
    2bb4:	fff54783          	lbu	a5,-1(a0) # ffffffff7fffffff <__BSS_END__+0xffffffff7fff11e7>
    2bb8:	0785                	addi	a5,a5,1
    2bba:	0ff7f793          	andi	a5,a5,255
    2bbe:	fef50fa3          	sb	a5,-1(a0)
}
    2bc2:	60a2                	ld	ra,8(sp)
    2bc4:	6402                	ld	s0,0(sp)
    2bc6:	0141                	addi	sp,sp,16
    2bc8:	8082                	ret

0000000000002bca <execout>:
// test the exec() code that cleans up if it runs out
// of memory. it's really a test that such a condition
// doesn't cause a panic.
void
execout(char *s)
{
    2bca:	715d                	addi	sp,sp,-80
    2bcc:	e486                	sd	ra,72(sp)
    2bce:	e0a2                	sd	s0,64(sp)
    2bd0:	fc26                	sd	s1,56(sp)
    2bd2:	f84a                	sd	s2,48(sp)
    2bd4:	f44e                	sd	s3,40(sp)
    2bd6:	f052                	sd	s4,32(sp)
    2bd8:	0880                	addi	s0,sp,80
  for(int avail = 0; avail < 15; avail++){
    2bda:	4901                	li	s2,0
    2bdc:	49bd                	li	s3,15
    int pid = fork();
    2bde:	00003097          	auipc	ra,0x3
    2be2:	ca0080e7          	jalr	-864(ra) # 587e <fork>
    2be6:	84aa                	mv	s1,a0
    if(pid < 0){
    2be8:	02054063          	bltz	a0,2c08 <execout+0x3e>
      printf("fork failed\n");
      exit(1);
    } else if(pid == 0){
    2bec:	c91d                	beqz	a0,2c22 <execout+0x58>
      close(1);
      char *args[] = { "echo", "x", 0 };
      exec("echo", args);
      exit(0);
    } else {
      wait((int*)0);
    2bee:	4501                	li	a0,0
    2bf0:	00003097          	auipc	ra,0x3
    2bf4:	c9e080e7          	jalr	-866(ra) # 588e <wait>
  for(int avail = 0; avail < 15; avail++){
    2bf8:	2905                	addiw	s2,s2,1
    2bfa:	ff3912e3          	bne	s2,s3,2bde <execout+0x14>
    }
  }

  exit(0);
    2bfe:	4501                	li	a0,0
    2c00:	00003097          	auipc	ra,0x3
    2c04:	c86080e7          	jalr	-890(ra) # 5886 <exit>
      printf("fork failed\n");
    2c08:	00004517          	auipc	a0,0x4
    2c0c:	17850513          	addi	a0,a0,376 # 6d80 <malloc+0x10ac>
    2c10:	00003097          	auipc	ra,0x3
    2c14:	006080e7          	jalr	6(ra) # 5c16 <printf>
      exit(1);
    2c18:	4505                	li	a0,1
    2c1a:	00003097          	auipc	ra,0x3
    2c1e:	c6c080e7          	jalr	-916(ra) # 5886 <exit>
        if(a == 0xffffffffffffffffLL)
    2c22:	59fd                	li	s3,-1
        *(char*)(a + 4096 - 1) = 1;
    2c24:	4a05                	li	s4,1
        uint64 a = (uint64) sbrk(4096);
    2c26:	6505                	lui	a0,0x1
    2c28:	00003097          	auipc	ra,0x3
    2c2c:	ce6080e7          	jalr	-794(ra) # 590e <sbrk>
        if(a == 0xffffffffffffffffLL)
    2c30:	01350763          	beq	a0,s3,2c3e <execout+0x74>
        *(char*)(a + 4096 - 1) = 1;
    2c34:	6785                	lui	a5,0x1
    2c36:	953e                	add	a0,a0,a5
    2c38:	ff450fa3          	sb	s4,-1(a0) # fff <bigdir+0x9d>
      while(1){
    2c3c:	b7ed                	j	2c26 <execout+0x5c>
      for(int i = 0; i < avail; i++)
    2c3e:	01205a63          	blez	s2,2c52 <execout+0x88>
        sbrk(-4096);
    2c42:	757d                	lui	a0,0xfffff
    2c44:	00003097          	auipc	ra,0x3
    2c48:	cca080e7          	jalr	-822(ra) # 590e <sbrk>
      for(int i = 0; i < avail; i++)
    2c4c:	2485                	addiw	s1,s1,1
    2c4e:	ff249ae3          	bne	s1,s2,2c42 <execout+0x78>
      close(1);
    2c52:	4505                	li	a0,1
    2c54:	00003097          	auipc	ra,0x3
    2c58:	c5a080e7          	jalr	-934(ra) # 58ae <close>
      char *args[] = { "echo", "x", 0 };
    2c5c:	00003517          	auipc	a0,0x3
    2c60:	4e450513          	addi	a0,a0,1252 # 6140 <malloc+0x46c>
    2c64:	faa43c23          	sd	a0,-72(s0)
    2c68:	00003797          	auipc	a5,0x3
    2c6c:	54878793          	addi	a5,a5,1352 # 61b0 <malloc+0x4dc>
    2c70:	fcf43023          	sd	a5,-64(s0)
    2c74:	fc043423          	sd	zero,-56(s0)
      exec("echo", args);
    2c78:	fb840593          	addi	a1,s0,-72
    2c7c:	00003097          	auipc	ra,0x3
    2c80:	c42080e7          	jalr	-958(ra) # 58be <exec>
      exit(0);
    2c84:	4501                	li	a0,0
    2c86:	00003097          	auipc	ra,0x3
    2c8a:	c00080e7          	jalr	-1024(ra) # 5886 <exit>

0000000000002c8e <fourteen>:
{
    2c8e:	1101                	addi	sp,sp,-32
    2c90:	ec06                	sd	ra,24(sp)
    2c92:	e822                	sd	s0,16(sp)
    2c94:	e426                	sd	s1,8(sp)
    2c96:	1000                	addi	s0,sp,32
    2c98:	84aa                	mv	s1,a0
  if(mkdir("12345678901234") != 0){
    2c9a:	00004517          	auipc	a0,0x4
    2c9e:	5d650513          	addi	a0,a0,1494 # 7270 <malloc+0x159c>
    2ca2:	00003097          	auipc	ra,0x3
    2ca6:	c4c080e7          	jalr	-948(ra) # 58ee <mkdir>
    2caa:	e165                	bnez	a0,2d8a <fourteen+0xfc>
  if(mkdir("12345678901234/123456789012345") != 0){
    2cac:	00004517          	auipc	a0,0x4
    2cb0:	41c50513          	addi	a0,a0,1052 # 70c8 <malloc+0x13f4>
    2cb4:	00003097          	auipc	ra,0x3
    2cb8:	c3a080e7          	jalr	-966(ra) # 58ee <mkdir>
    2cbc:	e56d                	bnez	a0,2da6 <fourteen+0x118>
  fd = open("123456789012345/123456789012345/123456789012345", O_CREATE);
    2cbe:	20000593          	li	a1,512
    2cc2:	00004517          	auipc	a0,0x4
    2cc6:	45e50513          	addi	a0,a0,1118 # 7120 <malloc+0x144c>
    2cca:	00003097          	auipc	ra,0x3
    2cce:	bfc080e7          	jalr	-1028(ra) # 58c6 <open>
  if(fd < 0){
    2cd2:	0e054863          	bltz	a0,2dc2 <fourteen+0x134>
  close(fd);
    2cd6:	00003097          	auipc	ra,0x3
    2cda:	bd8080e7          	jalr	-1064(ra) # 58ae <close>
  fd = open("12345678901234/12345678901234/12345678901234", 0);
    2cde:	4581                	li	a1,0
    2ce0:	00004517          	auipc	a0,0x4
    2ce4:	4b850513          	addi	a0,a0,1208 # 7198 <malloc+0x14c4>
    2ce8:	00003097          	auipc	ra,0x3
    2cec:	bde080e7          	jalr	-1058(ra) # 58c6 <open>
  if(fd < 0){
    2cf0:	0e054763          	bltz	a0,2dde <fourteen+0x150>
  close(fd);
    2cf4:	00003097          	auipc	ra,0x3
    2cf8:	bba080e7          	jalr	-1094(ra) # 58ae <close>
  if(mkdir("12345678901234/12345678901234") == 0){
    2cfc:	00004517          	auipc	a0,0x4
    2d00:	50c50513          	addi	a0,a0,1292 # 7208 <malloc+0x1534>
    2d04:	00003097          	auipc	ra,0x3
    2d08:	bea080e7          	jalr	-1046(ra) # 58ee <mkdir>
    2d0c:	c57d                	beqz	a0,2dfa <fourteen+0x16c>
  if(mkdir("123456789012345/12345678901234") == 0){
    2d0e:	00004517          	auipc	a0,0x4
    2d12:	55250513          	addi	a0,a0,1362 # 7260 <malloc+0x158c>
    2d16:	00003097          	auipc	ra,0x3
    2d1a:	bd8080e7          	jalr	-1064(ra) # 58ee <mkdir>
    2d1e:	cd65                	beqz	a0,2e16 <fourteen+0x188>
  unlink("123456789012345/12345678901234");
    2d20:	00004517          	auipc	a0,0x4
    2d24:	54050513          	addi	a0,a0,1344 # 7260 <malloc+0x158c>
    2d28:	00003097          	auipc	ra,0x3
    2d2c:	bae080e7          	jalr	-1106(ra) # 58d6 <unlink>
  unlink("12345678901234/12345678901234");
    2d30:	00004517          	auipc	a0,0x4
    2d34:	4d850513          	addi	a0,a0,1240 # 7208 <malloc+0x1534>
    2d38:	00003097          	auipc	ra,0x3
    2d3c:	b9e080e7          	jalr	-1122(ra) # 58d6 <unlink>
  unlink("12345678901234/12345678901234/12345678901234");
    2d40:	00004517          	auipc	a0,0x4
    2d44:	45850513          	addi	a0,a0,1112 # 7198 <malloc+0x14c4>
    2d48:	00003097          	auipc	ra,0x3
    2d4c:	b8e080e7          	jalr	-1138(ra) # 58d6 <unlink>
  unlink("123456789012345/123456789012345/123456789012345");
    2d50:	00004517          	auipc	a0,0x4
    2d54:	3d050513          	addi	a0,a0,976 # 7120 <malloc+0x144c>
    2d58:	00003097          	auipc	ra,0x3
    2d5c:	b7e080e7          	jalr	-1154(ra) # 58d6 <unlink>
  unlink("12345678901234/123456789012345");
    2d60:	00004517          	auipc	a0,0x4
    2d64:	36850513          	addi	a0,a0,872 # 70c8 <malloc+0x13f4>
    2d68:	00003097          	auipc	ra,0x3
    2d6c:	b6e080e7          	jalr	-1170(ra) # 58d6 <unlink>
  unlink("12345678901234");
    2d70:	00004517          	auipc	a0,0x4
    2d74:	50050513          	addi	a0,a0,1280 # 7270 <malloc+0x159c>
    2d78:	00003097          	auipc	ra,0x3
    2d7c:	b5e080e7          	jalr	-1186(ra) # 58d6 <unlink>
}
    2d80:	60e2                	ld	ra,24(sp)
    2d82:	6442                	ld	s0,16(sp)
    2d84:	64a2                	ld	s1,8(sp)
    2d86:	6105                	addi	sp,sp,32
    2d88:	8082                	ret
    printf("%s: mkdir 12345678901234 failed\n", s);
    2d8a:	85a6                	mv	a1,s1
    2d8c:	00004517          	auipc	a0,0x4
    2d90:	31450513          	addi	a0,a0,788 # 70a0 <malloc+0x13cc>
    2d94:	00003097          	auipc	ra,0x3
    2d98:	e82080e7          	jalr	-382(ra) # 5c16 <printf>
    exit(1);
    2d9c:	4505                	li	a0,1
    2d9e:	00003097          	auipc	ra,0x3
    2da2:	ae8080e7          	jalr	-1304(ra) # 5886 <exit>
    printf("%s: mkdir 12345678901234/123456789012345 failed\n", s);
    2da6:	85a6                	mv	a1,s1
    2da8:	00004517          	auipc	a0,0x4
    2dac:	34050513          	addi	a0,a0,832 # 70e8 <malloc+0x1414>
    2db0:	00003097          	auipc	ra,0x3
    2db4:	e66080e7          	jalr	-410(ra) # 5c16 <printf>
    exit(1);
    2db8:	4505                	li	a0,1
    2dba:	00003097          	auipc	ra,0x3
    2dbe:	acc080e7          	jalr	-1332(ra) # 5886 <exit>
    printf("%s: create 123456789012345/123456789012345/123456789012345 failed\n", s);
    2dc2:	85a6                	mv	a1,s1
    2dc4:	00004517          	auipc	a0,0x4
    2dc8:	38c50513          	addi	a0,a0,908 # 7150 <malloc+0x147c>
    2dcc:	00003097          	auipc	ra,0x3
    2dd0:	e4a080e7          	jalr	-438(ra) # 5c16 <printf>
    exit(1);
    2dd4:	4505                	li	a0,1
    2dd6:	00003097          	auipc	ra,0x3
    2dda:	ab0080e7          	jalr	-1360(ra) # 5886 <exit>
    printf("%s: open 12345678901234/12345678901234/12345678901234 failed\n", s);
    2dde:	85a6                	mv	a1,s1
    2de0:	00004517          	auipc	a0,0x4
    2de4:	3e850513          	addi	a0,a0,1000 # 71c8 <malloc+0x14f4>
    2de8:	00003097          	auipc	ra,0x3
    2dec:	e2e080e7          	jalr	-466(ra) # 5c16 <printf>
    exit(1);
    2df0:	4505                	li	a0,1
    2df2:	00003097          	auipc	ra,0x3
    2df6:	a94080e7          	jalr	-1388(ra) # 5886 <exit>
    printf("%s: mkdir 12345678901234/12345678901234 succeeded!\n", s);
    2dfa:	85a6                	mv	a1,s1
    2dfc:	00004517          	auipc	a0,0x4
    2e00:	42c50513          	addi	a0,a0,1068 # 7228 <malloc+0x1554>
    2e04:	00003097          	auipc	ra,0x3
    2e08:	e12080e7          	jalr	-494(ra) # 5c16 <printf>
    exit(1);
    2e0c:	4505                	li	a0,1
    2e0e:	00003097          	auipc	ra,0x3
    2e12:	a78080e7          	jalr	-1416(ra) # 5886 <exit>
    printf("%s: mkdir 12345678901234/123456789012345 succeeded!\n", s);
    2e16:	85a6                	mv	a1,s1
    2e18:	00004517          	auipc	a0,0x4
    2e1c:	46850513          	addi	a0,a0,1128 # 7280 <malloc+0x15ac>
    2e20:	00003097          	auipc	ra,0x3
    2e24:	df6080e7          	jalr	-522(ra) # 5c16 <printf>
    exit(1);
    2e28:	4505                	li	a0,1
    2e2a:	00003097          	auipc	ra,0x3
    2e2e:	a5c080e7          	jalr	-1444(ra) # 5886 <exit>

0000000000002e32 <iputtest>:
{
    2e32:	1101                	addi	sp,sp,-32
    2e34:	ec06                	sd	ra,24(sp)
    2e36:	e822                	sd	s0,16(sp)
    2e38:	e426                	sd	s1,8(sp)
    2e3a:	1000                	addi	s0,sp,32
    2e3c:	84aa                	mv	s1,a0
  if(mkdir("iputdir") < 0){
    2e3e:	00004517          	auipc	a0,0x4
    2e42:	47a50513          	addi	a0,a0,1146 # 72b8 <malloc+0x15e4>
    2e46:	00003097          	auipc	ra,0x3
    2e4a:	aa8080e7          	jalr	-1368(ra) # 58ee <mkdir>
    2e4e:	04054563          	bltz	a0,2e98 <iputtest+0x66>
  if(chdir("iputdir") < 0){
    2e52:	00004517          	auipc	a0,0x4
    2e56:	46650513          	addi	a0,a0,1126 # 72b8 <malloc+0x15e4>
    2e5a:	00003097          	auipc	ra,0x3
    2e5e:	a9c080e7          	jalr	-1380(ra) # 58f6 <chdir>
    2e62:	04054963          	bltz	a0,2eb4 <iputtest+0x82>
  if(unlink("../iputdir") < 0){
    2e66:	00004517          	auipc	a0,0x4
    2e6a:	49250513          	addi	a0,a0,1170 # 72f8 <malloc+0x1624>
    2e6e:	00003097          	auipc	ra,0x3
    2e72:	a68080e7          	jalr	-1432(ra) # 58d6 <unlink>
    2e76:	04054d63          	bltz	a0,2ed0 <iputtest+0x9e>
  if(chdir("/") < 0){
    2e7a:	00004517          	auipc	a0,0x4
    2e7e:	4ae50513          	addi	a0,a0,1198 # 7328 <malloc+0x1654>
    2e82:	00003097          	auipc	ra,0x3
    2e86:	a74080e7          	jalr	-1420(ra) # 58f6 <chdir>
    2e8a:	06054163          	bltz	a0,2eec <iputtest+0xba>
}
    2e8e:	60e2                	ld	ra,24(sp)
    2e90:	6442                	ld	s0,16(sp)
    2e92:	64a2                	ld	s1,8(sp)
    2e94:	6105                	addi	sp,sp,32
    2e96:	8082                	ret
    printf("%s: mkdir failed\n", s);
    2e98:	85a6                	mv	a1,s1
    2e9a:	00004517          	auipc	a0,0x4
    2e9e:	42650513          	addi	a0,a0,1062 # 72c0 <malloc+0x15ec>
    2ea2:	00003097          	auipc	ra,0x3
    2ea6:	d74080e7          	jalr	-652(ra) # 5c16 <printf>
    exit(1);
    2eaa:	4505                	li	a0,1
    2eac:	00003097          	auipc	ra,0x3
    2eb0:	9da080e7          	jalr	-1574(ra) # 5886 <exit>
    printf("%s: chdir iputdir failed\n", s);
    2eb4:	85a6                	mv	a1,s1
    2eb6:	00004517          	auipc	a0,0x4
    2eba:	42250513          	addi	a0,a0,1058 # 72d8 <malloc+0x1604>
    2ebe:	00003097          	auipc	ra,0x3
    2ec2:	d58080e7          	jalr	-680(ra) # 5c16 <printf>
    exit(1);
    2ec6:	4505                	li	a0,1
    2ec8:	00003097          	auipc	ra,0x3
    2ecc:	9be080e7          	jalr	-1602(ra) # 5886 <exit>
    printf("%s: unlink ../iputdir failed\n", s);
    2ed0:	85a6                	mv	a1,s1
    2ed2:	00004517          	auipc	a0,0x4
    2ed6:	43650513          	addi	a0,a0,1078 # 7308 <malloc+0x1634>
    2eda:	00003097          	auipc	ra,0x3
    2ede:	d3c080e7          	jalr	-708(ra) # 5c16 <printf>
    exit(1);
    2ee2:	4505                	li	a0,1
    2ee4:	00003097          	auipc	ra,0x3
    2ee8:	9a2080e7          	jalr	-1630(ra) # 5886 <exit>
    printf("%s: chdir / failed\n", s);
    2eec:	85a6                	mv	a1,s1
    2eee:	00004517          	auipc	a0,0x4
    2ef2:	44250513          	addi	a0,a0,1090 # 7330 <malloc+0x165c>
    2ef6:	00003097          	auipc	ra,0x3
    2efa:	d20080e7          	jalr	-736(ra) # 5c16 <printf>
    exit(1);
    2efe:	4505                	li	a0,1
    2f00:	00003097          	auipc	ra,0x3
    2f04:	986080e7          	jalr	-1658(ra) # 5886 <exit>

0000000000002f08 <exitiputtest>:
{
    2f08:	7179                	addi	sp,sp,-48
    2f0a:	f406                	sd	ra,40(sp)
    2f0c:	f022                	sd	s0,32(sp)
    2f0e:	ec26                	sd	s1,24(sp)
    2f10:	1800                	addi	s0,sp,48
    2f12:	84aa                	mv	s1,a0
  pid = fork();
    2f14:	00003097          	auipc	ra,0x3
    2f18:	96a080e7          	jalr	-1686(ra) # 587e <fork>
  if(pid < 0){
    2f1c:	04054663          	bltz	a0,2f68 <exitiputtest+0x60>
  if(pid == 0){
    2f20:	ed45                	bnez	a0,2fd8 <exitiputtest+0xd0>
    if(mkdir("iputdir") < 0){
    2f22:	00004517          	auipc	a0,0x4
    2f26:	39650513          	addi	a0,a0,918 # 72b8 <malloc+0x15e4>
    2f2a:	00003097          	auipc	ra,0x3
    2f2e:	9c4080e7          	jalr	-1596(ra) # 58ee <mkdir>
    2f32:	04054963          	bltz	a0,2f84 <exitiputtest+0x7c>
    if(chdir("iputdir") < 0){
    2f36:	00004517          	auipc	a0,0x4
    2f3a:	38250513          	addi	a0,a0,898 # 72b8 <malloc+0x15e4>
    2f3e:	00003097          	auipc	ra,0x3
    2f42:	9b8080e7          	jalr	-1608(ra) # 58f6 <chdir>
    2f46:	04054d63          	bltz	a0,2fa0 <exitiputtest+0x98>
    if(unlink("../iputdir") < 0){
    2f4a:	00004517          	auipc	a0,0x4
    2f4e:	3ae50513          	addi	a0,a0,942 # 72f8 <malloc+0x1624>
    2f52:	00003097          	auipc	ra,0x3
    2f56:	984080e7          	jalr	-1660(ra) # 58d6 <unlink>
    2f5a:	06054163          	bltz	a0,2fbc <exitiputtest+0xb4>
    exit(0);
    2f5e:	4501                	li	a0,0
    2f60:	00003097          	auipc	ra,0x3
    2f64:	926080e7          	jalr	-1754(ra) # 5886 <exit>
    printf("%s: fork failed\n", s);
    2f68:	85a6                	mv	a1,s1
    2f6a:	00004517          	auipc	a0,0x4
    2f6e:	a0e50513          	addi	a0,a0,-1522 # 6978 <malloc+0xca4>
    2f72:	00003097          	auipc	ra,0x3
    2f76:	ca4080e7          	jalr	-860(ra) # 5c16 <printf>
    exit(1);
    2f7a:	4505                	li	a0,1
    2f7c:	00003097          	auipc	ra,0x3
    2f80:	90a080e7          	jalr	-1782(ra) # 5886 <exit>
      printf("%s: mkdir failed\n", s);
    2f84:	85a6                	mv	a1,s1
    2f86:	00004517          	auipc	a0,0x4
    2f8a:	33a50513          	addi	a0,a0,826 # 72c0 <malloc+0x15ec>
    2f8e:	00003097          	auipc	ra,0x3
    2f92:	c88080e7          	jalr	-888(ra) # 5c16 <printf>
      exit(1);
    2f96:	4505                	li	a0,1
    2f98:	00003097          	auipc	ra,0x3
    2f9c:	8ee080e7          	jalr	-1810(ra) # 5886 <exit>
      printf("%s: child chdir failed\n", s);
    2fa0:	85a6                	mv	a1,s1
    2fa2:	00004517          	auipc	a0,0x4
    2fa6:	3a650513          	addi	a0,a0,934 # 7348 <malloc+0x1674>
    2faa:	00003097          	auipc	ra,0x3
    2fae:	c6c080e7          	jalr	-916(ra) # 5c16 <printf>
      exit(1);
    2fb2:	4505                	li	a0,1
    2fb4:	00003097          	auipc	ra,0x3
    2fb8:	8d2080e7          	jalr	-1838(ra) # 5886 <exit>
      printf("%s: unlink ../iputdir failed\n", s);
    2fbc:	85a6                	mv	a1,s1
    2fbe:	00004517          	auipc	a0,0x4
    2fc2:	34a50513          	addi	a0,a0,842 # 7308 <malloc+0x1634>
    2fc6:	00003097          	auipc	ra,0x3
    2fca:	c50080e7          	jalr	-944(ra) # 5c16 <printf>
      exit(1);
    2fce:	4505                	li	a0,1
    2fd0:	00003097          	auipc	ra,0x3
    2fd4:	8b6080e7          	jalr	-1866(ra) # 5886 <exit>
  wait(&xstatus);
    2fd8:	fdc40513          	addi	a0,s0,-36
    2fdc:	00003097          	auipc	ra,0x3
    2fe0:	8b2080e7          	jalr	-1870(ra) # 588e <wait>
  exit(xstatus);
    2fe4:	fdc42503          	lw	a0,-36(s0)
    2fe8:	00003097          	auipc	ra,0x3
    2fec:	89e080e7          	jalr	-1890(ra) # 5886 <exit>

0000000000002ff0 <dirtest>:
{
    2ff0:	1101                	addi	sp,sp,-32
    2ff2:	ec06                	sd	ra,24(sp)
    2ff4:	e822                	sd	s0,16(sp)
    2ff6:	e426                	sd	s1,8(sp)
    2ff8:	1000                	addi	s0,sp,32
    2ffa:	84aa                	mv	s1,a0
  if(mkdir("dir0") < 0){
    2ffc:	00004517          	auipc	a0,0x4
    3000:	36450513          	addi	a0,a0,868 # 7360 <malloc+0x168c>
    3004:	00003097          	auipc	ra,0x3
    3008:	8ea080e7          	jalr	-1814(ra) # 58ee <mkdir>
    300c:	04054563          	bltz	a0,3056 <dirtest+0x66>
  if(chdir("dir0") < 0){
    3010:	00004517          	auipc	a0,0x4
    3014:	35050513          	addi	a0,a0,848 # 7360 <malloc+0x168c>
    3018:	00003097          	auipc	ra,0x3
    301c:	8de080e7          	jalr	-1826(ra) # 58f6 <chdir>
    3020:	04054963          	bltz	a0,3072 <dirtest+0x82>
  if(chdir("..") < 0){
    3024:	00004517          	auipc	a0,0x4
    3028:	35c50513          	addi	a0,a0,860 # 7380 <malloc+0x16ac>
    302c:	00003097          	auipc	ra,0x3
    3030:	8ca080e7          	jalr	-1846(ra) # 58f6 <chdir>
    3034:	04054d63          	bltz	a0,308e <dirtest+0x9e>
  if(unlink("dir0") < 0){
    3038:	00004517          	auipc	a0,0x4
    303c:	32850513          	addi	a0,a0,808 # 7360 <malloc+0x168c>
    3040:	00003097          	auipc	ra,0x3
    3044:	896080e7          	jalr	-1898(ra) # 58d6 <unlink>
    3048:	06054163          	bltz	a0,30aa <dirtest+0xba>
}
    304c:	60e2                	ld	ra,24(sp)
    304e:	6442                	ld	s0,16(sp)
    3050:	64a2                	ld	s1,8(sp)
    3052:	6105                	addi	sp,sp,32
    3054:	8082                	ret
    printf("%s: mkdir failed\n", s);
    3056:	85a6                	mv	a1,s1
    3058:	00004517          	auipc	a0,0x4
    305c:	26850513          	addi	a0,a0,616 # 72c0 <malloc+0x15ec>
    3060:	00003097          	auipc	ra,0x3
    3064:	bb6080e7          	jalr	-1098(ra) # 5c16 <printf>
    exit(1);
    3068:	4505                	li	a0,1
    306a:	00003097          	auipc	ra,0x3
    306e:	81c080e7          	jalr	-2020(ra) # 5886 <exit>
    printf("%s: chdir dir0 failed\n", s);
    3072:	85a6                	mv	a1,s1
    3074:	00004517          	auipc	a0,0x4
    3078:	2f450513          	addi	a0,a0,756 # 7368 <malloc+0x1694>
    307c:	00003097          	auipc	ra,0x3
    3080:	b9a080e7          	jalr	-1126(ra) # 5c16 <printf>
    exit(1);
    3084:	4505                	li	a0,1
    3086:	00003097          	auipc	ra,0x3
    308a:	800080e7          	jalr	-2048(ra) # 5886 <exit>
    printf("%s: chdir .. failed\n", s);
    308e:	85a6                	mv	a1,s1
    3090:	00004517          	auipc	a0,0x4
    3094:	2f850513          	addi	a0,a0,760 # 7388 <malloc+0x16b4>
    3098:	00003097          	auipc	ra,0x3
    309c:	b7e080e7          	jalr	-1154(ra) # 5c16 <printf>
    exit(1);
    30a0:	4505                	li	a0,1
    30a2:	00002097          	auipc	ra,0x2
    30a6:	7e4080e7          	jalr	2020(ra) # 5886 <exit>
    printf("%s: unlink dir0 failed\n", s);
    30aa:	85a6                	mv	a1,s1
    30ac:	00004517          	auipc	a0,0x4
    30b0:	2f450513          	addi	a0,a0,756 # 73a0 <malloc+0x16cc>
    30b4:	00003097          	auipc	ra,0x3
    30b8:	b62080e7          	jalr	-1182(ra) # 5c16 <printf>
    exit(1);
    30bc:	4505                	li	a0,1
    30be:	00002097          	auipc	ra,0x2
    30c2:	7c8080e7          	jalr	1992(ra) # 5886 <exit>

00000000000030c6 <subdir>:
{
    30c6:	1101                	addi	sp,sp,-32
    30c8:	ec06                	sd	ra,24(sp)
    30ca:	e822                	sd	s0,16(sp)
    30cc:	e426                	sd	s1,8(sp)
    30ce:	e04a                	sd	s2,0(sp)
    30d0:	1000                	addi	s0,sp,32
    30d2:	892a                	mv	s2,a0
  unlink("ff");
    30d4:	00004517          	auipc	a0,0x4
    30d8:	41450513          	addi	a0,a0,1044 # 74e8 <malloc+0x1814>
    30dc:	00002097          	auipc	ra,0x2
    30e0:	7fa080e7          	jalr	2042(ra) # 58d6 <unlink>
  if(mkdir("dd") != 0){
    30e4:	00004517          	auipc	a0,0x4
    30e8:	2d450513          	addi	a0,a0,724 # 73b8 <malloc+0x16e4>
    30ec:	00003097          	auipc	ra,0x3
    30f0:	802080e7          	jalr	-2046(ra) # 58ee <mkdir>
    30f4:	38051663          	bnez	a0,3480 <subdir+0x3ba>
  fd = open("dd/ff", O_CREATE | O_RDWR);
    30f8:	20200593          	li	a1,514
    30fc:	00004517          	auipc	a0,0x4
    3100:	2dc50513          	addi	a0,a0,732 # 73d8 <malloc+0x1704>
    3104:	00002097          	auipc	ra,0x2
    3108:	7c2080e7          	jalr	1986(ra) # 58c6 <open>
    310c:	84aa                	mv	s1,a0
  if(fd < 0){
    310e:	38054763          	bltz	a0,349c <subdir+0x3d6>
  write(fd, "ff", 2);
    3112:	4609                	li	a2,2
    3114:	00004597          	auipc	a1,0x4
    3118:	3d458593          	addi	a1,a1,980 # 74e8 <malloc+0x1814>
    311c:	00002097          	auipc	ra,0x2
    3120:	78a080e7          	jalr	1930(ra) # 58a6 <write>
  close(fd);
    3124:	8526                	mv	a0,s1
    3126:	00002097          	auipc	ra,0x2
    312a:	788080e7          	jalr	1928(ra) # 58ae <close>
  if(unlink("dd") >= 0){
    312e:	00004517          	auipc	a0,0x4
    3132:	28a50513          	addi	a0,a0,650 # 73b8 <malloc+0x16e4>
    3136:	00002097          	auipc	ra,0x2
    313a:	7a0080e7          	jalr	1952(ra) # 58d6 <unlink>
    313e:	36055d63          	bgez	a0,34b8 <subdir+0x3f2>
  if(mkdir("/dd/dd") != 0){
    3142:	00004517          	auipc	a0,0x4
    3146:	2ee50513          	addi	a0,a0,750 # 7430 <malloc+0x175c>
    314a:	00002097          	auipc	ra,0x2
    314e:	7a4080e7          	jalr	1956(ra) # 58ee <mkdir>
    3152:	38051163          	bnez	a0,34d4 <subdir+0x40e>
  fd = open("dd/dd/ff", O_CREATE | O_RDWR);
    3156:	20200593          	li	a1,514
    315a:	00004517          	auipc	a0,0x4
    315e:	2fe50513          	addi	a0,a0,766 # 7458 <malloc+0x1784>
    3162:	00002097          	auipc	ra,0x2
    3166:	764080e7          	jalr	1892(ra) # 58c6 <open>
    316a:	84aa                	mv	s1,a0
  if(fd < 0){
    316c:	38054263          	bltz	a0,34f0 <subdir+0x42a>
  write(fd, "FF", 2);
    3170:	4609                	li	a2,2
    3172:	00004597          	auipc	a1,0x4
    3176:	31658593          	addi	a1,a1,790 # 7488 <malloc+0x17b4>
    317a:	00002097          	auipc	ra,0x2
    317e:	72c080e7          	jalr	1836(ra) # 58a6 <write>
  close(fd);
    3182:	8526                	mv	a0,s1
    3184:	00002097          	auipc	ra,0x2
    3188:	72a080e7          	jalr	1834(ra) # 58ae <close>
  fd = open("dd/dd/../ff", 0);
    318c:	4581                	li	a1,0
    318e:	00004517          	auipc	a0,0x4
    3192:	30250513          	addi	a0,a0,770 # 7490 <malloc+0x17bc>
    3196:	00002097          	auipc	ra,0x2
    319a:	730080e7          	jalr	1840(ra) # 58c6 <open>
    319e:	84aa                	mv	s1,a0
  if(fd < 0){
    31a0:	36054663          	bltz	a0,350c <subdir+0x446>
  cc = read(fd, buf, sizeof(buf));
    31a4:	660d                	lui	a2,0x3
    31a6:	00009597          	auipc	a1,0x9
    31aa:	c6258593          	addi	a1,a1,-926 # be08 <buf>
    31ae:	00002097          	auipc	ra,0x2
    31b2:	6f0080e7          	jalr	1776(ra) # 589e <read>
  if(cc != 2 || buf[0] != 'f'){
    31b6:	4789                	li	a5,2
    31b8:	36f51863          	bne	a0,a5,3528 <subdir+0x462>
    31bc:	00009717          	auipc	a4,0x9
    31c0:	c4c74703          	lbu	a4,-948(a4) # be08 <buf>
    31c4:	06600793          	li	a5,102
    31c8:	36f71063          	bne	a4,a5,3528 <subdir+0x462>
  close(fd);
    31cc:	8526                	mv	a0,s1
    31ce:	00002097          	auipc	ra,0x2
    31d2:	6e0080e7          	jalr	1760(ra) # 58ae <close>
  if(link("dd/dd/ff", "dd/dd/ffff") != 0){
    31d6:	00004597          	auipc	a1,0x4
    31da:	30a58593          	addi	a1,a1,778 # 74e0 <malloc+0x180c>
    31de:	00004517          	auipc	a0,0x4
    31e2:	27a50513          	addi	a0,a0,634 # 7458 <malloc+0x1784>
    31e6:	00002097          	auipc	ra,0x2
    31ea:	700080e7          	jalr	1792(ra) # 58e6 <link>
    31ee:	34051b63          	bnez	a0,3544 <subdir+0x47e>
  if(unlink("dd/dd/ff") != 0){
    31f2:	00004517          	auipc	a0,0x4
    31f6:	26650513          	addi	a0,a0,614 # 7458 <malloc+0x1784>
    31fa:	00002097          	auipc	ra,0x2
    31fe:	6dc080e7          	jalr	1756(ra) # 58d6 <unlink>
    3202:	34051f63          	bnez	a0,3560 <subdir+0x49a>
  if(open("dd/dd/ff", O_RDONLY) >= 0){
    3206:	4581                	li	a1,0
    3208:	00004517          	auipc	a0,0x4
    320c:	25050513          	addi	a0,a0,592 # 7458 <malloc+0x1784>
    3210:	00002097          	auipc	ra,0x2
    3214:	6b6080e7          	jalr	1718(ra) # 58c6 <open>
    3218:	36055263          	bgez	a0,357c <subdir+0x4b6>
  if(chdir("dd") != 0){
    321c:	00004517          	auipc	a0,0x4
    3220:	19c50513          	addi	a0,a0,412 # 73b8 <malloc+0x16e4>
    3224:	00002097          	auipc	ra,0x2
    3228:	6d2080e7          	jalr	1746(ra) # 58f6 <chdir>
    322c:	36051663          	bnez	a0,3598 <subdir+0x4d2>
  if(chdir("dd/../../dd") != 0){
    3230:	00004517          	auipc	a0,0x4
    3234:	34850513          	addi	a0,a0,840 # 7578 <malloc+0x18a4>
    3238:	00002097          	auipc	ra,0x2
    323c:	6be080e7          	jalr	1726(ra) # 58f6 <chdir>
    3240:	36051a63          	bnez	a0,35b4 <subdir+0x4ee>
  if(chdir("dd/../../../dd") != 0){
    3244:	00004517          	auipc	a0,0x4
    3248:	36450513          	addi	a0,a0,868 # 75a8 <malloc+0x18d4>
    324c:	00002097          	auipc	ra,0x2
    3250:	6aa080e7          	jalr	1706(ra) # 58f6 <chdir>
    3254:	36051e63          	bnez	a0,35d0 <subdir+0x50a>
  if(chdir("./..") != 0){
    3258:	00004517          	auipc	a0,0x4
    325c:	38050513          	addi	a0,a0,896 # 75d8 <malloc+0x1904>
    3260:	00002097          	auipc	ra,0x2
    3264:	696080e7          	jalr	1686(ra) # 58f6 <chdir>
    3268:	38051263          	bnez	a0,35ec <subdir+0x526>
  fd = open("dd/dd/ffff", 0);
    326c:	4581                	li	a1,0
    326e:	00004517          	auipc	a0,0x4
    3272:	27250513          	addi	a0,a0,626 # 74e0 <malloc+0x180c>
    3276:	00002097          	auipc	ra,0x2
    327a:	650080e7          	jalr	1616(ra) # 58c6 <open>
    327e:	84aa                	mv	s1,a0
  if(fd < 0){
    3280:	38054463          	bltz	a0,3608 <subdir+0x542>
  if(read(fd, buf, sizeof(buf)) != 2){
    3284:	660d                	lui	a2,0x3
    3286:	00009597          	auipc	a1,0x9
    328a:	b8258593          	addi	a1,a1,-1150 # be08 <buf>
    328e:	00002097          	auipc	ra,0x2
    3292:	610080e7          	jalr	1552(ra) # 589e <read>
    3296:	4789                	li	a5,2
    3298:	38f51663          	bne	a0,a5,3624 <subdir+0x55e>
  close(fd);
    329c:	8526                	mv	a0,s1
    329e:	00002097          	auipc	ra,0x2
    32a2:	610080e7          	jalr	1552(ra) # 58ae <close>
  if(open("dd/dd/ff", O_RDONLY) >= 0){
    32a6:	4581                	li	a1,0
    32a8:	00004517          	auipc	a0,0x4
    32ac:	1b050513          	addi	a0,a0,432 # 7458 <malloc+0x1784>
    32b0:	00002097          	auipc	ra,0x2
    32b4:	616080e7          	jalr	1558(ra) # 58c6 <open>
    32b8:	38055463          	bgez	a0,3640 <subdir+0x57a>
  if(open("dd/ff/ff", O_CREATE|O_RDWR) >= 0){
    32bc:	20200593          	li	a1,514
    32c0:	00004517          	auipc	a0,0x4
    32c4:	3a850513          	addi	a0,a0,936 # 7668 <malloc+0x1994>
    32c8:	00002097          	auipc	ra,0x2
    32cc:	5fe080e7          	jalr	1534(ra) # 58c6 <open>
    32d0:	38055663          	bgez	a0,365c <subdir+0x596>
  if(open("dd/xx/ff", O_CREATE|O_RDWR) >= 0){
    32d4:	20200593          	li	a1,514
    32d8:	00004517          	auipc	a0,0x4
    32dc:	3c050513          	addi	a0,a0,960 # 7698 <malloc+0x19c4>
    32e0:	00002097          	auipc	ra,0x2
    32e4:	5e6080e7          	jalr	1510(ra) # 58c6 <open>
    32e8:	38055863          	bgez	a0,3678 <subdir+0x5b2>
  if(open("dd", O_CREATE) >= 0){
    32ec:	20000593          	li	a1,512
    32f0:	00004517          	auipc	a0,0x4
    32f4:	0c850513          	addi	a0,a0,200 # 73b8 <malloc+0x16e4>
    32f8:	00002097          	auipc	ra,0x2
    32fc:	5ce080e7          	jalr	1486(ra) # 58c6 <open>
    3300:	38055a63          	bgez	a0,3694 <subdir+0x5ce>
  if(open("dd", O_RDWR) >= 0){
    3304:	4589                	li	a1,2
    3306:	00004517          	auipc	a0,0x4
    330a:	0b250513          	addi	a0,a0,178 # 73b8 <malloc+0x16e4>
    330e:	00002097          	auipc	ra,0x2
    3312:	5b8080e7          	jalr	1464(ra) # 58c6 <open>
    3316:	38055d63          	bgez	a0,36b0 <subdir+0x5ea>
  if(open("dd", O_WRONLY) >= 0){
    331a:	4585                	li	a1,1
    331c:	00004517          	auipc	a0,0x4
    3320:	09c50513          	addi	a0,a0,156 # 73b8 <malloc+0x16e4>
    3324:	00002097          	auipc	ra,0x2
    3328:	5a2080e7          	jalr	1442(ra) # 58c6 <open>
    332c:	3a055063          	bgez	a0,36cc <subdir+0x606>
  if(link("dd/ff/ff", "dd/dd/xx") == 0){
    3330:	00004597          	auipc	a1,0x4
    3334:	3f858593          	addi	a1,a1,1016 # 7728 <malloc+0x1a54>
    3338:	00004517          	auipc	a0,0x4
    333c:	33050513          	addi	a0,a0,816 # 7668 <malloc+0x1994>
    3340:	00002097          	auipc	ra,0x2
    3344:	5a6080e7          	jalr	1446(ra) # 58e6 <link>
    3348:	3a050063          	beqz	a0,36e8 <subdir+0x622>
  if(link("dd/xx/ff", "dd/dd/xx") == 0){
    334c:	00004597          	auipc	a1,0x4
    3350:	3dc58593          	addi	a1,a1,988 # 7728 <malloc+0x1a54>
    3354:	00004517          	auipc	a0,0x4
    3358:	34450513          	addi	a0,a0,836 # 7698 <malloc+0x19c4>
    335c:	00002097          	auipc	ra,0x2
    3360:	58a080e7          	jalr	1418(ra) # 58e6 <link>
    3364:	3a050063          	beqz	a0,3704 <subdir+0x63e>
  if(link("dd/ff", "dd/dd/ffff") == 0){
    3368:	00004597          	auipc	a1,0x4
    336c:	17858593          	addi	a1,a1,376 # 74e0 <malloc+0x180c>
    3370:	00004517          	auipc	a0,0x4
    3374:	06850513          	addi	a0,a0,104 # 73d8 <malloc+0x1704>
    3378:	00002097          	auipc	ra,0x2
    337c:	56e080e7          	jalr	1390(ra) # 58e6 <link>
    3380:	3a050063          	beqz	a0,3720 <subdir+0x65a>
  if(mkdir("dd/ff/ff") == 0){
    3384:	00004517          	auipc	a0,0x4
    3388:	2e450513          	addi	a0,a0,740 # 7668 <malloc+0x1994>
    338c:	00002097          	auipc	ra,0x2
    3390:	562080e7          	jalr	1378(ra) # 58ee <mkdir>
    3394:	3a050463          	beqz	a0,373c <subdir+0x676>
  if(mkdir("dd/xx/ff") == 0){
    3398:	00004517          	auipc	a0,0x4
    339c:	30050513          	addi	a0,a0,768 # 7698 <malloc+0x19c4>
    33a0:	00002097          	auipc	ra,0x2
    33a4:	54e080e7          	jalr	1358(ra) # 58ee <mkdir>
    33a8:	3a050863          	beqz	a0,3758 <subdir+0x692>
  if(mkdir("dd/dd/ffff") == 0){
    33ac:	00004517          	auipc	a0,0x4
    33b0:	13450513          	addi	a0,a0,308 # 74e0 <malloc+0x180c>
    33b4:	00002097          	auipc	ra,0x2
    33b8:	53a080e7          	jalr	1338(ra) # 58ee <mkdir>
    33bc:	3a050c63          	beqz	a0,3774 <subdir+0x6ae>
  if(unlink("dd/xx/ff") == 0){
    33c0:	00004517          	auipc	a0,0x4
    33c4:	2d850513          	addi	a0,a0,728 # 7698 <malloc+0x19c4>
    33c8:	00002097          	auipc	ra,0x2
    33cc:	50e080e7          	jalr	1294(ra) # 58d6 <unlink>
    33d0:	3c050063          	beqz	a0,3790 <subdir+0x6ca>
  if(unlink("dd/ff/ff") == 0){
    33d4:	00004517          	auipc	a0,0x4
    33d8:	29450513          	addi	a0,a0,660 # 7668 <malloc+0x1994>
    33dc:	00002097          	auipc	ra,0x2
    33e0:	4fa080e7          	jalr	1274(ra) # 58d6 <unlink>
    33e4:	3c050463          	beqz	a0,37ac <subdir+0x6e6>
  if(chdir("dd/ff") == 0){
    33e8:	00004517          	auipc	a0,0x4
    33ec:	ff050513          	addi	a0,a0,-16 # 73d8 <malloc+0x1704>
    33f0:	00002097          	auipc	ra,0x2
    33f4:	506080e7          	jalr	1286(ra) # 58f6 <chdir>
    33f8:	3c050863          	beqz	a0,37c8 <subdir+0x702>
  if(chdir("dd/xx") == 0){
    33fc:	00004517          	auipc	a0,0x4
    3400:	47c50513          	addi	a0,a0,1148 # 7878 <malloc+0x1ba4>
    3404:	00002097          	auipc	ra,0x2
    3408:	4f2080e7          	jalr	1266(ra) # 58f6 <chdir>
    340c:	3c050c63          	beqz	a0,37e4 <subdir+0x71e>
  if(unlink("dd/dd/ffff") != 0){
    3410:	00004517          	auipc	a0,0x4
    3414:	0d050513          	addi	a0,a0,208 # 74e0 <malloc+0x180c>
    3418:	00002097          	auipc	ra,0x2
    341c:	4be080e7          	jalr	1214(ra) # 58d6 <unlink>
    3420:	3e051063          	bnez	a0,3800 <subdir+0x73a>
  if(unlink("dd/ff") != 0){
    3424:	00004517          	auipc	a0,0x4
    3428:	fb450513          	addi	a0,a0,-76 # 73d8 <malloc+0x1704>
    342c:	00002097          	auipc	ra,0x2
    3430:	4aa080e7          	jalr	1194(ra) # 58d6 <unlink>
    3434:	3e051463          	bnez	a0,381c <subdir+0x756>
  if(unlink("dd") == 0){
    3438:	00004517          	auipc	a0,0x4
    343c:	f8050513          	addi	a0,a0,-128 # 73b8 <malloc+0x16e4>
    3440:	00002097          	auipc	ra,0x2
    3444:	496080e7          	jalr	1174(ra) # 58d6 <unlink>
    3448:	3e050863          	beqz	a0,3838 <subdir+0x772>
  if(unlink("dd/dd") < 0){
    344c:	00004517          	auipc	a0,0x4
    3450:	49c50513          	addi	a0,a0,1180 # 78e8 <malloc+0x1c14>
    3454:	00002097          	auipc	ra,0x2
    3458:	482080e7          	jalr	1154(ra) # 58d6 <unlink>
    345c:	3e054c63          	bltz	a0,3854 <subdir+0x78e>
  if(unlink("dd") < 0){
    3460:	00004517          	auipc	a0,0x4
    3464:	f5850513          	addi	a0,a0,-168 # 73b8 <malloc+0x16e4>
    3468:	00002097          	auipc	ra,0x2
    346c:	46e080e7          	jalr	1134(ra) # 58d6 <unlink>
    3470:	40054063          	bltz	a0,3870 <subdir+0x7aa>
}
    3474:	60e2                	ld	ra,24(sp)
    3476:	6442                	ld	s0,16(sp)
    3478:	64a2                	ld	s1,8(sp)
    347a:	6902                	ld	s2,0(sp)
    347c:	6105                	addi	sp,sp,32
    347e:	8082                	ret
    printf("%s: mkdir dd failed\n", s);
    3480:	85ca                	mv	a1,s2
    3482:	00004517          	auipc	a0,0x4
    3486:	f3e50513          	addi	a0,a0,-194 # 73c0 <malloc+0x16ec>
    348a:	00002097          	auipc	ra,0x2
    348e:	78c080e7          	jalr	1932(ra) # 5c16 <printf>
    exit(1);
    3492:	4505                	li	a0,1
    3494:	00002097          	auipc	ra,0x2
    3498:	3f2080e7          	jalr	1010(ra) # 5886 <exit>
    printf("%s: create dd/ff failed\n", s);
    349c:	85ca                	mv	a1,s2
    349e:	00004517          	auipc	a0,0x4
    34a2:	f4250513          	addi	a0,a0,-190 # 73e0 <malloc+0x170c>
    34a6:	00002097          	auipc	ra,0x2
    34aa:	770080e7          	jalr	1904(ra) # 5c16 <printf>
    exit(1);
    34ae:	4505                	li	a0,1
    34b0:	00002097          	auipc	ra,0x2
    34b4:	3d6080e7          	jalr	982(ra) # 5886 <exit>
    printf("%s: unlink dd (non-empty dir) succeeded!\n", s);
    34b8:	85ca                	mv	a1,s2
    34ba:	00004517          	auipc	a0,0x4
    34be:	f4650513          	addi	a0,a0,-186 # 7400 <malloc+0x172c>
    34c2:	00002097          	auipc	ra,0x2
    34c6:	754080e7          	jalr	1876(ra) # 5c16 <printf>
    exit(1);
    34ca:	4505                	li	a0,1
    34cc:	00002097          	auipc	ra,0x2
    34d0:	3ba080e7          	jalr	954(ra) # 5886 <exit>
    printf("subdir mkdir dd/dd failed\n", s);
    34d4:	85ca                	mv	a1,s2
    34d6:	00004517          	auipc	a0,0x4
    34da:	f6250513          	addi	a0,a0,-158 # 7438 <malloc+0x1764>
    34de:	00002097          	auipc	ra,0x2
    34e2:	738080e7          	jalr	1848(ra) # 5c16 <printf>
    exit(1);
    34e6:	4505                	li	a0,1
    34e8:	00002097          	auipc	ra,0x2
    34ec:	39e080e7          	jalr	926(ra) # 5886 <exit>
    printf("%s: create dd/dd/ff failed\n", s);
    34f0:	85ca                	mv	a1,s2
    34f2:	00004517          	auipc	a0,0x4
    34f6:	f7650513          	addi	a0,a0,-138 # 7468 <malloc+0x1794>
    34fa:	00002097          	auipc	ra,0x2
    34fe:	71c080e7          	jalr	1820(ra) # 5c16 <printf>
    exit(1);
    3502:	4505                	li	a0,1
    3504:	00002097          	auipc	ra,0x2
    3508:	382080e7          	jalr	898(ra) # 5886 <exit>
    printf("%s: open dd/dd/../ff failed\n", s);
    350c:	85ca                	mv	a1,s2
    350e:	00004517          	auipc	a0,0x4
    3512:	f9250513          	addi	a0,a0,-110 # 74a0 <malloc+0x17cc>
    3516:	00002097          	auipc	ra,0x2
    351a:	700080e7          	jalr	1792(ra) # 5c16 <printf>
    exit(1);
    351e:	4505                	li	a0,1
    3520:	00002097          	auipc	ra,0x2
    3524:	366080e7          	jalr	870(ra) # 5886 <exit>
    printf("%s: dd/dd/../ff wrong content\n", s);
    3528:	85ca                	mv	a1,s2
    352a:	00004517          	auipc	a0,0x4
    352e:	f9650513          	addi	a0,a0,-106 # 74c0 <malloc+0x17ec>
    3532:	00002097          	auipc	ra,0x2
    3536:	6e4080e7          	jalr	1764(ra) # 5c16 <printf>
    exit(1);
    353a:	4505                	li	a0,1
    353c:	00002097          	auipc	ra,0x2
    3540:	34a080e7          	jalr	842(ra) # 5886 <exit>
    printf("link dd/dd/ff dd/dd/ffff failed\n", s);
    3544:	85ca                	mv	a1,s2
    3546:	00004517          	auipc	a0,0x4
    354a:	faa50513          	addi	a0,a0,-86 # 74f0 <malloc+0x181c>
    354e:	00002097          	auipc	ra,0x2
    3552:	6c8080e7          	jalr	1736(ra) # 5c16 <printf>
    exit(1);
    3556:	4505                	li	a0,1
    3558:	00002097          	auipc	ra,0x2
    355c:	32e080e7          	jalr	814(ra) # 5886 <exit>
    printf("%s: unlink dd/dd/ff failed\n", s);
    3560:	85ca                	mv	a1,s2
    3562:	00004517          	auipc	a0,0x4
    3566:	fb650513          	addi	a0,a0,-74 # 7518 <malloc+0x1844>
    356a:	00002097          	auipc	ra,0x2
    356e:	6ac080e7          	jalr	1708(ra) # 5c16 <printf>
    exit(1);
    3572:	4505                	li	a0,1
    3574:	00002097          	auipc	ra,0x2
    3578:	312080e7          	jalr	786(ra) # 5886 <exit>
    printf("%s: open (unlinked) dd/dd/ff succeeded\n", s);
    357c:	85ca                	mv	a1,s2
    357e:	00004517          	auipc	a0,0x4
    3582:	fba50513          	addi	a0,a0,-70 # 7538 <malloc+0x1864>
    3586:	00002097          	auipc	ra,0x2
    358a:	690080e7          	jalr	1680(ra) # 5c16 <printf>
    exit(1);
    358e:	4505                	li	a0,1
    3590:	00002097          	auipc	ra,0x2
    3594:	2f6080e7          	jalr	758(ra) # 5886 <exit>
    printf("%s: chdir dd failed\n", s);
    3598:	85ca                	mv	a1,s2
    359a:	00004517          	auipc	a0,0x4
    359e:	fc650513          	addi	a0,a0,-58 # 7560 <malloc+0x188c>
    35a2:	00002097          	auipc	ra,0x2
    35a6:	674080e7          	jalr	1652(ra) # 5c16 <printf>
    exit(1);
    35aa:	4505                	li	a0,1
    35ac:	00002097          	auipc	ra,0x2
    35b0:	2da080e7          	jalr	730(ra) # 5886 <exit>
    printf("%s: chdir dd/../../dd failed\n", s);
    35b4:	85ca                	mv	a1,s2
    35b6:	00004517          	auipc	a0,0x4
    35ba:	fd250513          	addi	a0,a0,-46 # 7588 <malloc+0x18b4>
    35be:	00002097          	auipc	ra,0x2
    35c2:	658080e7          	jalr	1624(ra) # 5c16 <printf>
    exit(1);
    35c6:	4505                	li	a0,1
    35c8:	00002097          	auipc	ra,0x2
    35cc:	2be080e7          	jalr	702(ra) # 5886 <exit>
    printf("chdir dd/../../dd failed\n", s);
    35d0:	85ca                	mv	a1,s2
    35d2:	00004517          	auipc	a0,0x4
    35d6:	fe650513          	addi	a0,a0,-26 # 75b8 <malloc+0x18e4>
    35da:	00002097          	auipc	ra,0x2
    35de:	63c080e7          	jalr	1596(ra) # 5c16 <printf>
    exit(1);
    35e2:	4505                	li	a0,1
    35e4:	00002097          	auipc	ra,0x2
    35e8:	2a2080e7          	jalr	674(ra) # 5886 <exit>
    printf("%s: chdir ./.. failed\n", s);
    35ec:	85ca                	mv	a1,s2
    35ee:	00004517          	auipc	a0,0x4
    35f2:	ff250513          	addi	a0,a0,-14 # 75e0 <malloc+0x190c>
    35f6:	00002097          	auipc	ra,0x2
    35fa:	620080e7          	jalr	1568(ra) # 5c16 <printf>
    exit(1);
    35fe:	4505                	li	a0,1
    3600:	00002097          	auipc	ra,0x2
    3604:	286080e7          	jalr	646(ra) # 5886 <exit>
    printf("%s: open dd/dd/ffff failed\n", s);
    3608:	85ca                	mv	a1,s2
    360a:	00004517          	auipc	a0,0x4
    360e:	fee50513          	addi	a0,a0,-18 # 75f8 <malloc+0x1924>
    3612:	00002097          	auipc	ra,0x2
    3616:	604080e7          	jalr	1540(ra) # 5c16 <printf>
    exit(1);
    361a:	4505                	li	a0,1
    361c:	00002097          	auipc	ra,0x2
    3620:	26a080e7          	jalr	618(ra) # 5886 <exit>
    printf("%s: read dd/dd/ffff wrong len\n", s);
    3624:	85ca                	mv	a1,s2
    3626:	00004517          	auipc	a0,0x4
    362a:	ff250513          	addi	a0,a0,-14 # 7618 <malloc+0x1944>
    362e:	00002097          	auipc	ra,0x2
    3632:	5e8080e7          	jalr	1512(ra) # 5c16 <printf>
    exit(1);
    3636:	4505                	li	a0,1
    3638:	00002097          	auipc	ra,0x2
    363c:	24e080e7          	jalr	590(ra) # 5886 <exit>
    printf("%s: open (unlinked) dd/dd/ff succeeded!\n", s);
    3640:	85ca                	mv	a1,s2
    3642:	00004517          	auipc	a0,0x4
    3646:	ff650513          	addi	a0,a0,-10 # 7638 <malloc+0x1964>
    364a:	00002097          	auipc	ra,0x2
    364e:	5cc080e7          	jalr	1484(ra) # 5c16 <printf>
    exit(1);
    3652:	4505                	li	a0,1
    3654:	00002097          	auipc	ra,0x2
    3658:	232080e7          	jalr	562(ra) # 5886 <exit>
    printf("%s: create dd/ff/ff succeeded!\n", s);
    365c:	85ca                	mv	a1,s2
    365e:	00004517          	auipc	a0,0x4
    3662:	01a50513          	addi	a0,a0,26 # 7678 <malloc+0x19a4>
    3666:	00002097          	auipc	ra,0x2
    366a:	5b0080e7          	jalr	1456(ra) # 5c16 <printf>
    exit(1);
    366e:	4505                	li	a0,1
    3670:	00002097          	auipc	ra,0x2
    3674:	216080e7          	jalr	534(ra) # 5886 <exit>
    printf("%s: create dd/xx/ff succeeded!\n", s);
    3678:	85ca                	mv	a1,s2
    367a:	00004517          	auipc	a0,0x4
    367e:	02e50513          	addi	a0,a0,46 # 76a8 <malloc+0x19d4>
    3682:	00002097          	auipc	ra,0x2
    3686:	594080e7          	jalr	1428(ra) # 5c16 <printf>
    exit(1);
    368a:	4505                	li	a0,1
    368c:	00002097          	auipc	ra,0x2
    3690:	1fa080e7          	jalr	506(ra) # 5886 <exit>
    printf("%s: create dd succeeded!\n", s);
    3694:	85ca                	mv	a1,s2
    3696:	00004517          	auipc	a0,0x4
    369a:	03250513          	addi	a0,a0,50 # 76c8 <malloc+0x19f4>
    369e:	00002097          	auipc	ra,0x2
    36a2:	578080e7          	jalr	1400(ra) # 5c16 <printf>
    exit(1);
    36a6:	4505                	li	a0,1
    36a8:	00002097          	auipc	ra,0x2
    36ac:	1de080e7          	jalr	478(ra) # 5886 <exit>
    printf("%s: open dd rdwr succeeded!\n", s);
    36b0:	85ca                	mv	a1,s2
    36b2:	00004517          	auipc	a0,0x4
    36b6:	03650513          	addi	a0,a0,54 # 76e8 <malloc+0x1a14>
    36ba:	00002097          	auipc	ra,0x2
    36be:	55c080e7          	jalr	1372(ra) # 5c16 <printf>
    exit(1);
    36c2:	4505                	li	a0,1
    36c4:	00002097          	auipc	ra,0x2
    36c8:	1c2080e7          	jalr	450(ra) # 5886 <exit>
    printf("%s: open dd wronly succeeded!\n", s);
    36cc:	85ca                	mv	a1,s2
    36ce:	00004517          	auipc	a0,0x4
    36d2:	03a50513          	addi	a0,a0,58 # 7708 <malloc+0x1a34>
    36d6:	00002097          	auipc	ra,0x2
    36da:	540080e7          	jalr	1344(ra) # 5c16 <printf>
    exit(1);
    36de:	4505                	li	a0,1
    36e0:	00002097          	auipc	ra,0x2
    36e4:	1a6080e7          	jalr	422(ra) # 5886 <exit>
    printf("%s: link dd/ff/ff dd/dd/xx succeeded!\n", s);
    36e8:	85ca                	mv	a1,s2
    36ea:	00004517          	auipc	a0,0x4
    36ee:	04e50513          	addi	a0,a0,78 # 7738 <malloc+0x1a64>
    36f2:	00002097          	auipc	ra,0x2
    36f6:	524080e7          	jalr	1316(ra) # 5c16 <printf>
    exit(1);
    36fa:	4505                	li	a0,1
    36fc:	00002097          	auipc	ra,0x2
    3700:	18a080e7          	jalr	394(ra) # 5886 <exit>
    printf("%s: link dd/xx/ff dd/dd/xx succeeded!\n", s);
    3704:	85ca                	mv	a1,s2
    3706:	00004517          	auipc	a0,0x4
    370a:	05a50513          	addi	a0,a0,90 # 7760 <malloc+0x1a8c>
    370e:	00002097          	auipc	ra,0x2
    3712:	508080e7          	jalr	1288(ra) # 5c16 <printf>
    exit(1);
    3716:	4505                	li	a0,1
    3718:	00002097          	auipc	ra,0x2
    371c:	16e080e7          	jalr	366(ra) # 5886 <exit>
    printf("%s: link dd/ff dd/dd/ffff succeeded!\n", s);
    3720:	85ca                	mv	a1,s2
    3722:	00004517          	auipc	a0,0x4
    3726:	06650513          	addi	a0,a0,102 # 7788 <malloc+0x1ab4>
    372a:	00002097          	auipc	ra,0x2
    372e:	4ec080e7          	jalr	1260(ra) # 5c16 <printf>
    exit(1);
    3732:	4505                	li	a0,1
    3734:	00002097          	auipc	ra,0x2
    3738:	152080e7          	jalr	338(ra) # 5886 <exit>
    printf("%s: mkdir dd/ff/ff succeeded!\n", s);
    373c:	85ca                	mv	a1,s2
    373e:	00004517          	auipc	a0,0x4
    3742:	07250513          	addi	a0,a0,114 # 77b0 <malloc+0x1adc>
    3746:	00002097          	auipc	ra,0x2
    374a:	4d0080e7          	jalr	1232(ra) # 5c16 <printf>
    exit(1);
    374e:	4505                	li	a0,1
    3750:	00002097          	auipc	ra,0x2
    3754:	136080e7          	jalr	310(ra) # 5886 <exit>
    printf("%s: mkdir dd/xx/ff succeeded!\n", s);
    3758:	85ca                	mv	a1,s2
    375a:	00004517          	auipc	a0,0x4
    375e:	07650513          	addi	a0,a0,118 # 77d0 <malloc+0x1afc>
    3762:	00002097          	auipc	ra,0x2
    3766:	4b4080e7          	jalr	1204(ra) # 5c16 <printf>
    exit(1);
    376a:	4505                	li	a0,1
    376c:	00002097          	auipc	ra,0x2
    3770:	11a080e7          	jalr	282(ra) # 5886 <exit>
    printf("%s: mkdir dd/dd/ffff succeeded!\n", s);
    3774:	85ca                	mv	a1,s2
    3776:	00004517          	auipc	a0,0x4
    377a:	07a50513          	addi	a0,a0,122 # 77f0 <malloc+0x1b1c>
    377e:	00002097          	auipc	ra,0x2
    3782:	498080e7          	jalr	1176(ra) # 5c16 <printf>
    exit(1);
    3786:	4505                	li	a0,1
    3788:	00002097          	auipc	ra,0x2
    378c:	0fe080e7          	jalr	254(ra) # 5886 <exit>
    printf("%s: unlink dd/xx/ff succeeded!\n", s);
    3790:	85ca                	mv	a1,s2
    3792:	00004517          	auipc	a0,0x4
    3796:	08650513          	addi	a0,a0,134 # 7818 <malloc+0x1b44>
    379a:	00002097          	auipc	ra,0x2
    379e:	47c080e7          	jalr	1148(ra) # 5c16 <printf>
    exit(1);
    37a2:	4505                	li	a0,1
    37a4:	00002097          	auipc	ra,0x2
    37a8:	0e2080e7          	jalr	226(ra) # 5886 <exit>
    printf("%s: unlink dd/ff/ff succeeded!\n", s);
    37ac:	85ca                	mv	a1,s2
    37ae:	00004517          	auipc	a0,0x4
    37b2:	08a50513          	addi	a0,a0,138 # 7838 <malloc+0x1b64>
    37b6:	00002097          	auipc	ra,0x2
    37ba:	460080e7          	jalr	1120(ra) # 5c16 <printf>
    exit(1);
    37be:	4505                	li	a0,1
    37c0:	00002097          	auipc	ra,0x2
    37c4:	0c6080e7          	jalr	198(ra) # 5886 <exit>
    printf("%s: chdir dd/ff succeeded!\n", s);
    37c8:	85ca                	mv	a1,s2
    37ca:	00004517          	auipc	a0,0x4
    37ce:	08e50513          	addi	a0,a0,142 # 7858 <malloc+0x1b84>
    37d2:	00002097          	auipc	ra,0x2
    37d6:	444080e7          	jalr	1092(ra) # 5c16 <printf>
    exit(1);
    37da:	4505                	li	a0,1
    37dc:	00002097          	auipc	ra,0x2
    37e0:	0aa080e7          	jalr	170(ra) # 5886 <exit>
    printf("%s: chdir dd/xx succeeded!\n", s);
    37e4:	85ca                	mv	a1,s2
    37e6:	00004517          	auipc	a0,0x4
    37ea:	09a50513          	addi	a0,a0,154 # 7880 <malloc+0x1bac>
    37ee:	00002097          	auipc	ra,0x2
    37f2:	428080e7          	jalr	1064(ra) # 5c16 <printf>
    exit(1);
    37f6:	4505                	li	a0,1
    37f8:	00002097          	auipc	ra,0x2
    37fc:	08e080e7          	jalr	142(ra) # 5886 <exit>
    printf("%s: unlink dd/dd/ff failed\n", s);
    3800:	85ca                	mv	a1,s2
    3802:	00004517          	auipc	a0,0x4
    3806:	d1650513          	addi	a0,a0,-746 # 7518 <malloc+0x1844>
    380a:	00002097          	auipc	ra,0x2
    380e:	40c080e7          	jalr	1036(ra) # 5c16 <printf>
    exit(1);
    3812:	4505                	li	a0,1
    3814:	00002097          	auipc	ra,0x2
    3818:	072080e7          	jalr	114(ra) # 5886 <exit>
    printf("%s: unlink dd/ff failed\n", s);
    381c:	85ca                	mv	a1,s2
    381e:	00004517          	auipc	a0,0x4
    3822:	08250513          	addi	a0,a0,130 # 78a0 <malloc+0x1bcc>
    3826:	00002097          	auipc	ra,0x2
    382a:	3f0080e7          	jalr	1008(ra) # 5c16 <printf>
    exit(1);
    382e:	4505                	li	a0,1
    3830:	00002097          	auipc	ra,0x2
    3834:	056080e7          	jalr	86(ra) # 5886 <exit>
    printf("%s: unlink non-empty dd succeeded!\n", s);
    3838:	85ca                	mv	a1,s2
    383a:	00004517          	auipc	a0,0x4
    383e:	08650513          	addi	a0,a0,134 # 78c0 <malloc+0x1bec>
    3842:	00002097          	auipc	ra,0x2
    3846:	3d4080e7          	jalr	980(ra) # 5c16 <printf>
    exit(1);
    384a:	4505                	li	a0,1
    384c:	00002097          	auipc	ra,0x2
    3850:	03a080e7          	jalr	58(ra) # 5886 <exit>
    printf("%s: unlink dd/dd failed\n", s);
    3854:	85ca                	mv	a1,s2
    3856:	00004517          	auipc	a0,0x4
    385a:	09a50513          	addi	a0,a0,154 # 78f0 <malloc+0x1c1c>
    385e:	00002097          	auipc	ra,0x2
    3862:	3b8080e7          	jalr	952(ra) # 5c16 <printf>
    exit(1);
    3866:	4505                	li	a0,1
    3868:	00002097          	auipc	ra,0x2
    386c:	01e080e7          	jalr	30(ra) # 5886 <exit>
    printf("%s: unlink dd failed\n", s);
    3870:	85ca                	mv	a1,s2
    3872:	00004517          	auipc	a0,0x4
    3876:	09e50513          	addi	a0,a0,158 # 7910 <malloc+0x1c3c>
    387a:	00002097          	auipc	ra,0x2
    387e:	39c080e7          	jalr	924(ra) # 5c16 <printf>
    exit(1);
    3882:	4505                	li	a0,1
    3884:	00002097          	auipc	ra,0x2
    3888:	002080e7          	jalr	2(ra) # 5886 <exit>

000000000000388c <rmdot>:
{
    388c:	1101                	addi	sp,sp,-32
    388e:	ec06                	sd	ra,24(sp)
    3890:	e822                	sd	s0,16(sp)
    3892:	e426                	sd	s1,8(sp)
    3894:	1000                	addi	s0,sp,32
    3896:	84aa                	mv	s1,a0
  if(mkdir("dots") != 0){
    3898:	00004517          	auipc	a0,0x4
    389c:	09050513          	addi	a0,a0,144 # 7928 <malloc+0x1c54>
    38a0:	00002097          	auipc	ra,0x2
    38a4:	04e080e7          	jalr	78(ra) # 58ee <mkdir>
    38a8:	e549                	bnez	a0,3932 <rmdot+0xa6>
  if(chdir("dots") != 0){
    38aa:	00004517          	auipc	a0,0x4
    38ae:	07e50513          	addi	a0,a0,126 # 7928 <malloc+0x1c54>
    38b2:	00002097          	auipc	ra,0x2
    38b6:	044080e7          	jalr	68(ra) # 58f6 <chdir>
    38ba:	e951                	bnez	a0,394e <rmdot+0xc2>
  if(unlink(".") == 0){
    38bc:	00003517          	auipc	a0,0x3
    38c0:	f1c50513          	addi	a0,a0,-228 # 67d8 <malloc+0xb04>
    38c4:	00002097          	auipc	ra,0x2
    38c8:	012080e7          	jalr	18(ra) # 58d6 <unlink>
    38cc:	cd59                	beqz	a0,396a <rmdot+0xde>
  if(unlink("..") == 0){
    38ce:	00004517          	auipc	a0,0x4
    38d2:	ab250513          	addi	a0,a0,-1358 # 7380 <malloc+0x16ac>
    38d6:	00002097          	auipc	ra,0x2
    38da:	000080e7          	jalr	ra # 58d6 <unlink>
    38de:	c545                	beqz	a0,3986 <rmdot+0xfa>
  if(chdir("/") != 0){
    38e0:	00004517          	auipc	a0,0x4
    38e4:	a4850513          	addi	a0,a0,-1464 # 7328 <malloc+0x1654>
    38e8:	00002097          	auipc	ra,0x2
    38ec:	00e080e7          	jalr	14(ra) # 58f6 <chdir>
    38f0:	e94d                	bnez	a0,39a2 <rmdot+0x116>
  if(unlink("dots/.") == 0){
    38f2:	00004517          	auipc	a0,0x4
    38f6:	09e50513          	addi	a0,a0,158 # 7990 <malloc+0x1cbc>
    38fa:	00002097          	auipc	ra,0x2
    38fe:	fdc080e7          	jalr	-36(ra) # 58d6 <unlink>
    3902:	cd55                	beqz	a0,39be <rmdot+0x132>
  if(unlink("dots/..") == 0){
    3904:	00004517          	auipc	a0,0x4
    3908:	0b450513          	addi	a0,a0,180 # 79b8 <malloc+0x1ce4>
    390c:	00002097          	auipc	ra,0x2
    3910:	fca080e7          	jalr	-54(ra) # 58d6 <unlink>
    3914:	c179                	beqz	a0,39da <rmdot+0x14e>
  if(unlink("dots") != 0){
    3916:	00004517          	auipc	a0,0x4
    391a:	01250513          	addi	a0,a0,18 # 7928 <malloc+0x1c54>
    391e:	00002097          	auipc	ra,0x2
    3922:	fb8080e7          	jalr	-72(ra) # 58d6 <unlink>
    3926:	e961                	bnez	a0,39f6 <rmdot+0x16a>
}
    3928:	60e2                	ld	ra,24(sp)
    392a:	6442                	ld	s0,16(sp)
    392c:	64a2                	ld	s1,8(sp)
    392e:	6105                	addi	sp,sp,32
    3930:	8082                	ret
    printf("%s: mkdir dots failed\n", s);
    3932:	85a6                	mv	a1,s1
    3934:	00004517          	auipc	a0,0x4
    3938:	ffc50513          	addi	a0,a0,-4 # 7930 <malloc+0x1c5c>
    393c:	00002097          	auipc	ra,0x2
    3940:	2da080e7          	jalr	730(ra) # 5c16 <printf>
    exit(1);
    3944:	4505                	li	a0,1
    3946:	00002097          	auipc	ra,0x2
    394a:	f40080e7          	jalr	-192(ra) # 5886 <exit>
    printf("%s: chdir dots failed\n", s);
    394e:	85a6                	mv	a1,s1
    3950:	00004517          	auipc	a0,0x4
    3954:	ff850513          	addi	a0,a0,-8 # 7948 <malloc+0x1c74>
    3958:	00002097          	auipc	ra,0x2
    395c:	2be080e7          	jalr	702(ra) # 5c16 <printf>
    exit(1);
    3960:	4505                	li	a0,1
    3962:	00002097          	auipc	ra,0x2
    3966:	f24080e7          	jalr	-220(ra) # 5886 <exit>
    printf("%s: rm . worked!\n", s);
    396a:	85a6                	mv	a1,s1
    396c:	00004517          	auipc	a0,0x4
    3970:	ff450513          	addi	a0,a0,-12 # 7960 <malloc+0x1c8c>
    3974:	00002097          	auipc	ra,0x2
    3978:	2a2080e7          	jalr	674(ra) # 5c16 <printf>
    exit(1);
    397c:	4505                	li	a0,1
    397e:	00002097          	auipc	ra,0x2
    3982:	f08080e7          	jalr	-248(ra) # 5886 <exit>
    printf("%s: rm .. worked!\n", s);
    3986:	85a6                	mv	a1,s1
    3988:	00004517          	auipc	a0,0x4
    398c:	ff050513          	addi	a0,a0,-16 # 7978 <malloc+0x1ca4>
    3990:	00002097          	auipc	ra,0x2
    3994:	286080e7          	jalr	646(ra) # 5c16 <printf>
    exit(1);
    3998:	4505                	li	a0,1
    399a:	00002097          	auipc	ra,0x2
    399e:	eec080e7          	jalr	-276(ra) # 5886 <exit>
    printf("%s: chdir / failed\n", s);
    39a2:	85a6                	mv	a1,s1
    39a4:	00004517          	auipc	a0,0x4
    39a8:	98c50513          	addi	a0,a0,-1652 # 7330 <malloc+0x165c>
    39ac:	00002097          	auipc	ra,0x2
    39b0:	26a080e7          	jalr	618(ra) # 5c16 <printf>
    exit(1);
    39b4:	4505                	li	a0,1
    39b6:	00002097          	auipc	ra,0x2
    39ba:	ed0080e7          	jalr	-304(ra) # 5886 <exit>
    printf("%s: unlink dots/. worked!\n", s);
    39be:	85a6                	mv	a1,s1
    39c0:	00004517          	auipc	a0,0x4
    39c4:	fd850513          	addi	a0,a0,-40 # 7998 <malloc+0x1cc4>
    39c8:	00002097          	auipc	ra,0x2
    39cc:	24e080e7          	jalr	590(ra) # 5c16 <printf>
    exit(1);
    39d0:	4505                	li	a0,1
    39d2:	00002097          	auipc	ra,0x2
    39d6:	eb4080e7          	jalr	-332(ra) # 5886 <exit>
    printf("%s: unlink dots/.. worked!\n", s);
    39da:	85a6                	mv	a1,s1
    39dc:	00004517          	auipc	a0,0x4
    39e0:	fe450513          	addi	a0,a0,-28 # 79c0 <malloc+0x1cec>
    39e4:	00002097          	auipc	ra,0x2
    39e8:	232080e7          	jalr	562(ra) # 5c16 <printf>
    exit(1);
    39ec:	4505                	li	a0,1
    39ee:	00002097          	auipc	ra,0x2
    39f2:	e98080e7          	jalr	-360(ra) # 5886 <exit>
    printf("%s: unlink dots failed!\n", s);
    39f6:	85a6                	mv	a1,s1
    39f8:	00004517          	auipc	a0,0x4
    39fc:	fe850513          	addi	a0,a0,-24 # 79e0 <malloc+0x1d0c>
    3a00:	00002097          	auipc	ra,0x2
    3a04:	216080e7          	jalr	534(ra) # 5c16 <printf>
    exit(1);
    3a08:	4505                	li	a0,1
    3a0a:	00002097          	auipc	ra,0x2
    3a0e:	e7c080e7          	jalr	-388(ra) # 5886 <exit>

0000000000003a12 <dirfile>:
{
    3a12:	1101                	addi	sp,sp,-32
    3a14:	ec06                	sd	ra,24(sp)
    3a16:	e822                	sd	s0,16(sp)
    3a18:	e426                	sd	s1,8(sp)
    3a1a:	e04a                	sd	s2,0(sp)
    3a1c:	1000                	addi	s0,sp,32
    3a1e:	892a                	mv	s2,a0
  fd = open("dirfile", O_CREATE);
    3a20:	20000593          	li	a1,512
    3a24:	00002517          	auipc	a0,0x2
    3a28:	6bc50513          	addi	a0,a0,1724 # 60e0 <malloc+0x40c>
    3a2c:	00002097          	auipc	ra,0x2
    3a30:	e9a080e7          	jalr	-358(ra) # 58c6 <open>
  if(fd < 0){
    3a34:	0e054d63          	bltz	a0,3b2e <dirfile+0x11c>
  close(fd);
    3a38:	00002097          	auipc	ra,0x2
    3a3c:	e76080e7          	jalr	-394(ra) # 58ae <close>
  if(chdir("dirfile") == 0){
    3a40:	00002517          	auipc	a0,0x2
    3a44:	6a050513          	addi	a0,a0,1696 # 60e0 <malloc+0x40c>
    3a48:	00002097          	auipc	ra,0x2
    3a4c:	eae080e7          	jalr	-338(ra) # 58f6 <chdir>
    3a50:	cd6d                	beqz	a0,3b4a <dirfile+0x138>
  fd = open("dirfile/xx", 0);
    3a52:	4581                	li	a1,0
    3a54:	00004517          	auipc	a0,0x4
    3a58:	fec50513          	addi	a0,a0,-20 # 7a40 <malloc+0x1d6c>
    3a5c:	00002097          	auipc	ra,0x2
    3a60:	e6a080e7          	jalr	-406(ra) # 58c6 <open>
  if(fd >= 0){
    3a64:	10055163          	bgez	a0,3b66 <dirfile+0x154>
  fd = open("dirfile/xx", O_CREATE);
    3a68:	20000593          	li	a1,512
    3a6c:	00004517          	auipc	a0,0x4
    3a70:	fd450513          	addi	a0,a0,-44 # 7a40 <malloc+0x1d6c>
    3a74:	00002097          	auipc	ra,0x2
    3a78:	e52080e7          	jalr	-430(ra) # 58c6 <open>
  if(fd >= 0){
    3a7c:	10055363          	bgez	a0,3b82 <dirfile+0x170>
  if(mkdir("dirfile/xx") == 0){
    3a80:	00004517          	auipc	a0,0x4
    3a84:	fc050513          	addi	a0,a0,-64 # 7a40 <malloc+0x1d6c>
    3a88:	00002097          	auipc	ra,0x2
    3a8c:	e66080e7          	jalr	-410(ra) # 58ee <mkdir>
    3a90:	10050763          	beqz	a0,3b9e <dirfile+0x18c>
  if(unlink("dirfile/xx") == 0){
    3a94:	00004517          	auipc	a0,0x4
    3a98:	fac50513          	addi	a0,a0,-84 # 7a40 <malloc+0x1d6c>
    3a9c:	00002097          	auipc	ra,0x2
    3aa0:	e3a080e7          	jalr	-454(ra) # 58d6 <unlink>
    3aa4:	10050b63          	beqz	a0,3bba <dirfile+0x1a8>
  if(link("README", "dirfile/xx") == 0){
    3aa8:	00004597          	auipc	a1,0x4
    3aac:	f9858593          	addi	a1,a1,-104 # 7a40 <malloc+0x1d6c>
    3ab0:	00003517          	auipc	a0,0x3
    3ab4:	82850513          	addi	a0,a0,-2008 # 62d8 <malloc+0x604>
    3ab8:	00002097          	auipc	ra,0x2
    3abc:	e2e080e7          	jalr	-466(ra) # 58e6 <link>
    3ac0:	10050b63          	beqz	a0,3bd6 <dirfile+0x1c4>
  if(unlink("dirfile") != 0){
    3ac4:	00002517          	auipc	a0,0x2
    3ac8:	61c50513          	addi	a0,a0,1564 # 60e0 <malloc+0x40c>
    3acc:	00002097          	auipc	ra,0x2
    3ad0:	e0a080e7          	jalr	-502(ra) # 58d6 <unlink>
    3ad4:	10051f63          	bnez	a0,3bf2 <dirfile+0x1e0>
  fd = open(".", O_RDWR);
    3ad8:	4589                	li	a1,2
    3ada:	00003517          	auipc	a0,0x3
    3ade:	cfe50513          	addi	a0,a0,-770 # 67d8 <malloc+0xb04>
    3ae2:	00002097          	auipc	ra,0x2
    3ae6:	de4080e7          	jalr	-540(ra) # 58c6 <open>
  if(fd >= 0){
    3aea:	12055263          	bgez	a0,3c0e <dirfile+0x1fc>
  fd = open(".", 0);
    3aee:	4581                	li	a1,0
    3af0:	00003517          	auipc	a0,0x3
    3af4:	ce850513          	addi	a0,a0,-792 # 67d8 <malloc+0xb04>
    3af8:	00002097          	auipc	ra,0x2
    3afc:	dce080e7          	jalr	-562(ra) # 58c6 <open>
    3b00:	84aa                	mv	s1,a0
  if(write(fd, "x", 1) > 0){
    3b02:	4605                	li	a2,1
    3b04:	00002597          	auipc	a1,0x2
    3b08:	6ac58593          	addi	a1,a1,1708 # 61b0 <malloc+0x4dc>
    3b0c:	00002097          	auipc	ra,0x2
    3b10:	d9a080e7          	jalr	-614(ra) # 58a6 <write>
    3b14:	10a04b63          	bgtz	a0,3c2a <dirfile+0x218>
  close(fd);
    3b18:	8526                	mv	a0,s1
    3b1a:	00002097          	auipc	ra,0x2
    3b1e:	d94080e7          	jalr	-620(ra) # 58ae <close>
}
    3b22:	60e2                	ld	ra,24(sp)
    3b24:	6442                	ld	s0,16(sp)
    3b26:	64a2                	ld	s1,8(sp)
    3b28:	6902                	ld	s2,0(sp)
    3b2a:	6105                	addi	sp,sp,32
    3b2c:	8082                	ret
    printf("%s: create dirfile failed\n", s);
    3b2e:	85ca                	mv	a1,s2
    3b30:	00004517          	auipc	a0,0x4
    3b34:	ed050513          	addi	a0,a0,-304 # 7a00 <malloc+0x1d2c>
    3b38:	00002097          	auipc	ra,0x2
    3b3c:	0de080e7          	jalr	222(ra) # 5c16 <printf>
    exit(1);
    3b40:	4505                	li	a0,1
    3b42:	00002097          	auipc	ra,0x2
    3b46:	d44080e7          	jalr	-700(ra) # 5886 <exit>
    printf("%s: chdir dirfile succeeded!\n", s);
    3b4a:	85ca                	mv	a1,s2
    3b4c:	00004517          	auipc	a0,0x4
    3b50:	ed450513          	addi	a0,a0,-300 # 7a20 <malloc+0x1d4c>
    3b54:	00002097          	auipc	ra,0x2
    3b58:	0c2080e7          	jalr	194(ra) # 5c16 <printf>
    exit(1);
    3b5c:	4505                	li	a0,1
    3b5e:	00002097          	auipc	ra,0x2
    3b62:	d28080e7          	jalr	-728(ra) # 5886 <exit>
    printf("%s: create dirfile/xx succeeded!\n", s);
    3b66:	85ca                	mv	a1,s2
    3b68:	00004517          	auipc	a0,0x4
    3b6c:	ee850513          	addi	a0,a0,-280 # 7a50 <malloc+0x1d7c>
    3b70:	00002097          	auipc	ra,0x2
    3b74:	0a6080e7          	jalr	166(ra) # 5c16 <printf>
    exit(1);
    3b78:	4505                	li	a0,1
    3b7a:	00002097          	auipc	ra,0x2
    3b7e:	d0c080e7          	jalr	-756(ra) # 5886 <exit>
    printf("%s: create dirfile/xx succeeded!\n", s);
    3b82:	85ca                	mv	a1,s2
    3b84:	00004517          	auipc	a0,0x4
    3b88:	ecc50513          	addi	a0,a0,-308 # 7a50 <malloc+0x1d7c>
    3b8c:	00002097          	auipc	ra,0x2
    3b90:	08a080e7          	jalr	138(ra) # 5c16 <printf>
    exit(1);
    3b94:	4505                	li	a0,1
    3b96:	00002097          	auipc	ra,0x2
    3b9a:	cf0080e7          	jalr	-784(ra) # 5886 <exit>
    printf("%s: mkdir dirfile/xx succeeded!\n", s);
    3b9e:	85ca                	mv	a1,s2
    3ba0:	00004517          	auipc	a0,0x4
    3ba4:	ed850513          	addi	a0,a0,-296 # 7a78 <malloc+0x1da4>
    3ba8:	00002097          	auipc	ra,0x2
    3bac:	06e080e7          	jalr	110(ra) # 5c16 <printf>
    exit(1);
    3bb0:	4505                	li	a0,1
    3bb2:	00002097          	auipc	ra,0x2
    3bb6:	cd4080e7          	jalr	-812(ra) # 5886 <exit>
    printf("%s: unlink dirfile/xx succeeded!\n", s);
    3bba:	85ca                	mv	a1,s2
    3bbc:	00004517          	auipc	a0,0x4
    3bc0:	ee450513          	addi	a0,a0,-284 # 7aa0 <malloc+0x1dcc>
    3bc4:	00002097          	auipc	ra,0x2
    3bc8:	052080e7          	jalr	82(ra) # 5c16 <printf>
    exit(1);
    3bcc:	4505                	li	a0,1
    3bce:	00002097          	auipc	ra,0x2
    3bd2:	cb8080e7          	jalr	-840(ra) # 5886 <exit>
    printf("%s: link to dirfile/xx succeeded!\n", s);
    3bd6:	85ca                	mv	a1,s2
    3bd8:	00004517          	auipc	a0,0x4
    3bdc:	ef050513          	addi	a0,a0,-272 # 7ac8 <malloc+0x1df4>
    3be0:	00002097          	auipc	ra,0x2
    3be4:	036080e7          	jalr	54(ra) # 5c16 <printf>
    exit(1);
    3be8:	4505                	li	a0,1
    3bea:	00002097          	auipc	ra,0x2
    3bee:	c9c080e7          	jalr	-868(ra) # 5886 <exit>
    printf("%s: unlink dirfile failed!\n", s);
    3bf2:	85ca                	mv	a1,s2
    3bf4:	00004517          	auipc	a0,0x4
    3bf8:	efc50513          	addi	a0,a0,-260 # 7af0 <malloc+0x1e1c>
    3bfc:	00002097          	auipc	ra,0x2
    3c00:	01a080e7          	jalr	26(ra) # 5c16 <printf>
    exit(1);
    3c04:	4505                	li	a0,1
    3c06:	00002097          	auipc	ra,0x2
    3c0a:	c80080e7          	jalr	-896(ra) # 5886 <exit>
    printf("%s: open . for writing succeeded!\n", s);
    3c0e:	85ca                	mv	a1,s2
    3c10:	00004517          	auipc	a0,0x4
    3c14:	f0050513          	addi	a0,a0,-256 # 7b10 <malloc+0x1e3c>
    3c18:	00002097          	auipc	ra,0x2
    3c1c:	ffe080e7          	jalr	-2(ra) # 5c16 <printf>
    exit(1);
    3c20:	4505                	li	a0,1
    3c22:	00002097          	auipc	ra,0x2
    3c26:	c64080e7          	jalr	-924(ra) # 5886 <exit>
    printf("%s: write . succeeded!\n", s);
    3c2a:	85ca                	mv	a1,s2
    3c2c:	00004517          	auipc	a0,0x4
    3c30:	f0c50513          	addi	a0,a0,-244 # 7b38 <malloc+0x1e64>
    3c34:	00002097          	auipc	ra,0x2
    3c38:	fe2080e7          	jalr	-30(ra) # 5c16 <printf>
    exit(1);
    3c3c:	4505                	li	a0,1
    3c3e:	00002097          	auipc	ra,0x2
    3c42:	c48080e7          	jalr	-952(ra) # 5886 <exit>

0000000000003c46 <iref>:
{
    3c46:	7139                	addi	sp,sp,-64
    3c48:	fc06                	sd	ra,56(sp)
    3c4a:	f822                	sd	s0,48(sp)
    3c4c:	f426                	sd	s1,40(sp)
    3c4e:	f04a                	sd	s2,32(sp)
    3c50:	ec4e                	sd	s3,24(sp)
    3c52:	e852                	sd	s4,16(sp)
    3c54:	e456                	sd	s5,8(sp)
    3c56:	e05a                	sd	s6,0(sp)
    3c58:	0080                	addi	s0,sp,64
    3c5a:	8b2a                	mv	s6,a0
    3c5c:	03300913          	li	s2,51
    if(mkdir("irefd") != 0){
    3c60:	00004a17          	auipc	s4,0x4
    3c64:	ef0a0a13          	addi	s4,s4,-272 # 7b50 <malloc+0x1e7c>
    mkdir("");
    3c68:	00004497          	auipc	s1,0x4
    3c6c:	9f848493          	addi	s1,s1,-1544 # 7660 <malloc+0x198c>
    link("README", "");
    3c70:	00002a97          	auipc	s5,0x2
    3c74:	668a8a93          	addi	s5,s5,1640 # 62d8 <malloc+0x604>
    fd = open("xx", O_CREATE);
    3c78:	00004997          	auipc	s3,0x4
    3c7c:	dd098993          	addi	s3,s3,-560 # 7a48 <malloc+0x1d74>
    3c80:	a891                	j	3cd4 <iref+0x8e>
      printf("%s: mkdir irefd failed\n", s);
    3c82:	85da                	mv	a1,s6
    3c84:	00004517          	auipc	a0,0x4
    3c88:	ed450513          	addi	a0,a0,-300 # 7b58 <malloc+0x1e84>
    3c8c:	00002097          	auipc	ra,0x2
    3c90:	f8a080e7          	jalr	-118(ra) # 5c16 <printf>
      exit(1);
    3c94:	4505                	li	a0,1
    3c96:	00002097          	auipc	ra,0x2
    3c9a:	bf0080e7          	jalr	-1040(ra) # 5886 <exit>
      printf("%s: chdir irefd failed\n", s);
    3c9e:	85da                	mv	a1,s6
    3ca0:	00004517          	auipc	a0,0x4
    3ca4:	ed050513          	addi	a0,a0,-304 # 7b70 <malloc+0x1e9c>
    3ca8:	00002097          	auipc	ra,0x2
    3cac:	f6e080e7          	jalr	-146(ra) # 5c16 <printf>
      exit(1);
    3cb0:	4505                	li	a0,1
    3cb2:	00002097          	auipc	ra,0x2
    3cb6:	bd4080e7          	jalr	-1068(ra) # 5886 <exit>
      close(fd);
    3cba:	00002097          	auipc	ra,0x2
    3cbe:	bf4080e7          	jalr	-1036(ra) # 58ae <close>
    3cc2:	a889                	j	3d14 <iref+0xce>
    unlink("xx");
    3cc4:	854e                	mv	a0,s3
    3cc6:	00002097          	auipc	ra,0x2
    3cca:	c10080e7          	jalr	-1008(ra) # 58d6 <unlink>
  for(i = 0; i < NINODE + 1; i++){
    3cce:	397d                	addiw	s2,s2,-1
    3cd0:	06090063          	beqz	s2,3d30 <iref+0xea>
    if(mkdir("irefd") != 0){
    3cd4:	8552                	mv	a0,s4
    3cd6:	00002097          	auipc	ra,0x2
    3cda:	c18080e7          	jalr	-1000(ra) # 58ee <mkdir>
    3cde:	f155                	bnez	a0,3c82 <iref+0x3c>
    if(chdir("irefd") != 0){
    3ce0:	8552                	mv	a0,s4
    3ce2:	00002097          	auipc	ra,0x2
    3ce6:	c14080e7          	jalr	-1004(ra) # 58f6 <chdir>
    3cea:	f955                	bnez	a0,3c9e <iref+0x58>
    mkdir("");
    3cec:	8526                	mv	a0,s1
    3cee:	00002097          	auipc	ra,0x2
    3cf2:	c00080e7          	jalr	-1024(ra) # 58ee <mkdir>
    link("README", "");
    3cf6:	85a6                	mv	a1,s1
    3cf8:	8556                	mv	a0,s5
    3cfa:	00002097          	auipc	ra,0x2
    3cfe:	bec080e7          	jalr	-1044(ra) # 58e6 <link>
    fd = open("", O_CREATE);
    3d02:	20000593          	li	a1,512
    3d06:	8526                	mv	a0,s1
    3d08:	00002097          	auipc	ra,0x2
    3d0c:	bbe080e7          	jalr	-1090(ra) # 58c6 <open>
    if(fd >= 0)
    3d10:	fa0555e3          	bgez	a0,3cba <iref+0x74>
    fd = open("xx", O_CREATE);
    3d14:	20000593          	li	a1,512
    3d18:	854e                	mv	a0,s3
    3d1a:	00002097          	auipc	ra,0x2
    3d1e:	bac080e7          	jalr	-1108(ra) # 58c6 <open>
    if(fd >= 0)
    3d22:	fa0541e3          	bltz	a0,3cc4 <iref+0x7e>
      close(fd);
    3d26:	00002097          	auipc	ra,0x2
    3d2a:	b88080e7          	jalr	-1144(ra) # 58ae <close>
    3d2e:	bf59                	j	3cc4 <iref+0x7e>
    3d30:	03300493          	li	s1,51
    chdir("..");
    3d34:	00003997          	auipc	s3,0x3
    3d38:	64c98993          	addi	s3,s3,1612 # 7380 <malloc+0x16ac>
    unlink("irefd");
    3d3c:	00004917          	auipc	s2,0x4
    3d40:	e1490913          	addi	s2,s2,-492 # 7b50 <malloc+0x1e7c>
    chdir("..");
    3d44:	854e                	mv	a0,s3
    3d46:	00002097          	auipc	ra,0x2
    3d4a:	bb0080e7          	jalr	-1104(ra) # 58f6 <chdir>
    unlink("irefd");
    3d4e:	854a                	mv	a0,s2
    3d50:	00002097          	auipc	ra,0x2
    3d54:	b86080e7          	jalr	-1146(ra) # 58d6 <unlink>
  for(i = 0; i < NINODE + 1; i++){
    3d58:	34fd                	addiw	s1,s1,-1
    3d5a:	f4ed                	bnez	s1,3d44 <iref+0xfe>
  chdir("/");
    3d5c:	00003517          	auipc	a0,0x3
    3d60:	5cc50513          	addi	a0,a0,1484 # 7328 <malloc+0x1654>
    3d64:	00002097          	auipc	ra,0x2
    3d68:	b92080e7          	jalr	-1134(ra) # 58f6 <chdir>
}
    3d6c:	70e2                	ld	ra,56(sp)
    3d6e:	7442                	ld	s0,48(sp)
    3d70:	74a2                	ld	s1,40(sp)
    3d72:	7902                	ld	s2,32(sp)
    3d74:	69e2                	ld	s3,24(sp)
    3d76:	6a42                	ld	s4,16(sp)
    3d78:	6aa2                	ld	s5,8(sp)
    3d7a:	6b02                	ld	s6,0(sp)
    3d7c:	6121                	addi	sp,sp,64
    3d7e:	8082                	ret

0000000000003d80 <openiputtest>:
{
    3d80:	7179                	addi	sp,sp,-48
    3d82:	f406                	sd	ra,40(sp)
    3d84:	f022                	sd	s0,32(sp)
    3d86:	ec26                	sd	s1,24(sp)
    3d88:	1800                	addi	s0,sp,48
    3d8a:	84aa                	mv	s1,a0
  if(mkdir("oidir") < 0){
    3d8c:	00004517          	auipc	a0,0x4
    3d90:	dfc50513          	addi	a0,a0,-516 # 7b88 <malloc+0x1eb4>
    3d94:	00002097          	auipc	ra,0x2
    3d98:	b5a080e7          	jalr	-1190(ra) # 58ee <mkdir>
    3d9c:	04054263          	bltz	a0,3de0 <openiputtest+0x60>
  pid = fork();
    3da0:	00002097          	auipc	ra,0x2
    3da4:	ade080e7          	jalr	-1314(ra) # 587e <fork>
  if(pid < 0){
    3da8:	04054a63          	bltz	a0,3dfc <openiputtest+0x7c>
  if(pid == 0){
    3dac:	e93d                	bnez	a0,3e22 <openiputtest+0xa2>
    int fd = open("oidir", O_RDWR);
    3dae:	4589                	li	a1,2
    3db0:	00004517          	auipc	a0,0x4
    3db4:	dd850513          	addi	a0,a0,-552 # 7b88 <malloc+0x1eb4>
    3db8:	00002097          	auipc	ra,0x2
    3dbc:	b0e080e7          	jalr	-1266(ra) # 58c6 <open>
    if(fd >= 0){
    3dc0:	04054c63          	bltz	a0,3e18 <openiputtest+0x98>
      printf("%s: open directory for write succeeded\n", s);
    3dc4:	85a6                	mv	a1,s1
    3dc6:	00004517          	auipc	a0,0x4
    3dca:	de250513          	addi	a0,a0,-542 # 7ba8 <malloc+0x1ed4>
    3dce:	00002097          	auipc	ra,0x2
    3dd2:	e48080e7          	jalr	-440(ra) # 5c16 <printf>
      exit(1);
    3dd6:	4505                	li	a0,1
    3dd8:	00002097          	auipc	ra,0x2
    3ddc:	aae080e7          	jalr	-1362(ra) # 5886 <exit>
    printf("%s: mkdir oidir failed\n", s);
    3de0:	85a6                	mv	a1,s1
    3de2:	00004517          	auipc	a0,0x4
    3de6:	dae50513          	addi	a0,a0,-594 # 7b90 <malloc+0x1ebc>
    3dea:	00002097          	auipc	ra,0x2
    3dee:	e2c080e7          	jalr	-468(ra) # 5c16 <printf>
    exit(1);
    3df2:	4505                	li	a0,1
    3df4:	00002097          	auipc	ra,0x2
    3df8:	a92080e7          	jalr	-1390(ra) # 5886 <exit>
    printf("%s: fork failed\n", s);
    3dfc:	85a6                	mv	a1,s1
    3dfe:	00003517          	auipc	a0,0x3
    3e02:	b7a50513          	addi	a0,a0,-1158 # 6978 <malloc+0xca4>
    3e06:	00002097          	auipc	ra,0x2
    3e0a:	e10080e7          	jalr	-496(ra) # 5c16 <printf>
    exit(1);
    3e0e:	4505                	li	a0,1
    3e10:	00002097          	auipc	ra,0x2
    3e14:	a76080e7          	jalr	-1418(ra) # 5886 <exit>
    exit(0);
    3e18:	4501                	li	a0,0
    3e1a:	00002097          	auipc	ra,0x2
    3e1e:	a6c080e7          	jalr	-1428(ra) # 5886 <exit>
  sleep(1);
    3e22:	4505                	li	a0,1
    3e24:	00002097          	auipc	ra,0x2
    3e28:	af2080e7          	jalr	-1294(ra) # 5916 <sleep>
  if(unlink("oidir") != 0){
    3e2c:	00004517          	auipc	a0,0x4
    3e30:	d5c50513          	addi	a0,a0,-676 # 7b88 <malloc+0x1eb4>
    3e34:	00002097          	auipc	ra,0x2
    3e38:	aa2080e7          	jalr	-1374(ra) # 58d6 <unlink>
    3e3c:	cd19                	beqz	a0,3e5a <openiputtest+0xda>
    printf("%s: unlink failed\n", s);
    3e3e:	85a6                	mv	a1,s1
    3e40:	00003517          	auipc	a0,0x3
    3e44:	d2850513          	addi	a0,a0,-728 # 6b68 <malloc+0xe94>
    3e48:	00002097          	auipc	ra,0x2
    3e4c:	dce080e7          	jalr	-562(ra) # 5c16 <printf>
    exit(1);
    3e50:	4505                	li	a0,1
    3e52:	00002097          	auipc	ra,0x2
    3e56:	a34080e7          	jalr	-1484(ra) # 5886 <exit>
  wait(&xstatus);
    3e5a:	fdc40513          	addi	a0,s0,-36
    3e5e:	00002097          	auipc	ra,0x2
    3e62:	a30080e7          	jalr	-1488(ra) # 588e <wait>
  exit(xstatus);
    3e66:	fdc42503          	lw	a0,-36(s0)
    3e6a:	00002097          	auipc	ra,0x2
    3e6e:	a1c080e7          	jalr	-1508(ra) # 5886 <exit>

0000000000003e72 <forkforkfork>:
{
    3e72:	1101                	addi	sp,sp,-32
    3e74:	ec06                	sd	ra,24(sp)
    3e76:	e822                	sd	s0,16(sp)
    3e78:	e426                	sd	s1,8(sp)
    3e7a:	1000                	addi	s0,sp,32
    3e7c:	84aa                	mv	s1,a0
  unlink("stopforking");
    3e7e:	00004517          	auipc	a0,0x4
    3e82:	d5250513          	addi	a0,a0,-686 # 7bd0 <malloc+0x1efc>
    3e86:	00002097          	auipc	ra,0x2
    3e8a:	a50080e7          	jalr	-1456(ra) # 58d6 <unlink>
  int pid = fork();
    3e8e:	00002097          	auipc	ra,0x2
    3e92:	9f0080e7          	jalr	-1552(ra) # 587e <fork>
  if(pid < 0){
    3e96:	04054563          	bltz	a0,3ee0 <forkforkfork+0x6e>
  if(pid == 0){
    3e9a:	c12d                	beqz	a0,3efc <forkforkfork+0x8a>
  sleep(20); // two seconds
    3e9c:	4551                	li	a0,20
    3e9e:	00002097          	auipc	ra,0x2
    3ea2:	a78080e7          	jalr	-1416(ra) # 5916 <sleep>
  close(open("stopforking", O_CREATE|O_RDWR));
    3ea6:	20200593          	li	a1,514
    3eaa:	00004517          	auipc	a0,0x4
    3eae:	d2650513          	addi	a0,a0,-730 # 7bd0 <malloc+0x1efc>
    3eb2:	00002097          	auipc	ra,0x2
    3eb6:	a14080e7          	jalr	-1516(ra) # 58c6 <open>
    3eba:	00002097          	auipc	ra,0x2
    3ebe:	9f4080e7          	jalr	-1548(ra) # 58ae <close>
  wait(0);
    3ec2:	4501                	li	a0,0
    3ec4:	00002097          	auipc	ra,0x2
    3ec8:	9ca080e7          	jalr	-1590(ra) # 588e <wait>
  sleep(10); // one second
    3ecc:	4529                	li	a0,10
    3ece:	00002097          	auipc	ra,0x2
    3ed2:	a48080e7          	jalr	-1464(ra) # 5916 <sleep>
}
    3ed6:	60e2                	ld	ra,24(sp)
    3ed8:	6442                	ld	s0,16(sp)
    3eda:	64a2                	ld	s1,8(sp)
    3edc:	6105                	addi	sp,sp,32
    3ede:	8082                	ret
    printf("%s: fork failed", s);
    3ee0:	85a6                	mv	a1,s1
    3ee2:	00003517          	auipc	a0,0x3
    3ee6:	c5650513          	addi	a0,a0,-938 # 6b38 <malloc+0xe64>
    3eea:	00002097          	auipc	ra,0x2
    3eee:	d2c080e7          	jalr	-724(ra) # 5c16 <printf>
    exit(1);
    3ef2:	4505                	li	a0,1
    3ef4:	00002097          	auipc	ra,0x2
    3ef8:	992080e7          	jalr	-1646(ra) # 5886 <exit>
      int fd = open("stopforking", 0);
    3efc:	00004497          	auipc	s1,0x4
    3f00:	cd448493          	addi	s1,s1,-812 # 7bd0 <malloc+0x1efc>
    3f04:	4581                	li	a1,0
    3f06:	8526                	mv	a0,s1
    3f08:	00002097          	auipc	ra,0x2
    3f0c:	9be080e7          	jalr	-1602(ra) # 58c6 <open>
      if(fd >= 0){
    3f10:	02055463          	bgez	a0,3f38 <forkforkfork+0xc6>
      if(fork() < 0){
    3f14:	00002097          	auipc	ra,0x2
    3f18:	96a080e7          	jalr	-1686(ra) # 587e <fork>
    3f1c:	fe0554e3          	bgez	a0,3f04 <forkforkfork+0x92>
        close(open("stopforking", O_CREATE|O_RDWR));
    3f20:	20200593          	li	a1,514
    3f24:	8526                	mv	a0,s1
    3f26:	00002097          	auipc	ra,0x2
    3f2a:	9a0080e7          	jalr	-1632(ra) # 58c6 <open>
    3f2e:	00002097          	auipc	ra,0x2
    3f32:	980080e7          	jalr	-1664(ra) # 58ae <close>
    3f36:	b7f9                	j	3f04 <forkforkfork+0x92>
        exit(0);
    3f38:	4501                	li	a0,0
    3f3a:	00002097          	auipc	ra,0x2
    3f3e:	94c080e7          	jalr	-1716(ra) # 5886 <exit>

0000000000003f42 <killstatus>:
{
    3f42:	7139                	addi	sp,sp,-64
    3f44:	fc06                	sd	ra,56(sp)
    3f46:	f822                	sd	s0,48(sp)
    3f48:	f426                	sd	s1,40(sp)
    3f4a:	f04a                	sd	s2,32(sp)
    3f4c:	ec4e                	sd	s3,24(sp)
    3f4e:	e852                	sd	s4,16(sp)
    3f50:	0080                	addi	s0,sp,64
    3f52:	8a2a                	mv	s4,a0
    3f54:	06400913          	li	s2,100
    if(xst != -1) {
    3f58:	59fd                	li	s3,-1
    int pid1 = fork();
    3f5a:	00002097          	auipc	ra,0x2
    3f5e:	924080e7          	jalr	-1756(ra) # 587e <fork>
    3f62:	84aa                	mv	s1,a0
    if(pid1 < 0){
    3f64:	02054f63          	bltz	a0,3fa2 <killstatus+0x60>
    if(pid1 == 0){
    3f68:	c939                	beqz	a0,3fbe <killstatus+0x7c>
    sleep(1);
    3f6a:	4505                	li	a0,1
    3f6c:	00002097          	auipc	ra,0x2
    3f70:	9aa080e7          	jalr	-1622(ra) # 5916 <sleep>
    kill(pid1);
    3f74:	8526                	mv	a0,s1
    3f76:	00002097          	auipc	ra,0x2
    3f7a:	940080e7          	jalr	-1728(ra) # 58b6 <kill>
    wait(&xst);
    3f7e:	fcc40513          	addi	a0,s0,-52
    3f82:	00002097          	auipc	ra,0x2
    3f86:	90c080e7          	jalr	-1780(ra) # 588e <wait>
    if(xst != -1) {
    3f8a:	fcc42783          	lw	a5,-52(s0)
    3f8e:	03379d63          	bne	a5,s3,3fc8 <killstatus+0x86>
  for(int i = 0; i < 100; i++){
    3f92:	397d                	addiw	s2,s2,-1
    3f94:	fc0913e3          	bnez	s2,3f5a <killstatus+0x18>
  exit(0);
    3f98:	4501                	li	a0,0
    3f9a:	00002097          	auipc	ra,0x2
    3f9e:	8ec080e7          	jalr	-1812(ra) # 5886 <exit>
      printf("%s: fork failed\n", s);
    3fa2:	85d2                	mv	a1,s4
    3fa4:	00003517          	auipc	a0,0x3
    3fa8:	9d450513          	addi	a0,a0,-1580 # 6978 <malloc+0xca4>
    3fac:	00002097          	auipc	ra,0x2
    3fb0:	c6a080e7          	jalr	-918(ra) # 5c16 <printf>
      exit(1);
    3fb4:	4505                	li	a0,1
    3fb6:	00002097          	auipc	ra,0x2
    3fba:	8d0080e7          	jalr	-1840(ra) # 5886 <exit>
        getpid();
    3fbe:	00002097          	auipc	ra,0x2
    3fc2:	948080e7          	jalr	-1720(ra) # 5906 <getpid>
      while(1) {
    3fc6:	bfe5                	j	3fbe <killstatus+0x7c>
       printf("%s: status should be -1\n", s);
    3fc8:	85d2                	mv	a1,s4
    3fca:	00004517          	auipc	a0,0x4
    3fce:	c1650513          	addi	a0,a0,-1002 # 7be0 <malloc+0x1f0c>
    3fd2:	00002097          	auipc	ra,0x2
    3fd6:	c44080e7          	jalr	-956(ra) # 5c16 <printf>
       exit(1);
    3fda:	4505                	li	a0,1
    3fdc:	00002097          	auipc	ra,0x2
    3fe0:	8aa080e7          	jalr	-1878(ra) # 5886 <exit>

0000000000003fe4 <preempt>:
{
    3fe4:	7139                	addi	sp,sp,-64
    3fe6:	fc06                	sd	ra,56(sp)
    3fe8:	f822                	sd	s0,48(sp)
    3fea:	f426                	sd	s1,40(sp)
    3fec:	f04a                	sd	s2,32(sp)
    3fee:	ec4e                	sd	s3,24(sp)
    3ff0:	e852                	sd	s4,16(sp)
    3ff2:	0080                	addi	s0,sp,64
    3ff4:	84aa                	mv	s1,a0
  pid1 = fork();
    3ff6:	00002097          	auipc	ra,0x2
    3ffa:	888080e7          	jalr	-1912(ra) # 587e <fork>
  if(pid1 < 0) {
    3ffe:	00054563          	bltz	a0,4008 <preempt+0x24>
    4002:	8a2a                	mv	s4,a0
  if(pid1 == 0)
    4004:	e105                	bnez	a0,4024 <preempt+0x40>
    for(;;)
    4006:	a001                	j	4006 <preempt+0x22>
    printf("%s: fork failed", s);
    4008:	85a6                	mv	a1,s1
    400a:	00003517          	auipc	a0,0x3
    400e:	b2e50513          	addi	a0,a0,-1234 # 6b38 <malloc+0xe64>
    4012:	00002097          	auipc	ra,0x2
    4016:	c04080e7          	jalr	-1020(ra) # 5c16 <printf>
    exit(1);
    401a:	4505                	li	a0,1
    401c:	00002097          	auipc	ra,0x2
    4020:	86a080e7          	jalr	-1942(ra) # 5886 <exit>
  pid2 = fork();
    4024:	00002097          	auipc	ra,0x2
    4028:	85a080e7          	jalr	-1958(ra) # 587e <fork>
    402c:	89aa                	mv	s3,a0
  if(pid2 < 0) {
    402e:	00054463          	bltz	a0,4036 <preempt+0x52>
  if(pid2 == 0)
    4032:	e105                	bnez	a0,4052 <preempt+0x6e>
    for(;;)
    4034:	a001                	j	4034 <preempt+0x50>
    printf("%s: fork failed\n", s);
    4036:	85a6                	mv	a1,s1
    4038:	00003517          	auipc	a0,0x3
    403c:	94050513          	addi	a0,a0,-1728 # 6978 <malloc+0xca4>
    4040:	00002097          	auipc	ra,0x2
    4044:	bd6080e7          	jalr	-1066(ra) # 5c16 <printf>
    exit(1);
    4048:	4505                	li	a0,1
    404a:	00002097          	auipc	ra,0x2
    404e:	83c080e7          	jalr	-1988(ra) # 5886 <exit>
  pipe(pfds);
    4052:	fc840513          	addi	a0,s0,-56
    4056:	00002097          	auipc	ra,0x2
    405a:	840080e7          	jalr	-1984(ra) # 5896 <pipe>
  pid3 = fork();
    405e:	00002097          	auipc	ra,0x2
    4062:	820080e7          	jalr	-2016(ra) # 587e <fork>
    4066:	892a                	mv	s2,a0
  if(pid3 < 0) {
    4068:	02054e63          	bltz	a0,40a4 <preempt+0xc0>
  if(pid3 == 0){
    406c:	e525                	bnez	a0,40d4 <preempt+0xf0>
    close(pfds[0]);
    406e:	fc842503          	lw	a0,-56(s0)
    4072:	00002097          	auipc	ra,0x2
    4076:	83c080e7          	jalr	-1988(ra) # 58ae <close>
    if(write(pfds[1], "x", 1) != 1)
    407a:	4605                	li	a2,1
    407c:	00002597          	auipc	a1,0x2
    4080:	13458593          	addi	a1,a1,308 # 61b0 <malloc+0x4dc>
    4084:	fcc42503          	lw	a0,-52(s0)
    4088:	00002097          	auipc	ra,0x2
    408c:	81e080e7          	jalr	-2018(ra) # 58a6 <write>
    4090:	4785                	li	a5,1
    4092:	02f51763          	bne	a0,a5,40c0 <preempt+0xdc>
    close(pfds[1]);
    4096:	fcc42503          	lw	a0,-52(s0)
    409a:	00002097          	auipc	ra,0x2
    409e:	814080e7          	jalr	-2028(ra) # 58ae <close>
    for(;;)
    40a2:	a001                	j	40a2 <preempt+0xbe>
     printf("%s: fork failed\n", s);
    40a4:	85a6                	mv	a1,s1
    40a6:	00003517          	auipc	a0,0x3
    40aa:	8d250513          	addi	a0,a0,-1838 # 6978 <malloc+0xca4>
    40ae:	00002097          	auipc	ra,0x2
    40b2:	b68080e7          	jalr	-1176(ra) # 5c16 <printf>
     exit(1);
    40b6:	4505                	li	a0,1
    40b8:	00001097          	auipc	ra,0x1
    40bc:	7ce080e7          	jalr	1998(ra) # 5886 <exit>
      printf("%s: preempt write error", s);
    40c0:	85a6                	mv	a1,s1
    40c2:	00004517          	auipc	a0,0x4
    40c6:	b3e50513          	addi	a0,a0,-1218 # 7c00 <malloc+0x1f2c>
    40ca:	00002097          	auipc	ra,0x2
    40ce:	b4c080e7          	jalr	-1204(ra) # 5c16 <printf>
    40d2:	b7d1                	j	4096 <preempt+0xb2>
  close(pfds[1]);
    40d4:	fcc42503          	lw	a0,-52(s0)
    40d8:	00001097          	auipc	ra,0x1
    40dc:	7d6080e7          	jalr	2006(ra) # 58ae <close>
  if(read(pfds[0], buf, sizeof(buf)) != 1){
    40e0:	660d                	lui	a2,0x3
    40e2:	00008597          	auipc	a1,0x8
    40e6:	d2658593          	addi	a1,a1,-730 # be08 <buf>
    40ea:	fc842503          	lw	a0,-56(s0)
    40ee:	00001097          	auipc	ra,0x1
    40f2:	7b0080e7          	jalr	1968(ra) # 589e <read>
    40f6:	4785                	li	a5,1
    40f8:	02f50363          	beq	a0,a5,411e <preempt+0x13a>
    printf("%s: preempt read error", s);
    40fc:	85a6                	mv	a1,s1
    40fe:	00004517          	auipc	a0,0x4
    4102:	b1a50513          	addi	a0,a0,-1254 # 7c18 <malloc+0x1f44>
    4106:	00002097          	auipc	ra,0x2
    410a:	b10080e7          	jalr	-1264(ra) # 5c16 <printf>
}
    410e:	70e2                	ld	ra,56(sp)
    4110:	7442                	ld	s0,48(sp)
    4112:	74a2                	ld	s1,40(sp)
    4114:	7902                	ld	s2,32(sp)
    4116:	69e2                	ld	s3,24(sp)
    4118:	6a42                	ld	s4,16(sp)
    411a:	6121                	addi	sp,sp,64
    411c:	8082                	ret
  close(pfds[0]);
    411e:	fc842503          	lw	a0,-56(s0)
    4122:	00001097          	auipc	ra,0x1
    4126:	78c080e7          	jalr	1932(ra) # 58ae <close>
  printf("kill... ");
    412a:	00004517          	auipc	a0,0x4
    412e:	b0650513          	addi	a0,a0,-1274 # 7c30 <malloc+0x1f5c>
    4132:	00002097          	auipc	ra,0x2
    4136:	ae4080e7          	jalr	-1308(ra) # 5c16 <printf>
  kill(pid1);
    413a:	8552                	mv	a0,s4
    413c:	00001097          	auipc	ra,0x1
    4140:	77a080e7          	jalr	1914(ra) # 58b6 <kill>
  kill(pid2);
    4144:	854e                	mv	a0,s3
    4146:	00001097          	auipc	ra,0x1
    414a:	770080e7          	jalr	1904(ra) # 58b6 <kill>
  kill(pid3);
    414e:	854a                	mv	a0,s2
    4150:	00001097          	auipc	ra,0x1
    4154:	766080e7          	jalr	1894(ra) # 58b6 <kill>
  printf("wait... ");
    4158:	00004517          	auipc	a0,0x4
    415c:	ae850513          	addi	a0,a0,-1304 # 7c40 <malloc+0x1f6c>
    4160:	00002097          	auipc	ra,0x2
    4164:	ab6080e7          	jalr	-1354(ra) # 5c16 <printf>
  wait(0);
    4168:	4501                	li	a0,0
    416a:	00001097          	auipc	ra,0x1
    416e:	724080e7          	jalr	1828(ra) # 588e <wait>
  wait(0);
    4172:	4501                	li	a0,0
    4174:	00001097          	auipc	ra,0x1
    4178:	71a080e7          	jalr	1818(ra) # 588e <wait>
  wait(0);
    417c:	4501                	li	a0,0
    417e:	00001097          	auipc	ra,0x1
    4182:	710080e7          	jalr	1808(ra) # 588e <wait>
    4186:	b761                	j	410e <preempt+0x12a>

0000000000004188 <reparent>:
{
    4188:	7179                	addi	sp,sp,-48
    418a:	f406                	sd	ra,40(sp)
    418c:	f022                	sd	s0,32(sp)
    418e:	ec26                	sd	s1,24(sp)
    4190:	e84a                	sd	s2,16(sp)
    4192:	e44e                	sd	s3,8(sp)
    4194:	e052                	sd	s4,0(sp)
    4196:	1800                	addi	s0,sp,48
    4198:	89aa                	mv	s3,a0
  int master_pid = getpid();
    419a:	00001097          	auipc	ra,0x1
    419e:	76c080e7          	jalr	1900(ra) # 5906 <getpid>
    41a2:	8a2a                	mv	s4,a0
    41a4:	0c800913          	li	s2,200
    int pid = fork();
    41a8:	00001097          	auipc	ra,0x1
    41ac:	6d6080e7          	jalr	1750(ra) # 587e <fork>
    41b0:	84aa                	mv	s1,a0
    if(pid < 0){
    41b2:	02054263          	bltz	a0,41d6 <reparent+0x4e>
    if(pid){
    41b6:	cd21                	beqz	a0,420e <reparent+0x86>
      if(wait(0) != pid){
    41b8:	4501                	li	a0,0
    41ba:	00001097          	auipc	ra,0x1
    41be:	6d4080e7          	jalr	1748(ra) # 588e <wait>
    41c2:	02951863          	bne	a0,s1,41f2 <reparent+0x6a>
  for(int i = 0; i < 200; i++){
    41c6:	397d                	addiw	s2,s2,-1
    41c8:	fe0910e3          	bnez	s2,41a8 <reparent+0x20>
  exit(0);
    41cc:	4501                	li	a0,0
    41ce:	00001097          	auipc	ra,0x1
    41d2:	6b8080e7          	jalr	1720(ra) # 5886 <exit>
      printf("%s: fork failed\n", s);
    41d6:	85ce                	mv	a1,s3
    41d8:	00002517          	auipc	a0,0x2
    41dc:	7a050513          	addi	a0,a0,1952 # 6978 <malloc+0xca4>
    41e0:	00002097          	auipc	ra,0x2
    41e4:	a36080e7          	jalr	-1482(ra) # 5c16 <printf>
      exit(1);
    41e8:	4505                	li	a0,1
    41ea:	00001097          	auipc	ra,0x1
    41ee:	69c080e7          	jalr	1692(ra) # 5886 <exit>
        printf("%s: wait wrong pid\n", s);
    41f2:	85ce                	mv	a1,s3
    41f4:	00003517          	auipc	a0,0x3
    41f8:	90c50513          	addi	a0,a0,-1780 # 6b00 <malloc+0xe2c>
    41fc:	00002097          	auipc	ra,0x2
    4200:	a1a080e7          	jalr	-1510(ra) # 5c16 <printf>
        exit(1);
    4204:	4505                	li	a0,1
    4206:	00001097          	auipc	ra,0x1
    420a:	680080e7          	jalr	1664(ra) # 5886 <exit>
      int pid2 = fork();
    420e:	00001097          	auipc	ra,0x1
    4212:	670080e7          	jalr	1648(ra) # 587e <fork>
      if(pid2 < 0){
    4216:	00054763          	bltz	a0,4224 <reparent+0x9c>
      exit(0);
    421a:	4501                	li	a0,0
    421c:	00001097          	auipc	ra,0x1
    4220:	66a080e7          	jalr	1642(ra) # 5886 <exit>
        kill(master_pid);
    4224:	8552                	mv	a0,s4
    4226:	00001097          	auipc	ra,0x1
    422a:	690080e7          	jalr	1680(ra) # 58b6 <kill>
        exit(1);
    422e:	4505                	li	a0,1
    4230:	00001097          	auipc	ra,0x1
    4234:	656080e7          	jalr	1622(ra) # 5886 <exit>

0000000000004238 <sbrkfail>:
{
    4238:	7119                	addi	sp,sp,-128
    423a:	fc86                	sd	ra,120(sp)
    423c:	f8a2                	sd	s0,112(sp)
    423e:	f4a6                	sd	s1,104(sp)
    4240:	f0ca                	sd	s2,96(sp)
    4242:	ecce                	sd	s3,88(sp)
    4244:	e8d2                	sd	s4,80(sp)
    4246:	e4d6                	sd	s5,72(sp)
    4248:	0100                	addi	s0,sp,128
    424a:	892a                	mv	s2,a0
  if(pipe(fds) != 0){
    424c:	fb040513          	addi	a0,s0,-80
    4250:	00001097          	auipc	ra,0x1
    4254:	646080e7          	jalr	1606(ra) # 5896 <pipe>
    4258:	e901                	bnez	a0,4268 <sbrkfail+0x30>
    425a:	f8040493          	addi	s1,s0,-128
    425e:	fa840a13          	addi	s4,s0,-88
    4262:	89a6                	mv	s3,s1
    if(pids[i] != -1)
    4264:	5afd                	li	s5,-1
    4266:	a08d                	j	42c8 <sbrkfail+0x90>
    printf("%s: pipe() failed\n", s);
    4268:	85ca                	mv	a1,s2
    426a:	00003517          	auipc	a0,0x3
    426e:	81650513          	addi	a0,a0,-2026 # 6a80 <malloc+0xdac>
    4272:	00002097          	auipc	ra,0x2
    4276:	9a4080e7          	jalr	-1628(ra) # 5c16 <printf>
    exit(1);
    427a:	4505                	li	a0,1
    427c:	00001097          	auipc	ra,0x1
    4280:	60a080e7          	jalr	1546(ra) # 5886 <exit>
      sbrk(BIG - (uint64)sbrk(0));
    4284:	4501                	li	a0,0
    4286:	00001097          	auipc	ra,0x1
    428a:	688080e7          	jalr	1672(ra) # 590e <sbrk>
    428e:	064007b7          	lui	a5,0x6400
    4292:	40a7853b          	subw	a0,a5,a0
    4296:	00001097          	auipc	ra,0x1
    429a:	678080e7          	jalr	1656(ra) # 590e <sbrk>
      write(fds[1], "x", 1);
    429e:	4605                	li	a2,1
    42a0:	00002597          	auipc	a1,0x2
    42a4:	f1058593          	addi	a1,a1,-240 # 61b0 <malloc+0x4dc>
    42a8:	fb442503          	lw	a0,-76(s0)
    42ac:	00001097          	auipc	ra,0x1
    42b0:	5fa080e7          	jalr	1530(ra) # 58a6 <write>
      for(;;) sleep(1000);
    42b4:	3e800513          	li	a0,1000
    42b8:	00001097          	auipc	ra,0x1
    42bc:	65e080e7          	jalr	1630(ra) # 5916 <sleep>
    42c0:	bfd5                	j	42b4 <sbrkfail+0x7c>
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    42c2:	0991                	addi	s3,s3,4
    42c4:	03498563          	beq	s3,s4,42ee <sbrkfail+0xb6>
    if((pids[i] = fork()) == 0){
    42c8:	00001097          	auipc	ra,0x1
    42cc:	5b6080e7          	jalr	1462(ra) # 587e <fork>
    42d0:	00a9a023          	sw	a0,0(s3)
    42d4:	d945                	beqz	a0,4284 <sbrkfail+0x4c>
    if(pids[i] != -1)
    42d6:	ff5506e3          	beq	a0,s5,42c2 <sbrkfail+0x8a>
      read(fds[0], &scratch, 1);
    42da:	4605                	li	a2,1
    42dc:	faf40593          	addi	a1,s0,-81
    42e0:	fb042503          	lw	a0,-80(s0)
    42e4:	00001097          	auipc	ra,0x1
    42e8:	5ba080e7          	jalr	1466(ra) # 589e <read>
    42ec:	bfd9                	j	42c2 <sbrkfail+0x8a>
  c = sbrk(PGSIZE);
    42ee:	6505                	lui	a0,0x1
    42f0:	00001097          	auipc	ra,0x1
    42f4:	61e080e7          	jalr	1566(ra) # 590e <sbrk>
    42f8:	89aa                	mv	s3,a0
    if(pids[i] == -1)
    42fa:	5afd                	li	s5,-1
    42fc:	a021                	j	4304 <sbrkfail+0xcc>
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    42fe:	0491                	addi	s1,s1,4
    4300:	01448f63          	beq	s1,s4,431e <sbrkfail+0xe6>
    if(pids[i] == -1)
    4304:	4088                	lw	a0,0(s1)
    4306:	ff550ce3          	beq	a0,s5,42fe <sbrkfail+0xc6>
    kill(pids[i]);
    430a:	00001097          	auipc	ra,0x1
    430e:	5ac080e7          	jalr	1452(ra) # 58b6 <kill>
    wait(0);
    4312:	4501                	li	a0,0
    4314:	00001097          	auipc	ra,0x1
    4318:	57a080e7          	jalr	1402(ra) # 588e <wait>
    431c:	b7cd                	j	42fe <sbrkfail+0xc6>
  if(c == (char*)0xffffffffffffffffL){
    431e:	57fd                	li	a5,-1
    4320:	04f98163          	beq	s3,a5,4362 <sbrkfail+0x12a>
  pid = fork();
    4324:	00001097          	auipc	ra,0x1
    4328:	55a080e7          	jalr	1370(ra) # 587e <fork>
    432c:	84aa                	mv	s1,a0
  if(pid < 0){
    432e:	04054863          	bltz	a0,437e <sbrkfail+0x146>
  if(pid == 0){
    4332:	c525                	beqz	a0,439a <sbrkfail+0x162>
  wait(&xstatus);
    4334:	fbc40513          	addi	a0,s0,-68
    4338:	00001097          	auipc	ra,0x1
    433c:	556080e7          	jalr	1366(ra) # 588e <wait>
  if(xstatus != -1 && xstatus != 2)
    4340:	fbc42783          	lw	a5,-68(s0)
    4344:	577d                	li	a4,-1
    4346:	00e78563          	beq	a5,a4,4350 <sbrkfail+0x118>
    434a:	4709                	li	a4,2
    434c:	08e79d63          	bne	a5,a4,43e6 <sbrkfail+0x1ae>
}
    4350:	70e6                	ld	ra,120(sp)
    4352:	7446                	ld	s0,112(sp)
    4354:	74a6                	ld	s1,104(sp)
    4356:	7906                	ld	s2,96(sp)
    4358:	69e6                	ld	s3,88(sp)
    435a:	6a46                	ld	s4,80(sp)
    435c:	6aa6                	ld	s5,72(sp)
    435e:	6109                	addi	sp,sp,128
    4360:	8082                	ret
    printf("%s: failed sbrk leaked memory\n", s);
    4362:	85ca                	mv	a1,s2
    4364:	00004517          	auipc	a0,0x4
    4368:	8ec50513          	addi	a0,a0,-1812 # 7c50 <malloc+0x1f7c>
    436c:	00002097          	auipc	ra,0x2
    4370:	8aa080e7          	jalr	-1878(ra) # 5c16 <printf>
    exit(1);
    4374:	4505                	li	a0,1
    4376:	00001097          	auipc	ra,0x1
    437a:	510080e7          	jalr	1296(ra) # 5886 <exit>
    printf("%s: fork failed\n", s);
    437e:	85ca                	mv	a1,s2
    4380:	00002517          	auipc	a0,0x2
    4384:	5f850513          	addi	a0,a0,1528 # 6978 <malloc+0xca4>
    4388:	00002097          	auipc	ra,0x2
    438c:	88e080e7          	jalr	-1906(ra) # 5c16 <printf>
    exit(1);
    4390:	4505                	li	a0,1
    4392:	00001097          	auipc	ra,0x1
    4396:	4f4080e7          	jalr	1268(ra) # 5886 <exit>
    a = sbrk(0);
    439a:	4501                	li	a0,0
    439c:	00001097          	auipc	ra,0x1
    43a0:	572080e7          	jalr	1394(ra) # 590e <sbrk>
    43a4:	89aa                	mv	s3,a0
    sbrk(10*BIG);
    43a6:	3e800537          	lui	a0,0x3e800
    43aa:	00001097          	auipc	ra,0x1
    43ae:	564080e7          	jalr	1380(ra) # 590e <sbrk>
    for (i = 0; i < 10*BIG; i += PGSIZE) {
    43b2:	874e                	mv	a4,s3
    43b4:	3e8007b7          	lui	a5,0x3e800
    43b8:	97ce                	add	a5,a5,s3
    43ba:	6685                	lui	a3,0x1
      n += *(a+i);
    43bc:	00074603          	lbu	a2,0(a4)
    43c0:	9cb1                	addw	s1,s1,a2
    for (i = 0; i < 10*BIG; i += PGSIZE) {
    43c2:	9736                	add	a4,a4,a3
    43c4:	fef71ce3          	bne	a4,a5,43bc <sbrkfail+0x184>
    printf("%s: allocate a lot of memory succeeded %d\n", s, n);
    43c8:	8626                	mv	a2,s1
    43ca:	85ca                	mv	a1,s2
    43cc:	00004517          	auipc	a0,0x4
    43d0:	8a450513          	addi	a0,a0,-1884 # 7c70 <malloc+0x1f9c>
    43d4:	00002097          	auipc	ra,0x2
    43d8:	842080e7          	jalr	-1982(ra) # 5c16 <printf>
    exit(1);
    43dc:	4505                	li	a0,1
    43de:	00001097          	auipc	ra,0x1
    43e2:	4a8080e7          	jalr	1192(ra) # 5886 <exit>
    exit(1);
    43e6:	4505                	li	a0,1
    43e8:	00001097          	auipc	ra,0x1
    43ec:	49e080e7          	jalr	1182(ra) # 5886 <exit>

00000000000043f0 <mem>:
{
    43f0:	7139                	addi	sp,sp,-64
    43f2:	fc06                	sd	ra,56(sp)
    43f4:	f822                	sd	s0,48(sp)
    43f6:	f426                	sd	s1,40(sp)
    43f8:	f04a                	sd	s2,32(sp)
    43fa:	ec4e                	sd	s3,24(sp)
    43fc:	0080                	addi	s0,sp,64
    43fe:	89aa                	mv	s3,a0
  if((pid = fork()) == 0){
    4400:	00001097          	auipc	ra,0x1
    4404:	47e080e7          	jalr	1150(ra) # 587e <fork>
    m1 = 0;
    4408:	4481                	li	s1,0
    while((m2 = malloc(10001)) != 0){
    440a:	6909                	lui	s2,0x2
    440c:	71190913          	addi	s2,s2,1809 # 2711 <sbrkmuch+0x6d>
  if((pid = fork()) == 0){
    4410:	ed39                	bnez	a0,446e <mem+0x7e>
    while((m2 = malloc(10001)) != 0){
    4412:	854a                	mv	a0,s2
    4414:	00002097          	auipc	ra,0x2
    4418:	8c0080e7          	jalr	-1856(ra) # 5cd4 <malloc>
    441c:	c501                	beqz	a0,4424 <mem+0x34>
      *(char**)m2 = m1;
    441e:	e104                	sd	s1,0(a0)
      m1 = m2;
    4420:	84aa                	mv	s1,a0
    4422:	bfc5                	j	4412 <mem+0x22>
    while(m1){
    4424:	c881                	beqz	s1,4434 <mem+0x44>
      m2 = *(char**)m1;
    4426:	8526                	mv	a0,s1
    4428:	6084                	ld	s1,0(s1)
      free(m1);
    442a:	00002097          	auipc	ra,0x2
    442e:	822080e7          	jalr	-2014(ra) # 5c4c <free>
    while(m1){
    4432:	f8f5                	bnez	s1,4426 <mem+0x36>
    m1 = malloc(1024*20);
    4434:	6515                	lui	a0,0x5
    4436:	00002097          	auipc	ra,0x2
    443a:	89e080e7          	jalr	-1890(ra) # 5cd4 <malloc>
    if(m1 == 0){
    443e:	c911                	beqz	a0,4452 <mem+0x62>
    free(m1);
    4440:	00002097          	auipc	ra,0x2
    4444:	80c080e7          	jalr	-2036(ra) # 5c4c <free>
    exit(0);
    4448:	4501                	li	a0,0
    444a:	00001097          	auipc	ra,0x1
    444e:	43c080e7          	jalr	1084(ra) # 5886 <exit>
      printf("couldn't allocate mem?!!\n", s);
    4452:	85ce                	mv	a1,s3
    4454:	00004517          	auipc	a0,0x4
    4458:	84c50513          	addi	a0,a0,-1972 # 7ca0 <malloc+0x1fcc>
    445c:	00001097          	auipc	ra,0x1
    4460:	7ba080e7          	jalr	1978(ra) # 5c16 <printf>
      exit(1);
    4464:	4505                	li	a0,1
    4466:	00001097          	auipc	ra,0x1
    446a:	420080e7          	jalr	1056(ra) # 5886 <exit>
    wait(&xstatus);
    446e:	fcc40513          	addi	a0,s0,-52
    4472:	00001097          	auipc	ra,0x1
    4476:	41c080e7          	jalr	1052(ra) # 588e <wait>
    if(xstatus == -1){
    447a:	fcc42503          	lw	a0,-52(s0)
    447e:	57fd                	li	a5,-1
    4480:	00f50663          	beq	a0,a5,448c <mem+0x9c>
    exit(xstatus);
    4484:	00001097          	auipc	ra,0x1
    4488:	402080e7          	jalr	1026(ra) # 5886 <exit>
      exit(0);
    448c:	4501                	li	a0,0
    448e:	00001097          	auipc	ra,0x1
    4492:	3f8080e7          	jalr	1016(ra) # 5886 <exit>

0000000000004496 <sharedfd>:
{
    4496:	7159                	addi	sp,sp,-112
    4498:	f486                	sd	ra,104(sp)
    449a:	f0a2                	sd	s0,96(sp)
    449c:	eca6                	sd	s1,88(sp)
    449e:	e8ca                	sd	s2,80(sp)
    44a0:	e4ce                	sd	s3,72(sp)
    44a2:	e0d2                	sd	s4,64(sp)
    44a4:	fc56                	sd	s5,56(sp)
    44a6:	f85a                	sd	s6,48(sp)
    44a8:	f45e                	sd	s7,40(sp)
    44aa:	1880                	addi	s0,sp,112
    44ac:	8a2a                	mv	s4,a0
  unlink("sharedfd");
    44ae:	00002517          	auipc	a0,0x2
    44b2:	aa250513          	addi	a0,a0,-1374 # 5f50 <malloc+0x27c>
    44b6:	00001097          	auipc	ra,0x1
    44ba:	420080e7          	jalr	1056(ra) # 58d6 <unlink>
  fd = open("sharedfd", O_CREATE|O_RDWR);
    44be:	20200593          	li	a1,514
    44c2:	00002517          	auipc	a0,0x2
    44c6:	a8e50513          	addi	a0,a0,-1394 # 5f50 <malloc+0x27c>
    44ca:	00001097          	auipc	ra,0x1
    44ce:	3fc080e7          	jalr	1020(ra) # 58c6 <open>
  if(fd < 0){
    44d2:	04054a63          	bltz	a0,4526 <sharedfd+0x90>
    44d6:	892a                	mv	s2,a0
  pid = fork();
    44d8:	00001097          	auipc	ra,0x1
    44dc:	3a6080e7          	jalr	934(ra) # 587e <fork>
    44e0:	89aa                	mv	s3,a0
  memset(buf, pid==0?'c':'p', sizeof(buf));
    44e2:	06300593          	li	a1,99
    44e6:	c119                	beqz	a0,44ec <sharedfd+0x56>
    44e8:	07000593          	li	a1,112
    44ec:	4629                	li	a2,10
    44ee:	fa040513          	addi	a0,s0,-96
    44f2:	00001097          	auipc	ra,0x1
    44f6:	190080e7          	jalr	400(ra) # 5682 <memset>
    44fa:	3e800493          	li	s1,1000
    if(write(fd, buf, sizeof(buf)) != sizeof(buf)){
    44fe:	4629                	li	a2,10
    4500:	fa040593          	addi	a1,s0,-96
    4504:	854a                	mv	a0,s2
    4506:	00001097          	auipc	ra,0x1
    450a:	3a0080e7          	jalr	928(ra) # 58a6 <write>
    450e:	47a9                	li	a5,10
    4510:	02f51963          	bne	a0,a5,4542 <sharedfd+0xac>
  for(i = 0; i < N; i++){
    4514:	34fd                	addiw	s1,s1,-1
    4516:	f4e5                	bnez	s1,44fe <sharedfd+0x68>
  if(pid == 0) {
    4518:	04099363          	bnez	s3,455e <sharedfd+0xc8>
    exit(0);
    451c:	4501                	li	a0,0
    451e:	00001097          	auipc	ra,0x1
    4522:	368080e7          	jalr	872(ra) # 5886 <exit>
    printf("%s: cannot open sharedfd for writing", s);
    4526:	85d2                	mv	a1,s4
    4528:	00003517          	auipc	a0,0x3
    452c:	79850513          	addi	a0,a0,1944 # 7cc0 <malloc+0x1fec>
    4530:	00001097          	auipc	ra,0x1
    4534:	6e6080e7          	jalr	1766(ra) # 5c16 <printf>
    exit(1);
    4538:	4505                	li	a0,1
    453a:	00001097          	auipc	ra,0x1
    453e:	34c080e7          	jalr	844(ra) # 5886 <exit>
      printf("%s: write sharedfd failed\n", s);
    4542:	85d2                	mv	a1,s4
    4544:	00003517          	auipc	a0,0x3
    4548:	7a450513          	addi	a0,a0,1956 # 7ce8 <malloc+0x2014>
    454c:	00001097          	auipc	ra,0x1
    4550:	6ca080e7          	jalr	1738(ra) # 5c16 <printf>
      exit(1);
    4554:	4505                	li	a0,1
    4556:	00001097          	auipc	ra,0x1
    455a:	330080e7          	jalr	816(ra) # 5886 <exit>
    wait(&xstatus);
    455e:	f9c40513          	addi	a0,s0,-100
    4562:	00001097          	auipc	ra,0x1
    4566:	32c080e7          	jalr	812(ra) # 588e <wait>
    if(xstatus != 0)
    456a:	f9c42983          	lw	s3,-100(s0)
    456e:	00098763          	beqz	s3,457c <sharedfd+0xe6>
      exit(xstatus);
    4572:	854e                	mv	a0,s3
    4574:	00001097          	auipc	ra,0x1
    4578:	312080e7          	jalr	786(ra) # 5886 <exit>
  close(fd);
    457c:	854a                	mv	a0,s2
    457e:	00001097          	auipc	ra,0x1
    4582:	330080e7          	jalr	816(ra) # 58ae <close>
  fd = open("sharedfd", 0);
    4586:	4581                	li	a1,0
    4588:	00002517          	auipc	a0,0x2
    458c:	9c850513          	addi	a0,a0,-1592 # 5f50 <malloc+0x27c>
    4590:	00001097          	auipc	ra,0x1
    4594:	336080e7          	jalr	822(ra) # 58c6 <open>
    4598:	8baa                	mv	s7,a0
  nc = np = 0;
    459a:	8ace                	mv	s5,s3
  if(fd < 0){
    459c:	02054563          	bltz	a0,45c6 <sharedfd+0x130>
    45a0:	faa40913          	addi	s2,s0,-86
      if(buf[i] == 'c')
    45a4:	06300493          	li	s1,99
      if(buf[i] == 'p')
    45a8:	07000b13          	li	s6,112
  while((n = read(fd, buf, sizeof(buf))) > 0){
    45ac:	4629                	li	a2,10
    45ae:	fa040593          	addi	a1,s0,-96
    45b2:	855e                	mv	a0,s7
    45b4:	00001097          	auipc	ra,0x1
    45b8:	2ea080e7          	jalr	746(ra) # 589e <read>
    45bc:	02a05f63          	blez	a0,45fa <sharedfd+0x164>
    45c0:	fa040793          	addi	a5,s0,-96
    45c4:	a01d                	j	45ea <sharedfd+0x154>
    printf("%s: cannot open sharedfd for reading\n", s);
    45c6:	85d2                	mv	a1,s4
    45c8:	00003517          	auipc	a0,0x3
    45cc:	74050513          	addi	a0,a0,1856 # 7d08 <malloc+0x2034>
    45d0:	00001097          	auipc	ra,0x1
    45d4:	646080e7          	jalr	1606(ra) # 5c16 <printf>
    exit(1);
    45d8:	4505                	li	a0,1
    45da:	00001097          	auipc	ra,0x1
    45de:	2ac080e7          	jalr	684(ra) # 5886 <exit>
        nc++;
    45e2:	2985                	addiw	s3,s3,1
    for(i = 0; i < sizeof(buf); i++){
    45e4:	0785                	addi	a5,a5,1
    45e6:	fd2783e3          	beq	a5,s2,45ac <sharedfd+0x116>
      if(buf[i] == 'c')
    45ea:	0007c703          	lbu	a4,0(a5) # 3e800000 <__BSS_END__+0x3e7f11e8>
    45ee:	fe970ae3          	beq	a4,s1,45e2 <sharedfd+0x14c>
      if(buf[i] == 'p')
    45f2:	ff6719e3          	bne	a4,s6,45e4 <sharedfd+0x14e>
        np++;
    45f6:	2a85                	addiw	s5,s5,1
    45f8:	b7f5                	j	45e4 <sharedfd+0x14e>
  close(fd);
    45fa:	855e                	mv	a0,s7
    45fc:	00001097          	auipc	ra,0x1
    4600:	2b2080e7          	jalr	690(ra) # 58ae <close>
  unlink("sharedfd");
    4604:	00002517          	auipc	a0,0x2
    4608:	94c50513          	addi	a0,a0,-1716 # 5f50 <malloc+0x27c>
    460c:	00001097          	auipc	ra,0x1
    4610:	2ca080e7          	jalr	714(ra) # 58d6 <unlink>
  if(nc == N*SZ && np == N*SZ){
    4614:	6789                	lui	a5,0x2
    4616:	71078793          	addi	a5,a5,1808 # 2710 <sbrkmuch+0x6c>
    461a:	00f99763          	bne	s3,a5,4628 <sharedfd+0x192>
    461e:	6789                	lui	a5,0x2
    4620:	71078793          	addi	a5,a5,1808 # 2710 <sbrkmuch+0x6c>
    4624:	02fa8063          	beq	s5,a5,4644 <sharedfd+0x1ae>
    printf("%s: nc/np test fails\n", s);
    4628:	85d2                	mv	a1,s4
    462a:	00003517          	auipc	a0,0x3
    462e:	70650513          	addi	a0,a0,1798 # 7d30 <malloc+0x205c>
    4632:	00001097          	auipc	ra,0x1
    4636:	5e4080e7          	jalr	1508(ra) # 5c16 <printf>
    exit(1);
    463a:	4505                	li	a0,1
    463c:	00001097          	auipc	ra,0x1
    4640:	24a080e7          	jalr	586(ra) # 5886 <exit>
    exit(0);
    4644:	4501                	li	a0,0
    4646:	00001097          	auipc	ra,0x1
    464a:	240080e7          	jalr	576(ra) # 5886 <exit>

000000000000464e <fourfiles>:
{
    464e:	7171                	addi	sp,sp,-176
    4650:	f506                	sd	ra,168(sp)
    4652:	f122                	sd	s0,160(sp)
    4654:	ed26                	sd	s1,152(sp)
    4656:	e94a                	sd	s2,144(sp)
    4658:	e54e                	sd	s3,136(sp)
    465a:	e152                	sd	s4,128(sp)
    465c:	fcd6                	sd	s5,120(sp)
    465e:	f8da                	sd	s6,112(sp)
    4660:	f4de                	sd	s7,104(sp)
    4662:	f0e2                	sd	s8,96(sp)
    4664:	ece6                	sd	s9,88(sp)
    4666:	e8ea                	sd	s10,80(sp)
    4668:	e4ee                	sd	s11,72(sp)
    466a:	1900                	addi	s0,sp,176
    466c:	8caa                	mv	s9,a0
  char *names[] = { "f0", "f1", "f2", "f3" };
    466e:	00001797          	auipc	a5,0x1
    4672:	74a78793          	addi	a5,a5,1866 # 5db8 <malloc+0xe4>
    4676:	f6f43823          	sd	a5,-144(s0)
    467a:	00001797          	auipc	a5,0x1
    467e:	74678793          	addi	a5,a5,1862 # 5dc0 <malloc+0xec>
    4682:	f6f43c23          	sd	a5,-136(s0)
    4686:	00001797          	auipc	a5,0x1
    468a:	74278793          	addi	a5,a5,1858 # 5dc8 <malloc+0xf4>
    468e:	f8f43023          	sd	a5,-128(s0)
    4692:	00001797          	auipc	a5,0x1
    4696:	73e78793          	addi	a5,a5,1854 # 5dd0 <malloc+0xfc>
    469a:	f8f43423          	sd	a5,-120(s0)
  for(pi = 0; pi < NCHILD; pi++){
    469e:	f7040b93          	addi	s7,s0,-144
  char *names[] = { "f0", "f1", "f2", "f3" };
    46a2:	895e                	mv	s2,s7
  for(pi = 0; pi < NCHILD; pi++){
    46a4:	4481                	li	s1,0
    46a6:	4a11                	li	s4,4
    fname = names[pi];
    46a8:	00093983          	ld	s3,0(s2)
    unlink(fname);
    46ac:	854e                	mv	a0,s3
    46ae:	00001097          	auipc	ra,0x1
    46b2:	228080e7          	jalr	552(ra) # 58d6 <unlink>
    pid = fork();
    46b6:	00001097          	auipc	ra,0x1
    46ba:	1c8080e7          	jalr	456(ra) # 587e <fork>
    if(pid < 0){
    46be:	04054563          	bltz	a0,4708 <fourfiles+0xba>
    if(pid == 0){
    46c2:	c12d                	beqz	a0,4724 <fourfiles+0xd6>
  for(pi = 0; pi < NCHILD; pi++){
    46c4:	2485                	addiw	s1,s1,1
    46c6:	0921                	addi	s2,s2,8
    46c8:	ff4490e3          	bne	s1,s4,46a8 <fourfiles+0x5a>
    46cc:	4491                	li	s1,4
    wait(&xstatus);
    46ce:	f6c40513          	addi	a0,s0,-148
    46d2:	00001097          	auipc	ra,0x1
    46d6:	1bc080e7          	jalr	444(ra) # 588e <wait>
    if(xstatus != 0)
    46da:	f6c42503          	lw	a0,-148(s0)
    46de:	ed69                	bnez	a0,47b8 <fourfiles+0x16a>
  for(pi = 0; pi < NCHILD; pi++){
    46e0:	34fd                	addiw	s1,s1,-1
    46e2:	f4f5                	bnez	s1,46ce <fourfiles+0x80>
    46e4:	03000b13          	li	s6,48
    total = 0;
    46e8:	f4a43c23          	sd	a0,-168(s0)
    while((n = read(fd, buf, sizeof(buf))) > 0){
    46ec:	00007a17          	auipc	s4,0x7
    46f0:	71ca0a13          	addi	s4,s4,1820 # be08 <buf>
    46f4:	00007a97          	auipc	s5,0x7
    46f8:	715a8a93          	addi	s5,s5,1813 # be09 <buf+0x1>
    if(total != N*SZ){
    46fc:	6d05                	lui	s10,0x1
    46fe:	770d0d13          	addi	s10,s10,1904 # 1770 <pipe1+0x32>
  for(i = 0; i < NCHILD; i++){
    4702:	03400d93          	li	s11,52
    4706:	a23d                	j	4834 <fourfiles+0x1e6>
      printf("fork failed\n", s);
    4708:	85e6                	mv	a1,s9
    470a:	00002517          	auipc	a0,0x2
    470e:	67650513          	addi	a0,a0,1654 # 6d80 <malloc+0x10ac>
    4712:	00001097          	auipc	ra,0x1
    4716:	504080e7          	jalr	1284(ra) # 5c16 <printf>
      exit(1);
    471a:	4505                	li	a0,1
    471c:	00001097          	auipc	ra,0x1
    4720:	16a080e7          	jalr	362(ra) # 5886 <exit>
      fd = open(fname, O_CREATE | O_RDWR);
    4724:	20200593          	li	a1,514
    4728:	854e                	mv	a0,s3
    472a:	00001097          	auipc	ra,0x1
    472e:	19c080e7          	jalr	412(ra) # 58c6 <open>
    4732:	892a                	mv	s2,a0
      if(fd < 0){
    4734:	04054763          	bltz	a0,4782 <fourfiles+0x134>
      memset(buf, '0'+pi, SZ);
    4738:	1f400613          	li	a2,500
    473c:	0304859b          	addiw	a1,s1,48
    4740:	00007517          	auipc	a0,0x7
    4744:	6c850513          	addi	a0,a0,1736 # be08 <buf>
    4748:	00001097          	auipc	ra,0x1
    474c:	f3a080e7          	jalr	-198(ra) # 5682 <memset>
    4750:	44b1                	li	s1,12
        if((n = write(fd, buf, SZ)) != SZ){
    4752:	00007997          	auipc	s3,0x7
    4756:	6b698993          	addi	s3,s3,1718 # be08 <buf>
    475a:	1f400613          	li	a2,500
    475e:	85ce                	mv	a1,s3
    4760:	854a                	mv	a0,s2
    4762:	00001097          	auipc	ra,0x1
    4766:	144080e7          	jalr	324(ra) # 58a6 <write>
    476a:	85aa                	mv	a1,a0
    476c:	1f400793          	li	a5,500
    4770:	02f51763          	bne	a0,a5,479e <fourfiles+0x150>
      for(i = 0; i < N; i++){
    4774:	34fd                	addiw	s1,s1,-1
    4776:	f0f5                	bnez	s1,475a <fourfiles+0x10c>
      exit(0);
    4778:	4501                	li	a0,0
    477a:	00001097          	auipc	ra,0x1
    477e:	10c080e7          	jalr	268(ra) # 5886 <exit>
        printf("create failed\n", s);
    4782:	85e6                	mv	a1,s9
    4784:	00003517          	auipc	a0,0x3
    4788:	5c450513          	addi	a0,a0,1476 # 7d48 <malloc+0x2074>
    478c:	00001097          	auipc	ra,0x1
    4790:	48a080e7          	jalr	1162(ra) # 5c16 <printf>
        exit(1);
    4794:	4505                	li	a0,1
    4796:	00001097          	auipc	ra,0x1
    479a:	0f0080e7          	jalr	240(ra) # 5886 <exit>
          printf("write failed %d\n", n);
    479e:	00003517          	auipc	a0,0x3
    47a2:	5ba50513          	addi	a0,a0,1466 # 7d58 <malloc+0x2084>
    47a6:	00001097          	auipc	ra,0x1
    47aa:	470080e7          	jalr	1136(ra) # 5c16 <printf>
          exit(1);
    47ae:	4505                	li	a0,1
    47b0:	00001097          	auipc	ra,0x1
    47b4:	0d6080e7          	jalr	214(ra) # 5886 <exit>
      exit(xstatus);
    47b8:	00001097          	auipc	ra,0x1
    47bc:	0ce080e7          	jalr	206(ra) # 5886 <exit>
          printf("wrong char\n", s);
    47c0:	85e6                	mv	a1,s9
    47c2:	00003517          	auipc	a0,0x3
    47c6:	5ae50513          	addi	a0,a0,1454 # 7d70 <malloc+0x209c>
    47ca:	00001097          	auipc	ra,0x1
    47ce:	44c080e7          	jalr	1100(ra) # 5c16 <printf>
          exit(1);
    47d2:	4505                	li	a0,1
    47d4:	00001097          	auipc	ra,0x1
    47d8:	0b2080e7          	jalr	178(ra) # 5886 <exit>
      total += n;
    47dc:	00a9093b          	addw	s2,s2,a0
    while((n = read(fd, buf, sizeof(buf))) > 0){
    47e0:	660d                	lui	a2,0x3
    47e2:	85d2                	mv	a1,s4
    47e4:	854e                	mv	a0,s3
    47e6:	00001097          	auipc	ra,0x1
    47ea:	0b8080e7          	jalr	184(ra) # 589e <read>
    47ee:	02a05363          	blez	a0,4814 <fourfiles+0x1c6>
    47f2:	00007797          	auipc	a5,0x7
    47f6:	61678793          	addi	a5,a5,1558 # be08 <buf>
    47fa:	fff5069b          	addiw	a3,a0,-1
    47fe:	1682                	slli	a3,a3,0x20
    4800:	9281                	srli	a3,a3,0x20
    4802:	96d6                	add	a3,a3,s5
        if(buf[j] != '0'+i){
    4804:	0007c703          	lbu	a4,0(a5)
    4808:	fa971ce3          	bne	a4,s1,47c0 <fourfiles+0x172>
      for(j = 0; j < n; j++){
    480c:	0785                	addi	a5,a5,1
    480e:	fed79be3          	bne	a5,a3,4804 <fourfiles+0x1b6>
    4812:	b7e9                	j	47dc <fourfiles+0x18e>
    close(fd);
    4814:	854e                	mv	a0,s3
    4816:	00001097          	auipc	ra,0x1
    481a:	098080e7          	jalr	152(ra) # 58ae <close>
    if(total != N*SZ){
    481e:	03a91963          	bne	s2,s10,4850 <fourfiles+0x202>
    unlink(fname);
    4822:	8562                	mv	a0,s8
    4824:	00001097          	auipc	ra,0x1
    4828:	0b2080e7          	jalr	178(ra) # 58d6 <unlink>
  for(i = 0; i < NCHILD; i++){
    482c:	0ba1                	addi	s7,s7,8
    482e:	2b05                	addiw	s6,s6,1
    4830:	03bb0e63          	beq	s6,s11,486c <fourfiles+0x21e>
    fname = names[i];
    4834:	000bbc03          	ld	s8,0(s7)
    fd = open(fname, 0);
    4838:	4581                	li	a1,0
    483a:	8562                	mv	a0,s8
    483c:	00001097          	auipc	ra,0x1
    4840:	08a080e7          	jalr	138(ra) # 58c6 <open>
    4844:	89aa                	mv	s3,a0
    total = 0;
    4846:	f5843903          	ld	s2,-168(s0)
        if(buf[j] != '0'+i){
    484a:	000b049b          	sext.w	s1,s6
    while((n = read(fd, buf, sizeof(buf))) > 0){
    484e:	bf49                	j	47e0 <fourfiles+0x192>
      printf("wrong length %d\n", total);
    4850:	85ca                	mv	a1,s2
    4852:	00003517          	auipc	a0,0x3
    4856:	52e50513          	addi	a0,a0,1326 # 7d80 <malloc+0x20ac>
    485a:	00001097          	auipc	ra,0x1
    485e:	3bc080e7          	jalr	956(ra) # 5c16 <printf>
      exit(1);
    4862:	4505                	li	a0,1
    4864:	00001097          	auipc	ra,0x1
    4868:	022080e7          	jalr	34(ra) # 5886 <exit>
}
    486c:	70aa                	ld	ra,168(sp)
    486e:	740a                	ld	s0,160(sp)
    4870:	64ea                	ld	s1,152(sp)
    4872:	694a                	ld	s2,144(sp)
    4874:	69aa                	ld	s3,136(sp)
    4876:	6a0a                	ld	s4,128(sp)
    4878:	7ae6                	ld	s5,120(sp)
    487a:	7b46                	ld	s6,112(sp)
    487c:	7ba6                	ld	s7,104(sp)
    487e:	7c06                	ld	s8,96(sp)
    4880:	6ce6                	ld	s9,88(sp)
    4882:	6d46                	ld	s10,80(sp)
    4884:	6da6                	ld	s11,72(sp)
    4886:	614d                	addi	sp,sp,176
    4888:	8082                	ret

000000000000488a <concreate>:
{
    488a:	7135                	addi	sp,sp,-160
    488c:	ed06                	sd	ra,152(sp)
    488e:	e922                	sd	s0,144(sp)
    4890:	e526                	sd	s1,136(sp)
    4892:	e14a                	sd	s2,128(sp)
    4894:	fcce                	sd	s3,120(sp)
    4896:	f8d2                	sd	s4,112(sp)
    4898:	f4d6                	sd	s5,104(sp)
    489a:	f0da                	sd	s6,96(sp)
    489c:	ecde                	sd	s7,88(sp)
    489e:	1100                	addi	s0,sp,160
    48a0:	89aa                	mv	s3,a0
  file[0] = 'C';
    48a2:	04300793          	li	a5,67
    48a6:	faf40423          	sb	a5,-88(s0)
  file[2] = '\0';
    48aa:	fa040523          	sb	zero,-86(s0)
  for(i = 0; i < N; i++){
    48ae:	4901                	li	s2,0
    if(pid && (i % 3) == 1){
    48b0:	4b0d                	li	s6,3
    48b2:	4a85                	li	s5,1
      link("C0", file);
    48b4:	00003b97          	auipc	s7,0x3
    48b8:	4e4b8b93          	addi	s7,s7,1252 # 7d98 <malloc+0x20c4>
  for(i = 0; i < N; i++){
    48bc:	02800a13          	li	s4,40
    48c0:	acc1                	j	4b90 <concreate+0x306>
      link("C0", file);
    48c2:	fa840593          	addi	a1,s0,-88
    48c6:	855e                	mv	a0,s7
    48c8:	00001097          	auipc	ra,0x1
    48cc:	01e080e7          	jalr	30(ra) # 58e6 <link>
    if(pid == 0) {
    48d0:	a45d                	j	4b76 <concreate+0x2ec>
    } else if(pid == 0 && (i % 5) == 1){
    48d2:	4795                	li	a5,5
    48d4:	02f9693b          	remw	s2,s2,a5
    48d8:	4785                	li	a5,1
    48da:	02f90b63          	beq	s2,a5,4910 <concreate+0x86>
      fd = open(file, O_CREATE | O_RDWR);
    48de:	20200593          	li	a1,514
    48e2:	fa840513          	addi	a0,s0,-88
    48e6:	00001097          	auipc	ra,0x1
    48ea:	fe0080e7          	jalr	-32(ra) # 58c6 <open>
      if(fd < 0){
    48ee:	26055b63          	bgez	a0,4b64 <concreate+0x2da>
        printf("concreate create %s failed\n", file);
    48f2:	fa840593          	addi	a1,s0,-88
    48f6:	00003517          	auipc	a0,0x3
    48fa:	4aa50513          	addi	a0,a0,1194 # 7da0 <malloc+0x20cc>
    48fe:	00001097          	auipc	ra,0x1
    4902:	318080e7          	jalr	792(ra) # 5c16 <printf>
        exit(1);
    4906:	4505                	li	a0,1
    4908:	00001097          	auipc	ra,0x1
    490c:	f7e080e7          	jalr	-130(ra) # 5886 <exit>
      link("C0", file);
    4910:	fa840593          	addi	a1,s0,-88
    4914:	00003517          	auipc	a0,0x3
    4918:	48450513          	addi	a0,a0,1156 # 7d98 <malloc+0x20c4>
    491c:	00001097          	auipc	ra,0x1
    4920:	fca080e7          	jalr	-54(ra) # 58e6 <link>
      exit(0);
    4924:	4501                	li	a0,0
    4926:	00001097          	auipc	ra,0x1
    492a:	f60080e7          	jalr	-160(ra) # 5886 <exit>
        exit(1);
    492e:	4505                	li	a0,1
    4930:	00001097          	auipc	ra,0x1
    4934:	f56080e7          	jalr	-170(ra) # 5886 <exit>
  memset(fa, 0, sizeof(fa));
    4938:	02800613          	li	a2,40
    493c:	4581                	li	a1,0
    493e:	f8040513          	addi	a0,s0,-128
    4942:	00001097          	auipc	ra,0x1
    4946:	d40080e7          	jalr	-704(ra) # 5682 <memset>
  fd = open(".", 0);
    494a:	4581                	li	a1,0
    494c:	00002517          	auipc	a0,0x2
    4950:	e8c50513          	addi	a0,a0,-372 # 67d8 <malloc+0xb04>
    4954:	00001097          	auipc	ra,0x1
    4958:	f72080e7          	jalr	-142(ra) # 58c6 <open>
    495c:	892a                	mv	s2,a0
  n = 0;
    495e:	8aa6                	mv	s5,s1
    if(de.name[0] == 'C' && de.name[2] == '\0'){
    4960:	04300a13          	li	s4,67
      if(i < 0 || i >= sizeof(fa)){
    4964:	02700b13          	li	s6,39
      fa[i] = 1;
    4968:	4b85                	li	s7,1
  while(read(fd, &de, sizeof(de)) > 0){
    496a:	a03d                	j	4998 <concreate+0x10e>
        printf("%s: concreate weird file %s\n", s, de.name);
    496c:	f7240613          	addi	a2,s0,-142
    4970:	85ce                	mv	a1,s3
    4972:	00003517          	auipc	a0,0x3
    4976:	44e50513          	addi	a0,a0,1102 # 7dc0 <malloc+0x20ec>
    497a:	00001097          	auipc	ra,0x1
    497e:	29c080e7          	jalr	668(ra) # 5c16 <printf>
        exit(1);
    4982:	4505                	li	a0,1
    4984:	00001097          	auipc	ra,0x1
    4988:	f02080e7          	jalr	-254(ra) # 5886 <exit>
      fa[i] = 1;
    498c:	fb040793          	addi	a5,s0,-80
    4990:	973e                	add	a4,a4,a5
    4992:	fd770823          	sb	s7,-48(a4)
      n++;
    4996:	2a85                	addiw	s5,s5,1
  while(read(fd, &de, sizeof(de)) > 0){
    4998:	4641                	li	a2,16
    499a:	f7040593          	addi	a1,s0,-144
    499e:	854a                	mv	a0,s2
    49a0:	00001097          	auipc	ra,0x1
    49a4:	efe080e7          	jalr	-258(ra) # 589e <read>
    49a8:	04a05a63          	blez	a0,49fc <concreate+0x172>
    if(de.inum == 0)
    49ac:	f7045783          	lhu	a5,-144(s0)
    49b0:	d7e5                	beqz	a5,4998 <concreate+0x10e>
    if(de.name[0] == 'C' && de.name[2] == '\0'){
    49b2:	f7244783          	lbu	a5,-142(s0)
    49b6:	ff4791e3          	bne	a5,s4,4998 <concreate+0x10e>
    49ba:	f7444783          	lbu	a5,-140(s0)
    49be:	ffe9                	bnez	a5,4998 <concreate+0x10e>
      i = de.name[1] - '0';
    49c0:	f7344783          	lbu	a5,-141(s0)
    49c4:	fd07879b          	addiw	a5,a5,-48
    49c8:	0007871b          	sext.w	a4,a5
      if(i < 0 || i >= sizeof(fa)){
    49cc:	faeb60e3          	bltu	s6,a4,496c <concreate+0xe2>
      if(fa[i]){
    49d0:	fb040793          	addi	a5,s0,-80
    49d4:	97ba                	add	a5,a5,a4
    49d6:	fd07c783          	lbu	a5,-48(a5)
    49da:	dbcd                	beqz	a5,498c <concreate+0x102>
        printf("%s: concreate duplicate file %s\n", s, de.name);
    49dc:	f7240613          	addi	a2,s0,-142
    49e0:	85ce                	mv	a1,s3
    49e2:	00003517          	auipc	a0,0x3
    49e6:	3fe50513          	addi	a0,a0,1022 # 7de0 <malloc+0x210c>
    49ea:	00001097          	auipc	ra,0x1
    49ee:	22c080e7          	jalr	556(ra) # 5c16 <printf>
        exit(1);
    49f2:	4505                	li	a0,1
    49f4:	00001097          	auipc	ra,0x1
    49f8:	e92080e7          	jalr	-366(ra) # 5886 <exit>
  close(fd);
    49fc:	854a                	mv	a0,s2
    49fe:	00001097          	auipc	ra,0x1
    4a02:	eb0080e7          	jalr	-336(ra) # 58ae <close>
  if(n != N){
    4a06:	02800793          	li	a5,40
    4a0a:	00fa9763          	bne	s5,a5,4a18 <concreate+0x18e>
    if(((i % 3) == 0 && pid == 0) ||
    4a0e:	4a8d                	li	s5,3
    4a10:	4b05                	li	s6,1
  for(i = 0; i < N; i++){
    4a12:	02800a13          	li	s4,40
    4a16:	a8c9                	j	4ae8 <concreate+0x25e>
    printf("%s: concreate not enough files in directory listing\n", s);
    4a18:	85ce                	mv	a1,s3
    4a1a:	00003517          	auipc	a0,0x3
    4a1e:	3ee50513          	addi	a0,a0,1006 # 7e08 <malloc+0x2134>
    4a22:	00001097          	auipc	ra,0x1
    4a26:	1f4080e7          	jalr	500(ra) # 5c16 <printf>
    exit(1);
    4a2a:	4505                	li	a0,1
    4a2c:	00001097          	auipc	ra,0x1
    4a30:	e5a080e7          	jalr	-422(ra) # 5886 <exit>
      printf("%s: fork failed\n", s);
    4a34:	85ce                	mv	a1,s3
    4a36:	00002517          	auipc	a0,0x2
    4a3a:	f4250513          	addi	a0,a0,-190 # 6978 <malloc+0xca4>
    4a3e:	00001097          	auipc	ra,0x1
    4a42:	1d8080e7          	jalr	472(ra) # 5c16 <printf>
      exit(1);
    4a46:	4505                	li	a0,1
    4a48:	00001097          	auipc	ra,0x1
    4a4c:	e3e080e7          	jalr	-450(ra) # 5886 <exit>
      close(open(file, 0));
    4a50:	4581                	li	a1,0
    4a52:	fa840513          	addi	a0,s0,-88
    4a56:	00001097          	auipc	ra,0x1
    4a5a:	e70080e7          	jalr	-400(ra) # 58c6 <open>
    4a5e:	00001097          	auipc	ra,0x1
    4a62:	e50080e7          	jalr	-432(ra) # 58ae <close>
      close(open(file, 0));
    4a66:	4581                	li	a1,0
    4a68:	fa840513          	addi	a0,s0,-88
    4a6c:	00001097          	auipc	ra,0x1
    4a70:	e5a080e7          	jalr	-422(ra) # 58c6 <open>
    4a74:	00001097          	auipc	ra,0x1
    4a78:	e3a080e7          	jalr	-454(ra) # 58ae <close>
      close(open(file, 0));
    4a7c:	4581                	li	a1,0
    4a7e:	fa840513          	addi	a0,s0,-88
    4a82:	00001097          	auipc	ra,0x1
    4a86:	e44080e7          	jalr	-444(ra) # 58c6 <open>
    4a8a:	00001097          	auipc	ra,0x1
    4a8e:	e24080e7          	jalr	-476(ra) # 58ae <close>
      close(open(file, 0));
    4a92:	4581                	li	a1,0
    4a94:	fa840513          	addi	a0,s0,-88
    4a98:	00001097          	auipc	ra,0x1
    4a9c:	e2e080e7          	jalr	-466(ra) # 58c6 <open>
    4aa0:	00001097          	auipc	ra,0x1
    4aa4:	e0e080e7          	jalr	-498(ra) # 58ae <close>
      close(open(file, 0));
    4aa8:	4581                	li	a1,0
    4aaa:	fa840513          	addi	a0,s0,-88
    4aae:	00001097          	auipc	ra,0x1
    4ab2:	e18080e7          	jalr	-488(ra) # 58c6 <open>
    4ab6:	00001097          	auipc	ra,0x1
    4aba:	df8080e7          	jalr	-520(ra) # 58ae <close>
      close(open(file, 0));
    4abe:	4581                	li	a1,0
    4ac0:	fa840513          	addi	a0,s0,-88
    4ac4:	00001097          	auipc	ra,0x1
    4ac8:	e02080e7          	jalr	-510(ra) # 58c6 <open>
    4acc:	00001097          	auipc	ra,0x1
    4ad0:	de2080e7          	jalr	-542(ra) # 58ae <close>
    if(pid == 0)
    4ad4:	08090363          	beqz	s2,4b5a <concreate+0x2d0>
      wait(0);
    4ad8:	4501                	li	a0,0
    4ada:	00001097          	auipc	ra,0x1
    4ade:	db4080e7          	jalr	-588(ra) # 588e <wait>
  for(i = 0; i < N; i++){
    4ae2:	2485                	addiw	s1,s1,1
    4ae4:	0f448563          	beq	s1,s4,4bce <concreate+0x344>
    file[1] = '0' + i;
    4ae8:	0304879b          	addiw	a5,s1,48
    4aec:	faf404a3          	sb	a5,-87(s0)
    pid = fork();
    4af0:	00001097          	auipc	ra,0x1
    4af4:	d8e080e7          	jalr	-626(ra) # 587e <fork>
    4af8:	892a                	mv	s2,a0
    if(pid < 0){
    4afa:	f2054de3          	bltz	a0,4a34 <concreate+0x1aa>
    if(((i % 3) == 0 && pid == 0) ||
    4afe:	0354e73b          	remw	a4,s1,s5
    4b02:	00a767b3          	or	a5,a4,a0
    4b06:	2781                	sext.w	a5,a5
    4b08:	d7a1                	beqz	a5,4a50 <concreate+0x1c6>
    4b0a:	01671363          	bne	a4,s6,4b10 <concreate+0x286>
       ((i % 3) == 1 && pid != 0)){
    4b0e:	f129                	bnez	a0,4a50 <concreate+0x1c6>
      unlink(file);
    4b10:	fa840513          	addi	a0,s0,-88
    4b14:	00001097          	auipc	ra,0x1
    4b18:	dc2080e7          	jalr	-574(ra) # 58d6 <unlink>
      unlink(file);
    4b1c:	fa840513          	addi	a0,s0,-88
    4b20:	00001097          	auipc	ra,0x1
    4b24:	db6080e7          	jalr	-586(ra) # 58d6 <unlink>
      unlink(file);
    4b28:	fa840513          	addi	a0,s0,-88
    4b2c:	00001097          	auipc	ra,0x1
    4b30:	daa080e7          	jalr	-598(ra) # 58d6 <unlink>
      unlink(file);
    4b34:	fa840513          	addi	a0,s0,-88
    4b38:	00001097          	auipc	ra,0x1
    4b3c:	d9e080e7          	jalr	-610(ra) # 58d6 <unlink>
      unlink(file);
    4b40:	fa840513          	addi	a0,s0,-88
    4b44:	00001097          	auipc	ra,0x1
    4b48:	d92080e7          	jalr	-622(ra) # 58d6 <unlink>
      unlink(file);
    4b4c:	fa840513          	addi	a0,s0,-88
    4b50:	00001097          	auipc	ra,0x1
    4b54:	d86080e7          	jalr	-634(ra) # 58d6 <unlink>
    4b58:	bfb5                	j	4ad4 <concreate+0x24a>
      exit(0);
    4b5a:	4501                	li	a0,0
    4b5c:	00001097          	auipc	ra,0x1
    4b60:	d2a080e7          	jalr	-726(ra) # 5886 <exit>
      close(fd);
    4b64:	00001097          	auipc	ra,0x1
    4b68:	d4a080e7          	jalr	-694(ra) # 58ae <close>
    if(pid == 0) {
    4b6c:	bb65                	j	4924 <concreate+0x9a>
      close(fd);
    4b6e:	00001097          	auipc	ra,0x1
    4b72:	d40080e7          	jalr	-704(ra) # 58ae <close>
      wait(&xstatus);
    4b76:	f6c40513          	addi	a0,s0,-148
    4b7a:	00001097          	auipc	ra,0x1
    4b7e:	d14080e7          	jalr	-748(ra) # 588e <wait>
      if(xstatus != 0)
    4b82:	f6c42483          	lw	s1,-148(s0)
    4b86:	da0494e3          	bnez	s1,492e <concreate+0xa4>
  for(i = 0; i < N; i++){
    4b8a:	2905                	addiw	s2,s2,1
    4b8c:	db4906e3          	beq	s2,s4,4938 <concreate+0xae>
    file[1] = '0' + i;
    4b90:	0309079b          	addiw	a5,s2,48
    4b94:	faf404a3          	sb	a5,-87(s0)
    unlink(file);
    4b98:	fa840513          	addi	a0,s0,-88
    4b9c:	00001097          	auipc	ra,0x1
    4ba0:	d3a080e7          	jalr	-710(ra) # 58d6 <unlink>
    pid = fork();
    4ba4:	00001097          	auipc	ra,0x1
    4ba8:	cda080e7          	jalr	-806(ra) # 587e <fork>
    if(pid && (i % 3) == 1){
    4bac:	d20503e3          	beqz	a0,48d2 <concreate+0x48>
    4bb0:	036967bb          	remw	a5,s2,s6
    4bb4:	d15787e3          	beq	a5,s5,48c2 <concreate+0x38>
      fd = open(file, O_CREATE | O_RDWR);
    4bb8:	20200593          	li	a1,514
    4bbc:	fa840513          	addi	a0,s0,-88
    4bc0:	00001097          	auipc	ra,0x1
    4bc4:	d06080e7          	jalr	-762(ra) # 58c6 <open>
      if(fd < 0){
    4bc8:	fa0553e3          	bgez	a0,4b6e <concreate+0x2e4>
    4bcc:	b31d                	j	48f2 <concreate+0x68>
}
    4bce:	60ea                	ld	ra,152(sp)
    4bd0:	644a                	ld	s0,144(sp)
    4bd2:	64aa                	ld	s1,136(sp)
    4bd4:	690a                	ld	s2,128(sp)
    4bd6:	79e6                	ld	s3,120(sp)
    4bd8:	7a46                	ld	s4,112(sp)
    4bda:	7aa6                	ld	s5,104(sp)
    4bdc:	7b06                	ld	s6,96(sp)
    4bde:	6be6                	ld	s7,88(sp)
    4be0:	610d                	addi	sp,sp,160
    4be2:	8082                	ret

0000000000004be4 <bigfile>:
{
    4be4:	7139                	addi	sp,sp,-64
    4be6:	fc06                	sd	ra,56(sp)
    4be8:	f822                	sd	s0,48(sp)
    4bea:	f426                	sd	s1,40(sp)
    4bec:	f04a                	sd	s2,32(sp)
    4bee:	ec4e                	sd	s3,24(sp)
    4bf0:	e852                	sd	s4,16(sp)
    4bf2:	e456                	sd	s5,8(sp)
    4bf4:	0080                	addi	s0,sp,64
    4bf6:	8aaa                	mv	s5,a0
  unlink("bigfile.dat");
    4bf8:	00003517          	auipc	a0,0x3
    4bfc:	24850513          	addi	a0,a0,584 # 7e40 <malloc+0x216c>
    4c00:	00001097          	auipc	ra,0x1
    4c04:	cd6080e7          	jalr	-810(ra) # 58d6 <unlink>
  fd = open("bigfile.dat", O_CREATE | O_RDWR);
    4c08:	20200593          	li	a1,514
    4c0c:	00003517          	auipc	a0,0x3
    4c10:	23450513          	addi	a0,a0,564 # 7e40 <malloc+0x216c>
    4c14:	00001097          	auipc	ra,0x1
    4c18:	cb2080e7          	jalr	-846(ra) # 58c6 <open>
    4c1c:	89aa                	mv	s3,a0
  for(i = 0; i < N; i++){
    4c1e:	4481                	li	s1,0
    memset(buf, i, SZ);
    4c20:	00007917          	auipc	s2,0x7
    4c24:	1e890913          	addi	s2,s2,488 # be08 <buf>
  for(i = 0; i < N; i++){
    4c28:	4a51                	li	s4,20
  if(fd < 0){
    4c2a:	0a054063          	bltz	a0,4cca <bigfile+0xe6>
    memset(buf, i, SZ);
    4c2e:	25800613          	li	a2,600
    4c32:	85a6                	mv	a1,s1
    4c34:	854a                	mv	a0,s2
    4c36:	00001097          	auipc	ra,0x1
    4c3a:	a4c080e7          	jalr	-1460(ra) # 5682 <memset>
    if(write(fd, buf, SZ) != SZ){
    4c3e:	25800613          	li	a2,600
    4c42:	85ca                	mv	a1,s2
    4c44:	854e                	mv	a0,s3
    4c46:	00001097          	auipc	ra,0x1
    4c4a:	c60080e7          	jalr	-928(ra) # 58a6 <write>
    4c4e:	25800793          	li	a5,600
    4c52:	08f51a63          	bne	a0,a5,4ce6 <bigfile+0x102>
  for(i = 0; i < N; i++){
    4c56:	2485                	addiw	s1,s1,1
    4c58:	fd449be3          	bne	s1,s4,4c2e <bigfile+0x4a>
  close(fd);
    4c5c:	854e                	mv	a0,s3
    4c5e:	00001097          	auipc	ra,0x1
    4c62:	c50080e7          	jalr	-944(ra) # 58ae <close>
  fd = open("bigfile.dat", 0);
    4c66:	4581                	li	a1,0
    4c68:	00003517          	auipc	a0,0x3
    4c6c:	1d850513          	addi	a0,a0,472 # 7e40 <malloc+0x216c>
    4c70:	00001097          	auipc	ra,0x1
    4c74:	c56080e7          	jalr	-938(ra) # 58c6 <open>
    4c78:	8a2a                	mv	s4,a0
  total = 0;
    4c7a:	4981                	li	s3,0
  for(i = 0; ; i++){
    4c7c:	4481                	li	s1,0
    cc = read(fd, buf, SZ/2);
    4c7e:	00007917          	auipc	s2,0x7
    4c82:	18a90913          	addi	s2,s2,394 # be08 <buf>
  if(fd < 0){
    4c86:	06054e63          	bltz	a0,4d02 <bigfile+0x11e>
    cc = read(fd, buf, SZ/2);
    4c8a:	12c00613          	li	a2,300
    4c8e:	85ca                	mv	a1,s2
    4c90:	8552                	mv	a0,s4
    4c92:	00001097          	auipc	ra,0x1
    4c96:	c0c080e7          	jalr	-1012(ra) # 589e <read>
    if(cc < 0){
    4c9a:	08054263          	bltz	a0,4d1e <bigfile+0x13a>
    if(cc == 0)
    4c9e:	c971                	beqz	a0,4d72 <bigfile+0x18e>
    if(cc != SZ/2){
    4ca0:	12c00793          	li	a5,300
    4ca4:	08f51b63          	bne	a0,a5,4d3a <bigfile+0x156>
    if(buf[0] != i/2 || buf[SZ/2-1] != i/2){
    4ca8:	01f4d79b          	srliw	a5,s1,0x1f
    4cac:	9fa5                	addw	a5,a5,s1
    4cae:	4017d79b          	sraiw	a5,a5,0x1
    4cb2:	00094703          	lbu	a4,0(s2)
    4cb6:	0af71063          	bne	a4,a5,4d56 <bigfile+0x172>
    4cba:	12b94703          	lbu	a4,299(s2)
    4cbe:	08f71c63          	bne	a4,a5,4d56 <bigfile+0x172>
    total += cc;
    4cc2:	12c9899b          	addiw	s3,s3,300
  for(i = 0; ; i++){
    4cc6:	2485                	addiw	s1,s1,1
    cc = read(fd, buf, SZ/2);
    4cc8:	b7c9                	j	4c8a <bigfile+0xa6>
    printf("%s: cannot create bigfile", s);
    4cca:	85d6                	mv	a1,s5
    4ccc:	00003517          	auipc	a0,0x3
    4cd0:	18450513          	addi	a0,a0,388 # 7e50 <malloc+0x217c>
    4cd4:	00001097          	auipc	ra,0x1
    4cd8:	f42080e7          	jalr	-190(ra) # 5c16 <printf>
    exit(1);
    4cdc:	4505                	li	a0,1
    4cde:	00001097          	auipc	ra,0x1
    4ce2:	ba8080e7          	jalr	-1112(ra) # 5886 <exit>
      printf("%s: write bigfile failed\n", s);
    4ce6:	85d6                	mv	a1,s5
    4ce8:	00003517          	auipc	a0,0x3
    4cec:	18850513          	addi	a0,a0,392 # 7e70 <malloc+0x219c>
    4cf0:	00001097          	auipc	ra,0x1
    4cf4:	f26080e7          	jalr	-218(ra) # 5c16 <printf>
      exit(1);
    4cf8:	4505                	li	a0,1
    4cfa:	00001097          	auipc	ra,0x1
    4cfe:	b8c080e7          	jalr	-1140(ra) # 5886 <exit>
    printf("%s: cannot open bigfile\n", s);
    4d02:	85d6                	mv	a1,s5
    4d04:	00003517          	auipc	a0,0x3
    4d08:	18c50513          	addi	a0,a0,396 # 7e90 <malloc+0x21bc>
    4d0c:	00001097          	auipc	ra,0x1
    4d10:	f0a080e7          	jalr	-246(ra) # 5c16 <printf>
    exit(1);
    4d14:	4505                	li	a0,1
    4d16:	00001097          	auipc	ra,0x1
    4d1a:	b70080e7          	jalr	-1168(ra) # 5886 <exit>
      printf("%s: read bigfile failed\n", s);
    4d1e:	85d6                	mv	a1,s5
    4d20:	00003517          	auipc	a0,0x3
    4d24:	19050513          	addi	a0,a0,400 # 7eb0 <malloc+0x21dc>
    4d28:	00001097          	auipc	ra,0x1
    4d2c:	eee080e7          	jalr	-274(ra) # 5c16 <printf>
      exit(1);
    4d30:	4505                	li	a0,1
    4d32:	00001097          	auipc	ra,0x1
    4d36:	b54080e7          	jalr	-1196(ra) # 5886 <exit>
      printf("%s: short read bigfile\n", s);
    4d3a:	85d6                	mv	a1,s5
    4d3c:	00003517          	auipc	a0,0x3
    4d40:	19450513          	addi	a0,a0,404 # 7ed0 <malloc+0x21fc>
    4d44:	00001097          	auipc	ra,0x1
    4d48:	ed2080e7          	jalr	-302(ra) # 5c16 <printf>
      exit(1);
    4d4c:	4505                	li	a0,1
    4d4e:	00001097          	auipc	ra,0x1
    4d52:	b38080e7          	jalr	-1224(ra) # 5886 <exit>
      printf("%s: read bigfile wrong data\n", s);
    4d56:	85d6                	mv	a1,s5
    4d58:	00003517          	auipc	a0,0x3
    4d5c:	19050513          	addi	a0,a0,400 # 7ee8 <malloc+0x2214>
    4d60:	00001097          	auipc	ra,0x1
    4d64:	eb6080e7          	jalr	-330(ra) # 5c16 <printf>
      exit(1);
    4d68:	4505                	li	a0,1
    4d6a:	00001097          	auipc	ra,0x1
    4d6e:	b1c080e7          	jalr	-1252(ra) # 5886 <exit>
  close(fd);
    4d72:	8552                	mv	a0,s4
    4d74:	00001097          	auipc	ra,0x1
    4d78:	b3a080e7          	jalr	-1222(ra) # 58ae <close>
  if(total != N*SZ){
    4d7c:	678d                	lui	a5,0x3
    4d7e:	ee078793          	addi	a5,a5,-288 # 2ee0 <iputtest+0xae>
    4d82:	02f99363          	bne	s3,a5,4da8 <bigfile+0x1c4>
  unlink("bigfile.dat");
    4d86:	00003517          	auipc	a0,0x3
    4d8a:	0ba50513          	addi	a0,a0,186 # 7e40 <malloc+0x216c>
    4d8e:	00001097          	auipc	ra,0x1
    4d92:	b48080e7          	jalr	-1208(ra) # 58d6 <unlink>
}
    4d96:	70e2                	ld	ra,56(sp)
    4d98:	7442                	ld	s0,48(sp)
    4d9a:	74a2                	ld	s1,40(sp)
    4d9c:	7902                	ld	s2,32(sp)
    4d9e:	69e2                	ld	s3,24(sp)
    4da0:	6a42                	ld	s4,16(sp)
    4da2:	6aa2                	ld	s5,8(sp)
    4da4:	6121                	addi	sp,sp,64
    4da6:	8082                	ret
    printf("%s: read bigfile wrong total\n", s);
    4da8:	85d6                	mv	a1,s5
    4daa:	00003517          	auipc	a0,0x3
    4dae:	15e50513          	addi	a0,a0,350 # 7f08 <malloc+0x2234>
    4db2:	00001097          	auipc	ra,0x1
    4db6:	e64080e7          	jalr	-412(ra) # 5c16 <printf>
    exit(1);
    4dba:	4505                	li	a0,1
    4dbc:	00001097          	auipc	ra,0x1
    4dc0:	aca080e7          	jalr	-1334(ra) # 5886 <exit>

0000000000004dc4 <manywrites>:
{
    4dc4:	711d                	addi	sp,sp,-96
    4dc6:	ec86                	sd	ra,88(sp)
    4dc8:	e8a2                	sd	s0,80(sp)
    4dca:	e4a6                	sd	s1,72(sp)
    4dcc:	e0ca                	sd	s2,64(sp)
    4dce:	fc4e                	sd	s3,56(sp)
    4dd0:	f852                	sd	s4,48(sp)
    4dd2:	f456                	sd	s5,40(sp)
    4dd4:	f05a                	sd	s6,32(sp)
    4dd6:	ec5e                	sd	s7,24(sp)
    4dd8:	1080                	addi	s0,sp,96
    4dda:	8aaa                	mv	s5,a0
  for(int ci = 0; ci < nchildren; ci++){
    4ddc:	4901                	li	s2,0
    4dde:	4991                	li	s3,4
    int pid = fork();
    4de0:	00001097          	auipc	ra,0x1
    4de4:	a9e080e7          	jalr	-1378(ra) # 587e <fork>
    4de8:	84aa                	mv	s1,a0
    if(pid < 0){
    4dea:	02054963          	bltz	a0,4e1c <manywrites+0x58>
    if(pid == 0){
    4dee:	c521                	beqz	a0,4e36 <manywrites+0x72>
  for(int ci = 0; ci < nchildren; ci++){
    4df0:	2905                	addiw	s2,s2,1
    4df2:	ff3917e3          	bne	s2,s3,4de0 <manywrites+0x1c>
    4df6:	4491                	li	s1,4
    int st = 0;
    4df8:	fa042423          	sw	zero,-88(s0)
    wait(&st);
    4dfc:	fa840513          	addi	a0,s0,-88
    4e00:	00001097          	auipc	ra,0x1
    4e04:	a8e080e7          	jalr	-1394(ra) # 588e <wait>
    if(st != 0)
    4e08:	fa842503          	lw	a0,-88(s0)
    4e0c:	ed6d                	bnez	a0,4f06 <manywrites+0x142>
  for(int ci = 0; ci < nchildren; ci++){
    4e0e:	34fd                	addiw	s1,s1,-1
    4e10:	f4e5                	bnez	s1,4df8 <manywrites+0x34>
  exit(0);
    4e12:	4501                	li	a0,0
    4e14:	00001097          	auipc	ra,0x1
    4e18:	a72080e7          	jalr	-1422(ra) # 5886 <exit>
      printf("fork failed\n");
    4e1c:	00002517          	auipc	a0,0x2
    4e20:	f6450513          	addi	a0,a0,-156 # 6d80 <malloc+0x10ac>
    4e24:	00001097          	auipc	ra,0x1
    4e28:	df2080e7          	jalr	-526(ra) # 5c16 <printf>
      exit(1);
    4e2c:	4505                	li	a0,1
    4e2e:	00001097          	auipc	ra,0x1
    4e32:	a58080e7          	jalr	-1448(ra) # 5886 <exit>
      name[0] = 'b';
    4e36:	06200793          	li	a5,98
    4e3a:	faf40423          	sb	a5,-88(s0)
      name[1] = 'a' + ci;
    4e3e:	0619079b          	addiw	a5,s2,97
    4e42:	faf404a3          	sb	a5,-87(s0)
      name[2] = '\0';
    4e46:	fa040523          	sb	zero,-86(s0)
      unlink(name);
    4e4a:	fa840513          	addi	a0,s0,-88
    4e4e:	00001097          	auipc	ra,0x1
    4e52:	a88080e7          	jalr	-1400(ra) # 58d6 <unlink>
    4e56:	4b79                	li	s6,30
          int cc = write(fd, buf, sz);
    4e58:	00007b97          	auipc	s7,0x7
    4e5c:	fb0b8b93          	addi	s7,s7,-80 # be08 <buf>
        for(int i = 0; i < ci+1; i++){
    4e60:	8a26                	mv	s4,s1
    4e62:	02094e63          	bltz	s2,4e9e <manywrites+0xda>
          int fd = open(name, O_CREATE | O_RDWR);
    4e66:	20200593          	li	a1,514
    4e6a:	fa840513          	addi	a0,s0,-88
    4e6e:	00001097          	auipc	ra,0x1
    4e72:	a58080e7          	jalr	-1448(ra) # 58c6 <open>
    4e76:	89aa                	mv	s3,a0
          if(fd < 0){
    4e78:	04054763          	bltz	a0,4ec6 <manywrites+0x102>
          int cc = write(fd, buf, sz);
    4e7c:	660d                	lui	a2,0x3
    4e7e:	85de                	mv	a1,s7
    4e80:	00001097          	auipc	ra,0x1
    4e84:	a26080e7          	jalr	-1498(ra) # 58a6 <write>
          if(cc != sz){
    4e88:	678d                	lui	a5,0x3
    4e8a:	04f51e63          	bne	a0,a5,4ee6 <manywrites+0x122>
          close(fd);
    4e8e:	854e                	mv	a0,s3
    4e90:	00001097          	auipc	ra,0x1
    4e94:	a1e080e7          	jalr	-1506(ra) # 58ae <close>
        for(int i = 0; i < ci+1; i++){
    4e98:	2a05                	addiw	s4,s4,1
    4e9a:	fd4956e3          	bge	s2,s4,4e66 <manywrites+0xa2>
        unlink(name);
    4e9e:	fa840513          	addi	a0,s0,-88
    4ea2:	00001097          	auipc	ra,0x1
    4ea6:	a34080e7          	jalr	-1484(ra) # 58d6 <unlink>
      for(int iters = 0; iters < howmany; iters++){
    4eaa:	3b7d                	addiw	s6,s6,-1
    4eac:	fa0b1ae3          	bnez	s6,4e60 <manywrites+0x9c>
      unlink(name);
    4eb0:	fa840513          	addi	a0,s0,-88
    4eb4:	00001097          	auipc	ra,0x1
    4eb8:	a22080e7          	jalr	-1502(ra) # 58d6 <unlink>
      exit(0);
    4ebc:	4501                	li	a0,0
    4ebe:	00001097          	auipc	ra,0x1
    4ec2:	9c8080e7          	jalr	-1592(ra) # 5886 <exit>
            printf("%s: cannot create %s\n", s, name);
    4ec6:	fa840613          	addi	a2,s0,-88
    4eca:	85d6                	mv	a1,s5
    4ecc:	00003517          	auipc	a0,0x3
    4ed0:	05c50513          	addi	a0,a0,92 # 7f28 <malloc+0x2254>
    4ed4:	00001097          	auipc	ra,0x1
    4ed8:	d42080e7          	jalr	-702(ra) # 5c16 <printf>
            exit(1);
    4edc:	4505                	li	a0,1
    4ede:	00001097          	auipc	ra,0x1
    4ee2:	9a8080e7          	jalr	-1624(ra) # 5886 <exit>
            printf("%s: write(%d) ret %d\n", s, sz, cc);
    4ee6:	86aa                	mv	a3,a0
    4ee8:	660d                	lui	a2,0x3
    4eea:	85d6                	mv	a1,s5
    4eec:	00001517          	auipc	a0,0x1
    4ef0:	31450513          	addi	a0,a0,788 # 6200 <malloc+0x52c>
    4ef4:	00001097          	auipc	ra,0x1
    4ef8:	d22080e7          	jalr	-734(ra) # 5c16 <printf>
            exit(1);
    4efc:	4505                	li	a0,1
    4efe:	00001097          	auipc	ra,0x1
    4f02:	988080e7          	jalr	-1656(ra) # 5886 <exit>
      exit(st);
    4f06:	00001097          	auipc	ra,0x1
    4f0a:	980080e7          	jalr	-1664(ra) # 5886 <exit>

0000000000004f0e <fsfull>:
{
    4f0e:	7171                	addi	sp,sp,-176
    4f10:	f506                	sd	ra,168(sp)
    4f12:	f122                	sd	s0,160(sp)
    4f14:	ed26                	sd	s1,152(sp)
    4f16:	e94a                	sd	s2,144(sp)
    4f18:	e54e                	sd	s3,136(sp)
    4f1a:	e152                	sd	s4,128(sp)
    4f1c:	fcd6                	sd	s5,120(sp)
    4f1e:	f8da                	sd	s6,112(sp)
    4f20:	f4de                	sd	s7,104(sp)
    4f22:	f0e2                	sd	s8,96(sp)
    4f24:	ece6                	sd	s9,88(sp)
    4f26:	e8ea                	sd	s10,80(sp)
    4f28:	e4ee                	sd	s11,72(sp)
    4f2a:	1900                	addi	s0,sp,176
  printf("fsfull test\n");
    4f2c:	00003517          	auipc	a0,0x3
    4f30:	01450513          	addi	a0,a0,20 # 7f40 <malloc+0x226c>
    4f34:	00001097          	auipc	ra,0x1
    4f38:	ce2080e7          	jalr	-798(ra) # 5c16 <printf>
  for(nfiles = 0; ; nfiles++){
    4f3c:	4481                	li	s1,0
    name[0] = 'f';
    4f3e:	06600d13          	li	s10,102
    name[1] = '0' + nfiles / 1000;
    4f42:	3e800c13          	li	s8,1000
    name[2] = '0' + (nfiles % 1000) / 100;
    4f46:	06400b93          	li	s7,100
    name[3] = '0' + (nfiles % 100) / 10;
    4f4a:	4b29                	li	s6,10
    printf("writing %s\n", name);
    4f4c:	00003c97          	auipc	s9,0x3
    4f50:	004c8c93          	addi	s9,s9,4 # 7f50 <malloc+0x227c>
    int total = 0;
    4f54:	4d81                	li	s11,0
      int cc = write(fd, buf, BSIZE);
    4f56:	00007a17          	auipc	s4,0x7
    4f5a:	eb2a0a13          	addi	s4,s4,-334 # be08 <buf>
    name[0] = 'f';
    4f5e:	f5a40823          	sb	s10,-176(s0)
    name[1] = '0' + nfiles / 1000;
    4f62:	0384c7bb          	divw	a5,s1,s8
    4f66:	0307879b          	addiw	a5,a5,48
    4f6a:	f4f408a3          	sb	a5,-175(s0)
    name[2] = '0' + (nfiles % 1000) / 100;
    4f6e:	0384e7bb          	remw	a5,s1,s8
    4f72:	0377c7bb          	divw	a5,a5,s7
    4f76:	0307879b          	addiw	a5,a5,48
    4f7a:	f4f40923          	sb	a5,-174(s0)
    name[3] = '0' + (nfiles % 100) / 10;
    4f7e:	0374e7bb          	remw	a5,s1,s7
    4f82:	0367c7bb          	divw	a5,a5,s6
    4f86:	0307879b          	addiw	a5,a5,48
    4f8a:	f4f409a3          	sb	a5,-173(s0)
    name[4] = '0' + (nfiles % 10);
    4f8e:	0364e7bb          	remw	a5,s1,s6
    4f92:	0307879b          	addiw	a5,a5,48
    4f96:	f4f40a23          	sb	a5,-172(s0)
    name[5] = '\0';
    4f9a:	f4040aa3          	sb	zero,-171(s0)
    printf("writing %s\n", name);
    4f9e:	f5040593          	addi	a1,s0,-176
    4fa2:	8566                	mv	a0,s9
    4fa4:	00001097          	auipc	ra,0x1
    4fa8:	c72080e7          	jalr	-910(ra) # 5c16 <printf>
    int fd = open(name, O_CREATE|O_RDWR);
    4fac:	20200593          	li	a1,514
    4fb0:	f5040513          	addi	a0,s0,-176
    4fb4:	00001097          	auipc	ra,0x1
    4fb8:	912080e7          	jalr	-1774(ra) # 58c6 <open>
    4fbc:	892a                	mv	s2,a0
    if(fd < 0){
    4fbe:	0a055663          	bgez	a0,506a <fsfull+0x15c>
      printf("open %s failed\n", name);
    4fc2:	f5040593          	addi	a1,s0,-176
    4fc6:	00003517          	auipc	a0,0x3
    4fca:	f9a50513          	addi	a0,a0,-102 # 7f60 <malloc+0x228c>
    4fce:	00001097          	auipc	ra,0x1
    4fd2:	c48080e7          	jalr	-952(ra) # 5c16 <printf>
  while(nfiles >= 0){
    4fd6:	0604c363          	bltz	s1,503c <fsfull+0x12e>
    name[0] = 'f';
    4fda:	06600b13          	li	s6,102
    name[1] = '0' + nfiles / 1000;
    4fde:	3e800a13          	li	s4,1000
    name[2] = '0' + (nfiles % 1000) / 100;
    4fe2:	06400993          	li	s3,100
    name[3] = '0' + (nfiles % 100) / 10;
    4fe6:	4929                	li	s2,10
  while(nfiles >= 0){
    4fe8:	5afd                	li	s5,-1
    name[0] = 'f';
    4fea:	f5640823          	sb	s6,-176(s0)
    name[1] = '0' + nfiles / 1000;
    4fee:	0344c7bb          	divw	a5,s1,s4
    4ff2:	0307879b          	addiw	a5,a5,48
    4ff6:	f4f408a3          	sb	a5,-175(s0)
    name[2] = '0' + (nfiles % 1000) / 100;
    4ffa:	0344e7bb          	remw	a5,s1,s4
    4ffe:	0337c7bb          	divw	a5,a5,s3
    5002:	0307879b          	addiw	a5,a5,48
    5006:	f4f40923          	sb	a5,-174(s0)
    name[3] = '0' + (nfiles % 100) / 10;
    500a:	0334e7bb          	remw	a5,s1,s3
    500e:	0327c7bb          	divw	a5,a5,s2
    5012:	0307879b          	addiw	a5,a5,48
    5016:	f4f409a3          	sb	a5,-173(s0)
    name[4] = '0' + (nfiles % 10);
    501a:	0324e7bb          	remw	a5,s1,s2
    501e:	0307879b          	addiw	a5,a5,48
    5022:	f4f40a23          	sb	a5,-172(s0)
    name[5] = '\0';
    5026:	f4040aa3          	sb	zero,-171(s0)
    unlink(name);
    502a:	f5040513          	addi	a0,s0,-176
    502e:	00001097          	auipc	ra,0x1
    5032:	8a8080e7          	jalr	-1880(ra) # 58d6 <unlink>
    nfiles--;
    5036:	34fd                	addiw	s1,s1,-1
  while(nfiles >= 0){
    5038:	fb5499e3          	bne	s1,s5,4fea <fsfull+0xdc>
  printf("fsfull test finished\n");
    503c:	00003517          	auipc	a0,0x3
    5040:	f4450513          	addi	a0,a0,-188 # 7f80 <malloc+0x22ac>
    5044:	00001097          	auipc	ra,0x1
    5048:	bd2080e7          	jalr	-1070(ra) # 5c16 <printf>
}
    504c:	70aa                	ld	ra,168(sp)
    504e:	740a                	ld	s0,160(sp)
    5050:	64ea                	ld	s1,152(sp)
    5052:	694a                	ld	s2,144(sp)
    5054:	69aa                	ld	s3,136(sp)
    5056:	6a0a                	ld	s4,128(sp)
    5058:	7ae6                	ld	s5,120(sp)
    505a:	7b46                	ld	s6,112(sp)
    505c:	7ba6                	ld	s7,104(sp)
    505e:	7c06                	ld	s8,96(sp)
    5060:	6ce6                	ld	s9,88(sp)
    5062:	6d46                	ld	s10,80(sp)
    5064:	6da6                	ld	s11,72(sp)
    5066:	614d                	addi	sp,sp,176
    5068:	8082                	ret
    int total = 0;
    506a:	89ee                	mv	s3,s11
      if(cc < BSIZE)
    506c:	3ff00a93          	li	s5,1023
      int cc = write(fd, buf, BSIZE);
    5070:	40000613          	li	a2,1024
    5074:	85d2                	mv	a1,s4
    5076:	854a                	mv	a0,s2
    5078:	00001097          	auipc	ra,0x1
    507c:	82e080e7          	jalr	-2002(ra) # 58a6 <write>
      if(cc < BSIZE)
    5080:	00aad563          	bge	s5,a0,508a <fsfull+0x17c>
      total += cc;
    5084:	00a989bb          	addw	s3,s3,a0
    while(1){
    5088:	b7e5                	j	5070 <fsfull+0x162>
    printf("wrote %d bytes\n", total);
    508a:	85ce                	mv	a1,s3
    508c:	00003517          	auipc	a0,0x3
    5090:	ee450513          	addi	a0,a0,-284 # 7f70 <malloc+0x229c>
    5094:	00001097          	auipc	ra,0x1
    5098:	b82080e7          	jalr	-1150(ra) # 5c16 <printf>
    close(fd);
    509c:	854a                	mv	a0,s2
    509e:	00001097          	auipc	ra,0x1
    50a2:	810080e7          	jalr	-2032(ra) # 58ae <close>
    if(total == 0)
    50a6:	f20988e3          	beqz	s3,4fd6 <fsfull+0xc8>
  for(nfiles = 0; ; nfiles++){
    50aa:	2485                	addiw	s1,s1,1
    50ac:	bd4d                	j	4f5e <fsfull+0x50>

00000000000050ae <badwrite>:
{
    50ae:	7179                	addi	sp,sp,-48
    50b0:	f406                	sd	ra,40(sp)
    50b2:	f022                	sd	s0,32(sp)
    50b4:	ec26                	sd	s1,24(sp)
    50b6:	e84a                	sd	s2,16(sp)
    50b8:	e44e                	sd	s3,8(sp)
    50ba:	e052                	sd	s4,0(sp)
    50bc:	1800                	addi	s0,sp,48
  unlink("junk");
    50be:	00003517          	auipc	a0,0x3
    50c2:	eda50513          	addi	a0,a0,-294 # 7f98 <malloc+0x22c4>
    50c6:	00001097          	auipc	ra,0x1
    50ca:	810080e7          	jalr	-2032(ra) # 58d6 <unlink>
    50ce:	25800913          	li	s2,600
    int fd = open("junk", O_CREATE|O_WRONLY);
    50d2:	00003997          	auipc	s3,0x3
    50d6:	ec698993          	addi	s3,s3,-314 # 7f98 <malloc+0x22c4>
    write(fd, (char*)0xffffffffffL, 1);
    50da:	5a7d                	li	s4,-1
    50dc:	018a5a13          	srli	s4,s4,0x18
    int fd = open("junk", O_CREATE|O_WRONLY);
    50e0:	20100593          	li	a1,513
    50e4:	854e                	mv	a0,s3
    50e6:	00000097          	auipc	ra,0x0
    50ea:	7e0080e7          	jalr	2016(ra) # 58c6 <open>
    50ee:	84aa                	mv	s1,a0
    if(fd < 0){
    50f0:	06054b63          	bltz	a0,5166 <badwrite+0xb8>
    write(fd, (char*)0xffffffffffL, 1);
    50f4:	4605                	li	a2,1
    50f6:	85d2                	mv	a1,s4
    50f8:	00000097          	auipc	ra,0x0
    50fc:	7ae080e7          	jalr	1966(ra) # 58a6 <write>
    close(fd);
    5100:	8526                	mv	a0,s1
    5102:	00000097          	auipc	ra,0x0
    5106:	7ac080e7          	jalr	1964(ra) # 58ae <close>
    unlink("junk");
    510a:	854e                	mv	a0,s3
    510c:	00000097          	auipc	ra,0x0
    5110:	7ca080e7          	jalr	1994(ra) # 58d6 <unlink>
  for(int i = 0; i < assumed_free; i++){
    5114:	397d                	addiw	s2,s2,-1
    5116:	fc0915e3          	bnez	s2,50e0 <badwrite+0x32>
  int fd = open("junk", O_CREATE|O_WRONLY);
    511a:	20100593          	li	a1,513
    511e:	00003517          	auipc	a0,0x3
    5122:	e7a50513          	addi	a0,a0,-390 # 7f98 <malloc+0x22c4>
    5126:	00000097          	auipc	ra,0x0
    512a:	7a0080e7          	jalr	1952(ra) # 58c6 <open>
    512e:	84aa                	mv	s1,a0
  if(fd < 0){
    5130:	04054863          	bltz	a0,5180 <badwrite+0xd2>
  if(write(fd, "x", 1) != 1){
    5134:	4605                	li	a2,1
    5136:	00001597          	auipc	a1,0x1
    513a:	07a58593          	addi	a1,a1,122 # 61b0 <malloc+0x4dc>
    513e:	00000097          	auipc	ra,0x0
    5142:	768080e7          	jalr	1896(ra) # 58a6 <write>
    5146:	4785                	li	a5,1
    5148:	04f50963          	beq	a0,a5,519a <badwrite+0xec>
    printf("write failed\n");
    514c:	00003517          	auipc	a0,0x3
    5150:	e6c50513          	addi	a0,a0,-404 # 7fb8 <malloc+0x22e4>
    5154:	00001097          	auipc	ra,0x1
    5158:	ac2080e7          	jalr	-1342(ra) # 5c16 <printf>
    exit(1);
    515c:	4505                	li	a0,1
    515e:	00000097          	auipc	ra,0x0
    5162:	728080e7          	jalr	1832(ra) # 5886 <exit>
      printf("open junk failed\n");
    5166:	00003517          	auipc	a0,0x3
    516a:	e3a50513          	addi	a0,a0,-454 # 7fa0 <malloc+0x22cc>
    516e:	00001097          	auipc	ra,0x1
    5172:	aa8080e7          	jalr	-1368(ra) # 5c16 <printf>
      exit(1);
    5176:	4505                	li	a0,1
    5178:	00000097          	auipc	ra,0x0
    517c:	70e080e7          	jalr	1806(ra) # 5886 <exit>
    printf("open junk failed\n");
    5180:	00003517          	auipc	a0,0x3
    5184:	e2050513          	addi	a0,a0,-480 # 7fa0 <malloc+0x22cc>
    5188:	00001097          	auipc	ra,0x1
    518c:	a8e080e7          	jalr	-1394(ra) # 5c16 <printf>
    exit(1);
    5190:	4505                	li	a0,1
    5192:	00000097          	auipc	ra,0x0
    5196:	6f4080e7          	jalr	1780(ra) # 5886 <exit>
  close(fd);
    519a:	8526                	mv	a0,s1
    519c:	00000097          	auipc	ra,0x0
    51a0:	712080e7          	jalr	1810(ra) # 58ae <close>
  unlink("junk");
    51a4:	00003517          	auipc	a0,0x3
    51a8:	df450513          	addi	a0,a0,-524 # 7f98 <malloc+0x22c4>
    51ac:	00000097          	auipc	ra,0x0
    51b0:	72a080e7          	jalr	1834(ra) # 58d6 <unlink>
  exit(0);
    51b4:	4501                	li	a0,0
    51b6:	00000097          	auipc	ra,0x0
    51ba:	6d0080e7          	jalr	1744(ra) # 5886 <exit>

00000000000051be <countfree>:
// because out of memory with lazy allocation results in the process
// taking a fault and being killed, fork and report back.
//
int
countfree()
{
    51be:	7139                	addi	sp,sp,-64
    51c0:	fc06                	sd	ra,56(sp)
    51c2:	f822                	sd	s0,48(sp)
    51c4:	f426                	sd	s1,40(sp)
    51c6:	f04a                	sd	s2,32(sp)
    51c8:	ec4e                	sd	s3,24(sp)
    51ca:	0080                	addi	s0,sp,64
  int fds[2];

  if(pipe(fds) < 0){
    51cc:	fc840513          	addi	a0,s0,-56
    51d0:	00000097          	auipc	ra,0x0
    51d4:	6c6080e7          	jalr	1734(ra) # 5896 <pipe>
    51d8:	06054863          	bltz	a0,5248 <countfree+0x8a>
    printf("pipe() failed in countfree()\n");
    exit(1);
  }
  
  int pid = fork();
    51dc:	00000097          	auipc	ra,0x0
    51e0:	6a2080e7          	jalr	1698(ra) # 587e <fork>

  if(pid < 0){
    51e4:	06054f63          	bltz	a0,5262 <countfree+0xa4>
    printf("fork failed in countfree()\n");
    exit(1);
  }

  if(pid == 0){
    51e8:	ed59                	bnez	a0,5286 <countfree+0xc8>
    close(fds[0]);
    51ea:	fc842503          	lw	a0,-56(s0)
    51ee:	00000097          	auipc	ra,0x0
    51f2:	6c0080e7          	jalr	1728(ra) # 58ae <close>
    
    while(1){
      uint64 a = (uint64) sbrk(4096);
      if(a == 0xffffffffffffffff){
    51f6:	54fd                	li	s1,-1
        break;
      }

      // modify the memory to make sure it's really allocated.
      *(char *)(a + 4096 - 1) = 1;
    51f8:	4985                	li	s3,1

      // report back one more page.
      if(write(fds[1], "x", 1) != 1){
    51fa:	00001917          	auipc	s2,0x1
    51fe:	fb690913          	addi	s2,s2,-74 # 61b0 <malloc+0x4dc>
      uint64 a = (uint64) sbrk(4096);
    5202:	6505                	lui	a0,0x1
    5204:	00000097          	auipc	ra,0x0
    5208:	70a080e7          	jalr	1802(ra) # 590e <sbrk>
      if(a == 0xffffffffffffffff){
    520c:	06950863          	beq	a0,s1,527c <countfree+0xbe>
      *(char *)(a + 4096 - 1) = 1;
    5210:	6785                	lui	a5,0x1
    5212:	953e                	add	a0,a0,a5
    5214:	ff350fa3          	sb	s3,-1(a0) # fff <bigdir+0x9d>
      if(write(fds[1], "x", 1) != 1){
    5218:	4605                	li	a2,1
    521a:	85ca                	mv	a1,s2
    521c:	fcc42503          	lw	a0,-52(s0)
    5220:	00000097          	auipc	ra,0x0
    5224:	686080e7          	jalr	1670(ra) # 58a6 <write>
    5228:	4785                	li	a5,1
    522a:	fcf50ce3          	beq	a0,a5,5202 <countfree+0x44>
        printf("write() failed in countfree()\n");
    522e:	00003517          	auipc	a0,0x3
    5232:	dda50513          	addi	a0,a0,-550 # 8008 <malloc+0x2334>
    5236:	00001097          	auipc	ra,0x1
    523a:	9e0080e7          	jalr	-1568(ra) # 5c16 <printf>
        exit(1);
    523e:	4505                	li	a0,1
    5240:	00000097          	auipc	ra,0x0
    5244:	646080e7          	jalr	1606(ra) # 5886 <exit>
    printf("pipe() failed in countfree()\n");
    5248:	00003517          	auipc	a0,0x3
    524c:	d8050513          	addi	a0,a0,-640 # 7fc8 <malloc+0x22f4>
    5250:	00001097          	auipc	ra,0x1
    5254:	9c6080e7          	jalr	-1594(ra) # 5c16 <printf>
    exit(1);
    5258:	4505                	li	a0,1
    525a:	00000097          	auipc	ra,0x0
    525e:	62c080e7          	jalr	1580(ra) # 5886 <exit>
    printf("fork failed in countfree()\n");
    5262:	00003517          	auipc	a0,0x3
    5266:	d8650513          	addi	a0,a0,-634 # 7fe8 <malloc+0x2314>
    526a:	00001097          	auipc	ra,0x1
    526e:	9ac080e7          	jalr	-1620(ra) # 5c16 <printf>
    exit(1);
    5272:	4505                	li	a0,1
    5274:	00000097          	auipc	ra,0x0
    5278:	612080e7          	jalr	1554(ra) # 5886 <exit>
      }
    }

    exit(0);
    527c:	4501                	li	a0,0
    527e:	00000097          	auipc	ra,0x0
    5282:	608080e7          	jalr	1544(ra) # 5886 <exit>
  }

  close(fds[1]);
    5286:	fcc42503          	lw	a0,-52(s0)
    528a:	00000097          	auipc	ra,0x0
    528e:	624080e7          	jalr	1572(ra) # 58ae <close>

  int n = 0;
    5292:	4481                	li	s1,0
  while(1){
    char c;
    int cc = read(fds[0], &c, 1);
    5294:	4605                	li	a2,1
    5296:	fc740593          	addi	a1,s0,-57
    529a:	fc842503          	lw	a0,-56(s0)
    529e:	00000097          	auipc	ra,0x0
    52a2:	600080e7          	jalr	1536(ra) # 589e <read>
    if(cc < 0){
    52a6:	00054563          	bltz	a0,52b0 <countfree+0xf2>
      printf("read() failed in countfree()\n");
      exit(1);
    }
    if(cc == 0)
    52aa:	c105                	beqz	a0,52ca <countfree+0x10c>
      break;
    n += 1;
    52ac:	2485                	addiw	s1,s1,1
  while(1){
    52ae:	b7dd                	j	5294 <countfree+0xd6>
      printf("read() failed in countfree()\n");
    52b0:	00003517          	auipc	a0,0x3
    52b4:	d7850513          	addi	a0,a0,-648 # 8028 <malloc+0x2354>
    52b8:	00001097          	auipc	ra,0x1
    52bc:	95e080e7          	jalr	-1698(ra) # 5c16 <printf>
      exit(1);
    52c0:	4505                	li	a0,1
    52c2:	00000097          	auipc	ra,0x0
    52c6:	5c4080e7          	jalr	1476(ra) # 5886 <exit>
  }

  close(fds[0]);
    52ca:	fc842503          	lw	a0,-56(s0)
    52ce:	00000097          	auipc	ra,0x0
    52d2:	5e0080e7          	jalr	1504(ra) # 58ae <close>
  wait((int*)0);
    52d6:	4501                	li	a0,0
    52d8:	00000097          	auipc	ra,0x0
    52dc:	5b6080e7          	jalr	1462(ra) # 588e <wait>
  
  return n;
}
    52e0:	8526                	mv	a0,s1
    52e2:	70e2                	ld	ra,56(sp)
    52e4:	7442                	ld	s0,48(sp)
    52e6:	74a2                	ld	s1,40(sp)
    52e8:	7902                	ld	s2,32(sp)
    52ea:	69e2                	ld	s3,24(sp)
    52ec:	6121                	addi	sp,sp,64
    52ee:	8082                	ret

00000000000052f0 <run>:

// run each test in its own process. run returns 1 if child's exit()
// indicates success.
int
run(void f(char *), char *s) {
    52f0:	7179                	addi	sp,sp,-48
    52f2:	f406                	sd	ra,40(sp)
    52f4:	f022                	sd	s0,32(sp)
    52f6:	ec26                	sd	s1,24(sp)
    52f8:	e84a                	sd	s2,16(sp)
    52fa:	1800                	addi	s0,sp,48
    52fc:	84aa                	mv	s1,a0
    52fe:	892e                	mv	s2,a1
  int pid;
  int xstatus;

  printf("test %s: ", s);
    5300:	00003517          	auipc	a0,0x3
    5304:	d4850513          	addi	a0,a0,-696 # 8048 <malloc+0x2374>
    5308:	00001097          	auipc	ra,0x1
    530c:	90e080e7          	jalr	-1778(ra) # 5c16 <printf>
  if((pid = fork()) < 0) {
    5310:	00000097          	auipc	ra,0x0
    5314:	56e080e7          	jalr	1390(ra) # 587e <fork>
    5318:	02054e63          	bltz	a0,5354 <run+0x64>
    printf("runtest: fork error\n");
    exit(1);
  }
  if(pid == 0) {
    531c:	c929                	beqz	a0,536e <run+0x7e>
    f(s);
    exit(0);
  } else {
    wait(&xstatus);
    531e:	fdc40513          	addi	a0,s0,-36
    5322:	00000097          	auipc	ra,0x0
    5326:	56c080e7          	jalr	1388(ra) # 588e <wait>
    if(xstatus != 0) 
    532a:	fdc42783          	lw	a5,-36(s0)
    532e:	c7b9                	beqz	a5,537c <run+0x8c>
      printf("FAILED\n");
    5330:	00003517          	auipc	a0,0x3
    5334:	d4050513          	addi	a0,a0,-704 # 8070 <malloc+0x239c>
    5338:	00001097          	auipc	ra,0x1
    533c:	8de080e7          	jalr	-1826(ra) # 5c16 <printf>
    else
      printf("OK\n");
    return xstatus == 0;
    5340:	fdc42503          	lw	a0,-36(s0)
  }
}
    5344:	00153513          	seqz	a0,a0
    5348:	70a2                	ld	ra,40(sp)
    534a:	7402                	ld	s0,32(sp)
    534c:	64e2                	ld	s1,24(sp)
    534e:	6942                	ld	s2,16(sp)
    5350:	6145                	addi	sp,sp,48
    5352:	8082                	ret
    printf("runtest: fork error\n");
    5354:	00003517          	auipc	a0,0x3
    5358:	d0450513          	addi	a0,a0,-764 # 8058 <malloc+0x2384>
    535c:	00001097          	auipc	ra,0x1
    5360:	8ba080e7          	jalr	-1862(ra) # 5c16 <printf>
    exit(1);
    5364:	4505                	li	a0,1
    5366:	00000097          	auipc	ra,0x0
    536a:	520080e7          	jalr	1312(ra) # 5886 <exit>
    f(s);
    536e:	854a                	mv	a0,s2
    5370:	9482                	jalr	s1
    exit(0);
    5372:	4501                	li	a0,0
    5374:	00000097          	auipc	ra,0x0
    5378:	512080e7          	jalr	1298(ra) # 5886 <exit>
      printf("OK\n");
    537c:	00003517          	auipc	a0,0x3
    5380:	cfc50513          	addi	a0,a0,-772 # 8078 <malloc+0x23a4>
    5384:	00001097          	auipc	ra,0x1
    5388:	892080e7          	jalr	-1902(ra) # 5c16 <printf>
    538c:	bf55                	j	5340 <run+0x50>

000000000000538e <main>:

int
main(int argc, char *argv[])
{
    538e:	be010113          	addi	sp,sp,-1056
    5392:	40113c23          	sd	ra,1048(sp)
    5396:	40813823          	sd	s0,1040(sp)
    539a:	40913423          	sd	s1,1032(sp)
    539e:	41213023          	sd	s2,1024(sp)
    53a2:	3f313c23          	sd	s3,1016(sp)
    53a6:	3f413823          	sd	s4,1008(sp)
    53aa:	3f513423          	sd	s5,1000(sp)
    53ae:	3f613023          	sd	s6,992(sp)
    53b2:	42010413          	addi	s0,sp,1056
    53b6:	89aa                	mv	s3,a0
    53b8:	84ae                	mv	s1,a1
  printf("usertests main\n");
    53ba:	00003517          	auipc	a0,0x3
    53be:	cc650513          	addi	a0,a0,-826 # 8080 <malloc+0x23ac>
    53c2:	00001097          	auipc	ra,0x1
    53c6:	854080e7          	jalr	-1964(ra) # 5c16 <printf>
  int continuous = 0;
  char *justone = 0;

  if(argc == 2 && strcmp(argv[1], "-c") == 0){
    53ca:	4789                	li	a5,2
    53cc:	08f98863          	beq	s3,a5,545c <main+0xce>
    continuous = 2;
    printf("usertests if2\n");
  } else if(argc == 2 && argv[1][0] != '-'){
    justone = argv[1];
    printf("usertests if3\n");
  } else if(argc > 1){
    53d0:	4785                	li	a5,1
  char *justone = 0;
    53d2:	4901                	li	s2,0
  } else if(argc > 1){
    53d4:	0d37c063          	blt	a5,s3,5494 <main+0x106>
  }
  
  struct test {
    void (*f)(char *);
    char *s;
  } tests[] = {
    53d8:	00003797          	auipc	a5,0x3
    53dc:	e0878793          	addi	a5,a5,-504 # 81e0 <malloc+0x250c>
    53e0:	be040713          	addi	a4,s0,-1056
    53e4:	00003817          	auipc	a6,0x3
    53e8:	1dc80813          	addi	a6,a6,476 # 85c0 <malloc+0x28ec>
    53ec:	6388                	ld	a0,0(a5)
    53ee:	678c                	ld	a1,8(a5)
    53f0:	6b90                	ld	a2,16(a5)
    53f2:	6f94                	ld	a3,24(a5)
    53f4:	e308                	sd	a0,0(a4)
    53f6:	e70c                	sd	a1,8(a4)
    53f8:	eb10                	sd	a2,16(a4)
    53fa:	ef14                	sd	a3,24(a4)
    53fc:	02078793          	addi	a5,a5,32
    5400:	02070713          	addi	a4,a4,32
    5404:	ff0794e3          	bne	a5,a6,53ec <main+0x5e>
          exit(1);
      }
    }
  }

  printf("usertests starting\n");
    5408:	00003517          	auipc	a0,0x3
    540c:	d9850513          	addi	a0,a0,-616 # 81a0 <malloc+0x24cc>
    5410:	00001097          	auipc	ra,0x1
    5414:	806080e7          	jalr	-2042(ra) # 5c16 <printf>
  int free0 = countfree();
    5418:	00000097          	auipc	ra,0x0
    541c:	da6080e7          	jalr	-602(ra) # 51be <countfree>
    5420:	8a2a                	mv	s4,a0
  int free1 = 0;
  int fail = 0;
  for (struct test *t = tests; t->s != 0; t++) {
    5422:	be843503          	ld	a0,-1048(s0)
    5426:	be040493          	addi	s1,s0,-1056
  int fail = 0;
    542a:	4981                	li	s3,0
    if((justone == 0) || strcmp(t->s, justone) == 0) {
      if(!run(t->f, t->s))
        fail = 1;
    542c:	4a85                	li	s5,1
  for (struct test *t = tests; t->s != 0; t++) {
    542e:	14051363          	bnez	a0,5574 <main+0x1e6>
  }

  if(fail){
    printf("SOME TESTS FAILED\n");
    exit(1);
  } else if((free1 = countfree()) < free0){
    5432:	00000097          	auipc	ra,0x0
    5436:	d8c080e7          	jalr	-628(ra) # 51be <countfree>
    543a:	85aa                	mv	a1,a0
    543c:	17455c63          	bge	a0,s4,55b4 <main+0x226>
    printf("FAILED -- lost some free pages %d (out of %d)\n", free1, free0);
    5440:	8652                	mv	a2,s4
    5442:	00003517          	auipc	a0,0x3
    5446:	cf650513          	addi	a0,a0,-778 # 8138 <malloc+0x2464>
    544a:	00000097          	auipc	ra,0x0
    544e:	7cc080e7          	jalr	1996(ra) # 5c16 <printf>
    exit(1);
    5452:	4505                	li	a0,1
    5454:	00000097          	auipc	ra,0x0
    5458:	432080e7          	jalr	1074(ra) # 5886 <exit>
  if(argc == 2 && strcmp(argv[1], "-c") == 0){
    545c:	00003597          	auipc	a1,0x3
    5460:	c3458593          	addi	a1,a1,-972 # 8090 <malloc+0x23bc>
    5464:	6488                	ld	a0,8(s1)
    5466:	00000097          	auipc	ra,0x0
    546a:	1c6080e7          	jalr	454(ra) # 562c <strcmp>
    546e:	c921                	beqz	a0,54be <main+0x130>
  } else if(argc == 2 && strcmp(argv[1], "-C") == 0){
    5470:	00003597          	auipc	a1,0x3
    5474:	d4858593          	addi	a1,a1,-696 # 81b8 <malloc+0x24e4>
    5478:	6488                	ld	a0,8(s1)
    547a:	00000097          	auipc	ra,0x0
    547e:	1b2080e7          	jalr	434(ra) # 562c <strcmp>
    5482:	c14d                	beqz	a0,5524 <main+0x196>
  } else if(argc == 2 && argv[1][0] != '-'){
    5484:	0084b903          	ld	s2,8(s1)
    5488:	00094703          	lbu	a4,0(s2)
    548c:	02d00793          	li	a5,45
    5490:	0af71363          	bne	a4,a5,5536 <main+0x1a8>
    printf("Usage: usertests [-c] [testname]\n");
    5494:	00003517          	auipc	a0,0x3
    5498:	c3450513          	addi	a0,a0,-972 # 80c8 <malloc+0x23f4>
    549c:	00000097          	auipc	ra,0x0
    54a0:	77a080e7          	jalr	1914(ra) # 5c16 <printf>
    printf("usertests if4\n");
    54a4:	00003517          	auipc	a0,0x3
    54a8:	c4c50513          	addi	a0,a0,-948 # 80f0 <malloc+0x241c>
    54ac:	00000097          	auipc	ra,0x0
    54b0:	76a080e7          	jalr	1898(ra) # 5c16 <printf>
    exit(1);
    54b4:	4505                	li	a0,1
    54b6:	00000097          	auipc	ra,0x0
    54ba:	3d0080e7          	jalr	976(ra) # 5886 <exit>
    printf("usertests if1\n");
    54be:	00003517          	auipc	a0,0x3
    54c2:	bda50513          	addi	a0,a0,-1062 # 8098 <malloc+0x23c4>
    54c6:	00000097          	auipc	ra,0x0
    54ca:	750080e7          	jalr	1872(ra) # 5c16 <printf>
    continuous = 1;
    54ce:	4985                	li	s3,1
  } tests[] = {
    54d0:	00003797          	auipc	a5,0x3
    54d4:	d1078793          	addi	a5,a5,-752 # 81e0 <malloc+0x250c>
    54d8:	be040713          	addi	a4,s0,-1056
    54dc:	00003817          	auipc	a6,0x3
    54e0:	0e480813          	addi	a6,a6,228 # 85c0 <malloc+0x28ec>
    54e4:	6388                	ld	a0,0(a5)
    54e6:	678c                	ld	a1,8(a5)
    54e8:	6b90                	ld	a2,16(a5)
    54ea:	6f94                	ld	a3,24(a5)
    54ec:	e308                	sd	a0,0(a4)
    54ee:	e70c                	sd	a1,8(a4)
    54f0:	eb10                	sd	a2,16(a4)
    54f2:	ef14                	sd	a3,24(a4)
    54f4:	02078793          	addi	a5,a5,32
    54f8:	02070713          	addi	a4,a4,32
    54fc:	ff0794e3          	bne	a5,a6,54e4 <main+0x156>
    printf("continuous usertests starting\n");
    5500:	00003517          	auipc	a0,0x3
    5504:	c8050513          	addi	a0,a0,-896 # 8180 <malloc+0x24ac>
    5508:	00000097          	auipc	ra,0x0
    550c:	70e080e7          	jalr	1806(ra) # 5c16 <printf>
        printf("SOME TESTS FAILED\n");
    5510:	00003a97          	auipc	s5,0x3
    5514:	c10a8a93          	addi	s5,s5,-1008 # 8120 <malloc+0x244c>
        if(continuous != 2)
    5518:	4a09                	li	s4,2
        printf("FAILED -- lost %d free pages\n", free0 - free1);
    551a:	00003b17          	auipc	s6,0x3
    551e:	be6b0b13          	addi	s6,s6,-1050 # 8100 <malloc+0x242c>
    5522:	a0d9                	j	55e8 <main+0x25a>
    printf("usertests if2\n");
    5524:	00003517          	auipc	a0,0x3
    5528:	b8450513          	addi	a0,a0,-1148 # 80a8 <malloc+0x23d4>
    552c:	00000097          	auipc	ra,0x0
    5530:	6ea080e7          	jalr	1770(ra) # 5c16 <printf>
    5534:	bf71                	j	54d0 <main+0x142>
    printf("usertests if3\n");
    5536:	00003517          	auipc	a0,0x3
    553a:	b8250513          	addi	a0,a0,-1150 # 80b8 <malloc+0x23e4>
    553e:	00000097          	auipc	ra,0x0
    5542:	6d8080e7          	jalr	1752(ra) # 5c16 <printf>
    5546:	bd49                	j	53d8 <main+0x4a>
          exit(1);
    5548:	4505                	li	a0,1
    554a:	00000097          	auipc	ra,0x0
    554e:	33c080e7          	jalr	828(ra) # 5886 <exit>
        printf("FAILED -- lost %d free pages\n", free0 - free1);
    5552:	40a905bb          	subw	a1,s2,a0
    5556:	855a                	mv	a0,s6
    5558:	00000097          	auipc	ra,0x0
    555c:	6be080e7          	jalr	1726(ra) # 5c16 <printf>
        if(continuous != 2)
    5560:	09498463          	beq	s3,s4,55e8 <main+0x25a>
          exit(1);
    5564:	4505                	li	a0,1
    5566:	00000097          	auipc	ra,0x0
    556a:	320080e7          	jalr	800(ra) # 5886 <exit>
  for (struct test *t = tests; t->s != 0; t++) {
    556e:	04c1                	addi	s1,s1,16
    5570:	6488                	ld	a0,8(s1)
    5572:	c115                	beqz	a0,5596 <main+0x208>
    if((justone == 0) || strcmp(t->s, justone) == 0) {
    5574:	00090863          	beqz	s2,5584 <main+0x1f6>
    5578:	85ca                	mv	a1,s2
    557a:	00000097          	auipc	ra,0x0
    557e:	0b2080e7          	jalr	178(ra) # 562c <strcmp>
    5582:	f575                	bnez	a0,556e <main+0x1e0>
      if(!run(t->f, t->s))
    5584:	648c                	ld	a1,8(s1)
    5586:	6088                	ld	a0,0(s1)
    5588:	00000097          	auipc	ra,0x0
    558c:	d68080e7          	jalr	-664(ra) # 52f0 <run>
    5590:	fd79                	bnez	a0,556e <main+0x1e0>
        fail = 1;
    5592:	89d6                	mv	s3,s5
    5594:	bfe9                	j	556e <main+0x1e0>
  if(fail){
    5596:	e8098ee3          	beqz	s3,5432 <main+0xa4>
    printf("SOME TESTS FAILED\n");
    559a:	00003517          	auipc	a0,0x3
    559e:	b8650513          	addi	a0,a0,-1146 # 8120 <malloc+0x244c>
    55a2:	00000097          	auipc	ra,0x0
    55a6:	674080e7          	jalr	1652(ra) # 5c16 <printf>
    exit(1);
    55aa:	4505                	li	a0,1
    55ac:	00000097          	auipc	ra,0x0
    55b0:	2da080e7          	jalr	730(ra) # 5886 <exit>
  } else {
    printf("ALL TESTS PASSED\n");
    55b4:	00003517          	auipc	a0,0x3
    55b8:	bb450513          	addi	a0,a0,-1100 # 8168 <malloc+0x2494>
    55bc:	00000097          	auipc	ra,0x0
    55c0:	65a080e7          	jalr	1626(ra) # 5c16 <printf>
    exit(0);
    55c4:	4501                	li	a0,0
    55c6:	00000097          	auipc	ra,0x0
    55ca:	2c0080e7          	jalr	704(ra) # 5886 <exit>
        printf("SOME TESTS FAILED\n");
    55ce:	8556                	mv	a0,s5
    55d0:	00000097          	auipc	ra,0x0
    55d4:	646080e7          	jalr	1606(ra) # 5c16 <printf>
        if(continuous != 2)
    55d8:	f74998e3          	bne	s3,s4,5548 <main+0x1ba>
      int free1 = countfree();
    55dc:	00000097          	auipc	ra,0x0
    55e0:	be2080e7          	jalr	-1054(ra) # 51be <countfree>
      if(free1 < free0){
    55e4:	f72547e3          	blt	a0,s2,5552 <main+0x1c4>
      int free0 = countfree();
    55e8:	00000097          	auipc	ra,0x0
    55ec:	bd6080e7          	jalr	-1066(ra) # 51be <countfree>
    55f0:	892a                	mv	s2,a0
      for (struct test *t = tests; t->s != 0; t++) {
    55f2:	be843583          	ld	a1,-1048(s0)
    55f6:	d1fd                	beqz	a1,55dc <main+0x24e>
    55f8:	be040493          	addi	s1,s0,-1056
        if(!run(t->f, t->s)){
    55fc:	6088                	ld	a0,0(s1)
    55fe:	00000097          	auipc	ra,0x0
    5602:	cf2080e7          	jalr	-782(ra) # 52f0 <run>
    5606:	d561                	beqz	a0,55ce <main+0x240>
      for (struct test *t = tests; t->s != 0; t++) {
    5608:	04c1                	addi	s1,s1,16
    560a:	648c                	ld	a1,8(s1)
    560c:	f9e5                	bnez	a1,55fc <main+0x26e>
    560e:	b7f9                	j	55dc <main+0x24e>

0000000000005610 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
    5610:	1141                	addi	sp,sp,-16
    5612:	e422                	sd	s0,8(sp)
    5614:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
    5616:	87aa                	mv	a5,a0
    5618:	0585                	addi	a1,a1,1
    561a:	0785                	addi	a5,a5,1
    561c:	fff5c703          	lbu	a4,-1(a1)
    5620:	fee78fa3          	sb	a4,-1(a5)
    5624:	fb75                	bnez	a4,5618 <strcpy+0x8>
    ;
  return os;
}
    5626:	6422                	ld	s0,8(sp)
    5628:	0141                	addi	sp,sp,16
    562a:	8082                	ret

000000000000562c <strcmp>:

int
strcmp(const char *p, const char *q)
{
    562c:	1141                	addi	sp,sp,-16
    562e:	e422                	sd	s0,8(sp)
    5630:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
    5632:	00054783          	lbu	a5,0(a0)
    5636:	cb91                	beqz	a5,564a <strcmp+0x1e>
    5638:	0005c703          	lbu	a4,0(a1)
    563c:	00f71763          	bne	a4,a5,564a <strcmp+0x1e>
    p++, q++;
    5640:	0505                	addi	a0,a0,1
    5642:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
    5644:	00054783          	lbu	a5,0(a0)
    5648:	fbe5                	bnez	a5,5638 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
    564a:	0005c503          	lbu	a0,0(a1)
}
    564e:	40a7853b          	subw	a0,a5,a0
    5652:	6422                	ld	s0,8(sp)
    5654:	0141                	addi	sp,sp,16
    5656:	8082                	ret

0000000000005658 <strlen>:

uint
strlen(const char *s)
{
    5658:	1141                	addi	sp,sp,-16
    565a:	e422                	sd	s0,8(sp)
    565c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    565e:	00054783          	lbu	a5,0(a0)
    5662:	cf91                	beqz	a5,567e <strlen+0x26>
    5664:	0505                	addi	a0,a0,1
    5666:	87aa                	mv	a5,a0
    5668:	4685                	li	a3,1
    566a:	9e89                	subw	a3,a3,a0
    566c:	00f6853b          	addw	a0,a3,a5
    5670:	0785                	addi	a5,a5,1
    5672:	fff7c703          	lbu	a4,-1(a5)
    5676:	fb7d                	bnez	a4,566c <strlen+0x14>
    ;
  return n;
}
    5678:	6422                	ld	s0,8(sp)
    567a:	0141                	addi	sp,sp,16
    567c:	8082                	ret
  for(n = 0; s[n]; n++)
    567e:	4501                	li	a0,0
    5680:	bfe5                	j	5678 <strlen+0x20>

0000000000005682 <memset>:

void*
memset(void *dst, int c, uint n)
{
    5682:	1141                	addi	sp,sp,-16
    5684:	e422                	sd	s0,8(sp)
    5686:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    5688:	ce09                	beqz	a2,56a2 <memset+0x20>
    568a:	87aa                	mv	a5,a0
    568c:	fff6071b          	addiw	a4,a2,-1
    5690:	1702                	slli	a4,a4,0x20
    5692:	9301                	srli	a4,a4,0x20
    5694:	0705                	addi	a4,a4,1
    5696:	972a                	add	a4,a4,a0
    cdst[i] = c;
    5698:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    569c:	0785                	addi	a5,a5,1
    569e:	fee79de3          	bne	a5,a4,5698 <memset+0x16>
  }
  return dst;
}
    56a2:	6422                	ld	s0,8(sp)
    56a4:	0141                	addi	sp,sp,16
    56a6:	8082                	ret

00000000000056a8 <strchr>:

char*
strchr(const char *s, char c)
{
    56a8:	1141                	addi	sp,sp,-16
    56aa:	e422                	sd	s0,8(sp)
    56ac:	0800                	addi	s0,sp,16
  for(; *s; s++)
    56ae:	00054783          	lbu	a5,0(a0)
    56b2:	cb99                	beqz	a5,56c8 <strchr+0x20>
    if(*s == c)
    56b4:	00f58763          	beq	a1,a5,56c2 <strchr+0x1a>
  for(; *s; s++)
    56b8:	0505                	addi	a0,a0,1
    56ba:	00054783          	lbu	a5,0(a0)
    56be:	fbfd                	bnez	a5,56b4 <strchr+0xc>
      return (char*)s;
  return 0;
    56c0:	4501                	li	a0,0
}
    56c2:	6422                	ld	s0,8(sp)
    56c4:	0141                	addi	sp,sp,16
    56c6:	8082                	ret
  return 0;
    56c8:	4501                	li	a0,0
    56ca:	bfe5                	j	56c2 <strchr+0x1a>

00000000000056cc <gets>:

char*
gets(char *buf, int max)
{
    56cc:	711d                	addi	sp,sp,-96
    56ce:	ec86                	sd	ra,88(sp)
    56d0:	e8a2                	sd	s0,80(sp)
    56d2:	e4a6                	sd	s1,72(sp)
    56d4:	e0ca                	sd	s2,64(sp)
    56d6:	fc4e                	sd	s3,56(sp)
    56d8:	f852                	sd	s4,48(sp)
    56da:	f456                	sd	s5,40(sp)
    56dc:	f05a                	sd	s6,32(sp)
    56de:	ec5e                	sd	s7,24(sp)
    56e0:	1080                	addi	s0,sp,96
    56e2:	8baa                	mv	s7,a0
    56e4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
    56e6:	892a                	mv	s2,a0
    56e8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
    56ea:	4aa9                	li	s5,10
    56ec:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
    56ee:	89a6                	mv	s3,s1
    56f0:	2485                	addiw	s1,s1,1
    56f2:	0344d863          	bge	s1,s4,5722 <gets+0x56>
    cc = read(0, &c, 1);
    56f6:	4605                	li	a2,1
    56f8:	faf40593          	addi	a1,s0,-81
    56fc:	4501                	li	a0,0
    56fe:	00000097          	auipc	ra,0x0
    5702:	1a0080e7          	jalr	416(ra) # 589e <read>
    if(cc < 1)
    5706:	00a05e63          	blez	a0,5722 <gets+0x56>
    buf[i++] = c;
    570a:	faf44783          	lbu	a5,-81(s0)
    570e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
    5712:	01578763          	beq	a5,s5,5720 <gets+0x54>
    5716:	0905                	addi	s2,s2,1
    5718:	fd679be3          	bne	a5,s6,56ee <gets+0x22>
  for(i=0; i+1 < max; ){
    571c:	89a6                	mv	s3,s1
    571e:	a011                	j	5722 <gets+0x56>
    5720:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
    5722:	99de                	add	s3,s3,s7
    5724:	00098023          	sb	zero,0(s3)
  return buf;
}
    5728:	855e                	mv	a0,s7
    572a:	60e6                	ld	ra,88(sp)
    572c:	6446                	ld	s0,80(sp)
    572e:	64a6                	ld	s1,72(sp)
    5730:	6906                	ld	s2,64(sp)
    5732:	79e2                	ld	s3,56(sp)
    5734:	7a42                	ld	s4,48(sp)
    5736:	7aa2                	ld	s5,40(sp)
    5738:	7b02                	ld	s6,32(sp)
    573a:	6be2                	ld	s7,24(sp)
    573c:	6125                	addi	sp,sp,96
    573e:	8082                	ret

0000000000005740 <stat>:

int
stat(const char *n, struct stat *st)
{
    5740:	1101                	addi	sp,sp,-32
    5742:	ec06                	sd	ra,24(sp)
    5744:	e822                	sd	s0,16(sp)
    5746:	e426                	sd	s1,8(sp)
    5748:	e04a                	sd	s2,0(sp)
    574a:	1000                	addi	s0,sp,32
    574c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
    574e:	4581                	li	a1,0
    5750:	00000097          	auipc	ra,0x0
    5754:	176080e7          	jalr	374(ra) # 58c6 <open>
  if(fd < 0)
    5758:	02054563          	bltz	a0,5782 <stat+0x42>
    575c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
    575e:	85ca                	mv	a1,s2
    5760:	00000097          	auipc	ra,0x0
    5764:	17e080e7          	jalr	382(ra) # 58de <fstat>
    5768:	892a                	mv	s2,a0
  close(fd);
    576a:	8526                	mv	a0,s1
    576c:	00000097          	auipc	ra,0x0
    5770:	142080e7          	jalr	322(ra) # 58ae <close>
  return r;
}
    5774:	854a                	mv	a0,s2
    5776:	60e2                	ld	ra,24(sp)
    5778:	6442                	ld	s0,16(sp)
    577a:	64a2                	ld	s1,8(sp)
    577c:	6902                	ld	s2,0(sp)
    577e:	6105                	addi	sp,sp,32
    5780:	8082                	ret
    return -1;
    5782:	597d                	li	s2,-1
    5784:	bfc5                	j	5774 <stat+0x34>

0000000000005786 <atoi>:

int
atoi(const char *s)
{
    5786:	1141                	addi	sp,sp,-16
    5788:	e422                	sd	s0,8(sp)
    578a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
    578c:	00054603          	lbu	a2,0(a0)
    5790:	fd06079b          	addiw	a5,a2,-48
    5794:	0ff7f793          	andi	a5,a5,255
    5798:	4725                	li	a4,9
    579a:	02f76963          	bltu	a4,a5,57cc <atoi+0x46>
    579e:	86aa                	mv	a3,a0
  n = 0;
    57a0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
    57a2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
    57a4:	0685                	addi	a3,a3,1
    57a6:	0025179b          	slliw	a5,a0,0x2
    57aa:	9fa9                	addw	a5,a5,a0
    57ac:	0017979b          	slliw	a5,a5,0x1
    57b0:	9fb1                	addw	a5,a5,a2
    57b2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
    57b6:	0006c603          	lbu	a2,0(a3) # 1000 <bigdir+0x9e>
    57ba:	fd06071b          	addiw	a4,a2,-48
    57be:	0ff77713          	andi	a4,a4,255
    57c2:	fee5f1e3          	bgeu	a1,a4,57a4 <atoi+0x1e>
  return n;
}
    57c6:	6422                	ld	s0,8(sp)
    57c8:	0141                	addi	sp,sp,16
    57ca:	8082                	ret
  n = 0;
    57cc:	4501                	li	a0,0
    57ce:	bfe5                	j	57c6 <atoi+0x40>

00000000000057d0 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
    57d0:	1141                	addi	sp,sp,-16
    57d2:	e422                	sd	s0,8(sp)
    57d4:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
    57d6:	02b57663          	bgeu	a0,a1,5802 <memmove+0x32>
    while(n-- > 0)
    57da:	02c05163          	blez	a2,57fc <memmove+0x2c>
    57de:	fff6079b          	addiw	a5,a2,-1
    57e2:	1782                	slli	a5,a5,0x20
    57e4:	9381                	srli	a5,a5,0x20
    57e6:	0785                	addi	a5,a5,1
    57e8:	97aa                	add	a5,a5,a0
  dst = vdst;
    57ea:	872a                	mv	a4,a0
      *dst++ = *src++;
    57ec:	0585                	addi	a1,a1,1
    57ee:	0705                	addi	a4,a4,1
    57f0:	fff5c683          	lbu	a3,-1(a1)
    57f4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    57f8:	fee79ae3          	bne	a5,a4,57ec <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
    57fc:	6422                	ld	s0,8(sp)
    57fe:	0141                	addi	sp,sp,16
    5800:	8082                	ret
    dst += n;
    5802:	00c50733          	add	a4,a0,a2
    src += n;
    5806:	95b2                	add	a1,a1,a2
    while(n-- > 0)
    5808:	fec05ae3          	blez	a2,57fc <memmove+0x2c>
    580c:	fff6079b          	addiw	a5,a2,-1
    5810:	1782                	slli	a5,a5,0x20
    5812:	9381                	srli	a5,a5,0x20
    5814:	fff7c793          	not	a5,a5
    5818:	97ba                	add	a5,a5,a4
      *--dst = *--src;
    581a:	15fd                	addi	a1,a1,-1
    581c:	177d                	addi	a4,a4,-1
    581e:	0005c683          	lbu	a3,0(a1)
    5822:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    5826:	fee79ae3          	bne	a5,a4,581a <memmove+0x4a>
    582a:	bfc9                	j	57fc <memmove+0x2c>

000000000000582c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
    582c:	1141                	addi	sp,sp,-16
    582e:	e422                	sd	s0,8(sp)
    5830:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
    5832:	ca05                	beqz	a2,5862 <memcmp+0x36>
    5834:	fff6069b          	addiw	a3,a2,-1
    5838:	1682                	slli	a3,a3,0x20
    583a:	9281                	srli	a3,a3,0x20
    583c:	0685                	addi	a3,a3,1
    583e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
    5840:	00054783          	lbu	a5,0(a0)
    5844:	0005c703          	lbu	a4,0(a1)
    5848:	00e79863          	bne	a5,a4,5858 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
    584c:	0505                	addi	a0,a0,1
    p2++;
    584e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
    5850:	fed518e3          	bne	a0,a3,5840 <memcmp+0x14>
  }
  return 0;
    5854:	4501                	li	a0,0
    5856:	a019                	j	585c <memcmp+0x30>
      return *p1 - *p2;
    5858:	40e7853b          	subw	a0,a5,a4
}
    585c:	6422                	ld	s0,8(sp)
    585e:	0141                	addi	sp,sp,16
    5860:	8082                	ret
  return 0;
    5862:	4501                	li	a0,0
    5864:	bfe5                	j	585c <memcmp+0x30>

0000000000005866 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
    5866:	1141                	addi	sp,sp,-16
    5868:	e406                	sd	ra,8(sp)
    586a:	e022                	sd	s0,0(sp)
    586c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    586e:	00000097          	auipc	ra,0x0
    5872:	f62080e7          	jalr	-158(ra) # 57d0 <memmove>
}
    5876:	60a2                	ld	ra,8(sp)
    5878:	6402                	ld	s0,0(sp)
    587a:	0141                	addi	sp,sp,16
    587c:	8082                	ret

000000000000587e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
    587e:	4885                	li	a7,1
 ecall
    5880:	00000073          	ecall
 ret
    5884:	8082                	ret

0000000000005886 <exit>:
.global exit
exit:
 li a7, SYS_exit
    5886:	4889                	li	a7,2
 ecall
    5888:	00000073          	ecall
 ret
    588c:	8082                	ret

000000000000588e <wait>:
.global wait
wait:
 li a7, SYS_wait
    588e:	488d                	li	a7,3
 ecall
    5890:	00000073          	ecall
 ret
    5894:	8082                	ret

0000000000005896 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
    5896:	4891                	li	a7,4
 ecall
    5898:	00000073          	ecall
 ret
    589c:	8082                	ret

000000000000589e <read>:
.global read
read:
 li a7, SYS_read
    589e:	4895                	li	a7,5
 ecall
    58a0:	00000073          	ecall
 ret
    58a4:	8082                	ret

00000000000058a6 <write>:
.global write
write:
 li a7, SYS_write
    58a6:	48c1                	li	a7,16
 ecall
    58a8:	00000073          	ecall
 ret
    58ac:	8082                	ret

00000000000058ae <close>:
.global close
close:
 li a7, SYS_close
    58ae:	48d5                	li	a7,21
 ecall
    58b0:	00000073          	ecall
 ret
    58b4:	8082                	ret

00000000000058b6 <kill>:
.global kill
kill:
 li a7, SYS_kill
    58b6:	4899                	li	a7,6
 ecall
    58b8:	00000073          	ecall
 ret
    58bc:	8082                	ret

00000000000058be <exec>:
.global exec
exec:
 li a7, SYS_exec
    58be:	489d                	li	a7,7
 ecall
    58c0:	00000073          	ecall
 ret
    58c4:	8082                	ret

00000000000058c6 <open>:
.global open
open:
 li a7, SYS_open
    58c6:	48bd                	li	a7,15
 ecall
    58c8:	00000073          	ecall
 ret
    58cc:	8082                	ret

00000000000058ce <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
    58ce:	48c5                	li	a7,17
 ecall
    58d0:	00000073          	ecall
 ret
    58d4:	8082                	ret

00000000000058d6 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
    58d6:	48c9                	li	a7,18
 ecall
    58d8:	00000073          	ecall
 ret
    58dc:	8082                	ret

00000000000058de <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
    58de:	48a1                	li	a7,8
 ecall
    58e0:	00000073          	ecall
 ret
    58e4:	8082                	ret

00000000000058e6 <link>:
.global link
link:
 li a7, SYS_link
    58e6:	48cd                	li	a7,19
 ecall
    58e8:	00000073          	ecall
 ret
    58ec:	8082                	ret

00000000000058ee <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
    58ee:	48d1                	li	a7,20
 ecall
    58f0:	00000073          	ecall
 ret
    58f4:	8082                	ret

00000000000058f6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
    58f6:	48a5                	li	a7,9
 ecall
    58f8:	00000073          	ecall
 ret
    58fc:	8082                	ret

00000000000058fe <dup>:
.global dup
dup:
 li a7, SYS_dup
    58fe:	48a9                	li	a7,10
 ecall
    5900:	00000073          	ecall
 ret
    5904:	8082                	ret

0000000000005906 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
    5906:	48ad                	li	a7,11
 ecall
    5908:	00000073          	ecall
 ret
    590c:	8082                	ret

000000000000590e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
    590e:	48b1                	li	a7,12
 ecall
    5910:	00000073          	ecall
 ret
    5914:	8082                	ret

0000000000005916 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
    5916:	48b5                	li	a7,13
 ecall
    5918:	00000073          	ecall
 ret
    591c:	8082                	ret

000000000000591e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
    591e:	48b9                	li	a7,14
 ecall
    5920:	00000073          	ecall
 ret
    5924:	8082                	ret

0000000000005926 <get_cpu>:
.global get_cpu
get_cpu:
 li a7, SYS_get_cpu
    5926:	48d9                	li	a7,22
 ecall
    5928:	00000073          	ecall
 ret
    592c:	8082                	ret

000000000000592e <set_cpu>:
.global set_cpu
set_cpu:
 li a7, SYS_set_cpu
    592e:	48dd                	li	a7,23
 ecall
    5930:	00000073          	ecall
 ret
    5934:	8082                	ret

0000000000005936 <cpu_process_count>:
.global cpu_process_count
cpu_process_count:
 li a7, SYS_cpu_process_count
    5936:	48e1                	li	a7,24
 ecall
    5938:	00000073          	ecall
 ret
    593c:	8082                	ret

000000000000593e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
    593e:	1101                	addi	sp,sp,-32
    5940:	ec06                	sd	ra,24(sp)
    5942:	e822                	sd	s0,16(sp)
    5944:	1000                	addi	s0,sp,32
    5946:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
    594a:	4605                	li	a2,1
    594c:	fef40593          	addi	a1,s0,-17
    5950:	00000097          	auipc	ra,0x0
    5954:	f56080e7          	jalr	-170(ra) # 58a6 <write>
}
    5958:	60e2                	ld	ra,24(sp)
    595a:	6442                	ld	s0,16(sp)
    595c:	6105                	addi	sp,sp,32
    595e:	8082                	ret

0000000000005960 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
    5960:	7139                	addi	sp,sp,-64
    5962:	fc06                	sd	ra,56(sp)
    5964:	f822                	sd	s0,48(sp)
    5966:	f426                	sd	s1,40(sp)
    5968:	f04a                	sd	s2,32(sp)
    596a:	ec4e                	sd	s3,24(sp)
    596c:	0080                	addi	s0,sp,64
    596e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
    5970:	c299                	beqz	a3,5976 <printint+0x16>
    5972:	0805c863          	bltz	a1,5a02 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
    5976:	2581                	sext.w	a1,a1
  neg = 0;
    5978:	4881                	li	a7,0
    597a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
    597e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
    5980:	2601                	sext.w	a2,a2
    5982:	00003517          	auipc	a0,0x3
    5986:	c4650513          	addi	a0,a0,-954 # 85c8 <digits>
    598a:	883a                	mv	a6,a4
    598c:	2705                	addiw	a4,a4,1
    598e:	02c5f7bb          	remuw	a5,a1,a2
    5992:	1782                	slli	a5,a5,0x20
    5994:	9381                	srli	a5,a5,0x20
    5996:	97aa                	add	a5,a5,a0
    5998:	0007c783          	lbu	a5,0(a5)
    599c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
    59a0:	0005879b          	sext.w	a5,a1
    59a4:	02c5d5bb          	divuw	a1,a1,a2
    59a8:	0685                	addi	a3,a3,1
    59aa:	fec7f0e3          	bgeu	a5,a2,598a <printint+0x2a>
  if(neg)
    59ae:	00088b63          	beqz	a7,59c4 <printint+0x64>
    buf[i++] = '-';
    59b2:	fd040793          	addi	a5,s0,-48
    59b6:	973e                	add	a4,a4,a5
    59b8:	02d00793          	li	a5,45
    59bc:	fef70823          	sb	a5,-16(a4)
    59c0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    59c4:	02e05863          	blez	a4,59f4 <printint+0x94>
    59c8:	fc040793          	addi	a5,s0,-64
    59cc:	00e78933          	add	s2,a5,a4
    59d0:	fff78993          	addi	s3,a5,-1
    59d4:	99ba                	add	s3,s3,a4
    59d6:	377d                	addiw	a4,a4,-1
    59d8:	1702                	slli	a4,a4,0x20
    59da:	9301                	srli	a4,a4,0x20
    59dc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
    59e0:	fff94583          	lbu	a1,-1(s2)
    59e4:	8526                	mv	a0,s1
    59e6:	00000097          	auipc	ra,0x0
    59ea:	f58080e7          	jalr	-168(ra) # 593e <putc>
  while(--i >= 0)
    59ee:	197d                	addi	s2,s2,-1
    59f0:	ff3918e3          	bne	s2,s3,59e0 <printint+0x80>
}
    59f4:	70e2                	ld	ra,56(sp)
    59f6:	7442                	ld	s0,48(sp)
    59f8:	74a2                	ld	s1,40(sp)
    59fa:	7902                	ld	s2,32(sp)
    59fc:	69e2                	ld	s3,24(sp)
    59fe:	6121                	addi	sp,sp,64
    5a00:	8082                	ret
    x = -xx;
    5a02:	40b005bb          	negw	a1,a1
    neg = 1;
    5a06:	4885                	li	a7,1
    x = -xx;
    5a08:	bf8d                	j	597a <printint+0x1a>

0000000000005a0a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
    5a0a:	7119                	addi	sp,sp,-128
    5a0c:	fc86                	sd	ra,120(sp)
    5a0e:	f8a2                	sd	s0,112(sp)
    5a10:	f4a6                	sd	s1,104(sp)
    5a12:	f0ca                	sd	s2,96(sp)
    5a14:	ecce                	sd	s3,88(sp)
    5a16:	e8d2                	sd	s4,80(sp)
    5a18:	e4d6                	sd	s5,72(sp)
    5a1a:	e0da                	sd	s6,64(sp)
    5a1c:	fc5e                	sd	s7,56(sp)
    5a1e:	f862                	sd	s8,48(sp)
    5a20:	f466                	sd	s9,40(sp)
    5a22:	f06a                	sd	s10,32(sp)
    5a24:	ec6e                	sd	s11,24(sp)
    5a26:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    5a28:	0005c903          	lbu	s2,0(a1)
    5a2c:	18090f63          	beqz	s2,5bca <vprintf+0x1c0>
    5a30:	8aaa                	mv	s5,a0
    5a32:	8b32                	mv	s6,a2
    5a34:	00158493          	addi	s1,a1,1
  state = 0;
    5a38:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    5a3a:	02500a13          	li	s4,37
      if(c == 'd'){
    5a3e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    5a42:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    5a46:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    5a4a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    5a4e:	00003b97          	auipc	s7,0x3
    5a52:	b7ab8b93          	addi	s7,s7,-1158 # 85c8 <digits>
    5a56:	a839                	j	5a74 <vprintf+0x6a>
        putc(fd, c);
    5a58:	85ca                	mv	a1,s2
    5a5a:	8556                	mv	a0,s5
    5a5c:	00000097          	auipc	ra,0x0
    5a60:	ee2080e7          	jalr	-286(ra) # 593e <putc>
    5a64:	a019                	j	5a6a <vprintf+0x60>
    } else if(state == '%'){
    5a66:	01498f63          	beq	s3,s4,5a84 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    5a6a:	0485                	addi	s1,s1,1
    5a6c:	fff4c903          	lbu	s2,-1(s1)
    5a70:	14090d63          	beqz	s2,5bca <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    5a74:	0009079b          	sext.w	a5,s2
    if(state == 0){
    5a78:	fe0997e3          	bnez	s3,5a66 <vprintf+0x5c>
      if(c == '%'){
    5a7c:	fd479ee3          	bne	a5,s4,5a58 <vprintf+0x4e>
        state = '%';
    5a80:	89be                	mv	s3,a5
    5a82:	b7e5                	j	5a6a <vprintf+0x60>
      if(c == 'd'){
    5a84:	05878063          	beq	a5,s8,5ac4 <vprintf+0xba>
      } else if(c == 'l') {
    5a88:	05978c63          	beq	a5,s9,5ae0 <vprintf+0xd6>
      } else if(c == 'x') {
    5a8c:	07a78863          	beq	a5,s10,5afc <vprintf+0xf2>
      } else if(c == 'p') {
    5a90:	09b78463          	beq	a5,s11,5b18 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    5a94:	07300713          	li	a4,115
    5a98:	0ce78663          	beq	a5,a4,5b64 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    5a9c:	06300713          	li	a4,99
    5aa0:	0ee78e63          	beq	a5,a4,5b9c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    5aa4:	11478863          	beq	a5,s4,5bb4 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    5aa8:	85d2                	mv	a1,s4
    5aaa:	8556                	mv	a0,s5
    5aac:	00000097          	auipc	ra,0x0
    5ab0:	e92080e7          	jalr	-366(ra) # 593e <putc>
        putc(fd, c);
    5ab4:	85ca                	mv	a1,s2
    5ab6:	8556                	mv	a0,s5
    5ab8:	00000097          	auipc	ra,0x0
    5abc:	e86080e7          	jalr	-378(ra) # 593e <putc>
      }
      state = 0;
    5ac0:	4981                	li	s3,0
    5ac2:	b765                	j	5a6a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    5ac4:	008b0913          	addi	s2,s6,8
    5ac8:	4685                	li	a3,1
    5aca:	4629                	li	a2,10
    5acc:	000b2583          	lw	a1,0(s6)
    5ad0:	8556                	mv	a0,s5
    5ad2:	00000097          	auipc	ra,0x0
    5ad6:	e8e080e7          	jalr	-370(ra) # 5960 <printint>
    5ada:	8b4a                	mv	s6,s2
      state = 0;
    5adc:	4981                	li	s3,0
    5ade:	b771                	j	5a6a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    5ae0:	008b0913          	addi	s2,s6,8
    5ae4:	4681                	li	a3,0
    5ae6:	4629                	li	a2,10
    5ae8:	000b2583          	lw	a1,0(s6)
    5aec:	8556                	mv	a0,s5
    5aee:	00000097          	auipc	ra,0x0
    5af2:	e72080e7          	jalr	-398(ra) # 5960 <printint>
    5af6:	8b4a                	mv	s6,s2
      state = 0;
    5af8:	4981                	li	s3,0
    5afa:	bf85                	j	5a6a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    5afc:	008b0913          	addi	s2,s6,8
    5b00:	4681                	li	a3,0
    5b02:	4641                	li	a2,16
    5b04:	000b2583          	lw	a1,0(s6)
    5b08:	8556                	mv	a0,s5
    5b0a:	00000097          	auipc	ra,0x0
    5b0e:	e56080e7          	jalr	-426(ra) # 5960 <printint>
    5b12:	8b4a                	mv	s6,s2
      state = 0;
    5b14:	4981                	li	s3,0
    5b16:	bf91                	j	5a6a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    5b18:	008b0793          	addi	a5,s6,8
    5b1c:	f8f43423          	sd	a5,-120(s0)
    5b20:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    5b24:	03000593          	li	a1,48
    5b28:	8556                	mv	a0,s5
    5b2a:	00000097          	auipc	ra,0x0
    5b2e:	e14080e7          	jalr	-492(ra) # 593e <putc>
  putc(fd, 'x');
    5b32:	85ea                	mv	a1,s10
    5b34:	8556                	mv	a0,s5
    5b36:	00000097          	auipc	ra,0x0
    5b3a:	e08080e7          	jalr	-504(ra) # 593e <putc>
    5b3e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    5b40:	03c9d793          	srli	a5,s3,0x3c
    5b44:	97de                	add	a5,a5,s7
    5b46:	0007c583          	lbu	a1,0(a5)
    5b4a:	8556                	mv	a0,s5
    5b4c:	00000097          	auipc	ra,0x0
    5b50:	df2080e7          	jalr	-526(ra) # 593e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    5b54:	0992                	slli	s3,s3,0x4
    5b56:	397d                	addiw	s2,s2,-1
    5b58:	fe0914e3          	bnez	s2,5b40 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    5b5c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    5b60:	4981                	li	s3,0
    5b62:	b721                	j	5a6a <vprintf+0x60>
        s = va_arg(ap, char*);
    5b64:	008b0993          	addi	s3,s6,8
    5b68:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    5b6c:	02090163          	beqz	s2,5b8e <vprintf+0x184>
        while(*s != 0){
    5b70:	00094583          	lbu	a1,0(s2)
    5b74:	c9a1                	beqz	a1,5bc4 <vprintf+0x1ba>
          putc(fd, *s);
    5b76:	8556                	mv	a0,s5
    5b78:	00000097          	auipc	ra,0x0
    5b7c:	dc6080e7          	jalr	-570(ra) # 593e <putc>
          s++;
    5b80:	0905                	addi	s2,s2,1
        while(*s != 0){
    5b82:	00094583          	lbu	a1,0(s2)
    5b86:	f9e5                	bnez	a1,5b76 <vprintf+0x16c>
        s = va_arg(ap, char*);
    5b88:	8b4e                	mv	s6,s3
      state = 0;
    5b8a:	4981                	li	s3,0
    5b8c:	bdf9                	j	5a6a <vprintf+0x60>
          s = "(null)";
    5b8e:	00003917          	auipc	s2,0x3
    5b92:	a3290913          	addi	s2,s2,-1486 # 85c0 <malloc+0x28ec>
        while(*s != 0){
    5b96:	02800593          	li	a1,40
    5b9a:	bff1                	j	5b76 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    5b9c:	008b0913          	addi	s2,s6,8
    5ba0:	000b4583          	lbu	a1,0(s6)
    5ba4:	8556                	mv	a0,s5
    5ba6:	00000097          	auipc	ra,0x0
    5baa:	d98080e7          	jalr	-616(ra) # 593e <putc>
    5bae:	8b4a                	mv	s6,s2
      state = 0;
    5bb0:	4981                	li	s3,0
    5bb2:	bd65                	j	5a6a <vprintf+0x60>
        putc(fd, c);
    5bb4:	85d2                	mv	a1,s4
    5bb6:	8556                	mv	a0,s5
    5bb8:	00000097          	auipc	ra,0x0
    5bbc:	d86080e7          	jalr	-634(ra) # 593e <putc>
      state = 0;
    5bc0:	4981                	li	s3,0
    5bc2:	b565                	j	5a6a <vprintf+0x60>
        s = va_arg(ap, char*);
    5bc4:	8b4e                	mv	s6,s3
      state = 0;
    5bc6:	4981                	li	s3,0
    5bc8:	b54d                	j	5a6a <vprintf+0x60>
    }
  }
}
    5bca:	70e6                	ld	ra,120(sp)
    5bcc:	7446                	ld	s0,112(sp)
    5bce:	74a6                	ld	s1,104(sp)
    5bd0:	7906                	ld	s2,96(sp)
    5bd2:	69e6                	ld	s3,88(sp)
    5bd4:	6a46                	ld	s4,80(sp)
    5bd6:	6aa6                	ld	s5,72(sp)
    5bd8:	6b06                	ld	s6,64(sp)
    5bda:	7be2                	ld	s7,56(sp)
    5bdc:	7c42                	ld	s8,48(sp)
    5bde:	7ca2                	ld	s9,40(sp)
    5be0:	7d02                	ld	s10,32(sp)
    5be2:	6de2                	ld	s11,24(sp)
    5be4:	6109                	addi	sp,sp,128
    5be6:	8082                	ret

0000000000005be8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    5be8:	715d                	addi	sp,sp,-80
    5bea:	ec06                	sd	ra,24(sp)
    5bec:	e822                	sd	s0,16(sp)
    5bee:	1000                	addi	s0,sp,32
    5bf0:	e010                	sd	a2,0(s0)
    5bf2:	e414                	sd	a3,8(s0)
    5bf4:	e818                	sd	a4,16(s0)
    5bf6:	ec1c                	sd	a5,24(s0)
    5bf8:	03043023          	sd	a6,32(s0)
    5bfc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    5c00:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    5c04:	8622                	mv	a2,s0
    5c06:	00000097          	auipc	ra,0x0
    5c0a:	e04080e7          	jalr	-508(ra) # 5a0a <vprintf>
}
    5c0e:	60e2                	ld	ra,24(sp)
    5c10:	6442                	ld	s0,16(sp)
    5c12:	6161                	addi	sp,sp,80
    5c14:	8082                	ret

0000000000005c16 <printf>:

void
printf(const char *fmt, ...)
{
    5c16:	711d                	addi	sp,sp,-96
    5c18:	ec06                	sd	ra,24(sp)
    5c1a:	e822                	sd	s0,16(sp)
    5c1c:	1000                	addi	s0,sp,32
    5c1e:	e40c                	sd	a1,8(s0)
    5c20:	e810                	sd	a2,16(s0)
    5c22:	ec14                	sd	a3,24(s0)
    5c24:	f018                	sd	a4,32(s0)
    5c26:	f41c                	sd	a5,40(s0)
    5c28:	03043823          	sd	a6,48(s0)
    5c2c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    5c30:	00840613          	addi	a2,s0,8
    5c34:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    5c38:	85aa                	mv	a1,a0
    5c3a:	4505                	li	a0,1
    5c3c:	00000097          	auipc	ra,0x0
    5c40:	dce080e7          	jalr	-562(ra) # 5a0a <vprintf>
}
    5c44:	60e2                	ld	ra,24(sp)
    5c46:	6442                	ld	s0,16(sp)
    5c48:	6125                	addi	sp,sp,96
    5c4a:	8082                	ret

0000000000005c4c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    5c4c:	1141                	addi	sp,sp,-16
    5c4e:	e422                	sd	s0,8(sp)
    5c50:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    5c52:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    5c56:	00003797          	auipc	a5,0x3
    5c5a:	9927b783          	ld	a5,-1646(a5) # 85e8 <freep>
    5c5e:	a805                	j	5c8e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    5c60:	4618                	lw	a4,8(a2)
    5c62:	9db9                	addw	a1,a1,a4
    5c64:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    5c68:	6398                	ld	a4,0(a5)
    5c6a:	6318                	ld	a4,0(a4)
    5c6c:	fee53823          	sd	a4,-16(a0)
    5c70:	a091                	j	5cb4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    5c72:	ff852703          	lw	a4,-8(a0)
    5c76:	9e39                	addw	a2,a2,a4
    5c78:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    5c7a:	ff053703          	ld	a4,-16(a0)
    5c7e:	e398                	sd	a4,0(a5)
    5c80:	a099                	j	5cc6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    5c82:	6398                	ld	a4,0(a5)
    5c84:	00e7e463          	bltu	a5,a4,5c8c <free+0x40>
    5c88:	00e6ea63          	bltu	a3,a4,5c9c <free+0x50>
{
    5c8c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    5c8e:	fed7fae3          	bgeu	a5,a3,5c82 <free+0x36>
    5c92:	6398                	ld	a4,0(a5)
    5c94:	00e6e463          	bltu	a3,a4,5c9c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    5c98:	fee7eae3          	bltu	a5,a4,5c8c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    5c9c:	ff852583          	lw	a1,-8(a0)
    5ca0:	6390                	ld	a2,0(a5)
    5ca2:	02059713          	slli	a4,a1,0x20
    5ca6:	9301                	srli	a4,a4,0x20
    5ca8:	0712                	slli	a4,a4,0x4
    5caa:	9736                	add	a4,a4,a3
    5cac:	fae60ae3          	beq	a2,a4,5c60 <free+0x14>
    bp->s.ptr = p->s.ptr;
    5cb0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    5cb4:	4790                	lw	a2,8(a5)
    5cb6:	02061713          	slli	a4,a2,0x20
    5cba:	9301                	srli	a4,a4,0x20
    5cbc:	0712                	slli	a4,a4,0x4
    5cbe:	973e                	add	a4,a4,a5
    5cc0:	fae689e3          	beq	a3,a4,5c72 <free+0x26>
  } else
    p->s.ptr = bp;
    5cc4:	e394                	sd	a3,0(a5)
  freep = p;
    5cc6:	00003717          	auipc	a4,0x3
    5cca:	92f73123          	sd	a5,-1758(a4) # 85e8 <freep>
}
    5cce:	6422                	ld	s0,8(sp)
    5cd0:	0141                	addi	sp,sp,16
    5cd2:	8082                	ret

0000000000005cd4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    5cd4:	7139                	addi	sp,sp,-64
    5cd6:	fc06                	sd	ra,56(sp)
    5cd8:	f822                	sd	s0,48(sp)
    5cda:	f426                	sd	s1,40(sp)
    5cdc:	f04a                	sd	s2,32(sp)
    5cde:	ec4e                	sd	s3,24(sp)
    5ce0:	e852                	sd	s4,16(sp)
    5ce2:	e456                	sd	s5,8(sp)
    5ce4:	e05a                	sd	s6,0(sp)
    5ce6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    5ce8:	02051493          	slli	s1,a0,0x20
    5cec:	9081                	srli	s1,s1,0x20
    5cee:	04bd                	addi	s1,s1,15
    5cf0:	8091                	srli	s1,s1,0x4
    5cf2:	0014899b          	addiw	s3,s1,1
    5cf6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    5cf8:	00003517          	auipc	a0,0x3
    5cfc:	8f053503          	ld	a0,-1808(a0) # 85e8 <freep>
    5d00:	c515                	beqz	a0,5d2c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    5d02:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    5d04:	4798                	lw	a4,8(a5)
    5d06:	02977f63          	bgeu	a4,s1,5d44 <malloc+0x70>
    5d0a:	8a4e                	mv	s4,s3
    5d0c:	0009871b          	sext.w	a4,s3
    5d10:	6685                	lui	a3,0x1
    5d12:	00d77363          	bgeu	a4,a3,5d18 <malloc+0x44>
    5d16:	6a05                	lui	s4,0x1
    5d18:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    5d1c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    5d20:	00003917          	auipc	s2,0x3
    5d24:	8c890913          	addi	s2,s2,-1848 # 85e8 <freep>
  if(p == (char*)-1)
    5d28:	5afd                	li	s5,-1
    5d2a:	a88d                	j	5d9c <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
    5d2c:	00009797          	auipc	a5,0x9
    5d30:	0dc78793          	addi	a5,a5,220 # ee08 <base>
    5d34:	00003717          	auipc	a4,0x3
    5d38:	8af73a23          	sd	a5,-1868(a4) # 85e8 <freep>
    5d3c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    5d3e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    5d42:	b7e1                	j	5d0a <malloc+0x36>
      if(p->s.size == nunits)
    5d44:	02e48b63          	beq	s1,a4,5d7a <malloc+0xa6>
        p->s.size -= nunits;
    5d48:	4137073b          	subw	a4,a4,s3
    5d4c:	c798                	sw	a4,8(a5)
        p += p->s.size;
    5d4e:	1702                	slli	a4,a4,0x20
    5d50:	9301                	srli	a4,a4,0x20
    5d52:	0712                	slli	a4,a4,0x4
    5d54:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    5d56:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    5d5a:	00003717          	auipc	a4,0x3
    5d5e:	88a73723          	sd	a0,-1906(a4) # 85e8 <freep>
      return (void*)(p + 1);
    5d62:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    5d66:	70e2                	ld	ra,56(sp)
    5d68:	7442                	ld	s0,48(sp)
    5d6a:	74a2                	ld	s1,40(sp)
    5d6c:	7902                	ld	s2,32(sp)
    5d6e:	69e2                	ld	s3,24(sp)
    5d70:	6a42                	ld	s4,16(sp)
    5d72:	6aa2                	ld	s5,8(sp)
    5d74:	6b02                	ld	s6,0(sp)
    5d76:	6121                	addi	sp,sp,64
    5d78:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    5d7a:	6398                	ld	a4,0(a5)
    5d7c:	e118                	sd	a4,0(a0)
    5d7e:	bff1                	j	5d5a <malloc+0x86>
  hp->s.size = nu;
    5d80:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    5d84:	0541                	addi	a0,a0,16
    5d86:	00000097          	auipc	ra,0x0
    5d8a:	ec6080e7          	jalr	-314(ra) # 5c4c <free>
  return freep;
    5d8e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    5d92:	d971                	beqz	a0,5d66 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    5d94:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    5d96:	4798                	lw	a4,8(a5)
    5d98:	fa9776e3          	bgeu	a4,s1,5d44 <malloc+0x70>
    if(p == freep)
    5d9c:	00093703          	ld	a4,0(s2)
    5da0:	853e                	mv	a0,a5
    5da2:	fef719e3          	bne	a4,a5,5d94 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
    5da6:	8552                	mv	a0,s4
    5da8:	00000097          	auipc	ra,0x0
    5dac:	b66080e7          	jalr	-1178(ra) # 590e <sbrk>
  if(p == (char*)-1)
    5db0:	fd5518e3          	bne	a0,s5,5d80 <malloc+0xac>
        return 0;
    5db4:	4501                	li	a0,0
    5db6:	bf45                	j	5d66 <malloc+0x92>
