# Copyright 2026 Esri
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
