module RuoteAMQP

  # = AMQP Participants
  #
  # The RuoteAMQP::Participant allows you to send workitems (serialized as
  # JSON) or messages to any AMQP queues right from the process
  # definition. When combined with the RuoteAMQP::Listener you can easily
  # leverage an extremely powerful local/remote participant
  # combinations.
  #
  # By default the participant relies on the presence of an AMQP
  # listener. Workitems are sent and no replies are given to the
  # engine. The participant can be configured to reply to the engine
  # immediately after queueing a message, see the usage section below.
  #
  # == Configuration
  #
  # AMQP configuration is handled by directly manipulating the
  # values of the +AMQP.settings+ hash, as provided by the AMQP
  # gem. No AMQP defaults are set by the participant.
  #
  # The participant requires version 0.6.1 or later of the amqp gem.
  #
  # == Usage
  #
  # Currently it's possible to send either workitems or messages
  # directly to a specific queue, and have the engine wait for
  # replies on another queue (see AMQPListener).
  #
  # Setting up the participant
  #
  #   engine.register_participant(
  #     :amqp, RuoteAMQP::Participant )
  #
  # Setup a participant that always replies to the engine
  #
  #   engine.register_participant(
  #     :amqp, RuoteAMQP::Participant.new(:reply_by_default => true ) )
  #
  # Sending a message example
  #
  #   class AmqpMessageExample0 < OpenWFE::ProcessDefinition
  #     sequence do
  #       amqp :queue => 'test', :message => 'foo'
  #     end
  #   end
  #
  # Sending a workitem
  #
  #   class AmqpWorkitemExample0 < OpenWFE::ProcessDefinition
  #     sequence do
  #       amqp :queue => 'test'
  #     end
  #   end
  #
  # Let the participant reply to the engine without involving the listener
  #
  #   class AmqpWaitExample < OpenWFE::ProcessDefinition
  #     sequence do
  #       amqp :queue => 'test', :reply_anyway => true
  #     end
  #   end
  #
  # When waiting for a reply it only makes sense to send a workitem.
  #
  # Keeping things DRY with participant name to queue maps:
  #
  #   amqp = RuoteAMQP::Participant.new( :default_queue => 'test' )
  #   amqp.map_participant 'george', 'whitehouse'
  #   amqp.map_participant 'barak', 'whitehouse'
  #   amqp.map_participant 'greenspan', 'treasury'
  #
  #   engine.register_participant( :george, amqp )
  #   engine.register_participant( :barak, amqp )
  #   engine.register_participant( :greespan, amqp )
  #   engine.register_participant( :amqp, amqp )
  #
  #   class DryAmqProcess0 < OpenWFE::ProcessDefinition
  #     cursor :break_if => "${f:economy_recovered}" do
  #       # Workitem sent to 'whitehouse' queue
  #       george :activity => 'Tank economy'
  #
  #       # Workitem sent to 'treasury' queue
  #       greenspan :activity => 'Resign'
  #
  #       # Workitem sent to 'whitehouse' queue
  #       barak :activity => 'Cleanup mess'
  #
  #       # Workitem sent to default 'test' queue
  #       amqp :activity => 'Notify CNN'
  #     end
  #   end
  #
  # == Workitem modifications
  #
  # To ease replies, and additional workitem attribute is set:
  #
  #   'reply_queue'
  #
  # +reply_queue+ has the name of the queue where the RuoteAMQP::Listener
  # expects replies from remote participants
  #
  # == AMQP notes
  #
  # The participant currently only makes use of direct
  # exchanges. Possible future improvements might see use for topic
  # and fanout exchanges as well.
  #
  # The direct exchanges are always marked as durable by the
  # participant.
  #
  class Participant
    include OpenWFE::LocalParticipant

    # Accepts an options hash with the following keys:
    #
    # * :reply_by_default => (bool) false by default
    # * :default_queue => (string) nil by default
    def initialize( options = {} )
      ensure_reactor!

      @options = {
        :reply_by_default => false,
        :default_queue => nil
      }.merge( options )

      @participant_maps = {}
    end

    def map_participant( name, queue )
      @participant_maps[ name ] = queue
    end

    # Process the workitem at hand. By default the workitem will be
    # published to the direct exchange specified in the +queue+
    # workitem parameter. You can specify a +message+ workitem
    # parameter to have that sent instead of the workitem.
    #
    # To force the participant to reply to the engine, set the
    # +reply_anyway+ workitem parameter.
    def consume( workitem )
      ldebug { "consuming workitem" }
      ensure_reactor!

      if target_queue = determine_queue( workitem )

        q = MQ.queue( target_queue, :durable => true )

        # Message or workitem?
        if message = ( workitem.attributes['message'] || workitem.params['message'] )
          ldebug { "sending message to queue: #{target_queue}" }
          q.publish( message )

        else
          ldebug { "sending workitem to queue: #{target_queue}" }

          q.publish( encode_workitem( workitem ) )
        end
      else
        lerror { "no queue in workitem params!" }
      end

      if @options[:reply_by_default] || workitem.params['reply-anyway'] == true
        reply_to_engine( workitem )
      end

      ldebug { "done" }
    end

    def stop
      linfo { "Stopping..."  }

      AMQP.stop { EM.stop } #if EM.reactor_running? }
      @em_thread.join if @em_thread
    end

    private

    def determine_queue( workitem )
      workitem.params['queue'] ||
      @participant_maps[ workitem.participant_name ] ||
      @options[:default_queue]
    end

    # Encode (and extend) the workitem as JSON
    def encode_workitem( wi )
      wi.attributes['reply_queue'] = Listener.queue
      OpenWFE::Json.encode( wi.to_h )
    end

    def ensure_reactor!
      @em_thread = Thread.new { EM.run } unless EM.reactor_running?
    end
  end
end
