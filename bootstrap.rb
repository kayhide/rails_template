source_paths << File.dirname(__FILE__)

inside 'app/assets/stylesheets' do
  create_file 'application.css.scss' do
    body = <<EOS
@import 'bootstrap';
@import 'font-awesome';
EOS
  end

  remove_file 'application.css'
end

inside 'app/assets/javascripts' do
  inject_into_file 'application.js', <<EOS, before: '//= require_tree .'
//= require bootstrap
EOS
  remove_file 'application.css'
end

inside 'app/views/layouts' do
  template 'application.html.slim'
  remove_file 'application.html.erb'
end
