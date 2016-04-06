require "rails_helper"

describe SflgRecoveryCalculator do
  context "with additional monies" do
    it "calculates the amount due to secretary of state" do
      recovery = setup_recovery(
        total_liabilities_behind: Money.new(123_00),
        total_liabilities_after_demand: Money.new(234_00),
        additional_interest_accrued: Money.new(345_00),
        additional_break_costs: Money.new(456_00),
      )
      calculator = described_class.new(recovery)

      expect(calculator.amount_due_to_sec_state).to eq(Money.new(175_28))
    end

    it "calculates the amount due to DTI" do
      recovery = setup_recovery(
        total_liabilities_behind: Money.new(123_00),
        total_liabilities_after_demand: Money.new(234_00),
        additional_interest_accrued: Money.new(345_00),
        additional_break_costs: Money.new(456_00),
      )
      calculator = described_class.new(recovery)

      expect(calculator.amount_due_to_dti).to eq(Money.new(976_28))
    end
  end

  context "without additional monies" do
    it "calculates the amount due to secretary of state" do
      recovery = setup_recovery(
        total_liabilities_behind: Money.new(123_00),
        total_liabilities_after_demand: Money.new(234_00),
      )
      calculator = described_class.new(recovery)

      expect(calculator.amount_due_to_sec_state).to eq(Money.new(175_28))
    end

    it "calculates the amount due to DTI" do
      recovery = setup_recovery(
        total_liabilities_behind: Money.new(123_00),
        total_liabilities_after_demand: Money.new(234_00),
      )
      calculator = described_class.new(recovery)

      expect(calculator.amount_due_to_dti).to eq(Money.new(175_28))
    end
  end

  def setup_recovery(opts = {})
    total_liabilities_behind = opts.fetch(:total_liabilities_behind)
    total_liabilities_after_demand = opts.fetch(:total_liabilities_after_demand)
    additional_interest_accrued = opts[:additional_interest_accrued]
    additional_break_costs = opts[:additional_break_costs]

    loan = FactoryGirl.create(
      :loan,
      :sflg,
      :settled,
      amount: Money.new(200_000_00),
      dti_demand_outstanding: Money.new(90_000_57),
      dti_amount_claimed: Money.new(75_000_68),
      dti_interest: Money.new(10_000_34))

    FactoryGirl.build(
      :recovery,
      loan: loan,
      total_liabilities_behind: total_liabilities_behind,
      total_liabilities_after_demand: total_liabilities_after_demand,
      additional_interest_accrued: additional_interest_accrued,
      additional_break_costs: additional_break_costs)
  end
end
