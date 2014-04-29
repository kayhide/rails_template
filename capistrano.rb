run 'bundle exec cap install'
gsub_file 'config/deploy.rb', /my_app_name/, app_name
gsub_file 'config/deploy.rb', 'git@example.com:me/my_repo.git', `git config remote.origin.url`.strip

uncomment_lines 'config/deploy.rb', 'set :scm'
inject_into_file 'config/deploy.rb', <<EOS, after: /ask :branch.*\n/
set :branch, 'master'
EOS

uncomment_lines 'config/deploy.rb', 'set :deploy_to'
gsub_file 'config/deploy.rb', '/var/www/my_app', "/var/www/#{app_name}"

uncomment_lines 'config/deploy.rb', 'set :format'
uncomment_lines 'config/deploy.rb', 'set :log_level'

uncomment_lines 'config/deploy.rb', 'set :linked_dirs'
gsub_file 'config/deploy.rb', '{bin ', '{'

uncomment_lines 'config/deploy.rb', 'set :keep_releases'


inject_into_file 'config/deploy.rb', <<EOS, before: /namespace :deploy/
set :rbenv_type, :system
set :rbenv_ruby, '#{RUBY_VERSION}'

EOS

uncomment_lines 'config/deploy.rb', 'execute :touch'
remove_file 'config/deploy/staging.rb'
