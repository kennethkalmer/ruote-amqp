
# ruote-amqp

* http://github.com/kennethkalmer/ruote-amqp
* http://rdoc.info/projects/kennethkalmer/ruote-amqp
* http://ruote.rubyforge.org


## description

ruote-amqp provides an AMQP participant/listener pair that allows you to
distribute workitems out to AMQP consumers for processing, as well as launching
processes over AMQP.

To learn more about remote participants in ruote please see
http://ruote.rubyforge.org/part_implementations.html


## features/problems

* Flexible participant for sending workitems
* Flexible receiver for receiving replies
* Flexible launch item listener for launching processes over AMQP
* Fully evented (thanks to the amqp gem)


## synopsis

Please review the rdoc in RuoteAMQP::Participant and Ruote::AMQP::Listener


## requirements

* ruote[http://ruote.rubyforge.org] 2.3.0 or later
* amqp[http://github.com/tmm1/amqp] 0.9.0 or later
* rabbitmq[http://www.rabbitmq.com/] 2.2.0 or later


## install

Please be sure to have read the requirements section above

    gem install ruote-amqp

or via your Gemfile.


## tests

To run the tests you need the following requirements met, or the testing environment will fail horribly (or simply get stuck without output).


### RabbitMQ vhost

The tests use dedicated vhost on a running AMQP broker. To configure RabbitMQ
you can run the following commands:

  # rabbitmqctl add_vhost ruote-test
  # rabbitmqctl add_user ruote ruote
  # rabbitmqctl set_permissions -p ruote-test ruote '.*' '.*' '.*'

If you need to change the AMQP configuration used by the tests, edit the
+spec/spec_helper.rb+ file.


## daemon-kit

Although the RuoteAMQP gem will work perfectly well with any AMQP consumer,
it is recommended that you use daemon-kit[http://github.com/kennethkalmer/daemon-kit] to write your remote participants.

daemon-kit offers plenty of convenience for remote participants and includes
a code generator for ruote remote participants.

DaemonKit doesn't currently support ruote 2.1, support is forthcoming.


## license

MIT, see LICENSE.txt

