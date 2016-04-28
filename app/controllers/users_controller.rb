class UsersController < ApplicationController

  # GET '/ad/listuser/id/:id'
  def listads
    # ads lists for user
    @user = User.find(params[:id])
    redirect_to profile_path(username: @user.username)
  end

  # GET '/profile/:username'
  def profile
    # public profile for user
    @user = User.find_by_username(params[:username])
    if @user.nil? 
      # not username, but ID
      @user = User.find(params[:username])
    end
    @ads = @user.ads
                .includes(:user)
                .public_send(status_scope)
                .paginate(:page => params[:page])
  end

end
