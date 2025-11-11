import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui_nice/theme.dart';
import 'ui_nice/widgets.dart';
import 'dart:convert';
import 'dart:async';

// 统一前端使用的后端地址（如需改端口，改这里即可）
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:8001',
);

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '语伴同行',
      theme: buildNiceTheme(seedColor: Colors.teal),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;
  String? _token;
  String? _userName;
  String? _userEmail;
  String? _userBio;
  String? _avatarUrl;
  String? _accountId;
  int _totalUnreadCount = 0;
  Timer? _unreadPollTimer;
  static const Duration _unreadPollInterval = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadToken();
  }

  Future<void> _loadToken() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _token = sp.getString('token');
      _userName = sp.getString('user_name');
      _userEmail = sp.getString('user_email');
      _userBio = sp.getString('user_bio');
      _avatarUrl = sp.getString('user_avatar_url');
      _accountId = sp.getString('user_account_id');
    });
    if (_token != null && (_userName == null || _userEmail == null)) {
      await _fetchCurrentUser();
    }
    if (_token != null) {
      await _fetchUnreadCounts();
      _startUnreadPolling();
    }
  }

  Future<void> _fetchCurrentUser() async {
    final uri = Uri.parse('$apiBase/api/user');
    try {
      final res = await http.get(uri, headers: {
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final name = data['name'] as String?;
        final email = data['email'] as String?;
        final bio = data['bio'] as String?;
        final avatarUrl = data['avatar_url'] as String?;
        final accountId = data['account_id'] as String?;
        final sp = await SharedPreferences.getInstance();
        if (name != null) await sp.setString('user_name', name);
        if (email != null) await sp.setString('user_email', email);
        if (bio != null) await sp.setString('user_bio', bio);
        if (avatarUrl != null) await sp.setString('user_avatar_url', avatarUrl);
        if (accountId != null && accountId.isNotEmpty) await sp.setString('user_account_id', accountId);
        setState(() {
          _userName = name;
          _userEmail = email;
          _userBio = bio;
          _avatarUrl = avatarUrl;
          _accountId = accountId ?? _accountId;
        });
      }
    } catch (_) {
      // ignore network errors
    }
  }

  Future<void> _fetchUnreadCounts() async {
    if (_token == null) {
      setState(() => _totalUnreadCount = 0);
      return;
    }
    final uri = Uri.parse('$apiBase/api/messages/unread_counts');
    try {
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $_token'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final count = (data['total'] ?? 0) as int;
        setState(() => _totalUnreadCount = count);
      }
    } catch (_) {}
  }

  void _startUnreadPolling() {
    _unreadPollTimer?.cancel();
    if (_token == null) return;
    _unreadPollTimer = Timer.periodic(_unreadPollInterval, (_) {
      _fetchUnreadCounts();
    });
  }

  void _stopUnreadPolling() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _token != null) {
      _fetchUnreadCounts();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopUnreadPolling();
    super.dispose();
  }

  final _titles = const [
    '语伴同行',
    '树洞',
    '练习',
    '消息',
    '我的',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ListTile(title: Text('快捷入口')),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.drafts_outlined),
                title: const Text('我的草稿'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyDraftsPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.comment_bank_outlined),
                title: const Text('我的评论'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MyCommentsPage(token: _token)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('浏览记录'),
                onTap: () {
                  Navigator.pop(context);
                  if (_token == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BrowsingHistoryPage(token: _token!)));
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('设置'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(
                    token: _token,
                    onLoggedOut: () async {
                      setState(() {
                        _token = null;
                        _userName = null;
                        _userEmail = null;
                        _userBio = null;
                        _avatarUrl = null;
                        _accountId = null;
                        _totalUnreadCount = 0;
                      });
                      _stopUnreadPolling();
                    },
                  )));
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('帮助与客服'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_titles[_index]),
        centerTitle: true,
        actions: [
          if (_token == null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('登录'),
                onPressed: () async {
                  final result = await Navigator.push<Map<String, String?>?>(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  if (result != null) {
                    final sp = await SharedPreferences.getInstance();
                    final t = result['token'];
                    final name = result['userName'];
                    final email = result['userEmail'];
                    if (t != null) await sp.setString('token', t);
                    if (name != null) await sp.setString('user_name', name);
                    if (email != null) await sp.setString('user_email', email);
                    setState(() {
                      _token = t;
                      _userName = name;
                      _userEmail = email;
                    });
                    // 再次从后端读取，校准用户信息
                    await _fetchCurrentUser();
                    await _fetchUnreadCounts();
                    _startUnreadPolling();
                  }
                },
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _index, children: [
        CommunityPage(token: _token, onLoginChanged: (t) async {
          setState(() => _token = t);
          await _fetchCurrentUser();
          await _fetchUnreadCounts();
          if (_token != null) {
            _startUnreadPolling();
          } else {
            _stopUnreadPolling();
          }
        }),
        TreeHolePage(token: _token),
        const PracticePage(),
        MessagesPage(token: _token, onUnreadChanged: () async {
          await _fetchUnreadCounts();
        }),
        MePage(userName: _userName, userEmail: _userEmail, userBio: _userBio, avatarUrl: _avatarUrl, accountId: _accountId, token: _token, onEdit: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(
            initialName: _userName,
            initialBio: _userBio,
            initialAccountId: _accountId,
            token: _token,
          )));
          await _fetchCurrentUser();
        }, onChangePassword: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(token: _token)));
        }),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: '语伴同行'),
          const NavigationDestination(icon: Icon(Icons.eco_outlined), selectedIcon: Icon(Icons.eco), label: '树洞'),
          const NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: '练习'),
          NavigationDestination(
            icon: _buildBadgeIcon(icon: Icons.notifications_none, count: _totalUnreadCount),
            selectedIcon: _buildBadgeIcon(icon: Icons.notifications, count: _totalUnreadCount),
            label: '消息',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 3) {
            // 进入消息页后延迟刷新未读数（各标签页会在页内标记为已读）
            Future.delayed(const Duration(milliseconds: 800), _fetchUnreadCounts);
          }
        },
      ),
    );
  }

  Widget _buildBadgeIcon({required IconData icon, required int count}) {
    return NiceBadge(
      count: count,
      child: Icon(icon),
    );
  }
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, this.token, this.onUnreadChanged});
  final String? token;
  final VoidCallback? onUnreadChanged;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.token == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('请先登录以查看消息', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('消息'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '赞与收藏'),
              Tab(text: '关注'),
              Tab(text: '评论与@'),
              Tab(text: '系统通知'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReactionsTab(token: widget.token!, onUnreadChanged: widget.onUnreadChanged),
            _FollowsTab(token: widget.token!, onUnreadChanged: widget.onUnreadChanged),
            _CommentsMentionsTab(token: widget.token!, onUnreadChanged: widget.onUnreadChanged),
            _SystemTab(token: widget.token!, onUnreadChanged: widget.onUnreadChanged),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)));
  }
}

class _ReactionsTab extends StatefulWidget {
  const _ReactionsTab({required this.token, this.onUnreadChanged});
  final String token;
  final VoidCallback? onUnreadChanged;
  @override
  State<_ReactionsTab> createState() => _ReactionsTabState();
}

class _ReactionsTabState extends State<_ReactionsTab> {
  final ScrollController _scrollCtrl = ScrollController();
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollCtrl.addListener(() {
      if (_hasMore && !_loadingMore && _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120) {
        _loadMore();
      }
    });
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    _hasMore = true;
    _items = [];
    await _fetchAndAppend(reset: true);
    await _markAllRead();
    widget.onUnreadChanged?.call();
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    _page += 1;
    await _fetchAndAppend();
    _loadingMore = false;
  }

  Future<void> _markAllRead() async {
    final uri = Uri.parse('$apiBase/api/messages/reactions/mark_all_read');
    try {
      await http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
    } catch (_) {}
  }

  Future<void> _fetchAndAppend({bool reset = false}) async {
    final uri = Uri.parse('$apiBase/api/messages/reactions?page=$_page&per_page=10');
    try {
      final res = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List data = body['data'] ?? [];
        final bool hasMore = body['has_more'] ?? false;
        setState(() {
          _hasMore = hasMore;
          if (reset) {
            _items = data.cast<Map<String, dynamic>>();
          } else {
            _items.addAll(data.cast<Map<String, dynamic>>());
          }
        });
      }
    } catch (_) {}
  }

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (_items.isEmpty) {
            return const _EmptyHint(text: '暂无赞与收藏');
          }
          if (index == _items.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _hasMore ? const CircularProgressIndicator() : Text('没有更多了', style: Theme.of(context).textTheme.bodySmall),
              ),
            );
          }
          final item = _items[index];
          final type = item['type'] as String?;
          final actorName = item['actor']?['name'] ?? '用户';
          final postTitle = item['post']?['title'] ?? '帖子';
          final icon = type == 'favorite' ? Icons.bookmark_add_outlined : Icons.favorite_border;
          final label = type == 'favorite' ? '收藏了你的帖子' : '赞了你的帖子';
          final initials = actorName is String && actorName.isNotEmpty ? actorName.characters.first : '用';
          return NiceCard(
            child: NiceListItem(
              leading: NiceAvatar(initials: initials),
              title: '$actorName $label：$postTitle',
              subtitleText: _formatTime(item['created_at']),
              trailing: Icon(icon, color: cs.primary),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: (_items.isEmpty ? 1 : _items.length + 1),
      ),
    );
  }
}

