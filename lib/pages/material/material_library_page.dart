import 'package:flutter/material.dart';

import '../../core/router/route_names.dart';
import '../../widgets/scaffold_page.dart';

/// 页面 7：素材库页
///
/// 用户上传管理参考素材（垫图、首帧图）。
/// 上传是 Web / Android 差异最大的地方，重点在 MediaUtils 里统一封装。
class MaterialLibraryPage extends StatelessWidget {
  const MaterialLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      pageNumber: 7,
      title: '素材库',
      routePath: RouteNames.materialsPath,
      icon: Icons.photo_library_rounded,
      summary: '上传、分类、管理创作时用到的参考素材图片',
      plannedFeatures: [
        '网格展示素材（三列，正方形裁切）',
        '上传入口：相册选择 / 拍照（image_picker，双端兼容）',
        '上传前压缩与体积校验，显示上传进度',
        '素材分组：全部 / 未分类 / 自定义分组',
        '素材重命名、加标签、删除',
        '点击素材 → 全屏预览 → 可直接用于创作',
        'Android 相册与存储权限申请（Web 端自动跳过）',
        '本地缓存已上传素材，弱网时也能看到缩略图',
      ],
    );
  }
}
