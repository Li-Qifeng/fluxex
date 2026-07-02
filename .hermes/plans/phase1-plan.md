# Phase 1 — FluxEx 核心体验补齐计划

## 总览

4 个子任务，预估总工时：~12-15h
版本号：v0.2.7 (发版时统一 bump)

---

## 任务一：TopicDetail 增强

### 现状

- 楼层跳转：已有 `_showFloorPicker`（对话框模式）+ `_showFloorInputDialog`（输入模式）+ 水平拖拽胶囊
- 更多菜单：TopicCard（列表页）中有 `_showTopicMenu`，但 TopicDetail 页面没有完整的更多菜单
- 阅读进度条：无

### 改动文件

| 文件 | 改动类型 |
|:---|:---:|
| `lib/screens/topic_detail_screen.dart` | 增强 |
| `lib/widgets/reply_item.dart` | 增强（可选，增加引用回复按钮） |
| `lib/utils/db_helper.dart` | 无改动（已有进度存贮） |

### 1a. 楼层胶囊拖拽增强

**当前代码位置**：`topic_detail_screen.dart` 第 941-1000 行
- `_dragTargetFloor` / `_dragStartFloor` / `_dragAccumulatedDx` 状态变量
- `_showFloorPicker()` 对话框
- `_showFloorInputDialog()` 输入对话框
- `_commitDragJump()` 提交跳转

**增强点**：
1. 胶囊长按震动反馈后，显示 `_currentFloor / _totalReplies` 悬浮标签（类似 FluxDO 的 `TopicProgress`）
2. 胶囊上滑展开进度条（`Slider` 或自定义进度条）
3. 进度条旁显示 "N/N" 楼层计数

**实现方案**：
```dart
// 在 floatActionButton 的楼层胶囊区域增加进度条展开状态
// 使用 AnimatedContainer + GestureDetector 实现

enum _FloorMode { pill, expanded }

_FloorMode _floorMode = _FloorMode.pill;

// 展开时：在胶囊上方显示 Slider
// 收起时：仅显示胶囊
```

### 1b. 更多菜单扩展

**当前**：TopicDetail 页无完整更多菜单
**需要**：悬浮按钮上方增加更多菜单入口（⋯ 按钮），菜单项包括：

| 菜单项 | 功能 | 实现 | 已有代码 |
|:---|:---|:---|:---:|
| 复制链接 | 复制 `v2ex.com/t/{id}` | `Clipboard.setData` | ✅ 在 TopicCard 中已有 |
| 分享链接 | `Share.share` | 调用 share_plus | ✅ 已有 |
| 分享图片 | 生成截图分享 | `_shareImage` | ✅ 已有 |
| 收藏/取消收藏 | `DbHelper.addBookmark/removeBookmark` | 调用 DB | ✅ 已有 |
| 稍后阅读 | 独立标记，浏览历史中置顶 | `DbHelper` + 新字段 `isReadLater` | 需新增 |
| 在浏览器中打开 | `launchUrl` | url_launcher | ✅ 已有 |
| 导出 (JSON/MD) | 文本导出 | `export_utils.dart` 中 `exportAsFile` | ✅ 已有 |

**UI 方案**：在 `GlassButton`（回复按钮）下方增加 `GlassIconButton(Icons.more_horiz)`，或与 FluxDO 一样放在 FAB 的弹出菜单中。

### 1c. 阅读进度条

**实现方案**：
- 在 `CustomScrollView` 的 slivers 顶部增加一个 `SliverPersistentHeader` 或 Overlay
- 监听 `_scrollController` 的偏移量
- 计算 `回复区域已滚动高度 / 总回复高度`
- 显示进度百分比条

```dart
// 在 appBar 下方或 overlay 中
Widget _buildProgressBar() {
  if (_totalReplies <= 0) return const SizedBox.shrink();
  final progress = _currentFloor / _totalReplies;
  return LinearProgressIndicator(value: progress, ...);
}
```

---

## 任务二：用户页增强

### 现状

- `MemberDetailScreen`：展示用户信息（头像、tagline、创建时间、地理位置）
- `memberTopicsProvider` 已存在（调用 `TopicService.getByUser`）
- `MemberService` 只有 `getInfo` 方法
- V2EX API `/api/topics/show.json?username=xxx` 返回用户主题（已有 `getByUser`）

