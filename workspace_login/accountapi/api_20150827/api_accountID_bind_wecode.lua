
local ngx            = require ('ngx')
local sha            = require('sha1')
local utils          = require('utils')
local app_utils = require('app_utils')
local only           = require('only')
local msg            = require('msg')
local gosay          = require('gosay')
local safe           = require('safe')
local link           = require('link')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api       = require('http_short_api')

local get_imei = link["OWN_DIED"]["http"]["getMirrtalkInfoByImei"]

local get_one = link["OWN_DIED"]["http"]["getTrustAuthCode"]

local get_two = link["OWN_DIED"]["http"]["getTrustAccessCode"]

local disaccount = link["OWN_DIED"]["http"]["disconnectAccount"]


local function disaccount_imei(accountID, accessToken, appKey )
    local  tab = {
        appKey = appKey,
        accessToken =  accessToken,
        accountID =  accountID,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)

    local post_data = 'POST /accountapi/v2/disconnectAccount HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    local data = string.format(post_data, get_two['host'], get_two['port'], #body, body)
    local ret = http_api.http(get_two, data, true)

    if not ret then 
        only.log('E',"addCustomAccount failed!")
        return nil 
    end
    local body = string.match(ret, '{.+}')
    if not body then
        only.log('E',"addCustomAccount succed but return failed!")
        return nil
    end

    local ok, json_data = utils.json_decode(body)
    if not ok or tonumber(json_data['ERRORCODE']) ~= 0 then
      return nil
    else
      return json_data['RESULT']
    end
end


local function get_oauth_two( authorizationCode, grantType, scope, accountID, appKey )
    local  tab = {
        appKey = appKey,
        authorizationCode =  authorizationCode,
        grantType =  grantType,
        scope =  scope,
        accountID =  accountID,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)

    local post_data = 'POST /oauth/v2/getTrustAccessCode HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    local data = string.format(post_data, get_two['host'], get_two['port'], #body, body)
    local ret = http_api.http(get_two, data, true)

    if not ret then 
        only.log('E',"addCustomAccount failed!")
        return nil 
    end
    local body = string.match(ret, '{.+}')
    if not body then
        only.log('E',"addCustomAccount succed but return failed!")
        return nil
    end

    local ok, json_data = utils.json_decode(body)
    if not ok or tonumber(json_data['ERRORCODE']) ~= 0 then
      return nil
    else
      return json_data['RESULT']['accessToken']
    end
end



local function get_oauth_one( accountID, scope, appKey )      
    local  tab = {
        appKey = appKey,
        accountID =  accountID,
        scope =  scope,

    }
    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)

    local post_data = 'POST /oauth/v2/getTrustAuthCode HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    local data = string.format(post_data, get_one['host'], get_one['port'], #body, body)
    local ret = http_api.http(get_one, data, true)

    if not ret then 
        only.log('E',"addCustomAccount failed!")
        return nil 
    end
    local body = string.match(ret, '{.+}')
    if not body then
        only.log('E',"addCustomAccount succed but return failed!")
        return nil
    end

    local ok, json_data = utils.json_decode(body)
    if not ok or tonumber(json_data['ERRORCODE']) ~= 0 then
      return nil
    else
      return json_data['RESULT']['authorizationCode']
    end
end



local function get_imei_info(IMEI, appKey)      
    local  tab = {
        appKey = appKey,
        IMEI =  IMEI,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)

    local post_data = 'POST /accountapi/v2/getMirrtalkInfoByImei HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    local data = string.format(post_data, get_imei['host'], get_imei['port'], #body, body)
    local ret = http_api.http(get_imei, data, true)
  
    if not ret then 
        only.log('E',"addCustomAccount failed!")
        return nil 
    end
    local body = string.match(ret, '{.+}')
    if not body then
        only.log('E',"addCustomAccount succed but return failed!")
        return nil
    end
    
    local ok, json_data = utils.json_decode(body)
    if not ok or tonumber(json_data['ERRORCODE']) ~= 0 then
      return nil
    else
      return json_data['RESULT']['accountID']
    end
 end


local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

function headl( )
    
    local body = ngx.req.get_body_data()
    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body
    local res = utils.parse_url(body)

    url_info['app_key'] = res["appKey"]
    safe.sign_check(res, url_info)

    local accountID = get_imei_info(res["IMEI"], res["appKey"])
    local scope = "bindmirrtalk"
    local authorizationCode = get_oauth_one( accountID, scope, res["appKey"] )
    local grantType = "authorizationCode"
    local accessToken = get_oauth_two( authorizationCode, grantType, scope, accountID, res["appKey"] )

    local result= disaccount_imei(accountID, accessToken, res["appKey"] )

    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], result )

end





