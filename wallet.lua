--/ Gold Wallet /--
if not fs.exists('/auAPI.lua') then
    local h = http.get("https://raw.githubusercontent.com/Reactified/cc-economy/master/api.lua")
    if h then
        f = fs.open("/auAPI.lua","w")
        f.writeLine(h.readAll())
        f.close()
        h.close()
    end
end
local h = http.get("https://raw.githubusercontent.com/Reactified/cc-economy/master/wallet.lua")
if h then
    f = fs.open(shell.getRunningProgram(),"r")
    local data = f.readAll()
    f.close()
    local stream = h.readAll()
    h.close()
    if data ~= stream then
        print("Wallet update detected!")
        print("Install the update now? (Y/N)")
        local e,k = os.pullEvent('key')
        if k == keys.y then
            f = fs.open(shell.getRunningProgram(),"w")
            f.writeLine(stream)
            f.close()
            print("Installing...")
            sleep(1)
            print("Complete!")
            return
        end
    end
end
os.loadAPI("/auAPI.lua")
local api = auAPI
local cname = "Goldcoin"
local csn = "AU"

--/ Initialization /--
local w,h = term.getSize()
term.setPaletteColor(colors.brown,1,0.8,0.2)

--/ Functions /--
local function drawLogo(x,y)
    term.setCursorPos(x,y)
    term.setBackgroundColor(colors.orange)
    term.setTextColor(colors.white)
    term.write("/")
    term.setBackgroundColor(colors.brown)
    term.write("\\")
    term.setCursorPos(x,y+1)
    term.write("\\")
    term.setBackgroundColor(colors.yellow)
    term.write("/")
end
local function drawHeader()
    term.setBackgroundColor(colors.black)
    term.clear()
    paintutils.drawFilledBox(1,1,w,4,colors.gray)
    drawLogo(2,2)
    term.setBackgroundColor(colors.gray)
    term.setCursorPos(5,2)
    term.setTextColor(colors.brown)
    write(cname)
    term.setCursorPos(5,3)
    term.setTextColor(colors.lightGray)
    write("Wallet")
    term.setBackgroundColor(colors.black)
