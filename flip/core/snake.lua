-- snake.lua

-- function to create a snake in the middle of the screen with a given initial length
function spawn_snake(initial_length)
    local snake = {
        x = flr((screen_size / grid_size) / 2),
        y = flr((screen_size / grid_size - score_bar.height / grid_size) / 2) + (score_bar.height / grid_size),
        dx = 1,
        dy = 0,
        direction = directions.right,
        body = {}
    }

    -- add initial body parts behind the head
    for i = 1, initial_length do
        add(snake.body, {
            x = snake.x - i, -- position body parts to the left of the head
            y = snake.y,
            direction = directions.right,
            prev_direction = directions.right
        })
    end

    -- draw the snake
    function snake:draw()
        -- draw snake head sprite based on direction
        draw_snake_part(self.x, self.y, self.direction, sprites.head_horizontal, sprites.head_vertical)
        
        -- draw snake body except the last segment
        if not snake.invisible then
            for i = 1, #self.body - 1 do
                local part = self.body[i]
                local next_part = self.body[i + 1] or {direction = self.direction}
        
                -- check if this part is a corner
                if i ~= #self.body and part.direction ~= part.prev_direction then
                    -- determine flipping for the corner sprite based on direction change
                    draw_corner_part(part.x, part.y, part.prev_direction, part.direction)
                else
                    -- draw body sprite based on direction
                    draw_snake_part(part.x, part.y, part.direction, sprites.body_horizontal, sprites.body_vertical)
                end
            end
        end
    
        -- draw the tail separately as the last piece
        local tail = self.body[#self.body]
        if tail then
            draw_snake_part(tail.x, tail.y, tail.direction, sprites.tail_horizontal, sprites.tail_vertical)
        end
    end
    
    -- update the snake position and check for collisions
    function snake:update()
        if game_over then return end -- skip update if game over
    
        -- store the previous head position and direction
        local prev_x = self.x
        local prev_y = self.y
        local prev_direction = self.direction
    
        -- move the snake exactly one grid size at a time
        self.x = self.x + self.dx
        self.y = self.y + self.dy
    
        -- update head direction based on movement
        if self.dx == 1 then self.direction = directions.right end
        if self.dx == -1 then self.direction = directions.left end
        if self.dy == 1 then self.direction = directions.down end
        if self.dy == -1 then self.direction = directions.up end
    
        -- check for collision with border
        if self.x < border_size / grid_size or self.x >= (screen_size - border_size) / grid_size or 
            self.y < border_size / grid_size or self.y >= (screen_size - border_size) / grid_size then
            ui:start_game_over_sequence() -- start game over sequence
        end
    
        -- check for collision with self
        for part in all(self.body) do
            if self.x == part.x and self.y == part.y then
                ui:start_game_over_sequence() -- start game over sequence
            end
        end

        -- Check for collision with spikes
        check_snake_spike_collision()
    
        -- update body positions to follow the head
        if #self.body > 0 then
            -- move each body part to the position of the part in front of it
            for i = #self.body, 2, -1 do
                self.body[i].x = self.body[i - 1].x
                self.body[i].y = self.body[i - 1].y
                self.body[i].prev_direction = self.body[i].direction
                self.body[i].direction = self.body[i - 1].direction
            end
    
            -- first body part follows the head's previous position and direction
            self.body[1].x = prev_x
            self.body[1].y = prev_y
            self.body[1].prev_direction = self.body[1].direction
            self.body[1].direction = prev_direction
        end
    
        -- add the new segment as the tail after movement update
        if self.new_part then
            add(self.body, self.new_part)
            self.new_part = nil -- clear the temporary segment
        end
    
        -- check if snake eats an apple (regular or golden)
        if apple.x == self.x and apple.y == self.y then
            self:eat_apple(prev_x, prev_y)
        end
    
        -- update the last direction after movement
        last_direction = self.direction
    end

    -- handle snake eating an apple
    function snake:eat_apple(prev_x, prev_y)
        local is_golden = apple.is_golden
    
        if is_golden then
            -- enter choose option state
            game_state = "choose_option"
            sfx(1) -- play sound when eating a golden apple
        else
            sfx(0) -- play sound when eating a regular apple
        end
    
        -- temporarily store the new part information to be added after update
        local tail = self.body[#self.body]
        self.new_part = { 
            x = tail.x, 
            y = tail.y, 
            direction = tail.direction, 
            prev_direction = tail.prev_direction 
        }
    
        -- increment score by 2 points
        score += 2
    
        -- check if score is a multiple of 10 for golden apple
        if score % 10 == 0 then
            next_apple_golden = true
        else
            next_apple_golden = false
        end
    
        check_effect_end()
        -- increment apples eaten and create a new apple
        apples_eaten += 1
        apple = spawn_apple()
    end

    return snake
end

-- handle snake input for movement
function handle_snake_input()
    -- left input
    if btn(0) and snake.dx == 0 then
        -- prevent reversing direction
        if last_direction ~= directions.right then
            snake.dx = -1
            snake.dy = 0
            snake.direction = directions.left
        end

    -- right input
    elseif btn(1) and snake.dx == 0 then
        if last_direction ~= directions.left then
            snake.dx = 1
            snake.dy = 0
            snake.direction = directions.right
        end

    -- up input
    elseif btn(2) and snake.dy == 0 then
        if last_direction ~= directions.down then
            snake.dx = 0
            snake.dy = -1
            snake.direction = directions.up
        end

    -- down input
    elseif btn(3) and snake.dy == 0 then
        if last_direction ~= directions.up then
            snake.dx = 0
            snake.dy = 1
            snake.direction = directions.down
        end
    end
end

-- function to draw snake parts based on direction and sprite type
function draw_snake_part(x, y, direction, horizontal_sprite, vertical_sprite)
    if direction == directions.right then
        spr(horizontal_sprite, x * grid_size, y * grid_size, 1, 1, false, false) -- normal horizontal
    elseif direction == directions.left then
        spr(horizontal_sprite, x * grid_size, y * grid_size, 1, 1, true, false) -- flipped horizontally
    elseif direction == directions.up then
        spr(vertical_sprite, x * grid_size, y * grid_size, 1, 1, false, false) -- vertical sprite
    elseif direction == directions.down then
        spr(vertical_sprite, x * grid_size, y * grid_size, 1, 1, false, true) -- flipped vertically
    end
end

-- function to draw corner sprite based on direction change
function draw_corner_part(x, y, prev_direction, direction)
    local flip_x, flip_y = false, false

    -- determine the flipping based on direction change
    if prev_direction == directions.up and direction == directions.right then
        flip_x, flip_y = false, false -- normal corner (up-right)
    elseif prev_direction == directions.right and direction == directions.down then
        flip_x, flip_y = true, false -- flipped horizontally
    elseif prev_direction == directions.down and direction == directions.left then
        flip_x, flip_y = true, true -- flipped horizontally and vertically
    elseif prev_direction == directions.left and direction == directions.up then
        flip_x, flip_y = false, true -- flipped vertically
    elseif prev_direction == directions.right and direction == directions.up then
        flip_x, flip_y = true, true -- right to up, flipped vertically
    elseif prev_direction == directions.down and direction == directions.right then
        flip_x, flip_y = false, true -- down to right, flipped horizontally and vertically
    elseif prev_direction == directions.left and direction == directions.down then
        flip_x, flip_y = false, false -- left to down, normal
    elseif prev_direction == directions.up and direction == directions.left then
        flip_x, flip_y = true, false -- up to left, normal
    end

    -- draw the corner sprite with appropriate flipping
    spr(sprites.corner, x * grid_size, y * grid_size, 1, 1, flip_x, flip_y)
end

-- Check if the snake collides with any spike
function check_snake_spike_collision()
    for spike in all(spikes) do
        if snake.x == spike.x and snake.y == spike.y then
            ui:start_game_over_sequence() -- Trigger the game over sequence
        end
    end
end