class _FollowsTab extends StatefulWidget {
  const _FollowsTab({required this.token, this.onUnreadChanged});
  final String token;
  final VoidCallback? onUnreadChanged;
  @override
  State<_FollowsTab> createState() => _FollowsTabState();
}

class _FollowsTabState extends State<_FollowsTab> {
  final ScrollController _scrollCtrl = ScrollController();
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollCtrl.addListener(() {
      if (_hasMore && !_loadingMore && _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120) {
        _loadMore();
      }
    });
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    _hasMore = true;
    _items = [];
    await _fetchAndAppend(reset: true);
    await _markAllRead();
    widget.onUnreadChanged?.call();
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    _page += 1;
    await _fetchAndAppend();
    _loadingMore = false;
  }

  Future<void> _markAllRead() async {
    final uri = Uri.parse('$apiBase/api/messages/follows/mark_all_read');
    try {
      await http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
    } catch (_) {}
  }

  Future<void> _fetchAndAppend({bool reset = false}) async {
    final uri = Uri.parse('$apiBase/api/messages/follows?page=$_page&per_page=10');
    try {
      final res = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List data = body['data'] ?? [];
        final bool hasMore = body['has_more'] ?? false;
        setState(() {
          _hasMore = hasMore;
          if (reset) {
            _items = data.cast<Map<String, dynamic>>();
          } else {
            _items.addAll(data.cast<Map<String, dynamic>>());
          }
        });
      }
    } catch (_) {}
  }

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (_items.isEmpty) {
            return const _EmptyHint(text: '暂无新的关注');
          }
          if (index == _items.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _hasMore ? const CircularProgressIndicator() : Text('没有更多了', style: Theme.of(context).textTheme.bodySmall),
              ),
            );
          }
          final item = _items[index];
          final actorName = item['actor']?['name'] ?? '用户';
          final initials = actorName is String && actorName.isNotEmpty ? actorName.characters.first : '用';
          return NiceCard(
            child: NiceListItem(
              leading: NiceAvatar(initials: initials),
              title: '$actorName 关注了你',
              subtitleText: _formatTime(item['created_at']),
              trailing: const Icon(Icons.group_add_outlined),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: (_items.isEmpty ? 1 : _items.length + 1),
      ),
    );
  }
}

class _CommentsMentionsTab extends StatefulWidget {
  const _CommentsMentionsTab({required this.token, this.onUnreadChanged});
  final String token;
  final VoidCallback? onUnreadChanged;
  @override
  State<_CommentsMentionsTab> createState() => _CommentsMentionsTabState();
}

class _CommentsMentionsTabState extends State<_CommentsMentionsTab> {
  final ScrollController _scrollCtrl = ScrollController();
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollCtrl.addListener(() {
      if (_hasMore && !_loadingMore && _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120) {
        _loadMore();
      }
    });
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    _hasMore = true;
    _items = [];
    await _fetchAndAppend(reset: true);
    await _markAllRead();
    widget.onUnreadChanged?.call();
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    _page += 1;
    await _fetchAndAppend();
    _loadingMore = false;
  }

  Future<void> _markAllRead() async {
    final uri = Uri.parse('$apiBase/api/messages/comments/mark_all_read');
    try {
      await http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
    } catch (_) {}
  }

  Future<void> _fetchAndAppend({bool reset = false}) async {
    final uri = Uri.parse('$apiBase/api/messages/comments?page=$_page&per_page=10');
    try {
      final res = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List data = body['data'] ?? [];
        final bool hasMore = body['has_more'] ?? false;
        setState(() {
          _hasMore = hasMore;
          if (reset) {
            _items = data.cast<Map<String, dynamic>>();
          } else {
            _items.addAll(data.cast<Map<String, dynamic>>());
          }
        });
      }
    } catch (_) {}
  }

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (_items.isEmpty) {
            return const _EmptyHint(text: '暂无评论或@提及');
          }
          if (index == _items.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _hasMore ? const CircularProgressIndicator() : Text('没有更多了', style: Theme.of(context).textTheme.bodySmall),
              ),
            );
          }
          final item = _items[index];
          final type = item['type'] as String?; // comment | mention
          final actorName = item['actor']?['name'] ?? '用户';
          final postTitle = item['post']?['title'] ?? '帖子';
          final content = item['content'] ?? '';
          final icon = type == 'mention' ? Icons.alternate_email : Icons.mode_comment_outlined;
          final label = type == 'mention' ? '@了你' : '评论了你的帖子';
          final initials = actorName is String && actorName.isNotEmpty ? actorName.characters.first : '用';
          return NiceCard(
            child: NiceListItem(
              leading: NiceAvatar(initials: initials),
              title: '$actorName $label：$postTitle',
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(content),
                const SizedBox(height: 4),
                Text(_formatTime(item['created_at']), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ]),
              trailing: Icon(icon, color: cs.primary),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: (_items.isEmpty ? 1 : _items.length + 1),
      ),
    );
  }
}

class _SystemTab extends StatefulWidget {
  const _SystemTab({required this.token, this.onUnreadChanged});
  final String token;
  final VoidCallback? onUnreadChanged;
  @override
  State<_SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<_SystemTab> {
  final ScrollController _scrollCtrl = ScrollController();
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollCtrl.addListener(() {
      if (_hasMore && !_loadingMore && _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120) {
        _loadMore();
      }
    });
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    _hasMore = true;
    _items = [];
    await _fetchAndAppend(reset: true);
    await _markAllRead();
    widget.onUnreadChanged?.call();
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    _page += 1;
    await _fetchAndAppend();
    _loadingMore = false;
  }

  Future<void> _markAllRead() async {
    final uri = Uri.parse('$apiBase/api/messages/system/mark_all_read');
    try {
      await http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
    } catch (_) {}
  }

  Future<void> _fetchAndAppend({bool reset = false}) async {
    final uri = Uri.parse('$apiBase/api/messages/system?page=$_page&per_page=10');
    try {
      final res = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List data = body['data'] ?? [];
        final bool hasMore = body['has_more'] ?? false;
        setState(() {
          _hasMore = hasMore;
          if (reset) {
            _items = data.cast<Map<String, dynamic>>();
          } else {
            _items.addAll(data.cast<Map<String, dynamic>>());
          }
        });
      }
    } catch (_) {}
  }

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (_items.isEmpty) {
            return const _EmptyHint(text: '暂无系统通知');
          }
          if (index == _items.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _hasMore ? const CircularProgressIndicator() : Text('没有更多了', style: Theme.of(context).textTheme.bodySmall),
              ),
            );
          }
          final item = _items[index];
          final title = item['title'] ?? '系统通知';
          final content = item['content'] ?? '';
          return NiceCard(
            child: NiceListItem(
              leading: const Icon(Icons.notifications_active_outlined),
              title: title,
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(content),
                const SizedBox(height: 4),
                Text(_formatTime(item['created_at']), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: (_items.isEmpty ? 1 : _items.length + 1),
      ),
    );
  }
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, this.token, this.onLoginChanged});
  final String? token;
  final ValueChanged<String?>? onLoginChanged;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class TreeHolePage extends StatefulWidget {
  const TreeHolePage({super.key, this.token});
  final String? token;

  @override
  State<TreeHolePage> createState() => _TreeHolePageState();
}

