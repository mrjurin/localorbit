class OrderDecorator < Draper::Decorator
  delegate_all

  def display_delivery_or_pickup
    delivery.delivery_schedule.buyer_pickup? ? "can be picked up at:" : "will be delivered to:"
  end

  def display_fulfillment_info
    delivery.delivery_schedule.buyer_pickup? ? "Buyer picks up from market on" : "Market delivers to buyer on"
  end

  def display_delivery_address
    "#{delivery_address}<br> #{delivery_city}, #{delivery_state} #{delivery_zip}".html_safe
  end

  def display_delivery_street
    delivery_address
  end

  def display_delivery_city_state_zip
    "#{delivery_city}, #{delivery_state} #{delivery_zip}"
  end

  def display_delivery_phone
    delivery_phone
  end

  def display_market_street
    market_address.address if market_address
  end

  def display_market_city_state_zip
    "#{market_address.city}, #{market_address.state} #{market_address.zip}" if market_address
  end

  def display_market_phone
    market_address.phone if market_address
  end

  def market_address
    market.addresses.visible.first
  end

  def display_refund
    @refund ||= begin
      refund = refund_after_changes
      number_to_currency(refund) if refund && refund > 0
    end
  end

  def refund_after_changes
    total_cost_update = audits.last.audited_changes["total_cost"]
    if total_cost_update.present?
      total_cost[0] - total_cost[1]
    else
      false
    end
  end
end
