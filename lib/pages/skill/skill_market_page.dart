import 'package:flutter/material.dart';

import '../../core/router/route_names.dart';
import '../../widgets/scaffold_page.dart';

/// 页面 9：Skill 市场页
///
/// 老师需求里的「Skill 多线路」：把一整套生成参数（模型、采样器、
/// 步数、CFG、风格前缀、推荐尺寸…）打包成一个模板，用户切换线路即可换风格。
class SkillMarketPage extends StatelessWidget {
  const SkillMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      pageNumber: 9,
      title: 'Skill 市场',
      routePath: RouteNames.skillMarketPath,
      icon: Icons.dashboard_customize_rounded,
      summary: '多套生成参数模板（创作线路），切换即换风格',
      plannedFeatures: [
        '线路卡片列表：二次元 / 写实摄影 / 电商海报 / 国风水墨…',
        '每张卡片展示：封面样例图、名称、适用场景、调用次数',
        '线路详情底部弹窗：完整参数预览（模型、步数、CFG、尺寸）',
        '「用这条线路创作」→ 带 skillId 跳文生图 / 图生视频页',
        '收藏常用线路，置顶显示',
        '支持图片 + 视频两类线路的区分标识',
        '自定义线路（进阶）：基于现有线路微调参数另存为我的线路',
      ],
    );
  }
}
