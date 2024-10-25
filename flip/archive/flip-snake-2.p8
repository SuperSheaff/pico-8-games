pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- flip-snake.p8, a game by ben fowler

-- logging utilities
function log(text, overwrite)
    printh(text, "utilities/log", overwrite)
end



-- constants, global variables
-- variables.lua

-- constants
grid_size = 8                          -- size of each grid cell in the game
base_update_rate = 5                   -- base speed for the snake movement, adjust to change default speed
update_rate = base_update_rate         -- current speed of the snake, which can change with curses
screen_size = 128                      -- size of the game screen in pixels
score = 0

test_mode = false                      -- set this to true to only spawn golden apples for testing purposes

is_paused       = false
pause_duration  = 30                   -- Number of frames to pause (1 second at 60 FPS)
pause_timer     = 0


-- border and score bar
border_size = 8                        -- thickness of the border around the play area
score_bar = {                          -- settings for the score bar at the top of the screen
    color       = 7,                   -- color of the score bar
    text_color  = 0,                   -- color of the text in the score bar
    height      = border_size          -- height of the score bar, same as the border size
}
background_color = 0                   -- background color of the game screen

-- sprite ids
sprites = {                            
    tail_horizontal         = 1,        -- id for horizontal snake tail sprite
    body_horizontal         = 2,        -- id for horizontal snake body sprite
    head_horizontal         = {         -- id's for horizontal snake headsprites
        active              = 3,
        default             = 3,                  
        welly               = 32,                  
        doug                = 33,                  
        benny               = 34,                  
        bryce               = 35,                  
        reno                = 36,                  
        gabby               = 37,                  
        kell                = 38,                  
        jenna               = 39,                  
        jaz                 = 40,                  
    },    
    tail_vertical           = 17,       -- id for vertical snake tail sprite
    body_vertical           = 18,       -- id for vertical snake body sprite
    head_vertical           = {         -- id's for vertical snake headsprites
        active              = 19,
        default             = 19,                  
        welly               = 48,                  
        doug                = 49,                  
        benny               = 50,                  
        bryce               = 51,                  
        reno                = 52,                  
        gabby               = 53,                  
        kell                = 54,                  
        jenna               = 55,                  
        jaz                 = 56,                  
    },      
    corner                  = 4,        -- id for corner sprite (snake turns)
    apple                   = 5,        -- id for regular apple sprite
    golden_apple            = 6,        -- id for golden apple sprite
    semi_apple              = 21,       -- id for semi-transparent apple sprite (used in invisible apple curse)
    semi_golden_apple       = 22,       -- id for semi-transparent golden apple sprite
    skull                   = 8,        -- id for skull sprite
    poop                    = 9,        -- id for poop sprite
    egg                     = 25        -- id for poop sprite
}

-- sound ids
sounds = {
    eat_apple               = 0,       -- id for eating an apple sound
    game_tick               = 1,       -- id for game tick sound (when snake moves)
    ui_move                 = 3,       -- id for UI navigation sound
    ui_select               = 4        -- id for UI selection sound
}

-- directions
directions = {
    right   = 0,                       -- direction to the right
    down    = 1,                       -- direction downwards
    left    = 2,                       -- direction to the left
    up      = 3                        -- direction upwards
}

-- game state variables
game_state = "play"                    -- current game state, possible values: "play", "choose_curse", "resume_delay"

-- game over screen flash effect
flash = {
    count = 0,                         -- number of flashes that have occurred
    max_count = 8,                     -- total number of flashes before showing game over screen
    interval = 5,                      -- number of frames between each flash (controls flash speed)
    state = false,                     -- flash state toggle, true for flash, false for normal state
    timer = 0                          -- timer to control flash speed
}

-- snake variables
last_direction = directions.right      -- stores the last direction the snake moved in

-- apple variables
apples_eaten = 0                       -- total number of apples eaten by the snake
golden_apple_frequency = 10            -- spawn a golden apple every 10 apples eaten
speed_increase_per_golden = 1          -- increase the snake's speed by this amount for each golden apple eaten

