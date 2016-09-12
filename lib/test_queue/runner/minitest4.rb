require 'test_queue/runner'
require 'set'
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
        if ::MiniTest::Unit::TestCase.original_test_suites.any?
          fail "Do not `require` test files. Pass them via ARGV instead and they will be required as needed."
        end
        super([])
      end

      def run_worker(iterator)
        ::MiniTest::Unit::TestCase.test_suites = iterator
        ::MiniTest::Unit.new.run
      end
    end
  end

  class TestFramework
    def discover_suites
      ARGV.each do |arg|
        ::MiniTest::Unit::TestCase.reset
        require File.absolute_path(arg)
        ::MiniTest::Unit::TestCase.original_test_suites.each do |suite|
          yield suite.name, arg
        end
      end
    end

    def load_suite(suite_name, path)
      @suites ||= {}

      suite = @suites[suite_name]
      return suite if suite

      ::MiniTest::Unit::TestCase.reset
      begin
        require File.absolute_path(path)
      rescue LoadError
        return nil
      end
      ::MiniTest::Unit::TestCase.original_test_suites.each do |suite|
        @suites[suite.name] = suite
      end
      @suites[suite_name]
    end

    def filter_suites(suites)
      paths = ARGV.to_set
      suites.select { |suite| paths.include?(suite.path) }
    end
  end
end
