#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <sys/wait.h>
#include <stdio.h>
#include <fcntl.h>

#include "builtin.h"
#include "execute.h"
#include "tests/syscall_mock.h"

#define READ 0
#define WRITE 1

static void change_fd_in(char* red_in){

    if (red_in == NULL) 
        return;

    int file_in = open(red_in, O_RDONLY, S_IRUSR | S_IWUSR);
    dup2(file_in, STDIN_FILENO);
    close(file_in);

}

static void change_fd_out(char* red_out){
    
    if (red_out == NULL)
        return;

    int file_out = open(red_out, O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR);
    dup2(file_out, STDOUT_FILENO);  
    close(file_out);

}

void execute_pipeline(pipeline apipe, bool *is_exit){
    assert(apipe != NULL);  

    int err = 0;

    if (pipeline_is_empty(apipe)){
        return;
    }

    if (builtin_is_internal(pipeline_front(apipe))){
        builtin_run(pipeline_front(apipe), is_exit);
        return;
    } 

    if (pipeline_length(apipe) == 1){
        
        int pid1 = fork();
        
        if (pid1 < 0){
            perror("mybash> ");
            return;
        }
    
        char* red_out = scommand_get_redir_out(pipeline_front(apipe));
        char* red_in = scommand_get_redir_in(pipeline_front(apipe));
        char **argv = scommand_to_array(pipeline_front(apipe));
        pipeline_pop_front(apipe);

        if (pid1 == 0){

            change_fd_out(red_out);
            change_fd_in(red_in);
            
            err = execvp(argv[0], argv); 

            if(err == -1){
                printf("mybash> : command not found\n");
                exit(EXIT_SUCCESS);
            }
        }

        free(argv);

        if (pipeline_get_wait(apipe)){
            waitpid(pid1, NULL, 0);
        }   
        signal(SIGCHLD, SIG_IGN);
    }


    if(pipeline_length(apipe) == 2){
        int fd[2];

        if (pipe(fd) == -1){
            perror("mybash> ");
            return ;
        }

        char* red_out_1 = scommand_get_redir_out(pipeline_front(apipe));
        char* red_in_1 = scommand_get_redir_in(pipeline_front(apipe));

        char** array_1 = scommand_to_array(pipeline_front(apipe));
        pipeline_pop_front(apipe);

        char* red_out_2 = scommand_get_redir_out(pipeline_front(apipe));
        char* red_in_2 = scommand_get_redir_in(pipeline_front(apipe));

        char** array_2 = scommand_to_array(pipeline_front(apipe));
        pipeline_pop_front(apipe);

        int pid1 = fork();
        
        if (pid1 < 0){
            perror("mybash> ");
            return ;
        }

        if (pid1 == 0){
            
            dup2(fd[WRITE], STDOUT_FILENO);
            close(fd[READ]);
            close(fd[WRITE]);

            change_fd_out(red_out_1);
            change_fd_in(red_in_1);

            err = execvp(array_1[0], array_1);

            if(err == -1){
                printf("mybash> : command not found\n");
                exit(EXIT_SUCCESS);
            } 
        }
        
        int pid2 = fork();
    
        if (pid1 < 0){
            perror("mybash> ");
            return ;
        }

        if (pid2 == 0){

            dup2(fd[READ], STDIN_FILENO);
            close(fd[WRITE]);
            close(fd[READ]);

            change_fd_out(red_out_2);   
            change_fd_out(red_in_2);

            err = execvp(array_2[0], array_2);
            
            if(err == -1){
                printf("mybash> : command not found\n");
                exit(EXIT_SUCCESS);
            } 
        }

        close(fd[WRITE]);
        close(fd[READ]);
        
        free(array_1);
        free(array_2);

        if(pipeline_get_wait(apipe)){
            waitpid(pid1,NULL,0);
            waitpid(pid2,NULL,0);
        }
        signal(SIGCHLD, SIG_IGN);   
    }

    if(pipeline_length(apipe) > 2){
    int pid;
    char** array_1;
    char* red_out;
    char* red_in;
    int fd[2];
    uint len = pipeline_length(apipe); 

    if (pipe(fd) == -1){
        perror("mybash> ");
        return ;
    }

    for(uint i = 0; i < len;i++){
        pid = fork();

        if (pid < 0){
                perror("mybash> ");
                return;
        }
        
        if(i == len-1){
                red_out = scommand_get_redir_out(pipeline_front(apipe));
                red_in = scommand_get_redir_in(pipeline_front(apipe));
                array_1 = scommand_to_array(pipeline_front(apipe));
                pipeline_pop_front(apipe);

                if(pid == 0){
                    dup2(fd[READ], STDIN_FILENO);
                    close(fd[WRITE]);
                    close(fd[READ]);

                    change_fd_out(red_out);   
                    change_fd_out(red_in);

                    err = execvp(array_1[0], array_1);
                    
                    if(err == -1){
                        printf("mybash> : command not found\n");
                        exit(EXIT_SUCCESS);
                    } 
                }
            } else if(i == 0) {
                red_out = scommand_get_redir_out(pipeline_front(apipe));
                red_in = scommand_get_redir_in(pipeline_front(apipe));
                array_1 = scommand_to_array(pipeline_front(apipe));
                pipeline_pop_front(apipe);

                if (pid == 0){
                    
                    dup2(fd[WRITE], STDOUT_FILENO);
                    close(fd[READ]);
                    close(fd[WRITE]);

                    change_fd_out(red_out);
                    change_fd_in(red_in);

                    err = execvp(array_1[0], array_1);

                    if(err == -1){
                        printf("mybash> : command not found\n");
                        exit(EXIT_SUCCESS);
                    } 
                }
            } else {
                red_out = scommand_get_redir_out(pipeline_front(apipe));
                red_in = scommand_get_redir_in(pipeline_front(apipe));
                array_1 = scommand_to_array(pipeline_front(apipe));
                pipeline_pop_front(apipe);

                if(pid == 0){
                    dup2(fd[READ], STDIN_FILENO);
                    dup2(fd[WRITE],STDOUT_FILENO);
                    close(fd[WRITE]);
                    close(fd[READ]);

                    change_fd_out(red_out);   
                    change_fd_out(red_in);

                    err = execvp(array_1[0], array_1);
                    
                    if(err == -1){
                        printf("mybash> : command not found\n");
                        exit(EXIT_SUCCESS);
                    } 
                }
            }
        }
        close(fd[WRITE]);
        close(fd[READ]);

        free(array_1);

        if(pipeline_get_wait(apipe)){
        waitpid(pid,NULL,0);
        }
        signal(SIGCHLD, SIG_IGN);   
    }
}