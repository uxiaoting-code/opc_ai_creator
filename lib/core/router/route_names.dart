/// 路由路径 & 路由名常量。
///
/// 全项目跳转统一使用这里的常量，禁止在页面里手写字符串路径，
/// 否则后期改路径要全项目搜索替换。
///
/// 命名约定：
/// - 路径用 kebab-case，Web 上会直接显示在浏览器地址栏；
/// - 带参数的路由额外提供 `xxxPath(id)` 辅助方法，避免手拼字符串。
class RouteNames {
  const RouteNames._();

  // ===========================================================================
  // 一、13 个业务页面对照表
  // ===========================================================================
  // | # | 页面            | 路径                      | 类型     |
  // |---|-----------------|---------------------------|----------|
  // | 1 | 登录/注册页     | /login                    | 顶层     |
  // | 2 | 首页(Skill入口) | /home                     | 底部Tab  |
  // | 3 | 文生图创作页    | /create/text-to-image     | 顶层     |
  // | 4 | 图生视频创作页  | /create/image-to-video    | 顶层     |
  // | 5 | 我的任务列表页  | /tasks                    | 底部Tab  |
  // | 6 | 作品画廊        | /gallery                  | 底部Tab  |
  // | 7 | 素材库页        | /materials                | 底部Tab  |
  // | 8 | Prompt知识库广场| /prompts                  | 顶层     |
  // | 9 | Skill市场页     | /skills                   | 顶层     |
  // | 10| 作品详情页      | /gallery/:workId          | Tab内push|
  // | 11| 个人中心        | /profile                  | 底部Tab  |
  // | 12| 设置页          | /settings                 | 顶层     |
  // | 13| 任务详情页      | /tasks/:taskId            | Tab内push|
  // ===========================================================================

  // --- 路由名（go_router 的 name 参数，用于 goNamed/pushNamed） ---

  /// 1. 登录 / 注册
  static const String login = 'login';

  /// 2. 首页（Skill 选择入口）
  static const String home = 'home';

  /// 3. 文生图创作
  static const String textToImage = 'textToImage';

  /// 4. 图生视频创作
  static const String imageToVideo = 'imageToVideo';

  /// 5. 我的任务列表
  static const String taskList = 'taskList';

  /// 6. 作品画廊
  static const String gallery = 'gallery';

  /// 7. 素材库
  static const String materials = 'materials';

  /// 8. Prompt 知识库广场
  static const String prompts = 'prompts';

  /// 9. Skill 市场
  static const String skillMarket = 'skillMarket';

  /// 10. 作品详情
  static const String workDetail = 'workDetail';

  /// 11. 个人中心
  static const String profile = 'profile';

  /// 12. 设置
  static const String settings = 'settings';

  /// 13. 任务详情
  static const String taskDetail = 'taskDetail';

  // --- 路径 ---

  static const String loginPath = '/login';
  static const String homePath = '/home';
  static const String textToImagePath = '/create/text-to-image';
  static const String imageToVideoPath = '/create/image-to-video';
  static const String taskListPath = '/tasks';
  static const String galleryPath = '/gallery';
  static const String materialsPath = '/materials';
  static const String promptsPath = '/prompts';
  static const String skillMarketPath = '/skills';
  static const String profilePath = '/profile';
  static const String settingsPath = '/settings';

  /// 作品详情：/gallery/:workId
  static const String workDetailSegment = ':workId';
  static const String workDetailPath = '$galleryPath/$workDetailSegment';
  static String workDetailOf(Object workId) => '$galleryPath/$workId';

  /// 任务详情：/tasks/:taskId
  static const String taskDetailSegment = ':taskId';
  static const String taskDetailPath = '$taskListPath/$taskDetailSegment';
  static String taskDetailOf(Object taskId) => '$taskListPath/$taskId';

  /// 带查询参数的创作页：从 Skill 市场 / 首页带着线路 ID 直接进创作页。
  static String textToImageWithSkill(Object skillId) =>
      '$textToImagePath?skillId=$skillId';

  static String imageToVideoWithSkill(Object skillId) =>
      '$imageToVideoPath?skillId=$skillId';

  /// 全部 13 个业务页面的路由，顺序与需求清单一致。
  ///
  /// 用途：
  /// - 单元测试里断言「页面数量达标、路径不重复」（见 test/widget_test.dart）；
  /// - 首页的路由自检面板遍历它生成跳转列表。
  static const List<String> allBusinessPaths = [
    loginPath, // 1  登录/注册
    homePath, // 2  首页（Skill 选择入口）
    textToImagePath, // 3  文生图创作
    imageToVideoPath, // 4  图生视频创作
    taskListPath, // 5  我的任务列表（Harness）
    galleryPath, // 6  作品画廊
    materialsPath, // 7  素材库
    promptsPath, // 8  Prompt 知识库广场
    skillMarketPath, // 9  Skill 市场
    workDetailPath, // 10 作品详情
    profilePath, // 11 个人中心
    settingsPath, // 12 设置
    taskDetailPath, // 13 任务详情
  ];

  /// 需求要求的业务页面数量。
  static const int requiredPageCount = 13;
}
