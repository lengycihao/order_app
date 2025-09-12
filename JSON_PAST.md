我说错了，

修改人数不需要发送websocket，只需要调用接口就行了所以撤回上个需求
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
这是收到的ws消息，当type是table,action 是change_people_count时，需要更新页面人数，你直接取adult_count和child_count加起来的值去更新，就别请求桌台详情接口了
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
这个是收到的更换桌子消息，收到这个类型时，直接把桌名改成table_name对应的
{
    "id": "1755739492876irb4lh",
    "type": "cart",
    "data": {
        "action": "refresh"
    },
}收到这种时，去刷新购物车数据