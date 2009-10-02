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

    @engine.register_listener( RuoteAMQP::WorkitemListener )

    fei = @engine.launch pdef

    begin
      Timeout::timeout(5) do
        @msg = nil
        MQ.queue('test3').subscribe { |msg| @msg = msg; puts @msg }

        loop do
          break unless @msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    wi = Ruote::Workitem.from_h( Ruote::Json.decode( @msg ) )
    wi.attributes['foo'] = "bar"

    MQ.queue( wi.attributes['params']['reply_queue'] ).publish( Ruote::Json.encode( wi.to_h ) )

    @engine.context[:s_logger].wait_for([
      [ :processes, :terminated, { :wfid => fei } ],
      [ :errors, nil, { :wfid => fei } ]
    ])

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "foo\nbar"

    purge_engine
  end
end

