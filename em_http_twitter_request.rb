require 'rubygems'
require 'bundler/setup'
require 'em-http'

module EventMachine
  
  class TwitterRequest < HttpRequest
    def self.new(uri, options={})
      connopt = HttpConnectionOptions.new(uri, options)

      c = TwitterConnection.new
      c.connopts = connopt
      c.uri = uri
      c
    end
  end
  
  class TwitterConnection < HttpConnection
    def setup_request(method, options = {}, c = nil)
      c ||= TwitterClient.new(self, HttpClientOptions.new(@uri, options, method))
      @deferred ? activate_connection(c) : finalize_request(c)
      c.on_close do
        puts '>> Disconnected <<'
      end
      c.on_reconnect do
        puts '>> Reconnected <<'
      end
      c.on_max_reconnects do
        '>> Max Reconnects Reached <<'
      end
      c
    end
    def reconnect(host, port)
      EM::reconnect(host, port, self)
    end
  end
  
  class TwitterClient < HttpClient
    
    # network failure reconnections
    NF_RECONNECT_START = 0.25
    NF_RECONNECT_ADD   = 0.25
    NF_RECONNECT_MAX   = 16

    # app failure reconnections
    AF_RECONNECT_START = 10
    AF_RECONNECT_MUL   = 2

    RECONNECT_MAX   = 320
    RETRIES_MAX     = 10
    
    attr_accessor :immediate_reconnect
    
    def on_close &block
      @close_callback = block
    end
    
    def on_reconnect &block
      @reconnect_callback = block
    end
    
    def on_max_reconnects &block
      @max_reconnects_callback = block
    end
    
    def initialize(conn, options)
      @gracefully_closed = false
      @nf_last_reconnect = nil
      @af_last_reconnect = nil
      @reconnect_retries = 0
      @immediate_reconnect = false
      super(conn, options)
    end
    
    def unbind(reason = nil)
      if finished? 
        @close_callback.call if @close_callback
        schedule_reconnect unless @gracefully_closed 
      else
        on_error(reason)
      end
    end

    protected
    def schedule_reconnect
      timeout = reconnect_timeout
      @reconnect_retries += 1
      if timeout <= RECONNECT_MAX && @reconnect_retries <= RETRIES_MAX
        reconnect_after(timeout)
      else
        @max_reconnects_callback.call(timeout, @reconnect_retries) if @max_reconnects_callback
      end
    end

    def reconnect_after timeout
      @reconnect_callback.call(timeout, @reconnect_retries) if @reconnect_callback

      if timeout == 0
        begin
          @conn.reconnect(@req.host, @req.port)
        rescue EM::ConnectionError => e
          self.close(e.message)
        end
      else
        EM.add_timer(timeout) do
          begin
            @conn.reconnect(@req.host, @req.port)
          rescue EM::ConnectionError => e
            self.close(e.message)
          end
        end
      end
    end

    def reconnect_timeout
      if @immediate_reconnect
        @immediate_reconnect = false
        return 0
      end

      if (@response_header.status == 0) # network failure
        if @nf_last_reconnect
          @nf_last_reconnect += NF_RECONNECT_ADD
        else
          @nf_last_reconnect = NF_RECONNECT_START
        end
        [@nf_last_reconnect,NF_RECONNECT_MAX].min
      else
        if @af_last_reconnect
          @af_last_reconnect *= AF_RECONNECT_MUL
        else
          @af_last_reconnect = AF_RECONNECT_START
        end
        @af_last_reconnect
      end
    end
  end
  
end
      