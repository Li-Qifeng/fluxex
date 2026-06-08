# FluxEx 下一阶段开发计划

## 当前状态

- 最新 Release：`v0.1.2`
- Release 产物：Android 三架构 APK、Linux、macOS、Windows、unsigned iOS IPA 共 7 个。
- 当前计划版本：`v0.1.3`
- 已完成能力：基础浏览、登录、回帖、书签、浏览历史、通知中心、未读红点、更新检查、全平台图标、Actions 多平台发布。

## 目标

把 FluxEx 从“功能可用”推进到“版本可信、细节顺手、帖子阅读体验接近 Fluxdo”。下一阶段建议发布为 `v0.1.3`。

## P0：版本与发布链路修正

1. **统一应用版本号**
   - 文件：`pubspec.yaml`
   - 改动：`version: 0.1.3+3`
   - 验证：`package_info_plus` 显示 `0.1.3`；Release tag 使用 `v0.1.3`。

2. **修正 User-Agent**
   - 文件：`lib/providers/api_client.dart`
   - 改动：从 `V2exClient/0.1.0` 改为 `FluxEx/0.1.3`。
   - 后续优化：可新增 `app_metadata_provider.dart` 动态读取版本，但当前先用常量，避免 API client 异步初始化复杂化。

3. **更新检查适配当前 tag**
   - 文件：`lib/providers/update_provider.dart`
   - 问题：当前 app 版本低于 latest tag 时会一直提示更新，这是正确行为；版本号修正后应显示“已是最新版本”。
   - 验证：发布 `v0.1.3` 后，账号页显示当前 `0.1.3`，latest `0.1.3`，无更新按钮。

4. **Release 流程约束**
   - 文件：`.github/workflows/build.yaml`
   - 当前：仅 tag `v*` 触发发布。
   - 计划：保持 tag-only，避免 master push 产生重复产物；每次功能发布都执行 `git tag vX.Y.Z && git push origin vX.Y.Z`。

## P1：帖子详情页核心体验

1. **帖子 Header Card**
   - 文件：`lib/screens/topic_detail_screen.dart`
   - 做法：主帖标题、节点、作者、时间、回复数独立成 header card；滚动后 AppBar 显示简短标题。
   - 验证：长标题不挤压回复列表；暗色模式对比正常。

2. **回复卡片细节优化**
   - 文件：`lib/widgets/reply_item.dart`
   - 做法：参考 Fluxdo：头像左侧、用户名/楼层/时间一行、内容间距收紧、卡片圆角 10–12、已读/弱信息用 `onSurfaceVariant`。
   - 验证：移动端连续阅读密度更高；回复楼层清晰。

3. **相对时间组件**
   - 新增：`lib/widgets/relative_time_text.dart`
   - 用途：替代 `reply_item.dart`、`topic_card.dart`、`topic_detail_screen.dart` 中分散的时间格式。
   - 验证：同一时间在不同页面格式一致。

4. **楼层进度胶囊**
   - 新增：`lib/widgets/topic_progress.dart`
   - 做法：右下角显示 `当前/总数`，随回复滚动更新；点击可跳转楼层。
   - 验证：100+ 回复长帖可快速定位。

## P2：交互细节

1. **回复底部 Sheet**
   - 文件：`lib/screens/topic_detail_screen.dart`, `lib/screens/reply_screen.dart`
   - 做法：将回帖从独立页面改为 bottom sheet，发送成功后留在原页面并刷新回复。
   - 验证：回帖后滚动位置不丢失。

2. **图片/外链操作**
   - 文件：`lib/widgets/image_gallery.dart`, `lib/screens/topic_detail_screen.dart`
   - 做法：图片长按复制链接/浏览器打开；外链点击前确认。
   - 验证：误触外链减少；图片 URL 可复制。

3. **骨架屏**
   - 新增：`lib/widgets/topic_detail_skeleton.dart`
   - 做法：替换详情页和通知页部分 `CircularProgressIndicator`。
   - 验证：慢网时首屏没有空白感。

4. **桌面内容宽度**
   - 新增：`lib/widgets/constrained_content.dart`
   - 做法：桌面最大宽度 760–840px，移动端满宽。
   - 验证：Linux/Windows 宽屏卡片不拉伸。

## P3：数据与离线体验

1. **浏览历史增加阅读位置**
   - 文件：`lib/utils/db_helper.dart`
   - 做法：新增 `last_floor` / `scroll_offset` 字段；打开长帖时提示“回到上次阅读”。
   - 验证：关闭重开话题可恢复阅读点。

2. **缓存策略明确化**
   - 文件：`lib/utils/db_helper.dart`, `lib/providers/topic_list_provider.dart`
   - 做法：热门/最新列表读取缓存兜底；失败时展示缓存和离线提示。
   - 验证：断网仍能看上次列表。

3. **通知已读/刷新联动**
   - 文件：`lib/providers/notification_provider.dart`, `lib/screens/notifications_screen.dart`
   - 做法：进入通知页后刷新未读数；点击通知后延迟刷新。
   - 验证：未读红点不会长期滞留。

## 验证标准

每轮提交前必须执行：

```bash
flutter pub get
flutter analyze
flutter test
flutter build linux --release
```

发布时执行：

```bash
git tag v0.1.3
git push origin v0.1.3
gh run watch <run-id> --repo=Li-Qifeng/fluxex --exit-status
gh release view v0.1.3 --repo=Li-Qifeng/fluxex --json url,assets
```

## 推荐执行顺序

1. `v0.1.3`：版本号/User-Agent/更新检查一致性 + 小型 UI 修补。
2. `v0.1.4`：帖子 Header Card + 回复卡片 + 相对时间。
3. `v0.1.5`：楼层进度胶囊 + 回复 bottom sheet。
4. `v0.1.6`：桌面宽度、骨架屏、阅读位置记忆。
