#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"


struct cpu cpus[NCPU];


struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

int cpus_ll[CPUS]; //array of all cpus,s.t the value in index x is the first 
                  //process in the runnable list for cpu x (who's cpu's number is x).
struct spinlock cpus_head[CPUS]; //array with the dummy heads of the list. 

uint64 cpu_usage[CPUS]; // array of number of ready procs


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

// int leastUsedCPU(){ // get the CPU with least amount of processes
//   uint64 min = 4294967295;
//   int id = 0;
//   int idMin = 0;
//   for (uint64 * i = cpu_usage; i < &cpu_usage[CPUS]; i++){
//     if (*i < min){
//       min = *i;
//       idMin = id;
//     }     
//     id++;
//   }
//   printf("chosen cpu %d\n", idMin);
//   return idMin;
// }
int leastUsedCPU(){ // get the CPU with least amount of processes
  uint64 min = cpus[0].admittedProcs;
  int id = 0;
  int idMin = 0;
  for (struct cpu * c = cpus; c < &cpus[CPUS]; c++){
    uint64 procsNum = c->admittedProcs;
    if (procsNum < min){
      min = procsNum;
      idMin = id;
    }     
    id++;
  }
  return idMin;
}


int
remove_from_list(int to_remove, int* head, struct spinlock *lock){

  acquire(lock);
  if(*head == -1){
    release(lock);
    return 0;
  }
  release(lock);

  struct proc *p = 0;

  acquire(lock);
  if(*head == to_remove){
    p = &proc[*head];
    acquire(&p->linked_list_lock);
    *head = p->next;
    release(&p->linked_list_lock);

    release(lock);
    return 1;
  }
  release(lock);
 
  int not_in_list = 0;
  struct proc *pred_proc = &proc[*head];
  acquire(&pred_proc->linked_list_lock);
  p = &proc[pred_proc->next];
  acquire(&p->linked_list_lock);

  int stop = 0;
  while(!stop){

    if (pred_proc->next == -1){
      stop = 1;
      not_in_list = 1;
      continue;
    }
      
    if(p->index == to_remove){
      stop = 1;
      pred_proc->next = p->next;
      continue;
    }
    release(&pred_proc->linked_list_lock);

    
    pred_proc = p;
    p = &proc[p->next];
    acquire(&p->linked_list_lock);
  }
  release(&pred_proc->linked_list_lock); // last one to release on the way out
  release(&p->linked_list_lock); // last one to release on the way out
  if (not_in_list)
    return 0;
  return 1;
}

int
remove_cs(struct proc *pred, struct proc *curr, struct proc *p){ //created
int ret = -1;
int curr_inx = curr->index;
while (curr_inx != -1) {
  if ( p->index == curr->index) {
      pred->next = curr->next;
      ret = curr->index;
      release(&curr->linked_list_lock);
      release(&pred->linked_list_lock);
      return ret;
    }
    release(&pred->linked_list_lock);
    pred = curr;
    curr_inx =curr->next;
    if(curr_inx!=-1){
      curr = &proc[curr->next];
      acquire(&curr->linked_list_lock);
    }
    else{
      release(&curr->linked_list_lock);
    }
  }
  return -1;
}

int remove_from_list2(int p_index, int *list, struct spinlock *lock_list){
  int ret=-1;
  acquire(lock_list);
  if(*list==-1){
    release(lock_list);
    panic("the remove from list faild.\n");
  }
  else{
        if(p_index == *list){
          *list = proc[p_index].next;
          release(lock_list);
          ret=p_index;
          return ret;
        }
    else{
      release(lock_list);
      struct proc *pred;
      struct proc *curr;
      pred = &proc[*list];
      acquire(&pred->linked_list_lock);
      if(pred->next==-1)
      {
        release(&pred->linked_list_lock);
        panic("the item is not in the list\n");
      }
      curr = &proc[pred->next];
      acquire(&curr->linked_list_lock);     
      ret = remove_cs(pred, curr, &proc[p_index]);
    }
  }
  return ret;
}

