require File.dirname(__FILE__) + '/spec_helper'

describe RuoteAMQP::LaunchitemListener do

  it "should launch processes" do
    json = {
      "definition" => "
        Ruote.process_definition :name => 'test' do
          sequence do
            echo '${f:foo}'
          end
        end
      ",
      "fields" => {
        "foo" => "bar"
      }
    }.to_json

    @engine.register_listener( RuoteAMQP::LaunchitemListener )

    MQ.queue( RuoteAMQP::LaunchitemListener.queue ).publish( json )

    @engine.context[:s_logger].wait_for([
      [ :processes, :terminated, {} ],
      [ :errors, nil, nil ]
    ])

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "bar"

    purge_engine
  end
end
