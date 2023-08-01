

require('lib.moonloader')
local imgui = require('mimgui')
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'
local ffi = require 'ffi'

local cfg = inicfg.load({
    lastsum = 0,
    comis = false,
}, 'deposit')
local day = {
    [0] = 'Воскресенье',
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота'
}
print(day[os.date('%w')])
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
getMoney = false
local formula = function (sum)
    local procent = comission / 100
    local p = 1 + procent
    
    x = sum/p
    return math.ceil(x)
end
tekuwiy = 0
if not doesFileExist('moonloader/config/deposit.ini') then inicfg.save(cfg, 'deposit') end
function main() 
    while not isSampAvailable() do wait(0) end
    print(day[tonumber(os.date('%w'))])

    if day[tonumber(os.date('%w'))] ~= 'Воскресенье' and day[tonumber(os.date('%w'))] ~= 'Суббота' then
        print('asdasd')
        comission = 7
    else
        comission = 3
    end
    while true do
        wait(0)
        if tonumber(os.date('%w')) <= 5 then
            comission = 7
        else
            comission = 3
        end
    end
end

addEventHandler('onWindowMessage', function(msg, wparam, lparam)
    if msg == 0x100 and wparam == 0x0D then
        
        if set.renderWindow[0] then
            set.renderWindow[0] = false
            consumeWindowMessage()
            getMoney = true
            counter = 0
            if set.comis[0] == true then
                tsum = tonumber(tekuwiy) - set.sum[0]
                tsum = math.ceil(formula(tsum))
            else
                scounter = math.ceil(tonumber(tekuwiy) - set.sum[0])
                tsum = math.ceil(tonumber(tekuwiy) - set.sum[0])
            end
        end

    end
end)
 
set = {

    renderWindow = imgui.new.bool(false),
    sum = imgui.new.int(),
    comis = imgui.new.bool(cfg.comis),

}



