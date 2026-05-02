-- ==========================================================================================
-- Mod: Instant Death Skip & Fast Retry
-- Game: Clair Obscur: Expedition 33 (UE 5.4)
-- Description: Detects the "Expedition Failed" widget and accelerates time to skip animations.
-- Credits: Developed by [ZEDDTAY]
-- ==========================================================================================

print("--- SkipDeathMod: V1.0.0 Initialized ---")

local isTurboActive = false

--- Sets TimeDilation for all active WorldSettings instances.
-- Uses ExecuteInGameThread to ensure thread safety and prevent engine crashes.
-- @param val number: The target time dilation value (1.0 = normal, >1.0 = fast).
local function SetGlobalSpeed(val)
    ExecuteInGameThread(function()
        local allWorlds = FindAllOf("WorldSettings")
        if allWorlds then
            for _, ws in pairs(allWorlds) do
                if ws:IsValid() then 
                    ws.TimeDilation = val 
                end
            end
        end
    end)
end

--- Main Polling Loop (Runs every 200ms).
-- Monitors the memory for the existence and visibility of the Game Over widget.
LoopAsync(200, function()
    -- Safely attempt to find the JRPG Game Over widget instance
    local status, allWidgets = pcall(FindAllOf, "WBP_jRPG_GameOverScreen_C")
    
    -- Safety exit if engine is in a transitional state or shutting down
    if not status or not allWidgets then return false end

    local foundVisible = false

    for _, widget in pairs(allWidgets) do
        -- Check if widget is valid and currently rendered on screen
        if widget:IsValid() and widget:IsVisible() then
            foundVisible = true
            
            -- Enable high-speed mode (x25.0) to bypass 5-8s animations
            SetGlobalSpeed(25.0)

            -- Force-trigger internal widget events to bypass UI delay timers
            pcall(function() 
                widget:OnConstructTimerEnded() -- Skips the initial delay
                widget:ShowGameOverInstant()    -- Shows retry/load buttons immediately
                widget:StopMusic()             -- Silences the long failure jingle
            end)
            break
        end
    end

    -- Logic for restoring normal game speed
    if foundVisible then
        isTurboActive = true
    elseif isTurboActive then
        -- Widget no longer detected/visible: Reverting to 1.0 speed
        SetGlobalSpeed(1.0)
        isTurboActive = false
        print("!!! MOD: UI Cleared - Speed Restored !!!")
    end

    return false -- Keep the loop running
end)

--- Global Event Hooks for Emergency Reset.
-- Ensures speed is reverted to 1.0 whenever a level is restarted or loaded.
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    SetGlobalSpeed(1.0)
end)
