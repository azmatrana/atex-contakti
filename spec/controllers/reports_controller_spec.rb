require 'rails_helper'

describe ReportsController do

  let(:company) { ::FactoryGirl.create :company }
  let(:user) { ::FactoryGirl.create :manager, company: company }

  before(:each) do
    sign_in(user)
  end

  context 'permissions' do
    
    let(:another_company) { ::FactoryGirl.create :company }
    let(:summary_report) { ::FactoryGirl.create :summary_report, company: another_company }
    let(:comparison_report) { ::FactoryGirl.create :comparison_report, company: another_company }

    it 'should not let user see summary report from another company' do
      get :show, id: summary_report.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
    end

    it 'should not let user see comparison report from another company' do
      get :show, id: comparison_report.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
    end

    it 'should not let user see form of the report from another company' do
      get :index, id: summary_report.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
    end

    it 'should not let user to print report from another company' do
      get :print, id: summary_report.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
    end

    it 'should not let user edit report from another company' do
      put :update, id: summary_report.id, 
        report: { 
          send_to_emails: 'cracker@blackhatdev.com'
        }
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(summary_report.send_to_emails).not_to eq('cracker@blackhatdev.com')
    end

    it 'should not let user delete reports from another company' do
      delete :destroy, id: summary_report.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(::Report.where(kind: 'summary').count).to eq(1)
    end

    it 'should not be able to send report from another company' do
      post :send_report, id: summary_report.id, send_to_emails: 'hack@dev.com'
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(::SendReportWorker.jobs.size).to eq(0)
      expect(summary_report.reload.send_to_emails).not_to eq('hack@dev.com')
    end

  end
end
