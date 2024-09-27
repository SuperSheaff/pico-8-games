-- variables.lua

-- constants
grid_size = 8                          -- size of each grid cell in the game
base_update_rate = 5                   -- base speed for the snake movement, adjust to change default speed
update_rate = base_update_rate         -- current speed of the snake, which can change with curses
screen_size = 128                      -- size of the game screen in pixels

test_mode = true                      -- set this to true to only spawn golden apples for testing purposes

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
    tail_horizontal         = 1,       -- id for horizontal snake tail sprite
    body_horizontal         = 2,       -- id for horizontal snake body sprite
    head_horizontal         = 3,       -- id for horizontal snake head sprite
    tail_vertical           = 17,      -- id for vertical snake tail sprite
    body_vertical           = 18,      -- id for vertical snake body sprite
    head_vertical           = 19,      -- id for vertical snake head sprite
    corner                  = 4,       -- id for corner sprite (snake turns)
    apple                   = 5,       -- id for regular apple sprite
    golden_apple            = 6,       -- id for golden apple sprite
    semi_apple              = 21,      -- id for semi-transparent apple sprite (used in invisible apple curse)
    semi_golden_apple       = 22       -- id for semi-transparent golden apple sprite
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
        effect = "invisible"           -- effect name to apply during gameplay
    },
    { 
        name = "benny", 
        text = "extra speed", 
        effect = "speed" 
    },
    { 
        name = "benny", 
        text = "spikes", 
        effect = "spikes" 
    },
    { 
        name = "benny", 
        text = "reverse controls", 
        effect = "reverse_controls" 
    },
    { 
        name = "benny", 
        text = "invisible apple", 
        effect = "invisible_apple" 
    }
}

selected_curse      = 1                -- currently selected curse, 1 for top, 2 for bottom
selected_curses     = {}               -- table holding the two selected curses to choose from
curses_randomized   = false            -- flag to ensure curses are randomized once per golden apple
curse_counts        = { 0, 0 }         -- stores the number of apples required to end each selected curse
active_effect       = nil              -- stores the current active effect applied by a curse

-- spike variables
spikes = {}                            -- table to hold all active spike objects on the screen

resume_delay = 0                       -- time in frames to wait before resuming the game after curse selection
invisible_apples = false               -- flag to indicate if invisible apple curse is active
active_curses = {}                     -- table to hold all currently active curses
