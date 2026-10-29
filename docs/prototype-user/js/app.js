/* ========== AI 电商创作 · Light Premium · 移动端预览交互 ========== */

// ------- 常量数据 -------
const SCENES = [
  { ico: '✂', name: 'AI抠图',      caption: '一键去除背景，保留商品主体',   route: 'cutout' },
  { ico: '◈', name: '商品宣传图',  caption: '上传商品，生成高级宣传图',     route: 'imageGen' },
  { ico: '◐', name: '数字人播报',  caption: '输入文案，生成口播视频',       route: 'digitalHuman' },
  { ico: '▣', name: '主图换背景',  caption: '替换场景，保持商品真实',       route: 'cutout' },
  { ico: '▤', name: '详情页长图',  caption: '一键生成电商详情页',           route: 'imageGen' },
  { ico: '♪', name: '音频配音',    caption: '多语言商品配音',               route: 'audioGen' },
  { ico: '◍', name: '模特上身',    caption: '虚拟模特试穿展示',             route: 'imageGen' },
  { ico: '文', name: '跨境翻译图',  caption: '主图多语言一键本地化',         route: 'imageGen' }
];

const SCENE_HOME = ['AI抠图','商品宣传图','数字人播报','主图换背景','详情页长图','音频配音'];

const WORKS = [
  { title: '春季新品香水', mode: '图片', shape: 'tall',  g: 'g1' },
  { title: '咖啡机宣传视频', mode: '视频', shape: 'short', g: 'g2' },
  { title: '首饰主图', mode: '图片', shape: 'short', g: 'g3' },
  { title: '服装模特图', mode: '图片', shape: 'tall',  g: 'g4' },
  { title: '护肤详情页', mode: '图片', shape: 'short', g: 'g5' },
  { title: '包包旋转展示', mode: '视频', shape: 'tall',  g: 'g6' }
];

const STYLE_CHIPS = ['纯白背景','场景图','模特上身','3D质感','国潮','极简'];
const VIDEO_CHIPS = ['商品旋转展示','模特走秀','场景环绕','开箱','口播背景'];
const VOICES = [
  { ico: '♀', name: '温柔女声' },
  { ico: '♂', name: '磁性男声' },
  { ico: '◐', name: '童声' },
  { ico: '文', name: '方言' },
  { ico: '✦', name: '播报腔' },
  { ico: '♪', name: '主播风' }
];
const LANGS = ['中文','English','日本語','Español','العربية','Français','Deutsch'];
const BG_PRESETS = [
  { key: 'white',  cls: 'white',  lbl: '纯白' },
  { key: 'black',  cls: 'black',  lbl: '纯黑' },
  { key: 'grad',   cls: 'grad',   lbl: '渐变' },
  { key: 'scene',  cls: 'scene',  lbl: '场景图' },
  { key: 'custom', cls: 'custom', lbl: '自定义', ico: '+' }
];

// ------- 多彩渐变 SVG 图标（参考花瓣风车风格）-------
let _svgUid = 0;
/** 返回内联 SVG 字符串；name: camera/photos/ref/settings/frames/mic/doc/wave */
function iconSVG(name, size = 18) {
  const uid = 'g' + (++_svgUid);
  const P = {
    coral:  ['#E8705F', '#F0956E'],
    amber:  ['#F5A623', '#F8C04A'],
    green:  ['#7FBE3C', '#A6D65E'],
    teal:   ['#2AA79B', '#4FC3B0'],
    blue:   ['#3F9FD4', '#63C0E8'],
    purple: ['#8F83C0', '#B4A8D8'],
    pink:   ['#CE6BA4', '#E18FBE'],
    yellow: ['#F2D024', '#F9E86A']
  };
  let defs = '', body = '';
  const addGrad = (key, c) => {
    const id = uid + key;
    defs += `<linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${c[0]}"/><stop offset="1" stop-color="${c[1]}"/></linearGradient>`;
    return id;
  };
  switch (name) {
    case 'camera': {
      const id = addGrad('a', P.coral);
      body = `<path d="M8.6 7.2l1.3-2a1.7 1.7 0 0 1 1.42-.8h1.36a1.7 1.7 0 0 1 1.42.8l1.3 2z" fill="url(#${id})"/>` +
        `<rect x="2.6" y="7" width="18.8" height="12.8" rx="3.6" fill="url(#${id})"/>` +
        `<circle cx="12" cy="13.3" r="3.7" fill="#fff" opacity="0.95"/><circle cx="12" cy="13.3" r="1.8" fill="url(#${id})"/>`;
      break;
    }
    case 'photos': {
      // 八瓣风车花（参考图样式）
      const cols = [P.amber, P.yellow, P.green, P.teal, P.blue, P.purple, P.pink, P.coral];
      cols.forEach((c, i) => {
        const id = addGrad('p' + i, c);
        body += `<g transform="rotate(${i * 45} 12 12)"><path d="M12 12.6 C 8.4 10.8, 8 5.8, 10.3 3.7 C 11.3 2.8, 12.7 2.8, 13.7 3.7 C 16 5.8, 15.6 10.8, 12 12.6 Z" fill="url(#${id})"/></g>`;
      });
      break;
    }
    case 'ref': {
      const id = addGrad('a', P.purple);
      body = `<rect x="6.2" y="6.2" width="11.6" height="11.6" rx="2.6" transform="rotate(45 12 12)" fill="url(#${id})"/>` +
        `<rect x="9.4" y="9.4" width="5.2" height="5.2" rx="1.4" transform="rotate(45 12 12)" fill="#fff" opacity="0.9"/>`;
      break;
    }
    case 'settings': {
      const id = addGrad('a', P.teal);
      body = `<rect x="3.5" y="6.2" width="17" height="2.4" rx="1.2" fill="url(#${id})"/>` +
        `<rect x="3.5" y="10.8" width="17" height="2.4" rx="1.2" fill="url(#${id})" opacity="0.75"/>` +
        `<rect x="3.5" y="15.4" width="17" height="2.4" rx="1.2" fill="url(#${id})" opacity="0.55"/>` +
        `<circle cx="9" cy="7.4" r="2.5" fill="#fff"/><circle cx="9" cy="7.4" r="1.5" fill="url(#${id})"/>` +
        `<circle cx="15" cy="12" r="2.5" fill="#fff"/><circle cx="15" cy="12" r="1.5" fill="url(#${id})"/>` +
        `<circle cx="8" cy="16.6" r="2.5" fill="#fff"/><circle cx="8" cy="16.6" r="1.5" fill="url(#${id})"/>`;
      break;
    }
    case 'frames': {
      const id = addGrad('a', P.blue);
      body = `<rect x="3" y="4" width="12" height="12" rx="3" fill="url(#${id})" opacity="0.85"/>` +
        `<rect x="9" y="8" width="12" height="12" rx="3" fill="url(#${id})"/>` +
        `<path d="M13.6 11.6l3.4 2.4-3.4 2.4z" fill="#fff" opacity="0.95"/>`;
      break;
    }
    case 'mic': {
      const id = addGrad('a', P.pink);
      body = `<rect x="9.2" y="3" width="5.6" height="10" rx="2.8" fill="url(#${id})"/>` +
        `<path d="M6.4 11.4a5.6 5.6 0 0 0 11.2 0" stroke="url(#${id})" stroke-width="2" fill="none" stroke-linecap="round"/>` +
        `<rect x="11" y="17" width="2" height="3.4" rx="1" fill="url(#${id})"/>` +
        `<rect x="8.4" y="20" width="7.2" height="2" rx="1" fill="url(#${id})"/>`;
      break;
    }
    case 'doc': {
      const id = addGrad('a', P.blue);
      body = `<path d="M6 3.4h8l4 4v13.2a1.6 1.6 0 0 1-1.6 1.6H6a1.6 1.6 0 0 1-1.6-1.6V5A1.6 1.6 0 0 1 6 3.4z" fill="url(#${id})"/>` +
        `<path d="M14 3.4l4 4h-4z" fill="#fff" opacity="0.6"/>` +
        `<rect x="7.4" y="11" width="9.2" height="1.8" rx="0.9" fill="#fff" opacity="0.9"/>` +
        `<rect x="7.4" y="14.6" width="6.6" height="1.8" rx="0.9" fill="#fff" opacity="0.75"/>`;
      break;
    }
    case 'wave': {
      const id = addGrad('a', P.green);
      body = `<rect x="4" y="9" width="2.6" height="6" rx="1.3" fill="url(#${id})"/>` +
        `<rect x="8.4" y="5.5" width="2.6" height="13" rx="1.3" fill="url(#${id})"/>` +
        `<rect x="12.8" y="8" width="2.6" height="8" rx="1.3" fill="url(#${id})"/>` +
        `<rect x="17.2" y="6.5" width="2.6" height="11" rx="1.3" fill="url(#${id})"/>`;
      break;
    }
  }
  return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg"><defs>${defs}</defs>${body}</svg>`;
}

// ------- 首页输入卡：三模式配置 -------
const MODE_ICO = { '图片': '◈', '视频': '▶', '音频': '♪' };
const MODE_KEYS = ['图片', '视频', '音频'];

const MODE_CONFIG = {
  '图片': {
    placeholder: '描述商品画面，如：白色背景，柔光，高级质感…',
    icons: [
      { svg: 'camera', title: '相机',   act: 'source' },
      { svg: 'photos', title: '相册',   act: 'toast' },
      { svg: 'ref',    title: '参考图', act: 'toast' },
      { svg: 'settings', title: '设置', act: 'toast' }
    ],
    credits: 2,
    btnText: '✦  开始生成',
    caption: '',
    refSlot: false,
    target: 'result',
    params: [
      { key: 'ratio',   label: '比例',   value: '1:1',  options: ['1:1', '3:4', '4:3', '9:16', '16:9'] },
      { key: 'count',   label: '数量',   value: '4张',  options: ['1张', '2张', '4张', '6张', '9张'] },
      { key: 'style',   label: '风格',   value: '纯白', options: ['纯白', '场景图', '模特上身', '3D质感', '极简'] },
      { key: 'quality', label: '清晰度', value: '高清', options: ['标清', '高清', '超清', '4K'] }
    ]
  },
  '视频': {
    placeholder: '描述视频内容与运镜，如：商品360°旋转展示…',
    icons: [
      { svg: 'camera', title: '相机',   act: 'toast' },
      { svg: 'photos', title: '相册',   act: 'addRef' },
      { svg: 'frames', title: '首尾帧', act: 'toast' },
      { svg: 'settings', title: '设置', act: 'toast' }
    ],
    credits: 8,
    btnText: '✦  生成视频',
    caption: '视频生成约需 60 秒，请耐心等待',
    refSlot: true,
    target: 'videoGen',
    params: [
      { key: 'duration', label: '时长',   value: '5s',    options: ['3s', '5s', '10s', '15s'] },
      { key: 'ratio',    label: '比例',   value: '9:16',  options: ['9:16', '16:9', '1:1', '3:4'] },
      { key: 'quality',  label: '清晰度', value: '1080p', options: ['720p', '1080p', '2K', '4K'] },
      { key: 'camera',   label: '运镜',   value: '自动',  options: ['自动', '固定', '环绕', '推拉', '摇移'] }
    ]
  },
  '音频': {
    placeholder: '输入要生成语音的文案，如：欢迎光临本店…',
    icons: [
      { svg: 'mic',  title: '麦克风', act: 'toast' },
      { svg: 'doc',  title: '文档',   act: 'toast' },
      { svg: 'wave', title: '音色库', act: 'toast' },
      { svg: 'settings', title: '设置', act: 'toast' }
    ],
    credits: 1,
    btnText: '✦  生成音频',
    caption: '生成后可一键配到数字人播报',
    refSlot: false,
    target: 'audioGen',
    params: [
      { key: 'voice',   label: '音色', value: '温柔女声', options: ['温柔女声', '磁性男声', '童声', '播报腔', '主播风'] },
      { key: 'lang',    label: '语言', value: '中文',     options: ['中文', 'English', '日本語', 'Español', 'العربية', 'Français'] },
      { key: 'speed',   label: '语速', value: '1.0x',     options: ['0.75x', '1.0x', '1.25x', '1.5x', '2.0x'] },
      { key: 'emotion', label: '情感', value: '自然',     options: ['自然', '活泼', '沉稳', '温柔', '激动'] }
    ]
  }
};

// ------- 模型目录与积分联动 -------
/** 用户当前算力积分余额 */
const USER_CREDITS = 1250;

/** 模型目录：group 决定在哪些模式下可选 */
const MODELS = [
  // 文生图
  { id: 'gpt4o',  name: 'GPT-4o',        supplier: 'OpenAI',       logo: '✦', cost: 2,  quality: 8,  tags: ['高画质', '中文优化', '快速'], recommended: true,  group: '文生图' },
  { id: 'dalle3', name: 'DALL·E 3',      supplier: 'OpenAI',       logo: '◈', cost: 3,  quality: 8,  tags: ['高画质'],            recommended: false, group: '文生图' },
  { id: 'mj6',    name: 'Midjourney v6', supplier: 'Midjourney',   logo: '◆', cost: 12, quality: 10, tags: ['顶级画质', '艺术感'], recommended: false, group: '文生图' },
  { id: 'wanx',   name: '通义万相',       supplier: '阿里云',        logo: '❋', cost: 1,  quality: 6,  tags: ['快速', '中文优化'],   recommended: false, group: '文生图' },
  // 图生图
  { id: 'sdxl',   name: 'SDXL Refiner',  supplier: 'Stability',    logo: '▣', cost: 2,  quality: 7,  tags: ['快速'],              recommended: false, group: '图生图' },
  { id: 'flux',   name: 'FLUX.1',        supplier: 'Black Forest', logo: '⬡', cost: 6,  quality: 9,  tags: ['高画质', '细节保留'], recommended: true,  group: '图生图' },
  { id: 'imagen', name: 'Gemini Imagen', supplier: 'Google',       logo: '◇', cost: 4,  quality: 8,  tags: ['中文优化'],          recommended: false, group: '图生图' },
  // 视频生成
  { id: 'sora',   name: 'Sora',          supplier: 'OpenAI',       logo: '▶', cost: 15, quality: 10, tags: ['顶级画质', '运镜'],   recommended: false, group: '视频生成' },
  { id: 'kling',  name: '可灵 Kling',    supplier: '快手',          logo: '▷', cost: 8,  quality: 9,  tags: ['中文优化', '快速'],   recommended: true,  group: '视频生成' },
  { id: 'runway', name: 'Runway Gen-3',  supplier: 'Runway',       logo: '▸', cost: 10, quality: 9,  tags: ['高画质'],            recommended: false, group: '视频生成' },
  { id: 'jimeng', name: '即梦 Jimeng',   supplier: '字节跳动',      logo: '◭', cost: 5,  quality: 7,  tags: ['快速', '中文优化'],   recommended: false, group: '视频生成' },
  // 音频生成
  { id: 'edgetts',name: 'Edge-TTS',      supplier: 'Microsoft',    logo: '♪', cost: 1,  quality: 7,  tags: ['快速', '中文优化'],   recommended: true,  group: '音频生成' },
  { id: 'eleven', name: 'ElevenLabs',    supplier: 'ElevenLabs',   logo: '♫', cost: 6,  quality: 9,  tags: ['高拟真'],            recommended: false, group: '音频生成' },
  { id: 'cosy',   name: 'CosyVoice',     supplier: '阿里云',        logo: '♬', cost: 2,  quality: 8,  tags: ['中文优化'],          recommended: false, group: '音频生成' }
];

/** 各模式可选的模型分组 */
const MODE_GROUPS = { '图片': ['文生图', '图生图'], '视频': ['视频生成'], '音频': ['音频生成'] };
/** 各模式当前选中模型 id */
const selectedModel = { '图片': 'gpt4o', '视频': 'kling', '音频': 'edgetts' };

function getModel(id) { return MODELS.find(m => m.id === id); }
/** 成本分层：cheap(≤3 sage) / premium(4-9 gold) / high(≥10 red) */
function costTier(cost) { return cost <= 3 ? 'cheap' : cost <= 9 ? 'premium' : 'high'; }
/** 标签优先级：卖点标签(0) 优先于 中文优化/快速 类(1) */
function tagRank(t) { return /高画质|顶级画质|艺术感|高拟真|细节保留|运镜/.test(t) ? 0 : 1; }

const SCREENS = [
  { key: 'courseCenter', ico: '🎓', label: '课程中心' },
  { key: 'courseDetail', ico: '▤', label: '课程详情' },
  { key: 'home',         ico: '✦', label: '首页 · 创作' },
  { key: 'imageGen',     ico: '◈', label: '图片生成' },
  { key: 'result',       ico: '▣', label: '生成结果' },
  { key: 'videoGen',     ico: '▶', label: '视频生成' },
  { key: 'audioGen',     ico: '♪', label: '音频生成' },
  { key: 'scenes',       ico: '▦', label: '场景列表' },
  { key: 'cutout',       ico: '✂', label: 'AI 抠图' },
  { key: 'digitalHuman', ico: '◐', label: '数字人播报' },
  { key: 'taskMarket',   ico: '◎', label: '接单大厅' },
  { key: 'taskDetail',   ico: '▤', label: '任务详情' },
  { key: 'submitStatus', ico: '✓', label: '提交状态' },
  { key: 'taskHistory',  ico: '☰', label: '接单记录' },
  { key: 'wallet',       ico: '◎', label: '我的荷包' },
  { key: 'withdraw',     ico: '↑', label: '提现' },
  { key: 'buyCredits',   ico: '✶', label: '购买积分' },
  { key: 'works',        ico: '◈', label: '作品' },
  { key: 'me',           ico: '◍', label: '我的' },
  { key: 'creatorLevel', ico: '↑', label: '创作者等级' },
  { key: 'expRules',     ico: '?', label: '经验规则' },
  { key: 'badgeWall',    ico: '🏅', label: '我的徽章' },
  { key: 'badgeDetail',  ico: '◆', label: '徽章详情' },
  { key: 'training',     ico: '🎓', label: '培训报名' },
  { key: 'regSuccess',   ico: '✓', label: '报名成功' },
  { key: 'myRegistrations', ico: '🎫', label: '我的报名' },
  { key: 'regDetail',    ico: '▤', label: '报名详情' },
  { key: 'assessResult', ico: '★', label: '考核结果' }
];

// ------- 工具函数 -------
const $ = (s, r = document) => r.querySelector(s);

/**
 * 创建 DOM 元素。
 * children 处理规则：
 *   - Node（Element / Text / Fragment）→ 直接 appendChild
 *   - string / number → 通过 createTextNode 插入（等价于 textContent 语义，无 HTML 注入）
 *   - null / undefined / false → 忽略
 * 禁止将元素对象拼接为字符串（会得到 "[object HTMLDivElement]"），
 * 如需将节点序列化为 HTML 字符串，请使用 node.outerHTML。
 */
const el = (tag, attrs = {}, children = []) => {
  const n = document.createElement(tag);
  Object.entries(attrs).forEach(([k, v]) => {
    if (v == null || v === false) return;
    if (k === 'class') n.className = v;
    else if (k === 'html') n.innerHTML = v;   // 仅用于静态可信内容
    else if (k === 'text') n.textContent = v; // 安全文本插入
    else if (k === 'style' && typeof v === 'object') Object.assign(n.style, v);
    else if (k.startsWith('on') && typeof v === 'function') n.addEventListener(k.slice(2).toLowerCase(), v);
    else n.setAttribute(k, String(v));
  });
  const list = Array.isArray(children) ? children : [children];
  list.forEach(c => {
    if (c == null || c === false) return;
    if (c instanceof Node) {
      n.appendChild(c);
    } else {
      // string / number → textContent 语义，避免 HTML 注入
      n.appendChild(document.createTextNode(String(c)));
    }
  });
  return n;
};

/** 将任意值安全地归约为 HTML 字符串（节点取 outerHTML，其他取转义后的文本） */
const toHTML = v => {
  if (v == null || v === false) return '';
  if (v instanceof Node) return v.outerHTML;
  return esc(v);
};
const esc = s => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

function toast(msg) {
  document.querySelectorAll('.toast').forEach(t => t.remove());
  const t = el('div', { class: 'toast' }, msg);
  document.body.appendChild(t);
  setTimeout(() => t.remove(), 1800);
}

/** 带图标的成功 toast（接单成功反馈专用，~800ms） */
function successToast(msg, duration = 800) {
  document.querySelectorAll('.toast').forEach(t => t.remove());
  const t = el('div', { class: 'toast success' }, [
    el('span', { class: 't-ico' }, '✓'),
    el('span', {}, msg)
  ]);
  document.body.appendChild(t);
  setTimeout(() => t.remove(), duration);
}

// ------- 全局任务状态 -------
/** 已接单任务集合（taskId → 接单时间戳） */
const acceptedTasks = new Map();
/** 已提交审核的任务集合 */
const submittedTasks = new Set();
/** 当前活跃的任务上下文（工作台自动预设参数用） */
let activeTaskContext = null;
/** 上下文条是否被用户手动收起 */
let contextBarHidden = false;

/**
 * 任务目录（接单大厅 / 任务详情 / 首页进度条共用同一份数据）
 * deadlineLevel: normal / urgent(<24h) / critical(<6h)；hoursLeft 用于紧急度排序
 */
const TASKS_DB = [
  { id: 1, title: '夏季新品女装商品主图', price: 28, bonus: 50, desc: '需要纯白背景商品图，突出面料质感和版型细节', source: '星辰电商', deadline: '2天', deadlineFull: '2026-09-18 23:59', deadlineLevel: 'normal', type: '商品宣传图', taken: 12, total: 50, ratio: '1:1', count: 4, style: '纯白背景', hoursLeft: 48, hasRef: false },
  { id: 2, title: '美妆产品旋转展示视频', price: 65, bonus: 120, desc: '15秒商品360°旋转展示，需要流畅自然的光影变化', source: '花漾美妆', deadline: '5小时', deadlineFull: '2026-09-16 21:00', deadlineLevel: 'critical', type: '视频生成', taken: 38, total: 50, ratio: '9:16', count: 1, style: '光影质感', hoursLeft: 5, hasRef: true },
  { id: 3, title: '智能家居场景宣传图', price: 45, bonus: 80, desc: '现代简约客厅场景，产品自然融入环境中', source: '智居科技', deadline: '1天', deadlineFull: '2026-09-17 23:59', deadlineLevel: 'urgent', type: '商品宣传图', taken: 22, total: 40, ratio: '3:4', count: 3, style: '场景植入', hoursLeft: 24, hasRef: false },
  { id: 4, title: '跨境电商英文商品配音', price: 35, bonus: 60, desc: '地道美式英语配音，时长约30秒，语速适中', source: 'GlobalTrade', deadline: '3天', deadlineFull: '2026-09-19 23:59', deadlineLevel: 'normal', type: '音频配音', taken: 8, total: 30, ratio: null, count: null, style: '美式英语', hoursLeft: 72, hasRef: false },
  { id: 5, title: '数字人口播带货视频', price: 120, bonus: 200, desc: '女性数字人，自然亲和风格，口播时长约60秒', source: '星辰电商', deadline: '4天', deadlineFull: '2026-09-20 23:59', deadlineLevel: 'normal', type: '数字人播报', taken: 5, total: 20, ratio: '9:16', count: 1, style: '自然亲和', hoursLeft: 96, hasRef: false },
  { id: 6, title: '食品类日本站主图套组', price: 55, bonus: 100, desc: '5张一组，包含主图+卖点图+场景图+尺寸图+促销图', source: '东瀛优品', deadline: '18小时', deadlineFull: '2026-09-17 10:00', deadlineLevel: 'urgent', type: '跨境主图', taken: 15, total: 25, ratio: '1:1', count: 5, style: '日本站', hoursLeft: 18, hasRef: true }
];
/** 任务详情页当前查看的任务 id */
let selectedTaskId = 1;
/** 任务类型 → 多彩图标名（弹层缩略图用） */
const TASK_TYPE_ICON = { '商品宣传图': 'photos', 'AI抠图': 'ref', '视频生成': 'frames', '音频配音': 'wave', '数字人播报': 'mic', '跨境主图': 'photos' };

