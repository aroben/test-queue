require 'test_queue/runner'
require 'stringio'

class MiniTestQueueRunner < MiniTest::Unit
  def _run_suites(suites, type)
    self.class.output = $stdout

    if defined?(ParallelEach)
      # Ignore its _run_suites implementation since we don't handle it gracefully.
      # If we don't do this #partition is called on the iterator and all suites
      # distributed immediately, instead of picked up as workers are available.
      suites.map { |suite| _run_suite suite, type }
    else
      super
    end
  end

  def _run_anything(*)
    ret = super
    output.puts
    ret
  end

  def _run_suite(suite, type)
    output.print '    '
    output.print suite
    output.print ': '

    start = Time.now
    ret = super
    diff = Time.now - start

    output.puts("  <%.3f>" % diff)
    ret
  end

  self.runner = self.new
  self.output = StringIO.new
end

class MiniTest::Unit::TestCase
  class << self
    attr_accessor :test_suites

    def original_test_suites
      @@test_suites.keys.reject{ |s| s.test_methods.empty? }
    end
  end

  def failure_count
    failures.length
  end
end

module TestQueue
  class Runner
    class MiniTest < Runner
      def initialize
        tests = ::MiniTest::Unit::TestCase.original_test_suites.sort_by{ |s| -(stats[s.to_s] || 0) }
        queue = ::MiniTest::Unit::TestCase.original_test_suites
          .sort_by { |s| -(stats[s.to_s] || 0) }
          .map { |s| [s, suite_file(s)] }
        super(queue)
      end

      def run_worker(iterator)
        ::MiniTest::Unit::TestCase.test_suites = iterator
        ::MiniTest::Unit.new.run
      end

      def discover_new_suites
        ARGV.each do |arg|
          ::MiniTest::Unit::TestCase.reset
          require arg
          ::MiniTest::Unit::TestCase.original_test_suites.each do |suite|
            yield suite.name, suite_file(suite)
          end
        end
      end

      def suite_file(suite)
        suite.instance_method(suite.test_methods.first).source_location[0]
      end
    end
  end

  class TestFramework
    def load_suite(suite_name, path)
      @suites ||= {}

      suite = @suites[suite_name]
      return suite if suite

      ::MiniTest::Unit::TestCase.reset
      require path
      ::MiniTest::Unit::TestCase.original_test_suites.each do |suite|
        @suites[suite.name] = suite
      end
      @suites[suite_name]
    end
  end
end
