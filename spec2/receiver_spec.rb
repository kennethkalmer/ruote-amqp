
require File.expand_path('../spec_helper', __FILE__)


describe Ruote::Amqp::Receiver do

  before(:all) do

    start_em
  end

  before(:each) do

    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha')

    @queue = AMQP::Channel.new.queue('alpha')
    @receiver = Ruote::Amqp::Receiver.new(@dashboard, @queue)
  end

  after(:each) do

    @dashboard.shutdown
    @queue.delete
  end

  it 'grabs workitems from a queue' do

    pdef = Ruote.define do
      toto
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    r['action'].should == 'terminated'
  end

  pending 'offers a hook for errors' do

    $errs = []

    def @receiver.handle_error(e)
      $errs << e
    end

    exchange = AMQP::Exchange.new(AMQP::Channel.new, :direct, '')
    exchange.publish('nada', :routing_key => 'alpha')

    sleep 0.300

    $errs.size.should == 1
  end
end