end
local function rightAlign(str,ln)
    term.setCursorPos(w-#str,ln)
    write(str)
end
local function center(str,ln)
    local w,h = term.getSize()
    term.setCursorPos((w/2)-(#str/2)+1,2)
    write(str)
end

--/ Routine /--
while true do
    drawHeader()
    term.setCursorPos(2,6)
    term.setTextColor(colors.brown)
    write("Welcome!")
    term.setCursorPos(2,7)
    term.setTextColor(colors.lightGray)
    write("To get started, log in")
    term.setCursorPos(2,8)
    write("or create an account.")
    term.setCursorPos(2,10)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.gray)
    write(" Log In ")
    term.setCursorPos(11,10)
    term.setTextColor(colors.gray)
    term.setBackgroundColor(colors.brown)
    write(" Sign Up ")
    term.setCursorPos(2,h-1)
    term.setTextColor(colors.lightGray)
    term.setBackgroundColor(colors.black)
    write("Quit")
    local e,c,x,y = os.pullEvent("mouse_click")
    if y == h-1 then
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1,1)
        return
    elseif y == 10 then
        if x < 11 then
            -- Log In
            drawHeader()
            term.setCursorPos(2,6)
            term.setTextColor(colors.brown)
            write("Log In")
            term.setCursorPos(2,8)
            term.setTextColor(colors.lightGray)
            write("Username")
            term.setCursorPos(2,10)
            write("Password")
            term.setCursorPos(11,8)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
            write(string.rep(" ",w-11))
            term.setCursorPos(11,10)
            write(string.rep(" ",w-11))
            term.setCursorPos(12,8)
            term.setTextColor(colors.white)
            local username = string.upper(read())
            term.setCursorPos(12,10)
            term.setTextColor(colors.white)
            local password = read("*")
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.gray)
            term.setCursorPos(2,12)
            write("Loading...")
            if api.verify(username,password) then
                term.setCursorPos(2,12)
                term.setTextColor(colors.brown)
                term.clearLine()
                term.setCursorPos(2,12)
                write("Accepted!")
                sleep(1)
                -- Interface
                local transferTO = ""
                local transferAMT = "0"
                local tabs = {
                    "Dashboard",
                    "Transfer",
                    "Transactions",
                    "Leaderboard",
                }
                local tab = 1
                local scroll = 1
                while true do
                    -- Refresh
                    local balance = api.balance(username)
                    -- UI Draw
                    term.setBackgroundColor(colors.black)
                    term.clear()
                    paintutils.drawFilledBox(1,1,w,3,colors.gray)
                    term.setCursorPos(2,2)
                    term.setTextColor(colors.lightGray)
                    write("<- ")
                    term.setTextColor(colors.brown)
                    center(tabs[tab],2)
                    term.setTextColor(colors.lightGray)
                    term.setCursorPos(w-2,2)
                    write("->")
                    -- Tab Draw
                    if tab == 1 then
                        drawLogo(2,5)
                        term.setCursorPos(5,5)
                        term.setBackgroundColor(colors.black)
                        term.setTextColor(colors.lightGray)
                        write(username)
                        term.setTextColor(colors.brown)
                        term.setCursorPos(5,6)
                        write(tostring(balance).." "..csn)
                        term.setTextColor(colors.gray)
                        for i=2,w-1 do
                            term.setCursorPos(i,8)
                            write(string.char(math.random(129,140)))
                        end
                        term.setCursorPos(2,10)
                        term.setTextColor(colors.brown)
                        local rawBal = balance
                        local blocks = math.floor(rawBal/900)
                        rawBal = rawBal - (blocks*900)
                        local ingots = math.floor(rawBal/100)
                        rawBal = rawBal - (ingots*100)
                        local nuggets = math.floor(rawBal/11.111)
                        write(tostring(blocks))
                        term.setTextColor(colors.gray)
                        write(" gold blocks")
                        term.setCursorPos(2,11)
                        term.setTextColor(colors.brown)
                        write(tostring(ingots))
                        term.setTextColor(colors.gray)
                        write(" gold ingots")
                        term.setCursorPos(2,12)
                        term.setTextColor(colors.brown)
                        write(tostring(nuggets))
                        term.setTextColor(colors.gray)
                        write(" gold nuggets")
                        term.setCursorPos(2,h-1)
                        term.setTextColor(colors.lightGray)
                        write("> Logout")
                    elseif tab == 2 then
                        drawLogo(2,h-2)
                        term.setCursorPos(5,h-2)
                        term.setBackgroundColor(colors.black)
                        term.setTextColor(colors.lightGray)
                        write(username)
                        term.setTextColor(colors.brown)
                        term.setCursorPos(5,h-1)
                        write(tostring(balance).." "..csn)
                        term.setTextColor(colors.gray)
                        for i=2,w-1 do
                            term.setCursorPos(i,h-4)
                            write(string.char(math.random(129,140)))
                        end
                        term.setCursorPos(2,5)
                        term.setTextColor(colors.brown)
                        write("Transfer Funds")
                        term.setCursorPos(2,7)
                        term.setTextColor(colors.lightGray)
                        write("Target")
                        term.setCursorPos(2,9)
                        write("Amount")
                        term.setCursorPos(9,7)
                        term.setBackgroundColor(colors.gray)
                        term.setTextColor(colors.lightGray)
                        write(string.rep(" ",w-9))
                        term.setCursorPos(9,9)
                        write(string.rep(" ",w-9))
                        term.setCursorPos(10,7)
                        write(string.sub(transferTO,1,w-11))
                        term.setCursorPos(10,9)
                        write(string.sub(transferAMT,1,w-15).." "..csn)
                        term.setCursorPos(2,11)
                        term.setBackgroundColor(colors.brown)
                        term.setTextColor(colors.gray)
                        write(" Send ")
                    elseif tab == 3 then
                        drawLogo(2,5)
                        term.setCursorPos(5,5)
                        term.setBackgroundColor(colors.black)
                        term.setTextColor(colors.lightGray)
                        write(username)
                        term.setCursorPos(5,6)
                        term.setTextColor(colors.brown)
                        write("Transactions")
                        term.setTextColor(colors.gray)
                        for i=2,w-1 do
                            term.setCursorPos(i,8)
                            write(string.char(math.random(129,140)))
                        end
                        local rawTransactions = api.transactions(username)
                        local Xtrans = {}
                        local vx = 0
                        if vx < 1 then
                            vx = 1 
                        end
                        for i=vx,#rawTransactions do
                            local val = rawTransactions[i]
                            val.id = i
                            Xtrans[#Xtrans+1] = val
                        end
                        local trans = {}
                        for i,v in pairs(Xtrans) do
                            trans[#Xtrans-i+1] = v
                        end
                        local yp = 10
                        for i=scroll,h+scroll-11 do
                            local v = trans[i]
                            if v then
                                term.setCursorPos(2,yp)
                                term.setTextColor(colors.lightGray)
                                write(tostring(v.id)..": "..v.address)
                                local str = tostring(v.amount)
                                if v.amount > 0 then
                                    str = "+"..str.." <<"
                                    term.setTextColor(colors.lime)
                                else
                                    str = str .. " >>"
                                    term.setTextColor(colors.red)
                                end
                                rightAlign(str,yp)
                                yp = yp + 1
                            end
                        end
                    elseif tab == 4 then
                        local leaderboard = api.leaderboard()
                        local yp = 5
                        for i=1,math.floor((h-4)/3) do
                            if leaderboard[i] then
                                drawLogo(2,yp)
                                term.setCursorPos(5,yp)
                                term.setBackgroundColor(colors.black)
                                term.setTextColor(colors.white)
                                if i == 1 then
                                    term.setTextColor(colors.brown)
                                elseif i == 2 then
                                    term.setTextColor(colors.lightGray)
                                elseif i == 3 then
                                    term.setTextColor(colors.orange)
                                end
                                write("#"..tostring(i)..": "..leaderboard[i][1])
                                term.setCursorPos(5,yp+1)
                                term.setBackgroundColor(colors.black)
                                term.setTextColor(colors.gray)
                                write(tostring(leaderboard[i][2]).." "..csn)
                                yp = yp + 3
                            end
                        end
                    end
                    -- Event Handling
                    local e,c,x,y
                    while true do
                        e,c,x,y = os.pullEvent()
                        if e == "mouse_click" or e == "mouse_scroll" then
                            break
                        end
                    end
                    if e == "mouse_scroll" then
                        scroll = scroll + (c*2)
                        if scroll < 1 then
                            scroll = 1
                        end
                    elseif e == "mouse_click" then
                        if y == 1 or y == 2 or y == 3 then
                            if x < w/2 then
                                tab = tab - 1
                                if tab == 0 then
                                    tab = #tabs
                                end
                            elseif x > w/2 then
                                tab = tab + 1
                                if tab > #tabs then
                                    tab = 1
                                end
                            end
                        elseif tab == 1 then
                            if y == h-1 then
                                break
                            end
                        elseif tab == 2 then
                            if y == 7 then
                                term.setBackgroundColor(colors.gray)
                                term.setTextColor(colors.white)
                                term.setCursorPos(10,7)
                                transferTO = string.upper(read())
                            elseif y == 9 then
                                term.setBackgroundColor(colors.gray)
                                term.setTextColor(colors.white)
                                term.setCursorPos(10,9)
                                transferAMT = read()
                            elseif y == 11 then
                                term.setBackgroundColor(colors.black)
                                term.setTextColor(colors.brown)
                                term.setCursorPos(10,11)
                                write("...")
                                term.setCursorPos(10,11)
                                if tonumber(transferAMT) then
                                    if tonumber(transferAMT) > 0 then
                                        local ok,err = api.send(username,password,transferTO,tonumber(transferAMT))
                                        if ok and balance ~= api.balance(username) then
                                            write("Success!")
                                        else
                                            write("Failed.")
                                        end
                                    else
                                        write("Invalid amount.")
                                    end
                                else
                                    write("Invalid amount.")
                                end
                                os.pullEvent("mouse_click")
                            end
                        end
                    end
                end
            else
                term.setCursorPos(2,12)
                term.setTextColor(colors.brown)
                term.clearLine()
                term.setCursorPos(2,12)
                write("Invalid credentials.")
                sleep(2)
            end
        else
            -- Sign Up
            drawHeader()
            term.setCursorPos(2,6)
            term.setTextColor(colors.brown)
            write("Sign Up")
            term.setCursorPos(2,8)
            term.setTextColor(colors.lightGray)
            write("Username")
            term.setCursorPos(2,10)
            write("Password")
            term.setCursorPos(2,12)
            write("Confirm")
            term.setCursorPos(11,8)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
            write(string.rep(" ",w-11))
            term.setCursorPos(11,10)
            write(string.rep(" ",w-11))
            term.setCursorPos(11,12)
            write(string.rep(" ",w-11))
            term.setCursorPos(12,8)
            term.setTextColor(colors.white)
            local username = string.upper(read())
            term.setCursorPos(12,10)
            term.setTextColor(colors.white)
            local password = read("*")
            term.setCursorPos(12,12)
            local confirm = read("*")
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.gray)
            term.setCursorPos(2,14)
            write("Loading...")
            if #username > 16 then
                term.setCursorPos(2,14)
                term.setTextColor(colors.brown)
                term.clearLine()
                term.setCursorPos(2,14)
                write("Name too long!")
                sleep(2)
            elseif password == confirm then
                if api.register(username,password) then
                    term.setCursorPos(2,14)
                    term.setTextColor(colors.brown)
                    term.clearLine()
                    term.setCursorPos(2,14)
                    write("Account created!")
                    sleep(2)
                else
                    term.setCursorPos(2,14)
                    term.setTextColor(colors.brown)
                    term.clearLine()
                    term.setCursorPos(2,14)
                    write("Username in use.")
                    sleep(2)
                end
            else
                term.setCursorPos(2,14)
                term.setTextColor(colors.brown)
                term.clearLine()
                term.setCursorPos(2,14)
                write("Passwords must match.")
                sleep(2)
            end
        end
    end
end
