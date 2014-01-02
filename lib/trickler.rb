require "socket"

module Trickler
  KB_FACTOR = 1024
  MB_FACTOR = 1024 * KB_FACTOR

  DEFAULT_PORT = 1234
  DEFAULT_HOST = "localhost"

  DEFAULT_MESSAGE_SIZE = 1 * KB_FACTOR
  DEFAULT_MESSAGE_RATE = 1 # per second

  DEFAULT_TIMEOUT = 1

  MAX_MSG_SIZE = DEFAULT_MESSAGE_SIZE
  OK = "OK"
  OK_SIZE = OK.size

  class Config
    attr_accessor :host, :port, :rate, :size
  end

  def self.log(msg)
    puts "[#{Time.now}] #{msg}"
  end

  def self.serve(config)
    server = TCPServer.new(config.host, config.port)
    while true
      log "Awaiting client"
      client = server.accept
      log "Accepted client"

      begin
        while wait(client)
          d = client.recv(MAX_MSG_SIZE)
          client.write(OK)
          client.flush
          log "Acked client (payload size: #{d.length})"
        end
      rescue
        client.close
        log "Closed client"
      end
    end
  end

  def self.wait(socket, timeout=DEFAULT_TIMEOUT)
    sa = [socket]
    IO.select(sa, sa, sa, timeout) != nil
  end

  def self.trickle(config)
    while true
      log "Attempting connection"
      begin
        client = TCPSocket.new config.host, config.port
        log "Connected"

        while true
          log "Send"
          client.write("Y" * config.size)
          client.flush
          if wait(client)
            client.recv(OK_SIZE)
            puts "OK"
          else
            puts "Missed!"
          end
          sleep(1.0 / config.rate.to_f)
        end
      rescue Exception => e
        exit if e.kind_of?(Interrupt)
        log "Exception: #{e.class.to_s} #{e.to_s} #{e.backtrace}"
      ensure
        if client != nil
          client.close
        end
      end
    end
  end
end
