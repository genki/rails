module ActionView #:nodoc:
  class ActionViewError < StandardError #:nodoc:
  end

  class MissingTemplate < ActionViewError #:nodoc:
    attr_reader :path

    def initialize(paths, path, template_format = nil)
      @path = path
      full_template_path = path.include?('.') ? path : "#{path}.erb"
      display_paths = paths.compact.join(":")
      template_type = (path =~ /layouts/i) ? 'layout' : 'template'
      super("Missing #{template_type} #{full_template_path} in view path #{display_paths}")
    end
  end

  # Action View templates can be written in three ways. If the template file has a <tt>.erb</tt> (or <tt>.rhtml</tt>) extension then it uses a mixture of ERb
  # (included in Ruby) and HTML. If the template file has a <tt>.builder</tt> (or <tt>.rxml</tt>) extension then Jim Weirich's Builder::XmlMarkup library is used.
  # If the template file has a <tt>.rjs</tt> extension then it will use ActionView::Helpers::PrototypeHelper::JavaScriptGenerator.
  #
  # = ERb
  #
  # You trigger ERb by using embeddings such as <% %>, <% -%>, and <%= %>. The <%= %> tag set is used when you want output. Consider the
  # following loop for names:
  #
  #   <b>Names of all the people</b>
  #   <% for person in @people %>
  #     Name: <%= person.name %><br/>
  #   <% end %>
  #
  # The loop is setup in regular embedding tags <% %> and the name is written using the output embedding tag <%= %>. Note that this
  # is not just a usage suggestion. Regular output functions like print or puts won't work with ERb templates. So this would be wrong:
  #
  #   Hi, Mr. <% puts "Frodo" %>
  #
  # If you absolutely must write from within a function, you can use the TextHelper#concat.
  #
  # <%- and -%> suppress leading and trailing whitespace, including the trailing newline, and can be used interchangeably with <% and %>.
  #
  # == Using sub templates
  #
  # Using sub templates allows you to sidestep tedious replication and extract common display structures in shared templates. The
  # classic example is the use of a header and footer (even though the Action Pack-way would be to use Layouts):
  #
  #   <%= render "shared/header" %>
  #   Something really specific and terrific
  #   <%= render "shared/footer" %>
  #
  # As you see, we use the output embeddings for the render methods. The render call itself will just return a string holding the
  # result of the rendering. The output embedding writes it to the current template.
  #
  # But you don't have to restrict yourself to static includes. Templates can share variables amongst themselves by using instance
  # variables defined using the regular embedding tags. Like this:
  #
  #   <% @page_title = "A Wonderful Hello" %>
  #   <%= render "shared/header" %>
  #
  # Now the header can pick up on the <tt>@page_title</tt> variable and use it for outputting a title tag:
  #
  #   <title><%= @page_title %></title>
  #
  # == Passing local variables to sub templates
  #
  # You can pass local variables to sub templates by using a hash with the variable names as keys and the objects as values:
  #
  #   <%= render "shared/header", { :headline => "Welcome", :person => person } %>
  #
  # These can now be accessed in <tt>shared/header</tt> with:
  #
  #   Headline: <%= headline %>
  #   First name: <%= person.first_name %>
  #
  # If you need to find out whether a certain local variable has been assigned a value in a particular render call,
  # you need to use the following pattern:
  #
  #   <% if local_assigns.has_key? :headline %>
  #     Headline: <%= headline %>
  #   <% end %>
  #
  # Testing using <tt>defined? headline</tt> will not work. This is an implementation restriction.
  #
  # == Template caching
  #
  # By default, Rails will compile each template to a method in order to render it. When you alter a template, Rails will
  # check the file's modification time and recompile it.
  #
  # == Builder
  #
  # Builder templates are a more programmatic alternative to ERb. They are especially useful for generating XML content. An XmlMarkup object
  # named +xml+ is automatically made available to templates with a <tt>.builder</tt> extension.
  #
  # Here are some basic examples:
  #
  #   xml.em("emphasized")                              # => <em>emphasized</em>
  #   xml.em { xml.b("emph & bold") }                   # => <em><b>emph &amp; bold</b></em>
  #   xml.a("A Link", "href"=>"http://onestepback.org") # => <a href="http://onestepback.org">A Link</a>
  #   xml.target("name"=>"compile", "option"=>"fast")   # => <target option="fast" name="compile"\>
  #                                                     # NOTE: order of attributes is not specified.
  #
  # Any method with a block will be treated as an XML markup tag with nested markup in the block. For example, the following:
  #
  #   xml.div {
  #     xml.h1(@person.name)
  #     xml.p(@person.bio)
  #   }
  #
  # would produce something like:
  #
  #   <div>
  #     <h1>David Heinemeier Hansson</h1>
  #     <p>A product of Danish Design during the Winter of '79...</p>
  #   </div>
  #
  # A full-length RSS example actually used on Basecamp:
  #
  #   xml.rss("version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  #     xml.channel do
  #       xml.title(@feed_title)
  #       xml.link(@url)
  #       xml.description "Basecamp: Recent items"
  #       xml.language "en-us"
  #       xml.ttl "40"
  #
  #       for item in @recent_items
  #         xml.item do
  #           xml.title(item_title(item))
  #           xml.description(item_description(item)) if item_description(item)
  #           xml.pubDate(item_pubDate(item))
  #           xml.guid(@person.firm.account.url + @recent_items.url(item))
  #           xml.link(@person.firm.account.url + @recent_items.url(item))
  #
  #           xml.tag!("dc:creator", item.author_name) if item_has_creator?(item)
  #         end
  #       end
  #     end
  #   end
  #
  # More builder documentation can be found at http://builder.rubyforge.org.
  #
  # == JavaScriptGenerator
  #
  # JavaScriptGenerator templates end in <tt>.rjs</tt>. Unlike conventional templates which are used to
  # render the results of an action, these templates generate instructions on how to modify an already rendered page. This makes it easy to
  # modify multiple elements on your page in one declarative Ajax response. Actions with these templates are called in the background with Ajax
  # and make updates to the page where the request originated from.
  #
  # An instance of the JavaScriptGenerator object named +page+ is automatically made available to your template, which is implicitly wrapped in an ActionView::Helpers::PrototypeHelper#update_page block.
  #
  # When an <tt>.rjs</tt> action is called with +link_to_remote+, the generated JavaScript is automatically evaluated.  Example:
  #
  #   link_to_remote :url => {:action => 'delete'}
  #
  # The subsequently rendered <tt>delete.rjs</tt> might look like:
  #
  #   page.replace_html  'sidebar', :partial => 'sidebar'
  #   page.remove        "person-#{@person.id}"
  #   page.visual_effect :highlight, 'user-list'
  #
  # This refreshes the sidebar, removes a person element and highlights the user list.
  #
  # See the ActionView::Helpers::PrototypeHelper::GeneratorMethods documentation for more details.
  class Base
    include Helpers, Partials, ::ERB::Util
    include ActionPack::Common
    
    extend ActiveSupport::Memoizable

    attr_accessor :base_path, :assigns, :template_extension, :formats
    attr_accessor :controller

    attr_accessor :output_buffer

    class << self
      delegate :erb_trim_mode=, :to => 'ActionView::TemplateHandlers::ERB'
      delegate :logger, :to => 'ActionController::Base'
    end

    @@debug_rjs = false
    ##
    # :singleton-method:
    # Specify whether RJS responses should be wrapped in a try/catch block
    # that alert()s the caught exception (and then re-raises it).
    cattr_accessor :debug_rjs

    attr_internal :request

    delegate :controller_path, :to => :controller, :allow_nil => true

    delegate :request_forgery_protection_token, :template, :params, :session, :cookies, :response, :headers,
             :flash, :logger, :action_name, :controller_name, :to => :controller

    module CompiledTemplates #:nodoc:
      # holds compiled template code
    end
    include CompiledTemplates

    def self.process_view_paths(value)
      ActionView::PathSet.new(Array(value))
    end

    attr_reader :helpers

    class ProxyModule < Module
      def initialize(receiver)
        @receiver = receiver
      end

      def include(*args)
        super(*args)
        @receiver.extend(*args)
      end
    end

    def initialize(view_paths = [], assigns_for_first_render = {}, controller = nil, formats = nil)#:nodoc:
      @formats = formats || [:html]
      @assigns = assigns_for_first_render
      @assigns_added = nil
      @_render_stack = []
      @controller = controller
      @helpers = ProxyModule.new(self)
      self.view_paths = view_paths
    end

    attr_reader :view_paths

    def view_paths=(paths)
      @view_paths = self.class.process_view_paths(paths)
    end

    # Returns the result of a render that's dictated by the options hash. The primary options are:
    #
    # * <tt>:partial</tt> - See ActionView::Partials.
    # * <tt>:update</tt> - Calls update_page with the block given.
    # * <tt>:file</tt> - Renders an explicit template file (this used to be the old default), add :locals to pass in those.
    # * <tt>:inline</tt> - Renders an inline template similar to how it's done in the controller.
    # * <tt>:text</tt> - Renders the text passed in out.
    #
    # If no options hash is passed or :update specified, the default is to render a partial and use the second parameter
    # as the locals hash.
    def render(options = {}, local_assigns = {}, &block) #:nodoc:
      local_assigns ||= {}

      @exempt_from_layout = true

      case options
      when Hash
        options[:locals] ||= {}
        layout = options[:layout]
                
        return _render_partial(layout, options) if options.key?(:partial)
        return _render_partial_with_block(layout, block, options) if block_given?
        
        layout = view_paths.find_by_parts(layout, formats) if layout
        
        if file = options[:file]
          _render_for_parts([file, formats], layout, {:locals => options[:locals]})
        elsif inline = options[:inline]
          _render_inline(inline, layout, options)
        elsif text = options[:text]
          _render_text(text, layout, options)
        end
      when :update
        update_page(&block)
      when String, NilClass
        _render_partial(nil, :partial => options, :locals => local_assigns)
      end
    end
        
    def _render_partial_with_block(layout, block, options)
      @_proc_for_layout = block
      concat(render_partial(options.merge(:partial => layout)))
    ensure
      @_proc_for_layout = nil
    end
        
    def _render_partial(layout, options)
      if layout
        prefix = controller && !layout.include?("/") ? controller.controller_path : nil
        layout = view_paths.find_by_parts(layout, formats, prefix, true)
      end
      content = render_partial(options)
      return _render_content_with_layout(content, layout, options[:locals])
    end
        
    def _render_content_with_layout(content, layout, locals)
      return content unless layout
      
      locals ||= {}

      if controller && layout
        response.layout = layout.path_without_format_and_extension if controller.respond_to?(:response)
        logger.info("Rendering template within #{layout.path_without_format_and_extension}") if logger
      end
      
      begin
        original_content_for_layout = @content_for_layout if defined?(@content_for_layout)
        @content_for_layout = content

        @cached_content_for_layout = @content_for_layout
        layout.render_template(self, locals)
      ensure
        @content_for_layout = original_content_for_layout
      end
    end
        
    def _render_inline(inline, layout, options)
      content = InlineTemplate.new(options[:inline], options[:type]).render(self, options[:locals] || {})
      layout ? _render_content_with_layout(content, layout, options[:locals]) : content
    end

    def _render_text(text, layout, options)
      layout ? _render_content_with_layout(text, layout, options[:locals]) : text
    end
    
    def _render_for_parts(parts, layout, options)
      name, formats, prefix, partial = parts
      template = self.view_paths.find_by_parts(*parts)
      
      _render_for_template(template, layout, options, partial, prefix)
    end
    
    def _render_for_template(template, layout = nil, options = {}, partial = false, prefix = nil)
      if controller && logger
        logger.info("Rendering #{template.path_without_extension}" + 
          (options[:status] ? " (#{options[:status]})" : ''))
      end
      
      if partial
        if spacer = options[:spacer_template]
          spacer = view_paths.find_by_parts(spacer, formats, prefix, partial)
          options[:join] = spacer.render_template(self)
        end
        
        object = partial == true ? nil : partial
        content = template.render_partial_top(self, object, options)
      else
        content = template.render_template(self, options[:locals] || {})
      end
      
      if layout && !template.exempt_from_layout?
        _render_content_with_layout(content, layout, options[:locals] || {})
      else
        content
      end
    end
    
    # Access the current template being rendered.
    # Returns a ActionView::Template object.
    def template
      @_render_stack.last
    end

    private
      # Evaluates the local assigns and controller ivars, pushes them to the view.
      def _evaluate_assigns_and_ivars #:nodoc:
        unless @assigns_added
          @assigns.each { |key, value| instance_variable_set("@#{key}", value) }
          _copy_ivars_from_controller
          @assigns_added = true
        end
      end

      def _copy_ivars_from_controller #:nodoc:
        if @controller
          variables = @controller.instance_variable_names
          variables -= @controller.protected_instance_variables if @controller.respond_to?(:protected_instance_variables)
          variables.each { |name| instance_variable_set(name, @controller.instance_variable_get(name)) }
        end
      end

      def _set_controller_content_type(content_type) #:nodoc:
        if controller.respond_to?(:response)
          controller.response.content_type ||= content_type
        end
      end
  end
end
