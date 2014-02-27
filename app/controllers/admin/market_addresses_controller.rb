class Admin::MarketAddressesController < AdminController
  before_action :require_admin_or_market_manager
  before_action :find_current_market
  before_action :find_address, only: [:edit, :update, :destroy]

  def index
    @addresses = @market.addresses
  end

  def new
    @address = MarketAddress.new(market: @market)
  end

  def create
    @address = @market.addresses.build(market_address_params)
    if @address.save
      redirect_to admin_market_addresses_path(@market)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @address.update_attributes(market_address_params)
      redirect_to admin_market_addresses_path(@market)
    else
      render :edit
    end
  end

  def destroy
    @address.destroy
    redirect_to admin_market_addresses_path(@market)
  end

  private

  def market_address_params
    params.require('market_address').permit(
      :name,
      :address,
      :city,
      :state,
      :zip
    )
  end

  def find_current_market
    @market = Market.where(id: params[:market_id]).first
  end

  def find_address
    @address = MarketAddress.where(id: params[:id]).first
  end
end
