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
    local game_name = "the serpent"
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

    cls(0)

    ui:draw_background()

    -- Define the sprite ID for the game over screen
    local game_over_sprite_id = sprites.game_over  -- Replace with the actual sprite ID
    local sprite_width = 64  -- Replace with the actual width of the sprite
    local sprite_height = 32  -- Replace with the actual height of the sprite

    -- Calculate the position to center the sprite on the screen
    local sprite_x = (screen_size - sprite_width) / 2
    local sprite_y = (screen_size - sprite_height) / 2

    -- Draw the game over sprite
    spr(game_over_sprite_id, 32, 16, 16, 5)

    -- Display the score
    local score_text = "you scored "..score
    local score_width = #score_text * 4 -- approximate width of each character
    local score_x = (screen_size - score_width) / 2
    local score_y = 70 -- Position it below the game over sprite

    -- Print the score text in white
    print(score_text, score_x, score_y, 7)

    -- Print the score number in green
    print(score, score_x + (#"you scored " * 4), score_y, 11)

    -- calculate dimensions for the "press X to restart" box
    local instruction_text = "press X to restart"
    local instruction_width = #instruction_text * 4 -- approximate width of each character
    local instruction_height = 5 -- approximate height of text

    -- display restart instruction with black color
    print(instruction_text, (64 - instruction_width / 2) + 1, 100, 7) -- position text inside the box with color 0 (black)
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

function ui:draw_background()
    local corner_sprite = sprites.background_corner -- Assuming this is the sprite ID for the corner
    local edge_sprite_vertical = sprites.background_edge_vertical -- Assuming this is the sprite ID for the vertical edge
    local edge_sprite_horizontal = sprites.background_edge_horizontal -- Assuming this is the sprite ID for the horizontal edge
    local edge_size = 16 -- Size of the edge sprite in pixels
    local inset = 0 -- Inset from the screen edges

    -- Draw corners
    -- Top-left corner (no flip)
    spr(corner_sprite, inset, inset, 4, 4, false, false)

    -- Top-right corner (flipped horizontally)
    spr(corner_sprite, screen_size - 32 - inset, inset, 4, 4, true, false)

    -- Bottom-left corner (flipped vertically)
    spr(corner_sprite, inset, screen_size - 32 - inset, 4, 4, false, true)

    -- Bottom-right corner (flipped horizontally and vertically)
    spr(corner_sprite, screen_size - 32 - inset, screen_size - 32 - inset, 4, 4, true, true)

    -- Draw edges
    -- Left and right edges
    local counter = 0
    for y = 32 + inset, screen_size - 32 - edge_size - inset, edge_size do
        local flip = (flr(counter / 2) % 2) == 1 -- Flip every other pair
        -- Left edge
        spr(edge_sprite_vertical, inset, y, 2, 2, false, flip)

        -- Right edge
        spr(edge_sprite_vertical, screen_size - edge_size - inset, y, 2, 2, true, flip)

        counter = counter + 1
    end

    -- Top and bottom edges
    counter = 0
    for x = 32 + inset, screen_size - 32 - edge_size - inset, edge_size do
        local flip = (flr(counter / 2) % 2) == 1 -- Flip every other pair
        -- Top edge
        spr(edge_sprite_horizontal, x, inset, 2, 2, not flip, false)

        -- Bottom edge
        spr(edge_sprite_horizontal, x, screen_size - edge_size - inset, 2, 2, not flip, true)

        counter = counter + 1
    end
end
