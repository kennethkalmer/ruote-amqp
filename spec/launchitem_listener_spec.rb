
require File.join(File.dirname(__FILE__), 'spec_helper')

#
# NOTE : RuoteAMQP::LaunchitemListener has been depreacted in favour of
#        RuoteAMQP::Receiver
#

describe RuoteAMQP::LaunchitemListener do

  after(:each) do
    purge_engine
  end

  it 'launches processes' do

    json = {
      'definition' => %{
        Ruote.process_definition :name => 'test' do
          sequence do
            echo '${f:foo}'
          end
        end
      },
      'fields' => { 'foo' => 'bar' }
    }.to_json

    RuoteAMQP::LaunchitemListener.new(@engine)

    MQ.queue('ruote_launchitems').publish(json)

    sleep 0.5

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == 'bar'
  end
end

