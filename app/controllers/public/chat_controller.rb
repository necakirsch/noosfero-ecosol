class ChatController < PublicController

  before_filter :login_required
  before_filter :check_environment_feature
  before_filter :can_send_message, :only => :register_message

  def start_session
    login = user.jid
    password = current_user.crypted_password
    begin
      jid, sid, rid = RubyBOSH.initialize_session(login, password, "http://#{environment.default_hostname}/http-bind",
                                                  :wait => 30, :hold => 1, :window => 5)
      session_data = { :jid => jid, :sid => sid, :rid => rid }
      render :text => session_data.to_json, :layout => false, :content_type => 'application/javascript'
    rescue
      render :action => 'start_session_error', :layout => false, :status => 500
    end
  end

  def avatar
    profile = environment.profiles.find_by_identifier(params[:id])
    filename, mimetype = profile_icon(profile, :minor, true)
    if filename =~ /^https?:/
      redirect_to filename
    else
      data = File.read(File.join(Rails.root, 'public', filename))
      render :text => data, :layout => false, :content_type => mimetype
      expires_in 24.hours
    end
  end

  def index
    presence = current_user.last_chat_status
    if presence.blank? or presence == 'chat'
      render :action => 'auto_connect_online'
    else
      render :action => 'auto_connect_busy'
    end
  end

  def update_presence_status
    if request.xhr?
      current_user.update_attributes({:chat_status_at => DateTime.now}.merge(params[:status] || {}))
    end
    render :nothing => true
  end

  def register_message
    if request.post?
      begin
        ChatMessage.create!(:from => params[:from], :to => params[:to], :message => params[:message])
        render :text => {:status => 0}.to_json
      rescue Exception => exception
        render :text => {:status => 4, :message => exception.to_s, :backtrace => exception.backtrace}.to_json
      end
    end
  end

  protected

  def check_environment_feature
    unless environment.enabled?('xmpp_chat')
      render_not_found
      return
    end
  end

  def can_send_message
    return render_json({:status => 1, :message => 'Missing parameters!'}) if params[:from].nil? || params[:to].nil? || params[:message].nil?
    return render_json({:status => 2, :message => 'You can not send message as another user!'}) if params[:from] != user.jid
    # TODO Maybe register the jid in a table someday to avoid this below
    return render_json({:status => 3, :messsage => 'You can not send messages to strangers!'}) if user.friends.where(:identifier => params[:to].split('@').first).blank?
  end

  def render_json(result)
    render :text => result.to_json
  end
end
