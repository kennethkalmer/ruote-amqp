
require File.dirname(__FILE__) + '/spec_helper'


describe RuoteAMQP::Participant, :type => :ruote do

  it "should support 'forget' as participant attribute" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :queue => 'test1', :forget => true
        echo 'done.'
      end
    end

    @engine.register_participant( :amqp, RuoteAMQP::Participant )

    run_definition( pdef )

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout( 10 ) do
        @msg = nil
        MQ.queue( 'test1' ).subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    @msg.should match( /^\{.*\}$/ ) # JSON message by default
  end

  it "should support 'forget' as participant option" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :queue => 'test4'
        echo 'done.'
      end
    end

    @engine.register_participant(
      :amqp, RuoteAMQP::Participant, 'forget' => true )

    run_definition( pdef )

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout(5) do
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

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :queue => 'test2', :message => 'foo', :forget => true
        echo 'done.'
      end
    end

    @engine.register_participant( :amqp, RuoteAMQP::Participant )

    run_definition( pdef )

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout(5) do
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

  it "should support 'queue' as a participant option" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :forget => true
        echo 'done.'
      end
    end

    @engine.register_participant(
      :amqp, RuoteAMQP::Participant, 'queue' => 'test5' )

    run_definition( pdef )

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout(5) do
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
end