class _TreeHolePageState extends State<TreeHolePage> {
  final ScrollController _scrollCtrl = ScrollController();
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollCtrl.addListener(() {
      if (_hasMore && !_loadingMore && _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120) {
        _loadMore();
      }
    });
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    _hasMore = true;
    _items = [];
    await _fetchAndAppend(reset: true);
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    _page += 1;
    await _fetchAndAppend();
    _loadingMore = false;
  }

  Future<void> _fetchAndAppend({bool reset = false}) async {
    final uri = Uri.parse('$apiBase/api/moods?page=$_page&per_page=10');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List data = body['data'] ?? [];
        final bool hasMore = body['has_more'] ?? false;
        setState(() {
          _hasMore = hasMore;
          if (reset) {
            _items = data.cast<Map<String, dynamic>>();
          } else {
            _items.addAll(data.cast<Map<String, dynamic>>());
          }
        });
        return;
      }
    } catch (_) {}
    // fallback
    if (reset) {
      setState(() => _items = _fallback());
    }
  }

  List<Map<String, dynamic>> _fallback() {
    return [
      {
        'id': 1,
        'content': '今天练习时有点紧张，但说完一句后好很多。',
        'comments': 3,
      },
      {
        'id': 2,
        'content': '把“早上好”说顺了，开心！',
        'comments': 1,
      },
      {
        'id': 3,
        'content': '感谢大家的鼓励，慢慢来，别急。',
        'comments': 5,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      // 仅保留顶层 AppBar 的“树洞”标题，这里不再重复设置
      floatingActionButton: widget.token == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ComposeMoodPage(token: widget.token!)));
                if (ok == true) {
                  await _loadFirstPage();
                }
              },
              child: const Icon(Icons.edit),
            ),
      body: RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView.separated(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            if (index == _items.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _hasMore ? const CircularProgressIndicator() : Text('没有更多了', style: Theme.of(context).textTheme.bodySmall),
                ),
              );
            }
            final item = _items[index];
                return InkWell(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => MoodDetailPage(token: widget.token, mood: item)));
                  },
                  child: NiceCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final dynamic rawId = item['author']?['id'];
                            final int? authorId = rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);
                            if (authorId != null && widget.token != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PersonalSpacePage(
                                  token: widget.token!,
                                  userId: authorId,
                                  userName: item['author']?['name'] as String?,
                                  avatarUrl: item['author']?['avatar_url'] as String?,
                                ),
                              ));
                            }
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: cs.secondaryContainer,
                            backgroundImage: (item['author']?['avatar_url'] != null) ? NetworkImage(item['author']['avatar_url']) : null,
                            child: (item['author']?['avatar_url'] == null) ? Icon(Icons.eco, color: cs.onSecondaryContainer) : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(item['author']?['name'] ?? '匿名', style: Theme.of(context).textTheme.bodySmall)),
                                  Text(
                                    _formatTime(item['created_at']),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(item['content'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.mode_comment_outlined, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('${item['comments'] ?? 0}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.remove_red_eye_outlined, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('${item['views'] ?? 0}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: widget.token == null ? null : () => _toggleLike(item),
                                    icon: Icon((item['liked_by_me'] ?? false) ? Icons.favorite : Icons.favorite_border, color: (item['liked_by_me'] ?? false) ? cs.primary : cs.onSurfaceVariant),
                                  ),
                                  Text('${item['likes'] ?? 0}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                  const Spacer(),
                                  if ((item['owned_by_me'] ?? false))
                                    NiceActionButton(
                                      onPressed: () => _deleteMood(item),
                                      icon: Icons.delete_outline,
                                      label: '删除',
                                      variant: NiceButtonVariant.tonal,
                                    ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: _items.length + 1,
        ),
      ),
    );
  }

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> item) async {
    final id = item['id'];
    final liked = item['liked_by_me'] ?? false;
    try {
      final uri = Uri.parse('$apiBase/api/moods/$id/like');
      final res = await (liked
          ? http.delete(uri, headers: {'Authorization': 'Bearer ${widget.token}'})
          : http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'}));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          item['liked_by_me'] = body['liked_by_me'] ?? !liked;
          item['likes'] = body['likes'] ?? (item['likes'] ?? 0) + (liked ? -1 : 1);
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteMood(Map<String, dynamic> item) async {
    final id = item['id'];
    try {
      final uri = Uri.parse('$apiBase/api/moods/$id');
      final res = await http.delete(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        setState(() {
          _items.removeWhere((e) => e['id'] == id);
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
      }
    } catch (_) {}
  }
}

class ComposeMoodPage extends StatefulWidget {
  const ComposeMoodPage({super.key, required this.token});
  final String token;

  @override
  State<ComposeMoodPage> createState() => _ComposeMoodPageState();
}

class _ComposeMoodPageState extends State<ComposeMoodPage> {
  final _contentCtrl = TextEditingController();
  bool _loading = false;
  bool _anonymous = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('发布心情')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NiceCard(
              child: TextField(
                controller: _contentCtrl,
                maxLines: 6,
                decoration: const InputDecoration(labelText: '这一刻的心情...', hintText: '记录你的想法、期待或烦恼'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(value: _anonymous, onChanged: (v) => setState(() => _anonymous = v)),
                const SizedBox(width: 8),
                const Text('匿名发布'),
              ],
            ),
            const SizedBox(height: 16),
            NiceActionButton(
              onPressed: _loading ? null : _submit,
              icon: Icons.send,
              label: '发布',
              variant: NiceButtonVariant.primary,
            ),
            const SizedBox(height: 8),
            Text('发布后会显示在“树洞”列表，大家可以评论', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$apiBase/api/moods');
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
          body: json.encode({'content': _contentCtrl.text.trim(), 'is_anonymous': _anonymous}));
      if (res.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        // 后端未就绪则兜底
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败：${res.statusCode}')));
      }
    } catch (_) {
      // 网络或接口未就绪，先返回成功以便演示
      Navigator.pop(context, true);
    } finally {
      setState(() => _loading = false);
    }
  }
}

class MoodDetailPage extends StatefulWidget {
  const MoodDetailPage({super.key, this.token, required this.mood});
  final String? token;
  final Map<String, dynamic> mood;

  @override
  State<MoodDetailPage> createState() => _MoodDetailPageState();
}

class _MoodDetailPageState extends State<MoodDetailPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final _commentCtrl = TextEditingController();
  bool _posting = false;
  int? _replyParentId;

  @override
  void initState() {
    super.initState();
    _future = _fetchComments();
    // 浏览打点（心情）
    () async {
      if (widget.token == null) return;
      final id = widget.mood['id'] ?? 0;
      try {
        final uri = Uri.parse('$apiBase/api/moods/$id/view');
        await http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      } catch (_) {}
    }();
  }

  Future<List<Map<String, dynamic>>> _fetchComments() async {
    final id = widget.mood['id'] ?? 0;
    final uri = Uri.parse('$apiBase/api/moods/$id/comments');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List data = body['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [
      {'author': '匿名', 'content': '加油！慢慢来～'},
      {'author': '匿名', 'content': '我也有类似经历，互相鼓励'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('心情详情')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NiceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.mood['content'] ?? ''),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.mode_comment_outlined, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${widget.mood['comments'] ?? 0}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite_border, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${widget.mood['likes'] ?? 0}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(width: 16),
                      Icon(Icons.remove_red_eye_outlined, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${widget.mood['views'] ?? 0}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NiceSectionHeader(title: '评论'),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text('还没有评论，来做第一个吧', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    );
                  }
                  return ListView.separated(
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      return Column(
                        children: [
                          NiceCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(radius: 14, backgroundColor: cs.secondaryContainer,
                                      backgroundImage: (c['author']?['avatar_url'] != null) ? NetworkImage(c['author']['avatar_url']) : null,
                                      child: (c['author']?['avatar_url'] == null) ? Icon(Icons.person, size: 16, color: cs.onSecondaryContainer) : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(c['author']?['name'] ?? '匿名', style: Theme.of(context).textTheme.bodySmall)),
                                    Text(_formatTime(c['created_at']), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                    const SizedBox(width: 8),
                                    if (c['owned_by_me'] == true)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: widget.token == null ? null : () => _deleteComment(c['id']),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(c['content'] ?? ''),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: widget.token == null ? null : () {
                                      setState(() {
                                        _replyParentId = c['id'];
                                        _commentCtrl.text = '@${c['author']?['name'] ?? '匿名'} ';
                                      });
                                    },
                                    child: const Text('回复'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if ((c['children'] ?? []) is List && (c['children'] as List).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 6),
                              child: Column(
                                children: List.generate((c['children'] as List).length, (j) {
                                  final cc = (c['children'] as List)[j] as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: NiceCard(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(radius: 12, backgroundColor: cs.secondaryContainer,
                                                backgroundImage: (cc['author']?['avatar_url'] != null) ? NetworkImage(cc['author']['avatar_url']) : null,
                                                child: (cc['author']?['avatar_url'] == null) ? Icon(Icons.person, size: 14, color: cs.onSecondaryContainer) : null,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(child: Text(cc['author']?['name'] ?? '匿名', style: Theme.of(context).textTheme.bodySmall)),
                                              Text(_formatTime(cc['created_at']), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                              const SizedBox(width: 8),
                                              if (cc['owned_by_me'] == true)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline),
                                                  onPressed: widget.token == null ? null : () => _deleteComment(cc['id']),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(cc['content'] ?? ''),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (widget.token == null)
              Text('登录后可发表评论', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: '写下你的想法...',
                        helperText: '${300 - (_commentCtrl.text.length)} 字剩余',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  NiceActionButton(
                    onPressed: _posting ? null : _postComment,
                    icon: Icons.send,
                    label: '发表',
                    variant: NiceButtonVariant.tonal,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _postComment() async {
    if (widget.token == null) return;
    setState(() => _posting = true);
    final id = widget.mood['id'] ?? 0;
    try {
      final uri = Uri.parse('$apiBase/api/moods/$id/comments');
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
          body: json.encode({'content': _commentCtrl.text.trim(), 'parent_id': _replyParentId}));
      if (res.statusCode == 201) {
        setState(() {
          _future = _fetchComments();
          _replyParentId = null;
        });
        _commentCtrl.clear();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发表')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('评论失败：${res.statusCode}')));
      }
    } catch (_) {
      // 后端未就绪兜底：本地刷新
      setState(() {
        _future = Future.value([
          {'author': '你', 'content': _commentCtrl.text.trim()},
          ...([]),
        ]);
      });
      _commentCtrl.clear();
    } finally {
      setState(() => _posting = false);
    }
  }

  Future<void> _deleteComment(int id) async {
    try {
      final uri = Uri.parse('$apiBase/api/comments/$id');
      final res = await http.delete(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        setState(() {
          _future = _fetchComments();
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除评论')));
      }
    } catch (_) {}
  }

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
class _CommunityPageState extends State<CommunityPage> {
  late Future<List<Map<String, dynamic>>> _future;

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final uri = Uri.parse('$apiBase/api/categories');
    try {
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [
      {'key': 'experience', 'name': '经验交流', 'desc': '分享经历与方法'},
      {'key': 'practice', 'name': '练习打卡', 'desc': '每日复读与练习'},
      {'key': 'resources', 'name': '资源分享', 'desc': '教材与资料'},
      {'key': 'qa', 'name': '求助问答', 'desc': '提问与解答'},
      {'key': 'events', 'name': '线下活动', 'desc': '聚会与活动'},
    ];
  }

  @override
  void initState() {
    super.initState();
    _future = _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cats = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const NiceSectionHeader(title: '分类'),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: cats.map((cat) => InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage(category: cat, token: widget.token)));
                  },
                  child: NiceCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_iconFor((cat['key'] ?? '') as String), color: cs.onPrimaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text((cat['name'] ?? '') as String, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                (cat['desc'] ?? '') as String,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'experience':
        return Icons.forum;
      case 'practice':
        return Icons.mic;
      case 'resources':
        return Icons.book;
      case 'qa':
        return Icons.help;
      case 'events':
        return Icons.event;
      default:
        return Icons.category;
    }
  }
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.category, this.token});
  final Map<String, dynamic> category;
  final String? token;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<Map<String, dynamic>> _future;
  String _sort = 'latest';

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, dynamic>> _fetchDetail() async {
    final key = (widget.category['key'] ?? '') as String;
    final uri = Uri.parse('$apiBase/api/categories/$key?sort=${_sort}');
    try {
      final headers = {'Accept': 'application/json', if (widget.token != null) 'Authorization': 'Bearer ${widget.token}'};
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return data;
      }
    } catch (_) {}
    return {
      'category': widget.category,
      'content': [],
    };
  }

  @override
  void initState() {
    super.initState();
    _future = _fetchDetail();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(((widget.category['name']) ?? '分类') as String)),
      floatingActionButton: widget.token == null ? null : FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ComposePostPage(token: widget.token!, categoryKey: (widget.category['key'] ?? '') as String?)));
          if (ok == true) {
            setState(() { _future = _fetchDetail(); });
          }
        },
        child: const Icon(Icons.edit),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snapshot.data ?? {'category': widget.category, 'content': []};
          final List content = (detail['content'] ?? []) as List;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ChoiceChip(label: const Text('最新'), selected: _sort == 'latest', onSelected: (_) => setState(() { _sort = 'latest'; _future = _fetchDetail(); })),
                    const SizedBox(width: 12),
                    ChoiceChip(label: const Text('热门'), selected: _sort == 'hot', onSelected: (_) => setState(() { _sort = 'hot'; _future = _fetchDetail(); })),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    NiceCard(child: Text(((detail['category'] ?? widget.category)['desc'] ?? '') as String)),
                    const SizedBox(height: 16),
                    if (content.isEmpty)
                      Text('暂无内容', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ...content.map((e) {
                      final m = e as Map<String, dynamic>;
                      final liked = (m['liked_by_me'] ?? false) as bool;
                      final favored = (m['favorited_by_me'] ?? false) as bool;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: m, token: widget.token)));
                          },
                          child: NiceCard(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final dynamic rawId = m['author']?['id'];
                                          final int? uid = rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);
                                          if (uid != null && widget.token != null) {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => PersonalSpacePage(
                                                token: widget.token!,
                                                userId: uid,
                                                userName: m['author']?['name'] as String?,
                                                avatarUrl: m['author']?['avatar_url'] as String?,
                                              ),
                                            ));
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: cs.secondaryContainer,
                                          backgroundImage: (m['author']?['avatar_url'] != null) ? NetworkImage(m['author']['avatar_url']) : null,
                                          child: (m['author']?['avatar_url'] == null) ? Icon(Icons.person, size: 14, color: cs.onSecondaryContainer) : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(m['author']?['name'] ?? '匿名', style: Theme.of(context).textTheme.bodySmall)),
                                      Text(_formatTime(m['created_at']), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text((m['title'] ?? '') as String, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Text((m['body'] ?? '') as String, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
                                        onPressed: widget.token == null ? null : () async {
                                          final uri = Uri.parse('$apiBase/api/posts/${m['id']}/like');
                                          final headers = {'Authorization': 'Bearer ${widget.token}'};
                                          final res = await (liked ? http.delete(uri, headers: headers) : http.post(uri, headers: headers));
                                          if (res.statusCode == 200) setState(() { _future = _fetchDetail(); });
                                        },
                                      ),
                                      Text('${m['likes'] ?? 0}'),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: Icon(favored ? Icons.bookmark : Icons.bookmark_border),
                                        onPressed: widget.token == null ? null : () async {
                                          final uri = Uri.parse('$apiBase/api/posts/${m['id']}/favorite');
                                          final headers = {'Authorization': 'Bearer ${widget.token}'};
                                          final res = await (favored ? http.delete(uri, headers: headers) : http.post(uri, headers: headers));
                                          if (res.statusCode == 200) setState(() { _future = _fetchDetail(); });
                                        },
                                      ),
                                      Text('${m['favorites'] ?? 0}'),
                                      const SizedBox(width: 12),
                                  const Icon(Icons.comment, size: 18),
                                  const SizedBox(width: 4),
                                  Text('${m['comments'] ?? 0}'),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.remove_red_eye_outlined, size: 18),
                                  const SizedBox(width: 4),
                                  Text('${m['views'] ?? 0}')
                                ],
                              ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).cast<Widget>(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<bool> _logout(String token) async {
  final uri = Uri.parse('$apiBase/api/logout');
  try {
    final res = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '登录' : '注册')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_isLogin)
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '昵称')),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: '邮箱')),
            const SizedBox(height: 8),
            TextField(controller: _pwdCtrl, decoration: const InputDecoration(labelText: '密码'), obscureText: true),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_isLogin ? '登录' : '注册'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse('$apiBase/api/' + (_isLogin ? 'login' : 'register'));
      final body = _isLogin
          ? { 'email': _emailCtrl.text.trim(), 'password': _pwdCtrl.text }
          : { 'name': _nameCtrl.text.trim().isEmpty ? '匿名用户' : _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim(), 'password': _pwdCtrl.text };
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = json.decode(res.body);
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;
        final name = (user != null ? user['name'] as String? : null);
        final email = (user != null ? user['email'] as String? : null);
        Navigator.pop<Map<String, String?>>(context, {
          'token': token,
          'userName': name,
          'userEmail': email,
        });
      } else {
        setState(() { _error = '失败：${res.statusCode}'; });
      }
    } catch (e) {
      setState(() { _error = '网络错误'; });
    } finally {
      setState(() { _loading = false; });
    }
  }
}

