
module RuoteAMQP

  #
  # Got replaced by RuoteAMQP::Receiver
  #
  # This class is kept for backward compatibility.
  #
  class LaunchitemListener < ::RuoteAMQP::Receiver

    # Start a new LaunchItem listener
    #
    # @param [ Ruote::Engine, Ruote::Storage ] A configured ruote engine or storage instance
    # @param [ String ] Optional queue name
    #
    def initialize( engine_or_storage, queue = nil )

      super( engine_or_storage, :queue => queue, :launchitems => :only )
    end
  end
end

