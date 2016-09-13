require 'test_queue/runner'

module MiniTest
  def self.__run reporter, options
    suites = Runnable.runnables
    suites.map { |suite| suite.run reporter, options }
  end

  class Runnable
    def failure_count
      failures.length
    end
  end

  class Test
    def self.runnables= runnables
      @@runnables = runnables
    end

    # Synchronize all tests, even serial ones.
    #
    # Minitest runs serial tests before parallel ones to ensure the
    # unsynchronized serial tests don't overlap the parallel tests. But since
    # the test-queue master hands out tests without actually loading their
    # code, there's no way to know which are parallel and which are serial.
    # Synchronizing serial tests does add some overhead, but hopefully this is
    # outweighed by the speed benefits of using test-queue.
    def _synchronize; Test.io_lock.synchronize { yield }; end
  end

  class ProgressReporter
    # Override original method to make test-queue specific output
    def record result
      io.print '    '
      io.print result.class
      io.print ': '
      io.print result.result_code
      io.puts("  <%.3f>" % result.time)
    end
  end

  begin
    require 'minitest/minitest_reporter_plugin'

    class << self
      private
      def total_count(options)
        0
      end
    end
  rescue LoadError
  end
end

module TestQueue
  class Runner
    class MiniTest < Runner
      def initialize
        if ::MiniTest::Test.runnables.any? { |r| r.runnable_methods.any? }
          fail "Do not `require` test files. Pass them via ARGV instead and they will be required as needed."
        end
        super([])
      end

      def run_worker(iterator)
        ::MiniTest::Test.runnables = iterator
        ::MiniTest.run ? 0 : 1
      end
    end
  end

  class TestFramework
    def discover_suites
      ARGV.each do |arg|
        ::MiniTest::Test.reset
        require File.absolute_path(arg)
        ::MiniTest::Test.runnables.
          reject { |s| s.runnable_methods.empty? }.
          each do |s|
            yield s.name, arg
          end
      end
    end

    def load_suite(suite_name, path)
      @suites ||= {}

      suite = @suites[suite_name]
      return suite if suite

      ::MiniTest::Test.reset
      begin
        require File.absolute_path(path)
      rescue LoadError
        return nil
      end
      ::MiniTest::Test.runnables.
        reject { |s| s.runnable_methods.empty? }.
        each do |s|
          @suites[s.name] = s
        end

      @suites[suite_name]
    end

    def filter_suites(suites)
      paths = ARGV.to_set
      suites.select { |suite| paths.include?(suite.path) }
    end
  end
end