class ComposePostPage extends StatefulWidget {
  const ComposePostPage({super.key, required this.token, this.categoryKey});
  final String token;
  final String? categoryKey;

  @override
  State<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends State<ComposePostPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发布帖子')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: '标题')),
            const SizedBox(height: 12),
            TextField(controller: _bodyCtrl, decoration: const InputDecoration(labelText: '内容'), maxLines: 5),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: const Icon(Icons.send),
                label: const Text('发布'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$apiBase/api/posts');
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
          body: json.encode({
            'title': _titleCtrl.text.trim(),
            'body': _bodyCtrl.text.trim(),
            if (widget.categoryKey != null) 'category_key': widget.categoryKey,
          }));
      if (res.statusCode == 201) {
        Navigator.pop(context, true);
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post, this.token});
  final Map<String, dynamic> post;
  final String? token;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Future<Map<String, dynamic>> _future;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  Future<Map<String, dynamic>> _fetch() async {
    final uri = Uri.parse('$apiBase/api/posts/${widget.post['id']}/comments');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    return {'data': []};
  }

  Future<void> _send() async {
    if (widget.token == null) return;
    setState(() => _loading = true);
    final uri = Uri.parse('$apiBase/api/posts/${widget.post['id']}/comments');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: json.encode({'content': _commentCtrl.text.trim()}));
    setState(() => _loading = false);
    if (res.statusCode == 201) {
      _commentCtrl.clear();
      setState(() => _future = _fetch());
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    // 浏览打点
    () async {
      if (widget.token == null) return;
      try {
        final uri = Uri.parse('$apiBase/api/posts/${widget.post['id']}/view');
        await http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      } catch (_) {}
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.post['title'] ?? '') as String),
        actions: [
          if (widget.token != null)
            IconButton(
              tooltip: '转发到个人空间',
              icon: const Icon(Icons.person_pin_circle_outlined),
              onPressed: () async {
                try {
                  final uri = Uri.parse('$apiBase/api/posts/${widget.post['id']}/favorite');
                  final res = await http.post(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
                  if (res.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已转发到个人空间（收藏）')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('转发失败，请稍后重试')));
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网络异常，稍后重试')));
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text((widget.post['body'] ?? '') as String),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List comments = (snapshot.data?['data'] ?? []) as List;
                if (comments.isEmpty) {
                  return const Center(child: Text('暂无评论'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final c = comments[index] as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text((c['author']?['name'] ?? '匿名') as String),
                      subtitle: Text((c['content'] ?? '') as String),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: comments.length,
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _commentCtrl, decoration: const InputDecoration(hintText: '写下你的评论...'))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _loading ? null : _send, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('发送')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.mic, size: 64, color: cs.onPrimaryContainer),
                const SizedBox(height: 12),
                Text('今日练习建议', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('轻声起音 → 延长发音 → 朗读 2 段',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onPrimaryContainer.withOpacity(.8))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NiceActionButton(
            onPressed: () {},
            icon: Icons.play_arrow,
            label: '开始练习',
            variant: NiceButtonVariant.primary,
          ),
          const SizedBox(height: 12),
          NiceActionButton(
            onPressed: () {},
            icon: Icons.upload_file,
            label: '上传录音并获取反馈',
            variant: NiceButtonVariant.outline,
          ),
        ],
      ),
    );
  }
}

class MePage extends StatelessWidget {
  const MePage({super.key, this.userName, this.userEmail, this.userBio, this.avatarUrl, this.accountId, this.onEdit, this.onChangePassword, this.token});
  final String? userName;
  final String? userEmail;
  final String? userBio;
  final String? avatarUrl;
  final String? accountId;
  final VoidCallback? onEdit;
  final VoidCallback? onChangePassword;
  final String? token;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部个人卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: token == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PersonalSpacePage(token: token!)),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.background,
                        backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
                        child: (avatarUrl == null || avatarUrl!.isEmpty) ? Icon(Icons.person, color: cs.onBackground) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          final displayName = (userName != null && userName!.trim().isNotEmpty && userName != '匿名用户')
                              ? userName!
                              : (userEmail ?? '匿名用户');
                          return Text(displayName, style: Theme.of(context).textTheme.titleMedium);
                        }),
                        if (userEmail != null)
                          Text(userEmail!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        if (accountId != null && accountId!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('账号ID：$accountId', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ),
                        if (userBio != null && userBio!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(userBio!, style: Theme.of(context).textTheme.bodySmall),
                          ),
                      ],
                    ),
                  ),
                  if (token != null)
                    IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(
                          token: token,
                          onLoggedOut: () async {
                            // 尝试调用后端退出
                            if (token != null) {
                              await _logout(token!);
                            }
                            // 清理本地缓存由 RootShell 响应 Drawer 的回调处理
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已退出登录')));
                          },
                        )));
                      },
                      icon: const Icon(Icons.settings),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // 仅显示入口按钮，数据在页面点开后加载
          if (token != null)
            Row(
              children: [
                Expanded(
                  child: NiceActionButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FollowsPage(token: token!)));
                    },
                    icon: Icons.group_outlined,
                    label: '关注与粉丝',
                    variant: NiceButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NiceActionButton(
                    onPressed: onEdit,
                    icon: Icons.edit,
                    label: '编辑资料',
                    variant: NiceButtonVariant.primary,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),
          // 数据统计
          Row(
            children: [
              Expanded(child: _StatCard(title: '连续打卡', value: '7 天')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: '练习时长', value: '42 分钟')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: '成长积分', value: '120')),
            ],
          ),

          const SizedBox(height: 20),
          // 其他入口
          NiceCard(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.badge_outlined), title: Text('我的徽章'), subtitle: Text('坚持、分享、挑战')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.help_outline), title: Text('使用帮助与隐私')),
              ],
            ),
          ),

          // 已移除“我的记录：点赞 / 收藏 / 浏览”区块
        ],
      ),
    );
  }
}

