
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
  end

  after(:each) do

    @dashboard.shutdown
    @queue.delete
  end

  it 'grabs workitems from a queue' do

    receiver = Ruote::Amqp::Receiver.new(@dashboard, @queue)

    pdef = Ruote.define do
      toto
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    r['action'].should == 'terminated'
  end
end

