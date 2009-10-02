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
  #     "definition" : "URL or process definition",
  #     "fields" : { "key" : "value" }
  #  }
  #
  # The definition key can be a complete string representation of a business
  # process, or a URL pointing to the process definition. Note that the
  # engine needs to be configured to load process definitions from URL's
  #
  # == Configuration
  #
  # AMQP configuration is handled by directly manipulating the values of the
  # +AMQP.settings+ hash, as provided by the AMQP gem. No defaults are set by
  # the listener. The only +option+ parsed by the initializer is the +queue+
  # key (in the optional hash). If no +queue+ key is provided, the listener
  # will subscribe to the +ruote_launchitems+ direct exchange for launchitems.
  #
  # The listener requires version 0.6.1 or later of the amqp gem.
  #
  # == Usage
  #
  # Register the listener with the engine:
  #
  #   engine.register_listener( RuoteAMQP::LaunchitemListener )
  #
  # The workitem listener leverages the asynchronous nature of the amqp gem,
  # so no timers are setup when initialized.
  class LaunchitemListener

    include Ruote::EngineContext

    class << self

      # Listening queue - set this before initialization
      attr_writer :queue

      def queue
        @queue ||= 'ruote_launchitems'
      end

    end

    def initialize( options = {} )

      if q = options.delete(:queue)
        self.class.queue = q
      end

      RuoteAMQP.start!

      MQ.queue( self.class.queue, :durable => true ).subscribe do |message|
        if AMQP.closing?
          # Do nothing, we're going down
        else
          launchitem = decode_launchitem( message )
          engine.launch( launchitem )
        end
      end
    end

    def stop
      RuoteAMQP.stop!
    end

    private

    # Complicated guesswork that needs to happen here to detect the format
    def decode_launchitem( msg )
      hash = Ruote::Json.decode( msg )
      opts = {}
      definition = hash.delete('definition')
      fields = hash.delete('fields') || {}

      ::Ruote::Launchitem.new( definition, fields )
    end
  end
end