// 我的草稿（占位页）
class MyDraftsPage extends StatelessWidget {
  const MyDraftsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的草稿')),
      body: const Center(child: Text('暂无草稿，发布页支持即时编辑与发布')),
    );
  }
}

// 我的评论（我发表过的评论）
class MyCommentsPage extends StatefulWidget {
  const MyCommentsPage({super.key, this.token});
  final String? token;
  @override
  State<MyCommentsPage> createState() => _MyCommentsPageState();
}

class _MyCommentsPageState extends State<MyCommentsPage> {
  bool _loading = false;
  int _page = 1;
  bool _hasMore = true;
  final List<Map<String, dynamic>> _items = [];

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (widget.token == null) return;
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _page = 1; _hasMore = true; _items.clear(); }
    final uri = Uri.parse('$apiBase/api/me/comments?per_page=10&page=$_page');
    try {
      final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final items = (data['data'] as List).cast<Map<String, dynamic>>();
        setState(() {
          _items.addAll(items);
          _hasMore = data['has_more'] == true;
          _page += 1;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的评论')),
      body: widget.token == null
          ? const Center(child: Text('请先登录以查看我的评论'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_items.isEmpty && !_loading)
                  const Text('暂无评论'),
                for (final c in _items)
                  NiceCard(
                    child: ListTile(
                      leading: const Icon(Icons.mode_comment_outlined),
                      title: Text((c['content'] ?? '') as String),
                      subtitle: Text('${_formatTime(c['created_at'])} · ${(c['post']?['title'] ?? '') as String}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final post = c['post'] as Map<String, dynamic>?;
                        if (post != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: {'id': post['id'], 'title': post['title']}, token: widget.token)));
                        }
                      },
                    ),
                  ),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: NiceActionButton(onPressed: () => _load(), icon: Icons.expand_more, label: _loading ? '加载中…' : '加载更多'),
                  ),
              ],
            ),
    );
  }
}

// 浏览记录（拉取我浏览过的帖子）
class BrowsingHistoryPage extends StatefulWidget {
  const BrowsingHistoryPage({super.key, required this.token});
  final String token;
  @override
  State<BrowsingHistoryPage> createState() => _BrowsingHistoryPageState();
}

class _BrowsingHistoryPageState extends State<BrowsingHistoryPage> {
  bool _loading = false;
  int _page = 1;
  bool _hasMore = true;
  final List<Map<String, dynamic>> _items = [];

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _page = 1; _hasMore = true; _items.clear(); }
    final uri = Uri.parse('$apiBase/api/me/views?per_page=10&page=$_page');
    try {
      final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final items = (data['data'] as List).cast<Map<String, dynamic>>();
        setState(() {
          _items.addAll(items);
          _hasMore = data['has_more'] == true;
          _page += 1;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('浏览记录')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_items.isEmpty && !_loading)
            Text('暂无记录', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          for (final m in _items)
            NiceCard(
              child: ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text((m['title'] ?? '') as String),
                subtitle: Text(_formatTime(m['created_at'])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: m, token: widget.token)));
                },
              ),
            ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: NiceActionButton(onPressed: () => _load(), icon: Icons.expand_more, label: _loading ? '加载中…' : '加载更多'),
            ),
        ],
      ),
    );
  }
}

// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.token, this.onLoggedOut});
  final String? token;
  final VoidCallback? onLoggedOut;

  Future<void> _performLogout(BuildContext context) async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('尚未登录')));
      return;
    }
    final ok = await _logout(token!);
    if (ok) {
      final sp = await SharedPreferences.getInstance();
      await sp.remove('token');
      await sp.remove('user_name');
      await sp.remove('user_email');
      await sp.remove('user_bio');
      await sp.remove('user_avatar_url');
      await sp.remove('user_account_id');
      onLoggedOut?.call();
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('退出登录失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('账号与安全'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AccountSecurityPage(token: token)));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隐私设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsPage()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('帮助与客服'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于语伴同行'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () => _performLogout(context),
          ),
        ],
      ),
    );
  }
}

class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key, this.token});
  final String? token;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号与安全')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.devices_other_outlined),
            title: const Text('登录设备管理'),
            subtitle: const Text('查看并管理已登录设备（占位）'),
            onTap: () {
              showDialog(context: context, builder: (_) => const AlertDialog(title: Text('提示'), content: Text('该功能尚未开发')));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('注销账号'),
            subtitle: const Text('永久删除账户（占位）'),
            onTap: () {
              showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('确认注销'),
                content: const Text('该功能尚未开发，确认后不执行任何操作。'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
                ],
              ));
            },
          ),
        ],
      ),
    );
  }
}

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通用设置')),
      body: const Center(child: Text('通用设置暂未提供内容')),
    );
  }
}

// 隐私设置页面
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});
  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _onlyFollowingsCanComment = false;
  bool _onlyFollowingsCanMention = false;
  bool _favoritesPublic = true;
  bool _ratingsPublic = true;
  bool _spacePublic = true;
  List<int> _blacklist = [];

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _onlyFollowingsCanComment = sp.getBool('privacy_only_followings_can_comment') ?? false;
      _onlyFollowingsCanMention = sp.getBool('privacy_only_followings_can_mention') ?? false;
      _favoritesPublic = sp.getBool('privacy_favorites_public') ?? true;
      _ratingsPublic = sp.getBool('privacy_ratings_public') ?? true;
      _spacePublic = sp.getBool('privacy_space_public') ?? true;
      final raw = sp.getString('privacy_blacklist_user_ids');
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = (json.decode(raw) as List).map((e) => (e as num).toInt()).toList();
          _blacklist = list;
        } catch (_) {}
      }
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, value);
  }

  Future<void> _saveBlacklist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('privacy_blacklist_user_ids', json.encode(_blacklist));
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('隐私设置')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.comment_bank_outlined),
            title: const Text('只允许我关注的人评论我'),
            subtitle: const Text('开启后，未被我关注的用户无法评论我'),
            value: _onlyFollowingsCanComment,
            onChanged: (v) {
              setState(() => _onlyFollowingsCanComment = v);
              _saveBool('privacy_only_followings_can_comment', v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.alternate_email_outlined),
            title: const Text('只允许我关注的人@我'),
            subtitle: const Text('开启后，未被我关注的用户无法@我'),
            value: _onlyFollowingsCanMention,
            onChanged: (v) {
              setState(() => _onlyFollowingsCanMention = v);
              _saveBool('privacy_only_followings_can_mention', v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.favorite_outline),
            title: const Text('我的收藏是否公开'),
            subtitle: Text(_favoritesPublic ? '公开' : '不公开', style: TextStyle(color: cs.onSurfaceVariant)),
            value: _favoritesPublic,
            onChanged: (v) {
              setState(() => _favoritesPublic = v);
              _saveBool('privacy_favorites_public', v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.reviews_outlined),
            title: const Text('我的评价是否公开'),
            subtitle: Text(_ratingsPublic ? '公开' : '不公开', style: TextStyle(color: cs.onSurfaceVariant)),
            value: _ratingsPublic,
            onChanged: (v) {
              setState(() => _ratingsPublic = v);
              _saveBool('privacy_ratings_public', v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.public_outlined),
            title: const Text('我的空间是否公开'),
            subtitle: Text(_spacePublic ? '公开' : '不公开', style: TextStyle(color: cs.onSurfaceVariant)),
            value: _spacePublic,
            onChanged: (v) {
              setState(() => _spacePublic = v);
              _saveBool('privacy_space_public', v);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('黑名单用户'),
            subtitle: Text(_blacklist.isEmpty ? '未添加黑名单' : '共${_blacklist.length}人'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final updated = await Navigator.push<List<int>>(context, MaterialPageRoute(builder: (_) => BlacklistPage(initial: _blacklist)));
              if (updated != null) {
                setState(() => _blacklist = updated);
                _saveBlacklist();
              }
            },
          ),
        ],
      ),
    );
  }
}

