settings {
    logfile = "/home/comfy/.config/lsyncd/lsyncd.log",
    statusFile = "/home/comfy/.config/lsyncd/lsyncd.status",
    statusInterval = 5,
    nodaemon = true,   -- Run in foreground to avoid daemonization issues
    insist = true,
    maxProcesses = 4,  -- Allow multiple rsync processes for faster sync
    maxDelays = 0.5    -- Don't batch changes for too long
}

-- Sync ComfyUI from local to network storage (one-way sync)
-- This ensures persistent storage of changes made in the local environment
sync {
    default.rsync,
    source = "/home/comfy/ComfyUI",  -- local directory (faster access)
    target = "/workspace/ComfyUI",    -- workspace directory (persistent storage)
    exclude = {"__pycache__"},        -- exclude Python cache files
    -- Very small delay to ensure faster syncing
    delay = 0.5,
    rsync = {
        binary = "/usr/bin/rsync",
        archive = true,
        compress = false,
        verbose = true,
        -- Additional rsync options for reliability
        _extra = {"--delete"}
    },
}

-- Sync Python virtual environment from local to network storage (one-way sync)
-- This ensures persistent storage of installed packages
sync {
    default.rsync,
    source = "/home/comfy/.venv",    -- local directory (faster access)
    target = "/workspace/.venv",     -- workspace directory (persistent storage)
    exclude = {"__pycache__"},       -- exclude Python cache files
    delay = 10,
    rsync = {
        binary = "/usr/bin/rsync",
        archive = true,
        compress = false,
        verbose = true,
        -- Additional rsync options for reliability
        _extra = {"--delete"},
    },
}

-- Sync cursor-server from local to network storage (one-way sync)
sync {
    default.rsync,
    source = "/home/comfy/.cursor-server",    -- local directory (faster access)
    target = "/workspace/.cursor-server",     -- workspace directory (persistent storage)
    exclude = {"data"},                       -- exclude data directory
    delay = 20,
    rsync = {
        binary = "/usr/bin/rsync",
        archive = true,
        compress = false,
        verbose = true,
        -- Additional rsync options for reliability
        _extra = {"--delete"},
    },
}