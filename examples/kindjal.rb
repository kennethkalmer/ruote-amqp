
# this example comes under the same license as the rest of ruote-amqp

## a potential Gemfile for running this example:
#
# source :rubygems
#
# gem 'yajl-ruby', :require => 'yajl'
# gem 'ruote', :git => 'git://github.com/jmettraux/ruote.git'
# gem 'ruote-amqp', :git => 'git://github.com/kennethkalmer/ruote-amqp.git'

require 'rufus-json/automatic'
require 'ruote'
require 'ruote-amqp'

$em = Thread.new { EM.run {} }
sleep 0.5

$dboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
$dboard.noisy = ENV['NOISY'] == 'true'

$dboard.register(
  :toto,
  Ruote::Amqp::Participant,
  :exchange => [ 'direct', '' ],
  :routing_key => 'kindjal-test-0')

$receiver = Ruote::Amqp::Receiver.new(
  $dboard, AMQP::Channel.new.queue('kindjal-test-0'))

pdef = Ruote.define do
  toto
end

$dboard.launch(pdef)
$dboard.wait_for('terminated')

