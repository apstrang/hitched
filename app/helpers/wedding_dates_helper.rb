module WeddingDatesHelper
  # "Saturday, September 20, 2025", "September 19–21, 2025" or
  # "September 30 – October 2, 2025", spanning the given events' dates.
  def wedding_dates(events)
    dates = events.filter_map(&:date).sort
    return if dates.empty?

    first, last = dates.first, dates.last
    if first == last
      first.strftime("%A, %B %-d, %Y")
    elsif first.year != last.year
      "#{first.strftime("%B %-d, %Y")} – #{last.strftime("%B %-d, %Y")}"
    elsif first.month != last.month
      "#{first.strftime("%B %-d")} – #{last.strftime("%B %-d, %Y")}"
    else
      "#{first.strftime("%B %-d")}–#{last.strftime("%-d, %Y")}"
    end
  end
end
