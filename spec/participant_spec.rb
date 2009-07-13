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
          sleep 0.1
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
          sleep 0.1
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
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    @msg.should == 'foo'
  end

  it "should support a default queue name" do

    pdef = <<-EOF
    class AmqpParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        amqp 'reply_anyway' => true
        echo 'done.'
      end
    end
    EOF

    amqp = RuoteAMQP::Participant.new( :default_queue => 'test5' )
    @engine.register_participant( :amqp, amqp )

    run_definition( pdef )

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test5').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end
  end

  it "should support mapping participant names to queue names" do
    pdef = <<-EOF
    class AmqpParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        q1
        q2
        amqp
        echo 'done.'
      end
    end
    EOF

    amqp = RuoteAMQP::Participant.new( :reply_by_default => true, :default_queue => 'test6' )
    amqp.map_participant( 'q1', 'test7' )
    amqp.map_participant( 'q2', 'test8' )
    @engine.register_participant( :amqp, amqp )
    @engine.register_participant( :q1, amqp )
    @engine.register_participant( :q2, amqp )

    run_definition( pdef )

    @tracer.to_s.should == 'done.'

    [ 'test6', 'test7', 'test8' ].each do |q|
      begin
        Timeout::timeout(10) do
          @msg = nil
          MQ.queue( q ).subscribe { |msg| @msg = msg }

          loop do
            break unless @msg.nil?
            sleep 0.1
          end
        end
      rescue Timeout::Error
        violated "Timeout waiting for message on #{q}"
      end
    end
  end
end
