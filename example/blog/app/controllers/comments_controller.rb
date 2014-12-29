class CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy]
  before_action :set_post, only: [:new, :create, :destroy, :update]

  # GET /comments/new
  def new
    @comment = Comment.new
  end

  # POST /comments
  # POST /comments.json
  def create
    @comment = Comment.new(comment_params)

    respond_to do |format|
      if @comment.save
        # using the ActiveRel model to create the relationship
        # callbacks, validations would run
        # it will be timestamped as any other model since a :created_at property is present
        PostComment.create(from_node: @post, to_node: @comment)
        # alternatives
        # @post.comments << @comment
        # or
        # create a relationship with a created property between post and comment
        # @post.comments.create(@comment, :created => Time.now.to_i)


        format.html { redirect_to @post, notice: 'Comment was successfully created.' }
        format.json { render action: 'show', status: :created, location: @comment }
      else
        format.html { render action: 'new' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to @comment, notice: 'Comment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    # it will automatically destroy the relationship as well
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to @post }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_comment
    @comment = Comment.find(params[:id])
  end

  def set_post
    @post = Post.find(params[:post_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def comment_params
    params[:comment]
  end
end
