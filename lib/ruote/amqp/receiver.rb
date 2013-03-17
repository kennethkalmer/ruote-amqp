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
  # A receiver is plugged between a ruote engine/storage and an AMQP queue.
  # It will listen on the queue for messages, try to turn them into
  # workitems and feed those workitem back to the engine/storage (in the usual
  # use case, those workitems were initially emitted by the engine).
  #
  # == #decode_message(headers, payload)
  #
  # By default, the receiver expects the incoming workitem to be serialized
  # entirely in the payload of the AMQP message. One can change this
  # behaviour by overriding the #decode_workitem method (usually when
  # subclassing)
  #
  #   class MyYamlReceiver < Ruote::Amqp::Receiver
  #     def decode_message(headers, payload)
  #       YAML.load(payload)
  #     end
  #   end
  #
  # #decode_message is supposed to return a Ruby hash (describing either a
  # workitem or a launchitem), the difference is explained below.
  #
  # === workitems and launchitems
  #
  # The standard use case is to accept workitems coming back (they probably
  # left the engine via Ruote::Amqp::Participant). But it's also OK
  # to accept "launchitems", hashes with at least one 'process_definition'
  # (or 'definition') entry.
  #
  # Upon receiving a launchitem, the receiver will launch a new process
  # instances.
  #
  # Launchitems may have two more optional entries, 'workitems_fields' (or
  # 'fields') and 'process_variables' (or 'variables').
  #
  # 'workitem_fields' must contain a hash of initial workitem fields (they will
  # populate the initial workitem.
  #
  # 'process_variables' are a very advanced option. It's possible to set the
  # initial variables in a workflow. Read the general ruote documentation to
  # learn about the difference between fields and variables.
  #
  # The #decode_message is supposed to return a hash representing either a
  # workitem, either a launchitem.
  #
  # == #handle_error(err)
  #
  # Out of the box, the receiver will print out to $stderr the details of
  # errors it encounters when receiving, decoding and handing back the
  # workitems (messages?) to the engine. This can be changed by overriding
  # the #handle_error method:
  #
  #   class MyReceiver < Ruote::Amqp::Receiver
  #     def handle_error(err)
  #       ThatLoggerService.log(err)
  #     end
  #   end
  #
  #
  # == initialization options
  #
  # One can set the "launch_only" option to true when initializing the receiver
  # to prevent it from handling anything but launchitems.
  #
  #   receiver = Ruote::Amqp::Receiver.new(
  #     @dashboard, @amqp_queue, :launch_only => true)
  #
  # 'launch_only' (string) is valid too.
  #
  class Receiver < Ruote::Receiver

    attr_reader :queue

    def initialize(engine_or_storage, queue, options={})

      super(engine_or_storage, Ruote.keys_to_s(options))

      @queue = queue
      @queue.subscribe(&method(:handle))
    end

    def shutdown

      @queue.unsubscribe
    end

    protected

    def handle(header, payload)

      item = decode_message(header, payload)

      if item['error'] && item['fei']
        flunk(item)
      elsif item['fields'] && item['fei']
        receive(item)
      elsif item['process_definition'] || item['definition']
        launch(item)
      else
        raise ArgumentError.new("cannot receive or launch #{item.inspect}")
      end

    rescue => e
      handle_error(e)
    end

    def decode_message(header, payload)

      Rufus::Json.decode(payload)
    end

    def handle_error(err)

      $stderr.puts '**err**'
      $stderr.puts err.inspect
      $stderr.puts err.backtrace
    end

    def flunk(h)

      return if @options['launch_only']

      err = h.delete('error')

      args =
        case err
          when String
            [ RemoteError, err ]
          when Hash
            as = [ Ruote.constantize(err['class']), err['message'] ]
            as << err['trace'] if err['trace']
            as
          else
            [ RemoteError, err.inspect ]
        end

      super(h, *args)
    end

    def receive(h)

      return if @options['launch_only']

      super(h)
    end

    def launch(h)

      super(
        h['process_definition'] || h['definition'],
        h['workitem_fields'] || h['fields'] || {},
        h['process_variables'] || h['variables'] || {})
    end
  end

  #
  # Used to wrap errors that come as string (well, errors that don't come
  # with a class name). Could be thought of as "anonymous remote error".
  #
  class RemoteError < StandardError; end
end

