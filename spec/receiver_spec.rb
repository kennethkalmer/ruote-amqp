
require 'spec_helper'


describe Ruote::Amqp::Receiver do

  before(:all) do

    ensure_em_is_running
  end

  before(:each) do

    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))

    @dashboard.noisy = ENV['NOISY'].to_s == 'true'

    @dashboard.register(
      :toto,
      Ruote::Amqp::Participant,
      :exchange => [ 'direct', '' ],
      :routing_key => 'alpha')

    @queue = AMQP::Channel.new.queue('alpha')

    @receiver = Ruote::Amqp::Receiver.new(@dashboard, @queue)
    sleep 0.100 # give some time for the receiver to settle in
  end

  after(:each) do

    @dashboard.shutdown
    @receiver.shutdown

    #@queue.status { |mc, acc| p [ :messages, mc, :active_consumers, acc ] }
    @queue.delete
  end

  context 'with workitems' do

    it 'grabs workitems from a queue' do

      pdef = Ruote.define do
        toto
      end

      wfid = @dashboard.launch(pdef)
      r = @dashboard.wait_for(wfid)

      r['action'].should == 'terminated'
    end

    it 'offers a hook for errors' do

      $errs = []

      def @receiver.handle_error(e)
        $errs << e
      end

      exchange = AMQP::Exchange.new(AMQP::Channel.new, :direct, '')

      exchange.publish('nada zero', :routing_key => 'alpha')
      exchange.publish('nada one', :routing_key => 'alpha')

      sleep 0.300

      $errs.size.should == 2
    end
  end

  context 'with launchitems' do

    it 'accepts launchitems' do

      @dashboard.register('noop', Ruote::NoOpParticipant)

      launchitem = {
        'definition' => Ruote.define { noop },
        'fields' => { 'kilroy' => 'was here' }
      }

      exchange = AMQP::Exchange.new(AMQP::Channel.new, :direct, '')
      exchange.publish(Rufus::Json.encode(launchitem), :routing_key => 'alpha')

      r = @dashboard.wait_for('terminated')

      r['workitem']['fields']['kilroy'].should == 'was here'
    end
  end

  context 'when "launchitem-only" (find better name)' do

    it 'discards workitems'
    it 'discards errors'
  end

  context 'with errors' do

    class ParticipantWithError
      include Ruote::LocalParticipant

      def initialize(options)

        @options = options
      end

      def on_workitem

        wi = workitem.h
        wi['error'] = @options['error']

        exchange = AMQP::Exchange.new(AMQP::Channel.new, :direct, '')
        exchange.publish(Rufus::Json.encode(wi), :routing_key => 'alpha')

        # no replying to the engine
      end

      def on_cancel

        # nothing
      end
    end

    it 'propagates errors passed back as strings' do

      @dashboard.register_participant(
        'alf', ParticipantWithError, 'error' => 'something went wrong')

      wfid = @dashboard.launch(Ruote.define { alf })
      r = @dashboard.wait_for(wfid)

      r['action'].should == 'error_intercepted'

      r['error']['class'].should == 'Ruote::Amqp::RemoteError'
      r['error']['message'].should == 'something went wrong'
    end

    it 'propagates errors passed back as hashes' do

      @dashboard.register_participant(
        'alf',
        ParticipantWithError,
        'error' => {
          'class' => 'ArgumentError', 'message' => 'something missing' })

      wfid = @dashboard.launch(Ruote.define { alf })
      r = @dashboard.wait_for(wfid)

      r['action'].should == 'error_intercepted'

      r['error']['class'].should == 'ArgumentError'
      r['error']['message'].should == 'something missing'
    end

    it 'propagates errors passed back as whatever' do

      @dashboard.register_participant(
        'alf', ParticipantWithError, 'error' => %w[ not good ])

      wfid = @dashboard.launch(Ruote.define { alf })
      r = @dashboard.wait_for(wfid)

      r['action'].should == 'error_intercepted'

      r['error']['class'].should == 'Ruote::Amqp::RemoteError'
      r['error']['message'].should == %w[ not good ].inspect
    end
  end
end

