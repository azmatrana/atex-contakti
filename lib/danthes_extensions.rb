require 'redis'
class UserSubscriptions

  def initialize(conf_file, env)

    yaml = ::YAML.load(::ERB.new(::File.read(conf_file)).result)[env]

    @options = { host: 'localhost', port: 6379 }
    yaml.each do |key, val|
      @options[key.to_sym] = val
    end

  end

  def incoming(message, callback)
    # puts "Incoming message " + message.inspect
    case message['channel']
    when "/meta/handshake"
      self.associate_user_id_with_message_id(message)
    end
    callback.call(message)
  end

  def outgoing(message, callback)
    # puts "Outgoing message " + message.inspect
    case message['channel']
    when "/meta/handshake"
      self.user_connections_increase(message)
    else
    end
    callback.call(message)
  end

  def key_prefix
    "danthes:"
  end

  def clear_user_ids_key
    "#{self.key_prefix}clear_user_ids"
  end

  def stored_user_ids_key
    "#{self.key_prefix}user_ids"
  end

  def stored_message_associations_key
    "#{self.key_prefix}message_associations"
  end

  def clients_redis
    @clients_redis ||= Redis.new ({:host => @options[:host], :port => @options[:port], :timeout => 5.0, :connect_timeout => 5.0})
    @clients_redis
  end

  def client_disconnected(client_id)
    redis_key = "client_#{client_id}_has_connection"
    key_exists = self.clients_redis.exists(redis_key)
    if key_exists == true
      begin
        self.clients_redis.set(redis_key, 'false')
        self.clients_redis.expire(redis_key, 3600)
      rescue Exception => e
        puts e
      end
    end

    puts "client #{client_id} disconnected"
    stored_clients = JSON.parse(self.clients_redis.get(self.stored_user_ids_key) || "{}")
    user_id = nil
    if stored_clients
      stored_clients.keys.each do |c|
        if stored_clients[c].include?(client_id)
          user_id = c
          stored_clients[c].delete(client_id)
          if stored_clients[c].length == 0
            self.user_offline(c)
          end
          break
        end
      end
      self.clients_redis.set(self.stored_user_ids_key, stored_clients.to_json)
    end
    puts "User #{user_id} has #{JSON.parse(self.clients_redis.get(self.stored_user_ids_key))[user_id.to_s].to_s} connections"
  end

  def user_offline(user_id)
    clear_ids = JSON.parse(self.clients_redis.get(self.clear_user_ids_key) || "[]")
    clear_ids << user_id
    self.clients_redis.set(self.clear_user_ids_key, clear_ids.to_json)
  end

  def delete_from_clear_user_ids(user_id)
    clear_ids = JSON.parse(self.clients_redis.get(self.clear_user_ids_key) || "[]")
    if clear_ids.delete(user_id)
      self.clients_redis.set(self.clear_user_ids_key, clear_ids.to_json)
    end
  end

  def associate_user_id_with_message_id(message)
    if message['user_id']
      old_values = JSON.parse(self.clients_redis.get(self.stored_message_associations_key) || "{}")
      if old_values
        old_values[message['id']] = message['user_id']
        self.clients_redis.set(self.stored_message_associations_key, old_values.to_json)
      end
    end
  end

  def remove_message_association(message_id)
    values = JSON.parse(self.clients_redis.get(self.stored_message_associations_key) || "{}")
    if values
      values.delete(message_id)
      self.clients_redis.set(self.stored_message_associations_key, values.to_json)
    end
  end

  def user_connections_increase(message)
    stored_associations = JSON.parse(self.clients_redis.get(self.stored_message_associations_key) || "{}")
    user_id = stored_associations[message['id']]
    if user_id
      self.remove_message_association(message['id'])
      old_val = JSON.parse(self.clients_redis.get(self.stored_user_ids_key) || "{}")
      old_client_ids = old_val[user_id] || []
      old_client_ids << message['clientId']
      old_val[user_id] = old_client_ids
      self.clients_redis.set(self.stored_user_ids_key, old_val.to_json)
      self.delete_from_clear_user_ids(user_id)
      puts "User #{user_id} has #{JSON.parse(self.clients_redis.get(self.stored_user_ids_key))[user_id.to_s].to_s} connections"
    end
  end
end
