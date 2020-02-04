-- Tests Copas socket timeouts
--
-- Run the test file, it should exit successfully without hanging.

local copas = require("copas")
local socket = require("socket")

-- hack; no way to kill copas.loop from thread
local function error(err)
  print(debug.traceback(err, 2))
  os.exit(-1)
end
local function assert(truthy, err)
  if not truthy then
    print(debug.traceback(err, 2))
    os.exit(-1)
  end
end

-- udp echo server for testing against, returns `ip, port` to connect to
-- send `quit\n` to cause server to disconnect client
-- stops listen server after provided number of echos
local function singleuseechoserver(die_after)
  local print = function(...) print("!", ...) end

  local die_after = die_after or 1
  local server = socket.udp()
  server:setsockname("127.0.0.1", 0) -- "localhost" fails because of IPv6 error
  local ip, port = server:getsockname()

  copas.addthread(function()
    local skt = copas.wrap(server)
    while die_after > 0 do
      local data, ip, port = skt:receivefrom()
      if not data or data == "quit" then
        break
      end
      print("server data ("..#data.."):", data)
      skt:sendto(data, ip, port)
      die_after = die_after - 1
    end

    print("server end")
  end)

  return ip, port
end

local tests = {}

--function tests.receive_timeout()
--  local ip, port = singleuseechoserver(1)
--
--  copas.addthread(function()
--    local client = socket.udp()
--    client = copas.wrap(client)
--    client:settimeout(1)
--    local status, err = client:setpeername(ip, port)
--    assert(status, "failed to connect: "..tostring(err))
--
--    client:send("foo")
--    local data, err = client:receive()
--    assert(data, "failed to recieve: "..tostring(err))
--    assert(data == "foo", "recieved wrong echo: "..tostring(data))
--
--    local data, err = client:receive()
--    assert(data == nil, "somehow recieved echo without sending")
--    assert(err == "timeout", "failed with non-timeout error")
--
--    client:close()
--  end)
--
--  print("loop")
--  copas.loop()
--end

function tests.receivefrom_timeout()
  local ip, port = singleuseechoserver(1)

  local print = function(...) print("@", ...) end


  copas.addthread(function()
    local client = socket.udp()
    client = copas.wrap(client)
    client:settimeout(1)

    client:sendto("foo", ip, port)
    print("tfc", client)
    print("tft", client.timeout)
    local data, err = client:receivefrom()
    print("1", "rfb")
    assert(data, "failed to recieve: "..tostring(err))
    assert(data == "foo", "recieved wrong echo: "..tostring(data))

    local data, err = client:receivefrom()
    print("2", "rfb")
    assert(data == nil, "somehow recieved echo without sending")
    assert(err == "timeout", "failed with non-timeout error")

    client:close()

    print("end thread")
  end)

  print("loop")
  copas.loop()
end

-- test "framework"
for name, test in pairs(tests) do
  print("testing: "..tostring(name))
  local status, err = pcall(test)
  if not status then
    error(err)
  end
end

print("[✓] all tests completed successuly")
