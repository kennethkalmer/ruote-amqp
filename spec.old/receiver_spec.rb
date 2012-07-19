
require File.join(File.dirname(__FILE__), 'spec_helper')

require 'ruote/participant'


describe RuoteAMQP::Receiver do

  after(:each) do
    purge_engine
  end

  it "handles replies" do

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'foo', :value => 'foo'
      sequence do
        echo '${f:foo}'
        amqp :queue => 'test3'
        echo '${f:foo}'
      end
    end

    @engine.register_participant(:amqp, RuoteAMQP::ParticipantProxy)

    RuoteAMQP::Receiver.new(@engine)

    wfid = @engine.launch(pdef)

    workitem = nil

    begin
      Timeout::timeout(5) do

        MQ.queue('test3', :durable => true).subscribe { |msg|
          wi = Ruote::Workitem.new(Rufus::Json.decode(msg))
          workitem = wi if wi.wfid == wfid
        }

        loop do
          break unless workitem.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      violated "Timeout waiting for message"
    end

    workitem.fields['foo'] = "bar"

    MQ.queue('ruote_workitems', :durable => true).publish(Rufus::Json.encode(workitem.to_h), :persistent => true)

    @engine.wait_for(wfid)

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "foo\nbar"
  end

  it "launches processes" do

    json = {
      'definition' => %{
        Ruote.process_definition :name => 'test' do
          sequence do
            echo '${f:foo}'
          end
        end
      },
      'fields' => { 'foo' => 'bar' }
    }.to_json

    RuoteAMQP::Receiver.new(@engine, :launchitems => true, :unsubscribe => true)

    MQ.queue(
      'ruote_workitems', :durable => true
    ).publish(
      json, :persistent => true
    )

    sleep 0.5

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == 'bar'
  end

  it 'accepts a custom :queue' do

    #@engine.noisy = true

    RuoteAMQP::Receiver.new(
      @engine, :queue => 'mario', :launchitems => true, :unsubscribe => true)

    @engine.register_participant 'alpha', Ruote::StorageParticipant

    json = Rufus::Json.encode({
      'definition' => "Ruote.define { alpha }"
    })

    MQ.queue(
      'ruote_workitems', :durable => true
    ).publish(
      json, :persistent => true
    )

    sleep 1

    @engine.processes.size.should == 0
      # nothing happened

    MQ.queue(
      'mario', :durable => true
    ).publish(
      json, :persistent => true
    )

    sleep 1

    @engine.processes.size.should == 1
      # launch happened
  end
end

