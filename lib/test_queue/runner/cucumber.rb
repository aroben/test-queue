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
    attr_writer :features
  end
end

module TestQueue
  class Runner
    class Cucumber < Runner
      def run_worker(iterator)
        runtime = @test_framework.runtime

        if defined?(::Cucumber::Runtime::FeaturesLoader)
          runtime.send(:features).features = iterator
        else
          runtime.features = iterator
        end

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

    def discover_suites
      # FIXME: This loads all features at once before yielding any of them. It
      # would be nice to yield them as they're loaded to reduce startup
      # latency.
      runtime.send(:features).each do |document|
        if document.respond_to?(:uri)
          yield File.basename(document.uri), document.uri
        else
          yield document.title, document.file
        end
      end
    end

    def load_suite(suite_name, path)
      @suites ||= {}

      suite = @suites[suite_name]
      return suite if suite

      if defined?(::Cucumber::Runtime::FeaturesLoader)
        loader =
          ::Cucumber::Runtime::FeaturesLoader.new([path],
                                                  cli.configuration.filters,
                                                  cli.configuration.tag_expression)
        loader.features.each do |feature|
          @suites[feature.title] = feature
        end
      else
        source = ::Cucumber::Runtime::NormalisedEncodingFile.read(path)
        doc = Cucumber::Core::Gherkin::Document.new(path, source)
        @suites[File.basename(doc.uri)] = doc
      end

      @suites[suite_name]
    end

    def filter_suites(suites)
      files = if runtime.respond_to?(:feature_files, true)
                runtime.send(:feature_files)
              else
                cli.configuration.feature_files
              end
      files = Set.new(files)
      suites.select { |suite| files.include?(suite.path) }
    end
  end
end
