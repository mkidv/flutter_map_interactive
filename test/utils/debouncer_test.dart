import 'package:fake_async/fake_async.dart';
import 'package:flutter_map_interactive/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('executes action after duration', () {
      fakeAsync((async) {
        var callCount = 0;
        final debouncer = Debouncer(const Duration(milliseconds: 100));

        debouncer.run(() => callCount++);

        expect(callCount, 0, reason: 'Action should not execute immediately');

        async.elapse(const Duration(milliseconds: 50));
        expect(callCount, 0,
            reason: 'Action should not execute before duration');

        async.elapse(const Duration(milliseconds: 50));
        expect(callCount, 1, reason: 'Action should execute after duration');
      });
    });

    test('resets timer on subsequent calls (trailing debounce)', () {
      fakeAsync((async) {
        var callCount = 0;
        final debouncer = Debouncer(const Duration(milliseconds: 100));

        debouncer.run(() => callCount++);

        async.elapse(const Duration(milliseconds: 50));
        debouncer.run(() => callCount++); // Should reset timer

        async.elapse(const Duration(milliseconds: 60));
        expect(callCount, 0, reason: 'Should not execute yet (timer reset)');

        async.elapse(const Duration(milliseconds: 40));
        expect(callCount, 1,
            reason: 'Should execute after full duration from last call');
      });
    });

    test('allows new call after timer completes', () {
      fakeAsync((async) {
        var callCount = 0;
        final debouncer = Debouncer(const Duration(milliseconds: 100));

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 1);

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 2,
            reason: 'Second call should work after first completes');
      });
    });

    test('cancel stops pending action', () {
      fakeAsync((async) {
        var callCount = 0;
        final debouncer = Debouncer(const Duration(milliseconds: 100));

        debouncer.run(() => callCount++);

        async.elapse(const Duration(milliseconds: 50));
        debouncer.cancel();

        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 0, reason: 'Cancelled action should not execute');
      });
    });

    test('can run new action after cancel', () {
      fakeAsync((async) {
        var callCount = 0;
        final debouncer = Debouncer(const Duration(milliseconds: 100));

        debouncer.run(() => callCount++);
        debouncer.cancel();

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 1, reason: 'New action after cancel should work');
      });
    });

    test('cancel is safe to call multiple times', () {
      final debouncer = Debouncer(const Duration(milliseconds: 100));

      // Should not throw
      debouncer.cancel();
      debouncer.cancel();
      debouncer.cancel();
    });

    test('cancel is safe when no timer is active', () {
      final debouncer = Debouncer(const Duration(milliseconds: 100));

      // Should not throw
      debouncer.cancel();
    });
  });
}
