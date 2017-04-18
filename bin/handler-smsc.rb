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
require 'sensu-handler'
require 'timeout'

# smscSMS Handler
class SmscAlert < Sensu::Handler
  def send_sms(recipients, msg)
    client = Smsc::Sms.new(api_user, api_secret)
    client.message(msg, recipients)
  end

  def api_user
    settings['smsc']['api_user']
  end

  def api_secret
    settings['smsc']['api_secret']
  end

  def action_to_string
    @event['action'].eql?('resolve') ? 'RESOLVED' : 'ALERT'
  end

  def executed_at
    Time.at(@event['check']['executed']).to_datetime
  end

  def msg
    "#{action_to_string} - #{short_name}: #{output} #{executed_at}"
  end

  def output
    @event['check']['output'].strip
  end

  def recipients
    @event['check']['smsc']['recipients']
  end

  def short_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def handle
    Timeout.timeout 10 do
      send_sms(recipients, msg)
      puts 'smsc -- sent alert for ' + short_name + ' to ' + recipients
    end
  rescue Timeout::Error
    puts 'smsc -- timed out while attempting to ' + action_to_string + ' an incident -- '\
         '(TO: ' + settings['smsc']['recipients'] + ' SUBJ: ' + subject + ')' + short_name
  end
end
