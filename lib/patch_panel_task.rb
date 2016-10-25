# Software patch-panel.
class PatchPanel < Trema::Controller
  def start(_args)
    @patch = Hash.new {|hash, key| hash[key] = []}
    @mirror = Hash.new {|hash, key| hash[key] = []}
    logger.info 'PatchPanel started.'
  end

  def switch_ready(dpid)
    @patch[dpid].each do |port_a, port_b|
      delete_flow_entries dpid, port_a, port_b
      add_flow_entries dpid, port_a, port_b
    end
    @mirror[dpid].each do |port_a, port_b|
      delete_flow_entries dpid, port_a, port_b
      add_flow_entries dpid, port_a, port_b
    end
  end



  def create_patch(dpid, port_a, port_b)
    add_flow_entries dpid, port_a, port_b
    @patch[dpid] << [port_a, port_b].sort	#for two-dimensional array
  end

  def delete_patch(dpid, port_a, port_b)
    delete_flow_entries dpid, port_a, port_b
    @patch[dpid] -= [port_a, port_b].sort
  end

#task1 mirroring
  def create_mirrorring(dpid, observer, target)
    add_mirroring dpid, observer, target
    @mirror[dpid] << [observer, target]
  end

#task2 list
  def show_list_patch_mirroring(dpid)
    tmp = Array.new()
    tmp << @patch
    tmp << @mirror
    return tmp
  end


  private

  def add_flow_entries(dpid, port_a, port_b)
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: SendOutPort.new(port_b))
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_b),
                      actions: SendOutPort.new(port_a))
  end

  def delete_flow_entries(dpid, port_a, port_b)
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_a))
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_b))
  end

#task1
  def add_mirroring(dpid, observer, target)
    @patch[dpid].each do |port_a, port_b|
      port_tmp = nil
      port_tmp = port_b if port_a == target
      port_tmp = port_a if port_b == target
      if port_tmp != nil then
        send_flow_mod_delete(dpid, match: Match.new(in_port: target))
        send_flow_mod_delete(dpid, match: Match.new(in_port: port_tmp))
        send_flow_mod_add(dpid,
                      match: Match.new(in_port: target),
                      actions:[ 
                        SendOutPort.new(port_tmp),
                        SendOutPort.new(observer)
                    ])
        send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_tmp),
                      actions:[ 
                        SendOutPort.new(target),
                        SendOutPort.new(observer)
                    ])
      end
    end
  end



end
