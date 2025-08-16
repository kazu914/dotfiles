-- [[
-- Auto-mute all audio outputs at 11 PM daily
-- ]]

local function muteAllAudioOutputs()
    local outputDevices = hs.audiodevice.allOutputDevices()
    local mutedCount = 0

    for _, device in pairs(outputDevices) do
        if device:isOutputDevice() then
            local success = device:setOutputMuted(true)
            if success then
                mutedCount = mutedCount + 1
                print("Muted audio device: " .. device:name())
            else
                print("Failed to mute audio device: " .. device:name())
            end
        end
    end

    print("Auto-muted " .. mutedCount .. " audio output devices at 11 PM")
    hs.notify.new({title="Audio Auto-Mute", informativeText="Muted " .. mutedCount .. " audio output devices"}):send()
end

-- Schedule daily mute at 11 PM (23:00)
hs.timer.doAt("23:00", "1d", muteAllAudioOutputs)

print("Audio auto-mute scheduler loaded - will mute all outputs daily at 11 PM")
