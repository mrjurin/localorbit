module PaymentProvider
  module Handlers
    class AsyncHandler
      HANDLER_IMPLS = {
        'transfer.paid' => PaymentProvider::Handlers::TransferPaid,
        'plan.created' => PaymentProvider::Handlers::PlanHandler,
        'invoice.payment_succeeded' => PaymentProvider::Handlers::InvoiceHandler,
        'invoice.payment_failed' => PaymentProvider::Handlers::InvoiceHandler
      }
      # 'charge.failed' => PaymentProvider::Handlers::ChargeHandler
      # 'customer.subscription.created' => PaymentProvider::Handlers::SubscriptionHandler,

      def call(event)
        ::Rails::logger.info("WEBHOOK: #{event.type} CONNECT: #{event.try(:account)} LIVEMODE: #{event.livemode}")
        handler = HANDLER_IMPLS[event.type]
        return unless handler && event.livemode && Rails.env.production?

        params = handler.extract_job_params(event)
        Rails.logger.info "Enqueueing '#{event.type}' event. Stripe Event id: '#{event.id}'"
        handler.delay(:run_at => 1.minute.from_now).handle(params)
      end
    end
  end
end
