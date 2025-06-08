settings {
    logfile = "/home/comfy/.config/lsyncd/lsyncd.log",
    statusFile = "/home/comfy/.config/lsyncd/lsyncd.status",
    statusInterval = 5,
    nodaemon = true,   -- Run in foreground to avoid daemonization issues
    insist = true,
    maxProcesses = 4,  -- Allow multiple rsync processes for faster sync
    maxDelays = 0.5    -- Don't batch changes for too long
}

-- Sync ComfyUI from workspace to local (one-way sync)
-- Follower pulls changes from the workspace
sync {
    default.rsync,
    source = "/workspace/ComfyUI",    -- workspace directory (persistent storage)
    target = "/home/comfy/ComfyUI",  -- local directory (faster access)
    exclude = {"__pycache__", "home/comfy/ComfyUI/models"},        -- exclude Python cache files
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

-- Sync Python installation from workspace to local (one-way sync)
-- Follower pulls Python environment from workspace
sync {
    default.rsync,
    source = "/workspace/python",     -- workspace directory (persistent storage)
    target = "/home/comfy/python",    -- local directory (faster access)
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

-- Sync cursor-server from workspace to local (one-way sync)
sync {
    default.rsync,
    source = "/workspace/.cursor-server",     -- workspace directory (persistent storage)
    target = "/home/comfy/.cursor-server",    -- local directory (faster access)
    exclude = {"data", "__pycache__"},         -- exclude data directory
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