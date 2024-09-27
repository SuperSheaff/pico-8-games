-- curse.lua

function handle_curse_selection()
    -- up arrow to select curse 1
    if not curses_randomized then
        shuffle_curses()
        curses_randomized = true
    end

    if btnp(2) then
        sfx(sounds.ui_move)
        selected_curse = 1
    end

    -- down arrow to select curse 2
    if btnp(3) then
        sfx(sounds.ui_move)
        selected_curse = 2
    end

    -- X button to confirm selection
    if btnp(5) then
        sfx(sounds.ui_select)

        -- Apply the chosen effect based on the selected curse index
        apply_curse(selected_curse)

        -- Set the resume delay before the game resumes
        resume_delay = 30 -- 1 second delay (30 frames)
        
        -- Switch to "resume_delay" state
        game_state = "resume_delay"
        curses_randomized = false
    end
end

function shuffle_curses()
    -- Clear the selected_curses table to remove previous selections
    selected_curses = {}

    -- Generate a list of available curse indices
    local available_indices = {}
    for i = 1, #curses do
        add(available_indices, i)
    end

    -- Randomly select two distinct curses
    for i = 1, 2 do
        -- Randomly pick an index from available_indices
        local random_index = flr(rnd(#available_indices)) + 1
        local selected_index = available_indices[random_index]

        -- Remove the selected index from available_indices
        deli(available_indices, random_index)

        -- Get the selected curse
        local curse = curses[selected_index]
        
        -- Generate a random count (1-5) for the chosen curse
        local count = flr(rnd(5)) + 1

        -- Add the selected curse and count to the selected_curses table
        add(selected_curses, { curse = curse, count = count })
    end
end

function apply_curse(selected_curse_index)
    -- Get the chosen curse details
    local chosen_curse = selected_curses[selected_curse_index]
    local curse = chosen_curse.curse.effect
    local count = chosen_curse.count
    
    -- Add the curse to the active_curses table
    add(active_curses, {
        curse = curse,
        required_apples = count,
        start_apples = apples_eaten
    })

    -- Apply the curse effect
    if curse == "invisible" then
        -- Apply the invisible body curse
        snake.invisible = true
        
    elseif curse == "speed" then
        -- Apply the extra speed curse
        update_rate = max(1, update_rate - 2) -- Adjust the speed to be faster
        
    elseif curse == "spikes" then
        -- Spawn spikes on the game area
        spawn_spikes(count) -- Custom function to spawn spikes

    elseif curse == "reverse_controls" then
        snake.reversed = true

    elseif curse == "invisible_apple" then
        invisible_apples = true -- Activate curse
    end
end

function check_curse_end()
    -- Iterate through all active curses
    for curse in all(active_curses) do
        -- Check if the player has eaten the required number of apples to end the curse
        if apples_eaten - curse.start_apples >= curse.required_apples - 1 then
            -- End the current curse
            end_curse(curse.curse)
            del(active_curses, curse) -- Remove the curse from the table
        end
    end
end

function end_curse(curse)
    if curse == "invisible" then
        snake.invisible = false
    elseif curse == "speed" then
        update_rate = base_update_rate
    elseif curse == "spikes" then
        remove_spikes()
    elseif curse == "reverse_controls" then
        snake.reversed = false
    elseif curse == "invisible_apple" then
        invisible_apples = false -- Deactivate curse
        apple.state = "visible"
        apple.timer = 0 -- Reset timer
    end
end

function spawn_spikes(count)
    spikes = {} -- Clear any existing spikes

    count = 4
    
    -- Spawn the specified number of spikes
    for i = 1, count do
        local valid_position = false
        local spike_x, spike_y

        while not valid_position do
            spike_x = flr(rnd((screen_size - border_size * 2) / grid_size)) + (border_size / grid_size)
            spike_y = flr(rnd((screen_size - border_size * 2 - score_bar.height) / grid_size)) + (border_size / grid_size)
            
            -- Ensure the spike does not overlap with the snake or the apple
            valid_position = is_empty_position(spike_x, spike_y)
        end

        -- Create a new spike object and add it to the spikes table
        local spike = spawn_spike(spike_x, spike_y)
        add(spikes, spike)
    end
end

function remove_spikes()
    spikes = {} -- Clear the spikes table to remove all active spikes
end

function draw_spikes()
    for spike in all(spikes) do
        spr(spike.sprite_id, spike.x * grid_size, spike.y * grid_size)
    end
end

function spawn_spike(x, y)
    local spike = {
        x = x,
        y = y,
        sprite_id = 7, -- Assuming 7 is the sprite ID for spikes
    }

    function spike:draw()
        spr(self.sprite_id, self.x * grid_size, self.y * grid_size)
    end

    return spike
end
