module ToolbarHelper
  # Define the toolbar content for your view. There are two typical cases, depending on the value of
  # options[:profile]
  # * If present, render the profile menu for the {SocialStream::Models::Subject subject}
  # * If blank, render the home menu
  #
  # The menu option allows overwriting a menu slot with the content of the given block
  #
  #
  # Autoexpanding a menu section on your view:
  #
  # Toolbar allows you to autoexpand certain menu section that may be of interest for your view.
  # For example, the messages menu when you are looking your inbox. This is done through :option element.
  #
  # To get it working, you should use the proper :option to be expanded, ":option => :messages" in the
  # mentioned example. This will try, automatically, to expand the section of the menu where its root
  # list link, the one expanding the section, has an id equal to "#messages_menu". If you use
  # ":options => :contacts" it will try to expand "#contacts_menu".
  #
  # For now its working with :option => :messages, :contacts or :groups
  #
  #
  # Examples:
  #
  # Render the home toolbar:
  #
  #   <% toolbar %>
  #
  # Render the profile toolbar for a user:
  #
  #   <% toolbar :profile => @user %>
  #
  # Render the home toolbar changing the messages menu option:
  #
  #   <% toolbar :option => :messages %>
  #
  # Render the profile toolbar for group changing the contacts menu option:
  #
  #   <% toolbar :profile => @group, :option => :contacts %>
  #
  def toolbar(options = {}, &block)
    old_toolbar(options,&block)
  end

  def old_toolbar(options = {}, &block)
    if options[:option] && block_given?
      menu_options[options[:option]] = capture(&block)
    end

    content = capture do
      if options[:profile]
        render :partial => 'toolbar/profile', :locals => { :subject => options[:profile] }
      else
        render :partial => 'toolbar/home'
      end
    end

    case request.format
    when Mime::JS
      response = <<-EOJ

          $('#toolbar').html("#{ escape_javascript(content) }");
          initMenu();
          expandSubMenu('#{ options[:option] }');
          EOJ

      response.html_safe
    else
    content_for(:toolbar) do
    content
    end
    content_for(:javascript) do
    <<-EOJ
    expandSubMenu('#{ options[:option] }');
    EOJ
    end
    end
  end

  # Cache menu options for toolbar
  #
  # @api private
  def menu_options #:nodoc:
    @menu_options ||= {}
  end

  def default_toolbar_menu
    items = [{:key => :notifications,
        :name => image_tag("btn/btn_notification.png", :class => "menu_icon")+t('notification.other')+' ('+ current_subject.mailbox.notifications.not_trashed.unread.count.to_s+')',
        :url => notifications_path}]

    items << {:key => :messages, 
        :name => image_tag("btn/new.png", :class => "menu_icon")+t('message.other')+' (' + current_subject.mailbox.inbox(:unread => true).count.to_s + ')',
        :url => "#", :items => [
          {:key => :message_new, :name => image_tag("btn/message_new.png", :class => "menu_icon")+ t('message.new'), :url => new_message_path},
          {:key => :message_inbox, :name => image_tag("btn/message_inbox.png", :class => "menu_icon")+t('message.inbox')+' (' + current_subject.mailbox.inbox(:unread => true).count.to_s + ')', 
                   :url => conversations_path, :options => {:link =>{:remote=> true}}},
          {:key => :message_sentbox, :name => image_tag("btn/message_sentbox.png", :class => "menu_icon")+t('message.sentbox'), :url => conversations_path(:box => :sentbox), :remote=> true},
          {:key => :message_trash, :name => image_tag("btn/message_trash.png", :class => "menu_icon")+t('message.trash'), :url => conversations_path(:box => :trash)}
      ]}
      
    items << {:key => :contacts, 
        :name => image_tag("btn/btn_friend.png", :class => "menu_icon")+t('contact.other'),
        :url => "#", :items => [
          {:key => :invitations, :name => image_tag("btn/btn_invitation.png", :class => "menu_icon")+t('invitation.other'), :url => new_invitation_path},
          {:key => :message_inbox, :name => image_tag("btn/message_inbox.png", :class => "menu_icon")+t('message.inbox')+' (' + current_subject.mailbox.inbox(:unread => true).count.to_s + ')', 
                   :url => conversations_path, :options => {:link =>{:remote=> true}}},
          {:key => :message_sentbox, :name => image_tag("btn/message_sentbox.png", :class => "menu_icon")+t('message.sentbox'), :url => conversations_path(:box => :sentbox), :remote=> true},
          {:key => :message_trash, :name => image_tag("btn/message_trash.png", :class => "menu_icon")+t('message.trash'), :url => conversations_path(:box => :trash)}
      ]}
    return render_items items
  end

  def render_items(items)
    menu = render_navigation :items => items
    menu = menu.gsub(/\<ul\>/,'<ul class="menu">')
    return raw menu
  end
end
