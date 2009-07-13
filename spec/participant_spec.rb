require File.dirname(__FILE__) + '/spec_helper'

describe RuoteAMQP::Participant, :type => :ruote do

  it "should support 'reply anyway' on expression parameter" do

    pdef = <<-EOF
    class AmqpParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        amqp :queue => 'test1', 'reply_anyway' => true
        echo 'done.'
      end
    end
    EOF

    @engine.register_participant( :amqp, RuoteAMQP::Participant )

    run_definition( pdef )

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test1').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    @msg.should match(/^\{.*\}$/) # JSON message by default
  end

  it "should support 'reply anyway' as participant configuration" do
    pdef = <<-EOF
    class AmqpParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        amqp :queue => 'test4'
        echo 'done.'
      end
    end
    EOF

    p = RuoteAMQP::Participant.new( :reply_by_default => true )
    @engine.register_participant( :amqp, p )

    run_definition( pdef )

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test4').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    @msg.should match( /^\{.*\}$/) # JSON message by default
  end

  it "should support custom messages instead of workitems" do
    pdef = <<-EOF
    class AmqpParticipant1 < OpenWFE::ProcessDefinition

      sequence do
        amqp :queue => 'test2', :message => 'foo', 'reply_anyway' => true
        echo 'done.'
      end
    end
    EOF

    @engine.register_participant( :amqp, RuoteAMQP::Participant )

    run_definition( pdef )

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test2').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    @msg.should == 'foo'
  end
end
