-- apple.lua

-- function to create an apple at a random position
function spawn_apple()
    local apple = {}
    local valid_position = false
    
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
        -- choose the correct sprite based on state and type
        local sprite_to_draw = get_apple_sprite(self)
        if sprite_to_draw then
            spr(sprite_to_draw, self.x * grid_size, self.y * grid_size)
        end
    end

    -- function to update the apple state
    function apple:update()
        if invisible_apples then
            update_apple_state(self)
        else
            reset_apple_state(self)
        end
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
