class Api::V1::TrackerDetailController < Api::V1::BaseController
  before_action :set_tracker_detail

  def get_tracker_detail
    @tracker_details = Tracker::TrackerDetail.all
    render :json => { data: @tracker_details, success: "Successful" }, status: :ok
  end

  def create_tracker_detail
    @tracker_details = Tracker::TrackerDetail.new(tracker_params)
    if @tracker_details.save
      render :json => { data: @tracker_details, success: "Successful" }, status: :ok
    end
  end

  private
  def tracker_params
    params.require(:tracker_detail).permit(:tracker_id, :tracker_start_time ,:task_id)
  end

  def set_tracker_detail
      @tracker_details = Tracker::TrackerDetail.new
  end
end