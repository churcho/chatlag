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
      media_content: media_content,
      room_id: room_id,
      id: id
    } = msg

    case mtype do
      nil ->
        :error

      _ ->
        [_, _, ext] = Regex.run(~r/(.*)\/(.*)/, mtype)

        IO.puts("Try to save the file ")

        case storage_dir(room_id) do
          {fullDir, strDir} ->
            IO.inspect(media_content, label: "Content ")

            case File.write!("#{fullDir}/#{id}.#{ext}", media_content) do
              :ok ->
                "#{strDir}/#{id}.#{ext}"

              _ ->
                IO.puts("No write: #{fullDir}/#{id}.#{ext}")
                :error
            end

          :error ->
            "storage dir error"
            :error
        end
    end
  end
end
