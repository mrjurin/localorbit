require "spec_helper"

def fill_in_required_fields(select=:without_chosen)
  fill_in "Product Name", with: "Red Grapes"
  fill_in "Short description", with: "Grapes are yummy!"

  case select
  when :without_chosen
    select "Apples / Macintosh Apples", from: "Category"
  when :with_chosen
    select_from_chosen "Grapes / Red Grapes", from: "Category"
  end
end



describe "Adding a product" do
  let(:user) { create(:user) }
  let(:org) { create(:organization, :seller) }
  let(:loc1) {create(:location) }
  let(:stub_warning_pricing) {"Your product will not appear in the Shop until you add pricing"}
  let(:stub_warning_inventory) {"Your product will not appear in the Shop until you add inventory"}
  let(:stub_warning_both) {"Your product will not appear in the Shop until you add inventory, and add pricing"}
  let(:organization_label) { "Product Organization" }
  let(:market) { create(:market, organizations: [org]) }

  before do
    Unit.create! singular: "Pound", plural: "Pounds"
    Unit.create! singular: "Bushel", plural: "Bushels"
    switch_to_subdomain(market.subdomain)
  end

  describe "as a seller belonging to one organization" do
    let(:location){ create(:location) }

    before do
      org.users << user
      org.who_story = "We sell products"
      org.how_story = "We sell products very carefully"
      org.locations << location
      org.save!

      sign_in_as(user)
    end

    it "defaults to simple inventory" do
      within '#admin-nav' do
        click_link 'Products'
      end
      click_link "Add a product"

      simple_inventory_checkbox = page.find_field("Use simple inventory management")
      inventory_quantity = page.find_field("Your current inventory")

      expect(simple_inventory_checkbox).to be_checked
      expect(inventory_quantity.value).to eql("0")
    end

    context "filling in who/where/how", js: true, chosen_js: true do
      let(:product_form) { Dom::Admin::ProductForm.first }

      it "pre-populates the fields from the organization" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        uncheck "seller_info"

        expect(page).to have_content("Who")

        expect(product_form.who_story).to eq("We sell products")
        expect(product_form.how_story).to eq("We sell products very carefully")
        expect(product_form.selected_location).to eq(org.locations.default_shipping.to_param)
      end

      it "saves changes made to fields if checked and unchecked" do
        location2 = create(:location, name: "Good Place", organization: org)

        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        uncheck "seller_info"
        expect(page.find('.seller_info_fields', visible: false)).to be_visible
        product_form = Dom::Admin::ProductForm.first

        fill_in "product_who_story", with: "We sell other stuff"
        fill_in "product_how_story", with: "By selling stuff"
        select "Good Place", from: "product_location_id"

        check "seller_info"
        expect(page.find('.seller_info_fields', visible: false)).to_not be_visible

        uncheck "seller_info"
        expect(page.find('.seller_info_fields', visible: false)).to be_visible

        expect(product_form.seller_info).to_not be_checked
        expect(product_form.who_story).to eq("We sell other stuff")
        expect(product_form.how_story).to eq("By selling stuff")
        expect(product_form.location.value.to_i).to eq(location2.id)
      end

      it "does not save the product who/where/how information if checked after updating who/how/where" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        fill_in_required_fields(:with_chosen)

        uncheck "seller_info"
        expect(page.find('.seller_info_fields', visible: false)).to be_visible

        fill_in "product_who_story", with: "We sell other stuff"

        check "seller_info"
        expect(page.find('.seller_info_fields', visible: false)).to_not be_visible

        click_button "Add Product"

        click_link "Product Info"

        expect(page.find('.seller_info_fields', visible: false)).to_not be_visible

        product = Product.last.decorate

        expect(product.who_story).to eql(org.who_story)
        expect(product.how_story).to eql(org.how_story)
        expect(product.location).to eql(org.locations.default_shipping)
      end

      it "it uses a default address if using who/how" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        fill_in "Product Name", with: "Good food"
        select_from_chosen "Grapes / Red Grapes", from: "Category"
        select_from_chosen "Pounds", from: "Unit"

        uncheck "seller_info"
        expect(page).to have_content("Who")

        fill_in "product_who_story", with: "We sell other stuff"
        click_button "Add Product"

        expect(page).not_to have_content("Location can't be blank")
        expect(product_form.selected_location).to eq(org.locations.default_shipping.to_param)
      end
    end

    context "attaching an image" do
      it "uploads an image when provided" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        fill_in "Product Name", with: "Red Grapes"
        attach_file("Image", 'app/assets/images/backgrounds/kale.jpg')

        click_button "Add Product"
        expect(page).to have_css("img[alt='Red Grapes']")
      end
    end

    context "adding simple inventory for the first time", js: true, chosen_js: true do
      it "creates a new lot for the product" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        fill_in_required_fields(:with_chosen)
        select_from_chosen "Pounds", from: "Unit"
        fill_in("Your current inventory", with: 33)

        click_button "Add Product"
        expect(page).to have_content("Added Red Grapes")

        click_link "Product Info"

        simple_inventory_checkbox = page.find_field("Use simple inventory management")
        inventory_quantity        = page.find_field("Your current inventory")

        expect(simple_inventory_checkbox).to be_checked
        expect(inventory_quantity.value).to eql("33")

        expect(page).to have_content("Uncheck this to use advanced inventory tracking with lots and expirations dates")
        expect(page).to have_content("Pounds")

        within(".tabs") do
          expect(page).to_not have_content("Inventory")
        end
      end
    end

    context "adding a product with advanced inventory", js: true, chosen_js: true do
      it "hides the simple inventory field" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        expect(page).to have_content("Your current inventory")

        uncheck "Use simple inventory management"

        expect(page).to_not have_content("Your current inventory")
      end
    end

    context "using the choose category typeahead", js: true do
      let(:category_select) { Dom::CategorySelect.first }

      it "can quickly drill down to a result" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        category_select.click

        expect(category_select.visible_options).to have_text("Macintosh Apples")
        expect(category_select.visible_options).to have_text("Turnips")

        category_select.type_search("grapes")

        expect(category_select.visible_options).to have_text("Red Grapes")
        expect(category_select.visible_options).to have_text("Green Grapes")
        expect(category_select.visible_options).to_not have_text("Turnips")
        expect(category_select.visible_options).to_not have_text("Macintosh Apples")

        category_select.visible_option("Grapes / Red Grapes").click

        expect(page).to have_content("Fruits / Grapes / Red Grapes")

        # Set the product name so we have a valid product
        fill_in "Product Name", with: "Red Grapes"
        fill_in "Short description", with: "Apples are yummy!"

        click_button "Add Product"
        expect(page).to have_content("Added Red Grapes")

        click_link "Product Info"

        expect(page).to have_content("Grapes / Red Grapes")
      end

      it "fuzzy searches across top-level categories" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        category_select.click

        expect(category_select.visible_options).to have_text("Macintosh Apples")
        expect(category_select.visible_options).to have_text("Turnips")

        category_select.type_search("fruit apples mac")

        expect(category_select.visible_options).to_not have_text("Turnips")
        expect(category_select.visible_options).to have_text("Macintosh Apples")

        category_select.visible_option("Apples / Macintosh Apples").click

        expect(page).to have_content("Fruits / Apples / Macintosh Apples")
      end
    end

    context "when all input is valid", js: true, chosen_js: true do
      let!(:loc1) { create(:location, organization: org)}
      let!(:loc2) { create(:location, organization: org)}

      it "saves the product stub" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        expect(page).to_not have_content(stub_warning_both)
        expect(page).to_not have_content(organization_label)

        fill_in_required_fields(:with_chosen)

        select_from_chosen "Bushels", from: "Unit"
        fill_in "Long description", with: "There are many kinds of apples."

        fill_in "Your current inventory", with: "12"
        uncheck "Use simple inventory management"

        uncheck :seller_info

        select loc1.name, from: "Where"

        fill_in "Who", with: "The farmers down the road."
        fill_in "How", with: "With water, earth, and time."

        click_button "Add Product"

        expect(page).to have_content("Added Red Grapes")

        expect(page).to have_content(stub_warning_both)

        expect(current_path).to eql(admin_product_lots_path(Product.last))

        lot_rows = Dom::LotRow.all
        expect(lot_rows.count).to eq(0)
      end
    end

    context "when the product information is invalid", js: true do
      it "does not create the product" do
        within '#admin-nav' do
          click_link 'Products'
        end
        click_link "Add a product"

        expect(page).to have_content("Your current inventory")
        uncheck 'Use simple inventory management'

        click_button "Add Product"
        expect(page).to have_content("Name can't be blank")
        expect(page).to have_content("Category can't be blank")
        expect(page).to_not have_content("Your current inventory")
        within('.tabs') do
          expect(page).to have_content("Inventory")
        end
      end
    end
  end

  describe "a seller belonging to multiple organizations" do
    let(:org2) { create(:organization, who_story: "who org2", how_story: "how org2", locations: [create(:location)]) }
    let(:buying_org) { create(:organization, :buyer) }
    let(:loc1) { create(:location, organization: org) }
    let(:loc2) { create(:location, organization: org2) }

    before do
      org.users << user
      org2.users << user

      buying_org.users << user

      sign_in_as(user)
      within '#admin-nav' do
        click_link 'Products'
      end
      click_link "Add a product"
    end

    it "is prevented from unchecking 'Use seller info from my account' until organization is selected", js: true do
      seller_info = page.find("#seller_info")
      expect(seller_info).to be_disabled

      select org2.name, from: "Product Organization"

      seller_info = page.find("#seller_info")
      expect(seller_info).not_to be_disabled
    end

    context "Uncheck 'use seller info'", js: true do
      before do
        select org2.name, from: "Product Organization"
        uncheck "seller_info"
      end

      it "pre-populates who/where/how fields from the organization" do
        expect(page).to have_content("Who")

        product_form = Dom::Admin::ProductForm.first
        expect(product_form.who_story).to eq("who org2")
        expect(product_form.how_story).to eq("how org2")

        expect(product_form.locations).to include(*org2.locations.map(&:name))
        expect(product_form.locations).to_not include(*org.locations.map(&:name))
      end

      context "select a different organiztion" do

        before do
          select org2.locations.first.name, from: "product_location_id"
          expect(Dom::Admin::ProductForm.first.selected_location).to eql(org2.locations.first.id.to_s)
          select org.name, from: "Product Organization"
        end

        it "populates the locations list" do
          product_form = Dom::Admin::ProductForm.first
          expect(product_form.locations).to include(*org.locations.map(&:name))
        end
      end

      context "select the blank organization option" do
        before do
          select "Select an organization", from: "Product Organization"
        end

        it "disables seller info" do
          form = Dom::Admin::ProductForm.first
          expect(form.seller_info).to be_disabled
        end
      end
    end

    it "does not offer non-selling organizations as options for the Organization select" do
      product_form = Dom::Admin::ProductForm.first
      expect(product_form.organization_field).to_not have_content(buying_org.name)
    end

    context "when product information is valid" do
      it "makes the user choose an organization to add the product for" do
        expect(page).to_not have_content(stub_warning_both)
        select org2.name, from: organization_label
        fill_in_required_fields

        click_button "Add Product"

        expect(page).to have_content("Added Red Grapes")
        expect(page).to have_content(stub_warning_pricing)
        expect(Product.last.organization).to eql(org2)
      end
    end

    context "When no organization has been chosen" do
      it "does not create the product" do
        fill_in "Product Name", with: "Macintosh Apples"
        select "Apples / Macintosh Apples", from: "Category"

        click_button "Add Product"
        expect(page).to have_content("Organization can't be blank")
      end
    end
  end

  describe "as a market manager" do
    let(:user) { create(:user, :market_manager) }
    let(:market) { user.managed_markets.first }
    let(:org2) { create(:organization) }

    before do
      market.organizations << org
      market.organizations << org2

      sign_in_as(user)
      within '#admin-nav' do
        click_link 'Products'
      end
      click_link "Add a product"
    end

    it "makes the user choose an organization to add the product for" do
      expect(page).to_not have_content(stub_warning_both)
      select org2.name, from: organization_label
      fill_in_required_fields

      click_button "Add Product"

      expect(page).to have_content("Added Red Grapes")
      expect(page).to have_content(stub_warning_pricing)
      expect(Product.last.organization).to eql(org2)
    end
  end

  describe "additional taxonomy requests" do
    before do
      org.users << user
      sign_in_as(user)

      within '#admin-nav' do
        click_link 'Products'
      end
      click_link "Add a product"
    end

    describe "a user can request a new inventory unit" do
      it "allows the user to request a new unit" do
        click_link "Request a New Unit"

        expect(ZendeskMailer).to receive(:request_unit).with(user.email, user.name, {
          "singular" => "fathom",
          "plural" => "fathoms",
          "additional_notes" => "See more notes"
        }).and_return(double(:mailer, deliver: true))

        fill_in "Singular", with: "fathom"
        fill_in "Plural", with: "fathoms"
        fill_in "Additional Notes", with: "See more notes"
        click_button "Request Unit"

        expect(page).to have_content("Add Product")
      end
    end

    describe "a user can request a new category" do
      it "allows the user to request a new category" do
        click_link "Request a New Category"

        expect(ZendeskMailer).to receive(:request_category).with(
          user.email, user.name, "Goop"
        ).and_return(double(:mailer, deliver: true))

        fill_in "Product Category", with: "Goop"
        click_button "Request Category"

        expect(page).to have_content("Add Product")
      end
    end
  end
end
