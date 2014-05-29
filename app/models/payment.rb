class Payment < ActiveRecord::Base
  PAYMENT_METHODS = {
    "ach" => "ACH",
    "cash" => "Cash",
    "check" => "Check",
    "credit card" => "Credit Card",
    "purchase order" => "Purchase Order"
  }.freeze

  belongs_to :payee, polymorphic: true
  belongs_to :payer, polymorphic: true

  belongs_to :from_organization, class_name: 'Organization', foreign_key: :payer_id
  belongs_to :from_market, class_name: 'Market', foreign_key: :payer_id

  has_many :order_payments, inverse_of: :payment
  has_many :orders, through: :order_payments, inverse_of: :payments

  scope :refundable, -> { where(status: ['paid', 'pending']) }

  def bank_account
    BankAccount.find_by(balanced_uri: balanced_uri)
  end

  ransacker :update_at_date do |parent|
    Arel.sql("date(updated_at)")
  end
end
