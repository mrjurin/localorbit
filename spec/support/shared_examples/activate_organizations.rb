shared_examples "activates and deactivates organizations" do
  let!(:market) { create(:market) }
  let!(:org1)   { create(:organization, :seller, active: false, name: "Holland Farms", markets: [market]) }
  let!(:org2)   { create(:organization, :seller, active: true, name: "Franklin Farms", markets: [market]) }

  let!(:org1_product) { create(:product, organization: org1) }
  let!(:org2_product) { create(:product, organization: org2) }

  before do
    sign_out
    switch_to_subdomain(market.subdomain)
    sign_in_as(user)
  end

  it "activating an organization changes the active status" do
    visit admin_organizations_path

    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    org_row.activate!

    expect(page).to have_content("Updated #{org1.name}")
    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    expect(org_row.node).not_to have_content("Activate")
  end

  it "deactivating an organization changes the active status" do
    visit admin_organizations_path

    org_row = Dom::Admin::OrganizationRow.find_by_name(org2.name)
    org_row.deactivate!

    expect(page).to have_content("Updated #{org2.name}")
    org_row = Dom::Admin::OrganizationRow.find_by_name(org2.name)
    expect(org_row.node).not_to have_content("Deactivate")
  end

  it "sends an email to the organization after the first activation, but not subsequent activations" do
    org1_user = create(:user, organizations: [org1])

    visit admin_organizations_path

    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    org_row.activate!

    expect(page).to have_content("Updated #{org1.name}")
    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    expect(org_row.node).not_to have_content("Activate")

    open_last_email_for(org1_user.email)
    expect(current_email).to have_body_text("The #{market.name} Market Manager has activated your account")

    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    org_row.deactivate!
    expect(page).to have_content("Updated #{org1.name}")

    reset_mailer

    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    org_row.activate!
    expect(page).to have_content("Updated #{org1.name}")

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "sends an email mentioning the correct market" do
    market2 = create(:market, managers: [user])
    org1_user = create(:user, organizations: [org1])

    sign_out
    switch_to_subdomain(market2.subdomain)
    sign_in_as(user)

    visit admin_organizations_path

    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    org_row.activate!

    expect(page).to have_content("Updated #{org1.name}")
    org_row = Dom::Admin::OrganizationRow.find_by_name(org1.name)
    expect(org_row.node).not_to have_content("Activate")

    open_last_email_for(org1_user.email)
    expect(current_email).to have_body_text("The #{market.name} Market Manager has activated your account")
  end
end