// 演示：默认已接单一条任务，首页即可看到进度条
acceptedTasks.set(1, Date.now());

/** 进行中任务：已接单且未提交，按紧急度排序（最紧急在前） */
function getActiveTasks() {
  const rank = { critical: 0, urgent: 1, normal: 2 };
  return [...acceptedTasks.keys()]
    .filter(id => !submittedTasks.has(id))
    .map(id => TASKS_DB.find(t => t.id === id))
    .filter(Boolean)
    .sort((a, b) => (rank[a.deadlineLevel] - rank[b.deadlineLevel]) || (a.hoursLeft - b.hoursLeft));
}
/** 任务核心要求摘要：类型 · 比例 · 数量 */
function taskSummary(t) {
  return [t.type, t.ratio, t.count ? t.count + '张' : null].filter(Boolean).join(' · ');
}
/** 从首页进度条 / 多任务弹层继续某条任务：注入上下文并进入生图工作台 */
function continueTask(t) {
  activeTaskContext = t;
  contextBarHidden = false;
  navigate('imageGen');
}
/** 首页任务进度提示条（list[0] 为最紧急任务） */
function buildTaskBar(list) {
  const t = list[0];
  const multi = list.length > 1;
  return el('div', {
    class: 'task-bar ' + t.deadlineLevel,
    onClick: () => (multi ? openActiveTasksSheet(list) : continueTask(t))
  }, [
    el('span', { class: 'tb-dot' }),
    el('div', { class: 'tb-mid' }, [
      el('div', { class: 'tb-line1' }, '任务进行中 · ' + t.source),
      el('div', { class: 'tb-line2row' }, [
        el('span', { class: 'tb-line2' }, taskSummary(t)),
        el('span', { class: 'tb-countdown' }, '剩余 ' + t.deadline)
      ])
    ]),
    multi
      ? el('div', { class: 'tb-more' }, ['还有 ' + (list.length - 1) + ' 个任务 ', el('span', { class: 'tb-more-caret' }, '▸')])
      : el('div', { class: 'tb-cta' }, [el('span', {}, '继续创作'), el('span', { class: 'tb-cta-caret' }, '›')])
  ]);
}
/** 多任务底部弹层：列出全部进行中任务 */
function openActiveTasksSheet(list) {
  const body = $('#phoneBody');
  const close = () => { backdrop.remove(); sheet.remove(); };
  const backdrop = el('div', { class: 'sheet-backdrop', onClick: close });
  const sheet = el('div', { class: 'tasks-sheet' }, [
    el('div', { class: 'sheet-handle' }),
    el('div', { class: 'ats-head' }, [
      el('div', { class: 'ats-title' }, '进行中的任务'),
      el('div', { class: 'ats-count' }, list.length + ' 个')
    ])
  ]);
  const listWrap = el('div', { class: 'ats-list' });
  list.forEach(t => {
    const lvl = t.deadlineLevel;
    listWrap.appendChild(el('div', { class: 'ats-row', onClick: () => { close(); continueTask(t); } }, [
      el('div', { class: 'ats-thumb', html: iconSVG(TASK_TYPE_ICON[t.type] || 'photos', 22) }),
      el('div', { class: 'ats-info' }, [
        el('div', { class: 'ats-name' }, t.title),
        el('div', { class: 'ats-meta ' + lvl }, t.source + ' · 剩余 ' + t.deadline)
      ]),
      el('div', { class: 'ats-cta' }, '继续创作')
    ]));
  });
  sheet.appendChild(listWrap);
  sheet.appendChild(el('div', { class: 'ats-foot', onClick: () => { close(); navigate('taskHistory'); } }, '查看全部接单记录'));
  body.appendChild(backdrop);
  body.appendChild(sheet);
}

// ============ 创作者成长体系 ============
/** 创作者档案（演示数据） */
const CREATOR = {
  level: 5, exp: 2340, completed: 48, approvalRate: 98,
  badges: ['novice', 'steady', 'praise'] // 已获得徽章 id
};
/** 达到 Lv.N 所需累计经验（下标=等级） */
const LEVEL_EXP = [0, 0, 600, 1200, 1700, 2000, 3000, 4200, 5600, 7200, 9000];
const LEVEL_TITLES = { 1: '新手创作者', 2: '初级创作者', 3: '进阶创作者', 4: '熟练创作者', 5: '资深创作者', 6: '专业创作者', 7: '高级专家', 8: '资深专家', 9: '视觉大师', 10: '旗舰大师' };
/** 等级形制与金属色阶：Lv1-3 圆/sage・Lv4-6 六边形/gold・Lv7-9 盾形/深金・Lv10+ 星形/黑金 */
function levelShape(lv) { return lv >= 10 ? 'star' : lv >= 7 ? 'shield' : lv >= 4 ? 'hex' : 'circle'; }
function levelTier(lv) { return lv >= 10 ? 'blackgold' : lv >= 7 ? 'deepgold' : lv >= 4 ? 'gold' : 'sage'; }
const LEVEL_GRAD = {
  sage: ['#7C9A7E', '#A9C3A6'], gold: ['#C9A96E', '#E7D3A1'],
  deepgold: ['#B8860B', '#E6BE5A'], blackgold: ['#2C2823', '#C9A96E']
};
/** 等级徽章 SVG（形状随等级变化） */
function levelBadgeSVG(level, size = 72) {
  const uid = 'lb' + (++_svgUid);
  const g = LEVEL_GRAD[levelTier(level)];
  const shape = levelShape(level);
  let body;
  if (shape === 'circle') body = '<circle cx="36" cy="36" r="30"/>';
  else if (shape === 'hex') body = '<polygon points="36,5 62,20 62,52 36,67 10,52 10,20"/>';
  else if (shape === 'shield') body = '<path d="M36 5 L63 15 V37 C63 54 51 63 36 68 C21 63 9 54 9 37 V15 Z"/>';
  else body = '<polygon points="36,4 44,27 68,27 49,42 56,66 36,51 16,66 23,42 4,27 28,27"/>';
  return `<svg viewBox="0 0 72 72" width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">`
    + `<defs><linearGradient id="${uid}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${g[0]}"/><stop offset="1" stop-color="${g[1]}"/></linearGradient></defs>`
    + `<g fill="url(#${uid})">${body}</g>`
    + `<text x="36" y="45" text-anchor="middle" font-size="26" font-weight="700" fill="#fff" font-family="system-ui,sans-serif">${level}</text></svg>`;
}

/** 等级特权表（等级页展示用，严格按设计稿） */
const PRIVILEGES = [
  { band: 'Lv.1-3', label: '基础难度订单', range: '¥5-30', lv: 1 },
  { band: 'Lv.4-6', label: '进阶难度订单', range: '¥30-120', lv: 4 },
  { band: 'Lv.7-9', label: '专业难度订单', range: '¥120-500', lv: 7 },
  { band: 'Lv.10+', label: '旗舰难度订单', range: '¥500+', lv: 10 }
];
function privBandIndex(level) { return level >= 10 ? 3 : level >= 7 ? 2 : level >= 4 ? 1 : 0; }

/** 难度配置（接单大厅锁定逻辑）：需等级 + 需徽章 */
const DIFFICULTY = {
  '基础': { minLevel: 1, badge: null, cls: 'd-basic' },
  '进阶': { minLevel: 4, badge: null, cls: 'd-adv' },
  '专业': { minLevel: 6, badge: 'pro', cls: 'd-pro' },
  '旗舰': { minLevel: 9, badge: 'master', cls: 'd-flag' }
};
const DIFF_KEYS = ['基础', '进阶', '专业', '旗舰'];
/** 由价格推导任务难度 */
function taskDifficulty(t) {
  if (t.price >= 500) return '旗舰';
  if (t.price >= 120) return '专业';
  if (t.price >= 30) return '进阶';
  return '基础';
}
/** 任务解锁状态：{locked, reason:'level'|'badge', difficulty, needLevel, needBadge} */
function unlockState(t) {
  const d = taskDifficulty(t);
  const req = DIFFICULTY[d];
  const levelOK = CREATOR.level >= req.minLevel;
  const badgeOK = !req.badge || CREATOR.badges.includes(req.badge);
  if (levelOK && badgeOK) return { locked: false, difficulty: d };
  return { locked: true, reason: levelOK ? 'badge' : 'level', difficulty: d, needLevel: req.minLevel, needBadge: req.badge };
}

/** 徽章目录（12 枚） */
const BADGES = [
  { id: 'novice', name: '新手创作者', icon: '✦', tier: 'sage', date: '2026-03-01', cond: 'Lv.1 自动获得', abilities: ['可接基础难度订单 (¥5-30)'] },
  { id: 'steady', name: '稳定输出', icon: '◎', tier: 'sage', date: '2026-06-18', cond: '完成 20 单', abilities: ['订单列表优先展示'] },
  { id: 'praise', name: '好评如潮', icon: '♥', tier: 'gold', date: '2026-08-02', cond: '好评率 ≥95%', abilities: ['接单转化率提升'] },
  { id: 'pro', name: '专业认证', icon: '◆', tier: 'gold', date: null, cond: 'Lv.6 考核通过', abilities: ['可接专业难度订单 (¥120-500)', '可同时接 5 个订单 (原 3 个)', '订单优先推荐'] },
  { id: 'master', name: '大师认证', icon: '★', tier: 'blackgold', date: null, cond: 'Lv.9 考核通过', abilities: ['可接旗舰难度订单 (¥500+)', '专属客服通道'] },
  { id: 'multi', name: '多面手', icon: '▦', tier: 'sage', date: null, cond: '覆盖 5 种任务类型', abilities: ['跨类型订单推荐'] },
  { id: 'cross', name: '跨境专家', icon: '✈', tier: 'deepgold', date: null, cond: '完成 20 单跨境任务', abilities: ['跨境高单价订单优先'] },
  { id: 'dh', name: '数字人达人', icon: '◐', tier: 'deepgold', date: null, cond: '完成 30 单数字人播报', abilities: ['数字人专属订单'] },
  { id: 'speed', name: '闪电交付', icon: '⚡', tier: 'gold', date: null, cond: '平均交付 <2 小时', abilities: ['急单优先派发'] },
  { id: 'veteran', name: '百日坚守', icon: '◷', tier: 'sage', date: null, cond: '连续活跃 100 天', abilities: ['专属活动资格'] },
  { id: 'bigorder', name: '大单猎手', icon: '♦', tier: 'blackgold', date: null, cond: '完成 5 单旗舰订单', abilities: ['旗舰订单定向邀约'] },
  { id: 'mentor', name: '金牌导师', icon: '✚', tier: 'deepgold', date: null, cond: '辅导 10 位新人通过考核', abilities: ['导师佣金分成'] }
];
function getBadge(id) { return BADGES.find(b => b.id === id); }

/** 培训场次 */
const TRAINING = {
  targetLevel: 6, badgeId: 'pro', badgeName: '专业创作者',
  sessions: [
    { id: 'GZ-12', city: '广州', term: '第 12 期', date: '2026-10-12 ~ 10-13 (周六日)', addr: '广州市天河区 XX 大厦 3 楼', teacher: '陈老师', teacherTitle: '资深电商视觉设计师', enrolled: 37, quota: 40, fee: 0, deposit: true },
    { id: 'SZ-08', city: '深圳', term: '第 8 期', date: '2026-10-19 ~ 10-20 (周六日)', addr: '深圳市南山区 XX 中心 12 楼', teacher: '林老师', teacherTitle: '电商视觉总监', enrolled: 37, quota: 40, fee: 299, deposit: false },
    { id: 'HZ-05', city: '杭州', term: '第 5 期', date: '2026-10-26 ~ 10-27 (周六日)', addr: '杭州市西湖区 XX 园区 B 座', teacher: '苏老师', teacherTitle: '品牌视觉专家', enrolled: 40, quota: 40, fee: 299, deposit: false }
  ]
};
/** 我的报名（演示：一条已通过 + 一条待参加） */
let myRegistrations = [
  { code: 'GZ-09-016', city: '广州', term: '第 9 期', date: '2026-08-10 ~ 08-11 (周六日)', addr: '广州市天河区 XX 大厦 3 楼', teacher: '陈老师', status: 'passed', score: 88 },
  { code: 'SZ-08-028', city: '深圳', term: '第 8 期', date: '2026-10-19 ~ 10-20 (周六日)', addr: '深圳市南山区 XX 中心 12 楼', teacher: '林老师', status: 'pending' }
];
let selectedSessionId = null; // 培训页当前选中场次
let lastRegCode = null;       // 报名成功后用于展示凭证
let assessPass = true;        // 考核结果页演示态
let selectedBadgeId = 'pro';  // 徽章详情页当前徽章
let selectedRegCode = null;   // 报名详情页当前报名编号

/** 伪二维码 SVG（现场签到用） */
function qrSVG(size = 132) {
  let seed = 20260916;
  const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
  const N = 21, u = 4;
  const inFinder = (x, y) => (x < 7 && y < 7) || (x >= N - 7 && y < 7) || (x < 7 && y >= N - 7);
  let cells = '';
  for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
    if (inFinder(x, y)) continue;
    if (rnd() > 0.52) cells += `<rect x="${x * u}" y="${y * u}" width="${u}" height="${u}"/>`;
  }
  const finder = (ox, oy) => `<rect x="${ox}" y="${oy}" width="28" height="28" fill="#1C1C1E"/><rect x="${ox + 4}" y="${oy + 4}" width="20" height="20" fill="#fff"/><rect x="${ox + 8}" y="${oy + 8}" width="12" height="12" fill="#1C1C1E"/>`;
  return `<svg viewBox="0 0 84 84" width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg"><rect width="84" height="84" fill="#fff" rx="6"/><g fill="#1C1C1E">${cells}</g>${finder(0, 0)}${finder(56, 0)}${finder(0, 56)}</svg>`;
}
/** 报名状态 chip 配置 */
function regChip(r) {
  if (r.status === 'pending') return { cls: 'pending', txt: '待参加', medal: false };
  if (r.status === 'passed') return { cls: 'passed', txt: '考核通过', medal: true };
  if (r.status === 'failed') return { cls: 'failed', txt: '考核未通过', medal: false };
  return { cls: 'cancelled', txt: '已取消', medal: false };
}
/** 培训凭证卡（报名成功页 / 报名详情页共用） */
function ticketCardEl(reg) {
  return el('div', { class: 'section-card ticket-card' }, [
    el('div', { class: 'tk-head' }, [
      el('span', { class: 'sc-title', style: 'margin:0' }, '培训凭证'),
      el('span', { class: 'tk-save', onClick: () => toast('已保存到相册') }, '保存到相册')
    ]),
    el('div', { class: 'tk-qr', html: qrSVG(132) }),
    el('div', { class: 'tk-info' }, [
      el('div', { class: 'tk-row' }, [el('span', {}, '时间'), el('span', {}, reg.date)]),
      el('div', { class: 'tk-row' }, [el('span', {}, '地点'), el('span', {}, reg.addr)]),
      el('div', { class: 'tk-row' }, [el('span', {}, '讲师'), el('span', {}, reg.teacher)]),
      el('div', { class: 'tk-row code' }, [el('span', {}, '报名编号'), el('span', {}, reg.code)])
    ]),
    el('div', { class: 'tk-note' }, '请于培训当天出示此凭证签到')
  ]);
}
/** 考核通过：颁发专业徽章 + 升至 Lv.6（真实打通成长闭环） */
function applyAssessPass() {
  if (!CREATOR.badges.includes('pro')) {
    CREATOR.badges.push('pro');
    const pb = getBadge('pro'); if (pb) pb.date = '2026-09-16';
  }
  if (CREATOR.level < 6) CREATOR.level = 6;
  CREATOR.exp = Math.max(CREATOR.exp, LEVEL_EXP[6]);
}

// ============ 课程体系（首页课程化改造） ============
/** 主推课程 = 培训首个场次（广州第 12 期），报名计数与 myRegistrations 复用同一数据源 */
function featSession() { return TRAINING.sessions[0]; }

/** 课程富内容（详情/大纲/讲师/评价），与场次信息（城市/时间/名额）组合渲染 */
const COURSE_CONTENT = {
  title: '电商 AI 实战训练营',
  tags: ['线下', '2 天', '含考核'],
  intro: '2 天线下培训，通过考核解锁专业订单',
  highlights: [
    '系统掌握电商 AI 工具全流程',
    '通过考核获得「专业制作人」认证徽章',
    '解锁 L3 专业订单接单权限',
    '线下实操 + 讲师一对一点评'
  ],
  syllabus: [
    { day: 'Day 1', lessons: [
      { time: '09:00-12:00', topic: '电商视觉基础与构图', teacher: '陈老师', hours: 3,
        summary: '讲解电商主图的视觉逻辑、构图法则与色彩搭配，结合真实案例拆解高转化主图。',
        materials: ['讲义 · 构图九宫格与视觉动线', '视频 · 优秀主图案例拆解（38 分钟）', '案例库 · 20 套高转化主图模板'] },
      { time: '14:00-18:00', topic: 'AI 生图工具实战', teacher: '陈老师', hours: 4,
        summary: '主流 AI 生图工具 hands-on 实操，从提示词到成图的完整工作流。',
        materials: ['讲义 · 提示词工程速查手册', '视频 · 抠图 + 换背景实操（52 分钟）', '案例库 · 提示词模板 50 条'] }
    ]},
    { day: 'Day 2', lessons: [
      { time: '09:00-12:00', topic: '视频与音频生成技巧', teacher: '李老师', hours: 3,
        summary: '商品短视频与多语言配音生成，数字人口播脚本撰写要点。',
        materials: ['讲义 · 短视频分镜脚本模板', '视频 · 数字人口播实操（45 分钟）', '案例库 · 爆款短视频拆解 10 条'] },
      { time: '14:00-17:00', topic: '考核（笔试 + 实操）', teacher: '考官', hours: 3,
        summary: '笔试 30 分钟 + 实操 90 分钟，80 分及格，通过即获专业认证徽章。',
        materials: ['考核范围 · Day1-Day2 全部知识点', '样题 · 历年真题 3 套', '评分标准 · 实操评分细则'] }
    ]}
  ],
  teacherTitle: '资深电商视觉设计师',
  teacherBio: '10 年电商视觉设计经验，曾服务 50+ 头部品牌，主导多个百万级 GMV 视觉项目。',
  reviews: [
    { name: '林同学', avatar: '林', stars: 5, text: '两天干货满满，考核通过后接到了第一个专业订单！' },
    { name: '张同学', avatar: '张', stars: 5, text: '讲师一对一点评很到位，构图提升明显。' },
    { name: '王同学', avatar: '王', stars: 4, text: '实操环节很实用，节奏紧凑但收获大。' }
  ]
};

/** 线上课程（课程中心「线上课程」分类） */
const ONLINE_COURSES = [
  { id: 'OL-1', title: 'AI 商品图速成', cover: 'ol-a', duration: '3 小时 · 12 节', teacher: '陈老师', priceLabel: '免费', intro: '零基础快速上手 AI 生图，产出可用商品主图。' },
  { id: 'OL-2', title: '数字人播报实战', cover: 'ol-b', duration: '5 小时 · 18 节', teacher: '李老师', priceLabel: '200 积分', intro: '从脚本到成片，打造带货数字人口播视频。' },
  { id: 'OL-3', title: '跨境视觉本地化', cover: 'ol-c', duration: '8 小时 · 24 节', teacher: '苏老师', priceLabel: '免费', intro: '多语言主图与合规要点，出海视觉一键本地化。' }
];

/** 学习进度（已报名后展示，演示数据） */
const LEARNING = { done: 3, total: 8, next: 'AI 生图工具实战' };

/** 是否已报名某场次（未取消即视为已报名，用于解锁完整课程内容） */
function isEnrolled(sessId) {
  return myRegistrations.some(r => r.code.indexOf(sessId + '-') === 0 && r.status !== 'cancelled');
}
/** 取某场次的报名记录 */
function findReg(sessId) {
  return myRegistrations.find(r => r.code.indexOf(sessId + '-') === 0);
}
/** 距开课天数（解析场次日期起始 YYYY-MM-DD） */
function daysUntil(sess) {
  const start = (sess.date || '').slice(0, 10);
  const t = new Date(start + 'T00:00:00');
  if (isNaN(t.getTime())) return 0;
  const now = new Date(); now.setHours(0, 0, 0, 0);
  return Math.max(0, Math.round((t.getTime() - now.getTime()) / 86400000));
}
/** 由场次日期解析出「M月D日」 */
function shortDate(sess) {
  const m = /^\d{4}-(\d{2})-(\d{2})/.exec(sess.date || '');
  return m ? (parseInt(m[1], 10) + '月' + parseInt(m[2], 10) + '日') : sess.date;
}
/**
 * 首页课程 Banner 四态（针对主推场次）：
 *   open 未报名 / enrolled 已报名未开课 / failed 已结课未通过 / passed 已通过
 */
function courseBannerState() {
  const reg = findReg(featSession().id);
  if (reg) {
    if (reg.status === 'passed') return 'passed';
    if (reg.status === 'failed') return 'failed';
    if (reg.status === 'pending') return 'enrolled';
  }
  if (CREATOR.badges.includes('pro')) return 'passed';
  return 'open';
}
let bannerStateOverride = null; // 演示用：强制首页课程 Banner 状态
function effectiveBannerState() { return bannerStateOverride || courseBannerState(); }
/** 全局报名（课程详情/课程中心/首页 Banner 共用）：写入报名记录并跳转报名成功页 */
function registerCourse(sess) {
  const code = sess.id + '-' + String(sess.enrolled + 1).padStart(3, '0');
  lastRegCode = code;
  myRegistrations.unshift({ code, city: sess.city, term: sess.term, date: sess.date, addr: sess.addr, teacher: sess.teacher, status: 'pending' });
  sess.enrolled = Math.min(sess.quota, sess.enrolled + 1);
  successToast('报名成功', 700);
  setTimeout(() => navigate('regSuccess'), 380);
}

