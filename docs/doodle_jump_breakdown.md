# 简易涂鸦跳跃模块拆分

## 当前已实现内容

- 竖屏主场景与基础状态栏
- 玩家左右移动、重力下落、踩平台自动弹跳
- 左右穿屏
- 相机只向上跟随
- 平台持续生成、离屏回收
- 恒定平台、单次平台、移动平台、坚固平台
- 弹簧与火箭两种道具
- 基于爬升高度的计分
- 掉出镜头下方后结算、重开、返回主菜单
- 复用模板已有暂停菜单
- 平台与道具对象池复用，避免高频实例化和释放

## 核心目录

- `res://scenes/doodle_jump/doodle_jump_game.tscn`
- `res://scripts/doodle_jump/jumper_game.gd`
- `res://scripts/doodle_jump/jumper_player.gd`
- `res://scenes/doodle_jump/platforms/`
- `res://scripts/doodle_jump/platforms/`
- `res://scenes/doodle_jump/pickups/`
- `res://scripts/doodle_jump/pickups/`

## 职责拆分

### `doodle_jump_game.tscn`

- 提供竖屏主场景结构
- 组织背景层、平台容器、道具容器、玩家、相机、状态栏、失败面板、暂停菜单
- 为调试保留清晰的节点分层，方便后续继续扩展

### `jumper_game.gd`

- 负责一局游戏的启动与重置
- 维护相机、得分、失败状态
- 根据相机位置持续生成平台和道具
- 将离屏平台与道具回收到对象池
- 控制失败面板、重开、返回主菜单
- 统一管理不同平台和道具的生成概率

### `jumper_player.gd`

- 读取左右输入
- 处理水平加速度与重力
- 调用 `move_and_slide()` 完成角色运动
- 在下落踩中平台时自动触发反弹
- 处理火箭状态期间的持续上升
- 处理左右穿屏

### `platforms/*.gd`

- `base_platform.gd` 负责平台共用的激活、停用、碰撞体尺寸刷新、颜色刷新、回收信号
- `constant_platform.gd` 提供基础落脚点
- `single_use_platform.gd` 在玩家成功踩踏后请求回收
- `moving_platform.gd` 负责左右往返运动
- `solid_platform.gd` 提供不可从下方穿过的平台表现

### `pickups/*.gd`

- `base_pickup.gd` 负责道具共用的激活、停用、碰撞形状复用、消耗信号
- `spring_pickup.gd` 给玩家更强的单次弹跳速度
- `rocket_pickup.gd` 让玩家持续飞升一段时间并临时无视碰撞
- 道具都使用纯色圆球占位，半径与碰撞体一致

## 竖屏设计要点

- 项目视口改为 `720 x 1280`
- 关卡逻辑宽度同步改为 `720`
- 初始平台和玩家出生点下移，保证竖屏开局处于下半区
- 相机提前量增大，让玩家在竖屏里能更早看到上方平台
- 平台宽度、边距、移动范围按窄屏重新收紧，减少无解落点

## 后续扩展建议

- 增加敌人、陷阱或会坠落的平台
- 给状态栏增加对象池数量和节点数调试信息
- 增加存档最高分
- 补充音效、特效和正式美术资源
