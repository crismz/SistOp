#include "big_brother.h"
#include "fat_volume.h"
#include "fat_table.h"
#include "fat_util.h"
#include "fat_file.h"
#include <stdio.h>
#include <string.h>

int bb_is_log_file_dentry(fat_dir_entry dir_entry) {
    return strncmp(LOG_FILE_BASENAME, (char *)(dir_entry->base_name), 3) == 0 &&
           strncmp(LOG_FILE_EXTENSION, (char *)(dir_entry->extension), 3) == 0;
}

int bb_is_log_filepath(char *filepath) {
    return strncmp(BB_LOG_FILE, filepath, 8) == 0;
}

int bb_is_log_dirpath(char *filepath) {
    return strncmp(BB_DIRNAME, filepath, 15) == 0;
}

/* Searches for a cluster that could correspond to the bb directory and returns
 * its index. If the cluster is not found, returns 0.
 */

u32 search_bb_orphan_dir_cluster() {
    u32 bb_dir_start_cluster = 3;
    void * buf = NULL;

    fat_volume vol = get_fat_volume();
    fat_table table = vol->table;

    while (
        !fat_table_cluster_is_bad_sector(
            le32_to_cpu(((const le32 *)table->fat_map)[bb_dir_start_cluster])
            )   && bb_dir_start_cluster < (FAT_CLUSTER_END_OF_CHAIN_MIN/(fat_table_bytes_per_cluster(table)*8))
        ) {
        bb_dir_start_cluster++;
    }

    if (!fat_table_cluster_is_bad_sector(
            le32_to_cpu(((const le32 *)table->fat_map)[bb_dir_start_cluster])
            )
        )
        return 0;

    // Check if the first entry of direntry is fs.log
    off_t offset_bb = fat_table_cluster_offset(vol->table, bb_dir_start_cluster);
    buf = alloca(sizeof(struct fat_dir_entry_s));
    full_pread(vol->table->fd, buf, sizeof(struct fat_dir_entry_s), offset_bb);
    if(!bb_is_log_file_dentry((fat_dir_entry)buf)){
        fat_table_set_next_cluster(vol->table,bb_dir_start_cluster,FAT_CLUSTER_FREE);
        return 0;
    }

    return bb_dir_start_cluster;
}

/* Creates the /bb directory as an orphan and adds it to the file tree as
 * child of root dir.
 */

static int bb_create_new_orphan_dir() {
    errno = 0;
    fat_volume vol = NULL;
    u32 bb_orphan_dir_cluster = 0;
    fat_tree_node root_node = NULL;

    // ****MOST IMPORTANT PART, DO NOT SAVE DIR ENTRY TO PARENT ****
    vol = get_fat_volume();

    // Search for a free cluster and set cluster
    bb_orphan_dir_cluster = fat_table_get_next_free_cluster(vol->table);
    fat_table_set_next_cluster(vol->table,bb_orphan_dir_cluster,FAT_CLUSTER_BAD_SECTOR);

    // Create a new file from scratch, instead of using a direntry like normally done.
    fat_file loaded_bb_dir = fat_file_init_orphan_dir(BB_DIRNAME, vol->table, bb_orphan_dir_cluster);

    // Add directory to file tree. It's entries will be like any other dir.
    root_node = fat_tree_node_search(vol->file_tree, "/");
    vol->file_tree = fat_tree_insert(vol->file_tree, root_node, loaded_bb_dir);

    return -errno;
 }


int bb_init_log_dir(u32 start_cluster) {
    errno = 0;

    if(!start_cluster)
        errno = bb_create_new_orphan_dir();
    else {
        fat_volume vol = get_fat_volume();
        void *buf = NULL;
        fat_tree_node root_node = NULL, dir_node = NULL;

        // Search of log_file's dentry and save in buf
        off_t offset_bb = fat_table_cluster_offset(vol->table, start_cluster);
        buf = alloca(sizeof(struct fat_dir_entry_s));
        full_pread(vol->table->fd, buf, sizeof(struct fat_dir_entry_s),
                   offset_bb);

        fat_file loaded_bb_dir = fat_file_init_orphan_dir(BB_DIRNAME, vol->table, start_cluster);

        // Write log_file's dentry
        full_pwrite(vol->table->fd, buf, sizeof(struct fat_dir_entry_s),
                    offset_bb);

        // Add directory to file tree. It's entries will be like any other dir.
        root_node = fat_tree_node_search(vol->file_tree, "/");
        vol->file_tree = fat_tree_insert(vol->file_tree, root_node, loaded_bb_dir);

        dir_node = fat_tree_node_search(vol->file_tree, BB_DIRNAME);
        GList *children_list = fat_file_read_children(loaded_bb_dir);
        for (GList *l = children_list; l != NULL; l = l->next) {
            vol->file_tree =
                fat_tree_insert(vol->file_tree, dir_node, (fat_file)l->data);
        }
    }

    return -errno;
}
