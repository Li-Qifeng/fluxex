# FluxEx vs Fluxdo 完整差距分析与优化路线图

## 核心结论

| 维度 | Fluxdo (Linux.do) | FluxEx (V2EX) | 差距 | 可实现性 |
|---|---|---|---|---|
| 代码规模 | 548 文件，服务层128文件 | 53 文件 | **10x差距** | — |
| 架构分层 | services/providers/pages/widgets/storage/settings | screens/providers/widgets/utils | 缺服务层、存储抽象 | 🔴 高 |
| 多站点 | 支持多 Discourse 站点切换 | 单 V2EX 站点 | V2EX 非 Discourse，无需 | 🟢 不适用 |
| 国际化 | slang 完整多语言（30+模块） | 仅中文 | 可补 | 🟡 中 |
| 楼层导航 | 精确拖拽+timeline+索引网格 | ✅ 刚补齐 | 已打平 | ✅ 已做 |
| 回复引用 | 一键引用+@补全+表情 | ✅ 刚补齐引用+@补全 | 接近打平，缺表情 | 🟡 中 |

---

## 一、V2EX API 硬性限制（无法实现的功能）

以下功能受 V2EX 平台限制，无论客户端如何做都无法实现：

| # | 功能 | 说明 |
|---|---|---|
| 1 | **嵌套/Threaded 回复** | V2EX 是扁平回复列表，无 parent_id |
| 2 | **回复/帖子点赞** | V2EX 无点赞 API，只有收藏 |
| 3 | **投票(Poll)** | V2EX 不支持帖子投票 |
| 4 | **站内私信** | V2EX 无私信 API |
| 5 | **在线状态(Presence)** | V2EX 无此功能 |
| 6 | **用户徽章/Trust Level** | V2EX 无等级系统 |
| 7 | **帖子模板** | V2EX 发帖无模板选择 |
| 8 | **帖子 Wiki 化** | V2EX 不支持持续编辑主帖 |
| 9 | **主题分类徽章(Flair)** | V2EX 无此功能 |
| 10 | **已读追踪(Read Tracking)** | V2EX 无此 API |

**策略**：这些不是 FluxEx 的缺陷，是平台差异。不应强求。

---

## 二、客户端可实现且值得优化的差距

### 2.1 架构层 — 高优先级

| # | 差距 | Fluxdo 做法 | FluxEx 现状 | 优化方案 |
|---|---|---|---|---|
| 1 | **服务层抽象** | `services/discourse/` 128文件，分 auth/login/topics/posts/... | 只有一个 `api_client.dart` | 拆分为 service 层，pub.dev pattern |
| 2 | **存储抽象** | `storage/` 接口，支持 secure/encrypted/shared | 直接调 `SharedPreferences` | 引入 `flutter_secure_storage` 封装 |
| 3 | **设置系统** | `settings/definitions/` 定义式配置，支持搜索 | 硬编码设置项 | 定义式 + 可搜索 |
| 4 | **Message Bus** | `providers/message_bus/` 事件总线 | 无，直接调 ref.invalidate | 引入轻量 EventBus |
| 5 | **日志系统** | `services/log/` 分级日志(Debug/Info/Error) | 无，用 print/debugPrint | 引入分级日志 |

### 2.2 编辑与输入 — 高优先级

| # | 差距 | 说明 |
|---|---|---|
| 1 | **表情选择器** | 回复/发帖时支持 emoji 面板 |
| 2 | **Markdown 实时预览** | 输入时右侧/下方实时预览 |
| 3 | **草稿自动保存** | 退出编辑器自动保存，恢复时提示 |
| 4 | **@用户补全** | ✅ 已做（ReplyBottomSheet） |
| 5 | **图片拖拽上传** | 支持拖拽图片到编辑器 |

### 2.3 列表与浏览 — 中优先级

| # | 差距 | 说明 |
|---|---|---|
| 1 | **已读标记** | 已读话题标题变灰（本地存储阅读时间） |
| 2 | **列表骨架屏** | 更精细的骨架屏（标题+作者+内容的模拟） |
| 3 | **分类/排序** | 热门/最新/节点→更多筛选条件 |
| 4 | **无限滚动** | ✅ 节点已做，首页/搜索可补 |
| 5 | **缓存策略** | 更完善的图片/列表缓存（过期策略） |

### 2.4 外观与动效 — 中优先级

| # | 差距 | 说明 |
|---|---|---|
| 1 | **过渡动画** | 页面切换 Hero/Fade/Slide |
| 2 | **高刷新率** | Android 高刷 `flutter_displaymode` |
| 3 | **字体系统** | `google_fonts` 支持自定义字体 |
| 4 | **主题微调** | 主题色强度、圆角大小等更细粒度控制 |
| 5 | **骨架屏动画** | Skeleton shimmer 更自然 |

### 2.5 通知与消息 — 低优先级

| # | 差距 | 说明 |
|---|---|---|
| 1 | **通知分类** | 回复/提及/系统 分类 Tab |
| 2 | **通知快速操作** | 滑动标记已读 |
| 3 | **未读细粒度** | 按类型显示红点 |

---

## 三、分阶段实现路线图

### Phase 1（1-2 周）：核心体验打平
1. **拆分 API → Service 层**
   - 将 `api_client.dart` 拆为：`api_client.dart` (Dio配置) + `topic_service.dart` + `reply_service.dart` + `node_service.dart` + `member_service.dart` + `auth_service.dart`
2. **添加表情选择器**
   - `lib/widgets/emoji_picker.dart`
   - 接入 ReplyBottomSheet + CreateTopicScreen
3. **草稿自动保存**
   - 编辑器退出时存 SQLite，重新进入恢复
4. **已读标记**
   - 列表项根据浏览历史记录变灰

### Phase 2（2-3 周）：工程化超越
5. **安全存储**
   - Cookie 从 SharedPreferences 迁到 `flutter_secure_storage`
6. **分级日志**
   - `lib/utils/logger.dart`，替代 debugPrint
7. **设置系统重构**
   - 定义式设置，支持搜索过滤
8. **Google Fonts + 高刷**
   - 引入 `google_fonts` 和 `flutter_displaymode`
9. **国际化（slang）**
   - 中英双语切换

### Phase 3（3-4 周）：差异化创新
10. **Markdown 实时预览** — 编辑区双栏实时渲染
11. **列表骨架屏升级** — 更精细的 shimmer
12. **过渡动画** — 页面切换动效
13. **数据导出** — 浏览历史/收藏/设置的 JSON 导出
14. **桌面宽屏优化** — 双栏布局（左侧列表+右侧详情）

---

## 四、FluxEx 可以保持/放大的优势

| 优势 | 说明 |
|---|---|
| **简洁** | V2EX 比 Discourse 简洁，客户端也应保持轻量 |
| **Material 3 纯净** | 不像 Fluxdo 高度定制，Material 3 原生感更好 |
| **启动速度** | 功能更少，启动可以更快 |
| **维护性** | 53 文件比 548 文件好维护，适度增长即可 |

---

## 五、推荐优先修复的 5 项

1. **表情选择器** — 输入体验核心
2. **草稿自动保存** — 发帖/回复防丢失
3. **Service 层拆分** — 架构升级，后续好扩展
4. **已读标记** — 浏览效率
5. **Google Fonts** — 视觉质感
