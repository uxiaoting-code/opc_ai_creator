import '../models/notification_model.dart';
import '../models/skill_model.dart';
import '../models/work_model.dart';

/// 本地 Mock 数据源。
///
/// 后端 SpringBoot 还没起的时候，Repository 从这里取数据，
/// 保证「首页 Skill 选择」这类页面可以**完整开发、演示、写自动化测试**，
/// 不被后端进度卡住。
///
/// 切换到真实接口：把 `AppConfig.useMockData` 改成 `false`。
///
/// 注意：这里的字段结构与 `docs/DATABASE.md` 的表设计严格对齐，
/// 这样后端一落地，把 `fromJson` 接上就行，页面代码一行都不用改。
class MockData {
  const MockData._();

  /// 模拟网络延迟，让加载态在开发时真的能看见（否则一闪而过没法调样式）。
  static const Duration latency = Duration(milliseconds: 320);

  // ===========================================================================
  // Skill 创作线路
  // ===========================================================================

  /// 与 `docs/DATABASE.md` 里 `t_skill` 的初始化数据一致。
  static const List<SkillModel> skills = [
    SkillModel(
      id: 1,
      code: 'anime_v1',
      name: '二次元插画',
      type: SkillType.textToImage,
      scene: '头像 / 立绘 / 同人',
      description: '日系赛璐璐画风，线条干净、色彩通透，适合角色立绘与头像',
      provider: 'mock',
      modelName: 'sd-xl-anime',
      steps: 28,
      cfgScale: 7.5,
      width: 1024,
      height: 1024,
      promptPrefix: 'masterpiece, best quality, anime style, cel shading',
      negativePrompt: 'lowres, bad anatomy, extra fingers, watermark',
      usageCount: 12840,
      favoriteCount: 326,
      tags: ['二次元', '插画', '立绘'],
    ),
    SkillModel(
      id: 2,
      code: 'realistic_v1',
      name: '写实摄影',
      type: SkillType.textToImage,
      scene: '人像 / 风景 / 产品',
      description: '照片级真实感，光影层次丰富，适合商业人像与风光',
      provider: 'mock',
      modelName: 'sd-xl-real',
      steps: 30,
      cfgScale: 6.5,
      width: 1024,
      height: 1536,
      promptPrefix: 'photorealistic, 8k uhd, sharp focus, natural lighting',
      negativePrompt: 'cartoon, anime, painting, lowres, blurry',
      usageCount: 9260,
      favoriteCount: 251,
      tags: ['写实', '摄影', '人像'],
    ),
    SkillModel(
      id: 3,
      code: 'ecommerce_v1',
      name: '电商海报',
      type: SkillType.textToImage,
      scene: '商品主图 / 促销 Banner',
      description: '干净的纯色背景 + 商业布光，直接可用于商品主图',
      provider: 'mock',
      modelName: 'sd-xl-product',
      steps: 25,
      cfgScale: 7.0,
      width: 1024,
      height: 1024,
      promptPrefix:
          'product photography, clean background, studio lighting, commercial',
      negativePrompt: 'cluttered, messy, text, watermark, low quality',
      usageCount: 6180,
      favoriteCount: 178,
      tags: ['电商', '海报', '主图'],
    ),
    SkillModel(
      id: 4,
      code: 'guofeng_v1',
      name: '国风水墨',
      type: SkillType.textToImage,
      scene: '国潮 / 文创 / 插画',
      description: '水墨晕染 + 留白构图，适合国潮文创与东方美学题材',
      provider: 'mock',
      modelName: 'sd-xl-ink',
      steps: 26,
      cfgScale: 7.0,
      width: 1024,
      height: 1024,
      promptPrefix: 'chinese ink painting, traditional, rice paper texture',
      negativePrompt: 'western, oil painting, 3d render, lowres',
      usageCount: 3470,
      favoriteCount: 96,
      tags: ['国风', '水墨', '文创'],
    ),
    SkillModel(
      id: 5,
      code: 'motion_v1',
      name: '短视频运镜',
      type: SkillType.imageToVideo,
      scene: '产品展示 / 场景转场',
      description: '稳定的推拉摇移运镜，画面不崩坏，适合产品短视频',
      provider: 'mock',
      modelName: 'svd-xt',
      steps: 20,
      cfgScale: 6.0,
      width: 1024,
      height: 576,
      usageCount: 2150,
      favoriteCount: 84,
      tags: ['视频', '运镜', '产品'],
    ),
    SkillModel(
      id: 6,
      code: 'anime_motion_v1',
      name: '动漫动态漫',
      type: SkillType.imageToVideo,
      scene: '二次元短视频 / 动态壁纸',
      description: '让静态二次元插画动起来，适合动态壁纸与短视频',
      provider: 'mock',
      modelName: 'svd-anime',
      steps: 22,
      cfgScale: 6.5,
      width: 768,
      height: 768,
      usageCount: 1890,
      favoriteCount: 132,
      tags: ['视频', '二次元', '动态漫'],
    ),
  ];

