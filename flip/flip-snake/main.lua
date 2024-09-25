-- global variables
grid_size = 8
update_rate = 5
screen_size = 128

border_size = 8 -- Border thickness on all sides
score_bar = {
    color = 7,
    text_color = 0,
    height = border_size
}

background_color = 0

-- Sprite IDs for horizontal sprites
tail_sprite_id = 1
body_sprite_id = 2
head_sprite_id = 3

-- Sprite IDs for vertical sprites
tail_sprite_vertical_id = 17
body_sprite_vertical_id = 18
head_sprite_vertical_id = 19

-- Sprite ID for corner sprite
corner_sprite_id = 4 -- Up to Right corner sprite

apple_sprite_id = 5

-- Direction constants
right = 0
down = 1
left = 2
up = 3

-- Game state
game_over = false

flash_count = 0 -- To track the number of flashes
max_flashes = 8 -- Total number of flashes before showing game over
flash_interval = 5 -- Number of frames between each flash (adjust this for speed)
flash_state = false -- To toggle between normal and flash states
flash_timer = 0 -- Timer to control flash speed

apples_eaten = 0 -- Track number of apples eaten
golden_apple = nil -- Track the golden apple if present
golden_apple_frequency = 5 -- Spawn a golden apple every 5 apples eaten
speed_increase_per_golden = 1 -- Increase speed by 1 frame per golden apple eaten
golden_apple_sprite_id = 6 -- ID for golden apple sprite


-- native functions
function _init()
    start_game()
end

function start_game()
    ticks = 0
    apples = {}
    for i = 1, 2 do
        add(apples, make_apple())
    end
    snake = make_snake(5)
    game_over = false -- Reset game over state
end

function _update()
    if not game_over then
        handle_snake_input()
    
        ticks += 1
        if ticks >= update_rate then
            snake:update()
            ticks = 0
        end
    else
        if flash_count < max_flashes then
            -- Slow down the flash speed by using a timer
            flash_timer += 1
            if flash_timer >= flash_interval then
                flash_state = not flash_state -- Toggle flash state
                flash_count += 1
                flash_timer = 0 -- Reset timer
            end
        else
            -- Restart game on pressing X after flashing ends
            if btnp(5) then -- Button X
                start_game()
            end
        end
    end
end

function _draw()
    cls(background_color)

    -- Draw border, score, and game name regardless of game state
    draw_border()
    handle_score()

    -- Always draw the game elements (paused during game over)
    for apple in all(apples) do
        apple:draw()
    end

    if golden_apple then
        golden_apple:draw()
    end

    snake:draw()

    if game_over then
        if flash_count < max_flashes then
            -- Flash the screen during the game over sequence
            if flash_state then
                -- Fill the entire play area with white
                rectfill(border_size, border_size, screen_size - border_size - 1, screen_size - border_size - 1, 7)
            end
        else
            -- Show game over screen after flashing
            draw_game_over_screen()
        end
    end
end


