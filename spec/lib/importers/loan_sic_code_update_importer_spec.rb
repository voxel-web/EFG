require 'spec_helper'
require 'importers'

describe LoanSicCodeUpdateImporter do

  let(:csv_fixture_path) { Rails.root.join('spec/fixtures/import_data/loan_sic_code_mapping.csv') }

  describe ".import" do
    let!(:loan) { FactoryGirl.create(:loan, reference: 'GP9GR7V+01', sic_code: 'A01.11.001') }

    let!(:sic_code) {
      FactoryGirl.create(
        :sic_code,
        code: '01110',
        description: 'Growing of cereals (except rice)',
        eligible: true
      )
    }

    before do
      LoanSicCodeUpdateImporter.csv_path = csv_fixture_path
    end

    def dispatch
      LoanSicCodeUpdateImporter.import
    end

    it "should update existing SIC code and related fields to 2007 standard" do
      dispatch

      loan.reload
      loan.sic_code.should == "01110"
      loan.sic_desc.should == "Growing of cereals (except rice)"
      loan.should be_sic_eligible
      loan.sic_parent_desc.should be_nil
      loan.sic_notified_aid.should be_nil
    end

    it "should not change created_at and updated_at timestamps" do
      original_created_at = loan.created_at
      original_updated_at = loan.updated_at

      Timecop.freeze(1.minute.from_now) do
        dispatch

        loan.reload
        loan.updated_at.to_i.should == original_updated_at.to_i
        loan.created_at.to_i.should == original_created_at.to_i
      end
    end
  end

end
