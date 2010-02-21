require 'compass'
require 'compass-colors'

# If you have any compass plugins, require them here.
Compass.configuration.parse(File.join(RAILS_ROOT, "config", "compass.config"))
Compass.configuration.environment = RAILS_ENV.to_sym
Compass.configure_sass_plugin!

#cache_dir = "tmp/sass-cache"