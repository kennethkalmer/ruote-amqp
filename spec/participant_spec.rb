
require 'spec_helper'


describe Ruote::Amqp::Participant do

  before(:all) do

    ensure_em_is_running
  end

  before(:each) do

    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))

    @dashboard.noisy = ENV['NOISY'].to_s == 'true'
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

    sleep 0.1

    pdef = Ruote.define do
      toto
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    r['action'].should == 'terminated'

    sleep 0.350

    wi['participant_name'].should == 'toto'
  end

  it 'blocks if :forget is not set to true' do

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha')

    wi = nil

    @queue = AMQP::Channel.new.queue('alpha')
    @queue.subscribe { |headers, payload| wi = Rufus::Json.decode(payload) }

    sleep 0.1

    pdef = Ruote.define do
      toto
    end

    wfid = @dashboard.launch(pdef, 'customer' => 'taira no kiyomori')
    @dashboard.wait_for('dispatched')

    sleep 0.1

    wi['fields']['customer'].should == 'taira no kiyomori'

    @dashboard.ps(wfid).expressions.size.should == 2
  end

  it 'supports :forget as a participant attribute' do

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha')

    wi = nil

    @queue = AMQP::Channel.new.queue('alpha')
    @queue.subscribe { |headers, payload| wi = Rufus::Json.decode(payload) }

    pdef = Ruote.define do
      toto :forget => true
    end

    wfid = @dashboard.launch(pdef, 'customer' => 'minamoto no yoshitomo')
    r = @dashboard.wait_for(wfid)

    r['action'].should == 'terminated'

    sleep 0.1

    wi['fields']['customer'].should == 'minamoto no yoshitomo'
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

    sleep 0.1

    pdef = Ruote.define do
      alpha
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.1

    msg.should == 'hello world!'
  end

  it 'publishes messages with the given correlation-id' do

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha',
      :correlation_id => 'beta',
      :forget => true)

    correlation_id = nil

    @queue = AMQP::Channel.new.queue('alpha')
    @queue.subscribe { |headers, payload| correlation_id = headers.correlation_id }

    sleep 0.1

    pdef = Ruote.define do
      toto
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.1

    correlation_id.should == 'beta'
  end

  it 'reuses channels and exchanges within a thread' do

    @dashboard.register(
      :alpha,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha',
      :message => 'hello world!',
      :forget => true)

    c0 = count_amqp_objects

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

  context 'cancelitems' do

    it 'publishes "cancelitems"' do

      @dashboard.register(
        :toto,
        Ruote::Amqp::Participant,
        :exchange => [ 'direct', '' ],
        :routing_key => 'alpha')

      msgs = []

      @queue = AMQP::Channel.new.queue('alpha')
      @queue.subscribe { |headers, payload| msgs << [ headers, payload ] }

      pdef = Ruote.define do
        toto
      end

      wfid = @dashboard.launch(pdef)
      @dashboard.wait_for('dispatched')

      sleep 0.1

      @dashboard.cancel(wfid)

      sleep 0.1

      msgs.size.should == 2

      items = msgs.collect { |msg| Rufus::Json.decode(msg.last) }

      items.first['participant_name'].should == 'toto'

      items.last.keys.sort.should == %w[ cancel fei flavour ]
      items.last['cancel'].should == true
      items.last['fei']['wfid'].should == wfid
      items.last['flavour'].should == nil
    end

    it "doesn't publish \"cancelitems\" if 'discard_cancel' => true" do

      @dashboard.register(
        :toto,
        Ruote::Amqp::Participant,
        :exchange => [ 'direct', '' ],
        :routing_key => 'alpha',
        :discard_cancel => true)

      msgs = []

      @queue = AMQP::Channel.new.queue('alpha')
      @queue.subscribe { |headers, payload| msgs << [ headers, payload ] }

      pdef = Ruote.define do
        toto
      end

      wfid = @dashboard.launch(pdef)
      @dashboard.wait_for('dispatched')

      sleep 0.1

      @dashboard.cancel(wfid)

      sleep 0.1

      msgs.size.should == 1
    end
  end

  context 'Ruote::Amqp.session' do

    after(:each) do

      Ruote::Amqp.session = nil
    end

    it 'uses Ruote::Amqp.session if set for connecting to AMQP' do

      Ruote::Amqp.session = 'fail!'

      @dashboard.register(
        :toto,
        Ruote::Amqp::Participant,
        :exchange => [ 'direct', '' ],
        :routing_key => 'alpha',
        :forget => true)

      pdef = Ruote.define do
        toto
      end

      wfid = @dashboard.launch(pdef)
      r = @dashboard.wait_for(wfid)

      r['action'].should == 'error_intercepted'

      r['error']['class'].should ==
        'NoMethodError'
      r['error']['message'].should ==
        "undefined method `auto_recovering?' for \"fail!\":String"
    end

    it "doesn't use Ruote::Amqp.session if a 'connection' option is given" do

      Ruote::Amqp.session = 'do fail now!'

      @dashboard.register(
        :toto,
        Ruote::Amqp::Participant,
        :exchange => [ 'direct', '' ],
        :routing_key => 'alpha',
        :forget => true,
        :connection => {})

      wi = nil

      @queue = AMQP::Channel.new.queue('alpha')
      @queue.subscribe { |headers, payload| wi = Rufus::Json.decode(payload) }

      sleep 0.1

      pdef = Ruote.define do
        toto
      end

      wfid = @dashboard.launch(pdef)
      r = @dashboard.wait_for(wfid)
      sleep 0.1

      r['action'].should == 'terminated'
      wi['participant_name'].should == 'toto'
    end
  end
end

