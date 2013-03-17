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
  # The alert participant, when invoked from a process instance will
  # lay in wait for the next message on a given queue. As soon as the message
  # comes in, it will pack it in the workitem fields and let the process
  # definition resume.
  #
  #   @dashboard.register(
  #     :wait_for_info,
  #     Ruote::Amqp::AlertParticipant,
  #     :queue => 'info')
  #
  #   pdef = Ruote.define do
  #     wait_for_job
  #     # ... the rest of the flow
  #   end
  #
  # == configuration
  #
  # This class is mostly a subclass of Ruote::Amqp::Participant, it accepts
  # the same configuration options (but has no need for 'exchange'). It
  # accepts a 'queue' option in the form [ 'queue_name', { queue options } ].
  #
  #
  # == overriding #handle(header, payload)
  #
  # The default implementation for this method is:
  #
  #   def handle(header, payload)
  #     workitem.fields['amqp_message'] = [ header.to_hash, payload ]
  #   end
  #
  # One is free to override it:
  #
  #   class MyAlertParticipant < Ruote::Amqp::AlertParticipant
  #     def handle(header, payload)
  #       fields = Rufus::Json.decode(payload)
  #       workitem.fields.merge!(fields)
  #     end
  #   end
  #
  #
  # == overriding #on_workitem
  #
  # Out of the box, the alert participant listens for 1 message on 1 queue.
  # It's not too difficult to change that.
  #
  # Resuming after 3 messages:
  #
  #   class MyAlertParticipant < Ruote::Amqp::AlertParticipant
  #
  #     def on_workitem
  #
  #       messages = []
  #
  #       queue.subscribe { |header, payload |
  #
  #         messages << payload
  #
  #         if messages.size > 2
  #           queue.unsubscribe
  #           workitem.fields['messages'] = messages
  #           reply # let the flow resume
  #         end
  #       }
  #     end
  #   end
  #
  # Observing 2 queues:
  #
  #   class MyAlertParticipant < Ruote::Amqp::AlertParticipant
  #
  #     def on_workitem
  #
  #       messages = []
  #
  #       q0 = channel.queue('zero')
  #       q1 = channel.queue('one')
  #
  #       [ q0, q1 ].subscribe { |header, payload |
  #         messages << payload
  #       }
  #
  #       sleep 1.0 while messages.size < 2
  #
  #       reply # let the flow resume
  #     end
  #   end
  #
  class AlertParticipant < Participant

    def on_workitem

      queue.subscribe { |header, payload|

        queue.unsubscribe
        handle(header, payload)
        reply
      }
    end

    protected

    # Called when the AMQP message comes in. This default implementation
    # stuffs the AMQP [ header, payload ] into an 'amqp_message' workitem
    # field.
    #
    def handle(header, payload)

      workitem.fields['amqp_message'] = [ header.to_hash, payload ]
    end

    # Looks at the configuration options ('connection' and 'queue') and
    # returns the queue the participant will fetch a message from.
    #
    def queue

      @queue ||= channel.queue(*(opt('queue') || [ '' ]))
    end
  end
end

