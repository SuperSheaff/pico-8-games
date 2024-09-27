-- main.lua

-- native init
function _init()
    reset_game_state()
end

-- native update
function _update()
    if game_state == "play" then
        if not game_over then
            update_game()
        else
            update_game_over()
        end
    elseif game_state == "choose_curse" then
        handle_curse_selection()
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

    -- draw curse screen on top if in choose_curse state
    if game_state == "choose_curse" then
        ui:draw_curse_screen() -- draw curses over the game
    end
end

-- initialize game variables
function reset_game_state()
    ticks           = 0
    sound_ticks     = 0 -- initialize sound tick counter
    score           = 0 -- initialize score to 0
    update_rate     = base_update_rate -- reset game speed to base value
    snake           = spawn_snake(5)
    apple           = spawn_apple() -- only one apple at a time
    active_curses   = {}
    invisible_apples = false
    next_apple_golden = false
    game_over       = false
    remove_spikes()
    ui:reset_flash_state()
end

function update_game()
    -- handle input and update game state
    handle_snake_input()
    apple:update()

    -- update game objects based on ticks
    ticks += 1
    if ticks >= update_rate then
        snake:update()
        ticks = 0

        -- increment sound_ticks and play sound if needed
        sound_ticks += 1
        if sound_ticks >= 4 then
            sfx(sounds.game_tick) -- play tick sound effect
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
            reset_game_state()
        end
    end
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