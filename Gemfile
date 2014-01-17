source 'https://rubygems.org'

ruby '2.1.0'

gem 'rails', '4.0.2'

gem 'pg'

# Assets
gem 'sass-rails',   '~> 4.0.0'
gem 'uglifier',     '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'jquery-rails'
gem 'compass-rails'

gem 'devise'
gem 'devise_invitable'
gem 'figaro',       github: 'laserlemon/figaro'
gem 'honeybadger'
gem 'interactor-rails'
gem 'newrelic_rpm'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

group :development, :test do
  gem 'rspec-rails', '~> 2.14.0'

  # Use debugger
  gem 'debugger'
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'capybara'
  gem 'factory_girl_rails'
end

group :production, :staging do
  gem 'unicorn', require: false
  gem 'rails_12factor'
end
