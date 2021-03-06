require "simplecov"
require "coveralls"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '.bundle/'
end
Coveralls.wear!

require "store_agent"
if !File.exists?(StoreAgent.config.storage_root)
  FileUtils.mkdir_p(StoreAgent.config.storage_root)
end
$directory_bytesize = File.size(StoreAgent.config.storage_root)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.profile_examples = 10
  config.order = :random

  Kernel.srand config.seed

  config.before(:suite) do
    StoreAgent.configure do |config|
      config.json_indent_level = 2
      config.default_owner_permission = {
        "read" => true,
        "write" => true,
        "execute" => true,
        "chmod" => true
      }
    end
    if File.exists?(StoreAgent.config.storage_root)
      FileUtils.remove_dir(StoreAgent.config.storage_root)
    end
  end
end
