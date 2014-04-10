class Admin::IndividualPackListsController < AdminController
  def show
    @delivery = Delivery.find(params[:id]).decorate
    order_items = OrderItem.for_delivery_and_user(@delivery, current_user)
    @pack_lists = OrdersBySellerPresenter.new(order_items)
  end
end
