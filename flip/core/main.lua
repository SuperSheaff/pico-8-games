-- main.lua

-- native init
function _init()
    reset_game_state()

    -- enable_secret_palette()
    poke(0x5f15, 129) 
end

-- native update, pseudo state machine
function _update()
    if game_state == "play" then
        update_game()
    elseif game_state == "game_over" then
        update_game_over()
    elseif game_state == "choose_curse" then
        handle_curse_selection()
    elseif game_state == "resume_delay" then
        update_resume_delay()
    end
end

-- native draw
function _draw()
    cls(background_color) -- clear the background with the specified color

    -- draw checkerboard background
    draw_checkerboard(0, 5) -- use color 1 for light squares and 5 for dark squares


    ui:draw_border()    -- draw the ui
    ui:handle_score()   -- draw the score
    apple:draw()        -- draw the apple
    draw_spikes()       -- draw all active spikes
    draw_poop_trail()   -- draw all active poop
    snake:draw()        -- draw the snake

    -- handle drawing for game over state
    if game_state == "game_over" then
        ui:draw_game_over_effects() -- draw game over effects
    end

    -- draw the curse selection screen if in choose_curse state
    if game_state == "choose_curse" then
        ui:draw_curse_screen() -- draw curses over the game
    end
end

-- reset the game state to its initial values
function reset_game_state()
    -- game variables
    ticks               = 0 -- reset game ticks
    sound_ticks         = 0 -- reset sound tick counter
    score               = 0 -- reset score to 0
    update_rate         = base_update_rate -- set game speed to base value
    snake               = spawn_snake(5) -- create a new snake with initial length
    apple               = spawn_apple() -- spawn the first apple
    active_curses       = {}    -- clear active curses
    invisible_apples    = false -- reset invisible apple curse state
    next_apple_golden   = false -- reset golden apple state

    -- initialize game state to play
    game_state = "play"

    -- remove spikes, poop and reset the UI flash state
    remove_spikes()
    remove_poop()
    ui:reset_flash_state()
end

-- update the game when in play state
function update_game()
    -- handle snake input and update game state
    handle_snake_input()
    apple:update() -- update apple state

    -- update game objects based on ticks
    ticks += 1
    if ticks >= update_rate then
        snake:update() -- update snake position and state
        ticks = 0

        -- play a sound every few ticks
        sound_ticks += 1
        if sound_ticks >= 2 then
            sfx(sounds.game_tick) -- play tick sound effect
            sound_ticks = 0 -- reset sound tick counter
        end
    end
end


-- handle the game over state and restart option
function update_game_over()
    if flash.count < flash.max_count then
        ui:update_flash_effect() -- handle the flashing effect during game over
    else
        -- restart game on pressing X after flashing ends
        if btnp(5) then -- button X
            reset_game_state()
        end
    end
end

-- handle the delay before resuming the game after selecting a curse
function update_resume_delay()
    -- decrement the resume delay timer
    if resume_delay > 0 then
        resume_delay -= 1
    end

    -- resume the game once the delay timer reaches zero
    if resume_delay <= 0 then
        game_state = "play"
    end
end

-- check if a position is empty and valid for placing objects
function is_empty_position(x, y)
    -- check if position overlaps with the snake's head
    if snake and x == snake.x and y == snake.y then
        return false
    end

    -- check if position overlaps with the snake's body
    if snake then
        for part in all(snake.body) do
            if x == part.x and y == part.y then
                return false
            end
        end
    end

    -- check if position overlaps with existing spikes
    for spike in all(spikes) do
        if x == spike.x and y == spike.y then
            return false
        end
    end

    -- check if position overlaps with existing spikes
    for poop in all(poop_trail) do
        if x == poop.x and y == poop.y then
            return false
        end
    end

    -- position is empty and valid
    return true
end

-- function to draw a checkerboard pattern across the screen
function draw_checkerboard(light_color, dark_color)
    local start_x = border_size
    local start_y = border_size
    local end_x = screen_size - border_size
    local end_y = screen_size - border_size

    for x = start_x, end_x - grid_size, grid_size do
        for y = start_y, end_y - grid_size, grid_size do
            -- determine if the square should be light or dark
            local is_light_square = ((x - start_x) / grid_size + (y - start_y) / grid_size) % 2 == 0
            local color = is_light_square and light_color or dark_color
            -- draw the 8x8 square
            rectfill(x, y, x + grid_size - 1, y + grid_size - 1, color)
        end
    end
end

function enable_secret_palette()
    -- Load the secret colors into the screen palette
    for i=0,15 do
        poke(0x5f10 + i, 128 + i) -- Load secret colors from 128 to 143 into palette
    end
end