print "Running Timeout Test..."

print(...)

package.path = './src/?.lua;./?.lua;' .. package.path

local socket = require "socket"
local copas = require "copas"
local asynchttp = require("copas.http").request

if true then
  local testtimeout = 2

  function runsocket()
    local sock = assert(socket.udp())
    local sock = copas.wrap(sock)

    local timeout = testtimeout - 1 -- seconds

    local responses = {}

    local ip = '127.0.0.1'
    local port = 9
    assert(sock:sendto("hello nobody", ip, port), "sent sendto for ssdp discover")

    sock:settimeout(timeout)
    local recv, err = sock:receive()

    if recv ~= nil then
      error("received a packet while testing timeout, test invalid")
    elseif err and err ~= "timeout" then
      error(err)
    end

    print("IT FUCKING WORKS!!!")
  end

  copas.addthread(runsocket)

  local timeouttime = os.time() + testtimeout

  repeat
    copas.step(1)
  until os.time() > timeouttime or copas.finished()

  assert(copas.finished(), "failed to finish task, presumably still waiting in receive")
end

-- part 2

if true then
  local list = {
    "http://httpbin.org/delay/2",
    "http://httpbin.org/delay/0",
    "http://httpbin.org/delay/1",
    "http://httpbin.org/delay/10",
  }

  local handler = function(host)
    res, err = asynchttp(host)
    if res then
      print("request finised: "..host)
    elseif err == "timeout" then
      print("request timed-out:", host)
    else
      print("actual error on:", host, err)
    end
  end

  for _, host in ipairs(list) do copas.addthread(handler, host) end

  local timeouttime = os.time() + 10

  repeat
    copas.step(1)
  until os.time() > timeouttime or copas.finished()
end

print("end")
