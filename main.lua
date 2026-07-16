display.setStatusBar(display.HiddenStatusBar)

local physics = require("physics")
physics.start()
physics.setGravity(0, 0)

display.setDefault("background", 0.1, 0.1, 0.1)

local screenW = display.contentWidth - (display.screenOriginX * 2)
local screenH = display.contentHeight - (display.screenOriginY * 2)
local leftEdge = display.screenOriginX
local rightEdge = display.screenOriginX + screenW
local topEdge = display.screenOriginY
local bottomEdge = display.screenOriginY + screenH

local currentLevel = 1
local maxLevels = 10
local ballSpeed = 350
local paddle, ball
local bricksGroup = display.newGroup()
local bricksCount = 0
local lives = 3
local livesText
local isBallLaunched = false
local isLoadingLevel = false
local isPaused = false

local sndHit = audio.loadSound("hit.wav")
local sndBoom = audio.loadSound("boom.wav")
local sndLose = audio.loadSound("lose.wav")
local sndWin = audio.loadSound("win.wav")

local function playSound(snd)
    if snd then audio.play(snd) end
end

local colors = {
    [1] = {1, 0, 0},
    [2] = {0, 1, 0},
    [3] = {0, 0.5, 1},
    [4] = {1, 1, 0},
    [5] = {1, 0, 1},
    [6] = {0, 1, 1},
    [7] = {1, 0.5, 0}
}

local levels = {
    {
        {0,0,7,7,0,0,0,0,7,7,0,0},
        {0,7,1,1,7,0,0,7,1,1,7,0},
        {7,1,1,1,1,7,7,1,1,1,1,7},
        {7,1,1,1,1,1,1,1,1,1,1,7},
        {0,7,1,1,1,1,1,1,1,1,7,0},
        {0,0,7,1,1,1,1,1,1,7,0,0},
        {0,0,0,7,1,1,1,1,7,0,0,0},
        {0,0,0,0,0,7,7,0,0,0,0,0}
    },
    {
        {0,0,0,7,0,0,0,0,7,0,0,0},
        {0,0,0,0,7,0,0,7,0,0,0,0},
        {0,0,0,7,2,2,2,2,7,0,0,0},
        {0,0,7,2,0,2,2,0,2,7,0,0},
        {0,0,7,2,2,2,2,2,2,7,0,0},
        {0,0,0,0,7,0,0,7,0,0,0,0},
        {0,0,0,7,0,7,7,0,7,0,0,0},
        {0,0,7,0,0,0,0,0,0,7,0,0}
    },
    {
        {0,0,0,0,0,7,7,0,0,0,0,0},
        {0,0,0,0,7,3,3,7,0,0,0,0},
        {0,0,0,7,3,7,7,3,7,0,0,0},
        {0,0,7,3,7,7,7,7,3,7,0,0},
        {0,7,3,7,7,7,7,7,7,3,7,0},
        {7,3,7,7,7,7,7,7,7,7,3,7},
        {0,7,7,7,0,0,0,0,7,7,7,0},
        {7,7,0,0,0,0,0,0,0,0,7,7}
    },
    {
        {7,4,7,4,7,4,7,4,7,4,7,4},
        {4,7,4,7,4,7,4,7,4,7,4,7},
        {7,4,7,4,7,4,7,4,7,4,7,4},
        {4,7,4,7,4,7,4,7,4,7,4,7},
        {7,4,7,4,7,4,7,4,7,4,7,4},
        {4,7,4,7,4,7,4,7,4,7,4,7},
        {7,4,7,4,7,4,7,4,7,4,7,4},
        {0,0,0,0,0,0,0,0,0,0,0,0}
    },
    {
        {1,1,1,1,1,1,1,1,1,1,1,1},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {2,2,2,2,2,2,2,2,2,2,2,2},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {3,3,3,3,3,3,3,3,3,3,3,3},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {4,4,4,4,4,4,4,4,4,4,4,4},
        {0,0,0,7,7,0,0,7,7,0,0,0}
    },
    {
        {0,0,5,5,5,5,5,5,5,5,0,0},
        {0,5,0,0,0,0,0,0,0,0,5,0},
        {5,0,7,7,0,0,0,0,7,7,0,5},
        {5,0,7,7,0,0,0,0,7,7,0,5},
        {5,0,0,0,0,7,7,0,0,0,0,5},
        {5,0,7,0,0,0,0,0,0,7,0,5},
        {0,5,0,7,7,7,7,7,7,0,5,0},
        {0,0,5,5,5,5,5,5,5,5,0,0}
    },
    {
        {7,0,7,0,7,0,0,7,0,7,0,7},
        {7,6,7,6,7,6,6,7,6,7,6,7},
        {7,6,7,6,7,6,6,7,6,7,6,7},
        {7,6,7,6,7,6,6,7,6,7,6,7},
        {7,6,7,6,7,6,6,7,6,7,6,7},
        {7,6,7,6,7,6,6,7,6,7,6,7},
        {7,0,7,0,7,0,0,7,0,7,0,7},
        {7,7,7,7,7,0,0,7,7,7,7,7}
    },
    {
        {0,0,0,0,0,7,7,0,0,0,0,0},
        {1,1,0,0,0,7,7,0,0,0,1,1},
        {1,1,1,0,0,7,7,0,0,1,1,1},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {1,1,1,0,0,7,7,0,0,1,1,1},
        {1,1,0,0,0,7,7,0,0,0,1,1},
        {0,0,0,0,0,7,7,0,0,0,0,0}
    },
    {
        {7,2,2,2,2,2,2,2,2,2,2,7},
        {2,7,0,0,0,0,0,0,0,0,7,2},
        {2,0,7,0,0,0,0,0,0,7,0,2},
        {2,0,0,7,0,0,0,0,7,0,0,2},
        {2,0,0,0,7,0,0,7,0,0,0,2},
        {2,0,0,0,0,7,7,0,0,0,0,2},
        {2,7,7,7,7,7,7,7,7,7,7,2},
        {7,7,7,7,7,7,7,7,7,7,7,7}
    },
    {
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {7,7,7,3,3,3,3,3,3,7,7,7},
        {7,7,7,3,7,7,7,7,3,7,7,7},
        {7,7,7,3,3,3,3,3,3,7,7,7},
        {7,7,7,7,7,7,7,7,7,7,7,7},
        {7,7,7,7,7,7,7,7,7,7,7,7}
    }
}

