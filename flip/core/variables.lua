-- variables.lua

-- constants
grid_size = 8
base_update_rate = 5 -- set this to the initial speed value
update_rate = base_update_rate -- use this as the variable for current speed
screen_size = 128

test_mode = true -- set this to true for only gold apples

-- border and score bar
border_size = 8
score_bar = {
    color       = 7,
    text_color  = 0,
    height      = border_size
}
background_color = 0

-- sprite ids
sprites = {
    tail_horizontal         = 1,    -- id for horizontal snake tail sprite
    body_horizontal         = 2,    -- id for horizontal snake body sprite
    head_horizontal         = 3,    -- id for horizontal snake head sprite
    tail_vertical           = 17,   -- id for vertical snake tail sprite
    body_vertical           = 18,   -- id for vertical snake body sprite
    head_vertical           = 19,   -- id for vertical snake head sprite
    corner                  = 4,    -- id for vertical snake corner sprite
    apple                   = 5,    -- id for normal apple sprite
    golden_apple            = 6,    -- id for golden apple sprite
    semi_transparent_apple  = 21    -- id for semi-transparent apple sprite
}

-- sound ids
sounds = {
    eat_apple               = 0,    -- id for eat apple sound
    game_tick               = 1,    -- id for game tick sound
    ui_move                 = 3,    -- id for ui move sound
    ui_select               = 4,    -- id for ui select sound
}

-- directions
directions = {
    right   = 0,
    down    = 1,
    left    = 2,
    up      = 3
}

-- game state variables
game_over       = false     -- is the game over?
game_state      = "play"    -- current possible states: "play", "choose_curse", "resume_delay"

-- game over screen flash effect
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

-- curse variables
curses = {
    { name = "invisible_body",      text = "invisible body",    effect = "invisible" },
    { name = "extra_speed",         text = "extra speed",       effect = "speed" },
    { name = "spikes",              text = "spikes",            effect = "spikes" },
    { name = "reverse_controls",    text = "reverse controls",  effect = "reverse_controls" }, 
    { name = "invisible_apple",     text = "invisible apple",   effect = "invisible_apple" } 
}

selected_curse      = 1 -- default selected curse, 1 for top, 2 for bottom
selected_curses     = {}
curses_randomized   = false
curse_counts        = { 0, 0 } -- will store the number of apples for each selected curse
active_effect = nil

spikes = {}

resume_delay = 0 -- Time to wait before resuming the game
invisible_apples = false
active_curses = {} -- Table to hold all active curses
