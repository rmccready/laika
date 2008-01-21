class RegistrationInformationController < ApplicationController

  before_filter :find_patient_data

  def new
    @registration_information = RegistrationInformation.new

    render :partial  => 'edit', :locals => {:registration_information =>  @registration_information,
                                            :patient_data => @patient_data}
  end

  def edit
    @registration_information = @patient_data.registration_information
    render :partial  => 'edit', :locals => {:registration_information =>  @registration_information,
                                            :patient_data => @patient_data}
  end

  def create
    @registration_information = RegistrationInformation.new(params[:registration_information])
    @patient_data.registration_information = @registration_information
    render :partial  => 'show', :locals => {:registration_information =>  @registration_information,
                                            :patient_data => @patient_data}
  end

  def update
    @registration_information = @patient_data.registration_information
    @registration_information.update_attributes(params[:registration_information])
    
    render :partial  => 'show', :locals => {:registration_information =>  @registration_information,
                                            :patient_data => @patient_data}
  end

  def destroy
    @registration_information = @patient_data.registration_information
    @registration_information.destroy

    redirect_to patient_data_url
  end
  
  private
  
  def find_patient_data
    @patient_data_id = params[:patient_data_id]
    redirect_to patient_data_url unless @patient_data_id
    @patient_data = PatientData.find(@patient_data_id)
  end
end