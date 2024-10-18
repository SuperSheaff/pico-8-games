-- variables.lua

-- constants
grid_size = 8                          -- size of each grid cell in the game
base_update_rate = 5                   -- base speed for the snake movement, adjust to change default speed
update_rate = base_update_rate         -- current speed of the snake, which can change with curses
screen_size = 128                      -- size of the game screen in pixels
score = 0

test_mode = false                      -- set this to true to only spawn golden apples for testing purposes

is_paused       = false
pause_duration  = 30                   -- Number of frames to pause (1 second at 60 FPS)
pause_timer     = 0


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
    tail_horizontal         = 1,        -- id for horizontal snake tail sprite
    body_horizontal         = 2,        -- id for horizontal snake body sprite
    head_horizontal         = {         -- id's for horizontal snake headsprites
        active              = 3,
        default             = 3,                  
        welly               = 32,                  
        doug                = 33,                  
        benny               = 34,                  
        bryce               = 35,                  
        reno                = 36,                  
        gabby               = 37,                  
        kell                = 38,                  
        jenna               = 39,                  
        jaz                 = 40,                  
    },    
    tail_vertical           = 17,       -- id for vertical snake tail sprite
    body_vertical           = 18,       -- id for vertical snake body sprite
    head_vertical           = {         -- id's for vertical snake headsprites
        active              = 19,
        default             = 19,                  
        welly               = 48,                  
        doug                = 49,                  
        benny               = 50,                  
        bryce               = 51,                  
        reno                = 52,                  
        gabby               = 53,                  
        kell                = 54,                  
        jenna               = 55,                  
        jaz                 = 56,                  
    },      
    corner                  = 4,        -- id for corner sprite (snake turns)
    apple                   = 5,        -- id for regular apple sprite
    golden_apple            = 6,        -- id for golden apple sprite
    semi_apple              = 21,       -- id for semi-transparent apple sprite (used in invisible apple curse)
    semi_golden_apple       = 22,       -- id for semi-transparent golden apple sprite
    skull                   = 8,        -- id for skull sprite
    poop                    = 9,        -- id for poop sprite
    egg                     = 25        -- id for poop sprite
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
        effect = "invisible",          -- effect name to apply during gameplay
        apple_range = {min = 1, max = 10} -- Range of apples for this curse
    },
    { 
        name = "doug", 
        text = "double length", 
        effect = "long",
        apple_range = {min = 1, max = 10} -- Range of apples for this curse
    },
    { 
        name = "reno", 
        text = "spikes", 
        effect = "spikes",
        apple_range = {min = 2, max = 10} -- Range of apples for this curse
    },
    { 
        name = "gabby", 
        text = "reverse controls", 
        effect = "reverse_controls",
        apple_range = {min = 1, max = 5} -- Range of apples for this curse
    },
    { 
        name = "welly", 
        text = "invisible apple", 
        effect = "invisible_apple",
        apple_range = {min = 3, max = 10} -- Range of apples for this curse
    },
    { 
        name = "jaz", 
        text = "extra speed", 
        effect = "speed",
        apple_range = {min = 1, max = 7} -- Range of apples for this curse
    },
    { 
        name = "bryce", 
        text = "swap head with tail", 
        effect = "flip",
        apple_range = {min = 1, max = 10} -- Range of apples for this curse
    },
    { 
        name = "kell", 
        text = "teleporting apple", 
        effect = "teleport_apple",
        apple_range = {min = 2, max = 10} -- Range of apples for this curse
    },
    { 
        name = "jenna", 
        text = "lay an egg", 
        effect = "egg",
        apple_range = {min = 1, max = 5} -- Range of apples for this curse
    }
     -- { 
    --     name = "headless", 
    --     text = "invisible head", 
    --     effect = "invisible_head",
    --     apple_range = {min = 1, max = 7} -- Range of apples for this curse
    -- },
}

selected_curse      = 1                -- currently selected curse, 1 for top, 2 for bottom
selected_curses     = {}               -- table holding the two selected curses to choose from
curses_randomized   = false            -- flag to ensure curses are randomized once per golden apple
curse_counts        = { 0, 0 }         -- stores the number of apples required to end each selected curse
active_effect       = "default"              -- stores the current active effect applied by a curse

-- spike variables
spikes              = {}                            -- table to hold all active spike objects on the screen
poop_trail          = {}    
egg_trail           = {}                    -- table to store poop positions
egg_counter         = 0
egg_interval        = 5 -- Set the interval

resume_delay = 0                       -- time in frames to wait before resuming the game after curse selection
invisible_apples = false               -- flag to indicate if invisible apple curse is active
teleporting_apples    = false                  -- flag to indicate if teleport apple curse is active
active_curses     = {}                     -- table to hold all currently active curses
