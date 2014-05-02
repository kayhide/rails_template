run 'bundle exec guard init'
gsub_file 'Guardfile', /guard :rspec do/, <<EOS.strip
guard :rspec, cmd: 'spring rspec' do
EOS

inject_into_file 'Guardfile', <<EOS, after: /^guard :rspec.*\n(\n|  .*\n)*/

  # FactoryGirl
  watch(%r{^spec/factories/(.+)\.rb$})                { |m| ["spec/controllers", "spec/requests"] }
EOS
