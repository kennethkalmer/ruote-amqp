
module RuoteAMQP

  #
  # Got replaced by RuoteAMQP::Receiver
  #
  # This class is kept for backward compatibility.
  #
  class WorkitemListener < ::RuoteAMQP::Receiver

    # Starts a new WorkitemListener
    #
    # @param [ Ruote::Engine, Ruote::Storage ] A configured ruote engine or storage instance
    # @param [ String ] An optional queue name
    #
    def initialize( engine_or_storage, queue = nil )

      super( engine_or_storage, :queue => queue )
    end
  end
end

