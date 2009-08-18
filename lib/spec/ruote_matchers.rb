
Spec::Matchers.define :have_errors do |*args|

  match do |engine|

    @ps = if wfid = args.shift
      engine.processes( wfid )
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
    @ps.errors.map { |e|
      "  * error: #{e.error_class} #{e.error_message} " +
      "\n\"#{e.error_backtrace.join("\n")}\""
    }.join("\n")
  end
  description do
    #
  end
end

Spec::Matchers.define :have_remaining_expressions do

  match do |engine|

    (engine.expstorage.size != 0)
  end

  failure_message_for_should do |engine|
    "Expected engine to have processes remaining, but it didn't"
  end
  failure_message_for_should_not do |engine|
    "Expected engine to have no processes remaining, but it did.#{engine.get_expression_storage.to_s}"
  end
  description do
  end
end

