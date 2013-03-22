FactoryGirl.define do
  factory :loan_change_presenter do
    association :created_by, factory: :lender_user
    date_of_change Date.new
    loan

    factory :lump_sum_repayment_loan_change_presenter, class: LumpSumRepaymentLoanChangePresenter do
      lump_sum_repayment Money.new(1_000_00)
    end

    factory :repayment_duration_loan_change_presenter, class: RepaymentDurationLoanChangePresenter do
      added_months 3
    end
  end
end
