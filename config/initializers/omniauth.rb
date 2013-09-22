ActionController::Dispatcher.middleware.use OmniAuth::Builder do
  #provider :facebook, GRAPH_APP_ID, GRAPH_SECRET, :scope => %(email user_birthday user_photos, friends_photos, read_mailbox, publish_stream offline_access), :client_options => {:ssl => {:ca_file => "#{Rails.root}/config/fb_ca_chain_bundle.crt"}}
  #provider :instagram, INSTAGRAM_CLIENT_ID, INSTAGRAM_SECRET, {:client_options => {:ssl => {:ca_file => "#{Rails.root}/config/cacert.pem"}}}
end
