source_paths << File.dirname(__FILE__)

@locale = nil
@use_bootstrap = true
@use_heroku = false
@use_capistrano = false
@keep_comments = false

if ENV['USE_HEROKU'] || yes?('use heroku?')
  say 'use heroku: [yes]'
  @use_heroku = true
else
  say 'use heroku: [no]'
  if ENV['USE_CAPISTRANO'] || yes?('use capistrano?')
    say 'use capistrano: [yes]'
    @use_capistrano = true
  else
    say 'use capistrano: [no]'
  end
end

if ENV['KEEP_COMMENTS'] || yes?('keep comments?')
  say 'keep comments: [yes]'
  @keep_comments = true
else
  say 'keep comments: [no]'
end

if (@locale = ask("locale?")).empty?
  @locale = (ENV['LANG'] || 'en').split('_').first
end
say "locale: [#{@locale}]"

ask('press key...')

if @keep_comments
  def remove_comments _
  end
else
  def remove_comments file
    gsub_file file, /^[ \t]*#.*\n\n*/, ''
  end
end

def insert_breakline file, line = "\n"
  append_to_file file, line, force: true
end


# Gemfile
# ============================================================
comment_lines 'Gemfile', /turbolinks/
comment_lines 'Gemfile', /jbuilder/
comment_lines 'Gemfile', /sdoc/
comment_lines 'Gemfile', /unicorn/
comment_lines 'Gemfile', /spring/
remove_comments 'Gemfile'

inject_into_file 'Gemfile', <<EOS, before: /^gem 'rails'/
ruby '#{RUBY_VERSION}'
EOS

gem 'unicorn'
gem 'foreman'
gem 'slim-rails'
gem 'kaminari'
gem 'settingslogic'
insert_breakline 'Gemfile'

gem 'bootstrap-sass'
gem 'font-awesome-rails'
gem 'compass-rails'
insert_breakline 'Gemfile'

gem 'rails-i18n'
insert_breakline 'Gemfile'

gem 'pry-rails'
gem 'awesome_print'
insert_breakline 'Gemfile'

gem_group :development, :test do
  gem 'pry-doc'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'tapp'
  gem 'quiet_assets'
  gem 'dotenv-rails'
  gem 'factory_girl_rails'
  insert_breakline 'Gemfile'

  gem 'rspec-rails'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-livereload', require: false
end

gem_group :development do
  gem 'web-console'
  gem 'letter_opener'
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

gsub_file 'Gemfile', '"', '\''


# config/application.rb
# ============================================================
remove_comments 'config/application.rb'
application <<EOS.strip
    config.active_record.default_timezone = :local
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = :#{@locale}
    config.i18n.available_locales = [:#{@locale}]

    config.generators do |g|
      g.orm :active_record
      g.test_framework :rspec, fixture: true, fixture_replacement: :factory_girl
      g.view_specs false
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
EOS


# config/environments
# ============================================================
environment <<EOS, env: :development
config.action_mailer.delivery_method = :letter_opener
EOS

Dir['config/environments/*.rb'].each do |f|
  remove_comments f
end


# config/locales
# ============================================================
source_paths.each do |dir|
  Dir[File.join(dir, "**/locales/*#{@locale}.yml")].each do |f|
    f = Pathname.new(f).relative_path_from(Pathname.new(dir)).to_s
    template f
  end
end


# turbolinks
# ============================================================
gsub_file 'app/assets/javascripts/application.js', /^.*turbolinks.*\n/, ''


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

gsub_file 'config/database.yml', /  pool:.*\n/, <<EOS
  pool: <%= ENV['DB_POOL'] || ENV['MAX_THREADS'] || 5 %>
  username: #{app_name}
  password:
EOS

remove_comments 'config/database.yml'

create_file '.env.sample', <<EOS
export DB_POOL=5
EOS


# rspec
# ============================================================
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


# settingslogic
# ============================================================
copy_file 'config/settings.yml'
copy_file 'app/models/settings.rb'


# guard
# ============================================================
apply 'guard.rb'


# unicorn
# ============================================================
copy_file 'config/unicorn.rb'
create_file 'Procfile' do
  body = <<EOS
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
EOS
end


# rails_footnotes
# ============================================================
apply 'rails_footnotes.rb'


# bootstrap
# ============================================================
if @use_bootstrap
  apply 'bootstrap.rb'
end


# kaminari
# ============================================================
generate 'kaminari:config'
if @use_bootstrap
  directory File.expand_path('../app/views/kaminari', __FILE__), 'app/views/kaminari'
else
  generate 'kaminari:views'
end


# capistrano
# ============================================================
if @use_capistrano
  apply File.expand_path('../capistrano.rb', __FILE__)
end


# remove .keep
# ============================================================
Dir['**/.keep'].each do |f|
  if Dir[File.join(File.dirname(f), '*')].present?
    remove_file f
  end
end


# git
# ============================================================
remove_file '.gitignore'
create_file '.gitignore', <<EOS
.env

#{open(File.expand_path('../gitignore/Rails.gitignore', __FILE__)).read}
#{open(File.expand_path('../gitignore/OSX.gitignore', __FILE__)).read}
EOS

comment_lines '.gitignore', '.rspec'
comment_lines '.gitignore', 'config/secrets.yml'
comment_lines '.gitignore', '.rvmrc'

remove_comments '.gitignore'

git :init
git add: '.'
git commit: '-m "init."'
