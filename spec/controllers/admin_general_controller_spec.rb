require 'spec_helper'

RSpec.describe AdminGeneralController do
  describe "GET #index" do
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    before do
      InfoRequest.destroy_all
    end

    it "should render the front page" do
      sign_in admin_user
      get :index
      expect(response).to render_template('index')
    end

    it 'assigns a count of old unclassified requests' do
      FactoryBot.create_list(:old_unclassified_request, 2)
      sign_in admin_user
      get :index
      expect(assigns[:old_unclassified_count]).to eq(2)
    end

    it 'assigns old unclassified requests' do
      @old_request = FactoryBot.create(:old_unclassified_request)
      sign_in admin_user
      get :index
      expect(assigns[:old_unclassified]).to eq([@old_request])
    end

    it 'assigns requests that require admin to the view' do
      requires_admin_request = FactoryBot.create(:requires_admin_request)
      sign_in admin_user
      get :index
      expect(assigns[:requires_admin_requests]).to eq([requires_admin_request])
    end

    it 'assigns requests that have error messages to the view' do
      error_message_request = FactoryBot.create(:error_message_request)
      sign_in admin_user
      get :index
      expect(assigns[:error_message_requests]).to eq([error_message_request])
    end

    it 'assigns requests flagged for admin attention to the view' do
      attention_requested_request = FactoryBot.create(
        :attention_requested_request
      )
      sign_in admin_user
      get :index
      expect(assigns[:attention_requests]).to eq([attention_requested_request])
    end

    it 'assigns messages sent to the holding pen to the view' do
      undeliverable = FactoryBot.
                        create(:incoming_message,
                               info_request: InfoRequest.holding_pen_request)
      sign_in admin_user
      get :index
      expect(assigns[:holding_pen_messages]).to eq([undeliverable])
    end

    context 'when there are request tasks' do
      it 'assigns public_request_tasks to true' do
        undeliverable = FactoryBot.
                          create(:incoming_message,
                                 info_request: InfoRequest.holding_pen_request)
        sign_in admin_user
        get :index
        expect(assigns[:public_request_tasks]).to be true
      end
    end

    context 'when there are no request tasks' do
      it 'assigns public_request_tasks to false' do
        sign_in admin_user
        get :index
        expect(assigns[:public_request_tasks]).to be false
      end
    end

    it 'assigns blank contacts to the view' do
      blank_contact = FactoryBot.create(:blank_email_public_body)
      sign_in admin_user
      get :index
      expect(assigns[:blank_contacts]).to eq([blank_contact])
    end

    it 'limits blank contacts to 20' do
      25.times { FactoryBot.create(:blank_email_public_body) }
      sign_in admin_user
      get :index
      expect(assigns[:blank_contacts].count).to eq(20)
    end

    it 'assigns new body request to the view' do
      add_body_request = FactoryBot.create(:add_body_request)
      sign_in admin_user
      get :index
      expect(assigns[:new_body_requests]).to eq([add_body_request])
    end

    it 'assigns body update requests to the view' do
      update_body_request = FactoryBot.create(:update_body_request)
      sign_in admin_user
      get :index
      expect(assigns[:body_update_requests]).to eq([update_body_request])
    end

    context 'when there are authority tasks' do
      it 'assigns authority tasks to true' do
        update_body_request = FactoryBot.create(:update_body_request)
        sign_in admin_user
        get :index
        expect(assigns[:authority_tasks]).to be true
      end
    end

    context 'when there are no authority tasks' do
      it 'assigns authority tasks to false' do
        sign_in admin_user
        get :index
        expect(assigns[:authority_tasks]).to be false
      end
    end

    it 'assigns comments requiring attention to the view' do
      comment = FactoryBot.create(:attention_requested_comment)
      sign_in admin_user
      get :index
      expect(assigns[:attention_comments]).to eq([comment])
    end

    context 'when there are comment tasks' do
      it 'assigns comment tasks to true' do
        comment = FactoryBot.create(:attention_requested_comment)
        sign_in admin_user
        get :index
        expect(assigns[:comment_tasks]).to be true
      end
    end

    context 'when there are no authority tasks' do
      it 'assigns authority tasks to false' do
        sign_in admin_user
        get :index
        expect(assigns[:comment_tasks]).to be false
      end
    end

    context 'when there is nothing to do' do
      it 'assigns nothing to do to true' do
        sign_in admin_user
        get :index
        expect(assigns[:nothing_to_do]).to be true
      end
    end

    context 'when there is something to do' do
      it 'assigns nothing to do to false' do
        comment = FactoryBot.create(:attention_requested_comment)
        sign_in admin_user
        get :index
        expect(assigns[:nothing_to_do]).to be false
      end
    end

    context 'when the user is not a pro admin' do
      context 'when pro is enabled' do
        it 'does not assign embargoed requests that require admin to the view' do
          with_feature_enabled(:alaveteli_pro) do
            requires_admin_request = FactoryBot.create(:requires_admin_request)
            requires_admin_request.create_embargo
            sign_in admin_user
            get :index
            expect(assigns[:requires_admin_requests]).to eq([])
            expect(assigns[:embargoed_requires_admin_requests]).to be nil
          end
        end

        it 'does not assign embargoed requests that have error messages to the view' do
          with_feature_enabled(:alaveteli_pro) do
            error_message_request = FactoryBot.create(:error_message_request)
            error_message_request.create_embargo
            sign_in admin_user
            get :index
            expect(assigns[:error_message_requests]).to eq([])
            expect(assigns[:embargoed_error_message_requests]).to be nil
          end
        end

        it 'does not assign embargoed requests flagged for admin attention to the view' do
          with_feature_enabled(:alaveteli_pro) do
            attention_requested_request = FactoryBot.create(
              :attention_requested_request
            )
            attention_requested_request.create_embargo
            sign_in admin_user
            get :index
            expect(assigns[:attention_requests]).to eq([])
            expect(assigns[:embargoed_attention_requests]).to be nil
          end
        end
      end

      it 'does not assign embargoed requests that require admin to the view' do
        requires_admin_request = FactoryBot.create(:requires_admin_request)
        requires_admin_request.create_embargo
        sign_in admin_user
        get :index
        expect(assigns[:requires_admin_requests]).to eq([])
        expect(assigns[:embargoed_requires_admin_requests]).to be nil
      end

      it 'does not assign embargoed requests that have error messages to the view' do
        error_message_request = FactoryBot.create(:error_message_request)
        error_message_request.create_embargo
        sign_in admin_user
        get :index
        expect(assigns[:error_message_requests]).to eq([])
        expect(assigns[:embargoed_error_message_requests]).to be nil
      end

      it 'does not assign embargoed requests flagged for admin attention to
          the view' do
        attention_requested_request =
          FactoryBot.create(:attention_requested_request)
        attention_requested_request.create_embargo
        sign_in admin_user
        get :index
        expect(assigns[:attention_requests]).to eq([])
        expect(assigns[:embargoed_attention_requests]).to be nil
      end
    end

    context 'when the user is a pro admin and pro is enabled' do
      it 'assigns embargoed requests that require admin to the view' do
        with_feature_enabled(:alaveteli_pro) do
          requires_admin_request = FactoryBot.create(:requires_admin_request)
          requires_admin_request.create_embargo
          sign_in pro_admin_user
          get :index
          expect(assigns[:embargoed_requires_admin_requests]).
            to eq([requires_admin_request])
        end
      end

      it 'assigns embargoed requests that have error messages to the view' do
        with_feature_enabled(:alaveteli_pro) do
          error_message_request = FactoryBot.create(:error_message_request)
          error_message_request.create_embargo
          sign_in pro_admin_user
          get :index
          expect(assigns[:embargoed_error_message_requests]).
            to eq([error_message_request])
        end
      end

      it 'assigns embargoed requests flagged for admin attention to the view' do
        with_feature_enabled(:alaveteli_pro) do
          attention_requested_request =
            FactoryBot.create(:attention_requested_request)
          attention_requested_request.create_embargo
          sign_in pro_admin_user
          get :index
          expect(assigns[:embargoed_attention_requests]).
            to eq([attention_requested_request])
        end
      end

      context 'when there is nothing to do' do
        it 'assigns nothing to do to true' do
          sign_in pro_admin_user
          get :index
          expect(assigns[:nothing_to_do]).to be true
        end
      end

      context 'when there is something to do' do
        it 'assigns nothing to do to false' do
          with_feature_enabled(:alaveteli_pro) do
            attention_requested_request =
              FactoryBot.create(:attention_requested_request)
            attention_requested_request.create_embargo
            sign_in pro_admin_user
            get :index
            expect(assigns[:nothing_to_do]).to be false
          end
        end
      end
    end
  end

  describe 'GET #timeline' do
    before do
      info_request = FactoryBot.create(:info_request)
      public_body = FactoryBot.create(:public_body)
      @first_request_event = info_request.log_event('edit', {})
      public_body.name = 'Changed name'
      public_body.save!
      @first_public_body_version = public_body.versions.latest
      @second_request_event = info_request.log_event('edit', {})
      public_body.name = 'Changed name again'
      public_body.save!
      public_body.reload
      @second_public_body_version = public_body.versions.latest
      get :timeline, params: { all: 1 }
    end

    it 'assigns an array of events in order of descending date to the view' do
      expect(assigns[:events].first.first).to eq(@second_public_body_version)
      expect(assigns[:events].second.first).to eq(@second_request_event)
      expect(assigns[:events].third.first).to eq(@first_public_body_version)
      expect(assigns[:events].fourth.first).to eq(@first_request_event)
    end

    it 'sets the title appropriately' do
      expect(assigns[:events_title]).to eq("All events in the last 2 days")
    end

    context 'when start_date is set' do
      before do
        get :timeline, params: { all: 1, start_date: Time.utc(1970, 1, 1) }
      end

      it 'sets the title appropriately' do
        expect(assigns[:events_title]).to eq("All events, all time")
      end
    end

    context 'when event_type is info_request_event' do
      before do
        get :timeline, params: { all: 1, event_type: 'info_request_event' }
      end

      it 'assigns an array of info request events in order of descending
          date to the view' do
        expect(assigns[:events].first.first).to eq(@second_request_event)
        expect(assigns[:events].second.first).to eq(@first_request_event)
      end

      it 'sets the title appropriately' do
        expect(assigns[:events_title]).to eq(
          "Request events in the last 2 days"
        )
      end
    end

    context 'when event_type is authority_change' do
      before do
        get :timeline, params: { all: 1, event_type: 'authority_change' }
      end

      it 'assigns an array of public body versions in order of descending
          date to the view' do
        expect(assigns[:events].first.first).to eq(@second_public_body_version)
        expect(assigns[:events].second.first).to eq(@first_public_body_version)
      end

      it 'sets the title appropriately' do
        expect(assigns[:events_title]).to eq(
          "Authority changes in the last 2 days"
        )
      end
    end
  end
end
