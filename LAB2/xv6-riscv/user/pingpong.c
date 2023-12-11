#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/syscall.h"

int
main (int argc, char **argv)
{   
    int N = atoi(argv[1]);    
    sem_open(0,1);
    sem_open(1,1);
    sem_down(1);

    int i,j;
    int pid = fork();
   
    if (pid == 0){
        for(i=0; i<N; i++) {
            sem_down(0);
            printf("    PING\n");  
            sem_up(1);
        }
    } else {    
        for(j=0; j<N; j++) {
            sem_down(1);
            printf("  PONG\n");
            sem_up(0);
        }
    } 
    sem_close(1);
    sem_close(0);
    return 0;
}
