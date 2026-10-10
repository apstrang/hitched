# QR code for a household's permanent RSVP link (/r/:token). The same image
# is shown in the admin, attached to emails and downloaded for print, so it
# always encodes the public mail host rather than whatever host the admin
# happens to be browsing on.
class RsvpQrCode
  attr_reader :url

  def initialize(invite)
    @url = Rails.application.routes.url_helpers.rsvp_invite_url(
      token: invite.rsvp_token,
      **Rails.application.config.action_mailer.default_url_options
    )
  end

  # Scales to its container (viewBox, no fixed size). White background and a
  # four-module quiet zone so it still scans on the admin's dark theme.
  def svg
    qr.as_svg(module_size: 10, offset: 40, fill: "fff", use_path: true, viewbox: true,
      svg_attributes: { role: "img", "aria-label": "QR code for #{url}" })
  end

  # For embedding straight into an HTML page.
  def inline_svg
    svg.sub(/\A<\?xml[^>]*\?>/, "").html_safe
  end

  def png(size: 600)
    qr.as_png(size: size, border_modules: 4).to_s
  end

  private

  def qr
    @qr ||= RQRCode::QRCode.new(url, level: :m)
  end
end