### 改动文件

| 文件 | 改动类型 | 
|:---|:---:|
| `lib/screens/member_detail_screen.dart` | 增强 |
| `lib/services/member_service.dart` | 新增 `getReplies`/`follow`/`unfollow` |
| `lib/providers/member_provider.dart` | 新增 provider |

### 2a. 用户主题/回复列表

**当前**：已有 `memberTopicsProvider`（调用 `TopicService.getByUser`），但 `MemberDetailScreen` 只用 `CustomScrollView` 展示用户基本信息，没有主题列表。

**V2EX API**：`/api/topics/show.json?username=xxx` → 返回用户所有主题列表

**方案**：
在用户信息下方添加 TabBar/TabBarView：
- Tab 1: 用户主题（已有 `memberTopicsProvider`）
- Tab 2: 用户回复（需新增 `memberRepliesProvider`）

V2EX 没有回复列表的 JSON API，回复需要爬取或使用 `api/v2/members/{username}/replies`（如果启用了 V2EX API v2）。

**替代方案**：暂不实现用户回复列表（V2EX API 限制），仅展示用户主题列表。

```dart
// MemberDetailScreen 中
DefaultTabController(
  length: 2,
  child: NestedScrollView(
    headerSliverBuilder: (ctx, inner) => [
      // 现有用户信息 SliverAppBar
    ],
    body: TabBarView(
      children: [
        // 用户主题列表
        _buildTopicList(topicsAsync),
        // 用户回复列表（或占位）
        const EmptyState(message: 'V2EX 暂未提供此数据'),
      ],
    ),
  ),
)
```

### 2b. 关注/取关用户

**V2EX API**：没有公开的关注用户 API（Web 端通过 `/favorite/followers` 页面操作）。

**方案**：
- 本地模拟关注功能：在 `DbHelper` 中新增 `member_follows` 表
- 在用户页头部增加关注按钮（仅在非当前用户时显示）
- 关注列表页（后续在 Profile 中展示）

```dart
// DbHelper 新增
CREATE TABLE member_follows (
  username TEXT PRIMARY KEY,
  followed_at INTEGER NOT NULL
)
// static 方法：followMember / unfollowMember / isMemberFollowed / getFollowedMembers
```

### 2c. 用户信息完善

**当前**：显示头像、用户名、tagline、创建时间、地理位置

**新增**：
- 用户主题数（可以从 `memberTopicsProvider` 获取）
- 用户节点收藏数（本地 `node_follows` 中获取）
- 用户活跃度统计（V2EX API 限制，可选）

---

## 任务三：草稿自动保存

### 现状

- `create_topic_screen.dart`：**已有**完整的草稿功能（`_restoreDraft`, `_saveDraftNow`, `_draftTimer`）
- `reply_bottom_sheet.dart`：**没有**草稿功能
- `DbHelper`：**已有** `saveDraft`/`getDraft`/`deleteDraft` 方法 + `drafts` 表
- DB schema 中 `draft_id` 字段设计支持多种草稿类型

### 改动文件

| 文件 | 改动类型 |
|:---|:---:|
| `lib/widgets/reply_bottom_sheet.dart` | 新增草稿功能 |
| `lib/screens/create_topic_screen.dart` | 无需改动（已实现） |

### 3a. 回复草稿自动保存

**方案**：在 `ReplyBottomSheet` 中添加：

```dart
// 1. initState 中加载草稿: _restoreReplyDraft()
// 2. 用户输入变化时自动保存 (Timer debounce)
// 3. dispose 时立即保存最后状态
// 4. 回复成功后删除草稿

final _contentController = TextEditingController();
Timer? _draftTimer;
static const _draftKey = 'reply_topic_{topicId}';

@override
void initState() {
  super.initState();
  _restoreDraft();
  _contentController.addListener(_onContentChanged);
}

void _onContentChanged() {
  _draftTimer?.cancel();
  _draftTimer = Timer(const Duration(seconds: 2), _saveDraft);
}

void _saveDraft() {
  final text = _contentController.text.trim();
  if (text.isEmpty) return;
  DbHelper.saveDraft(draftId: _draftKey, type: 'reply', content: text);
}

void _restoreDraft() async {
  final draft = await DbHelper.getDraft(_draftKey);
  if (draft != null && mounted) {
    _contentController.text = draft['content'] as String? ?? '';
  }
}
```

