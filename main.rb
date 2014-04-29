@use_bootstrap = true
@use_semantic_ui = false
@use_capistrano = true
@use_heroku = false
@keep_comments = false

if ENV['USE_SEMANTIC_UI']
  @use_bootstrap = false
  @use_semantic_ui = true
end

if ENV['USE_HEROKU']
  @use_capistrano = false
  @use_heroku = true
end

if ENV['KEEP_COMMENTS']
  @keep_comments = true
end

def remove_comments file
  unless @keep_comments
    gsub_file file, /^[ \t]*#.*\n\n*/, ''
  end
end

def insert_breakline file, line = "\n"
  append_to_file file, line, force: true
end


# Gemfile
# ============================================================
comment_lines 'Gemfile', /turbolinks/
comment_lines 'Gemfile', /sdoc/
comment_lines 'Gemfile', /unicorn/
comment_lines 'Gemfile', /spring/
remove_comments 'Gemfile'

inject_into_file 'Gemfile', <<EOS, before: /gem 'rails'/
ruby '#{RUBY_VERSION}'
EOS

gem 'unicorn'
gem 'foreman'
gem 'pry-rails'
gem 'slim-rails'
gem 'redcarpet'
gem 'kaminari'
gem 'settingslogic'
insert_breakline 'Gemfile'

if @use_bootstrap
  gem 'therubyracer'
  gem 'less-rails'
  gem 'twitter-bootstrap-rails', github: 'seyhunak/twitter-bootstrap-rails', branch: 'bootstrap3'
  insert_breakline 'Gemfile'
end

if @use_semantic_ui
  gem 'therubyracer'
  gem 'less-rails'
  gem 'autoprefixer-rails'
  gem 'semantic-ui-rails'
  insert_breakline 'Gemfile'
end

gem_group :development, :test do
  gem 'pry-doc'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'tapp'
  gem 'awesome_print'
  gem 'quiet_assets'
  insert_breakline 'Gemfile'

  gem 'rspec-rails'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-livereload', require: false
  gem 'factory_girl_rails'
end

gem_group :development do
  gem 'rack-mini-profiler'
  gem 'letter_opener'
  gem 'meta_request'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rails-footnotes'
end

gem_group :test do
  gem 'timecop'
  gem 'fuubar'
  gem 'webmock'
  gem 'simplecov', require: false
end

if @use_capistrano
  gem_group :development do
    gem 'capistrano-rails'
    gem 'capistrano-rbenv'
    gem 'capistrano-bundler'
  end
end

if @use_heroku
  gem_group :production, :staging do
    gem 'rails_12factor'
    gem 'newrelic_rpm'
  end
end

run_bundle


# config/application.rb
# ============================================================
application <<EOS.strip
    config.active_record.default_timezone = :local
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = :ja

    config.generators do |g|
      g.orm :active_record
      g.test_framework :rspec, fixture: true, fixture_replacement: :factory_girl
      g.view_specs false
      g.controller_specs false
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
EOS

remove_comments 'config/application.rb'


# config/environments
# ============================================================
environment <<EOS, env: :development
config.action_mailer.delivery_method = :letter_opener
EOS

Dir['config/environments/*.rb'].each do |f|
  remove_comments f
end


# postgresql
# ============================================================
if gem_for_database == 'pg'
  rakefile 'db_create_user.rake', <<'EOS'
namespace :db do
  desc 'Creates postgres user for all environments.'
  task :create_user => :environment do
    Rails.configuration.database_configuration.map do |env, conf|
      conf['username']
    end.uniq.compact.each do |username|
      `createuser -e -s -d #{username}`
    end
  end
end
EOS
end

inject_into_file 'config/database.yml', <<EOS, after: /  pool:.*\n/
  username: #{app_name}
  password:
EOS

remove_comments 'config/database.yml'


# rspec
# ============================================================
generate 'rspec:install'

append_to_file '.rspec', <<EOS
--format=Fuubar
EOS

inside 'spec' do
  prepend_to_file 'spec_helper.rb', <<EOS
require 'simplecov'
SimpleCov.start 'rails'

EOS

  comment_lines 'spec_helper.rb', 'config.fixture_path'
  comment_lines 'spec_helper.rb', 'rspec/autorun'

  inject_into_file 'spec_helper.rb', <<EOS, before: /^end$/

  config.before do
    FactoryGirl.reload
  end
EOS


  remove_comments 'spec_helper.rb'
end

remove_dir 'test'


# guard
# ============================================================
run 'bundle exec guard init'
gsub_file 'Guardfile', /guard :rspec/, <<EOS.strip
guard :rspec, cmd: 'spring rspec'
EOS

inject_into_file 'Guardfile', <<EOS, before: /^end$/

  # FactoryGirl
  watch(%r{^spec/factories/(.+)\.rb$})                { |m| ["spec/controllers", "spec/requests"] }
EOS


# unicorn
# ============================================================
copy_file File.expand_path('../config/unicorn.rb', __FILE__), 'config/unicorn.rb'
create_file 'Procfile' do
  body = <<EOS
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
EOS
end

create_file '.env', <<EOS
PORT=8080
EOS


# bootstrap
# ============================================================
if @use_bootstrap
  generate 'bootstrap:install', 'less'
  generate 'bootstrap:layout'
  remove_file 'app/views/layouts/application.html.erb'

  append_to_file 'app/assets/stylesheets/application.css', <<EOS
body { padding-top: 60px; }
EOS
end


# remove .keep
# ============================================================
Dir['**/.keep'].each do |f|
  if Dir[File.join(File.dirname(f), '*')].present?
    puts Dir[File.join(File.dirname(f), '*')]
    remove_file f
  end
end


# git
# ============================================================
remove_file '.gitignore'
create_file '.gitignore', <<EOS
#{open(File.expand_path('../gitignore/Rails.gitignore', __FILE__)).read}
#{open(File.expand_path('../gitignore/OSX.gitignore', __FILE__)).read}
EOS

comment_lines '.gitignore', '.rspec'
comment_lines '.gitignore', 'config/initializers/secret_token.rb'
comment_lines '.gitignore', 'config/secrets.yml'
comment_lines '.gitignore', '.rvmrc'

remove_comments '.gitignore'

git :init
