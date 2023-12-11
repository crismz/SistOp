#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>

#include "parsing.h"
#include "parser.h"
#include "command.h"
#include "strextra.h"

static scommand parse_scommand(Parser p, bool *had_error) {
    scommand cmd = scommand_new();
    arg_kind_t type;
    char *arg;
    
    parser_skip_blanks(p);
    arg = parser_next_argument(p,&type);

    /* If first argument is '|', '&' or '\n' destroy cmd and return NULL */
    if(arg == NULL){         
        cmd = scommand_destroy(cmd);
        return cmd;  

    } else {
        /* While next argument isn't '|', '&' or '\n', consume it */
        while(arg != NULL){
            if(type == ARG_NORMAL){
                scommand_push_back(cmd,arg);
            } else if(type == ARG_INPUT){
                scommand_set_redir_in(cmd,arg);
            } else {
                scommand_set_redir_out(cmd,arg);
            }
            
            parser_skip_blanks(p);
            
            arg = parser_next_argument(p,&type);
            
            if((type == ARG_INPUT || type == ARG_OUTPUT) && arg == NULL){
                cmd = scommand_destroy(cmd);
                printf("mybash> : Syntax error, no redirection specified\n");
                *had_error = true;
            }
        }
    }

    return cmd;
}

pipeline parse_pipeline(Parser p) {
    assert(p != NULL);
    assert(!parser_at_eof(p));

    pipeline result = pipeline_new();
    scommand cmd = NULL;

    bool error = false, another_pipe=true, 
    is_op_background = true, is_garbage = false,
    had_error = false; // Detects if an error has ocurred

    cmd = parse_scommand(p,&had_error);
    error = (cmd==NULL);

    // Differentiate between empty input(\n) or "|" "&"    
    if(error){
        parser_op_pipe(p,&another_pipe);
        parser_op_background(p,&is_op_background);
        had_error = !(is_op_background || another_pipe);
    }

    if (!error){
        pipeline_push_back(result,cmd);
        parser_op_pipe(p,&another_pipe);

        /* Repeat process while is another_pipe and no error */
        while (another_pipe && !error) {
            cmd = parse_scommand(p,&had_error);
            error = (cmd==NULL);
            if(!error){
                pipeline_push_back(result,cmd);
                parser_op_pipe(p,&another_pipe);
            } else {
                pipeline_pop_front(result);
            }
        }

        if(!error){
            parser_op_background(p,&is_op_background);
            pipeline_set_wait(result,!is_op_background);
            
            /* If there is | after  & causes error */
            if(is_op_background){
                parser_skip_blanks(p);
                parser_op_pipe(p,&another_pipe);
                error = another_pipe;
            }
            
        }
    } 
  

    if(error){
        /* See if is empty or a syntatic error */ 
        is_op_background = false;

        if(pipeline_is_empty(result)){
            parser_op_pipe(p,&another_pipe);
            parser_op_background(p,&is_op_background);
        } 

        if((another_pipe || is_op_background) && !had_error){
            printf("mybash> : Syntax error\n");
            had_error = true;
        }

        if(!had_error){
            printf("mybash> : Not enough arguments\n");
        }

        result = pipeline_destroy(result);
        result = pipeline_new();
    }

    parser_garbage(p,&is_garbage);
    
    return result;
}
