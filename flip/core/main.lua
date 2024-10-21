-- main.lua

-- native init
function _init()
    -- swaps one of the colors
    poke(0x5f15, 129) 

    play_intro()

end

-- native update, pseudo state machine
function _update()
    if game_state == "intro" then
        update_intro()
    elseif game_state == "play" then
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
    if game_state == "intro" then
        draw_intro()
    elseif game_state == "play" then
        draw_game()
    elseif game_state == "game_over" then
        draw_game_over()
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
    teleporting_apples  = false -- reset teleporting apple curse state
    next_apple_golden   = false -- reset golden apple state


    -- initialize game state to play
    game_state = "play"

    active_effect = "default"
    update_current_head_sprite()

    -- remove spikes, poop and reset the UI flash state
    remove_spikes()
    remove_poop()
    remove_egg_trail()
    ui:reset_flash_state()
end

function play_intro()
    music(0)
    game_state = "intro"
end
-- update the game when in play state
function update_game()

    if is_paused then
        pause_timer = pause_timer - 1
        if pause_timer <= 0 then
            is_paused = false
        end
        return -- Skip the rest of the update logic while paused
    end

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

function update_intro()
    -- Wait for player input to continue
    if btnp(5) then
        music(-1)
        reset_game_state()
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

    -- check if position overlaps with existing poop
    for poop in all(poop_trail) do
        if x == poop.x and y == poop.y then
            return false
        end
    end

    -- check if position overlaps with existing eggs
    for egg in all(egg_trail) do
        if x == egg.x and y == egg.y then
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

function draw_intro()
    cls(0)   -- clear the background with the specified color
    ui:draw_background()

    local presents = "flip presents"
    local presents_x = (screen_size - #presents * 4) / 2  -- calculate x position to center the presents
    local presents_y = 16

    -- draw the presents in green
    print(presents, presents_x, presents_y, 7)

    local the = "the"
    local the_x = ((screen_size - #the * 4) / 2) - 15   -- calculate x position to center the the
    local the_y = 27 + 8  -- Lower by 8

    -- draw the the in green
    print(the, the_x, the_y, 11)

    -- Draw the game name sprite with a black border
    local sprite_x = 0
    local sprite_y = 26 + 8  -- Lower by 8
    local sprite_id = sprites.game_title
    local sprite_size = 64

    -- Draw the actual sprite
    spr(sprite_id, sprite_x, sprite_y, 128, 128)

    -- Bobbing effect for character faces
    local character_sprites = {32, 33, 34, 35, 36, 37, 38, 39, 40}  -- IDs for welly, doug, etc.
    local num_sprites = #character_sprites
    local spacing = screen_size / (num_sprites + 3)  -- Reduce spacing to bring sprites closer

    for i, sprite_id in ipairs(character_sprites) do
        local x = (i * spacing) + 8  -- Adjust starting position slightly to the right
        -- Single wave effect
        local base_y = screen_size / 2 + 16  -- Lower by 16
        local y = base_y + sin((frame_count * 0.05) + (i * 0.3)) * 5  -- Wave effect
        spr(sprite_id, x, y)
    end

    local instructions = "press x to start"
    local instructions_x = (screen_size - #instructions * 4) / 2  -- calculate x position to center the instructions
    local instructions_y = screen_size - 22  -- calculate y position to center the instructions

    -- draw the instructions in green
    print(instructions, instructions_x, instructions_y, 7) 
    
    -- Flashing square logic
    if (frame_count / flash_interval) % 2 < 1 then
        -- Draw the flashing square
        rectfill(55, 105, 59, 111, 11)  -- Adjust the position and size as needed
        print("x", 56, 106, 0)
    end

    frame_count = frame_count + 0.2  -- Increment frame count for animation
end

function draw_game()
    draw_checkerboard(0, 5) -- use color 1 for light squares and 5 for dark squares
    ui:draw_background()    -- draw the background
    ui:draw_border()        -- draw the ui
    ui:handle_score()       -- draw the score
    apple:draw()            -- draw the apple
    draw_spikes()           -- draw all active spikes
    draw_poop_trail()       -- draw all active poop
    draw_egg_trail()        -- draw all active poop
    snake:draw()            -- draw the snake
end

function draw_game_over()
    ui:draw_game_over_effects() -- draw game over effects
end
