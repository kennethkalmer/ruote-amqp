require File.dirname(__FILE__) + '/spec_helper'

describe RuoteAMQP::WorkitemListener do

  it "should handle replies" do

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'foo', :value => 'foo'
      sequence do
        echo '${f:foo}'
        amqp :queue => 'test3'
        echo '${f:foo}'
      end
    end

    @engine.register_participant( :amqp, RuoteAMQP::Participant )

    RuoteAMQP::WorkitemListener.new( @engine )

    fei = @engine.launch pdef

    begin
      Timeout::timeout(5) do
        @msg = nil
        MQ.queue('test3').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    wi = Ruote::Workitem.new( Rufus::Json.decode( @msg ) )
    wi.fields['foo'] = "bar"

    MQ.queue( wi.fields['params']['reply_queue'] ).publish( Rufus::Json.encode( wi.to_h ) )

    @engine.context.logger.wait_for( fei )

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "foo\nbar"

    purge_engine
  end
end

