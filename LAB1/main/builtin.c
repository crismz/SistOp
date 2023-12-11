#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "strextra.h"
#include "builtin.h"
#include "tests/syscall_mock.h"

static bool cmd_is_help(scommand cmd){
    return scommand_length(cmd) == 1 && streq(scommand_front(cmd), "help");
}

static bool cmd_is_exit(scommand cmd){
    return scommand_length(cmd) == 1 && streq(scommand_front(cmd), "exit");
}

static bool cmd_is_cd(scommand cmd){
    return streq(scommand_front(cmd), "cd");
}

bool builtin_is_internal(scommand cmd){

    assert(cmd != NULL);

    return ( cmd_is_cd(cmd)   ||
             cmd_is_exit(cmd) ||
             cmd_is_help(cmd));
}

bool builtin_alone(pipeline p){
    return (pipeline_length(p) == 1 && builtin_is_internal(pipeline_front(p)));
}

static void run_help(void){
    printf ("\n"
    "MYBASH:                                                                \n"
    "                                                                       \n"
    " Members:                                                              \n"
    "              Santiago Troiano                                         \n" 
    "              Cristian Ariel Muñoz                                     \n"
    "              Santiago Torres                                          \n"
    "              Damian Feigelmuller                                      \n"
    "                                                                       \n"
    " Builtin commands:                                                     \n"
    "                                                                       \n"
    "   cd                                                                  \n"
    "     Description:                                                      \n"
    "       Change current working directory to DIR                         \n"
    "     Usage:                                                            \n"        
    "       cd ""\"DIR\"                                                    \n"
    "                                                                       \n"
    "   exit                                                                \n"
    "      Description                                                      \n"    
    "         Terminates myBash shell process                               \n"
    "      Usage:                                                           \n"
    "         exit                                                          \n"
    "                                                                       \n"
    "   help                                                                \n"
    "      Description                                                      \n"    
    "         Prints useful info about MyBash                               \n"
    "      Uso:                                                             \n"
    "         help                                                          \n"
    "                                                                       \n");
}   
    
void builtin_run(scommand cmd, bool *is_exit){
    assert(builtin_is_internal(cmd));

    if (cmd_is_help(cmd)) {
        run_help();
    }

    if (cmd_is_exit(cmd)){
        *is_exit = true;
    }

    if (cmd_is_cd(cmd)){
        
        if (scommand_length(cmd) > 2){
            perror("mybash> : cd");
        }

        scommand_pop_front(cmd);                       // We dont neet "cd" anymore
        int chd;                                       // For error handling
        char* home_path = getenv("HOME");              // home/usr

        if (scommand_is_empty(cmd)){
            chd = chdir(home_path);
        } else {
            char* desired_path = scommand_front(cmd);      // cd command input
            if (strlen(desired_path) == 1){   
                desired_path = scommand_front(cmd);        // This case sends us to home/"usr"

                if (streq(desired_path, "~")){
                    chd = chdir(home_path);
                }

                else if (streq(desired_path, ".")){
                    printf("%s\n", getcwd(home_path, MAX_BUFF));
                }

                else {
                    chd = chdir(desired_path);
                }
            }
            
            else if (strlen(desired_path) > 1){

                if (desired_path[0] == '~' && 
                        desired_path[1] == '/'){                               // ~/"directory" accesses a directory in home
                    
                    desired_path = &desired_path[1];                      
                    desired_path = strcat(home_path, desired_path);
                    chd = chdir(desired_path);                           
                }
                else if (desired_path[0] == '.' &&                             // Accecess a directory 
                            desired_path[1] == '/'){                          // inside the current one
                    
                    char* curr_dir = NULL;
                    desired_path = &desired_path[1];
                    desired_path = strcat( getcwd(curr_dir, MAX_BUFF), desired_path );
                    chd = chdir(desired_path);
                }
                // ".." or any directory
                else {
                    chd = chdir(desired_path);
                }
            }
            scommand_pop_front(cmd);
            if (chd != 0) {
                perror("mybash> : cd");
            }
        }
    }    
}
