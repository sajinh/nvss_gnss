require "./make_msgs.rb"
require 'pp'

def hex_fmt(arr)
  arr.join.scan(/../).map {|a| '0x'+a}.join(",")
end
nvs = NVSMessages.new(:nmea)
puts "NMEA CLR MSG"
p nvs.clear_messages
puts "NMEA GET PORT INFO"
p  nvs.formatted_msg(:GET_PORT_INFO)

nvs.mode=:binr
puts "BINR CLR"
p nvs.clear_messages
msg=  nvs.formatted_msg(:GET_PORT_INFO)
puts "BINR GET PORT INFO"
pp hex_fmt(msg)
msg=  nvs.formatted_msg(:SET_PORT_INFO,:port=>2,:baud=>9600, :new_mode=>:binr)
puts "BINR SET PORT INFO :baud=> 9600"
p hex_fmt(msg)

nvs.mode=:binr
msg=  nvs.formatted_msg(:SET_PORT_INFO,:port=>2,:baud=>9600, :new_mode=>:nmea)
puts "BINR SET PORT INFO :baud=> 9600, :new_mode=>:nmea"
p hex_fmt(msg)

puts "BINR ASK RAW DATA (F5h every second)"
frq = [10.to_i].pack('C*').unpack('H*')[0]
p frq
msg = nvs.send_msg("F4",frq)
p hex_fmt(msg)
nvs.mode=:nmea
msg = nvs.send_msg("PORZB,RMC,5")
p msg

