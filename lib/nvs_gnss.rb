require 'serialport'
require File.join(File.dirname(__FILE__), 'nvs_module')

class NVSHandler
  attr_reader :mode
  def initialize(sp)
    @sp = sp
    @sp.sync = true
    @mode = :nmea
  end

  def debug=(args=true)
    $debug=args
  end

  def in_right_mode?(new_mode)
    if new_mode==:nmea
      ans = self.in_nmea_mode?
    else
      ans = self.in_binr_mode?
    end
    p "In #{new_mode} mode : #{ans}" if $debug
    ans
  end

  def set_mode(new_mode)
    if in_right_mode?(new_mode)
      p "Module is in the right mode : #{self.mode.to_s.upcase}"
      p "Not changing settings"
      return(true)
    end
    p "Module is currently in #{self.mode.to_s.upcase} mode"
    p "Module will be changed to #{new_mode.to_s.upcase} mode"
    set_port(:new_mode=>new_mode)
    in_right_mode?(new_mode)
  end
  def mode=(new_mode)
    @mode=new_mode
    new_mode==:nmea ?  par=SerialPort::NONE : par=SerialPort::ODD
    @sp.parity=par
  end
  
  def in_nmea_mode?
    p "checking if we are in NMEA mode"
    self.mode=:nmea
    @sp.read_timeout=1
    clear_messages
    NVS::send_msg(@sp, :nmea, :GET_PORT_INFO)
    res=NVS::response(@sp, @mode,[22,10],1)
    # not reading all the buffer gives us trouble
    # why are we reading only 22 chars
    #res[0] == 36 ? true : false
    if res[0] == "$" 
      return true
    end
    self.mode=:binr
    false
  end
  def in_binr_mode?
    p "checking if we are in BINR mode"
    self.mode=:binr
    @sp.read_timeout=1
    clear_messages
    NVS::send_msg(@sp, :binr, :GET_PORT_INFO)
    res=NVS::response(@sp, @mode,[22,10],1)
    if res[0].to_i == 10 
      return true 
    end
    self.mode=:nmea
    false 
  end
  def clear_messages
    NVS::send_msg(@sp, @mode, :CLR_MSGS)
    sleep(0.1)
    @sp.flush
  end
  def nmea_proto
    [:none, :nmea, :diff, :binr, :binr2]
  end
  def binr_proto
    [:nil, :none, :nmea, :diff, :binr, :binr2]
  end
  def find_protocol(protocol)
    return nmea_proto[protocol] if @mode==:nmea
    binr_proto[protocol]
  end
  def baud_rate(baud)
    if @mode==:binr
      return [baud.join].pack('H*').unpack("L*")[0]
    end
  end
  def binr_port_info(res)
    p "in binr_port_info" if $debug
    port = res[1]
    protocol = res[6].to_i
    baud = baud_rate(res[2..5])
    {:port     => port, 
     :mode => find_protocol(protocol),
     :baud => baud
    }
  end

  def nmea_port_info(res)
    p "in nmea_port_info" if $debug
    res = res.join.split(",")
    port = res[1]
    protocol = res[3].to_i
    baud = res[2]
    {:port     => port, 
     :mode =>  find_protocol(protocol),
     :baud => baud
    }
  end

  def get_port_info
    puts "Retrieving Port settings"
    @sp.read_timeout=1
    clear_messages
    NVS::send_msg(@sp, @mode, :GET_PORT_INFO)
    res=NVS::response(@sp, @mode,[22,10],1)
    res=NVS::remove_delimiter(@mode,res)
    if @mode == :nmea
      return nmea_port_info(res) 
    end
    binr_port_info(res)
  end

  def recv_msg(sp,fh)
    NVS::receive_msg(sp,@mode, fh)
  end

private
  def set_port(hsh)
    #abort "Not in #{hsh[:mode]} mode \n; eXit" if not in_right_mode?(mode)
    hsh=get_port_info.merge(hsh)
    org_mode = self.mode
    if self.mode == :binr
      baud = [hsh[:baud].to_i].pack('L*').unpack('H*')[0]
      new_mode = binr_proto.index(hsh[:new_mode])
      new_mode = [new_mode].pack('C').unpack('H*')[0]
      params = "00#{baud}#{new_mode}"
    else
      baud = hsh[:baud]
      new_mode = nmea_proto.index(hsh[:new_mode])
      params = ",0,#{baud},#{new_mode}"
    end
    NVS::send_msg(@sp, org_mode, :SET_PORT_INFO,params)
    @mode = new_mode
    @sp.read_timeout=1
    res=NVS::response(@sp, @mode,[22,10],1)
  end
end
