local http = require "resty.http"
local servers_str = os.getenv("SERVERS")
if not servers_str then
    ngx.log(ngx.ERR, "No servers found in environment variable")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local servers = {}
for server in string.gmatch(servers_str, "[^%s]+") do
    table.insert(servers, server)
end

local httpc = http.new()
local configs = {}
local total_upload = 0
local total_download = 0
local first_total = nil
local first_expire = nil

for idx, base_url in ipairs(servers) do
    local url = base_url .. ngx.var.sub_id
    local res, err = httpc:request_uri(url, {
        method = "GET",
        ssl_verify = false,
    })
    if res and res.status == 200 then
        local decoded_config = ngx.decode_base64(res.body)
        if decoded_config then
            table.insert(configs, decoded_config)
        else
            ngx.log(ngx.ERR, "Failed to decode base64 from ", url)
        end

        local userinfo = res.headers["Subscription-Userinfo"]
        if userinfo then
            local upload = userinfo:match("upload=(%d+)")
            local download = userinfo:match("download=(%d+)")
            local total = userinfo:match("total=(%d+)")
            local expire = userinfo:match("expire=(%d+)")

            if upload then total_upload = total_upload + tonumber(upload) end
            if download then total_download = total_download + tonumber(download) end

            if idx == 1 then
                if total then first_total = tonumber(total) end
                if expire then first_expire = tonumber(expire) end
            end
        else
            ngx.log(ngx.WARN, "No Subscription-Userinfo header from ", url)
        end
    else
        ngx.log(ngx.ERR, "Error fetching from ", url, ": ", err)
    end
end

if #configs > 0 then
    local final_total = first_total or 0
    local final_expire = first_expire or 0
    local final_userinfo = string.format(
        "upload=%d; download=%d; total=%d; expire=%d",
        total_upload, total_download, final_total, final_expire
    )
    ngx.header["Subscription-Userinfo"] = final_userinfo

    local combined_configs = table.concat(configs)
    local encoded_combined_configs = ngx.encode_base64(combined_configs)
    ngx.header.content_type = "text/plain; charset=utf-8"
    ngx.print(encoded_combined_configs)
else
    ngx.status = ngx.HTTP_BAD_GATEWAY
    ngx.say("No configs available")
end