---

## 任务四：搜索增强

### 现状

- 搜索使用 `sov2ex.com` 搜索引擎（`searchProvider` → `searchSov2ex`）
- 搜索结果返回：id, title, content, member, node, replies, created
- `sov2ex` API 支持 `q`（查询词）+ `from` + `size` 参数
- `SearchScreen` 只有输入搜索框 → 显示结果列表

### 改动文件

| 文件 | 改动类型 |
|:---|:---:|
| `lib/screens/search_screen.dart` | 增强 |
| `lib/providers/search_provider.dart` | 新增过滤参数 |
| `lib/models/node.dart` | 无改动 |

### 4a. 按节点过滤搜索

**现状**：`sov2ex` API `/api/search` 没有节点过滤参数
**方案**：

1. **前端过滤**：搜索结果包含 `node` 字段（int 类型，节点 id），在前端做过滤
2. **添加节点选择器**：在搜索框下方增加节点选择 Chip/Chunk

```dart
// search_screen.dart
String? _selectedNodeName; // 当前过滤的节点
// 在搜索框下方显示节点选择条
Node? _selectedNode;

Widget _buildNodeFilter() {
  return FutureBuilder(
    future: getAllNodes(), // 已有的 nodes provider
    builder: (ctx, snapshot) {
      final nodes = snapshot.data ?? [];
      return Wrap(
        spacing: 6,
        children: [
          FilterChip(
            label: Text('全部'),
            selected: _selectedNode == null,
            onSelected: (_) => setState(() => _selectedNode = null),
          ),
          for (final node in nodes.where((n) => n.topics > 0).take(5))
            FilterChip(
              label: Text(node.title),
              selected: _selectedNode == node,
              onSelected: (sel) => setState(() => _selectedNode = sel ? node : null),
            ),
        ],
      );
    },
  );
}
```

**注意**：sov2ex 的搜索 API 不支持服务端过滤，节点过滤只能在前端对已有搜索结果做二次过滤。这对大量结果不理想，但 Sov2ex 搜索结果通常只有 20 条/页，前端过滤可行。

### 4b. 按作者过滤

**方案**：
- 在结果列表的每个 item 中显示作者名（已有 `member` 字段）
- 点击作者名跳转到用户详情页（`/member/{username}`）
- 增加"搜索该作者主题"快捷操作

```dart
// 搜索结果 item 中
InkWell(
  onTap: () => context.push('/member/${r.member}'),
  child: Text(r.member, style: TextStyle(color: cs.primary, fontSize: 12)),
)
```

### 4c. 搜索历史 UI 增强

**当前**：已有搜索历史（`searchHistoryProvider`），以列表形式展示

**增强**：
- 搜索历史增加删除按钮（单项删除 + 清空全部）
- 热门搜索推荐（V2EX 无此 API，可跳过）
- 搜索建议（基于 sov2ex 的 suggest API，可选）

---

## 实施顺序

```
Task 1 (TopicDetail 增强) ─────────────────┐
                                            ├─→ v0.2.7 统一发版
Task 2 (用户页增强) ────────────────────────┤
                                            │
Task 3 (草稿自动保存) ──────────────────────┤
                                            │
Task 4 (搜索增强) ──────────────────────────┘
```

每个任务独立可提交，但按用户偏好统一在 **Phase 1 所有任务完成后** bump 版本并发布。

---

## 验证清单

每个子任务完成后验证：

- [ ] Task 1a：楼层胶囊拖拽流畅，进度条实时更新
- [ ] Task 1b：更多菜单所有功能（复制/分享/收藏/稍后读/浏览器打开/导出）正常
- [ ] Task 1c：阅读进度条随滚动实时更新
- [ ] Task 2a：用户页显示主题列表，Tab 切换正常
- [ ] Task 2b：关注/取关用户功能正常，数据持久化
- [ ] Task 3a：回复输入自动保存草稿，离开后恢复，回复成功后清除
- [ ] Task 4a：节点过滤选择器正常，搜索结果按节点过滤
- [ ] Task 4b：搜索结果中作者名可点击跳转
- [ ] Task 4c：搜索历史管理正常
