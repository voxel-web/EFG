require 'rails_helper'

describe Recovery do
  describe 'validations' do
    let(:recovery) { FactoryGirl.build(:recovery) }

    it 'has a valid Factory' do
      expect(recovery).to be_valid
    end

    it 'strictly requires a loan' do
      expect {
        recovery.loan = nil
        recovery.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'strictly requires a creator' do
      expect {
        recovery.created_by = nil
        recovery.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    it 'requires recovered_on' do
      recovery.recovered_on = ''
      expect(recovery).not_to be_valid
    end

    it 'recovered_on must be after its loan was settled' do
      recovery.loan.settled_on = Date.current
      recovery.recovered_on = 1.day.ago
      expect(recovery).not_to be_valid
    end

    it "cannot have a recovered_on date in the future" do
      recovery.recovered_on = 1.day.from_now
      expect(recovery).not_to be_valid
    end

    context 'EFG' do
      let(:loan) { FactoryGirl.build(:loan, :efg, :settled) }

      before do
        recovery.loan = loan
      end

      %w(
        outstanding_prior_non_efg_debt
        outstanding_subsequent_non_efg_debt
        non_linked_security_proceeds
        linked_security_proceeds
      ).each do |attr|
        it "requires #{attr}" do
          recovery.send("#{attr}=", '')
          expect(recovery).not_to be_valid
        end
      end

      it "outstanding_subsequent_non_efg_debt is not required existing
          EFG recoveries" do
        recovery.outstanding_subsequent_non_efg_debt = nil
        recovery.valid?
        recovery.save(validate: false)

        expect(recovery.reload).to be_valid
      end
    end

    [:sflg, :legacy_sflg].each do |scheme|
      context scheme.to_s do
        let(:loan) { FactoryGirl.build(:loan, scheme, :settled) }

        before do
          recovery.loan = loan
        end

        %w(
          total_liabilities_after_demand
          total_liabilities_behind
        ).each do |attr|
          it "requires #{attr}" do
            recovery.send("#{attr}=", '')
            expect(recovery).not_to be_valid
          end
        end
      end
    end
  end

  describe '#calculate' do
    let(:recovery) {
      Recovery.new.tap { |recovery|
        recovery.loan = loan
        recovery.created_by = FactoryGirl.build(:user)
        recovery.recovered_on = Date.current
      }
    }

    context "EFG" do
      let(:loan) {
        FactoryGirl.build(:loan, :settled,
          dti_demand_outstanding: Money.new(100_000_00),
          dti_amount_claimed: Money.new(0),
        )
      }

      it "sets values correctly" do
        recovery.outstanding_prior_non_efg_debt = Money.new(300_000_00)
        recovery.outstanding_subsequent_non_efg_debt = Money.new(100_000_00)
        recovery.non_linked_security_proceeds = Money.new(325_000_00)
        recovery.linked_security_proceeds = Money.new(50_000_00)

        recovery.calculate

        expect(recovery.realisations_attributable).to eq(Money.new(58_250_00))
        expect(recovery.amount_due_to_dti).to eq(Money.new(43_687_50))
        expect(recovery.amount_due_to_sec_state).to eq(Money.new(0))
      end

      it "does not allow recovered amount to be greater than remaining unrecovered amount (i.e. dti_amount_claimed - previous recoveries)" do
        recovery.outstanding_prior_non_efg_debt = Money.new(0)
        recovery.outstanding_subsequent_non_efg_debt = Money.new(0)
        recovery.non_linked_security_proceeds = Money.new(200_000_00)
        recovery.linked_security_proceeds = Money.new(5_001_00)

        recovery.calculate

        expect(recovery.errors[:base]).not_to be_empty
      end
    end

    context 'SFLG' do
      let(:loan) {
        # Training loan reference YJXAD9K-01.
        FactoryGirl.create(:loan, :sflg, :settled,
          amount: Money.new(200_000_00),
          dti_demand_outstanding: Money.new(90_000_57),
          dti_amount_claimed: Money.new(75_000_68),
          dti_interest: Money.new(10_000_34)
        )
      }

      it "sets values correctly" do
        recovery.total_liabilities_behind = Money.new(123_00)
        recovery.total_liabilities_after_demand = Money.new(234_00)
        recovery.additional_interest_accrued = Money.new(345_00)
        recovery.additional_break_costs = Money.new(456_00)

        recovery.calculate

        expect(recovery.realisations_attributable).to eq(Money.new(0))
        expect(recovery.amount_due_to_sec_state).to eq(Money.new(175_28))
        expect(recovery.amount_due_to_dti).to eq(Money.new(976_28))
      end
    end
  end

  describe '#save_and_update_loan' do
    context 'when the recovery is valid' do
      let(:user) { FactoryGirl.create(:lender_user) }
      let(:recovery) { FactoryGirl.build(:recovery, created_by: user) }
      let(:loan) { recovery.loan }

      it 'saves the recovery' do
        expect {
          recovery.save_and_update_loan
        }.to change(Recovery, :count).by(1)
      end

      it 'updates the loan state to recovered' do
        recovery.save_and_update_loan
        expect(loan.reload.state).to eq(Loan::Recovered)
      end

      it 'stores who last modified the loan' do
        recovery.save_and_update_loan
        loan.reload.modified_by == user
      end

      it 'stores the recovered date on the loan' do
        recovery.save_and_update_loan
        expect(loan.reload.recovery_on).to eq(recovery.recovered_on)
      end

      it 'creates a new loan state change record for the state change' do
        expect {
          recovery.save_and_update_loan
        }.to change(LoanStateChange, :count).by(1)

        state_change = loan.state_changes.last
        expect(state_change.event_id).to eq(20)
        expect(state_change.state).to eq(Loan::Recovered)
      end
    end

    context 'when the recovery is not valid' do
      let(:loan) { FactoryGirl.build(:loan) }
      let(:recovery) {
        Recovery.new do |recovery|
          recovery.created_by = FactoryGirl.build(:lender_user)
          recovery.loan = loan
        end
      }

      it 'returns false' do
        expect(recovery.save_and_update_loan).to eq(false)
      end
    end
  end

  describe '#seq' do
    let(:recovery) { FactoryGirl.create(:recovery) }

    it 'is incremented for each change' do
      recovery1 = FactoryGirl.create(:recovery)
      recovery2 = FactoryGirl.create(:recovery, loan: recovery1.loan)

      expect(recovery1.seq).to eq(0)
      expect(recovery2.seq).to eq(1)
    end
  end
end