// 黑名单管理页面
class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key, required this.initial});
  final List<int> initial;
  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  late List<int> _ids;
  final TextEditingController _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ids = [...widget.initial];
  }

  void _addId() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final id = int.tryParse(text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的用户ID')));
      return;
    }
    if (_ids.contains(id)) return;
    setState(() { _ids.add(id); _inputCtrl.clear(); });
  }

  void _removeId(int id) {
    setState(() { _ids.remove(id); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('黑名单用户'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ids),
            child: const Text('完成'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '输入用户ID并添加到黑名单',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addId, child: const Text('添加')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _ids.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final id = _ids[index];
                  return ListTile(
                    leading: const Icon(Icons.person_off_outlined),
                    title: Text('用户ID：$id'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeId(id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('帮助与客服')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('常见问题', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('• 如何发布树洞与帖子\n• 如何查看收藏与浏览记录\n• 如何关注与取消关注', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text('联系客服', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('邮箱：support@example.com\n微信：stutter-helper'),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('关于语伴同行')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('语伴同行', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('版本：v0.1.0', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            const Text('语伴同行旨在提供交流、练习建议与树洞记录功能。'),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NiceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.initialName, this.initialBio, this.initialAccountId, this.token});
  final String? initialName;
  final String? initialBio;
  final String? initialAccountId;
  final String? token;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class MeRecordsSection extends StatefulWidget {
  const MeRecordsSection({super.key, required this.token});
  final String token;

  @override
  State<MeRecordsSection> createState() => _MeRecordsSectionState();
}

// 获赞与收藏统计（别人给我的）
class MeStatsReceived extends StatefulWidget {
  const MeStatsReceived({super.key, required this.token});
  final String token;
  @override
  State<MeStatsReceived> createState() => _MeStatsReceivedState();
}

class _MeStatsReceivedState extends State<MeStatsReceived> {
  int _likesReceived = 0;
  int _favoritesReceived = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_loading) return; setState(() => _loading = true);
    final uri = Uri.parse('$apiBase/api/me/stats_received');
    try {
      final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          _likesReceived = (data['likes_received'] ?? 0) as int;
          _favoritesReceived = (data['favorites_received'] ?? 0) as int;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NiceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(leading: Icon(Icons.bar_chart), title: Text('我的数据（别人给我的）')),
            const Divider(height: 1),
            Row(
              children: [
                Expanded(child: _StatCard(title: '获赞', value: _loading ? '…' : '$_likesReceived')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: '被收藏', value: _loading ? '…' : '$_favoritesReceived')),
              ],
            ),
            const SizedBox(height: 8),
            Text('统计你发布内容被点赞与被收藏的总次数', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// 关注与粉丝列表
class MeFollowsSection extends StatefulWidget {
  const MeFollowsSection({super.key, required this.token});
  final String token;
  @override
  State<MeFollowsSection> createState() => _MeFollowsSectionState();
}

class _MeFollowsSectionState extends State<MeFollowsSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  int _pageFollowers = 1;
  int _pageFollowings = 1;
  bool _hasMoreFollowers = true;
  bool _hasMoreFollowings = true;
  final List<Map<String, dynamic>> _followers = [];
  final List<Map<String, dynamic>> _followings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFollowers(reset: true);
    _loadFollowings(reset: true);
  }

  Future<void> _loadFollowers({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageFollowers = 1; _hasMoreFollowers = true; _followers.clear(); }
    final uri = Uri.parse('$apiBase/api/me/followers?per_page=10&page=$_pageFollowers');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _followers.addAll(items);
        _hasMoreFollowers = data['has_more'] == true;
        _pageFollowers += 1;
      });
    }
  }

  Future<void> _loadFollowings({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageFollowings = 1; _hasMoreFollowings = true; _followings.clear(); }
    final uri = Uri.parse('$apiBase/api/me/followings?per_page=10&page=$_pageFollowings');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _followings.addAll(items);
        _hasMoreFollowings = data['has_more'] == true;
        _pageFollowings += 1;
      });
    }
  }

  Widget _buildUserList(List<Map<String, dynamic>> items, bool hasMore, VoidCallback onLoadMore) {
    return Column(
      children: [
        for (final u in items)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text((u['name'] ?? '') as String),
            subtitle: Text((u['email'] ?? '') as String),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: NiceActionButton(onPressed: onLoadMore, icon: Icons.expand_more, label: '加载更多'),
          ),
        if (!hasMore && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('暂无数据'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('关注与粉丝'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FollowsPage(token: widget.token)));
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: NiceActionButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FollowsPage(token: widget.token, initialTabIndex: 0)));
                    },
                    icon: Icons.compare_arrows_outlined,
                    label: '互相关注',
                    variant: NiceButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NiceActionButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FollowsPage(token: widget.token, initialTabIndex: 1)));
                    },
                    icon: Icons.person_add_alt_1_outlined,
                    label: '关注',
                    variant: NiceButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NiceActionButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FollowsPage(token: widget.token, initialTabIndex: 2)));
                    },
                    icon: Icons.people_outline,
                    label: '粉丝',
                    variant: NiceButtonVariant.outline,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(padding: const EdgeInsets.all(8), child: _buildUserList(_followings, _hasMoreFollowings, () => _loadFollowings())),
                SingleChildScrollView(padding: const EdgeInsets.all(8), child: _buildUserList(_followers, _hasMoreFollowers, () => _loadFollowers())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 关注页面：互相关注 / 关注 / 粉丝 三个标签
class FollowsPage extends StatefulWidget {
  const FollowsPage({super.key, required this.token, this.initialTabIndex = 1});
  final String token;
  final int initialTabIndex; // 0: 互相关注, 1: 关注, 2: 粉丝

  @override
  State<FollowsPage> createState() => _FollowsPageState();
}

class _FollowsPageState extends State<FollowsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  int _pageMutuals = 1;
  int _pageFollowers = 1;
  int _pageFollowings = 1;
  bool _hasMoreMutuals = true;
  bool _hasMoreFollowers = true;
  bool _hasMoreFollowings = true;
  final List<Map<String, dynamic>> _mutuals = [];
  final List<Map<String, dynamic>> _followers = [];
  final List<Map<String, dynamic>> _followings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 2));
    _loadMutuals(reset: true);
    _loadFollowers(reset: true);
    _loadFollowings(reset: true);
  }

  Future<void> _loadMutuals({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageMutuals = 1; _hasMoreMutuals = true; _mutuals.clear(); }
    final uri = Uri.parse('$apiBase/api/me/mutuals?per_page=10&page=$_pageMutuals');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _mutuals.addAll(items);
        _hasMoreMutuals = data['has_more'] == true;
        _pageMutuals += 1;
      });
    }
  }

  Future<void> _loadFollowers({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageFollowers = 1; _hasMoreFollowers = true; _followers.clear(); }
    final uri = Uri.parse('$apiBase/api/me/followers?per_page=10&page=$_pageFollowers');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _followers.addAll(items);
        _hasMoreFollowers = data['has_more'] == true;
        _pageFollowers += 1;
      });
    }
  }

  Future<void> _loadFollowings({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageFollowings = 1; _hasMoreFollowings = true; _followings.clear(); }
    final uri = Uri.parse('$apiBase/api/me/followings?per_page=10&page=$_pageFollowings');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _followings.addAll(items);
        _hasMoreFollowings = data['has_more'] == true;
        _pageFollowings += 1;
      });
    }
  }

  Widget _buildUserList(List<Map<String, dynamic>> items, bool hasMore, VoidCallback onLoadMore) {
    return Column(
      children: [
        for (final u in items)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text((u['name'] ?? '') as String),
            subtitle: Text((u['email'] ?? '') as String),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: NiceActionButton(onPressed: onLoadMore, icon: Icons.expand_more, label: '加载更多'),
          ),
        if (!hasMore && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('暂无数据'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关注关系'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '互相关注'),
            Tab(text: '关注'),
            Tab(text: '粉丝'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(padding: const EdgeInsets.all(12), child: _buildUserList(_mutuals, _hasMoreMutuals, () => _loadMutuals())),
          SingleChildScrollView(padding: const EdgeInsets.all(12), child: _buildUserList(_followings, _hasMoreFollowings, () => _loadFollowings())),
          SingleChildScrollView(padding: const EdgeInsets.all(12), child: _buildUserList(_followers, _hasMoreFollowers, () => _loadFollowers())),
        ],
      ),
    );
  }
}

// 个人空间页面：我的树洞 / 我的帖子 / 我的收藏
class PersonalSpacePage extends StatefulWidget {
  const PersonalSpacePage({super.key, required this.token, this.userId, this.userName, this.avatarUrl});
  final String token;
  final int? userId;
  final String? userName;
  final String? avatarUrl;

  @override
  State<PersonalSpacePage> createState() => _PersonalSpacePageState();
}

