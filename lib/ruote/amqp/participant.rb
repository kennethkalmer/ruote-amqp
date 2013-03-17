#--
# Copyright (c) 2010-2013, Kenneth Kalmer, John Mettraux.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#++


module Ruote::Amqp

  #
  # This participant publishes messages on AMQP exchanges.
  #
  # == options
  #
  # A few options are supported. They can be declared at 3 levels:
  #
  # * options (when the participant is registered)
  #
  #   dashboard.register(
  #     'amqp_participant',
  #     Ruote::Amqp::Participant,
  #     :routing_key => 'nada.x')
  #
  # * params (from the process definition)
  #
  #   sequence do
  #     amqp_participant :routing_key => 'nada.x'
  #   end
  #
  # * fields (from the passing workitem)
  #
  #   sequence do
  #     set 'f:routing_key' => 'nada.x'
  #     amqp_participant
  #   end
  #
  # The 'conf' option (only available at participant registration) decides
  # which levels are enabled or not.
  #
  # By default 'conf' is set to 'params, fields, options'.
  #
  # === 'conf'
  #
  # As said above, this option decides who can tweak this participant's
  # options. It accepts a comma-separated list of levels.
  #
  # The levels are "params", "fields", "options".
  #
  # The order in which the levels are given is the order in which they
  # are investigated for values.
  #
  # === 'connection'
  #
  # A hash of connection options. This is direcly fed to the amqp gem, the
  # options of that gem apply thus ('host', 'port', 'vhost', 'username' and
  # 'password').
  #
  # If no 'connection' (or :connection) hash is passed, the participant
  # will attempt to use the connection (AMQP::Session) found in
  # Ruote::Amqp.session. If there is nothing in there, it will [attempt] to
  # create a new connection with AMQP's default settings.
  #
  # === 'exchange'
  #
  # Accepts a two or three sized Array.
  #
  # The first element is a string or symbol detailing the exchange type,
  # like :direct, :fanout, :topic, ...
  #
  # The second element is an exchange name.
  #
  # The third, optional, element is a hash of exchange options.
  #
  # There is more information at http://rubyamqp.info/
  #
  # By default, 'exchange' is set to [ 'direct', '' ] (the default exchange).
  #
  # Note: you cannot pass an instantiated Ruby-AMQP exchange here. Ruote
  # cannot serialize it for remote workers, so the settings are passed
  # in a flat form, easily JSONifiable.
  #
  # === 'field_prefix'
  #
  # Sometimes one wants to separate his AMQP participant settings from other
  # workitem fields.
  #
  #   dashboard.register(
  #     'amqp_participant',
  #     Ruote::Amqp::Participant,
  #     :conf => 'fields', :field_prefix => 'amqp_')
  #
  # registers a participant that draws is configuration from workitem fields
  # prefixed with 'amqp_'.
  #
  # Note that setting this option doesn't implicitely add 'fields' to the
  # 'conf' option.
  #
  # === 'forget'
  #
  # When set to true forces the participant to reply to the engine immediately
  # after the message got published, in a "fire and forget" fashion.
  #
  # === 'routing_key'
  #
  # Depending on the exchange used, this option lets you influence how the
  # exchange routes the message towards queues.
  #
  # Consult your AMQP documentation for more information.
  #
  # === 'message'
  #
  # By default, the workitem is turned into a JSON string and transmitted in
  # the AMQP message payload. If this 'message' option is set, its value is
  # used as the payload.
  #
  # === 'persistent'
  #
  # If this option is set to something else than false or nil, messages
  # messages published by this participant will be persistent (hopefully
  # the queues they'll end up in will be persistent as well).
  #
  #
  # == #encode_workitem
  #
  # The default way to encode a workitem before pushing it to the exchange
  # is by turning it entirely into a JSON string.
  #
  # To alter this, one can subclass this participant and provide its own
  # #encode_workitem(wi) method:
  #
  #   require 'yaml'
  #
  #   class MyAmqpParticipant < Ruote::Amqp::Participant
  #
  #     def encode_workitem(workitem)
  #       YAML.dump(workitem)
  #     end
  #   end
  #
  # or when one needs to filter some fields:
  #
  #   class MyAmqpParticipant < Ruote::Amqp::Participant
  #
  #     def encode_workitem(workitem)
  #       workitem.fields.delete_if { |k, v| k.match(/^private_/) }
  #       super(workitem)
  #     end
  #   end
  #
  class Participant
    include Ruote::LocalParticipant

    # Initializing the participant, right before calling #on_workitem or
    # another on_ method.
    #
    def initialize(options)

      @options = options

      @conf = (@options['conf'] || 'params, fields, options').split(/\s*,\s*/)
      @conf = %w[ params fields options ] if @conf.include?('all')

      @field_prefix = @options['field_prefix'] || ''
    end

    # Workitem consumption code.
    #
    def on_workitem

      instantiate_exchange.publish(
        message,
        :routing_key => routing_key,
        :persistent => persistent,
        :correlation_id => correlation_id)

      reply if forget
    end

    def on_cancel

      return if opt('discard_cancel')

      instantiate_exchange.publish(
        encode_cancelitem,
        :routing_key => routing_key,
        :persistent => persistent,
        :correlation_id => correlation_id)
    end

    # No need for a dedicated thread when dispatching messages. Respond
    # true.
    #
    def do_not_thread; true; end

    # Returns the exchange coordinates (a triple [ type, name, options ]).
    # Defaults to the direct exchange.
    #
    # Available as a method so it can be overriden (the return value could
    # depend on the @workitem or other factors).
    #
    def exchange

      opt('exchange') || [ 'direct', '', {} ]
        #
        # defaults to the "default exchange"...
    end

    # Returns the message to publish.
    #
    # Available as a method so it can be overriden (the return value could
    # depend on the @workitem or other factors).
    #
    def message; opt('message') || encode_workitem; end

    # Returns the routing key for the message to publish.
    #
    # Available as a method so it can be overriden (the return value could
    # depend on the @workitem or other factors).
    #
    def routing_key; opt('routing_key'); end

    # Returns whether the publish should be persistent or not.
    #
    # Available as a method so it can be overriden (the return value could
    # depend on the @workitem or other factors).
    #
    def persistent; opt('persistent'); end

    # Returns the correlation_id for the message publication. Returns ''
    # by default.
    #
    # Available as a method so it can be overriden (the return value could
    # depend on the @workitem or other factors).
    #
    def correlation_id

      opt('correlation_id') || ''
    end

    # Returns something true-ish if the participant should not reply to the
    # engine once the publish operation is done.
    #
    # Available as a method so it can be overriden (the return value could
    # depend on the @workitem or other factors).
    #
    def forget; opt('forget'); end

    protected

    # How a workitem is turned into an AMQP message payload (string).
    #
    # Feel free to override this method to accommodate your needs.
    #
    def encode_workitem

      workitem.as_json
    end

    # How a "cancelitem" is turned into an AMQP message payload (string).
    #
    # Feel free to override this method to accommodate your needs.
    #
    def encode_cancelitem

      Rufus::Json.encode(
        'cancel' => true, 'fei' => @fei.h, 'flavour' => @flavour)
    end

    # Default AMQP.connect method.
    #
    # Feel free to override this method to accommodate your needs (See
    # the README for an example).
    #
    def amqp_connect

      ocon = opt('connection')

      if Ruote::Amqp.session && ( ! ocon)
        Ruote::Amqp.session
      else
        AMQP.connect(Ruote.keys_to_sym(ocon || {}))
      end
    end

    # Given connection options passed at registration time (when the
    # participant is registered in ruote) or from the process definition,
    # returns an AMQP::Channel instance.
    #
    def channel

      Thread.current['_ruote_amqp_channel'] ||= AMQP::Channel.new(amqp_connect)
    end

    # Given exchange options passed at registrations time or from the process
    # definition, returns an AMQP::Exchange instance.
    #
    def instantiate_exchange

      Thread.current['_ruote_amqp_exchange'] ||= begin

        exc = exchange
        type, name, options = exc

        raise ArgumentError.new(
          "couldn't determine exchange from #{exc.inspect}"
        ) unless name

        exchange_opts = (options || {}).each_with_object({}) { |(k, v), h|
          h[k.to_sym] = v
        }

        AMQP::Exchange.new(channel, type.to_sym, name, exchange_opts)
      end
    end

    # The mechanism for looking up options like 'connection', 'exchange',
    # 'routing_key' in either the participant options, the process
    # definition or the workitem fields...
    #
    def opt(key)

      @conf.each do |type|

        container = (type == 'options' ? @options : workitem.send(type))
        k = type == 'fields' ? "#{@field_prefix}#{key}" : key

        return container[k] if container.has_key?(k)
      end

      nil
    end
  end
end

