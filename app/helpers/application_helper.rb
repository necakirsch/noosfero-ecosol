# Methods added to this helper will be available to all templates in the
# application.
module ApplicationHelper

  include PermissionName

  include LightboxHelper

  include BoxesHelper

  include FormsHelper
  
  include AssetsHelper

  include BlockHelper
  
  # Displays context help. You can pass the content of the help message as the
  # first parameter or using template code inside a block passed to this
  # method. *Note*: the block is ignored if <tt>content</tt> is not
  # <tt>nil</tt>
  #
  # The method returns the text generated, so you can also use it inside a
  #  <%= ... %>
  #
  # Follow some examples ...
  #
  # Passing the text as argument:
  #
  #  <% help 'This your help message' %>
  #
  # Using a block:
  #
  #  <% help do %>
  #    This is the help message to be displayed. It can contain any HTML you
  #    want: <strong>bold</strong>, <em>italic</em>. It can also contain calls
  #    to any Rails helper, like <%= link_to 'home', :controller => 'home' %>.
  #  <% end %>
  #
  # You can also pass an optional argument to force the use of textile in your
  # help message:
  #
  #  <% help nil, :textile do %>
  #    You can also use *textile*!
  #  <% end %>
  #
  # or, using the return of the method:
  #
  #  <%= help 'this is your help message' %>
  #
  # Formally, the <tt>type</tt> argument can be <tt>:html</tt> (i.e. no
  # conversion of the input) or <tt>:textile</tt> (converts the message, in
  # textile, into HTML). It defaults to <tt>:html</tt>.
  #
  # TODO: implement correcly the 'Help' button click
  def help(content = nil, link_name = nil, options = {}, &block)

    link_name ||= _('Help')

    @help_message_id ||= 1
    help_id = "help_message_#{@help_message_id}"

    if content.nil?
      return '' if block.nil?
      content = capture(&block)
    end

    if options[:type] == :textile
      content = RedCloth.new(content).to_html
    end
    
    options[:class] = '' if ! options[:class]
    options[:class] += ' button icon-help' # with-text

    # TODO: implement this button, and add style='display: none' to the help
    # message DIV
    button = link_to_function(content_tag('span', link_name), "Element.show('#{help_id}')", options )
    close_button = content_tag("div", link_to_function(_("Close"), "Element.hide('#{help_id}')", :class => 'close_help_button'))

    text = content_tag('div', button + content_tag('div', content_tag('div', content) + close_button, :class => 'help_message', :id => help_id, :style => 'display: none;'), :class => 'help_box')

    unless block.nil?
      concat(text, block.binding)
    end

    text
  end

  # alias for <tt>help(content, :textile)</tt>. You can pass a block in the
  # same way you would do if you called <tt>help</tt> directly.
  def help_textile(content = nil, link_name = nil, options = {}, &block)
    options[:type] = :textile
    help(content, link_name, options, &block)
  end

  # TODO: do something more useful here
  # TODO: test this helper
  # TODO: add an icon?
  # TODO: the command rake test:rcov didn't works because of this method. See what it's the problem
  def environment_identification
    content_tag('div', @environment.name, :id => 'environment_identification')
  end

  def link_to_cms(text, profile = nil, options = {})
    profile ||= current_user.login
    link_to text, myprofile_path(:controller => 'cms', :profile => profile), options
  end

  def link_to_profile(text, profile = nil, options = {})
    profile ||= current_user.login
    link_to text, profile_path(:profile => profile) , options
  end

  def link_to_homepage(text, profile = nil, options = {})
    profile ||= current_user.login
    link_to text, homepage_path(:profile => profile) , options
  end

  def link_to_myprofile(text, url = {}, profile = nil, options = {})
    profile ||= current_user.login
    link_to text, { :profile => profile, :controller => 'profile_editor' }.merge(url), options
  end

  def link_to_document(doc, text = nil)
    text ||= doc.title
    path = doc.path.split(/\//)
    link_to text, homepage_path(:profile => doc.profile.identifier , :page => path)
  end

  def link_if_permitted(link, permission = nil, target = nil)
    if permission.nil? || current_user.person.has_permission?(permission, target)
      link
    else
      nil
    end
  end

  def footer
    # FIXME: add some information from the environment
    [
      content_tag('div', _('This is %s, version %s') % [ link_to(Noosfero::PROJECT, 'http://www.noosfero.com.br/'), Noosfero::VERSION]),
    ].join("\n")
  end

  # returns the current profile beign viewed.
  #
  # Make sure that you use this helper method only in contexts where there
  # should be a current profile (i.e. while viewing some profile's pages, or the
  # profile info, etc), because if there is no profile an exception is thrown.
  def profile
    @controller.send(:profile) || raise("There is no current profile")
  end

  # create a form field structure (as if it were generated with
  # labelled_form_for), but with a customized control and label.
  #
  # If +field_id+ is not given, the underlying implementation will try to guess
  # it from +field_html+ using a regular expression. In this case, make sure
  # that the first ocurrance of id=['"]([^'"]*)['"] in +field_html+ if the one
  # you want (i.e. the correct id for the control )
  def labelled_form_field(label, field_html, field_id = nil)
    NoosferoFormBuilder::output_field(label, field_html, field_id)
  end

  alias_method :display_form_field, :labelled_form_field

  def labelled_form_for(name, object = nil, options = {}, &proc)
    object ||= instance_variable_get("@#{name}")
    form_for(name, object, { :builder => NoosferoFormBuilder }.merge(options), &proc)
  end

  class NoosferoFormBuilder < ActionView::Helpers::FormBuilder
    include GetText
    extend ActionView::Helpers::TagHelper

    def self.output_field(text, field_html, field_id = nil)
      # try to guess an id if none given
      if field_id.nil?
        field_html =~ /id=['"]([^'"]*)['"]/
        field_id = $1
      end
      field_html =~ /type=['"]([^'"]*)['"]/
      field_html =~ /<(\w*)/ unless $1
      field_type = $1
      field_class = 'formfield type-' + field_type if field_type

      label_html = content_tag('label', text, :class => 'formlabel', :for => field_id)
      control_html = content_tag('div', field_html, :class => field_class )

      content_tag('div', label_html + control_html, :class => 'formfieldline' )
    end

    (field_helpers - %w(hidden_field)).each do |selector|
      src = <<-END_SRC
        def #{selector}(field, *args, &proc)
          column = object.class.columns_hash[field.to_s]
          text =
            ( column ?
              column.human_name :
              _(field.to_s.humanize)
            )

          NoosferoFormBuilder::output_field(text, super)
        end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end
  end

  def category_color
    if @category.nil?
      ""
    else
      @category.top_ancestor.display_color
    end
  end

  def text_editor(object, method, filter_type_method = nil, options = {})
    text_area(object, method, { :rows => 10, :cols => 64 }.merge(options))
  end

  def file_manager(&block)
    concat(content_tag('div', capture(&block), :class => 'file-manager') + "<br style='clear: left;'/>", block.binding)
  end

  def file_manager_button(title, icon, url)
    content_tag('div', link_to(image_tag(icon, :alt => title, :title => title) + content_tag('div', title), url), :class => 'file-manager-button')
  end

  def hide(id)
    "Element.hide(#{id.inspect});"
  end

  def show(id)
    "Element.show(#{id.inspect});"
  end

  def toggle_panel(hide_label, show_label, id)
    hide_button_id = id + "-hide"
    show_button_id = id + "-show"

    result = ""
    result << button_to_function('open', show_label, show(id) + show(hide_button_id) + hide(show_button_id), :id => show_button_id, :class => 'show-button with-text', :style => 'display: none;' )

    result < " "
    result << button_to_function('close', hide_label, hide(id) + hide(hide_button_id) + show(show_button_id), :id => hide_button_id, :class => 'hide-button with-text')

    result
  end

  def button(type, label, url, html_options = {})
    the_class = "button with-text icon-#{type}"
    if html_options.has_key?(:class)
      the_class << ' ' << html_options[:class]
    end
    link_to(content_tag('span', label), url, html_options.merge(:class => the_class ))
  end

  def submit_button(type, label, html_options = {})
    bt_cancel = html_options[:cancel] ? button(:cancel, _('Cancel'), html_options[:cancel]) : ''

    html_options[:class] = [html_options[:class], 'submit'].compact.join(' ')
    
    the_class = "button with-text icon-#{type}"
    if html_options.has_key?(:class)
      the_class << ' ' << html_options[:class]
    end

    bt_submit = submit_tag(label, html_options.merge(:class => the_class))

    bt_submit
  end

  def button_to_function(type, label, js_code, html_options = {})
    html_options[:class] = "" unless html_options[:class]
    html_options[:class] << " button #{type}"
    link_to_function(label, js_code, html_options)
  end

  def icon(icon_name, html_options = {})
    the_class = "button #{icon_name}"
    if html_options.has_key?(:class)
      the_class << ' ' << html_options[:class]
    end
    content_tag('div', '', html_options.merge(:class => the_class))
  end

  def icon_button(type, text, url, html_options = {})
    the_class = "button icon-button icon-#{type}"
    if html_options.has_key?(:class)
      the_class << ' ' << html_options[:class]
    end

    link_to(content_tag('span', text), url, html_options.merge(:class => the_class, :title => text))
  end

  def button_bar(options = {}, &block)
    concat(content_tag('div', capture(&block) + tag('br', :style => 'clear: left;'), { :class => 'button-bar' }.merge(options)), block.binding)
  end

  def link_to_category(category)
    return _('Uncategorized product') unless category
    link_to category.full_name, :controller => 'category', :action => 'view', :path => category.path.split('/')
  end

  def link_to_product(product)
    return _('No product') unless product
    link_to product.name, :controller => 'catalog', :action => 'show', :id => product, :profile => product.enterprise.identifier
  end

  def partial_for_class(klass)
    name = klass.name.underscore
    if File.exists?(File.join(RAILS_ROOT, 'app', 'views', params[:controller], "_#{name}.rhtml"))
      name
    else
      partial_for_class(klass.superclass)
    end
  end

  def user
    @controller.send(:user)
  end


  def stylesheet_import(*sources)
    options = sources.last.is_a?(Hash) ? sources.pop : { }
    themed_source = options.delete(:themed_source) 
    content_tag(
      'style',
      "\n" +
      sources.flatten.map do |source|
        filename = filename_for_stylesheet(source.to_s, themed_source)
        if File.exists?(File.join(RAILS_ROOT, 'public', filename))
          "@import url(#{filename});\n"
        else
          "/* Not included: url(#{filename}) */\n"
        end
      end.join(),
      { "type" => "text/css" }.merge(options)
    )
  end 

  def filename_for_stylesheet(name, in_theme)
    result = ''
    if in_theme
      result << '/designs/themes/' + current_theme
    end
    result << '/stylesheets/' << name << '.css'
  end

  # FIXME do not hardcode 'default' like this
  def current_theme
    'default'
  end

  # generates a image tag for the profile. 
  #
  # If the profile has no image set yet, then a default image is used.
  def profile_image(profile)
    image_tag(profile_icon(profile), :alt => profile.name(), :title => '' )
  end

  def profile_icon(profile)
    if profile.image
      profile.image.public_filename(:minor)
    else
      if profile.organization?
        if profile.kind_of?(Community)
          'icons-app/users.png'
        else
          'icons-app/gnome-home.png'
        end
      else
        'icons-app/user_icon.png'
      end
    end

  end

  # displays a link to the profile homepage with its image (as generated by
  # #profile_image) and its name below it.
  def profile_image_link(profile)
    link_to( '<div>'+ profile_image(profile) +'</div><span>'+ profile.name() +'</span>', profile.url,
             :help => _('Click on this icon to go to the <b>%s</b>\'s home page') % profile.name )
  end

  def text_field_with_local_autocomplete(name, choices, html_options = {})
    id = html_options[:id] || name

    text_field_tag(name, '', html_options) +
    content_tag('div', '', :id => "autocomplete-for-#{id}", :class => 'auto-complete', :style => 'display: none;') +
    javascript_tag('new Autocompleter.Local(%s, %s, %s)' % [ id.to_json, "autocomplete-for-#{id}".to_json, choices.to_json ] )

  end

end