class _PersonalSpacePageState extends State<PersonalSpacePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loadingMoods = false;
  bool _loadingPosts = false;
  bool _loadingFavs = false;
  int? _meId;
  bool _isFollowing = false;
  List<Map<String, dynamic>> _myMoods = [];
  List<Map<String, dynamic>> _myPosts = [];
  List<Map<String, dynamic>> _myFavorites = [];

  String _formatTime(dynamic t) {
    try {
      final dt = t is String ? DateTime.parse(t) : (t as DateTime);
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMe().then((_) {
      _loadMyMoods();
      _loadMyPosts();
      if (!_isViewingOther()) {
        _loadMyFavorites();
      }
      if (_isViewingOther()) {
        _checkFollowing();
      }
    });
  }

  bool _isViewingOther() => widget.userId != null && (_meId == null || widget.userId != _meId);

  Future<void> _loadMe() async {
    try {
      final uri = Uri.parse('$apiBase/api/user');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() { _meId = data['id'] as int?; });
      }
    } catch (_) {}
  }

  Future<void> _checkFollowing() async {
    try {
      final uri = Uri.parse('$apiBase/api/me/followings?per_page=50&page=1');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final List list = (data['data'] ?? []) as List;
        final uid = widget.userId;
        if (uid != null) {
          setState(() { _isFollowing = list.any((e) => (e as Map<String, dynamic>)['id'] == uid); });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMyMoods() async {
    if (_loadingMoods) return; setState(() => _loadingMoods = true);
    try {
      final authorParam = (widget.userId != null) ? '&author=${widget.userId}' : '';
      final uri = Uri.parse('$apiBase/api/moods?per_page=20&page=1$authorParam');
      final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final items = (data['data'] as List).cast<Map<String, dynamic>>();
        setState(() {
          _myMoods = (widget.userId != null) ? items : items.where((m) => (m['owned_by_me'] ?? false) == true).toList();
        });
      }
    } catch (_) {}
    setState(() => _loadingMoods = false);
  }

  Future<void> _loadMyPosts() async {
    if (_loadingPosts) return; setState(() => _loadingPosts = true);
    try {
      final authorParam = (widget.userId != null) ? 'author=${widget.userId}' : 'author=me';
      final uri = Uri.parse('$apiBase/api/posts?$authorParam&per_page=20&page=1');
      final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          _myPosts = ((data['data'] ?? []) as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    setState(() => _loadingPosts = false);
  }

  Future<void> _loadMyFavorites() async {
    if (_loadingFavs) return; setState(() => _loadingFavs = true);
    try {
      final uri = Uri.parse('$apiBase/api/me/favorites?per_page=20&page=1');
      final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          _myFavorites = ((data['data'] ?? []) as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    setState(() => _loadingFavs = false);
  }

  Widget _buildMoodItem(Map<String, dynamic> m) {
    final cs = Theme.of(context).colorScheme;
    return NiceCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.secondaryContainer,
                  backgroundImage: (m['author']?['avatar_url'] != null) ? NetworkImage(m['author']['avatar_url']) : null,
                  child: (m['author']?['avatar_url'] == null) ? Icon(Icons.person, size: 16, color: cs.onSecondaryContainer) : null,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(m['author']?['name'] ?? '我', style: Theme.of(context).textTheme.bodySmall)),
                Text(_formatTime(m['created_at']), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            Text((m['content'] ?? '') as String),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> p) {
    return NiceCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((p['title'] ?? '') as String, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text((p['body'] ?? '') as String),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isViewingOther() ? (widget.userName ?? '个人空间') : '个人空间'),
        actions: [
          if (_isViewingOther())
            NiceActionButton(
              onPressed: () async {
                if (widget.userId == null) return;
                try {
                  final uri = Uri.parse('$apiBase/api/users/${widget.userId}/follow');
                  final headers = {'Authorization': 'Bearer ${widget.token}'};
                  final res = await (_isFollowing ? http.delete(uri, headers: headers) : http.post(uri, headers: headers));
                  if (res.statusCode == 200) {
                    setState(() { _isFollowing = !_isFollowing; });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isFollowing ? '已关注' : '已取消关注')));
                  }
                } catch (_) {}
              },
              icon: _isFollowing ? Icons.person_remove_alt_1 : Icons.person_add_alt_1,
              label: _isFollowing ? '取消关注' : '关注',
              variant: NiceButtonVariant.tonal,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '树洞'),
            Tab(text: '帖子'),
            Tab(text: '收藏'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 我的树洞
          RefreshIndicator(
            onRefresh: _loadMyMoods,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadingMoods) const Center(child: CircularProgressIndicator()),
                if (!_loadingMoods && _myMoods.isEmpty) const Center(child: Text('暂无树洞')),
                ..._myMoods.map(_buildMoodItem),
              ],
            ),
          ),
          // 我的帖子
          RefreshIndicator(
            onRefresh: _loadMyPosts,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadingPosts) const Center(child: CircularProgressIndicator()),
                if (!_loadingPosts && _myPosts.isEmpty) const Center(child: Text('暂无帖子')),
                ..._myPosts.map(_buildPostItem),
              ],
            ),
          ),
          // 我的收藏
          RefreshIndicator(
            onRefresh: _loadMyFavorites,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadingFavs) const Center(child: CircularProgressIndicator()),
                if (!_loadingFavs && _myFavorites.isEmpty) const Center(child: Text('暂无收藏')),
                ..._myFavorites.map(_buildPostItem),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeRecordsSectionState extends State<MeRecordsSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _pageLikes = 1;
  int _pageFavorites = 1;
  int _pageViews = 1;
  bool _loading = false;
  bool _hasMoreLikes = true;
  bool _hasMoreFavorites = true;
  bool _hasMoreViews = true;
  List<Map<String, dynamic>> _likes = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _views = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLikes(reset: true);
    _loadFavorites(reset: true);
    _loadViews(reset: true);
  }

  Future<void> _loadLikes({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageLikes = 1; _hasMoreLikes = true; _likes = []; }
    final uri = Uri.parse('$apiBase/api/me/likes?per_page=10&page=$_pageLikes');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _likes.addAll(items);
        _hasMoreLikes = data['has_more'] == true;
        _pageLikes += 1;
      });
    }
  }

  Future<void> _loadFavorites({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageFavorites = 1; _hasMoreFavorites = true; _favorites = []; }
    final uri = Uri.parse('$apiBase/api/me/favorites?per_page=10&page=$_pageFavorites');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _favorites.addAll(items);
        _hasMoreFavorites = data['has_more'] == true;
        _pageFavorites += 1;
      });
    }
  }

  Future<void> _loadViews({bool reset = false}) async {
    if (_loading) return; setState(() => _loading = true);
    if (reset) { _pageViews = 1; _hasMoreViews = true; _views = []; }
    final uri = Uri.parse('$apiBase/api/me/views?per_page=10&page=$_pageViews');
    final res = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'});
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _views.addAll(items);
        _hasMoreViews = data['has_more'] == true;
        _pageViews += 1;
      });
    }
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool hasMore, VoidCallback onLoadMore) {
    return Column(
      children: [
        for (final p in items)
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text((p['title'] ?? '') as String),
            subtitle: Text('👍 ${(p['likes'] ?? 0)}   ⭐ ${(p['favorites'] ?? 0)}   💬 ${(p['comments'] ?? 0)}'),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: p, token: widget.token)));
            },
          ),
        if (hasMore) Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: NiceActionButton(onPressed: onLoadMore, icon: Icons.expand_more, label: '加载更多'),
        ),
        if (!hasMore && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('暂无内容'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ListTile(leading: Icon(Icons.history), title: Text('我的记录')),
          const Divider(height: 1),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '点赞'),
              Tab(text: '收藏'),
              Tab(text: '浏览'),
            ],
          ),
          const Divider(height: 1),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(padding: const EdgeInsets.all(8), child: _buildList(_likes, _hasMoreLikes, () => _loadLikes())),
                SingleChildScrollView(padding: const EdgeInsets.all(8), child: _buildList(_favorites, _hasMoreFavorites, () => _loadFavorites())),
                SingleChildScrollView(padding: const EdgeInsets.all(8), child: _buildList(_views, _hasMoreViews, () => _loadViews())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.initialName ?? '');
  late final TextEditingController _bioCtrl = TextEditingController(text: widget.initialBio ?? '');
  late final TextEditingController _accountIdCtrl = TextEditingController(text: widget.initialAccountId ?? '');
  final TextEditingController _regionCtrl = TextEditingController();
  String _gender = 'other'; // male / female / other
  bool _genderPublic = true;
  bool _regionPublic = true;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('编辑资料')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NiceCard(
              child: Column(
                children: [
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '昵称')),
                  const SizedBox(height: 12),
                  TextField(controller: _bioCtrl, maxLines: 4, decoration: const InputDecoration(labelText: '简介')),
                  const SizedBox(height: 12),
                  TextField(controller: _accountIdCtrl, decoration: const InputDecoration(labelText: '账号ID')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    items: const [
                      DropdownMenuItem(value: 'other', child: Text('保密')),
                      DropdownMenuItem(value: 'male', child: Text('男')),
                      DropdownMenuItem(value: 'female', child: Text('女')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'other'),
                    decoration: const InputDecoration(labelText: '性别'),
                  ),
                  SwitchListTile(
                    value: _genderPublic,
                    onChanged: (v) => setState(() => _genderPublic = v),
                    title: const Text('性别是否公开'),
                  ),
                  TextField(controller: _regionCtrl, decoration: const InputDecoration(labelText: '地区')),
                  SwitchListTile(
                    value: _regionPublic,
                    onChanged: (v) => setState(() => _regionPublic = v),
                    title: const Text('地区是否公开'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NiceActionButton(
                    onPressed: _saving ? null : _saveProfile,
                    icon: Icons.save,
                    label: '保存资料',
                    variant: NiceButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NiceActionButton(
                    onPressed: _saving ? null : _uploadAvatar,
                    icon: Icons.photo_camera,
                    label: '上传头像',
                    variant: NiceButtonVariant.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('保存会更新服务器数据，返回后自动刷新“我的”页', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }
    setState(() => _saving = true);
    try {
      final uri = Uri.parse('$apiBase/api/user');
      final res = await http.put(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'name': _nameCtrl.text.trim(),
            'bio': _bioCtrl.text.trim(),
            'account_id': _accountIdCtrl.text.trim(),
            'gender': _gender,
            'gender_public': _genderPublic,
            'region': _regionCtrl.text.trim(),
            'region_public': _regionPublic,
          }));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
        Navigator.pop(context);
      } else {
        String msg = '保存失败：${res.statusCode}';
        try {
          final data = json.decode(res.body);
          if (data is Map && data['message'] is String) {
            msg = data['message'];
          } else if (data is Map && data['errors'] is Map) {
            final Map errs = data['errors'] as Map;
            if (errs.isNotEmpty) {
              final firstKey = errs.keys.first;
              final firstVal = errs[firstKey];
              if (firstVal is List && firstVal.isNotEmpty) {
                msg = firstVal.first.toString();
              }
            }
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网络错误')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _uploadAvatar() async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final uri = Uri.parse('$apiBase/api/user/avatar');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer ${widget.token}';
      req.files.add(http.MultipartFile.fromBytes('avatar', file.bytes!, filename: file.name));
      final res = await req.send();
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('头像已更新')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传失败：${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网络错误')));
    } finally {
      setState(() => _saving = false);
    }
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.token});
  final String? token;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('修改密码')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NiceCard(
              child: Column(
                children: [
                  TextField(controller: _currentCtrl, decoration: const InputDecoration(labelText: '当前密码'), obscureText: true),
                  const SizedBox(height: 12),
                  TextField(controller: _newCtrl, decoration: const InputDecoration(labelText: '新密码（至少6位）'), obscureText: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: NiceActionButton(
                onPressed: _saving ? null : _submit,
                icon: Icons.lock_reset,
                label: '提交修改',
                variant: NiceButtonVariant.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('修改成功后会返回“我的”页', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }
    setState(() => _saving = true);
    try {
      final uri = Uri.parse('$apiBase/api/user/password');
      final res = await http.put(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'current_password': _currentCtrl.text,
            'new_password': _newCtrl.text,
          }));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码已更新')));
        Navigator.pop(context);
      } else {
        String msg = '修改失败：${res.statusCode}';
        try {
          final data = json.decode(res.body);
          msg = data['message'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网络错误')));
    } finally {
      setState(() => _saving = false);
    }
  }
}
