-- apple.lua

-- Function to create an apple at a random position
function spawn_apple()
    local apple = {}
    local valid_position = false
    
    -- Keep generating a new position until it's valid
    while not valid_position do
        apple.x = flr(rnd((screen_size - border_size * 2) / grid_size)) + (border_size / grid_size)
        apple.y = flr(rnd((screen_size - border_size * 2 - score_bar.height) / grid_size)) + (border_size / grid_size)
        
        -- Check if the new apple position is valid
        valid_position = is_empty_position(apple.x, apple.y)
    end
    
    -- Check if the next apple should be golden
    if next_apple_golden or test_mode then
        apple.sprite_id = sprites.golden_apple
        apple.is_golden = true
        next_apple_golden = false -- Reset the flag after spawning golden apple
    else
        apple.sprite_id = sprites.apple
        apple.is_golden = false
    end

    -- Apple drawing function
    function apple:draw()
        -- Check the current state of the apple
        if not invisible_apples or self.state == "visible" then
            -- Draw the normal or golden apple sprite
            spr(self.sprite_id, self.x * grid_size, self.y * grid_size)
        elseif self.state == "semi-transparent" then
            -- Draw the semi-transparent apple sprite
            spr(sprites.semi_transparent_apple, self.x * grid_size, self.y * grid_size)
        end
        -- Do not draw if state is "invisible" and curse is active
    end

    -- Apple update function for handling invisible apple curse
    function apple:update()
        if invisible_apples then
            if self.state == "visible" then
                self.timer += 1
                if self.timer >= 15 then -- 1 second delay (assuming 30 FPS)
                    self.state = "semi-transparent"
                    self.timer = 0
                end
            elseif self.state == "semi-transparent" then
                self.timer += 1
                if self.timer >= 15 then -- 1 second delay
                    self.state = "invisible"
                    self.timer = 0
                end
            end
        else
            -- Reset state to visible if curse is not active
            self.state = "visible"
            self.timer = 0
        end
    end

    -- Initialize apple state and timer
    apple.state = "visible"
    apple.timer = 0

    return apple
end
