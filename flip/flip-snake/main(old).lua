-- flip snake game

-- global variables

x = {}
y = {}
x_dir = 0
y_dir = 0

tile_num = 32
tile_size = 128 / tile_num
score = 0

fruit = {}
fruit.x = 0
fruit.y = 0
fruit.color = 8

game_over = false

-- native functions
function _init()
    -- initialize snake position
    x[1] = tile_size * tile_num / 4
    y[1] = tile_size * tile_num / 2

    -- start moving right
    x_dir = 1

    -- set default snake tail length
    for i = 2, 7 do
        x[i] = (x[i - 1] / tile_size - 1) * tile_size
        y[i] = y[1]
    end

    -- initialize fruit position
    update_fruit()

    -- reset score and game over state
    score = 0
    game_over = false
end

function _update()
    if btn(❎) then
        log("btn x")
    end

    if not game_over then
        -- capture input
        update_input()

        -- check for collisions
        if check_wall_collision() or check_self_collision() then
            game_over = true
        else
            -- check fruit collision
            local collide = check_fruit_collision()
            if collide then
                -- increment score
                score = score + 10

                -- push new snake tail
                for i = #x + 1, 2, -1 do
                    x[i] = x[i - 1]
                    y[i] = y[i - 1]
                end

                -- update snake head position to fruit position
                x[1] = fruit.x
                y[1] = fruit.y

                -- update fruit position
                update_fruit()
            else
                -- update snake position
                update_snake()
            end
        end
    else
        -- restart game if x button is pressed after game over
        if btnp(4) then
            -- 4 corresponds to the x button on pico-8
            _init()
        end
    end
end

function _draw()
    -- clear screen with color 1
    cls(1)
    -- draw snake, fruit, and score
    draw_snake()
    draw_fruit()
    draw_score()

    if game_over then
        draw_game_over()
    end
end

-- check functions
function check_fruit_collision()
    -- check if snake head collides with fruit
    if x[1] == fruit.x and y[1] == fruit.y then
        return true
    end
    return false
end

function check_wall_collision()
    -- check if snake head collides with the wall
    if x[1] >= 128 or x[1] < 0 or y[1] < 0 or y[1] >= 128 then
        return true
    end
    return false
end

function check_self_collision()
    -- check if snake head collides with its own body
    for i = 2, #x do
        if x[1] == x[i] and y[1] == y[i] then
            return true
        end
    end
    return false
end

-- draw functions
function draw_fruit()
    -- draw the fruit on the screen
    rectfill(fruit.x, fruit.y, fruit.x + tile_size, fruit.y + tile_size, fruit.color)
end

function draw_score()
    -- draw the score on the screen
    color(10)
    print("score: " .. score, 1, 1)
end

function draw_snake()
    -- draw the snake head
    rectfill(x[1], y[1], x[1] + tile_size, y[1] + tile_size, 11)

    -- draw the snake body
    for i = 2, #x do
        rectfill(x[i], y[i], x[i] + tile_size, y[i] + tile_size, 3)
    end
end

function draw_game_over()
    -- draw game over message
    color(8)
    print("game over!", 44, 60)
    print("press x to restart", 34, 70)
end

-- update functions
function update_fruit()
    -- update fruit position randomly on the grid
    fruit.x = flr(rnd(tile_num)) * tile_size
    fruit.y = flr(rnd(tile_num)) * tile_size
end

function update_input()
    -- update snake direction based on player input
    if btn(0) and x_dir == 0 then
        x_dir = -1
        y_dir = 0
    elseif btn(1) and x_dir == 0 then
        x_dir = 1
        y_dir = 0
    elseif btn(2) and y_dir == 0 then
        x_dir = 0
        y_dir = -1
    elseif btn(3) and y_dir == 0 then
        x_dir = 0
        y_dir = 1
    end
end

function update_snake()
    -- local temp variables
    local temp1x = x[1]
    local temp1y = y[1]
    local temp2x, temp2y

    -- update snake head
    x[1] += x_dir * tile_size
    y[1] += y_dir * tile_size

    -- update snake tails
    for i = 2, #x do
        temp2x = x[i]
        temp2y = y[i]

        x[i] = temp1x
        y[i] = temp1y

        temp1x = temp2x
        temp1y = temp2y
    end
end