  /// 首页只展示前 N 条线路（横滑列表不宜太长）。
  static List<SkillModel> get homeSkills => skills.take(6).toList();

  // ===========================================================================
  // 作品
  // ===========================================================================

  /// 最近生成的作品，时间逐条往前推，让「最近作品」看起来是真实的。
  static List<WorkModel> get works {
    final now = DateTime.now();
    return [
      WorkModel(
        id: 101,
        userId: 1,
        taskId: 9001,
        title: '赛博朋克少女',
        type: WorkType.image,
        resourceUrl: '',
        prompt: 'cyberpunk girl, neon city, rain, reflective street, cinematic',
        skillId: 1,
        skillName: '二次元插画',
        width: 1024,
        height: 1024,
        isPublic: true,
        likeCount: 42,
        viewCount: 318,
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      WorkModel(
        id: 102,
        userId: 1,
        taskId: 9002,
        title: '清晨咖啡馆',
        type: WorkType.image,
        resourceUrl: '',
        prompt: 'cozy cafe in the morning, sunlight through window, film grain',
        skillId: 2,
        skillName: '写实摄影',
        width: 1024,
        height: 1536,
        isPublic: true,
        likeCount: 67,
        viewCount: 502,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      WorkModel(
        id: 103,
        userId: 1,
        taskId: 9003,
        title: '香水产品短片',
        type: WorkType.video,
        resourceUrl: '',
        prompt: 'perfume bottle rotating, soft studio light, slow motion',
        skillId: 5,
        skillName: '短视频运镜',
        width: 1024,
        height: 576,
        duration: 8,
        isPublic: true,
        likeCount: 128,
        viewCount: 1043,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      WorkModel(
        id: 104,
        userId: 1,
        title: '春季新品主图',
        type: WorkType.image,
        resourceUrl: '',
        prompt: 'skincare product on pastel podium, spring campaign, soft shadow',
        skillId: 3,
        skillName: '电商海报',
        width: 1024,
        height: 1024,
        likeCount: 23,
        viewCount: 176,
        createdAt: now.subtract(const Duration(hours: 9)),
      ),
      WorkModel(
        id: 105,
        userId: 1,
        title: '远山如黛',
        type: WorkType.image,
        resourceUrl: '',
        prompt: 'misty mountains, chinese ink wash, minimal composition, blank space',
        skillId: 4,
        skillName: '国风水墨',
        width: 1024,
        height: 1024,
        isPublic: true,
        likeCount: 89,
        viewCount: 640,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      WorkModel(
        id: 106,
        userId: 1,
        title: '动态壁纸·星海',
        type: WorkType.video,
        resourceUrl: '',
        prompt: 'anime girl standing under starry sky, hair floating, loop',
        skillId: 6,
        skillName: '动漫动态漫',
        width: 768,
        height: 768,
        duration: 12,
        likeCount: 210,
        viewCount: 1876,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      WorkModel(
        id: 107,
        userId: 1,
        title: '机械蜂鸟',
        type: WorkType.image,
        resourceUrl: '',
        prompt: 'steampunk hummingbird, brass and copper, macro shot, intricate',
        skillId: 2,
        skillName: '写实摄影',
        width: 1024,
        height: 1024,
        likeCount: 55,
        viewCount: 401,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      WorkModel(
        id: 108,
        userId: 1,
        title: '校园日常',
        type: WorkType.image,
        resourceUrl: '',
        prompt: 'anime girl in school uniform, cherry blossom, warm afternoon',
        skillId: 1,
        skillName: '二次元插画',
        width: 1024,
        height: 1536,
        isPublic: true,
        likeCount: 176,
        viewCount: 1290,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }

  /// 首页「最近作品」横滑区展示前 N 条。
  static List<WorkModel> get recentWorks => works.take(6).toList();

  // ===========================================================================
  // 消息
  // ===========================================================================

  static List<NotificationModel> get notifications {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 1,
        title: '生成成功',
        content: '作品《赛博朋克少女》已生成完成，点击查看',
        type: 'TASK',
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      NotificationModel(
        id: 2,
        title: '任务失败',
        content: '《香水产品短片》生成失败：服务商超时，可在任务列表重试',
        type: 'TASK',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      NotificationModel(
        id: 3,
        title: '平台公告',
        content: '新增「动漫动态漫」创作线路，欢迎体验',
        type: 'SYSTEM',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  /// 未读消息数，用于顶部消息入口的红点角标。
  static int get unreadCount =>
      notifications.where((n) => !n.isRead).length;
}
