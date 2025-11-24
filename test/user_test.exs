defmodule ArcGIS.Test.User do
  use ArcGIS.Test.Helper
  doctest ArcGIS.User

  test "Translates a map to a user struct" do
    Req.Test.stub(ArcGIS, fn conn ->
      assert(conn.request_path == "/sharing/rest/community/self")
      Req.Test.json(conn, Fixtures.Network.json("user"))
    end)

    assert ArcGIS.User.from_token(Fixtures.portal(), "fake_token") == {:ok, Fixtures.user()}
  end

  test "Confirm user privilege" do
    assert ArcGIS.User.can?(Fixtures.user(), "premium:user:spatialanalysis")
  end

  test "Confirm user lacks privilege" do
    refute ArcGIS.User.can?(Fixtures.user(), "fatulations:user:spatialanalysis")
  end

  test "Fetches a token" do
    Req.Test.stub(ArcGIS, fn conn ->
      assert(conn.request_path == "/sharing/rest/generateToken")
      Req.Test.json(conn, Fixtures.Network.json("token_success"))
    end)

    assert {:ok, token} = ArcGIS.User.generate_token("user", "pass", Fixtures.portal())
    assert is_binary(token)
  end

  test "Handled token request failure" do
    Req.Test.stub(ArcGIS, fn conn ->
      assert(conn.request_path == "/sharing/rest/generateToken")
      Req.Test.json(conn, Fixtures.Network.json("token_failure"))
    end)

    assert {:error, "Unable to generate token."} =
             ArcGIS.User.generate_token("user", "pass", Fixtures.portal())
  end
end