-- curse variables
curses = {                             -- list of all possible curses
    { 
        name = "benny",       -- internal name of the curse
        text = "invisible body",       -- text displayed on the curse selection screen
        effect = "invisible",          -- effect name to apply during gameplay
        apple_range = {min = 1, max = 10} -- Range of apples for this curse
    },
    { 
        name = "doug", 
        text = "double length", 
        effect = "long",
        apple_range = {min = 1, max = 10} -- Range of apples for this curse
    },
    { 
        name = "reno", 
        text = "spikes", 
        effect = "spikes",
        apple_range = {min = 2, max = 10} -- Range of apples for this curse
    },
    { 
        name = "gabby", 
        text = "reverse controls", 
        effect = "reverse_controls",
        apple_range = {min = 1, max = 5} -- Range of apples for this curse
    },
    { 
        name = "welly", 
        text = "invisible apple", 
        effect = "invisible_apple",
        apple_range = {min = 3, max = 10} -- Range of apples for this curse
    },
    { 
        name = "jaz", 
        text = "extra speed", 
        effect = "speed",
        apple_range = {min = 1, max = 7} -- Range of apples for this curse
    },
    { 
        name = "bryce", 
        text = "swap head with tail", 
        effect = "flip",
        apple_range = {min = 1, max = 10} -- Range of apples for this curse
    },
    { 
        name = "kell", 
        text = "teleporting apple", 
        effect = "teleport_apple",
        apple_range = {min = 2, max = 10} -- Range of apples for this curse
    },
    { 
        name = "jenna", 
        text = "lay an egg", 
        effect = "egg",
        apple_range = {min = 1, max = 5} -- Range of apples for this curse
    }
     -- { 
    --     name = "headless", 
    --     text = "invisible head", 
    --     effect = "invisible_head",
    --     apple_range = {min = 1, max = 7} -- Range of apples for this curse
    -- },
}

selected_curse      = 1                -- currently selected curse, 1 for top, 2 for bottom
selected_curses     = {}               -- table holding the two selected curses to choose from
curses_randomized   = false            -- flag to ensure curses are randomized once per golden apple
curse_counts        = { 0, 0 }         -- stores the number of apples required to end each selected curse
active_effect       = "default"              -- stores the current active effect applied by a curse

-- spike variables
spikes              = {}                            -- table to hold all active spike objects on the screen
poop_trail          = {}    
egg_trail           = {}                    -- table to store poop positions
egg_counter         = 0
egg_interval        = 5 -- Set the interval

resume_delay = 0                       -- time in frames to wait before resuming the game after curse selection
invisible_apples = false               -- flag to indicate if invisible apple curse is active
teleporting_apples    = false                  -- flag to indicate if teleport apple curse is active
active_curses     = {}                     -- table to hold all currently active curses




-- snake movement, collision, rendering
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






-- apple spawning, rendering
-- apple.lua

-- function to create an apple at a random position
function spawn_apple()
    local apple = {}
    local valid_position = false
    local is_teleporting = false
    local teleport_timer = 0
    local flash_timer = 0
    local flash_interval = 10
    local flash_state = true

    -- keep generating a new position until it's valid
    while not valid_position do
        apple.x = flr(rnd((screen_size - border_size * 2) / grid_size)) + (border_size / grid_size)
        apple.y = flr(rnd((screen_size - border_size * 2 - score_bar.height) / grid_size)) + (border_size / grid_size)
        
        -- check if the new apple position is valid
        valid_position = is_empty_position(apple.x, apple.y)
    end
    
    -- check if the next apple should be golden
    if next_apple_golden or test_mode then
        apple.sprite_id = sprites.golden_apple
        apple.is_golden = true
        next_apple_golden = false -- reset the flag after spawning golden apple
    else
        apple.sprite_id = sprites.apple
        apple.is_golden = false
    end

    -- function to draw the apple
    function apple:draw()
        -- Determine if the apple should be drawn
        local should_draw = true

        -- If teleporting, use the flash state to determine visibility
        if teleporting_apples and self.is_teleporting then
            should_draw = self.flash_state
        end

        -- Draw the apple if it should be visible
        if should_draw then
            local sprite_to_draw = get_apple_sprite(self)
            if sprite_to_draw then
                spr(sprite_to_draw, self.x * grid_size, self.y * grid_size)
            end
        end
    end

    -- function to update the apple state
    function apple:update()
        if invisible_apples then
            update_apple_state(self)
        else
            reset_apple_state(self)
        end

        -- Check for global teleporting_apples state
        if teleporting_apples then
            if not self.is_teleporting then
                -- Start teleportation process if not already started
                self:start_teleport()
            end

            -- Handle teleportation logic
            if self.is_teleporting then
                if self.teleport_timer > 0 then
                    -- Waiting phase: keep the apple visible
                    self.teleport_timer = self.teleport_timer - 1
                    self.flash_state = true -- Ensure apple is visible during waiting
                else
                    -- Flashing phase
                    self.flash_timer = self.flash_timer + 1
                    if self.flash_timer >= self.flash_interval then
                        self.flash_state = not self.flash_state
                        self.flash_timer = 0
                        -- Decrease the interval to make flashing faster
                        if self.flash_interval > 1 then
                            self.flash_interval = self.flash_interval - 1
                        end
                    end

                    -- Check if flashing is done
                    if self.flash_interval == 1 and not self.flash_state then
                        self:teleport()
                    end
                end
            end
        end
    end

    function apple:start_teleport()
        self.is_teleporting = true
        self.teleport_timer = 30 -- Wait for 1 second (60 frames at 60 FPS)
        self.flash_timer = 0
        self.flash_interval = 10
    end

    function apple:teleport()
        local valid_position = false

        -- Keep generating a new position until it's valid
        while not valid_position do
            -- Generate a random position within the screen bounds
            local new_x = flr(rnd((screen_size - border_size * 2) / grid_size)) + (border_size / grid_size)
            local new_y = flr(rnd((screen_size - border_size * 2 - score_bar.height) / grid_size)) + (border_size / grid_size)

            -- Check if the new apple position is valid
            valid_position = is_empty_position(new_x, new_y)

            -- If valid, update the apple's position
            if valid_position then
                self.x = new_x
                self.y = new_y
            end
        end

        self.is_teleporting = false
        self.flash_state = true -- Ensure apple is visible after teleporting
    end
    

    -- initialize apple state and timer
    apple.state = "visible"
    apple.timer = 0

    return apple
