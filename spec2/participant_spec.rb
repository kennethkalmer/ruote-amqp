
require File.expand_path('../spec_helper', __FILE__)


describe Ruote::Amqp::Participant do

  before(:all) do
    unless @em
      @em = Thread.new { EM.run {} }
      sleep 0.5
    end
  end

  before(:each) do
    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
  end

  after(:each) do
    @dashboard.shutdown
  end

  it 'publishes messages on the given exchange' do

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => 'direct/',
      :routing_key => 'toto',
      :forget => true)

    wi = nil

    AMQP::Channel.new.queue('toto').subscribe do |h, p|
      wi = Rufus::Json.decode(p)
    end

    pdef = Ruote.define do
      toto
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.1

    wi['participant_name'].should == 'toto'
  end

  it 'supports the :message option' do

    @dashboard.register(
      :alpha,
      Ruote::Amqp::Participant,
      :exchange => 'direct/',
      :routing_key => 'alpha',
      :message => 'hello world!',
      :forget => true)

    msg = nil

    AMQP::Channel.new.queue('alpha').subscribe do |h, p|
      msg = p
    end

    pdef = Ruote.define do
      alpha
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.1

    msg.should == 'hello world!'
  end
end

