require 'rubygems'
require 'bundler/setup'
require 'em-http'
require 'em-http/middleware/oauth'

# require_relative 'http_connection'
#require_relative 'em_http_twitter_request'

class TwitterStream
  URL = 'https://stream.twitter.com/1/statuses/filter.json'
  # network failure reconnections
  NF_RECONNECT_START = 0.25
  NF_RECONNECT_ADD   = 0.25
  NF_RECONNECT_MAX   = 16

  # app failure reconnections
  AF_RECONNECT_START = 10
  AF_RECONNECT_MUL   = 2

  RECONNECT_MAX   = 320
  RETRIES_MAX     = 10

  OAUTHCONFIG = {
    :consumer_key     => ENV['TWITTER_KEY'],
    :consumer_secret  => ENV['TWITTER_SECRET'],
    :access_token     => ENV['TWITTER_ACCESS_TOKEN'],
    # use this to test handling of >200 HTTP status codes
    #:access_token_secret => 'pqoweiruwqeopiruqwepoiruqweporiuwqeproiuqwe'
    :access_token_secret => ENV['TWITTER_ACCESS_TOKEN_SECRET']
  }
  
  #bb_array represents the bounding box in which to listen for tweets.
  #it is [sw_long,sw_lat,ne_long,ne_lat] => yes, that is correct, long/lat despite the docs saying otherwise...
  def initialize(bb_array = [-75.280327,39.864841,-74.941788,40.154541], terms = nil)
    @terms = terms
    @locations = bb_array.join(',')
    @callbacks = []
    @buffer = BufferedTokenizer.new("\r")
    @query = { :locations => @locations, :stall_warnings => true }
    unless terms.nil?
      @query[:track => terms]
    end
    #@gracefully_closed = false
    @nf_last_reconnect = nil
    @af_last_reconnect = nil
    @reconnect_retries = 0
    @immediate_reconnect = false
    puts ">> INITIALIZING <<"
    
    listen
  end
  
  def ontweet(&block)
    @callbacks << block
  end

  def on_disconnect(&block)
    @disconnect_callback = block
  end

  def on_reconnect(&block)
    @reconnect_callback = block
  end

  def on_max_reconnects(&block)
    @max_reconnects_callback = block
  end

  def on_connect_error(&block)
    @connect_error_callback = block
  end
  
  private
  
  def listen
    @conn = EM::HttpRequest.new(URL, {:ssl => {:verify_peer => false}})
    @conn.use EM::Middleware::OAuth, OAUTHCONFIG
    @http = @conn.post({
      :head => { 'Content-Type' => 'application/x-www-form-urlencoded' },
      :body => @query,
      :inactivity_timeout => 0
    })

    @http.callback do |caller|
      if [0, 200].include?(caller.response_header.status)
        @disconnect_callback.call if @disconnect_callback
        schedule_reconnect
      else
        @connect_error_callback.call(caller.response_header.status)
        EM.stop
      end
    end

    @http.errback do |caller|
      @connect_error_callback.call(caller.response_header.status)
    end
    
    @http.stream do |chunk|
      @immediate_reconnect = true if @reconnect_retries == 0
      process_buffer(chunk)
    end
  end
  
  def process_buffer(chunk)
    @buffer.extract(chunk).each do |line|
      process_line(line)
    end
  end

  def process_line(line)
    line.chomp!
    line.strip!
    @callbacks.each { |c| c.call(line) } if line.start_with?('{') && line.end_with?('}')
  end

  def schedule_reconnect
    timeout = reconnect_timeout
    @reconnect_retries += 1
    if timeout <= RECONNECT_MAX && @reconnect_retries <= RETRIES_MAX
      reconnect_after(timeout)
    else
      @max_reconnects_callback.call(timeout, @reconnect_retries) if @max_reconnects_callback
    end
  end

  def reconnect_after(timeout)
    @reconnect_callback.call(timeout, @reconnect_retries) if @reconnect_callback

    if timeout == 0
      listen
    else
      EM.add_timer(timeout) do
        listen
      end
    end
  end

  def reconnect_timeout
    if @immediate_reconnect
      @immediate_reconnect = false
      return 0
    end

    if [0, 200].include?(@http.response_header.status) # network failure
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
