
# ruote-amqp

ruote-amqp is a set of classes that let a ruote engine publish and/or receive messages over AMQP.

The most common use case is publishing workitems for processing by AMQP consumers and eventually receiving them back to resume the flow.

Another use case would be to listen on an AMQP queue for workflow launch requests.

Listening for arbitrary AMQP messages before resuming a flow (ambush/alert) is also possible.


## usage

### Ruote::Amqp::Participant

Publishing messages

```ruby
$dashboard.register(
  :toto,
  Ruote::Amqp::Participant,
  :exchange => [ 'direct', '' ],
  :routing_key => 'alpha')

pdef = Ruote.define do
  toto
end

$dashboard.launch(pdef)

# ...
```

### Ruote::Amqp::AlertParticipant

Ambushing messages from a process definition. The alert participant when
receiving a workitem starts waiting for the next message on a given queue. When
the message arrives, it responds to the engine (with a

```ruby
$dashboard.register(
  :wait_for_info,
  Ruote::Amqp::AlertParticipant,
  :queue => 'info')

pdef = Ruote.define do
  # ... before
  wait_for_job # flows wait for first message on 'info' queue
  # ... after
end
```

By default it waits for 1 message that it places in the "amqp_message" field
of the workitem going back to the engine.

One can override the #handle method to change the way the workitem is modified
according to the message.

It's also OK to override the #on_workitem method of this participant if one
waits to wait for more than 1 message.

See the AlertParticipant rdoc for more.

### Ruote::Amqp::Receiver

Receiving messages.

A receiver is a ruote service subscribed to a queue. When a message comes on
the queue, the receiver will look at it and, according to the payload, either
launch a new workflow instance, resume a currently workflow instance segment
or pass an error back from a participant to the engine.

(In fact the resume workflow / pass participant error back to the engine are
closely related)

(NTS: at some point, receivers should be able to deal with "cancel messages")

```ruby
# A simple coupling between participant "toto" and a receiver via AMQP
#
# A real world example would have toto publishing somewhere, the message
# getting fetched by the real (remote) participant and then handed back
# on the queue the receiver is subscribed to.

$dashboard.register(
  :toto,
  Ruote::Amqp::Participant,
  :exchange => [ 'direct', '' ],
  :routing_key => 'alpha')

receiver = Ruote::Amqp::Receiver.new(
  $dashboard, AMQP::Channel.new.queue('alpha'))

# ...
```

### Controlling the connection (AMQP session)

The Ruote::Amqp module has a handy singleton for connections (actually
AMQP::Session instances).

```ruby
# (before registering participants)

Ruote::Amqp.session = AMQP.connect(:auto_recovery => true) do |con|
  con.on_recovery do |con|
    puts "Recovered..."
  end
  connection.on_tcp_connection_loss do |con, settings|
    puts "Reconnecting... please wait"
    conn.reconnect(false, 20)
  end
end
```

When a participant tries to connect to AMQP, it will automatically use the value in Ruote::Amqp.session (else it will set up a new connection).

The receivers expect a queue when they are set up, feel free to set Ruote::Amqp.session, then use it when instantiating receivers (the participant will follow suit).

If you want a different way of connecting to AMQP for the participants, you can override their #amqp_connect methods (or pass them AMQP connection settings when registering them).


## requirements

* ruote[http://ruote.rubyforge.org] 2.3.0 or later
* amqp[http://rubyamqp.info/] 0.9.0 or later
* rabbitmq[http://www.rabbitmq.com/] 2.2.0 or later


## install

Please be sure to have read the requirements section above

    gem install ruote-amqp

or via your Gemfile (thanks [bundler](http://gembundler.com)).


## tests / specs

To run the tests you need the following requirements met, or the testing environment will fail horribly (or simply get stuck without output).


### RabbitMQ vhost

The tests use dedicated vhost on a running AMQP broker. To configure RabbitMQ
you can run the following commands (the RabbitMQ server must be running):

    $ rabbitmqctl add_vhost ruote-test
    $ rabbitmqctl add_user ruote ruote
    $ rabbitmqctl set_permissions -p ruote-test ruote '.*' '.*' '.*'

or by running:

    $ rake prepare


If you need to change the AMQP configuration used by the tests, edit the
+spec/spec_helper.rb+ file.


## daemon-kit

Kenneth Kalmer, the original author of the ruote-amqp gem is also the author of [DaemonKit](https://github.com/kennethkalmer/daemon-kit) a library/toolbox for building daemons.

It used to be the preferred way to wrap remote participants (as daemons) but lately Kenneth hasn't had much time for support. It's still full of excellent ideas.


## license

MIT, see LICENSE.txt

