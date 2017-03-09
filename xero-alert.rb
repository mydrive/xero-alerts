#!/usr/bin/env ruby

require "bundler/setup"
require "xero-min"
require "terminal-table"
require "aws-sdk"
require "trollop"

opts = Trollop::options do
  opt :to, "to: email address", default: "po-alerts@mydrivesolutions.com"
  opt :status, "PO state to report", default: "PENDING"
  opt :private_key, "path to private key", default: "./privatekey.pem"
end

XERO_KEY=ENV.fetch("XERO_KEY")
XERO_SECRET=ENV.fetch("XERO_SECRET")

MAX_VALUE_TO_ALERT=5000.0

cli = XeroMin::Client.new( XERO_KEY, XERO_SECRET )
cli.private!( File.expand_path(opts[:private_key]) )

doc = cli.get! "https://api.xero.com/api.xro/2.0/PurchaseOrders?status=#{opts[:status].upcase}"

qualifying_purchase_orders = doc.xpath("//PurchaseOrder").select do |po|
  Float(po.xpath("./Total").text) > MAX_VALUE_TO_ALERT
end.map do |po|
  [
    po.xpath("./UpdatedDateUTC").text,
    po.xpath("./Contact/Name").text,
    po.xpath("./Total").text,
  ]
end

if qualifying_purchase_orders.size > 0
  table = Terminal::Table.new(
    title: "Purchase Orders",
    headings: %w(Date Name Amount),
    rows: qualifying_purchase_orders
  )

  output =<<EOF
<p><h3>Pending Purchase Orders:</h3></p>
<p><pre>#{table}</pre></p>
EOF

  ses = Aws::SES::Client.new
  ses.send_email({
    source: "Pending Purchase Orders <noreply+purchaseorders@mydrivesolutions.com>",
    destination: {
      to_addresses: [ opts[:to] ]
    },
    message: {
      subject: {
        charset: "UTF-8",
        data: "Large POs Awaiting Approval - #{Date.today}"
      },
      body: {
        html: {
          charset: "UTF-8",
          data: output
        }
      }
    }
  })

end
