# defmodule PwdlessGsWeb.UserSocket do
#   @behaviour Phoenix.Socket.Transport
#   # use Phoenix.Socket

#   alias PwdlessGs
#   alias PwdlessGs.Repo

#   # ## Transports
#   # transport(:websocket, Phoenix.Transports.WebSocket)

#   def connect(%{"token" => token}, socket) do
#     case Repo.verify_token(token) do
#       {:ok, email} ->
#         {:ok, assign(socket, :user, %{email: email})}

#       _ ->
#         :error
#     end
#   end

#   def connect(_, _socket), do: :error

#   def id(socket), do: "user_socket:#{socket.assigns.user.email}"
# end
