require 'rubygems'
require 'bundler/setup'

require_relative 'twitter_stream'

EM.run do
  
  @count = 0
  philly = [-75.280327,39.864841,-74.941788,40.154541]
  stream = TwitterStream.new(philly)

  stream.ontweet do |tweet|
    puts tweet
    @count += 1
  end

  stream.on_disconnect do |_, _|
    $stdout.print "\n>>>>>>>>>>>>>>>>>>>>> Disconnected at #{Time.now} <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
    $stdout.flush
  end

  stream.on_reconnect do |timeout, _|
    $stdout.print "\n>>>>>>>>>>>>>>>>>>>>> Reconnecting in: #{timeout} seconds <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
    $stdout.flush
  end

  stream.on_max_reconnects do |_, retries|
    $stdout.print "\n>>>>>>>>>>>>>>>>>>>>> Failed after #{retries} failed reconnects <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
    $stdout.flush
  end
    
  EM.add_periodic_timer(60) do
    puts "\n>>>>>>>>>>>>>>>>>>>>> TWEET COUNT: #{@count} <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
  end
  
end