int
insert_cs(struct proc *pred, struct proc *p){  //created
  int curr = pred->index; 
  struct spinlock *pred_lock;
  while (curr != -1) {
    //printf("the index of pred is %d ,its state is:%d, its cpu_num is %d\n ",pred->index,pred->state,pred->cpu_num);
    if(pred->next!=-1){
      pred_lock=&pred->linked_list_lock; // caller acquired
      pred = &proc[pred->next];
      release(pred_lock);
      acquire(&pred->linked_list_lock);
    }
    curr = pred->next;
    }
    pred->next = p->index;
    release(&pred->linked_list_lock);      
    p->next=-1;
    return p->index;
}

int
insert_to_list(int p_index, int *list,struct spinlock *lock_list){;
  int ret=-1;
  acquire(lock_list);
  if(*list==-1){
    *list=p_index;
    acquire(&proc[p_index].linked_list_lock);
    proc[p_index].next=-1;
    release(&proc[p_index].linked_list_lock);
    ret = p_index;
    release(lock_list);
  }
  else{
    release(lock_list);
    struct proc *pred;
  //struct proc *curr;
    pred=&proc[*list];
    acquire(&pred->linked_list_lock);
    ret = insert_cs(pred, &proc[p_index]);
  }
if(ret == -1){
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
  struct proc *p;

  for (int i = 0; i<CPUS; i++){
    cpus_ll[i] = -1;
    // cpu_usage[i] = 0;    // set initial cpu's admitted to 0
    cpus[i].admittedProcs = 0;
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
      p->state = UNUSED; 
      p->index = i;
      p->next = -1;
      p->cpu_num = 0;
      initlock(&p->lock, "proc");
     // char name[1] ;
      char * name = "inbar";
      initlock(&p->linked_list_lock, name);
      i++;
      insert_to_list(p->index, &unused, &unused_head);
      //printf("the value of the index is:%d\n",i);
  }

  
  
  //printf("the head of the unused list is %d, and the value of next is:%d\n ",unused,proc[unused].next);
      
  //printf("finished procinit\n");
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

void
inc_cpu_usage(int cpu_num){
  struct cpu* c = &cpus[cpu_num];
  uint64 usage;
  do {
    usage = c->admittedProcs;
  } while (cas(&c->admittedProcs, usage, usage + 1));
}

// int
// increment(struct proc* p){
//   struct cpu* c = &cpus[p->cpu_num];
//   uint64 count;
//     do {
//       count = c->counter;
//     } while (cas(&c->counter, count, count+1));
//   return count;
// }

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
  //printf("entered allocproc\n");
  struct proc *p;
  if(unused != -1){
    p = &proc[unused];
    remove_from_list(p->index,&unused, &unused_head);
    acquire(&p->lock);
    goto found;
    } 
 
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    //printf("exit allocproc in 1.\n");
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    //printf("exit allocproc in 2.\n");
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  //printf("exit allocproc in 3.\n");
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p) //changed
{
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

 remove_from_list(p->index, &zombie, &zombie_head);

  p->state = UNUSED;

  insert_to_list(p->index, &unused, &unused_head);
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
  // printf("entered userinit\n");
  struct proc *p;

  p = allocproc();
  //printf("come back to userinit from allocproc with state of:%d\n",p->state);
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
  insert_to_list(p->index, &cpus_ll[0], &cpus_head[0]);
  // cas(&cpu_usage[0], cpu_usage[0], cpu_usage[0]+1);
  inc_cpu_usage(0);
  p->state = RUNNABLE;
  release(&p->lock);

 
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
fork(void)
{
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

  #ifdef OFF
  np->cpu_num = p->cpu_num; //giving the child it's parent's cpu_num
  #endif

  #ifdef ON
  int cpui = leastUsedCPU();
  np->cpu_num = cpui;
  // cas(&cpu_usage[cpui], cpu_usage[cpui], cpu_usage[cpui]+1);
  inc_cpu_usage(cpui);
  #endif


  initlock(&np->linked_list_lock, np->name);
  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  // insert_to_list(np->index, &cpus_ll[0], &cpus_head[0]);
  insert_to_list(np->index, &cpus_ll[np->cpu_num], &cpus_head[np->cpu_num]);
  
  release(&np->lock);
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
  //printf("entered exit\n");
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
  //printf("before insertind %d to the zombie list. its state is:%d",p->index);
  p->state = ZOMBIE;
  insert_to_list(p->index, &zombie, &zombie_head);
  //printf("doen with inserting the prosses index %d to the zombie list.\n",ret);

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
  //printf("entered wait\n");
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
            //printf("exited wait1\n");
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          //printf("exited wait2\n");
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      //printf("exited wait3\n");
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
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    while (cpus_ll[cpuid()] != -1){   // if no one is RUNNABL, skip swtch 

      p = &proc[cpus_ll[cpuid()]];
      acquire(&p->lock);
      int removed = remove_from_list(p->index, &cpus_ll[cpuid()], &cpus_head[cpuid()]);
      if(removed == -1)
        panic("could not remove");
      p->state = RUNNING;
      c->proc = p;
      swtch(&c->context, &p->context);

      // BUG
      if(p->state != ZOMBIE){
        goto b;
        b:
        // printf("stop\n");
        // insert_to_list(p->index,&cpus_ll[cpuid()],cpus_head[cpuid()]);
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
      }
        // Process is done running for now.
        // It should have changed its p->state before coming back.
      c->proc = 0;
      release(&p->lock);
   }
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
  //printf("entered sched\n");
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
  struct proc *p = myproc();

  acquire(&p->lock);
  p->state = RUNNABLE;
  insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
  sched();
  release(&p->lock);
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
  struct proc *p = myproc();
  // Must acquire p->lock in order to change p->state and then call sched.
  // Once we hold p->lock, we can be guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock), so it's okay to release lk.
  // Go to sleep.
  // cas(&p->state, RUNNING, SLEEPING);
  insert_to_list(p->index, &sleeping, &sleeping_head);
  p->chan = chan;
  // if (p->state == RUNNING){
  //   p->state = SLEEPING;
  //   }
  while(!cas(&p->state, RUNNING, SLEEPING));
  release(lk);
  acquire(&p->lock);  //DOC: sleeplock1
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
  }
  p = &proc[sleeping];
  int curr= proc[sleeping].index;
  while(curr !=- 1) { // loop through all sleepers
    if(p != myproc()){
      acquire(&p->lock);
      if(p->chan == chan && p->state == SLEEPING) {
        remove_from_list(p->index, &sleeping, &sleeping_head);
        p->chan=0;
        while(!cas(&p->state, SLEEPING, RUNNABLE));
        #ifdef ON
        int cpui = leastUsedCPU();
        p->cpu_num = cpui;
        release(&p->lock);
        // while (!cas(&cpus[p->cpu_num].admittedProcs, cpus[p->cpu_num].admittedProcs, cpus[p->cpu_num].admittedProcs + 1))
        inc_cpu_usage(p->cpu_num);
        #endif
        insert_to_list(p->index,&cpus_ll[p->cpu_num],&cpus_head[p->cpu_num]);
        
      }
      #ifdef OFF
      release(&p->lock);
      #endif
    }
    if(p->next !=- 1)
      p = &proc[p->next];
    curr=p->next;
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
      // if(p->state == SLEEPING){
      if(!cas(&p->state, SLEEPING, RUNNABLE)){  //because cas returns 0 when succesful
        // Wake process from sleep().
        remove_from_list(p->index, &sleeping, &sleeping_head);
        p->state = RUNNABLE;
      release(&p->lock);
      insert_to_list(p->index, &cpus_ll[p->cpu_num], &cpus_head[p->cpu_num]);
      }
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
either_copyout(int user_dst, uint64 dst, void *src, uint64 len){

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
    printf("%d %s %s %d", p->pid, state, p->name, p->cpu_num);
    printf("\n");
  }
}


int set_cpu(int cpu_num){ //added as orderd
// printf("%d\n", 12);
  struct proc *p= myproc();  
  if(cas(&p->cpu_num, p->cpu_num, cpu_num)){
    yield();
    return cpu_num;
  }
  return 0;
}

int get_cpu(){ //added as orderd
// printf("%d\n", 13);
  struct proc *p = myproc();
  int ans=0;
  cas(&ans, ans, p->cpu_num);
    return ans;
}

// int cpu_process_count (int cpu_num){
//   return cpu_usage[cpu_num];
// }
int cpu_process_count(int cpu_num){
  struct cpu* c = &cpus[cpu_num];
  uint64 procsNum = c->admittedProcs;
  return procsNum;
}
