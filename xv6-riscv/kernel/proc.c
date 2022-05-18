#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"


struct cpu cpus[NCPU]; //was here

struct proc proc[NPROC]; //was here

struct proc *initproc; //was here

int nextpid = 1; //was here
struct spinlock pid_lock;

int cpus_ll[NCPU]; //array of all cpus,s.t the value in index x is the first 
                  //process in the runnable list for cpu x (who's cpu's number is x).
struct spinlock cpus_head[NCPU]; //array with the dummy heads of the list. 


//the following are the indexes in the array "proc" of the heads of those lists.
//upon initialization, while they are still empty, it's -1.
//whenever a process is added, it's next field should be set to -1.
int sleeping= -1; // index to the first sleeping process in the sleeping list
int zombie= -1; // index to the first zombie process in the zombie list
int unused= -1; // index to the first unused process in the unused list
 
 //the following are the dummy heads of the sleeping, zombie and unused
struct spinlock sleeping_head;
struct spinlock zombie_head;
struct spinlock unused_head;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S
extern uint64 cas(volatile void *addr, int expected, int newval); // addad as ordered in TASK #2

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

int
remove_cs(struct proc *pred, struct proc *curr, struct proc *p){ //created
int ret=-1;
// while (curr->index <= p->index) {
while (curr->next != -1) {
  if ( p->index == curr->index) {
      pred->next = curr->next;
      ret = curr->index;
      release(&pred->linked_list_lock);
      return ret;
    }
    release(&pred->linked_list_lock);
    //printf("%d\n",132);
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    pred = curr;
    curr = &proc[curr->next];
    //printf("pred: %d curr: %d\n", pred->index, curr->index);
    acquire(&curr->linked_list_lock);
    //printf("after lock\n");
  }
  panic("item not found");
}

int remove_from_list(int p_index, int *list,struct spinlock lock_list){
  int ret=-1;
  acquire(&lock_list);
  if(*list==-1){
    panic("the remove from list faild.\n");
  }
  else{
    
    if(proc[*list].next==-1){ // only one is on the list
        if(p_index==*list){
          //acquire(proc[p_index].linked_list_lock);
          *list = -1;
          release(&lock_list);
          ret=p_index;
          return ret;
        }
    }
    else {
      struct proc *pred;
      struct proc *curr;
      pred= &proc[*list];
      curr= &proc[pred->next];
      acquire(&pred->linked_list_lock);
      if (curr->next == -1 && curr->index == p_index){
        pred->next = -1;
        ret = p_index;
        return ret;
      }
      acquire(&curr->linked_list_lock);
      if (pred->index == p_index){
        *list = curr->index;
        pred->next = -1;  //the caller will insert to the new list
      }
      else {
      ret=remove_cs(pred, curr, &proc[p_index]);
      }
      release(&curr->linked_list_lock);
      release(&pred->linked_list_lock);
    }
  }
  release(&lock_list);
  return ret;
}

int
insert_cs(struct proc *pred, struct proc *p){  //created
  //struct proc *curr=pred; 
  while (pred->next != -1) {
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    release(&pred->linked_list_lock); // caller acquired
    pred = &proc[pred->next];
    acquire(&pred->linked_list_lock);
    }
    //printf("exitloop\n");
    pred->next = p->index;
    //printf("the pred is:%d pred->next:%d p->index=%d\n",pred->index,pred->next,p->index);
    //printf("the p->index is:%d\n",p->index);
    p->next=-1;
    release(&pred->linked_list_lock);
    return p->index;
}