/** 首页课程 Banner（四态：open 未报名 / enrolled 已报名 / failed 未通过 / passed 已通过） */
function buildCourseBanner() {
  const sess = featSession();
  const state = effectiveBannerState();
  const remain = sess.quota - sess.enrolled;
  const goDetail = () => navigate('courseDetail');

  if (state === 'enrolled') {
    const d = daysUntil(sess);
    return el('div', { class: 'course-banner glass enrolled', onClick: goDetail }, [
      el('div', { class: 'cb-pattern' }),
      el('div', { class: 'cb-tag mine' }, '我的课程'),
      el('div', { class: 'cb-title' }, '已报名 · ' + sess.city + sess.term),
      el('div', { class: 'cb-countdown' }, ['距开课还有 ', el('b', {}, String(d)), ' 天']),
      el('div', { class: 'cb-actions' }, [
        el('button', { class: 'cb-btn', onClick: e => { e.stopPropagation(); const reg = findReg(sess.id) || myRegistrations.find(r => r.status === 'pending'); if (reg) { selectedRegCode = reg.code; navigate('regDetail'); } else navigate('myRegistrations'); } }, '查看凭证'),
        el('span', { class: 'cb-link', onClick: e => { e.stopPropagation(); goDetail(); } }, '课程详情')
      ])
    ]);
  }
  if (state === 'passed') {
    return el('div', { class: 'course-banner glass passed' }, [
      el('div', { class: 'cb-pattern' }),
      el('div', { class: 'cb-medal' }, '🏅'),
      el('div', { class: 'cb-title' }, '已获得「专业创作者」徽章'),
      el('div', { class: 'cb-sub' }, '专业难度订单已解锁，去接更高价值的单'),
      el('div', { class: 'cb-actions' }, [
        el('button', { class: 'cb-btn', onClick: () => switchTab('taskMarket') }, '去接单'),
        el('span', { class: 'cb-link', onClick: () => navigate('badgeWall') }, '我的徽章')
      ])
    ]);
  }
  if (state === 'failed') {
    return el('div', { class: 'course-banner glass failed', onClick: () => navigate('courseCenter') }, [
      el('div', { class: 'cb-pattern' }),
      el('div', { class: 'cb-tag failed' }, '考核未通过'),
      el('div', { class: 'cb-title' }, '本期考核未通过'),
      el('div', { class: 'cb-sub' }, '可免费重听下一期，再次冲击专业认证'),
      el('div', { class: 'cb-actions' }, [
        el('button', { class: 'cb-btn', onClick: e => { e.stopPropagation(); navigate('courseCenter'); } }, '报名下一期')
      ])
    ]);
  }
  return el('div', { class: 'course-banner glass open', onClick: goDetail }, [
    el('div', { class: 'cb-pattern' }),
    el('div', { class: 'cb-tag' }, '本期热招'),
    el('div', { class: 'cb-title' }, COURSE_CONTENT.title + ' · ' + sess.term),
    el('div', { class: 'cb-sub' }, COURSE_CONTENT.intro),
    el('div', { class: 'cb-meta' }, [
      el('span', { class: 'cb-loc' }, sess.city + ' · ' + shortDate(sess)),
      el('span', { class: 'cb-seat' + (remain < 5 ? ' amber' : '') }, remain < 5 ? ('仅剩 ' + remain + ' 席') : ('剩 ' + remain + ' 席'))
    ]),
    el('div', { class: 'cb-actions' }, [
      el('button', { class: 'cb-btn', onClick: e => { e.stopPropagation(); goDetail(); } }, '立即报名'),
      el('span', { class: 'cb-link', onClick: e => { e.stopPropagation(); goDetail(); } }, '了解详情')
    ])
  ]);
}

/** 首页学习进度卡（已报名时展示） */
function buildLearnCard() {
  const pct = Math.round(LEARNING.done / LEARNING.total * 100);
  return el('div', { class: 'section-card learn-card' }, [
    el('div', { class: 'lc-head' }, [
      el('span', { class: 'sc-title', style: 'margin:0' }, '我的学习'),
      el('span', { class: 'lc-all', onClick: () => navigate('courseDetail') }, '查看全部 ›')
    ]),
    el('div', { class: 'lc-body' }, [
      el('div', { class: 'lc-info' }, [
        el('div', { class: 'lc-course' }, COURSE_CONTENT.title),
        el('div', { class: 'lc-next' }, '下一节：' + LEARNING.next)
      ]),
      el('button', { class: 'lc-continue', onClick: () => navigate('courseDetail') }, '继续学习')
    ]),
    el('div', { class: 'lc-prog' }, [
      el('div', { class: 'progress-thin' }, [el('div', { class: 'pt-fill', style: 'width:' + pct + '%' })]),
      el('span', { class: 'lc-count' }, '已完成 ' + LEARNING.done + '/' + LEARNING.total + ' 节')
    ])
  ]);
}

/** 首页快捷入口（课程中心 / 我的报名 / 考核认证 / 接单大厅） */
function buildQuickEntries() {
  const pending = myRegistrations.filter(r => r.status === 'pending').length;
  const items = [
    { ico: '🎓', label: '课程中心', dot: false, onClick: () => navigate('courseCenter') },
    { ico: '🎫', label: '我的报名', dot: pending > 0, onClick: () => navigate('myRegistrations') },
    { ico: '★', label: '考核认证', dot: false, onClick: () => navigate('assessResult') },
    { ico: '◎', label: '接单大厅', dot: false, onClick: () => switchTab('taskMarket') }
  ];
  return el('div', { class: 'quick-entries' }, items.map(it =>
    el('div', { class: 'qe-item', onClick: it.onClick }, [
      el('div', { class: 'qe-icon' + (it.dot ? ' has-dot' : '') }, [el('span', { class: 'qe-glyph' }, it.ico), it.dot ? el('i', { class: 'qe-dot' }) : null]),
      el('div', { class: 'qe-label' }, it.label)
    ])
  ));
}

/** 课时详情底部弹层：报名前预览锁定（可预览不可完整获取），报名后解锁讲义/视频/案例 */
function openLessonSheet(lesson, enrolled, sess) {
  const body = $('#phoneBody');
  const close = () => { backdrop.remove(); sheet.remove(); };
  const backdrop = el('div', { class: 'sheet-backdrop', onClick: close });
  const sheet = el('div', { class: 'sheet lesson-sheet' });
  sheet.appendChild(el('div', { class: 'sheet-handle' }));
  sheet.appendChild(el('div', { class: 'ls-head' }, [
    el('div', { class: 'ls-time' }, lesson.time),
    el('div', { class: 'ls-topic' }, lesson.topic),
    el('div', { class: 'ls-meta' }, lesson.teacher + ' · ' + lesson.hours + ' 小时')
  ]));
  const matIcon = m => m.indexOf('视频') === 0 ? '▶' : m.indexOf('讲义') === 0 ? '📄' : m.indexOf('案例') === 0 ? '🗂' : '●';
  if (enrolled) {
    sheet.appendChild(el('div', { class: 'ls-summary' }, lesson.summary));
    sheet.appendChild(el('div', { class: 'ls-mat-title' }, '课程资料'));
    const mats = el('div', { class: 'ls-mats' });
    lesson.materials.forEach(m => {
      const isVideo = m.indexOf('视频') === 0, isDoc = m.indexOf('讲义') === 0;
      mats.appendChild(el('div', { class: 'ls-mat' }, [
        el('span', { class: 'ls-mat-ico' }, matIcon(m)),
        el('span', { class: 'ls-mat-txt' }, m),
        el('button', { class: 'ls-mat-btn', onClick: () => toast(isVideo ? '开始播放视频' : isDoc ? '讲义已下载' : '打开案例库') }, isVideo ? '播放' : isDoc ? '下载' : '查看')
      ]));
    });
    sheet.appendChild(mats);
  } else {
    sheet.appendChild(el('div', { class: 'ls-lock' }, [
      el('div', { class: 'ls-lock-ico' }, '🔒'),
      el('div', { class: 'ls-lock-txt' }, '报名后解锁本节完整内容'),
      el('div', { class: 'ls-lock-sub' }, '含讲义、实操视频与案例库')
    ]));
    const mats = el('div', { class: 'ls-mats blurred' });
    lesson.materials.forEach(m => mats.appendChild(el('div', { class: 'ls-mat' }, [
      el('span', { class: 'ls-mat-ico' }, '🔒'),
      el('span', { class: 'ls-mat-txt' }, m),
      el('button', { class: 'ls-mat-btn disabled' }, '锁定')
    ])));
    sheet.appendChild(mats);
    sheet.appendChild(el('button', { class: 'btn-gradient', style: 'width:100%;margin-top:14px', onClick: () => { close(); registerCourse(sess); } }, '立即报名解锁'));
  }
  body.appendChild(backdrop); body.appendChild(sheet);
}

/** 解锁条件底部弹层（接单大厅/任务详情「查看解锁条件」「去提升」使用） */
function openUnlockSheet(diff) {
  const req = DIFFICULTY[diff];
  const badge = req.badge ? getBadge(req.badge) : null;
  const levelOK = CREATOR.level >= req.minLevel;
  const badgeOK = !badge || CREATOR.badges.includes(badge.id);
  const body = $('#phoneBody');
  const close = () => { backdrop.remove(); sheet.remove(); };
  const backdrop = el('div', { class: 'sheet-backdrop', onClick: close });
  const sheet = el('div', { class: 'sheet unlock-sheet' }, [
    el('div', { class: 'sheet-handle' }),
    el('div', { class: 'us-ico' }, '🔒'),
    el('div', { class: 'us-title' }, '解锁「' + diff + '」难度订单'),
    el('div', { class: 'us-sub' }, '满足以下条件后即可接取该难度任务'),
    el('div', { class: 'us-req' }, [
      el('div', { class: 'us-req-row' }, [
        el('span', { class: 'us-k' }, '所需等级'),
        el('span', { class: 'us-v' + (levelOK ? ' ok' : '') }, levelOK ? ('Lv.' + req.minLevel + ' ✓') : ('Lv.' + req.minLevel + '（当前 Lv.' + CREATOR.level + '）'))
      ]),
      badge ? el('div', { class: 'us-req-row' }, [
        el('span', { class: 'us-k' }, '所需徽章'),
        el('span', { class: 'us-v' + (badgeOK ? ' ok' : '') }, badge.name + (badgeOK ? ' ✓' : ''))
      ]) : null
    ]),
    el('button', {
      class: 'btn-gradient',
      style: { width: '100%', marginTop: '16px' },
      onClick: () => { close(); navigate(levelOK ? 'training' : 'creatorLevel'); }
    }, '去提升')
  ]);
  body.appendChild(backdrop);
  body.appendChild(sheet);
}

/**
 * 接单确认底部弹层（轻量非全屏）
 * opts: { task, onConfirm, unavailable, unavailableReason }
 *   unavailable=true 时展示“名额已满/已截止”分支
 */
function openConfirmSheet(opts) {
  const body = $('#phoneBody');
  const { task, onConfirm, unavailable = false, unavailableReason = '' } = opts;

  const close = () => { backdrop.remove(); sheet.remove(); };
  const backdrop = el('div', { class: 'confirm-backdrop', onClick: close });
  const sheet = el('div', { class: 'confirm-sheet' }, [
    el('div', { class: 'cs-handle' }),
    el('div', { class: 'cs-title' }, unavailable ? '无法接单' : '确认接取任务？'),
    el('div', { class: 'cs-task' }, [
      el('div', { class: 'cs-thumb' }, '🖼'),
      el('div', { class: 'cs-info' }, [
        el('div', { class: 'cs-name' }, task.title),
        el('div', { class: 'cs-reward' }, [
          el('span', { class: 'cash' }, '¥' + task.price),
          el('span', { style: 'color:var(--text-muted)' }, '+'),
          el('span', { class: 'bonus' }, task.bonus + ' 积分')
        ])
      ])
    ])
  ]);

  if (unavailable) {
    sheet.appendChild(el('div', { class: 'cs-warn' }, unavailableReason || '该任务已满员/已截止'));
    sheet.appendChild(el('button', { class: 'cs-btn', onClick: () => { close(); switchTab('taskMarket'); } }, '看看其他任务'));
  } else {
    sheet.appendChild(el('div', { class: 'cs-note' }, '接单后请在截止时间前提交作品'));
    sheet.appendChild(el('button', {
      class: 'cs-btn',
      onClick: () => { close(); onConfirm && onConfirm(); }
    }, '确认接单并去创作'));
    sheet.appendChild(el('button', { class: 'cs-btn secondary', onClick: close }, '再想想'));
  }

  body.appendChild(backdrop);
  body.appendChild(sheet);
}

/** 查看任务完整要求弹层（上下文条“查看要求”使用） */
function openTaskReqSheet(task) {
  openSheet('任务完整要求', [
    { ico: '◈', label: '任务：' + task.title },
    { ico: '⚖', label: '比例：' + task.ratio + '　张数：' + task.count + ' 张' },
    { ico: '✦', label: '风格：' + task.style },
    { ico: '🕐', label: '截止：' + task.deadlineFull + '　剩余 ' + task.deadline },
    { ico: '◎', label: '发布方：' + task.source + '　奖励 ¥' + task.price + ' + ' + task.bonus + ' 积分' }
  ]);
}

/** 在 phone-body 内弹出底部 sheet */
function openSheet(title, items) {
  const body = $('#phoneBody');
  const backdrop = el('div', { class: 'sheet-backdrop', onClick: close });
  const sheet = el('div', { class: 'sheet' }, [
    el('div', { class: 'sheet-handle' }),
    el('div', { class: 'sheet-title' }, title)
  ]);
  items.forEach(it => {
    sheet.appendChild(el('div', { class: 'sheet-item', onClick: () => { close(); it.onClick && it.onClick(); } }, [
      el('span', { class: 'ico' }, it.ico),
      el('span', {}, it.label)
    ]));
  });
  body.appendChild(backdrop);
  body.appendChild(sheet);
  function close() { backdrop.remove(); sheet.remove(); }
}

/**
 * 模型选择底部弹层（核心新增组件）
 * mode: 当前模式；onPick(modelId): 选中回调
 * 内含：排序 tabs / 按类型分组 / 模型卡片 / 空态 / 赚积分入口
 */
function openModelSheet(mode, onPick) {
  const body = $('#phoneBody');
  let sortKey = 'rec';
  const SORTS = [
    { k: 'rec',     lbl: '推荐' },
    { k: 'cheap',   lbl: '最省积分' },
    { k: 'quality', lbl: '最高画质' }
  ];

  const close = () => { backdrop.remove(); sheet.remove(); };
  const backdrop = el('div', { class: 'sheet-backdrop', onClick: close });
  const sheet = el('div', { class: 'model-sheet' }, [
    el('div', { class: 'sheet-handle' }),
    el('div', { class: 'ms-head' }, [
      el('div', { class: 'ms-title' }, '选择模型'),
      el('div', { class: 'ms-mode-chip' }, mode + '模式')
    ])
  ]);
  const sortRow = el('div', { class: 'ms-sort' });
  const listWrap = el('div', { class: 'ms-list' });
  sheet.appendChild(sortRow);
  sheet.appendChild(listWrap);
  sheet.appendChild(el('div', { class: 'ms-foot' }, [
    el('span', {}, '积分不够？'),
    el('span', { class: 'ms-link', onClick: () => { close(); switchTab('taskMarket'); } }, '去赚积分 →')
  ]));

  function renderSort() {
    sortRow.innerHTML = '';
    SORTS.forEach(so => {
      sortRow.appendChild(el('button', {
        class: 'ms-sort-tab' + (sortKey === so.k ? ' active' : ''),
        onClick: () => { sortKey = so.k; renderSort(); renderList(); }
      }, [ el('span', {}, so.lbl), el('span', { class: 'caret' }, '▾') ]));
    });
  }

  function renderList() {
    listWrap.innerHTML = '';
    const groups = MODE_GROUPS[mode] || [];
    let any = false;
    groups.forEach(g => {
      let items = MODELS.filter(m => m.group === g);
      if (!items.length) return;
      any = true;
      if (sortKey === 'cheap') items = items.slice().sort((a, b) => a.cost - b.cost);
      else if (sortKey === 'quality') items = items.slice().sort((a, b) => b.quality - a.quality);
      else items = items.slice().sort((a, b) => (b.recommended ? 1 : 0) - (a.recommended ? 1 : 0));
      listWrap.appendChild(el('div', { class: 'ms-group' }, g));
      items.forEach(m => {
        const sel = selectedModel[mode] === m.id;
        const tier = costTier(m.cost);
        // 标签排序：卖点标签优先，中文优化/快速类其次
        const ordered = m.tags.slice().sort((a, b) => tagRank(a) - tagRank(b));
        const card = el('div', {
          class: 'ms-card' + (sel ? ' selected' : '') + (m.recommended ? ' has-rec' : '') + (ordered.length >= 3 ? ' tall' : ''),
          onClick: () => { close(); onPick && onPick(m.id); }
        }, [
          // Column 1 — 模型信息
          el('div', { class: 'ms-col1' }, [
            el('div', { class: 'ms-logo' }, m.logo),
            el('div', { class: 'ms-info' }, [
              el('div', { class: 'ms-name' }, m.name),
              el('div', { class: 'ms-sup' }, m.supplier)
            ])
          ]),
          // Column 2 — 能力标签（固定左起始）
          el('div', { class: 'ms-col2' }, ordered.map(t => el('span', { class: 'ms-tag' }, t))),
          // Column 3 — 积分（固定右对齐）
          el('div', { class: 'ms-col3 ' + tier }, [
            el('span', { class: 'ms-cost-num' }, String(m.cost)),
            el('span', { class: 'ms-cost-unit' }, '积分')
          ])
        ]);
        if (m.recommended) card.appendChild(el('div', { class: 'ms-rec' }, '推荐'));
        listWrap.appendChild(card);
      });
    });
    if (!any) listWrap.appendChild(el('div', { class: 'ms-empty' }, '当前模式暂无可用模型'));
  }

  renderSort();
  renderList();
  body.appendChild(backdrop);
  body.appendChild(sheet);
}

// ------- 顶栏组件 -------
/**
 * 顶栏：返回按钮根据导航栈条件性显示
 * opts: { rightIco, onRight, rightToast, forceBack }
 *   - forceBack=true: 即使栈为空也强制显示返回按钮（子屏默认行为）
 *   - forceBack=false/undefined: 栈为空时隐藏返回（用于 Tab 根屏可作为子路由进入的情况）
 */
function topBar(title, opts = {}) {
  const showBack = opts.forceBack !== false && (canGoBack() || opts.forceBack === true);
  const leftSlot = showBack
    ? el('div', { class: 'back', title: '返回', onClick: () => goBack() }, '←')
    : el('div', { style: 'width:36px' });
  const rightIco = opts.rightIco || '🕐';
  const rightAction = opts.onRight || (() => toast(opts.rightToast || '历史记录'));
  return el('div', { class: 'top-bar' }, [
    leftSlot,
    el('div', { class: 'title' }, title),
    el('div', { class: 'act', onClick: rightAction }, rightIco)
  ]);
}

