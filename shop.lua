--/ Dynamic Shop / Reactified /--

--/ Automatic Updating /--
local h = http.get("https://raw.githubusercontent.com/Reactified/cc-economy/master/shop.lua")
if h then
    f = fs.open(shell.getRunningProgram(),"r")
    local data = f.readAll()
    f.close()
    local stream = h.readAll()
    h.close()
    if data ~= stream then
        print("Shop update detected!")
        print("Installing in 5 seconds")
        sleep(5)
        f = fs.open(shell.getRunningProgram(),"w")
        f.writeLine(stream)
        f.close()
        print("Installing...")
        sleep(1)
        print("Complete!")
        sleep(1)
        os.reboot()
    end
end

--/ Initialization /--
local currency = "AU"
local errors = {}
local m = peripheral.find("monitor")
local modem = peripheral.find("modem")

--/ Shop API /--
if not fs.exists("/api.lua") then
    h = http.get("https://raw.githubusercontent.com/Reactified/cc-economy/master/api.lua")
    if h then
        f = fs.open("/api.lua","w")
        f.writeLine(h.readAll())
        f.close()
    else
        errors[#errors+1] = "Unable to download API"
    end
end
local ok,err = pcall(function() os.loadAPI("/api.lua") end)
if not ok then
    errors[#errors+1] = "Economy server unreachable"
end

--/ Data Persistence /--
local data = {
    price_change_time = 120,
    price_change_magnitude = 0.01,
    price_increase_magnitude = 0.1,
}
local init =  false
local function saveData()
    f = fs.open("/.shopdata","w")
    f.writeLine(textutils.serialise(data))
    f.close()
end
if fs.exists('/.shopdata') then
    f = fs.open("/.shopdata","r")
    data = textutils.unserialise(f.readAll())
    f.close()
else
    init = true
end

--/ Inventory Management /--
local price_change_time = data.price_change_time -- How often the shop lowers prices
local price_change_magnitude = data.price_change_magnitude -- How much the shop lowers prices
local price_increase_magnitude = data.price_increase_magnitude -- How much prices increase per item sold
local stock = {}
local uncategorized = {}
local function genID(item)
    return item.name.."/"..tostring(item.damage)
end
local function invMgmt()
    while init do
        sleep(5)
    end
    while true do
        nstock = {}
        uncategorized = {}
        for i=1,16 do
            local item = turtle.getItemDetail(i)
            if item then
                local id = genID(item)
                if data.products[id] then
                    nstock[id] = (nstock[id] or 0) + item.count
                else
                    uncategorized[id] = true
                end
            end
        end
        stock = {}
        for i,v in pairs(nstock) do
            stock[#stock+1] = {i,v}
        end
        -- Dynamic Pricing
        for i,v in pairs(data.products) do
            if v.price_timer > price_change_time then
                local delta = v.price - v.min_price
                data.products[i].price = v.price - (delta * price_change_magnitude)
                data.products[i].price_timer = 0
                saveData()
            end
            data.products[i].price_timer = v.price_timer + 1
        end
        sleep(1)
    end
end

--/ Shop Routine /--
local function shopRoutine()
    -- Check Peripherals
    if not modem then
        errors[#errors+1] = "No modem detected."
    end
    if not m then 
        errors[#errors+1] = "No monitor detected."
    elseif m and not m.isColor() then
        errors[#errors+1] = "Advanced monitor required."
    end
    if #errors > 0 then
        -- Abort Startup
        os.pullEvent("INFINITE-YIELD")
    end
    -- UI Functions
    m.setTextScale(0.5)
    local w,h = m.getSize()
    local function center(str,ln)
        m.setCursorPos(1+(w/2)-(#str/2),ln)
        m.write(str)
    end
    -- First Time Setup
    while init do
        m.setTextScale(0.5)
        m.setBackgroundColor(colors.white)
        m.clear()
        m.setTextColor(colors.black)
        center("Welcome!",h/2-2)
        m.setTextColor(colors.gray)
        center("Perform first time setup",h/2)
        center("on the turtle's interface.",h/2+1)
        m.setCursorPos(2,2)
        m.setTextColor(colors.lightGray)
        m.write(string.rep(".",w-2))
        m.setCursorPos(2,h-1)
        m.write(string.rep(".",w-2))
        m.setTextColor(colors.lime)
        for i=1,4 do
            m.setCursorPos(math.random(2,w-2),2)
            m.write(",")
            m.setCursorPos(math.random(2,w-2),h-1)
            m.write(",")
        end
        sleep(0.5)
    end
    -- Routine
    while true do
        -- Draw Background
        m.setBackgroundColor(colors.gray)
        m.clear()
        m.setBackgroundColor(data.color)
        m.setCursorPos(1,1)
        m.clearLine()
        m.setCursorPos(1,2)
        m.clearLine()
        m.setCursorPos(1,3)
        m.clearLine()
        m.setCursorPos(2,2)
        if data.color == colors.white then
            m.setTextColor(colors.black)
        else
            m.setTextColor(colors.white)
        end
        center(data.name,2)
        -- Products
        m.setBackgroundColor(colors.gray)
        m.setTextColor(colors.lightGray)
        center("Right-click to purchase",h-2)
        for i,v in pairs(stock) do
            local product = data.products[v[1]]
            if product then
                m.setBackgroundColor(colors.gray)
                m.setTextColor(colors.lightGray)
                m.setCursorPos(1,4+(i*3))
                m.write(string.rep(string.char(140),w))
                m.setCursorPos(2,2+(i*3))
                m.setTextColor(colors.lightGray)
                m.write("> ")
                m.setTextColor(data.color)
                m.write(product.name)
                m.setTextColor(colors.white)
                local str = tostring(math.floor(product.price)).." "..currency
                m.setCursorPos(w-#str,2+(i*3))
                m.write(str)
                m.setCursorPos(2,3+(i*3))
                m.setTextColor(colors.lightGray)
                m.write(tostring(v[2]).."x in stock")
                local str = "each"
                m.setCursorPos(w-#str,3+(i*3))
                m.write(str)
            end
        end
        -- Event Handling
        local tmr = os.startTimer(10)
        while true do
            local e,c,x,y = os.pullEvent()
            if e == "timer" and c == tmr then
                break
            elseif e == "monitor_touch" then
                local sel = stock[math.floor((y-2)/3)]
                if sel then
                    local product = data.products[sel[1]]
                    local price = math.floor(product.price)
                    m.setBackgroundColor(colors.gray)
                    m.clear()
                    m.setBackgroundColor(data.color)
                    m.setCursorPos(1,1)
                    m.clearLine()
                    m.setCursorPos(1,2)
                    m.clearLine()
                    m.setCursorPos(1,3)
                    m.clearLine()
                    m.setCursorPos(2,2)
                    if data.color == colors.white then
                        m.setTextColor(colors.black)
                    else
                        m.setTextColor(colors.white)
                    end
                    center(data.name,2)
                    m.setBackgroundColor(colors.gray)
                    m.setTextColor(colors.lightGray)
                    center("Purchasing",5)
                    center("> Cancel <",h-1)
                    center("Send "..currency.." to",math.floor(h/2)+2)
                    center(tostring(price).." "..currency.." / each",8)
                    m.setTextColor(data.color)
                    center(" "..data.username.." ",math.floor(h/2)+3)
                    center(product.name,7)
                    center(tostring(sel[2]).." available",h-3)
                    local function vendingFunction()
                        local state = 0
                        while true do
                            state = state + 1
                            if state == 1 or state == 6 then
                                center("------------------",math.floor(h/2)+1)
                                center("------------------",math.floor(h/2)+4)
                                if state == 6 then
                                    state = 0
                                end
                            elseif state == 2 or state == 5 then
                                center(" ---------------- ",math.floor(h/2)+1)
                                center(" ---------------- ",math.floor(h/2)+4)
                            elseif state == 3 or state == 4 then
                                center("  --------------  ",math.floor(h/2)+1)
                                center("  --------------  ",math.floor(h/2)+4)
                            end
                            sleep(0.2)
                            if state == 5 then
                                local bal = api.balance(data.username)
                                if type(bal) == "number" and bal >= tonumber(price) then
                                    local amount = math.floor(bal/price)
                                    api.send(data.username,data.password,data.vault,bal)
                                    for _=1,amount do
                                        for slot=1,16 do
                                            local data = turtle.getItemDetail(slot)
                                            if data then
                                                if genID(data) == sel[1] then
                                                    turtle.select(slot)
                                                    turtle.dropUp(1)
                                                    break
                                                end
                                            end
                                        end
                                        sleep()
                                    end
                                    data.products[sel[1]].price = data.products[sel[1]].price * (1+price_change_magnitude)
                                    break
                                end
                            end
                        end
                    end
                    local function cancelUiFunction()
                        while true do
                            local e,c,x,y = os.pullEvent("monitor_touch")
                            if y > h-2 then break end
                        end
                    end
                    parallel.waitForAny(vendingFunction,cancelUiFunction)
                end
                break
            end
        end
    end
end

--/ Admin UI /--
local function adminUI()
    -- Initialization
    term.setBackgroundColor(colors.gray)
    term.clear()
    term.setCursorPos(2,2)
    term.setTextColor(colors.lightGray)
    write("Dynamic Shop - Boot")
    term.setCursorPos(2,4)
    term.setTextColor(colors.white)
    write("Initializing...")
    sleep(1)
    if #errors > 0 then
        term.setCursorPos(2,6)
        write("!! Fatal Error(s) Encountered:")
        for i,v in pairs(errors) do
            term.setCursorPos(2,7+i)
            write("- "..v)
        end
        print()
        print()
        print(" Startup aborted.")
        if m and m.isColor() then
            m.setTextScale(0.5)
            m.setBackgroundColor(colors.blue)
            m.clear()
            m.setTextColor(colors.white)
            m.setCursorPos(2,2)
            m.write("0xCE2752129 | INIT ERR")
            for i,v in pairs(errors) do
                m.setCursorPos(2,3+i)
                m.write(string.upper(v))
            end
        end
        sleep(20)
        os.reboot()
    else
        term.setCursorPos(2,5)
        write("Complete!")
    end
    local w,h = term.getSize()
    -- First Time Setup
    if init then
        -- Setup Stage 1
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(2,2)
        term.setTextColor(colors.white)
        write("Dynamic Shop | Setup 1/4")
        term.setCursorPos(2,4)
        term.setTextColor(colors.lightGray)
        write("Shop Name")
        term.setTextColor(colors.gray)
        term.setCursorPos(2,6)
        write("Select a display name to be")
        term.setCursorPos(2,7)
        write("shown on the display.")
        term.setCursorPos(2,h-1)
        write("> ")
        term.setTextColor(colors.white)
        data.name = read()
        -- Setup Stage 2
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(2,2)
        term.setTextColor(colors.white)
        write("Dynamic Shop | Setup 2/4")
        term.setCursorPos(2,4)
        term.setTextColor(colors.lightGray)
        write("Shop Username")
        term.setTextColor(colors.gray)
        term.setCursorPos(2,6)
        write("The name of this economy account")
        term.setCursorPos(2,7)
        write("This will be auto-capitalized.")
        term.setCursorPos(2,h-1)
        write("> ")
        term.setTextColor(colors.white)
        data.username = string.upper(read())
        -- Setup Stage 3
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(2,2)
        term.setTextColor(colors.white)
        write("Dynamic Shop | Setup 3/4")
        term.setCursorPos(2,4)
        term.setTextColor(colors.lightGray)
        write("Vault Username")
        term.setTextColor(colors.gray)
        term.setCursorPos(2,6)
        write("The account to send any earnings to")
        term.setCursorPos(2,7)
        write("This will be auto-capitalized.")
        term.setCursorPos(2,h-1)
        write("> ")
        term.setTextColor(colors.white)
        data.vault = string.upper(read())
        -- Setup Stage 4
        local selection = 1
        while true do
            term.setBackgroundColor(colors.gray)
            term.clear()
            term.setCursorPos(2,2)
            term.setTextColor(colors.white)
            write("Dynamic Shop | Setup 4/4")
            term.setCursorPos(2,4)
            term.setTextColor(colors.lightGray)
            write("Accent Color")
            term.setCursorPos(2,6)
            local options = {}
            for i,v in pairs(colors) do
                if type(v) == "number" and v ~= colors.gray then
                    options[#options+1] = v
                end
            end
            if term.isColor() then
                for i,v in pairs(options) do
                    term.setBackgroundColor(v)
                    write("  ")
                end
                term.setCursorPos((selection*2),7)
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.white)
                write("^^")
            else
                term.setCursorPos(2,7)
                term.setTextColor(colors.white)
                local option = options[selection]
                for i,v in pairs(colors) do
                    if v == option then
                        option = i
                    end
                end
                write(string.upper(option))
            end
            term.setTextColor(colors.black)
            term.setCursorPos(2,h-2)
            write("<> Change Selection")
            term.setCursorPos(2,h-1)
            write("[Enter] Select Color")
            local e,k = os.pullEvent('key')
            if k == keys.right then
                selection = selection + 1
                if selection > 15 then selection = 15 end
            elseif k == keys.left then
                selection = selection - 1
                if selection < 1 then selection = 1 end
            elseif k == keys.enter then
                data.color = options[selection]
                break
            end
        end
        -- Setup Completion
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setTextColor(colors.white)
        term.setCursorPos(2,2)
        write(">> setup")
        term.setCursorPos(2,4)
        write("registering account.. ")
        sleep(1)
        data.password = tostring(math.random(99999,9999999))
        if api.register(data.username,data.password) then
            write("success!")
        else
            write("failed!")
            term.setCursorPos(2,6)
            write("fatal error, restarting.")
            sleep(2)
            os.reboot()
        end
        term.setCursorPos(2,5)
        write("building database.. ")
        sleep(0.5)
        data.products = {}
        write('success!')
        sleep(0.5)
        term.setCursorPos(2,6)
        write("saving data.. ")
        sleep(1)
        saveData()
        write("success!")
        term.setCursorPos(2,8)
        write("setup complete!")
        term.setCursorPos(2,9)
        write("press any key")
        os.pullEvent('key')
        init = false
    end
    -- Menu Functions
    local function menu(options,ln)
        local selection = 1
        while true do
            term.setBackgroundColor(colors.gray)
            for i,v in pairs(options) do
                term.setCursorPos(1,ln+i-1)
                term.clearLine()
                term.setCursorPos(2,ln+i-1)
                if selection == i then
                    term.setTextColor(colors.white)
                    write("> "..v)
                else
                    term.setTextColor(colors.lightGray)
                    write("| "..v)
                end
            end
            local e,k = os.pullEvent("key")
            if k == keys.up then
                selection = selection - 1
                if selection < 1 then
                    selection = #options
                end
            elseif k == keys.down then
                selection = selection + 1
                if selection > #options then
                    selection = 1
                end
            elseif k == keys.enter then
                return selection
            end
        end
    end
    local function count(tbl)
        local count = 0
        for i,v in pairs(tbl) do
            count = count + 1
        end
        return count
    end
    -- Routine
    while true do
        term.setBackgroundColor(colors.gray)
        term.clear()
        term.setBackgroundColor(colors.lightGray)
        term.setCursorPos(2,1)
        term.clearLine()
        term.setCursorPos(2,1)
        term.setTextColor(colors.black)
        write(data.name)
        local sel = menu({"Products ("..tostring(count(data.products))..")","Uncategorized ("..tostring(count(uncategorized))..")"},3)
        if sel == 1 then
            term.setBackgroundColor(colors.gray)
            term.clear()
            term.setBackgroundColor(colors.lightGray)
            term.setCursorPos(2,1)
            term.clearLine()
            term.setCursorPos(2,1)
            term.setTextColor(colors.black)
            write("Product List")
            local choices = {"<- Return"}
            local productids = {false}
            for i,v in pairs(data.products) do
                choices[#choices+1] = v.name
                productids[#productids+1] = i
            end
            local sel = menu(choices,3)
            if sel ~= 1 then
                local id = productids[sel]
                local product = data.products[id]
                term.setBackgroundColor(colors.gray)
                term.clear()
                term.setBackgroundColor(colors.lightGray)
                term.setCursorPos(2,1)
                term.clearLine()
                term.setCursorPos(2,1)
                term.setTextColor(colors.black)
                write(product.name)
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.lightGray)
                term.setCursorPos(2,3)
                write("Price")
                term.setCursorPos(2,4)
                write("Min Price")
                term.setCursorPos(2,5)
                write("Start Price")
                term.setCursorPos(14,3)
                term.setTextColor(colors.white)
                write(tostring(math.floor(product.price*100)/100).." "..currency)
                term.setCursorPos(14,4)
                write(tostring(product.min_price).." "..currency)
                term.setCursorPos(14,5)
                write(tostring(product.start_price).." "..currency)
                local sel = menu({"<- Return","Delete","Set Price"},7)
                if sel == 2 then
                    data.products[id] = nil
                    saveData()
                elseif sel == 3 then
                    term.setCursorPos(2,h-1)
                    term.setTextColor(colors.white)
                    write("> ")
                    local input = tonumber(read())
                    if input then
                        data.products[id].price = input
                    end
                    saveData()
                end
            end
        elseif sel == 2 then
            term.setBackgroundColor(colors.gray)
            term.clear()
            term.setBackgroundColor(colors.lightGray)
            term.setCursorPos(2,1)
            term.clearLine()
            term.setCursorPos(2,1)
            term.setTextColor(colors.black)
            write("Uncategorized Items")
            local choices = {"<- Return"}
            for i,v in pairs(uncategorized) do
                choices[#choices+1] = i
            end
            local sel = menu(choices,3)
            if sel ~= 1 then
                local id = choices[sel]
                term.setBackgroundColor(colors.gray)
                term.clear()
                term.setBackgroundColor(colors.lightGray)
                term.setCursorPos(2,1)
                term.clearLine()
                term.setCursorPos(2,1)
                term.setTextColor(colors.black)
                write("Create Product")
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.lightGray)
                term.setCursorPos(2,3)
                write("Product Name")
                term.setCursorPos(2,4)
                write("Start Price")
                term.setCursorPos(2,5)
                write("Min Price")
                term.setCursorPos(16,3)
                term.setTextColor(colors.white)
                local product = {}
                product.name = read()
                term.setCursorPos(16,4)
                product.price = tonumber(read())
                term.setCursorPos(16,5)
                product.min_price = tonumber(read())
                
                product.start_price = product.price
                product.price_timer = 0

                data.products[id] = product

                term.setCursorPos(2,7)
                if tonumber(product.price) and tonumber(product.min_price) then
                    saveData()
                    write("Product Created!")
                else
                    write("Failed")
                end
                sleep(1.5)
            end
        end
    end
end

--/ Kernel /--
parallel.waitForAll(shopRoutine,adminUI,invMgmt)