end

-- function to set apple type (normal or golden)
function set_apple_type(apple, type)
    if type == "golden" then
        apple.sprite_id = sprites.golden_apple
        apple.is_golden = true
    else
        apple.sprite_id = sprites.apple
        apple.is_golden = false
    end
end

-- function to get the correct apple sprite based on state and type
function get_apple_sprite(apple)
    if not invisible_apples or apple.state == "visible" then
        return apple.sprite_id -- normal or golden apple sprite
    elseif apple.state == "semi-transparent" then
        if apple.is_golden then
            return sprites.semi_golden_apple -- semi-transparent golden apple
        else
            return sprites.semi_apple -- semi-transparent normal apple
        end
    else
        return nil -- invisible state, do not draw
    end
end

-- function to update apple state during invisible apple curse
function update_apple_state(apple)
    if apple.state == "visible" then
        apple.timer += 1
        if apple.timer >= 15 then -- 1 second delay (assuming 30 fps)
            apple.state = "semi-transparent"
            apple.timer = 0
        end
    elseif apple.state == "semi-transparent" then
        apple.timer += 1
        if apple.timer >= 15 then -- 1 second delay
            apple.state = "invisible"
            apple.timer = 0
        end
    end
end

-- function to reset apple state when curse is not active
function reset_apple_state(apple)
    apple.state = "visible"
    apple.timer = 0
end




-- curse selection, curse activation
-- curse.lua

-- handle player input for curse selection
function handle_curse_selection()
    if not curses_randomized then
        shuffle_curses()
        curses_randomized = true
    end

    -- up arrow to select curse 1
    if btnp(2) then
        sfx(sounds.ui_move)
        selected_curse = 1
    end

    -- down arrow to select curse 2
    if btnp(3) then
        sfx(sounds.ui_move)
        selected_curse = 2
    end

    -- x button to confirm selection
    if btnp(5) then
        sfx(sounds.ui_select)
        apply_curse(selected_curse)
        set_resume_delay(30) -- 1 second delay before resuming the game
        game_state = "resume_delay"
        curses_randomized = false
    end
end

