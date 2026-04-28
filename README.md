# AWL Focus

> 一个用 Flutter 写的极简学术词汇（Academic Word List）背单词应用，主打 **Apple 风格 + 玻璃拟态（Glassmorphism）+ 专注学习体验**。

[English](#english) · 简体中文

---

## ✨ 特性

- **专注的两屏流程** — Sublist 选择页 + 单词学习页，没有多余干扰
- **真磨砂玻璃 UI** — 使用 `BackdropFilter(ImageFilter.blur(20, 20))`，柔和阴影 + 半透明白底
- **丝滑转场** — 自定义 `SmoothPageRoute`：渐显 + 微缩放 + 微位移，进入与返回一气呵成
- **拼写训练** — 看中文释义和遮盖了关键词的英文例句，键盘输入拼写
- **单词朗读** — 点扬声器图标朗读发音（`flutter_tts`）
- **本地进度** — 每个 Sublist 独立断点续学，`shared_preferences` 持久化
- **错题本** — 错过的单词自动收集，可筛选 Sublist，"已掌握" 一键移除
- **柔和动效** — 卡片 `AnimatedScale` 按下反馈、进度条 `TweenAnimationBuilder` 动画、单词切换 `AnimatedSwitcher` 渐显+滑入

## 🎨 设计语言

| Token         | 值                              |
|---------------|--------------------------------|
| Primary       | `#6C63FF`                      |
| Background    | `#F8F9FB → #EEF1F6` 垂直渐变   |
| Text primary  | `#1C1C1E`                      |
| Text secondary| `#8E8E93`                      |
| Success       | `#34C759`                      |
| Danger        | `#FF3B30`                      |
| 圆角           | 20–28px                        |
| 阴影           | `blur 20, offset (0,8), α 0.06`|
| 玻璃模糊       | `sigmaX/Y: 20`                 |
| 玻璃白底       | 普通卡 60% / 焦点卡 75%         |

## 🛠 技术栈

| 层 | 选型 |
|---|---|
| 框架 | Flutter (Material 3 + Cupertino 混合) |
| 状态 | `ChangeNotifier`（`StudyManager` 单例） |
| 存储 | `shared_preferences` |
| 语音 | `flutter_tts` |
| 数据 | `assets/words.json`（AWL 10 个 sublist） |

## 🚀 快速开始

```bash
# 1. 克隆
git clone https://github.com/<your-name>/awl-focus.git
cd awl-focus

# 2. 拉依赖
flutter pub get

# 3. 运行（接好设备或开模拟器）
flutter run
```

需要 Flutter SDK `^3.10.1`。

### 生成 App 图标

```bash
flutter pub run flutter_launcher_icons
```

图标源文件：`assets/icon/2.png`（在 `pubspec.yaml` 的 `flutter_launcher_icons` 配置里）。

## 📁 项目结构

```
lib/
  main.dart                # 全部代码：主题、GlassCard、页面、StudyManager
assets/
  words.json               # AWL Sublist 数据
  icon/2.png               # App 图标源
android/  ios/  windows/   # 各平台壳工程
```

> 单文件结构是刻意的：表面只有两屏，组件足够小，过度拆分反而增加理解成本。

## 🧪 数据格式

`assets/words.json` 是一个 sublist 数组：

```json
[
  {
    "title": "Sublist 1",
    "words": [
      {
        "id": 1,
        "english": "process",
        "phonetic": "/ˈprəʊses/",
        "chinese": "v. 处理, 处置",
        "example": "We need to process the application before the deadline."
      }
    ]
  }
]
```

## 🗺 路线图

下面这些是已经规划但还没动工的方向（欢迎 PR）：

- [ ] 学习统计页（连续打卡、准确率、每日学习曲线）
- [ ] 错题智能复习（基于艾宾浩斯曲线的 SRS）
- [ ] 多种练习模式（选择题 / 听写 / 看英选中）
- [ ] 收藏 / 星标功能（界面上的星星图标已经预留）
- [ ] Dark Mode
- [ ] 完成 Sublist 的庆祝动效（Lottie / 自绘粒子）
- [ ] 触觉反馈与音效

## 📜 License

[MIT](LICENSE)

---

<a id="english"></a>

## English

A minimalist Flutter vocabulary trainer for the Academic Word List (AWL), with an Apple-style glassmorphism UI and a focus-first study flow.

Two screens (sublist picker + word study), real backdrop-blur glass cards, custom smooth page transitions (fade + soft scale), TTS pronunciation, local persistence, and a built-in mistake review page.

```bash
flutter pub get
flutter run
```

Design tokens, structure, and roadmap are in the Chinese section above.
