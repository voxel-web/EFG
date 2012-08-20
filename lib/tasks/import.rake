namespace :import do
  desc "Import all data"
  task all: [:users, :lenders, :loans, :loan_allocations, :state_aid_calculations, :loan_securities]

  desc "Import user data (SFLG_USER_DATA_TABLE)"
  task users: :lenders do
    _import User
  end

  desc "Import user data (SFLG_INVOICE_DATA_TABLE)"
  task invoices: [:lenders, :users] do
    _import Invoice
  end

  desc 'Associate creators/modifiers of Lenders'
  task lender_user_associations: [:lenders, :users] do
    require 'importers'
    LenderUserAssociationImporter.import
  end

  desc "Import lender data (SFLG_LENDER_DATA_TABLE)"
  task lenders: :environment do
    _import Lender
  end

  desc "Import LoanRealisation data (SFLG_LOAN_REALISE_MONEY_DATA_TABLE)"
  task loan_realisations: [:users, :loans] do
    _import LoanRealisation
  end

  desc "Import loan data (SFLG_LOAN_DATA_TABLE)"
  task loans: [:invoices, :loan_allocations] do
    _import Loan
  end

  desc "Import loan allocation data (SFLG_LENDER_CAP_ALLOC_DATA_TABLE)"
  task loan_allocations: :environment do
    _import LoanAllocation
  end

  desc "Import loan allocation data (SFLG_LOAN_CHANGES_DATA_TABLE)"
  task loan_changes: :loans do
    _import LoanChange
  end

  desc "Import state aid calculation data (SFLG_CALCULATORS_DATA_TABLE)"
  task state_aid_calculations: :loans do
    _import StateAidCalculation
  end

  desc "Import loan securities data (SFLG_LOAN_SECURITY_DATA_TABLE)"
  task loan_securities: :loans do
    _import LoanSecurity
  end

  def _import(klass)
    if klass.count.zero?
      require 'importers'
      importer = "#{klass.name}Importer".constantize
      importer.import
    else
      puts "Did not import #{klass.table_name} - table is not empty."
    end
  end

end
