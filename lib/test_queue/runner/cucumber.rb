require 'cucumber'
require 'cucumber/rspec/disable_option_parser'
require 'cucumber/cli/main'

module Cucumber
  module Ast
    class Features
      attr_accessor :features
    end

    class Feature
      def to_s
        title
      end
    end
  end

  class Runtime
    if defined?(::Cucumber::Runtime::FeaturesLoader)
      # Without this module, Runtime#features would load all features specified
      # on the command line. We want to avoid that and load only the features
      # each worker needs ourselves, so we override the default behavior to let
      # us put our iterator in place without loading any features directly.
      module InjectableFeatures
        def features
          return @features if defined?(@features)
          super
        end

        def features=(iterator)
          @features = ::Cucumber::Ast::Features.new
          @features.features = iterator
        end
      end

      prepend InjectableFeatures
    else
      attr_writer :features
    end
  end
end

module TestQueue
  class Runner
    class Cucumber < Runner
      def run_worker(iterator)
        runtime = @test_framework.runtime
        runtime.features = iterator

        @test_framework.cli.execute!(runtime)

        if runtime.respond_to?(:summary_report, true)
          runtime.send(:summary_report).test_cases.total_failed
        else
          runtime.results.scenarios(:failed).size
        end
      end

      def summarize_worker(worker)
        output                = worker.output.gsub(/\e\[\d+./, '')
        worker.summary        = output.split("\n").grep(/^\d+ (scenarios?|steps?)/).first
        worker.failure_output = output.scan(/^Failing Scenarios:\n(.*)\n\d+ scenarios?/m).join("\n")
      end
    end
  end

  class TestFramework
    class FakeKernel
      def exit(n)
      end
    end

    def cli
      @cli ||= ::Cucumber::Cli::Main.new(ARGV.dup, $stdin, $stdout, $stderr, FakeKernel.new)
    end

    def runtime
      @runtime ||= ::Cucumber::Runtime.new(cli.configuration)
    end

    def all_suite_paths
      if runtime.respond_to?(:feature_files, true)
        runtime.send(:feature_files)
      else
        cli.configuration.feature_files
      end
    end

    def suites_from_path(path)
      if defined?(::Cucumber::Core::Gherkin::Document)
        source = ::Cucumber::Runtime::NormalisedEncodingFile.read(path)
        doc = ::Cucumber::Core::Gherkin::Document.new(path, source)
        [[File.basename(doc.uri), doc]]
      else
        loader =
          ::Cucumber::Runtime::FeaturesLoader.new([path],
                                                  cli.configuration.filters,
                                                  cli.configuration.tag_expression)
        loader.features.map { |feature| [feature.title, feature] }
      end
    end
  end
end
