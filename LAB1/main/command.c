#include "command.h"
#include "strextra.h"
#include <assert.h>
#include <glib-2.0/glib.h>  
#include <stdlib.h>
#include <string.h>

struct scommand_s {
    GList* args;     
    char* in;     
    char* out;
}; 

struct pipeline_s {
    GList* scmd;
    bool wait;
};

char **scommand_to_array(scommand scmd){
    assert(scmd != NULL);

    uint len = scommand_length(scmd);
    char **ret = calloc(len + 1, sizeof(char*)); 
    
    for ( uint i = 0; i < len; i++ ){
        ret[i] = scommand_front(scmd);
        scommand_pop_front(scmd);
    }

    ret[len] = NULL;

    assert(ret != NULL);
    return ret;
}


scommand scommand_new(void){
    scommand self = calloc(1, sizeof(struct scommand_s));
    
    if (self == NULL){
        exit(EXIT_FAILURE);
    }
    
    self->args = NULL;
    self->in = NULL;
    self->out = NULL; 
    
    assert (
        self != NULL && scommand_is_empty (self) &&
        scommand_get_redir_in (self) == NULL &&
        scommand_get_redir_out (self) == NULL
    );

    return self;
}

scommand scommand_destroy(scommand self){
    assert(self != NULL);
    
    g_list_free_full(self->args, free);
    
    free(self->in);
    free(self->out);
    self->args = NULL; 
    self->in = self->out = NULL;

    free(self);
    self = NULL;

    assert(self == NULL);
    return self;
}

void scommand_push_back(scommand self, char * argument){ 
    assert(self != NULL && argument != NULL);
    
    self->args = g_list_append(self->args, argument);

    assert(!scommand_is_empty(self));
}

void scommand_pop_front(scommand self) {
    assert(self != NULL && !scommand_is_empty(self));

    self->args = g_list_remove(self->args, g_list_nth_data(self->args,0u));
}

void scommand_set_redir_in(scommand self, char * filename){
    assert(self != NULL);
    self->in = filename;
}

void scommand_set_redir_out(scommand self, char * filename){
    assert(self != NULL);
    self->out = filename;
}

bool scommand_is_empty(const scommand self){
    assert(self != NULL);
    return g_list_length(self->args) == 0;
}

unsigned int scommand_length(const scommand self){
    assert(self != NULL);

    uint len = g_list_length(self->args); 
    
    assert((len==0) == scommand_is_empty(self));
    return len;

}

char * scommand_front(const scommand self){
    assert(self != NULL && !scommand_is_empty(self));
    
    char* res = g_list_nth_data(self->args, 0);

    assert(res != NULL);
    return res;
}

char * scommand_get_redir_in(const scommand self){
    assert(self != NULL);
    return self->in;
}

char * scommand_get_redir_out(const scommand self){
    assert(self != NULL);
    return self->out;
}

char * scommand_to_string(const scommand self){
    assert(self != NULL);
    
    char* str = strdup("");
    GList* args = g_list_copy(self->args);
        
    if (args != NULL) {
        uint len = g_list_length(args);

        for (uint i = 0u; i < len; i++) {
            str = strmerge(str, g_list_nth_data(args, i));
            if (i != len-1)
                str = strmerge(str, " ");  
        }
    }
        
    if (scommand_get_redir_in(self) != NULL){
        str = strcat(str, " < ");
        str = strcat(str, scommand_get_redir_in(self));
    }

    if (scommand_get_redir_out(self) != NULL){
        str = strcat(str, " > ");
        str = strcat(str, scommand_get_redir_out(self));
    }

    assert (
        scommand_is_empty(self) ||
        scommand_get_redir_in(self) == NULL || 
        scommand_get_redir_out(self) == NULL ||
        strlen(str) > 0
    );
    return str;
}


pipeline pipeline_new(void){
    pipeline pipe = calloc(1, sizeof(struct pipeline_s));
    pipe->scmd = NULL;
    pipe->wait = true;

    if (pipe == NULL){
        exit(EXIT_FAILURE);
    }

    assert (   
        pipe != NULL && pipeline_is_empty(pipe) && 
        pipeline_get_wait(pipe)
    );

    return pipe;
}

// Auxiliary function tu use as the second argument of g_list_free_full()
static void void_scommand_destroy(gpointer self){
    self = scommand_destroy(self);
    self = NULL;
}

pipeline pipeline_destroy(pipeline self){
    assert(self != NULL);
    g_list_free_full(self->scmd, void_scommand_destroy);
    self->scmd = NULL;
    free(self);
    self = NULL;

    assert(self == NULL);
    return self;
}

void pipeline_push_back(pipeline self, scommand sc){
    assert(self != NULL && sc != NULL);
    
    self->scmd = g_list_append(self->scmd, sc);

    assert(!pipeline_is_empty(self));
}

void pipeline_pop_front(pipeline self) {
    assert(self != NULL && !pipeline_is_empty(self));

    self->scmd = g_list_remove(self->scmd,g_list_nth_data(self->scmd,0u));
}

void pipeline_set_wait(pipeline self, const bool w){
    assert(self != NULL);
    self->wait = w;
}

bool pipeline_is_empty(const pipeline self){
    assert(self != NULL);
    return (g_list_length(self->scmd) == 0);
}

unsigned int pipeline_length(const pipeline self){
    assert(self != NULL);

    uint len = g_list_length(self->scmd);

    assert((len==0) == pipeline_is_empty(self));
    return len;
}

scommand pipeline_front(const pipeline self){
    assert(self!=NULL && !pipeline_is_empty(self));
    
    scommand res = g_list_first(self->scmd)->data;
    
    assert(res != NULL);
    return res;
}

bool pipeline_get_wait(const pipeline self){
    assert(self != NULL);
    return self->wait;
}

char * pipeline_to_string(const pipeline self) {

    assert(self != NULL);

    char* str = strdup("");
    char* aux = NULL;
    uint len = pipeline_length(self);
    GList* cmds = self->scmd;

    if (cmds != NULL){
        // Concat the commands separated by |
        for (uint i = 0; i < len-1; i++){
            aux = scommand_to_string(g_list_nth_data(cmds, i));
            str = strcat(str, aux);
            str = strcat(str, " | ");
            free(aux);
            aux = NULL;
        }   
        aux = scommand_to_string(g_list_nth_data(cmds, len-1));
        str = strcat(str, aux);
        free(aux);
        aux = NULL;
        
        if (!pipeline_get_wait(self)){
            str = strcat(str, " &");
        }
    }

    assert( pipeline_is_empty(self) || 
            pipeline_get_wait(self) || 
            strlen(str)>0 
    );
    return str;
}
