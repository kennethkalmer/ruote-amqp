require File.dirname(__FILE__) + '/ruote_example_group.rb'
require File.dirname(__FILE__) + '/ruote_matchers.rb'
require File.dirname(__FILE__) + '/ruote_helpers.rb'

Spec::Example::ExampleGroupFactory.register(:ruote, Spec::Ruote::Example::RuoteExampleGroup)
