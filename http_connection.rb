require 'em-http'

module EventMachine 
  class HttpConnection
    def initialize
      puts 'Initializing your monkeypatch'
      @deferred = true
      @middleware = []
    end
    def unbind(reason)
      puts '>> RECONNECTING <<'
      @clients.map { |c| c.unbind(reason) }

      if r = @pending.shift
        @clients.push r

        r.reset!
        @p.reset!

        begin
          @conn.set_deferred_status :unknown

          if @connopts.proxy
            @conn.reconnect(@connopts.host, @connopts.port)
          else
            @conn.reconnect(r.req.host, r.req.port)
          end

          @conn.callback { r.connection_completed }
        rescue EventMachine::ConnectionError => e
          @clients.pop.close(e.message)
        end
      else
        @conn.close_connection
      end
    end
    alias :close :unbind
  end
end