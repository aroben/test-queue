require 'test_queue/runner'
require 'rspec/core'

case ::RSpec::Core::Version::STRING.to_i
when 2
  require_relative 'rspec2'
when 3
  require_relative 'rspec3'
else
  fail 'requires rspec version 2 or 3'
end

class ::RSpec::Core::ExampleGroup
  def self.failure_count
    examples.map {|e| e.execution_result[:status] == "failed"}.length
  end
end

module TestQueue
  class Runner
    class RSpec < Runner
      def run_worker(iterator)
        rspec = ::RSpec::Core::QueueRunner.new
        rspec.run_each(iterator).to_i
      end

      def summarize_worker(worker)
        worker.summary  = worker.lines.grep(/ examples?, /).first
        worker.failure_output = worker.output[/^Failures:\n\n(.*)\n^Finished/m, 1]
      end
    end
  end

  class TestFramework
    def all_suite_paths
      options = RSpec::Core::ConfigurationOptions.new(ARGV)
      options.parse_options if options.respond_to?(:parse_options)
      options.configure(RSpec.configuration)

      RSpec.configuration.files_to_run.uniq
    end
    
    def suites_from_path(path, raise_on_error)
      RSpec.world.reset
      begin
        load path
      rescue LoadError
        raise if raise_on_error
        return []
      end
      split_groups(RSpec.world.example_groups).map { |example_or_group|
        name = example_or_group.respond_to?(:id) ? example_or_group.id : example_or_group.to_s
        [name, example_or_group]
      }
    end

    private

    def split_groups(groups)
      return groups unless split_groups?

      # FIXME: Need a test for this.
      groups_to_split, groups_to_keep = [], []
      groups.each do |group|
        (group.metadata[:no_split] ? groups_to_keep : groups_to_split) << group
      end
      queue = groups_to_split.flat_map(&:descendant_filtered_examples)
      queue.concat groups_to_keep
      queue
    end

    def split_groups?
      return @split_groups if defined?(@split_groups)
      @split_groups = ENV['TEST_QUEUE_SPLIT_GROUPS'] && ENV['TEST_QUEUE_SPLIT_GROUPS'].strip.downcase == 'true'
    end
  end
end