// ------- 屏幕渲染器 -------
const Renderers = {

  /* ========== 首页 · 创作 ========== */
  home() {
    const s = el('div', { class: 'screen' });
    let mode = '图片';
    let videoRefAdded = false;
    let promptText = '';
    // 每模式参数状态（跨切换记忆用户修改，def 记录默认值用于“已修改”高亮）
    const paramState = {};
    MODE_KEYS.forEach(m => {
      paramState[m] = MODE_CONFIG[m].params.map(p => ({ ...p, def: p.value }));
    });

    // 顶部问候 + 等级徽章
    s.appendChild(el('div', { class: 'home-header' }, [
      el('div', {}, [
        el('div', { class: 'greeting-sub' }, '晚上好，来点灵感'),
        el('div', { class: 'greeting-main' }, '开始创作')
      ]),
      el('div', { class: 'hh-right' }, [
        el('div', { class: 'level-pill', title: '我的等级', onClick: () => navigate('creatorLevel') }, 'L' + CREATOR.level),
        el('div', { class: 'avatar' }, 'K')
      ])
    ]));

    // NEW：课程 Banner（首页课程化核心，随报名状态四态切换）
    s.appendChild(buildCourseBanner());

    // NEW：学习进度（已报名才显示）
    const bState = effectiveBannerState();
    if (bState === 'enrolled' || bState === 'passed') s.appendChild(buildLearnCard());

    // NEW：快捷入口（4 个）
    s.appendChild(buildQuickEntries());

    // 进行中任务（底部固定提示条使用）
    const activeTasks = getActiveTasks();

    // Hero 卡
    const hero = el('div', { class: 'hero-card glass' });

    // 模式切换行（带滑动指示器 thumb）
    const modeRow = el('div', { class: 'mode-row' });
    const thumb = el('div', { class: 'mode-thumb' });
    modeRow.appendChild(thumb);
    const pills = [];
    MODE_KEYS.forEach((m, idx) => {
      const pill = el('button', {
        class: 'mode-pill' + (m === mode ? ' active' : ''),
        onClick: () => switchMode(idx)
      }, [ el('span', { class: 'mp-ico' }, MODE_ICO[m]), el('span', {}, m) ]);
      pills.push(pill);
      modeRow.appendChild(pill);
    });
    hero.appendChild(modeRow);

    // 动态内容容器（模式切换时整体交叉淡入）
    const content = el('div', { class: 'mode-content' });
    hero.appendChild(content);

    // --- 图标动作映射 ---
    function iconAction(act, title) {
      if (act === 'source') return () => openSheet('选择来源', [
        { ico: '📷', label: '拍照', onClick: () => toast('打开相机') },
        { ico: '🖼', label: '相册', onClick: () => toast('打开相册') },
        { ico: '📁', label: '文件', onClick: () => toast('打开文件') }
      ]);
      if (act === 'addRef') return () => { videoRefAdded = true; buildContent(); };
      return () => toast(title);
    }

    // --- 自动增高文本域（最多 4 行 ≈ 96px）---
    function autoGrow(ta) {
      const grow = () => {
        promptText = ta.value;
        ta.style.height = 'auto';
        ta.style.height = Math.min(ta.scrollHeight, 96) + 'px';
      };
      ta.addEventListener('input', grow);
      ta.value = promptText;
      requestAnimationFrame(grow);
    }

    // --- 视频首帧槽（可选）---
    function buildRefSlot() {
      if (videoRefAdded) {
        return el('div', { class: 'ref-frame filled' }, [
          el('div', { class: 'ref-thumb', html: iconSVG('photos', 20) }),
          el('div', { class: 'ref-label' }, '首帧图.jpg'),
          el('div', { class: 'ref-remove', title: '移除', onClick: () => { videoRefAdded = false; buildContent(); } }, '×')
        ]);
      }
      return el('div', { class: 'ref-frame', onClick: () => { videoRefAdded = true; buildContent(); } }, [
        el('span', { class: 'rf-ico', html: iconSVG('photos', 18) }),
        el('span', { class: 'rf-txt' }, '添加首帧图（可选，用于图生视频）')
      ]);
    }

    // --- 参数快捷栏 ---
    function buildParamRow() {
      const row = el('div', { class: 'param-quick-row' });
      // 模型 pill（最前，特殊样式，点击开模型选择弹层）
      const cur = getModel(selectedModel[mode]);
      row.appendChild(el('button', {
        class: 'param-quick model-pill' + (costTier(cur.cost) !== 'cheap' ? ' premium' : ''),
        onClick: () => openModelSheet(mode, id => { selectedModel[mode] = id; buildContent(); })
      }, [
        el('span', { class: 'pq-logo' }, cur.logo),
        el('span', { class: 'pq-label' }, '模型'),
        el('span', { class: 'pq-value' }, cur.name),
        el('span', { class: 'pq-caret' }, '▾')
      ]));
      paramState[mode].forEach((p, i) => {
        const changed = p.value !== p.def;
        row.appendChild(el('button', {
          class: 'param-quick' + (changed ? ' changed' : ''),
          style: { animationDelay: ((i + 1) * 0.045) + 's' },
          onClick: () => openSheet('选择' + p.label, p.options.map(opt => ({
            ico: opt === p.value ? '✓' : '·',
            label: opt,
            onClick: () => { p.value = opt; buildContent(); }
          })))
        }, [
          el('span', { class: 'pq-label' }, p.label),
          el('span', { class: 'pq-value' }, p.value),
          el('span', { class: 'pq-caret' }, '▾')
        ]));
      });
      return row;
    }

    // --- 组装当前模式的动态内容 ---
    function buildContent() {
      const cfg = MODE_CONFIG[mode];
      content.innerHTML = '';
      content.classList.remove('swap');
      void content.offsetWidth; // 强制回流以重启动画
      content.classList.add('swap');

      // 输入区（frosted box：文本域 + 可选首帧槽 + 分隔线/图标行）
      const area = el('div', { class: 'prompt-area' });
      const ta = el('textarea', { class: 'prompt-ta', placeholder: cfg.placeholder });
      area.appendChild(ta);
      if (cfg.refSlot) area.appendChild(buildRefSlot());
      const actions = el('div', { class: 'prompt-actions' });
      cfg.icons.forEach(ic => {
        actions.appendChild(el('div', { class: 'icon-btn', title: ic.title, onClick: iconAction(ic.act, ic.title), html: iconSVG(ic.svg, 19) }));
      });
      const m = getModel(selectedModel[mode]);
      const tier = costTier(m.cost);
      const insufficient = m.cost > USER_CREDITS;
      actions.appendChild(el('div', { class: 'prompt-hint' }, '预计消耗 ' + m.cost + ' 积分'));
      area.appendChild(actions);
      content.appendChild(area);
      autoGrow(ta);

      // 参数快捷栏（模型 pill 最前 + 其余参数）
      content.appendChild(buildParamRow());

      // 生成按钮 + 动态积分文案（模型联动）
      const genArea = el('div', { class: 'gen-area' });
      const btnChildren = [el('span', { class: 'gb-text' }, cfg.btnText)];
      if (insufficient) btnChildren.push(el('span', { class: 'gb-lack' }, '积分不足'));
      genArea.appendChild(el('button', {
        class: 'gen-btn' + (insufficient ? ' disabled' : ''),
        onClick: () => { if (insufficient) { toast('积分不足，先去赚积分吧'); return; } navigate(cfg.target); }
      }, btnChildren));
      const cap = el('div', { class: 'gen-caption' + (insufficient ? ' insufficient' : tier !== 'cheap' ? ' premium' : '') });
      if (insufficient) {
        cap.appendChild(el('span', {}, '积分不足（当前 ' + USER_CREDITS.toLocaleString() + '）· '));
        cap.appendChild(el('span', { class: 'cap-link', onClick: () => navigate('buyCredits') }, '去充值 →'));
      } else {
        if (tier === 'high') cap.appendChild(el('span', { class: 'cap-spark' }, '✦'));
        cap.appendChild(el('span', {}, '预计消耗 ' + m.cost + ' 积分 · ' + m.name));
      }
      genArea.appendChild(cap);
      if (cfg.caption) genArea.appendChild(el('div', { class: 'gen-caption sub' }, cfg.caption));
      content.appendChild(genArea);
    }

    // --- 模式切换：滑块位移 + 内容交叉淡入 ---
    function switchMode(idx) {
      const m = MODE_KEYS[idx];
      if (m === mode) return;
      mode = m;
      pills.forEach((p, i) => p.classList.toggle('active', i === idx));
      thumb.style.transform = 'translateX(' + (idx * 100) + '%)';
      buildContent();
    }

    buildContent();
    s.appendChild(hero);

    // 创作工具（原「电商场景」，标题更清晰）
    s.appendChild(el('div', { class: 'section-title' }, [
      el('span', {}, '创作工具'),
      el('span', { class: 'more', onClick: () => navigate('scenes') }, '查看全部 ›')
    ]));
    const scroll = el('div', { class: 'scene-scroll' });
    SCENE_HOME.forEach(name => {
      const sc = SCENES.find(x => x.name === name);
      scroll.appendChild(el('div', { class: 'scene-card', onClick: () => navigate(sc.route) }, [
        el('div', { class: 'ico' }, sc.ico),
        el('div', { class: 'name' }, sc.name)
      ]));
    });
    s.appendChild(scroll);

    // 最近作品
    s.appendChild(el('div', { class: 'section-title' }, [
      el('span', {}, '最近作品'),
      el('span', { class: 'more', onClick: () => navigate('works') }, '全部 ›')
    ]));
    const grid = el('div', { class: 'works-grid' });
    WORKS.slice(0, 4).forEach(w => {
      grid.appendChild(el('div', { class: 'work-item ' + w.shape, onClick: () => navigate('result') }, [
        el('div', { class: 'work-thumb ' + w.g }),
        el('div', { class: 'work-badge' + (w.mode === '视频' ? ' video' : '') }, w.mode)
      ]));
    });
    s.appendChild(grid);

    // 演示：课程 Banner 四态切换（原型辅助，便于查看不同报名状态下的首页）
    const demoRow = el('div', { class: 'demo-row' }, [el('span', { class: 'demo-label' }, '演示 Banner')]);
    [['open', '未报名'], ['enrolled', '已报名'], ['failed', '未通过'], ['passed', '已通过']].forEach(pair => {
      demoRow.appendChild(el('button', {
        class: 'demo-btn' + (effectiveBannerState() === pair[0] ? ' active' : ''),
        onClick: () => { bannerStateOverride = (bannerStateOverride === pair[0] ? null : pair[0]); navigate('home', { replace: true }); }
      }, pair[1]));
    });
    s.appendChild(demoRow);

    // NEW：底部固定任务提示条（有进行中任务才显示）
    if (activeTasks.length) {
      const tb = buildTaskBar(activeTasks);
      tb.classList.add('bottom');
      s.appendChild(tb);
    }

    return s;
  },

  /* ========== 图片生成 ========== */
  imageGen() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('图片生成', { forceBack: true }));

    // 任务上下文：若从“去创作”进入，则预设参数
    const ctx = activeTaskContext;
    const taskMode = !!ctx && !contextBarHidden;

    let uploaded = taskMode && !!ctx.hasRef;
    let selectedStyle = taskMode ? ctx.style : '纯白背景';
    let selectedRatio = taskMode ? ctx.ratio : '1:1';
    let selectedCount = taskMode ? ctx.count : 4;

    // 任务上下文条（仅任务模式且未收起时显示）
    if (ctx && !contextBarHidden) {
      s.appendChild(el('div', { class: 'task-context-bar' }, [
        el('div', { class: 'tcb-ico' }, '◎'),
        el('div', { class: 'tcb-mid' }, [
          el('div', { class: 'tcb-title' }, '任务：' + ctx.source + ' · ' + ctx.type),
          el('div', { class: 'tcb-reqs' }, ctx.ratio + ' · ' + ctx.count + '张 · ' + ctx.style)
        ]),
        el('div', { class: 'tcb-view', onClick: () => openTaskReqSheet(ctx) }, '查看要求'),
        el('div', { class: 'tcb-close', title: '收起上下文条', onClick: () => { contextBarHidden = true; navigate('imageGen', { replace: true }); } }, '×')
      ]));
    } else if (ctx && contextBarHidden) {
      // 已收起：展示一个轻量恢复条，方便用户重新开启
      s.appendChild(el('div', {
        style: 'display:flex;align-items:center;gap:8px;padding:8px 12px;margin-bottom:12px;border-radius:12px;background:rgba(124,154,126,0.08);font-size:12px;color:var(--sage);cursor:pointer',
        onClick: () => { contextBarHidden = false; navigate('imageGen', { replace: true }); }
      }, [
        el('span', {}, '◎'),
        el('span', { style: 'flex:1' }, '任务模式：' + ctx.title),
        el('span', { style: 'font-weight:600' }, '重新展开 ›')
      ]));
    }

    const container = el('div');
    s.appendChild(container);

    function renderUpload() {
      container.innerHTML = '';
      if (uploaded) {
        container.appendChild(el('div', { class: 'ref-card' }, [
          el('button', { class: 'remove', onClick: () => { uploaded = false; renderUpload(); } }, '×'),
          el('button', { class: 'retake', onClick: () => toast('重拍') }, '↻ 重拍')
        ]));
      } else {
        container.appendChild(el('div', { class: 'upload-area', onClick: () => openSheet('选择来源', [
          { ico: '📷', label: '拍照', onClick: () => { uploaded = true; renderUpload(); } },
          { ico: '🖼', label: '相册', onClick: () => { uploaded = true; renderUpload(); } },
          { ico: '📁', label: '文件', onClick: () => { uploaded = true; renderUpload(); } }
        ]) }, [
          el('div', { class: 'ico' }, '📷'),
          el('div', { class: 'txt' }, taskMode ? '上传商品参考图（任务推荐）' : '拍照或上传商品图'),
          el('div', { class: 'sub' }, '支持 JPG / PNG，最大 20MB')
        ]));
      }
    }
    renderUpload();

    container.appendChild(el('textarea', {
      class: 'soft-textarea',
      placeholder: taskMode
        ? '描述商品，或直接使用任务参考图…'
        : '描述你想要的商品图效果，例如：白色背景，柔光，高级质感…'
    }));

    // 风格芯片
    const chipRow = el('div', { class: 'chip-scroll' });
    function renderChips() {
      chipRow.innerHTML = '';
      STYLE_CHIPS.forEach(c => {
        chipRow.appendChild(el('button', {
          class: 'style-chip' + (c === selectedStyle ? ' selected' : ''),
          onClick: () => { selectedStyle = c; renderChips(); }
        }, c));
      });
    }
    renderChips();
    container.appendChild(chipRow);

    // 任务模式下额外提醒（已预设参数）
    if (taskMode) {
      container.appendChild(el('div', {
        style: 'margin-top:10px;padding:8px 12px;border-radius:10px;background:rgba(124,154,126,0.08);font-size:11.5px;color:var(--sage);line-height:1.5'
      }, '⚡ 已按任务要求预设比例 ' + ctx.ratio + '、数量 ' + ctx.count + ' 张、风格“' + ctx.style + '”'));
    }

    // 参数切换弹层
    function openRatioSheet() {
      openSheet('选择比例', ['1:1', '3:4', '4:3', '9:16', '16:9'].map(r => ({
        ico: r === selectedRatio ? '✓' : '⚖',
        label: r,
        onClick: () => { selectedRatio = r; refreshParams(); }
      })));
    }
    function openCountSheet() {
      openSheet('选择数量', [1, 2, 4, 6, 9].map(n => ({
        ico: n === selectedCount ? '✓' : '🔢',
        label: n + ' 张',
        onClick: () => { selectedCount = n; refreshParams(); }
      })));
    }

    // 底部生成栏
    const genBar = el('div', { class: 'gen-bar' });
    function refreshParams() {
      genBar.innerHTML = '';
      genBar.appendChild(el('div', { class: 'gen-bar-row' }, [
        el('div', { class: 'mode-mini' }, [
          el('button', { class: 'active' }, '图片'),
          el('button', { onClick: () => navigate('videoGen') }, '视频'),
          el('button', { onClick: () => navigate('audioGen') }, '音频')
        ]),
        el('button', { class: 'param-pill', onClick: openRatioSheet }, [
          document.createTextNode(selectedRatio), el('span', { class: 'caret' }, '▾')
        ]),
        el('button', { class: 'param-pill', onClick: openCountSheet }, [
          document.createTextNode(selectedCount + '张'), el('span', { class: 'caret' }, '▾')
        ])
      ]));
      genBar.appendChild(el('button', {
        class: 'gen-btn',
        onClick: () => navigate('result')
      }, taskMode ? '✦  生成并提交到任务' : '✦  生成'));
      genBar.appendChild(el('div', { class: 'gen-hint' },
        taskMode ? '完成后将在结果页一键提交回任务'
                 : '预计消耗 ' + (selectedCount * 2) + ' 积分'));
    }
    refreshParams();
    s.appendChild(genBar);

    return s;
  },

  /* ========== 生成结果 ========== */
  result() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('生成结果', { forceBack: true }));

    // 任务上下文：仅当从工作台带着任务上下文进来时显示“提交到任务”主按钮
    const ctx = activeTaskContext;
    const taskMode = !!ctx;

    // 任务上下文条（结果页也保留，提醒用户当前处于任务模式）
    if (taskMode) {
      s.appendChild(el('div', { class: 'task-context-bar' }, [
        el('div', { class: 'tcb-ico' }, '◎'),
        el('div', { class: 'tcb-mid' }, [
          el('div', { class: 'tcb-title' }, '任务：' + ctx.source + ' · ' + ctx.type),
          el('div', { class: 'tcb-reqs' }, '当前选中：第 ' + 1 + ' / 4 张 · ' + ctx.ratio)
        ]),
        el('div', { class: 'tcb-view', onClick: () => openTaskReqSheet(ctx) }, '查看要求'),
        el('div', { class: 'tcb-close', title: '退出任务模式', onClick: () => {
          activeTaskContext = null;
          navigate('result', { replace: true });
        } }, '×')
      ]));
    }

    // Prompt 摘要
    s.appendChild(el('div', { class: 'prompt-summary' }, [
      el('span', {}, taskMode ? (ctx.style + ' · ' + ctx.ratio + ' · ' + ctx.count + '张') : '白色背景 · 高级质感 · 柔光'),
      el('span', { class: 'edit', onClick: () => toast('编辑 prompt') }, '✎')
    ]));

    // 模型 / 实际消耗 / 耗时 meta 行
    const usedModel = getModel(selectedModel['图片']);
    s.appendChild(el('div', { class: 'result-meta' }, [
      el('span', { class: 'rm-item' }, [
        el('span', { class: 'rm-logo' }, usedModel.logo),
        el('span', { class: 'rm-k' }, '模型'),
        el('span', { class: 'rm-v' }, usedModel.name)
      ]),
      el('span', { class: 'rm-item' }, [
        el('span', { class: 'rm-k' }, '实际消耗'),
        el('span', { class: 'rm-v sage' }, usedModel.cost + ' 积分')
      ]),
      el('span', { class: 'rm-item' }, [
        el('span', { class: 'rm-k' }, '生成耗时'),
        el('span', { class: 'rm-v' }, '3.2s')
      ])
    ]));

    // 缩略图 tabs
    let currentIdx = 0;
    const thumbs = el('div', { class: 'thumb-tabs' });
    const pager = el('div', { class: 'result-pager' });
    ['p1','p2','p3','p4'].forEach((p, i) => {
      pager.appendChild(el('div', { class: 'result-page ' + p }));
    });

    function renderThumbs() {
      thumbs.innerHTML = '';
      ['t1','t2','t3','t4'].forEach((t, i) => {
        thumbs.appendChild(el('div', {
          class: 'thumb-tab ' + (i === 0 ? '' : t) + (i === currentIdx ? ' active' : ''),
          onClick: () => { currentIdx = i; updatePager(); renderThumbs(); }
        }));
      });
    }
    function updatePager() {
      pager.style.transform = `translateX(-${currentIdx * 100}%)`;
      indexLabel.textContent = `${currentIdx + 1} / 4`;
      if (taskMode) {
        // 同步上下文条中的“当前选中”提示
        const reqs = s.querySelector('.task-context-bar .tcb-reqs');
        if (reqs) reqs.textContent = '当前选中：第 ' + (currentIdx + 1) + ' / 4 张 · ' + ctx.ratio;
      }
    }
    renderThumbs();
    s.appendChild(thumbs);

    // 主图（含 pager + 索引 + 底部动作栏）
    const frame = el('div', { class: 'result-frame' });
    frame.appendChild(pager);
    const indexLabel = el('div', { class: 'result-index' }, '1 / 4');
    frame.appendChild(indexLabel);
    frame.appendChild(el('div', { class: 'result-actions' }, [
      el('button', { onClick: () => toast('已保存到相册') }, [ el('span', { class: 'ico' }, '↓'), el('span', {}, '下载') ]),
      el('button', { onClick: () => toast('重新生成中…') }, [ el('span', { class: 'ico' }, '↻'), el('span', {}, '重生') ]),
      el('button', { onClick: () => toast('高清放大中…') }, [ el('span', { class: 'ico' }, '⤢'), el('span', {}, '高清') ]),
      el('button', { onClick: () => toast('已设为参考图') }, [ el('span', { class: 'ico' }, '◈'), el('span', {}, '参考') ]),
      el('button', { onClick: () => toast('分享链接已复制') }, [ el('span', { class: 'ico' }, '↗'), el('span', {}, '分享') ])
    ]));
    s.appendChild(frame);

    // 手势：左右滑动切换
    let startX = 0;
    frame.addEventListener('touchstart', e => startX = e.touches[0].clientX);
    frame.addEventListener('touchend', e => {
      const dx = e.changedTouches[0].clientX - startX;
      if (Math.abs(dx) > 50) {
        currentIdx = Math.max(0, Math.min(3, currentIdx + (dx < 0 ? 1 : -1)));
        updatePager(); renderThumbs();
      }
    });

    // 微调建议
    s.appendChild(el('div', { class: 'section-title', style: 'margin-top: 18px' }, [
      el('span', {}, '试试这些微调')
    ]));
    const refine = el('div', { class: 'refine-row' });
    ['换成暖光','加模特','换背景色','生成视频'].forEach(t => {
      refine.appendChild(el('button', { class: 'refine-chip', onClick: () => {
        if (t === '生成视频') navigate('videoGen');
        else toast(`已应用：${t}`);
      }}, t));
    });
    s.appendChild(refine);

    // 底部：任务模式下以“提交到任务”为主 CTA；非任务模式下为微调输入
    if (taskMode) {
      const submitBar = el('div', { class: 'gen-bar' }, [
        el('div', { style: 'display:flex;align-items:center;justify-content:space-between;gap:10px;width:100%' }, [
          el('div', { style: 'flex:1;min-width:0' }, [
            el('div', { style: 'font-size:11px;color:var(--text-muted);margin-bottom:2px' }, '完成后提交至'),
            el('div', { style: 'font-size:13px;color:var(--charcoal);font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis' }, ctx.source + ' · ' + ctx.title)
          ]),
          el('button', {
            class: 'btn-submit-task',
            onClick: () => {
              // 提交回任务：写入已提交集合 → 瞬时反馈 → 回到任务详情（待审核态）
              submittedTasks.add(ctx.id);
              const submittedCtx = ctx;
              activeTaskContext = null;
              successToast('已提交，等待发布方审核', 900);
              setTimeout(() => {
                // 直接回到 taskDetail（弹掉中间的工作台历史）
                while (navStack.length > 0 && navStack[navStack.length - 1] !== 'taskDetail') {
                  navStack.pop();
                }
                navigate('taskDetail', { replace: true });
              }, 600);
            }
          }, [
            el('span', { class: 'bst-ico' }, '◎'),
            el('span', {}, '提交到任务')
          ])
        ])
      ]);
      s.appendChild(submitBar);
      s.appendChild(el('div', { style: 'text-align:center;font-size:11px;color:var(--text-muted);padding:6px 20px 14px' },
        '提交后回到任务详情，状态变为“待审核”'));
    } else {
      // 非任务模式：保留原有微调输入栏
      s.appendChild(el('div', { class: 'gen-bar' }, [
        el('div', { class: 'gen-bar-row' }, [
          el('div', { class: 'mode-mini' }, [
            el('button', { class: 'active' }, '图片'),
            el('button', { onClick: () => navigate('videoGen') }, '视频'),
            el('button', { onClick: () => navigate('audioGen') }, '音频')
          ]),
          el('input', {
            class: 'soft-textarea',
            style: 'flex:1; min-height:auto; padding:8px 14px; font-size:13px; border-radius:999px',
            placeholder: '继续微调 prompt…'
          })
        ])
      ]));
    }

    return s;
  },

  /* ========== 视频生成 ========== */
  videoGen() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('视频生成', { forceBack: true }));

    // 起始帧 + 结束帧
    s.appendChild(el('div', { class: 'frame-row' }, [
      el('div', { class: 'frame-slot' }, [
        el('div', { class: 'label' }, '起始帧')
      ]),
      el('div', { class: 'frame-slot dashed', onClick: () => toast('添加结束帧') }, [
        el('span', { style: 'font-size:24px' }, '+'),
        el('div', { class: 'label' }, '结束帧（可选）')
      ])
    ]));

    s.appendChild(el('textarea', {
      class: 'soft-textarea',
      placeholder: '描述视频内容、运镜、节奏…'
    }));

    // 快捷芯片
    const chipRow = el('div', { class: 'chip-scroll' });
    let sel = '商品旋转展示';
    function renderChips() {
      chipRow.innerHTML = '';
      VIDEO_CHIPS.forEach(c => {
        chipRow.appendChild(el('button', {
          class: 'style-chip' + (c === sel ? ' selected' : ''),
          onClick: () => { sel = c; renderChips(); }
        }, c));
      });
    }
    renderChips();
    s.appendChild(chipRow);

    // 参数
    s.appendChild(el('div', { class: 'param-row', style: 'margin-top:14px' }, [
      el('button', { class: 'param-pill' }, [document.createTextNode('时长 5s'), el('span', { class: 'caret' }, '▾')]),
      el('button', { class: 'param-pill' }, [document.createTextNode('比例 9:16'), el('span', { class: 'caret' }, '▾')]),
      el('button', { class: 'param-pill' }, [document.createTextNode('1080p'), el('span', { class: 'caret' }, '▾')])
    ]));

    // 底部栏
    s.appendChild(el('div', { class: 'gen-bar' }, [
      el('div', { class: 'gen-bar-row' }, [
        el('div', { class: 'mode-mini' }, [
          el('button', { onClick: () => navigate('imageGen') }, '图片'),
          el('button', { class: 'active' }, '视频'),
          el('button', { onClick: () => navigate('audioGen') }, '音频')
        ])
      ]),
      el('button', { class: 'gen-btn', onClick: () => toast('视频生成中，约需 60 秒…') }, '▶  生成视频'),
      el('div', { class: 'gen-hint' }, '视频生成约需 60 秒')
    ]));

    return s;
  },

  /* ========== 音频生成 ========== */
  audioGen() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('音频生成', { forceBack: true }));

    // 波形预览
    const wave = el('div', { class: 'wave-card' });
    const wf = el('div', { class: 'waveform' });
    for (let i = 0; i < 32; i++) {
      const bar = el('span', { style: { animationDelay: (i * 0.05) + 's', height: '8px' } });
      wf.appendChild(bar);
    }
    wave.appendChild(wf);
    wave.appendChild(el('div', { class: 'wave-placeholder' }, '生成后将显示波形'));
    s.appendChild(wave);

    s.appendChild(el('textarea', {
      class: 'soft-textarea',
      placeholder: '输入文案或描述音频内容…'
    }));

    // 音色选择
    s.appendChild(el('div', { class: 'section-title', style: 'margin-top:18px' }, [
      el('span', {}, '选择音色')
    ]));
    let selVoice = 0;
    const voiceScroll = el('div', { class: 'voice-scroll' });
    function renderVoices() {
      voiceScroll.innerHTML = '';
      VOICES.forEach((v, i) => {
        voiceScroll.appendChild(el('div', {
          class: 'voice-chip' + (i === selVoice ? ' selected' : ''),
          onClick: () => { selVoice = i; renderVoices(); }
        }, [
          el('div', { class: 'voice-avatar' }, v.ico),
          el('div', { class: 'voice-name' }, v.name)
        ]));
      });
    }
    renderVoices();
    s.appendChild(voiceScroll);

    // 语言切换
    s.appendChild(el('div', { class: 'section-title', style: 'margin-top:18px' }, [
      el('span', {}, '语言')
    ]));
    s.appendChild(el('div', { class: 'param-row' }, [
      el('button', { class: 'param-pill', style: 'flex:1; justify-content:center',
        onClick: () => openSheet('选择播报语言', LANGS.map(l => ({
          ico: '🌐', label: l, onClick: () => toast(`已切换到 ${l}`)
        })))
      }, [document.createTextNode('语言：中文'), el('span', { class: 'caret' }, '▾')])
    ]));

    // 底部栏
    s.appendChild(el('div', { class: 'gen-bar' }, [
      el('div', { class: 'gen-bar-row' }, [
        el('div', { class: 'mode-mini' }, [
          el('button', { onClick: () => navigate('imageGen') }, '图片'),
          el('button', { onClick: () => navigate('videoGen') }, '视频'),
          el('button', { class: 'active' }, '音频')
        ])
      ]),
      el('button', { class: 'gen-btn', onClick: () => toast('音频生成中…') }, '♪  生成音频')
    ]));

    return s;
  },

  /* ========== 场景列表 ========== */
  scenes() {
    const s = el('div', { class: 'screen' });

    // 作为 Tab 根时隐藏返回；从首页“查看全部”或侧栏进入时显示返回
    s.appendChild(topBar('电商场景', { rightIco: '🔍', onRight: () => toast('搜索场景') }));

    s.appendChild(el('div', { class: 'search-bar-placeholder', style: 'margin-bottom:16px' }, [
      el('div', {
        class: 'glass',
        style: 'padding:11px 16px; border-radius:999px; display:flex; align-items:center; gap:8px; color:var(--text-muted); font-size:13px; cursor:pointer',
        onClick: () => toast('搜索场景')
      }, [
        el('span', {}, '🔍'),
        el('span', {}, '搜索 AI 工具…')
      ])
    ]));

    const grid = el('div', { class: 'scene-grid' });
    SCENES.forEach(sc => {
      grid.appendChild(el('div', { class: 'scene-tile', onClick: () => navigate(sc.route) }, [
        el('div', {}, [
          el('div', { class: 'ico' }, sc.ico),
          el('div', { class: 'name' }, sc.name)
        ]),
        el('div', { class: 'caption' }, sc.caption)
      ]));
    });
    s.appendChild(grid);
    s.appendChild(el('div', { style: 'height:20px' }));

    return s;
  },

  /* ========== 课程中心 ========== */
  courseCenter() {
    const s = el('div', { class: 'screen course-center' });
    const COVERS = [
      'linear-gradient(135deg,#7C9A7E,#A9C3A6)',
      'linear-gradient(135deg,#C9A96E,#E7D3A1)',
      'linear-gradient(135deg,#6E8B9A,#A7C4D0)',
      'linear-gradient(135deg,#8A7E9A,#C3B6D6)',
      'linear-gradient(135deg,#9A8B6E,#D6C7A7)'
    ];
    const pending = myRegistrations.filter(r => r.status === 'pending').length;

    // 顶栏：课程中心 + 搜索 + 我的报名（含角标）
    s.appendChild(el('div', { class: 'top-bar' }, [
      el('div', { style: 'width:36px' }),
      el('div', { class: 'title' }, '课程中心'),
      el('div', { class: 'tb-acts' }, [
        el('div', { class: 'act', title: '搜索课程', onClick: () => toast('搜索课程') }, '🔍'),
        el('div', { class: 'act', title: '我的报名', style: 'position:relative', onClick: () => navigate('myRegistrations') }, ['🎫', pending ? el('span', { class: 'act-badge' }, String(pending)) : null])
      ])
    ]));

    const TABS = ['全部', '线下培训', '线上课程', '已报名'];
    let activeTab = 0;
    const seg = el('div', { class: 'seg-control' });
    const listWrap = el('div');

    function offlineCard(sess, i) {
      const remain = sess.quota - sess.enrolled;
      const full = remain <= 0, tight = remain > 0 && remain < 5;
      const pct = Math.round(sess.enrolled / sess.quota * 100);
      const enr = isEnrolled(sess.id);
      return el('div', { class: 'course-card', onClick: () => { selectedSessionId = sess.id; navigate('courseDetail'); } }, [
        el('div', { class: 'cc-cover', style: { background: COVERS[i % COVERS.length] } }, [
          el('span', { class: 'cc-glyph' }, '🎓'),
          el('span', { class: 'cc-cover-tag' }, '线下培训'),
          full ? el('span', { class: 'cc-cover-full' }, '已满员') : null
        ]),
        el('div', { class: 'cc-body' }, [
          el('div', { class: 'cc-loc' }, sess.city + ' · ' + sess.term + ' · ' + shortDate(sess)),
          el('div', { class: 'cc-title' }, COURSE_CONTENT.title),
          el('div', { class: 'cc-intro' }, COURSE_CONTENT.intro),
          el('div', { class: 'cc-quota' }, [
            el('div', { class: 'progress-thin' + (tight ? ' amber' : '') }, [el('div', { class: 'pt-fill' + (tight ? ' amber' : ''), style: 'width:' + pct + '%' })]),
            el('span', { class: 'cc-quota-txt' + (tight ? ' amber' : '') }, full ? '已满员' : (tight ? '仅剩 ' + remain + ' 席' : '已报名 ' + sess.enrolled + '/' + sess.quota))
          ]),
          el('div', { class: 'cc-foot' }, [
            el('span', { class: 'cc-fee' + (sess.fee === 0 ? ' free' : '') }, sess.fee === 0 ? '免费' : '¥ ' + sess.fee),
            el('button', { class: full ? 'btn-outline sm' : 'btn-gradient sm', onClick: e => { e.stopPropagation(); if (enr) navigate('myRegistrations'); else if (full) toast('已加入候补登记'); else { selectedSessionId = sess.id; registerCourse(sess); } } }, enr ? '已报名' : (full ? '候补登记' : '立即报名'))
          ])
        ])
      ]);
    }
    function onlineCard(c, i) {
      return el('div', { class: 'course-card online', onClick: () => toast('进入线上课程：' + c.title) }, [
        el('div', { class: 'cc-cover sm', style: { background: COVERS[(i + 2) % COVERS.length] } }, [
          el('span', { class: 'cc-glyph' }, '▶'),
          el('span', { class: 'cc-cover-tag' }, '线上课程')
        ]),
        el('div', { class: 'cc-body' }, [
          el('div', { class: 'cc-title' }, c.title),
          el('div', { class: 'cc-intro' }, c.intro),
          el('div', { class: 'cc-foot' }, [
            el('span', { class: 'cc-meta' }, c.duration + ' · ' + c.teacher),
            el('button', { class: 'btn-gradient sm', onClick: e => { e.stopPropagation(); toast('开始学习：' + c.title); } }, c.priceLabel === '免费' ? '开始学习' : c.priceLabel)
          ])
        ])
      ]);
    }
    function enrolledCard(r) {
      const chip = regChip(r);
      return el('div', { class: 'reg-card', onClick: () => { selectedRegCode = r.code; navigate('regDetail'); } }, [
        el('div', { class: 'reg-top' }, [
          el('span', { class: 'reg-city' }, r.city + ' · ' + r.term),
          el('span', { class: 'reg-chip ' + chip.cls }, [chip.medal ? el('span', { class: 'rc-medal' }, '🏅') : null, chip.txt])
        ]),
        el('div', { class: 'reg-mid' }, r.date + ' · ' + r.addr),
        el('div', { class: 'reg-bottom' }, [
          el('span', { class: 'reg-link', onClick: e => { e.stopPropagation(); selectedRegCode = r.code; navigate('regDetail'); } }, '查看凭证')
        ])
      ]);
    }
    const head = (txt, mt) => el('div', { class: 'section-title', style: mt ? 'margin-top:22px' : '' }, el('span', {}, txt));
    const empty = () => el('div', { style: 'text-align:center;padding:40px;color:var(--text-muted);font-size:13px' }, '暂无内容');

    function render() {
      seg.innerHTML = '';
      TABS.forEach((t, i) => seg.appendChild(el('div', { class: 'seg-item' + (i === activeTab ? ' active' : ''), onClick: () => { activeTab = i; render(); } }, t)));
      listWrap.innerHTML = '';
      const tab = TABS[activeTab];
      const showOff = tab === '全部' || tab === '线下培训';
      const showOn = tab === '全部' || tab === '线上课程';
      const showEnr = tab === '全部' || tab === '已报名';
      if (showOff) { listWrap.appendChild(head('即将开课')); TRAINING.sessions.forEach((sess, i) => listWrap.appendChild(offlineCard(sess, i))); }
      if (showOn) { listWrap.appendChild(head('线上课程', showOff)); ONLINE_COURSES.forEach((c, i) => listWrap.appendChild(onlineCard(c, i))); }
      if (showEnr) {
        const regs = myRegistrations.filter(r => r.status !== 'cancelled');
        listWrap.appendChild(head(tab === '已报名' ? '我的报名记录' : '我的报名', showOff || showOn));
        if (!regs.length) listWrap.appendChild(empty()); else regs.forEach(r => listWrap.appendChild(enrolledCard(r)));
      }
    }
    render();
    s.appendChild(seg);
    s.appendChild(listWrap);
    s.appendChild(el('div', { style: 'height:20px' }));
    return s;
  },

  /* ========== 课程详情（可预览不可完整获取） ========== */
  courseDetail() {
    const sess = (selectedSessionId && TRAINING.sessions.find(x => x.id === selectedSessionId)) || featSession();
    const s = el('div', { class: 'screen course-detail' });
    const enrolled = isEnrolled(sess.id);
    const remain = sess.quota - sess.enrolled;
    const tight = remain > 0 && remain < 5;

    s.appendChild(topBar('课程详情', { forceBack: true, rightIco: '↗', onRight: () => toast('分享课程') }));

    // Hero 封面（16:9 + 渐变遮罩 + 浮层标题）
    s.appendChild(el('div', { class: 'cd-hero' }, [
      el('div', { class: 'cd-cover' }, el('span', { class: 'cd-cover-glyph' }, '🎓')),
      el('div', { class: 'cd-hero-txt' }, [
        el('div', { class: 'cd-title' }, COURSE_CONTENT.title),
        el('div', { class: 'cd-term' }, sess.term + ' · ' + sess.city + '站'),
        el('div', { class: 'cd-tags' }, COURSE_CONTENT.tags.map(t => el('span', { class: 'cd-pill' }, t)))
      ])
    ]));

    // 课程亮点
    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { class: 'sc-title' }, '课程亮点'),
      el('div', { class: 'hl-list' }, COURSE_CONTENT.highlights.map(h => el('div', { class: 'hl-row' }, [el('span', { class: 'hl-check' }, '✓'), el('span', { class: 'hl-txt' }, h)])))
    ]));

    // 课程大纲（Day 分组可折叠；报名前预览、报名后可点进每节）
    const sylCard = el('div', { class: 'section-card syllabus-card' }, [
      el('div', { class: 'sc-title' }, '课程大纲'),
      el('div', { class: 'syl-hint' + (enrolled ? ' unlocked' : '') }, enrolled ? '🔓 已报名 · 点击每节查看讲义 / 视频 / 案例' : '🔒 报名前仅可预览标题与时间，报名后解锁完整内容')
    ]);
    COURSE_CONTENT.syllabus.forEach(group => {
      const totalH = group.lessons.reduce((a, l) => a + l.hours, 0);
      const gEl = el('div', { class: 'syl-group' });
      const caret = el('span', { class: 'syl-caret' }, '▾');
      const lessonsEl = el('div', { class: 'syl-lessons' });
      group.lessons.forEach(l => lessonsEl.appendChild(el('div', { class: 'syl-lesson' + (enrolled ? '' : ' locked'), onClick: () => openLessonSheet(l, enrolled, sess) }, [
        el('div', { class: 'sl-time' }, l.time),
        el('div', { class: 'sl-main' }, [
          el('div', { class: 'sl-topic' }, l.topic),
          el('div', { class: 'sl-meta' }, l.teacher + ' · ' + l.hours + 'h')
        ]),
        enrolled ? el('span', { class: 'sl-go' }, '›') : el('span', { class: 'sl-lock' }, '🔒')
      ])));
      const head = el('div', { class: 'syl-day', onClick: () => { const open = lessonsEl.style.display !== 'none'; lessonsEl.style.display = open ? 'none' : ''; caret.textContent = open ? '▸' : '▾'; head.classList.toggle('collapsed', open); } }, [
        el('span', { class: 'syl-day-name' }, group.day),
        el('span', { class: 'syl-day-sum' }, '共 ' + group.lessons.length + ' 节 · 约 ' + totalH + ' 小时'),
        caret
      ]);
      gEl.appendChild(head); gEl.appendChild(lessonsEl);
      sylCard.appendChild(gEl);
    });
    s.appendChild(sylCard);

    // 讲师介绍
    s.appendChild(el('div', { class: 'section-card teacher-card' }, [
      el('div', { class: 'sc-title' }, '讲师介绍'),
      el('div', { class: 'tch-row' }, [
        el('div', { class: 'tch-avatar' }, sess.teacher[0]),
        el('div', { class: 'tch-info' }, [
          el('div', { class: 'tch-name' }, sess.teacher),
          el('div', { class: 'tch-role' }, COURSE_CONTENT.teacherTitle),
          el('div', { class: 'tch-bio' }, COURSE_CONTENT.teacherBio)
        ])
      ])
    ]));

    // 培训信息
    const pct = Math.round(sess.enrolled / sess.quota * 100);
    s.appendChild(el('div', { class: 'section-card info-card' }, [
      el('div', { class: 'sc-title' }, '培训信息'),
      el('div', { class: 'info-row' }, [el('span', { class: 'in-k' }, '时间'), el('span', { class: 'in-v' }, sess.date)]),
      el('div', { class: 'info-row' }, [el('span', { class: 'in-k' }, '地点'), el('span', { class: 'in-v' }, [sess.addr, el('span', { class: 'in-map', onClick: () => toast('打开地图 App') }, '📍')])]),
      el('div', { class: 'info-row col' }, [
        el('span', { class: 'in-k' }, '名额'),
        el('div', { class: 'in-quota' }, [
          el('div', { class: 'progress-thin' + (tight ? ' amber' : '') }, [el('div', { class: 'pt-fill' + (tight ? ' amber' : ''), style: 'width:' + pct + '%' })]),
          el('span', { class: 'quota-txt' + (tight ? ' amber' : '') }, sess.enrolled + ' / ' + sess.quota + (tight ? ' · 仅剩 ' + remain + ' 席' : ''))
        ])
      ]),
      el('div', { class: 'info-row' }, [el('span', { class: 'in-k' }, '讲师'), el('span', { class: 'in-v' }, sess.teacher)]),
      el('div', { class: 'info-row' }, [el('span', { class: 'in-k' }, '费用'), el('span', { class: 'in-v fee' + (sess.fee === 0 ? ' free' : '') }, sess.fee === 0 ? '免费' : '¥ ' + sess.fee)]),
      sess.deposit ? el('div', { class: 'info-note' }, '通过考核后全额返还至荷包') : null
    ]));

    // 报名须知（折叠）
    let noticeOpen = false;
    const noticeFull = ['需携带身份证 + 手机', '培训期间需全程参与', '考核在第二天下午进行', '未通过可免费重听一次', '食宿自理'];
    const noticeCard = el('div', { class: 'section-card notice-card' });
    function renderNotice() {
      noticeCard.innerHTML = '';
      noticeCard.appendChild(el('div', { class: 'notice-head' }, [
        el('span', { class: 'sc-title', style: 'margin:0' }, '报名须知'),
        el('span', { class: 'notice-toggle', onClick: () => { noticeOpen = !noticeOpen; renderNotice(); } }, noticeOpen ? '收起 ▴' : '展开 ▾')
      ]));
      const ul = el('ul', { class: 'notice-list' });
      (noticeOpen ? noticeFull : noticeFull.slice(0, 3)).forEach(n => ul.appendChild(el('li', {}, n)));
      noticeCard.appendChild(ul);
    }
    renderNotice();
    s.appendChild(noticeCard);

    // 往期学员评价
    s.appendChild(el('div', { class: 'section-card review-card' }, [
      el('div', { class: 'sc-title' }, '往期学员评价'),
      el('div', { class: 'rv-list' }, COURSE_CONTENT.reviews.map(rv => el('div', { class: 'rv-row' }, [
        el('div', { class: 'rv-avatar' }, rv.avatar),
        el('div', { class: 'rv-body' }, [
          el('div', { class: 'rv-top' }, [el('span', { class: 'rv-name' }, rv.name), el('span', { class: 'rv-stars' }, '★'.repeat(rv.stars) + '☆'.repeat(5 - rv.stars))]),
          el('div', { class: 'rv-text' }, rv.text)
        ])
      ]))),
      el('div', { class: 'rv-all', onClick: () => toast('查看全部评价') }, '查看全部评价 ›')
    ]));

    s.appendChild(el('div', { style: 'height:78px' }));

    // 底部固定 bar（价格 + 限人数 + 报名/候补/查看）
    const bottom = el('div', { class: 'cd-bottom' });
    function renderBottom() {
      bottom.innerHTML = '';
      const isEnr = isEnrolled(sess.id);
      const rm = sess.quota - sess.enrolled;
      bottom.appendChild(el('div', { class: 'cd-binfo' }, [
        el('span', { class: 'cd-price' + (sess.fee === 0 ? ' free' : '') }, sess.fee === 0 ? '免费' : '¥ ' + sess.fee),
        el('span', { class: 'cd-limit' }, '限 ' + sess.quota + ' 人')
      ]));
      let txt = '立即报名', cls = 'btn-gradient', fn = () => registerCourse(sess);
      if (isEnr) { txt = '查看我的报名'; fn = () => navigate('myRegistrations'); }
      else if (rm <= 0) { txt = '候补登记'; cls = 'btn-outline'; fn = () => toast('已加入候补登记'); }
      bottom.appendChild(el('button', { class: cls, onClick: fn }, txt));
    }
    renderBottom();
    s.appendChild(bottom);
    return s;
  },

  /* ========== AI 抠图 ========== */
  cutout() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('AI 抠图', { forceBack: true, rightIco: '?', onRight: () => toast('帮助') }));

    let state = 'upload'; // upload | result
    let tab = 'after';
    let bgSel = 'white';

    const container = el('div');
    s.appendChild(container);

    function render() {
      container.innerHTML = '';
      if (state === 'upload') {
        container.appendChild(el('div', { class: 'upload-area', onClick: () => openSheet('选择来源', [
          { ico: '📷', label: '拍照', onClick: () => { state = 'result'; render(); } },
          { ico: '🖼', label: '相册', onClick: () => { state = 'result'; render(); } }
        ]) }, [
          el('div', { class: 'ico' }, '✂'),
          el('div', { class: 'txt' }, '上传商品图，一键抠图'),
          el('div', { class: 'sub' }, 'AI 自动识别边缘，输出透明 PNG')
        ]));
      } else {
        // 原图 / 抠图后 切换
        container.appendChild(el('div', { class: 'toggle-tabs' }, [
          el('button', { class: tab === 'before' ? 'active' : '', onClick: () => { tab = 'before'; render(); } }, '原图'),
          el('button', { class: tab === 'after' ? 'active' : '', onClick: () => { tab = 'after'; render(); } }, '抠图后')
        ]));

        if (tab === 'after') {
          container.appendChild(el('div', { class: 'checker-card' }, [
            el('div', { class: 'product' })
          ]));
        } else {
          container.appendChild(el('div', {
            style: 'aspect-ratio:1; border-radius:24px; overflow:hidden; box-shadow:var(--shadow-soft); background:linear-gradient(135deg,#E4C9A8,#C9A96E); margin-bottom:14px'
          }));
        }

        // 动作栏
        container.appendChild(el('div', { class: 'result-actions', style: 'position:relative; left:0; right:0; bottom:0; margin-bottom:14px' }, [
          el('button', { onClick: () => toast('下载 PNG') }, [ el('span', { class: 'ico' }, '↓'), el('span', {}, 'PNG') ]),
          el('button', { onClick: () => toast('选择背景') }, [ el('span', { class: 'ico' }, '▣'), el('span', {}, '换背景') ]),
          el('button', { onClick: () => toast('加阴影') }, [ el('span', { class: 'ico' }, '◐'), el('span', {}, '阴影') ]),
          el('button', { onClick: () => toast('边缘优化') }, [ el('span', { class: 'ico' }, '✎'), el('span', {}, '边缘') ]),
          el('button', { onClick: () => toast('分享') }, [ el('span', { class: 'ico' }, '↗'), el('span', {}, '分享') ])
        ]));

        // 背景预设
        container.appendChild(el('div', { class: 'section-title' }, [ el('span', {}, '换背景') ]));
        const presets = el('div', { class: 'bg-presets' });
        BG_PRESETS.forEach(p => {
          presets.appendChild(el('div', { style: 'display:flex; flex-direction:column; align-items:center; gap:6px' }, [
            el('div', {
              class: 'bg-preset ' + p.cls + (p.key === bgSel ? ' active' : ''),
              onClick: () => { bgSel = p.key; render(); toast(`已应用：${p.lbl}`); }
            }, p.ico ? [el('span', {}, p.ico)] : []),
            el('div', { style: 'font-size:10.5px; color:var(--taupe)' }, p.lbl)
          ]));
        });
        container.appendChild(presets);
      }
    }
    render();

    s.appendChild(el('div', { class: 'gen-bar' }, [
      el('button', { class: 'gen-btn', onClick: () => {
        if (state === 'upload') toast('请先上传图片');
        else toast('抠图完成！');
      }}, state === 'upload' ? '✦  开始抠图' : '↻  重新抠图')
    ]));

    return s;
  },

  /* ========== 数字人播报 ========== */
  digitalHuman() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('数字人播报', { forceBack: true }));

    // 数字人预览
    s.appendChild(el('div', { class: 'dh-preview' }, [
      el('div', { class: 'dh-avatar-circle' }, '◐'),
      el('button', { class: 'dh-change', onClick: () => toast('选择数字人形象') }, '更换形象')
    ]));

    // 文案
    s.appendChild(el('textarea', {
      class: 'soft-textarea',
      placeholder: '输入口播文案…',
      style: 'min-height: 80px'
    }));

    // 音色 / 语言
    s.appendChild(el('div', { class: 'param-row', style: 'margin-top:14px' }, [
      el('button', { class: 'param-pill', onClick: () => openSheet('选择音色', VOICES.map(v => ({
        ico: v.ico, label: v.name, onClick: () => toast(`音色：${v.name}`)
      }))) }, [document.createTextNode('音色：温柔女声'), el('span', { class: 'caret' }, '▾')]),
      el('button', { class: 'param-pill', onClick: () => openSheet('选择语言', LANGS.map(l => ({
        ico: '🌐', label: l, onClick: () => toast(`语言：${l}`)
      }))) }, [document.createTextNode('语言：中文'), el('span', { class: 'caret' }, '▾')])
    ]));

    // 语速 slider
    s.appendChild(el('div', { class: 'slider-row' }, [
      el('span', { class: 'lbl' }, '语速'),
      el('input', { type: 'range', min: '0.5', max: '2', step: '0.1', value: '1' }),
      el('span', { class: 'val' }, '1.0x')
    ]));

    // 背景选择
    s.appendChild(el('div', { class: 'section-title' }, [ el('span', {}, '播报背景') ]));
    const bgScroll = el('div', { class: 'bg-presets' });
    ['纯色','办公室','直播间','户外','自定义'].forEach((n, i) => {
      const colors = ['#F7F7F5', '#E4C9A8', '#D4B896', '#A8BFA0', 'rgba(255,255,255,0.5)'];
      bgScroll.appendChild(el('div', { style: 'display:flex; flex-direction:column; align-items:center; gap:6px' }, [
        el('div', {
          class: 'bg-preset' + (i === 0 ? ' active' : ''),
          style: { background: colors[i], border: i === 4 ? '1.5px dashed rgba(124,154,126,0.4)' : '' }
        }, i === 4 ? [el('span', { style: 'color:var(--sage); font-size:18px' }, '+')] : []),
        el('div', { style: 'font-size:10.5px; color:var(--taupe)' }, n)
      ]));
    });
    s.appendChild(bgScroll);

    s.appendChild(el('div', { class: 'gen-bar' }, [
      el('button', { class: 'gen-btn', onClick: () => toast('视频生成中，约需 90 秒…') }, '◐  生成播报视频'),
      el('div', { class: 'gen-hint' }, '约需 90 秒')
    ]));

    return s;
  },

  /* ========== 作品 ========== */
  works() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('我的作品', { rightIco: '🔍', onRight: () => toast('搜索作品') }));

    // 分类 tabs
    const tabs = el('div', { class: 'chip-scroll', style: 'margin: 0 -20px 16px; padding-left:20px; padding-right:20px' });
    let cat = '全部';
    function renderTabs() {
      tabs.innerHTML = '';
      ['全部','图片','视频','音频'].forEach(c => {
        tabs.appendChild(el('button', {
          class: 'style-chip' + (c === cat ? ' selected' : ''),
          onClick: () => { cat = c; renderTabs(); renderGrid(); }
        }, c));
      });
    }
    renderTabs();
    s.appendChild(tabs);

    const grid = el('div', { class: 'works-grid' });
    function renderGrid() {
      grid.innerHTML = '';
      WORKS.filter(w => cat === '全部' || w.mode === cat).forEach(w => {
        grid.appendChild(el('div', { class: 'work-item ' + w.shape, onClick: () => navigate('result') }, [
          el('div', { class: 'work-thumb ' + w.g }),
          el('div', { class: 'work-badge' + (w.mode === '视频' ? ' video' : '') }, w.mode)
        ]));
      });
    }
    renderGrid();
    s.appendChild(grid);

    return s;
  },

  /* ========== 我的 ========== */
  me() {
    const s = el('div', { class: 'screen' });

    // 仅当从侧栏或其他屏跳转而来时显示顶栏（Tab 根无需返回）
    if (canGoBack()) {
      s.appendChild(topBar('我的', { rightIco: '⚙', onRight: () => toast('设置') }));
    }

    // 用户头部卡片
    s.appendChild(el('div', { class: 'detail-hero', style: 'margin-bottom:16px' }, [
      el('div', { style: 'display:flex;align-items:center;gap:14px;margin-bottom:14px' }, [
        el('div', { class: 'dh-avatar', style: 'width:56px;height:56px;font-size:20px' }, 'K'),
        el('div', {}, [
          el('div', { style: 'font-size:17px;font-weight:600;color:var(--charcoal)' }, 'KST 创作者'),
          el('div', { style: 'display:flex;align-items:center;gap:6px;margin-top:4px' }, [
            el('span', { class: 'dh-verified' }, '✓ 认证创作者')
          ])
        ])
      ]),
      el('div', { class: 'me-stats' }, [
        el('div', { class: 'ms-item' }, [
          el('div', { class: 'ms-val' }, '23'),
          el('div', { class: 'ms-lbl' }, '接单数')
        ]),
        el('div', { class: 'ms-item' }, [
          el('div', { class: 'ms-val' }, '91%'),
          el('div', { class: 'ms-lbl' }, '完成率')
        ]),
        el('div', { class: 'ms-item' }, [
          el('div', { class: 'ms-val' }, '4.9'),
          el('div', { class: 'ms-lbl' }, '好评率')
        ])
      ])
    ]));

    // 创作者成长入口卡
    s.appendChild(el('div', { class: 'growth-entry glass', onClick: () => navigate('creatorLevel') }, [
      el('div', { class: 'ge-badge', html: levelBadgeSVG(CREATOR.level, 44) }),
      el('div', { class: 'ge-mid' }, [
        el('div', { class: 'ge-title' }, 'Lv.' + CREATOR.level + ' ' + LEVEL_TITLES[CREATOR.level]),
        el('div', { class: 'progress-thin' }, [el('div', { class: 'pt-fill', style: 'width:' + Math.min(100, Math.round(CREATOR.exp / (LEVEL_EXP[CREATOR.level + 1] || LEVEL_EXP[10]) * 100)) + '%' })])
      ]),
      el('div', { class: 'ge-right' }, [el('span', {}, CREATOR.badges.length + ' 徽章'), el('span', { class: 'caret' }, '›')])
    ]));

    // 荷包入口卡
    s.appendChild(el('div', { class: 'wallet-entry', onClick: () => navigate('wallet') }, [
      el('div', { class: 'we-top' }, [
        el('div', {}, [
          el('div', { class: 'we-label' }, '我的荷包'),
          el('div', { class: 'we-balance' }, '¥ 156.00')
        ]),
        el('button', { class: 'we-btn', onClick: e => { e.stopPropagation(); navigate('withdraw'); } }, '提现')
      ]),
      el('div', { class: 'we-stats' }, [
        el('span', {}, '累计赚取 ¥ 892'),
        el('span', {}, '积分 1,250')
      ])
    ]));

    // 功能菜单
    const items = [
      { ico: '↑', name: '创作者等级', route: 'creatorLevel' },
      { ico: '🏅', name: '我的徽章', route: 'badgeWall' },
      { ico: '🎓', name: '培训报名', route: 'training' },
      { ico: '🎫', name: '我的报名', route: 'myRegistrations' },
      { ico: '◈', name: '我的作品', route: 'works' },
      { ico: '☰', name: '接单记录', route: 'taskHistory' },
      { ico: '◎', name: '收益明细', route: 'wallet' },
      { ico: '✶', name: '算力积分', route: 'buyCredits' },
      { ico: '↑', name: '提现记录', toast: '提现记录' },
      { ico: '♡', name: '邀请好友赚佣金', toast: '邀请好友' },
      { ico: '⚙', name: '设置', toast: '设置' },
      { ico: '?', name: '帮助与反馈', toast: '帮助' }
    ];
    const list = el('div', { class: 'me-list' });
    items.forEach(it => {
      list.appendChild(el('div', {
        class: 'me-item',
        onClick: () => it.route ? navigate(it.route) : toast(it.toast)
      }, [
        el('div', { class: 'ico' }, it.ico),
        el('div', { class: 'name' }, it.name),
        el('div', { class: 'caret' }, '›')
      ]));
    });
    s.appendChild(list);

    return s;
  },

  /* ========== 接单大厅 ========== */
  taskMarket() {
    const s = el('div', { class: 'screen' });
    const TASKS = TASKS_DB;
    const CATS = ['全部', '商品宣传图', '数字人播报', '视频生成', '音频配音', '跨境主图'];
    let activeCat = '全部';
    let activeSort = 0;

    s.appendChild(topBar('接单大厅', { rightIco: '🔔', onRight: () => toast('消息通知') }));

    // 分类芯片
    const chipRow = el('div', { class: 'chip-scroll', style: 'margin:0 -20px 12px; padding:0 20px' });
    function renderChips() {
      chipRow.innerHTML = '';
      CATS.forEach(c => {
        chipRow.appendChild(el('button', {
          class: 'style-chip' + (c === activeCat ? ' active' : ''),
          onClick: () => { activeCat = c; renderChips(); }
        }, c));
      });
    }
    renderChips();
    s.appendChild(chipRow);

    // 难度筛选行（分类芯片下方）：超出当前等级的难度显示锁图标 + 50% 透明
    const DIFFS = ['全部难度', ...DIFF_KEYS];
    let activeDiff = '全部难度';
    const diffRow = el('div', { class: 'diff-scroll', style: 'margin:0 -20px 12px; padding:0 20px' });
    function diffLocked(d) {
      const req = DIFFICULTY[d];
      return CREATOR.level < req.minLevel || (!!req.badge && !CREATOR.badges.includes(req.badge));
    }
    function renderDiffs() {
      diffRow.innerHTML = '';
      DIFFS.forEach(d => {
        const isAll = d === '全部难度';
        const locked = !isAll && diffLocked(d);
        diffRow.appendChild(el('button', {
          class: 'diff-filter' + (d === activeDiff ? ' active' : '') + (locked ? ' locked' : '') + (!isAll ? ' ' + DIFFICULTY[d].cls : ''),
          onClick: () => {
            if (locked) { openUnlockSheet(d); return; }
            activeDiff = d; renderDiffs(); renderList();
          }
        }, isAll
          ? [el('span', {}, d), el('span', { class: 'df-caret' }, '▾')]
          : [locked ? el('span', { class: 'dc-lock' }, '🔒') : null, el('span', {}, d)]));
      });
    }
    renderDiffs();
    s.appendChild(diffRow);

    // 排序行
    const sortLabels = ['最新发布 ▾', '价格最高 ▾', '即将截止 ▾'];
    const sortRow = el('div', { class: 'sort-row' });
    function renderSort() {
      sortRow.innerHTML = '';
      sortLabels.forEach((l, i) => {
        sortRow.appendChild(el('span', {
          class: 'sort-item' + (i === activeSort ? ' active' : ''),
          onClick: () => { activeSort = i; renderSort(); }
        }, l));
      });
    }
    renderSort();
    s.appendChild(sortRow);

    // 任务列表
    const listWrap = el('div');
    function renderList() {
      listWrap.innerHTML = '';
      let filtered = activeCat === '全部' ? TASKS : TASKS.filter(t => t.type === activeCat);
      if (activeDiff !== '全部难度') filtered = filtered.filter(t => taskDifficulty(t) === activeDiff);
      if (activeSort === 1) filtered = [...filtered].sort((a, b) => b.price - a.price);
      if (activeSort === 2) filtered = [...filtered].sort((a, b) => a.total - a.taken - (b.total - b.taken));
      filtered.forEach(t => {
        const dlClass = t.deadlineLevel === 'critical' ? 'deadline-critical' : t.deadlineLevel === 'urgent' ? 'deadline-urgent' : 'deadline-normal';
        const us = unlockState(t);
        const dcls = DIFFICULTY[us.difficulty].cls;
        const byLevel = us.locked && us.reason === 'level';   // 等级不足 → 60% 透明 + 锁标签
        const byBadge = us.locked && us.reason === 'badge';   // 等级够但缺徽章 → 正常显示 + 去考核

        // 底部 CTA 三态
        let cta;
        if (byLevel) {
          cta = el('span', { class: 'cta locked-cta', onClick: e => { e.stopPropagation(); openUnlockSheet(us.difficulty); } }, '查看解锁条件');
        } else if (byBadge) {
          cta = el('span', { class: 'cta need-exam', onClick: e => { e.stopPropagation(); navigate('training'); } }, '需通过 Lv.' + us.needLevel + ' 考核');
        } else {
          cta = el('span', { class: 'cta', onClick: e => { e.stopPropagation(); toast('已接单，请查看任务详情'); } }, '立即接单');
        }

        const card = el('div', { class: 'task-card' + (byLevel ? ' locked' : ''), onClick: () => { selectedTaskId = t.id; navigate('taskDetail'); } }, [
          el('div', { class: 'tc-top' }, [
            el('div', { class: 'tc-titlewrap' }, [
              el('span', { class: 'diff-chip ' + dcls }, us.difficulty),
              el('span', { class: 'tc-title' }, t.title)
            ]),
            el('span', { class: 'price-tag' }, '¥ ' + t.price)
          ]),
          byLevel ? el('div', { class: 'tc-lock-tag' }, [el('span', {}, '🔒'), el('span', {}, 'Lv.' + us.needLevel + ' 解锁')]) : null,
          el('div', { class: 'tc-desc' }, t.desc),
          el('div', { class: 'tc-meta' }, [
            el('span', { class: 'tc-badge source' }, '来自：' + t.source),
            el('span', { class: 'tc-badge ' + dlClass }, '剩余 ' + t.deadline),
            el('span', { class: 'tc-badge type' }, t.type)
          ]),
          el('div', { class: 'tc-progress' }, [
            el('span', {}, '已接 ' + t.taken + '/' + t.total),
            el('div', { class: 'bar' }, [el('div', { class: 'bar-fill', style: 'width:' + Math.round(t.taken / t.total * 100) + '%' })]),
            cta
          ])
        ]);
        listWrap.appendChild(card);
      });
      if (filtered.length === 0) {
        listWrap.appendChild(el('div', { style: 'text-align:center;padding:40px;color:var(--text-muted);font-size:13px' }, '暂无该分类任务'));
      }
    }
    renderList();
    s.appendChild(listWrap);

    return s;
  },

  /* ========== 任务详情 ========== */
  taskDetail() {
    const s = el('div', { class: 'screen' });

    // 当前任务（来自任务目录，支持从接单大厅点选任意任务）
    const TASK = TASKS_DB.find(t => t.id === selectedTaskId) || TASKS_DB[0];
    const totalQuota = TASK.total;
    const remainQuota = TASK.total - TASK.taken;

    const accepted = acceptedTasks.has(TASK.id);
    const submitted = submittedTasks.has(TASK.id);
    const us = unlockState(TASK); // 解锁状态（等级/徽章门槛）

    // 任务状态芯片（Hero 右上角）
    let statusChip;
    if (submitted) {
      statusChip = el('span', { class: 'hero-status-chip reviewing' }, '待审核');
    } else if (accepted) {
      statusChip = el('span', { class: 'hero-status-chip accepted' }, '已接单');
    } else if (remainQuota <= 0) {
      statusChip = el('span', { class: 'hero-status-chip expired' }, '名额已满');
    } else {
      statusChip = el('span', { class: 'hero-status-chip available' }, '可接单');
    }

    s.appendChild(topBar('任务详情', { forceBack: true, rightIco: '↗', onRight: () => toast('分享任务') }));

    // Hero 卡片
    s.appendChild(el('div', { class: 'detail-hero' }, [
      el('div', { style: 'display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:10px' }, [
        el('div', { class: 'dh-title', style: 'flex:1;margin-bottom:0' }, TASK.title),
        statusChip
      ]),
      el('div', { class: 'dh-price' }, [
        el('span', { class: 'price-tag lg' }, '¥ ' + TASK.price),
        el('span', { class: 'price-tag lg bonus' }, '+ ' + TASK.bonus + ' 积分')
      ]),
      el('div', { class: 'dh-source' }, [
        el('div', { class: 'dh-avatar' }, TASK.source[0]),
        el('span', {}, TASK.source),
        el('span', { class: 'dh-verified' }, '✓ 已认证')
      ])
    ]));

    // 未解锁提示卡（等级不足或徽章缺失）：frosted gold tint
    if (us.locked) {
      const needBadge = us.needBadge ? getBadge(us.needBadge) : null;
      s.appendChild(el('div', { class: 'unlock-hint glass', onClick: () => navigate(us.reason === 'level' ? 'creatorLevel' : 'training') }, [
        el('div', { class: 'uh-ico' }, '🔒'),
        el('div', { class: 'uh-mid' }, [
          el('div', { class: 'uh-title' }, '尚未解锁'),
          el('div', { class: 'uh-desc' }, '该任务需要 Lv.' + us.needLevel + (needBadge ? ' + ' + needBadge.name + '徽章' : ''))
        ]),
        el('div', { class: 'uh-btn' }, ['去提升 ', el('span', { class: 'caret' }, '›')])
      ]));
    }

    // 任务要求
    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { class: 'sc-title' }, '任务要求'),
      el('ul', { class: 'req-list' }, [
        el('li', {}, '图片尺寸：800×800px 以上，正方形比例（' + TASK.ratio + '）'),
        el('li', {}, '数量：' + TASK.count + ' 张不同角度'),
        el('li', {}, '风格：' + TASK.style + '，突出面料质感'),
        el('li', {}, '格式：JPG / PNG，单张不超过 5MB')
      ])
    ]));

    // 时间与名额
    const remainPercent = Math.round((totalQuota - remainQuota) / totalQuota * 100);
    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { class: 'sc-title' }, '时间与名额'),
      el('div', { class: 'time-grid' }, [
        el('div', { class: 'tg-col' }, [
          el('div', { class: 'tg-label' }, '截止时间'),
          el('div', { class: 'tg-val' }, TASK.deadlineFull),
          el('div', { class: 'tg-sub' }, '剩余 ' + TASK.deadline)
        ]),
        el('div', { class: 'tg-col' }, [
          el('div', { class: 'tg-label' }, '剩余名额'),
          el('div', { class: 'tg-val' }, remainQuota + ' / ' + totalQuota),
          el('div', { class: 'progress-thin', style: 'margin-top:8px' }, [
            el('div', { class: 'pt-fill', style: 'width:' + remainPercent + '%' })
          ])
        ])
      ]),
      el('div', { class: 'warn-strip' }, '即将截止，请尽快提交')
    ]));

    // 接单后显示当前任务状态卡
    if (submitted) {
      s.appendChild(el('div', { class: 'section-card', style: 'background:rgba(232,166,60,0.08);border-color:rgba(232,166,60,0.2)' }, [
        el('div', { style: 'display:flex;align-items:center;gap:10px' }, [
          el('span', { style: 'font-size:20px' }, '🕐'),
          el('div', { style: 'flex:1' }, [
            el('div', { style: 'font-size:13px;font-weight:600;color:#B8860B' }, '作品已提交，等待审核'),
            el('div', { style: 'font-size:11px;color:var(--text-muted);margin-top:2px' }, '预计 24 小时内出结果')
          ]),
          el('span', { style: 'font-size:12px;color:var(--sage);font-weight:600;cursor:pointer', onClick: () => navigate('submitStatus') }, '查看 ›')
        ])
      ]));
    } else if (accepted) {
      s.appendChild(el('div', { class: 'section-card', style: 'background:rgba(124,154,126,0.06);border-color:rgba(124,154,126,0.18)' }, [
        el('div', { style: 'display:flex;align-items:center;gap:10px' }, [
          el('span', { style: 'font-size:20px;color:var(--sage)' }, '✓'),
          el('div', { style: 'flex:1' }, [
            el('div', { style: 'font-size:13px;font-weight:600;color:var(--sage)' }, '已接单，任务进行中'),
            el('div', { style: 'font-size:11px;color:var(--text-muted);margin-top:2px' }, '可前往工作台继续创作并提交')
          ])
        ])
      ]));
    }

    // 底部固定栏（两态）
    const bar = el('div', { class: 'bottom-action-bar' });
    const caption = el('div', { style: 'text-align:center;font-size:11px;color:var(--text-muted);padding:8px 20px 16px' });

    function renderBar() {
      bar.innerHTML = '';
      caption.innerHTML = '';

      const unavailable = remainQuota <= 0;

      if (us.locked) {
        // 未解锁 → 禁用「去创作」，文案改为「尚未解锁」
        bar.appendChild(el('div', { class: 'bab-info' }, [
          '解锁后可得 ',
          el('strong', {}, '¥' + TASK.price + ' + ' + TASK.bonus + '积分')
        ]));
        bar.appendChild(el('button', { class: 'btn-gradient disabled', onClick: () => openUnlockSheet(us.difficulty) }, '尚未解锁'));
        caption.appendChild(document.createTextNode(us.reason === 'level' ? ('达到 Lv.' + us.needLevel + ' 后可接取该任务') : ('通过 Lv.' + us.needLevel + ' 考核获得徽章后可接取')));
      } else if (submitted) {
        // 已提交 → 查看审核进度
        bar.appendChild(el('div', { class: 'bab-info' }, [
          '任务状态 ',
          el('strong', {}, '待审核')
        ]));
        bar.appendChild(el('button', {
          class: 'btn-gradient',
          onClick: () => navigate('submitStatus')
        }, '查看审核进度'));
        caption.appendChild(document.createTextNode('发布方预计 24 小时内完成审核'));
      } else if (accepted) {
        // 已接单 → 继续创作（不重复扣名额）
        bar.appendChild(el('div', { class: 'bab-info' }, [
          '任务进行中 · ',
          el('strong', {}, '剩余 ' + TASK.deadline)
        ]));
        bar.appendChild(el('button', {
          class: 'btn-gradient',
          onClick: () => {
            // 直接回到工作台，不重复弹层确认
            activeTaskContext = TASK;
            contextBarHidden = false;
            navigate('imageGen');
          }
        }, '继续创作'));
        caption.appendChild(document.createTextNode('回到工作台时会保留任务上下文与参数预设'));
      } else {
        // 未接单 → 去创作（主 CTA）
        bar.appendChild(el('div', { class: 'bab-info' }, [
          '完成后可得 ',
          el('strong', {}, '¥' + TASK.price + ' + ' + TASK.bonus + '积分')
        ]));
        bar.appendChild(el('button', {
          class: 'btn-gradient',
          onClick: () => {
            openConfirmSheet({
              task: TASK,
              unavailable,
              unavailableReason: unavailable ? '该任务名额已满，看看其他任务吧' : '',
              onConfirm: () => {
                // 接单成功：写入全局状态 + 瞬时反馈 + 跳转工作台
                acceptedTasks.set(TASK.id, Date.now());
                activeTaskContext = TASK;
                contextBarHidden = false;
                successToast('接单成功，正在进入工作台…', 800);
                setTimeout(() => navigate('imageGen'), 500);
              }
            });
          }
        }, unavailable ? '名额已满' : '去创作'));
        caption.appendChild(document.createTextNode(
          unavailable ? '可看看其他同类任务'
                      : '点击后将接取任务并进入生图工作台'
        ));
      }
    }
    renderBar();
    s.appendChild(bar);
    s.appendChild(caption);

    return s;
  },

  /* ========== 提交状态页 ========== */
  submitStatus() {
    const s = el('div', { class: 'screen' });
    let state = 'pending'; // pending | success | rejected

    s.appendChild(topBar('提交状态', { forceBack: true, rightIco: '', onRight: () => {} }));

    const content = el('div');
    function renderState() {
      content.innerHTML = '';
      if (state === 'pending') {
        content.appendChild(el('div', { class: 'status-center' }, [
          el('div', { class: 'status-icon pending' }, '🕐'),
          el('div', { class: 'status-title' }, '作品已提交'),
          el('div', { class: 'status-sub' }, '发布方正在审核，预计 24 小时内出结果'),
          el('div', { class: 'status-note' }, '审核期间可在「接单记录」查看进度'),
          el('div', { class: 'status-btns' }, [
            el('button', { class: 'btn-gradient', onClick: () => navigate('taskHistory') }, '查看接单记录'),
            el('button', { class: 'btn-outline', onClick: () => switchTab('taskMarket') }, '继续接单')
          ])
        ]));
      } else if (state === 'success') {
        content.appendChild(el('div', { class: 'status-center' }, [
          el('div', { class: 'status-icon success' }, '✓'),
          el('div', { class: 'status-title' }, '任务已完成'),
          el('div', { class: 'status-sub' }, '审核通过，奖励已发放'),
          el('div', { class: 'reward-card' }, [
            el('div', { class: 'reward-row' }, [
              el('span', {}, '现金奖励'),
              el('span', {}, [el('span', { class: 'rr-val sage' }, '¥ 28.00'), el('span', { class: 'rr-chip' }, '已入荷包')])
            ]),
            el('div', { class: 'reward-row' }, [
              el('span', {}, '积分奖励'),
              el('span', {}, [el('span', { class: 'rr-val gold' }, '+ 50 积分'), el('span', { class: 'rr-chip' }, '已到账')])
            ]),
            el('div', { class: 'reward-row' }, [
              el('span', {}, '经验奖励'),
              el('span', {}, [el('span', { class: 'rr-val', style: 'color:var(--sage)' }, '+ 50 经验'), el('span', { class: 'rr-chip' }, '等级进度已更新')])
            ]),
            el('div', { class: 'reward-row' }, [
              el('span', {}, '当前荷包余额'),
              el('span', { class: 'rr-val', style: 'cursor:pointer;color:var(--sage)', onClick: () => navigate('wallet') }, '¥ 156.00 查看 ›')
            ])
          ]),
          el('div', { class: 'status-btns' }, [
            el('button', { class: 'btn-gradient', onClick: () => switchTab('taskMarket') }, '继续接单'),
            el('button', { class: 'btn-outline', onClick: () => navigate('wallet') }, '查看我的荷包')
          ])
        ]));
      } else {
        content.appendChild(el('div', { class: 'status-center' }, [
          el('div', { class: 'status-icon rejected' }, '✗'),
          el('div', { class: 'status-title' }, '作品被驳回'),
          el('div', { class: 'status-sub' }, '发布方未通过审核，可申诉或修改后重新提交'),
          el('div', { class: 'reject-card' }, [
            el('div', { class: 'rc-title' }, '驳回原因'),
            el('div', { class: 'rc-text' }, '图片背景不够纯净，有轻微阴影残留。请重新抠图后上传，确保背景为纯白 #FFFFFF。')
          ]),
          el('div', { class: 'status-btns' }, [
            el('button', { class: 'btn-gradient', onClick: () => { state = 'pending'; renderState(); successToast('申诉已提交，回到待审核', 900); } }, '申诉 / 重新提交'),
            el('button', { class: 'btn-outline', onClick: () => { toast('订单已关闭，扣除 30 经验'); switchTab('taskMarket'); } }, '放弃并关闭')
          ]),
          el('div', { class: 'status-note' }, '申诉成功 → 回到「待审核」；申诉失败 → 订单关闭并扣除 30 经验')
        ]));
      }
    }
    renderState();
    s.appendChild(content);

    // 演示状态切换（仅预览器用）
    s.appendChild(el('div', { style: 'padding:20px;display:flex;gap:8px;justify-content:center' }, [
      el('button', { class: 'btn-outline', style: 'font-size:11px;padding:6px 12px', onClick: () => { state = 'pending'; renderState(); } }, '状态A:待审核'),
      el('button', { class: 'btn-outline', style: 'font-size:11px;padding:6px 12px', onClick: () => { state = 'success'; renderState(); } }, '状态B:通过'),
      el('button', { class: 'btn-outline', style: 'font-size:11px;padding:6px 12px', onClick: () => { state = 'rejected'; renderState(); } }, '状态C:驳回')
    ]));

    return s;
  },

  /* ========== 接单记录 ========== */
  taskHistory() {
    const s = el('div', { class: 'screen' });
    const TABS = ['进行中', '待审核', '已完成', '未通过'];
    let activeTab = 0;
    const RECORDS = [
      { title: '夏季新品女装商品主图', source: '星辰电商', date: '09-15', status: '进行中', statusClass: 'ongoing', amount: '¥28', route: 'taskDetail' },
      { title: '美妆产品旋转展示视频', source: '花漾美妆', date: '09-14', status: '待审核', statusClass: 'reviewing', amount: '¥65', route: 'submitStatus' },
      { title: '智能家居场景宣传图', source: '智居科技', date: '09-12', status: '已完成', statusClass: 'done', amount: '¥45 +80积分', route: 'submitStatus' },
      { title: '食品类日本站主图套组', source: '东瀛优品', date: '09-10', status: '未通过', statusClass: 'failed', amount: '—', route: 'submitStatus' }
    ];

    s.appendChild(topBar('接单记录', { forceBack: true, rightIco: '▽', onRight: () => toast('筛选') }));

    const seg = el('div', { class: 'seg-control' });
    const listWrap = el('div');
    function render() {
      seg.innerHTML = '';
      TABS.forEach((t, i) => {
        seg.appendChild(el('div', {
          class: 'seg-item' + (i === activeTab ? ' active' : ''),
          onClick: () => { activeTab = i; render(); }
        }, t));
      });
      listWrap.innerHTML = '';
      const filtered = RECORDS.filter(r => r.status === TABS[activeTab]);
      if (filtered.length === 0) {
        listWrap.appendChild(el('div', { style: 'text-align:center;padding:40px;color:var(--text-muted);font-size:13px' }, '暂无记录'));
      }
      filtered.forEach(r => {
        listWrap.appendChild(el('div', { class: 'task-row', onClick: () => navigate(r.route) }, [
          el('div', { class: 'tr-thumb' }, '🖼'),
          el('div', { class: 'tr-mid' }, [
            el('div', { class: 'tr-title' }, r.title),
            el('div', { class: 'tr-sub' }, r.source + ' · ' + r.date)
          ]),
          el('div', { class: 'tr-right' }, [
            el('span', { class: 'status-chip ' + r.statusClass }, r.status),
            el('div', { class: 'tr-amount' }, r.amount)
          ])
        ]));
      });
    }
    render();
    s.appendChild(seg);
    s.appendChild(listWrap);

    return s;
  },

  /* ========== 我的荷包 ========== */
  wallet() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('我的荷包', { forceBack: true, rightIco: '☰', onRight: () => navigate('taskHistory') }));

    // 余额卡
    s.appendChild(el('div', { class: 'wallet-hero' }, [
      el('div', { class: 'wh-label' }, '可提现余额'),
      el('div', { class: 'wh-balance' }, '¥ 156.00'),
      el('div', { class: 'wh-chips' }, [
        el('span', { class: 'wh-chip sage' }, '累计赚取 ¥ 892'),
        el('span', { class: 'wh-chip amber' }, '待结算 ¥ 64')
      ]),
      el('div', { class: 'wh-btns' }, [
        el('button', { class: 'btn-gradient', onClick: () => navigate('withdraw') }, '提现'),
        el('button', { class: 'btn-outline', onClick: () => navigate('buyCredits') }, '购买算力积分')
      ])
    ]));

    // 积分
    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { style: 'display:flex;align-items:center;justify-content:space-between' }, [
        el('div', {}, [
          el('div', { class: 'sc-title', style: 'margin-bottom:4px' }, '算力积分'),
          el('div', { style: 'font-size:20px;font-weight:700;color:var(--charcoal)' }, '1,250 分')
        ]),
        el('span', { style: 'font-size:12px;color:var(--sage);font-weight:600;cursor:pointer', onClick: () => navigate('buyCredits') }, '充值 / 兑换 ›')
      ]),
      el('div', { class: 'progress-thin', style: 'margin-top:12px' }, [
        el('div', { class: 'pt-fill gold', style: 'width:83%' })
      ]),
      el('div', { style: 'font-size:11px;color:var(--text-muted);margin-top:6px' }, '距离下一档会员还差 250 分')
    ]));

    // 收益构成
    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { class: 'sc-title' }, '收益构成'),
      el('div', { class: 'earning-row' }, [el('span', {}, '接单现金'), el('span', { class: 'er-val' }, '¥ 780')]),
      el('div', { class: 'earning-row' }, [el('span', {}, '邀请佣金'), el('span', { class: 'er-val' }, '¥ 80')]),
      el('div', { class: 'earning-row' }, [el('span', {}, '活动奖励'), el('span', { class: 'er-val' }, '¥ 32')])
    ]));

    // 最近收益
    const recent = [
      { title: '夏季新品女装商品主图', date: '09-15', amount: '+¥28' },
      { title: '智能家居场景宣传图', date: '09-12', amount: '+¥45' },
      { title: '跨境电商英文配音', date: '09-10', amount: '+¥35' }
    ];
    const recentCard = el('div', { class: 'section-card' }, [
      el('div', { class: 'sc-title' }, '最近收益')
    ]);
    recent.forEach(r => {
      recentCard.appendChild(el('div', { class: 'earning-row' }, [
        el('div', {}, [
          el('div', { style: 'font-size:13px;color:var(--charcoal)' }, r.title),
          el('div', { style: 'font-size:11px;color:var(--text-muted);margin-top:2px' }, r.date)
        ]),
        el('span', { style: 'font-weight:600;color:var(--sage);font-size:14px' }, r.amount)
      ]));
    });
    recentCard.appendChild(el('div', { style: 'text-align:center;margin-top:10px;font-size:12px;color:var(--sage);cursor:pointer;font-weight:500', onClick: () => toast('查看全部收益') }, '查看全部 ›'));
    s.appendChild(recentCard);

    return s;
  },

  /* ========== 提现 ========== */
  withdraw() {
    const s = el('div', { class: 'screen' });
    let method = 0;
    const METHODS = [
      { ico: '💬', name: '微信零钱', sub: '已绑定尾号 8856', bg: '#07C160' },
      { ico: '🅰', name: '支付宝', sub: '已绑定 tail***@163.com', bg: '#1677FF' },
      { ico: '🏦', name: '银行卡', sub: '工商银行 尾号 6622', bg: '#C0392B' }
    ];

    s.appendChild(topBar('提现', { forceBack: true }));

    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { style: 'font-size:13px;color:var(--text-muted);margin-bottom:4px' }, '可提现金额'),
      el('div', { style: 'font-size:32px;font-weight:700;color:var(--charcoal);margin-bottom:16px' }, '¥ 156.00'),
      el('div', { style: 'font-size:13px;font-weight:600;color:var(--charcoal);margin-bottom:10px' }, '提现方式')
    ]));

    const methodWrap = el('div', { style: 'margin-bottom:16px' });
    function renderMethods() {
      methodWrap.innerHTML = '';
      METHODS.forEach((m, i) => {
        methodWrap.appendChild(el('div', {
          class: 'withdraw-method' + (i === method ? ' active' : ''),
          onClick: () => { method = i; renderMethods(); }
        }, [
          el('div', { class: 'wm-ico', style: 'background:' + m.bg + '20;color:' + m.bg }, m.ico),
          el('div', {}, [
            el('div', { class: 'wm-name' }, m.name),
            el('div', { class: 'wm-sub' }, m.sub)
          ]),
          el('span', { class: 'wm-check' }, '✓')
        ]));
      });
    }
    renderMethods();
    s.appendChild(methodWrap);

    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { class: 'amount-row' }, [
        el('span', { style: 'font-size:13px;font-weight:600;color:var(--charcoal)' }, '提现金额'),
        el('span', { class: 'ar-all', onClick: () => { const inp = s.querySelector('.amount-input'); if (inp) inp.value = '156.00'; } }, '全部提现')
      ]),
      el('input', { class: 'amount-input', type: 'number', placeholder: '0.00', value: '' }),
      el('div', { class: 'fee-note' }, '到账时间：预计 2 小时内\n单笔满 ¥10 免手续费，低于 ¥10 收取 ¥1')
    ]));

    s.appendChild(el('div', { class: 'bottom-action-bar' }, [
      el('div', {}),
      el('button', { class: 'btn-gradient', onClick: () => toast('提现申请已提交') }, '确认提现')
    ]));
    s.appendChild(el('div', { style: 'text-align:center;font-size:11px;color:var(--text-muted);padding:8px 20px 16px' },
      '提现即表示同意《提现服务协议》'));

    return s;
  },

  /* ========== 购买算力积分 ========== */
  buyCredits() {
    const s = el('div', { class: 'screen' });
    let selectedPkg = 1;
    let payMethod = 0;
    const PKGS = [
      { amount: '100', price: '¥ 6', tag: '' },
      { amount: '500', price: '¥ 25', tag: '热门' },
      { amount: '1,200', price: '¥ 55', tag: '省 12%' },
      { amount: '3,000', price: '¥ 120', tag: '最划算' }
    ];
    const PAYS = ['荷包余额 ¥156.00', '微信支付', '支付宝', 'Apple Pay'];

    s.appendChild(topBar('购买算力积分', { forceBack: true }));

    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { style: 'display:flex;align-items:baseline;gap:8px' }, [
        el('span', { style: 'font-size:13px;color:var(--text-muted)' }, '当前积分'),
        el('span', { style: 'font-size:20px;font-weight:700;color:var(--charcoal)' }, '1,250 分')
      ]),
      el('div', { style: 'font-size:11px;color:var(--text-muted);margin-top:4px' }, '1 积分 ≈ 1 次普通生图')
    ]));

    // 套餐网格
    const grid = el('div', { class: 'credit-grid' });
    function renderGrid() {
      grid.innerHTML = '';
      PKGS.forEach((p, i) => {
        const card = el('div', {
          class: 'credit-card' + (i === selectedPkg ? ' active' : ''),
          onClick: () => { selectedPkg = i; renderGrid(); }
        }, [
          el('div', { class: 'cc-amount' }, p.amount),
          el('div', { class: 'cc-unit' }, '积分'),
          el('div', { class: 'cc-price' }, p.price)
        ]);
        if (p.tag) card.appendChild(el('span', { class: 'cc-tag' }, p.tag));
        grid.appendChild(card);
      });
    }
    renderGrid();
    s.appendChild(grid);

    // 支付方式
    s.appendChild(el('div', { class: 'section-card', style: 'padding:12px' }, [
      el('div', { class: 'sc-title' }, '支付方式')
    ]));
    const payWrap = el('div', { style: 'margin-bottom:16px' });
    function renderPays() {
      payWrap.innerHTML = '';
      PAYS.forEach((p, i) => {
        payWrap.appendChild(el('div', {
          class: 'pay-row' + (i === payMethod ? ' active' : ''),
          onClick: () => { payMethod = i; renderPays(); }
        }, [
          el('span', {}, p),
          el('span', { class: 'pr-check' }, '✓')
        ]));
      });
    }
    renderPays();
    s.appendChild(payWrap);

    s.appendChild(el('div', { class: 'bottom-action-bar' }, [
      el('div', { class: 'bab-info' }, ['合计 ', el('strong', {}, PKGS[selectedPkg].price)]),
      el('button', { class: 'btn-gradient', onClick: () => toast('购买成功！积分已到账') }, '立即购买')
    ]));
    s.appendChild(el('div', { style: 'text-align:center;font-size:11px;color:var(--text-muted);padding:8px 20px 16px' },
      '积分不可提现，可用于图片 / 视频 / 音频生成'));

    return s;
  },

  /* ========== 创作者等级 ========== */
  creatorLevel() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('创作者等级', { forceBack: true, rightIco: '?', onRight: () => navigate('expRules') }));
    const lv = CREATOR.level;
    const nextExp = LEVEL_EXP[lv + 1] || LEVEL_EXP[10];
    const remain = Math.max(0, nextExp - CREATOR.exp);
    const pct = Math.min(100, Math.round(CREATOR.exp / nextExp * 100));

    s.appendChild(el('div', { class: 'level-hero glass' }, [
      el('div', { class: 'lh-top' }, [
        el('div', { class: 'lh-badge', html: levelBadgeSVG(lv, 72) }),
        el('div', { class: 'lh-info' }, [
          el('div', { class: 'lh-title' }, 'Lv.' + lv + ' ' + LEVEL_TITLES[lv]),
          el('div', { class: 'lh-exp' }, CREATOR.exp.toLocaleString() + ' / ' + nextExp.toLocaleString()),
          el('div', { class: 'progress-thin' }, [el('div', { class: 'pt-fill', style: 'width:' + pct + '%' })]),
          el('div', { class: 'lh-next' }, '距离 Lv.' + (lv + 1) + ' 还需 ' + remain + ' 经验')
        ])
      ]),
      el('div', { class: 'lh-stats' }, [
        el('span', { class: 'lh-chip' }, '已完成 ' + CREATOR.completed + ' 单'),
        el('span', { class: 'lh-chip' }, '好评率 ' + CREATOR.approvalRate + '%'),
        el('span', { class: 'lh-chip' }, '徽章 ' + CREATOR.badges.length + ' 枚')
      ]),
      el('div', { class: 'lh-cert', onClick: () => navigate('training') }, [
        el('span', { class: 'lh-cert-ico' }, '🎓'),
        el('div', { style: 'flex:1;min-width:0' }, [
          el('div', { class: 'lh-cert-t' }, 'Lv.6 考核认证'),
          el('div', { class: 'lh-cert-s' }, '通过考核解锁专业难度订单')
        ]),
        el('span', { class: 'lh-cert-btn' }, '前往认证 ›')
      ])
    ]));

    const card = el('div', { class: 'section-card' }, [el('div', { class: 'sc-title' }, '等级特权')]);
    const curBand = privBandIndex(lv);
    PRIVILEGES.forEach((p, i) => {
      const unlocked = lv >= p.lv;
      const isCur = i === curBand;
      card.appendChild(el('div', { class: 'priv-row' + (isCur ? ' current' : '') + (unlocked ? '' : ' locked') }, [
        el('div', { class: 'priv-badge', html: levelBadgeSVG(p.lv, 30) }),
        el('div', { class: 'priv-mid' }, [
          el('div', { class: 'priv-band' }, p.band),
          el('div', { class: 'priv-label' }, '可接: ' + p.label)
        ]),
        el('div', { class: 'priv-right' }, [
          isCur ? el('span', { class: 'priv-cur-chip' }, '当前') : null,
          el('span', { class: 'priv-range' }, (unlocked ? '' : '🔒 ') + p.range)
        ])
      ]));
    });
    s.appendChild(card);

    s.appendChild(el('div', { class: 'me-item', style: 'margin-top:12px', onClick: () => navigate('badgeWall') }, [
      el('div', { class: 'ico' }, '🏅'), el('div', { class: 'name' }, '我的徽章'),
      el('div', { class: 'caret' }, '›')
    ]));
    return s;
  },

  /* ========== 经验规则 ========== */
  expRules() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('经验规则', { forceBack: true }));

    const gain = [['✓', '完成订单（发布方确认）', '+50'], ['★', '订单获好评', '+20'], ['🎓', '首次通过考核', '+200'], ['🔥', '连续 7 天完成订单', '+100'], ['🤝', '邀请好友接单成功', '+80']];
    const c1 = el('div', { class: 'section-card' }, [el('div', { class: 'sc-title' }, '如何获得经验')]);
    gain.forEach(([ico, txt, val]) => {
      c1.appendChild(el('div', { class: 'exp-row' }, [
        el('span', { class: 'exp-ico' }, ico),
        el('span', { class: 'exp-txt' }, txt),
        el('span', { class: 'exp-val gain' }, val + ' 经验')
      ]));
    });
    s.appendChild(c1);

    const lose = [['⚠', '订单被驳回且申诉失败', '-30'], ['⏰', '超时未提交', '-20']];
    const c2 = el('div', { class: 'section-card warn-card' }, [el('div', { class: 'sc-title' }, '经验扣减')]);
    lose.forEach(([ico, txt, val]) => {
      c2.appendChild(el('div', { class: 'exp-row' }, [
        el('span', { class: 'exp-ico' }, ico),
        el('span', { class: 'exp-txt' }, txt),
        el('span', { class: 'exp-val lose' }, val + ' 经验')
      ]));
    });
    s.appendChild(c2);

    const c3 = el('div', { class: 'section-card' }, [el('div', { class: 'sc-title' }, '等级对照表')]);
    const tbl = el('div', { class: 'lvl-table' });
    tbl.appendChild(el('div', { class: 'lt-row lt-head' }, [
      el('span', {}, '等级'), el('span', {}, '所需经验'), el('span', {}, '可接难度'), el('span', {}, '考核')
    ]));
    [['Lv.1', '0', '基础', false], ['Lv.4', '1,700', '进阶', false], ['Lv.6', '3,000', '专业', true], ['Lv.9', '7,200', '旗舰', true]].forEach(([lvv, expv, diffv, need]) => {
      tbl.appendChild(el('div', { class: 'lt-row' + (need ? ' need' : '') }, [
        el('span', {}, lvv), el('span', {}, expv), el('span', {}, diffv),
        el('span', { class: 'lt-exam' }, need ? '🔒 需考核' : '—')
      ]));
    });
    c3.appendChild(tbl);
    s.appendChild(c3);
    return s;
  },

  /* ========== 我的徽章 ========== */
  badgeWall() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('我的徽章', { forceBack: true, rightIco: '↗', onRight: () => toast('分享徽章墙') }));
    const earned = BADGES.filter(b => CREATOR.badges.includes(b.id));
    const locked = BADGES.filter(b => !CREATOR.badges.includes(b.id));
    const pct = Math.round(earned.length / BADGES.length * 100);

    s.appendChild(el('div', { class: 'badge-hero glass' }, [
      el('div', { class: 'bh-title' }, '已获得 ' + earned.length + ' / ' + BADGES.length + ' 枚徽章'),
      el('div', { class: 'progress-thin' }, [el('div', { class: 'pt-fill gold', style: 'width:' + pct + '%' })])
    ]));

    function cell(b, isEarned) {
      return el('div', { class: 'badge-cell' + (isEarned ? '' : ' locked'), onClick: () => { selectedBadgeId = b.id; navigate('badgeDetail'); } }, [
        el('div', { class: 'bc-icon ' + b.tier }, [
          el('span', { class: 'bc-glyph' }, b.icon),
          isEarned ? null : el('span', { class: 'bc-lock' }, '🔒')
        ]),
        el('div', { class: 'bc-name' }, b.name),
        el('div', { class: 'bc-date' }, isEarned ? b.date : b.cond)
      ]);
    }

    const c1 = el('div', { class: 'section-card' }, [el('div', { class: 'sc-title' }, '已获得')]);
    const g1 = el('div', { class: 'badge-grid' });
    earned.forEach(b => g1.appendChild(cell(b, true)));
    c1.appendChild(g1);
    s.appendChild(c1);

    const c2 = el('div', { class: 'section-card' }, [el('div', { class: 'sc-title' }, '待解锁')]);
    const g2 = el('div', { class: 'badge-grid' });
    locked.forEach(b => g2.appendChild(cell(b, false)));
    c2.appendChild(g2);
    s.appendChild(c2);
    return s;
  },

  /* ========== 徽章详情 ========== */
  badgeDetail() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('徽章详情', { forceBack: true }));
    const b = getBadge(selectedBadgeId) || BADGES[0];
    const earned = CREATOR.badges.includes(b.id);

    s.appendChild(el('div', { class: 'bd-hero' }, [
      el('div', { class: 'bd-badge ' + b.tier + (earned ? '' : ' locked') }, el('span', {}, b.icon)),
      el('div', { class: 'bd-name' }, b.name),
      el('div', { class: 'bd-date' }, earned ? ('获得于 ' + b.date) : ('未获得 · ' + b.cond))
    ]));

    const c1 = el('div', { class: 'section-card' }, [el('div', { class: 'sc-title' }, '解锁能力')]);
    b.abilities.forEach(a => c1.appendChild(el('div', { class: 'ability-row' }, [el('span', { class: 'ab-dot' }, '✦'), el('span', {}, a)])));
    s.appendChild(c1);

    if (!earned) {
      const c2 = el('div', { class: 'section-card' }, [el('div', { class: 'sc-title' }, '如何获得')]);
      c2.appendChild(el('div', { class: 'howto-row' }, [
        el('span', { style: 'flex:1' }, b.cond),
        el('button', { class: 'btn-outline sm', onClick: () => navigate((b.id === 'pro' || b.id === 'master') ? 'training' : 'taskMarket') }, '去完成')
      ]));
      s.appendChild(c2);
    }

    s.appendChild(el('div', { class: 'bottom-action-bar' }, [
      el('button', { class: 'btn-gradient', style: 'width:100%', onClick: () => toast('徽章分享链接已复制') }, '分享徽章')
    ]));
    return s;
  },

  /* ========== 培训报名 ========== */
  training() {
    const s = el('div', { class: 'screen' });
    const pendingCount = myRegistrations.filter(r => r.status === 'pending').length;
    const tb = topBar('培训报名', { forceBack: true, rightIco: '🎫', onRight: () => navigate('myRegistrations') });
    const act = tb.querySelector('.act');
    if (act) { act.style.position = 'relative'; if (pendingCount) act.appendChild(el('span', { class: 'act-badge' }, String(pendingCount))); }
    s.appendChild(tb);

    // Hero banner
    s.appendChild(el('div', { class: 'train-hero glass' }, [
      el('div', { class: 'th-title' }, 'Lv.6 考核培训'),
      el('div', { class: 'th-desc' }, '通过考核可获得「专业创作者」徽章，解锁专业难度订单'),
      el('div', { class: 'th-meta' }, '线下 · 2 天 · 城市可选')
    ]));

    // 衔接进度流程图（3 节点 + 箭头，当前高亮）
    function flowNode(title, sub, active) {
      return el('div', { class: 'gf-node' + (active ? ' active' : '') }, [
        el('div', { class: 'gf-dot' }),
        el('div', { class: 'gf-t' }, title),
        sub ? el('div', { class: 'gf-s' }, sub) : null
      ]);
    }
    s.appendChild(el('div', { class: 'growth-flow' }, [
      flowNode('当前 Lv.5', null, true),
      el('span', { class: 'gf-arrow' }, '→'),
      flowNode('通过培训考核', 'Lv.6 + 专业徽章', false),
      el('span', { class: 'gf-arrow' }, '→'),
      flowNode('解锁专业订单', null, false)
    ]));

    // 可报名场次
    s.appendChild(el('div', { class: 'section-title' }, el('span', {}, '可报名场次')));
    const listWrap = el('div');
    function doRegister(sess) {
      const code = sess.id + '-' + String(sess.enrolled + 1).padStart(3, '0');
      lastRegCode = code;
      myRegistrations.unshift({ code, city: sess.city, term: sess.term, date: sess.date, addr: sess.addr, teacher: sess.teacher, status: 'pending' });
      sess.enrolled = Math.min(sess.quota, sess.enrolled + 1);
      successToast('报名成功', 700);
      setTimeout(() => navigate('regSuccess'), 380);
    }
    function renderSessions() {
      listWrap.innerHTML = '';
      TRAINING.sessions.forEach(sess => {
        const remain = sess.quota - sess.enrolled;
        const full = remain <= 0;
        const tight = remain > 0 && remain < 5;
        const selected = selectedSessionId === sess.id;
        const pctEnr = Math.round(sess.enrolled / sess.quota * 100);
        listWrap.appendChild(el('div', {
          class: 'sess-card' + (full ? ' full' : '') + (selected ? ' selected' : ''),
          onClick: () => { if (!full) { selectedSessionId = sess.id; renderSessions(); renderBottom(); } }
        }, [
          el('div', { class: 'sess-top' }, [
            el('span', { class: 'sess-city' }, sess.city + ' · ' + sess.term),
            full ? el('span', { class: 'sess-flag full' }, '已满员') : (tight ? el('span', { class: 'sess-flag tight' }, '仅剩 ' + remain + ' 席') : null)
          ]),
          el('div', { class: 'sess-date' }, sess.date),
          el('div', { class: 'sess-addr' }, [
            el('span', {}, sess.addr),
            el('span', { class: 'sess-map', onClick: e => { e.stopPropagation(); toast('打开地图 App'); } }, '📍 地图')
          ]),
          el('div', { class: 'sess-teacher' }, [
            el('span', { class: 'st-avatar' }, sess.teacher[0]),
            el('span', {}, sess.teacher + ' · ' + sess.teacherTitle)
          ]),
          el('div', { class: 'sess-quota' }, el('span', {}, '已报名 ' + sess.enrolled + ' / ' + sess.quota)),
          el('div', { class: 'progress-thin' + (tight ? ' amber' : '') }, [el('div', { class: 'pt-fill' + (tight ? ' amber' : ''), style: 'width:' + pctEnr + '%' })]),
          el('div', { class: 'sess-bottom' }, [
            el('div', { class: 'sess-fee' }, [
              el('span', { class: 'sf-val' + (sess.fee === 0 ? ' free' : '') }, sess.fee === 0 ? '免费' : '¥ ' + sess.fee),
              sess.deposit ? el('span', { class: 'sf-note' }, '通过考核后全额返还') : null
            ]),
            el('button', {
              class: full ? 'btn-outline sm' : 'btn-gradient sm',
              onClick: e => { e.stopPropagation(); if (full) toast('已加入候补登记'); else { selectedSessionId = sess.id; doRegister(sess); } }
            }, full ? '候补登记' : '立即报名')
          ])
        ]));
      });
    }

    // 底部固定 bar
    const bottomBar = el('div', { class: 'train-bottom' });
    function renderBottom() {
      bottomBar.innerHTML = '';
      const sel = TRAINING.sessions.find(x => x.id === selectedSessionId);
      bottomBar.appendChild(el('div', { class: 'trb-info' }, sel ? ('已选：' + sel.city + ' · ' + sel.term) : '选择场次后可报名'));
      bottomBar.appendChild(el('button', { class: 'btn-gradient' + (sel ? '' : ' disabled'), onClick: () => { if (sel) doRegister(sel); } }, '立即报名'));
    }

    // 报名须知（折叠）
    let noticeOpen = false;
    const noticeFull = ['需携带身份证 + 手机（用于签到和考核）', '培训期间需全程参与，缺席超过 2 小时取消考核资格', '考核在培训第二天下午进行，当场出结果', '未通过者可在下一期免费重听一次', '培训期间食宿自理'];
    const noticeCard = el('div', { class: 'section-card notice-card' });
    function renderNotice() {
      noticeCard.innerHTML = '';
      noticeCard.appendChild(el('div', { class: 'notice-head' }, [
        el('span', { class: 'sc-title', style: 'margin:0' }, '报名须知'),
        el('span', { class: 'notice-toggle', onClick: () => { noticeOpen = !noticeOpen; renderNotice(); } }, noticeOpen ? '收起 ▴' : '展开 ▾')
      ]));
      const ul = el('ul', { class: 'notice-list' });
      (noticeOpen ? noticeFull : noticeFull.slice(0, 3)).forEach(n => ul.appendChild(el('li', {}, n)));
      noticeCard.appendChild(ul);
    }

    renderSessions(); renderBottom(); renderNotice();
    s.appendChild(listWrap);
    s.appendChild(noticeCard);
    s.appendChild(el('div', { style: 'height:64px' }));
    s.appendChild(bottomBar);
    return s;
  },

  /* ========== 报名成功 ========== */
  regSuccess() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('报名成功', { forceBack: true }));
    const reg = myRegistrations.find(r => r.code === lastRegCode) || myRegistrations[0];
    s.appendChild(el('div', { class: 'reg-success' }, [
      el('div', { class: 'rs-check' }, '✓'),
      el('div', { class: 'rs-title' }, '报名成功'),
      el('div', { class: 'rs-sub' }, reg.city + ' · ' + reg.term)
    ]));
    s.appendChild(ticketCardEl(reg));
    s.appendChild(el('div', { class: 'section-card' }, [
      el('div', { class: 'sc-title' }, '培训提醒'),
      el('div', { class: 'remind-row' }, '开课前 3 天会收到短信提醒'),
      el('div', { class: 'remind-row' }, '开课前 24 小时可免费取消，逾期取消不退费'),
      el('button', { class: 'btn-outline', style: 'width:100%;margin-top:10px', onClick: () => toast('已生成 .ics 日历事件') }, '添加到日历')
    ]));
    s.appendChild(el('div', { class: 'bottom-action-bar' }, [
      el('button', { class: 'btn-gradient', onClick: () => navigate('myRegistrations') }, '查看我的报名')
    ]));
    s.appendChild(el('div', { style: 'text-align:center;padding:4px 0 16px' }, el('button', { class: 'link-btn', onClick: () => switchTab('home') }, '返回首页')));
    return s;
  },

  /* ========== 我的报名 ========== */
  myRegistrations() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('我的报名', { forceBack: true }));
    const TABS = ['待参加', '已完成', '已取消'];
    let activeTab = 0;
    const seg = el('div', { class: 'seg-control' });
    const listWrap = el('div');
    function tabOf(r) { return r.status === 'cancelled' ? '已取消' : r.status === 'pending' ? '待参加' : '已完成'; }
    function render() {
      seg.innerHTML = '';
      TABS.forEach((t, i) => seg.appendChild(el('div', { class: 'seg-item' + (i === activeTab ? ' active' : ''), onClick: () => { activeTab = i; render(); } }, t)));
      listWrap.innerHTML = '';
      const filtered = myRegistrations.filter(r => tabOf(r) === TABS[activeTab]);
      if (!filtered.length) listWrap.appendChild(el('div', { style: 'text-align:center;padding:40px;color:var(--text-muted);font-size:13px' }, '暂无记录'));
      filtered.forEach(r => {
        const chip = regChip(r);
        const bottom = r.status === 'pending'
          ? [
            el('span', { class: 'reg-link', onClick: e => { e.stopPropagation(); selectedRegCode = r.code; navigate('regDetail'); } }, '查看凭证'),
            el('span', { class: 'reg-link danger', onClick: e => { e.stopPropagation(); r.status = 'cancelled'; render(); toast('已取消报名'); } }, '取消报名')
          ]
          : [
            el('span', { class: 'reg-link', onClick: e => { e.stopPropagation(); assessPass = (r.status === 'passed'); navigate('assessResult'); } }, '查看结果'),
            r.status === 'passed' ? el('span', { class: 'reg-link', onClick: e => { e.stopPropagation(); toast('徽章分享链接已复制'); } }, '分享徽章') : null
          ];
        listWrap.appendChild(el('div', { class: 'reg-card', onClick: () => { selectedRegCode = r.code; navigate('regDetail'); } }, [
          el('div', { class: 'reg-top' }, [
            el('span', { class: 'reg-city' }, r.city + ' · ' + r.term),
            el('span', { class: 'reg-chip ' + chip.cls }, [chip.medal ? el('span', { class: 'rc-medal' }, '🏅') : null, chip.txt])
          ]),
          el('div', { class: 'reg-mid' }, r.date + ' · ' + r.addr),
          el('div', { class: 'reg-bottom' }, bottom)
        ]));
      });
    }
    render();
    s.appendChild(seg);
    s.appendChild(listWrap);
    return s;
  },

  /* ========== 报名详情 ========== */
  regDetail() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('报名详情', { forceBack: true }));
    const reg = myRegistrations.find(r => r.code === selectedRegCode) || myRegistrations[0];
    const chip = regChip(reg);
    s.appendChild(el('div', { class: 'regd-head' }, [
      el('div', { class: 'regd-city' }, reg.city + ' · ' + reg.term),
      el('span', { class: 'reg-chip ' + chip.cls }, [chip.medal ? el('span', { class: 'rc-medal' }, '🏅') : null, chip.txt])
    ]));
    s.appendChild(ticketCardEl(reg));
    if (reg.status === 'passed' || reg.status === 'failed') {
      s.appendChild(el('div', { class: 'section-card' }, [
        el('div', { class: 'sc-title' }, '考核结果'),
        el('button', { class: 'btn-outline', style: 'width:100%', onClick: () => { assessPass = reg.status === 'passed'; navigate('assessResult'); } }, '查看考核结果详情')
      ]));
    }
    s.appendChild(el('div', { class: 'bottom-action-bar' }, [
      el('button', { class: 'btn-gradient', onClick: () => navigate('myRegistrations') }, '返回我的报名')
    ]));
    return s;
  },

  /* ========== 考核结果 ========== */
  assessResult() {
    const s = el('div', { class: 'screen' });
    s.appendChild(topBar('考核结果', { forceBack: true }));
    const content = el('div');
    function renderState() {
      content.innerHTML = '';
      if (assessPass) {
        content.appendChild(el('div', { class: 'assess-center pass' }, [
          el('div', { class: 'as-badge', html: levelBadgeSVG(6, 96) }),
          el('div', { class: 'as-title' }, '考核通过'),
          el('div', { class: 'as-sub' }, '恭喜获得「专业创作者」徽章'),
          el('div', { class: 'as-score' }, [el('span', { class: 'as-num' }, '92'), el('span', { class: 'as-unit' }, '分 · 用时 38 分钟')])
        ]));
        content.appendChild(el('div', { class: 'section-card' }, [
          el('div', { class: 'sc-title' }, '新解锁能力'),
          el('div', { class: 'ability-row' }, [el('span', { class: 'ab-dot' }, '✦'), el('span', {}, '可接专业难度订单 (¥120-500)')]),
          el('div', { class: 'ability-row' }, [el('span', { class: 'ab-dot' }, '✦'), el('span', {}, '可同时接 5 个订单')]),
          el('div', { class: 'ability-row' }, [el('span', { class: 'ab-dot' }, '✦'), el('span', {}, '订单优先推荐')])
        ]));
        content.appendChild(el('div', { class: 'bottom-action-bar' }, [
          el('button', { class: 'btn-gradient', onClick: () => { applyAssessPass(); successToast('已升至 Lv.6，专业订单已解锁', 900); setTimeout(() => switchTab('taskMarket'), 500); } }, '去接更高难度订单')
        ]));
        content.appendChild(el('div', { style: 'text-align:center;padding:4px 0 16px' }, el('button', { class: 'link-btn', onClick: () => toast('徽章分享链接已复制') }, '分享徽章')));
      } else {
        content.appendChild(el('div', { class: 'assess-center fail' }, [
          el('div', { class: 'as-icon-fail' }, '!'),
          el('div', { class: 'as-title' }, '本次未通过'),
          el('div', { class: 'as-score' }, [el('span', { class: 'as-num' }, '72'), el('span', { class: 'as-sep' }, '/ 80 及格')])
        ]));
        content.appendChild(el('div', { class: 'section-card' }, [
          el('div', { class: 'sc-title' }, '薄弱环节分析'),
          el('div', { class: 'weak-row' }, '构图与色彩搭配需加强'),
          el('div', { class: 'weak-row' }, '商品主体突出不够，背景干扰较多'),
          el('div', { class: 'weak-row' }, '光影质感处理偏平，缺乏层次'),
          el('div', { class: 'weak-row' }, '交付用时偏长，建议提升效率')
        ]));
        content.appendChild(el('div', { class: 'as-tip' }, '可免费参加下一期培训重听一次'));
        content.appendChild(el('div', { class: 'bottom-action-bar' }, [
          el('button', { class: 'btn-gradient', onClick: () => navigate('training') }, '报名下一期')
        ]));
        content.appendChild(el('div', { style: 'text-align:center;padding:4px 0 16px' }, el('button', { class: 'link-btn', onClick: () => toast('查看错题解析') }, '查看错题解析')));
      }
    }
    renderState();
    s.appendChild(content);
    s.appendChild(el('div', { style: 'padding:16px;display:flex;gap:8px;justify-content:center' }, [
      el('button', { class: 'btn-outline', style: 'font-size:11px;padding:6px 12px', onClick: () => { assessPass = true; renderState(); } }, '状态A:通过'),
      el('button', { class: 'btn-outline', style: 'font-size:11px;padding:6px 12px', onClick: () => { assessPass = false; renderState(); } }, '状态B:未通过')
    ]));
    return s;
  }
};

