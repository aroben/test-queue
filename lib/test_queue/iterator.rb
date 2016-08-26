module TestQueue
  class Iterator
    attr_reader :suites, :sock

    def initialize(test_framework, sock, suites, filter=nil, early_failure_limit: nil)
      @test_framework = test_framework
      @done = false
      @suites = []
      @procline = $0
      @sock = sock
      @filter = filter
      if @sock =~ /^(.+):(\d+)$/
        @tcp_address = $1
        @tcp_port = $2.to_i
      end
      @failures = 0
      @early_failure_limit = early_failure_limit
    end

    def each
      fail "already used this iterator. previous caller: #@done" if @done

      while true
        # If we've hit too many failures in one worker, assume the entire
        # test suite is broken, and notify master so the run
        # can be immediately halted.
        if @early_failure_limit && @failures >= @early_failure_limit
          connect_to_master("KABOOM")
          break
        else
          client = connect_to_master('POP')
        end
        break if client.nil?
        _r, _w, e = IO.select([client], nil, [client], nil)
        break if !e.empty?

        if data = client.read(65536)
          client.close
          item = Marshal.load(data)
          break if item.nil? || item.empty?
          next if item == "WAIT"
          suite_name, file = item
          suite = @test_framework.load_suite(suite_name, file)

          # Maybe we were told to load a suite that doesn't exist anymore.
          next unless suite

          $0 = "#{@procline} - #{suite.respond_to?(:description) ? suite.description : suite}"
          start = Time.now
          if @filter
            @filter.call(suite){ yield suite }
          else
            yield suite
          end
          @suites << TestQueue::Stats::Suite.new(suite_name, file, Time.now - start, Time.now)
          @failures += suite.failure_count if suite.respond_to? :failure_count
        else
          break
        end
      end
    rescue Errno::ENOENT, Errno::ECONNRESET, Errno::ECONNREFUSED
    ensure
      @done = caller.first
      File.open("/tmp/test_queue_worker_#{$$}_suites", "wb") do |f|
        f.write Marshal.dump(@suites)
      end
    end

    def connect_to_master(cmd)
      sock =
        if @tcp_address
          TCPSocket.new(@tcp_address, @tcp_port)
        else
          UNIXSocket.new(@sock)
        end
      sock.puts(cmd)
      sock
    rescue Errno::EPIPE
      nil
    end

    include Enumerable

    def empty?
      false
    end
  end
end
