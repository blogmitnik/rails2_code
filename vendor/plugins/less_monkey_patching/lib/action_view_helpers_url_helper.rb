module ActionView::Helpers::UrlHelper


  alias_method :link_to_original, :link_to
  def link_to name, options = {}, html_options = nil
    replace = html_options && html_options.has_key?(:method) ? true : false
    s = link_to_original name, options, html_options
    s = s.gsub(/href=\".*?\"/,'href="#"') if replace
    s
  end

end
