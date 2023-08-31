require 'cgi/escape'

module FormHelper
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
      if object[field_name].nil?
        false
      elsif field_name =~ /\[.*\]/ && value
        object[field_name].split(',').include?(value.to_s)
      else
        object[field_name] == "true"
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
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : 'mb-3'
    control_class = "form-check-input #{opts.delete(:control_class)}".strip
    html = <<~HTML
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

    html = '<div class="form-check mb-0">'
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
    type = opts.delete(:type) || 'text'
    value = opts.delete(:value)
    placeholder = opts.delete(:placeholder)

    html = ""
    field_value = value || object_field_value(object, field_name)
    html << %{<input type="#{type}" name="#{field_name}" id="#{id_name}" value="#{field_value}"}
    html << %{ #{:disabled if disabled} #{:readonly if readonly} #{"placeholder='#{placeholder}'" if placeholder}}
    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << "/>"
    html
  end

  private def field_classes(object, field_name, custom_classes)
    classes = "form-control"

    classes << ' ' << custom_classes if custom_classes
    classes << ' is-invalid' if object&.hasFieldErrors(field_name.to_s)
    classes
  end

  private def select_classes(object, field_name, custom_classes)
    classes = "form-select"

    classes << ' ' << custom_classes if custom_classes
    classes << ' is-invalid' if object&.hasFieldErrors(field_name.to_s)
    classes
  end

  def bootstrap_text_input(object, field_name, **opts)
    classes = field_classes(object, field_name, opts.delete(:class))
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_key = label_key_opt(opts, field_name)
    hide_label_suffix = opts.key?(:hide_label_suffix) ? opts.delete(:hide_label_suffix) : true
    label_suffix = hide_label_suffix ? nil : ':'
    label = opts.delete(:label) || "#{message[label_key]}#{label_suffix}"
    label_class = opts.delete(:label_class) || 'form-label'
    label_style = opts.delete(:label_style)
    append = opts.delete(:append)
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : 'mb-3'

    if hide_label
      html = ''
    else
      label = label == '' ? '&nbsp;' : CGI.escapeHTML(label)
      html = %{<label for="#{field_name}" class="#{label_class}"}
      html << %{ style="#{label_style}"} if label_style
      html << %{>#{label}</label> }
    end
    html << %{<div class="input-group flex-nowrap" >} if append
    html << text_input(object, field_name, class: classes, no_break: true, **opts)
    if append
      if append.include?('btn')
        html << append
      else
        html << %{<span class="input-group-text">#{append}</span>}
      end
      html << '</div>'
    end
    <<~HTML
      <div class="#{wrapper_class}">#{html}</div>
    HTML
  end

  def hidden_input(object, field_name, **opts)
    id_name = opts.delete(:id) || field_name

    field_value = object_field_value(object, field_name)

    html = %{<input type="hidden" name="#{field_name}" id="#{id_name}" value="#{field_value}"}

    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << "/>"
    html
  end

  alias hidden_field hidden_input

  def textarea(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_style = opts.delete(:label_style)
    label_key = label_key_opt(opts, field_name)
    label_suffix = opts.delete(:hide_label_suffix) ? nil : ':'
    label = opts.delete(:label) || "#{message[label_key]}#{label_suffix}"
    id_name = opts.delete(:id) || field_name
    no_break = opts.delete(:no_break) || opts.delete(:inline)
    appendix = opts.delete(:append)
    disabled = opts.delete(:disabled)

    if hide_label
      html = ""
    else
      html = %{<label for="#{field_name}" style="#{label_style}">#{CGI.escapeHTML(label)}</label> }
    end

    html << '<span>' if appendix

    html << %{<textarea name="#{field_name}" id="#{id_name}" #{:disabled if disabled}}

    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << ">"
    html << object[field_name]
    html << "</textarea>"
    html << "<label for='#{id_name}' style='width:auto'>#{appendix}</label></span>" if appendix
    html << "<br/>" unless no_break
    html
  end

  def bootstrap_textarea(object, field_name, **opts)
    classes = field_classes(object, field_name, opts.delete(:class))
    textarea(object, field_name, hide_label_suffix: true, class: classes, no_break: true, **opts)
  end

  private def object_field_value(object, field_name)
    return '' unless object
    (object.respond_to?(:[]) ? object[field_name.to_sym] : object.send(field_name)).to_s.strip
  end

  def select_input(object, field_name, option_map = [], **opts)
    id_name = opts.delete(:id) || field_name
    no_break = opts.delete(:no_break) || opts.delete(:inline)
    prompt = opts.delete(:prompt)
    appendix = opts.delete(:append)
    disabled = opts.delete(:disabled)
    multiple = opts.delete(:multiple)
    ondblclick = opts.delete(:ondblclick)
    addon = opts.delete(:addon)

    html = ''
    html << '<span>' if appendix
    html << %{<div class="input-group flex-nowrap" >} if addon

    html << %{<select name="#{field_name}" id="#{id_name}" #{:disabled if disabled} #{:multiple if multiple} }
    if prompt
      html << %{ data-placeholder='#{TrueClass === prompt ? '' : CGI.escapeHTML(prompt.to_s)}'}
      html << %{ data-allow-clear='true'}
    end
    opts.each do |key, value|
      html << %{ #{key}="#{value}"}
    end
    html << ">"

    field_value = object_field_value(object, field_name)

    if prompt
      html << %{<option value="">}
      if field_value.empty?
        html << %{#{TrueClass === prompt ? '' : CGI.escapeHTML(prompt.to_s)}</option>}
      else
        html << "(#{message['text.none']})"
      end
      html << "</option>"
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

    html << "#{addon}</div>" if addon
    html << "<br/>" unless no_break
    html
  end

  alias select_field select_input

  def bootstrap_select_input(object, field_name, option_map = [], **opts, &block)
    opts[:id] ||= field_name
    classes = select_classes(object, field_name, opts.delete(:class))
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_style = opts.delete(:label_style)
    label_class = opts.delete(:label_class) || 'form-label'
    label_key = label_key_opt(opts, field_name)
    hide_label_suffix = opts.key?(:hide_label_suffix) ? opts.delete(:hide_label_suffix) : true
    label_suffix = hide_label_suffix ? nil : ':'
    label = opts.delete(:label) || "#{message[label_key]}#{label_suffix}"
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : 'mb-3'

    if hide_label
      html = ""
    else
      html = %{<label for="#{opts[:id]}" class="#{label_class}" style="#{label_style}">#{CGI.escapeHTML(label)}</label>}
    end

    html << select_input(object, field_name, option_map, class: classes, no_break: true, **opts, &block)
    <<~HTML
      <div class="#{wrapper_class}">#{html}</div>
    HTML
  end

  # Will only work with Bootstrap
  def datetime_input(object, field_name, **opts)
    hide_label = opts.delete(:hide_label) || opts.delete(:no_label)
    label_class = opts.delete(:label_class) || 'form-label'
    label_style = opts.delete(:label_style)
    input_group_style = opts.delete(:input_group_style)
    label_key = label_key_opt(opts, field_name)
    id_name = opts.delete(:id) || field_name
    classes = opts.delete(:class)
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : 'mb-3'
    wrapper_classes = opts.delete(:wrapper_class)

    if hide_label
      html = ""
    else
      html = %{<label for="#{field_name}" class="#{label_class}" style="#{label_style}">#{message[label_key]}</label> }
    end

    html << %{<div class="input-group flex-nowrap #{wrapper_classes}"}
    if input_group_style
      html << %{style="#{input_group_style}"}
    end
    html << '>'

    html << %{<input type="text" name="#{field_name}" class="form-control datetime #{classes}" id="#{id_name}" value="#{object_field_value(object, field_name)}" style="min-width: 10.1rem;" }
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
    text_input object, field_name, **{ label_class: "date-label", size: 10, style: 'min-width:7rem' }.merge(opts)
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
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : 'mb-3'

    if hide_label
      html = ""
    else
      html = %{<label for="#{field_name}" class="#{label_class}" style="#{label_style}">#{message[label_key]}</label> }
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

    html = <<-END_HTML
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
    wrapper_class = opts.key?(:wrapper_class) ? opts.delete(:wrapper_class) : 'mb-3'

    if hide_label
      html = ""
    else
      html = %{<label for="#{field_name}" class="#{label_class}" style="#{label_style}">#{message[label_key]}</label> }
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

  def label_key_opt(opts, field_name)
    opts.delete(:label_key) || ["field.#{field_name}", "label.#{field_name}", field_name, "text.#{field_name}"]
  end
end
