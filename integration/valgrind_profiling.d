/*
    static void illegal      (ev_loop_t * default_loop, ev_signal * interruption_watcher, int revents)
    {
        // do nothing
        void sighandler (int signo, siginfo_t si, void *data) {
            ucontext_t *uc = (ucontext_t *)data;

            int instruction_length = // the length of the "instruction" to skip

            uc->uc_mcontext.gregs[REG_RIP] += instruction_length;
        }

        install the sighandler like that:

        struct sigaction sa, osa;
        sa.sa_flags = SA_ONSTACK | SA_RESTART | SA_SIGINFO;
        sa.sa_sigaction = sighandler;
        sigaction(SIGILL, &sa, &osa);
        That could work if you know how far to skip (
        
    }
    
    __gshared ev_signal illegal_instruction_watcher;
    ev_signal_init (&illegal_instruction_watcher, &illegal, SIGILL);
    ev_signal_start (default_loop, &illegal_instruction_watcher);
    */