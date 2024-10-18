-- snake.lua

-- function to create a snake in the middle of the screen with a given initial length
function spawn_snake(initial_length)
    -- create the snake object with initial properties
    local snake = {
        x = flr((screen_size / grid_size) / 2), -- initial x position (centered)
        y = flr((screen_size / grid_size - score_bar.height / grid_size) / 2) + (score_bar.height / grid_size), -- initial y position (centered below score bar)
        dx = 1, -- initial movement direction (right)
        dy = 0,
        direction = directions.right, -- initial facing direction (right)
        reversed = false, -- initial state for reverse controls
        flipped = false, -- initial state for flip
        invisible_body = false, -- initial state for invisible body
        invisible_head = false, -- initial state for invisible body
        body = {}, -- body parts of the snake
        egg = false, -- initial state for egg
        original_length = 0, -- To 
        smelly = false -- initial state for smelly
    }

    -- add initial body parts behind the head
    for i = 1, initial_length do
        add(snake.body, {
            x = snake.x - i, -- position body parts to the left of the head
            y = snake.y,
            direction = directions.right, -- initial direction of each part
            prev_direction = directions.right -- previous direction for each part
        })
    end

    -- function to draw the snake
    function snake:draw()

        if not snake.invisible_head then
            -- draw snake head sprite based on current direction
            draw_snake_part(self.x, self.y, self.body[1].direction, sprites.head_horizontal.active, sprites.head_vertical.active)
        end

        -- draw snake body except the last segment if not invisible
        if not snake.invisible_body then
            for i = 1, #self.body - 1 do
                local part = self.body[i]
                local next_part = self.body[i + 1] or {direction = self.direction}
        
                -- check if this part is a corner based on direction change
                if i ~= #self.body and part.direction ~= part.prev_direction then
                    draw_corner_part(part.x, part.y, part.prev_direction, part.direction) -- draw corner
                else
                    draw_snake_part(part.x, part.y, part.direction, sprites.body_horizontal, sprites.body_vertical) -- draw body part
                end
            end
        end
    
        -- draw the tail separately as the last piece
        local tail = self.body[#self.body]
        if tail then
            draw_snake_part(tail.x, tail.y, tail.direction, sprites.tail_horizontal, sprites.tail_vertical)
        end
    end
    
    -- function to update the snake position and state
    function snake:update()
        -- skip update if in game over state
        if game_state == "game_over" then return end
    
        -- store the previous head position and direction
        local prev_x = self.x
        local prev_y = self.y
        local prev_direction = self.direction
    
        -- move the snake exactly one grid size at a time
        self.x = self.x + self.dx
        self.y = self.y + self.dy

        -- leave a poop trail if the curse is active
        if self.smelly then
            leave_poop_trail()
        end

        -- lay an egg if the curse is active
        if self.egg then
            leave_egg_trail()
        end
    
        -- update head direction based on movement
        if self.dx == 1 then self.direction = directions.right end
        if self.dx == -1 then self.direction = directions.left end
        if self.dy == 1 then self.direction = directions.down end
        if self.dy == -1 then self.direction = directions.up end
    
        -- check for collision with border
        if self.x < border_size / grid_size or self.x >= (screen_size - border_size) / grid_size or 
           self.y < border_size / grid_size or self.y >= (screen_size - border_size) / grid_size then
            ui:start_game_over_sequence() -- start game over sequence if snake hits the border
        end
    
        -- check for collision with self
        for part in all(self.body) do
            if self.x == part.x and self.y == part.y then
                ui:start_game_over_sequence() -- start game over sequence if snake hits itself
            end
        end

        -- check for collision with spikes
        check_snake_osbtacle_collision()
    
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

    -- function to handle snake eating an apple
    function snake:eat_apple(prev_x, prev_y)
        local is_golden = apple.is_golden
    
        if is_golden then
            game_state = "choose_curse" -- enter choose curse state
            sfx(sounds.golden_apple) -- play sound for golden apple
        else
            sfx(sounds.eat_apple) -- play sound for regular apple
        end

        -- Handle snake flipping if the curse is active
        if self.flipped then
            self:flip()
        end
        
        -- temporarily store the new part information to be added after update
        local tail = self.body[#self.body]
        self.new_part = { 
            x = tail.x, 
            y = tail.y, 
            direction       = tail.direction, 
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
    
        check_curse_end() -- check if any curse has ended

        self.original_length = self.original_length + 1

        -- increment apples eaten and create a new apple
        apples_eaten += 1
        apple = spawn_apple()
    end

    -- new function to handle snake flipping
    function snake:flip()
        -- Check if the body exists and has elements
        if not self.body or #self.body == 0 then
            print("Error: Snake body is not initialized or empty.")
            return
        end

        -- Reverse the body
        local new_body = {}
        local new_index = 1
        for i = #self.body, 1, -1 do
            local part = self.body[i]
            new_body[new_index] = {
                x = part.x,
                y = part.y,
                direction = opposite_direction(part.prev_direction),
                prev_direction = opposite_direction(part.direction)
            }
            new_index = new_index + 1
        end

        -- Update snake properties
        self.body = new_body
        -- Set the head to the old tail's position
        self.x = self.body[1].x
        self.y = self.body[1].y
        -- Set the direction to the opposite of the old tail's direction
        self.direction = self.body[1].direction
        self.dx = direction_to_dx(self.direction)
        self.dy = direction_to_dy(self.direction)

        -- Correct the direction of the first body part
        if #self.body > 1 then
            self.body[1].prev_direction = self.body[2].direction
        end

        -- Move the head one position forward
        self:move_head_forward()

        -- Initiate pause
        is_paused = true
        pause_timer = pause_duration    
    end

    -- function to move the head forward
    function snake:move_head_forward()
        if self.direction == directions.right then
            self.x = self.x + 1
        elseif self.direction == directions.left then
            self.x = self.x - 1
        elseif self.direction == directions.up then
            self.y = self.y - 1
        elseif self.direction == directions.down then
            self.y = self.y + 1
        end
    end

    function snake:activate_long_curse()
        self.original_length = #self.body

        -- Double the snake's length
        local tail = self.body[#self.body]
        for i = 1, self.original_length do
            local new_part = {
                x = tail.x,
                y = tail.y,
                direction = tail.direction,
                prev_direction = tail.prev_direction
            }
            self.body[#self.body + 1] = new_part -- Manually add new part
        end
    end

    function snake:deactivate_long_curse()
        -- Revert to original length
        for i = #self.body, self.original_length + 1, -1 do
            self.body[i] = nil -- Manually remove part
        end
    end

    return snake
end

-- handle snake input for movement
function handle_snake_input()
    -- determine the input directions based on whether controls are reversed
    local left = snake.reversed and 1 or 0
    local right = snake.reversed and 0 or 1
    local up = snake.reversed and 3 or 2
    local down = snake.reversed and 2 or 3

    -- left input
    if btn(left) and snake.dx == 0 then
        if last_direction ~= directions.right then
            snake.dx = -1
            snake.dy = 0
            snake.direction = directions.left
        end

    -- right input
    elseif btn(right) and snake.dx == 0 then
        if last_direction ~= directions.left then
            snake.dx = 1
            snake.dy = 0
            snake.direction = directions.right
        end

    -- up input
    elseif btn(up) and snake.dy == 0 then
        if last_direction ~= directions.down then
            snake.dx = 0
            snake.dy = -1
            snake.direction = directions.up
        end

    -- down input
    elseif btn(down) and snake.dy == 0 then
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

-- check if the snake collides with any spike
function check_snake_osbtacle_collision()
    for spike in all(spikes) do
        if snake.x == spike.x and snake.y == spike.y then
            ui:start_game_over_sequence() -- trigger the game over sequence
        end
    end
    for poop in all(poop_trail) do
        if snake.x == poop.x and snake.y == poop.y then
            ui:start_game_over_sequence() -- trigger the game over sequence
        end
    end
    for egg in all(egg_trail) do
        if snake.x == egg.x and snake.y == egg.y then
            ui:start_game_over_sequence() -- trigger the game over sequence
        end
    end
end

-- function to leave a poop trail behind the snake
function leave_poop_trail()
    -- create a poop object at the tail's previous position
    local tail = snake.body[#snake.body]
    if tail then
        local poop = {
            x = tail.x,
            y = tail.y,
            sprite_id = sprites.poop
        }
        add(poop_trail, poop) -- Add the poop to the trail
    end
end

-- Function to leave an egg trail behind the snake
function leave_egg_trail()
    -- Increment the movement counter
    egg_counter = egg_counter + 1

    -- Check if it's time to place an egg
    if egg_counter >= egg_interval then
        -- Create an egg object at the tail's previous position
        local tail = snake.body[#snake.body]
        if tail then
            local egg = {
                x = tail.x,
                y = tail.y,
                sprite_id = sprites.egg
            }
            add(egg_trail, egg) -- Add the egg to the trail
        end

        -- Reset the counter after placing an egg
        egg_counter = 0
    end
end


-- gets current head sprite
function update_current_head_sprite()
    if active_effect == "invisible" then
        sprites.head_horizontal.active  = sprites.head_horizontal.benny
        sprites.head_vertical.active    = sprites.head_vertical.benny
    elseif active_effect == "long" then
        sprites.head_horizontal.active  = sprites.head_horizontal.doug
        sprites.head_vertical.active    = sprites.head_vertical.doug
    elseif active_effect == "spikes" then
        sprites.head_horizontal.active  = sprites.head_horizontal.reno
        sprites.head_vertical.active    = sprites.head_vertical.reno
    elseif active_effect == "reverse_controls" then
        sprites.head_horizontal.active  = sprites.head_horizontal.gabby
        sprites.head_vertical.active    = sprites.head_vertical.gabby
    elseif active_effect == "invisible_apple" then
        sprites.head_horizontal.active  = sprites.head_horizontal.welly
        sprites.head_vertical.active    = sprites.head_vertical.welly
    elseif active_effect == "flip" then
        sprites.head_horizontal.active  = sprites.head_horizontal.bryce
        sprites.head_vertical.active    = sprites.head_vertical.bryce
    elseif active_effect == "teleport_apple" then
        sprites.head_horizontal.active  = sprites.head_horizontal.kell
        sprites.head_vertical.active    = sprites.head_vertical.kell
    elseif active_effect == "egg" then
        sprites.head_horizontal.active  = sprites.head_horizontal.jenna
        sprites.head_vertical.active    = sprites.head_vertical.jenna
    elseif active_effect == "speed" then
        sprites.head_horizontal.active  = sprites.head_horizontal.jaz
        sprites.head_vertical.active    = sprites.head_vertical.jaz

        
    -- default sprite curses
    elseif active_effect == "invisible_head" then
        sprites.head_horizontal.active  = sprites.head_horizontal.default
        sprites.head_vertical.active    = sprites.head_vertical.default
    elseif active_effect == "smelly" then
        sprites.head_horizontal.active  = sprites.head_horizontal.default
        sprites.head_vertical.active    = sprites.head_vertical.default
    elseif active_effect == "default" then
        sprites.head_horizontal.active  = sprites.head_horizontal.default
        sprites.head_vertical.active    = sprites.head_vertical.default
    end

end

-- kell teleporting apple
-- bryce flip snake

-- helper function to get the opposite direction
function opposite_direction(dir)
    if dir == directions.right then return directions.left
    elseif dir == directions.left then return directions.right
    elseif dir == directions.up then return directions.down
    elseif dir == directions.down then return directions.up
    end
end

-- helper function to convert direction to dx
function direction_to_dx(dir)
    if dir == directions.right then return 1
    elseif dir == directions.left then return -1
    else return 0
    end
end

-- helper function to convert direction to dy
function direction_to_dy(dir)
    if dir == directions.down then return 1
    elseif dir == directions.up then return -1
    else return 0
    end
end


