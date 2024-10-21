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
        local bias_factor = score / 10 -- Adjust this factor to control scaling
        if bias_factor > 1 then bias_factor = 1 end -- Cap the bias factor at 1

        -- Generate a weighted random count
        local range = max_apples - min_apples
        local weighted_random = flr(rnd(range * (1 - bias_factor))) + min_apples

        -- Further reduce the count early in the game
        if score < 10 then
            weighted_random = min_apples + flr(rnd((max_apples - min_apples) * 0.5))
        end

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
