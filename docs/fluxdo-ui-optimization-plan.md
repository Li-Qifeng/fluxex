# FluxEx 下一步 UI 优化计划（参考 Fluxdo）

## 调研结论

Fluxdo 的帖子体验不是单点美化，而是一套围绕“阅读连续性”的组件体系：紧凑话题卡、智能头像、相对时间、回复底部面板、楼层进度胶囊、骨架屏、HTML 折叠/图片处理、链接确认、快速跳转和桌面适配。

FluxEx 当前已经具备 V2EX 基础浏览、登录、回帖、书签、通知和多平台构建，但帖子详情页仍偏“API 数据直出”：层级、阅读进度、交互反馈和内容处理都较弱。

## P0：帖子详情页阅读体验

1. **帖子头部重排**
   - 文件：`lib/screens/topic_detail_screen.dart`
   - 做法：将标题、节点、作者、时间、回复数拆成独立 header card；顶部使用 `SliverAppBar` 保持标题收起态可读。
   - 验证：长帖滚动时顶部不遮挡内容，标题/节点/作者在首屏清晰。

2. **回复卡片 Fluxdo 化**
   - 文件：`lib/widgets/reply_item.dart`
   - 做法：头像左侧对齐，楼层号/时间右侧弱化；回复内容区减少边框感，使用 `surfaceContainerLow` 和 10–12px 圆角。
   - 验证：回复列表在移动端连续阅读更紧凑，暗色模式对比正常。

3. **楼层进度胶囊**
   - 新增：`lib/widgets/topic_progress.dart`
   - 做法：参考 Fluxdo `TopicProgress`，在详情页右下角显示 `当前楼层/总楼层`，带进度底色；点击弹出楼层跳转 sheet。
   - 验证：滚动回复时数字更新；输入楼层可跳转。

4. **骨架屏替代转圈**
   - 新增：`lib/widgets/topic_detail_skeleton.dart`
   - 做法：首屏加载展示标题骨架 + 3 条回复骨架，减少等待突兀感。
   - 验证：慢网加载时无空白闪烁。

## P1：内容处理与交互

1. **HTML 内容折叠**
   - 新增：`lib/widgets/collapsed_html_content.dart`
   - 做法：长内容默认显示摘要，支持“展开/收起”；保留 emoji/图片占位。
   - 验证：超长主帖不会挤压首屏，展开后图片仍可点击预览。

2. **链接与图片操作菜单**
   - 文件：`lib/screens/topic_detail_screen.dart`, `lib/widgets/image_gallery.dart`
   - 做法：外链点击前确认；图片支持长按复制 URL/浏览器打开。
   - 验证：误触外链减少；图片 URL 可复制。

3. **回复输入底部 Sheet**
   - 文件：`lib/screens/reply_screen.dart`
   - 做法：将单独页面改为底部 sheet，保留引用目标和发送状态。
   - 验证：回帖后返回原滚动位置。

4. **相对时间组件**
   - 新增：`lib/widgets/relative_time_text.dart`
   - 做法：统一显示“3分钟前 / 昨天 / 06-08”，替代分散的 `DateFormat`。
   - 验证：话题卡和回复卡时间格式一致。

## P2：桌面与高级体验

1. **响应式内容宽度**
   - 新增：`lib/widgets/constrained_content.dart`
   - 做法：桌面端正文最大宽度 720–840px，居中显示；移动端满宽。
   - 验证：Linux/Windows 宽屏下卡片不被拉伸。

2. **阅读位置记忆**
   - 扩展：`lib/utils/db_helper.dart`
   - 做法：为 browse_history 增加最后楼层/滚动进度；打开话题时提示回到上次阅读位置。
   - 验证：关闭再打开同一长帖可恢复阅读点。

3. **话题预览/分享图**
   - 新增：`lib/widgets/share_topic_preview.dart`
   - 做法：借鉴 Fluxdo share widgets，生成标题、节点、作者、二维码样式分享卡。
   - 验证：可保存或调用系统分享。

4. **通知快速面板**
   - 文件：`lib/screens/notifications_screen.dart`
   - 做法：账号页点击未读红点可直接弹出最近 5 条通知，而不是总进通知页。
   - 验证：未读处理链路更短。

## 推荐执行顺序

1. 先做 P0-1/2：帖子头部和回复卡片，收益最大且风险最低。
2. 再做 P0-3：楼层进度胶囊，需要滚动监听但不影响数据层。
3. 然后做 P1-3：回复底部 Sheet，提升交互闭环。
4. 最后做 P2 桌面宽度和阅读位置记忆。
