
require File.expand_path('../spec_helper', __FILE__)


describe Ruote::Amqp::Participant do

  before(:each) do
    @em = Thread.new { EM.run {} }
    sleep 1.0
    AMQP.connect
    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
  end

  after(:each) do
    @dashboard.shutdown
    AMQP.stop
    @em.terminate
  end

  it 'publishes messages on the given exchange' do

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => 'direct/',
      :routing_key => 'toto',
      :forget => true)

    wi = nil

    AMQP::Channel.new.queue('toto').subscribe do |headers, payload|
      wi = Rufus::Json.decode(payload)
    end

    pdef = Ruote.define do
      toto
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.1

    wi['participant_name'].should == 'toto'
  end

  it 'supports custom messages when publishing' do

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => 'direct/',
      :routing_key => 'toto',
      :message => 'hello world!',
      :forget => true)

    msg = nil

    #AMQP::Channel.new.queue('toto').subscribe do |headers, payload|
    AMQP::Channel.new.queue('toto').subscribe do |payload|
      msg = payload
    end

    pdef = Ruote.define do
      toto
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.1

    msg.should == 'hello world!'
  end
end

