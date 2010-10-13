
require File.dirname(__FILE__) + '/spec_helper'


describe RuoteAMQP::ParticipantProxy, :type => :ruote do

  it "should support 'forget' as participant attribute" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :queue => 'test1', :forget => true
        echo 'done.'
      end
    end

    @engine.register_participant( :amqp, RuoteAMQP::ParticipantProxy )

    run_definition( pdef )

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout( 10 ) do
        @msg = nil
        MQ.queue( 'test1', :durable => true ).subscribe { |msg| @msg = msg }

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
      :amqp, RuoteAMQP::ParticipantProxy, 'forget' => true )

    run_definition( pdef )

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout( 5 ) do
        @msg = nil
        MQ.queue( 'test4', :durable => true ).subscribe { |msg| @msg = msg }

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

    @engine.register_participant( :amqp, RuoteAMQP::ParticipantProxy )

    run_definition( pdef )

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout( 5 ) do
        @msg = nil
        MQ.queue( 'test2', :durable => true ).subscribe { |msg| @msg = msg }

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
      :amqp, RuoteAMQP::ParticipantProxy, 'queue' => 'test5' )

    run_definition( pdef )

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout( 5 ) do
        @msg = nil
        MQ.queue( 'test5', :durable => true ).subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end
  end

  it "should pass 'participant_options' over amqp" do

    pdef = ::Ruote.process_definition :name => 'test' do
      amqp :queue => 'test6', :forget => true
    end

    @engine.register_participant( :amqp, RuoteAMQP::ParticipantProxy )

    run_definition( pdef )

    msg = nil

    begin
      Timeout::timeout( 10 ) do

        MQ.queue( 'test6', :durable => true ).subscribe { |m| msg = m }

        loop do
          break unless msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    wi = Rufus::Json.decode( msg )
    params = wi['fields']['params']

    params['queue'].should == 'test6'
    params['forget'].should == true
    params['participant_options'].should == { 'forget' => false, 'queue' => nil }
  end
end

