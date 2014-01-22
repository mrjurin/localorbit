class Admin::MarketManagersController < AdminController
  before_action :require_admin

  def index
    @market = Market.find(params[:market_id])
  end

  def new
    @market = Market.find(params[:market_id])
  end

  def create
    @market = Market.find(params[:market_id])
    result = AddMarketManager.perform(market: @market, email: params.require(:email), inviter: current_user)
    if result.success?
      redirect_to [:admin, @market, :managers]
    else
      render :new
    end
  end

  def destroy
    @market = Market.find(params[:market_id])
    @user = User.find(params[:id])
    @market.managers.delete(@user)
    redirect_to [:admin, @market, :managers]
  end
end
