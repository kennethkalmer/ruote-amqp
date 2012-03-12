
require File.expand_path('../spec_helper', __FILE__)


describe Ruote::Amqp::AlertParticipant do

  before(:all) do
    start_em
  end

  before(:each) do
    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
  end

  after(:each) do
    @dashboard.shutdown
  end

  it 'lets the flow resume upon receiving a message' do

    @dashboard.register(
      :snare,
      Ruote::Amqp::AlertParticipant,
      :queue => 'x')

    pdef = Ruote.define do
      snare
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    exchange = AMQP::Exchange.new(AMQP::Channel.new, :direct, '')
    exchange.publish('nada', :routing_key => 'x')

    r = @dashboard.wait_for(wfid)

    r['action'].should == 'terminated'

    r['workitem']['fields'].should == {
      'amqp_message' => [
        {
          'content_type' => 'application/octet-stream',
          'priority' => 0,
          'delivery_mode' => 1
        },
        'nada'
      ]
    }
  end
end

