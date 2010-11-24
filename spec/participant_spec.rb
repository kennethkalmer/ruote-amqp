
require File.join(File.dirname(__FILE__), 'spec_helper')


describe RuoteAMQP::ParticipantProxy, :type => :ruote do

  it "supports 'forget' as participant attribute" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :queue => 'test1', :forget => true
        echo 'done.'
      end
    end

    @engine.register_participant(:amqp, RuoteAMQP::ParticipantProxy)

    run_definition(pdef)

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test1', :durable => true).subscribe { |msg| @msg = msg }

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

  it "supports 'forget' as participant option" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :queue => 'test4'
        echo 'done.'
      end
    end

    @engine.register_participant(
      :amqp, RuoteAMQP::ParticipantProxy, 'forget' => true)

    run_definition(pdef)

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout(5) do
        @msg = nil
        MQ.queue('test4', :durable => true).subscribe { |msg| @msg = msg }

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

  it "supports custom messages instead of workitems" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :queue => 'test2', :message => 'foo', :forget => true
        echo 'done.'
      end
    end

    @engine.register_participant(:amqp, RuoteAMQP::ParticipantProxy)

    run_definition(pdef)

    @tracer.to_s.should == "done."

    begin
      Timeout::timeout(5) do
        @msg = nil
        MQ.queue('test2', :durable => true).subscribe { |msg| @msg = msg }

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

  it "supports 'queue' as a participant option" do

    pdef = ::Ruote.process_definition :name => 'test' do
      sequence do
        amqp :forget => true
        echo 'done.'
      end
    end

    @engine.register_participant(
      :amqp, RuoteAMQP::ParticipantProxy, 'queue' => 'test5')

    run_definition(pdef)

    @tracer.to_s.should == 'done.'

    begin
      Timeout::timeout(5) do
        @msg = nil
        MQ.queue('test5', :durable => true).subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end
  end

  it "passes 'participant_options' over amqp" do

    pdef = ::Ruote.process_definition :name => 'test' do
      amqp :queue => 'test6', :forget => true
    end

    @engine.register_participant(:amqp, RuoteAMQP::ParticipantProxy)

    run_definition(pdef)

    msg = nil

    begin
      Timeout::timeout(10) do

        MQ.queue('test6', :durable => true).subscribe { |m| msg = m }

        loop do
          break unless msg.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    wi = Rufus::Json.decode(msg)
    params = wi['fields']['params']

    params['queue'].should == 'test6'
    params['forget'].should == true
    params['participant_options'].should == { 'forget' => false, 'queue' => nil }
  end

  it "doesn't create 1 queue instance per delivery" do

    pdef = ::Ruote.process_definition do
      amqp :queue => 'test7', :forget => true
    end

    mq_count = 0
    ObjectSpace.each_object(MQ) { |o| mq_count += 1 }

    @engine.register_participant(:amqp, RuoteAMQP::ParticipantProxy)

    10.times do
      run_definition(pdef)
    end

    sleep 1

    count = 0
    ObjectSpace.each_object(MQ) { |o| count += 1 }

    count.should == mq_count + 1
  end
end

