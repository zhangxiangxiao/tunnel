--[[
Tunnel initialization
Copyright 2016 Xiang Zhang
--]]

tunnel = tunnel or {}

require('tunnel.block')

require('tunnel.atomic')
require('tunnel.hash')
require('tunnel.printer')
require('tunnel.vector')

return tunnel
