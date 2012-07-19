
module RuoteSpecHelpers

  def purge_engine

    # TODO : adapt to ruote 2.1.10
  end

  def run_definition(pdef)

    wfid = @engine.launch(pdef)

    #r = @engine.wait_for(wfid)
    #@engine.wait_for(wfid) if r['action'] == 'ceased'
    #  # make sure to wait for 'terminated'
    @engine.wait_for(:inactive)

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    purge_engine
  end

  def noisy(on = true)

    @engine.context.logger.noisy = on
  end
end

