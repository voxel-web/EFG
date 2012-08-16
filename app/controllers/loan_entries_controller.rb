class LoanEntriesController < ApplicationController
  before_filter :verify_create_permission, only: [:new, :create]

  def new
    @loan = current_lender.loans.find(params[:loan_id])
    @loan_entry = LoanEntry.new(@loan)
  end

  def create
    @loan = current_lender.loans.find(params[:loan_id])
    @loan_entry = LoanEntry.new(@loan)
    @loan_entry.attributes = params[:loan_entry]
    @loan_entry.modified_by = current_user

    case params[:commit]
    when 'Save as Incomplete'
      @loan_entry.save_as_incomplete
      redirect_to loan_url(@loan_entry.loan)
    when 'State Aid Calculation'
      @loan_entry.save_as_incomplete
      redirect_to edit_loan_state_aid_calculation_url(@loan_entry.loan, redirect: 'loan_entry')
    else
      if @loan_entry.save
        redirect_to loan_url(@loan_entry.loan)
      else
        render :new
      end
    end
  end

  private
  def verify_create_permission
    enforce_create_permission(LoanEntry)
  end
end
