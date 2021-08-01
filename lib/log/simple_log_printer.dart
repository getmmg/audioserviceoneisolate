// Package imports:
import 'package:logger/logger.dart';

Logger getLogger(String className) {
  return Logger(printer: SimpleLogPrinter(className));
}

class SimpleLogPrinter extends SimplePrinter {
  final String className;
  SimpleLogPrinter(this.className);
  @override
  List<String> log(LogEvent event) {
    String now = DateTime.now().toString();
    return ["$className :  $now: ------------> ${event.message} <------------"];
  }
}
