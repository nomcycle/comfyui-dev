settings {
    logfile = "/home/comfy/.config/lsyncd/lsyncd.log",
    statusFile = "/home/comfy/.config/lsyncd/lsyncd.status",
    statusInterval = 5,
    nodaemon = true,   -- Run in foreground to avoid daemonization issues
    insist = true,
    maxProcesses = 4,  -- Allow multiple rsync processes for faster sync
    maxDelays = 0.5    -- Don't batch changes for too long
}

-- Sync ComfyUI to network storage.
sync {
    default.rsync,
    source = "/home/comfy/ComfyUI",
    target = "/workspace/ComfyUI",
    exclude = {"__pycache__"}
    -- Very small delay to ensure faster syncing
    delay = 0.5,
    -- Initialize is important for the first sync
    rsync = {
        binary = "/usr/bin/rsync",
        archive = true,
        compress = false,
        verbose = true,
        -- Additional rsync options for reliability
        _extra = {"--delete"}
    },
}

-- Sync .venv to network storage.
sync {
    default.rsync,
    source = "/home/comfy/.venv",
    target = "/workspace/.venv",
    exclude = {"__pycache__"}
    -- Very small delay to ensure faster syncing
    delay = 0.5,
    -- Initialize is important for the first sync
    rsync = {
        binary = "/usr/bin/rsync",
        archive = true,
        compress = false,
        verbose = true,
        -- Additional rsync options for reliability
        _extra = {"--delete"},
    },
}