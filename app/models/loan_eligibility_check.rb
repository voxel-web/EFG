require 'active_model/model'

class LoanEligibilityCheck
  include ActiveModel::Model

  ATTRIBUTES = [:viable_proposition, :would_you_lend, :collateral_exhausted,
                :amount, :lender_cap, :repayment_duration, :turnover,
                :trading_date, :sic_code, :loan_category, :reason,
                :previous_borrowing, :private_residence_charge_required,
                :personal_guarantee_required]

  ATTRIBUTES.each do |attribute|
    delegate attribute, "#{attribute}=", to: :loan
  end
  delegate :errors, :save, to: :loan

  attr_reader :loan

  def initialize(*)
    @loan = Loan.new
    super
  end
end
