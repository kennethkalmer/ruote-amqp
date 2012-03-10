
module RuoteAmqpHelper

  def start_em

    unless @em
      @em = Thread.new { EM.run {} }
      sleep 0.5
    end
  end
end
