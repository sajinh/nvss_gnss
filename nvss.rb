require './lib/nvs_gnss'
require 'serialport'
require 'pp'

def which_mode(nvs)
  mode = :nmea if nvs.in_nmea_mode?
  mode = :binr if nvs.in_binr_mode?
  p "We are in #{mode.to_s.upcase} mode"
  mode
end

usbport="/dev/cu.usbserial-AH01PTDB"
usbport="/dev/ttyUSB0"
sp = SerialPort.new(usbport,115200,8,1,  SerialPort::ODD)
nvs = NVSHandler.new(sp)
nvs.debug = true

# find what mode we are in

 which_mode(nvs)

# We can set up the mode without knowing which mode
# we are in

p "set NVS to NMEA mode"
nvs.set_mode(:nmea) # set nvs to NMEA mode
which_mode(nvs)

p "set NVS to BINR mode"
ans=nvs.set_mode(:binr) # now set to BINR mode
if ans
p "success" 
else
  p "failed to set new mode"
end
which_mode(nvs)

p nvs.set_mode(:binr)
nvs.mode=:binr
p nvs.get_port_info
p nvs.in_nmea_mode?
p nvs.get_port_info
sp.close
