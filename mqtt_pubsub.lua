sensorID = "status"    -- a sensor identifier for this device
tgtHost = "iot.eclipse.org" -- target host (broker)
tgtPort = 1883          -- target port (broker listening on)
mqttUserID = "MQTT_USER_ID"     -- account to use to log into the broker
mqttPass = "MQTT_USER_PASSWORD"     -- broker account password
mqttTimeOut = 120       -- connection timeout
dataInt = 1         -- data transmission interval in seconds
topicQueue = "/readEsp8266"-- the MQTT topic queue to use
pin = 1

local nmea = require "nmea"

-- Subscribe to a topic
function subscribe()
    print("subscribed")
    mqttBroker:subscribe("/control/#",0, function(conn) end)
end
 
 
-- Reconnect to MQTT when we receive an "offline" message.
function reconn()
    print("Disconnected, reconnecting....")
    conn()
end


-- Establish a connection to the MQTT broker with the configured parameters.
function conn()
    print("Making connection to MQTT broker")
    mqttBroker:connect(tgtHost, tgtPort, 0, 1,function(client) 
        print ("connected") 
        subscribe() 
        gps()
        end, function(client, reason) print("failed reason: " .. reason) end)
end

function performTask(topic,data)
    if(topic == "/control/led" and data == "OFF")
    then
    gpio.mode(pin, gpio.OUTPUT,gpio.PULLUP)
    gpio.write(pin, gpio.LOW)
    elseif(topic == "/control/led" and data == "ON")
    then
    gpio.mode(pin, gpio.OUTPUT,gpio.PULLUP)
    gpio.write(pin, gpio.HIGH)
    elseif(topic == "/control/led" and data == "RESET")
    then
    node.restart()
    elseif(topic == "/control/led" and data == "STATUS")
    then
    status = gpio.read(pin)
    print("status" .. status)
    if status == 0
    then 
    mqttBroker:publish(topicQueue, "led_pin:off", 2, 0,function(client) -- publish
        print("published")
        end)
    elseif status == 1
    then
     mqttBroker:publish(topicQueue, "led_pin:on", 2, 0,function(client)-- publish
        print("published")
        end)
    else
    print("Do Nothing")
    end
  end

end
 
function makeConn()
    -- Instantiate a global MQTT client object
    print("Instantiating mqttBroker")
    mqttBroker = mqtt.Client(sensorID, mqttTimeOut, mqttUserID, mqttPass, 1)
 
    -- Set up the event callbacks
    print("Setting up callbacks")
    mqttBroker:on("connect", function(client) print ("connected") end)
    mqttBroker:on("offline", reconn)
    
    -- Recieve the Msg from Broker
    mqttBroker:on("message", function(conn, topic, data)
    print("MQTT Message Received...")
    print("Topic: " .. topic)
    if data ~= nil then
    print("Message: " .. data)
    -- Perform Speific Task based on Topic & Data
    performTask(topic,data)
    end
end)
    -- Connect to the Broker
    conn()
end

function gps()
    -- setup GPS Reciever
    uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
    handleGPS()
end

function handleGPS()
    print("GPS Data")
    uart.on("data", 255,
        function(data)
        print("receive from uart:", data)
       --  repeat
      --  local data1 = split(data,",")
      --  local result = nmea.decode(data1)
       -- print("decoded data : ")
        mqttBroker:publish(topicQueue, data, 2, 0) 
      --  for k,v in pairs(result) 
      --  do 
      --  print(k.." => "..v)
       -- mqttBroker:publish(topicQueue, k .. "=" .. v, 2, 0)  -- publish
       -- end
   -- until false
   -- print("decoded")
        if data=="quit" then
        uart.on("data") -- unregister callback function
        end
    end, 0)
end
   


