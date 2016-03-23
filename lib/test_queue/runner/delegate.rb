module TestQueue
  class Runner
    # Delegate gets called at various points during the test run.
    class Delegate
      # Run in the master before the fork. Used to create
      # concurrency copies of any databases required by the
      # test workers.
      def prepare(concurrency)
      end

      def around_filter(suite)
        yield
      end

      # Prepare a worker for executing jobs after a fork.
      def after_fork(num)
      end

      def cleanup_worker
      end

      # Override to monitor the status of the queue.
      #
      # For example, you may want to record metrics about how quickly remote
      # workers connect, or abort the build if not enough connect.
      #
      # This method is called very frequently during the test run, so don't do
      # anything expensive/blocking.
      #
      # This method is not called on remote masters when using remote workers,
      # only on the central master.
      #
      # start_time          - Time when the test run began
      # queue_size          - Integer number of suites left in the queue
      # local_worker_count  - Integer number of active local workers
      # remote_worker_count - Integer number of active remote workers
      #
      # Returns nothing.
      def queue_status(start_time, queue_size, local_worker_count, remote_worker_count)
      end

      def summarize(workers)
      end
    end
  end
end
