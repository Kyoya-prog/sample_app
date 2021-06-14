require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test "micropost interface" do
    log_in_as @user
    get root_path
    assert_select 'div.pagination'
    assert_select 'input[type=file]'
    # 無効な送信
    assert_no_difference 'Micropost.count' do
      post microposts_path,params:{micropost:{content:""}}
    end
    assert_select 'div#error_explanation'
    assert_select 'a[href=?]', '/?page=2'  # 正しいページネーションリンク
    # 有効な送信
    content = "This is valid micropost content"
    image = fixture_file_upload('test/fixtures/kitten.jpg', 'image/jpeg')
    assert_difference 'Micropost.count',1  do
      post microposts_path,params:{micropost:{content:content,image:image}}
    end
    assert assigns(:micropost).image.attached?
    assert_redirected_to root_url
    follow_redirect!
    assert_match content,response.body
    #　投稿の削除
    assert_select 'a',text:'delete'
    first_micropost = @user.microposts.paginate(page:1).first
    assert_difference 'Micropost.count',-1 do
      delete micropost_path(first_micropost)
    end
    # 違うユーザーの時は削除リンクを表示しない
    get user_path(users(:archer))
    assert_select 'a',text:"delete",count:0
  end
end
