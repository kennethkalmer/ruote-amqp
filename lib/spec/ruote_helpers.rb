module RuoteSpecHelpers

  def purge_engine
    @engine.application_context.values.each do |s|
      s.purge if s.respond_to?(:purge)
    end
  end

  def run_definition( pdef )
    fei = @engine.launch( pdef )
    wait( fei )

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    purge_engine
  end

  def wait( fei )
    Thread.pass
    return if @terminated_processes.include?( fei.wfid )
    @engine.wait_for( fei )
  end
end
