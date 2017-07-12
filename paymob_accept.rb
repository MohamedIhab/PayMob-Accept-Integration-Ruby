
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'irb/frame'


module PaymobAccept

  # INPUT: merchant's credentials
  # OUTPUT: authentication token , merchant id
  def self.authentication_token_request(username, password)
    payload = { username: username, password: password, expiration: 3600 }.to_json
    uri = URI.parse('https://accept.paymobsolutions.com/api/auth/tokens')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = payload.to_s
    response = https.request(request)
    res = JSON.parse(response.body.to_s)
    final_response = {}
    final_response['token'] = res['token']
    final_response['merchant_id'] = res['profile']['id']
    return final_response
  end

  # INPUT: return output from authentication method + amount + currency + shipping_info. The items, merchant order id,
  # delivery need are optional fields.
  # OUTPUT: order id
  def self.create_order(previous_response, amount, currency, shipping_info,
      items=nil, merchant_order_id=nil, delivery_needed=nil)
    payload = { delivery_needed: delivery_needed,
                merchant_id: previous_response['merchant_id'],
                amount_cents: amount,
                currency: currency,
                items: [],
                shipping_data: shipping_info }
    uri = URI.parse('https://accept.paymobsolutions.com/api/ecommerce/orders')
    unless merchant_order_id.nil?
      payload['merchant_order_id'] = merchant_order_id
    end
    unless items.nil?
      payload['items'] = items
    end
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = payload.to_s
    request.add_field('token', previous_response['token'])
    response = https.request(request)
    res = JSON.parse(response.body.to_s)
    previous_response['order_id'] = res['id']
    previous_response['amount'] = amount
    previous_response['currency'] = currency
    return previous_response
  end

  # INPUT: return output from order creation method + merchant's card integration ID + client's billing information
  # OUTPUT: payment key token
  def self.generate_payment_key(previous_response, card_integration_id, billing_info)
    payload = { amount_cents: previous_response['amount'], currency: previous_response['currency'],
                card_integration_id: card_integration_id, order_id: previous_response['order_id'],
                billing_data: billing_info }
    uri = URI.parse('https://accept.paymobsolutions.com/api/acceptance/payment_keys')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path,'Content-Type' => 'application/json')
    request.body = payload.to_s
    request.add_field('token', previous_response['token'])
    response = https.request(request)
    res = JSON.parse(response.body.to_s)
    previous_response['payment_key'] = res['token']
    return previous_response
  end

end



