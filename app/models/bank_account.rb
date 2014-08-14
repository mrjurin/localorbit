class BankAccount < ActiveRecord::Base
  audited allow_mass_assignment: true, associated_with: :bankable
  include SoftDelete

  attr_accessor :save_for_future

  belongs_to :bankable, polymorphic: true

  validate :account_is_unique_to_bankable

  def balanced_verification
    return nil if verified? || balanced_verification_uri.nil?
    @balanced_verification ||= Balanced::Verification.find(balanced_verification_uri)
  rescue Balanced::NotFound # Probably bad account info
    nil
  end

  def bank_account?
    account_type == "checking" || account_type == "savings"
  end

  def credit_card?
    !bank_account?
  end

  def verification_failed?
    return false if verified?
    return true if balanced_verification.nil?
    balanced_verification.try(:state) == "failed"
  end

  private

  def account_is_unique_to_bankable
    accounts = bankable.bank_accounts.visible.where(account_type: account_type, last_four: last_four, bank_name: bank_name, name: name)
    accounts = accounts.where.not(id: id) if persisted?

    if accounts.any?
      errors.add(:bankable_id, "already exists for this #{bankable_type.downcase}.")
    end
  end
end
