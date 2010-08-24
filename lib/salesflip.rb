# All this plugin stuff is taken directly from FatFreeCRM (http://github.com/michaeldv/fat_free_crm)
require 'salesflip/callback'
require 'salesflip/plugin'
require 'salesflip/plugin_views'

ActionView::Base.send(:include, Salesflip::Callback::Helper)
ActionController::Base.send(:include, Salesflip::Callback::Helper)
#Rails::Plugin::Loader.send(:include, Salesflip::PrependingEngineViews)
