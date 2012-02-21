#--
# Copyright (c) 2010-2012, Kenneth Kalmer, John Mettraux.
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


module Ruote
module Amqp

  #
  # This participant publishes messages on AMQP exchanges.
  #
  # == options
  #
  # A few options are supported. They can be declared at 3 levels:
  #
  # * options (when the participant is registered)
  #
  #   dashboard.register 'amqp_participant', :routing_key => 'nada.x'
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
  # The levels are "params", "fields", "options". When the option 'field_prefix'
  # is set, the level "fields" is set implicitely.
  #
  # The order in which the levels are given is the order in which they
  # are investigated for values.
  #
  # === 'connection'
  # === 'exchange'
  # === 'field_prefix'
  # === 'forget'
  # === 'routing_key'
  # === 'message'
  #
  # === 'persistent'
  #
  # If this option is set to something else than false or nil, messages
  # messages published by this participant will be persistent (hopefully
  # the queues they'll end up in will be persistent as well).
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

      exchange.publish(
        opt('message') || encode_workitem,
        :routing_key => opt('routing_key'),
        :persistent => opt('persistent'))

      reply if opt('forget')
    end

    protected

    def encode_workitem

      workitem.as_json
    end

    def exchange

      con = AMQP.connect(opt('connection') || {})
      cha = AMQP::Channel.new(con)

      exn, exo = Array(opt('exchange')) || [ 'direct/', {} ]
        #
        # defaults to the "default exchange"...

      m = exn.match(/^([a-z]+)\/(.*)$/)

      raise ArgumentError.new(
        "couldn't determine exchange from #{ex.inspect}"
      ) unless m

      AMQP::Exchange.new(cha, m[1].to_sym, m[2], exo || {})
    end

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
end