// ------- 导航 -------
let currentScreen = 'courseCenter';

// ------- 导航栈 -------
const TAB_ROOTS = ['courseCenter', 'home', 'taskMarket', 'me'];
const navStack = [];

/** 当前屏是否为 Tab 根屏（不需返回按钮） */
function isTabRoot(key) { return TAB_ROOTS.includes(key); }

/** 能否返回：栈非空即可返回 */
function canGoBack() { return navStack.length > 0; }

/**
 * 导航到新屏（默认压栈）
 * opts.replace=true: 替换当前屏而不压栈（用于“提交后跳结果页”之类不希望回到的场景）
 * opts.resetStack=true: 清空栈后写入（用于 Tab 切换）
 */
function navigate(key, opts = {}) {
  if (!Renderers[key]) { toast('该屏暂未实现'); return; }
  if (opts.resetStack) {
    navStack.length = 0;
  } else if (!opts.replace && currentScreen && currentScreen !== key) {
    navStack.push(currentScreen);
    // 防止栈无限增长（开发预览器保留 20 层就够了）
    if (navStack.length > 20) navStack.shift();
  }
  currentScreen = key;
  render();
}

/** 返回上一级：弹栈；若栈空但当前为子屏，兵底回到逻辑父 Tab */
function goBack() {
  if (navStack.length > 0) {
    currentScreen = navStack.pop();
  } else if (!isTabRoot(currentScreen)) {
    const fallback = {
      imageGen: 'home', videoGen: 'home', audioGen: 'home', result: 'home',
      cutout: 'home', digitalHuman: 'home', scenes: 'home',
      courseDetail: 'courseCenter',
      taskDetail: 'taskMarket', submitStatus: 'taskMarket', taskHistory: 'taskMarket',
      wallet: 'me', withdraw: 'wallet', buyCredits: 'wallet', works: 'me',
      creatorLevel: 'me', expRules: 'creatorLevel', badgeWall: 'creatorLevel', badgeDetail: 'badgeWall',
      training: 'courseCenter', regSuccess: 'courseDetail', myRegistrations: 'courseCenter', regDetail: 'myRegistrations', assessResult: 'myRegistrations'
    }[currentScreen] || 'courseCenter';
    currentScreen = fallback;
  } else {
    return; // 已在 Tab 根，无处可退
  }
  render();
}

