generate 'rspec:install'

append_to_file '.rspec', <<EOS
--format=Fuubar
EOS

inside 'spec' do
  prepend_to_file 'rails_helper.rb', <<EOS
require 'simplecov'
SimpleCov.start 'rails'

EOS

  comment_lines 'rails_helper.rb', 'config.fixture_path'
  comment_lines 'rails_helper.rb', 'rspec/autorun'

  inject_into_file 'rails_helper.rb', <<EOS, before: /^end$/

  config.before do
    FactoryGirl.reload
  end
EOS


  remove_comments 'rails_helper.rb'
end

remove_dir 'test'
