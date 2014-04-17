class OrganizationDecorator < Draper::Decorator
  include Draper::LazyHelpers
  include MapHelper

  delegate_all

  def locations_map(w=400, h=400)
    addresses = locations.visible.map do |location|
      location.geocode if location
    end.compact

    static_map(addresses, addresses.first, w, h)
  end

  def ship_from_address
    address = shipping_location
    raw "#{address.address}<br/>#{address.city}, #{address.state} #{address.zip}"
  end

  def delivery_schedules
    markets.inject({}) do |result, market|
      result[market] = market.delivery_schedules.visible.order(:day)
      result
    end
  end

  def shipping_address
    shipping_location.address
  end

  def shipping_city_state_zip
    "#{shipping_location.city}, #{shipping_location.state} #{shipping_location.zip}"
  end

  def shipping_phone
    shipping_location.phone
  end
end
