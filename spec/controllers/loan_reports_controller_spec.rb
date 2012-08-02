require 'spec_helper'

describe LoanReportsController do

  let(:loan) { FactoryGirl.create(:loan, :eligible) }

  describe "#create" do

    context 'with lender user' do
      let(:current_user) { FactoryGirl.create(:lender_user, lender: loan.lender) }

      let(:loan2) { FactoryGirl.create(:loan, :eligible) }

      before { sign_in(current_user) }

      def dispatch
        post :create, loan_report: { lender_ids: [ loan.lender.id, loan2.lender.id ] }
      end

      it "should raise exception when trying to access loans belonging to a different user" do
        expect {
          dispatch
        }.to raise_error(LoanReport::LenderNotAllowed)
      end
    end

  end

end
