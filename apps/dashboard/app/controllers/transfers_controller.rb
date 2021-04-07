class TransfersController < ApplicationController
  # before_action only: [:show, :destroy] do
  #   request.format = :json
  # end

  # TODO: mv create here
  # then expand the interface for multiple strategies
  # 2 controllers, 1 model?
  #
  def index
    @transfers = Transfer.transfers

    # FIXME: this can be addressed by react based transfers view
    # or otherwise clientside
    #
    # or would just be handled by SSE events if we could maintain this
    # or actioncable for server events (like these directories CHANGED)
    #
    @table_needs_reloaded = @transfers.any? {|t|
      # FIXME: better handled by a Transfer model

      if t.status.completed? && t.completed_at && t.completed_at >= params['current_directory_updated_at'].to_i
        if t.action == "rm"
          Pathname.new(t.from).cleanpath == Pathname.new(params['current_directory']).cleanpath
        else
          Pathname.new(t.to).cleanpath == Pathname.new(params['current_directory']).cleanpath
        end
      end
    }

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @transfer = Transfer.find(params[:id])
    if(@transfer)
      respond_to do |format|
        format.html
        format.json
      end
    else
      respond_to do |format|
        format.html
        format.json { render json: {}, status: 404 }
      end
    end
  end

  def create
    body_params = JSON.parse(request.body.read).symbolize_keys
    @transfer = Transfer.build(action: body_params[:command], files: body_params[:files])
    if ! @transfer.valid?
      # error
      render json: { error_message: @transfer.errors.full_messages.join('. ') }
    elsif @transfer.synchronous?
      @transfer.perform

      respond_to do |format|
        format.json { render :show }
      end
    else
      @transfer.perform_later

      respond_to do |format|
        format.json { render :show }
      end
    end
  end

  def destroy
    TransferLocalJob.cancel(params[:id])
  rescue StandardError => e
    render json: { error: e.message }, status: 500
  end
end
