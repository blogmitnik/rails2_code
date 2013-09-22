module MembershipsHelper
  # Return true if a user is the owner of a group or if member of it
  def is_member_of?(group)
    group.owner?(logged_in_user) or Membership.accepted?(logged_in_user, group)
  end
end
