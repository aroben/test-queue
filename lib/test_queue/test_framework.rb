# This class provides an abstraction over the various test frameworks we
# support. The framework-specific implementations are defined in the various
# test_queue/runner/* files. This file just defines the interface.
class TestFramework
  # Discover all suites to run by loading them from disk.
  #
  # An example implementation might `require` test files from the repository
  # one-by-one and yield the suites found in each file.
  #
  # Yields a series of 2-element Arrays containing:
  #
  # suite_name - String suite name (or could be an RSpec Example/ExampleGroup
  #              ID; whatever's appropriate for the test framework)
  # path       - String file path of the file that contains the suite
  def discover_suites
  end

  # Load the specified suite from the specified path.
  #
  # suite_name - String suite name (or could be an RSpec Example/ExampleGroup
  #              ID; whatever's appropriate for the test framework)
  # path       - String file path of the file that contains the suite
  #
  # Returns a runnable test suite object appropriate for the test framework.
  def load_suite(suite_name, path)
    raise NotImplementedError
  end
end