-- function that creates a snake in the middle of the screen with a given initial length
function make_snake(initial_length)
    local snake = {}
    snake.x = flr((screen_size / grid_size) / 2)
    snake.y = flr((screen_size / grid_size - score_bar.height / grid_size) / 2) + (score_bar.height / grid_size)

    snake.dx = 1
    snake.dy = 0
    snake.direction = right
    snake.body = {}

    -- Add initial body parts behind the head
    for i = 1, initial_length do
        add(snake.body, {
            x = snake.x - i, -- Position body parts to the left of the head
            y = snake.y,
            direction = right,
            prev_direction = right
        })
    end

    snake.draw = function(self)
        -- Draw snake head sprite based on direction
        draw_snake_part(self.x, self.y, self.direction, head_sprite_id, head_sprite_vertical_id)
    
        -- Draw snake body
        for i = 1, #self.body do
            local part = self.body[i]
            local next_part = self.body[i + 1] or {direction = self.direction}
    
            -- Check if this part is a corner
            if i ~= #self.body and part.direction ~= part.prev_direction then
                -- Determine flipping for the corner sprite based on direction change
                draw_corner_part(part.x, part.y, part.prev_direction, part.direction)
            elseif i == #self.body then
                -- Draw tail sprite based on direction
                draw_snake_part(part.x, part.y, part.direction, tail_sprite_id, tail_sprite_vertical_id)
            else
                -- Draw body sprite based on direction
                draw_snake_part(part.x, part.y, part.direction, body_sprite_id, body_sprite_vertical_id)
            end
        end
    end
    
    snake.update = function(self)
        if game_over then return end -- Skip update if game over
        
        -- Store the previous head position and direction
        local prev_x = self.x
        local prev_y = self.y
        local prev_direction = self.direction
    
        -- Move the snake exactly one grid size at a time
        self.x = self.x + self.dx
        self.y = self.y + self.dy
    
        -- Update head direction based on movement
        if self.dx == 1 then self.direction = right end
        if self.dx == -1 then self.direction = left end
        if self.dy == 1 then self.direction = down end
        if self.dy == -1 then self.direction = up end
    
        -- Check for collision with border
        if self.x < border_size / grid_size or self.x >= (screen_size - border_size) / grid_size or 
           self.y < border_size / grid_size or self.y >= (screen_size - border_size) / grid_size then
            start_game_over_sequence() -- Start game over sequence
        end
    
        -- Check for collision with self
        for part in all(self.body) do
            if self.x == part.x and self.y == part.y then
                start_game_over_sequence() -- Start game over sequence
            end
        end
    
        -- Update body positions to follow the head
        if #self.body > 0 then
            -- Move each body part to the position of the part in front of it
            for i = #self.body, 2, -1 do
                self.body[i].x = self.body[i - 1].x
                self.body[i].y = self.body[i - 1].y
                self.body[i].prev_direction = self.body[i].direction
                self.body[i].direction = self.body[i - 1].direction
            end
    
            -- First body part follows the head's previous position and direction
            self.body[1].x = prev_x
            self.body[1].y = prev_y
            self.body[1].prev_direction = self.body[1].direction
            self.body[1].direction = prev_direction
        end
    
        -- Check if snake eats a regular apple
        local ate_regular_apple = false
        for apple in all(apples) do
            if apple.x == self.x and apple.y == self.y then
                del(apples, apple)
                add(apples, make_apple())
                ate_regular_apple = true
                sfx(0) -- Play sound when eating an apple
            end
        end
    
        -- Check if snake eats a golden apple
        local ate_golden_apple = false
        if golden_apple and golden_apple.x == self.x and golden_apple.y == self.y then
            golden_apple = nil -- Remove the golden apple
            ate_golden_apple = true
            update_rate = max(1, update_rate - speed_increase_per_golden) -- Increase speed
            sfx(1) -- Play sound when eating a golden apple
        end
    
        -- Grow the snake if it ate a regular or golden apple
        if ate_regular_apple or ate_golden_apple then
            -- Add a new body part at the previous head position
            add(self.body, { x = prev_x, y = prev_y, direction = prev_direction, prev_direction = prev_direction })
            
            -- Increment apples eaten and check for golden apple spawn
            apples_eaten += 1
            if apples_eaten % golden_apple_frequency == 0 and not golden_apple then
                golden_apple = make_golden_apple()
            end
        end
    end

    return snake
end

function is_valid_apple_position(x, y)
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

    -- Check against other apples
    for apple in all(apples) do
        if x == apple.x and y == apple.y then
            return false
        end
    end

    return true
end



function make_apple()
    local apple = {}
    local valid_position = false
    
    -- Keep generating a new position until it's valid
    while not valid_position do
        apple.x = flr(rnd((screen_size - border_size * 2) / grid_size)) + (border_size / grid_size)
        apple.y = flr(rnd((screen_size - border_size * 2 - score_bar.height) / grid_size)) + (border_size / grid_size)

        -- Check if the new apple position is valid
        valid_position = is_valid_apple_position(apple.x, apple.y)
    end

    apple.draw = function(self)
        -- Draw apple sprite at the apple's position
        spr(apple_sprite_id, self.x * grid_size, self.y * grid_size)
    end

    return apple
end


function handle_snake_input()
    -- left input
    if (btn(0)) then
        if snake.dx == 0 then
            snake.dx = -1
            snake.dy = 0
            snake.direction = left
        end

    -- right input
    elseif (btn(1)) then
        if snake.dx == 0 then
            snake.dx = 1
            snake.dy = 0
            snake.direction = right
        end
    
    -- up input
    elseif (btn(2)) then
        if snake.dy == 0 then
            snake.dx = 0
            snake.dy = -1
            snake.direction = up
        end

    -- down input
    elseif (btn(3)) then
        if snake.dy == 0 then
            snake.dx = 0
            snake.dy = 1
            snake.direction = down
        end
    end
end

-- Function to draw snake parts based on direction and sprite type
function draw_snake_part(x, y, direction, horizontal_sprite, vertical_sprite)
    if direction == right then
        spr(horizontal_sprite, x * grid_size, y * grid_size, 1, 1, false, false) -- Normal horizontal
    elseif direction == left then
        spr(horizontal_sprite, x * grid_size, y * grid_size, 1, 1, true, false) -- Flipped horizontally
    elseif direction == up then
        spr(vertical_sprite, x * grid_size, y * grid_size, 1, 1, false, false) -- Vertical sprite
    elseif direction == down then
        spr(vertical_sprite, x * grid_size, y * grid_size, 1, 1, false, true) -- Flipped vertically
    end
end

