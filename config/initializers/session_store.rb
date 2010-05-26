# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_lean_crm_session',
  :secret      => 'b037c8a2110a3536220eb6e61ddb5eaf1359f2794ef8490edcf8f8d2083cf5769c9c4f9d2b9b43efaaf7638b1e0dc64ee6a78ce5cf1150ec374e60132c617bdc'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
#ActionController::Base.session_store = :mem_cache_store