local Frame = imgui.OnInitialize(function()
    u32 = imgui.ColorConvertFloat4ToU32
    
    imgui.CenterTextColoredRGB = function(text)
        local text = u8:decode(text)
        local width = imgui.GetWindowWidth()
        local style = imgui.GetStyle()
        local colors = style.Colors
        local ImVec4 = imgui.ImVec4

        local explode_argb = function(argb)
            local a = bit.band(bit.rshift(argb, 24), 0xFF)
            local r = bit.band(bit.rshift(argb, 16), 0xFF)
            local g = bit.band(bit.rshift(argb, 8), 0xFF)
            local b = bit.band(argb, 0xFF)
            return a, r, g, b
        end

        local getcolor = function(color)
            if color:sub(1, 6):upper() == 'SSSSSS' then
                local r, g, b = colors[1].x, colors[1].y, colors[1].z
                local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
                return ImVec4(r, g, b, a / 255)
            end
            local color = type(color) == 'string' and tonumber(color, 16) or color
            if type(color) ~= 'number' then return end
            local r, g, b, a = explode_argb(color)
            return imgui.ImColor(r, g, b, a):GetVec4()
        end

        local render_text = function(text_)
            for w in text_:gmatch('[^\r\n]+') do
                local textsize = w:gsub('{.-}', '')
                local text_width = imgui.CalcTextSize(u8(textsize))
                imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
                local text, colors_, m = {}, {}, 1
                w = w:gsub('{(......)}', '{%1FF}')
                while w:find('{........}') do
                    local n, k = w:find('{........}')
                    local color = getcolor(w:sub(n + 1, k - 1))
                    if color then
                        text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                        colors_[#colors_ + 1] = color
                        m = n
                    end
                    w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
                end
                if text[0] then
                    for i = 0, #text do
                        imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                        imgui.SameLine(nil, 0)
                    end
                    imgui.NewLine()
                else 
                    imgui.Text(u8(w))
                end
            end
        end
        render_text(text) 
    end

    
    style()
end)
local sizeX, sizeY = getScreenResolution()
local onFrame = imgui.OnFrame(
    function() return set.renderWindow[0] end,
    function(player)
        imgui.SetNextWindowSize(imgui.ImVec2(600, 200), imgui.Cond.FirstUseEver)
        
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(u8'Снятие с депозита', set.renderWindow, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoTitleBar)
        if imgui.Checkbox(u8'Учитывать комиссию', set.comis) then
            cfg.comis = set.comis[0]
        end
        imgui.SameLine()
        imgui.Text(u8'| Текущая комиссия: '..comission)
        if imgui.InputInt(u8'Сумма для снятия', set.sum, 256) then
            cfg.lastsum = set.sum[0]
        end
        if set.comis[0] == true then
            imgui.Text(u8'С депозита будет снято: '..formula(tekuwiy - tonumber(set.sum[0])))
        else imgui.Text(u8'С депозита будет снято: '..set.sum[0]) end
        imgui.End()
    end
)

lua_thread.create(function()
    while true do wait(0)
        if getMoney == true then
            setGameKeyState(21, 255)
            wait(20) -- Устанавливает WALK true
            setGameKeyState(21, 0)
            wait(500)
        end
    end
end)

function sampev.onServerMessage(color, text)
    if text:find('состояние депозита') and color ~= -1 then
        tekuwiy = text:match('депозита: {......}$(%d*)')
        sampAddChatMessage(tekuwiy, -1)
    end
end
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if tekuwiy ==  0 and id == 33 then
        lua_thread.create(function()
            sampSendDialogResponse(id, 1, 0, '')
            wait(100)
            setGameKeyState(21, 255)
            wait(20) -- Устанавливает WALK true
            setGameKeyState(21, 0)
        end)
        return false 
    end
    if getMoney == false then
        if id == 4499 then

            set.renderWindow[0] = true
            return false
        end
    end
    if getMoney == true then
        
        if id == 33 then
            sampSendDialogResponse(id, 1, 8, '')
            return false
        end
        if id == 4499 then
            if tsum == 0 then
                getMoney = false
                
            end
            if tsum > 10000000 then
                sampSendDialogResponse(id, 1, 1, '10000000')
                tsum = tsum - 10000000
            else 
                sampSendDialogResponse(id, 1, 1, tsum) 
                tsum = 0
            end
            
            return false
        end
    end
end






function style()
	imgui.SwitchContext()
    imgui.GetStyle().WindowRounding		= 7.0
    imgui.GetStyle().ChildRounding		= 7.0
    imgui.GetStyle().FrameRounding		= 5.0
    imgui.GetStyle().WindowBorderSize	= 0.0
    imgui.GetStyle().FramePadding		= imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing		= imgui.ImVec2(5, 5)
    imgui.GetStyle().WindowPadding		= imgui.ImVec2(15, 15)
    imgui.GetStyle().ButtonTextAlign	= imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().GrabMinSize		= 7
    imgui.GetStyle().GrabRounding		= 15

	imgui.GetStyle().Colors[imgui.Col.Text]					= imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextDisabled]			= imgui.ImVec4(1.00, 1.00, 1.00, 0.20)
	imgui.GetStyle().Colors[imgui.Col.WindowBg]				= imgui.ImVec4(0.07, 0.07, 0.09, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PopupBg]				= imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Border]				= imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
	imgui.GetStyle().Colors[imgui.Col.SliderGrab]			= imgui.ImVec4(1.00, 1.00, 1.00, 0.50)
	imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]		= imgui.ImVec4(1.00, 1.00, 1.00, 0.20)
	imgui.GetStyle().Colors[imgui.Col.BorderShadow]			= imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]			= imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]		= imgui.ImVec4(0.90, 0.90, 0.90, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]	= imgui.ImVec4(0.80, 0.80, 0.80, 0.30)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]	= imgui.ImVec4(0.70, 0.70, 0.70, 0.40)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]				= imgui.ImVec4(0.13, 0.13, 0.15, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]		= imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgActive]		= imgui.ImVec4(0.17, 0.17, 0.19, 1.00)
	imgui.GetStyle().Colors[imgui.Col.CheckMark]			= imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Button]				= imgui.ImVec4(0.13, 0.13, 0.15, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonHovered]		= imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonActive]			= imgui.ImVec4(0.17, 0.17, 0.19, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]		= imgui.ImVec4(0.80, 0.80, 0.80, 0.80)
end