
RSpec::Matchers.define :have_errors do |*args|

  match do |engine|

    @ps = if wfid = args.shift
      engine.processes(wfid)
    else
      engine.processes.first
    end

    @ps ? (@ps.errors.size != 0) : false
  end

  failure_message_for_should do |engine|

    "Expected engine to have errors, but didn't"
  end

  failure_message_for_should_not do |engine|

    "Expected the engine to not have errors, but it did.\n" +
    @ps.errors.map { |e| "  * error: #{e.message}\n\"#{e.trace}\"" }.join("\n")
  end

  description do
  end
end

RSpec::Matchers.define :have_remaining_expressions do

  match do |engine|

    (engine.storage.get_many('expressions').size != 0)
  end

  failure_message_for_should do |engine|

    "Expected engine to have processes remaining, but it didn't"
  end

  failure_message_for_should_not do |engine|

    "Expected engine to have no processes remaining, but it did." +
    "#{engine.storage.get_many('expressions').inspect}"
  end

  description do
  end
end