int
insert_to_list(int p_index, int *list,struct spinlock lock_list){
  //printf("entered insert_to_list.\n");
  int ret=-1;
  if(*list==-1){
    //printf("here\nlist pointer:  %d\n", *list);
    acquire(&lock_list);
    *list=p_index;
    acquire(&proc[p_index].linked_list_lock);
    proc[p_index].next=-1;
    release(&proc[p_index].linked_list_lock);
    ret=p_index;
    //printf("here\nlist pointer: %d, list next %d\n",*list, proc[*list].next);
    release(&lock_list);
  }
  else{
    acquire(&lock_list);
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    //printf("the index of the first prosses in the list is:%d %d\n",*list,pred->next);
    acquire(&pred->linked_list_lock);
    //curr=&proc[pred->next];
    //acquire(&curr->lock);
    ret=insert_cs(pred, &proc[p_index]);
    //release(&curr->lock);
    // release(&pred->linked_list_lock);
    //printf("ret is:%d \n",ret);  
    release(&lock_list);
}
if(ret==-1){
  panic("insert is failed");
}
return ret;
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void
procinit(void) //changed
{
  printf("entered procinit\n");
  struct proc *p;

  for (int i = 0; i<NCPU; i++){
    cas(&cpus_ll[i],0,-1); 
}
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  initlock(&sleeping_head,"sleeping head");
  initlock(&zombie_head,"zombie head");
  initlock(&unused_head,"unused head");
  
  int i=0; //added
  for(p = proc; p < &proc[NPROC]; p++) {
      p->kstack = KSTACK((int) (p - proc));
      //added:
      p->state= UNUSED; 
      p->index=i; 
      initlock(&p->lock, "proc");
      initlock(&p->linked_list_lock, "inbar");
      i++;
      insert_to_list(p->index, &unused,unused_head);
      //printf("the value of the index is:%d\n",i);
  }
  printf("finished procinit\n");
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) { 
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() { //changed as ordered in task 2
  int pid;
  do {
      pid = nextpid;
  } while(cas(&nextpid, pid, pid+1));

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void) //only added printings for debudding
{
  printf("entered allocproc\n");
  struct proc *p;
  //printf("the head of the unused list is %d ,and the next one is %d\n",unused,proc[unused].next);
  if(unused != -1){
    p = &proc[unused];
    acquire(&p->lock);
    goto found;
    } 
 
  return 0;

found:
  p->pid = allocpid();
  remove_from_list(p->index,&unused,unused_head);
  p->state = USED;
 // printf("%s\n", p->state);

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    printf("exit allocproc in 1.\n");
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    printf("exit allocproc in 2.\n");
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  printf("exit allocproc in 3.\n");
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p) //changed
{
  printf("entered freeproc\n");
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  //changes:
 remove_from_list(p->index,&zombie,zombie_head);
 
  p->state = UNUSED;
  insert_to_list(p->index,&unused,unused_head);
  printf("exiting from freeproc\n");
}


// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void) //changed
{
  printf("entered userinit\n");
  struct proc *p;

  p = allocproc();
  //printf("userinit, p->state= %d\n", p->state);
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  p->state = RUNNABLE;
 
  insert_to_list(p->index,&cpus_ll[0],cpus_head[0]);
  release(&p->lock);
  printf("exiting from userinit\n");
 
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void) //changed
{
  printf("entered fork\n");
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  np->cpu_num=p->cpu_num; //giving the child it's parent's cpu_num (the only change)
  initlock(&p->linked_list_lock,"inbar");
  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  insert_to_list(np->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
  release(&np->lock);

  printf("finished fork\n");
  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  printf("entered exit\n");
  //printf("the number of locks is:%d\n",mycpu()->noff);
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  insert_to_list(p->index,&zombie,zombie_head);

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  printf("entered wait\n");
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            printf("exited wait1\n");
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          printf("exited wait2\n");
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      printf("exited wait3\n");
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
  
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void) //changed
{
  printf("entered scheduler\n");
  struct proc *p=myproc();
  struct cpu *c = mycpu();
  
  printf("the cpuid=%d\n",cpuid());
  c->proc = 0;
  for(;;){
    
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 
      // printf("the cpus_ll[%d]=%d with the state of:%d\n",cpuid(),cpus_ll[cpuid()], proc[cpus_ll[cpuid()]].state);
      // acquire(&cpus_head[cpuid()]);
      p = &proc[cpus_ll[cpuid()]];
      // printf("the pid of p after choosing:%d\n",p->pid);
      // printf("p.next= %d, pid= %d\n", p->next, p->pid);
      // release(&cpus_head[cpuid()]);
      remove_from_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
      acquire(&p->lock);
        //printf("after acquire\n");
        p->state = RUNNING;
        c->proc = p;
        // printf("enter swtc with prosses index:%d\n",p->index);
        swtch(&c->context, &p->context);
    
      

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
        release(&p->lock);
   }
   
    // release(&cpus_head[cpuid()]);
   
  }
}
//   }
// }


// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1){
    panic("sched locks");
  }
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  printf("entered yield\n");
  struct proc *p = myproc();
  insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
  printf("exit yield\n");
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  //printf("entered sleep\n");
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  insert_to_list(p->index,&sleeping,sleeping_head);
  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  //printf("the number of locks is:%d\n",mycpu()->noff);
  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);

}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;
  if (sleeping == -1){
    return;
  } // if no one is sleeping - do nothing
  //acquire(&sleeping_head);
  p = &proc[sleeping];
  if (p->next == -1){ // there is only one sleeper
    if(p != myproc()){ 
      acquire(&p->lock);
      if(p->chan == chan && p->state == SLEEPING) {
        remove_from_list(p->index, &sleeping, sleeping_head);
        p->state = RUNNABLE;
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
      }
      release(&p->lock);
    }  
  }
  while(p->next != -1 ) { // loop through all sleepers
    if(p != myproc()){
      //printf("process p->pid = %d\n", p->pid);
      acquire(&p->lock);
      if(p->chan == chan && p->state==SLEEPING) {
        remove_from_list(p->index,&sleeping,sleeping_head);
        p->state = RUNNABLE;
        insert_to_list(p->index,&cpus_ll[p->cpu_num],cpus_head[p->cpu_num]);
      }
      release(&p->lock);
    }
    p++;
  }
}



// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  //printf("entered either_copyout\n");
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  //printf("entered either_copyin\n");
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}


int set_cpu(int cpu_num){ //added as orderd
  struct proc *p= myproc();  
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    yield();
    return cpu_num;
  }
  return 0;
}

int get_cpu(){ //added as orderd
  struct proc *p=myproc();
  int ans=0;
  cas(&ans, ans, p->cpu_num);
    return ans;
}
