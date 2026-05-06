module RedmineHmCratchmere
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head,
              partial: 'hooks/redmine_hm_cratchmere/html_head'
  end
end
