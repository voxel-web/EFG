require 'spec_helper'

describe 'Transfer a legacy loan' do

  let(:current_user) { FactoryGirl.create(:lender_user) }

  let(:loan) { FactoryGirl.create(:loan, :offered, :guaranteed, :with_state_aid_calculation, :legacy_sflg) }

  before(:each) do
    login_as(current_user, scope: :user)
    visit root_path
    click_link 'Transfer a legacy loan'
  end

  it 'should transfer legacy loan from one lender to another' do
    fill_in 'loan_transfer_legacy_sflg_reference', with: loan.reference
    fill_in 'loan_transfer_legacy_sflg_amount', with: loan.amount.to_s
    fill_in 'loan_transfer_legacy_sflg_initial_draw_date', with: loan.initial_draw_date.strftime('%d/%m/%Y')
    fill_in 'loan_transfer_legacy_sflg_new_amount', with: loan.amount - Money.new(500)
    choose 'loan_transfer_legacy_sflg_declaration_signed_true'

    click_button 'Transfer Loan'

    page.should have_content('This page provides confirmation that the loan has been transferred.')

    # Check original loan and new loan
    loan.reload.state.should == Loan::RepaidFromTransfer
    transferred_loan = Loan.last
    transferred_loan.transferred_from_id.should == loan.id
    transferred_loan.reference.should == loan.reference + '-02'
    transferred_loan.state.should == Loan::Incomplete
    transferred_loan.business_name.should == loan.business_name
    transferred_loan.amount.should == loan.amount - Money.new(500)

    # verify correct loan entry form is shown
    click_link 'Loan Entry'
    current_path.should == new_loan_transferred_entry_path(transferred_loan)
  end

end
