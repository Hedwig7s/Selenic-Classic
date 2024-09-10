
local record http
    record response
        on: function(self:response,event:string, function(...:any))
        statusCode: integer
        headers: {string:string}
    end
    get: function(url:string, function(res:response))
end
return http