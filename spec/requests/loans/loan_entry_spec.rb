# encoding: utf-8

require 'spec_helper'

describe 'loan entry' do
  let(:current_lender) { FactoryGirl.create(:lender) }
  let(:current_user) { FactoryGirl.create(:lender_user, lender: current_lender) }
  let(:loan) { FactoryGirl.create(:loan, lender: current_lender) }
  before { login_as(current_user, scope: :user) }

  it 'entering further loan information' do
    visit loan_path(loan)
    click_link 'Loan Entry'

    fill_in_valid_details

    click_button 'Submit'

    loan = Loan.last

    current_path.should == loan_path(loan)

    loan.state.should == Loan::Completed
    loan.declaration_signed.should be_true
    loan.business_name.should == 'Widgets Ltd.'
    loan.trading_name.should == 'Brilliant Widgets'
    loan.company_registration.should == '0123456789'
    loan.postcode.should == 'N8 4HF'
    loan.non_validated_postcode.should == 'JF3 8HF'
    loan.branch_sortcode.should == '03-12-45'
    loan.generic1.should == 'Generic 1'
    loan.generic2.should == 'Generic 2'
    loan.generic3.should == 'Generic 3'
    loan.generic4.should == 'Generic 4'
    loan.generic5.should == 'Generic 5'
    loan.town.should == 'Londinium'
    loan.interest_rate_type.should == InterestRateType.find(1)
    loan.interest_rate.should == 2.25
    loan.fees.should == Money.new(12345)
    loan.maturity_date.should == Date.new(2013, 1, 1)
  end

  it 'does not continue with invalid values' do
    visit new_loan_entry_path(loan)

    loan.state.should == Loan::Eligible
    expect {
      click_button 'Submit'
    }.not_to change(loan, :state)

    current_path.should == loan_entry_path(loan)
  end

  it 'saves the loan as Incomplete when it is invalid' do
    visit new_loan_entry_path(loan)

    click_button 'Save as Incomplete'

    loan.reload.state.should == Loan::Incomplete
    current_path.should == loan_path(loan)
  end

  it 'progressing a loan from Incomplete to Completed' do
    loan.update_attribute(:state, Loan::Incomplete)
    visit loan_path(loan)
    click_link 'Loan Entry'

    fill_in_valid_details

    click_button 'Submit'

    loan = Loan.last

    current_path.should == loan_path(loan)

    loan.state.should == Loan::Completed
  end

  private
    def choose_radio_button(attribute, value)
      choose "loan_entry_#{attribute}_#{value}"
    end

    def fill_in(attribute, value)
      page.fill_in "loan_entry_#{attribute}", with: value
    end

    def fill_in_valid_details
      choose_radio_button 'declaration_signed', true
      fill_in 'business_name', 'Widgets Ltd.'
      fill_in 'trading_name', 'Brilliant Widgets'
      fill_in 'company_registration', '0123456789'
      choose_radio_button 'legal_form_id', 1
      fill_in 'postcode', 'N8 4HF'
      fill_in 'non_validated_postcode', 'JF3 8HF'
      fill_in 'branch_sortcode', '03-12-45'
      choose_radio_button 'repayment_frequency_id', 1
      fill_in 'maturity_date', '01/01/2013'

      click_button 'State Aid Calculation'
      page.fill_in 'state_aid_calculation_initial_draw_year', with: '2012'
      page.fill_in 'state_aid_calculation_initial_draw_amount', with: '7000'
      page.fill_in 'state_aid_calculation_initial_draw_months', with: '12'
      click_button 'Submit'

      fill_in 'generic1', 'Generic 1'
      fill_in 'generic2', 'Generic 2'
      fill_in 'generic3', 'Generic 3'
      fill_in 'generic4', 'Generic 4'
      fill_in 'generic5', 'Generic 5'
      fill_in 'town', 'Londinium'
      choose_radio_button 'interest_rate_type_id', 1
      fill_in 'interest_rate', '2.25'
      fill_in 'fees', '123.45'
    end
end
