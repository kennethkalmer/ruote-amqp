Spec::Matchers.define :have_errors do |*args|
  match do |engine|
    @ps = if fei = args.shift
      engine.process_status( fei )
    else
      engine.process_statuses.values.first
    end

    if @ps
      @ps.errors.size != 0
    else
      false
    end
  end

  failure_message_for_should do |engine|
    "Expected engine to have errors, but didn't"
  end
  failure_message_for_should_not do |engine|
    "Expected the engine to not have errors, but it did.\n" +
    @ps.errors.values.map do |e|
      "  * error: #{e.error_class} \"#{e.stacktrace}\""
    end.join("\n")
  end
  description do
    #
  end
end

Spec::Matchers.define :have_remaining_expressions do
  match do |engine|
    exp_count = engine.get_expression_storage.size

    if exp_count == 1
      false
    else
      50.times { Thread.pass }
      exp_count = engine.get_expression_storage.size
      if exp_count == 1
        false
      else
        true
      end
    end
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
