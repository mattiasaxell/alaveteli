require 'spec_helper'

RSpec.describe AlaveteliPro::ProjectsController, type: :controller do
  let(:ability) { Object.new.extend(CanCan::Ability) }

  let(:pro_user) { FactoryBot.create(:pro_user) }
  let(:project) { FactoryBot.create(:project, owner: pro_user) }

  let(:batch1) { FactoryBot.create(:info_request_batch, user: pro_user) }
  let(:batch2) { FactoryBot.create(:info_request_batch, user: pro_user) }
  let(:request1) { FactoryBot.create(:info_request, user: pro_user) }
  let(:request2) { FactoryBot.create(:info_request, user: pro_user) }

  before do
    sign_in(pro_user)
    ability.can :edit, project
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  describe 'GET #index' do
    it 'assigns @projects' do
      get :index
      expect(assigns(:projects)).to eq([project])
    end
  end

  describe 'GET #new' do
    it 'assigns a new project to @project' do
      get :new
      expect(assigns(:project)).to be_a_new(Project)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new project' do
        expect {
          post :create, params: { project: FactoryBot.attributes_for(:project) }
        }.to change(Project, :count).by(1)
      end

      it 'redirects to the next step' do
        post :create, params: { project: FactoryBot.attributes_for(:project) }
        expect(response).to redirect_to(
          requests_alaveteli_pro_project_path(Project.last)
        )
      end
    end

    context 'with invalid attributes' do
      it 'does not save the new project' do
        expect {
          post :create,
          params: { project: FactoryBot.attributes_for(:project, title: nil) }
        }.not_to change(Project, :count)
      end

      it 're-renders the new template' do
        post :create,
          params: { project: FactoryBot.attributes_for(:project, title: nil) }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested project to @project' do
      get :edit, params: { id: project.id }
      expect(assigns(:project)).to eq(project)
    end
  end

  describe 'PATCH #update' do
    context 'with valid attributes' do
      it 'updates the project' do
        patch :update,
          params: { id: project.id, project: { title: 'Updated Title' } }
        project.reload
        expect(project.title).to eq('Updated Title')
      end

      it 'redirects from edit to resources step' do
        patch :update,
          params: { id: project.id, project: { title: 'Updated Title' } }
        expect(response).to redirect_to(
          requests_alaveteli_pro_project_path(Project.last)
        )
      end
    end

    context 'when new project session and with valid attributes' do
      before do
        session[:new_project] = true
        allow(controller).to receive(:project_params).and_return({})
      end

      it 'redirects from edit to the resources step' do
        patch :update,
          params: { id: project.id, step: 'edit' }
        expect(response).to redirect_to(
          requests_alaveteli_pro_project_path(Project.last)
        )
      end

      it 'redirects from resources to the project' do
        project.requests << InfoRequest.first
        patch :update, params: { id: project.id, step: 'edit_resources' }
        expect(response).to redirect_to(
          project_path(Project.last)
        )
      end
    end

    context 'with invalid attributes' do
      it 'does not update the project' do
        patch :update,
          params: { id: project.id, step: 'edit', project: { title: nil } }
        project.reload
        expect(project.title).not_to be_nil
      end

      it 're-renders the edit template' do
        patch :update,
          params: { id: project.id, step: 'edit', project: { title: nil } }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'GET #edit_resources' do
    context 'when the user has associated batches, requests, and info requests' do
      before do
        pro_user.info_request_batches << batch1
        project.batches << batch1
        pro_user.info_requests << request1
        project.requests << request1
      end

      it 'assigns @batches' do
        get :edit_resources, params: { id: project.id }
        expect(assigns(:batches)).to eq([batch1])
      end

      it 'assigns @requests' do
        get :edit_resources, params: { id: project.id }
        expect(assigns(:requests)).to eq([request1])
      end

      it 'assigns @results' do
        get :edit_resources, params: { id: project.id }
        expect(assigns(:results)).to contain_exactly(request1)
      end

      it 'renders the edit_resources template' do
        get :edit_resources, params: { id: project.id }
        expect(response).to render_template(:edit_resources)
      end
    end

    context 'when the user has no associated batches, requests, or info requests' do
      it 'assigns an empty @batches' do
        get :edit_resources, params: { id: project.id }
        expect(assigns(:batches)).to be_empty
      end

      it 'assigns an empty @requests' do
        get :edit_resources, params: { id: project.id }
        expect(assigns(:requests)).to be_empty
      end

      it 'assigns an empty @results' do
        get :edit_resources, params: { id: project.id }
        expect(assigns(:results)).to be_empty
      end

      it 'renders the edit_resources template' do
        get :edit_resources, params: { id: project.id }
        expect(response).to render_template(:edit_resources)
      end
    end
  end

  describe 'PATCH #update_resources' do
    let(:updated_project_params) do
      {
        id: project.id,
        project: {
          batch_ids: [batch1.id, batch2.id],
          request_ids: [request1.id, request2.id]
        }
      }
    end

    it 'assigns updated @batches' do
      patch :update_resources, params: updated_project_params,
                               format: :turbo_stream
      expect(assigns(:batches)).to contain_exactly(batch1, batch2)
    end

    it 'assigns updated @requests' do
      patch :update_resources, params: updated_project_params,
                               format: :turbo_stream
      expect(assigns(:requests)).to contain_exactly(request1, request2)
    end

    it 'assigns @results based on query' do
      patch :update_resources,
          params: updated_project_params.merge(query: request1.title),
          format: :turbo_stream
      expect(assigns(:results)).to contain_exactly(request1)
    end

    it 'responds with Turbo Stream format' do
      patch :update_resources,
          params: updated_project_params,
          format: :turbo_stream
      expect(response.media_type).to eq Mime[:turbo_stream]
    end
  end
end
