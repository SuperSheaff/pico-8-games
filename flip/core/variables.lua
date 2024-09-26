-- variables.lua

-- constants
grid_size = 8
base_update_rate = 5 -- set this to the initial speed value
update_rate = base_update_rate -- use this as the variable for current speed
screen_size = 128

-- border and score bar
border_size = 8
score_bar = {
    color = 7,
    text_color = 0,
    height = border_size
}
background_color = 0

-- sprite ids
sprites = {
    tail_horizontal = 1,
    body_horizontal = 2,
    head_horizontal = 3,
    tail_vertical = 17,
    body_vertical = 18,
    head_vertical = 19,
    corner = 4,                     -- up to right corner sprite
    apple = 5,                      -- id for normal apple sprite
    golden_apple = 6,               -- id for golden apple sprite
    semi_transparent_apple = 21     -- id for semi-transparent apple sprite
}

-- directions
directions = {
    right = 0,
    down = 1,
    left = 2,
    up = 3
}

-- game state
game_over = false
game_state = "play" -- possible states: "play", "choose_option"
selected_option = 1 -- default selected option, 1 for top, 2 for bottom

-- flash effect
flash = {
    count = 0,          -- number of flashes
    max_count = 8,      -- total number of flashes before showing game over
    interval = 5,       -- frames between each flash (adjust for speed)
    state = false,      -- toggle between normal and flash states
    timer = 0           -- timer to control flash speed
}

-- snake variables
last_direction = directions.right

-- apple variables
apples_eaten = 0              -- track number of apples eaten
golden_apple_frequency = 10   -- spawn a golden apple every 10 apples eaten
speed_increase_per_golden = 1 -- increase speed by 1 frame per golden apple eaten

-- option variables
options = {
    { name = "invisible_body", text = "invisible body", effect = "invisible" },
    { name = "extra_speed", text = "extra speed", effect = "speed" },
    { name = "spikes", text = "spikes", effect = "spikes" },
    { name = "reverse_controls", text = "reverse controls", effect = "reverse_controls" }, 
    { name = "invisible_apple", text = "invisible apple", effect = "invisible_apple" } 
}

selected_options = {}
options_randomized = false
effect_start_apples = 0
option_counts = { 0, 0 } -- will store the number of apples for each selected option
active_effect = nil

spikes = {}

resume_delay = 0 -- Time to wait before resuming the game
apple_invisible_curse_active = false
active_curses = {} -- Table to hold all active curses
