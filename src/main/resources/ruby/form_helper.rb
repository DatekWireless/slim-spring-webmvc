# frozen_string_literal: true

require 'cgi/escape'

module FormHelper
  WRAPPER_CLASS = 'mb-2 mb-lg-3'

  def checkbox(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_key = label_key_opt(opts, field_name)
    label_style = opts.delete(:label_style)
    label_class = opts.delete(:label_class)
    label_suffix = opts.delete(:hide_label_suffix) ? nil : ':'
    label = opts.delete(:label) || "#{message[label_key]}#{label_suffix}"
    id_name = opts.delete(:id) || field_name
    no_hidden = opts.delete(:no_hidden)
    value = opts[:value]
    no_break = opts.key?(:no_break) || opts.key?(:inline) ? opts.delete(:no_break) || opts.delete(:inline) : true
    appendix = opts.delete(:append)
    disabled = opts.delete(:disabled)

    checked =
      if opts.key?(:checked)
        opts.delete(:checked)
      else
        if object&.[](field_name).nil?
          false
        elsif field_name =~ /\[.*\]/ && value
          object[field_name].split(',').include?(value.to_s)
        else
          object[field_name] == "true"
        end
      end
    html = +''
    unless no_hidden
      html << %{<input type="hidden" name="_#{field_name}" value="false" />}
    end
    html << %{<input type="checkbox" name="#{field_name}" id="#{id_name}" #{'checked="checked"' if checked} #{:disabled if disabled}}
    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << "/>"

    unless hide_label
      html << %{<label for="#{id_name}" class="#{label_class}"}
      html << %{ style="#{label_style}"} if label_style
      html << %{>#{CGI.escapeHTML(label)}</label>}
    end
    if appendix
      html << "<label for='#{id_name}' style='float:none;width:auto;display:inline;margin-left:0.5rem'>#{appendix}</label>"
    end
    html << "<br/>" unless no_break

    html
  end

  def bootstrap_checkbox(object, field_name, **opts)
    group_label = opts.key?(:group_label) ? opts.delete(:group_label) : '&nbsp;'
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : WRAPPER_CLASS
    control_class = "form-check-input #{opts.delete(:control_class)}".strip
    html = +<<~HTML
      <div class="form-check #{'py-2' if group_label && wrapper_class}">
        #{checkbox(object, field_name, hide_label_suffix: true, label_class: "form-check-label", class: control_class, **opts)}
      </div>
    HTML

    html.prepend(%{<label class="form-label d-none d-md-block">#{group_label}</label>}) if group_label

    if wrapper_class
      <<~HTML
        <div class="#{wrapper_class}">
          #{html}
        </div>
      HTML
    else
      html
    end
  end

  def custom_checkbox(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_key = label_key_opt(opts, field_name)
    label_style = opts.delete(:label_style)
    label_class = opts.delete(:label_class)
    label = opts.delete(:label) || "#{message[label_key]}"
    id_name = opts.delete(:id) || field_name
    no_hidden = opts.delete(:no_hidden)
    value = opts[:value]
    no_break = opts.delete(:no_break) || opts.delete(:inline)
    appendix = opts.delete(:append)
    disabled = opts.delete(:disabled)

    checked =
      if object[field_name].nil?
        false
      elsif field_name =~ /\[.*\]/ && value
        object[field_name].split(',').include?(value.to_s)
      else
        object[field_name] == "true"
      end

    html = +'<div class="form-check mb-0">'
    html << %{<input type="checkbox" class="form-check-input" name="#{field_name}" id="#{id_name}" #{'checked="checked"' if checked} #{:disabled if disabled}}
    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << "/>"
    unless no_hidden
      html << %{<input type="hidden" name="_#{field_name}" value="false" />}
    end

    unless hide_label
      html << %{<label class="form-check-label" for="#{id_name}" class="#{label_class}" style="#{label_style}">#{CGI.escapeHTML(label)}</label>}
    end
    if appendix
      html << "<label class='form-check-label' for='#{id_name}' style='float:none;width:auto;display:inline;margin-left:0.5rem'>#{appendix}</label>"
    end
    html << "<br/>" unless no_break
    html << '</div>'

    html
  end

  def text_input(object, field_name, **opts)
    id_name = opts.delete(:id) || field_name.to_s.gsub('.', '_')
    disabled = opts.delete(:disabled)
    readonly = opts.delete(:readonly)
    required = opts.delete(:required)
    type = opts.delete(:type) || 'text'
    value = opts.delete(:value)
    placeholder = opts.delete(:placeholder)

    html = +""
    field_value = value || object_field_value(object, field_name)
    html << %{<input type="#{type}" name="#{field_name}" id="#{id_name}" value="#{field_value}"}
    html << %{ #{:disabled if disabled} #{:readonly if readonly} #{:required if required} #{"placeholder='#{placeholder}'" if placeholder}}
    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << "/>"
    html
  end

  private def field_classes(object, field_name, custom_classes)
    classes = +"form-control"

    classes << ' ' << custom_classes if custom_classes
    classes << ' is-invalid' if object.try(:hasFieldErrors, field_name.to_s)
    classes
  end

  private def select_classes(object, field_name, custom_classes)
    classes = +"form-select"

    classes << ' ' << custom_classes if custom_classes
    classes << ' is-invalid' if object.try(:hasFieldErrors, field_name.to_s)
    classes
  end

  def bootstrap_text_field(object, field_name, **opts)
    classes = field_classes(object, field_name, opts.delete(:class))
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_key = label_key_opt(opts, field_name)
    hide_label_suffix = opts.key?(:hide_label_suffix) ? opts.delete(:hide_label_suffix) : true
    label_suffix = hide_label_suffix ? nil : ':'
    label = opts.delete(:label) || "#{message[label_key]}#{label_suffix}"
    label_class = opts.delete(:label_class) || 'form-label'
    label_style = opts.delete(:label_style)
    append = opts.delete(:append)
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : WRAPPER_CLASS
    required = opts[:required]

    if hide_label
      html = +''
    else
      label = label == '' ? +'&nbsp;' : CGI.escapeHTML(label)
      html = +%{<label for="#{field_name}" class="#{label_class} #{:required if required}"}
      html << %{ style="#{label_style}"} if label_style
      html << %{>#{label}</label> }
    end
    html << %{<div class="input-group flex-nowrap" >} if append
    html << text_input(object, field_name, class: classes, no_break: true, **opts)
    if append
      [*append].compact.each do |addon|
        if addon.start_with?('<')
          html << addon
        else
          html << %{<span class="input-group-text">#{addon}</span>}
        end
      end
      html << '</div>'
    end
    if wrapper_class.present?
      html = <<~HTML
        <div class="#{wrapper_class}">#{html}</div>
      HTML
    end
    html
  end

  alias bootstrap_text_input bootstrap_text_field

  def hidden_input(object, field_name, **opts)
    id_name = opts.delete(:id) || field_name

    field_value = object_field_value(object, field_name)

    html = +%{<input type="hidden" name="#{field_name}" id="#{id_name}" value="#{field_value}"}

    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << "/>"
    html
  end

  alias hidden_field hidden_input

  def textarea(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_class = opts.delete(:label_class)
    label_style = opts.delete(:label_style)
    label_key = label_key_opt(opts, field_name)
    label_suffix = opts.delete(:hide_label_suffix) ? nil : ':'
    label = opts.delete(:label) || "#{message[label_key]}#{label_suffix}"
    id_name = opts.delete(:id) || field_name
    no_break = opts.delete(:no_break) || opts.delete(:inline)
    appendix = opts.delete(:append)
    disabled = opts.delete(:disabled)

    if hide_label
      html = +""
    else
      html = +%{<label for="#{field_name}" class="#{label_class}" style="#{label_style}">#{CGI.escapeHTML(label)}</label> }
    end

    html << '<span>' if appendix

    html << %{<textarea name="#{field_name}" id="#{id_name}" #{:disabled if disabled}}

    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << ">"
    html << (object.try(field_name) || object.try(:[], field_name)).to_s
    html << "</textarea>"
    html << "<label for='#{id_name}' style='width:auto'>#{appendix}</label></span>" if appendix
    html << "<br/>" unless no_break
    html
  end

  def bootstrap_textarea(object, field_name, **opts)
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : WRAPPER_CLASS
    label_class = opts.delete(:label_class) || 'form-label'
    classes = field_classes(object, field_name, opts.delete(:class))
    html = textarea(object, field_name, hide_label_suffix: true, class: classes, no_break: true, label_class:, **opts)
    if wrapper_class.present?
      html = <<~HTML
        <div class="#{wrapper_class}">#{html}</div>
      HTML
    end
    html
  end

  private def object_field_value(object, field_name)
    return '' unless object
    (object.respond_to?(:[]) ? object[field_name.to_sym] : object.send(field_name)).to_s.strip
  end

  def select_field(object, field_name, option_map = [], **opts)
    id_name = opts.delete(:id) || field_name
    no_break = opts.delete(:no_break) || opts.delete(:inline)
    prompt = opts.delete(:prompt)
    include_blank = opts.delete(:include_blank)
    appendix = opts.delete(:append)
    disabled = opts.delete(:disabled)
    multiple = opts.delete(:multiple)
    ondblclick = opts.delete(:ondblclick)
    selected = opts.delete(:selected) || '' if opts.key?(:selected)

    uses_select2 = opts[:class] =~ /chosen-select|select2/

    html = +''
    html << '<span>' if appendix

    html << %{<select name="#{field_name}" id="#{id_name}" #{:disabled if disabled} #{:multiple if multiple} }
    if uses_select2 && prompt
      html << %{ data-placeholder='#{TrueClass === prompt ? message['pleaseSelect'] : CGI.escapeHTML(prompt.to_s)}'}
      html << %{ data-allow-clear='true'}
    end
    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << ">"

    field_value = selected&.to_s&.strip || object_field_value(object, field_name)

    unless uses_select2 && multiple
      if field_value.blank? && prompt
        html << %{<option value="">#{TrueClass === prompt ? message['pleaseSelect'] : CGI.escapeHTML(prompt.to_s)}</option>}
      elsif include_blank
        html << %{<option value="">#{TrueClass === include_blank ? "" : CGI.escapeHTML(include_blank.to_s)}</option>}
      end
    end

    selected_values = multiple ? field_value.split(',') : [field_value]
    option_map.each do |value, label = value|
      html << %{<option value="#{value}"}
      html << %{ ondblclick="#{ondblclick}"} if ondblclick
      if selected_values.include?(value.to_s.strip)
        html << %{ selected="selected"}
      end
      html << %{>#{CGI.escapeHTML(label.to_s)}</option>}
    end

    html << yield if block_given?

    html << "</select>"

    html << "<span for='#{id_name}' style='width:auto;float:inherit;display:inline;margin-left:.25rem'>#{appendix}</span></span>" if appendix
    if multiple && !disabled
      html << %{<input type="hidden" name="_#{field_name}" value="" />}
    end

    html << "<br/>" unless no_break
    html
  end

  alias select_input select_field

  def bootstrap_select(object, field_name, option_map = [], **opts, &block)
    opts[:id] ||= field_name
    classes = select_classes(object, field_name, opts.delete(:class))
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_style = opts.delete(:label_style)
    label_class = opts.delete(:label_class) || 'form-label'
    label_key = label_key_opt(opts, field_name)
    hide_label_suffix = opts.key?(:hide_label_suffix) ? opts.delete(:hide_label_suffix) : true
    label_suffix = hide_label_suffix ? nil : ':'
    label = opts.delete(:label) || "#{message[label_key]}#{label_suffix}"
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : WRAPPER_CLASS
    append = opts.delete(:append)

    if hide_label || wrapper_class.blank?
      html = +""
    else
      html = +%{<label for="#{opts[:id]}" class="#{label_class}" style="#{label_style}">#{CGI.escapeHTML(label)}</label>}
    end

    html << %{<div class="input-group flex-nowrap" >} if append
    html << select_field(object, field_name, option_map, class: classes, no_break: true, **opts, &block)
    if append
      [*append].compact.each do |addon|
        if addon.start_with?('<')
          html << addon
        else
          html << %{<span class="input-group-text">#{addon}</span>}
        end
      end
      html << '</div>'
    end
    if wrapper_class.present?
      html = <<~HTML
        <div class="#{wrapper_class}">#{html}</div>
      HTML
    end
    html
  end

  alias bootstrap_select_field bootstrap_select
  alias bootstrap_select_input bootstrap_select

  # Will only work with Bootstrap
  def datetime_input(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_class = opts.delete(:label_class) || 'form-label'
    label_style = opts.delete(:label_style)
    input_group_style = opts.delete(:input_group_style)
    label_key = label_key_opt(opts, field_name)
    id_name = opts.delete(:id) || field_name
    classes = opts.delete(:class)
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : WRAPPER_CLASS
    wrapper_classes = opts.delete(:wrapper_class)

    if hide_label
      html = +""
    else
      html = +%{<label for="#{field_name}" class="#{label_class}" style="#{label_style}">#{message[label_key]}</label> }
    end

    html << %{<div class="input-group flex-nowrap #{wrapper_classes}"}
    if input_group_style
      html << %{style="#{input_group_style}"}
    end
    html << '>'

    html << %{<input type="text" name="#{field_name}" class="form-control datetime #{classes}" id="#{id_name}" value="#{object_field_value(object, field_name)}"}
    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << "/>"

    unless opts[:disabled]
      html << %{<label for="#{id_name}"  class="input-group-text">}
      html << %{<span class="input-group-addon"><i class="far fa-calendar-alt"></i></span>}
      html << %{</label>}
    end
    html << %{</div>}

    <<~HTML
      <div class="#{wrapper_class}">#{html}</div>
    HTML
  end

  def date_input(object, field_name, **opts)
    text_input object, field_name, **{ label_class: "date-label", size: 10}.merge(opts)
  end

  def bootstrap_date_input(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_class = opts.delete(:label_class) || 'form-label'
    label_style = opts.delete(:label_style)
    input_group_style = opts.delete(:input_group_style)
    label_key = label_key_opt(opts, field_name)
    id_name = opts.delete(:id) || field_name
    classes = opts.delete(:class)
    max_date = opts.delete(:max_date)
    min_date = opts.delete(:min_date)
    invalid_input = opts.delete(:invalid_input)
    value = opts.delete(:value)
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : WRAPPER_CLASS

    if hide_label
      html = +""
    else
      html = +%{<label for="#{field_name}" class="#{label_class}" style="#{label_style}">#{message[label_key]}</label> }
    end

    html << %{<div class="input-group flex-nowrap"}
    if input_group_style
      html << %{style="#{input_group_style}"}
    end
    html << '>'

    field_value = value || object_field_value(object, field_name)

    opts['data-max-date'] = max_date if max_date
    opts['data-min-date'] = min_date if min_date
    html << date_input(object, field_name, class: "form-control date #{classes} #{"is-invalid" if invalid_input}", id: "#{id_name}", value: "#{field_value}", **opts)

    unless opts[:disabled]
      html << %{<label for="#{id_name}"  class="input-group-text">}
      html << %{<span class="input-group-addon"><i class="far fa-calendar-alt"></i></span>}
      html << %{</label>}
    end

    if invalid_input
      html << %{<div class="invalid-feedback">#{invalid_input}</div>}
    end
    html << %{</div>}
    <<~HTML
      <div class="#{wrapper_class}">#{html}</div>
    HTML
  end

  def bootstrap_tristate_checkbox(object, field_name, **opts)
    # disabled = opts.delete(:disabled)
    no_break = opts.delete(:no_break) || opts.delete(:inline)

    field_value = object[field_name]
    is_on = field_value.nil? ? nil : field_value == "true"

    html = +<<-END_HTML
    <div class="tri-state-wrapper">
      <input type="radio" name="#{field_name}" class="tri-state-yes" id="yes-#{field_name}" value="true" #{"checked='true'" if is_on} />
      <label for="yes-#{field_name}">
        <i class="fas fa-check"></i>
      </label>
    
      <input type="radio" name="#{field_name}" class="tri-state-no" id="no-#{field_name}" value="false" #{"checked='true'" if is_on == false} />
      <label for="no-#{field_name}">
        <i class="fas fa-times"></i>
      </label>

      <input type="radio" name="#{field_name}" class="tri-state-neutral" id="neutral-#{field_name}" value="" #{"checked='true'" if is_on.nil?} />
      <label for="neutral-#{field_name}">
        <i class="fas fa-minus"></i>
      </label>
    </div>
    END_HTML

    html << "<br/>" unless no_break

    html
  end

  def bootstrap_file_field(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_class = opts.delete(:label_class) || 'form-label'
    label_style = opts.delete(:label_style)
    label_key = label_key_opt(opts, field_name)
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : WRAPPER_CLASS

    if hide_label
      html = +""
    else
      html = +%{<label for="#{field_name}" class="#{label_class}" style="#{label_style}">#{message[label_key]}</label> }
    end

    html << <<~HTML
      <div class="input-group">
        <input type="file" class="form-control" id=#{field_name} name=#{field_name} accept="image/*" />
        <label class="form-label" for=#{field_name} />
      </div>
    HTML
    <<~HTML
      <div class="#{wrapper_class}">#{html}</div>
    HTML
  end

  JS_ESCAPE_MAP =   { "\\" => "\\\\", "</" => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'", "`" => "\\`", "$" => "\\$" }.freeze

  def escape_javascript(javascript)
    javascript = javascript.to_s
    if javascript.empty?
      ""
    else
      javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"']|[`]|[$])/u, JS_ESCAPE_MAP)
    end
  end

  private

  MESSAGE_PREFIXES = ['field', 'label', nil, 'text'].freeze
  ID_BASE_PATTERN = /^.*(?=(?:I|_i)d$)/.freeze

  def label_key_opt(opts, field_name)
    key = opts.delete(:label_key)
    if key.nil?
      key = MESSAGE_PREFIXES.map{|prefix| "#{"#{prefix}." if prefix}#{field_name}"}
      if (base_name = field_name[ID_BASE_PATTERN])
        key += MESSAGE_PREFIXES.map{|prefix| "#{"#{prefix}." if prefix}#{base_name}"}
      end
    end
    key
  end
end
