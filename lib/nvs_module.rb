require 'serialport'
module NVS
  module NMEA
    GET_PORT_INFO="CCGPQ,PORZA"
    SET_PORT_INFO="PORZA"
    CLR_MSGS="PORZB"
    RMC1_GSV5="PORZB,RMC,1,GSV,5"
    RMC5_GSV5="PORZB,RMC,5,GSV,5"
    RMC="PORZB,RMC"
  end

  module BINR
    GET_PORT_INFO="0B"
    SET_PORT_INFO="0B"
    CLR_MSGS="0E"
    RAW_DATA="F4"
  end

  def self.checksum(str)
    c = 0;
    str.split(//).each do |char|
      c ^= char.unpack('C')[0]
    end
  return sprintf("%02X",c)
  end

  def self.receive_msg(sp,mode,fh)
    while true do  # Read from device
      c = sp.getc
      if c
        c = c.unpack("H*") if mode==:binr
        fh.print c
      end
    end
  end

  def self.remove_delimiter(mode,msg)
    if mode == :binr
      msg[1..-2]
    else
      msg[1..-5]
    end
  end
  def self.response(sp,mode,nchar,timeout=nil)
    if mode==:nmea
      nchr=nchar[0]
    else
      nchr=nchar[1]
    end
    nrcv=0
    nchar=10000 # we want to remove the
    # code to check num chars later on
    res=[]
    now=Time.now
    while (nrcv<=nchr) do
      if timeout
        break if (Time.now-now) > timeout
      end
      c = sp.getc
      next unless c
      if mode==:binr
        c =  c.unpack('H*')[0]
        break if c=="03" 
      else
        break if c=="\n"
      end
      res << c
      p c if $debug
      nrcv+=1
    end
    p nrcv
    res
  end

  def self.discriminate_msg(mode,msg)
    if mode==:nmea
      NVS::NMEA.const_get(msg)
    else
      NVS::BINR.const_get(msg)
    end
  end

  def self.format_msg(mode,msg,params)
    msg="#{msg}#{params}"
    return "$#{msg}*#{checksum(msg)}\r\n" if mode==:nmea
    ["10#{msg}1003"].pack('H*') 
  end

 def self.format_msg2(mode,msg,params)
    msg="#{msg}#{params}"
    return "$#{msg}*#{checksum(msg)}\r\n" if mode==:nmea
    ["10#{msg}1003"]
 end

  def self.send_msg(sp,mode,msg,params="")
    msg = discriminate_msg(mode,msg)
    msg = format_msg(mode,msg,params)
    p msg if $debug
    sp.flush
    sp.print(msg)  # Write to device
  end
end
