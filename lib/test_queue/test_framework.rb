module TestQueue
  # This class provides an abstraction over the various test frameworks we
  # support. The framework-specific implementations are defined in the various
  # test_queue/runner/* files. This file just defines the interface.
  class TestFramework
    # Return all file paths to load test suites from.
    #
    # An example implementation might just return files passed on the command
    # line, or defer to the underlying test framework to determine which files
    # to load.
    #
    # Returns an Array of String file paths.
    def all_suite_paths
      raise NotImplementedError
    end

    # Load all suites from the specified path.
    #
    # path           - String file path to load suites from
    # raise_on_error - Boolean indicating whether to raise an exception if
    #                  suites cannot be loaded from the path (e.g., because
    #                  there is no file at that path)
    #
    # Returns an Array of tuples containing:
    #   suite_name   - String that uniquely identifies this suite
    #   suite        - Framework-specific object that can be used to actually
    #                  run the suite
    def suites_from_path(path, raise_on_error)
      raise NotImplementedError
    end
  end
end
