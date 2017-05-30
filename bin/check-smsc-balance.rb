#! /usr/bin/env ruby
#
#   handler-smsc.rb
#
# DESCRIPTION:
#   Sensu handler for sending SMS messages through a SMSC gateway.
#
# OUTPUT:
#   None unless there is an error
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-handler
#   gem: smsc
#
# USAGE:
#
#   Configure your SMSC user, and secret here:
#     smsc.json
#
#   Recipients can be a single phone number. Recipients are listed in the checks as an array of
#     one or more of the above.
#     e.g. [ '+380675555555', '+79037777777' ]
#
# NOTES:
#
# LICENSE:
#   Matt Mencel mr-mencel@wiu.edu
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
#   SMSC handler by Maxim Moroz <maxim.moroz@gmail.com>
#

require 'date'
require 'smsc'
require 'timeout'
require 'faraday'

require 'sensu-plugin/check/cli'

class SMSCBalance < Sensu::Plugin::Check::CLI

  check_name 'smsc_balance' # defaults to class name

  def check_balance
      connection = Faraday.new(url: 'https://smsc.ru') do |i|
        i.request  :url_encoded
        i.response :logger
        i.adapter  Faraday.default_adapter
      end
      params = {
        login: api_user,
        psw: api_secret
      }

      resp = connection.post '/sys/balance.php', params
      resp.body.to_i
  end

  def api_user
    settings['smsc']['api_user']
  end

  def api_secret
    settings['smsc']['api_secret']
  end

  def run
    balance = check_balance
    if balance > 200
        ok "All is well"
    elsif balance > 100
        warning "SMSC balance low" 
    else
        critical "SMSC balance critical"
    end
  end

end