local loadLevel

local function updateLivesText()
    livesText.text = "Жизни: " .. lives
end

local function setGrayscale(enabled)
    local effectName = enabled and "filter.grayscale" or nil
    if paddle and paddle.fill then paddle.fill.effect = effectName end
    if ball and ball.fill then ball.fill.effect = effectName end
    for i = 1, bricksGroup.numChildren do
        local brick = bricksGroup[i]
        if brick and brick.fill then
            brick.fill.effect = effectName
        end
    end
end

local function resetBall()
    isBallLaunched = false
    ball:setLinearVelocity(0, 0)
    ball.x = paddle.x
    ball.y = paddle.y - 15
end

local function gameOver()
    lives = 3
    currentLevel = 1
    updateLivesText()
    loadLevel(currentLevel)
end

local function createEnvironment()
    local wallThickness = 40
    local leftWall = display.newRect(leftEdge - wallThickness/2, display.contentCenterY, wallThickness, screenH*2)
    physics.addBody(leftWall, "static", {bounce = 1, friction = 0})
    local rightWall = display.newRect(rightEdge + wallThickness/2, display.contentCenterY, wallThickness, screenH*2)
    physics.addBody(rightWall, "static", {bounce = 1, friction = 0})
    local topWall = display.newRect(display.contentCenterX, topEdge - wallThickness/2, screenW*2, wallThickness)
    physics.addBody(topWall, "static", {bounce = 1, friction = 0})

    local bottomZone = display.newRect(display.contentCenterX, bottomEdge + 50, screenW*2, 20)
    physics.addBody(bottomZone, "static", {isSensor = true})
    bottomZone.name = "bottom"

    livesText = display.newText("Жизни: 3   Уровень: 1", leftEdge + 80, topEdge + 15, native.systemFontBold, 14)
    livesText:setFillColor(1, 1, 1)
end

local function createPlayer()
    paddle = display.newRect(display.contentCenterX, bottomEdge - 30, 90, 12)
    paddle:setFillColor(0.8, 0.8, 0.8)
    physics.addBody(paddle, "kinematic", {bounce = 0, friction = 0})
    paddle.name = "paddle"

    ball = display.newCircle(display.contentCenterX, paddle.y - 15, 6)
    ball:setFillColor(1, 1, 1)
    physics.addBody(ball, "dynamic", {radius = 6, bounce = 1, friction = 0})
    ball.name = "ball"
    ball.isBullet = true
end

function loadLevel(levelNum)
    for i = bricksGroup.numChildren, 1, -1 do
        local child = bricksGroup[i]
        if child then child:removeSelf() end
    end
    bricksCount = 0

    livesText.text = "Жизни: " .. lives .. "   Уровень: " .. currentLevel

    local map = levels[levelNum]
    local cols = 12
    local rows = #map

    local brickWidth = screenW / cols
    local brickHeight = 22

    local startX = leftEdge + (brickWidth / 2)
    local startY = topEdge + 40

    for row = 1, rows do
        for col = 1, cols do
            local colorType = map[row][col]
            if colorType > 0 then
                local brick = display.newRect(
                    bricksGroup,
                    startX + (col - 1) * brickWidth,
                    startY + (row - 1) * brickHeight,
                    brickWidth - 2,
                    brickHeight - 2
                )
                local c = colors[colorType]
                brick:setFillColor(c[1], c[2], c[3])
                physics.addBody(brick, "static", {bounce = 1, friction = 0})

                brick.name = "brick"
                brick.row = row
                brick.col = col
                brick.isExplosive = (colorType == 7)
                brick.isMarkedForDeath = false

                bricksCount = bricksCount + 1
            end
        end
    end
    resetBall()
