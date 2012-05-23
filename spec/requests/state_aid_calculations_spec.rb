# encoding: utf-8

require 'spec_helper'

describe 'state aid calculations' do
  describe 'creating' do
    let(:current_lender) { FactoryGirl.create(:lender) }
    let(:current_user) { FactoryGirl.create(:user, lender: current_lender) }
    let(:loan) { FactoryGirl.create(:loan, lender: current_lender, amount: 123_456_00) }

    before do
      login_as(current_user, scope: :user)
    end

    it 'creates a new record with valid data' do
      visit new_loan_state_aid_calculations_path(loan)

      fill_in :initial_draw_year, '2012'
      fill_in :initial_draw_amount, '123456'
      fill_in :initial_draw_months, '12'
      fill_in :initial_capital_repayment_holiday, '0'
      fill_in :second_draw_amount, '0'
      fill_in :second_draw_months, '0'

      expect {
        click_button 'Submit'
      }.to change(StateAidCalculation, :count).by(1)

      current_path.should == loan_path(loan)

      state_aid_calculation = StateAidCalculation.last
      state_aid_calculation.loan.should == loan
      state_aid_calculation.initial_draw_year.should == 2012
      state_aid_calculation.initial_draw_amount.should == Money.new(123_456_00)
      state_aid_calculation.initial_draw_months.should == 12
      state_aid_calculation.initial_capital_repayment_holiday.should == 0
      state_aid_calculation.second_draw_amount.should == 0
      state_aid_calculation.second_draw_months.should == 0
      state_aid_calculation.third_draw_amount.should be_nil
      state_aid_calculation.third_draw_months.should be_nil
      state_aid_calculation.fourth_draw_amount.should be_nil
      state_aid_calculation.fourth_draw_months.should be_nil
    end

    it 'does not create a new record with invalid data' do
      visit new_loan_state_aid_calculations_path(loan)

      expect {
        click_button 'Submit'
      }.to change(StateAidCalculation, :count).by(0)

      current_path.should == loan_state_aid_calculations_path(loan)
    end
  end

  private
    def fill_in(attribute, value)
      page.fill_in "state_aid_calculation_#{attribute}", with: value
    end
end
