module ApplicationHelper
  # Options for a meal <select>. Guests only see active options, but an
  # inactive option a guest already picked stays selectable so saving the
  # form doesn't silently clear it.
  def menu_option_choices(selected_id = nil, include_inactive: false)
    scope = include_inactive ? MenuOption.all : MenuOption.active.or(MenuOption.where(id: selected_id))
    options = scope.ordered.map { |o| [ o.active? ? o.name : "#{o.name} (hidden)", o.id ] }
    options_for_select([ [ "Not chosen yet", "" ] ] + options, selected_id)
  end
end
