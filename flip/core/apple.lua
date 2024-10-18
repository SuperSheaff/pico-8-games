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
