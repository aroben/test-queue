# This class provides an abstraction over the various test frameworks we
# support. The framework-specific implementations are defined in the various
# test_queue/runner/* files. This file just defines the interface.
class TestFramework
  # Load the specified suite from the specified path.
  #
  # suite_name - String suite name (or could be an RSpec Example/ExampleGroup
  #              ID; whatever's appropriate for the test framework)
  # path       - String file path
  #
  # Returns a runnable test suite object appropriate for the test framework.
  def load_suite(suite_name, path)
    raise NotImplementedError
  end
end
