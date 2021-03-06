require "spec_helper"

describe Admin::ReportsController do
  let!(:market) { create(:market) }
  let!(:user)   { create(:user, :supplier)}

  before do
    switch_to_subdomain market.subdomain
  end

  it_behaves_like "an action that prevents access to buyers", lambda { get :show, id: "total-sales" }
  #it_behaves_like "an action that prevents access to buyers", lambda { get :show, id: "sales-by-supplier" }
  it_behaves_like "an action that prevents access to buyers", lambda { get :show, id: "sales-by-product" }
  it_behaves_like "an action that prevents access to buyers", lambda { get :show, id: "sales-by-payment-method" }
  #it_behaves_like "an action that prevents access to buyers", lambda { get :show, id: "sales-by-fulfillment" }
  #it_behaves_like "an action that prevents access to buyers", lambda { get :show, id: "discount-code-use" }

  context "seller has not made a purchase" do
    it_behaves_like "an action that grants access to buyers only", lambda { get :show, id: "purchases-by-product" }
    it_behaves_like "an action that grants access to buyers only", lambda { get :show, id: "total-purchases" }
  end

  context "seller has made a purchase" do
    it_behaves_like "an action that grants access to buyers and sellers only", lambda { get :show, id: "purchases-by-product" }
    it_behaves_like "an action that grants access to buyers and sellers only", lambda { get :show, id: "total-purchases" }
  end
end
