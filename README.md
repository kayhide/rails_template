# Rails Template

## 使い方
ローカルにクローンする。

```bash
git clone https://github.com/kayhide/rails_template.com
```

new する。

```bash
rails new hogepiyo -m ~/prj/ruby/rails_template/main.rb -d=postgresql
```

postgresql のユーザーを作る。

```bash
cd hogepiyo
rake db:create_user
```
