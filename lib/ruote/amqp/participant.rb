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
  # == options
  #
  # === conf
  # === connection
  # === exchange
  # === field_prefix
  # === forget
  # === routing_key
  # === message
  #
  class Participant
    include Ruote::LocalParticipant

    def initialize(options)

      @options = options

      @conf = (@options['conf'] || 'options').split(/\s*,\s*/)
      @conf = %w[ params fields options ] if @conf.include?('all')
      @conf = @conf.inject({}) { |h, e| h[e] = true; h }
      @conf['fields'] = true if @options['field_prefix']

      @field_prefix = @options['field_prefix'] || ''
    end

    def on_workitem

      exchange.publish(
        encode_workitem, :routing_key => opt('routing_key'))

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

    def opt(key, default=nil, &default_block)

      (@conf['params'] ? workitem.params[key] : nil) ||
      (@conf['fields'] ? workitem.fields[@field_prefix + key] : nil) ||
      (@conf['options'] ? @options[key] : nil)
    end
  end
end
end

