//
// File-system system calls.
// Mostly argument checking, since we don't trust
// user code, and calls into file.c and fs.c.
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
//#include "stat.h"
#include "spinlock.h"
#include "proc.h"
// #include "fs.h"
// #include "sleeplock.h"
// #include "file.h"
// #include "fcntl.h"

uint64
sys_write(void)
{
  int n;
  uint64 src;
  int i;
  
  // 获取系统调用参数：文件描述符(忽略)、源地址、字节数
  argaddr(1, &src);
  argint(2, &n);
  
  // 直接实现consolewrite的功能，忽略文件描述符
  for(i = 0; i < n; i++){
    char c;
    if(either_copyin(&c, 1, src+i, 1) == -1)
      break;
    uartputc(c);
  }
  
  return i;
}