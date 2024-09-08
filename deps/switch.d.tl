local type switch = function(case:any): function(casetable:{any:function(case:any):any}): any
return switch