
module RuoteSpecHelpers

  def purge_engine

    @engine.context.values.each do |s|
      s.purge if s.respond_to?(:purge)
    end
  end

  def run_definition( pdef )

    wfid = @engine.launch( pdef )

    @engine.context[:s_logger].wait_for([
      [ :processes, :terminated, { :wfid => wfid } ],
      [ :errors, nil, { :wfid => wfid } ]
    ])

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    purge_engine
  end
end

