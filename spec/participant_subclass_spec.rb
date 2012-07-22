
require 'spec_helper'


describe 'X < Ruote::Amqp::Participant' do

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

  context 'RoutingKeyParticipant' do

    #
    # Sample subclass, simply uses the participant name as the routing_key.
    #
    class RoutingKeyParticipant < Ruote::Amqp::Participant

      def routing_key

        @workitem.participant_name
      end
    end

    it 'sets the routing key to the participant name' do

      @dashboard.register(
        /.+/, RoutingKeyParticipant, :forget => true)

      wi = nil

      @queue = AMQP::Channel.new.queue('alpha')
      @queue.subscribe { |headers, payload| wi = Rufus::Json.decode(payload) }

      sleep 0.1

      pdef = Ruote.define do
        alpha
      end

      wfid = @dashboard.launch(pdef, 'customer' => 'goshirakawa')
      r = @dashboard.wait_for(wfid)

      r['action'].should == 'terminated'

      sleep 0.1

      wi['participant_name'].should == 'alpha'
      wi['fields']['customer'].should == 'goshirakawa'
    end
  end
end

