#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>

#include "command.h"    
#include "execute.h"
#include "parser.h"
#include "parsing.h"
#include "builtin.h"

static void verde(void){
    printf("\033[1;32m");
}

static void azul(void){
    printf("\033[1;34m");
}

static void reset_color(void){
    printf("\033[0m");
}

static void show_prompt(void) {
    
    char *currdir = NULL;                       
    char host_name[HOST_NAME_MAX + 1]; 
    char* usr = getlogin();                    // Get user name

    gethostname(host_name, HOST_NAME_MAX + 1); // Get host name and save it in host_name
    
    verde();                                   
    printf("%s@%s", usr, host_name);
    reset_color();
    printf(":");
    azul();

    currdir = getcwd(currdir, MAX_BUFF);
    printf("%s",currdir); // get current working directory
    reset_color();
    printf("(mybash)> ");

    free(currdir);

    fflush(stdout);
}

int main(int argc, char *argv[]) {
    pipeline pipe; 
    Parser input;
    bool quit = false;
    bool is_exit = false;   // variable to know is we exit or not of mybash 
                            // and cleanup using pipeline_destroy() and parser_destroy()

    input = parser_new(stdin);
    while (!quit && !is_exit) {
        show_prompt();
        pipe = parse_pipeline(input);

        execute_pipeline(pipe, &is_exit);

        pipe = pipeline_destroy(pipe);
  
        quit = parser_at_eof(input);

    }
    parser_destroy(input); input = NULL; 

    return EXIT_SUCCESS;
}

