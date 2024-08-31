module Admins
  class UsersController < Admins::AdminsPagesController
    def index
      @users = current_admin.users
    end
  end
end
