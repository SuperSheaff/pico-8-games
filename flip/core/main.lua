-- main.lua

-- native init
function _init()
    start_game_state()
end

-- native update
function _update()
    if game_state == "play" then
        if not game_over then
            update_game()
        else
            update_game_over()
        end
    elseif game_state == "choose_option" then
        handle_option_selection()
    elseif game_state == "resume_delay" then
        update_resume_delay()
    end
end

-- native draw
function _draw()
    cls(background_color) -- clear background color

    -- always draw the game and UI
    ui:draw_border()
    ui:handle_score()

    -- draw the apple (only one apple at a time)
    apple:draw()
    -- Draw all active spikes using their draw methods
    for spike in all(spikes) do
        spike:draw()
    end
    snake:draw()


    if game_over then
        ui:draw_game_over_effects() -- handle game over drawing
    end

    -- draw option screen on top if in choose_option state
    if game_state == "choose_option" then
        ui:draw_option_screen() -- draw options over the game
    end
end

-- Check if a position is empty
function is_empty_position(x, y)
    -- Check against the snake's head if snake is initialized
    if snake and x == snake.x and y == snake.y then
        return false
    end

    -- Check against the snake's body if snake is initialized
    if snake then
        for part in all(snake.body) do
            if x == part.x and y == part.y then
                return false
            end
        end
    end

    -- Check against existing spikes
    for spike in all(spikes) do
        if x == spike.x and y == spike.y then
            return false
        end
    end

    -- Additional checks can be added here in the future

    return true
end

-- initialize game variables
function start_game_state()
    ticks = 0
    sound_ticks = 0 -- initialize sound tick counter
    score = 0 -- initialize score to 0
    update_rate = base_update_rate -- reset game speed to base value
    apple = spawn_apple() -- only one apple at a time
    snake = spawn_snake(5)
    next_apple_golden = false
    game_over = false
    remove_spikes()
    ui:reset_flash_state()
end

function update_game()
    -- handle input and update game state
    handle_snake_input()

    -- update game objects based on ticks
    ticks += 1
    if ticks >= update_rate then
        snake:update()
        ticks = 0

        -- increment sound_ticks and play sound if needed
        sound_ticks += 1
        if sound_ticks >= 4 then
            sfx(1) -- play tick sound effect
            sound_ticks = 0 -- reset sound counter
        end
    end
end

function update_game_over()
    if flash.count < flash.max_count then
        ui:update_flash_effect() -- handle flash updates
    else
        -- restart game on pressing X after flashing ends
        if btnp(5) then -- button X
            start_game_state()
        end
    end
end

function handle_option_selection()
    -- up arrow to select option 1
    if not options_randomized then
        select_random_options()
        options_randomized = true
    end

    if btnp(2) then
        sfx(3)
        selected_option = 1
    end

    -- down arrow to select option 2
    if btnp(3) then
        sfx(3)
        selected_option = 2
    end

    -- X button to confirm selection
    if btnp(5) then
        sfx(4)

        -- Apply the chosen effect based on the selected option index
        apply_effect(selected_option)

        -- Set the resume delay before the game resumes
        resume_delay = 30 -- 1 second delay (30 frames)
        
        -- Switch to "resume_delay" state
        game_state = "resume_delay"
        options_randomized = false
    end
end

function select_random_options()
    -- Clear the selected_options table to remove previous selections
    selected_options = {}

    local option_indices = { 1, 2, 3 }
    
    -- Randomly shuffle the option indices
    for i = #option_indices, 2, -1 do
        local j = flr(rnd(i)) + 1
        option_indices[i], option_indices[j] = option_indices[j], option_indices[i]
    end
    
    -- Select the first two options from the shuffled list
    for i = 1, 2 do
        local option = options[option_indices[i]]
        -- Generate a random count (1-5) for the chosen option
        local count = flr(rnd(4)) + 1
        add(selected_options, { option = option, count = count })
    end
end

function apply_effect(selected_option_index)
    -- Get the chosen option details
    local chosen_option = selected_options[selected_option_index]
    local effect = chosen_option.option.effect
    local count = chosen_option.count
    
    -- Store the active effect details
    active_effect = {
        effect = effect,
        required_apples = count,
        start_apples = apples_eaten
    }

    if effect == "invisible" then
        -- Apply the invisible body effect
        snake.invisible = true
        print("Invisible body activated for " .. count .. " apples!", 10, 10, 8)
        
    elseif effect == "speed" then
        -- Apply the extra speed effect
        update_rate = base_update_rate - 2 -- Adjust the speed to be faster
        print("Extra speed activated for " .. count .. " apples!", 10, 10, 8)
        
    elseif effect == "spikes" then
        -- Spawn spikes on the game area
        spawn_spikes(count) -- Custom function to spawn spikes
        print(count .. " spikes spawned for " .. count .. " apples!", 10, 10, 8)
    end
end


function check_effect_end()
    -- Check if an effect is currently active
    if active_effect then
        -- Check if the player has eaten the required number of apples to end the effect
        if apples_eaten - active_effect.start_apples >= active_effect.required_apples - 1 then
            -- End the current active effect
            end_effect(active_effect.effect)
            active_effect = nil -- Reset active effect to indicate no effect is active
        end
    end
end

function end_effect(effect)
    if effect == "invisible" then
        snake.invisible = false
    elseif effect == "speed" then
        update_rate = base_update_rate
    elseif effect == "spikes" then
        remove_spikes()
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

function update_resume_delay()
    -- Decrement the delay timer
    if resume_delay > 0 then
        resume_delay -= 1
    end

    -- If the delay timer reaches zero, resume the game
    if resume_delay <= 0 then
        game_state = "play"
    end
end