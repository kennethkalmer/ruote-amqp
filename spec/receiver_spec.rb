
require File.dirname(__FILE__) + '/spec_helper'

# rspec clobbering global space... :(
undef :context if defined?(:context)


describe RuoteAMQP::Receiver do

  it "should handle replies" do

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'foo', :value => 'foo'
      sequence do
        echo '${f:foo}'
        amqp :queue => 'test3'
        echo '${f:foo}'
      end
    end

    @engine.register_participant( :amqp, RuoteAMQP::ParticipantProxy )

    RuoteAMQP::Receiver.new( @engine )

    wfid = @engine.launch pdef

    begin
      Timeout::timeout( 5 ) do
        @msg = nil
        MQ.queue( 'test3', :durable => true ).subscribe { |msg| @msg = msg }

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

    MQ.queue( 'ruote_workitems' ).publish( Rufus::Json.encode( wi.to_h ) )

    @engine.wait_for( wfid )

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "foo\nbar"

    purge_engine
  end

  it "should launch processes" do
    json = {
      "definition" => "
        Ruote.process_definition :name => 'test' do
          sequence do
            echo '${f:foo}'
          end
        end
      ",
      "fields" => {
        "foo" => "bar"
      }
    }.to_json

    RuoteAMQP::Receiver.new( @engine, :launchitems => true )

    MQ.queue( 'ruote_workitems' ).publish( json )

    sleep 0.5

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "bar"

    purge_engine
  end
end

