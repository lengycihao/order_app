发送消息
基本格式：

{
    "id": "随机生成的id,回复时会原样返回",
    "type": "类型",
    "data": "具体业务数据",
    "timestamp": "时间戳"
}
type 类型
cart 购物车业务

购物车业务action类型
add 添加

update 修改

delete 删除

clear 清空

 
添加示例：

{
    "id": "1755739492876irb4lh",
    "type": "cart",
    "data": {
        "action": "add",
        "options": [
            {
                "id": 3,
                "item_ids": [
                    7
                ],
                "custom_values": [

                ]
            },
            {
                "id": 4,
                "item_ids": [
                    9
                ],
                "custom_values": [

                ]
            }
        ],
         "force_operate": true, // 强制操作
        "dish_id": 2,
        "quantity": 1
    },
    "timestamp": 1755739492
}
修改示例：

{
    "id": "1755758043673qa5z8d", 
    "type": "cart", 
    "data": {
        "action": "update", 
        "quantity": 2, 
        "cart_id": 2, 
        "cart_specification_id": 3
    }, 
    "timestamp": 1755758043
}
删除示例：

{
    "id": "1755758043673qa5z8d", 
    "type": "cart", 
    "data": {
        "action": "delete",
        "cart_specification_id": 3
    }, 
    "timestamp": 1755758043
}
清空示例：

{
    "id": "1755758043673qa5z8d", 
    "type": "cart", 
    "data": {
        "action": "clear",
    }, 
    "timestamp": 1755758043
}
接收消息
{
    "id": "id",
    "type": "类型",
    "data": "业务数据",
    "timestamp": "时间戳"
}
示例：

{
    "id": "1755739492876irb4lh",
    "type": "cart_response",
    "data": {
        "success": true,
        "message": "操作成功",
        "original_id": "1755739492876irb4lh"
    },
    "timestamp": 1755739492
}
修改菜单消息
{
    "id": "1755739492876irb4lh",
    "type": "table",
    "data": {
        "action": "change_menu"
        "menu_id": 1
    },
    "timestamp": 1755739492
}
修改人数消息
{
    "id": "1755739492876irb4lh",
    "type": "table",
    "data": {
        "action": "change_people_count"
        "adult_count": 2,
        "child_count": 1
    },
    "timestamp": 1755739492
}
更换桌子消息
{
    "id": "1755739492876irb4lh",
    "type": "table",
    "data": {
        "action": "change_table"
        "table_id": 2,
        "table_name": "桌名"
    },
    "timestamp": 1755739492
}
刷新购物车消息
{
    "id": "1755739492876irb4lh",
    "type": "order",
    "data": {
        "action": "refresh"
    },
    "timestamp": 1755739492
}