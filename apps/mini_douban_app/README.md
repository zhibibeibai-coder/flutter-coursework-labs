# mini_douban_app

Flutter 实验七八 miniDouban 源码工作副本。

- 实验七：使用 `MovieCard`、`MoviePoster`、`MovieInfo` 等自定义 Widget 复用电影列表组件。
- 实验八：使用 `http.get` 异步请求远程 JSON，解析为 `Movie` Model；远程不可用时加载本地 fallback JSON，方便课堂环境展示。

说明：当前按要求暂停新的 Flutter/Gradle 构建，因此本项目只整理源码和报告材料，尚未执行 `flutter pub get` 或 APK 构建。为避免保留从 miniQuiz 复制来的旧依赖锁定文件，本项目暂不附带 `pubspec.lock`，后续构建时由 `pubspec.yaml` 重新生成。
