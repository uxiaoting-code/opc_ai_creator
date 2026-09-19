import 'package:flutter/material.dart';

import '../../core/router/route_names.dart';
import '../../widgets/scaffold_page.dart';

/// 页面 8：Prompt 知识库广场
///
/// 老师需求里的「知识库」：可检索、可收藏的提示词库。
class PromptLibraryPage extends StatelessWidget {
  const PromptLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      pageNumber: 8,
      title: 'Prompt 知识库',
      routePath: RouteNames.promptsPath,
      icon: Icons.menu_book_rounded,
      summary: '可检索、可收藏的提示词库，一键复制或直接用于创作',
      plannedFeatures: [
        '搜索框：按标题 / 标签 / 正文关键词检索（防抖处理）',
        '分类筛选：人物 / 风景 / 电商 / 二次元 / 建筑…',
        '热门标签云',
        '提示词卡片：标题、正文预览、标签、收藏数',
        '收藏 / 取消收藏 → POST /api/prompts/{id}/favorite',
        '「我的收藏」Tab（按用户维度查）',
        '一键复制到剪贴板（Clipboard，双端兼容）',
        '「用它创作」：跳到文生图页并自动填充提示词',
        '用户投稿自己的提示词',
      ],
    );
  }
}
