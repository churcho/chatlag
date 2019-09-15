defmodule ChatlagWeb.UploadMedia do
  alias Chatlag.Chat.Message

  def storage_dir(room_id) do
    ymDir = Timex.today() |> Timex.format!("%Y/%m", :strftime)
    strDir = "uploads/messages/#{ymDir}/#{room_id}"

    {:ok, dir} = File.cwd()
    fullDir = "#{dir}/#{strDir}"

    case File.mkdir_p(fullDir) do
      :ok ->
        {fullDir, "/#{strDir}"}

      _ ->
        IO.puts("error: #{fullDir}")
        :error
    end

    # "#{File.cwd()}/uploads/users/#{room_id}/#{msg_id}"
  end

  def save_media(msg) do
    # IO.inspect(storage_dir(msg[:room_id], msg[:id]), label: "store image to")
    %Message{
      media_type: mtype,
      media_name: media_name,
      room_id: room_id,
      id: id
    } = msg

    case mtype do
      nil ->
        :error

      _ ->
        [_, _, ext] = Regex.run(~r/(.*)\/(.*)/, mtype)

        case storage_dir(room_id) do
          {fullDir, strDir} ->
            res = File.cp!("./uploads/tmp/#{media_name}", ".#{strDir}/#{id}.#{ext}")

            case res do
              :ok ->
                File.rm("./uploads/tmp/#{media_name}")
                :timer.sleep(300)
                "#{strDir}/#{id}.#{ext}"

              _ ->
                IO.puts("No write: #{fullDir}/#{id}.#{ext}")
                :error
            end

          :error ->
            :error
        end
    end
  end
end
