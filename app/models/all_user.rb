class AllUser < User
  is_indexed :fields => [ 'username', 'first_name', 'last_name', 'description' ]
end