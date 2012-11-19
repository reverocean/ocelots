require 'team_filter'

class TeamsController < ApplicationController
  include TeamFilter

  def index
    @memberships = current_person.memberships.select{|membership| membership.ended==nil}
    @team = Team.new
    @organisations = Organisation.find(:all)
  end

  def create

    @teams = current_person.teams
    @team = Team.new params[:team].merge creator: current_person
    if @team.save
      if org = current_person.get_organisation_by_email
        org.teams << @team
      end

      current_person.teams << @team

      redirect_to "/teams/#{@team.slug}"
    else
      render :index
    end
  end

  def add
    with_team do |team|
      person = Person.find_by_email params[:email]
      person = Person.create_for_email params[:email] unless person
      unless person.teams.include? team
        unless person == current_person
          Membership.create_pending_membership current_person, team, person
        end
      end
      redirect_to "/teams/#{team.slug}"
    end
  end

  def show
    with_team { render :show }
  end

  def avatars
    with_team { render :avatars, layout: 'no_header' }
  end

  def quiz
    with_team do |team|
      @people = team.people.sample 5
      @person = @people.sample
      @facts = @person.facts.sample 3
      render :quiz
    end
  end

  def join
    with_team do |team|
      current_person.join team
      redirect_to "/teams/#{team.slug}"
    end
  end

  def quit
    with_team do |team|
      current_person.leave team
    end
    redirect_to "/teams"
  end
end