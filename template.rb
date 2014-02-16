require "rails"
require "bundler"

git :init
run 'echo "*.rbc" >> .gitignore'
run 'echo "*.sassc" >> .gitignore'
run 'echo ".sass-cache" >> .gitignore'
run 'echo "**.orig" >> .gitignore'
run 'echo "/log" >> .gitignore'
run 'echo "/tmp" >> .gitignore'
run 'echo "/public/uploads" >> .gitignore'
run 'echo "/coverage/" >> .gitignore'
run 'echo "/spec/tmp" >> .gitignore'
run 'echo ".ruby-version" >> .gitignore'
run 'echo "config/database.yml" >> .gitignore'
git add: "."
git commit: '-m "Initial commit"'

@template_root = File.expand_path(File.join(File.dirname(__FILE__), "files"))
@views_root = File.join(@template_root, "app", "views")
@asset_root = File.join(@template_root, "app", "assets")
@stylesheet_root = File.join(@asset_root, "stylesheets")
@javascript_root = File.join(@asset_root, "javascripts")
@app_name_files = @app_name.underscore

run "cp #{File.join(@template_root, "Gemfile")} Gemfile"
run "cp #{File.join(@template_root, "config", "database.sample.yml")} config/database.sample.yml"
run "cp #{File.join(@template_root, "config", "database.yml")} config/database.yml"
gsub_file "config/database.sample.yml", "PROJECT_NAME", @app_name_files
gsub_file "config/database.yml", "PROJECT_NAME", @app_name_files
run "bundle install"
run "rake db:create db:migrate"
run "rails generate rspec:install"
run "rails generate machinist:install"

simple_cov_prepend = <<-EOF
require 'simplecov'
SimpleCov.start 'rails' do
  # add_filter '/app/admin'
end
EOF

run "content=$(cat spec/spec_helper.rb) && echo \"#{simple_cov_prepend}\n$content\" > spec/spec_helper.rb"

gsub_file "spec/spec_helper.rb", 'config.order = "random"', 'config.order = "random"

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end'

git add: "."
git commit: '-am "Basic gems"'

if yes?("Install devise?")
  gsub_file "Gemfile", "# gem 'devise'", "gem 'devise'"
  run "bundle install"
  run "rails generate devise:install"
  git add: "."
  git commit: '-am "Install devise"'
  if yes?("Generate default User (devise)?")
    run "rails generate devise User"
    run "rake db:migrate db:test:load"
    git add: "."
    git commit: '-am "Generate User (devise)"'
  end
end


run "mkdir app/assets/javascripts/#{@app_name_files}"
run "cp #{File.join(@javascript_root, "my_app", "my_app.js.coffee")} app/assets/javascripts/#{@app_name_files}/#{@app_name_files}.js.coffee"
run "touch app/assets/javascripts/#{@app_name_files}/.keep"
run "mkdir app/assets/javascripts/lib"
run "touch app/assets/javascripts/lib/.keep"
run "mkdir app/assets/stylesheets/#{@app_name_files}"
run "touch app/assets/stylesheets/#{@app_name_files}/.keep"
run "cp -r #{File.join(@views_root, "layouts")} app/views"
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss"
run 'echo "@import \"twitter/bootstrap\"" >> app/assets/stylesheets/application.css.scss'
gsub_file "app/assets/stylesheets/application.css.scss", "require_tree .", "require_tree ./#{@app_name_files}"
gsub_file "app/assets/javascripts/application.js", "//= require turbolinks\n", ""
gsub_file "app/assets/javascripts/#{@app_name_files}/#{@app_name_files}.js.coffee", "PROJECT_NAME", @app_name.camelize
gsub_file "app/assets/javascripts/application.js", "//= require turbolinks", ""
gsub_file "app/assets/javascripts/application.js", "require_tree .", "require_tree ./#{@app_name_files}"

gsub_file "app/views/layouts/application.html.slim", "PROJECT_NAME", @app_name.camelize

gsub_file "config/application.rb", "# config.time_zone = 'Central Time (US & Canada)'", "config.time_zone = 'Brasilia'"
gsub_file "config/application.rb", "# config.i18n.default_locale = :de", 'config.i18n.available_locales = %i(pt-BR)
    config.i18n.default_locale = :"pt-BR"
    config.i18n.locale = :"pt-BR"

    config.generators do |g|
      g.javascripts false
      g.stylesheets false
      g.helper false
      g.template_engine :slim
      g.test_framework :rspec,
        view_specs: false,
        helper_specs: false
      g.fixture_replacement :machinist
    end'

git rm: "app/views/layouts/application.html.erb"
git add: "."
git commit: '-am "Basic structure"'
