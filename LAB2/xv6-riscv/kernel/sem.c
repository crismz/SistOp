#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "sem.h"

#define MAX_SEM 32

/*  
    One of them will run first and acquire the lock that sleep
    was called with, and (in the case of pipes) read whatever data is waiting in the pipe.
    The other processes will find that, despite being woken up, there is no data to be read.
    From their point of view the wakeup was ‘‘spurious,’’ and they must sleep again. For
    this reason sleep is always called inside a loop that checks the condition.
    
*/
struct semaphore sem_array[MAX_SEM];

int
sem_open(int sem, int value)
{   
    acquire(&sem_array[sem].lk);
    if (sem > MAX_SEM) {
        return -1;
    }
    sem_array[sem].value = value;

    sem_array[sem].init_value = value; 
    
    release(&sem_array[sem].lk);         
    return 0;
}

int
sem_down(int sem)
{
    acquire(&sem_array[sem].lk);

    if (sem_array[sem].value > 0) {
        sem_array[sem].value = sem_array[sem].value - 1;
    } else {
        while (sem_array[sem].value <= 0){
            sleep(&sem_array[sem], &sem_array[sem].lk);
        }
        sem_array[sem].value = sem_array[sem].value - 1;
    }

    release(&sem_array[sem].lk);

    return 0;
}

int
sem_up(int sem)
{
    // Wakeup must be called while holding a lock
    // that guards the condition
    acquire(&sem_array[sem].lk);
    if(sem_array[sem].init_value == sem_array[sem].value){
        release(&sem_array[sem].lk);
        return -1;
    }
    sem_array[sem].value = sem_array[sem].value + 1 ;
    wakeup(&sem_array[sem]);
    release(&sem_array[sem].lk);
    return 0;
}

int 
sem_close(int sem)
{
    if(sem_array[sem].lk.locked == 1){
        return -1;
    }
    sem_array[sem].value = 0;
    sem_array[sem].init_value = 0;
    return 0;
}
