class Admin::Financials::ServicePaymentsController < AdminController
  before_action :require_admin

  def index
    @markets = Market.active.sort_service_payment.reject{|m| m.organization.adjunct_organization == true}.map(&:decorate)
  end

  def create
    market = Market.find(params[:market_id])
    organization = Organization.find(params[:organization_id])
    results = ChargeServiceFee.perform(entity: organization, subscription_params: {plan: organization.plan.stripe_id}, flash: flash)

    if results.success?
      market.subscribe!
      market.set_subscription(results.invoice)

      PaymentMadeEmailConfirmation.perform(recipients: market.managers.map(&:pretty_email), payment: results.payment)
      notice = "Payment made for #{market.name}"
    else
      notice = results.context[:error] || "Payment failed for #{market.name}"
    end

    redirect_to admin_financials_service_payments_path, notice: notice
  end
end
