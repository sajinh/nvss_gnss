require File.join(File.dirname(__FILE__), 'nvs_module')
class NVSMessages
  attr_accessor :mode
  def initialize(mode)
    @mode = mode
  end

  def debug=(args=true)
    $debug=args
  end

  def format_param(params)
    if self.mode==:nmea
      return(",#{params.join(',')}")
    else
      return(params.join(""))
    end
  end

  def formatted_msg(msg,phsh={})
    msg = NVS::discriminate_msg(self.mode,msg)
    params = set_port(phsh) 
    msg = NVS::format_msg2(self.mode,msg,params)
  end

  def send_msg(msg,params="")
    msg = NVS::format_msg2(self.mode,msg,params)
  end

  def clear_messages
    formatted_msg(:CLR_MSGS)
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

  def set_port(hsh)
    return("") if hsh.empty?
    port=({:port=>0}.merge(hsh))[:port]
    if self.mode == :binr
      baud = [hsh[:baud].to_i].pack('L*').unpack('H*')[0]
      new_mode = binr_proto.index(hsh[:new_mode])
      new_mode = [new_mode].pack('C').unpack('H*')[0]
      params = "0#{port}#{baud}#{new_mode}"
    else
      baud = hsh[:baud]
      new_mode = nmea_proto.index(hsh[:new_mode])
      params = ",#{port},#{baud},#{new_mode}"
    end
    params
  end
end
