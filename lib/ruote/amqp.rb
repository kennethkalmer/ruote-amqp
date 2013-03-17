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

require 'amqp'
require 'ruote'

require 'ruote/amqp/participant'
require 'ruote/amqp/alert_participant'
require 'ruote/amqp/receiver'


module Ruote::Amqp

  # Returns the AMQP::Session shared by the ruote participants (and potentially
  # the receivers too).
  #
  # Returns nil if none is set (the participant will mostly create a connection
  # on their own).
  #
  # See http://rubydoc.info/github/ruby-amqp/amqp/master/AMQP/Session
  #
  def self.session

    @session
  end

  # Sets the AMQP::Session shared by the ruote participants (and potentially
  # the receivers too).
  #
  #   Ruote::Amqp.session = AMQP.connect(:auto_recovery => true) do |con|
  #     con.on_recovery do |con|
  #       puts "Recovered..."
  #     end
  #     connection.on_tcp_connection_loss do |con, settings|
  #       puts "Reconnecting... please wait"
  #       conn.reconnect(false, 20)
  #     end
  #   end
  #
  # (Thanks Jim Li - https://github.com/marsbomber/ruote-amqp/commit/0f36a41f)
  #
  # See http://rubydoc.info/github/ruby-amqp/amqp/master/AMQP/Session
  #
  def self.session=(s)

    @session = s
  end
end

