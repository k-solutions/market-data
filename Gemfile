source 'https://rubygems.org'
# source 'mwdvmglb01'

gem 'daemons'
gem 'celluloid', :git => 'git://github.com/celluloid/celluloid.git'
# gem 'debugger', :platform => :mri, :group => :development
# Redis drivers 
# NOTE: we currently use all of them 
gem 'hiredis' # used in market stoarege and watchdog
gem 'redis', '< 3.0', :require => ["redis", "redis/connection/hiredis"]
gem 'celluloid-redis'

gem 'pry',  :group => :development
group :test do
  gem "rspec"
end
