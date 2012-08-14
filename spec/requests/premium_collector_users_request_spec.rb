require 'spec_helper'
require 'memorable_password'

describe 'PremiumCollectorUser management' do
  let(:current_user) { FactoryGirl.create(:cfe_admin) }
  before { login_as(current_user, scope: :user) }

  describe 'list' do
    before do
      FactoryGirl.create(:premium_collector_user, first_name: 'Barry', last_name: 'White')
      FactoryGirl.create(:lender_user, first_name: 'David', last_name: 'Bowie')
    end

    it do
      visit root_path
      click_link 'Manage Premium Collector Users'

      page.should have_content('Barry White')
      page.should_not have_content('David Bowie')
    end
  end

  describe 'create' do
    before do
      MemorablePassword.stub!(:generate).and_return('correct horse battery staple')
    end

    it do
      visit root_path
      click_link 'Manage Premium Collector Users'

      click_link 'New Premium Collector User'

      fill_in 'first_name', 'Bob'
      fill_in 'last_name', 'Flemming'
      fill_in 'email', 'bob.flemming@example.com'

      expect {
        click_button 'Create Premium Collector User'
      }.to change(PremiumCollectorUser, :count).by(1)

      page.should have_content('Bob Flemming')
      page.should have_content('bob.flemming@example.com')
      page.should have_content('correct horse battery staple')

      user = PremiumCollectorUser.last
      user.created_by.should == current_user
      user.modified_by.should == current_user
    end
  end

  describe 'update' do
    let!(:user) { FactoryGirl.create(:premium_collector_user, first_name: 'Bob', last_name: 'Flemming') }

    it do
      visit root_path
      click_link 'Manage Premium Collector Users'

      click_link 'Bob Flemming'

      fill_in 'first_name', 'Bill'
      fill_in 'last_name', 'Example'
      fill_in 'email', 'bill.example@example.com'

      click_button 'Update Premium Collector User'

      page.should have_content('Bill Example')
      page.should have_content('bill.example@example.com')

      user.reload.modified_by.should == current_user
    end
  end

  describe 'unlocking the user' do
    let!(:user) { FactoryGirl.create(:premium_collector_user, first_name: 'Bob', last_name: 'Flemming', locked: true) }

    it do
      visit root_path
      click_link 'Manage Premium Collector Users'
      click_link 'Bob Flemming'

      uncheck 'Locked'
      click_button 'Update Premium Collector User'

      user.reload.locked.should == false
    end
  end

  private
    def fill_in(attribute, value)
      page.fill_in "premium_collector_user_#{attribute}", with: value
    end

    def select(attribute, value)
      page.select value, from: "premium_collector_user_#{attribute}"
    end
end
