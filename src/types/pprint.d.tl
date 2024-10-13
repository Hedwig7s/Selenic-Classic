local record pprint
    metamethod __call: function(self:pprint,...:any)
    enum object_cache_options
        "local"
        "global"
    end
    record options
        show_metatable: boolean
        show_all: boolean
        use_tostring: boolean
        filter_function: function(v:any,k?:any,t?:table):boolean
        object_cache: object_cache_options | boolean
        indent_size: number
        level_width: number
        wrap_string: boolean
        wrap_array: boolean
        sort_keys: boolean
    end
    setup: function(options:options)
    defaults: options
    pformat: function(obj:any, options?:options, printer?:function(...:string)):string
end
return pprint