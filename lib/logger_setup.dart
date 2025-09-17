import 'package:logging/logging.dart';

final Logger logger = Logger('TripLogger');

void setupLogging() {
  Logger.root.level = Level.ALL; // log everything
  Logger.root.onRecord.listen((record) {
    // Customize output: console for dev, remote for production
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