-- shuffle and select two random curses
function shuffle_curses()
    selected_curses = {} -- clear previous selections
    local available_indices = get_available_curse_indices()

    for i = 1, 2 do
        local random_index = flr(rnd(#available_indices)) + 1
        local selected_index = available_indices[random_index]
        deli(available_indices, random_index) -- remove selected index from available list

        local curse = curses[selected_index]
        local min_apples = curse.apple_range.min
        local max_apples = curse.apple_range.max

        -- Calculate a bias factor based on the score
        local bias_factor = score / 1000 -- Adjust this factor to control scaling
        if bias_factor > 1 then bias_factor = 1 end -- Cap the bias factor at 1

        -- Generate a weighted random count
        local range = max_apples - min_apples
        local weighted_random = flr(rnd(range * (1 - bias_factor))) + min_apples + flr(range * bias_factor)

        add(selected_curses, { curse = curse, count = weighted_random })
    end
end

-- get all available curse indices
function get_available_curse_indices()
    local indices = {}
    for i = 1, #curses do
        add(indices, i)
    end
    return indices
end

-- apply the selected curse to the game
function apply_curse(selected_curse_index)
    local chosen_curse = selected_curses[selected_curse_index]
    local curse = chosen_curse.curse.effect
    local count = chosen_curse.count

    add(active_curses, {
        curse = curse,
        required_apples = count,
        start_apples = apples_eaten
    })

    active_effect = curse

    if curse == "invisible" then
        apply_invisible_body_curse()
    elseif curse == "speed" then
        apply_extra_speed_curse()
    elseif curse == "spikes" then
        spawn_spikes(10)
    elseif curse == "reverse_controls" then
        apply_reverse_controls_curse()
    elseif curse == "invisible_apple" then
        apply_invisible_apple_curse()
    elseif curse == "invisible_head" then
        apply_invisible_head_curse()
    elseif curse == "smelly" then
        apply_smelly_curse()
    elseif curse == "flip" then
        apply_flip_curse()
    elseif curse == "teleport_apple" then
        apply_teleport_apple_curse()
    elseif curse == "egg" then
        apply_egg_curse()
    elseif curse == "long" then
        apply_long_curse()
    end

    update_current_head_sprite()
end

-- check if any active curse should end
function check_curse_end()
    for curse in all(active_curses) do
        if apples_eaten - curse.start_apples >= curse.required_apples - 1 then
            end_curse(curse.curse)
            del(active_curses, curse) -- remove from active curses
        end
    end

    -- check if there are no more active curses
    if #active_curses == 0 then
        active_effect = "default"
    end

    update_current_head_sprite()
end

-- end the specified curse effect
function end_curse(curse)
    if curse == "invisible" then
        end_invisible_body_curse()
    elseif curse == "speed" then
        end_extra_speed_curse()
    elseif curse == "spikes" then
        remove_spikes()
    elseif curse == "reverse_controls" then
        end_reverse_controls_curse()
    elseif curse == "invisible_apple" then
        end_invisible_apple_curse()
    elseif curse == "invisible_head" then
        end_invisible_head_curse()
    elseif curse == "smelly" then
        end_smelly_curse()
    elseif curse == "flip" then
        end_flip_curse()
    elseif curse == "teleport_apple" then
        end_teleport_apple_curse()
    elseif curse == "egg" then
        end_egg_curse()
    elseif curse == "long" then
        end_long_curse()
    end 
end

-- apply invisible body curse
function apply_invisible_body_curse()
    snake.invisible_body = true
end

-- end invisible body curse
function end_invisible_body_curse()
    snake.invisible_body = false
end

-- apply extra speed curse
function apply_extra_speed_curse()
    update_rate = max(1, update_rate - 2)
end

-- end extra speed curse
function end_extra_speed_curse()
    update_rate = base_update_rate
end

-- apply reverse controls curse
function apply_reverse_controls_curse()
    snake.reversed = true
end

-- end reverse controls curse
function end_reverse_controls_curse()
    snake.reversed = false
end

-- apply teleport apple curse
function apply_teleport_apple_curse()
    teleporting_apples = true
end

-- end teleport apple curse
function end_teleport_apple_curse()
    teleporting_apples = false
end

-- apply flip curse
function apply_flip_curse()
    snake.flipped = true
end

-- end flip curse
function end_flip_curse()
    snake.flipped = false
end

-- apply egg curse
function apply_egg_curse()
    snake.egg = true
end

-- end egg curse
function end_egg_curse()
    remove_egg_trail()
    snake.egg = false
end

-- apply long curse
function apply_long_curse()
    snake:activate_long_curse()
end

-- end long curse
function end_long_curse()
    snake:deactivate_long_curse()
end

-- apply invisible apple curse
function apply_invisible_apple_curse()
    invisible_apples = true
end

-- end invisible apple curse
function end_invisible_apple_curse()
    invisible_apples = false
    apple.state = "visible"
    apple.timer = 0
end

-- apply invisible head curse
function apply_invisible_head_curse()
    snake.invisible_head = true
end

-- end invisible head curse
function end_invisible_head_curse()
    snake.invisible_head = false
end

-- apply invisible head curse
function apply_smelly_curse()
    snake.smelly = true
end

-- end invisible head curse
function end_smelly_curse()
    remove_poop()
    snake.smelly = false
end

-- set a delay before resuming the game
function set_resume_delay(frames)
    resume_delay = frames
end

-- spawn a specific number of spikes on the game area
function spawn_spikes(count)
    spikes = {} -- clear existing spikes

    for i = 1, count do
        local spike = generate_valid_spike()
        add(spikes, spike)
    end
end

-- generate a valid spike position that does not overlap with other objects
function generate_valid_spike()
    local spike = {}
    local valid_position = false

    while not valid_position do
        spike.x = flr(rnd((screen_size - border_size * 2) / grid_size)) + (border_size / grid_size)
        spike.y = flr(rnd((screen_size - border_size * 2 - score_bar.height) / grid_size)) + (border_size / grid_size)
        valid_position = is_empty_position(spike.x, spike.y)
    end

    return spawn_spike(spike.x, spike.y)
end

-- remove all spikes from the game area
function remove_spikes()
    spikes = {}
end

-- draw all active spikes
function draw_spikes()
    for spike in all(spikes) do
        spike:draw()
    end
end

-- create a spike object at a given position
function spawn_spike(x, y)
    local spike = {
        x = x,
        y = y,
        sprite_id = 7 -- assuming 7 is the sprite id for spikes
    }

    function spike:draw()
        spr(self.sprite_id, self.x * grid_size, self.y * grid_size)
    end

    return spike
end

function draw_poop_trail()
    for poop in all(poop_trail) do
        spr(poop.sprite_id, poop.x * grid_size, poop.y * grid_size)
    end
end

function draw_egg_trail()
    for egg in all(egg_trail) do
        spr(egg.sprite_id, egg.x * grid_size, egg.y * grid_size)
    end
end

-- remove all spikes from the game area
function remove_poop()
    poop_trail = {}
end

-- remove all spikes from the game area
function remove_egg_trail()
    egg_trail = {}
end




-- user interface rendering
-- ui.lua
-- UI-related functions for drawing the score, border, and game over screen.

ui = {}

-- draw the score bar and borders around the screen
function ui:draw_border()
    -- top border (score bar)
    rectfill(0, 0, screen_size - 1, border_size - 2, score_bar.color)

    -- left border
    rectfill(0, border_size - 1, border_size - 2, screen_size - 1, score_bar.color)

    -- right border
    rectfill(screen_size - border_size + 1, border_size - 1, screen_size - 1, screen_size - 1, score_bar.color)

    -- bottom border
    rectfill(border_size - 1, screen_size - border_size + 1, screen_size - border_size, screen_size - 1, score_bar.color)
end

-- draw the score and game name inside the score bar
function ui:handle_score()
    -- draw score text
    print("score: "..score, 7, 1, score_bar.text_color) -- display the current score
    
    -- draw game name
    local game_name = "flip snake"
    local text_width = #game_name * 4 -- approximate width calculation
    print(game_name, screen_size - text_width - 6, 1, score_bar.text_color) -- display game name at top right
end

-- start the game over sequence with flashing effect
function ui:start_game_over_sequence()
    game_state = "game_over"
    flash.count = 0 -- reset flash counter
    flash.state = false -- reset flash state
    flash.timer = 0 -- reset flash timer
end

-- function to draw the game over screen
function ui:draw_game_over_screen()
    -- calculate dimensions for the "GAME OVER" box
    local game_over_text = "game over"
    local game_over_width = #game_over_text * 4 -- approximate width of each character
    local game_over_height = 5 -- approximate height of text
    local game_over_box_x = (screen_size - game_over_width - 5) / 2 -- centered x position
    local game_over_box_y = 50 -- y position for the first box
    local game_over_box_w = game_over_box_x + game_over_width + 5 -- width of the box
    local game_over_box_h = game_over_box_y + game_over_height + 5 -- height of the box

    -- calculate dimensions for the "press X to restart" box
    local instruction_text = "press X to restart"
    local instruction_width = #instruction_text * 4 -- approximate width of each character
    local instruction_height = 5 -- approximate height of text
    local instruction_box_x = (screen_size - instruction_width - 5) / 2 -- centered x position
    local instruction_box_y = game_over_box_y + 20 -- y position below the first box
    local instruction_box_w = instruction_box_x + instruction_width + 5 -- width of the box
    local instruction_box_h = instruction_box_y + instruction_height + 5 -- height of the box

    -- draw background box for the "GAME OVER" text
    rectfill(game_over_box_x, game_over_box_y, game_over_box_w, game_over_box_h, 7) -- white background box
    -- draw "GAME OVER" in big text with black color
    print(game_over_text, game_over_box_x + 4, game_over_box_y + 4, 0) -- position text inside the box with color 0 (black)
    
    -- draw background box for the instruction text
    rectfill(instruction_box_x, instruction_box_y, instruction_box_w, instruction_box_h, 7) -- white background box
    -- display restart instruction with black color
    print(instruction_text, instruction_box_x + 4, instruction_box_y + 4, 0) -- position text inside the box with color 0 (black)
end

-- function to draw the game over effects
function ui:draw_game_over_effects()
    if flash.count < flash.max_count then
        self:draw_flash_effect()
    else
        self:draw_game_over_screen()
    end
end

-- function to handle flashing effect
function ui:draw_flash_effect()
    -- flash the screen during the game over sequence
    if flash.state then
        -- fill the entire play area with white
        rectfill(border_size, border_size, screen_size - border_size - 1, screen_size - border_size - 1, 7)
    end
end

-- function to update flash effect
function ui:update_flash_effect()
    -- slow down the flash speed by using a timer
    flash.timer += 1
    if flash.timer >= flash.interval then
        flash.state = not flash.state -- toggle flash state
        flash.count += 1
        flash.timer = 0 -- reset timer
    end
end

-- function to reset flash state
function ui:reset_flash_state()
    flash.count = 0
    flash.timer = 0
    flash.state = false
end

-- function to draw the curse selection screen
function ui:draw_curse_screen()
    -- ensure selected_curses is populated
    if #selected_curses < 2 then
        return
    end

    -- define UI border dimensions and gap
    local border_x = border_size
    local border_y = border_size
    local ui_width = screen_size - border_size * 2 - 3 -- reduce width by 2 (1 pixel on each side)
    local ui_height = screen_size - border_size * 2 - 6 -- reduce height by 2 (1 pixel on each side)

    -- draw black rectangle to cover snake and background elements
    rectfill(border_x, border_y, border_x + ui_width + 2, border_y + ui_height + 5, 0)

    -- calculate rectangle dimensions
    local rect_width = ui_width
    local rect_height = (ui_height / 2) - 4 -- Adjust height for gap and alignment

    -- calculate positions for curse 1 and curse 2 rectangles
    local curse1_rect_y = border_y + 1
    local curse2_rect_y = curse1_rect_y + rect_height + 10

    -- draw the curses
    ui:draw_curse_box(selected_curses[1], border_x + 1, curse1_rect_y, rect_width, rect_height, selected_curse == 1)
    ui:draw_curse_box(selected_curses[2], border_x + 1, curse2_rect_y, rect_width, rect_height + 1, selected_curse == 2)

    -- draw "or" in the middle of the screen, centered vertically
    local or_text = "or"
    local or_text_width = #or_text * 4 -- width of the text "or" in pixels (4 pixels per character)
    local or_x = (screen_size - or_text_width) / 2 -- center of the screen minus half the text width
    local or_y = screen_size / 2 - 3 -- adjust y-position to center vertically between curses
    print(or_text, or_x, or_y, 7)

    -- draw "Press X to select" message at the bottom
    ui:draw_select_message()
end

-- function to draw a single curse box with title, name, and count
function ui:draw_curse_box(curse_info, x, y, width, height, is_selected)
    -- draw the white background rectangle
    rectfill(x, y, x + width, y + height, 7)

    -- extract the title, name, and count for the curse
    local title = "curse of the " .. curse_info.curse.name
    local name = curse_info.curse.text
    local count = "for \f8" .. curse_info.count .. "\f0 apples"

    -- calculate widths for centering using `print()` function and measuring
    local text_width_title = print(title, 0, -6) -- measure width without drawing
    local text_width_name = print(name, 0, -6)
    local text_width_count = print(count, 0, -6)

    -- draw the title at the top
    local title_y = y + 3
    print(title, x + (width / 2) - (text_width_title / 2), title_y, 8)

    -- draw a black line under the title
    local line_y = title_y + 8
    rectfill(x, line_y, x + width, line_y, 0)

    -- draw the icons on either side of the title
    draw_curse_icons(x, y, width, title_y)

    -- calculate center for the name and count
    local center_y = y + (height / 2) + 2

    -- draw the name and count in the remaining space
    print(name, x + (width / 2) - (text_width_name / 2), center_y - 4, 0)
    print(count, x + (width / 2) - (text_width_count / 2), center_y + 4, 0)

    -- draw the flashing border if this curse is selected
    if is_selected then
        draw_pulsing_border(x - 1, y - 1, width + 2, height + 2, 8, 14)
    end
end

-- function to draw icons on either side of the title with black background
function draw_curse_icons(x, y, width, title_y)
    -- hard-coded icon sprite ID
    local icon_id = 8

    -- icon size (assuming 7x7)
    local icon_size = 7

    -- calculate positions for the icons
    local left_icon_x = x + 2 -- left side of the box
    local right_icon_x = x + width - icon_size - 1 -- right side of the box
    local icon_y = title_y - 1 -- align slightly above the title

    -- draw a black background square for each icon
    rectfill(left_icon_x, icon_y, left_icon_x + icon_size - 1, icon_y + icon_size - 1, 0) -- black square for left icon
    rectfill(right_icon_x, icon_y, right_icon_x + icon_size - 1, icon_y + icon_size - 1, 0) -- black square for right icon

    -- draw the icons
    spr(icon_id, left_icon_x, icon_y) -- draw left icon
    spr(icon_id, right_icon_x, icon_y) -- draw right icon
end

-- function to draw a pulsing border with an inside red square
function draw_pulsing_border(x, y, width, height, color1, color2)
    -- draw the red square inside the border
    local red_square_margin = 1 -- margin between the border and red square

    -- timer to control the pulsing effect
    if pulsing_timer == nil then 
        pulsing_timer = 0
    end

    -- update the pulsing timer
    pulsing_timer += 0.05 -- increment timer to control pulsing speed

    -- choose the color based on the timer
    local current_color = pulsing_timer % 1 < 0.5 and color1 or color2

    -- draw the pulsing border with the current color
    rect(x, y, x + width, y + height, current_color)
end
    
-- function to draw "Press X to select" message at the bottom center
function ui:draw_select_message()
    local message = "press x to select"
    local message_width = #message * 4 -- calculate message width based on character count

    -- calculate the x position to center the message horizontally
    local message_x = (screen_size - message_width) / 2

    -- y position just above the bottom UI border
    local message_y = screen_size - 6

    -- draw the message in black color
    print(message, message_x, message_y, 0)
end




-- main game loop, initialization, directions.updates
-- main.lua

-- native init
function _init()
    reset_game_state()

    -- swaps one of the colors
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
    draw_egg_trail()   -- draw all active poop
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




__gfx__
000000000000000000000000077777700000000000088000000bb000000700707000007700004000111111101111111000000000000000000000000000000000
0000000000777777777777777777777700007777000080000000b000700707000000000700044400111111101111111000000000000000000000000000000000
0070070007777777777777777777777700077777088808800bbb0bb0070770000000000700444400111111101111111000000000000000000000000000000000
000770007000077700007777777077070077770088888888bbbbbbbb007777770770770700000440111111101111111000000000000000000000000000000000
000770007777700077770000777777770777707788888888bbbbbbbb777777000000000704444444111111101111111000000000000000000000000000000000
007007000777777777777777777777770777077788888888bbbbbbbb000770707000007744444444111111101111111000000000000000000000000000000000
0000000000777777777777777777007007707777088880800bbbb0b0007070077070707744000004111111101111111000000000000000000000000000000000
00000000000000000000000000777700077077700088080000bb0b00070070007777777704444400000000000000000000000000000000000000000000000000
077777700777077007770770077777000000000000088000000bb000000000000000000000077000000000000000000000000000000000000000000000000000
7777777707770770077707707770777000000000000080000000b000000000000000000000777700000000000000000000000000000000000000000000000000
7707777007770770077707707777770700000000088808800bbb0bb0000000000000000000f77700000000000000000000000000000000000000000000000000
777770000770777007770770777777070000000080000008b000000b00000000000000000ff777f0000000000000000000000000000000000000000000000000
777770000770777007707770777077770000000080000008b000000b000000000000000007777ff0000000000000000000000000000000000000000000000000
777777700770777007707770777777770000000080000008b000000b000000000000000007ff77f0000000000000000000000000000000000000000000000000
7777777700707700077077707777777000000000080080800b00b0b0000000000000000007ff7770000000000000000000000000000000000000000000000000
07777770000770000770777007777770000000000088080000bb0b00000000000000000000777700000000000000000000000000000000000000000000000000
04444440077777000444444044444440011111101111111011111110181111100044444000000000000000000000000000000000000000000000000000000000
47744477770ccccc4444447404777774177777711111171171111111811777710447777400000000000000000000000000000000000000000000000000000000
4777777700cbbbbb4777777747777777771171171777777717711111117777774447777700000000000000000000000000000000000000000000000000000000
4770770700ccbbbb4770770747707707777077071770770771707707177077074470770700000000000000000000000000000000000000000000000000000000
47777777770ccccc7777777747777777777777777777777717777777777777774477777700000000000000000000000000000000000000000000000000000000
77755557777444477777777777744447777111177777777777777777777777774477777700000000000000000000000000000000000000000000000000000000
55557750444400407777007044447740111177107777007017778870777700704477007000000000000000000000000000000000000000000000000000000000
00555500004444000077770000444400001111000077770010777700007777004477770000000000111000000000000000000000000000000000000000000000
077777000cbbc7000477770004777700017777000177770001177700017777000477770011111111111100000000000000000000000000000000000000000000
477075500cbbc4404770777047707440171071101170777011107770177077704770777011111111111110000000000000000000000000000000000000000000
447775757cbbc4044477770747777474171771711777770711177787177777074777770711111111111111000000000000000000000000000000000000000000
447775757cbbc4044477770747777474177771711177770711177787177777074777770711111111111111110000000000000000000000000000000000000000
447075557cbcc4444470777747707444171071111170777711107777177077774770777711110000000111110000000000000000000000000000000000000000
4777775570cc07444477777747777744171777111177777711777777117777774447777711000000000011110000000000000000000000000000000000000000
47777750770077404477777044777740177777101177777011717770811777700444444400000000000001111000000000000000000000000000000000000000
04444750070077400444777040444740017777101111777017171711181177700044444400000000000000111000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000011110000000000100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000011110000000001000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111100011000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111100011000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111100010000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111000010000000000111100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111000000000000000111110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001110000000000000000111100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001100000100000000000111000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001100001100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000011100001100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000011000011100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000111001111100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000111111111100000011111000000000000000000000000001111111110000000000
00000000000000000000000000000000000000000000000000000000000001111111100100001111111110000000000000000000111111111111111110000000
00000000000000000000000000000000000000000000000000000000000001111000000100111001111110000000000000000001111111111111111111100000
00000000000000000000000000000000000000000000000000000000000011110000000101100000011111000000000000000111111111100001111111110000
00000000000000000000000000000000000000000000000000000000000011110000001111000000011111000000000000001111111100000000001111111000
00000000000000000000000000000000000000000000000000000000000111110000001110000000001111000000000000011111111000000000001111111000
00000000000000000000000000000000000000000000000000000000000111110000001100000000001111000000000000111111100000000000000111111000
00000000000000000000000000000000000000000000000000000000000111110000001100000000001111000000000001111111000000000000000001111100
00000000000000000000000000000000000001111111000000000000001111110000011100000000001111000000000001111110000000000000000000111100
00000000000000000000000000000000011111111111111100000000011111110000011100000000001111000000000011111110000000000000000000111100
00000000000000000000000000000000111111111111111111111111111111110000011100000000001111000000000011111100000000000000000000111110
00000000000000000000000000000001111111000000001110000011111111100000111100000000011110000000000111111000000000000000000000011110
00000000000000000000000000000111111100000000000011000000111111100000111100000000011110000000000111110000000000000000000000011110
00000000000000000000000000000111111000000000000001000000111111000000111100000000011110000000001111110000000000000000000000011110
00000000000000000000000000001111110000000000000001000000111111000001111000000000111100000000011111100000000000000000000000111110
00000000000000000000000000011111000000000000000000100000111110000001111000000000111100000000011111000000000000000000000000111100
00000000000000000000000000011110000000000000000000100001111110000001111000000001111100000000111111000000000000000000000000111100
00000000000000000000000000111110000000000000000000000001111100000011110000000001111000000000111111000000000000000000000001111100
00000000000000000000000000111100000000000000000000000011111100000011110000100001111000000000111110000100000000000000000001111000
00000000000000000000000000111100000000000000000000000011111000000011110000000011111000000001111110000100000000000000000011111000
00000000000000000000000000111100000000000000000000000111111000000011110001000011111000000001111110000110000000000000000011111000
00000000000000000000000001111100000000000000000000000111110000000000000010000111110000000011111100000011000000000000001111110000
00000000000000000000000001111000000000000000000000001111100000000000000100000111110000000011111100000011000000000000011111100000
00000000000000000000000001111000000000000000000000011111100000000000011000001111110000000011111100000001100000000000111111000000
00000000000000000000000001111100000000000000000000011111000000000000010000001111100000000111111111111111111000000111111110000000
00000000000000000000000001111100000000000000000000111111000000001111100000001111100001111111111000001111111111111111111100000000
00000000000000000000000000111100000000000000000001111111000000001111100000001111000111111111111000000000111111111111110000000000
00000000000000000000000000111110000000000000000001111111000000000000000000011111111111001111110000000000000000110000000000000000
00000000000000000000000000111110000000000000000011111110000000000000000000011111111100011111100000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000111111111000011111100000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000111111111000111111000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000001111111100000111111000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000011111000000000001111111000001111111000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000011111000000000011111110000001111110000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111110000000000111111100000011111100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000001000000000000111111000000011111100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000001111110000000111111100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000001111110000000111111100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000011111110000000111111100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001000000011111110000000111111000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000100000000011111100000001111110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000001000000000011111000000001111110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000111111000000011111110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000010000000000111110000000011111100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000100000000000000000000000111111000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000100000000000000000000001111111000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001000000000000000000000001111110000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001000000000000000000000011111100000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001000000000000000000000111111100000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001000000000000000000000111111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001000000000000000000001111111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001000000000000000000001111111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001100000000000000000001111111000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001110000000000000000111111110000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001111000000000000001111111100000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001111100000000000011111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111110000000001111111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111111100000111111111110000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000011111111111111111111100000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000001111111111111111110000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000111111111111111100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001111111111110000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000111111111000000000000000000000000000000000000000000000000000000000
__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777007700770070007000777777777007707077777777777777777777777777777777777777770007077700070007777770070077000707070007777777
77777770777077707070707077770777777707707077777777777777777777777777777777777777770777077770770707777707770707070707070777777777
77777770007077707070077007777777777707700077777777777777777777777777777777777777770077077770770007777700070707000700770077777777
77777777707077707070707077770777777707777077777777777777777777777777777777777777770777077770770777777777070707070707070777777777
77777770077700700770707000777777777000777077777777777777777777777777777777777777770777000700070777777700770707070707070007777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000070070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000007077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000077070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000707007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700007000000000000000000000000000000000000700700000000000000000000000000000000007777777
77777770000000000000000000000000000000007070070700000000000000000000000000000000700707000000000000000000000000000000000007777777
77777770000000000000000000000000000000007070070700000000000000000000000000000000070770000000000000000000000000000000000007777777
77777770000000000000000000000000000000007007700700000000000000000000000000000000007777770000000000000000000000000000000007777777
77777770000000000000000000000000000000007000000700000000000000000000000000000000777777000000000000000000000000000000000007777777
77777770000000000000000000000000000000007070000700000000000000000000000000000000000770700000000000000000000000000000000007777777
77777770000000000000000000000000000000007000000700000000000000000000000000000000007070070000000000000000000000000000000007777777
77777770000000000000000000000000000000000700007000000000000000000000000000000000070070000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000000088000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000000008000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000008880880000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000088888888000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000088888888000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000088888888000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000008888080000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000000880800000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700707000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707007000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000707000777777777777777777777777777770000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700700000000000000000000000000000007000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000700070000007777000077770000777777000700000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000070007777770000777700007777000000700070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000007000000000000000000000000000000070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000777777777777777777777777777770007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007070070000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000007007070000000000007007000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000077777770007070000000007007070000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000700000000070070000000000707700000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000007777700000700070000000000077777700000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000007000077777000700000000007777770000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000700000000007000000000000007707000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000077777777770000000000000070700700000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000700700000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

__gff__
0000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001a7501c750217502875000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000097700e77009750047500075026c002cb002cb002cb002cb002cb00000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000016150161501615016150121501215012150121501515015150151501515010150101501015010150151501515015150151500d1500d1500d1500d1501515015150151501515010150101501015010150
000400000812000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001155011550115501155011500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 02424344

