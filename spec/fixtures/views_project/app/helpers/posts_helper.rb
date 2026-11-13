# frozen_string_literal: true

module PostsHelper
  def post_title(post)
    post.title.upcase
  end
end
