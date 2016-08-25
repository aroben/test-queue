module TestQueue
  class Stats
    class Suite
      attr_reader :name, :path, :last_duration, :last_seen_at

      def initialize(name, path, last_duration, last_seen_at)
        @name = name
        @path = path
        @last_duration = last_duration
        @last_seen_at = last_seen_at
      end
    end

    def initialize(path)
      @path = path
      @suites = {}
      self.load
    end

    def all_suites
      @suites.values
    end

    def suite(name)
      @suites[name]
    end

    def record_suites(suites)
      suites.each do |suite|
        @suites[suite.name] = suite
      end
    end

    def save
      prune

      data = @suites.each_value.map do |suite|
        [suite.name, suite.path, suite.last_duration, suite.last_seen_at]
      end

      File.open(@path, 'wb') do |f|
        f.write Marshal.dump(data)
      end
    end

    private

    def load
      data = begin
               # FIXME: Need to handle reading an old format
               Marshal.load(IO.binread(@path))
             rescue Errno::ENOENT
             end
      return unless data
      data.each do |name, path, last_duration, last_seen_at|
        @suites[name] = Suite.new(name, path, last_duration, last_seen_at)
      end
    end

    def prune
      earliest = Time.now - (8 * 24 * 60 * 60)
      @suites.delete_if do |name, suite|
        suite.last_seen_at < earliest
      end
    end
  end
end
