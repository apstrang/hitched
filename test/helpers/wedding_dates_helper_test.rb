require "test_helper"

class WeddingDatesHelperTest < ActionView::TestCase
  Day = Struct.new(:date)

  def days(*dates) = dates.map { |d| Day.new(d && Date.parse(d)) }

  test "formats one day, a span within a month, across months and across years" do
    assert_equal "Saturday, September 20, 2025", wedding_dates(days("2025-09-20", "2025-09-20"))
    assert_equal "September 19–21, 2025", wedding_dates(days("2025-09-21", nil, "2025-09-19"))
    assert_equal "September 30 – October 2, 2025", wedding_dates(days("2025-09-30", "2025-10-02"))
    assert_equal "December 31, 2025 – January 1, 2026", wedding_dates(days("2025-12-31", "2026-01-01"))
  end

  test "is nil without dates" do
    assert_nil wedding_dates(days(nil))
    assert_nil wedding_dates([])
  end
end