/** 底部 Tab 切换：重置导航栈（与 iOS/Android 官方 Tab 行为一致） */
function switchTab(tabKey) {
  navStack.length = 0;
  currentScreen = tabKey;
  render();
}

function render() {
  const body = $('#phoneBody');
  body.innerHTML = '';
  body.appendChild(Renderers[currentScreen]());
  body.scrollTop = 0;

  // Tab 高亮（子屏归属到其逻辑父 Tab）
  const tabMap = {
    // 课程 tab（课程中心 + 报名/考核链路）
    courseCenter: 'courseCenter', courseDetail: 'courseCenter',
    training: 'courseCenter', regSuccess: 'courseCenter', myRegistrations: 'courseCenter', regDetail: 'courseCenter', assessResult: 'courseCenter',
    // 创作 tab（首页 + 创作工具，场景已并入）
    home: 'home', imageGen: 'home', result: 'home', videoGen: 'home', audioGen: 'home',
    cutout: 'home', digitalHuman: 'home', scenes: 'home',
    // 接单 tab
    taskMarket: 'taskMarket', taskDetail: 'taskMarket', submitStatus: 'taskMarket', taskHistory: 'taskMarket',
    // 我的 tab
    works: 'me', wallet: 'me', withdraw: 'me', buyCredits: 'me', me: 'me',
    creatorLevel: 'me', expRules: 'me', badgeWall: 'me', badgeDetail: 'me'
  };
  document.querySelectorAll('.tab').forEach(t => {
    t.classList.toggle('active', t.dataset.tab === tabMap[currentScreen]);
  });

  // 侧栏高亮
  document.querySelectorAll('.screen-item').forEach(it => {
    it.classList.toggle('active', it.dataset.key === currentScreen);
  });
}

// 兼容旧调用：保留 navigate 作为默认入口

// ------- 启动 -------
function init() {
  const list = $('#screenList');
  SCREENS.forEach(sc => {
    const item = el('div', {
      class: 'screen-item' + (sc.key === 'courseCenter' ? ' active' : ''),
      'data-key': sc.key,
      onClick: () => navigate(sc.key)
    }, [
      el('span', { class: 'ico' }, sc.ico),
      el('span', {}, sc.label)
    ]);
    list.appendChild(item);
  });

  document.querySelectorAll('.tab').forEach(t => {
    t.addEventListener('click', () => switchTab(t.dataset.tab));
  });

  // 语速 slider 联动
  document.addEventListener('input', e => {
    if (e.target.type === 'range' && e.target.closest('.slider-row')) {
      const val = e.target.closest('.slider-row').querySelector('.val');
      if (val) val.textContent = parseFloat(e.target.value).toFixed(1) + 'x';
    }
  });

  switchTab('courseCenter');
}

document.addEventListener('DOMContentLoaded', init);
