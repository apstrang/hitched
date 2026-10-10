require "test_helper"

class RsvpQrCodeTest < ActiveSupport::TestCase
  setup { @qr = invites(:smiths).rsvp_qr_code }

  test "encodes the permanent link on the mail host" do
    assert_equal "http://example.com/r/smithsToken0000000000000", @qr.url
  end

  test "renders a scalable SVG with a white background" do
    assert_match %r{\A<\?xml}, @qr.svg
    assert_match %r{<svg[^>]*viewBox="0 0 \d+ \d+"}, @qr.svg
    assert_match %r{<rect[^>]*fill="#fff"}, @qr.svg
    assert_match %r{\A<svg}, @qr.inline_svg
  end

  test "renders a PNG" do
    png = @qr.png(size: 300)
    assert png.start_with?("\x89PNG".b)
  end
end
