class DemandedAmountDataCorrection < DataCorrectionPresenter
  attr_reader :demanded_amount, :demanded_interest
  attr_accessible :demanded_amount, :demanded_interest

  before_save :update_loan

  validate :ensure_loan_is_demanded
  validate :ensure_value_entered
  validate :validate_demanded_amount
  validate :validate_demanded_interest

  def demanded_amount=(value)
    @demanded_amount = value.present? ? Money.parse(value) : nil
  end

  def demanded_interest=(value)
    @demanded_interest = value.present? ? Money.parse(value) : nil
  end

  private
    def can_correct_interest?
      !loan.efg_loan?
    end

    def change_type
      ChangeType::DataCorrection
    end

    def ensure_loan_is_demanded
      if loan.state != Loan::Demanded
        raise ActiveModel::StrictValidationFailed
      end
    end

    def ensure_value_entered
      errors.add(:base, :change_required) unless demanded_amount || demanded_interest
    end

    def formatted_value(key, value)
        binding.pry
      if key == 'dti_demand_outstanding'
        Money.new(value)
      else
        value
      end
    end

    def update_loan
      loan.dti_demand_outstanding = demanded_amount if demanded_amount
      loan.dti_interest = demanded_interest if can_correct_interest? && demanded_interest
      loan.calculate_dti_amount_claimed
    end

    def validate_demanded_amount
      return unless demanded_amount

      if demanded_amount == loan.dti_demand_outstanding
        errors.add(:demanded_amount, :must_have_changed)
      elsif demanded_amount < Money.new(0)
        errors.add(:demanded_amount, :must_not_be_negative)
      elsif demanded_amount > loan.cumulative_drawn_amount
        errors.add(:demanded_amount, :must_not_be_greater_than_cumulative_drawn_amount)
      end
    end

    def validate_demanded_interest
      return unless demanded_interest

      if demanded_interest == loan.dti_interest
        errors.add(:demanded_interest, :must_have_changed)
      elsif demanded_interest < Money.new(0)
        errors.add(:demanded_interest, :must_not_be_negative)
      elsif demanded_interest > loan.amount
        errors.add(:demanded_interest, :must_be_lte_original_loan_amount)
      end
    end
end
