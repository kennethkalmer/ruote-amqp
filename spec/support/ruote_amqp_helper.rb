
module RuoteAmqpHelper

  def ensure_em_is_running

    unless @em
      @em = Thread.new { EM.run {} }
      sleep 0.5
    end
  end

  def count_amqp_objects

    objects = {}

    ObjectSpace.each_object do |o|

      next unless [
        AMQP::Queue, AMQP::Channel, AMQP::Exchange
      ].include?(o.class)

      k = o.class.to_s

      objects[k] ||= 0
      objects[k] = objects[k] + 1
    end

    objects
  end

  def display_amqp_object_count

    objects = count_amqp_objects

    objects.keys.sort.each do |k|
      puts "#{k}: #{objects[k]}"
    end
  end
end