end

local function checkWin()
    if bricksCount <= 0 and not isLoadingLevel then
        isLoadingLevel = true
        playSound(sndWin)
        currentLevel = currentLevel + 1

        if currentLevel > maxLevels then currentLevel = 1 end

        timer.performWithDelay(500, function()
            loadLevel(currentLevel)
            isLoadingLevel = false
        end)
    end
end

local function destroyBrick(brick)
    if not brick or brick.isMarkedForDeath then return end

    brick.isMarkedForDeath = true
    bricksCount = bricksCount - 1

    if brick.isExplosive then
        playSound(sndBoom)
        local explosion = display.newCircle(brick.x, brick.y, 10)
        explosion:setFillColor(1, 0.5, 0)
        transition.to(explosion, {
            time = 250, xScale = 6, yScale = 6, alpha = 0,
            onComplete = function() explosion:removeSelf() end
        })

        timer.performWithDelay(20, function()
            for i = bricksGroup.numChildren, 1, -1 do
                local other = bricksGroup[i]
                if other and not other.isMarkedForDeath then
                    if math.abs(other.row - brick.row) <= 1 and math.abs(other.col - brick.col) <= 1 then
                        destroyBrick(other)
                    end
                end
            end
        end)
    else
        playSound(sndHit)
    end

    timer.performWithDelay(10, function()
        if brick and brick.parent then
            brick:removeSelf()
            checkWin()
        end
    end)
end

local function onCollision(event)
    if event.phase == "began" then
        local obj1 = event.object1
        local obj2 = event.object2

        if obj1.name == "bottom" or obj2.name == "bottom" then
            if isPaused then return end
            isPaused = true
            playSound(sndLose)

            timer.performWithDelay(1, function() ball:setLinearVelocity(0, 0) end)
            setGrayscale(true)

            timer.performWithDelay(2000, function()
                setGrayscale(false)
                lives = lives - 1
                updateLivesText()
                if lives <= 0 then gameOver() else resetBall() end
                isPaused = false
            end)
        end

        if obj1.name == "brick" or obj2.name == "brick" then
            local brick = (obj1.name == "brick") and obj1 or obj2
            destroyBrick(brick)
        end

        if obj1.name == "paddle" or obj2.name == "paddle" then
            playSound(sndHit)
            local hitPoint = ball.x - paddle.x
            local normalizedHit = hitPoint / (paddle.width / 2)
            local vx = normalizedHit * 450
            local vy = -ballSpeed

            timer.performWithDelay(10, function()
                if isBallLaunched and not isPaused then
                    ball:setLinearVelocity(vx, vy)
                end
            end)
        end
    end
end

local function onScreenTouch(event)
    if isPaused then return true end

    if event.phase == "began" then
        if not isBallLaunched then
            isBallLaunched = true
            local startX = (math.random(0,1) == 0) and -100 or 100
            ball:setLinearVelocity(startX, -ballSpeed)
        end
        paddle.x = event.x
    elseif event.phase == "moved" then
        paddle.x = event.x
    end

    if paddle.x < leftEdge + paddle.width/2 then paddle.x = leftEdge + paddle.width/2 end
    if paddle.x > rightEdge - paddle.width/2 then paddle.x = rightEdge - paddle.width/2 end
    return true
end

local function gameLoop()
    if isPaused then
        ball:setLinearVelocity(0, 0)
        return
    end

    if not isBallLaunched then
        ball.x = paddle.x
        ball.y = paddle.y - 15
        ball:setLinearVelocity(0, 0)
        return
    end

    if ball and ball.x then
        local vx, vy = ball:getLinearVelocity()
        local speed = math.sqrt(vx*vx + vy*vy)

        if speed > 0 then
            if math.abs(vy) < 60 then
                vy = (vy < 0) and -100 or 100
            end
            local ratio = ballSpeed / speed
            ball:setLinearVelocity(vx * ratio, vy * ratio)
        end
    end
end

local function initGame()
    createEnvironment()
    createPlayer()
    loadLevel(currentLevel)

    Runtime:addEventListener("touch", onScreenTouch)
    Runtime:addEventListener("collision", onCollision)
    Runtime:addEventListener("enterFrame", gameLoop)
end

initGame()
