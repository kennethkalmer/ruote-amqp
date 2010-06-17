module RuoteAMQP

  # = AMQP Launchitem Listener
  #
  # Used on its own, the RuoteAMQP::LaunchitemListener provides the engine with
  # a way to launch process definitions over an AMQP direct exchange.
  #
  # == Message Format
  #
  # The LaunchitemListener expects JSON formatted messages that look like this:
  #
  #   {
  #     "definition" : [ 'process_definition', {}, [] ],
  #     "fields" : { "key" : "value" },
  #     "variables" : { "key" : "value" }
  #  }
  #
  # The definition key is a complete string representation of a business process.
  #
  # == Configuration
  #
  # AMQP configuration is handled by directly manipulating the values of the
  # +AMQP.settings+ hash, as provided by the AMQP gem. No defaults are set by
  # the listener. The only +option+ parsed by the initializer is the +queue+
  # key (in the optional hash). If no +queue+ key is provided, the listener
  # will subscribe to the +ruote_launchitems+ direct exchange for launchitems.
  #
  # The listener requires version 0.6.6 or later of the amqp gem.
  #
  # == Usage
  #
  # Register the engine with the listener:
  #
  #   RuoteAMQP::LaunchitemListener.new( engine_instance )
  #
  # The workitem listener leverages the asynchronous nature of the amqp gem,
  # so no timers are setup when initialized.
  class LaunchitemListener < Ruote::Receiver

    class << self

      # Listening queue - set this before initialization
      attr_writer :queue

      def queue
        @queue ||= 'ruote_launchitems'
      end

    end

    # Start a new LaunchItem listener
    #
    # @param [ Ruote::Engine ] An instance of a ruote engine
    # @param [ String ] Optional queue name
    def initialize( engine, queue = nil )

      self.class.queue = queue if queue

      RuoteAMQP.start!

      MQ.queue( self.class.queue, :durable => true ).subscribe do |message|
        if AMQP.closing?
          # Do nothing, we're going down
        else
          launchitem = decode_launchitem( message )
          engine.launch( *launchitem )
        end
      end
    end

    def stop
      RuoteAMQP.stop!
    end

    private

    # Complicated guesswork that needs to happen here to detect the format
    def decode_launchitem( msg )
      hash = Rufus::Json.decode( msg )
      opts = {}
      definition = hash.delete('definition')
      fields = hash.delete('fields') || {}
      variables = hash.delete('variables') || {}

      [ definition, fields, variables ]
    end
  end
end
