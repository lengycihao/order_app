API : /api/waiter/cart/submit_order
参数：table_id   POST请求
请求成功之后切换到已点页面

帮我实现已点页面
1.页面由多个相同的模块组成（这个模块是由下单次数决定的）
2.这个模块白色背景，边距15,
3.第一行展示如下
    柱状条 第一次下单   space()    轮次：1/2  数量：4/6
4.下面是菜品列表
    UI和点餐的列表差不多，我把却别告诉你，原来点餐列表item的价格位置，已点的这里展示 配菜中
    没有增减模块，没有选规格模块，有一个价格和数量在item的右侧和左侧的模块顶部对齐，价格和数量上下排列
下面是已点的接口数据，这个界面的数据是在接口获取的
API:/api/waiter/order/current
参数：table_id
{
        "id": 10,
        "order_type": 1,
        "total_amount": "2735",
        "settled_amount": "0",
        "paid_amount": "0",
        "quantity": 101,
        "details": [
            {
                "times": 2,
                "times_str": "第2次下单",
                "round_str": "2/6",
                "quantity_str": "101/6",
                "total_amount": "0",
                "payment_status": 0,
                "payment_id": 0,
                "dishes": [
                    {
                        "id": 78,
                        "dish_id": 7,
                        "name": "标准汤面",
                        "quantity": 1,
                        "price": "15",
                        "menu_price": "15",
                        "price_increment": "0",
                        "unit_price": "15",
                        "tax_rate": "6",
                        "image": "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop&crop=center",
                        "allergens": [
                            {
                                "label": "花生",
                                "id": 1,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/huansheng.png"
                            },
                            {
                                "label": "坚果类",
                                "id": 2,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/jianguo.png"
                            },
                            {
                                "label": "海鲜类",
                                "id": 3,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/longxia.png"
                            }
                        ],
                        "options_str": "",
                        "round_str": "",
                        "quantity_str": "",
                        "cooking_status": 1,
                        "cooking_status_name": "In Attesa di Cucinare",
                        "process_status": 1,
                        "process_status_name": "Chiamato",
                        "cooking_timeout": "2025-09-12 10:56:52"
                    }
                ]
            },
            {
                "times": 1,
                "times_str": "第1次下单",
                "round_str": "2/6",
                "quantity_str": "100/6",
                "total_amount": "0",
                "payment_status": 0,
                "payment_id": 0,
                "dishes": [
                    {
                        "id": 76,
                        "dish_id": 4,
                        "name": "特色炖汤",
                        "quantity": 6,
                        "price": "0",
                        "menu_price": "0",
                        "price_increment": "0",
                        "unit_price": "0",
                        "tax_rate": "6",
                        "image": "https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=300&fit=crop&crop=center",
                        "allergens": [
                            {
                                "label": "花生",
                                "id": 1,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/huansheng.png"
                            },
                            {
                                "label": "坚果类",
                                "id": 2,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/jianguo.png"
                            },
                            {
                                "label": "海鲜类",
                                "id": 3,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/longxia.png"
                            }
                        ],
                        "options_str": "标准、常温",
                        "round_str": "",
                        "quantity_str": "",
                        "cooking_status": 1,
                        "cooking_status_name": "In Attesa di Cucinare",
                        "process_status": 1,
                        "process_status_name": "Chiamato",
                        "cooking_timeout": "2025-09-12 10:55:57"
                    },
                    {
                        "id": 77,
                        "dish_id": 4,
                        "name": "特色炖汤",
                        "quantity": 94,
                        "price": "2632",
                        "menu_price": "28",
                        "price_increment": "0",
                        "unit_price": "28",
                        "tax_rate": "6",
                        "image": "https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=300&fit=crop&crop=center",
                        "allergens": [
                            {
                                "label": "花生",
                                "id": 1,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/huansheng.png"
                            },
                            {
                                "label": "坚果类",
                                "id": 2,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/jianguo.png"
                            },
                            {
                                "label": "海鲜类",
                                "id": 3,
                                "icon": "https://testkt.oss-cn-shanghai.aliyuncs.com/longxia.png"
                            }
                        ],
                        "options_str": "标准、常温",
                        "round_str": "",
                        "quantity_str": "",
                        "cooking_status": 1,
                        "cooking_status_name": "In Attesa di Cucinare",
                        "process_status": 1,
                        "process_status_name": "Chiamato",
                        "cooking_timeout": "2025-09-12 10:55:57"
                    },
                    {
                        "id": 0,
                        "dish_id": 0,
                        "name": "大人",
                        "quantity": 1,
                        "price": "88",
                        "menu_price": "88",
                        "price_increment": "0",
                        "unit_price": "88",
                        "tax_rate": "0",
                        "image": "https://testkt.oss-cn-shanghai.aliyuncs.com/default_dish_list.png",
                        "allergens": null,
                        "options_str": "",
                        "round_str": "",
                        "quantity_str": "",
                        "cooking_status": 0,
                        "cooking_status_name": "",
                        "process_status": 0,
                        "process_status_name": "",
                        "cooking_timeout": ""
                    }
                ]
            }
        ],
        "payments": []
    }