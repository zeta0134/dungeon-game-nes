.macpack longbranch

.macro branch_if_equal value, target_address
        cmp value
        jeq target_address
.endmacro

.macro branch_if_not_equal value, target_address
        cmp value
        jne target_address
.endmacro

.macro branch_if_gte value, target_address
        cmp value
        jcs target_address
.endmacro

.macro branch_if_lt value, target_address
        cmp value
        jcc target_address
.endmacro






