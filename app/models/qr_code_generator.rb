require "rqrcode"

class QrCodeGenerator
  def self.call(url)
    qrcode = RQRCode::QRCode.new(url)
    qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 11,
      standalone: true,
      use_path: true
    )
  end
end
