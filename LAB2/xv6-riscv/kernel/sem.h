struct semaphore {
    int value;
    struct spinlock lk;
    int init_value;
};
