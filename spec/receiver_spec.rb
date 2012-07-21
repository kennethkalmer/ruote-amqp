
require 'spec_helper'


describe Ruote::Amqp::Receiver do

  before(:all) do

    start_em
  end

  before(:each) do

    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))

    @dashboard.noisy = ENV['NOISY']

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

  it 'offers a hook for errors' do

    $errs = []

    def @receiver.handle_error(e)
      $errs << e
    end

    sleep 0.100
      # give some time for the receiver to get ready...

    exchange = AMQP::Exchange.new(AMQP::Channel.new, :direct, '')

    exchange.publish('nada zero', :routing_key => 'alpha')
    exchange.publish('nada one', :routing_key => 'alpha')

    sleep 0.300

    $errs.size.should == 2
  end

  it 'accepts launchitems' do

    @dashboard.register('noop', Ruote::NoOpParticipant)

    #@dashboard.noisy = true

    launchitem = {
      'definition' => Ruote.define { noop },
      'fields' => { 'kilroy' => 'was here' }
    }

    sleep 0.100
      # give some time for the receiver to get ready...

    exchange = AMQP::Exchange.new(AMQP::Channel.new, :direct, '')
    exchange.publish(Rufus::Json.encode(launchitem), :routing_key => 'alpha')

    r = @dashboard.wait_for('terminated')

    r['workitem']['fields']['kilroy'].should == 'was here'
  end
end

