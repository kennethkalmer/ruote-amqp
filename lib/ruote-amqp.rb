require 'mq'

# AMQP participant and listener pair for ruote.
#
# == Documentation
#
# See #RuoteAMQP::Listener and #RuoteAMQP::Participant for detailed
# documentation on using each of them.
#
# == AMQP Notes
#
# RuoteAMQP uses durable queues and persistent messages by default, to ensure
# no messages get lost along the way and that running expressions doesn't have
# to be restarted in order for messages to be resent.
#
module RuoteAMQP

  VERSION = '2.1.4pre'

  autoload 'Participant',        'ruote-amqp/participant'
  autoload 'WorkitemListener',   'ruote-amqp/workitem_listener'
  autoload 'LaunchitemListener', 'ruote-amqp/launchitem_listener'

  class << self

    attr_writer :use_persistent_messages

    # Whether or not to use persistent messages (true by default)
    def use_persistent_messages?
      @use_persistent_messages = true if @use_persistent_messages.nil?
      @use_persistent_messages
    end

    # Ensure the AMQP connection is started
    def start!
      return if started?

      mutex = Mutex.new
      cv = ConditionVariable.new

      Thread.main[:ruote_amqp_connection] = Thread.new do
        Thread.abort_on_exception = true
        AMQP.start {
          started!
          cv.signal
        }
      end

      mutex.synchronize { cv.wait(mutex) }

      MQ.prefetch(1)

      yield if block_given?
    end

    # Check whether the AMQP connection is started
    def started?
      Thread.main[:ruote_amqp_started] == true
    end

    def started! #:nodoc:
      Thread.main[:ruote_amqp_started] = true
    end

    # Close down the AMQP connections
    def stop!
      return unless started?

      AMQP.stop
      Thread.main[:ruote_amqp_connection].join
      Thread.main[:ruote_amqp_started] = false
    end

  end
end
