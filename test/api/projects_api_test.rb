require 'test_helper'
require 'date'

class ProjectsApiTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include TestHelpers::AuthHelper
  include TestHelpers::JsonHelper

  def app
    Rails.application
  end

  def test_can_get_projects
    user = FactoryBot.create(:user, :student, enrol_in: 0)

    # Add username and auth_token to Header
    add_auth_header_for(user: user)

    get '/api/projects'
    assert_equal 200, last_response.status
  end

  def test_get_projects_with_streams_match
    unit = FactoryBot.create :unit, stream_count: 2, campus_count: 2, tutorials: 2, unenrolled_student_count: 0, part_enrolled_student_count: 0, inactive_student_count: 0
    project = unit.projects.first
    assert_equal 2, project.tutorial_enrolments.count

    # Add username and auth_token to Header
    add_auth_header_for(user: project.student)

    get '/api/projects'
    assert_equal 200, last_response.status
    assert_equal 1, last_response_body.count, last_response_body
  end


  def test_projects_returns_correct_number_of_projects
    user = FactoryBot.create(:user, :student, enrol_in: 2)

    # Add username and auth_token to Header
    add_auth_header_for(user: user)
    
    get '/api/projects'
    assert_equal 2, last_response_body.count
  end

  def test_projects_returns_correct_data
    user = FactoryBot.create(:user, :student, enrol_in: 2)

    # Add username and auth_token to Header
    add_auth_header_for(user: user)

    get '/api/projects'
    last_response_body.each do |data|
      project = user.projects.find(data['project_id'])
      assert project.present?, data.inspect

      assert_json_matches_model(project, data, %w(campus_id has_portfolio target_grade campus_id))
      assert_equal project.unit.name, data['unit_name'], data.inspect
      assert_equal project.unit.id, data['unit_id'], data.inspect
      assert_equal project.unit.code, data['unit_code'], data.inspect
      assert_json_matches_model(project.unit, data, %w(teaching_period_id active))
    end
  end

  def test_projects_works_with_inactive_units
    user = FactoryBot.create(:user, :student, enrol_in: 2)
    Unit.last.update(active: false)

    # Add username and auth_token to Header
    add_auth_header_for(user: user)

    get '/api/projects'
    assert_equal 1, last_response_body.count

    get '/api/projects?include_inactive=false'
    assert_equal 1, last_response_body.count

    get '/api/projects?include_inactive=true'

    assert_equal 2, last_response_body.count

    last_response_body.each do |data|
      project = user.projects.find(data['project_id'])
      assert project.present?, data.inspect

      assert_json_matches_model(project, data, %w(campus_id has_portfolio target_grade campus_id))
      assert_equal project.unit.name, data['unit_name'], data.inspect
      assert_equal project.unit.id, data['unit_id'], data.inspect
      assert_equal project.unit.code, data['unit_code'], data.inspect
      assert_json_matches_model(project.unit, data, %w(teaching_period_id active))
    end
  end

  def test_submitted_grade_cant_change_after_submission
    user = FactoryBot.create(:user, :student, enrol_in: 1)
    project = user.projects.first

    data_to_put = {
      id: project.id,
      submitted_grade: 2
    }

    add_auth_header_for(user: user)

    put_json "/api/projects/#{project.id}", data_to_put

    assert_equal 200, last_response.status
    assert_equal user.projects.find(project.id).submitted_grade, 2

    DatabasePopulator.generate_portfolio(project)
    
    data_to_put['submitted_grade'] = 1

    put_json with_auth_token("/api/projects/#{project.id}", user), data_to_put

    assert_not_equal user.projects.find(project.id).submitted_grade, 1
    assert_equal 403, last_response.status
  end
end
