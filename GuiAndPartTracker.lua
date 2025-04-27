-- Проверка, что игра загружена
print("Шаг 1: Проверка загрузки игры...")
if not game:IsLoaded() then
    print("Игра не загружена, ждём...")
    game.Loaded:Wait()
end
print("Игра загружена!")

-- Переменные
print("Шаг 2: Инициализация переменных...")
local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local playerGui = player:WaitForChild("PlayerGui", 10)
local starterGui = game:GetService("StarterGui")
if not playerGui then
    print("PlayerGui не найден!")
end

-- Таблица для отслеживания количества кликов по объектам
local clickCounts = {}

-- Функция для получения пути через StarterGui
local function getStarterGuiPath(obj)
    -- Проверяем, находится ли объект в PlayerGui
    local parent = obj.Parent
    local pathParts = {obj.Name}
    while parent and parent ~= playerGui do
        table.insert(pathParts, 1, parent.Name)
        parent = parent.Parent
    end

    -- Если объект в PlayerGui, формируем путь через StarterGui
    if parent == playerGui then
        return "game.StarterGui." .. table.concat(pathParts, ".")
    else
        -- Если объект не в PlayerGui, формируем обычный путь
        local fullPathParts = {obj.Name}
        parent = obj.Parent
        while parent and parent ~= game do
            table.insert(fullPathParts, 1, parent.Name)
            parent = parent.Parent
        end
        return "game." .. table.concat(fullPathParts, ".")
    end
end

-- Функция для логирования действий с счётчиком кликов (вывод только в F9)
local function logAction(action, details, path)
    local timestamp = os.date("%H:%M:%S")
    -- Увеличиваем счётчик кликов для данного пути
    clickCounts[path] = (clickCounts[path] or 0) + 1
    print(string.format("[%s] Действие: %s | Подробности: %s | Путь: %s | Клик: %d", timestamp, action, details, path, clickCounts[path]))
end

-- Отслеживание кликов мыши по GUI
print("Шаг 3: Настройка отслеживания GUI...")
local function setupGuiTracking()
    if not playerGui then return end

    -- Рекурсивная функция для поиска всех интерактивных элементов
    local function scanGuiForInteractables(gui)
        for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if not obj:GetAttribute("InteractionTrackerConnected") then
                    obj:SetAttribute("InteractionTrackerConnected", true)
                    obj.MouseButton1Click:Connect(function()
                        local path = getStarterGuiPath(obj)
                        logAction("Клик по GUI", "Имя: " .. obj.Name, path)
                    end)
                end
            end
        end
    end

    -- Первоначальное сканирование всех GUI элементов в PlayerGui
    scanGuiForInteractables(playerGui)

    -- Отслеживаем добавление новых GUI
    playerGui.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
            if not descendant:GetAttribute("InteractionTrackerConnected") then
                descendant:SetAttribute("InteractionTrackerConnected", true)
                descendant.MouseButton1Click:Connect(function()
                    local path = getStarterGuiPath(descendant)
                    logAction("Клик по GUI", "Имя: " .. descendant.Name, path)
                end)
            end
        end
    end)

    -- Повторное сканирование каждые 5 секунд для надёжности
    spawn(function()
        while true do
            scanGuiForInteractables(playerGui)
            wait(5)
        end
    end)
end

setupGuiTracking()

-- Отслеживание кликов по физическим объектам (ClickDetector)
print("Шаг 4: Настройка отслеживания ClickDetector...")
local function setupClickDetectorTracking()
    local function scanForClickDetectors(parent)
        for _, obj in pairs(parent:GetDescendants()) do
            if obj:IsA("ClickDetector") then
                if not obj:GetAttribute("InteractionTrackerConnected") then
                    obj:SetAttribute("InteractionTrackerConnected", true)
                    obj.MouseClick:Connect(function()
                        local path = getStarterGuiPath(obj.Parent)
                        logAction("Клик по объекту", "Имя: " .. obj.Parent.Name, path)
                    end)
                end
            end
        end
    end

    -- Сканируем Workspace и другие основные сервисы
    scanForClickDetectors(game.Workspace)
    game.Workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ClickDetector") then
            if not descendant:GetAttribute("InteractionTrackerConnected") then
                descendant:SetAttribute("InteractionTrackerConnected", true)
                descendant.MouseClick:Connect(function()
                    local path = getStarterGuiPath(descendant.Parent)
                    logAction("Клик по объекту", "Имя: " .. descendant.Parent.Name, path)
                end)
            end
        end
    end)
end

setupClickDetectorTracking()

-- Отслеживание кликов мыши в 3D-пространстве (на всех Part)
print("Шаг 5: Настройка отслеживания кликов в 3D...")
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = player:GetMouse()
        local target = mouse.Target
        if target then
            local partPath = getStarterGuiPath(target)
            if target:IsA("BasePart") then
                -- Логируем все Part, независимо от CanCollide
                logAction("Клик по Part", "Имя: " .. target.Name .. " | CanCollide: " .. tostring(target.CanCollide), partPath)
            else
                logAction("Клик в 3D", "Имя: " .. target.Name, partPath)
            end
        else
            logAction("Клик в 3D", "Нет цели (клик в пустоту)", "N/A")
        end
    end
end)

-- Уведомление о запуске
print("Шаг 6: Скрипт загружен!")
print("Отслеживание действий запущено! Открой консоль F9, чтобы увидеть логи.")