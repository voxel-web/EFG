# encoding: utf-8

require 'spec_helper'

describe 'loan guarantee' do
  let(:current_user) { FactoryGirl.create(:lender_user) }
  let(:loan) { FactoryGirl.create(:loan, :offered, :with_state_aid_calculation, lender: current_user.lender) }
  before { login_as(current_user, scope: :user) }

  it 'entering further loan information' do
    visit loan_path(loan)
    click_link 'Guarantee & Initial Draw'

    fill_in_valid_loan_guarantee_details
    click_button 'Submit'

    loan = Loan.last!

    current_path.should == loan_path(loan)

    loan.state.should == Loan::Guaranteed
    loan.received_declaration.should == true
    loan.signed_direct_debit_received.should == true
    loan.first_pp_received.should == true
    loan.maturity_date.should == Date.today.advance(years: 10)
    loan.modified_by.should == current_user

    should_log_loan_state_change(loan, Loan::Guaranteed, 7, current_user)

    loan_change = loan.initial_draw_change
    loan_change.amount_drawn.should == loan.amount
    loan_change.change_type_id.should == nil
    loan_change.created_by.should == current_user
    loan_change.date_of_change.should == Date.current
    loan_change.modified_date.should == Date.current
    loan_change.seq.should == 0
  end

  it "amending draw down details" do
    loan.reference = 'ABCDEF98+01'
    loan.save!

    visit loan_path(loan)
    click_link 'Guarantee & Initial Draw'

    click_link 'amend the draw down details'

    page.should have_content('Amend Draw Down Details')
    click_button 'Submit'

    current_path.should == loan_path(loan)
    page.should have_content('The recalculated De Minimis figure is €3,141.18.')

    click_link 'Guarantee & Initial Draw'
    fill_in_valid_loan_guarantee_details
    click_button 'Submit'

    loan = Loan.last!
    current_path.should == loan_path(loan)
    loan.state.should == Loan::Guaranteed
  end

  it 'does not continue with invalid values' do
    visit new_loan_guarantee_path(loan)

    loan.state.should == Loan::Offered
    expect {
      click_button 'Submit'
      loan.reload
    }.to_not change(loan, :state)

    current_path.should == "/loans/#{loan.id}/guarantee"
  end

end
