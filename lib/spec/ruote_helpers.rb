
module RuoteSpecHelpers

  def purge_engine

    #@engine.context.values.each do |s|
    #  s.purge if s.respond_to?(:purge)
    #end
  end

  def run_definition( pdef )

    wfid = @engine.launch( pdef )

    @engine.wait_for( wfid )

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    purge_engine
  end

  def noisy( on = true )
    @engine.context.logger.noisy = on
  end
end

