import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/features/chat/widgets/modern_chat_input.dart';

void main() {
  group('resolveModelValvesFunctionId', () {
    test('returns base function id when model has valves and user allowed', () {
      final id = resolveModelValvesFunctionId(
        modelId: 'zhongxiaozhi.pipe-1',
        hasUserValves: true,
        userRole: 'user',
        permissions: {'chat': {'valves': true}},
      );
      expect(id, 'zhongxiaozhi');
    });

    test('null when model has no user valves', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'm.x',
          hasUserValves: false,
          userRole: 'user',
          permissions: {'chat': {'valves': true}},
        ),
        isNull,
      );
    });

    test('null when chat.valves permission is false and not admin', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'm.x',
          hasUserValves: true,
          userRole: 'user',
          permissions: {'chat': {'valves': false}},
        ),
        isNull,
      );
    });

    test('admin bypasses permission gate', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'm.x',
          hasUserValves: true,
          userRole: 'admin',
          permissions: {'chat': {'valves': false}},
        ),
        'm',
      );
    });

    test('defaults to allowed when permissions missing', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: 'abc',
          hasUserValves: true,
          userRole: 'user',
          permissions: null,
        ),
        'abc',
      );
    });

    test('null when modelId empty', () {
      expect(
        resolveModelValvesFunctionId(
          modelId: '',
          hasUserValves: true,
          userRole: 'admin',
          permissions: null,
        ),
        isNull,
      );
    });
  });
}
