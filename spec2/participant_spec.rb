
require File.expand_path('../spec_helper', __FILE__)


describe Ruote::Amqp::Participant do

  before(:all) do
    start_em
  end

  before(:each) do
    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
  end

  after(:each) do
    @dashboard.shutdown
    @queue.delete rescue nil
  end

  it 'publishes messages on the given exchange' do

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha',
      :forget => true)

    wi = nil

    @queue = AMQP::Channel.new.queue('alpha')
    @queue.subscribe { |headers, payload| wi = Rufus::Json.decode(payload) }

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
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha',
      :message => 'hello world!',
      :forget => true)

    msg = nil

    @queue = AMQP::Channel.new.queue('alpha')
    @queue.subscribe { |headers, payload| msg = payload }

    pdef = Ruote.define do
      alpha
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.1

    msg.should == 'hello world!'
  end

  it 'flips burgers' do

    @dashboard.register(
      :alpha,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha',
      :message => 'hello world!',
      :forget => true)

    c0 = count_amqp_objects

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
      concurrence do
        10.times { alpha }
      end
    end)

    @dashboard.wait_for(2 + 3 * 10)

    c1 = count_amqp_objects

    3.times { GC.start }
    sleep 2
      # doesn't change much...

    c2 = count_amqp_objects

    c2.should == c1
    c1['AMQP::Channel'].should == (c0['AMQP::Channel'] || 0) + 1
    c1['AMQP::Exchange'].should == (c0['AMQP::Exchange'] || 0) + 1
  end
end

