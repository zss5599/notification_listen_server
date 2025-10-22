import 'dart:developer';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// 日志工具类：支持全局开关控制 + 文件存储
class LogUtil {
  static bool _enableLog = true; // 全局总开关
  static late Logger _logger;
  static File? _logFile;

  /// 初始化日志系统
  /// [enableLog] 是否启用日志
  /// [logDirName] 存储目录名称（默认 logs）
  static Future<void> init({
    bool enableLog = true,
    String logDirName = "logs",
    Level minLevel = Level.all,
  }) async {
    _enableLog = enableLog;
    if (!_enableLog) return; // 开关关闭时不初始化

    // 1. 创建日志目录
    final appDocDir = Platform.isAndroid?await getExternalStorageDirectory():await getApplicationDocumentsDirectory();
    final logDir = Directory('${appDocDir?.path}/$logDirName');
    if (!await logDir.exists()) await logDir.create(recursive: true);

    // 2. 创建日志文件（按日期命名）
    final now = DateTime.now();
    _logFile = File('${logDir.path}/log');

    log("logPath : $_logFile");
    // 3. 配置Logger实例
    _logger = Logger(
      filter: _CustomLogFilter(minLevel), // 日志级别过滤
      printer: PrettyPrinter(
        noBoxingByDefault: true,
        methodCount: 0, // 不显示调用栈
        dateTimeFormat:DateTimeFormat.onlyTime, // 显示时间
        // printEmojis: false,
        colors: false, // 不显示颜色
      ),
      output: MultiOutput([
        ConsoleOutput(), // 控制台输出
        _FileOutput(file: _logFile!), // 文件输出
        // _CleanFileOutput(file: _logFile!),
      ]),
    );
  }

  // ---------- 日志方法（带开关检查）-----------
  static void d(String message) {
    if (_enableLog) _logger.d(message);
  }

  static void i(String message) {
    if (_enableLog) _logger.i(message);
  }

  static void w(String message) {
    if (_enableLog) _logger.w(message);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_enableLog) _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 获取日志目录路径（用于UI展示或清理）
  static Future<String?> get logDirPath async {
    if (!_enableLog) return null;
    return _logFile?.path;
  }

  /// 删除日志文件
  void delLog() {
     _logFile?.delete();

  }
}

// ---------- 自定义组件 -----------
/// 文件输出器（将日志写入文件）
class _FileOutput extends LogOutput {
  final File file;

  _FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    final log = event.lines.join('\n');
    file.writeAsStringSync('$log\n', mode: FileMode.append);
  }
}

class _CleanFileOutput extends LogOutput {
  final File file;
  final _ansiEscapePattern = RegExp(r'\x1b\[[0-9;]*m'); // 匹配 ANSI 转义序列

  _CleanFileOutput({required this.file});

  @override
  void output(OutputEvent event) async {
    // 过滤颜色代码
    final cleanLogs = event.lines.map((line) => line.replaceAll(_ansiEscapePattern, '')).join('\n');

    await file.writeAsString('$cleanLogs\n', mode: FileMode.append);
  }
}

/// 日志级别过滤器[1,5](@ref)
class _CustomLogFilter extends LogFilter {
  final Level minLevel;

  _CustomLogFilter(this.minLevel);

  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= minLevel.index;
  }
}