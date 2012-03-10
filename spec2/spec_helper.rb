
require 'rufus-json/automatic'
require 'ruote/amqp'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require(f) }


RSpec.configure do |config|

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.include RuoteAmqpHelper
end

