# This class provides an abstraction over the various test frameworks we
# support. The framework-specific implementations are defined in the various
# test_queue/runner/* files. This file just defines the interface.
class TestFramework
  # Discover all suites to run by loading them from disk.
  #
  # An example implementation might `require` test files from the repository
  # one-by-one and yield the suites found in each file. This is called in a
  # separate process; changes to global state will not affect the master or its
  # workers.
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

  # Filter the list of suites to be run.
  #
  # For instance, some test frameworks might support limiting the suites to be
  # run based on command line parameters.
  #
  # suites - Array of TestQueue::Stats::Suite pulled from TestQueue::Stats.
  #
  # Returns an Array of TestQueue::Stats::Suite after applying filtering.
  def filter_suites(suites)
    suites
  end
end
