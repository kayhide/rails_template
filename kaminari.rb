generate 'kaminari:config'
if @use_bootstrap
  directory File.expand_path('../app/views/kaminari', __FILE__), 'app/views/kaminari'
else
  generate 'kaminari:views'
end
