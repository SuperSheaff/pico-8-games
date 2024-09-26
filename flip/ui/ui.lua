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
    game_over = true
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

-- function to draw the option selection screen
function ui:draw_option_screen()
    -- Ensure selected_options is populated
    if #selected_options < 2 then
        print("Error: selected_options not properly initialized.", 10, 10, 8)
        return
    end

    -- Define UI border dimensions and gap
    local border_x = border_size
    local border_y = border_size
    local ui_width = screen_size - border_size * 2 - 3 -- reduce width by 2 (1 pixel on each side)
    local ui_height = screen_size - border_size * 2 - 6 -- reduce height by 2 (1 pixel on each side)
    local gap = 1

    -- Draw black rectangle to cover snake and background elements
    rectfill(border_x, border_y, border_x + ui_width + 1, border_y + ui_height + 4, 0)

    -- Calculate rectangle dimensions
    local rect_width = ui_width
    local rect_height = (ui_height / 2) - (gap / 2) - 3

    -- Calculate positions for option 1 and option 2 rectangles
    local option1_rect_x = border_x + 1
    local option1_rect_y = border_y + 1
    local option2_rect_x = border_x + 1
    local option2_rect_y = border_y + rect_height + gap + 10

    -- Draw the white background rectangles for each option
    rectfill(option1_rect_x, option1_rect_y, option1_rect_x + rect_width, option1_rect_y + rect_height, 7)
    rectfill(option2_rect_x, option2_rect_y, option2_rect_x + rect_width, option2_rect_y + rect_height, 7)

    -- Extract the name and count for each option
    local option1_name = selected_options[1].option.text
    local option1_count = "for \f8" .. selected_options[1].count .. "\f0 apples"
    local option2_name = selected_options[2].option.text
    local option2_count = "for \f8" .. selected_options[2].count .. "\f0 apples"

    -- Calculate widths for centering
    local text_width_1_name = #option1_name * 4
    local text_width_1_count = #option1_count * 4
    local text_width_2_name = #option2_name * 4
    local text_width_2_count = #option2_count * 4

    -- Calculate the vertical center of the rectangles
    local center_y_1 = option1_rect_y + (rect_height / 2) - 7 -- Adjust for two lines of text (approx. 7 pixels height)
    local center_y_2 = option2_rect_y + (rect_height / 2) - 7 -- Adjust for two lines of text (approx. 7 pixels height)

    -- Print the first option (two lines)
    print(option1_name, option1_rect_x + (rect_width / 2) - (text_width_1_name / 2), center_y_1, 0)
    print(option1_count, option1_rect_x + (rect_width / 2) - (text_width_1_count / 2) + 8, center_y_1 + 8, 0)

    -- Print the second option (two lines)
    print(option2_name, option2_rect_x + (rect_width / 2) - (text_width_2_name / 2), center_y_2, 0)
    print(option2_count, option2_rect_x + (rect_width / 2) - (text_width_2_count / 2) + 8, center_y_2 + 8, 0)

    -- Draw the selector box around the selected option
    if selected_option == 1 then
        rect(option1_rect_x, option1_rect_y, option1_rect_x + rect_width, option1_rect_y + rect_height, 8)
    elseif selected_option == 2 then
        rect(option2_rect_x, option2_rect_y, option2_rect_x + rect_width, option2_rect_y + rect_height, 8)
    end

    -- Draw "or" in the middle of the screen, centered vertically
    local or_text = "or"
    local or_text_width = #or_text * 4 -- width of the text "or" in pixels (4 pixels per character)
    local or_x = (screen_size - or_text_width) / 2 -- center of the screen minus half the text width
    local or_y = screen_size / 2 - 3 -- adjust y-position to center vertically between options
    print(or_text, or_x, or_y, 7)

end
