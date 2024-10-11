##
# A wrapper for a Stripe::Price
#
class AlaveteliPro::Price < SimpleDelegator
  include Taxable

  tax :unit_amount

  def self.list
    AlaveteliConfiguration.stripe_prices.inject([]) do |arr, (_key, id)|
      arr << retrieve(id)
      arr
    end
  end

  def self.retrieve(id)
    key = AlaveteliConfiguration.stripe_prices.key(id)
    new(Stripe::Price.retrieve(key))
  rescue Stripe::InvalidRequestError
    nil
  end

  def to_param
    AlaveteliConfiguration.stripe_prices[id]
  end

  # product
  def product
    @product ||= (
      product_id = __getobj__.product
      Stripe::Product.retrieve(product_id) if product_id
    )
  end
end
