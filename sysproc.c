#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  // struct proc *p = myproc();
  // printf("%d %s: sys_exit, exit code: %d\n", p->pid, p->name, n); // 添加日志输出
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  uint64 result = fork();
  // struct proc *p = myproc();
  // printf("%d %s: sys_fork, result: %d\n", p->pid, p->name, (int)result); // 添加日志输出
  return result;
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  uint64 result = wait(p);
  // struct proc *proc = myproc();
  // printf("%d %s: sys_wait, result: %d\n", proc->pid, proc->name, (int)result); // 添加日志输出
  return result;
}

static int sbrk_call_count = 0;

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  sbrk_call_count++;
  printf("sbrk called for the %d time\n", sbrk_call_count);
  if(growproc(n) < 0) {
    return -1;
  }
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  uint64 result = kill(pid);
  // struct proc *p = myproc();
  // printf("%d %s: sys_kill, target pid: %d, result: %d\n", p->pid, p->name, pid, (int)result); // 添加日志输出
  return result;
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}