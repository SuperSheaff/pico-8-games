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
    
    -- check if this should be a golden apple
    if next_apple_golden then
        apple.sprite_id = sprites.golden_apple
        apple.is_golden = true
    else
        apple.sprite_id = sprites.apple
        apple.is_golden = false
    end

    -- draw the apple
    function apple:draw()
        -- draw the apple sprite based on its type
        spr(self.sprite_id, self.x * grid_size, self.y * grid_size)
    end

    return apple
end