-- Function to draw corner sprite based on direction change
function draw_corner_part(x, y, prev_direction, direction)
    local flip_x, flip_y = false, false

    -- Determine the flipping based on direction change
    if prev_direction == up and direction == right then
        flip_x, flip_y = false, false -- Normal corner (up-right)
    elseif prev_direction == right and direction == down then
        flip_x, flip_y = true, false -- Flipped horizontally
    elseif prev_direction == down and direction == left then
        flip_x, flip_y = true, true -- Flipped horizontally and vertically
    elseif prev_direction == left and direction == up then
        flip_x, flip_y = false, true -- Flipped vertically
    elseif prev_direction == right and direction == up then
        flip_x, flip_y = true, true -- Right to up, flipped vertically
    elseif prev_direction == down and direction == right then
        flip_x, flip_y = false, true -- Down to right, flipped horizontally and vertically
    elseif prev_direction == left and direction == down then
        flip_x, flip_y = false, false -- Left to down, flipped horizontally
    elseif prev_direction == up and direction == left then
        flip_x, flip_y = true, false -- Up to left, normal
    end

    -- Draw the corner sprite with appropriate flipping
    spr(corner_sprite_id, x * grid_size, y * grid_size, 1, 1, flip_x, flip_y)
end

-- Draw the score bar and borders around the screen
function draw_border()
    -- Top border (score bar)
    rectfill(0, 0, screen_size - 1, border_size - 2, score_bar.color)

    -- Left border
    rectfill(0, border_size - 1, border_size - 2, screen_size - 1, score_bar.color)

    -- Right border
    rectfill(screen_size - border_size + 1, border_size - 1, screen_size - 1, screen_size - 1, score_bar.color)

    -- Bottom border
    rectfill(border_size - 1, screen_size - border_size + 1, screen_size - border_size, screen_size - 1, score_bar.color)
end

-- Draw the score and game name inside the score bar
function handle_score()
    -- Draw score text
    print("score: "..#snake.body, 7, 1, score_bar.text_color) -- Offset by 8 pixels to the right
    
    -- Draw game name
    local game_name = "flip snake"
    local text_width = #game_name * 4 -- Approximate width calculation
    print(game_name, screen_size - text_width - 6, 1, score_bar.text_color) -- Display game name at top right
end

-- Start the game over sequence with flashing effect
function start_game_over_sequence()
    game_over = true
    flash_count = 0 -- Reset flash counter
    flash_state = false -- Reset flash state
    flash_timer = 0 -- Reset flash timer
end

-- Function to draw the game over screen
function draw_game_over_screen()
    -- Calculate dimensions for the "GAME OVER" box
    local game_over_text = "game over"
    local game_over_width = #game_over_text * 4 -- Approximate width of each character
    local game_over_height = 5 -- Approximate height of text
    local game_over_box_x = (screen_size - game_over_width - 5) / 2 -- Centered x position
    local game_over_box_y = 50 -- Y position for the first box
    local game_over_box_w = game_over_box_x + game_over_width + 5 -- Width of the box
    local game_over_box_h = game_over_box_y + game_over_height + 5 -- Height of the box

    -- Calculate dimensions for the "press X to restart" box
    local instruction_text = "press X to restart"
    local instruction_width = #instruction_text * 4 -- Approximate width of each character
    local instruction_height = 5 -- Approximate height of text
    local instruction_box_x = (screen_size - instruction_width - 5) / 2 -- Centered x position
    local instruction_box_y = game_over_box_y + 20 -- Y position below the first box
    local instruction_box_w = instruction_box_x + instruction_width + 5 -- Width of the box
    local instruction_box_h = instruction_box_y + instruction_height + 5 -- Height of the box

    -- Draw background box for the "GAME OVER" text
    rectfill(game_over_box_x, game_over_box_y, game_over_box_w, game_over_box_h, 7) -- White background box
    -- Draw "GAME OVER" in big text with black color
    print(game_over_text, game_over_box_x + 4, game_over_box_y + 4, 0) -- Position text inside the box with color 0 (black)
    
    -- Draw background box for the instruction text
    rectfill(instruction_box_x, instruction_box_y, instruction_box_w, instruction_box_h, 7) -- White background box
    -- Display restart instruction with black color
    print(instruction_text, instruction_box_x + 4, instruction_box_y + 4, 0) -- Position text inside the box with color 0 (black)
end

-- Function to create a golden apple
function make_golden_apple()
    local apple = {}
    local valid_position = false
    
    -- Keep generating a new position until it's valid
    while not valid_position do
        apple.x = flr(rnd((screen_size - border_size * 2) / grid_size)) + (border_size / grid_size)
        apple.y = flr(rnd((screen_size - border_size * 2 - score_bar.height) / grid_size)) + (border_size / grid_size)
        -- Check if the new apple position is valid and not on another apple
        valid_position = is_valid_apple_position(apple.x, apple.y) and not is_apple_at_position(apple.x, apple.y)
    end

    apple.draw = function(self)
        -- Draw golden apple sprite at the apple's position
        spr(golden_apple_sprite_id, self.x * grid_size, self.y * grid_size)
    end

    return apple
end

-- Function to check if an apple is at a given position
function is_apple_at_position(x, y)
    for apple in all(apples) do
        if apple.x == x and apple.y == y then
            return true
        end
    end
    return false
end