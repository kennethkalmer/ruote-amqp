require File.dirname(__FILE__) + '/spec_helper'

describe RuoteAMQP::Listener do

  it "should handle replies" do
    pdef = <<-EOF
    class AmqpParticipant2 < OpenWFE::ProcessDefinition

      set :field => 'foo', :value => 'foo'

      sequence do
        echo '${f:foo}'
        amqp :queue => 'test3'
        echo '${f:foo}'
      end
    end
    EOF

    @engine.register_participant( :amqp, RuoteAMQP::Participant )

    @engine.register_listener( RuoteAMQP::Listener )

    fei = @engine.launch pdef

    begin
      Timeout::timeout(10) do
        msg = nil
        MQ.queue('test3').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    wi = OpenWFE::InFlowWorkItem.from_h( OpenWFE::Json.decode( @msg ) )
    wi.attributes['foo'] = "bar"

    MQ.queue( wi.attributes['reply_queue'] ).publish( OpenWFE::Json.encode( wi.to_h ) )

    wait( fei )

    @engine.should_not have_errors( fei )
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "foo\nbar"

    purge_engine
  end
end
