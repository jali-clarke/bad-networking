require 'socket'

class Player
  attr_accessor :color, :x, :y, :port

  def initialize(port, color)
    @port = port
    @color = color
    @x = 0
    @y = 0
  end
end
change = false
threads = []

# Ctrl-c will kill threads
at_exit do
  puts 'trapping'
  threads.each do |t|
    puts 'killing'
    Thread.kill t
  end
end

# this gurantees something you choose will not be executed more then 60 times a second
def once_per_frame
  last = Time.now
  while true
    yield
    now = Time.now
    _next = [last + (1 / 60), now].max
    sleep(_next - now)
    last = _next
  end
end

semaphore = Mutex.new

players = []

#Socket.do_not_reverse_lookup = true
s = UDPSocket.new
s.bind(nil, 4000)

#reciever
threads.push(Thread.new do
  loop do
    text, _sender = s.recvfrom(16)
    temp = text.split(' ')
    # if new connection
    # format: "0 #{port}"
    if temp[0] == '0'
      semaphore.synchronize do
        players.push Player.new(temp[1], 'red')#colors.delete(colors.sample))
        s.send("0 #{players.last.color}", 0, 'localhost', temp[1])
      end
    #else if player updating their position
    # format: "1 #{port} #{x}-#{y}"
    elsif temp[0] == '1'
      semaphore.synchronize do
        user = players.select { |player| player.port == temp[1] }
        # something changed, inform sender to send update
        if (user.first.x != temp[2].split('-')[0]) && (user.first.x != temp[2].split('-')[0])
          user.first.x = temp[2].split('-')[0]
          user.first.y = temp[2].split('-')[1]
          change = true
        end
      end
    end
  end
end)

#sender
threads.push(Thread.new do
  once_per_frame do
    semaphore.synchronize do
      # only if something changed should you send an update
      if change
        change = false
        players.each do |target|
          players.each do |player, _str|
            s.send("#{player.color}-#{player.x}-#{player.y}", 0, 'localhost', target.port)
          end
        end
      end
    end
  end
end)

#prevents threads of going to background
loop do
  sleep 2
end
