# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 103) do

  create_table "activities", :force => true do |t|
    t.boolean  "public"
    t.integer  "item_id"
    t.string   "item_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["item_id"], :name => "index_activities_on_item_id"
  add_index "activities", ["item_type"], :name => "index_activities_on_item_type"

  create_table "articles", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "synopsis"
    t.text     "body"
    t.boolean  "published",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.integer  "category_id",  :default => 1
  end

  create_table "bag_properties", :force => true do |t|
    t.integer  "bag_id",                :default => 1
    t.string   "name"
    t.string   "label"
    t.integer  "data_type",             :default => 1
    t.string   "display_type",          :default => "text"
    t.boolean  "required",              :default => false
    t.string   "default_value"
    t.integer  "default_visibility",    :default => 4
    t.boolean  "can_change_visibility", :default => true
    t.integer  "sort",                  :default => 9999
    t.integer  "width",                 :default => -1
    t.integer  "height",                :default => -1
    t.integer  "registration_page"
    t.string   "sf_field"
    t.boolean  "is_link",               :default => false
    t.string   "prefix"
    t.integer  "maxlength",             :default => 5000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bag_property_enums", :force => true do |t|
    t.integer  "bag_property_id"
    t.string   "name"
    t.string   "value"
    t.integer  "sort"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bag_property_enums", ["bag_property_id"], :name => "index_bag_property_enums_on_bag_property_id"

  create_table "bag_property_values", :force => true do |t|
    t.integer  "data_type",                                  :default => 1
    t.integer  "user_id"
    t.integer  "bag_property_id"
    t.string   "svalue"
    t.text     "tvalue",               :limit => 2147483647
    t.integer  "ivalue"
    t.integer  "bag_property_enum_id"
    t.datetime "tsvalue"
    t.integer  "visibility"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bag_property_values", ["user_id", "bag_property_id"], :name => "index_bag_property_values_on_user_id_and_bag_property_id"

  create_table "blogs", :force => true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string "name"
  end

  create_table "comments", :force => true do |t|
    t.integer  "entry_id"
    t.integer  "user_id"
    t.string   "guest_name"
    t.string   "guest_email"
    t.string   "guest_url"
    t.text     "body"
    t.datetime "created_at"
  end

  add_index "comments", ["entry_id"], :name => "index_comments_on_entry_id"

  create_table "communications", :force => true do |t|
    t.string   "subject"
    t.text     "content"
    t.integer  "parent_id"
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.datetime "sender_deleted_at"
    t.datetime "sender_read_at"
    t.datetime "recipient_deleted_at"
    t.datetime "recipient_read_at"
    t.datetime "replied_at"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "conversation_id"
  end

  add_index "communications", ["conversation_id"], :name => "index_communications_on_conversation_id"
  add_index "communications", ["recipient_id"], :name => "index_communications_on_recipient_id"
  add_index "communications", ["sender_id"], :name => "index_communications_on_sender_id"
  add_index "communications", ["type"], :name => "index_communications_on_type"

  create_table "connections", :force => true do |t|
    t.integer  "member_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "headline"
    t.string   "location"
    t.string   "country"
    t.string   "industry"
    t.string   "logged_in_url"
    t.string   "picture_url"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "connections", ["user_id"], :name => "connections_user_index"

  create_table "contacts", :force => true do |t|
    t.integer "user_id",                            :null => false
    t.string  "network"
    t.string  "gender"
    t.boolean "show_gender",      :default => true
    t.date    "birthday"
    t.boolean "show_birthday",    :default => true
    t.string  "hometown"
    t.string  "affection"
    t.string  "polity"
    t.string  "religion"
    t.string  "msn_account"
    t.string  "ichat_account"
    t.string  "gtalk_account"
    t.string  "aim_account"
    t.string  "phone"
    t.string  "cell_phone"
    t.string  "address"
    t.string  "city"
    t.integer "zipcode"
    t.string  "state"
    t.text    "website"
    t.string  "school"
    t.string  "school_year"
    t.string  "dept"
    t.string  "major"
    t.string  "high_school"
    t.string  "high_school_year"
    t.string  "employer"
    t.string  "position"
    t.text    "brief"
    t.string  "country"
    t.boolean "is_working",       :default => true
  end

  add_index "contacts", ["user_id"], :name => "index_contacts_on_user_id"

  create_table "content_page_versions", :force => true do |t|
    t.integer  "content_page_id"
    t.integer  "version"
    t.integer  "creator_id"
    t.string   "title"
    t.string   "url_key"
    t.text     "body"
    t.string   "locale"
    t.datetime "updated_at"
    t.text     "body_raw"
    t.integer  "contentable_id"
    t.string   "contentable_type"
    t.integer  "parent_id",        :default => 0
  end

  create_table "content_pages", :force => true do |t|
    t.integer  "creator_id"
    t.string   "title"
    t.string   "url_key"
    t.text     "body"
    t.string   "locale"
    t.text     "body_raw"
    t.integer  "contentable_id"
    t.string   "contentable_type"
    t.integer  "parent_id",        :default => 0, :null => false
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_pages", ["parent_id"], :name => "index_content_pages_on_parent_id"

  create_table "conversations", :force => true do |t|
  end

  create_table "ecategories", :force => true do |t|
    t.string "name"
  end

  create_table "educations", :force => true do |t|
    t.string   "linkedin_education_id"
    t.string   "school_name"
    t.string   "degree"
    t.string   "field_of_study"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "notes"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.integer  "last_send_attempt", :default => 0
    t.datetime "created_on"
    t.text     "mail"
  end

  create_table "entries", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "wall_comments_count",                 :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "permalink",           :limit => 2083
    t.datetime "published_at"
    t.boolean  "google_doc",                          :default => false
    t.boolean  "displayable",                         :default => false
  end

  create_table "event_attendees", :force => true do |t|
    t.integer "user_id"
    t.integer "event_id"
  end

  create_table "events", :force => true do |t|
    t.string   "title",                                  :null => false
    t.string   "description"
    t.integer  "user_id",                                :null => false
    t.datetime "start_time",                             :null => false
    t.datetime "end_time"
    t.boolean  "reminder"
    t.integer  "event_attendees_count", :default => 0
    t.integer  "privacy",                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "summary"
    t.string   "location"
    t.text     "uri"
    t.integer  "eventable_id"
    t.string   "eventable_type"
    t.string   "sponsor"
    t.string   "phone"
    t.string   "email"
    t.string   "city"
    t.string   "address"
    t.float    "lat",                   :default => 0.0
    t.float    "lng",                   :default => 0.0
    t.string   "icon"
    t.integer  "photos_count",          :default => 0,   :null => false
    t.integer  "wall_comments_count",   :default => 0,   :null => false
  end

  create_table "facebook_templates", :force => true do |t|
    t.string "template_name", :null => false
    t.string "content_hash",  :null => false
    t.string "bundle_id"
  end

  add_index "facebook_templates", ["template_name"], :name => "index_facebook_templates_on_template_name", :unique => true

  create_table "feeds", :force => true do |t|
    t.integer "user_id"
    t.integer "activity_id"
  end

  add_index "feeds", ["user_id", "activity_id"], :name => "index_feeds_on_user_id_and_activity_id"

  create_table "forums", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "topics_count",      :default => 0
    t.string   "url_key"
    t.string   "forumable_type"
    t.integer  "forumable_id"
    t.integer  "position"
    t.integer  "forum_posts_count", :default => 0
    t.text     "description_html"
  end

  add_index "forums", ["url_key"], :name => "index_forums_on_url_key"

  create_table "friendships", :force => true do |t|
    t.integer  "user_id",                             :null => false
    t.integer  "friend_id",                           :null => false
    t.boolean  "xfn_friend",       :default => false, :null => false
    t.boolean  "xfn_acquaintance", :default => false, :null => false
    t.boolean  "xfn_contact",      :default => false, :null => false
    t.boolean  "xfn_met",          :default => false, :null => false
    t.boolean  "xfn_coworker",     :default => false, :null => false
    t.boolean  "xfn_colleague",    :default => false, :null => false
    t.boolean  "xfn_coresident",   :default => false, :null => false
    t.boolean  "xfn_neighbor",     :default => false, :null => false
    t.boolean  "xfn_child",        :default => false, :null => false
    t.boolean  "xfn_parent",       :default => false, :null => false
    t.boolean  "xfn_sibling",      :default => false, :null => false
    t.boolean  "xfn_spouse",       :default => false, :null => false
    t.boolean  "xfn_kin",          :default => false, :null => false
    t.boolean  "xfn_muse",         :default => false, :null => false
    t.boolean  "xfn_crush",        :default => false, :null => false
    t.boolean  "xfn_date",         :default => false, :null => false
    t.boolean  "xfn_sweetheart",   :default => false, :null => false
    t.string   "status"
    t.datetime "created_at"
    t.datetime "accepted_at"
  end

  add_index "friendships", ["user_id", "friend_id"], :name => "index_friendships_on_user_id_and_friend_id"

  create_table "galleries", :force => true do |t|
    t.string   "title"
    t.string   "location"
    t.string   "description"
    t.integer  "photos_count",        :default => 0, :null => false
    t.integer  "primary_photo_id"
    t.integer  "privacy",             :default => 1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "creator_id"
    t.integer  "wall_comments_count", :default => 0, :null => false
  end

  create_table "geo_data", :force => true do |t|
    t.string "zipcode"
    t.float  "latitude"
    t.float  "longitude"
    t.string "city"
    t.string "state"
    t.string "address"
  end

  add_index "geo_data", ["zipcode"], :name => "zip_code_optimization"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "news"
    t.string   "office"
    t.string   "email"
    t.string   "address"
    t.string   "city"
    t.string   "website"
    t.integer  "mode",                :default => 0,        :null => false
    t.integer  "user_id"
    t.integer  "avatar_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_key"
    t.string   "default_role",        :default => "member"
    t.integer  "galleries_count",     :default => 0,        :null => false
    t.integer  "forum_posts_count",   :default => 0,        :null => false
    t.integer  "wall_comments_count", :default => 0,        :null => false
  end

  create_table "memberships", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.integer  "status"
    t.datetime "accepted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
    t.boolean  "banned",      :default => false
  end

  create_table "moderatorships", :force => true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

  create_table "monitorships", :force => true do |t|
    t.integer  "topic_id"
    t.integer  "user_id"
    t.boolean  "active",     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "news_items", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "newsable_id"
    t.string   "newsable_type"
    t.string   "url_key"
    t.string   "icon"
    t.integer  "creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wall_comments_count", :default => 0, :null => false
  end

  add_index "news_items", ["url_key"], :name => "index_news_items_on_url_key"

  create_table "newsletters", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.boolean  "sent",       :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :null => false
    t.string  "server_url"
    t.string  "salt",       :null => false
  end

  create_table "page_views", :force => true do |t|
    t.integer  "user_id"
    t.string   "request_url", :limit => 200
    t.string   "session",     :limit => 32
    t.string   "ip_address",  :limit => 16
    t.string   "referer",     :limit => 200
    t.string   "user_agent",  :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.string   "permalink"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.string   "content_type",        :limit => 100
    t.string   "filename"
    t.string   "path"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.float    "geo_lat"
    t.float    "geo_long"
    t.boolean  "show_geo",                           :default => true
    t.boolean  "avatar"
    t.integer  "gallery_id"
    t.integer  "position"
    t.datetime "updated_at"
    t.boolean  "primary"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "creator_id"
    t.integer  "wall_comments_count",                :default => 0,    :null => false
  end

  add_index "photos", ["parent_id"], :name => "index_photos_on_parent_id"

  create_table "pictures", :force => true do |t|
    t.string   "caption",        :limit => 1000
    t.integer  "photoable_id"
    t.string   "image"
    t.string   "photoable_type"
    t.integer  "creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pictures", ["photoable_id"], :name => "index_photos_on_user_id"

  create_table "positions", :force => true do |t|
    t.string   "linkedin_position_id"
    t.string   "title"
    t.text     "summary"
    t.string   "is_current",           :limit => 1
    t.date     "start_date"
    t.date     "end_date"
    t.string   "company"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", :force => true do |t|
    t.integer  "topic_id"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "blog_id"
    t.string   "title"
    t.string   "type"
    t.integer  "wall_comments_count", :default => 0, :null => false
    t.integer  "forum_id"
    t.integer  "group_id"
    t.text     "body_html"
  end

  add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
  add_index "posts", ["group_id", "created_at"], :name => "index_posts_on_group_id"
  add_index "posts", ["topic_id"], :name => "index_posts_on_topic_id"
  add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"

  create_table "preferences", :force => true do |t|
    t.string   "domain",              :default => "",    :null => false
    t.string   "smtp_server",         :default => "",    :null => false
    t.string   "server_name"
    t.string   "app_name"
    t.boolean  "email_notifications", :default => false, :null => false
    t.boolean  "email_verifications", :default => false, :null => false
    t.boolean  "demo",                :default => false
    t.text     "analytics"
    t.text     "about"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "whitelist",           :default => false
    t.string   "sidebar_title"
    t.text     "sidebar_body"
    t.boolean  "graph_api",           :default => false, :null => false
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id", :null => false
    t.integer "user_id", :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shared_entries", :force => true do |t|
    t.integer  "shared_by_id"
    t.integer  "entry_id"
    t.string   "destination_type", :default => "",    :null => false
    t.integer  "destination_id",                      :null => false
    t.boolean  "can_edit",         :default => false
    t.boolean  "public",           :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shared_pages", :force => true do |t|
    t.integer  "content_page_id"
    t.string   "share_type",      :default => "", :null => false
    t.integer  "share_id",                        :null => false
    t.integer  "status",          :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shared_uploads", :force => true do |t|
    t.integer  "shared_uploadable_id"
    t.string   "shared_uploadable_type"
    t.integer  "upload_id"
    t.integer  "shared_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shared_uploads", ["shared_by_id"], :name => "index_shared_uploads_on_shared_by_id"
  add_index "shared_uploads", ["shared_uploadable_id"], :name => "index_shared_uploads_on_uploadable_id"
  add_index "shared_uploads", ["upload_id"], :name => "index_shared_uploads_on_upload_id"

  create_table "signin_failures", :force => true do |t|
    t.string   "email"
    t.string   "ip"
    t.datetime "created_at"
  end

  create_table "simple_captcha_data", :force => true do |t|
    t.string   "key",        :limit => 40
    t.string   "value",      :limit => 6
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", :force => true do |t|
    t.string   "name"
    t.string   "title",                        :default => "", :null => false
    t.string   "subtitle",                     :default => "", :null => false
    t.string   "slogan",                       :default => "", :null => false
    t.string   "background_color",             :default => "", :null => false
    t.string   "font_color",                   :default => "", :null => false
    t.string   "font_style",                   :default => "", :null => false
    t.string   "font_size",                    :default => "", :null => false
    t.string   "content_background_color",     :default => "", :null => false
    t.string   "a_font_style",                 :default => "", :null => false
    t.string   "a_font_color",                 :default => "", :null => false
    t.string   "top_background_color",         :default => "", :null => false
    t.string   "top_color",                    :default => "", :null => false
    t.string   "link_button_background_color"
    t.string   "link_button_font_color"
    t.string   "highlight_color"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "specs", :force => true do |t|
    t.integer "user_id",  :null => false
    t.text    "activity"
    t.text    "interest"
    t.text    "music"
    t.text    "tv"
    t.text    "movie"
    t.text    "book"
    t.text    "maxim"
    t.text    "about_me"
  end

  create_table "status_updates", :force => true do |t|
    t.integer  "user_id"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_tag_id_and_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "topics", :force => true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_posts_count", :default => 0
    t.string   "title"
    t.integer  "hits",              :default => 0
    t.integer  "sticky",            :default => 0
    t.boolean  "locked",            :default => false
    t.datetime "replied_at"
    t.integer  "replied_by"
    t.integer  "last_post_id"
  end

  add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"
  add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
  add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"

  create_table "user_openids", :force => true do |t|
    t.string   "openid_url", :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_openids", ["openid_url"], :name => "index_user_openids_on_openid_url"
  add_index "user_openids", ["user_id"], :name => "index_user_openids_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "username",                                                      :null => false
    t.string   "email",                       :limit => 128,                    :null => false
    t.string   "hashed_password",             :limit => 64
    t.boolean  "enabled",                                    :default => true,  :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_login_at"
    t.integer  "forum_posts_count",                          :default => 0,     :null => false
    t.integer  "site_forum_posts_count",                     :default => 0,     :null => false
    t.integer  "group_forum_posts_count",                    :default => 0,     :null => false
    t.integer  "entries_count",                              :default => 0,     :null => false
    t.string   "blog_link"
    t.string   "blog_rss"
    t.integer  "photos_count",                               :default => 0,     :null => false
    t.string   "last_activity"
    t.datetime "last_activity_at"
    t.string   "flickr_username"
    t.string   "flickr_id"
    t.string   "first_name",                                                    :null => false
    t.string   "middle_name"
    t.string   "last_name",                                                     :null => false
    t.string   "full_name"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "pw_reset_code",               :limit => 40
    t.string   "yahoo_userhash"
    t.string   "identity_url"
    t.string   "activation_code",             :limit => 40
    t.datetime "activated_at"
    t.string   "question"
    t.string   "answer"
    t.string   "reactivation_code",           :limit => 40
    t.datetime "reactivated_at"
    t.datetime "last_contacted_at"
    t.boolean  "connection_notifications",                   :default => true
    t.boolean  "message_notifications",                      :default => true
    t.boolean  "wall_comment_notifications",                 :default => true
    t.boolean  "blog_comment_notifications",                 :default => true
    t.boolean  "photo_comment_notifications",                :default => true
    t.boolean  "email_verified"
    t.string   "youtube_name"
    t.integer  "galleries_count",                            :default => 0,     :null => false
    t.boolean  "entry_comment_notifications",                :default => true
    t.boolean  "event_comment_notifications",                :default => true
    t.integer  "blog_posts_count",                           :default => 0,     :null => false
    t.boolean  "admin",                                      :default => false, :null => false
    t.boolean  "group_comment_notifications",                :default => true
    t.boolean  "news_comment_notifications",                 :default => true
    t.integer  "wall_comments_count",                        :default => 0,     :null => false
    t.integer  "twitter_id",                  :limit => 8
    t.string   "screen_name"
    t.string   "token"
    t.string   "secret"
    t.string   "profile_image_url"
    t.integer  "fb_uid",                                     :default => 0
    t.integer  "fb_user_uid",                                :default => 0
    t.string   "fb_access_token",             :limit => 64
    t.string   "email_hash",                  :limit => 64
    t.string   "oauth_token"
    t.string   "oauth_secret"
    t.string   "youtube_username"
    t.string   "wll_uid"
    t.string   "wll_name"
    t.string   "persistence_token"
    t.string   "member_id"
    t.string   "linkedin_first_name"
    t.string   "linkedin_last_name"
    t.string   "picture_url"
    t.string   "headline"
    t.string   "industry"
    t.text     "summary"
    t.text     "specialties"
    t.text     "interests"
    t.string   "logged_in_url"
    t.string   "public_profile_url"
    t.string   "location"
    t.string   "country"
    t.string   "member_id_token"
    t.string   "honors"
    t.string   "associations"
    t.text     "member_url_resources"
    t.string   "twitter_accounts"
    t.integer  "signin_count",                               :default => 0
    t.integer  "foursquare_uid",                             :default => 0
    t.string   "foursquare_token"
  end

  add_index "users", ["oauth_token"], :name => "index_users_on_oauth_token"
  add_index "users", ["screen_name"], :name => "index_users_on_screen_name", :unique => true
  add_index "users", ["twitter_id"], :name => "index_users_on_twitter_id", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username"
  add_index "users", ["wll_uid"], :name => "index_users_on_wll_uid", :unique => true
  add_index "users", ["youtube_username"], :name => "index_users_on_youtube_username", :unique => true

  create_table "usertemplates", :force => true do |t|
    t.integer "user_id"
    t.string  "name"
    t.text    "body"
  end

  add_index "usertemplates", ["user_id", "name"], :name => "index_usertemplates_on_user_id_and_name"

  create_table "wall_comments", :force => true do |t|
    t.integer  "commenter_id"
    t.integer  "commentable_id"
    t.string   "commentable_type", :default => "", :null => false
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wall_comments", ["commentable_id", "commentable_type"], :name => "index_wall_comments_on_commentable_id_and_commentable_type"
  add_index "wall_comments", ["commenter_id"], :name => "index_wall_comments_on_commenter_id"

  create_table "widgets", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
